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

## 0.2.1 Preview image pipeline

Use a dedicated Fedora 44 VM (4 CPUs, 8 GiB RAM planned, 100 GB development
disk plus sufficient free storage for intermediates). The bootstrap configures
Podman storage; do not run it on a general-purpose host.

```sh
sudo bash scripts/bootstrap-builder.sh
sudo bash scripts/build.sh runtime
```

The runtime and Live images are separate. The runtime OCI image was rebuilt
from the digest-pinned Fedora Kinoite 44 base in sources.lock.json; it no
longer depends on unpublished NOVA 0.1 bootstrap images or includes proprietary
Opera/Steam application binaries. The signed Flathub remote lets the user choose
those apps through Discover.

The build needs network access to fetch pinned OCI inputs and Fedora packages.
The base and Image Builder inputs are digest-pinned, but Fedora RPM repositories
are not snapshot-pinned, so byte-identical output is not promised. artifacts/
records image and package provenance. The 0.2.1 runtime build and native checks
have evidence in VALIDATION.md. The full iso build and offline installation
from the resulting ISO have not passed acceptance for this update; do not treat
successful runtime image construction as an installer test.
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
