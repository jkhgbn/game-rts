extends SceneTree
## Task G-B Fire: one windowed shot of the Fire Keep row tier 1 / tier 2 / tier 3 / upgrading (+ an Ember Hall,
## a Hearth, an Ember Spire and the Hall at 20 % HP) on a plain ground, for docs/art/gb_fire_buildings.md.
##   tools\godot_run.ps1 --path . -s res://art/buildings/fire/tools/gb_fire_keep_tiers_shot.gd --resolution 1920x1080
##       --quit-after 3000 '--' --gfx=high [tag=after] [legacy=1] [zoom=30]

const OUT_DIR := "res://docs/art/lab/gb_fire/shots"

var _tag := "after"
var _zoom := 58.0
var _fx := 0.0
var _name := "keep_row"


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		var k := arg.get_slice("=", 0)
		var v := arg.substr(k.length() + 1)
		match k:
			"tag": _tag = v
			"zoom": _zoom = float(v)
			"fx": _fx = float(v)
			"name": _name = v
			"legacy": FireBuildingLook.legacy = v != "0"
	var root3 := Node3D.new()
	root.add_child(root3)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.42, 0.5, 0.58)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.58, 0.66)
	e.ambient_light_energy = 0.55
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.glow_enabled = true
	e.glow_hdr_threshold = 1.2
	env.environment = e
	root3.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.light_energy = 1.25
	sun.light_color = Color(1.0, 0.94, 0.84)
	sun.shadow_enabled = true
	root3.add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(120, 120)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.30, 0.36, 0.20)
	gm.roughness = 1.0
	ground.material_override = gm
	root3.add_child(ground)
	var keep_scene: PackedScene = load("res://art/buildings/fire_keep.tscn")
	var keeps: Array[Node3D] = []
	for i: int in 4:
		var k: Node3D = keep_scene.instantiate()
		k.position = Vector3(19.5 - 13.0 * i, 0, 6.0)
		root3.add_child(k)
		keeps.append(k)
	var small := ["res://art/buildings/fire_hall.tscn", "res://art/buildings/hearth.tscn",
		"res://art/buildings/fire_tower.tscn", "res://art/buildings/fire_hall.tscn"]
	var others: Array[Node3D] = []
	for i: int in small.size():
		var b: Node3D = (load(small[i]) as PackedScene).instantiate()
		b.position = Vector3(19.5 - 13.0 * i, 0, -9.0)
		root3.add_child(b)
		others.append(b)
	var cam := Camera3D.new()
	cam.fov = 40.0
	root3.add_child(cam)
	var focus := Vector3(_fx, 5.0 if _zoom > 40.0 else 9.0, 1.0)
	var pitch := deg_to_rad(55.0)
	cam.look_at_from_position(focus + Vector3(0, sin(pitch) * _zoom, -cos(pitch) * _zoom), focus, Vector3.UP)
	cam.current = true
	_run(keeps, others)


func _run(keeps: Array[Node3D], others: Array[Node3D]) -> void:
	for i in 5:
		await process_frame
	keeps[1].call(&"set_tier", 2)
	keeps[2].call(&"set_tier", 3)
	keeps[3].call(&"set_tier", 2)
	keeps[3].call(&"set_upgrading", true)
	others[3].call(&"set_health_ratio", 0.2)
	for i in 90:
		await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var path := "%s/%s_q%d_%s.png" % [OUT_DIR, _tag, GameSettings.effective_graphics_quality(), _name]
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print("saved %s" % path)
	quit()
