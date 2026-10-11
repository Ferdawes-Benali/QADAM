# Architecture

## Data flow

```
 ┌───────────── bench (prototype) ─────────────┐
 │ DHT22 LEFT  (D2) ─┐                          │
 │ DHT22 RIGHT (D3) ─┴─ Arduino Uno             │   measures + averages 4 readings (10 s window)
 │                     LED D5 ok / D6 fault     │   never decides green/amber/red
 └──────────────┬──────────────────────────────┘
                │ USB serial 115200: $QDM,1,seq,tL,tR,spreadL,spreadR,n,hL,hR,flags*CRC8
                ▼
 bridge/qadam_bridge.py  ── CRC check, format check, sensor faults, sequence gaps, "source" label
                │ MQTT qadam/bench-01/live   (QoS 1, retained)   + qadam/bench-01/status (health, last will)
                ▼
 MQTT broker (Mosquitto, or the hub's embedded broker)
        │                                        │
        ▼                                        ▼
 Patient app (Flutter)                        Hub (FastAPI)
  · live L/R view, staleness, faults            · ingests frames (validation, device state, 24 h buffer)
  · 10 s scan → FootRule (on device)            · re-evaluates every scan with rule.py (reference)
  · encrypted Hive storage                      · alerts + explanations + confidence
  · offline outbox ── HTTP sync ──────────────► · clinician review (confirm / dismiss), audit chain
  · assistant: rules → hub AI → library  ─────► · AI proxy (Gemini key stays here)
  · alerts + clinician decisions  ◄──────────── · FHIR R4 export, clinician dashboard (static/)
```

## Layers (cahier des charges §5 — séparation stricte)

| Layer | Patient side | Care-team side |
| --- | --- | --- |
| Presentation | `app/lib/features/*`, `widgets/` | `hub/static/` (dashboard) |
| Business logic | `services/foot_rule.dart`, `services/safety_service.dart`, `state/app_state.dart` | `rule.py`, `domain.py`, `safety.py` |
| Inference (optional) | none on the phone | `ai.py` (Gemini REST, output guard) |
| Data | Hive boxes, AES-256 (`storage_service.dart`) | SQLite (`db.py`), AES-256-GCM fields (`crypto.py`), audit hash chain (`audit.py`) |
| Telemetry | `mqtt_service.dart` | `telemetry.py` |

## Key decisions

1. **Detection is a deterministic, published rule, not a model.** It is explainable (temperatures, site, threshold,
   persistence), testable (`shared/rule_vectors.json` runs in Python *and* Dart) and does not depend on data we do
   not have. AI is only used for language (education, summaries).
2. **Decision support, human in the loop.** Every amber/red alert lands in the clinician queue; the clinician
   confirms or dismisses it in three steps and the patient sees the decision and note. The smart-mat study that
   used the same 2.2 °C threshold reported 97 % sensitivity but a 57 % false-positive rate (Frykberg 2017): the
   persistence rule, the confidence index and clinician review exist to handle that.
3. **Firmware measures, software decides.** Thresholds and logic can change without re-flashing; the board only
   reports values, faults and stability.
4. **Two independent evaluations.** The app evaluates instantly (works offline); the hub re-evaluates every synced
   scan with its own history and flags any disagreement (`mismatch`).
5. **Integrity at every hop.** CRC-8 on serial frames, schema/range validation at the bridge, the app and the hub,
   explicit `source` (`hardware` / `simulated` / `synthetic`), staleness after 15 s, faults never interpolated.
6. **Local-first and degraded mode.** The phone works without network (encrypted outbox, verified answer library);
   the hub works without internet (SQLite, vendored assets, embedded broker option); the AI is optional.
7. **Privacy by design.** Names stay on the phone; the hub only knows `QDM-xxxx`; consent gates sharing and AI;
   right to export/erase in the app.
8. **Interoperability.** JSON contracts everywhere; read-only FHIR R4 export (`Observation` LOINC 8310-5 for skin
   temperature components, 2339-0 for glucose) prepares SIH integration.

## Scaling path (for the technical defence)

| Now (hackathon) | Pilot (3–6 months) | Scale |
| --- | --- | --- |
| 1 laptop hub, SQLite, local hotspot | Hub per clinic on a mini-PC or a certified health-data host, PostgreSQL, HTTPS + MQTT/TLS | Multi-tenant hub, managed broker (MQTT over TLS / BLE gateway), HL7 FHIR server, SSO for clinicians |
| Uno + 2 × DHT22 bench | ESP32 + 8 × DS18B20 mat (contact sensors), battery, Wi-Fi direct to broker | Insole / sock form factor (roadmap), calibrated sensors, device certification |
| Polling dashboard (3 s) | Server-sent events | Push notifications |
