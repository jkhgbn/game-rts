# Dragon sky: the flock actor (prologue P3, 2026-09-27, tech-artist)

A drop-in `Node3D` (`DragonFlock`, `dragon_flock.gd`) that fills the sky over its position with 30-120 flyers of three
sizes, on looping flight paths, with banking, varied wing phases and glides. It reuses the real flyer models (no new
creature art): Cinder Dragon, Frost Dragon, Roc (Stormcrest / Duskwing), Frost Wyrm (Rimescale / Old Hoarfang).

| File | What |
|---|---|
| `dragon_flock.gd` | `class_name DragonFlock`: paths, flap / glide schedule, LOD, heroes, time source, arrive / leave |
| `flock_kinds.gd` | `class_name FlockKinds`: the kind table + the impostor bake (model merged at its rest pose, cached per process) |
| `flock_impostor.gdshader` | impostor material: wing beat about the model's own hinge axes, tail sway, serpent S-wave, recolour, glow parts |
| `dragon_sky.tscn` | preset: 2 elders (x4-5, 75-115 m up) + 10 big (x0.9-1.4, a cinder + frost pair wing to wing) + 42 small (x0.16-0.34, flights of 3-7, 60 % recoloured) = **54 flyers**, radius 90 m, heights 22-70 m, 2 heroes |
| `dragon_sky_far.tscn` | backdrop preset: 1 elder + 8 big + 56 small = **65 flyers**, radius 220 m, 55-170 m up, 0 heroes (all impostors) |
| `dragon_sky_leave57.tscn` | `dragon_sky` that leaves at cine time 57 s (S12 "circle once and fly away") |
| `tools/flock_check.gd` | headless determinism + budget check (`PASS flock_check`) |
| `tools/flock_sheet.gd` | windowed still sheet -> `sheets/sheet.png` (+ one PNG per view) |

## 1. Place a flock

**World Forge set spec (works today, no tool change):** a `place` line with the preset scene; `at=` is the flock
centre on the ground, heights are relative to it. Give it a small `radius=` so World Forge does not treat it as a
blocker in its camera checks.
```
place res://art/cinematics/flocks/dragon_sky.tscn      at=(0,0)   tag=dragons     radius=0.5
place res://art/cinematics/flocks/dragon_sky_far.tscn  at=(0,-40) tag=dragons_far radius=0.5
```
A spec cannot set the flock's parameters through `place` (seed, counts, leave time...): use a preset `.tscn` (copy one,
change the exported values; 5 lines, see below) or the requested `flock` line (`docs/handoff/for-world-forge.md`).

**A `.cine`:** `prop sky res://art/cinematics/flocks/dragon_sky.tscn at=(0, 0, 0)` (any flock preset).

**Code / a scene:** instance the `.tscn` or `DragonFlock.new()` (set exports before it enters the tree, or call
`rebuild()` after changing them).

A preset `.tscn` is just the script plus the values you change:
```
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://art/cinematics/flocks/dragon_flock.gd" id="1_flock"]
[node name="DragonSkyDusk" type="Node3D"]
script = ExtResource("1_flock")
flock_seed = 21
small = 30
leave_at = 176.0
```

### Parameters (exports)
| Export | Default | Meaning |
|---|---|---|
| `flock_seed` | 7 | same seed = same flock, every frame |
| `elders` / `big` / `small` | 2 / 10 / 42 | counts per size class |
| `kinds_elder` / `kinds_big` / `kinds_small` | frost + cinder / all 6 / dragons + rocs | ids from `FlockKinds.KINDS`: `cinder_dragon frost_dragon roc roc_dusk frost_wyrm hoarfang` |
| `elder_scale` / `big_scale` / `small_scale` | (4,5) / (0.9,1.4) / (0.16,0.34) | model scale ranges (1 = the in-game titan, wingspan ~8 m) |
| `radius`, `height`, `elder_height` | 90, (22,70), (75,115) | area (m) and flight heights above the node |
| `speed_elder` / `speed_big` / `speed_small` | 6 / 13 / 16 m/s | cruise speeds (+-15 % per flyer) |
| `pattern` | `mixed` | `orbit`, `figure8`, `wander` (all loop exactly) or a random mix |
| `flight_size` | 7 | small flyers fly in loose V flights of 3..N sharing a path |
| `pair` | true | big 0 + 1 = a cinder and a frost dragon wing to wing |
| `heroes` | 2 | elders, then big flyers, drawn with the **real model** (pivots driven by the flock). ~40 draw calls each |
| `tints`, `tint_share`, `tint_strength` | 6 colours, 0.6, 0.75 | recolours of the small flights (ember gold, moss, violet, pearl, storm blue, rose) |
| `lod_px` | 70 | impostor switches to its far LOD below this projected size (px) |
| `bank_gain` | 2.2 | bank = atan(lateral g) x gain, clamped to the kind's bank limit |
| `time_offset`, `time_scale` | 0, 1 | flock time = cine time x scale + offset |
| `arrive_until`, `arrive_spread`, `arrive_from` | -1 (off), 6, (0,-0.8,0) | before this flock time they fly in (from below: "lift off the spires"), staggered |
| `leave_at`, `leave_spread`, `leave_dir` | -1 (off), 5, (0,0.35,-1) | from this flock time they fly away (accelerating, staggered); 30 s later the flock stops drawing |

### Public API
`set_cine_time(t)` (poses at once; group `"cine_timed"`), `update_at(flock_t)`, `flock_time()`, `flyer_count()`,
`hero_count()`, `flyer_state(i, t) -> {xform, flap, aw, slow, bank_deg, kind, role, scale, hero}` (pure),
`flyer_position(i, t) -> Vector3` (global, for a follow camera / marker), `budget() -> {flyers, heroes, draws, verts,
near, far, lights}`, `rebuild()`.

## 2. Time and determinism
Every pose is a pure function of `(flock_seed, time)` (no `randf`, no `TIME` in the shader, no accumulated state; the
real hero models' own `_process` is switched off). The time source, in order:
1. `set_cine_time(t)` called this frame (a driver: `get_tree().call_group(&"cine_timed", &"set_cine_time", t)`),
2. a playing `CinematicPlayer` (group `"cinematic_player"`): `elapsed()`, so runtime `seek()` is exact,
3. a playing cine `CinePreview` (`play` / `record`): its `t`,
4. its own clock (sum of `delta`; exact under `--fixed-fps` / Movie Maker from the start).

**cine `stills` / `check` limit:** stills pose the stage with `CinePreview.pose(at)` and freeze the stage's processing;
nothing tells the flock the time, so stills show the flock at its own clock (not the shot time) until cine adds the
one-line `call_group` (requested in `docs/handoff/for-cine.md`). `record` and the runtime player are exact now.

Checked (`tools/flock_check.gd`, headless): D1 two instances same seed identical at 6 times, D2 shuffled / repeated seek
identical, other seed differs, D3 own clock == `set_cine_time` at the same t. Windowed (`flock_sheet.gd`): the same t
rendered before and after another t = **0 changed pixels**.

## 3. LOD and budget
- **Heroes** (tier 0): the real model, full shaders, driven pivot by pivot (wings about the model's hinge axes, neck,
  tail, legs, same curve as `flyer_model.gd`). Static assignment (no pop). Frost Wyrm kinds are never heroes (skinned,
  own clock).
- **Near impostor** (tier 1): the model's meshes merged at rest into ONE mesh per kind (5.7-9.5 k verts), flat colours
  read from its materials (scale / belly / membrane tint / fin / glow parts emissive), one MultiMesh per kind, wing beat
  in the vertex shader. 1 draw call per kind.
- **Far impostor** (tier 2): the same mesh clustered per part (140-480 verts), switched per flyer by projected size
  (`lod_px`). 1 draw call per kind.
- Measured (RTX 3070 laptop, windowed, `dragon_sky` + `dragon_sky_far` = 119 flyers): **+93 draw calls** (2 heroes ~80
  + 12 multimeshes), +143 k primitives, **0 lights**, 0 shadow casters, pose update of both flocks ~3.7 ms / frame
  (GDScript; the cinematic runs at 30 fps). `dragon_sky` alone: 54 flyers, ~87 draws. With `heroes = 0`: 10-12 draws.
  Bake: ~3.7 s once per process (6 kinds).

## 4. The prologue shots (docs/design/prologue-3min.md, data/cinematics/src/prologue_3min.cine)
Global cine times assume the current draft (S01 at 0 s). One flock per set is enough; time with `arrive_until` /
`leave_at` in cine seconds.
| Shot | Dragons | Setup |
|---|---|---|
| S01 0-7 s | "the first dragons lift off the spires" | `dragon_sky` with `arrive_until = 6`, `arrive_from = (0,-1,0)` (they rise into the loops over 0-6 s) |
| S02 7-14 s | an elder glides under the bridge | elders loop at 75-115 m: for an under-bridge pass put a 2nd preset with `elders = 1, big = 0, small = 0, elder_height = (y,y)` at the bridge and `pattern = orbit`, or give me the bridge height and I tune it |
| S03 14-21 s | background life | `dragon_sky_far` behind the citadel |
| S04 21-28 s | elders, flights, cinder + frost wing to wing | `dragon_sky` (pair on by default). FOLLOW a baby dragon: use `flyer_position(i, t)` of a small flyer for the camera (a cine `follow` needs a moving actor: see missing) |
| S07 40-45 s | every head turns | not done (heroes only could; see missing) |
| S12 57-60 s | the dragons circle once and fly away | `dragon_sky_leave57.tscn` (`leave_at = 57`) |
| S30 174-180 s | the dragons leave at dusk | a preset with `leave_at = 176` (or place none: they left in S12) |
| S15 / S23 | the cinder / frost dragon in the vignettes | the real unit models (`cast` in the .cine), not the flock |

## 5. Stills
`& .\tools\godot_run.ps1 --path . -s res://art/cinematics/flocks/tools/flock_sheet.gd --quit-after 30000 '--' set=forge_citadel`
(falls back to a plain dawn sky while the set is not built). `sheets/sheet.png`: ground-up, high wide, in the flock,
the elder hero close, a small flight close, at t = 3 and 21.5 s, then the LOD pair (all near / all far).

## 6. Missing / next
- cine stills timing (handoff above); a World Forge `flock` line (handoff `for-world-forge.md`).
- Perched "gargoyle" dragons, the bell carrier, the baby ember-dragon as a cine actor for S04 FOLLOW, S07 head turn:
  not built (a FlyerModel has no perch pose; a child on a baby dragon needs a rider).
- Impostors use flat material colours: close to the camera (< ~40 m for a big one) prefer a hero.
- Pose update is GDScript (~2.2 ms per 54 flyers headless); fine at 30 fps, move to a typed array if flocks grow past ~200.
