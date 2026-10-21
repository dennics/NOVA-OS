#!/usr/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
lock=build/sources.lock.json
if [[ -f sources.lock.json ]]; then
    jq -e '.schema == 1 and .fedora == 44 and (.base.digest | test("^sha256:[a-f0-9]{64}$")) and (.builder.digest | test("^sha256:[a-f0-9]{64}$")) and (.runtimeBootstrap == null or ((.runtimeBootstrap.ref | type == "string") and (.runtimeBootstrap.imageId | test("^[a-f0-9]{64}$")))) and (.liveBootstrap == null or ((.liveBootstrap.ref | type == "string") and (.liveBootstrap.imageId | test("^[a-f0-9]{64}$"))))' sources.lock.json >/dev/null
    cp sources.lock.json "$lock"
    echo "Using pinned source manifest: sources.lock.json"
    exit 0
fi
if [[ -f "$lock" ]]; then
    jq -e '.schema == 1 and .fedora == 44 and (.base.digest | startswith("sha256:")) and (.builder.digest | startswith("sha256:"))' "$lock" >/dev/null
    echo "Using existing source lock: $lock"
    exit 0
fi
base=quay.io/fedora-ostree-desktops/kinoite:44
builder=ghcr.io/osbuild/image-builder-cli:latest
base_digest=$(skopeo inspect --format '{{.Digest}}' "docker://$base")
builder_digest=$(skopeo inspect --format '{{.Digest}}' "docker://$builder")
jq -n --arg base "$base" --arg bd "$base_digest" --arg builder "$builder" --arg id "$builder_digest" \
    '{schema:1,fedora:44,base:{ref:$base,digest:$bd},builder:{ref:$builder,digest:$id}}' >"$lock.tmp"
mv "$lock.tmp" "$lock"
cat "$lock"

