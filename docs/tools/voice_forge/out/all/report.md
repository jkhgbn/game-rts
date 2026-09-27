# voice_forge check: all

2026-09-27 18:14:10 - `tools/voice_forge/run_voice_forge.ps1 check all` - hash `05e61876a2c40c7d` (manifest.json (line keys are content hashes))

## Result: **WARN** - quality **95 / 100** (previous run 98, -3)

0 FAIL, 2 WARN, 13 PASS, 1 info, 0 skipped, 5 s

## Improve next
1. **voice fits its slot** (WARN): the lines listed in the notes _(from F1 voice fits its slot)_
2. **Hold lines as long as their voice** (IDEA): DialogueBox shows every line 5 s; VoicePlayer.line_duration() lets it wait for the voice (handoff for ui-coder). _(from voice_forge)_
3. **Voice the cinematics** (IDEA): The cinematic runtime can play manifest WAVs for `line` cues (handoff for systems-coder-high). _(from voice_forge)_

## Data (cast, index, manifest)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| D1 | cast.json | PASS 100 | 58 speakers | parses, has speakers |  |
| D2 | lines found | PASS 100 | 284 unique lines | > 0 |  |
| D3 | manifest entries | PASS 100 | 284 entries, 0 bad  | text_hash = sha256(speaker\ntext)[:16], path under assets/audio/voice/<speaker>/, duration > 0 |  |
| D4 | speakers cast | PASS 100 | all cast | every speaker has a voice in cast.json |  |
| D5 | speakers vs Speakers.TABLE | INFO | aldra, dancer, messenger, reveler, unit_ash_hurler, unit_ashveil_saboteur, unit_barrow_ghoul, unit_blaze_rider, unit_bleakbow, unit_bloomtender, unit_bramblehorn, unit_burr_slinger, unit_cinder_arbalest, unit_cinder_hand, unit_ember_archer, unit_flame_guard, unit_frost_mortar, unit_frostbow, unit_gloom_thrall, unit_greenheart_oathkeeper, unit_hexweaver, unit_hoarlight_magebow, unit_hollow_oathsworn, unit_nightblood_reaver, unit_nightbolt, unit_pyre_adept, unit_rime_colossus, unit_rime_hauler, unit_rime_seer, unit_rimeling, unit_rimeshield, unit_scorchbow, unit_scorchling, unit_shadow_knight, unit_shardcaster, unit_shardguard, unit_sprigling, unit_stormbottle_genie, unit_thistle_darter, unit_thornling, unit_vinelasher, unit_wildwood_archer | subtitle names known |  |

## Coverage (every spoken line has audio)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| C1 | lines with audio | PASS 100 | 284 / 284 | every spoken line has a WAV |  |
| C2 | mission lines voiced | PASS 100 | 15 / 15 | all mission dialogue voiced |  |
| C3 | imported | PASS 100 | 0 not importable | load(path) is AudioStream |  |
| C4 | orphan WAVs | PASS 100 | 0 | no manifest line without a source |  |

## Fit (voice length vs cine slot / subtitle time)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| F1 | voice fits its slot | **WARN** 68 | 5 / 166 over (0 by > 15 %) | voice length <= cine slot / subtitle time | run_voice_forge.ps1 build fit=all (speeds the overrunning lines up, <= x1.25), lengthen the slot, or shorten the line |

## Audio (format, clipping, trim, size)
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| A1 | format | PASS 100 | 0 bad  | mono, 24 kHz, PCM 16-bit |  |
| A2 | clipping | PASS 100 | none | no sample at full scale |  |
| A3 | peak level | PASS 100 | -1.0..-1.0 dBFS | -2..-0.5 dBFS (target -1) |  |
| A4 | trimmed | **WARN** 50 | 1 untrimmed unit_rime_hauler/right_ill_have_a_92efb9f7 (0.05 / 0.32 s) | lead <= 0.12 s, tail <= 0.20 s of silence | re-render |
| A5 | size | PASS 89 | 28.6 MB source WAV, 10.4 min of speech | <= 40 MB |  |

## Game hookup
| # | Check | Result | Measured | Rule | Fix hint |
|---|---|---|---|---|---|
| H1 | VoicePlayer in the mission HUD | PASS 100 | script present, added by MissionHud | DialogueBox child plays the manifest WAV on line_started |  |

## Notes
- source: docs/design/episode3-4-opening.md ### 3.1 -> data/voice/lines/ep3_opening.json: 15 lines
- source: docs/design/episode3-4-opening.md ### 3.2 -> data/voice/lines/ep4_opening.json: 15 lines
- source: scripts/campaign/mission_01.gd: 15 lines
- source: data/cinematics/src/ep2_opening.cine: 28 lines
- source: data/cinematics/src/prologue_3min.cine: 30 lines
- source: data/cinematics/src/two_wizards.cine: 1 lines
- source: data/cinematics/src/watch_keep.cine: 4 lines
- source: data/cinematics/src/watch_keep_bugs.cine: skipped (planted-bug fixture)
- source: data/voice/lines/ep2_opening.json: 28 lines
- source: data/voice/lines/ep3_opening.json: 15 lines
- source: data/voice/lines/ep4_opening.json: 15 lines
- source: data/voice/lines/prologue_3min.json: 30 lines
- source: data/voice/lines/unit_barks.json: 176 lines
- over slot: malrik/look_at_it_the_489223a3 ep3_opening/L12: 4.97 s > cine slot 4.80 s
- over slot: malrik/they_will_stand_there_52f7eb60 ep3_opening/L13: 4.88 s > cine slot 4.50 s
- over slot: narrator/the_westwatch_fire_rises_d7e80c5e L7: 5.23 s > subtitle 5.00 s
- over slot: pell/free_at_last_buy_f2b6c6c4 L6: 5.57 s > subtitle 5.00 s
- over slot: vessa/an_ember_crown_in_21770f9f L2: 5.59 s > subtitle 5.00 s
- this build: 28.0 rendered, 80.0 unchanged
- last render: 28.0 lines, 47.6 s of audio in 175.0 s (x3.67 real time) on ["CPUExecutionProvider"], at 2026-09-27 13:23:24
- total: 284 lines, 10.41 min of speech, 0 speed-fitted, 28 with direction tags
