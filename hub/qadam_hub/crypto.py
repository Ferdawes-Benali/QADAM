"""AES-256-GCM encryption for free-text fields at rest, PBKDF2 password hashing, token helpers."""
from __future__ import annotations

import base64
import hashlib
import hmac
import os
import secrets

from cryptography.hazmat.primitives.ciphers.aead import AESGCM

_PREFIX = "enc1:"


class FieldCipher:
    def __init__(self, key: bytes) -> None:
        if len(key) != 32:
            raise ValueError("QADAM_DATA_KEY must be 32 bytes (AES-256)")
        self._aes = AESGCM(key)

    def encrypt(self, text: str | None) -> str | None:
        if text is None or text == "":
            return text
        nonce = os.urandom(12)
        ct = self._aes.encrypt(nonce, text.encode("utf-8"), None)
        return _PREFIX + base64.b64encode(nonce + ct).decode()

    def decrypt(self, value: str | None) -> str | None:
        if not value or not value.startswith(_PREFIX):
            return value
        raw = base64.b64decode(value[len(_PREFIX):])
        return self._aes.decrypt(raw[:12], raw[12:], None).decode("utf-8")


def hash_password(password: str, salt: bytes | None = None, iterations: int = 200_000) -> str:
    salt = salt or os.urandom(16)
    dk = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, iterations)
    return f"pbkdf2_sha256${iterations}${base64.b64encode(salt).decode()}${base64.b64encode(dk).decode()}"


def verify_password(password: str, stored: str) -> bool:
    try:
        _, it, salt_b64, dk_b64 = stored.split("$")
        dk = hashlib.pbkdf2_hmac("sha256", password.encode(), base64.b64decode(salt_b64), int(it))
        return hmac.compare_digest(dk, base64.b64decode(dk_b64))
    except Exception:
        return False


def new_token() -> str:
    return secrets.token_urlsafe(32)


def token_hash(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()
