# Visual Diff Lab (Labs program item 4)

Golden screenshots of a fixed shot list, pixel-diffed on every run, to catch **accidental** visual changes (a shader
tweak that darkens the whole map, a HUD panel that moved, a unit model that lost its weapon). Same style as the other
labs: PASS / WARN / FAIL per shot, score 0-100, "Look at next", history log.

## Run it

```powershell
# check the current tree against the goldens (exit 0 = PASS / WARN, 1 = a shot FAILs)
powershell -ExecutionPolicy Bypass -File tools\visual_diff_lab\run_visual_diff_lab.ps1
# (re)record every golden from the current tree (after an intended visual change, or a new shot)
.\tools\visual_diff_lab\run_visual_diff_lab.ps1 -Golden
# re-record / check only some shots; looser tolerance; no history row
.\tools\visual_diff_lab\run_visual_diff_lab.ps1 -Golden -Shots lineup_ice,map_centre
.\tools\visual_diff_lab\run_visual_diff_lab.ps1 -Shots menu_main -Tolerance 20 -NoHistory
```

One **windowed** Godot run (1600x900, `--position 0,0`) through `tools/godot_run.ps1` (the Godot gate), ~35 s of
Godot time plus the gate wait. A window pops up: don't click it while it renders. Headless runs can't render: the lab
refuses them (exit 2). Headless test of the image maths: `tests/test_visual_diff_lab.gd` (prints `PASS visual_diff_lab`).

## Files

| File | What |
|---|---|
| `tools/visual_diff_lab/run_visual_diff_lab.ps1` | runner: commit id from `.git` files (git never run), launches the lab through the gate (`'--'` quoted) |
| `tools/visual_diff_lab/visual_diff_lab.gd` | SceneTree script: freezes the game, places cameras, spawns lineups, captures |
| `tools/visual_diff_lab/vdl_shots.gd` | the fixed shot list + ignore rectangles |
| `tools/visual_diff_lab/vdl_diff.gd` | pure image maths: diff, masks, verdict, heatmap, compare strip |
| `tools/visual_diff_lab/vdl_report.gd` | goldens, scorecard (md + json), history (md + jsonl) |
| `docs/visual/golden/<shot>.png` | the references (+ `<shot>.unstable.png` when a shot had unstable pixels, `golden.json` meta) |
| `docs/visual/lab/latest/` | last check: `<shot>.png` (now), `<shot>_diff.png` (heatmap), `<shot>_compare.png` (golden / now / heatmap), `<shot>_focus.png` (zoomed change regions, when >= 25 px changed), `scorecard.md` / `.json` (`regions` per shot) |
| `docs/visual/lab/history.md` / `history.jsonl` | one row per run (golden or check) |
| `docs/visual/.gdignore` | Godot doesn't import the goldens / heatmaps as textures (the lab reads them by OS path). The `*.png.import` files made before it (00:08) are stale and can be deleted by the lead |

## Shot list (v1, 9 shots, `vdl_shots.gd`)

| Shot | Scene / camera |
|---|---|
| `menu_main` | main menu + 3D diorama, after 150 frames |
| `map_player_base` | 1v1 skirmish (Fire vs Shadow) at match start, camera on the player keep, zoom 30, HUD on |
| `map_centre` | camera (0, 0) zoom 45 (Crown isle, river, crossings), **fog off** for the shot (`FogOfWar.enabled = false`) |
| `map_west_meadow` | camera (-24, 18) zoom 40 (meadow, fog edge; fog on) |
| `map_overview` | camera (-6, 6) zoom 55 (max zoom, taverns, isle, river), **fog off** |
| `lineup_fire` / `_ice` / `_nature` / `_shadow` | every unit type of the kingdom (sorted by id, workers included, caravans / timed summons not) in a row near the player start, facing the camera, other units + HUD hidden |

## How it stays deterministic

- `--fixed-fps 60`, global + node RNGs seeded like the Perf Lab (`class_rng` / `_rng` / `rng`, camp / guild services).
- The skirmish **loads with `Engine.time_scale = 0`**: every delta is 0, so idle animations, portraits and tweens stay at
  t = 0 however long the (threaded) navmesh bake takes. The match still starts (the bake doesn't need a timer).
  Fallback: if the match hasn't started after 900 frames, real time is used and the scorecard says so.
- Before capturing: tree paused, `time_scale = 0`, and the shader `TIME` is reset to ~0 by setting
  `rendering/limits/time/time_rollover_secs` to 1e-6 for 3 frames (water, fog, glow shaders render the same frame).
- Each shot is captured **twice, 12 frames apart**. Pixels that differ are "unstable" (an animation still running):
  they are ignored (grown by 2 px), stored as `<shot>.unstable.png` with the golden, and reported. v1: 0 unstable px
  on all 9 shots.
- Mouse parked in the bottom-right corner (no button hover).
- Ignore rectangles (v1): the **minimap** on the 4 map shots (its camera frame is redrawn on a real-time throttle, so its
  position at the freeze differs run to run), and Vessa next to the keep in `map_player_base` (she turns a little run
  to run). Blue in the heatmaps.

- Node RNGs (`class_rng` / `_rng` / `rng`) are seeded from the node's **path** (auto `@Class@123` ids stripped), when
  the node enters the tree and again after its `_ready`. Seeding by arrival order (the Perf Lab way) was not stable:
  threaded loads add nodes in a different order each run (menu diorama characters changed pose run to run: 1-1.4 %).
- The menu loads at time_scale 0 for 150 frames, then is frozen at t = 0 (`MENU_RUN_FRAMES` 0; verified 0 px).

## Known noise

- **Fixed 2026-09-27 (lab review):** the v1 map noise (`map_centre` 0.07-0.19 %, `map_overview` 0.07-0.16 %: the 4 Ruin
  Wardens on the Crown isle), Vessa's head turn in `map_player_base` and the menu diorama characters (menu_main
  1.0-1.24 % on the laptop) had one source: `CharacterModel._ready` picks `_phase_off` / `_tier_timer` from
  `hash(get_instance_id())`, and instance ids change run to run. The lab now sets them (and `_flap_p`, `_breath_t`,
  `_pollen_t`) from the node path right after `_ready` (`visual_diff_lab.gd` `_fix_idle_phase`, lab only; the game keeps
  its variety). Result: 0 px changed on all 9 shots over 3 runs, so `MAP_PASS_PCT` is back to 0.05 % and the Vessa
  ignore rect is gone. Only the minimap rect stays ignored.
- Remaining: `map_overview` can show **1 px** (x 1343, y 3) between runs: far under the 25 px floor.
- `docs/visual/lab/history.md` has 2 FAIL check rows (23:58, 00:02) from before the RNG fix: noise, not regressions.
- **Goldens re-recorded 2026-09-27 (laptop, RTX 3070 Laptop)**, all 9: the v1 goldens held one random idle phase per
  character, so menu_main FAILed (1.0 %, then 1.24 %) on every laptop check and the map goldens carried a random Warden
  pose no later run could reproduce. The lineups and `map_player_base` / `map_west_meadow` were already 0 px identical
  on the laptop GPU (desktop GTX 1660 and laptop renders match; re-check once on the desktop).

## Scoring

- A pixel changed when its largest RGB channel difference > **tolerance** (default 12 / 255).
- **PASS** <= 0.05 % of the compared pixels changed (or fewer than 25 px; `pass_pct` per shot, map shots were 0.35 %
  until the idle-phase fix), **WARN** <= 1 %, **FAIL** above; missing
  golden = **NEW** (counts as WARN). Score = 100 at 0 %, 0 at 5 % (linear). Overall = worst result, score = mean.
- Per shot: % changed, changed px, max delta, bounding box of the changes (x, y, w, h) + where (top-left ... centre),
  unstable px, ignored %.

## When a shot FAILs / WARNs

1. Open `docs/visual/lab/latest/<shot>_focus.png` first (v1.1): the change **regions** (changed pixels grouped in
   24 px cells) zoomed up to 3x, one row per region (red, orange, yellow bar = regions 1, 2, 3 of the scorecard's
   "Regions" list), golden | now | heatmap. Then `<shot>_compare.png` (whole frame at 1/3 size, magenta box = bounding
   box of every change).
2. Intended change (new art, new HUD) -> re-record that shot: `run_visual_diff_lab.ps1 -Golden -Shots <shot>`, commit
   the new golden with the change.
3. Accidental -> the heatmap region + the history row tell which commit / area to look at.

## Status (2026-09-27, 00:10)

- v1 built and run. Goldens: 9 shots recorded at 00:06 from HEAD `main@ccb98e65df` (+ wip tree) into
  `docs/visual/golden/` (1600x900 PNG, ~1-2 MB each).
- Check right after: **PASS 100** (worst 97): menu, `map_player_base` and the 4 lineups 0 px changed; `map_west_meadow`
  8 px; `map_centre` / `map_overview` 0.13 % / 0.07 % (known noise above).
- Detection proven on a tampered golden copy (scratch, not kept): a 120x90 box painted on `lineup_fire` -> WARN
  0.75 % (10 821 px = the 10 800 px box + 21 px noise) with its bounding box. (The same run's `menu_main` FAIL does
  not count: the menu code changed between that golden and the check.)
- Headless maths test green (`PASS visual_diff_lab`).
- Wall time: ~35-45 s of Godot per run (+ the gate wait when other agents run Godot).

## Next steps

1. (done in v1: `"fog": false` per shot.) A fog-off variant of `map_player_base` / `map_west_meadow` if the fog look
   itself should stop being part of those two.
2. The start-of-match selection panel's right half (portrait / stats) is empty in the frozen load (a timer fills it):
   step real time for a fixed number of frames after the freeze, or select Vessa again from the lab.
3. (done 2026-09-27: the idle-phase fix; the Vessa ignore rect is gone.)
4. Minimap: force a redraw after placing the camera (`queue_redraw` on the minimap control) so it can be compared
   instead of ignored.
5. More shots: 1920x1080 and 3440x1440 variants (the UI Lab will want them), buildings lineup per kingdom, VFX freeze
   frames (spell mid-cast at a fixed frame), the tavern / bazaar windows, the pause and end-of-match screens.
6. Golden size: ~1-2 MB each in git. If that grows, store goldens with Git LFS or keep them out of git on a
   OneDrive share (lead's call).
7. Hook into the lead playbook: run the lab after each wave (or before each commit touching `art/`, `scripts/ui/`,
   `scripts/vfx/`), like the Perf Lab.
