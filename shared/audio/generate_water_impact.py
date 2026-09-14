"""Original deterministic splash: impact, spray, then muffled underwater bubbles."""
import math, random, struct, wave
from pathlib import Path
rng = random.Random(1665)
rate = 44100
samples = []
low = 0.0
for i in range(int(rate * 2.8)):
    t = i / rate
    noise = rng.uniform(-1, 1)
    low += (noise - low) * 0.045
    impact = math.sin(2 * math.pi * (72 * t - 9 * t * t)) * math.exp(-t * 10) * 0.48
    spray = noise * (1 - math.exp(-t * 90)) * math.exp(-t * 4.5) * 0.35
    wash = low * math.exp(-t * 0.9) * 1.4
    bubbles = math.sin(2 * math.pi * (190 * t + 65 * t * t)) * max(0, math.sin(t * 22)) ** 12 * math.exp(-t * 1.6) * 0.09
    fade = min(1, (2.8 - t) / 0.4)
    samples.append(struct.pack('<h', int(max(-0.95, min(0.95, impact + spray + wash + bubbles)) * fade * 32767)))
with wave.open(str(Path(__file__).with_name('water_impact.wav')), 'wb') as out:
    out.setparams((1, 2, rate, 0, 'NONE', 'not compressed'))
    out.writeframes(b''.join(samples))
