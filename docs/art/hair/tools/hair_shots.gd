extends SceneTree
## Hair review renders (hair redesign plan, docs/art/hair-redesign-plan.md). Windowed (pixels need a GPU).
## For each subject: head close-up 3/4, full body 3/4, game camera at 25 m and 40 m (pitch 55, fov 50, the real
## RTS camera, 1920x1080, cropped around the unit). Writes <out>/<name>_{head,body,z25,z40}.png.
## Usage: tools\godot_run.ps1 --path . -s res://docs/art/hair/tools/hair_shots.gd --quit-after 60000 -- out=res://docs/art/hair/before list=vessa=res://art/units/wizards/vessa.tscn,...

const SUBJECTS_DEFAULT := [
	["vessa", "res://art/units/wizards/vessa.tscn"],
	["malrik", "res://art/units/wizards/malrik.tscn"],
	["torvald", "res://art/units/wizards/torvald.tscn"],
	["ysolde", "res://art/units/wizards/ysolde.tscn"],
	["cinder_hand", "res://art/units/fire/cinder_hand.tscn"],
	["gloom_thrall", "res://art/units/shadow/gloom_thrall.tscn"],
	["rime_hauler", "res://art/units/ice/rime_hauler.tscn"],
	["sprigling", "res://art/units/nature/sprigling.tscn"],
]

var vp: SubViewport
var cam: Camera3D
var out_dir := "res://docs/art/hair/before"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var subjects: Array = SUBJECTS_DEFAULT.duplicate()
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("out="):
			out_dir = a.substr(4)
		elif a.begins_with("list="):
			subjects = []
			for pair: String in a.substr(5).split(","):
				var kv := pair.split("=", true, 1)
				subjects.append([kv[0], kv[1]])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	_stage()
	for s: Array in subjects:
		var ps := load(s[1]) as PackedScene
		if ps == null:
			print("HAIR SHOTS missing ", s[1])
			continue
		var m := ps.instantiate() as Node3D
		if String(s[0]).ends_with("_b") and m.has_method("set_variant"):
			m.call("set_variant", 1)   # champion variant B (the sibling)
		vp.add_child(m)
		await _frames(30)
		m.process_mode = Node.PROCESS_MODE_DISABLED   # freeze the idle sway for the stills
		await _frames(2)
		var body := _aabb(m, m)
		var head_node := m.get_node_or_null(^"Root/Chest/Head") as Node3D
		var head := _aabb(head_node, m) if head_node else body
		if head.size.y < 0.05:
			head = body
		if head.size.y > 0.8:   # hats / antlers / crowns: frame the face + hair, not the whole headgear
			var py := head_node.global_position.y
			head = AABB(Vector3(-0.42, py - 0.32, head.position.z), Vector3(0.84, 0.86, head.size.z))
			print("HAIR SHOTS ", s[0], " head pivot y=", py)
		# head close-up, 3/4 from the unit's right (camera on its left side sees the model's right cheek), slightly high
		vp.size = Vector2i(900, 900)
		cam.fov = 30.0
		_fit(head.grow(0.04), 10.0, 35.0, 0.88)
		await _frames(4)
		_save(s[0] + "_head")
		cam.fov = 30.0
		_fit(body, 12.0, -35.0, 0.92)
		await _frames(4)
		_save(s[0] + "_body")
		vp.size = Vector2i(1920, 1080)
		cam.fov = 50.0
		for z: float in [25.0, 40.0]:
			var focus := Vector3(0, 0.8, 0)
			var p := deg_to_rad(55.0)
			cam.position = focus + Vector3(0, sin(p), cos(p)) * z
			cam.rotation = Vector3(-p, 0, 0)
			await _frames(4)
			var img := vp.get_texture().get_image()
			var sp := cam.unproject_position(Vector3(0, body.get_center().y, 0))
			var top := cam.unproject_position(Vector3(0, body.end.y, 0))
			var bot := cam.unproject_position(Vector3(0, 0, 0))
			var half := maxi(110 if z < 30.0 else 80, int(absf(bot.y - top.y) * 0.85))
			var r := Rect2i(int(sp.x) - half, int(sp.y) - half, half * 2, half * 2)
			var crop := img.get_region(r)
			crop.save_png(ProjectSettings.globalize_path(out_dir.path_join("%s_z%d.png" % [s[0], int(z)])))
		m.queue_free()
		await _frames(2)
		print("HAIR SHOTS ", s[0], " head=", head.size, " body=", body.size)
	print("HAIR SHOTS done -> ", out_dir)
	quit(0)


func _stage() -> void:
	vp = SubViewport.new()
	vp.size = Vector2i(900, 900)
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.42, 0.5, 0.42)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.64, 0.7)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.93, 0.82)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-52, -35, 0)
	vp.add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 80)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.40, 0.47, 0.27)
	gm.roughness = 1.0
	ground.material_override = gm
	vp.add_child(ground)
	cam = Camera3D.new()
	cam.current = true
	vp.add_child(cam)


func _fit(box: AABB, pitch_deg: float, yaw_deg: float, fill: float) -> void:
	var r := maxf(box.size.y, maxf(box.size.x, box.size.z) * 0.9) * 0.5
	var d := r / tan(deg_to_rad(cam.fov * 0.5)) / fill
	var p := deg_to_rad(pitch_deg)
	var y := deg_to_rad(yaw_deg)
	cam.position = box.get_center() + Vector3(sin(y) * cos(p), sin(p), cos(y) * cos(p)) * d
	cam.rotation = Vector3(-p, y, 0.0)


func _aabb(n: Node, model: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for c: Node in n.find_children("*", "GeometryInstance3D", true, false):
		if c.name == "Shadow" or c is GPUParticles3D or c is CPUParticles3D:
			continue
		var gi := c as GeometryInstance3D
		if not gi.is_visible_in_tree():
			continue
		var b: AABB = gi.global_transform * gi.get_aabb()
		if b.size.length() > 6.0:
			continue
		if first:
			box = b
			first = false
		else:
			box = box.merge(b)
	return box


func _save(name: String) -> void:
	vp.get_texture().get_image().save_png(ProjectSettings.globalize_path(out_dir.path_join(name + ".png")))


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


