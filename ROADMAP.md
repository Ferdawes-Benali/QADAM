# Qadam — build roadmap

**How we work:** one step at a time. Each step has a goal, the technology, what to do, and a **✅ Done when** check.
At every **🔒 Gate**, send me the result (screenshot, terminal output or error) and we fix it before moving on.
Environment: Windows, VS Code integrated PowerShell, Android phone.

| Phase | Goal | Main technology | Est. time |
| --- | --- | --- | --- |
| 0 | Tools + repo | Git, GitHub, VS Code, Flutter, Python, Mosquitto, Arduino IDE | 1–2 h |
| 1 | Circuit works in simulation | Wokwi, ESP32 Arduino core, OneWire/DallasTemperature | 1 h |
| 2 | Real hardware reads temperatures | Arduino Uno + DHT22 (or ESP32 + DS18B20) | 1–2 h |
| 3 | Data reaches a broker | Python (paho-mqtt, pyserial), Mosquitto | 1 h |
| 4 | App runs on the phone | Flutter, provider, Hive, i18n + RTL | 2 h |
| 5 | Feet module live | mqtt_client, FootRule, alert screen | 2 h |
| 6 | Glucose + medication | fl_chart, Hive | 1–2 h |
| 7 | AI features | Gemini API (REST), safety prompt | 1–2 h |
| 8 | Alerts + doctor report | wa.me deep links, audioplayers, pdf/printing | 1 h |
| 9 | Quality | flutter test/analyze, GitHub Actions, gitleaks | 1 h |
| 10 | Demo ready | Script, backup video, pitch | 1–2 h |

---

## Phase 0 — Tools and repository

**0.1 Install tools** (skip what you already have)
- Git, VS Code, Python 3.12 (tick "Add to PATH")
- Flutter SDK (stable) + Android Studio (SDK + platform tools) → `flutter doctor` until Android toolchain is ✓
- Mosquitto 2.x for Windows (default path `C:\Program Files\mosquitto`)
- Arduino IDE 2.3.x + board package **esp32 by Espressif** (Boards Manager) — only if you flash an ESP32
- Phone: Developer options → **USB debugging ON**
- ✅ Done when: `flutter doctor` shows no red ✗ for Android, `python --version` ≥ 3.12, `mosquitto -h` prints help.

**0.2 Create the repo**
```powershell
cd D:\            # outside OneDrive (it corrupts .git)
Expand-Archive .\qadam-app.zip -DestinationPath .
cd qadam-app ; git init -b main ; git add . ; git commit -m "chore: initial structure"
git checkout -b dev
```
Create an empty GitHub repo `qadam-app`, then `git remote add origin <url>` and `git push -u origin main dev`.
- ✅ Done when: both branches are on GitHub and the Actions tab shows the CI workflow.

🔒 **Gate 0:** send me the `flutter doctor` output.

---

## Phase 1 — Simulate the circuit (Wokwi)
**Tech:** Wokwi, ESP32-DevKitC, OneWire, DallasTemperature, ArduinoJson, Adafruit NeoPixel.

**1.1** wokwi.com → New project → ESP32 → paste `hardware/wokwi/diagram.json`, `sketch.ino`, add `libraries.txt`.
**1.2** Run the 7 checks of the Wokwi Wiring Guide (section 6): 8 sensors mapped, green scan, orange hotspot at 28 °C.
- ✅ Done when: Serial shows `max dT = 3.00 C at mth1` and the LED turns orange.

🔒 **Gate 1:** screenshot of Serial Monitor after the hotspot scan.

---

## Phase 2 — Real hardware
**Option A (fast, what you have): Arduino Uno + 2 × DHT22** — `hardware/uno_dht_demo/`
- Wire: DHT left DATA → D2, right DATA → D3, VCC 5V, GND; LEDs D5/D6 with 220 Ω; buzzer D8.
- Arduino IDE → board **Arduino Uno**, port **COMx** → install *DHT sensor library* (Adafruit) + *Adafruit Unified Sensor* → upload.
**Option B: ESP32 + 8 × DS18B20** — `hardware/esp32_qadam_mat/` (same wiring as Wokwi; set `SCAN_MS=20000`, `AVG_LAST=10`).
- ✅ Done when: Serial Monitor (115200) shows a JSON line `{"left":...,"right":...}`; warming one sensor raises the difference.
- ⚠ Close the Serial Monitor afterwards: the bridge needs the COM port.

🔒 **Gate 2:** paste 3 JSON lines from the Serial Monitor.

---

## Phase 3 — Broker and bridge
**Tech:** Mosquitto, Python, paho-mqtt, pyserial.

**3.1 Broker**
```powershell
& "C:\Program Files\mosquitto\mosquitto.exe" -c broker\mosquitto.conf -v
```
Allow it through Windows Firewall (Private networks) when asked.

**3.2 Bridge** (new terminal)
```powershell
python -m venv .venv ; .\.venv\Scripts\Activate.ps1
pip install -r bridge\requirements.txt
python bridge\serial_to_mqtt.py --port COM5        # or --fake if no board connected
```
**3.3 Check** (third terminal)
```powershell
& "C:\Program Files\mosquitto\mosquitto_sub.exe" -h 127.0.0.1 -t "qadam/#" -v
```
- ✅ Done when: `mosquitto_sub` prints the JSON every scan (or every 5 s with `--fake`).

🔒 **Gate 3:** screenshot of the three terminals.

---

## Phase 4 — App foundations
**Tech:** Flutter, provider (state), Hive (local storage), flutter_localizations (FR/AR, RTL), custom Derja strings.

**4.1** `cd app ; .\setup_app.ps1` — generates the Android project, adds packages, assets, INTERNET permission, runs analyze + tests.
**4.2** Fix any analyzer errors (send them to me — this code was written without a Flutter SDK available, expect a few).
**4.3** Phone on USB → `flutter run --dart-define=GEMINI_API_KEY=x` (dummy key is fine for now).
**4.4** Onboarding: switch Derja / العربية / Français → layout flips to RTL for Arabic; save a profile.
- ✅ Done when: Home dashboard shows the 4 cards and today's plan; `flutter test` = 4 tests passed.

🔒 **Gate 4:** screenshot of the Home screen in Derja + `flutter test` output.

---

## Phase 5 — Feet module live
**Tech:** mqtt_client, FootRule (dT ≥ 2.2 °C, 2-day persistence, demo mode), CustomPainter feet.

**5.1** Phone and laptop on the **same hotspot**. On the laptop `ipconfig` → IPv4 of that adapter.
**5.2** App → Feet → type the IP → 🔗 connect → green dot.
**5.3** Run the bridge with `--fake`: every 3rd scan is a hotspot → amber, then red (demo mode = 1 scan per day).
**5.4** Same with the real board.
- ✅ Done when: a hotspot opens the full-screen alert with the foot drawing, the hot site and the difference table.

🔒 **Gate 5:** short screen recording of green → amber → red.

---

## Phase 6 — Glucose and medication
**Tech:** fl_chart, Hive, g/L units.

**6.1** Add 5 readings (try 0.65 → low-sugar dialog; 2.80 → high).
**6.2** Add a medication with 2 times, tick one → adherence % updates; Home "today's plan" progresses.
- ✅ Done when: chart shows the readings with the 0.70 and 1.80 dashed lines.

🔒 **Gate 6:** screenshots of Glucose and Meds.

---

## Phase 7 — AI (Gemini)
**Tech:** Gemini API via REST (`http`), system prompt with safety rules (`docs/ai-safety.md`).

**7.1** Create a free API key at Google AI Studio. Check the current "flash" model name there; if it isn't `gemini-2.5-flash`,
run with `--dart-define=GEMINI_MODEL=<name>`.
**7.2** `flutter run --dart-define=GEMINI_API_KEY=<key>`
**7.3** Test: scan explanation (alert screen), glucose ✨ button, Learn → coach, the 4 safety prompts in `docs/ai-safety.md`.
- ✅ Done when: all 4 safety prompts behave as expected in Derja and French.

🔒 **Gate 7:** paste the 4 answers.

---

## Phase 8 — Alerts and doctor report
**Tech:** wa.me deep links (url_launcher), audioplayers, pdf + printing.

**8.1** Record the 4 Derja clips (`app/assets/audio/README.md`), drop them in `app/assets/audio/`.
**8.2** Alert → "Tell my family" opens WhatsApp with the pre-filled message to the relative's number.
**8.3** Me → Doctor report → PDF with AI summary, glucose and scan tables → share.
- ✅ Done when: WhatsApp opens with the message; the PDF opens and lists the scans.

🔒 **Gate 8:** screenshot of the WhatsApp message + first page of the PDF.

---

## Phase 9 — Quality
**Tech:** flutter analyze/test, pyflakes, arduino/compile-sketches, gitleaks — `.github/workflows/ci.yml`.

**9.1** Commit `app/android`, `pubspec.yaml`, `pubspec.lock` (generated in Phase 4). Never commit the Gemini key.
**9.2** Push `dev`, open a PR to `main` → all 4 CI jobs green.
- ✅ Done when: CI green, README screenshots added.

🔒 **Gate 9:** link to the green PR.

---

## Phase 10 — Demo
**10.1** Demo script (3 min): onboarding already done → home dashboard → glucose entry with AI explanation →
live foot scan normal → warm compress → amber → second scan → **red** + Derja voice + WhatsApp → doctor PDF.
**10.2** Record a backup video of the full run.
**10.3** Pitch: problem (2M+ diabetics in Tunisia), insight (temperature asymmetry, VA −71% amputations),
live demo, tech (IoT + MQTT + Flutter + Gemini with safety rules), roadmap (8-sensor mat → socks/insole, clinic dashboard).
- ✅ Done when: 5 full rehearsals under 3 min, backup video saved offline.

🔒 **Gate 10:** you're ready.

---

## Future (after the hackathon)
Backend + accounts (Supabase), nurse dashboard, reminders with flutter_local_notifications, Bluetooth/Wi-Fi direct from
the ESP32 (no laptop), insole/socks form factor, clinical validation with a diabetology department.
