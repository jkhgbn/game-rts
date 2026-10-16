extends SceneTree
## Hollow King shots (campaign review 2026-10-16, e8m3). Windowed:
##   tools\godot_run.ps1 --path . -s res://art/units/titans/hollow_king/tools/hollow_king_shots.gd --resolution 1600x900
##       --fixed-fps 60 --quit-after 3000 -- --gfx=high
## Writes docs/art/screens/cr_hollow_king/: rts.png (game camera, King x 2.2 next to the old Colossus x 2.2 and an Ice
## soldier for scale), front.png (close 3/4), back.png (mantle + chains), top.png (top-down silhouettes, King left),
## contact_sheet.png (the 4 in a 2 x 2 grid). Then quits.

const OUT := "res://docs/art/screens/cr_hollow_king/"
const KING := "res://art/units/titans/hollow_king/hollow_king.tscn"
const COLOSSUS := "res://art/units/ice/rime_colossus.tscn"
const SOLDIER := "res://art/units/ice/rimeshield.tscn"
const SCALE := 2.2

var _cam: Camera3D
var _king: Node3D
var _shots: Array[Image] = []


func _initialize() -> void:
	var w := Node3D.new()
	root.add_child(w)
	var env := WorldEnvironment.new()
	env.environment = load("res://art/environment/world_env.tres")
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.86, 0.70)
	sun.light_energy = 1.2
	sun.rotation_degrees = Vector3(-48, 30, 0)
	sun.shadow_enabled = true
	sun.shadow_normal_bias = 2.0
	w.add_child(sun)
	var g := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(300, 300)
	g.mesh = pm
	g.material_override = load("res://art/environment/ground_material.tres")
	w.add_child(g)
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	w.add_child(_cam)
	_cam.make_current()
	_king = _spawn(w, KING, Vector3(0, 0, 0), 20.0, SCALE)
	_spawn(w, COLOSSUS, Vector3(9, 0, 0), 20.0, SCALE)
	_spawn(w, SOLDIER, Vector3(-4.5, 0, 2.5), 20.0, 1.0)
	_run()


func _spawn(w: Node3D, path: String, at: Vector3, yaw: float, sc: float) -> Node3D:
	var holder := Node3D.new()
	holder.position = at
	holder.rotation_degrees.y = yaw
	w.add_child(holder)
	var m := (load(path) as PackedScene).instantiate() as Node3D
	if &"fidget_every" in m:
		m.set(&"fidget_every", 0.0)
	m.scale = Vector3.ONE * sc
	holder.add_child(m)
	return m


func _look(focus: Vector3, dist: float, pitch_deg: float, yaw_deg: float, fov: float = 50.0) -> void:
	var p := deg_to_rad(pitch_deg)
	var y := deg_to_rad(yaw_deg)
	_cam.fov = fov
	_cam.position = focus + Vector3(sin(y) * cos(p), sin(p), cos(y) * cos(p)) * dist
	_cam.rotation = Vector3(-p, y, 0)


func _run() -> void:
	for i: int in 30:
		await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_look(Vector3(3.5, 2.0, 0), 34.0, 55.0, 0.0)
	await _shot("rts")
	_look(Vector3(0, 3.4, 0), 11.0, 12.0, 45.0)
	await _shot("front")
	_look(Vector3(0, 3.2, 0), 12.0, 22.0, 200.0)
	await _shot("back")
	_look(Vector3(4.5, 0, 0), 22.0, 89.0, 0.0, 40.0)
	await _shot("top")
	var sheet := Image.create(1600, 900, false, Image.FORMAT_RGB8)
	for i: int in _shots.size():
		var im := _shots[i].duplicate() as Image
		im.convert(Image.FORMAT_RGB8)
		im.resize(800, 450, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(im, Rect2i(0, 0, 800, 450), Vector2i((i % 2) * 800, (i >> 1) * 450))
	sheet.save_png(ProjectSettings.globalize_path(OUT + "contact_sheet.png"))
	print("HK SHOTS done -> ", OUT)
	quit()


func _shot(name: String) -> void:
	for i: int in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var im := root.get_viewport().get_texture().get_image()
	im.save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	_shots.append(im)
