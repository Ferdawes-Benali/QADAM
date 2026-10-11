"""Runtime configuration from environment variables (see .env.example)."""
from __future__ import annotations

import base64
import os
import secrets
from pathlib import Path

HUB_DIR = Path(__file__).resolve().parent.parent
REPO_DIR = HUB_DIR.parent
SHARED_DIR = Path(os.environ.get("QADAM_SHARED_DIR", REPO_DIR / "shared"))
STATIC_DIR = HUB_DIR / "static"
DATA_DIR = Path(os.environ.get("QADAM_DATA_DIR", HUB_DIR / "data"))


def _env(name: str, default: str = "") -> str:
    return os.environ.get(name, default).strip()


class Settings:
    def __init__(self) -> None:
        self.db_path = Path(_env("QADAM_DB", str(DATA_DIR / "qadam.db")))
        self.mqtt_host = _env("QADAM_MQTT_HOST", "127.0.0.1")
        self.mqtt_port = int(_env("QADAM_MQTT_PORT", "1883"))
        self.mqtt_enabled = _env("QADAM_MQTT_ENABLED", "1") == "1"
        self.embedded_broker = _env("QADAM_EMBEDDED_BROKER", "0") == "1"
        self.topic_root = _env("QADAM_TOPIC_ROOT", "qadam")
        self.gemini_key = _env("GEMINI_API_KEY")
        self.gemini_model = _env("GEMINI_MODEL", "gemini-3.8-flash")
        self.demo_mode = _env("QADAM_DEMO_MODE", "1") == "1"  # previous scan counts as "yesterday"
        self.demo_device = _env("QADAM_DEMO_DEVICE", "bench-01")
        self.demo_patient = _env("QADAM_DEMO_PATIENT", "QDM-2048")
        self.demo_pairing_code = _env("QADAM_DEMO_PAIRING_CODE", "246810")
        self.clinician_user = _env("QADAM_CLINICIAN_USER", "dr.demo")
        self.clinician_password = _env("QADAM_CLINICIAN_PASSWORD", "qadam-demo-2026")
        self.stale_after_s = int(_env("QADAM_STALE_AFTER_S", "15"))
        self.seed_synthetic = _env("QADAM_SEED", "1") == "1"
        key_b64 = _env("QADAM_DATA_KEY")
        self.data_key = base64.b64decode(key_b64) if key_b64 else _local_key()


def _local_key() -> bytes:
    """AES-256 key for field encryption. Generated once and kept next to the database (demo only).
    In production the key comes from a secrets manager / HSM, never from the same disk as the data."""
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    path = DATA_DIR / ".data_key"
    if path.exists():
        return base64.b64decode(path.read_text().strip())
    key = secrets.token_bytes(32)
    path.write_text(base64.b64encode(key).decode())
    try:
        os.chmod(path, 0o600)
    except OSError:
        pass
    return key



