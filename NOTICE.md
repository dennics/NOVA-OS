# Source and third-party notices

Original NOVA code, documentation and graphics are licensed under MIT.
The 0.3 orbit-frame vectors and synthesized sound cues are original NOVA work;
their generators are included. No third-party audio recordings are bundled.
See [licensing review](docs/LICENSING.md) and the root `LICENSE`.

This source tree does not vendor Fedora/Linux, Qt, KDE, Anaconda, bootc, Wine,
GameMode, Ark, unar, 7zip, QEMU, proprietary GPU drivers or Opera GX. Dependencies
retain upstream licenses, package notices and source obligations. A NOVA code
license does not cover the full multi-license operating-system image.

The files under `system/usr/share/nova/store/` are upstream Flathub install
references, including its public repository signing key, downloaded from
`https://dl.flathub.org/repo/appstream/com.valvesoftware.Steam.flatpakref` and
`https://dl.flathub.org/repo/appstream/com.opera.opera-gx.flatpakref` on 2026-10-23.
They contain repository metadata, not application binaries or a license grant
for the applications. Installation remains subject to their own terms.

The RAR5 fixture retains its upstream CC0-1.0 dedication. Origin and checksums
are in `tests/fixtures/rar/README.md`; the license is `LICENSES/CC0-1.0.txt`.

The Windows utility invokes the unchanged Fedora Media Writer 5.3.2 helper as
a separate process. The generated portable package and Qt libraries are excluded
from Git. Exact upstream source: https://github.com/FedoraQt/MediaWriter/tree/5.3.2 .
Fedora records LGPL-2.0-or-later AND GPL-2.0-or-later for Media Writer. The local
0.3 test kit includes Media Writer 5.3.2 sources and GPL/LGPL license texts.
Public binary distribution still needs its complete dependency/source and
notice obligations reviewed; source URLs alone are not universal compliance.

The Plymouth script adapts Fedora's installed spinner theme by Jakub Steiner
(jimmac), using the packaged two-step plugin and animation/keyboard/password
assets. Those assets are not copied into this source tree and retain their
package licenses in images. NOVA's SVG mark/wallpaper and Plasma configuration
are original; rights in third-party names and marks are not granted by NOVA.

The local preview used Opera GX 137.0.6036.65, SHA-256
`b911fb526d872e59ca8a3bf92e6e77fcf16a42a042b53f23f5abf97f74ebfd52`.
The RPM and EULA HTML are excluded; build references remain authentic. The EULA
allows limited application-repository redistribution under conditions; permission
for NOVA ISO packaging has not been established. Public images need separate
review: https://www.opera.com/legal/eula-computers .

The screenshots show NOVA's own application UI. Provenance and limits are
in `docs/screenshots/README.md`. No personal desktop captures, photographs, game
artwork or vendor-browser screenshots are included.
