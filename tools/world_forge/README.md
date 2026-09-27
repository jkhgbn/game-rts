# World Forge (tool 6): stage sets and map layouts from text

Two modes, one CLI (run from the project folder, PowerShell):

```
tools\world_forge\run_world_forge.ps1 <verb> <id> [key=value...]
```

| Verb | What it does | Time |
|---|---|---|
| `help` | prints this README | 2 s |
| `check <set>` | parse + build in memory + all checks, writes the report (no scene saved) | ~5 s |
| `build <set>` | parse, build, **save** the set scene + marks.json + lighting + baked meshes, reload it, check, plan.png, report, history row | ~5 s |
| `sheet <set>` | **windowed**: renders every mark at a / b / c (start / middle / end) at 1600x900 with the 2.39 bars + a top-down view -> `sheet.png`, `stills/*.png` (run `build` first) | ~20 s |
| `map <map>` | `data/maps/<map>.map` -> `data/maps/<map>_layout.tres` (MapLayout) + navmesh-baked preview + **Map Lab** run + layout.png | 45-150 s |
| `export-map crown_hollow` | reads the live spots of an existing map scene into `data/maps/crown_hollow.map` (also `scene=res://x.tscn as=<id>`) | ~40 s |
| `demo` | the acceptance demo: build forge_watch_keep, map fourfold_hollow, export-map + map crown_hollow | ~5 min |

Exit codes: 0 PASS / WARN, 1 FAIL, 2 bad input. Specs are read by the shared reader `tools/common/tool_spec.gd`
(same grammar and errors as every tool: `file:line: message -> did you mean "x"?`); reports are the shared
`ToolReport` scorecard (PASS / WARN / FAIL, measured value, rule, fix hint, quality 0-100, "Improve next").
Outputs: `docs/tools/world_forge/out/<id>/report.md` + `report.json` for `check` / `build`, `report_map.md` for `map`,
`report_export-map.md` for `export-map`, + PNGs; one row per run in `docs/tools/world_forge/history.md`.
**Read report.md first, then look at the PNGs** (plan.png = where things are, sheet.png = what each camera sees).

---

## 1. Stage sets (`art/cinematics/stage_sets/<id>/<id>.set`, id starts with `forge_`)

Coordinates: metres, `(x,z)` on the ground (y = 0) or `(x,y,z)`. The set is centred on (0, 0); +z is "south" (toward
the usual camera side), -z "north". `yaw` = rotation.y in degrees; at `yaw=0` models face **+Z** (the game and
the cinematic runtime convention, `atan2(dir.x, dir.z)`): an actor at `yaw=0` faces a camera placed at larger z. `#` starts a comment. One statement per line: `keyword args key=value ...`.

| Statement | Keys (default) | Notes |
|---|---|---|
| `set <id>` | `size=WxD` (40x30), `ground=` ash / dirt / grass / snow / stone / sand / moss / crypt / `#rrggbb`, `light=` warm / ice / nightfall / dusk / storm / crypt / dawn / `res://preset.tres`, `seed=` (1), `title="..."` | first line |
| `budget` | `draws<=150 lights<=0 tris<=400000` | set budgets (checked) |
| `zone <name> <area>` | area = `ring((x,z),r0..r1)`, `circle((x,z),r)`, `rect((x0,z0),(x1,z1))` | used by `scatter area=<name>` / `avoid=<name>` |
| `place <kit> ` | `at=(x,z)`, `yaw=` (0), `scale=` (1), `tag=` (name for `subject=` / puppets), `lights=` off (default) / on, `y=`, `radius=` | one model (instanced) or a procedural prop (baked) |
| `row <kit>` | `poly=[(x,z),...]` or `from=(x,z) to=(x,z)`, `spacing=` (3) or `count=`, `yaw=along/across/random/<deg>`, `jitter=`, `scale=` | many copies along a line; mesh-only kits are baked |
| `scatter <kit>` | `area=<area or zone>`, `count=` (10), `gap=` (2), `seed=`, `avoid=cams,<zone>...`, `scale=a..b` (0.85..1.15), `tilt=` (deg) | deterministic, **baked to one mesh per material**; always keeps off places, walls, paths, actors; `engine=proton` = a live ProtonScatter node (below) |
| `wall <name>` | `poly=[...]`, `height=` (4), `thick=` (1.2), `gate=(x,z)` or `gate=[(x,z),(x,z)]`, `gate_width=` (4), `color=` (stone) | procedural crenellated wall + corner towers |
| `path <name>` | `poly=[...]`, `width=` (3), `kit=` road / flagstone / ember (glows) / river / snow / ash | flat ribbon |
| `actor <tag> <kit>` | `at=`, `yaw=`, `scale=`, `lights=` off (default) / on | a puppet: `puppet(&"<tag>")` returns it |
| `flock <tag>` | `at=`, `preset=` sky / far, DragonFlock keys (see "Flocks" below) | a flying flock (dragons, rocs) |
| `mark <shot>` | `from=(x,y,z)`, `look=(x,y,z)`, `to=` (= from), `look_to=` (= look), `fov=` (40, vertical deg), `fov_to=`, `subject=<actor or place tag>`, `dur=` (s, note only), `lens="..."` (note only) | camera marks; **explicit coordinates** (Lens, tool 3, is not installed yet) |

### Terrain, sky and water (prologue P1, 2026-09-27)

A set without any of these lines stays exactly as before (flat ground at y = 0). With them, the ground becomes a
**height field** baked to one mesh (+ a `StaticBody3D` collision, layer 1) and everything sits on it.

| Statement | Keys (default) | Notes |
|---|---|---|
| `terrain` | `step=` (2, grid metres), `smooth=` (2, blur passes), `noise=` (0.25, m of small bumps), `extend=` (0, m of terrain beyond the set edges on every side: distant hills), `rock=` (stone, colour of steep slopes), `snow=` (off, height above which the ground turns snow), `seed=` | optional: the first `hill` / `ridge` / `valley` / `pad` turns terrain on with these defaults |
| `hill <name>` | `at=(x,z)`, `r=` (12, radius), `h=` (6, height; negative = a hollow), `flat=` (0, plateau fraction 0..0.9 of r) | round, cosine falloff; ops add up |
| `ridge <name>` | `poly=[(x,z),...]`, `width=` (10), `h=` (8), `jag=` (0.3, crest roughness 0..1) | a hill line along a polyline (ends taper) |
| `valley <name>` | `poly=[...]`, `width=` (12), `depth=` (3), `flat=` (0.4, flat bottom fraction) | a cut along a polyline (put a `water` or a `path kit=river` in it) |
| `pad <name>` | `at=(x,z)`, `r=` (6), `y=` (terrain height at the centre), `edge=` (r*0.6, blend ring) | **exactly flat** circle for buildings / actors, applied after smoothing |
| `sky` | `mountains=` (2 layers, 0 = none), `dist=` (190 m from the set centre), `height=` (38 m), `color=` (#3a4150), `haze=` (the mood's horizon colour), `top=` / `horizon=` (retint the mood's sky), `seed=` | distant mountains: jagged silhouette rings, unshaded, 1 draw; the far layer fades to `haze`. The cinematic camera's far plane is 250 m: keep `dist` + the camera's distance from (0,0) < 250 |
| `water <name>` | `level=` (-0.5, y), `area=` (whole terrain) ring / circle / rect / zone, `color=` (#1d4252), `alpha=` (0.85) | a flat transparent plane, 1 draw; fills valleys below `level`; scatter never lands under water |

Placement on terrain: `place` / `row` / `scatter` / `actor` / `wall` / `path` sit on the terrain automatically
(`place ... y=` is still an absolute height). `place` / `actor` take **`pad=R`** (= a `pad` of radius R under them).
**`keep_height=1`** (on `place` / `row` / `actor`, U3): the y of `at=(x,y,z)` / `from=` / `to=` / `poly=` is absolute and
the terrain does not re-seat it; with `pad=R` (on `row` too: one pad per copy) the pad is flattened **at that y**, so raised
pieces stand on their own rock tier (steep pad edges take the `rock=` colour) instead of being pulled down to the ground:
```
row  res://.../tier2_wall.tscn  from=(-20,38,10) to=(20,38,10) count=5  keep_height=1  pad=7
```

### Flocks (`flock`, U3)
`flock <tag> at=(x,z) preset=sky|far seed= elders= big= small= heroes= radius= height=a..b elder_height=a..b
kinds=a,b small_kinds=... elder_kinds=... pattern=mixed|orbit|figure8|wander arrive_until= leave_at= leave_dir=(x,y,z)`
instances `art/cinematics/flocks/dragon_sky.tscn` (`preset=far`: `dragon_sky_far.tscn`) under `Placed/<tag>` with those
`DragonFlock` exports set (`seed` -> `flock_seed`, `kinds` -> `kinds_big`; keys left out keep the preset's values); they are
saved in the set scene. Not an obstacle (M2 / M3 skip it: flyers move); **B1** adds `DragonFlock.budget()["draws"]` after
`set_cine_time(0)` (~87 draws with 2 heroes, ~7 with `heroes=0`); `sheet` poses every `cine_timed` node at the mark's
a / b / c time (0, dur / 2, dur).

### `scatter ... engine=proton` (U3, optional)
`engine=forge` (default) bakes as above. `engine=proton` writes a live **ProtonScatter** node (`addons/proton_scatter`,
plugin enabled 2026-09-27) named `Proton_<kit>_<n>` instead: one item (the kit scene; `forge:` props are refused), the
area as shapes (rect = box, circle = sphere, ring = sphere minus a negative sphere), stack `Create Inside (Random)`
(`count=`) -> `Randomize Transforms` (yaw 360, `scale=` spread), seed = `seed=`, `dbg_disable_thread` on (Proton's
worker thread never delivered in 4.7.2 headless; the main-thread build gave 12 / 12 points inside a test ring). Proton
builds its multimesh when the set loads; tweak it in the editor afterwards. Limits: `avoid=` / `gap=` are ignored
(warning); on terrain the node sits at the area centre's ground height (no "Project On Colliders", which waits on physics
frames); S3 counts the request, B1 counts 1 draw each; the points are not in the D1 hash (the parameters are).
```
scatter kit:pine  area=ring((0,0),20..40)  count=60  seed=4  scale=0.8..1.2  engine=proton
```

### Generated specs (convention)
A spec written by a script keeps that script **in the set folder**: `art/cinematics/stage_sets/<id>/tools/gen_set.ps1` (or
`gen_set.gd`), next to its other set-only tools (e.g. `forge_citadel/tools/`: gen_set.ps1, make_parts.gd, bake_kits.gd).
`check` / `build` notice it and add a report note "Spec GENERATED by ...": edit the script, re-run it, then build.
A pad needs `r` >= 2 x `step` to be flat (smaller pads fall between grid points); make a building's pad cover its
forecourt too. `mark ... ground=rel` measures the y of `from` / `to` / `look` / `look_to` from the terrain under each point
(`from=(0,2,30) ground=rel` = 2 m above the hill there); without it y is absolute.
Checks added: **T1** placements on flat enough ground (slope under a place / actor > 12 deg = WARN, add `pad=`),
**M2** now fails a camera under the terrain, **M3** warns when a hill hides the subject. plan.png shows hill shading.
Budget: terrain = 1 draw (grid capped at 300 x 300 cells: `step` grows), mountains 1, each water 1.

Example (`art/cinematics/stage_sets/forge_hills_demo/forge_hills_demo.set`, builds PASS):
```
set forge_hills_demo  size=60x50  ground=grass  light=dawn  seed=5
terrain  step=2  smooth=2  noise=0.3  extend=60  rock=stone
hill   crown   at=(0,-12)  r=18  h=7  flat=0.45
ridge  north   poly=[(-70,-45),(-20,-60),(40,-55),(80,-35)]  width=36  h=22  jag=0.4
valley stream  poly=[(-60,20),(-15,14),(20,22),(70,12)]  width=14  depth=3
water  lake    level=-1.2
place kit:fire_keep  at=(0,-12)  tag=keep  lights=off  pad=9
sky    mountains=2  dist=190  height=40
mark H01  from=(-6,3,30)  look=(0,6,-12)  subject=keep  ground=rel  fov=40   # + H02..H04 in the file
```

**Kits** (`kit:<name>`): trees `pine fir birch broadleaf gold_tree`; rocks `boulder shards slab spire ruin_pillar
standing_stones giant_stump aqueduct crystal_node`; buildings `fire_keep ice_keep nature_keep dusk_keep watchtower
wayshrine essence_well ember_crucible tavern lost_cache`; actors `vessa torvald ysolde malrik flame_guard
ember_archer cinder_hand ash_hurler`; procedural `forge:brazier forge:stake forge:crate` (glowing tops, no lights).
Any `res://...tscn` works too. Keeps and wizards bring their own OmniLights: every place / row / actor switches its
lights off by default (0-lights rule; the set disables them at `_ready`, B2 reports how many); `lights=on` keeps them.

**What `build` writes** (never hand-edit, change the spec and rebuild):
`art/cinematics/stage_sets/<id>/<id>.tscn` (root = `ForgeStageSet`), `marks.json`, `<id>_lighting.tres`,
`meshes/{ground,paths,scatter,masonry}.res`; `docs/tools/world_forge/out/<id>/{report.md,report.json,plan.png}`.

**Set contract** (prologue-movie-plan.md 2.3, read by `CinematicPlayer`): root in group `"cinematic_sets"`, `set_id`,
`lighting` (LightingPreset), `Shots/<shot>_from|_to|_look_from|_look_to` Marker3Ds (meta `fov`), `begin_shot(id)`
(resets puppets), `end_shot(id)`, `set_active(on)`, `puppet(tag)`, plus `shot_ids()` and `mark(shot)`.
`marks.json` = `{shot: {from, to, look_from, look_to, fov_from, fov_to, subject, dur, lens}}` (set-local).
In a `.cine`: `use set <id>`, then `shot W02 4.0` (no `cam=`) uses the set's `W02` marks; puppets are actors.
Verified: `docs/tools/world_forge/cine/forge_watch_keep_probe.cine` -> `run_cine.ps1 check forge_watch_keep_probe
src=res://docs/tools/world_forge/cine/forge_watch_keep_probe.cine` plays 5 shots in the set (faces in band, runtime
camera = cine camera 0.000 m). Runtime: CinematicShot `stage_set = <id>`, `marker_prefix = <shot>`.

**Checks** (report IDs): K1 contract, B1 draws, B2 lights, B3 triangles, S3 scatter counts, M1 subject inside the
2.39 band at a / b / c, M2 camera clear of geometry along the whole move (inside = FAIL, < 0.9 m = WARN), M3 line of
sight to the subject, D1 deterministic layout (built twice, same hash). A FAIL value names the mark and the blocker.

### Complete example (a small crypt corner with 2 marks)

`art/cinematics/stage_sets/forge_crypt_corner/forge_crypt_corner.set`:
```
set forge_crypt_corner  size=24x20  ground=crypt  light=crypt  seed=3
budget draws<=60 lights<=0
wall  back  poly=[(-10,-8),(10,-8)]  height=3.5  thick=1  color=#3a3640
wall  side  poly=[(-10,-8),(-10,6)]  height=3.5  thick=1  color=#3a3640
place kit:ruin_pillar  at=(4,-4)  yaw=15  tag=pillar
place forge:brazier    at=(-3,-3)
place forge:brazier    at=(3,-6)
scatter kit:shards  area=rect((-9,-7),(9,8))  count=10  gap=2.5  seed=4  avoid=cams  scale=0.6..0.9
actor keeper  kit:malrik  at=(0,-2)  yaw=0  lights=off
mark C01  from=(0,1.7,7)  to=(0.8,1.7,5.5)  look=(0,1.5,-2)  subject=keeper  fov=36
mark C02  from=(-6,2.4,4)  look=(4,1.5,-4)  subject=pillar  fov=42
```
Then: `run_world_forge.ps1 build forge_crypt_corner` -> read the report (fix FAIL / WARN rows: each has a fix hint),
open `plan.png`; `run_world_forge.ps1 sheet forge_crypt_corner` -> open `sheet.png`. Iterate on the spec only.

### Demo set `forge_watch_keep` ("The Watch-Keep": Vessa's Fire keep behind its curtain wall at nightfall)
56 x 44 m, light `nightfall`, 118 draws, 0 visible lights (3 switched off: 2 in the keep, 1 on Vessa). Puppets: `vessa` (0, 5.2) at the gate, `guard_w` (-3.4, 2.9),
`guard_e` (3.4, 2.9). Marks (all subject-in-band PASS):

| Mark | Move | Subject | Use |
|---|---|---|---|
| `W01` | (-15,3.2,24) -> (-9,3.8,21), fov 44, 6 s | keep | establishing wide through the pines, keep against the dusk sky |
| `W02` | (-1.3,1.75,10.8) -> (-0.8,1.7,9.2), fov 34, 4 s | vessa | slow push-in, Vessa at the gate, keep behind |
| `W03` | (-7.5,2.1,8.5) static, fov 38, 3 s | guard_w | the sentry by the brazier |
| `W04` | (10,10,15) -> (6,9,13), fov 46, 5 s | keep | high over the wall toward the keep |

---

## 2. Map layouts (`data/maps/<id>.map`)

Write the **canonical quadrant / half** and a symmetry; World Forge places the twins, then the Map Lab judges the
layout before any map code exists.

| Statement | Keys | Notes |
|---|---|---|
| `map <id>` | `size=` (m, square), `symmetry=` none / mirror_x / mirror_z / rot180 / fourfold, `title="..."`, `spec=<doc>` | first line; fourfold = images identity, mirror_z, rot180, mirror_x (ids get `_a1 _a2 _b1 _b2`) |
| `seat <team>` | `name="..."`, `side=` 0/1, `frame=` identity / mirror_x / mirror_z / rot180 | the image of the canonical quadrant this seat owns (its keep = the canonical keep's image) |
| `<kind> <id>` | `at=(x,z)`, `sub=`, `team=`, `twin=<id of its image>` (2-image symmetries), any `key=value` prop, flag `solo` (no twins) | kinds: `keep node point camp tavern post guild peddler cache lair crown start slot` |
| `river <id>` | `poly=[...]`, `half_width=` | global (not mirrored): obstacles with gaps at crossings |
| `moat` | `center=(x,z) radius= half_width=` | global |
| `crossing <id>` | `kind=` bridge_road / bridge_lane / ford / steps, `at=`, `width=`, `length=`, `dir=(x,z)`, `name=` | global, RiverSystem shape |
| `road <id>` / `zone <id> <area> biome=` / `block <id> at= size=(w,d) yaw=` | | mirrored like spots (`solo` = once); blocks are navmesh obstacles |

A spot exactly on a mirror axis appears once per distinct image (midline objects twice in fourfold, the crown once).
Outputs: `data/maps/<id>_layout.tres` (`MapLayout`, `data/maps/map_layout.gd`: `spots_of(kind)`, `keep_of(team)`,
`seat_frame(team)`, `spot(id)`), `docs/tools/world_forge/out/<id>/{report_map.md, layout.png, map_profile.json,
preview.tscn, preview_level.gd, map_lab/scorecard.md, map_lab/heatmap.png}`. Checks: L1 keep per seat, L2 in bounds,
L3 spacing, L4 counts, N0 navmesh bakes, LAB (Map Lab result + score >= 90), LAB.M1-M4 / F1 symmetry rows, and after
an `export-map`: R1 round trip (every live spot rebuilt within 0.1 m), R2 path table (every spot pair's
NavigationServer path on the preview = the live one, <= 0.01 m).
`navmesh <res> origin=(x,y,z)` (written by export-map): the preview loads that navmesh instead of baking a flat one,
so paths and the Map Lab table are the live map's. export-map saves `data/maps/<id>_navmesh.res` and
`out/<id>/export_paths.json`.
The Map Lab CLI also takes the generated profile: `tools\godot_run.ps1 --headless --path . -s res://tools/map_lab/map_lab.gd
--fixed-fps 60 --quit-after 9000 -- profile_json=res://docs/tools/world_forge/out/<id>/map_profile.json`.

Example (a 60 m 1v1 with a diagonal river):
```
map test_mini  size=60  symmetry=rot180  title="Test Mini"
seat 0  name="south-west"  side=0  frame=identity
seat 1  name="north-east"  side=1  frame=rot180
keep  keep   at=(-20,20)
node  n1     at=(-12,6)
camp  c1     at=(-6,-15)
crown crown  at=(0,0)
river mid  poly=[(-31,-31),(31,31)]  half_width=1.5
crossing ford_c  kind=ford  at=(0,0)  width=8  dir=(1,1)
```
Demo maps: `fourfold_hollow.map` (map-2v2.md 2.3-2.7: 95 Map Lab spots, 10 crossings; Map Lab WARN 98, symmetry
M1-M4 / F1 PASS), `crown_hollow.map` (exported from `scenes/skirmish.tscn`, 51 spots, round trip 0.000 m, path table
1275 pairs identical; Map Lab on the rebuild = the live Crown Hollow run: WARN 98, same 42 F2 findings).

## Limits (v1)
- A new map (no `navmesh` line) previews on flat ground + water + keep footprints + blocks: no forest / cliffs.
  Lairs reach the Map Lab through a generated `LAIR_SPOTS` constant. Navigation links are not exported (WARN E5).
- Sets: terrain is a height field (no overhangs / cliffs, no caves), no per-shot acting (`AnimationPlayer` "Acting" is honoured if added later),
  no Art Lab `decor_set` run yet, marks need explicit coordinates until Lens (tool 3) lands.
- `forge_spec.gd` / `forge_report.gd` are thin adapters over `tools/common/` (ToolSpec / ToolReport): budget tokens
  `draws<=150`, `(x,z)` ground points, polylines and areas are World Forge's own value shapes.
