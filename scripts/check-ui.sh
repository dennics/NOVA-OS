#!/usr/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
binary=${1:-build/native/nova-control-center}
output=${2:-artifacts/native}
mkdir -p "$output"
test_config=$(mktemp -d)
trap 'rm -f "$test_config/novarc" "$test_config/welcome"; rmdir "$test_config"' EXIT
export QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software QT_SCALE_FACTOR=1 QT_FORCE_STDERR_LOGGING=1
for resolution in 1280x720 1920x1080; do
    for page in overview appearance performance system; do
        "$binary" --no-desktop-integration --config "$test_config/novarc" \
            --page "$page" --width "${resolution%x*}" --height "${resolution#*x}" \
            --screenshot "$output/$page-$resolution.png"
    done
done
"$binary" --no-desktop-integration --config "$test_config/welcome" --welcome \
    --width 1280 --height 720 --screenshot "$output/welcome-1280x720.png"
QT_SCALE_FACTOR=1.5 "$binary" --no-desktop-integration --config "$test_config/novarc" \
    --page appearance --width 1280 --height 720 --screenshot "$output/appearance-scale150.png"
python3 - "$output" <<'PY'
import json
from pathlib import Path
import struct
import sys
result = []
for path in sorted(Path(sys.argv[1]).glob("*.png")):
    header = path.read_bytes()[:24]
    assert header[:8] == b"\x89PNG\r\n\x1a\n", path
    width, height = struct.unpack(">II", header[16:24])
    result.append({"file": path.name, "width": width, "height": height})
print(json.dumps(result, indent=2))
PY
