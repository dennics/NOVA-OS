#!/usr/bin/python3
"""Render an original orbit loop into Plymouth's native two-step throbber frames."""
import math
from pathlib import Path
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

def render(directory: Path, mark: Path):
    # Retain the distribution's frame count, timing, progress and authentication UI.
    frames = sorted(directory.glob('throbber-*.png'))
    if not frames:
        raise SystemExit('Distribution two-step throbber assets are missing')
    logo = ET.parse(mark).getroot()
    logo.attrib.update(x='90', y='90', width='76', height='76')
    logo_svg = ET.tostring(logo, encoding='unicode')
    with tempfile.TemporaryDirectory(prefix='nova-boot-', dir='/tmp') as work:
        svg = Path(work) / 'frame.svg'
        for number, frame in enumerate(frames):
            phase = math.tau * number / len(frames)
            particles = []
            for radius, direction, color in ((84, 1, '#57c7ff'), (67, -1, '#9775ff')):
                for trail in range(22):
                    angle = direction * phase - direction * trail * 0.045
                    x, y = 128 + radius * math.cos(angle), 128 + radius * math.sin(angle)
                    particles.append(f'<circle cx="{x:.3f}" cy="{y:.3f}" r="{3.0 - trail * 0.07:.2f}" fill="{color}" opacity="{(1 - trail / 24) ** 2:.3f}"/>')
            svg.write_text('<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">'
                '<circle cx="128" cy="128" r="84" fill="none" stroke="#57c7ff" stroke-opacity=".13"/>'
                '<circle cx="128" cy="128" r="67" fill="none" stroke="#9775ff" stroke-opacity=".16"/>'
                + ''.join(particles) + logo_svg + '</svg>')
            subprocess.run(['magick', '-background', 'none', str(svg), 'PNG32:' + str(frame)], check=True)
    print(f'NOVA Plymouth: {len(frames)} orbit frames; native progress and password dialogs retained')

if __name__ == '__main__':
    render(Path(sys.argv[1]), Path(sys.argv[2]))
