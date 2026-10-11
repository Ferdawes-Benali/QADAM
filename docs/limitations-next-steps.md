# Known limitations and next steps (prioritised)

## Must know before the demo

1. **The Flutter app was written without a Flutter SDK in the build environment.** It was reviewed line by line
   against the exact package versions, but its first compilation happens on the team's PC. Any analyzer error must
   be fixed before the demo (send it to the developer / Claude).
2. **DHT22 = air temperature.** The bench proves the data chain and the alert logic; it is not a clinical
   measurement. Say it before the jury does.
3. **Demo mode** counts each scan as one day so the red alert can be shown live. It is labelled in the app,
   the dashboard and the PDF. Turn it off for any real use.
4. **Plain HTTP/MQTT during the demo** on an isolated hotspot; the TLS 1.3 profile exists and was tested on the hub.
5. **Derja and Arabic texts** are team drafts: get a native-speaker check of the screens you show.

## Product / technical next steps

| Priority | Item |
| --- | --- |
| P0 | Compile and run `flutter test` / `flutter analyze` on the team PC; record phone screenshots for the deck |
| P0 | Flash `uno_dht_bench` on the Uno and run the hardware checklist (docs/hardware-setup.md) |
| P1 | App: pin the hub's CA for HTTPS and MQTT over TLS; store the data key wrapped in Android Keystore (biometric unlock) |
| P1 | Daily reminder notifications (`flutter_local_notifications`), Derja voice clips recorded by a native speaker |
| P1 | ESP32 firmware v2 with the same CRC frame format and 4 sites per foot; Wi-Fi/MQTT direct (no laptop) |
| P2 | Hub: PostgreSQL, server-sent events instead of polling, clinician MFA, backup/restore, FHIR validation against a server |
| P2 | Calibration procedure and per-sensor offsets; foot-presence detection |
| P3 | Clinic analytics (adherence, review times), multi-clinic tenancy, SIH integration |

## Clinical / scientific limits

- The 2.2 °C rule and its benefit come from studies outside Tunisia with contact thermometers; low certainty of
  evidence; high false-positive rates reported. Qadam must be evaluated locally before claiming any benefit.
- Confidence index measures *measurement quality*, not diagnostic probability.
- No outcome data, no usability study yet; all business figures are hypotheses.
- Bias: the rule does not use demographics; risks to study are sensor contact, foot size and placement, ambient
  temperature (mitigated by comparing left vs right at the same moment), and literacy (mitigated by Derja + voice).
