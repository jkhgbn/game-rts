# Audio Lab scorecard: trade

- Date: 2026-09-26 22:09:47
- Command: `godot --headless --path . -s tools/audio_lab/audio_lab.gd -- set=res://assets/audio/trade_ name=trade`
- set: `res://assets/audio/trade_`, kind `auto`, 3 cues, 1 players judged
- Missing cues are listed for context but not scored (set is not the whole game; use scene= or set=res://assets/audio).

## Score: 94 / 100

PASS 53 | WARN 0 | FAIL 1 | INFO 0

| Group | Weight | PASS | WARN | FAIL | INFO | Group score |
|---|---|---|---|---|---|---|
| Loudness (in game) | 18 | 3 | 0 | 0 | 0 | 100 % |
| Peaks and clipping | 10 | 2 | 0 | 1 | 0 | 67 % |
| Duration, silence, tails | 8 | 9 | 0 | 0 | 0 | 100 % |
| Spectral balance and masking | 10 | 5 | 0 | 0 | 0 | 100 % |
| Memory and disk | 5 | 4 | 0 | 0 | 0 | 100 % |
| Bus routing | 12 | 1 | 0 | 0 | 0 | 100 % |
| Variation | 10 | 3 | 0 | 0 | 0 | 100 % |
| Voice limits | 7 | 1 | 0 | 0 | 0 | 100 % |
| Missing cues | 15 | 25 | 1 | 2 | 14 | not scored |

## Improve next

1. **FAIL Peaks and clipping** - Normalise the file to -1 dBTP (peak), lower the level before export if it clips.  _(trade_whistle; true peak <= -1 dBTP, no clipping)_
2. **Replace placeholders** - 3 of 3 files are generated tones (see "What a real replacement needs"); start with the most played cues (combat hits, shots, deaths) and the alerts.
3. **Polish ui** - 44.1/48 kHz mono, 16-bit WAV, 40-250 ms, peak <= -1 dBTP, cue loudness about -20 LUFS before volume_db, energy in 1-6 kHz, no lead silence (< 5 ms), one family feel for every UI cue.

## Checks

### Loudness (in game)

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | trade_coin | -18.7 LUFS in game (file -12.7, vol -6.0 dB, 3D 0.0 dB) | ui: -30..-14 cue |  |
| PASS | trade_horn | -9.0 LUFS in game (file -9.0, vol 0.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | trade_whistle | -8.6 LUFS in game (file -8.6, vol 0.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |

### Peaks and clipping

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| FAIL | trade_whistle | true peak 1.4 dBTP, 3 clipped runs | true peak <= -1 dBTP, no clipping | Normalise the file to -1 dBTP (peak), lower the level before export if it clips. |
| PASS | trade_coin | true peak -5.1 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | trade_horn | true peak -3.1 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |

### Duration, silence, tails

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | trade_coin | lead silence 0 ms | lead <= 10 ms |  |
| PASS | trade_coin | trailing silence 1 ms | trail <= 150 ms |  |
| PASS | trade_coin | 0.25 s | ui: 0.03..0.8 s |  |
| PASS | trade_horn | lead silence 1 ms | lead <= 15 ms |  |
| PASS | trade_horn | trailing silence 20 ms | trail <= 150 ms |  |
| PASS | trade_horn | 0.80 s | alert: 0.03..3.5 s |  |
| PASS | trade_whistle | lead silence 0 ms | lead <= 15 ms |  |
| PASS | trade_whistle | trailing silence 3 ms | trail <= 150 ms |  |
| PASS | trade_whistle | 0.50 s | alert: 0.03..3.5 s |  |

### Spectral balance and masking

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | trade_coin | low 0% / mid 6% / pres 90% / air 4% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | trade_horn | low 84% / mid 16% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | trade_horn | beats the battle bed by 12.8 dB (low band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | trade_whistle | low 1% / mid 86% / pres 6% / air 7% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | trade_whistle | beats the battle bed by 6.5 dB (mid band) | alert >= +3 dB over 6 combat voices in one band |  |

### Memory and disk

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | trade_coin | 11 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | trade_horn | 34 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | trade_whistle | 22 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | set | 0.0 MB in memory | set <= 48 MB |  |

### Bus routing

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | res://scripts/vfx/trade_popups.gd:95 | AudioStreamPlayer on bus SFX | bus in Music, SFX |  |

### Variation

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | trade_coin | 1 take(s), pitch +-0%, ~3/min | occasional cue (< 20/min): one take is fine |  |
| PASS | trade_horn | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | trade_whistle | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |

### Voice limits

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | players | 1 players (0 3D) (from code) | <= 64 players, 3D pool <= 32 |  |

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
| trade_coin | ui | 2d | -18.7 | -12.7 | -6.0 | 0.0 | -5.1 | 0.25 | 0 / 1 | 0/6/90/4 | 3 | 1 | - | generated |
| trade_horn | alert | 2d | -9.0 | -9.0 | 0.0 | 0.0 | -3.1 | 0.80 | 1 / 20 | 84/16/0/0 | 0 | 1 | - | generated |
| trade_whistle | alert | 2d | -8.6 | -8.6 | 0.0 | 0.0 | 1.4 | 0.50 | 0 / 3 | 1/86/6/7 | 0 | 1 | - | generated |

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

3 / 3 files are generated placeholders (sine / noise tones from a generator script). The numbers above judge the level, timing and routing they give the mix; a real sound must keep those and add:

- **ui**: 44.1/48 kHz mono, 16-bit WAV, 40-250 ms, peak <= -1 dBTP, cue loudness about -20 LUFS before volume_db, energy in 1-6 kHz, no lead silence (< 5 ms), one family feel for every UI cue.
- **alert**: 44.1/48 kHz mono (stereo only for 2D stingers), 0.3-3 s, strong 1-5 kHz content so it cuts through the fight, a distinct pitch contour per meaning (rising = good, falling = danger), peak <= -1 dBTP.
- Every file: original or CC0 only (note the source in the file's folder), 16-bit WAV for SFX / Ogg for music, no clipping, trimmed start, faded end.

## Limits

- Loudness is a BS.1770 approximation on the 44.1 kHz decode (dual mono counted as 2 channels, as the game plays it); true peak is a 4x interpolation estimate.
- Masking uses 4 bands and a synthetic battle bed (6 unit cues at once), not a real mix; listen in the preview.
- Code facts come from patterns (DIR / DICT / PATH consts, `*.new()` players) and, for scene=, the live players; a sound played in an unusual way can be missed.
- Numbers can't judge taste, timbre or meaning: fill the listening sheet.
