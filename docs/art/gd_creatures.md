# G-D creatures

Task G-D of the graphics week (JS 2026-10-15: "make the graphics as beautiful as possible"): the neutral camp
creatures, the epic beasts, the hired neutrals and the game critters. No contract changed: same scenes, pivots, node
names, attachment points, attack / death styles, CreatureAbilities / MapFillVfx hooks, LOD tiers, hit flash, faces,
draw instances (every new shape merges into an existing pivot mesh or a keep_separate mesh that already existed).

## Inventory (art/units/neutral/)

| Asset | Scene | Used by |
|---|---|---|
| Bristleback | `bristleback/bristleback.tscn` | camp creature (bristleback.tres) |
| Mirefang | `mirefang/mirefang.tscn` | camp creature |
| Gloomcap Sprout / Elder | `gloomcap/gloomcap_sprout.tscn`, `gloomcap_elder.tscn` | camp creatures |
| Hollow Stag | `hollow_stag/hollow_stag.tscn` | camp creature |
| Ironhide Tusker / Old Scarback | `beasts/tusker/tusker.tscn` (variant 0 / 1) | epic beast |
| Stormcrest / Duskwing Roc | `beasts/roc/roc.tscn` (0 / 1) | epic beast |
| Greymane / Moonpelt Direwolf | `beasts/direwolf/direwolf.tscn` (0 / 1) | epic beast |
| Grizzlemaw / Elder Grizzlemaw | `beasts/grizzlemaw/grizzlemaw.tscn` (0 / 1) | epic beast |
| Frost Wyrm (Rimescale / crystal-horned) | `beasts/frost_wyrm/frost_wyrm.tscn` | titan-budget beast (no data/units entry today) |
| Stormbottle Genie | `stormbottle_genie/stormbottle_genie.tscn` | hired T3 helper |
| Magpie | `magpie/magpie.tscn` | Thieves' Guild thief |
| Greywater Tracker | `tracker/tracker.tscn` | Lodge hunter |
| Deer, Rabbit | `critters/deer.tscn`, `rabbit.tscn` | game critters (one mesh, vertex-rig shader) |
| Ruin Warden | `ruin_warden.tscn` | not in this task's list: untouched |

The "8 beasts" are the 4 beast models x 2 variants (`EpicBeasts.KIND_TYPES`).

## What changed

Shapes and materials (every tier; lead ruling 2026-10-15: better shapes at every tier while perf passes):

| Asset | Change |
|---|---|
| Tusker (both) | Plates were read as sheet metal: `tusker_plate` / `_plate_b` are horn now (surface_kind 7, spec 0.35 -> 0.14 / 0.18 -> 0.1, A slightly darker grey 0.43,0.46,0.50 -> 0.39,0.40,0.42), and every armour band carries a row of horn **scutes** (osteoderm knobs, bigger along the spine; `TuskerMesh._scutes`). The pillar legs get three sagging **skin folds** (ankle, knee) like an old pachyderm. Mesh keys `body_v2`, `leg_v2_*`. |
| Direwolf (both) | Fur locks shade as one soft painted fur mass: each lock's normals lean 62 % to the coat normal after its winding is set (`DirewolfMesh.soften`, `SOFT_FUR`), the silhouette stays shaggy. Sturdier build (body width x1.1 -> x1.16 / x0.95 -> x1.0, legs x1.3 -> x1.42 / x1.12 -> x1.22: B still < 0.9 x A's width). Moonpelt's blue-silver saddle widened (`SADDLE` 0.7 -> 1.0 rad) so the white wolf keeps a value break from the RTS camera. |
| Grizzlemaw (both) | The moss saddle was flat lurid fans: now **moss cushions** (4-5 soft domes per clump, half sunk in the fur; `_moss_cushion`), the moss material deeper (0.40,0.56,0.22 -> 0.33,0.47,0.19) with the fur / velvet surface kind (6). A **shag** of 48 soft fur locks over flanks / haunches / shoulders, normals leaning to the coat (`_soften`). |
| Gloomcap Sprout / Elder | Flat octagon spots -> raised fungal **warts** (`GloomcapMesh.warts`, same vertex count as the old spots; the Elder's crown warts stay low so the HP bar is not covered). |
| Others | Shapes untouched (Bristleback, Mirefang, Hollow Stag, Roc, Frost Wyrm, Genie, Magpie, Tracker, critters were already hand-lofted near their budgets: Mirefang 2440 / 2500, Elder over the soft 2500). |

**Signatures** (`art/units/neutral/creature_signature.gd`, `CreatureSignature`): one subtle looping emitter per
creature, built only at High / Ultra (`GameSettings.effective_graphics_quality() >= 2`; test hook
`CreatureSignature.quality_override`). Never built at Low / Medium or headless (headless runs are Low).

| Asset | Kind | Where |
|---|---|---|
| Bristleback | breath (warm snort puffs) | snout (Head) |
| Mirefang | mist (marsh vapour) | round the body (Mount) |
| Gloomcap Sprout | spores (glowing teal) | cap (Head) |
| Gloomcap Elder | mist (dank, low) | root feet (Root); its cap spores already loop at every tier |
| Hollow Stag | pollen (forest motes) | antler crown (Crown) |
| Tusker A / B | breath (hot steam) | snout (Head) |
| Roc A / B | sparks (storm crackle) / dusk_motes (violet, drifting down) | body (Body); restyled on set_variant |
| Direwolf A / B | breath / frost_breath | nose (Skull); restyled on set_variant |
| Grizzlemaw A / B | moss_dust (pale spores) | over the hump (Mount) |
| Frost Wyrm | frost_motes | body (Body) |
| Stormbottle Genie | sparks | cloud torso (Chest) |
| Magpie | glints (a stolen coin) | belt (Hips) |
| Tracker, critters | none (Tracker: a person with a face; critters: one-mesh shader rig, 30+ on a map) | |

Rules kept: the emitter is a child of a pivot of the model (FogOfWar hides it with the unit), world-space particles
(puffs trail a moving creature), 3-10 particles, materials / quads shared per kind and scale (static cache: zero runtime
materials per instance, `test_gd_creatures` B). It starts off; its own gate script (`creature_signature_gate.gd`) polls
5x / s and emits only while `model.signature_should_emit()` (kit tier 0 = camera < 30 m, not frozen, not off-screen,
alive; FlyerModel: tier 0 and alive) and `CreatureSignature.on_screen()` (inside the camera frustum, within 30 m). The
gate lives on the particle node because the kit's `_extra_process` stops while a model is frozen off-screen; the
emitter is never in a kit `_loop_fx` list (a tier change there would turn it back on).

## Measurements

Art Lab (default = Low), batches `docs/art/lab/gd_creatures/batch_before.txt` / `batch_after.txt`, scorecards in
`docs/art/lab/gd_creatures/before|after/<asset>/` (md / json committed, images local):

| Asset | Before | After | Notes |
|---|---|---|---|
| bristleback | WARN 92 | WARN 92 | R5 glow WARN is old (no glow by design) |
| mirefang | PASS 94 | PASS 94 | |
| gloomcap_sprout | WARN 94 | WARN 92 | same R5 WARN (old); small R1 / C-score swing |
| gloomcap_elder | WARN 96 | WARN 96 | B4 3100 / 2500 soft WARN is old (warts cost no vertices); a first pass with tall crown warts made R7 (HP bar) WARN, fixed |
| hollow_stag | WARN 91 | WARN 91 | 3 old WARN |
| stormbottle_genie | WARN 93 | WARN 93 | B4 WARN old |
| magpie | WARN 90 | WARN 90 | R5 WARN old |
| tracker | WARN 91 | WARN 91 | R10 / R5 old |
| tusker | PASS 95 | PASS 97 | test_12_v27 vertices A 6403 / B 6664 (limit 7000) |
| roc | WARN 95 | WARN 95 | R10 footprint WARN old |
| direwolf | WARN 92 | WARN 93 | R7 HP bar WARN old (9 %, unchanged); test_12_v29 vertices unchanged (soft normals cost none) |
| grizzlemaw | PASS 94 | PASS 95 | test_12_v30 vertices A 6585 / B 7820 (limit 8000) |
| frost_wyrm | WARN 91 | WARN 90 | no shape change (signature only, absent at Low) |
| deer / rabbit | PASS 99 / WARN 79 | PASS 86 / PASS 84 | critter files NOT touched: the swing is the shared stage (ground / light changes by other running agents between the two runs) |

Draw instances (B2), lights (B5), runtime materials (B9) and allocations (B10) unchanged for every asset.

Shots (windowed, `--gfx=high`, Art Lab stage, `art/units/neutral/tools/gd_creature_shots.gd`, before = taken before any
edit, same scene): contact sheet `docs/art/lab/gd_creatures/contact_sheet.jpg` (built by
`art/units/neutral/tools/gd_creature_sheet.ps1`), key PNGs `after_portrait_tusker_a.png`,
`after_portrait_direwolf_b.png`, `after_portrait_grizzlemaw_a.png`, `after_camps_z10b.png` in
`docs/art/lab/gd_creatures/shots/` (the rest stay local).

Honest read: at zoom 10 the change shows (horn scutes and leg folds on the tuskers, lumpy moss and a shaggier bear,
softer wolf fur and a Moonpelt with a saddle, raised gloomcap warts, the breath / spores / motes). At zoom 30-40 it
is small: the tusker reads less "tin can" and the Moonpelt less "flat white shape"; signatures do not run that far
out (by design: tier 0 only).

## Tests

- `tests/test_gd_creatures.gd` (new, headless): Low builds no signature on any of the 12 scenes; forced High: exactly
  one Signature per scene under the expected pivot, child of the model, shared materials across 2 instances, off when
  far, on at 6 m, off at 80 m, off when the camera looks away, on again, off once dead; direwolf / roc variant restyle;
  shapes (soft lock normals, horn plate kind + scutes, moss cushions A > 2 x B, raised warts). PASS.
- PASS: test_12_v20, v21, v22, v23, v27, v28, v29, v30, v32, test_12_c4, c9, c11, test_12_a3, test_13c_v8, v3, v9,
  test_13_v5, test_10_v6, v7, c6, c10, test_a2_7, test_a5, test_unit_review_fixes, test_unit_dances, test_face_review,
  test_g3b_materials, test_shader_lint, test_11_v4, smoke (victory=true), test_ws_perf (PASS, clash p95 32.15 / 36.42 ms).
- perf_test: norm 6.77 then 7.12 vs limit 6.72 (OVER) while 4-6 other Godot processes ran (other agents, the Art Lab
  batch). perf_test runs the mission 1 map (scenes/main.tscn): no camp creature or beast spawns there and headless is
  Low (no signature), so these changes are not in its path; to re-run on a quiet PC.

## Notes for later

- `art/units/kit/tools/assign_surface_kinds.ps1` maps names containing "plate" to metal (2): re-running it would put the
  tusker plates back to metal. Either skip `tusker_plate*` there or rename them (kit is frozen for this task: request in
  `docs/handoff/for-tech-artist.md` if wanted).
- Ideas left: a shag / mud-clump pass on the Bristleback (2078 / 2650 vertices), Hollow Stag bark plates, Roc feather
  layering, critter shapes (deer 1200-triangle budget), the Elder Grizzlemaw's silver streaks (flat strips) as soft
  locks.
