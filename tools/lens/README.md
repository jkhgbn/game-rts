# Lens (tool 3): shot composer + icon / portrait studio

Framing words in, camera out. Lens stages model scenes, solves a camera from their measured bounds and a framing
vocabulary (`"mcu on vessa, 3/4 left, low"`), writes a **CameraSpec** (`camera.json`, used by `cine`), renders stills and
**measures the framing from pixels** (ID passes). It also makes game **icons** and dialogue **portraits** with one rule.
Spec: `docs/plan/tools-wave.md` section 4. Owner: four-wizards-high. Uses `tools/common/` (never edit it).

## Commands (PowerShell, from the project root)
| Command | Window? | What |
|---|---|---|
| `.\tools\lens\run_lens.ps1 help` | no | grammar + example |
| `.\tools\lens\run_lens.ps1 check <id>` (= `solve`, `build`) | no | parse, stage, solve every shot; writes `camera_<shot>.json`; predicted coverage + faces in band; 2-run stability |
| `.\tools\lens\run_lens.ps1 shoot <id> [shot=P02] [res=1600x900,3440x1440]` (= `sheet`) | yes | stills + measured coverage, face in band, occlusion, contrast; `sheet.png` |
| `.\tools\lens\run_lens.ps1 marks <id> set=<set_id> [prefix=P]` | no | solve the shots on a stage set's puppets -> `marks.json` (contract format) |
| `.\tools\lens\run_lens.ps1 icons <id> [only=a,b]` | yes | the spec's `icons` blocks -> `art/icons/lens/<kind>/<id>.png` + `icons_sheet.png` |
| `.\tools\lens\run_lens.ps1 portrait <id> [only=vessa]` | yes | the spec's `portrait` lines -> `art/portraits/<speaker>.png` + `portraits_sheet.png` |
| `.\tools\lens\run_lens.ps1 turnaround <res://scene.tscn or file name>` | yes | 8 views at 45 deg, one scale -> `out/turnaround_<name>/turnaround.png` |
| `.\tools\lens\run_lens.ps1 cinecheck <id> [cine=<cine id>]` | no | the baked `data/cinematics/<cine>.tres` uses this spec's cameras |
| `.\tools\lens\run_lens.ps1 demo` | yes | acceptance demo: check + shoot prose10, icons, portraits, cine bake + cinecheck |

`<id>` = `tools/lens/specs/<id>.lens` (or `src=res://path.lens`). Outputs: `docs/tools/lens/out/<id>/` (`report.md` /
`report.json` for check, `report_<verb>.*` for the others, PNGs, `camera_<shot>.json`, `camera.json` = first shot),
one row per run in `docs/tools/lens/history.md`. Exit codes: 0 PASS / WARN, 1 FAIL, 2 bad input, 3 watchdog.
Windowed verbs open a small window for ~1-3 minutes (do not close it).

## Spec grammar (`tools/lens/specs/<id>.lens`, shared ToolSpec reader: `#` comments, `key=value`, indented children)
| Line | Keys | Meaning |
|---|---|---|
| `lens <id>` | `res=WxH[,WxH]` (1600x900) `band=2.39` `fov=40` `light=` `rim=` `bg=` | optional header, defaults for every shot (outputs use the file name) |
| `use cine=res://x.cine` | | the `.cine`'s `cast <tag> <res> at= yaw=` lines become subjects (camera solved on cine's stage) |
| `subject <tag> <res://scene.tscn>` (or `cast`) | `at=(x,y,z)` `yaw=<deg>` `pose=<hook>[:<arg>]@<sec>` `scale=` | a model; facing = (sin yaw, 0, cos yaw), like cine |
| `shot <id> "<words>"` | `res= band= fov= light= rim= bg=` | one framing (id = identifier: `P01`, `L2`) |
| `  frame <size> on <tag>` | `angle= height= comp= lead= dutch= push= truck= crane= arc= fov=` | same vocabulary as the words, instead of the quoted text |
| `  subject ...` / `  light preset= rim=` / `  bg flat=#hex \| ground=#hex \| set=<set_id>` / `  out 1600x900 3440x1440 [band=]` | | shot-only overrides |
| `icons <group>` | `kind=units\|buildings size=256 yaw=30 pitch=20 fill=0.65 fov=30 bg=kingdom\|flat\|none light=studio` | an icon batch |
| `  icon <id> <res://scene.tscn>` | `faction=fire\|ice\|nature\|shadow\|neutral kind= yaw= pitch= fill= hide=Node,Node` | one icon |
| `portrait <speaker> <res://scene.tscn>` | `frame=cu angle=3/4-right height=eye size=512 faction= light=` | one portrait |

Lights: `studio` (key / fill fixed to the camera), `warm` / `ice` (the map LightingPresets), `dusk`, `night`, `set` (the
stage set's own preset). `rim=warm|cool|off`. Backgrounds: `#hex`, `ground:#hex` (a ground plane), `set:<set_id>`
(`art/cinematics/stage_sets/<id>/<id>.tscn`; its `Puppets/<tag>` are subjects by tag).

## Framing words
`"<size> on <tag>[ and <tag>], <angle>, <height>, <comp>, lead <side>, dutch <deg>, push <0..1>"`, comma separated,
any order after the first part. Unknown words FAIL with the nearest valid word.
| Word | Values |
|---|---|
| size | `ecu cu mcu ms cowboy fs ws ews`, `<size> two-shot a b` (or `ms on a and b`), `<size> ots a over b` (camera behind a's shoulder, framing b; also `, ots a` after `mcu on b`) |
| angle | `front 3/4-left 3/4-right profile-left profile-right back 3/4-back-left 3/4-back-right` (spaces ok: `3/4 left`) or `angle=<deg>`. **3/4-left = the camera stands on the subject's LEFT** (it looks toward frame left) |
| height | `eye low high overhead ground` (camera elevation 0 / -14 / +20 / +70 / -28 deg) or `height=<deg>` |
| comp | `center thirds-left thirds-right`; default `auto` = lead room: a subject seen from the side goes on the opposite third |
| moves (camera `b`) | `push <0..1>` (toward the subject), `truck <m>` (right), `crane <m>` (up), `arc <deg>` (around) |
| other | `dutch <deg>` (roll), `fov <deg>`, `lead left\|right` |

**Coverage s** (the number every report shows) = the Head pivot's height on screen / the 2.39 band height for `ecu cu
mcu ms cowboy`, the whole subject's height / band for `fs ws ews`. Targets: `ecu` 1.25; `cu mcu ms cowboy` from a **cut
line** (band bottom at 12 / 35 / 55 / 75 % of the way from the chin to the feet, head top 8 % under the band top), so
big-headed stylised models frame like realistic ones; `fs` 0.8, `ws` 0.35, `ews` 0.12. `check` predicts s from mesh
vertices; `shoot` measures it: PASS within +-10 %. Face in band = >= 90 % of the head mask rows inside the band.
Icons: silhouette = `fill` of the tile (rule 55-75 %), centred +- 5 %, refined on the pixels. Portraits: the size's
cut-line rule on a square tile without bars (the wizards use `mcu` so hats / antlers fit).

## Complete example
```
# tools/lens/specs/two_wizards.lens
lens two_wizards  res=1600x900  band=2.39  light=studio  rim=warm  bg=#1b1a1f
subject vessa  res://art/units/wizards/vessa.tscn  at=(0,0,0)      yaw=0
subject shade  res://art/units/shadow/shade.tscn   at=(1.6,0,0.7)  yaw=250
shot V1 "mcu on vessa, 3/4 left, low"
shot V2 "cowboy two-shot vessa shade"
shot V3 "mcu ots vessa over shade"
shot V4
  frame ms on vessa  angle=3/4-right  height=low  comp=thirds-left  push=0.15
  light preset=dusk rim=cool
icons mounts  kind=units  size=256  fill=0.72  bg=kingdom
  icon ember_boar  res://art/units/mounts/ember_boar/ember_boar.tscn  faction=fire
portrait vessa  res://art/units/wizards/vessa.tscn  frame=mcu  angle=3/4-right  size=512  faction=fire
```
```
.\tools\lens\run_lens.ps1 check two_wizards      # cameras + predicted metrics (headless, ~30 s)
.\tools\lens\run_lens.ps1 shoot two_wizards      # look at docs/tools/lens/out/two_wizards/sheet.png
.\tools\lens\run_lens.ps1 icons two_wizards      # art/icons/lens/units/ember_boar.png
.\tools\lens\run_lens.ps1 portrait two_wizards   # art/portraits/vessa.png
```
Reading a failure: `FAIL S_V2_cov ... two-shot too wide` -> move the subjects closer or pick a wider size; `FAIL
F_V1_..._band_vessa` -> face outside the 2.39 band: use `eye` or a wider size; `R_..._occl` -> something covers the
subject (the report names the shot; pick another angle); `U_<icon> at 48 px` WARN -> dark model on a dark kingdom
background: add `rim=` / another `bg=`.

## CameraSpec (contract 13.2, tool 3 -> tool 2)
`docs/tools/lens/out/<id>/camera_<shot>.json`:
`{shot, words, size, pos: [x,y,z], look: [x,y,z], fov, roll, a: {pos, look, fov}, b: {pos, look, fov}, res, band,
target_s, pred_s, head_ndc: {tag: [x,y]}}`. `a` = start camera, `b` = end camera (push / truck / crane / arc), fov in
degrees (Camera3D vertical, keep-height). In a `.cine`: `shot L1 4.0 cam=lens "mcu on vessa, 3/4 left, low"
lens_spec=res://docs/tools/lens/out/<id>/camera_L1.json` (solve with `use cine=<that .cine>` so both see the same cast;
example: `specs/lens_demo.lens` + `specs/lens_demo.cine`).

## Library use (cine at bake time, World Forge marks) - no files, no window
```gdscript
var subs := {"vessa": LensSolver.subject(Vector3(0, 0, 0), 0.0, 1.9)}          # feet, yaw deg, height (no model)
# or measured from a live model (Head pivot + mesh vertices, works headless):  LensSolver.subject_of(model_node, yaw_deg)
var cam := LensSolver.solve_words("mcu on vessa, 3/4 left, low", subs, {"res": Vector2i(1600, 900), "band": 2.39, "fov": 40.0})
if cam["ok"]:
	shot.from_pos = cam["a"]["pos"]; shot.to_pos = cam["b"]["pos"]
	shot.look_from = cam["a"]["look"]; shot.look_to = cam["b"]["look"]
	shot.fov_from = cam["a"]["fov"]; shot.fov_to = cam["b"]["fov"]    # CameraMode DOLLY
else:
	for e: Dictionary in cam["errors"]: print(e["message"], " -> ", e["hint"])   # "did you mean ..."
var json := LensSolver.to_json(cam, "P11")    # the CameraSpec dictionary; LensSolver.from_json(path) reads one back
```
Other statics: `parse_words(words, known_tags)`, `solve(parsed, subjects, opts)`, `project(xform, fov, aspect, point) ->
ndc`, `band_frac(res, band)`, `solve_fit(aabb, facing_yaw, yaw, pitch, fill, fov)` (icon / turnaround fit), `SIZES`,
`ANGLES`, `HEIGHTS`. Result keys: `pos look fov roll a b size subjects target_s pred_s head_ndc band_frac xform`.

## Files
`lens_main.gd` (CLI), `lens_solver.gd` (`LensSolver`, pure math), `lens_doc.gd` (`LensDoc`, spec reader), `lens_stage.gd`
(`LensStage`: staging, poses, lights, ID passes), `lens_measure.gd` (`LensMeasure`: masks, contrast, 48 px legibility),
`run_lens.ps1`, `specs/` (`prose10`, `audit_icons`, `wizard_portraits`, `lens_demo` + `.cine`, `watch_keep_marks`).
Test: `tests/test_tool_lens.gd` (prints `PASS tool_lens`).

## Notes / limits
- Idle animations sway models by +-4 cm: bounds are the mean over ~4 s (13 samples); stills freeze the models after
  measuring. Two stagings agree within 80 mm (check D2 PASS; WARN to 120 mm: the sway alone can move bounds ~+-4 cm
  per staging), the solver itself is byte-deterministic (D1). Scores use the shared `ToolReport.grade()`.
- Lens never edits other owners' files: icons go to `art/icons/lens/`, portraits to `art/portraits/`, marks to its own
  out folder (World Forge merges them). The icon libraries adopt the new PNGs later (their owner).
- Pixels need a window (the dummy renderer draws nothing). At most 2 Lens windows at once on a shared PC.
