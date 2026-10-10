# Architecture

```
Patient feet
   │  (skin temperature, 4 sites per foot)
   ▼
DS18B20 ×8  ──1-Wire GPIO4/16──►  ESP32 (or Uno + 2 DHT22)
                                   │ calibrate, detect feet, average 10 s, JSON line on USB serial
                                   ▼
                         bridge/serial_to_mqtt.py  (laptop)
                                   │ publish, retain
                                   ▼
                         Mosquitto broker :1883  (laptop, same hotspot as the phone)
                                   │ topic qadam/mat01/live
                                   ▼
                         Flutter app (Android)
                           ├─ FootRule: dT per site → green / amber / red (2-day persistence, demo mode)
                           ├─ Hive local storage: profile, glucose, meds, scans
                           ├─ Gemini: explain scan / glucose (Derja-AR-FR), doctor summary, Q&A coach
                           ├─ Alert screen: voice clip + WhatsApp to family + call doctor
                           └─ PDF report for the doctor
```

## Design decisions
- **Rule on the phone, not on the board.** The board sends raw site temperatures; the threshold and 2-day logic live in
  `app/lib/services/foot_rule.dart` and are unit-tested. Changing the rule never needs re-flashing.
- **MQTT with retain.** The app receives the last scan as soon as it connects; duplicates are filtered in AppState.
- **Local-first.** No account or server needed for the demo; a backend (Supabase or similar) is a future phase.
- **AI only for language, not for detection.** Detection is deterministic and explainable; AI explains, summarises, answers.
