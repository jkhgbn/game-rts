# Error Lab scorecard: baseline-2026-09-27-partial

2026-09-27 09:08 - lab v1.1 - 180 tests (7 failed) - project `C:\Users\elzzo\Documents\four-wizards-rts` - logs: `C:\Users\elzzo\Documents\four-wizards-rts\docs\errors\lab\baseline-2026-09-27\logs`

## Result: **FAIL** - score **14 / 100**

2 unique FAIL errors - 0 unique WARN errors - 4 INFO (exit noise) - 2 NEW (not in the last 10 history rows) - previous run day-end-2026-09-26: FAIL 38

Score = 100 - 8 per unique FAIL error - 3 per unique WARN error - 10 per failed test (min 0).

## Improve next
1. **tests/test_12_a1.gd** failed: **assert** (FAIL line; no PASS line) - owner **ai-coder**. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
2. **tests/test_12_v28.gd** failed: **assert** (FAIL line; no PASS line) - owner **tech-artist**. The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
3. **res://tests/test_13_v13.gd:287** (FAIL, NEW) - owner **tech-artist**: Invalid call. Nonexistent 'float' constructor. _(x1 in 1 tests: test_13_v13)_

## By owner (who has work)
| Owner | FAIL errors | WARN errors | Failed tests | Tests to re-run |
|---|---|---|---|---|
| tech-artist | 2 | 0 | test_12_v28 (assert), test_13_v13 (script error), test_13_v5 (assert), test_13c_v1 (script error) +1 more | test_13_v13, test_13c_v1, test_12_v28, test_13_v5, test_13c_v3 |
| ai-coder | 0 | 0 | test_12_a1 (assert), test_20_a3 (assert) | test_12_a1, test_20_a3 |

## Failed tests (diagnosis + log tail)

### test_12_a1 - assert - owner ai-coder
FAIL line; no PASS line;  s, cap . The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 12.A1: 2 problem(s)`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\errors\lab\baseline-2026-09-27\logs\test_12_a1.log):
```text
  [4:30] SCOUT Nightbolt to (-24, 36) via (-9, -34)
  [4:49] SQUAD back: Mossmere Well done
  [4:50] SCOUT next (-24, 48)
  [4:52] SCOUT next (-36, 48)
  [4:53] SCOUT next (-48, 48)
  [4:56] SCOUT hurt, coming home
  [5:01] SQUAD 3 units to Rookwatch
  [5:20] SQUAD back: Rookwatch done
  [5:29] SQUAD 3 units to Millwatch
finished after 46807 frames
NOTE normal: 1 rule-7 attacks (pop capped)
NOTE hard: deer shots 0
ERROR normal: map-fill median 0.129 ms per tick (limit 0.10)
ERROR hard: map-fill median 0.117 ms per tick (limit 0.10)
FAIL 12.A1: 2 problem(s)
```

### test_12_v28 - assert - owner tech-artist
FAIL line; no PASS line;  s, cap . The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 12.v28: nothing below 1.2 m while gliding (1.05)`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\errors\lab\baseline-2026-09-27\logs\test_12_v28.log):
```text
  lowest HeadMesh 0.360
  lowest Neck2Mesh 0.390
  lowest Neck1Mesh 0.202
  lowest WingL2Mesh 0.467
  lowest WingLMesh 0.568
  lowest WingR2Mesh 0.115
  lowest WingRMesh 0.340
  lowest Tail1Mesh 0.309
  lowest LegFLMesh 0.175
  lowest LegFRMesh 0.112
  lowest BodyMesh -0.018
death 1.15 s: body 0.50 m, lowest -0.018, eyes 0.00, bursts 3
death_finished at 1.80 s
revived: body 2.55, eyes 1.00
FAIL 12.v28: nothing below 1.2 m while gliding (1.05)
```

### test_13_v13 - script error - owner tech-artist
no PASS line;  s, cap . A script error stopped the test before its PASS line: fix the first FAIL-class error listed for this test.

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\errors\lab\baseline-2026-09-27\logs\test_13_v13.log):
```text
authored meshes (blob included) 17, particle systems 2, draw instances 19
materials: 5 own + 1 shared (res://art/units/titans/cinder_dragon/cinder_scale.tres, res://art/units/titans/cinder_dragon/cinder_horn.tres, res://art/units/titans/cinder_dragon/cinder_lava.tres, res://art/units/titans/cinder_dragon/cinder_flame.tres, res://art/units/titans/cinder_dragon/cinder_membrane.tres, res://art/units/kit/materials/unit_shadow_blob.tres); vertices 9476; shadow casters 10
rest extent: span 7.51 (membranes 7.04), length 8.41, y 3.18 .. 6.11
hover: tip swing 4.76 m, beat period 1.20 s, body bob 0.42 m, span now 4.03
forward flight: tip range 4.51 m; longest glide 2.23 s (tip range in it 0.39 m)
set_turning(120): +X wing tip 1.15, -X wing tip 4.88, body x axis y -0.55
measured turn (yaw -120 deg/s, no set_turning): body x axis y 0.55
breath: released at 0.35 s, jaw max 43 deg, open (> 24 deg) 0.63 s, head flare 2.70, head down 38 deg
breath origin at rest: (0.300265, 5.154871, -3.040702) forward (0.170955, 0.119, -0.978066)
SCRIPT ERROR: Invalid call. Nonexistent 'float' constructor.
   at: _run (res://tests/test_13_v13.gd:287)
   GDScript backtrace (most recent call first):
       [0] _run (res://tests/test_13_v13.gd:287)
```

### test_13_v5 - assert - owner tech-artist
FAIL line; no PASS line;  s, cap . The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 13.v5: nothing below the ground at rest (-0.015)`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\errors\lab\baseline-2026-09-27\logs\test_13_v5.log):
```text
  FAILED: nothing below the ground at rest (-0.015)
blossom petals: glow surfaces 1, vertices left / centre / right [175, 175, 175]
hollow stag bounds: top 3.69, width 3.02, length 3.30 (grove: top 2.97, rack 2.54, length 2.75)
red deer bounds: top 2.70, width 0.94, length 2.03
seat (model space) (0.001841, 1.633663, -0.196916)
walk: leg swing 21.9 deg, gallop blend 0.00
gallop: blend 1.00, bounce 0.090, seat bob 0.113, leg swing 38.0 deg, strides/s 2, neck 3.0 deg, head carried 0.076 m
hit: body flash 0.58, leg 0.58, neck 0.58, root z -0.083
charge: head 35.6 deg (rack levelled), lunge z 0.41, toss -36.3 deg, blossom glow 1.00 -> 2.60
fidget: neck -1.4 -> 32.1 deg (grazing)
barded: draw instances 8, vertices 9301, body surfaces 8 -> 9
team colour on the barded body: [(0.85, 0.3, 0.12, 1.0), (0.3825, 0.135, 0.054, 1.0)]
slot collisions: 0
death: roll -27.6 -> -86.0 deg, lying bounds y -0.03..1.76, wither 0.12, blossoms 0.00, finished true
FAIL 13.v5: nothing below the ground at rest (-0.015)
```

### test_13c_v1 - script error - owner tech-artist
no PASS line;  s, cap . A script error stopped the test before its PASS line: fix the first FAIL-class error listed for this test.

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\errors\lab\baseline-2026-09-27\logs\test_13c_v1.log):
```text
authored meshes (blob included) 17, particle systems 2, draw instances 19
materials: 5 own + 1 shared (res://art/units/titans/frost_dragon/frost_scale.tres, res://art/units/titans/frost_dragon/frost_horn.tres, res://art/units/titans/frost_dragon/frost_ice.tres, res://art/units/titans/frost_dragon/frost_glow.tres, res://art/units/titans/frost_dragon/frost_membrane.tres, res://art/units/kit/materials/unit_shadow_blob.tres)
triangles 13258, vertices 8580, shadow casters 10
glow parts (cold glow / glowing ice): JawMesh/frost_ice, JawMesh/frost_glow, HeadMesh/frost_ice, HeadMesh/frost_glow, Neck2Mesh/frost_ice, Neck1Mesh/frost_ice, WingLMesh/frost_ice, WingRMesh/frost_ice, Tail3Mesh/frost_ice, Tail2Mesh/frost_ice, Tail1Mesh/frost_ice, BodyMesh/frost_ice
KITFIX AUDIT OK (frost dragon: slot map, no collision)
rest extent: span 7.98 (membranes 7.50), length 7.65, y 3.18 .. 6.14 (top: HeadMesh/frost_ice.tres)
hover: tip swing 5.06 m, beat period 1.28 s, body bob 0.42 m
forward flight: longest glide 1.87 s
set_turning(110): body x axis y -0.52
breath: released at 0.35 s, jaw max 44 deg, open 0.63 s, throat glow 2.70, neck spines 2.27
breath origin at rest: (-0.594206, 5.251147, -2.904703) forward (-0.153867, 0.114986, -0.981378)
SCRIPT ERROR: Invalid call. Nonexistent 'float' constructor.
   at: _run (res://tests/test_13c_v1.gd:317)
   GDScript backtrace (most recent call first):
       [0] _run (res://tests/test_13c_v1.gd:317)
```

### test_13c_v3 - assert - owner tech-artist
FAIL line; no PASS line;  s, cap . The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 13c.v3: nothing under the ground`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\errors\lab\baseline-2026-09-27\logs\test_13c_v3.log):
```text
script chain: BarrowGiantModel > WardenModel > CharacterModel
meshes (blob + hidden mound included) 11, particle systems 2 (looping 0), draw instances in play 10, nodes 13
materials: 7 own + 3 kit (res://art/units/shadow/barrow_giant/materials/barrow_stone.tres, res://art/units/shadow/barrow_giant/materials/barrow_stone_dark.tres, res://art/units/kit/materials/shadow_silver.tres, res://art/units/shadow/barrow_giant/materials/barrow_shroud_cape.tres, res://art/units/shadow/barrow_giant/materials/barrow_soul_glow.tres, res://art/units/shadow/barrow_giant/materials/barrow_grave.tres, res://art/units/shadow/barrow_giant/materials/barrow_earth.tres, res://art/units/kit/materials/shadow_obsidian.tres, res://art/units/shadow/barrow_giant/materials/barrow_shroud_cloth.tres, res://art/units/kit/materials/unit_shadow_blob.tres)
triangles 2460, vertices 5457, shadow casters ArmL/Merged, ArmR/Gravestone, ArmR/Merged, Chest/Merged
KITFIX AUDIT OK (barrow giant: slot map, no collision)
rest extent: width 3.44, depth 2.63, height 5.26 (y -0.06 .. 5.26); slab 1.38 x 2.08, y 3.18 .. 5.26; body top 3.47; head top 3.06
  check failed: nothing under the ground
fists vs slab at rest: 0.000 m
team colour: chest surfaces tinted 2 (early instance 2), hip rag 1
walk: worst fist gap 0.000 m, footfall dust moves 4, arm rot diff 0.0000
throw: released at 0.58 s (origin y 3.48, 2.28 m from the rest slab), hidden from 0.60 to 1.08 s, lowest slab 0.13 m, wind-up z -1.03, core peak 2.40, rune reignites 2.60, ends 1.82 s, worst fist gap 0.000
death: finished 1 time(s) at 1.60 s, mound seen true (top 1.66 m, rune 2.20), body alpha at 1.1 s 1.00, core glow 0.00
warden: 11 draw instances, 9 materials
6 giants: 0.155 ms per frame (whole headless frame)
FAIL 13c.v3: nothing under the ground
```

### test_20_a3 - assert - owner ai-coder
FAIL line; no PASS line;  s, cap . The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).

FAIL line: `FAIL 20.A3: bot 0 median think 1.705 ms > 1.5 ms`

Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\errors\lab\baseline-2026-09-27\logs\test_20_a3.log):
```text
  sub (avg ms/max ms): scan.units 0.20/6.7
team 1: crystals 30, gathered 7030, pop 11 / 40
bot 1: ticks 973, median 1.951 ms, avg 2.563 ms, max 316.400 ms at 573 s; attacks 4 (first 230 s), stage 0, str 200 vs seen 1160
  steps (median ms/avg ms/max ms@s): scan 0.371/0.43/8.3@868, memory 0.166/0.20/24.5@730, champions 0.148/0.29/45.2@441, pending 0.139/0.14/1.5@788, items 0.128/0.17/15.9@861, mapfill_sense 0.097/0.12/1.9@934, trade 0.078/0.43/314.3@573, mapfill 0.076/0.13/2.9@169, trade_sense 0.062/0.07/1.0@783, train 0.056/0.08/8.2@176, wizard 0.050/0.08/2.8@676, economy 0.041/0.07/8.4@676, defend 0.037/0.13/2.6@789, attack 0.033/0.05/3.8@570, all_in 0.022/0.04/1.5@708, learn 0.017/0.02/0.8@623, track_workers 0.015/0.03/4.6@713, scout 0.011/0.03/0.9@373, exchange 0.010/0.02/3.2@713, build 0.009/0.23/39.1@168, concede 0.004/0.00/0.1@383, retreat 0.002/0.01/0.2@428
  attack blocks (ticks): { "no army": 408, "pop": 291, "group out": 132, "retreat": 34, "defending": 90, "rally": 14, "strength": 1 }
  sub (avg ms/max ms): scan.units 0.34/3.9
bot 0 think: median 1.705 ms, avg 1.998 ms, p95 3.713 ms, max 35.544 ms at 886 s
bot 0: no attack by 900 s, rule 7's own gates only 1 % of its blocked ticks: { "no army": 405, "pop": 161, "defending": 361, "group out": 31, "retreat": 5, "rally": 8 }
bot 0 (fire): 0 attacks, first -1 s, median 1.705 ms, max 35.544 ms
bot 1 think: median 1.951 ms, avg 2.563 ms, p95 3.942 ms, max 316.400 ms at 573 s
bot 1 (shadow): 4 attacks, first 230 s, median 1.951 ms, max 316.400 ms
match: over false at 960 s, winner -1
  bot 0 median think 1.705 ms > 1.5 ms
  bot 1 median think 1.951 ms > 1.5 ms
FAIL 20.A3: bot 0 median think 1.705 ms > 1.5 ms
```

## Tests
| Test | Result | Why | Exit | Seconds | Cap |
|---|---|---|---|---|---|
| test_1_g1 | PASS |  |  |  |  |
| test_1_g2 | PASS |  |  |  |  |
| test_1_g3 | PASS |  |  |  |  |
| test_1_s1 | PASS |  |  |  |  |
| test_1_s2 | PASS |  |  |  |  |
| test_1_s3 | PASS |  |  |  |  |
| test_1_u1 | PASS |  |  |  |  |
| test_1_u2 | PASS |  |  |  |  |
| test_1_u3 | PASS |  |  |  |  |
| test_1_u4 | PASS |  |  |  |  |
| test_1_u5 | PASS |  |  |  |  |
| test_10_a1 | PASS |  |  |  |  |
| test_10_a2 | PASS |  |  |  |  |
| test_10_a3 | PASS |  |  |  |  |
| test_10_c1 | PASS |  |  |  |  |
| test_10_c10 | PASS |  |  |  |  |
| test_10_c11 | PASS |  |  |  |  |
| test_10_c12 | PASS |  |  |  |  |
| test_10_c2 | PASS |  |  |  |  |
| test_10_c3 | PASS |  |  |  |  |
| test_10_c4 | PASS |  |  |  |  |
| test_10_c5 | PASS |  |  |  |  |
| test_10_c6 | PASS |  |  |  |  |
| test_10_c7 | PASS |  |  |  |  |
| test_10_c8 | PASS |  |  |  |  |
| test_10_c9 | PASS |  |  |  |  |
| test_10_v1 | PASS |  |  |  |  |
| test_10_v10 | PASS |  |  |  |  |
| test_10_v11 | PASS |  |  |  |  |
| test_10_v12 | PASS |  |  |  |  |
| test_10_v2 | PASS |  |  |  |  |
| test_10_v3 | PASS |  |  |  |  |
| test_10_v4 | PASS |  |  |  |  |
| test_10_v5 | PASS |  |  |  |  |
| test_10_v6 | PASS |  |  |  |  |
| test_10_v7 | PASS |  |  |  |  |
| test_10_v8 | PASS |  |  |  |  |
| test_10_v9 | PASS |  |  |  |  |
| test_11_a1 | PASS |  |  |  |  |
| test_11_c1 | PASS |  |  |  |  |
| test_11_c2 | PASS |  |  |  |  |
| test_11_c3 | PASS |  |  |  |  |
| test_11_c4 | PASS |  |  |  |  |
| test_11_c5 | PASS |  |  |  |  |
| test_11_v1 | PASS |  |  |  |  |
| test_11_v2 | PASS |  |  |  |  |
| test_11_v3 | PASS |  |  |  |  |
| test_11_v4 | PASS |  |  |  |  |
| test_11_v5 | PASS |  |  |  |  |
| test_11_v6 | PASS |  |  |  |  |
| test_11_v7 | PASS |  |  |  |  |
| test_12_a1 | **FAIL** (assert) | FAIL line; no PASS line |  |  |  |
| test_12_a2 | PASS |  |  |  |  |
| test_12_a3 | PASS |  |  |  |  |
| test_12_c1 | PASS |  |  |  |  |
| test_12_c10 | PASS |  |  |  |  |
| test_12_c11 | PASS |  |  |  |  |
| test_12_c2 | PASS |  |  |  |  |
| test_12_c3 | PASS |  |  |  |  |
| test_12_c4 | PASS |  |  |  |  |
| test_12_c5 | PASS |  |  |  |  |
| test_12_c6 | PASS |  |  |  |  |
| test_12_c7 | PASS |  |  |  |  |
| test_12_c8 | PASS |  |  |  |  |
| test_12_c9 | PASS |  |  |  |  |
| test_12_v1 | PASS |  |  |  |  |
| test_12_v10 | PASS |  |  |  |  |
| test_12_v11 | PASS |  |  |  |  |
| test_12_v12 | PASS |  |  |  |  |
| test_12_v13 | PASS |  |  |  |  |
| test_12_v14 | PASS |  |  |  |  |
| test_12_v15 | PASS |  |  |  |  |
| test_12_v16 | PASS |  |  |  |  |
| test_12_v17 | PASS |  |  |  |  |
| test_12_v18 | PASS |  |  |  |  |
| test_12_v19 | PASS |  |  |  |  |
| test_12_v2 | PASS |  |  |  |  |
| test_12_v20 | PASS |  |  |  |  |
| test_12_v21 | PASS |  |  |  |  |
| test_12_v22 | PASS |  |  |  |  |
| test_12_v23 | PASS |  |  |  |  |
| test_12_v24 | PASS |  |  |  |  |
| test_12_v25 | PASS |  |  |  |  |
| test_12_v27 | PASS |  |  |  |  |
| test_12_v28 | **FAIL** (assert) | FAIL line; no PASS line |  |  |  |
| test_12_v29 | PASS |  |  |  |  |
| test_12_v3 | PASS |  |  |  |  |
| test_12_v30 | PASS |  |  |  |  |
| test_12_v31 | PASS |  |  |  |  |
| test_12_v32 | PASS |  |  |  |  |
| test_12_v4 | PASS |  |  |  |  |
| test_12_v5 | PASS |  |  |  |  |
| test_12_v6 | PASS |  |  |  |  |
| test_12_v7 | PASS |  |  |  |  |
| test_12_v8 | PASS |  |  |  |  |
| test_12_v9 | PASS |  |  |  |  |
| test_12b_v2 | PASS |  |  |  |  |
| test_12b_v3 | PASS |  |  |  |  |
| test_12b_v4 | PASS |  |  |  |  |
| test_12b_v5 | PASS |  |  |  |  |
| test_13_v10 | PASS |  |  |  |  |
| test_13_v13 | **FAIL** (script error) | no PASS line |  |  |  |
| test_13_v14 | PASS |  |  |  |  |
| test_13_v15 | PASS |  |  |  |  |
| test_13_v16 | PASS |  |  |  |  |
| test_13_v18 | PASS |  |  |  |  |
| test_13_v19 | PASS |  |  |  |  |
| test_13_v1a | PASS |  |  |  |  |
| test_13_v1b | PASS |  |  |  |  |
| test_13_v2 | PASS |  |  |  |  |
| test_13_v20 | PASS |  |  |  |  |
| test_13_v25 | PASS |  |  |  |  |
| test_13_v26 | PASS |  |  |  |  |
| test_13_v3 | PASS |  |  |  |  |
| test_13_v5 | **FAIL** (assert) | FAIL line; no PASS line |  |  |  |
| test_13_v6 | PASS |  |  |  |  |
| test_13_v7 | PASS |  |  |  |  |
| test_13_v8 | PASS |  |  |  |  |
| test_13_v9 | PASS |  |  |  |  |
| test_13b_v1 | PASS |  |  |  |  |
| test_13b_v2 | PASS |  |  |  |  |
| test_13b_v3 | PASS |  |  |  |  |
| test_13b_v4 | PASS |  |  |  |  |
| test_13b_v5 | PASS |  |  |  |  |
| test_13b_v6 | PASS |  |  |  |  |
| test_13b_v7 | PASS |  |  |  |  |
| test_13b_v8 | PASS |  |  |  |  |
| test_13b_v9 | PASS |  |  |  |  |
| test_13c_v1 | **FAIL** (script error) | no PASS line |  |  |  |
| test_13c_v3 | **FAIL** (assert) | FAIL line; no PASS line |  |  |  |
| test_13c_v5 | PASS |  |  |  |  |
| test_13c_v7 | PASS |  |  |  |  |
| test_13c_v8 | PASS |  |  |  |  |
| test_13c_v9 | PASS |  |  |  |  |
| test_16a | PASS |  |  |  |  |
| test_2_a1_attack | PASS |  |  |  |  |
| test_2_a1_bot_vs_bot | PASS |  |  |  |  |
| test_2_a1_economy | PASS |  |  |  |  |
| test_2_a1_rules | PASS |  |  |  |  |
| test_2_g1 | PASS |  |  |  |  |
| test_2_g2 | PASS |  |  |  |  |
| test_2_g3 | PASS |  |  |  |  |
| test_2_s1 | PASS |  |  |  |  |
| test_2_s2 | PASS |  |  |  |  |
| test_2_s3 | PASS |  |  |  |  |
| test_2_u1 | PASS |  |  |  |  |
| test_20_a2 | PASS |  |  |  |  |
| test_20_a3 | **FAIL** (assert) | FAIL line; no PASS line |  |  |  |
| test_20_v0 | PASS |  |  |  |  |
| test_3_a1 | PASS |  |  |  |  |
| test_3_g1 | PASS |  |  |  |  |
| test_3_g2a | PASS |  |  |  |  |
| test_3_g2b | PASS |  |  |  |  |
| test_3_s1 | PASS |  |  |  |  |
| test_3_u1 | PASS |  |  |  |  |
| test_3_u3 | PASS |  |  |  |  |
| test_4_a1 | PASS |  |  |  |  |
| test_4_g1 | PASS |  |  |  |  |
| test_4_g2 | PASS |  |  |  |  |
| test_4_i1 | PASS |  |  |  |  |
| test_4_i2 | PASS |  |  |  |  |
| test_4_s1 | PASS |  |  |  |  |
| test_4_u1a | PASS |  |  |  |  |
| test_4_u1b | PASS |  |  |  |  |
| test_5_s1 | PASS |  |  |  |  |
| test_5_u1 | PASS |  |  |  |  |
| test_6_a1 | PASS |  |  |  |  |
| test_6_b2 | PASS |  |  |  |  |
| test_6_s1 | PASS |  |  |  |  |
| test_6_s2 | PASS |  |  |  |  |
| test_6_u1 | PASS |  |  |  |  |
| test_6_u2 | PASS |  |  |  |  |
| test_6_u3 | PASS |  |  |  |  |
| test_7_a1 | PASS |  |  |  |  |
| test_7_g1 | PASS |  |  |  |  |
| test_7_g2 | PASS |  |  |  |  |
| test_7_g3 | PASS |  |  |  |  |
| test_7_i1 | PASS |  |  |  |  |
| test_7_s1 | PASS |  |  |  |  |
| test_7_u1 | PASS |  |  |  |  |

## Unique errors
| # | Sev | New | Location | Owner | Count | Tests | Message |
|---|---|---|---|---|---|---|---|
| 1 | FAIL | NEW | res://tests/test_13_v13.gd:287 | tech-artist | 1 | test_13_v13 | Invalid call. Nonexistent 'float' constructor. |
| 2 | FAIL | NEW | res://tests/test_13c_v1.gd:317 | tech-artist | 1 | test_13c_v1 | Invalid call. Nonexistent 'float' constructor. |

## Gone vs the previous run (day-end-2026-09-26): fixed, or their test did not run this time
- hard: no B7 Guard flag after a raid @ (engine)
- N RIDs of type "CanvasItem" were leaked. @ (engine)
- N RID of type "CanvasItem" was leaked. @ (engine)
- ART LAB ERROR: scene not found: res://nope.tscn @ res://nope.tscn:0

## INFO (known exit noise, never FAIL)
- N ObjectDB instances were leaked at exit (run with `--verbose` for details). - x88 in 88 tests
- N resources still in use at exit (run with --verbose for details). - x88 in 88 tests
- N RID of type "CanvasItem" was leaked. - x1 in 1 tests
- N RIDs of type "CanvasItem" were leaked. - x1 in 1 tests

## Fix-agent briefs (one per owner; the lead's rule: any failure -> launch a fix agent)

### tech-artist (2 errors, 5 failed tests)
```text
Task: fix what the Error Lab found (run baseline-2026-09-27-partial) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Errors (location - message - hits):
1. [FAIL, NEW] res://tests/test_13_v13.gd:287 - Invalid call. Nonexistent 'float' constructor. - x1 in: test_13_v13
2. [FAIL, NEW] res://tests/test_13c_v1.gd:317 - Invalid call. Nonexistent 'float' constructor. - x1 in: test_13c_v1
Failed tests:
- test_12_v28: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 12.v28: nothing below 1.2 m while gliding (1.05)
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\errors\lab\baseline-2026-09-27\logs\test_12_v28.log):
      lowest WingR2Mesh 0.115
      lowest WingRMesh 0.340
      lowest Tail1Mesh 0.309
      lowest LegFLMesh 0.175
      lowest LegFRMesh 0.112
      lowest BodyMesh -0.018
    death 1.15 s: body 0.50 m, lowest -0.018, eyes 0.00, bursts 3
    death_finished at 1.80 s
    revived: body 2.55, eyes 1.00
    FAIL 12.v28: nothing below 1.2 m while gliding (1.05)
- test_13_v13: script error (no PASS line). A script error stopped the test before its PASS line: fix the first FAIL-class error listed for this test.
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\errors\lab\baseline-2026-09-27\logs\test_13_v13.log):
    hover: tip swing 4.76 m, beat period 1.20 s, body bob 0.42 m, span now 4.03
    forward flight: tip range 4.51 m; longest glide 2.23 s (tip range in it 0.39 m)
    set_turning(120): +X wing tip 1.15, -X wing tip 4.88, body x axis y -0.55
    measured turn (yaw -120 deg/s, no set_turning): body x axis y 0.55
    breath: released at 0.35 s, jaw max 43 deg, open (> 24 deg) 0.63 s, head flare 2.70, head down 38 deg
    breath origin at rest: (0.300265, 5.154871, -3.040702) forward (0.170955, 0.119, -0.978066)
    SCRIPT ERROR: Invalid call. Nonexistent 'float' constructor.
       at: _run (res://tests/test_13_v13.gd:287)
       GDScript backtrace (most recent call first):
           [0] _run (res://tests/test_13_v13.gd:287)
- test_13_v5: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 13.v5: nothing below the ground at rest (-0.015)
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\errors\lab\baseline-2026-09-27\logs\test_13_v5.log):
    walk: leg swing 21.9 deg, gallop blend 0.00
    gallop: blend 1.00, bounce 0.090, seat bob 0.113, leg swing 38.0 deg, strides/s 2, neck 3.0 deg, head carried 0.076 m
    hit: body flash 0.58, leg 0.58, neck 0.58, root z -0.083
    charge: head 35.6 deg (rack levelled), lunge z 0.41, toss -36.3 deg, blossom glow 1.00 -> 2.60
    fidget: neck -1.4 -> 32.1 deg (grazing)
    barded: draw instances 8, vertices 9301, body surfaces 8 -> 9
    team colour on the barded body: [(0.85, 0.3, 0.12, 1.0), (0.3825, 0.135, 0.054, 1.0)]
    slot collisions: 0
    death: roll -27.6 -> -86.0 deg, lying bounds y -0.03..1.76, wither 0.12, blossoms 0.00, finished true
    FAIL 13.v5: nothing below the ground at rest (-0.015)
- test_13c_v1: script error (no PASS line). A script error stopped the test before its PASS line: fix the first FAIL-class error listed for this test.
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\errors\lab\baseline-2026-09-27\logs\test_13c_v1.log):
    rest extent: span 7.98 (membranes 7.50), length 7.65, y 3.18 .. 6.14 (top: HeadMesh/frost_ice.tres)
    hover: tip swing 5.06 m, beat period 1.28 s, body bob 0.42 m
    forward flight: longest glide 1.87 s
    set_turning(110): body x axis y -0.52
    breath: released at 0.35 s, jaw max 44 deg, open 0.63 s, throat glow 2.70, neck spines 2.27
    breath origin at rest: (-0.594206, 5.251147, -2.904703) forward (-0.153867, 0.114986, -0.981378)
    SCRIPT ERROR: Invalid call. Nonexistent 'float' constructor.
       at: _run (res://tests/test_13c_v1.gd:317)
       GDScript backtrace (most recent call first):
           [0] _run (res://tests/test_13c_v1.gd:317)
- test_13c_v3: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 13c.v3: nothing under the ground
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\errors\lab\baseline-2026-09-27\logs\test_13c_v3.log):
    rest extent: width 3.44, depth 2.63, height 5.26 (y -0.06 .. 5.26); slab 1.38 x 2.08, y 3.18 .. 5.26; body top 3.47; head top 3.06
      check failed: nothing under the ground
    fists vs slab at rest: 0.000 m
    team colour: chest surfaces tinted 2 (early instance 2), hip rag 1
    walk: worst fist gap 0.000 m, footfall dust moves 4, arm rot diff 0.0000
    throw: released at 0.58 s (origin y 3.48, 2.28 m from the rest slab), hidden from 0.60 to 1.08 s, lowest slab 0.13 m, wind-up z -1.03, core peak 2.40, rune reignites 2.60, ends 1.82 s, worst fist gap 0.000
    death: finished 1 time(s) at 1.60 s, mound seen true (top 1.66 m, rune 2.20), body alpha at 1.1 s 1.00, core glow 0.00
    warden: 11 draw instances, 9 materials
    6 giants: 0.155 ms per frame (whole headless frame)
    FAIL 13c.v3: nothing under the ground
Repro:
  & tools\godot_run.ps1 --headless --path . -s tests/test_13_v13.gd --fixed-fps 60 --quit-after 40000
  & tools\godot_run.ps1 --headless --path . -s tests/test_13c_v1.gd --fixed-fps 60 --quit-after 40000
  & tools\godot_run.ps1 --headless --path . -s tests/test_12_v28.gd --fixed-fps 60 --quit-after 40000
Done when: tools\error_lab\error_lab.ps1 -Tests test_13_v13,test_13c_v1,test_12_v28,test_13_v5,test_13c_v3 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```

### ai-coder (0 errors, 2 failed tests)
```text
Task: fix what the Error Lab found (run baseline-2026-09-27-partial) in the Four Wizards RTS at C:\Users\elzzo\Documents\four-wizards-rts.
Read CLAUDE.md first; edit only files you own (else write docs/handoff/for-<owner>.md); never run git; launch Godot only through tools/godot_run.ps1.
Failed tests:
- test_12_a1: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 12.A1: 2 problem(s)
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\errors\lab\baseline-2026-09-27\logs\test_12_a1.log):
      [4:56] SCOUT hurt, coming home
      [5:01] SQUAD 3 units to Rookwatch
      [5:20] SQUAD back: Rookwatch done
      [5:29] SQUAD 3 units to Millwatch
    finished after 46807 frames
    NOTE normal: 1 rule-7 attacks (pop capped)
    NOTE hard: deer shots 0
    ERROR normal: map-fill median 0.129 ms per tick (limit 0.10)
    ERROR hard: map-fill median 0.117 ms per tick (limit 0.10)
    FAIL 12.A1: 2 problem(s)
- test_20_a3: assert (FAIL line; no PASS line). The test's own check failed: read the FAIL line, reproduce with the repro command, fix the code (or the test if the rule changed).
  FAIL line: FAIL 20.A3: bot 0 median think 1.705 ms > 1.5 ms
  Log tail (C:\Users\elzzo\Documents\four-wizards-rts\docs\errors\lab\baseline-2026-09-27\logs\test_20_a3.log):
      sub (avg ms/max ms): scan.units 0.34/3.9
    bot 0 think: median 1.705 ms, avg 1.998 ms, p95 3.713 ms, max 35.544 ms at 886 s
    bot 0: no attack by 900 s, rule 7's own gates only 1 % of its blocked ticks: { "no army": 405, "pop": 161, "defending": 361, "group out": 31, "retreat": 5, "rally": 8 }
    bot 0 (fire): 0 attacks, first -1 s, median 1.705 ms, max 35.544 ms
    bot 1 think: median 1.951 ms, avg 2.563 ms, p95 3.942 ms, max 316.400 ms at 573 s
    bot 1 (shadow): 4 attacks, first 230 s, median 1.951 ms, max 316.400 ms
    match: over false at 960 s, winner -1
      bot 0 median think 1.705 ms > 1.5 ms
      bot 1 median think 1.951 ms > 1.5 ms
    FAIL 20.A3: bot 0 median think 1.705 ms > 1.5 ms
Repro:
  & tools\godot_run.ps1 --headless --path . -s tests/test_12_a1.gd --fixed-fps 60 --quit-after 60000
  & tools\godot_run.ps1 --headless --path . -s tests/test_20_a3.gd --fixed-fps 60 --quit-after 80000
Done when: tools\error_lab\error_lab.ps1 -Tests test_12_a1,test_20_a3 -NoHistory shows none of these errors and those tests print PASS.
Report: files changed, root cause per error, the new Error Lab result line.
```
