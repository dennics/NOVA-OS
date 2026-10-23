#!/usr/bin/python3
"""Generate NOVA's original, deterministic short notification tones (MIT)."""
import math
from pathlib import Path
import struct
import sys
import wave

TONES = {
    'desktop-login': [523.25, 659.25, 783.99, 1046.50],
    'desktop-logout': [783.99, 659.25, 523.25],
    'device-added': [659.25, 987.77],
    'device-removed': [987.77, 659.25],
    'message-new-instant': [880.00, 1174.66],
    'dialog-information': [659.25, 783.99],
    'dialog-warning': [440.00, 415.30],
    'dialog-error': [329.63, 293.66],
    'dialog-error-serious': [329.63, 293.66, 261.63],
    'dialog-error-critical': [329.63, 293.66, 261.63],
    'dialog-question': [587.33, 783.99],
    'trash-empty': [783.99, 523.25],
    'complete': [659.25, 783.99, 1046.50],
    'theme-demo': [523.25, 659.25, 783.99, 1046.50],
}

def generate(destination: Path):
    destination.mkdir(parents=True, exist_ok=True)
    rate = 44100
    for name, notes in TONES.items():
        frames = bytearray()
        duration = 0.17 if name != 'desktop-login' else 0.22
        samples = int(rate * (len(notes) * duration + 0.2))
        for index in range(samples):
            time = index / rate
            value = 0.0
            for step, frequency in enumerate(notes):
                age = time - step * duration
                if 0 <= age < duration + 0.2:
                    attack = min(1.0, age / 0.012)
                    release = max(0.0, 1 - age / (duration + 0.2)) ** 2
                    value += 0.085 * attack * release * (math.sin(math.tau * frequency * age)
                        + 0.16 * math.sin(math.tau * frequency * 2 * age))
            sample = round(max(-0.3, min(0.3, value)) * 32767)
            frames.extend(struct.pack('<hh', sample, sample))
        with wave.open(str(destination / (name + '.wav')), 'wb') as output:
            output.setparams((2, 2, rate, 0, 'NONE', 'not compressed'))
            output.writeframes(frames)
    print(f'NOVA sounds: generated {len(TONES)} original stereo cues')

if __name__ == '__main__':
    generate(Path(sys.argv[1]))
