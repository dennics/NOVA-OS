# Security policy

NOVA OS 0.2 Preview has no supported stable release or guaranteed response time.
Fedora updates do not establish security validation of NOVA integration/delivery.

Use GitHub Issues for non-sensitive bugs. For vulnerabilities use GitHub private
reporting **if enabled by the maintainer**:
https://github.com/dennics/NOVA-OS/security/advisories/new . Its availability has
not been verified. No private security mailbox is established. If unavailable,
request a private contact in an issue without exploit details or secrets, then
wait for a maintainer-provided channel.

Include affected commit/component, impact, minimal reproduction and possible
mitigation. Do not publish credentials, private data or unreviewed logs. Only test
on systems you control or have explicit permission to test.

Boundaries include unprivileged Qt apps, polkit-authorized fixed helper operations,
SELinux and bootc destination checks. EXE metadata, files, logs and third-party
themes are untrusted. Wine prefixes do not isolate malicious code. AI command
execution and NOVA cloud accounts are not implemented.
