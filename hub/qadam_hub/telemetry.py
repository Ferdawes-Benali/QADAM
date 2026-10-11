"""MQTT ingestion: subscribes to qadam/+/live (measurement frames) and qadam/+/status (bridge health)."""
from __future__ import annotations

import json
import logging
import threading

import paho.mqtt.client as mqtt

from . import domain
from .config import Settings
from .db import Database

log = logging.getLogger("qadam.mqtt")


class TelemetryIngest:
    def __init__(self, db: Database, cfg: Settings) -> None:
        self.db, self.cfg = db, cfg
        self.connected = False
        self.stats = {"frames": 0, "rejected": 0, "status": 0}
        self.last_error = ""
        self._client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2, client_id="qadam-hub", clean_session=True)
        self._client.on_connect = self._on_connect
        self._client.on_disconnect = self._on_disconnect
        self._client.on_message = self._on_message
        self._client.reconnect_delay_set(1, 10)
        self._lock = threading.Lock()

    def start(self) -> None:
        try:
            self._client.connect_async(self.cfg.mqtt_host, self.cfg.mqtt_port, keepalive=20)
            self._client.loop_start()
        except Exception as e:  # broker not running yet: paho retries in the background
            self.last_error = str(e)
            log.warning("MQTT connect failed: %s", e)

    def stop(self) -> None:
        try:
            self._client.loop_stop()
            self._client.disconnect()
        except Exception:
            pass

    def _on_connect(self, client, userdata, flags, reason_code, properties=None):
        if reason_code == 0 or getattr(reason_code, "value", 1) == 0:
            self.connected = True
            root = self.cfg.topic_root
            client.subscribe([(f"{root}/+/live", 1), (f"{root}/+/status", 1)])
            log.info("MQTT connected to %s:%s", self.cfg.mqtt_host, self.cfg.mqtt_port)
        else:
            self.last_error = f"connect refused: {reason_code}"

    def _on_disconnect(self, client, userdata, flags, reason_code, properties=None):
        self.connected = False

    def _on_message(self, client, userdata, msg):
        parts = msg.topic.split("/")
        if len(parts) != 3:
            return
        _, device_id, kind = parts
        try:
            payload = json.loads(msg.payload.decode("utf-8"))
        except (UnicodeDecodeError, ValueError):
            self.stats["rejected"] += 1
            self.last_error = f"malformed JSON on {msg.topic}"
            return
        try:
            with self._lock:
                if kind == "live":
                    if isinstance(payload, dict):
                        payload.setdefault("device_id", device_id)
                    domain.ingest_live(self.db, payload, self.cfg)
                    self.stats["frames"] += 1
                elif kind == "status":
                    domain.ingest_status(self.db, device_id, payload)
                    self.stats["status"] += 1
        except domain.PayloadError as e:
            self.stats["rejected"] += 1
            self.last_error = f"{msg.topic}: {e}"
        except Exception as e:  # never let a bad frame kill the ingest thread
            self.stats["rejected"] += 1
            self.last_error = f"{msg.topic}: {e}"
            log.exception("ingest error")


async def start_embedded_broker(port: int):
    """Optional pure-Python broker (amqtt) for laptops without Mosquitto. Mosquitto remains the reference."""
    from amqtt.broker import Broker

    config = {
        "listeners": {"default": {"type": "tcp", "bind": f"0.0.0.0:{port}"}},
        "sys_interval": 0,
        "auth": {"allow-anonymous": True, "plugins": ["auth_anonymous"]},
        "topic-check": {"enabled": False},
    }
    broker = Broker(config)
    await broker.start()
    return broker
