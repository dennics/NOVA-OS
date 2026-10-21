# RAR5 extraction fixture

These files are test inputs only. They let NOVA check RAR extraction offline without
requiring WinRAR or creating a RAR archive during the test.

| File | Upstream source | SHA-256 |
| --- | --- | --- |
| `testfile.rar5.rar` | [ssokolow/rar-test-files/build/testfile.rar5.rar](https://github.com/ssokolow/rar-test-files/blob/master/build/testfile.rar5.rar) | `a546b39c1aa42669543ef81f5ec8c4ef49fc7c2e5b8d08ab10549e919996e1a4` |
| `testfile.txt` | [ssokolow/rar-test-files/sources/testfile.txt](https://github.com/ssokolow/rar-test-files/blob/master/sources/testfile.txt) | `b2f51cd17b3cbe77f091f887d91110164a2cb5a5a9ebe828c44d655c83dca8eb` |

The 82-byte RAR5 archive contains one file, `testfile.txt`. The expected file is
12 bytes (`Testing 123` followed by a line feed). The test compares the extracted
bytes with this upstream source file.

The [upstream README](https://github.com/ssokolow/rar-test-files#license)
describes these test archives as redistributable and dedicates the author's
copyrightable contributions to the public domain under
[CC0 1.0](https://github.com/ssokolow/rar-test-files/blob/master/LICENSE.cc0).
No self-extracting executable or WinRAR program is included here.

Run `bash tests/rar_extraction.sh` from the NOVA project directory on a system
with `unar`. This checks the command-line extractor; opening the archive in Ark
remains a separate graphical test.
