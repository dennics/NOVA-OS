#!/usr/bin/bash
set -euo pipefail

source_theme=/usr/share/plymouth/themes/spinner
nova_theme=/usr/share/plymouth/themes/nova
mark=/usr/share/icons/hicolor/scalable/apps/nova-control-center.svg
for package in plymouth-theme-spinner plymouth-plugin-two-step ImageMagick dracut ostree; do
    rpm -q --quiet "$package"
done
test -f "$source_theme/spinner.plymouth"
test -f "$mark"
command -v magick >/dev/null
command -v plymouth-set-default-theme >/dev/null
command -v lsinitrd >/dev/null

# Derive from the installed Fedora spinner theme, retaining the native two-step
# plugin and every password, keyboard, fallback, update and progress asset.
install -d -m 0755 "$nova_theme"
cp -a "$source_theme/." "$nova_theme/"
mv "$nova_theme/spinner.plymouth" "$nova_theme/nova.plymouth"
# The packaged watermark can link to Fedora's shared logo. Remove only this
# copied directory entry before rendering the original NOVA vector mark.
rm -f "$nova_theme/watermark.png"
magick -background none "$mark" -resize 96x96 "PNG32:$nova_theme/watermark.png"

python3 - <<'PY'
from pathlib import Path
import configparser
import struct

theme_dir = Path('/usr/share/plymouth/themes/nova')
png = (theme_dir / 'watermark.png').read_bytes()
assert png[:8] == b'\x89PNG\r\n\x1a\n' and png[12:16] == b'IHDR'
width, height, depth, color_type = struct.unpack('>IIBB', png[16:26])
assert (width, height, depth, color_type) == (96, 96, 8, 6), 'Expected 96px RGBA PNG'

path = theme_dir / 'nova.plymouth'
before = configparser.ConfigParser(interpolation=None)
before.optionxform = str
before.read(path)
assert before['Plymouth Theme']['ModuleName'] == 'two-step'
assert Path(before['two-step']['ImageDir']) == Path('/usr/share/plymouth/themes/spinner')
for mode in ('boot-up', 'shutdown', 'reboot'):
    assert before.getboolean(mode, 'UseEndAnimation') is False

replacements = {
    ('Plymouth Theme', 'Name'): 'NOVA',
    ('Plymouth Theme', 'Description'): 'NOVA colors and mark with the distribution spinner',
    ('two-step', 'ImageDir'): str(theme_dir),
    ('two-step', 'BackgroundStartColor'): '0x0b0d14',
    ('two-step', 'BackgroundEndColor'): '0x0b0d14',
    ('two-step', 'ProgressBarForegroundColor'): '0x57c7ff',
}
for key in before['Plymouth Theme']:
    if key.startswith('Name['):
        replacements['Plymouth Theme', key] = 'NOVA'

# Preserve all other keys, comments and translated status messages verbatim.
pending = dict(replacements)
group = None
lines = []
for line in path.read_text().splitlines():
    if line.startswith('[') and line.endswith(']'):
        group = line[1:-1]
    elif '=' in line and not line.lstrip().startswith(('#', ';')):
        key = line.split('=', 1)[0].strip()
        pair = group, key
        if pair in replacements:
            line = key + '=' + replacements[pair]
            pending.pop(pair)
    lines.append(line)
assert not pending, f'Unexpected distribution theme schema: {pending}'
path.write_text('\n'.join(lines) + '\n')

after = configparser.ConfigParser(interpolation=None)
after.optionxform = str
after.read(path)
for section in before.sections():
    for key, value in before.items(section):
        assert after[section][key] == replacements.get((section, key), value), (section, key)
assert after.sections() == before.sections()
print('NOVA Plymouth: 96px RGBA mark, unchanged native dialogs and progress settings')
PY

# Select without the helper's separate host-oriented initramfs command.
plymouth-set-default-theme nova
test "$(plymouth-set-default-theme)" = nova

# The runtime initramfs must contain the branding too. Keep the non-host-only
# distribution configuration and explicitly retain bootc/OSTree and LUKS support.
# The Live stage regenerates its own image later with its existing Live modules.
kernel=$(find /usr/lib/modules -mindepth 2 -maxdepth 2 -name vmlinuz -printf '%h\n' | sort -V | tail -n 1)
[[ -n "$kernel" ]] || { echo 'No kernel found for NOVA Plymouth' >&2; exit 1; }
kernel=${kernel##*/}
initramfs="/usr/lib/modules/$kernel/initramfs.img"
DRACUT_NO_XATTR=1 dracut --force --zstd --no-hostonly --stdlog 4 \
    --add 'ostree plymouth crypt systemd-cryptsetup' "$initramfs" "$kernel"

members=$(mktemp /tmp/nova-initramfs-members.XXXXXX)
modules=$(mktemp /tmp/nova-initramfs-modules.XXXXXX)
trap 'rm -f "$members" "$modules"' EXIT
lsinitrd "$initramfs" > "$members"
lsinitrd -m "$initramfs" > "$modules"
for module in ostree plymouth crypt systemd-cryptsetup; do
    grep -Fxq "$module" "$modules"
done
for file in nova.plymouth watermark.png entry.png keyboard.png lock.png; do
    grep -Eq "usr/share/plymouth/themes/nova/${file//./\\.}$" "$members"
done
grep -Eq 'usr/(lib64|lib)/plymouth/two-step\.so$' "$members"
grep -Eq 'usr/lib/ostree/ostree-prepare-root$' "$members"
grep -Eq 'usr/lib/systemd/systemd-cryptsetup( -> ../../bin/systemd-cryptsetup)?$' "$members"
grep -Eq 'usr/bin/systemd-cryptsetup$' "$members"
echo 'NOVA runtime initramfs includes its theme, native plugin, OSTree and LUKS modules'
