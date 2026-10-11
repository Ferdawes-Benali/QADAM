# Data contracts

## 1. Serial frame (Arduino → bridge), 115200 baud, one line every 2.5 s

```
$QDM,1,<seq>,<tL>,<tR>,<spreadL>,<spreadR>,<n>,<hL>,<hR>,<flags>*<CRC8>
$QDM,1,42,30.25,33.10,0.10,0.15,4,45.0,46.0,0*8B
```

| Field | Meaning |
| --- | --- |
| `1` | frame version |
| `seq` | frame counter (gaps are counted by the bridge) |
| `tL`, `tR` | mean of the last 4 valid readings, °C, or `nan` |
| `spreadL/R` | max − min in that window (stability → confidence index) |
| `n` | valid readings in the window (min of both sides, 0–4) |
| `hL`, `hR` | relative humidity %, diagnostics only |
| `flags` | bit0 left sensor fault · bit1 right sensor fault · bit2 warming up |
| `CRC8` | CRC-8/ATM (poly 0x07, init 0) of the text between `$` and `*`, 2 hex digits |

Lines starting with `#` are information (boot banner, errors). Anything else is dropped and counted.

## 2. MQTT

Broker port 1883 (demo, isolated network) or 8883 with TLS 1.3 (`broker/mosquitto-tls.conf`).

### `qadam/<device>/live` — QoS 1, retained

```json
{ "v": 2, "device_id": "bench-01", "source": "hardware", "sensor": "DHT22", "seq": 42, "ts": 1791680000000,
  "left": {"mth1": 30.25}, "right": {"mth1": 33.10},
  "spread": {"left": 0.10, "right": 0.15}, "samples": 4,
  "humidity": {"left": 45.0, "right": 46.0},
  "faults": [], "warming_up": false, "integrity": "ok" }
```

- `source` is mandatory: `hardware` or `simulated`. Consumers reject frames without it.
- A faulty side is sent **empty** and listed in `faults` (`left_sensor` / `right_sensor`) — never estimated.
- Sites: `hallux`, `mth1`, `mth5`, `heel` (the 2-sensor bench uses `mth1`; the ESP32 mat uses all four).

### `qadam/<device>/status` — QoS 1, retained, also the MQTT *last will*

```json
{ "state": "online", "source": "hardware", "port": "COM5", "detail": "ok",
  "counters": {"frames": 812, "bad_checksum": 0, "parse_errors": 1, "sensor_faults": 0, "seq_gaps": 0, "info_lines": 2},
  "last_frame_age_s": 1.2, "ts": 1791680000000 }
```

`state`: `online` · `error` (port lost, no frame for 8 s) · `offline` (bridge stopped or crashed — last will).

## 3. Hub REST API (JSON; OpenAPI at `http://<hub>:8000/docs`)

| Method & path | Who | Purpose |
| --- | --- | --- |
| `GET /api/health` | public | status, MQTT, AI, demo mode |
| `POST /api/patient/pair` | app | pairing code + consent → patient token, device id |
| `POST /api/patient/sync` | app (token) | idempotent batch: `scan`, `glucose`, `adherence`, `ack` |
| `GET /api/patient/alerts` | app | alerts + clinician decision and note |
| `POST /api/patient/assistant` | app | `{question, lang, context}` → `{kind, source, text, label}` |
| `DELETE /api/patient/data` | app | right to erasure (data + token) |
| `POST /api/auth/login` | clinician | session token (8 h), 5 failures / 5 min lock |
| `GET /api/overview`, `/api/patients`, `/api/patients/{ref}` | clinician | dashboard data |
| `GET /api/alerts`, `/api/alerts/{id}`, `POST /api/alerts/{id}/review` | clinician | triage, evidence, decision |
| `POST /api/patients/{ref}/summaries`, `POST /api/summaries/{id}/review` | clinician | draft summary, validate / reject |
| `GET /api/devices`, `/api/devices/{id}/live` | clinician | device health, live readings |
| `GET /api/audit`, `/api/audit/verify` | clinician | audit log and hash-chain check |
| `GET /fhir/Patient/{ref}`, `/fhir/Observation?patient=` | clinician | FHIR R4 read-only export |

### Sync item examples

```json
{"type": "scan", "id": "1791680000-123", "ts": 1791680000000, "left": {"mth1": 30.8}, "right": {"mth1": 33.6},
 "samples": 4, "spread_left": 0.1, "spread_right": 0.2, "source": "hardware", "app_level": "amber"}
{"type": "glucose", "id": "g-1", "ts": 1791680000000, "g_l": 0.62, "context": "fasting"}
{"type": "adherence", "id": "adh-2026-10-11", "day": "2026-10-11", "planned": 2, "taken": 1}
{"type": "ack", "id": "ack-1791680000-123", "scan_id": "1791680000-123"}
```
