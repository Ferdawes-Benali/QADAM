import json
from datetime import date, timedelta
from pathlib import Path

import pytest

from qadam_hub import rule, safety

VECTORS = json.loads((Path(__file__).resolve().parents[2] / "shared" / "rule_vectors.json").read_text(encoding="utf-8"))


@pytest.mark.parametrize("case", VECTORS["cases"], ids=[c["name"] for c in VECTORS["cases"]])
def test_rule_vectors(case):
    today = date(2026, 10, 11)
    hist = [rule.PastScan(today - timedelta(days=h["days_ago"]), h["dt"]) for h in case["history"]]
    r = rule.evaluate(case["left"], case["right"], hist, today, demo=case["demo"],
                      samples=case.get("samples", 4), spread_left=case.get("spread_left", 0.0),
                      spread_right=case.get("spread_right", 0.0))
    exp = case["expect"]
    if exp.get("invalid"):
        assert r is None
        return
    assert r is not None
    for key, value in exp.items():
        assert getattr(r, key) == value, f"{key}: {getattr(r, key)} != {value}"


def test_threshold_constant_matches_vectors():
    assert VECTORS["threshold_c"] == rule.THRESHOLD_C


@pytest.mark.parametrize("q,lang,tier", [
    ("My foot is black and smells", "fr", "urgent"),
    ("J'ai une plaie sous le pied", "fr", "urgent"),
    ("عندي جرح في ساقي", "aeb", "urgent"),
    ("صُبعي ولّات كحلة", "aeb", "urgent"),
    ("j'ai une douleur dans la poitrine", "fr", "emergency"),
    ("بابا طاح وما فاقش", "aeb", "emergency"),
])
def test_red_flags(q, lang, tier):
    t = safety.triage(q, lang)
    assert t is not None and t.tier == tier
    assert "190" in t.text


@pytest.mark.parametrize("q", ["نجم نمشي حافي في البحر؟", "Puis-je marcher pieds nus ?", "شنوة الحمية متاع السكر؟", "Quelle alimentation ?"])
def test_no_false_alarm_on_normal_questions(q):
    assert safety.triage(q, "fr") is None


@pytest.mark.parametrize("q,lang,topic", [
    ("نجم نمشي حافي في البحر؟", "aeb", "barefoot"),
    ("Can I double my insulin tonight? doubler la dose d'insuline", "fr", "treatment_change"),
    ("Est-ce que je peux faire le ramadan ?", "fr", "ramadan"),
    ("شنوة معناها الفرق في السخانه؟", "aeb", "qadam_result"),
])
def test_library_topics(q, lang, topic):
    tid, text = safety.library_answer(q, lang)
    assert tid == topic
    assert text


def test_library_fallback():
    tid, text = safety.library_answer("quel temps fera-t-il demain", "fr")
    assert tid is None and "médecin" in text


def test_every_topic_has_three_languages():
    for t in safety.library()["topics"]:
        assert set(t["answer"]) == {"fr", "ar", "aeb"}
        assert all(t["keywords"].get(lang) for lang in ("fr", "ar", "aeb"))
