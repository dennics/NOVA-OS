#!/usr/bin/bash
set -euo pipefail
trap 'status=$?; printf "NOVA runtime configuration failed near line %s (exit %s)\\n" "$LINENO" "$status" >&2; exit "$status"' ERR
version=${1:?NOVA version required}
install -d /var/roothome
opera_launcher=/usr/share/nova/opera-gx.desktop
install -d /usr/share/nova
install -m 0644 /usr/share/applications/opera-gx.desktop "$opera_launcher"
flathub_repo=/usr/share/flatpak/remotes.d/flathub.flatpakrepo
flathub_sha256=3371dd250e61d9e1633630073fefda153cd4426f72f4afa0c3373ae2e8fea03a
printf '%s  %s\n' "$flathub_sha256" "$flathub_repo" | sha256sum --check --status
grep -Fxq 'Url=https://dl.flathub.org/repo/' "$flathub_repo"
grep -q '^GPGKey=.' "$flathub_repo"
missing=()
for package in firewalld qemu-guest-agent glibc-langpack-ro kf6-kirigami kf6-kiconthemes wine ark unar 7zip pciutils gamemode steam-devices tuned-ppd; do
    rpm -q --quiet "$package" || missing+=("$package")
done
if ((${#missing[@]})); then
    dnf -y --setopt=install_weak_deps=False --setopt=keepcache=True install "${missing[@]}"
fi
# Remove the upstream RPM-repository setup that may be inherited from NOVA 0.1.
if command -v atq >/dev/null && command -v at >/dev/null; then
    while read -r job _; do
        if [[ -n "$job" ]] && at -c "$job" 2>/dev/null | grep -Fq '/usr/lib64/opera-gx-stable/setup_repo.sh'; then
            atrm "$job"
        fi
    done < <(atq)
fi
if rpm -q --quiet opera-gx-stable; then
    dnf -y --setopt=clean_requirements_on_remove=False remove opera-gx-stable
fi
systemctl disable atd.service 2>/dev/null || true
rm -f /etc/yum.repos.d/opera*.repo
install -m 0644 "$opera_launcher" /usr/share/applications/opera-gx.desktop
test -x /usr/bin/wine
test -x /usr/bin/unar
# Every default panel launcher must resolve to an installed application.
for desktop in org.novaos.ControlCenter org.kde.dolphin opera-gx com.valvesoftware.Steam org.kde.ark org.kde.discover nova-wine; do
    test -f "/usr/share/applications/$desktop.desktop"
done
sed -i -e 's/^NAME=.*/NAME="NOVA OS"/' \
    -e 's/^PRETTY_NAME=.*/PRETTY_NAME="NOVA OS 0.2 Preview"/' /usr/lib/os-release
install -d /usr/share/nova /usr/lib/nova
printf '{"name":"NOVA OS","version":"%s","updateChannel":null,"preview":true}\n' "$version" >/usr/lib/nova/release.json
printf 'NOVA OS release 44 (0.2 Preview)\n' >/etc/system-release
kwriteconfig6 --file /etc/xdg/kdeglobals --group KDE --key LookAndFeelPackage org.novaos.desktop
kwriteconfig6 --file /etc/xdg/kdeglobals --group General --key ColorScheme NovaDark
kwriteconfig6 --file /etc/xdg/kdeglobals --group Icons --key Theme breeze-dark
install -d /usr/share/wallpapers/NovaDark/contents/images
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software nova-control-center \
    --render-wallpaper /usr/share/wallpapers/NovaDark/contents/images/3840x2160.png
# Supported Plasma Login Manager distribution defaults, also configurable by users.
if test -f /usr/lib/plasmalogin/defaults.conf; then
    kwriteconfig6 --file /usr/lib/plasmalogin/defaults.conf --group Greeter --key WallpaperPluginId org.kde.image
    for key in Image PreviewImage; do
        kwriteconfig6 --file /usr/lib/plasmalogin/defaults.conf \
            --group Greeter --group Wallpaper --group org.kde.image --group General --key "$key" \
            file:///usr/share/wallpapers/NovaDark/contents/images/3840x2160.png
    done
fi
systemctl enable firewalld.service
systemctl enable nova-flathub-setup.service
# Anaconda creates the local account; NOVA owns the first-login welcome.
# KDE's documented completion flag prevents its separate setup autologin.
install -m 0644 /dev/null /etc/plasma-setup-done
# The separate KDE welcome daemon otherwise opens a second first-run window.
# Seed its documented version state; the app remains available for manual use.
if rpm -q --quiet plasma-welcome; then
    welcome_version=$(rpm -q --qf '%{VERSION}' plasma-welcome)
    kwriteconfig6 --file /etc/xdg/plasma-welcomerc --group General --key LastSeenVersion "$welcome_version"
    kwriteconfig6 --file /etc/xdg/plasma-welcomerc --group General --key ShowUpdatePage false
fi
test -f /etc/selinux/config
sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
# Preview images have no public update source. Local update/rollback tests use bootc explicitly.
for unit in bootc-fetch-apply-updates.timer rpm-ostreed-automatic.timer; do
    systemctl disable "$unit" 2>/dev/null || true
done
/usr/libexec/nova-image/configure-plymouth.sh
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software nova-control-center --version
# These paths contain only package-manager build state, not user data.
rm -rf /run/dnf /var/lib/dnf/repos
rm -f /var/log/dnf5.log /var/cache/ldconfig/aux-cache

