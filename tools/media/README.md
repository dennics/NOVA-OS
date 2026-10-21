# Fedora Media Writer input

Only the original provenance JSON is tracked. The portable ZIP, extracted Qt
libraries and helper executable are excluded from Git. Retrieve the exact input
for local Windows builds with `python3 scripts/fetch-dependency.py media-writer`.
It is verified and never executed by that helper. See `docs/DEPENDENCIES.md` and
`docs/LICENSING.md` before any binary kit redistribution.
