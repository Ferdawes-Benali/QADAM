# Qadam (قدم) — diabetic-foot early warning + diabetes companion

> HackCure 2026 prototype · Track 1 (IoT) with Track 2 (mobile) and Track 3 (decision support) components.
> **Not a medical device. No clinical validation has been performed.**

## 1. What Qadam does

Diabetic foot ulcers usually start as a silent inflammation: the skin over the future ulcer gets warmer days or
weeks before the wound opens. Home studies used one simple, explainable signal: **the same spot on the left and
right foot differs by ≥ 2.2 °C on two consecutive days** (IWGDF 2023 prevention guideline; meta-analysis of 5 RCTs:
RR 0.51 for ulcers with at-home temperature monitoring — Golledge et al., *DMRR* 2022, low certainty).

Qadam turns that signal into a daily 10-second habit and a clinical workflow:

| Who | What they get |
| --- | --- |
| **Patient** (Flutter app, Derja / Arabic / French) | 10 s foot scan on the mat, result with *why* (temperatures, threshold, confidence) and *what to do* (fixed, validated wording), glucose and medication diary, safety-first assistant, WhatsApp/phone shortcuts, PDF report. Works offline, encrypted on the phone. |
| **Care team** (web dashboard served by the hub) | Triage queue (red first), alert evidence, **confirm/dismiss in 3 steps**, patient file with trends, live bench, AI-drafted summary that only enters the record after validation, FHIR export, tamper-evident audit log. |
| **Hardware** | Arduino Uno + 2 × DHT22 bench (left/right foot, same site) → CRC-checked serial frames → MQTT. ESP32 + 8 × DS18B20 mat is the next hardware step (`hardware/esp32_qadam_mat`). |

## 2. Architecture

```
 DHT22 L ─┐                 USB serial                MQTT (QoS1)              REST / JSON
 DHT22 R ─┴─ Arduino Uno ── $QDM,...*CRC ──► bridge ──► broker ──┬──► Hub (FastAPI) ──► clinician dashboard (web)
                           (no clinical       (CRC,       :1883   │     ├ rule re-check, alerts, audit (SQLite)
                            decision)          source              │     ├ FHIR R4 export
                                               label)              │     └ AI proxy (Gemini key server-side)
                                                                   └──► Patient app (Flutter): live view + 10 s scan
                                                                          └ offline outbox ──sync──► Hub
```

Layers are separated as required (§5 of the *cahier des charges*): presentation (app, dashboard), business logic
(`rule.py` / `foot_rule.dart`, `domain.py`, `safety.*`), inference (`ai.py`, optional), data (`db.py`, Hive).
Details: [docs/architecture.md](docs/architecture.md).

| Part | Technology |
| --- | --- |
| Firmware | Arduino C++ (`hardware/uno_dht_bench`), Adafruit DHT library |
| Bridge | Python 3.12, pyserial, paho-mqtt 2 |
| Broker | Mosquitto 2 (Docker or native) — or the built-in Python broker (`QADAM_EMBEDDED_BROKER=1`) |
| Hub | Python 3.12, FastAPI, SQLite (WAL), cryptography (AES-256-GCM), httpx (Gemini REST) |
| Dashboard | Vanilla JS + Chart.js 4 (vendored, works offline), Rubik font |
| Patient app | Flutter 3.44 / Dart 3.13, provider, Hive (AES-256), mqtt_client, fl_chart, pdf |

## 3. Prerequisites

- Windows 10/11 (tested commands are PowerShell) or Linux/macOS
- Python ≥ 3.11, Git
- Flutter ≥ 3.44 + Android SDK (for the phone app), an Android phone with USB debugging
- Arduino IDE 2.x (to flash the Uno) + libraries **DHT sensor library** and **Adafruit Unified Sensor**
- Optional: Docker Desktop (one-command stack), Mosquitto for Windows

## 4. Install and run (local, ~5 minutes)

```powershell
cd D:\qadam-app
python -m venv .venv ; .\.venv\Scripts\Activate.ps1
pip install -r hub\requirements.txt -r bridge\requirements.txt

# terminal 1 — hub + built-in MQTT broker (no Mosquitto needed)
$env:QADAM_EMBEDDED_BROKER = "1"
cd hub ; python -m qadam_hub          # http://localhost:8000  (login dr.demo / qadam-demo-2026)

# terminal 2 — data source
python bridge\qadam_bridge.py --simulate       # labelled SIMULATION
python bridge\qadam_bridge.py --port COM5      # real Arduino (close the Arduino Serial Monitor first)

# terminal 3 — phone app
cd app ; .\setup_app.ps1 ; flutter run
```

**Docker (stack autonome, §9 of the cahier):** `copy .env.example .env` then `docker compose up --build`
(Mosquitto + hub). The bridge stays on the host because USB/COM ports are not visible inside Docker Desktop.

**Phone ↔ laptop:** put both on the same Wi-Fi or on the laptop's hotspot, find the laptop IP with `ipconfig`,
allow Python/Mosquitto through the Windows firewall (private networks). In the app: *More → Mat and care team*:
computer address = laptop IP; server address = `http://<laptop IP>:8000`; pairing code = `246810` (demo patient
QDM-2048).

## 5. Environment variables

See [.env.example](.env.example). The important ones:

| Variable | Default | Purpose |
| --- | --- | --- |
| `GEMINI_API_KEY` | empty | Enables the AI assistant and AI-drafted summaries. **Server-side only.** Empty = verified library, no AI. |
| `GEMINI_MODEL` | `gemini-3.8-flash` | Check the current Flash model ID on ai.google.dev. |
| `QADAM_DEMO_MODE` | `1` | Each scan counts as one day (shows amber → red live). Set `0` for real calendar logic. |
| `QADAM_EMBEDDED_BROKER` | `0` | `1` starts a Python MQTT broker inside the hub. |
| `QADAM_DATA_KEY` | auto | Base64 32-byte AES key for encrypted fields (auto-generated into `hub/data/.data_key` for the demo). |
| `QADAM_CLINICIAN_USER` / `_PASSWORD` | `dr.demo` / `qadam-demo-2026` | Demo account — change it. |

## 6. Database

SQLite file `hub/data/qadam.db`, schema created automatically on first start (`hub/qadam_hub/db.py`).
`QADAM_SEED=1` loads a **synthetic** dataset (7 patients, 21 days, clearly tagged `synthetic`) plus the demo patient
QDM-2048 linked to device `bench-01`. Reset: stop the hub and delete `hub/data/`.

## 7. AI assistant

Pipeline (both app and hub): **red-flag rules → Gemini grounded on the verified library → output guard → verified
library fallback**. Every answer is labelled with its source. Details and test prompts: [docs/ai-safety.md](docs/ai-safety.md).

## 8. Hardware

Arduino Uno + 2 × DHT22: wiring, power, precautions, flashing and troubleshooting in
[docs/hardware-setup.md](docs/hardware-setup.md). The DHT22 measures **air** temperature — it demonstrates the data
chain; it is not a skin thermometer.

## 9. Simulation mode

`python bridge\qadam_bridge.py --simulate` — keys: `n` normal, `h` right-foot hotspot, `l` left-foot hotspot,
`f` left sensor fault, `x` noisy, `q` quit. Unattended: `--script n:4,h:12`. Every frame carries
`"source":"simulated"`; the app and dashboard show a hatched **SIMULATION** badge. The bridge never switches to
simulation on its own when the board is unplugged: it reports an error instead.

## 10. Tests

```powershell
cd hub ; python -m pytest -q                   # rule vectors, safety, API, MQTT end-to-end (embedded broker)
cd ..\bridge ; python -m pytest -q             # CRC, frame parsing, fault handling, simulator labels
python scripts\check_app_strings.py            # 3 languages complete, shared JSON in sync
cd ..\app ; flutter test                       # same rule vectors in Dart, PBKDF2 RFC vectors, safety, models
```
Results and what remains unverified: [docs/test-report.md](docs/test-report.md).

## 11. Troubleshooting

| Symptom | Fix |
| --- | --- |
| App: "Computer unreachable" | Same Wi-Fi? Laptop IP correct? Firewall allows port 1883 (and 8000)? Hub/broker running? |
| App: "Waiting for the mat" | Bridge not running, or wrong device id (default `bench-01`). |
| Bridge: `could not open port COM5` | Close the Arduino IDE Serial Monitor; check the port in Device Manager or `--list-ports`. |
| Bridge: many `checksum` drops | Wrong baud rate (must be 115200) or loose USB cable. |
| Dashboard empty | Hub started from `hub\`? `QADAM_SEED=1`? Delete `hub\data` to reseed. |
| Assistant says "offline / verified library" | Not paired, AI consent off, no `GEMINI_API_KEY`, or model ID unavailable — by design it never fakes an AI answer. |
| Flutter: Kotlin "different roots" | `kotlin.incremental=false` in `app\android\gradle.properties` (done by `setup_app.ps1`). |

## 12. Known limitations and next steps

See [docs/limitations-next-steps.md](docs/limitations-next-steps.md) and the requirement traceability matrix
[docs/requirements-traceability.md](docs/requirements-traceability.md).

## Repository map

```
app/        Flutter patient app            hub/       FastAPI hub + clinician dashboard (static/)
bridge/     serial → MQTT bridge + simulator hardware/ firmware (uno_dht_bench = demo; esp32 = next step)
broker/     Mosquitto configs (plain, TLS)  shared/    rule test vectors, red flags, verified answer library
docs/       architecture, security, AI, hardware, design system, test report, scripts, traceability
presentation/  pitch deck (PPTX + PDF)      scripts/   string checker, TLS dev certs, screenshots
```

Credits: Rubik font (SIL OFL), Chart.js (MIT). Qadam logo © the Qadam team.
