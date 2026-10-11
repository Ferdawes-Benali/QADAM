"""Qadam foot-temperature rule (deterministic, explainable, no AI).

Clinical basis (for skin temperature measured with validated thermometers):
a contralateral difference >= 2.2 C at the same plantar site, on two consecutive
days, is the warning sign used in home temperature-monitoring trials
(Lavery 2004/2007, Armstrong 2007) and in the IWGDF 2023 prevention guideline.

Levels
  green : max dT < 2.2 C
  amber : max dT >= 2.2 C today only
  red   : max dT >= 2.2 C at the SAME site on the previous calendar day too
          (demo mode: the previous scan counts as "yesterday")

Confidence index (0-100) = how reliable THIS measurement is, not a probability of disease:
  samples   min(1, n/4)                         -> enough readings in the 10 s window
  stability clamp(1 - (spread-0.3)/0.7, .2, 1)  -> sensors were stable (spread = max-min in window)
  margin    0.5 + 0.5*clamp(|dT-2.2|/0.5, 0, 1) -> far from the threshold = clearer decision
The same rule lives in app/lib/services/foot_rule.dart; shared/rule_vectors.json keeps both identical.
"""
from __future__ import annotations

import math
from dataclasses import dataclass, field
from datetime import date

THRESHOLD_C = 2.2
PLAUSIBLE_MIN_C = 10.0
PLAUSIBLE_MAX_C = 45.0


def round2(x: float) -> float:
    return math.floor(x * 100 + 0.5) / 100


def _clamp(x: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, x))


@dataclass
class PastScan:
    day: date
    dt: dict[str, float]


@dataclass
class RuleResult:
    level: str
    max_dt: float
    site: str
    warmer_side: str
    dt: dict[str, float]
    consecutive_days: int
    confidence: int
    confidence_label: str
    factors: dict[str, float] = field(default_factory=dict)

    def explanation(self) -> dict:
        """Triggering parameters shown to patient and clinician (XAI)."""
        return {
            "rule": f"|left - right| at the same site >= {THRESHOLD_C} C on 2 consecutive days",
            "max_dt_c": self.max_dt,
            "site": self.site,
            "warmer_side": self.warmer_side,
            "threshold_c": THRESHOLD_C,
            "consecutive_days": self.consecutive_days,
            "per_site_dt_c": self.dt,
            "confidence": self.confidence,
            "confidence_label": self.confidence_label,
            "confidence_factors": self.factors,
        }


def confidence(max_dt: float, samples: int = 4, spread_left: float = 0.0, spread_right: float = 0.0):
    s = min(1.0, samples / 4.0)
    spread = max(spread_left, spread_right)
    st = _clamp(1 - (spread - 0.3) / 0.7, 0.2, 1.0)
    m = 0.5 + 0.5 * _clamp(abs(max_dt - THRESHOLD_C) / 0.5, 0.0, 1.0)
    value = int(math.floor(100 * s * st * m + 0.5))
    label = "high" if value >= 75 else ("medium" if value >= 50 else "low")
    return value, label, {"samples": round2(s), "stability": round2(st), "margin": round2(m)}


def evaluate(
    left: dict[str, float],
    right: dict[str, float],
    history: list[PastScan],
    today: date,
    demo: bool = False,
    samples: int = 4,
    spread_left: float = 0.0,
    spread_right: float = 0.0,
) -> RuleResult | None:
    """Return None when the input is not a valid scan (missing side or implausible value)."""
    if not left or not right:
        return None
    for v in list(left.values()) + list(right.values()):
        if v is None or not (PLAUSIBLE_MIN_C <= float(v) <= PLAUSIBLE_MAX_C):
            return None
    dt = {s: round2(abs(float(left[s]) - float(right[s]))) for s in left if s in right}
    if not dt:
        return None
    site = max(dt, key=lambda k: dt[k])
    max_dt = dt[site]
    warmer = "left" if float(left[site]) > float(right[site]) else "right"

    level, days = "green", 0
    if max_dt >= THRESHOLD_C:
        level, days = "amber", 1
        prev = _previous(history, today, demo)
        if prev is not None and prev.dt.get(site, 0.0) >= THRESHOLD_C:
            level, days = "red", 2

    conf, label, factors = confidence(max_dt, samples, spread_left, spread_right)
    return RuleResult(level, max_dt, site, warmer, dt, days, conf, label, factors)


def _previous(history: list[PastScan], today: date, demo: bool) -> PastScan | None:
    if not history:
        return None
    if demo:
        return history[-1]
    yesterday = date.fromordinal(today.toordinal() - 1)
    same = [h for h in history if h.day == yesterday]
    return same[-1] if same else None
