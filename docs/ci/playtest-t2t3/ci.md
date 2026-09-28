# CI: playtest-t2t3

2026-09-27 21:46 - ci v2.0 - project `C:\Users\elzzo\Documents\four-wizards-rts-play2`

## Result: **FAIL**

| Step | Result | Detail | Fix |
|---|---|---|---|
| Import | PASS | no script / parse errors (19.1 s) |  |
| Smoke | PASS | 3 / 3 victory=true |  |
| Perf 100 units | **FAIL** | PERF units=100 ms_per_frame=10.19 budget=8.0 arrived=69 stuck=0 | Read logs/perf_100.log (stuck units = a pathing bug; ms over budget on a quiet PC = the Perf Lab breakdown). |
| Perf 200 units | **FAIL** | PERF units=200 ms_per_frame=18.66 budget=16.0 arrived=115 stuck=0 | Read logs/perf_200.log (stuck units = a pathing bug; ms over budget on a quiet PC = the Perf Lab breakdown). |
| Tests (Error Lab) | **FAIL** | 209 / 262 tests pass; Error Lab FAIL 0 / 100 (46 FAIL, 3 WARN unique errors, 48 NEW) | Open error_lab/scorecard.md: 'By owner' + one fix-agent brief per owner. |

## Tests by owner (from the Error Lab)
| Owner | FAIL errors | WARN errors | Failed tests |
|---|---|---|---|
| ui-coder | 11 | 0 | test_4_u1a, test_8_u1, test_8_u2, test_m7_u1 |
| systems-coder | 7 | 0 | test_2_s1, test_2_s3, test_7_s1, test_8_s1, test_m7_s1, test_m7_s2 |
| ai-coder | 2 | 0 | test_10_a3, test_12_a1, test_20_a3 |
| lab group A (visual) | 3 | 0 | test_ui_lab |
| tech-artist | 0 | 0 | test_12_v20, test_12_v27, test_13_v2, test_13_v6 |
| task agent of test_9_c8 | 2 | 0 | test_9_c8 |
| task agent of test_ui_minimap_zoom | 2 | 0 | test_ui_minimap_zoom |
| task agent of test_unit_dances | 2 | 0 | test_unit_dances |
| task agent of test_ux_1 | 2 | 0 | test_ux_1 |
| map_lab owner (lab) | 1 | 0 | test_map_lab |
| task agent of test_9_c3 | 1 | 0 | test_9_c3 |
| task agent of test_9_c6 | 1 | 0 | test_9_c6 |
| task agent of test_9_c7 | 1 | 0 | test_9_c7 |
| task agent of test_a2_3 | 1 | 0 | test_a2_3 |
| task agent of test_caravan_pop | 1 | 0 | test_caravan_pop |
| task agent of test_fix_groups | 1 | 0 | test_fix_groups |
| task agent of test_fix_minimap_click | 1 | 0 | test_fix_minimap_click |
| task agent of test_lead_item_passives | 1 | 0 | test_lead_item_passives |
| task agent of test_map_p1 | 1 | 0 | test_map_p1 |
| task agent of test_sound_plan | 1 | 0 | test_sound_plan |
| task agent of test_str_int | 1 | 0 | test_str_int |
| task agent of test_unit_voice | 1 | 0 | test_unit_voice |
| lab group B (simulation) | 0 | 0 | test_bot_lab, test_replay_lab |
| task agent of test_a2_9 | 1 | 0 |  |
| task agent of test_tool_voice_forge | 1 | 0 |  |
| task agent of test_10_c8 | 0 | 0 | test_10_c8 |
| task agent of test_11_c4 | 0 | 0 | test_11_c4 |
| task agent of test_12_c7 | 0 | 0 | test_12_c7 |
| task agent of test_12_c9 | 0 | 0 | test_12_c9 |
| task agent of test_6_b2 | 0 | 0 | test_6_b2 |
| task agent of test_9_c11 | 0 | 0 | test_9_c11 |
| task agent of test_9_c5 | 0 | 0 | test_9_c5 |
| task agent of test_9_c9 | 0 | 0 | test_9_c9 |
| task agent of test_bowmen | 0 | 0 | test_bowmen |
| task agent of test_new_units_12 | 0 | 0 | test_new_units_12 |
| task agent of test_pop_200 | 0 | 0 | test_pop_200 |
| task agent of test_t3 | 0 | 0 | test_t3 |
| task agent of test_tiers | 0 | 0 | test_tiers |
| task agent of test_ui_building_groups | 0 | 0 | test_ui_building_groups |
| task agent of test_ui_restart_hint | 0 | 0 | test_ui_restart_hint |
| task agent of test_ui_train_queue | 0 | 0 | test_ui_train_queue |
| ai-coder (engine error, no script frame) | 0 | 3 |  |

Full report, log tails and fix-agent briefs: `error_lab/scorecard.md`.

## Result lines
```text
CI: FAIL - Import PASS, Smoke PASS, Perf 100 units FAIL, Perf 200 units FAIL, Tests (Error Lab) FAIL
SMOKE: GAME OVER at frame 3840: victory=true player=7 enemy=6
SMOKE: GAME OVER at frame 3660: victory=true player=1 enemy=6
SMOKE: GAME OVER at frame 3840: victory=true player=7 enemy=5
PERF units=100 ms_per_frame=10.19 budget=8.0 arrived=69 stuck=0
PERF units=200 ms_per_frame=18.66 budget=16.0 arrived=115 stuck=0
tests run: 262, failed: 53
FAIL-> test_10_a3: assert (exit 1; FAIL line; no PASS line) [ai-coder] FAIL 10.A3: 2 error(s)
FAIL-> test_10_c8: assert (FAIL line; no PASS line) [task agent of test_10_c8] FAIL 10.c8: top bar rect [P: (479.5, 8.0), S: (641.0, 40.0)], expected (488, 8, 624, 40) (step 3)
FAIL-> test_11_c4: assert (FAIL line; no PASS line) [task agent of test_11_c4] FAIL 11.c4: 3 problem(s) (step 3)
FAIL-> test_12_a1: assert (FAIL line; no PASS line) [ai-coder] FAIL 12.A1: 2 problem(s)
FAIL-> test_12_c7: assert (FAIL line; no PASS line) [task agent of test_12_c7] FAIL 12.C7: blessing chip rects [P: (958.0, 54.0), S: (144.0, 23.0)] [P: (958.0, 78.0), S: (144.0, 23.0)]
FAIL-> test_12_c9: assert (FAIL line; no PASS line) [task agent of test_12_c9] FAIL 12.C9: 12 problem(s)
FAIL-> test_12_v20: assert (FAIL line; no PASS line) [tech-artist] FAIL 12.v20: head tossed up at the strike (-12.0)
FAIL-> test_12_v27: assert (FAIL line; no PASS line) [tech-artist] FAIL 12.v27: B's right tusk is the broken one
FAIL-> test_13_v2: assert (FAIL line; no PASS line) [tech-artist] FAIL 13.v2: nothing below the ground at rest (-0.011)
FAIL-> test_13_v6: assert (FAIL line; no PASS line) [tech-artist] FAIL 13.v6: nothing below the ground at rest (-0.010)
FAIL-> test_2_s1: assert (FAIL line; no PASS line) [systems-coder] FAIL 2.S1: fire_hearth numbers | shadow_hovel numbers
FAIL-> test_2_s3: assert (FAIL line; no PASS line) [systems-coder] FAIL 2.S3: crown bonus: hp 450 / 450 mana max 188, want 450 / 450, 150
FAIL-> test_20_a3: assert (FAIL line; no PASS line) [ai-coder] FAIL 20.A3: bot 0 median think 2.354 ms > 1.5 ms
FAIL-> test_4_u1a: assert (FAIL line; no PASS line) [ui-coder] FAIL 4.u1a: top bar rect [P: (479.5, 8.0), S: (641.0, 40.0)]
FAIL-> test_6_b2: assert (FAIL line; no PASS line) [task agent of test_6_b2] FAIL 6.B2: fire_hearth data; shadow_hovel data
FAIL-> test_7_s1: assert (FAIL line; no PASS line) [systems-coder] FAIL 7.S1: ice_lodge is [80, 30.0, 600.0, (2, 2), 3.0, 20, 9, "Z"], spec [80, 30.0, 600.0, (2, 2), 3.0, 10, 2, "Z"]
FAIL-> test_8_s1: assert (FAIL line; no PASS line) [systems-coder] FAIL 8.S1: nature_hollow is [60, 20.0, 450.0, (2, 2), 3.0, 20, 9, "Z", &"house"], spec [60, 20.0, 450.0, (2, 2), 3.0, 10, 3, "Z", &"house"]; pop_cap_limit_for nature / fire = 200 / 200; after the Heartwood: kingdom nature, max 200, cap 20; Heartwood + 3 hollows: pop cap 80, not 50; 4th hollow: ''; pop cap above the Nature cap: 100; pop cap after losing the extra hollow: 80; Fire cap changed: max 200, cap 20
FAIL-> test_8_u1: assert (FAIL line; no PASS line) [ui-coder] FAIL 8.u1: top bar pop is '13 / 80', expected '/ 50'
FAIL-> test_8_u2: assert (FAIL line; no PASS line) [ui-coder] FAIL 8.U2: navigation never finished baking
FAIL-> test_9_c11: assert (FAIL line; no PASS line) [task agent of test_9_c11] FAIL 9.C11: navigation never finished baking
FAIL-> test_9_c3: assert (FAIL line; no PASS line) [task agent of test_9_c3] FAIL 9.C3: navigation never finished baking
FAIL-> test_9_c5: assert (FAIL line; no PASS line) [task agent of test_9_c5] FAIL 9.C5: navigation never finished baking
FAIL-> test_9_c6: assert (FAIL line; no PASS line) [task agent of test_9_c6] FAIL 9.c6: navigation never finished baking
FAIL-> test_9_c7: assert (FAIL line; no PASS line) [task agent of test_9_c7] FAIL 9.c7: navigation never finished baking
FAIL-> test_9_c8: assert (FAIL line; no PASS line) [task agent of test_9_c8] FAIL 9.C8: navigation never finished baking
FAIL-> test_9_c9: assert (FAIL line; no PASS line) [task agent of test_9_c9] FAIL 9.C9: navigation never finished baking
FAIL-> test_a2_3: assert (exit 1; FAIL line; no PASS line) [task agent of test_a2_3] FAIL a2.3: navigation never finished baking
FAIL-> test_bot_lab: assert (FAIL line; no PASS line) [lab group B (simulation)] FAIL bot lab: fire-ice_s1.json has no 'score'
FAIL-> test_bowmen: assert (FAIL line; no PASS line) [task agent of test_bowmen] FAIL bowmen: navigation never finished baking
FAIL-> test_caravan_pop: assert (FAIL line; no PASS line) [task agent of test_caravan_pop] FAIL caravan_pop: navigation never finished baking
FAIL-> test_fix_groups: assert (FAIL line; no PASS line) [task agent of test_fix_groups] FAIL fix_groups: navigation never finished baking
FAIL-> test_fix_minimap_click: assert (FAIL line; no PASS line) [task agent of test_fix_minimap_click] FAIL fix_minimap_click: navigation never finished baking
FAIL-> test_lead_item_passives: assert (FAIL line; no PASS line) [task agent of test_lead_item_passives] FAIL lead_item_passives: map never ready
FAIL-> test_m7_s1: assert (FAIL line; no PASS line) [systems-coder] FAIL m7_s1: navigation never finished baking
FAIL-> test_m7_s2: assert (FAIL line; no PASS line) [systems-coder] FAIL m7_s2: navigation never finished baking
FAIL-> test_m7_u1: assert (FAIL line; no PASS line) [ui-coder] FAIL M7.U1: navigation never finished baking
FAIL-> test_map_lab: assert (FAIL line; no PASS line) [map_lab owner (lab)] FAIL map_lab: the skirmish never finished its bake
FAIL-> test_map_p1: assert (FAIL line; no PASS line) [task agent of test_map_p1] FAIL MAP.P1: the skirmish never finished loading
FAIL-> test_new_units_12: assert (FAIL line; no PASS line) [task agent of test_new_units_12] FAIL new_units_12: navigation never finished baking
FAIL-> test_pop_200: assert (FAIL line; no PASS line) [task agent of test_pop_200] FAIL pop_200: navigation never finished baking
FAIL-> test_replay_lab: assert (FAIL line; no PASS line) [lab group B (simulation)] FAIL replay_lab: timed out waiting for script_rec
FAIL-> test_sound_plan: assert (FAIL line; no PASS line) [task agent of test_sound_plan] FAIL sound_plan: 1 problem(s)
FAIL-> test_str_int: assert (FAIL line; no PASS line) [task agent of test_str_int] FAIL str_int: map never ready
FAIL-> test_t3: assert (FAIL line; no PASS line) [task agent of test_t3] FAIL t3: navigation never finished baking
FAIL-> test_tiers: assert (FAIL line; no PASS line) [task agent of test_tiers] FAIL tiers: navigation never finished baking
FAIL-> test_ui_building_groups: assert (FAIL line; no PASS line) [task agent of test_ui_building_groups] FAIL ui_building_groups: skirmish never started
FAIL-> test_ui_lab: script error (no PASS line) [lab group A (visual)]
FAIL-> test_ui_minimap_zoom: assert (FAIL line; no PASS line) [task agent of test_ui_minimap_zoom] FAIL ui_minimap_zoom: navigation never finished baking
FAIL-> test_ui_restart_hint: assert (FAIL line; no PASS line) [task agent of test_ui_restart_hint] FAIL ui_restart_hint: timed out at step 1
FAIL-> test_ui_train_queue: assert (FAIL line; no PASS line) [task agent of test_ui_train_queue] FAIL ui_train_queue: skirmish never started
FAIL-> test_unit_dances: assert (FAIL line; no PASS line) [task agent of test_unit_dances] FAIL unit_dances: timed out at step 2
FAIL-> test_unit_voice: assert (FAIL line; no PASS line) [task agent of test_unit_voice] FAIL unit_voice: navigation never finished baking
FAIL-> test_ux_1: assert (FAIL line; no PASS line) [task agent of test_ux_1] FAIL ux.1: navigation never finished baking
```

Logs: `C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\logs`.
