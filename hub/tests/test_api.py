import json
import os

import httpx
import pytest
from fastapi.testclient import TestClient

from qadam_hub import ai, audit
from qadam_hub.config import Settings
from qadam_hub.main import create_app


@pytest.fixture()
def cfg(tmp_path, monkeypatch):
    monkeypatch.setenv("QADAM_DB", str(tmp_path / "t.db"))
    monkeypatch.setenv("QADAM_DATA_KEY", "MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=")
    monkeypatch.setenv("GEMINI_API_KEY", "")
    return Settings()


def make_client(cfg, gemini=None):
    return TestClient(create_app(cfg, gemini=gemini, start_mqtt=False))


def login(c, cfg):
    r = c.post("/api/auth/login", json={"username": cfg.clinician_user, "password": cfg.clinician_password})
    assert r.status_code == 200
    return {"Authorization": f"Bearer {r.json()['token']}"}


def pair(c, cfg, **kw):
    r = c.post("/api/patient/pair", json={"code": cfg.demo_pairing_code, **kw})
    assert r.status_code == 200, r.text
    return {"Authorization": f"Bearer {r.json()['token']}"}, r.json()


def test_health_and_auth_required(cfg):
    with make_client(cfg) as c:
        assert c.get("/api/health").json()["ok"]
        assert c.get("/api/patients").status_code == 401
        assert c.post("/api/auth/login", json={"username": cfg.clinician_user, "password": "wrong"}).status_code == 401


def test_login_rate_limit(cfg):
    with make_client(cfg) as c:
        for _ in range(5):
            c.post("/api/auth/login", json={"username": "x", "password": "y"})
        assert c.post("/api/auth/login", json={"username": "x", "password": "y"}).status_code == 429


def test_synthetic_dataset_and_overview(cfg):
    with make_client(cfg) as c:
        h = login(c, cfg)
        pts = c.get("/api/patients", headers=h).json()
        assert len(pts) == 8
        assert pts[0]["ref"] == "QDM-1001" and pts[0]["open_alerts"]["red"] == 1  # red first in triage order
        assert all(p["synthetic"] for p in pts if p["ref"] != cfg.demo_patient)
        ov = c.get("/api/overview", headers=h).json()
        assert ov["alerts_open"]["red"] >= 2  # QDM-1001 foot + QDM-1004 low glucose
        assert ov["ai_configured"] is False
        # labels are encrypted at rest
        raw = c.app.state.db.one("SELECT label_enc FROM patients WHERE ref='QDM-1001'")["label_enc"]
        assert raw.startswith("enc1:") and "Patient A" not in raw


def test_full_patient_flow_amber_then_red_then_review(cfg):
    with make_client(cfg) as c:
        ph, info = pair(c, cfg)
        assert info["patient_ref"] == cfg.demo_patient and info["device_id"] == cfg.demo_device
        hot = {"left": {"mth1": 30.8}, "right": {"mth1": 33.6}, "samples": 4, "source": "hardware"}
        r1 = c.post("/api/patient/sync", headers=ph, json={"items": [{"type": "scan", "id": "s1", "app_level": "amber", **hot}]}).json()
        assert r1["results"]["s1"]["level"] == "amber" and r1["results"]["s1"]["mismatch"] is False
        r2 = c.post("/api/patient/sync", headers=ph, json={"items": [{"type": "scan", "id": "s2", "app_level": "red", **hot}]}).json()
        assert r2["results"]["s2"]["level"] == "red"  # demo mode: previous scan counts as yesterday
        # idempotent re-sync
        r3 = c.post("/api/patient/sync", headers=ph, json={"items": [{"type": "scan", "id": "s2", **hot}]}).json()
        assert r3["results"]["s2"]["alert_id"] == r2["results"]["s2"]["alert_id"]
        # clinician: 3 steps = open alert, decide, confirm
        h = login(c, cfg)
        aid = r2["results"]["s2"]["alert_id"]
        d = c.get(f"/api/alerts/{aid}", headers=h).json()
        assert d["alert"]["explanation"]["threshold_c"] == 2.2 and d["alert"]["explanation"]["consecutive_days"] == 2
        rv = c.post(f"/api/alerts/{aid}/review", headers=h, json={"decision": "confirmed", "note": "Consultation demain 9h"})
        assert rv.status_code == 200 and rv.json()["status"] == "confirmed"
        assert c.post(f"/api/alerts/{aid}/review", headers=h, json={"decision": "dismissed"}).status_code == 409
        # patient sees the clinician decision
        pa = c.get("/api/patient/alerts", headers=ph).json()
        seen = next(a for a in pa if a["id"] == aid)
        assert seen["status"] == "confirmed" and seen["review_note"] == "Consultation demain 9h" and "reviewer" not in seen
        # ack
        c.post("/api/patient/sync", headers=ph, json={"items": [{"type": "ack", "id": "ack1", "scan_id": "s2"}]})
        assert c.app.state.db.one("SELECT patient_ack_at FROM alerts WHERE id=?", (aid,))["patient_ack_at"]
        assert audit.verify(c.app.state.db)["ok"]


def test_sync_validation_and_consent(cfg):
    with make_client(cfg) as c:
        ph, _ = pair(c, cfg)
        r = c.post("/api/patient/sync", headers=ph, json={"items": [
            {"type": "scan", "id": "bad", "left": {"mth1": 80}, "right": {"mth1": 31}},
            {"type": "glucose", "id": "g1", "g_l": 0.62, "context": "fasting"},
            {"type": "glucose", "id": "g2", "g_l": 9.0},
            {"type": "nonsense", "id": "x"}]}).json()
        assert r["accepted"] == ["g1"]
        assert {x["id"] for x in r["rejected"]} == {"bad", "g2", "x"}
        assert r["results"]["g1"]["band"] == "low"
    with make_client(cfg) as c:
        ph2, _ = pair(c, cfg, share_with_care_team=False)
        assert c.post("/api/patient/sync", headers=ph2, json={"items": []}).status_code == 403


def test_assistant_without_ai_uses_rules_and_library(cfg):
    with make_client(cfg) as c:
        ph, _ = pair(c, cfg)
        r = c.post("/api/patient/assistant", headers=ph, json={"question": "عندي جرح تحت ساقي", "lang": "aeb"}).json()
        assert r["kind"] == "urgent" and r["source"] == "rules"
        r = c.post("/api/patient/assistant", headers=ph, json={"question": "نجم نمشي حافي في البحر؟", "lang": "aeb"}).json()
        assert r["kind"] == "answer" and r["source"] == "library" and r["topic"] == "barefoot"
        assert c.post("/api/patient/assistant", json={"question": "x", "lang": "fr"}).status_code == 401


def _gemini_transport(text):
    def handler(request: httpx.Request):
        assert request.headers["x-goog-api-key"] == "test-key"
        assert "key=" not in str(request.url)
        return httpx.Response(200, json={"candidates": [{"content": {"parts": [{"text": text}]}}]})
    return httpx.MockTransport(handler)


def test_assistant_with_mocked_gemini_and_output_guard(cfg):
    cfg.gemini_key = "test-key"
    g = ai.GeminiClient(cfg, transport=_gemini_transport("Non, évitez de marcher pieds nus. Portez des chaussures fermées."))
    with make_client(cfg, gemini=g) as c:
        ph, _ = pair(c, cfg)
        r = c.post("/api/patient/assistant", headers=ph, json={"question": "pieds nus à la plage ?", "lang": "fr"}).json()
        assert r["source"] == "gemini" and "IA" in r["label"]
    bad = ai.GeminiClient(cfg, transport=_gemini_transport("Augmentez votre dose de 4 UI ce soir."))
    with make_client(cfg, gemini=bad) as c:
        ph, _ = pair(c, cfg)
        r = c.post("/api/patient/assistant", headers=ph, json={"question": "insuline ce soir ?", "lang": "fr"}).json()
        assert r["source"] == "library"  # unsafe AI output never reaches the patient


def test_assistant_respects_ai_consent(cfg):
    cfg.gemini_key = "test-key"
    g = ai.GeminiClient(cfg, transport=_gemini_transport("Réponse IA"))
    with make_client(cfg, gemini=g) as c:
        ph, _ = pair(c, cfg, ai_assistant=False)
        r = c.post("/api/patient/assistant", headers=ph, json={"question": "pieds nus ?", "lang": "fr"}).json()
        assert r["source"] == "library"


def test_summary_review_fhir_audit(cfg):
    with make_client(cfg) as c:
        h = login(c, cfg)
        s = c.post("/api/patients/QDM-1001/summaries", headers=h).json()
        assert s["status"] == "draft" and s["source"] == "template" and "Scans plantaires" in s["narrative"]
        v = c.post(f"/api/summaries/{s['id']}/review", headers=h, json={"decision": "validated", "note": "ok"}).json()
        assert v["status"] == "validated"
        b = c.get("/fhir/Observation", params={"patient": "QDM-1001"}, headers=h)
        assert b.headers["content-type"].startswith("application/fhir+json")
        bundle = b.json()
        assert bundle["resourceType"] == "Bundle" and bundle["total"] > 10
        codes = {e["resource"]["code"]["coding"][0]["code"] for e in bundle["entry"]}
        assert codes == {"8310-5", "2339-0"}
        ver = c.get("/api/audit/verify", headers=h).json()
        assert ver["ok"] and ver["entries"] > 3
        # tampering is detected
        c.app.state.db.execute("UPDATE audit SET actor='mallory' WHERE id=2")
        assert c.get("/api/audit/verify", headers=h).json()["ok"] is False


def test_enroll_and_pair_new_patient(cfg):
    with make_client(cfg) as c:
        h = login(c, cfg)
        e = c.post("/api/patients", headers=h, json={"label": "M. B.", "birth_year": 1960, "diabetes_type": "t2"}).json()
        r = c.post("/api/patient/pair", json={"code": e["pairing_code"]})
        assert r.status_code == 200 and r.json()["patient_ref"] == e["ref"]
        assert c.post("/api/patient/pair", json={"code": "000000"}).status_code == 404


def test_erase_my_data(cfg):
    with make_client(cfg) as c:
        ph, info = pair(c, cfg)
        c.post("/api/patient/sync", headers=ph, json={"items": [{"type": "glucose", "id": "g1", "g_l": 1.1}]})
        assert c.delete("/api/patient/data", headers=ph).json()["ok"]
        assert c.app.state.db.one("SELECT COUNT(*) n FROM glucose WHERE patient_ref=?", (info["patient_ref"],))["n"] == 0
        assert c.get("/api/patient/me", headers=ph).status_code == 401  # token revoked


def test_security_headers_and_dashboard(cfg):
    with make_client(cfg) as c:
        r = c.get("/")
        assert r.status_code == 200 and "Qadam" in r.text
        assert r.headers["x-frame-options"] == "DENY" and "default-src 'self'" in r.headers["content-security-policy"]
