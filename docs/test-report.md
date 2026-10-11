# Test report — 11 October 2026

Environment for the runs below: Linux, Python 3.13, FastAPI 0.143, paho-mqtt 2, amqtt 0.12 (embedded broker),
Chromium (Playwright), g++ 13. **No Flutter/Dart SDK and no Arduino toolchain were reachable in this environment**
(download servers blocked): those parts are marked *pending* and must be run on the team's PC.

## 1. Results

| Suite | Command | Result |
| --- | --- | --- |
| Rule vectors + safety (Python) | `cd hub && pytest tests/test_rule_and_safety.py` | **29 passed** (12 shared rule vectors incl. confidence values; 6 red-flag cases FR/Derja/EN; 4 no-false-alarm cases; 4 library topics; fallback; 3-language completeness) |
| Hub API | `pytest tests/test_api.py` | **12 passed**: auth + rate limit; synthetic dataset & encrypted labels; full patient flow green→amber→red → clinician confirm → patient sees decision + ack; idempotent sync; validation & consent (403); assistant rules/library; mocked Gemini + output guard; AI consent; summary draft → validate; FHIR bundle codes; audit chain verify + tamper detection; enrol + pair; erase my data; security headers |
| End-to-end telemetry | `pytest tests/test_e2e_mqtt.py` | **1 passed**: simulator → embedded broker → hub ingest → `/api/devices` (online, source simulated, counters) → live readings; malformed JSON and source-less frames rejected; bridge stop → device `offline` (last will) |
| Bridge | `cd bridge && pytest` | **9 passed**: CRC-8/ATM check value (0xF4), round-trip, 4 bad-frame kinds, counters (checksum, parse, faults, seq gaps), simulator labels/scenarios, real firmware output accepted |
| Firmware (host) | `g++ ... main.cpp && ./fw_host` | compiles with `-Wall -Wextra`; 40 frames + 1 error line; Python encoder reproduces every firmware line byte-for-byte; averaging, spread, fault after 2 failed reads, recovery and warming-up flag behave as specified |
| Translations | `python scripts/check_app_strings.py` | **OK**: 395 keys × 3 languages, placeholders consistent, 318 literal + 27 dynamic uses resolved, shared JSON copies identical |
| Dashboard UI | `python scripts/dashboard_screens.py` (Playwright, 1440 px and 390 px) | all 9 pages render, **0 console errors**; screenshots in `docs/screenshots/` |
| HTTPS | uvicorn `--ssl-*` + `curl --cacert` | **TLSv1.3 / TLS_AES_256_GCM_SHA384** negotiated |
| Colour contrast | WCAG formula on all text tokens | all ≥ 4.5:1 after darkening `ink-3` to `#5F6B78` |

**Total automated (Python): 51 passed, 0 failed.**

## 2. Pending (must be run by the team)

| Item | How | Why pending |
| --- | --- | --- |
| Flutter analyze / build / tests (28 Dart tests: 12 shared rule vectors + threshold + demo escalation, safety ×5, PBKDF2 RFC vectors ×3, strings ×3, models ×3) | `cd app; .\setup_app.ps1` | no Dart SDK here. The code was reviewed independently against the exact package versions (one compile error and two runtime issues found and fixed). |
| Arduino compile + upload | Arduino IDE, or CI job `firmware` (arduino/compile-sketches) | no AVR toolchain here; logic verified via host build |
| Real DHT22 readings, warming test, unplug tests | docs/hardware-setup.md checklist | needs the physical bench |
| Phone ↔ laptop over hotspot, Windows firewall | docs/demo-script.md set-up | needs the team's devices |
| Gemini live call | set `GEMINI_API_KEY`, ask the 4 prompts in docs/ai-safety.md | outbound access to Google AI blocked here; client tested with a mocked transport |
| `docker compose up` | Docker Desktop | registry not reachable here |

## 3. Defects found and fixed during verification

| # | Defect | Fix |
| --- | --- | --- |
| 1 | Seeded "today" records could be in the future before 8 a.m. | timestamps clamped before "now" |
| 2 | Alert queue flooded with 3-week-old synthetic alerts | older synthetic alerts pre-reviewed (realistic queue) |
| 3 | Dashboard back icon rendered at full width (unsized SVG) | explicit icon sizing |
| 4 | Rule text and site codes shown in English / codes in a French UI | French labels, decimal commas |
| 5 | Firmware ring buffer reused stale slots after a fault | reset write index with the window |
| 6 | Firmware fault message always blamed the left sensor | uses the per-side flag |
| 7 | Two simulators on the same device id produced a saw-tooth signal | documented (one bridge per device); hub counts `seq_gaps` |
| 8 | `ink-3` contrast 4.19:1 on paper | darkened to 5.0:1 |
| 9 | Dart: nullable scan passed to result screen; screens stayed above the lock screen; danger label overflow | fixed (review agent) |
| 10 | App sync/pairing: unexpected hub responses could leave a spinner | catch-all with user message |
