# Error Lab scorecard: ci-playtest-2026-09-27

2026-09-27 14:35 - lab v1.1 - 248 tests (10 failed) - project `C:\Users\elzzo\Documents\four-wizards-rts-play` - logs: `C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-2026-09-27\error_lab\logs`

## Result: **FAIL** - score **0 / 100**

0 unique FAIL errors - 1 unique WARN errors - 4 INFO (exit noise) - 1 NEW (not in the last 10 history rows) - previous run baseline-2026-09-27-partial: FAIL 14

Score = 100 - 8 per unique FAIL error - 3 per unique WARN error - 10 per failed test (min 0).

## Improve next
1. **tests/test_10_c6.gd** failed: **assert** (FAIL line; no PASS line) - owner **task agent of test_10_c6**. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
2. **tests/test_10_c7.gd** failed: **assert** (FAIL line; no PASS line) - owner **task agent of test_10_c7**. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
3. **(no frame)** (WARN, NEW) - owner **lab group A (visual) (engine error, no script frame)**: ART LAB ERROR: sweep=bogus: use all or a comma list of ["fire", "ice", "nature", "shadow", "neutral"] _(x1 in 1 tests: test_art_lab)_

## By owner (who has work)
| Owner | FAIL errors | WARN errors | Failed tests | Tests to re-run |
|---|---|---|---|---|
| ai-coder | 0 | 0 | test_12_a1 (assert), test_20_a3 (assert) | test_12_a1, test_20_a3 |
| lab group A (visual) | 0 | 0 | test_art_lab (assert) | test_art_lab |
| lab group B (simulation) | 0 | 0 | test_replay_lab (assert) | test_replay_lab |
| task agent of test_10_c6 | 0 | 0 | test_10_c6 (assert) | test_10_c6 |
| task agent of test_10_c7 | 0 | 0 | test_10_c7 (assert) | test_10_c7 |
| task agent of test_9_c5 | 0 | 0 | test_9_c5 (assert) | test_9_c5 |
| task agent of test_9_c9 | 0 | 0 | test_9_c9 (assert) | test_9_c9 |
| task agent of test_art_lab_calibration | 0 | 0 | test_art_lab_calibration (assert) | test_art_lab_calibration |
| tech-artist | 0 | 0 | test_9_v2 (assert) | test_9_v2 |
| lab group A (visual) (engine error, no script frame) | 0 | 1 |  | test_art_lab |

## Failed tests (diagnosis + log tail)

### test_10_c6 - assert - owner task agent of test_10_c6
FAIL line; no PASS line; 26.2 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 10.C6: caravan pop (got 0, want 1)`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-2026-09-27\error_lab\logs\test_10_c6.log):
```text
  x caravan pop (got 0, want 1)
FAIL 10.C6: caravan pop (got 0, want 1)
```

### test_10_c7 - assert - owner task agent of test_10_c7
FAIL line; no PASS line; 58.7 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 10.C7: 1 check(s) failed`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-2026-09-27\error_lab\logs\test_10_c7.log):
```text
  - caravan tooltip 'Caravan  [Z]
Cost 75 crystals ? Pop 0 ? 20 s
Trades with a post and brings gold back. Max 6.'
FAIL 10.C7: 1 check(s) failed
```

### test_12_a1 - assert - owner ai-coder
FAIL line; no PASS line; 368.4 s, cap 60000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 12.A1: 2 problem(s)`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-2026-09-27\error_lab\logs\test_12_a1.log):
```text
  [4:30] SCOUT Nightbolt to (36, 48)
  [4:44] SCOUT next (-24, 36) via (12, 49)
  [4:47] SQUAD back: Mossmere Well done
  [4:54] SCOUT next (-24, 48)
  [4:55] SCOUT next (-36, 48)
  [4:57] SCOUT next (-48, 48)
  [4:58] SQUAD 3 units to Rookwatch
  [5:16] SQUAD back: Rookwatch done
  [5:26] SQUAD 3 units to Millwatch
finished after 46807 frames
NOTE normal: 1 rule-7 attacks (pop capped)
NOTE hard: deer shots 0
ERROR normal: map-fill median 0.127 ms per tick (limit 0.10)
ERROR hard: map-fill median 0.115 ms per tick (limit 0.10)
FAIL 12.A1: 2 problem(s)
```

### test_20_a3 - assert - owner ai-coder
FAIL line; no PASS line; 459.2 s, cap 80000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 20.A3: bot 0 median think 1.621 ms > 1.5 ms`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-2026-09-27\error_lab\logs\test_20_a3.log):
```text
  attack blocks (ticks): { "no army": 239, "pop": 192, "defending": 51, "group out": 94, "rally": 34, "strength": 6, "retreat": 29 }
  sub (avg ms/max ms): scan.units 0.21/2.5
team 1: crystals 5, gathered 5030, pop 4 / 40
bot 1: ticks 646, median 1.751 ms, avg 1.980 ms, max 42.699 ms at 215 s; attacks 1 (first 632 s), stage 0, str 200 vs seen 1810
  steps (median ms/avg ms/max ms@s): scan 0.374/0.41/18.4@168, memory 0.152/0.14/1.0@369, pending 0.138/0.13/3.5@480, champions 0.136/0.31/44.5@602, items 0.123/0.13/1.9@391, mapfill_sense 0.081/0.09/0.6@161, mapfill 0.078/0.13/2.0@182, train 0.076/0.08/2.8@502, trade_sense 0.054/0.06/0.2@312, attack 0.049/0.06/1.2@247, wizard 0.049/0.06/2.8@480, trade 0.042/0.07/1.3@403, economy 0.036/0.04/1.7@167, defend 0.031/0.13/10.0@552, learn 0.016/0.02/0.3@155, track_workers 0.015/0.02/0.3@152, exchange 0.009/0.01/0.3@357, scout 0.009/0.03/1.3@386, build 0.009/0.29/40.2@361, all_in 0.007/0.06/27.1@215, concede 0.004/0.03/17.0@639, retreat 0.002/0.01/2.0@189
  attack blocks (ticks): { "no army": 211, "pop": 169, "group out": 93, "strength": 47, "defending": 86, "retreat": 17, "rally": 23 }
  sub (avg ms/max ms): scan.units 0.35/18.3
bot 0 think: median 1.621 ms, avg 1.740 ms, p95 3.022 ms, max 9.277 ms at 299 s
bot 0 (fire): 2 attacks, first 389 s, median 1.621 ms, max 9.277 ms
bot 1 think: median 1.751 ms, avg 1.980 ms, p95 3.071 ms, max 42.699 ms at 215 s
bot 1 (shadow): 1 attacks, first 632 s, median 1.751 ms, max 42.699 ms
match: over true at 639 s, winner 0
  bot 0 median think 1.621 ms > 1.5 ms
  bot 1 median think 1.751 ms > 1.5 ms
FAIL 20.A3: bot 0 median think 1.621 ms > 1.5 ms
```

### test_9_c5 - assert - owner task agent of test_9_c5
FAIL line; no PASS line; 142.6 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL timing: brains + senses 112.8 us per frame (< 100)`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-2026-09-27\error_lab\logs\test_9_c5.log):
```text
ok   Oathwall never goes more than 25 m from its buildings (max 13.2 m) and drops the chase
ok   fog: a worker 22 m away in the fog is unknown, no raid (fog state 1, remembered false, plan GAME)
ok   R8 Coin-Cutter raids the seen worker
ok   R8 Coin-Cutter goes for the nearest closed Lost Cache (plan CACHE, available true, fog 2, caches 5)
ok   Coin-Cutter reaches the cache (opened: true, purse 0 -> 80)
ok   R8 Mender follows the 5-soldier group, goal 4.0 m behind its centre
ok   Mender stands on the side away from the enemy (toward home)
ok   R1 fallen: intent Fallen
ok   a real Champion creates its ChampionBrain child
ok   real Champion takes a real Explore flag (place: '', intent Scouting bounty)
ok   real Champion walks to it and is paid (purse 50 -> 75)
timing: 200 units, 6 champions: brains 24723.0 us (120 ticks), senses 42938.0 us (40 passes) over 600 frames
FAIL timing: brains + senses 112.8 us per frame (< 100)
---- 43 checks, 1 failed
FAIL 9.C5: timing: brains + senses 112.8 us per frame (< 100)
```

### test_9_c9 - assert - owner task agent of test_9_c9
FAIL line; no PASS line; 1013.5 s, cap 150000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 9.C9: hard: champion rule median 0.184 ms per tick (limit 0.10)`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-2026-09-27\error_lab\logs\test_9_c9.log):
```text
  [2:08] CHAMPION hire coin_cutter (Sable Quint) #1: 225 crystals + 75 essence, crystals 390 -> 165, from (-15, -15)
  [3:50] CHAMPION hire mender (Orla Fenwick) #2: 275 crystals + 100 essence, crystals 425 -> 150, from (-15, -15)
  [6:02] CHAMPION hire wayfinder (Tamsin Farrow) #3: 325 crystals + 125 essence, crystals 485 -> 160, from (15, 15)
  [8:58] BOUNTY B1 Guard 50 on Gloom Hall (stakes 0 + 50 <= 1320 of 3300 spare essence)
  [9:00] BOUNTY B7 Guard 50 on Gloom Hall (stakes 50 + 50 <= 1300 of 3249 spare essence)
  [9:10] BOUNTY B4 Explore 25 on (-23, 9) (stakes 100 + 25 <= 1286 of 3214 spare essence)
  [9:10] BOUNTY B1 Guard 50 on Gloom Hall (stakes 0 + 50 <= 1240 of 3101 spare essence)
  [9:11] BOUNTY B2 Hunt 100 on Cinder Hand (stakes 50 + 100 <= 1221 of 3052 spare essence)
  [9:11] BOUNTY B7 Guard 50 on Gloom Hall (stakes 150 + 50 <= 1181 of 2952 spare essence)
  [9:14] BOUNTY B1 Guard 50 on Gloom Hall (stakes 0 + 50 <= 1260 of 3150 spare essence)
  [9:15] BOUNTY B3 Hunt 150 on Vessa (stakes 50 + 150 <= 1240 of 3101 spare essence)
normal: hires [&"coin_cutter", &"oathwall"] at ["3:12", "4:35"], roster max 2, flags 0
easy: hires [&"oathwall"] at ["7:44"], roster max 1, flags []
hard: hires ["coin_cutter", "mender", "wayfinder"] at ["2:08", "3:50", "6:02"], roster max 3, flags ["B1@8:58", "B7@9:00", "B4@9:10", "B1@9:10", "B2@9:11", "B7@9:11", "B1@9:14", "B3@9:15"]
FAIL 9.C9: hard: champion rule median 0.184 ms per tick (limit 0.10)
```

### test_9_v2 - assert - owner tech-artist
FAIL line; no PASS line; 220.1 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 9.v2: part below the ground (-0.01)`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-2026-09-27\error_lab\logs\test_9_v2.log):
```text
INFO 9.v2: authored 25, draw instances 10 + 2 particle systems, lights 0, vertices 2467, materials 5
FAIL 9.v2: part below the ground (-0.01)
```

### test_art_lab - assert - owner lab group A (visual)
FAIL line; 58.1 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL B4t Triangles: 2534`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-2026-09-27\error_lab\logs\test_art_lab.log):
```text
ART LAB mirefang_ff: vs previous run quality 84 -> 80 (-4); worse: none; better: 0
ART LAB mirefang (unit / creature, neutral) -> user://art_lab_test/diff [headless: no renders]
ART LAB mirefang: PASS quality 98 (0 FAIL, 0 WARN, 15 PASS) in 1 s -> user://art_lab_test/diff/scorecard.md
  focus=B4: 2 check(s) re-measured, 23 kept from the run of 2026-09-27 14:18:19
ART LAB mirefang: vs previous run quality 98 -> 98 (+0); worse: none; better: 1
  diff: headless focus=B4 0.7 s vs full 1.7 s
ART LAB SWEEP v3 neutral: 1 assets (neutral 1) [headless: budgets only]
ART LAB mirefang (unit / creature, neutral) -> user://art_lab_test/army/assets/mirefang [headless: no renders]
ART LAB mirefang: PASS quality 98 (0 FAIL, 0 WARN, 15 PASS) in 0 s -> user://art_lab_test/army/assets/mirefang/scorecard.md
ART LAB mirefang: vs previous run quality 98 -> 98 (+0); worse: none; better: 0
ART LAB BATCH 1 / 1: mirefang PASS 98 (0.5 s)
ART LAB SWEEP v3 done: 1 assets, 0 FAIL, 0 pairs read alike, batch 1 s (0.6 s / asset), silhouettes 0 s (0 models), total 1 s -> user://art_lab_test/army/army.md, user://art_lab_test/army_backlog.md
ART LAB SWEEP backlog rebuilt from 1 scorecards, 0 pairs -> user://art_lab_test/army_backlog.md
ART LAB ERROR: sweep=bogus: use all or a comma list of ["fire", "ice", "nature", "shadow", "neutral"]
PASS art_lab
```

### test_art_lab_calibration - assert - owner task agent of test_art_lab_calibration
FAIL line; 229.6 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL B4 Vertices: 20663 (biggest: Merged 19645, Merged 253, Merged 229, Merged 215)`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-2026-09-27\error_lab\logs\test_art_lab_calibration.log):
```text
ART LAB plant_team_dusk_steed: PASS quality 98 (0 FAIL, 0 WARN, 13 PASS) in 0 s -> res://docs/art/lab/_calibration_headless/plant_team_dusk_steed/scorecard.md
  shade                      PASS q  99.3 band 94-100    0.4 s
  dusk_steed                 PASS q  98.4 band 94-100    0.3 s
  aqueduct                   PASS q 100.0 band 95-100    0.1 s
  fire_gun_vfx               PASS q 100.0 band 90-100    0.5 s
  deer                       PASS q  98.7 band 95-100    0.1 s
  frost_dragon               PASS q  98.9 band 95-100    1.7 s
  plant_green_shade          PASS q  99.3 band 79-88     0.0 s
  plant_glow40_frost_dragon  PASS q  98.8 band 89-95     0.1 s
  plant_verts20k_shade       FAIL q  94.3 band 91-98     0.1 s  FAIL B4
  plant_float_deer           FAIL q  84.4 band 87-94     0.0 s  FAIL R9
  plant_permat_dusk_steed    FAIL q  89.0 band 86-92     0.1 s  FAIL B9
  plant_team_dusk_steed      PASS q  98.4 band 91-97     0.1 s
ART LAB BATCH done: 12 assets in 4.8 s (0.4 s / asset; first 0.4 s, then 0.3 s / asset)
PASS art_lab_calibration (12 cases in band, headless: render checks not judged, 5 s)
```

### test_replay_lab - assert - owner lab group B (simulation)
FAIL line; no PASS line; 534.9 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL replay_lab: script replay does not match ({"diff":["pos: [11626.0,-10939.0,0.0] vs [11619.0,-10870.0,0.0]"],"f":900.0,"t":15.0}) \| bot-vs-bot seed 3 is not deterministic: first different checkpoint 600 (36 vs 36 checkpoints) \| bot replay from file does not match ({"diff":["pos: [8853.0,-8846.0,0.0] vs [8846.0,-8846.0,0.0]"],"f":600.0,"t":10.0})`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-2026-09-27\error_lab\logs\test_replay_lab.log):
```text
REPLAY_LAB bots_b: {"abs_path":"C:/Users/elzzo/AppData/Roaming/Godot/app_userdata/Four Wizards RTS/replay_lab_test/bots_b.replay","frame":10800.0,"hash":"422bcf710ff10c06a83beb5eaf27bf2b","mode":"bots","ok":true,"path":"user://replay_lab_test/bots_b.replay","real_s":81.2,"reason":"time"}
REPLAY_LAB script_rec: {"abs_path":"C:/Users/elzzo/AppData/Roaming/Godot/app_userdata/Four Wizards RTS/replay_lab_test/script.replay","frame":10800.0,"hash":"6dfcbd4ca5626cd909a04e963bae136c","mode":"script","ok":true,"path":"user://replay_lab_test/script.replay","real_s":77.4,"reason":"time"}
REPLAY_LAB bots_a: {"abs_path":"C:/Users/elzzo/AppData/Roaming/Godot/app_userdata/Four Wizards RTS/replay_lab_test/bots_a.replay","frame":10800.0,"hash":"25df35045edae08f7c068e92d9f7f687","mode":"bots","ok":true,"path":"user://replay_lab_test/bots_a.replay","real_s":84.2,"reason":"time"}
REPLAY_LAB script_play: {"checks":35.0,"checks_ok":2.0,"divergence":{"diff":["pos: [11626.0,-10939.0,0.0] vs [11619.0,-10870.0,0.0]"],"f":900.0,"t":15.0},"end_match":false,"file_checks":35.0,"file_end_frame":10800.0,"frame":10800.0,"hash":"d2578ecafdecda850513c054e66202c2","mode":"play","ok":false,"partial":false,"partial_ok":false,"real_s":77.9,"reason":"end_frame","recorded_end_frame":10800.0,"recorded_hash":"6dfcbd4ca5626cd909a04e963bae136c"}
REPLAY_LAB bots_play: {"checks":35.0,"checks_ok":1.0,"divergence":{"diff":["pos: [8853.0,-8846.0,0.0] vs [8846.0,-8846.0,0.0]"],"f":600.0,"t":10.0},"end_match":false,"file_checks":35.0,"file_end_frame":10800.0,"frame":10800.0,"hash":"750c506a2b1c45c5f21973eb0111e233","mode":"play","ok":false,"partial":false,"partial_ok":false,"real_s":85.1,"reason":"end_frame","recorded_end_frame":10800.0,"recorded_hash":"25df35045edae08f7c068e92d9f7f687"}
REPLAY_LAB bots diverge at frame 600: pos [8853.0,-8846.0,0.0] vs [8846.0,-8853.0,0.0]
REPLAY_LAB took 523 s
FAIL replay_lab: script replay does not match ({"diff":["pos: [11626.0,-10939.0,0.0] vs [11619.0,-10870.0,0.0]"],"f":900.0,"t":15.0}) | bot-vs-bot seed 3 is not deterministic: first different checkpoint 600 (36 vs 36 checkpoints) | bot replay from file does not match ({"diff":["pos: [8853.0,-8846.0,0.0] vs [8846.0,-8846.0,0.0]"],"f":600.0,"t":10.0})
```

## Tests
| Test | Result | Why | Exit | Seconds | Cap |
|---|---|---|---|---|---|
| test_1_g1 | PASS |  | 0 | 41.9 | 40000 |
| test_1_g2 | PASS |  | 0 | 23.4 | 40000 |
| test_1_g3 | PASS |  | 0 | 24.9 | 40000 |
| test_1_s1 | PASS |  | 0 | 42.2 | 40000 |
| test_1_s2 | PASS |  | 0 | 27.3 | 40000 |
| test_1_s3 | PASS |  | 0 | 59.6 | 40000 |
| test_1_u1 | PASS |  | 0 | 64.9 | 40000 |
| test_1_u2 | PASS |  | 0 | 19.8 | 40000 |
| test_1_u3 | PASS |  | 0 | 28.4 | 40000 |
| test_1_u4 | PASS |  | 0 | 45.8 | 40000 |
| test_1_u5 | PASS |  | 0 | 32.3 | 40000 |
| test_10_a1 | PASS |  | 0 | 44.3 | 40000 |
| test_10_a2 | PASS |  | 0 | 44 | 40000 |
| test_10_a3 | PASS |  | 0 | 1306.8 | 150000 |
| test_10_c1 | PASS |  | 0 | 165.2 | 40000 |
| test_10_c10 | PASS |  | 0 | 103.2 | 40000 |
| test_10_c11 | PASS |  | 0 | 135.7 | 40000 |
| test_10_c12 | PASS |  | 0 | 52.8 | 40000 |
| test_10_c2 | PASS |  | 0 | 93.8 | 40000 |
| test_10_c3 | PASS |  | 0 | 54.4 | 40000 |
| test_10_c4 | PASS |  | 0 | 21.2 | 40000 |
| test_10_c5 | PASS |  | 0 | 30.2 | 40000 |
| test_10_c6 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 26.2 | 40000 |
| test_10_c7 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 58.7 | 40000 |
| test_10_c8 | PASS |  | 0 | 51.7 | 40000 |
| test_10_c9 | PASS |  | 0 | 44.3 | 40000 |
| test_10_v1 | PASS |  | 0 | 19.5 | 40000 |
| test_10_v10 | PASS |  | 0 | 21 | 40000 |
| test_10_v11 | PASS |  | 0 | 6.3 | 40000 |
| test_10_v12 | PASS |  | 0 | 5.7 | 40000 |
| test_10_v2 | PASS |  | 0 | 3.6 | 40000 |
| test_10_v3 | PASS |  | 0 | 4.1 | 40000 |
| test_10_v4 | PASS |  | 0 | 3.1 | 40000 |
| test_10_v5 | PASS |  | 0 | 5.1 | 40000 |
| test_10_v6 | PASS |  | 0 | 9.5 | 40000 |
| test_10_v7 | PASS |  | 0 | 13.1 | 40000 |
| test_10_v8 | PASS |  | 0 | 15.5 | 40000 |
| test_10_v9 | PASS |  | 0 | 9.8 | 40000 |
| test_11_a1 | PASS |  | 0 | 83.1 | 40000 |
| test_11_c1 | PASS |  | 0 | 27.6 | 40000 |
| test_11_c2 | PASS |  | 0 | 55 | 40000 |
| test_11_c3 | PASS |  | 0 | 52.6 | 40000 |
| test_11_c4 | PASS |  | 0 | 15.2 | 40000 |
| test_11_c5 | PASS |  | 0 | 6.3 | 40000 |
| test_11_v1 | PASS |  | 0 | 3.6 | 40000 |
| test_11_v2 | PASS |  | 0 | 2.5 | 40000 |
| test_11_v3 | PASS |  | 0 | 2.6 | 40000 |
| test_11_v4 | PASS |  | 0 | 2.6 | 40000 |
| test_11_v5 | PASS |  | 0 | 2.6 | 40000 |
| test_11_v6 | PASS |  | 0 | 3.1 | 40000 |
| test_11_v7 | PASS |  | 0 | 3.6 | 40000 |
| test_12_a1 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 368.4 | 60000 |
| test_12_a2 | PASS |  | 0 | 42.2 | 40000 |
| test_12_a3 | PASS |  | 0 | 14 | 40000 |
| test_12_c1 | PASS |  | 0 | 56.9 | 40000 |
| test_12_c10 | PASS |  | 0 | 28.8 | 40000 |
| test_12_c11 | PASS |  | 0 | 7.3 | 40000 |
| test_12_c2 | PASS |  | 0 | 5.7 | 40000 |
| test_12_c3 | PASS |  | 0 | 12.6 | 40000 |
| test_12_c4 | PASS |  | 0 | 7.5 | 40000 |
| test_12_c5 | PASS |  | 0 | 10.4 | 40000 |
| test_12_c6 | PASS |  | 0 | 33.6 | 40000 |
| test_12_c7 | PASS |  | 0 | 34.5 | 40000 |
| test_12_c8 | PASS |  | 0 | 22.6 | 40000 |
| test_12_c9 | PASS |  | 0 | 8.3 | 40000 |
| test_12_v1 | PASS |  | 0 | 4.7 | 40000 |
| test_12_v10 | PASS |  | 0 | 5.2 | 40000 |
| test_12_v11 | PASS |  | 0 | 4.2 | 40000 |
| test_12_v12 | PASS |  | 0 | 5.9 | 40000 |
| test_12_v13 | PASS |  | 0 | 3.4 | 40000 |
| test_12_v14 | PASS |  | 0 | 4.2 | 40000 |
| test_12_v15 | PASS |  | 0 | 3.8 | 40000 |
| test_12_v16 | PASS |  | 0 | 20.4 | 40000 |
| test_12_v17 | PASS |  | 0 | 5.9 | 40000 |
| test_12_v18 | PASS |  | 0 | 15.4 | 40000 |
| test_12_v19 | PASS |  | 0 | 6.3 | 40000 |
| test_12_v2 | PASS |  | 0 | 26.3 | 40000 |
| test_12_v20 | PASS |  | 0 | 6.1 | 40000 |
| test_12_v21 | PASS |  | 0 | 8.7 | 40000 |
| test_12_v22 | PASS |  | 0 | 4.2 | 40000 |
| test_12_v23 | PASS |  | 0 | 5.6 | 40000 |
| test_12_v24 | PASS |  | 0 | 5.7 | 40000 |
| test_12_v25 | PASS |  | 0 | 26.3 | 40000 |
| test_12_v27 | PASS |  | 0 | 24.7 | 40000 |
| test_12_v28 | PASS |  | 0 | 6.7 | 40000 |
| test_12_v29 | PASS |  | 0 | 8.3 | 40000 |
| test_12_v3 | PASS |  | 0 | 8.8 | 40000 |
| test_12_v30 | PASS |  | 0 | 9.3 | 40000 |
| test_12_v31 | PASS |  | 0 | 9.1 | 40000 |
| test_12_v32 | PASS |  | 0 | 6.2 | 40000 |
| test_12_v4 | PASS |  | 0 | 5.6 | 40000 |
| test_12_v5 | PASS |  | 0 | 26.7 | 40000 |
| test_12_v6 | PASS |  | 0 | 27.1 | 40000 |
| test_12_v7 | PASS |  | 0 | 6.7 | 40000 |
| test_12_v8 | PASS |  | 0 | 6.6 | 40000 |
| test_12_v9 | PASS |  | 0 | 5.5 | 40000 |
| test_12b_v2 | PASS |  | 0 | 3.5 | 40000 |
| test_12b_v3 | PASS |  | 0 | 3.5 | 40000 |
| test_12b_v4 | PASS |  | 0 | 5.3 | 40000 |
| test_12b_v5 | PASS |  | 0 | 4.9 | 40000 |
| test_13_v10 | PASS |  | 0 | 5.2 | 40000 |
| test_13_v13 | PASS |  | 0 | 4.5 | 40000 |
| test_13_v14 | PASS |  | 0 | 17.5 | 40000 |
| test_13_v15 | PASS |  | 0 | 20.5 | 40000 |
| test_13_v16 | PASS |  | 0 | 8.5 | 40000 |
| test_13_v18 | PASS |  | 0 | 8.4 | 40000 |
| test_13_v19 | PASS |  | 0 | 10.5 | 40000 |
| test_13_v1a | PASS |  | 0 | 8.5 | 40000 |
| test_13_v1b | PASS |  | 0 | 17.6 | 40000 |
| test_13_v2 | PASS |  | 0 | 11.8 | 40000 |
| test_13_v20 | PASS |  | 0 | 31.4 | 40000 |
| test_13_v25 | PASS |  | 0 | 29.2 | 40000 |
| test_13_v26 | PASS |  | 0 | 9 | 40000 |
| test_13_v3 | PASS |  | 0 | 7.6 | 40000 |
| test_13_v5 | PASS |  | 0 | 10.2 | 40000 |
| test_13_v6 | PASS |  | 0 | 11.1 | 40000 |
| test_13_v7 | PASS |  | 0 | 20.1 | 40000 |
| test_13_v8 | PASS |  | 0 | 20.4 | 40000 |
| test_13_v9 | PASS |  | 0 | 5.5 | 40000 |
| test_13b_v1 | PASS |  | 0 | 5.7 | 40000 |
| test_13b_v2 | PASS |  | 0 | 9 | 40000 |
| test_13b_v3 | PASS |  | 0 | 10.8 | 40000 |
| test_13b_v4 | PASS |  | 0 | 7 | 40000 |
| test_13b_v5 | PASS |  | 0 | 7.4 | 40000 |
| test_13b_v6 | PASS |  | 0 | 10.2 | 40000 |
| test_13b_v7 | PASS |  | 0 | 7.2 | 40000 |
| test_13b_v8 | PASS |  | 0 | 6 | 40000 |
| test_13b_v9 | PASS |  | 0 | 5.3 | 40000 |
| test_13c_v1 | PASS |  | 0 | 3.7 | 40000 |
| test_13c_v3 | PASS |  | 0 | 3.3 | 40000 |
| test_13c_v5 | PASS |  | 0 | 3.3 | 40000 |
| test_13c_v7 | PASS |  | 0 | 3.7 | 40000 |
| test_13c_v8 | PASS |  | 0 | 4.9 | 40000 |
| test_13c_v9 | PASS |  | 0 | 6.3 | 40000 |
| test_16a | PASS |  | 0 | 37.5 | 40000 |
| test_2_a1_attack | PASS |  | 0 | 261.5 | 95000 |
| test_2_a1_bot_vs_bot | PASS |  | 0 | 842.2 | 116000 |
| test_2_a1_economy | PASS |  | 0 | 113.9 | 40000 |
| test_2_a1_rules | PASS |  | 0 | 180.9 | 40000 |
| test_2_g1 | PASS |  | 0 | 17.5 | 40000 |
| test_2_g2 | PASS |  | 0 | 15.3 | 40000 |
| test_2_g3 | PASS |  | 0 | 18.7 | 40000 |
| test_2_s1 | PASS |  | 0 | 40.6 | 40000 |
| test_2_s2 | PASS |  | 0 | 26.5 | 40000 |
| test_2_s3 | PASS |  | 0 | 44.3 | 40000 |
| test_2_u1 | PASS |  | 0 | 27.1 | 40000 |
| test_20_a2 | PASS |  | 0 | 393.6 | 60000 |
| test_20_a3 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 459.2 | 80000 |
| test_20_v0 | PASS |  | 0 | 4.4 | 40000 |
| test_3_a1 | PASS |  | 0 | 31.1 | 40000 |
| test_3_g1 | PASS |  | 0 | 28.2 | 40000 |
| test_3_g2a | PASS |  | 0 | 41.2 | 40000 |
| test_3_g2b | PASS |  | 0 | 16.3 | 40000 |
| test_3_s1 | PASS |  | 0 | 23.2 | 40000 |
| test_3_u1 | PASS |  | 0 | 51.3 | 40000 |
| test_3_u3 | PASS |  | 0 | 32.5 | 40000 |
| test_4_a1 | PASS |  | 0 | 42.8 | 40000 |
| test_4_g1 | PASS |  | 0 | 20.5 | 40000 |
| test_4_g2 | PASS |  | 0 | 20.4 | 40000 |
| test_4_i1 | PASS |  | 0 | 16.3 | 40000 |
| test_4_i2 | PASS |  | 0 | 18.4 | 40000 |
| test_4_s1 | PASS |  | 0 | 23.3 | 40000 |
| test_4_u1a | PASS |  | 0 | 30.7 | 40000 |
| test_4_u1b | PASS |  | 0 | 52.9 | 40000 |
| test_5_s1 | PASS |  | 0 | 25.3 | 40000 |
| test_5_u1 | PASS |  | 0 | 30.3 | 40000 |
| test_6_a1 | PASS |  | 0 | 87.6 | 40000 |
| test_6_b2 | PASS |  | 0 | 26.9 | 40000 |
| test_6_s1 | PASS |  | 0 | 25.7 | 40000 |
| test_6_s2 | PASS |  | 0 | 22.3 | 40000 |
| test_6_u1 | PASS |  | 0 | 14.6 | 40000 |
| test_6_u2 | PASS |  | 0 | 23.6 | 40000 |
| test_6_u3 | PASS |  | 0 | 22.5 | 40000 |
| test_7_a1 | PASS |  | 0 | 136.2 | 40000 |
| test_7_g1 | PASS |  | 0 | 19 | 40000 |
| test_7_g2 | PASS |  | 0 | 15 | 40000 |
| test_7_g3 | PASS |  | 0 | 19.2 | 40000 |
| test_7_i1 | PASS |  | 0 | 20.8 | 40000 |
| test_7_s1 | PASS |  | 0 | 25.2 | 40000 |
| test_7_u1 | PASS |  | 0 | 26 | 40000 |
| test_8_a1 | PASS |  | 0 | 2001.2 | 200000 |
| test_8_a2 | PASS |  | 0 | 1047.5 | 100000 |
| test_8_b3 | PASS |  | 0 | 593.7 | 95000 |
| test_8_g1 | PASS |  | 0 | 105.3 | 40000 |
| test_8_g2 | PASS |  | 0 | 47.8 | 40000 |
| test_8_i1 | PASS |  | 0 | 40.3 | 40000 |
| test_8_s1 | PASS |  | 0 | 37.4 | 40000 |
| test_8_s2 | PASS |  | 0 | 142.9 | 40000 |
| test_8_u1 | PASS |  | 0 | 28.3 | 40000 |
| test_8_u2 | PASS |  | 0 | 26 | 40000 |
| test_9_c1 | PASS |  | 0 | 9.4 | 40000 |
| test_9_c10 | PASS |  | 0 | 40.3 | 40000 |
| test_9_c11 | PASS |  | 0 | 659.6 | 95000 |
| test_9_c2 | PASS |  | 0 | 43 | 40000 |
| test_9_c3 | PASS |  | 0 | 241.2 | 40000 |
| test_9_c4 | PASS |  | 0 | 599.9 | 40000 |
| test_9_c5 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 142.6 | 40000 |
| test_9_c6 | PASS |  | 0 | 125.5 | 40000 |
| test_9_c7 | PASS |  | 0 | 78.8 | 40000 |
| test_9_c8 | PASS |  | 0 | 358.9 | 40000 |
| test_9_c9 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 1013.5 | 150000 |
| test_9_v1 | PASS |  | 0 | 254.8 | 40000 |
| test_9_v2 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 220.1 | 40000 |
| test_9_v3 | PASS |  | 0 | 250 | 40000 |
| test_9_v4 | PASS |  | 0 | 125.9 | 40000 |
| test_9_v5 | PASS |  | 0 | 115.8 | 40000 |
| test_9_v6 | PASS |  | 0 | 54.2 | 40000 |
| test_a_8 | PASS |  | 0 | 54.7 | 40000 |
| test_a_9 | PASS |  | 0 | 27.3 | 40000 |
| test_a17 | PASS |  | 0 | 35.5 | 40000 |
| test_a2_10 | PASS |  | 0 | 43.8 | 40000 |
| test_a2_3 | PASS |  | 0 | 71.8 | 40000 |
| test_a2_4 | PASS |  | 0 | 34 | 40000 |
| test_a2_5 | PASS |  | 0 | 18.1 | 40000 |
| test_a2_6 | PASS |  | 0 | 17.7 | 40000 |
| test_a2_7 | PASS |  | 0 | 25.3 | 40000 |
| test_a2_8 | PASS |  | 0 | 25.8 | 40000 |
| test_a2_9 | PASS |  | 0 | 29.1 | 40000 |
| test_a5 | PASS |  | 0 | 27.9 | 40000 |
| test_art_lab | **FAIL** (assert) | FAIL line | 0 | 58.1 | 40000 |
| test_art_lab_calibration | **FAIL** (assert) | FAIL line | 0 | 229.6 | 40000 |
| test_audio_lab | PASS |  | 0 | 125.3 | 40000 |
| test_balance_lab | PASS |  | 0 | 98 | 40000 |
| test_bot_lab | PASS |  | 0 | 116.6 | 40000 |
| test_caravan_pop | PASS |  | 0 | 95.5 | 40000 |
| test_data_lab | PASS |  | 0 | 44 | 40000 |
| test_fix_groups | PASS |  | 0 | 14.3 | 40000 |
| test_fix_minimap_click | PASS |  | 0 | 15 | 40000 |
| test_kit_team_color | PASS |  | 0 | 20.9 | 40000 |
| test_lead_item_passives | PASS |  | 0 | 22.7 | 40000 |
| test_m7_s1 | PASS |  | 0 | 20.2 | 40000 |
| test_m7_s2 | PASS |  | 0 | 73.9 | 40000 |
| test_m7_s3 | PASS |  | 0 | 11.3 | 40000 |
| test_m7_u1 | PASS |  | 0 | 17.3 | 40000 |
| test_map_lab | PASS |  | 0 | 57.4 | 40000 |
| test_map_p1 | PASS |  | 0 | 20.1 | 40000 |
| test_map_p3 | PASS |  | 0 | 5.5 | 40000 |
| test_perf_lab | PASS |  | 0 | 11.9 | 40000 |
| test_replay_lab | **FAIL** (assert) | FAIL line; no PASS line | 0 | 534.9 | 40000 |
| test_tool_cine | PASS |  | 0 | 9.2 | 40000 |
| test_tool_cine_runtime | PASS |  | 0 | 117.3 | 40000 |
| test_tool_lens | PASS |  | 0 | 135.1 | 40000 |
| test_tool_voice_forge | PASS |  | 0 | 43.5 | 40000 |
| test_tool_world_forge | PASS |  | 0 | 10.7 | 40000 |
| test_ui_lab | PASS |  | 0 | 4.1 | 40000 |
| test_ui_voice_hold | PASS |  | 0 | 213.2 | 40000 |
| test_ux_1 | PASS |  | 0 | 15 | 40000 |
| test_visual_diff_lab | PASS |  | 0 | 30.8 | 40000 |

## Unique errors
| # | Sev | New | Location | Owner | Count | Tests | Message |
|---|---|---|---|---|---|---|---|
| 1 | WARN | NEW | (no frame) | lab group A (visual) (engine error, no script frame) | 1 | test_art_lab | ART LAB ERROR: sweep=bogus: use all or a comma list of ["fire", "ice", "nature", "shadow", "neutral"] |

## Gone vs the previous run (baseline-2026-09-27-partial): fixed, or their test did not run this time
- Invalid call. Nonexistent 'float' constructor. @ res://tests/test_13c_v1.gd::_run
- Invalid call. Nonexistent 'float' constructor. @ res://tests/test_13_v13.gd::_run

## INFO (known exit noise, never FAIL)
- N ObjectDB instances were leaked at exit (run with `--verbose` for details). - x128 in 128 tests
- N resources still in use at exit (run with --verbose for details). - x128 in 128 tests
- N RID of type "CanvasItem" was leaked. - x1 in 1 tests
- N RIDs of type "CanvasItem" were leaked. - x1 in 1 tests

## Fix-agent briefs (one per owner; the lead's rule: any failure -> launch a fix agent)

### ai-coder (0 errors, 2 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-2026-09-27) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Failed tests:
- test_12_a1: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 12.A1: 2 problem(s)
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-2026-09-27\error_lab\logs\test_12_a1.log):
      [4:57] SCOUT next (-48, 48)
      [4:58] SQUAD 3 units to Rookwatch
      [5:16] SQUAD back: Rookwatch done
      [5:26] SQUAD 3 units to Millwatch
    finished after 46807 frames
    NOTE normal: 1 rule-7 attacks (pop capped)
    NOTE hard: deer shots 0
    ERROR normal: map-fill median 0.127 ms per tick (limit 0.10)
    ERROR hard: map-fill median 0.115 ms per tick (limit 0.10)
    FAIL 12.A1: 2 problem(s)
- test_20_a3: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 20.A3: bot 0 median think 1.621 ms > 1.5 ms
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-2026-09-27\error_lab\logs\test_20_a3.log):
      attack blocks (ticks): { "no army": 211, "pop": 169, "group out": 93, "strength": 47, "defending": 86, "retreat": 17, "rally": 23 }
      sub (avg ms/max ms): scan.units 0.35/18.3
    bot 0 think: median 1.621 ms, avg 1.740 ms, p95 3.022 ms, max 9.277 ms at 299 s
    bot 0 (fire): 2 attacks, first 389 s, median 1.621 ms, max 9.277 ms
    bot 1 think: median 1.751 ms, avg 1.980 ms, p95 3.071 ms, max 42.699 ms at 215 s
    bot 1 (shadow): 1 attacks, first 632 s, median 1.751 ms, max 42.699 ms
    match: over true at 639 s, winner 0
      bot 0 median think 1.621 ms > 1.5 ms
      bot 1 median think 1.751 ms > 1.5 ms
    FAIL 20.A3: bot 0 median think 1.621 ms > 1.5 ms
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play" -s tests/test_12_a1.gd --fixed-fps 60 --quit-after 60000
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play" -s tests/test_20_a3.gd --fixed-fps 60 --quit-after 80000
Done when: tools\error_lab\error_lab.ps1 -Tests test_12_a1,test_20_a3 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### lab group A (visual) (0 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-2026-09-27) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Failed tests:
- test_art_lab: assert (FAIL line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL B4t Triangles: 2534
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-2026-09-27\error_lab\logs\test_art_lab.log):
      diff: headless focus=B4 0.7 s vs full 1.7 s
    ART LAB SWEEP v3 neutral: 1 assets (neutral 1) [headless: budgets only]
    ART LAB mirefang (unit / creature, neutral) -> user://art_lab_test/army/assets/mirefang [headless: no renders]
    ART LAB mirefang: PASS quality 98 (0 FAIL, 0 WARN, 15 PASS) in 0 s -> user://art_lab_test/army/assets/mirefang/scorecard.md
    ART LAB mirefang: vs previous run quality 98 -> 98 (+0); worse: none; better: 0
    ART LAB BATCH 1 / 1: mirefang PASS 98 (0.5 s)
    ART LAB SWEEP v3 done: 1 assets, 0 FAIL, 0 pairs read alike, batch 1 s (0.6 s / asset), silhouettes 0 s (0 models), total 1 s -> user://art_lab_test/army/army.md, user://art_lab_test/army_backlog.md
    ART LAB SWEEP backlog rebuilt from 1 scorecards, 0 pairs -> user://art_lab_test/army_backlog.md
    ART LAB ERROR: sweep=bogus: use all or a comma list of ["fire", "ice", "nature", "shadow", "neutral"]
    PASS art_lab
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play" -s tests/test_art_lab.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_art_lab -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### lab group B (simulation) (0 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-2026-09-27) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Failed tests:
- test_replay_lab: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL replay_lab: script replay does not match ({"diff":["pos: [11626.0,-10939.0,0.0] vs [11619.0,-10870.0,0.0]"],"f":900.0,"t":15.0}) | bot-vs-bot seed 3 is not deterministic: first different checkpoint 600 (36 vs 36 checkpoints) | bot replay from file does not match ({"diff":["pos: [8853.0,-8846.0,0.0] vs [8846.0,-8846.0,0.0]"],"f":600.0,"t":10.0})
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-2026-09-27\error_lab\logs\test_replay_lab.log):
    REPLAY_LAB bots_b: {"abs_path":"C:/Users/elzzo/AppData/Roaming/Godot/app_userdata/Four Wizards RTS/replay_lab_test/bots_b.replay","frame":10800.0,"hash":"422bcf710ff10c06a83beb5eaf27bf2b","mode":"bots","ok":true,"path":"user://replay_lab_test/bots_b.replay","real_s":81.2,"reason":"time"}
    REPLAY_LAB script_rec: {"abs_path":"C:/Users/elzzo/AppData/Roaming/Godot/app_userdata/Four Wizards RTS/replay_lab_test/script.replay","frame":10800.0,"hash":"6dfcbd4ca5626cd909a04e963bae136c","mode":"script","ok":true,"path":"user://replay_lab_test/script.replay","real_s":77.4,"reason":"time"}
    REPLAY_LAB bots_a: {"abs_path":"C:/Users/elzzo/AppData/Roaming/Godot/app_userdata/Four Wizards RTS/replay_lab_test/bots_a.replay","frame":10800.0,"hash":"25df35045edae08f7c068e92d9f7f687","mode":"bots","ok":true,"path":"user://replay_lab_test/bots_a.replay","real_s":84.2,"reason":"time"}
    REPLAY_LAB script_play: {"checks":35.0,"checks_ok":2.0,"divergence":{"diff":["pos: [11626.0,-10939.0,0.0] vs [11619.0,-10870.0,0.0]"],"f":900.0,"t":15.0},"end_match":false,"file_checks":35.0,"file_end_frame":10800.0,"frame":10800.0,"hash":"d2578ecafdecda850513c054e66202c2","mode":"play","ok":false,"partial":false,"partial_ok":false,"real_s":77.9,"reason":"end_frame","recorded_end_frame":10800.0,"recorded_hash":"6dfcbd4ca5626cd909a04e963bae136c"}
    REPLAY_LAB bots_play: {"checks":35.0,"checks_ok":1.0,"divergence":{"diff":["pos: [8853.0,-8846.0,0.0] vs [8846.0,-8846.0,0.0]"],"f":600.0,"t":10.0},"end_match":false,"file_checks":35.0,"file_end_frame":10800.0,"frame":10800.0,"hash":"750c506a2b1c45c5f21973eb0111e233","mode":"play","ok":false,"partial":false,"partial_ok":false,"real_s":85.1,"reason":"end_frame","recorded_end_frame":10800.0,"recorded_hash":"25df35045edae08f7c068e92d9f7f687"}
    REPLAY_LAB bots diverge at frame 600: pos [8853.0,-8846.0,0.0] vs [8846.0,-8853.0,0.0]
    REPLAY_LAB took 523 s
    FAIL replay_lab: script replay does not match ({"diff":["pos: [11626.0,-10939.0,0.0] vs [11619.0,-10870.0,0.0]"],"f":900.0,"t":15.0}) | bot-vs-bot seed 3 is not deterministic: first different checkpoint 600 (36 vs 36 checkpoints) | bot replay from file does not match ({"diff":["pos: [8853.0,-8846.0,0.0] vs [8846.0,-8846.0,0.0]"],"f":600.0,"t":10.0})
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play" -s tests/test_replay_lab.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_replay_lab -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_10_c6 (0 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-2026-09-27) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Failed tests:
- test_10_c6: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 10.C6: caravan pop (got 0, want 1)
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-2026-09-27\error_lab\logs\test_10_c6.log):
      x caravan pop (got 0, want 1)
    FAIL 10.C6: caravan pop (got 0, want 1)
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play" -s tests/test_10_c6.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_10_c6 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_10_c7 (0 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-2026-09-27) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Failed tests:
- test_10_c7: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 10.C7: 1 check(s) failed
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-2026-09-27\error_lab\logs\test_10_c7.log):
      - caravan tooltip 'Caravan  [Z]
    Cost 75 crystals ? Pop 0 ? 20 s
    Trades with a post and brings gold back. Max 6.'
    FAIL 10.C7: 1 check(s) failed
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play" -s tests/test_10_c7.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_10_c7 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_9_c5 (0 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-2026-09-27) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Failed tests:
- test_9_c5: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL timing: brains + senses 112.8 us per frame (< 100)
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-2026-09-27\error_lab\logs\test_9_c5.log):
    ok   R8 Mender follows the 5-soldier group, goal 4.0 m behind its centre
    ok   Mender stands on the side away from the enemy (toward home)
    ok   R1 fallen: intent Fallen
    ok   a real Champion creates its ChampionBrain child
    ok   real Champion takes a real Explore flag (place: '', intent Scouting bounty)
    ok   real Champion walks to it and is paid (purse 50 -> 75)
    timing: 200 units, 6 champions: brains 24723.0 us (120 ticks), senses 42938.0 us (40 passes) over 600 frames
    FAIL timing: brains + senses 112.8 us per frame (< 100)
    ---- 43 checks, 1 failed
    FAIL 9.C5: timing: brains + senses 112.8 us per frame (< 100)
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play" -s tests/test_9_c5.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_9_c5 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_9_c9 (0 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-2026-09-27) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Failed tests:
- test_9_c9: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 9.C9: hard: champion rule median 0.184 ms per tick (limit 0.10)
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-2026-09-27\error_lab\logs\test_9_c9.log):
      [9:10] BOUNTY B4 Explore 25 on (-23, 9) (stakes 100 + 25 <= 1286 of 3214 spare essence)
      [9:10] BOUNTY B1 Guard 50 on Gloom Hall (stakes 0 + 50 <= 1240 of 3101 spare essence)
      [9:11] BOUNTY B2 Hunt 100 on Cinder Hand (stakes 50 + 100 <= 1221 of 3052 spare essence)
      [9:11] BOUNTY B7 Guard 50 on Gloom Hall (stakes 150 + 50 <= 1181 of 2952 spare essence)
      [9:14] BOUNTY B1 Guard 50 on Gloom Hall (stakes 0 + 50 <= 1260 of 3150 spare essence)
      [9:15] BOUNTY B3 Hunt 150 on Vessa (stakes 50 + 150 <= 1240 of 3101 spare essence)
    normal: hires [&"coin_cutter", &"oathwall"] at ["3:12", "4:35"], roster max 2, flags 0
    easy: hires [&"oathwall"] at ["7:44"], roster max 1, flags []
    hard: hires ["coin_cutter", "mender", "wayfinder"] at ["2:08", "3:50", "6:02"], roster max 3, flags ["B1@8:58", "B7@9:00", "B4@9:10", "B1@9:10", "B2@9:11", "B7@9:11", "B1@9:14", "B3@9:15"]
    FAIL 9.C9: hard: champion rule median 0.184 ms per tick (limit 0.10)
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play" -s tests/test_9_c9.gd --fixed-fps 60 --quit-after 150000
Done when: tools\error_lab\error_lab.ps1 -Tests test_9_c9 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_art_lab_calibration (0 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-2026-09-27) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Failed tests:
- test_art_lab_calibration: assert (FAIL line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL B4 Vertices: 20663 (biggest: Merged 19645, Merged 253, Merged 229, Merged 215)
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-2026-09-27\error_lab\logs\test_art_lab_calibration.log):
      deer                       PASS q  98.7 band 95-100    0.1 s
      frost_dragon               PASS q  98.9 band 95-100    1.7 s
      plant_green_shade          PASS q  99.3 band 79-88     0.0 s
      plant_glow40_frost_dragon  PASS q  98.8 band 89-95     0.1 s
      plant_verts20k_shade       FAIL q  94.3 band 91-98     0.1 s  FAIL B4
      plant_float_deer           FAIL q  84.4 band 87-94     0.0 s  FAIL R9
      plant_permat_dusk_steed    FAIL q  89.0 band 86-92     0.1 s  FAIL B9
      plant_team_dusk_steed      PASS q  98.4 band 91-97     0.1 s
    ART LAB BATCH done: 12 assets in 4.8 s (0.4 s / asset; first 0.4 s, then 0.3 s / asset)
    PASS art_lab_calibration (12 cases in band, headless: render checks not judged, 5 s)
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play" -s tests/test_art_lab_calibration.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_art_lab_calibration -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### tech-artist (0 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-2026-09-27) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Failed tests:
- test_9_v2: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 9.v2: part below the ground (-0.01)
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-2026-09-27\error_lab\logs\test_9_v2.log):
    INFO 9.v2: authored 25, draw instances 10 + 2 particle systems, lights 0, vertices 2467, materials 5
    FAIL 9.v2: part below the ground (-0.01)
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play" -s tests/test_9_v2.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_9_v2 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### lab group A (visual) (engine error, no script frame) (1 errors, 0 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-2026-09-27) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [WARN, NEW] (no frame) - ART LAB ERROR: sweep=bogus: use all or a comma list of ["fire", "ice", "nature", "shadow", "neutral"] - x1 in: test_art_lab
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play" -s tests/test_art_lab.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_art_lab -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```
