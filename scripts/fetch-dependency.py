#!/usr/bin/env python3
"""Explicitly retrieve a pinned external build input; never execute or extract it."""
from __future__ import annotations

import argparse
import hashlib
import os
from pathlib import Path
import tempfile
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
INPUTS = {
    'media-writer': (
        'https://github.com/FedoraQt/MediaWriter/releases/download/5.3.2/FedoraMediaWriter-win64-portable-5.3.2.zip',
        '1043a01b5bfc4b0a79b4f431696eeaeb18c605f38579009877aada3a836904da',
        'tools/media/FedoraMediaWriter-win64-portable-5.3.2.zip'),
    'opera-gx': (
        'https://get.opera.com/pub/opera_gx/137.0.6036.65/linux/opera-gx-stable_137.0.6036.65_amd64.rpm',
        'b911fb526d872e59ca8a3bf92e6e77fcf16a42a042b53f23f5abf97f74ebfd52',
        'vendor/opera-gx-stable_137.0.6036.65_amd64.rpm'),
}


def retrieve(url: str, target: Path, expected: str | None, limit: int) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        if expected and hashlib.sha256(target.read_bytes()).hexdigest() == expected:
            print(f'Already verified: {target.relative_to(ROOT)}')
            return
        raise SystemExit(f'Refusing to overwrite existing unverified input: {target.name}')
    fd, temporary = tempfile.mkstemp(prefix='.nova-input-', dir=target.parent)
    try:
        digest, count = hashlib.sha256(), 0
        request = urllib.request.Request(url, headers={'User-Agent': 'NOVA-source-input-fetcher/1'})
        with os.fdopen(fd, 'wb') as output, urllib.request.urlopen(request, timeout=60) as response:
            if not response.geturl().startswith('https://'):
                raise SystemExit('Refusing a non-HTTPS redirect')
            while chunk := response.read(1024 * 1024):
                count += len(chunk)
                if count > limit:
                    raise SystemExit('Input exceeds download size limit')
                digest.update(chunk)
                output.write(chunk)
        if expected and digest.hexdigest() != expected:
            raise SystemExit('Input hash mismatch; nothing installed')
        # Link only if absent; a concurrent fetch must never be overwritten.
        os.link(temporary, target)
        print(f'Retrieved {target.relative_to(ROOT)}: SHA-256 {digest.hexdigest()}')
    finally:
        Path(temporary).unlink(missing_ok=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('input', choices=INPUTS)
    parser.add_argument('--accept-opera-eula', action='store_true')
    args = parser.parse_args()
    if args.input == 'opera-gx' and not args.accept_opera_eula:
        parser.error('Review https://www.opera.com/legal/eula-computers first; local use requires --accept-opera-eula. '
                     'This does not grant NOVA ISO redistribution permission.')
    url, digest, relative = INPUTS[args.input]
    retrieve(url, ROOT / relative, digest, 256 * 1024 * 1024)
    if args.input == 'opera-gx':
        retrieve('https://www.opera.com/legal/eula-computers', ROOT / 'vendor/opera-eula-computers.html',
                 None, 4 * 1024 * 1024)


if __name__ == '__main__':
    main()
