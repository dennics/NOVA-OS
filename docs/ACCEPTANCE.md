# NOVA OS 0.2 — release gate

The presence of source code or a completed ISO build does not pass this gate.
Every scenario needs recorded evidence from a booted guest.

| Scenario | Required evidence |
| --- | --- |
| Offline Live boot | No virtual NIC; usable Plasma desktop; screenshot and guest probe |
| Offline installation | Embedded payload; Anaconda completes on a new virtual disk |
| Manual partition choice | On a disposable pre-partitioned disk, assign EFI/boot/root, format only selected targets, and verify an unassigned KEEP partition stays intact |
| First installed boot | ISO detached; normal login; no live account or automatic login |
| Persistence | User-created file, NOVA accent and motion preference survive reboot |
| Encryption | LUKS installation unlocks and reaches the desktop |
| Power and lock | Lock/unlock, restart and shutdown work |
| Metrics | CPU delta and MemAvailable match /proc; unavailable data stays unavailable |
| Monitor lifecycle | Sampling stops when monitor page/window is not visible |
| Component failure | Terminating Control Center leaves Plasma usable |
| Update and rollback | Two local builds; previous deployment boots; user file survives |
| Security | SELinux enforcing; firewall active; administrative actions authorize correctly |
| Display and access | 1280x720 and 1920x1080; keyboard, scaling and reduced motion |
| Browser and archives | Opera GX launches offline and owns HTTP/HTTPS/HTML defaults; Ark extracts a RAR sample with `unar` |
| Smart Compatibility | Opening a trusted disposable `.exe` shows an offline assessment before execution. Verify a PE with curated ProductName metadata (Blender, VLC or OBS Studio), an unknown PE, an ARM64 PE and an invalid/non-PE file; native suggestion is labelled unverified. Wine availability is shown without claiming compatibility. The file is not run until the user explicitly chooses Wine. Wine runs as the normal user; cancelling, unsupported architecture or missing Wine leaves the file unopened. |
| Wine environments | Separate per-app and shared prefixes produce the expected `WINEPREFIX`; no execution occurs when the assessment dialog closes. |
| Update Engine | On the offline placeholder source, check/download/stage stay disabled. Unknown helper verbs fail; polkit authorizes fixed operations only. With a configured test registry, check, download, stage, reboot and rollback are validated on two images. |
| Profile Manager | Eco/Balanced/Gaming map to the system's supported power profiles; unavailable hardware/service reports an error. GameMode is checked for an explicitly launched game. |
| Driver Center | Detected GPU vendor and active driver match sysfs. No proprietary NVIDIA installation is claimed without curated source and Secure Boot validation. |
| ZIP and 7z | Ark default associations and round-trip extraction produce the expected files. |

Record failed, blocked and not-run scenarios explicitly. Preserving an existing
Windows installation and dual-boot require separate tests. VM results do not
establish GPU performance, hardware compatibility, Secure Boot support or FPS
improvements.

