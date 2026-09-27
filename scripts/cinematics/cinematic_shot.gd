class_name CinematicShot
extends Resource
## One camera shot (docs/design/cinematics.md 2.2 + prologue 2.1 `stage_set` / `marker_prefix` + tools-wave 2).
## FROZEN field list: scripts/cinematics/README.md (add only, never rename).
## Spec names `ease` / `trans` are `ease_type` / `trans_type` here (`ease` is a global GDScript function).

enum CameraMode { STATIC, DOLLY, CRANE, ORBIT, RAIL, FOLLOW }
enum Transition { CUT, FADE_BLACK, FADE_WHITE, BLEND_FROM_GAME }

## Shot id (`P11`, `s1`...): marker lookups, set `begin_shot(id)`, stills / timing sheets, debug_state.
@export var id: StringName = &""
## Seconds.
@export var duration: float = 2.0
@export var camera_mode: CameraMode = CameraMode.STATIC
@export var from_pos: Vector3 = Vector3(0, 2, 6)
@export var to_pos: Vector3 = Vector3(0, 2, 6)
@export var look_from: Vector3 = Vector3.ZERO
@export var look_to: Vector3 = Vector3.ZERO
## If set, the camera looks at that actor (+ look_offset) instead of look_from / look_to.
@export var look_actor: StringName = &""
@export var look_offset: Vector3 = Vector3(0, 1.6, 0)
## ORBIT centre: the actor if set, else `pivot`.
@export var pivot_actor: StringName = &""
@export var pivot: Vector3 = Vector3.ZERO
@export var orbit_radius: float = 6.0
@export var orbit_height: float = 2.0
@export var orbit_from_deg: float = 0.0
@export var orbit_to_deg: float = 90.0
## RAIL: a Path3D (relative to the context / stage; absolute paths work too). "" + marker_prefix = `<prefix>_rail`.
@export var rail: NodePath = NodePath("")
@export var follow_actor: StringName = &""
## FOLLOW: offset in the actor's local space (smoothed).
@export var follow_offset: Vector3 = Vector3(0, 3, 6)
@export var fov_from: float = 45.0
@export var fov_to: float = 45.0
@export var roll_deg: float = 0.0
@export var ease_type: Tween.EaseType = Tween.EASE_IN_OUT
@export var trans_type: Tween.TransitionType = Tween.TRANS_SINE
@export var transition_in: Transition = Transition.CUT
## Fades: half out (end of the previous shot), half in (start of this one). Blends: the whole time.
@export var transition_time: float = 0.5
## Last shot of an in-mission cutscene: ends exactly at the game camera's view.
@export var blend_to_game: bool = false
## 0-1 camera trauma at the shot start (decays 1.0 / s).
@export var shake: float = 0.0
## > 0 = far blur distance (STAGE, High graphics only).
@export var dof_far: float = 0.0
## "flag" = play only if the campaign flag is true, "!flag" = only if false. A skipped shot takes 0 s.
@export var branch_flag: String = ""
## Times from the shot start.
@export var lines: Array[CinematicLine] = []
## Times from the shot start.
@export var actions: Array[CinematicAction] = []
## STAGE: the set (group "cinematic_sets", `set_id`) shown during this shot; &"" = keep the current one.
@export var stage_set: StringName = &""
## Marker prefix in the set (`<prefix>_from`, `_to`, `_look_from`, `_look_to`, `_pivot`, `_rail`) or the key in the
## set's `marks.json`. &"" = use the coordinates above.
@export var marker_prefix: StringName = &""


static func make(p_id: StringName, p_duration: float, p_mode: CameraMode = CameraMode.STATIC) -> CinematicShot:
	var s := CinematicShot.new()
	s.id = p_id
	s.duration = p_duration
	s.camera_mode = p_mode
	return s


func add_line(p_at: float, p_speaker: StringName, p_text: String, p_duration: float = 0.0) -> CinematicLine:
	var l := CinematicLine.make(p_at, p_speaker, p_text, p_duration)
	lines.append(l)
	return l


func add_action(p_at: float, p_kind: StringName, p_actor: StringName = &"", p_target: Vector3 = Vector3.ZERO,
		p_params: Dictionary = {}) -> CinematicAction:
	var a := CinematicAction.make(p_at, p_kind, p_actor, p_target, p_params)
	actions.append(a)
	return a
