# Qadam — patient app (Flutter, Android)

Patient-side app: daily foot scan on the Qadam mat, glucose and medication diary, safety-first assistant,
alerts reviewed by the care team, PDF report. Works offline; data encrypted on the phone (AES-256, key from the PIN).

```powershell
cd app
.\setup_app.ps1          # first time: generates android/, applies overrides, pub get, analyze, test
flutter run              # phone connected by USB (USB debugging on)
```

No API key in the app: the AI assistant goes through the care-team hub (`hub/`), which holds the Gemini key.

| Folder | Content |
| --- | --- |
| `lib/core` | design tokens, theme, strings (French / Arabic / Derja) |
| `lib/models` | data classes stored in Hive |
| `lib/services` | foot rule, safety triage, storage + crypto, MQTT, hub client, report, actions |
| `lib/state/app_state.dart` | single ChangeNotifier: lifecycle, live link, scan, sync, assistant |
| `lib/features/*` | screens |
| `assets/data` | copies of `shared/red_flags.json` and `shared/assistant_library.json` (`python scripts/sync_shared.py`) |
| `android_overrides` | AndroidManifest (queries, cleartext for the local demo hub) and launcher icons |
| `test` | rule vectors shared with the hub, safety, crypto (RFC vectors), strings, models |
