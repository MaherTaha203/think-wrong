#!/usr/bin/env python3
"""Generate THINK WRONG's original minimal SFX as small WAV files.

All sounds are synthesized with the Python standard library only (no third-party
or copyrighted audio). Run: python3 tools/gen_audio.py
"""
from __future__ import annotations
import math, os, struct, wave

SR = 44100

def tone(freq, dur, vol=0.35, decay=9.0, freq_end=None):
    n = int(SR * dur); out = []
    for i in range(n):
        t = i / SR
        f = freq if freq_end is None else freq + (freq_end - freq) * (i / max(1, n))
        out.append(math.sin(2 * math.pi * f * t) * math.exp(-decay * t) * vol)
    return out

def chord(freqs, dur, vol=0.3, decay=5.0):
    layers = [tone(f, dur, vol, decay) for f in freqs]
    n = max(len(l) for l in layers); mixed = [0.0] * n
    for l in layers:
        for i, s in enumerate(l):
            mixed[i] += s / len(layers)
    return mixed

def write(path, samples):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "w") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 32767)) for s in samples))

def main():
    out = "assets/audio"
    effects = {
        "tap": tone(520, 0.06, 0.28, 14.0),
        "nav": tone(380, 0.07, 0.25, 12.0, freq_end=460),
        "invalid": tone(150, 0.14, 0.33, 7.0, freq_end=110),
        "success": chord([523, 659, 784], 0.5, 0.32, 4.0),  # C-E-G
    }
    for name, s in effects.items():
        p = os.path.join(out, name + ".wav"); write(p, s); print("wrote", p)

if __name__ == "__main__":
    raise SystemExit(main())
