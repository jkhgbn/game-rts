extends SceneTree
## Faces pass 2026-09-28 (Fire + Ice units): review stills of every FaceKit face on the Fire / Ice army. Windowed.
## Per unit one sheet <out>/<name>.png, 5 tiles per face: neutral front close-up | neutral 3/4 | fierce front | the
## game camera at 25 m (pitch 55, fov 50, 1080p, head crop upscaled) | 40 m with the bold FAR face. Every FaceRig of
## the scene gets a row (frost mortar: loader + gunner). Prints each face's vertex count (neutral / far) per unit.
## Run: tools\godot_run.ps1 --path . -s res://docs/art/faces/fire_ice/tools/unit_face_shots.gd --quit-after 60000 -- [only=a,b] [out=res://...]

const SUBJECTS := [
	["cinder_hand", "res://art/units/fire/cinder_hand.tscn"],
	["flame_guard", "res://art/units/fire/flame_guard.tscn"],
	["ember_archer", "res://art/units/fire/ember_archer.tscn"],
	["ash_hurler", "res://art/units/fire/ash_hurler.tscn"],
	["blaze_rider", "res://art/units/fire/blaze_rider.tscn"],
	["ashveil_saboteur", "res://art/units/fire/ashveil_saboteur/ashveil_saboteur.tscn"],
	["cinder_arbalest", "res://art/units/fire/cinder_arbalest/cinder_arbalest.tscn"],
	["cinderlock", "res://art/units/fire/cinderlock/cinderlock.tscn"],
	["pyre_adept", "res://art/units/fire/pyre_adept/pyre_adept.tscn"],
	["scorchbow", "res://art/units/fire/scorchbow/scorchbow.tscn"],
	["scorchling", "res://art/units/fire/scorchling/scorchling.tscn"],
	["rime_hauler", "res://art/units/ice/rime_hauler.tscn"],
	["rimeshield", "res://art/units/ice/rimeshield.tscn"],
	["shardcaster", "res://art/units/ice/shardcaster.tscn"],
	["rime_seer", "res://art/units/ice/rime_seer.tscn"],
	["frost_mortar", "res://art/units/ice/frost_mortar/frost_mortar.tscn"],
	["frostbow", "res://art/units/ice/frostbow/frostbow.tscn"],
	["frostrune_rifleman", "res://art/units/ice/frostrune_rifleman/frostrune_rifleman.tscn"],
	["hoarlight_magebow", "res://art/units/ice/hoarlight_magebow/hoarlight_magebow.tscn"],
	["rimehorn_rider", "res://art/units/ice/rimehorn_rider/rimehorn_rider.tscn"],
	["rimeling", "res://art/units/ice/rimeling/rimeling.tscn"],
	["shardguard", "res://art/units/ice/shardguard/shardguard.tscn"],
	["torvald", "res://art/units/wizards/torvald.tscn"],
]
const T := 300

var vp: SubViewport
var cam: Camera3D
var out_dir := "res://docs/art/faces/fire_ice"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var only := PackedStringArray()
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("only="):
			only = a.substr(5).split(",")
		elif a.begins_with("out="):
			out_dir = a.substr(4)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	_stage()
	var lineup: Array[Image] = []
	for s: Array in SUBJECTS:
		if not only.is_empty() and not only.has(String(s[0])):
			continue
		var ps := load(s[1]) as PackedScene
		var m := ps.instantiate() as Node3D
		vp.add_child(m)
		await _frames(20)
		var rigs: Array[FaceRig] = []
		_find_rigs(m, rigs)
		if rigs.is_empty():
			print("UNIT FACES ", s[0], " NO FACE")
			m.queue_free()
			continue
		var info := PackedStringArray()
		for r: FaceRig in rigs:
			var key: String = r.get(&"_key")
			var st: Dictionary = r.get(&"_style")
			info.append("%s neutral %d far %d" % [key, _vcount(FaceKit.face_mesh(key, st, &"neutral")),
				_vcount(FaceKit.face_mesh(key, st, FaceKit.FAR))])
		print("UNIT FACES ", s[0], " | ", " | ".join(info))
		m.process_mode = Node.PROCESS_MODE_DISABLED
		var tiles: Array[Image] = []
		for ri: int in rigs.size():
			var rig := rigs[ri]
			var st: Dictionary = rig.get(&"_style")
			var fc: Vector3 = rig.global_transform * (st["canvas"]["c"] as Vector3)
			var rr: float = st["canvas"]["r"]
			var dist := rr * 8.0
			var yaws: Array[float] = [0.0, 32.0, 0.0]
			var exprs: Array[StringName] = [&"neutral", &"neutral", &"fierce"]
			for k: int in 3:
				rig.set_expression(exprs[k])
				vp.size = Vector2i(T, T)
				cam.fov = 20.0
				_look(fc, dist, 8.0, yaws[k])
				await _frames(3)
				tiles.append(vp.get_texture().get_image())
			rig.set_expression(&"neutral")
			tiles.append(await _game_crop(fc, 25.0))
			rig.far()
			tiles.append(await _game_crop(fc, 40.0))
			rig.set_expression(&"neutral")
			if ri == 0:
				lineup.append(tiles[tiles.size() - 2])
		var rows := tiles.size() / 5
		var sheet := Image.create(T * 5, T * rows, false, Image.FORMAT_RGBA8)
		for i: int in tiles.size():
			var im := tiles[i]
			im.convert(Image.FORMAT_RGBA8)
			sheet.blit_rect(im, Rect2i(0, 0, T, T), Vector2i((i % 5) * T, (i / 5) * T))
		sheet.save_png(ProjectSettings.globalize_path(out_dir.path_join("%s.png" % s[0])))
		m.queue_free()
		await _frames(2)
	if lineup.size() > 1:
		var cols := 8
		var lu := Image.create(T * cols, T * ((lineup.size() + cols - 1) / cols), false, Image.FORMAT_RGBA8)
		lu.fill(Color(0.2, 0.2, 0.2))
		for i: int in lineup.size():
			lineup[i].convert(Image.FORMAT_RGBA8)
			lu.blit_rect(lineup[i], Rect2i(0, 0, T, T), Vector2i((i % cols) * T, (i / cols) * T))
		lu.save_png(ProjectSettings.globalize_path(out_dir.path_join("rts_lineup.png")))
	print("UNIT FACES done -> ", out_dir)
	quit(0)


func _find_rigs(n: Node, out: Array[FaceRig]) -> void:
	if n is FaceRig:
		out.append(n as FaceRig)
	for c: Node in n.get_children():
		_find_rigs(c, out)


static func _vcount(m: Mesh) -> int:
	var n := 0
	for s: int in m.get_surface_count():
		n += (m.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return n


## The RTS camera (pitch 55, fov 50, 1080p) at `z` m, a crop around the head, upscaled to T x T.
func _game_crop(fc: Vector3, z: float) -> Image:
	vp.size = Vector2i(1920, 1080)
	cam.fov = 50.0
	var focus := Vector3(fc.x, 0.8, fc.z)
	var p := deg_to_rad(55.0)
	cam.position = focus + Vector3(0, sin(p), cos(p)) * z
	cam.rotation = Vector3(-p, 0, 0)
	await _frames(4)
	var img := vp.get_texture().get_image()
	var sp := cam.unproject_position(fc + Vector3(0, -0.2, 0))
	var half := 44 if z < 30.0 else 30
	var crop := img.get_region(Rect2i(int(sp.x) - half, int(sp.y) - half, half * 2, half * 2))
	crop.resize(T, T, Image.INTERPOLATE_NEAREST)
	vp.size = Vector2i(T, T)
	return crop


func _look(target: Vector3, dist: float, pitch_deg: float, yaw_deg: float) -> void:
	var p := deg_to_rad(pitch_deg)
	var y := deg_to_rad(yaw_deg)
	cam.position = target + Vector3(sin(y) * cos(p), sin(p), cos(y) * cos(p)) * dist
	cam.rotation = Vector3(-p, y, 0.0)


func _stage() -> void:
	vp = SubViewport.new()
	vp.size = Vector2i(T, T)
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
	env.glow_enabled = true
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


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame
