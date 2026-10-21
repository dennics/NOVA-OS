"""Package the exact ISO pinned by NOVA Media Creation Tool as a ZIP64 USB kit."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import zipfile


PROJECT = Path(__file__).resolve().parents[2]
RELEASE = PROJECT / "NOVA Media Creation Tool.release.json"
OUTPUT = PROJECT / "artifacts" / "NOVA-OS-0.2-Preview-USB-Kit.zip"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(8 * 1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> None:
    release = json.loads(RELEASE.read_text(encoding="utf-8"))
    exe = PROJECT / release["executable"]["file"]
    iso = PROJECT / "artifacts" / release["iso"]["file"]
    for file, record in ((exe, release["executable"]), (iso, release["iso"])):
        if not file.is_file() or file.stat().st_size != record["bytes"]:
            raise SystemExit(f"Missing file or incorrect size: {file}")
        actual = sha256(file)
        if actual != record["sha256"]:
            raise SystemExit(f"SHA-256 mismatch for {file.name}: {actual}")
    instructions = (
        "NOVA OS 0.2 Preview - USB Kit\r\n"
        "\r\n"
        "Extrage ambele fisiere in acelasi folder. Porneste NOVA Media Creation Tool.exe\r\n"
        "si selecteaza stickul USB corect. Aplicatia gaseste ISO-ul automat, ii\r\n"
        "verifica SHA-256 si cere confirmarea inainte de a sterge stickul.\r\n"
        "Stickul trebuie sa aiba minimum 8 GB. Scrierea fizica nu a fost inca\r\n"
        "validata pe acest PC. ISO-ul este un preview pentru testare in VM;\r\n"
        "instalarea pe laptop, pastrarea Windows si Secure Boot necesita validare.\r\n"
    )
    OUTPUT.parent.mkdir(exist_ok=True)
    temporary = OUTPUT.with_suffix(".zip.tmp")
    if temporary.exists():
        temporary.unlink()
    try:
        with zipfile.ZipFile(temporary, "w", compression=zipfile.ZIP_STORED,
                             allowZip64=True) as archive:
            archive.writestr("CITESTE-MA.txt", instructions.encode("utf-8"))
            archive.write(exe, exe.name)
            archive.write(iso, iso.name)
        with zipfile.ZipFile(temporary) as archive:
            if archive.testzip() is not None:
                raise SystemExit("USB kit ZIP integrity check failed")
        temporary.replace(OUTPUT)
    finally:
        if temporary.exists():
            temporary.unlink()
    digest = sha256(OUTPUT)
    OUTPUT.with_suffix(".zip.sha256").write_text(
        f"{digest}  {OUTPUT.name}\n", encoding="ascii")
    print(f"{OUTPUT} ({OUTPUT.stat().st_size} bytes) SHA-256 {digest}")


if __name__ == "__main__":
    main()
