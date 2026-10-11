import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import frame as fr  # noqa: E402
import qadam_bridge as qb  # noqa: E402

FIRMWARE_OUTPUT = Path(__file__).resolve().parents[2] / "hardware" / "uno_dht_bench" / "host_test" / "frames.txt"


class FakePub:
    def __init__(self):
        self.live_msgs, self.status_msgs = [], 0

    def live(self, p):
        self.live_msgs.append(p)

    def status(self):
        self.status_msgs += 1


def test_crc_known_value():
    # CRC-8/ATM check value for "123456789" is 0xF4
    assert fr.crc8("123456789") == 0xF4


def test_roundtrip_and_payload():
    f = fr.Frame(7, 30.8, 33.6, 0.1, 0.2, 4, 45.0, 46.0, 0)
    line = fr.encode(f)
    g = fr.parse(line)
    assert g == f
    p = fr.to_payload(g, "bench-01", "hardware", 1)
    assert p["left"] == {"mth1": 30.8} and p["right"] == {"mth1": 33.6} and p["faults"] == [] and p["source"] == "hardware"


@pytest.mark.parametrize("line,kind", [
    ("$QDM,1,7,30.80,33.60,0.10,0.20,4,45.0,46.0,0*00", "checksum"),
    ("QDM,1,7,30.80*12", "format"),
    ("$QDM,1,7,30.80,33.60*" + f"{fr.crc8('QDM,1,7,30.80,33.60'):02X}", "format"),
    ("$QDM,2,7,30.80,33.60,0.10,0.20,4,45.0,46.0,0*" + f"{fr.crc8('QDM,2,7,30.80,33.60,0.10,0.20,4,45.0,46.0,0'):02X}", "version"),
])
def test_bad_frames_rejected(line, kind):
    with pytest.raises(fr.FrameError) as e:
        fr.parse(line)
    assert e.value.kind == kind


def test_handle_line_counts_and_faults():
    st, pub = qb.BridgeState("bench-01", "hardware"), FakePub()
    assert qb.handle_line("#QDM boot", st, pub, "DHT22") is None
    assert qb.handle_line("garbage line", st, pub, "DHT22") is None
    good = fr.encode(fr.Frame(1, 30.0, 30.2, 0, 0, 4, 45, 45, 0))
    qb.handle_line(good, st, pub, "DHT22")
    corrupted = good.replace("30.20", "39.20")  # bit flip on the wire -> CRC mismatch
    assert qb.handle_line(corrupted, st, pub, "DHT22") is None
    fault = fr.encode(fr.Frame(3, None, 30.2, None, 0, 0, None, 45, fr.FLAG_LEFT_FAULT))
    p = qb.handle_line(fault, st, pub, "DHT22")
    assert p["left"] == {} and p["faults"] == ["left_sensor"]
    c = st.counters
    assert (c.frames, c.bad_checksum, c.parse_errors, c.sensor_faults, c.seq_gaps, c.info_lines) == (2, 1, 1, 1, 1, 1)
    assert len(pub.live_msgs) == 2


def test_simulator_is_labelled_and_scenarios_work():
    sim, st, pub = qb.Simulator(seed=1), qb.BridgeState("bench-01", "simulated"), FakePub()
    for _ in range(3):
        qb.handle_line(sim.next_line(), st, pub, "simulated-DHT22")
    sim.key("h")
    p = qb.handle_line(sim.next_line(), st, pub, "simulated-DHT22")
    assert all(m["source"] == "simulated" for m in pub.live_msgs)
    assert p["right"]["mth1"] - p["left"]["mth1"] > 2.5
    sim.key("f")
    p = qb.handle_line(sim.next_line(), st, pub, "simulated-DHT22")
    assert p["faults"] == ["left_sensor"]


@pytest.mark.skipif(not FIRMWARE_OUTPUT.exists(), reason="run hardware/uno_dht_bench/host_test first")
def test_real_firmware_output_is_accepted():
    st, pub = qb.BridgeState("bench-01", "hardware"), FakePub()
    for line in FIRMWARE_OUTPUT.read_text().splitlines():
        qb.handle_line(line, st, pub, "DHT22")
    assert st.counters.bad_checksum == 0 and st.counters.parse_errors == 0
    assert st.counters.frames == 40 and st.counters.sensor_faults >= 1
