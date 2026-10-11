"""Append-only audit trail with a SHA-256 hash chain (tamper-evident: editing any past row breaks the chain)."""
from __future__ import annotations

import hashlib
import json

from .db import Database, now

GENESIS = "0" * 64


def _digest(prev: str, ts: float, actor: str, action: str, target: str, detail: str) -> str:
    payload = json.dumps([prev, round(ts, 3), actor, action, target, detail], ensure_ascii=False)
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def log(db: Database, actor: str, action: str, target: str = "", detail: str = "") -> None:
    with db.tx():
        last = db.one("SELECT hash FROM audit ORDER BY id DESC LIMIT 1")
        prev = last["hash"] if last else GENESIS
        ts = round(now(), 3)
        h = _digest(prev, ts, actor, action, target, detail)
        db.execute(
            "INSERT INTO audit(ts, actor, action, target, detail, prev_hash, hash) VALUES (?,?,?,?,?,?,?)",
            (ts, actor, action, target, detail, prev, h),
        )


def verify(db: Database) -> dict:
    prev = GENESIS
    rows = db.all("SELECT * FROM audit ORDER BY id")
    for r in rows:
        if r["prev_hash"] != prev or _digest(prev, r["ts"], r["actor"], r["action"], r["target"], r["detail"]) != r["hash"]:
            return {"ok": False, "entries": len(rows), "broken_at": r["id"]}
        prev = r["hash"]
    return {"ok": True, "entries": len(rows), "head": prev}
