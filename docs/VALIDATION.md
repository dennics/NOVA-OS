# Validation status

NOVA OS 0.2.1 is an experimental Preview. The runtime image was built and
tested in a dedicated Fedora 44 VM. This does not certify the HP laptop or a
full offline ISO installation.

| Check | Evidence/status |
| --- | --- |
| Native application tests | 4/4 CTest entries passed on Fedora 44 |
| Wine launch failure UI | Test script exited with code 7; NOVA reported failure and log location in the UI |
| Wine console smoke | NOVA-WINE-SMOKE-OK; this checks console Wine only, not arbitrary GUI applications |
| Store launchers | Stubbed Discover launch verified for Opera GX and Steam application IDs; real downloads/installations were not tested |
| Runtime image | Built from the pinned Fedora Kinoite 44 base; bootc container lint passed 14 checks with one skipped |
| Image contents | Wine 11.0 and steam-devices present; signed Flathub remote configured; Opera proprietary RPM absent |
| Runtime image | Rebuilt candidate image ID sha256:d3a26241fe40a3ccada8673f5bf24c94c5dc0ae86ff3c7d368bbd18eef64958d |
| 0.2.0 to 0.2.1 laptop update | Not tested on the HP laptop; existing systems require a one-time source switch because 0.2.0 points to nova.invalid |
| Steam or Opera GX use | Applications are offered through Discover; actual installation, login, games and hardware behavior were not tested |
| Installer wrapper | Space-checked staging changes are in source, but the rebuilt Live ISO and full offline installation have not passed acceptance |
| HP installation | Earlier user report documents failure; full Anaconda logs and the exact UUID directory creator were unavailable |
| Security/license audit | Source audit scope and limitations are in PUBLICATION-AUDIT.md |
| Clean-room reproducibility | Runtime was rebuilt in the dedicated development VM; package repositories are not snapshot-pinned and bit-identical output is not claimed |

The publication audit reported no findings in the current worktree and reachable
Git history. It is a scoped automated check, not a guarantee that all secrets or
security issues were found. See ACCEPTANCE.md and INSTALLER-ISSUES.md for
the remaining release gates.