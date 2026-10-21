#!/usr/bin/bash
set -euo pipefail
version=${1:?NOVA version required}
install -d /var/roothome
opera_rpm=/tmp/nova-opera-gx.rpm
opera_sha256=b911fb526d872e59ca8a3bf92e6e77fcf16a42a042b53f23f5abf97f74ebfd52
printf '%s  %s\n' "$opera_sha256" "$opera_rpm" | sha256sum --check --status
test "$(rpm -qp --qf '%{NAME} %{VERSION} %{ARCH}' "$opera_rpm")" = 'opera-gx-stable 137.0.6036.65 x86_64'
missing=()
for package in firewalld qemu-guest-agent glibc-langpack-ro kf6-kirigami kf6-kiconthemes wine ark unar 7zip pciutils gamemode tuned-ppd; do
    rpm -q --quiet "$package" || missing+=("$package")
done
if ((${#missing[@]})); then
    dnf -y --setopt=install_weak_deps=False --setopt=keepcache=True install "${missing[@]}"
fi
if ! rpm -q --quiet opera-gx-stable; then
    dnf -y --disablerepo='*' install "$opera_rpm"
fi
# Opera schedules its own RPM repository setup through atd. NOVA image updates
# remain image-managed, so remove only that queued job and disable the timer.
while read -r job _; do
    if [[ -n "$job" ]] && at -c "$job" 2>/dev/null | grep -Fq '/usr/lib64/opera-gx-stable/setup_repo.sh'; then
        atrm "$job"
    fi
done < <(atq)
systemctl disable atd.service 2>/dev/null || true
rm -f /etc/yum.repos.d/opera*.repo
if rpm -q --quiet firefox; then dnf -y remove firefox; fi
rm -f "$opera_rpm"
test -x /usr/bin/opera-gx
test -x /usr/bin/wine
test -x /usr/bin/unar
# Every default panel launcher must resolve to an installed application.
for desktop in org.novaos.ControlCenter org.kde.dolphin opera-gx org.kde.ark org.kde.discover nova-wine; do
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

