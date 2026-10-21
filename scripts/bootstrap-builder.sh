#!/usr/bin/bash
set -euo pipefail
[[ $EUID == 0 ]] || { echo 'Use sudo inside the dedicated builder VM.' >&2; exit 1; }
source /etc/os-release
[[ $ID == fedora && $VERSION_ID == 44 ]] || { echo 'Fedora 44 builder required.' >&2; exit 1; }
dnf -y install podman skopeo jq git python3 tar gzip policycoreutils
dnf -y --setopt=install_weak_deps=False install cmake ninja-build gcc-c++ \
    qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtsvg-devel \
    kf6-kconfig-devel kf6-kirigami-devel kf6-kiconthemes-devel \
    extra-cmake-modules breeze-icon-theme
bash "$(dirname "$0")/configure-builder-storage.sh"
podman version
skopeo --version
getenforce
df -h / /var/tmp

