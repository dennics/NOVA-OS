"""Regression checks for additive publication helpers; no network or disk formatting."""
import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import io

ROOT = Path(__file__).resolve().parents[1]


def load(name, filename):
    spec = importlib.util.spec_from_file_location(name, ROOT / 'scripts' / filename)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


audit = load('nova_audit', 'audit-publication.py')
fetch = load('nova_fetch', 'fetch-dependency.py')


class PublicationTests(unittest.TestCase):
    def test_secret_report_omits_value(self):
        token = b'gh' + b'p_' + b'a' * 36
        findings = []
        audit.audit_file('example.txt', token, 'fixture', findings)
        self.assertEqual(findings[0]['rule'], 'github-token')
        self.assertNotIn(token.decode(), repr(findings))

    def test_binary_and_private_paths_are_refused(self):
        findings = []
        audit.audit_file('vendor/payload.rpm', b'\0binary', 'fixture', findings)
        audit.audit_file('keys/id_ed25519', b'sample', 'fixture', findings)
        self.assertIn('generated-or-private-path', {f['rule'] for f in findings})
        self.assertIn('credential-or-seed-path', {f['rule'] for f in findings})

    def test_bad_download_never_installs_and_cleans_temporary(self):
        response = io.BytesIO(b'wrong payload')
        response.geturl = lambda: 'https://example.invalid/input'
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / 'input.zip'
            with patch.object(fetch.urllib.request, 'urlopen', return_value=response):
                with self.assertRaises(SystemExit):
                    fetch.retrieve('https://example.invalid/input', target, '0' * 64, 100)
            self.assertFalse(target.exists())
            self.assertEqual(list(target.parent.iterdir()), [])

    def test_existing_unverified_input_is_preserved(self):
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / 'input.zip'
            target.write_bytes(b'keep')
            with self.assertRaises(SystemExit):
                fetch.retrieve('https://example.invalid/input', target, '0' * 64, 100)
            self.assertEqual(target.read_bytes(), b'keep')


if __name__ == '__main__':
    unittest.main()
