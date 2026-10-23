#!/usr/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

version=${NOVA_VERSION:-0.3.0-preview}
[[ "$version" =~ ^0\.[0-9]+\.[0-9]+-preview$ ]] || { echo 'Expected a NOVA Preview version, such as 0.3.0-preview.' >&2; exit 2; }
local_image="localhost/nova:${version}"
remote_image="ghcr.io/dennics/nova-os:${version}"
channel_image=ghcr.io/dennics/nova-os:preview
podman image exists "$local_image" || { echo "Build $local_image first." >&2; exit 3; }
actual_version=$(podman image inspect --format '{{ index .Labels "org.opencontainers.image.version" }}' "$local_image")
[[ "$actual_version" == "$version" ]] || { echo 'Image version label does not match the release version.' >&2; exit 3; }
scratch=$(mktemp -d "${TMPDIR:-/var/tmp}/nova-publish.XXXXXX")
trap 'rm -rf "$scratch"' EXIT
if skopeo inspect "docker://${remote_image}" >/dev/null 2>"$scratch/preflight-error"; then
    echo 'This version tag already exists. Use a new version instead of overwriting a published version.' >&2
    exit 4
fi
grep -Eqi 'manifest unknown|name unknown' "$scratch/preflight-error" \
    || { echo 'Could not establish that the version tag is unused. Check registry access and connectivity; nothing was uploaded.' >&2; exit 4; }
podman push "$local_image" "docker://${remote_image}"
version_digest=$(skopeo inspect --format '{{.Digest}}' "docker://${remote_image}")
# A private package must never be advertised as a working OS update channel.
printf '{"auths":{}}\n' >"$scratch/auth.json"
skopeo inspect --authfile "$scratch/auth.json" "docker://${remote_image}" >"$scratch/inspect.json" \
    || { echo 'Version upload completed, but anonymous access failed. Make the GHCR package public before channel promotion.' >&2; exit 6; }
# Promote only after the uploaded version is anonymously readable.
skopeo copy --all --preserve-digests "docker://ghcr.io/dennics/nova-os@${version_digest}" "docker://${channel_image}"
channel_digest=$(skopeo inspect --format '{{.Digest}}' "docker://${channel_image}")
[[ "$channel_digest" == "$version_digest" ]] || { echo 'Channel/version digest mismatch.' >&2; exit 5; }
skopeo inspect --authfile "$scratch/auth.json" "docker://${channel_image}" >"$scratch/inspect.json" \
    || { echo 'Upload completed, but anonymous access failed. Make the GHCR package public before advertising this update.' >&2; exit 6; }
mkdir -p artifacts
jq -n --arg version "$version" --arg image "$remote_image" --arg channel "$channel_image" --arg digest "$version_digest" \
    '{version:$version,image:$image,channel:$channel,digest:$digest,anonymousPullVerified:true}' >"artifacts/update-${version}.json"
echo "Published $remote_image and promoted $channel_image at $version_digest; anonymous access verified."
