extends SceneTree
## G-C Fire units (docs/art/gc_fire_units.md): before / after shots of the whole Fire roster on the Art Lab stage
## (game lighting rig, skirmish ground, game camera pitch 55 / fov 50). WINDOWED only (headless renders nothing):
##   tools\godot_run.ps1 --path . -s res://art/units/fire/tools/gc_fire_shots.gd --quit-after 20000 -- --gfx=high --tag=after
##   ... -- --sheet            (no render: builds docs/art/lab/gc_fire/contact_sheet.jpg from the before / after PNGs)
## Shots -> docs/art/lab/gc_fire/shots/<tag>_<view>.png: army_z30 (3 rows of the roster + an enemy-coloured Hall row),
## squad_z30 (a 30-unit Hall army in formation, the play view), army_z40, close_<row> (zoom 10), portrait_hall (zoom 4).

const STAGE := preload("res://tools/art_lab/lab_stage.gd")
const OUT := "res://docs/art/lab/gc_fire/shots/"
const SHEET := "res://docs/art/lab/gc_fire/contact_sheet.jpg"
const ROWS: Array = [
	["hall", ["flame_guard", "ember_archer", "ash_hurler", "cinder_hand", "blaze_rider"]],
	["t2", ["scorchling/scorchling", "scorchbow/scorchbow", "pyre_adept/pyre_adept", "kilnwarden/kilnwarden",
		"cinderlock/cinderlock"]],
	["t3", ["cinder_arbalest/cinder_arbalest", "emberdart_harrier/emberdart_harrier", "pyrehoof_lancer/pyrehoof_lancer",
		"sunforge_cataphract/sunforge_cataphract", "ashveil_saboteur/ashveil_saboteur"]],
	["enemy", ["flame_guard", "ember_archer", "ash_hurler", "cinder_hand", "blaze_rider"]],
]
const ENEMY_COLOR := Color(0.25, 0.45, 0.90)
const SPACING := 2.6
const ROW_GAP := 3.4   # same framing as the before shots (2026-10-15)

var stage: Node
var center := Vector3(-18.0, 0.0, 36.0)   # the lab's meadow point
var tag := "after"
var _models: Array[Node3D] = []


func _initialize() -> void:
	var sheet := false
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--tag="):
			tag = a.substr(6)
		elif a == "--sheet":
			sheet = true
	if sheet:
		_contact_sheet()
		quit(0)
		return
	if DisplayServer.get_name() == "headless":
		print("GC FIRE SHOTS: windowed only")
		quit(2)
		return
	_run.call_deferred()


func _spawn(path: String, pos: Vector3, yaw: float) -> Node3D:
	var p := "res://art/units/fire/%s.tscn" % path
	if not ResourceLoader.exists(p):
		push_warning("gc_fire_shots: missing " + p)
		return null
	var m := (load(p) as PackedScene).instantiate() as Node3D
	m.position = pos
	m.rotation.y = yaw
	stage.world.add_child(m)
	_models.append(m)
	return m


func _clear() -> void:
	for m: Node3D in _models:
		if is_instance_valid(m):
			m.queue_free()
	_models.clear()


func _run() -> void:
	stage = STAGE.new()
	root.add_child(stage)
	stage.setup(&"warm")
	stage.vp.msaa_3d = Viewport.MSAA_4X
	await stage.warm()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var row_z: Array[float] = []
	for r: int in ROWS.size():
		var ids: Array = ROWS[r][1]
		var z := center.z + (r - (ROWS.size() - 1) * 0.5) * ROW_GAP
		row_z.append(z)
		for i: int in ids.size():
			var m := _spawn(ids[i], Vector3(center.x + (i - (ids.size() - 1) * 0.5) * SPACING, 0.0, z),
				deg_to_rad(-20.0 + 8.0 * i))
			if m and ROWS[r][0] == "enemy" and m.has_method("set_team_color"):
				m.call("set_team_color", ENEMY_COLOR)
	for i: int in 30:
		await process_frame
	stage.game_cam(center, 30.0)
	_save(await stage.grab(), "army_z30")
	stage.game_cam(center, 40.0)
	_save(await stage.grab(), "army_z40")
	for r: int in ROWS.size():
		stage.game_cam(Vector3(center.x, 0.8, row_z[r]), 10.0, 45.0)
		_save(await stage.grab(), "close_" + String(ROWS[r][0]))
	# Row details (zoom 6, lower pitch): each unit about 150 px tall, for judging shapes.
	for r: int in 3:
		stage.game_cam(Vector3(center.x, 0.8, row_z[r]), 6.5, 32.0)
		_save(await stage.grab(), "row_" + String(ROWS[r][0]))
	var hall: Array = ROWS[0][1]
	for r: int in 3:
		for i: int in 3:
			stage.game_cam(Vector3(center.x + (i * 2 - 2) * SPACING, 0.9, row_z[r]), 4.5, 25.0, 15.0)
			_save(await stage.grab(), "portrait_%s_%d" % [ROWS[r][0], i])
	# The play view: a Hall army in formation (10 guards, 8 archers, 4 hurlers, 4 riders, 6 workers behind).
	_clear()
	await process_frame
	var plan: Array = [["flame_guard", 10, 2.0], ["ember_archer", 8, -0.5], ["ash_hurler", 4, -2.8],
		["blaze_rider", 4, 4.6], ["cinder_hand", 6, -5.2]]
	for e: Array in plan:
		var n: int = e[1]
		for i: int in n:
			var col := i % 5
			var rw := i / 5
			_spawn(e[0], center + Vector3((col - 2) * 1.5 + rw * 0.7, 0.0, float(e[2]) - rw * 1.3), 0.15 * sin(i * 1.7))
	for i: int in 30:
		await process_frame
	stage.game_cam(center, 30.0)
	_save(await stage.grab(), "squad_z30")
	stage.game_cam(center, 18.0)
	_save(await stage.grab(), "squad_z18")
	print("GC FIRE SHOTS done: %s (%s), %d hall ids" % [OUT, tag, hall.size()])
	quit(0)


func _save(img: Image, view: String) -> void:
	var p := ProjectSettings.globalize_path(OUT + "%s_%s.png" % [tag, view])
	img.save_png(p)
	print("GC FIRE SHOT ", p)


## Before | after, one row per view, each tile 800 x 450: the commit-friendly JPG (the PNGs stay local).
func _contact_sheet() -> void:
	var views: Array[String] = ["squad_z30", "army_z30", "close_hall", "close_t3", "portrait_hall_0", "portrait_hall_1"]
	var tw := 800
	var th := 450
	var sheet := Image.create(tw * 2, th * views.size(), false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.1, 0.1, 0.1))
	var y := 0
	for v: String in views:
		for k: int in 2:
			var p := ProjectSettings.globalize_path(OUT + "%s_%s.png" % [["before", "after"][k], v])
			if not FileAccess.file_exists(p):
				continue
			var img := Image.load_from_file(p)
			img.convert(Image.FORMAT_RGB8)
			img.resize(tw, th, Image.INTERPOLATE_LANCZOS)
			sheet.blit_rect(img, Rect2i(0, 0, tw, th), Vector2i(k * tw, y))
		y += th
	sheet.save_jpg(ProjectSettings.globalize_path(SHEET), 0.85)
	print("GC FIRE SHEET ", ProjectSettings.globalize_path(SHEET))
