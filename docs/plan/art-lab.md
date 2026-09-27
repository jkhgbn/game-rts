# Art Lab: judge, fix and push every art asset

The Art Lab is the standard check every art agent runs at the end of an art task (the art side of the Bot Lab).
It renders the asset the way the player sees it (skirmish ground, lighting preset, game camera), measures it against
the spec budgets and the readability rules, and writes a **scorecard** with PASS / WARN / FAIL, the measured value,
the rule, a concrete fix hint, a **quality score 0-100** and an **"Improve next"** list (always at least 3 items, even
when everything passes). Every run appends a row to `docs/art/lab/improvement-log.md` so trends are visible.

Files: `tools/art_lab/` (module map below, v3 split 2026-09-27), test `tests/test_art_lab.gd` (headless: `PASS art_lab`).

**Module map (v3).** Every check module is a `class_name` of static functions taking the run context
`ctx: ArtLabRunner` (state: `ctx.rep`, `ctx.stage`, `ctx.target`, `ctx.holder`, `ctx.kind`, `ctx.tier`, `ctx.opts`,
shared measurements `ctx.m`; helpers: `ctx.frames`, `ctx.wait`, `ctx.call_hook`, `ctx.spawn`, `ctx.settle`,
`ctx.free_model`, `ctx.crop`, `ctx.crop_box`, `ctx.add_tile`, `ctx.save_shot`, `ctx.fmt`, `ctx.use_stage`). Modules call
each other only through public (non-`_`) functions. One owner per file in a phase (v3 plan "Rules for phase 1").
| File | Class | Owns | v3 phase-1 owner |
|---|---|---|---|
| `art_lab.gd` | (SceneTree entry) | args, single run, `sweep=`, `batch=` entry | 1.E |
| `lab_runner.gd` | `ArtLabRunner` | the run context (state + helpers), argument resolve, the run order (`_run_model`: headless checks, `fail_fast`, shots, readability, turns, anim strip, references, frame cost), `use_stage` (own or pooled stage), `timing=1` laps; thin forwarders `resolve_scene`, `list_scenes`, `army_pass` for old callers | lead (change on request) |
| `lab_batch.gd` | `ArtLabBatch` | v3 batch: entries (list / file), kind guess, per-entry args, `run_all` (stage pool, vsync off), summary line | 1.E |
| `lab_shots.gd` | `ArtLabShots` | black silhouette / height passes (`sil`, `height_pass`), 40 / 55 / 25 m + close-up shots, turns, lineup, `mask_tile`, `mark`, army silhouette pass | 1.D (with the stage) |
| `lab_scenes.gd` | `ArtLabScenes` | short names (`resolve_scene`), `list_scenes`, auto references (`auto_candidates`, `probe_height` cached per process, `pick_refs`) | 1.E |
| `checks/budgets.gd` | `ArtLabCheckBudgets` | B1-B8, B1a, B11, B12 (census), B9 / B9m, B10 (action cycles), B13 frame cost (`measure`), H1 / H2 errors | 1.C (numbers stay in `lab_budgets.gd`) |
| `checks/readability.gd` | `ArtLabCheckRead` | R1, R2 / R2r (`references`), R3 / R3t / R4 / R4k (`add_contrast`), R5 (`glow_phase`, `glow_report`), R6 (`team_pass`), R7, R8 / R8w, R9, R10 (`check_geometry`) | 1.D |
| `checks/animation.gd` | `ArtLabCheckAnim` | A1 hooks, A2 `death_check`, A3 `attack_reads` (called from the 40 m pass), animation strip | 1.D (walk cycle) |
| `checks/polish.gd` | `ArtLabCheckPolish` | P1 / P3 / P4 `shape_value_detail`, P2 `asymmetry`, P5 `glow_placement` (INFO, scored) | 1.D (style bible f) |
| `checks/decor_vfx.gd` | `ArtLabCheckDecorVfx` | decor sets (D1-D9, patch R5 / B13), VFX families (B5, V2-V6, B13) | free (none in phase 1) |
| `lab_score.gd` | `ArtLabScore` | `score_of`, `grade`, `budget_status`, `quality`, `improve_next`, `GROUP_WEIGHT`, kind ideas `add_extras` | 1.A (+ new `lab_fixes.gd`) |
| `lab_report.gd` | `ArtLabReport` | the check list, scorecard.md / .json, contact sheet, improvement log; `quality()` / `improve_next()` forward to `ArtLabScore`; `GROUP_WEIGHT` kept as an alias. **`tools/common/tool_report.gd` (`ToolReport`) extends it**: keep its public API (`add`, `count`, `result`, `quality`, `improve_next`, `exit_code`, `to_dict`, `to_markdown`, `_cell`, `write`, `append_log`, `read_previous`, `contact_sheet`); `grade` / `budget_status` moved to `ArtLabScore` (ToolReport has its own copies since 2026-09-27) | 1.B (+ new `lab_diff.gd`) |
| `lab_stage.gd` | `ArtLabStage` | SubViewport, ground, lights, render modes, cameras, `override` / `restore`, v3 `warm()` / `reset()` | 1.D |
| `lab_image.gd` / `lab_census.gd` | `ArtLabImage` / `ArtLabCensus` | pixel analysis / scene census (shared helpers) | ask the lead before changing a signature |
| `lab_budgets.gd` | `ArtLabBudgets` | **all numbers** | 1.C only (others send changes by note) |

## 1. One command
Windowed (it renders; `--headless` only runs budgets / health / hooks and marks the render checks SKIP):
```powershell
cd C:\Users\elzzo\Documents\four-wizards-rts
# through the Godot gate (same arguments as the exe; works on the desktop and the laptop)
& .\tools\godot_run.ps1 --path . -s res://tools/art_lab/art_lab.gd --quit-after 90000 '--' scene=res://art/units/neutral/mirefang/mirefang.tscn kind=unit kingdom=neutral
# or the wrapper
.\tools\art_lab\run_art_lab.ps1 mirefang unit neutral
```
| Arg (after `--`) | Meaning |
|---|---|
| `scene=` | the asset: a model `.tscn` (unit, mount, titan, building, beast, critter, landmark), a biome set `<id>_set.gd` (`decor_set`), or a VFX family script / scene with `play(id, at, target)` (`vfx`). **Short names work** (v2): `scene=sapling` finds the first `sapling.tscn` under `res://art/` |
| `kind=` | `unit` `mount` `titan` `building` `beast` `critter` `decor_set` `vfx` `landmark` |
| `kingdom=` | `fire` `shadow` `ice` `nature` `neutral` (default: from the UnitType faction or the path) |
| `out=` | output folder, default `docs/art/lab/<name>/` |
| `ref=` | comma list of comparison scenes: short names (`ref=ember_archer,flame_guard`), `fire/ember_archer` or `res://` paths (default: auto-picked, see 2). A ref that does not resolve prints `ART LAB WARNING: ref not found` and adds a **WARN R2r** |
| `tier=` | budget row inside the kind (default guessed: e.g. `unit/creature` for `art/units/neutral/`, `unit/wizard`, `unit/champion`, `unit/cavalry` for `*_rider.tscn`, `unit/heavy` when body_height >= 2.2, `beast/titan` for the Frost Wyrm, `building/keep`, `landmark/objective` for the Crown altar / capture shrines) |
| `ground=` | main ground: `meadow` (default) `heath` `old_wood` `riverbank` `dirt`, and (v2) `snow` `ash` `sand` `marsh` (flat stand-in patches tinted with the biome set's `GROUND_TINT`, off the Crown Hollow map); `light=warm` (default) or `ice` (**default when `ground=snow`**) |
| (PowerShell) | quote the `--` and every comma list: `'--'`, `'ref=ember_archer,flame_guard'`, `'only=a,b'` (an unquoted `a,b` becomes two arguments) |
| `sweep=<kingdom>` | **army sweep** (v2): every model in `res://art/units/<kingdom>/` (or `dir=`), each run with `quick=1` (`full=1` keeps the per-asset refs / frame cost), then every silhouette rendered **once** and all pairs compared (IoU over 4 turns + colour dE). `only=a,b` filters by file name; `kind= ground= light= log= tier=` pass through. Writes `docs/art/lab/_sweep_<kingdom>/sweep.md` + `army_silhouettes.png` (plus each asset's own scorecard). Exit 1 if any asset FAILs |
| `name=` `ids=` `n=` | asset name; VFX ids (default: the family's `EFFECTS`); instances for the frame cost |
| `quick=1` / `log=0` | skip references + frame cost / no improvement-log row |
| `table` | print the budget table (Markdown) and quit |
| `batch=<list or file>` | **v3 batch**: several assets in ONE Godot process (`lab_batch.gd`). The stage (ground, lights, shaders) is built once per light preset and warmed (all 4 render modes) before the first asset; each asset then runs on the reset stage (its nodes freed). A comma list of scenes shares the other args (`'batch=shade,dusk_steed,aqueduct'`); a `.txt` / `.list` file holds one `<scene> [key=value ...]` per line (`#` = comment). `kind=` is guessed from the path when missing; `out_root=<dir>` puts each scorecard in `<dir>/<name>/`. vsync is off in a batch (capped 240 fps; `vsync=1` keeps it): the lab's waits are timers, so the poses are the same. Ends with `ART LAB BATCH done: N assets in S s (s / asset)` + one line per asset; exit 1 if any FAILs. `sweep=` uses the same stage pool |
| `fail_fast=1` | v3: the headless checks (budgets, health, hooks, allocations) run first; on a FAIL the render passes are skipped (render checks SKIP "fail_fast", note in the scorecard) |
| `timing=1` | v3: prints the seconds of each phase (headless checks, shots, read_40, turns + anim strip, references, frame cost) |

Lead shortcut (v2): `.\tools\art_lab\run_art_lab.ps1 sapling unit nature` (one asset, through the Godot gate),
`.\tools\art_lab\run_art_lab.ps1 -Sweep ice` (army sweep), `-Extra 'ground=ash','light=ice'`, `-Headless`;
v3: `.\tools\art_lab\run_art_lab.ps1 -Batch 'shade,dusk_steed,aqueduct' -Extra 'fail_fast=1'` (or a batch file).

Runtime 20-40 s per asset (GTX 1660); v3 on the RTX 3070 laptop: ~30 s per asset single (+ ~5 s Godot start and the
gate wait), 27 s per asset in a full batch, 16.5 s with `quick=1 fail_fast=1` (section 9.1). Exit code **1 on any FAIL**, 0 otherwise, 2 = bad arguments. The console ends with
`ART LAB <name>: <RESULT> quality <N> ...` and one line per FAIL / WARN.

Output in the out folder: `scorecard.md`, `scorecard.json`, `contact_sheet.png` (everything on one page, with the
FAIL / WARN lines and the top improvement in the header), `z40.jpg`, `z55.jpg`, `z25.jpg` (full 1600 x 900 frames),
`close.jpg`, `turns.jpg`, `anim.jpg`, `silhouette.png`, `lineup.jpg` (VFX: `effects.jpg`).

## 2. What it shoots (1600 x 900 SubViewport, MSAA 2x)
- Stage: the skirmish ground material (`EnvProps.ground_material` + Crown Hollow river / biome uniforms, like
  `skirmish.gd`), water under the river cut, `LightingRig` preset `warm` (sun, fill, vignette), no gameplay.
  The asset stands at a real map spot of the chosen ground (meadow = Hearth Meadow west hub).
- Game camera (pitch 55, fov 50, `rts_camera.gd`) at zoom **40** and **55**, **25 m**, a 3/4 **close-up**, **4 turns**
  (0 / 90 / 180 / 270), the 40 m frame on the other grounds (heath, Old Wood, riverbank; the worst one is shown).
- **Black silhouette sheet** (unshaded black on white, same scale, 40 m) of the asset and its references;
  **emission-only** frame (black world, no lights, bloom kept) for the tile, and (v2) a **"hot" frame** (no bloom,
  linear, 255 = the bloom level) x 3 idle phases for the glow count; a **height frame** (unshaded grey = world height)
  for P3 / P5 and R3's top third. v2 also shoots R4 on the snow / ash / sand / marsh stand-in patches.
- **Team-colour sheet**: the asset at 40 m in the 4 kingdom colours (one fresh instance per colour: `set_team_color` is
  a spawn-time hook).
- **Lineup** at 40 m and from the side: the asset + references. Auto refs: up to 4 of the same kind (same kingdom's
  units / all titans / all mounts / beasts / buildings of the kingdom), closest in height, + 2 neutral neighbours
  (units: camp creatures; titans: epic beasts; mounts: beasts).
- **Animation strip** via the standard hooks (`has_method`): idle, move (mount: + gallop), attack (strike), charge,
  hit, cast, death 0.45 s and death end. Buildings: construction 50 %, 40 % / 20 % HP, training pulse, selected,
  destroyed 1.2 s / 3 s. Critters: move, flee, hit, death. Decor: a 30 x 30 m scattered patch with 4 kingdom units
  standing in it. VFX: every id at 0.35 / 0.8 s at 40 m.

## 3. The checks (thresholds live in `tools/art_lab/lab_budgets.gd`)
Budget numbers come from the specs (hard = FAIL when over); "soft" numbers are lab defaults or guidelines (WARN only).

| # | Check | Rule (default thresholds) |
|---|---|---|
| H0 | Scene instantiates | no crash, root Node3D |
| H1 | Errors from the asset while running | 0 errors (FAIL) / 0 warnings (WARN) from the asset folder or the kit, caught by an engine `Logger` during the whole run; other files' errors listed as INFO (H2) |
| B1 | Meshes after the kit merge (v2) | MeshInstance3D + MultiMeshInstance3D **drawn at rest after the kit merge** (render cost, user decision 2026-09-26 23:20) <= the `meshes` budget |
| B1a | Authored build parts (INFO) | v1's B1: build parts counted while the scene enters the tree (before the merge); info only, "authoring detail is cheap" |
| B11 / B12 | Surfaces / downward faces (INFO) | surfaces per instance (1 surface = 1 draw call); triangles whose normal points steeply down (y < -0.7, never seen from pitch 55; a sphere has ~15 %): above 25 % an "Improve next" hint (drop bottom caps). The per-mesh vertex breakdown (biggest first) is in the Notes and in B4's value |
| B2 | Draw instances at rest | visible meshes + multimeshes + emitting particle systems + decals <= budget |
| B3 | keep_separate parts | <= 6 (soft) |
| B4 / B4t | Vertices / triangles | <= budget (critters: triangles) |
| B5 | Real lights | 0 (wizard 1, keep 2) |
| B6 / B6l / B6p | Particle systems / looping / looping particles alive | per kind |
| B7 | Shadow casters | <= 4 units (soft), 6 heavy, 12 titans |
| B8 | Unique materials | champion 5, keep 8, critters 1; else INFO |
| B9 | Materials / meshes built per instance | 0: a 2nd instance must share every material (FAIL on units) and mesh (WARN) |
| B10 | Allocations after `_ready` | move / attack / hit / cast create no nodes (WARN) and no materials (FAIL on units, mounts, titans, beasts, critters). v2: the actions run **twice**; only materials first seen in the 2nd cycle count (a static cache or a swapped cached process material is not "new"; saved `.tres` materials never count) |
| B13 | Frame cost | process ms per instance with N animated at zoom 40 (unit 100 x <= 0.005 ms = art-units "0.5 ms per 100"; building 0.05; titan 0.02 soft) + render CPU / GPU delta. v2 **noise band**: 1-1.5 x a hard budget = WARN ("re-run quiet"), FAIL above (the same Ember Archer measured 0.083 then 0.007 ms with 6 Godot processes running) |
| R1 | Silhouette area at 40 m | unit >= 120 px (FAIL < 45); mount 150 / 60; beast 350 / 150; titan 900 / 350; critter 25 / 8; building 5000 / 2000; landmark 3000 / 800 |
| R2 | Distinct from references | mean pixel IoU of the black masks over 4 turns <= 0.8; above it WARN "reads like X" unless the colour differs (mean dE >= 15) |
| R3 | Contrast vs the ground behind (main ground) | frames with and without the model, same pose and camera. **Mean-colour dE** (CIE76 between the body's mean L\*a\*b\* and the mean of the ground pixels behind it: the 40 m "average read") >= 20 PASS, 10-20 WARN, < 10 FAIL; and **melt share** (body pixels within dE 15 of that ground colour) <= 35 % (WARN above, FAIL > 60 %). Buildings 14 / 8, critters 14 / 7, landmarks 10 / 5. The value also gives body vs ground L\* / chroma, the hue gap, the per-pixel dE and the outline dE; the hint says whether value or hue is the problem ("melts into the grass") |
| R3 v2 | (additions) | the value also gives the **top third (by world height)** vs the ground (the part read from pitch 55; its own hint when it melts); the hue gap is only reported / hinted when the body's C\* > 25 (low-chroma bodies have no real hue) |
| R3t | Contrast in every team colour | R3's metric on the 4 kingdom-colour instances (enemy / mirror colours): worst >= de_warn, WARN only |
| R4 | Contrast on the other grounds | same metric on meadow / heath / Old Wood / riverbank / snow / ash / sand / marsh (the main ground skipped); worst below the FAIL line = WARN |
| R4k | Contrast on the home ground | the kingdom's own ground on its own line (fire ash, ice snow, nature Old Wood, shadow marsh): >= de_warn, WARN only |
| R5 | Glow points at 40 m (v2) | a **"hot" pass**: emission only, no bloom, linear tonemap scaled so a channel saturates exactly at the **bloom level** (the preset's `glow_hdr_threshold`, else 1.1); clusters by the brightest channel, merged within 3 px, >= 2 px. Flat decals hidden; clusters <= 4 px on the silhouette outline are a painted-shader rim light (ignored, counted apart); **median over 3 idle phases** (0.37 s apart); clusters > 15 % of the body = "glowing surface". Ranges: unit 1-3, wizard / champion 1-4, titan 1-5, building 2-4, **keep 4-12**, mount 0-2, beast 0-3, landmark 0-3, **objective landmark 4-12**. The value lists the **part** of each point; the emission tile boxes the points (green), rim specks (grey) and surfaces (orange) |
| R6 | Team-colour visibility | share of body pixels that change (dE > 8) between the 4 kingdom colours >= 3 % (FAIL if nothing changes); neutral = INFO |
| R7 | HP bar over the body at 40 m | the bar (body_height + 0.5, `max(1, radius x 2.6)` wide) hides <= 8 % of the silhouette (FAIL > 25 %; titans 6 / 20) |
| R8 / R8w | Head height / tall parts | head top within body_height x 0.75-1.25; parts above body_height + 0.4 narrower than 0.35 m (art-units 1.1). v2 **identity-crest tolerance**: wizards x0.75-1.45 / crest 0.7 m wide, champions x1.35 / 0.6 m (a crest inside the tolerance = INFO "identity crest") |
| R9 | Feet on the ground | lowest vertex -0.08 .. +0.05 m (FAIL > 0.15 m floating); buildings / landmarks touch (<= 0.05); flyers INFO |
| R10 | Footprint vs selection radius | x <= radius x 1.4, z <= x 1.4 (x 2.4 quadrupeds), 25 % slack; INFO when there is no UnitType yet. v2: thin "line" parts (two sizes < 8 cm: spear shafts, staffs, bow strings) are ignored and listed |
| A1 | Standard hooks | the kind's hooks exist (art-units 6.1, cavalry-mounts 10, map-fill 10, art-keep 8.8) |
| A2 | death_finished | fires <= 2.0 s after `play_death` (gameplay fallback) |
| A3 | Attack reads at 40 m | biggest silhouette change (1 - IoU rest vs pose) sampled at 0.08 / 0.14 / 0.24 / 0.36 s >= 12 % (titans 8 %, beasts 10 %) |
| P1-P5 | Polish (scored, never fail) | silhouette hook (outline complexity >= 2.2), asymmetric secondary element (front asymmetry >= 0.15), tops light / bottoms dark (top third - bottom third >= +10 L*), detail density at 25 m (3-11 mean L* gradient), a glow point in the upper half. v2: **P3 and P5 use world height** (a height pass: unshaded grey = world y / model top), so flat creatures and quadrupeds are judged by what is physically on top, not by screen rows; P5 counts glowing surfaces too |
| D1-D9 | Decor sets | kinds <= 6 (soft; map total 24), triangles per mesh <= 1200 (soft), only trees / logs / big rocks cast shadows (FAIL), ranges 65 / 90 m, instance-budget coverage, **units hidden by decor** <= 20 % (FAIL > 40 %), **units still read on the decor** mean-colour dE >= 20 (WARN only), coverage <= 55 %, glow points per 144 m2, patch frame cost |
| V2-V6 | VFX families | lights 0, nodes created per play after warm-up 0 (pooled), no leak 3 s after, 0 materials per play, peak particles 200 / draws 40 (soft), each id visible at 40 m (>= 200 px of the frame change by dE > 10 at its peak, sampled at 0.05 / 0.12 / 0.35 / 0.8 / 1.5 s) |

**Spawn animations (v2):** every fresh instance (the target, team-colour copies, references, the lineup) first gets
`skip_spawn()` / `skip_spawn_animation()` / `finish_spawn()` when it has one, then 0.6 s, then the lab waits until its
one-shot emitters stop (<= 3 s) and their particles fade (<= 1.5 s), so the Sapling's sprout or a spawn ring is never shot.

### Budget table (from `-- table`)
`meshes` = drawn meshes after the kit merge (B1, v2); the v1 authored-part number is B1a (INFO). Sources unchanged
except the new `landmark/objective` row; glow ranges per tier live in `GLOW_TIER`, crest tolerances in `TIER_READ`
(`lab_budgets.gd`).
| kind/tier | meshes | draw | separate | verts | tris | lights | systems | looping | particles | casters | materials | runtime_mats | frame_ms | n | source |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| unit/worker | 22 | 14 | 6 (soft) | 2500 |  | 0 |  | 0 (soft) |  | 4 (soft) |  | 0 | 0.005 | 100 | art-units.md 8 |
| unit/soldier | 26 | 14 | 6 (soft) | 2500 |  | 0 |  | 1 (soft) | 10 (soft) | 4 (soft) |  | 0 | 0.005 | 100 | art-units.md 8, tier3-extras.md 12 |
| unit/heavy | 30 | 16 | 6 (soft) | 6000 (soft) |  | 0 |  | 1 | 16 (soft) | 6 (soft) |  | 0 | 0.005 | 100 | art-units.md 8 (knight), tier3-extras.md 12 (heavy); verts / casters: lab default |
| unit/rider | 36 | 16 | 6 (soft) | 5000 (soft) |  | 0 |  | 1 | 10 | 5 (soft) |  | 0 | 0.005 | 100 | art-units.md 8 (rider = mount + rider) |
| unit/cavalry | 20 | 12 | 6 (soft) | 2500 (soft) |  | 0 | 1 |  | 10 | 4 (soft) |  | 0 | 0.005 | 100 | cavalry-mounts.md 10 (cavalry rider, mount separate) |
| unit/wizard | 26 | 16 | 6 (soft) | 3000 (soft) |  | 1 |  | 1 (soft) | 8 (soft) | 4 (soft) |  | 0 | 0.005 | 100 | art-units.md 8 (wizard) |
| unit/champion | 26 | 16 | 6 (soft) | 3000 (soft) |  | 0 |  | 1 (soft) | 8 (soft) | 4 (soft) | 5 | 0 | 0.005 | 100 | champions.md 4 / 13, tier3-extras.md 12 |
| unit/creature | 18 | 10 | 6 (soft) | 2500 (soft) |  | 0 |  | 1 (soft) |  | 4 (soft) |  | 0 | 0.005 | 100 | map-fill.md 10 (camp creature = soldier: 18 / 10) |
| beast/hero | 26 | 16 |  | 8000 (soft) |  | 0 |  | 2 (soft) |  | 6 (soft) |  | 0 | 0.01 | 12 | map-fill.md 10 (epic beast hero budget) |
| beast/titan | 36 | 20 |  | 12000 (soft) |  | 0 |  | 2 |  | 8 (soft) |  | 0 | 0.02 | 12 | titans-2.md 11 (Frost Wyrm uses the titan budget) |
| mount/mount | 12 | 8 |  | 6000 (soft) |  | 0 |  | 1 (soft) |  | 2 (soft) |  | 0 | 0.005 | 50 | cavalry-mounts.md 10 (mount) |
| titan/titan | 36 | 20 |  | 12000 (soft) |  | 0 |  | 2 |  | 12 (soft) |  | 0 | 0.02 (soft) | 12 | cavalry-mounts.md 10, titans-2.md 11 |
| building/keep |  | 32 |  | 12000 |  | 2 |  |  | 90 |  | 8 | 0 (soft) | 0.05 | 8 | art-keep.md 9 |
| building/hall |  | 32 |  | 12000 |  | 0 |  |  | 90 |  | 8 | 0 (soft) | 0.05 | 8 | art-keep.md 9 numbers, step-12/13 rules: 0 lights |
| building/small |  | 16 (soft) |  | 6000 (soft) |  | 0 |  |  | 40 (soft) |  | 6 (soft) | 0 (soft) | 0.05 | 8 | lab default (towers, walls, posts): half a keep |
| critter/deer |  | 6 (soft) |  |  | 1200 | 0 |  |  |  |  | 1 | 0 (soft) | 0.005 (soft) | 30 | map-fill.md 9 (game critter deer) |
| critter/rabbit |  | 6 (soft) |  |  | 300 | 0 |  |  |  |  | 1 | 0 (soft) | 0.005 (soft) | 30 | map-fill.md 9 (game critter rabbit) |
| critter/cosmetic |  | 2 (soft) |  |  | 300 | 0 |  |  |  |  |  |  | 0.003 (soft) | 30 | map-fill.md 9 (cosmetic critter) |
| decor_set/set |  |  |  |  |  | 0 |  |  |  |  |  |  |  |  | map-fill.md 9 / 10 (+ kinds 6, tris per mesh 1200, range 90 soft) |
| vfx/family |  | 40 (soft) |  |  |  | 0 |  |  | 200 (soft) |  |  |  | 0.02 (soft) |  | art-units.md 6.10 / 8, cavalry-mounts.md 11 (pooled) |
| landmark/landmark |  | 24 (soft) |  | 20000 (soft) |  | 0 |  | 2 (soft) |  |  | 6 (soft) |  | 0.05 (soft) | 4 | map-fill.md 9; counts = lab defaults |
| landmark/objective |  | 32 (soft) |  | 24000 (soft) |  | 0 |  | 3 (soft) |  |  | 10 (soft) |  | 0.05 (soft) | 4 | map-fill.md 9 + mission objective (Crown altar, capture shrines): lab defaults, glow 4-12 |

## 4. Quality score, "Improve next", improvement log
- **Quality 0-100** = weighted mean of every scored check (readability x2, health x1.5, decor / VFX x1.5, budgets,
  animation and polish x1; the main-ground contrast x1.5 more). Checks are graded, not just PASS / FAIL: a PASS lands in
  70-100 depending on its margin (e.g. contrast dE 20 scores lower than dE 40), a WARN in 35-69, a FAIL in 0-34, and
  the polish checks (P1-P5) score 0-100 without ever failing. So the score moves when an agent improves something
  that already passes. The scorecard shows the previous run's score in the same out folder (before / after).
- **Improve next** (top of `scorecard.md`, header of the contact sheet): every FAIL first, then WARNs, then the checks
  with the most weighted headroom that carry a concrete suggestion (value contrast of the key read, silhouette hook,
  asymmetric secondary shape, glow placement, team-colour area, attack beat at 40 m, detail density 25 / 40 m, tops light
  / bottoms dark, decor occlusion...), each with the check and the shot it comes from. Always >= 3 items: the list is
  topped up with kind-specific ideas (idle / attack beats, detail density, key-read contrast, ground contact...).
- **`docs/art/lab/improvement-log.md`**: one row per windowed run: when, asset, kind / tier, quality (+ delta), result,
  top 3 suggestions, scorecard path.

## 5. Rule to add
The lead pastes this into `docs/plan/step13-agent-rules.md` and `docs/plan/step12-agent-rules.md` (and later steps):

> **N. Art Lab (every art task, `docs/plan/art-lab.md`).** When the asset is built, run the Art Lab windowed:
> `& $GODOT --path . -s res://tools/art_lab/art_lab.gd --quit-after 90000 -- scene=<your scene or set / vfx script> kind=<kind> kingdom=<kingdom>`
> (add `ref=` only if the auto-picked references are wrong). Open `docs/art/lab/<name>/contact_sheet.png` and
> `scorecard.md`. Fix **every FAIL** and every WARN that makes sense (a WARN you keep needs one line of reason in your
> report), then apply **at least the top "Improve next" item** and re-run. Repeat until there is no FAIL and the quality
> score stops rising. Your final report includes: the scorecard path, the **before / after quality score** (first run
> and last run), what you changed for each FAIL / WARN / improvement, and it ends with a section **"Art Lab notes"**:
> what the lab missed (problems you saw that no check caught), false alarms (checks that were wrong for your asset, with
> the measured value), and checks you would add. Never edit `tools/art_lab/` yourself.

The lead collects the "Art Lab notes" for one day, then gives them to one tech-artist task "Art Lab v2" (tune
thresholds, add checks). The notes are the lab's backlog.

## 6. Validation (2026-09-26, lab v1.0, GTX 1660, windowed)
Scorecards and contact sheets in `docs/art/lab/<name>/`. Thresholds were tuned on these runs so finished, good-looking
assets pass and the real problems still show.

| Asset (command args) | Result | Quality | What the lab says |
|---|---|---|---|
| Mirefang `kind=unit kingdom=neutral` (tier creature) | WARN | 87 | Budgets fine (10 meshes / 10 draws / 2 440 verts / 0 lights), frame cost 0.0026 ms per unit, 1 glow point, attack changes 47 % of the 40 m silhouette. **R3 contrast PASS: mean-colour dE 35.6** (the current body is a dark olive, L\* 38 on L\* 65 grass, with an orange frill). WARN R10: the tail reaches 1.45 m behind (radius 0.45 x 2.4 = 1.08). The "too green on grass" case: the Mirefang scale colour flat on the grass colour gives mean-colour dE < 10 / > 60 % melting = **FAIL** (asserted in `tests/test_art_lab.gd`); the real-world twin is the Mossback below |
| Frost Dragon `kind=titan kingdom=ice ref=cinder_dragon,war_mammoth,frost_wyrm` | WARN | 97 | 17 meshes / 18 draws / 8 580 verts, 0 lights; dE 77 on meadow; 2 glow points; team colour changes 71 % of the body; vs the Cinder Dragon: silhouette IoU 0.46 (same rig, depends on the wing phase) and very different colours, so it reads apart; death_finished at 1.87 s. WARN B9m: 1 mesh is built per instance (should be cached) |
| Mossback `kind=unit kingdom=nature` (tier heavy) | WARN | 84 | **WARN R3: green on grass**: mean-colour dE 18.1, hue gap 2 deg to the meadow (value only separates it); WARN 4 glow points (spec 1-2), 17 459 vertices (heavy soft 6 000; art-units 2 500), 7 shadow casters. "Improve next" #1 = push the shell's main mass off the grass hue |
| Dusk Steed `kind=mount kingdom=shadow` | PASS | 98 | 8 draws, dE 99, 1 glow point (the eye), IoU 0.67 vs the Roan Courser (horses: expected, colour differs) |
| Heath set `kind=decor_set` (heath_set.gd, ground heath) | WARN | 86 | 4 kinds, shadows / ranges fine, patch cost +0.009 ms process / +0.5 ms GPU; units hidden <= 16 % (Shade behind tall grass); WARN gorse 2 080 triangles (soft 1 200); WARN the Thornling (Nature green) melts into the heath patch (dE 8) |
| Fire gunpowder VFX `kind=vfx` (unit_fire_gun_vfx.gd, 5 ids) | PASS | 100 | 0 lights, 0 nodes per play after warm-up (pooled), no leak, 0 materials per play, every id visible at 40 m |
| Thornling `kind=unit kingdom=nature` (extra: a green unit) | PASS | 96 | dE 21.8 on meadow (just over 20; "Improve next" #1 = more contrast), everything else PASS |
| Fire Keep `kind=building kingdom=fire` (extra) | FAIL | 83 | **FAIL 14 775 vertices (art-keep 9: <= 12 000) and 18 unique materials (<= 8)**: the keep grew in the polish passes; WARN glow spread over 48 clusters (cracks) instead of 2-4 points |
| Deer `kind=critter` / Colossus `kind=landmark` (extras) | PASS 98 / WARN 86 | | Deer fine (tris, 1 material, dE 51). Colossus: WARN 7 glow points; IoU 0.80 vs the Giant's Stump at 40 m (borderline) |

**v2 re-runs (2026-09-26 23:46-23:55, busy PC: 6 Godot processes):**

| Asset | v1 | v2 | What changed |
|---|---|---|---|
| Sapling `scene=sapling kind=unit kingdom=nature` | WARN 93 (B1 15 authored parts; R5 2 points at luma 0.4; R8 WARN x1.3) | WARN 92 (91 first v2 run) | **B1 7 drawn** (B1a 15 INFO); the sprout is skipped before the shots (every shot shows the grown tree); R5 now **0 points above the bloom level 1.2** (median 1/0/0; 3 soft glows under it): the sap veins glow under the bloom, so "add a glow point" is a real v2 finding (or accept a soft kingdom glow, see next steps); P3 by world height +58 L\*; R4k Old Wood dE 29; R3t worst = nature green dE 20.6 |
| Ember Archer `scene=ember_archer kind=unit kingdom=fire` | WARN 95 | FAIL 91 | **B13 frame cost 0.083 / 0.007 / 0.011 ms per unit over 3 runs** (budget 0.005; busy PC): above the new noise band twice, so likely real (Perf Lab hot spot 4: fire model scripts) - re-run quiet before fixing; the v1 run passed it. B1 drawn; R3t: in the **nature** colour the archer drops to dE 7.7 on the meadow (mirror / recolour risk); R10 still WARN (the bow is a curved limb, not a thin line) |
| Fire Keep `scene=fire_keep kind=building kingdom=fire` | WARN 89 (v1 R5: 47 clusters at luma 0.4) | WARN 90 | R5 **32 points above the bloom level** (median 31/32/35) over the keep range 4-12, listed per part (Braziers x6, BannersGate x5, RoofLost x5, Spire x4, ...): now a precise art-keep 0.4 list; B4 11 397 verts / B8 7 materials (fixed since v1); B12 2 % down faces; R4k ash dE 24.9 |

False alarms found and fixed while tuning: per-pixel dE was inflated by the grass texture (replaced by the mean-colour
dE + melt share); the keep's own OmniLights lit the emission-only pass (lights now off there); buildings' per-instance
selection-rim materials (allowed by art-keep 8.6) are INFO; particle process materials no longer count as materials;
landmarks may be half buried; big glowing surfaces (the Frost Dragon's membranes) are not "points"; custom attack
styles are sampled at 4 moments; `TIME_PROCESS` units auto-detected (this build reports ms).

## 7. Known limits
- Needs a window: `--headless` has no renderer, so R1-R7, A3, P1-P5, D7-D9, V6 and the frame cost are SKIP there.
- Poses: v2.1 puts every instance at idle phase 0 (repeatable); flyers still flap between the shots, so R2 between
  two flyers matches their phase only as far as they spawned together. A single idle frame is judged (no motion blur,
  no "reads while walking").
- Silhouettes use a black override: alpha-scissor leaves and cards count as solid; transparent mist / glow cards count
  as body; flat ground parts (blob, contact decal, rings: < 8 cm tall at ground level) and particles are ignored.
- Glow points (v2) count emission above the bloom level on a no-bloom linear render: an emissive part just under the
  threshold (e.g. energy 1.0 on a 1.1 preset) does not count even if it looks bright with the bloom; a painted rim
  bigger than 4 px on the outline still counts. Big glowing surfaces are reported apart.
- Contrast is measured on fixed Crown Hollow spots (meadow / heath / Old Wood / riverbank) and, since v2, on **flat
  stand-in patches** for snow / ash / sand / marsh (the biome's `GROUND_TINT`, no ground texture / decals; the real
  step-12b TerrainSystem paint is not in the stage yet). The ice preset is used only with `light=ice` or `ground=snow`.
- Team colour uses one fresh instance per colour (the kit's `set_team_color` is spawn-time only: calling it again with
  the scene's own colour is ignored and `material_override` parts keep the first colour). Small pose differences
  between instances add a few edge pixels to R6.
- Frame cost: process time from `Performance.TIME_PROCESS` (this build reports ms, auto-detected) with the kit's distance
  tiers at zoom 40; small N (titans 12) makes it noisy (negative deltas are clamped to 0). GPU numbers are for info.
- VFX: ids are played with `at` = a ground point and `target` = a point 4 m ahead; ids that need a Unit target may show
  nothing (V6 WARN "may need a unit target").
- References are auto-picked by folder and height: a new kind of asset may need `ref=`.
- Buildings / landmarks are judged on the same per-kind rules; the per-building hooks beyond art-keep 8.8 (e.g.
  `set_owner_color`, `set_occupied`) are not exercised yet.
- R5 v2 removes most of the crack-vein noise (only veins above the bloom level count) but a keep with many hot cracks
  still splits into many clusters.
- B1 (v2) counts what is drawn after the merge; B1a keeps the authored count for info. A kit that merges late (after
  the lab's 4-frame spawn wait + settle) would be counted before its merge.
- R10 thin-part rule works per mesh: a spear merged into the arm mesh by the kit is no longer a separate thin part.
- Army sweep: per-asset runs are quick (no refs / frame cost) unless `full=1`; the army pass compares models of one
  folder only (no neutral neighbours) at yaw 0 / 90 / 180 / 270 with each model's own team colour.

## 8. Next steps (Art Lab v2 backlog; the "Art Lab notes" of the agents go here)
- Kit note (not the lab's file): `CharacterModel.set_team_color` is spawn-time only (the scene's own colour is ignored
  after a change, `material_override` parts keep the first colour). A mirror-match recolour or a mid-game recolour needs
  the kit owner to fix it.
- Compare flyers at a matching wing phase (R2), exercise the extra building / landmark hooks, a "reads while walking"
  check (40 m silhouette over a walk cycle).

## 9. Art Lab v2 (2026-09-26 23:32-00:40, tech-artist): progress and next steps
Done (all 9 backlog items from the day's "Art Lab notes" + `docs/art/art-audit-2026-09-26.md`, first pass each):
1. **B1 = meshes after the kit merge** (user decision 23:20); v1's authored count = **B1a INFO**.
2. **R5 at the bloom level**: "hot" pass (no bloom, linear, 255 = the preset's `glow_hdr_threshold` / 1.1), brightest
   channel, flat decals hidden, <= 4 px outline clusters = painted rim (ignored), median of 3 idle phases, per-part list,
   marked emission tile, tier ranges (`GLOW_TIER`: keep / objective landmark 4-12, wizard / champion 1-4).
3. **Spawn animations / effects skipped** (`_settle`: skip hooks, 0.6 s, one-shot emitters finished + faded) for the
   target, team-colour copies, references and the lineup.
4. **B10**: two action cycles; only materials first seen in the 2nd cycle count; saved `.tres` never count.
5. **R3**: top third by world height in the value + hint; hue gap only when C\* > 25; **R3t** (every team colour);
   **R4k** (home ground on its own line: fire ash, ice snow, nature Old Wood, shadow marsh).
6. **P3 / P5 by world height** (height pass).
7. **R10** ignores thin line parts (< 8 cm in two sizes); **R8 / R8w crest tolerance** for wizards / champions.
8. **ref= / scene= short names** (+ loud WARN R2r), grounds **snow / ash / sand / marsh** (stand-in patches), ice
   preset default on snow, **army sweep** (`sweep=<kingdom>`, references once for the army).
9. **Per-mesh vertex breakdown** (Notes + B4 value), **B11 surfaces per instance**, **B12 downward-facing triangles**.
Test: `tests/test_art_lab.gd` updated for the new rules (PASS).

Next steps (v2.1):
- Run `sweep=` for each kingdom (Ice / Nature first: their B1 FAILs should turn green) and log the results.
- Replace the flat snow / ash / sand / marsh patches with the real step-12b TerrainSystem paint in the stage once the
  terrain shader params are reachable like `ground_params.gd` (then drop the stand-in note from R4k).
- R5: the value now also shows the v1 "soft glow" count (luma > 0.4 with bloom) and the hint says when a soft glow only
  needs more energy. Decide with the art director whether soft kingdom glows (Nature sap veins) may replace a point
  (then: count soft glows as points for the nature tier).
- Army sweep: add the neutral neighbours to the army pass and a per-pair side-by-side tile; `full=1` is slow (frame
  cost x N). A full windowed sweep was not run yet (only a headless smoke run).
- Per-variant triangles for decor sets (map art note), B9: accept art-keep 8.6 per-keep copies explicitly (buildings
  are INFO already), glow-point local contrast (Ice/Nature note), R2 flyers at a matching wing phase.
Also done late: P1 / P2 hints say hooks thinner than ~0.25 m do not register at 40 m (1 px = ~4 cm); B13 noise band;
`tools/art_lab/run_art_lab.ps1` wrapper.

### 9.1 Art Lab v3 phase 0 (2026-09-27 08:20-09:30, four-wizards-high; plan `docs/plan/art-lab-v3-plan.md`)
- **0.1 split** of `lab_runner.gd` (110 KB -> 19 KB) into the modules of the section-1 map (`lab_shots.gd`,
  `lab_scenes.gd`, `checks/{budgets,readability,animation,polish,decor_vfx}.gd`, `lab_score.gd`). A mechanical move:
  every function body kept, run state reached through `ctx`, P1-P5 / A3 cut out of the 40 m pass and called at the
  same place (same check order in the scorecard). **Proof** (fixed idle pose, `log=0`, before / after scorecards):
  headless runs of Shade / Dusk Steed / Aqueduct / fire gun VFX give the same checks, statuses, scores and quality
  (98.4-100) except two animation-timing values (A2 1.01 vs 1.00 s; R8 score 4th decimal). Windowed: Aqueduct 24 / 25
  and the gun VFX 8 / 9 checks identical (only B13 frame cost differs), quality identical (98.5 / 100 / 98.6 Dusk
  Steed). Shade / Dusk Steed differ only in the values that move between two runs of the **unchanged** v2.1 lab too
  (before vs before-again: Shade 25 / 37 identical, FAIL 94 -> PASS 99 from B13 0.08 ms on a loaded PC, R5 phase
  0/1/0 vs 0/1/1, A2): +-1 px areas, +-0.2 dE, glow phase counts, A2 / A3 timing, B13. So the lab is repeatable in
  budgets / health / hooks / geometry and within this noise band in the render checks, not byte-identical.
- **0.2 batch**: `batch=` (+ `run_art_lab.ps1 -Batch`), stage pool (built + warmed once per light preset, `reset()`
  between assets), `fail_fast=1`, `timing=1`, reference heights probed once per process, vsync off in a batch; `sweep=`
  uses the stage pool too. Measured on the RTX 3070 laptop with 3-6 other Godot processes (other agents) running:

| 8 assets (shade, dusk_steed, aqueduct, mirefang, thornling, ember_archer, sapling, deer) | s / asset |
|---|---|
| single runs, lab time only (`in N s`) | 30.4 (19-41) |
| single runs, wall incl. Godot start (~5 s) and the Godot-gate wait (machine busy) | 107 (29-283) |
| batch, full (refs + frame cost) | **27.2** in process (first 29.5, then 26.8); 33.4 wall incl. one gate wait |
| batch, `quick=1 fail_fast=1` (the sweep setting) | **16.5** (first 19.5, then 16.1) |
| a planted budget FAIL with `fail_fast=1` (test, headless) | < 1 s after the headless checks |

  **Target <= 8 s / asset not met.** The start-up saving is ~5 s / asset (plus one gate wait instead of 8); the rest is
  the lab's own timed waits, not the process: per unit (`timing=1`, Shade) headless checks 7.8 s (two action cycles of
  ~3 s for B10 + settle 0.6 s), 40 m pass 5.6 s (4 team-colour copies x settle 0.6 s, A3 1.4 s, 3 glow phases),
  turns + anim strip 4.9 s (timed hooks), references 8.8 s (6 refs x settle + 30 silhouettes), frame cost 2.6 s;
  VFX families ~3 s per id (the gun family: 89 s). Next speed steps (phase 1, they change what is measured, so they need
  the 1.C calibration first): settle the 4 team copies / 6 references in parallel (one 0.6 s wait instead of 10),
  `focus=` (1.B) to re-run only the checks that changed, a shorter second B10 cycle, VFX ids played in parallel.
- Test `tests/test_art_lab.gd` extended (batch entries / file, kind guess, entry args, one stage for 2 assets,
  fail_fast on a planted critter-budget FAIL): `PASS art_lab`. `tests/test_tool_cine.gd` (ToolReport extends
  ArtLabReport): PASS.

## 10. v2.1 (2026-09-27, lab review on the laptop, RTX 3070 Laptop)
Checked the known notes against v2 first: rim light (R5), R3 low-chroma hue gap, P1 / P2 thin hooks, emission crop +
marked clusters, per-mesh vertex breakdown, B11 surfaces, B12 downward faces, R3t team colours, `ref=` short names,
objective vs decor landmark budgets, P3 / P5 by world height, identity crest, army sweep: **all already in v2**. Added:
- **Repeatable idle pose**: the kit picks each model's idle phase from `hash(instance id)` (`_phase_off`, flyers
  `_flap_p`), so an asset stood in a new pose every run and two flyers were compared at random wing phases (R2). The lab
  now sets phase 0 on every instance it spawns (`_fix_idle_phase` in `_settle`): Mirefang scored 95 / 95 on two runs;
  target, references and team copies share one idle phase (flyer R2 at a matching wing phase, first pass).
- **B1 per-pivot breakdown** in the value (`per pivot: Head 3, Mount 2, ...`) and an "Improve next" item naming the
  pivot to merge when B1 is over budget.
- **B9 accepts art-keep 8.6 per-building copies**: buildings / landmarks with per-instance materials up to 2x their
  material budget are INFO at full score (v2 already said INFO but still scored 0); above that it stays a WARN.
- B12 rule text printed `%%` (fixed); `run_art_lab.ps1` shows script / parse errors (a broken lab is no longer silent)
  and prints the scorecard path; section 1 uses the Godot gate instead of the desktop's Downloads path.
Left for later (v2.2): glow-point local contrast (needs the lit 40 m frame sampled around each hot cluster), per-variant
triangles for decor sets, the windowed army sweep per kingdom, real terrain paint for snow / ash / sand / marsh.

