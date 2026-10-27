"""Regenerate the project's original short sound effects using Python's standard library."""
from pathlib import Path
import math
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[1] / "assets" / "audio"
RATE = 22050


def tone(name, notes, duration=0.09, noise=False):
    rng = random.Random(42)
    samples = []
    for frequency in notes:
        length = int(RATE * duration)
        for index in range(length):
            t = index / RATE
            envelope = min(1.0, t / 0.008) * (1.0 - index / length) ** 1.8
            pitch = frequency * (1.0 - 0.20 * index / length)
            value = math.sin(2 * math.pi * pitch * t)
            if noise:
                value = value * 0.45 + rng.uniform(-0.55, 0.55)
            samples.append(int(value * envelope * 20000))
    ROOT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(ROOT / f"{name}.wav"), "wb") as output:
        output.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        output.writeframes(struct.pack(f"<{len(samples)}h", *samples))


if __name__ == "__main__":
    tone("hop", [640], 0.065)
    tone("hit", [150, 80], 0.14, noise=True)
    tone("dock", [660, 880, 1100], 0.095)
    tone("complete", [523, 659, 784, 1047], 0.15)
    tone("ui", [480, 640], 0.06)
    print("Generated five original WAV effects.")
