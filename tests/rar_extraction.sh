#!/usr/bin/env bash
set -euo pipefail

tests_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
fixture_dir="$tests_dir/fixtures/rar"
archive="$fixture_dir/testfile.rar5.rar"
expected="$fixture_dir/testfile.txt"

if ! command -v unar >/dev/null 2>&1; then
    echo 'unar is required to test RAR extraction.' >&2
    exit 1
fi

printf '%s  %s\n' \
    'a546b39c1aa42669543ef81f5ec8c4ef49fc7c2e5b8d08ab10549e919996e1a4' "$archive" \
    'b2f51cd17b3cbe77f091f887d91110164a2cb5a5a9ebe828c44d655c83dca8eb' "$expected" \
    | sha256sum --check --status

extract_dir=$(mktemp -d)
trap 'rm -rf -- "$extract_dir"' EXIT

unar -o "$extract_dir" "$archive" >/dev/null
cmp -- "$expected" "$extract_dir/testfile.txt"

echo 'RAR5 extraction passed: testfile.txt matches the expected bytes.'
