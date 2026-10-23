#!/usr/bin/env python3
"""Reproduce the Steam first-install regression without installing applications."""
import configparser
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
STEAM = "com.valvesoftware.Steam"
OPERA = "com.opera.opera-gx"
MOCK = r'''#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
name = Path(sys.argv[0]).name
args = sys.argv[1:]
with open(os.environ["NOVA_STORE_TEST_LOG"], "a") as log:
    log.write(json.dumps([name] + args) + "\n")
if name == "flatpak" and args[0] == "info":
    installed = os.environ.get("NOVA_STORE_TEST_INSTALLED", "").split(",")
    sys.exit(0 if args[1] in installed else 1)
'''


class StoreLauncher(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="nova store test ")
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        self.prefix = self.directory / "local prefix"
        self.bin = self.prefix / "bin"
        self.bin.mkdir(parents=True)
        self.script = self.bin / "nova-launch-store-app"
        shutil.copyfile(ROOT / "system/usr/bin/nova-launch-store-app", self.script)
        self.script.chmod(0o755)
        self.store = self.prefix / "share/nova/store"
        shutil.copytree(ROOT / "system/usr/share/nova/store", self.store)
        for name in ("flatpak", "plasma-discover", "kdialog"):
            tool = self.bin / name
            tool.write_text(MOCK)
            tool.chmod(0o755)
        self.log = self.directory / "calls.jsonl"

    def launch(self, app_id, *arguments, installed=""):
        env = dict(os.environ, PATH=str(self.bin) + os.pathsep + os.environ["PATH"],
                   NOVA_STORE_TEST_LOG=str(self.log), NOVA_STORE_TEST_INSTALLED=installed)
        result = subprocess.run([str(self.script), app_id, *arguments], env=env,
                                capture_output=True, text=True, timeout=10)
        calls = [json.loads(line) for line in self.log.read_text().splitlines()] if self.log.exists() else []
        return result, calls

    def test_first_install_uses_exact_case_local_reference_without_catalog(self):
        for app_id in (STEAM, OPERA):
            with self.subTest(app_id=app_id):
                result, calls = self.launch(app_id)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(calls[-1], ["plasma-discover", "--local-filename",
                                            str(self.store / (app_id + ".flatpakref"))])
                self.assertNotIn("appstream://", str(calls))

    def test_installed_user_app_preserves_arguments_and_precedes_system(self):
        arguments = ("steam://run/123", "literal space; $(nothing)")
        result, calls = self.launch(STEAM, *arguments, installed="--user,--system")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, [["flatpak", "info", "--user", STEAM],
                                 ["flatpak", "run", "--user", STEAM, *arguments]])

    def test_installed_system_app_does_not_open_installer(self):
        result, calls = self.launch(STEAM, installed="--system")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls[-1], ["flatpak", "run", "--system", STEAM])
        self.assertNotIn("plasma-discover", str(calls))

    def test_unknown_app_is_rejected_before_any_command(self):
        result, calls = self.launch("../../untrusted")
        self.assertEqual(result.returncode, 64)
        self.assertEqual(calls, [])

    def test_missing_reference_has_visible_error_instead_of_empty_store(self):
        (self.store / (STEAM + ".flatpakref")).unlink()
        result, calls = self.launch(STEAM)
        self.assertEqual(result.returncode, 1)
        self.assertIn("missing", result.stderr)
        self.assertEqual(calls[-1][:4], ["kdialog", "--title", "NOVA Applications", "--error"])
        self.assertNotIn("plasma-discover", str(calls))

    def test_references_use_exact_app_ids_and_signed_https_repository(self):
        for app_id in (STEAM, OPERA):
            parser = configparser.ConfigParser(interpolation=None)
            parser.read(self.store / (app_id + ".flatpakref"))
            reference = parser["Flatpak Ref"]
            self.assertEqual(reference["Name"], app_id)
            self.assertEqual(reference["Url"], "https://dl.flathub.org/repo/")
            self.assertEqual(reference["RuntimeRepo"], "https://dl.flathub.org/repo/flathub.flatpakrepo")
            self.assertTrue(reference["GPGKey"])
            self.assertEqual(reference["IsRuntime"], "false")


if __name__ == "__main__":
    unittest.main()
