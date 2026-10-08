"""Voice Forge (tools/voice_forge/README.md): every spoken line of the game -> one Kokoro WAV per line.

Run through tools/voice_forge/run_voice_forge.ps1 (it picks the Kokoro venv outside the repo). Verbs:
  extract            find every spoken line -> data/voice/lines_index.json (+ data/voice/lines/ep3|ep4_opening.json)
  generate           extract + render missing / changed lines -> assets/audio/voice/<speaker>/<key>.wav + manifest
  audition           render each cast entry's audition candidates -> docs/tools/voice_forge/auditions/
                     (only=<speaker> replaces that speaker's rows in auditions.md, keeps the others)
  selftest           no Kokoro: direction tags, speed-fit, manifest compatibility, auditions merge
Options: force=1 (re-render everything), only=<speaker> (limit generate), id=<report id> (default "all"),
  match=<regex on a source path> / limit=<n> (render one batch), fit_max=<x> (speed-fit cap below x1.25),
  fit=1 (default: new / changed lines are sped up, <= x1.25, to fit their slot) | fit=all (also re-render existing
  lines that overrun) | fit=0 (off).
Direction tags in a line's text ([scared], [whisper], [angry], [pause] ...: DIRECTIONS) change speed / pauses /
stutter / ending of what Kokoro reads; the tag stays in the keyed text.

Line key = <first words>_<sha256(speaker + "\n" + text)[:8]>: stable, so an unchanged line is never re-rendered.
Output WAV: mono, 24 kHz, 16-bit PCM, leading / trailing silence trimmed (40 ms / 90 ms kept), peak -1 dBFS.
"""
import hashlib
import json
import os
import re
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
VOICE_HOME = Path(os.environ.get("FW_VOICE_HOME", r"C:\Users\elzzo\Documents\four-wizards-voice"))
MODEL = VOICE_HOME / "models" / "kokoro-v1.0.onnx"
VOICES = VOICE_HOME / "models" / "voices-v1.0.bin"
CAST = ROOT / "data" / "voice" / "cast.json"
MANIFEST = ROOT / "data" / "voice" / "manifest.json"
INDEX = ROOT / "data" / "voice" / "lines_index.json"
LINES_DIR = ROOT / "data" / "voice" / "lines"
AUDIO_DIR = ROOT / "assets" / "audio" / "voice"
DOCS = ROOT / "docs" / "tools" / "voice_forge"
EP_DOC = ROOT / "docs" / "design" / "episode3-4-opening.md"
SR = 24000
PEAK = 10 ** (-1.0 / 20.0)          # -1 dBFS
KEEP_HEAD, KEEP_TAIL = 0.04, 0.09   # seconds of room kept around the speech
FADE = 0.008
MISSION_SLOT_DEFAULT = 5.0
FIT_MAX = 1.25        # speed-fit never speeds a line up more than x1.25 over its cast (+ direction) speed
FIT_MARGIN = 0.05     # a line fits when its length <= slot + FIT_MARGIN (the report's F1 rule)
FIT_AIM = 0.96        # a fitted line aims at 96 % of its slot


# ------------------------------------------------------------------ text helpers

def norm_text(t: str) -> str:
    """Display text -> the text the line is keyed and spoken by (subtitle breaks `|` become spaces)."""
    return re.sub(r"\s+", " ", t.replace("|", " ")).strip()


def spoken_text(t: str) -> str:
    """What Kokoro reads: direction tags applied (see DIRECTIONS), shouted words in capitals read as words, not
    letters ("NOT" -> "not")."""
    t = direction(t)["text"]
    return re.sub(r"\b([A-Z]{2,})\b", lambda m: m.group(1).lower() if m.group(1) not in ("OK",) else m.group(1), t)


# Direction tags in a line's text: `[scared] We are not alone.` or `Wait [pause] listen.` The tag stays in the line's
# text (key, subtitle lookup), and only changes how Kokoro reads it: speed x `speed`, `pause` = commas / dashes become
# "..." (longer breaks), `stutter` = the first word is repeated ("We... we are"), `end` = the last "." becomes this.
# `[pause]` alone = a "..." break at that point. Unknown tags are stripped and listed in the extract notes.
DIRECTIONS = {
    "scared": {"speed": 0.94, "pause": True, "stutter": True},
    "hesitant": {"speed": 0.95, "pause": True, "stutter": True},
    "stutter": {"stutter": True},
    "whisper": {"speed": 0.9, "pause": True},
    "sad": {"speed": 0.88, "pause": True},
    "tired": {"speed": 0.9, "pause": True},
    "slow": {"speed": 0.88},
    "calm": {"speed": 0.95},
    "fast": {"speed": 1.12},
    "excited": {"speed": 1.1, "end": "!"},
    "angry": {"speed": 1.06, "end": "!"},
    "shout": {"speed": 1.05, "end": "!"},
    "pause": {},
}
RE_TAG = re.compile(r"\[\s*([A-Za-z][A-Za-z _-]*?)\s*\]")


def direction(t: str) -> dict:
    """Line text -> {text: what Kokoro reads, speed: multiplier, tags: [known], unknown: [names]}."""
    t = norm_text(t)
    tags, unknown = [], []
    for m in RE_TAG.finditer(t):
        name = m.group(1).lower().replace(" ", "_").replace("-", "_")
        (tags if name in DIRECTIONS else unknown).append(name)
    if not tags and not unknown:
        return {"text": t, "speed": 1.0, "tags": [], "unknown": []}
    s = RE_TAG.sub(lambda m: " ... " if m.group(1).lower() == "pause" else " ", t)
    s = re.sub(r"\s+", " ", s).strip()
    s = re.sub(r"^(\.\.\.\s*)+", "", s)
    speed, pause, stutter, end = 1.0, False, False, ""
    for name in tags:
        d = DIRECTIONS[name]
        speed *= float(d.get("speed", 1.0))
        pause = pause or d.get("pause", False)
        stutter = stutter or d.get("stutter", False)
        end = d.get("end", end)
    if pause:
        s = re.sub(r"\s*[,;]\s+|\s+-+\s+", "... ", s)
    if stutter:
        m = re.match(r"([A-Za-z']+)(.*)$", s, re.S)
        if m:
            s = f"{m.group(1)}... {m.group(1).lower() if m.group(1) != 'I' else 'I'}{m.group(2)}"
    if end and s.endswith(".") and not s.endswith("..."):
        s = s[:-1] + end
    s = re.sub(r"\s+([,.!?])", r"\1", re.sub(r"\s+", " ", s)).strip()
    return {"text": s, "speed": round(speed, 4), "tags": tags, "unknown": unknown}


def text_hash(speaker: str, text: str) -> str:
    return hashlib.sha256((speaker + "\n" + norm_text(text)).encode("utf-8")).hexdigest()


def line_key(speaker: str, text: str) -> str:
    words = re.findall(r"[a-z0-9]+", norm_text(text).lower().replace("'", ""))
    slug = "_".join(words[:4])[:28].strip("_") or "line"
    return f"{slug}_{text_hash(speaker, text)[:8]}"


def unescape_gd(s: str) -> str:
    return s.replace('\\"', '"').replace("\\n", " ").replace("\\\\", "\\")


def rel(p: Path) -> str:
    return p.relative_to(ROOT).as_posix()


# ------------------------------------------------------------------ extraction

GD_STR = r'"((?:[^"\\]|\\.)*)"'
RE_DIALOGUE_BLOCK = re.compile(r"^const\s+(\w*DIALOGUE\w*)\b[^\n]*?=\s*\[", re.M)
RE_ENTRY = re.compile(r'\[\s*&?"(\w+)"\s*,\s*' + GD_STR + r"\s*\]")
RE_EMIT = re.compile(r'(?:emit_signal\(\s*&?"dialogue"\s*,|dialogue\.emit\(|\.say\()\s*&?"(\w+)"\s*,\s*' + GD_STR)


def _block_end(text: str, start: int) -> int:
    depth, i, in_str = 0, start, False
    while i < len(text):
        c = text[i]
        if in_str:
            if c == "\\":
                i += 1
            elif c == '"':
                in_str = False
        elif c == '"':
            in_str = True
        elif c == "[":
            depth += 1
        elif c == "]":
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return len(text)


def mission_slot() -> float:
    box = ROOT / "scripts" / "ui" / "mission" / "dialogue_box.gd"
    if box.exists():
        m = re.search(r"const\s+LINE_SECONDS\s*:?=\s*([\d.]+)", box.read_text(encoding="utf-8"))
        if m:
            return float(m.group(1))
    return MISSION_SLOT_DEFAULT


def extract_missions(out: list, notes: list) -> None:
    slot = mission_slot()
    files = sorted((ROOT / "scripts" / "campaign").glob("*.gd")) + sorted((ROOT / "missions").rglob("*.gd"))
    for f in files:
        src = f.read_text(encoding="utf-8")
        n = 0
        for m in RE_DIALOGUE_BLOCK.finditer(src):
            end = _block_end(src, m.end() - 1)
            for i, e in enumerate(RE_ENTRY.finditer(src[m.end() - 1:end + 1])):
                n += 1
                out.append({"speaker": e.group(1).lower(), "text": unescape_gd(e.group(2)), "kind": "mission",
                            "source": f"{rel(f)}:{m.group(1)}[{i}]", "ref": f"L{i + 1}", "slot": slot,
                            "slot_kind": "subtitle"})
        for e in RE_EMIT.finditer(src):
            n += 1
            ln = src.count("\n", 0, e.start()) + 1
            out.append({"speaker": e.group(1).lower(), "text": unescape_gd(e.group(2)), "kind": "mission",
                        "source": f"{rel(f)}:{ln}", "ref": "emit", "slot": slot, "slot_kind": "subtitle"})
        if n:
            notes.append(f"{rel(f)}: {n} lines")
    for f in sorted((ROOT / "missions").rglob("*.json")):
        _extract_json(f, out, notes, "mission")


RE_SHOT = re.compile(r"^shot\s+(\S+)\s+([\d.]+)")
RE_CINE_LINE = re.compile(r'^\s+at\s+([\d.]+)\s+line\s+(\w+)\s+"([^"]*)"(.*)$')


def extract_cines(out: list, notes: list) -> None:
    for f in sorted((ROOT / "data" / "cinematics" / "src").glob("*.cine")):
        if f.stem.endswith("_bugs"):
            notes.append(f"{rel(f)}: skipped (planted-bug fixture)")
            continue
        shot, shot_len, pending = "", 0.0, []

        def flush():
            for j, (at, spk, txt, dur, ln) in enumerate(pending):
                nxt = pending[j + 1][0] if j + 1 < len(pending) else shot_len
                slot = dur if dur > 0 else max(0.0, min(nxt, shot_len) - at)
                out.append({"speaker": spk.lower(), "text": txt, "kind": "cine", "source": f"{rel(f)}:{ln}",
                            "ref": f"{f.stem}/{shot}@{at:g}", "slot": round(slot, 3), "slot_kind": "cine shot"})
            pending.clear()

        n = 0
        for ln, raw in enumerate(f.read_text(encoding="utf-8").splitlines(), 1):
            s = raw.split(" # ")[0].rstrip()
            m = RE_SHOT.match(s)
            if m:
                flush()
                shot, shot_len = m.group(1), float(m.group(2))
                continue
            m = RE_CINE_LINE.match(s)
            if m:
                dm = re.search(r"\b(?:dur|time)=([\d.]+)", m.group(4))
                pending.append((float(m.group(1)), m.group(2), m.group(3), float(dm.group(1)) if dm else 0.0, ln))
                n += 1
        flush()
        notes.append(f"{rel(f)}: {n} lines")
    story = ROOT / "data" / "story"
    if story.exists():
        for f in sorted(story.glob("*.lines.json")):
            _extract_json(f, out, notes, "cine")


def _extract_json(f: Path, out: list, notes: list, kind: str) -> None:
    """Our line files ({lines: [{speaker, text, dur}]}) and the LineTrack contract ({lines: {shot: [{at, speaker,
    text, duration}]}})."""
    try:
        d = json.loads(f.read_text(encoding="utf-8"))
    except Exception as e:  # noqa: BLE001
        notes.append(f"{rel(f)}: unreadable JSON ({e})")
        return
    lines = d.get("lines", []) if isinstance(d, dict) else d
    rows = []
    if isinstance(lines, dict):
        for shot, arr in lines.items():
            for x in arr:
                rows.append((f"{d.get('cine_id', f.stem)}/{shot}@{x.get('at', 0)}", x))
    elif isinstance(lines, list):
        for i, x in enumerate(lines):
            rows.append((f"{d.get('cine_id', f.stem)}/{x.get('id', i + 1)}", x))
    n = 0
    for ref, x in rows:
        if not isinstance(x, dict) or not x.get("speaker") or not x.get("text"):
            continue
        n += 1
        slot = float(x.get("dur", x.get("duration", 0)) or 0)
        out.append({"speaker": str(x["speaker"]).lower(), "text": str(x["text"]), "kind": kind, "source": rel(f),
                    "ref": ref, "slot": slot if slot > 0 else None, "slot_kind": "cine slot"})
    notes.append(f"{rel(f)}: {n} lines")


RE_EP_ROW = re.compile(r"^\|\s*(L\d+)\s*\|\s*(\w+)\s*\|\s*([\d.]+)\s*/\s*([\d.]+)\s*\|(.*)\|\s*$")


def write_episode_lines(notes: list) -> None:
    """docs/design/episode3-4-opening.md section 3 tables -> data/voice/lines/ep3_opening.json / ep4_opening.json."""
    if not EP_DOC.exists():
        notes.append(f"{rel(EP_DOC)} missing: episode lines kept as they are")
        return
    sections = {"ep3_opening": ("### 3.1", "malrik"), "ep4_opening": ("### 3.2", None)}
    text = EP_DOC.read_text(encoding="utf-8")
    for cid, (head, default_speaker) in sections.items():
        i = text.find(head)
        if i < 0:
            notes.append(f"{rel(EP_DOC)}: section {head} not found, {cid}.json kept")
            continue
        j = text.find("\n##", i + len(head))
        block = text[i:j if j > 0 else len(text)]
        lines, bad = [], []
        for raw in block.splitlines():
            row = raw.replace("\\|", "\u0001")
            m = RE_EP_ROW.match(row)
            if not m:
                if raw.startswith("| L"):
                    bad.append(raw)
                continue
            cells = [c.strip().replace("\u0001", "|") for c in m.group(5).split("|")]
            if default_speaker:
                speaker, sub = default_speaker, "|".join(cells).strip()
            else:
                speaker, sub = cells[0].lower(), "|".join(cells[1:]).strip()
            lines.append({"id": m.group(1), "shot": m.group(2), "at": float(m.group(3)), "dur": float(m.group(4)),
                          "speaker": speaker, "subtitle": sub, "text": norm_text(sub)})
        if not lines:
            notes.append(f"{rel(EP_DOC)} {head}: no rows read, {cid}.json kept")
            continue
        LINES_DIR.mkdir(parents=True, exist_ok=True)
        doc = {"cine_id": cid, "source": f"{rel(EP_DOC)} {head}",
               "note": "Written by tools/voice_forge (extract); edit the design doc, not this file.", "lines": lines}
        (LINES_DIR / f"{cid}.json").write_text(json.dumps(doc, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
        notes.append(f"{rel(EP_DOC)} {head} -> data/voice/lines/{cid}.json: {len(lines)} lines"
                     + (f", {len(bad)} rows unreadable" if bad else ""))


def extract() -> dict:
    notes, raw = [], []
    write_episode_lines(notes)
    extract_missions(raw, notes)
    extract_cines(raw, notes)
    for f in sorted(LINES_DIR.glob("*.json")) if LINES_DIR.exists() else []:
        _extract_json(f, raw, notes, "cine")
    cast = load_cast()
    lines: dict = {}
    for r in raw:
        spk = resolve_speaker(cast, r["speaker"])
        mid = f"{spk}/{line_key(spk, r['text'])}"
        e = lines.setdefault(mid, {"id": mid, "speaker": spk, "text": norm_text(r["text"]),
                                   "text_hash": text_hash(spk, r["text"])[:16], "sources": []})
        e["sources"].append({"kind": r["kind"], "source": r["source"], "ref": r["ref"], "slot": r["slot"],
                             "slot_kind": r["slot_kind"], "speaker_id": r["speaker"]})
        dr = direction(r["text"])
        if dr["tags"]:
            e["direction"] = dr["tags"]
        if dr["unknown"]:
            notes.append(f"{r['source']}: unknown direction tag(s) {', '.join('[' + u + ']' for u in dr['unknown'])} "
                         f"(stripped; known: {', '.join(sorted(DIRECTIONS))})")
    idx = {"version": 1, "generated_by": "tools/voice_forge/voice_forge.py extract", "notes": notes,
           "count": len(lines), "lines": sorted(lines.values(), key=lambda e: e["id"])}
    INDEX.parent.mkdir(parents=True, exist_ok=True)
    INDEX.write_text(json.dumps(idx, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    return idx


# ------------------------------------------------------------------ cast

def load_cast() -> dict:
    return json.loads(CAST.read_text(encoding="utf-8"))


def resolve_speaker(cast: dict, speaker: str) -> str:
    """Aliases (e.g. torren -> vey) share one voice folder."""
    e = cast.get("speakers", {}).get(speaker)
    return e["alias_of"] if isinstance(e, dict) and e.get("alias_of") else speaker


def voice_of(cast: dict, speaker: str) -> dict:
    sp = cast.get("speakers", {})
    e = sp.get(speaker) or sp.get(cast.get("default_speaker", "narrator"))
    return {"voice": e["voice"], "speed": float(e.get("speed", 1.0)), "lang": e.get("lang") or lang_of(e["voice"])}


def lang_of(voice) -> str:
    v = voice if isinstance(voice, str) else str(next(iter(voice)))
    return "en-gb" if v.startswith("b") else "en-us"


# ------------------------------------------------------------------ audio

class Engine:
    def __init__(self):
        import onnxruntime as rt
        from kokoro_onnx import Kokoro
        t0 = time.perf_counter()
        self.k = Kokoro(str(MODEL), str(VOICES))
        self.load_s = time.perf_counter() - t0
        sess = getattr(self.k, "sess", None)
        self.providers = sess.get_providers() if sess is not None else rt.get_available_providers()

    def style(self, voice):
        """A voice id, or a blend {"bm_george": 0.7, "bm_lewis": 0.3}."""
        if isinstance(voice, str):
            return voice
        import numpy as np
        total = sum(voice.values())
        return sum(self.k.get_voice_style(v) * (w / total) for v, w in voice.items()).astype(np.float32)

    def render(self, text: str, cfg: dict):
        import numpy as np
        s, sr = self.k.create(spoken_text(text), voice=self.style(cfg["voice"]), speed=cfg["speed"], lang=cfg["lang"])
        s = np.asarray(s, dtype=np.float32)
        if s.ndim > 1:
            s = s.mean(axis=1)
        if sr != SR:
            n = int(round(len(s) * SR / sr))
            s = np.interp(np.linspace(0, len(s) - 1, n), np.arange(len(s)), s).astype(np.float32)
        return finish_audio(s)


def finish_audio(s):
    """Trim silence (keep KEEP_HEAD / KEEP_TAIL), short fades, peak-normalise to -1 dBFS, float32 -> int16 range."""
    import numpy as np
    win = int(0.01 * SR)
    if len(s) > win:
        frames = len(s) // win
        rms = np.sqrt(np.mean(s[:frames * win].reshape(frames, win) ** 2, axis=1) + 1e-12)
        thr = max(rms.max() * 10 ** (-34 / 20), 1e-4)   # -34 dB of the loudest 10 ms: drops breath tails
        voiced = np.nonzero(rms > thr)[0]
        if len(voiced):
            a = max(0, voiced[0] * win - int(KEEP_HEAD * SR))
            b = min(len(s), (voiced[-1] + 1) * win + int(KEEP_TAIL * SR))
            s = s[a:b]
    f = min(int(FADE * SR), len(s) // 4)
    if f > 0:
        ramp = np.linspace(0.0, 1.0, f, dtype=np.float32)
        s[:f] *= ramp
        s[-f:] *= ramp[::-1]
    peak = float(np.max(np.abs(s))) if len(s) else 0.0
    if peak > 0:
        s = s * (PEAK / peak)
    return np.clip(s, -1.0, 1.0).astype(np.float32)


def write_wav(path: Path, s) -> dict:
    import numpy as np
    import soundfile as sf
    path.parent.mkdir(parents=True, exist_ok=True)
    q = np.round(s * 32767.0).astype(np.int16)
    sf.write(str(path), q, SR, subtype="PCM_16")
    peak = float(np.max(np.abs(q.astype(np.int32)))) / 32767.0 if len(q) else 0.0
    rms = float(np.sqrt(np.mean((q.astype(np.float64) / 32767.0) ** 2))) if len(q) else 0.0
    return {"duration": round(len(q) / SR, 3), "peak": round(peak, 4),
            "rms_db": round(20 * np.log10(max(rms, 1e-9)), 1), "clipped": int(np.sum(np.abs(q.astype(np.int32)) >= 32767)),
            "file_hash": hashlib.sha256(path.read_bytes()).hexdigest()[:16]}


# ------------------------------------------------------------------ generate

def load_manifest() -> dict:
    if MANIFEST.exists():
        try:
            return json.loads(MANIFEST.read_text(encoding="utf-8"))
        except Exception:  # noqa: BLE001
            pass
    return {"version": 1, "lines": {}}


def min_slot(sources: list):
    """The tightest positive slot of a line's sources (seconds), or None."""
    slots = [float(s["slot"]) for s in sources if s.get("slot") not in (None, 0) and float(s["slot"]) > 0]
    return min(slots) if slots else None


def fit_speed(duration: float, slot, speed: float, base: float, cap: float = FIT_MAX) -> float:
    """Speed that brings `duration` (rendered at `speed`) to FIT_AIM of `slot`, capped at base * cap (FIT_MAX by
    default). Returns `speed` unchanged when the line already fits (or has no slot). Kokoro's length is ~ 1 / speed."""
    if not slot or duration <= slot + FIT_MARGIN:
        return speed
    want = speed * duration / (slot * FIT_AIM)
    return round(min(want, base * cap), 3)


def same_render(prev, cfg: dict, e: dict, path: Path) -> bool:
    """The manifest entry still matches: voice, cast speed (entries before speed-fit have no cast_speed: their
    speed is the cast speed), text hash, file present."""
    if not prev:
        return False
    cast_speed = float(prev.get("cast_speed", prev.get("speed", 0)))
    return (prev.get("voice") == cfg["voice"] and cast_speed == cfg["speed"]
            and prev.get("text_hash") == e["text_hash"] and path.exists())


def generate(opts: dict) -> int:
    t_all = time.perf_counter()
    idx = extract()
    cast = load_cast()
    man = load_manifest()
    old = man.get("lines", {})
    force = opts.get("force", "0") in ("1", "true", "yes")
    only = opts.get("only", "")
    # fit=1 (default): new / changed lines are sped up to fit their slot. fit=all: also re-render existing lines
    # that overrun (opt-in: it changes WARNed WAVs). fit=0: off.
    fit = opts.get("fit", "1")
    # Batches (2026-10-07): match=<regex> renders only lines with a source path matching it (e.g.
    # "mission_e2_0[1-5]"), limit=<n> at most n lines this run; the rest stay as they are (re-run for the next batch).
    # fit_max=<x> lowers the speed-fit cap below FIT_MAX for this run (e.g. 1.2).
    match = re.compile(opts["match"]) if opts.get("match") else None
    limit = int(opts.get("limit", "0") or 0)
    fit_cap = min(FIT_MAX, float(opts.get("fit_max", FIT_MAX)))
    todo, kept, new_lines, refit = [], 0, {}, 0
    for e in idx["lines"]:
        cfg = voice_of(cast, e["speaker"])
        path = AUDIO_DIR / e["speaker"] / (e["id"].split("/", 1)[1] + ".wav")
        prev = old.get(e["id"])
        same = same_render(prev, cfg, e, path)
        overrun = same and fit == "all" and "fit" not in prev and fit_speed(
            float(prev.get("duration", 0)), min_slot(e["sources"]), 1.0, 1.0) != 1.0
        skip = (only and e["speaker"] != only) \
            or (match and not any(match.search(str(s.get("source", ""))) for s in e["sources"])) \
            or (limit and len(todo) >= limit)
        if (same and not force and not overrun) or skip:
            if prev:
                new_lines[e["id"]] = dict(prev, sources=e["sources"])
                kept += 1
            continue
        refit += 1 if overrun else 0
        todo.append((e, cfg, path))
    eng = None
    gen_s, audio_s, fitted = 0.0, 0.0, []
    if todo:
        eng = Engine()
        print(f"VOICE_FORGE providers {eng.providers} (model load {eng.load_s:.1f} s); rendering {len(todo)} lines, "
              f"{kept} unchanged" + (f", {refit} re-fitted (fit=all)" if refit else ""))
        for n, (e, cfg, path) in enumerate(todo, 1):
            t0 = time.perf_counter()
            dr = direction(e["text"])
            base = round(cfg["speed"] * dr["speed"], 4)
            rcfg = dict(cfg, speed=base)
            s = eng.render(e["text"], rcfg)
            slot = min_slot(e["sources"])
            first = len(s) / SR
            if fit != "0":
                for _ in range(2):   # one step usually lands; the second corrects Kokoro's non-linear timing
                    sp = fit_speed(len(s) / SR, slot, rcfg["speed"], base, fit_cap)
                    if sp == rcfg["speed"]:
                        break
                    rcfg = dict(rcfg, speed=sp)
                    s = eng.render(e["text"], rcfg)
            info = write_wav(path, s)
            dt = time.perf_counter() - t0
            gen_s += dt
            audio_s += info["duration"]
            entry = {"speaker": e["speaker"], "text": e["text"], "text_hash": e["text_hash"],
                     "path": "res://" + rel(path), "voice": cfg["voice"], "speed": rcfg["speed"],
                     "cast_speed": cfg["speed"], "lang": cfg["lang"], **info, "gen_s": round(dt, 2),
                     "sources": e["sources"]}
            if dr["tags"]:
                entry["direction"] = dr["tags"]
            if rcfg["speed"] != base:
                entry["fit"] = {"slot": slot, "unfitted_s": round(first, 3), "speed_x": round(rcfg["speed"] / base, 3)}
                fitted.append(f"{e['id']} {first:.2f} -> {info['duration']:.2f} s (slot {slot:g} s, x{rcfg['speed'] / base:.2f})")
            print(f"  [{n}/{len(todo)}] {e['id']} {info['duration']:.2f} s in {dt:.1f} s"
                  + (f"  fitted x{rcfg['speed'] / base:.2f} (was {first:.2f} s, slot {slot:g})" if "fit" in entry else "")
                  + (f"  [{', '.join(dr['tags'])}]" if dr["tags"] else ""))
            new_lines[e["id"]] = entry   # (was missing: rendered lines never reached the manifest)
    else:
        print(f"VOICE_FORGE nothing to render ({kept} lines unchanged)")
    orphans = sorted(k for k in old if k not in new_lines)
    total = sum(v["duration"] for v in new_lines.values())
    man = {"version": 1, "generated_by": "tools/voice_forge/voice_forge.py generate", "engine": "kokoro-onnx v1.0",
           "sample_rate": SR, "format": "mono PCM16, trimmed, peak -1 dBFS", "count": len(new_lines),
           "total_seconds": round(total, 2), "orphans": orphans,
           "lines": dict(sorted(new_lines.items()))}
    MANIFEST.write_text(json.dumps(man, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    run = {"rendered": len(todo), "unchanged": kept, "gen_s": round(gen_s, 1), "audio_s": round(audio_s, 1),
           "rtf": round(gen_s / audio_s, 2) if audio_s else None, "wall_s": round(time.perf_counter() - t_all, 1),
           "providers": eng.providers if eng else [], "model_load_s": round(eng.load_s, 1) if eng else 0,
           "total_lines": len(new_lines), "total_audio_s": round(total, 1), "fit": fit, "fitted": fitted,
           "at": time.strftime("%Y-%m-%d %H:%M:%S")}
    out = DOCS / "out" / opts.get("id", "all")
    out.mkdir(parents=True, exist_ok=True)
    prev_run = {}
    if (out / "generate.json").exists():
        try:
            prev_run = json.loads((out / "generate.json").read_text(encoding="utf-8"))
        except Exception:  # noqa: BLE001
            prev_run = {}
    # The speed of the last run that rendered something stays readable after no-op builds.
    run["last_render"] = {k: run[k] for k in ("rendered", "gen_s", "audio_s", "rtf", "providers", "at")} if todo \
        else prev_run.get("last_render", {})
    (out / "generate.json").write_text(json.dumps(run, indent=1) + "\n", encoding="utf-8")
    print(f"VOICE_FORGE generate: {len(todo)} rendered ({len(fitted)} speed-fitted), {kept} unchanged, {len(new_lines)} lines, "
          f"{total / 60:.2f} min audio, gen {gen_s:.1f} s (x{run['rtf']} real time) {run['providers']}")
    return 0


# ------------------------------------------------------------------ audition

def f0_median(s) -> float:
    """Median pitch (Hz) of the voiced 40 ms frames, autocorrelation 60-400 Hz. Rough, for comparing voices."""
    import numpy as np
    w = int(0.04 * SR)
    lo, hi = SR // 400, SR // 60
    vals = []
    rms_all = np.sqrt(np.mean(s ** 2) + 1e-12)
    for i in range(0, len(s) - w, w // 2):
        fr = s[i:i + w] - np.mean(s[i:i + w])
        if np.sqrt(np.mean(fr ** 2)) < rms_all * 0.6:
            continue
        ac = np.correlate(fr, fr, "full")[w - 1:]
        if ac[0] <= 0:
            continue
        seg = ac[lo:hi]
        k = int(np.argmax(seg)) + lo
        if ac[k] / ac[0] > 0.45:
            vals.append(SR / k)
    return float(np.median(vals)) if vals else 0.0


def audition(opts: dict) -> int:
    import soundfile as sf
    cast = load_cast()
    eng = Engine()
    out = DOCS / "auditions"
    out.mkdir(parents=True, exist_ok=True)
    (out / ".gdignore").write_text("", encoding="utf-8")
    rows = []
    t_all = time.perf_counter()
    only = opts.get("only", "")
    for spk, e in cast.get("speakers", {}).items():
        if e.get("alias_of") or (only and spk != only):
            continue
        line = e.get("audition_line") or cast.get("audition_line")
        for cand in e.get("audition", []):
            cfg = {"voice": cand["voice"], "speed": float(cand.get("speed", 1.0)),
                   "lang": cand.get("lang") or lang_of(cand["voice"])}
            t0 = time.perf_counter()
            s = eng.render(line, cfg)
            dt = time.perf_counter() - t0
            vname = cand["voice"] if isinstance(cand["voice"], str) else "+".join(cand["voice"])
            name = f"{spk}__{vname}_x{cfg['speed']:g}.ogg"
            sf.write(str(out / name), s, SR, format="OGG", subtype="VORBIS")
            f0 = f0_median(s)
            rate = len(norm_text(line)) / (len(s) / SR)
            picked = cand["voice"] == e["voice"] and abs(cfg["speed"] - float(e.get("speed", 1.0))) < 1e-6
            rows.append((spk, vname, cfg["speed"], round(len(s) / SR, 2), round(f0), round(rate, 1), picked, name, dt))
            print(f"  {spk:12s} {vname:18s} x{cfg['speed']:<5g} {len(s) / SR:5.2f} s  f0 {f0:5.0f} Hz  "
                  f"{rate:4.1f} ch/s{'  <- picked' if picked else ''}")
    new_rows = [f"| {r[0]} | {r[1]} | {r[2]:g} | {r[3]} | {r[4]} | {r[5]} | {'**yes**' if r[6] else ''} | {r[7]} |"
                for r in rows]
    footer = (f"Last run: {'only=' + only if only else 'all speakers'}, {len(rows)} candidates in "
              f"{time.perf_counter() - t_all:.1f} s on {eng.providers}.")
    md_path = out / "auditions.md"
    old_md = md_path.read_text(encoding="utf-8") if md_path.exists() else ""
    md_path.write_text(merge_auditions(old_md, new_rows, only, list(cast.get("speakers", {})), footer),
                       encoding="utf-8")
    return 0


AUDITION_HEAD = ["# Voice Forge auditions", "",
                 "One line per candidate (`audition_line` in `data/voice/cast.json`), rendered by `run_voice_forge.ps1 "
                 "audition`. f0 = median pitch of the voiced frames (rough), rate = characters per second. OGG, 24 kHz.",
                 "", "| Speaker | Voice | Speed | Length s | f0 Hz | Rate ch/s | Picked | File |",
                 "|---|---|---|---|---|---|---|---|"]


def merge_auditions(old_md: str, new_rows: list, only: str, order: list, footer: str) -> str:
    """auditions.md after a run. only= replaces that speaker's rows and keeps every other speaker's rows as they
    were (before: the whole table was rewritten with one speaker). A full run replaces the table."""
    rows = list(new_rows)
    if only:
        for ln in old_md.splitlines():
            cells = [c.strip() for c in ln.strip().strip("|").split("|")]
            if not ln.startswith("| ") or len(cells) < 8 or cells[0] in ("Speaker", "") or cells[0].startswith("---"):
                continue
            if cells[0] != only:
                rows.append(ln)
    rank = {s: i for i, s in enumerate(order)}
    rows.sort(key=lambda ln: rank.get(ln.strip("| ").split(" |")[0].strip(), len(rank)))   # stable: keeps each speaker's order
    return "\n".join(AUDITION_HEAD + rows + ["", footer]) + "\n"


def selftest() -> int:
    """No Kokoro, no files written: direction tags, speed-fit, manifest compatibility, auditions merge."""
    fails = []

    def need(ok, what):
        if not ok:
            fails.append(what)

    d = direction("[scared] We are not alone, Vessa. Stay close.")
    need(d["tags"] == ["scared"] and d["speed"] == 0.94, f"scared tag/speed: {d}")
    need(d["text"].startswith("We... we are not alone... Vessa."), f"scared text: {d['text']}")
    need(direction("[angry] Get out.")["text"] == "Get out!", f"angry end: {direction('[angry] Get out.')}")
    d = direction("Wait [pause] listen.")
    need(d["text"] == "Wait... listen." and d["speed"] == 1.0, f"inline pause: {d}")
    d = direction("[mumble] Hello there.")
    need(d["unknown"] == ["mumble"] and d["text"] == "Hello there.", f"unknown tag: {d}")
    plain = "The Master is gone. His crown is NOT."
    need(direction(plain)["text"] == norm_text(plain) and spoken_text(plain) == "The Master is gone. His crown is not.",
         "untagged line changed")
    need(line_key("malrik", "[sad] Gone.") != line_key("malrik", "Gone."), "tag not part of the key")
    # Speed-fit: 6 s at x1.0 into a 5 s slot -> 6 / 4.8 = 1.25 (cap); fits already -> unchanged; no slot -> unchanged.
    need(fit_speed(5.3, 5.0, 1.0, 1.0) == round(5.3 / 4.8, 3), f"fit 5.3/5: {fit_speed(5.3, 5.0, 1.0, 1.0)}")
    need(fit_speed(8.0, 5.0, 1.1, 1.1) == round(1.1 * FIT_MAX, 3), "fit cap")
    need(fit_speed(5.04, 5.0, 1.0, 1.0) == 1.0 and fit_speed(9.0, None, 1.0, 1.0) == 1.0, "fit when it fits / no slot")
    need(min_slot([{"slot": None}, {"slot": 3.2}, {"slot": 5.0}]) == 3.2, "min_slot")
    # Manifest entries written before speed-fit (no cast_speed) still count as unchanged.
    e = {"text_hash": "abc"}
    p = Path(__file__)
    need(same_render({"voice": "af_heart", "speed": 1.12, "text_hash": "abc"}, {"voice": "af_heart", "speed": 1.12}, e, p),
         "old entry re-rendered")
    need(same_render({"voice": "af_heart", "speed": 1.3, "cast_speed": 1.12, "text_hash": "abc", "fit": {}},
                     {"voice": "af_heart", "speed": 1.12}, e, p), "fitted entry re-rendered")
    need(not same_render({"voice": "af_heart", "speed": 1.12, "text_hash": "abc"}, {"voice": "af_heart", "speed": 1.0}, e, p),
         "cast speed change not seen")
    # Auditions: only= keeps the other speakers' rows.
    old = merge_auditions("", ["| vessa | af_heart | 1.12 | 3 | 220 | 15 | **yes** | a.ogg |",
                               "| hush | af_sky | 1 | 2 | 200 | 14 |  | b.ogg |"], "", ["vessa", "hush"], "x")
    new = merge_auditions(old, ["| hush | af_nova | 1 | 2 | 210 | 14 |  | c.ogg |"], "hush", ["vessa", "hush"], "y")
    need("a.ogg" in new and "c.ogg" in new and "b.ogg" not in new and new.index("a.ogg") < new.index("c.ogg"),
         f"auditions merge:\n{new}")
    if fails:
        print("FAIL voice_forge selftest: " + " | ".join(fails))
        return 1
    print("PASS voice_forge selftest (direction tags, speed-fit, manifest compat, auditions merge)")
    return 0


def main(argv: list) -> int:
    if not argv:
        print(__doc__)
        return 0
    verb = argv[0]
    opts = dict(a.split("=", 1) for a in argv[1:] if "=" in a)
    if verb == "extract":
        idx = extract()
        for n in idx["notes"]:
            print("  " + n)
        print(f"VOICE_FORGE extract: {idx['count']} unique lines -> {rel(INDEX)}")
        return 0
    if verb == "generate":
        return generate(opts)
    if verb == "audition":
        return audition(opts)
    if verb == "selftest":
        return selftest()
    print(f'unknown verb "{verb}" -> extract | generate | audition | selftest')
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
