# Cinematic Runtime (tools wave, tool 1)

The engine player of `docs/design/cinematics.md` (2-6, 8.3, 11) + `docs/plan/prologue-movie-plan.md` (2.2-2.5).
Owner: systems-coder-high. Tools 2 (`cine`), 6 (World Forge) and 10 (Script Desk) build against THIS file.

**Freeze rule (M1, 2026-09-27):** the resource fields below never get renamed or removed; new fields are only added.

## 1. Resources (frozen field list)

### `CinematicScript` (`cinematic_script.gd`, Resource)
| Field | Type = default | Meaning |
|---|---|---|
| `id` | StringName = `&""` | `prologue`, `c1_offer`, `tool_demo`... |
| `title` | String = `""` | Theatre label |
| `kind` | `CinematicScript.Kind` { `ENGINE`, `VIDEO` } = ENGINE | |
| `world_mode` | `CinematicScript.WorldMode` { `STAGE`, `PAUSE`, `HOLD` } = STAGE | HOLD = stub: `play()` refuses it |
| `stage_scene` | String = `""` | STAGE scene path (StoryFlow loads it) |
| `video_path` | String = `""` | VIDEO only |
| `shots` | `Array[CinematicShot]` = [] | the timeline |
| `lines` | `Array[CinematicLine]` = [] | VIDEO subtitle track (times from the video start) |
| `letterbox_aspect` | float = 2.39 | 0 = no bars |
| `music_cue` | StringName = `&""` | a `res://` audio path (Music bus) started at play, stopped at the end |
| `skippable` | bool = true | |
| `skip_locked_until` | float = 0.0 | seconds; skip presses before it are eaten (no prompt) |
| `fallback_text` | String = `""` | VIDEO fallback card |
| `return_focus` | Vector3 = `Vector3.INF` | in-mission camera return point (INF = the wizard) |
| `shake_seed` | int = 1 | seeds the camera-shake noise |
| `music_volume_db` | float = 0.0 | (added 2026-09-27) volume of `music_cue`; the cue loops when shorter than the movie |
| `voice_over` | Array[StringName] = [] | (added) speakers whose subtitles show no name (cine's hidden narrator) |
| `lines_over_cuts` | bool = false | (added) cine rule: a line runs over cuts until the next line starts |
Methods: `total_duration() -> float`, `shot_index_of(shot_id) -> int`, `static find(id) -> CinematicScript`
(`res://data/cinematics/<id>.tres`, null if missing).

### `CinematicShot` (`cinematic_shot.gd`, Resource)
| Field | Type = default | Meaning |
|---|---|---|
| `id` | StringName = `&""` | shot id (`P11`); markers, set `begin_shot(id)`, reports |
| `duration` | float = 2.0 | seconds |
| `camera_mode` | `CinematicShot.CameraMode` { `STATIC`, `DOLLY`, `CRANE`, `ORBIT`, `RAIL`, `FOLLOW` } = STATIC | section 3 of cinematics.md |
| `from_pos`, `to_pos` | Vector3 = (0, 2, 6) | STATIC uses `from_pos`; DOLLY / CRANE lerp from -> to |
| `look_from`, `look_to` | Vector3 = ZERO | look-at point lerped over the shot |
| `look_actor` | StringName = `&""` | overrides `look_*` with the actor + `look_offset` |
| `look_offset` | Vector3 = (0, 1.6, 0) | |
| `pivot_actor`, `pivot` | StringName `&""`, Vector3 ZERO | ORBIT centre |
| `orbit_radius`, `orbit_height`, `orbit_from_deg`, `orbit_to_deg` | float 6, 2, 0, 90 | ORBIT: pos = pivot + (cos a x r, h, sin a x r) |
| `rail` | NodePath = `""` | RAIL: Path3D (relative to the context / stage node) |
| `follow_actor`, `follow_offset` | StringName `&""`, Vector3 (0, 3, 6) | FOLLOW (offset in the actor's local space) |
| `fov_from`, `fov_to` | float 45, 45 | degrees |
| `roll_deg` | float 0 | |
| `ease_type` | `Tween.EaseType` = EASE_IN_OUT | (spec name `ease`) |
| `trans_type` | `Tween.TransitionType` = TRANS_SINE | (spec name `trans`); CRANE with SINE uses CUBIC |
| `transition_in` | `CinematicShot.Transition` { `CUT`, `FADE_BLACK`, `FADE_WHITE`, `BLEND_FROM_GAME` } = CUT | |
| `transition_time` | float = 0.5 | fades: half out at the end of the previous shot, half in |
| `blend_to_game` | bool = false | last shot blends into the game camera over `transition_time` |
| `shake` | float = 0 | 0-1 trauma at the shot start (decays 1 / s) |
| `dof_far` | float = 0 | > 0 = far blur distance |
| `branch_flag` | String = `""` | `"flag"` / `"!flag"`; a dropped shot takes 0 s |
| `lines` | `Array[CinematicLine]` | times from the shot start |
| `actions` | `Array[CinematicAction]` | times from the shot start |
| `stage_set` | StringName = `&""` | set shown during the shot (group `"cinematic_sets"`, its `set_id`); `&""` = keep |
| `marker_prefix` | StringName = `&""` | read camera from the set's markers / `marks.json` (section 4); `&""` = fields above |
Helpers: `static make(id, duration, mode)`, `add_line(at, speaker, text, duration := 0.0)`,
`add_action(at, kind, actor := &"", target := Vector3.ZERO, params := {})`.

### `CinematicLine` (`cinematic_line.gd`, Resource)
`at: float = 0`, `speaker: StringName`, `text: String`, `duration: float = 0` (0 = auto
`max(2.5, 0.9 + 0.055 x chars)`, always cut at the shot's end), `voice: String = ""` (optional audio path).
Helpers: `effective_duration()`, `static auto_duration(text)`, `static make(at, speaker, text, duration := 0.0)`.

### `CinematicAction` (`cinematic_action.gd`, Resource)
`at: float = 0`, `kind: StringName`, `actor: StringName`, `target: Vector3`, `params: Dictionary`, `on_skip: bool = true`.
Helpers: `static make(at, kind, actor, target, params)`, `static is_known_kind(kind)`, `const KINDS`.
| kind | params | Plays | End state (skip, seek, normal end) |
|---|---|---|---|
| `move` | `speed` 2.0, `path` (NodePath to a Path3D, optional) | lerp / path follow at `speed`, `set_moving(speed)`, faces the way | at `target`, `set_moving(0)`, facing the way |
| `teleport` | `yaw_deg` (optional) | instant | same |
| `face` | `yaw_deg` or `look_actor`, `time` 0.3 | turns | final yaw |
| `anim` | `hook` (`play_cast`, `play_attack`, `play_hit`, `play_gesture`, ...), `arg` | model hook (has_method guard) | none |
| `clip` | `id` (tool 5 clip id) | `play_clip(id)` on actor or its model | none |
| `spawn` | `scene` (res path), `tag` (default = `actor`), `yaw_deg`; missions: `context.cinematic_spawn(tag, params)` | instance at `target`, registered as `tag` | spawned |
| `despawn` | `fade` 0.5 | hides after `fade` s | hidden |
| `dormant` | `on` | `actor.set_dormant(on)` / `context.cinematic_dormant(actor, on)` | final |
| `visible` | `node` (NodePath from the context) or the actor, `on` | show / hide | final |
| `vfx` | `vfx_id` (-> group `"composer_vfx"` `play(id, at, target)`, else a `CastProxy` actor `cast(id, target)`) or `scene` (+ `life` 3 s) | one-shot | nothing (not replayed by seek / skip) |
| `call` | `method`, `args` (Array) | `context.callv(method, args)` | runs on skip / seek only if `on_skip` |
| `fade` | `color` (Color, black), `alpha` 1.0, `time` 0.5 | full-screen fade | final alpha |
| `music` | `path` (or `cue`) , `volume_db` 0 | starts a stream (Music bus) | stopped at the end |
| `sfx` | `path`, `volume_db` 0 | one-shot (SFX bus) | none |
| `shake` | `amount` 0.5 | camera trauma (decays 1 / s) | - |
| `title` | `text`, `sub`, `time` 3.0 | overlay title card (shown in recording mode too) | hidden |
| `set_shot` | `set` (set id) | switches the active set mid-shot | final |

## 2. `CinematicPlayer` (`cinematic_player.gd`, `extends Node`, group `"cinematic_player"`, process ALWAYS)
- `static instance(tree: SceneTree) -> CinematicPlayer` (creates one under the root if none), `static is_any_playing(tree) -> bool`
- `play(script: CinematicScript, context: Node = null) -> String` - `""` = ok, else `"Already playing"`, `"No script"`,
  `"Empty script"`, `"VIDEO scripts go to VideoCinematic"`, `"HOLD mode is not supported yet"`.
  `context` = the stage (`CinematicStage`) or a mission; actor lookup: registered tags, then `context.cinematic_actor(tag)`.
- `play_from(shot_index: int) -> void` (= `seek(start of that shot)`), `seek(t: float) -> void`: restores the start
  snapshot, applies the end states of every earlier action (in timeline order), runs in-flight ones at their progress,
  `call` actions only if `on_skip`; vfx / sfx / anim / clip are not replayed. `seek(t)` then one frame == playing to it.
- `skip()` (end states, then `finished(id, true)`), `stop()` (ends now, no end states; tools abort), `set_paused(on)`,
  `is_paused()`, `is_playing()`, `current_id()`, `current_script()`, `elapsed() -> float` (cinematic clock),
  `shot_index() -> int`, `shot_start(i) -> float`, `total_duration() -> float`, `end_line()` (Enter), `press_skip()`
  (the two-press / lock rule), `register_actor(tag, node)`, `actor(tag) -> Node3D`, `camera() -> Camera3D`,
  `overlay() -> CinematicOverlay`.
- `debug_state() -> Dictionary` (probe for tools, valid headless): `{id, playing, paused, t, total, shot_index, shot_id,
  camera: {pos: Vector3, look: Vector3, basis: Basis, fov: float, xform: Transform3D}, active_set: StringName,
  visible_actors: Array[StringName], line: {speaker, text} or {}, fade_alpha: float, fade_color: Color,
  skip_prompt: bool, skip_armed: bool, recording: bool, fired: {kind: count}, title: String}`.
- Options (set before `play`): `recording: bool` (no input / skip / focus pause, subtitles off, title card on),
  `one_press_skip: bool` (seen before / Theatre; else read from `CampaignState.is_seen(id)` when it exists),
  `use_overlay: bool = true`, `emit_events: bool = true`, `perf_probe: bool` (frame ms per shot: `perf_samples()`).
- Signals: `started(id)`, `shot_started(index: int, shot_id: StringName)`, `line_shown(line: CinematicLine)`,
  `line_started(speaker, text)`, `action_fired(action: CinematicAction)`, `finished(id: StringName, skipped: bool)`.
  Globals: `Events.cinematic_started(id)` / `Events.cinematic_finished(id, skipped)`.
- Clock: `t += delta` in `_process` (frozen while paused); the camera is a pure function of `t` (shake noise is seeded
  and time-based), so `--fixed-fps` runs are frame-identical. 0 lights are ever created.

## 3. Other pieces
- `CinematicStage` (`cinematic_stage.gd`, `extends Node3D`): root of stage scenes. `@export autoplay_script`,
  `autoplay := true`, `prewarm_frames := 2`, `render_scale := true`; `cinematic_actor(tag)` (sets' `puppet(tag)`,
  then children by name, case-insensitive), `set_active_set(id)`, `sets() -> Array[Node3D]`, `find_set(id)`,
  `markers_for(prefix) -> Dictionary`; recording mode when `Engine.get_write_movie_path() != ""` or
  `force_recording` (0.5 s black head / tail, then `get_tree().quit()` unless `quit_when_done` is false; signal `recording_done`).
  `start(script) -> String` plays on demand; signal `cinematic_done(id, skipped)`; `is_black()`; `register_actor(tag, node)`.
  Added 2026-09-27: `@export actor_paths` (tag -> NodePath, registered at `_ready`), `@export lighting_rig` (a
  LightingRig child: `set_active_set` applies the set's `lighting`, else the rig's own preset).
- **Campaign prologue** (2026-09-27): `scenes/cinematics/prologue_3min.tscn` (CinematicStage, 5 World Forge sets, cast,
  dragon flocks) + `data/cinematics/prologue_3min.tres`, both written by `tools/cine/cine_stage_export.gd`. `MenuFlow.
  start_campaign_mission` plays it before mission 1 until `CampaignState.is_seen(&"prologue_3min")`; the Campaign
  menu's "Watch prologue" replays it (`MenuFlow.play_prologue`). Test: `tests/test_campaign_prologue.gd`.
- `vfx` with `scene`: `yaw` / `scale` / `to` (`set_cine_target`) are applied before it enters the tree; a scene with
  `set_cine_age(age)` (art/cinematics/fx) is posed from the cinematic clock every frame and freed after `life`.
  Line voices play at -2 dB.
- `CinematicInput` (`cinematic_input.gd`): `static ensure_actions()`; the node reads `cinematic_skip` /
  `cinematic_advance` / `cinematic_pause` in `_input` and consumes them.
- `CastProxy` (`cast_proxy.gd`, `extends Node3D`, group `"heroes"`): `setup(model, kingdom)`, `get_model()`,
  `cast(spell_id, at, travel_time := 0.6)` (prologue 2.4).
- `CinematicOverlay` (`scripts/ui/cinematic/cinematic_overlay.gd`, CanvasLayer 85): `open(aspect)`, `close()`,
  `show_line(speaker, text, duration)`, `end_line()`, `show_skip_prompt()`, `set_paused_view(on)`, `set_fade(color, a)`,
  `show_title(text, sub, time)`, `static bar_height(screen: Vector2, aspect: float) -> float` (115 / 43 / 32 px at
  1600x900 / 3440x1440 / 2560x1080).
- `Speakers` (`scripts/ui/cinematic/speakers.gd`): `static name_of(id)`, `color_of(id)`, `portrait_of(id)`.

## 4. Set contract (prologue 2.3) as the player reads it
Set root in group `"cinematic_sets"` with `set_id`; optional `set_active(on)`, `begin_shot(shot_id)`, `end_shot(shot_id)`,
`puppet(tag)`. Camera for a shot with `marker_prefix` P: `Shots/P_from`, `P_to`, `P_look_from`, `P_look_to`,
optional `P_pivot` (ORBIT: radius / angles / height from `_from` / `_to` around it), `Path3D P_rail`, metadata `fov` on
`_from` / `_to`. If the set has no `P_from` marker, the player reads `<set folder>/marks.json`
`{P: {from, to, look_from, look_to, fov_from, fov_to}}` (vectors as `[x, y, z]`). Missing keys keep the shot's fields.
- `begin_shot` may reset the set's puppets (World Forge sets do): actors this play has moved / teleported / turned keep
  their pose over it (in play and after `seek`), so the timeline's end states carry over cuts.
- **Set cue API (U2, 2026-09-27)**: optional `cine_cues(shot_id: StringName) -> Array` of cue Dictionaries
  `{at, kind, actor, target, params}` (kind default `vfx`; only vfx / sfx / anim / clip / shake; `target` / `to` in the
  set root's local space; shortcut keys `scene`, `vfx_id`, `life`, `scale`, `yaw`, `to`, `hook`, `arg`, `path`,
  `volume_db`, `amount`, `travel_time` go to params). The player merges them into the timeline at `play` (seek /
  skip treat them like any cosmetic action) unless the shot already has baked set cues (params `from_set`, written by
  `cine build`). Statics `CinematicPlayer.set_cues(set_node, shot) -> Array[CinematicAction]`, `cue_action(cue, xform)`;
  `fire_cue(cue, set_node := null)` fires one cue now (outside the timeline: seek / stills do not see it).
  Example: `return [{"at": 0.8, "vfx_id": &"frost_nova", "actor": &"torvald", "target": Vector3(0, 0, 4)}]`.

## 5. Runtime notes (for tools 2 `cine`, 6 World Forge, 10 Script Desk)
- **Stills / checks without pixels**: `var p := CinematicPlayer.new()` (add it where the camera must render, e.g. inside
  your SubViewport; `instance()` returns the first player in the group), set `p.use_overlay = false` (or keep it for the
  bars), `p.emit_events = false`, `p.log_enabled = false`, then `p.play(script, stage)`, `p.seek(t)` and read
  `p.debug_state()` right away (the camera is already placed; no frame needed). `p.stop()` when done.
- `shot_index()` / `play_from(i)` / `shot_start(i)` use indices in `script.shots`; branch shots whose flag fails are
  dropped (0 s). Flags: `context.cinematic_flag(name)` if the context has it, else `CampaignState.flag(name)`.
- Everything is timed from the shot start; line / action `at` values are clamped into the shot; a line never
  outlives its shot. Frame count of a play at `--fixed-fps F` = `round(total_duration() x F)` +- 1.
- Actors: the context (stage) resolves `cinematic_actor(tag)`: registered tags, the active set's `puppet(tag)`, other
  sets' `puppet(tag)`, then a stage child whose name matches the tag (case-insensitive). Unknown tags warn once
  (`[cine] unknown actor "x"`) and the action is skipped (never an error).
- Yaw convention (the game's, `Unit._face`): models face **+Z** at yaw 0; `yaw_deg` = `rotation.y` in degrees and a
  direction `d` gives `yaw = atan2(d.x, d.z)` (so yaw 90 faces +X). `move` / `face` (and `CastProxy.cast` when its opt-in `face_target` is true) use it.
- Sets (tool 6): root `Node3D` in group `"cinematic_sets"` with `@export var set_id: StringName`. Markers under
  `Shots/`; if absent, `marks.json` next to the set's `.tscn` (vectors in the set root's local space, `[x, y, z]`).
  ORBIT from markers needs `<P>_pivot` + `_from` / `_to`; RAIL needs `Path3D <P>_rail` (only the rail is enough).
- Camera: near 0.1, far 250, fov lerp `fov_from -> fov_to` with the shot's ease; shake is seeded (`shake_seed`) and a
  pure function of time. The player never creates lights; `vfx` with `scene` instances it for `life` s.
- `vfx_id` routes to the first node in group `"composer_vfx"` (`play(id, at, target_actor)`), else to a `CastProxy`
  actor (`cast(id, target)`: SpellVfx / IceVfx / NatureVfx draw the real spell), else a warning.
- Input in tests: `root.push_input(InputEventAction)` with `cinematic_skip` / `cinematic_advance` / `cinematic_pause`.
- Test: `tests/test_tool_cine_runtime.gd` (prints `PASS tool_cine_runtime`) is also a complete code example of a
  4-shot script built in code.