# Audio Lab scorecard: forge_e34

- Date: 2026-09-28 16:51:01
- Command: `godot --headless --path . -s tools/audio_lab/audio_lab.gd -- set=res://assets/audio/forge name=forge_e34 log=0`
- set: `res://assets/audio/forge`, kind `auto`, 13 cues, 0 players judged
- Missing cues are listed for context but not scored (set is not the whole game; use scene= or set=res://assets/audio).

## Score: 85 / 100

PASS 107 | WARN 35 | FAIL 0 | INFO 0

| Group | Weight | PASS | WARN | FAIL | INFO | Group score |
|---|---|---|---|---|---|---|
| Loudness (in game) | 18 | 4 | 9 | 0 | 0 | 65 % |
| Peaks and clipping | 10 | 13 | 0 | 0 | 0 | 100 % |
| Duration, silence, tails | 8 | 30 | 10 | 0 | 0 | 88 % |
| Spectral balance and masking | 10 | 9 | 2 | 0 | 0 | 91 % |
| Memory and disk | 5 | 13 | 14 | 0 | 0 | 74 % |
| Variation | 10 | 11 | 0 | 0 | 0 | 100 % |
| Missing cues | 15 | 27 | 1 | 0 | 14 | not scored |

## Improve next

1. **WARN Loudness (in game)** - Lower the in-game level into the range (volume_db in the player, or re-render the file)  _(ep4_opening -3 dB, army_armour -5 dB, candle_pinch -4 dB, evenmead_horns -2 dB, knife_ring -6 dB, obren_whisper -3 dB (+3 more); music: -26..-18 integrated)_
2. **WARN Duration, silence, tails** - Shorten the tail or split into a cue + a separate layer.  _(army_armour, evenmead_amb, evenmead_horns, ice_creak, knife_ring, obren_whisper (+2 more); unit: 0.03..1.5 s)_
3. **WARN Memory and disk** - Wire it up (see Missing cues) or delete it.  _(ep3_opening, ep4_opening, army_armour, candle_pinch, evenmead_amb, evenmead_horns (+7 more); every file in the set is used)_
4. **WARN Spectral balance and masking** - Add 1-4 kHz content (attack, harmonics): all-bass cues vanish on laptop speakers and mud the mix.  _(evenmead_horns, stone_thump; not all-bass (< 85% low), not all-hiss (< 60% air))_
5. **WARN Duration, silence, tails** - Trim the start (import option edit/trim, or cut the file) so it fires on the frame.  _(ep3_opening; lead <= 500 ms)_
6. **WARN Duration, silence, tails** - Add a 5-20 ms fade-out at the end (click).  _(evenmead_amb; fade to silence (last 10 ms < -45 dB))_
7. **WARN Memory and disk** - Use Ogg Vorbis for music / long loops; trim or compress (QOA) long SFX.  _(evenmead_amb; file <= 977 KB)_

## Checks

### Loudness (in game)

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| WARN | ep4_opening | -17.3 LUFS in game (file -17.3, vol 0.0 dB, 3D 0.0 dB) | music: -26..-18 integrated | Lower the in-game level into the range (volume_db in the player, or re-render the file) |
| WARN | army_armour | -12.8 LUFS in game (file -12.8, vol 0.0 dB, 3D 0.0 dB) | unit: -30..-16 cue | Lower the in-game level into the range (volume_db in the player, or re-render the file) |
| WARN | candle_pinch | -13.9 LUFS in game (file -13.9, vol 0.0 dB, 3D 0.0 dB) | unit: -30..-16 cue | Lower the in-game level into the range (volume_db in the player, or re-render the file) |
| WARN | evenmead_horns | -15.6 LUFS in game (file -15.6, vol 0.0 dB, 3D 0.0 dB) | unit: -30..-16 cue | Lower the in-game level into the range (volume_db in the player, or re-render the file) |
| WARN | knife_ring | -11.7 LUFS in game (file -11.7, vol 0.0 dB, 3D 0.0 dB) | unit: -30..-16 cue | Lower the in-game level into the range (volume_db in the player, or re-render the file) |
| WARN | obren_whisper | -15.3 LUFS in game (file -15.3, vol 0.0 dB, 3D 0.0 dB) | unit: -30..-16 cue | Lower the in-game level into the range (volume_db in the player, or re-render the file) |
| WARN | sapling_creak | -14.6 LUFS in game (file -14.6, vol 0.0 dB, 3D 0.0 dB) | unit: -30..-16 cue | Lower the in-game level into the range (volume_db in the player, or re-render the file) |
| WARN | shovel_earth | -10.6 LUFS in game (file -10.6, vol 0.0 dB, 3D 0.0 dB) | unit: -30..-16 cue | Lower the in-game level into the range (volume_db in the player, or re-render the file) |
| WARN | stone_thump | -10.1 LUFS in game (file -10.1, vol 0.0 dB, 3D 0.0 dB) | unit: -30..-16 cue | Lower the in-game level into the range (volume_db in the player, or re-render the file) |
| PASS | ep3_opening | -18.9 LUFS in game (file -18.9, vol 0.0 dB, 3D 0.0 dB) | music: -26..-18 integrated |  |
| PASS | evenmead_amb | -16.6 LUFS in game (file -16.6, vol 0.0 dB, 3D 0.0 dB) | unit: -30..-16 cue |  |
| PASS | ice_creak | -21.4 LUFS in game (file -21.4, vol 0.0 dB, 3D 0.0 dB) | unit: -30..-16 cue |  |
| PASS | snow_step | -18.9 LUFS in game (file -18.9, vol 0.0 dB, 3D 0.0 dB) | unit: -30..-16 cue |  |

### Peaks and clipping

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | ep3_opening | true peak -1.9 dBTP, 0 clipped runs, source -2.0 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ep4_opening | true peak -2.0 dBTP, 0 clipped runs, source -2.0 dBFS (QOA import +0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | army_armour | true peak -4.4 dBTP, 0 clipped runs, source -4.0 dBFS (QOA import -0.4 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | candle_pinch | true peak -6.3 dBTP, 0 clipped runs, source -6.0 dBFS (QOA import -0.4 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | evenmead_amb | true peak -6.0 dBTP, 0 clipped runs, source -6.0 dBFS (QOA import +0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | evenmead_horns | true peak -10.0 dBTP, 0 clipped runs, source -10.0 dBFS (QOA import +0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ice_creak | true peak -6.3 dBTP, 0 clipped runs, source -5.0 dBFS (QOA import -1.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | knife_ring | true peak -4.9 dBTP, 0 clipped runs, source -5.0 dBFS (QOA import +0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | obren_whisper | true peak -5.9 dBTP, 0 clipped runs, source -6.0 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | sapling_creak | true peak -8.3 dBTP, 0 clipped runs, source -8.0 dBFS (QOA import -0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | shovel_earth | true peak -2.5 dBTP, 0 clipped runs, source -3.0 dBFS (QOA import +0.5 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | snow_step | true peak -6.6 dBTP, 0 clipped runs, source -6.0 dBFS (QOA import -0.6 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | stone_thump | true peak -3.0 dBTP, 0 clipped runs, source -3.0 dBFS (QOA import -0.0 dB) | true peak <= -1 dBTP, no clipping |  |

### Duration, silence, tails

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| WARN | ice_creak | 2.25 s | unit: 0.03..1.5 s | Shorten the tail or split into a cue + a separate layer. |
| WARN | knife_ring | 2.40 s | unit: 0.03..1.5 s | Shorten the tail or split into a cue + a separate layer. |
| WARN | evenmead_horns | 6.37 s | unit: 0.03..1.5 s | Shorten the tail or split into a cue + a separate layer. |
| WARN | obren_whisper | 2.68 s | unit: 0.03..1.5 s | Shorten the tail or split into a cue + a separate layer. |
| WARN | evenmead_amb | ends at -23.3 dB RMS (last sample 0.089) | fade to silence (last 10 ms < -45 dB) | Add a 5-20 ms fade-out at the end (click). |
| WARN | evenmead_amb | 19.00 s | unit: 0.03..1.5 s | Shorten the tail or split into a cue + a separate layer. |
| WARN | sapling_creak | 1.54 s | unit: 0.03..1.5 s | Shorten the tail or split into a cue + a separate layer. |
| WARN | army_armour | 2.68 s | unit: 0.03..1.5 s | Shorten the tail or split into a cue + a separate layer. |
| WARN | shovel_earth | 1.55 s | unit: 0.03..1.5 s | Shorten the tail or split into a cue + a separate layer. |
| WARN | ep3_opening | lead silence 565 ms | lead <= 500 ms | Trim the start (import option edit/trim, or cut the file) so it fires on the frame. |
| PASS | shovel_earth | trailing silence 72 ms | trail <= 150 ms |  |
| PASS | shovel_earth | lead silence 3 ms | lead <= 15 ms |  |
| PASS | snow_step | lead silence 3 ms | lead <= 15 ms |  |
| PASS | sapling_creak | trailing silence 41 ms | trail <= 150 ms |  |
| PASS | sapling_creak | lead silence 3 ms | lead <= 15 ms |  |
| PASS | snow_step | trailing silence 145 ms | trail <= 150 ms |  |
| PASS | snow_step | 1.30 s | unit: 0.03..1.5 s |  |
| PASS | stone_thump | lead silence 0 ms | lead <= 15 ms |  |
| PASS | obren_whisper | trailing silence 2 ms | trail <= 150 ms |  |
| PASS | stone_thump | trailing silence 32 ms | trail <= 150 ms |  |
| PASS | obren_whisper | lead silence 3 ms | lead <= 15 ms |  |
| PASS | stone_thump | 1.20 s | unit: 0.03..1.5 s |  |
| PASS | knife_ring | trailing silence 2 ms | trail <= 150 ms |  |
| PASS | ep3_opening | 91.0 s loop | music loop >= 60 s |  |
| PASS | ep3_opening | loop seam jump 0.000 | \|last - first sample\| <= 0.05 |  |
| PASS | ep4_opening | lead silence 426 ms | lead <= 500 ms |  |
| PASS | ep4_opening | 88.0 s loop | music loop >= 60 s |  |
| PASS | ep4_opening | loop seam jump 0.000 | \|last - first sample\| <= 0.05 |  |
| PASS | army_armour | lead silence 3 ms | lead <= 15 ms |  |
| PASS | army_armour | trailing silence 9 ms | trail <= 150 ms |  |
| PASS | candle_pinch | lead silence 1 ms | lead <= 15 ms |  |
| PASS | candle_pinch | trailing silence 10 ms | trail <= 150 ms |  |
| PASS | candle_pinch | 0.70 s | unit: 0.03..1.5 s |  |
| PASS | evenmead_amb | lead silence 0 ms | lead <= 15 ms |  |
| PASS | evenmead_amb | trailing silence 0 ms | trail <= 150 ms |  |
| PASS | evenmead_horns | lead silence 7 ms | lead <= 15 ms |  |
| PASS | evenmead_horns | trailing silence 115 ms | trail <= 150 ms |  |
| PASS | ice_creak | lead silence 3 ms | lead <= 15 ms |  |
| PASS | ice_creak | trailing silence 63 ms | trail <= 150 ms |  |
| PASS | knife_ring | lead silence 3 ms | lead <= 15 ms |  |

### Spectral balance and masking

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| WARN | evenmead_horns | low 87% / mid 13% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) | Add 1-4 kHz content (attack, harmonics): all-bass cues vanish on laptop speakers and mud the mix. |
| WARN | stone_thump | low 100% / mid 0% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) | Add 1-4 kHz content (attack, harmonics): all-bass cues vanish on laptop speakers and mud the mix. |
| PASS | army_armour | low 0% / mid 18% / pres 67% / air 15% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | candle_pinch | low 0% / mid 48% / pres 21% / air 31% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | evenmead_amb | low 84% / mid 7% / pres 9% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ice_creak | low 2% / mid 61% / pres 11% / air 27% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | knife_ring | low 0% / mid 38% / pres 56% / air 6% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | obren_whisper | low 0% / mid 88% / pres 9% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | sapling_creak | low 0% / mid 36% / pres 15% / air 49% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | shovel_earth | low 4% / mid 28% / pres 56% / air 12% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | snow_step | low 0% / mid 10% / pres 50% / air 40% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |

### Memory and disk

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| WARN | obren_whisper | no code plays it | every file in the set is used | Wire it up (see Missing cues) or delete it. |
| WARN | sapling_creak | no code plays it | every file in the set is used | Wire it up (see Missing cues) or delete it. |
| WARN | knife_ring | no code plays it | every file in the set is used | Wire it up (see Missing cues) or delete it. |
| WARN | ice_creak | no code plays it | every file in the set is used | Wire it up (see Missing cues) or delete it. |
| WARN | shovel_earth | no code plays it | every file in the set is used | Wire it up (see Missing cues) or delete it. |
| WARN | evenmead_horns | no code plays it | every file in the set is used | Wire it up (see Missing cues) or delete it. |
| WARN | evenmead_amb | no code plays it | every file in the set is used | Wire it up (see Missing cues) or delete it. |
| WARN | evenmead_amb | 2375 KB on disk, QOA 32000 Hz stereo | file <= 977 KB | Use Ogg Vorbis for music / long loops; trim or compress (QOA) long SFX. |
| WARN | candle_pinch | no code plays it | every file in the set is used | Wire it up (see Missing cues) or delete it. |
| WARN | snow_step | no code plays it | every file in the set is used | Wire it up (see Missing cues) or delete it. |
| WARN | army_armour | no code plays it | every file in the set is used | Wire it up (see Missing cues) or delete it. |
| WARN | ep4_opening | no code plays it | every file in the set is used | Wire it up (see Missing cues) or delete it. |
| WARN | stone_thump | no code plays it | every file in the set is used | Wire it up (see Missing cues) or delete it. |
| WARN | ep3_opening | no code plays it | every file in the set is used | Wire it up (see Missing cues) or delete it. |
| PASS | snow_step | 163 KB on disk, QOA 32000 Hz stereo | file <= 977 KB |  |
| PASS | stone_thump | 150 KB on disk, QOA 32000 Hz stereo | file <= 977 KB |  |
| PASS | shovel_earth | 194 KB on disk, QOA 32000 Hz stereo | file <= 977 KB |  |
| PASS | set | 5.6 MB in memory | set <= 48 MB |  |
| PASS | sapling_creak | 192 KB on disk, QOA 32000 Hz stereo | file <= 977 KB |  |
| PASS | obren_whisper | 335 KB on disk, QOA 32000 Hz stereo | file <= 977 KB |  |
| PASS | knife_ring | 300 KB on disk, QOA 32000 Hz stereo | file <= 977 KB |  |
| PASS | ice_creak | 281 KB on disk, QOA 32000 Hz stereo | file <= 977 KB |  |
| PASS | evenmead_horns | 796 KB on disk, QOA 32000 Hz stereo | file <= 977 KB |  |
| PASS | candle_pinch | 88 KB on disk, QOA 32000 Hz stereo | file <= 977 KB |  |
| PASS | army_armour | 335 KB on disk, QOA 32000 Hz stereo | file <= 977 KB |  |
| PASS | ep4_opening | 11000 KB on disk, QOA 32000 Hz stereo | file <= 15625 KB |  |
| PASS | ep3_opening | 11375 KB on disk, QOA 32000 Hz stereo | file <= 15625 KB |  |

### Variation

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | army_armour | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | candle_pinch | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | evenmead_amb | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | evenmead_horns | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ice_creak | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | knife_ring | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | obren_whisper | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | sapling_creak | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | shovel_earth | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | snow_step | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | stone_thump | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |

### Missing cues

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| WARN | Base / army under attack (off-screen alert) (core) | not in the game yet (no event to hook) | every key event has a sound | Needs a design (game-designer / ui-designer) + a cue. |
| PASS | UI button click (core) | covered: game_audio.gd (pressed\.connect) | every key event has a sound |  |
| PASS | Victory / defeat (core) | covered: game_audio.gd.mission_ended -> _on_mission_ended | every key event has a sound |  |
| PASS | Your wizard has fallen (alert) (core) | covered: game_audio.gd.wizard_fell -> _on_wizard_fell | every key event has a sound |  |
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
| PASS | Champion ability cast (core) | covered: game_audio.gd.ability_cast -> _on_ability_cast | every key event has a sound |  |
| PASS | Building hit (core) | covered: game_audio.gd.damaged -> _on_building_damaged | every key event has a sound |  |
| PASS | Wizard spell cast (core) | covered: game_audio.gd.spell_cast -> _on_spell_cast | every key event has a sound |  |
| PASS | Ranged shot (projectile) (core) | covered: game_audio.gd (bolt_shot) | every key event has a sound |  |
| PASS | Building destroyed (core) | covered: game_audio.gd.destroyed -> _on_building_destroyed | every key event has a sound |  |
| PASS | Construction finished (core) | covered: game_audio.gd.construction_finished -> _on_construction_finished | every key event has a sound |  |
| PASS | Melee hit (core) | covered: game_audio.gd.attack_landed -> _on_attack_landed | every key event has a sound |  |
| PASS | Unit trained (core) | covered: game_audio.gd.unit_trained -> _on_unit_trained | every key event has a sound |  |
| PASS | Worker mining (nice) | covered: game_audio.gd (mine_tick) | every key event has a sound |  |
| PASS | Crystals delivered (nice) | covered: game_audio.gd (crystals_delivered) | every key event has a sound |  |
| PASS | Unit death (core) | covered: game_audio.gd.unit_died -> _on_unit_died | every key event has a sound |  |
| PASS | Not enough resources (refused) (core) | covered: game_audio.gd.spend_failed -> _on_spend_failed | every key event has a sound |  |
| PASS | Level up (core) | covered: game_audio.gd.level_changed -> _on_level_changed | every key event has a sound |  |
| INFO | Order acknowledged (move / attack click) (nice) | not in the game yet (no event to hook) | every key event has a sound | Needs a design (game-designer / ui-designer) + a cue. |
| INFO | Wizard respawned (nice) | no sound (signal wizard_respawned, respawned exists) | every key event has a sound | Add a cue and hook it (ui-coder, GameAudio or the system's popups script). |
| INFO | Crown dropped / lost (nice) | no sound (signal dropped, lost exists) | every key event has a sound | Add a cue and hook it (ui-coder, GameAudio or the system's popups script). |
| INFO | Minimap / ally ping (2v2) (nice) | event not in the game yet | every key event has a sound |  |
| INFO | Spell impact / zone tick (nice) | partly: game_audio.gd (fireball_explode) | every key event has a sound | Hook the event's signal (spell_hit, spell_effect, hit_target) to a cue. |
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
| ep3_opening | music | - | -18.9 | -18.9 | 0.0 | 0.0 | -1.9 | 91.00 | 565 / 15 | 71/29/0/0 | 0 | 1 | - | file |
| ep4_opening | music | - | -17.3 | -17.3 | 0.0 | 0.0 | -2.0 | 88.00 | 426 / 8 | 81/18/0/0 | 0 | 1 | - | file |
| army_armour | unit | - | -12.8 | -12.8 | 0.0 | 0.0 | -4.4 | 2.68 | 3 / 9 | 0/18/67/15 | 0 | 1 | - | file |
| candle_pinch | unit | - | -13.9 | -13.9 | 0.0 | 0.0 | -6.3 | 0.70 | 1 / 10 | 0/48/21/31 | 0 | 1 | - | file |
| evenmead_amb | unit | - | -16.6 | -16.6 | 0.0 | 0.0 | -6.0 | 19.00 | 0 / 0 | 84/7/9/0 | 0 | 1 | - | file |
| evenmead_horns | unit | - | -15.6 | -15.6 | 0.0 | 0.0 | -10.0 | 6.37 | 7 / 115 | 87/13/0/0 | 0 | 1 | - | file |
| ice_creak | unit | - | -21.4 | -21.4 | 0.0 | 0.0 | -6.3 | 2.25 | 3 / 63 | 2/61/11/27 | 0 | 1 | - | file |
| knife_ring | unit | - | -11.7 | -11.7 | 0.0 | 0.0 | -4.9 | 2.40 | 3 / 2 | 0/38/56/6 | 0 | 1 | - | file |
| obren_whisper | unit | - | -15.3 | -15.3 | 0.0 | 0.0 | -5.9 | 2.68 | 3 / 2 | 0/88/9/2 | 0 | 1 | - | file |
| sapling_creak | unit | - | -14.6 | -14.6 | 0.0 | 0.0 | -8.3 | 1.54 | 3 / 41 | 0/36/15/49 | 0 | 1 | - | file |
| shovel_earth | unit | - | -10.6 | -10.6 | 0.0 | 0.0 | -2.5 | 1.55 | 3 / 72 | 4/28/56/12 | 0 | 1 | - | file |
| snow_step | unit | - | -18.9 | -18.9 | 0.0 | 0.0 | -6.6 | 1.30 | 3 / 145 | 0/10/50/40 | 0 | 1 | - | file |
| stone_thump | unit | - | -10.1 | -10.1 | 0.0 | 0.0 | -3.0 | 1.20 | 0 / 32 | 100/0/0/0 | 0 | 1 | - | file |

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

- **music**: Stereo Ogg Vorbis (q 5-6) 2-4 min per track with clean loop points or intro + loop, integrated about -12 LUFS in the file (the game plays it at MUSIC_DB -10: -22 in game), several tracks per state (menu / build-up / battle).
- **unit**: 44.1/48 kHz mono WAV, 3-5 takes per frequent cue (<id>_1.wav ... or an AudioStreamRandomizer .tres), 80-600 ms, transient in the first 5 ms, tail <= 400 ms for hits, peak <= -1 dBTP; recorded / layered foley, not synth.
- Every file: original or CC0 only (note the source in the file's folder), 16-bit WAV for SFX / Ogg for music, no clipping, trimmed start, faded end.

## Limits

- Loudness is a BS.1770 approximation on the 44.1 kHz decode (dual mono counted as 2 channels, as the game plays it); true peak is a 4x interpolation estimate.
- Masking uses 4 bands and a synthetic battle bed (6 unit cues at once), not a real mix; listen in the preview.
- Code facts come from patterns (DIR / DICT / PATH consts, `*.new()` players) and, for scene=, the live players; a sound played in an unusual way can be missed.
- Numbers can't judge taste, timbre or meaning: fill the listening sheet.
