# Bot Lab: fast bot-vs-bot batches for balance

Built 2026-09-26 (tools engineer). Runs many bot-vs-bot skirmish matches headless, in parallel, against a stable copy of
the game, and turns them into a win matrix report (targets of `docs/design/rush-balance.md` section 8).

## Files
| File | What |
|---|---|
| `tools/bot_lab/run_lab.ps1` | The runner: N Godot processes in parallel, one match each, `results.jsonl`, then the report |
| `tools/bot_lab/lab_match.gd` | One match (SceneTree script): both sides normal `Commander`s, sim mode, early stop, one JSON line |
| `tools/bot_lab/lab_report.gd` | `results.jsonl` -> `report.md` + `report.html` (self-contained) |
| `scripts/core/sim_mode.gd` | `SimMode.enabled` (static, off in the game). Read through a preload by the build-time art hooks |
| `tests/test_bot_lab.gd` | Smoke test: 2 short sim matches as child processes + the report |
| Hooks (art spawn only) | `scripts/world/main.gd`, `river_system.gd`, `neutral_camp.gd`, `epic_beasts.gd` skip draw-only art when `SimMode.enabled` |

Nothing else in the game changed. `scripts/units/unit.gd` is **not** touched: the model freeze is done from `lab_match.gd`.

## How to use
```powershell
# 16 ordered pairs (4 x 4, mirrors included) x seed 1, sim on, normal bots, balanced style, 4 in parallel:
powershell -ExecutionPolicy Bypass -File tools\bot_lab\run_lab.ps1
# Round A style: 6 seeds, results into a named folder
.\tools\bot_lab\run_lab.ps1 -Seeds (1..6) -OutDir C:\Users\elzzo\Documents\four-wizards-lab-runs\roundA
# One pair, per-side difficulty / style (style needs the step-16 bot: AIProfile.apply_style or Commander.style)
.\tools\bot_lab\run_lab.ps1 -Pairs fire:ice,ice:fire -Seeds (1..12) -Difficulty "player:hard,enemy:normal" -Style "player:rusher,enemy:balanced"
```
| Parameter | Default | Meaning |
|---|---|---|
| `-Dir` | `C:\Users\elzzo\Documents\four-wizards-rts-lab` | The project to run (the lab worktree; the lead moves it to tags, the lab never runs git) |
| `-Pairs` | all 16 | `player:enemy` kingdoms, comma list (`fire:ice,ice:fire`) |
| `-Seeds` | `1` | Seeds, e.g. `(1..6)`; each seeds every random system of the match |
| `-Parallel` | logical CPUs - 2 (4 here) | Godot processes at a time |
| `-Difficulty`, `-Style` | `normal`, `balanced` | Both sides, or `player:x,enemy:y` |
| `-Sim` | `on` | Sim mode (below) |
| `-Limit` | `1800` | Time limit (game s): ends on score (`time-score`) |
| `-Early` | `on` | Early stop on a clear score lead (below) |
| `-Tick` | `60` | Physics ticks per second (30 = faster, see "Speed", not the default) |
| `-Extra` | | More `lab_match.gd` args, e.g. `"--stall=0 --early-ratio=1.8"` |
| `-OutDir` | `..\four-wizards-lab-runs\<date-time>` | Results folder (outside the repo) |
| `-TimeoutMin` | `90` | Wall-clock guard per match (stops only its own process) |
| `-StopAt` | | `"00:45"`: no match starts after that clock time, running ones are stopped (own processes only), the report covers what finished |

**Godot traffic light**: every match holds one slot of the machine-wide gate of `tools/godot_run.ps1` (named semaphore
`Local\FourWizardsGodotGate`, `FW_GODOT_SLOTS` default 4) and starts only while fewer than `FW_GODOT_HARDCAP` (default 6)
Godot processes of any origin run; after `FW_GODOT_MAXWAIT` s (default 900) of waiting it starts anyway, like the gate.
So `-Parallel` never pushes the PC past the shared limit; the wait is polled, so `-StopAt` still works. (The import and
the final report run are a few seconds and are not gated.)

Output folder: `results.jsonl` (one JSON line per match, the runner adds `wall_s`, `cpu_s`, `script_errors`),
`matches\<pair>_s<seed>.json|.log|.err`, `report.md`, `report.html`. `lab_match.gd` / `lab_report.gd` are taken from
`-Dir` when it has them, else from the runner's own folder by absolute path, so the lab works on commits older than the
Bot Lab (sim mode is then "partial", see below). A fresh worktree is imported once automatically.

Single match by hand:
`$GODOT --headless --path <dir> -s tools/bot_lab/lab_match.gd --fixed-fps 60 --quit-after 118000 -- --pair=fire:shadow --seed=1 --sim=1 --out=C:/tmp/m.json`
(all flags are listed at the top of `lab_match.gd`). Profiling: `--profile=1` prints ms/frame every game minute;
`--ablate=300` switches each system off in turn at 5:00 and prints its cost per frame (disturbs the match, profile only).

## The match (lab_match.gd)
- `scenes/skirmish.tscn`, `player_kingdom` / `enemy_kingdom` from `--pair`, the scene's own ENEMY `Commander` plus one for
  the PLAYER (like `tests/test_2_a1_bot_vs_bot.gd`), difficulty set before they enter the tree, `debug_log` off.
- Style: `balanced` = today's bot. Another style is applied only if the bot supports it (`Commander.style`, or
  `AIProfile.apply_style(p, style, faction)` handed over as `Commander.profile`); `style_applied` says whether it was.
- Seeds: `seed()` for the global rng, the `rng` of ThievesGuild / CampManager / EpicBeasts / CritterHerds / Lost Caches,
  and every node's `class_rng` / `_rng` (champions, champion brains, critters) right after its `_ready`.
- `time_limit_s` of the skirmish is set to 0: the lab decides the end with the same rule on every commit.
- **End reasons**: `kill` (every defeat-relevant building down), `concede` (the bot surrendered: the loser still had
  buildings), `early-score`, `time-score` (at `--limit`), `stall` (`--stall` game seconds, default 300, with no unit /
  building lost and no crystal mined by either side, or 120 s with neither side owning a worker or a soldier: flag
  `both_dead`, seen in fire:shadow where both economies are mined out by ~15:00), `cap` (frame cap, should not
  happen), `error`.
- **Score**: the match's `ScoreKeeper` (group `"score"`, `scripts/world/score_keeper.gd`) when it exists (created by the
  lab at match start if the skirmish did not); else the fallback score = army value (cost of living soldiers) + bank +
  buildings (keep 400) + 50 per worker + half the crystals gathered. The JSON says which (`score.source`).
- **Early stop** (`--early=1`, default): after `--early-min` (480 s), the leader's score >= `--early-ratio` (1.5) x the
  other's **and** >= `--early-margin` ahead (3000 ScoreKeeper points, 1500 fallback points), held for `--early-hold`
  (180 s). With `--early=0` the would-be call is still logged (`early_call`), and the report checks it against the
  real winner ("Early-stop check"): run a batch with `-Early off` to recalibrate.
- **Stall flags**: `<side>_no_workers` (alive with no worker for 60 s), `<side>_floating_crystals` (> 1500 for 180 s),
  `stall`; `max_quiet_s` = longest time without a kill or a mined crystal.
- **JSON** (one line): pair, seed, difficulty, style, sim, tick, winner / winner_side / winner_team, end_reason,
  end_time, score table (categories + total per side, margin, source), stats per side (peak army pop and value, peak
  workers, workers / army / buildings / crystals at the end, gathered, units trained / lost / killed, buildings lost,
  gold earned, camps, points held, wizard level, attacks, first attack, bot tick ms), snapshots at 3 / 5 / 7 / 10 / 15 /
  20 min (army pop, workers, gathered, buildings, worth), stall flags, early_call, real_s, startup_s, fps, speed, bakes.

## Sim mode
Goal: skip what only draws, keep gameplay identical (navmesh, colliders, fog, AI, economy, timings).
| Part | Where | What |
|---|---|---|
| VFX / audio / horizon | `lab_match.gd` | The level's `SpellVfx`, `CombatVfx`, `IceVfx`, `NatureVfx`, `ChampionVfx`, `TradeVfx`, `MapFillVfx`, `TitanVfx`, `UnitVfx`, `GameAudio`, `Horizon` are freed before the level enters the tree (the game only finds them through groups, guarded) |
| Models and prop art | `lab_match.gd` | Every node with a script under `res://art/` or `res://scripts/vfx/` gets `process_mode = DISABLED` when it enters the tree: `_ready` and every hook call still run (same `has_method` answers, `attack_windup`, signals), only the per-frame animation stops. A model inside a Unit (signal `died`) or a Building (signal `destroyed`) wakes up when its owner dies, so `death_finished` / `destroyed_finished` (which free the corpse / ruin, and its pop) come at the normal time. Art with signals of its own and no such owner keeps running |
| UI | `lab_match.gd` | HUD, camera, selection, pause menu and every CanvasLayer: process off and hidden (they still receive their calls) |
| Build-time decor | `SimMode.enabled` hooks | main.gd: no lighting rig, MapDressingArt, CritterSystem (cosmetic), EnvProps, ground paint; placeholder trees / rocks / pillars keep their colliders (same shapes) without meshes (willows fall back to the same collider). RiverSystem `build_visuals = false` (carve, colliders, crossings unchanged; bridge models have no collider). NeutralCamp: no site art; EpicBeasts: no lair art (neither has colliders) |
"full" = both; "partial" = the lab_match part only (a commit without `scripts/core/sim_mode.gd`, or `--sim-hooks=0`).
The per-frame savings are the same; "full" only starts faster.

Known, accepted differences: a frozen champion model's `get_weapon_tip()` / `get_beam_origin()` stay at the rest pose, so
its bolts start a few cm off (flight time differs by a few ms).

### Navmesh rebakes (`--bake=real`, default)
Every placed or destroyed building rebakes the whole navmesh on a thread (20 rebakes of 0.15-0.25 s in a 20-min match).
A fast run advances more game time while a bake runs, so a new building would be walked through for longer than in a real
game. `--bake=real` paces frames at real time only while a rebake runs, so the new navmesh lands after the same game time
as in a real 60 fps game (costs about the total bake time, 3-5 s per match). `--bake=fast` = no pacing.

## Determinism (measured)
The game is **not** deterministic, even with every rng seeded and the same mode: two normal runs of the same seed differ
by 3:00-5:00 (a few crystals, one unit) and then diverge. Sources: threaded navmesh rebakes (their completion frame depends
on the CPU), plus the physics / avoidance order that follows. So "same outcome" is checked statistically (same seeds,
several runs per arm, compare the spread with the normal-vs-normal spread), see "Validation".

## Speed
Measured 2026-09-26 evening on this PC (6 threads) while **other agents ran 10-30 Godot processes**: the CPU was at
100 % the whole time, so the absolute numbers are pessimistic and noisy. Same match (fire:shadow, seed 1, 20:00 of game
time, early stop off), the configs of one table started together (same load).
| Config | Run 1 (3 of mine + others) | Run 2 (4 of mine + others) |
|---|---|---|
| (a) old way: `tests/test_2_a1_bot_vs_bot.gd` (full art, bot debug logs on) | ~985 s per 20:00 (25:00 in 1 232 s) | ~1 400 s per 20:00 |
| (b) lab normal (`-Sim off`: full art, no logs) | 1 047 s (x1.17) | 1 167 s (x1.07) |
| (c) lab sim ("partial", as in the lab worktree today) | 945 s (x1.29) | 640 s (x1.94) |
| (d) lab sim + `-Tick 30` | - | 383 s (x3.29) |
Start-up (load + map + first navmesh bake), CPU seconds, main folder, 2 runs each: normal 20.1 s, sim partial 17.9 s, sim
full 17.3 s. Exit adds 2-10 s of wall time. **Sim mode is worth 1.1-1.8x, tick 30 another ~1.7x**; the rest of the cost is
gameplay itself.
Where the time goes (`--ablate=300`, 62 units at 5:00, sim; noisy under that load): NavigationServer (avoidance + path
queries) ~6 ms/frame, units' own `_physics_process` + `move_and_slide` ~3 ms, buildings ~2 ms, game critters (deer /
rabbits, gameplay) ~1.5 ms, the bots < 1 ms per frame on average (a think tick costs 3-4 ms every 0.5 s; the old test's
`debug_log` makes it 20-35 ms), art / VFX / UI ~0 once frozen.
Throughput: the first batch ran **13 matches per hour** with `-Parallel 4` under that load (about 1 000 s per 13-min
match). On a quiet PC expect roughly 2x (the same match at 1:00 ran 5.5 ms/frame quiet vs 10.6 loaded), so ~25-30 per
hour with sim, ~45-50 with tick 30 if it gets validated.
| Option tried | Gain | Risk / status |
|---|---|---|
| Sim mode (art frozen, VFX / audio / UI off) | 1.1-1.8x | Kept (default). Gameplay unchanged (see Validation) |
| Sim build-time hooks (decor, water, camp / lair art) | start-up -0.6 s CPU | Kept; tiny |
| `-Tick 30` (`--fixed-fps 30`, physics 30 Hz) | ~1.7x | **Not default.** Attack cooldowns are counted per frame without carry-over (`Unit._cooldown_left = attack_cooldown`), so each attack can lose up to 1/30 s instead of 1/60: up to 4 % DPS for 0.75-0.8 s cooldowns (Scorchling, keep with the Bell) vs 2 %: a small bias against fast attackers. Projectiles are time-based (no tunnelling). Use for quick sweeps, confirm with 60 Hz |
| Early stop | 30:00 -> ~12-15 min for one-sided games | Kept; the would-be call is logged when off so it can be checked |
| Dead-economy stall (both sides 0 workers + 0 army 120 s) | ends mined-out games early | Kept; the score cannot change any more |
| Fog texture updates | < 0.7 ms (5 Hz) | Not touched (fog_of_war.gd is systems-owned; gameplay reads the grid) |
| Navmesh cache across matches | the first bake is inside the ~17 s start-up | Not done: needs a main.gd hook; measure `startup_parts` first |
| HUD / UI off | inside the sim number | Kept in sim |
| No model colliders | - | Models have none (checked); nothing to gain |

## Validation (sim vs normal)
fire:shadow, 10:00 (`-Limit 600 -Early off --stall=0`), lab at fb2166f. Means of the `at` snapshots
(player / enemy):
| Arm | N | Gathered 3:00 | 5:00 | 7:00 | 10:00 | Army pop 5:00 | Workers 10:00 | Score winner at 10:00 |
|---|---|---|---|---|---|---|---|---|
| normal | 3 | 1320 / 1363 | 2220 / 2257 | 3240 / 3717 | 4750 / 5440 | 10.3 / 10.7 | 8.7 / 7.0 | Fire 2, Shadow 1 |
| sim | 6 | 1340 / 1340 | 2252 / 2222 | 3175 / 3428 | 4692 / 5300 | 7.0 / 9.8 | 9.0 / 7.7 | Fire 1, Shadow 5 |
| sim tick 30 | 6 | 1320 / 1327 | 2230 / 2220 | 3150 / 3545 | 4762 / 5558 | 8.0 / 8.8 | 7.7 / 10.8 | Fire 1, Shadow 5 |
- The economy curve (crystals gathered) of sim matches normal within 1-3 % at every checkpoint, inside the seed-to-seed
  spread; both arms show the same shape (even to 5:00, Shadow ahead from 7:00).
- Army pop and the 10:00 score winner are noisy at this N: normal 2-1 Fire vs sim 1-5 is not a significant difference
  (Fisher p ~ 0.2), and two normal runs of the same seed already diverge (see Determinism). Not proven equal either:
  step 2 of "Next steps" reruns it with 8 seeds x 2 pairs.
- Tick 30 (N = 6): economy and winners match the sim arm (gathered within 2-5 %, Fire 1 / Shadow 5), speed x1.6 over
  sim under the same load. Promising, but the attack-cooldown rounding bias is real in the code: keep 60 Hz as the
  default until step 2 confirms it on more pairs.

## First batch (16 pairs x seed 1, sim, normal, balanced, lab at fb2166f)
Full report: `C:\Users\elzzo\Documents\four-wizards-lab-runs\first-batch-sim\report.md` / `.html`. 16 of 16 matches ran,
0 failed, 0 script errors. Wall time 72:54 with `-Parallel 4` (13 per hour, PC saturated by other agents). Sim was
"partial" (the lab commit has no sim_mode.gd). No ScoreKeeper at fb2166f, so the fallback score. N = 1 per ordered
pair: this is a smoke of the lab, **not** a balance verdict.
| Kingdom (non-mirror) | W-G | Median length |
|---|---|---|
| Fire | 5-6 | 13:19 |
| Nature | 5-6 | 12:48 |
| Shadow | 1-6 | 17:39 |
| Ice | 1-6 | 15:33 |
- Order Fire ≈ Nature > Shadow ≈ Ice, the same order as `balance-2.md` / rush-balance.md section 2.
- Median length 14:22 (p90 26:01), under the 15:00-20:00 target.
- Ends: early-score 8, stall 4 (all "both dead": no worker and no soldier on either side), concede 3, time-score 1
  (fire:fire at 30:00). Only 2 of 16 had a real end (kill / concede) by 24:00 (target: >= 90 %).
- 12 of 16 matches flag `player_no_workers` and 6 `enemy_no_workers`: in most games a side (often both) is left with
  **no workers for over a minute**, and 4 end with both economies dead: the bots don't rebuild workers once the home
  nodes run dry or the workers die. That, not combat, is what stops most games. Worth an ai.md look before tuning.
- `cpu_s` is missing for most of this batch (runner version from before the handle fix); `wall_s` / `real_s` are right.

## Next steps
1. **Lead**: commit `tools/bot_lab/`, `scripts/core/sim_mode.gd`, the 4 hooks (`main.gd`, `river_system.gd`,
   `neutral_camp.gd`, `epic_beasts.gd`), `tests/test_bot_lab.gd`, this file; run the import (new class `SimMode`); move
   the lab worktree to that tag: the lab then runs its own copies and sim mode is "full".
2. Validation with more seeds (this was 3-6 per arm under heavy load): `-Pairs fire:shadow,ice:nature -Seeds 1-8 -Limit
   600 -Early off -Extra "--stall=0"` once with `-Sim off`, once `-Sim on`, once `-Sim on -Tick 30`; compare the
   `at` snapshots and the 10:00 score winner. Decide then whether tick 30 can be the sweep default.
3. Early-stop calibration once `ScoreKeeper` is in the lab: one Round-A batch with `-Early off`, read "Early-stop
   check" in the report, tune `--early-ratio` / `--early-margin` / `--early-hold`.
4. Faster exit: the process teardown costs 2-10 s per match; a quick `quit()` path (free the level first) could save it.
5. Start-up (~17 CPU s): `startup_parts` in the JSON (load / build / first bake) says whether caching the first navmesh
   is worth a main.gd hook.
6. Determinism (optional, big value for paired A/B tests): the threaded navmesh rebakes are the main source; a
   BuildGrid option to bake synchronously in the lab would make seeds reproducible.
7. Styles: when step-16 lands (`AIProfile.apply_style` or `Commander.style`), `-Style` works without lab changes.
