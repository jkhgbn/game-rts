extends SceneTree
## G-C champions (docs/art/gc_champions.md): before / after shots of the four hired champions (both variants, every
## class weapon) on the Art Lab stage (game lighting rig, skirmish ground, game camera pitch 55 / fov 50).
## WINDOWED only (headless renders nothing):
##   tools\godot_run.ps1 --path . -s res://art/units/champions/tools/gc_champions_shots.gd --quit-after 30000 '--' --gfx=high --tag=after
##   ... '--' --sheet            (no render: builds docs/art/lab/gc_champions/contact_sheet.jpg from the before / after PNGs)
## Shots -> docs/art/lab/gc_champions/shots/<tag>_<view>.png: line_z30 (the 4 x A / B + a class row, play view),
## line_z40, close_<row> (zoom 10), portrait_<id>_<v> (zoom 2.6 on the face: the HUD inspect framing), classes_<id>
## (zoom 6, the 5 weapon classes side by side).

const STAGE := preload("res://tools/art_lab/lab_stage.gd")
const OUT := "res://docs/art/lab/gc_champions/shots/"
const SHEET := "res://docs/art/lab/gc_champions/contact_sheet.jpg"
const IDS: Array[String] = ["oathwall", "wayfinder", "coin_cutter", "mender"]
const CLASSES: Array[StringName] = [&"", &"spear", &"sword_shield", &"two_hand", &"wizard"]
const ENEMY_COLOR := Color(0.25, 0.45, 0.90)
const TEAM_COLORS: Array[Color] = [Color(0.85, 0.30, 0.12), Color(0.42, 0.22, 0.60), Color(0.45, 0.75, 0.95),
	Color(0.35, 0.70, 0.25)]
const SPACING := 2.4
const ROW_GAP := 3.4

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
		print("GC CHAMPIONS SHOTS: windowed only")
		quit(2)
		return
	_run.call_deferred()


func _spawn(id: String, pos: Vector3, yaw: float, v: int, col: Color, cls: StringName) -> Node3D:
	var p := "res://art/units/champions/%s/%s.tscn" % [id, id]
	var m := (load(p) as PackedScene).instantiate() as Node3D
	m.position = pos
	m.rotation.y = yaw
	if m.has_method("set_variant"):
		m.call("set_variant", v)
	stage.world.add_child(m)
	if m.has_method("set_team_color"):
		m.call("set_team_color", col)
	if cls != &"" and m.has_method("set_weapon_class"):
		m.call("set_weapon_class", cls, false)
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
	# Row 0: variant A in their kingdom-ish colours; row 1: variant B, enemy blue; row 2: one class each.
	var row_cls: Array[StringName] = [&"spear", &"sword_shield", &"two_hand", &"wizard"]
	var row_z: Array[float] = []
	for r: int in 3:
		var z := center.z + (r - 1) * ROW_GAP
		row_z.append(z)
		for i: int in IDS.size():
			var x := center.x + (i - 1.5) * SPACING
			var col: Color = TEAM_COLORS[i] if r != 1 else ENEMY_COLOR
			_spawn(IDS[i], Vector3(x, 0.0, z), deg_to_rad(-15.0 + 10.0 * i), 1 if r == 1 else 0, col,
				row_cls[i] if r == 2 else &"")
	for i: int in 40:
		await process_frame
	stage.game_cam(center, 30.0)
	_save(await stage.grab(), "line_z30")
	stage.game_cam(center, 40.0)
	_save(await stage.grab(), "line_z40")
	for r: int in 3:
		stage.game_cam(Vector3(center.x, 0.9, row_z[r]), 10.0, 45.0)
		_save(await stage.grab(), "close_row%d" % r)
	# Portraits (HUD inspect framing: head and shoulders, low pitch, a little from the side).
	for r: int in 2:
		for i: int in IDS.size():
			var x := center.x + (i - 1.5) * SPACING
			stage.game_cam(Vector3(x, 1.45, row_z[r]), 2.4, 12.0, 18.0)
			_save(await stage.grab(), "portrait_%s_%d" % [IDS[i], r])
	# Full body at zoom 4.5 (shapes).
	for i: int in IDS.size():
		var x := center.x + (i - 1.5) * SPACING
		stage.game_cam(Vector3(x, 1.0, row_z[0]), 4.6, 22.0, 20.0)
		_save(await stage.grab(), "body_%s" % IDS[i])
	# Class rows: one champion, the 5 classes side by side (zoom 6.5).
	for id: String in IDS:
		_clear()
		await process_frame
		for c: int in CLASSES.size():
			_spawn(id, center + Vector3((c - 2) * 1.7, 0.0, 0.0), deg_to_rad(-25.0), 0, TEAM_COLORS[0], CLASSES[c])
		for i: int in 30:
			await process_frame
		stage.game_cam(center + Vector3(0, 1.0, 0), 6.8, 24.0, 10.0)
		_save(await stage.grab(), "classes_%s" % id)
	# The champion-folder NPCs (not hired, untouched by G-C; watched for palette / shared-material changes).
	_clear()
	await process_frame
	var npcs: Array[String] = ["wildcaller", "mage_archer"]
	for i: int in npcs.size():
		for v: int in 2:
			_spawn(npcs[i], center + Vector3((i * 2 + v - 1.5) * 2.2, 0.0, 0.0), deg_to_rad(-15.0), v, TEAM_COLORS[3 - i * 2], &"")
	for i: int in 30:
		await process_frame
	stage.game_cam(center + Vector3(0, 1.0, 0), 9.0, 30.0, 0.0)
	_save(await stage.grab(), "npcs")
	print("GC CHAMPIONS SHOTS done: %s (%s)" % [OUT, tag])
	quit(0)


func _save(img: Image, view: String) -> void:
	var p := ProjectSettings.globalize_path(OUT + "%s_%s.png" % [tag, view])
	img.save_png(p)
	print("GC CHAMPIONS SHOT ", p)


## Before | after, one row per view, each tile 800 x 450: the commit-friendly JPG (the PNGs stay local).
func _contact_sheet() -> void:
	var views: Array[String] = ["line_z30", "close_row0", "close_row2", "portrait_oathwall_0", "portrait_wayfinder_0",
		"portrait_coin_cutter_0", "portrait_mender_0", "classes_oathwall", "classes_wayfinder"]
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
	print("GC CHAMPIONS SHEET ", ProjectSettings.globalize_path(SHEET))
