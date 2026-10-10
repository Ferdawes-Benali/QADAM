"""Qadam bridge: board (USB serial) -> MQTT broker.

Works with both firmwares:
  - ESP32 mat   : {"patient_id":..,"left":{"hallux":..,"mth1":..,"mth5":..,"heel":..},"right":{...},"max_dt":..}
  - Uno DHT demo: {"left":31.2,"right":33.6,"dt":2.4,"alert":true}
Lines starting with '#' or not valid JSON are printed and ignored.

Usage (PowerShell):
  python bridge/serial_to_mqtt.py --port COM5
  python bridge/serial_to_mqtt.py --port COM5 --broker 127.0.0.1 --topic qadam/mat01/live
  python bridge/serial_to_mqtt.py --fake        # no board: publishes simulated scans (for app development)
"""
import argparse, json, random, time
import paho.mqtt.client as mqtt

p = argparse.ArgumentParser()
p.add_argument("--port", default="COM5")
p.add_argument("--baud", type=int, default=115200)
p.add_argument("--broker", default="127.0.0.1")
p.add_argument("--topic", default="qadam/mat01/live")
p.add_argument("--fake", action="store_true", help="publish simulated scans every 5 s")
a = p.parse_args()

client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2, client_id="qadam-bridge")
client.connect(a.broker, 1883, 60)
client.loop_start()


def publish(data: dict):
    data.setdefault("ts", int(time.time() * 1000))
    client.publish(a.topic, json.dumps(data), qos=1, retain=True)   # retain: app gets last scan on connect
    print("published:", data)


if a.fake:
    sites = ["hallux", "mth1", "mth5", "heel"]
    n = 0
    while True:
        left = {s: round(30.5 + random.uniform(-0.3, 0.3), 2) for s in sites}
        right = {s: round(left[s] + random.uniform(-0.4, 0.4), 2) for s in sites}
        if n % 3 == 2:                       # every third scan: hotspot on right MTH1
            right["mth1"] = round(left["mth1"] + 2.8, 2)
        publish({"patient_id": "P001", "device_id": "fake", "left": left, "right": right})
        n += 1
        time.sleep(5)

import serial  # imported here so --fake works without pyserial
ser = serial.Serial(a.port, a.baud, timeout=2)
print(f"Serial {a.port} -> mqtt://{a.broker}:1883/{a.topic}")
while True:
    line = ser.readline().decode(errors="ignore").strip()
    if not line:
        continue
    if not line.startswith("{"):
        print(line)
        continue
    try:
        publish(json.loads(line))
    except json.JSONDecodeError:
        print("ignored:", line)
