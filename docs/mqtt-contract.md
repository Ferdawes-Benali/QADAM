# MQTT contract

- Broker: Mosquitto on the laptop, port **1883**, anonymous (demo only)
- Topic: **`qadam/mat01/live`** (one topic per mat: `qadam/<device>/live`)
- QoS 1, **retained** (last scan delivered on subscribe)

## Payload — ESP32 8-sensor mat
```json
{ "patient_id": "P001", "device_id": "mat-01", "battery_v": 3.98,
  "left":  { "hallux": 31.20, "mth1": 30.80, "mth5": 30.10, "heel": 29.60 },
  "right": { "hallux": 31.00, "mth1": 33.40, "mth5": 30.30, "heel": 29.90 },
  "max_dt": 2.60, "site": "mth1", "ts": 1791652339564 }
```

## Payload — Uno + 2 DHT22 demo
```json
{ "left": 31.20, "right": 33.60, "dt": 2.40, "alert": true, "ts": 1791652339564 }
```
The app treats it as a single site (`mth1`).

## Test without the app
```powershell
& "C:\Program Files\mosquitto\mosquitto_sub.exe" -h 127.0.0.1 -t "qadam/#" -v
```
