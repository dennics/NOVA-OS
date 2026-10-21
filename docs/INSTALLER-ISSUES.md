# Installer failures — open release blockers

Status: **unresolved**. This preparation retains the historical defective wrapper.
The Bugzilla API-key field is part of optional crash reporting after failure;
no Bugzilla account or key is required to install NOVA.

## A — target root contains temporary directories

The HP report fails during `bootc install to-filesystem` root validation:

```text
Verifying roots: Requiring directory contains only mount points
Found empty directory: <uuid>
```

`installer/usr/local/bin/bootc` creates `var/tmp/nova-bootc.*` beneath the target
resolved as `/var/mnt/sysimage`, exports `TMPDIR`, then invokes the preserved
real binary. Ordinary scratch directories violate bootc's initially empty target
contract: only mounts, their parents and allowed filesystem metadata are permitted.
The [bootc 1.16.13 implementation](https://github.com/bootc-dev/bootc/blob/v1.16.13/crates/lib/src/install.rs)
explains the validation. NOVA's wrapper has a real integration defect.

The reported UUID's exact full path/creator on the HP has **not** been established
from complete HP logs. Do not assume it is a partition or delete matching names.
Capture `/tmp/anaconda.log`, `/tmp/storage.log`, `/tmp/program.log`,
`/tmp/packaging.log`, `findmnt --json` and `lsblk --json --fs` before corrections.
Review privately and publish only sanitized excerpts.

## B — import exhausts the Live writable filesystem

The follow-up report says moving `TMPDIR` to `/tmp` allows progress, then fails:

```text
write /var/tmp/container_images_*: no space left on device
```

Earlier local VM attempts also observed this import path exhausting the Live
overlay with free target space. It does not establish that the SSD is full.
`TMPDIR` alone does not redirect every transport's image temporary files.
[Red Hat's bootc deployment guidance](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/using_image_mode_for_rhel_to_build_deploy_and_manage_operating_systems/deploying-the-rhel-bootc-images)
describes separate storage and a `/var/tmp` bind for image import. That approach
still needs integration with NOVA's exact Live/Anaconda stack. The reported `/tmp`
edit has not been silently substituted for the historical wrapper here.

## Safe staging proposal — not implemented

1. Record namespaces, mount IDs/device identity, bytes/inodes, options and Anaconda
   logs before writing. Require the explicitly selected root/boot/ESP mounts;
   reject symlinks, missing mounts, read-only or ambiguous targets. Never select
   or format a second disk automatically.
2. Initially prove the contract with an explicitly selected **separate scratch
   filesystem**, mounted outside `/mnt/sysimage`. The VM fixture may provide a
   second disposable virtual disk. A single-SSD product needs a separately reviewed
   Anaconda-managed temporary volume/partition lifecycle. An ordinary directory
   or concealed bind on the target must not be used to evade bootc validation.
3. Use root-owned restricted scratch and appropriate SELinux contexts. In a private
   installer mount namespace back `/var/tmp` and other *confirmed* import paths
   with that filesystem; also set `TMPDIR`. Verify where actual writes occur.
   Do not change unrelated desktop processes' temporary filesystems.
4. Derive conservative scratch/destination bounds from actual embedded layer sizes,
   decompression/import behavior, concurrent copies and measured high-water marks.
   Check free bytes **and inodes** with reserve; fail clearly before deployment
   if insufficient. A guessed universal threshold is not adequate.
5. Keep SELinux enforcing and bootc validation. Capture the process namespace's
   mount tree immediately before invocation. Define success, failure, interruption,
   power-loss and retry handling. Unmount only invocation-owned mounts and clean
   only verified scratch; never recursively clean the installation root.

The separate-filesystem approach is a reference experiment, not a finished laptop
installer. Do not use `/boot` or the ESP as unbounded staging space.

## Required evidence before closure

Reproduce the original failure offline in a disposable VM and capture its real
layout/logs. Verify that foreign ordinary files still make bootc refuse deployment.
Test insufficient bytes/inodes, missing scratch, interruption and retry. Rebuild
the ISO with the fix and install from its **unmodified bytes without a virtual
NIC**. Detach it and boot normally; verify login, persistence, SELinux enforcing,
firewall and scratch cleanup. Repeat with encryption and manual partitioning while
preserving an unassigned sentinel partition. Hardware retesting is separate.
Successful image construction or UI screenshots do not close these issues.
