# NOVA OS 0.3 Preview validation — 2026-10-22

These results cover the local development build. They do not establish a stable
release, a public update service, or successful installation/update on the HP.

Environment: Fedora 44 development VM; Qt 6.11.2, Frameworks 6.31.0; runtime
Plasma 6.7.5. The local runtime derives from the existing 0.2.1 image
`sha256:d3a26241fe40a3ccada8673f5bf24c94c5dc0ae86ff3c7d368bbd18eef64958d`.
This is not a fresh-host image-reproducibility test. Final local image identity
and input archive hash are recorded in the ignored build artifact manifest.

| Check | Observed result |
| --- | --- |
| Native C++/Qt/KDE build | Passed |
| CTest suites | 7/7 passed |
| Update metadata decoding | Current/cached/staged/rollback versions, digest differences, download-only status, rollback boot order and legacy-source recognition passed |
| Process safety | Parser, paused sampling, own-user guards and pidfd termination of a deliberately spawned child passed |
| Panel migration | Qt JS test preserves unbranded panels and the old branded widget's index/shortcut; it does not test an installed Plasma session |
| Control Center UI | All eight pages loaded without QML warnings; keyboard and monitor lifecycle passed |
| Layout captures | This PC and Task Manager captured and visually reviewed at 1280×720 and 1920×1080 |
| NOVA Start | Real applet loaded in `plasmawindowed` on an isolated X11 virtual display, Romanian catalogue loaded, keyboard search found NOVA Update and Return launched `nova-control-center --page updates`; no QML errors found |
| Sound generation | 14 original stereo PCM cues; reproducible bytes, duration ≤1.2 seconds, bounded non-clipping amplitude |
| Publication guards | Existing tags, inconclusive network access and wrong image labels refused; private version did not promote Preview; public mock promoted matching digest. No network publication performed by these tests |
| Runtime image | Constructed locally; bootc lint passed 14 checks, skipped 1 |
| Boot assets | Native two-step loop retained, 30 new orbit frames rendered; initramfs membership verified for NOVA, OSTree, crypt and systemd-cryptsetup |
| Update units/config | `systemd-analyze verify` passed inside the runtime; timer/firewall enablement, helper executability and SELinux enforcing configuration checked |
| Container update attempt | Refused because the container is not an installed bootc system |
| Source audit | New source worktree and all four existing published commits scanned; no findings in the scoped audit |

The Start capture is a real isolated applet window, not a full desktop or a
mockup. Its session-action list reflects the services available in that test
container. The CPU/RAM/storage captures reflect the development VM and are not
performance benchmarks. See [screenshot provenance](screenshots/README.md).

## Not yet validated

- 0.2.1 → 0.3 registry update, reboot and rollback on an installed test VM, with
  personal-file markers and application settings checked.
- The HP laptop, physical installation, Secure Boot, drivers and games.
- Existing-user panel migration in an installed Wayland session (only the scoped
  JavaScript migration test has run).
- Plymouth encrypted-disk unlock and physical GPU smoothness in 0.3.
- Sound playback through an actual audio device and notification preferences.
- Anonymous access to a published 0.3 Preview channel.

## Local ISO and Windows kit check — 2026-10-22

`NOVA-OS-0.3-Preview-x86_64.iso` was produced and transferred with its size
(4,950,038,528 bytes) and SHA-256 independently checked on Windows:
`9119ccb6e21780f0310c59a4a68c82a97c9373da74361aff9bd67c9afdd23240`.
Its embedded runtime is the tested local 0.3 image above. The Live image was
derived from that runtime, adding Fedora's installer packages. Build manifests,
package lists and native test evidence accompany the local kit.

The unchanged ISO booted in QEMU/WHPX with UEFI, 4 CPUs, 4 GiB RAM, a fresh
48 GiB virtual disk and **no virtual network adapter**. The native Anaconda
WebUI completed whole-disk plain ext4 installation. Its log records bootc
deployment, root/boot finalization and staging cleanup. Neither the UUID root
failure nor the `/var/tmp` capacity failure occurred. The 12.5 GiB loop-backed
scratch mount was observed during deployment and absent afterward.

After a clean power-off, the virtual machine booted without an ISO attached and
the created local account logged in. bootc reports 0.3.0-preview, a test file
created on the installed user volume before power-off retained its SHA-256, the
temporary Live account is absent, SELinux is Enforcing, firewalld is active,
and the NOVA metadata-check timer is enabled. The welcome UI saved violet,
Cinematic and its completed flag on the installed user account.

SELinux detail: the unmodified Fedora `/usr/bin/liveinst` saves the Live state,
temporarily calls `setenforce 0` (line 151), and restores it when the installer
exits (line 278). The Live session was Enforcing before launch and after exit;
the installed system was Enforcing. NOVA did not change this upstream behavior,
disable policy, enable QGA's unconfined-execution boolean or remove bootc root
validation. A transient test worker was explicitly started from the VM's
authorized console; it is not part of the image.

The centered panel and NOVA Start also opened in the actual Live Wayland session.
The NOVA orbit artwork appeared during an installed-system boot. This does not
validate physical GPU smoothness or encrypted-disk prompting. A minor overlapping
“All apps” label was visible in the Start menu under this Plasma style; that
cosmetic issue remains in this Preview. The loop setup emitted a non-sector-aligned
size warning; deployment and cleanup nevertheless completed.

The Windows writer was rebuilt against this exact ISO. Its safe self-test checks
the embedded Fedora package, ISO checksum, helper arguments and ACL classification
and exits successfully without enumerating or writing USB disks. The release JSON
records the real executable and source hashes. The ZIP packager verifies file
hashes and ZIP CRC and includes NOVA sources, Media Writer sources and notices.

This is an experimental **local test kit**, not stable release acceptance.
Physical USB writing, HP hardware, manual partitioning, encryption, interruption
recovery and installed online update/rollback are still unvalidated for this ISO.
The 0.3 registry image/channel has not been published by this work.
