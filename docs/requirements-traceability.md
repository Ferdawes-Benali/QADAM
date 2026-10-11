# Cahier des charges → implementation traceability

Status: ✅ implemented and verified here · 🟡 implemented, verification pending on the team's machine (Flutter build /
real hardware) · 🔶 partial / prototype-level · ⛔ out of hackathon scope (plan given).

## §1–2 Clinical problem and value chain

| Requirement | Implementation | Verification | Status | Limitation |
| --- | --- | --- | --- | --- |
| Precisely qualified medical problem | Diabetic-foot ulcer prevention in IWGDF risk 2–3 patients via contralateral temperature asymmetry (README §1, deck slides 2–3) | Sources cited (IWGDF 2023, Golledge 2022, Frykberg 2017, IDF Atlas) | ✅ | Prevalence of risk 2–3 in Tunisia to be measured in the pilot |
| 1. Collecte & télémétrie | Uno + 2 × DHT22 firmware, CRC frames, bridge → MQTT; glucose/meds forms in app | `bridge/tests`, firmware host test, `test_e2e_mqtt.py` | ✅ / 🟡 board | DHT22 measures air, not skin |
| 2. Traitement & analyse | Deterministic rule + confidence index (app + hub), safety triage, optional AI | 12 shared rule vectors (Python ✅, Dart 🟡), safety tests | ✅ | Rule threshold from literature, not re-validated |
| 3. Restitution clinique | Clinician dashboard: triage queue, evidence, patient file, live bench; patient result screen | Playwright screenshots `docs/screenshots/` | ✅ dashboard · 🟡 app | — |
| 4. Impact terrain | Earlier detection workflow, 3-step decision, PDF report, WhatsApp/phone shortcuts | Demo script; impact metrics defined in deck slide 8 | 🔶 | No clinical outcome data (hypotheses only) |

## §3 Track 1 — IoT (primary track)

| Requirement | Implementation | Verification | Status |
| --- | --- | --- | --- |
| Functional physical components (temperature sensors, microcontroller) | `hardware/uno_dht_bench` (Uno, 2 × DHT22, LEDs, buzzer) | Host-compiled firmware output parsed by bridge (40/40 frames, 0 CRC errors); flashing on the real Uno pending | 🟡 |
| Signal reliability | 10 s averaging window, spread (stability), plausibility checks, fault flags, warming-up flag, staleness (15 s), CRC-8, sequence-gap counter, confidence index | `test_bridge.py`, `test_rule_and_safety.py`, e2e | ✅ |
| Ergonomics | 10 s scan with countdown and posture instruction; mat form factor (ESP32 design) | App screens | 🟡 |
| Tracks 2/3 elements | Patient app works offline; decision support is explainable and advisory | see below | ✅ / 🟡 |

## §4 Regulation, ethics, data protection (INPDP / GDPR, privacy by design)

| Requirement | Implementation | Verification | Status | Limitation |
| --- | --- | --- | --- | --- |
| Privacy by design | Name only on phone, pseudonym on hub, consent gates, minimised AI context | `test_sync_validation_and_consent`, `test_assistant_respects_ai_consent` | ✅ | — |
| INPDP / GDPR conformity | Patient rights in app (export, erase → hub erase), audit log, documented plan | `test_erase_my_data` | 🔶 | Formal INPDP declaration not done (docs/security-privacy.md §6) |

## §5 Technical specifications

| Requirement | Implementation | Verification | Status | Limitation |
| --- | --- | --- | --- | --- |
| Encryption in transit TLS 1.3 | Hub HTTPS (uvicorn `--ssl-*`), Mosquitto TLS 1.3 profile, dev CA script | `curl` handshake: TLSv1.3 / TLS_AES_256_GCM_SHA384 | 🔶 | Live demo runs plain HTTP/MQTT on an isolated hotspot; app does not yet pin the dev CA |
| Encryption at rest AES-256 | Phone: Hive AES-256, key PBKDF2(PIN). Hub: AES-256-GCM fields, PBKDF2 passwords | `test_synthetic_dataset…` checks ciphertext; Dart PBKDF2 RFC vectors 🟡 | ✅ / 🟡 | Hub DB file itself not encrypted (pseudonymised content) |
| Pseudonymisation | `QDM-xxxx` references, encrypted labels | API tests | ✅ | — |
| Non-repudiation of access | SHA-256 hash-chained audit of views, decisions, exports | `test_summary_review_fhir_audit` (tamper detected) | ✅ | Chain head not externally anchored |
| Separation front / logic / inference / DB | See docs/architecture.md table | Code structure | ✅ | — |
| Degraded mode / offline cache | App: encrypted outbox, offline library, works without hub; hub: SQLite, vendored assets, embedded broker | Sync idempotency test; app 🟡 | ✅ / 🟡 | — |
| Structured JSON, HL7/FHIR compatibility | JSON contracts (docs/mqtt-contract.md); FHIR R4 `Patient`, `Observation` bundle (LOINC 8310-5, 2339-0; SNOMED foot sites) | `test_summary_review_fhir_audit` | ✅ | Not validated against a FHIR server/profile |
| Low cognitive load, validation in ≤ 3 steps | Alert: open → choose confirm/dismiss → save (step indicator in UI) | Screenshot `dash-alert-detail`; `test_full_patient_flow…` | ✅ | — |
| Lightweight standard protocols (MQTT, BLE) | MQTT QoS 1, retained, last-will health topic | e2e test | ✅ | BLE: roadmap (ESP32) |
| Frame integrity control | CRC-8 on serial, JSON schema/range/source checks, malformed frames counted | `test_bad_frames_rejected`, e2e malformed JSON | ✅ | — |
| Energy autonomy, EMI immunity | ESP32 mat design: LiPo + TP4056 + MT3608 (engineering package); averaging, CRC | Design docs | ⛔ bench is USB-powered |

## §6 Algorithmic ethics (SADM)

| Requirement | Implementation | Verification | Status |
| --- | --- | --- | --- |
| Measurable confidence index | 0–100 index (samples × stability × margin) + label, shown to patient and clinician | Shared vectors (confidence values) | ✅ |
| Contextual explanation (triggering parameters) | ΔT, threshold, site, warmer side, consecutive days, per-site ΔT, factors | Dashboard evidence panel, app "Why?" card | ✅ / 🟡 |
| No black box | Rule is 6 lines, published, tested | — | ✅ |
| Human-in-the-loop validation / rejection | Confirm / dismiss with note; summaries need Validate | API tests | ✅ |
| Advisory nature stated unambiguously | Banner on every alert, labels on AI output, "not a diagnosis" on every result screen | Screenshots | ✅ |
| Bias control | Thresholds independent of demographics; multilingual (Derja/AR/FR); limits documented (skin tone not relevant to contact thermometry; sensor calibration and foot-size effects to study) | docs/limitations | 🔶 |
| Mastery of generated code / third-party APIs | Every module documented; dependencies listed with purpose; Gemini optional and isolated behind `ai.py` | README, architecture | ✅ |

## §7 Economic viability

| Requirement | Where | Status |
| --- | --- | --- |
| Payer identified | Deck slide 10 + docs/deployment-dossier.md: private diabetology clinics (B2B2C) first, CNAM pilot next | 🔶 hypotheses to validate |
| Access barriers | Deck slide 11 | ✅ |
| Realistic server / hardware costs | docs/deployment-dossier.md (BOM and hosting estimates, labelled as estimates) | 🔶 |

## §8 Mandatory deliverables

| Deliverable | Where | Status |
| --- | --- | --- |
| L1 Technical repository, README, history | This repository; README; push to GitHub (team action) | 🟡 push pending |
| L2 MVP with synthetic data | Hub + dashboard + bridge (verified), app (build pending), synthetic dataset (7 patients, 21 days) | ✅ / 🟡 |
| L3 Deployment dossier (feasibility, regulation, 3- and 6-month roadmap) | `presentation/` deck + docs/deployment-dossier.md | ✅ |

## §9 Live demonstration protocol

| Step | Where | Status |
| --- | --- | --- |
| Clinical case | docs/demo-script.md (persona, scenario) | ✅ |
| Live MVP manipulation (no video) | docs/demo-script.md, backup paths without video | ✅ |
| Technical defence | docs/pitch-script.md Q&A section | ✅ |
| Robustness: Docker, local test DB, backup access point | docker-compose.yml, SQLite seed, embedded broker, phone hotspot plan | ✅ (compose not run here: no registry access) |
