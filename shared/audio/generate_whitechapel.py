"""Ambient and scare sounds for the Whitechapel watch: rain, a heartbeat, the Shadow's slow
footsteps, and a whisper. Original synthesis; the whisper uses the macOS Whisper voice.
Standard library only."""
from pathlib import Path
import math
import random
import struct
import subprocess
import tempfile
import wave

ROOT = Path(__file__).parent
RATE = 22050


def save(name, samples, peak_level=0.9):
    peak = max(map(abs, samples)) or 1.0
    with wave.open(str(ROOT / name), 'wb') as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, v * peak_level / peak)) * 32767)) for v in samples))


def rain(seconds=8.0):
    rng = random.Random(1888)
    n = int(seconds * RATE)
    out, low, high = [0.0] * n, 0.0, 0.0
    for i in range(n):
        noise = rng.random() * 2 - 1
        low += (noise - low) * 0.35
        high = noise - low
        out[i] = low * 0.35 + high * 0.12
    for drop in range(int(seconds * 60)):
        start = rng.randrange(n)
        hz = rng.uniform(1800, 4200)
        for k in range(int(0.018 * RATE)):
            t = k / RATE
            out[(start + k) % n] += math.sin(math.tau * hz * t) * math.exp(-t * 260) * rng.uniform(0.05, 0.25)
    return out


def heartbeat():
    n = int(1.0 * RATE)
    out = [0.0] * n
    for start, gain in ((0.0, 1.0), (0.26, 0.7)):
        phase = 0.0
        for k in range(int(0.18 * RATE)):
            t = k / RATE
            phase += math.tau * (38 + 30 * math.exp(-t * 30)) / RATE
            out[int(start * RATE) + k] += math.sin(phase) * math.exp(-t * 22) * gain
    return out


def footsteps():
    rng = random.Random(7)
    n = int(1.6 * RATE)
    out = [0.0] * n
    for start in (0.05, 0.85):
        previous = 0.0
        for k in range(int(0.25 * RATE)):
            t = k / RATE
            noise = rng.random() * 2 - 1
            click = (noise - previous) * math.exp(-t * 90)
            previous = noise
            thud = math.sin(math.tau * 120 * t) * math.exp(-t * 35) * 0.6
            out[int(start * RATE) + k] += click + thud
    # Stone echo off the tenement walls.
    for delay, gain in ((0.09, 0.35), (0.21, 0.18)):
        d = int(delay * RATE)
        for i in range(n - 1, d - 1, -1):
            out[i] += out[i - d] * gain
    return out


def whisper():
    with tempfile.TemporaryDirectory() as folder:
        path = Path(folder) / 'w.wav'
        subprocess.run(['say', '-v', 'Whisper', '-r', '120', '-o', str(path), '--file-format=WAVE',
                        '--data-format=LEI16@%d' % RATE, 'I see you. [[slnc 300]] Keep walking.'], check=True)
        with wave.open(str(path)) as source:
            raw = source.readframes(source.getnframes())
    dry = [v / 32768 for v in struct.unpack('<%dh' % (len(raw) // 2), raw)]
    out = dry + [0.0] * int(RATE * 0.8)
    for delay, gain in ((0.061, 0.5), (0.113, 0.35), (0.197, 0.25), (0.311, 0.15)):
        d = int(delay * RATE)
        for i, value in enumerate(dry):
            out[i + d] += value * gain
    return out


if __name__ == '__main__':
    save('whitechapel_rain.wav', rain(), 0.6)
    save('heartbeat.wav', heartbeat())
    save('shadow_steps.wav', footsteps(), 0.8)
    save('shadow_whisper.wav', whisper())
    print('done')
