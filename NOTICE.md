# Source and third-party notices

Original NOVA code, documentation and graphics are licensed under MIT.
See [licensing review](docs/LICENSING.md) and the root `LICENSE`.

This source tree does not vendor Fedora/Linux, Qt, KDE, Anaconda, bootc, Wine,
GameMode, Ark, unar, 7zip, QEMU, proprietary GPU drivers or Opera GX. Dependencies
retain upstream licenses, package notices and source obligations. A NOVA code
license does not cover the full multi-license operating-system image.

The RAR5 fixture retains its upstream CC0-1.0 dedication. Origin and checksums
are in `tests/fixtures/rar/README.md`; the license is `LICENSES/CC0-1.0.txt`.

The Windows utility invokes the unchanged Fedora Media Writer 5.3.2 helper as
a separate process. The generated portable package and Qt libraries are excluded
from Git. Exact upstream source: https://github.com/FedoraQt/MediaWriter/tree/5.3.2 .
Fedora records LGPL-2.0-or-later AND GPL-2.0-or-later for Media Writer. A future
binary kit needs corresponding-source availability, notices/license texts and
GPL/LGPL obligations reviewed; a source URL alone is not universal compliance.

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

The three screenshots show NOVA's own application UI. Provenance and limits are
in `docs/screenshots/README.md`. No personal desktop captures, photographs, game
artwork or vendor-browser screenshots are included.
