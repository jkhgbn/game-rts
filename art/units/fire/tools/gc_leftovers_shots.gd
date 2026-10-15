extends SceneTree
## G-C leftovers (docs/art/gc_leftovers.md): before / after shots of the units the first G-C pass skipped (cavalry
## riders of the 4 kingdoms, the Nature mounts, the Ice Rimecarver / Rimeling / Frost Mortar / Frostrune Rifleman, the
## Shadow T2 units, the Mender) on the Art Lab stage (game lighting rig, skirmish ground, game camera). WINDOWED only:
##   tools\godot_run.ps1 --path . -s res://art/units/fire/tools/gc_leftovers_shots.gd --quit-after 30000 '--' --gfx=high --tag=after
##   ... '--' --sheet          (no render: docs/art/lab/gc_leftovers/contact_sheet.jpg from the before / after PNGs)
##   ... '--' --count          (headless ok: body vertices / draw meshes per scene after _ready, no shots)
## Shots -> docs/art/lab/gc_leftovers/shots/<tag>_<view>.png: all_z30 (every row), close_<row> (zoom 10),
## portrait_<id> (zoom 4.5).

const STAGE := preload("res://tools/art_lab/lab_stage.gd")
const OUT := "res://docs/art/lab/gc_leftovers/shots/"
const SHEET := "res://docs/art/lab/gc_leftovers/contact_sheet.jpg"
const ROWS: Array = [
	["fire_cav", ["res://art/units/fire/blaze_rider.tscn", "res://art/units/fire/emberdart_harrier/emberdart_harrier.tscn",
		"res://art/units/fire/pyrehoof_lancer/pyrehoof_lancer.tscn",
		"res://art/units/fire/sunforge_cataphract/sunforge_cataphract.tscn"]],
	["shadow_cav", ["res://art/units/shadow/barrow_knight/barrow_knight.tscn",
		"res://art/units/shadow/duskbolt_harrier/duskbolt_harrier.tscn",
		"res://art/units/shadow/veilborn_dreadrider/veilborn_dreadrider.tscn",
		"res://art/units/shadow/gloam_rider/gloam_rider.tscn"]],
	["ice_cav", ["res://art/units/ice/rimehorn_rider/rimehorn_rider.tscn", "res://art/units/ice/rime_harrier/rime_harrier.tscn",
		"res://art/units/ice/snowdrift_rider/snowdrift_rider.tscn",
		"res://art/units/ice/frostcrown_juggernaut/frostcrown_juggernaut.tscn"]],
	["mixed", ["res://art/units/nature/thornback_charger/thornback_charger.tscn",
		"res://art/units/nature/bramble_harrier/bramble_harrier.tscn", "res://art/units/ice/rimecarver/rimecarver.tscn",
		"res://art/units/ice/rimeling/rimeling.tscn", "res://art/units/ice/frost_mortar/frost_mortar.tscn",
		"res://art/units/ice/frostrune_rifleman/frostrune_rifleman.tscn"]],
	["shadow_t2", ["res://art/units/shadow/barrow_ghoul/barrow_ghoul.tscn",
		"res://art/units/shadow/hollow_oathsworn/hollow_oathsworn.tscn", "res://art/units/shadow/bleakbow/bleakbow.tscn",
		"res://art/units/shadow/nightblood_reaver/nightblood_reaver.tscn", "res://art/units/shadow/hexweaver/hexweaver.tscn",
		"res://art/units/shadow/gloom_deacon/gloom_deacon.tscn", "res://art/units/champions/mender/mender.tscn"]],
]
## Portraits: [row, index, name].
const PORTRAITS: Array = [[0, 0, "blaze_rider"], [1, 0, "barrow_knight"], [2, 1, "rime_harrier"], [3, 0, "thornback"],
	[3, 4, "frost_mortar"], [4, 6, "mender"], [3, 2, "rimecarver"], [3, 3, "rimeling"], [3, 5, "frostrune"],
	[4, 0, "barrow_ghoul"], [4, 3, "reaver"], [3, 1, "bramble"]]
const SPACING := 3.6
const ROW_GAP := 4.4

var stage: Node
var center := Vector3(-18.0, 0.0, 36.0)   # the lab's meadow point
var tag := "after"
var _models: Array[Node3D] = []
var _pos: Dictionary = {}


func _initialize() -> void:
	var sheet := false
	var count := false
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--tag="):
			tag = a.substr(6)
		elif a == "--sheet":
			sheet = true
		elif a == "--count":
			count = true
	if sheet:
		_contact_sheet()
		quit(0)
		return
	if count:
		_count_all.call_deferred()
		return
	if DisplayServer.get_name() == "headless":
		print("GC LEFTOVERS SHOTS: windowed only")
		quit(2)
		return
	_run.call_deferred()


func _spawn(p: String, pos: Vector3, yaw: float) -> Node3D:
	if not ResourceLoader.exists(p):
		push_warning("gc_leftovers_shots: missing " + p)
		return null
	var m := (load(p) as PackedScene).instantiate() as Node3D
	m.position = pos
	m.rotation.y = yaw
	stage.world.add_child(m)
	_models.append(m)
	return m


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
			var p := Vector3(center.x + (i - (ids.size() - 1) * 0.5) * SPACING, 0.0, z)
			_pos[Vector2i(r, i)] = p
			_spawn(ids[i], p, deg_to_rad(-60.0 + 9.0 * i))
	for i: int in 60:
		await process_frame
	stage.game_cam(center, 30.0)
	_save(await stage.grab(), "all_z30")
	for r: int in ROWS.size():
		for g: Array in _groups(r):
			var c := Vector3.ZERO
			for i: int in g[1]:
				c += _pos[Vector2i(r, i)]
			c /= float((g[1] as Array).size())
			stage.game_cam(c + Vector3(0, 1.0, 0), 9.0, 45.0)
			_save(await stage.grab(), "close_" + String(ROWS[r][0]) + String(g[0]))
	for pr: Array in PORTRAITS:
		var p: Vector3 = _pos.get(Vector2i(int(pr[0]), int(pr[1])), center)
		stage.game_cam(p + Vector3(0, 1.3, 0), 4.5, 25.0, 15.0)
		_save(await stage.grab(), "portrait_" + String(pr[2]))
	print("GC LEFTOVERS SHOTS done: %s (%s)" % [OUT, tag])
	quit(0)


## Close-shot groups of a row: one group of up to 4 units, else two halves ("_l" / "_r").
func _groups(r: int) -> Array:
	var n: int = (ROWS[r][1] as Array).size()
	if n <= 4:
		return [["", range(n)]]
	var h: int = (n + 1) >> 1
	return [["_l", range(h)], ["_r", range(h, n)]]


func _save(img: Image, view: String) -> void:
	var p := ProjectSettings.globalize_path(OUT + "%s_%s.png" % [tag, view])
	img.save_png(p)
	print("GC LEFTOVERS SHOT ", p)


## Body vertices (face apart) / draw meshes per scene after _ready, the riders split rider / mount.
func _count_all() -> void:
	var w := Node3D.new()
	root.add_child(w)
	for row: Array in ROWS:
		for p: String in row[1]:
			var n := (load(p) as PackedScene).instantiate() as Node3D
			w.add_child(n)
			await process_frame
			await process_frame
			var c: Array[int] = [0, 0, 0]
			_count(n, c)
			var extra := ""
			for part: String in ["Rider", "Boar", "Steed", "Mount"]:
				var sub := n.get_node_or_null(part)
				if sub:
					var cs: Array[int] = [0, 0, 0]
					_count(sub, cs)
					extra += " | %s %d verts %d draws" % [part, cs[1], cs[0]]
			print("GC LEFTOVERS COUNT %s: body %d face %d draws %d%s" % [p.get_file().get_basename(), c[1], c[2], c[0], extra])
			n.queue_free()
			await process_frame
	quit(0)


func _count(n: Node, c: Array[int]) -> void:
	if n is Node3D and not (n as Node3D).visible:
		return
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		var mi := n as MeshInstance3D
		var v := 0
		for s: int in mi.mesh.get_surface_count():
			v += (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		if String(n.name).containsn("face"):
			c[2] += v
		else:
			c[0] += 1
			c[1] += v
	for ch: Node in n.get_children():
		_count(ch, c)


## Before | after, one row per view, each tile 640 x 360: the commit-friendly JPG (the PNGs stay local).
func _contact_sheet() -> void:
	var views: Array[String] = ["all_z30"]
	for r: int in ROWS.size():
		for g: Array in _groups(r):
			views.append("close_" + String(ROWS[r][0]) + String(g[0]))
	for pr: Array in PORTRAITS:
		views.append("portrait_" + String(pr[2]))
	var tw := 640
	var th := 360
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
	print("GC LEFTOVERS SHEET ", ProjectSettings.globalize_path(SHEET))
