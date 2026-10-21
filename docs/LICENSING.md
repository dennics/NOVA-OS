# Licensing review

## Original-source license: MIT

The owner approved MIT licensing and source publication on 2026-10-22. MIT applies
to original NOVA C++, QML, C#, scripts, documentation and original graphics. The
adopted text is in root `LICENSE` and `LICENSES/MIT.txt`. Theme metadata is aligned
with that decision. Third-party material is governed by its own licenses.

MIT permits broad reuse with copyright/license preservation. It can be used for
original application code that uses appropriately licensed Qt/KDE libraries, but
it does not remove those libraries' LGPL/GPL requirements or authorize copying
proprietary programs. Qt documents its [licensing options](https://doc.qt.io/qt-6/licensing.html)
and [LGPL obligations](https://www.qt.io/development/open-source-lgpl-obligations).
An OS image is an aggregation of separately licensed components, not one MIT work.

This decision does not relicense dependencies, grant rights in third-party marks,
or authorize proprietary binary redistribution. It is not a dual-license grant.

## Component review

`evidence/component-licenses.json` contains 21 actual package/version/license
records read offline from the original local runtime, Live and ISO-tool images.
It preserves the full RPM expressions, including mixed licenses rather than
reducing Qt/KDE or the kernel to one shorthand. It is a selected inventory,
not a transitive SBOM or a legal-compliance certificate.

| Component | Source-tree treatment | Obligations / unresolved questions |
| --- | --- | --- |
| Original NOVA code/assets | Included from original workspace | MIT, owner-approved on 2026-10-22 |
| Qt 6 and KDE Frameworks/Plasma | Dependency references only; no vendored library code/binaries | Module/package-specific LGPL/GPL licenses and third-party notices; retain replaceability/source rights in future binaries |
| Fedora/Linux packages | Build/runtime dependencies only | Mixed package licenses, including GPL/LGPL/permissive and firmware terms; generate exact package/SBOM notices for each image |
| bootc | Original integration wrapper only; upstream binary not vendored | Upstream project and dependency licenses retained; consult the pinned source/Cargo metadata for any binary distribution |
| Anaconda | NOVA configuration only | Upstream Anaconda licensing remains; no upstream code is relicensed by NOVA |
| Podman, skopeo, osbuild/Image Builder, QEMU | Tool references only | Review pinned upstream/package notices for any redistribution; source-only references do not distribute those tools |
| Wine, GameMode, Ark, unar, 7zip | Runtime integration only | Per-package source/license obligations remain; no WinRAR or Windows drivers are included |
| RAR test data | Two existing tiny files retained | Upstream CC0-1.0 dedication, provenance/checksums and full text retained |
| Fedora Media Writer 5.3.2 | Provenance JSON and NOVA invocation code only | Fedora lists LGPL-2.0-or-later AND GPL-2.0-or-later; binary kit needs corresponding-source/notices review |
| Opera GX | Build references retained, RPM/EULA HTML excluded | Proprietary; limited EULA permission is not an established grant for NOVA ISO bundling |
| NVIDIA proprietary software | Not present | No redistribution or driver-support claim |
| Plymouth theme | NOVA configuration script only | Packaged upstream spinner assets/licenses must remain in generated images |
| Screenshots | Three reviewed NOVA application captures | Original UI, MIT; no personal desktop or third-party artwork included |

The [Opera EULA](https://www.opera.com/legal/eula-computers), section 2, permits
limited distribution through desktop open-source distribution application
repositories, subject to conditions. It requires unchanged software, no charge to
end users and the EULA. This source preparation does **not** interpret that as
permission for a bundled ISO or kit. The existing runtime script also removes
Opera's queued repository-setup task; the effect on the EULA's unchanged-software
condition needs review before binary publication. Consider explicit permission or
a user-initiated post-install download. No proprietary file is added to Git.

Media Writer references:
[upstream 5.3.2 source](https://github.com/FedoraQt/MediaWriter/tree/5.3.2),
[Fedora package licensing](https://packages.fedoraproject.org/pkgs/mediawriter/mediawriter/).
An upstream URL alone is not a blanket legal-compliance claim. Source publication
does not clear the historical EXE/ISO for public binary redistribution.

This is a scoped engineering inventory, not a complete legal review of all RPM
dependencies. No image is being released, and full package-level license/SBOM
review remains a binary-release gate.
