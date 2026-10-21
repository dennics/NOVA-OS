# NOVA OS — Your PC. Your Power.

NOVA OS is an experimental desktop operating system based on Fedora Kinoite 44,
KDE Plasma 6 and bootc images. It combines a cosmic desktop theme with a native
C++ / Qt 6 / QML / Kirigami Control Center. No online NOVA account is required.

**0.2 Preview has known installation failures. It is a development snapshot,
not a stable release or a recommended installation on a personal computer.**
Read the [installer issues](docs/INSTALLER-ISSUES.md) before image experiments.
No fix or successful end-to-end 0.2 installation is claimed here. This source
commit distributes no ISO, VM image or executable.

These are the [original NOVA sources](docs/SOURCE-PROVENANCE.md), including the
defective installer wrapper. Original NOVA code, documentation and graphics are
available under the MIT license. Third-party components retain their own terms;
see [LICENSE](LICENSE), [NOTICE.md](NOTICE.md) and [licensing review](docs/LICENSING.md).

## What exists in 0.2

| Component | Implemented behavior | Preview limits |
| --- | --- | --- |
| Control Center | Native UI, system information, CPU/RAM sampling, KConfig preferences, first-login welcome, Romanian/English UI | Desktop/hardware behavior needs testing beyond unit tests |
| NOVA Dark | Plasma look-and-feel, colors, bottom panel, original SVG wallpaper/mark and motion preferences | Plasma provides desktop infrastructure; GPU effects vary |
| Smart Compatibility | Local PE inspection, architecture checks, limited native-app hints, explicit Wine launch, shared/per-app prefixes, Dolphin integration | Hints use untrusted metadata; Wine is not a sandbox and execution is not guaranteed |
| Update Center | bootc status and fixed helper operations through polkit | No public NOVA registry; placeholder sources disable online actions; full 0.2 update/rollback is unvalidated |
| Performance Profiles | Eco/Balanced/Gaming request power-saver/balanced/performance over D-Bus | Requires service/hardware support; GameMode is used by explicitly launched games; no FPS claims |
| Driver Center | PCI GPU/vendor and active Linux driver detection with guidance | No proprietary NVIDIA driver installer |
| Installer | Anaconda Live/WebUI configuration, offline payload integration, explicit disk selection | Known staging defects prevent reliable installation |
| Browser/archives | Local preview configured Opera GX; Wine, Ark, unar and 7zip integration | Opera binaries are proprietary and excluded; ZIP/RAR/7z extraction needs no WinRAR; RAR creation is absent |
| Windows USB tool | Original C# frontend and build script | Pins the historical defective ISO; binaries and Fedora writer payload excluded; not a recommended kit |

## Real application screenshots

These captures show the running NOVA application in development environments,
not design mockups. Unavailable services are visible. Momentary CPU/RAM values
are not benchmarks. The UI shown is Romanian.

![NOVA performance page showing an unavailable power-profile service](docs/screenshots/performance-0.2.png)

![NOVA Update Center with no configured update source](docs/screenshots/updates-0.2.png)

![NOVA Driver Center detecting a virtual GPU](docs/screenshots/drivers-0.2.png)

These images do not demonstrate successful installation.
[Screenshot provenance](docs/screenshots/README.md) records their origin/hashes.

## Architecture and layout

The runtime OCI image contains Plasma and NOVA applications. A separate Live
image adds Anaconda and a temporary Live account. Image Builder embeds the runtime
payload in `bootc-generic-iso` for offline installation. bootc manages system
deployments; user state is separate. Normal NOVA applications are unprivileged;
system services and polkit authorize administrative actions. Configuration keeps
SELinux enforcing and enables the firewall; every delivered image must verify both.

| Path | Purpose |
| --- | --- |
| `src/`, `ui/`, `assets/` | Native applications, compatibility inspector and original graphics |
| `system/` | Installed-system configuration, Plasma, MIME and polkit integration |
| `installer/` | Live-only Anaconda settings, defaults and bootc wrapper |
| `Containerfile`, `Containerfile.build-tools` | Runtime, Live and ISO build-tool stages |
| `sources.lock.json`, `scripts/` | Image pins, build pipeline and osbuild integration |
| `tests/` | Existing C++ tests, read-only guest probe and RAR fixture |
| `tools/nova-media-creator/` | Windows utility source |
| `tools/host.py` | Original Windows/QEMU helper; requires its documented workspace layout |
| `docs/` | Architecture, building, validation and release preparation |

See [ARCHITECTURE.md](docs/ARCHITECTURE.md) for component boundaries and
[VALIDATION.md](docs/VALIDATION.md) for the actual evidence and gaps.

## Build and VM testing

Use a disposable Fedora 44 development VM. Install the dependencies in
[BUILD.md](docs/BUILD.md), then compile the native applications:

```sh
cmake -S . -B build/native -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
cmake --build build/native -j2
ctest --test-dir build/native --output-on-failure
```

The authentic image pipeline is `sudo bash scripts/build.sh iso`. It currently
requires exact local NOVA 0.1 bootstrap images from `sources.lock.json` and
separately acquired Opera inputs. Those inputs are not in GitHub. A contributor
can build the native applications, but **a clean checkout cannot yet reproduce
the historical ISO**. The build guide lists missing inputs and required follow-up;
it does not replace them with invented files or promise identical bytes.

Run publication checks with Python 3.10+ and Git:

```sh
python3 scripts/audit-publication.py
```

Full installation must use an unmodified rebuilt ISO with no virtual NIC and a
disposable target disk. [VM.md](docs/VM.md) and [ACCEPTANCE.md](docs/ACCEPTANCE.md)
define the acceptance gate. Current 0.2 failures leave that gate open.

## Hardware and development resources

No general hardware minimum or compatibility list has been established. The
development target is x86_64/UEFI. Previous VM work used 4 virtual CPUs, 6–8 GiB RAM
and a 48 GiB test disk; the builder uses a 100 GB disk. These are development
configurations, not supported minima. Plan 8 GiB guest RAM for new experiments
and sufficient host memory/storage for OCI layers and intermediates; run builder
and test guests one at a time on a constrained host.

An HP laptop with 8 GB RAM, integrated graphics and a 128 GB SATA SSD was reported
to fail during installation. That is a known failure, not hardware certification.
Secure Boot, dual boot, proprietary GPU drivers and physical gaming performance
remain unvalidated.

## Roadmap and contributions

The immediate priorities are safe installer staging, offline installation/first
boot, and removal of private-bootstrap build dependencies. Later work includes
physical hardware validation, Steam/Proton/GameMode integration, recovery/Defender
UI, and eventually NOVA AI/NOVA ID. These later services are planned, not shipped.
See [ROADMAP.md](docs/ROADMAP.md).

Use [GitHub Issues](https://github.com/dennics/NOVA-OS/issues) for non-sensitive
reproducible bugs. Follow [CONTRIBUTING.md](CONTRIBUTING.md) for changes and
[SECURITY.md](SECURITY.md) for sensitive reports. No stable support SLA is promised.
