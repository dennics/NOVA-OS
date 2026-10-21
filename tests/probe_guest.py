"""Read-only evidence collected inside a booted NOVA guest; not a substitute for UI QA."""
import datetime
import json
from pathlib import Path
import subprocess


def command(*args):
    try:
        result = subprocess.run(args, capture_output=True, text=True, timeout=10)
        return {"exitCode": result.returncode, "stdout": result.stdout.strip(), "stderr": result.stderr.strip()}
    except (OSError, subprocess.TimeoutExpired) as error:
        return {"exitCode": None, "error": str(error)}


def main():
    release = Path("/usr/lib/nova/release.json")
    result = {
        "collectedAt": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "novaRelease": json.loads(release.read_text()) if release.exists() else None,
        "uefi": Path("/sys/firmware/efi").exists(),
        "kernelCommandLine": Path("/proc/cmdline").read_text().strip(),
        "selinux": command("getenforce"),
        "firewall": command("systemctl", "is-active", "firewalld.service"),
        "graphicalTarget": command("systemctl", "is-active", "graphical.target"),
        "plasma": command("pgrep", "-a", "-x", "plasmashell"),
        "failedUnits": command("systemctl", "--failed", "--no-pager", "--plain"),
        "bootc": command("bootc", "status", "--format", "json"),
        "memory": Path("/proc/meminfo").read_text(),
    }
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()

