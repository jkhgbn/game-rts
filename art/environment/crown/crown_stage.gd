extends SceneTree
## Fast look-dev stage for task A2.3 (no gameplay): painted ground with the crown plaza, the warm lighting rig,
## the altar in a manual look, a stand-in crown (the crown model + the Artifact's OmniLight values), and crystal
## nodes at several fills. Game camera (pitch 55, fov 50). Windowed only:
##   Godot_v4.7.2-stable_win64_console.exe --path . -s res://art/environment/crown/crown_stage.gd
##       --resolution 1600x900 --quit-after 2000 -- tag=t1 shots=crown_z14,crystal_z14
## light=E / range=R: the stand-in crown's OmniLight (defaults 2.0 / 7.0 = artifact.gd today).
## Shots: crown_z14, crown_z24 (4 looks side by side is not possible: one look per run, look=sealed|stirring|
## awake|empty), crystal_z14, crystal_z30.

const PEDESTAL := "res://art/environment/crown_pedestal.tscn"
const CROWN_MESH := "res://art/environment/crown/ember_crown_mesh.res"
const CRYSTAL := "res://art/environment/crystal_node.tscn"

var _tag := "stage"
var _look := "sealed"
var _light := 2.0
var _range := 7.0
var _shots: PackedStringArray = PackedStringArray(["crown_z14", "crown_z24"])
var _cam: Camera3D
var _stage: Node3D


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("tag="):
			_tag = arg.substr(4)
		elif arg.begins_with("look="):
			_look = arg.substr(5)
		elif arg.begins_with("light="):
			_light = float(arg.substr(6))
		elif arg.begins_with("range="):
			_range = float(arg.substr(6))
		elif arg.begins_with("shots="):
			_shots = arg.substr(6).split(",")
	_stage = Node3D.new()
	root.add_child(_stage)
	var rig: Node = (load("res://art/environment/lighting/lighting_rig.gd") as GDScript).new()
	rig.set(&"preset_id", &"warm")
	_stage.add_child(rig)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(80, 80)
	ground.mesh = plane
	var gm := (load("res://art/environment/ground_material.tres") as ShaderMaterial).duplicate() as ShaderMaterial
	gm.set_shader_parameter("spot_0", Vector4(0, 0, 9.5, 1.0))
	gm.set_shader_parameter("spot_1", Vector4(30, 0, 5.0, 0.0))
	gm.set_shader_parameter("spot_2", Vector4.ZERO)
	gm.set_shader_parameter("spot_3", Vector4.ZERO)
	ground.material_override = gm
	_stage.add_child(ground)
	# Altar + stand-in crown.
	var ped: Node3D = (load(PEDESTAL) as PackedScene).instantiate() as Node3D
	_stage.add_child(ped)
	for arg: String in OS.get_cmdline_user_args():
		if arg == "freeze=1":
			ped.set_process(false)
		if arg.begins_with("hide="):
			for n: String in arg.substr(5).split(","):
				var node := ped.get_node_or_null(NodePath(n)) as Node3D
				if node:
					node.visible = false
					node.process_mode = Node.PROCESS_MODE_DISABLED
	match _look:
		"sealed":
			ped.call(&"set_sealed", true)
		"stirring":
			ped.call(&"set_sealed", true)
			ped.call(&"set_stirring", true)
		"empty":
			ped.call(&"set_crown_present", false)
	if _look != "empty":
		var gem := MeshInstance3D.new()
		gem.mesh = load(CROWN_MESH) as Mesh
		gem.position = Vector3(0, 1.8, 0)
		gem.set_script(load("res://art/environment/crown/crown_stage_spin.gd"))
		_stage.add_child(gem)
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.8, 0.3)
		light.omni_range = _range
		light.light_energy = _light
		light.position.y = 2.0
		_stage.add_child(light)
	# Crystal nodes at 100 / 62 / 30 / 10 %.
	var fills: Array[float] = [1.0, 0.62, 0.3, 0.1]
	for i: int in fills.size():
		if not ResourceLoader.exists(CRYSTAL):
			break
		var cn: Node3D = (load(CRYSTAL) as PackedScene).instantiate() as Node3D
		cn.position = Vector3(24.0 + i * 4.0, 0, 1.0 + (i % 2) * 1.2)
		_stage.add_child(cn)
		cn.call(&"set_fill_ratio", fills[i])
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_stage.add_child(_cam)
	_cam.make_current()
	_run()


func _place(zoom: float, focus: Vector3) -> void:
	var p := deg_to_rad(55.0)
	_cam.position = focus + Vector3(0.0, sin(p) * zoom, cos(p) * zoom)
	_cam.rotation = Vector3(-p, 0.0, 0.0)


func _run() -> void:
	for i in 30:
		await process_frame
	for s: String in _shots:
		match s:
			"crown_z10":
				_place(10.0, Vector3(0, 0.6, 0.4))
			"crown_z14":
				_place(14.0, Vector3(0, 0, 0.6))
			"crown_z24":
				_place(24.0, Vector3(0, 0, 0.6))
			"crown_z45":
				_place(45.0, Vector3(0, 0, 2.0))
			"side":
				_cam.position = Vector3(0.0, 4.0, 22.0)
				_cam.rotation = Vector3(0.0, 0.0, 0.0)
			"crystal_z10":
				_place(10.0, Vector3(30.0, 0.3, 1.6))
			"crystal_z14":
				_place(14.0, Vector3(30.0, 0, 1.6))
			"crystal_z30":
				_place(30.0, Vector3(30.0, 0, 1.6))
		for i in 40:
			await process_frame
		await RenderingServer.frame_post_draw
		var img: Image = root.get_texture().get_image()
		var path := "res://docs/art/screens/a23_stage_%s_%s_%s.png" % [_tag, _look, s]
		img.save_png(ProjectSettings.globalize_path(path))
		print("saved %s draws=%d" % [path, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])
	quit()
