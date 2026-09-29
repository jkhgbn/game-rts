extends SceneTree
## Face review renders for the Nature / Shadow unit faces (face rework 2026-09-28). Windowed.
## Per subject: one sheet row = front close-up neutral | 3/4 neutral | smile | fierce | worried | shout | RTS 25 m crop |
## RTS 40 m crop (bold far face). Every FaceRig in the scene is driven (riders + mounts). Also a lineup at the game
## camera (pitch 55, fov 50, 1080p, 35 m, real pixels, no upscale) of all subjects side by side.
## Writes <out>/<name>_sheet.png, <out>/<name>_front.png, <out>/lineup_<kingdom>_35m.png (+ _x3, nearest x3).
## Run: tools\godot_run.ps1 --path . -s res://docs/art/faces/nature_shadow/tools/ns_face_shots.gd --quit-after 90000 -- [only=a,b] [out=res://docs/art/faces/nature_shadow]

const U := "res://art/units/"
const SUBJECTS := [
	["sprigling", U + "nature/sprigling.tscn"],
	["sapling", U + "nature/sapling.tscn"],
	["bloomtender", U + "nature/bloomtender.tscn"],
	["thornling", U + "nature/thornling.tscn"],
	["burr_slinger", U + "nature/burr_slinger.tscn"],
	["vinelasher", U + "nature/vinelasher/vinelasher.tscn"],
	["wildwood_archer", U + "nature/wildwood_archer/wildwood_archer.tscn"],
	["thistle_darter", U + "nature/thistle_darter/thistle_darter.tscn"],
	["greenheart_oathkeeper", U + "nature/greenheart_oathkeeper/greenheart_oathkeeper.tscn"],
	["bramblehorn", U + "nature/bramblehorn.tscn"],
	["briar_roc", U + "nature/briar_roc/briar_roc.tscn"],
	["mossback", U + "nature/mossback/mossback.tscn"],
	["glade_outrider", U + "nature/glade_outrider/glade_outrider.tscn"],
	["stagrunner", U + "nature/stagrunner/stagrunner.tscn"],
	["gloom_thrall", U + "shadow/gloom_thrall.tscn"],
	["shade", U + "shadow/shade.tscn"],
	["nightbolt", U + "shadow/nightbolt.tscn"],
	["shadow_knight", U + "shadow/shadow_knight.tscn"],
	["grave_hound", U + "shadow/grave_hound.tscn"],
	["barrow_ghoul", U + "shadow/barrow_ghoul/barrow_ghoul.tscn"],
	["bleakbow", U + "shadow/bleakbow/bleakbow.tscn"],
	["hexweaver", U + "shadow/hexweaver/hexweaver.tscn"],
	["hollow_oathsworn", U + "shadow/hollow_oathsworn/hollow_oathsworn.tscn"],
	["nightblood_reaver", U + "shadow/nightblood_reaver/nightblood_reaver.tscn"],
	["gloam_rider", U + "shadow/gloam_rider/gloam_rider.tscn"],
	["barrow_giant", U + "shadow/barrow_giant/barrow_giant.tscn"],
]
const EXPRS: Array[StringName] = [&"neutral", &"neutral", &"smile", &"fierce", &"worried", &"shout", &"neutral", &"far"]
const T := 360

var vp: SubViewport
var cam: Camera3D
var out_dir := "res://docs/art/faces/nature_shadow"


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
	var picked: Array = []
	for s: Array in SUBJECTS:
		if only.is_empty() or only.has(String(s[0])):
			picked.append(s)
	for s: Array in picked:
		var ps := load(s[1]) as PackedScene
		var row: Array[Image] = []
		for i: int in EXPRS.size():
			var e: StringName = EXPRS[i]
			var m := ps.instantiate() as Node3D
			vp.add_child(m)
			await _frames(40)
			var rigs: Array[FaceRig] = []
			_rigs(m, rigs)
			for rig: FaceRig in rigs:
				if e == &"far":
					rig.far()
				else:
					rig.set_expression(e)
			await _frames(2)
			m.process_mode = Node.PROCESS_MODE_DISABLED
			await _frames(2)
			var fc := _face_centre(m, rigs)
			var size := _face_size(rigs)
			if i == 6 or i == 7:
				row.append(await _game_crop(fc, 25.0 if i == 6 else 40.0))
			else:
				vp.size = Vector2i(T, T)
				cam.fov = 20.0
				var dist := clampf(size * 5.5, 1.6, 9.0)
				_look(fc, dist, 8.0, 32.0 if i == 1 else 0.0)
				await _frames(3)
				var im := vp.get_texture().get_image()
				row.append(im)
				if i == 0:
					im.save_png(ProjectSettings.globalize_path(out_dir.path_join("%s_front.png" % s[0])))
			m.queue_free()
			await _frames(2)
		var sheet := Image.create(T * row.size(), T, false, Image.FORMAT_RGBA8)
		for c: int in row.size():
			var im: Image = row[c]
			im.convert(Image.FORMAT_RGBA8)
			sheet.blit_rect(im, Rect2i(0, 0, T, T), Vector2i(c * T, 0))
		sheet.save_png(ProjectSettings.globalize_path(out_dir.path_join("%s_sheet.png" % s[0])))
		print("NS FACE SHOTS ", s[0], " rigs=", _count_rigs(ps))
	for k: String in ["nature", "shadow"]:
		var part: Array = picked.filter(func(e: Array) -> bool: return String(e[1]).contains("/" + k + "/"))
		if not part.is_empty():
			await _lineup(part, k)
	print("NS FACE SHOTS done -> ", out_dir)
	quit(0)


## All subjects in a row at the game camera, 35 m: what the player sees (real pixels) + a nearest x3 blow-up.
func _lineup(picked: Array, tag: String) -> void:
	vp.size = Vector2i(1920, 1080)
	cam.fov = 50.0
	var nodes: Array[Node3D] = []
	var n := picked.size()
	var gap := 2.4
	for i: int in n:
		var m := (load(picked[i][1]) as PackedScene).instantiate() as Node3D
		vp.add_child(m)
		m.position = Vector3((float(i) - float(n - 1) * 0.5) * gap, 0, 0)
		nodes.append(m)
	var p := deg_to_rad(55.0)
	var z := 35.0 * maxf(1.0, float(n) * gap / 34.0)
	cam.position = Vector3(0, 1.0, 0) + Vector3(0, sin(p), cos(p)) * z
	cam.rotation = Vector3(-p, 0, 0)
	await _frames(40)
	var img := vp.get_texture().get_image()
	var a := cam.unproject_position(nodes[0].position + Vector3(-1.4, 3.2, 0))
	var b := cam.unproject_position(nodes[n - 1].position + Vector3(1.4, -0.3, 0))
	var r := Rect2i(Vector2i(maxi(int(a.x), 0), maxi(int(a.y), 0)), Vector2i(int(b.x - a.x), int(b.y - a.y)))
	r = r.intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	var crop := img.get_region(r)
	crop.save_png(ProjectSettings.globalize_path(out_dir.path_join("lineup_%s_35m.png" % tag)))
	var big := crop.duplicate() as Image
	big.resize(crop.get_width() * 3, crop.get_height() * 3, Image.INTERPOLATE_NEAREST)
	big.save_png(ProjectSettings.globalize_path(out_dir.path_join("lineup_%s_35m_x3.png" % tag)))
	for m: Node3D in nodes:
		m.queue_free()
	await _frames(2)


func _rigs(n: Node, out: Array[FaceRig]) -> void:
	if n is FaceRig:
		out.append(n as FaceRig)
	for c: Node in n.get_children():
		_rigs(c, out)


func _count_rigs(ps: PackedScene) -> int:
	var m := ps.instantiate()
	root.add_child(m)
	var r: Array[FaceRig] = []
	_rigs(m, r)
	var k := r.size()
	m.free()
	return k


## Centre of the first rig's face (the neutral mesh's AABB, lower half of it = the painted face, not the hair).
func _face_centre(m: Node3D, rigs: Array[FaceRig]) -> Vector3:
	if rigs.is_empty():
		return m.global_position + Vector3(0, 1.4, 0)
	var rig := rigs[rigs.size() - 1]   # riders are built after their mount: the rider's face
	var bb := rig.get_aabb()
	return rig.global_transform * (bb.get_center() + Vector3(0, -bb.size.y * 0.08, bb.size.z * 0.1))


func _face_size(rigs: Array[FaceRig]) -> float:
	if rigs.is_empty():
		return 0.5
	var bb := rigs[rigs.size() - 1].get_aabb()
	return maxf(bb.size.x, bb.size.y) * 0.8


## The RTS camera (pitch 55, fov 50, 1080p) at `z` m looking at the unit, a crop around the face, upscaled to T x T.
func _game_crop(fc: Vector3, z: float) -> Image:
	vp.size = Vector2i(1920, 1080)
	cam.fov = 50.0
	var focus := Vector3(fc.x, 0.8, fc.z)
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
	pm.size = Vector2(160, 160)
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
