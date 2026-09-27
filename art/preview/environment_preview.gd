extends Node3D
## Preview of the environment art (task 5.V3) from the RTS camera (pitch 55, fov 50).
## Trees and rocks are drawn with MultiMeshInstance3D, like the map should do it.
## Windowed run `-- --shots` saves docs/art/screens/env_z15_crown.png, env_z15_props.png, env_z40.png.
## Mouse wheel = zoom.

const TREES: Array[String] = ["tree_pine", "tree_broadleaf", "tree_fir"]
const ROCKS: Array[String] = ["rock_boulder", "rock_slab", "rock_shards"]
const DIR := "res://art/environment/"

@export var zoom: float = 40.0
@export var pitch_degrees: float = 55.0
@export var focus: Vector3 = Vector3(0, 0, 0)

var _rng := RandomNumberGenerator.new()
var _cam: Camera3D


func _ready() -> void:
	_cam = $Camera3D
	_rng.seed = 7
	_build()
	_apply()
	if "--shots" in OS.get_cmdline_user_args():
		_shots()


func _apply() -> void:
	var p: float = deg_to_rad(pitch_degrees)
	_cam.position = focus + Vector3(0.0, sin(p) * zoom, cos(p) * zoom)
	_cam.rotation = Vector3(-p, 0.0, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed:
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clampf(zoom - 3.0, 10.0, 55.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clampf(zoom + 3.0, 10.0, 55.0)
		_apply()


func _scene(name: String, pos: Vector3, rot: float = 0.0) -> Node3D:
	var n: Node3D = (load(DIR + name + ".tscn") as PackedScene).instantiate() as Node3D
	n.position = pos
	n.rotation.y = rot
	add_child(n)
	return n


func _multimesh(mesh_name: String, xfs: Array[Transform3D]) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = load(DIR + "meshes/" + mesh_name + ".res") as Mesh
	mm.instance_count = xfs.size()
	for i: int in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	add_child(mmi)


func _build() -> void:
	# Ground.
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(120, 120)
	ground.mesh = plane
	ground.material_override = load(DIR + "ground_material.tres") as Material
	add_child(ground)

	# Forest clusters (upper left and right), mixed variants, scale 0.8-1.3 like main.gd.
	var tree_xf: Array = [[], [], []]
	for c: Vector3 in [Vector3(-17, 0, -8), Vector3(16, 0, -14), Vector3(-20, 0, 10)]:
		for i: int in 14:
			var p: Vector3 = c + Vector3(_rng.randf_range(-6, 6), 0, _rng.randf_range(-4, 4))
			var s: float = _rng.randf_range(0.8, 1.3)
			var v: int = _rng.randi() % 3
			(tree_xf[v] as Array).append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s, s)), p))
	for v: int in 3:
		var arr: Array[Transform3D] = []
		arr.assign(tree_xf[v])
		_multimesh(TREES[v], arr)
	# Rocks.
	var rock_xf: Array = [[], [], []]
	for i: int in 12:
		var p2 := Vector3(_rng.randf_range(-24, 24), 0, _rng.randf_range(-16, 16))
		if p2.length() < 11.0:
			p2 = p2.normalized() * 12.0
		var s2: float = _rng.randf_range(0.8, 2.0)
		(rock_xf[i % 3] as Array).append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s2, s2, s2)), p2))
	for v2: int in 3:
		var arr2: Array[Transform3D] = []
		arr2.assign(rock_xf[v2])
		_multimesh(ROCKS[v2], arr2)

	# Centre: pedestal + ring of 10 pillars (radius 8, gaps at i = 4 and 9), heights 2-4.5 (scale y = h / 3).
	_scene("crown_pedestal", Vector3.ZERO)
	_crown_gem()
	var pil: Array[Transform3D] = []
	for i: int in 10:
		if i == 4 or i == 9:
			continue
		var a: float = i * TAU / 10.0
		var h: float = _rng.randf_range(2.0, 4.5)
		pil.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(1, h / 3.0, 1)),
			Vector3(cos(a) * 8.0, 0, sin(a) * 8.0)))
	_multimesh("ruin_pillar", pil)

	# Crystal nodes at 100 %, 60 %, 25 %.
	var fills: Array[float] = [1.0, 0.6, 0.25]
	for i: int in 3:
		var cn: Node3D = _scene("crystal_node", Vector3(11 + i * 3.2, 0, 4 + i * 1.5), i * 1.3)
		cn.call(&"set_fill_ratio", fills[i])
	# Peddler and two caches (one open).
	_scene("ruin_peddler", Vector3(-10, 0, 7), 0.3)
	_scene("lost_cache", Vector3(4, 0, 11), -0.3)
	var open: Node3D = _scene("lost_cache", Vector3(7, 0, 12), 0.4)
	open.call(&"set_open", true)


func _crown_gem() -> void:
	# Stand-in for the Ember Crown gem (gameplay owns the real one), to judge the pedestal.
	var gem := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.45
	s.height = 1.2
	gem.mesh = s
	gem.material_override = load(DIR + "ember_glow_mat.tres") as Material
	gem.position = Vector3(0, 1.8, 0)
	add_child(gem)


func _save(name: String) -> void:
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = "res://docs/art/screens/%s.png" % name
	img.save_png(ProjectSettings.globalize_path(path))
	print("saved ", path, " fps=", Engine.get_frames_per_second(),
		" draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))


func _shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	for shot: Array in [[15.0, Vector3(0, 0, 1.5), "env_z15_crown"], [15.0, Vector3(5, 0, 8), "env_z15_props"],
			[40.0, Vector3(0, 0, 2), "env_z40"]]:
		zoom = shot[0]
		focus = shot[1]
		_apply()
		await get_tree().create_timer(1.2).timeout
		_save(shot[2])
	get_tree().quit()
