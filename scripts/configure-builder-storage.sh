#!/usr/bin/bash
set -euo pipefail
[[ $EUID == 0 ]] || { echo 'Use sudo in the dedicated builder VM.' >&2; exit 1; }
source /etc/os-release
[[ $ID == fedora && $VERSION_ID == 44 ]] || { echo 'Fedora 44 builder required.' >&2; exit 1; }
systemd-detect-virt -q || { echo 'This helper is restricted to the dedicated builder VM.' >&2; exit 1; }
install -d /etc/containers
if [[ ! -f /etc/containers/storage.conf ]]; then
    install -m 0644 /usr/share/containers/storage.conf /etc/containers/storage.conf
fi
# metacopy/redirect_dir force the naive whole-filesystem diff in this Fedora kernel.
# Keep overlay's native diff usable; this changes the builder, not the NOVA runtime.
python3 - <<'PY'
from pathlib import Path
import re
path = Path('/etc/containers/storage.conf')
text = path.read_text()
updated, count = re.subn(r'^mountopt\s*=.*$', 'mountopt = "nodev,metacopy=off,redirect_dir=off"', text, flags=re.M)
if count != 1:
    raise SystemExit('Expected one overlay mountopt entry; refusing an ambiguous storage configuration')
path.write_text(updated)
PY
status=$(podman info --format '{{json .Store.GraphStatus}}')
echo "$status"
jq -e '."Native Overlay Diff" == "true" and ."Using metacopy" == "false"' <<<"$status" >/dev/null

