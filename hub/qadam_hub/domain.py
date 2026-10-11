"""Business logic: telemetry ingestion, scans, alerts, glucose, clinical facts.
Kept independent of the web layer (FastAPI) and of the transport (MQTT) so it can be unit-tested."""
from __future__ import annotations

import uuid
from datetime import date, datetime, timedelta

from . import rule
from .config import Settings
from .crypto import FieldCipher
from .db import Database, jdump, jload, now

SOURCES = {"hardware", "simulated", "synthetic", "manual"}
SITES = {"hallux", "mth1", "mth5", "heel"}
SITE_FR = {"mth1": "1re tête métatarsienne", "mth5": "5e tête métatarsienne", "hallux": "hallux", "heel": "talon"}


class PayloadError(ValueError):
    pass


# ---------------------------------------------------------------- telemetry
def validate_live(p: dict) -> dict:
    """Integrity checks on a measurement frame published by the bridge (docs/mqtt-contract.md)."""
    if not isinstance(p, dict):
        raise PayloadError("payload is not a JSON object")
    dev = str(p.get("device_id", "")).strip()
    if not dev or len(dev) > 40:
        raise PayloadError("device_id missing")
    source = p.get("source")
    if source not in ("hardware", "simulated"):
        raise PayloadError("source must be 'hardware' or 'simulated'")
    if p.get("integrity") not in (None, "ok"):
        raise PayloadError("frame failed integrity check at the bridge")

    def side(name: str) -> dict[str, float]:
        v = p.get(name)
        if isinstance(v, (int, float)):  # legacy Uno payload: single site
            v = {"mth1": v}
        if not isinstance(v, dict):
            return {}
        out = {}
        for k, x in v.items():
            if k in SITES and isinstance(x, (int, float)) and rule.PLAUSIBLE_MIN_C <= x <= rule.PLAUSIBLE_MAX_C:
                out[k] = float(x)
        return out

    left, right = side("left"), side("right")
    faults = [str(f) for f in p.get("faults", []) if isinstance(f, str)][:8]
    if not left and "left_sensor" not in faults:
        faults.append("left_sensor")
    if not right and "right_sensor" not in faults:
        faults.append("right_sensor")
    spread = p.get("spread") if isinstance(p.get("spread"), dict) else {}
    ts = p.get("ts")
    ts_s = ts / 1000.0 if isinstance(ts, (int, float)) and ts > 1e11 else now()
    return {
        "device_id": dev, "source": source, "sensor": str(p.get("sensor", ""))[:20],
        "seq": int(p.get("seq", 0) or 0), "ts": ts_s, "left": left, "right": right,
        "spread_left": float(spread.get("left", 0) or 0), "spread_right": float(spread.get("right", 0) or 0),
        "samples": int(p.get("samples", 1) or 1), "faults": faults,
    }


def ingest_live(db: Database, p: dict, cfg: Settings) -> dict:
    f = validate_live(p)
    dev = db.one("SELECT * FROM devices WHERE id=?", (f["device_id"],))
    patient = dev["patient_ref"] if dev and dev["patient_ref"] else (
        cfg.demo_patient if f["device_id"] == cfg.demo_device else None)
    t = now()
    with db.tx():
        db.execute(
            "INSERT INTO readings(device_id, patient_ref, ts, source, left_json, right_json, spread_left, spread_right, seq, faults_json)"
            " VALUES (?,?,?,?,?,?,?,?,?,?)",
            (f["device_id"], patient, f["ts"], f["source"], jdump(f["left"]), jdump(f["right"]),
             f["spread_left"], f["spread_right"], f["seq"], jdump(f["faults"])),
        )
        db.execute(
            "INSERT INTO devices(id, patient_ref, source, sensor, state, last_seen, last_frame_json) VALUES (?,?,?,?,?,?,?)"
            " ON CONFLICT(id) DO UPDATE SET source=excluded.source, sensor=excluded.sensor, state=excluded.state,"
            " last_seen=excluded.last_seen, last_frame_json=excluded.last_frame_json,"
            " patient_ref=COALESCE(devices.patient_ref, excluded.patient_ref)",
            (f["device_id"], patient, f["source"], f["sensor"], "online" if not f["faults"] else "sensor_fault",
             t, jdump(f)),
        )
        db.execute("DELETE FROM readings WHERE ts < ?", (t - 24 * 3600,))
    return f


def ingest_status(db: Database, device_id: str, p: dict) -> None:
    if not isinstance(p, dict):
        return
    state = p.get("state") if p.get("state") in ("online", "offline", "error") else "error"
    with db.tx():
        db.execute(
            "INSERT INTO devices(id, source, state, detail, last_status_at, counters_json, port) VALUES (?,?,?,?,?,?,?)"
            " ON CONFLICT(id) DO UPDATE SET source=COALESCE(excluded.source, devices.source), state=excluded.state,"
            " detail=excluded.detail, last_status_at=excluded.last_status_at, counters_json=excluded.counters_json,"
            " port=excluded.port",
            (device_id[:40], p.get("source"), state, str(p.get("detail", ""))[:200], now(),
             jdump(p.get("counters", {})), str(p.get("port", ""))[:40]),
        )


def device_view(row: dict, cfg: Settings) -> dict:
    t = now()
    age = (t - row["last_seen"]) if row.get("last_seen") else None
    state = row.get("state") or "unknown"
    if state in ("online", "sensor_fault") and (age is None or age > cfg.stale_after_s):
        state = "stale"
    frame = jload(row.get("last_frame_json"), {})
    return {
        "id": row["id"], "patient_ref": row.get("patient_ref"), "source": row.get("source"),
        "sensor": row.get("sensor"), "state": state, "detail": row.get("detail") or "",
        "last_seen": row.get("last_seen"), "age_s": round(age, 1) if age is not None else None,
        "port": row.get("port") or "", "counters": jload(row.get("counters_json"), {}),
        "last_frame": {k: frame.get(k) for k in ("left", "right", "faults", "seq", "samples")} if frame else None,
    }


# ---------------------------------------------------------------- scans & alerts
def _history(db: Database, patient_ref: str, before_ts: float) -> list[rule.PastScan]:
    rows = db.all("SELECT ts, dt_json FROM scans WHERE patient_ref=? AND ts < ? ORDER BY ts", (patient_ref, before_ts))
    return [rule.PastScan(datetime.fromtimestamp(r["ts"]).date(), jload(r["dt_json"], {})) for r in rows]


def record_scan(db: Database, cipher: FieldCipher, patient_ref: str, item: dict, cfg: Settings,
                origin: str = "app", demo: bool | None = None) -> dict:
    """Server-side re-evaluation of a scan. The hub is the reference: the app's own verdict is kept for
    comparison (mismatch flag) but alerts are created from the hub's evaluation."""
    scan_id = str(item.get("id") or uuid.uuid4())
    existing = db.one("SELECT * FROM scans WHERE id=?", (scan_id,))
    if existing:
        return _scan_result(db, existing)
    ts = float(item.get("ts") or now())
    if ts > 1e11:
        ts /= 1000.0
    left = {k: float(v) for k, v in (item.get("left") or {}).items() if k in SITES}
    right = {k: float(v) for k, v in (item.get("right") or {}).items() if k in SITES}
    source = item.get("source") if item.get("source") in SOURCES else "manual"
    demo = cfg.demo_mode if demo is None else demo
    r = rule.evaluate(left, right, _history(db, patient_ref, ts), datetime.fromtimestamp(ts).date(), demo=demo,
                      samples=int(item.get("samples", 4) or 4), spread_left=float(item.get("spread_left", 0) or 0),
                      spread_right=float(item.get("spread_right", 0) or 0))
    if r is None:
        raise PayloadError("invalid scan (missing side or implausible temperature)")
    app_level = item.get("app_level")
    mismatch = 1 if app_level and app_level != r.level else 0
    with db.tx():
        db.execute(
            "INSERT INTO scans(id, patient_ref, ts, source, origin, left_json, right_json, dt_json, max_dt, site, warmer_side,"
            " level, consecutive_days, confidence, confidence_label, factors_json, samples, app_level, mismatch)"
            " VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
            (scan_id, patient_ref, ts, source, origin, jdump(left), jdump(right), jdump(r.dt), r.max_dt, r.site,
             r.warmer_side, r.level, r.consecutive_days, r.confidence, r.confidence_label, jdump(r.factors),
             int(item.get("samples", 4) or 4), app_level, mismatch),
        )
        if r.level in ("amber", "red"):
            title = (f"Asymétrie {r.max_dt:.1f} °C · {SITE_FR.get(r.site, r.site)} · pied {'gauche' if r.warmer_side == 'left' else 'droit'} plus chaud"
                     + (" · 2 jours consécutifs" if r.level == "red" else "")).replace(".", ",", 1)
            db.execute(
                "INSERT INTO alerts(patient_ref, scan_id, kind, level, created_at, title, explanation_json, source)"
                " VALUES (?,?,?,?,?,?,?,?)",
                (patient_ref, scan_id, "foot", r.level, ts, title, jdump(r.explanation()), source),
            )
    return _scan_result(db, db.one("SELECT * FROM scans WHERE id=?", (scan_id,)))


def _scan_result(db: Database, s: dict) -> dict:
    a = db.one("SELECT id, status FROM alerts WHERE scan_id=?", (s["id"],))
    return {"id": s["id"], "level": s["level"], "max_dt": s["max_dt"], "site": s["site"],
            "confidence": s["confidence"], "confidence_label": s["confidence_label"],
            "mismatch": bool(s["mismatch"]), "alert_id": a["id"] if a else None}


def glucose_band(g_l: float, context: str) -> str:
    if g_l < 0.70:
        return "low"
    if g_l > 2.50:
        return "very_high"
    top = 1.30 if context == "fasting" else 1.80
    return "in_target" if 0.80 <= g_l <= top else "out_of_target"


def record_glucose(db: Database, patient_ref: str, item: dict, source: str = "manual") -> dict:
    gid = str(item.get("id") or uuid.uuid4())
    if db.one("SELECT id FROM glucose WHERE id=?", (gid,)):
        return {"id": gid, "duplicate": True}
    g = float(item["g_l"])
    if not 0.2 <= g <= 6.0:
        raise PayloadError("glucose out of measurable range (0.20-6.00 g/L)")
    ctx = item.get("context") if item.get("context") in ("fasting", "after_meal", "other") else "other"
    ts = float(item.get("ts") or now())
    if ts > 1e11:
        ts /= 1000.0
    band = glucose_band(g, ctx)
    with db.tx():
        db.execute("INSERT INTO glucose(id, patient_ref, ts, g_l, context, band, source) VALUES (?,?,?,?,?,?,?)",
                   (gid, patient_ref, ts, g, ctx, band, source))
        if band in ("low", "very_high"):
            kind = "glucose_low" if band == "low" else "glucose_high"
            title = f"Glycémie {g:.2f} g/L · {'hypoglycémie' if band == 'low' else 'très élevée'}".replace(".", ",", 1)
            expl = {"rule": "< 0.70 g/L = hypoglycémie ; > 2.50 g/L = très élevée", "value_g_l": g, "context": ctx}
            db.execute("INSERT INTO alerts(patient_ref, kind, level, created_at, title, explanation_json, source)"
                       " VALUES (?,?,?,?,?,?,?)",
                       (patient_ref, kind, "red" if band == "low" else "amber", ts, title, jdump(expl), source))
    return {"id": gid, "band": band}


def record_adherence(db: Database, patient_ref: str, item: dict, source: str = "manual") -> None:
    day = str(item["day"])[:10]
    date.fromisoformat(day)
    db.execute("INSERT INTO adherence(patient_ref, day, planned, taken, source) VALUES (?,?,?,?,?)"
               " ON CONFLICT(patient_ref, day) DO UPDATE SET planned=excluded.planned, taken=excluded.taken",
               (patient_ref, day, int(item.get("planned", 0)), int(item.get("taken", 0)), source))


# ---------------------------------------------------------------- facts for the clinician summary
def facts(db: Database, patient_ref: str, days: int = 14) -> dict:
    since = now() - days * 86400
    scans = db.all("SELECT * FROM scans WHERE patient_ref=? AND ts>=? ORDER BY ts", (patient_ref, since))
    gl = db.all("SELECT * FROM glucose WHERE patient_ref=? AND ts>=? ORDER BY ts", (patient_ref, since))
    since_day = (date.today() - timedelta(days=days)).isoformat()
    adh = db.all("SELECT * FROM adherence WHERE patient_ref=? AND day>=?", (patient_ref, since_day))
    alerts = db.all("SELECT level, status, kind FROM alerts WHERE patient_ref=? AND created_at>=?", (patient_ref, since))
    levels = {lv: sum(1 for s in scans if s["level"] == lv) for lv in ("green", "amber", "red")}
    top = max(scans, key=lambda s: s["max_dt"]) if scans else None
    planned = sum(a["planned"] or 0 for a in adh)
    taken = sum(a["taken"] or 0 for a in adh)
    vals = [g["g_l"] for g in gl]
    return {
        "patient_ref": patient_ref, "period_days": days,
        "scans": {"count": len(scans), "levels": levels,
                  "max_dt_c": top["max_dt"] if top else None, "max_dt_site": top["site"] if top else None,
                  "last_level": scans[-1]["level"] if scans else None,
                  "days_with_scan": len({datetime.fromtimestamp(s["ts"]).date() for s in scans})},
        "glucose": {"count": len(vals), "mean_g_l": round(sum(vals) / len(vals), 2) if vals else None,
                    "in_target_pct": round(100 * sum(1 for g in gl if g["band"] == "in_target") / len(gl)) if gl else None,
                    "lows": sum(1 for g in gl if g["band"] == "low"),
                    "very_high": sum(1 for g in gl if g["band"] == "very_high")},
        "adherence_pct": round(100 * taken / planned) if planned else None,
        "alerts": {"open": sum(1 for a in alerts if a["status"] == "open"),
                   "confirmed": sum(1 for a in alerts if a["status"] == "confirmed"),
                   "dismissed": sum(1 for a in alerts if a["status"] == "dismissed")},
    }


def _fr(x: float, d: int = 1) -> str:
    return f"{x:.{d}f}".replace(".", ",")


def template_narrative(f: dict) -> str:
    """Deterministic French summary used when no AI is available (and as a cross-check of AI output)."""
    s, g = f["scans"], f["glucose"]
    lines = [f"Période : {f['period_days']} derniers jours."]
    if s["count"]:
        lines.append(f"Scans plantaires : {s['count']} sur {s['days_with_scan']} jours — {s['levels']['green']} normaux, "
                     f"{s['levels']['amber']} à surveiller, {s['levels']['red']} en alerte. Écart maximal {_fr(s['max_dt_c'])} °C "
                     f"({SITE_FR.get(s['max_dt_site'], s['max_dt_site'])}).")
    else:
        lines.append("Aucun scan plantaire sur la période.")
    if g["count"]:
        lines.append(f"Glycémie : {g['count']} mesures, moyenne {_fr(g['mean_g_l'], 2)} g/L, {g['in_target_pct']} % dans la cible, "
                     f"{g['lows']} hypoglycémie(s) < 0,70 g/L, {g['very_high']} valeur(s) > 2,50 g/L.")
    else:
        lines.append("Aucune glycémie enregistrée.")
    if f["adherence_pct"] is not None:
        lines.append(f"Observance déclarée : {f['adherence_pct']} %.")
    a = f["alerts"]
    lines.append(f"Alertes : {a['open']} à traiter, {a['confirmed']} confirmée(s), {a['dismissed']} rejetée(s).")
    return "\n".join(lines)
