# Character kit (4.V0) - how to build a unit

Spec: `docs/design/art-units.md`. Owner: 4.V1 tech-artist. **Fire / Shadow builds: use, don't edit these files**
(ask the owner for API changes). Example units: `art/units/wizards/vessa.gd`, `malrik.gd`.

## Files
| File | What |
|---|---|
| `character_model.gd` | `class_name CharacterModel`: pivots, all hooks, merge, idle / walk / attacks / hit / death / level-up / mine, distance tiers |
| `unit_painted.gdshader` | copy of `art/shaders/painted.gdshader` + instance uniforms `hit_flash`, `flash_color` (the keeps' shader stays untouched); slots 1-4 (see "Instance uniform slots") |
| `unit_paint.gdshaderinc` | G3b painted-PBR layer included by `unit_painted` and `champions/champion_palette`: soft wrap light, per-surface sheen / spec (`surface_kind`: 0 plain, 1 cloth, 2 metal, 3 leather, 4 skin, 5 wood, 6 fur / hide, 7 bone / stone; -1 auto), procedural detail, metal fake reflection. `docs/art/g3b_materials.md` |
| `tools/assign_surface_kinds.ps1` | writes `surface_kind` into every unit material from its name (re-run after adding materials) |
| `tools/g3b_shots.gd` | windowed before / after army shots + GPU timing (`-- --gfx=high [--legacy] [--perf]`) |
| `unit_glow.gdshader` | copy of `rune_glow.gdshader` + instance uniform `glow_boost` (slot 5) |
| `unit_blob.gdshader` | ground blob, instance uniform `blob_color` (slot 6) |
| `tools/kitfix_glow_check.*` | A.16 slot audit (headless) + glow / flash screenshot rig and GPU probe (windowed) for every unit |
| `materials/*.tres` | the closed palette of 2.2 (42 files: `fire_*`, `shadow_*`, `warden_*`, `unit_eye_dark`, `unit_gold_trim`, `crystal_glow`, `unit_shadow_blob`). **Never add a material in a unit scene**: snap to the nearest entry. New entries go in `tools/make_materials.gd` (owner) |

## Scene layout (face = local +Z, weapon hand ArmR at +X)
```
MyUnit (Node3D, script extends CharacterModel)   <- never animated
  Root (Node3D)
    Hips (Node3D)    LegL, LegR (Node3D at the top of each leg)
    Chest (Node3D)   Head, ArmL, ArmR (Node3D at the shoulder)
    Mount (Node3D)   LegFL, LegFR, LegBL, LegBR, Head   (riders / hound only)
  Fx (Node3D)
  Shadow (MeshInstance3D, optional: ensure_shadow_blob() makes it)
```
Missing pivots are skipped. Keep pivot rotations at 0 in the rest pose (rotate the meshes instead).

## Two ways to author parts
1. **Code (recommended, what the wizards do)**: override `_build_parts()` and call
   `add_part(pivot, mesh, material, model_pos, rot_deg, scale, keep_separate, name)`. `model_pos` is in MODEL space
   (feet origin), the kit converts it to the pivot's local space. Meshes: `cyl(top_r, bottom_r, h, seg)`, `sphere(r)`,
   `box(size)`, `capsule(r, h_total)`, `torus(inner, outer)`, `prism(size)`, `cape(w, h)` (all cached, shared).
   Materials: `palette(&"fire_cloth")`. Static parts return `null` after the first instance of the type (they are
   already merged), so only keep references to `keep_separate` parts. Call `ensure_shadow_blob(radius, tint)` there too.
2. **Editor**: put `MeshInstance3D` children under the pivots (materials from `materials/`). Same merge.

**Merge (automatic, once per scene type)**: every static `MeshInstance3D` under a pivot becomes one merged mesh per
pivot (one surface per material), cached in a static dictionary. Parts with meta `keep_separate` (or any
`MultiMeshInstance3D`, `GPUParticles3D`, `Light3D`) stay as they are. Mark keep_separate only for toggled / animated
parts. Shadows: merged Chest / Head / ArmR / Mount cast, everything else off.

## Metas the kit reads
| Meta | Effect |
|---|---|
| `keep_separate` | not merged |
| `carry` | shown only while `set_carrying(true)` |
| `vet_trim` | hidden, shown at `set_veterancy(4)` |
| `death_fx` | one-shot `GPUParticles3D` restarted when the glows die (fall 0.25 s, sink 0.4 s, crumble 0 s) |
| `own_glow` | glow part NOT boosted by the kit (you drive `glow_boost` yourself; multiply by `glow_level()`) |
Looping `GPUParticles3D` (one_shot false) stop beyond 45 m automatically. Glow parts (any shader declaring `glow_boost`) get
`glow_boost` = veterancy x haste automatically, 0 when dead.

## Root exports (set in the scene)
`body_height`, `attack_style` (`melee_swing`, `dual_slash`, `great_swing`, `lance_charge`, `bow_draw`, `caster_fire`,
`sling_throw`, `bite`, `wizard_bolt`, `worker_pick`), `attack_windup` (<= 0.15, ranged only), `death_style`
(`fall`, `sink`, `crumble`), `stride_time`, `stride_speed` (m/s at stride rate 1), `idle_period`, `is_quadruped`,
`gallop_rate`, `kingdom_color` (the cloth colour of the scene), `swing_scale`, `leg_swing_deg`, `walk_bounce`, `flinch_push`.

## Hooks (gameplay calls these, all `has_method`-guarded; calls before `_ready` are kept)
`set_team_color(c)` · `set_moving(speed)` · `play_attack()` · `play_cast(spell_id)` · `play_hit()` · `set_weapon_class(id)` ·
`play_death()` + signal `death_finished` (1.0 s) · `play_level_up()` · `set_veterancy(level)` · `set_carrying(on)` ·
`play_mine()` · `set_status(id, on) -> bool` (true for `haste`, `shroud`) · `revive()` · riding (13.V1b, below):
`set_seated(on, mount)` · `play_mount()` · `play_dismount()` · `play_thrown()` + signal `dismount_finished`. Read-only: `attack_windup`.
Dances (2026-09-27): `play_clip(&"dance_victory" | &"dance_surrender" | &"dance_random") -> bool` (looping, procedural,
kingdom flavour from the script folder / wizard name, per-instance phase + tempo), `stop_clip()`, `current_clip()`,
`has_clip(id)`, `can_dance()` (false for quadrupeds, mounts, seated riders, no chest + arm), `dance_style()`; override
`_pose_dance(clip, t, w)` / `_can_dance()`. Stops on attack / cast / mine / death and on any Unit order; fades while
walking; 0 cost when not dancing. Glue: `scripts/vfx/unit_dances.gd` (match end), chat "dance 1/2/3" (`scripts/ui/chat_line.gd`).

`set_team_color(c)` can be called any number of times, in any order (mid-game recolour, mirror matches): every
`*_cloth` / `*_cloth_dark` / `*_cape` / `*_cape_plain` / `*_pennon` surface (merged, keep_separate `material_override`,
mount barding) takes the kit's cached per-colour variant (it remembers its authored material in meta `team_base`), and
the scene's own `kingdom_color` restores the authored materials. A subclass whose own `set_team_color` skips the base
calls `_apply_team_color(c)` (Barrow Giant). Test: `tests/test_kit_team_color.gd`.

## Subclass hooks (override in your unit script)
- `_build_parts()`, `_after_ready()` (grab keep_separate nodes), `_on_revive()` (reset your own parts).
- `_on_action_event(ev)`: `attack_start`, `release` (at `attack_windup`, or the strike frame for melee), `attack_end`,
  `cast_start`, `cast_end`, `mine_hit`, `level_up`, `death_glow_off`. Use it to hide a bolt / ash ball, restart
  a pre-built emitter, etc.
- `_extra_process(dt)`: your own per-frame motion (lantern swing, flames). Keep it tiny; `dt` respects the tiers.
- `_pose_cast(spell, t) -> length`, `_pose_mine(t)`: write offsets with `rot(P_ARM_R, Vector3(rad, 0, 0))` and
  `pos(P_ROOT, Vector3(...))` (added to the rest pose this frame). Pivot ids: `P_ROOT, P_HIPS, P_LEG_L, P_LEG_R,
  P_CHEST, P_HEAD, P_ARM_L, P_ARM_R, P_MOUNT, P_LEG_FL, P_LEG_FR, P_LEG_BL, P_LEG_BR, P_MOUNT_HEAD`.
- Useful state: `_action` (`&"attack"`, `&"cast"`, `&"mine"`, `&""`), `_action_t`, `_dead`, `_death_t`, `_tier`
  (0 < 30 m, 1 < 45 m, 2 frozen), `_t`, `glow_level()`.

## Champion weapons (11.V1, skills-rework.md 5)
The shared class weapons live in `art/units/champions/weapons/` (`champion_weapon_kit.gd`, 8 shared materials). The kit
merges them into the model's own pivot meshes: **0 extra draw instances, 0 lights**. Full convention for the champion
models (tags, grips, poses): `docs/handoff/for-tech-artist.md` "Step 11 (task 11.V1)". In short:
- `set_weapon_class(class_id, pop := true)` (`&""` = archetype weapon), `weapon_class()`, `weapon_pieces()`,
  `get_weapon_tip()`, `weapon_slot_xf(slot)`, `weapon_grip_xf(piece)`; attack styles `spear_thrust`, `sword_slash`,
  `great_cleave`, `staff_bolt` (set / restored by the swap); `play_cast` routes the 12 class skill ids
  (`CLASS_SKILL_IDS`) to `_pose_class_skill(id, t)`, never to `_pose_cast`.
- Tag parts with `mark_weapon_classes(part, [...])` / `mark_archetype_weapon(part)` (meta `weapon_classes`).
- Hooks: `_weapon_pieces(class_id)`, `_weapon_slot(slot)`, `_weapon_grip(piece)`, `_on_weapon_class(class_id)`,
  `_pose_class_skill(id, t)`; pose helpers `show_weapon_piece(piece, on)`, `weapon_flare(amount)`.
- Private kit members of this feature all start with `_wk_` (don't reuse the prefix in a unit script).

## Seated rider (13.V1b, cavalry-mounts.md 6.2 / 10)
Any CharacterModel can ride a `MountModel` (`kit/mount_model.gd`); mount and rider are siblings under the unit's visual
(same transform). Hooks: `set_seated(on, mount: Node3D = null)` (instant), `play_mount()` (0.3 s hop-on from the left
flank; call right after `set_seated(true, mount)`), `play_dismount()` (0.3 s hop-off onto the model's own origin, then
unseated + signal `dismount_finished`), `play_thrown()` (0.5 s tumble, back on its feet on its origin, unseated +
`dismount_finished`); read-only `is_seated()`, `seat_mount()`, `seat_action()` (`&""`, `&"mount"`, `&"dismount"`,
`&"thrown"`); constants `MOUNT_HOP_LEN` 0.3, `THROWN_LEN` 0.5. All safe before `_ready`; a hop-off / thrown finishes even
if the mount node is freed meanwhile. While seated: the Hips pivot sits on the mount's live Seat (no frame lag: the rider
gets `process_priority` = mount + 1), legs astride (splay measured from the mount's body mesh, clamped 12-50), walk off
(`set_moving` ignored), riding idle + rider bob from the mount's `gait_phase()` / `gallop_blend()`, own blob hidden,
tier / parity / freeze follow the mount; attacks / hits / level-ups play on top (their Root motion halved). Death seated:
on a dying mount the rider rides its fall, on a living one it is thrown and stays down; `revive()` = on foot.
Exports (group "Riding"): `seat_offset` (hip point vs the Seat, seat frame), `seat_leg_splay_deg` (0 = measured),
`seat_leg_forward_deg` (28). Subclass hook `_pose_seated(w, gait, gallop, moving)` (arms / props per model; call super).
Private members start with `_rd_`. Not seated = one bool check per frame. Preview: `tools/rider_seat_preview.tscn -- --shots`.

## Instance uniform slots (A.16, every unit shader MUST follow this)
Godot stores a GeometryInstance's instance uniforms in ONE buffer of 16 vec4 slots shared by all its surfaces. Without
a hint each shader numbers its own instance uniforms 0, 1, 2... in declaration order, so on a merged mesh (painted +
glow + banner surfaces) `ao_bottom` (painted #0) and `glow_boost` (glow #0) wrote the same slot and the glows rendered
with `glow_boost` = 0 (dark). Fix: every unit shader declares the kit names with an explicit slot, the same everywhere:

| Slot | Name | Type | Declared in |
|---|---|---|---|
| 0 | *(reserved)* | | `art/shaders/banner.gdshader` `phase` (implicit #0, capes / pennons are merged with the body) |
| 1 | `ao_bottom` | float | `unit_painted`, `ice/ice_crystal.gdshaderinc`, `wizards/torvald_frost`, `wizards/ysolde_grove` |
| 2 | `ao_height` | float | same |
| 3 | `hit_flash` | float | same |
| 4 | `flash_color` | vec3 | same |
| 5 | `glow_boost` | float | `unit_glow` |
| 6 | `blob_color` | vec4 | `unit_blob` |
| 7-11 | *(model-own)* | | titans / critters: `membrane_tint` 7 (dragons, briar roc), treant `root_morph` 7 / `heal_glow` 8 / `team_tint` 9, critters `gait` 8 .. `dissolve` 11 (never merged with a slot-12 surface of another meaning) |
| 12 | `kit_detail` | float | `unit_painted`, `champions/champion_palette` (G3b cost tier: 0 Low, 1 Medium, 2 High / Ultra; the kit writes it from `GameSettings.effective_graphics_quality()`) |
| 13 | `flare` | float | `wizards/wizard_runes` (G3a hero rune bands: cast / attack / level-up flare, written by `WizardModel`) |
| 14-15 | free | | a new per-unit instance uniform takes the next free slot: add it here AND to `CharacterModel.INSTANCE_SLOTS` |

Syntax: `instance uniform float glow_boost : instance_index(5) = 1.0;`. A new unit / hero shader copies the lines of
`unit_painted` (flash + height) or `unit_glow` verbatim. The kit finds its targets by instance uniform NAME
(`CharacterModel.instance_uniforms_of(mat)`, includes resolved): any GeometryInstance with a `hit_flash` surface gets
`ao_height` + the hit / level-up flash, any with `glow_boost` gets the glow level; set them only by name with
`set_instance_shader_parameter`. Values authored on static parts (`instance_shader_parameters/<name>` for the names
above) are carried over to the merged node (first part wins; one value per pivot), then the kit writes its own.
Never merge a part whose shader has other implicit instance uniforms (the `art/vfx/` shaders: mark it
`keep_separate`). Check: `art/units/kit/tools/kitfix_glow_check.tscn -- --audit` (headless, prints KITFIX AUDIT OK;
lists every slot collision) and windowed `-- --shots --tag=x` (GPU probe + `docs/art/screens/kitfix_glow_x_*.png`).

## Headless builds drop MultiMesh transforms
Under `--headless` (dummy renderer) `MultiMesh.set_instance_transform` is not kept: a MultiMesh built or saved by a
headless tool script comes out with every instance at the origin (or empty). Generators that fill a
`MultiMeshInstance3D` (grass tufts, scale plates, leaves...) must run **windowed**, or bake the instances into a
regular mesh (`ArrayMesh` / merged surfaces) before saving. Runtime-built MultiMeshes are fine in the game (windowed).

## Rules
Rotation sign (face +Z): an arm `rotation.x` **negative raises it forward**; Root `rotation.x` positive falls toward +Z.
A tool held UP from the fist (pick, pole, great sword on the shoulder) points opposite the arm: its head moves forward
when the arm goes **positive** (4.V4: `worker_pick`, `great_swing`, mine use that; sword / hammer / blades held down
from the fist chop with negative angles). Check a new swing from the side (`docs/art/screens/kitfix_*.png`).
No `get_node`, no allocation, no Tween in `_extra_process`. Only `set_instance_shader_parameter` for per-unit looks.
