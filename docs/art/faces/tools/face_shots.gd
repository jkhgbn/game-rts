extends SceneTree
## Face review renders (face rework 2026-09-28: eyes, resting smile, expressions of the 5 main wizards). Windowed.
## For each wizard and each expression (+ "far": the bold RTS-distance face): a front close-up, a 3/4 close-up and the
## game camera at 25 m (40 m for "far"; pitch 55, fov 50, 1920x1080, cropped around the head and upscaled so the pixels
## can be judged). Writes
## <out>/<name>_<expr>.png (front close-up), <out>/<name>_sheet.png (rows = expressions: front | 3/4 | 25 m x3) and
## <out>/rts_lineup.png (all wizards: neutral at 25 m, far face at 40 m).
## Run: tools\godot_run.ps1 --path . -s res://docs/art/faces/tools/face_shots.gd --quit-after 60000 -- [only=vessa,malrik] [out=res://docs/art/faces/x]

const SUBJECTS := [
	["vessa", "res://art/units/wizards/vessa.tscn", Vector3(0.0, 1.76, 0.02)],
	["malrik", "res://art/units/wizards/malrik.tscn", Vector3(0.0, 1.90, 0.09)],
	["torvald", "res://art/units/wizards/torvald.tscn", Vector3(0.0, 1.76, 0.10)],
	["ysolde", "res://art/units/wizards/ysolde.tscn", Vector3(0.0, 1.75, 0.05)],
	["aldra", "res://art/units/helpers/helper_aldra/helper_aldra.tscn", Vector3(0.0, 1.74, 0.02)],
]
const EXPRS: Array[StringName] = [&"neutral", &"smile", &"fierce", &"worried", &"shout", &"far"]
const T := 400

var vp: SubViewport
var cam: Camera3D
var out_dir := "res://docs/art/faces"


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
		var fc: Vector3 = s[2]
		var rows: Array = []
		for e: StringName in EXPRS:
			var m := ps.instantiate() as Node3D
			vp.add_child(m)
			await _frames(20)
			if e == &"far":
				var rig: Variant = m.get(&"_face")
				if rig is FaceRig:
					(rig as FaceRig).far()
			elif m.has_method(&"set_expression"):
				m.call(&"set_expression", e)
			await _frames(2)
			m.process_mode = Node.PROCESS_MODE_DISABLED
			await _frames(2)
			var shown: StringName = m.call(&"get_expression") if m.has_method(&"get_expression") else &"-"
			vp.size = Vector2i(T, T)
			cam.fov = 20.0
			_look(fc + Vector3(0, 0.02, 0), 1.9, 8.0, 0.0)
			await _frames(3)
			var front := vp.get_texture().get_image()
			front.save_png(ProjectSettings.globalize_path(out_dir.path_join("%s_%s.png" % [s[0], e])))
			_look(fc + Vector3(0, 0.02, 0), 1.9, 12.0, 32.0)
			await _frames(3)
			var tq := vp.get_texture().get_image()
			var z25 := await _game_crop(fc, 40.0 if e == &"far" else 25.0, 3)
			rows.append([front, tq, z25])
			if e == &"neutral":
				lineup.append(z25)
			elif e == &"far":
				lineup.append(z25)
			print("FACE SHOTS ", s[0], " ", e, " (shown ", shown, ")")
			m.queue_free()
			await _frames(2)
		var sheet := Image.create(T * 3, T * rows.size(), false, Image.FORMAT_RGBA8)
		for r: int in rows.size():
			for c: int in 3:
				var im: Image = rows[r][c]
				im.convert(Image.FORMAT_RGBA8)
				sheet.blit_rect(im, Rect2i(0, 0, T, T), Vector2i(c * T, r * T))
		sheet.save_png(ProjectSettings.globalize_path(out_dir.path_join("%s_sheet.png" % s[0])))
	if not lineup.is_empty():
		var n := lineup.size() / 2
		var lu := Image.create(T * n, T * 2, false, Image.FORMAT_RGBA8)
		for i: int in n:
			for k: int in 2:
				var im := lineup[i * 2 + k]
				im.convert(Image.FORMAT_RGBA8)
				lu.blit_rect(im, Rect2i(0, 0, T, T), Vector2i(i * T, k * T))
		lu.save_png(ProjectSettings.globalize_path(out_dir.path_join("rts_lineup.png")))
	print("FACE SHOTS done -> ", out_dir)
	quit(0)


## The RTS camera (pitch 55, fov 50, 1080p) at `z` m, a crop of the head region, upscaled so it fills a T x T tile.
func _game_crop(fc: Vector3, z: float, _k: int) -> Image:
	vp.size = Vector2i(1920, 1080)
	cam.fov = 50.0
	var focus := Vector3(0, 0.8, 0)
	var p := deg_to_rad(55.0)
	cam.position = focus + Vector3(0, sin(p), cos(p)) * z
	cam.rotation = Vector3(-p, 0, 0)
	await _frames(4)
	var img := vp.get_texture().get_image()
	var sp := cam.unproject_position(fc + Vector3(0, -0.25, 0))
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
