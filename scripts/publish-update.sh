#!/usr/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

version=${NOVA_VERSION:-0.2.1-preview}
[[ "$version" == 0.2.1-preview ]] || { echo 'Only the reviewed 0.2.1 Preview tag is allowed.' >&2; exit 2; }
local_image="localhost/nova:${version}"
remote_image="ghcr.io/dennics/nova-os:${version}"
podman image exists "$local_image" || { echo "Build $local_image first." >&2; exit 3; }

echo "Publishing $remote_image. Authenticate to ghcr.io with an account allowed to publish this package."
podman tag "$local_image" "$remote_image"
podman push "$remote_image"
skopeo inspect "docker://${remote_image}" >/dev/null
echo "Published and registry-inspected: $remote_image"
