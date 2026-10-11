"""Qadam serial frame codec (shared by the bridge, the simulator and the tests).

    $QDM,1,<seq>,<tL>,<tR>,<spreadL>,<spreadR>,<n>,<hL>,<hR>,<flags>*<CRC8>

CRC-8/ATM: polynomial 0x07, init 0x00, over the characters between '$' and '*'.
"""
from __future__ import annotations

import math
from dataclasses import dataclass

FLAG_LEFT_FAULT = 0x01
FLAG_RIGHT_FAULT = 0x02
FLAG_WARMING_UP = 0x04


class FrameError(ValueError):
    def __init__(self, kind: str, detail: str = "") -> None:
        super().__init__(f"{kind}: {detail}" if detail else kind)
        self.kind = kind  # checksum | format | version


def crc8(data: str) -> int:
    crc = 0
    for byte in data.encode("ascii", errors="replace"):
        crc ^= byte
        for _ in range(8):
            crc = ((crc << 1) ^ 0x07) & 0xFF if crc & 0x80 else (crc << 1) & 0xFF
    return crc


@dataclass
class Frame:
    seq: int
    t_left: float | None
    t_right: float | None
    spread_left: float | None
    spread_right: float | None
    samples: int
    h_left: float | None
    h_right: float | None
    flags: int

    @property
    def left_fault(self) -> bool:
        return bool(self.flags & FLAG_LEFT_FAULT) or self.t_left is None

    @property
    def right_fault(self) -> bool:
        return bool(self.flags & FLAG_RIGHT_FAULT) or self.t_right is None

    @property
    def warming_up(self) -> bool:
        return bool(self.flags & FLAG_WARMING_UP)


def _num(s: str) -> float | None:
    if s.lower() == "nan":
        return None
    v = float(s)
    return None if math.isnan(v) else v


def parse(line: str) -> Frame:
    line = line.strip()
    if not line.startswith("$") or "*" not in line:
        raise FrameError("format", "missing $ or *")
    body, _, crc_hex = line[1:].rpartition("*")
    try:
        expected = int(crc_hex, 16)
    except ValueError:
        raise FrameError("format", "bad checksum field") from None
    if crc8(body) != expected:
        raise FrameError("checksum", f"got {crc_hex}, computed {crc8(body):02X}")
    f = body.split(",")
    if len(f) != 11 or f[0] != "QDM":
        raise FrameError("format", f"{len(f)} fields")
    if f[1] != "1":
        raise FrameError("version", f[1])
    try:
        return Frame(seq=int(f[2]), t_left=_num(f[3]), t_right=_num(f[4]), spread_left=_num(f[5]),
                     spread_right=_num(f[6]), samples=int(f[7]), h_left=_num(f[8]), h_right=_num(f[9]), flags=int(f[10]))
    except ValueError as e:
        raise FrameError("format", str(e)) from None


def encode(fr: Frame) -> str:
    def n(v: float | None, d: int) -> str:
        return "nan" if v is None else f"{v:.{d}f}"
    body = (f"QDM,1,{fr.seq},{n(fr.t_left, 2)},{n(fr.t_right, 2)},{n(fr.spread_left, 2)},{n(fr.spread_right, 2)},"
            f"{fr.samples},{n(fr.h_left, 1)},{n(fr.h_right, 1)},{fr.flags}")
    return f"${body}*{crc8(body):02X}"


def to_payload(fr: Frame, device_id: str, source: str, ts_ms: int, sensor: str = "DHT22", site: str = "mth1") -> dict:
    """MQTT payload v2 (docs/mqtt-contract.md). A faulty side is sent empty + listed in faults, never guessed."""
    faults = []
    if fr.left_fault:
        faults.append("left_sensor")
    if fr.right_fault:
        faults.append("right_sensor")
    return {
        "v": 2, "device_id": device_id, "source": source, "sensor": sensor, "seq": fr.seq, "ts": ts_ms,
        "left": {} if fr.left_fault else {site: round(fr.t_left, 2)},
        "right": {} if fr.right_fault else {site: round(fr.t_right, 2)},
        "spread": {"left": fr.spread_left or 0.0, "right": fr.spread_right or 0.0},
        "samples": fr.samples, "humidity": {"left": fr.h_left, "right": fr.h_right},
        "faults": faults, "warming_up": fr.warming_up, "integrity": "ok",
    }
