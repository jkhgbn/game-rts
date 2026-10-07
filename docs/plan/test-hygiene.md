# Test hygiene: load-independent timing, and the tests that hard-code balance numbers

2026-10-07. Two lists: (1) how a test may wait or measure time so it does not flake on a loaded laptop, with the
tests fixed so far; (2) the tests that assert balance numbers (unit stats, costs, rewards, start resources), to update
together after a balance pass. Numbers in (2) were not changed.

## 1. Load-independent timing

### Rules
- **Wait in simulation time, not process frames.** Gameplay runs in `_physics_process` (Unit, ScoreKeeper, M00Cast...).
  A test that waits N `_process` frames assumes 1 physics tick per frame. That holds with `--fixed-fps 60` most of the
  time, but not without it (headless, uncapped: ~140 process frames per 60 ticks on the laptop) and not on every frame
  (Godot's physics jitter fix can run 0 or 2 ticks in one frame). Count `Engine.get_physics_frames()` since a mark
  instead, or wait until at least one tick ran after a change before checking its effect.
- **Judge timing as a ratio of a calibration loop, not in ms.** `_calib_once` (test_20_a3's fixed GDScript loop: 2048
  Vector3 / Dictionary iterations), sampled every 30 frames, best of 3, median over the run. Quiet laptop: 0.225-0.232
  ms. A budget in loops (or a ms budget scaled by `max(1, loop / 0.232)`) moves with the machine. Keep the plain ms
  verdict in the log as info. Run the calibration outside the timed span (restart the frame timer after it).
- **Hang guards may stay in frames** (`--quit-after`, "navigation never finished baking" after 5000 frames): the
  navmesh bake ends in 1-2 frames (measured: skirmish 2 frames, mission 0 1 frame), so a hit means a real problem.
  The CI's 2026-10-06 10:58 "never finished baking" lines (test_16a, test_19_c7, test_19_c7_sim) came from a compile
  break (`ForgeKit` not declared), not from load.
- A failure message of a timing check names what it waited for and the counts seen (ticks, frames, strikes, ms and
  loops), so one CI flake can be told from a real regression without a rerun.

### Tests fixed (2026-10-07)
| Test | Was | Now |
|---|---|---|
| `test_8_u1` | Sapling lifetime bar checked after 60 process frames ("24.57 / 25.0 after 1 s" = 60 / 141 s drained without `--fixed-fps`); W walk after 45 frames | waits 60 physics ticks (1 s) / 45 ticks; prints ticks, frames and the time left. Same 22-24.5 s window |
| `test_16a` | history checks one process frame after moving the fake clock | each step waits for >= 1 physics tick after the clock moved (ScoreKeeper samples in `_physics_process`) |
| `test_19_c7` | "Hush never used Blink Strike" after 1300 process frames | 1300 physics ticks, + one cooldown (660 ticks) per strike Hush aimed at Vey instead (at most 3); the message names the strikes, target, range and Vessa's HP |
| `test_ws_perf` | march p95 <= 16.7 ms wall clock (busy-laptop CI: 17.3-20.7 ms with a 14-17 ms average) | same 16.7 ms budget, scaled by the calibration loop (`max(1, loop / 0.232)`); prints p50 and p95 of march and clash, the loop, the load factor and the plain 16.7 ms verdict |
| `test_9_c9` | champion-rule median < 0.1 ms (hard part 0.067-0.094 quiet, 0.184 loaded) | <= 0.43 calibration loops (= 0.1 ms on the quiet laptop, test_12_a1's line); ms printed as info |

Already calibrated before: `test_20_a3`, `test_12_a1`, `test_11_a1`, `test_9_c5`.

### Still wall-clock sensitive (not changed here)
- `tests/perf_test.gd` and the Perf Lab: absolute frame-time budgets by design (lead-owned, run them on a quiet PC).
- Bot-vs-bot outcome tests (`test_stables` "no Stables rider by 600 s", `test_12_a1` behaviour checks, the `*_sim`
  missions): sim-time deterministic in the test, but threaded avoidance / nav (replay-lab.md step 0) can change a
  match; not a test-timing issue.

## 2. Tests that hard-code balance numbers

Update these together after a balance change (Balance Lab, data/units/*.tres, economy.md, champions.md...). Found by
scanning `tests/test_*.gd` for comparisons of stat-like names (hp, damage, cost, crystals, gold, essence, pop,
cooldown, range, speed, lifetime, radius, reward...) with numeric literals; count = matching lines. Tests that read
the number from the data (`UnitType.find(id).cost * m`) are safe and not listed for that line.

### Unit / building / spell stats
| Test | Lines | What |
|---|---|---|
| `test_bowmen` | 10 | bowman table: faction, cost, max_hp, attack_damage per unit |
| `test_casters` | 10 | caster cost 120, pop 2, train 30 s, tier 2, mana |
| `test_10_c2` | 6 | merchant units: name, cost, max_hp, faction |
| `test_11_c1` | 9 | class champions: ranged, projectile speed, stats table |
| `test_6_b2` | 5 | tower attack cooldown, max count, keeps 2500 HP, crystal node amounts |
| `test_7_s1`, `test_8_s1` | 4 / 6 | Ice / Nature spire damage 12 / 10, range 11 / 10, cooldown 1.5 / 1.2 |
| `test_1_g1`, `test_1_g3`, `test_1_s2` | 3 / 5 / 2 | Flame Guard 120 HP, Malrik 400 HP, keep 2500 HP |
| `test_2_g3` | 2 | neutral creep 300 HP, aggro 7 |
| `test_2_s3`, `test_3_g2a`, `test_3_g2b` | 4 / 1 / 7 | hero 350 HP x mult, shade champion 143 HP, level-up +25 HP |
| `test_4_g1` | 14 | shield 20, armor 25 (50 -> 40), damage overflow |
| `test_7_g1`, `test_7_g3` | 11 / 2 | chill: cooldown 1.375, speed 2.7, regen timings; chill 3 s |
| `test_8_g1`, `test_8_g2` | 10 / 2 | Nature: Sapling lifetime 25, Bloom heal 12, Thornling regen, Wild Bloom heal |
| `test_new_units_12` | 8 | Flashpoint 15 damage and other new-unit numbers |
| `test_unit_upgrades`, `test_tiers` | 8 / 4 | forge +6 % damage, 3 x 100 refund, Stronghold HP x1.2, unit HP x1.1, upgrade 200 |
| `test_9_c10` | 1 | Cutpurse bonus x1.24 on 25 damage |
| `test_t3` | 5 | Vey L4 / L8: 850 / 1050 HP, 35 damage |
| `test_12_c10`, `test_12_c11`, `test_12_a3` | 13 / 5 / 2 | critters 60 / 12 HP, venison heal 40 / 20, lair leash 14, beast regen |
| `test_12_c4` | 4 | beast sight 11-14 m |
| `test_8_u1` | 1 | Sapling lifetime 25 s (set by the test; the bar window follows it) |

### Economy: start resources, costs, pop
| Test | Lines | What |
|---|---|---|
| `test_2_s1` | 17 | start crystals 250, pop cap 20, hall 130 HP, building costs |
| `test_1_s1`, `test_1_s3`, `test_1_u2`, `test_1_u5` | 3 / 2 / 2 / 1 | node 600 crystals, enemy 250, unit cost 50 |
| `test_2_u1`, `test_1_u1` | 6 / 1 | build cost 150, 1000 crystals, top-bar widths |
| `test_pop_200` | 6 | pop cap limit 200, cap 20 / 180 |
| `test_m3_s2`, `test_m7_s1`, `test_19_c5` | 7 / 4 / 4 | mission start: pop cap 40 / 20, crystals 300, pop 26 |
| `test_e2m4`, `test_e3m1`, `test_e3m3`, `test_e3m4` | 3 / 2 / 3 / 3 | mission start crystals 300 / 300+400 essence / 400 / 450 |
| `test_mission_framework` | 9 | start_crystals 333 (hard), enemy 999, call essence 30, train 5 s |
| `test_stables` | 1 | refund 75 % |
| `test_10_a3` | 2 | Bazaar crystals 175 -> 275 |
| `test_ws_director` | 12 | Wave Strike pop overrides (3), prices derived from cost x mode mult |
| `test_i18n` | 1 | "Need 50 more crystals" |

### Champions, taverns, bounties, items, essence
| Test | Lines | What |
|---|---|---|
| `test_9_c4` | 28 | bounty min stakes 75 / 25 / 50 / 50, payouts |
| `test_12_c5`, `test_9_c8` | 11 / 7 | Guard stake 90, refund 80, chip "Explore 25 essence" |
| `test_9_c1`, `test_9_c3`, `test_9_c6`, `test_9_c7` | 3 / 8 / 8 / 8 | champion pop 2, growth 8 %, hire refusals, Ember Draught 150 heal, Stride +2.5, upkeep 1 / 10 s |
| `test_9_c5` | 1 | potion at 55 % HP |
| `test_11_c3`, `test_11_c4` | 8 / 8 | gold price 225 + 75 essence, fallback costs 225/275/325 + 75/100/125 |
| `test_4_i1`, `test_4_i2`, `test_8_i1`, `test_7_i1` | 9 / 7 / 6 / 3 | item prices 200, essence 150-165, artifact cost 250 / 1910-630, cooldowns 80 / 75 |
| `test_4_s1` | 3 | cache essence 80 / 100 / 120 by time |
| `test_12_c3`, `test_12_c2` | 13 / 7 | creep camp rewards (stag 50 essence, wallow 10, drop 30 %), well radius 6, 15 s capture, sight 22 |
| `test_m7_s3`, `test_m9_s3`, `test_m9_s3_defeat` | 4 / 1 / 1 | carried essence 700, +300 then 50 %, cap 1500, 150 + 400 |
| `test_m9_s1` | 8 | Heartfrost 1500 HP (normal) |
| `test_19_c7` | 9 | mission 0: Vessa 169 / 375, Hush 900 / 1200, wave counts A1-A5, brazier heal 2 / s |
| `test_e2m2`, `test_e2m5`, `test_e3m2` | 1 / 2 / 3 | Grove 900 HP, door HP, Hush 900 HP |

### Gold / trade
| Test | Lines | What |
|---|---|---|
| `test_10_c11` | 28 | GoldBank: 140 earned, trade 100, loot 30, reward 10, spend 500 refused |
| `test_10_c8` | 27 | top bar GOLD_EXTRA 124, gold 200 / 250 |
| `test_10_c5` | 14 | guild hire 1000 gold, contract durations 180 / 120 |
| `test_10_c12` | 14 | prices 225 crystals + 75 essence |
| `test_10_c1`, `test_10_c3`, `test_10_c4`, `test_10_c7` | 7 / 2 / 8 / 2 | trade income 120 / 20, ~56 gold / min, road weight 58, veteran 140 HP, cargo 119 |
| `test_12_c7` | 18 | point texts: +0.4 essence / s, +3 mana / s, 8 m, 2:30 |
| `test_20_a2`, `test_ui_card_hotkeys`, `test_e2m3` | 2 / 1 / 1 | gold 100 thresholds, exchange step x5, tribute 1000 |

### Labs (check the lab math on fixed inputs; update only if the lab defaults change)
`test_unit_lab` (10: +25 % damage mods, equal-cost pair within 8 %), `test_balance_lab` (3), `test_health` (3).

Not listed: scripted-run tactics in the `*_sim` tests (`hero.mana > 60` decides when the script casts; not an
assertion), visual footprint / radius checks (`test_10_v*`, `test_12_v*`), tool tests.
