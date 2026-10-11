# Deployment dossier (L3) — feasibility, regulation, business model, roadmap

> Figures marked **(estimate)** or **(hypothesis)** are the team's working assumptions, to be validated in the pilot.
> No partnership, contract or clinical result exists yet.

## 1. Need (evidence)

- **1.39 million** Tunisian adults (20–79) live with diabetes; age-standardised prevalence **16.0 %**; **31.7 %**
  undiagnosed (IDF Diabetes Atlas, 2024 estimates).
- Diabetic foot ulcers affect **19–34 %** of people with diabetes during their lifetime and about **40 %** recur
  within a year after healing (Armstrong, Boulton & Bus, *NEJM* 2017).
- In 82 hospitalised diabetic patients in Tunis, only **22 %** inspected their feet daily and **77 %** had a poor
  level of foot-care knowledge (Mizouri et al., *La Tunisie Médicale* 2021).
- In a Tunis burn centre, **44 %** of diabetic patients admitted with foot burns needed an amputation (Blagui et al.,
  *Ann Burns Fire Disasters* 2024) — heat sources (kanoun, hot water) are a local risk Qadam addresses in its education.
- At-home foot temperature monitoring halved ulcer risk in a meta-analysis of 5 RCTs (RR 0.51, 95 % CI 0.31–0.84,
  low certainty; Golledge et al., *DMRR* 2022); IWGDF 2023 recommends considering it for moderate/high-risk patients.
- A smart mat using the same 2.2 °C threshold detected 97 % of ulcers ~37 days early, but with 57 % false positives
  (Frykberg et al., *Diabetes Care* 2017) → Qadam adds persistence, a confidence index and clinician review.

## 2. Target users and first segment

| Segment | Why first | Size |
| --- | --- | --- |
| Patients with a healed foot ulcer, neuropathy or amputation (IWGDF 2–3) followed in **private diabetology clinics / endocrinologists** in Tunis, Sfax, Sousse | Highest risk and benefit; clinicians already follow them; can pay | to measure in pilot **(hypothesis: a few % of the 1.39 M)** |
| Public endocrinology departments (e.g. INNTA) | Volume, research partner | via pilot study |
| CNAM (APCI chronic-disease programme) | Payer at scale | after evidence |

## 3. Business model (hypotheses)

| Who pays | For what | Price **(hypothesis)** |
| --- | --- | --- |
| Clinic / endocrinologist (B2B2C) | Monitoring subscription per active patient: mat loan, app, dashboard, support | 25–40 TND / patient / month |
| Patient (out of pocket, optional) | Mat purchase or rental for self-monitoring | rental 20 TND / month |
| CNAM / mutuelles (phase 2) | Reimbursed remote monitoring package for high-risk APCI patients, conditional on pilot outcomes | per-patient per-year package |
| Free | Glucose & medication diary, education assistant | free (adoption) |

Why customers keep paying: fewer emergency visits and amputations for their patients, structured follow-up
between visits (data in the PDF / FHIR export), and a differentiating service for clinics.

## 4. Costs (estimates)

| Item | Estimate |
| --- | --- |
| ESP32 mat BOM (ESP32, 8 × DS18B20, LiPo + charger + boost, PCB, foam, enclosure) | 150–220 TND per mat at small series **(estimate)** |
| Hub per clinic: mini-PC on site or a VPS at an approved health-data host | 50–150 TND / month **(estimate)** |
| Gemini API | optional; education answers are short — low cost; can be replaced by a self-hosted model |
| Support, logistics, cleaning of loaned mats | to measure in the pilot |

## 5. Barriers and answers

| Barrier | Answer |
| --- | --- |
| Clinical trust | Evidence-based rule, explainable alerts, clinician decides; pilot with an endocrinology department |
| Digital literacy, age | 10-second routine, Derja voice and text, large type, family WhatsApp |
| Connectivity in rural areas | Offline-first app, sync when connected, SMS/WhatsApp fallback |
| Cost | Clinic subscription with mat loan; CNAM reimbursement as the goal |
| Regulation | INPDP declaration, approved hosting, medical-device pathway planned from the start |
| False alarms | 2-day persistence, confidence index, clinician review, metrics tracked |

## 6. Regulatory path (Tunisia)

1. INPDP declaration/authorisation for health data (organic law 2004-63); data-processing agreements with clinics.
2. Approved hosting of health data; encryption and audit already designed in.
3. Ethics committee + informed consent for the pilot study.
4. Software-as-a-medical-device qualification of the alerting function; electrical safety of the mat.

## 7. Roadmap

| Horizon | Milestones | Measurable goals |
| --- | --- | --- |
| **0–3 months** | ESP32 + 8 contact-sensor mat (×10), calibration bench vs a reference skin thermometer; native-speaker + clinician review of Derja/AR texts; INPDP file; pilot protocol with one endocrinology team | sensor agreement ±0.3 °C vs reference; 10 mats built; protocol approved |
| **3–6 months** | Pilot: 30–50 IWGDF 2–3 patients for 3 months; HTTPS/TLS everywhere, Keystore-wrapped keys; clinic dashboard in routine use | ≥ 80 % of days with a scan; median clinician review < 24 h; false-alert rate measured; patient SUS ≥ 70 |
| 6–12 months | Larger study with outcome (ulcer incidence), CNAM discussions, second region | ulcer incidence vs usual care; cost per avoided complication |
| Vision | Insole / sock form factor, BLE direct to phone, integration with hospital information systems via FHIR | — |

## 8. Validation metrics (what we will measure)

Adherence (scan days / total), time-to-review, alert precision (confirmed / total), ulcers detected before opening,
patient-reported usability (SUS), clinician time per alert, cost per monitored patient.
