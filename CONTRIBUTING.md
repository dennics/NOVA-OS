# Contributing

0.2 is an experimental snapshot with known installer failures. Read `README.md`,
`docs/BUILD.md`, `docs/ARCHITECTURE.md` and `docs/INSTALLER-ISSUES.md` first.
Original NOVA code is licensed under MIT; third-party material keeps its own terms.

For bugs include the commit, build manifest/image hash when relevant, environment,
exact steps and expected/actual results. Installer reports need Anaconda logs and
mount layout. Review logs privately and redact account names, machine IDs, disk
serials/labels/UUIDs consistently. Never post keys, passwords or unreviewed bundles.

Keep pull requests focused. Preserve the existing source/install paths:
Containerfile copies `system/` and `installer/` directly into images. Describe
behavior changes, tests run and untested scenarios. Screenshots and successful
image builds do not prove installation, hardware compatibility or FPS gains.

Run CMake/CTest for native changes and `python3 scripts/audit-publication.py` for
source changes. Installer changes need offline tests from an unchanged rebuilt
ISO as defined in `docs/ACCEPTANCE.md`. Record failures and interrupted runs.
Destructive tests belong only on identified disposable virtual disks.

Keep normal applications unprivileged, administrative verbs fixed and authorized
by services/polkit, SELinux enforcing and bootc target validation intact. Wine
executes untrusted programs as the user; prefixes are not a sandbox.

Keep generated binaries, third-party payloads, caches, VM state and credentials
out of Git. New assets need origin/license records. Submit original contributions
under MIT and only when you have the rights to do so. No CLA is currently established.
