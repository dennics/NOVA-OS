# Changelog

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
