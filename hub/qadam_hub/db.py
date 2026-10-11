"""SQLite persistence (single file, works offline). Only pseudonymised data is stored:
patients are identified by a reference such as QDM-2048; the clinic's display label is AES-encrypted."""
from __future__ import annotations

import json
import sqlite3
import threading
import time
from pathlib import Path
from typing import Any

SCHEMA = """
CREATE TABLE IF NOT EXISTS users (
  username TEXT PRIMARY KEY, pw_hash TEXT NOT NULL, role TEXT NOT NULL, display_name TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS sessions (
  token_hash TEXT PRIMARY KEY, username TEXT NOT NULL, expires_at REAL NOT NULL);
CREATE TABLE IF NOT EXISTS patients (
  ref TEXT PRIMARY KEY, label_enc TEXT, birth_year INTEGER, diabetes_type TEXT, foot_risk TEXT,
  consent_json TEXT, pairing_code TEXT, pairing_expires REAL, synthetic INTEGER DEFAULT 0,
  device_id TEXT, created_at REAL NOT NULL);
CREATE TABLE IF NOT EXISTS patient_tokens (
  token_hash TEXT PRIMARY KEY, patient_ref TEXT NOT NULL, created_at REAL NOT NULL);
CREATE TABLE IF NOT EXISTS devices (
  id TEXT PRIMARY KEY, patient_ref TEXT, source TEXT, sensor TEXT, state TEXT, detail TEXT,
  last_seen REAL, last_status_at REAL, last_frame_json TEXT, counters_json TEXT, port TEXT);
CREATE TABLE IF NOT EXISTS readings (
  id INTEGER PRIMARY KEY AUTOINCREMENT, device_id TEXT, patient_ref TEXT, ts REAL, source TEXT,
  left_json TEXT, right_json TEXT, spread_left REAL, spread_right REAL, seq INTEGER, faults_json TEXT);
CREATE INDEX IF NOT EXISTS idx_readings_dev_ts ON readings(device_id, ts);
CREATE TABLE IF NOT EXISTS scans (
  id TEXT PRIMARY KEY, patient_ref TEXT NOT NULL, ts REAL NOT NULL, source TEXT, origin TEXT,
  left_json TEXT, right_json TEXT, dt_json TEXT, max_dt REAL, site TEXT, warmer_side TEXT, level TEXT,
  consecutive_days INTEGER, confidence INTEGER, confidence_label TEXT, factors_json TEXT,
  samples INTEGER, app_level TEXT, mismatch INTEGER DEFAULT 0);
CREATE INDEX IF NOT EXISTS idx_scans_patient_ts ON scans(patient_ref, ts);
CREATE TABLE IF NOT EXISTS alerts (
  id INTEGER PRIMARY KEY AUTOINCREMENT, patient_ref TEXT NOT NULL, scan_id TEXT, kind TEXT NOT NULL,
  level TEXT NOT NULL, created_at REAL NOT NULL, title TEXT, explanation_json TEXT, source TEXT,
  status TEXT NOT NULL DEFAULT 'open', reviewer TEXT, review_note_enc TEXT, reviewed_at REAL,
  patient_ack_at REAL);
CREATE TABLE IF NOT EXISTS glucose (
  id TEXT PRIMARY KEY, patient_ref TEXT NOT NULL, ts REAL NOT NULL, g_l REAL NOT NULL, context TEXT,
  band TEXT, source TEXT);
CREATE INDEX IF NOT EXISTS idx_glucose_patient_ts ON glucose(patient_ref, ts);
CREATE TABLE IF NOT EXISTS adherence (
  patient_ref TEXT NOT NULL, day TEXT NOT NULL, planned INTEGER, taken INTEGER, source TEXT,
  PRIMARY KEY (patient_ref, day));
CREATE TABLE IF NOT EXISTS summaries (
  id INTEGER PRIMARY KEY AUTOINCREMENT, patient_ref TEXT NOT NULL, created_at REAL NOT NULL,
  period_days INTEGER, facts_json TEXT, narrative_enc TEXT, source TEXT, model TEXT,
  status TEXT NOT NULL DEFAULT 'draft', reviewer TEXT, review_note_enc TEXT, reviewed_at REAL);
CREATE TABLE IF NOT EXISTS audit (
  id INTEGER PRIMARY KEY AUTOINCREMENT, ts REAL NOT NULL, actor TEXT, action TEXT, target TEXT,
  detail TEXT, prev_hash TEXT, hash TEXT);
"""


class Database:
    def __init__(self, path: Path) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        self.path = path
        self._lock = threading.RLock()
        self._conn = sqlite3.connect(str(path), check_same_thread=False, isolation_level=None)
        self._conn.row_factory = sqlite3.Row
        self._conn.execute("PRAGMA journal_mode=WAL")
        self._conn.execute("PRAGMA foreign_keys=ON")
        self._conn.executescript(SCHEMA)

    def execute(self, sql: str, params: tuple | list = ()) -> sqlite3.Cursor:
        with self._lock:
            return self._conn.execute(sql, params)

    def all(self, sql: str, params: tuple | list = ()) -> list[dict[str, Any]]:
        with self._lock:
            return [dict(r) for r in self._conn.execute(sql, params).fetchall()]

    def one(self, sql: str, params: tuple | list = ()) -> dict[str, Any] | None:
        with self._lock:
            r = self._conn.execute(sql, params).fetchone()
            return dict(r) if r else None

    def tx(self):
        return _Tx(self)

    def close(self) -> None:
        with self._lock:
            self._conn.close()


class _Tx:
    def __init__(self, db: Database) -> None:
        self.db = db

    def __enter__(self):
        self.db._lock.acquire()
        self.db._conn.execute("BEGIN")
        return self.db

    def __exit__(self, exc_type, exc, tb):
        try:
            self.db._conn.execute("ROLLBACK" if exc_type else "COMMIT")
        finally:
            self.db._lock.release()
        return False


def jdump(x: Any) -> str:
    return json.dumps(x, ensure_ascii=False, separators=(",", ":"))


def jload(x: str | None, default: Any = None) -> Any:
    if not x:
        return default
    try:
        return json.loads(x)
    except ValueError:
        return default


def now() -> float:
    return time.time()
