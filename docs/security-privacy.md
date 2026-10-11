# Security and privacy by design

Qadam processes health data (glucose, foot temperature, treatment). The prototype implements the controls below;
it does **not** claim INPDP / GDPR compliance or certification — those require the steps in §6.

## 1. Data minimisation and pseudonymisation

| Data | Phone | Hub |
| --- | --- | --- |
| First name, phone numbers of doctor and family | yes (encrypted) | **never** |
| Patient identity | — | pseudonym `QDM-xxxx`; clinic label (e.g. initials) encrypted |
| Scans, glucose, adherence | yes | only with *share with care team* consent |
| Assistant questions | not stored (memory only) | not stored; audit keeps only `kind/source` |
| Live sensor frames | memory only | rolling 24 h buffer |

## 2. Encryption

| Where | Mechanism |
| --- | --- |
| Phone, at rest | Hive boxes encrypted with **AES-256** (HiveAesCipher); key = PBKDF2-HMAC-SHA256(PIN, 16-byte salt, 20 000 iterations); only salt + verifier stored. Auto-lock after 5 min in background; 30 s delay after 5 wrong PINs. |
| Hub, at rest | Sensitive free text (clinic labels, clinician notes, summaries) **AES-256-GCM** (`crypto.py`); passwords PBKDF2-SHA256 200 000 iterations; tokens stored as SHA-256 hashes. |
| In transit | Demo: isolated local hotspot (HTTP/MQTT). Deployment profile provided and tested: hub over **HTTPS TLS 1.3** (`--ssl-certfile/--ssl-keyfile`, verified with `curl`: TLSv1.3 / AES-256-GCM), Mosquitto **TLS 1.3** listener 8883 with passwords (`broker/mosquitto-tls.conf`), dev CA script `scripts/make_dev_certs.py`. |
| Serial / MQTT frames | CRC-8 integrity on serial; schema, range and source validation at bridge, app and hub. |

## 3. Access control and traceability

- Clinicians: login + 8 h session token, rate limiting (5 failures / 5 min), role on every endpoint.
- Patients: token obtained with a clinic-issued pairing code (48 h validity for new enrolments); revoked on erase.
- **Audit log** (`audit.py`): every login, view of a patient or alert, decision, summary validation, FHIR export,
  pairing, sync and erasure is appended with a **SHA-256 hash chain**; `/api/audit/verify` detects any modification
  (tested: editing one row breaks the chain). This supports non-repudiation of clinical decisions.
- Security headers on the dashboard: CSP `default-src 'self'` (no inline script), `X-Frame-Options: DENY`,
  `nosniff`, `no-referrer`, `no-store` on API responses.

## 4. Consent and patient rights

- Onboarding consent screen: local encrypted storage (always), sharing with the care team (opt-in), AI assistant
  (opt-in), explicit "Qadam does not replace my doctor".
- Settings: change consents, change PIN (data re-encrypted), **export** (JSON), **erase** (local + request to hub:
  `DELETE /api/patient/data`).

## 5. Threats considered (STRIDE summary)

| Threat | Mitigation in prototype | Remaining |
| --- | --- | --- |
| Lost / stolen phone | AES-256 + PIN, auto-lock | 4-digit PINs are brute-forceable offline → production: Android Keystore-wrapped key + biometrics |
| Spoofed sensor frames on the LAN | isolated hotspot, CRC, source label, range checks | MQTT auth + TLS in deployment profile |
| Stolen hub database | pseudonyms, encrypted free text | full-disk encryption + key in a secrets manager / HSM |
| Prompt injection via patient questions | grounding, output guard, no tools, no PII sent | model drift → re-test |
| Clinician account takeover | rate limit, hashed tokens, audit | MFA / SSO (roadmap) |
| Tampering with decisions | hash-chained audit | external anchoring of the chain head (roadmap) |

## 6. Before any real pilot (Tunisia)

1. Declaration/authorisation with the **INPDP** (Loi organique n° 2004-63) for health data processing; data
   processing agreement with the clinic.
2. Hosting of identifiable health data with an approved host; GDPR alignment if any EU processing (Gemini → check
   region and terms, or replace with a self-hosted model).
3. Ethics committee approval and informed consent for a clinical study.
4. Medical device qualification of the alerting function (software as a medical device) and of the mat.
5. Security review / penetration test; key management; backup and incident response procedures.
