# Installer failures — validation still open

Status: mitigation implemented in source; full installation remains unverified.
The 0.2.1 runtime update does not contain an updated Live installer. No rebuilt
0.2.1 ISO or successful offline installation is claimed.

The HP report fails during bootc install to-filesystem root validation:

```text
Verifying roots: Requiring directory contains only mount points
Found empty directory: <uuid>
```

The earlier wrapper put scratch data under the selected target root, which
violates bootc's requirement that the target initially contain only mount
points. The exact path and creator of the reported UUID have not been established
because complete Anaconda logs and a mount inventory from the HP were unavailable.
Do not assume it names a partition or delete matching directories. Preserve
/tmp/anaconda.log, /tmp/storage.log, /tmp/program.log, /tmp/packaging.log,
findmnt --json and lsblk --json --fs before any correction; sanitize private
data before sharing.

The follow-up report says moving TMPDIR to /tmp allows progress, then fails:

```text
write /var/tmp/container_images_*: no space left on device
```

This indicates the import path writes under /var/tmp; free target space alone
does not prove the Live writable filesystem has enough room.

## Source mitigation under test

installer/usr/local/bin/bootc now validates the Anaconda target and the
selected root filesystem, estimates required bytes and inodes, and creates a
preallocated loop-backed ext4 staging filesystem on the selected root device.
It mounts that filesystem at the Live system's /var/tmp, restores its SELinux
context, removes the staging file's directory entry before invoking the
unmodified bootc binary, then attempts to unmount and clean up on exit. SELinux
and bootc root checks remain enabled.

The wrapper refuses layouts it does not recognize and fails early when its
conservative space checks do not pass. That behavior has not been validated with
manual partitioning, separate /home or /var, encryption, interruption, retry,
or a full installation. The staging mount temporarily covers the Live system's
/var/tmp; its interaction with Anaconda services still needs testing. This
source-only change is not present in the currently installed 0.2.0 system and
is not part of the 0.2.1 runtime image update.

## Required evidence before closure

Reproduce the original failure offline in a disposable VM and capture its real
layout/logs. Verify that foreign ordinary files still make bootc refuse
deployment. Test insufficient bytes/inodes, missing scratch, interruption and
retry. Rebuild the Live ISO with these exact sources and install from its
unmodified bytes without a virtual NIC. Detach it and boot normally; verify
login, persistence, SELinux enforcing, firewall and staging cleanup. Repeat
with encryption and manual partitioning while preserving an unassigned sentinel
partition. Hardware retesting is separate. Successful image construction or
Wine tests do not close these installer issues.