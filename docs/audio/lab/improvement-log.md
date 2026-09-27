# Audio Lab improvement log

Each run of tools/audio_lab/audio_lab.gd appends one entry (newest last): asset set, score, counts, top suggestions. Audio agents: compare before / after here.

## 2026-09-26 22:05:52 - skirmish (scene `res://scenes/skirmish.tscn`, kind auto)

- Score **85 / 100** - PASS 390, WARN 23, FAIL 5, INFO 14; 39 cues; scorecard `res://docs/audio/lab/skirmish/scorecard.md`
- Next 1: **FAIL Missing cues** - Add a cue and hook it (ui-coder, GameAudio or the system's popups script).  _(Champion ability cast (core), Your wizard has fallen (alert) (core); every key event has a sound)_
- Next 2: **FAIL Loudness (in game)** - Raise the in-game level into the range (volume_db in mapfill_popups.gd, or re-render the file)  _(mapfill_splash +10 dB; unit (frequent): -36..-22 cue)_
- Next 3: **FAIL Variation** - Add takes (<id>_1.wav, <id>_2.wav... or an AudioStreamRandomizer) and randomise pitch +-5 % in the play function.  _(mapfill_splash; frequent cue: >= 3 takes, or 2 takes + pitch / volume randomisation)_

## 2026-09-26 22:06:24 - all_audio (set `res://assets/audio`, kind auto)

- Score **84 / 100** - PASS 333, WARN 33, FAIL 5, INFO 14; 39 cues; scorecard `res://docs/audio/lab/all_audio/scorecard.md`
- Next 1: **FAIL Missing cues** - Add a cue and hook it (ui-coder, GameAudio or the system's popups script).  _(Champion ability cast (core), Your wizard has fallen (alert) (core); every key event has a sound)_
- Next 2: **FAIL Loudness (in game)** - Raise the in-game level into the range (volume_db in mapfill_popups.gd, or re-render the file)  _(mapfill_splash +10 dB; unit (frequent): -36..-22 cue)_
- Next 3: **FAIL Variation** - Add takes (<id>_1.wav, <id>_2.wav... or an AudioStreamRandomizer) and randomise pitch +-5 % in the play function.  _(mapfill_splash; frequent cue: >= 3 takes, or 2 takes + pitch / volume randomisation)_

## 2026-09-26 22:06:37 - sfx (set `res://assets/audio/sfx`, kind auto)

- Score **95 / 100** - PASS 242, WARN 22, FAIL 0, INFO 0; 27 cues; scorecard `res://docs/audio/lab/sfx/scorecard.md`
- Next 1: **WARN Loudness (in game)** - Lower the in-game level into the range (volume_db in game_audio.gd, or re-render the file)  _(crystals_delivered -2 dB, death_shadow -2 dB, item_bought -4 dB, item_used -6 dB; ui (frequent): -36..-20 cue)_
- Next 2: **WARN Variation** - Add takes (<id>_1.wav, <id>_2.wav... or an AudioStreamRandomizer).  _(bolt_impact, bolt_shot, building_hit, melee_hit, mine_tick; frequent cue: >= 3 takes, or 2 takes + pitch / volume randomisation)_
- Next 3: **WARN Spectral balance and masking** - Add 1-4 kHz content (attack, harmonics): all-bass cues vanish on laptop speakers and mud the mix.  _(building_collapse, building_hit, item_used, spell_umbral_shroud, ui_click; not all-bass (< 85% low), not all-hiss (< 60% air))_

## 2026-09-26 22:06:44 - mapfill (set `res://assets/audio/mapfill_`, kind auto)

- Score **89 / 100** - PASS 86, WARN 4, FAIL 2, INFO 0; 7 cues; scorecard `res://docs/audio/lab/mapfill/scorecard.md`
- Next 1: **FAIL Loudness (in game)** - Raise the in-game level into the range (volume_db in mapfill_popups.gd, or re-render the file)  _(mapfill_splash +10 dB; unit (frequent): -36..-22 cue)_
- Next 2: **FAIL Variation** - Add takes (<id>_1.wav, <id>_2.wav... or an AudioStreamRandomizer) and randomise pitch +-5 % in the play function.  _(mapfill_splash; frequent cue: >= 3 takes, or 2 takes + pitch / volume randomisation)_
- Next 3: **WARN Spectral balance and masking** - Add 2-5 kHz content so the UI cue reads on small speakers.  _(mapfill_bubble, mapfill_drum, mapfill_horn, mapfill_roar; not all-bass (< 85% low), not all-hiss (< 60% air))_

## 2026-09-26 22:06:50 - trade (set `res://assets/audio/trade_`, kind auto)

- Score **94 / 100** - PASS 53, WARN 0, FAIL 1, INFO 0; 3 cues; scorecard `res://docs/audio/lab/trade/scorecard.md`
- Next 1: **FAIL Peaks and clipping** - Normalise the file to -1 dBTP (peak), lower the level before export if it clips.  _(trade_whistle; true peak <= -1 dBTP, no clipping)_
- Next 2: **Replace placeholders** - 3 of 3 files are generated tones (see "What a real replacement needs"); start with the most played cues (combat hits, shots, deaths) and the alerts.
- Next 3: **Polish ui** - 44.1/48 kHz mono, 16-bit WAV, 40-250 ms, peak <= -1 dBTP, cue loudness about -20 LUFS before volume_db, energy in 1-6 kHz, no lead silence (< 5 ms), one family feel for every UI cue.

## 2026-09-26 22:07:06 - music (set `res://assets/audio/music`, kind music)

- Score **96 / 100** - PASS 39, WARN 4, FAIL 0, INFO 0; 2 cues; scorecard `res://docs/audio/lab/music/scorecard.md`
- Next 1: **WARN Duration, silence, tails** - Longer track / more tracks: a short loop repeats dozens of times in a match.  _(music_match, music_menu; music loop >= 60 s)_
- Next 2: **WARN Duration, silence, tails** - Cut the loop on a zero crossing / crossfade the loop point (click every loop).  _(music_match, music_menu; |last - first sample| <= 0.05)_
- Next 3: **Replace placeholders** - 2 of 2 files are generated tones (see "What a real replacement needs"); start with the most played cues (combat hits, shots, deaths) and the alerts.

## 2026-09-26 22:09:29 - all_audio (set `res://assets/audio`, kind auto)

- Score **84 / 100** - PASS 333, WARN 33, FAIL 5, INFO 14; 39 cues; scorecard `res://docs/audio/lab/all_audio/scorecard.md`
- Next 1: **FAIL Missing cues** - Add a cue and hook it (ui-coder, GameAudio or the system's popups script).  _(Champion ability cast (core), Your wizard has fallen (alert) (core); every key event has a sound)_
- Next 2: **FAIL Loudness (in game)** - Raise the in-game level into the range (volume_db in mapfill_popups.gd, or re-render the file)  _(mapfill_splash +10 dB; unit (frequent): -36..-22 cue)_
- Next 3: **FAIL Variation** - Add takes (<id>_1.wav, <id>_2.wav... or an AudioStreamRandomizer) and randomise pitch +-5 % in the play function.  _(mapfill_splash; frequent cue: >= 3 takes, or 2 takes + pitch / volume randomisation)_

## 2026-09-26 22:09:36 - sfx (set `res://assets/audio/sfx`, kind auto)

- Score **95 / 100** - PASS 242, WARN 22, FAIL 0, INFO 0; 27 cues; scorecard `res://docs/audio/lab/sfx/scorecard.md`
- Next 1: **WARN Loudness (in game)** - Lower the in-game level into the range (volume_db in game_audio.gd, or re-render the file)  _(crystals_delivered -2 dB, death_shadow -2 dB, item_bought -4 dB, item_used -6 dB; ui (frequent): -36..-20 cue)_
- Next 2: **WARN Variation** - Add takes (<id>_1.wav, <id>_2.wav... or an AudioStreamRandomizer).  _(bolt_impact, bolt_shot, building_hit, melee_hit, mine_tick; frequent cue: >= 3 takes, or 2 takes + pitch / volume randomisation)_
- Next 3: **WARN Loudness (in game)** - Raise the in-game level into the range (volume_db in game_audio.gd, or re-render the file)  _(mine_tick +5 dB; unit (frequent): -36..-22 cue)_

## 2026-09-26 22:09:41 - mapfill (set `res://assets/audio/mapfill_`, kind auto)

- Score **89 / 100** - PASS 86, WARN 4, FAIL 2, INFO 0; 7 cues; scorecard `res://docs/audio/lab/mapfill/scorecard.md`
- Next 1: **FAIL Loudness (in game)** - Raise the in-game level into the range (volume_db in mapfill_popups.gd, or re-render the file)  _(mapfill_splash +10 dB; unit (frequent): -36..-22 cue)_
- Next 2: **FAIL Variation** - Add takes (<id>_1.wav, <id>_2.wav... or an AudioStreamRandomizer) and randomise pitch +-5 % in the play function.  _(mapfill_splash; frequent cue: >= 3 takes, or 2 takes + pitch / volume randomisation)_
- Next 3: **WARN Spectral balance and masking** - Add 1-4 kHz content (attack, harmonics): all-bass cues vanish on laptop speakers and mud the mix.  _(mapfill_drum, mapfill_horn, mapfill_roar; not all-bass (< 85% low), not all-hiss (< 60% air))_

## 2026-09-26 22:09:47 - trade (set `res://assets/audio/trade_`, kind auto)

- Score **94 / 100** - PASS 53, WARN 0, FAIL 1, INFO 0; 3 cues; scorecard `res://docs/audio/lab/trade/scorecard.md`
- Next 1: **FAIL Peaks and clipping** - Normalise the file to -1 dBTP (peak), lower the level before export if it clips.  _(trade_whistle; true peak <= -1 dBTP, no clipping)_
- Next 2: **Replace placeholders** - 3 of 3 files are generated tones (see "What a real replacement needs"); start with the most played cues (combat hits, shots, deaths) and the alerts.
- Next 3: **Polish ui** - 44.1/48 kHz mono, 16-bit WAV, 40-250 ms, peak <= -1 dBTP, cue loudness about -20 LUFS before volume_db, energy in 1-6 kHz, no lead silence (< 5 ms), one family feel for every UI cue.

## 2026-09-26 22:10:00 - music (set `res://assets/audio/music`, kind music)

- Score **96 / 100** - PASS 39, WARN 4, FAIL 0, INFO 0; 2 cues; scorecard `res://docs/audio/lab/music/scorecard.md`
- Next 1: **WARN Duration, silence, tails** - Longer track / more tracks: a short loop repeats dozens of times in a match.  _(music_match, music_menu; music loop >= 60 s)_
- Next 2: **WARN Duration, silence, tails** - Cut the loop on a zero crossing / crossfade the loop point (click every loop).  _(music_match, music_menu; |last - first sample| <= 0.05)_
- Next 3: **Replace placeholders** - 2 of 2 files are generated tones (see "What a real replacement needs"); start with the most played cues (combat hits, shots, deaths) and the alerts.

## 2026-09-26 22:11:08 - skirmish (scene `res://scenes/skirmish.tscn`, kind auto)

- Score **84 / 100** - PASS 380, WARN 33, FAIL 5, INFO 14; 39 cues; scorecard `res://docs/audio/lab/skirmish/scorecard.md`
- Next 1: **FAIL Missing cues** - Add a cue and hook it (ui-coder, GameAudio or the system's popups script).  _(Champion ability cast (core), Your wizard has fallen (alert) (core); every key event has a sound)_
- Next 2: **FAIL Loudness (in game)** - Raise the in-game level into the range (volume_db in mapfill_popups.gd, or re-render the file)  _(mapfill_splash +10 dB; unit (frequent): -36..-22 cue)_
- Next 3: **FAIL Variation** - Add takes (<id>_1.wav, <id>_2.wav... or an AudioStreamRandomizer) and randomise pitch +-5 % in the play function.  _(mapfill_splash; frequent cue: >= 3 takes, or 2 takes + pitch / volume randomisation)_

## 2026-09-26 22:28:27 - all_audio (set `res://assets/audio`, kind auto)

- Score **98 / 100** - PASS 452, WARN 24, FAIL 0, INFO 14; 52 cues; scorecard `res://docs/audio/lab/all_audio/scorecard.md`
- Next 1: **WARN Spectral balance and masking** - Add 1-4 kHz content (attack, harmonics): all-bass cues vanish on laptop speakers and mud the mix.  _(mapfill_drum, mapfill_horn, mapfill_roar, building_collapse, building_hit, spell_umbral_shroud; not all-bass (< 85% low), not all-hiss (< 60% air))_
- Next 2: **WARN Spectral balance and masking** - Give it energy where the fight is thin (2-5 kHz presence), or +5 dB; a distinct pitch contour helps.  _(mapfill_chime, mapfill_drum, mapfill_roar, construction_done, unit_trained; alert >= +3 dB over 6 combat voices in one band)_
- Next 3: **WARN Spectral balance and masking** - Add 2-5 kHz content so the UI cue reads on small speakers.  _(mapfill_bubble, item_used, ui_click; not all-bass (< 85% low), not all-hiss (< 60% air))_
