"""Package the exact ISO pinned by NOVA Media Creation Tool as a ZIP64 USB kit."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import zipfile


PROJECT = Path(__file__).resolve().parents[2]
RELEASE = PROJECT / "NOVA Media Creation Tool.release.json"


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
    output = iso.with_name(iso.name.replace("-x86_64.iso", "-USB-Kit.zip"))
    if output == iso or output.suffix != ".zip":
        raise SystemExit("Unexpected ISO name in release manifest")
    for file, record in ((exe, release["executable"]), (iso, release["iso"])):
        if not file.is_file() or file.stat().st_size != record["bytes"]:
            raise SystemExit(f"Missing file or incorrect size: {file}")
        actual = sha256(file)
        if actual != record["sha256"]:
            raise SystemExit(f"SHA-256 mismatch for {file.name}: {actual}")
    instructions = (
        f"NOVA OS {release['version']} - USB Kit\r\n"
        "\r\n"
        "Extrage ambele fisiere in acelasi folder. Porneste NOVA Media Creation Tool.exe\r\n"
        "si selecteaza stickul USB corect. Aplicatia gaseste ISO-ul automat, ii\r\n"
        "verifica SHA-256 si cere confirmarea inainte de a sterge stickul.\r\n"
        "Stickul trebuie sa aiba minimum 8 GB. Toate datele de pe stick vor fi sterse.\r\n"
        "Dupa scriere, porneste laptopul de pe USB. In instalator alegi discul si\r\n"
        "partitiile; nu confirma formatarea decat dupa verificarea discului ales.\r\n"
        "\r\n"
        "Preview experimental. Citeste VALIDATION-0.3.md pentru testele efective.\r\n"
        "Suportul HP, Secure Boot, dual-boot si scrierea fizica USB nu sunt certificate.\r\n"
        "Opera GX si Steam pot fi instalate din Discover cu internet. Wine este inclus;\r\n"
        "compatibilitatea executabilelor Windows variaza. Update-ul online 0.3 nu este\r\n"
        "inca publicat; disponibilitatea canalului este afisata in Settings.\r\n"
        "Executabilul Windows nu este semnat digital.\r\n"
    )
    source_archive = PROJECT / "artifacts/NOVA-OS-0.3-Preview-sources.tar"
    extras = {
        RELEASE: RELEASE.name,
        PROJECT / "LICENSE": "LICENSES/NOVA-MIT.txt",
        PROJECT / "NOTICE.md": "NOTICE.md",
        PROJECT / "tools/media/FedoraMediaWriter-5.3.2/LICENSE.GPL-2.txt": "LICENSES/MediaWriter-GPL-2.txt",
        PROJECT / "tools/media/FedoraMediaWriter-5.3.2/LICENSE.LGPL-2.txt": "LICENSES/MediaWriter-LGPL-2.txt",
        PROJECT / "tools/media/media-writer-provenance.json": "provenance/media-writer.json",
        PROJECT / "tools/media/MediaWriter-5.3.2.tar.gz": "sources/MediaWriter-5.3.2.tar.gz",
        PROJECT / "artifacts/kit-0.3-evidence/build-manifest.json": "provenance/build-manifest.json",
        PROJECT / "docs/VALIDATION-0.3.md": "VALIDATION-0.3.md",
        source_archive: "sources/" + source_archive.name,
        source_archive.with_suffix(".tar.sha256"): "sources/" + source_archive.name + ".sha256",
    }
    for name in ("runtime-inspect.json", "live-inspect.json", "packages.txt", "native-tests.log",
                 "nova-live.osbuild-manifest.json", "sources.lock.json", "build-tools-inspect.json",
                 "build-tools-packages.txt", "upstream-0.3.osbuild-manifest.json"):
        extras[PROJECT / "artifacts/kit-0.3-evidence" / name] = "provenance/" + name
    for extra in extras:
        if not extra.is_file():
            raise SystemExit(f"Missing kit documentation/source: {extra}")
    upstream_source = PROJECT / "tools/media/MediaWriter-5.3.2.tar.gz"
    if sha256(upstream_source) != "8a8054893044dd559a696bfbed61da9d979898b55f85904f275f37f57901f415":
        raise SystemExit("Media Writer corresponding-source archive checksum mismatch")
    source_digest = source_archive.with_suffix(".tar.sha256").read_text().split()[0]
    if sha256(source_archive) != source_digest:
        raise SystemExit("NOVA source archive checksum mismatch")
    output.parent.mkdir(exist_ok=True)
    temporary = output.with_suffix(".zip.tmp")
    if temporary.exists():
        temporary.unlink()
    try:
        with zipfile.ZipFile(temporary, "w", compression=zipfile.ZIP_STORED,
                             allowZip64=True) as archive:
            archive.writestr("CITESTE-MA.txt", instructions.encode("utf-8"))
            archive.write(exe, exe.name)
            archive.write(iso, iso.name)
            archive.writestr(iso.name + ".sha256", f"{release['iso']['sha256']}  {iso.name}\n")
            archive.writestr(exe.name + ".sha256", f"{release['executable']['sha256']}  {exe.name}\n")
            for extra, name in extras.items():
                archive.write(extra, name)
            archive.writestr("sources/THIRD-PARTY-SOURCES.txt", (
                "Fedora Media Writer 5.3.2, unchanged portable helper:\n"
                "https://github.com/FedoraQt/MediaWriter/tree/5.3.2\n"
                "https://github.com/FedoraQt/MediaWriter/archive/refs/tags/5.3.2.tar.gz\n"
                "Qt 6.10.2 libraries in the upstream portable package:\n"
                "https://download.qt.io/archive/qt/6.10/6.10.2/submodules/\n"
                "Fedora package source RPMs: https://src.fedoraproject.org/\n"
                "See the bundled operating system's /usr/share/licenses and RPM package metadata.\n"
                "The NOVA MIT license applies to original NOVA sources only.\n"
                "This kit is a local experimental build; it has not been cleared as a public binary release.\n"
            ))
        with zipfile.ZipFile(temporary) as archive:
            if archive.testzip() is not None:
                raise SystemExit("USB kit ZIP integrity check failed")
        temporary.replace(output)
    finally:
        if temporary.exists():
            temporary.unlink()
    digest = sha256(output)
    output.with_suffix(".zip.sha256").write_text(
        f"{digest}  {output.name}\n", encoding="ascii")
    print(f"{output} ({output.stat().st_size} bytes) SHA-256 {digest}")


if __name__ == "__main__":
    main()
