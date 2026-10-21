# Validation status

This publication preparation is a source snapshot. No stable release or working
0.2 installer is claimed.

| Check | Evidence/status |
| --- | --- |
| Original source present | C++, QML, C#, themes, installer/configuration and build scripts copied from the development project; `SOURCE-PROVENANCE.md` |
| Historical native suite | Four CTest entries passed on Fedora 44, 2026-10-21; original log in `evidence/native-tests-2026-10-21.log` |
| Fresh native compilation | Publication C++/QML/asset/test copy compiled in a new Fedora VM directory, then 4/4 CTest entries passed; `evidence/native-publication-clean-build.log` |
| CPU parser | Interval/guest accounting, reset, memory-cache and malformed-source cases in `tests/metrics_test.cpp` |
| Compatibility parser | Invalid/truncated PE, architecture and metadata-hint cases in `tests/compatibility_test.cpp` |
| Backend/UI | Persistence, unavailable metrics, monitor lifecycle, reduced effects and keyboard/page lifecycle cases |
| Real screenshots | Three native-application captures, reviewed for personal desktop content; no performance or install-success claim |
| 0.2 offline installation | Known failures A and B; not accepted |
| HP installation | User-reported failure; full HP logs unavailable in this preparation |
| Update/rollback, Wine end-to-end, profile hardware effects | Not established by parser/UI tests; require separate system acceptance |
| Clean-host ISO reproduction | Blocked by unpublished exact local bootstrap images and separately acquired inputs |
| Security/license audit | Scope and results in `PUBLICATION-AUDIT.md`; no automatic claim of vulnerability freedom |

CMake emitted Kirigami QML plugin link-target warnings in this dynamic Qt/KDE
environment. Compilation and the real offscreen UI test still passed. This does
not validate static linkage or a different dependency stack. The additive Python
publication-helper tests are run separately with `python3 tests/publication_test.py`.

Historical 0.1 successes are not carried forward as 0.2 passes. A successful
compiler/test run does not verify Anaconda, disk formatting, SELinux after first
boot, physical USB writing, Secure Boot or gaming performance. The release gate
is `ACCEPTANCE.md`, with issue-specific additions in `INSTALLER-ISSUES.md`.
