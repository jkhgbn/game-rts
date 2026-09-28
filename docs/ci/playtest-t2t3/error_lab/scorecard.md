# Error Lab scorecard: ci-playtest-t2t3

2026-09-27 21:46 - lab v1.2 - 262 tests (53 failed) - project `C:\Users\elzzo\Documents\four-wizards-rts-play2` - logs: `C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs`

## Result: **FAIL** - score **0 / 100**

46 unique FAIL errors - 3 unique WARN errors - 4 INFO (exit noise) - 48 NEW (not in the last 10 history rows) - previous run ci-playtest-2026-09-27: FAIL 0

Score = 100 - 8 per unique FAIL error - 3 per unique WARN error - 10 per failed test (min 0).

## Improve next
1. **tests/test_10_a3.gd** failed: **assert** (exit 1; FAIL line; no PASS line) - owner **ai-coder**. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
2. **tests/test_10_c8.gd** failed: **assert** (FAIL line; no PASS line) - owner **task agent of test_10_c8**. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
3. **res://scripts/ui/hud.gd:119** (FAIL, NEW) - owner **ui-coder**: Parse Error: Identifier "IdleWorkerButton" not declared in the current scope. _(x144 in 36 tests: test_8_u2, test_9_c11, test_9_c3, test_9_c5 +32 more)_

## By owner (who has work)
| Owner | FAIL errors | WARN errors | Failed tests | Tests to re-run |
|---|---|---|---|---|
| ui-coder | 11 | 0 | test_4_u1a (assert), test_8_u1 (assert), test_8_u2 (assert), test_m7_u1 (assert) | test_8_u2, test_9_c11, test_9_c3, test_9_c5, test_9_c6 +33 more |
| systems-coder | 7 | 0 | test_2_s1 (assert), test_2_s3 (assert), test_7_s1 (assert), test_8_s1 (assert) +2 more | test_9_c11, test_9_c3, test_9_c5, test_9_c9, test_a2_3 +33 more |
| ai-coder | 2 | 0 | test_10_a3 (assert), test_12_a1 (assert), test_20_a3 (assert) | test_8_u2, test_m7_s1, test_m7_s2, test_tool_voice_forge, test_10_a3 +2 more |
| lab group A (visual) | 3 | 0 | test_ui_lab (script error) | test_ui_lab |
| tech-artist | 0 | 0 | test_12_v20 (assert), test_12_v27 (assert), test_13_v2 (assert), test_13_v6 (assert) | test_12_v20, test_12_v27, test_13_v2, test_13_v6 |
| task agent of test_9_c8 | 2 | 0 | test_9_c8 (assert) | test_9_c8 |
| task agent of test_ui_minimap_zoom | 2 | 0 | test_ui_minimap_zoom (assert) | test_ui_minimap_zoom |
| task agent of test_unit_dances | 2 | 0 | test_unit_dances (assert) | test_unit_dances |
| task agent of test_ux_1 | 2 | 0 | test_ux_1 (assert) | test_ux_1 |
| map_lab owner (lab) | 1 | 0 | test_map_lab (assert) | test_map_lab |
| task agent of test_9_c3 | 1 | 0 | test_9_c3 (assert) | test_9_c3 |
| task agent of test_9_c6 | 1 | 0 | test_9_c6 (assert) | test_9_c6 |
| task agent of test_9_c7 | 1 | 0 | test_9_c7 (assert) | test_9_c7 |
| task agent of test_a2_3 | 1 | 0 | test_a2_3 (assert) | test_a2_3 |
| task agent of test_caravan_pop | 1 | 0 | test_caravan_pop (assert) | test_caravan_pop |
| task agent of test_fix_groups | 1 | 0 | test_fix_groups (assert) | test_fix_groups |
| task agent of test_fix_minimap_click | 1 | 0 | test_fix_minimap_click (assert) | test_fix_minimap_click |
| task agent of test_lead_item_passives | 1 | 0 | test_lead_item_passives (assert) | test_lead_item_passives |
| task agent of test_map_p1 | 1 | 0 | test_map_p1 (assert) | test_map_p1 |
| task agent of test_sound_plan | 1 | 0 | test_sound_plan (assert) | test_sound_plan |
| task agent of test_str_int | 1 | 0 | test_str_int (assert) | test_str_int |
| task agent of test_unit_voice | 1 | 0 | test_unit_voice (assert) | test_unit_voice |
| lab group B (simulation) | 0 | 0 | test_bot_lab (assert), test_replay_lab (assert) | test_bot_lab, test_replay_lab |
| task agent of test_a2_9 | 1 | 0 |  | test_a2_9 |
| task agent of test_tool_voice_forge | 1 | 0 |  | test_tool_voice_forge |
| task agent of test_10_c8 | 0 | 0 | test_10_c8 (assert) | test_10_c8 |
| task agent of test_11_c4 | 0 | 0 | test_11_c4 (assert) | test_11_c4 |
| task agent of test_12_c7 | 0 | 0 | test_12_c7 (assert) | test_12_c7 |
| task agent of test_12_c9 | 0 | 0 | test_12_c9 (assert) | test_12_c9 |
| task agent of test_6_b2 | 0 | 0 | test_6_b2 (assert) | test_6_b2 |
| task agent of test_9_c11 | 0 | 0 | test_9_c11 (assert) | test_9_c11 |
| task agent of test_9_c5 | 0 | 0 | test_9_c5 (assert) | test_9_c5 |
| task agent of test_9_c9 | 0 | 0 | test_9_c9 (assert) | test_9_c9 |
| task agent of test_bowmen | 0 | 0 | test_bowmen (assert) | test_bowmen |
| task agent of test_new_units_12 | 0 | 0 | test_new_units_12 (assert) | test_new_units_12 |
| task agent of test_pop_200 | 0 | 0 | test_pop_200 (assert) | test_pop_200 |
| task agent of test_t3 | 0 | 0 | test_t3 (assert) | test_t3 |
| task agent of test_tiers | 0 | 0 | test_tiers (assert) | test_tiers |
| task agent of test_ui_building_groups | 0 | 0 | test_ui_building_groups (assert) | test_ui_building_groups |
| task agent of test_ui_restart_hint | 0 | 0 | test_ui_restart_hint (assert) | test_ui_restart_hint |
| task agent of test_ui_train_queue | 0 | 0 | test_ui_train_queue (assert) | test_ui_train_queue |
| ai-coder (engine error, no script frame) | 0 | 3 |  | test_2_a1_bot_vs_bot, test_10_a3 |

## Failed tests (diagnosis + log tail)

### test_10_a3 - assert - owner ai-coder
exit 1; FAIL line; no PASS line; 1079.7 s, cap 150000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 10.A3: 2 error(s)`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_10_a3.log):
```text
  [10:38] TRADE route Lantern Wharf (15 gold / trip): Saltgate unsafe
  [10:59] TRADE buys Tempered Steel (350 gold, 76 left)
  [11:23] TRADE buys Iron-shod Axles (150 gold, 57 left)
  [11:39] TRADE route Saltgate (28 gold / trip): default
  [11:39] TRADE 3 caravan(s) far to Heron Ford (154 gold / trip; str 1305 vs seen 0)
  [11:57] TRADE hires outriders (120 gold): a caravan was lost
  [12:04] BOUNTY B5 Escort 50 on Caravan (stakes 50 + 50 <= 640 of 1599 spare essence)
  [12:09] TRADE far caravans called home: far road unsafe
  [12:23] TRAIN Caravan (5 caravans + 1 queued, target 6, crystals left 100)
  [12:37] TRADE buys Quilted Gambesons (350 gold, 65 left)
  [12:37] TRADE buys Masons' Charter (350 gold, 60 left)
  [12:38] CHAMPION hire coin_cutter (Sable Quint) #3 in gold: 325 gold + 125 essence, from (-15, -15)
ERROR: normal: the Coin-Cutter ignored a looting Magpie 8 s free / 8 s in all (intent Raiding)
ERROR: hard: no B7 Guard flag after a raid
FAIL 10.A3: 2 error(s)
```

### test_10_c8 - assert - owner task agent of test_10_c8
FAIL line; no PASS line; 63.1 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 10.c8: top bar rect [P: (479.5, 8.0), S: (641.0, 40.0)], expected (488, 8, 624, 40) (step 3)`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_10_c8.log):
```text
FAIL 10.c8: top bar rect [P: (479.5, 8.0), S: (641.0, 40.0)], expected (488, 8, 624, 40) (step 3)
```

### test_11_c4 - assert - owner task agent of test_11_c4
FAIL line; no PASS line; 37.6 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 11.c4: 3 problem(s) (step 3)`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_11_c4.log):
```text
  - ability line 0 height 18.0
  - ability line 1 height 18.0
  - ability line 2 height 18.0
FAIL 11.c4: 3 problem(s) (step 3)
```

### test_12_a1 - assert - owner ai-coder
FAIL line; no PASS line; 403.8 s, cap 60000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 12.A1: 2 problem(s)`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_12_a1.log):
```text
  [4:40] SCOUT next (-24, 36) via (12, 49)
  [4:43] SQUAD 3 units to Rookwatch
  [4:47] SCOUT next (-24, 48)
  [4:48] SCOUT next (-36, 48)
  [4:49] SCOUT next (-48, 48)
  [4:50] CREEP over (cleared): Gloomcap Hollow SE
  [5:02] SQUAD back: Rookwatch done
  [5:09] SCOUT home
  [5:11] SQUAD 3 units to Millwatch
  [5:37] SQUAD back: Millwatch done
finished after 46807 frames
NOTE hard: deer shots 1
ERROR normal: map-fill median 0.141 ms per tick (limit 0.10)
ERROR hard: map-fill median 0.123 ms per tick (limit 0.10)
FAIL 12.A1: 2 problem(s)
```

### test_12_c7 - assert - owner task agent of test_12_c7
FAIL line; no PASS line; 28.7 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 12.C7: blessing chip rects [P: (958.0, 54.0), S: (144.0, 23.0)] [P: (958.0, 78.0), S: (144.0, 23.0)]`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_12_c7.log):
```text
  x blessing chip rects [P: (958.0, 54.0), S: (144.0, 23.0)] [P: (958.0, 78.0), S: (144.0, 23.0)]
  note: hint 701 px at font 22 (pushed under the help panel when > 636)
FAIL 12.C7: blessing chip rects [P: (958.0, 54.0), S: (144.0, 23.0)] [P: (958.0, 78.0), S: (144.0, 23.0)]
```

### test_12_c9 - assert - owner task agent of test_12_c9
FAIL line; no PASS line; 16 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 12.C9: 12 problem(s)`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_12_c9.log):
```text
147 checks
  - bleakbow projectile_speed: got 26.000, want 25.000
  - briar_roc projectile_speed: got 22.000, want 25.000
  - cinder_arbalest projectile_speed: got 32.000, want 25.000
  - frost_mortar projectile_speed: got 18.000, want 25.000
  - frostbow projectile_speed: got 30.000, want 25.000
  - hexweaver projectile_speed: got 24.000, want 25.000
  - hoarlight_magebow projectile_speed: got 28.000, want 25.000
  - pyre_adept projectile_speed: got 24.000, want 25.000
  - scorchbow projectile_speed: got 26.000, want 25.000
  - stormbottle_genie projectile_speed: got 40.000, want 25.000
  - thistle_darter projectile_speed: got 26.000, want 25.000
  - Unit.MAX_UNIT_RADIUS 1.10 >= 1.20
FAIL 12.C9: 12 problem(s)
```

### test_12_v20 - assert - owner tech-artist
FAIL line; no PASS line; 4.1 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 12.v20: head tossed up at the strike (-12.0)`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_12_v20.log):
```text
  Root/Mount/LegBL/Merged (MeshInstance3D): 186 vertices
  Root/Mount/LegBR/Merged (MeshInstance3D): 186 vertices
  Root/Mount/Quills (MeshInstance3D): 504 vertices
  Root/Mount/Merged (MeshInstance3D): 321 vertices
  Fx/Dust (GPUParticles3D): 0 vertices
  Fx/Clods (GPUParticles3D): 0 vertices
  Shadow (MeshInstance3D): 4 vertices
rest AABB top 1.211, bottom 0.000, x -0.34 .. 0.35, z -0.91 .. 1.18
walk: max fore-leg swing 29.9 deg
gore: head x windup 42.0, strike -12.0 deg, lunge z 0.27, quills 1.00 (scale y 1.34)
  FAILED: head tossed up at the strike (-12.0)
dig: head x 36.4 deg
cast: root pitch -15.0 deg, root y 0.13
death 0.6 s: root roll 82.0 deg
FAIL 12.v20: head tossed up at the strike (-12.0)
```

### test_12_v27 - assert - owner tech-artist
FAIL line; no PASS line; 4.1 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 12.v27: B's right tusk is the broken one`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_12_v27.log):
```text
A AABB top 2.22 bottom 0.020, w 1.54, l 3.78 (z -1.59 .. 2.19)
B AABB top 2.93 bottom 0.019, w 1.84, l 4.37
A body (hump) top 1.89
bristleback AABB w 0.69, h 1.21, l 2.06
right tusk top (model y) A 1.38, B 1.15
  FAILED: B's right tusk is the broken one
walk: max fore-leg swing 25.8 deg, bristles -0.12
gore: head windup 40.3, lunge z 0.41, toss -14.7
charge: head 31.7, charging true, trail true, leg swing 37.4, bristles 1.00
toss: head -23.9, charging false, tosses 1
dash: charging at 0.9 s true, stopped 6 frames after the unit stopped
bristle hide: action '', raise 0.78
hit: head -2.8, bristles 0.80
death 0.7 s: root roll 80.0 deg, root y 0.50, lowest body -0.055, lowest all -0.055, trail false
FAIL 12.v27: B's right tusk is the broken one
```

### test_13_v2 - assert - owner tech-artist
FAIL line; no PASS line; 4.1 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 13.v2: nothing below the ground at rest (-0.011)`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_13_v2.log):
```text
own materials (2): ember_boar_hide.tres, ember_boar_flame_core.tres
palette materials (9): fire_hair.tres, unit_eye_dark.tres, fire_glow.tres, fire_skin.tres, fire_flame.tres, fire_cloth.tres, fire_cloth_dark.tres, fire_bronze.tres, fire_leather.tres
rest AABB y -0.01..1.94, x -0.53..0.53, z -1.10..1.56
  FAILED: nothing below the ground at rest (-0.011)
seat (model space) (-0.004218, 1.258265, -0.174245)
walk: leg swing 24.0 deg, gallop blend 0.00
gallop: blend 1.00, bounce 0.080, seat bob 0.110, leg swing 38.0 deg, strides/s 3, tail lift 70.0 deg
hit: body flash 0.58, leg flash 0.58, root z -0.083
charge: head 20.0 deg (tusks levelled), lunge z 0.41, toss -29.2 deg, mane glow 1.00 -> 2.60
fidget: rooting head 28.7 deg, toss -14.1 deg, glow 2.01
barded: draw instances 8, vertices 6880, body surfaces 8 -> 8
team colour on the barded body: [(0.45, 0.75, 0.95, 1.0), (0.2025, 0.3375, 0.4275, 1.0)]
slot collisions: 0
death: roll -40.1 -> -86.0 deg, lying AABB y -0.03..1.04, smoulder 0.17 -> 0.03 ((1.0, 0.3, 0.05)), mane glow 0.00, finished true
FAIL 13.v2: nothing below the ground at rest (-0.011)
```

### test_13_v6 - assert - owner tech-artist
FAIL line; no PASS line; 4.2 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 13.v6: nothing below the ground at rest (-0.010)`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_13_v6.log):
```text
own materials (3): roan_courser_coat.tres, roan_courser_chestnut.tres, roan_courser_wool.tres
palette materials (11): fire_hair.tres, shadow_bone.tres, unit_eye_dark.tres, fire_fur.tres, weapon_leather.tres, weapon_brass.tres, weapon_iron.tres, fire_leather.tres, weapon_ash.tres, fire_cloth.tres, fire_cloth_dark.tres
rest AABB y -0.01..2.20, x -0.56..0.53, z -1.19..1.45
  FAILED: nothing below the ground at rest (-0.010)
body merge AABB (Mount space) [P: (-0.553781, -0.394, -0.885317), S: (1.077091, 1.0835, 1.695317)]
seat (model space) (-0.003905, 1.530416, -0.104508)
walk: leg swing 19.9 deg, gallop blend 0.00
gallop: blend 1.00, bounce 0.070, seat bob 0.082, leg swing 32.0 deg, strides/s 3, tail lift 26.0 deg
hit: body flash 0.58, leg flash 0.58, root z -0.083
charge: head 14.5 deg, lunge z 0.41, toss -29.8 deg
graze: head 49.5 deg, lifted 2.3 deg
team colour on the body: [(0.45, 0.75, 0.95, 1.0), (0.2025, 0.3375, 0.4275, 1.0)]
slot collisions: 0
death: roll -86.0 deg, lying AABB y 0.01..1.09, finished true
FAIL 13.v6: nothing below the ground at rest (-0.010)
```

### test_2_s1 - assert - owner systems-coder
FAIL line; no PASS line; 20.4 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 2.S1: fire_hearth numbers \| shadow_hovel numbers`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_2_s1.log):
```text
  hall at (-29.0, 0.0, 41.0)
FAIL 2.S1: fire_hearth numbers | shadow_hovel numbers
```

### test_2_s3 - assert - owner systems-coder
FAIL line; no PASS line; 21.9 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 2.S3: crown bonus: hp 450 / 450 mana max 188, want 450 / 450, 150`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_2_s3.log):
```text
  94 obstacles (trees, rocks, pillars), 0 without a mirror
FAIL 2.S3: crown bonus: hp 450 / 450 mana max 188, want 450 / 450, 150
```

### test_20_a3 - assert - owner ai-coder
FAIL line; no PASS line; 537.1 s, cap 80000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 20.A3: bot 0 median think 2.354 ms > 1.5 ms`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_20_a3.log):
```text
  attack blocks (ticks): { "no army": 369, "pop": 132, "defending": 327, "group out": 41, "retreat": 5 }
  sub (avg ms/max ms): scan.units 0.16/1.3
team 1: crystals 175, gathered 7320, pop 18 / 40
bot 1: ticks 875, median 2.468 ms, avg 3.378 ms, max 533.820 ms at 48 s; attacks 5 (first 238 s), stage 0, str 215 vs seen 800
  steps (median ms/avg ms/max ms@s): scan 0.362/0.36/1.4@412, train 0.244/0.94/532.3@48, pending 0.225/0.19/0.7@249, champions 0.146/0.27/41.6@277, memory 0.140/0.13/0.5@821, items 0.115/0.14/1.7@328, mapfill 0.094/0.13/0.7@769, mapfill_sense 0.094/0.10/0.3@605, trade 0.068/0.40/268.5@815, trade_sense 0.060/0.06/0.2@459, wizard 0.050/0.07/0.5@325, attack 0.047/0.06/0.4@492, economy 0.036/0.07/0.6@764, defend 0.034/0.11/1.0@556, track_workers 0.018/0.02/0.3@445, learn 0.017/0.02/0.3@256, scout 0.011/0.03/0.9@532, exchange 0.010/0.01/0.1@167, build 0.009/0.20/36.9@340, all_in 0.006/0.01/0.2@775, concede 0.004/0.00/0.0@179, retreat 0.002/0.01/0.1@503
  attack blocks (ticks): { "no army": 265, "pop": 261, "group out": 140, "strength": 10, "retreat": 40, "defending": 131, "rally": 24 }
  sub (avg ms/max ms): scan.units 0.29/1.3
bot 0 think: median 2.354 ms, avg 2.970 ms, p95 3.333 ms, max 540.938 ms at 48 s
bot 0 (fire): 0 attacks, first -1 s, median 2.354 ms, max 540.938 ms
bot 1 think: median 2.468 ms, avg 3.378 ms, p95 3.447 ms, max 533.820 ms at 48 s
bot 1 (shadow): 5 attacks, first 238 s, median 2.468 ms, max 533.820 ms
match: over true at 863 s, winner 1
  bot 0 median think 2.354 ms > 1.5 ms
  bot 1 median think 2.468 ms > 1.5 ms
FAIL 20.A3: bot 0 median think 2.354 ms > 1.5 ms
```

### test_4_u1a - assert - owner ui-coder
FAIL line; no PASS line; 23.5 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 4.u1a: top bar rect [P: (479.5, 8.0), S: (641.0, 40.0)]`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_4_u1a.log):
```text
viewport (1600.0, 900.0)
FAIL 4.u1a: top bar rect [P: (479.5, 8.0), S: (641.0, 40.0)]
```

### test_6_b2 - assert - owner task agent of test_6_b2
FAIL line; no PASS line; 19.5 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 6.B2: fire_hearth data; shadow_hovel data`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_6_b2.log):
```text
FAIL 6.B2: fire_hearth data; shadow_hovel data
```

### test_7_s1 - assert - owner systems-coder
FAIL line; no PASS line; 27.8 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 7.S1: ice_lodge is [80, 30.0, 600.0, (2, 2), 3.0, 20, 9, "Z"], spec [80, 30.0, 600.0, (2, 2), 3.0, 10, 2, "Z"]`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_7_s1.log):
```text
FAIL 7.S1: ice_lodge is [80, 30.0, 600.0, (2, 2), 3.0, 20, 9, "Z"], spec [80, 30.0, 600.0, (2, 2), 3.0, 10, 2, "Z"]
```

### test_8_s1 - assert - owner systems-coder
FAIL line; no PASS line; 38.1 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 8.S1: nature_hollow is [60, 20.0, 450.0, (2, 2), 3.0, 20, 9, "Z", &"house"], spec [60, 20.0, 450.0, (2, 2), 3.0, 10, 3, "Z", &"house"]; pop_cap_limit_for nature / fire = 200 / 200; after the Heartwood: kingdom nature, max 200, cap 20; Heartwood + 3 hollows: pop cap 80, not 50; 4th hollow: ''; pop cap above the Nature cap: 100; pop cap after losing the extra hollow: 80; Fire cap changed: max 200, cap 20`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_8_s1.log):
```text
FAIL 8.S1: nature_hollow is [60, 20.0, 450.0, (2, 2), 3.0, 20, 9, "Z", &"house"], spec [60, 20.0, 450.0, (2, 2), 3.0, 10, 3, "Z", &"house"]; pop_cap_limit_for nature / fire = 200 / 200; after the Heartwood: kingdom nature, max 200, cap 20; Heartwood + 3 hollows: pop cap 80, not 50; 4th hollow: ''; pop cap above the Nature cap: 100; pop cap after losing the extra hollow: 80; Fire cap changed: max 200, cap 20
```

### test_8_u1 - assert - owner ui-coder
FAIL line; no PASS line; 20 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 8.u1: top bar pop is '13 / 80', expected '/ 50'`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_8_u1.log):
```text
FAIL 8.u1: top bar pop is '13 / 80', expected '/ 50'
```

### test_8_u2 - assert - owner ui-coder
FAIL line; no PASS line; 14.9 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 8.U2: navigation never finished baking`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_8_u2.log):
```text
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_8_u2.gd:45)
ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_8_u2.gd:45)
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
   at: Mission01._ready (res://scripts/world/main.gd:91)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/main.gd:91)
       [1] _ready (res://scripts/world/skirmish.gd:407)
       [2] _ready (res://scripts/campaign/mission_01.gd:253)
FAIL 8.U2: navigation never finished baking
```

### test_9_c11 - assert - owner task agent of test_9_c11
FAIL line; no PASS line; 23.1 s, cap 95000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 9.C11: navigation never finished baking`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_9_c11.log):
```text
   at: GDScript::reload (res://scripts/ui/hud.gd:122)
SCRIPT ERROR: Parse Error: Identifier "IdleWorkerButton" not declared in the current scope.
   at: GDScript::reload (res://scripts/ui/hud.gd:124)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/selection_manager.gd:0)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
   at: Skirmish._ready (res://scripts/world/main.gd:91)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/main.gd:91)
       [1] _ready (res://scripts/world/skirmish.gd:407)
FAIL 9.C11: navigation never finished baking
```

### test_9_c3 - assert - owner task agent of test_9_c3
FAIL line; no PASS line; 29.3 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 9.C3: navigation never finished baking`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_9_c3.log):
```text
       [0] _initialize (res://tests/test_9_c3.gd:103)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_9_c3.gd:103)
ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_9_c3.gd:103)
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
   at: Skirmish._ready (res://scripts/world/main.gd:91)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/main.gd:91)
       [1] _ready (res://scripts/world/skirmish.gd:407)
FAIL 9.C3: navigation never finished baking
```

### test_9_c5 - assert - owner task agent of test_9_c5
FAIL line; no PASS line; 27.2 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 9.C5: navigation never finished baking`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_9_c5.log):
```text
   at: GDScript::reload (res://scripts/ui/hud.gd:122)
SCRIPT ERROR: Parse Error: Identifier "IdleWorkerButton" not declared in the current scope.
   at: GDScript::reload (res://scripts/ui/hud.gd:124)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/selection_manager.gd:0)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
   at: Skirmish._ready (res://scripts/world/main.gd:91)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/main.gd:91)
       [1] _ready (res://scripts/world/skirmish.gd:407)
FAIL 9.C5: navigation never finished baking
```

### test_9_c6 - assert - owner task agent of test_9_c6
FAIL line; no PASS line; 13.3 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 9.c6: navigation never finished baking`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_9_c6.log):
```text
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_9_c6.gd:63)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_9_c6.gd:63)
ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_9_c6.gd:63)
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
   at: _ready (res://scripts/world/main.gd:91)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/main.gd:91)
FAIL 9.c6: navigation never finished baking
```

### test_9_c7 - assert - owner task agent of test_9_c7
FAIL line; no PASS line; 13.9 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 9.c7: navigation never finished baking`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_9_c7.log):
```text
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_9_c7.gd:175)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_9_c7.gd:175)
ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_9_c7.gd:175)
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
   at: _ready (res://scripts/world/main.gd:91)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/main.gd:91)
FAIL 9.c7: navigation never finished baking
```

### test_9_c8 - assert - owner task agent of test_9_c8
FAIL line; no PASS line; 13.9 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 9.C8: navigation never finished baking`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_9_c8.log):
```text
SCRIPT ERROR: Parse Error: Identifier "IdleWorkerButton" not declared in the current scope.
   at: GDScript::reload (res://scripts/ui/hud.gd:124)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/selection_manager.gd:0)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/bounty_mode.gd:0)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://tests/test_9_c8.gd:0)
ERROR: Failed to load script "res://tests/test_9_c8.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
   at: _ready (res://scripts/world/main.gd:91)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/main.gd:91)
FAIL 9.C8: navigation never finished baking
```

### test_9_c9 - assert - owner task agent of test_9_c9
FAIL line; no PASS line; 20.2 s, cap 150000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 9.C9: navigation never finished baking`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_9_c9.log):
```text
SCRIPT ERROR: Parse Error: Identifier "IdleWorkerButton" not declared in the current scope.
   at: GDScript::reload (res://scripts/ui/hud.gd:124)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/selection_manager.gd:0)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
part 0: champion knobs, revive rule and champion strength checked
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
   at: Skirmish._ready (res://scripts/world/main.gd:91)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/main.gd:91)
       [1] _ready (res://scripts/world/skirmish.gd:407)
FAIL 9.C9: navigation never finished baking
```

### test_a2_3 - assert - owner task agent of test_a2_3
exit 1; FAIL line; no PASS line; 20.7 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL a2.3: navigation never finished baking`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_a2_3.log):
```text
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
   GDScript backtrace (most recent call first):
       [0] _process (res://tests/test_a2_3.gd:114)
ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
   GDScript backtrace (most recent call first):
       [0] _process (res://tests/test_a2_3.gd:114)
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
   at: Skirmish._ready (res://scripts/world/main.gd:91)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/main.gd:91)
       [1] _ready (res://scripts/world/skirmish.gd:407)
       [2] _process (res://tests/test_a2_3.gd:118)
FAIL a2.3: navigation never finished baking
```

### test_bot_lab - assert - owner lab group B (simulation)
FAIL line; no PASS line; 13.9 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL bot lab: fire-ice_s1.json has no 'score'`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_bot_lab.log):
```text
bot lab test: 2 match(es) started (C:/Users/elzzo/AppData/Roaming/Godot/app_userdata/Four Wizards RTS/bot_lab_test), 120 game s each
FAIL bot lab: fire-ice_s1.json has no 'score'
```

### test_bowmen - assert - owner task agent of test_bowmen
FAIL line; no PASS line; 27.7 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL bowmen: navigation never finished baking`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_bowmen.log):
```text
   at: GDScript::reload (res://scripts/ui/hud.gd:122)
SCRIPT ERROR: Parse Error: Identifier "IdleWorkerButton" not declared in the current scope.
   at: GDScript::reload (res://scripts/ui/hud.gd:124)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/selection_manager.gd:0)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
   at: Skirmish._ready (res://scripts/world/main.gd:91)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/main.gd:91)
       [1] _ready (res://scripts/world/skirmish.gd:407)
FAIL bowmen: navigation never finished baking
```

### test_caravan_pop - assert - owner task agent of test_caravan_pop
FAIL line; no PASS line; 31.4 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL caravan_pop: navigation never finished baking`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_caravan_pop.log):
```text
       [0] _initialize (res://tests/test_caravan_pop.gd:18)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_caravan_pop.gd:18)
ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_caravan_pop.gd:18)
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
   at: Skirmish._ready (res://scripts/world/main.gd:91)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/main.gd:91)
       [1] _ready (res://scripts/world/skirmish.gd:407)
FAIL caravan_pop: navigation never finished baking
```

### test_fix_groups - assert - owner task agent of test_fix_groups
FAIL line; no PASS line; 13.3 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL fix_groups: navigation never finished baking`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_fix_groups.log):
```text
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_fix_groups.gd:30)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_fix_groups.gd:30)
ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_fix_groups.gd:30)
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
   at: _ready (res://scripts/world/main.gd:91)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/main.gd:91)
FAIL fix_groups: navigation never finished baking
```

### test_fix_minimap_click - assert - owner task agent of test_fix_minimap_click
FAIL line; no PASS line; 14 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL fix_minimap_click: navigation never finished baking`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_fix_minimap_click.log):
```text
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_fix_minimap_click.gd:32)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_fix_minimap_click.gd:32)
ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_fix_minimap_click.gd:32)
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
   at: _ready (res://scripts/world/main.gd:91)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/main.gd:91)
FAIL fix_minimap_click: navigation never finished baking
```

### test_lead_item_passives - assert - owner task agent of test_lead_item_passives
FAIL line; no PASS line; 20.1 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL lead_item_passives: map never ready`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_lead_item_passives.log):
```text
       [0] _initialize (res://tests/test_lead_item_passives.gd:13)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_lead_item_passives.gd:13)
ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_lead_item_passives.gd:13)
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
   at: Skirmish._ready (res://scripts/world/main.gd:91)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/main.gd:91)
       [1] _ready (res://scripts/world/skirmish.gd:407)
FAIL lead_item_passives: map never ready
```

### test_m7_s1 - assert - owner systems-coder
FAIL line; no PASS line; 20.1 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL m7_s1: navigation never finished baking`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_m7_s1.log):
```text
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_m7_s1.gd:28)
ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_m7_s1.gd:28)
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
   at: Mission01._ready (res://scripts/world/main.gd:91)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/main.gd:91)
       [1] _ready (res://scripts/world/skirmish.gd:407)
       [2] _ready (res://scripts/campaign/mission_01.gd:253)
FAIL m7_s1: navigation never finished baking
```

### test_m7_s2 - assert - owner systems-coder
FAIL line; no PASS line; 13.2 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL m7_s2: navigation never finished baking`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_m7_s2.log):
```text
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_m7_s2.gd:26)
ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_m7_s2.gd:26)
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
   at: Mission01._ready (res://scripts/world/main.gd:91)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/main.gd:91)
       [1] _ready (res://scripts/world/skirmish.gd:407)
       [2] _ready (res://scripts/campaign/mission_01.gd:253)
FAIL m7_s2: navigation never finished baking
```

### test_m7_u1 - assert - owner ui-coder
FAIL line; no PASS line; 19 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL M7.U1: navigation never finished baking`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_m7_u1.log):
```text
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_m7_u1.gd:55)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_m7_u1.gd:55)
ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_m7_u1.gd:55)
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
   at: _ready (res://scripts/world/main.gd:91)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/main.gd:91)
FAIL M7.U1: navigation never finished baking
```

### test_map_lab - assert - owner map_lab owner (lab)
FAIL line; no PASS line; 39.5 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL map_lab: the skirmish never finished its bake`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_map_lab.log):
```text
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_map_lab.gd:27)
ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_map_lab.gd:27)
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
   at: Skirmish._ready (res://scripts/world/main.gd:91)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/main.gd:91)
       [1] _ready (res://scripts/world/skirmish.gd:407)
  - the skirmish never finished its bake
FAIL map_lab: the skirmish never finished its bake
```

### test_map_p1 - assert - owner task agent of test_map_p1
FAIL line; no PASS line; 59.8 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL MAP.P1: the skirmish never finished loading`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_map_p1.log):
```text
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_map_p1.gd:30)
ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_map_p1.gd:30)
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
   at: Skirmish._ready (res://scripts/world/main.gd:91)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/main.gd:91)
       [1] _ready (res://scripts/world/skirmish.gd:407)
  - the skirmish never finished loading
FAIL MAP.P1: the skirmish never finished loading
```

### test_new_units_12 - assert - owner task agent of test_new_units_12
FAIL line; no PASS line; 21.5 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL new_units_12: navigation never finished baking`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_new_units_12.log):
```text
   at: GDScript::reload (res://scripts/ui/hud.gd:122)
SCRIPT ERROR: Parse Error: Identifier "IdleWorkerButton" not declared in the current scope.
   at: GDScript::reload (res://scripts/ui/hud.gd:124)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/selection_manager.gd:0)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
   at: Skirmish._ready (res://scripts/world/main.gd:91)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/main.gd:91)
       [1] _ready (res://scripts/world/skirmish.gd:407)
FAIL new_units_12: navigation never finished baking
```

### test_pop_200 - assert - owner task agent of test_pop_200
FAIL line; no PASS line; 13.9 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL pop_200: navigation never finished baking`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_pop_200.log):
```text
SCRIPT ERROR: Parse Error: Identifier "IdleWorkerButton" not declared in the current scope.
   at: GDScript::reload (res://scripts/ui/hud.gd:122)
SCRIPT ERROR: Parse Error: Identifier "IdleWorkerButton" not declared in the current scope.
   at: GDScript::reload (res://scripts/ui/hud.gd:124)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/selection_manager.gd:0)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
   at: _ready (res://scripts/world/main.gd:91)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/main.gd:91)
FAIL pop_200: navigation never finished baking
```

### test_replay_lab - assert - owner lab group B (simulation)
FAIL line; no PASS line; 1503.8 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL replay_lab: timed out waiting for script_rec`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_replay_lab.log):
```text
REPLAY_LAB took 1500 s
FAIL replay_lab: timed out waiting for script_rec
```

### test_sound_plan - assert - owner task agent of test_sound_plan
FAIL line; no PASS line; 82.8 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL sound_plan: 1 problem(s)`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_sound_plan.log):
```text
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
   GDScript backtrace (most recent call first):
       [0] _process (res://tests/test_sound_plan.gd:61)
ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
   GDScript backtrace (most recent call first):
       [0] _process (res://tests/test_sound_plan.gd:61)
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
   at: _ready (res://scripts/world/main.gd:91)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/main.gd:91)
       [1] _process (res://tests/test_sound_plan.gd:62)
  - navigation never finished baking
FAIL sound_plan: 1 problem(s)
```

### test_str_int - assert - owner task agent of test_str_int
FAIL line; no PASS line; 59.5 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL str_int: map never ready`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_str_int.log):
```text
       [0] _initialize (res://tests/test_str_int.gd:29)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_str_int.gd:29)
ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
   GDScript backtrace (most recent call first):
       [0] _initialize (res://tests/test_str_int.gd:29)
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
   at: Skirmish._ready (res://scripts/world/main.gd:91)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/main.gd:91)
       [1] _ready (res://scripts/world/skirmish.gd:407)
FAIL str_int: map never ready
```

### test_t3 - assert - owner task agent of test_t3
FAIL line; no PASS line; 47.7 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL t3: navigation never finished baking`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_t3.log):
```text
   at: GDScript::reload (res://scripts/ui/hud.gd:122)
SCRIPT ERROR: Parse Error: Identifier "IdleWorkerButton" not declared in the current scope.
   at: GDScript::reload (res://scripts/ui/hud.gd:124)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/selection_manager.gd:0)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
   at: Skirmish._ready (res://scripts/world/main.gd:91)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/main.gd:91)
       [1] _ready (res://scripts/world/skirmish.gd:407)
FAIL t3: navigation never finished baking
```

### test_tiers - assert - owner task agent of test_tiers
FAIL line; no PASS line; 54.4 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL tiers: navigation never finished baking`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_tiers.log):
```text
SCRIPT ERROR: Parse Error: Identifier "IdleWorkerButton" not declared in the current scope.
   at: GDScript::reload (res://scripts/ui/hud.gd:124)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/selection_manager.gd:0)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
---- part gates
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
   at: Skirmish._ready (res://scripts/world/main.gd:91)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/main.gd:91)
       [1] _ready (res://scripts/world/skirmish.gd:407)
FAIL tiers: navigation never finished baking
```

### test_ui_building_groups - assert - owner task agent of test_ui_building_groups
FAIL line; no PASS line; 19.9 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL ui_building_groups: skirmish never started`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_ui_building_groups.log):
```text
   at: GDScript::reload (res://scripts/ui/hud.gd:122)
SCRIPT ERROR: Parse Error: Identifier "IdleWorkerButton" not declared in the current scope.
   at: GDScript::reload (res://scripts/ui/hud.gd:124)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/selection_manager.gd:0)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
   at: Skirmish._ready (res://scripts/world/main.gd:91)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/main.gd:91)
       [1] _ready (res://scripts/world/skirmish.gd:407)
FAIL ui_building_groups: skirmish never started
```

### test_ui_lab - script error - owner lab group A (visual)
no PASS line; 191.2 s, cap 40000. A script error stopped the test before its PASS line: fix the first FAIL-class error listed for this test.

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_ui_lab.log):
```text
   at: GDScript::reload (res://scripts/ui/hud.gd:119)
SCRIPT ERROR: Parse Error: Identifier "IdleWorkerButton" not declared in the current scope.
   at: GDScript::reload (res://scripts/ui/hud.gd:121)
SCRIPT ERROR: Parse Error: Identifier "IdleWorkerButton" not declared in the current scope.
   at: GDScript::reload (res://scripts/ui/hud.gd:122)
SCRIPT ERROR: Parse Error: Identifier "IdleWorkerButton" not declared in the current scope.
   at: GDScript::reload (res://scripts/ui/hud.gd:124)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://tests/test_ui_lab.gd:0)
ERROR: Failed to load script "res://tests/test_ui_lab.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
SCRIPT ERROR: Invalid call. Nonexistent function 'help_text' in base 'GDScript'.
   at: _run (res://tests/test_ui_lab.gd:139)
   GDScript backtrace (most recent call first):
       [0] _run (res://tests/test_ui_lab.gd:139)
```

### test_ui_minimap_zoom - assert - owner task agent of test_ui_minimap_zoom
FAIL line; no PASS line; 56.2 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL ui_minimap_zoom: navigation never finished baking`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_ui_minimap_zoom.log):
```text
SCRIPT ERROR: Parse Error: Identifier "IdleWorkerButton" not declared in the current scope.
   at: GDScript::reload (res://scripts/ui/hud.gd:124)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/selection_manager.gd:0)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/minimap.gd:0)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://tests/test_ui_minimap_zoom.gd:0)
ERROR: Failed to load script "res://tests/test_ui_minimap_zoom.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
   at: _ready (res://scripts/world/main.gd:91)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/main.gd:91)
FAIL ui_minimap_zoom: navigation never finished baking
```

### test_ui_restart_hint - assert - owner task agent of test_ui_restart_hint
FAIL line; no PASS line; 24.1 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL ui_restart_hint: timed out at step 1`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_ui_restart_hint.log):
```text
SCRIPT ERROR: Parse Error: Identifier "IdleWorkerButton" not declared in the current scope.
   at: GDScript::reload (res://scripts/ui/hud.gd:124)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/selection_manager.gd:0)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
   at: _ready (res://scripts/world/main.gd:91)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/main.gd:91)
hint before: Next: build an Ember Hall: select a worker, press B then X (150 crystals)
hint after: Next: train soldiers: select the Ember Hall, press Z X C V
FAIL ui_restart_hint: timed out at step 1
```

### test_ui_train_queue - assert - owner task agent of test_ui_train_queue
FAIL line; no PASS line; 27.6 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL ui_train_queue: skirmish never started`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_ui_train_queue.log):
```text
   at: GDScript::reload (res://scripts/ui/hud.gd:122)
SCRIPT ERROR: Parse Error: Identifier "IdleWorkerButton" not declared in the current scope.
   at: GDScript::reload (res://scripts/ui/hud.gd:124)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/selection_manager.gd:0)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
   at: Skirmish._ready (res://scripts/world/main.gd:91)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/main.gd:91)
       [1] _ready (res://scripts/world/skirmish.gd:407)
FAIL ui_train_queue: skirmish never started
```

### test_unit_dances - assert - owner task agent of test_unit_dances
FAIL line; no PASS line; 16.4 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL unit_dances: timed out at step 2`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_unit_dances.log):
```text
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/main.gd:91)
  flame_guard (fire) dances dance_victory, arm moved 2.86 rad
  pyre_adept (fire) dances dance_surrender, arm moved 1.52 rad
  rimeshield (ice) dances dance_random, arm moved 2.89 rad
  shardguard (ice) dances dance_victory, arm moved 2.78 rad
  thornling (nature) dances dance_surrender, arm moved 1.52 rad
  vinelasher (nature) dances dance_random, arm moved 2.88 rad
  shade (shadow) dances dance_victory, arm moved 1.34 rad
  hexweaver (shadow) dances dance_surrender, arm moved 1.04 rad
  vessa.tscn (fire) dances dance_random, arm moved 0.79 rad
  torvald.tscn (ice) dances dance_victory, arm moved 2.93 rad
  ysolde.tscn (nature) dances dance_surrender, arm moved 1.53 rad
  malrik.tscn (shadow) dances dance_random, arm moved 2.89 rad
FAIL unit_dances: timed out at step 2
```

### test_unit_voice - assert - owner task agent of test_unit_voice
FAIL line; no PASS line; 16.4 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL unit_voice: navigation never finished baking`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_unit_voice.log):
```text
       [0] _process (res://tests/test_unit_voice.gd:40)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
   GDScript backtrace (most recent call first):
       [0] _process (res://tests/test_unit_voice.gd:40)
ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
   GDScript backtrace (most recent call first):
       [0] _process (res://tests/test_unit_voice.gd:40)
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
   at: _ready (res://scripts/world/main.gd:91)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/main.gd:91)
       [1] _process (res://tests/test_unit_voice.gd:41)
FAIL unit_voice: navigation never finished baking
```

### test_ux_1 - assert - owner task agent of test_ux_1
FAIL line; no PASS line; 56.9 s, cap 40000. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL ux.1: navigation never finished baking`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_ux_1.log):
```text
SCRIPT ERROR: Parse Error: Identifier "IdleWorkerButton" not declared in the current scope.
   at: GDScript::reload (res://scripts/ui/hud.gd:121)
SCRIPT ERROR: Parse Error: Identifier "IdleWorkerButton" not declared in the current scope.
   at: GDScript::reload (res://scripts/ui/hud.gd:122)
SCRIPT ERROR: Parse Error: Identifier "IdleWorkerButton" not declared in the current scope.
   at: GDScript::reload (res://scripts/ui/hud.gd:124)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://tests/test_ux_1.gd:0)
ERROR: Failed to load script "res://tests/test_ux_1.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
   at: _ready (res://scripts/world/main.gd:91)
   GDScript backtrace (most recent call first):
       [0] _ready (res://scripts/world/main.gd:91)
FAIL ux.1: navigation never finished baking
```

## Tests
| Test | Result | Why | Exit | Seconds | Cap |
|---|---|---|---|---|---|
| test_1_g1 | PASS |  | 0 | 15 | 40000 |
| test_1_g2 | PASS |  | 0 | 17.6 | 40000 |
| test_1_g3 | PASS |  | 0 | 16.4 | 40000 |
| test_1_s1 | PASS |  | 0 | 38.2 | 40000 |
| test_1_s2 | PASS |  | 0 | 24.7 | 40000 |
| test_1_s3 | PASS |  | 0 | 16.4 | 40000 |
| test_1_u1 | PASS |  | 0 | 19.7 | 40000 |
| test_1_u2 | PASS |  | 0 | 19.4 | 40000 |
| test_1_u3 | PASS |  | 0 | 16.2 | 40000 |
| test_1_u4 | PASS |  | 0 | 15.5 | 40000 |
| test_1_u5 | PASS |  | 0 | 16.8 | 40000 |
| test_10_a1 | PASS |  | 0 | 26.4 | 40000 |
| test_10_a2 | PASS |  | 0 | 7.2 | 40000 |
| test_10_a3 | **FAIL** (assert) | exit 1; FAIL line; no PASS line | 1 | 1079.7 | 150000 |
| test_10_c1 | PASS |  | 0 | 49.8 | 40000 |
| test_10_c10 | PASS |  | 0 | 55.4 | 40000 |
| test_10_c11 | PASS |  | 0 | 19.4 | 40000 |
| test_10_c12 | PASS |  | 0 | 42.9 | 40000 |
| test_10_c2 | PASS |  | 0 | 31.8 | 40000 |
| test_10_c3 | PASS |  | 0 | 17.5 | 40000 |
| test_10_c4 | PASS |  | 0 | 14.6 | 40000 |
| test_10_c5 | PASS |  | 0 | 13.8 | 40000 |
| test_10_c6 | PASS |  | 0 | 19.6 | 40000 |
| test_10_c7 | PASS |  | 0 | 33.9 | 40000 |
| test_10_c8 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 63.1 | 40000 |
| test_10_c9 | PASS |  | 0 | 23 | 40000 |
| test_10_v1 | PASS |  | 0 | 19 | 40000 |
| test_10_v10 | PASS |  | 0 | 6.7 | 40000 |
| test_10_v11 | PASS |  | 0 | 10.9 | 40000 |
| test_10_v12 | PASS |  | 0 | 3.6 | 40000 |
| test_10_v2 | PASS |  | 0 | 7.2 | 40000 |
| test_10_v3 | PASS |  | 0 | 7.3 | 40000 |
| test_10_v4 | PASS |  | 0 | 7.7 | 40000 |
| test_10_v5 | PASS |  | 0 | 11.3 | 40000 |
| test_10_v6 | PASS |  | 0 | 3.6 | 40000 |
| test_10_v7 | PASS |  | 0 | 4.6 | 40000 |
| test_10_v8 | PASS |  | 0 | 9.9 | 40000 |
| test_10_v9 | PASS |  | 0 | 3.6 | 40000 |
| test_11_a1 | PASS |  | 0 | 45.2 | 40000 |
| test_11_c1 | PASS |  | 0 | 9.2 | 40000 |
| test_11_c2 | PASS |  | 0 | 98.9 | 40000 |
| test_11_c3 | PASS |  | 0 | 44 | 40000 |
| test_11_c4 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 37.6 | 40000 |
| test_11_c5 | PASS |  | 0 | 14.8 | 40000 |
| test_11_v1 | PASS |  | 0 | 4.8 | 40000 |
| test_11_v2 | PASS |  | 0 | 3.6 | 40000 |
| test_11_v3 | PASS |  | 0 | 3.6 | 40000 |
| test_11_v4 | PASS |  | 0 | 3.8 | 40000 |
| test_11_v5 | PASS |  | 0 | 4.2 | 40000 |
| test_11_v6 | PASS |  | 0 | 4.3 | 40000 |
| test_11_v7 | PASS |  | 0 | 4.7 | 40000 |
| test_12_a1 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 403.8 | 60000 |
| test_12_a2 | PASS |  | 0 | 53.7 | 40000 |
| test_12_a3 | PASS |  | 0 | 15.5 | 40000 |
| test_12_c1 | PASS |  | 0 | 35.5 | 40000 |
| test_12_c10 | PASS |  | 0 | 30.2 | 40000 |
| test_12_c11 | PASS |  | 0 | 6.2 | 40000 |
| test_12_c2 | PASS |  | 0 | 7.2 | 40000 |
| test_12_c3 | PASS |  | 0 | 14.8 | 40000 |
| test_12_c4 | PASS |  | 0 | 8.7 | 40000 |
| test_12_c5 | PASS |  | 0 | 10.8 | 40000 |
| test_12_c6 | PASS |  | 0 | 24.1 | 40000 |
| test_12_c7 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 28.7 | 40000 |
| test_12_c8 | PASS |  | 0 | 26.1 | 40000 |
| test_12_c9 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 16 | 40000 |
| test_12_v1 | PASS |  | 0 | 6.1 | 40000 |
| test_12_v10 | PASS |  | 0 | 4.6 | 40000 |
| test_12_v11 | PASS |  | 0 | 4.1 | 40000 |
| test_12_v12 | PASS |  | 0 | 3.6 | 40000 |
| test_12_v13 | PASS |  | 0 | 3.6 | 40000 |
| test_12_v14 | PASS |  | 0 | 4.1 | 40000 |
| test_12_v15 | PASS |  | 0 | 3.6 | 40000 |
| test_12_v16 | PASS |  | 0 | 20.5 | 40000 |
| test_12_v17 | PASS |  | 0 | 6.1 | 40000 |
| test_12_v18 | PASS |  | 0 | 5.1 | 40000 |
| test_12_v19 | PASS |  | 0 | 4.6 | 40000 |
| test_12_v2 | PASS |  | 0 | 23.6 | 40000 |
| test_12_v20 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 4.1 | 40000 |
| test_12_v21 | PASS |  | 0 | 3.6 | 40000 |
| test_12_v22 | PASS |  | 0 | 4.1 | 40000 |
| test_12_v23 | PASS |  | 0 | 4.1 | 40000 |
| test_12_v24 | PASS |  | 0 | 3.6 | 40000 |
| test_12_v25 | PASS |  | 0 | 21.6 | 40000 |
| test_12_v27 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 4.1 | 40000 |
| test_12_v28 | PASS |  | 0 | 4.1 | 40000 |
| test_12_v29 | PASS |  | 0 | 4.7 | 40000 |
| test_12_v3 | PASS |  | 0 | 3.2 | 40000 |
| test_12_v30 | PASS |  | 0 | 4.1 | 40000 |
| test_12_v31 | PASS |  | 0 | 4.1 | 40000 |
| test_12_v32 | PASS |  | 0 | 3.1 | 40000 |
| test_12_v4 | PASS |  | 0 | 3.1 | 40000 |
| test_12_v5 | PASS |  | 0 | 21.6 | 40000 |
| test_12_v6 | PASS |  | 0 | 20.5 | 40000 |
| test_12_v7 | PASS |  | 0 | 3.7 | 40000 |
| test_12_v8 | PASS |  | 0 | 3.1 | 40000 |
| test_12_v9 | PASS |  | 0 | 3.8 | 40000 |
| test_12b_v2 | PASS |  | 0 | 3.7 | 40000 |
| test_12b_v3 | PASS |  | 0 | 3.1 | 40000 |
| test_12b_v4 | PASS |  | 0 | 3.8 | 40000 |
| test_12b_v5 | PASS |  | 0 | 3.1 | 40000 |
| test_13_v10 | PASS |  | 0 | 4.1 | 40000 |
| test_13_v13 | PASS |  | 0 | 4.2 | 40000 |
| test_13_v14 | PASS |  | 0 | 5.2 | 40000 |
| test_13_v15 | PASS |  | 0 | 4.7 | 40000 |
| test_13_v16 | PASS |  | 0 | 4.2 | 40000 |
| test_13_v18 | PASS |  | 0 | 4.1 | 40000 |
| test_13_v19 | PASS |  | 0 | 6.9 | 40000 |
| test_13_v1a | PASS |  | 0 | 4.6 | 40000 |
| test_13_v1b | PASS |  | 0 | 5.8 | 40000 |
| test_13_v2 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 4.1 | 40000 |
| test_13_v20 | PASS |  | 0 | 4.2 | 40000 |
| test_13_v25 | PASS |  | 0 | 3.6 | 40000 |
| test_13_v26 | PASS |  | 0 | 4.1 | 40000 |
| test_13_v3 | PASS |  | 0 | 4.6 | 40000 |
| test_13_v5 | PASS |  | 0 | 4.7 | 40000 |
| test_13_v6 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 4.2 | 40000 |
| test_13_v7 | PASS |  | 0 | 4.6 | 40000 |
| test_13_v8 | PASS |  | 0 | 4.1 | 40000 |
| test_13_v9 | PASS |  | 0 | 4.2 | 40000 |
| test_13b_v1 | PASS |  | 0 | 3.6 | 40000 |
| test_13b_v2 | PASS |  | 0 | 3.6 | 40000 |
| test_13b_v3 | PASS |  | 0 | 4.6 | 40000 |
| test_13b_v4 | PASS |  | 0 | 4.1 | 40000 |
| test_13b_v5 | PASS |  | 0 | 4.4 | 40000 |
| test_13b_v6 | PASS |  | 0 | 4.7 | 40000 |
| test_13b_v7 | PASS |  | 0 | 5.8 | 40000 |
| test_13b_v8 | PASS |  | 0 | 5.9 | 40000 |
| test_13b_v9 | PASS |  | 0 | 5.7 | 40000 |
| test_13c_v1 | PASS |  | 0 | 4.7 | 40000 |
| test_13c_v3 | PASS |  | 0 | 4.1 | 40000 |
| test_13c_v5 | PASS |  | 0 | 4.2 | 40000 |
| test_13c_v7 | PASS |  | 0 | 4.1 | 40000 |
| test_13c_v8 | PASS |  | 0 | 6.3 | 40000 |
| test_13c_v9 | PASS |  | 0 | 6.7 | 40000 |
| test_16a | PASS |  | 0 | 38.9 | 40000 |
| test_2_a1_attack | PASS |  | 0 | 250.4 | 95000 |
| test_2_a1_bot_vs_bot | PASS |  | 0 | 896.4 | 116000 |
| test_2_a1_economy | PASS |  | 0 | 104.5 | 40000 |
| test_2_a1_rules | PASS |  | 0 | 157.3 | 40000 |
| test_2_g1 | PASS |  | 0 | 18.4 | 40000 |
| test_2_g2 | PASS |  | 0 | 16.3 | 40000 |
| test_2_g3 | PASS |  | 0 | 18.3 | 40000 |
| test_2_s1 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 20.4 | 40000 |
| test_2_s2 | PASS |  | 0 | 16.3 | 40000 |
| test_2_s3 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 21.9 | 40000 |
| test_2_u1 | PASS |  | 0 | 28.7 | 40000 |
| test_20_a2 | PASS |  | 0 | 350.7 | 60000 |
| test_20_a3 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 537.1 | 80000 |
| test_20_v0 | PASS |  | 0 | 4.1 | 40000 |
| test_3_a1 | PASS |  | 0 | 31.7 | 40000 |
| test_3_g1 | PASS |  | 0 | 26.6 | 40000 |
| test_3_g2a | PASS |  | 0 | 15.8 | 40000 |
| test_3_g2b | PASS |  | 0 | 15.8 | 40000 |
| test_3_s1 | PASS |  | 0 | 22 | 40000 |
| test_3_u1 | PASS |  | 0 | 27 | 40000 |
| test_3_u3 | PASS |  | 0 | 28.1 | 40000 |
| test_4_a1 | PASS |  | 0 | 31.3 | 40000 |
| test_4_g1 | PASS |  | 0 | 16.9 | 40000 |
| test_4_g2 | PASS |  | 0 | 17 | 40000 |
| test_4_i1 | PASS |  | 0 | 15.9 | 40000 |
| test_4_i2 | PASS |  | 0 | 17.1 | 40000 |
| test_4_s1 | PASS |  | 0 | 19.1 | 40000 |
| test_4_u1a | **FAIL** (assert) | FAIL line; no PASS line | 0 | 23.5 | 40000 |
| test_4_u1b | PASS |  | 0 | 23.7 | 40000 |
| test_5_s1 | PASS |  | 0 | 21.3 | 40000 |
| test_5_u1 | PASS |  | 0 | 24.2 | 40000 |
| test_6_a1 | PASS |  | 0 | 79.2 | 40000 |
| test_6_b2 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 19.5 | 40000 |
| test_6_s1 | PASS |  | 0 | 22.2 | 40000 |
| test_6_s2 | PASS |  | 0 | 26.7 | 40000 |
| test_6_u1 | PASS |  | 0 | 20.7 | 40000 |
| test_6_u2 | PASS |  | 0 | 31.7 | 40000 |
| test_6_u3 | PASS |  | 0 | 27.8 | 40000 |
| test_7_a1 | PASS |  | 0 | 142.8 | 40000 |
| test_7_g1 | PASS |  | 0 | 21.1 | 40000 |
| test_7_g2 | PASS |  | 0 | 15.3 | 40000 |
| test_7_g3 | PASS |  | 0 | 17.2 | 40000 |
| test_7_i1 | PASS |  | 0 | 17.1 | 40000 |
| test_7_s1 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 27.8 | 40000 |
| test_7_u1 | PASS |  | 0 | 28.3 | 40000 |
| test_8_a1 | PASS |  | 0 | 1446.9 | 200000 |
| test_8_a2 | PASS |  | 0 | 789.5 | 100000 |
| test_8_b3 | PASS |  | 0 | 481.2 | 95000 |
| test_8_g1 | PASS |  | 0 | 219.3 | 40000 |
| test_8_g2 | PASS |  | 0 | 34.5 | 40000 |
| test_8_i1 | PASS |  | 0 | 32.9 | 40000 |
| test_8_s1 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 38.1 | 40000 |
| test_8_s2 | PASS |  | 0 | 136.5 | 40000 |
| test_8_u1 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 20 | 40000 |
| test_8_u2 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 14.9 | 40000 |
| test_9_c1 | PASS |  | 0 | 16.9 | 40000 |
| test_9_c10 | PASS |  | 0 | 6.7 | 40000 |
| test_9_c11 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 23.1 | 95000 |
| test_9_c2 | PASS |  | 0 | 7.2 | 40000 |
| test_9_c3 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 29.3 | 40000 |
| test_9_c4 | PASS |  | 0 | 7.7 | 40000 |
| test_9_c5 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 27.2 | 40000 |
| test_9_c6 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 13.3 | 40000 |
| test_9_c7 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 13.9 | 40000 |
| test_9_c8 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 13.9 | 40000 |
| test_9_c9 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 20.2 | 150000 |
| test_9_v1 | PASS |  | 0 | 4.1 | 40000 |
| test_9_v2 | PASS |  | 0 | 4.1 | 40000 |
| test_9_v3 | PASS |  | 0 | 3.6 | 40000 |
| test_9_v4 | PASS |  | 0 | 5.5 | 40000 |
| test_9_v5 | PASS |  | 0 | 4.6 | 40000 |
| test_9_v6 | PASS |  | 0 | 3.6 | 40000 |
| test_a_8 | PASS |  | 0 | 4.1 | 40000 |
| test_a_9 | PASS |  | 0 | 4.7 | 40000 |
| test_a17 | PASS |  | 0 | 7.3 | 40000 |
| test_a2_10 | PASS |  | 0 | 6.2 | 40000 |
| test_a2_3 | **FAIL** (assert) | exit 1; FAIL line; no PASS line | 1 | 20.7 | 40000 |
| test_a2_4 | PASS |  | 0 | 3.6 | 40000 |
| test_a2_5 | PASS |  | 0 | 4.6 | 40000 |
| test_a2_6 | PASS |  | 0 | 5.1 | 40000 |
| test_a2_7 | PASS |  | 0 | 4.1 | 40000 |
| test_a2_8 | PASS |  | 0 | 4.1 | 40000 |
| test_a2_9 | PASS |  | 0 | 5.7 | 40000 |
| test_a5 | PASS |  | 0 | 5.7 | 40000 |
| test_art_lab | PASS | verdict=last: 2 inner FAIL line(s) ignored | 0 | 8.8 | 40000 |
| test_art_lab_calibration | PASS | verdict=last: 3 inner FAIL line(s) ignored | 0 | 8.3 | 40000 |
| test_audio_lab | PASS |  | 0 | 16.6 | 40000 |
| test_balance_lab | PASS |  | 0 | 8.7 | 40000 |
| test_bot_lab | **FAIL** (assert) | FAIL line; no PASS line | 0 | 13.9 | 40000 |
| test_bowmen | **FAIL** (assert) | FAIL line; no PASS line | 0 | 27.7 | 40000 |
| test_campaign_prologue | PASS |  | 0 | 29.8 | 40000 |
| test_caravan_pop | **FAIL** (assert) | FAIL line; no PASS line | 0 | 31.4 | 40000 |
| test_data_lab | PASS |  | 0 | 44.9 | 40000 |
| test_fix_groups | **FAIL** (assert) | FAIL line; no PASS line | 0 | 13.3 | 40000 |
| test_fix_minimap_click | **FAIL** (assert) | FAIL line; no PASS line | 0 | 14 | 40000 |
| test_kit_team_color | PASS |  | 0 | 7.2 | 40000 |
| test_lead_item_passives | **FAIL** (assert) | FAIL line; no PASS line | 0 | 20.1 | 40000 |
| test_m7_s1 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 20.1 | 40000 |
| test_m7_s2 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 13.2 | 40000 |
| test_m7_s3 | PASS |  | 0 | 3.6 | 40000 |
| test_m7_u1 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 19 | 40000 |
| test_map_lab | **FAIL** (assert) | FAIL line; no PASS line | 0 | 39.5 | 40000 |
| test_map_p1 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 59.8 | 40000 |
| test_map_p3 | PASS |  | 0 | 3.6 | 40000 |
| test_new_units_12 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 21.5 | 40000 |
| test_perf_lab | PASS |  | 0 | 3.6 | 40000 |
| test_pop_200 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 13.9 | 40000 |
| test_replay_lab | **FAIL** (assert) | FAIL line; no PASS line | 0 | 1503.8 | 40000 |
| test_sound_plan | **FAIL** (assert) | FAIL line; no PASS line | 0 | 82.8 | 40000 |
| test_str_int | **FAIL** (assert) | FAIL line; no PASS line | 0 | 59.5 | 40000 |
| test_t3 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 47.7 | 40000 |
| test_tiers | **FAIL** (assert) | FAIL line; no PASS line | 0 | 54.4 | 40000 |
| test_tool_cine | PASS |  | 0 | 35 | 40000 |
| test_tool_cine_runtime | PASS |  | 0 | 18.2 | 40000 |
| test_tool_lens | PASS |  | 0 | 35.3 | 40000 |
| test_tool_voice_forge | PASS |  | 0 | 38.9 | 40000 |
| test_tool_world_forge | PASS |  | 0 | 29.2 | 40000 |
| test_ui_building_groups | **FAIL** (assert) | FAIL line; no PASS line | 0 | 19.9 | 40000 |
| test_ui_lab | **FAIL** (script error) | no PASS line | 0 | 191.2 | 40000 |
| test_ui_minimap_zoom | **FAIL** (assert) | FAIL line; no PASS line | 0 | 56.2 | 40000 |
| test_ui_restart_hint | **FAIL** (assert) | FAIL line; no PASS line | 0 | 24.1 | 40000 |
| test_ui_train_queue | **FAIL** (assert) | FAIL line; no PASS line | 0 | 27.6 | 40000 |
| test_ui_voice_hold | PASS |  | 0 | 3.1 | 40000 |
| test_unit_dances | **FAIL** (assert) | FAIL line; no PASS line | 0 | 16.4 | 40000 |
| test_unit_voice | **FAIL** (assert) | FAIL line; no PASS line | 0 | 16.4 | 40000 |
| test_ux_1 | **FAIL** (assert) | FAIL line; no PASS line | 0 | 56.9 | 40000 |
| test_visual_diff_lab | PASS |  | 0 | 47.5 | 40000 |

## Unique errors
| # | Sev | New | Location | Owner | Count | Tests | Message |
|---|---|---|---|---|---|---|---|
| 1 | FAIL | NEW | res://scripts/ui/hud.gd:119 | ui-coder | 144 | test_8_u2, test_9_c11, test_9_c3, test_9_c5, test_9_c6 +31 more | Parse Error: Identifier "IdleWorkerButton" not declared in the current scope. |
| 2 | FAIL | NEW | res://scripts/ui/hud.gd:11 | ui-coder | 36 | test_8_u2, test_9_c11, test_9_c3, test_9_c5, test_9_c6 +31 more | Parse Error: Could not find type "IdleWorkerButton" in the current scope. |
| 3 | FAIL | NEW | res://scripts/ui/selection_manager.gd:0 | ui-coder | 34 | test_8_u2, test_9_c11, test_9_c3, test_9_c5, test_9_c6 +29 more | Compile Error: Failed to compile depended scripts. |
| 4 | FAIL | NEW | res://scripts/ui/menus/pause_menu.gd:0 | ui-coder | 30 | test_8_u2, test_9_c11, test_9_c3, test_9_c5, test_9_c6 +25 more | Compile Error: Failed to compile depended scripts. |
| 5 | FAIL | NEW | res://scripts/world/main.gd:91 | systems-coder | 16 | test_9_c11, test_9_c3, test_9_c5, test_9_c9, test_a2_3 +11 more | Invalid call. Nonexistent function 'new' in base 'GDScript'. |
| 6 | FAIL | NEW | res://scripts/world/main.gd:91 | systems-coder | 13 | test_9_c6, test_9_c7, test_9_c8, test_fix_groups, test_fix_minimap_click +8 more | Invalid call. Nonexistent function 'new' in base 'GDScript'. |
| 7 | FAIL | NEW | res://scripts/ui/menus/pause_menu.gd:0 | ui-coder | 12 | test_9_c11, test_9_c5, test_9_c9, test_bowmen, test_campaign_prologue +7 more | Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". |
| 8 | FAIL | NEW | res://scripts/world/main.gd:91 | systems-coder | 5 | test_8_u2, test_campaign_prologue, test_m7_s1, test_m7_s2 | Invalid call. Nonexistent function 'new' in base 'GDScript'. |
| 9 | FAIL | NEW | res://scripts/ai/ai_champions.gd:0 | ai-coder | 4 | test_8_u2, test_m7_s1, test_m7_s2, test_tool_voice_forge | Compile Error: Failed to compile depended scripts. |
| 10 | FAIL | NEW | res://scripts/ai/commander.gd:0 | ai-coder | 4 | test_8_u2, test_m7_s1, test_m7_s2, test_tool_voice_forge | Compile Error: Failed to compile depended scripts. |
| 11 | FAIL | NEW | res://scripts/ui/menus/menu_flow.gd:0 | ui-coder | 4 | test_8_u2, test_m7_s1, test_m7_s2, test_tool_voice_forge | Compile Error: Failed to compile depended scripts. |
| 12 | FAIL | NEW | res://scripts/world/main.gd:0 | systems-coder | 4 | test_8_u2, test_m7_s1, test_m7_s2, test_tool_voice_forge | Compile Error: Failed to compile depended scripts. |
| 13 | FAIL | NEW | res://scripts/world/skirmish.gd:0 | systems-coder | 4 | test_8_u2, test_m7_s1, test_m7_s2, test_tool_voice_forge | Compile Error: Failed to compile depended scripts. |
| 14 | FAIL | NEW | res://scripts/ui/bounty_mode.gd:0 | ui-coder | 1 | test_9_c8 | Compile Error: Failed to compile depended scripts. |
| 15 | FAIL | NEW | res://scripts/ui/champion_bar.gd:0 | ui-coder | 1 | test_a2_9 | Compile Error: Failed to compile depended scripts. |
| 16 | FAIL | NEW | res://scripts/ui/minimap.gd:0 | ui-coder | 1 | test_ui_minimap_zoom | Compile Error: Failed to compile depended scripts. |
| 17 | FAIL | NEW | res://tests/test_9_c8.gd:0 | task agent of test_9_c8 | 1 | test_9_c8 | Compile Error: Failed to compile depended scripts. |
| 18 | FAIL | NEW | res://tests/test_ui_lab.gd:0 | lab group A (visual) | 1 | test_ui_lab | Compile Error: Failed to compile depended scripts. |
| 19 | FAIL | NEW | res://tests/test_ui_minimap_zoom.gd:0 | task agent of test_ui_minimap_zoom | 1 | test_ui_minimap_zoom | Compile Error: Failed to compile depended scripts. |
| 20 | FAIL | NEW | res://tests/test_unit_dances.gd:0 | task agent of test_unit_dances | 1 | test_unit_dances | Compile Error: Failed to compile depended scripts. |
| 21 | FAIL | NEW | res://tests/test_ux_1.gd:0 | task agent of test_ux_1 | 1 | test_ux_1 | Compile Error: Failed to compile depended scripts. |
| 22 | FAIL | NEW | res://tests/test_a2_9.gd:73 | task agent of test_a2_9 | 1 | test_a2_9 | Failed to load script "res://scripts/ui/champion_bar.gd" with error "Compilation failed". |
| 23 | FAIL | NEW | res://tests/test_8_u2.gd:45 | ui-coder | 1 | test_8_u2 | Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". |
| 24 | FAIL | NEW | res://tests/test_9_c3.gd:103 | task agent of test_9_c3 | 1 | test_9_c3 | Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". |
| 25 | FAIL | NEW | res://tests/test_9_c6.gd:63 | task agent of test_9_c6 | 1 | test_9_c6 | Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". |
| 26 | FAIL | NEW | res://tests/test_9_c7.gd:175 | task agent of test_9_c7 | 1 | test_9_c7 | Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". |
| 27 | FAIL | NEW | res://tests/test_a2_3.gd:114 | task agent of test_a2_3 | 1 | test_a2_3 | Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". |
| 28 | FAIL | NEW | res://tests/test_caravan_pop.gd:18 | task agent of test_caravan_pop | 1 | test_caravan_pop | Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". |
| 29 | FAIL | NEW | res://tests/test_fix_groups.gd:30 | task agent of test_fix_groups | 1 | test_fix_groups | Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". |
| 30 | FAIL | NEW | res://tests/test_fix_minimap_click.gd:32 | task agent of test_fix_minimap_click | 1 | test_fix_minimap_click | Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". |
| 31 | FAIL | NEW | res://tests/test_lead_item_passives.gd:13 | task agent of test_lead_item_passives | 1 | test_lead_item_passives | Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". |
| 32 | FAIL | NEW | res://tests/test_m7_s1.gd:28 | systems-coder | 1 | test_m7_s1 | Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". |
| 33 | FAIL | NEW | res://tests/test_m7_s2.gd:26 | systems-coder | 1 | test_m7_s2 | Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". |
| 34 | FAIL | NEW | res://tests/test_m7_u1.gd:55 | ui-coder | 1 | test_m7_u1 | Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". |
| 35 | FAIL | NEW | res://tests/test_map_lab.gd:27 | map_lab owner (lab) | 1 | test_map_lab | Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". |
| 36 | FAIL | NEW | res://tests/test_map_p1.gd:30 | task agent of test_map_p1 | 1 | test_map_p1 | Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". |
| 37 | FAIL | NEW | res://tests/test_sound_plan.gd:61 | task agent of test_sound_plan | 1 | test_sound_plan | Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". |
| 38 | FAIL | NEW | res://tests/test_str_int.gd:29 | task agent of test_str_int | 1 | test_str_int | Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". |
| 39 | FAIL | NEW | res://tests/test_tool_voice_forge.gd:76 | task agent of test_tool_voice_forge | 1 | test_tool_voice_forge | Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". |
| 40 | FAIL | NEW | res://tests/test_unit_voice.gd:40 | task agent of test_unit_voice | 1 | test_unit_voice | Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". |
| 41 | FAIL | NEW | res://tests/test_9_c8.gd:0 | task agent of test_9_c8 | 1 | test_9_c8 | Failed to load script "res://tests/test_9_c8.gd" with error "Compilation failed". |
| 42 | FAIL | NEW | res://tests/test_ui_lab.gd:0 | lab group A (visual) | 1 | test_ui_lab | Failed to load script "res://tests/test_ui_lab.gd" with error "Compilation failed". |
| 43 | FAIL | NEW | res://tests/test_ui_minimap_zoom.gd:0 | task agent of test_ui_minimap_zoom | 1 | test_ui_minimap_zoom | Failed to load script "res://tests/test_ui_minimap_zoom.gd" with error "Compilation failed". |
| 44 | FAIL | NEW | res://tests/test_unit_dances.gd:0 | task agent of test_unit_dances | 1 | test_unit_dances | Failed to load script "res://tests/test_unit_dances.gd" with error "Compilation failed". |
| 45 | FAIL | NEW | res://tests/test_ux_1.gd:0 | task agent of test_ux_1 | 1 | test_ux_1 | Failed to load script "res://tests/test_ux_1.gd" with error "Compilation failed". |
| 46 | FAIL | NEW | res://tests/test_ui_lab.gd:139 | lab group A (visual) | 1 | test_ui_lab | Invalid call. Nonexistent function 'help_text' in base 'GDScript'. |
| 47 | WARN | NEW | engine core/variant/array.cpp:619 | ai-coder (engine error, no script frame) | 1 | test_2_a1_bot_vs_bot | Error calling method from 'filter': 'GDScript::<anonymous lambda>': Cannot convert argument N from Object to Object. |
| 48 | WARN | NEW | (no frame) | ai-coder (engine error, no script frame) | 1 | test_10_a3 | normal: the Coin-Cutter ignored a looting Magpie N s free / N s in all (intent Raiding) |
| 49 | WARN |  | (no frame) | ai-coder (engine error, no script frame) | 1 | test_10_a3 | hard: no B7 Guard flag after a raid |

## Gone vs the previous run (ci-playtest-2026-09-27): fixed, or their test did not run this time
- ART LAB ERROR: sweep=bogus: use all or a comma list of ["fire", "ice", "nature", "shadow", "neutral"] @ (engine)

## INFO (known exit noise, never FAIL)
- N ObjectDB instances were leaked at exit (run with `--verbose` for details). - x262 in 262 tests
- N resources still in use at exit (run with --verbose for details). - x262 in 262 tests
- N RID of type "CanvasItem" was leaked. - x1 in 1 tests
- N RIDs of type "CanvasItem" were leaked. - x1 in 1 tests

## Fix-agent briefs (one per owner; the lead's rule: any failure -> launch a fix agent)

### ui-coder (11 errors, 4 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [FAIL, NEW] res://scripts/ui/hud.gd:119 - Parse Error: Identifier "IdleWorkerButton" not declared in the current scope. - x144 in: test_8_u2, test_9_c11, test_9_c3, test_9_c5, test_9_c6 +31 more
2. [FAIL, NEW] res://scripts/ui/hud.gd:11 - Parse Error: Could not find type "IdleWorkerButton" in the current scope. - x36 in: test_8_u2, test_9_c11, test_9_c3, test_9_c5, test_9_c6 +31 more
3. [FAIL, NEW] res://scripts/ui/selection_manager.gd:0 - Compile Error: Failed to compile depended scripts. - x34 in: test_8_u2, test_9_c11, test_9_c3, test_9_c5, test_9_c6 +29 more
4. [FAIL, NEW] res://scripts/ui/menus/pause_menu.gd:0 - Compile Error: Failed to compile depended scripts. - x30 in: test_8_u2, test_9_c11, test_9_c3, test_9_c5, test_9_c6 +25 more
5. [FAIL, NEW] res://scripts/ui/menus/pause_menu.gd:0 - Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". - x12 in: test_9_c11, test_9_c5, test_9_c9, test_bowmen, test_campaign_prologue +7 more
6. [FAIL, NEW] res://scripts/ui/menus/menu_flow.gd:0 - Compile Error: Failed to compile depended scripts. - x4 in: test_8_u2, test_m7_s1, test_m7_s2, test_tool_voice_forge
7. [FAIL, NEW] res://scripts/ui/bounty_mode.gd:0 - Compile Error: Failed to compile depended scripts. - x1 in: test_9_c8
8. [FAIL, NEW] res://scripts/ui/champion_bar.gd:0 - Compile Error: Failed to compile depended scripts. - x1 in: test_a2_9
9. [FAIL, NEW] res://scripts/ui/minimap.gd:0 - Compile Error: Failed to compile depended scripts. - x1 in: test_ui_minimap_zoom
10. [FAIL, NEW] res://tests/test_8_u2.gd:45 - Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". - x1 in: test_8_u2
11. [FAIL, NEW] res://tests/test_m7_u1.gd:55 - Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". - x1 in: test_m7_u1
Failed tests:
- test_4_u1a: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 4.u1a: top bar rect [P: (479.5, 8.0), S: (641.0, 40.0)]
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_4_u1a.log):
    viewport (1600.0, 900.0)
    FAIL 4.u1a: top bar rect [P: (479.5, 8.0), S: (641.0, 40.0)]
- test_8_u1: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 8.u1: top bar pop is '13 / 80', expected '/ 50'
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_8_u1.log):
    FAIL 8.u1: top bar pop is '13 / 80', expected '/ 50'
- test_8_u2: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 8.U2: navigation never finished baking
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_8_u2.log):
       at: load (modules/gdscript/gdscript_resource_format.cpp:46)
       GDScript backtrace (most recent call first):
           [0] _initialize (res://tests/test_8_u2.gd:45)
    SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
       at: Mission01._ready (res://scripts/world/main.gd:91)
       GDScript backtrace (most recent call first):
           [0] _ready (res://scripts/world/main.gd:91)
           [1] _ready (res://scripts/world/skirmish.gd:407)
           [2] _ready (res://scripts/campaign/mission_01.gd:253)
    FAIL 8.U2: navigation never finished baking
- test_m7_u1: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL M7.U1: navigation never finished baking
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_m7_u1.log):
           [0] _initialize (res://tests/test_m7_u1.gd:55)
    ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
       at: load (modules/gdscript/gdscript_resource_format.cpp:46)
       GDScript backtrace (most recent call first):
           [0] _initialize (res://tests/test_m7_u1.gd:55)
    SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
       at: _ready (res://scripts/world/main.gd:91)
       GDScript backtrace (most recent call first):
           [0] _ready (res://scripts/world/main.gd:91)
    FAIL M7.U1: navigation never finished baking
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_8_u2.gd --fixed-fps 60 --quit-after 40000
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_9_c11.gd --fixed-fps 60 --quit-after 95000
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_9_c3.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_8_u2,test_9_c11,test_9_c3,test_9_c5,test_9_c6,test_9_c7,test_9_c8,test_9_c9 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### systems-coder (7 errors, 6 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [FAIL, NEW] res://scripts/world/main.gd:91 - Invalid call. Nonexistent function 'new' in base 'GDScript'. - x16 in: test_9_c11, test_9_c3, test_9_c5, test_9_c9, test_a2_3 +11 more
2. [FAIL, NEW] res://scripts/world/main.gd:91 - Invalid call. Nonexistent function 'new' in base 'GDScript'. - x13 in: test_9_c6, test_9_c7, test_9_c8, test_fix_groups, test_fix_minimap_click +8 more
3. [FAIL, NEW] res://scripts/world/main.gd:91 - Invalid call. Nonexistent function 'new' in base 'GDScript'. - x5 in: test_8_u2, test_campaign_prologue, test_m7_s1, test_m7_s2
4. [FAIL, NEW] res://scripts/world/main.gd:0 - Compile Error: Failed to compile depended scripts. - x4 in: test_8_u2, test_m7_s1, test_m7_s2, test_tool_voice_forge
5. [FAIL, NEW] res://scripts/world/skirmish.gd:0 - Compile Error: Failed to compile depended scripts. - x4 in: test_8_u2, test_m7_s1, test_m7_s2, test_tool_voice_forge
6. [FAIL, NEW] res://tests/test_m7_s1.gd:28 - Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". - x1 in: test_m7_s1
7. [FAIL, NEW] res://tests/test_m7_s2.gd:26 - Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". - x1 in: test_m7_s2
Failed tests:
- test_2_s1: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 2.S1: fire_hearth numbers | shadow_hovel numbers
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_2_s1.log):
      hall at (-29.0, 0.0, 41.0)
    FAIL 2.S1: fire_hearth numbers | shadow_hovel numbers
- test_2_s3: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 2.S3: crown bonus: hp 450 / 450 mana max 188, want 450 / 450, 150
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_2_s3.log):
      94 obstacles (trees, rocks, pillars), 0 without a mirror
    FAIL 2.S3: crown bonus: hp 450 / 450 mana max 188, want 450 / 450, 150
- test_7_s1: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 7.S1: ice_lodge is [80, 30.0, 600.0, (2, 2), 3.0, 20, 9, "Z"], spec [80, 30.0, 600.0, (2, 2), 3.0, 10, 2, "Z"]
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_7_s1.log):
    FAIL 7.S1: ice_lodge is [80, 30.0, 600.0, (2, 2), 3.0, 20, 9, "Z"], spec [80, 30.0, 600.0, (2, 2), 3.0, 10, 2, "Z"]
- test_8_s1: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 8.S1: nature_hollow is [60, 20.0, 450.0, (2, 2), 3.0, 20, 9, "Z", &"house"], spec [60, 20.0, 450.0, (2, 2), 3.0, 10, 3, "Z", &"house"]; pop_cap_limit_for nature / fire = 200 / 200; after the Heartwood: kingdom nature, max 200, cap 20; Heartwood + 3 hollows: pop cap 80, not 50; 4th hollow: ''; pop cap above the Nature cap: 100; pop cap after losing the extra hollow: 80; Fire cap changed: max 200, cap 20
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_8_s1.log):
    FAIL 8.S1: nature_hollow is [60, 20.0, 450.0, (2, 2), 3.0, 20, 9, "Z", &"house"], spec [60, 20.0, 450.0, (2, 2), 3.0, 10, 3, "Z", &"house"]; pop_cap_limit_for nature / fire = 200 / 200; after the Heartwood: kingdom nature, max 200, cap 20; Heartwood + 3 hollows: pop cap 80, not 50; 4th hollow: ''; pop cap above the Nature cap: 100; pop cap after losing the extra hollow: 80; Fire cap changed: max 200, cap 20
- test_m7_s1: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL m7_s1: navigation never finished baking
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_m7_s1.log):
       at: load (modules/gdscript/gdscript_resource_format.cpp:46)
       GDScript backtrace (most recent call first):
           [0] _initialize (res://tests/test_m7_s1.gd:28)
    SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
       at: Mission01._ready (res://scripts/world/main.gd:91)
       GDScript backtrace (most recent call first):
           [0] _ready (res://scripts/world/main.gd:91)
           [1] _ready (res://scripts/world/skirmish.gd:407)
           [2] _ready (res://scripts/campaign/mission_01.gd:253)
    FAIL m7_s1: navigation never finished baking
- test_m7_s2: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL m7_s2: navigation never finished baking
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_m7_s2.log):
       at: load (modules/gdscript/gdscript_resource_format.cpp:46)
       GDScript backtrace (most recent call first):
           [0] _initialize (res://tests/test_m7_s2.gd:26)
    SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
       at: Mission01._ready (res://scripts/world/main.gd:91)
       GDScript backtrace (most recent call first):
           [0] _ready (res://scripts/world/main.gd:91)
           [1] _ready (res://scripts/world/skirmish.gd:407)
           [2] _ready (res://scripts/campaign/mission_01.gd:253)
    FAIL m7_s2: navigation never finished baking
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_9_c11.gd --fixed-fps 60 --quit-after 95000
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_9_c3.gd --fixed-fps 60 --quit-after 40000
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_9_c5.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_9_c11,test_9_c3,test_9_c5,test_9_c9,test_a2_3,test_bowmen,test_caravan_pop,test_lead_item_passives -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### ai-coder (2 errors, 3 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [FAIL, NEW] res://scripts/ai/ai_champions.gd:0 - Compile Error: Failed to compile depended scripts. - x4 in: test_8_u2, test_m7_s1, test_m7_s2, test_tool_voice_forge
2. [FAIL, NEW] res://scripts/ai/commander.gd:0 - Compile Error: Failed to compile depended scripts. - x4 in: test_8_u2, test_m7_s1, test_m7_s2, test_tool_voice_forge
Failed tests:
- test_10_a3: assert (exit 1; FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 10.A3: 2 error(s)
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_10_a3.log):
      [11:57] TRADE hires outriders (120 gold): a caravan was lost
      [12:04] BOUNTY B5 Escort 50 on Caravan (stakes 50 + 50 <= 640 of 1599 spare essence)
      [12:09] TRADE far caravans called home: far road unsafe
      [12:23] TRAIN Caravan (5 caravans + 1 queued, target 6, crystals left 100)
      [12:37] TRADE buys Quilted Gambesons (350 gold, 65 left)
      [12:37] TRADE buys Masons' Charter (350 gold, 60 left)
      [12:38] CHAMPION hire coin_cutter (Sable Quint) #3 in gold: 325 gold + 125 essence, from (-15, -15)
    ERROR: normal: the Coin-Cutter ignored a looting Magpie 8 s free / 8 s in all (intent Raiding)
    ERROR: hard: no B7 Guard flag after a raid
    FAIL 10.A3: 2 error(s)
- test_12_a1: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 12.A1: 2 problem(s)
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_12_a1.log):
      [4:50] CREEP over (cleared): Gloomcap Hollow SE
      [5:02] SQUAD back: Rookwatch done
      [5:09] SCOUT home
      [5:11] SQUAD 3 units to Millwatch
      [5:37] SQUAD back: Millwatch done
    finished after 46807 frames
    NOTE hard: deer shots 1
    ERROR normal: map-fill median 0.141 ms per tick (limit 0.10)
    ERROR hard: map-fill median 0.123 ms per tick (limit 0.10)
    FAIL 12.A1: 2 problem(s)
- test_20_a3: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 20.A3: bot 0 median think 2.354 ms > 1.5 ms
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_20_a3.log):
      attack blocks (ticks): { "no army": 265, "pop": 261, "group out": 140, "strength": 10, "retreat": 40, "defending": 131, "rally": 24 }
      sub (avg ms/max ms): scan.units 0.29/1.3
    bot 0 think: median 2.354 ms, avg 2.970 ms, p95 3.333 ms, max 540.938 ms at 48 s
    bot 0 (fire): 0 attacks, first -1 s, median 2.354 ms, max 540.938 ms
    bot 1 think: median 2.468 ms, avg 3.378 ms, p95 3.447 ms, max 533.820 ms at 48 s
    bot 1 (shadow): 5 attacks, first 238 s, median 2.468 ms, max 533.820 ms
    match: over true at 863 s, winner 1
      bot 0 median think 2.354 ms > 1.5 ms
      bot 1 median think 2.468 ms > 1.5 ms
    FAIL 20.A3: bot 0 median think 2.354 ms > 1.5 ms
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_8_u2.gd --fixed-fps 60 --quit-after 40000
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_m7_s1.gd --fixed-fps 60 --quit-after 40000
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_m7_s2.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_8_u2,test_m7_s1,test_m7_s2,test_tool_voice_forge,test_10_a3,test_12_a1,test_20_a3 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### lab group A (visual) (3 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [FAIL, NEW] res://tests/test_ui_lab.gd:0 - Compile Error: Failed to compile depended scripts. - x1 in: test_ui_lab
2. [FAIL, NEW] res://tests/test_ui_lab.gd:0 - Failed to load script "res://tests/test_ui_lab.gd" with error "Compilation failed". - x1 in: test_ui_lab
3. [FAIL, NEW] res://tests/test_ui_lab.gd:139 - Invalid call. Nonexistent function 'help_text' in base 'GDScript'. - x1 in: test_ui_lab
Failed tests:
- test_ui_lab: script error (no PASS line). A script error stopped the test before its PASS line: fix the first FAIL-class error listed for this test.
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_ui_lab.log):
    SCRIPT ERROR: Parse Error: Identifier "IdleWorkerButton" not declared in the current scope.
       at: GDScript::reload (res://scripts/ui/hud.gd:124)
    SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
       at: GDScript::reload (res://tests/test_ui_lab.gd:0)
    ERROR: Failed to load script "res://tests/test_ui_lab.gd" with error "Compilation failed".
       at: load (modules/gdscript/gdscript_resource_format.cpp:46)
    SCRIPT ERROR: Invalid call. Nonexistent function 'help_text' in base 'GDScript'.
       at: _run (res://tests/test_ui_lab.gd:139)
       GDScript backtrace (most recent call first):
           [0] _run (res://tests/test_ui_lab.gd:139)
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_ui_lab.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_ui_lab -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### tech-artist (0 errors, 4 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Failed tests:
- test_12_v20: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 12.v20: head tossed up at the strike (-12.0)
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_12_v20.log):
      Fx/Clods (GPUParticles3D): 0 vertices
      Shadow (MeshInstance3D): 4 vertices
    rest AABB top 1.211, bottom 0.000, x -0.34 .. 0.35, z -0.91 .. 1.18
    walk: max fore-leg swing 29.9 deg
    gore: head x windup 42.0, strike -12.0 deg, lunge z 0.27, quills 1.00 (scale y 1.34)
      FAILED: head tossed up at the strike (-12.0)
    dig: head x 36.4 deg
    cast: root pitch -15.0 deg, root y 0.13
    death 0.6 s: root roll 82.0 deg
    FAIL 12.v20: head tossed up at the strike (-12.0)
- test_12_v27: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 12.v27: B's right tusk is the broken one
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_12_v27.log):
      FAILED: B's right tusk is the broken one
    walk: max fore-leg swing 25.8 deg, bristles -0.12
    gore: head windup 40.3, lunge z 0.41, toss -14.7
    charge: head 31.7, charging true, trail true, leg swing 37.4, bristles 1.00
    toss: head -23.9, charging false, tosses 1
    dash: charging at 0.9 s true, stopped 6 frames after the unit stopped
    bristle hide: action '', raise 0.78
    hit: head -2.8, bristles 0.80
    death 0.7 s: root roll 80.0 deg, root y 0.50, lowest body -0.055, lowest all -0.055, trail false
    FAIL 12.v27: B's right tusk is the broken one
- test_13_v2: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 13.v2: nothing below the ground at rest (-0.011)
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_13_v2.log):
    walk: leg swing 24.0 deg, gallop blend 0.00
    gallop: blend 1.00, bounce 0.080, seat bob 0.110, leg swing 38.0 deg, strides/s 3, tail lift 70.0 deg
    hit: body flash 0.58, leg flash 0.58, root z -0.083
    charge: head 20.0 deg (tusks levelled), lunge z 0.41, toss -29.2 deg, mane glow 1.00 -> 2.60
    fidget: rooting head 28.7 deg, toss -14.1 deg, glow 2.01
    barded: draw instances 8, vertices 6880, body surfaces 8 -> 8
    team colour on the barded body: [(0.45, 0.75, 0.95, 1.0), (0.2025, 0.3375, 0.4275, 1.0)]
    slot collisions: 0
    death: roll -40.1 -> -86.0 deg, lying AABB y -0.03..1.04, smoulder 0.17 -> 0.03 ((1.0, 0.3, 0.05)), mane glow 0.00, finished true
    FAIL 13.v2: nothing below the ground at rest (-0.011)
- test_13_v6: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 13.v6: nothing below the ground at rest (-0.010)
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_13_v6.log):
    seat (model space) (-0.003905, 1.530416, -0.104508)
    walk: leg swing 19.9 deg, gallop blend 0.00
    gallop: blend 1.00, bounce 0.070, seat bob 0.082, leg swing 32.0 deg, strides/s 3, tail lift 26.0 deg
    hit: body flash 0.58, leg flash 0.58, root z -0.083
    charge: head 14.5 deg, lunge z 0.41, toss -29.8 deg
    graze: head 49.5 deg, lifted 2.3 deg
    team colour on the body: [(0.45, 0.75, 0.95, 1.0), (0.2025, 0.3375, 0.4275, 1.0)]
    slot collisions: 0
    death: roll -86.0 deg, lying AABB y 0.01..1.09, finished true
    FAIL 13.v6: nothing below the ground at rest (-0.010)
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_12_v20.gd --fixed-fps 60 --quit-after 40000
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_12_v27.gd --fixed-fps 60 --quit-after 40000
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_13_v2.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_12_v20,test_12_v27,test_13_v2,test_13_v6 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_9_c8 (2 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [FAIL, NEW] res://tests/test_9_c8.gd:0 - Compile Error: Failed to compile depended scripts. - x1 in: test_9_c8
2. [FAIL, NEW] res://tests/test_9_c8.gd:0 - Failed to load script "res://tests/test_9_c8.gd" with error "Compilation failed". - x1 in: test_9_c8
Failed tests:
- test_9_c8: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 9.C8: navigation never finished baking
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_9_c8.log):
       at: GDScript::reload (res://scripts/ui/bounty_mode.gd:0)
    SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
       at: GDScript::reload (res://tests/test_9_c8.gd:0)
    ERROR: Failed to load script "res://tests/test_9_c8.gd" with error "Compilation failed".
       at: load (modules/gdscript/gdscript_resource_format.cpp:46)
    SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
       at: _ready (res://scripts/world/main.gd:91)
       GDScript backtrace (most recent call first):
           [0] _ready (res://scripts/world/main.gd:91)
    FAIL 9.C8: navigation never finished baking
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_9_c8.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_9_c8 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_ui_minimap_zoom (2 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [FAIL, NEW] res://tests/test_ui_minimap_zoom.gd:0 - Compile Error: Failed to compile depended scripts. - x1 in: test_ui_minimap_zoom
2. [FAIL, NEW] res://tests/test_ui_minimap_zoom.gd:0 - Failed to load script "res://tests/test_ui_minimap_zoom.gd" with error "Compilation failed". - x1 in: test_ui_minimap_zoom
Failed tests:
- test_ui_minimap_zoom: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL ui_minimap_zoom: navigation never finished baking
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_ui_minimap_zoom.log):
       at: GDScript::reload (res://scripts/ui/minimap.gd:0)
    SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
       at: GDScript::reload (res://tests/test_ui_minimap_zoom.gd:0)
    ERROR: Failed to load script "res://tests/test_ui_minimap_zoom.gd" with error "Compilation failed".
       at: load (modules/gdscript/gdscript_resource_format.cpp:46)
    SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
       at: _ready (res://scripts/world/main.gd:91)
       GDScript backtrace (most recent call first):
           [0] _ready (res://scripts/world/main.gd:91)
    FAIL ui_minimap_zoom: navigation never finished baking
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_ui_minimap_zoom.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_ui_minimap_zoom -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_unit_dances (2 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [FAIL, NEW] res://tests/test_unit_dances.gd:0 - Compile Error: Failed to compile depended scripts. - x1 in: test_unit_dances
2. [FAIL, NEW] res://tests/test_unit_dances.gd:0 - Failed to load script "res://tests/test_unit_dances.gd" with error "Compilation failed". - x1 in: test_unit_dances
Failed tests:
- test_unit_dances: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL unit_dances: timed out at step 2
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_unit_dances.log):
      shardguard (ice) dances dance_victory, arm moved 2.78 rad
      thornling (nature) dances dance_surrender, arm moved 1.52 rad
      vinelasher (nature) dances dance_random, arm moved 2.88 rad
      shade (shadow) dances dance_victory, arm moved 1.34 rad
      hexweaver (shadow) dances dance_surrender, arm moved 1.04 rad
      vessa.tscn (fire) dances dance_random, arm moved 0.79 rad
      torvald.tscn (ice) dances dance_victory, arm moved 2.93 rad
      ysolde.tscn (nature) dances dance_surrender, arm moved 1.53 rad
      malrik.tscn (shadow) dances dance_random, arm moved 2.89 rad
    FAIL unit_dances: timed out at step 2
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_unit_dances.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_unit_dances -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_ux_1 (2 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [FAIL, NEW] res://tests/test_ux_1.gd:0 - Compile Error: Failed to compile depended scripts. - x1 in: test_ux_1
2. [FAIL, NEW] res://tests/test_ux_1.gd:0 - Failed to load script "res://tests/test_ux_1.gd" with error "Compilation failed". - x1 in: test_ux_1
Failed tests:
- test_ux_1: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL ux.1: navigation never finished baking
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_ux_1.log):
       at: GDScript::reload (res://scripts/ui/hud.gd:124)
    SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
       at: GDScript::reload (res://tests/test_ux_1.gd:0)
    ERROR: Failed to load script "res://tests/test_ux_1.gd" with error "Compilation failed".
       at: load (modules/gdscript/gdscript_resource_format.cpp:46)
    SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
       at: _ready (res://scripts/world/main.gd:91)
       GDScript backtrace (most recent call first):
           [0] _ready (res://scripts/world/main.gd:91)
    FAIL ux.1: navigation never finished baking
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_ux_1.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_ux_1 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### map_lab owner (lab) (1 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [FAIL, NEW] res://tests/test_map_lab.gd:27 - Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". - x1 in: test_map_lab
Failed tests:
- test_map_lab: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL map_lab: the skirmish never finished its bake
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_map_lab.log):
       at: load (modules/gdscript/gdscript_resource_format.cpp:46)
       GDScript backtrace (most recent call first):
           [0] _initialize (res://tests/test_map_lab.gd:27)
    SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
       at: Skirmish._ready (res://scripts/world/main.gd:91)
       GDScript backtrace (most recent call first):
           [0] _ready (res://scripts/world/main.gd:91)
           [1] _ready (res://scripts/world/skirmish.gd:407)
      - the skirmish never finished its bake
    FAIL map_lab: the skirmish never finished its bake
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_map_lab.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_map_lab -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_9_c3 (1 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [FAIL, NEW] res://tests/test_9_c3.gd:103 - Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". - x1 in: test_9_c3
Failed tests:
- test_9_c3: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 9.C3: navigation never finished baking
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_9_c3.log):
    ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
       at: load (modules/gdscript/gdscript_resource_format.cpp:46)
       GDScript backtrace (most recent call first):
           [0] _initialize (res://tests/test_9_c3.gd:103)
    SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
       at: Skirmish._ready (res://scripts/world/main.gd:91)
       GDScript backtrace (most recent call first):
           [0] _ready (res://scripts/world/main.gd:91)
           [1] _ready (res://scripts/world/skirmish.gd:407)
    FAIL 9.C3: navigation never finished baking
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_9_c3.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_9_c3 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_9_c6 (1 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [FAIL, NEW] res://tests/test_9_c6.gd:63 - Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". - x1 in: test_9_c6
Failed tests:
- test_9_c6: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 9.c6: navigation never finished baking
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_9_c6.log):
           [0] _initialize (res://tests/test_9_c6.gd:63)
    ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
       at: load (modules/gdscript/gdscript_resource_format.cpp:46)
       GDScript backtrace (most recent call first):
           [0] _initialize (res://tests/test_9_c6.gd:63)
    SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
       at: _ready (res://scripts/world/main.gd:91)
       GDScript backtrace (most recent call first):
           [0] _ready (res://scripts/world/main.gd:91)
    FAIL 9.c6: navigation never finished baking
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_9_c6.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_9_c6 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_9_c7 (1 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [FAIL, NEW] res://tests/test_9_c7.gd:175 - Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". - x1 in: test_9_c7
Failed tests:
- test_9_c7: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 9.c7: navigation never finished baking
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_9_c7.log):
           [0] _initialize (res://tests/test_9_c7.gd:175)
    ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
       at: load (modules/gdscript/gdscript_resource_format.cpp:46)
       GDScript backtrace (most recent call first):
           [0] _initialize (res://tests/test_9_c7.gd:175)
    SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
       at: _ready (res://scripts/world/main.gd:91)
       GDScript backtrace (most recent call first):
           [0] _ready (res://scripts/world/main.gd:91)
    FAIL 9.c7: navigation never finished baking
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_9_c7.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_9_c7 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_a2_3 (1 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [FAIL, NEW] res://tests/test_a2_3.gd:114 - Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". - x1 in: test_a2_3
Failed tests:
- test_a2_3: assert (exit 1; FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL a2.3: navigation never finished baking
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_a2_3.log):
       at: load (modules/gdscript/gdscript_resource_format.cpp:46)
       GDScript backtrace (most recent call first):
           [0] _process (res://tests/test_a2_3.gd:114)
    SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
       at: Skirmish._ready (res://scripts/world/main.gd:91)
       GDScript backtrace (most recent call first):
           [0] _ready (res://scripts/world/main.gd:91)
           [1] _ready (res://scripts/world/skirmish.gd:407)
           [2] _process (res://tests/test_a2_3.gd:118)
    FAIL a2.3: navigation never finished baking
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_a2_3.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_a2_3 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_caravan_pop (1 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [FAIL, NEW] res://tests/test_caravan_pop.gd:18 - Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". - x1 in: test_caravan_pop
Failed tests:
- test_caravan_pop: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL caravan_pop: navigation never finished baking
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_caravan_pop.log):
    ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
       at: load (modules/gdscript/gdscript_resource_format.cpp:46)
       GDScript backtrace (most recent call first):
           [0] _initialize (res://tests/test_caravan_pop.gd:18)
    SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
       at: Skirmish._ready (res://scripts/world/main.gd:91)
       GDScript backtrace (most recent call first):
           [0] _ready (res://scripts/world/main.gd:91)
           [1] _ready (res://scripts/world/skirmish.gd:407)
    FAIL caravan_pop: navigation never finished baking
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_caravan_pop.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_caravan_pop -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_fix_groups (1 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [FAIL, NEW] res://tests/test_fix_groups.gd:30 - Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". - x1 in: test_fix_groups
Failed tests:
- test_fix_groups: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL fix_groups: navigation never finished baking
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_fix_groups.log):
           [0] _initialize (res://tests/test_fix_groups.gd:30)
    ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
       at: load (modules/gdscript/gdscript_resource_format.cpp:46)
       GDScript backtrace (most recent call first):
           [0] _initialize (res://tests/test_fix_groups.gd:30)
    SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
       at: _ready (res://scripts/world/main.gd:91)
       GDScript backtrace (most recent call first):
           [0] _ready (res://scripts/world/main.gd:91)
    FAIL fix_groups: navigation never finished baking
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_fix_groups.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_fix_groups -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_fix_minimap_click (1 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [FAIL, NEW] res://tests/test_fix_minimap_click.gd:32 - Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". - x1 in: test_fix_minimap_click
Failed tests:
- test_fix_minimap_click: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL fix_minimap_click: navigation never finished baking
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_fix_minimap_click.log):
           [0] _initialize (res://tests/test_fix_minimap_click.gd:32)
    ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
       at: load (modules/gdscript/gdscript_resource_format.cpp:46)
       GDScript backtrace (most recent call first):
           [0] _initialize (res://tests/test_fix_minimap_click.gd:32)
    SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
       at: _ready (res://scripts/world/main.gd:91)
       GDScript backtrace (most recent call first):
           [0] _ready (res://scripts/world/main.gd:91)
    FAIL fix_minimap_click: navigation never finished baking
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_fix_minimap_click.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_fix_minimap_click -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_lead_item_passives (1 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [FAIL, NEW] res://tests/test_lead_item_passives.gd:13 - Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". - x1 in: test_lead_item_passives
Failed tests:
- test_lead_item_passives: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL lead_item_passives: map never ready
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_lead_item_passives.log):
    ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
       at: load (modules/gdscript/gdscript_resource_format.cpp:46)
       GDScript backtrace (most recent call first):
           [0] _initialize (res://tests/test_lead_item_passives.gd:13)
    SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
       at: Skirmish._ready (res://scripts/world/main.gd:91)
       GDScript backtrace (most recent call first):
           [0] _ready (res://scripts/world/main.gd:91)
           [1] _ready (res://scripts/world/skirmish.gd:407)
    FAIL lead_item_passives: map never ready
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_lead_item_passives.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_lead_item_passives -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_map_p1 (1 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [FAIL, NEW] res://tests/test_map_p1.gd:30 - Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". - x1 in: test_map_p1
Failed tests:
- test_map_p1: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL MAP.P1: the skirmish never finished loading
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_map_p1.log):
       at: load (modules/gdscript/gdscript_resource_format.cpp:46)
       GDScript backtrace (most recent call first):
           [0] _initialize (res://tests/test_map_p1.gd:30)
    SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
       at: Skirmish._ready (res://scripts/world/main.gd:91)
       GDScript backtrace (most recent call first):
           [0] _ready (res://scripts/world/main.gd:91)
           [1] _ready (res://scripts/world/skirmish.gd:407)
      - the skirmish never finished loading
    FAIL MAP.P1: the skirmish never finished loading
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_map_p1.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_map_p1 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_sound_plan (1 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [FAIL, NEW] res://tests/test_sound_plan.gd:61 - Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". - x1 in: test_sound_plan
Failed tests:
- test_sound_plan: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL sound_plan: 1 problem(s)
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_sound_plan.log):
       at: load (modules/gdscript/gdscript_resource_format.cpp:46)
       GDScript backtrace (most recent call first):
           [0] _process (res://tests/test_sound_plan.gd:61)
    SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
       at: _ready (res://scripts/world/main.gd:91)
       GDScript backtrace (most recent call first):
           [0] _ready (res://scripts/world/main.gd:91)
           [1] _process (res://tests/test_sound_plan.gd:62)
      - navigation never finished baking
    FAIL sound_plan: 1 problem(s)
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_sound_plan.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_sound_plan -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_str_int (1 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [FAIL, NEW] res://tests/test_str_int.gd:29 - Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". - x1 in: test_str_int
Failed tests:
- test_str_int: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL str_int: map never ready
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_str_int.log):
    ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
       at: load (modules/gdscript/gdscript_resource_format.cpp:46)
       GDScript backtrace (most recent call first):
           [0] _initialize (res://tests/test_str_int.gd:29)
    SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
       at: Skirmish._ready (res://scripts/world/main.gd:91)
       GDScript backtrace (most recent call first):
           [0] _ready (res://scripts/world/main.gd:91)
           [1] _ready (res://scripts/world/skirmish.gd:407)
    FAIL str_int: map never ready
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_str_int.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_str_int -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_unit_voice (1 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [FAIL, NEW] res://tests/test_unit_voice.gd:40 - Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". - x1 in: test_unit_voice
Failed tests:
- test_unit_voice: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL unit_voice: navigation never finished baking
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_unit_voice.log):
    ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
       at: load (modules/gdscript/gdscript_resource_format.cpp:46)
       GDScript backtrace (most recent call first):
           [0] _process (res://tests/test_unit_voice.gd:40)
    SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
       at: _ready (res://scripts/world/main.gd:91)
       GDScript backtrace (most recent call first):
           [0] _ready (res://scripts/world/main.gd:91)
           [1] _process (res://tests/test_unit_voice.gd:41)
    FAIL unit_voice: navigation never finished baking
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_unit_voice.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_unit_voice -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### lab group B (simulation) (0 errors, 2 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Failed tests:
- test_bot_lab: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL bot lab: fire-ice_s1.json has no 'score'
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_bot_lab.log):
    bot lab test: 2 match(es) started (C:/Users/elzzo/AppData/Roaming/Godot/app_userdata/Four Wizards RTS/bot_lab_test), 120 game s each
    FAIL bot lab: fire-ice_s1.json has no 'score'
- test_replay_lab: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL replay_lab: timed out waiting for script_rec
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_replay_lab.log):
    REPLAY_LAB took 1500 s
    FAIL replay_lab: timed out waiting for script_rec
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_bot_lab.gd --fixed-fps 60 --quit-after 40000
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_replay_lab.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_bot_lab,test_replay_lab -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_a2_9 (1 errors, 0 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [FAIL, NEW] res://tests/test_a2_9.gd:73 - Failed to load script "res://scripts/ui/champion_bar.gd" with error "Compilation failed". - x1 in: test_a2_9
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_a2_9.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_a2_9 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_tool_voice_forge (1 errors, 0 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [FAIL, NEW] res://tests/test_tool_voice_forge.gd:76 - Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed". - x1 in: test_tool_voice_forge
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_tool_voice_forge.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_tool_voice_forge -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_10_c8 (0 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Failed tests:
- test_10_c8: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 10.c8: top bar rect [P: (479.5, 8.0), S: (641.0, 40.0)], expected (488, 8, 624, 40) (step 3)
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_10_c8.log):
    FAIL 10.c8: top bar rect [P: (479.5, 8.0), S: (641.0, 40.0)], expected (488, 8, 624, 40) (step 3)
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_10_c8.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_10_c8 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_11_c4 (0 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Failed tests:
- test_11_c4: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 11.c4: 3 problem(s) (step 3)
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_11_c4.log):
      - ability line 0 height 18.0
      - ability line 1 height 18.0
      - ability line 2 height 18.0
    FAIL 11.c4: 3 problem(s) (step 3)
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_11_c4.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_11_c4 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_12_c7 (0 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Failed tests:
- test_12_c7: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 12.C7: blessing chip rects [P: (958.0, 54.0), S: (144.0, 23.0)] [P: (958.0, 78.0), S: (144.0, 23.0)]
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_12_c7.log):
      x blessing chip rects [P: (958.0, 54.0), S: (144.0, 23.0)] [P: (958.0, 78.0), S: (144.0, 23.0)]
      note: hint 701 px at font 22 (pushed under the help panel when > 636)
    FAIL 12.C7: blessing chip rects [P: (958.0, 54.0), S: (144.0, 23.0)] [P: (958.0, 78.0), S: (144.0, 23.0)]
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_12_c7.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_12_c7 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_12_c9 (0 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Failed tests:
- test_12_c9: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 12.C9: 12 problem(s)
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_12_c9.log):
      - frost_mortar projectile_speed: got 18.000, want 25.000
      - frostbow projectile_speed: got 30.000, want 25.000
      - hexweaver projectile_speed: got 24.000, want 25.000
      - hoarlight_magebow projectile_speed: got 28.000, want 25.000
      - pyre_adept projectile_speed: got 24.000, want 25.000
      - scorchbow projectile_speed: got 26.000, want 25.000
      - stormbottle_genie projectile_speed: got 40.000, want 25.000
      - thistle_darter projectile_speed: got 26.000, want 25.000
      - Unit.MAX_UNIT_RADIUS 1.10 >= 1.20
    FAIL 12.C9: 12 problem(s)
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_12_c9.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_12_c9 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_6_b2 (0 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Failed tests:
- test_6_b2: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 6.B2: fire_hearth data; shadow_hovel data
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_6_b2.log):
    FAIL 6.B2: fire_hearth data; shadow_hovel data
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_6_b2.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_6_b2 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_9_c11 (0 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Failed tests:
- test_9_c11: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 9.C11: navigation never finished baking
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_9_c11.log):
    SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
       at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
    ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
       at: load (modules/gdscript/gdscript_resource_format.cpp:46)
    SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
       at: Skirmish._ready (res://scripts/world/main.gd:91)
       GDScript backtrace (most recent call first):
           [0] _ready (res://scripts/world/main.gd:91)
           [1] _ready (res://scripts/world/skirmish.gd:407)
    FAIL 9.C11: navigation never finished baking
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_9_c11.gd --fixed-fps 60 --quit-after 95000
Done when: tools\error_lab\error_lab.ps1 -Tests test_9_c11 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_9_c5 (0 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Failed tests:
- test_9_c5: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 9.C5: navigation never finished baking
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_9_c5.log):
    SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
       at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
    ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
       at: load (modules/gdscript/gdscript_resource_format.cpp:46)
    SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
       at: Skirmish._ready (res://scripts/world/main.gd:91)
       GDScript backtrace (most recent call first):
           [0] _ready (res://scripts/world/main.gd:91)
           [1] _ready (res://scripts/world/skirmish.gd:407)
    FAIL 9.C5: navigation never finished baking
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_9_c5.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_9_c5 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_9_c9 (0 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Failed tests:
- test_9_c9: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 9.C9: navigation never finished baking
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_9_c9.log):
       at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
    ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
       at: load (modules/gdscript/gdscript_resource_format.cpp:46)
    part 0: champion knobs, revive rule and champion strength checked
    SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
       at: Skirmish._ready (res://scripts/world/main.gd:91)
       GDScript backtrace (most recent call first):
           [0] _ready (res://scripts/world/main.gd:91)
           [1] _ready (res://scripts/world/skirmish.gd:407)
    FAIL 9.C9: navigation never finished baking
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_9_c9.gd --fixed-fps 60 --quit-after 150000
Done when: tools\error_lab\error_lab.ps1 -Tests test_9_c9 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_bowmen (0 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Failed tests:
- test_bowmen: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL bowmen: navigation never finished baking
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_bowmen.log):
    SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
       at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
    ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
       at: load (modules/gdscript/gdscript_resource_format.cpp:46)
    SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
       at: Skirmish._ready (res://scripts/world/main.gd:91)
       GDScript backtrace (most recent call first):
           [0] _ready (res://scripts/world/main.gd:91)
           [1] _ready (res://scripts/world/skirmish.gd:407)
    FAIL bowmen: navigation never finished baking
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_bowmen.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_bowmen -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_new_units_12 (0 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Failed tests:
- test_new_units_12: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL new_units_12: navigation never finished baking
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_new_units_12.log):
    SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
       at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
    ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
       at: load (modules/gdscript/gdscript_resource_format.cpp:46)
    SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
       at: Skirmish._ready (res://scripts/world/main.gd:91)
       GDScript backtrace (most recent call first):
           [0] _ready (res://scripts/world/main.gd:91)
           [1] _ready (res://scripts/world/skirmish.gd:407)
    FAIL new_units_12: navigation never finished baking
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_new_units_12.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_new_units_12 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_pop_200 (0 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Failed tests:
- test_pop_200: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL pop_200: navigation never finished baking
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_pop_200.log):
       at: GDScript::reload (res://scripts/ui/selection_manager.gd:0)
    SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
       at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
    ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
       at: load (modules/gdscript/gdscript_resource_format.cpp:46)
    SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
       at: _ready (res://scripts/world/main.gd:91)
       GDScript backtrace (most recent call first):
           [0] _ready (res://scripts/world/main.gd:91)
    FAIL pop_200: navigation never finished baking
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_pop_200.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_pop_200 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_t3 (0 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Failed tests:
- test_t3: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL t3: navigation never finished baking
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_t3.log):
    SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
       at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
    ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
       at: load (modules/gdscript/gdscript_resource_format.cpp:46)
    SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
       at: Skirmish._ready (res://scripts/world/main.gd:91)
       GDScript backtrace (most recent call first):
           [0] _ready (res://scripts/world/main.gd:91)
           [1] _ready (res://scripts/world/skirmish.gd:407)
    FAIL t3: navigation never finished baking
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_t3.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_t3 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_tiers (0 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Failed tests:
- test_tiers: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL tiers: navigation never finished baking
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_tiers.log):
       at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
    ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
       at: load (modules/gdscript/gdscript_resource_format.cpp:46)
    ---- part gates
    SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
       at: Skirmish._ready (res://scripts/world/main.gd:91)
       GDScript backtrace (most recent call first):
           [0] _ready (res://scripts/world/main.gd:91)
           [1] _ready (res://scripts/world/skirmish.gd:407)
    FAIL tiers: navigation never finished baking
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_tiers.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_tiers -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_ui_building_groups (0 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Failed tests:
- test_ui_building_groups: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL ui_building_groups: skirmish never started
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_ui_building_groups.log):
    SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
       at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
    ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
       at: load (modules/gdscript/gdscript_resource_format.cpp:46)
    SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
       at: Skirmish._ready (res://scripts/world/main.gd:91)
       GDScript backtrace (most recent call first):
           [0] _ready (res://scripts/world/main.gd:91)
           [1] _ready (res://scripts/world/skirmish.gd:407)
    FAIL ui_building_groups: skirmish never started
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_ui_building_groups.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_ui_building_groups -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_ui_restart_hint (0 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Failed tests:
- test_ui_restart_hint: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL ui_restart_hint: timed out at step 1
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_ui_restart_hint.log):
       at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
    ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
       at: load (modules/gdscript/gdscript_resource_format.cpp:46)
    SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
       at: _ready (res://scripts/world/main.gd:91)
       GDScript backtrace (most recent call first):
           [0] _ready (res://scripts/world/main.gd:91)
    hint before: Next: build an Ember Hall: select a worker, press B then X (150 crystals)
    hint after: Next: train soldiers: select the Ember Hall, press Z X C V
    FAIL ui_restart_hint: timed out at step 1
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_ui_restart_hint.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_ui_restart_hint -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### task agent of test_ui_train_queue (0 errors, 1 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Failed tests:
- test_ui_train_queue: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL ui_train_queue: skirmish never started
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\ci\playtest-t2t3\error_lab\logs\test_ui_train_queue.log):
    SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
       at: GDScript::reload (res://scripts/ui/menus/pause_menu.gd:0)
    ERROR: Failed to load script "res://scripts/ui/menus/pause_menu.gd" with error "Compilation failed".
       at: load (modules/gdscript/gdscript_resource_format.cpp:46)
    SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
       at: Skirmish._ready (res://scripts/world/main.gd:91)
       GDScript backtrace (most recent call first):
           [0] _ready (res://scripts/world/main.gd:91)
           [1] _ready (res://scripts/world/skirmish.gd:407)
    FAIL ui_train_queue: skirmish never started
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_ui_train_queue.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_ui_train_queue -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### ai-coder (engine error, no script frame) (3 errors, 0 failed tests)
```text
Task: fix what the Error Lab found (run ci-playtest-t2t3) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts-play2.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [WARN, NEW] engine core/variant/array.cpp:619 - Error calling method from 'filter': 'GDScript::<anonymous lambda>': Cannot convert argument N from Object to Object. - x1 in: test_2_a1_bot_vs_bot
2. [WARN, NEW] (no frame) - normal: the Coin-Cutter ignored a looting Magpie N s free / N s in all (intent Raiding) - x1 in: test_10_a3
3. [WARN] (no frame) - hard: no B7 Guard flag after a raid - x1 in: test_10_a3
Repro:
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_2_a1_bot_vs_bot.gd --fixed-fps 60 --quit-after 116000
  & tools\godot_run.ps1 --headless --path "C:\Users\elzzo\Documents\four-wizards-rts-play2" -s tests/test_10_a3.gd --fixed-fps 60 --quit-after 150000
Done when: tools\error_lab\error_lab.ps1 -Tests test_2_a1_bot_vs_bot,test_10_a3 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```
