"""Minimal HL7 FHIR R4 export (read-only) so the hub can later feed a hospital information system (SIH).

Mappings (to be validated with an interoperability specialist before real use):
  foot scan  -> Observation, LOINC 8310-5 "Body temperature", components per side, plus the left/right difference
  glucose    -> Observation, LOINC 2339-0 "Glucose [Mass/volume] in Blood", unit g/L (UCUM)
"""
from __future__ import annotations

from datetime import datetime, timezone

from .db import Database, jload

SNOMED_LEFT_FOOT = ("22335008", "Left foot structure")
SNOMED_RIGHT_FOOT = ("7769000", "Right foot structure")


def _iso(ts: float) -> str:
    return datetime.fromtimestamp(ts, tz=timezone.utc).isoformat()


def patient(p: dict) -> dict:
    return {
        "resourceType": "Patient",
        "id": p["ref"],
        "identifier": [{"system": "urn:qadam:patient-ref", "value": p["ref"]}],
        "birthDate": str(p["birth_year"]) if p.get("birth_year") else None,
        "meta": {"tag": [{"system": "urn:qadam:data", "code": "synthetic" if p.get("synthetic") else "pseudonymised"}]},
    }


def _qty(v: float, unit: str, code: str) -> dict:
    return {"value": round(v, 2), "unit": unit, "system": "http://unitsofmeasure.org", "code": code}


def scan_observation(s: dict) -> dict:
    left, right = jload(s["left_json"], {}), jload(s["right_json"], {})
    site = s["site"]
    interp = {"green": "N", "amber": "A", "red": "AA"}[s["level"]]
    return {
        "resourceType": "Observation",
        "id": f"scan-{s['id']}",
        "status": "preliminary",
        "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "vital-signs"}]}],
        "code": {"coding": [{"system": "http://loinc.org", "code": "8310-5", "display": "Body temperature"}],
                 "text": "Plantar skin temperature, contralateral comparison (Qadam prototype)"},
        "subject": {"reference": f"Patient/{s['patient_ref']}"},
        "effectiveDateTime": _iso(s["ts"]),
        "device": {"display": f"Qadam {s['source']} sensor"},
        "interpretation": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation", "code": interp}],
                            "text": f"Qadam level {s['level']} (confidence {s['confidence']}/100)"}],
        "note": [{"text": "Prototype measurement, not a validated medical device. Decision support only."}],
        "component": [
            {"code": {"text": f"Left foot {site}"},
             "bodySite": {"coding": [{"system": "http://snomed.info/sct", "code": SNOMED_LEFT_FOOT[0], "display": SNOMED_LEFT_FOOT[1]}]},
             "valueQuantity": _qty(left.get(site, 0.0), "Cel", "Cel")},
            {"code": {"text": f"Right foot {site}"},
             "bodySite": {"coding": [{"system": "http://snomed.info/sct", "code": SNOMED_RIGHT_FOOT[0], "display": SNOMED_RIGHT_FOOT[1]}]},
             "valueQuantity": _qty(right.get(site, 0.0), "Cel", "Cel")},
            {"code": {"text": "Absolute left/right difference"}, "valueQuantity": _qty(s["max_dt"], "Cel", "Cel")},
        ],
    }


def glucose_observation(g: dict) -> dict:
    return {
        "resourceType": "Observation",
        "id": f"glucose-{g['id']}",
        "status": "final",
        "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "laboratory"}]}],
        "code": {"coding": [{"system": "http://loinc.org", "code": "2339-0", "display": "Glucose [Mass/volume] in Blood"}]},
        "subject": {"reference": f"Patient/{g['patient_ref']}"},
        "effectiveDateTime": _iso(g["ts"]),
        "valueQuantity": _qty(g["g_l"], "g/L", "g/L"),
        "note": [{"text": f"Self-measured ({g['context']}), source: {g['source']}"}],
    }


def observation_bundle(db: Database, patient_ref: str, limit: int = 200) -> dict:
    scans = db.all("SELECT * FROM scans WHERE patient_ref=? ORDER BY ts DESC LIMIT ?", (patient_ref, limit))
    gl = db.all("SELECT * FROM glucose WHERE patient_ref=? ORDER BY ts DESC LIMIT ?", (patient_ref, limit))
    entries = [scan_observation(s) for s in scans] + [glucose_observation(g) for g in gl]
    return {"resourceType": "Bundle", "type": "searchset", "total": len(entries),
            "entry": [{"fullUrl": f"urn:qadam:{e['id']}", "resource": e} for e in entries]}
