"""Copy shared/*.json (rule vectors excluded) into the Flutter assets so app and hub use identical safety content."""
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
for name in ("red_flags.json", "assistant_library.json"):
    shutil.copyfile(ROOT / "shared" / name, ROOT / "app" / "assets" / "data" / name)
    print("copied", name)
