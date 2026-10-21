# Publication audit — 2026-10-22 (Europe/Bucharest)

## Scope and original files

The public repository was read and cloned before preparing changes. Its existing
README-only commit `74f358e9704f48e032b335a88c33e902ab9b5188` is the parent; no
history was deleted or rewritten. The populated original project had no `.git`
history. Only this clone's reachable history and the proposed source tree are in
publication scope. Unrelated workspace files and unreachable Git objects are not
being published.

The source inventory maps 105 included files to original project paths/hashes.
95 are byte-identical before Git newline normalization; ten publication edits
are documentation/ignore/license status and three provisional theme license
labels. The C++, QML, C#, installer logic, Containerfiles and build pipeline are
authentic and unchanged. New helpers, English documentation and CI/issue guidance
are clearly additive. The final full file inventory is the prepared Git commit.

## Secrets and private/generated material

The publication tree excludes Opera RPM/EULA HTML, Media Writer ZIP/extracted
binaries, compiled EXEs/DLLs, ISO/VM images, firmware, caches, local SSH keys,
NoCloud seeds, unreviewed manifests/logs and personal screenshots. The three PNGs
were visually reviewed; they show only NOVA's application. Original files remain
in the development workspace; publication preparation did not delete them.

Checks used:

- Manual review of selected paths, configuration, graphical assets, dependency
  provenance and native logs; targeted searches for keys, passwords, tokens and
  personally identifying local paths.
- `scripts/audit-publication.py`: unignored worktree plus every blob/path and
  commit message in every reachable commit, including content no longer in HEAD.
  Checks private-key/token patterns, literal credential assignments, private paths,
  generated/large files, binary exceptions and fixed fixture hashes. It reports
  paths/rules rather than matched secret values.
- Gitleaks **8.30.1**, default rules, redacted output, worktree directory scan and
  all-history Git scan. Official Windows ZIP SHA-256 verified against upstream:
  `d29144deff3a68aa93ced33dddf84b7fdc26070add4aa0f4513094c8332afc4e`.
  No custom rule exclusions or secret allowlist were introduced.

The precommit checks found no credential leaks. Repeat both worktree/history
checks on the final commit before publication. Detailed machine-local scan JSON
is kept in ignored `artifacts/` to avoid publishing private scanner paths.
Pattern scanning cannot prove the absence of every secret or vulnerability.

The pre-existing public commit includes its original author email metadata.
It is preserved, not republished as a new contact or silently rewritten. New
preparation commits use a GitHub noreply identity. If removal of historical
identity metadata is desired, that needs an explicit separate history decision.

## Compilation and tests

The publication's native source subset was transferred to a new directory in the
dedicated Fedora 44 VM and compiled from scratch. Both native applications and
all four CTest entries built/passed. Log:
`evidence/native-publication-clean-build.log`. The metrics-only CMake configuration
also built and passed independently. The four additive Python publication-helper
tests passed locally, covering secret redaction, forbidden paths, bad-download
cleanup and refusal to overwrite an unverified input.

CMake reported Kirigami plugin link-target warnings; dynamic UI tests passed.
The proposed GitHub Actions workflow has read-only permissions, immutable action
commits and complete history checkout. Its commands are tested locally where
applicable, but **the workflow has not run on GitHub**. It covers source checks
and metrics, not the complete Qt/KDE or installer acceptance suite.

## Licensing and unresolved release risks

MIT is proposed for original work; no final license has been adopted. The root
pending notice and theme labels make that explicit. Original ownership/branding
approval remains an owner decision. The RAR fixture's upstream CC0 text/provenance
is included. Selected exact RPM license expressions are recorded for 21 actual
packages. No third-party binary payload or proprietary GPU driver is committed.

The Opera EULA does not establish permission for this ISO packaging; proprietary
image distribution remains held. Media Writer/Qt binary kits require their own
corresponding-source/notices review. This source audit does not clear a full OS
image's transitive licensing. See `LICENSING.md`.

Installer issues A and B remain open. The exact HP UUID path still needs complete
logs/mount evidence. Safe staging is proposed, not implemented or validated.
Clean-host ISO reproduction remains blocked by exact unpublished local bootstrap
images and separately acquired inputs. There is no public NOVA update registry,
stable release, recommended ISO or certified hardware list.

## Approval and push procedure

The prepared source branch is local only. Before public push the owner must
approve original-source licensing and this source publication. Then finalize the
approved license/metadata, rerun audits/tests relevant to those edits and inspect
the final diff. Re-fetch the remote and check ancestry/content changes. Preserve
any new remote work; stop for conflicts rather than force-pushing. Confirm an
authorized GitHub write credential exists without exposing its value.

Push only the reviewed source history. Do not upload the defective ISO/kit as a
recommended release or claim the installer is fixed. Repository private security
reporting availability and write permissions have not been confirmed by this
read-only GitHub inspection.
