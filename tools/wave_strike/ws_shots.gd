extends SceneTree
## Wave Strike screenshot pass (windowed; M1): the lobby page, then a bot-vs-bot match on Ashwind Reach with the
## player's HUD, shots at fixed game times with the camera on the action. PNGs in docs/tools/wave_strike/shots/.
## Run (windowed, not --headless):
##   tools\godot_run.ps1 --path . -s tools/wave_strike/ws_shots.gd --resolution 1600x900 --quit-after 30000
## Args (after "--"): --speed=4 (Engine.time_scale)  --out=res://docs/tools/wave_strike/shots

const SCENE := "res://scenes/wave_strike.tscn"
const MENU := "res://scenes/ui/main_menu.tscn"
## [game time s, name, camera focus: "start" / "mid" / "front" / "enemy_bastion", zoom]
const SHOTS := [
	[12.0, "ws_hud_start", "start", 34.0],
	[46.0, "ws_first_clash", "front", 30.0],
	[110.0, "ws_lane_wide", "mid", 55.0],
	[200.0, "ws_wave_close", "front", 22.0],
	[420.0, "ws_midgame", "front", 34.0],
	[660.0, "ws_late", "front", 40.0],
]

var level: Node
var menu: Node
var out_dir := "res://docs/tools/wave_strike/shots"
var speed := 4.0
var _i := 0
var _frames := 0
var _phase := 0
var _menu_frames := 0
var shots: Array[String] = []


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		var s := a.trim_prefix("--")
		if s.begins_with("speed="):
			speed = float(s.substr(6))
		elif s.begins_with("out="):
			out_dir = s.substr(4)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	menu = (load(MENU) as PackedScene).instantiate()
	root.add_child(menu)
	current_scene = menu


func _process(_delta: float) -> bool:
	_frames += 1
	if _phase == 0:
		_menu_frames += 1
		if _menu_frames == 20 and menu.has_method(&"show_wave_strike"):
			menu.call(&"show_wave_strike")
		if _menu_frames == 60:
			_save("ws_lobby")
			menu.queue_free()
			level = (load(SCENE) as PackedScene).instantiate()
			level.set(&"autopilot_player", true)
			var p: Array[String] = ["hammer", "steward"]
			level.set(&"personalities", p)
			root.add_child(level)
			current_scene = level
			_phase = 1
		return false
	var director: Node = level.get(&"director")
	if director == null:
		return _frames > 6000
	Engine.time_scale = speed
	if _i >= SHOTS.size() or bool(level.get(&"game_over")):
		Engine.time_scale = 1.0
		print("WS_SHOTS %s" % ", ".join(shots))
		return true
	var t := float(director.get(&"time"))
	var shot: Array = SHOTS[_i]
	var cam: Node = level.get(&"camera_rig")
	if t >= float(shot[0]) - 1.5 and cam:
		cam.call(&"focus_on", _focus(String(shot[2])))
		cam.set(&"_zoom", float(shot[3]))
		cam.set(&"_target_zoom", float(shot[3]))
		cam.call(&"_apply_zoom")
	if t >= float(shot[0]):
		Engine.time_scale = 1.0
		_save(String(shot[1]))
		_i += 1
	return false


## The camera focus for a shot: the player's start, the lane middle, the front line (the mean x of the lane units
## nearest the middle), the enemy Bastion.
func _focus(kind: String) -> Vector3:
	var start: Vector3 = level.call(&"start_position", 0)
	match kind:
		"start":
			return start + Vector3(16.0, 0.0, 6.0)
		"mid":
			return Vector3(0.0, 0.0, 6.0)
		"enemy_bastion":
			return (level.get(&"bastions")[1] as Node3D).global_position + Vector3(-12.0, 0.0, 6.0)
	var units: Array = level.call(&"lane_units", -1)
	if units.is_empty():
		return Vector3(0.0, 0.0, 6.0)
	# the front: the median x of all lane units
	var xs: Array[float] = []
	for u: Node3D in units:
		xs.append(u.global_position.x)
	xs.sort()
	return Vector3(xs[xs.size() / 2], 0.0, 6.0)


func _save(name: String) -> void:
	var img := root.get_texture().get_image()
	var path := "%s/%s.png" % [out_dir, name]
	img.save_png(ProjectSettings.globalize_path(path))
	shots.append(path)
	print("WS_SHOT %s" % path)
