"""Qadam Hub: REST API + clinician dashboard + MQTT ingestion.

Layers (cahier des charges §5 "séparation stricte"):
  presentation  static/ (clinician dashboard)       + the Flutter patient app (separate repo folder)
  business      domain.py, rule.py, safety.py
  inference     ai.py (Gemini, optional, server-side key)
  data          db.py (SQLite), crypto.py (AES-256-GCM fields), audit.py (hash chain)
"""
from __future__ import annotations

import logging
import secrets
import time
from contextlib import asynccontextmanager
from datetime import date, datetime, timedelta
from typing import Literal

from fastapi import Depends, FastAPI, Header, HTTPException, Request
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field

from . import ai, audit, domain, fhir, seed
from .config import STATIC_DIR, Settings
from .crypto import FieldCipher, new_token, token_hash, verify_password
from .db import Database, jdump, jload, now
from .telemetry import TelemetryIngest, start_embedded_broker

log = logging.getLogger("qadam.hub")
SESSION_TTL_S = 8 * 3600


# ---------------------------------------------------------------- request models
class LoginIn(BaseModel):
    username: str = Field(min_length=1, max_length=64)
    password: str = Field(min_length=1, max_length=128)


class ReviewIn(BaseModel):
    decision: Literal["confirmed", "dismissed"]
    note: str = Field(default="", max_length=1000)


class SummaryReviewIn(BaseModel):
    decision: Literal["validated", "rejected"]
    note: str = Field(default="", max_length=1000)


class EnrollIn(BaseModel):
    label: str = Field(min_length=1, max_length=60)
    birth_year: int | None = Field(default=None, ge=1900, le=2026)
    diabetes_type: Literal["t1", "t2", "gest", "other"] = "t2"
    foot_risk: Literal["low", "moderate", "high"] = "moderate"


class PairIn(BaseModel):
    code: str = Field(min_length=4, max_length=12)
    share_with_care_team: bool = True
    ai_assistant: bool = True
    diabetes_type: Literal["t1", "t2", "gest", "other"] | None = None
    foot_risk: Literal["low", "moderate", "high"] | None = None


class SyncIn(BaseModel):
    items: list[dict] = Field(default_factory=list, max_length=500)


class AssistantIn(BaseModel):
    question: str = Field(min_length=1, max_length=500)
    lang: Literal["fr", "ar", "aeb"] = "fr"
    context: dict | None = None


# ---------------------------------------------------------------- app factory
def create_app(cfg: Settings | None = None, gemini: ai.GeminiClient | None = None, start_mqtt: bool | None = None) -> FastAPI:
    cfg = cfg or Settings()
    db = Database(cfg.db_path)
    cipher = FieldCipher(cfg.data_key)
    gem = gemini or ai.GeminiClient(cfg)
    ingest = TelemetryIngest(db, cfg)
    failed_logins: dict[str, list[float]] = {}

    @asynccontextmanager
    async def lifespan(app: FastAPI):
        if cfg.seed_synthetic:
            seed.seed(db, cipher, cfg)
        else:
            seed.ensure_users(db, cfg)
            seed.ensure_demo_patient(db, cipher, cfg)
        broker = None
        run_mqtt = cfg.mqtt_enabled if start_mqtt is None else start_mqtt
        if run_mqtt and cfg.embedded_broker:
            broker = await start_embedded_broker(cfg.mqtt_port)
        if run_mqtt:
            ingest.start()
        audit.log(db, "system", "hub_start", "", f"ai={'on' if gem.configured else 'off'} demo_mode={cfg.demo_mode}")
        yield
        ingest.stop()
        if broker is not None:
            await broker.shutdown()
        db.close()

    app = FastAPI(title="Qadam Hub", version="1.0.0", lifespan=lifespan,
                  description="Pseudonymised diabetic-foot monitoring hub (hackathon prototype, not a medical device).")
    app.state.db, app.state.cfg, app.state.ingest = db, cfg, ingest

    @app.middleware("http")
    async def security_headers(request: Request, call_next):
        resp = await call_next(request)
        resp.headers["X-Content-Type-Options"] = "nosniff"
        resp.headers["X-Frame-Options"] = "DENY"
        resp.headers["Referrer-Policy"] = "no-referrer"
        resp.headers["Cache-Control"] = "no-store" if request.url.path.startswith(("/api", "/fhir")) else "no-cache"
        if not request.url.path.startswith(("/api", "/fhir", "/docs", "/openapi")):
            resp.headers["Content-Security-Policy"] = (
                "default-src 'self'; img-src 'self' data:; style-src 'self'; script-src 'self'; font-src 'self'")
        return resp

    # ------------------------------------------------------------ auth helpers
    def clinician(authorization: str = Header(default="")) -> dict:
        tok = authorization.removeprefix("Bearer ").strip()
        row = db.one("SELECT s.username, s.expires_at, u.role, u.display_name FROM sessions s JOIN users u"
                      " ON u.username=s.username WHERE s.token_hash=?", (token_hash(tok),)) if tok else None
        if not row or row["expires_at"] < now():
            raise HTTPException(401, "Session expirée ou invalide")
        return row

    def patient(authorization: str = Header(default="")) -> dict:
        tok = authorization.removeprefix("Bearer ").strip()
        row = db.one("SELECT p.* FROM patient_tokens t JOIN patients p ON p.ref=t.patient_ref WHERE t.token_hash=?",
                     (token_hash(tok),)) if tok else None
        if not row:
            raise HTTPException(401, "Appareil non appairé")
        return row

    def get_patient_or_404(ref: str) -> dict:
        p = db.one("SELECT * FROM patients WHERE ref=?", (ref,))
        if not p:
            raise HTTPException(404, "Patient inconnu")
        return p

    # ------------------------------------------------------------ public
    @app.get("/api/health")
    def health():
        return {"ok": True, "time": now(), "mqtt_connected": ingest.connected, "ai_configured": gem.configured,
                "demo_mode": cfg.demo_mode, "version": app.version}

    @app.post("/api/auth/login")
    def login(body: LoginIn, request: Request):
        key = body.username.lower()
        recent = [t for t in failed_logins.get(key, []) if t > now() - 300]
        if len(recent) >= 5:
            raise HTTPException(429, "Trop de tentatives, réessayez dans 5 minutes")
        u = db.one("SELECT * FROM users WHERE username=?", (body.username,))
        if not u or not verify_password(body.password, u["pw_hash"]):
            failed_logins[key] = recent + [now()]
            audit.log(db, body.username[:64], "login_failed", "", request.client.host if request.client else "")
            raise HTTPException(401, "Identifiants incorrects")
        failed_logins.pop(key, None)
        tok = new_token()
        exp = now() + SESSION_TTL_S
        db.execute("INSERT INTO sessions(token_hash, username, expires_at) VALUES (?,?,?)", (token_hash(tok), u["username"], exp))
        db.execute("DELETE FROM sessions WHERE expires_at < ?", (now(),))
        audit.log(db, u["username"], "login", "", "")
        return {"token": tok, "username": u["username"], "display_name": u["display_name"], "role": u["role"], "expires_at": exp}

    @app.post("/api/auth/logout")
    def logout(authorization: str = Header(default="")):
        tok = authorization.removeprefix("Bearer ").strip()
        db.execute("DELETE FROM sessions WHERE token_hash=?", (token_hash(tok),))
        return {"ok": True}

    # ------------------------------------------------------------ clinician API
    @app.get("/api/me")
    def me(user: dict = Depends(clinician)):
        return {k: user[k] for k in ("username", "display_name", "role")}

    def _patient_card(p: dict) -> dict:
        ref = p["ref"]
        last = db.one("SELECT id, ts, level, max_dt, site, source, confidence FROM scans WHERE patient_ref=? ORDER BY ts DESC LIMIT 1", (ref,))
        lastg = db.one("SELECT ts, g_l, context, band FROM glucose WHERE patient_ref=? ORDER BY ts DESC LIMIT 1", (ref,))
        open_alerts = db.all("SELECT level FROM alerts WHERE patient_ref=? AND status='open'", (ref,))
        since = (date.today() - timedelta(days=7)).isoformat()
        adh = db.one("SELECT SUM(planned) p, SUM(taken) t FROM adherence WHERE patient_ref=? AND day>=?", (ref, since))
        age = date.today().year - p["birth_year"] if p.get("birth_year") else None
        return {
            "ref": ref, "label": cipher.decrypt(p["label_enc"]), "age": age, "diabetes_type": p["diabetes_type"],
            "foot_risk": p["foot_risk"], "synthetic": bool(p["synthetic"]), "device_id": p.get("device_id"),
            "paired": bool(db.one("SELECT 1 FROM patient_tokens WHERE patient_ref=?", (ref,))),
            "last_scan": last, "last_glucose": lastg,
            "open_alerts": {"red": sum(1 for a in open_alerts if a["level"] == "red"),
                            "amber": sum(1 for a in open_alerts if a["level"] == "amber")},
            "adherence_7d": round(100 * adh["t"] / adh["p"]) if adh and adh["p"] else None,
        }

    @app.get("/api/overview")
    def overview(user: dict = Depends(clinician)):
        pts = db.all("SELECT * FROM patients ORDER BY ref")
        open_alerts = db.all("SELECT level FROM alerts WHERE status='open'")
        start_today = datetime.combine(date.today(), datetime.min.time()).timestamp()
        devs = [domain.device_view(d, cfg) for d in db.all("SELECT * FROM devices")]
        return {
            "patients": len(pts),
            "alerts_open": {"red": sum(1 for a in open_alerts if a["level"] == "red"),
                            "amber": sum(1 for a in open_alerts if a["level"] == "amber")},
            "scans_today": db.one("SELECT COUNT(*) n FROM scans WHERE ts>=?", (start_today,))["n"],
            "patients_scanned_today": db.one("SELECT COUNT(DISTINCT patient_ref) n FROM scans WHERE ts>=?", (start_today,))["n"],
            "devices": devs,
            "ingest": {"mqtt_connected": ingest.connected, **ingest.stats, "last_error": ingest.last_error,
                       "broker": f"{cfg.mqtt_host}:{cfg.mqtt_port}"},
            "ai_configured": gem.configured, "ai_model": cfg.gemini_model if gem.configured else None,
            "demo_mode": cfg.demo_mode,
        }

    @app.get("/api/patients")
    def patients(user: dict = Depends(clinician)):
        cards = [_patient_card(p) for p in db.all("SELECT * FROM patients")]
        prio = {"red": 0, "amber": 1, "green": 2, None: 3}
        cards.sort(key=lambda c: (0 if c["open_alerts"]["red"] else 1 if c["open_alerts"]["amber"] else 2,
                                  prio.get((c["last_scan"] or {}).get("level"), 3), c["ref"]))
        return cards

    @app.post("/api/patients")
    def enroll(body: EnrollIn, user: dict = Depends(clinician)):
        for _ in range(20):
            ref = f"QDM-{secrets.randbelow(9000) + 1000}"
            if not db.one("SELECT 1 FROM patients WHERE ref=?", (ref,)):
                break
        code = f"{secrets.randbelow(900000) + 100000}"
        db.execute("INSERT INTO patients(ref, label_enc, birth_year, diabetes_type, foot_risk, consent_json, pairing_code,"
                   " pairing_expires, synthetic, created_at) VALUES (?,?,?,?,?,?,?,?,?,?)",
                   (ref, cipher.encrypt(body.label), body.birth_year, body.diabetes_type, body.foot_risk, jdump({}),
                    code, now() + 48 * 3600, 0, now()))
        audit.log(db, user["username"], "enroll_patient", ref, "")
        return {"ref": ref, "pairing_code": code, "expires_in_h": 48}

    @app.get("/api/patients/{ref}")
    def patient_detail(ref: str, days: int = 30, user: dict = Depends(clinician)):
        p = get_patient_or_404(ref)
        since = now() - min(max(days, 1), 120) * 86400
        scans = db.all("SELECT * FROM scans WHERE patient_ref=? AND ts>=? ORDER BY ts", (ref, since))
        for s in scans:
            for k in ("left_json", "right_json", "dt_json", "factors_json"):
                s[k.removesuffix("_json")] = jload(s.pop(k), {})
        gl = db.all("SELECT * FROM glucose WHERE patient_ref=? AND ts>=? ORDER BY ts", (ref, since))
        adh = db.all("SELECT day, planned, taken FROM adherence WHERE patient_ref=? ORDER BY day DESC LIMIT 14", (ref,))
        alerts = [_alert_out(a) for a in db.all("SELECT * FROM alerts WHERE patient_ref=? ORDER BY created_at DESC LIMIT 30", (ref,))]
        sums = [_summary_out(s) for s in db.all("SELECT * FROM summaries WHERE patient_ref=? ORDER BY created_at DESC LIMIT 5", (ref,))]
        live = []
        if p.get("device_id"):
            live = db.all("SELECT ts, source, left_json, right_json, faults_json FROM readings WHERE device_id=? AND ts>=?"
                          " ORDER BY ts DESC LIMIT 60", (p["device_id"], now() - 600))
            for r in live:
                r["left"], r["right"], r["faults"] = jload(r.pop("left_json"), {}), jload(r.pop("right_json"), {}), jload(r.pop("faults_json"), [])
        dev = db.one("SELECT * FROM devices WHERE id=?", (p.get("device_id") or "",))
        audit.log(db, user["username"], "view_patient", ref, "")
        return {"patient": _patient_card(p), "consent": jload(p.get("consent_json"), {}), "scans": scans, "glucose": gl,
                "adherence": adh, "alerts": alerts, "summaries": sums, "live": live[::-1],
                "device": domain.device_view(dev, cfg) if dev else None}

    def _alert_out(a: dict) -> dict:
        out = {k: a[k] for k in ("id", "patient_ref", "scan_id", "kind", "level", "created_at", "title", "source",
                                 "status", "reviewer", "reviewed_at", "patient_ack_at")}
        out["explanation"] = jload(a.get("explanation_json"), {})
        out["review_note"] = cipher.decrypt(a.get("review_note_enc"))
        return out

    def _summary_out(s: dict) -> dict:
        out = {k: s[k] for k in ("id", "patient_ref", "created_at", "period_days", "source", "model", "status", "reviewer", "reviewed_at")}
        out["facts"] = jload(s.get("facts_json"), {})
        out["narrative"] = cipher.decrypt(s.get("narrative_enc"))
        out["review_note"] = cipher.decrypt(s.get("review_note_enc"))
        return out

    @app.get("/api/alerts")
    def alerts(status: str = "open", user: dict = Depends(clinician)):
        if status == "all":
            rows = db.all("SELECT * FROM alerts ORDER BY created_at DESC LIMIT 200")
        else:
            rows = db.all("SELECT * FROM alerts WHERE status=? ORDER BY CASE level WHEN 'red' THEN 0 ELSE 1 END, created_at DESC LIMIT 200", (status,))
        labels = {p["ref"]: cipher.decrypt(p["label_enc"]) for p in db.all("SELECT ref, label_enc FROM patients")}
        return [{**_alert_out(a), "patient_label": labels.get(a["patient_ref"], "")} for a in rows]

    @app.get("/api/alerts/{alert_id}")
    def alert_detail(alert_id: int, user: dict = Depends(clinician)):
        a = db.one("SELECT * FROM alerts WHERE id=?", (alert_id,))
        if not a:
            raise HTTPException(404, "Alerte inconnue")
        scan = db.one("SELECT * FROM scans WHERE id=?", (a["scan_id"],)) if a["scan_id"] else None
        if scan:
            for k in ("left_json", "right_json", "dt_json", "factors_json"):
                scan[k.removesuffix("_json")] = jload(scan.pop(k), {})
        trend = db.all("SELECT ts, max_dt, level, site, source FROM scans WHERE patient_ref=? AND ts>=? ORDER BY ts",
                       (a["patient_ref"], a["created_at"] - 14 * 86400))
        p = get_patient_or_404(a["patient_ref"])
        audit.log(db, user["username"], "view_alert", str(alert_id), a["patient_ref"])
        return {"alert": _alert_out(a), "scan": scan, "trend": trend, "patient": _patient_card(p)}

    @app.post("/api/alerts/{alert_id}/review")
    def review_alert(alert_id: int, body: ReviewIn, user: dict = Depends(clinician)):
        a = db.one("SELECT * FROM alerts WHERE id=?", (alert_id,))
        if not a:
            raise HTTPException(404, "Alerte inconnue")
        if a["status"] != "open":
            raise HTTPException(409, "Alerte déjà traitée")
        db.execute("UPDATE alerts SET status=?, reviewer=?, review_note_enc=?, reviewed_at=? WHERE id=?",
                   (body.decision, user["username"], cipher.encrypt(body.note.strip()), now(), alert_id))
        audit.log(db, user["username"], f"alert_{body.decision}", str(alert_id), a["patient_ref"])
        return _alert_out(db.one("SELECT * FROM alerts WHERE id=?", (alert_id,)))

    @app.post("/api/patients/{ref}/summaries")
    async def make_summary(ref: str, days: int = 14, user: dict = Depends(clinician)):
        get_patient_or_404(ref)
        f = domain.facts(db, ref, days)
        template = domain.template_narrative(f)
        text, source, model = await ai.clinician_narrative(f, template, gem)
        cur = db.execute("INSERT INTO summaries(patient_ref, created_at, period_days, facts_json, narrative_enc, source, model)"
                         " VALUES (?,?,?,?,?,?,?)", (ref, now(), days, jdump(f), cipher.encrypt(text), source, model))
        audit.log(db, user["username"], "summary_draft", ref, source)
        return _summary_out(db.one("SELECT * FROM summaries WHERE id=?", (cur.lastrowid,)))

    @app.post("/api/summaries/{sid}/review")
    def review_summary(sid: int, body: SummaryReviewIn, user: dict = Depends(clinician)):
        s = db.one("SELECT * FROM summaries WHERE id=?", (sid,))
        if not s:
            raise HTTPException(404, "Synthèse inconnue")
        if s["status"] != "draft":
            raise HTTPException(409, "Synthèse déjà traitée")
        db.execute("UPDATE summaries SET status=?, reviewer=?, review_note_enc=?, reviewed_at=? WHERE id=?",
                   (body.decision, user["username"], cipher.encrypt(body.note.strip()), now(), sid))
        audit.log(db, user["username"], f"summary_{body.decision}", str(sid), s["patient_ref"])
        return _summary_out(db.one("SELECT * FROM summaries WHERE id=?", (sid,)))

    @app.get("/api/devices")
    def devices(user: dict = Depends(clinician)):
        return [domain.device_view(d, cfg) for d in db.all("SELECT * FROM devices ORDER BY id")]

    @app.get("/api/devices/{device_id}/live")
    def device_live(device_id: str, seconds: int = 600, user: dict = Depends(clinician)):
        dev = db.one("SELECT * FROM devices WHERE id=?", (device_id,))
        if not dev:
            raise HTTPException(404, "Appareil inconnu")
        rows = db.all("SELECT ts, source, left_json, right_json, spread_left, spread_right, faults_json FROM readings"
                      " WHERE device_id=? AND ts>=? ORDER BY ts DESC LIMIT 240", (device_id, now() - min(seconds, 3600)))
        for r in rows:
            r["left"], r["right"], r["faults"] = jload(r.pop("left_json"), {}), jload(r.pop("right_json"), {}), jload(r.pop("faults_json"), [])
        return {"device": domain.device_view(dev, cfg), "readings": rows[::-1]}

    @app.get("/api/audit")
    def audit_list(limit: int = 100, user: dict = Depends(clinician)):
        return db.all("SELECT id, ts, actor, action, target, detail, hash FROM audit ORDER BY id DESC LIMIT ?", (min(limit, 500),))

    @app.get("/api/audit/verify")
    def audit_verify(user: dict = Depends(clinician)):
        return audit.verify(db)

    # ------------------------------------------------------------ FHIR (read-only)
    @app.get("/fhir/Patient/{ref}")
    def fhir_patient(ref: str, user: dict = Depends(clinician)):
        audit.log(db, user["username"], "fhir_export", ref, "Patient")
        return JSONResponse(fhir.patient(get_patient_or_404(ref)), media_type="application/fhir+json")

    @app.get("/fhir/Observation")
    def fhir_observations(patient: str, user: dict = Depends(clinician)):
        get_patient_or_404(patient)
        audit.log(db, user["username"], "fhir_export", patient, "Observation")
        return JSONResponse(fhir.observation_bundle(db, patient), media_type="application/fhir+json")

    # ------------------------------------------------------------ patient app API
    @app.post("/api/patient/pair")
    def pair(body: PairIn):
        p = db.one("SELECT * FROM patients WHERE pairing_code=?", (body.code.strip(),))
        if not p or (p["pairing_expires"] or 0) < now():
            raise HTTPException(404, "Code d'appairage invalide ou expiré")
        consent = {"share_with_care_team": body.share_with_care_team, "ai_assistant": body.ai_assistant,
                   "given_at": now(), "version": "2026-10"}
        updates = {"consent_json": jdump(consent)}
        if body.diabetes_type:
            updates["diabetes_type"] = body.diabetes_type
        if body.foot_risk:
            updates["foot_risk"] = body.foot_risk
        sets = ", ".join(f"{k}=?" for k in updates)
        db.execute(f"UPDATE patients SET {sets} WHERE ref=?", (*updates.values(), p["ref"]))
        tok = new_token()
        db.execute("INSERT INTO patient_tokens(token_hash, patient_ref, created_at) VALUES (?,?,?)", (token_hash(tok), p["ref"], now()))
        audit.log(db, f"patient:{p['ref']}", "pair_app", p["ref"], jdump(consent))
        device = p.get("device_id") or ""
        return {"patient_ref": p["ref"], "token": tok, "device_id": device,
                "mqtt_topic": f"{cfg.topic_root}/{device}/live" if device else None, "demo_mode": cfg.demo_mode}

    @app.get("/api/patient/me")
    def patient_me(p: dict = Depends(patient)):
        return {"patient_ref": p["ref"], "device_id": p.get("device_id"), "consent": jload(p["consent_json"], {}),
                "demo_mode": cfg.demo_mode, "ai_configured": gem.configured}

    @app.post("/api/patient/sync")
    def sync(body: SyncIn, p: dict = Depends(patient)):
        consent = jload(p["consent_json"], {})
        if not consent.get("share_with_care_team"):
            raise HTTPException(403, "Partage avec l'équipe soignante non consenti")
        accepted, rejected, results = [], [], {}
        for it in body.items:
            iid = str(it.get("id", ""))
            try:
                kind = it.get("type")
                if kind == "scan":
                    results[iid] = domain.record_scan(db, cipher, p["ref"], it, cfg, origin="app")
                elif kind == "glucose":
                    results[iid] = domain.record_glucose(db, p["ref"], it, source="app")
                elif kind == "adherence":
                    domain.record_adherence(db, p["ref"], it, source="app")
                elif kind == "ack":
                    db.execute("UPDATE alerts SET patient_ack_at=? WHERE patient_ref=? AND scan_id=? AND patient_ack_at IS NULL",
                               (now(), p["ref"], str(it.get("scan_id", ""))))
                else:
                    raise domain.PayloadError(f"unknown item type {kind!r}")
                accepted.append(iid)
            except (domain.PayloadError, KeyError, ValueError, TypeError) as e:
                rejected.append({"id": iid, "error": str(e)})
        if accepted:
            audit.log(db, f"patient:{p['ref']}", "sync", p["ref"], f"{len(accepted)} items")
        return {"accepted": accepted, "rejected": rejected, "results": results, "server_time": now()}

    @app.get("/api/patient/alerts")
    def patient_alerts(p: dict = Depends(patient)):
        rows = db.all("SELECT * FROM alerts WHERE patient_ref=? ORDER BY created_at DESC LIMIT 30", (p["ref"],))
        return [{k: v for k, v in _alert_out(a).items() if k != "reviewer"} for a in rows]

    @app.post("/api/patient/assistant")
    async def assistant(body: AssistantIn, p: dict = Depends(patient)):
        consent = jload(p["consent_json"], {})
        client = gem if consent.get("ai_assistant") else ai.NO_AI  # no consent -> verified library only
        res = await ai.answer(body.question, body.lang, body.context, client)
        audit.log(db, f"patient:{p['ref']}", "assistant", p["ref"], f"{res['kind']}/{res['source']}")
        return res

    @app.delete("/api/patient/data")
    def erase(p: dict = Depends(patient)):
        ref = p["ref"]
        with db.tx():
            for table in ("scans", "glucose", "adherence", "alerts", "summaries", "patient_tokens"):
                db.execute(f"DELETE FROM {table} WHERE patient_ref=?", (ref,))
            db.execute("UPDATE patients SET consent_json=?, pairing_code=NULL WHERE ref=?", (jdump({"erased_at": now()}), ref))
        audit.log(db, f"patient:{ref}", "erase_data", ref, "right to erasure")
        return {"ok": True}

    # ------------------------------------------------------------ dashboard
    if STATIC_DIR.exists():
        app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")

        @app.get("/", include_in_schema=False)
        def index():
            return FileResponse(STATIC_DIR / "index.html")

    return app


def run() -> None:
    import argparse

    import uvicorn

    ap = argparse.ArgumentParser(description="Qadam Hub")
    ap.add_argument("--host", default="0.0.0.0")
    ap.add_argument("--port", type=int, default=8000)
    ap.add_argument("--ssl-keyfile")
    ap.add_argument("--ssl-certfile")
    a = ap.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(name)s %(levelname)s %(message)s")
    for noisy in ("amqtt", "transitions", "passlib"):
        logging.getLogger(noisy).setLevel(logging.WARNING)
    uvicorn.run(create_app(), host=a.host, port=a.port, ssl_keyfile=a.ssl_keyfile, ssl_certfile=a.ssl_certfile)


if __name__ == "__main__":
    run()
