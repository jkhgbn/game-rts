# Art Lab v3: plan for one 5-hour window (quality AND speed)

Written 2026-09-27 by the lead. User request (2026-09-27): "make a new plan for the next 5-hour limit that will greatly
improve the Art Lab; all suggestions that improve both quality and the time needed for each task are approved".
Builds on Art Lab v2 (`docs/plan/art-lab.md` section 9) and today's group-A review (`docs/plan/lab-review-2026-09-27.md`),
which must land and be committed first.

## Goals (numbers, checked at the end)
| Goal | Today (v2) | v3 target |
|---|---|---|
| Time per asset run (windowed, laptop) | 20-40 s, a new Godot start each time | **<= 8 s per asset in batch**, <= 15 s single run |
| Time for an art task to reach "no FAIL, score stops rising" | ~5-8 runs, each read by eye | **<= 3 runs**: fix recipes + before/after diff |
| Army sweep of one kingdom | not run windowed (too slow) | **< 4 min per kingdom**, all 4 kingdoms in one command |
| Lab self-check | one test on synthetic assets | **calibration set**: 12 known-good / known-bad assets with expected score bands, run in < 3 min |
| False alarms | found by agents' "Art Lab notes" | each rule has a calibration case; 0 known false alarms open |

## Phase 0 (lead + 1 agent, 0:00-0:45): make the lab parallel-editable and fast to start
- **0.1 Split `lab_runner.gd` (110 KB)** into `lab_shots.gd` (shots), `checks/readability.gd`, `checks/budgets.gd`,
  `checks/animation.gd`, `checks/decor_vfx.gd`, `checks/polish.gd`, `lab_score.gd`. Pure move, no rule change: every
  scorecard of the calibration assets must be byte-identical before / after (proves the split). Without this, only one
  agent at a time can touch the lab. **[H] four-wizards-high.**
- **0.2 Stage reuse + batch mode** (same agent, after 0.1): one Godot process, the stage / ground / lighting / shaders
  built once, then `batch=<file or list>` runs N assets in a row (free each asset, reset the SubViewport). Warm the
  pipeline cache on the first asset. Headless-only checks (budgets, health, hooks) run first and stop early on a FAIL
  (`fail_fast=1`) so a broken asset costs 2 s, not 30.

## Phase 1 (5 agents in parallel, 0:45-3:15): speed features and quality features
| Task | What | Why (quality / time) | Agent |
|---|---|---|---|
| **1.A Fix recipes** | Every FAIL / WARN also writes a machine-readable `fixes.json`: target mesh / material / node path, measured vs wanted value, and a concrete proposal (e.g. "albedo of `Shell` #5c7a3a -> #7a5c3a gives dE 31 on meadow", "move glow `Eye_L` energy 1.0 -> 1.4 to pass the bloom level", "merge `Strap*` 6 meshes -> 1"). Colour proposals are computed, not guessed (search the nearest colour that passes R3 / R3t / R4k at once). | agents stop guessing: fewer runs per task | [H] four-wizards-high |
| **1.B Before / after diff** | `compare=prev` (default when a previous run exists): a diff contact sheet (old / new / changed-pixel mask per shot), score delta per check, "what got worse" list at the top. `focus=<check ids>` re-runs only the shots those checks need (contrast only: ~3 s). | the agent sees at once whether a change helped; the fast inner loop | [H] four-wizards-high |
| **1.C Calibration set + lab-on-lab test** | 12 assets with expected score bands: 6 good finished assets (Shade, Dusk Steed, Aqueduct, gun VFX, Deer, Frost Dragon) + 6 planted-bad copies generated in code (green-on-grass, 40 glow points, 20 k verts, floating feet, per-instance materials, unreadable team colour). `tests/test_art_lab_calibration.gd` fails when a rule change moves a known case out of its band. Every open false alarm gets a case. | stops threshold drift; every future rule change is safe | four-wizards-high (medium effort) |
| **1.D New quality checks** | (a) **real terrain paint** grounds (step-12b TerrainSystem uniforms, drop the flat stand-ins); (b) **reads while walking**: 40 m silhouette IoU over a walk cycle + flicker of glow points; (c) **R2 flyers at a matching wing phase**; (d) **colour-blind team colours** (deuteranopia / protanopia simulation on R6 / R3t); (e) **glow-point local contrast** (a point must stand out from its 1 m surround); (f) **style bible conformance** against `docs/art/style-autumn.md` (palette distance, saturation / value bands) as INFO then WARN; (g) **night / ice / warm** preset sweep for units that appear in all maps. | catches what agents' notes said the lab missed | [H] tech-artist-level agent (four-wizards-high) |
| **1.E Army sweep v3 + backlog** | Batch-mode sweep for all 4 kingdoms (+ neutral neighbours, per-pair side-by-side tiles), one `docs/art/lab/_army/army.md` ranking every asset by score with its top fix recipe, and a **ranked art backlog** (`docs/art/lab/backlog.md`: FAIL first, then biggest score gain per estimated minute). | turns the lab into the art to-do list; next art waves start from it | four-wizards-high (medium effort) |

Rules for phase 1: file ownership after the 0.1 split — 1.A `lab_score.gd` + new `lab_fixes.gd`; 1.B `lab_report.gd` +
new `lab_diff.gd`; 1.C `tests/` + `tools/art_lab/calibration/`; 1.D `checks/readability.gd` + `lab_stage.gd`; 1.E
`art_lab.gd` batch / sweep entry + `docs/art/lab/_army/`. `lab_budgets.gd` (all numbers) is edited by one agent at a
time: 1.C owns it; others send threshold changes to 1.C by note. At most 4 Godot runs machine-wide (the gate); windowed
runs allowed (laptop display). No git, no downloads, original IP.

## Phase 2 (2:45-4:15): prove it on real work
- **2.1 Timed trial**: a fresh **medium-effort** tech-artist agent gets one real backlog item from 1.E (e.g. Fire Keep
  glow points 32 -> 4-12, or the worst Nature soldier) and only `docs/plan/art-lab.md`. Measure runs and minutes to
  "no FAIL, score stops rising". Target <= 3 runs. Its "Art Lab notes" go straight back to the phase-1 agents (one fix round).
- **2.2 Second trial** on a different kind (a decor set or a VFX family) the same way.
- **2.3 Art agent rule v3**: replace section 5 of art-lab.md with the short v3 loop (`batch`, `compare=prev`, apply
  `fixes.json` top item, `focus=` inner loop, stop rule) and paste it into the step agent-rules files.

## Phase 3 (4:15-5:00, lead): gate and wrap up
Calibration test PASS, `tests/test_art_lab.gd` PASS, smoke `victory=true`, perf `PERF OK`, a timed batch of 10 assets
(report s / asset), commit per task, tag `art-lab-v3`, update art-lab.md sections 1, 7, 9 and the improvement log,
"what to play / look at" note for the user. Stop launching new work at 85 % of the 5-hour meter.

## Budget
~2 % of the window per agent-hour (tools-wave.md 14): 0.1-0.2 ~0.75 h [H], phase 1 5 agents x ~2 h, two trials x ~0.4 h,
one fix round x 5 x 0.25 h, lead ~12 %. **Expected ~40-45 % of a 5-hour window**; worst case ~60 %. Cut order if short:
1.D (g) night sweep, 1.D (f) style check (keep as INFO), 2.2 second trial. Never cut: 0.1 split, 1.A fix recipes, 1.B diff,
1.C calibration.

## Default decisions (pre-approved by the user's "all suggestions approved")
- Soft kingdom glows (Nature sap veins) count as glow points for the nature tier when they pass local contrast (1.D e).
- Colour-blind check starts as WARN, never FAIL.
- The style-bible check is INFO until the autumn runs (style-autumn.md section 6) are done.
- Batch mode becomes the default for sweeps; single runs keep working with the same arguments.
