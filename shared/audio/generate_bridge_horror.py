"""Original deterministic cues for the fair lady's attack on London Bridge.

bridge_crack.wav: a deep stone groan with splitting cracks while she climbs over the parapet.
lady_lunge.wav: a torn, detuned shriek over a body-blow thump, then rushing air as the player falls.
"""
import math, random, struct, wave
from pathlib import Path

RATE = 44100


def write(name, samples):
    with wave.open(str(Path(__file__).with_name(name)), 'wb') as out:
        out.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        out.writeframes(b''.join(struct.pack('<h', int(max(-0.97, min(0.97, s)) * 32767)) for s in samples))


def crack():
    rng = random.Random(1209)
    length = 4.2
    low = 0.0
    rumble = 0.0
    hits = sorted(rng.uniform(0.1, 3.6) for _ in range(14))
    out = []
    for i in range(int(RATE * length)):
        t = i / RATE
        noise = rng.uniform(-1, 1)
        low += (noise - low) * 0.012
        rumble += (low - rumble) * 0.05
        groan = math.sin(2 * math.pi * (38 + 6 * math.sin(t * 1.3)) * t) * 0.25 + rumble * 6.0
        swell = min(1.0, t / 0.6) * min(1.0, (length - t) / 0.8)
        snap = 0.0
        for hit in hits:
            d = t - hit
            if 0 <= d < 0.18:
                snap += noise * math.exp(-d * 60) * 0.8 + math.sin(2 * math.pi * 140 * d) * math.exp(-d * 30) * 0.4
        out.append((groan * 0.6 + snap) * swell)
    write('bridge_crack.wav', out)


def lunge():
    rng = random.Random(1606)
    length = 2.6
    air = 0.0
    phases = [0.0] * 5
    out = []
    for i in range(int(RATE * length)):
        t = i / RATE
        noise = rng.uniform(-1, 1)
        # The shriek: detuned voices bending up, then collapsing, with a nervous vibrato.
        bend = 820 + 620 * math.sin(min(t, 0.9) / 0.9 * math.pi * 0.8)
        voice = 0.0
        for k in range(5):
            freq = bend * (1 + (k - 2) * 0.013) * (1 + 0.04 * math.sin(2 * math.pi * 11 * t + k))
            phases[k] += freq / RATE
            voice += (2 * (phases[k] % 1.0) - 1) * 0.18
        voice = math.tanh(voice * 3.0) * 0.55 + noise * 0.2
        shriek = voice * min(1.0, t / 0.03) * math.exp(-max(0.0, t - 0.55) * 4.0)
        thump = math.sin(2 * math.pi * (55 * t - 20 * t * t)) * math.exp(-t * 9) * 0.9
        air += (noise - air) * 0.08
        wind = air * min(1.0, max(0.0, t - 0.4) / 0.6) * math.exp(-max(0.0, t - 1.9) * 3.0) * 2.2
        out.append(shriek + thump + wind)
    write('lady_lunge.wav', out)


crack()
lunge()
