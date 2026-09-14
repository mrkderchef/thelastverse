"""Reproduce the prototype music loops and mechanism tones.

The music is "London Bridge Is Falling Down" (traditional nursery rhyme; melody and
lyrics are public domain). While London is still whole it plays as a bright children's
song in major (london_bridge_bright_0: glockenspiel melody only; _1: sung with bass and
claps). The witches sing it in the market square (witches_chant.wav) and the immured fair
lady sings it as the bridge falls (fair_lady.wav; `python3 generate_audio.py sung`).
After the bridge falls it returns in natural minor as five escalating loops:

    0  broken music box, very slow, no voice
    1  slowed, sung verse over a drone
    2  near tempo, heartbeat enters
    3  faster, drums and distortion
    4  frantic, everything at once

Every loop is rendered at one base tempo and then resampled as a whole, so slower
stages are also lower and faster stages higher, like slowed / sped-up edits.

Instruments are additive synthesis. Vocals are single words spoken by the macOS `say`
command, stretched to the note lengths and forced onto the melody with a channel
vocoder, so regenerating requires macOS. Standard library only; runs in a few minutes.
"""
from pathlib import Path
import math
import random
import struct
import subprocess
import tempfile
import wave

ROOT = Path(__file__).parent
RATE = 22050
BEAT = 60 / 100
TONIC = 293.66  # D4 at base speed
MINOR = {1: 0, 2: 2, 3: 3, 4: 5, 5: 7, 6: 8}
MAJOR = {1: 0, 2: 2, 3: 4, 4: 5, 5: 7, 6: 9}
VOICE = 'Daniel'
WHISPER = 'Whisper'

# Melody rhythm of one verse as (scale degree, beats).
LINE_A = [(5, 1.5), (6, .5), (5, 1), (4, 1), (3, 1), (4, 1), (5, 2)]
LINE_B = [(2, 1), (3, 1), (4, 2)]
LINE_C = [(3, 1), (4, 1), (5, 2)]
LINE_D = [(2, 2), (5, 2), (3, 1), (1, 3)]
# Lyrics as (word, syllables) for line A, the refrain word group, and the ending.
VERSES = {
    'falling': ([('London', 2), ('Bridge', 1), ('is', 1), ('falling', 2), ('down', 1)],
                [('falling', 2), ('down', 1)]),
    'lock': ([('Take', 1), ('the', 1), ('key', 1), ('and', 1), ('lock', 1), ('her', 1), ('up', 1)],
             [('lock', 1), ('her', 1), ('up', 1)]),
    'watch': ([('Set', 1), ('a', 1), ('man', 1), ('to', 1), ('watch', 1), ('all', 1), ('night', 1)],
              [('watch', 1), ('all', 1), ('night', 1)]),
}
ENDING = [('my', 1), ('fair', 1), ('lady', 2)]
# Harmony roots per 4-beat bar: i i v i i i v i (D minor / A minor).
BARS = [0, 0, 7, 0, 0, 0, 7, 0]


def freq(degree, octave=0, scale=MINOR):
    return TONIC * 2 ** ((scale[degree] + 12 * octave) / 12)


def verse_notes():
    """Return [(start_beat, degree, beats)] for one 32-beat verse."""
    notes, beat = [], 0.0
    for line in (LINE_A, LINE_B, LINE_C, LINE_A, LINE_D):
        for degree, length in line:
            notes.append((beat, degree, length))
            beat += length
    return notes


def verse_words(name, scale=MINOR):
    """Group verse notes into sung words: [(word, start_beat, [(hz, beats), ...])]."""
    line_a, refrain = VERSES[name]
    words = line_a + refrain + refrain + line_a + ENDING
    notes = verse_notes()
    result, index = [], 0
    for word, syllables in words:
        group = notes[index:index + syllables]
        index += syllables
        pitches = [(freq(degree, 0, scale) / 2, beats) for _, degree, beats in group]
        result.append((word, group[0][0], pitches))
    return result


# --- signal helpers ---------------------------------------------------------------

def speak(text, voice, cache={}):
    key = (text, voice)
    if key not in cache:
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'word.wav'
            subprocess.run(['say', '-v', voice, '-o', str(path), '--file-format=WAVE',
                            '--data-format=LEI16@%d' % RATE, text], check=True)
            with wave.open(str(path)) as source:
                raw = source.readframes(source.getnframes())
        samples = [v / 32768 for v in struct.unpack('<%dh' % (len(raw) // 2), raw)]
        peak = max(map(abs, samples)) or 1.0
        loud = [i for i, v in enumerate(samples) if abs(v) > peak * 0.04]
        start, end = max(0, loud[0] - 200), min(len(samples), loud[-1] + 400)
        cache[key] = [v / peak for v in samples[start:end]]
    return cache[key]


def stretch(samples, length):
    """Overlap-add time stretch; phasey, which suits a vocoder modulator."""
    grain, hop = 1024, 256
    window = [0.5 - 0.5 * math.cos(math.tau * i / grain) for i in range(grain)]
    source = samples + [0.0] * grain
    out = [0.0] * (length + grain)
    ratio = max(0, len(samples) - grain) / max(1, length - grain)
    for position in range(0, length, hop):
        offset = min(int(position * ratio), len(samples))
        for i in range(grain):
            out[position + i] += source[offset + i] * window[i] * 0.5
    return out[:length]


def bandpass(center, q):
    w = math.tau * center / RATE
    alpha = math.sin(w) / (2 * q)
    a0 = 1 + alpha
    return (alpha / a0, -alpha / a0, -2 * math.cos(w) / a0, (1 - alpha) / a0)


def vocode(modulator, pitches):
    """Channel vocoder: speech envelope imposed on a sawtooth that follows the melody."""
    length = len(modulator)
    total = sum(b for _, b in pitches)
    carrier, phase, hz = [0.0] * length, 0.0, pitches[0][0]
    rng = random.Random(len(modulator))
    boundaries, acc = [], 0.0
    for target, beats in pitches:
        acc += beats
        boundaries.append((acc / total * length, target))
    note = 0
    for n in range(length):
        while n > boundaries[note][0] and note < len(boundaries) - 1:
            note += 1
        hz += (boundaries[note][1] - hz) * 0.004  # short glide between syllables
        t = n / RATE
        vibrato = 1 + 0.012 * math.sin(math.tau * 5.2 * t) * min(t / 0.4, 1)
        phase = (phase + hz * vibrato / RATE) % 1.0
        carrier[n] = (2 * phase - 1) * 0.8 + (rng.random() * 2 - 1) * 0.08
    out = [0.0] * length
    bands = 18
    follow = 1 - math.exp(-1 / (0.012 * RATE))
    for band in range(bands):
        center = 110 * (6500 / 110) ** (band / (bands - 1))
        b0, b2, a1, a2 = bandpass(center, 5.0)
        mx1 = mx2 = my1 = my2 = cx1 = cx2 = cy1 = cy2 = env = 0.0
        for n in range(length):
            x = modulator[n]
            y = b0 * x + b2 * mx2 - a1 * my1 - a2 * my2
            mx2, mx1, my2, my1 = mx1, x, my1, y
            env += (abs(y) - env) * follow
            x = carrier[n]
            z = b0 * x + b2 * cx2 - a1 * cy1 - a2 * cy2
            cx2, cx1, cy2, cy1 = cx1, x, cy1, z
            out[n] += z * env * 6.0
    # Consonants survive through a little high-passed speech.
    previous = 0.0
    for n in range(length):
        x = modulator[n]
        out[n] += (x - previous) * 0.35
        previous = x
    return out


def mix_into(buffer, start, samples, gain):
    size = len(buffer)
    for i, value in enumerate(samples):
        buffer[(start + i) % size] += value * gain


def music_box(buffer, start, hz, gain, rng, detune=14):
    hz *= 2 ** (rng.uniform(-detune, detune) / 1200)  # worn, slightly out-of-tune comb
    length = int(2.6 * RATE)
    size = len(buffer)
    w1, w2, w3 = math.tau * hz / RATE, math.tau * hz * 1.004 / RATE, math.tau * hz * 5.4 / RATE
    for n in range(length):
        t = n / RATE
        env = min(t / 0.003, 1.0) * math.exp(-t * 2.4)
        tone = math.sin(w1 * n) + 0.5 * math.sin(w2 * n) + 0.3 * math.sin(w3 * n) * math.exp(-t * 11)
        buffer[(start + n) % size] += tone * env * gain


def kick(buffer, start, gain):
    size, phase = len(buffer), 0.0
    for n in range(int(0.35 * RATE)):
        t = n / RATE
        phase += math.tau * (45 + 70 * math.exp(-t * 28)) / RATE
        buffer[(start + n) % size] += math.sin(phase) * math.exp(-t * 11) * gain


def hit(buffer, start, gain, rng, decay=18.0, metal=False):
    size, previous = len(buffer), 0.0
    for n in range(int(0.5 * RATE)):
        t = n / RATE
        noise = rng.random() * 2 - 1
        value = noise - previous
        previous = noise
        if metal:
            value = sum(math.sin(math.tau * 310 * r * t) for r in (1, 2.37, 3.93, 5.4)) * 0.3 + value * 0.3
        buffer[(start + n) % size] += value * math.exp(-t * decay) * gain


def pluck(buffer, start, hz, gain):
    size = len(buffer)
    for n in range(int(0.45 * RATE)):
        t = n / RATE
        tone = math.sin(math.tau * hz * t) + 0.35 * math.sin(math.tau * hz * 2 * t) * math.exp(-t * 9)
        buffer[(start + n) % size] += tone * math.exp(-t * 7) * min(t / 0.004, 1.0) * gain


def pad(buffer, start_beat, root_semitones, beats, gain, lowest=0.25, third=3):
    size = len(buffer)
    start, length = int(start_beat * BEAT * RATE), int(beats * BEAT * RATE)
    base = TONIC * lowest * 2 ** (root_semitones / 12)
    ratios = [1, 2 ** (third / 12), 2 ** (7 / 12), 2]
    for n in range(length):
        t = n / RATE
        env = min(t / 0.3, 1.0) * min((length - n) / RATE / 0.3, 1.0)
        tone = sum(math.sin(math.tau * base * r * t) + 0.3 * math.sin(math.tau * base * r * 2.003 * t) for r in ratios)
        buffer[(start + n) % size] += tone * env * gain


def drone_and_wind(buffer, gain, wind, rng):
    size = len(buffer)
    seconds = size / RATE
    low = round(TONIC / 8 * seconds) / seconds
    beat_lfo = round(0.13 * seconds) / seconds
    state = 0.0
    for n in range(size):
        t = n / RATE
        swell = 0.6 + 0.4 * math.sin(math.tau * beat_lfo * t)
        tone = math.sin(math.tau * low * t) + 0.5 * math.sin(math.tau * low * 1.5 * t) + 0.2 * math.sin(math.tau * low * 2.01 * t)
        state += ((rng.random() * 2 - 1) - state) * 0.02
        buffer[n] += tone * swell * gain + state * wind * (0.5 + 0.5 * math.sin(math.tau * beat_lfo * 2 * t + 1))


def reverb(buffer, wet):
    """Schroeder reverb run twice over the loop so the tail wraps seamlessly."""
    size = len(buffer)
    combs = [[0.0] * d for d in (1116, 1188, 1277, 1356)]
    comb_pos = [0, 0, 0, 0]
    allpasses = [[0.0] * d for d in (556, 441)]
    all_pos = [0, 0]
    out = [0.0] * size
    for loop in range(2):
        for n in range(size):
            x = buffer[n]
            acc = 0.0
            for c in range(4):
                line, p = combs[c], comb_pos[c]
                y = line[p]
                line[p] = x + y * 0.84
                comb_pos[c] = (p + 1) % len(line)
                acc += y
            y = acc * 0.25
            for a in range(2):
                line, p = allpasses[a], all_pos[a]
                delayed = line[p]
                line[p] = y + delayed * 0.5
                all_pos[a] = (p + 1) % len(line)
                y = delayed - y * 0.5
            if loop:
                out[n] = x + y * wet
    return out


def resample(buffer, speed):
    size = len(buffer)
    length = round(size / speed)
    out = [0.0] * length
    for i in range(length):
        position = i * size / length
        index = int(position)
        frac = position - index
        out[i] = buffer[index] * (1 - frac) + buffer[(index + 1) % size] * frac
    return out


# --- arrangement -----------------------------------------------------------------

STAGES = [
    # speed, sung verses (None = instrumental), drone, heartbeat, drums, drive, reverb
    dict(speed=.62, verses=[None, None], box=.30, drone=0.0, wind=.05, heart=0, drums=0, drive=1.0, wet=.55),
    dict(speed=.72, verses=['falling', None], box=.16, drone=.10, wind=.06, heart=0, drums=0, drive=1.0, wet=.50),
    dict(speed=.95, verses=['falling', 'lock'], box=.14, drone=.12, wind=.05, heart=1, drums=0, drive=1.3, wet=.40),
    dict(speed=1.22, verses=['lock', 'watch'], box=.13, drone=.13, wind=.04, heart=1, drums=1, drive=2.0, wet=.32),
    dict(speed=1.55, verses=['watch', 'falling'], box=.12, drone=.14, wind=.03, heart=1, drums=2, drive=3.2, wet=.25),
]


def render_stage(index, config):
    rng = random.Random(1606 + index)
    verse_beats = 32
    buffer = [0.0] * int(verse_beats * len(config['verses']) * BEAT * RATE)
    if config['drone'] or config['wind']:
        drone_and_wind(buffer, config['drone'], config['wind'], rng)
    for number, sung in enumerate(config['verses']):
        offset = number * verse_beats
        for note, (beat, degree, beats) in enumerate(verse_notes()):
            # The very first loop drops notes like a worn cylinder.
            if index == 0 and number == 1 and note % 3 == 1:
                continue
            music_box(buffer, int((offset + beat) * BEAT * RATE), freq(degree, 1), config['box'], rng)
        if index >= 2:
            for bar, root in enumerate(BARS):
                pad(buffer, offset + bar * 4, root, 4, 0.018 + 0.006 * index)
        if sung:
            for word, beat, pitches in verse_words(sung):
                length = int(sum(b for _, b in pitches) * BEAT * RATE * 0.94)
                voiced = vocode(stretch(speak(word, VOICE), length), pitches)
                breath = stretch(speak(word, WHISPER), length)
                start = int((offset + beat) * BEAT * RATE)
                mix_into(buffer, start, voiced, 0.22)
                mix_into(buffer, start, breath, 0.10 + 0.04 * index)
        for beat in range(verse_beats):
            start = int((offset + beat) * BEAT * RATE)
            if config['heart'] and beat % 2 == 0:
                kick(buffer, start, 0.35)
                kick(buffer, start + int(0.22 * RATE), 0.22)
            if config['drums'] >= 1 and beat % 4 == 3:
                hit(buffer, start, 0.10, rng, decay=7.0, metal=True)
            if config['drums'] >= 1 and beat % 2 == 1:
                hit(buffer, start, 0.22, rng)
            if config['drums'] >= 2:
                kick(buffer, start, 0.5)
                hit(buffer, start + int(BEAT * RATE / 2), 0.05, rng, decay=60.0)
                root = BARS[beat // 4]
                pad(buffer, offset + beat, root, 0.45, 0.05, lowest=0.125)
    print('  stage %d: mixing' % index, flush=True)
    buffer = resample(reverb(buffer, config['wet']), config['speed'])
    drive = config['drive']
    if drive > 1:
        buffer = [math.tanh(v * drive) / math.tanh(drive) for v in buffer]
    if index == 4:
        buffer = [round(v * 48) / 48 for v in buffer]  # a little bit crush
    peak = max(map(abs, buffer)) or 1.0
    level = (.55, .70, .78, .82, .86)[index] / peak
    return [v * level for v in buffer]


def render_bright(index):
    """A cheerful nursery rhyme in major: 0 glockenspiel melody, 1 sung with bass and claps."""
    rng = random.Random(1590 + index)
    verses = [None, None] if index == 0 else ['falling', 'lock']
    buffer = [0.0] * int(32 * len(verses) * BEAT * RATE)
    for number, sung in enumerate(verses):
        offset = number * 32
        for beat, degree, beats in verse_notes():
            start = int((offset + beat) * BEAT * RATE)
            music_box(buffer, start, freq(degree, 1, MAJOR), 0.24 if index == 0 else 0.11, rng, detune=2)
            if index == 1:
                music_box(buffer, start, freq(degree, 2, MAJOR), 0.04, rng, detune=1)
        for bar, root in enumerate(BARS):
            bar_start = offset + bar * 4
            if index == 0:
                pluck(buffer, int(bar_start * BEAT * RATE), TONIC / 2 * 2 ** (root / 12), 0.08)
                continue
            pad(buffer, bar_start, root, 4, 0.01, third=4)
            for step in range(4):
                beat_start = int((bar_start + step) * BEAT * RATE)
                hz = TONIC / 4 * 2 ** ((root + (0 if step % 2 == 0 else 7)) / 12)
                pluck(buffer, beat_start, hz, 0.2 if step % 2 == 0 else 0.13)
                if step % 2 == 1:
                    hit(buffer, beat_start, 0.08, rng, decay=45.0)
        if sung:
            for word, beat, pitches in verse_words(sung, MAJOR):
                length = int(sum(b for _, b in pitches) * BEAT * RATE * 0.9)
                voiced = vocode(stretch(speak(word, VOICE), length), pitches)
                start = int((offset + beat) * BEAT * RATE)
                mix_into(buffer, start, voiced, 0.26)
                mix_into(buffer, start, stretch(speak(word, VOICE), length), 0.05)
    print('  bright %d: mixing' % index, flush=True)
    buffer = resample(reverb(buffer, 0.16), 1.0 if index == 0 else 1.12)
    peak = max(map(abs, buffer)) or 1.0
    level = (0.6, 0.78)[index] / peak
    return [v * level for v in buffer]


def render_sung(verses, voice, octave, gain, dry, whisper, speed, box, loop_tail):
    """Clearly sung verses over a slow music box: the witches' chant and the fair lady's song."""
    rng = random.Random(len(voice) + int(speed * 100))
    buffer = [0.0] * int((32 * len(verses) + loop_tail) * BEAT * RATE)
    for number, sung in enumerate(verses):
        offset = number * 32
        for beat, degree, beats in verse_notes():
            music_box(buffer, int((offset + beat) * BEAT * RATE), freq(degree, 1), box, rng, detune=6)
        for word, beat, pitches in verse_words(sung):
            length = int(sum(b for _, b in pitches) * BEAT * RATE * 0.95)
            start = int((offset + beat) * BEAT * RATE)
            spoken = stretch(speak(word, voice), length)
            tuned = [(hz * octave, beats) for hz, beats in pitches]
            mix_into(buffer, start, vocode(spoken, tuned), gain)
            if whisper:
                # A second, lower voice a fifth below makes a choir of witches.
                mix_into(buffer, start, vocode(spoken, [(hz * octave * 0.667, b) for hz, b in pitches]), gain * 0.6)
                mix_into(buffer, start, stretch(speak(word, WHISPER), length), whisper)
            mix_into(buffer, start, spoken, dry)
    print('  sung %s: mixing' % voice, flush=True)
    buffer = resample(reverb(buffer, 0.45), speed)
    peak = max(map(abs, buffer)) or 1.0
    return [v * 0.9 / peak for v in buffer]


def write_samples(name, samples):
    with wave.open(str(ROOT / name), 'wb') as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, s)) * 32767)) for s in samples))


def write(name, duration, notes):
    samples = [0.0] * int(duration * RATE)
    for start, frequency, length, gain in notes:
        for n in range(min(int(length * RATE), len(samples) - int(start * RATE))):
            t = n / RATE
            envelope = min(t / 0.04, 1.0) * math.exp(-t * 2.0 / length)
            envelope *= min((length - t) / 0.25, 1.0)
            tone = math.sin(math.tau * frequency * t)
            tone += 0.2 * math.sin(math.tau * frequency * 2.002 * t)
            samples[int(start * RATE) + n] += tone * envelope * gain
    write_samples(name, samples)


if __name__ == '__main__':
    import sys
    if 'sung' in sys.argv:
        print('Rendering the witches\' chant', flush=True)
        write_samples('witches_chant.wav', render_sung(['falling', 'lock', 'watch'], VOICE, 1.0, 0.3, 0.12, 0.14, 0.9, 0.08, 0))
        print('Rendering the fair lady', flush=True)
        write_samples('fair_lady.wav', render_sung(['falling'], 'Samantha', 2.0, 0.34, 0.16, 0.0, 0.82, 0.12, 6))
        sys.exit(0)
    for index in range(2):
        print('Rendering bright London Bridge %d' % index, flush=True)
        write_samples('london_bridge_bright_%d.wav' % index, render_bright(index))
    for index, config in enumerate(STAGES):
        print('Rendering London Bridge stage %d' % index, flush=True)
        write_samples('london_bridge_%d.wav' % index, render_stage(index, config))
    write('solved.wav', 2, [(0, 293.66, 1.8, .10), (.12, 440, 1.7, .09), (.24, 587.33, 1.6, .07)])
    write('mechanism.wav', .35, [(0, 110, .3, .12), (.08, 164.81, .2, .06)])
