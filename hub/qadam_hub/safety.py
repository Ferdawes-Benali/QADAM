"""Deterministic safety layer for the assistant: red-flag triage + verified answer library.

Runs BEFORE any language model. Mirrors app/lib/services/safety_service.dart (same JSON files).
"""
from __future__ import annotations

import json
import re
import unicodedata
from dataclasses import dataclass
from functools import lru_cache

from .config import SHARED_DIR

LANGS = ("fr", "ar", "aeb")
_TASHKEEL = re.compile(r"[ؐ-ًؚ-ٰٟۖ-ۭـ]")


def normalize(text: str) -> str:
    t = text.lower()
    t = _TASHKEEL.sub("", t)
    t = t.replace("أ", "ا").replace("إ", "ا").replace("آ", "ا").replace("ة", "ه").replace("ى", "ي")
    t = "".join(c for c in unicodedata.normalize("NFD", t) if unicodedata.category(c) != "Mn")
    t = t.replace("’", "'")
    return re.sub(r"\s+", " ", t).strip()


@lru_cache(maxsize=1)
def red_flags() -> dict:
    data = json.loads((SHARED_DIR / "red_flags.json").read_text(encoding="utf-8"))
    for r in data["rules"]:
        r["_norm"] = [normalize(k) for k in r["keywords"]]
    return data


@lru_cache(maxsize=1)
def library() -> dict:
    data = json.loads((SHARED_DIR / "assistant_library.json").read_text(encoding="utf-8"))
    for t in data["topics"]:
        t["_norm"] = [normalize(k) for lang in LANGS for k in t["keywords"].get(lang, [])]
    return data


@dataclass
class Triage:
    tier: str  # emergency | urgent
    rule_id: str
    text: str


def triage(question: str, lang: str) -> Triage | None:
    q = normalize(question)
    data = red_flags()
    hits = [r for r in data["rules"] if any(k in q for k in r["_norm"])]
    if not hits:
        return None
    hits.sort(key=lambda r: 0 if r["tier"] == "emergency" else 1)
    top = hits[0]
    return Triage(top["tier"], top["id"], data["tiers"][top["tier"]][_lang(lang)])


def library_answer(question: str, lang: str) -> tuple[str | None, str]:
    """Return (topic_id or None, answer text in the requested language)."""
    q = normalize(question)
    lib = library()
    best, score = None, 0
    for t in lib["topics"]:
        s = sum(len(k) for k in t["_norm"] if k and k in q)
        if s > score:
            best, score = t, s
    if best is None:
        return None, lib["fallback"][_lang(lang)]
    return best["id"], best["answer"][_lang(lang)]


def grounding_text(lang: str) -> str:
    lib = library()
    return "\n".join(f"- [{t['id']}] {t['answer']['fr']}" for t in lib["topics"])


def _lang(lang: str) -> str:
    return lang if lang in LANGS else "fr"
