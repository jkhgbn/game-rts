extends SceneTree
## G-C mounts + titans (docs/art/gc_mounts_titans.md): before / after shots on the Art Lab stage (game lighting rig,
## skirmish ground, game camera). WINDOWED only (headless renders nothing):
##   tools\godot_run.ps1 --path . -s res://art/units/mounts/tools/gc_mounts_shots.gd --quit-after 20000 -- --gfx=high --tag=after
##   ... -- --sheet            (no render: builds docs/art/lab/gc_mounts/contact_sheet.jpg from the before / after PNGs)
## Shots -> docs/art/lab/gc_mounts/shots/<tag>_<view>.png: mounts_z30 (the 5 mounts, the 4 cavalry riders, an
## enemy-coloured mount row, a galloping row), close_mounts / close_cavalry / close_gallop (zoom 10), portrait_<mount>
## (zoom 4.5), titans_z30 / titans_z40 (the 5 titans side by side), close_<titan> (zoom 10).

const STAGE := preload("res://tools/art_lab/lab_stage.gd")
const OUT := "res://docs/art/lab/gc_mounts/shots/"
const SHEET := "res://docs/art/lab/gc_mounts/contact_sheet.jpg"
const MOUNTS: Array[String] = ["ember_boar", "dusk_steed", "grove_stag", "rimehorn", "roan_courser"]
const CAVALRY: Array[String] = ["res://art/units/fire/blaze_rider.tscn", "res://art/units/shadow/gloam_rider/gloam_rider.tscn",
	"res://art/units/ice/rimehorn_rider/rimehorn_rider.tscn", "res://art/units/nature/glade_outrider/glade_outrider.tscn"]
const TITANS: Array[String] = ["cinder_dragon", "frost_dragon", "elder_treant", "nightmare_knight", "war_mammoth"]
const ENEMY_COLOR := Color(0.25, 0.45, 0.90)
const SPACING := 3.4
const ROW_GAP := 4.2
const TITAN_SPACING := 7.0

var stage: Node
var center := Vector3(-18.0, 0.0, 36.0)   # the lab's meadow point
var tag := "after"
var only := ""   # --only=mounts | titans
var _models: Array[Node3D] = []


func _initialize() -> void:
	var sheet := false
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--tag="):
			tag = a.substr(6)
		elif a.begins_with("--only="):
			only = a.substr(7)
		elif a == "--sheet":
			sheet = true
	if sheet:
		_contact_sheet()
		quit(0)
		return
	if DisplayServer.get_name() == "headless":
		print("GC MOUNTS SHOTS: windowed only")
		quit(2)
		return
	_run.call_deferred()


func _spawn(p: String, pos: Vector3, yaw: float) -> Node3D:
	if not ResourceLoader.exists(p):
		push_warning("gc_mounts_shots: missing " + p)
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


func _mount_path(id: String) -> String:
	return "res://art/units/mounts/%s/%s.tscn" % [id, id]


func _titan_path(id: String) -> String:
	return "res://art/units/titans/%s/%s.tscn" % [id, id]


func _run() -> void:
	stage = STAGE.new()
	root.add_child(stage)
	stage.setup(&"warm")
	stage.vp.msaa_3d = Viewport.MSAA_4X
	await stage.warm()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	if only != "titans":
		await _mounts()
	if only != "mounts":
		await _titans()
	print("GC MOUNTS SHOTS done: %s (%s)" % [OUT, tag])
	quit(0)


func _mounts() -> void:
	# ---- mounts: plain row, cavalry row, enemy-coloured row, galloping row
	var rows: Array = [["mounts", MOUNTS.map(_mount_path)], ["cavalry", CAVALRY], ["enemy", MOUNTS.map(_mount_path)],
		["gallop", MOUNTS.map(_mount_path)]]
	var row_z: Array[float] = []
	for r: int in rows.size():
		var ids: Array = rows[r][1]
		var z := center.z + (r - (rows.size() - 1) * 0.5) * ROW_GAP
		row_z.append(z)
		for i: int in ids.size():
			var yaw := deg_to_rad(-70.0 + 10.0 * i) if rows[r][0] != "gallop" else deg_to_rad(90.0)
			var m := _spawn(ids[i], Vector3(center.x + (i - (ids.size() - 1) * 0.5) * SPACING, 0.0, z), yaw)
			if m == null:
				continue
			if rows[r][0] == "enemy" and m.has_method("set_team_color"):
				m.call("set_team_color", ENEMY_COLOR)
			if rows[r][0] == "gallop" and m.has_method("set_moving"):
				m.call("set_moving", 6.0)
	for i: int in 40:
		await process_frame
	stage.game_cam(center, 30.0)
	_save(await stage.grab(), "mounts_z30")
	for r: int in rows.size():
		stage.game_cam(Vector3(center.x, 0.9, row_z[r]), 10.0, 45.0)
		_save(await stage.grab(), "close_" + String(rows[r][0]))
	for i: int in MOUNTS.size():
		stage.game_cam(Vector3(center.x + (i - 2) * SPACING, 1.1, row_z[0]), 4.5, 25.0, 15.0)
		_save(await stage.grab(), "portrait_" + MOUNTS[i])
	_clear()
	await process_frame


func _titans() -> void:
	# ---- titans side by side
	for i: int in TITANS.size():
		var m := _spawn(_titan_path(TITANS[i]), Vector3(center.x + (i - 2) * TITAN_SPACING, 0.0, center.z),
			deg_to_rad(-60.0 + 8.0 * i))
		if m == null:
			continue
	for i: int in 40:
		await process_frame
	stage.game_cam(center, 30.0)
	_save(await stage.grab(), "titans_z30")
	stage.game_cam(center, 40.0)
	_save(await stage.grab(), "titans_z40")
	for i: int in TITANS.size():
		stage.game_cam(Vector3(center.x + (i - 2) * TITAN_SPACING, 2.0, center.z), 10.0, 45.0)
		_save(await stage.grab(), "close_" + TITANS[i])
	_clear()
	await process_frame


func _save(img: Image, view: String) -> void:
	var p := ProjectSettings.globalize_path(OUT + "%s_%s.png" % [tag, view])
	img.save_png(p)
	print("GC MOUNTS SHOT ", p)


## Before | after, one row per view, each tile 800 x 450: the commit-friendly JPG (the PNGs stay local).
func _contact_sheet() -> void:
	var views: Array[String] = ["mounts_z30", "close_mounts", "close_cavalry", "close_gallop", "portrait_ember_boar",
		"portrait_dusk_steed", "titans_z30", "close_cinder_dragon", "close_elder_treant", "close_nightmare_knight",
		"close_war_mammoth"]
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
	print("GC MOUNTS SHEET ", ProjectSettings.globalize_path(SHEET))
