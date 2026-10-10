# Qadam (قدم) — diabetes companion with a smart foot mat

**HackCure 2026 · Tunisia.** A patient app for people with diabetes (glucose, medication, education in Derja/Arabic/French)
connected to a low-cost IoT mat that catches diabetic-foot inflammation early by comparing left/right skin temperature
(alert at ≥ 2.2 °C at the same site, two days in a row).

## Repository layout

```
qadam-app/
├── ROADMAP.md                 ← the step-by-step plan: follow it phase by phase
├── docs/                      architecture, MQTT contract, AI safety rules
├── hardware/
│   ├── wokwi/                 diagram.json + sketch.ino + libraries.txt (simulation, same pins as the real mat)
│   ├── esp32_qadam_mat/       firmware for the real 8-sensor ESP32 mat
│   └── uno_dht_demo/          fallback demo: Arduino Uno + 2 DHT22
├── bridge/                    serial_to_mqtt.py: board (USB) → MQTT (also --fake mode with no hardware)
├── broker/                    mosquitto.conf (+ optional Node-RED dashboard flow)
├── app/                       Flutter app (lib/ + setup_app.ps1 that generates the Android project)
└── .github/workflows/ci.yml   Flutter analyze/test, Python lint, ESP32 compile, gitleaks
```

## Technology stack

| Layer | Technology | Why |
| --- | --- | --- |
| Sensing | ESP32-DevKitC + 8 × DS18B20 (1-Wire) — or Uno + 2 × DHT22 | Cheap, available in Tunisia, ±0.5 °C, relative L/R difference is what matters |
| Firmware | Arduino C++ (OneWire, DallasTemperature, ArduinoJson, Adafruit NeoPixel) | Fast to write, simulated in Wokwi |
| Simulation | Wokwi | Test wiring and firmware before soldering |
| Transport | USB serial → Python bridge (paho-mqtt, pyserial) → **Mosquitto** MQTT broker | Works with boards without Wi-Fi; app gets live data |
| Mobile app | **Flutter 3** (Dart), provider, mqtt_client, Hive (local storage), fl_chart, pdf/printing, url_launcher, audioplayers | One codebase, offline-first, Android demo phone |
| AI | **Google Gemini API** (free tier, REST) | Explanations in Derja, doctor summary, diabetes Q&A — with strict safety rules |
| Alerts | WhatsApp deep link (wa.me) + Derja voice clips | No paid SMS gateway, works for every family |
| Quality | flutter analyze/test, pyflakes, arduino compile-sketches, gitleaks in GitHub Actions | Same discipline as previous projects |

## Quick start (Windows, VS Code PowerShell)

```powershell
# 1. broker
& "C:\Program Files\mosquitto\mosquitto.exe" -c broker\mosquitto.conf -v
# 2. bridge (no hardware yet? use --fake)
pip install -r bridge\requirements.txt
python bridge\serial_to_mqtt.py --fake
# 3. app
cd app ; .\setup_app.ps1
flutter run --dart-define=GEMINI_API_KEY=YOUR_KEY
```
In the app: Feet tab → enter the PC's IP (`ipconfig` → IPv4 of the hotspot adapter) → connect.

## What works / what doesn't (honest status)
- Written, **not yet compiled or run** in the authoring environment: Flutter app, firmware, bridge. Phase 4 of the roadmap is where you first build and fix.
- Clinical rule is literature-based (2.2 °C); the app is a screening aid, not a diagnosis.
- Gemini key inside the app is acceptable for a demo only.
