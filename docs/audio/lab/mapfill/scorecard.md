# Audio Lab scorecard: mapfill

- Date: 2026-09-26 22:09:41
- Command: `godot --headless --path . -s tools/audio_lab/audio_lab.gd -- set=res://assets/audio/mapfill_ name=mapfill`
- set: `res://assets/audio/mapfill_`, kind `auto`, 7 cues, 2 players judged
- Missing cues are listed for context but not scored (set is not the whole game; use scene= or set=res://assets/audio).

## Score: 89 / 100

PASS 86 | WARN 4 | FAIL 2 | INFO 0

| Group | Weight | PASS | WARN | FAIL | INFO | Group score |
|---|---|---|---|---|---|---|
| Loudness (in game) | 18 | 6 | 0 | 1 | 0 | 86 % |
| Peaks and clipping | 10 | 7 | 0 | 0 | 0 | 100 % |
| Duration, silence, tails | 8 | 21 | 0 | 0 | 0 | 100 % |
| Spectral balance and masking | 10 | 8 | 4 | 0 | 0 | 83 % |
| Memory and disk | 5 | 8 | 0 | 0 | 0 | 100 % |
| Bus routing | 12 | 2 | 0 | 0 | 0 | 100 % |
| Variation | 10 | 6 | 0 | 1 | 0 | 86 % |
| 3D attenuation | 5 | 1 | 0 | 0 | 0 | 100 % |
| Voice limits | 7 | 2 | 0 | 0 | 0 | 100 % |
| Missing cues | 15 | 25 | 1 | 2 | 14 | not scored |

## Improve next

1. **FAIL Loudness (in game)** - Raise the in-game level into the range (volume_db in mapfill_popups.gd, or re-render the file)  _(mapfill_splash +10 dB; unit (frequent): -36..-22 cue)_
2. **FAIL Variation** - Add takes (<id>_1.wav, <id>_2.wav... or an AudioStreamRandomizer) and randomise pitch +-5 % in the play function.  _(mapfill_splash; frequent cue: >= 3 takes, or 2 takes + pitch / volume randomisation)_
3. **WARN Spectral balance and masking** - Add 1-4 kHz content (attack, harmonics): all-bass cues vanish on laptop speakers and mud the mix.  _(mapfill_drum, mapfill_horn, mapfill_roar; not all-bass (< 85% low), not all-hiss (< 60% air))_
4. **WARN Spectral balance and masking** - Add 2-5 kHz content so the UI cue reads on small speakers.  _(mapfill_bubble; not all-bass (< 85% low), not all-hiss (< 60% air))_
5. **Replace placeholders** - 7 of 7 files are generated tones (see "What a real replacement needs"); start with the most played cues (combat hits, shots, deaths) and the alerts.

## Checks

### Loudness (in game)

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| FAIL | mapfill_splash | -43.8 LUFS in game (file -16.3, vol -18.0 dB, 3D -9.5 dB) | unit (frequent): -36..-22 cue | Raise the in-game level into the range (volume_db in mapfill_popups.gd, or re-render the file) |
| PASS | mapfill_bubble | -27.7 LUFS in game (file -15.7, vol -12.0 dB, 3D 0.0 dB) | ui: -30..-14 cue |  |
| PASS | mapfill_chime | -17.8 LUFS in game (file -11.8, vol -6.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | mapfill_drum | -20.3 LUFS in game (file -14.3, vol -6.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | mapfill_horn | -9.8 LUFS in game (file -9.8, vol 0.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | mapfill_roar | -20.1 LUFS in game (file -12.1, vol -8.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | mapfill_stag | -9.5 LUFS in game (file -9.5, vol 0.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |

### Peaks and clipping

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | mapfill_bubble | true peak -6.9 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | mapfill_chime | true peak -4.5 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | mapfill_drum | true peak -3.2 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | mapfill_horn | true peak -4.4 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | mapfill_roar | true peak -5.2 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | mapfill_splash | true peak -5.5 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | mapfill_stag | true peak -4.4 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |

### Duration, silence, tails

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | mapfill_stag | 1.00 s | alert: 0.03..3.5 s |  |
| PASS | mapfill_stag | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | mapfill_stag | lead silence 1 ms | lead <= 15 ms |  |
| PASS | mapfill_splash | 0.25 s | unit: 0.03..1.5 s |  |
| PASS | mapfill_splash | trailing silence 30 ms | trail <= 150 ms |  |
| PASS | mapfill_splash | lead silence 0 ms | lead <= 15 ms |  |
| PASS | mapfill_roar | 1.50 s | alert: 0.03..3.5 s |  |
| PASS | mapfill_roar | trailing silence 48 ms | trail <= 150 ms |  |
| PASS | mapfill_roar | lead silence 2 ms | lead <= 15 ms |  |
| PASS | mapfill_horn | 1.20 s | alert: 0.03..3.5 s |  |
| PASS | mapfill_horn | trailing silence 30 ms | trail <= 150 ms |  |
| PASS | mapfill_horn | lead silence 1 ms | lead <= 15 ms |  |
| PASS | mapfill_drum | 0.60 s | alert: 0.03..3.5 s |  |
| PASS | mapfill_drum | trailing silence 84 ms | trail <= 150 ms |  |
| PASS | mapfill_drum | lead silence 0 ms | lead <= 15 ms |  |
| PASS | mapfill_chime | 0.40 s | alert: 0.03..3.5 s |  |
| PASS | mapfill_chime | trailing silence 1 ms | trail <= 150 ms |  |
| PASS | mapfill_chime | lead silence 0 ms | lead <= 15 ms |  |
| PASS | mapfill_bubble | 0.30 s | ui: 0.03..0.8 s |  |
| PASS | mapfill_bubble | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | mapfill_bubble | lead silence 0 ms | lead <= 10 ms |  |

### Spectral balance and masking

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| WARN | mapfill_bubble | low 1% / mid 99% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) | Add 2-5 kHz content so the UI cue reads on small speakers. |
| WARN | mapfill_drum | low 99% / mid 1% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) | Add 1-4 kHz content (attack, harmonics): all-bass cues vanish on laptop speakers and mud the mix. |
| WARN | mapfill_horn | low 91% / mid 9% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) | Add 1-4 kHz content (attack, harmonics): all-bass cues vanish on laptop speakers and mud the mix. |
| WARN | mapfill_roar | low 98% / mid 2% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) | Add 1-4 kHz content (attack, harmonics): all-bass cues vanish on laptop speakers and mud the mix. |
| PASS | mapfill_chime | low 0% / mid 81% / pres 18% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | mapfill_chime | beats the battle bed by 21.1 dB (mid band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | mapfill_drum | beats the battle bed by 45.8 dB (low band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | mapfill_horn | beats the battle bed by 55.9 dB (low band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | mapfill_roar | beats the battle bed by 45.9 dB (low band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | mapfill_splash | low 0% / mid 42% / pres 25% / air 33% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | mapfill_stag | low 77% / mid 23% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | mapfill_stag | beats the battle bed by 55.5 dB (low band) | alert >= +3 dB over 6 combat voices in one band |  |

### Memory and disk

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | mapfill_bubble | 13 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | mapfill_chime | 17 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | mapfill_drum | 26 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | mapfill_horn | 52 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | mapfill_roar | 65 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | mapfill_splash | 11 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | mapfill_stag | 43 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | set | 0.0 MB in memory | set <= 48 MB |  |

### Bus routing

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | res://scripts/vfx/mapfill_popups.gd:132 | AudioStreamPlayer on bus SFX | bus in Music, SFX |  |
| PASS | res://scripts/vfx/mapfill_popups.gd:142 | AudioStreamPlayer3D on bus SFX | bus in Music, SFX |  |

### Variation

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| FAIL | mapfill_splash | 1 take(s), pitch +-0%, ~20/min | frequent cue: >= 3 takes, or 2 takes + pitch / volume randomisation | Add takes (<id>_1.wav, <id>_2.wav... or an AudioStreamRandomizer) and randomise pitch +-5 % in the play function. |
| PASS | mapfill_bubble | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | mapfill_chime | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | mapfill_drum | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | mapfill_horn | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | mapfill_roar | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | mapfill_stag | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |

### 3D attenuation

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | res://scripts/vfx/mapfill_popups.gd:142 | unit_size 10, max_distance 60, inverse_distance; -9.5 dB @30 m, -14.8 dB @55 m, -15.6 dB @cut | gain >= -15 dB at 30 m, <= -10 dB at the cut-off |  |

### Voice limits

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | players | 2 players (1 3D) (from code) | <= 64 players, 3D pool <= 32 |  |
| PASS | mapfill_splash | rate limit 4.0 s | frequent cue has a per-cue cooldown >= 0.03 s |  |

### Missing cues

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| FAIL | Your wizard has fallen (alert) (core) | no sound (signal wizard_fell exists) | every key event has a sound | Add a cue and hook it (ui-coder, GameAudio or the system's popups script). |
| FAIL | Champion ability cast (core) | no sound (signal ability_cast, skill_hit exists) | every key event has a sound | Add a cue and hook it (ui-coder, GameAudio or the system's popups script). |
| WARN | Base / army under attack (off-screen alert) (core) | not in the game yet (no event to hook) | every key event has a sound | Needs a design (game-designer / ui-designer) + a cue. |
| PASS | UI button click (core) | covered: game_audio.gd (pressed\.connect) | every key event has a sound |  |
| PASS | Victory / defeat (core) | covered: game_audio.gd.mission_ended -> _on_mission_ended | every key event has a sound |  |
| PASS | Artifact / crown claimed (core) | covered: game_audio.gd.artifact_claimed -> _on_artifact_claimed | every key event has a sound |  |
| PASS | Item / loot picked up (core) | covered: game_audio.gd.picked_up -> _on_picked_up | every key event has a sound |  |
| PASS | Item used (core) | covered: game_audio.gd.item_used -> (lambda) | every key event has a sound |  |
| PASS | Item / ware bought (core) | covered: game_audio.gd.item_bought -> (lambda) | every key event has a sound |  |
| PASS | Hunters' contract starts (nice) | covered: trade_popups.gd.contract_started -> _on_contract_started | every key event has a sound |  |
| PASS | Caravan robbed / miners raided (core) | covered: trade_popups.gd.caravan_robbed -> _on_caravan_robbed | every key event has a sound |  |
| PASS | Caravan delivery (trade arrival) (core) | covered: trade_popups.gd.delivered -> _on_delivered | every key event has a sound |  |
| PASS | Epic beast spawns (core) | covered: mapfill_popups.gd.beast_spawned -> _on_beast_spawned | every key event has a sound |  |
| PASS | Neutral camp cleared (core) | covered: mapfill_popups.gd.camp_cleared -> _on_camp_cleared | every key event has a sound |  |
| PASS | Wayshrine awakens (nice) | covered: mapfill_popups.gd.shrine_awakened -> _on_shrine_awakened | every key event has a sound |  |
| PASS | Capture point taken (core) | covered: mapfill_popups.gd.point_captured -> _on_point_captured | every key event has a sound |  |
| PASS | Level up (core) | covered: game_audio.gd.level_changed -> _on_level_changed | every key event has a sound |  |
| PASS | Unit death (core) | covered: game_audio.gd.unit_died -> _on_unit_died | every key event has a sound |  |
| PASS | Not enough resources (refused) (core) | covered: game_audio.gd.spend_failed -> _on_spend_failed | every key event has a sound |  |
| PASS | Crystals delivered (nice) | covered: game_audio.gd (crystals_delivered) | every key event has a sound |  |
| PASS | Worker mining (nice) | covered: game_audio.gd (mine_tick) | every key event has a sound |  |
| PASS | Building hit (core) | covered: game_audio.gd.damaged -> _on_building_damaged | every key event has a sound |  |
| PASS | Unit trained (core) | covered: game_audio.gd.unit_trained -> _on_unit_trained | every key event has a sound |  |
| PASS | Melee hit (core) | covered: game_audio.gd.attack_landed -> _on_attack_landed | every key event has a sound |  |
| PASS | Construction finished (core) | covered: game_audio.gd.construction_finished -> _on_construction_finished | every key event has a sound |  |
| PASS | Ranged shot (projectile) (core) | covered: game_audio.gd (bolt_shot) | every key event has a sound |  |
| PASS | Building destroyed (core) | covered: game_audio.gd.destroyed -> _on_building_destroyed | every key event has a sound |  |
| PASS | Wizard spell cast (core) | covered: game_audio.gd.spell_cast -> _on_spell_cast | every key event has a sound |  |
| INFO | Spell impact / zone tick (nice) | partly: game_audio.gd (fireball_explode) | every key event has a sound | Hook the event's signal (spell_hit, spell_effect, hit_target) to a cue. |
| INFO | Crown dropped / lost (nice) | no sound (signal dropped, lost exists) | every key event has a sound | Add a cue and hook it (ui-coder, GameAudio or the system's popups script). |
| INFO | Wizard respawned (nice) | no sound (signal wizard_respawned, respawned exists) | every key event has a sound | Add a cue and hook it (ui-coder, GameAudio or the system's popups script). |
| INFO | Order acknowledged (move / attack click) (nice) | not in the game yet (no event to hook) | every key event has a sound | Needs a design (game-designer / ui-designer) + a cue. |
| INFO | Minimap / ally ping (2v2) (nice) | event not in the game yet | every key event has a sound |  |
| INFO | Creature / beast ability (nice) | no sound (signal ability_hit exists) | every key event has a sound | Add a cue and hook it (ui-coder, GameAudio or the system's popups script). |
| INFO | Bounty placed / paid (nice) | no sound (signal bounty_placed, bounty_paid exists) | every key event has a sound | Add a cue and hook it (ui-coder, GameAudio or the system's popups script). |
| INFO | Champion class chosen (nice) | no sound (signal class_chosen exists) | every key event has a sound | Add a cue and hook it (ui-coder, GameAudio or the system's popups script). |
| INFO | Champion fallen (nice) | no sound (signal champion_fallen exists) | every key event has a sound | Add a cue and hook it (ui-coder, GameAudio or the system's popups script). |
| INFO | Champion hired / revived (nice) | no sound (signal champion_hired, champion_revived exists) | every key event has a sound | Add a cue and hook it (ui-coder, GameAudio or the system's popups script). |
| INFO | Building placed (order confirmed) (nice) | no sound (signal building_placed exists) | every key event has a sound | Add a cue and hook it (ui-coder, GameAudio or the system's popups script). |
| INFO | Epic beast slain (nice) | no sound (signal beast_slain exists) | every key event has a sound | Add a cue and hook it (ui-coder, GameAudio or the system's popups script). |
| INFO | Capture point neutralised / lost (nice) | no sound (signal point_neutralised exists) | every key event has a sound | Add a cue and hook it (ui-coder, GameAudio or the system's popups script). |
| INFO | Spell learned / ranked up (nice) | no sound (signal spell_learned exists) | every key event has a sound | Add a cue and hook it (ui-coder, GameAudio or the system's popups script). |

## Cue table

| Cue | Cat | Mode | In game | File | Vol dB | 3D dB | TP dBTP | Dur s | Lead / trail ms | Bands L/M/P/A % | Rate /min | Takes | Pitch | Source |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| mapfill_bubble | ui | 2d | -27.7 | -15.7 | -12.0 | 0.0 | -6.9 | 0.30 | 0 / 50 | 1/99/0/0 | 0 | 1 | - | generated |
| mapfill_chime | alert | 2d | -17.8 | -11.8 | -6.0 | 0.0 | -4.5 | 0.40 | 0 / 1 | 0/81/18/1 | 0 | 1 | - | generated |
| mapfill_drum | alert | 2d | -20.3 | -14.3 | -6.0 | 0.0 | -3.2 | 0.60 | 0 / 84 | 99/1/0/0 | 0 | 1 | - | generated |
| mapfill_horn | alert | 2d | -9.8 | -9.8 | 0.0 | 0.0 | -4.4 | 1.20 | 1 / 30 | 91/9/0/0 | 0 | 1 | - | generated |
| mapfill_roar | alert | 2d | -20.1 | -12.1 | -8.0 | 0.0 | -5.2 | 1.50 | 2 / 48 | 98/2/0/0 | 0 | 1 | - | generated |
| mapfill_splash | unit | 3d | -43.8 | -16.3 | -18.0 | -9.5 | -5.5 | 0.25 | 0 / 30 | 0/42/25/33 | 20* | 1 | - | generated |
| mapfill_stag | alert | 2d | -9.5 | -9.5 | 0.0 | 0.0 | -4.4 | 1.00 | 1 / 50 | 77/23/0/0 | 0 | 1 | - | generated |

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

7 / 7 files are generated placeholders (sine / noise tones from a generator script). The numbers above judge the level, timing and routing they give the mix; a real sound must keep those and add:

- **ui**: 44.1/48 kHz mono, 16-bit WAV, 40-250 ms, peak <= -1 dBTP, cue loudness about -20 LUFS before volume_db, energy in 1-6 kHz, no lead silence (< 5 ms), one family feel for every UI cue.
- **alert**: 44.1/48 kHz mono (stereo only for 2D stingers), 0.3-3 s, strong 1-5 kHz content so it cuts through the fight, a distinct pitch contour per meaning (rising = good, falling = danger), peak <= -1 dBTP.
- **unit**: 44.1/48 kHz mono WAV, 3-5 takes per frequent cue (<id>_1.wav ... or an AudioStreamRandomizer .tres), 80-600 ms, transient in the first 5 ms, tail <= 400 ms for hits, peak <= -1 dBTP; recorded / layered foley, not synth.
- Every file: original or CC0 only (note the source in the file's folder), 16-bit WAV for SFX / Ogg for music, no clipping, trimmed start, faded end.

## Limits

- Loudness is a BS.1770 approximation on the 44.1 kHz decode (dual mono counted as 2 channels, as the game plays it); true peak is a 4x interpolation estimate.
- Masking uses 4 bands and a synthetic battle bed (6 unit cues at once), not a real mix; listen in the preview.
- Code facts come from patterns (DIR / DICT / PATH consts, `*.new()` players) and, for scene=, the live players; a sound played in an unusual way can be missed.
- Numbers can't judge taste, timbre or meaning: fill the listening sheet.
