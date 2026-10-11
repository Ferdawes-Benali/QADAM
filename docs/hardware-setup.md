# Hardware setup — Arduino Uno + 2 × DHT22 bench

## Role of each sensor

| Sensor | Pin | Physical role | What it really measures |
| --- | --- | --- | --- |
| DHT22 **LEFT** | D2 | under the left foot, 1st metatarsal head area (`mth1`) | air temperature in the small pocket under the forefoot (°C, ±0.5 °C, 0.1 °C resolution) + humidity |
| DHT22 **RIGHT** | D3 | same spot under the right foot | same |

The app compares **left vs right at the same site**. With DHT22s this demonstrates the data chain and the alert
logic; it is **not** a measurement of skin temperature and must not be used to judge a patient. The production mat
uses contact sensors (DS18B20 / NTC) — see `hardware/esp32_qadam_mat` and the Wokwi simulation.

## Bill of materials (bench)

| Qty | Part | Notes |
| --- | --- | --- |
| 1 | Arduino Uno R3 (or compatible) + USB cable | powered by the laptop USB (5 V) |
| 2 | DHT22 / AM2302 (3-pin module preferred) | module = built-in pull-up |
| 2 | 10 kΩ resistor | **only** for bare 4-pin DHT22 sensors (DATA → 5 V pull-up) |
| 1 + 1 | green LED, red LED | status only |
| 2 | 220 Ω resistor | LED current ≈ 13 mA |
| 1 | active 5 V buzzer (≤ 20 mA) | optional |
| — | breadboard, jumper wires, 2 foam pads / cups | foam pads hold each sensor under the forefoot |

## Wiring

```
Arduino Uno                     DHT22 LEFT (module)        DHT22 RIGHT (module)
  5V  ─────────────┬──────────── VCC (+)       ┌────────── VCC (+)
                   └───────────────────────────┘
  GND ─────────────┬──────────── GND (−)       ┌────────── GND (−)
                   └───────────────────────────┘
  D2  ────────────────────────── DATA (OUT)
  D3  ─────────────────────────────────────────────────── DATA (OUT)

  D5 ── 220 Ω ── LED green (anode → cathode) ── GND
  D6 ── 220 Ω ── LED red   (anode → cathode) ── GND
  D8 ── buzzer (+) ; buzzer (−) ── GND
```

Bare 4-pin DHT22 (front grid facing you, pins down, left→right): **1 VCC · 2 DATA · 3 not connected · 4 GND**, plus a
10 kΩ resistor between pin 1 and pin 2.

| From | To | Wire colour (suggested) |
| --- | --- | --- |
| Uno 5V | both DHT VCC | red |
| Uno GND | both DHT GND, LED cathodes, buzzer − | black |
| Uno D2 | DHT LEFT DATA | yellow |
| Uno D3 | DHT RIGHT DATA | orange |
| Uno D5 | 220 Ω → green LED | green |
| Uno D6 | 220 Ω → red LED | white |
| Uno D8 | buzzer + | blue |

## Electrical and safety precautions

- Power **only** from the laptop USB (5 V, < 500 mA). Never from mains, never a bare battery on the board.
- Total current is small (2 × 1.5 mA DHT + 2 × 13 mA LEDs + ≤ 20 mA buzzer ≈ 50 mA): within Uno limits
  (40 mA max per pin; keep the buzzer ≤ 20 mA or drive it through a transistor).
- Keep electronics dry. Feet must be clean and dry; put a thin plastic film over the foam pads.
- No exposed solder joints in contact with skin. The bench is for demonstration on the team, not on patients.
- DHT22 needs ≥ 2 s between readings and ~2 s after power-up (handled by the firmware).
- Long wires (> 1 m) on DATA lines may need a stronger pull-up (4.7 kΩ).

## Flash the firmware

1. Arduino IDE → *Library Manager*: install **DHT sensor library** (Adafruit) and **Adafruit Unified Sensor**.
2. Open `hardware/uno_dht_bench/uno_dht_bench.ino`. If you have DHT11s, change `#define DHT_TYPE DHT22` to `DHT11`.
3. *Tools → Board → Arduino Uno*, *Tools → Port → COMx* (the one that appears when you plug the board).
4. Upload. Two short beeps = boot.
5. *Serial Monitor* at **115200 baud**: you should see `#QDM boot ...` then one `$QDM,...*XX` line every 2.5 s.
   The first 3 frames have flag `4` (warming up) — normal.
6. **Close the Serial Monitor** (the bridge needs the COM port), then:
   `python bridge\qadam_bridge.py --port COM5`

## Verification checklist

| Test | Expected |
| --- | --- |
| Both sensors in open air | `tL` ≈ `tR` (±0.5 °C), green LED blinks every 2.5 s |
| Hold the RIGHT sensor in your hand 20 s | `tR` rises 2–6 °C; app live difference turns amber; a scan → amber |
| Second scan while still warm (demo mode) | red alert, appears in the dashboard triage queue |
| Unplug LEFT DATA wire | `#QDM error left sensor...`, red LED, long beep; app shows "sensor fault", scan refuses to compute |
| Unplug USB | bridge prints `serial: ...` and retries; app shows "data stale" after 15 s; **no** simulated data appears |

## Host test (no board needed)

`hardware/uno_dht_bench/host_test` compiles the real sketch on a PC with a small Arduino shim and scripted sensor
values; its output (`frames.txt`) is parsed by the bridge tests to prove the CRC and frame format match:

```bash
cd hardware/uno_dht_bench/host_test && g++ -std=c++17 -I. -o fw_host main.cpp && ./fw_host > frames.txt
```
