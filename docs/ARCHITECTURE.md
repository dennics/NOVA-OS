# Architecture

NOVA adds original applications/configuration to Fedora Kinoite 44, Plasma 6 and
KWin/Wayland. It does not implement a kernel or window manager.

| Boundary | Source | Responsibility |
| --- | --- | --- |
| User UI | `src/main.cpp`, `ui/Main.qml` | Control Center and welcome |
| Preferences/metrics | `Preferences`, `MetricsProvider`, `core/SystemMetrics` | KConfig; CPU deltas from `/proc/stat`, memory from `/proc/meminfo`; sampling follows visibility |
| Compatibility | `src/compat/`, `ui/Compatibility.qml`, `system/usr/bin/nova-run-exe` | Local PE parsing/hints and explicit Wine execution |
| Desktop | `system/usr/share/plasma/`, `system/etc/xdg/` | Look-and-feel, colors, bottom panel and MIME defaults |
| Profiles | `ProfileManager` | Requests `net.hadess.PowerProfiles`; system service/hardware decides availability |
| Drivers | `DriverCenter` | Reads PCI sysfs class/vendor/active driver; no proprietary installer |
| Updates | `UpdateManager`, `nova-update-helper`, polkit policy | Status and fixed bootc verbs; UI cannot supply arbitrary commands |
| Runtime image | Containerfile runtime, `system/` | Installed system without Live account |
| Live image | Containerfile live, `installer/` | Anaconda, Live session, initramfs and wrapper around preserved real bootc |
| ISO tooling | `scripts/build-iso.sh`, `scripts/osbuild` | Image Builder/tools image integration and SELinux labeling before squashfs |

Anaconda selects/formats disks, prepares mounts and creates accounts. It calls
bootc with the local embedded image and prepared destination. The current wrapper
allocates scratch inside that destination and violates the empty-root contract;
see `INSTALLER-ISSUES.md`. bootc's safety check is intentional and must remain.

Normal apps are unprivileged. Services/polkit authorize administration. The
dedicated builder uses privileged containers and `--security-opt label=disable`
to assemble/relabel images; this is not runtime SELinux configuration. The runtime
requests enforcing mode and needs separate Live/installed verification.

No NOVA cloud API, AI executor, identity service, public update registry, universal
driver installer or anti-cheat compatibility service exists in 0.2. Source paths
are preserved because CMake resources and image COPY operations depend on them.
