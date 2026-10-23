"""Record provenance after a successful build; acceptance remains a separate gate."""
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import subprocess


def command(*args):
    return subprocess.check_output(args, text=True).strip()


root = Path(__file__).resolve().parents[1]
artifacts = root / "artifacts"
test_log = (artifacts / "native-tests.log").read_text()
passed_tests = test_log.count("Test Passed.")
summary = re.search(r"100% tests passed, 0 tests failed out of (\d+)", test_log)
if summary:
    passed_tests = len(re.findall(r"(?m)^\s*\d+/\d+ Test #[^\n]*\bPassed\b", test_log))
    if passed_tests != int(summary.group(1)):
        raise SystemExit("CTest summary does not match the recorded test entries")
if passed_tests < 2 or "Test Failed." in test_log or "***Failed" in test_log:
    raise SystemExit("Native test evidence is missing or contains failures")
runtime = json.loads((artifacts / "runtime-inspect.json").read_text())[0]
version = runtime["Labels"]["org.opencontainers.image.version"]
artifact_version = version.removesuffix(".0-preview") if version.endswith(".0-preview") else version.removesuffix("-preview")
iso_name = f"NOVA-OS-{artifact_version}-Preview-x86_64.iso"
checksum = (artifacts / (iso_name + ".sha256")).read_text().split()[0]
live = json.loads(command("podman", "image", "inspect", f"localhost/nova-live:{version}"))[0]
tools = json.loads((artifacts / "build-tools-inspect.json").read_text())[0]
evidence_names = ["packages.txt", "runtime-inspect.json", "native-tests.log",
                  "build-tools-inspect.json", "build-tools-packages.txt", "nova-live.osbuild-manifest.json"]
evidence = {name: hashlib.sha256((artifacts / name).read_bytes()).hexdigest() for name in evidence_names}
sources = []
for path in sorted(root.rglob("*")):
    relative = path.relative_to(root)
    if not path.is_file() or any(part in {"build", "artifacts", "rar-fixture", ".git", "__pycache__"} for part in relative.parts):
        continue
    if relative.parts[0].startswith("NOVA Media Creation Tool"):
        continue
    if relative.as_posix() == "docs/VALIDATION.md":
        continue
    sources.append({"path": relative.as_posix(), "sha256": hashlib.sha256(path.read_bytes()).hexdigest()})
manifest = {
    "schema": 1,
    "name": "NOVA OS",
    "createdAt": datetime.now(timezone.utc).isoformat(),
    "sources": json.loads((artifacts / "sources.lock.json").read_text()),
    "iso": {"file": iso_name, "sha256": checksum,
            "bytes": (artifacts / iso_name).stat().st_size},
    "images": {"runtime": runtime["Id"], "live": live["Id"], "isoTools": tools["Id"]},
    "evidenceSha256": evidence,
    "tools": {name: command(*args) for name, args in {
        "podman": ("podman", "--version"),
        "cmake": ("cmake", "--version"),
        "compiler": ("c++", "--version"),
        "kernel": ("uname", "-r"),
    }.items()},
    "sourceFiles": sources,
    "nativeTests": {"status": "passed", "passed": passed_tests, "evidence": "native-tests.log"},
    "vmAcceptance": {"status": "not-run", "recordedAtBuild": True, "criteria": "docs/ACCEPTANCE.md"},
}
(artifacts / "build-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
