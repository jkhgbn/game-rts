# Audio Lab scorecard: music

- Date: 2026-09-26 22:10:00
- Command: `godot --headless --path . -s tools/audio_lab/audio_lab.gd -- set=res://assets/audio/music kind=music name=music`
- set: `res://assets/audio/music`, kind `music`, 2 cues, 3 players judged
- Missing cues are listed for context but not scored (set is not the whole game; use scene= or set=res://assets/audio).

## Score: 96 / 100

PASS 39 | WARN 4 | FAIL 0 | INFO 0

| Group | Weight | PASS | WARN | FAIL | INFO | Group score |
|---|---|---|---|---|---|---|
| Loudness (in game) | 18 | 2 | 0 | 0 | 0 | 100 % |
| Peaks and clipping | 10 | 2 | 0 | 0 | 0 | 100 % |
| Duration, silence, tails | 8 | 2 | 4 | 0 | 0 | 67 % |
| Memory and disk | 5 | 3 | 0 | 0 | 0 | 100 % |
| Bus routing | 12 | 3 | 0 | 0 | 0 | 100 % |
| 3D attenuation | 5 | 1 | 0 | 0 | 0 | 100 % |
| Voice limits | 7 | 1 | 0 | 0 | 0 | 100 % |
| Missing cues | 15 | 25 | 1 | 2 | 14 | not scored |

## Improve next

1. **WARN Duration, silence, tails** - Longer track / more tracks: a short loop repeats dozens of times in a match.  _(music_match, music_menu; music loop >= 60 s)_
2. **WARN Duration, silence, tails** - Cut the loop on a zero crossing / crossfade the loop point (click every loop).  _(music_match, music_menu; |last - first sample| <= 0.05)_
3. **Replace placeholders** - 2 of 2 files are generated tones (see "What a real replacement needs"); start with the most played cues (combat hits, shots, deaths) and the alerts.

## Checks

### Loudness (in game)

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | music_match | -22.3 LUFS in game (file -12.3, vol -10.0 dB, 3D 0.0 dB) | music: -26..-18 integrated |  |
| PASS | music_menu | -23.1 LUFS in game (file -13.1, vol -10.0 dB, 3D 0.0 dB) | music: -26..-18 integrated |  |

### Peaks and clipping

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | music_match | true peak -4.4 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |
| PASS | music_menu | true peak -4.4 dBTP, 0 clipped runs | true peak <= -1 dBTP, no clipping |  |

### Duration, silence, tails

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| WARN | music_match | 48.0 s loop | music loop >= 60 s | Longer track / more tracks: a short loop repeats dozens of times in a match. |
| WARN | music_match | loop seam jump 0.265 | \|last - first sample\| <= 0.05 | Cut the loop on a zero crossing / crossfade the loop point (click every loop). |
| WARN | music_menu | 40.0 s loop | music loop >= 60 s | Longer track / more tracks: a short loop repeats dozens of times in a match. |
| WARN | music_menu | loop seam jump 0.310 | \|last - first sample\| <= 0.05 | Cut the loop on a zero crossing / crossfade the loop point (click every loop). |
| PASS | music_match | lead silence 0 ms | lead <= 500 ms |  |
| PASS | music_menu | lead silence 0 ms | lead <= 500 ms |  |

### Memory and disk

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | music_match | 2067 KB on disk, QOA 22050 Hz mono | file <= 15625 KB |  |
| PASS | music_menu | 1723 KB on disk, QOA 22050 Hz mono | file <= 15625 KB |  |
| PASS | set | 0.8 MB in memory | set <= 48 MB |  |

### Bus routing

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | res://scripts/audio/game_audio.gd:478 | AudioStreamPlayer3D on bus SFX | bus in Music, SFX |  |
| PASS | res://scripts/audio/game_audio.gd:489 | AudioStreamPlayer on bus SFX | bus in Music, SFX |  |
| PASS | res://scripts/audio/game_audio.gd:493 | AudioStreamPlayer on bus Music | bus in Music, SFX |  |

### 3D attenuation

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | res://scripts/audio/game_audio.gd:478 | unit_size 18, max_distance 75, inverse_distance; -4.4 dB @30 m, -9.7 dB @55 m, -12.4 dB @cut | gain >= -15 dB at 30 m, <= -10 dB at the cut-off |  |

### Voice limits

| Status | Item | Measured | Rule | Fix hint |
|---|---|---|---|---|
| PASS | players | 3 players (1 3D) (from code) | <= 64 players, 3D pool <= 32 |  |

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
| music_match | music | 2d | -22.3 | -12.3 | -10.0 | 0.0 | -4.4 | 48.00 | 0 / 0 | 79/21/0/0 | 0 | 1 | - | generated |
| music_menu | music | 2d | -23.1 | -13.1 | -10.0 | 0.0 | -4.4 | 40.00 | 0 / 0 | 70/30/0/0 | 0 | 1 | - | generated |

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

2 / 2 files are generated placeholders (sine / noise tones from a generator script). The numbers above judge the level, timing and routing they give the mix; a real sound must keep those and add:

- **music**: Stereo Ogg Vorbis (q 5-6) 2-4 min per track with clean loop points or intro + loop, integrated about -12 LUFS in the file (the game plays it at MUSIC_DB -10: -22 in game), several tracks per state (menu / build-up / battle).
- Every file: original or CC0 only (note the source in the file's folder), 16-bit WAV for SFX / Ogg for music, no clipping, trimmed start, faded end.

## Limits

- Loudness is a BS.1770 approximation on the 44.1 kHz decode (dual mono counted as 2 channels, as the game plays it); true peak is a 4x interpolation estimate.
- Masking uses 4 bands and a synthetic battle bed (6 unit cues at once), not a real mix; listen in the preview.
- Code facts come from patterns (DIR / DICT / PATH consts, `*.new()` players) and, for scene=, the live players; a sound played in an unusual way can be missed.
- Numbers can't judge taste, timbre or meaning: fill the listening sheet.
