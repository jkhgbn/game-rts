# Error Lab scorecard: day-end-2026-09-26

2026-09-27 00:09 - lab v1.0 - 235 tests (5 failed) - logs: `C:\Users\elzzo\Documents\four-wizards-rts\docs\errors\lab\day-end-2026-09-26\logs`

## Result: **FAIL** - score **38 / 100**

0 unique FAIL errors - 4 unique WARN errors - 2 INFO (exit noise) - 4 NEW vs previous run (no previous run)

Score = 100 - 8 per unique FAIL error - 3 per unique WARN error - 10 per failed test (min 0).

## Improve next
1. **res://nope.tscn:0** (WARN, NEW) - owner **lead (unmapped: nope.tscn)**: ART LAB ERROR: scene not found: res://nope.tscn _(x2 in 1 tests: test_art_lab)_
2. **(no frame)** (WARN, NEW) - owner **task agent of test_10_a3 (engine error, no script frame)**: hard: no B7 Guard flag after a raid _(x1 in 1 tests: test_10_a3)_
3. **engine servers/rendering/renderer_canvas_cull.cpp:2733** (WARN, NEW) - owner **task agent of test_1_u4 (engine error, no script frame)**: N RID of type "CanvasItem" was leaked. _(x1 in 1 tests: test_1_u4)_

## Tests
| Test | Result | Why | Exit | Seconds | Cap |
|---|---|---|---|---|---|
| test_1_g1 | PASS |  | 0 | 10.8 | 40000 |
| test_1_g2 | PASS |  | 0 | 12.4 | 40000 |
| test_1_g3 | PASS |  | 0 | 11.8 | 40000 |
| test_1_s1 | PASS |  | 0 | 43.7 | 40000 |
| test_1_s2 | PASS |  | 0 | 14.9 | 40000 |
| test_1_s3 | PASS |  | 0 | 10.2 | 40000 |
| test_1_u1 | PASS |  | 0 | 10.2 | 40000 |
| test_1_u2 | PASS |  | 0 | 10.8 | 40000 |
| test_1_u3 | PASS |  | 0 | 20.5 | 40000 |
| test_1_u4 | PASS |  | 0 | 10.2 | 40000 |
| test_1_u5 | PASS |  | 0 | 12.8 | 40000 |
| test_10_a1 | PASS |  | 0 | 26.1 | 40000 |
| test_10_a2 | PASS |  | 0 | 3.6 | 40000 |
| test_10_a3 | **FAIL** | exit 1; FAIL line; no PASS line | 1 | 674.8 | 150000 |
| test_10_c1 | PASS |  | 0 | 31.7 | 40000 |
| test_10_c10 | PASS |  | 0 | 30.1 | 40000 |
| test_10_c11 | PASS |  | 0 | 12.7 | 40000 |
| test_10_c12 | PASS |  | 0 | 23.1 | 40000 |
| test_10_c2 | PASS |  | 0 | 38.5 | 40000 |
| test_10_c3 | PASS |  | 0 | 6.6 | 40000 |
| test_10_c4 | PASS |  | 0 | 2.5 | 40000 |
| test_10_c5 | PASS |  | 0 | 5.6 | 40000 |
| test_10_c6 | PASS |  | 0 | 5.1 | 40000 |
| test_10_c7 | PASS |  | 0 | 28.7 | 40000 |
| test_10_c8 | PASS |  | 0 | 11.8 | 40000 |
| test_10_c9 | PASS |  | 0 | 20.6 | 40000 |
| test_10_v1 | PASS |  | 0 | 14.4 | 40000 |
| test_10_v10 | PASS |  | 0 | 2 | 40000 |
| test_10_v11 | PASS |  | 0 | 14 | 40000 |
| test_10_v12 | PASS |  | 0 | 2.1 | 40000 |
| test_10_v2 | PASS |  | 0 | 2.1 | 40000 |
| test_10_v3 | PASS |  | 0 | 2.1 | 40000 |
| test_10_v4 | PASS |  | 0 | 2.6 | 40000 |
| test_10_v5 | PASS |  | 0 | 3.6 | 40000 |
| test_10_v6 | PASS |  | 0 | 3.1 | 40000 |
| test_10_v7 | PASS |  | 0 | 3.1 | 40000 |
| test_10_v8 | PASS |  | 0 | 1.5 | 40000 |
| test_10_v9 | PASS |  | 0 | 2 | 40000 |
| test_11_a1 | PASS |  | 0 | 52.9 | 40000 |
| test_11_c1 | PASS |  | 0 | 4.6 | 40000 |
| test_11_c2 | PASS |  | 0 | 13.3 | 40000 |
| test_11_c3 | PASS |  | 0 | 25.6 | 40000 |
| test_11_c4 | PASS |  | 0 | 11.2 | 40000 |
| test_11_c5 | PASS |  | 0 | 17.5 | 40000 |
| test_11_v1 | PASS |  | 0 | 3.1 | 40000 |
| test_11_v2 | PASS |  | 0 | 2.6 | 40000 |
| test_11_v3 | PASS |  | 0 | 1.5 | 40000 |
| test_11_v4 | PASS |  | 0 | 2.6 | 40000 |
| test_11_v5 | PASS |  | 0 | 9.3 | 40000 |
| test_11_v6 | PASS |  | 0 | 2 | 40000 |
| test_11_v7 | PASS |  | 0 | 2 | 40000 |
| test_12_a1 | PASS |  | 0 | 233.2 | 60000 |
| test_12_a2 | PASS |  | 0 | 27.6 | 40000 |
| test_12_a3 | PASS |  | 0 | 78.2 | 40000 |
| test_12_c1 | PASS |  | 0 | 19.4 | 40000 |
| test_12_c10 | PASS |  | 0 | 19.9 | 40000 |
| test_12_c11 | PASS |  | 0 | 4.1 | 40000 |
| test_12_c2 | PASS |  | 0 | 3.6 | 40000 |
| test_12_c3 | PASS |  | 0 | 24.1 | 40000 |
| test_12_c4 | PASS |  | 0 | 4.6 | 40000 |
| test_12_c5 | PASS |  | 0 | 6.1 | 40000 |
| test_12_c6 | PASS |  | 0 | 22.5 | 40000 |
| test_12_c7 | PASS |  | 0 | 47.1 | 40000 |
| test_12_c8 | PASS |  | 0 | 14.8 | 40000 |
| test_12_c9 | PASS |  | 0 | 22.5 | 40000 |
| test_12_v1 | PASS |  | 0 | 11.8 | 40000 |
| test_12_v10 | PASS |  | 0 | 2 | 40000 |
| test_12_v11 | PASS |  | 0 | 2 | 40000 |
| test_12_v12 | PASS |  | 0 | 5.7 | 40000 |
| test_12_v13 | PASS |  | 0 | 2 | 40000 |
| test_12_v14 | PASS |  | 0 | 19.5 | 40000 |
| test_12_v15 | PASS |  | 0 | 2 | 40000 |
| test_12_v16 | PASS |  | 0 | 10.7 | 40000 |
| test_12_v17 | PASS |  | 0 | 2 | 40000 |
| test_12_v18 | PASS |  | 0 | 1.5 | 40000 |
| test_12_v19 | PASS |  | 0 | 20.5 | 40000 |
| test_12_v2 | PASS |  | 0 | 14.8 | 40000 |
| test_12_v20 | PASS |  | 0 | 2.5 | 40000 |
| test_12_v21 | PASS |  | 0 | 36.5 | 40000 |
| test_12_v22 | PASS |  | 0 | 2.5 | 40000 |
| test_12_v23 | PASS |  | 0 | 2.5 | 40000 |
| test_12_v24 | PASS |  | 0 | 2.6 | 40000 |
| test_12_v25 | PASS |  | 0 | 13.8 | 40000 |
| test_12_v27 | PASS |  | 0 | 2.5 | 40000 |
| test_12_v28 | PASS |  | 0 | 3.1 | 40000 |
| test_12_v29 | PASS |  | 0 | 2.6 | 40000 |
| test_12_v3 | PASS |  | 0 | 1.5 | 40000 |
| test_12_v30 | PASS |  | 0 | 2.6 | 40000 |
| test_12_v31 | PASS |  | 0 | 4.6 | 40000 |
| test_12_v32 | PASS |  | 0 | 2.6 | 40000 |
| test_12_v4 | PASS |  | 0 | 28.9 | 40000 |
| test_12_v5 | PASS |  | 0 | 14.8 | 40000 |
| test_12_v6 | PASS |  | 0 | 14.3 | 40000 |
| test_12_v7 | PASS |  | 0 | 2.6 | 40000 |
| test_12_v8 | PASS |  | 0 | 2 | 40000 |
| test_12_v9 | PASS |  | 0 | 2.1 | 40000 |
| test_12b_v2 | PASS |  | 0 | 1.5 | 40000 |
| test_12b_v3 | PASS |  | 0 | 2.1 | 40000 |
| test_12b_v4 | PASS |  | 0 | 2 | 40000 |
| test_12b_v5 | PASS |  | 0 | 2.1 | 40000 |
| test_13_v10 | PASS |  | 0 | 3.6 | 40000 |
| test_13_v13 | PASS |  | 0 | 3.1 | 40000 |
| test_13_v14 | PASS |  | 0 | 9.9 | 40000 |
| test_13_v15 | PASS |  | 0 | 3.1 | 40000 |
| test_13_v16 | PASS |  | 0 | 4.1 | 40000 |
| test_13_v18 | PASS |  | 0 | 2.6 | 40000 |
| test_13_v19 | PASS |  | 0 | 4.1 | 40000 |
| test_13_v1a | PASS |  | 0 | 5.1 | 40000 |
| test_13_v1b | PASS |  | 0 | 12.9 | 40000 |
| test_13_v2 | PASS |  | 0 | 3.1 | 40000 |
| test_13_v20 | PASS |  | 0 | 1.5 | 40000 |
| test_13_v25 | PASS |  | 0 | 2.6 | 40000 |
| test_13_v26 | PASS |  | 0 | 2 | 40000 |
| test_13_v3 | PASS |  | 0 | 3.1 | 40000 |
| test_13_v5 | PASS |  | 0 | 3.6 | 40000 |
| test_13_v6 | PASS |  | 0 | 9.8 | 40000 |
| test_13_v7 | PASS |  | 0 | 3.1 | 40000 |
| test_13_v8 | PASS |  | 0 | 3.6 | 40000 |
| test_13_v9 | PASS |  | 0 | 3.6 | 40000 |
| test_13b_v1 | PASS |  | 0 | 2.1 | 40000 |
| test_13b_v2 | PASS |  | 0 | 13.5 | 40000 |
| test_13b_v3 | PASS |  | 0 | 4.1 | 40000 |
| test_13b_v4 | PASS |  | 0 | 3.6 | 40000 |
| test_13b_v5 | PASS |  | 0 | 2.6 | 40000 |
| test_13b_v6 | PASS |  | 0 | 2.5 | 40000 |
| test_13b_v7 | PASS |  | 0 | 2.6 | 40000 |
| test_13b_v8 | PASS |  | 0 | 3.1 | 40000 |
| test_13b_v9 | PASS |  | 0 | 3.1 | 40000 |
| test_13c_v1 | PASS |  | 0 | 39 | 40000 |
| test_13c_v3 | PASS |  | 0 | 2.1 | 40000 |
| test_13c_v5 | PASS |  | 0 | 3.1 | 40000 |
| test_13c_v7 | PASS |  | 0 | 2.1 | 40000 |
| test_13c_v8 | PASS |  | 0 | 3.6 | 40000 |
| test_13c_v9 | PASS |  | 0 | 3.6 | 40000 |
| test_16a | PASS |  | 0 | 26.6 | 40000 |
| test_2_a1_attack | PASS |  | 0 | 166.2 | 40000 |
| test_2_a1_bot_vs_bot | PASS |  | 0 | 765 | 116000 |
| test_2_a1_economy | PASS |  | 0 | 69.5 | 40000 |
| test_2_a1_rules | PASS |  | 0 | 105.9 | 40000 |
| test_2_g1 | PASS |  | 0 | 11.8 | 40000 |
| test_2_g2 | PASS |  | 0 | 10.7 | 40000 |
| test_2_g3 | PASS |  | 0 | 11.8 | 40000 |
| test_2_s1 | PASS |  | 0 | 23.6 | 40000 |
| test_2_s2 | PASS |  | 0 | 10.2 | 40000 |
| test_2_s3 | PASS |  | 0 | 262.2 | 40000 |
| test_2_u1 | PASS |  | 0 | 17.9 | 40000 |
| test_20_a2 | **FAIL** | no PASS line | 0 | 220.8 | 40000 |
| test_20_a3 | **FAIL** | no PASS line | 0 | 296.4 | 40000 |
| test_3_a1 | PASS |  | 0 | 57.7 | 40000 |
| test_3_g1 | PASS |  | 0 | 55.2 | 40000 |
| test_3_g2a | PASS |  | 0 | 11.2 | 40000 |
| test_3_g2b | PASS |  | 0 | 31.2 | 40000 |
| test_3_s1 | PASS |  | 0 | 16.4 | 40000 |
| test_3_u1 | PASS |  | 0 | 30.2 | 40000 |
| test_3_u3 | PASS |  | 0 | 49.1 | 40000 |
| test_4_a1 | PASS |  | 0 | 27.6 | 40000 |
| test_4_g1 | PASS |  | 0 | 11.7 | 40000 |
| test_4_g2 | PASS |  | 0 | 13.3 | 40000 |
| test_4_i1 | PASS |  | 0 | 25.5 | 40000 |
| test_4_i2 | PASS |  | 0 | 14.8 | 40000 |
| test_4_s1 | PASS |  | 0 | 24 | 40000 |
| test_4_u1a | PASS |  | 0 | 21.9 | 40000 |
| test_4_u1b | PASS |  | 0 | 37.3 | 40000 |
| test_5_s1 | PASS |  | 0 | 23.5 | 40000 |
| test_5_u1 | PASS |  | 0 | 39.9 | 40000 |
| test_6_a1 | PASS |  | 0 | 100.2 | 40000 |
| test_6_b2 | PASS |  | 0 | 40.3 | 40000 |
| test_6_s1 | PASS |  | 0 | 96 | 40000 |
| test_6_s2 | PASS |  | 0 | 95.6 | 40000 |
| test_6_u1 | PASS |  | 0 | 50.1 | 40000 |
| test_6_u2 | PASS |  | 0 | 55.3 | 40000 |
| test_6_u3 | PASS |  | 0 | 35.9 | 40000 |
| test_7_a1 | PASS |  | 0 | 132.6 | 40000 |
| test_7_g1 | PASS |  | 0 | 40.9 | 40000 |
| test_7_g2 | PASS |  | 0 | 30.2 | 40000 |
| test_7_g3 | PASS |  | 0 | 30.7 | 40000 |
| test_7_i1 | PASS |  | 0 | 24.6 | 40000 |
| test_7_s1 | PASS |  | 0 | 109.1 | 40000 |
| test_7_u1 | PASS |  | 0 | 102.9 | 40000 |
| test_8_a1 | PASS |  | 0 | 1462.7 | 200000 |
| test_8_a2 | PASS |  | 0 | 563.8 | 100000 |
| test_8_b3 | PASS |  | 0 | 281.9 | 40000 |
| test_8_g1 | PASS |  | 0 | 232.2 | 40000 |
| test_8_g2 | PASS |  | 0 | 181.6 | 40000 |
| test_8_i1 | PASS |  | 0 | 65.2 | 40000 |
| test_8_s1 | PASS |  | 0 | 287.2 | 40000 |
| test_8_s2 | PASS |  | 0 | 130.8 | 40000 |
| test_8_u1 | PASS |  | 0 | 361.7 | 40000 |
| test_8_u2 | PASS |  | 0 | 93.7 | 40000 |
| test_9_c1 | PASS |  | 0 | 82 | 40000 |
| test_9_c10 | PASS |  | 0 | 77.8 | 40000 |
| test_9_c11 | **FAIL** | no PASS line | 0 | 355.1 | 40000 |
| test_9_c2 | PASS |  | 0 | 93 | 40000 |
| test_9_c3 | PASS |  | 0 | 605.7 | 40000 |
| test_9_c4 | PASS |  | 0 | 180.4 | 40000 |
| test_9_c5 | PASS |  | 0 | 90.9 | 40000 |
| test_9_c6 | PASS |  | 0 | 66.8 | 40000 |
| test_9_c7 | PASS |  | 0 | 27 | 40000 |
| test_9_c8 | PASS |  | 0 | 36.6 | 40000 |
| test_9_c9 | PASS |  | 0 | 546.9 | 150000 |
| test_9_v1 | PASS |  | 0 | 135 | 40000 |
| test_9_v2 | PASS |  | 0 | 50.1 | 40000 |
| test_9_v3 | PASS |  | 0 | 138.7 | 40000 |
| test_9_v4 | PASS |  | 0 | 36.6 | 40000 |
| test_9_v5 | PASS |  | 0 | 3.1 | 40000 |
| test_9_v6 | PASS |  | 0 | 2.6 | 40000 |
| test_a_8 | PASS |  | 0 | 2.1 | 40000 |
| test_a_9 | PASS |  | 0 | 3.6 | 40000 |
| test_a17 | PASS |  | 0 | 7.7 | 40000 |
| test_a2_10 | PASS |  | 0 | 8.2 | 40000 |
| test_a2_3 | PASS |  | 0 | 18.3 | 40000 |
| test_a2_4 | PASS |  | 0 | 16.8 | 40000 |
| test_a2_5 | PASS |  | 0 | 8.7 | 40000 |
| test_a2_6 | PASS |  | 0 | 9.2 | 40000 |
| test_a2_7 | PASS |  | 0 | 125.8 | 40000 |
| test_a2_8 | PASS |  | 0 | 50.4 | 40000 |
| test_a2_9 | PASS |  | 0 | 5.6 | 40000 |
| test_a5 | PASS |  | 0 | 5.1 | 40000 |
| test_art_lab | PASS |  | 0 | 8.7 | 40000 |
| test_audio_lab | PASS |  | 0 | 11.2 | 40000 |
| test_bot_lab | PASS |  | 0 | 58.3 | 40000 |
| test_data_lab | PASS |  | 0 | 13.4 | 40000 |
| test_fix_groups | PASS |  | 0 | 99.2 | 40000 |
| test_fix_minimap_click | PASS |  | 0 | 15.3 | 40000 |
| test_kit_team_color | PASS |  | 0 | 16.8 | 40000 |
| test_lead_item_passives | PASS |  | 0 | 19.9 | 40000 |
| test_m7_s1 | PASS |  | 0 | 26.1 | 40000 |
| test_m7_s2 | PASS |  | 0 | 61.3 | 40000 |
| test_m7_s3 | PASS |  | 0 | 59.9 | 40000 |
| test_m7_u1 | PASS |  | 0 | 28.1 | 40000 |
| test_map_p1 | PASS |  | 0 | 26.7 | 40000 |
| test_map_p3 | PASS |  | 0 | 6.6 | 40000 |
| test_perf_lab | PASS |  | 0 | 3.6 | 40000 |
| test_replay_lab | **FAIL** | FAIL line; no PASS line | 0 | 213.1 | 40000 |
| test_ux_1 | PASS |  | 0 | 15.3 | 40000 |

## Unique errors
| # | Sev | New | Location | Owner | Count | Tests | Message |
|---|---|---|---|---|---|---|---|
| 1 | WARN | NEW | res://nope.tscn:0 | lead (unmapped: nope.tscn) | 2 | test_art_lab | ART LAB ERROR: scene not found: res://nope.tscn |
| 2 | WARN | NEW | (no frame) | task agent of test_10_a3 (engine error, no script frame) | 1 | test_10_a3 | hard: no B7 Guard flag after a raid |
| 3 | WARN | NEW | engine servers/rendering/renderer_canvas_cull.cpp:2733 | task agent of test_1_u4 (engine error, no script frame) | 1 | test_1_u4 | N RID of type "CanvasItem" was leaked. |
| 4 | WARN | NEW | engine servers/rendering/renderer_canvas_cull.cpp:2735 | task agent of test_7_u1 (engine error, no script frame) | 1 | test_7_u1 | N RIDs of type "CanvasItem" were leaked. |

## INFO (known exit noise, never FAIL)
- N ObjectDB instances were leaked at exit (run with `--verbose` for details). - x121 in 121 tests
- N resources still in use at exit (run with --verbose for details). - x121 in 121 tests

## Fix-agent briefs (one per owner; the lead's rule: any failure -> launch a fix agent)

### lead (unmapped: nope.tscn) (1 errors)
```text
Task: fix the runtime errors the Error Lab found (run day-end-2026-09-26) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts.
Read CLAUDE.md first; edit only files you own; never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [WARN, NEW] res://nope.tscn:0 - ART LAB ERROR: scene not found: res://nope.tscn - x2 in: test_art_lab
Repro:
  & tools\godot_run.ps1 --headless --path . -s tests/test_art_lab.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_art_lab -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_1_u4 (engine error, no script frame) (1 errors)
```text
Task: fix the runtime errors the Error Lab found (run day-end-2026-09-26) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts.
Read CLAUDE.md first; edit only files you own; never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [WARN, NEW] engine servers/rendering/renderer_canvas_cull.cpp:2733 - N RID of type "CanvasItem" was leaked. - x1 in: test_1_u4
Repro:
  & tools\godot_run.ps1 --headless --path . -s tests/test_1_u4.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_1_u4 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_10_a3 (1 errors)
```text
Task: fix the runtime errors the Error Lab found (run day-end-2026-09-26) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts.
Read CLAUDE.md first; edit only files you own; never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [FAIL] tests/test_10_a3.gd - test failed (exit 1; FAIL line; no PASS line); read C:\Users\elzzo\Documents\four-wizards-rts\docs\errors\lab\day-end-2026-09-26\logs\test_10_a3.log - x1 in: test_10_a3
Repro:
  & tools\godot_run.ps1 --headless --path . -s tests/test_10_a3.gd --fixed-fps 60 --quit-after 150000
Done when: tools\error_lab\error_lab.ps1 -Tests test_10_a3 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_10_a3 (engine error, no script frame) (1 errors)
```text
Task: fix the runtime errors the Error Lab found (run day-end-2026-09-26) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts.
Read CLAUDE.md first; edit only files you own; never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [WARN, NEW] (no frame) - hard: no B7 Guard flag after a raid - x1 in: test_10_a3
Repro:
  & tools\godot_run.ps1 --headless --path . -s tests/test_10_a3.gd --fixed-fps 60 --quit-after 150000
Done when: tools\error_lab\error_lab.ps1 -Tests test_10_a3 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_20_a2 (1 errors)
```text
Task: fix the runtime errors the Error Lab found (run day-end-2026-09-26) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts.
Read CLAUDE.md first; edit only files you own; never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [FAIL] tests/test_20_a2.gd - test failed (no PASS line); read C:\Users\elzzo\Documents\four-wizards-rts\docs\errors\lab\day-end-2026-09-26\logs\test_20_a2.log - x1 in: test_20_a2
Repro:
  & tools\godot_run.ps1 --headless --path . -s tests/test_20_a2.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_20_a2 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_20_a3 (1 errors)
```text
Task: fix the runtime errors the Error Lab found (run day-end-2026-09-26) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts.
Read CLAUDE.md first; edit only files you own; never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [FAIL] tests/test_20_a3.gd - test failed (no PASS line); read C:\Users\elzzo\Documents\four-wizards-rts\docs\errors\lab\day-end-2026-09-26\logs\test_20_a3.log - x1 in: test_20_a3
Repro:
  & tools\godot_run.ps1 --headless --path . -s tests/test_20_a3.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_20_a3 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_7_u1 (engine error, no script frame) (1 errors)
```text
Task: fix the runtime errors the Error Lab found (run day-end-2026-09-26) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts.
Read CLAUDE.md first; edit only files you own; never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [WARN, NEW] engine servers/rendering/renderer_canvas_cull.cpp:2735 - N RIDs of type "CanvasItem" were leaked. - x1 in: test_7_u1
Repro:
  & tools\godot_run.ps1 --headless --path . -s tests/test_7_u1.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_7_u1 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_9_c11 (1 errors)
```text
Task: fix the runtime errors the Error Lab found (run day-end-2026-09-26) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts.
Read CLAUDE.md first; edit only files you own; never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [FAIL] tests/test_9_c11.gd - test failed (no PASS line); read C:\Users\elzzo\Documents\four-wizards-rts\docs\errors\lab\day-end-2026-09-26\logs\test_9_c11.log - x1 in: test_9_c11
Repro:
  & tools\godot_run.ps1 --headless --path . -s tests/test_9_c11.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_9_c11 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_replay_lab (1 errors)
```text
Task: fix the runtime errors the Error Lab found (run day-end-2026-09-26) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts.
Read CLAUDE.md first; edit only files you own; never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [FAIL] tests/test_replay_lab.gd - test failed (FAIL line; no PASS line); read C:\Users\elzzo\Documents\four-wizards-rts\docs\errors\lab\day-end-2026-09-26\logs\test_replay_lab.log - x1 in: test_replay_lab
Repro:
  & tools\godot_run.ps1 --headless --path . -s tests/test_replay_lab.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_replay_lab -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```
