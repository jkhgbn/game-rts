extends SceneTree
## Horizon fit before / after shots (windowed, not --headless): Crown Hollow (skirmish.tscn) and Wave Strike on Ashwind
## Reach (wave_strike.tscn, with the pad camera P). PNGs in docs/art/horizon_fit/<tag>/.
## Run:
##   tools\godot_run.ps1 --path . -s res://art/environment/horizon/horizon_shots.gd --resolution 1600x900 --fixed-fps 60
##       --quit-after 6000 -- --tag=after [--level=crown|ws|both] [--nofit]

const SKIRMISH := "res://scenes/skirmish.tscn"
const WAVE := "res://scenes/wave_strike.tscn"
const SETTLE := 150          ## frames after the level is added before the first shot
const HOLD := 45             ## frames between a camera setup and its shot

## [name, kind, a, b, c]: kind "rig" = game camera focus a (Vector3), zoom b; "free" = own camera at a looking at b;
## "pad" = Wave Strike pad camera (P).
const CROWN_SHOTS := [
	["crown_north_edge", "rig", Vector3(0.0, 0.0, -46.0), 55.0],
	["crown_se_corner", "rig", Vector3(46.0, 0.0, 46.0), 55.0],
	["crown_west_edge", "rig", Vector3(-46.0, 0.0, 0.0), 55.0],
	["crown_overview", "free", Vector3(0.0, 150.0, 175.0), Vector3(0.0, 0.0, 0.0)],
]
const WS_SHOTS := [
	["ws_pad_camera", "pad"],
	["ws_west_end", "rig", Vector3(-80.0, 0.0, 0.0), 55.0],
	["ws_east_end", "rig", Vector3(80.0, 0.0, 0.0), 55.0],
	["ws_overview", "free", Vector3(0.0, 175.0, 150.0), Vector3(0.0, 0.0, 0.0)],
]

var tag := "after"
var which := "both"
var nofit := false     ## --nofit: the ring as baked (60 x 60), i.e. the look before HorizonFit
var out_dir := ""
var level: Node
var _queue: Array = []        # [scene path, shots]
var _shots: Array = []
var _i := 0
var _f := 0
var _cam: Camera3D


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		var s := a.trim_prefix("--")
		if s.begins_with("tag="):
			tag = s.substr(4)
		elif s.begins_with("level="):
			which = s.substr(6)
		elif s == "nofit":
			nofit = true
	out_dir = "res://docs/art/horizon_fit/%s" % tag
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	if which != "ws":
		_queue.append([SKIRMISH, CROWN_SHOTS])
	if which != "crown":
		_queue.append([WAVE, WS_SHOTS])
	_next_level()


func _next_level() -> void:
	if level != null:
		level.queue_free()
		level = null
	if _queue.is_empty():
		print("HORIZON SHOTS DONE %s" % out_dir)
		quit()
		return
	var item: Array = _queue.pop_front()
	level = (load(String(item[0])) as PackedScene).instantiate()
	if String(item[0]) == WAVE:
		level.set(&"autopilot_player", true)
	root.add_child(level)
	current_scene = level
	_shots = item[1]
	_i = 0
	_f = 0
	_cam = null


func _process(_delta: float) -> bool:
	if level == null:
		return false
	_f += 1
	if _f < SETTLE:
		return false
	var k := _f - SETTLE
	var shot_i := k / HOLD
	var step := k % HOLD
	if shot_i >= _shots.size():
		_next_level()
		return false
	var shot: Array = _shots[shot_i]
	if step == 0:
		var rig := _rig()
		if rig != null:
			rig.set(&"edge_pan_enabled", false)   # the mouse in the window must not pan the shot
		var hz: Node = level.get_node_or_null(^"Horizon")
		if nofit and hz != null and hz.has_method(&"fit_to"):
			hz.call(&"fit_to", 60.0, 60.0)
		_setup(shot)
	elif String(shot[1]) == "rig" and step < HOLD - 2:
		_rig_hold(shot)
	if step == HOLD - 8:
		_hide_hud(level)
	elif step == HOLD - 1:
		var hf: Node = level.get_node_or_null(^"Horizon")
		var info := ""
		if hf != null and hf.get(&"fitted_half") != null:
			info = " fitted_half=%s" % str(hf.get(&"fitted_half"))
		print("map %s x %s%s" % [MapInfo.size_x, MapInfo.size_z, info])
		_save(String(shot[0]))
	return false


func _rig() -> Node:
	return level.get(&"camera_rig") as Node


func _setup(shot: Array) -> void:
	var kind := String(shot[1])
	if kind == "free":
		if _cam == null:
			_cam = Camera3D.new()
			_cam.fov = 50.0
			_cam.far = 600.0
			level.add_child(_cam)
		_cam.position = shot[2]
		_cam.look_at(shot[3], Vector3.UP)
		_cam.make_current()
		return
	if _cam != null:
		_cam.queue_free()
		_cam = null
		var rig := _rig()
		if rig != null and rig.get(&"camera") != null:
			(rig.get(&"camera") as Camera3D).make_current()
	if kind == "pad":
		var hud: Node = level.get(&"ws_hud")
		if hud != null:
			hud.call(&"toggle_pad_camera")
		else:
			push_error("horizon_shots: no ws_hud")
		return
	_rig_hold(shot)


func _rig_hold(shot: Array) -> void:
	var rig := _rig()
	if rig == null:
		return
	rig.call(&"focus_on", shot[2])
	rig.set(&"_zoom", float(shot[3]))
	rig.set(&"_target_zoom", float(shot[3]))
	rig.call(&"_apply_zoom")


## Hides every HUD layer (the shots compare the 3D view; the STR / INT pick dims the screen).
func _hide_hud(n: Node) -> void:
	for c: Node in n.get_children():
		if c is CanvasLayer:
			(c as CanvasLayer).visible = false
		else:
			_hide_hud(c)


func _save(nm: String) -> void:
	var img := root.get_texture().get_image()
	var path := "%s/%s.png" % [out_dir, nm]
	img.save_png(ProjectSettings.globalize_path(path))
	print("HORIZON_SHOT %s" % path)
