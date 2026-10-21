#!/usr/bin/env python3
"""Audit unignored worktree files and every reachable Git commit/blob without printing secrets.

This is a scoped publication check, not a proof that software has no vulnerabilities.
Run again after the final commit; unreachable objects and external files are not published.
"""
from __future__ import annotations

import argparse
from collections import defaultdict
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
FORBIDDEN_SUFFIXES = {
    '.iso', '.qcow2', '.oci', '.exe', '.dll', '.rpm', '.deb', '.zip', '.img',
    '.raw', '.vhd', '.vhdx', '.vmdk', '.fd', '.pem', '.key', '.pfx', '.p12', '.pyc',
}
FORBIDDEN_PARTS = {'vendor', 'artifacts', 'build', 'work', '__pycache__', '.venv', '.local'}
FIXTURES = {
    'tests/fixtures/rar/testfile.rar5.rar': 'a546b39c1aa42669543ef81f5ec8c4ef49fc7c2e5b8d08ab10549e919996e1a4',
    'tests/fixtures/rar/testfile.txt': 'b2f51cd17b3cbe77f091f887d91110164a2cb5a5a9ebe828c44d655c83dca8eb',
}
PATTERNS = {
    'private-key': re.compile(rb'-----BEGIN (?:RSA |EC |OPENSSH |DSA |ENCRYPTED )?PRIVATE KEY-----'),
    'github-token': re.compile(rb'\b(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,})\b'),
    'gitlab-token': re.compile(rb'\bglpat-[A-Za-z0-9_-]{20,}\b'),
    'aws-access-key': re.compile(rb'\b(?:AKIA|ASIA)[A-Z0-9]{16}\b'),
    'openai-token': re.compile(rb'\bsk-(?:proj-|svcacct-)?[A-Za-z0-9_-]{40,}\b'),
    'slack-token': re.compile(rb'\bxox[baprs]-[A-Za-z0-9-]{20,}\b'),
    'credential-url': re.compile(rb'https?://[^\s/:@]+:[^\s/@]+@'),
    'literal-secret-assignment': re.compile(
        rb'''(?i)\b(?:password|passwd|api_key|apikey|client_secret|access_token)\s*[:=]\s*["'][^"'\r\n]{8,}["']'''),
    'personal-windows-path': re.compile(rb'(?i)C:[/\\]+Users[/\\]+[A-Za-z0-9_.-]+'),
}


def git(*args: str) -> bytes:
    # Per-command exception for this exact checkout, never global configuration.
    return subprocess.check_output(
        ['git', '-c', f'safe.directory={ROOT.as_posix()}', '-C', str(ROOT), *args])


def audit_file(path: str, data: bytes, scope: str, findings: list) -> None:
    parts = PurePosixPath(path).parts
    filename = PurePosixPath(path).name
    reason = None
    if set(parts) & FORBIDDEN_PARTS or PurePosixPath(path).suffix.lower() in FORBIDDEN_SUFFIXES:
        reason = 'generated-or-private-path'
    if filename in {'.env', 'known_hosts', 'user-data'} or filename.startswith(('id_rsa', 'id_ed25519')):
        reason = 'credential-or-seed-path'
    if path.startswith('tools/media/') and filename not in {'README.md', 'media-writer-provenance.json'}:
        reason = 'vendored-media-binary'
    if len(data) > 1024 * 1024:
        reason = 'file-over-1-MiB-review-required'
    if reason:
        findings.append({'scope': scope, 'path': path, 'rule': reason})
    if path in FIXTURES and hashlib.sha256(data).hexdigest() != FIXTURES[path]:
        findings.append({'scope': scope, 'path': path, 'rule': 'fixture-hash-mismatch'})
    if b'\0' in data:
        if PurePosixPath(path).suffix.lower() not in {'.png', '.rar'}:
            findings.append({'scope': scope, 'path': path, 'rule': 'unreviewed-binary'})
        return
    for rule, pattern in PATTERNS.items():
        for match in pattern.finditer(data):
            findings.append({'scope': scope, 'path': path, 'rule': rule,
                             'line': data.count(b'\n', 0, match.start()) + 1})


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, help='Optional JSON report (use an ignored/private path)')
    args = parser.parse_args()
    findings: list[dict] = []
    paths = sorted(set(filter(None, git('ls-files', '--cached', '--others', '--exclude-standard', '-z').decode().split('\0'))))
    total_bytes = 0
    missing = []
    for path in paths:
        file = ROOT / path
        if not file.is_file():
            missing.append(path)
            continue
        data = file.read_bytes()
        total_bytes += len(data)
        audit_file(path, data, 'worktree', findings)
    commits = git('rev-list', '--all').decode().splitlines()
    objects: dict[str, set[str]] = defaultdict(set)
    for commit in commits:
        for entry in git('ls-tree', '-rz', '-r', commit).split(b'\0'):
            if not entry:
                continue
            metadata, path = entry.split(b'\t', 1)
            mode, kind, oid = metadata.decode().split()
            decoded = path.decode('utf-8', errors='replace')
            if kind != 'blob' or mode == '120000':
                findings.append({'scope': commit, 'path': decoded, 'rule': 'submodule-or-symlink-review'})
            else:
                objects[oid].add(decoded)
        message = git('show', '-s', '--format=%B', commit)
        for rule, pattern in PATTERNS.items():
            if pattern.search(message):
                findings.append({'scope': commit, 'path': '<commit-message>', 'rule': rule})
    identifiers = sorted(objects)
    if identifiers:
        result = subprocess.run(
            ['git', '-c', f'safe.directory={ROOT.as_posix()}', '-C', str(ROOT), 'cat-file', '--batch'],
            input=('\n'.join(identifiers) + '\n').encode(), capture_output=True, check=True).stdout
        offset = 0
        for expected in identifiers:
            end = result.index(b'\n', offset)
            oid, kind, size = result[offset:end].decode().split()
            if oid != expected or kind != 'blob':
                raise RuntimeError('Unexpected Git batch object')
            offset = end + 1
            data = result[offset:offset + int(size)]
            offset += int(size) + 1
            for path in sorted(objects[oid]):
                audit_file(path, data, f'git-blob:{oid}', findings)
    report = {
        'schema': 1, 'status': 'passed' if not findings else 'review-required',
        'worktreeFiles': len(paths) - len(missing), 'worktreeBytes': total_bytes,
        'reachableCommits': commits, 'historicalBlobs': len(objects),
        'missingWorktreePaths': missing, 'findings': findings,
        'scope': 'Unignored worktree and all blobs/messages in every commit reachable from local refs. '
                 'Historical author identities are retained, not classified as secrets. '
                 'No entropy/exploit analysis; no guarantee that all secrets or vulnerabilities are detected.',
    }
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report, indent=2))
    return 0 if not findings else 1


if __name__ == '__main__':
    sys.exit(main())
