# Cinematics: tech spec (ENGINE player + VIDEO pipeline)

Task 19.D1, written 2026-09-26. The content (which cinematics, shot lists, lines) is in `story-episode-1.md` section 7;
this file is the system that plays them. Source of truth for tasks 19.C1, 19.C2, 19.C8-19.C10, 19.U1-19.U3, 19.V18,
19.L1-19.L3. Godot 4.7.2, GDScript, static types. Seconds, metres; screen sizes in pixels.
**Future work** (step 19, after steps 12-18): complete spec, not scheduled yet. The VIDEOs are **later production**
(recorded last); until they exist the game plays their fallback text cards (8.5), so nothing waits on video.

## 0. Decisions in one table
| Question | Decision | Why |
|---|---|---|
| Video or engine | **Hybrid.** VIDEO (pre-rendered `.ogv`, later production) for the 5 big moments (the assassination attempt, the twist memory, the boss reveal, the rescue: Old Vey's storm, the ending). ENGINE for everything else: between-mission scenes on small stage scenes, short in-mission cutscenes, credits | Video buys quality the game can't afford live (hi-res models, real lights, fog, a full lightning storm) and characters that never appear in play (the Master, young Obren). Engine keeps size at 0, can show the player's own choices (Pell branch, the companion) and never breaks when the game's look changes |
| Max length | **2:00 per cinematic** (user decision) | Short enough to never feel like a movie with a game attached |
| One data format for both | Every cinematic is a `CinematicScript` resource. A VIDEO is staged with the same shot-list format, recorded, and then played as a file | One tool, one mental model; the shot lists in the story doc map 1:1 to data |
| Where engine scenes run | **STAGE** (own small scene, between missions), **PAUSE** (in a mission, tree paused, camera-only), **HOLD** (in a mission, tree running, units dormant, actors walk) | Pausing is the safest; HOLD only when actors must really walk with navigation |
| Skip | **Esc or Space**, two presses (first shows the prompt); **one press** once the cinematic was seen before | No accidental skips the first time; no annoyance on retries |
| Pause / advance | **P** pauses and resumes; **Enter** ends the current subtitle early | Esc is taken by skip; Enter is already "next line" in the dialogue box |
| Input | Through the **Input Map** (3 new actions, physical keycodes) | First step toward rebinding; tests can press actions |
| Aspect | ENGINE: letterbox to **2.39:1** (bars on 16:9, thin 3 % bars on 21:9). VIDEO: **16:9 1920 x 1080 30 fps**, pillarboxed on 21:9 | 16:9 is the common screen; the user's ultrawide gets black side bars on videos and full-width engine scenes |
| Lights | Gameplay / in-game stage scenes: **0 new real lights** (the scene's one sun only). Video staging scenes (never shipped): anything | The perf rule stays; video pays its cost offline |
| Subtitles over video | **Drawn by the game**, never burnt in (except the episode title card) | Readable at any size, translatable later (French UI is on the backlog) |
| Save | Campaign save **before** each between-mission cinematic and **after** it; `cinematics_seen` list; retries skip the mission intro | Quitting in a cinematic never loses a mission |

## 1. Pieces and files
| Piece | Path | Owner |
|---|---|---|
| `CinematicScript`, `CinematicShot`, `CinematicLine`, `CinematicAction` resources | `scripts/cinematics/*.gd` | systems |
| `CinematicPlayer` (timeline, camera, actions, world modes) | `scripts/cinematics/cinematic_player.gd` | systems |
| `CinematicStage` (root script of stage scenes; recording mode) | `scripts/cinematics/cinematic_stage.gd` | systems |
| `CinematicInput` (Input Map actions, runtime fallback) | `scripts/cinematics/cinematic_input.gd` | systems |
| `StoryFlow` (between-mission sequencer) | `scripts/campaign/story_flow.gd` | systems |
| Cinematic data (18 for Episode 1 + video stage scripts) | `data/cinematics/<id>.tres` | systems |
| In-game stage scenes (`c1_offer`, `c2_two_fronts`, `c3_parley`, `ep1_credits`) | `missions/cinematics/<id>.tscn` | systems (set models from tech-artist) |
| `CinematicOverlay` (letterbox, subtitles, prompts) | `scripts/ui/cinematic/cinematic_overlay.gd` | ui |
| `VideoCinematic` (video screen) | `scripts/ui/cinematic/video_cinematic.gd` | ui |
| `Speakers` (names, colours, portraits) | `scripts/ui/cinematic/speakers.gd` | ui |
| In-game stage set models | `art/cinematics/stage_sets/<set>/` | tech-artist |
| Video staging scenes (**not exported**) | `art/cinematics/sets/<video_id>/stage.tscn` | tech-artist |
| Video-only hi-res models (**not exported**) | `art/cinematics/hires/` | tech-artist |
| Final videos | `art/cinematics/video/<video_id>.ogv` | tech-artist (19.V18) |
| Portraits | `art/portraits/<speaker>.png` (512 x 512) | tech-artist |
The lead adds the new folders to the ownership table and the export filter (19.L1).

## 2. Data
### 2.1 `CinematicScript` (Resource, `class_name CinematicScript`)
| Field | Type / default | Meaning |
|---|---|---|
| `id` | StringName | `ep1_intro`, `c1_offer`, ... (`story-episode-1.md` 7.1) |
| `title` | String | Theatre label |
| `kind` | int enum `ENGINE`, `VIDEO` | |
| `world_mode` | int enum `STAGE`, `PAUSE`, `HOLD` | ENGINE only (section 5) |
| `stage_scene` | String `""` | STAGE: the scene to load |
| `video_path` | String `""` | VIDEO: `res://art/cinematics/video/<id>.ogv` |
| `shots` | `Array[CinematicShot]` | ENGINE timeline (also used to stage a VIDEO) |
| `lines` | `Array[CinematicLine]` | VIDEO subtitle track (times from the video start) |
| `letterbox_aspect` | float 2.39 | ENGINE bars (section 6.1); 0 = no bars |
| `music_cue` | StringName `&""` | Played on the `Cinematic` bus (19.U6) |
| `skippable` | bool true | |
| `fallback_text` | String `""` | Shown as a text card (10 s, skippable) when a VIDEO file is missing or fails to load |
| `return_focus` | Vector3 `INF` | In-mission: where the RTS camera looks when control returns (INF = the player's wizard) |
| `total_duration() -> float` | | Sum of shot durations (VIDEO: from the file's length when known, else the last line's end) |
| `static find(id: StringName) -> CinematicScript` | | Loads `data/cinematics/<id>.tres` (null if missing) |

### 2.2 `CinematicShot` (Resource)
| Field | Type / default | Meaning |
|---|---|---|
| `duration` | float | Seconds (the shot-list column "Dur") |
| `camera_mode` | enum `STATIC`, `DOLLY`, `CRANE`, `ORBIT`, `RAIL`, `FOLLOW` | Section 3 |
| `from_pos`, `to_pos` | Vector3 | STATIC uses `from_pos`; DOLLY / CRANE move from -> to |
| `look_from`, `look_to` | Vector3 | Look-at point moving over the shot |
| `look_actor` | StringName `&""` | If set, the camera looks at that actor (+ `look_offset`) instead of `look_*` |
| `look_offset` | Vector3 `(0, 1.6, 0)` | Head height by default |
| `pivot_actor`, `pivot` | StringName / Vector3 | ORBIT centre |
| `orbit_radius`, `orbit_height`, `orbit_from_deg`, `orbit_to_deg` | float | ORBIT |
| `rail` | NodePath | RAIL: a `Path3D` in the stage or mission |
| `follow_actor`, `follow_offset` | StringName / Vector3 | FOLLOW (offset in the actor's local space, smoothed) |
| `fov_from`, `fov_to` | float 45, 45 | Degrees (the RTS camera uses 50) |
| `roll_deg` | float 0 | |
| `ease`, `trans` | `Tween.EaseType` IN_OUT, `Tween.TransitionType` SINE | Motion curve |
| `transition_in` | enum `CUT`, `FADE_BLACK`, `FADE_WHITE`, `BLEND_FROM_GAME` | How the shot starts; BLEND_FROM_GAME starts from the RTS camera's current transform |
| `transition_time` | float 0.5 | For fades and blends |
| `blend_to_game` | bool false | Last shot of an in-mission cutscene: ends exactly at the RTS camera's return view |
| `shake` | float 0 | 0-1 trauma, decays over the shot |
| `dof_far` | float 0 | > 0 = far blur distance (STAGE only, High graphics only; section 10) |
| `branch_flag` | String `""` | `"m1_peddler_freed"` = play only if the campaign flag is true; `"!m1_peddler_freed"` = only if false. A skipped branch shot takes 0 s |
| `lines` | `Array[CinematicLine]` | Times from the shot start |
| `actions` | `Array[CinematicAction]` | Times from the shot start |

### 2.3 `CinematicLine` (Resource)
`at: float`, `speaker: StringName`, `text: String`, `duration: float = 0.0` (0 = auto:
`max(2.5, 0.9 + 0.055 x characters)`, cut at the shot's end). The story doc's `A: ... / B: ...` = two lines in order.

### 2.4 `CinematicAction` (Resource)
`at: float`, `kind: StringName`, `actor: StringName`, `target: Vector3`, `params: Dictionary`, `on_skip: bool = true`.
| kind | params | Plays | End state (applied on skip, and at the end of a normal play) |
|---|---|---|---|
| `move` | `speed` (2.0), `path` (NodePath, optional) | STAGE: tween along a line / path, `set_moving(speed)`, face the way. HOLD: `command_move(target)` (real navigation) | Teleport to `target`, `set_moving(0)`, face the way, `reset_physics_interpolation()` |
| `teleport` | `yaw_deg` | Instant | Same |
| `face` | `yaw_deg` or `look_actor` | 0.3 s turn | Final yaw |
| `anim` | `hook` (`play_cast`, `play_attack`, `play_hit`, `play_gesture`, `play_kneel`, ...), `arg` | Calls the model hook (`has_method` guard) | Nothing (one-shot), except hooks listed in `params.final` |
| `spawn` | `scene` or `unit_type`, `team`, `tag`, `yaw_deg` | STAGE: instance a puppet; mission: `context.cinematic_spawn(tag, params)` | Spawned at `target` |
| `despawn` | `fade` (0.5) | Fade, then free / hide | Freed / hidden |
| `dormant` | `on` | Mission `_set_dormant` rule | Final state |
| `visible` | `node` (NodePath), `on` | Show / hide | Final state |
| `vfx` | `scene` or `vfx_id` | One-shot effect | Nothing (cosmetic) |
| `call` | `method`, `args` | `context.call(method, args...)` (e.g. `_seal_flash`, `open_barrier`) | Called on skip too (state!) unless `on_skip` false |
| `fade` | `color`, `alpha`, `time` | Full-screen fade | Final alpha |
| `music` | `cue` | Starts a cue | Stopped at the end |
| `shake` | `amount` | Camera trauma | - |
Actors are registered by tag: STAGE puppets by their node name (`Vessa`, `Malrik`...), missions through
`context.cinematic_actor(tag) -> Node3D` (the mission maps `&"vessa"` to its hero, `&"ysolde"` to the enemy or ally
Ysolde, `&"colossus"` to the boss...).

## 3. Camera
- The player owns one `Camera3D` (near 0.1, far **250**, `CameraAttributesPractical` for optional DOF). `play()` calls
  `make_current()` on it; the end calls `make_current()` on the RTS camera (`main.camera_rig.camera`) and
  `RTSCamera.focus_on(return_focus or the wizard)`. The RTS camera's own input is ignored while a cinematic plays.
- Per-frame (`_process`, the cinematic's own clock `t` advanced by `delta`, frozen while paused), with
  `k = ease(t / duration)`:
| Mode | Position | Look-at |
|---|---|---|
| STATIC | `from_pos` | `look_from` (or `look_actor`) |
| DOLLY | `from_pos.lerp(to_pos, k)` | `look_from.lerp(look_to, k)` |
| CRANE | as DOLLY with default ease IN_OUT CUBIC (reads as a crane move) | as DOLLY |
| ORBIT | `pivot + (cos a x r, orbit_height, sin a x r)`, `a = lerp(from_deg, to_deg, k)` | pivot + `look_offset` |
| RAIL | `PathFollow3D.progress_ratio = k` on `rail` | as DOLLY / `look_actor` |
| FOLLOW | `actor.global_transform * follow_offset`, smoothed `lerp(pos, 6 x delta)` | actor + `look_offset` |
- `fov = lerp(fov_from, fov_to, k)`; `roll_deg` applied after `look_at`; shake = small random offset and rotation
  scaled by `trauma²` (trauma decays 1.0 / s), seeded per cinematic so recordings repeat exactly.
- Transitions: CUT (default), FADE_BLACK / FADE_WHITE (a full-screen `ColorRect` in the overlay, half the time out,
  half in), BLEND_FROM_GAME (the first `transition_time` interpolates from the RTS camera transform).
- Framing rule for writers: keep faces and key action inside the central **2.39:1** band; on 16:9 the bars hide the rest.

## 4. Actors
- **STAGE puppets**: the unit model scenes (`art/units/...`, `unit_model.gd` hooks: `set_moving`, `play_cast`,
  `play_attack`, `play_hit`, `play_death`, `set_team_color`, new `play_gesture(id)` from 19.V10) placed in the stage
  scene without any `Unit` script: no AI, no navigation, no physics. Moves are tweens.
- **Mission actors**: real units. PAUSE mode: they do not move (teleports are applied right before the pause; their
  model node may be set to `PROCESS_MODE_ALWAYS` with `params.animate = true` so an idle / cast pose plays). HOLD mode:
  they move with `command_move` and the navmesh; their `move` action has a **timeout** of `2 x distance / speed + 1 s`
  after which the end state is forced (never stuck on a blocked path).

## 5. World modes
| Mode | Used by | Rules |
|---|---|---|
| **STAGE** | Between-mission scenes, credits, the Theatre | `StoryFlow` changes the current scene to `missions/cinematics/<id>.tscn` (root `CinematicStage`: puppets, markers, rails, one `DirectionalLight3D`, a `WorldEnvironment`). Nothing else runs. At `finished` StoryFlow moves on |
| **PAUSE** | Short camera-only mission cutscenes (`m0_fall`, `m1_seal`, `m2_heartfrost`, `m3_oldroot`, `m3_plea`, `m3_parting`, `m4_fall`), and the mid-mission VIDEOs (`m3_memory`, `m4_rise`, `m4_storm`) | `get_tree().paused = true`. `CinematicPlayer`, its camera, the overlay and nodes listed in `params.animate` / `vfx` actions run with `PROCESS_MODE_ALWAYS`. The mission clock, AI, units, projectiles and timers stop by themselves. At the end: restore every changed `process_mode`, unpause |
| **HOLD** | Mission cutscenes where actors walk (`m0_dawn`, `m4_war`) | Tree runs. `context.hold_world(true, actor_nodes)` (MissionBase): the mission clock stops (`mission_time()` excludes held time; waves, meters, `_after` timers read it), every Commander `set_paused(true)` (19.A1), every living unit in `"units"` **that is not an actor** goes dormant (the `mission_01.gd` `_set_dormant` rule; the hold keeps its own list so units already dormant for mission reasons stay dormant after). Economy ticks keep running (<= 45 s, negligible). At the end `hold_world(false)` restores exactly what it changed |
In every mode, while a cinematic plays: HUD and mission HUD hidden (`hud.set_cinematic_mode(true)` when the method
exists, else `visible = false`), SelectionManager ignores input, `Wizard.set_move_input(Vector3.ZERO)`, the pause
menu ignores Esc, the dialogue box queue is held (mission lines fired during the cinematic wait for its end, except
the cinematic's own lines which go to the overlay).
Order of `play()` for PAUSE / HOLD: apply `teleport` actions at `at == 0` of shot 1 -> enter the mode -> overlay in
(0.4 s, the bars grow while the first shot already runs) -> timeline. Order at the end (or skip): end states of all
remaining actions in timeline order -> leave the mode -> overlay out (0.3 s) -> camera back -> `finished`.

## 6. Overlay, subtitles, input
### 6.1 Letterbox (`CinematicOverlay`, CanvasLayer **85**: above the HUD and the briefing (80), below the pause menu (90))
Two black `ColorRect` bars. For a screen `W x H` and aspect `A` (2.39): `bar = max((H - W / A) / 2, 0.03 x H)`.
| Screen | Bar (each) |
|---|---|
| 1600 x 900 | 115 px |
| 1920 x 1080 | 138 px |
| 2560 x 1080 | 32 px (the 3 % minimum) |
| **3440 x 1440** (the user) | **43 px** (3 % minimum; the image itself is already 2.39:1) |
Bars slide in over 0.4 s (ease out) and out over 0.3 s. Recomputed on `size_changed`.

### 6.2 Subtitles
- Bottom-centre inside the bottom bar when the bar is >= 80 px; otherwise on a strip `(0, 0, 0, 0.45)` just above it.
  Max width 70 % of the screen, **2 lines max**, <= 48 characters per line (writers: split longer lines).
- `Speaker` name in its colour (`Speakers.color_of`) above the text; text white `UIStyle` panel font, 22 px at 900 p
  scaled with height, 2 px drop shadow. The Whisper shows as `???` in amber until `obren` is used.
- Timing from `CinematicLine` (auto rule in 2.3). A line fades in 0.15 s, out 0.15 s. `cinematic_advance` ends the
  current line at once (the next line keeps its own start time; never skips a shot).
- Video: the same widget, positioned inside the video rectangle (section 8.6), timed against the video position.

### 6.3 Portraits (talking heads, in missions)
The `DialogueBox` gets a 96 x 96 portrait left of the text (19.U3): `Speakers.portrait_of(id)` -> `art/portraits/<id>.png`
(512 x 512 painted renders, 19.V6); fallback the existing 3D `Portrait` of the speaker's unit if it is on the map, else
the 2-letter abbreviation. Cinematics show faces on screen, not portraits.
`Speakers` table (ids, names, colours): `story-episode-1.md` section 2. `DialogueBox.SPEAKER_COLORS` reads from it.

### 6.4 Input (Input Map, physical keycodes; `CinematicInput.ensure_actions()` adds them at runtime if the project
file lacks them, so tests and old builds work; the lead adds them to `project.godot` in 19.L1)
| Action | Keys | Effect |
|---|---|---|
| `cinematic_skip` | Escape, Space | First press: prompt `Esc / Space: skip` bottom-right for 2.5 s; a second press inside it skips. **Seen before** (`cinematics_seen`) or Theatre: one press skips. Not skippable (`skippable` false): ignored |
| `cinematic_advance` | Enter, Keypad Enter | Ends the current subtitle line |
| `cinematic_pause` | P | Pause / resume. Paused view: dim 30 %, `Paused · P: resume · Esc / Space: skip`. Window focus lost = pause (stays paused on return) |
- Handled in the overlay's `_input` (before any gameplay `_unhandled_input`), then `set_input_as_handled()`. Space is
  "centre on the wizard" in play: it never reaches the game during a cinematic.
- Mouse: clicks do nothing; the cursor hides after 2 s still; moving it shows the key hint line for 3 s.

## 7. Save points and the story flow (`StoryFlow` + `CampaignState`, 19.C2)
New optional keys in `user://campaign.json` (VERSION stays **1**; old saves load with defaults):
`"episode": 1`, `"cinematics_seen": ["ep1_intro", ...]`, `"resume": {"kind": "cinematic" | "choice" | "mission",
"id": "c1_offer" | "m02"}`. New `CampaignState` methods: `mark_seen(id)` (loads, appends, saves: touches only that
key, safe in the middle of a mission), `is_seen(id) -> bool`, `set_resume(kind, id)`.
| Moment | Save | Resume point after it |
|---|---|---|
| New episode | reset, then save | `cinematic ep1_intro` (then `m00`) |
| Intro cinematic ends / skipped | `mark_seen`, save | `mission m00` |
| M0 victory (`m0_dawn` already played in the mission) | save | `mission m01` (no between cinematic) |
| Mission victory M1-M3 (existing `on_mission_victory` save) | **save point before** the between cinematic | `cinematic c1_offer` (`c2_two_fronts`, `c3_parley`) |
| Between cinematic ends / skipped | **save point after**: `mark_seen`, save | `choice m02` (the artifact / companion choice screen) |
| Choice confirmed | save | `mission m02` |
| M4 victory -> `ep1_ending` -> credits end | `ep1_complete`, save | `episode 1 complete` (Continue greyed; Theatre + Missions stay) |
- **Continue** starts from `resume`. Quitting during a cinematic replays it on Continue (one-press skip: seen rule is
  per finished play, so a quit mid-way still needs two presses... unless it was finished once before).
- **Retry after a defeat**: the mission's pre-mission cinematic (only `ep1_intro` for M0) is skipped; in-mission
  cutscenes play again with one-press skip (they are marked seen at their first finish via `mark_seen`).
- **Missions list** (replay a completed mission): no between-mission cinematics, no change to `resume`.
- **Theatre**: every seen `VIDEO` and `STAGE` cinematic (in-mission ones need their mission world and are not listed).
- Mid-mission saves do not exist; nothing here adds them.

## 8. VIDEO pipeline
### 8.1 Staging (tech-artist, 19.V12-19.V17, 19.V21, 19.V22)
- One scene per video: `art/cinematics/sets/<video_id>/stage.tscn`, root `CinematicStage`, playing the video's shot
  list (`data/cinematics/<video_id>_stage.tres`, same format as ENGINE) with hi-res puppets from `art/cinematics/hires/`.
  The shot list is the story doc's table; the `.ogv` must match its timings within 0.5 s per shot (subtitles are timed
  from the story doc, so drift shows).
- **Allowed in staging scenes only** (never loaded by the game, excluded from export): any number of `OmniLight3D` /
  `SpotLight3D` / extra `DirectionalLight3D` **with shadows** (4 k shadow atlas, PCSS / soft shadows), SDFGI or VoxelGI,
  volumetric fog, SSAO, SSIL, SSR, glow, DOF (`CameraAttributesPhysical`), MSAA 8x + TAA, high-poly meshes (no LOD, no
  visibility ranges), 4 k textures, dense particles (tens of thousands), baked physics debris, hand-keyed animation.
  Limit: the recording PC's VRAM (GTX 1660: 6 GB; the laptop RTX 3070: 8 GB): keep each set under ~4 GB.
- Required: 1920 x 1080, 30 fps, the game's tonemap (so video and game colours match), no UI, the overlay off,
  sound (CC0 music bed + SFX) played by `AudioStreamPlayer`s in the stage so it is captured in sync.

### 8.2 Movie Maker in Godot 4.7.2 (what we know, what the probe must confirm)
- Movie Maker records a run to a file with `--write-movie <path>`; the **file extension picks the writer**. Built in
  since 4.0: **`.avi`** (MJPEG video + PCM audio) and **`.png`** (a numbered PNG sequence + one `.wav`). An **`.ogv`**
  writer (Theora video + Vorbis audio) was added in **Godot 4.5** as far as I know, so 4.7.2 should have it. **This is
  not verified on this machine**: 19.L2 runs a 5 s probe first.
- Time is fixed: every frame advances exactly `1 / fps` (`--fixed-fps 30`, or the Project Setting
  `editor/movie_writer/fps`), however slow it renders: max-quality settings only make the recording take longer.
  Audio is mixed offline and stays in sync. V-Sync is ignored while recording.
- It needs a real renderer: **no `--headless`** (the dummy renderer records nothing). It opens a window on the user's
  PC (Vulkan). The picture size is the window size: `--resolution 1920x1080` in windowed mode.
- Quality knobs live in Project Settings > Editor > Movie Writer (editor-only, they do not change the game):
  `video_quality` (MJPEG / OGV), and for OGV audio quality, encoding speed and keyframe interval. The probe reports
  the exact names in 4.7.2; the lead sets them in `project.godot` (19.L1 / 19.L2).
- The recording ends when the game quits: the stage calls `get_tree().quit()` itself (8.3); `--quit-after` is the
  safety net.

### 8.3 Recording (the `CinematicStage` recording mode, 19.C10; run by 19.V18 / the lead)
`CinematicStage._ready()`: if `Engine.get_write_movie_path() != ""` (Movie Maker active), play `autoplay_script` with
the overlay off and no skip input, wait 0.5 s after the last shot, then `get_tree().quit()`. The first frame is
held 0.5 s (black) so the video never starts mid-fade. Output goes **outside the project** (Godot must not import the
raw file), then the final `.ogv` is copied into `art/cinematics/video/`.
```powershell
$GODOT = "C:\Users\elzzo\Downloads\game gadot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
New-Item -ItemType Directory -Force "$env:USERPROFILE\Videos\four-wizards-rec" | Out-Null
& $GODOT --path . --windowed --resolution 1920x1080 --fixed-fps 30 `
  --write-movie "$env:USERPROFILE\Videos\four-wizards-rec\ep1_intro.ogv" `
  --quit-after 2900 "res://art/cinematics/sets/ep1_intro/stage.tscn"
```
(`--quit-after` = (length + 5 s) x 30 frames: 90 s -> 2 850, rounded up.)
**Probe (19.L2)**: a 5 s `probe/stage.tscn` (a spinning lit cube + a tone) recorded to `probe.ogv`, then opened in a
`VideoStreamPlayer` test scene: result OK when it plays with sound. Also record `probe.avi` to learn the MJPEG size.

### 8.4 Fallback if `.ogv` cannot be written directly (needs the user's approval)
Record `.avi` (MJPEG, `video_quality` 0.95: roughly 150-250 MB per minute at 1080p30) or `.png` (lossless: a 1080p
PNG is ~3 MB, so ~5 GB per minute: check the disk first), then convert with **ffmpeg** (libtheora + libvorbis):
```
ffmpeg -i ep1_intro.avi -c:v libtheora -q:v 7 -g 64 -c:a libvorbis -q:a 5 ep1_intro.ogv
ffmpeg -framerate 30 -i ep1_intro%08d.png -i ep1_intro.wav -c:v libtheora -q:v 7 -g 64 -c:a libvorbis -q:a 5 ep1_intro.ogv
```
(`-q:v` 0-10: 7 for fire, sparks and snow; 6 for calm shots. `-g 64` = a keyframe every ~2 s, smoother pause /
resume. The PNG numbering pattern is confirmed by the probe.) **ffmpeg is not installed. Downloading it (official
Windows build, ~100 MB) requires the user's approval; the lead asks (story doc question 4) and never downloads
without a yes.** If the answer is no: each VIDEO is shipped as its `fallback_text` card and the 5 moments are
rebuilt later as ENGINE stages with game assets.

### 8.5 Playback (`VideoCinematic`, 19.U2)
- A `CanvasLayer` (86) with a full-screen black `ColorRect`, an `AspectRatioContainer` (ratio 16 / 9, stretch FIT,
  centred) holding a `VideoStreamPlayer` (`expand` true, `stream = load(video_path)` as `VideoStreamTheora`,
  `bus = &"Cinematic"` if that bus exists else `&"Master"`), and the subtitle widget of 6.2 inside the video rect.
- `play()` -> `VideoStreamPlayer.play()`; `finished` -> `finished(id, false)`; skip -> `stop()` ->
  `finished(id, true)`; pause -> `paused = true` (and on focus loss). Subtitles follow `stream_position` (so they stay
  in sync after a pause). The mouse / key rules of 6.4 apply.
- While a video plays in a mission (V2, V3 happen mid-mission in PAUSE mode) the 3D world is not drawn:
  `get_viewport().disable_3d = true`, restored after. Between missions nothing else is loaded.
- Loading: start `ResourceLoader.load_threaded_request(video_path)` when the mission starts (M3, M4) or when the
  preceding scene starts, so the switch has no hitch.
- Missing / unloadable file: `push_warning`, show `fallback_text` as a text card (10 s, skippable) and emit
  `finished(id, false)` after it; with no fallback text, `finished` within 2 frames. The game never blocks on a video.
- Tests use `fake_duration > 0`: no stream, an internal clock drives the same code path.

### 8.6 16:9 video on the 21:9 ultrawide
At 3440 x 1440 the 16:9 video is drawn 2560 x 1440 in the middle with **440 px black bars left and right**
(pillarbox); at 1600 x 900 it fills the screen. Subtitles sit inside the video rectangle, 8 % above its bottom edge.
Knob (not the default): render the videos in "scope" 1920 x 804 (2.39:1): full width on 21:9, letterboxed on 16:9,
about 25 % smaller files; costs a softer upscale on the ultrawide (1920 -> 3440).

### 8.7 Export
The lead's export preset excludes `art/cinematics/sets/*` and `art/cinematics/hires/*` and includes `*.ogv`
(19.L1). Test: an export build contains the 5 `.ogv` and no staging file.

## 9. Size budget
| Rate (1080p30 Theora) | When | Episode 1 (5 videos, 7:00) |
|---|---|---|
| ~10 MB / min | Calm, dark, slow shots | ~70 MB |
| **~15 MB / min** | **Expected mix** | **~105 MB** |
| ~25 MB / min | Fire, sparks, lightning flashes, snow, dust waves everywhere | ~175 MB |
**Budget: <= 115 MB of video for Episode 1** (per video: `ep1_intro` 2:00 -> 30, `m3_memory` 1:00 -> 15, `m4_rise`
0:45 -> 12, `m4_storm` 1:45 -> 30 (lightning flashes are the most expensive frames), `ep1_ending` 1:30 -> 24 MB = 111).
The rest of the game is small (art is built from primitives and code), so video will be the biggest part of the
download: plan **<= 115 MB per episode**. Over budget -> in order: `-q:v` 7 -> 6 on calm shots, thin particle density
and film grain (noise costs the most bits), fewer full-screen lightning flashes (a flash forces a near-keyframe),
shorten held shots, 900 p render. 19.L3 checks the total.

## 10. Performance budget
| Where | Rule |
|---|---|
| ENGINE in missions | `PERF OK` must hold (same test, 60 fps at 1600 x 900; the user's GTX 1660 at 3440 x 1440). Camera far 250 m with the map's fog; **0 new real lights**; emission only; <= 3 extra particle systems alive per shot, <= 500 extra particles; no runtime material creation; no DOF |
| ENGINE stages | One `DirectionalLight3D` (sun or moon, the only shadow caster) + `WorldEnvironment`; 0 other lights (campfires, lanterns, windows = emission + particles); <= 150 extra draw calls over an empty map; DOF far blur only when the graphics setting is High; 60 fps on the GTX 1660 |
| Cinematic player | < 0.1 ms per frame (one camera transform, a few tweens, subtitle labels) |
| VIDEO | CPU Theora decode of 1080p30 (fine on both of the user's PCs); 3D disabled while playing |
| HOLD mode | Dormant units still cost their idle time; test: `m4_war` with 150 dormant units keeps 60 fps |
| Memory | Hi-res / staging assets never exported; a video streams from disk |

## 11. Proposed contracts (the lead freezes them in `CLAUDE.md`, 19.L1)
- **CinematicPlayer** (`scripts/cinematics/cinematic_player.gd`, `class_name CinematicPlayer extends Node`, group
  `"cinematic_player"`, `process_mode = ALWAYS`): `static instance(tree: SceneTree) -> CinematicPlayer` (creates one
  under the root if none), `static is_any_playing(tree: SceneTree) -> bool`, `play(script: CinematicScript,
  context: Node = null) -> String` (`""` = ok, else `"Already playing"`, `"Missing stage"`, `"No context"`),
  `skip() -> void`, `set_paused(on: bool) -> void`, `is_paused() -> bool`, `is_playing() -> bool`,
  `current_id() -> StringName`, `elapsed() -> float`, `register_actor(tag: StringName, node: Node3D)`,
  `actor(tag: StringName) -> Node3D`; signals `started(id: StringName)`, `shot_started(id: StringName, index: int)`,
  `line_started(speaker: StringName, text: String)`, `finished(id: StringName, skipped: bool)`. VIDEO scripts are
  handed to `VideoCinematic`; the signals are the same.
- **Resources**: `CinematicScript`, `CinematicShot`, `CinematicLine`, `CinematicAction` with the fields of section 2.
- **Context** (a mission or a stage; every method optional, `has_method` guarded): `cinematic_actor(tag) -> Node3D`,
  `cinematic_spawn(tag: StringName, params: Dictionary) -> Node3D`, `hold_world(on: bool, keep_awake: Array) -> void`,
  and the methods named by `call` actions. **MissionBase** adds `hold_world`, `mission_time() -> float` (excludes
  held time) and `play_cutscene(id: StringName) -> void`.
- **VideoCinematic** (`scripts/ui/cinematic/video_cinematic.gd`, CanvasLayer 86): `play(script) -> String`, `skip()`,
  `set_paused(on)`, `fake_duration: float`, signal `finished(id, skipped)`.
- **CinematicOverlay** (`scripts/ui/cinematic/cinematic_overlay.gd`, CanvasLayer 85): `open(aspect: float)`,
  `close()`, `show_line(speaker, text, duration)`, `end_line()`, `show_skip_prompt()`, `set_paused_view(on)`,
  `static bar_height(screen: Vector2, aspect: float) -> float`.
- **Speakers** (`scripts/ui/cinematic/speakers.gd`): `static name_of(id) -> String`, `color_of(id) -> Color`,
  `portrait_of(id) -> Texture2D` (null = none).
- **HUD** (ui): `set_cinematic_mode(on: bool)` on the HUD and the MissionHud (hide, block input, hold dialogue lines).
- **Commander** (ai): `set_paused(on: bool)` (no decisions, no casts, units keep their last orders).
- **Events** (lead): `cinematic_started(id: StringName)`, `cinematic_finished(id: StringName, skipped: bool)`, so
  audio, HUD and AI react without knowing the player.
- **Input Map**: `cinematic_skip` (physical Escape, Space), `cinematic_advance` (physical Enter, Keypad Enter),
  `cinematic_pause` (physical P).
- **CampaignState**: `cinematics_seen`, `resume`, `episode`, `mark_seen(id)`, `is_seen(id) -> bool`,
  `set_resume(kind: String, id: StringName)`; VERSION stays 1.

## 12. Headless tests (`--fixed-fps 60 --quit-after N`; never name the `Events` autoload in a test; Movie Maker and
real Theora decoding cannot run headless and are manual checks in 19.L2 / 19.L3)
| Test | Checks |
|---|---|
| `tests/test_19_c1.gd` (CinematicPlayer) | A synthetic 3-shot script (2.0 + 1.5 + 1.0 s) on an empty stage: `started`, 3 `shot_started` in order, `finished(false)` after 270 frames +- 1; lines emitted in order with auto durations; a DOLLY camera is at `to_pos` +- 0.01 m on its last frame. **Skip**: press `cinematic_skip` twice (`Input.parse_input_event` of an `InputEventAction`) during shot 2 -> `finished(true)` the next frame; a `move` actor is at its target +- 0.1 m, a `call` action with `on_skip` true ran once, a `vfx` did not. **One-press skip** when the id is marked seen. **Pause**: 60 paused frames add 0 to `elapsed()`. **Advance**: Enter ends a line, not the shot. **PAUSE mode**: the tree is paused during and unpaused after; a non-actor unit did not move. **HOLD mode** (a stub context): non-actor units dormant during, back in `"units"` with their aggro after; a unit that was dormant before stays dormant |
| `tests/test_19_u1.gd` (overlay) | `bar_height` = 115 at 1600 x 900, 43 at 3440 x 1440, 32 at 2560 x 1080; HUD hidden during and visible after (also after a skip); the pause menu does not open on Esc during a cinematic |
| `tests/test_19_u2.gd` (video screen, fake mode) | `fake_duration` 3 s: `finished(false)` after 180 frames; skip (two presses) -> `finished(true)`; pause stops the clock; a missing `video_path` with no fallback text -> `finished` within 2 frames and a warning; with fallback text -> the card shows, skip works |
| `tests/test_19_c2.gd` (story flow) | New episode -> resume `cinematic ep1_intro`; after its finish -> `mission m01`, `ep1_intro` in `cinematics_seen`; a faked `m00` victory -> `mission m01`; a faked `m01` victory -> `cinematic c1_offer`; after it -> `choice m02`; an old `campaign.json` without the new keys loads (defaults) and saves them; `mark_seen` in the middle of a mission does not change `items` |
| `tests/test_19_c9.gd` (in-mission cutscenes) | For each of the 9 (`m0_fall`, `m0_dawn`, `m1_seal`, `m2_heartfrost`, `m3_oldroot`, `m3_plea`, `m3_parting`, `m4_war`, `m4_fall`): full play vs skip at 1 s -> the same end snapshot (actor positions +- 0.2 m, dormant sets, objective states, spawned nodes, barrier / pylon states) |

## 13. Risks and open points
| Risk | Plan |
|---|---|
| The 4.7.2 Movie Maker has no `.ogv` writer | 19.L2 probe first; fallback 8.4 (ffmpeg only with the user's yes) |
| Some Theora files stutter or desync in Godot | Keyframe every <= 64 frames, 30 fps, test each file in the game on the user's PC (19.L3); re-encode with the ffmpeg line if needed |
| PAUSE mode freezes a VFX we wanted moving | Only nodes named in `animate` / `vfx` actions switch to `ALWAYS`; the test checks nothing else moves |
| HOLD mode side effects (economy ticks, a projectile in flight) | Dormant units keep full HP (death guard); cutscenes are <= 45 s; the test checks the restore |
| Esc means "pause menu" everywhere else | The pause menu checks `CinematicPlayer.is_any_playing()`; the overlay consumes the event first |
| Subtitle overflow on long lines | 2 lines x 48 characters max; 19.D3 reads every line in game |
| Video look drifts from the game's look after later art passes | Record last (phase 3), from sets that reuse the game's materials and tonemap |
