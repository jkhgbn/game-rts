extends SceneTree
## G-C Shadow units (docs/art/gc_shadow_units.md): before / after shots on the Art Lab stage (game lighting rig,
## skirmish ground, game camera pitch). WINDOWED only:
##   tools\godot_run.ps1 --path . -s res://art/units/shadow/tools/gc_shadow_shots.gd --quit-after 20000 '--' --gfx=high --tag=after
##   ... '--' --gfx=high --tag=before --before      (ShadowUnitDress off: the generated primitives, same scene)
##   ... '--' --gfx=high --perf [--before]          (240 Shadow Hall units at zoom 30, mean GPU / CPU ms; GC PERF line)
## Shots -> docs/art/lab/gc_shadow/shots/<tag>_<view>.png: hall_z30 (two Shadow squads, purple vs red, some walking /
## striking), hall_z10, row_z7 (the 5 Hall units side by side), portrait_left / _right (zoom ~4: shade + nightbolt,
## knight + thrall), dark_z30 (the squads on ash ground).

const STAGE := preload("res://tools/art_lab/lab_stage.gd")
const OUT := "res://docs/art/lab/gc_shadow/shots/"
const HALL: Array[String] = ["shade", "nightbolt", "grave_hound", "shadow_knight", "gloom_thrall"]
const SQUAD: Array[String] = ["shadow_knight", "shade", "shade", "shade", "grave_hound", "grave_hound", "nightbolt",
	"nightbolt", "nightbolt", "shadow_knight", "gloom_thrall", "gloom_thrall"]
const SHADOW := Color(0.42, 0.22, 0.60)
const RED := Color(0.78, 0.16, 0.12)

var stage: Node
var center := Vector3(-18.0, 0.0, 36.0)   # the lab's meadow point
var dark := Vector3(140.0, 0.0, -140.0)   # the ash patch
var tag := "after"
var perf := false
var models: Array[Node3D] = []


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--tag="):
			tag = a.substr(6)
		elif a == "--before":
			ShadowUnitDress.enabled = false
		elif a == "--perf":
			perf = true
	if DisplayServer.get_name() == "headless":
		print("GC SHOTS: windowed only")
		quit(2)
		return
	_run.call_deferred()


func _spawn(id: String, pos: Vector3, yaw: float, col: Color) -> Node3D:
	var m := (load("res://art/units/shadow/%s.tscn" % id) as PackedScene).instantiate() as Node3D
	m.position = pos
	m.rotation.y = yaw
	stage.world.add_child(m)
	m.call(&"set_team_color", col)
	models.append(m)
	return m


func _squads(at: Vector3) -> void:
	for side: int in 2:
		var col := SHADOW if side == 0 else RED
		var face: float = 0.0 if side == 0 else PI
		var z0: float = at.z + (2.6 if side == 0 else -2.6)
		for i: int in SQUAD.size():
			var row: int = i / 6
			var col_i: int = i % 6
			var dz: float = (1.7 * row) * (1.0 if side == 0 else -1.0)
			var m := _spawn(SQUAD[i], Vector3(at.x + (col_i - 2.5) * 1.6 + 0.3 * row, 0.0, z0 + dz), face + 0.25 * sin(i * 1.7), col)
			if (i + side) % 3 == 0:
				m.call(&"set_moving", float(m.get(&"stride_speed")))


func _strike() -> void:
	var k := 0
	for m: Node3D in models:
		k += 1
		if k % 4 == 1 and m.has_method(&"play_attack"):
			m.call(&"play_attack")


func _run() -> void:
	stage = STAGE.new()
	root.add_child(stage)
	stage.setup(&"warm")
	stage.vp.msaa_3d = Viewport.MSAA_4X
	await stage.warm()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	if perf:
		await _perf()
		quit(0)
		return
	_squads(center)
	_squads(dark)
	for i: int in HALL.size():
		_spawn(HALL[i], center + Vector3((i - 2.0) * 2.2, 0.0, 9.0), deg_to_rad(-18.0 + 9.0 * i), SHADOW)
	for i: int in 45:
		await process_frame
	_strike()
	for i: int in 8:
		await process_frame
	stage.game_cam(center, 30.0)
	_save(await stage.grab(), "hall_z30")
	stage.game_cam(center + Vector3(0, 0.6, 1.5), 10.0)
	_save(await stage.grab(), "hall_z10")
	stage.game_cam(center + Vector3(0, 0.9, 9.0), 7.5, 30.0)
	_save(await stage.grab(), "row_z7")
	stage.game_cam(center + Vector3(-3.3, 0.9, 9.0), 4.2, 22.0, 12.0)
	_save(await stage.grab(), "portrait_left")
	stage.game_cam(center + Vector3(3.3, 1.1, 9.0), 4.8, 22.0, -12.0)
	_save(await stage.grab(), "portrait_right")
	_strike()
	for i: int in 8:
		await process_frame
	stage.game_cam(dark, 30.0)
	_save(await stage.grab(), "dark_z30")
	print("GC SHOTS done: %s (%s)" % [OUT, tag])
	quit(0)


func _perf() -> void:
	var k := 0
	for gx: int in 20:
		for gz: int in 12:
			var m := _spawn(HALL[k % HALL.size()], center + Vector3((gx - 9.5) * 1.5, 0.0, (gz - 5.5) * 1.5), 0.0,
				SHADOW if gz < 6 else RED)
			if k % 2 == 0:
				m.call(&"set_moving", float(m.get(&"stride_speed")))
			k += 1
	for i: int in 60:
		await process_frame
	stage.game_cam(center, 30.0)
	var gpu := 0.0
	var cpu := 0.0
	var n := 0
	for i: int in 150:
		await RenderingServer.frame_post_draw
		if i >= 30:
			var ms: Vector2 = stage.render_ms()
			cpu += ms.x
			gpu += ms.y
			n += 1
	_save(await stage.grab(), "perf_240")
	print("GC PERF %s: %d units, gpu %.3f ms, cpu %.3f ms (mean of %d frames, MSAA 4x)" % [tag, k, gpu / n, cpu / n, n])


func _save(img: Image, view: String) -> void:
	var p := ProjectSettings.globalize_path(OUT + "%s_%s.png" % [tag, view])
	img.save_png(p)
	print("GC SHOT ", p)
