# Changelog

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
