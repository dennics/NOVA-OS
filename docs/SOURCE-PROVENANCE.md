# Source provenance

The original development project was found at workspace-relative
`outputs/NOVA-OS`. It was a populated source directory, not a Git repository.
The public repository already contained one README-only commit,
`74f358e9704f48e032b335a88c33e902ab9b5188`; that history is preserved.

The preparation branch is based on that existing commit. The original application
code, UI, graphics, `system/`, `installer/`, Containerfiles, lock and existing tests
are copied from the real project with their relative paths intact. No missing
application component, bootstrap image or third-party payload was recreated.

`SOURCE-PROVENANCE.json` records included original-file hashes and identifies any
publication edits. Native implementation files are unchanged. The owner approved
MIT for original NOVA work on 2026-10-22; theme metadata uses that license. Additions include
English documentation, publication audit/dependency-fetch helpers and repository
contribution/issue guidance. Root documentation/ignore rules are revised for safe
source publication. The adopted MIT text is retained in `LICENSE` and `LICENSES/MIT.txt`.

The historical wrapper, source lock's local bootstrap IDs and Windows tool's old
ISO pins remain visible. They document real limitations rather than being replaced
with demonstrative implementations. The runtime/image build is not certified
reproducible from a clean checkout; see `BUILD.md`.

Excluded from the publication tree: ISO/ZIP/EXE products, VM disks/firmware, build
caches, third-party Opera and Media Writer payloads, local SSH keys/NoCloud seeds,
unreviewed logs/manifests and personal screenshots. Only three reviewed application
captures and native test logs are included as evidence.

The separate `work/vm-tests` host-specific acceptance experiments are not part of
the original source directory. They contain disposable account/LUKS credentials
and VM-state assumptions and are excluded from publication. The existing project
`tests/` and `scripts/check-ui.sh` are retained. A reusable public installer
automation harness still needs credential parameterization and target guards;
the present VM guide provides the manual acceptance procedure.
