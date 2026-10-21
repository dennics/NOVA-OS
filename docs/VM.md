# VM testing

Current 0.2 installation is known to fail. This is a validation procedure for
future rebuilt candidates, not an assertion that the present installer works.
Use disposable x86_64 UEFI VMs with a separate target disk and no access to host
physical drives. Previous work used QEMU, 4 vCPUs, 6–8 GiB RAM and a 48 GiB disk.
WHPX was used on the Windows development host; TCG is slower. These are examples,
not supported hardware minima or performance benchmarks.

1. Record the commit, ISO SHA-256/size, build manifest, QEMU/firmware versions and
   machine settings. Attach only the ISO and disposable disk; remove the virtual
   NIC (`-nic none` in QEMU). Do not patch the ISO or Live files for the acceptance run.
2. Boot Live. Confirm Plasma usability and included applications offline. Collect
   a read-only `python3 tests/probe_guest.py` result from an appropriately authorized
   console. The probe is diagnostic only and does not install anything.
3. Open the actual NOVA/Anaconda installer. Check target identity and confirmation,
   create a disposable account, then install. Capture mount trees/Anaconda logs at
   failure; sanitize before publication. A Bugzilla API key is optional for reports.
4. After completed installation, shut down cleanly, detach the ISO and start the
   disk alone. Verify normal graphical login, no temporary Live user, user file
   and NOVA preference persistence, lock, restart and shutdown.
5. Verify `getenforce` reports `Enforcing`, the firewall is active, and `bootc status`
   matches the deployed image. Check low-space failure handling/scratch cleanup.
6. Repeat encryption and manual assignments on separate fixtures. Preserve an
   unassigned sentinel partition. Never reuse a failed disk without first recording
   its layout and logs; use new disks or deliberate overlays for repeated tests.

`ACCEPTANCE.md` defines the complete gate, including UI scale/accessibility and
update/rollback. Running the native tests is not a substitute for it. A test that
modifies Live after boot is a diagnostic experiment and must not be described as
an unchanged-ISO installation test. VM results do not certify HP hardware, Secure
Boot, dual boot or gaming performance.
