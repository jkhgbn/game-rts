# Audio Lab scorecard: sfx_orders

- Date: 2026-09-27 18:48:30
- Command: `godot --headless --path . -s tools/audio_lab/audio_lab.gd -- set=res://assets/audio/sfx name=sfx_orders`
- set: `res://assets/audio/sfx`, kind `auto`, 189 cues, 3 players judged
- Missing cues are listed for context but not scored (set is not the whole game; use scene= or set=res://assets/audio).

## Score: 100 / 100

PASS 1530 | WARN 13 | FAIL 0 | INFO 0

| Group | Weight | PASS | WARN | FAIL | INFO | Group score |
|---|---|---|---|---|---|---|
| Loudness (in game) | 18 | 230 | 2 | 0 | 0 | 100 % |
| Peaks and clipping | 10 | 186 | 3 | 0 | 0 | 99 % |
| Duration, silence, tails | 8 | 567 | 1 | 0 | 0 | 100 % |
| Spectral balance and masking | 10 | 200 | 7 | 0 | 0 | 98 % |
| Memory and disk | 5 | 190 | 0 | 0 | 0 | 100 % |
| Bus routing | 12 | 3 | 0 | 0 | 0 | 100 % |
| Variation | 10 | 105 | 0 | 0 | 0 | 100 % |
| 3D attenuation | 5 | 1 | 0 | 0 | 0 | 100 % |
| Voice limits | 7 | 21 | 0 | 0 | 0 | 100 % |
| Missing cues | 15 | 27 | 1 | 0 | 14 | not scored |

## Improve next

1. **WARN Loudness (in game)** - Raise the in-game level into the range (volume_db in game_audio.gd, or re-render the file)  _(ability_cast +3 dB; spell: -22..-9 cue)_
2. **WARN Loudness (in game)** - Re-level the takes (or re-render them) so a random pick never jumps out of the mix.  _(building_hit takes; takes of one cue within 2.0 dB)_
3. **WARN Peaks and clipping** - The source file itself peaks at -0.4 dBFS (the import adds -0.1 dB): normalise the file to -1 dBTP.  _(building_collapse, fireball_explode, spell_ember_step; true peak <= -1 dBTP, no clipping)_
4. **WARN Spectral balance and masking** - Add 1-4 kHz content (attack, harmonics): all-bass cues vanish on laptop speakers and mud the mix.  _(building_collapse, building_hit, spell_umbral_shroud; not all-bass (< 85% low), not all-hiss (< 60% air))_
5. **WARN Spectral balance and masking** - Give it energy where the fight is thin (2-5 kHz presence), or +1 dB; a distinct pitch contour helps.  _(construction_done, unit_trained; alert >= +3 dB over 6 combat voices in one band)_
6. **WARN Spectral balance and masking** - Add 2-5 kHz content so the UI cue reads on small speakers.  _(item_used, ui_click; not all-bass (< 85% low), not all-hiss (< 60% air))_
7. **WARN Duration, silence, tails** - Add a 5-20 ms fade-out at the end (click).  _(defeat; fade to silence (last 10 ms < -45 dB))_
8. **Replace placeholders** - 115 of 189 files are generated tones (see "What a real replacement needs"); start with the most played cues (combat hits, shots, deaths) and the alerts.

## Checks

### Loudness (in game)

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| WARN | ability_cast | -23.4 LUFS in game (file -10.9, vol -8.0 dB, 3D -4.4 dB) | spell: -22..-9 cue | Raise the in-game level into the range (volume_db in game_audio.gd, or re-render the file) |
| WARN | building_hit takes | spread 5.1 dB (building_hit, building_hit_1, building_hit_2) | takes of one cue within 2.0 dB | Re-level the takes (or re-render them) so a random pick never jumps out of the mix. |
| PASS | hit_siege | -25.4 LUFS in game (file -15.0, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_siege_1 | -25.8 LUFS in game (file -15.4, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_siege_2 | -25.2 LUFS in game (file -14.7, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_storm | -24.2 LUFS in game (file -13.8, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_storm_1 | -24.5 LUFS in game (file -14.0, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_storm_2 | -24.3 LUFS in game (file -13.8, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_whip | -27.6 LUFS in game (file -18.2, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_whip_1 | -28.3 LUFS in game (file -18.8, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_whip_2 | -27.3 LUFS in game (file -17.9, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | item_bought | -16.1 LUFS in game (file -12.1, vol -4.0 dB, 3D 0.0 dB) | ui: -30..-14 cue |  |
| PASS | item_pickup | -15.0 LUFS in game (file -15.0, vol 0.0 dB, 3D 0.0 dB) | ui: -30..-14 cue |  |
| PASS | item_used | -15.8 LUFS in game (file -9.8, vol -6.0 dB, 3D 0.0 dB) | ui: -30..-14 cue |  |
| PASS | level_up | -10.4 LUFS in game (file -10.4, vol 0.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | melee_hit | -26.5 LUFS in game (file -18.0, vol -4.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | melee_hit_1 | -27.6 LUFS in game (file -19.1, vol -4.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | melee_hit_2 | -27.4 LUFS in game (file -19.0, vol -4.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | mine_tick | -34.9 LUFS in game (file -22.4, vol -8.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | mine_tick_1 | -34.5 LUFS in game (file -22.1, vol -8.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | mine_tick_2 | -34.6 LUFS in game (file -22.2, vol -8.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | skill_hit | -27.7 LUFS in game (file -17.3, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | spell_ember_step | -11.3 LUFS in game (file -6.9, vol 0.0 dB, 3D -4.4 dB) | spell: -22..-9 cue |  |
| PASS | spell_kindle | -12.6 LUFS in game (file -8.1, vol 0.0 dB, 3D -4.4 dB) | spell: -22..-9 cue |  |
| PASS | spell_shadow_lance | -15.9 LUFS in game (file -11.5, vol 0.0 dB, 3D -4.4 dB) | spell: -22..-9 cue |  |
| PASS | spell_snow_shield_off | -16.7 LUFS in game (file -12.2, vol 0.0 dB, 3D -4.4 dB) | spell: -22..-9 cue |  |
| PASS | spell_snow_shield_on | -12.7 LUFS in game (file -8.3, vol 0.0 dB, 3D -4.4 dB) | spell: -22..-9 cue |  |
| PASS | spell_soul_siphon | -11.3 LUFS in game (file -6.8, vol 0.0 dB, 3D -4.4 dB) | spell: -22..-9 cue |  |
| PASS | spell_umbral_shroud | -12.0 LUFS in game (file -7.5, vol 0.0 dB, 3D -4.4 dB) | spell: -22..-9 cue |  |
| PASS | spell_vigor_off | -18.0 LUFS in game (file -13.6, vol 0.0 dB, 3D -4.4 dB) | spell: -22..-9 cue |  |
| PASS | fx_burn_1 | -24.8 LUFS in game (file -14.3, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | fx_burn_2 | -25.5 LUFS in game (file -15.1, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | fx_chill | -23.7 LUFS in game (file -13.3, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | fx_chill_1 | -24.1 LUFS in game (file -13.7, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | fx_chill_2 | -23.4 LUFS in game (file -13.0, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | fx_crit | -27.2 LUFS in game (file -16.8, vol -6.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | fx_crit_1 | -27.5 LUFS in game (file -17.1, vol -6.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | fx_crit_2 | -27.0 LUFS in game (file -16.5, vol -6.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | helper_cast | -21.9 LUFS in game (file -12.4, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | helper_cast_1 | -22.0 LUFS in game (file -12.5, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | helper_cast_2 | -21.9 LUFS in game (file -12.5, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_beast | -26.4 LUFS in game (file -17.0, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_beast_1 | -26.5 LUFS in game (file -17.0, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_beast_2 | -26.3 LUFS in game (file -16.9, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_blade | -29.3 LUFS in game (file -19.9, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_blade_1 | -29.7 LUFS in game (file -20.2, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_blade_2 | -29.0 LUFS in game (file -19.6, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_bolt | -27.3 LUFS in game (file -17.9, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_bolt_1 | -27.5 LUFS in game (file -18.1, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_bolt_2 | -27.0 LUFS in game (file -17.6, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_bow | -28.2 LUFS in game (file -20.8, vol -3.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_bow_1 | -28.3 LUFS in game (file -20.9, vol -3.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_bow_2 | -28.1 LUFS in game (file -20.6, vol -3.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_heavy | -27.7 LUFS in game (file -18.3, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_heavy_1 | -27.9 LUFS in game (file -18.4, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_heavy_2 | -27.6 LUFS in game (file -18.2, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_magic | -25.8 LUFS in game (file -16.4, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_magic_1 | -26.1 LUFS in game (file -16.6, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | hit_magic_2 | -26.3 LUFS in game (file -16.9, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | bolt_impact takes | spread 0.6 dB (bolt_impact, bolt_impact_1, bolt_impact_2) | takes of one cue within 2.0 dB |  |
| PASS | bolt_shot takes | spread 0.2 dB (bolt_shot, bolt_shot_1, bolt_shot_2) | takes of one cue within 2.0 dB |  |
| PASS | death_beast takes | spread 0.2 dB (death_beast, death_beast_1, death_beast_2) | takes of one cue within 2.0 dB |  |
| PASS | death_blade takes | spread 0.4 dB (death_blade, death_blade_1, death_blade_2) | takes of one cue within 2.0 dB |  |
| PASS | death_bolt takes | spread 0.1 dB (death_bolt, death_bolt_1, death_bolt_2) | takes of one cue within 2.0 dB |  |
| PASS | death_bow takes | spread 0.2 dB (death_bow, death_bow_1, death_bow_2) | takes of one cue within 2.0 dB |  |
| PASS | death_heavy takes | spread 0.2 dB (death_heavy, death_heavy_1, death_heavy_2) | takes of one cue within 2.0 dB |  |
| PASS | death_magic takes | spread 0.1 dB (death_magic, death_magic_1, death_magic_2) | takes of one cue within 2.0 dB |  |
| PASS | death_siege takes | spread 1.4 dB (death_siege, death_siege_1, death_siege_2) | takes of one cue within 2.0 dB |  |
| PASS | death_storm takes | spread 0.1 dB (death_storm, death_storm_1, death_storm_2) | takes of one cue within 2.0 dB |  |
| PASS | death_whip takes | spread 0.9 dB (death_whip, death_whip_1, death_whip_2) | takes of one cue within 2.0 dB |  |
| PASS | fx_bleed takes | spread 0.2 dB (fx_bleed, fx_bleed_1, fx_bleed_2) | takes of one cue within 2.0 dB |  |
| PASS | fx_burn takes | spread 0.8 dB (fx_burn, fx_burn_1, fx_burn_2) | takes of one cue within 2.0 dB |  |
| PASS | fx_chill takes | spread 0.7 dB (fx_chill, fx_chill_1, fx_chill_2) | takes of one cue within 2.0 dB |  |
| PASS | fx_crit takes | spread 0.5 dB (fx_crit, fx_crit_1, fx_crit_2) | takes of one cue within 2.0 dB |  |
| PASS | helper_cast takes | spread 0.1 dB (helper_cast, helper_cast_1, helper_cast_2) | takes of one cue within 2.0 dB |  |
| PASS | hit_beast takes | spread 0.1 dB (hit_beast, hit_beast_1, hit_beast_2) | takes of one cue within 2.0 dB |  |
| PASS | hit_blade takes | spread 0.6 dB (hit_blade, hit_blade_1, hit_blade_2) | takes of one cue within 2.0 dB |  |
| PASS | hit_bolt takes | spread 0.5 dB (hit_bolt, hit_bolt_1, hit_bolt_2) | takes of one cue within 2.0 dB |  |
| PASS | hit_bow takes | spread 0.2 dB (hit_bow, hit_bow_1, hit_bow_2) | takes of one cue within 2.0 dB |  |
| PASS | hit_heavy takes | spread 0.2 dB (hit_heavy, hit_heavy_1, hit_heavy_2) | takes of one cue within 2.0 dB |  |
| PASS | hit_magic takes | spread 0.5 dB (hit_magic, hit_magic_1, hit_magic_2) | takes of one cue within 2.0 dB |  |
| PASS | hit_siege takes | spread 0.6 dB (hit_siege, hit_siege_1, hit_siege_2) | takes of one cue within 2.0 dB |  |
| PASS | hit_storm takes | spread 0.3 dB (hit_storm, hit_storm_1, hit_storm_2) | takes of one cue within 2.0 dB |  |
| PASS | hit_whip takes | spread 1.0 dB (hit_whip, hit_whip_1, hit_whip_2) | takes of one cue within 2.0 dB |  |
| PASS | melee_hit takes | spread 1.1 dB (melee_hit, melee_hit_1, melee_hit_2) | takes of one cue within 2.0 dB |  |
| PASS | mine_tick takes | spread 0.4 dB (mine_tick, mine_tick_1, mine_tick_2) | takes of one cue within 2.0 dB |  |
| PASS | ui_tab takes | spread 0.7 dB (ui_tab, ui_tab_1, ui_tab_2) | takes of one cue within 2.0 dB |  |
| PASS | spell_vigor_on | -14.8 LUFS in game (file -10.4, vol 0.0 dB, 3D -4.4 dB) | spell: -22..-9 cue |  |
| PASS | ui_click | -33.7 LUFS in game (file -25.7, vol -8.0 dB, 3D 0.0 dB) | ui (frequent): -36..-20 cue |  |
| PASS | ui_error | -13.7 LUFS in game (file -9.7, vol -4.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | ui_helper_call | -18.4 LUFS in game (file -12.4, vol -6.0 dB, 3D 0.0 dB) | ui: -30..-14 cue |  |
| PASS | ui_hint | -22.4 LUFS in game (file -14.4, vol -8.0 dB, 3D 0.0 dB) | ui: -30..-14 cue |  |
| PASS | ui_plus_start | -23.0 LUFS in game (file -17.0, vol -6.0 dB, 3D 0.0 dB) | ui: -30..-14 cue |  |
| PASS | ui_restart | -21.4 LUFS in game (file -13.4, vol -8.0 dB, 3D 0.0 dB) | ui: -30..-14 cue |  |
| PASS | ui_tab | -28.1 LUFS in game (file -24.1, vol -4.0 dB, 3D 0.0 dB) | ui: -30..-14 cue |  |
| PASS | ui_tab_1 | -28.5 LUFS in game (file -24.5, vol -4.0 dB, 3D 0.0 dB) | ui: -30..-14 cue |  |
| PASS | ui_tab_2 | -27.8 LUFS in game (file -23.8, vol -4.0 dB, 3D 0.0 dB) | ui: -30..-14 cue |  |
| PASS | ui_tier_start | -24.2 LUFS in game (file -18.2, vol -6.0 dB, 3D 0.0 dB) | ui: -30..-14 cue |  |
| PASS | ui_tier_tick | -28.8 LUFS in game (file -24.8, vol -4.0 dB, 3D 0.0 dB) | ui: -30..-14 cue |  |
| PASS | ui_upgrade_cancel | -22.4 LUFS in game (file -16.4, vol -6.0 dB, 3D 0.0 dB) | ui: -30..-14 cue |  |
| PASS | unit_trained | -17.0 LUFS in game (file -8.6, vol -4.0 dB, 3D -4.4 dB) | alert: -22..-7 cue |  |
| PASS | victory | -8.7 LUFS in game (file -8.7, vol 0.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | death_* | spread 2.6 dB (death_beast, death_beast_1, death_beast_2, death_blade, death_blade_1, death_blade_2, death_bolt, death_bolt_1, death_bolt_2, death_bow, death_bow_1, death_bow_2, death_fire, death_heavy, death_heavy_1, death_heavy_2, death_magic, death_magic_1, death_magic_2, death_shadow, death_siege, death_siege_1, death_siege_2, death_storm, death_storm_1, death_storm_2, death_whip, death_whip_1, death_whip_2) | same-role cues within 3 dB |  |
| PASS | ab_frost_shell takes | spread 0.4 dB (ab_frost_shell, ab_frost_shell_1, ab_frost_shell_2) | takes of one cue within 2.0 dB |  |
| PASS | ab_genie_chain takes | spread 0.7 dB (ab_genie_chain, ab_genie_chain_1, ab_genie_chain_2) | takes of one cue within 2.0 dB |  |
| PASS | ab_piercing_bolt takes | spread 0.5 dB (ab_piercing_bolt, ab_piercing_bolt_1, ab_piercing_bolt_2) | takes of one cue within 2.0 dB |  |
| PASS | ab_skitter takes | spread 0.3 dB (ab_skitter, ab_skitter_1, ab_skitter_2) | takes of one cue within 2.0 dB |  |
| PASS | atk_beast takes | spread 0.4 dB (atk_beast, atk_beast_1, atk_beast_2) | takes of one cue within 2.0 dB |  |
| PASS | atk_blade takes | spread 0.2 dB (atk_blade, atk_blade_1, atk_blade_2) | takes of one cue within 2.0 dB |  |
| PASS | atk_bolt takes | spread 0.2 dB (atk_bolt, atk_bolt_1, atk_bolt_2) | takes of one cue within 2.0 dB |  |
| PASS | atk_bow takes | spread 0.3 dB (atk_bow, atk_bow_1, atk_bow_2) | takes of one cue within 2.0 dB |  |
| PASS | atk_heavy takes | spread 0.1 dB (atk_heavy, atk_heavy_1, atk_heavy_2) | takes of one cue within 2.0 dB |  |
| PASS | atk_magic takes | spread 0.0 dB (atk_magic, atk_magic_1, atk_magic_2) | takes of one cue within 2.0 dB |  |
| PASS | atk_siege takes | spread 0.6 dB (atk_siege, atk_siege_1, atk_siege_2) | takes of one cue within 2.0 dB |  |
| PASS | atk_storm takes | spread 0.5 dB (atk_storm, atk_storm_1, atk_storm_2) | takes of one cue within 2.0 dB |  |
| PASS | atk_whip takes | spread 0.3 dB (atk_whip, atk_whip_1, atk_whip_2) | takes of one cue within 2.0 dB |  |
| PASS | ab_wither_hex | -19.5 LUFS in game (file -10.1, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | alert_caravan_trained | -16.2 LUFS in game (file -10.8, vol -1.0 dB, 3D -4.4 dB) | alert: -22..-7 cue |  |
| PASS | alert_helper_arrive | -12.5 LUFS in game (file -10.5, vol -2.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | alert_helper_fall | -12.3 LUFS in game (file -8.3, vol -4.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | alert_helper_revive | -11.6 LUFS in game (file -9.6, vol -2.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | alert_path_int | -13.2 LUFS in game (file -9.2, vol -4.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | alert_path_str | -12.6 LUFS in game (file -10.1, vol -2.5 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | alert_plus_done | -13.0 LUFS in game (file -9.0, vol -4.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | alert_tier_citadel | -12.8 LUFS in game (file -10.8, vol -2.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | alert_tier_stronghold | -11.4 LUFS in game (file -8.4, vol -3.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | alert_wizard_fell | -9.0 LUFS in game (file -9.0, vol 0.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | atk_beast | -25.6 LUFS in game (file -15.1, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_beast_1 | -25.7 LUFS in game (file -15.3, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_beast_2 | -25.3 LUFS in game (file -14.9, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_blade | -24.7 LUFS in game (file -14.2, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_blade_1 | -24.6 LUFS in game (file -14.1, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_blade_2 | -24.8 LUFS in game (file -14.4, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_bolt | -27.7 LUFS in game (file -17.3, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_bolt_1 | -27.7 LUFS in game (file -17.2, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_bolt_2 | -27.9 LUFS in game (file -17.5, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_bow | -28.9 LUFS in game (file -17.5, vol -7.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_bow_1 | -28.8 LUFS in game (file -17.4, vol -7.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_bow_2 | -29.1 LUFS in game (file -17.7, vol -7.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_heavy | -21.2 LUFS in game (file -10.8, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_heavy_1 | -21.1 LUFS in game (file -10.6, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_heavy_2 | -21.2 LUFS in game (file -10.8, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_magic | -23.1 LUFS in game (file -12.6, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_magic_1 | -23.1 LUFS in game (file -12.6, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_magic_2 | -23.0 LUFS in game (file -12.6, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | ab_blood_frenzy | -20.9 LUFS in game (file -11.5, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | ab_challenge | -23.4 LUFS in game (file -13.9, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | ab_flame_burst | -18.7 LUFS in game (file -10.3, vol -4.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | ab_flashpoint | -22.1 LUFS in game (file -12.6, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | ab_frost_needle | -20.7 LUFS in game (file -10.3, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | ab_frost_shell | -23.1 LUFS in game (file -12.6, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | ab_frost_shell_1 | -22.9 LUFS in game (file -12.5, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | ab_frost_shell_2 | -23.3 LUFS in game (file -12.8, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | ab_genie_chain | -19.6 LUFS in game (file -9.2, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | ab_genie_chain_1 | -20.0 LUFS in game (file -9.6, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | ab_genie_chain_2 | -19.4 LUFS in game (file -8.9, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | ab_grave_feast | -21.1 LUFS in game (file -11.6, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | ab_grove_oath | -21.3 LUFS in game (file -11.9, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | ab_hold_the_line | -23.1 LUFS in game (file -13.7, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | ab_piercing_bolt | -27.2 LUFS in game (file -16.8, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | ab_piercing_bolt_1 | -27.2 LUFS in game (file -16.8, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | ab_piercing_bolt_2 | -27.7 LUFS in game (file -17.3, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | ab_sab_armed | -21.8 LUFS in game (file -12.4, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | ab_sab_blast | -18.3 LUFS in game (file -9.9, vol -4.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | ab_sab_disguise | -22.3 LUFS in game (file -12.9, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | ab_sab_plant | -24.7 LUFS in game (file -15.3, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | ab_sab_reveal | -22.1 LUFS in game (file -12.7, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | ab_seed_storm | -21.8 LUFS in game (file -12.3, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | ab_skitter | -27.6 LUFS in game (file -16.2, vol -7.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | ab_skitter_1 | -27.6 LUFS in game (file -16.1, vol -7.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | ab_skitter_2 | -27.9 LUFS in game (file -16.5, vol -7.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | ab_snare_lash | -18.5 LUFS in game (file -9.1, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | ab_tempest_bolt | -18.1 LUFS in game (file -9.7, vol -4.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | ab_unbroken_vow | -19.4 LUFS in game (file -9.9, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_bolt_1 | -19.5 LUFS in game (file -12.1, vol -3.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_bolt_2 | -19.5 LUFS in game (file -12.0, vol -3.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_bow | -20.0 LUFS in game (file -12.6, vol -3.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_bow_1 | -20.2 LUFS in game (file -12.8, vol -3.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_bow_2 | -20.0 LUFS in game (file -12.6, vol -3.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_fire | -19.3 LUFS in game (file -11.9, vol -3.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_heavy | -19.2 LUFS in game (file -11.8, vol -3.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_heavy_1 | -19.3 LUFS in game (file -11.9, vol -3.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_heavy_2 | -19.1 LUFS in game (file -11.7, vol -3.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_magic | -17.7 LUFS in game (file -10.2, vol -3.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_magic_1 | -17.7 LUFS in game (file -10.3, vol -3.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_magic_2 | -17.6 LUFS in game (file -10.2, vol -3.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_shadow | -17.9 LUFS in game (file -8.5, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_siege | -18.0 LUFS in game (file -10.5, vol -3.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_siege_1 | -18.6 LUFS in game (file -11.1, vol -3.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_siege_2 | -19.4 LUFS in game (file -12.0, vol -3.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_storm | -18.3 LUFS in game (file -8.8, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_storm_1 | -18.3 LUFS in game (file -8.8, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_storm_2 | -18.2 LUFS in game (file -8.7, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_whip | -18.7 LUFS in game (file -10.8, vol -3.5 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_whip_1 | -19.4 LUFS in game (file -11.5, vol -3.5 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_whip_2 | -18.5 LUFS in game (file -10.5, vol -3.5 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | defeat | -7.6 LUFS in game (file -7.6, vol 0.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | fireball_cast | -12.7 LUFS in game (file -8.2, vol 0.0 dB, 3D -4.4 dB) | spell: -22..-9 cue |  |
| PASS | fireball_explode | -14.1 LUFS in game (file -9.7, vol 0.0 dB, 3D -4.4 dB) | spell: -22..-9 cue |  |
| PASS | fx_bleed | -24.3 LUFS in game (file -13.8, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | fx_bleed_1 | -24.2 LUFS in game (file -13.7, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | fx_bleed_2 | -24.4 LUFS in game (file -13.9, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | fx_burn | -24.7 LUFS in game (file -14.3, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_siege | -23.2 LUFS in game (file -12.8, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_siege_1 | -23.1 LUFS in game (file -12.7, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_siege_2 | -23.7 LUFS in game (file -13.3, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_storm | -21.5 LUFS in game (file -11.1, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_storm_1 | -21.9 LUFS in game (file -11.4, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_storm_2 | -21.4 LUFS in game (file -11.0, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_whip | -23.7 LUFS in game (file -13.3, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_whip_1 | -23.5 LUFS in game (file -13.0, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | atk_whip_2 | -23.5 LUFS in game (file -13.1, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | bolt_impact | -30.7 LUFS in game (file -19.3, vol -7.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | bolt_impact_1 | -30.6 LUFS in game (file -19.2, vol -7.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | bolt_impact_2 | -31.2 LUFS in game (file -19.8, vol -7.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | bolt_shot | -31.7 LUFS in game (file -19.2, vol -8.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | bolt_shot_1 | -31.7 LUFS in game (file -19.2, vol -8.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | bolt_shot_2 | -31.9 LUFS in game (file -19.4, vol -8.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | building_collapse | -12.9 LUFS in game (file -8.5, vol 0.0 dB, 3D -4.4 dB) | alert: -22..-7 cue |  |
| PASS | building_hit | -25.3 LUFS in game (file -15.8, vol -5.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | building_hit_1 | -28.5 LUFS in game (file -19.1, vol -5.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | building_hit_2 | -30.3 LUFS in game (file -20.9, vol -5.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | construction_done | -14.5 LUFS in game (file -10.1, vol 0.0 dB, 3D -4.4 dB) | alert: -22..-7 cue |  |
| PASS | crown_claimed | -8.6 LUFS in game (file -8.6, vol 0.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | crystals_delivered | -21.8 LUFS in game (file -11.8, vol -10.0 dB, 3D 0.0 dB) | ui (frequent): -36..-20 cue |  |
| PASS | death_beast | -18.1 LUFS in game (file -9.2, vol -4.5 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_beast_1 | -18.2 LUFS in game (file -9.3, vol -4.5 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_beast_2 | -18.0 LUFS in game (file -9.1, vol -4.5 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_blade | -19.2 LUFS in game (file -12.8, vol -2.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_blade_1 | -19.6 LUFS in game (file -13.1, vol -2.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_blade_2 | -19.5 LUFS in game (file -13.0, vol -2.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_bolt | -19.4 LUFS in game (file -12.0, vol -3.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |

### Peaks and clipping

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| WARN | spell_ember_step | true peak -0.7 dBTP, 0 clipped runs, source -1.4 dBFS (QOA import +0.6 dB) | true peak <= -1 dBTP, no clipping | The source file itself peaks at -1.4 dBFS (the import adds +0.6 dB): normalise the file to -1 dBTP. |
| WARN | building_collapse | true peak -0.5 dBTP, 0 clipped runs, source -0.4 dBFS (QOA import -0.1 dB) | true peak <= -1 dBTP, no clipping | The source file itself peaks at -0.4 dBFS (the import adds -0.1 dB): normalise the file to -1 dBTP. |
| WARN | fireball_explode | true peak -0.3 dBTP, 0 clipped runs, source -0.4 dBFS (QOA import +0.2 dB) | true peak <= -1 dBTP, no clipping | The source file itself peaks at -0.4 dBFS (the import adds +0.2 dB): normalise the file to -1 dBTP. |
| PASS | fx_chill | true peak -4.0 dBTP, 0 clipped runs, source -4.2 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | fx_chill_1 | true peak -4.4 dBTP, 0 clipped runs, source -3.8 dBFS (QOA import -0.6 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | fx_chill_2 | true peak -4.1 dBTP, 0 clipped runs, source -4.7 dBFS (QOA import +0.5 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | fx_crit | true peak -2.9 dBTP, 0 clipped runs, source -3.1 dBFS (QOA import +0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | fx_crit_1 | true peak -3.3 dBTP, 0 clipped runs, source -3.4 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | fx_crit_2 | true peak -3.7 dBTP, 0 clipped runs, source -3.5 dBFS (QOA import -0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | helper_cast | true peak -3.4 dBTP, 0 clipped runs, source -3.1 dBFS (QOA import -0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | helper_cast_1 | true peak -3.1 dBTP, 0 clipped runs, source -3.2 dBFS (QOA import +0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | helper_cast_2 | true peak -2.3 dBTP, 0 clipped runs, source -2.5 dBFS (QOA import +0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_beast | true peak -3.2 dBTP, 0 clipped runs, source -3.4 dBFS (QOA import +0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_beast_1 | true peak -3.3 dBTP, 0 clipped runs, source -3.0 dBFS (QOA import -0.4 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_beast_2 | true peak -1.5 dBTP, 0 clipped runs, source -2.0 dBFS (QOA import +0.4 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_blade | true peak -2.2 dBTP, 0 clipped runs, source -2.9 dBFS (QOA import +0.4 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_blade_1 | true peak -3.4 dBTP, 0 clipped runs, source -4.1 dBFS (QOA import +0.6 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_blade_2 | true peak -3.9 dBTP, 0 clipped runs, source -4.0 dBFS (QOA import +0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_bolt | true peak -2.9 dBTP, 0 clipped runs, source -2.9 dBFS (QOA import -0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_bolt_1 | true peak -3.6 dBTP, 0 clipped runs, source -3.7 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_bolt_2 | true peak -2.2 dBTP, 0 clipped runs, source -2.3 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_bow | true peak -2.4 dBTP, 0 clipped runs, source -3.1 dBFS (QOA import +0.7 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_bow_1 | true peak -3.8 dBTP, 0 clipped runs, source -3.6 dBFS (QOA import -0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_bow_2 | true peak -3.1 dBTP, 0 clipped runs, source -3.7 dBFS (QOA import +0.5 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_heavy | true peak -2.3 dBTP, 0 clipped runs, source -2.9 dBFS (QOA import +0.5 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_heavy_1 | true peak -3.3 dBTP, 0 clipped runs, source -3.3 dBFS (QOA import -0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_heavy_2 | true peak -2.0 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import -0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_magic | true peak -2.7 dBTP, 0 clipped runs, source -2.9 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_magic_1 | true peak -3.3 dBTP, 0 clipped runs, source -3.3 dBFS (QOA import +0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_magic_2 | true peak -1.9 dBTP, 0 clipped runs, source -2.0 dBFS (QOA import +0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_shadow | true peak -2.0 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import -0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_siege | true peak -1.7 dBTP, 0 clipped runs, source -2.2 dBFS (QOA import +0.4 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_siege_1 | true peak -2.5 dBTP, 0 clipped runs, source -2.4 dBFS (QOA import -0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_siege_2 | true peak -1.8 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_storm | true peak -3.5 dBTP, 0 clipped runs, source -2.9 dBFS (QOA import -0.7 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_storm_1 | true peak -3.0 dBTP, 0 clipped runs, source -3.4 dBFS (QOA import +0.4 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_storm_2 | true peak -3.3 dBTP, 0 clipped runs, source -2.7 dBFS (QOA import -0.6 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_whip | true peak -1.9 dBTP, 0 clipped runs, source -2.5 dBFS (QOA import +0.5 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_whip_1 | true peak -2.4 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import -0.4 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_whip_2 | true peak -2.2 dBTP, 0 clipped runs, source -2.7 dBFS (QOA import +0.4 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | defeat | true peak -1.9 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import +0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | fireball_cast | true peak -1.3 dBTP, 0 clipped runs, source -1.4 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | fx_bleed | true peak -4.2 dBTP, 0 clipped runs, source -4.2 dBFS (QOA import -0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | fx_bleed_1 | true peak -4.6 dBTP, 0 clipped runs, source -4.0 dBFS (QOA import -0.6 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | fx_bleed_2 | true peak -3.4 dBTP, 0 clipped runs, source -3.6 dBFS (QOA import +0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | fx_burn | true peak -3.9 dBTP, 0 clipped runs, source -4.2 dBFS (QOA import +0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | fx_burn_1 | true peak -2.0 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import -0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | fx_burn_2 | true peak -1.6 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import +0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | skill_hit | true peak -1.9 dBTP, 0 clipped runs, source -2.5 dBFS (QOA import +0.6 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | spell_kindle | true peak -1.4 dBTP, 0 clipped runs, source -1.4 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | spell_shadow_lance | true peak -1.0 dBTP, 0 clipped runs, source -1.4 dBFS (QOA import +0.4 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | spell_snow_shield_off | true peak -3.0 dBTP, 0 clipped runs, source -2.9 dBFS (QOA import -0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | spell_snow_shield_on | true peak -1.6 dBTP, 0 clipped runs, source -1.4 dBFS (QOA import -0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | spell_soul_siphon | true peak -2.0 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import -0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | spell_umbral_shroud | true peak -1.8 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | spell_vigor_off | true peak -3.2 dBTP, 0 clipped runs, source -3.1 dBFS (QOA import -0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | spell_vigor_on | true peak -1.4 dBTP, 0 clipped runs, source -1.4 dBFS (QOA import +0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ui_click | true peak -8.2 dBTP, 0 clipped runs, source -8.0 dBFS (QOA import -0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ui_error | true peak -6.0 dBTP, 0 clipped runs, source -6.0 dBFS (QOA import +0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ui_helper_call | true peak -5.7 dBTP, 0 clipped runs, source -6.0 dBFS (QOA import +0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ui_hint | true peak -6.8 dBTP, 0 clipped runs, source -6.9 dBFS (QOA import -0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ui_plus_start | true peak -6.9 dBTP, 0 clipped runs, source -6.9 dBFS (QOA import -0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ui_restart | true peak -6.6 dBTP, 0 clipped runs, source -6.9 dBFS (QOA import +0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ui_tab | true peak -7.9 dBTP, 0 clipped runs, source -8.0 dBFS (QOA import +0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ui_tab_1 | true peak -8.3 dBTP, 0 clipped runs, source -8.3 dBFS (QOA import -0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ui_tab_2 | true peak -7.6 dBTP, 0 clipped runs, source -7.7 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ui_tier_start | true peak -5.9 dBTP, 0 clipped runs, source -6.0 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ui_tier_tick | true peak -7.7 dBTP, 0 clipped runs, source -8.0 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ui_upgrade_cancel | true peak -6.8 dBTP, 0 clipped runs, source -6.9 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | unit_trained | true peak -4.5 dBTP, 0 clipped runs, source -4.4 dBFS (QOA import -0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | victory | true peak -1.3 dBTP, 0 clipped runs, source -1.4 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_heavy_1 | true peak -1.7 dBTP, 0 clipped runs, source -2.0 dBFS (QOA import +0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_heavy_2 | true peak -2.6 dBTP, 0 clipped runs, source -2.7 dBFS (QOA import +0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_magic | true peak -3.4 dBTP, 0 clipped runs, source -3.4 dBFS (QOA import -0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_magic_1 | true peak -2.1 dBTP, 0 clipped runs, source -2.0 dBFS (QOA import -0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_magic_2 | true peak -1.5 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import +0.4 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_siege | true peak -2.7 dBTP, 0 clipped runs, source -2.5 dBFS (QOA import -0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_siege_1 | true peak -3.0 dBTP, 0 clipped runs, source -3.2 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_siege_2 | true peak -2.5 dBTP, 0 clipped runs, source -2.6 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_storm | true peak -2.9 dBTP, 0 clipped runs, source -2.9 dBFS (QOA import -0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_storm_1 | true peak -2.6 dBTP, 0 clipped runs, source -3.2 dBFS (QOA import +0.6 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_storm_2 | true peak -1.3 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import +0.6 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_whip | true peak -3.0 dBTP, 0 clipped runs, source -3.1 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_whip_1 | true peak -3.5 dBTP, 0 clipped runs, source -3.9 dBFS (QOA import +0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | hit_whip_2 | true peak -1.3 dBTP, 0 clipped runs, source -2.1 dBFS (QOA import +0.8 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | item_bought | true peak -4.2 dBTP, 0 clipped runs, source -4.4 dBFS (QOA import +0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | item_pickup | true peak -4.4 dBTP, 0 clipped runs, source -4.4 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | item_used | true peak -4.4 dBTP, 0 clipped runs, source -4.4 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | level_up | true peak -1.8 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | melee_hit | true peak -1.8 dBTP, 0 clipped runs, source -1.4 dBFS (QOA import -0.4 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | melee_hit_1 | true peak -2.2 dBTP, 0 clipped runs, source -2.5 dBFS (QOA import +0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | melee_hit_2 | true peak -2.3 dBTP, 0 clipped runs, source -2.1 dBFS (QOA import -0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | mine_tick | true peak -6.5 dBTP, 0 clipped runs, source -6.9 dBFS (QOA import +0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | mine_tick_1 | true peak -6.8 dBTP, 0 clipped runs, source -6.9 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | mine_tick_2 | true peak -6.7 dBTP, 0 clipped runs, source -6.9 dBFS (QOA import +0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ab_skitter_1 | true peak -5.3 dBTP, 0 clipped runs, source -4.9 dBFS (QOA import -0.4 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ab_skitter_2 | true peak -5.1 dBTP, 0 clipped runs, source -5.1 dBFS (QOA import -0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ab_snare_lash | true peak -2.6 dBTP, 0 clipped runs, source -2.6 dBFS (QOA import -0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ab_tempest_bolt | true peak -1.0 dBTP, 0 clipped runs, source -0.9 dBFS (QOA import -0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ab_unbroken_vow | true peak -2.2 dBTP, 0 clipped runs, source -2.2 dBFS (QOA import -0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ab_wither_hex | true peak -3.0 dBTP, 0 clipped runs, source -2.9 dBFS (QOA import -0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ability_cast | true peak -3.4 dBTP, 0 clipped runs, source -3.1 dBFS (QOA import -0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | alert_caravan_trained | true peak -4.0 dBTP, 0 clipped runs, source -4.2 dBFS (QOA import +0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | alert_helper_arrive | true peak -1.5 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import +0.4 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | alert_helper_fall | true peak -2.0 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import -0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | alert_helper_revive | true peak -1.9 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import +0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | alert_path_int | true peak -1.8 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | alert_path_str | true peak -1.3 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import +0.6 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | alert_plus_done | true peak -2.3 dBTP, 0 clipped runs, source -2.5 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | alert_tier_citadel | true peak -1.9 dBTP, 0 clipped runs, source -1.7 dBFS (QOA import -0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | alert_tier_stronghold | true peak -1.4 dBTP, 0 clipped runs, source -1.7 dBFS (QOA import +0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | alert_wizard_fell | true peak -2.5 dBTP, 0 clipped runs, source -2.5 dBFS (QOA import +0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_beast | true peak -2.8 dBTP, 0 clipped runs, source -3.1 dBFS (QOA import +0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_beast_1 | true peak -2.7 dBTP, 0 clipped runs, source -2.9 dBFS (QOA import +0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_beast_2 | true peak -3.4 dBTP, 0 clipped runs, source -3.2 dBFS (QOA import -0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_blade | true peak -3.0 dBTP, 0 clipped runs, source -3.1 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_blade_1 | true peak -3.3 dBTP, 0 clipped runs, source -3.8 dBFS (QOA import +0.4 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_blade_2 | true peak -3.5 dBTP, 0 clipped runs, source -2.8 dBFS (QOA import -0.7 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ab_blood_frenzy | true peak -1.8 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import +0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ab_challenge | true peak -3.9 dBTP, 0 clipped runs, source -4.4 dBFS (QOA import +0.5 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ab_flame_burst | true peak -2.0 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import -0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ab_flashpoint | true peak -2.3 dBTP, 0 clipped runs, source -2.5 dBFS (QOA import +0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ab_frost_needle | true peak -3.3 dBTP, 0 clipped runs, source -3.6 dBFS (QOA import +0.4 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ab_frost_shell | true peak -4.5 dBTP, 0 clipped runs, source -3.6 dBFS (QOA import -0.9 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ab_frost_shell_1 | true peak -3.3 dBTP, 0 clipped runs, source -3.2 dBFS (QOA import -0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ab_frost_shell_2 | true peak -2.8 dBTP, 0 clipped runs, source -2.2 dBFS (QOA import -0.6 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ab_genie_chain | true peak -3.3 dBTP, 0 clipped runs, source -4.2 dBFS (QOA import +0.8 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ab_genie_chain_1 | true peak -2.6 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import -0.7 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ab_genie_chain_2 | true peak -2.5 dBTP, 0 clipped runs, source -2.4 dBFS (QOA import -0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ab_grave_feast | true peak -2.9 dBTP, 0 clipped runs, source -2.9 dBFS (QOA import +0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ab_grove_oath | true peak -2.3 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import -0.4 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ab_hold_the_line | true peak -2.2 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import -0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ab_piercing_bolt | true peak -3.3 dBTP, 0 clipped runs, source -3.4 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ab_piercing_bolt_1 | true peak -2.1 dBTP, 0 clipped runs, source -2.7 dBFS (QOA import +0.6 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ab_piercing_bolt_2 | true peak -1.8 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ab_sab_armed | true peak -3.1 dBTP, 0 clipped runs, source -3.4 dBFS (QOA import +0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ab_sab_blast | true peak -1.7 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import +0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ab_sab_disguise | true peak -4.7 dBTP, 0 clipped runs, source -4.4 dBFS (QOA import -0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ab_sab_plant | true peak -3.3 dBTP, 0 clipped runs, source -3.6 dBFS (QOA import +0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ab_sab_reveal | true peak -2.4 dBTP, 0 clipped runs, source -2.6 dBFS (QOA import +0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ab_seed_storm | true peak -2.2 dBTP, 0 clipped runs, source -2.2 dBFS (QOA import -0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | ab_skitter | true peak -4.5 dBTP, 0 clipped runs, source -5.2 dBFS (QOA import +0.7 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | bolt_shot | true peak -3.9 dBTP, 0 clipped runs, source -3.1 dBFS (QOA import -0.8 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | bolt_shot_1 | true peak -2.8 dBTP, 0 clipped runs, source -3.1 dBFS (QOA import +0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | bolt_shot_2 | true peak -3.7 dBTP, 0 clipped runs, source -3.5 dBFS (QOA import -0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | building_hit | true peak -1.7 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import +0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | building_hit_1 | true peak -3.7 dBTP, 0 clipped runs, source -3.4 dBFS (QOA import -0.4 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | building_hit_2 | true peak -6.0 dBTP, 0 clipped runs, source -3.4 dBFS (QOA import -2.8 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | construction_done | true peak -2.3 dBTP, 0 clipped runs, source -2.5 dBFS (QOA import +0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | crown_claimed | true peak -1.7 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import +0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | crystals_delivered | true peak -5.4 dBTP, 0 clipped runs, source -6.0 dBFS (QOA import +0.5 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_beast | true peak -2.6 dBTP, 0 clipped runs, source -2.9 dBFS (QOA import +0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_beast_1 | true peak -2.9 dBTP, 0 clipped runs, source -2.8 dBFS (QOA import -0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_beast_2 | true peak -2.4 dBTP, 0 clipped runs, source -2.2 dBFS (QOA import -0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_blade | true peak -2.1 dBTP, 0 clipped runs, source -2.5 dBFS (QOA import +0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_blade_1 | true peak -1.8 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_blade_2 | true peak -2.0 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import -0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_bolt | true peak -2.4 dBTP, 0 clipped runs, source -2.5 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_bolt_1 | true peak -2.7 dBTP, 0 clipped runs, source -2.9 dBFS (QOA import +0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_bolt_2 | true peak -2.2 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import -0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_bow | true peak -2.9 dBTP, 0 clipped runs, source -2.9 dBFS (QOA import -0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_bow_1 | true peak -3.1 dBTP, 0 clipped runs, source -3.4 dBFS (QOA import +0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_bow_2 | true peak -2.3 dBTP, 0 clipped runs, source -2.7 dBFS (QOA import +0.4 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_fire | true peak -2.2 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import -0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | death_heavy | true peak -2.8 dBTP, 0 clipped runs, source -2.5 dBFS (QOA import -0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_bolt | true peak -3.1 dBTP, 0 clipped runs, source -3.1 dBFS (QOA import +0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_bolt_1 | true peak -3.4 dBTP, 0 clipped runs, source -3.9 dBFS (QOA import +0.4 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_bolt_2 | true peak -4.2 dBTP, 0 clipped runs, source -4.0 dBFS (QOA import -0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_bow | true peak -4.0 dBTP, 0 clipped runs, source -3.4 dBFS (QOA import -0.8 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_bow_1 | true peak -2.8 dBTP, 0 clipped runs, source -3.3 dBFS (QOA import +0.5 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_bow_2 | true peak -2.5 dBTP, 0 clipped runs, source -2.2 dBFS (QOA import -0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_heavy | true peak -3.3 dBTP, 0 clipped runs, source -2.9 dBFS (QOA import -0.4 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_heavy_1 | true peak -3.6 dBTP, 0 clipped runs, source -4.0 dBFS (QOA import +0.4 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_heavy_2 | true peak -2.9 dBTP, 0 clipped runs, source -2.7 dBFS (QOA import -0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_magic | true peak -3.2 dBTP, 0 clipped runs, source -3.4 dBFS (QOA import +0.2 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_magic_1 | true peak -3.6 dBTP, 0 clipped runs, source -4.0 dBFS (QOA import +0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_magic_2 | true peak -2.4 dBTP, 0 clipped runs, source -2.8 dBFS (QOA import +0.4 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_siege | true peak -2.6 dBTP, 0 clipped runs, source -2.2 dBFS (QOA import -0.5 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_siege_1 | true peak -3.3 dBTP, 0 clipped runs, source -3.0 dBFS (QOA import -0.4 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_siege_2 | true peak -2.9 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import -1.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_storm | true peak -3.5 dBTP, 0 clipped runs, source -3.1 dBFS (QOA import -0.4 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_storm_1 | true peak -2.9 dBTP, 0 clipped runs, source -1.9 dBFS (QOA import -1.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_storm_2 | true peak -3.5 dBTP, 0 clipped runs, source -3.8 dBFS (QOA import +0.3 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_whip | true peak -3.6 dBTP, 0 clipped runs, source -3.1 dBFS (QOA import -0.5 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_whip_1 | true peak -4.6 dBTP, 0 clipped runs, source -3.3 dBFS (QOA import -1.5 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | atk_whip_2 | true peak -3.0 dBTP, 0 clipped runs, source -2.1 dBFS (QOA import -1.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | bolt_impact | true peak -2.4 dBTP, 0 clipped runs, source -2.5 dBFS (QOA import -0.1 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | bolt_impact_1 | true peak -2.4 dBTP, 0 clipped runs, source -2.5 dBFS (QOA import -0.0 dB) | true peak <= -1 dBTP, no clipping |  |
| PASS | bolt_impact_2 | true peak -2.8 dBTP, 0 clipped runs, source -2.9 dBFS (QOA import +0.1 dB) | true peak <= -1 dBTP, no clipping |  |

### Duration, silence, tails

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| WARN | defeat | ends at -25.3 dB RMS (last sample 0.099) | fade to silence (last 10 ms < -45 dB) | Add a 5-20 ms fade-out at the end (click). |
| PASS | fx_crit_2 | trailing silence 21 ms | trail <= 150 ms |  |
| PASS | fx_crit_2 | 0.27 s | unit: 0.03..1.5 s |  |
| PASS | helper_cast | lead silence 0 ms | lead <= 15 ms |  |
| PASS | helper_cast | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | helper_cast | 0.45 s | unit: 0.03..1.5 s |  |
| PASS | helper_cast_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | helper_cast_1 | trailing silence 56 ms | trail <= 150 ms |  |
| PASS | helper_cast_1 | 0.50 s | unit: 0.03..1.5 s |  |
| PASS | helper_cast_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | helper_cast_2 | trailing silence 45 ms | trail <= 150 ms |  |
| PASS | helper_cast_2 | 0.40 s | unit: 0.03..1.5 s |  |
| PASS | hit_beast | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_beast | trailing silence 41 ms | trail <= 150 ms |  |
| PASS | hit_beast | 0.22 s | unit: 0.03..1.5 s |  |
| PASS | hit_beast_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_beast_1 | trailing silence 46 ms | trail <= 150 ms |  |
| PASS | fx_burn_2 | trailing silence 18 ms | trail <= 150 ms |  |
| PASS | fx_burn_2 | 0.29 s | unit: 0.03..1.5 s |  |
| PASS | fx_chill | lead silence 0 ms | lead <= 15 ms |  |
| PASS | fx_chill | trailing silence 21 ms | trail <= 150 ms |  |
| PASS | fx_chill | 0.26 s | unit: 0.03..1.5 s |  |
| PASS | fx_chill_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | fx_chill_1 | trailing silence 24 ms | trail <= 150 ms |  |
| PASS | fx_chill_1 | 0.29 s | unit: 0.03..1.5 s |  |
| PASS | fx_chill_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | fx_chill_2 | trailing silence 19 ms | trail <= 150 ms |  |
| PASS | fx_chill_2 | 0.23 s | unit: 0.03..1.5 s |  |
| PASS | fx_crit | lead silence 0 ms | lead <= 15 ms |  |
| PASS | fx_crit | trailing silence 23 ms | trail <= 150 ms |  |
| PASS | fx_crit | 0.30 s | unit: 0.03..1.5 s |  |
| PASS | fx_crit_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | fx_crit_1 | trailing silence 26 ms | trail <= 150 ms |  |
| PASS | fx_crit_1 | 0.34 s | unit: 0.03..1.5 s |  |
| PASS | fx_crit_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_bolt_1 | 0.22 s | unit: 0.03..1.5 s |  |
| PASS | hit_bolt_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_bolt_2 | trailing silence 52 ms | trail <= 150 ms |  |
| PASS | hit_bolt_2 | 0.18 s | unit: 0.03..1.5 s |  |
| PASS | hit_bow | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_bow | trailing silence 69 ms | trail <= 150 ms |  |
| PASS | hit_bow | 0.16 s | unit: 0.03..1.5 s |  |
| PASS | hit_bow_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_bow_1 | trailing silence 80 ms | trail <= 150 ms |  |
| PASS | hit_bow_1 | 0.18 s | unit: 0.03..1.5 s |  |
| PASS | hit_bow_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_bow_2 | trailing silence 61 ms | trail <= 150 ms |  |
| PASS | hit_bow_2 | 0.14 s | unit: 0.03..1.5 s |  |
| PASS | hit_heavy | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_heavy | trailing silence 23 ms | trail <= 150 ms |  |
| PASS | hit_heavy | 0.30 s | unit: 0.03..1.5 s |  |
| PASS | hit_heavy_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_heavy_1 | trailing silence 25 ms | trail <= 150 ms |  |
| PASS | hit_beast_1 | 0.25 s | unit: 0.03..1.5 s |  |
| PASS | hit_beast_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_beast_2 | trailing silence 37 ms | trail <= 150 ms |  |
| PASS | hit_beast_2 | 0.20 s | unit: 0.03..1.5 s |  |
| PASS | hit_blade | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_blade | trailing silence 93 ms | trail <= 150 ms |  |
| PASS | hit_blade | 0.18 s | unit: 0.03..1.5 s |  |
| PASS | hit_blade_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_blade_1 | trailing silence 103 ms | trail <= 150 ms |  |
| PASS | hit_blade_1 | 0.20 s | unit: 0.03..1.5 s |  |
| PASS | hit_blade_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_blade_2 | trailing silence 83 ms | trail <= 150 ms |  |
| PASS | hit_blade_2 | 0.16 s | unit: 0.03..1.5 s |  |
| PASS | hit_bolt | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_bolt | trailing silence 60 ms | trail <= 150 ms |  |
| PASS | hit_bolt | 0.20 s | unit: 0.03..1.5 s |  |
| PASS | hit_bolt_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_bolt_1 | trailing silence 66 ms | trail <= 150 ms |  |
| PASS | death_shadow | 0.80 s | unit: 0.03..1.5 s |  |
| PASS | death_siege | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_siege | trailing silence 101 ms | trail <= 150 ms |  |
| PASS | death_siege | 0.90 s | unit: 0.03..1.5 s |  |
| PASS | death_siege_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_siege_1 | trailing silence 113 ms | trail <= 150 ms |  |
| PASS | death_siege_1 | 1.01 s | unit: 0.03..1.5 s |  |
| PASS | death_siege_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_siege_2 | trailing silence 91 ms | trail <= 150 ms |  |
| PASS | death_siege_2 | 0.81 s | unit: 0.03..1.5 s |  |
| PASS | death_storm | lead silence 1 ms | lead <= 15 ms |  |
| PASS | death_storm | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | death_storm | 0.90 s | unit: 0.03..1.5 s |  |
| PASS | death_storm_1 | lead silence 1 ms | lead <= 15 ms |  |
| PASS | death_storm_1 | trailing silence 56 ms | trail <= 150 ms |  |
| PASS | death_storm_1 | 1.01 s | unit: 0.03..1.5 s |  |
| PASS | death_storm_2 | lead silence 1 ms | lead <= 15 ms |  |
| PASS | death_heavy | 0.75 s | unit: 0.03..1.5 s |  |
| PASS | death_heavy_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_heavy_1 | trailing silence 108 ms | trail <= 150 ms |  |
| PASS | death_heavy_1 | 0.84 s | unit: 0.03..1.5 s |  |
| PASS | death_heavy_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_heavy_2 | trailing silence 87 ms | trail <= 150 ms |  |
| PASS | death_heavy_2 | 0.67 s | unit: 0.03..1.5 s |  |
| PASS | death_magic | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_magic | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | death_magic | 0.80 s | unit: 0.03..1.5 s |  |
| PASS | death_magic_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_magic_1 | trailing silence 56 ms | trail <= 150 ms |  |
| PASS | death_magic_1 | 0.90 s | unit: 0.03..1.5 s |  |
| PASS | death_magic_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_magic_2 | trailing silence 45 ms | trail <= 150 ms |  |
| PASS | death_magic_2 | 0.72 s | unit: 0.03..1.5 s |  |
| PASS | death_shadow | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_shadow | trailing silence 51 ms | trail <= 150 ms |  |
| PASS | fireball_explode | trailing silence 55 ms | trail <= 150 ms |  |
| PASS | fireball_explode | 1.10 s | spell: 0.03..2.5 s |  |
| PASS | fx_bleed | lead silence 0 ms | lead <= 15 ms |  |
| PASS | fx_bleed | trailing silence 12 ms | trail <= 150 ms |  |
| PASS | fx_bleed | 0.26 s | unit: 0.03..1.5 s |  |
| PASS | fx_bleed_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | fx_bleed_1 | trailing silence 12 ms | trail <= 150 ms |  |
| PASS | fx_bleed_1 | 0.29 s | unit: 0.03..1.5 s |  |
| PASS | fx_bleed_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | fx_bleed_2 | trailing silence 10 ms | trail <= 150 ms |  |
| PASS | fx_bleed_2 | 0.23 s | unit: 0.03..1.5 s |  |
| PASS | fx_burn | lead silence 0 ms | lead <= 15 ms |  |
| PASS | fx_burn | trailing silence 20 ms | trail <= 150 ms |  |
| PASS | fx_burn | 0.32 s | unit: 0.03..1.5 s |  |
| PASS | fx_burn_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | fx_burn_1 | trailing silence 22 ms | trail <= 150 ms |  |
| PASS | fx_burn_1 | 0.36 s | unit: 0.03..1.5 s |  |
| PASS | fx_burn_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_storm_2 | trailing silence 45 ms | trail <= 150 ms |  |
| PASS | death_storm_2 | 0.81 s | unit: 0.03..1.5 s |  |
| PASS | death_whip | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_whip | trailing silence 51 ms | trail <= 150 ms |  |
| PASS | death_whip | 0.60 s | unit: 0.03..1.5 s |  |
| PASS | death_whip_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_whip_1 | trailing silence 57 ms | trail <= 150 ms |  |
| PASS | death_whip_1 | 0.67 s | unit: 0.03..1.5 s |  |
| PASS | death_whip_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_whip_2 | trailing silence 46 ms | trail <= 150 ms |  |
| PASS | death_whip_2 | 0.54 s | unit: 0.03..1.5 s |  |
| PASS | defeat | lead silence 0 ms | lead <= 15 ms |  |
| PASS | defeat | trailing silence 0 ms | trail <= 150 ms |  |
| PASS | defeat | 2.80 s | alert: 0.03..3.5 s |  |
| PASS | fireball_cast | lead silence 0 ms | lead <= 20 ms |  |
| PASS | fireball_cast | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | fireball_cast | 0.55 s | spell: 0.03..2.5 s |  |
| PASS | fireball_explode | lead silence 0 ms | lead <= 20 ms |  |
| PASS | spell_soul_siphon | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | spell_soul_siphon | 1.10 s | spell: 0.03..2.5 s |  |
| PASS | spell_umbral_shroud | lead silence 1 ms | lead <= 20 ms |  |
| PASS | spell_umbral_shroud | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | spell_umbral_shroud | 0.90 s | spell: 0.03..2.5 s |  |
| PASS | spell_vigor_off | lead silence 0 ms | lead <= 20 ms |  |
| PASS | spell_vigor_off | trailing silence 51 ms | trail <= 150 ms |  |
| PASS | spell_vigor_off | 0.50 s | spell: 0.03..2.5 s |  |
| PASS | spell_vigor_on | lead silence 0 ms | lead <= 20 ms |  |
| PASS | spell_vigor_on | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | spell_vigor_on | 0.80 s | spell: 0.03..2.5 s |  |
| PASS | ui_click | lead silence 0 ms | lead <= 10 ms |  |
| PASS | ui_click | trailing silence 31 ms | trail <= 150 ms |  |
| PASS | ui_click | 0.06 s | ui: 0.03..0.8 s |  |
| PASS | ui_error | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ui_error | trailing silence 20 ms | trail <= 150 ms |  |
| PASS | ui_error | 0.30 s | alert: 0.03..3.5 s |  |
| PASS | skill_hit | trailing silence 52 ms | trail <= 150 ms |  |
| PASS | skill_hit | 0.28 s | unit: 0.03..1.5 s |  |
| PASS | spell_ember_step | lead silence 0 ms | lead <= 20 ms |  |
| PASS | spell_ember_step | trailing silence 31 ms | trail <= 150 ms |  |
| PASS | spell_ember_step | 0.45 s | spell: 0.03..2.5 s |  |
| PASS | spell_kindle | lead silence 0 ms | lead <= 20 ms |  |
| PASS | spell_kindle | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | spell_kindle | 0.80 s | spell: 0.03..2.5 s |  |
| PASS | spell_shadow_lance | lead silence 0 ms | lead <= 20 ms |  |
| PASS | spell_shadow_lance | trailing silence 52 ms | trail <= 150 ms |  |
| PASS | spell_shadow_lance | 0.50 s | spell: 0.03..2.5 s |  |
| PASS | spell_snow_shield_off | lead silence 0 ms | lead <= 20 ms |  |
| PASS | spell_snow_shield_off | trailing silence 101 ms | trail <= 150 ms |  |
| PASS | spell_snow_shield_off | 0.60 s | spell: 0.03..2.5 s |  |
| PASS | spell_snow_shield_on | lead silence 0 ms | lead <= 20 ms |  |
| PASS | spell_snow_shield_on | trailing silence 4 ms | trail <= 150 ms |  |
| PASS | spell_snow_shield_on | 0.90 s | spell: 0.03..2.5 s |  |
| PASS | spell_soul_siphon | lead silence 1 ms | lead <= 20 ms |  |
| PASS | ui_tab_2 | lead silence 0 ms | lead <= 10 ms |  |
| PASS | ui_tab_2 | trailing silence 27 ms | trail <= 150 ms |  |
| PASS | ui_tab_2 | 0.06 s | ui: 0.03..0.8 s |  |
| PASS | ui_tier_start | lead silence 0 ms | lead <= 10 ms |  |
| PASS | ui_tier_start | trailing silence 6 ms | trail <= 150 ms |  |
| PASS | ui_tier_start | 0.50 s | ui: 0.03..0.8 s |  |
| PASS | ui_tier_tick | lead silence 0 ms | lead <= 10 ms |  |
| PASS | ui_tier_tick | trailing silence 63 ms | trail <= 150 ms |  |
| PASS | ui_tier_tick | 0.16 s | ui: 0.03..0.8 s |  |
| PASS | ui_upgrade_cancel | lead silence 0 ms | lead <= 10 ms |  |
| PASS | ui_upgrade_cancel | trailing silence 2 ms | trail <= 150 ms |  |
| PASS | ui_upgrade_cancel | 0.32 s | ui: 0.03..0.8 s |  |
| PASS | unit_trained | lead silence 0 ms | lead <= 15 ms |  |
| PASS | unit_trained | trailing silence 10 ms | trail <= 150 ms |  |
| PASS | unit_trained | 0.45 s | alert: 0.03..3.5 s |  |
| PASS | victory | lead silence 0 ms | lead <= 15 ms |  |
| PASS | victory | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | victory | 2.80 s | alert: 0.03..3.5 s |  |
| PASS | ui_helper_call | lead silence 0 ms | lead <= 10 ms |  |
| PASS | ui_helper_call | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | ui_helper_call | 0.60 s | ui: 0.03..0.8 s |  |
| PASS | ui_hint | lead silence 0 ms | lead <= 10 ms |  |
| PASS | ui_hint | trailing silence 4 ms | trail <= 150 ms |  |
| PASS | ui_hint | 0.45 s | ui: 0.03..0.8 s |  |
| PASS | ui_plus_start | lead silence 0 ms | lead <= 10 ms |  |
| PASS | ui_plus_start | trailing silence 21 ms | trail <= 150 ms |  |
| PASS | ui_plus_start | 0.34 s | ui: 0.03..0.8 s |  |
| PASS | ui_restart | lead silence 0 ms | lead <= 10 ms |  |
| PASS | ui_restart | trailing silence 4 ms | trail <= 150 ms |  |
| PASS | ui_restart | 0.50 s | ui: 0.03..0.8 s |  |
| PASS | ui_tab | lead silence 0 ms | lead <= 10 ms |  |
| PASS | ui_tab | trailing silence 30 ms | trail <= 150 ms |  |
| PASS | ui_tab | 0.07 s | ui: 0.03..0.8 s |  |
| PASS | ui_tab_1 | lead silence 0 ms | lead <= 10 ms |  |
| PASS | ui_tab_1 | trailing silence 35 ms | trail <= 150 ms |  |
| PASS | ui_tab_1 | 0.08 s | ui: 0.03..0.8 s |  |
| PASS | hit_siege_1 | 0.45 s | unit: 0.03..1.5 s |  |
| PASS | hit_siege_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_siege_2 | trailing silence 49 ms | trail <= 150 ms |  |
| PASS | hit_siege_2 | 0.36 s | unit: 0.03..1.5 s |  |
| PASS | hit_storm | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_storm | trailing silence 54 ms | trail <= 150 ms |  |
| PASS | hit_storm | 0.35 s | unit: 0.03..1.5 s |  |
| PASS | hit_storm_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_storm_1 | trailing silence 60 ms | trail <= 150 ms |  |
| PASS | hit_storm_1 | 0.39 s | unit: 0.03..1.5 s |  |
| PASS | hit_storm_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_storm_2 | trailing silence 49 ms | trail <= 150 ms |  |
| PASS | hit_storm_2 | 0.31 s | unit: 0.03..1.5 s |  |
| PASS | hit_whip | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_whip | trailing silence 45 ms | trail <= 150 ms |  |
| PASS | hit_whip | 0.20 s | unit: 0.03..1.5 s |  |
| PASS | hit_whip_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_heavy_1 | 0.34 s | unit: 0.03..1.5 s |  |
| PASS | hit_heavy_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_heavy_2 | trailing silence 21 ms | trail <= 150 ms |  |
| PASS | hit_heavy_2 | 0.27 s | unit: 0.03..1.5 s |  |
| PASS | hit_magic | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_magic | trailing silence 43 ms | trail <= 150 ms |  |
| PASS | hit_magic | 0.24 s | unit: 0.03..1.5 s |  |
| PASS | hit_magic_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_magic_1 | trailing silence 49 ms | trail <= 150 ms |  |
| PASS | hit_magic_1 | 0.27 s | unit: 0.03..1.5 s |  |
| PASS | hit_magic_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_magic_2 | trailing silence 39 ms | trail <= 150 ms |  |
| PASS | hit_magic_2 | 0.22 s | unit: 0.03..1.5 s |  |
| PASS | hit_siege | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_siege | trailing silence 54 ms | trail <= 150 ms |  |
| PASS | hit_siege | 0.40 s | unit: 0.03..1.5 s |  |
| PASS | hit_siege_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_siege_1 | trailing silence 60 ms | trail <= 150 ms |  |
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
| PASS | hit_whip_1 | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | hit_whip_1 | 0.22 s | unit: 0.03..1.5 s |  |
| PASS | hit_whip_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | hit_whip_2 | trailing silence 40 ms | trail <= 150 ms |  |
| PASS | hit_whip_2 | 0.18 s | unit: 0.03..1.5 s |  |
| PASS | item_bought | lead silence 0 ms | lead <= 10 ms |  |
| PASS | item_bought | trailing silence 1 ms | trail <= 150 ms |  |
| PASS | item_bought | 0.32 s | ui: 0.03..0.8 s |  |
| PASS | item_pickup | lead silence 0 ms | lead <= 10 ms |  |
| PASS | item_pickup | trailing silence 2 ms | trail <= 150 ms |  |
| PASS | item_pickup | 0.26 s | ui: 0.03..0.8 s |  |
| PASS | item_used | lead silence 0 ms | lead <= 10 ms |  |
| PASS | item_used | trailing silence 20 ms | trail <= 150 ms |  |
| PASS | item_used | 0.40 s | ui: 0.03..0.8 s |  |
| PASS | level_up | lead silence 0 ms | lead <= 15 ms |  |
| PASS | level_up | trailing silence 2 ms | trail <= 150 ms |  |
| PASS | level_up | 0.95 s | alert: 0.03..3.5 s |  |
| PASS | melee_hit | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ab_wither_hex | 0.70 s | unit: 0.03..1.5 s |  |
| PASS | ability_cast | lead silence 1 ms | lead <= 20 ms |  |
| PASS | ability_cast | trailing silence 3 ms | trail <= 150 ms |  |
| PASS | ability_cast | 0.45 s | spell: 0.03..2.5 s |  |
| PASS | alert_caravan_trained | lead silence 0 ms | lead <= 15 ms |  |
| PASS | alert_caravan_trained | trailing silence 4 ms | trail <= 150 ms |  |
| PASS | alert_caravan_trained | 0.70 s | alert: 0.03..3.5 s |  |
| PASS | alert_helper_arrive | lead silence 2 ms | lead <= 15 ms |  |
| PASS | alert_helper_arrive | trailing silence 20 ms | trail <= 150 ms |  |
| PASS | alert_helper_arrive | 1.20 s | alert: 0.03..3.5 s |  |
| PASS | alert_helper_fall | lead silence 0 ms | lead <= 15 ms |  |
| PASS | alert_helper_fall | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | alert_helper_fall | 1.20 s | alert: 0.03..3.5 s |  |
| PASS | alert_helper_revive | lead silence 1 ms | lead <= 15 ms |  |
| PASS | alert_helper_revive | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | alert_helper_revive | 1.10 s | alert: 0.03..3.5 s |  |
| PASS | alert_path_int | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ab_skitter | 0.22 s | unit: 0.03..1.5 s |  |
| PASS | ab_skitter_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ab_skitter_1 | trailing silence 23 ms | trail <= 150 ms |  |
| PASS | ab_skitter_1 | 0.25 s | unit: 0.03..1.5 s |  |
| PASS | ab_skitter_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ab_skitter_2 | trailing silence 18 ms | trail <= 150 ms |  |
| PASS | ab_skitter_2 | 0.20 s | unit: 0.03..1.5 s |  |
| PASS | ab_snare_lash | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ab_snare_lash | trailing silence 20 ms | trail <= 150 ms |  |
| PASS | ab_snare_lash | 0.60 s | unit: 0.03..1.5 s |  |
| PASS | ab_tempest_bolt | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ab_tempest_bolt | trailing silence 51 ms | trail <= 150 ms |  |
| PASS | ab_tempest_bolt | 1.20 s | unit: 0.03..1.5 s |  |
| PASS | ab_unbroken_vow | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ab_unbroken_vow | trailing silence 51 ms | trail <= 150 ms |  |
| PASS | ab_unbroken_vow | 0.90 s | unit: 0.03..1.5 s |  |
| PASS | ab_wither_hex | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ab_wither_hex | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | atk_beast | trailing silence 66 ms | trail <= 150 ms |  |
| PASS | atk_beast | 0.30 s | unit: 0.03..1.5 s |  |
| PASS | atk_beast_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_beast_1 | trailing silence 72 ms | trail <= 150 ms |  |
| PASS | atk_beast_1 | 0.34 s | unit: 0.03..1.5 s |  |
| PASS | atk_beast_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_beast_2 | trailing silence 59 ms | trail <= 150 ms |  |
| PASS | atk_beast_2 | 0.27 s | unit: 0.03..1.5 s |  |
| PASS | atk_blade | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_blade | trailing silence 61 ms | trail <= 150 ms |  |
| PASS | atk_blade | 0.20 s | unit: 0.03..1.5 s |  |
| PASS | atk_blade_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_blade_1 | trailing silence 68 ms | trail <= 150 ms |  |
| PASS | atk_blade_1 | 0.22 s | unit: 0.03..1.5 s |  |
| PASS | atk_blade_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_blade_2 | trailing silence 55 ms | trail <= 150 ms |  |
| PASS | atk_blade_2 | 0.18 s | unit: 0.03..1.5 s |  |
| PASS | atk_bolt | lead silence 0 ms | lead <= 15 ms |  |
| PASS | alert_path_int | trailing silence 100 ms | trail <= 150 ms |  |
| PASS | alert_path_int | 1.00 s | alert: 0.03..3.5 s |  |
| PASS | alert_path_str | lead silence 0 ms | lead <= 15 ms |  |
| PASS | alert_path_str | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | alert_path_str | 1.00 s | alert: 0.03..3.5 s |  |
| PASS | alert_plus_done | lead silence 0 ms | lead <= 15 ms |  |
| PASS | alert_plus_done | trailing silence 51 ms | trail <= 150 ms |  |
| PASS | alert_plus_done | 0.80 s | alert: 0.03..3.5 s |  |
| PASS | alert_tier_citadel | lead silence 0 ms | lead <= 15 ms |  |
| PASS | alert_tier_citadel | trailing silence 20 ms | trail <= 150 ms |  |
| PASS | alert_tier_citadel | 1.70 s | alert: 0.03..3.5 s |  |
| PASS | alert_tier_stronghold | lead silence 0 ms | lead <= 15 ms |  |
| PASS | alert_tier_stronghold | trailing silence 20 ms | trail <= 150 ms |  |
| PASS | alert_tier_stronghold | 1.30 s | alert: 0.03..3.5 s |  |
| PASS | alert_wizard_fell | lead silence 0 ms | lead <= 15 ms |  |
| PASS | alert_wizard_fell | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | alert_wizard_fell | 1.40 s | alert: 0.03..3.5 s |  |
| PASS | atk_beast | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ab_frost_shell_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ab_frost_shell_1 | trailing silence 57 ms | trail <= 150 ms |  |
| PASS | ab_frost_shell_1 | 0.50 s | unit: 0.03..1.5 s |  |
| PASS | ab_frost_shell_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ab_frost_shell_2 | trailing silence 46 ms | trail <= 150 ms |  |
| PASS | ab_frost_shell_2 | 0.40 s | unit: 0.03..1.5 s |  |
| PASS | ab_genie_chain | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ab_genie_chain | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | ab_genie_chain | 0.30 s | unit: 0.03..1.5 s |  |
| PASS | ab_genie_chain_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ab_genie_chain_1 | trailing silence 54 ms | trail <= 150 ms |  |
| PASS | ab_genie_chain_1 | 0.34 s | unit: 0.03..1.5 s |  |
| PASS | ab_genie_chain_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ab_genie_chain_2 | trailing silence 45 ms | trail <= 150 ms |  |
| PASS | ab_genie_chain_2 | 0.27 s | unit: 0.03..1.5 s |  |
| PASS | ab_grave_feast | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ab_grave_feast | trailing silence 30 ms | trail <= 150 ms |  |
| PASS | ab_blood_frenzy | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ab_blood_frenzy | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | ab_blood_frenzy | 0.80 s | unit: 0.03..1.5 s |  |
| PASS | ab_challenge | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ab_challenge | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | ab_challenge | 0.70 s | unit: 0.03..1.5 s |  |
| PASS | ab_flame_burst | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ab_flame_burst | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | ab_flame_burst | 0.80 s | unit: 0.03..1.5 s |  |
| PASS | ab_flashpoint | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ab_flashpoint | trailing silence 52 ms | trail <= 150 ms |  |
| PASS | ab_flashpoint | 0.50 s | unit: 0.03..1.5 s |  |
| PASS | ab_frost_needle | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ab_frost_needle | trailing silence 40 ms | trail <= 150 ms |  |
| PASS | ab_frost_needle | 0.32 s | unit: 0.03..1.5 s |  |
| PASS | ab_frost_shell | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ab_frost_shell | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | ab_frost_shell | 0.45 s | unit: 0.03..1.5 s |  |
| PASS | ab_sab_armed | 0.80 s | unit: 0.03..1.5 s |  |
| PASS | ab_sab_blast | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ab_sab_blast | trailing silence 52 ms | trail <= 150 ms |  |
| PASS | ab_sab_blast | 1.30 s | unit: 0.03..1.5 s |  |
| PASS | ab_sab_disguise | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ab_sab_disguise | trailing silence 51 ms | trail <= 150 ms |  |
| PASS | ab_sab_disguise | 0.50 s | unit: 0.03..1.5 s |  |
| PASS | ab_sab_plant | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ab_sab_plant | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | ab_sab_plant | 0.60 s | unit: 0.03..1.5 s |  |
| PASS | ab_sab_reveal | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ab_sab_reveal | trailing silence 100 ms | trail <= 150 ms |  |
| PASS | ab_sab_reveal | 0.60 s | unit: 0.03..1.5 s |  |
| PASS | ab_seed_storm | lead silence 1 ms | lead <= 15 ms |  |
| PASS | ab_seed_storm | trailing silence 118 ms | trail <= 150 ms |  |
| PASS | ab_seed_storm | 0.90 s | unit: 0.03..1.5 s |  |
| PASS | ab_skitter | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ab_skitter | trailing silence 21 ms | trail <= 150 ms |  |
| PASS | ab_grave_feast | 0.60 s | unit: 0.03..1.5 s |  |
| PASS | ab_grove_oath | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ab_grove_oath | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | ab_grove_oath | 0.90 s | unit: 0.03..1.5 s |  |
| PASS | ab_hold_the_line | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ab_hold_the_line | trailing silence 53 ms | trail <= 150 ms |  |
| PASS | ab_hold_the_line | 0.70 s | unit: 0.03..1.5 s |  |
| PASS | ab_piercing_bolt | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ab_piercing_bolt | trailing silence 38 ms | trail <= 150 ms |  |
| PASS | ab_piercing_bolt | 0.30 s | unit: 0.03..1.5 s |  |
| PASS | ab_piercing_bolt_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ab_piercing_bolt_1 | trailing silence 46 ms | trail <= 150 ms |  |
| PASS | ab_piercing_bolt_1 | 0.34 s | unit: 0.03..1.5 s |  |
| PASS | ab_piercing_bolt_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ab_piercing_bolt_2 | trailing silence 36 ms | trail <= 150 ms |  |
| PASS | ab_piercing_bolt_2 | 0.27 s | unit: 0.03..1.5 s |  |
| PASS | ab_sab_armed | lead silence 0 ms | lead <= 15 ms |  |
| PASS | ab_sab_armed | trailing silence 50 ms | trail <= 150 ms |  |
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
| PASS | death_beast_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_beast_1 | trailing silence 56 ms | trail <= 150 ms |  |
| PASS | bolt_shot | lead silence 0 ms | lead <= 15 ms |  |
| PASS | bolt_shot | trailing silence 46 ms | trail <= 150 ms |  |
| PASS | bolt_shot | 0.24 s | unit: 0.03..1.5 s |  |
| PASS | bolt_shot_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | bolt_shot_1 | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | bolt_shot_1 | 0.25 s | unit: 0.03..1.5 s |  |
| PASS | bolt_shot_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | bolt_shot_2 | trailing silence 43 ms | trail <= 150 ms |  |
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
| PASS | death_bolt_1 | 0.73 s | unit: 0.03..1.5 s |  |
| PASS | death_bolt_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_bolt_2 | trailing silence 92 ms | trail <= 150 ms |  |
| PASS | death_bolt_2 | 0.58 s | unit: 0.03..1.5 s |  |
| PASS | death_bow | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_bow | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | death_bow | 0.55 s | unit: 0.03..1.5 s |  |
| PASS | death_bow_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_bow_1 | trailing silence 57 ms | trail <= 150 ms |  |
| PASS | death_bow_1 | 0.62 s | unit: 0.03..1.5 s |  |
| PASS | death_bow_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_bow_2 | trailing silence 45 ms | trail <= 150 ms |  |
| PASS | death_bow_2 | 0.49 s | unit: 0.03..1.5 s |  |
| PASS | death_fire | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_fire | trailing silence 101 ms | trail <= 150 ms |  |
| PASS | death_fire | 0.65 s | unit: 0.03..1.5 s |  |
| PASS | death_heavy | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_heavy | trailing silence 98 ms | trail <= 150 ms |  |
| PASS | death_beast_1 | 0.90 s | unit: 0.03..1.5 s |  |
| PASS | death_beast_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_beast_2 | trailing silence 45 ms | trail <= 150 ms |  |
| PASS | death_beast_2 | 0.72 s | unit: 0.03..1.5 s |  |
| PASS | death_blade | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_blade | trailing silence 101 ms | trail <= 150 ms |  |
| PASS | death_blade | 0.55 s | unit: 0.03..1.5 s |  |
| PASS | death_blade_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_blade_1 | trailing silence 113 ms | trail <= 150 ms |  |
| PASS | death_blade_1 | 0.62 s | unit: 0.03..1.5 s |  |
| PASS | death_blade_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_blade_2 | trailing silence 90 ms | trail <= 150 ms |  |
| PASS | death_blade_2 | 0.49 s | unit: 0.03..1.5 s |  |
| PASS | death_bolt | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_bolt | trailing silence 102 ms | trail <= 150 ms |  |
| PASS | death_bolt | 0.65 s | unit: 0.03..1.5 s |  |
| PASS | death_bolt_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_bolt_1 | trailing silence 113 ms | trail <= 150 ms |  |
| PASS | atk_heavy | trailing silence 23 ms | trail <= 150 ms |  |
| PASS | atk_heavy | 0.30 s | unit: 0.03..1.5 s |  |
| PASS | atk_heavy_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_heavy_1 | trailing silence 25 ms | trail <= 150 ms |  |
| PASS | atk_heavy_1 | 0.34 s | unit: 0.03..1.5 s |  |
| PASS | atk_heavy_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_heavy_2 | trailing silence 20 ms | trail <= 150 ms |  |
| PASS | atk_heavy_2 | 0.27 s | unit: 0.03..1.5 s |  |
| PASS | atk_magic | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_magic | trailing silence 40 ms | trail <= 150 ms |  |
| PASS | atk_magic | 0.40 s | unit: 0.03..1.5 s |  |
| PASS | atk_magic_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_magic_1 | trailing silence 45 ms | trail <= 150 ms |  |
| PASS | atk_magic_1 | 0.45 s | unit: 0.03..1.5 s |  |
| PASS | atk_magic_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_magic_2 | trailing silence 36 ms | trail <= 150 ms |  |
| PASS | atk_magic_2 | 0.36 s | unit: 0.03..1.5 s |  |
| PASS | atk_bolt | trailing silence 33 ms | trail <= 150 ms |  |
| PASS | atk_bolt | 0.26 s | unit: 0.03..1.5 s |  |
| PASS | atk_bolt_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_bolt_1 | trailing silence 41 ms | trail <= 150 ms |  |
| PASS | atk_bolt_1 | 0.29 s | unit: 0.03..1.5 s |  |
| PASS | atk_bolt_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_bolt_2 | trailing silence 28 ms | trail <= 150 ms |  |
| PASS | atk_bolt_2 | 0.23 s | unit: 0.03..1.5 s |  |
| PASS | atk_bow | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_bow | trailing silence 44 ms | trail <= 150 ms |  |
| PASS | atk_bow | 0.24 s | unit: 0.03..1.5 s |  |
| PASS | atk_bow_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_bow_1 | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | atk_bow_1 | 0.27 s | unit: 0.03..1.5 s |  |
| PASS | atk_bow_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_bow_2 | trailing silence 40 ms | trail <= 150 ms |  |
| PASS | atk_bow_2 | 0.22 s | unit: 0.03..1.5 s |  |
| PASS | atk_heavy | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_whip | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_whip | trailing silence 76 ms | trail <= 150 ms |  |
| PASS | atk_whip | 0.26 s | unit: 0.03..1.5 s |  |
| PASS | atk_whip_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_whip_1 | trailing silence 86 ms | trail <= 150 ms |  |
| PASS | atk_whip_1 | 0.29 s | unit: 0.03..1.5 s |  |
| PASS | atk_whip_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_whip_2 | trailing silence 68 ms | trail <= 150 ms |  |
| PASS | atk_whip_2 | 0.23 s | unit: 0.03..1.5 s |  |
| PASS | bolt_impact | lead silence 0 ms | lead <= 15 ms |  |
| PASS | bolt_impact | trailing silence 46 ms | trail <= 150 ms |  |
| PASS | bolt_impact | 0.14 s | unit: 0.03..1.5 s |  |
| PASS | bolt_impact_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | bolt_impact_1 | trailing silence 53 ms | trail <= 150 ms |  |
| PASS | bolt_impact_1 | 0.15 s | unit: 0.03..1.5 s |  |
| PASS | bolt_impact_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | bolt_impact_2 | trailing silence 43 ms | trail <= 150 ms |  |
| PASS | bolt_impact_2 | 0.13 s | unit: 0.03..1.5 s |  |
| PASS | atk_siege | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_siege | trailing silence 52 ms | trail <= 150 ms |  |
| PASS | atk_siege | 0.45 s | unit: 0.03..1.5 s |  |
| PASS | atk_siege_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_siege_1 | trailing silence 57 ms | trail <= 150 ms |  |
| PASS | atk_siege_1 | 0.50 s | unit: 0.03..1.5 s |  |
| PASS | atk_siege_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_siege_2 | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | atk_siege_2 | 0.40 s | unit: 0.03..1.5 s |  |
| PASS | atk_storm | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_storm | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | atk_storm | 0.40 s | unit: 0.03..1.5 s |  |
| PASS | atk_storm_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_storm_1 | trailing silence 57 ms | trail <= 150 ms |  |
| PASS | atk_storm_1 | 0.45 s | unit: 0.03..1.5 s |  |
| PASS | atk_storm_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | atk_storm_2 | trailing silence 46 ms | trail <= 150 ms |  |
| PASS | atk_storm_2 | 0.36 s | unit: 0.03..1.5 s |  |

### Spectral balance and masking

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| WARN | unit_trained | beats the battle bed by 0.1 dB (low band) | alert >= +3 dB over 6 combat voices in one band | Give it energy where the fight is thin (2-5 kHz presence), or +3 dB; a distinct pitch contour helps. |
| WARN | item_used | low 0% / mid 99% / pres 0% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) | Add 2-5 kHz content so the UI cue reads on small speakers. |
| WARN | building_collapse | low 93% / mid 6% / pres 1% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) | Add 1-4 kHz content (attack, harmonics): all-bass cues vanish on laptop speakers and mud the mix. |
| WARN | building_hit | low 93% / mid 5% / pres 1% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) | Add 1-4 kHz content (attack, harmonics): all-bass cues vanish on laptop speakers and mud the mix. |
| WARN | spell_umbral_shroud | low 98% / mid 2% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) | Add 1-4 kHz content (attack, harmonics): all-bass cues vanish on laptop speakers and mud the mix. |
| WARN | ui_click | low 0% / mid 98% / pres 2% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) | Add 2-5 kHz content so the UI cue reads on small speakers. |
| WARN | construction_done | beats the battle bed by 2.4 dB (mid band) | alert >= +3 dB over 6 combat voices in one band | Give it energy where the fight is thin (2-5 kHz presence), or +1 dB; a distinct pitch contour helps. |
| PASS | fx_bleed_2 | low 2% / mid 95% / pres 1% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | fx_burn | low 37% / mid 52% / pres 8% / air 3% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | fx_burn_1 | low 37% / mid 52% / pres 8% / air 3% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | fx_burn_2 | low 26% / mid 57% / pres 12% / air 4% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | fx_chill | low 0% / mid 68% / pres 28% / air 4% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | fx_chill_1 | low 0% / mid 76% / pres 17% / air 7% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | fx_chill_2 | low 0% / mid 55% / pres 43% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | fx_crit | low 18% / mid 51% / pres 29% / air 3% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | fx_crit_1 | low 23% / mid 53% / pres 21% / air 3% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | fx_crit_2 | low 11% / mid 48% / pres 38% / air 3% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | helper_cast | low 0% / mid 88% / pres 7% / air 5% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | helper_cast_1 | low 1% / mid 87% / pres 7% / air 6% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | helper_cast_2 | low 0% / mid 88% / pres 7% / air 5% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_beast | low 2% / mid 92% / pres 4% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_beast_1 | low 2% / mid 93% / pres 4% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_beast_2 | low 1% / mid 92% / pres 6% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_blade | low 19% / mid 49% / pres 21% / air 10% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_blade_1 | low 37% / mid 40% / pres 16% / air 7% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_blade_2 | low 18% / mid 43% / pres 28% / air 11% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_bolt | low 69% / mid 24% / pres 6% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_bolt_1 | low 80% / mid 14% / pres 4% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_bolt_2 | low 62% / mid 26% / pres 9% / air 3% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_bow | low 12% / mid 72% / pres 11% / air 5% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_bow_2 | low 2% / mid 87% / pres 7% / air 4% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_fire | low 8% / mid 84% / pres 3% / air 5% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_heavy | low 60% / mid 36% / pres 3% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_heavy_1 | low 68% / mid 29% / pres 2% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_heavy_2 | low 55% / mid 40% / pres 4% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_magic | low 7% / mid 93% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_magic_1 | low 10% / mid 90% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_magic_2 | low 5% / mid 95% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_shadow | low 8% / mid 92% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_siege | low 70% / mid 23% / pres 6% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_siege_1 | low 75% / mid 19% / pres 4% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_siege_2 | low 66% / mid 25% / pres 7% / air 3% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_storm | low 14% / mid 35% / pres 25% / air 26% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_storm_1 | low 19% / mid 30% / pres 25% / air 26% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_storm_2 | low 10% / mid 42% / pres 24% / air 25% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_whip | low 48% / mid 40% / pres 10% / air 3% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_whip_1 | low 54% / mid 37% / pres 7% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_whip_2 | low 34% / mid 48% / pres 13% / air 5% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | defeat | low 49% / mid 51% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | defeat | beats the battle bed by 9.4 dB (low band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | fireball_cast | low 46% / mid 50% / pres 3% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | fireball_explode | low 80% / mid 15% / pres 4% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | fx_bleed | low 3% / mid 90% / pres 2% / air 4% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | fx_bleed_1 | low 6% / mid 85% / pres 4% / air 5% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | mine_tick_2 | low 0% / mid 10% / pres 89% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | skill_hit | low 70% / mid 21% / pres 7% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | spell_ember_step | low 4% / mid 77% / pres 9% / air 11% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | spell_kindle | low 5% / mid 94% / pres 1% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | spell_shadow_lance | low 1% / mid 94% / pres 5% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | spell_snow_shield_off | low 2% / mid 60% / pres 34% / air 4% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | spell_snow_shield_on | low 2% / mid 81% / pres 15% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | spell_soul_siphon | low 76% / mid 24% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | spell_vigor_off | low 22% / mid 65% / pres 10% / air 3% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | spell_vigor_on | low 61% / mid 36% / pres 2% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ui_error | low 80% / mid 20% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ui_error | beats the battle bed by 5.5 dB (low band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | ui_helper_call | low 9% / mid 82% / pres 9% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ui_hint | low 0% / mid 89% / pres 11% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ui_plus_start | low 0% / mid 96% / pres 2% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ui_restart | low 0% / mid 93% / pres 6% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ui_tab | low 0% / mid 90% / pres 9% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ui_tab_1 | low 0% / mid 94% / pres 5% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ui_tab_2 | low 0% / mid 83% / pres 17% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ui_tier_start | low 8% / mid 86% / pres 5% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ui_tier_tick | low 1% / mid 76% / pres 17% / air 6% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ui_upgrade_cancel | low 0% / mid 81% / pres 18% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | unit_trained | low 50% / mid 50% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | victory | low 22% / mid 77% / pres 1% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | victory | beats the battle bed by 7.3 dB (mid band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | hit_bow_1 | low 13% / mid 75% / pres 10% / air 3% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_bow_2 | low 4% / mid 79% / pres 12% / air 5% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_heavy | low 30% / mid 63% / pres 5% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_heavy_1 | low 40% / mid 54% / pres 4% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_heavy_2 | low 26% / mid 66% / pres 6% / air 3% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_magic | low 1% / mid 85% / pres 12% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_magic_1 | low 1% / mid 88% / pres 10% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_magic_2 | low 1% / mid 81% / pres 16% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_siege | low 46% / mid 34% / pres 15% / air 5% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_siege_1 | low 59% / mid 27% / pres 11% / air 3% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_siege_2 | low 43% / mid 32% / pres 18% / air 7% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_storm | low 36% / mid 31% / pres 24% / air 10% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_storm_1 | low 44% / mid 29% / pres 19% / air 8% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_storm_2 | low 32% / mid 28% / pres 27% / air 13% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_whip | low 24% / mid 41% / pres 26% / air 9% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_whip_1 | low 39% / mid 37% / pres 17% / air 6% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | hit_whip_2 | low 15% / mid 42% / pres 33% / air 11% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | item_bought | low 0% / mid 64% / pres 34% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | item_pickup | low 0% / mid 95% / pres 4% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | level_up | low 3% / mid 95% / pres 2% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | level_up | beats the battle bed by 6.6 dB (mid band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | melee_hit | low 74% / mid 17% / pres 7% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | melee_hit_1 | low 69% / mid 20% / pres 10% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | melee_hit_2 | low 78% / mid 17% / pres 5% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | mine_tick | low 0% / mid 16% / pres 83% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | mine_tick_1 | low 0% / mid 27% / pres 72% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ab_snare_lash | low 79% / mid 20% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ab_tempest_bolt | low 68% / mid 22% / pres 7% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ab_unbroken_vow | low 48% / mid 52% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ab_wither_hex | low 0% / mid 96% / pres 2% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ability_cast | low 0% / mid 87% / pres 8% / air 4% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | alert_caravan_trained | low 27% / mid 31% / pres 40% / air 3% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | alert_caravan_trained | beats the battle bed by 3.7 dB (presence band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | alert_helper_arrive | low 9% / mid 80% / pres 8% / air 3% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | alert_helper_arrive | beats the battle bed by 3.7 dB (mid band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | alert_helper_fall | low 23% / mid 76% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | alert_helper_fall | beats the battle bed by 3.7 dB (mid band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | alert_helper_revive | low 19% / mid 80% / pres 1% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | alert_helper_revive | beats the battle bed by 4.6 dB (mid band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | alert_path_int | low 1% / mid 96% / pres 3% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | alert_path_int | beats the battle bed by 3.8 dB (mid band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | alert_path_str | low 50% / mid 49% / pres 1% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | alert_path_str | beats the battle bed by 4.6 dB (low band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | alert_plus_done | low 1% / mid 96% / pres 3% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | alert_plus_done | beats the battle bed by 4.0 dB (mid band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | alert_tier_citadel | low 7% / mid 86% / pres 7% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | alert_tier_citadel | beats the battle bed by 3.7 dB (mid band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | alert_tier_stronghold | low 0% / mid 94% / pres 5% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | alert_tier_stronghold | beats the battle bed by 5.5 dB (mid band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | alert_wizard_fell | low 59% / mid 41% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | alert_wizard_fell | beats the battle bed by 8.8 dB (low band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | ab_blood_frenzy | low 72% / mid 25% / pres 2% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ab_challenge | low 27% / mid 69% / pres 2% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ab_flame_burst | low 67% / mid 28% / pres 4% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ab_flashpoint | low 32% / mid 45% / pres 17% / air 6% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ab_frost_needle | low 0% / mid 20% / pres 78% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ab_frost_shell | low 0% / mid 56% / pres 19% / air 25% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ab_frost_shell_1 | low 0% / mid 50% / pres 22% / air 28% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ab_frost_shell_2 | low 0% / mid 68% / pres 12% / air 20% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ab_genie_chain | low 0% / mid 57% / pres 33% / air 10% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ab_genie_chain_1 | low 0% / mid 65% / pres 25% / air 10% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ab_genie_chain_2 | low 0% / mid 46% / pres 46% / air 8% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ab_grave_feast | low 64% / mid 35% / pres 1% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ab_grove_oath | low 55% / mid 44% / pres 1% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ab_hold_the_line | low 45% / mid 47% / pres 6% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ab_piercing_bolt | low 31% / mid 44% / pres 15% / air 10% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ab_piercing_bolt_1 | low 36% / mid 40% / pres 14% / air 10% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ab_piercing_bolt_2 | low 24% / mid 54% / pres 16% / air 7% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ab_sab_armed | low 0% / mid 58% / pres 29% / air 13% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ab_sab_blast | low 72% / mid 19% / pres 6% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ab_sab_disguise | low 0% / mid 61% / pres 18% / air 21% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ab_sab_plant | low 13% / mid 65% / pres 17% / air 5% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ab_sab_reveal | low 19% / mid 67% / pres 10% / air 4% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ab_seed_storm | low 38% / mid 14% / pres 24% / air 25% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ab_skitter | low 0% / mid 78% / pres 10% / air 12% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ab_skitter_1 | low 0% / mid 69% / pres 14% / air 17% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ab_skitter_2 | low 0% / mid 85% / pres 7% / air 8% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_whip_2 | low 0% / mid 22% / pres 41% / air 37% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | bolt_impact | low 16% / mid 69% / pres 11% / air 4% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | bolt_impact_1 | low 20% / mid 63% / pres 13% / air 3% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | bolt_impact_2 | low 12% / mid 79% / pres 7% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | bolt_shot | low 0% / mid 61% / pres 16% / air 23% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | bolt_shot_1 | low 0% / mid 80% / pres 11% / air 8% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | bolt_shot_2 | low 0% / mid 63% / pres 18% / air 18% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | building_collapse | beats the battle bed by 6.9 dB (low band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | building_hit_1 | low 81% / mid 12% / pres 5% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | building_hit_2 | low 71% / mid 16% / pres 10% / air 3% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | construction_done | low 3% / mid 95% / pres 2% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | crown_claimed | low 1% / mid 95% / pres 4% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | crown_claimed | beats the battle bed by 8.4 dB (mid band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | crystals_delivered | low 0% / mid 58% / pres 40% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_beast | low 2% / mid 95% / pres 3% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_beast_1 | low 3% / mid 95% / pres 2% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_beast_2 | low 1% / mid 95% / pres 4% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_blade | low 15% / mid 79% / pres 5% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_blade_1 | low 24% / mid 70% / pres 4% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_blade_2 | low 10% / mid 81% / pres 7% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_bolt | low 27% / mid 65% / pres 6% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_bolt_1 | low 35% / mid 58% / pres 5% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_bolt_2 | low 19% / mid 72% / pres 7% / air 3% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_bow | low 4% / mid 85% / pres 8% / air 3% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_bow_1 | low 6% / mid 85% / pres 6% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_beast | low 59% / mid 35% / pres 4% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_beast_1 | low 64% / mid 32% / pres 4% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_beast_2 | low 58% / mid 35% / pres 5% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_blade | low 0% / mid 23% / pres 37% / air 40% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_blade_1 | low 0% / mid 25% / pres 32% / air 42% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_blade_2 | low 0% / mid 24% / pres 33% / air 42% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_bolt | low 48% / mid 42% / pres 4% / air 6% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_bolt_1 | low 58% / mid 31% / pres 6% / air 6% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_bolt_2 | low 38% / mid 54% / pres 3% / air 4% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_bow | low 72% / mid 9% / pres 10% / air 9% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_bow_1 | low 74% / mid 8% / pres 9% / air 9% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_bow_2 | low 70% / mid 14% / pres 10% / air 7% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_heavy | low 48% / mid 10% / pres 22% / air 20% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_heavy_1 | low 46% / mid 9% / pres 22% / air 23% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_heavy_2 | low 48% / mid 8% / pres 21% / air 23% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_magic | low 2% / mid 92% / pres 3% / air 3% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_magic_1 | low 4% / mid 89% / pres 4% / air 4% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_magic_2 | low 1% / mid 93% / pres 3% / air 3% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_siege | low 68% / mid 4% / pres 13% / air 15% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_siege_1 | low 65% / mid 4% / pres 16% / air 15% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_siege_2 | low 72% / mid 3% / pres 11% / air 14% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_storm | low 0% / mid 70% / pres 19% / air 11% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_storm_1 | low 0% / mid 68% / pres 19% / air 13% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_storm_2 | low 0% / mid 70% / pres 21% / air 9% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_whip | low 0% / mid 25% / pres 35% / air 39% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | atk_whip_1 | low 0% / mid 25% / pres 37% / air 38% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |

### Memory and disk

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | fx_chill | 11 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | fx_chill_1 | 13 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | fx_chill_2 | 10 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | fx_crit | 13 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | fx_crit_1 | 15 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | fx_crit_2 | 12 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | helper_cast | 19 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | helper_cast_1 | 22 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | helper_cast_2 | 17 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_beast | 10 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_beast_1 | 11 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_beast_2 | 9 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_blade | 8 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_blade_1 | 9 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_blade_2 | 7 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_bolt | 9 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_bolt_1 | 10 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_bolt_2 | 8 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_bow | 7 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_bow_1 | 8 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_bow_2 | 6 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_heavy | 13 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_heavy_1 | 15 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_heavy_1 | 36 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_heavy_2 | 29 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_magic | 34 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_magic_1 | 39 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_magic_2 | 31 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_shadow | 34 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_siege | 39 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_siege_1 | 43 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_siege_2 | 35 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_storm | 39 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_storm_1 | 43 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_storm_2 | 35 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_whip | 26 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_whip_1 | 29 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_whip_2 | 23 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | defeat | 121 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | fireball_cast | 24 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | fireball_explode | 47 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | fx_bleed | 11 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | fx_bleed_1 | 13 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | fx_bleed_2 | 10 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | fx_burn | 14 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | fx_burn_1 | 15 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | fx_burn_2 | 12 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | spell_ember_step | 19 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | spell_kindle | 34 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | spell_shadow_lance | 22 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | spell_snow_shield_off | 26 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | spell_snow_shield_on | 39 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | spell_soul_siphon | 47 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | spell_umbral_shroud | 39 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | spell_vigor_off | 22 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | spell_vigor_on | 34 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ui_click | 3 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ui_error | 13 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ui_helper_call | 26 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ui_hint | 19 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ui_plus_start | 15 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ui_restart | 22 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ui_tab | 3 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ui_tab_1 | 3 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ui_tab_2 | 3 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ui_tier_start | 22 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ui_tier_tick | 7 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ui_upgrade_cancel | 14 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | unit_trained | 19 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | victory | 121 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | set | 0.9 MB in memory | set <= 48 MB |  |
| PASS | hit_heavy_2 | 12 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_magic | 10 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_magic_1 | 12 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_magic_2 | 9 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_siege | 17 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_siege_1 | 19 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_siege_2 | 16 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_storm | 15 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_storm_1 | 17 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_storm_2 | 14 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_whip | 9 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_whip_1 | 10 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | hit_whip_2 | 8 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | item_bought | 14 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | item_pickup | 11 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | item_used | 17 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | level_up | 41 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | melee_hit | 9 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | melee_hit_1 | 9 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | melee_hit_2 | 8 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | mine_tick | 4 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | mine_tick_1 | 5 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | mine_tick_2 | 4 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | skill_hit | 12 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ab_skitter_1 | 11 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ab_skitter_2 | 9 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ab_snare_lash | 26 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ab_tempest_bolt | 52 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ab_unbroken_vow | 39 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ab_wither_hex | 30 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ability_cast | 19 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | alert_caravan_trained | 30 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | alert_helper_arrive | 52 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | alert_helper_fall | 52 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | alert_helper_revive | 47 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | alert_path_int | 43 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | alert_path_str | 43 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | alert_plus_done | 34 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | alert_tier_citadel | 73 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | alert_tier_stronghold | 56 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | alert_wizard_fell | 60 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_beast | 13 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_beast_1 | 15 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_beast_2 | 12 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_blade | 9 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_blade_1 | 10 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_blade_2 | 8 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ab_blood_frenzy | 34 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ab_challenge | 30 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ab_flame_burst | 34 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ab_flashpoint | 22 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ab_frost_needle | 14 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ab_frost_shell | 19 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ab_frost_shell_1 | 22 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ab_frost_shell_2 | 17 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ab_genie_chain | 13 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ab_genie_chain_1 | 15 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ab_genie_chain_2 | 12 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ab_grave_feast | 26 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ab_grove_oath | 39 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ab_hold_the_line | 30 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ab_piercing_bolt | 13 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ab_piercing_bolt_1 | 15 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ab_piercing_bolt_2 | 12 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ab_sab_armed | 34 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ab_sab_blast | 56 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ab_sab_disguise | 22 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ab_sab_plant | 26 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ab_sab_reveal | 26 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ab_seed_storm | 39 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ab_skitter | 10 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | bolt_shot | 10 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | bolt_shot_1 | 11 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | bolt_shot_2 | 10 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | building_collapse | 78 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | building_hit | 13 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | building_hit_1 | 14 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | building_hit_2 | 12 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | construction_done | 32 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | crown_claimed | 60 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | crystals_delivered | 17 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_beast | 34 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_beast_1 | 39 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_beast_2 | 31 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_blade | 24 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_blade_1 | 27 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_blade_2 | 21 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_bolt | 28 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_bolt_1 | 31 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_bolt_2 | 25 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_bow | 24 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_bow_1 | 27 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_bow_2 | 21 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_fire | 28 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_heavy | 32 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_bolt | 11 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_bolt_1 | 13 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_bolt_2 | 10 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_bow | 10 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_bow_1 | 12 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_bow_2 | 9 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_heavy | 13 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_heavy_1 | 15 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_heavy_2 | 12 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_magic | 17 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_magic_1 | 19 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_magic_2 | 16 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_siege | 19 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_siege_1 | 22 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_siege_2 | 17 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_storm | 17 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_storm_1 | 19 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_storm_2 | 16 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_whip | 11 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_whip_1 | 13 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | atk_whip_2 | 10 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | bolt_impact | 6 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | bolt_impact_1 | 6 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | bolt_impact_2 | 6 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |

### Bus routing

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | res://scripts/audio/game_audio.gd:1084 | AudioStreamPlayer3D on bus SFX | bus in Music, SFX, Voice |  |
| PASS | res://scripts/audio/game_audio.gd:1095 | AudioStreamPlayer on bus SFX | bus in Music, SFX, Voice |  |
| PASS | res://scripts/audio/game_audio.gd:1099 | AudioStreamPlayer on bus Music | bus in Music, SFX, Voice |  |

### Variation

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | item_pickup | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | item_bought | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | hit_whip | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | hit_storm | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | hit_siege | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | hit_magic | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | hit_heavy | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | hit_bow | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | hit_bolt | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | hit_blade | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | hit_beast | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | helper_cast | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | fx_crit | 3 take(s), pitch +-7%, ~60/min | frequent cue: >= 3 takes, or 2 takes + pitch / volume randomisation |  |
| PASS | fx_chill | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | fx_burn | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | fx_bleed | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | fireball_explode | 1 take(s), pitch +-7%, ~6/min | occasional cue (< 20/min): one take is fine |  |
| PASS | fireball_cast | 1 take(s), pitch +-7%, ~6/min | occasional cue (< 20/min): one take is fine |  |
| PASS | defeat | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | death_whip | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | death_storm | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | death_siege | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | death_shadow | 1 take(s), pitch +-7%, ~12/min | occasional cue (< 20/min): one take is fine |  |
| PASS | death_magic | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | death_heavy | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | death_fire | 1 take(s), pitch +-7%, ~12/min | occasional cue (< 20/min): one take is fine |  |
| PASS | victory | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | unit_trained | 1 take(s), pitch +-7%, ~4/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ui_upgrade_cancel | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ui_tier_tick | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ui_tier_start | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ui_tab | 3 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ui_restart | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ui_plus_start | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ui_hint | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ui_helper_call | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ui_error | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ui_click | 1 take(s), pitch +-0%, ~30/min | UI cues stay identical on purpose (consistency) |  |
| PASS | spell_vigor_on | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | spell_vigor_off | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | spell_umbral_shroud | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | spell_soul_siphon | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | spell_snow_shield_on | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | spell_snow_shield_off | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | spell_shadow_lance | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | spell_kindle | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | spell_ember_step | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | skill_hit | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | mine_tick | 3 take(s), pitch +-7%, ~60/min | frequent cue: >= 3 takes, or 2 takes + pitch / volume randomisation |  |
| PASS | melee_hit | 3 take(s), pitch +-7%, ~120/min | frequent cue: >= 3 takes, or 2 takes + pitch / volume randomisation |  |
| PASS | level_up | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | item_used | 1 take(s), pitch +-0%, ~3/min | occasional cue (< 20/min): one take is fine |  |
| PASS | alert_helper_fall | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | alert_helper_arrive | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | alert_caravan_trained | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ability_cast | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ab_wither_hex | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ab_unbroken_vow | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ab_tempest_bolt | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ab_snare_lash | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ab_skitter | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ab_seed_storm | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ab_sab_reveal | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ab_sab_plant | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ab_sab_disguise | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ab_sab_blast | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ab_sab_armed | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ab_piercing_bolt | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ab_hold_the_line | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ab_grove_oath | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ab_grave_feast | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ab_genie_chain | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ab_frost_shell | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ab_frost_needle | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ab_flashpoint | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ab_flame_burst | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ab_challenge | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ab_blood_frenzy | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | death_bow | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | death_bolt | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | death_blade | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | death_beast | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | crystals_delivered | 1 take(s), pitch +-0%, ~20/min | UI cues stay identical on purpose (consistency) |  |
| PASS | crown_claimed | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | construction_done | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | building_hit | 3 take(s), pitch +-7%, ~40/min | frequent cue: >= 3 takes, or 2 takes + pitch / volume randomisation |  |
| PASS | building_collapse | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | bolt_shot | 3 take(s), pitch +-7%, ~120/min | frequent cue: >= 3 takes, or 2 takes + pitch / volume randomisation |  |
| PASS | bolt_impact | 3 take(s), pitch +-7%, ~120/min | frequent cue: >= 3 takes, or 2 takes + pitch / volume randomisation |  |
| PASS | atk_whip | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | atk_storm | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | atk_siege | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | atk_magic | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | atk_heavy | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | atk_bow | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | atk_bolt | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | atk_blade | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | atk_beast | 3 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | alert_wizard_fell | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | alert_tier_stronghold | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | alert_tier_citadel | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | alert_plus_done | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | alert_path_str | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | alert_path_int | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | alert_helper_revive | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |

### 3D attenuation

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | res://scripts/audio/game_audio.gd:1084 | unit_size 18, max_distance 75, inverse_distance; -4.4 dB @30 m, -9.7 dB @55 m, -12.4 dB @cut | gain >= -15 dB at 30 m, <= -10 dB at the cut-off |  |

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
| PASS | fx_crit_2 | rate limit 0.1 s | frequent cue has a per-cue cooldown >= 0.03 s |  |
| PASS | fx_crit_1 | rate limit 0.1 s | frequent cue has a per-cue cooldown >= 0.03 s |  |
| PASS | fx_crit | rate limit 0.1 s | frequent cue has a per-cue cooldown >= 0.03 s |  |
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
| ab_blood_frenzy | unit | 3d | -20.9 | -11.5 | -5.0 | -4.4 | -1.8 | 0.80 | 0 / 50 | 72/25/2/1 | 0 | 1 | +-7% | generated |
| ab_challenge | unit | 3d | -23.4 | -13.9 | -5.0 | -4.4 | -3.9 | 0.70 | 0 / 50 | 27/69/2/1 | 0 | 1 | +-7% | generated |
| ab_flame_burst | unit | 3d | -18.7 | -10.3 | -4.0 | -4.4 | -2.0 | 0.80 | 0 / 50 | 67/28/4/1 | 0 | 1 | +-7% | generated |
| ab_flashpoint | unit | 3d | -22.1 | -12.6 | -5.0 | -4.4 | -2.3 | 0.50 | 0 / 52 | 32/45/17/6 | 0 | 1 | +-7% | generated |
| ab_frost_needle | unit | 3d | -20.7 | -10.3 | -6.0 | -4.4 | -3.3 | 0.32 | 0 / 40 | 0/20/78/2 | 0 | 1 | +-7% | generated |
| ab_frost_shell | unit | 3d | -23.1 | -12.6 | -6.0 | -4.4 | -4.5 | 0.45 | 0 / 50 | 0/56/19/25 | 0 | 3 | +-7% | generated |
| ab_frost_shell_1 | unit | 3d | -22.9 | -12.5 | -6.0 | -4.4 | -3.3 | 0.50 | 0 / 57 | 0/50/22/28 | 0 | 3 | +-7% | file |
| ab_frost_shell_2 | unit | 3d | -23.3 | -12.8 | -6.0 | -4.4 | -2.8 | 0.40 | 0 / 46 | 0/68/12/20 | 0 | 3 | +-7% | file |
| ab_genie_chain | unit | 3d | -19.6 | -9.2 | -6.0 | -4.4 | -3.3 | 0.30 | 0 / 50 | 0/57/33/10 | 0 | 3 | +-7% | generated |
| ab_genie_chain_1 | unit | 3d | -20.0 | -9.6 | -6.0 | -4.4 | -2.6 | 0.34 | 0 / 54 | 0/65/25/10 | 0 | 3 | +-7% | file |
| ab_genie_chain_2 | unit | 3d | -19.4 | -8.9 | -6.0 | -4.4 | -2.5 | 0.27 | 0 / 45 | 0/46/46/8 | 0 | 3 | +-7% | file |
| ab_grave_feast | unit | 3d | -21.1 | -11.6 | -5.0 | -4.4 | -2.9 | 0.60 | 0 / 30 | 64/35/1/0 | 0 | 1 | +-7% | generated |
| ab_grove_oath | unit | 3d | -21.3 | -11.9 | -5.0 | -4.4 | -2.3 | 0.90 | 0 / 50 | 55/44/1/0 | 0 | 1 | +-7% | generated |
| ab_hold_the_line | unit | 3d | -23.1 | -13.7 | -5.0 | -4.4 | -2.2 | 0.70 | 0 / 53 | 45/47/6/2 | 0 | 1 | +-7% | generated |
| ab_piercing_bolt | unit | 3d | -27.2 | -16.8 | -6.0 | -4.4 | -3.3 | 0.30 | 0 / 38 | 31/44/15/10 | 0 | 3 | +-7% | generated |
| ab_piercing_bolt_1 | unit | 3d | -27.2 | -16.8 | -6.0 | -4.4 | -2.1 | 0.34 | 0 / 46 | 36/40/14/10 | 0 | 3 | +-7% | file |
| ab_piercing_bolt_2 | unit | 3d | -27.7 | -17.3 | -6.0 | -4.4 | -1.8 | 0.27 | 0 / 36 | 24/54/16/7 | 0 | 3 | +-7% | file |
| ab_sab_armed | unit | 3d | -21.8 | -12.4 | -5.0 | -4.4 | -3.1 | 0.80 | 0 / 50 | 0/58/29/13 | 0 | 1 | +-7% | generated |
| ab_sab_blast | unit | 3d | -18.3 | -9.9 | -4.0 | -4.4 | -1.7 | 1.30 | 0 / 52 | 72/19/6/2 | 0 | 1 | +-7% | generated |
| ab_sab_disguise | unit | 3d | -22.3 | -12.9 | -5.0 | -4.4 | -4.7 | 0.50 | 0 / 51 | 0/61/18/21 | 0 | 1 | +-7% | generated |
| ab_sab_plant | unit | 3d | -24.7 | -15.3 | -5.0 | -4.4 | -3.3 | 0.60 | 0 / 50 | 13/65/17/5 | 0 | 1 | +-7% | generated |
| ab_sab_reveal | unit | 3d | -22.1 | -12.7 | -5.0 | -4.4 | -2.4 | 0.60 | 0 / 100 | 19/67/10/4 | 0 | 1 | +-7% | generated |
| ab_seed_storm | unit | 3d | -21.8 | -12.3 | -5.0 | -4.4 | -2.2 | 0.90 | 1 / 118 | 38/14/24/25 | 0 | 1 | +-7% | generated |
| ab_skitter | unit | 3d | -27.6 | -16.2 | -7.0 | -4.4 | -4.5 | 0.22 | 0 / 21 | 0/78/10/12 | 0 | 3 | +-7% | generated |
| ab_skitter_1 | unit | 3d | -27.6 | -16.1 | -7.0 | -4.4 | -5.3 | 0.25 | 0 / 23 | 0/69/14/17 | 0 | 3 | +-7% | file |
| ab_skitter_2 | unit | 3d | -27.9 | -16.5 | -7.0 | -4.4 | -5.1 | 0.20 | 0 / 18 | 0/85/7/8 | 0 | 3 | +-7% | file |
| ab_snare_lash | unit | 3d | -18.5 | -9.1 | -5.0 | -4.4 | -2.6 | 0.60 | 0 / 20 | 79/20/0/0 | 0 | 1 | +-7% | generated |
| ab_tempest_bolt | unit | 3d | -18.1 | -9.7 | -4.0 | -4.4 | -1.0 | 1.20 | 0 / 51 | 68/22/7/2 | 0 | 1 | +-7% | generated |
| ab_unbroken_vow | unit | 3d | -19.4 | -9.9 | -5.0 | -4.4 | -2.2 | 0.90 | 0 / 51 | 48/52/0/0 | 0 | 1 | +-7% | generated |
| ab_wither_hex | unit | 3d | -19.5 | -10.1 | -5.0 | -4.4 | -3.0 | 0.70 | 0 / 50 | 0/96/2/2 | 0 | 1 | +-7% | generated |
| ability_cast | spell | 3d | -23.4 | -10.9 | -8.0 | -4.4 | -3.4 | 0.45 | 1 / 3 | 0/87/8/4 | 0 | 1 | +-7% | generated |
| alert_caravan_trained | alert | 3d | -16.2 | -10.8 | -1.0 | -4.4 | -4.0 | 0.70 | 0 / 4 | 27/31/40/3 | 0 | 1 | +-7% | generated |
| alert_helper_arrive | alert | 2d | -12.5 | -10.5 | -2.0 | 0.0 | -1.5 | 1.20 | 2 / 20 | 9/80/8/3 | 0 | 1 | - | generated |
| alert_helper_fall | alert | 2d | -12.3 | -8.3 | -4.0 | 0.0 | -2.0 | 1.20 | 0 / 50 | 23/76/0/0 | 0 | 1 | - | generated |
| alert_helper_revive | alert | 2d | -11.6 | -9.6 | -2.0 | 0.0 | -1.9 | 1.10 | 1 / 50 | 19/80/1/0 | 0 | 1 | - | generated |
| alert_path_int | alert | 2d | -13.2 | -9.2 | -4.0 | 0.0 | -1.8 | 1.00 | 0 / 100 | 1/96/3/0 | 0 | 1 | - | generated |
| alert_path_str | alert | 2d | -12.6 | -10.1 | -2.5 | 0.0 | -1.3 | 1.00 | 0 / 50 | 50/49/1/0 | 0 | 1 | - | generated |
| alert_plus_done | alert | 2d | -13.0 | -9.0 | -4.0 | 0.0 | -2.3 | 0.80 | 0 / 51 | 1/96/3/0 | 0 | 1 | - | generated |
| alert_tier_citadel | alert | 2d | -12.8 | -10.8 | -2.0 | 0.0 | -1.9 | 1.70 | 0 / 20 | 7/86/7/0 | 0 | 1 | - | generated |
| alert_tier_stronghold | alert | 2d | -11.4 | -8.4 | -3.0 | 0.0 | -1.4 | 1.30 | 0 / 20 | 0/94/5/0 | 0 | 1 | - | generated |
| alert_wizard_fell | alert | 2d | -9.0 | -9.0 | 0.0 | 0.0 | -2.5 | 1.40 | 0 / 50 | 59/41/0/0 | 0 | 1 | - | generated |
| atk_beast | unit | 3d | -25.6 | -15.1 | -6.0 | -4.4 | -2.8 | 0.30 | 0 / 66 | 59/35/4/2 | 0 | 3 | +-7% | generated |
| atk_beast_1 | unit | 3d | -25.7 | -15.3 | -6.0 | -4.4 | -2.7 | 0.34 | 0 / 72 | 64/32/4/1 | 0 | 3 | +-7% | file |
| atk_beast_2 | unit | 3d | -25.3 | -14.9 | -6.0 | -4.4 | -3.4 | 0.27 | 0 / 59 | 58/35/5/2 | 0 | 3 | +-7% | file |
| atk_blade | unit | 3d | -24.7 | -14.2 | -6.0 | -4.4 | -3.0 | 0.20 | 0 / 61 | 0/23/37/40 | 0 | 3 | +-7% | generated |
| atk_blade_1 | unit | 3d | -24.6 | -14.1 | -6.0 | -4.4 | -3.3 | 0.22 | 0 / 68 | 0/25/32/42 | 0 | 3 | +-7% | file |
| atk_blade_2 | unit | 3d | -24.8 | -14.4 | -6.0 | -4.4 | -3.5 | 0.18 | 0 / 55 | 0/24/33/42 | 0 | 3 | +-7% | file |
| atk_bolt | unit | 3d | -27.7 | -17.3 | -6.0 | -4.4 | -3.1 | 0.26 | 0 / 33 | 48/42/4/6 | 0 | 3 | +-7% | generated |
| atk_bolt_1 | unit | 3d | -27.7 | -17.2 | -6.0 | -4.4 | -3.4 | 0.29 | 0 / 41 | 58/31/6/6 | 0 | 3 | +-7% | file |
| atk_bolt_2 | unit | 3d | -27.9 | -17.5 | -6.0 | -4.4 | -4.2 | 0.23 | 0 / 28 | 38/54/3/4 | 0 | 3 | +-7% | file |
| atk_bow | unit | 3d | -28.9 | -17.5 | -7.0 | -4.4 | -4.0 | 0.24 | 0 / 44 | 72/9/10/9 | 0 | 3 | +-7% | generated |
| atk_bow_1 | unit | 3d | -28.8 | -17.4 | -7.0 | -4.4 | -2.8 | 0.27 | 0 / 50 | 74/8/9/9 | 0 | 3 | +-7% | file |
| atk_bow_2 | unit | 3d | -29.1 | -17.7 | -7.0 | -4.4 | -2.5 | 0.22 | 0 / 40 | 70/14/10/7 | 0 | 3 | +-7% | file |
| atk_heavy | unit | 3d | -21.2 | -10.8 | -6.0 | -4.4 | -3.3 | 0.30 | 0 / 23 | 48/10/22/20 | 0 | 3 | +-7% | generated |
| atk_heavy_1 | unit | 3d | -21.1 | -10.6 | -6.0 | -4.4 | -3.6 | 0.34 | 0 / 25 | 46/9/22/23 | 0 | 3 | +-7% | file |
| atk_heavy_2 | unit | 3d | -21.2 | -10.8 | -6.0 | -4.4 | -2.9 | 0.27 | 0 / 20 | 48/8/21/23 | 0 | 3 | +-7% | file |
| atk_magic | unit | 3d | -23.1 | -12.6 | -6.0 | -4.4 | -3.2 | 0.40 | 0 / 40 | 2/92/3/3 | 0 | 3 | +-7% | generated |
| atk_magic_1 | unit | 3d | -23.1 | -12.6 | -6.0 | -4.4 | -3.6 | 0.45 | 0 / 45 | 4/89/4/4 | 0 | 3 | +-7% | file |
| atk_magic_2 | unit | 3d | -23.0 | -12.6 | -6.0 | -4.4 | -2.4 | 0.36 | 0 / 36 | 1/93/3/3 | 0 | 3 | +-7% | file |
| atk_siege | unit | 3d | -23.2 | -12.8 | -6.0 | -4.4 | -2.6 | 0.45 | 0 / 52 | 68/4/13/15 | 0 | 3 | +-7% | generated |
| atk_siege_1 | unit | 3d | -23.1 | -12.7 | -6.0 | -4.4 | -3.3 | 0.50 | 0 / 57 | 65/4/16/15 | 0 | 3 | +-7% | file |
| atk_siege_2 | unit | 3d | -23.7 | -13.3 | -6.0 | -4.4 | -2.9 | 0.40 | 0 / 50 | 72/3/11/14 | 0 | 3 | +-7% | file |
| atk_storm | unit | 3d | -21.5 | -11.1 | -6.0 | -4.4 | -3.5 | 0.40 | 0 / 50 | 0/70/19/11 | 0 | 3 | +-7% | generated |
| atk_storm_1 | unit | 3d | -21.9 | -11.4 | -6.0 | -4.4 | -2.9 | 0.45 | 0 / 57 | 0/68/19/13 | 0 | 3 | +-7% | file |
| atk_storm_2 | unit | 3d | -21.4 | -11.0 | -6.0 | -4.4 | -3.5 | 0.36 | 0 / 46 | 0/70/21/9 | 0 | 3 | +-7% | file |
| atk_whip | unit | 3d | -23.7 | -13.3 | -6.0 | -4.4 | -3.6 | 0.26 | 0 / 76 | 0/25/35/39 | 0 | 3 | +-7% | generated |
| atk_whip_1 | unit | 3d | -23.5 | -13.0 | -6.0 | -4.4 | -4.6 | 0.29 | 0 / 86 | 0/25/37/38 | 0 | 3 | +-7% | file |
| atk_whip_2 | unit | 3d | -23.5 | -13.1 | -6.0 | -4.4 | -3.0 | 0.23 | 0 / 68 | 0/22/41/37 | 0 | 3 | +-7% | file |
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
| death_beast | unit | 3d | -18.1 | -9.2 | -4.5 | -4.4 | -2.6 | 0.80 | 0 / 50 | 2/95/3/0 | 0 | 3 | +-7% | generated |
| death_beast_1 | unit | 3d | -18.2 | -9.3 | -4.5 | -4.4 | -2.9 | 0.90 | 0 / 56 | 3/95/2/0 | 0 | 3 | +-7% | file |
| death_beast_2 | unit | 3d | -18.0 | -9.1 | -4.5 | -4.4 | -2.4 | 0.72 | 0 / 45 | 1/95/4/0 | 0 | 3 | +-7% | file |
| death_blade | unit | 3d | -19.2 | -12.8 | -2.0 | -4.4 | -2.1 | 0.55 | 0 / 101 | 15/79/5/2 | 0 | 3 | +-7% | generated |
| death_blade_1 | unit | 3d | -19.6 | -13.1 | -2.0 | -4.4 | -1.8 | 0.62 | 0 / 113 | 24/70/4/2 | 0 | 3 | +-7% | file |
| death_blade_2 | unit | 3d | -19.5 | -13.0 | -2.0 | -4.4 | -2.0 | 0.49 | 0 / 90 | 10/81/7/2 | 0 | 3 | +-7% | file |
| death_bolt | unit | 3d | -19.4 | -12.0 | -3.0 | -4.4 | -2.4 | 0.65 | 0 / 102 | 27/65/6/2 | 0 | 3 | +-7% | generated |
| death_bolt_1 | unit | 3d | -19.5 | -12.1 | -3.0 | -4.4 | -2.7 | 0.73 | 0 / 113 | 35/58/5/2 | 0 | 3 | +-7% | file |
| death_bolt_2 | unit | 3d | -19.5 | -12.0 | -3.0 | -4.4 | -2.2 | 0.58 | 0 / 92 | 19/72/7/3 | 0 | 3 | +-7% | file |
| death_bow | unit | 3d | -20.0 | -12.6 | -3.0 | -4.4 | -2.9 | 0.55 | 0 / 50 | 4/85/8/3 | 0 | 3 | +-7% | generated |
| death_bow_1 | unit | 3d | -20.2 | -12.8 | -3.0 | -4.4 | -3.1 | 0.62 | 0 / 57 | 6/85/6/2 | 0 | 3 | +-7% | file |
| death_bow_2 | unit | 3d | -20.0 | -12.6 | -3.0 | -4.4 | -2.3 | 0.49 | 0 / 45 | 2/87/7/4 | 0 | 3 | +-7% | file |
| death_fire | unit | 3d | -19.3 | -11.9 | -3.0 | -4.4 | -2.2 | 0.65 | 0 / 101 | 8/84/3/5 | 12 | 1 | +-7% | generated |
| death_heavy | unit | 3d | -19.2 | -11.8 | -3.0 | -4.4 | -2.8 | 0.75 | 0 / 98 | 60/36/3/1 | 0 | 3 | +-7% | generated |
| death_heavy_1 | unit | 3d | -19.3 | -11.9 | -3.0 | -4.4 | -3.3 | 0.84 | 0 / 108 | 68/29/2/1 | 0 | 3 | +-7% | file |
| death_heavy_2 | unit | 3d | -19.1 | -11.7 | -3.0 | -4.4 | -2.0 | 0.67 | 0 / 87 | 55/40/4/2 | 0 | 3 | +-7% | file |
| death_magic | unit | 3d | -17.7 | -10.2 | -3.0 | -4.4 | -2.7 | 0.80 | 0 / 50 | 7/93/0/0 | 0 | 3 | +-7% | generated |
| death_magic_1 | unit | 3d | -17.7 | -10.3 | -3.0 | -4.4 | -3.3 | 0.90 | 0 / 56 | 10/90/0/0 | 0 | 3 | +-7% | file |
| death_magic_2 | unit | 3d | -17.6 | -10.2 | -3.0 | -4.4 | -1.9 | 0.72 | 0 / 45 | 5/95/0/0 | 0 | 3 | +-7% | file |
| death_shadow | unit | 3d | -17.9 | -8.5 | -5.0 | -4.4 | -2.0 | 0.80 | 0 / 51 | 8/92/0/0 | 12 | 1 | +-7% | generated |
| death_siege | unit | 3d | -18.0 | -10.5 | -3.0 | -4.4 | -1.7 | 0.90 | 0 / 101 | 70/23/6/2 | 0 | 3 | +-7% | generated |
| death_siege_1 | unit | 3d | -18.6 | -11.1 | -3.0 | -4.4 | -2.5 | 1.01 | 0 / 113 | 75/19/4/1 | 0 | 3 | +-7% | file |
| death_siege_2 | unit | 3d | -19.4 | -12.0 | -3.0 | -4.4 | -1.8 | 0.81 | 0 / 91 | 66/25/7/3 | 0 | 3 | +-7% | file |
| death_storm | unit | 3d | -18.3 | -8.8 | -5.0 | -4.4 | -3.5 | 0.90 | 1 / 50 | 14/35/25/26 | 0 | 3 | +-7% | generated |
| death_storm_1 | unit | 3d | -18.3 | -8.8 | -5.0 | -4.4 | -3.0 | 1.01 | 1 / 56 | 19/30/25/26 | 0 | 3 | +-7% | file |
| death_storm_2 | unit | 3d | -18.2 | -8.7 | -5.0 | -4.4 | -3.3 | 0.81 | 1 / 45 | 10/42/24/25 | 0 | 3 | +-7% | file |
| death_whip | unit | 3d | -18.7 | -10.8 | -3.5 | -4.4 | -1.9 | 0.60 | 0 / 51 | 48/40/10/3 | 0 | 3 | +-7% | generated |
| death_whip_1 | unit | 3d | -19.4 | -11.5 | -3.5 | -4.4 | -2.4 | 0.67 | 0 / 57 | 54/37/7/2 | 0 | 3 | +-7% | file |
| death_whip_2 | unit | 3d | -18.5 | -10.5 | -3.5 | -4.4 | -2.2 | 0.54 | 0 / 46 | 34/48/13/5 | 0 | 3 | +-7% | file |
| defeat | alert | 2d | -7.6 | -7.6 | 0.0 | 0.0 | -1.9 | 2.80 | 0 / 0 | 49/51/0/0 | 0 | 1 | - | generated |
| fireball_cast | spell | 3d | -12.7 | -8.2 | 0.0 | -4.4 | -1.3 | 0.55 | 0 / 50 | 46/50/3/1 | 6 | 1 | +-7% | generated |
| fireball_explode | spell | 3d | -14.1 | -9.7 | 0.0 | -4.4 | -0.3 | 1.10 | 0 / 55 | 80/15/4/1 | 6 | 1 | +-7% | generated |
| fx_bleed | unit | 3d | -24.3 | -13.8 | -6.0 | -4.4 | -4.2 | 0.26 | 0 / 12 | 3/90/2/4 | 0 | 3 | +-7% | generated |
| fx_bleed_1 | unit | 3d | -24.2 | -13.7 | -6.0 | -4.4 | -4.6 | 0.29 | 0 / 12 | 6/85/4/5 | 0 | 3 | +-7% | file |
| fx_bleed_2 | unit | 3d | -24.4 | -13.9 | -6.0 | -4.4 | -3.4 | 0.23 | 0 / 10 | 2/95/1/2 | 0 | 3 | +-7% | file |
| fx_burn | unit | 3d | -24.7 | -14.3 | -6.0 | -4.4 | -3.9 | 0.32 | 0 / 20 | 37/52/8/3 | 0 | 3 | +-7% | generated |
| fx_burn_1 | unit | 3d | -24.8 | -14.3 | -6.0 | -4.4 | -2.0 | 0.36 | 0 / 22 | 37/52/8/3 | 0 | 3 | +-7% | file |
| fx_burn_2 | unit | 3d | -25.5 | -15.1 | -6.0 | -4.4 | -1.6 | 0.29 | 0 / 18 | 26/57/12/4 | 0 | 3 | +-7% | file |
| fx_chill | unit | 3d | -23.7 | -13.3 | -6.0 | -4.4 | -4.0 | 0.26 | 0 / 21 | 0/68/28/4 | 0 | 3 | +-7% | generated |
| fx_chill_1 | unit | 3d | -24.1 | -13.7 | -6.0 | -4.4 | -4.4 | 0.29 | 0 / 24 | 0/76/17/7 | 0 | 3 | +-7% | file |
| fx_chill_2 | unit | 3d | -23.4 | -13.0 | -6.0 | -4.4 | -4.1 | 0.23 | 0 / 19 | 0/55/43/2 | 0 | 3 | +-7% | file |
| fx_crit | unit | 3d | -27.2 | -16.8 | -6.0 | -4.4 | -2.9 | 0.30 | 0 / 23 | 18/51/29/3 | 60* | 3 | +-7% | generated |
| fx_crit_1 | unit | 3d | -27.5 | -17.1 | -6.0 | -4.4 | -3.3 | 0.34 | 0 / 26 | 23/53/21/3 | 60* | 3 | +-7% | file |
| fx_crit_2 | unit | 3d | -27.0 | -16.5 | -6.0 | -4.4 | -3.7 | 0.27 | 0 / 21 | 11/48/38/3 | 60* | 3 | +-7% | file |
| helper_cast | unit | 3d | -21.9 | -12.4 | -5.0 | -4.4 | -3.4 | 0.45 | 0 / 50 | 0/88/7/5 | 0 | 3 | +-7% | generated |
| helper_cast_1 | unit | 3d | -22.0 | -12.5 | -5.0 | -4.4 | -3.1 | 0.50 | 0 / 56 | 1/87/7/6 | 0 | 3 | +-7% | file |
| helper_cast_2 | unit | 3d | -21.9 | -12.5 | -5.0 | -4.4 | -2.3 | 0.40 | 0 / 45 | 0/88/7/5 | 0 | 3 | +-7% | file |
| hit_beast | unit | 3d | -26.4 | -17.0 | -5.0 | -4.4 | -3.2 | 0.22 | 0 / 41 | 2/92/4/1 | 0 | 3 | +-7% | generated |
| hit_beast_1 | unit | 3d | -26.5 | -17.0 | -5.0 | -4.4 | -3.3 | 0.25 | 0 / 46 | 2/93/4/1 | 0 | 3 | +-7% | file |
| hit_beast_2 | unit | 3d | -26.3 | -16.9 | -5.0 | -4.4 | -1.5 | 0.20 | 0 / 37 | 1/92/6/2 | 0 | 3 | +-7% | file |
| hit_blade | unit | 3d | -29.3 | -19.9 | -5.0 | -4.4 | -2.2 | 0.18 | 0 / 93 | 19/49/21/10 | 0 | 3 | +-7% | generated |
| hit_blade_1 | unit | 3d | -29.7 | -20.2 | -5.0 | -4.4 | -3.4 | 0.20 | 0 / 103 | 37/40/16/7 | 0 | 3 | +-7% | file |
| hit_blade_2 | unit | 3d | -29.0 | -19.6 | -5.0 | -4.4 | -3.9 | 0.16 | 0 / 83 | 18/43/28/11 | 0 | 3 | +-7% | file |
| hit_bolt | unit | 3d | -27.3 | -17.9 | -5.0 | -4.4 | -2.9 | 0.20 | 0 / 60 | 69/24/6/2 | 0 | 3 | +-7% | generated |
| hit_bolt_1 | unit | 3d | -27.5 | -18.1 | -5.0 | -4.4 | -3.6 | 0.22 | 0 / 66 | 80/14/4/2 | 0 | 3 | +-7% | file |
| hit_bolt_2 | unit | 3d | -27.0 | -17.6 | -5.0 | -4.4 | -2.2 | 0.18 | 0 / 52 | 62/26/9/3 | 0 | 3 | +-7% | file |
| hit_bow | unit | 3d | -28.2 | -20.8 | -3.0 | -4.4 | -2.4 | 0.16 | 0 / 69 | 12/72/11/5 | 0 | 3 | +-7% | generated |
| hit_bow_1 | unit | 3d | -28.3 | -20.9 | -3.0 | -4.4 | -3.8 | 0.18 | 0 / 80 | 13/75/10/3 | 0 | 3 | +-7% | file |
| hit_bow_2 | unit | 3d | -28.1 | -20.6 | -3.0 | -4.4 | -3.1 | 0.14 | 0 / 61 | 4/79/12/5 | 0 | 3 | +-7% | file |
| hit_heavy | unit | 3d | -27.7 | -18.3 | -5.0 | -4.4 | -2.3 | 0.30 | 0 / 23 | 30/63/5/2 | 0 | 3 | +-7% | generated |
| hit_heavy_1 | unit | 3d | -27.9 | -18.4 | -5.0 | -4.4 | -1.7 | 0.34 | 0 / 25 | 40/54/4/1 | 0 | 3 | +-7% | file |
| hit_heavy_2 | unit | 3d | -27.6 | -18.2 | -5.0 | -4.4 | -2.6 | 0.27 | 0 / 21 | 26/66/6/3 | 0 | 3 | +-7% | file |
| hit_magic | unit | 3d | -25.8 | -16.4 | -5.0 | -4.4 | -3.4 | 0.24 | 0 / 43 | 1/85/12/2 | 0 | 3 | +-7% | generated |
| hit_magic_1 | unit | 3d | -26.1 | -16.6 | -5.0 | -4.4 | -2.1 | 0.27 | 0 / 49 | 1/88/10/1 | 0 | 3 | +-7% | file |
| hit_magic_2 | unit | 3d | -26.3 | -16.9 | -5.0 | -4.4 | -1.5 | 0.22 | 0 / 39 | 1/81/16/2 | 0 | 3 | +-7% | file |
| hit_siege | unit | 3d | -25.4 | -15.0 | -6.0 | -4.4 | -2.7 | 0.40 | 0 / 54 | 46/34/15/5 | 0 | 3 | +-7% | generated |
| hit_siege_1 | unit | 3d | -25.8 | -15.4 | -6.0 | -4.4 | -3.0 | 0.45 | 0 / 60 | 59/27/11/3 | 0 | 3 | +-7% | file |
| hit_siege_2 | unit | 3d | -25.2 | -14.7 | -6.0 | -4.4 | -2.5 | 0.36 | 0 / 49 | 43/32/18/7 | 0 | 3 | +-7% | file |
| hit_storm | unit | 3d | -24.2 | -13.8 | -6.0 | -4.4 | -2.9 | 0.35 | 0 / 54 | 36/31/24/10 | 0 | 3 | +-7% | generated |
| hit_storm_1 | unit | 3d | -24.5 | -14.0 | -6.0 | -4.4 | -2.6 | 0.39 | 0 / 60 | 44/29/19/8 | 0 | 3 | +-7% | file |
| hit_storm_2 | unit | 3d | -24.3 | -13.8 | -6.0 | -4.4 | -1.3 | 0.31 | 0 / 49 | 32/28/27/13 | 0 | 3 | +-7% | file |
| hit_whip | unit | 3d | -27.6 | -18.2 | -5.0 | -4.4 | -3.0 | 0.20 | 0 / 45 | 24/41/26/9 | 0 | 3 | +-7% | generated |
| hit_whip_1 | unit | 3d | -28.3 | -18.8 | -5.0 | -4.4 | -3.5 | 0.22 | 0 / 50 | 39/37/17/6 | 0 | 3 | +-7% | file |
| hit_whip_2 | unit | 3d | -27.3 | -17.9 | -5.0 | -4.4 | -1.3 | 0.18 | 0 / 40 | 15/42/33/11 | 0 | 3 | +-7% | file |
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
| spell_snow_shield_off | spell | 3d | -16.7 | -12.2 | 0.0 | -4.4 | -3.0 | 0.60 | 0 / 101 | 2/60/34/4 | 0 | 1 | +-7% | generated |
| spell_snow_shield_on | spell | 3d | -12.7 | -8.3 | 0.0 | -4.4 | -1.6 | 0.90 | 0 / 4 | 2/81/15/2 | 0 | 1 | +-7% | generated |
| spell_soul_siphon | spell | 3d | -11.3 | -6.8 | 0.0 | -4.4 | -2.0 | 1.10 | 1 / 50 | 76/24/0/0 | 0 | 1 | +-7% | generated |
| spell_umbral_shroud | spell | 3d | -12.0 | -7.5 | 0.0 | -4.4 | -1.8 | 0.90 | 1 / 50 | 98/2/0/0 | 0 | 1 | +-7% | generated |
| spell_vigor_off | spell | 3d | -18.0 | -13.6 | 0.0 | -4.4 | -3.2 | 0.50 | 0 / 51 | 22/65/10/3 | 0 | 1 | +-7% | generated |
| spell_vigor_on | spell | 3d | -14.8 | -10.4 | 0.0 | -4.4 | -1.4 | 0.80 | 0 / 50 | 61/36/2/1 | 0 | 1 | +-7% | generated |
| ui_click | ui | 2d | -33.7 | -25.7 | -8.0 | 0.0 | -8.2 | 0.06 | 0 / 31 | 0/98/2/0 | 30* | 1 | - | generated |
| ui_error | alert | 2d | -13.7 | -9.7 | -4.0 | 0.0 | -6.0 | 0.30 | 0 / 20 | 80/20/0/0 | 0 | 1 | - | generated |
| ui_helper_call | ui | 2d | -18.4 | -12.4 | -6.0 | 0.0 | -5.7 | 0.60 | 0 / 50 | 9/82/9/1 | 0 | 1 | - | generated |
| ui_hint | ui | 2d | -22.4 | -14.4 | -8.0 | 0.0 | -6.8 | 0.45 | 0 / 4 | 0/89/11/1 | 0 | 1 | - | generated |
| ui_plus_start | ui | 2d | -23.0 | -17.0 | -6.0 | 0.0 | -6.9 | 0.34 | 0 / 21 | 0/96/2/2 | 0 | 1 | - | generated |
| ui_restart | ui | 2d | -21.4 | -13.4 | -8.0 | 0.0 | -6.6 | 0.50 | 0 / 4 | 0/93/6/2 | 0 | 1 | - | generated |
| ui_tab | ui | 2d | -28.1 | -24.1 | -4.0 | 0.0 | -7.9 | 0.07 | 0 / 30 | 0/90/9/1 | 0 | 3 | - | generated |
| ui_tab_1 | ui | 2d | -28.5 | -24.5 | -4.0 | 0.0 | -8.3 | 0.08 | 0 / 35 | 0/94/5/1 | 0 | 3 | - | file |
| ui_tab_2 | ui | 2d | -27.8 | -23.8 | -4.0 | 0.0 | -7.6 | 0.06 | 0 / 27 | 0/83/17/0 | 0 | 3 | - | file |
| ui_tier_start | ui | 2d | -24.2 | -18.2 | -6.0 | 0.0 | -5.9 | 0.50 | 0 / 6 | 8/86/5/1 | 0 | 1 | - | generated |
| ui_tier_tick | ui | 2d | -28.8 | -24.8 | -4.0 | 0.0 | -7.7 | 0.16 | 0 / 63 | 1/76/17/6 | 0 | 1 | - | generated |
| ui_upgrade_cancel | ui | 2d | -22.4 | -16.4 | -6.0 | 0.0 | -6.8 | 0.32 | 0 / 2 | 0/81/18/1 | 0 | 1 | - | generated |
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

115 / 189 files are generated placeholders (sine / noise tones from a generator script). The numbers above judge the level, timing and routing they give the mix; a real sound must keep those and add:

- **unit**: 44.1/48 kHz mono WAV, 3-5 takes per frequent cue (<id>_1.wav ... or an AudioStreamRandomizer .tres), 80-600 ms, transient in the first 5 ms, tail <= 400 ms for hits, peak <= -1 dBTP; recorded / layered foley, not synth.
- **spell**: 44.1/48 kHz mono WAV, one cast + one impact per spell, 0.3-2 s, a faction signature (fire = crackle / roar, shadow = breathy whoosh / reverse swell, ice = crystalline, nature = wood / leaves), tail matched to the VFX.
- **alert**: 44.1/48 kHz mono (stereo only for 2D stingers), 0.3-3 s, strong 1-5 kHz content so it cuts through the fight, a distinct pitch contour per meaning (rising = good, falling = danger), peak <= -1 dBTP.
- **ui**: 44.1/48 kHz mono, 16-bit WAV, 40-250 ms, peak <= -1 dBTP, cue loudness about -20 LUFS before volume_db, energy in 1-6 kHz, no lead silence (< 5 ms), one family feel for every UI cue.
- Every file: original or CC0 only (note the source in the file's folder), 16-bit WAV for SFX / Ogg for music, no clipping, trimmed start, faded end.

## Limits

- Loudness is a BS.1770 approximation on the 44.1 kHz decode (dual mono counted as 2 channels, as the game plays it); true peak is a 4x interpolation estimate.
- Masking uses 4 bands and a synthetic battle bed (6 unit cues at once), not a real mix; listen in the preview.
- Code facts come from patterns (DIR / DICT / PATH consts, `*.new()` players) and, for scene=, the live players; a sound played in an unusual way can be missed.
- Numbers can't judge taste, timbre or meaning: fill the listening sheet.
