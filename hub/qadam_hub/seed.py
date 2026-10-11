"""Synthetic demonstration dataset. Every record is tagged source='synthetic' and every patient synthetic=1.
No real patient data is used anywhere in Qadam."""
from __future__ import annotations

import random
from datetime import date, datetime, timedelta

from . import audit, domain
from .config import Settings
from .crypto import FieldCipher, hash_password
from .db import Database, jdump, now

PATIENTS = [
    # ref, label, birth_year, type, risk, scenario
    ("QDM-1001", "Patient A (synthétique)", 1958, "t2", "high", "red_today"),
    ("QDM-1002", "Patient B (synthétique)", 1966, "t2", "moderate", "amber_today"),
    ("QDM-1003", "Patient C (synthétique)", 1974, "t2", "low", "stable"),
    ("QDM-1004", "Patient D (synthétique)", 1989, "t1", "moderate", "lows"),
    ("QDM-1005", "Patient E (synthétique)", 1961, "t2", "moderate", "high_glucose"),
    ("QDM-1006", "Patient F (synthétique)", 1952, "t2", "high", "red_last_week_reviewed"),
    ("QDM-1007", "Patient G (synthétique)", 1970, "t2", "low", "new"),
]


def _at(day: date, hour: int, minute: int) -> float:
    """Timestamp on `day` at hour:minute, but never in the future (today's records stay before 'now')."""
    ts = datetime(day.year, day.month, day.day, hour, minute).timestamp()
    if ts > now() - 600:
        ts = now() - 600 - (14 - min(hour, 14)) * 900
    return ts


def ensure_users(db: Database, cfg: Settings) -> None:
    if not db.one("SELECT username FROM users WHERE username=?", (cfg.clinician_user,)):
        db.execute("INSERT INTO users(username, pw_hash, role, display_name) VALUES (?,?,?,?)",
                   (cfg.clinician_user, hash_password(cfg.clinician_password), "clinician", "Dr Démo (compte de démonstration)"))


def ensure_demo_patient(db: Database, cipher: FieldCipher, cfg: Settings) -> None:
    if db.one("SELECT ref FROM patients WHERE ref=?", (cfg.demo_patient,)):
        return
    db.execute(
        "INSERT INTO patients(ref, label_enc, birth_year, diabetes_type, foot_risk, consent_json, pairing_code,"
        " pairing_expires, synthetic, device_id, created_at) VALUES (?,?,?,?,?,?,?,?,?,?,?)",
        (cfg.demo_patient, cipher.encrypt("Patient démo (banc Qadam)"), 1963, "t2", "high", jdump({}),
         cfg.demo_pairing_code, now() + 365 * 86400, 0, cfg.demo_device, now()),
    )
    db.execute("INSERT INTO devices(id, patient_ref, state) VALUES (?,?,?) ON CONFLICT(id) DO UPDATE SET patient_ref=excluded.patient_ref",
               (cfg.demo_device, cfg.demo_patient, "unknown"))


def seed(db: Database, cipher: FieldCipher, cfg: Settings) -> bool:
    ensure_users(db, cfg)
    ensure_demo_patient(db, cipher, cfg)
    if db.one("SELECT ref FROM patients WHERE synthetic=1 LIMIT 1"):
        return False
    rnd = random.Random(2048)
    today = date.today()
    for ref, label, by, dtype, risk, scenario in PATIENTS:
        db.execute(
            "INSERT INTO patients(ref, label_enc, birth_year, diabetes_type, foot_risk, consent_json, synthetic, created_at)"
            " VALUES (?,?,?,?,?,?,?,?)",
            (ref, cipher.encrypt(label), by, dtype, risk,
             jdump({"share_with_care_team": True, "ai_assistant": True, "synthetic": True}), 1, now()),
        )
        n_days = 3 if scenario == "new" else 21
        for back in range(n_days - 1, -1, -1):
            day = today - timedelta(days=back)
            if scenario == "high_glucose" and back % 3 == 1:
                continue  # irregular use
            base = 29.6 + rnd.uniform(-0.8, 0.8)
            dts = {"hallux": rnd.uniform(-0.4, 0.4), "mth1": rnd.uniform(-0.4, 0.4),
                   "mth5": rnd.uniform(-0.4, 0.4), "heel": rnd.uniform(-0.4, 0.4)}
            if scenario == "red_today" and back <= 1:
                dts["mth1"] = 2.6 if back == 1 else 2.9
            if scenario == "amber_today" and back == 0:
                dts["heel"] = -2.4
            if scenario == "red_last_week_reviewed" and back in (8, 7):
                dts["mth5"] = 2.5 if back == 8 else 2.7
            left = {s: round(base + rnd.uniform(-0.6, 0.6), 2) for s in dts}
            right = {s: round(left[s] + d, 2) for s, d in dts.items()}
            domain.record_scan(db, cipher, ref, {
                "id": f"syn-{ref}-{day.isoformat()}", "ts": _at(day, 8, rnd.randint(0, 40)), "left": left, "right": right,
                "samples": 4, "spread_left": round(rnd.uniform(0.0, 0.25), 2), "spread_right": round(rnd.uniform(0.0, 0.25), 2),
                "source": "synthetic"}, cfg, origin="synthetic", demo=False)
            # glucose: fasting + after a meal
            mean = {"lows": 1.05, "high_glucose": 2.05}.get(scenario, 1.20)
            for hour, ctx, shift in ((7, "fasting", 0.0), (14, "after_meal", 0.35)):
                g = max(0.45, rnd.gauss(mean + shift, 0.22))
                if scenario == "lows" and back in (2, 10) and ctx == "fasting":
                    g = 0.58
                domain.record_glucose(db, ref, {"id": f"syn-g-{ref}-{day.isoformat()}-{hour}", "ts": _at(day, hour, 15),
                                                "g_l": round(g, 2), "context": ctx}, source="synthetic")
            planned = 2
            taken = 2 if rnd.random() < (0.55 if scenario == "high_glucose" else 0.92) else 1
            domain.record_adherence(db, ref, {"day": day.isoformat(), "planned": planned, "taken": taken}, source="synthetic")
    # Human-in-the-loop history: last week's red alert for QDM-1006 was reviewed and confirmed.
    a = db.one("SELECT id FROM alerts WHERE patient_ref='QDM-1006' AND level='red' ORDER BY created_at LIMIT 1")
    if a:
        db.execute("UPDATE alerts SET status='confirmed', reviewer=?, review_note_enc=?, reviewed_at=? WHERE id=?",
                   (cfg.clinician_user, cipher.encrypt("Vu en consultation : inflammation MTH5 droite, décharge prescrite."),
                    now() - 6 * 86400, a["id"]))
        db.execute("UPDATE alerts SET status='confirmed', reviewer=?, reviewed_at=? WHERE patient_ref='QDM-1006' AND status='open' AND kind='foot'",
                   (cfg.clinician_user, now() - 6 * 86400))
    # Older synthetic alerts were already handled by the care team (realistic queue: only recent ones stay open).
    cutoff = now() - 2.5 * 86400
    db.execute("UPDATE alerts SET status='dismissed', reviewer=?, review_note_enc=?, reviewed_at=created_at+3600"
               " WHERE status='open' AND source='synthetic' AND created_at < ?",
               (cfg.clinician_user, cipher.encrypt("Revu (historique synthétique)."), cutoff))
    # Demo patient: 7 days of synthetic green history so the live scans have context.
    for back in range(7, 0, -1):
        day = today - timedelta(days=back)
        left = {"mth1": round(29.8 + rnd.uniform(-0.5, 0.5), 2)}
        right = {"mth1": round(left["mth1"] + rnd.uniform(-0.3, 0.3), 2)}
        domain.record_scan(db, cipher, cfg.demo_patient, {"id": f"syn-{cfg.demo_patient}-{day.isoformat()}",
                           "ts": _at(day, 8, 10), "left": left, "right": right, "source": "synthetic"},
                           cfg, origin="synthetic", demo=False)
        domain.record_glucose(db, cfg.demo_patient, {"id": f"syn-g-demo-{day.isoformat()}", "ts": _at(day, 7, 30),
                              "g_l": round(rnd.gauss(1.25, 0.15), 2), "context": "fasting"}, source="synthetic")
    audit.log(db, "system", "seed_synthetic_data", "", f"{len(PATIENTS)} synthetic patients")
    return True
