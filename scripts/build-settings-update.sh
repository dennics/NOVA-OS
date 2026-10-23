#!/usr/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ $EUID == 0 ]] || { echo 'Run in the dedicated Fedora builder as root.' >&2; exit 1; }
parent=localhost/nova:0.3.1-preview
actual_parent=$(podman image inspect --format '{{.Id}}' "$parent")
[[ "${actual_parent#sha256:}" == 0f8d4cdd2bcbcc441122c245e21454fb6cdd73af06c9e0b0b613fc580923a63a ]] || exit 2
cmake -S . -B build/native-v03 -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
cmake --build build/native-v03 --target nova-control-center nova_desktop_test -j2
ctest --test-dir build/native-v03 -R '^update-state-and-process-safety$' --output-on-failure
install -D -m 0755 build/native-v03/nova-control-center build/settings-install/usr/bin/nova-control-center
podman build --pull=never --file Containerfile.update-repair \
    --build-arg "BASE_IMAGE=$parent" --tag localhost/nova:0.3.2-preview .
podman image inspect localhost/nova:0.3.2-preview > artifacts/runtime-0.3.2-preview-inspect.json
