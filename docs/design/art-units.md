# Art direction: characters (wave 4, tasks 4.V1 / 4.V2 / 4.V3 / 4.G2)

Written 2026-09-25 (task 4.D2). Source of truth for the tech-artist (`art/units/wizards/`, `art/units/fire/`,
`art/units/shadow/`) and for the gameplay coder who plugs the models in (4.G2).
Follows **section 0 of `art-keep.md`** (painted style, palette, shader, bloom). Metres, seconds, degrees.
Positions are `(x, y, z)` **relative to the unit's feet** (`y` up, **local +Z is the face / weapon side**:
`Unit._face` sets `_visual.rotation.y = atan2(dir.x, dir.z)`, which turns local +Z toward the target, and `_lunge`
pushes along the same +Z. This is the opposite of Godot's usual -Z "forward": do not "fix" it; see 1.6).
Colours `Color(r, g, b)` 0-1. Everything here is original: names and shapes are ours.

## Review 2026-09-25 (double-check before 4.V1-4.V3; these changes override anything older below)
- **Facing**: the header said -Z; the code faces **+Z** (fixed). Added a handedness note (1.6).
- **Build order / ownership** (new 2.4): the shared kit (`unit_model.gd`, parts, shader uniforms) is one owner's job,
  built first; the three builds only add scenes in their folders.
- **Materials** (2.2): the old "10 / 11 / 4" lists missed every per-unit secondary cloth, wood, bone, obsidian, crack
  and glow-energy variant. Replaced by closed palettes; team colour = the kingdom colour, so a 1v1 makes **no** duplicates.
- **Per-unit flashes**: `rune_glow` uniforms (`boost`, `energy`) and `banner` `amplitude` are *material-wide*, so
  "orb boost 3", "cape amplitude x3" and "cape amplitude 0 far away" would have flashed / frozen every unit of the
  kingdom. Now: new instance uniform `glow_boost` in `rune_glow.gdshader`; cape changes removed.
- **Part counts**: tables count rows, not meshes (Flame Guard was "14", really 24; knight "18", really 29). New rule 8:
  count every `MeshInstance3D`, and `unit_model.gd` **merges static parts per pivot once per unit type** (2.3).
  Hidden heads under helms removed (z-fighting). Wizard budget raised (only 2 per game).
- **Hooks** (6.1) rechecked against the code: `_lunge` is in `_perform_attack` melee branch (not line ~859); the hit /
  gold flash code already skips itself when there is no `_body_mat`; casts come from the existing `Wizard.spell_cast`
  signal with the real spell ids; wizards get `play_level_up` but never `set_veterancy` (their levels are 1-8);
  `set_status` returns `bool` so unhandled ids (`smoulder`, `burn`) keep their placeholder marks; death fallback 2.0 s
  with a run-once guard; `set_team_color` gets the kingdom colour, not the green/red ring colour.
- **HP bar / chevrons** can be hidden by hats (the bar shader keeps the depth test). 4.G2 draws them on top (7.4).
- **Decisions D1-D3 set to defaults** (end of file): deaths ~1.0 s (sink / fall, no dissolve shader: `discard` in
  `painted` would slow the keeps too); ranged windup <= 0.15 s owned by `unit.gd`; ground ring only.
- **Simplified for ~20 min per build**: one generic death per kingdom, veterancy = glow + L4 trim only (no pennons,
  no motes), no haste attack-speed retiming, one-shot bursts pre-built. Perf budget made concrete (section 8).
- **Originality**: all shapes and names are ours; note: the unit name "Shade" is also a Warcraft III unit name
  (it lives in `data/units/shade.tres`, not this file): suggest a rename to the lead (e.g. "Veilblade").

Sections: 1 style rules · 2 shared parts and materials · 3 wizards · 4 Fire army · 5 Shadow army + warden ·
6 animation · 7 veterancy and status looks · 8 performance and LOD · 9 ASCII sheets · 10 done when.

---

## 1. Style rules for characters

### 1.1 Proportions (chunky, "3 heads tall")
| Rule | Number |
|---|---|
| Head | Sphere / box of diameter **0.32-0.42 x body height** for soldiers (a Flame Guard 1.6 m tall has a 0.55 m head). Wizards 0.28 x (a longer hat takes the room) |
| Hands / fists | Spheres **r 0.10-0.14** (as big as half the head). No fingers |
| Shoulders | Wider than the hips by **1.6-2.2 x**; pauldrons are spheres / half-spheres r 0.16-0.24 hanging *outside* the torso |
| Weapon | **1.0-1.3 x body height** long; blades >= 0.18 m wide, staff heads >= 0.35 m. A weapon must read from 40 m |
| Legs | Short: **0.30-0.36 x body height**; feet are boxes 0.24 x 0.12 x 0.32 (long along +Z, the face side) |
| Torso | A tapered "keg": `CylinderMesh` top r > bottom r (heroic V) for soldiers; a bell (bottom wider) for wizards, workers and the Grave Hound |
| Smallest detail | **>= 0.12 m** in its smallest dimension (units are seen at 10-55 m, buildings rule is 0.35 m because they are seen farther and are bigger; below 0.12 m nothing survives MSAA at 40 m) |
| Height | The visual top of the head (not the hat / weapon) sits at **`body_height` +- 25 %** (checked: every unit below passes). HP bar (0.16 m tall, `max(1.0, radius x 2.6)` wide, billboard), chevrons and placeholder status marks hang at `body_height + 0.5 / + 0.8 / + 0.3` (`unit.gd`). 4.G2 draws the bar and chevrons on top (7.4), so hats may cross them; still keep any part above `body_height + 0.4` **narrower than 0.35 m** (hat cones, horns, staff heads) so the bar stays readable |
| Footprint | Everything stays within the collision radius x **1.4** at rest (arms and weapons may swing out to 2.0 x during attacks). Quadrupeds (Blaze Rider mount, Grave Hound) may reach **2.4 x radius** along z (nose / tail) |

### 1.2 Silhouette = role (the "black test" at 40 m, same as `art-keep.md` 0.1)
| Role | Silhouette rule | Fire | Shadow |
|---|---|---|---|
| Worker | Small, round, tool over the shoulder, **a sack / crystal on the back** when carrying | Cinder Hand: pick + basket | Gloom Thrall: hunched, lantern pole |
| Melee line | Wide shoulders + **big shield or blade**, square stance | Flame Guard: tower shield + short sword | Shade: two curved blades, no shield, thin |
| Ranged | Narrow, **long weapon held sideways**, quiver / arm bow | Ember Archer: long bow | Nightbolt: crossbow-like "dusk caster" held flat |
| Cavalry / fast | **Long horizontal mass** (mount) | Blaze Rider: rider on a flame boar | Grave Hound: low, long, spiky back |
| Artillery / elite | **Tall vertical extra** (backpack, banner, horns) | Ash Hurler: big sling pole + ash pot on the back | Shadow Knight: 2.4 m, horned helm, great sword |
| Hero | **Hat / crown + staff + cape** (three verticals) | Vessa: flame crown hat, orb staff | Malrik: horned mitre, shard staff |
Test: the tech-artist renders every unit unlit black on white in one contact sheet (`docs/art/screens/units_silhouette.png`) and names each by shape.

### 1.3 Colour split per unit (from `art-keep.md` 0.2, applied to bodies)
~**45 % team colour** (cloth, plates) · ~**30 % dark base** (leather, boots, hair, mount fur) · ~**15 % skin / metal** · ~**5-10 % glow**.
| | Team cloth | Team dark (cloth shadow) | Skin | Metal | Glow (emissive) | Leather / dark base |
|---|---|---|---|---|---|---|
| Fire | `(0.85, 0.30, 0.12)` | `(0.55, 0.08, 0.05)` | `(0.92, 0.72, 0.55)` | bronze `(0.62, 0.40, 0.16)` | `(1.00, 0.55, 0.15)` | `(0.22, 0.14, 0.10)` |
| Shadow | `(0.42, 0.22, 0.60)` | `(0.18, 0.08, 0.28)` | ashen `(0.62, 0.60, 0.70)` | tarnished silver `(0.55, 0.52, 0.66)` | `(0.70, 0.30, 1.00)` | `(0.12, 0.09, 0.16)` |
| Neutral (warden) | moss stone `(0.45, 0.50, 0.40)` | `(0.28, 0.32, 0.26)` | - | `(0.50, 0.48, 0.40)` | `(1.00, 0.85, 0.30)` | `(0.20, 0.22, 0.18)` |
- The **team colour parts** are the ones `set_team_color(c)` recolours (cloth, plates, the roof-like caps). The per-unit
  tints in `units-fire-shadow.md` (e.g. archer `(0.95, 0.55, 0.20)`) become the **secondary cloth** of that unit
  so units of one kingdom are still told apart; the team cloth itself is the kingdom colour.
- Team colour saturation >= 0.6, skin / metal saturation <= 0.35, dark base value <= 0.25: the team colour pops.
- Eyes: one **eye bar** (`BoxMesh` 0.22 x 0.07 x 0.06) per face. Glow colour, energy 1.5 on helmeted units,
  wizards and the warden; a dark bar `(0.10, 0.08, 0.08)` with no emission on bare-faced workers and archers.

### 1.4 Glow rules
- Every unit shows **exactly 1-2 glowing points** (weapon rune, eyes, orb, brazier). Wizards 3 (orb, staff runes, hat gem).
- Emission energy: **1.5** for eyes and small runes (no halo, no noise at 200 units), **3.0** for the wizard orbs and the
  Shadow Knight's sword (halo wanted), **4.0** only during cast / level-up flashes.
- Glow parts use `art/shaders/rune_glow.gdshader` (uniforms `glow_color`, `energy`, `pulse_speed`, `boost`, `phase`:
  **all material-wide**; per-unit changes only through the new instance uniform `glow_boost`, 2.4). Everything opaque
  uses `art/shaders/painted.gdshader` (`base_color`, `spec_strength`, `rim_strength`, `crack_*`, `damage`: material-wide)
  with its instance uniforms set **once in the scene** (inspector, no code): `ao_bottom` = 0 (the map is flat at y 0;
  `ao_bottom` is a *world* y) and `ao_height` = the unit's `body_height`. Never per frame.
- Rim light: default `rim_strength 0.25`; the gameplay selection ring stays the selection cue (no rim change on select, see 7.3).

### 1.5 Ground contact
Each unit has a **soft shadow blob**: `PlaneMesh` `radius x 2.6` square at `y 0.02`, unshaded, alpha blend, radial
gradient `(0.05, 0.03, 0.02, 0.45)` to alpha 0, no shadow cast, shared material per kingdom. Units keep casting the
real sun shadow (the sun does the shadows; `cast_shadow ON` for the 3-4 biggest parts only, OFF on small parts).

### 1.6 Facing and pivot
- The model scene root is a `Node3D` at the feet; the face, weapon hand and shield face **local +Z** (the direction
  `Unit._face` rotates `_visual` toward). The weapon hand (ArmR) sits at `x = +0.30`, the shield / off hand (ArmL)
  at `x = -0.30`; "right" and "left" below always mean these local x signs. (Facing +Z, local +X is anatomically the
  character's *left*: every table uses +X for the weapon on purpose, handedness does not read at 40 m. Never mirror a
  single unit.)
- Test it: in the preview, `rotation.y = atan2(d.x, d.z)` toward a marker must show the face and weapon to the marker.
- No part below `y = 0` except the shadow blob.
- Two eye dots would be below the 0.12 m rule; that is why every face uses one **eye bar** (1.3).

---

## 2. Shared kit (built once, reused by every unit)

### 2.1 Primitive parts library (the tech-artist makes them as `.tres` meshes in `art/units/parts/`, shared)
| Part id | Primitive | Size | Used by |
|---|---|---|---|
| `head_s` | `SphereMesh` r 0.22 (radial 10, rings 5) | workers, archers, casters | |
| `head_m` | `SphereMesh` r 0.27 | guards, shades, riders | |
| `helm_box` | `BoxMesh` 0.50 x 0.44 x 0.50 | guard, knight (scaled 1.3) | |
| `torso_v` | `CylinderMesh` top r 0.34 bottom r 0.24 h 0.55, 8 segments | soldiers | |
| `torso_bell` | `CylinderMesh` top r 0.22 bottom r 0.36 h 0.60, 8 seg | workers, wizards (scaled) | |
| `pauldron` | `SphereMesh` r 0.20 (half hidden in the torso) | guard, knight, rider, warden | |
| `arm` | `CapsuleMesh` r 0.09 h 0.42 | all bipeds | |
| `fist` | `SphereMesh` r 0.12 | all bipeds | |
| `leg` | `CapsuleMesh` r 0.11 h 0.40 | all bipeds | |
| `foot` | `BoxMesh` 0.24 x 0.12 x 0.32 | all bipeds | |
| `cape` | `PlaneMesh` 0.7 x 1.0, `subdivide_depth 6`, `banner.gdshader` (top edge fixed) | wizards, knight, rider | |
| `visor` | `BoxMesh` 0.22 x 0.07 x 0.06, `rune_glow` | helmeted units | |
| `shadow_blob` | `PlaneMesh` 1 x 1 scaled per unit | all | |
Every unit is built from these plus 2-6 unit-specific parts listed in its table. Mesh-count budgets are in section 8
(count every `MeshInstance3D` *before* the merge of 2.3; the tables' "Parts" lines count rows, not meshes).
Primitive sizes follow Godot 4: `CapsuleMesh.height` and `CylinderMesh.height` are the **total** height.

### 2.2 Materials: closed palettes (one `.tres` per entry, shared by every unit of the kingdom, never per unit)
Rule: a material = one (shader, colour, energy / params) combination. **If a table below asks for a colour or energy
not in the list, use the nearest list entry; never add a material.** Fire in `art/units/fire/materials/`, Shadow in
`art/units/shadow/materials/`, shared in `art/units/materials/`.
| Kingdom | `painted` | `rune_glow` | `banner` |
|---|---|---|---|
| Fire (18) | `fire_cloth` (team), `fire_cloth_dark`, `fire_skin`, `fire_bronze` (spec 0.35; also blades, gloves), `fire_leather`, `fire_wood` `(0.30, 0.16, 0.08)` (staffs, bow, pick, lance), `fire_fur` `(0.35, 0.16, 0.08)`, `fire_hair` `(0.20, 0.06, 0.04)` (hair, snout), `fire_ash_ball` (`(0.30, 0.28, 0.26)`, crack 0.8), secondary cloths `fire_sec_worker` `(0.80, 0.60, 0.45)`, `fire_sec_archer` `(0.95, 0.55, 0.20)`, `fire_sec_rider` `(0.95, 0.40, 0.05)`, `fire_sec_hurler` `(0.60, 0.35, 0.25)` | `fire_glow` (1.5), `fire_glow_hero` (3.0; Vessa's orb and gem), `fire_flame` (2.5, `pulse_speed 6`; crown flames, boar mane) | `fire_cape` (flame glyph), `fire_pennon` (no glyph) |
| Shadow (17) | `shadow_cloth` (team), `shadow_cloth_dark`, `shadow_skin`, `shadow_silver` (spec 0.35), `shadow_leather`, `shadow_iron` `(0.10, 0.08, 0.14)`, `shadow_obsidian` `(0.09, 0.07, 0.13)` spec 0.3 (knight armour, Malrik's shard; one rim value for both), `shadow_bone` `(0.80, 0.78, 0.70)`, secondary `shadow_sec_worker` `(0.50, 0.45, 0.55)`, `shadow_sec_bolt` `(0.55, 0.30, 0.70)` | `shadow_glow` (1.5), `shadow_glow_hero` (3.0), `shadow_glow_mid` (2.0; lantern, knight fuller, horn tips) | `shadow_cape` (diamond glyph), `shadow_cape_plain` (glyph_energy 0: Shade half-cape) |
| Neutral (5) | `warden_stone` (crack 0.6 amber), `warden_stone_dark`, `warden_moss` | `warden_glow` (2.0) | - |
| Shared (3) | `unit_eye_dark` `(0.10, 0.08, 0.08)`, `unit_gold_trim` `(1.0, 0.85, 0.4)` spec 0.4 | `crystal_glow` `(0.55, 0.85, 1.0)` 2.0 (carried crystals) | - |
Total **43 materials for every character in the game**, zero created at runtime in a 1v1. Dropped from the tables:
the Hurler's "soot `damage 0.3`" head (use `fire_skin`), Malrik's separate shard rim value, per-part energies that
differ from the list (they snap to the nearest entry).
**Team colour**: `set_team_color(c)` receives the **kingdom colour** (Fire `(0.85, 0.30, 0.12)`, Shadow
`(0.42, 0.22, 0.60)`), the same rule as the keeps (`art-keep.md` 8.7; not `Unit.team_color()`, which is the green / red
ring colour). If `c` equals the scene's cloth colour (+-0.01, always true in Fire vs Shadow) it does nothing; otherwise
(a future mirror match) it swaps `*_cloth`, `*_cloth_dark`, `*_cape` / `*_pennon` to duplicates cached in a
`static var` dictionary keyed by colour: made once per colour, never per unit.
Skin tones per unit come from the `painted` **height gradient + noise**, not from extra materials.

### 2.3 Node layout of a unit scene (the animation drives these 7 nodes only)
```
UnitModel (Node3D, root; script art/units/unit_model.gd, shared by every unit)
  Root (Node3D)        bob / breath / flinch / death tilt
    Hips (Node3D)      legs hang here
      LegL, LegR (Node3D pivots at the hip, y 0.55)   mesh children
    Chest (Node3D)     torso, pauldrons, cape, head
      Head (Node3D)    head, helm, visor
      ArmL, ArmR (Node3D pivots at the shoulder)  arm + fist + weapon / shield children
  Shadow (MeshInstance3D)  never animated
  Fx (Node3D)          particles, wizard light, status anchors
```
Rider / hound / mount units add `Mount (Node3D)` under `Root` with `LegFL, LegFR, LegBL, LegBR, Head`. The 7 (or 12)
`Node3D` pivots are the "bones"; there is no `Skeleton3D`.
- Pivot heights: a leg pivot sits at the **top** of its leg (listed leg centre y + half the leg height; "y 0.55" above
  is the Flame Guard value), its mesh hangs below it. Arm pivots sit at the listed shoulder point, the arm mesh hangs
  down from it. Every part in the tables is a child of the pivot named in its "Node" column.
- **Static merge (required, in `unit_model.gd`, once per unit type)**: at the first `_ready` of a scene path, for each
  pivot, all `MeshInstance3D` children that are **not** marked `meta "keep_separate"` are combined with
  `SurfaceTool.append_from()` into one `ArrayMesh` (one surface per material), cached in a
  `static var _merged: Dictionary` keyed by `scene_file_path + pivot name`; every later instance just assigns the cached
  mesh to one `MeshInstance3D` per pivot and frees the originals. Mark `keep_separate` only on parts that are toggled
  (`visible`), animated on their own (jaw, shard, flames, lantern, bolt, ash ball, crystals), particles, lights and
  the shadow blob. Result: about **8-14 draw instances per unit**, whatever the authoring detail.

### 2.4 Build order and file ownership (4.V1 / 4.V2 / 4.V3 run in parallel)
| Owner | Files | What |
|---|---|---|
| **Shared kit** (recommended as a first ~10 min step "4.V0" by one tech-artist before the three builds; if the lead keeps three parallel agents, **4.V1 owns it** and 4.V2 / 4.V3 build against this contract without editing these files) | `art/units/unit_model.gd`, `art/units/parts/*.tres`, `art/units/materials/`, edits to `art/shaders/painted.gdshader` and `rune_glow.gdshader` | The hooks of 6.1 with the generic idle / walk / flinch / death / level-up code, the merge of 2.3, the distance tiers of 8. Shader edits: `painted` gains `instance uniform float hit_flash = 0.0;` and `instance uniform vec3 flash_color = vec3(1.0);` with `EMISSION += flash_color * hit_flash * 2.0;` (keeps look unchanged at 0). `rune_glow` gains `instance uniform float glow_boost = 1.0;` multiplied into its final emission. Nothing else changes in the shaders |
| 4.V1 | `art/units/wizards/` | Vessa, Malrik scenes + their cast code (a `wizard_model.gd` extending `unit_model.gd`) |
| 4.V2 | `art/units/fire/` | 5 scenes + Fire materials; per-unit attack timelines as data (`@export` on the scene root) or a small `fire_model.gd` extending `unit_model.gd` |
| 4.V3 | `art/units/shadow/`, `art/units/neutral/` | 6 scenes + Shadow / warden materials, same pattern |
Scene config on the root (all `@export` of `unit_model.gd`): `attack_style: StringName`, `attack_windup: float` (6.4),
`death_style: StringName` (`&"fall"`, `&"sink"`, `&"crumble"`, 6.7), `stride_time: float`, `body_height: float`,
`is_quadruped: bool`. Missing pivots (a warden has no cape, a rider no `LegL`) are simply skipped: cache `get_node_or_null`
once in `_ready`.

---

## 3. Wizards (4.V1): the most detail, one small light each

### 3.1 Vessa, Fire Wizard ("the Ember Queen")
Concept: a proud fire sorceress in a wide-shouldered red mantle, a **crown-hat of bronze flames** and a staff whose
head is a caged sun. Height **2.0 m** to the head top (`body_height` 2.0; hat tip 2.75 m, thin). Radius 0.5.
| # | Part | Primitive and size | Position (centre) | Colour | Emission | Node |
|---|---|---|---|---|---|---|
| 1 | Skirt | `CylinderMesh` top r 0.30 bottom r 0.52 h 0.85, 10 seg | (0, 0.43, 0) | team `(0.85, 0.30, 0.12)` | - | Hips |
| 2 | Skirt hem band | `TorusMesh` inner 0.50 outer 0.58 | (0, 0.06, 0) | dark `(0.55, 0.08, 0.05)` | - | Hips |
| 3 | Torso | `CylinderMesh` top r 0.36 bottom r 0.28 h 0.55 | (0, 1.12, 0) | dark `(0.55, 0.08, 0.05)` | - | Chest |
| 4 | Mantle (shoulders) | `CylinderMesh` top r 0.30 bottom r 0.62 h 0.28, 8 seg | (0, 1.42, 0) | team | - | Chest |
| 5 | Mantle bronze rim | `TorusMesh` inner 0.58 outer 0.66 | (0, 1.30, 0) | bronze | - | Chest |
| 6 | Cape | `cape` plane 0.9 x 1.3, top edge at y 1.50, hanging behind (z -0.35) | (0, 0.85, -0.38) | `banner.gdshader`, Fire values | glyph emission 0.6 | Chest |
| 7 | Head | `SphereMesh` r 0.26 | (0, 1.76, 0) | skin `(0.92, 0.72, 0.55)` | - | Head |
| 8 | Hair | `SphereMesh` r 0.29 scaled (1, 0.8, 1.1), back half only visible (offset z -0.06) | (0, 1.82, -0.06) | `(0.20, 0.06, 0.04)` (near black-red) | - | Head |
| 9 | Eye bar | `visor` 0.20 x 0.06 x 0.06 | (0, 1.78, 0.24) | `(1.0, 0.55, 0.15)` | 1.5 | Head |
| 10 | Crown-hat brim | `CylinderMesh` r 0.46 h 0.08 | (0, 2.02, 0) | bronze | - | Head |
| 11 | Crown-hat cone | `CylinderMesh` top r 0 bottom r 0.34 h 0.75, 6 seg (jagged) | (0, 2.40, 0) | dark `(0.55, 0.08, 0.05)` | - | Head |
| 12 | Crown flames | `MultiMeshInstance3D`, 5 x cone (top r 0 bottom r 0.09 h 0.30), tilted 25° outward, ring r 0.40 on the brim | y 2.18 | `rune_glow` `(1.0, 0.55, 0.15)` | 2.5 (the "crown" halo) | Head |
| 13 | Hat gem | `SphereMesh` r 0.10 on the cone front | (0, 2.25, 0.30) | glow | 3.0 | Head |
| 14 | Arms (2) | `arm` capsule r 0.10 h 0.45, sleeves | shoulder pivots (+-0.42, 1.40, 0), hanging down 15° outward | team | - | ArmL / ArmR |
| 15 | Fists (2) | `fist` r 0.12 | arm ends | skin | - | ArmL / ArmR |
| 16 | Staff shaft | `CylinderMesh` r 0.05 h 2.3 | in ArmR, held at (0.45, 0.95, 0.20) vertical | `(0.30, 0.16, 0.08)` wood | - | ArmR |
| 17 | Staff cage | `TorusMesh` inner 0.20 outer 0.27, tilted 90° (vertical ring) + a second ring rotated 90° about y | (0.45, 2.30, 0.20) | bronze | - | ArmR |
| 18 | Staff orb (the sun) | `SphereMesh` r 0.20 | (0.45, 2.30, 0.20) | `rune_glow` `(1.0, 0.45, 0.1)` | **3.0**, pulse 1.5 s | ArmR |
| 19 | Orb light | `OmniLight3D` colour `(1.0, 0.55, 0.20)`, energy 1.2, range 4.5, shadows off | at the orb | - | - | Fx |
| 20 | Ember motes | `GPUParticles3D` 8 particles, lifetime 1.6, sphere r 0.3 at the orb, up 0.4, size 0.06 -> 0.02, ADD | orb | glow | - | Fx |
| 21 | Shadow blob | `shadow_blob` scaled 1.3 | (0, 0.02, 0) | - | - | Shadow |
Mesh parts: 22 `MeshInstance3D` (MultiMesh counts 1) + 1 particle system + 1 light (budget 26, section 8). The orb light
and motes are children of **ArmR** (not `Fx`) so they follow the staff in casts. Materials: flames `fire_flame`, orb and
gem `fire_glow_hero`, cape `fire_cape`, staff `fire_wood`, hair `fire_hair`. Signature detail: **the flame crown**: five
bronze flames that flare (scale 1.0 -> 1.5) when she casts.

### 3.2 Malrik, Shadow Wizard ("the Hollow Bishop")
Concept: a gaunt, very tall shadow priest in a narrow violet robe, a **split horned mitre**, a staff that is a
floating black shard in a silver claw. Height **2.0 m** (`body_height` 2.0; mitre tips 2.85 m, thin). Radius 0.5.
| # | Part | Primitive and size | Position | Colour | Emission | Node |
|---|---|---|---|---|---|---|
| 1 | Robe | `CylinderMesh` top r 0.24 bottom r 0.46 h 1.0, 8 seg | (0, 0.50, 0) | team `(0.42, 0.22, 0.60)` | - | Hips |
| 2 | Robe hem (torn) | `CylinderMesh` top r 0.46 bottom r 0.40 h 0.12, **6 seg** (jagged) | (0, 0.06, 0) | dark `(0.18, 0.08, 0.28)` | - | Hips |
| 3 | Torso | `CylinderMesh` top r 0.30 bottom r 0.22 h 0.55 | (0, 1.20, 0) | dark | - | Chest |
| 4 | Collar (high) | `CylinderMesh` top r 0.42 bottom r 0.30 h 0.35, 8 seg, open at the front (rotate so a seam faces +Z; fine if closed) | (0, 1.58, -0.05) | team | - | Chest |
| 5 | Collar silver trim | `TorusMesh` inner 0.40 outer 0.46 | (0, 1.74, -0.05) | silver | - | Chest |
| 6 | Cape | `cape` 0.8 x 1.5, top at y 1.55, z -0.30 | (0, 0.80, -0.32) | `banner.gdshader`, Dusk values | 0.6 | Chest |
| 7 | Head (skull-thin) | `SphereMesh` r 0.24 scaled (0.9, 1.1, 0.9) | (0, 1.80, 0) | ashen skin `(0.62, 0.60, 0.70)` | - | Head |
| 8 | Eye bar | `visor` 0.20 x 0.06 x 0.06 | (0, 1.83, 0.22) | `(0.70, 0.30, 1.00)` | 1.5 | Head |
| 9 | Mitre base | `BoxMesh` 0.44 x 0.30 x 0.40 | (0, 2.10, 0) | dark `(0.12, 0.05, 0.20)` | - | Head |
| 10 | Mitre horns (2) | cones top r 0 bottom r 0.12 h 0.65, tilted 18° outward (+-x) | (+-0.16, 2.55, 0) | dark | - | Head |
| 11 | Horn tips (2) | `SphereMesh` r 0.07 | (+-0.28, 2.85, 0) | glow | 2.0 | Head |
| 12 | Mitre gem | `SphereMesh` r 0.10 | (0, 2.15, 0.22) | glow | 3.0 | Head |
| 13 | Arms (2) | `arm` r 0.09 h 0.50 (long sleeves) | pivots (+-0.36, 1.45, 0), 10° outward | team | - | ArmL / ArmR |
| 14 | Hands (2) | `fist` r 0.11 | arm ends | ashen skin | - | ArmL / ArmR |
| 15 | Staff shaft | `CylinderMesh` r 0.045 h 2.4 | held at (0.42, 1.0, 0.20) | `(0.10, 0.08, 0.14)` iron | - | ArmR |
| 16 | Staff claw | 3 x cones (top r 0 bottom r 0.06 h 0.35) tilted 30° inward around the top, `MultiMesh` | (0.42, 2.35, 0.20) | silver | - | ArmR |
| 17 | Staff shard | octahedron (two cones top r 0 bottom r 0.14 h 0.24, 4 seg, base to base) **floating** 0.1 m above the claw, spins 40°/s, bobs +-0.04 m over 2 s | (0.42, 2.62, 0.20) | obsidian `(0.09, 0.07, 0.13)` `rim_strength 0.6` | - | ArmR |
| 18 | Shard core | `SphereMesh` r 0.10 inside the shard | same | `rune_glow` `(0.70, 0.30, 1.00)` | **3.0**, pulse 2 s | ArmR |
| 19 | Shard light | `OmniLight3D` `(0.60, 0.30, 1.00)`, energy 1.0, range 4.5, shadows off | at the shard | - | - | Fx |
| 20 | Void motes | `GPUParticles3D` 8, lifetime 2.0, ring r 0.5 at the feet rising 0.5 m/s, size 0.05, ADD | (0, 0.2, 0) | glow | - | Fx |
| 21 | Shadow blob | scaled 1.3, tinted `(0.15, 0.06, 0.25, 0.45)` (mist stain) | (0, 0.02, 0) | - | - | Shadow |
Mesh parts: 22 + 1 particle system + 1 light (budget 26); shard light is a child of **ArmR**. Materials: shard
`shadow_obsidian`, core / gem `shadow_glow_hero`, horn tips `shadow_glow_mid`, mitre `shadow_cloth_dark`, staff
`shadow_iron`. Signature detail: **the floating shard** that never touches the staff; on cast it drops into the claw
(0.1 s) and springs back.

---

## 4. Fire army (4.V2). Shared kit parts are named by id; only the extras get sizes
All Fire soldiers: cloth = team `(0.85, 0.30, 0.12)`, dark cloth `(0.55, 0.08, 0.05)`, bronze metal, skin `(0.92, 0.72, 0.55)`,
leather `(0.22, 0.14, 0.10)`, glow `(1.00, 0.55, 0.15)`. Node column as in 2.3.

### 4.1 Cinder Hand (worker). Height 1.4 m (`body_height` 1.4), radius 0.4
Concept: a stout, cheerful ash-miner with a big pick and a crystal basket strapped to the back.
| # | Part | Primitive / size | Position | Colour | Emission | Node |
|---|---|---|---|---|---|---|
| 1 | Body | `torso_bell` scaled (1.0, 0.9, 1.0): top r 0.22 bottom r 0.36 h 0.54 | (0, 0.62, 0) | secondary cloth `(0.80, 0.60, 0.45)` (the unit tint = a dusty apron) | - | Chest |
| 2 | Apron bib | `BoxMesh` 0.30 x 0.30 x 0.08 | (0, 0.78, 0.30) | leather | - | Chest |
| 3 | Belt | `TorusMesh` inner 0.30 outer 0.36 | (0, 0.40, 0) | team | - | Hips |
| 4 | Head | `head_s` r 0.24 | (0, 1.15, 0) | skin | - | Head |
| 5 | Cap (flat, round) | `CylinderMesh` r 0.30 h 0.10 + a stub `CylinderMesh` r 0.16 h 0.14 on top | (0, 1.36, 0) / (0, 1.46, 0) | team | - | Head |
| 6 | Head-lamp | `SphereMesh` r 0.08 on the cap front | (0, 1.38, 0.28) | glow | 1.5 (the miner's lamp: the unit's one glow) | Head |
| 7 | Eye bar | dark bar | (0, 1.15, 0.22) | `(0.10, 0.08, 0.08)` | - | Head |
| 8 | Legs (2) + feet | `leg` r 0.10 h 0.30, `foot` | hips (+-0.15, 0.30, 0) | leather | - | LegL / LegR |
| 9 | Arms (2) + fists | `arm` r 0.09 h 0.32, `fist` r 0.11 | shoulders (+-0.36, 0.95, 0) | skin | - | ArmL / ArmR |
| 10 | Pick | shaft `CylinderMesh` r 0.04 h 1.1; head `BoxMesh` 0.55 x 0.12 x 0.12 with one end tapered (a second cone top r 0 bottom r 0.07 h 0.25) | in ArmR, resting on the shoulder at idle (shaft tilted 60° back) | wood `(0.30, 0.16, 0.08)` / bronze | - | ArmR |
| 11 | Basket | `CylinderMesh` top r 0.22 bottom r 0.16 h 0.34 | (0, 0.85, -0.36) on the back | leather | - | Chest |
| 12 | Crystals (carry) | `MultiMesh` 3 x octahedron (cones r 0.09 h 0.18 x2) poking out of the basket, **visible only while carrying** | (0, 1.05, -0.36) | `rune_glow` `(0.55, 0.85, 1.0)` (crystal colour of `economy.md` nodes) | 2.0 | Chest |
Parts: 12 meshes (MultiMesh 1) + shadow. Signature detail: **the glowing head-lamp** that swings when it walks.

### 4.2 Flame Guard (melee line). Height 1.6 m, radius 0.45
Concept: a squat, wide legionary behind a **tower shield shaped like a flame**, short heavy blade.
| # | Part | Primitive / size | Position | Colour | Emission | Node |
|---|---|---|---|---|---|---|
| 1 | Torso | `torso_v` top r 0.36 bottom r 0.26 h 0.55 | (0, 0.98, 0) | team plates | - | Chest |
| 2 | Chest plate | `BoxMesh` 0.52 x 0.36 x 0.16 | (0, 1.05, 0.22) | bronze | - | Chest |
| 3 | Pauldrons (2) | `pauldron` r 0.22 | (+-0.42, 1.24, 0) | bronze | - | Chest |
| 4 | Skirt (tassets) | `CylinderMesh` top r 0.28 bottom r 0.34 h 0.26, 6 seg | (0, 0.62, 0) | dark cloth | - | Hips |
| 5 | ~~Head~~ | **removed in review**: a r 0.26 sphere is wider than the 0.50 helm box and z-fights through its sides; the helm is the head | - | - | - | - |
| 6 | Helm | `helm_box` 0.50 x 0.44 x 0.50 + crest `BoxMesh` 0.10 x 0.30 x 0.52 on top | (0, 1.44, 0) / (0, 1.78, 0) | bronze / crest team | - | Head |
| 7 | Visor | `visor` | (0, 1.42, 0.26) | glow | 1.5 | Head |
| 8 | Legs (2) + feet | `leg` r 0.11 h 0.40, `foot` | (+-0.17, 0.35, 0) | leather / bronze feet | - | LegL / LegR |
| 9 | Arms (2) + fists | `arm`, `fist` | (+-0.44, 1.18, 0) | dark cloth / bronze fists | - | ArmL / ArmR |
| 10 | Tower shield | `BoxMesh` 0.62 x 0.95 x 0.10 with a `PrismMesh` 0.62 x 0.30 x 0.10 on top (the flame point) | in ArmL, held in front-left (-0.38, 0.85, 0.30), face +Z | team, bronze rim = a second box 0.66 x 0.99 x 0.06 behind it | flame glyph = `BoxMesh` 0.10 x 0.34 x 0.02 on the face, glow 1.5 | ArmL |
| 11 | Short sword | blade `BoxMesh` 0.18 x 0.75 x 0.05, guard `BoxMesh` 0.30 x 0.06 x 0.10, grip `CylinderMesh` r 0.04 h 0.18 | in ArmR, blade forward-down at idle (tilted 30°) | bronze blade `(0.75, 0.55, 0.25)`, `spec_strength 0.35` | - | ArmR |
Parts: 24 meshes incl. the blob (review count; the shield rim box is optional: drop it first if over budget). Signature detail: the
**flame-pointed shield**, twice as wide as the shoulders when raised.

### 4.3 Ember Archer (ranged). Height 1.6 m, radius 0.45
Concept: a lean scout in a hooded orange-gold coat with a **long recurve bow taller than herself** and a smouldering quiver.
| # | Part | Primitive / size | Position | Colour | Emission | Node |
|---|---|---|---|---|---|---|
| 1 | Coat | `CylinderMesh` top r 0.28 bottom r 0.34 h 0.80, 8 seg | (0, 0.75, 0) | secondary `(0.95, 0.55, 0.20)` | - | Chest |
| 2 | Sash | `TorusMesh` inner 0.28 outer 0.34, tilted 15° | (0, 0.95, 0) | team | - | Chest |
| 3 | Head | `head_s` r 0.23 | (0, 1.38, 0) | skin | - | Head |
| 4 | Hood | `CylinderMesh` top r 0.10 bottom r 0.32 h 0.40, 6 seg, tilted 15° back | (0, 1.50, -0.05) | dark cloth | - | Head |
| 5 | Eye bar | dark | (0, 1.38, 0.21) | - | - | Head |
| 6 | Legs (2) + feet | `leg` r 0.10 h 0.40, `foot` | (+-0.15, 0.35, 0) | leather | - | LegL / LegR |
| 7 | Arms (2) + fists | `arm`, `fist` | (+-0.36, 1.12, 0) | secondary / skin | - | ArmL / ArmR |
| 8 | Bow | 3 `CylinderMesh` r 0.035 (h 0.7 centre, h 0.6 upper tilted 30° forward, h 0.6 lower tilted 30° forward) making a 1.7 m tall recurve, tips `SphereMesh` r 0.06 | in ArmL, held vertical at (-0.40, 1.0, 0.30) | bronze-wood `(0.55, 0.30, 0.12)` | tips glow 1.5 | ArmL |
| 9 | Bowstring | `CylinderMesh` r 0.012 h 1.55 | between the tips | `(0.90, 0.85, 0.70)` | - | ArmL |
| 10 | Quiver | `CylinderMesh` r 0.10 h 0.50 tilted 25°, 4 arrow shafts `MultiMesh` `CylinderMesh` r 0.02 h 0.30 poking out | (0.20, 1.10, -0.30) on the back | leather / shafts glow | 1.5 (embers in the quiver) | Chest |
Parts: 13 (bow 3 cylinders + 2 tips = 5). Signature detail: **the bow height** and the arrows glowing in the quiver.
Draw: `play_attack()` pulls ArmR back to the ear in 0.15 s then releases (6.4, `attack_windup 0.15`). The bolt itself stays the gameplay projectile.

### 4.4 Blaze Rider (cavalry): rider + mount. Height 1.9 m (rider head top), radius 0.6
Concept: a whooping lancer on a **flame-maned war boar**: low, long, wide; the mane is fire.
Mount (node `Mount`, under `Root`), body length 1.6 m along z:
| # | Part | Primitive / size | Position | Colour | Emission | Node |
|---|---|---|---|---|---|---|
| 1 | Boar body | `CapsuleMesh` r 0.36 h 1.5, rotated 90° (along z) | (0, 0.62, 0) | fur `(0.35, 0.16, 0.08)` | - | Mount |
| 2 | Boar head | `BoxMesh` 0.44 x 0.40 x 0.55 + snout `CylinderMesh` r 0.14 h 0.20 (along z) | (0, 0.68, 0.85) / (0, 0.62, 1.15) | fur / dark `(0.20, 0.10, 0.06)` | - | Mount/Head |
| 3 | Tusks (2) | cones top r 0 bottom r 0.06 h 0.28, tilted 40° up-out | (+-0.16, 0.55, 1.08) | bone `(0.90, 0.85, 0.70)` | - | Mount/Head |
| 4 | Eyes | `visor` bar | (0, 0.76, 1.12) | glow | 1.5 | Mount/Head |
| 5 | Legs (4) | `CylinderMesh` r 0.10 h 0.45 + hoof `BoxMesh` 0.20 x 0.10 x 0.22 | (+-0.24, 0.25, +-0.50) | dark fur | - | LegFL... LegBR |
| 6 | Mane (fire) | `MultiMesh` 7 x cone (top r 0 bottom r 0.10 h 0.32), along the spine from z 0.6 to -0.4, tilted 20° back, alternating +-8° sideways | y 1.02 | `rune_glow` `(1.0, 0.55, 0.15)` | **2.5**, `pulse_speed 6` | Mount |
| 7 | Mane particles | `GPUParticles3D` 10, lifetime 0.5, box 0.2 x 0.1 x 1.0 on the spine, up 1.0, size 0.18 -> 0.05, fire ramp, ADD | (0, 1.05, 0.1) | - | - | Fx |
| 8 | Saddle | `BoxMesh` 0.44 x 0.12 x 0.50 | (0, 1.02, -0.05) | leather | - | Mount |
Rider (nodes `Chest`, `Head`, `ArmL`, `ArmR`, seated: no `LegL/LegR` pivots; legs are 2 static capsules hugging the boar):
| 9 | Torso | `torso_v` scaled 0.85 | (0, 1.35, -0.05) | team | - | Chest |
| 10 | Pauldrons (2) | `pauldron` r 0.18 | (+-0.36, 1.55, -0.05) | bronze | - | Chest |
| 11 | Rider legs (2) | `CapsuleMesh` r 0.09 h 0.45 tilted 35° forward-down along the boar's flanks | (+-0.34, 1.0, 0.15) | dark cloth | - | Chest |
| 12 | Head + helm | `head_m` + open helm `CylinderMesh` r 0.28 h 0.24 with 2 cones (top r 0 bottom r 0.06 h 0.30) as horns tilted 45° back | (0, 1.78, -0.05) | skin / bronze | visor glow 1.5 | Head |
| 13 | Arms + fists | `arm`, `fist` | (+-0.38, 1.50, -0.05) | secondary `(0.95, 0.40, 0.05)` / bronze | - | ArmL / ArmR |
| 14 | Lance | `CylinderMesh` r 0.04 h 2.0, tip cone top r 0 bottom r 0.08 h 0.30, pennon `PlaneMesh` 0.35 x 0.20 (`banner.gdshader`) near the tip | in ArmR, pointing forward-up 20° at idle, level at charge | wood / bronze tip / pennon team | tip glow 1.5 | ArmR |
| 15 | Small round shield | `CylinderMesh` r 0.28 h 0.06, face -X | (-0.50, 1.40, -0.05) | team + bronze boss `SphereMesh` r 0.08 | - | ArmL |
Parts: 8 mount (MultiMesh 1, legs 4) + 9 rider = 17, + 1 particle system. Signature detail: **the burning mane**, the only unit
with an always-on particle system (10 particles; the model's distance tier stops it beyond 45 m, 6.10).

### 4.5 Ash Hurler (artillery). Height 1.6 m, radius 0.45
Concept: a hunched, soot-black engineer with a **tall staff-sling** and a smoking **ash pot** on the back, the tallest
silhouette of the Fire line (pole to 2.5 m, thin).
| # | Part | Primitive / size | Position | Colour | Emission | Node |
|---|---|---|---|---|---|---|
| 1 | Body | `torso_bell` top r 0.24 bottom r 0.36 h 0.62 | (0, 0.78, 0) | secondary `(0.60, 0.35, 0.25)` | - | Chest |
| 2 | Leather harness | 2 x `BoxMesh` 0.08 x 0.60 x 0.06 crossed on the chest (rotated +-30°) | (0, 0.95, 0.30) | leather | - | Chest |
| 3 | Head | `head_s` r 0.22 | (0, 1.32, 0.05) (leaning forward) | skin, soot-dark tint via `damage 0.3` | - | Head |
| 4 | Goggles | `BoxMesh` 0.26 x 0.10 x 0.10 | (0, 1.35, 0.24) | glow (two round lenses read as one bar) | 1.5 | Head |
| 5 | Scarf | `TorusMesh` inner 0.20 outer 0.30 | (0, 1.14, 0) | team | - | Head |
| 6 | Legs (2) + feet | `leg`, `foot` | (+-0.16, 0.32, 0) | leather | - | LegL / LegR |
| 7 | Arms (2) + fists | `arm`, `fist` (gloved, bronze) | (+-0.38, 1.05, 0) | secondary / bronze | - | ArmL / ArmR |
| 8 | Sling pole | `CylinderMesh` r 0.04 h 2.2, with a `TorusMesh` inner 0.12 outer 0.16 at the top (the sling loop) | in ArmR, vertical, at (0.40, 1.25, 0.10) | wood / bronze loop | - | ArmR |
| 9 | Ash ball (loaded) | `SphereMesh` r 0.16 in the loop, **visible until the throw** | (0.40, 2.30, 0.10) | `(0.30, 0.28, 0.26)` with `crack_strength 0.8`, `crack_color` glow (an ember inside) | cracks 2.0 | ArmR |
| 10 | Ash pot | `CylinderMesh` top r 0.22 bottom r 0.18 h 0.42 + lid `CylinderMesh` r 0.24 h 0.06 | (0, 1.05, -0.36) | bronze / dark | rim glow ring `TorusMesh` inner 0.18 outer 0.22 at the lid, 1.5 | Chest |
| 11 | Pot smoke | `GPUParticles3D` 6, lifetime 2.0, up 0.5, size 0.25 -> 0.6, `(0.28, 0.22, 0.20)` alpha 0.3 -> 0, MIX | (0, 1.32, -0.36) | - | - | Fx |
Parts: 13 + 1 particle system (6, hidden beyond zoom 45). Signature detail: the **loaded ash ball cracking with ember light**
at the top of the pole; it vanishes on the throw and reappears 0.6 s later (a reload).

---

## 5. Shadow army + Ruin Warden (4.V3)
All Shadow soldiers: cloth = team `(0.42, 0.22, 0.60)`, dark cloth `(0.18, 0.08, 0.28)`, tarnished silver metal, ashen skin
`(0.62, 0.60, 0.70)`, leather `(0.12, 0.09, 0.16)`, glow `(0.70, 0.30, 1.00)`. Shadow units are **thinner and taller-looking**
than Fire ones at the same height: torsos scaled x 0.85 on x/z, heads 0.9, pauldrons replaced by spikes.

### 5.1 Gloom Thrall (worker). Height 1.4 m, radius 0.4
Concept: a hunched, hooded drudge dragging a **soul-lantern on a pole**; crystals float in a cage behind it.
| # | Part | Primitive / size | Position | Colour | Emission | Node |
|---|---|---|---|---|---|---|
| 1 | Body (hunched robe) | `torso_bell` top r 0.20 bottom r 0.34 h 0.60, tilted 12° forward | (0, 0.60, 0.04) | secondary `(0.50, 0.45, 0.55)` | - | Chest |
| 2 | Rope belt | `TorusMesh` inner 0.26 outer 0.30 | (0, 0.48, 0) | dark cloth | - | Hips |
| 3 | Head | `head_s` r 0.21 | (0, 1.08, 0.12) (thrust forward) | ashen skin | - | Head |
| 4 | Hood | `CylinderMesh` top r 0.06 bottom r 0.30 h 0.36, 6 seg, tilted 25° forward | (0, 1.22, 0.06) | dark cloth | - | Head |
| 5 | Eye bar | `visor` | (0, 1.08, 0.30) | glow | 1.5 | Head |
| 6 | Legs (2) + feet | `leg` r 0.09 h 0.30, `foot` | (+-0.14, 0.28, 0) | leather | - | LegL / LegR |
| 7 | Arms (2) + hands | `arm` r 0.08 h 0.34, `fist` r 0.10 | (+-0.32, 0.92, 0.04) | secondary / ashen | - | ArmL / ArmR |
| 8 | Lantern pole | `CylinderMesh` r 0.035 h 1.5, tilted 20° forward over the shoulder | in ArmR, (0.36, 1.0, 0.1) | iron `(0.10, 0.08, 0.14)` | - | ArmR |
| 9 | Soul lantern | `BoxMesh` 0.18 x 0.24 x 0.18 frame + `SphereMesh` r 0.08 inside | hanging at the pole tip (0.36, 1.90, 0.55) | silver frame / glow orb | 2.0, pulse 2.5 s (the unit's one glow) | ArmR |
| 10 | Crystal cage (carry) | `MultiMesh` 3 octahedra (r 0.09) **floating** behind the back, visible only while carrying, slow spin 60°/s | (0, 1.10, -0.40) | `rune_glow` `(0.55, 0.85, 1.0)` | 2.0 | Chest |
Parts: 10 + shadow. Signature detail: the **swinging soul lantern** (pendulum +-10° at the walk rate).

### 5.2 Shade (melee line). Height 1.6 m, radius 0.45
Concept: a lithe assassin wrapped in violet bandages, **two curved blades held low**, a tattered half-cape; no shield.
| # | Part | Primitive / size | Position | Colour | Emission | Node |
|---|---|---|---|---|---|---|
| 1 | Torso | `torso_v` scaled (0.85, 1.0, 0.85) | (0, 0.98, 0) | team | - | Chest |
| 2 | Bandage bands | 3 x `TorusMesh` inner 0.24 outer 0.30, tilted 10° alternating | y 0.85 / 1.00 / 1.15 | dark cloth | - | Chest |
| 3 | Shoulder spikes (2) | cones top r 0 bottom r 0.09 h 0.32, tilted 40° outward | (+-0.36, 1.32, 0) | silver | - | Chest |
| 4 | Half-cape | `cape` 0.5 x 0.8 hanging from the **left** shoulder | (-0.20, 0.85, -0.25) | `banner.gdshader` Dusk values, no glyph | - | Chest |
| 5 | Head | `head_m` scaled 0.9 | (0, 1.40, 0) | ashen | - | Head |
| 6 | Face wrap + mask | `CylinderMesh` r 0.25 h 0.20 (wrap) + `visor` | (0, 1.36, 0) / (0, 1.42, 0.23) | dark cloth / glow | 1.5 | Head |
| 7 | Legs (2) + feet | `leg`, `foot` | (+-0.15, 0.35, 0) | leather | - | LegL / LegR |
| 8 | Arms (2) + fists | `arm`, `fist` | (+-0.38, 1.18, 0) | dark cloth / silver | - | ArmL / ArmR |
| 9 | Curved blades (2) | blade `BoxMesh` 0.14 x 0.70 x 0.04 **bent**: two boxes h 0.35 joined at 25°; grip `CylinderMesh` r 0.035 h 0.16 | one per arm, held blade-down and back at idle (reverse grip, tilt -40°) | silver, `spec_strength 0.4`, edge line `BoxMesh` 0.02 x 0.60 x 0.05 glow | edge 1.5 (one blade only; the other is plain: "1-2 glows" rule) | ArmL / ArmR |
Parts: 14. Signature detail: **reverse-grip double blades**, tips nearly touching the ground at idle.

### 5.3 Nightbolt (ranged). Height 1.6 m, radius 0.45
Concept: a stiff, cloaked marksman holding a **flat dusk-caster** (a heavy crossbow-like frame) level at the hip; a
tall collar and a rune-lit bolt in the groove.
| # | Part | Primitive / size | Position | Colour | Emission | Node |
|---|---|---|---|---|---|---|
| 1 | Coat | `CylinderMesh` top r 0.26 bottom r 0.32 h 0.85, 8 seg | (0, 0.75, 0) | secondary `(0.55, 0.30, 0.70)` | - | Chest |
| 2 | Collar | `CylinderMesh` top r 0.36 bottom r 0.28 h 0.24 | (0, 1.28, -0.04) | dark cloth | - | Chest |
| 3 | Head | `head_s` r 0.22 | (0, 1.40, 0) | ashen | - | Head |
| 4 | Wide hat | `CylinderMesh` r 0.42 h 0.06 brim + `CylinderMesh` top r 0.18 bottom r 0.22 h 0.24 crown | (0, 1.58, 0) / (0, 1.72, 0) | dark cloth, silver band `TorusMesh` inner 0.20 outer 0.24 at y 1.63 | - | Head |
| 5 | Eye bar | `visor` | (0, 1.40, 0.21) | glow | 1.5 | Head |
| 6 | Legs (2) + feet | `leg`, `foot` | (+-0.15, 0.35, 0) | leather | - | LegL / LegR |
| 7 | Arms (2) + fists | `arm`, `fist` | (+-0.36, 1.12, 0) | secondary / silver gloves | - | ArmL / ArmR |
| 8 | Dusk-caster frame | stock `BoxMesh` 0.10 x 0.12 x 0.90 (along z) + bow-arm `BoxMesh` 0.90 x 0.06 x 0.08 (along x) at the front + 2 tip cones | in ArmR, held level at (0.15, 1.0, 0.35), ArmL supports the front | iron / silver arms | - | ArmR |
| 9 | Loaded bolt | `CylinderMesh` r 0.025 h 0.70 in the groove | (0.15, 1.05, 0.40) | `rune_glow` `(0.7, 0.4, 1.0)` | 2.0, hidden 0.12 s after `play_attack()` (= its `attack_windup`) then back at 0.50 s (reload) | ArmR |
| 10 | Bolt quiver | `BoxMesh` 0.16 x 0.40 x 0.10 on the back, 3 bolt stubs | (0.18, 1.0, -0.28) | leather / glow stubs | 1.5 | Chest |
Parts: 13. Signature detail: the **level, sideways dusk-caster** (a horizontal 0.9 m bar in the silhouette).

### 5.4 Grave Hound (fast harasser). Height 1.0 m, radius 0.4, quadruped
Concept: a skeletal, low **bone-and-shadow hound**, spine spikes, a violet flame where the head should glow.
| # | Part | Primitive / size | Position | Colour | Emission | Node |
|---|---|---|---|---|---|---|
| 1 | Body | `CapsuleMesh` r 0.22 h 1.1 along z | (0, 0.55, 0) | leather-dark `(0.12, 0.09, 0.16)` | - | Root |
| 2 | Rib cage | `MultiMesh` 4 x `TorusMesh` inner 0.20 outer 0.26 around the body, spaced 0.16 along z from z 0.05 to -0.43 | y 0.55 | bone `(0.80, 0.78, 0.70)` | - | Root |
| 3 | Spine spikes | `MultiMesh` 5 x cone (top r 0 bottom r 0.06 h 0.22) tilted 30° back | along the spine y 0.80, z 0.3 to -0.5 | bone | - | Root |
| 4 | Head | `BoxMesh` 0.30 x 0.26 x 0.45 + jaw `BoxMesh` 0.26 x 0.08 x 0.34 (pivot at the back, opens 25° on attack) | (0, 0.70, 0.70) / (0, 0.56, 0.72) | bone | - | Mount/Head |
| 5 | Eye flame | `visor` bar + `SphereMesh` r 0.07 between the ribs (the "heart") | (0, 0.74, 0.92) / (0, 0.55, -0.10) | glow | 1.5 / 2.0 | Head / Root |
| 6 | Legs (4) | `CapsuleMesh` r 0.07 h 0.42, tilted 15° | (+-0.18, 0.28, +-0.38) | bone | - | LegFL... LegBR |
| 7 | Tail | `CylinderMesh` top r 0.02 bottom r 0.06 h 0.50 tilted 35° up-back | (0, 0.70, -0.75) | bone | - | Root |
Parts: 9 (2 MultiMesh, legs 4). Signature detail: the **glowing heart between the ribs**.

### 5.5 Shadow Knight (heavy elite). Height 2.4 m, radius 0.7
Concept: a towering, black-armoured **horned juggernaut** with a two-handed great sword and a long, tattered cape;
the biggest and most decorated soldier (wizard-level part count).
| # | Part | Primitive / size | Position | Colour | Emission | Node |
|---|---|---|---|---|---|---|
| 1 | Torso | `torso_v` scaled 1.5: top r 0.51 bottom r 0.36 h 0.82 | (0, 1.45, 0) | team plates | - | Chest |
| 2 | Chest plate | `BoxMesh` 0.80 x 0.55 x 0.22 with a `PrismMesh` 0.80 x 0.25 x 0.22 on top (pointed gorget) | (0, 1.55, 0.30) | obsidian `(0.09, 0.07, 0.13)` `spec_strength 0.3` | rune line `BoxMesh` 0.06 x 0.50 x 0.02 on the front, glow 2.0 | Chest |
| 3 | Pauldrons (2) | `pauldron` r 0.30 + one spike each (cone r 0.08 h 0.45, tilted 35° outward) | (+-0.62, 1.85, 0) | obsidian / silver spikes | - | Chest |
| 4 | Tassets | `CylinderMesh` top r 0.40 bottom r 0.50 h 0.40, 6 seg | (0, 0.92, 0) | dark cloth | - | Hips |
| 5 | Cape | `cape` 1.0 x 1.8, top at y 2.0, z -0.42 | (0, 1.10, -0.45) | `banner.gdshader` Dusk values, diamond glyph | 0.6 | Chest |
| 6 | ~~Head~~ | **removed in review** (hidden inside the helm: a wasted mesh) | - | - | - | - |
| 7 | Great helm | `helm_box` scaled 1.3 (0.65 x 0.57 x 0.65) | (0, 2.12, 0) | obsidian | - | Head |
| 8 | Horns (2) | cones top r 0 bottom r 0.10 h 0.60, tilted 50° outward, curving = a second cone h 0.30 tilted 30° more | (+-0.30, 2.45, 0) | silver | - | Head |
| 9 | Visor | `visor` scaled 1.4 | (0, 2.10, 0.34) | glow | **2.0** | Head |
| 10 | Legs (2) + feet | `leg` scaled 1.5 (r 0.16 h 0.60), `foot` scaled 1.5 | (+-0.26, 0.50, 0) | obsidian / silver | - | LegL / LegR |
| 11 | Arms (2) + fists | `arm` scaled 1.5, `fist` r 0.17 | (+-0.66, 1.75, 0) | obsidian / silver | - | ArmL / ArmR |
| 12 | Great sword | blade `BoxMesh` 0.26 x 1.70 x 0.06, fuller `BoxMesh` 0.06 x 1.30 x 0.07 glow, guard `BoxMesh` 0.60 x 0.08 x 0.14, grip `CylinderMesh` r 0.05 h 0.40, pommel `SphereMesh` r 0.09 | in ArmR, **resting on the shoulder** at idle (tilted 35° back), ArmL joins the grip | silver blade / obsidian grip | fuller **3.0** (the elite's halo) | ArmR |
Parts: 29 meshes before the merge incl. the blob (review count; within the 30 budget of section 8, the merge brings it
to ~12 draw instances). Sword guard + grip + pommel may be one `BoxMesh` 0.60 x 0.08 x 0.14 plus the grip if time is short.
Signature detail: **the great sword resting on the shoulder** with its glowing fuller: a 1.7 m vertical light bar.

### 5.6 Ruin Warden (neutral camp guard). Height 1.8 m, radius 0.5
Concept: a squat **stone golem** of mossy ruin blocks held together by amber light, eyes of the old god's gold; no cloth,
no team colour (`set_team_color` is a no-op on it).
| # | Part | Primitive / size | Position | Colour | Emission | Node |
|---|---|---|---|---|---|---|
| 1 | Torso | `BoxMesh` 0.80 x 0.70 x 0.55, tilted 8° forward | (0, 1.05, 0) | stone `(0.45, 0.50, 0.40)`, `crack_strength 0.6`, `crack_color (1.0, 0.85, 0.3)` | cracks 2.0 | Chest |
| 2 | Moss cap | `BoxMesh` 0.84 x 0.12 x 0.60 on top of the torso | (0, 1.45, 0) | moss `(0.35, 0.50, 0.30)` | - | Chest |
| 3 | Shoulder blocks (2) | `BoxMesh` 0.36 x 0.36 x 0.36, tilted 12° | (+-0.58, 1.40, 0) | dark stone `(0.28, 0.32, 0.26)` | - | Chest |
| 4 | Head | `BoxMesh` 0.40 x 0.34 x 0.38, sunk into the torso | (0, 1.66, 0.05) | stone | - | Head |
| 5 | Eyes | `visor` bar 0.26 x 0.08 x 0.06 | (0, 1.68, 0.25) | `(1.0, 0.85, 0.3)` | **2.0** | Head |
| 6 | Legs (2) + feet | `BoxMesh` 0.26 x 0.50 x 0.30 + `foot` scaled 1.3 | (+-0.24, 0.35, 0) | dark stone | - | LegL / LegR |
| 7 | Arms (2) + fists | `BoxMesh` 0.22 x 0.55 x 0.22 + `fist` r 0.16 | (+-0.66, 1.15, 0) | stone / dark stone fists | - | ArmL / ArmR |
| 8 | Ruin mace | `CylinderMesh` r 0.05 h 1.1 + head `BoxMesh` 0.34 x 0.34 x 0.34 (a broken capital) | in ArmR, head-down at idle | dark stone, moss on top | - | ArmR |
| 9 | Floating gap | the head hovers 0.06 m above the torso (no neck); bobs +-0.02 m | - | - | amber light `SphereMesh` r 0.06 in the gap, glow 1.5 | Head |
| 10 | Amber motes | `GPUParticles3D` 6, lifetime 2.0, rising 0.3 m/s from the cracks, size 0.05, ADD | (0, 1.0, 0) | `(1.0, 0.85, 0.3)` | - | Fx |
Parts: 13 + 1 particle system. Signature detail: the **hovering head with amber light in the gap**.

---

## 6. Animation (no skeleton: 7-12 `Node3D` pivots driven by one shared script `art/units/unit_model.gd`)

### 6.1 Hooks on the model scene root (the gameplay coder calls them, 4.G2; safe before `_ready`: cache and apply)
| Hook | Who calls it | When | What the model does |
|---|---|---|---|
| `set_team_color(c: Color)` | `Unit._build_visual` right after `instantiate()` (the model is a child of `_visual`) | once | 2.2: `c` = kingdom colour from `unit_type.faction` (wizards: Fire / Shadow by class); no-op when it matches, no-op on the warden |
| `set_moving(speed: float)` | `Unit._on_velocity_computed` (flat speed after `move_and_slide`), **only when it changes by > 0.3 m/s or crosses 0.3** (hysteresis, no per-frame calls); `set_moving(0)` in `die()` | each change | < 0.3 = idle; else walk at rate `speed / stride_speed` where `stride_speed` = the type's base `move_speed` read once at spawn (haste simply gives a higher rate) |
| `play_attack()` | `Unit._perform_attack`, **both branches**, at the moment the cooldown restarts. Melee branch: call it **instead of** `_lunge()` when the model has the hook (damage stays instant). Ranged branch: see `attack_windup` below | each attack | 6.4 (`attack_style`) |
| `attack_windup: float` (an `@export` read once by `Unit._build_visual`, 0 if absent, clamped to **<= 0.15 s**) | Owner: `scripts/units/unit.gd` (4.G2). Ranged branch only: `play_attack()` now, the `Projectile` spawns after `attack_windup` through a per-unit countdown in `_physics_process` (no `Timer`, no `await`); dropped if the unit dies or the target is gone. `_cooldown_left` still starts at the trigger, so DPS is unchanged; only the first bolt of a fight lands <= 0.15 s later | - | Release frame of 6.4 = `attack_windup` |
| `play_cast(spell_id: StringName)` | 4.G2 connects the existing `Wizard.spell_cast(spell_id)` signal (emitted when mana and cooldown are paid) in `Wizard._build_visual`. Ids: `fireball`, `ember_step`, `kindle`, `shadow_lance`, `soul_siphon`, `umbral_shroud` | each cast | 6.5 |
| `play_hit()` | `Unit.take_damage` next to `_hit_flash = 1.0`. Nothing to skip: `_update_hit_flash` already returns when `_body_mat == null` (always the case with a model). Only when `amount > 0` | each hit | 6.6; ignores calls < 0.15 s apart (DoT ticks, multi-hits) |
| `play_death()` + signal `death_finished` | `Unit.die()` **instead of** the `_visual` flatten tween. `Unit` connects `death_finished` (one-shot) to `_on_death_finished`; fallback `get_tree().create_timer(2.0)` to the same method; a `_death_done` bool makes it run **once** (queue_free, or the wizard hide) | once | 6.7 |
| `play_level_up()` | Soldiers: `Unit._set_veterancy_level` (next to `_gold_flash`, which is already inert with a model). Wizards: their `level_changed` (levels 2-8) | each level | 6.8 |
| `set_veterancy(level: int)` | Soldiers only, right after `play_level_up()` (1-4). **Never on wizards** (their 1-8 scale has no accents) | each level | 7.1 |
| `set_carrying(on: bool)` | `Worker._update_carry_visual` (`carried > 0`); with a model the worker does not build its own `_carry_visual` crystal | each change | 6.9 |
| `play_mine()` | `Worker._try_start_mining` when `begin_mining` succeeds (`MINE_TIME` = 4.0 s) | each cycle | 6.9 |
| `set_status(id: StringName, on: bool) -> bool` | `Unit._add_mark` / `_remove_mark` callers (`apply_status`, `_end_status`, `apply_dot`, DoT end): call the model first; **if it returns true, skip the placeholder sphere** | each change | 7.2. Handles `haste`, `shroud` (returns true); returns false for anything else (`smoulder`, `burn`), so those keep their marks |
| `revive()` | `Wizard.respawn` after `_revive` (which already resets `_visual` scale / position) | once | Resets every pivot, scale, visibility and instance uniform to idle in 0 s; stops death motion |
`Unit` keeps owning: facing (`_visual.rotation.y`), the selection ring, the HP bar, the chevrons `Label3D`, the shadow
casting of the sun, the `_visual` position (lunge on placeholders only). The model never moves its own root transform
(only children of `Root`). Every hook is called with `has_method` checks so placeholder units keep working; calls
before `_ready` are cached and applied in `_ready`.

### 6.2 Idle (looping, phase offset per unit = `hash(get_instance_id()) % 100 / 100.0 x period` so a line never breathes in sync)
| Unit type | Motion | Period |
|---|---|---|
| Bipeds | `Root.position.y = 0.02 x sin(t)` (breath), `Chest.rotation.x = 1.5° x sin(t)`, `Head.rotation.y = 4° x sin(0.5 t + 1)` (looks around) | 3.0 s |
| Wizards | + orb / shard bob +-0.04 m (2 s), Vessa crown flames flicker `scale 1.0 + 0.1 x noise(8 t)`, cape wave (shader), staff sways `ArmR.rotation.z = 2° x sin(0.7 t)` | 3.0 s |
| Hound | `Root.position.y = 0.03 x sin(t)`, head bob `Head.rotation.x = 5° x sin(1.3 t)`, tail wag `rotation.y = 15° x sin(2.5 t)` | 2.0 s |
| Rider | mount breath scale y 1.0 <-> 1.03 (2.2 s), head toss every 4-7 s (`rotation.x` -15° over 0.3 s, back 0.4 s), mane pulse (shader) | 2.2 s |
| Warden | `Head.position.y` bob +-0.02 (4 s), nothing else (stone) | 4.0 s |

### 6.3 Walk cycle (rate 1.0 = one stride per **0.55 s** for bipeds, 0.40 s hound, 0.45 s rider gallop; scaled by `speed / move_speed`)
| Pivot | Bipeds (angles in degrees, `p` = cycle phase 0-1) | Hound / Mount |
|---|---|---|
| LegL / LegR | `rotation.x = 28° x sin(2π p)` and `-28° x sin(2π p)` (opposite) | 4 legs: FL and BR `+32° x sin`, FR and BL `-32° x sin` (trot); rider mount at rate >= 1.3: FL+FR together, BL+BR together `+-38°` (gallop) |
| ArmL / ArmR | opposite to the legs, `18° x sin(2π p)`; the weapon arm keeps its idle pose **plus** `8°` (heavy weapons barely swing) | - |
| Root.position.y | `0.04 x abs(sin(2π p))` (bounce twice per stride); hound 0.06; mount 0.08 at gallop | |
| Chest.rotation.z | `3° x sin(2π p)` (sway) | mount `Root.rotation.x = 4° x sin(2π p)` (pitching) |
| Rider | seated: `Chest.position.y` follows the mount bounce; `Chest.rotation.x = -6°` leaning forward at gallop | |
| Warden | stride 0.80 s, legs +-18°, `Root.position.y` 0.06 bounce, a **stomp**: `Root.position.y` drops sharply at p = 0.5 (`ease in` 0.1 s) | |
Transitions idle <-> walk blend over **0.15 s** (lerp the pivot angles toward the target each frame: cheap, one lerp per pivot).
Turning is gameplay's `lerp_angle` (0.25 / frame); the model does not animate turns.

### 6.4 Attack (`play_attack()`; `attack_style` per scene). Re-trigger restarts. Timelines are evaluated in the model's
`_process` from one `_action_t` timer and the table below (no `Tween` per attack). Melee damage is instant at the trigger,
so every **strike frame is <= 0.12 s**; ranged **release frame = `attack_windup` <= 0.15 s** (D2). If an attack is
longer than the unit's current `attack_cooldown` (items can cut it to 40 %), the next trigger simply restarts it.
| Style | Units | Timeline (`attack_windup`) |
|---|---|---|
| `melee_swing` | Flame Guard, Ruin Warden | 0-0.06 s: ArmR `rotation.x` 0 -> **-140°** (wind-up, overhead), Chest `rotation.y` +15° · 0.06-0.12: ArmR -> **-35°** (chop down in front, ease-out), Chest -25°, `Root.position.z` +0.25 (replaces `_lunge`) · 0.12-0.40: back to idle. Warden: same timings, `swing_scale` 1.15 (0). (4.V4: negative arm `rotation.x` swings toward +Z; the old -70 / +55 struck behind) |
| `dual_slash` | Shade | reverse-grip blades: ArmR +50° (blade back) -> -85° (blade forward-down) 0-0.12 s, then ArmL the same 0.10-0.22 s (two cuts), Chest twists +-20°; total 0.45 s (0) |
| `great_swing` | Shadow Knight | 0-0.08 s: sword snaps off the shoulder over the head (ArmR `rotation.x` -25°, ArmL follows x0.8) · 0.08-0.14: **overhead chop** to +160° (the sword rests UP from the fist, so a positive arm brings the blade over the shoulder to the front), `Root.position.y` -0.08, restart the pre-built 12-particle purple spark emitter at the blade tip · 0.14-0.9: slow recovery (the weight reads in the recovery, not the wind-up) (0) |
| `lance_charge` | Blaze Rider | 0-0.06 s: lance from +20° to **0° (level)** · 0.06-0.12 thrust `ArmR.position.z` +0.35, mount `Head.rotation.x` +15° · 0.12-0.55 back (0) |
| `bow_draw` | Ember Archer | 0-0.15 s: ArmR pulls to the ear (`rotation.x` -35°, `position.z` -0.30), Chest turns -20°, the drawn-string mesh (2 thin boxes as a "V", `keep_separate`) replaces the straight string · 0.15: **release**, straight string back · 0.15-0.45: ArmR returns (**0.15**) |
| `caster_fire` | Nightbolt | 0-0.12 s: frame lifts to shoulder height (ArmR `rotation.x` -25°) · 0.12: **release**, loaded bolt hidden, 6-particle purple puff (pre-built emitter), `Root.position.z` -0.06 (recoil) · 0.12-0.50: back; bolt reappears at 0.50 (**0.12**) |
| `sling_throw` | Ash Hurler | 0-0.15 s: pole (up from the fist) cocks back, ArmR `rotation.x` 0 -> -110° at 0.09 s, then whips over the head toward +60° at 0.25 s · 0.15: **release** (mid-whip), ash ball hidden, Root leans +10° · 0.15-0.7: follow-through and back; ball reappears at 0.8 (**0.15**) |
| `bite` | Grave Hound | 0-0.06 s: `Root.position.z` +0.30, jaw opens 25° · 0.06-0.12: jaw snaps shut, Head `rotation.x` -20° -> +10° · 0.12-0.40: back (0) |
| `wizard_bolt` | Vessa / Malrik **auto-attack** (not spells) | 0-0.12 s: ArmR staff raised 30°, orb `glow_boost` 1.6 · 0.12: **release** · 0.12-0.45: back. No lunge (**0.12**) |
| `worker_pick` | Cinder Hand / Gloom Thrall when fighting | melee_swing timings; the pick / pole rests UP from the fist, so ArmR -30° (head cocked back) -> **+125°** (head over the shoulder to the front) (0) |

### 6.5 Cast (wizards, `play_cast(spell_id)`; the spell VFX of `art/vfx/spell_vfx.gd` stay as they are; this is the body only)
| Spell | Vessa | Malrik |
|---|---|---|
"boost" below always means the **instance uniform `glow_boost`** on that part (never the material's `boost`: the
material is shared). Light energy is per node, fine to animate.
| Spell id | Vessa | Malrik |
|---|---|---|
| `fireball` / `shadow_lance` | 0-0.20 s: both arms rise (ArmL + ArmR `rotation.x` -80°), staff vertical, orb boost 1 -> **3** and light energy 1.2 -> 3.0 (a bloom flash), crown flames scale 1.5 · 0.20-0.35: ArmR **thrusts** the staff forward (`rotation.x` -30°, `position.z` +0.25) · 0.35-0.8: back, boost eases to 1 | 0-0.20 s: the shard drops into the claw (`position.y` -0.10), spins 400°/s, core boost 3, light 1.0 -> 2.5 · 0.20-0.35: staff thrust, shard springs 0.15 m up · 0.35-0.8 back |
| `ember_step` / `soul_siphon` | 0-0.15 s: staff slams down (ArmR `rotation.x` +25°, `Root.position.y` -0.06), orb boost 3 · 0.15-0.5 back; the fade-out / in is `spell_vfx` `_set_body_alpha` (7.4) | 0-0.30 s: both arms spread wide (ArmL / ArmR `rotation.x` -60°, `rotation.z` +-40°), shard rises 0.25 m · 0.30-0.8 back (no cape change: the cape material is shared) |
| `kindle` / `umbral_shroud` | 0-0.30 s: staff raised overhead (ArmR -150°), crown flames scale 1.8 and boost 3 for 0.6 s, Head `rotation.x` -15° (looks up) · 0.30-0.9 back | 0-0.25 s: Malrik hunches (Chest `rotation.x` +20°), arms cross over the chest (ArmL / ArmR `rotation.y` +-45°), mitre gem boost 3 · 0.25-0.9 back |
Unknown spell ids play the first row. Casting while walking is allowed: the arms play over the leg cycle (arms leave
the walk for the cast, <= 0.9 s).

### 6.6 Hit flinch (`play_hit()`; 0.22 s; ignored if a death is playing; re-trigger restarts)
`Chest.rotation.x` -> **-12°** (bipeds) / `Root.position.z -0.10` (hound, mount, warden) over 0.06 s, back over 0.16 s, plus a
**white flash** on the merged `Chest`, `Head` and `ArmR` instances (2.3; 3 calls). Materials are shared per kingdom (2.2),
so the flash cannot touch a material: `painted.gdshader` gains two instance uniforms (2.4), `hit_flash` and
`flash_color` (default white), with `EMISSION += flash_color * hit_flash * 2.0`; the model sets `hit_flash` 1.0 -> 0
over 0.12 s with `set_instance_shader_parameter` on those instances. No material duplication, ever.
The same uniforms in gold `(1.0, 0.85, 0.4)` serve the level-up flash (6.8).

### 6.7 Death (`play_death()`; emits `death_finished` at the end; the unit is freed / hidden right after)
Three generic styles coded once in `unit_model.gd` (`death_style` export, 2.4); no shader change (a `discard`-based
dissolve in `painted` would cost the keeps too, so it was removed in review). Every death is **~1.0 s** (D1).
| `death_style` | Units | Sequence | Length |
|---|---|---|---|
| `fall` | Fire soldiers, Vessa, Blaze Rider | 0-0.25 s: Chest `rotation.x` +35° (buckles), legs +40°, `Root.position.y` -0.25 · 0.25-0.55: `Root.rotation.x` -> **+80°** (falls face down toward +Z, ease-in), ArmR +60° (flop), glows' `glow_boost` -> 0, restart the pre-built 12-ember emitter · 0.55-1.0: `Root.position.y` -> **-0.6 x body_height** (sinks into the ground, ease-in) · 1.0: `death_finished`. Rider: the mount rolls instead (`Root.rotation.z` +70°), same timings | 1.0 s |
| `sink` | Shadow soldiers, hound, knight, Malrik | 0-0.25 s: buckle as above (hound: legs `rotation.z` +-40°) · 0.25-1.0: **sinks straight down** into its shadow, `Root.position.y` -> -1.0 x `body_height`, `scale` 1 -> 0.8, glows off at 0.4 s, restart the pre-built 16-mote purple emitter · 1.0: `death_finished` | 1.0 s |
| `crumble` | Ruin Warden | 0-0.3 s: gap light off, head drops 0.06 m · 0.3-1.0: `Root.position.y` -0.4, `Root.scale.y` 1 -> 0.6, pre-built 10-particle dust emitter `(0.45, 0.50, 0.40)` · 1.0: `death_finished` | 1.0 s |
Wizard extras (optional, same length): Vessa's orb `glow_boost` 5 for 0.15 s then 0 and light energy -> 0; Malrik's
shard rises 0.5 m then hides. Rules: no collision changes (gameplay did them), no `queue_free` by the model, no
allocation (emitters are pre-built `one_shot` children restarted with `restart()`), the shadow blob fades with
`transparency` 0 -> 1 over the last 0.3 s. The gameplay fallback (2.0 s) covers a model that fails to emit.

### 6.8 Level-up (`play_level_up()`, 0.4 s): `flash_color` gold, `hit_flash` 1 -> 0 over 0.3 s on every part; bipeds
`Root.scale` 1 -> 1.12 -> 1 (`TRANS_BACK`), weapon arm raised 40° for 0.3 s. Wizards: orb `glow_boost` 3 for 0.4 s. The
gold ring / sparks stay the existing `spell_vfx` / 3.U2 effect. Soldiers then receive `set_veterancy(level)` (7.1);
wizards never do.

### 6.9 Workers: carry and mine
- `set_carrying(true)`: crystal parts visible (4.1 #12 / 5.1 #10); walk variant: Chest `rotation.x` +10° (leaning under the
  load), stride rate x 0.9 (the unit's real speed is unchanged; the legs just cycle slower and longer: 32° instead of 28°).
- `play_mine()` (once per 4 s cycle): a **loop of 4 swings** at 1.0 s each: ArmR pick `rotation.x` -30° (0.35 s, cocked back) ->
  +150° (0.15 s, the head comes over the shoulder into the node in front; the hit: 4 crystal-blue sparks `(0.55, 0.85, 1.0)` at the tool tip, Root drops 0.03 m) -> back (0.5 s).
  The Gloom Thrall instead **holds the lantern toward the node** (ArmR -60°) and the lantern pulses at 2 Hz; the crystals
  in its cage fade in one by one at 1.3 / 2.6 / 3.9 s. `set_moving(> 0)` cancels the loop.

### 6.10 Cost rules (200 units; the numbers are in section 8)
- All animation is **procedural in one `_process`** per model with cached pivot references; no `AnimationPlayer`, no
  `Tween` (except the optional level-up scale), no `get_node` / allocation in `_process`. Idle / walk are pure functions
  of time and phase; attacks, casts, flinch and death read one `_action_t` timer.
- **Distance tiers**, re-evaluated every 0.5 s (staggered by instance id) from the distance to the active camera
  (`get_viewport().get_camera_3d()`, cached; no camera = headless: use the **middle tier**, so the perf test measures a
  realistic cost): < 30 m full rate; 30-45 m every 2nd frame, legs + arms only; > 45 m frozen in the idle pose, looping
  particles `emitting = false`; action timelines (attack / death) still run at every 2nd frame so `death_finished` always fires.
- Only write a pivot property when its value changed (idle units write 2: `Root.position.y`, `Chest.rotation.x`).

---

## 7. Veterancy, statuses, selection

### 7.1 Veterancy accents (`set_veterancy(level)`, 1-4; the gold chevrons `Label3D` of `unit.gd` stay and remain the main cue)
| Level | Accent (added, not replacing) |
|---|---|
| 1 Recruit | nothing |
| 2 Veteran | the unit's glow parts `glow_boost` **1.25** |
| 3 Elite | `glow_boost` **1.5** |
| 4 Champion | `glow_boost` 1.8 + a **gold trim**: one `TorusMesh` inner 0.20 outer 0.24 (`unit_gold_trim`) on the helm / head / pauldron, pre-built hidden, `keep_separate` |
(Simplified in review: no pennons, no gold motes; the chevrons already carry the level.) The trim is toggled with
`visible` (no instancing at runtime). Ruin Wardens, workers and wizards never receive `set_veterancy`; their scenes
have no trim.

### 7.2 Status looks (`set_status(id, on)`), compatible with `spell_vfx.gd` which already adds the flame billboard / shroud sphere
| Status | `spell_vfx` already does | The model adds |
|---|---|---|
| `haste` | flame billboard at `height + 1.15`, 6 ember particles at the feet | Faster legs come for free (`set_moving` gets the higher speed). Glow parts `glow_boost` x 1.3 while on. (Review: no attack retiming) |
| `shroud` | body transparency 0.6 via `_set_body_alpha` (walks the plain `Node3D` children of the unit, i.e. `_visual`, and recursively sets `transparency` on every `GeometryInstance3D`, the model included), smoke, sphere | Nothing: **the model must tolerate `transparency` on every part** (including the merged instances, the blob and particles). Capes: `cast_shadow` OFF, `render_priority 1` to limit sorting flicker |
The model returns `true` for these two ids (6.1) and `false` for anything else. `glow_boost` from statuses multiplies the
veterancy value. No new particles from the model (the VFX script owns them).

### 7.3 Selection: the existing yellow / team **ground ring** from `Unit` stays the only selection cue. No rim change (differs
from the keeps: 200 rings are enough, and a rim on 40 selected units flickers at 40 m). Hovered enemy: nothing from the model.

### 7.4 Compatibility rules with existing gameplay visuals
- `_set_body_alpha` finds the plain `Node3D` child of the unit (`get_class() == "Node3D"`, no VFX meta): that is
  `_visual`, created by `Unit._build_visual`; the model is instantiated **under** it and reached by the recursion.
  Nothing to change. The model must not add metas named like `spell_vfx`'s `META` on its root.
- HP bar (`body_height + 0.5`) and chevrons (`+ 0.8`): the bar shader keeps the depth test today, so a hat or staff can
  cut it. **4.G2** adds `depth_test_disabled` to the HP bar shader's `render_mode` (in `unit.gd`) and sets
  `_chevrons.no_depth_test = true`, so both always draw on top (as RTS bars usually do). The 0.35 m rule of 1.1 keeps
  them readable anyway.
- Projectiles spawn from gameplay at the unit centre, `body_height x 0.75` up (`Unit._perform_attack`, soldiers and
  wizard auto-attacks) or `body_height` (`Wizard._launch_fireball`). The bow hand, the dusk-caster, the sling loop
  and the orbs sit within ~0.5 m of that point; good enough at 40 m, no gameplay change.
- Selection ring: `TorusMesh` `radius + 0.2` to `+ 0.32` at y 0.05, flattened; the shadow blob (y 0.02) stays under it.

---

## 8. Performance and LOD (200 units on screen, `tests/perf_test.gd` must stay `PERF OK`)
| Item | Budget | Notes |
|---|---|---|
| Authored meshes per unit (every `MeshInstance3D` / `MultiMeshInstance3D`, blob included, before the merge) | **<= 22** worker / hound / warden, **<= 26** soldier, **<= 30** knight, **<= 36** rider (mount + rider), **<= 26** wizard | Review counts: Cinder Hand 22, Thrall 18, hound 13, warden 18, Guard 24, Archer 22, Shade 26, Nightbolt 23, Hurler 21, Knight 29, Rider 36, wizards 22. Authoring detail is cheap because of the merge |
| **Draw instances per unit after the merge (2.3)** | **<= 14** (<= 16 rider / knight / wizard), of which `keep_separate` parts <= 6 | 200 units ~ 2 800 instances: every child's transform is re-sent each frame a unit *moves*, so this is the real CPU cost, headless included |
| Unique materials | the **43** of 2.2, all `.tres` on disk | Zero materials created at runtime in a 1v1 (team colour = kingdom colour). No `material_override` except shared ones. Per-unit variation only through instance uniforms: `ao_bottom`, `ao_height` (set in the scene), `hit_flash`, `flash_color` (painted), `glow_boost` (rune_glow) |
| Vertices per unit | <= 2 500 (cylinders 8 seg, spheres radial 10 / rings 5, capsules radial 8 / rings 4) | 200 units ~ 500 k vertices: fine |
| Lights | **0 per soldier. 1 `OmniLight3D` per wizard** (range 4.5, shadows off) | 2 lights in a 1v1. Never more |
| Particles | Looping, only < 45 m: Blaze Rider mane (10), Ash Hurler smoke (6), warden motes (6), wizard motes (8). Everything else is a **pre-built `one_shot` emitter** (<= 16) restarted with `restart()`, never instanced at runtime | Worst case 60 riders: 600 particles |
| Shadows | `cast_shadow ON` only on the merged `Chest`, `Head`, `ArmR` instances and the mount body; OFF on legs, `ArmL`, glows, capes, blob, particles | ~4 casters per unit |
| Animation CPU | Rules of 6.10: <= 7 pivot writes per unit per animated frame (idle 2), every 2nd frame beyond 30 m, none beyond 45 m; no allocation, no `get_node`, no `Tween` in `_process` | **<= 0.5 ms per 100 units** (the 4.G2 rule "no worse than +0.5 ms per 100 units" of logic): measured by the 200-unit preview (`Performance.TIME_PROCESS` delta with / without models) and by `tests/perf_test.gd` |
| If over budget (in this order) | 1) raise the 30 m tier to 20 m, 2) run idle at every 3rd frame, 3) turn off `cast_shadow` on `Head` and `ArmR`, 4) drop the Blaze Rider mane particles (the flame cones stay) | Tell the lead which step was needed |
| Headless | Every model scene instantiates headless without errors; no camera = middle tier (6.10), so the perf test counts the animation | `tests/perf_test.gd` spawns units with the real `model_scene` after 4.G2 |
| Frame rate check | Windowed 1920 x 1080, zoom 40, a 1v1 base + **120 units** in view fighting: **>= 60 fps**; 200 units in view: >= 45 fps | Printed by `art/preview/units_preview.tscn` |

## 9. ASCII front views (looking at the face, +Z toward the reader; 1 column ~ 0.12 m, 1 row ~ 0.2 m, not to scale)
```
 VESSA (2.0)            MALRIK (2.0)          CINDER HAND (1.4)   GLOOM THRALL (1.4)
   *   \ * /   *           \       /              ___                 o
    \  /^^^\  /             \  ^  /            .-'   '-.        _   /^\   _
  ===[=======]===   O       |[ ]| *  o          |  o  |    ___/ \  (__)  /
     (  o   )   /|\         ( o )   /|\        (( o ))  --'       /___\ [S]
   __/\_____/\__ | |     __/\_____/\__| |     _/|   |\_          _|   |_
  |  \  ==  /  | |O|    |  \\ == //  |(*)    (_|_____|_)        (_|___|_)
  |  |      |  | | |    |  |      |  | | |     /|     |\  P        | |  ^
  |__|______|__| | |    |__|______|__| | |    (_)     (_)        (_)   (_)
    /   ||   \   | |     /   ||   \   | |
   |____||____|  | |    |____||____|  | |
  hat gem, 5 crown       horned mitre, floating   head-lamp, pick on   hood, lantern pole,
  flames, orb staff,     shard staff, high collar, the shoulder,        crystal cage (carry)
  wide mantle, cape      cape, torn hem           basket (carry)

 FLAME GUARD (1.6)      SHADE (1.6)           EMBER ARCHER (1.6)     NIGHTBOLT (1.6)
     _____                 \  ___  /               ^                   ________
   [|_____|]               \/(o)\/               /_\ o                 ( o )
   [[=====]]  /\           |[===]|              (  o  )   |          [========]
  (__|===|__) ||          (__|_|__)            /|=====|\  |     ----[=====|=====]---- *
  ##|  #  |##  ||  \       |\   /|  /           |     |   |          |       |
  ##|  #  |##  ||   \      | )-( |  |           |  |  |   |          |  |    |
  ##|_____|## /||    )     |_|_|_| /            |__|__|   |          |__|____|
  ###|_|_|###  ||  --     (_)   (_)            (_)   (_)            (_)    (_)
  tower shield (flame    reverse-grip blades,   1.7 m recurve bow,    flat dusk-caster
  point) + short sword,  shoulder spikes,       hood, ember quiver    held level, wide hat
  crested helm           half-cape

 BLAZE RIDER (1.9, side view ->)              ASH HURLER (1.6)        GRAVE HOUND (1.0, side view ->)
                 o/====>  *                     O                          ^ ^ ^ ^ ^
     ~~~ ~~~ ~~~ /|                          ( oo )  ||  ( )  ||     __/\/\/\/\/\__
   _/\_/\_/\_/\_/ \                          /|====|\ ||     (o)     (o=(  )(  )(  ))=o>
  <(  o  ________ /  ) )                      | [] |  ||             /  \  ||   /  \
    \_/ (        )   /                        |____|  ||            /    \ ||  /    \
     ||   ||   ||  ||                        (_)  (_)             ||    || ||  ||   ||
  war boar, fire mane, tusks,                 tall sling pole with   bone ribs, spine spikes,
  lance with pennon, round shield             a cracked ash ball,   glowing heart, eye flame
                                              smoking ash pot

 SHADOW KNIGHT (2.4)                  RUIN WARDEN (1.8)
   \\           //                      _______
    \\  _____  //     ||                |  ==  |   <- eyes, amber
   [[==|=====|==]]    ||               .-'-----'-.  <- floating head gap
  (@@)|[=====]|(@@)   ||              |  [ ] [ ]  |
  ####|   |   |####   ||      [#]     |___________|   [___]
  ####|   |   |####   ||      | |   (__)  ||  ||  (__)  | |
  ####|___|___|####   ||      | |    ||   ||  ||   ||   | |
   ###|__|_|__|###    ||      | |    ||  _||__||_  ||   |_|
     |   | |   |      ||      | |       (__)  (__)
    (_)  | |  (_)     ||     /   \
  great helm with horns, glowing   mossy stone blocks, hovering
  fuller on a 1.7 m sword resting  head, ruin-capital mace
  on the shoulder, long cape
```

## 10. Done when
### 4.V1 (wizards)
### Shared kit (4.V0, or the first part of 4.V1; see 2.4)
- [ ] `art/units/unit_model.gd` with every hook of 6.1 (+ `attack_windup`, `death_style`... exports of 2.4), the per-pivot
  merge of 2.3, the tiers of 6.10, the three death styles; `art/units/parts/*.tres`; `art/units/materials/` (shared 3);
  `painted.gdshader` + `hit_flash`, `flash_color`; `rune_glow.gdshader` + `glow_boost`; keep screenshots unchanged
  (`docs/art/screens/` keep shots before / after look the same).
### 4.V1 (wizards)
- [ ] `art/units/wizards/vessa.tscn` and `malrik.tscn`, root `Node3D` at the feet, **face +Z**, script extending
  `unit_model.gd` (`set_carrying` / `play_mine` / `set_veterancy` stay inherited no-ops).
- [ ] Every part of 3.1 / 3.2 at the listed size, position (+-0.05 m) and palette material (2.2); head top at 2.0 m +-0.25;
  1 `OmniLight3D` each (child of ArmR), shadows off; orb / shard halo visible at zoom 40.
- [ ] Idle, walk (blend 0.15 s), `wizard_bolt` (`attack_windup 0.12`), the three casts of 6.5 per wizard (by spell id),
  flinch, death (~1.0 s, `death_finished` emitted), level-up, `revive()` resets everything, shroud `transparency` looks right.
- [ ] Screenshots in `docs/art/screens/`: `wizards_z15.png`, `wizards_z40.png` (game camera pitch 55°), `wizards_cast.png`
  (the 6 casts at their peak frame), `wizards_death.png` (0.3 / 0.6 / 0.9 s), `units_silhouette_wizards.png`. Looked at:
  hat, staff and cape read at 40 m, 3 glowing points each, no z-fighting.
### 4.V2 (Fire army)
- [ ] `art/units/fire/cinder_hand.tscn`, `flame_guard.tscn`, `ember_archer.tscn`, `blaze_rider.tscn`, `ash_hurler.tscn`
  from section 4, within the section 8 budgets, the **18 Fire materials** of 2.2 in `art/units/fire/materials/`.
- [ ] Attack styles `melee_swing`, `bow_draw` (windup 0.15), `lance_charge`, `sling_throw` (windup 0.15), `worker_pick`
  per 6.4; `set_carrying` shows the crystals, `play_mine` swings 4 times in 4 s; rider gallop at rate >= 1.3; `fall`
  deaths; flashes via instance uniforms; `set_veterancy` glow + L4 trim.
- [ ] `art/preview/units_preview_fire.tscn` (own file): the 5 units walking / attacking at zoom 15 and 40
  (`fire_army_z15.png`, `fire_army_z40.png`), a **200-unit** row (`fire_army_200.png`) printing fps and animation ms
  (section 8 targets), `units_silhouette_fire.png` (unlit black on white).
### 4.V3 (Shadow army + warden)
- [ ] `art/units/shadow/gloom_thrall.tscn`, `shade.tscn`, `nightbolt.tscn`, `grave_hound.tscn`, `shadow_knight.tscn` and
  `art/units/neutral/ruin_warden.tscn`; the **17 Shadow + 5 warden materials** of 2.2; `set_team_color` no-op on the warden.
- [ ] Attack styles `dual_slash`, `caster_fire` (windup 0.12), `bite`, `great_swing`, `melee_swing` (warden), `worker_pick`;
  `sink` deaths, warden `crumble`; hound trot at 0.40 s stride.
- [ ] `art/preview/units_preview_shadow.tscn` (own file): `shadow_army_z15.png`, `shadow_army_z40.png`, `shadow_army_200.png`,
  `units_silhouette_shadow.png`: each character nameable from its black silhouette, and Fire vs Shadow units of the
  same role differ in outline (shield vs blades, bow vs flat caster, boar vs hound) when the two sheets sit side by side.
- [ ] (All three builds) headless: every scene instantiates with `--headless` without errors; `tests/perf_test.gd`
  prints `PERF OK`; each build adds its own `## 4.Vx` section (Edit, never rewrite the file) with its units'
  `attack_style` / `attack_windup` / `death_style` to `docs/handoff/for-gameplay-coder.md` (the shared-kit owner writes
  the hook list of 6.1 there).
### 4.G2 (plug-in + hooks; `scripts/units/`, `scripts/economy/worker.gd`, `data/units/`)
- [ ] Every `data/units/*.tres` (12 + `ruin_warden.tres`) points `model_scene` at its scene; Vessa / Malrik get theirs where
  the wizards are created. All hook calls of 6.1 exactly as listed there (`has_method`-guarded): `set_team_color` with
  the kingdom colour, `set_moving` with hysteresis, `play_attack` instead of `_lunge`, the ranged `attack_windup` countdown
  (<= 0.15 s), `play_hit`, `play_death` + `death_finished` / 2.0 s fallback run once, `spell_cast` -> `play_cast`,
  `play_level_up` (+ `set_veterancy` for soldiers only), `set_carrying` / `play_mine` (no worker crystal mesh with a
  model), `set_status` -> bool before the placeholder marks, `revive()` in `Wizard.respawn`.
- [ ] HP bar shader `depth_test_disabled`, chevrons `no_depth_test` (7.4). Selection ring, HP bar, chevrons,
  `_set_body_alpha` shroud fade and the Ember Step fade work on the new models (test: a shrouded Malrik is translucent;
  Vessa fades out and in on Ember Step; a Champion Flame Guard shows `^^^` above a visible HP bar).
- [ ] Test `tests/test_4g2.gd`: headless spawn of every unit type with its model, walk / attack / hit / death cycle without
  errors, `death_finished` frees the unit within 2.0 s, an archer's bolt spawns 0.15 s after `play_attack` and not at
  all if the archer dies first, a dead wizard revives with the model reset; `tests/perf_test.gd` with 200 real models
  still prints `PERF OK` and is no worse than +0.5 ms per 100 units.

## Decisions (D1-D3): defaults set in review 2026-09-25 (the user may still overturn them)
- **D1 = yes, ~1.0 s deaths** (was 0.35 s flatten): Fire falls face down and sinks, Shadow sinks into its shadow,
  the warden crumbles; bodies stay 1 s (readable, little clutter). No dissolve shader.
- **D2 = windup, <= 0.15 s**: ranged units spawn their projectile `attack_windup` after `play_attack()` (archer 0.15,
  Ash Hurler 0.15, Nightbolt 0.12, wizard auto-attack 0.12; melee 0 = instant). **Owner: `scripts/units/unit.gd`**
  (4.G2), a per-unit countdown in `_physics_process`; the cooldown still starts at the trigger, so DPS does not change.
- **D3 = ground ring only** on selected units (no rim), unlike the keeps, to keep 40-unit selections calm at 40 m.
