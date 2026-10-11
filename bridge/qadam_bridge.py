"""Qadam bridge: Arduino (USB serial) -> MQTT, or a clearly labelled simulator.

  Real hardware : python bridge/qadam_bridge.py --port COM5
  Simulation    : python bridge/qadam_bridge.py --simulate
  List ports    : python bridge/qadam_bridge.py --list-ports

Topics (docs/mqtt-contract.md):
  qadam/<device>/live    measurement frames, QoS 1, retained
  qadam/<device>/status  bridge health (online/offline/error + counters), QoS 1, retained, also the MQTT last will

Rules:
  * Every payload carries "source": "hardware" or "simulated". The bridge NEVER switches to simulation by itself:
    if the board disappears it publishes status "error" and keeps retrying the serial port.
  * Frames with a bad CRC or format are dropped and counted, never forwarded.
"""
from __future__ import annotations

import argparse
import json
import logging
import queue
import random
import sys
import threading
import time
from dataclasses import dataclass, field

import paho.mqtt.client as mqtt

import frame as fr

log = logging.getLogger("qadam.bridge")


@dataclass
class Counters:
    frames: int = 0
    bad_checksum: int = 0
    parse_errors: int = 0
    sensor_faults: int = 0
    seq_gaps: int = 0
    info_lines: int = 0

    def as_dict(self) -> dict:
        return self.__dict__.copy()


@dataclass
class BridgeState:
    device: str
    source: str
    port: str = ""
    counters: Counters = field(default_factory=Counters)
    last_seq: int | None = None
    last_frame_at: float = 0.0
    state: str = "starting"
    detail: str = ""


class Publisher:
    def __init__(self, args, st: BridgeState) -> None:
        self.args, self.st = args, st
        self.live_topic = f"{args.root}/{st.device}/live"
        self.status_topic = f"{args.root}/{st.device}/status"
        self.client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2, client_id=f"qadam-bridge-{st.device}-{random.randint(0, 9999)}")
        will = json.dumps({"state": "offline", "source": st.source, "detail": "bridge disconnected unexpectedly"})
        self.client.will_set(self.status_topic, will, qos=1, retain=True)
        if args.tls:
            self.client.tls_set(ca_certs=args.cafile)
        self.client.reconnect_delay_set(1, 10)
        self.client.connect_async(args.broker, args.mqtt_port, keepalive=20)
        self.client.loop_start()

    def live(self, payload: dict) -> None:
        self.client.publish(self.live_topic, json.dumps(payload, separators=(",", ":")), qos=1, retain=True)

    def status(self) -> None:
        st = self.st
        body = {"state": st.state, "source": st.source, "port": st.port, "detail": st.detail,
                "counters": st.counters.as_dict(), "ts": int(time.time() * 1000),
                "last_frame_age_s": round(time.time() - st.last_frame_at, 1) if st.last_frame_at else None}
        self.client.publish(self.status_topic, json.dumps(body, separators=(",", ":")), qos=1, retain=True)

    def close(self) -> None:
        self.st.state, self.st.detail = "offline", "bridge stopped"
        self.status()
        time.sleep(0.3)
        self.client.loop_stop()
        self.client.disconnect()


def handle_line(line: str, st: BridgeState, pub: Publisher, sensor: str) -> dict | None:
    """Validate one serial line and publish it. Returns the payload (for tests) or None."""
    line = line.strip()
    if not line:
        return None
    if line.startswith("#"):
        st.counters.info_lines += 1
        log.info("board: %s", line[1:].strip())
        if "error" in line.lower():
            st.detail = line[1:].strip()
        return None
    try:
        f = fr.parse(line)
    except fr.FrameError as e:
        if e.kind == "checksum":
            st.counters.bad_checksum += 1
        else:
            st.counters.parse_errors += 1
        log.warning("dropped frame (%s): %r", e, line[:80])
        return None
    if st.last_seq is not None and f.seq != st.last_seq + 1 and f.seq > 1:
        st.counters.seq_gaps += 1
    st.last_seq = f.seq
    st.counters.frames += 1
    st.last_frame_at = time.time()
    if f.left_fault or f.right_fault:
        st.counters.sensor_faults += 1
        st.state, st.detail = "online", "sensor fault: " + ", ".join(
            s for s, bad in (("left", f.left_fault), ("right", f.right_fault)) if bad)
    else:
        st.state, st.detail = "online", "warming up" if f.warming_up else "ok"
    payload = fr.to_payload(f, st.device, st.source, int(time.time() * 1000), sensor=sensor)
    pub.live(payload)
    return payload


# ---------------------------------------------------------------- hardware mode
def run_serial(args, st: BridgeState, pub: Publisher, stop: threading.Event) -> None:
    import serial  # pyserial

    while not stop.is_set():
        try:
            with serial.Serial(args.port, args.baud, timeout=1) as ser:
                log.info("serial %s open at %d baud", args.port, args.baud)
                st.state, st.detail = "online", "port open, waiting for frames"
                pub.status()
                last_status = 0.0
                while not stop.is_set():
                    raw = ser.readline()
                    if raw:
                        handle_line(raw.decode("ascii", errors="replace"), st, pub, args.sensor)
                    if st.last_frame_at and time.time() - st.last_frame_at > 8:
                        st.state, st.detail = "error", "no valid frame for 8 s (check board / baud rate)"
                    if time.time() - last_status > 5:
                        pub.status()
                        last_status = time.time()
        except Exception as e:  # port busy (Serial Monitor open), cable unplugged...
            st.state, st.detail = "error", f"serial: {e}"
            log.error("%s - retrying in 2 s (simulation is NOT started automatically)", e)
            pub.status()
            stop.wait(2)


# ---------------------------------------------------------------- simulation mode
class Simulator:
    """Generates firmware-identical frames (same CRC path). Scenario keys: n normal, h right foot hotspot,
    l left foot hotspot, f left sensor fault, x noisy readings, q quit."""

    def __init__(self, seed: int | None = None) -> None:
        self.rnd = random.Random(seed)
        self.scenario = "normal"
        self.seq = 0
        self.base = 30.4

    def next_line(self) -> str:
        self.seq += 1
        r = self.rnd
        self.base += r.uniform(-0.05, 0.05)
        tl = self.base + r.uniform(-0.1, 0.1)
        tr = self.base + r.uniform(-0.1, 0.1) + r.uniform(-0.2, 0.2)
        sl, sr, flags = r.uniform(0.0, 0.2), r.uniform(0.0, 0.2), 0
        if self.scenario == "hot_right":
            tr = tl + 2.8 + r.uniform(-0.1, 0.1)
        elif self.scenario == "hot_left":
            tl = tr + 2.6 + r.uniform(-0.1, 0.1)
        elif self.scenario == "noisy":
            sl, sr = r.uniform(0.6, 1.0), r.uniform(0.5, 0.9)
        frame = fr.Frame(self.seq, round(tl, 2), round(tr, 2), round(sl, 2), round(sr, 2), 4,
                         round(45 + r.uniform(-2, 2), 1), round(46 + r.uniform(-2, 2), 1), flags)
        if self.scenario == "fault_left":
            frame.t_left, frame.spread_left, frame.h_left, frame.samples = None, None, None, 0
            frame.flags |= fr.FLAG_LEFT_FAULT
        return fr.encode(frame)

    def key(self, k: str) -> bool:
        mapping = {"n": "normal", "h": "hot_right", "l": "hot_left", "f": "fault_left", "x": "noisy"}
        if k in mapping:
            self.scenario = mapping[k]
            log.info("SIMULATION scenario -> %s", self.scenario)
            return True
        return False


def _keyboard(q: queue.Queue) -> None:
    try:
        import msvcrt  # Windows: single key press
        while True:
            q.put(msvcrt.getwch().lower())
    except ImportError:
        for line in sys.stdin:  # other OS: type a letter + Enter
            for ch in line.strip().lower():
                q.put(ch)


def run_simulation(args, st: BridgeState, pub: Publisher, stop: threading.Event) -> None:
    sim = Simulator()
    keys: queue.Queue = queue.Queue()
    threading.Thread(target=_keyboard, args=(keys,), daemon=True).start()
    script = [(p.split(":")[0], int(p.split(":")[1])) for p in args.script.split(",")] if args.script else []
    print("SIMULATION MODE - every frame is labelled source=simulated.\n"
          "Keys: [n] normal  [h] right-foot hotspot  [l] left-foot hotspot  [f] left sensor fault  [x] noisy  [q] quit")
    st.state, st.detail, st.port = "online", "simulator", "simulator"
    last_status = 0.0
    seg, in_seg = 0, 0
    while not stop.is_set():
        while not keys.empty():
            k = keys.get()
            if k == "q":
                stop.set()
            sim.key(k)
        if script:  # unattended demo: cycle through scenario segments
            key, count = script[seg % len(script)]
            if in_seg == 0:
                sim.key(key)
            in_seg += 1
            if in_seg >= max(count, 1):
                seg, in_seg = seg + 1, 0
        handle_line(sim.next_line(), st, pub, "simulated-DHT22")
        if time.time() - last_status > 5:
            pub.status()
            last_status = time.time()
        stop.wait(args.period)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Qadam serial -> MQTT bridge")
    mode = ap.add_mutually_exclusive_group(required=True)
    mode.add_argument("--port", help="serial port of the Arduino, e.g. COM5 or /dev/ttyACM0")
    mode.add_argument("--simulate", action="store_true", help="labelled simulated frames (no hardware)")
    mode.add_argument("--list-ports", action="store_true")
    ap.add_argument("--device", default="bench-01")
    ap.add_argument("--sensor", default="DHT22")
    ap.add_argument("--baud", type=int, default=115200)
    ap.add_argument("--broker", default="127.0.0.1")
    ap.add_argument("--mqtt-port", type=int, default=1883)
    ap.add_argument("--root", default="qadam")
    ap.add_argument("--period", type=float, default=2.5, help="simulation period in seconds")
    ap.add_argument("--script", default="", help="simulation script, e.g. n:4,h:8 (scenario:frames)")
    ap.add_argument("--tls", action="store_true")
    ap.add_argument("--cafile")
    args = ap.parse_args(argv)
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

    if args.list_ports:
        from serial.tools import list_ports
        for p in list_ports.comports():
            print(f"{p.device:10} {p.description}")
        return 0

    st = BridgeState(device=args.device, source="simulated" if args.simulate else "hardware", port=args.port or "")
    pub = Publisher(args, st)
    stop = threading.Event()
    try:
        (run_simulation if args.simulate else run_serial)(args, st, pub, stop)
    except KeyboardInterrupt:
        pass
    finally:
        stop.set()
        pub.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
