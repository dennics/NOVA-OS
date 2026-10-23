#!/usr/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ $EUID == 0 ]] || { echo 'Run inside the dedicated Fedora builder as root.' >&2; exit 1; }
version=${NOVA_VERSION:-0.3.0-preview}
[[ "$version" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] || exit 1
artifact_version=${version%.0-preview}
[[ $artifact_version != "$version" ]] || artifact_version=${version%-preview}
iso_name="NOVA-OS-${artifact_version}-Preview-x86_64"
runtime="localhost/nova:${version}"
live="localhost/nova-live:${version}"
builder=$(jq -r '.builder.ref + "@" + .builder.digest' sources.lock.json)
podman image exists "$runtime"
podman image exists "$live"
podman image exists "$builder" || podman pull "$builder"
tools_ref=localhost/nova-iso-tools:0.1
podman build --pull=never --security-opt label=disable -f Containerfile.build-tools \
    --build-arg "IMAGE_BUILDER_IMAGE=$builder" -t "$tools_ref" .
# containers-storage sources use the configuration image ID, not .Digest.
tools_id=$(podman image inspect --format '{{.Id}}' "$tools_ref")
tools_id="sha256:${tools_id#sha256:}"
[[ "$tools_id" =~ ^sha256:[0-9a-f]{64}$ ]] || { echo 'Invalid tools image ID' >&2; exit 1; }
chmod 0755 scripts/osbuild
mkdir -p artifacts
podman image inspect "$tools_ref" >artifacts/build-tools-inspect.json
podman run --rm --network none --entrypoint rpm "$tools_ref" -qa \
    --qf '%{NAME} %{EPOCHNUM}:%{VERSION}-%{RELEASE}.%{ARCH}\n' \
    | sort >artifacts/build-tools-packages.txt
install -d -m 0755 /var/cache/nova-osbuild
iso_output=$(mktemp -d "$PWD/artifacts/image-builder.XXXXXXXX")
podman run --pull=never --rm --privileged \
    --env PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    --env "NOVA_OSBUILD_TOOLS_REF=$tools_ref" --env "NOVA_OSBUILD_TOOLS_ID=$tools_id" \
    --env "NOVA_OSBUILD_LIVE_REF=$live" \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    -v /etc/containers/storage.conf:/etc/containers/storage.conf:ro \
    -v /var/cache/nova-osbuild:/store:Z \
    -v "$PWD/scripts/osbuild:/usr/local/bin/osbuild:ro,Z" \
    -v "$iso_output:/output:Z" "$builder" build --output-dir /output --cache /store --progress verbose \
    --output-name "$iso_name" \
    --bootc-ref "$live" --bootc-build-ref "$tools_ref" --bootc-installer-payload-ref "$runtime" \
    --bootc-default-fs ext4 --with-manifest --with-sbom bootc-generic-iso
mapfile -t isos < <(find "$iso_output" -type f -name '*.iso')
[[ ${#isos[@]} == 1 ]] || { echo 'Image Builder must produce exactly one ISO.' >&2; exit 1; }
[[ ! -e artifacts/"$iso_name.iso" ]] || { echo 'ISO already exists; preserve it before rebuilding.' >&2; exit 1; }
mv "${isos[0]}" "artifacts/$iso_name.iso"
cp "$iso_output/nova-live.osbuild-manifest.json" artifacts/nova-live.osbuild-manifest.json
(cd artifacts && sha256sum "$iso_name.iso" >"$iso_name.iso.sha256")
case "$iso_output" in
    "$PWD"/artifacts/image-builder.*) rm -rf -- "$iso_output" ;;
    *) echo "Refusing to remove unexpected Image Builder path: $iso_output" >&2; exit 1 ;;
esac
