#!/usr/bin/env python3
"""Generates the game's sound effects procedurally (no third-party samples).

Usage: python3 tool/generate_sfx.py   (writes assets/audio/sfx/*.wav)
Requires numpy. Output: 22.05 kHz mono 16-bit WAV, a few KB each.
"""
import os
import wave

import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio', 'sfx')
rng = np.random.default_rng(7)


def t_axis(seconds):
    return np.arange(int(SR * seconds)) / SR


def note(name):
    names = {'C': 0, 'C#': 1, 'D': 2, 'D#': 3, 'E': 4, 'F': 5, 'F#': 6, 'G': 7, 'G#': 8, 'A': 9, 'A#': 10, 'B': 11}
    pitch, octave = name[:-1], int(name[-1])
    return 440.0 * 2 ** ((names[pitch] + 12 * (octave + 1) - 69) / 12)


def sweep(f0, f1, seconds, shape='sine'):
    t = t_axis(seconds)
    freq = f0 * (f1 / f0) ** (t / seconds)
    phase = 2 * np.pi * np.cumsum(freq) / SR
    if shape == 'tri':
        return 2 / np.pi * np.arcsin(np.sin(phase))
    if shape == 'square':
        return np.tanh(3 * np.sin(phase))
    return np.sin(phase)


def tone(freq, seconds, shape='sine'):
    return sweep(freq, freq, seconds, shape)


def decay(seconds, tau, attack=0.003):
    t = t_axis(seconds)
    env = np.exp(-t / tau)
    a = int(SR * attack)
    if a > 0:
        env[:a] *= np.linspace(0, 1, a)
    return env


def lowpass(x, cutoff):
    alpha = 1 - np.exp(-2 * np.pi * cutoff / SR)
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        y[i] = acc
    return y


def noise(seconds):
    return rng.uniform(-1, 1, int(SR * seconds))


def bell(freq, seconds, tau):
    """Bright bell: fundamental plus an inharmonic partial."""
    return (tone(freq, seconds) + 0.35 * tone(freq * 2.76, seconds) * decay(seconds, tau * 0.4)
            + 0.15 * tone(freq * 5.4, seconds) * decay(seconds, tau * 0.2)) * decay(seconds, tau)


def place(buffer, sound, at):
    start = int(SR * at)
    end = min(len(buffer), start + len(sound))
    buffer[start:end] += sound[:end - start]
    return buffer


def reverb(x, mix=0.25):
    out = x.copy()
    for delay_ms, gain in ((37, 0.5), (71, 0.35), (113, 0.25), (167, 0.18), (229, 0.12)):
        d = int(SR * delay_ms / 1000)
        out[d:] += gain * mix * x[:-d]
    return out


def arpeggio(notes, step, length, tau, gain=1.0):
    buf = np.zeros(int(SR * length))
    for i, n in enumerate(notes):
        place(buf, gain * bell(note(n), length - i * step, tau), i * step)
    return buf


def save(name, x, peak=0.9):
    x = np.asarray(x, dtype=np.float64)
    fade = min(len(x), int(SR * 0.008))
    x[-fade:] *= np.linspace(1, 0, fade)
    m = np.max(np.abs(x)) or 1
    x = x / m * peak
    data = (x * 32767).astype('<i2')
    with wave.open(os.path.join(OUT, f'{name}.wav'), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


def main():
    os.makedirs(OUT, exist_ok=True)

    save('move', (tone(1250, 0.05) + 0.3 * tone(2500, 0.05)) * decay(0.05, 0.012), 0.35)
    save('bump', tone(260, 0.07, 'tri') * decay(0.07, 0.018), 0.3)
    save('rotate', sweep(650, 1350, 0.08, 'tri') * decay(0.08, 0.035), 0.42)
    save('soft', tone(950, 0.03) * decay(0.03, 0.006), 0.18)

    thud = sweep(170, 42, 0.32) * decay(0.32, 0.11)
    crack = lowpass(noise(0.32), 2500) * decay(0.32, 0.03)
    click = tone(2200, 0.32) * decay(0.32, 0.006)
    save('hard', thud + 0.6 * crack + 0.25 * click, 0.95)

    save('lock', tone(520, 0.1) * decay(0.1, 0.025) + 0.4 * lowpass(noise(0.1), 4000) * decay(0.1, 0.008), 0.5)

    t = t_axis(0.25)
    whoosh = lowpass(noise(0.25), 1800) * np.sin(np.pi * t / 0.25) ** 2
    save('hold', whoosh + 0.25 * sweep(400, 900, 0.25) * np.sin(np.pi * t / 0.25), 0.55)

    save('clear1', reverb(arpeggio(['C6', 'G6'], 0.05, 0.6, 0.18)), 0.7)
    save('clear2', reverb(arpeggio(['C6', 'E6', 'G6'], 0.05, 0.7, 0.2)), 0.75)
    save('clear3', reverb(arpeggio(['C6', 'E6', 'G6', 'C7'], 0.045, 0.8, 0.22)), 0.8)

    tetris = arpeggio(['C5', 'E5', 'G5', 'C6', 'E6', 'G6', 'C7', 'E7'], 0.04, 1.5, 0.35)
    boom = sweep(120, 40, 1.5) * decay(1.5, 0.25)
    shimmer = lowpass(noise(1.5), 7000) * decay(1.5, 0.5) * 0.15
    save('clear4', reverb(tetris + 0.8 * boom + shimmer, 0.35), 0.95)

    t = t_axis(0.9)
    rise = lowpass(noise(0.9), 3000) * np.clip(t / 0.25, 0, 1) * decay(0.9, 0.25)
    save('tspin', reverb(0.5 * rise + arpeggio(['A5', 'C#6', 'E6', 'G#6', 'B6'], 0.05, 0.9, 0.22)), 0.85)

    for i, n in enumerate(['C6', 'D6', 'E6', 'G6', 'A6', 'C7', 'D7', 'E7'], start=1):
        save(f'combo{i}', reverb(bell(note(n), 0.35, 0.09) + 0.4 * bell(note(n) * 1.5, 0.35, 0.06)), 0.55)

    fanfare = np.zeros(int(SR * 1.3))
    for i, n in enumerate(['G5', 'C6', 'E6', 'G6']):
        place(fanfare, tone(note(n), 0.18, 'square') * decay(0.18, 0.08) * 0.5, i * 0.09)
    for n in ['C6', 'E6', 'G6', 'C7']:
        place(fanfare, bell(note(n), 0.95, 0.4) * 0.6, 0.36)
    save('levelup', reverb(lowpass(fanfare, 6000), 0.3), 0.85)

    sad = np.zeros(int(SR * 1.8))
    for i, n in enumerate(['G5', 'E5', 'C5', 'G4']):
        place(sad, tone(note(n), 0.6, 'tri') * decay(0.6, 0.25), i * 0.28)
    save('gameover', reverb(lowpass(sad, 2200), 0.4), 0.75)

    sparkle = np.zeros(int(SR * 1.6))
    for i in range(18):
        f = note(['C7', 'E7', 'G7', 'D7', 'A6'][i % 5]) * (1 + 0.002 * i)
        place(sparkle, bell(f, 0.4, 0.1) * (0.4 + 0.6 * rng.random()), rng.random() * 1.0)
    sparkle += arpeggio(['C5', 'G5', 'C6', 'E6', 'G6'], 0.03, 1.6, 0.5) * 0.7
    save('perfect', reverb(sparkle, 0.35), 0.9)

    # ---- Süper Küpler powers
    boom = sweep(110, 30, 1.2) * decay(1.2, 0.35)
    blast = lowpass(noise(1.2), 1600) * decay(1.2, 0.18)
    crackle = lowpass(noise(1.2), 6000) * decay(1.2, 0.05)
    save('bomb', reverb(boom + 0.9 * blast + 0.4 * crackle, 0.3), 0.98)

    t = t_axis(0.7)
    buzz = sweep(180, 90, 0.7, 'square') * 0.5 + lowpass(noise(0.7), 3000) * 0.4
    buzz *= (0.6 + 0.4 * np.sin(2 * np.pi * 38 * t)) * np.clip(t / 0.03, 0, 1) * decay(0.7, 0.35)
    save('drill', buzz, 0.8)

    fall = sweep(900, 140, 0.45, 'tri') * decay(0.45, 0.3) * 0.6
    thuds = np.zeros(int(SR * 0.9))
    place(thuds, fall, 0)
    for i, at in enumerate([0.42, 0.55, 0.64]):
        place(thuds, sweep(160, 60, 0.18) * decay(0.18, 0.06) * (1 - i * 0.25), at)
    save('gravity', thuds, 0.85)

    slow = sweep(700, 160, 0.9, 'tri') * decay(0.9, 0.6)
    t = t_axis(0.9)
    slow *= 0.7 + 0.3 * np.sin(2 * np.pi * 5 * t)
    save('slowmo', reverb(lowpass(slow, 2500), 0.4), 0.75)

    ghost = np.zeros(int(SR * 1.2))
    for i, n in enumerate(['E6', 'B6', 'G#6', 'E7']):
        place(ghost, bell(note(n), 1.0, 0.35) * 0.6, i * 0.06)
    t = t_axis(1.2)
    ghost += lowpass(noise(1.2), 5000) * 0.08 * np.sin(np.pi * t / 1.2)
    save('ghost', reverb(ghost, 0.45), 0.7)

    save('power', reverb(arpeggio(['G5', 'C6', 'E6', 'G6', 'C7'], 0.035, 0.7, 0.18)), 0.75)
    zap = sweep(300, 2400, 0.22, 'square') * decay(0.22, 0.12) * 0.5
    zap = np.concatenate([zap, np.zeros(int(SR * 0.3))])
    place(zap, bell(note('C7'), 0.4, 0.12) * 0.5, 0.12)
    save('poweruse', reverb(lowpass(zap, 7000)), 0.75)

    save('click', tone(1500, 0.035) * decay(0.035, 0.008), 0.35)
    start = sweep(300, 1200, 0.35, 'tri') * decay(0.35, 0.2)
    start = np.concatenate([start, np.zeros(int(SR * 0.4))])
    place(start, arpeggio(['C6', 'E6', 'G6'], 0.0, 0.6, 0.25), 0.15)
    save('start', reverb(start), 0.75)


if __name__ == '__main__':
    main()
