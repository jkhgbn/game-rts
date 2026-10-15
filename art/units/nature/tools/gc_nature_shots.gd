extends SceneTree
## G-C Nature units (docs/art/gc_nature_units.md): army shots of the whole Nature roster on the Art Lab stage (game
## lighting rig, meadow ground, game camera pitch 55 / fov 50). WINDOWED only (headless renders nothing):
##   tools\godot_run.ps1 --path . -s res://art/units/nature/tools/gc_nature_shots.gd --quit-after 20000 '--' --gfx=high --tag=after
##   ... '--' --gfx=high --perf --tag=after   (240 Nature soldiers in the zoom-30 view, mean GPU / CPU ms; prints GC NATURE PERF)
##   ... '--' --gfx=high --perf --legacy --tag=legacy   (the same with the Nature materials back on the kit's unit_painted)
##   ... '--' --gfx=high --ysolde --tag=after [--legacy]   (Ysolde at zoom 10 + a portrait, the hero check)
## Shots -> docs/art/lab/gc_nature/shots/<tag>_<view>.png: army_z30 / army_z40 (4 rows: Hall + worker in the Nature
## green, the same in the Fire red, tier 2 units, riders / tier 3), army_z30_crop2x, close_<row> (zoom 10) and
## portrait_<row> (zoom 4).

const STAGE := preload("res://tools/art_lab/lab_stage.gd")
const OUT := "res://docs/art/lab/gc_nature/shots/"
const HALL: Array[String] = ["sprigling", "thornling", "burr_slinger", "bloomtender", "bramblehorn"]
const ROWS: Array = [
	["hall", HALL, Color(0.35, 0.70, 0.25)],
	["hall_red", HALL, Color(0.85, 0.30, 0.12)],
	["tier2", ["sapling", "vinelasher/vinelasher", "wildwood_archer/wildwood_archer", "bramblesage/bramblesage",
		"thistle_darter/thistle_darter"], Color(0.35, 0.70, 0.25)],
	["tier3", ["greenheart_oathkeeper/greenheart_oathkeeper", "spirit_wolf/spirit_wolf", "stagrunner/stagrunner",
		"glade_outrider/glade_outrider", "thornback_charger/thornback_charger", "bramble_harrier/bramble_harrier"],
		Color(0.35, 0.70, 0.25)],
]
const SPACING := 2.6
const ROW_GAP := 3.4

var stage: Node
var center := Vector3(-18.0, 0.0, 36.0)   # the lab's meadow point
var tag := "after"
var perf := false
var legacy := false
var ysolde := false
var _held: Array[Material] = []   # keeps the swapped materials in the resource cache


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--tag="):
			tag = a.substr(6)
		elif a == "--perf":
			perf = true
		elif a == "--legacy":
			legacy = true
		elif a == "--ysolde":
			ysolde = true
	if DisplayServer.get_name() == "headless":
		print("GC NATURE SHOTS: windowed only")
		quit(2)
		return
	if legacy:
		_swap_legacy()
	_run.call_deferred()


## --legacy: every Nature material on nature_living.gdshader goes back to the kit's unit_painted.gdshader at runtime
## (the pre-G-C shading on the same meshes: a fair GPU A / B, and the material half of the before / after).
func _swap_legacy() -> void:
	var painted := load("res://art/units/kit/unit_painted.gdshader") as Shader
	var n := 0
	for f: String in _tres("res://art/units/nature/"):
		var m := load(f) as ShaderMaterial
		if m and m.shader and m.shader.resource_path.ends_with("nature_living.gdshader"):
			m.shader = painted
			_held.append(m)
			n += 1
	print("GC NATURE legacy: %d materials back on unit_painted" % n)


func _tres(dir: String) -> PackedStringArray:
	var out := PackedStringArray()
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f: String in d.get_files():
		if f.get_extension() == "tres":
			out.append(dir.path_join(f))
	for sub: String in d.get_directories():
		out.append_array(_tres(dir.path_join(sub)))
	return out


func _spawn(path: String, pos: Vector3, yaw: float, team: Color) -> Node3D:
	var p := "res://art/units/nature/%s.tscn" % path
	if not ResourceLoader.exists(p):
		push_warning("gc_nature_shots: missing " + p)
		return null
	var m := (load(p) as PackedScene).instantiate() as Node3D
	m.position = pos
	m.rotation.y = yaw
	stage.world.add_child(m)
	if m.has_method(&"set_team_color"):
		m.call(&"set_team_color", team)
	return m


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
	if ysolde:
		await _ysolde()
		quit(0)
		return
	var row_z: Array[float] = []
	for r: int in ROWS.size():
		var ids: Array = ROWS[r][1]
		var z := center.z + (r - (ROWS.size() - 1) * 0.5) * ROW_GAP
		row_z.append(z)
		for i: int in ids.size():
			_spawn(ids[i], Vector3(center.x + (i - (ids.size() - 1) * 0.5) * SPACING, 0.0, z), deg_to_rad(-20.0 + 8.0 * i),
				ROWS[r][2])
	for i: int in 40:
		await process_frame
	stage.game_cam(center, 30.0)
	var img: Image = await stage.grab()
	_save(img, "army_z30")
	var crop := img.get_region(Rect2i(400, 225, 800, 450))
	crop.resize(1600, 900, Image.INTERPOLATE_LANCZOS)
	_save(crop, "army_z30_crop2x")
	stage.game_cam(center, 40.0)
	_save(await stage.grab(), "army_z40")
	for r: int in ROWS.size():
		stage.game_cam(Vector3(center.x, 0.8, row_z[r]), 10.0, 40.0)
		_save(await stage.grab(), "close_" + String(ROWS[r][0]))
	for r: int in [0, 2]:
		var ids: Array = ROWS[r][1]
		stage.game_cam(Vector3(center.x - (ids.size() - 1) * 0.5 * SPACING + SPACING, 0.9, row_z[r]), 4.5, 30.0, 20.0)
		_save(await stage.grab(), "portrait_" + String(ROWS[r][0]))
	print("GC NATURE SHOTS done: %s (%s)" % [OUT, tag])
	quit(0)


## --ysolde: the Nature hero (her belt, satchel, vine and head leaf ring use nature_bark / nature_leaf /
## nature_leaf_dark) next to a Thornling and a Sprigling: ysolde_z10 (zoom 10) and ysolde_portrait (3.5 m, front).
func _ysolde() -> void:
	var y := load("res://art/units/wizards/ysolde.tscn") as PackedScene
	var m := y.instantiate() as Node3D
	m.position = center
	m.rotation.y = deg_to_rad(-15.0)
	stage.world.add_child(m)
	_spawn("thornling", center + Vector3(-1.6, 0, 0.4), deg_to_rad(10.0), ROWS[0][2])
	_spawn("sprigling", center + Vector3(1.5, 0, 0.5), deg_to_rad(-25.0), ROWS[0][2])
	for i: int in 40:
		await process_frame
	stage.game_cam(center + Vector3(0, 0.8, 0), 10.0, 40.0)
	_save(await stage.grab(), "ysolde_z10")
	stage.game_cam(center + Vector3(0, 1.1, 0), 3.5, 18.0, 0.0)
	_save(await stage.grab(), "ysolde_portrait")


func _perf() -> void:
	# 240 Nature soldiers (Hall roster + tier 2, 20 x 12 grid) filling the zoom-30 view.
	var ids: Array = []
	ids.append_array(ROWS[0][1])
	ids.append_array(ROWS[2][1])
	var k := 0
	for gx: int in 20:
		for gz: int in 12:
			_spawn(ids[k % ids.size()], center + Vector3((gx - 9.5) * 1.5, 0.0, (gz - 5.5) * 1.5), 0.0, ROWS[0][2])
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
	print("GC NATURE PERF %s: %d units, gpu %.3f ms, cpu %.3f ms (mean of %d frames, 1600x900 MSAA 4x)" % [tag, k, gpu / n,
		cpu / n, n])


func _save(img: Image, view: String) -> void:
	var p := ProjectSettings.globalize_path(OUT + "%s_%s.png" % [tag, view])
	img.save_png(p)
	print("GC NATURE SHOT ", p)
