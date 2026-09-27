# Voice Forge: every spoken line of the game, voiced by Kokoro

Owner: the Voice Forge agent. Owns `tools/voice_forge/`, `assets/audio/voice/`, `data/voice/`,
`docs/tools/voice_forge/`, `tests/test_tool_voice_forge.gd` (+ `scripts/ui/voice_player.gd`, in ui-coder's folder).
Rules: `docs/plan/tools-wave.md` section 0 (text in, report out, deterministic names, history row).

## One CLI
```powershell
.\tools\voice_forge\run_voice_forge.ps1 help
.\tools\voice_forge\run_voice_forge.ps1 check                 # extract + report, no rendering (< 60 s)
.\tools\voice_forge\run_voice_forge.ps1 build [force=1] [only=vessa]   # extract + render new / changed + --import + report
.\tools\voice_forge\run_voice_forge.ps1 demo                  # acceptance demo = build + report (all lines voiced, 0 FAIL)
.\tools\voice_forge\run_voice_forge.ps1 audition [only=hush]  # cast candidates -> docs/tools/voice_forge/auditions/
.\tools\voice_forge\run_voice_forge.ps1 build fit=all         # also re-render existing lines that overrun their slot
```
`build` options: `fit=1` (default) speeds a **new / changed** line up (at most x1.25 over its cast speed) until it fits
its slot (<= slot + 0.05 s, aim 96 %); `fit=all` also re-renders existing overrunning lines (opt-in: it changes WARNed
WAVs); `fit=0` off. Unchanged lines are never touched. The manifest keeps `speed` (rendered), `cast_speed` (cast.json,
what "changed?" compares) and `fit: {slot, unfitted_s, speed_x}`. `audition only=<speaker>` replaces that speaker's
rows in `auditions.md` and keeps every other speaker's rows. `voice_forge.py selftest` (no Kokoro) checks tags, fit,
manifest compatibility and the auditions merge; `tests/test_tool_voice_forge.gd` runs it when the venv exists.

## Direction tags (U4, 2026-09-27)
Write them in the line's text: `[scared] We are not alone, Vessa.` or inline `Wait [pause] listen.` The tag stays in
the keyed text (the subtitle lookup is unchanged); only what Kokoro reads changes (`DIRECTIONS` in voice_forge.py):

| Tag | Speed | Text |
|---|---|---|
| `[scared]`, `[hesitant]` | x0.94 / x0.95 | first word stuttered ("We... we are"), `,` / `;` / ` - ` become `...` |
| `[stutter]` | - | first word stuttered |
| `[whisper]`, `[sad]`, `[tired]` | x0.9 / x0.88 / x0.9 | pauses (`...`) |
| `[slow]`, `[calm]`, `[fast]` | x0.88 / x0.95 / x1.12 | - |
| `[excited]`, `[angry]`, `[shout]` | x1.1 / x1.06 / x1.05 | the final `.` becomes `!` |
| `[pause]` (inline) | - | a `...` break there |

Unknown tags are stripped and listed in the extract notes (report). Manifest entries of tagged lines carry
`direction: [tags]`. The subtitle shows the tag unless the DialogueBox strips `[...]` (ui-coder handoff).

## Loudness per speaker
The Audio Lab judges the voice WAVs per speaker (group "speech": median LUFS per speaker, speakers within 3 dB,
lines within 4 dB of their speaker): `$GODOT --headless --path . -s tools/audio_lab/audio_lab.gd --quit-after 600 --
set=res://assets/audio/voice name=voice log=0`.
Exit 0 PASS / WARN, 1 FAIL, 2 bad input. Report: `docs/tools/voice_forge/out/<id>/report.md` (+ `report.json`,
`generate.json` = speed of the last render), history row in `docs/tools/voice_forge/history.md`. `strict=1` makes slot
overruns FAIL.

## How it works
1. **Extract** (`voice_forge.py extract`) finds every spoken line -> `data/voice/lines_index.json`:
   - missions: `const *DIALOGUE* := [[&"speaker", "text"], ...]` and literal `emit_signal(&"dialogue", &"x", "...")` /
     `dialogue.emit(&"x", "...")` in `scripts/campaign/` and `missions/` (slot = DialogueBox `LINE_SECONDS`);
   - cinematics: `at <t> line <speaker> "<text>"` in `data/cinematics/src/*.cine` (slot = up to the next line or the
     shot end, or `dur=`); `*_bugs.cine` fixtures skipped; LineTrack files `data/story/*.lines.json`;
   - Episode 3 / 4 openings: the section 3 tables of `docs/design/episode3-4-opening.md` are rewritten to
     `data/voice/lines/ep3_opening.json` / `ep4_opening.json` (slot = `dur`); any `data/voice/lines/*.json`
     (`{cine_id, lines: [{id, speaker, text, dur}]}`) is read too — add hand-made line sets there.
2. **Render** (`generate`, Kokoro v1.0 ONNX, venv outside the repo: `$env:FW_VOICE_HOME`, default
   `..\four-wizards-voice`): voice + speed from `data/voice/cast.json`. File =
   `assets/audio/voice/<speaker>/<first_words>_<sha256(speaker\ntext)[:8]>.wav`, mono 24 kHz PCM16, silence trimmed
   (40 ms / 90 ms kept), 8 ms fades, peak -1 dBFS. A line is re-rendered only when its text, its speaker's voice or
   speed changed, or `force=1`. Capital words are read as words ("NOT" -> "not").
3. **Manifest** `data/voice/manifest.json`: `id -> {speaker, text, text_hash, path, duration, peak, rms_db, voice,
   speed, sources: [{kind, source, ref, slot, speaker_id}]}` + `orphans` (entries whose source line is gone).
4. **Check** (Godot, `voice_forge_main.gd`): cast / index / manifest valid, every line has an imported WAV, every
   mission line voiced, voice length vs slot, format, clipping, peak, trim, size, hookup present.

## Cast (`data/voice/cast.json`)
`speakers.<id> = {voice, speed, notes, audition_line?, audition: [{voice, speed}]}`. `voice` = a Kokoro id
(`af_` / `am_` American F / M, `bf_` / `bm_` British F / M; British ids speak `en-gb`) or a blend `{"bm_daniel": 0.6,
"bm_lewis": 0.4}`. `alias_of` shares a voice (`torren` -> `vey`). Unknown speakers use `default_speaker`.
Auditions: `docs/tools/voice_forge/auditions/auditions.md` (length, median pitch, chars/s per candidate; OGG files).

## In game
`scripts/ui/voice_player.gd` (`VoicePlayer`), added under the mission DialogueBox by `MissionHud` (load-guarded):
plays a line's WAV when the box shows it; no WAV = silent. API: `play_line(speaker, text) -> bool`, `has_line`,
`line_duration`, `enabled`, signal `voice_started(speaker, text, path)`. Cinematics can use the manifest the same way
(handoff in `docs/handoff/for-systems-coder.md`).

## Speed
CPU only (onnxruntime 1.30). DirectML (`onnxruntime-directml` 1.24) was tried: the Kokoro graph fails on it
(`ConvTranspose` in `/encoder/F0.1/pool`, "parameter is incorrect"), so the venv was put back to the CPU build.
