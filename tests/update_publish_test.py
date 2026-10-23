#!/usr/bin/env python3
"""Exercise registry promotion guards without uploading or accessing the network."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import shutil

ROOT = Path(__file__).resolve().parents[1]
MOCK = '''#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
args = sys.argv[1:]
name = Path(sys.argv[0]).name
with open(os.environ['NOVA_MOCK_LOG'], 'a') as log:
    log.write(json.dumps([name] + args) + '\\n')
mode = os.environ['NOVA_MOCK_MODE']
if name == 'podman':
    if args[:2] == ['image', 'inspect']:
        print('0.3.0-preview' if mode != 'wrong-label' else '0.2.1-preview')
elif name == 'skopeo':
    if '--authfile' in args:
        if mode == 'private':
            sys.exit(1)
        print('{}')
    elif '--format' in args:
        print('sha256:' + 'a' * 64)
    elif args[0] == 'inspect':
        if mode == 'existing':
            sys.exit(0)
        print('network unavailable' if mode == 'network' else 'manifest unknown', file=sys.stderr)
        sys.exit(1)
'''

class PublicationGuards(unittest.TestCase):
    def run_mode(self, mode):
        with tempfile.TemporaryDirectory(prefix='nova-publish-test-') as temporary:
            directory = Path(temporary)
            script = directory / 'project/scripts/publish-update.sh'
            script.parent.mkdir(parents=True)
            shutil.copyfile(ROOT / 'scripts/publish-update.sh', script)
            for tool in ('podman', 'skopeo'):
                path = directory / tool
                path.write_text(MOCK)
                path.chmod(0o755)
            log = directory / 'calls.jsonl'
            env = dict(os.environ, PATH=str(directory) + os.pathsep + os.environ['PATH'],
                NOVA_VERSION='0.3.0-preview', NOVA_MOCK_MODE=mode, NOVA_MOCK_LOG=str(log), TMPDIR=str(directory))
            result = subprocess.run(['bash', str(script)], env=env, capture_output=True, text=True)
            calls = log.read_text() if log.exists() else ''
            return result.returncode, calls

    def test_existing_version_is_never_overwritten(self):
        code, calls = self.run_mode('existing')
        self.assertEqual(code, 4)
        self.assertNotIn('"push"', calls)

    def test_network_failure_is_not_mistaken_for_unused_tag(self):
        code, calls = self.run_mode('network')
        self.assertEqual(code, 4)
        self.assertNotIn('"push"', calls)

    def test_label_must_match_version(self):
        code, calls = self.run_mode('wrong-label')
        self.assertEqual(code, 3)
        self.assertNotIn('"push"', calls)

    def test_private_package_cannot_promote_channel(self):
        code, calls = self.run_mode('private')
        self.assertEqual(code, 6)
        self.assertIn('"push"', calls)
        self.assertNotIn('"copy"', calls)

    def test_readable_version_promotes_the_exact_digest(self):
        code, calls = self.run_mode('public')
        self.assertEqual(code, 0)
        self.assertIn('"--preserve-digests"', calls)
        self.assertEqual(calls.count('"--authfile"'), 2)
        self.assertIn('nova-os:preview', calls)

if __name__ == '__main__':
    unittest.main()
