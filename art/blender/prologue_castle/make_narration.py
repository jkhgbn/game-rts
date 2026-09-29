"""The Master's narration for the 30-second citadel film (script.md) + a synthesised bell toll.

Run with the Kokoro venv (outside the repo, same one the Voice Forge uses):
    ..\\..\\..\\..\\four-wizards-voice\\venv\\Scripts\\python.exe make_narration.py
i.e.  C:\\Users\\elzzo\\Documents\\four-wizards-voice\\venv\\Scripts\\python.exe art\\blender\\prologue_castle\\make_narration.py

Uses tools/voice_forge/voice_forge.py (Engine, cast voice, trim / fades / -1 dBFS) without touching the game's
manifest or assets: every file lands in this folder.
Outputs (this folder):
    narration.wav        30.0 s, 24 kHz mono PCM16, the Master's lines at their start times
    bell.wav             30.0 s, 48 kHz mono PCM16, bell tolls (the last one is cut dead at "empty")
    wind.wav             30.0 s, 48 kHz mono PCM16, high-altitude wind bed (mixed low)
    lines/<id>.wav       each line alone
    narration_timing.json  measured start / end / speed per line (read by build_castle.py)
"""
import json
import math
import sys
from pathlib import Path

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(ROOT / "tools" / "voice_forge"))
import voice_forge as vf  # noqa: E402

import numpy as np  # noqa: E402
import soundfile as sf  # noqa: E402

LENGTH = 30.0
SR = vf.SR
FIT_MAX = 1.12          # never faster than x1.12 over the cast speed (stays kingly)
WORD_FIT_MAX = 1.04     # the four one-word lines: at most x1.04 (a rushed single word sounds clipped)
GAP = 0.25              # silence kept before the next line starts

# id, start (s), text, latest end (s) the line may reach (next line start - GAP, or the fade)
LINES = [
    ("L1", 0.40, "Above the clouds stood the citadel of the Master.", 4.70 - GAP),
    ("L2", 4.70, "For a thousand years, its bells rang peace.", 8.60 - GAP),
    ("L3", 8.60, "Kings climbed his bridge with drawn swords,", 12.20 - GAP),
    ("L4", 12.20, "and walked home as brothers.", 15.20 - GAP),
    ("L5", 15.20, "Four wizards he raised. Four crowns he gave them.", 19.30 - 0.15),
    ("L6a", 19.30, "Fire.", 20.22 + 0.02),
    ("L6b", 20.22, "Ice.", 21.12 + 0.02),
    ("L6c", 21.12, "Nature.", 22.20 + 0.02),
    ("L6d", 22.20, "Shadow.", 23.25),
    ("L7", 23.35, "Then, in one breath, the throne stood empty.", 27.10 - 0.15),
    ("L8", 27.10, "And the bells fell silent.", 29.45),
]


def render_lines() -> list:
    cast = vf.load_cast()
    cfg = vf.voice_of(cast, "master")
    base = cfg["speed"]
    eng = vf.Engine()
    out = []
    (HERE / "lines").mkdir(exist_ok=True)
    for lid, start, text, latest in LINES:
        slot = latest - start
        speed = base
        s = eng.render(text, dict(cfg, speed=speed))
        dur = len(s) / SR
        tries = 0
        cap = base * (WORD_FIT_MAX if lid.startswith("L6") else FIT_MAX)
        while dur > slot and speed < cap - 1e-6 and tries < 6:
            speed = min(cap, speed * max(1.02, dur / slot))
            s = eng.render(text, dict(cfg, speed=speed))
            dur = len(s) / SR
            tries += 1
        # the rendered clip has 40 ms of room before the first word: start the clip that much early
        clip_start = max(0.0, start - vf.KEEP_HEAD)
        vf.write_wav(HERE / "lines" / f"{lid}.wav", s)
        out.append({"id": lid, "text": text, "start": round(clip_start, 3), "speech_start": round(start, 3),
                    "end": round(clip_start + dur, 3), "duration": round(dur, 3), "slot": round(slot, 3),
                    "speed": round(speed, 4), "cast_speed": base, "fits": dur <= slot + 0.05,
                    "voiced": speech_span(s, clip_start), "pauses": pauses(s, clip_start), "audio": s})
        print(f"{lid}: {dur:5.2f} s in slot {slot:4.2f} s at speed {speed:.3f}  {'OK' if dur <= slot + 0.05 else 'OVER'}"
              f"  voiced {out[-1]['voiced']} pauses {out[-1]['pauses']}  {text}")
    return out


def _frames_rms(s):
    win = int(0.01 * SR)
    frames = len(s) // win
    return np.sqrt(np.mean(s[:frames * win].reshape(frames, win) ** 2, axis=1) + 1e-12) if frames else np.zeros(0)


def pauses(s, t0: float, min_gap: float = 0.10) -> list:
    """Silent gaps inside a clip (10 ms RMS < -30 dB of its loudest frame), as absolute [start, end] seconds: the
    build puts cuts inside a line on these (e.g. SH02 -> SH03 after "years,")."""
    rms = _frames_rms(s)
    frames = len(rms)
    quiet = rms < (rms.max() if frames else 1.0) * 10 ** (-30 / 20)
    out, i = [], 0
    while i < frames:
        if quiet[i]:
            j = i
            while j < frames and quiet[j]:
                j += 1
            if 0 < i and j < frames and (j - i) * 0.01 >= min_gap:
                out.append([round(t0 + i * 0.01, 3), round(t0 + j * 0.01, 3)])
            i = j
        else:
            i += 1
    return out


def speech_span(s, t0: float) -> list:
    """First and last voiced 10 ms frame (absolute seconds)."""
    rms = _frames_rms(s)
    v = np.nonzero(rms > rms.max() * 10 ** (-30 / 20))[0] if len(rms) else []
    return [round(t0 + v[0] * 0.01, 3), round(t0 + (v[-1] + 1) * 0.01, 3)] if len(v) else [t0, t0]


def mix_narration(lines: list) -> np.ndarray:
    buf = np.zeros(int(LENGTH * SR), dtype=np.float32)
    for ln in lines:
        a = int(round(ln["start"] * SR))
        s = ln["audio"]
        b = min(len(buf), a + len(s))
        buf[a:b] += s[: b - a]
    peak = float(np.max(np.abs(buf)))
    if peak > vf.PEAK:
        buf *= vf.PEAK / peak
    return buf


def bell(empty_at: float, sr: int = 48000):
    """A large bronze bell: church-bell partial ratios (hum, prime, tierce, quint, nominal, upper partials) with
    per-partial decay, a short metallic strike transient, slight beating (doublets). Tolls at the SH03 clapper
    strike (7.0 s), the gate (10.6 s), the dome (15.05 s) and at SH10 (23.12 s), whose ring is cut dead on the word
    "empty" (`empty_at`, measured from L7); nothing after that ("And the bells fell silent")."""
    f0 = 196.0  # prime ~G3: big but not muddy under the voice
    partials = [  # ratio, amplitude, decay seconds
        (0.5, 0.55, 7.0), (1.0, 0.8, 5.0), (1.19, 0.5, 3.6), (1.5, 0.28, 2.8), (2.0, 0.6, 2.4),
        (2.51, 0.22, 1.6), (2.66, 0.2, 1.5), (3.01, 0.16, 1.2), (4.07, 0.1, 0.8), (5.2, 0.06, 0.5),
    ]
    n = int(LENGTH * sr)
    t_all = np.arange(n) / sr
    out = np.zeros(n, dtype=np.float64)
    rng = np.random.default_rng(7)
    tolls = [(7.0, 1.0, None), (10.6, 0.55, None), (15.05, 0.6, None), (23.12, 0.8, empty_at)]
    for t0, gain, cut in tolls:
        a = int(t0 * sr)
        t = t_all[a:] - t0
        tone = np.zeros_like(t)
        for r, amp, dec in partials:
            f = f0 * r
            beat = 1.0 + 0.12 * np.cos(2 * math.pi * (0.7 + r * 0.3) * t)   # doublet beating
            tone += amp * np.exp(-t / dec) * beat * np.sin(2 * math.pi * f * t + rng.uniform(0, 6.28))
        # strike: 12 ms of filtered noise
        k = int(0.012 * sr)
        noise = rng.normal(0, 1, k) * np.exp(-np.arange(k) / (0.003 * sr))
        tone[:k] += 0.6 * noise
        env = np.minimum(1.0, t / 0.002)
        tone *= env * gain
        if cut is not None:
            c = int((cut - t0) * sr)
            fade = int(0.06 * sr)
            tone[c:c + fade] *= np.linspace(1, 0, min(fade, len(tone) - c))
            tone[c + fade:] = 0.0
        out[a:] += tone
    out /= max(1e-9, np.max(np.abs(out)))
    return (out * 10 ** (-1.0 / 20.0)).astype(np.float32), sr


def wind(empty_at: float, sr: int = 48000):
    """High-altitude wind under everything: spectrally shaped noise (a low roar + a faint whistle band) in slow gusts;
    it swells a little when the light dies ("empty") and carries on after the bells stop."""
    n = int(LENGTH * sr)
    rng = np.random.default_rng(11)
    spec = np.fft.rfft(rng.normal(0, 1, n))
    f = np.fft.rfftfreq(n, 1.0 / sr)
    shape = 1.0 / np.sqrt(1.0 + (f / 220.0) ** 2) + 0.22 * np.exp(-((f - 720.0) / 260.0) ** 2)
    shape[f < 25.0] *= (f[f < 25.0] / 25.0) ** 2          # no DC / sub rumble
    x = np.fft.irfft(spec * shape, n)
    t = np.arange(n) / sr
    gust = 0.62 + 0.18 * np.sin(2 * math.pi * 0.07 * t + 1.0) + 0.12 * np.sin(2 * math.pi * 0.19 * t + 2.3)         + 0.08 * np.sin(2 * math.pi * 0.41 * t + 0.4)
    swell = 1.0 + 0.45 * np.clip((t - empty_at) / 0.8, 0.0, 1.0) * np.clip((29.0 - t) / 2.0 + 0.5, 0.5, 1.0)
    env = np.clip(t / 1.2, 0.0, 1.0) * np.clip((LENGTH - t) / 0.8, 0.0, 1.0)
    x = x * gust * swell * env
    x /= max(1e-9, np.max(np.abs(x)))
    return (x * 10 ** (-1.0 / 20.0)).astype(np.float32), sr


def main() -> int:
    lines = render_lines()
    nar = mix_narration(lines)
    sf.write(str(HERE / "narration.wav"), np.round(nar * 32767).astype(np.int16), SR, subtype="PCM_16")
    l7 = next(ln for ln in lines if ln["id"] == "L7")
    empty_at = round(l7["voiced"][1] - 0.42, 3)   # "empty" = the last ~0.42 s of L7's speech
    b, bsr = bell(empty_at)
    sf.write(str(HERE / "bell.wav"), np.round(b * 32767).astype(np.int16), bsr, subtype="PCM_16")
    w, wsr = wind(empty_at)
    sf.write(str(HERE / "wind.wav"), np.round(w * 32767).astype(np.int16), wsr, subtype="PCM_16")
    timing = {"length": LENGTH, "sample_rate": SR, "speaker": "master",
              "voice": vf.voice_of(vf.load_cast(), "master")["voice"], "empty_at": empty_at,
              "lines": [{k: v for k, v in ln.items() if k != "audio"} for ln in lines]}
    (HERE / "narration_timing.json").write_text(json.dumps(timing, indent=1), encoding="utf-8")
    bad = [ln["id"] for ln in lines if not ln["fits"]]
    print(f"narration.wav {LENGTH:.1f} s, {len(lines)} clips; over their slot: {bad or 'none'}")
    return 0 if not bad else 1


if __name__ == "__main__":
    sys.exit(main())
