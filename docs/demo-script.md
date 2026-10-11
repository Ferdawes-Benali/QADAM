# Live demo script (3 minutes) — follows the cahier §9 protocol

**Assumption:** 3-minute live demo inside an ~8-minute slot (5 min pitch + 3 min demo), then Q&A. Adjust if the
jury announces another format. No video is used: everything below is manipulated live.

## Set-up (before entering the room, 10 min)

| # | Action | Check |
| --- | --- | --- |
| 1 | Laptop on the team phone hotspot (backup: second phone hotspot). Note the laptop IP (`ipconfig`). | IP noted on a sticky note |
| 2 | Terminal 1: `$env:QADAM_EMBEDDED_BROKER="1"; cd hub; python -m qadam_hub` | `http://localhost:8000/api/health` → `"mqtt_connected": true` |
| 3 | Terminal 2: `python bridge\qadam_bridge.py --port COM5` (real Uno). Backup: `--simulate` | bridge prints frames, no checksum drops |
| 4 | Browser: dashboard logged in (`dr.demo`), tab **Vue d'ensemble**, zoom 110 % | bench card "En ligne · Matériel réel" |
| 5 | Phone: app unlocked, language **Derja**, paired (code `246810`), Feet tab | "Mat connected · Real sensors" |
| 6 | Glass of warm water or a heat pack (or your hand) ready to warm the RIGHT sensor | — |
| 7 | Phone on screen mirroring (scrcpy) or a document camera | jury can see the phone |

## Step 1 — Clinical case (30 s, slide 2)

"Am Hédi (fictional persona), 62, type 2 diabetes for 15 years, a foot ulcer healed last year, reduced sensation.
Tonight he warms his feet near the kanoun. Inflammation starts under his right forefoot; he cannot feel it.
In 2–3 weeks it could be an open ulcer."

## Step 2 — Live demo (3 min)

| Time | Do | Say | Expected |
| --- | --- | --- | --- |
| 0:00 | Phone, Feet tab | "Every morning, 10 seconds on the mat." | live L/R ≈ equal, badge *Real sensors* |
| 0:15 | Tap **Start a 10 s scan**, hands off | "The board only measures; the decision is software, explainable." | countdown → **green**, "why" card: ΔT 0.2 °C < 2.2 |
| 0:40 | Warm the RIGHT sensor (hand / warm pack) ~20 s | "Simulating the inflammation: one spot gets warmer." | live difference turns amber on the phone |
| 1:00 | New scan | "Day 1: one hot spot — amber. Rest the foot, check shoes, rescan tomorrow." | **amber**, warmer side right, confidence shown |
| 1:25 | Keep warming, scan again | "Demo mode counts each scan as a day. Same spot two days in a row:" | **red** + Derja message, call doctor / WhatsApp family buttons |
| 1:45 | Switch to dashboard (auto-refresh) | "The care team sees it first in the triage queue." | red alert at the top, source *Matériel réel* |
| 2:00 | Open alert → evidence | "Why: 2.8 °C at the forefoot, threshold 2.2, 2 days, confidence 100 / 100. Advisory only." | evidence panel + 14-day chart |
| 2:20 | Choose **Confirm**, note "RDV demain 9h", save | "Three steps. Logged in a tamper-evident audit." | status *Confirmed* |
| 2:35 | Phone → More → Alerts and follow-up (syncs on open) | "Hédi sees his doctor's decision and note, in Derja." | "Your team confirmed… — RDV demain 9h" |
| 2:50 | Assistant: type `صبعي ولات كحلة` | "Danger signs never go to the AI: fixed rule, call 190." | urgent card, *fixed safety message (not AI)* |

## Fallbacks (decide in 2 seconds, never apologise for long)

| Problem | Fallback |
| --- | --- |
| Uno/sensor fails | Ctrl+C bridge, run `python bridge\qadam_bridge.py --simulate`, press `h` to create the hotspot. Say "this is the labelled simulation mode" — the app shows the SIMULATION badge. |
| Phone cannot reach laptop | Use the dashboard only: patient QDM-1001 already shows a red alert with full evidence; review it live. |
| Hub crashed | Restart Terminal 1 (data persists in SQLite). |
| Sensor does not warm enough | Hold the sensor in a closed fist / breathe on it; or switch to simulation. |
| AI offline | That's fine: the answer shows "verified library (no AI)" — mention it as a feature. |
| Wi-Fi of the venue | Never used: everything runs on the team hotspot; backup hotspot on a second phone. |

## Step 3 — Technical defence: likely questions

See docs/pitch-script.md § Q&A.
