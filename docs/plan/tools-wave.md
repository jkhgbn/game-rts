# Tools wave: 10 custom tools for agents (Movie Maker first)

Written 2026-09-27 ~00:05 by the production planner for the lead. User request: the NEXT wave is ~10 agents building
**custom tools** that make possible what was impossible before, or make design much faster, starting with the
**Movie Maker** (the Cinematic Toolkit of `waves.md` step 19.0 + `prologue-movie-plan.md` + `docs/design/cinematics.md`).
Inputs read: `CLAUDE.md`, `waves.md` (19.0, 19, 20, Labs program), `prologue-movie-plan.md`, `cinematics.md`,
`art-audit-2026-09-26.md`, the lab docs, `art/units/kit/README.md`, the builders of the Glade Outrider rider (38 KB),
the Elder Treant (`treant_mesh.gd` 41 KB + `elder_treant.gd` 34 KB) and the heath (`build_heath.gd` 38 KB).

---

## 0. The framing: every user of these tools is a Claude Code agent

No human runs these tools. The user only sees what they produce (a scene, a sheet of icons, a model, a movie). So a
tool is good when an agent with **only its README and a one-line brief** can get a correct result in a few runs. Rules
for all 10 tools (frozen by the lead at T0 in `docs/plan/tools-wave-agent-rules.md`):

| Rule | What it means |
|---|---|
| **Text in** | Input is a short, diffable text spec (one file per asset / scene), never an editor session. Coordinates only when nothing better exists (markers, framing words, areas, symmetry). |
| **One CLI** | `tools/<tool>/run_<tool>.ps1 <verb> <id> [key=value...]` (goes through `tools/godot_run.ps1`; quotes `'--'`). Verbs every tool has: `help` (grammar + a complete example), `check` (headless, < 60 s, exit 0 PASS/WARN, 1 FAIL, 2 bad input), `build`, `sheet` (windowed stills), `demo` (re-runs its acceptance demo). |
| **Readable out** | `docs/tools/<tool>/out/<id>/report.md` + `report.json` + PNGs. Report = the lab scorecard format (PASS / WARN / FAIL, measured value, rule, fix hint, score 0-100, **"Improve next"**), plus one history row in `docs/tools/<tool>/history.md`. PNGs are made to be looked at by an agent: labelled contact sheets, one question per image (framing, silhouette, timing, spectrogram). |
| **Errors that teach** | Every parse / resolve error names the file, line, the token, and the nearest valid value (`unknown actor "torvlad" (line 12) -> did you mean "torvald"?`). |
| **Self-validating** | Each tool checks its own output (budgets, determinism hash of two runs, lab run) and fails loudly. Own test `tests/test_tool_<id>.gd` prints `PASS tool_<id>`. |
| **Deterministic** | Same spec + seed = same bytes (mesh / wav / tres) and the same frames at `--fixed-fps`. Reports print the hash. |
| **Headless first** | Parse, build, measure headless. Pixels need a windowed run (dummy renderer draws nothing and **drops MultiMesh transforms**: bake to `ArrayMesh`). At most 4 Godot runs machine-wide (the gate). |
| **Plugs into the Labs** | A tool calls the right lab itself at the end of `build` (section 12) and folds its score into its report. |
| **No asset surgery** | Tools write **new** files in their own folders; they never rewrite another owner's asset. A tool that "fixes" something writes a variant and a note for the owner. |
| **Original only** | No names, art, sound or music from existing works; generated audio only; no downloads. |

**The "impossible before -> possible now" gate.** Each tool has one acceptance demo (sections 2-11): a concrete
thing nobody could make before in reasonable time, made **from text only**, checked by numbers, not taste. An agent
keeps working on its tool until the demo passes (cap: section 14). Then a **cold-start usability trial** (section 13):
a fresh medium-effort agent gets only the README + a one-line brief and must reproduce a variant of the demo. A tool
that only its author can use is not done.

---

## 1. The 10 tools at a glance

| # | Tool (folder) | Agent | Effort | One line | Share of a 5-h window |
|---|---|---|---|---|---|
| 1 | **Cinematic Runtime** (`scripts/cinematics/`, `scripts/ui/cinematic/`) | systems-coder-high | [H] | The player of `cinematics.md`: timeline, 6 camera modes, actors, cues, overlay (2.39 letterbox, subtitles, skip lock), cast proxy, recording mode | ~5 % |
| 2 | **Movie Maker CLI `cine`** (`tools/cine/`, `data/cinematics/`) | four-wizards-high | [H] | `.cine` text timeline -> baked `CinematicScript`, checks (timing, framing band, 180-degree rule, cue resolve), stills, animatic, timing sheet, record | ~6 % |
| 3 | **Lens** shot composer + icon / portrait studio (`tools/lens/`) | four-wizards-high | [H] | Framing words ("mcu on vessa, 3/4 left, low, thirds left") -> camera solve, stills, markers; icons / portraits with one framing rule | ~4 % |
| 4 | **Model Forge** procedural model DSL, kit v2 (`tools/model_forge/`, `art/forge/`) | four-wizards-high | [H] | Compact part spec (lathe / loft / sweep / mirror / pivots / palette slots / LOD) -> CharacterModel scene + turnaround + Art Lab | ~6 % |
| 5 | **Motion Lab** animation from text (`tools/motion/`, `art/motion/`) | four-wizards-high | [H] | Pose library + keyframe clips + gait generator -> `play_clip(id)` on any kit model, filmstrips, foot-slide / timing checks | ~5 % |
| 6 | **World Forge** stage sets + map layouts (`tools/world_forge/`, `data/maps/`) | four-wizards-high | [H] | Set spec (place / scatter / paths / marks) -> set-contract scene; map spec (quadrant + symmetry) -> layout + Map Lab | ~6 % |
| 7 | **VFX Composer** (`tools/vfx_composer/`, `art/vfx/composer/`) | tech-artist | M | Layered effect recipe -> one pooled family (0 lights), preview sheet at 6 m / 40 m on 3 grounds, Art Lab `kind=vfx` | ~4 % |
| 8 | **Palette Studio** (`tools/palette_studio/`, `art/palettes/`) | tech-artist | M | Style bible -> palette LUTs, restyled mesh / material variants (no builder edits), contrast matrix units x grounds | ~3 % |
| 9 | **Sound Forge** synth (`tools/sound_forge/`, `assets/audio/forge/`) | ui-coder | M | Layered synth / music spec -> WAV takes + spectrogram PNG + Audio Lab; descriptor check (bright / dark, attack, length) | ~3.5 % |
| 10 | **Script Desk** dialogue / story (`tools/script_desk/`, `data/story/`) | ui-coder | M | Screenplay text -> line tracks for `cine` and missions, subtitle / CPS checks, table-read timeline PNG, story-doc extractor | ~2.5 % |
| (11) | **Scene Director** (phase B, optional) (`tools/director/`) | four-wizards-high | [H] | One scene brief -> runs tools 2-10 in order -> one review pack | ~3 % |

The Cinematic Toolkit (step 19.0, "6-8 agents") becomes tools 1 + 2 plus reusable pieces of 3, 5, 6, 7, 9, 10. The
prologue window (`prologue-movie-plan.md`) then shrinks from 19 agent tasks to specs + a few fix rounds (section 16).

**Shared base (lead, T0, <= 25 min): `tools/common/`** (read-only for agents): `tool_cli.gd` (`key=value` after `--`,
`help` from a table, exit codes), `tool_report.gd` (scorecard md / json / history row: a thin wrapper over
`tools/art_lab/lab_report.gd`'s format), `tool_sheet.gd` (labelled contact-sheet grid, 2.39 band / safe-area overlay),
`tool_capture.gd` (SubViewport render at W x H, wait N frames, save PNG; windowed only), `tool_spec.gd` (the shared
line-based spec reader: `keyword arg arg key=value ...`, indentation blocks, `#` comments, `@marker` / `res://` / `#hex`
/ `a>b` (from -> to) / `a..b` (range) tokens, line numbers kept for errors). Using one reader keeps all 10 formats alike.

---

## 2. Tool 1 [H] Cinematic Runtime (the player)

**Purpose.** The engine side of the Movie Maker: plays a `CinematicScript` deterministically in STAGE and PAUSE mode
(HOLD later with missions), with the overlay, skip lock and recording mode. Built exactly to `cinematics.md` 2-6, 8.3,
11 + `prologue-movie-plan.md` 2.2-2.5 (`skip_locked_until`, `stage_set`, `marker_prefix`, set contract, CastProxy).

**Impossible today and why.** No `scripts/cinematics/` exists: nothing can play a camera move, a subtitle or a timed
cue. Every "scene" would be a hand-written `_process` with tweens that cannot skip, pause, repeat frame-exactly or be
checked headless.

**Format / API sketch.** Resources `CinematicScript`, `CinematicShot`, `CinematicLine`, `CinematicAction` (fields of
`cinematics.md` 2 + the prologue additions). `CinematicPlayer`: `play(script, context)`, `play_from(shot_index)`,
`seek(t)` (**new, for tools**: jump to any time and apply end states of earlier actions, so stills of shot 20 do not
need 2 minutes of play), `elapsed()`, `shot_index()`, signals `shot_started(i, id)`, `line_shown(line)`,
`action_fired(action)`, `finished(skipped)`. Action kinds of `cinematics.md` 2.4 + `clip` (tool 5 `play_clip`),
`vfx` with `vfx_id` routed to a hub (tool 7 `VfxComposer` or the existing hubs), `sfx` / `music` by path. `CinematicStage`
(set switching, prewarm under black, render scale, recording mode), `CinematicInput`, `CastProxy`, `CinematicOverlay`
(bars formula, subtitles 2 x 48, speaker colours, skip prompt with lock, pause view, fades, title card), `Speakers`.
A **probe API for tools**: `debug_state() -> Dictionary` (camera xform, fov, active set, visible actors, current line)
so `cine check` can test framing headless without pixels.

**Owns.** `scripts/cinematics/` (all files above + `cast_proxy.gd`), `scripts/ui/cinematic/` (`cinematic_overlay.gd`,
`speakers.gd`), `tests/test_tool_cine_runtime.gd`. Minimal touches: none (the lead adds the 3 Input Map actions and
`Events.cinematic_started(id)` / `cinematic_finished(id, skipped)` at T0).

**Depends on.** Nothing. **Everyone waits on its resource scripts**: milestone M1 at ~0:25 = the 4 resource classes
parse and are frozen (the lead relays to tools 2, 6, 10).

**Acceptance demo ("impossible -> possible").** A synthetic 4-shot script built **in code, no scene editing** (STATIC,
DOLLY, ORBIT from markers, RAIL) with 3 lines, a fade, a `clip` and a `vfx` action plays headless: finishes at frame
N +- 1 at `--fixed-fps 60`; two runs give identical camera transforms at 10 sample times; `seek(t)` then 1 frame equals
the same frame reached by playing; skip ignored before `skip_locked_until`, two presses after, one when seen; pause
adds 0; PAUSE mode restores every `process_mode` it changed; recording flag path covered; bars 115 / 43 / 32 px at
1600 x 900 / 3440 x 1440 / 2560 x 1080; 0 lights created.

**Labs.** Perf Lab probe hook (frame ms per shot, used by `cine perf`); Error Lab reads its logs.

**Effort / share.** [H], ~1.5-2 h, **~5 %**. **Risks.** Scope creep into HOLD / missions (out of scope: HOLD is a stub
that refuses with a clear message); `seek` correctness for tweens-in-flight (end states are data, so it is exact for
the listed kinds; `call` actions run on seek only if `on_skip`).

---

## 3. Tool 2 [H] Movie Maker CLI `cine`

**Purpose.** The agent-facing movie maker: a compact `.cine` text timeline -> baked `data/cinematics/<id>.tres`, plus
the checks, stills and sheets an agent needs to judge a movie it cannot watch.

**Impossible today and why.** The prologue plan authors shots as GDScript blocks (`prologue_shots.gd`) and judges them
from 81 windowed stills by eye (gate G2). Nobody can ask "is Torvald's face inside the 2.39 band in P11?", "does the
camera cross the line between Vessa and the Shade at the P24 -> P25 cut?", "does line 17 fit its shot?", or "does
every cue exist?" before a full windowed run.

**Format sketch** (`data/cinematics/src/<id>.cine`, read by `tools/common/tool_spec.gd`):
```
cine prologue_ice  title="Torvald"  letterbox=2.39  skip_lock=0  seed=11
use set prologue_ice                       # stage set id (tool 6 or hand-made, set contract)
use lines data/story/prologue.lines.json   # tool 10 line track (lines per shot id)
shot P11 5.0  cam=dolly  from=@P11_from to=@P11_to  look=@P11_look_from>@P11_look_to  fov=38>32  in=cut
  at 0.4  clip   torvald staff_slam            # tool 5 clip (falls back to play_cast)
  at 1.1  vfx    flash_freeze  from=torvald to=@P11_target
  at 1.1  sfx    forge/ice/ice_crack_big       # tool 9 path under assets/audio/
  at 3.0  shake  0.3
shot P12 3.5  cam=lens "ws on torvald, low, thirds left"  in=cut   # tool 3 solves it at bake time
shot P13 4.0  cam=orbit pivot=torvald r=6 h=2.2 deg=200>250  in=fade_black:0.4
```
**CLI.** `run_cine.ps1 check <id>` (headless: parse, resolve every set / marker / actor / clip / vfx / sfx / line,
bake, play at 60 fps with the runtime's `debug_state()`: timing, framing of named actors projected into the 2.39 band,
**180-degree rule** across cuts between the same two actors, jump-cut warning (same framing +- 10 % across a cut),
subtitle fit and CPS, determinism hash of two runs) · `stills <id> [shot=P11] [res=1600x900,3440x1440]` (windowed:
frames a / b / c per shot with band + safe area; contact sheet) · `animatic <id>` (grey capsules named after the actors
and grey boxes for missing sets, so a movie can be judged before any art exists) · `sheet <id>` (timing sheet PNG:
shot bars, line bars, cue ticks, music blocks) · `perf <id>` (windowed: ms per shot, draw calls, worst frame) · `play`
(windowed live) · `record <id> [fps=30 res=1920x804]` (Movie Maker, output outside `res://`, `.avi` if `.ogv` is not
available: never downloads ffmpeg; see question 2) · `diff <id>` (stills vs the previous run: which shots changed).

**Owns.** `tools/cine/`, `data/cinematics/` (sources `src/*.cine` + baked `*.tres`), `missions/cinematics/tool_demo/`
(its demo stage), `tests/test_tool_cine.gd`, `docs/tools/cine/`. Minimal touches: none.

**Depends on.** Tool 1 resource classes (M1, ~0:25; builds its parser / checks against the frozen field list before
that). Optional at bake time: tool 3 (`cam=lens`), 5 (clip ids), 7 (vfx ids), 9 (paths), 10 (line tracks), 6 (sets):
each missing one degrades to a WARN + animatic proxy, never a crash.

**Acceptance demo.** A 45-60 s, 8-shot scene **"The Watch-Keep"** (Vessa on the Fire keep walls at nightfall, a Shade
appears, knife glint, cut to black) written as one `.cine` of <= 80 lines, using existing models only (Vessa, Shade,
Fire keep) and a set made by tool 6 (or the animatic fallback): `check` PASS (0 FAIL, framing band PASS for every
named face, no 180-degree break), `stills` sheet produced, `sheet` timing PNG produced, two runs hash-identical, and a
**planted-bug file** (a crossed axis, an overlong line, a missing marker, an unknown clip) gets exactly 4 FAILs with
fix hints. Recording a 10 s `.avi` windowed works (or reports why).

**Labs.** Visual Diff Lab: `stills` can register a scene's shots as goldens (a model change that breaks a movie shows
up). Perf Lab numbers in `cine perf`. Data Lab: line text fits.

**Effort / share.** [H], ~2 h, **~6 %**. **Risks.** Headless framing check without pixels (use `debug_state()` +
actor AABBs / `Head` pivot projection: exact enough); Movie Maker not headless (record is windowed-only, flagged in the
help); format sprawl (the grammar lives in one table in the README; unknown keys FAIL).

---

## 4. Tool 3 [H] Lens: shot composer + icon / portrait studio

**Purpose.** Turn framing words into a camera. Stage subjects (model scenes, optional pose at a time), solve the camera
from their bounds and a framing vocabulary, light it with a `LightingPreset`, and render / measure. Special modes for
game icons and dialogue portraits with one consistent rule.

**Impossible today and why.** Three separate icon renderers (`render_icons.gd`, `render_champion_icons.gd`,
`render_trade_icons.gd`) each hand-place a camera; the art audit lists ~25 missing unit / titan / building icons and 12
missing portraits. Set artists place `<shot>_from` markers by typing numbers and checking windowed previews. No tool
can answer "how much of the frame is the subject?", "is the face in the band?", "is the subject readable against the
background?".

**Format sketch** (`tools/lens/specs/<id>.lens`):
```
shot vessa_mcu
  subject vessa  res://art/units/wizards/vessa.tscn  at=(0,0,0) yaw=20  pose=play_cast:fireball@0.35
  subject shade  res://art/units/shadow/shade/shade.tscn  at=(2.5,0,1) yaw=200
  frame mcu on vessa  angle=3/4-left  height=low  comp=thirds-left  lead=right
  light preset=dusk  rim=warm
  bg set:prologue_fire | ground:meadow | flat=#1a1410
  out 1600x900 3440x1440  band=2.39
icons units kingdom=nature  frame=bust  size=256  bg=kingdom  rim=team     # batch mode
portrait speaker=vessa  frame=cu  angle=3/4-right  size=512
```
Vocabulary: `ecu cu mcu ms cowboy fs ws ews`, `two-shot a b`, `ots a over b`, angles `front 3/4-left profile-right
back`, heights `eye low high overhead dutch=10`, compositions `center thirds-left thirds-right`, lead room.
**CLI.** `run_lens.ps1 solve <id>` (headless: camera transform + fov to `camera.json`, metrics from bounds) · `shoot
<id>` (windowed stills + measured metrics from pixels: subject coverage via an ID pass, occlusion %, luminance / dE
contrast subject vs background, head inside band) · `marks <id> set=<set> prefix=P11` (writes `Marker3D`s `_from / _to
/ _look_from / _look_to` into a **marks file** the set reads, see tool 6) · `icons <kind> [kingdom=]` (every model
without an icon, uniform framing, sheet) · `portrait <speaker>` · `turnaround <scene>` (8 views, used by tools 4 / 5).

**Owns.** `tools/lens/`, `art/icons/lens/` (new icons, beside the existing ones), `art/portraits/` (new folder,
`cinematics.md` 1), `tests/test_tool_lens.gd`, `docs/tools/lens/`. Minimal touches: none (the icon libraries adopt the
new files later by their owner; the report lists the paths).

**Depends on.** Nothing at start. Serves tools 2 (`cam=lens`), 4 / 5 (turnarounds), 6 (marks).

**Acceptance demo.** (a) Every missing icon of the art audit (units: Cinderlock, Frostrune, Glade Outrider, Mossback,
4 riders, Barrow Giant, 5 titans, Mage Archer, Wildcaller; buildings: Dragon Roost, Dread Paddock, Ember Crucible,
Tavern, Trade Post, Watchtower, Wayshrine, Essence Well) rendered by **one command** with one framing rule, sheet +
per-icon metrics (subject 55-75 % of the tile, centred +- 5 %). (b) The 4 wizard portraits at 512. (c) 10 prose
framings solved headless: measured coverage within +- 10 % of the vocabulary target and the face in the band in 10 / 10
when checked windowed. (d) `cine` bakes a `cam=lens` shot.

**Labs.** UI Lab (icon legibility at 48 px), Data Lab (icon present per `UnitType` / `BuildingType`), Art Lab uses its
turnaround later.

**Effort / share.** [H], ~1.5 h, **~4 %**. **Risks.** Models with bad `body_height` (the wizards: head top 1.3-1.47 x)
break bust framing: use the measured mesh AABB of the `Head` pivot, not `body_height`; ID pass needs a windowed run.

---

## 5. Tool 4 [H] Model Forge: procedural model DSL (kit v2)

**Purpose.** Describe a creature, character, prop or building in a compact part spec; get a kit-compatible model
(pivots, merge, palette materials, glow / team-cloth tags, LODs), a turnaround sheet and an Art Lab scorecard in one run.

**Impossible today and why.** Every model is hundreds of lines of hand GDScript (Glade Outrider rider 38 KB, Elder
Treant 75 KB of mesh + rig code, heath 38 KB): shapes are constants inside code, there is no lathe / loft / sweep, no
automatic LOD, and the Art Lab is a separate manual step. A new story character (Old Vey, Mother Hush, the Master) or a
silhouette fix (Nature heavies "blob", Colossus vs Stump IoU 0.80) costs a full agent session per iteration.

**Format sketch** (`art/forge/specs/<id>.forge`):
```
model old_vey  rig=humanoid  height=1.95  face=+z  kingdom=neutral  attack_style=sword_slash
palette robe=unit_warden_cloth beard=#d8d4cc steel=unit_gold_trim glow=lightning  # kit palette names or new hex (-> variant)
part robe    lathe  profile=[(0,0.30),(0.95,0.26),(1.35,0.20)]  seg=10  pivot=hips  mat=robe  cloth
part hood    loft   sections=[circle(0.16)@1.55, circle(0.12)@1.75, point@1.90 z=-0.08]  pivot=head mat=robe cloth
part beard   cone   r=0.12 h=0.35  at=head(0,-0.10,0.12) tilt=15  mat=beard
part sword   sweep  path=[(0,0,0),(0,1.05,0)] section=blade(0.06,0.012) taper=0.3  pivot=arm_r grip=(0,-0.52,0) mat=steel
  glow edge  mat=glow  own_glow
mirror pauldron x
deform robe  noise=0.02 seed=4
lod 30m: seg*0.5 drop=beard_strands ; 45m: merge=all
budget verts<=3000 draws<=8 glows<=2 lights=0
```
Primitives: the kit's (`cyl sphere box capsule torus prism cape`) + `lathe`, `loft`, `sweep` (polyline / bezier with a
section and taper), `extrude` (2D outline), `array` (radial / linear), `mirror`, deforms (`bend taper twist noise`),
`scatter` (leaves / plates on a part's surface, baked, never MultiMesh). Rigs: `humanoid`, `quadruped`, `rider`,
`flyer`, `static` (buildings / props) = the kit pivot layouts.
**CLI.** `run_model_forge.ps1 build <id>` (headless mesh bake + cache `.res`, budgets; then windowed turnaround 8
views + silhouette + Art Lab `quick=1`) · `diff <id>` (vs the previous build: silhouette IoU, verts / draws delta,
colour dE on the lab ground) · `explode <id>` (sheet with each part labelled: the agent sees which line made which
shape) · `from <scene>` (import helper: measures an existing model into a starter spec of pivots + bounds).

**Owns.** `tools/model_forge/`, `art/forge/` (`forge_model.gd` = `ForgeModel extends CharacterModel` reading a baked
`ForgeSpec` resource, `specs/`, `models/<id>/`), `tests/test_tool_model_forge.gd`, `docs/tools/model_forge/`. Minimal
touches: none (new palette entries go as a request to the kit owner's `make_materials.gd`; until then variants live in
`art/forge/materials/`).

**Depends on.** Nothing at start; tool 3 for turnarounds (falls back to its own capture), tool 8 for palettes (later).

**Acceptance demo.** (a) **NEW: Old Vey** (`story-episode-1.md` 2: old wizard, sword, lightning) from a spec of <= 200
lines: walks, attacks, casts, dies through the kit hooks; Art Lab `kind=unit` >= 92 with 0 FAIL; <= 3 000 verts.
(b) **REBUILD: Sprigling** from a spec that also applies the audit fixes (off-grass main colour, team colour >= 20 % of
the top area, body_height to the head top): Art Lab >= 93 (today 88 FAIL) in fewer spec lines than today's script has
lines / 4. (c) Same spec twice = identical mesh hash. (d) A planted over-budget spec FAILs with the part that costs most.

**Labs.** Art Lab (every build), Perf Lab (instanced crowd cost later), Visual Diff (turnaround goldens).

**Effort / share.** [H], ~2 h, **~6 %**. **Risks.** Loft / sweep normals and seams (test on a known cylinder);
instance-uniform slot rules of the kit (use the kit shaders only); scope: no marching cubes / sculpting (out).

---

## 6. Tool 5 [H] Motion Lab: animation from text

**Purpose.** Author poses, clips and gaits as text for any kit rig, play them with one hook, and see them as filmstrips
with measured quality (foot sliding, ground penetration, timing events, loop seams).

**Impossible today and why.** Animation is procedural code inside each model (`_pose_cast`, `_extra_process`, sin
curves; 27 pose references in `elder_treant.gd` alone). A gesture cannot be reused across models: the prologue plan
needed 5 files edited for 7 gestures (19.P15). Nobody can see a motion without a windowed run and a human; foot sliding
and strike timing have never been measured.

**Format sketch** (`art/motion/clips/<id>.motion`):
```
pose guard_high  rig=humanoid  chest=(0,-10,0) arm_r=(-120,0,15) arm_l=(-40,0,-10)
pose wind_up     chest=(0,-35,0) arm_r=(-150,0,20) hips=(0,-10,0) root.y=-0.05
pose strike      chest=(0,25,0)  arm_r=(-20,0,-10) root.z=0.12
clip vey_overhead_strike  len=0.9  loop=no  blend_in=0.1
  key 0.00 guard_high
  key 0.30 wind_up  ease=in_cubic
  key 0.42 strike   ease=out_expo  event=release
  key 0.90 guard_high ease=in_out_sine
gait trot  rig=quadruped  legs=[fl,fr,bl,br] phase=[0,0.5,0.5,0] stride=0.9 lift=0.18 speed=3.2
gesture nod  additive  head=(12,0,0)@0.15 (0,0,0)@0.35
```
**CLI.** `run_motion.ps1 check <clip>` (headless: rig match, joint ranges per rig table, event times vs the model's
`attack_windup`, loop seam, sampled foot positions -> sliding cm per stride, ground penetration, arm-through-body via
sphere proxies) · `strip <clip> model=<scene>` (windowed filmstrip: side + front, 8 frames, onion skin, event frames
marked) · `curves <clip>` (PNG of every pivot angle vs time) · `audit dir=res://art/units/<kingdom>` (measures the
existing procedural walks: sliding numbers for every unit).
**Runtime.** `MotionClip` / `MotionPose` / `GaitSpec` resources, `MotionPlayer` (child node, writes pivot offsets
additively after the kit's pose, 0 allocation per frame), hooks `play_clip(id)`, `play_gesture(id)` (the 19.P15 names).

**Owns.** `tools/motion/`, `art/motion/`, `tests/test_tool_motion.gd`, `docs/tools/motion/`. **Minimal touch:**
`art/units/kit/character_model.gd`: <= 40 additive lines (a guarded `play_clip` / `play_gesture` that forwards to a
`MotionPlayer` child and a post-pose apply call). Nobody else edits the kit in this wave; `test_kit_team_color` and
`kitfix_glow_check --audit` must still pass.

**Depends on.** Nothing at start; tool 3 (strips) optional; tool 4 models get it for free (they are CharacterModels).

**Acceptance demo.** (a) The 7 cinematic gestures (`turn_head_left/right`, `nod`, `laugh`, `read`, `pinch`,
`raise_staff`) + `kneel` + `point` authored once as text and played on **all 4 wizards and Old Vey** through one hook
(19.P15 becomes a data file); (b) a **sword exchange** (Vey strike / Hush parry, 2 clips timed so the blades meet at
the event frame +- 1 frame, measured from the weapon tips); (c) `audit` prints foot sliding for 10 existing walkers
(never measured before) and one gait spec fixes the worst below 3 cm per stride; (d) a planted clip (release at 0.3 s
on a 0.12 s windup unit) FAILs.

**Labs.** Art Lab (poses at the lab's phases), Visual Diff (filmstrip goldens), Perf Lab (MotionPlayer cost at 200
units; must be ~0 when idle).

**Effort / share.** [H], ~1.75 h, **~5 %**. **Risks.** Fighting the kit's own procedural pose (apply after it,
additive; `override` flag per pivot); rotation sign rules of the kit README (tests from the side view).

---

## 7. Tool 6 [H] World Forge: stage sets and map layouts

**Purpose.** Place and scatter existing kits from text with rules (areas, gaps, avoid zones, paths, symmetry) to make
(a) cinematic stage sets that follow the set contract, with camera marks, and (b) skirmish map layouts with mirrored
spots, checked by the Map Lab before any map code exists.

**Impossible today and why.** Each prologue stage set is one [H] art agent placing nodes by coordinates for ~1 h
(7 sets = 7 agents). Map spots are hand constants in `scripts/world/skirmish.gd`; the 2v2 "Fourfold Hollow" needs
everything re-placed and mirrored 4 ways by hand, and the Map Lab can only judge after the code is written. No top-down
layout image exists before the scene does.

**Format sketch.** Set (`art/cinematics/stage_sets/<id>/<id>.set`):
```
set prologue_ice_forge  size=40x30  ground=snow  light=preset_ice  sky=horizon  budget draws<=150 lights=0
place  res://art/buildings/ice/ice_keep.tscn  at=(-8,0,-10) yaw=30
scatter kit:snow_pines  area=ring((0,0),14..20)  count=24  gap=2.2  seed=7  avoid=cams
path   river  poly=[(-20,5),(0,3),(20,8)]  width=4  kit=river_ice
actor  torvald  res://art/units/wizards/torvald.tscn  at=(0,0,0) yaw=180
marks  P11 lens "mcu on torvald, 3/4 left, low"
marks  P12 lens "ws on torvald, thirds left"
```
Map (`data/maps/<id>.map`): canonical quadrant table (keep, camps, points, posts, crossings, expansions, lairs),
`symmetry=mirror_x | rot180 | fourfold`, river polylines, roads, biome zones, cliffs.
**CLI.** `run_world_forge.ps1 set <id>` (builds the scene with a generated set-contract script: group
`"cinematic_sets"`, `begin_shot`, `set_active`, `puppet(tag)`, the `Shots` markers from tool 3; budget report; top-down
PNG with marks and camera frusta; Lens stills per mark) · `map <id>` (writes `data/maps/<id>_layout.tres` =
`MapLayout` resource: spots, river, crossings, roads, zones; builds a preview scene with navmesh; runs the Map Lab with
a generated profile; top-down PNG with spots, lanes and the heat map) · `export-map <scene>` (reads the live spots of an
existing map into a `.map` spec: round trip).

**Owns.** `tools/world_forge/`, `art/cinematics/stage_sets/forge_*` (its generated demo sets; real prologue sets get
their own folders later), `data/maps/` (new), `tests/test_tool_world_forge.gd`, `docs/tools/world_forge/`. **Minimal
touch:** `tools/map_lab/map_profiles.gd` + `map_lab.gd`: an additive `profile_json=<path>` argument (<= 30 lines;
Map Lab test must still print `PASS map_lab`). Never edits `skirmish.gd`: step 20 adopts `MapLayout` (systems-coder).

**Depends on.** Tool 3 for marks (falls back to explicit `from= / look=` coordinates); tool 1 for the set contract
test (uses `CinematicStage` if present).

**Acceptance demo.** (a) A new stage set of prologue quality from <= 60 spec lines in <= 3 build iterations: set
contract test PASS, <= 150 draws, 0 lights, all marks' Lens stills with the subject in the band; `cine` plays a shot in
it. (b) **Fourfold Hollow** from `map-2v2.md` 2.4 (quadrant A1 table) + `symmetry=fourfold`: layout built, navmesh bakes,
Map Lab symmetry PASS and score >= 90, before any step-20 code exists. (c) Round trip: Crown Hollow exported and rebuilt
= every spot within 0.1 m, Map Lab path table identical.

**Labs.** Map Lab (maps), Art Lab `decor_set` (sets), Perf Lab (set cost), Visual Diff (top-down goldens).

**Effort / share.** [H], ~2 h, **~6 %**. **Risks.** Two tools in one (sets first: the Movie Maker needs them; map mode
is the second half, cut to the "layout + Map Lab" core if short); nav bake time under the Godot gate; scatter must bake
to meshes (headless MultiMesh rule).

---

## 8. Tool 7 (M) VFX Composer

**Purpose.** Describe an effect as layers in text; get one pooled VFX family (preallocated, 0 lights, 0 nodes per
play after warm-up) with `play(id, at, target)` and a preview sheet an agent can judge.

**Impossible today and why.** Each family is a hand-coded manager of 20-55 KB (`cavalry_vfx.gd` 54 KB); the Perf Lab
found runtime nodes and 3 OmniLight3D in 4 managers; only 1 of ~18 families was ever scored; seeing an effect needs a
windowed run and a human. The story VFX (Old Vey's lightning, the storm, the regalia burst) do not exist.

**Format sketch** (`art/vfx/composer/recipes/<id>.vfx`):
```
vfx lightning_strike  family=story  pool=4  budget particles<=600 materials<=4 lights=0
  layer bolt   ribbon    from=caster.weapon_tip to=target+(0,6,0)>target  jag=0.35 seg=12 width=0.25  color=#bfe6ff>#ffffff  life=0.18 flicker=3
  layer flash  billboard size=3.5 at=target  color=#e8f4ff  alpha=1>0  life=0.12
  layer sparks burst     count=40 speed=6..12 spread=160 gravity=9 life=0.4..0.7 color=#9fd8ff
  layer scorch decal     ring r=1.2 color=#1a1a22 life=4 fade=1.5
  layer shock  ring      r=0.2>4.0 life=0.35 color=#cfefff alpha=0.8>0
```
**CLI.** `run_vfx_composer.ps1 build <family>` (headless: recipes -> `VfxRecipe` resources, budget, pool warm-up, 0
lights / nodes per play check) · `sheet <id>` (windowed: 8 frames x close 6 m and RTS camera 40 m x meadow / snow / ash
grounds; peak screen coverage, luminance peak = bloom risk, particles alive, ms) · `lab <family>` (Art Lab `kind=vfx`).

**Owns.** `tools/vfx_composer/`, `art/vfx/composer/` (`vfx_composer.gd` hub in group `"composer_vfx"`, layer
builders, shaders, recipes), `tests/test_tool_vfx_composer.gd`, `docs/tools/vfx_composer/`. Minimal touches: none.

**Depends on.** Nothing. Serves tool 2 (`vfx` actions) and later every VFX task.

**Acceptance demo.** (a) The 5 story VFX (Vey lightning strike, storm sky flashes, regalia burst, candle-out, knife
glint) from specs: Art Lab `kind=vfx` PASS, 0 lights, 0 nodes per play after warm-up, visible at 40 m. (b) The
`fireball` impact re-created from a spec next to the original: side-by-side sheet + Visual Diff similarity reported (the
lead judges), with <= 1 / 5 of the original's code. (c) A planted light layer FAILs.

**Labs.** Art Lab `kind=vfx`, Perf Lab (idle pooled cost must be ~0: stop emitters beyond 45 m).

**Effort / share.** M, ~1.5 h, **~4 %**. **Risks.** Ribbon / trail quality with GPUParticles only (use mesh ribbons
rebuilt per play from a pool); looks "generic" (the sheet makes it visible; the fix is recipe tuning, not code).

---

## 9. Tool 8 (M) Palette Studio

**Purpose.** Turn a style bible into palettes and restyled variants of existing meshes / materials without touching
their builders, and measure readability (units vs grounds) as a matrix.

**Impossible today and why.** Colours are constants inside each builder (`build_heath.gd` has 30+ `Color` consts), so
the GOLDEN AUTUMN reskin of Fourfold Hollow means editing and re-running ~24 builders owned by different agents.
"Green on green" (Nature army, dE 8 on heath) is found only after one Art Lab run per asset; nothing gives the contrast
of every unit on every ground at once.

**Format sketch** (`art/palettes/bibles/<style>.style`, first one encoded from `docs/art/style-autumn.md`):
```
style autumn  base=crown_hollow
  ground   hue=28..48  value=0.30..0.55  sat<=0.55
  foliage  map green(70..150) -> russet(18..32):60% gold(38..48):30% keep:10% value*0.8
  accent   lantern=#ffb347 glow  mist=#d9c7a8 alpha=0.35
  protect  team_cloth glow unit_*          # never remapped
  contrast units_vs_ground dE>=20  heath dE>=14  team_area>=0.20
```
**CLI.** `run_palette_studio.ps1 swatch <style>` (swatches + hue / value plots) · `restyle <target> style=<style>`
(vertex-colour LUT for baked `.res` meshes, albedo / uniform remap for `.tres` materials -> variants in
`art/palettes/variants/<style>/<mirrored path>`) · `preview <scene> style=<style>` (windowed before / after split image,
live remap, nothing written) · `audit [dir] grounds=meadow,heath,snow,ash,autumn` (contrast matrix: dE, hue gap, team
colour area) · `check <style>` (bible vs output statistics).

**Owns.** `tools/palette_studio/`, `art/palettes/`, `tests/test_tool_palette_studio.gd`, `docs/tools/palette_studio/`.
Minimal touches: none.

**Depends on.** Nothing. Serves tools 4 and 6 (palette names), step 20 art (20.V0-V6).

**Acceptance demo.** (a) All 10 decor sets + horizon + ground restyled to autumn from one <= 50-line bible with **no
builder edited**; before / after sheet; `check` PASS. (b) Contrast matrix of 60+ units x 6 grounds in one run that
reproduces the audit's known findings by itself (Thornling on heath ~dE 8, Nature army dE 20-22 on meadow, Sapling team
colour ~4 %) and adds the autumn column nobody has measured. (c) Same bible twice = identical variant hashes.

**Labs.** Art Lab contrast rules (R3 family) and grounds; Visual Diff (restyle goldens).

**Effort / share.** M, ~1.25 h, **~3 %**. **Risks.** Shaders that compute colour in code (heath gradients) do not
follow a vertex LUT: report "not remappable" per file with the reason; hue remaps can look flat (value / saturation
bands are in the bible).

---

## 10. Tool 9 (M) Sound Forge: procedural audio synth

**Purpose.** Describe a sound or a music cue in layers; get original WAV takes, a spectrogram + waveform image an
agent can read, the Audio Lab scorecard, and a check that the result matches the descriptors.

**Impossible today and why.** Every feature has its own ad-hoc generator (`mapfill_sfx_generator.gd`,
`trade_sfx_generator.gd`, `champion_sfx_generator.gd`, `takes_sfx_generator.gd`); agents cannot hear, so there is no
feedback beyond loudness numbers; there is no music at all, and the prologue needs 5 cues + 5 stingers.

**Format sketch** (`assets/audio/forge/specs/<set>.sound`):
```
sfx ice_crack_big  takes=4  len=1.2  bus=SFX  cat=spell  loud=-16  seed=3
  layer crack   noise=white  env=a0.002,d0.08,s0,r0.3  bp=2400..6000 q=2  pitch_rand=0.08
  layer groan   osc=saw f=90>55  env=a0.05,d0.6,s0.2,r0.4  lp=900  drive=0.3
  layer shards  grains=18  f=3000..7000  spread=0.9  env=perc
music prologue_ice  len=30  bpm=64  key=D dorian  xfade=0.5
  stem bed    drone D2 A2  pad=sine_choir
  stem motif  notes=[D4 F4 A4 G4]  patch=bell  every=4 bars
  stem perc   pattern="x...x..x"  patch=frame_drum  from=bar 5
```
**CLI.** `run_sound_forge.ps1 build <set>` (headless render 44.1 kHz WAV via `AudioStreamWAV.save_to_wav`, takes,
spectrogram + waveform PNG per cue, loudness / peak table, descriptor check: brightness from the spectral centroid,
attack time, length, pitch contour vs the spec words) · `lab <set>` (Audio Lab on the output folder) · `listen <set>`
(writes the Audio Lab preview cue list so the user can audition later).

**Owns.** `tools/sound_forge/`, `assets/audio/forge/`, `tests/test_tool_sound_forge.gd`, `docs/tools/sound_forge/`.
Minimal touches: none.

**Depends on.** Nothing. Serves tool 2 (`sfx` / `music` paths).

**Acceptance demo.** (a) **The prologue score** of `prologue-movie-plan.md` 2.7 (5 music cues: world 60 s, ice /
nature / shadow / fire 30 s; 5 stingers) from <= 80 spec lines: lengths +- 0.05 s, clean loop seams, Audio Lab 0 FAIL,
<= 25 MB. (b) A 12-cue Old Vey set (sword whoosh, lightning crack, thunder tail, footsteps...) with 3-4 takes each:
variation check PASS. (c) Descriptor self-test: the same patch rendered "dark" vs "bright" differs >= 40 % in spectral
centroid.

**Labs.** Audio Lab (every build), Build Lab (size report).

**Effort / share.** M, ~1.25 h, **~3.5 %**. **Risks.** Music that is technically clean but dull (the motif / patch
table is the lever; the user judges at the playtest); render time of 60 s cues in GDScript (vectorise per block).

---

## 11. Tool 10 (M) Script Desk: dialogue and story

**Purpose.** Write dialogue as a screenplay; get timed line tracks for `cine` and mission dialogue, subtitle checks, a
table-read timeline image, and extraction from the story docs.

**Impossible today and why.** `story-episode-1.md` (100 KB) holds every line inside markdown tables; moving them to
data is copy-paste, line lengths are checked by hand, timings are guessed from `max(2.5, 0.9 + 0.055 x chars)`, and no
one can see whether 26 lines fit 26 shots.

**Format sketch** (`data/story/<id>.script`):
```
= SCENE prologue  cine=prologue
== P01
NARRATOR: Once upon a time, a peaceful world... [hold 1.0]
== P24
VESSA (whisper): Someone is in the keep.
  > portrait vessa worried
```
**CLI.** `run_script_desk.ps1 check <id>` (<= 2 x 48 chars per subtitle with a suggested split, reading speed <= 17
characters / s, known speakers + colours from `Speakers`, names consistent with the story bible list, shot ids exist in
the `.cine`, lines fit their shots) · `tracks <id>` (`data/story/<id>.lines.json` LineTrack for `cine`, mission
dialogue JSON for `Events.dialogue` users) · `table_read <id>` (PNG timeline: shots as bars, lines, overflow in red; a
markdown read-through for the user) · `extract docs/design/story-episode-1.md section=7.2` (pulls a shot-list table
into a screenplay draft) · `voice <id>` (**off by default**: placeholder timing voices only if the user says yes,
question 3 note).

**Owns.** `tools/script_desk/`, `data/story/`, `tests/test_tool_script_desk.gd`, `docs/tools/script_desk/`. Minimal
touches: none (reads `story-episode-1.md`, never edits it).

**Depends on.** LineTrack JSON contract (T0). Serves tool 2.

**Acceptance demo.** (a) The prologue (26 lines) and 3 Episode 1 cinematics extracted from `story-episode-1.md`
automatically into screenplays, every line checked, tracks consumed by `cine check` with 0 FAIL; (b) table-read PNG;
(c) a planted overflow line and an unknown speaker FAIL with the fix hint (the suggested split at <= 48).

**Labs.** Data Lab (text fits, French-readiness keys), UI Lab (subtitle box at 3 resolutions via tool 1's overlay).

**Effort / share.** M, ~1 h, **~2.5 %**. **Risks.** Table formats in the story doc vary (the extractor reports rows it
could not read instead of guessing).

---

## 12. How the tools plug into the Labs

| Tool | Runs itself | Feeds |
|---|---|---|
| 1 Runtime | - | Perf Lab probe per shot, Error Lab logs |
| 2 cine | Visual Diff (`stills` as goldens), Perf Lab (`perf`) | Data Lab (line text) |
| 3 Lens | UI Lab (icons at 48 px) | Data Lab (icon present), Art Lab (turnarounds) |
| 4 Model Forge | Art Lab (every build) | Visual Diff (turnarounds), Perf Lab crowds |
| 5 Motion | own checks | Art Lab phases, Visual Diff (filmstrips) |
| 6 World Forge | Map Lab (maps), Art Lab `decor_set` (sets) | Perf Lab (set cost) |
| 7 VFX Composer | Art Lab `kind=vfx` | Perf Lab (pooled idle cost) |
| 8 Palette Studio | own contrast matrix | Art Lab contrast rules / grounds |
| 9 Sound Forge | Audio Lab | Build Lab (size) |
| 10 Script Desk | own checks | Data Lab, UI Lab |
Every tool writes the lab scorecard format and a history row, so the Error Lab and the lead read them like the labs.
Tool notes loop like the Art Lab notes: users of a tool end their report with "<Tool> notes"; the lead collects them
for a day and sends them to the tool's owner (the tool agent, continued).

---

## 13. Launch plan

### 13.1 T0, lead (<= 30 min, before anyone starts)
1. Budget check (`get_usage`); 5-hour meter near 0 %. The CLAUDE.md cap is 6 parallel agents: this wave needs 10
   (question 1).
2. `docs/plan/tools-wave-agent-rules.md` = section 0 rules + the per-tool "Owns" rows; CLAUDE.md: ownership rows for
   the new folders, a short "Tools" contract bullet (section 13.2), the Cinematics subset contract of
   `prologue-movie-plan.md` 2.3.
3. `tools/common/` (section 1). `project.godot`: `cinematic_skip` (Esc, Space), `cinematic_advance` (Enter, KP Enter),
   `cinematic_pause` (P), physical keycodes. `scripts/core/events.gd`: `cinematic_started(id)`,
   `cinematic_finished(id, skipped)`. Export filter: exclude `tools/*`, `docs/*`, `art/cinematics/sets/*`,
   `art/cinematics/hires/*`, `*/specs/*` sources stay (tiny).
4. `--import` clean, launch the 10 agents in one message (order below = priority when the Godot gate is busy).

### 13.2 Contracts frozen at T0 (the only cross-tool interfaces)
| Contract | Between | Shape |
|---|---|---|
| Cinematic resources + player API + `seek` + `debug_state()` | 1 -> 2, 6, 10 | `cinematics.md` 2-4 + prologue 2.2-2.5 + this doc section 2 |
| Set contract + marks file | 6 / 3 -> 1, 2 | prologue 2.3; marks = `<set>/marks.json` `{shot: {from, to, look_from, look_to, fov_from, fov_to}}` |
| CameraSpec | 3 -> 2 | `camera.json` `{pos, look, fov, a:{...}, b:{...}}` |
| LineTrack | 10 -> 2 | `{cine_id, lines: {shot_id: [{at, speaker, text, duration}]}}` |
| Clip / gesture ids | 5 -> 2, 4 | `play_clip(id: StringName) -> bool`, `play_gesture(id) -> bool`, ids = file names |
| VFX ids | 7 -> 2 | `VfxComposer.play(id, at: Vector3, target: Variant) -> void`, group `"composer_vfx"` |
| Audio paths | 9 -> 2 | `res://assets/audio/forge/<set>/<cue>[_<take>].wav` |
| Palette names | 8 -> 4, 6 | `art/palettes/<style>.tres` (`PaletteSet`: name -> Color / material path) |
| Tool CLI + report | all | section 0 + `tools/common/` |

### 13.3 Order and gates (one 5-hour window)
| Window clock | What |
|---|---|
| 0:00-0:30 | T0 (lead). Launch, in this order: **1 Runtime, 2 cine, 6 World Forge, 3 Lens, 4 Model Forge, 5 Motion, 7 VFX, 9 Sound, 10 Script Desk, 8 Palette** |
| ~0:55 (= ~0:25 after launch) | **G1**: tool 1 milestone M1 (resource scripts frozen, parse clean). Lead relays to 2, 6, 10 (`SendMessage`) |
| 1:30-2:30 | Tools land one by one. Per tool, the lead runs: its test, `check` on its demo, the smoke + perf tests (nothing in-game should change). Failure -> back to the same agent once |
| 2:00-3:00 | **G2 usability trials** (section 13.4) as tools land; findings go back to the tool agent (one fix round, `SendMessage`) |
| 2:45-3:45 | **G3 flagship demo** (13.5) by tool 2's agent, continued. Optional: tool 11 Director starts when a slot frees |
| 3:45-4:30 | Lead: all tests, commit per tool folder, tag `tools-wave-green`, `docs/tools/index.md` (one row per tool: command, demo path, score), playtest note |
| 4:30-5:00 | Reserve (retries, the 95 % save rule). Stop launching at 85 % |

### 13.4 Cold-start usability trial (the real "done")
For each tool: a fresh **medium-effort** agent (`four-wizards-high` is not needed) gets ONLY `tools/<tool>/README.md`
and a one-line brief that is a **variant** of the demo (e.g. Lens: "icons for the 4 mounts"; Model Forge: "a Mother
Hush stand-in"; Sound Forge: "a 20 s shadow-kingdom music cue"; World Forge: "a small crypt corner set with 2 marks";
Motion: "a bow for Malrik"). Pass = a correct output with `check` PASS in <= 3 build runs and no question about the
tool. Its report lists every confusing error / missing example; the tool agent fixes them. ~10 min each.

### 13.5 The flagship demo: "Old Vey arrives" (the impossible scene)
A 20-30 s scene made **only from text files** in <= 1 hour by one agent using all the tools: Old Vey (tool 4) walks in
(tool 5 gait) on a storm-lit hill set (tool 6, autumn-free night palette from tool 8), strikes a Shade with a lightning
sword (tool 5 clip + tool 7 VFX + tool 9 thunder), Vessa watches (tool 5 gesture `turn_head_left`), 3 subtitled lines
(tool 10), 5 shots framed by words (tool 3), assembled and checked by `cine` (tool 2), played by the runtime (tool 1).
None of these pieces exists today (no Vey, no sword animation, no lightning, no storm sound, no set, no player). Done
when `cine check` PASS, stills sheet + timing sheet exist, the scene plays windowed at the playtest, and the lead can
say which text line to change for any note the user gives.

---

## 14. Budget estimate
Rule of thumb from `prologue-movie-plan.md` 4: ~2 % of the 5-hour window per agent-hour (mixed effort).

| Part | Agents x time | Share of the window |
|---|---|---|
| 10 tool agents (H ~2 h, M ~1.25-1.5 h) | ~17 agent-hours | **~34-38 %** |
| One fix round each after the trials | 10 x ~0.3 h | ~6 % |
| 10 usability trials (medium) | 10 x ~0.15 h | ~3 % |
| Flagship demo (tool 2 agent continued) | ~1 h | ~2-3 % |
| Director (optional, tool 11) | ~1 h | ~2-3 % |
| Lead (T0, gates, tests, merges, index) | whole window | ~10-12 % |
| **Expected total** | | **~57-65 %**; worst case (every [H] tool 2.5 h + a second fix round) **~80 %** |
**Per-agent cap:** "keep working until the demo passes" is capped at **2.5 h or 3 build iterations after the first full
demo run**, whichever comes first; then the agent reports the gap (what still fails, the next step). Cut order if the
window runs short: Director, then map mode of tool 6 (sets stay), then Palette Studio's `preview`, then Lens portraits,
then Sound Forge music stems (SFX stay). Never cut: tools 1 and 2, the usability trials of tools 1-6.

**Payback.** The prologue window (`prologue-movie-plan.md`, ~50-60 % of a window, 19 agent tasks) becomes: sets as
World Forge specs (7 x medium ~25 min), shots as one `.cine`, lines via Script Desk, score via Sound Forge, gestures
already done: estimate **~25-35 %** of a window, and every later Episode 1 scene reuses it. Icons, Old Vey, the story
VFX and the prologue score come out of this wave as demos.

---

## 15. Risks (wave level)
| Risk | Plan |
|---|---|
| 10 agents and the 4-run Godot gate: slow windowed stills | Headless-first design; windowed only for `sheet` / `shoot` / `strip`; agents batch captures in one run; perf numbers only on the quiet PC at the end |
| Tools 2 / 6 / 10 waiting on tool 1 | Frozen field list at T0; M1 milestone at ~0:25; each tool degrades to proxies / WARN when a partner is missing |
| Tools that only their author can use | Cold-start trials (13.4) are part of "done" |
| Format sprawl (10 languages) | One shared reader `tool_spec.gd`, same token rules everywhere; unknown keys FAIL with "did you mean" |
| Kit edit by tool 5 | <= 40 additive lines, guarded, kit tests re-run; nobody else touches the kit this wave |
| Movie Maker `.ogv` not available in 4.7.2 | `record` writes `.avi` and stops; ffmpeg only with the user's yes (question 2) |
| Tools changing the game by accident | Tools write only their folders; the smoke + perf tests after each landing must be unchanged |
| Endless polishing | Section 14 cap; the demo numbers are the finish line, not taste |

---

## 16. What this changes in the plan
- `waves.md` step 19.0 (Cinematic Toolkit) = tools 1 + 2 (+ 3, 5, 6, 7, 9, 10 pieces). The prologue window's 19.P1,
  P2, P7 (runtime), P15 (gestures), P5 (score), P16 (assembly tooling) are done here; its 7 set tasks become World Forge
  specs; 19.P3 / P4 (StoryFlow, menu hook) and P17-P19 (probe, video player, recording) stay in the prologue window.
- Step 20 (2v2) starts from `data/maps/fourfold_hollow_layout.tres` + a Map Lab score; 20.V0 uses the autumn bible.
- Art audit top-10: icons (Lens), Nature readability and the wizards (Model Forge rebuild path + Palette audit), VFX
  sweep (Composer) get faster tools.

---

## Questions for the user (recommendation first)
1. **How many agents at once?** (a) **All 10 at once in one fresh 5-hour window, stop launching at 85 % (needs your OK
   over the 6-agent rule)** (b) Two windows: tools 1, 2, 3, 6, 10 first (the Movie Maker chain), then 4, 5, 7, 8, 9
   (c) 6 now (1, 2, 3, 4, 6, 10) + 4 later.
2. **Movie recording in this wave?** (a) **Live in-engine playback + a windowed `.avi` test recording only; ask about
   ffmpeg later only if you want `.ogv` / trailers** (b) Allow the ffmpeg download now so `record` makes `.ogv` / `.mp4`
   trailers (c) No recording at all this wave.
3. **What happens to the demo outputs?** (a) **They are real deliverables and go into the game** (the missing icons,
   Old Vey, the story VFX, the prologue score, the autumn variants), each adopted by its owner after the lab checks
   (b) They stay as proofs in `docs/tools/` and the normal art tasks redo them with the tools (c) Tools only, no demo
   content committed. (Default for voices: none; placeholder voices via the built-in Windows speech only if you ask.)

## User answers (2026-09-27 00:12)
1. Agents: **two windows** (5 tools per 5-hour window, launch order 1, 2, 6, 3, 4 first; then 5, 7, 9, 10, 8). Respects the 6-agent cap.
2. Recording: "best for visuel" -> in-game live playback at native resolution stays the main path; recording uses Godot's built-in Movie Maker as a lossless PNG sequence + WAV (no download). Converting to .mp4 / .webm would need ffmpeg: ask the user before any download.
3. Demo outputs: **real deliverables in the game** (missing icons, Old Vey, story VFX, prologue score, autumn variants), under normal review + labs.
