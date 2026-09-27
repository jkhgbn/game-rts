# Audio Lab

The Art Lab idea for sound (waves.md, "Audio Lab" note). One command per sound set or scene. It measures every cue,
reads how the code plays it, lists the gameplay events that have no sound, and writes a scorecard: PASS / WARN / FAIL
with the measured value, the rule and a fix hint, a 0-100 score, and an "Improve next" list (always at least 3 items).
It also writes a listening sheet and the cue list for a windowed preview scene, where a human listens to each cue
over a staged fight.

Everything runs headless. The Dummy audio driver plays nothing, so the lab decodes each stream itself with
`AudioStreamPlayback.mix_audio()`. That is the game's own decoder (PCM, IMA-ADPCM, QOA, Ogg, MP3), running at 44.1 kHz.

## Files

| File | What |
|---|---|
| `tools/audio_lab/audio_lab.gd` | Entry point (`-s`). Parses the arguments, runs the scene (scene=), stages the fight, analyses, writes. |
| `tools/audio_lab/lab_rules.gd` | **Every threshold and table**: per-category loudness targets, silence / duration, spectral, masking, memory, 3D, voices, variation, key events, listening prompts, "real replacement" specs, score weights. Tune here only. |
| `tools/audio_lab/lab_signal.gd` | Decodes and measures: BS.1770 loudness (integrated + 200 ms "cue" loudness + 400 ms momentary), sample and 4x true peak, clipping, DC, lead / trail silence, decay, end level, loop seam, dual mono, 4-band energy split (LR4 filters). |
| `tools/audio_lab/lab_code.gd` | Static code scan: audio scripts, cue registry (DIR / DICT / PATH / LITERAL patterns), players and their bus / 3D settings, play functions (2D / 3D, pitch / volume randomisation), signal connections and whether their handler plays a sound, takes, generator detection, event coverage. |
| `tools/audio_lab/lab_report.gd` | Checks, score, Improve next, writes `scorecard.md`, `scorecard.json`, `listening_sheet.md`, `preview_cues.json` and the improvement log. |
| `tools/audio_lab/audio_lab_preview.tscn` / `.gd` | Windowed listening room (see "Listening"). |
| `tests/test_audio_lab.gd` | Known signals (a -6 dBFS sine, a clipped tone), rules, code scan facts, a broken cue that must FAIL, report files, preview plays. |
| `docs/audio/lab/<name>/` | One folder per run: `scorecard.md` / `.json`, `listening_sheet.md`, `preview_cues.json`. |
| `docs/audio/lab/improvement-log.md` | Each run adds one entry: set, score, counts, top 3 suggestions. |

## Run

`$GODOT` = the Godot gate `tools\godot_run.ps1` (same arguments as the console exe `C:\Godot\...console.exe`; in
PowerShell write `& tools\godot_run.ps1 ... '--' set=...` with the `--` quoted). Always pass `--quit-after`.

```
# A folder (recursive) or a file prefix
$GODOT --headless --path . -s tools/audio_lab/audio_lab.gd --quit-after 600 -- set=res://assets/audio/sfx
$GODOT --headless --path . -s tools/audio_lab/audio_lab.gd --quit-after 600 -- set=res://assets/audio/mapfill_ name=mapfill
# Everything (also scores the missing cues)
$GODOT --headless --path . -s tools/audio_lab/audio_lab.gd --quit-after 600 -- set=res://assets/audio
# A scene: runs it, lists the players it really creates, stages a 12 v 12 fight near the hero to measure play rates and voices
$GODOT --headless --path . -s tools/audio_lab/audio_lab.gd --fixed-fps 60 --quit-after 12000 -- scene=res://scenes/skirmish.tscn fight=1
```

Arguments (after `--`): `set=`, `scene=`, `kind=ui|unit|spell|ambience|music|alert|auto` (default auto: a category
per cue from `lab_rules.gd`), `out=` (default `docs/audio/lab/<name>/`), `name=`, `live=0` (scene= without running
it), `fight=1`, `fight_s=30`, and `log=0` (no log entry: use it for tests and experiments). The last line printed is
`AUDIO_LAB score=N pass=N warn=N fail=N info=N cues=N out=DIR`. A set run takes about 20 s for the whole
`assets/audio` folder. A skirmish run takes 1-3 minutes.

## Checks and thresholds (all in `lab_rules.gd`)

"In game" level = the file's loudness + the `volume_db` the code sets + the 3D distance loss at 30 m (the RTSCamera
default zoom), with the buses at 0 dB. Cue loudness = the maximum K-weighted loudness over any 200 ms window.
Music and ambience use integrated loudness.

| Group (weight) | Check | PASS | WARN | FAIL |
|---|---|---|---|---|
| Loudness (18) | in-game level vs category range | inside | up to 6 LU outside | more |
| | ui -30..-14, unit -30..-16, spell -22..-9, alert -22..-7 (cue); ambience -36..-26, music -26..-18 (integrated) | | | |
| | frequent cues (>= 20 plays/min) of ui / unit: range - 6 LU | | | |
| | families (`death_*`, `ping_*`) within 3 dB | | spread > 3 | |
| Peaks (10) | true peak / clipping / DC | <= -1 dBTP | -1..-0.1 dBTP, DC > 0.01 | > -0.1 dBTP or clipped |
| Duration (8) | lead silence | <= 10-20 ms (by category) | up to 60 ms | > 60 ms |
| | trailing silence (GameAudio keeps a voice busy for the whole stream) | <= 150 ms | up to 600 ms | more |
| | length: ui <= 0.8 s, unit <= 1.5, spell <= 2.5, alert <= 3.5; loops: music >= 60 s, ambience >= 20 s | | outside | |
| | abrupt end (last 10 ms > -45 dB), start pop (first sample > 0.1), loop seam jump > 0.05, frequent tail > 500 ms | | WARN | |
| Spectral (10) | all-bass (>= 85 % under 250 Hz), all-hiss (>= 60 % over 6 kHz), UI thin (< 2 % over 2 kHz) | | WARN | |
| | alert masking: best band margin over a battle bed of 6 unit cues | >= +3 dB | -6..+3 dB | < -6 dB |
| Memory (5) | sample rate < 22.05 kHz | | | FAIL |
| | stereo file on a 3D player, SFX file > 1 MB (music > 16 MB), set > 48 MB in memory, file nothing plays (orphan) | | WARN | SFX > 4 MB |
| Bus (12) | every AudioStreamPlayer* (code, .tscn, live) on a bus GameSettings creates (SFX, Music) | allowed | unresolved | Master / unknown |
| Variation (10) | frequent non-UI cues: >= 3 takes, or 2 takes + randomisation | ok | 1 take + pitch >= +-3 % | 1 take, no randomisation |
| 3D (5) | unit_size >= 5, max_distance 20-150, <= -10 dB at the cut-off, >= -15 dB at 30 m, no doppler | ok | WARN | |
| Voices (7) | players <= 64, 3D pool <= 32, every frequent cue has a cooldown >= 0.03 s | ok | pool | no cooldown |
| | fight=1: all 3D voices busy <= 20 % of frames, dropped <= 25 %, fight >= 40 plays (else the expected rates are used) | | WARN | |
| Missing cues (15) | `KEY_EVENTS` (unit death, spell cast, capture, camp cleared, beast spawn, trade arrival, level up, UI click, alerts...): signal connected in an audio script to a handler that plays | covered | core event only partly covered / not in the game yet | core event whose signal exists has no sound |

Non-core events with no sound are INFO ("nice to have"). INFO is never scored. Missing cues are scored only for
`scene=` runs and for the whole `res://assets/audio`. Score = weighted mean of the group scores (PASS 1, WARN 0.5,
FAIL 0), minus 2 points per FAIL (at most 20).

Play rates: a fight=1 run measures them when the fight is big enough. Otherwise they come from `EXPECTED_RATE`,
or from the cooldown (unit cues with a cooldown <= 0.1 s count as 60/min).

## Validation on the current placeholders (2026-09-26)

All 39 files are generated tones (tools/generate_sfx.gd, trade / mapfill generators). The thresholds were tuned so
that the clean ones PASS. Real findings:

- **trade_whistle clips** (+1.4 dBTP, 3 clipped runs): FAIL.
- **mapfill_splash** is inaudible at the default zoom: -18 dB volume, unit_size 10, so about -44 LUFS in game at
  30 m. It is also a frequent cue with one take and no randomisation. FAIL x2.
- **Champion abilities** (`ability_cast` / `skill_hit`) and **"your wizard has fallen"** (`wizard_fell`) have no
  sound: FAIL. The "under attack" alert does not exist yet (design gap): WARN.
- Frequent combat cues have one take plus pitch +-7 %: WARN (they need 3-5 takes). `death_shadow` is 3.4 dB louder
  than `death_fire`. `mine_tick` is very low, `crystals_delivered` / `item_*` are a little hot.
- Both music loops are shorter than 60 s and have a loop-seam click (the last sample is 0.27-0.31). `defeat` ends
  abruptly.
- The alerts `unit_trained`, `construction_done`, `mapfill_drum` and `mapfill_roar` barely beat a battle bed.
- Sine placeholders are spectrally narrow. 6 cues are all-bass (`mapfill_drum` / `horn` / `roar`,
  `building_hit` / `collapse`, `spell_umbral_shroud`) and 3 UI cues are thin (`ui_click`, `item_used`,
  `mapfill_bubble`). This is what real recordings fix.

Scores:

| Run | Score | PASS | WARN | FAIL |
|---|---|---|---|---|
| all_audio | 84 | 333 | 33 | 5 |
| skirmish (fight=1) | 84 | 380 | 33 | 5 |
| sfx | 95 | 242 | 22 | 0 |
| mapfill | 89 | 86 | 4 | 2 |
| trade | 94 | 53 | 0 | 1 |
| music | 96 | 39 | 4 | 0 |

The skirmish fight measured 66 plays in 30 s, 0 dropped, peak 4 of 16 voices.

Scorecards are in `docs/audio/lab/{all_audio,sfx,mapfill,trade,music,skirmish}/`.

## v1.1 (2026-09-27 lab review, group C)

- **Takes fold into their parent cue**: `<id>_N.wav` / `<id>_a.wav` next to `<id>.wav` gets the parent's volume_db,
  3D settings, category, play rate (so the frequent-cue range) and takes count. Before, takes were judged as separate
  cues at `vol -` / no 3D loss (8 takes measured 8-12 dB too loud in game) and each got its own variation row.
  Variation is judged once, on the parent. New check **"<id> takes"**: the takes' in-game levels within
  `TAKE_TOL` 2 dB (a random pick must not jump out).
- **Categories**: `alert_wizard_fell` / `wizard_fell` = alert, `ability_cast` = spell, `skill_hit` = unit
  (`CATEGORY_BY_ID`).
- **Import overshoot measured**: for QOA / IMA-ADPCM imports the lab reads the source .wav peak (8 / 16 / 24-bit PCM)
  and prints it next to the decoded true peak ("source -0.4 dBFS (QOA import +0.2 dB)"). >= `IMPORT_OVERSHOOT_DB`
  1 dB = WARN "import as PCM / IMA-ADPCM"; a peak WARN whose cause is the file itself says so (normalise the file), so
  the hint no longer blames QOA when it is innocent. All 52 files import as QOA today; measured overshoot <= +0.6 dB.
- Result `set=res://assets/audio`: 98 / 100, PASS 460, WARN 21, FAIL 0 (`docs/audio/lab/review_after/`). New real
  findings (handoff `docs/handoff/for-ui-coder.md`): `building_hit` takes 5.1 dB apart; `ability_cast` 3 dB under
  the spell range; the 3 peak WARNs are in the source files (normalise to -1 dBTP).

## Rule to add (for every audio agent: ui-coder on assets/audio, future sound agents)

> **Audio Lab.** When you add or change sounds, run
> `$GODOT --headless --path . -s tools/audio_lab/audio_lab.gd --quit-after 600 -- set=<your folder or prefix>`
> (and `scene=res://scenes/skirmish.tscn fight=1` when you change GameAudio or a popups script). Fix every FAIL.
> Fix the WARNs you can, or explain them. Apply the top "Improve next" item. Report the score before / after
> (docs/audio/lab/improvement-log.md shows both). Attach `scorecard.md`. Listen to your cues in
> `tools/audio_lab/audio_lab_preview.tscn` and fill the listening sheet. End with "Audio Lab notes": what the lab
> got wrong or missed, so the lead can improve it (same loop as the Art Lab). Original / CC0 audio only.

## Listening

`godot --path . res://tools/audio_lab/audio_lab_preview.tscn -- cues=res://docs/audio/lab/<name>/preview_cues.json`
opens a window with the camera 30 m away:

- **battle** context: 8 3D voices, 4-14 m around the focus, fire the set's unit cues (pitch +-7 %, their volumes).
  Keys 1-3 set the intensity.
- **ui** context: the music on the Music bus.
- **map** context: a generated wind bed.

Keys:

| Key | Action |
|---|---|
| Right / Left | next / previous cue (and play it) |
| Space | play again |
| A | auto-play all |
| B | battle bed on / off |
| M | music on / off |
| Esc | quit |

Fill `listening_sheet.md` (verdict + notes per cue).

## Limits / next steps

- Loudness is a BS.1770 approximation at 44.1 kHz (dual mono = 2 channels, as the game plays it). True peak is a
  4x interpolation estimate.
- Masking uses 4 bands and a synthetic bed, not a real mix: the preview is the judge.
- The code scan understands the patterns the game uses today (GameAudio DIR + SOUNDS / COOLDOWNS / VOLUMES,
  popups DICT + PATH consts, `AudioStreamPlayer*.new()` + `.bus =`). A new way of playing sounds needs a branch in
  `lab_code.gd`. scene= also lists the players that really exist at run time.
- The fight=1 staged fight (12 v 12 next to the hero, 30 s, camera culling lifted like test_6_s1) is small: about
  66 plays, peak 4 of 16 voices. It proves the plumbing, but not a late-game pile-up. The first lab improvement to
  make: bigger armies, or a real bot match via the Bot Lab, plus counting the plays blocked by cooldowns inside
  GameAudio.
- No AudioStreamRandomizer is used yet, so the "takes" path is only tested on file names.
- Collect "Audio Lab notes" from the audio agents, then retune `lab_rules.gd`, as with the Art Lab.
