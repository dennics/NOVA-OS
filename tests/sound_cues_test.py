#!/usr/bin/env python3
"""Validate original generated sound artifacts without using an audio device."""
from pathlib import Path
import runpy
import struct
import tempfile
import unittest
import wave

ROOT = Path(__file__).resolve().parents[1]

class OriginalCues(unittest.TestCase):
    def test_stereo_short_nonclipping_and_reproducible(self):
        generator = runpy.run_path(str(ROOT / 'system/usr/libexec/nova-image/generate-sounds.py'))
        with tempfile.TemporaryDirectory(prefix='nova-sounds-test-') as temporary:
            first, second = Path(temporary) / 'first', Path(temporary) / 'second'
            generator['generate'](first)
            generator['generate'](second)
            self.assertEqual(len(list(first.glob('*.wav'))), 14)
            for file in first.glob('*.wav'):
                self.assertEqual(file.read_bytes(), (second / file.name).read_bytes())
                with wave.open(str(file), 'rb') as sound:
                    self.assertEqual(sound.getnchannels(), 2)
                    self.assertEqual(sound.getsampwidth(), 2)
                    self.assertEqual(sound.getframerate(), 44100)
                    self.assertLessEqual(sound.getnframes() / sound.getframerate(), 1.2)
                    samples = struct.iter_unpack('<h', sound.readframes(sound.getnframes()))
                    peak = max(abs(value[0]) for value in samples)
                    self.assertGreater(peak, 500)
                    self.assertLess(peak, 10000)

if __name__ == '__main__':
    unittest.main()
