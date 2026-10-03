# Review: face system, unit / building art merge code (since f53e3d70)

Reviewer: senior code review (read-only), 2026-10-02. Base: `f53e3d70` ("laptop start from a5aaecf").

Covered in depth: `art/units/kit/face/*` (FaceKit, FaceRig, UnitFaces, release()), `CreatureFaceRig`, `ChampionFaces`,
the kingdom face hooks (fire / ice / shadow / nature models), `character_model.gd` hit-flash + dance diff,
`PaintedVC`, `NatureVC`, `BuildingPalette`, `ChampionPalette`.
NOT yet covered in this file: `art/vfx/*` (ice / nature / spell / combat / caster_*), `art/buildings/stables/`, the 12 T3
unit scripts. Two separate read-only reviews of those were started and had not returned when this file was written;
their findings belong in an addendum.

## Verdict

The face system is well built: one cached mesh per unit type and expression, one shared material, the flash and glow
driven through instance uniforms, and no per-instance mesh copies. The quit crash fix (`release()`) holds up. I found
one real logic bug that affects every unit that has levelled up: its face smiles for good and never shows the
attack / cast faces again. There are also two smaller gaps: the face and hair do not take part in the hit flash, and
each face costs one draw call at every distance. The building merge code works, but the same merge is written four
times. No tests check face behaviour (only budgets and materials).

## Findings

### High

**H1. A face smiles for good after the unit's first level-up (close camera, cutscenes, portraits).**
`art/units/kit/face/face_rig.gd:55` (`elif float(model.get(&"_level_t")) < 1.6: mood = &"smile"`), the same check in
`art/units/neutral/creature_face_rig.gd:139`, `art/units/helpers/helper_vey/helper_model.gd:212` and
`art/units/helpers/helper_aldra/aldra.gd:594`.
`CharacterModel._level_t` only moves forward while it is below `LEVEL_LEN` (0.4): `character_model.gd:938-939`
(`if _level_t < LEVEL_LEN: _level_t += dt`). After `play_level_up()` (line 358) it therefore stops at about 0.40-0.45
and stays there until `revive()` sets it back to 99. So `_level_t < 1.6` stays true forever. That branch comes before
the cast and attack checks, so the face can no longer show `shout` or `fierce`.
*How it shows up:* a soldier reaches level 2 (or a wizard or champion levels up). From then on, at tier 0 (cinematic
camera, close zoom, tavern or portrait renders), every attack and every cast shows the open smile.
*Fix:* add a timer that keeps running (for example `var _level_age := 99.0`, set to 0 in `play_level_up()` and
advanced in `_process`), or have FaceRig keep its own timestamp of the level-up. Read that timer in all four places.
Add a test: level up, wait 2 s, attack, and check that `shown_expression() == &"fierce"`.

### Medium

**M1. The Face node (face + hair + beard) is left out of the hit flash.**
`character_model.gd:243-248` adds only the merged Chest / Head / ArmR nodes to `_flash_hit_targets`. `FaceKit.attach`
(`face_kit.gd:962-979`) creates a separate node, and `_collect` (`character_model.gd:1554-1555`) adds it only to
`_flash_all_targets`. On a hit, the head turns white (or cyan / lilac for Ice / Shadow) for 0.12 s while the eyes,
lips and the whole hair mesh keep their normal colours. The kit's unit_face shader supports the flash (slots 3/4), so
this is an omission. Units in CreatureFaceRig host mode do flash correctly, because their face is inside the merged
mesh.
*Fix:* in `FaceKit.attach`, set a meta such as `flash_hit` on the rig. In `CharacterModel._ready`, after `_collect`,
add the nodes that carry that meta to `_flash_hit_targets`. caravan.gd, mender.gd and rimecarver.gd already add extra
nodes this way by hand.

**M2. Each face costs one draw call at every distance, and nothing hides it.**
`face_kit.gd:962-979` / `face_rig.gd`: FaceRig is its own MeshInstance3D and has no `visibility_range_end`. Shadows
are off, which is good. Even so, at 200 population that is about 200 extra draw calls, plus the depth prepass, at the
RTS zoom, where the FAR face is a few pixels. At tier 2 the model freezes, but the face is still drawn.
*Fix:* set `rig.visibility_range_end` to around the tier-2 distance (with a small `visibility_range_end_margin`), or
hide the rig in `_update_tier` when `_tier == 2`. For mass units, the CreatureFaceRig host mode is the zero-extra-call
option.

**M3. Each new unit type builds its face meshes synchronously mid-match.**
`face_kit.gd:845-906` (`warm` builds 5 expressions + FAR on the first `attach` per key). `point()` (`:111-131`) runs a
GDScript `ray_intersects_triangle` loop over the head triangles for every decal vertex (about 800-1400 vertices x 6
meshes). Nothing in `scripts/` warms the faces at match start (grepped: no prewarm). So the first instance of each type
(first T3, first champion hire, first beast) pays this cost on the frame it spawns. The "never in a fight" claim
(face_kit.gd:5-6, 959-961) is true per type, not per match. I have not measured the cost: time
`FaceKit.warm` for a high-detail key before deciding.
*Fix:* warm the keys of the kingdoms in play while the match loads, or spread `warm` over a few frames.

**M4. `NatureVC.sync` / `BuildingPalette.refresh` redo full array uploads, plus RenderingServer default lookups, on
every state change.**
`art/buildings/nature/nature_vc.gd:46-92, 205-242`: every `apply_health` (each damage update), `apply_rim` and
`apply_boost` (every frame of a 0.15-0.25 s selection fade) rebuilds 9 packed arrays. `sync_cards` also calls
`RenderingServer.shader_get_parameter_default` for every null uniform: 18 uniforms x 4 slots. `building_palette.gd`
`_p()` does the same, and `index_of` calls `refresh()` once per new source (O(n^2) while the building is built).
`PaintedVC.sync_glow` (`painted_vc.gd:380-404`) runs every frame for every Fire Hall / Hearth (`fire_hall.gd:177, 202`)
with 6 new packed arrays and 6 `set_shader_parameter` calls, even when nothing changed.
*Fix:* cache the shader defaults once per shader, and add a dirty flag or value compare (sync_glow: compare with the
last uploaded arrays, or only sync while a pulse or fade is active).

### Low

**L1. The building merge is written four times.** `PaintedVC._bake`, `NatureVC._bake`, `BuildingPalette` and
`ChampionPalette._folded` each re-implement "copy the surfaces, write a per-vertex material channel, merge, cache by
mesh instance id", with differences that are already drifting apart:
- `NatureVC._bake` (`nature_vc.gd:307`) re-adds the KEEP surfaces without the custom-format flags. PaintedVC keeps
  them with `_custom_flags` (`painted_vc.gd:305, 408-416`).
- `ChampionPalette._folded` (`champion_palette.gd:183-234`) drops UV2 / CUSTOM and assumes triangles.
- Only `PaintedVC._prune` trims its cache. `NatureVC._cache` and `ChampionPalette._meshes` grow without limit if a
  per-instance mesh is ever passed in.

One shared "surface baker" with a channel callback would remove about 300 lines and these inconsistencies.

**L2. `ChampionPalette.claim_crystal_glow` (`champion_palette.gd:324-339`) writes CharacterModel private state**
(`_merged_nodes`, `_glow_nodes`, `_wk_glow_added`, `_wk_flare_written`) from a static helper. This goes against the
project rule that other systems never touch `_private` members. It will break silently if the kit renames them. Make
it a public kit method (for example `CharacterModel.claim_weapon_glow(node)`).

**L3. `FaceKit._dens` is a static shared by every build** (`face_kit.gd:50, 855`). It is set only inside
`face_mesh()`. Any outside call to `FaceKit.fill` / `strip` / `resample` silently uses the density of the last face
built. Pass the density in `cv`, or reset `_dens` after each build.

**L4. `FaceRig.auto` reads typed fields through `Object.get()`** (`face_rig.gd:46-59`, five reflective gets per frame
per unit at tier 0), although the parameter is typed `CharacterModel`. It is cheap, but it also hides typos: a renamed
field returns null and fails silently (the `!= 0` test turns into "always far"). Prefer a small public
`face_state()` on CharacterModel.

**L5. `UnitFaces._lean_cache` duplicates `FaceKit._styles`** (`unit_faces.gd:34-41`). `attach_lean` could check
`FaceKit._styles.has(key)` before calling `style_from`. This is minor: it costs one extra static dictionary that
`release()` must also remember (it does).

**L6. The four kingdom models copy the face tick** (`fire_model.gd:134-136`, `ice_model.gd:183-184`,
`shadow_model.gd:279-281`, `nature_model.gd:56-59` `_face_tick`), and each declares `var _face: FaceRig`. Moving
`_face` and the tick into CharacterModel (call `_face.auto(self)` before `_extra_process`) would also guarantee the
tick for subclasses that override `_extra_process` without calling super. glade_outrider_rider and stagrunner_rider
remember to call `_face_tick()` themselves.

### Tests

- There is no behaviour test for faces: nothing calls `set_expression` / `react` / `auto` and then checks
  `shown_expression()`, nothing covers the tier-0 / FAR switch, level-up, revive (`reset`) or
  `ChampionFaces.switch`. The existing tests (`tests/face_probe.gd` and the art budget tests) check materials, draw
  calls and glow vertices only. H1 would have been caught by a 10-line test.
- `release()` has no direct test (for example: build a face with a lambda, call `release()`, check that
  `_seen_styles` / `_cache` are empty and that no style value is a Callable). The protection today is only that CI
  stops exiting with -1073741819.
- The merge passes (PaintedVC / NatureVC) have no test that compares the look before and after (sampled vertex
  colours against the source `base_color`), which would protect L1 during a refactor.

## What is good

- **Draw-call and memory discipline.** Faces, hair, ears and beards are one vertex-coloured surface per unit with one
  shared material (`unit_face.tres`). Meshes are cached per type x expression, so instance 2 onward allocates nothing.
  CreatureFaceRig "host" mode even appends the face into the merged pivot mesh, so mounts gain no draw call.
- **The kit's instance-uniform slot contract is respected.** `unit_face.gdshader` declares `hit_flash` /
  `flash_color` / `glow_boost` at the kit's slot indexes, so flash and glow work per instance on a shared material.
  The Ice / Shadow / Fire per-model flash colour (`hit_flash_color/scale/time`) is a clean extension. `_set_flash`
  still writes only on change.
- **`release()` is a careful fix for the quit crash.** It strips the Callables out of every style that `face_mesh`
  saw, including dictionaries held by other statics (ChampionFaces, CreatureFaceRig, wizard styles). It runs on the
  root's `tree_exiting`, which fires after every child has left the tree, so no FaceRig rebuilds a mesh afterwards.
- `FaceRig` has no `_process` and swaps a mesh only when the shown expression changes. The FAR "bold" face is a
  thoughtful readability solution for the RTS zoom.
- PaintedVC keeps the building scripts' source materials as the source of truth (sync instead of rewrite), so the
  existing selection, damage and team code kept working without edits. Each merge's documentation explains its
  channels clearly.
