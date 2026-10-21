"""Record provenance after a successful build; acceptance remains a separate gate."""
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import subprocess


def command(*args):
    return subprocess.check_output(args, text=True).strip()


root = Path(__file__).resolve().parents[1]
artifacts = root / "artifacts"
test_log = (artifacts / "native-tests.log").read_text()
if test_log.count("Test Passed.") < 2 or "Test Failed." in test_log:
    raise SystemExit("Native test evidence is missing or contains failures")
checksum = (artifacts / "NOVA-OS-0.2-Preview-x86_64.iso.sha256").read_text().split()[0]
runtime = json.loads((artifacts / "runtime-inspect.json").read_text())[0]
version = runtime["Labels"]["org.opencontainers.image.version"]
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
    "iso": {"file": "NOVA-OS-0.2-Preview-x86_64.iso", "sha256": checksum,
            "bytes": (artifacts / "NOVA-OS-0.2-Preview-x86_64.iso").stat().st_size},
    "images": {"runtime": runtime["Id"], "live": live["Id"], "isoTools": tools["Id"]},
    "evidenceSha256": evidence,
    "tools": {name: command(*args) for name, args in {
        "podman": ("podman", "--version"),
        "cmake": ("cmake", "--version"),
        "compiler": ("c++", "--version"),
        "kernel": ("uname", "-r"),
    }.items()},
    "sourceFiles": sources,
    "nativeTests": {"status": "passed", "evidence": "native-tests.log"},
    "vmAcceptance": {"status": "not-run", "recordedAtBuild": True, "criteria": "docs/ACCEPTANCE.md"},
}
(artifacts / "build-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
