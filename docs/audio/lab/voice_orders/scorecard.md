# Audio Lab scorecard: voice_orders

- Date: 2026-09-27 18:45:44
- Command: `godot --headless --path . -s tools/audio_lab/audio_lab.gd -- set=res://assets/audio/voice name=voice_orders log=0`
- set: `res://assets/audio/voice`, kind `auto`, 0 cues, 0 players judged
- Missing cues are listed for context but not scored (set is not the whole game; use scene= or set=res://assets/audio).

## Score: 82 / 100

PASS 37 | WARN 21 | FAIL 0 | INFO 0

| Group | Weight | PASS | WARN | FAIL | INFO | Group score |
|---|---|---|---|---|---|---|
| Spoken lines (Voice Forge, per speaker) | 10 | 37 | 21 | 0 | 0 | 82 % |

## Improve next

1. **WARN Spoken lines (Voice Forge, per speaker)** - Level the speaker (a per-speaker gain in voice_forge.py finish_audio, or VoicePlayer volume per speaker).  _(aldra -1 dB, ashby -3 dB, malrik -1 dB, narrator +4 dB, shade -1 dB, unit_cinder_hand -1 dB (+10 more); speaker median -24..-14 LUFS, within 3 dB of the others)_
2. **WARN Spoken lines (Voice Forge, per speaker)** - Voice Forge normalises to -1 dBFS; a higher decoded peak = import overshoot (import the voice folder as PCM).  _(master peak, unit_ash_hurler peak, unit_bleakbow peak, ysolde peak; voice true peak <= -0.5 dBTP)_
3. **WARN Spoken lines (Voice Forge, per speaker)** - Re-render the listed lines (a direction tag like [whisper] explains a quiet one: note it in the listening sheet).  _(lines vs their speaker; every line within 4 dB of its speaker's median (FAIL > 8))_

## Checks

### Spoken lines (Voice Forge, per speaker)

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| WARN | lines vs their speaker | 1 / 284 lines off by > 4 dB: unit_rime_hauler/right_ill_have_a_92efb9f7 -4.1 dB | every line within 4 dB of its speaker's median (FAIL > 8) | Re-render the listed lines (a direction tag like [whisper] explains a quiet one: note it in the listening sheet). |
| WARN | ysolde peak | -0.5 dBTP | voice true peak <= -0.5 dBTP | Voice Forge normalises to -1 dBFS; a higher decoded peak = import overshoot (import the voice folder as PCM). |
| WARN | unit_vinelasher | median -13.9 LUFS (+0.7 dB vs all speakers -14.7), 4 lines -16.4..-12.5, 5 s, peak -0.6 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others | Level the speaker (a per-speaker gain in voice_forge.py finish_audio, or VoicePlayer volume per speaker). |
| WARN | unit_thistle_darter | median -13.9 LUFS (+0.7 dB vs all speakers -14.7), 4 lines -14.4..-13.7, 4 s, peak -0.8 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others | Level the speaker (a per-speaker gain in voice_forge.py finish_audio, or VoicePlayer volume per speaker). |
| WARN | unit_scorchling | median -13.4 LUFS (+1.3 dB vs all speakers -14.7), 4 lines -15.2..-12.6, 3 s, peak -0.9 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others | Level the speaker (a per-speaker gain in voice_forge.py finish_audio, or VoicePlayer volume per speaker). |
| WARN | unit_rimeling | median -14.0 LUFS (+0.7 dB vs all speakers -14.7), 4 lines -14.2..-13.6, 4 s, peak -0.8 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others | Level the speaker (a per-speaker gain in voice_forge.py finish_audio, or VoicePlayer volume per speaker). |
| WARN | unit_rime_seer | median -12.6 LUFS (+2.0 dB vs all speakers -14.7), 4 lines -15.3..-12.1, 7 s, peak -1.0 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others | Level the speaker (a per-speaker gain in voice_forge.py finish_audio, or VoicePlayer volume per speaker). |
| WARN | unit_pyre_adept | median -10.8 LUFS (+3.8 dB vs all speakers -14.7), 4 lines -11.6..-10.6, 6 s, peak -0.8 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others | Level the speaker (a per-speaker gain in voice_forge.py finish_audio, or VoicePlayer volume per speaker). |
| WARN | unit_hexweaver | median -12.9 LUFS (+1.7 dB vs all speakers -14.7), 4 lines -13.5..-12.2, 5 s, peak -1.0 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others | Level the speaker (a per-speaker gain in voice_forge.py finish_audio, or VoicePlayer volume per speaker). |
| WARN | unit_frostbow | median -13.5 LUFS (+1.2 dB vs all speakers -14.7), 4 lines -15.1..-12.1, 6 s, peak -0.8 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others | Level the speaker (a per-speaker gain in voice_forge.py finish_audio, or VoicePlayer volume per speaker). |
| WARN | unit_frost_mortar | median -12.9 LUFS (+1.8 dB vs all speakers -14.7), 4 lines -14.8..-12.3, 7 s, peak -0.9 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others | Level the speaker (a per-speaker gain in voice_forge.py finish_audio, or VoicePlayer volume per speaker). |
| WARN | unit_flame_guard | median -12.7 LUFS (+1.9 dB vs all speakers -14.7), 7 lines -14.6..-11.4, 13 s, peak -0.9 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others | Level the speaker (a per-speaker gain in voice_forge.py finish_audio, or VoicePlayer volume per speaker). |
| WARN | unit_cinder_hand | median -13.7 LUFS (+0.9 dB vs all speakers -14.7), 4 lines -14.4..-12.2, 4 s, peak -0.9 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others | Level the speaker (a per-speaker gain in voice_forge.py finish_audio, or VoicePlayer volume per speaker). |
| WARN | unit_bleakbow peak | -0.5 dBTP | voice true peak <= -0.5 dBTP | Voice Forge normalises to -1 dBFS; a higher decoded peak = import overshoot (import the voice folder as PCM). |
| WARN | aldra | median -13.3 LUFS (+1.3 dB vs all speakers -14.7), 2 lines -14.7..-11.9, 4 s, peak -0.9 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others | Level the speaker (a per-speaker gain in voice_forge.py finish_audio, or VoicePlayer volume per speaker). |
| WARN | ashby | median -11.9 LUFS (+2.8 dB vs all speakers -14.7), 3 lines -12.5..-11.5, 6 s, peak -0.8 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others | Level the speaker (a per-speaker gain in voice_forge.py finish_audio, or VoicePlayer volume per speaker). |
| WARN | malrik | median -13.5 LUFS (+1.2 dB vs all speakers -14.7), 19 lines -15.8..-11.7, 80 s, peak -0.8 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others | Level the speaker (a per-speaker gain in voice_forge.py finish_audio, or VoicePlayer volume per speaker). |
| WARN | master peak | -0.4 dBTP | voice true peak <= -0.5 dBTP | Voice Forge normalises to -1 dBFS; a higher decoded peak = import overshoot (import the voice folder as PCM). |
| WARN | narrator | median -18.5 LUFS (-3.9 dB vs all speakers -14.7), 4 lines -20.0..-16.6, 17 s, peak -0.7 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others | Level the speaker (a per-speaker gain in voice_forge.py finish_audio, or VoicePlayer volume per speaker). |
| WARN | shade | median -13.8 LUFS (+0.9 dB vs all speakers -14.7), 5 lines -15.0..-11.6, 9 s, peak -0.9 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others | Level the speaker (a per-speaker gain in voice_forge.py finish_audio, or VoicePlayer volume per speaker). |
| WARN | unit_ash_hurler peak | -0.2 dBTP | voice true peak <= -0.5 dBTP | Voice Forge normalises to -1 dBFS; a higher decoded peak = import overshoot (import the voice folder as PCM). |
| PASS | master | median -17.0 LUFS (-2.4 dB vs all speakers -14.7), 30 lines -18.7..-14.1, 124 s, peak -0.4 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | unit_barrow_ghoul | median -15.9 LUFS (-1.2 dB vs all speakers -14.7), 4 lines -16.1..-14.7, 5 s, peak -0.9 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | unit_rimeshield | median -15.3 LUFS (-0.6 dB vs all speakers -14.7), 7 lines -16.3..-13.6, 11 s, peak -0.8 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | unit_scorchbow | median -14.7 LUFS (+0.0 dB vs all speakers -14.7), 4 lines -15.2..-13.9, 6 s, peak -0.9 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | maelis | median -14.9 LUFS (-0.3 dB vs all speakers -14.7), 2 lines -17.7..-12.2, 3 s, peak -1.0 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | unit_shadow_knight | median -14.2 LUFS (+0.5 dB vs all speakers -14.7), 4 lines -14.6..-12.9, 6 s, peak -0.9 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | unit_shardcaster | median -14.4 LUFS (+0.2 dB vs all speakers -14.7), 4 lines -15.8..-13.9, 6 s, peak -0.9 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | unit_shardguard | median -14.7 LUFS (-0.0 dB vs all speakers -14.7), 4 lines -16.3..-13.4, 7 s, peak -0.9 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | unit_sprigling | median -14.1 LUFS (+0.6 dB vs all speakers -14.7), 4 lines -16.1..-12.9, 5 s, peak -0.8 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | unit_stormbottle_genie | median -14.8 LUFS (-0.1 dB vs all speakers -14.7), 4 lines -15.8..-13.0, 6 s, peak -0.9 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | hush | median -14.7 LUFS (-0.1 dB vs all speakers -14.7), 2 lines -15.8..-13.7, 3 s, peak -1.0 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | unit_thornling | median -14.2 LUFS (+0.5 dB vs all speakers -14.7), 7 lines -17.7..-12.8, 10 s, peak -0.9 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | dancer | median -16.6 LUFS (-2.0 dB vs all speakers -14.7), 1 lines -16.6..-16.6, 2 s, peak -0.9 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | unit_wildwood_archer | median -14.5 LUFS (+0.2 dB vs all speakers -14.7), 4 lines -16.0..-12.9, 7 s, peak -0.6 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | vessa | median -14.9 LUFS (-0.2 dB vs all speakers -14.7), 20 lines -18.2..-10.9, 44 s, peak -0.6 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | vey | median -14.7 LUFS (-0.1 dB vs all speakers -14.7), 5 lines -16.2..-13.7, 12 s, peak -0.8 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | ysolde | median -14.2 LUFS (+0.5 dB vs all speakers -14.7), 14 lines -16.1..-11.4, 52 s, peak -0.5 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | unit_ashveil_saboteur | median -14.4 LUFS (+0.2 dB vs all speakers -14.7), 4 lines -15.1..-13.7, 6 s, peak -0.8 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | unit_bloomtender | median -14.6 LUFS (+0.0 dB vs all speakers -14.7), 4 lines -15.4..-13.1, 6 s, peak -1.0 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | unit_bramblehorn | median -14.9 LUFS (-0.2 dB vs all speakers -14.7), 4 lines -15.9..-14.4, 8 s, peak -1.0 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | unit_burr_slinger | median -14.4 LUFS (+0.3 dB vs all speakers -14.7), 4 lines -15.7..-13.3, 5 s, peak -0.7 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | unit_cinder_arbalest | median -14.6 LUFS (+0.0 dB vs all speakers -14.7), 4 lines -15.6..-13.1, 7 s, peak -0.7 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | unit_ash_hurler | median -14.7 LUFS (-0.0 dB vs all speakers -14.7), 4 lines -17.7..-13.3, 7 s, peak -0.2 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | unit_ember_archer | median -14.8 LUFS (-0.1 dB vs all speakers -14.7), 4 lines -15.8..-13.9, 5 s, peak -0.7 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | reveler | median -15.3 LUFS (-0.6 dB vs all speakers -14.7), 1 lines -15.3..-15.3, 2 s, peak -0.8 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | pell | median -15.8 LUFS (-1.2 dB vs all speakers -14.7), 1 lines -15.8..-15.8, 6 s, peak -1.0 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | unit_bleakbow | median -14.7 LUFS (-0.1 dB vs all speakers -14.7), 4 lines -16.5..-14.2, 7 s, peak -0.5 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | unit_gloom_thrall | median -15.0 LUFS (-0.3 dB vs all speakers -14.7), 4 lines -16.5..-13.0, 7 s, peak -0.9 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | unit_greenheart_oathkeeper | median -15.1 LUFS (-0.5 dB vs all speakers -14.7), 4 lines -15.5..-13.3, 8 s, peak -0.8 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | messenger | median -15.4 LUFS (-0.8 dB vs all speakers -14.7), 11 lines -18.5..-12.5, 16 s, peak -0.8 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | unit_hoarlight_magebow | median -14.6 LUFS (+0.0 dB vs all speakers -14.7), 4 lines -14.9..-13.7, 6 s, peak -0.9 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | unit_hollow_oathsworn | median -14.8 LUFS (-0.1 dB vs all speakers -14.7), 4 lines -16.3..-13.8, 7 s, peak -0.7 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | unit_nightblood_reaver | median -15.0 LUFS (-0.3 dB vs all speakers -14.7), 7 lines -17.2..-13.6, 9 s, peak -0.9 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | unit_nightbolt | median -15.7 LUFS (-1.1 dB vs all speakers -14.7), 4 lines -17.1..-13.4, 8 s, peak -0.9 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | unit_blaze_rider | median -15.5 LUFS (-0.8 dB vs all speakers -14.7), 4 lines -16.2..-13.2, 4 s, peak -1.0 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | unit_rime_colossus | median -14.7 LUFS (-0.1 dB vs all speakers -14.7), 4 lines -17.3..-14.0, 6 s, peak -0.8 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |
| PASS | unit_rime_hauler | median -15.6 LUFS (-1.0 dB vs all speakers -14.7), 4 lines -19.7..-13.9, 7 s, peak -1.0 dBTP | speaker median -24..-14 LUFS, within 3 dB of the others |  |

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
