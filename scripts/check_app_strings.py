"""Static check of the Flutter app's translations (runs without the Flutter SDK; used in CI).
- every key used in lib/ exists in lib/core/strings.dart
- every dynamic key family is complete
- every entry has 3 non-empty translations with the same {placeholders}
- shared JSON copies in app/assets/data are identical to shared/
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "app" / "lib"
src = (LIB / "core" / "strings.dart").read_text(encoding="utf-8")

entries = {}
for m in re.finditer(r"^\s*'([a-zA-Z0-9_.]+)':\s*\[(.*?)\],\s*$", src, re.S | re.M):
    key, body = m.group(1), m.group(2)
    vals = re.findall(r"'((?:[^'\\]|\\.)*)'", body)
    entries[key] = vals

errors = []
for k, v in entries.items():
    if len(v) != 3 or any(not x.strip() for x in v):
        errors.append(f"{k}: expected 3 non-empty strings, got {len(v)}")
        continue
    ph = [sorted(set(re.findall(r"\{(\w+)\}", x))) for x in v]
    if not (ph[0] == ph[1] == ph[2]):
        errors.append(f"{k}: placeholders differ {ph}")

used, dynamic = set(), set()
pat = re.compile(r"""\bt\(\s*'([^']+)'|tr\(context,\s*'([^']+)'|'(scan\.err\.[a-zA-Z]+)'|'(pair\.err\.[a-zA-Z]+)'""")
for f in LIB.rglob("*.dart"):
    if f.name == "strings.dart":
        continue
    for m in pat.finditer(f.read_text(encoding="utf-8")):
        k = next(g for g in m.groups() if g)
        (dynamic if "$" in k else used).add(k)
for k in sorted(used):
    if k not in entries:
        errors.append(f"missing key: {k}")

FAMILIES = {
    "ai.danger.": ["emergency", "urgent"], "alerts.glucose.": ["low", "very_high"],
    "band.": ["low", "very_high", "in_target", "out_of_target"], "conf.": ["high", "medium", "low"],
    "conn.state.": ["notConfigured", "connecting", "brokerDown", "waiting", "online", "stale", "fault", "bridgeError"],
    "glu.low.": ["1", "2", "3"], "glu.saved.": ["in_target", "out_of_target"],
    "level.": ["green", "amber", "red", "none"], "result.head.": ["green", "amber", "red"],
    "result.why.": ["green", "amber", "red"], "review.": ["confirmed", "dismissed"],
    "risk.result.": ["low", "moderate", "high"], "riskLabel.": ["low", "moderate", "high"],
    "side.": ["left", "right"], "site.": ["mth1", "mth5", "hallux", "heel"],
    "source.": ["hardware", "simulated", "manual", "synthetic"],
    "sync.state.": ["idle", "syncing", "ok", "offline", "error", "notPaired"],
    "todo.green.": ["1", "2", "3"], "todo.amber.": ["1", "2", "3"], "todo.red.": ["1", "2", "3"],
    "type.": ["t1", "t2", "gest", "other"], "treat.": ["tablets", "insulin", "both", "diet"],
    "ctx.": ["fasting", "after_meal", "other"],
}
import json
lib = json.loads((ROOT / "shared" / "assistant_library.json").read_text(encoding="utf-8"))
FAMILIES["topic."] = [t["id"] for t in lib["topics"]]
for prefix, items in FAMILIES.items():
    for it in items:
        if prefix + it not in entries:
            errors.append(f"missing dynamic key: {prefix}{it}")

for name in ("red_flags.json", "assistant_library.json"):
    a = (ROOT / "shared" / name).read_bytes()
    b = (ROOT / "app" / "assets" / "data" / name).read_bytes()
    if a != b:
        errors.append(f"app/assets/data/{name} differs from shared/{name} (run: python scripts/sync_shared.py)")

print(f"{len(entries)} keys, {len(used)} literal uses, {len(dynamic)} dynamic uses checked")
if errors:
    print("\n".join(errors))
    sys.exit(1)
print("OK")
