"""End-to-end: bridge simulator -> MQTT broker (embedded amqtt) -> hub ingestion -> REST API."""
import argparse
import asyncio
import socket
import sys
import threading
import time
from pathlib import Path

import paho.mqtt.client as mqtt
import pytest
from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "bridge"))
import qadam_bridge as qb  # noqa: E402

from qadam_hub.config import Settings  # noqa: E402
from qadam_hub.main import create_app  # noqa: E402


def free_port() -> int:
    s = socket.socket()
    s.bind(("127.0.0.1", 0))
    p = s.getsockname()[1]
    s.close()
    return p


def wait(cond, timeout=8.0):
    end = time.time() + timeout
    while time.time() < end:
        if cond():
            return True
        time.sleep(0.1)
    return False


@pytest.fixture()
def env(tmp_path, monkeypatch):
    port = free_port()
    monkeypatch.setenv("QADAM_DB", str(tmp_path / "e2e.db"))
    monkeypatch.setenv("QADAM_DATA_KEY", "MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=")
    monkeypatch.setenv("QADAM_MQTT_PORT", str(port))
    monkeypatch.setenv("QADAM_EMBEDDED_BROKER", "1")
    monkeypatch.setenv("GEMINI_API_KEY", "")
    return Settings(), port


def test_simulated_bridge_to_hub(env):
    cfg, port = env
    with TestClient(create_app(cfg)) as c:
        ingest = c.app.state.ingest
        assert wait(lambda: ingest.connected), "hub did not connect to the embedded broker"
        args = argparse.Namespace(root="qadam", broker="127.0.0.1", mqtt_port=port, tls=False, cafile=None)
        st = qb.BridgeState("bench-01", "simulated", port="simulator")
        pub = qb.Publisher(args, st)
        assert wait(lambda: pub.client.is_connected())
        sim = qb.Simulator(seed=3)
        for _ in range(3):
            qb.handle_line(sim.next_line(), st, pub, "simulated-DHT22")
        sim.key("h")
        qb.handle_line(sim.next_line(), st, pub, "simulated-DHT22")
        pub.status()
        assert wait(lambda: ingest.stats["frames"] >= 4 and ingest.stats["status"] >= 1)

        # malformed JSON and a frame without source are rejected, not stored
        raw = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
        raw.connect("127.0.0.1", port)
        raw.loop_start()
        raw.publish("qadam/bench-01/live", b"{not json", qos=1).wait_for_publish()
        raw.publish("qadam/bench-01/live", b'{"device_id":"bench-01","left":{"mth1":30}}', qos=1).wait_for_publish()
        assert wait(lambda: ingest.stats["rejected"] >= 2)
        raw.loop_stop()
        raw.disconnect()

        tok = c.post("/api/auth/login", json={"username": cfg.clinician_user, "password": cfg.clinician_password}).json()["token"]
        h = {"Authorization": f"Bearer {tok}"}
        dev = next(d for d in c.get("/api/devices", headers=h).json() if d["id"] == "bench-01")
        assert dev["state"] == "online" and dev["source"] == "simulated" and dev["counters"]["frames"] == 4
        detail = c.get(f"/api/patients/{cfg.demo_patient}", headers=h).json()
        assert len(detail["live"]) == 4 and all(r["source"] == "simulated" for r in detail["live"])
        assert detail["live"][-1]["right"]["mth1"] - detail["live"][-1]["left"]["mth1"] > 2.5
        pub.close()
        assert wait(lambda: c.app.state.db.one("SELECT state FROM devices WHERE id='bench-01'")["state"] == "offline")
