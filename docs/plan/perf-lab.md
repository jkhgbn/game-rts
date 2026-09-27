# Perf Lab

The optimisation twin of the Art Lab / Bot Lab / Audio Lab. It runs **fixed, seeded scenarios** (skirmish early game,
100-unit fight, 200-unit late game, VFX storm, menu diorama), measures frame time, spikes, Godot monitors and a
**per-script profile**, then judges everything against the budgets in the specs. The output is a **scorecard per scenario**
(PASS / WARN / FAIL, a 0-100 perf score, an "Improve next" list that points at file / function) and a **history log**
that tracks regressions between commits.

It never edits game code. Its suggestions go to the owner agent (CLAUDE.md "Who owns what") as a handoff.

## Files

| File | What it does |
|---|---|
| `tools/perf_lab/run_perf_lab.ps1` | The runner. Runs one Godot process at a time, with the noise guard and repeats, then the report. |
| `tools/perf_lab/perf_lab.gd` | One scenario run (a SceneTree script). Writes one JSON line: `PERF_LAB_RESULT {...}` / `--out`. |
| `tools/perf_lab/perf_probe.gd` | The band profiler (opt-in, no autoload, no game code touched). |
| `tools/perf_lab/perf_budgets.gd` | Every budget, with its source (spec file:line). |
| `tools/perf_lab/perf_scorecard.gd` | Checks, score, "Improve next", md / json writers, history. |
| `tools/perf_lab/perf_hints.gd` | Lint of hot scripts (costly patterns in per-frame functions, file:line) + the fix playbook. |
| `tools/perf_lab/perf_report.gd` | Merges the runs (median of the repeats), writes the scorecards + `summary.md` + history rows. |
| `tools/perf_lab/perf_stats.gd` | Percentiles, median merge, spread. |
| `tests/test_perf_lab.gd` | Self-test (stats, budgets, probe accuracy on synthetic load, lint, scorecard, history). |
| `docs/perf/lab/latest/` | The latest scorecards: `<scenario>_<cpu|gpu>.md/.json` and `summary.md`. |
| `docs/perf/lab/history.md` (+ `history.jsonl`) | One row per scenario + mode per lab run (commit, noise, numbers, score). |

Lab scripts use `preload` (no `class_name`), so they never touch the global class cache and need no `--import`.

## How to use

```powershell
# Everything (5 scenarios x 3 headless runs + 1 windowed run at 1600x900), about 25-40 min on a quiet PC:
powershell -ExecutionPolicy Bypass -File tools\perf_lab\run_perf_lab.ps1

# Only what you changed, 5 repeats, plus the user's ultrawide:
.\tools\perf_lab\run_perf_lab.ps1 -Scenarios mid100,late200 -Repeats 5 -Resolutions 1600x900,3440x1440

# Logic only, short windows (a smoke check after a change, ~5 min; -Quick never writes history or docs/perf/lab/latest):
.\tools\perf_lab\run_perf_lab.ps1 -Scenarios mid100 -NoGpu -Quick

# Wait for the machine to calm down (other agents) before each run, up to 10 min:
.\tools\perf_lab\run_perf_lab.ps1 -WaitQuietS 600

# One run by hand (headless = CPU; drop --headless and add --resolution 1600x900 for GPU):
$GODOT --headless --path . -s res://tools/perf_lab/perf_lab.gd --fixed-fps 60 --quit-after 40000 -- --scenario=late200 --profile=1 --out=C:/tmp/r.json

# The self-test (must print PASS perf lab):
$GODOT --headless --path . -s tests/test_perf_lab.gd --fixed-fps 60 --quit-after 900
```

Raw runs go to `..\four-wizards-perf-runs\<date-time>\` (outside the repo). The scorecards are copied to
`docs/perf/lab/latest/`. Open `summary.md` first, then the scorecard of the scenario you care about.

## Scenarios

All skirmish scenarios use `scenes/skirmish.tscn` (Crown Hollow, full map fill: river, decor, critters, camps, trade),
fire vs shadow, seed 1, `--fixed-fps 60`, the HUD on (it is part of the real cost), and a fixed camera path driven by game
time. Every per-node RandomNumberGenerator is seeded like the Bot Lab. The measure window starts after a warm-up.

| Scenario | What happens | Warm-up / measured (game s) | Camera |
|---|---|---|---|
| `early` | 1v1 from 0:20 to 1:05, **both** sides normal Commanders (player side = a lab bot) | 20 / 45 | player base, centre, enemy base, back |
| `mid100` | 50 v 50 mixed soldiers of each kingdom attack-move into each other on the west meadow (player army selected), enemy Commander on | 4 / 30 | orbit over the fight |
| `late200` | 100 v 100 + 1 "titan" per side + all 8 epic beasts spawned (`EpicBeasts.spawn_now`) + river, decor, critters | 4 / 30 | fight, Old Wood at zoom 55, Crown Isle at 55, back |
| `vfx_storm` | 40 v 40 fight + both wizards cast every spell (rank 3, mana / cooldowns refilled) every 0.5 s + every VFX manager (`TitanVfx`, `TitanGroundVfx`, `MapFillVfx`, `BeastVfx`, `WyrmVfx`, `TradeVfx`, the 3 unit VFX families) plays its next effect every 0.5 s | 3 / 25 | orbit over the fight |
| `menu` | `scenes/ui/main_menu.tscn` with the 3D diorama (own SubViewport) | 3 / 20 | the diorama's own |

Titans: there is no gameplay titan yet (13.C3). The lab spawns a `rime_colossus` stat block wearing the
`war_mammoth` / `nightmare_knight` titan models, so the model + VFX cost is measured. Replace it with the real titan
type when it lands (`TITANS` / `TITAN_BASE_TYPE` in perf_lab.gd).

Modes: **cpu** = `--headless` (logic: scripts, physics, navigation; no rendering). **gpu** = windowed at `-Resolutions`
(1600x900 by default, 3440x1440 optional), VSync off, `Engine.max_fps = 0`, GPU time from
`RenderingServer.viewport_get_measured_render_time_gpu` (root + SubViewports), draw calls / objects / primitives from the
render monitors.

## What is measured

- **Frame time**: wall clock between two frames (avg, p50, p95, p99, max) and **hitches** (> 33.3 ms), each with the
  game time, the top 3 bands of that frame, the engine gaps and what happened (scenario events, nodes added, navmesh
  rebake).
- **Performance monitors** (avg + max): draw calls, objects, primitives, video memory, static memory, nodes, objects,
  resources, orphan nodes, physics active objects / pairs, navigation agents. Godot's TIME_* monitors are recorded but
  not trusted headless (same finding as `tests/perf_test.gd`).
- **Band profiler** (`--profile=1`, run 1 of each scenario): Godot runs `_process` / `_physics_process` (and internal
  processing) in `process_priority` order. The probe gives every scripted node a priority **band per script**, and puts a
  marker node before each band; each marker stamps `Time.get_ticks_usec()`, so the gap between two markers is what that
  script's nodes cost this frame. A Timer / AnimationPlayer is charged to its parent's script (the Commander thinks on a
  Timer). The gaps after the last marker are the engine's own work: **physics + navigation server step** and **render +
  tweens + idle**. Output: a **top-15 hot list** (script, system, nodes, avg / median / p95 / max ms, share of the frame),
  per-system totals judged against the spec budgets, and a lint of the 10 hottest scripts.
  Cost: ~1.5 us per marker per pass (listed as "probe overhead" in the scorecard). The headline frame numbers come from
  the unprofiled repeats. Side effect: process order between scripts follows the bands (mount models are reserved first,
  so a rider still poses after its mount).
- **Commander think ticks** from `commander.gd`'s own counters (median, max, worst rule step).
- **Scene census** (at the end of the warm-up): real lights, shadow-casting lights, decor MultiMesh instances, map-dressing
  draw nodes, geometry nodes, shadow casters, particle systems, node classes.
- **Health**: nodes created under a VFX manager during the measure window (pools must not instance), orphan nodes, node
  growth outside units, static memory growth, script errors in the log.

## Budgets

From `perf_budgets.gd` (`perf_report.gd -- --table` prints this table). Spec numbers FAIL, lab defaults only WARN.

| Scenario / system | Rule | FAIL above | WARN above | Source |
|---|---|---|---|---|
| early | logic frame avg | 8.0 ms / 100 units (floor 3) | 5.5 / 100 | waves.md:82 (8 ms / 100 units, scaled to the early-game unit count); warn waves.md:226 |
| mid100 | logic frame avg | 8.0 ms | 5.5 ms | waves.md:82 (100 units <= 8 ms), warn waves.md:226 (5.P1) |
| late200 | logic frame avg | 16.0 ms | 11.0 ms | waves.md:82-83 (200 units, scaled), warn waves.md:226 (5.P1: <= 11 ms) |
| vfx_storm | logic frame avg | 8.0 ms / 100 units + 1.0 | 5.5 / 100 | waves.md:82 + lab default 1 ms VFX allowance |
| menu | logic frame avg | 2.0 ms | 1.0 ms | lab default |
| all | p95 / p99 | - | 1.5x / 2.0x the avg budget | lab default |
| all | hitches (> 33 ms) per minute | 3.0 | 0.5 | lab default |
| all (windowed) | frame avg | 16.7 ms (60 fps) | 8.3 ms (120 fps) | cinematics.md:316-317, map-fill.md:406 |
| all (windowed) | frame p99 | 33.3 ms | - | idem |
| per scenario (windowed) | draw calls / objects / primitives | - | early 1500 / 2500 / 2.5 M, mid100 2500 / 4000 / 3.5 M, late200 4000 / 6500 / 5 M, vfx 3000 / 5000 / 4 M, menu 800 / 1500 / 1.5 M | lab default (art-units.md:627, art-keep.md:294) |
| AI commanders | per-frame logic | avg 0.6 ms, worst frame 1.5 ms | median 0.1 ms | ai-2v2.md:340, ai.md:146 |
| Commander think tick | commander.gd counters | median 0.3 ms, max 1.5 ms | median 0.1, max 0.45 ms | ai.md:146, ai-2v2.md:340 |
| Champion brains | per-frame logic | avg 0.1 ms | - | champions.md:228 |
| Epic beast brains | per-frame logic | avg 0.03 ms | - | map-fill.md:403 |
| Map fill services | per-frame logic | avg 0.2 ms | - | map-fill.md:398 |
| Critters (game + cosmetic) | per-frame logic | avg 0.11 ms | - | map-fill.md:398 + :404 |
| Trade | per-frame logic | avg 0.1 ms | - | market-trade.md:128 |
| Fog of war | per-frame logic | avg 0.3 ms | - | lab default (fog-of-war.md:42-47) |
| VFX managers | per-frame logic | avg 0.5 ms | - | lab default (for-lead.md:94) |
| HUD / minimap / UI | per-frame logic | avg 0.5 ms | - | lab default |
| Unit / building model scripts | per-frame logic | 0.5 ms / 100 units | - | art-units.md:633 |
| census: real lights (not directional) | count | 15 | - | step12-agent-rules.md:27-28 |
| census: shadow-casting lights | count | 1 (the sun) | - | art-keep.md:291, map-fill.md:400 |
| census: decor instances | count | 12 000 | - | map-fill.md:400 |
| census: map-dressing draw nodes | count | - | 140 | map-2v2.md:227 |
| VFX nodes created after warm-up | count | 0 | - | art-units.md:631, champion-skill-tree.md:361 |
| orphan nodes / node growth | count | - | 0 / 10 % | lab default |
| change vs previous quiet run | frame avg | - | +10 % | lab default (history) |

**Perf score (0-100)**: every check scores PASS 70-100, WARN 35-69, FAIL 0-34 (graded by how far inside / outside the
limit it is), weighted by group (frame 3, GPU 3, shape 1.5, systems 1.5, health 1.5, census 1). So a change that makes
a passing number better still moves the score.

## Machine-noise guard

Perf numbers taken while other agents run Godot are meaningless (lead-status.md:9-10). The runner:

1. runs its Godot processes **one at a time**, never in parallel;
2. samples every 2 s during each run: **other Godot processes** (not started by the runner; the console wrapper and its
   child are both ours) and the **whole-machine CPU load minus our own process tree** (WMI, locale-independent);
3. marks a run **noisy** when another Godot ran or the other load averaged > `-NoiseCpu` (20 %);
4. inside the game, a fixed GDScript **calibration loop** runs at start and end; the report also marks a run noisy when it
   was > 1.3x slower than the batch's fastest (catches throttling and busy programs that are not Godot);
5. repeats each scenario `-Repeats` times (3) and takes the **element-wise median**; when at least one run is quiet, only
   the quiet runs count; otherwise the scorecard is flagged **NOISY** in red and the history row says so;
6. `-WaitQuietS 600` waits (up to 10 min) for a quiet machine before each run (the wait line names the busiest processes);
7. names the **busiest other processes** (Godot or not: every ~6 s, `Win32_PerfFormattedData_PerfProc_Process`, in % of
   the whole machine, averaged over the run) in the noise reason, e.g. `other CPU load 92 % (busiest: AlsulicsService 76 %,
   Godot_v4.7.2-stable_win64 12 %)`, so a NOISY card says who loaded the PC; the runner's own PowerShell sampling counts
   as ours (it used to be counted as "other" load); the JSON row has `other_top`;
8. holds **one slot of the shared Godot gate** (`tools/godot_run.ps1`, semaphore `Local\FourWizardsGodotGate`) during
   each measured run, so agents and labs that use the gate wait instead of starting next to it (a run that waited
   `FW_GODOT_MAXWAIT` s and started anyway is marked noisy). The slot is given back on Ctrl+C.

Report outputs: `-NoLatest` keeps `docs/perf/lab/latest/` untouched (`perf_report.gd --latest=none`); `-Quick` implies
`-NoHistory -NoLatest` (8 s windows must never become the "previous quiet run" of R1 or replace the reference cards).
Functional check 2026-09-27 (laptop, 5 other agents): `-Scenarios menu -NoGpu -Quick -Repeats 1` ran, NOISY as it should
(6-10 other Godot, 92-95 % other CPU, one service at ~76 %); latest/ and history untouched. No number from it is usable.

Regression checks (history) only compare **quiet** rows.

## Reading a scorecard

1. **Result + perf score** at the top, and the NOISY banner if any.
2. **Improve next**: at least 3 concrete items. Hot scripts come with the lint findings (`unit.gd:1948 in
   _update_hp_bar()`: shader parameter write every frame...) plus the per-system playbook; then the worst hitch; then the
   failing checks (draw calls, lights, pools...).
3. The check tables per group, the **hot list**, the engine gaps, the **hitch table** (what happened), the monitors,
   the Commander tick counters.

## Rule to add (for all agents)

> **Perf Lab rule.** Any change to per-frame code (`_process`, `_physics_process`, think ticks, VFX managers, HUD,
> fog, minimap, unit / building models) or to what a level draws (decor, lights, particles, shaders) runs the Perf Lab on
> the scenario that exercises it before it is called done:
> `.\tools\perf_lab\run_perf_lab.ps1 -Scenarios <scenario> -NoHistory` (add `-NoGpu` for pure logic changes).
> Done when: no new FAIL in the scorecard, the frame avg is not more than +10 % over the latest quiet row of
> `docs/perf/lab/history.md` for that scenario, and the script you touched is not newly in the top 5 of the hot list.
> A **noisy** scorecard proves nothing: say so in the handoff instead of quoting its numbers. Agents never kill Godot
> processes they did not start. The lead runs the full lab (with history) at the end of each wave on a quiet PC.

## Validation run (2026-09-26, main @ 49ff2b29cb + uncommitted work)

Scorecards: `docs/perf/lab/latest/` (start with `summary.md`); raw runs: `..\four-wizards-perf-runs\20260926-validation\`.
2 headless runs (run 1 profiled) + 1 windowed 1600x900 run per scenario. The machine was **not** quiet: 22-31 other
Godot processes from parallel agents at once, the other CPU load was 90-105 %, and the calibration loop ran up to x8 slower. Every
scorecard is flagged **NOISY**. The absolute frame times are upper bounds. The **relative** numbers still hold: hot-list
order, per-system shares, Commander counters, census, GPU layer costs (GPU-bound, measured with the tree paused) and lint.

| Scenario | cpu frame avg (noisy) | gpu frame / GPU ms (1600x900) | Units avg | Score cpu / gpu |
|---|---|---|---|---|
| early | 22.8 ms | 10.8 / 5.7 ms, 1 047 draw calls | 26 | 42 / 82 |
| mid100 | 36.2 ms | 19.1 / 6.2 ms | 62 (the fight kills half) | 42 / 65 |
| late200 | 42.7 ms | 28.9 / 8.2 ms, 2 156 draw calls, 8 288 objects, 3.1 M prims | 135 | 38 / 61 |
| vfx_storm | 40.8 ms | 19.2 / 7.0 ms | 38 | 41 / 68 |
| menu | 0.25 ms | 3.6 / 2.5 ms | 0 | 97 / 98 |

Top findings (details in the scorecards):
1. **Commander think tick**: median 0.6-3.5 ms (budget 0.3). The worst single ticks are 186 ms (`scout`, early), 188 ms
   (`attack`, mid100), and 144 ms (`champions`) in the first trial run. Even allowing for up to x8 noise, this is far over
   ai.md:146. This is the "bot think up to 2.3 s" seen today.
2. **HUD / UI costs 3.9-4.5 ms per frame** in every skirmish scenario. `selection_panel.gd` refreshes every frame (1-3 ms,
   string formatting in `_update_hero()` :564-580), then `command_card.gd` and `selection_manager.gd`.
3. **Units**:
   - late200: `unit.gd` costs 4.4 ms over 224 nodes. The lint flags `_update_hp_bar()` :1948-1949, which writes shader
     parameters every frame.
   - The unit model scripts cost 4.5 ms at late200 against a 0.7 ms budget: `fire_model`, `blaze_rider_rider`,
     `ember_boar` and `shadow_model`, with shader writes like `fire_model.gd:324 _set_ball_heat()`.
4. **GPUParticles3D internal processing costs 1.5-2.2 ms per frame** across 1 400-1 700 particle nodes (an engine-side
   cost). Pooled but idle emitters still process.
5. **VFX managers**:
   - They cost 1.1 ms per frame in a fight and 3.5 ms in the storm. The hottest are `mapfill_wyrm_vfx`,
     `titan_ground_vfx`, `mapfill_beast_vfx` and `spell_vfx`.
   - Nodes created under a VFX manager during the measure window:
     - mid100: 52 (39 GPUParticles3D, 10 meshes, **3 OmniLight3D**)
     - vfx_storm: 28
   - That breaks the "pooled, no runtime instancing" rule.
6. **GPU by layer** (late200, windowed ablation):
   - map dressing (biome decor): **1.82 ms = 25 %**
   - sun shadows: **1.06 ms = 15 %**
   - units: 0.48 ms
   - HUD: 0.28 ms
   - trees and rocks: 0.22 ms
   - cosmetic critters: 0.20 ms
   - river meshes: 0.17 ms
   The ground-shader river paint was not isolated: the ground mesh was not found by the lab's heuristic. That is the next
   lab fix.
7. **Census is within budget**:
   - 5-6 real lights (cap 15), 1 shadow light
   - about 3 800 decor instances (cap 12 000)
   - 109-114 map-dressing draw nodes (140)
   - Render objects are over the lab default at late200: 8 288 against 6 500.

## Limits

- Headless has no camera culling of the render, but the models still run their distance tiers from the camera rig
  (the lab drives the camera path in both modes, so the tiers match the GPU run).
- The band profiler sees scripts, not functions. Inside a hot script, the lint (static patterns in per-frame functions
  and the helpers they call) points at the likely lines; confirm with the Godot editor profiler when needed.
- Nodes that change their own `process_priority` after entering the tree (only the seated rider today) are charged to
  the band they moved to.
- TIME_* monitors are unreliable headless; the lab keeps them for reference only.
- `early` depends on the bots' decisions: deterministic for a given commit and seed, but a navmesh rebake finishing a
  frame earlier or later can shift events slightly.
- GPU numbers depend on the window being visible and not covered; the runner places it at 0,0.
- No gameplay titan exists yet: the titan cost is the model + VFX cost on colossus stats.

## Next steps

- Re-run the full lab on a quiet PC (`-WaitQuietS 600 -Repeats 3 -Resolutions 1600x900,3440x1440`) to get the first
  quiet baseline rows in the history.
- GPU ablation: find the ground mesh (river paint in the ground shader) by its material instead of by size, so the
  "+15 % river shader" cost gets its own row.
- mid100 / late200: the armies kill each other fast (unit avg 62 / 135 over the window). Consider re-spawning losses to
  hold the count, or judge against the average unit count (the scorecard shows both).
- Add a 2v2 scenario once the 2v2 map is in (map-2v2.md gate: 300 units <= 15 ms).
- Optional: per-function timing inside a hot script through the Godot remote-debugger profiler protocol (not done: the
  band profiler + lint already name file and function).
