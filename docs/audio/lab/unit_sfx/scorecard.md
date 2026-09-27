# Audio Lab scorecard: unit_sfx

- Date: 2026-09-27 18:13:25
- Command: `godot --headless --path . -s tools/audio_lab/audio_lab.gd -- set=res://assets/audio/sfx name=unit_sfx`
- set: `res://assets/audio/sfx`, kind `auto`, 67 cues, 3 players judged
- Missing cues are listed for context but not scored (set is not the whole game; use scene= or set=res://assets/audio).

## Score: 99 / 100

PASS 579 | WARN 13 | FAIL 0 | INFO 0

| Group | Weight | PASS | WARN | FAIL | INFO | Group score |
|---|---|---|---|---|---|---|
| Loudness (in game) | 18 | 71 | 2 | 0 | 0 | 99 % |
| Peaks and clipping | 10 | 64 | 3 | 0 | 0 | 98 % |
| Duration, silence, tails | 8 | 201 | 1 | 0 | 0 | 100 % |
| Spectral balance and masking | 10 | 69 | 7 | 0 | 0 | 95 % |
| Memory and disk | 5 | 68 | 0 | 0 | 0 | 100 % |
| Bus routing | 12 | 3 | 0 | 0 | 0 | 100 % |
| Variation | 10 | 57 | 0 | 0 | 0 | 100 % |
| 3D attenuation | 5 | 1 | 0 | 0 | 0 | 100 % |
| Voice limits | 7 | 18 | 0 | 0 | 0 | 100 % |
| Missing cues | 15 | 27 | 1 | 0 | 14 | not scored |

## Improve next

1. **WARN Loudness (in game)** - Raise the in-game level into the range (volume_db in game_audio.gd, or re-render the file)  _(ability_cast +3 dB; spell: -22..-9 cue)_
2. **WARN Loudness (in game)** - Re-level the takes (or re-render them) so a random pick never jumps out of the mix.  _(building_hit takes; takes of one cue within 2.0 dB)_
3. **WARN Peaks and clipping** - The source file itself peaks at -0.4 dBFS (the import adds -0.1 dB): normalise the file to -1 dBTP.  _(building_collapse, fireball_explode, spell_ember_step; true peak <= -1 dBTP, no clipping)_
4. **WARN Spectral balance and masking** - Add 1-4 kHz content (attack, harmonics): all-bass cues vanish on laptop speakers and mud the mix.  _(building_collapse, building_hit, spell_umbral_shroud; not all-bass (< 85% low), not all-hiss (< 60% air))_
5. **WARN Spectral balance and masking** - Give it energy where the fight is thin (2-5 kHz presence), or +1 dB; a distinct pitch contour helps.  _(construction_done, unit_trained; alert >= +3 dB over 6 combat voices in one band)_
6. **WARN Spectral balance and masking** - Add 2-5 kHz content so the UI cue reads on small speakers.  _(item_used, ui_click; not all-bass (< 85% low), not all-hiss (< 60% air))_
7. **WARN Duration, silence, tails** - Add a 5-20 ms fade-out at the end (click).  _(defeat; fade to silence (last 10 ms < -45 dB))_
8. **Replace placeholders** - 67 of 67 files are generated tones (see "What a real replacement needs"); start with the most played cues (combat hits, shots, deaths) and the alerts.

## Checks

### Loudness (in game)

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| WARN | ability_cast | -23.4 LUFS in game (file -10.9, vol -8.0 dB, 3D -4.4 dB) | spell: -22..-9 cue | Raise the in-game level into the range (volume_db in game_audio.gd, or re-render the file) |
| WARN | building_hit takes | spread 5.1 dB (building_hit, building_hit_1, building_hit_2) | takes of one cue within 2.0 dB | Re-level the takes (or re-render them) so a random pick never jumps out of the mix. |
| PASS | melee_hit_2 | -27.4 LUFS in game (file -19.0, vol -4.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | melee_hit_1 | -27.6 LUFS in game (file -19.1, vol -4.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | melee_hit | -26.5 LUFS in game (file -18.0, vol -4.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | level_up | -10.4 LUFS in game (file -10.4, vol 0.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | item_used | -15.8 LUFS in game (file -9.8, vol -6.0 dB, 3D 0.0 dB) | ui: -30..-14 cue |  |
| PASS | item_pickup | -15.0 LUFS in game (file -15.0, vol 0.0 dB, 3D 0.0 dB) | ui: -30..-14 cue |  |
| PASS | item_bought | -16.1 LUFS in game (file -12.1, vol -4.0 dB, 3D 0.0 dB) | ui: -30..-14 cue |  |
| PASS | hit_whip | -27.6 LUFS in game (file -18.2, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_storm | -24.2 LUFS in game (file -13.8, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_siege | -25.4 LUFS in game (file -15.0, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_magic | -25.8 LUFS in game (file -16.4, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_heavy | -27.7 LUFS in game (file -18.3, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_bow | -28.2 LUFS in game (file -20.8, vol -3.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_bolt | -27.3 LUFS in game (file -17.9, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_blade | -29.3 LUFS in game (file -19.9, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_beast | -26.4 LUFS in game (file -17.0, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | fireball_explode | -14.1 LUFS in game (file -9.7, vol 0.0 dB, 3D -4.4 dB) | spell: -22..-9 cue |  |
| PASS | mine_tick takes | spread 0.4 dB (mine_tick, mine_tick_1, mine_tick_2) | takes of one cue within 2.0 dB |  |
| PASS | melee_hit takes | spread 1.1 dB (melee_hit, melee_hit_1, melee_hit_2) | takes of one cue within 2.0 dB |  |
| PASS | bolt_shot takes | spread 0.2 dB (bolt_shot, bolt_shot_1, bolt_shot_2) | takes of one cue within 2.0 dB |  |
| PASS | bolt_impact takes | spread 0.6 dB (bolt_impact, bolt_impact_1, bolt_impact_2) | takes of one cue within 2.0 dB |  |
| PASS | death_* | spread 2.3 dB (death_beast, death_blade, death_bolt, death_bow, death_fire, death_heavy, death_magic, death_shadow, death_siege, death_storm, death_whip) | same-role cues within 3 dB |  |
| PASS | victory | -8.7 LUFS in game (file -8.7, vol 0.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | unit_trained | -17.0 LUFS in game (file -8.6, vol -4.0 dB, 3D -4.4 dB) | alert: -22..-7 cue |  |
| PASS | ui_error | -13.7 LUFS in game (file -9.7, vol -4.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | ui_click | -33.7 LUFS in game (file -25.7, vol -8.0 dB, 3D 0.0 dB) | ui (frequent): -36..-20 cue |  |
| PASS | spell_umbral_shroud | -12.0 LUFS in game (file -7.5, vol 0.0 dB, 3D -4.4 dB) | spell: -22..-9 cue |  |
| PASS | spell_soul_siphon | -11.3 LUFS in game (file -6.8, vol 0.0 dB, 3D -4.4 dB) | spell: -22..-9 cue |  |
| PASS | spell_shadow_lance | -15.9 LUFS in game (file -11.5, vol 0.0 dB, 3D -4.4 dB) | spell: -22..-9 cue |  |
| PASS | spell_kindle | -12.6 LUFS in game (file -8.1, vol 0.0 dB, 3D -4.4 dB) | spell: -22..-9 cue |  |
| PASS | spell_ember_step | -11.3 LUFS in game (file -6.9, vol 0.0 dB, 3D -4.4 dB) | spell: -22..-9 cue |  |
| PASS | skill_hit | -27.7 LUFS in game (file -17.3, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | mine_tick_2 | -34.6 LUFS in game (file -22.2, vol -8.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | mine_tick_1 | -34.5 LUFS in game (file -22.1, vol -8.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | mine_tick | -34.9 LUFS in game (file -22.4, vol -8.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | building_hit | -25.3 LUFS in game (file -15.8, vol -5.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | building_collapse | -12.9 LUFS in game (file -8.5, vol 0.0 dB, 3D -4.4 dB) | alert: -22..-7 cue |  |
| PASS | bolt_shot_2 | -31.9 LUFS in game (file -19.4, vol -8.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | bolt_shot_1 | -31.7 LUFS in game (file -19.2, vol -8.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | bolt_shot | -31.7 LUFS in game (file -19.2, vol -8.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | bolt_impact_2 | -31.2 LUFS in game (file -19.8, vol -7.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | bolt_impact_1 | -30.6 LUFS in game (file -19.2, vol -7.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | bolt_impact | -30.7 LUFS in game (file -19.3, vol -7.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | atk_whip | -23.7 LUFS in game (file -13.3, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_storm | -21.5 LUFS in game (file -11.1, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_siege | -23.2 LUFS in game (file -12.8, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_magic | -23.1 LUFS in game (file -12.6, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_heavy | -21.2 LUFS in game (file -10.8, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_bow | -28.9 LUFS in game (file -17.5, vol -7.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_bolt | -27.7 LUFS in game (file -17.3, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_blade | -24.7 LUFS in game (file -14.2, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_beast | -25.6 LUFS in game (file -15.1, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | alert_wizard_fell | -9.0 LUFS in game (file -9.0, vol 0.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | fireball_cast | -12.7 LUFS in game (file -8.2, vol 0.0 dB, 3D -4.4 dB) | spell: -22..-9 cue |  |
| PASS | defeat | -7.6 LUFS in game (file -7.6, vol 0.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | death_whip | -18.7 LUFS in game (file -10.8, vol -3.5 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_storm | -18.3 LUFS in game (file -8.8, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_siege | -18.0 LUFS in game (file -10.5, vol -3.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_shadow | -17.9 LUFS in game (file -8.5, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_magic | -17.7 LUFS in game (file -10.2, vol -3.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_heavy | -19.2 LUFS in game (file -11.8, vol -3.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_fire | -19.3 LUFS in game (file -11.9, vol -3.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_bow | -20.0 LUFS in game (file -12.6, vol -3.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_bolt | -19.4 LUFS in game (file -12.0, vol -3.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_blade | -19.2 LUFS in game (file -12.8, vol -2.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_beast | -18.1 LUFS in game (file -9.2, vol -4.5 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | crystals_delivered | -21.8 LUFS in game (file -11.8, vol -10.0 dB, 3D 0.0 dB) | ui (frequent): -36..-20 cue |  |
| PASS | crown_claimed | -8.6 LUFS in game (file -8.6, vol 0.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | construction_done | -14.5 LUFS in game (file -10.1, vol 0.0 dB, 3D -4.4 dB) | alert: -22..-7 cue |  |
| PASS | building_hit_2 | -30.3 LUFS in game (file -20.9, vol -5.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | building_hit_1 | -28.5 LUFS in game (file -19.1, vol -5.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |

### Peaks and clipping

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| WARN | building_collapse | true peak -0.5 dBTP, 0 clipped runs, source -0.4 dBFS (QOA import -0.1 dB) | true peak <= -1 dBTP, no clipping | The source file itself peaks at -0.4 dBFS (the import adds -0.1 dB): normalise the file to -1 dBTP. |
| WARN | fireball_explode | true peak -0.3 dBTP, 0 clipped runs, source -0.4 dBFS (QOA import +0.2 dB) | true peak <= -1 dBTP, no clipping | The source file itself peaks at -0.4 dBFS (the import adds +0.2 dB): normalise the file to -1 dBTP. |
| WARN | spell_ember_step | true peak -0.7 dBTP, 0 clipped runs, source -1.4 dBFS (QOA import +0.6 dB) | true peak <= -1 dBTP, no clipping | The source file itself peaks at -1.4 dBFS (the import adds +0.6 dB): normalise the file to -1 dBTP. |
| PASS | item_used | true peak -4.4 dBTP, 0 clipped runs, source -4.4 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | item_pickup | true peak -4.4 dBTP, 0 clipped runs, source -4.4 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | item_bought | true peak -4.2 dBTP, 0 clipped runs, source -4.4 dBFS (QOA import +0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_whip | true peak -3.0 dBTP, 0 clipped runs, source -3.1 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_storm | true peak -2.9 dBTP, 0 clipped runs, source -2.9 dBFS (QOA import -0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_siege | true peak -2.7 dBTP, 0 clipped runs, source -2.5 dBFS (QOA import -0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_magic | true peak -3.4 dBTP, 0 clipped runs, source -3.4 dBFS (QOA import -0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_heavy | true peak -2.3 dBTP, 0 clipped runs, source -2.9 dBFS (QOA import +0.5 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_bow | true peak -2.4 dBTP, 0 clipped runs, source -3.1 dBFS (QOA import +0.7 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_bolt | true peak -2.9 dBTP, 0 clipped runs, source -2.9 dBFS (QOA import -0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_blade | true peak -2.2 dBTP, 0 clipped runs, source -2.9 dBFS (QOA import +0.4 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_beast | true peak -3.2 dBTP, 0 clipped runs, source -3.4 dBFS (QOA import +0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | fireball_cast | true peak -1.3 dBTP, 0 clipped runs, source -1.4 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | defeat | true peak -1.9 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import +0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_whip | true peak -1.9 dBTP, 0 clipped runs, source -2.5 dBFS (QOA import +0.5 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | level_up | true peak -1.8 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | melee_hit | true peak -1.8 dBTP, 0 clipped runs, source -1.4 dBFS (QOA import -0.4 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | melee_hit_1 | true peak -2.2 dBTP, 0 clipped runs, source -2.5 dBFS (QOA import +0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | melee_hit_2 | true peak -2.3 dBTP, 0 clipped runs, source -2.1 dBFS (QOA import -0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | mine_tick | true peak -6.5 dBTP, 0 clipped runs, source -6.9 dBFS (QOA import +0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | mine_tick_1 | true peak -6.8 dBTP, 0 clipped runs, source -6.9 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | mine_tick_2 | true peak -6.7 dBTP, 0 clipped runs, source -6.9 dBFS (QOA import +0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | skill_hit | true peak -1.9 dBTP, 0 clipped runs, source -2.5 dBFS (QOA import +0.6 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | spell_kindle | true peak -1.4 dBTP, 0 clipped runs, source -1.4 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | spell_shadow_lance | true peak -1.0 dBTP, 0 clipped runs, source -1.4 dBFS (QOA import +0.4 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | spell_soul_siphon | true peak -2.0 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import -0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | spell_umbral_shroud | true peak -1.8 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ui_click | true peak -8.2 dBTP, 0 clipped runs, source -8.0 dBFS (QOA import -0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ui_error | true peak -6.0 dBTP, 0 clipped runs, source -6.0 dBFS (QOA import +0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | unit_trained | true peak -4.5 dBTP, 0 clipped runs, source -4.4 dBFS (QOA import -0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | victory | true peak -1.3 dBTP, 0 clipped runs, source -1.4 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ability_cast | true peak -3.4 dBTP, 0 clipped runs, source -3.1 dBFS (QOA import -0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | alert_wizard_fell | true peak -2.5 dBTP, 0 clipped runs, source -2.5 dBFS (QOA import +0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_beast | true peak -2.8 dBTP, 0 clipped runs, source -3.1 dBFS (QOA import +0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_blade | true peak -3.0 dBTP, 0 clipped runs, source -3.1 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_bolt | true peak -3.1 dBTP, 0 clipped runs, source -3.1 dBFS (QOA import +0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_bow | true peak -4.0 dBTP, 0 clipped runs, source -3.4 dBFS (QOA import -0.8 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_heavy | true peak -3.3 dBTP, 0 clipped runs, source -2.9 dBFS (QOA import -0.4 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_magic | true peak -3.2 dBTP, 0 clipped runs, source -3.4 dBFS (QOA import +0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_siege | true peak -2.6 dBTP, 0 clipped runs, source -2.2 dBFS (QOA import -0.5 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_storm | true peak -3.5 dBTP, 0 clipped runs, source -3.1 dBFS (QOA import -0.4 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_whip | true peak -3.6 dBTP, 0 clipped runs, source -3.1 dBFS (QOA import -0.5 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | bolt_impact | true peak -2.4 dBTP, 0 clipped runs, source -2.5 dBFS (QOA import -0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | bolt_impact_1 | true peak -2.4 dBTP, 0 clipped runs, source -2.5 dBFS (QOA import -0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | bolt_impact_2 | true peak -2.8 dBTP, 0 clipped runs, source -2.9 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | bolt_shot | true peak -3.9 dBTP, 0 clipped runs, source -3.1 dBFS (QOA import -0.8 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | bolt_shot_1 | true peak -2.8 dBTP, 0 clipped runs, source -3.1 dBFS (QOA import +0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_storm | true peak -3.5 dBTP, 0 clipped runs, source -2.9 dBFS (QOA import -0.7 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_siege | true peak -1.7 dBTP, 0 clipped runs, source -2.2 dBFS (QOA import +0.4 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_shadow | true peak -2.0 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import -0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_magic | true peak -2.7 dBTP, 0 clipped runs, source -2.9 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_heavy | true peak -2.8 dBTP, 0 clipped runs, source -2.5 dBFS (QOA import -0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_fire | true peak -2.2 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import -0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_bow | true peak -2.9 dBTP, 0 clipped runs, source -2.9 dBFS (QOA import -0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_bolt | true peak -2.4 dBTP, 0 clipped runs, source -2.5 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_blade | true peak -2.1 dBTP, 0 clipped runs, source -2.5 dBFS (QOA import +0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_beast | true peak -2.6 dBTP, 0 clipped runs, source -2.9 dBFS (QOA import +0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | crystals_delivered | true peak -5.4 dBTP, 0 clipped runs, source -6.0 dBFS (QOA import +0.5 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | crown_claimed | true peak -1.7 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import +0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | construction_done | true peak -2.3 dBTP, 0 clipped runs, source -2.5 dBFS (QOA import +0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | building_hit_2 | true peak -6.0 dBTP, 0 clipped runs, source -3.4 dBFS (QOA import -2.8 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | building_hit_1 | true peak -3.7 dBTP, 0 clipped runs, source -3.4 dBFS (QOA import -0.4 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | building_hit | true peak -1.7 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import +0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | bolt_shot_2 | true peak -3.7 dBTP, 0 clipped runs, source -3.5 dBFS (QOA import -0.3 dB) | true peak <= -1 dBTP, no clipping |  |

### Duration, silence, tails

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| WARN | defeat | ends at -25.3 dB RMS (last sample 0.099) | fade to silence (last 10 ms < -45 dB) | Add a 5-20 ms fade-out at the end (click). |
| PASS | hit_heavy | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_heavy | trailing silence 23 ms | trail <= 150 ms |  |
| PASS | hit_heavy | 0.30 s | unit: 0.03..1.5 s |  |
| PASS | hit_magic | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_magic | trailing silence 43 ms | trail <= 150 ms |  |
| PASS | hit_magic | 0.24 s | unit: 0.03..1.5 s |  |
| PASS | hit_siege | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_siege | trailing silence 54 ms | trail <= 150 ms |  |
| PASS | hit_siege | 0.40 s | unit: 0.03..1.5 s |  |
| PASS | hit_storm | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_storm | trailing silence 54 ms | trail <= 150 ms |  |
| PASS | hit_storm | 0.35 s | unit: 0.03..1.5 s |  |
| PASS | hit_whip | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_whip | trailing silence 45 ms | trail <= 150 ms |  |
| PASS | hit_whip | 0.20 s | unit: 0.03..1.5 s |  |
| PASS | item_bought | lead silence 0 ms | lead <= 10 ms |  |
| PASS | item_bought | trailing silence 1 ms | trail <= 150 ms |  |
| PASS | item_bought | 0.32 s | ui: 0.03..0.8 s |  |
| PASS | item_pickup | lead silence 0 ms | lead <= 10 ms |  |
| PASS | item_pickup | trailing silence 2 ms | trail <= 150 ms |  |
| PASS | item_pickup | 0.26 s | ui: 0.03..0.8 s |  |
| PASS | item_used | lead silence 0 ms | lead <= 10 ms |  |
| PASS | item_used | trailing silence 20 ms | trail <= 150 ms |  |
| PASS | item_used | 0.40 s | ui: 0.03..0.8 s |  |
| PASS | death_storm | 0.90 s | unit: 0.03..1.5 s |  |
| PASS | death_whip | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_whip | trailing silence 51 ms | trail <= 150 ms |  |
| PASS | death_whip | 0.60 s | unit: 0.03..1.5 s |  |
| PASS | defeat | lead silence 0 ms | lead <= 15 ms |  |
| PASS | defeat | trailing silence 0 ms | trail <= 150 ms |  |
| PASS | defeat | 2.80 s | alert: 0.03..3.5 s |  |
| PASS | fireball_cast | lead silence 0 ms | lead <= 20 ms |  |
| PASS | fireball_cast | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | fireball_cast | 0.55 s | spell: 0.03..2.5 s |  |
| PASS | fireball_explode | lead silence 0 ms | lead <= 20 ms |  |
| PASS | fireball_explode | trailing silence 55 ms | trail <= 150 ms |  |
| PASS | fireball_explode | 1.10 s | spell: 0.03..2.5 s |  |
| PASS | hit_beast | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_beast | trailing silence 41 ms | trail <= 150 ms |  |
| PASS | hit_beast | 0.22 s | unit: 0.03..1.5 s |  |
| PASS | hit_blade | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_blade | trailing silence 93 ms | trail <= 150 ms |  |
| PASS | hit_blade | 0.18 s | unit: 0.03..1.5 s |  |
| PASS | hit_bolt | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_bolt | trailing silence 60 ms | trail <= 150 ms |  |
| PASS | hit_bolt | 0.20 s | unit: 0.03..1.5 s |  |
| PASS | hit_bow | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_bow | trailing silence 69 ms | trail <= 150 ms |  |
| PASS | hit_bow | 0.16 s | unit: 0.03..1.5 s |  |
| PASS | spell_ember_step | 0.45 s | spell: 0.03..2.5 s |  |
| PASS | spell_kindle | lead silence 0 ms | lead <= 20 ms |  |
| PASS | spell_kindle | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | spell_kindle | 0.80 s | spell: 0.03..2.5 s |  |
| PASS | spell_shadow_lance | lead silence 0 ms | lead <= 20 ms |  |
| PASS | spell_shadow_lance | trailing silence 52 ms | trail <= 150 ms |  |
| PASS | spell_shadow_lance | 0.50 s | spell: 0.03..2.5 s |  |
| PASS | spell_soul_siphon | lead silence 1 ms | lead <= 20 ms |  |
| PASS | spell_soul_siphon | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | spell_soul_siphon | 1.10 s | spell: 0.03..2.5 s |  |
| PASS | spell_umbral_shroud | lead silence 1 ms | lead <= 20 ms |  |
| PASS | spell_umbral_shroud | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | spell_umbral_shroud | 0.90 s | spell: 0.03..2.5 s |  |
| PASS | ui_click | lead silence 0 ms | lead <= 10 ms |  |
| PASS | ui_click | trailing silence 31 ms | trail <= 150 ms |  |
| PASS | ui_click | 0.06 s | ui: 0.03..0.8 s |  |
| PASS | ui_error | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ui_error | trailing silence 20 ms | trail <= 150 ms |  |
| PASS | ui_error | 0.30 s | alert: 0.03..3.5 s |  |
| PASS | unit_trained | lead silence 0 ms | lead <= 15 ms |  |
| PASS | unit_trained | trailing silence 10 ms | trail <= 150 ms |  |
| PASS | unit_trained | 0.45 s | alert: 0.03..3.5 s |  |
| PASS | victory | lead silence 0 ms | lead <= 15 ms |  |
| PASS | victory | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | victory | 2.80 s | alert: 0.03..3.5 s |  |
| PASS | level_up | lead silence 0 ms | lead <= 15 ms |  |
| PASS | level_up | trailing silence 2 ms | trail <= 150 ms |  |
| PASS | level_up | 0.95 s | alert: 0.03..3.5 s |  |
| PASS | melee_hit | lead silence 0 ms | lead <= 15 ms |  |
| PASS | melee_hit | trailing silence 75 ms | trail <= 150 ms |  |
| PASS | melee_hit | 0.20 s | unit: 0.03..1.5 s |  |
| PASS | melee_hit_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | melee_hit_1 | trailing silence 80 ms | trail <= 150 ms |  |
| PASS | melee_hit_1 | 0.21 s | unit: 0.03..1.5 s |  |
| PASS | melee_hit_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | melee_hit_2 | trailing silence 68 ms | trail <= 150 ms |  |
| PASS | melee_hit_2 | 0.19 s | unit: 0.03..1.5 s |  |
| PASS | mine_tick | lead silence 0 ms | lead <= 15 ms |  |
| PASS | mine_tick | trailing silence 58 ms | trail <= 150 ms |  |
| PASS | mine_tick | 0.10 s | unit: 0.03..1.5 s |  |
| PASS | mine_tick_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | mine_tick_1 | trailing silence 62 ms | trail <= 150 ms |  |
| PASS | mine_tick_1 | 0.11 s | unit: 0.03..1.5 s |  |
| PASS | mine_tick_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | mine_tick_2 | trailing silence 53 ms | trail <= 150 ms |  |
| PASS | mine_tick_2 | 0.09 s | unit: 0.03..1.5 s |  |
| PASS | skill_hit | lead silence 0 ms | lead <= 15 ms |  |
| PASS | skill_hit | trailing silence 52 ms | trail <= 150 ms |  |
| PASS | skill_hit | 0.28 s | unit: 0.03..1.5 s |  |
| PASS | spell_ember_step | lead silence 0 ms | lead <= 20 ms |  |
| PASS | spell_ember_step | trailing silence 31 ms | trail <= 150 ms |  |
| PASS | atk_siege | trailing silence 52 ms | trail <= 150 ms |  |
| PASS | atk_siege | 0.45 s | unit: 0.03..1.5 s |  |
| PASS | atk_storm | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_storm | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | atk_storm | 0.40 s | unit: 0.03..1.5 s |  |
| PASS | atk_whip | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_whip | trailing silence 76 ms | trail <= 150 ms |  |
| PASS | atk_whip | 0.26 s | unit: 0.03..1.5 s |  |
| PASS | bolt_impact | lead silence 0 ms | lead <= 15 ms |  |
| PASS | bolt_impact | trailing silence 46 ms | trail <= 150 ms |  |
| PASS | bolt_impact | 0.14 s | unit: 0.03..1.5 s |  |
| PASS | bolt_impact_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | bolt_impact_1 | trailing silence 53 ms | trail <= 150 ms |  |
| PASS | bolt_impact_1 | 0.15 s | unit: 0.03..1.5 s |  |
| PASS | bolt_impact_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | bolt_impact_2 | trailing silence 43 ms | trail <= 150 ms |  |
| PASS | bolt_impact_2 | 0.13 s | unit: 0.03..1.5 s |  |
| PASS | bolt_shot | lead silence 0 ms | lead <= 15 ms |  |
| PASS | bolt_shot | trailing silence 46 ms | trail <= 150 ms |  |
| PASS | bolt_shot | 0.24 s | unit: 0.03..1.5 s |  |
| PASS | bolt_shot_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | bolt_shot_1 | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | bolt_shot_1 | 0.25 s | unit: 0.03..1.5 s |  |
| PASS | bolt_shot_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | bolt_shot_2 | trailing silence 43 ms | trail <= 150 ms |  |
| PASS | ability_cast | lead silence 1 ms | lead <= 20 ms |  |
| PASS | ability_cast | trailing silence 3 ms | trail <= 150 ms |  |
| PASS | ability_cast | 0.45 s | spell: 0.03..2.5 s |  |
| PASS | alert_wizard_fell | lead silence 0 ms | lead <= 15 ms |  |
| PASS | alert_wizard_fell | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | alert_wizard_fell | 1.40 s | alert: 0.03..3.5 s |  |
| PASS | atk_beast | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_beast | trailing silence 66 ms | trail <= 150 ms |  |
| PASS | atk_beast | 0.30 s | unit: 0.03..1.5 s |  |
| PASS | atk_blade | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_blade | trailing silence 61 ms | trail <= 150 ms |  |
| PASS | atk_blade | 0.20 s | unit: 0.03..1.5 s |  |
| PASS | atk_bolt | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_bolt | trailing silence 33 ms | trail <= 150 ms |  |
| PASS | atk_bolt | 0.26 s | unit: 0.03..1.5 s |  |
| PASS | atk_bow | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_bow | trailing silence 44 ms | trail <= 150 ms |  |
| PASS | atk_bow | 0.24 s | unit: 0.03..1.5 s |  |
| PASS | atk_heavy | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_heavy | trailing silence 23 ms | trail <= 150 ms |  |
| PASS | atk_heavy | 0.30 s | unit: 0.03..1.5 s |  |
| PASS | atk_magic | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_magic | trailing silence 40 ms | trail <= 150 ms |  |
| PASS | atk_magic | 0.40 s | unit: 0.03..1.5 s |  |
| PASS | atk_siege | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_blade | trailing silence 101 ms | trail <= 150 ms |  |
| PASS | death_blade | 0.55 s | unit: 0.03..1.5 s |  |
| PASS | death_bolt | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_bolt | trailing silence 102 ms | trail <= 150 ms |  |
| PASS | death_bolt | 0.65 s | unit: 0.03..1.5 s |  |
| PASS | death_bow | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_bow | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | death_bow | 0.55 s | unit: 0.03..1.5 s |  |
| PASS | death_fire | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_fire | trailing silence 101 ms | trail <= 150 ms |  |
| PASS | death_fire | 0.65 s | unit: 0.03..1.5 s |  |
| PASS | death_heavy | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_heavy | trailing silence 98 ms | trail <= 150 ms |  |
| PASS | death_heavy | 0.75 s | unit: 0.03..1.5 s |  |
| PASS | death_magic | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_magic | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | death_magic | 0.80 s | unit: 0.03..1.5 s |  |
| PASS | death_shadow | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_shadow | trailing silence 51 ms | trail <= 150 ms |  |
| PASS | death_shadow | 0.80 s | unit: 0.03..1.5 s |  |
| PASS | death_siege | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_siege | trailing silence 101 ms | trail <= 150 ms |  |
| PASS | death_siege | 0.90 s | unit: 0.03..1.5 s |  |
| PASS | death_storm | lead silence 1 ms | lead <= 15 ms |  |
| PASS | death_storm | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | bolt_shot_2 | 0.23 s | unit: 0.03..1.5 s |  |
| PASS | building_collapse | lead silence 0 ms | lead <= 15 ms |  |
| PASS | building_collapse | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | building_collapse | 1.80 s | alert: 0.03..3.5 s |  |
| PASS | building_hit | lead silence 0 ms | lead <= 15 ms |  |
| PASS | building_hit | trailing silence 53 ms | trail <= 150 ms |  |
| PASS | building_hit | 0.30 s | unit: 0.03..1.5 s |  |
| PASS | building_hit_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | building_hit_1 | trailing silence 60 ms | trail <= 150 ms |  |
| PASS | building_hit_1 | 0.32 s | unit: 0.03..1.5 s |  |
| PASS | building_hit_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | building_hit_2 | trailing silence 70 ms | trail <= 150 ms |  |
| PASS | building_hit_2 | 0.28 s | unit: 0.03..1.5 s |  |
| PASS | construction_done | lead silence 0 ms | lead <= 15 ms |  |
| PASS | construction_done | trailing silence 1 ms | trail <= 150 ms |  |
| PASS | construction_done | 0.75 s | alert: 0.03..3.5 s |  |
| PASS | crown_claimed | lead silence 0 ms | lead <= 15 ms |  |
| PASS | crown_claimed | trailing silence 100 ms | trail <= 150 ms |  |
| PASS | crown_claimed | 1.40 s | alert: 0.03..3.5 s |  |
| PASS | crystals_delivered | lead silence 0 ms | lead <= 10 ms |  |
| PASS | crystals_delivered | trailing silence 12 ms | trail <= 150 ms |  |
| PASS | crystals_delivered | 0.40 s | ui: 0.03..0.8 s |  |
| PASS | death_beast | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_beast | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | death_beast | 0.80 s | unit: 0.03..1.5 s |  |
| PASS | death_blade | lead silence 0 ms | lead <= 15 ms |  |

### Spectral balance and masking

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| WARN | building_hit | low 93% / mid 5% / pres 1% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) | Add 1-4 kHz content (attack, harmonics): all-bass cues vanish on laptop speakers and mud the mix. |
| WARN | unit_trained | beats the battle bed by 0.9 dB (low band) | alert >= +3 dB over 6 combat voices in one band | Give it energy where the fight is thin (2-5 kHz presence), or +2 dB; a distinct pitch contour helps. |
| WARN | item_used | low 0% / mid 99% / pres 0% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) | Add 2-5 kHz content so the UI cue reads on small speakers. |
| WARN | building_collapse | low 93% / mid 6% / pres 1% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) | Add 1-4 kHz content (attack, harmonics): all-bass cues vanish on laptop speakers and mud the mix. |
| WARN | construction_done | beats the battle bed by 2.9 dB (mid band) | alert >= +3 dB over 6 combat voices in one band | Give it energy where the fight is thin (2-5 kHz presence), or +1 dB; a distinct pitch contour helps. |
| WARN | ui_click | low 0% / mid 98% / pres 2% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) | Add 2-5 kHz content so the UI cue reads on small speakers. |
| WARN | spell_umbral_shroud | low 98% / mid 2% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) | Add 1-4 kHz content (attack, harmonics): all-bass cues vanish on laptop speakers and mud the mix. |
| PASS | level_up | low 3% / mid 95% / pres 2% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | item_pickup | low 0% / mid 95% / pres 4% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | item_bought | low 0% / mid 64% / pres 34% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_whip | low 24% / mid 41% / pres 26% / air 9% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_storm | low 36% / mid 31% / pres 24% / air 10% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_siege | low 46% / mid 34% / pres 15% / air 5% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_magic | low 1% / mid 85% / pres 12% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_heavy | low 30% / mid 63% / pres 5% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_bow | low 12% / mid 72% / pres 11% / air 5% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_bolt | low 69% / mid 24% / pres 6% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_blade | low 19% / mid 49% / pres 21% / air 10% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_beast | low 2% / mid 92% / pres 4% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | fireball_explode | low 80% / mid 15% / pres 4% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | fireball_cast | low 46% / mid 50% / pres 3% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | defeat | beats the battle bed by 10.1 dB (low band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | victory | beats the battle bed by 7.8 dB (mid band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | victory | low 22% / mid 77% / pres 1% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | unit_trained | low 50% / mid 50% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ui_error | beats the battle bed by 6.2 dB (low band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | ui_error | low 80% / mid 20% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | spell_soul_siphon | low 76% / mid 24% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | spell_shadow_lance | low 1% / mid 94% / pres 5% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | spell_kindle | low 5% / mid 94% / pres 1% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | spell_ember_step | low 4% / mid 77% / pres 9% / air 11% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | skill_hit | low 70% / mid 21% / pres 7% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | mine_tick_2 | low 0% / mid 10% / pres 89% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | mine_tick_1 | low 0% / mid 27% / pres 72% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | mine_tick | low 0% / mid 16% / pres 83% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | melee_hit_2 | low 78% / mid 17% / pres 5% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | melee_hit_1 | low 69% / mid 20% / pres 10% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | melee_hit | low 74% / mid 17% / pres 7% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | level_up | beats the battle bed by 7.0 dB (mid band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | bolt_shot_2 | low 0% / mid 63% / pres 18% / air 18% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | bolt_shot_1 | low 0% / mid 80% / pres 11% / air 8% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | bolt_shot | low 0% / mid 61% / pres 16% / air 23% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | bolt_impact_2 | low 12% / mid 79% / pres 7% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | bolt_impact_1 | low 20% / mid 63% / pres 13% / air 3% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | bolt_impact | low 16% / mid 69% / pres 11% / air 4% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_whip | low 0% / mid 25% / pres 35% / air 39% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_storm | low 0% / mid 70% / pres 19% / air 11% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_siege | low 68% / mid 4% / pres 13% / air 15% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_magic | low 2% / mid 92% / pres 3% / air 3% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_heavy | low 48% / mid 10% / pres 22% / air 20% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_bow | low 72% / mid 9% / pres 10% / air 9% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_bolt | low 48% / mid 42% / pres 4% / air 6% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_blade | low 0% / mid 23% / pres 37% / air 40% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_beast | low 59% / mid 35% / pres 4% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | alert_wizard_fell | beats the battle bed by 9.5 dB (low band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | alert_wizard_fell | low 59% / mid 41% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ability_cast | low 0% / mid 87% / pres 8% / air 4% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | defeat | low 49% / mid 51% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_whip | low 48% / mid 40% / pres 10% / air 3% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_storm | low 14% / mid 35% / pres 25% / air 26% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_siege | low 70% / mid 23% / pres 6% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_shadow | low 8% / mid 92% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_magic | low 7% / mid 93% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_heavy | low 60% / mid 36% / pres 3% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_fire | low 8% / mid 84% / pres 3% / air 5% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_bow | low 4% / mid 85% / pres 8% / air 3% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_bolt | low 27% / mid 65% / pres 6% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_blade | low 15% / mid 79% / pres 5% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_beast | low 2% / mid 95% / pres 3% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | crystals_delivered | low 0% / mid 58% / pres 40% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | crown_claimed | beats the battle bed by 8.8 dB (mid band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | crown_claimed | low 1% / mid 95% / pres 4% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | construction_done | low 3% / mid 95% / pres 2% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | building_hit_2 | low 71% / mid 16% / pres 10% / air 3% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | building_hit_1 | low 81% / mid 12% / pres 5% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | building_collapse | beats the battle bed by 7.6 dB (low band) | alert >= +3 dB over 6 combat voices in one band |  |

### Memory and disk

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | level_up | 41 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | item_used | 17 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | item_pickup | 11 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | item_bought | 14 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_whip | 9 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_storm | 15 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_siege | 17 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_magic | 10 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_heavy | 13 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_bow | 7 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_bolt | 9 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_blade | 8 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_beast | 10 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | fireball_explode | 47 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | fireball_cast | 24 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | defeat | 121 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_whip | 26 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | set | 0.3 MB in memory | set <= 48 MB |  |
| PASS | victory | 121 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | unit_trained | 19 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ui_error | 13 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ui_click | 3 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | spell_umbral_shroud | 39 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | spell_soul_siphon | 47 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | spell_shadow_lance | 22 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | spell_kindle | 34 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | spell_ember_step | 19 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | skill_hit | 12 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | mine_tick_2 | 4 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | mine_tick_1 | 5 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | mine_tick | 4 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | melee_hit_2 | 8 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | melee_hit_1 | 9 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | melee_hit | 9 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | bolt_shot_2 | 10 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | bolt_shot_1 | 11 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | bolt_shot | 10 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | bolt_impact_2 | 6 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | bolt_impact_1 | 6 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | bolt_impact | 6 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_whip | 11 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_storm | 17 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_siege | 19 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_magic | 17 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_heavy | 13 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_bow | 10 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_bolt | 11 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_blade | 9 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_beast | 13 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | alert_wizard_fell | 60 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ability_cast | 19 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_storm | 39 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_siege | 39 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_shadow | 34 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_magic | 34 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_heavy | 32 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_fire | 28 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_bow | 24 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_bolt | 28 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_blade | 24 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_beast | 34 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | crystals_delivered | 17 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | crown_claimed | 60 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | construction_done | 32 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | building_hit_2 | 12 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | building_hit_1 | 14 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | building_hit | 13 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | building_collapse | 78 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |

### Bus routing

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | res://scripts/audio/game_audio.gd:627 | AudioStreamPlayer3D on bus SFX | bus in Music, SFX, Voice |  |
| PASS | res://scripts/audio/game_audio.gd:638 | AudioStreamPlayer on bus SFX | bus in Music, SFX, Voice |  |
| PASS | res://scripts/audio/game_audio.gd:642 | AudioStreamPlayer on bus Music | bus in Music, SFX, Voice |  |

### Variation

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | defeat | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | fireball_cast | 1 take(s), pitch +-7%, ~6/min | occasional cue (< 20/min): one take is fine |  |
| PASS | fireball_explode | 1 take(s), pitch +-7%, ~6/min | occasional cue (< 20/min): one take is fine |  |
| PASS | hit_beast | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | hit_blade | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | hit_bolt | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | hit_bow | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | hit_heavy | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | hit_magic | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | hit_siege | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | hit_storm | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | hit_whip | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | item_bought | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | item_pickup | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | item_used | 1 take(s), pitch +-0%, ~3/min | occasional cue (< 20/min): one take is fine |  |
| PASS | level_up | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | melee_hit | 3 take(s), pitch +-7%, ~120/min | frequent cue: >= 3 takes, or 2 takes + pitch / volume randomisation |  |
| PASS | mine_tick | 3 take(s), pitch +-7%, ~60/min | frequent cue: >= 3 takes, or 2 takes + pitch / volume randomisation |  |
| PASS | skill_hit | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | spell_ember_step | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | spell_kindle | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | spell_shadow_lance | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | spell_soul_siphon | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | spell_umbral_shroud | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ui_click | 1 take(s), pitch +-0%, ~30/min | UI cues stay identical on purpose (consistency) |  |
| PASS | ui_error | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | unit_trained | 1 take(s), pitch +-7%, ~4/min | occasional cue (< 20/min): one take is fine |  |
| PASS | victory | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ability_cast | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | alert_wizard_fell | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | atk_beast | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | atk_blade | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | atk_bolt | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | atk_bow | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | atk_heavy | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | atk_magic | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | atk_siege | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | atk_storm | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | atk_whip | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | bolt_impact | 3 take(s), pitch +-7%, ~120/min | frequent cue: >= 3 takes, or 2 takes + pitch / volume randomisation |  |
| PASS | bolt_shot | 3 take(s), pitch +-7%, ~120/min | frequent cue: >= 3 takes, or 2 takes + pitch / volume randomisation |  |
| PASS | building_collapse | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | building_hit | 3 take(s), pitch +-7%, ~40/min | frequent cue: >= 3 takes, or 2 takes + pitch / volume randomisation |  |
| PASS | construction_done | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | crown_claimed | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | crystals_delivered | 1 take(s), pitch +-0%, ~20/min | UI cues stay identical on purpose (consistency) |  |
| PASS | death_beast | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | death_blade | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | death_bolt | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | death_bow | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | death_fire | 1 take(s), pitch +-7%, ~12/min | occasional cue (< 20/min): one take is fine |  |
| PASS | death_heavy | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | death_magic | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | death_shadow | 1 take(s), pitch +-7%, ~12/min | occasional cue (< 20/min): one take is fine |  |
| PASS | death_siege | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | death_storm | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | death_whip | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |

### 3D attenuation

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | res://scripts/audio/game_audio.gd:627 | unit_size 18, max_distance 75, inverse_distance; -4.4 dB @30 m, -9.7 dB @55 m, -12.4 dB @cut | gain >= -15 dB at 30 m, <= -10 dB at the cut-off |  |

### Voice limits

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | ui_click | rate limit 0.0 s | frequent cue has a per-cue cooldown >= 0.03 s |  |
| PASS | mine_tick_2 | rate limit 0.1 s | frequent cue has a per-cue cooldown >= 0.03 s |  |
| PASS | mine_tick_1 | rate limit 0.1 s | frequent cue has a per-cue cooldown >= 0.03 s |  |
| PASS | mine_tick | rate limit 0.1 s | frequent cue has a per-cue cooldown >= 0.03 s |  |
| PASS | melee_hit_2 | rate limit 0.1 s | frequent cue has a per-cue cooldown >= 0.03 s |  |
| PASS | melee_hit_1 | rate limit 0.1 s | frequent cue has a per-cue cooldown >= 0.03 s |  |
| PASS | melee_hit | rate limit 0.1 s | frequent cue has a per-cue cooldown >= 0.03 s |  |
| PASS | crystals_delivered | rate limit 0.3 s | frequent cue has a per-cue cooldown >= 0.03 s |  |
| PASS | building_hit_2 | rate limit 0.2 s | frequent cue has a per-cue cooldown >= 0.03 s |  |
| PASS | building_hit_1 | rate limit 0.2 s | frequent cue has a per-cue cooldown >= 0.03 s |  |
| PASS | building_hit | rate limit 0.2 s | frequent cue has a per-cue cooldown >= 0.03 s |  |
| PASS | bolt_shot_2 | rate limit 0.1 s | frequent cue has a per-cue cooldown >= 0.03 s |  |
| PASS | bolt_shot_1 | rate limit 0.1 s | frequent cue has a per-cue cooldown >= 0.03 s |  |
| PASS | bolt_shot | rate limit 0.1 s | frequent cue has a per-cue cooldown >= 0.03 s |  |
| PASS | bolt_impact_2 | rate limit 0.1 s | frequent cue has a per-cue cooldown >= 0.03 s |  |
| PASS | bolt_impact_1 | rate limit 0.1 s | frequent cue has a per-cue cooldown >= 0.03 s |  |
| PASS | bolt_impact | rate limit 0.1 s | frequent cue has a per-cue cooldown >= 0.03 s |  |
| PASS | players | 3 players (1 3D) (from code) | <= 64 players, 3D pool <= 32 |  |

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
| ability_cast | spell | 3d | -23.4 | -10.9 | -8.0 | -4.4 | -3.4 | 0.45 | 1 / 3 | 0/87/8/4 | 0 | 1 | +-7% | generated |
| alert_wizard_fell | alert | 2d | -9.0 | -9.0 | 0.0 | 0.0 | -2.5 | 1.40 | 0 / 50 | 59/41/0/0 | 0 | 1 | - | generated |
| atk_beast | unit | 3d | -25.6 | -15.1 | -6.0 | -4.4 | -2.8 | 0.30 | 0 / 66 | 59/35/4/2 | 0 | 1 | +-7% | generated |
| atk_blade | unit | 3d | -24.7 | -14.2 | -6.0 | -4.4 | -3.0 | 0.20 | 0 / 61 | 0/23/37/40 | 0 | 1 | +-7% | generated |
| atk_bolt | unit | 3d | -27.7 | -17.3 | -6.0 | -4.4 | -3.1 | 0.26 | 0 / 33 | 48/42/4/6 | 0 | 1 | +-7% | generated |
| atk_bow | unit | 3d | -28.9 | -17.5 | -7.0 | -4.4 | -4.0 | 0.24 | 0 / 44 | 72/9/10/9 | 0 | 1 | +-7% | generated |
| atk_heavy | unit | 3d | -21.2 | -10.8 | -6.0 | -4.4 | -3.3 | 0.30 | 0 / 23 | 48/10/22/20 | 0 | 1 | +-7% | generated |
| atk_magic | unit | 3d | -23.1 | -12.6 | -6.0 | -4.4 | -3.2 | 0.40 | 0 / 40 | 2/92/3/3 | 0 | 1 | +-7% | generated |
| atk_siege | unit | 3d | -23.2 | -12.8 | -6.0 | -4.4 | -2.6 | 0.45 | 0 / 52 | 68/4/13/15 | 0 | 1 | +-7% | generated |
| atk_storm | unit | 3d | -21.5 | -11.1 | -6.0 | -4.4 | -3.5 | 0.40 | 0 / 50 | 0/70/19/11 | 0 | 1 | +-7% | generated |
| atk_whip | unit | 3d | -23.7 | -13.3 | -6.0 | -4.4 | -3.6 | 0.26 | 0 / 76 | 0/25/35/39 | 0 | 1 | +-7% | generated |
| bolt_impact | unit | 3d | -30.7 | -19.3 | -7.0 | -4.4 | -2.4 | 0.14 | 0 / 46 | 16/69/11/4 | 120* | 3 | +-7% | generated |
| bolt_impact_1 | unit | 3d | -30.6 | -19.2 | -7.0 | -4.4 | -2.4 | 0.15 | 0 / 53 | 20/63/13/3 | 120* | 3 | +-7% | generated |
| bolt_impact_2 | unit | 3d | -31.2 | -19.8 | -7.0 | -4.4 | -2.8 | 0.13 | 0 / 43 | 12/79/7/2 | 120* | 3 | +-7% | generated |
| bolt_shot | unit | 3d | -31.7 | -19.2 | -8.0 | -4.4 | -3.9 | 0.24 | 0 / 46 | 0/61/16/23 | 120* | 3 | +-7% | generated |
| bolt_shot_1 | unit | 3d | -31.7 | -19.2 | -8.0 | -4.4 | -2.8 | 0.25 | 0 / 50 | 0/80/11/8 | 120* | 3 | +-7% | generated |
| bolt_shot_2 | unit | 3d | -31.9 | -19.4 | -8.0 | -4.4 | -3.7 | 0.23 | 0 / 43 | 0/63/18/18 | 120* | 3 | +-7% | generated |
| building_collapse | alert | 3d | -12.9 | -8.5 | 0.0 | -4.4 | -0.5 | 1.80 | 0 / 50 | 93/6/1/0 | 0 | 1 | +-7% | generated |
| building_hit | unit | 3d | -25.3 | -15.8 | -5.0 | -4.4 | -1.7 | 0.30 | 0 / 53 | 93/5/1/0 | 40* | 3 | +-7% | generated |
| building_hit_1 | unit | 3d | -28.5 | -19.1 | -5.0 | -4.4 | -3.7 | 0.32 | 0 / 60 | 81/12/5/1 | 40* | 3 | +-7% | generated |
| building_hit_2 | unit | 3d | -30.3 | -20.9 | -5.0 | -4.4 | -6.0 | 0.28 | 0 / 70 | 71/16/10/3 | 40* | 3 | +-7% | generated |
| construction_done | alert | 3d | -14.5 | -10.1 | 0.0 | -4.4 | -2.3 | 0.75 | 0 / 1 | 3/95/2/0 | 0 | 1 | +-7% | generated |
| crown_claimed | alert | 2d | -8.6 | -8.6 | 0.0 | 0.0 | -1.7 | 1.40 | 0 / 100 | 1/95/4/0 | 0 | 1 | - | generated |
| crystals_delivered | ui | 2d | -21.8 | -11.8 | -10.0 | 0.0 | -5.4 | 0.40 | 0 / 12 | 0/58/40/2 | 20* | 1 | - | generated |
| death_beast | unit | 3d | -18.1 | -9.2 | -4.5 | -4.4 | -2.6 | 0.80 | 0 / 50 | 2/95/3/0 | 0 | 1 | +-7% | generated |
| death_blade | unit | 3d | -19.2 | -12.8 | -2.0 | -4.4 | -2.1 | 0.55 | 0 / 101 | 15/79/5/2 | 0 | 1 | +-7% | generated |
| death_bolt | unit | 3d | -19.4 | -12.0 | -3.0 | -4.4 | -2.4 | 0.65 | 0 / 102 | 27/65/6/2 | 0 | 1 | +-7% | generated |
| death_bow | unit | 3d | -20.0 | -12.6 | -3.0 | -4.4 | -2.9 | 0.55 | 0 / 50 | 4/85/8/3 | 0 | 1 | +-7% | generated |
| death_fire | unit | 3d | -19.3 | -11.9 | -3.0 | -4.4 | -2.2 | 0.65 | 0 / 101 | 8/84/3/5 | 12 | 1 | +-7% | generated |
| death_heavy | unit | 3d | -19.2 | -11.8 | -3.0 | -4.4 | -2.8 | 0.75 | 0 / 98 | 60/36/3/1 | 0 | 1 | +-7% | generated |
| death_magic | unit | 3d | -17.7 | -10.2 | -3.0 | -4.4 | -2.7 | 0.80 | 0 / 50 | 7/93/0/0 | 0 | 1 | +-7% | generated |
| death_shadow | unit | 3d | -17.9 | -8.5 | -5.0 | -4.4 | -2.0 | 0.80 | 0 / 51 | 8/92/0/0 | 12 | 1 | +-7% | generated |
| death_siege | unit | 3d | -18.0 | -10.5 | -3.0 | -4.4 | -1.7 | 0.90 | 0 / 101 | 70/23/6/2 | 0 | 1 | +-7% | generated |
| death_storm | unit | 3d | -18.3 | -8.8 | -5.0 | -4.4 | -3.5 | 0.90 | 1 / 50 | 14/35/25/26 | 0 | 1 | +-7% | generated |
| death_whip | unit | 3d | -18.7 | -10.8 | -3.5 | -4.4 | -1.9 | 0.60 | 0 / 51 | 48/40/10/3 | 0 | 1 | +-7% | generated |
| defeat | alert | 2d | -7.6 | -7.6 | 0.0 | 0.0 | -1.9 | 2.80 | 0 / 0 | 49/51/0/0 | 0 | 1 | - | generated |
| fireball_cast | spell | 3d | -12.7 | -8.2 | 0.0 | -4.4 | -1.3 | 0.55 | 0 / 50 | 46/50/3/1 | 6 | 1 | +-7% | generated |
| fireball_explode | spell | 3d | -14.1 | -9.7 | 0.0 | -4.4 | -0.3 | 1.10 | 0 / 55 | 80/15/4/1 | 6 | 1 | +-7% | generated |
| hit_beast | unit | 3d | -26.4 | -17.0 | -5.0 | -4.4 | -3.2 | 0.22 | 0 / 41 | 2/92/4/1 | 0 | 1 | +-7% | generated |
| hit_blade | unit | 3d | -29.3 | -19.9 | -5.0 | -4.4 | -2.2 | 0.18 | 0 / 93 | 19/49/21/10 | 0 | 1 | +-7% | generated |
| hit_bolt | unit | 3d | -27.3 | -17.9 | -5.0 | -4.4 | -2.9 | 0.20 | 0 / 60 | 69/24/6/2 | 0 | 1 | +-7% | generated |
| hit_bow | unit | 3d | -28.2 | -20.8 | -3.0 | -4.4 | -2.4 | 0.16 | 0 / 69 | 12/72/11/5 | 0 | 1 | +-7% | generated |
| hit_heavy | unit | 3d | -27.7 | -18.3 | -5.0 | -4.4 | -2.3 | 0.30 | 0 / 23 | 30/63/5/2 | 0 | 1 | +-7% | generated |
| hit_magic | unit | 3d | -25.8 | -16.4 | -5.0 | -4.4 | -3.4 | 0.24 | 0 / 43 | 1/85/12/2 | 0 | 1 | +-7% | generated |
| hit_siege | unit | 3d | -25.4 | -15.0 | -6.0 | -4.4 | -2.7 | 0.40 | 0 / 54 | 46/34/15/5 | 0 | 1 | +-7% | generated |
| hit_storm | unit | 3d | -24.2 | -13.8 | -6.0 | -4.4 | -2.9 | 0.35 | 0 / 54 | 36/31/24/10 | 0 | 1 | +-7% | generated |
| hit_whip | unit | 3d | -27.6 | -18.2 | -5.0 | -4.4 | -3.0 | 0.20 | 0 / 45 | 24/41/26/9 | 0 | 1 | +-7% | generated |
| item_bought | ui | 2d | -16.1 | -12.1 | -4.0 | 0.0 | -4.2 | 0.32 | 0 / 1 | 0/64/34/1 | 0 | 1 | - | generated |
| item_pickup | ui | both | -15.0 | -15.0 | 0.0 | 0.0 | -4.4 | 0.26 | 0 / 2 | 0/95/4/0 | 0 | 1 | +-7% | generated |
| item_used | ui | 2d | -15.8 | -9.8 | -6.0 | 0.0 | -4.4 | 0.40 | 0 / 20 | 0/99/0/1 | 3 | 1 | - | generated |
| level_up | alert | both | -10.4 | -10.4 | 0.0 | 0.0 | -1.8 | 0.95 | 0 / 2 | 3/95/2/0 | 0 | 1 | +-7% | generated |
| melee_hit | unit | 3d | -26.5 | -18.0 | -4.0 | -4.4 | -1.8 | 0.20 | 0 / 75 | 74/17/7/2 | 120* | 3 | +-7% | generated |
| melee_hit_1 | unit | 3d | -27.6 | -19.1 | -4.0 | -4.4 | -2.2 | 0.21 | 0 / 80 | 69/20/10/2 | 120* | 3 | +-7% | generated |
| melee_hit_2 | unit | 3d | -27.4 | -19.0 | -4.0 | -4.4 | -2.3 | 0.19 | 0 / 68 | 78/17/5/1 | 120* | 3 | +-7% | generated |
| mine_tick | unit | 3d | -34.9 | -22.4 | -8.0 | -4.4 | -6.5 | 0.10 | 0 / 58 | 0/16/83/1 | 60* | 3 | +-7% | generated |
| mine_tick_1 | unit | 3d | -34.5 | -22.1 | -8.0 | -4.4 | -6.8 | 0.11 | 0 / 62 | 0/27/72/1 | 60* | 3 | +-7% | generated |
| mine_tick_2 | unit | 3d | -34.6 | -22.2 | -8.0 | -4.4 | -6.7 | 0.09 | 0 / 53 | 0/10/89/1 | 60* | 3 | +-7% | generated |
| skill_hit | unit | 3d | -27.7 | -17.3 | -6.0 | -4.4 | -1.9 | 0.28 | 0 / 52 | 70/21/7/2 | 0 | 1 | +-7% | generated |
| spell_ember_step | spell | 3d | -11.3 | -6.9 | 0.0 | -4.4 | -0.7 | 0.45 | 0 / 31 | 4/77/9/11 | 0 | 1 | +-7% | generated |
| spell_kindle | spell | 3d | -12.6 | -8.1 | 0.0 | -4.4 | -1.4 | 0.80 | 0 / 50 | 5/94/1/0 | 0 | 1 | +-7% | generated |
| spell_shadow_lance | spell | 3d | -15.9 | -11.5 | 0.0 | -4.4 | -1.0 | 0.50 | 0 / 52 | 1/94/5/0 | 0 | 1 | +-7% | generated |
| spell_soul_siphon | spell | 3d | -11.3 | -6.8 | 0.0 | -4.4 | -2.0 | 1.10 | 1 / 50 | 76/24/0/0 | 0 | 1 | +-7% | generated |
| spell_umbral_shroud | spell | 3d | -12.0 | -7.5 | 0.0 | -4.4 | -1.8 | 0.90 | 1 / 50 | 98/2/0/0 | 0 | 1 | +-7% | generated |
| ui_click | ui | 2d | -33.7 | -25.7 | -8.0 | 0.0 | -8.2 | 0.06 | 0 / 31 | 0/98/2/0 | 30* | 1 | - | generated |
| ui_error | alert | 2d | -13.7 | -9.7 | -4.0 | 0.0 | -6.0 | 0.30 | 0 / 20 | 80/20/0/0 | 0 | 1 | - | generated |
| unit_trained | alert | 3d | -17.0 | -8.6 | -4.0 | -4.4 | -4.5 | 0.45 | 0 / 10 | 50/50/0/0 | 4 | 1 | +-7% | generated |
| victory | alert | 2d | -8.7 | -8.7 | 0.0 | 0.0 | -1.3 | 2.80 | 0 / 50 | 22/77/1/0 | 0 | 1 | - | generated |

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

67 / 67 files are generated placeholders (sine / noise tones from a generator script). The numbers above judge the level, timing and routing they give the mix; a real sound must keep those and add:

- **spell**: 44.1/48 kHz mono WAV, one cast + one impact per spell, 0.3-2 s, a faction signature (fire = crackle / roar, shadow = breathy whoosh / reverse swell, ice = crystalline, nature = wood / leaves), tail matched to the VFX.
- **alert**: 44.1/48 kHz mono (stereo only for 2D stingers), 0.3-3 s, strong 1-5 kHz content so it cuts through the fight, a distinct pitch contour per meaning (rising = good, falling = danger), peak <= -1 dBTP.
- **unit**: 44.1/48 kHz mono WAV, 3-5 takes per frequent cue (<id>_1.wav ... or an AudioStreamRandomizer .tres), 80-600 ms, transient in the first 5 ms, tail <= 400 ms for hits, peak <= -1 dBTP; recorded / layered foley, not synth.
- **ui**: 44.1/48 kHz mono, 16-bit WAV, 40-250 ms, peak <= -1 dBTP, cue loudness about -20 LUFS before volume_db, energy in 1-6 kHz, no lead silence (< 5 ms), one family feel for every UI cue.
- Every file: original or CC0 only (note the source in the file's folder), 16-bit WAV for SFX / Ogg for music, no clipping, trimmed start, faded end.

## Limits

- Loudness is a BS.1770 approximation on the 44.1 kHz decode (dual mono counted as 2 channels, as the game plays it); true peak is a 4x interpolation estimate.
- Masking uses 4 bands and a synthetic battle bed (6 unit cues at once), not a real mix; listen in the preview.
- Code facts come from patterns (DIR / DICT / PATH consts, `*.new()` players) and, for scene=, the live players; a sound played in an unusual way can be missed.
- Numbers can't judge taste, timbre or meaning: fill the listening sheet.
