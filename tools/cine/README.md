# cine: the Movie Maker CLI (tools wave, tool 2)

Write a movie as a short text file, check it headless, look at stills and a timing sheet, bake it for the game's
cinematic runtime, record it. Spec: `docs/plan/tools-wave.md` section 3. Runtime (tool 1): `scripts/cinematics/README.md`.

## 1. Five commands you need
```powershell
cd C:\Users\elzzo\Documents\four-wizards-rts
.\tools\cine\run_cine.ps1 help                      # grammar + a complete example
.\tools\cine\run_cine.ps1 check my_scene            # headless, ~10 s. Exit 0 PASS/WARN, 1 FAIL, 2 bad input
.\tools\cine\run_cine.ps1 stills my_scene           # opens a window ~1 min: frames a/b/c per shot + contact sheet
.\tools\cine\run_cine.ps1 sheet my_scene            # headless timing sheet PNG
.\tools\cine\run_cine.ps1 build my_scene            # check, then bake data/cinematics/my_scene.tres (only if 0 FAIL)
```
Also:
- `animatic <id>`: stills with grey capsules / boxes. `play <id>`: live window.
- `record <id> [fps=30] [res=1920x804] [dur=10]`: Godot Movie Maker PNG sequence + WAV in
  `%USERPROFILE%\Videos\four-wizards-rec\<id>\` (never inside the project, no ffmpeg). Movie Maker always renders at the
  project viewport size (1600x900); a headless `reframe` pass then scales + centre-crops every PNG to `res=`. With a
  2.39 `res` (1920x804) the crop IS the letterbox band: no bars are drawn, subtitles stay inside it. The record report
  (`report_record.md`, `report_reframe.md`) says the size / fps used.
- **AVI (default for `record`, 2026-09-27):** `record <id> [fps=30] [dur=] [from=] [movie=<path>.avi] [format=avi|png]`
  runs Godot with `--write-movie <out>\<id>.avi`: one MJPEG + PCM file (narration + music mixed) **at `res=`
  (default 1920x804)**. Godot 4.7's Movie Maker resizes AVI frames to the project viewport size
  (`display/window/size/viewport_*`) whatever the window, so the record runs from a **sized project copy**
  `%LOCALAPPDATA%\four-wizards-cine\proj_<WxH>\` (directory junctions to this project's folders + a fresh
  `project.godot` + `override.cfg` with viewport = res; kept between runs, never `Remove-Item -Recurse` it: that follows
  the junctions) and the window = res. At a 2.39 `res` the frame IS the band: no bars, subtitles inside. The ps1 reads
  the first JPEG's size and fails if it is not `res` (`CINE record <id>: AVI frame size 1920x804 (asked 1920x804)`);
  report row P3 PASS. `from=<s>` starts mid-movie (tests). Proof 2026-09-27: `Videos\four-wizards-rec\u2_proof\`.
- `perf <id>`: window, plays it, CPU ms / GPU ms / draw calls per shot + worst frame (`report_perf.md`). Noisy when
  other Godot runs share the PC: compare runs, do not judge one.
- `diff <id> [against=golden]`: new stills vs the previous `stills` run (kept in `stills_prev/`) or vs the goldens.
  Per shot: PASS unchanged, INFO minor (< 1 % px, flame / particle flicker), WARN changed; `diff.png` = was | now |
  heatmap of the changed frames (Visual Diff Lab maths). Models are frozen and animated pixels masked (2 captures per
  frame) so an unchanged movie diffs clean.
- `stills <id> golden=1`: also registers the frames as goldens in `docs/tools/cine/goldens/<id>/` (Visual Diff hook:
  after a model / set change, `diff <id> against=golden` says which shots of the movie changed).
- `demo`: the acceptance demo. Options: `shot=S3` (stills of one shot), `res=1600x900,3440x1440`, `src=<path.cine>`,
  `animatic=1`, `log=0`, `expect_fail=N`.

- Source: `data/cinematics/src/<id>.cine`. Output: `docs/tools/cine/out/<id>/` (`report.md` / `report.json` from
  check / build, `report_<verb>.*`, `timing.png`, `stills.png`, `stills/<shot>_<a|b|c>_<W>.png`, `animatic.png`),
  one row per run in `docs/tools/cine/history.md`. Baked: `data/cinematics/<id>.tres` (`CinematicScript`).
- The last printed lines are the summary + every FAIL / WARN with a fix hint:
  `CINE check my_scene: FAIL quality 79 (1 FAIL, 0 WARN) hash ... -> docs/tools/cine/out/my_scene`
  `  FAIL R2 marker @S8_frm (line 40): missing (from=) -> did you mean "@S8_from"? ...`
- **Look at `stills.png`** after every change (red / amber frame = that shot has a FAIL / WARN). Yellow lines = the 2.39
  band (the dark part is hidden by the bars in game), cyan = safe area. Faces belong inside the cyan box.

## 2. A complete example (copy, rename, edit)
```
# data/cinematics/src/two_wizards.cine
cine two_wizards  title="Two Wizards"  letterbox=2.39  seed=3  length=6..12
env night  moon_yaw=200
prop  keep   res://art/buildings/fire_keep.tscn  at=(0, 0, 0)
cast  vessa  res://art/units/wizards/vessa.tscn  at=(0, 0, -7)   yaw=180
cast  shade  res://art/units/shadow/shade.tscn   at=(1, 0, -11)  yaw=0
shot S1 4.0  cam=frame "ms on vessa and shade, high"  push=0.6
  at 0.5  line vessa "Who walks the wall at this hour?"
  at 2.0  anim shade play_attack
shot S2 3.0  cam=frame "mcu on vessa, ots shade left"
  at 0.2  sfx res://assets/audio/sfx/spell_umbral_shroud.wav
  at 2.4  fade alpha=1 time=0.6
```
The full demo, 8 shots / 46 s: `data/cinematics/src/watch_keep.cine`. Its planted-bug twin (exactly 4 FAILs):
`watch_keep_bugs.cine`.

## 3. Grammar
One item per line; `# ` starts a comment; `key=value`, `"quoted text"`; indented `at` lines belong to the shot above.
Positions: `(x, y, z)` (metres, y up) · `@marker` · `<actor>` (for look: its face) · `<actor>+(dx, dy, dz)`.
Yaw in degrees: 0 = the model faces +Z, 180 = faces -Z (the game's convention: unit.gd `atan2(dir.x, dir.z)`).

| Line | Keys | Meaning |
|---|---|---|
| `cine <id>` | `title` `letterbox`(2.39) `skip_lock`(0) `seed`(1) `length`(0..120, e.g. 45..60) `skippable` `mode`(stage \| pause) | Header (required, first). `mode=pause` (2026-10-07) = an in-mission scene: baked as WorldMode.PAUSE with no stage, played by `MissionBase.play_cutscene(id)` over the frozen mission (world-space cameras; the cast / props only exist for the checks; actor tags resolve through `MissionBase.cinematic_actor`: a mission property such as `torvald`, `hero`, or the hero's model name such as `malrik`, so `cam=orbit pivot=malrik` follows the live hero) |
| `use set <set_id>` | | Tool 6 set `art/cinematics/stage_sets/<set_id>/<set_id>.tscn`: its `Shots` markers / `marks.json` become `@<name>`, its `Puppets` become actors. Missing = WARN + grey boxes, shots using its markers get a proxy camera |
| `use lines <file.json>` | | Tool 10 LineTrack `{cine_id, lines: {shot_id: [{at, speaker, text, duration}]}}` merged into shots |
| `use music <res path>` | | Music for the whole movie |
| `env night\|dusk\|day\|none` | `moon_yaw` `moon_pitch` `energy` `color` | Sky + one moon light + ground (skipped when the set has a WorldEnvironment) |
| `prop <name> <res://x.tscn>` | `at` `yaw` `scale` | Any scene (keeps, trees...) |
| `cast <tag> <res://model.tscn \| capsule>` | `at` `yaw` `hidden=1` `speaker` | An actor (puppet). Face height read from the model's `Head` |
| `mark <name> (x,y,z)` | `fov` | Marker `@name` |
| `marks <shot> ` | `from` `to` `look=a>b` `fov=a>b` `pivot` | Markers `@<shot>_from/_to/_look_from/_look_to`; a shot with no `cam=` uses them |
| `shot <id> <seconds>` | `cam` + mode keys below, `in` `ease` `trans` `roll` `shake` `faces` `set` `fov` | One shot |

Camera modes (`cam=`):
| Mode | Keys | Notes |
|---|---|---|
| (none) | | uses `marks <id>` / the set's markers for this shot id |
| `static` | `from` `look` `fov` | |
| `dolly` / `crane` | `from` `to` `look=a>b` `fov=a>b` | crane = cubic ease |
| `orbit` | `pivot` (actor / @marker / pos) `r` `h` `deg=a>b` | angle 0 = +X side, 90 = +Z side |
| `follow` | `actor` `offset=(x,y,z)` | offset in the actor's space |
| `rail` | `rail=<Path3D in the set>` | not evaluated by checks (WARN) |
| `frame "<words>"` | `push=<m>` `fov` | **built-in framer**, best default. Words: `<size> on <actor>[ and <actor>]` then any of: angle `front` `3/4 left` `3/4 right` `profile left` `profile right` `back`; height `eye` `low` `high` `top`; `thirds left` / `thirds right`; `ots <actor> [left]` (over that actor's right / left shoulder). Sizes: `ecu cu mcu ms mls ws ews` |
| `lens "<words>"` | `lens_spec=<camera.json>` | tool 3 CameraSpec; without it = the framer + WARN |

`in=cut | fade_black[:s] | fade_white[:s] | blend[:s]`, `ease=in|out|in_out|out_in`, `trans=sine|linear|cubic|quad|...`,
`faces=a,b` = faces that must stay in the band (the camera's subjects are added automatically).

Actions (indented `at <seconds> <action> ...`, time from the shot start):
| Action | Example |
|---|---|
| `line <speaker> "text" [dur=]` | `at 0.8 line vessa "The watch fires are out."` (auto duration max(2.5, 0.9 + 0.055 x chars)) |
| `move <actor> to=<pos> [speed=2]` | `at 1.2 move shade to=(1.2, 0, -11.5) speed=1.1` (faces the way) |
| `teleport <actor> to=<pos> [yaw=]` / `face <actor> yaw=<deg> \| to=<actor\|pos> [time=0.3]` | |
| `anim <actor> <play_hook> [arg=]` | `at 0.4 anim vessa play_cast arg=fireball` (hook must exist on the model: did-you-mean) |
| `clip <actor> <clip_id>` | tool 5 clip; without tool 5 these ids fall back to hooks (WARN): `cast attack hit death level_up staff_slam draw_knife slash kneel bow point nod turn_head_left turn_head_right`. **Dances** (2026-09-27): `clip d1 dance_victory` / `dance_random` / `dance_surrender` = the unit's SAME in-game clip (`play_clip`, art/units/kit/README.md); valid when the model's `has_clip(id)` is true, else FAIL. Stop with `anim d1 stop_clip` (an attack / cast stops it too; walking fades it). Stills pose the dance at the frame's time |
| `vfx <id> [at=] [to=] [scene=res://..]` | tool 7 id (missing tool = WARN) or any scene |
| `sfx <res path> [vol=]` / `music <res path>` | a missing file = FAIL (under `assets/audio/forge/` without tool 9 = WARN) |
| `fade [color=#000] [alpha=1] [time=0.5]` / `shake <0..1>` / `title "text" [sub=] [time=3]` | |
| `show <actor>` / `hide <actor>` / `call <method> [args=a,b]` / `set_shot <set_id>` | |

### Multi-set movies, voices, fx (prologue, 2026-09-27)
- Per-shot `set=<set_id>`: every set named by the header or a shot is loaded at the origin and shown only during its
  shots (`CineStage.set_active_set`, also the runtime's context API `find_set` / `set_active_set`); each set's
  LightingPreset drives one LightingRig; its marks / marks.json `subject` belong to that set only (the subject's face is
  framing-checked). A set not built yet = WARN, its shots use the proxy camera + the cine env. Set puppets are only
  "on stage" while their set is shown. `prop ... set=<id>` / `cast ... set=<id> [scale=]` put a prop / an extra actor
  in one set; a set puppet whose tag collides gets the prefix `<wizard>_` (e.g. `ysolde_messenger`).
- Voices: every line gets its WAV from `data/voice/manifest.json` (speaker + text) or `voice=`; `play` / `record` play
  it at the line time (mixed into the AVI). Check rows V1 (every line voiced) / V2 (WAV fits before the next line).
  A line may run on over later cuts until the next line starts (subtitles, check and timing sheet agree). A hidden cast
  speaker (`cast narrator capsule hidden=1 speaker=master`) = voice-over: no name above the subtitle.
- `use music <path> vol=<dB>`; the music loops.
- Time-driven nodes: every pose calls `set_cine_time(t)` on group `cine_timed` (dragon flocks) and `set_cine_age(age)`
  on `vfx ... scene=` nodes, so stills / seek / record agree. Cine effects: `art/cinematics/fx/*.tscn` (`cine_fx.gd`:
  streak, pillar, ring, dome, orbs, burst; `vfx x scene=res://art/cinematics/fx/fire_pillar.tscn at=(..) [to=(..)] life= scale= yaw=`).
- Continuity (180-degree rule) now judges only the line between the two shots' subjects (faces), not crowd extras.

### Upgrade U2 (2026-09-27)
- **Set cues**: a set root with `cine_cues(shot_id) -> Array` (cue Dictionaries `{at, kind, actor, target, scene /
  vfx_id, life, scale, yaw, to, ...}`, kinds vfx / sfx / anim / clip / shake, positions in the set's space) fires its
  own spell VFX: `build` bakes them as actions (params `from_set`), so stills / sheet / play / record / the .tres see
  them; the runtime merges them for scripts not baked by cine (`scripts/cinematics/README.md` section 4).
- **Puppets speak**: a set puppet (e.g. `ysolde_messenger`) is a valid `line` speaker (no "not cast" WARN).
- **Lens at bake**: `cam=lens "<words>"` without `lens_spec=` is solved at bake by tool 3's `LensSolver` on the actors'
  poses at the shot start (no framer WARN; the solved subjects are framing-checked). Bad words = FAIL with Lens's hint.
- **RT2 fixed**: the runtime keeps actors the cinematic moved over a set's `begin_shot` puppet reset (play and seek).

## 4. What `check` measures (one report row per problem)
| Group | Rule |
|---|---|
| parse | grammar, unknown keywords / keys / modes / actions with "did you mean" and the line |
| resolve | every set, marker, actor, hook, clip, vfx, audio file, line track exists |
| timing | total inside `length=`; shots >= 1 s (WARN); fades fit |
| framing | every named face (look / pivot / frame / follow subject + `faces=`) sampled every 0.25 s: inside the 90 % safe area of the 2.39 band on 16:9 = PASS, inside the band = WARN, outside / behind = FAIL (hint says which way to move) |
| continuity | at each cut, for every pair of actors on screen in both shots: camera on the same side of the line between them (180-degree rule, FAIL); jump cut (camera moved < 10 %, turned < 10 deg, same fov) WARN. Fades reset the axis |
| subtitles | <= 2 lines x 48 chars, <= 17 chars/s (WARN to 22, FAIL above), >= 1 s on screen, speaker cast |
| determinism | 2 fresh runs (parse + stage + bake + every frame at 60 fps) hash-identical; the hash is in the report |
| partners | which tools are present; the runtime player's camera (seek + `debug_state()`) = cine's camera within 5 cm; the runtime's puppet facing / position = cine's (5 deg, 5 cm) |

## 5. Tips
- Keep every camera on ONE side of the line between the two main actors (write it in a comment at the top).
- Tight shots: `mcu` / `cu` with `ots` keep both actors on screen; a fade (`in=fade_black:0.8`) lets you cross the axis.
- Stills are slow-ish (~2 s per frame): `shot=S3` for one shot while iterating.
- Recording: 10 s at 30 fps ~ 300 PNG (~0.7 MB each at 1600x900). The frame size follows the project window.
  Converting to .ogv / .mp4 needs ffmpeg = ask the user first.

## 5b. Into the game (2026-09-27)
`$GODOT --headless --path . -s tools/cine/cine_stage_export.gd --quit-after 3000 -- prologue_3min` bakes
`data/cinematics/<id>.tres` and saves the runtime stage `scenes/cinematics/<id>.tscn` (CinematicStage: the sets, props and
cast posed like cine, a LightingRig, `actor_paths` for every tag). Re-run it after changing the .cine or a set. The game
never loads tools/ (excluded from the export): cine effects live in `art/cinematics/fx/`.

## 6. Files
`run_cine.ps1` (CLI), `cine_main.gd` (verbs), `cine_doc.gd` (parser, shared `tools/common/tool_spec.gd`), `cine_stage.gd`
(stage built from set / props / cast; runtime context `cinematic_actor(tag)`), `cine_bake.gd` (resolve, framer,
.tres), `cine_eval.gd` (camera + actors as a pure function of t), `cine_checks.gd`, `cine_preview.gd` (play / record /
stills player with bars, subtitles, fades), `cine_sheets.gd` (timing sheet). Test: `tests/test_tool_cine.gd`.
