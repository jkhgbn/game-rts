# Audio Lab scorecard: voice

- Date: 2026-09-27 14:14:54
- Command: `godot --headless --path . -s tools/audio_lab/audio_lab.gd -- set=res://assets/audio/voice name=voice log=0`
- set: `res://assets/audio/voice`, kind `auto`, 0 cues, 0 players judged
- Missing cues are listed for context but not scored (set is not the whole game; use scene= or set=res://assets/audio).

## Score: 83 / 100

PASS 10 | WARN 5 | FAIL 0 | INFO 0

| Group | Weight | PASS | WARN | FAIL | INFO | Group score |
|---|---|---|---|---|---|---|
| Spoken lines (Voice Forge, per speaker) | 10 | 10 | 5 | 0 | 0 | 83 % |

## Improve next

1. **WARN Spoken lines (Voice Forge, per speaker)** - Level the speaker (a per-speaker gain in voice_forge.py finish_audio, or VoicePlayer volume per speaker).  _(ashby -3 dB, malrik -2 dB, narrator +3 dB; speaker median -24..-14 LUFS, within 3 dB of the others)_
2. **WARN Spoken lines (Voice Forge, per speaker)** - Voice Forge normalises to -1 dBFS; a higher decoded peak = import overshoot (import the voice folder as PCM).  _(master peak, ysolde peak; voice true peak <= -0.5 dBTP)_
3. **Listen in context** - run the preview (tools/audio_lab/audio_lab_preview.tscn) and fill the listening sheet; numbers can't judge taste.

## Checks

### Spoken lines (Voice Forge, per speaker)

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| WARN | ashby | median -11.9 LUFS (+3.3 dB vs all speakers -15.2), 3 lines -12.5..-11.5, 6 s, peak -0.8 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others | Level the speaker (a per-speaker gain in voice_forge.py finish_audio, or VoicePlayer volume per speaker). |
| WARN | malrik | median -13.5 LUFS (+1.7 dB vs all speakers -15.2), 19 lines -15.8..-11.7, 80 s, peak -0.8 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others | Level the speaker (a per-speaker gain in voice_forge.py finish_audio, or VoicePlayer volume per speaker). |
| WARN | master peak | -0.4 dBTP | voice true peak <= -0.5 dBTP | Voice Forge normalises to -1 dBFS; a higher decoded peak = import overshoot (import the voice folder as PCM). |
| WARN | narrator | median -18.5 LUFS (-3.4 dB vs all speakers -15.2), 4 lines -20.0..-16.6, 17 s, peak -0.7 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others | Level the speaker (a per-speaker gain in voice_forge.py finish_audio, or VoicePlayer volume per speaker). |
| WARN | ysolde peak | -0.5 dBTP | voice true peak <= -0.5 dBTP | Voice Forge normalises to -1 dBFS; a higher decoded peak = import overshoot (import the voice folder as PCM). |
| PASS | dancer | median -16.6 LUFS (-1.5 dB vs all speakers -15.2), 1 lines -16.6..-16.6, 2 s, peak -0.9 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | master | median -17.0 LUFS (-1.9 dB vs all speakers -15.2), 30 lines -18.7..-14.1, 124 s, peak -0.4 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | messenger | median -15.4 LUFS (-0.3 dB vs all speakers -15.2), 11 lines -18.5..-12.5, 16 s, peak -0.8 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | pell | median -15.8 LUFS (-0.7 dB vs all speakers -15.2), 1 lines -15.8..-15.8, 6 s, peak -1.0 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | reveler | median -15.3 LUFS (-0.2 dB vs all speakers -15.2), 1 lines -15.3..-15.3, 2 s, peak -0.8 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | shade | median -15.0 LUFS (+0.2 dB vs all speakers -15.2), 1 lines -15.0..-15.0, 2 s, peak -0.9 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | vessa | median -14.9 LUFS (+0.3 dB vs all speakers -15.2), 20 lines -18.2..-10.9, 44 s, peak -0.6 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | vey | median -14.7 LUFS (+0.4 dB vs all speakers -15.2), 3 lines -14.7..-14.2, 8 s, peak -0.8 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | ysolde | median -14.2 LUFS (+1.0 dB vs all speakers -15.2), 14 lines -16.1..-11.4, 52 s, peak -0.5 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | lines vs their speaker | 0 / 108 lines off by > 4 dB | every line within 4 dB of its speaker's median (FAIL > 8) |  |

## Cue table

| Cue | Cat | Mode | In game | File | Vol dB | 3D dB | TP dBTP | Dur s | Lead / trail ms | Bands L/M/P/A % | Rate /min | Takes | Pitch | Source |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|

In game = file loudness (cue: 200 ms max; music / ambience: integrated) + the code's volume_db + 3D loss at 30 m (default zoom), on 0 dB buses. `*` = frequent (>= 20 plays / min). Rates are expected (lab table; `fight=1` measures them).

## Targets (lab_rules.gd LOUDNESS)

| Category | Metric | In-game range LUFS | Frequent range | Why |
|---|---|---|---|---|
| ui | cue | -30..-14 | -36..-20 | clear but polite: never louder than an alert, audible over the music |
| unit | cue | -30..-16 | -36..-22 | combat bed: hits, shots, deaths; many at once, so each one moderate |
| spell | cue | -22..-9 | - | hero actions read above the combat bed |
| alert | cue | -22..-7 | - | must cut through a battle (level up, capture, raid, stingers) |
| ambience | integrated | -36..-26 | - | a bed under everything, well below the music |
| music | integrated | -26..-18 | - | the mix anchor (includes GameAudio.MUSIC_DB) |

## What a real replacement needs

- Every file: original or CC0 only (note the source in the file's folder), 16-bit WAV for SFX / Ogg for music, no clipping, trimmed start, faded end.

## Limits

- Loudness is a BS.1770 approximation on the 44.1 kHz decode (dual mono counted as 2 channels, as the game plays it); true peak is a 4x interpolation estimate.
- Masking uses 4 bands and a synthetic battle bed (6 unit cues at once), not a real mix; listen in the preview.
- Code facts come from patterns (DIR / DICT / PATH consts, `*.new()` players) and, for scene=, the live players; a sound played in an unusual way can be missed.
- Numbers can't judge taste, timbre or meaning: fill the listening sheet.
