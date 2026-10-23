#!/usr/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ $EUID == 0 ]] || { echo 'Run in the dedicated Fedora builder as root.' >&2; exit 1; }
version=0.3.1-preview
parent=localhost/nova:0.3.0-preview
expected_parent=0a8328c8bb80002b5771716e625250603e4ef352cf8b6b081175e58a63ebe649
actual_parent=$(podman image inspect --format '{{.Id}}' "$parent")
[[ "${actual_parent#sha256:}" == "$expected_parent" ]] \
    || { echo 'The original, verified NOVA 0.3 runtime is required; refusing another base.' >&2; exit 2; }
mkdir -p build artifacts
python3 tests/store_launcher_test.py
podman build --pull=never --file Containerfile.store-update \
    --build-arg "BASE_IMAGE=$parent" --build-arg "NOVA_VERSION=$version" \
    --tag "localhost/nova:$version" .
podman image inspect "localhost/nova:$version" >"artifacts/runtime-${version}-inspect.json"
jq -n --arg version "$version" --arg parent "$parent" --arg parentId "$expected_parent" \
    '{version:$version,parent:$parent,parentImageId:$parentId,maintenanceOnly:true,
      changes:["store launcher","official Flathub install references","OS version metadata"]}' \
    >"artifacts/build-${version}.json"
echo "Built localhost/nova:$version; publication and installed update validation are separate steps."
