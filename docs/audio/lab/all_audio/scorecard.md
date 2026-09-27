# Audio Lab scorecard: all_audio

- Date: 2026-09-26 22:28:27
- Command: `godot --headless --path . -s tools/audio_lab/audio_lab.gd -- set=res://assets/audio name=all_audio`
- set: `res://assets/audio`, kind `auto`, 52 cues, 6 players judged

## Score: 98 / 100

PASS 452 | WARN 24 | FAIL 0 | INFO 14

| Group | Weight | PASS | WARN | FAIL | INFO | Group score |
|---|---|---|---|---|---|---|
| Loudness (in game) | 18 | 53 | 0 | 0 | 0 | 100 % |
| Peaks and clipping | 10 | 49 | 3 | 0 | 0 | 97 % |
| Duration, silence, tails | 8 | 152 | 5 | 0 | 0 | 98 % |
| Spectral balance and masking | 10 | 52 | 14 | 0 | 0 | 89 % |
| Memory and disk | 5 | 53 | 0 | 0 | 0 | 100 % |
| Bus routing | 12 | 6 | 0 | 0 | 0 | 100 % |
| Variation | 10 | 49 | 1 | 0 | 0 | 99 % |
| 3D attenuation | 5 | 2 | 0 | 0 | 0 | 100 % |
| Voice limits | 7 | 9 | 0 | 0 | 0 | 100 % |
| Missing cues | 15 | 27 | 1 | 0 | 14 | 98 % |

## Improve next

1. **WARN Spectral balance and masking** - Add 1-4 kHz content (attack, harmonics): all-bass cues vanish on laptop speakers and mud the mix.  _(mapfill_drum, mapfill_horn, mapfill_roar, building_collapse, building_hit, spell_umbral_shroud; not all-bass (< 85% low), not all-hiss (< 60% air))_
2. **WARN Spectral balance and masking** - Give it energy where the fight is thin (2-5 kHz presence), or +5 dB; a distinct pitch contour helps.  _(mapfill_chime, mapfill_drum, mapfill_roar, construction_done, unit_trained; alert >= +3 dB over 6 combat voices in one band)_
3. **WARN Spectral balance and masking** - Add 2-5 kHz content so the UI cue reads on small speakers.  _(mapfill_bubble, item_used, ui_click; not all-bass (< 85% low), not all-hiss (< 60% air))_
4. **WARN Peaks and clipping** - Normalise the file to -1 dBTP (peak), lower the level before export if it clips.  _(building_collapse, fireball_explode, spell_ember_step; true peak <= -1 dBTP, no clipping)_
5. **WARN Missing cues** - Needs a design (game-designer / ui-designer) + a cue.  _(Base / army under attack (off-screen alert) (core); every key event has a sound)_
6. **WARN Duration, silence, tails** - Longer track / more tracks: a short loop repeats dozens of times in a match.  _(music_match, music_menu; music loop >= 60 s)_
7. **WARN Duration, silence, tails** - Cut the loop on a zero crossing / crossfade the loop point (click every loop).  _(music_match, music_menu; |last - first sample| <= 0.05)_
8. **WARN Variation** - Add takes (<id>_1.wav, <id>_2.wav... or an AudioStreamRandomizer).  _(mapfill_splash; frequent cue: >= 3 takes, or 2 takes + pitch / volume randomisation)_
9. **Replace placeholders** - 52 of 52 files are generated tones (see "What a real replacement needs"); start with the most played cues (combat hits, shots, deaths) and the alerts.

## Checks

### Loudness (in game)

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | fireball_cast | -12.7 LUFS in game (file -8.2, vol 0.0 dB, 3D -4.4 dB) | spell: -22..-9 cue |  |
| PASS | fireball_explode | -14.1 LUFS in game (file -9.7, vol 0.0 dB, 3D -4.4 dB) | spell: -22..-9 cue |  |
| PASS | item_bought | -16.1 LUFS in game (file -12.1, vol -4.0 dB, 3D 0.0 dB) | ui: -30..-14 cue |  |
| PASS | item_pickup | -15.0 LUFS in game (file -15.0, vol 0.0 dB, 3D 0.0 dB) | ui: -30..-14 cue |  |
| PASS | item_used | -15.8 LUFS in game (file -9.8, vol -6.0 dB, 3D 0.0 dB) | ui: -30..-14 cue |  |
| PASS | level_up | -10.4 LUFS in game (file -10.4, vol 0.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | melee_hit | -26.5 LUFS in game (file -18.0, vol -4.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | melee_hit_1 | -19.1 LUFS in game (file -19.1, vol - dB, 3D 0.0 dB) | unit: -30..-16 cue |  |
| PASS | melee_hit_2 | -19.0 LUFS in game (file -19.0, vol - dB, 3D 0.0 dB) | unit: -30..-16 cue |  |
| PASS | mine_tick | -34.9 LUFS in game (file -22.4, vol -8.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | mine_tick_1 | -22.1 LUFS in game (file -22.1, vol - dB, 3D 0.0 dB) | unit: -30..-16 cue |  |
| PASS | mine_tick_2 | -22.2 LUFS in game (file -22.2, vol - dB, 3D 0.0 dB) | unit: -30..-16 cue |  |
| PASS | skill_hit | -27.7 LUFS in game (file -17.3, vol -6.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | spell_ember_step | -11.3 LUFS in game (file -6.9, vol 0.0 dB, 3D -4.4 dB) | spell: -22..-9 cue |  |
| PASS | spell_kindle | -12.6 LUFS in game (file -8.1, vol 0.0 dB, 3D -4.4 dB) | spell: -22..-9 cue |  |
| PASS | spell_shadow_lance | -15.9 LUFS in game (file -11.5, vol 0.0 dB, 3D -4.4 dB) | spell: -22..-9 cue |  |
| PASS | spell_soul_siphon | -11.3 LUFS in game (file -6.8, vol 0.0 dB, 3D -4.4 dB) | spell: -22..-9 cue |  |
| PASS | spell_umbral_shroud | -12.0 LUFS in game (file -7.5, vol 0.0 dB, 3D -4.4 dB) | spell: -22..-9 cue |  |
| PASS | ui_click | -33.7 LUFS in game (file -25.7, vol -8.0 dB, 3D 0.0 dB) | ui (frequent): -36..-20 cue |  |
| PASS | ui_error | -13.7 LUFS in game (file -9.7, vol -4.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | unit_trained | -17.0 LUFS in game (file -8.6, vol -4.0 dB, 3D -4.4 dB) | alert: -22..-7 cue |  |
| PASS | victory | -8.7 LUFS in game (file -8.7, vol 0.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | trade_coin | -18.7 LUFS in game (file -12.7, vol -6.0 dB, 3D 0.0 dB) | ui: -30..-14 cue |  |
| PASS | trade_horn | -9.0 LUFS in game (file -9.0, vol 0.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | trade_whistle | -8.1 LUFS in game (file -8.1, vol 0.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | death_* | spread 1.4 dB (death_fire, death_shadow) | same-role cues within 3 dB |  |
| PASS | mapfill_bubble | -27.7 LUFS in game (file -15.7, vol -12.0 dB, 3D 0.0 dB) | ui: -30..-14 cue |  |
| PASS | mapfill_chime | -17.8 LUFS in game (file -11.8, vol -6.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | mapfill_drum | -20.3 LUFS in game (file -14.3, vol -6.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | mapfill_horn | -9.8 LUFS in game (file -9.8, vol 0.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | mapfill_roar | -20.1 LUFS in game (file -12.1, vol -8.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | mapfill_splash | -29.9 LUFS in game (file -7.5, vol -18.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | mapfill_stag | -9.5 LUFS in game (file -9.5, vol 0.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | music_match | -22.3 LUFS in game (file -12.3, vol -10.0 dB, 3D 0.0 dB) | music: -26..-18 integrated |  |
| PASS | music_menu | -23.1 LUFS in game (file -13.1, vol -10.0 dB, 3D 0.0 dB) | music: -26..-18 integrated |  |
| PASS | ability_cast | -23.4 LUFS in game (file -10.9, vol -8.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | alert_wizard_fell | -9.0 LUFS in game (file -9.0, vol 0.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | bolt_impact | -30.7 LUFS in game (file -19.3, vol -7.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | bolt_impact_1 | -19.2 LUFS in game (file -19.2, vol - dB, 3D 0.0 dB) | unit: -30..-16 cue |  |
| PASS | bolt_impact_2 | -19.8 LUFS in game (file -19.8, vol - dB, 3D 0.0 dB) | unit: -30..-16 cue |  |
| PASS | bolt_shot | -31.7 LUFS in game (file -19.2, vol -8.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | bolt_shot_1 | -19.2 LUFS in game (file -19.2, vol - dB, 3D 0.0 dB) | unit: -30..-16 cue |  |
| PASS | bolt_shot_2 | -19.4 LUFS in game (file -19.4, vol - dB, 3D 0.0 dB) | unit: -30..-16 cue |  |
| PASS | building_collapse | -12.9 LUFS in game (file -8.5, vol 0.0 dB, 3D -4.4 dB) | alert: -22..-7 cue |  |
| PASS | building_hit | -25.3 LUFS in game (file -15.8, vol -5.0 dB, 3D -4.4 dB) | unit (frequent): -36..-22 cue |  |
| PASS | building_hit_1 | -19.1 LUFS in game (file -19.1, vol - dB, 3D 0.0 dB) | unit: -30..-16 cue |  |
| PASS | building_hit_2 | -20.9 LUFS in game (file -20.9, vol - dB, 3D 0.0 dB) | unit: -30..-16 cue |  |
| PASS | construction_done | -14.5 LUFS in game (file -10.1, vol 0.0 dB, 3D -4.4 dB) | alert: -22..-7 cue |  |
| PASS | crown_claimed | -8.6 LUFS in game (file -8.6, vol 0.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |
| PASS | crystals_delivered | -21.8 LUFS in game (file -11.8, vol -10.0 dB, 3D 0.0 dB) | ui (frequent): -36..-20 cue |  |
| PASS | death_fire | -19.3 LUFS in game (file -11.9, vol -3.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | death_shadow | -17.9 LUFS in game (file -8.5, vol -5.0 dB, 3D -4.4 dB) | unit: -30..-16 cue |  |
| PASS | defeat | -7.6 LUFS in game (file -7.6, vol 0.0 dB, 3D 0.0 dB) | alert: -22..-7 cue |  |

### Peaks and clipping

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| WARN | fireball_explode | true peak -0.3 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping | Normalise the file to -1 dBTP (peak), lower the level before export if it clips. |
| WARN | building_collapse | true peak -0.5 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping | Normalise the file to -1 dBTP (peak), lower the level before export if it clips. |
| WARN | spell_ember_step | true peak -0.7 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping | Normalise the file to -1 dBTP (peak), lower the level before export if it clips. |
| PASS | fireball_cast | true peak -1.3 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | item_bought | true peak -4.2 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | item_pickup | true peak -4.4 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | item_used | true peak -4.4 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | level_up | true peak -1.8 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | melee_hit | true peak -1.8 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | melee_hit_1 | true peak -2.2 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | melee_hit_2 | true peak -2.3 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | mine_tick | true peak -6.5 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | mine_tick_1 | true peak -6.8 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | mine_tick_2 | true peak -6.7 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | skill_hit | true peak -1.9 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | spell_kindle | true peak -1.4 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | spell_shadow_lance | true peak -1.0 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | spell_soul_siphon | true peak -2.0 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | spell_umbral_shroud | true peak -1.8 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | ui_click | true peak -8.2 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | ui_error | true peak -6.0 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | unit_trained | true peak -4.5 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | victory | true peak -1.3 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | trade_coin | true peak -5.1 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | trade_horn | true peak -3.1 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | trade_whistle | true peak -4.4 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | mapfill_bubble | true peak -6.9 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | mapfill_chime | true peak -4.5 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | mapfill_drum | true peak -3.2 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | mapfill_horn | true peak -4.4 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | mapfill_roar | true peak -5.2 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | mapfill_splash | true peak -2.2 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | mapfill_stag | true peak -4.4 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | music_match | true peak -4.4 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | music_menu | true peak -4.4 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | ability_cast | true peak -3.4 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | alert_wizard_fell | true peak -2.5 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | bolt_impact | true peak -2.4 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | bolt_impact_1 | true peak -2.4 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | bolt_impact_2 | true peak -2.8 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | bolt_shot | true peak -3.9 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | bolt_shot_1 | true peak -2.8 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | bolt_shot_2 | true peak -3.7 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | building_hit | true peak -1.7 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | building_hit_1 | true peak -3.7 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | building_hit_2 | true peak -6.0 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | construction_done | true peak -2.3 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | crown_claimed | true peak -1.7 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | crystals_delivered | true peak -5.4 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | death_fire | true peak -2.2 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | death_shadow | true peak -2.0 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | defeat | true peak -1.9 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |

### Duration, silence, tails

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| WARN | music_match | 48.0 s loop | music loop >= 60 s | Longer track / more tracks: a short loop repeats dozens of times in a match. |
| WARN | music_match | loop seam jump 0.265 | \|last - first sample\| <= 0.05 | Cut the loop on a zero crossing / crossfade the loop point (click every loop). |
| WARN | music_menu | 40.0 s loop | music loop >= 60 s | Longer track / more tracks: a short loop repeats dozens of times in a match. |
| WARN | music_menu | loop seam jump 0.310 | \|last - first sample\| <= 0.05 | Cut the loop on a zero crossing / crossfade the loop point (click every loop). |
| WARN | defeat | ends at -25.3 dB RMS (last sample 0.099) | fade to silence (last 10 ms < -45 dB) | Add a 5-20 ms fade-out at the end (click). |
| PASS | skill_hit | lead silence 0 ms | lead <= 15 ms |  |
| PASS | melee_hit_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | mine_tick_2 | 0.09 s | unit: 0.03..1.5 s |  |
| PASS | mine_tick_2 | trailing silence 53 ms | trail <= 150 ms |  |
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
| PASS | fireball_cast | lead silence 0 ms | lead <= 20 ms |  |
| PASS | fireball_cast | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | fireball_cast | 0.55 s | spell: 0.03..2.5 s |  |
| PASS | fireball_explode | lead silence 0 ms | lead <= 20 ms |  |
| PASS | fireball_explode | trailing silence 55 ms | trail <= 150 ms |  |
| PASS | fireball_explode | 1.10 s | spell: 0.03..2.5 s |  |
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
| PASS | melee_hit | trailing silence 75 ms | trail <= 150 ms |  |
| PASS | melee_hit | 0.20 s | unit: 0.03..1.5 s |  |
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
| PASS | trade_coin | lead silence 0 ms | lead <= 10 ms |  |
| PASS | trade_coin | trailing silence 1 ms | trail <= 150 ms |  |
| PASS | trade_coin | 0.25 s | ui: 0.03..0.8 s |  |
| PASS | trade_horn | lead silence 1 ms | lead <= 15 ms |  |
| PASS | trade_horn | trailing silence 20 ms | trail <= 150 ms |  |
| PASS | trade_horn | 0.80 s | alert: 0.03..3.5 s |  |
| PASS | trade_whistle | lead silence 0 ms | lead <= 15 ms |  |
| PASS | trade_whistle | trailing silence 10 ms | trail <= 150 ms |  |
| PASS | trade_whistle | 0.50 s | alert: 0.03..3.5 s |  |
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
| PASS | spell_soul_siphon | lead silence 1 ms | lead <= 20 ms |  |
| PASS | spell_soul_siphon | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | spell_soul_siphon | 1.10 s | spell: 0.03..2.5 s |  |
| PASS | spell_umbral_shroud | lead silence 1 ms | lead <= 20 ms |  |
| PASS | spell_umbral_shroud | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | spell_umbral_shroud | 0.90 s | spell: 0.03..2.5 s |  |
| PASS | ui_click | lead silence 0 ms | lead <= 10 ms |  |
| PASS | ui_click | trailing silence 31 ms | trail <= 150 ms |  |
| PASS | mapfill_stag | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | mapfill_stag | 1.00 s | alert: 0.03..3.5 s |  |
| PASS | music_match | lead silence 0 ms | lead <= 500 ms |  |
| PASS | music_menu | lead silence 0 ms | lead <= 500 ms |  |
| PASS | ability_cast | lead silence 1 ms | lead <= 15 ms |  |
| PASS | ability_cast | trailing silence 3 ms | trail <= 150 ms |  |
| PASS | ability_cast | 0.45 s | unit: 0.03..1.5 s |  |
| PASS | alert_wizard_fell | lead silence 0 ms | lead <= 15 ms |  |
| PASS | alert_wizard_fell | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | alert_wizard_fell | 1.40 s | alert: 0.03..3.5 s |  |
| PASS | bolt_impact | lead silence 0 ms | lead <= 15 ms |  |
| PASS | bolt_impact | trailing silence 46 ms | trail <= 150 ms |  |
| PASS | bolt_impact | 0.14 s | unit: 0.03..1.5 s |  |
| PASS | bolt_impact_1 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | bolt_impact_1 | trailing silence 53 ms | trail <= 150 ms |  |
| PASS | bolt_impact_1 | 0.15 s | unit: 0.03..1.5 s |  |
| PASS | bolt_impact_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | bolt_impact_2 | trailing silence 43 ms | trail <= 150 ms |  |
| PASS | bolt_impact_2 | 0.13 s | unit: 0.03..1.5 s |  |
| PASS | mapfill_bubble | lead silence 0 ms | lead <= 10 ms |  |
| PASS | mapfill_bubble | trailing silence 50 ms | trail <= 150 ms |  |
| PASS | mapfill_bubble | 0.30 s | ui: 0.03..0.8 s |  |
| PASS | mapfill_chime | lead silence 0 ms | lead <= 15 ms |  |
| PASS | mapfill_chime | trailing silence 1 ms | trail <= 150 ms |  |
| PASS | mapfill_chime | 0.40 s | alert: 0.03..3.5 s |  |
| PASS | mapfill_drum | lead silence 0 ms | lead <= 15 ms |  |
| PASS | mapfill_drum | trailing silence 84 ms | trail <= 150 ms |  |
| PASS | mapfill_drum | 0.60 s | alert: 0.03..3.5 s |  |
| PASS | mapfill_horn | lead silence 1 ms | lead <= 15 ms |  |
| PASS | mapfill_horn | trailing silence 30 ms | trail <= 150 ms |  |
| PASS | mapfill_horn | 1.20 s | alert: 0.03..3.5 s |  |
| PASS | mapfill_roar | lead silence 2 ms | lead <= 15 ms |  |
| PASS | mapfill_roar | trailing silence 48 ms | trail <= 150 ms |  |
| PASS | mapfill_roar | 1.50 s | alert: 0.03..3.5 s |  |
| PASS | mapfill_splash | lead silence 0 ms | lead <= 15 ms |  |
| PASS | mapfill_splash | trailing silence 40 ms | trail <= 150 ms |  |
| PASS | mapfill_splash | 0.30 s | unit: 0.03..1.5 s |  |
| PASS | mapfill_stag | lead silence 1 ms | lead <= 15 ms |  |
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
| PASS | death_fire | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_fire | trailing silence 101 ms | trail <= 150 ms |  |
| PASS | death_fire | 0.65 s | unit: 0.03..1.5 s |  |
| PASS | death_shadow | lead silence 0 ms | lead <= 15 ms |  |
| PASS | death_shadow | trailing silence 51 ms | trail <= 150 ms |  |
| PASS | death_shadow | 0.80 s | unit: 0.03..1.5 s |  |
| PASS | defeat | lead silence 0 ms | lead <= 15 ms |  |
| PASS | defeat | trailing silence 0 ms | trail <= 150 ms |  |
| PASS | defeat | 2.80 s | alert: 0.03..3.5 s |  |
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
| PASS | building_hit_2 | lead silence 0 ms | lead <= 15 ms |  |
| PASS | building_hit_2 | trailing silence 70 ms | trail <= 150 ms |  |

### Spectral balance and masking

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| WARN | item_used | low 0% / mid 99% / pres 0% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) | Add 2-5 kHz content so the UI cue reads on small speakers. |
| WARN | construction_done | beats the battle bed by 1.8 dB (mid band) | alert >= +3 dB over 6 combat voices in one band | Give it energy where the fight is thin (2-5 kHz presence), or +1 dB; a distinct pitch contour helps. |
| WARN | building_hit | low 93% / mid 5% / pres 1% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) | Add 1-4 kHz content (attack, harmonics): all-bass cues vanish on laptop speakers and mud the mix. |
| WARN | building_collapse | low 93% / mid 6% / pres 1% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) | Add 1-4 kHz content (attack, harmonics): all-bass cues vanish on laptop speakers and mud the mix. |
| WARN | spell_umbral_shroud | low 98% / mid 2% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) | Add 1-4 kHz content (attack, harmonics): all-bass cues vanish on laptop speakers and mud the mix. |
| WARN | ui_click | low 0% / mid 98% / pres 2% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) | Add 2-5 kHz content so the UI cue reads on small speakers. |
| WARN | unit_trained | beats the battle bed by -1.4 dB (low band) | alert >= +3 dB over 6 combat voices in one band | Give it energy where the fight is thin (2-5 kHz presence), or +4 dB; a distinct pitch contour helps. |
| WARN | mapfill_roar | beats the battle bed by -1.6 dB (low band) | alert >= +3 dB over 6 combat voices in one band | Give it energy where the fight is thin (2-5 kHz presence), or +5 dB; a distinct pitch contour helps. |
| WARN | mapfill_bubble | low 1% / mid 99% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) | Add 2-5 kHz content so the UI cue reads on small speakers. |
| WARN | mapfill_chime | beats the battle bed by -2.1 dB (mid band) | alert >= +3 dB over 6 combat voices in one band | Give it energy where the fight is thin (2-5 kHz presence), or +5 dB; a distinct pitch contour helps. |
| WARN | mapfill_drum | low 99% / mid 1% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) | Add 1-4 kHz content (attack, harmonics): all-bass cues vanish on laptop speakers and mud the mix. |
| WARN | mapfill_drum | beats the battle bed by -1.8 dB (low band) | alert >= +3 dB over 6 combat voices in one band | Give it energy where the fight is thin (2-5 kHz presence), or +5 dB; a distinct pitch contour helps. |
| WARN | mapfill_horn | low 91% / mid 9% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) | Add 1-4 kHz content (attack, harmonics): all-bass cues vanish on laptop speakers and mud the mix. |
| WARN | mapfill_roar | low 98% / mid 2% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) | Add 1-4 kHz content (attack, harmonics): all-bass cues vanish on laptop speakers and mud the mix. |
| PASS | item_pickup | low 0% / mid 95% / pres 4% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | level_up | low 3% / mid 95% / pres 2% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | level_up | beats the battle bed by 6.0 dB (mid band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | melee_hit | low 74% / mid 17% / pres 7% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | melee_hit_1 | low 69% / mid 20% / pres 10% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | melee_hit_2 | low 78% / mid 17% / pres 5% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | mine_tick | low 0% / mid 16% / pres 83% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | mine_tick_1 | low 0% / mid 27% / pres 72% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | mine_tick_2 | low 0% / mid 10% / pres 89% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | trade_whistle | beats the battle bed by 8.2 dB (mid band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | skill_hit | low 70% / mid 21% / pres 7% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | spell_ember_step | low 4% / mid 77% / pres 9% / air 11% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | spell_kindle | low 5% / mid 94% / pres 1% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | trade_horn | beats the battle bed by 8.9 dB (low band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | spell_shadow_lance | low 1% / mid 94% / pres 5% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | trade_horn | low 84% / mid 16% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | spell_soul_siphon | low 76% / mid 24% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | trade_coin | low 0% / mid 6% / pres 90% / air 4% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | victory | beats the battle bed by 6.7 dB (mid band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | ui_error | low 80% / mid 20% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | ui_error | beats the battle bed by 4.0 dB (low band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | unit_trained | low 50% / mid 50% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | trade_whistle | low 0% / mid 95% / pres 5% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | victory | low 22% / mid 77% / pres 1% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | mapfill_chime | low 0% / mid 81% / pres 18% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | mapfill_horn | beats the battle bed by 8.4 dB (low band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | mapfill_splash | low 9% / mid 50% / pres 26% / air 15% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | mapfill_stag | low 77% / mid 23% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | mapfill_stag | beats the battle bed by 8.0 dB (low band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | ability_cast | low 0% / mid 87% / pres 8% / air 4% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | alert_wizard_fell | low 59% / mid 41% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | alert_wizard_fell | beats the battle bed by 7.3 dB (low band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | bolt_impact | low 16% / mid 69% / pres 11% / air 4% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | bolt_impact_1 | low 20% / mid 63% / pres 13% / air 3% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | bolt_impact_2 | low 12% / mid 79% / pres 7% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | bolt_shot | low 0% / mid 61% / pres 16% / air 23% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | bolt_shot_1 | low 0% / mid 80% / pres 11% / air 8% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | bolt_shot_2 | low 0% / mid 63% / pres 18% / air 18% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | building_collapse | beats the battle bed by 5.4 dB (low band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | building_hit_1 | low 81% / mid 12% / pres 5% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | building_hit_2 | low 71% / mid 16% / pres 10% / air 3% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | construction_done | low 3% / mid 95% / pres 2% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | crown_claimed | low 1% / mid 95% / pres 4% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | crown_claimed | beats the battle bed by 7.7 dB (mid band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | crystals_delivered | low 0% / mid 58% / pres 40% / air 2% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_fire | low 8% / mid 84% / pres 3% / air 5% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | death_shadow | low 8% / mid 92% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | defeat | low 49% / mid 51% / pres 0% / air 0% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | defeat | beats the battle bed by 7.9 dB (low band) | alert >= +3 dB over 6 combat voices in one band |  |
| PASS | fireball_cast | low 46% / mid 50% / pres 3% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | fireball_explode | low 80% / mid 15% / pres 4% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |
| PASS | item_bought | low 0% / mid 64% / pres 34% / air 1% | not all-bass (< 85% low), not all-hiss (< 60% air) |  |

### Memory and disk

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | fireball_cast | 24 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | fireball_explode | 47 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
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
| PASS | spell_ember_step | 19 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | spell_kindle | 34 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | spell_shadow_lance | 22 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | spell_soul_siphon | 47 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | spell_umbral_shroud | 39 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ui_click | 3 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | ui_error | 13 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | unit_trained | 19 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | victory | 121 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | trade_coin | 11 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | trade_horn | 34 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | trade_whistle | 22 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | set | 1.1 MB in memory | set <= 48 MB |  |
| PASS | mapfill_bubble | 13 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | mapfill_chime | 17 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | mapfill_drum | 26 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | mapfill_horn | 52 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | mapfill_roar | 65 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | mapfill_splash | 13 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | mapfill_stag | 43 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | music_match | 2067 KB on disk, QOA 22050 Hz mono | file <= 15625 KB |  |
| PASS | music_menu | 1723 KB on disk, QOA 22050 Hz mono | file <= 15625 KB |  |
| PASS | ability_cast | 19 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | alert_wizard_fell | 60 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | bolt_impact | 6 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | bolt_impact_1 | 6 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | bolt_impact_2 | 6 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
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
| PASS | death_fire | 28 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | death_shadow | 34 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |
| PASS | defeat | 121 KB on disk, QOA 22050 Hz mono | file <= 977 KB |  |

### Bus routing

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | res://scripts/audio/game_audio.gd:556 | AudioStreamPlayer3D on bus SFX | bus in Music, SFX |  |
| PASS | res://scripts/audio/game_audio.gd:567 | AudioStreamPlayer on bus SFX | bus in Music, SFX |  |
| PASS | res://scripts/audio/game_audio.gd:571 | AudioStreamPlayer on bus Music | bus in Music, SFX |  |
| PASS | res://scripts/vfx/mapfill_popups.gd:136 | AudioStreamPlayer on bus SFX | bus in Music, SFX |  |
| PASS | res://scripts/vfx/mapfill_popups.gd:146 | AudioStreamPlayer3D on bus SFX | bus in Music, SFX |  |
| PASS | res://scripts/vfx/trade_popups.gd:95 | AudioStreamPlayer on bus SFX | bus in Music, SFX |  |

### Variation

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| WARN | mapfill_splash | 1 take(s), pitch +-6%, ~20/min | frequent cue: >= 3 takes, or 2 takes + pitch / volume randomisation | Add takes (<id>_1.wav, <id>_2.wav... or an AudioStreamRandomizer). |
| PASS | fireball_explode | 1 take(s), pitch +-7%, ~6/min | occasional cue (< 20/min): one take is fine |  |
| PASS | item_bought | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | item_pickup | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | item_used | 1 take(s), pitch +-0%, ~3/min | occasional cue (< 20/min): one take is fine |  |
| PASS | level_up | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | melee_hit | 3 take(s), pitch +-7%, ~120/min | frequent cue: >= 3 takes, or 2 takes + pitch / volume randomisation |  |
| PASS | melee_hit_1 | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | melee_hit_2 | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | mine_tick | 3 take(s), pitch +-7%, ~60/min | frequent cue: >= 3 takes, or 2 takes + pitch / volume randomisation |  |
| PASS | mine_tick_1 | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | mine_tick_2 | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
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
| PASS | trade_coin | 1 take(s), pitch +-0%, ~3/min | occasional cue (< 20/min): one take is fine |  |
| PASS | trade_horn | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | trade_whistle | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | mapfill_bubble | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | mapfill_chime | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | mapfill_drum | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | mapfill_horn | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | mapfill_roar | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | mapfill_stag | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | ability_cast | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | alert_wizard_fell | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | bolt_impact | 3 take(s), pitch +-7%, ~120/min | frequent cue: >= 3 takes, or 2 takes + pitch / volume randomisation |  |
| PASS | bolt_impact_1 | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | bolt_impact_2 | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | bolt_shot | 3 take(s), pitch +-7%, ~120/min | frequent cue: >= 3 takes, or 2 takes + pitch / volume randomisation |  |
| PASS | bolt_shot_1 | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | bolt_shot_2 | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | building_collapse | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | building_hit | 3 take(s), pitch +-7%, ~40/min | frequent cue: >= 3 takes, or 2 takes + pitch / volume randomisation |  |
| PASS | building_hit_1 | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | building_hit_2 | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | construction_done | 1 take(s), pitch +-7%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | crown_claimed | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | crystals_delivered | 1 take(s), pitch +-0%, ~20/min | UI cues stay identical on purpose (consistency) |  |
| PASS | death_fire | 1 take(s), pitch +-7%, ~12/min | occasional cue (< 20/min): one take is fine |  |
| PASS | death_shadow | 1 take(s), pitch +-7%, ~12/min | occasional cue (< 20/min): one take is fine |  |
| PASS | defeat | 1 take(s), pitch +-0%, ~0/min | occasional cue (< 20/min): one take is fine |  |
| PASS | fireball_cast | 1 take(s), pitch +-7%, ~6/min | occasional cue (< 20/min): one take is fine |  |

### 3D attenuation

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | res://scripts/audio/game_audio.gd:556 | unit_size 18, max_distance 75, inverse_distance; -4.4 dB @30 m, -9.7 dB @55 m, -12.4 dB @cut | gain >= -15 dB at 30 m, <= -10 dB at the cut-off |  |
| PASS | res://scripts/vfx/mapfill_popups.gd:146 | unit_size 18, max_distance 60, inverse_distance; -4.4 dB @30 m, -9.7 dB @55 m, -10.5 dB @cut | gain >= -15 dB at 30 m, <= -10 dB at the cut-off |  |

### Voice limits

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | players | 6 players (2 3D) (from code) | <= 64 players, 3D pool <= 32 |  |
| PASS | mapfill_splash | rate limit 4.0 s | frequent cue has a per-cue cooldown >= 0.03 s |  |
| PASS | bolt_impact | rate limit 0.1 s | frequent cue has a per-cue cooldown >= 0.03 s |  |
| PASS | bolt_shot | rate limit 0.1 s | frequent cue has a per-cue cooldown >= 0.03 s |  |
| PASS | building_hit | rate limit 0.2 s | frequent cue has a per-cue cooldown >= 0.03 s |  |
| PASS | crystals_delivered | rate limit 0.3 s | frequent cue has a per-cue cooldown >= 0.03 s |  |
| PASS | melee_hit | rate limit 0.1 s | frequent cue has a per-cue cooldown >= 0.03 s |  |
| PASS | mine_tick | rate limit 0.1 s | frequent cue has a per-cue cooldown >= 0.03 s |  |
| PASS | ui_click | rate limit 0.0 s | frequent cue has a per-cue cooldown >= 0.03 s |  |

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
| mapfill_bubble | ui | 2d | -27.7 | -15.7 | -12.0 | 0.0 | -6.9 | 0.30 | 0 / 50 | 1/99/0/0 | 0 | 1 | - | generated |
| mapfill_chime | alert | 2d | -17.8 | -11.8 | -6.0 | 0.0 | -4.5 | 0.40 | 0 / 1 | 0/81/18/1 | 0 | 1 | - | generated |
| mapfill_drum | alert | 2d | -20.3 | -14.3 | -6.0 | 0.0 | -3.2 | 0.60 | 0 / 84 | 99/1/0/0 | 0 | 1 | - | generated |
| mapfill_horn | alert | 2d | -9.8 | -9.8 | 0.0 | 0.0 | -4.4 | 1.20 | 1 / 30 | 91/9/0/0 | 0 | 1 | - | generated |
| mapfill_roar | alert | 2d | -20.1 | -12.1 | -8.0 | 0.0 | -5.2 | 1.50 | 2 / 48 | 98/2/0/0 | 0 | 1 | - | generated |
| mapfill_splash | unit | 3d | -29.9 | -7.5 | -18.0 | -4.4 | -2.2 | 0.30 | 0 / 40 | 9/50/26/15 | 20* | 1 | +-6% | generated |
| mapfill_stag | alert | 2d | -9.5 | -9.5 | 0.0 | 0.0 | -4.4 | 1.00 | 1 / 50 | 77/23/0/0 | 0 | 1 | - | generated |
| music_match | music | 2d | -22.3 | -12.3 | -10.0 | 0.0 | -4.4 | 48.00 | 0 / 0 | 79/21/0/0 | 0 | 1 | - | generated |
| music_menu | music | 2d | -23.1 | -13.1 | -10.0 | 0.0 | -4.4 | 40.00 | 0 / 0 | 70/30/0/0 | 0 | 1 | - | generated |
| ability_cast | unit | 3d | -23.4 | -10.9 | -8.0 | -4.4 | -3.4 | 0.45 | 1 / 3 | 0/87/8/4 | 0 | 1 | +-7% | generated |
| alert_wizard_fell | alert | 2d | -9.0 | -9.0 | 0.0 | 0.0 | -2.5 | 1.40 | 0 / 50 | 59/41/0/0 | 0 | 1 | - | generated |
| bolt_impact | unit | 3d | -30.7 | -19.3 | -7.0 | -4.4 | -2.4 | 0.14 | 0 / 46 | 16/69/11/4 | 120* | 3 | +-7% | generated |
| bolt_impact_1 | unit | - | -19.2 | -19.2 | - | 0.0 | -2.4 | 0.15 | 0 / 53 | 20/63/13/3 | 0 | 1 | - | generated |
| bolt_impact_2 | unit | - | -19.8 | -19.8 | - | 0.0 | -2.8 | 0.13 | 0 / 43 | 12/79/7/2 | 0 | 1 | - | generated |
| bolt_shot | unit | 3d | -31.7 | -19.2 | -8.0 | -4.4 | -3.9 | 0.24 | 0 / 46 | 0/61/16/23 | 120* | 3 | +-7% | generated |
| bolt_shot_1 | unit | - | -19.2 | -19.2 | - | 0.0 | -2.8 | 0.25 | 0 / 50 | 0/80/11/8 | 0 | 1 | - | generated |
| bolt_shot_2 | unit | - | -19.4 | -19.4 | - | 0.0 | -3.7 | 0.23 | 0 / 43 | 0/63/18/18 | 0 | 1 | - | generated |
| building_collapse | alert | 3d | -12.9 | -8.5 | 0.0 | -4.4 | -0.5 | 1.80 | 0 / 50 | 93/6/1/0 | 0 | 1 | +-7% | generated |
| building_hit | unit | 3d | -25.3 | -15.8 | -5.0 | -4.4 | -1.7 | 0.30 | 0 / 53 | 93/5/1/0 | 40* | 3 | +-7% | generated |
| building_hit_1 | unit | - | -19.1 | -19.1 | - | 0.0 | -3.7 | 0.32 | 0 / 60 | 81/12/5/1 | 0 | 1 | - | generated |
| building_hit_2 | unit | - | -20.9 | -20.9 | - | 0.0 | -6.0 | 0.28 | 0 / 70 | 71/16/10/3 | 0 | 1 | - | generated |
| construction_done | alert | 3d | -14.5 | -10.1 | 0.0 | -4.4 | -2.3 | 0.75 | 0 / 1 | 3/95/2/0 | 0 | 1 | +-7% | generated |
| crown_claimed | alert | 2d | -8.6 | -8.6 | 0.0 | 0.0 | -1.7 | 1.40 | 0 / 100 | 1/95/4/0 | 0 | 1 | - | generated |
| crystals_delivered | ui | 2d | -21.8 | -11.8 | -10.0 | 0.0 | -5.4 | 0.40 | 0 / 12 | 0/58/40/2 | 20* | 1 | - | generated |
| death_fire | unit | 3d | -19.3 | -11.9 | -3.0 | -4.4 | -2.2 | 0.65 | 0 / 101 | 8/84/3/5 | 12 | 1 | +-7% | generated |
| death_shadow | unit | 3d | -17.9 | -8.5 | -5.0 | -4.4 | -2.0 | 0.80 | 0 / 51 | 8/92/0/0 | 12 | 1 | +-7% | generated |
| defeat | alert | 2d | -7.6 | -7.6 | 0.0 | 0.0 | -1.9 | 2.80 | 0 / 0 | 49/51/0/0 | 0 | 1 | - | generated |
| fireball_cast | spell | 3d | -12.7 | -8.2 | 0.0 | -4.4 | -1.3 | 0.55 | 0 / 50 | 46/50/3/1 | 6 | 1 | +-7% | generated |
| fireball_explode | spell | 3d | -14.1 | -9.7 | 0.0 | -4.4 | -0.3 | 1.10 | 0 / 55 | 80/15/4/1 | 6 | 1 | +-7% | generated |
| item_bought | ui | 2d | -16.1 | -12.1 | -4.0 | 0.0 | -4.2 | 0.32 | 0 / 1 | 0/64/34/1 | 0 | 1 | - | generated |
| item_pickup | ui | both | -15.0 | -15.0 | 0.0 | 0.0 | -4.4 | 0.26 | 0 / 2 | 0/95/4/0 | 0 | 1 | +-7% | generated |
| item_used | ui | 2d | -15.8 | -9.8 | -6.0 | 0.0 | -4.4 | 0.40 | 0 / 20 | 0/99/0/1 | 3 | 1 | - | generated |
| level_up | alert | both | -10.4 | -10.4 | 0.0 | 0.0 | -1.8 | 0.95 | 0 / 2 | 3/95/2/0 | 0 | 1 | +-7% | generated |
| melee_hit | unit | 3d | -26.5 | -18.0 | -4.0 | -4.4 | -1.8 | 0.20 | 0 / 75 | 74/17/7/2 | 120* | 3 | +-7% | generated |
| melee_hit_1 | unit | - | -19.1 | -19.1 | - | 0.0 | -2.2 | 0.21 | 0 / 80 | 69/20/10/2 | 0 | 1 | - | generated |
| melee_hit_2 | unit | - | -19.0 | -19.0 | - | 0.0 | -2.3 | 0.19 | 0 / 68 | 78/17/5/1 | 0 | 1 | - | generated |
| mine_tick | unit | 3d | -34.9 | -22.4 | -8.0 | -4.4 | -6.5 | 0.10 | 0 / 58 | 0/16/83/1 | 60* | 3 | +-7% | generated |
| mine_tick_1 | unit | - | -22.1 | -22.1 | - | 0.0 | -6.8 | 0.11 | 0 / 62 | 0/27/72/1 | 0 | 1 | - | generated |
| mine_tick_2 | unit | - | -22.2 | -22.2 | - | 0.0 | -6.7 | 0.09 | 0 / 53 | 0/10/89/1 | 0 | 1 | - | generated |
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
| trade_coin | ui | 2d | -18.7 | -12.7 | -6.0 | 0.0 | -5.1 | 0.25 | 0 / 1 | 0/6/90/4 | 3 | 1 | - | generated |
| trade_horn | alert | 2d | -9.0 | -9.0 | 0.0 | 0.0 | -3.1 | 0.80 | 1 / 20 | 84/16/0/0 | 0 | 1 | - | generated |
| trade_whistle | alert | 2d | -8.1 | -8.1 | 0.0 | 0.0 | -4.4 | 0.50 | 0 / 10 | 0/95/5/0 | 0 | 1 | - | generated |

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

52 / 52 files are generated placeholders (sine / noise tones from a generator script). The numbers above judge the level, timing and routing they give the mix; a real sound must keep those and add:

- **ui**: 44.1/48 kHz mono, 16-bit WAV, 40-250 ms, peak <= -1 dBTP, cue loudness about -20 LUFS before volume_db, energy in 1-6 kHz, no lead silence (< 5 ms), one family feel for every UI cue.
- **alert**: 44.1/48 kHz mono (stereo only for 2D stingers), 0.3-3 s, strong 1-5 kHz content so it cuts through the fight, a distinct pitch contour per meaning (rising = good, falling = danger), peak <= -1 dBTP.
- **unit**: 44.1/48 kHz mono WAV, 3-5 takes per frequent cue (<id>_1.wav ... or an AudioStreamRandomizer .tres), 80-600 ms, transient in the first 5 ms, tail <= 400 ms for hits, peak <= -1 dBTP; recorded / layered foley, not synth.
- **music**: Stereo Ogg Vorbis (q 5-6) 2-4 min per track with clean loop points or intro + loop, integrated about -12 LUFS in the file (the game plays it at MUSIC_DB -10: -22 in game), several tracks per state (menu / build-up / battle).
- **spell**: 44.1/48 kHz mono WAV, one cast + one impact per spell, 0.3-2 s, a faction signature (fire = crackle / roar, shadow = breathy whoosh / reverse swell, ice = crystalline, nature = wood / leaves), tail matched to the VFX.
- Every file: original or CC0 only (note the source in the file's folder), 16-bit WAV for SFX / Ogg for music, no clipping, trimmed start, faded end.

## Limits

- Loudness is a BS.1770 approximation on the 44.1 kHz decode (dual mono counted as 2 channels, as the game plays it); true peak is a 4x interpolation estimate.
- Masking uses 4 bands and a synthetic battle bed (6 unit cues at once), not a real mix; listen in the preview.
- Code facts come from patterns (DIR / DICT / PATH consts, `*.new()` players) and, for scene=, the live players; a sound played in an unusual way can be missed.
- Numbers can't judge taste, timbre or meaning: fill the listening sheet.
