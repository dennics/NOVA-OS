# Changelog

## 0.3.1 Preview — store repair, 2026-10-23

- Repair Steam/Opera GX first-install launchers using official Flathub install
  references instead of a case-folded AppStream URL and a preloaded catalog.
  Published as an OS update on the anonymous `ghcr.io/dennics/nova-os:preview`
  channel. The previously delivered ISO is unchanged.
- Verified deployment from public GHCR onto installed NOVA 0.3, cold boot into
  0.3.1 and rollback cold boot to 0.3.0, with the personal-file fixture and
  personalization retained. Windows QEMU/WHPX warm-reset failures remain a
  test-environment limitation; no HP, Steam startup or game validation claimed.

## 0.3.0 Preview — local test kit

- Moving NOVA Preview image channel, one-action system update UI, streamed logs,
  version status, metadata-check timer and explicit restart/rollback prompts.
- A fixed, authorized migration path from legacy NOVA Preview sources.
- This PC with standard personal folders and actual mounted storage capacity.
- Task Manager with visible-page CPU/RAM/process sampling, search, sorting and
  confirmed own-user SIGTERM through pidfds.
- Original NOVA Start Plasma applet, centered floating panel and conservative
  migration of the old NOVA-branded launcher.
- Original orbit boot frames on native Plymouth and 14 generated notification cues.
- Native parser/lifecycle/process-safety tests and expanded QML page coverage.
- Local 0.3 ISO and Windows USB kit: checksum-pinned image, complete offline
  whole-disk plain ext4 installation in a UEFI/WHPX VM, detached-ISO boot/login,
  persisted user-file fixture, enforcing SELinux and active firewall verified.
- No published 0.3 update or physical HP/USB validation claimed; manual layouts,
  encryption, failure recovery and installed update/rollback acceptance remain open.

## 0.2.1 Preview — compatibility and update repair

- Wine launches report process-start failures, exit status and a per-launch log.
- Flathub is configured with signed repository metadata for Discover.
- NOVA Steam and Opera GX launchers open their Discover pages when those
  applications are absent; proprietary binaries are not bundled.
- Fedora `steam-devices` controller rules are included.
- The installer wrapper uses space-checked, disk-backed temporary staging to
  avoid leaving scratch directories in the bootc target root. Full offline
  installation validation is still required.
- The image update target is prepared at
  `ghcr.io/dennics/nova-os:0.2.1-preview`; installed 0.2.0 systems need a
  one-time source migration before Settings can use the registry.

## 0.2 Preview — source publication, 2026-10-22

Source snapshot only; no stable or recommended binary release.

- Original native Control Center and NOVA Dark Plasma customization.
- Smart Compatibility inspection/native hints and explicit Wine prefixes/launch.
- bootc update helper/status, power-profile D-Bus integration and GPU detection.
- Opera GX configuration in local image sources; no proprietary browser payload.
- Ark/unar/7zip archive integration and the existing RAR fixture/test.
- Anaconda/bootc integration, Containerfiles, osbuild scripts, four native tests
  and Windows USB utility source.
- English architecture/build/VM documentation, contribution/security guidance,
  source provenance and publication audit.
- Owner-approved MIT license for original NOVA code, documentation and graphics.

Unresolved: target-root temporary directories fail bootc validation; `TMPDIR`
alone does not prevent `/var/tmp` image-import exhaustion. Historical builds
depend on unpublished 0.1 bootstrap images. No full fix, fresh-host ISO reproduction
or successful 0.2 hardware installation is claimed.

## 0.1 development baseline

Local groundwork for desktop/Live/offline installation. Some 0.1 VM scenarios
have historical evidence in the development workspace; those do not validate 0.2
or establish a public stable release.
