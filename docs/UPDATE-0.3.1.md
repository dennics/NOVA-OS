# NOVA OS 0.3.1 Preview — application store repair

Correction from final installed-user testing: the original Settings code invokes
`bootc status` without privilege, which fails on this installed bootc version.
Consequently the old GUI may leave update controls disabled despite the valid
public image channel. The root-run NOVA update helper successfully finds 0.3.1.
The 0.3.2 Settings repair is in preparation; affected installations need the
one-time `pkexec /usr/libexec/nova-update-helper install` bootstrap before the
fixed GUI can be used. Earlier GUI-update instructions below depend on that fix.

Historical publication: 0.3.1 was published on 2026-10-23 and its numbered
reference remains readable. The moving Preview channel has subsequently been
promoted to [0.3.2](UPDATE-0.3.2.md), which also repairs the Settings blocker.

On an installed NOVA 0.3 system: NOVA Settings → Updates → Check for updates →
Download & install. Restart when ready, then open Steam and confirm its app
installation in Discover. A numbered legacy source can be connected using the
Settings page's Connect NOVA Preview action. No ISO replacement is required.

Published numbered reference: `ghcr.io/dennics/nova-os:0.3.1-preview`.
Published manifest digest:

```
sha256:cb9046a8af7263fd969d1de91b5c3e97c251a10d3efa71600864fde4c2a141fc
```

This maintenance image fixes first installation of Steam and Opera GX. The
launcher opens the exact upstream Flathub install reference in Discover instead
of an AppStream hostname that Qt converts to lowercase. Existing Flatpak
applications run directly in their user/system installation.

No Steam, Opera GX, games, third-party application runtimes or new kernel are
bundled by this maintenance layer. OS version metadata becomes `0.3.1-preview`;
the native Control Center binary remains the previously built 0.3.0 application.

## Exact local build

`scripts/build-store-update.sh` checks that the parent image is the original
verified local `localhost/nova:0.3.0-preview`:

```
0a8328c8bb80002b5771716e625250603e4ef352cf8b6b081175e58a63ebe649
```

It builds `Containerfile.store-update` without pulling another parent. The
resulting local image ID is:

```
0f8d4cdd2bcbcc441122c245e21454fb6cdd73af06c9e0b0b613fc580923a63a
```

The full source build also includes the repair through `COPY system/ /` in the
main Containerfile. The maintenance build requires the original local parent;
a fresh-host build uses the full pipeline with `NOVA_VERSION=0.3.1-preview` and
retains the reproducibility limits described in [BUILD.md](BUILD.md).

## Observed validation

- Six launcher/reference regression tests passed in Fedora.
- Bash syntax passed; both upstream install-reference SHA-256 values matched.
- bootc container lint: 14 checks passed, one skipped.
- The image reports `0.3.1-preview` and the `ghcr.io/dennics/nova-os:preview`
  update target. SELinux configuration remains enforcing; firewall and the
  metadata-check timer remain enabled.
- Original NOVA runtime Discover supports local install files. Flatpak resolved
  Steam from Flathub in an empty temporary installation, without installing it.

## Installed-system check

A disposable qcow2 overlay was created over the accepted, installed NOVA 0.3.0
UEFI test VM; the reference disk was kept unchanged. The test used 4 virtual
CPUs, 4 GiB RAM and an online user-mode network. `bootc switch` fetched the
public numbered reference without registry credentials and staged the exact
digest above. bootc reported 263 existing layers and three needed layers
(5.9 kB), with deployment completing in 15 seconds. These sizes apply to this
specific installed VM, not every installation or a future release.

Cold boot entered `0.3.1-preview`, with the exact published booted digest and
`0.3.0-preview` available for rollback. The original personal-file SHA-256,
violet accent, Cinematic motion preference and completed-welcome flag persisted.
Both install references matched their expected hashes; the repaired launcher
was executable and used Discover's local-file option. SELinux was Enforcing,
firewalld active, the update timer enabled and QGA's unconfined-execution boolean
off. Console-authorized test access existed only in the disposable overlay.

A direct warm reboot hit the Windows QEMU/WHPX errors `failed to get xsave
state` and `Unexpected VP exit code 4`; the emulator was stopped after that
failed reset and started again for the successful cold boot. This does not
establish successful warm reboot behavior on the user's physical HP.

`bootc rollback` then selected the previous deployment; after a clean power-off
and start, the VM entered `0.3.0-preview` with `0.3.1-preview` available as its
other deployment. The same personal-file hash and customization were retained;
SELinux remained Enforcing and firewalld active. The original moving Preview
source was restored. These are observed cold-boot update/rollback outcomes,
not a claim that the complete hardware/recovery acceptance matrix has passed.

No Steam installation or game launch on the user's HP is claimed. Existing
ISO/USB kit contents have not been rebuilt or changed for this repair.
