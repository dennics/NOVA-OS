#!/usr/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ $EUID == 0 ]] || { echo 'Run in the dedicated Fedora builder as root.' >&2; exit 1; }
stage=${1:-iso}
version=${NOVA_VERSION:-0.2.0-preview}
[[ "$version" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] || { echo 'Invalid NOVA_VERSION' >&2; exit 1; }
case "$stage" in runtime|live|iso) ;; *) echo 'Usage: scripts/build.sh [runtime|live|iso]' >&2; exit 1;; esac
for tool in podman skopeo jq cmake ninja ctest; do command -v "$tool" >/dev/null; done
mkdir -p build artifacts
exec > >(tee "build/build-${version}.log") 2>&1
cmake -S . -B build/native -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
cmake --build build/native -j2
ctest --test-dir build/native --output-on-failure
DESTDIR="$PWD/build/install" cmake --install build/native --strip
bash scripts/lock.sh
base=$(jq -r '.base.ref + "@" + .base.digest' build/sources.lock.json)
builder=$(jq -r '.builder.ref + "@" + .builder.digest' build/sources.lock.json)
bootstrap=$(jq -r '.runtimeBootstrap.ref // empty' build/sources.lock.json)
if [[ -n "$bootstrap" ]]; then
    expected=$(jq -r '.runtimeBootstrap.imageId' build/sources.lock.json)
    actual=$(podman image inspect --format '{{.Id}}' "$bootstrap")
    [[ "${actual#sha256:}" == "$expected" ]] || { echo 'Runtime bootstrap image ID mismatch.' >&2; exit 1; }
    base=$bootstrap
    echo "Using verified local runtime bootstrap: $bootstrap ($expected)"
fi
runtime="localhost/nova:${version}"
live="localhost/nova-live:${version}"
live_bootstrap=$(jq -r '.liveBootstrap.ref // "runtime"' build/sources.lock.json)
if [[ "$live_bootstrap" != runtime ]]; then
    expected_live=$(jq -r '.liveBootstrap.imageId' build/sources.lock.json)
    actual_live=$(podman image inspect --format '{{.Id}}' "$live_bootstrap")
    [[ "${actual_live#sha256:}" == "$expected_live" ]] || { echo 'Live bootstrap image ID mismatch.' >&2; exit 1; }
    echo "Using verified local Live bootstrap: $live_bootstrap ($expected_live)"
fi
podman image exists "$base" || podman pull "$base"
podman build --pull=never --cap-add SYS_ADMIN --security-opt label=disable --target runtime \
    --build-arg "BASE_IMAGE=$base" --build-arg "NOVA_VERSION=$version" -t "$runtime" .
podman run --rm --entrypoint rpm "$runtime" -qa --qf '%{NAME} %{EPOCHNUM}:%{VERSION}-%{RELEASE}.%{ARCH}\n' \
    | sort >build/packages.txt
podman image inspect "$runtime" >build/runtime-inspect.json
[[ $stage != runtime ]] || exit 0
podman build --pull=never --cap-add SYS_ADMIN --security-opt label=disable --target live \
    --build-arg "BASE_IMAGE=$base" --build-arg "LIVE_BOOTSTRAP_IMAGE=$live_bootstrap" \
    --build-arg "NOVA_VERSION=$version" -t "$live" .
[[ $stage != live ]] || exit 0
NOVA_VERSION="$version" bash scripts/build-iso.sh
cp build/sources.lock.json build/packages.txt build/runtime-inspect.json artifacts/
cp build/native/Testing/Temporary/LastTest.log artifacts/native-tests.log
python3 scripts/write-manifest.py
echo 'ISO built. VM acceptance tests are still required before release.'

