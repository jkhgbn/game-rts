class_name CinematicStage
extends Node3D
## Root script of stage scenes (cinematics.md 5 STAGE + 8.3 recording; prologue 2.2 / 2.3).
## Children: the set scenes (group "cinematic_sets", all at the origin, one active), puppets, markers, rails, one
## DirectionalLight3D + WorldEnvironment (0 other lights), VFX hubs. The stage is the player's `context`.
##
## Recording mode (`Engine.get_write_movie_path() != ""` or `force_recording`): no input, no skip, no focus-loss pause,
## subtitles off, title card on, 0.5 s black head and tail, then `get_tree().quit()` (unless `quit_when_done` false).

signal recording_done
signal cinematic_done(id: StringName, skipped: bool)

const HEAD_TAIL := 0.5
const TARGET_PIXELS := 2000000.0
const MIN_SCALE := 0.5

@export var autoplay_script: CinematicScript
@export var autoplay := true
## Frames each set is shown under black before the first shot (pipeline prewarm).
@export var prewarm_frames := 2
## Root viewport render scale (menu diorama method: ~2 MP, FSR 1, min 0.5), restored on exit.
@export var render_scale := true
@export var force_recording := false
@export var quit_when_done := true

var player: CinematicPlayer = null
var _actors: Dictionary = {}
var _active_set: StringName = &""
var _saved_scale := -1.0
var _saved_mode := -1
var _black: ColorRect = null
var _black_layer: CanvasLayer = null


func is_recording() -> bool:
	return force_recording or Engine.get_write_movie_path() != ""


func _ready() -> void:
	if render_scale:
		_apply_render_scale()
	if autoplay and autoplay_script != null:
		_start.call_deferred()


func _exit_tree() -> void:
	if _saved_scale >= 0.0:
		var vp := get_viewport()
		if vp:
			vp.scaling_3d_scale = _saved_scale
			vp.scaling_3d_mode = _saved_mode as Viewport.Scaling3DMode
		_saved_scale = -1.0


## Plays `script` on this stage (autoplay calls it with `autoplay_script`). Returns the player's `play` result.
func start(script: CinematicScript) -> String:
	autoplay_script = script
	return await _start()


func _start() -> String:
	var rec := is_recording()
	player = CinematicPlayer.instance(get_tree())
	player.recording = rec
	if not player.finished.is_connected(_on_finished):
		player.finished.connect(_on_finished)
	var all := sets()
	if rec or (prewarm_frames > 0 and all.size() > 1):
		_show_black(true)
	if prewarm_frames > 0 and all.size() > 1:
		for s in all:
			set_active_set(StringName(str(s.get(&"set_id"))))
			for i in prewarm_frames:
				await get_tree().process_frame
	if rec:
		await _wait(HEAD_TAIL)
	_show_black(false)
	var err := player.play(autoplay_script, self)
	if err != "":
		push_warning("[cine] stage: play refused: %s" % err)
	return err


func _on_finished(id: StringName, skipped: bool) -> void:
	if player != null and player.finished.is_connected(_on_finished):
		player.finished.disconnect(_on_finished)
	cinematic_done.emit(id, skipped)
	if is_recording():
		_show_black(true)
		await _wait(HEAD_TAIL)
		recording_done.emit()
		if quit_when_done:
			get_tree().quit()


func _wait(seconds: float) -> void:
	var left := seconds
	while left > 0.0:
		await get_tree().process_frame
		left -= get_process_delta_time()


func _show_black(on: bool) -> void:
	if on and _black == null:
		_black_layer = CanvasLayer.new()
		_black_layer.layer = 84
		_black_layer.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_black_layer)
		_black = ColorRect.new()
		_black.color = Color.BLACK
		_black.set_anchors_preset(Control.PRESET_FULL_RECT)
		_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_black_layer.add_child(_black)
	if _black_layer != null:
		_black_layer.visible = on


func is_black() -> bool:
	return _black_layer != null and _black_layer.visible


func _apply_render_scale() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	var sz := Vector2(vp.get_visible_rect().size)
	if sz.x <= 0.0 or sz.y <= 0.0:
		return
	_saved_scale = vp.scaling_3d_scale
	_saved_mode = vp.scaling_3d_mode
	var k := clampf(sqrt(TARGET_PIXELS / (sz.x * sz.y)), MIN_SCALE, 1.0)
	if k < 1.0:
		vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
	vp.scaling_3d_scale = k


# ------------------------------------------------------------------ context API (read by CinematicPlayer)

func register_actor(tag: StringName, node: Node3D) -> void:
	_actors[tag] = node


func cinematic_actor(tag: StringName) -> Node3D:
	if _actors.has(tag) and is_instance_valid(_actors[tag]):
		return _actors[tag]
	var active := find_set(_active_set)
	if active != null and active.has_method(&"puppet"):
		var p := active.call(&"puppet", tag) as Node3D
		if p != null:
			return p
	for s in sets():
		if s != active and s.has_method(&"puppet"):
			var p2 := s.call(&"puppet", tag) as Node3D
			if p2 != null:
				return p2
	var want := String(tag).to_lower()
	for c in get_children():
		if c is Node3D and String(c.name).to_lower() == want:
			return c
	return null


## Set roots under this stage (group "cinematic_sets").
func sets() -> Array[Node3D]:
	var out: Array[Node3D] = []
	for n in get_tree().get_nodes_in_group(&"cinematic_sets"):
		if n is Node3D and is_ancestor_of(n):
			out.append(n)
	return out


func find_set(id: StringName) -> Node3D:
	if id == &"":
		return null
	for s in sets():
		if StringName(str(s.get(&"set_id"))) == id:
			return s
	return null


func active_set_id() -> StringName:
	return _active_set


func set_active_set(id: StringName) -> void:
	_active_set = id
	for s in sets():
		var on := StringName(str(s.get(&"set_id"))) == id
		if s.has_method(&"set_active"):
			s.call(&"set_active", on)
		else:
			s.visible = on
			s.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED


## Camera markers for a shot prefix in the given set (or the active one): see CinematicPlayer.read_markers.
func markers_for(prefix: StringName, set_id: StringName = &"") -> Dictionary:
	var s := find_set(set_id if set_id != &"" else _active_set)
	if s == null:
		s = self if get_node_or_null(^"Shots") != null else null
	return CinematicPlayer.read_markers(s, prefix)
