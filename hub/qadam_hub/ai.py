"""Assistant + clinician summary. The API key stays on the hub (never in the mobile app).

Pipeline for a patient question:
  1. deterministic red-flag triage (safety.triage)       -> fixed emergency/urgent message, no AI
  2. Gemini, grounded on the verified library + context    -> labelled "AI-generated"
  3. if no key / network error / unsafe output: verified library answer -> labelled "Qadam library"
"""
from __future__ import annotations

import logging
import re

import httpx

from . import safety
from .config import Settings

log = logging.getLogger("qadam.ai")

LANG_NAMES = {
    "aeb": "Tunisian Arabic (Derja) written in Arabic script, simple everyday words",
    "ar": "simple Modern Standard Arabic",
    "fr": "simple French",
}

SYSTEM = """You are the Qadam assistant for adults living with diabetes in Tunisia. Answer in {lang}.
Hard rules:
- You give general education only. You never diagnose and never interpret a result as a diagnosis.
- Never start, stop or change a medication or insulin dose: say to ask the doctor.
- For danger signs (wound, black or very red/hot/swollen foot, fever, chest pain, confusion, glucose < 0.70 g/L
  with confusion) tell the person to call SAMU 190 or go to the emergency department.
- Max 4 short sentences. No markdown, no lists, no tables.
- Use ONLY the reference below and widely accepted diabetes education. If unsure, say so and suggest the doctor.
- Measurements from Qadam come from a prototype, not a medical device: never present them as clinically validated.
REFERENCE (verified Qadam library, French):
{reference}
"""

# Output guard: phrases an answer must not contain (dose instructions, diagnoses).
_UNSAFE = re.compile(
    r"(\b\d+\s*(ui|unit[ée]s?|units?)\b)|(augmente[rz]? (votre|ta|la) dose)|(double[rz]? (votre|ta|la) dose)|"
    r"(vous avez (une|un) (infection|ulc[eè]re|ost[ée]ite|charcot))|(increase your dose)",
    re.IGNORECASE,
)


class GeminiClient:
    def __init__(self, cfg: Settings, transport: httpx.AsyncBaseTransport | None = None) -> None:
        self.cfg = cfg
        self._transport = transport

    @property
    def configured(self) -> bool:
        return bool(self.cfg.gemini_key)

    async def generate(self, system: str, user: str, max_tokens: int = 350) -> str:
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{self.cfg.gemini_model}:generateContent"
        body = {
            "systemInstruction": {"parts": [{"text": system}]},
            "contents": [{"role": "user", "parts": [{"text": user}]}],
            "generationConfig": {"temperature": 0.2, "maxOutputTokens": max_tokens},
        }
        async with httpx.AsyncClient(timeout=15.0, transport=self._transport) as client:
            r = await client.post(url, json=body, headers={"x-goog-api-key": self.cfg.gemini_key})
        if r.status_code != 200:
            raise RuntimeError(f"Gemini HTTP {r.status_code}")
        data = r.json()
        parts = (data.get("candidates") or [{}])[0].get("content", {}).get("parts", [])
        text = "".join(p.get("text", "") for p in parts).strip()
        if not text:
            raise RuntimeError("Gemini returned no text")
        return text


class _NoAI:
    configured = False


NO_AI = _NoAI()


def _context_text(ctx: dict | None) -> str:
    if not ctx:
        return "No personal data shared by the patient."
    out = []
    if ctx.get("diabetes_type"):
        out.append(f"Diabetes type: {ctx['diabetes_type']}.")
    s = ctx.get("last_scan")
    if isinstance(s, dict) and s.get("level"):
        out.append(f"Last Qadam foot scan: level {s.get('level')}, max left/right difference {s.get('max_dt')} C at {s.get('site')} "
                   "(prototype sensor).")
    g = ctx.get("last_glucose")
    if isinstance(g, dict) and g.get("g_l"):
        out.append(f"Last glucose: {g.get('g_l')} g/L ({g.get('context')}).")
    return " ".join(out) or "No personal data shared by the patient."


async def answer(question: str, lang: str, ctx: dict | None, client: GeminiClient) -> dict:
    question = (question or "").strip()[:500]
    lang = lang if lang in safety.LANGS else "fr"
    base = {"lang": lang, "question": question}
    t = safety.triage(question, lang)
    if t:
        return {**base, "kind": t.tier, "source": "rules", "rule_id": t.rule_id, "text": t.text,
                "label": "Message de sécurité prédéfini (pas d'IA)"}
    topic, lib_text = safety.library_answer(question, lang)
    if client.configured:
        try:
            system = SYSTEM.format(lang=LANG_NAMES[lang], reference=safety.grounding_text(lang))
            user = f"Context: {_context_text(ctx)}\nQuestion: {question}"
            text = await client.generate(system, user)
            if _UNSAFE.search(text):
                log.warning("AI answer blocked by output guard")
            else:
                return {**base, "kind": "answer", "source": "gemini", "model": client.cfg.gemini_model,
                        "topic": topic, "text": text,
                        "label": "Réponse générée par IA — informative, non validée médicalement"}
        except Exception as e:  # network down, quota, bad key: fall back, never fake an AI answer
            log.warning("Gemini unavailable: %s", e)
    return {**base, "kind": "answer", "source": "library", "topic": topic, "text": lib_text,
            "label": "Bibliothèque Qadam vérifiée (sans IA)"}


async def clinician_narrative(facts: dict, template: str, client: GeminiClient) -> tuple[str, str, str | None]:
    """Returns (text, source, model). The AI only rephrases deterministic facts; template is the fallback."""
    if not client.configured:
        return template, "template", None
    system = ("Tu rédiges pour un médecin une synthèse factuelle en français, 5 lignes maximum. "
              "Utilise UNIQUEMENT les faits fournis, sans interprétation diagnostique ni conseil thérapeutique. "
              "Signale les éléments qui méritent l'attention du médecin. Pas de markdown.")
    try:
        text = await client.generate(system, f"Faits (JSON) : {facts}\nRésumé déterministe : {template}", 300)
        if _UNSAFE.search(text):
            return template, "template", None
        return text, "gemini", client.cfg.gemini_model
    except Exception as e:
        log.warning("Gemini unavailable for summary: %s", e)
        return template, "template", None
