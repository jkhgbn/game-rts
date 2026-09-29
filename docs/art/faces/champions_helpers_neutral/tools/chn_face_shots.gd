extends SceneTree
## Faces pass 2026-09-28 (champions, helpers, neutral, mounts, caravan, titans): review stills. Windowed.
## Per subject one sheet <out>/<name>.png, 6 tiles per head: front close-up (neutral) | 3/4 | fierce front | smile front |
## the game camera at 25 m (pitch 55, fov 50, 1080p, head crop upscaled) | 40 m (bold FAR face). Subjects without a
## FaceRig get the same framing on their "Head" pivot (before shots). Prints each face's vertex count (neutral / far).
## Run: tools\godot_run.ps1 --path . -s res://docs/art/faces/champions_helpers_neutral/tools/chn_face_shots.gd
##      --quit-after 90000 -- [only=a,b] [out=res://...] [variant=1] (variant 1 = the B sibling: <name>_b.png)

const SUBJECTS := [
	["coin_cutter", "res://art/units/champions/coin_cutter/coin_cutter.tscn"],
	["mage_archer", "res://art/units/champions/mage_archer/mage_archer.tscn"],
	["mender", "res://art/units/champions/mender/mender.tscn"],
	["oathwall", "res://art/units/champions/oathwall/oathwall.tscn"],
	["wayfinder", "res://art/units/champions/wayfinder/wayfinder.tscn"],
	["wildcaller", "res://art/units/champions/wildcaller/wildcaller.tscn"],
	["helper_maelis", "res://art/units/helpers/helper_maelis/helper_maelis.tscn"],
	["helper_vey", "res://art/units/helpers/helper_vey/helper_vey.tscn"],
	["helper_hush", "res://art/units/helpers/helper_hush/helper_hush.tscn"],
	["helper_aldra", "res://art/units/helpers/helper_aldra/helper_aldra.tscn"],
	["tracker", "res://art/units/neutral/tracker/tracker.tscn"],
	["magpie", "res://art/units/neutral/magpie/magpie.tscn"],
	["ruin_warden", "res://art/units/neutral/ruin_warden.tscn"],
	["stormbottle_genie", "res://art/units/neutral/stormbottle_genie/stormbottle_genie.tscn"],
	["gloomcap_elder", "res://art/units/neutral/gloomcap/gloomcap_elder.tscn"],
	["gloomcap_sprout", "res://art/units/neutral/gloomcap/gloomcap_sprout.tscn"],
	["bristleback", "res://art/units/neutral/bristleback/bristleback.tscn"],
	["mirefang", "res://art/units/neutral/mirefang/mirefang.tscn"],
	["hollow_stag", "res://art/units/neutral/hollow_stag/hollow_stag.tscn"],
	["direwolf", "res://art/units/neutral/beasts/direwolf/direwolf.tscn"],
	["grizzlemaw", "res://art/units/neutral/beasts/grizzlemaw/grizzlemaw.tscn"],
	["tusker", "res://art/units/neutral/beasts/tusker/tusker.tscn"],
	["roc", "res://art/units/neutral/beasts/roc/roc.tscn"],
	["frost_wyrm", "res://art/units/neutral/beasts/frost_wyrm/frost_wyrm.tscn"],
	["deer", "res://art/units/neutral/critters/deer.tscn"],
	["rabbit", "res://art/units/neutral/critters/rabbit.tscn"],
	["dusk_steed", "res://art/units/mounts/dusk_steed/dusk_steed.tscn"],
	["ember_boar", "res://art/units/mounts/ember_boar/ember_boar.tscn"],
	["grove_stag", "res://art/units/mounts/grove_stag/grove_stag.tscn"],
	["rimehorn", "res://art/units/mounts/rimehorn/rimehorn.tscn"],
	["roan_courser", "res://art/units/mounts/roan_courser/roan_courser.tscn"],
	["caravan", "res://art/units/caravan/caravan.tscn"],
	["cinder_dragon", "res://art/units/titans/cinder_dragon/cinder_dragon.tscn"],
	["frost_dragon", "res://art/units/titans/frost_dragon/frost_dragon.tscn"],
	["elder_treant", "res://art/units/titans/elder_treant/elder_treant.tscn"],
	["nightmare_knight", "res://art/units/titans/nightmare_knight/nightmare_knight.tscn"],
	["war_mammoth", "res://art/units/titans/war_mammoth/war_mammoth.tscn"],
]
const T := 300
const COLS := 6

var vp: SubViewport
var cam: Camera3D
var out_dir := "res://docs/art/faces/champions_helpers_neutral"
var variant := ""


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var only := PackedStringArray()
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("only="):
			only = a.substr(5).split(",")
		elif a.begins_with("out="):
			out_dir = a.substr(4)
		elif a.begins_with("variant="):
			variant = a.substr(8)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	_stage()
	var lineup: Array[Image] = []
	for s: Array in SUBJECTS:
		if not only.is_empty() and not only.has(String(s[0])):
			continue
		var ps := load(s[1]) as PackedScene
		var m := ps.instantiate() as Node3D
		vp.add_child(m)
		if variant != "" and m.has_method(&"set_variant"):
			m.call(&"set_variant", int(variant))
		await _frames(20)
		var rigs: Array[FaceRig] = []
		_find_rigs(m, rigs)
		var heads: Array = []   # [centre, radius, rig or null]
		if rigs.is_empty():
			var h := _find_head(m)
			if h == null:
				print("UNIT FACES ", s[0], " NO HEAD")
				m.queue_free()
				continue
			var bb := _aabb(h)
			heads.append([bb.get_center(), maxf(bb.size.y, maxf(bb.size.x, bb.size.z)) * 0.3, null])
			print("UNIT FACES ", s[0], " NO FACE (head ", h.name, " ", bb, ")")
		else:
			var info := PackedStringArray()
			for r: FaceRig in rigs:
				var key: String = r.get(&"_key")
				var st: Dictionary = r.get(&"_style")
				info.append("%s neutral %d far %d" % [key, _vcount(FaceKit.face_mesh(key, st, &"neutral")),
					_vcount(FaceKit.face_mesh(key, st, FaceKit.FAR))])
				heads.append([r.global_transform * (st["canvas"]["c"] as Vector3), float(st["canvas"]["r"]), r])
			print("UNIT FACES ", s[0], " | ", " | ".join(info))
		m.process_mode = Node.PROCESS_MODE_DISABLED
		var tiles: Array[Image] = []
		for hi: int in heads.size():
			var fc: Vector3 = heads[hi][0]
			var rr: float = heads[hi][1]
			var rig: FaceRig = heads[hi][2]
			var fwd := _forward(m, rig)
			var dist := rr * 8.0
			var yaws: Array[float] = [0.0, 32.0, 0.0, 0.0]
			var exprs: Array[StringName] = [&"neutral", &"neutral", &"fierce", &"smile"]
			for k: int in 4:
				if rig:
					rig.set_expression(exprs[k])
				vp.size = Vector2i(T, T)
				cam.fov = 20.0
				_look(fc, dist, 8.0, rad_to_deg(atan2(fwd.x, fwd.z)) + yaws[k])
				await _frames(3)
				tiles.append(vp.get_texture().get_image())
			if rig:
				rig.set_expression(&"neutral")
			tiles.append(await _game_crop(fc, 25.0, rr))
			if rig:
				rig.far()
			tiles.append(await _game_crop(fc, 40.0, rr))
			if rig:
				rig.set_expression(&"neutral")
			if hi == 0:
				lineup.append(tiles[tiles.size() - 2])
		var rows := tiles.size() / COLS
		var sheet := Image.create(T * COLS, T * rows, false, Image.FORMAT_RGBA8)
		for i: int in tiles.size():
			var im := tiles[i]
			im.convert(Image.FORMAT_RGBA8)
			sheet.blit_rect(im, Rect2i(0, 0, T, T), Vector2i((i % COLS) * T, (i / COLS) * T))
		sheet.save_png(ProjectSettings.globalize_path(out_dir.path_join("%s%s.png" % [s[0], "_b" if variant == "1" else ""])))
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


## The facing direction of a face in world space (+Z of the rig's parent chain / the model).
func _forward(m: Node3D, rig: FaceRig) -> Vector3:
	var b := (rig.global_transform.basis if rig else m.global_transform.basis)
	var f := b * Vector3(0, 0, 1)
	f.y = 0.0
	return f.normalized() if f.length() > 0.01 else Vector3(0, 0, 1)


func _find_rigs(n: Node, out: Array[FaceRig]) -> void:
	if n is FaceRig:
		out.append(n as FaceRig)
	for c: Node in n.get_children():
		_find_rigs(c, out)


func _find_head(n: Node) -> Node3D:
	var q: Array[Node] = [n]
	while not q.is_empty():
		var c: Node = q.pop_front()
		if c is Node3D and String(c.name) == "Head" and not _aabb(c as Node3D).size.is_zero_approx():
			return c as Node3D
		q.append_array(c.get_children())
	return null


func _aabb(n: Node3D) -> AABB:
	var out := AABB()
	var first := true
	var q: Array[Node] = [n]
	while not q.is_empty():
		var c: Node = q.pop_front()
		if c is MeshInstance3D and (c as MeshInstance3D).mesh and (c as MeshInstance3D).visible:
			var bb: AABB = (c as MeshInstance3D).global_transform * (c as MeshInstance3D).get_aabb()
			out = bb if first else out.merge(bb)
			first = false
		q.append_array(c.get_children())
	return out


static func _vcount(m: Mesh) -> int:
	var n := 0
	for s: int in m.get_surface_count():
		n += (m.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return n


## The RTS camera (pitch 55, fov 50, 1080p) at `z` m, a crop around the head, upscaled to T x T.
func _game_crop(fc: Vector3, z: float, rr: float) -> Image:
	vp.size = Vector2i(1920, 1080)
	cam.fov = 50.0
	var focus := Vector3(fc.x, 0.8, fc.z)
	var p := deg_to_rad(55.0)
	cam.position = focus + Vector3(0, sin(p), cos(p)) * z
	cam.rotation = Vector3(-p, 0, 0)
	await _frames(4)
	var img := vp.get_texture().get_image()
	var sp := cam.unproject_position(fc + Vector3(0, -0.2, 0))
	var half := int((44 if z < 30.0 else 30) * clampf(rr / 0.2, 1.0, 4.0))
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
