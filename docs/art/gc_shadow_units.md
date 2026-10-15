# G-C Shadow units

Task G-C of the graphics week (JS 2026-10-15: "make the graphics as beautiful as possible"). The Shadow army's
soldiers read as blocky primitives (box feet floating under capsule legs, plain cylinders and cones, box gauntlets,
flat plane capes). The Hall units and the Gloom Thrall are reshaped; the T2 / T3 units built from stacked cylinders
get smooth continuous limbs. No contract changed: same scenes, pivots, node names, attachment points, attack / death
styles, LOD tiers, team-colour API, hit flash, faces, glow nodes, merged-mesh draw counts.

## How

- `art/units/shadow/shadow_geo.gd` (`ShadowGeo`, static): lathes (rings of radius / height / z offset; ellipse,
  front keel, tattered hem `jag`, open arcs, caps, flat facets), tapered tubes along a polyline (parallel-transport
  frame, pointed tips, flattened sections), bevelled diamond-section blades (flat-shaded), tattered capes for
  `banner.gdshader` (real UVs, v 0 at the fixed top edge), Bezier helper, combiner. Every triangle is wound clockwise
  seen from outside (Godot's front face); the test checks it.
- `art/units/shadow/shadow_unit_dress.gd` (`ShadowUnitDress`): called at the end of `ShadowModel._build_parts`
  (after the face canvases are read, before the kit merge). Picks the scene by file (`shade.tscn` ...), not by
  `unit_kind` (Hollow Oathsworn and the forge stage-set puppets reuse kinds). On the first instance of a type it drops
  the generated primitives by node path and adds shaped parts with `add_part` (they merge into the existing pivot
  meshes: **no new draw instance**); later instances skip it all (`ShadowModel.is_type_merged()`). keep_separate parts
  that are reshaped (lantern cage, hound jaw and tail, the two capes) keep their node / transform / material and swap
  to a mesh cached once per type (B9 clean). Materials: the kit's Shadow palette only (team colour, `surface_kind`,
  hit flash, kit_detail all unchanged). `ShadowUnitDress.enabled = false` gives the pre-G-C look (shots).
- T2 / T3 (`barrow_ghoul`, `hollow_oathsworn`, `bleakbow`, `nightblood_reaver`, `hexweaver`, `gloom_deacon`): their
  cached `_tube` / `_path` helper (a stack of separate 5-6 sided cylinders) now returns one `ShadowGeo.tube` with two more
  sides and shared rings: rounder limbs, fewer vertices (ghoul 2044 -> 1544, hexweaver 2068 -> 1673, bleakbow 2081 ->
  1915, reaver 2101 -> 1822, deacon 2275 -> 2088, oathsworn 2459 -> 2285). Their shapes are otherwise unchanged
  (they were already hand-modelled and close to the 2500 budget). Cavalry riders: untouched.

| Unit | New shapes |
|---|---|
| Gloom Thrall (worker) | tapered legs + wrapped boots; hunched pale drudge robe with a tattered hem over a longer team-dark under-robe; ragged team mantle over the hump; rope belt + satchel; dark rolled rim framing the face, drooping hood tail; bell sleeves; crooked iron pole with a crook over the lantern, bone charm, two team rags; pagoda-roofed lantern cage (4 bars, bottom cup) round the glowing orb; rounded fist |
| Shade (melee) | tapered legs, pointed curled boots with spiky cuffs; tattered war-skirt (team dark); V torso; domed obsidian pauldrons with two curved silver spikes each; swept-back hood in team cloth (was dark: the biggest mass from the game camera) with a dark rim round the face; leather bracers; bevelled reverse-grip sickle blades with crescent guards, soul-fire back edge on the right one (the old glow strip); tattered half cape |
| Nightbolt (ranged) | legs + boots; long tattered coat (team dark) with longer tails; ragged team mantle; round quiver with a silver band; wide drooping hat brim with a tattered edge, bent pointed crown (glowing band kept); tapered iron stock, bone prod mount, recurved silver limbs with barbed tips and a string; rounded fist |
| Grave Hound | gaunt digitigrade legs with bone claws; six open bone ribs over the flanks; five curved spine spikes; swept-back horns; upper fangs; tapered lower jaw with teeth; vertebra tail ending in a barb |
| Shadow Knight (heavy) | obsidian greaves, silver knee cops with spikes, pointed sabatons with spiky cuffs; layered plate skirt (team), iron belt, bone skull buckle, pointed tattered tabard; faceted barrel cuirass with a keel and a V soul-fire rune (the old rune's glow point); spiky obsidian collar; three-lame domed team pauldrons with a silver rim and three curved silver spikes each; spiked couters, obsidian vambraces, rounded gauntlets with knuckle spikes; helm: ridged spire cap, silver brow band, cheek plates, crest fin, swept-back bone horns (kept under body_height + 0.4 for the HP bar); greatsword: wrapped grip, pommel spike, swept spiked guard, leaf-shaped bevelled blade (fuller glow kept); tattered cape |

## Graphics tiers

Shapes apply at every tier (lead ruling 2026-10-15: better model shapes at every tier while perf passes). Only the
**soul wisps** are gated: at High / Ultra (`GameSettings.effective_graphics_quality() >= 2`, read in `_after_ready`;
test hook `ShadowModel.wisp_quality_override`) the Shadow Knight gets 10 violet motes trailing off the greatsword and
the Gloom Thrall 6 motes rising from the lantern (`CharacterModel.make_motes`, shared resources). They emit only while
the camera is within the kit's tier-0 range (30 m), the model is on-screen, not frozen and alive
(`ShadowModel.wisps_should_emit()`, polled 5x / s by the SoulWisps node's own script `shadow_wisps.gd`: the model's
`_extra_process` stops while it is frozen off-screen, and the wisps stay out of the kit's `_loop_fx` so a tier change
never turns them on; only knights / thralls at High+ carry it, so 200 units pay nothing extra). Children of the model, so FogOfWar hides them with the unit. Low / Medium /
headless: never built.

## Measurements

**Art Lab** (lab default = Low, batch `docs/art/lab/gc_shadow/batch_before.txt` / `batch_after.txt` /
`batch_after_hall.txt`, scorecards in `docs/art/lab/gc_shadow/before|after/<unit>/`):

| Unit | Before | After | B4 body vertices | Notes |
|---|---|---|---|---|
| gloom_thrall | WARN 94 | WARN 96 | 1147 -> 1557 / 2500 | R10 footprint WARN is old (the lantern pole) |
| shade | PASS 97 | PASS 97 | 1289 -> 1714 | R6cb (colour-blind fire / nature) borderline: dark team skirt; hood moved to bright team cloth |
| nightbolt | PASS 95 | PASS 96 | 1325 -> 1469 | bow / stock pulled in to keep R10 |
| grave_hound | PASS 93 | PASS 95 | 1271 -> 1382 | |
| shadow_knight | WARN 91 | PASS 97 | 1094 -> 2971 / 6000 soft | old R8w WARN (horns above the HP bar) gone |
| barrow_ghoul | WARN 93 | WARN 94 | 2044 -> 1544 | R5 glow WARN is old |
| bleakbow / hexweaver / deacon / oathsworn / reaver | 95 / 96 / 96 / 94 / 92 | 95 / 95 / 96 / 95 / 94 | see above | hexweaver R10 WARN: x 0.44 / z 0.79 (measurement now sees its smooth staff) |

Draw instances unchanged for every unit (B2). B9 0 runtime meshes / materials. Frame cost B13 PASS.

**Shots** (windowed, `--gfx=high`, Art Lab stage, two Shadow squads purple vs red + the Hall row;
`art/units/shadow/tools/gc_shadow_shots.gd`, before = `--before`, same scene): contact sheet
`docs/art/lab/gc_shadow/contact_sheet.jpg` (built by `art/units/shadow/tools/gc_shadow_sheet.ps1`), key PNGs
`docs/art/lab/gc_shadow/shots/after_row_z7.png`, `after_hall_z10.png`, `after_portrait_left.png`,
`after_portrait_right.png` (the rest stay local).

Honest read: at zoom 10 and closer the change is large (no more box feet / box fists / flat bucket helm; tattered
cloth, spikes, horns, ribs and blades). At zoom 30-40 it shows as stronger silhouettes (knight pauldron spikes and
horns, shade swept hood, hound ribs and spines, nightbolt brim) more than as detail.

## Tests

- `tests/test_gc_shadow.gd` (new, headless): ShadowGeo winding / outward normals / cape UVs; per Hall scene on 2
  instances: pivots, keep_separate nodes and emitters, face rig, no BoxMesh drawn, same draws / vertices on the cached
  instance, budgets, shared reshaped meshes, team colour on the merged cloth; hooks (walk, attack, hit, level-up,
  death once + fade, revive); wisps none at Low, at forced High only on knight / thrall, on near, off far, off when
  off-screen within 30 m and back on when on-screen, off dead;
  ghoul / oathsworn budgets. PASS.
- PASS: test_a5, test_a17, test_kit_team_color, test_new_units_12, test_bowmen, test_unit_dances, test_12_v29,
  test_13_v7, test_13_v15, test_11_v4, smoke (victory=true), test_ws_perf (PASS at load x2.41), perf_test
  norm 6.54 / limit 6.72 (PERF OK; two earlier runs at 6.85 / 7.15 were machine load: the same run with the dress off
  gave 6.49 next to it).
- Coupling to know: test_13_v15 asks the Barrow Knight titan footprint >= 2.5 x the Shadow Knight's; the knight went
  2.68 -> 2.73 m2 (limit 2.84). Bigger knight pauldrons / spikes would break that test.

## Tools

`art/units/shadow/tools/gc_shadow_shots.gd` (shots + `--perf` 240 units), `gc_shadow_sheet.ps1` (contact sheet),
`gc_bounds_probe.gd` (a scene's vertex bounds and which mesh reaches each extreme, `--before` for the old look).

## Ideas left

Shape pass on the cavalry riders (barrow_knight, duskbolt_harrier, veilborn_dreadrider, gloam_rider) once the mount
work settles; the T2 units' box-ish pieces (reaver greaves, ghoul loincloth boxes); a tattered cape for the Nightbolt.
