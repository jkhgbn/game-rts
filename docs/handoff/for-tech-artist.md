# For tech-artist (from gameplay-coder, task 4.G2)

- **Shadow soldier scenes have no `kingdom_color`**: `art/units/shadow/{gloom_thrall,shade,nightbolt,grave_hound,shadow_knight}.tscn`
  keep the default Fire colour `(0.85, 0.30, 0.12)`. Gameplay calls `set_team_color(Color(0.42, 0.22, 0.6))` (the Shadow kingdom
  colour, as art-units.md 6.1 says), so the kit's "no-op when it matches" never triggers and every Shadow soldier recolours
  (duplicated `shadow_cloth*` / cape materials, `_cloth_dark` gets `c.darkened(0.55)`). Fix: set
  `kingdom_color = Color(0.42, 0.22, 0.6, 1)` on those five roots (Malrik already has it).
- **Swing direction looks reversed** in `character_model.gd` (`melee_swing`, `worker_pick`, `dual_slash`, `great_swing`,
  `_pose_mine`): with the README rule "negative rotation.x raises the arm forward", the strike keyframe `+55` / `+60` / `+30`
  ends with the weapon arm swung *behind* the body, and the windup (`-70`) is forward. The Fire artist reported the same.
  Gameplay does not touch it (models face +Z exactly as `Unit._face` expects).
- Exit warning in every headless run with models: `1 resources still in use at exit` / `2 ObjectDB instances leaked`
  (probably the static `_merged` / `_mesh_cache` / `_mat_cache` dictionaries). Harmless, but a `static func clear_caches()`
  would silence it if the lead wants.

# From gameplay-coder (step 8, task 8.G1)
- `data/units/{sprigling,thornling,burr_slinger,bloomtender,bramblehorn,sapling}.tres` have no `model_scene` yet (no
  scene existed when 8.G1 ended). Name them `art/units/nature/<id>.tscn` (Burr Slinger = `burr_slinger.tscn`, not
  `slinger`) and set `model_scene` in the .tres, or ask gameplay to. Ysolde picks up `art/units/wizards/ysolde.tscn`
  by herself (`default_model_path`) once it exists.

# From gameplay-coder (step 8, task 8.G2): Nature spell VFX hooks (8.V5)
`SpellCaster.spell_effect(id, position)` on Ysolde's caster: `thornburst` = circle centre (radius = `radius_of(id)`);
`wild_bloom` = circle centre, then `wild_bloom_heal` on each healed unit every 0.5 s tick (its position);
`call_the_thicket` = the point, then `call_the_thicket_sprout` once per Sapling (its spawn spot). New signal
`summoned(id, units)` gives the Sapling nodes (grow 0.5 s: they hold that long; withering = Unit lifetime death).
# Step 9 (task 9.C3, from systems-coder): tavern model contract (9.V6)
- `res://art/buildings/tavern/tavern_model.tscn` is instanced as child "Art" of the Tavern body at its origin, no
  scaling. **Front (door side) = local +Z**; footprint 6 x 6 m centred on the origin, ground at y = 0. The tavern is
  turned so +Z faces the map centre (45 degrees on Crown Hollow). The door point (where champions walk out and rest)
  is 4.24 m in front of the centre, i.e. about 1.2 m in front of the front wall: put the door / threshold there.
- The script adds the collider (box 6 x 4 x 6); the model needs none. No lights (the lantern sign glows by emission).

# Step 11 (task 11.D2, from ui-designer): icon paths the UI reads (11.V7)
- The 4 class icons: `res://art/icons/classes/<class_id>.png` (`spear`, `sword_shield`, `two_hand`, `wizard`), 128 x 128
  as `ui-style.md` 6.1 (the weapon over the radial gradient); `IconLibrary.icon_for(&"classes", id)`. They are shown at
  **14 px** only (a 16 x 16 badge on the champion bar and tavern tile), so keep one bold silhouette per weapon. Until
  the files exist the UI draws a code glyph (`ui-champions.md` 15.1), so nothing blocks.
- The 12 class skill icons go next to the archetype ones: `res://art/icons/abilities/<id>.png` (`lunge`,
  `hobbling_javelin`, `skewer`, `riposte`, `second_wind`, `shield_throw`, `cleave`, `crushing_blow`, `whirlwind`,
  `arc_bolt`, `slipstep`, `starfall`), shown at 40 px in 48 px slots (and greyed at alpha 0.45 while locked).
- `flare_arrow.png` keeps its file name; the UI shows it as "Signal Flare" (a thrown flare would suit a repaint later).

# Step 10 (task 10.C1, from systems-coder): what the code expects from the 10.V8-10.V11 scenes
- Post / Den / Lodge scenes (`art/buildings/trade_post/trade_post.tscn`, `art/buildings/guilds/magpie_den/magpie_den.tscn`,
  `.../greywater_lodge/greywater_lodge.tscn`) are instanced as a child named "Art" of the TradePost / GuildHouse. Front =
  local **+Z**, footprint 6 x 6 centred on the origin, square on the grid (the root is turned in 90-degree steps so +Z
  faces the road); the door point is local (0, 0, 4). Hooks called when present: post `set_sign(i)`, `set_open(bool)`,
  `set_held(color_or_null)`, `set_selected(bool)`; houses `set_open(bool)`, `set_selected(bool)`, `play_band_out()`,
  `play_contract()`. No collision in the scene (the node has its own 6 x 6 x 4 box).
- Ground roads (10.V10): `EnvProps.set_roads` fills the ground shader uniforms **`road_segs`** (`uniform vec4
  road_segs[16]`, xy = a.xz, zw = b.xz), **`road_count`** (`int`, 10 on Crown Hollow) and **`road_width`** (`float`, 3.0)
  when `road_segs` exists in `art/environment/ground.gdshader` (nothing is set before). Segments: `Skirmish.road_param()`.
- Loot sack scene `art/vfx/trade_loot_sack.tscn`: instanced under the sack node (y 0 = ground); it may bob itself (the
  placeholder bobs 0.08 m). No hooks needed.

# Step 11 (task 11.V1, from tech-artist): champion class weapons, the convention for 11.V2-11.V5
Kit: `art/units/kit/character_model.gd` (sections "champion class weapon"), pieces + materials:
`art/units/champions/weapons/champion_weapon_kit.gd` (`ChampionWeaponKit`, static; the kit preloads it by path),
`weapons/materials/*.tres` (8, shared, read-only; never copy them into a champion folder). Test: `tests/test_11_v1.gd`.
Previews with the GENERIC grips (your starting point): `docs/art/screens/champion_weapons_kit.png`,
`champion_weapons_<champion>.png` (columns archetype / spear / sword_shield / two_hand / wizard; rows front 3/4, back
3/4), `champion_weapons_poses_<champion>.png` (4 attack strikes, then the 12 class skills in the order of 4.2),
`champion_weapons_z40.png` / `_z14.png`. Tool (windowed): `art/units/champions/weapons/tools/champion_weapons_preview.tscn
-- --shots`; it hides the Wayfinder's Bow and the Mender's Staff by hand (your tags will do it for real); the Oathwall's
hammer and the Coin-Cutter's knives are merged in their arms and still show until you tag them.

**How it works.** `set_weapon_class(id, pop := true)` (`spear` / `sword_shield` / `two_hand` / `wizard`, `&""` =
archetype) swaps each pivot's `Merged` mesh for a cached *class variant* = (the pivot's untagged parts) + (parts tagged
for that class) + (the class pieces whose slot is on that pivot): 0 extra draw instances, the weapon casts shadows with
ArmR / Chest. Slots: `hand_r` -> ArmR, `hand_l` -> ArmL, `back` -> Chest. Pieces (`ChampionWeaponKit.CLASS_PIECES`):
spear = `spear` (hand_r) + `quiver` (back) + `javelin` (hand_l, hidden unless a pose shows it); sword_shield = `sword`
+ `round_shield` (hand_l); two_hand = `greatsword`; wizard = `staff` (its crystal = the class's one extra glow point,
driven by the kit: own_glow, 1.6 x glow_level + pose flares). The swap also sets `attack_style` (spear_thrust /
sword_slash / great_cleave / staff_bolt) and `attack_windup` (0.12 staff, 0 melee) and restores the archetype ones
with `&""`. The pieces scale in over 0.3 s (pop, 2 temporary nodes) when the class is drawn; a class set before `_ready`
(save restore) appears without it. Variants are cached **per scene type**: grips and tags must not depend on the
instance (variant A / B included). Team colour (tassel, shield boss: `weapon_team_cloth`) follows `set_team_color`.

**1. Tag your archetype weapon (and identity props that move).** In `_build_parts()`, right after `add_part`:
- `mark_archetype_weapon(part)`: the part exists only before a class (bow, hammer, knives, censer staff).
- `mark_weapon_classes(part, [&"", &"spear", &"sword_shield"])`: only for those classes (`""` = before a class). Use it
  for props that change place, e.g. the Oathwall's door shield in ArmL `["", "spear", "sword_shield"]` + a second copy
  authored on Chest (on his back) `["two_hand", "wizard"]`.
- Static parts are left out of / merged into the variants (tag on the first build; `add_part` returns null for cached
  types and both helpers are null-safe). keep_separate nodes (Bow, the Mender's `Staff` Node3D...) are hidden / shown
  by the kit (children follow); don't toggle a tagged node's `visible` yourself.
- Budget: a tagged static part still counts in your authored meshes; the kit pieces don't (not authored by you, no
  extra draw instance). Keep <= 26 authored, <= 16 draw instances, <= 5 own materials.

**2. Grips.** Default `_weapon_slot(slot)` measures the fist on your merged arm (lowest point + 0.085 m, plausibility
checked, else a body-height estimate) and the back point just behind the chest merge. Measured today (model space):
Wayfinder hand_r (0.43, 0.915, 0.07), back (0.12, 1.22, -0.61) · Oathwall hand_r (0.64, 1.06, 0.10) = the fallback
(his untagged hammer is the lowest point; real fist FIST_R (0.64, 1.00, 0.20)), hand_l (-0.64, 1.06, 0.10) (irrelevant
if he keeps his door shield), back (0.12, 1.30, -0.47) · Coin-Cutter hand_r (0.32, 0.92, 0.06), hand_l (-0.40, 0.96,
-0.02), back (0.12, 1.06, -0.48) · Mender hand_r (0.53, 0.92, 0.17), hand_l (-0.55, 0.76, 0.13), back (0.12, 0.97,
-0.69) (the quiver sits beside the basket). Override, constant per scene:
```gdscript
func _weapon_slot(slot: StringName) -> Transform3D:
	if slot == &"hand_r":
		return Transform3D(Basis.IDENTITY, GRIP_R)       # the fist centre, model space, rest pose
	return super._weapon_slot(slot)

func _weapon_grip(piece: StringName) -> Transform3D:   # optional per-weapon tweak
	if piece == &"quiver":
		return Transform3D(Basis.from_euler(Vector3(-10, 0, -20) * DEG), Vector3(-0.18, 1.25, -0.55))
	return super._weapon_grip(piece)                     # = _weapon_slot(slot) * ChampionWeaponKit.piece_hold(piece)
```
Piece space: long weapons along +Y, origin = the fist (spear held 40 % from the butt; greatsword and staff held UP from
the fist, so their head goes forward when the arm rotates positive; sword forward-down; blades show their flat to the
front). `ChampionWeaponKit.piece_hold(piece)` = the generic rest orientation, `piece_tip(piece)` = the working end.
`weapon_slot_xf(slot)` / `weapon_grip_xf(piece)` read the result (identity before `_ready`); `get_weapon_tip()` = the
world tip (return it from your `get_beam_origin()` for the Wizard class; the Mender's must stop returning her hidden
censer then).

**3. Which pieces.** Override `_weapon_pieces(class_id) -> Array[StringName]` (super, then erase): the Oathwall
returns `[&"sword"]` for sword_shield (he keeps his door shield).

**4. After a swap.** `_on_weapon_class(class_id)`: re-grab nodes, reset your per-class state (called for `&""` too).
`weapon_class()` / `weapon_pieces()` tell your poses what the hands hold.

**5. Poses.** `play_cast(id)` sends the 12 class ids (`CharacterModel.CLASS_SKILL_IDS`) to `_pose_class_skill(id, t) ->
float`, never to your `_pose_cast` (whose default branch would swallow them). The kit has a generic pose for each
(`_wk_pose_*`, keyframes `_WK_*`); override for your own versions and call `super` for the rest:
```gdscript
func _pose_class_skill(id: StringName, t: float) -> float:
	if id == &"shield_throw" and weapon_class() == &"sword_shield":
		return _pose_door_throw(t)     # the Oathwall throws his door shield
	return super._pose_class_skill(id, t)
```
Archetype casts with a class weapon (Signal Flare, Snare Line, Trailblaze, Oath of Iron, Shield Bash / Bulwark from the
back, Cutpurse per weapon, the Soothing Circle jar throw) stay in your `_pose_cast`: branch on `weapon_class()`.
Attack styles: the kit plays the 4 class styles; your `_pose_attack` override already falls through to `super` for a
style that is not yours (keep it so); to customise one, test `attack_style == &"sword_slash"` first.
Pose helpers, called every frame they apply: `show_weapon_piece(piece, on)` (the merged mesh is swapped only when the
visible set changes; e.g. `(&"javelin", true)` during the throw, `(&"round_shield", false)` while it flies; an
interrupted pose gives the piece back by itself) and `weapon_flare(0..1)` (the crystal).
Generic timings: lunge strike 0.20 (0.6 s), javelin release 0.40 (0.8), skewer 0.30 (0.9), riposte held to 3.7 (4.0),
second wind (1.4), shield throw out 0.28 / caught 0.88 (1.1), cleave 0.30 (0.8), crushing blow 0.38 (0.9), whirlwind 3
turns (2.0), arc bolt 0.20 (0.6), slipstep gone 0.1-0.2 (0.5), starfall (1.2); spear_thrust / sword_slash strike 0.12
(0.5 s), great_cleave 0.16 (0.85), staff_bolt release = windup 0.12 (0.5).
Your `_on_action_event(&"release")` also fires for the class styles: effects tied to the archetype weapon (the Mender's
censer puff + swing, the Oathwall's hammer dust at FX_SLAM) should check `weapon_class() == &""`.

**6. Names.** Every private kit member of this feature starts with `_wk_`; don't declare `_wk_*` members in a model.

# Step 11 (task 11.V3, from tech-artist / Oathwall): notes for the VFX owner (11.V6) and 11.V1
- **Shield Throw VFX for the Oathwall**: his model throws his DOOR (1.2 x 1.6 m), not the round shield. The model
  flings `DoorShield` flat and shrinks it away 0.28-0.40 s (gone 0.40-0.80, caught back 0.80-0.88), so
  `ChampionVfx._shield_throw` carries the whole flight. Optional polish: when the caster's model has a node
  `Root/Chest/ArmL/DoorShield`, draw the flying piece as a flat rectangle (~1.2 x 1.6, rune tint steel-blue
  (0.6, 0.85, 1.0)) instead of the round disc.
- `tests/test_11_v1.gd` now expects the Oathwall's Sword and Shield WITHOUT the kit round shield (spec section 5):
  the round-shield checks read his `DoorShield` node for him (`_has_shield`, `_door_scale`), and the "shield boss
  team colour" check uses the Mender (the Oathwall's colour-first check moved to his spear tassel).

# Step 12 (task 12.V7, Riverbank set): notes for 12.V6 (biome scatter) and 12.V16 (critters)
- Set file `res://art/environment/biomes/riverbank/riverbank_set.gd`: BIOME_ID `&"riverbank"`, GROUND_TINT
  `Color(0.17, 0.32, 0.18)`, 10 ENTRIES over 5 meshes (`rb_reeds`, `rb_cattails`, `rb_lily_pads`, `rb_river_stones`,
  `rb_driftwood`, all in `biomes/riverbank/`, shared `nature_mat.tres`, 3 shape variants each through the variant mask).
- Two optional keys beyond the section-10 format: `"y": -0.35` on every `&"water"` entry (instance height = the water
  surface; the lily-pad origin IS the surface, reed / cattail stems reach 0.5 m below their origin) and `"shore": m`
  (water entries only within that distance of the water edge: reeds / cattails 0.7 m, lily pads 1.8 m). If 12.V6
  ignores `shore`, lily pads spread over the whole channel (still fine); if it ignores `y`, water entries sit 0.35 m
  above the water: please honour `y`.
- `per_100m2` is per 100 m2 of the entry's OWN zone (`&"bank"` 0-2.5 m from the water, `&"land"` 0-6 m, `&"water"`).
  Expected on Crown Hollow: ~930 instances (budget 1 800). Only driftwood casts shadows; ranges 90 (reeds, cattails,
  driftwood) / 65 (lily pads, stones). `riverbank_preview.gd` has a small stand-in of this scatter (`_scatter()`).
- 12.V16: fireflies under willows can use `WILLOW.crown_centre[variant]` (x s) and the willow positions from EnvProps.
# Step 12, task 12.V1 (river water) -> 12.V2 (ground cut), 12.V4 (fords), 12.V25 (wade VFX)
- **12.V2**: the river polylines end at N5 / S5 on the moat centre line (r 12.75). A plain capsule distance there bites
  0.75 m into the Crown Isle (the round end reaches r 10.25). Ignore the river segments' distance where `length(p) < 12.75`
  (the moat covers the mouth). The water's bank foam and the riverbed lip assume the cut is exactly at the half width.
  My wet-bank look inside the ford film ends in dark wet earth at its banks, to meet your 2.5 m wet band.
- **12.V4**: the ford film already has rapids foam along the drop-off rim and painted stones under it; your stepping stones /
  rapids dressing go on top. The film is at y 0.02 (`WaterMeshes.FILM_Y`). Piers standing in the water: give the lead /
  12.C1 their `(x, z, radius)` for the water's `foam_rocks` (foam collar + downstream V wake).
- **12.V25**: `art/environment/water/wade_ripple_tex.res` (128 px white ring with alpha, mipmapped) and
  `wade_ripple_mat.tres` (unshaded, alpha, double-sided, `vertex_color_use_as_albedo`: fade each ripple with the MultiMesh /
  instance colour alpha). Use a flat 1 x 1 m `PlaneMesh` at y 0.04 on a ford, scale 0.5 -> 1.9 over ~1.2 s while fading
  out, 3 per wader (see `water_test_strip.gd` `_process`).
# Step 12, task 12.V3 (Crown Bridges) -> whoever owns `art/environment/build_env.gd` `_build_ruin_dressing()` (12.V12)
- Two pieces of `meshes/crown_ruin_dressing.res` lie on the Crown Bridges' isle-end decks, i.e. in the lane: the broken
  lintel slab at angle 2.2 rad, r 10.6 (~1.7 m off the west bridge's axis, 0.45 m tall) and the toppled capital at 5.35 rad,
  r 10.3 (east bridge). The decks cover r 9.5-16.0 within 4 m of the lane axis (135 / 315 deg). Please move both out of that
  band (>= 0.5 rad from 135 / 315 deg, e.g. 1.8 / 4.95 rad: the parapets and brazier posts reach 4.9 m off the axis) when the ruins set is rebuilt; the kerb fragments at r 9.35 near 135 / 315 deg are fine.
  See `docs/art/screens/lane_bridge_z18_west.png` (the grey slab at the bridge head).

# Step 12, task 12.V4 (fords) -> 12.V24 (camp sites: the Mirefang nest in the ford)
- `art/environment/bridges/ford_stones.tscn` keeps the ford centre free within r 1.6 m for the nest mounds: its stepping
  stones run 1.85 m upstream of the centre (local -Z; +Z = downstream), sill boulders on the upstream rim (r 3.5-3.6),
  lip stones and the cascade on the downstream rim, marker poles on the banks at (+-2.95, -2.1) / (+-2.95, 1.1).

# Step 12, task 12.V8 (Hearth Meadow set) -> 12.V6 (biome scatter), 12.V2 (ground tint)
- Set file `art/environment/biomes/meadow/meadow_set.gd` (`BIOME_ID`, `GROUND_TINT`, `ENTRIES`), 6 meshes
  `biomes/meadow/meadow_{tufts,clover,daisies,dandelions,fruit_bush,hay}.res` (shared nature_mat.tres, 3 variants each;
  hay + fruit bush have a 2nd surface = contact disc). One MultiMesh per mesh and chunk, random yaw, uniform scale, y 0.
- `cluster` meaning used by my preview (`meadow_preview.gd` `_scatter()`): a fraction `cluster` of the count goes into
  patches of ~8 instances, gaussian sigma 1.2 m around a patch centre (x2 for the big props); the rest is even.
  Optional key `gap` (fruit bush 2.5 m, hay 3.5 m): min distance between two instances of that entry, clearance
  from roads / slots / buildings ~gap / 2. Scale `per_100m2` by the meadow weight inside the 4 m blend.
- Budget: sum per_100m2 = 52 -> ~1 010 instances on the skirmish map (both hubs, obstacles cleared), <= 1 280 upper bound.
- 12.V2: `GROUND_TINT = Color(0.40, 0.56, 0.20)` (short bright lawn); the clover mats are a darker cool green on top.
# Step 12, task 12.V13 (Landmarks A) -> 12.V32 (Colossus Crag nest) and 12.V6 (biome scatter)
- `art/environment/landmarks/colossus.tscn` at `(-57, 0, -16)` (yaw 0; the mirror at `(57, 0, 16)` turned by PI). In its
  local space: the head (collider cylinder r 2.2) is centred at (1.0, -, -0.7), crown pointing (0.85, 0, 0.53) (east-
  south-east), the face turned up 52 deg toward the camera, the beard toward the north-west. The flattest high area,
  good for the nest's branches, is around local (0.56, 2.15, -0.80) (top of the skull, upward normals; highest point
  2.53 m at (0.17, 2.53, -0.92)). World (player side): about (-56.4, 2.15, -16.8). The crag lair centre (-53, -18) is
  4.5 m east of the landmark centre, on the crown side. The open hand lies south-west (box centre local (-1.05, 1.59)).
- Stump `giant_stump.tscn`: roots reach r 3.6 m, decor-free radius (metadata `decor_clear_radius`) 3.8 m; colossus 4.2 m.
- Both use the shared `nature_mat.tres` / `nature_contact_mat.tres` (+ `colossus_rune_mat.tres`, env_glow ember, energy 2.0).

# Step 13 (task 13.V1a, from tech-artist): MountModel, the base of every mount (13.V2-13.V6, riders 13.V1b / V7-V12)
Kit file `art/units/kit/mount_model.gd` (`class_name MountModel extends CharacterModel`: merge, instance-uniform slots,
flash, glow, tiers, statuses, Unit fade all unchanged). First mount and reference: `art/units/mounts/rimehorn/`
(`rimehorn.tscn` + `.gd`, 2 own materials, previews `docs/art/screens/rimehorn_*.png`, tool
`tools/rimehorn_preview.tscn -- --shots`). Test: `tests/test_13_v1a.gd` (also checks a code-built mount with a Neck).

**Scene** (face +Z, feet origin, pivots unrotated at rest; your folder `art/units/mounts/<id>/<id>.tscn`):
`Root` > `Mount` (= the BODY pivot, kit name P_MOUNT; put it at the body centre: the gait pitches / rolls it) >
`Head` (P_MOUNT_HEAD, at the neck root), `LegFL LegFR LegBL LegBR` (top of each leg), optional `Neck` and `Tail` (extra
pivots merged and animated by MountModel; Head stays a sibling of Neck and is carried by it), `Seat` (Node3D, no mesh:
the rider's hip point, +Z forward). Plus `Fx` under the root. Set `is_quadruped = true`, `flinch_push = true`,
`attack_style = &"mount_toss"`, `kingdom_color` = your saddle-cloth colour, `body_height` = the hump / withers top.

**Authoring** (override `_build_mount()`, never `_build_parts()`): model-space helpers, all static meshes cached:
- `add_sculpt(pivot, func(s): ...)`: ONE authored part holding many primitives in several materials (fill it with
  `sculpt_put(s, mesh, mat, at, rot_deg, scale)`, `sculpt_add(s, mesh, xf, mat)`, `sculpt_crystal`, `sculpt_lock`,
  `sculpt_fringe`). The callable runs for the first instance only. This is how 12 authored meshes stay enough.
- `part(...)` = `add_part` that counts. `authored_mesh_count()` = parts + sculpts + barding + blob (budget <= 12).
- Builders: `lathe_mesh(key, [Vector2(r, y)...] bottom->top, seg)`, `tube_mesh(key, pts, radii, seg, caps, flat)`
  (horns, tails, legs; `flat` < 1 = blade section), `shell_mesh(key, rx, ry, a0, a1, l0, l1, thick, seg_a, seg_l, taper,
  bulge)` (curved plates / saddle-cloths around local Z; angle from +Y toward +X), `fringe_mesh(key, rx0, rz0, rx1, rz1,
  h, a0, a1, teeth, tooth, thick, ragged)` (shaggy manes, fur skirts, boots, around local Y), `lock_mesh()` +
  `lock_xform` (single fur lock), `crystal_mesh(tip)`, `frame(o, y_dir, z_hint)`, `material_at(path)`. Keys must be
  unique per shape. Avoid negative scales (flip the geometry instead).
- **Barding**: `add_barding_sculpt(pivot, func(s): ...)` / `add_barding_part(...)`: merged into a cached barded variant of
  that pivot's mesh; `set_barded(on)` swaps the mesh (0 extra draw instances), re-applies the team colour. Plates go
  OVER the plain parts (nothing is removed).
- Team colour: any `*_cloth`, `*_cloth_dark`, `*_cape`, `*_pennon` surface (use your kingdom's `<kingdom>_cloth`).
  `set_team_color(kingdom_color)` restores the scene's own. Only cloth surfaces are touched.
- `ensure_shadow_blob(r, tint)` then scale `_shadow` to the body. 0 lights. Particles: none in the Rimehorn; if you add
  one it counts as a draw instance (mount budget 8 incl. the blob).

**Hooks** (exact): `set_moving(speed: float)`, `play_hit()`, `play_death()` + `signal death_finished` (1.0 s: stumble,
roll onto its side at `lie_height`, glows off 0.3 s, blob fades), `set_team_color(c: Color)`, `set_barded(on: bool)`,
`is_barded() -> bool`, `play_charge()` (call on the charge hit; strike frame 0.10 s, 0.85 s: head levels the horn /
tusks by `charge_head_deg`, lunge, gore toss, glow flare), `seat_transform() -> Transform3D` (Seat in MODEL space with
the live bob / pitch / death roll), `seat_node() -> Node3D`, `gait_phase() -> float` (0-1, 0 = left-hind footfall),
`gallop_blend() -> float`, `is_galloping() -> bool`, `play_fidget()`, plus the kit's `play_attack` (mount_toss, strike
0.12), `play_cast` (short rear), `play_level_up`, `set_veterancy`, `set_status`, `revive`. All safe before `_ready`.
**Gait**: 4-beat walk at `stride_speed` / `stride_time`, blending (0.35 s) into a transverse gallop from `gallop_speed`
(m/s, independent of `stride_speed`, which Unit overwrites with move_speed) at `gallop_time` s per stride; hoof lift,
bounce, pitch rocking, head nod, tail lift. Exports: `walk_swing_deg`, `gallop_swing_deg`, `step_lift`,
`gallop_bounce`, `gallop_pitch_deg`, `gallop_head_deg`, `tail_swish_deg`, `tail_gallop_lift_deg`, `charge_head_deg`,
`lie_height` (0 = half the body width), `fidget_every`. The kit's `gallop_rate` is not used by mounts.
**Subclass hooks**: `_mount_ready()`, `_mount_process(dt)` (offsets only on animated frames), `_pose_fidget(t) -> len`,
`_pose_charge(t) -> len`, `_on_mount_event(ev)` (`charge_start`, `charge_hit`, `fidget_snort`, `death_down`),
`_on_footfall(leg 0-3, gallop)` (tier 0 only), `_mount_revive()`; pose helpers `rot` / `pos` (kit pivots) and
`xrot(X_NECK | X_TAIL, r)` / `xpos` (extra pivots); keyframe tracks `_mkf(t, PackedFloat32Array[t, v, ease...])`.

**For 13.V1b / riders**: parent the rider model to `seat_node()` (no frame lag, it follows bob, pitch and the death
roll) or read `seat_transform()` each frame; sync the rider bob to `gait_phase()` / `gallop_blend()`. The Rimehorn seat
is at (0, 1.48, -0.20); a shaggy hump rises in front of it to 1.64 (keep the rider's knees / cape clear of it).
Rimehorn numbers: 12 authored meshes, 8 draw instances (Body, Head, 4 legs, Tail, blob) plain and barded, ~5.0k
vertices (7.0k barded), 28 surfaces, 0 lights, 0 particles, length 3.75 m incl. the forward horn (tip at z 2.45).

# Step 12, task 12.V2 (ground river cut + biome tints) -> 12.V6 (BiomeMap / scatter), 12b.V1 (terrain layers), 12.V9-12.V12
- The ground's biome zones are **analytic** (no biome mask texture; the ground keeps ONE sampler, `tests/test_map_p1.gd`
  checks it). Same numbers for the scatter: `art/environment/ground_params.gd` (load() it) constants `HUBS` / `HUB_RADIUS`
  22, `WOODS` / `WOOD_RADIUS` 28, `HEATH_EDGE` 44, `BANK_REACH` 6, `BLEND` 4, `RUINS` (isle r 11 + 3 m around colossus,
  stump, standing stones), first match wins in this order: ruins > riverbank (water distance < 6) > meadow > old wood >
  heath (`max(|x|, |z|) > 44`) > glade. Water distance / cut: `water_distance(params, p)`, `is_cut(params, p)`,
  `in_ford(params, p)` with `params = skirmish_river()`. The ground jitters every border by about +-1.6 m of paint noise
  and blends over 4 m; a scatter weight from the plain distances matches it closely enough.
- `biome_tints` slots: 0 meadow, 1 heath, 2 old wood, 3 riverbank, read from `biomes/<id>/<id>_set.gd` `GROUND_TINT`
  (`heath`, `old_wood` sets not there yet: built-in fallbacks (0.50, 0.46, 0.26) / (0.18, 0.22, 0.13)). A set's tint is
  applied at `biome_tint_strength` 0.62 in a square-root space, so a darker or brighter GROUND_TINT is safe to try.
- The wet bank band is 0.8-2.9 m wide (mud ~0.45 m, damp earth ~0.5 m, then sand where wide), narrower (1 m, no sand) on
  the isle side of the moat: `bank` decor at 0-2.5 m sits on mud / sand, fine.
- 12b.V1: add `terrain_mask` as the 2nd sampler and update test_map_p1's `samplers == 1` with the lead; keep the
  `discard` single and last in `fragment()` (after every fwidth), and keep `skip_sun_shadow` (see for-systems-coder.md).
# Step 12, task 12.V12 (Crown Isle ruins set) -> 12.V6 (biome scatter) and the lead
- Set file `art/environment/biomes/ruins/ruins_set.gd`: `static func items() -> Array[Dictionary]` (shared format: `mesh`,
  `material`, `density` per 100 m2, `scale`, `vis_end`, `shadow`, `variants` = 3, + optional `id`, `cluster`, `gap`,
  `place`, `paving_ok`, `max_height`, `lane_clear_paving`) and the same data as `ENTRIES` (map-fill.md 10 format, paths)
  + `BIOME_ID &"ruins"`, `GROUND_TINT`, `ISLE_DAIS_CLEAR` 3.8, `PILLAR_CLEAR` 1.2, `LANE_CLEAR_FLAT` 2.6.
- 4 kinds (budget: <= 24 kinds map-wide): `ruins_flagstones` (15 / 100 m2, range 65), `ruins_ember_moss` (13, 65,
  `ruins_ember_mat.tres`, emission only), `ruins_drums` (4.5, 90, gap 1.6), `ruins_monuments` (1.5, 90, gap 4, the only
  one with shadows; its V2 is the cold brazier). One surface each, 3 variants by the shaders' position hash. No colliders.
- **Please allow the ruins set on the kind-1 paving spot** (the isle, skirmish spot `(0, 0, 9.5, 1)`): today
  `MapDressingArt._blocked()` keeps every spot decor-free, which would leave the isle empty. Keep the crown dais
  (r < 3.8), pillars (1.2 m), crossings and roads clear. Flat kinds (`lane_clear_paving` > 0) may come 2.6 m from the
  lane line on that paving instead of 5.2 (the isle plaza is almost all inside the 5.2 m corridor; units walk over them).
- `ruins_preview.gd` `_scatter()` / `_blocked()` is a working stand-in of those rules (mode=map, ~170 instances).
- Lead: the 12.V3 note above (move the lintel slab / toppled capital of `crown_ruin_dressing` off the Crown Bridge decks)
  is in `art/environment/build_env.gd`, which 12.V12 does not own and left untouched (the task said the dressing stays).

# Step 12, task 12.V10 (Old Wood set) -> 12.V6 (biome scatter), 12.V2 (ground tint), 12b.V6 (thickets)
- Set file `art/environment/biomes/old_wood/old_wood_set.gd`: `static func items() -> Array[Dictionary]` (mesh: Mesh,
  material: Material, density per 100 m2, scale: Vector2, vis_end, shadow, variants 3, + optional id / cluster / place /
  gap) AND the section-10 constants `BIOME_ID` `&"old_wood"`, `GROUND_TINT` `Color(0.19, 0.21, 0.12)`, `ENTRIES`.
- 6 meshes `biomes/old_wood/ow_{ferns,glowcaps,roots,cobwebs,moss_boulders,fallen_trunk}.res`, ONE surface each, so
  `material` == the mesh's surface material (a material_override gives the same result). Materials: shared
  `nature_mat.tres` (ferns, roots, boulders, trunks), own `old_wood_glow_mat.tres` (glowcaps: emission 1.8, variant mask,
  no lights) and `old_wood_web_mat.tres` (cobwebs: transparent blend, cull off, depth write; one MultiMesh is fine).
- Shadows only on moss_boulders / fallen_trunk; ranges 90 (ferns, glowcaps, roots), 65 (cobwebs), 110 (boulders,
  trunks). Optional `gap` (roots 1.5, boulders 3, trunks 7 m) = min spacing, clearance ~gap / 2. No colliders.
- Budget: sum density 23 / 100 m2 -> <= ~620 instances on the 2 680 m2 of both woods (~420 after clearing; Old Wood
  budget 900). Measured on the skirmish map (old_wood_preview.gd mode=map vs nodecor=1): within the GPU noise (~0.2 ms).
- 12b.V6: the fern item has `id` `&"ferns"` (double it in the thickets).

# Step 13 (task 13.V1b, from tech-artist): the seated rider in CharacterModel (riders 13.V7-13.V12)
Full contract: `art/units/kit/README.md` "Seated rider". Test `tests/test_13_v1b.gd`; preview
`art/units/kit/tools/rider_seat_preview.tscn -- --shots` (`docs/art/screens/13_v1b_*.png`: Torvald, Oathwall, Rimeshield on
the Rimehorn: riding, walk, gallop, mount, thrown, z40, silhouette).
- Use it: mount + rider as siblings (same transform), `rider.set_seated(true, mount)`; nothing to author in the rider
  scene. The kit puts the rider's **Hips pivot** on the mount's Seat each frame (bob, pitch, death roll), legs astride.
- Per model (13.V11 / V12): `seat_offset` (m, seat frame; e.g. `(0, 0.04, -0.05)`), `seat_leg_splay_deg` (0 = measured
  from the mount's body mesh; Rimehorn hits the 50 clamp, Dusk Steed ~35, Ember Boar ~44, Grove Stag ~48 for a
  Rimeshield), `seat_leg_forward_deg` (28). Override `_pose_seated(w, gait, gallop, moving)` (call super) to hold a
  staff / lantern pole / shield instead of the generic reins (ArmL -34 deg, ArmR -18 deg, faded while `_action` runs).
- Seen in the previews, for V11 / V12: Torvald's bell robe (on Hips) sits into the Rimehorn's back and reads as a draped
  robe; Oathwall's door shield on the back covers most of him from the side (a riding pose for it is V12's call); the
  legs are single rigid pieces (no knee pivot), mostly hidden in the Rimehorn's wool at 50 deg splay.
- Cavalry units built as rider + MountModel (V7-V9) can attack from the saddle: attack poses play on top, their Root
  motion halved, the legs stay astride.

# Step 12b, task 12b.V3 (Sand set) -> 12b.V6 (terrain scatter), 12b.V1 (sand ground layer)
- Set file `art/environment/biomes/sand/sand_set.gd` (`class_name SandSet`, read it with load()): `BIOME_ID &"sand"`,
  `GROUND_TINT`, `INSTANCE_BUDGET` 400, `VARIANTS` 3, `ENTRIES` + `static func items() -> Array[Dictionary]` (shared format +
  `path`, `id`, `cluster`, `place`, `gap`). 3 rows, 2 meshes: `tussock` (sand_tussock.res, 46 / 100 m2, place `&"sand"`),
  `tussock_edge` (same mesh, 190 / 100 m2, place `&"sand_edge"`: the thin 0.2-0.5 rim, a fringe ~1 per 1.5 m of edge),
  `bones` (sand_bones.res, 8 / 100 m2, `&"sand"`, gap 2.6, **shadow on** = the set's "rocks", range 90). Tussocks range 65,
  no shadow. `BiomeMap.load_items(&"sand")` already returns the 3 rows with their place (test_12b_v3 checks it).
- Density is per 100 m2 of the row's place area (not x weight): ~321 instances on the 4 patches before clearing
  (376 m2 sand + 62 m2 rim with the 1 m smoothstep edge model in sand_preview.gd); ~140 after the real map's clearing.
- 12b.V6: on the skirmish map roads, the watchtower capture point (Millwatch / Saltwatch) and the Colossus / Roc lair
  (Heron / Lantern Dunes) clear ~45 % of each patch, and the step-12 heath / ruins decor still stands on the sand (thin
  it there). Use chunked MultiMeshes: one map-wide MultiMesh fades out as a block at 65 m.
- 12b.V1: the sand at terrain.md's colours (light 0.86 / dark 0.66) lit by the 1.3 sun crosses the glow threshold in the
  preview stand-in (a soft bloom halo round the patch); tone the layer down or check it in the real shader.

# Step 12b, task 12b.V4 (Ash set, static-scar particles, TerrainVfx) -> 12b.V6 (terrain scatter), 12b.V1, lead glue
- Set file `art/environment/biomes/ash/ash_set.gd` (`class_name AshSet`, read it with load()): `BIOME_ID` / `TERRAIN_ID
  &"ash"`, `GROUND_TINT`, `INSTANCE_BUDGET` 200, `VARIANTS` 3, `ENTRIES` + `static func items()` (shared format + `id`,
  `cluster`, `place`, `gap`, `max_height`). 3 rows, 2 meshes: `charred_wood` (ash_charred_wood.res, **ash_char_mat.tres**
  (own shader, one surface), 5.5 / 100 m2, place `&"ash"`, gap 2.6, **shadow on**, range 90), `burnt_grass`
  (ash_burnt_grass.res, shared nature_mat, 105 / 100 m2, `&"ash"`, range 65), `burnt_grass_edge` (same mesh, 90 / 100 m2,
  `&"ash_edge"`). `BiomeMap.load_items(&"ash")` returns the 3 rows with their place (test_12b_v4 checks it).
- Decor only on the two STATIC Cinder Scars (`TerrainSystem.patches()` rows with terrain `&"ash"`); random / Fire ash never
  moves decor. ~160 instances for both scars. The Lost Cache (-30, 0) sits in the West scar: keep the wood ~1.5 m + gap / 2
  off it (the preview does).
- Static-scar particles: `AshSet.scar_fx(centre, radius := 4.5) -> Node3D` instances `ash_scar_fx.tscn` (EmberMotes 16
  additive quads + SmokeColumn 8, no light, no shadow, local coords, preprocessed, visibility range 90). Add ONE per static
  ash patch as a child of the dressing root (map origin), e.g. in MapDressingArt next to the ash scatter. 4 emitters map-wide.
- 12b.V1: ash_preview.gd draws a stand-in of the ash ground layer (terrain.md 7.1 colours) under the decor; the real layer
  should keep the blotch values dark enough that the pale ash tops of the charred wood (ash_char.gdshader `ash_color`
  0.50) still read against it.
- Lead glue (12b.L2): one Node3D "TerrainVfx" with `art/vfx/terrain_vfx.gd` in `scenes/skirmish.tscn` (next to
  MapFillVfx). It hooks the TerrainSystem (group "terrain") signals `event_warning`, `event_started`, `scorch_added` by
  itself; direct `play(id, at, radius, seconds)` calls are deduped with the hooks.
