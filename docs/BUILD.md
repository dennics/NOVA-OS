# Building the authentic source

## Native applications — independent of the ISO

Use Fedora 44 with Qt 6.6+ and KDE Frameworks 6. The development builder used
Qt 6.11.2. On a disposable development VM install:

```sh
sudo dnf install cmake ninja-build gcc-c++ qt6-qtbase-devel qt6-qtdeclarative-devel \
  qt6-qtsvg-devel kf6-kconfig-devel kf6-kirigami-devel kf6-kiconthemes-devel \
  extra-cmake-modules breeze-icon-theme
cmake -S . -B build/native -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
cmake --build build/native -j2
ctest --test-dir build/native --output-on-failure
```

For an isolated UI capture that does not change desktop preferences:

```sh
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software build/native/nova-control-center \
  --no-desktop-integration --config /tmp/nova-preview-config --page appearance \
  --width 1280 --height 720 --screenshot /tmp/nova-appearance.png
```

`bash scripts/check-ui.sh` produces real Qt application captures. It does not
validate system services or installation. `NOVA_BUILD_DESKTOP=OFF` allows building
the metrics parser/test independently of Qt/KDE.

## Historical image pipeline — required inputs are not all public

Use a dedicated Fedora 44 VM (4 CPUs, 8 GiB RAM planned, 100 GB development disk
plus sufficient free storage for intermediates). The bootstrap configures Podman
storage and requires a VM; do not run it on a general-purpose host.

```sh
sudo bash scripts/bootstrap-builder.sh
sudo bash scripts/build.sh iso
```

Other stages: `runtime` and `live`. The runtime and Live images are separate;
Image Builder's `bootc-generic-iso` embeds the runtime for offline deployment.
`scripts/osbuild` validates/transforms the tools pipeline and applies SELinux
labels before compression. The manifest and package list go into `artifacts/`.

The pipeline above is retained from the original project. It requires:

| Input | Identity/location | Availability |
| --- | --- | --- |
| Fedora Kinoite 44 base | Digest in `sources.lock.json` | Upstream registry; availability must be checked by builder |
| Image Builder | Digest in the same lock | Upstream registry; requires network/cached input |
| NOVA 0.1 runtime/Live bootstrap | Exact local image IDs in that lock | Only in the original builder; not published with this tree |
| Opera GX RPM | `vendor/opera-gx-stable_137.0.6036.65_amd64.rpm` | Excluded proprietary input; version/hash in `docs/DEPENDENCIES.md` |
| Opera EULA HTML | `vendor/opera-eula-computers.html` | Separately acquire from the official EULA page; not fabricated |
| Fedora RPM dependencies | Live repositories/caches used by configuration scripts | Not snapshot-pinned; versions recorded after build |

**A clean checkout does not reproduce the historical ISO.** Copying an unrelated
image under a bootstrap tag is refused by ID validation and is not a solution.
Do not create dummy vendor files to pass COPY/checksum checks.

For authorized local development, retrieve exact Opera inputs with the additive
`scripts/fetch-dependency.py` helper only after reviewing its EULA. Dependency
retrieval does not grant ISO redistribution permission. No proprietary payload
is fetched by cloning the repository or by the source audit.

The clean-host follow-up is to build directly from the pinned Fedora base with
all NOVA configuration stages, rather than unpublished bootstrap images, then
validate the result. `scripts/build.sh` already falls back to the Fedora base
when bootstrap fields are absent, but that path has **not** been qualified for
this snapshot. Do not remove pins and claim that the historical image was reproduced.
RPM repository snapshots and all inputs/tool versions are also needed for a
bit-reproducible image. The current process records provenance, not identical bytes.

The known installer failures remain even if image construction succeeds.
Follow `VM.md`, `INSTALLER-ISSUES.md` and `ACCEPTANCE.md` before any binary release.

## Windows Media Creation Tool

Source is in `tools/nova-media-creator/`. The original build requires Windows,
.NET Framework 4.8, the pinned Fedora Media Writer 5.3.2 portable ZIP and the exact
historical ISO. The latter pins are intentionally preserved for provenance and
must be updated in both `App.cs` and `build.ps1` only after a fixed ISO passes
acceptance. Do not compile/distribute a new recommended kit around the defective ISO.
No physical USB is touched by source preparation/auditing.

## Original local QEMU helper

`tools/host.py` derives the workspace two directories above the project. It expects
`work/tools/qemu`, `work/downloads` and `work/vm`, with local UEFI files, a Fedora
Cloud base and an independently generated builder SSH key. A plain repository
clone does not contain those prerequisites. It binds control ports to localhost.
Use a normal Fedora development VM directly unless that workspace is deliberately
provisioned. Do not commit its seed files, private key or VM disks.
