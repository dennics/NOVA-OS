# Contributing

0.2 is an experimental snapshot with known installer failures. Read `README.md`,
`docs/BUILD.md`, `docs/ARCHITECTURE.md` and `docs/INSTALLER-ISSUES.md` first.
The original-source license awaits owner approval; external code contributions
should wait until that decision is recorded.

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
out of Git. New assets need origin/license records. After license approval,
submit contributions with rights to contribute under the adopted terms. No CLA
is currently established.
