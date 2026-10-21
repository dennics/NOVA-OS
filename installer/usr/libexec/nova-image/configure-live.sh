#!/usr/bin/bash
set -euo pipefail
version=${1:?NOVA version required}
test -x /usr/local/bin/bootc
test -x /usr/libexec/nova-bootc-real
[[ $(readlink -f /usr/sbin/bootc) == /usr/local/bin/bootc ]] || { echo 'Anaconda bootc wrapper is not first on its PATH.' >&2; exit 1; }
missing=()
for package in dracut-live livesys-scripts anaconda anaconda-live slitherer \
    grub2-efi-x64-cdboot xorriso isomd5sum squashfs-tools \
    libblockdev-lvm libblockdev-btrfs libblockdev-dm libblockdev-mpath; do
    rpm -q --quiet "$package" || missing+=("$package")
done
if ((${#missing[@]})); then
    dnf -y --setopt=install_weak_deps=False --setopt=keepcache=True install "${missing[@]}"
fi
# Fedora's KDE installer profile selects this WebUI browser, but anaconda-live
# does not require it. Keep it explicit while weak dependencies are disabled.
command -v slitherer >/dev/null
test -x /usr/libexec/anaconda/webui-desktop
sed -i 's/^livesys_session=.*/livesys_session=kde/' /etc/sysconfig/livesys
systemctl enable livesys.service livesys-late.service
kernel=$(find /usr/lib/modules -mindepth 2 -maxdepth 2 -name vmlinuz -printf '%h\n' | sort -V | tail -n 1)
[[ -n "$kernel" ]] || { echo 'No kernel found in runtime image' >&2; exit 1; }
kernel=${kernel##*/}
DRACUT_NO_XATTR=1 dracut --force --zstd --no-hostonly --stdlog 4 \
    --add 'dmsquash-live dmsquash-live-autooverlay' "/usr/lib/modules/$kernel/initramfs.img" "$kernel"
install -d /boot/efi /usr/lib/image-builder/bootc /usr/lib/bootc-image-builder
for efi_tree in /usr/lib/efi/*/*/EFI; do
    [[ -d "$efi_tree" ]] || continue
    cp -a "$efi_tree" /boot/efi/
done
sed -i "s/@VERSION@/$version/g" /usr/share/nova/installer.ks
install -m 0644 /usr/share/nova/installer.ks /usr/share/anaconda/interactive-defaults.ks
cp /usr/share/nova/iso.yaml /usr/lib/image-builder/bootc/iso.yaml
cp /usr/share/nova/iso.yaml /usr/lib/bootc-image-builder/iso.yaml

# Validate the effective distribution profile, including conf.d overrides,
# without probing or partitioning disks. This guards the bootc mount contract.
python3 - <<'PY'
from pyanaconda.core.configuration.anaconda import AnacondaConfiguration
from pykickstart.constants import AUTOPART_TYPE_PLAIN

config = AnacondaConfiguration.from_defaults()
config.set_from_detected_profile('fedora', 'kinoite')
config.set_from_files()
assert config.storage.default_scheme == AUTOPART_TYPE_PLAIN
assert config.storage.file_system_type == 'ext4'
requests = config.storage.default_partitioning
assert len(requests) == 1 and requests[0]['name'] == '/'
assert int(requests[0]['min']) >= 8 * 1024**3 and 'max' not in requests[0]
assert config.get_parser().get('User Interface', 'webui_web_engine') == 'slitherer'
print('NOVA installer profile validated: plain ext4 root, platform boot partitions, WebUI browser')
PY

