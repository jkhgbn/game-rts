extends SceneTree
## Task 9.V4: the Mender champion model + variant B (art/units/champions/mender/mender.tscn).
## Headless check:  $GODOT --headless --path . -s tests/test_9_v4.gd --fixed-fps 60 --quit-after 900
##   instantiation (both variants, team colour before _ready), budgets (<= 26 authored meshes, <= 16 draw instances
##   after the merge, 0 lights, <= 5 own materials), head height, team colour only on sash + pennant (cached per
##   colour), variant toggle, every hook callable (walk, attack release, the 3 casts + an unknown id, hit, level-up,
##   statuses, death -> death_finished, revive), the censer hangs under the crook. Prints PASS 9.v4 / FAIL 9.v4.
## Shots (windowed):  Godot_v4.7.2-stable_win64.exe --path . -s tests/test_9_v4.gd --fixed-fps 60 --quit-after 4000 -- --shots
##   docs/art/screens/champion_mender.png (both variants: portraits, game camera z15 / z40, poses, team colours),
##   docs/art/screens/champion_mender_silhouette.png, and docs/art/screens/champions_silhouette.png when the three
##   other champions' silhouettes exist.

const TASK_ID := "9.v4"
const SCENE := "res://art/units/champions/mender/mender.tscn"
const OWN_DIR := "res://art/units/champions/mender/"
const FIRE := Color(0.85, 0.30, 0.12)
const SHADOW := Color(0.42, 0.22, 0.60)
const ICE := Color(0.55, 0.80, 0.95)
const NATURE := Color(0.35, 0.70, 0.25)
const HOOKS: Array[String] = ["set_team_color", "set_moving", "play_attack", "play_cast", "play_hit", "play_death",
	"play_level_up", "set_veterancy", "set_carrying", "play_mine", "set_status", "revive", "set_variant",
	"get_beam_origin", "authored_mesh_count"]

var _fails: PackedStringArray = []
var _world: Node3D
var _cam: Camera3D
var _env: Environment


func _initialize() -> void:
	if "--shots" in OS.get_cmdline_user_args():
		_shots.call_deferred()
	else:
		_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAIL: ", what)


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


# ================================================================ headless test

func _run() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	var packed := load(SCENE) as PackedScene
	_check(packed != null, "scene loads")
	if packed == null:
		_finish()
		return
	var a: Node3D = packed.instantiate()
	var b: Node3D = packed.instantiate()
	for h: String in HOOKS:
		_check(a.has_method(h), "hook %s exists" % h)
	# calls before _ready are cached (kit rule)
	b.call(&"set_variant", 1)
	b.call(&"set_team_color", SHADOW)
	a.position = Vector3(-2, 0, 0)
	b.position = Vector3(2, 0, 0)
	_world.add_child(a)
	_world.add_child(b)
	await _frames(3)

	# ---- budgets
	var authored: int = a.call(&"authored_mesh_count")
	print("authored meshes: ", authored)
	_check(authored > 0 and authored <= 26, "authored meshes <= 26 (%d)" % authored)
	_check(int(b.call(&"authored_mesh_count")) == authored, "second instance counts the same parts")
	var draws := _draw_instances(a)
	print("draw instances after merge: ", draws.size(), "  ", draws)
	_check(draws.size() <= 16, "draw instances <= 16 (%d)" % draws.size())
	_check(a.find_children("*", "Light3D", true, false).is_empty(), "0 lights")
	var mats := _materials(a)
	print("materials: ", mats)
	var own := 0
	for p: String in mats:
		if p.begins_with(OWN_DIR):
			own += 1
		elif p != "res://art/units/kit/materials/unit_shadow_blob.tres":
			_check(false, "unexpected material %s" % p)
	_check(own <= 5, "own materials <= 5 (%d)" % own)
	var verts := 0
	var per: PackedStringArray = []
	for n: Node in a.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh:
			var nv := 0
			for s: int in mi.mesh.get_surface_count():
				nv += (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			verts += nv
			per.append("%s %d" % [a.get_path_to(mi), nv])
	print("vertices: ", verts, "  ", per)
	for id: String in ["wizards/vessa", "wizards/ysolde", "nature/bloomtender"]:
		var w: Node3D = (load("res://art/units/%s.tscn" % id) as PackedScene).instantiate()
		_world.add_child(w)
		await process_frame
		var wv := 0
		for n: Node in w.find_children("*", "MeshInstance3D", true, false):
			var mi := n as MeshInstance3D
			if mi.mesh:
				for s: int in mi.mesh.get_surface_count():
					wv += (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		print("  reference %s vertices: %d" % [id, wv])
		w.queue_free()
	_check(verts <= 8000, "vertices <= 8000, a hero budget like Ysolde (%d)" % verts)

	# ---- shape: head top ~ body_height, blob, staff length, footprint
	var top := _top_of(a.get_node(^"Root/Chest/Head/Merged") as MeshInstance3D, a)
	print("head top (A, no bun): %.3f" % top)
	_check(absf(top - 1.7) <= 0.25, "head top at body_height +- 25 %% (%.2f)" % top)
	_check(is_equal_approx(float(a.get(&"body_height")), 1.7), "body_height 1.7")
	_check(a.get(&"attack_style") == &"staff", "attack_style staff")
	_check(float(a.get(&"attack_windup")) > 0.0 and float(a.get(&"attack_windup")) <= 0.15, "attack_windup <= 0.15")
	_check(a.get_node_or_null(^"Shadow") != null, "shadow blob")

	# ---- variant toggle: one node, mesh swapped
	var va := a.get_node(^"Root/Chest/Head/Variant") as MeshInstance3D
	var vb := b.get_node(^"Root/Chest/Head/Variant") as MeshInstance3D
	_check(va != null and vb != null and va.mesh != vb.mesh, "variant B shows another piece than A")
	a.call(&"set_variant", 1)
	_check(va.mesh == vb.mesh, "set_variant(1) swaps to the beard")
	a.call(&"set_variant", 0)
	_check(va.mesh != vb.mesh, "set_variant(0) swaps back")

	# ---- team colour: only sash (cloth, cloth_dark) + pennant change; cached per colour; no-op for the scene colour
	var chest_b := b.get_node(^"Root/Chest/Merged") as MeshInstance3D
	var changed := _recoloured_surfaces(b)
	print("recoloured surfaces (B, shadow): ", changed)
	_check(changed.size() == 3, "set_team_color touches exactly sash, sash trim and pennant (%d)" % changed.size())
	var got_team := false
	for s: int in chest_b.mesh.get_surface_count():
		var m := chest_b.get_surface_override_material(s) as ShaderMaterial
		if m and m.resource_name == "mender_cloth":
			got_team = (m.get_shader_parameter(&"base_color") as Color).is_equal_approx(SHADOW)
	_check(got_team, "sash is the team colour")
	a.call(&"set_team_color", FIRE)
	_check(_recoloured_surfaces(a).is_empty(), "kingdom colour of the scene = no-op")
	var c: Node3D = packed.instantiate()
	c.call(&"set_team_color", SHADOW)
	_world.add_child(c)
	await _frames(1)
	var chest_c := c.get_node(^"Root/Chest/Merged") as MeshInstance3D
	var same := true
	for s: int in chest_b.mesh.get_surface_count():
		if chest_b.get_surface_override_material(s) != chest_c.get_surface_override_material(s):
			same = false
	_check(same, "team materials cached per colour (shared between units)")
	c.queue_free()

	# ---- censer hangs below the crook
	await _frames(30)
	var censer := a.get_node(^"Root/Chest/ArmR/Staff/Censer") as Node3D
	var o: Vector3 = a.call(&"get_beam_origin")
	_check(o.y < censer.global_position.y - 0.15 and absf(o.x - censer.global_position.x) < 0.05, "kettle hangs under the hook")
	print("beam origin (model): ", a.to_local(o))
	_check(a.to_local(o).y > 1.6 and a.to_local(o).y < 2.1, "beam origin at the censer")

	# ---- hooks
	a.call(&"set_moving", 4.8)
	await _frames(40)
	a.call(&"set_moving", 0.0)
	var o0: Vector3 = a.call(&"get_beam_origin")
	a.call(&"play_attack")
	await _frames(10)   # past the 0.14 s release
	var o1: Vector3 = a.call(&"get_beam_origin")
	_check(a.to_local(o1).z > a.to_local(o0).z + 0.1, "staff jab throws the censer forward (%.2f -> %.2f)" % [a.to_local(o0).z, a.to_local(o1).z])
	await _frames(30)
	for id: StringName in [&"mending_draught", &"soothing_circle", &"lifeline", &"something_else"]:
		a.call(&"play_cast", id)
		var max_tilt := 0.0
		for i: int in 40:
			await process_frame
			var d: Vector3 = (a.call(&"get_beam_origin") as Vector3) - censer.global_position
			max_tilt = maxf(max_tilt, rad_to_deg(Vector3.DOWN.angle_to(d.normalized())))
		print("cast %s: censer swings up to %.0f deg" % [id, max_tilt])
		_check(max_tilt > 35.0, "cast %s swings the censer (%.0f deg)" % [id, max_tilt])
		await _frames(35)
	a.call(&"play_hit")
	await _frames(15)
	a.call(&"play_level_up")
	await _frames(30)
	_check(a.call(&"set_status", &"haste", true) == true, "haste handled")
	_check(a.call(&"set_status", &"shroud", true) == true, "shroud handled")
	_check(a.call(&"set_status", &"burn", true) == false, "burn keeps the placeholder mark")
	a.call(&"set_status", &"haste", false)
	a.call(&"set_veterancy", 2)
	a.call(&"set_carrying", true)
	a.call(&"play_mine")
	await _frames(5)
	var done := [false]
	a.connect(&"death_finished", func() -> void: done[0] = true, CONNECT_ONE_SHOT)
	a.call(&"play_death")
	await _frames(75)
	_check(done[0], "death_finished within 1.25 s")
	a.call(&"revive")
	await _frames(10)
	_check(absf((a.get_node(^"Root") as Node3D).rotation.x) < 0.05, "revive resets the pose")
	b.call(&"play_death")
	await _frames(10)
	_finish()


func _finish() -> void:
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


func _draw_instances(m: Node) -> PackedStringArray:
	var out := PackedStringArray()
	for n: Node in m.find_children("*", "GeometryInstance3D", true, false):
		if n is MeshInstance3D and (n as MeshInstance3D).mesh == null:
			continue
		out.append(String(m.get_path_to(n)))
	return out


func _materials(m: Node) -> PackedStringArray:
	var seen := {}
	for n: Node in m.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		if mi.material_override:
			seen[mi.material_override.resource_path] = true
			continue
		for s: int in mi.mesh.get_surface_count():
			var mat := mi.get_surface_override_material(s)
			if mat == null:
				mat = mi.mesh.surface_get_material(s)
			if mat:
				seen[mat.resource_path if mat.resource_path != "" else "<runtime %s>" % mat.resource_name] = true
	return PackedStringArray(seen.keys())


## Surfaces / nodes whose material was swapped by set_team_color (override != mesh material).
func _recoloured_surfaces(m: Node) -> PackedStringArray:
	var out := PackedStringArray()
	for n: Node in m.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		if mi.material_override and mi.material_override.resource_path == "":
			out.append("%s override" % mi.name)
		for s: int in mi.mesh.get_surface_count():
			var o := mi.get_surface_override_material(s)
			if o and o != mi.mesh.surface_get_material(s):
				out.append("%s/%d %s" % [m.get_path_to(mi), s, o.resource_name])
	return out


func _top_of(mi: MeshInstance3D, model: Node3D) -> float:
	var ab := mi.get_aabb()
	var xf := model.global_transform.affine_inverse() * mi.global_transform
	var top := -INF
	for i: int in 8:
		top = maxf(top, (xf * ab.get_endpoint(i)).y)
	return top


# ================================================================ shots (windowed)

func _shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
	_world = Node3D.new()
	root.add_child(_world)
	var we := WorldEnvironment.new()
	_env = (load("res://art/environment/world_env.tres") as Environment).duplicate()
	we.environment = _env
	_world.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.00, 0.93, 0.82)
	sun.light_energy = 1.3
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.shadow_enabled = true
	sun.shadow_normal_bias = 2.0
	sun.directional_shadow_max_distance = 80.0
	_world.add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(400, 400)
	ground.mesh = pm
	ground.material_override = load("res://art/environment/ground_material.tres")
	_world.add_child(ground)
	_cam = Camera3D.new()
	_cam.fov = 50.0
	_cam.far = 500.0
	_world.add_child(_cam)
	await _wait(0.5)

	var cells: Array[Image] = []
	var labels: PackedStringArray = []
	# 1) portraits A / B, 3/4 front, front, 3/4 back
	var pa := _spawn(0, Vector3(0, 0, 0), FIRE)
	var pb := _spawn(1, Vector3(8, 0, 0), SHADOW)
	await _wait(2.0)
	for pair: Array in [[pa, "Orla (A), fire sash"], [pb, "Osric (B), shadow sash"]]:
		var m: Node3D = pair[0]
		for yaw: float in [28.0, 0.0, 150.0]:
			_orbit(m.global_position + Vector3(0, 1.2, 0), 4.9, 14.0, yaw)
			cells.append(await _grab_crop(0.62))
			labels.append("%s yaw %d" % [pair[1], yaw])
	# 2) game camera (pitch 55) at zoom 15 and 40, both variants side by side + another team colour pair
	var pc := _spawn(0, Vector3(1.4, 0, 30), ICE)
	var pd := _spawn(1, Vector3(-1.4, 0, 30), NATURE)
	var pe := _spawn(0, Vector3(-0.6, 0, 60), FIRE)
	var pf := _spawn(1, Vector3(0.6, 0, 60), SHADOW)
	pf.rotation.y = 0.6
	pe.rotation.y = -0.5
	await _wait(0.6)
	_game_cam(15.0, Vector3(0, 0.8, 30))
	cells.append(await _grab_crop(0.62))
	labels.append("zoom 15 (ice / nature)")
	_game_cam(40.0, Vector3(0, 0.8, 60))
	cells.append(await _grab_crop(0.62))
	labels.append("zoom 40 (fire / shadow)")
	# 3) poses: attack release, draught circle, soothing circle overhead, lifeline thrust, walk, death
	var poses: Array = [["attack", &"", 0.15], ["cast", &"mending_draught", 0.35], ["cast", &"soothing_circle", 0.55],
		["cast", &"lifeline", 0.55], ["walk", &"", 0.3], ["death", &"", 0.5]]
	var x := -20.0
	var actors: Array = []
	for i: int in poses.size():
		var m := _spawn(i % 2, Vector3(x + 7.0 * i, 0, -30), FIRE if i % 2 == 0 else SHADOW)
		actors.append(m)
	await _wait(1.5)
	for i: int in poses.size():
		var m: Node3D = actors[i]
		var p: Array = poses[i]
		match p[0]:
			"attack": m.call(&"play_attack")
			"cast": m.call(&"play_cast", p[1])
			"walk": m.call(&"set_moving", 4.8)
			"death": m.call(&"play_death")
		var t0 := Time.get_ticks_msec()
		await _wait(p[2])
		_orbit(m.global_position + Vector3(0, 1.35, 0), 6.2, 16.0, 35.0)
		await RenderingServer.frame_post_draw
		cells.append(_crop(root.get_texture().get_image(), 0.62))
		labels.append("%s %s @%.2fs" % [p[0], p[1], (Time.get_ticks_msec() - t0) / 1000.0])
	_sheet(cells, 4, "res://docs/art/screens/champion_mender.png")
	print("labels: ", labels)

	# 4) silhouette: unlit black on white; A and B front + side, game camera at 17 and 40
	await _silhouette()
	print("9.V4 SHOTS DONE")
	quit()


func _spawn(variant: int, p: Vector3, team: Color) -> Node3D:
	var holder := Node3D.new()   # stands in for Unit._visual
	holder.position = p
	_world.add_child(holder)
	var m: Node3D = (load(SCENE) as PackedScene).instantiate()
	m.call(&"set_variant", variant)
	m.call(&"set_team_color", team)
	holder.add_child(m)
	return m


func _game_cam(z: float, focus: Vector3) -> void:
	_orbit(focus, z, 55.0, 0.0)


func _orbit(focus: Vector3, dist: float, pitch_deg: float, yaw_deg: float) -> void:
	var pitch := deg_to_rad(pitch_deg)
	var yaw := deg_to_rad(yaw_deg)
	_cam.position = focus + Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * dist
	_cam.look_at(focus, Vector3.UP)


func _wait(sec: float) -> void:
	await create_timer(sec).timeout


func _grab_crop(frac: float) -> Image:
	await create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	return _crop(root.get_texture().get_image(), frac)


## Centre crop: `frac` of the height, 4:5 aspect.
func _crop(img: Image, frac: float) -> Image:
	img.convert(Image.FORMAT_RGBA8)
	var h := int(img.get_height() * frac)
	var w := int(h * 0.8)
	return img.get_region(Rect2i((img.get_width() - w) / 2, (img.get_height() - h) / 2, w, h))


func _sheet(cells: Array[Image], cols: int, path: String) -> void:
	var cw := 360
	var ch := 450
	var rows := ceili(float(cells.size()) / cols)
	var out := Image.create(cw * cols, ch * rows, false, Image.FORMAT_RGBA8)
	out.fill(Color(0.1, 0.1, 0.1))
	for i: int in cells.size():
		var c := cells[i]
		c.resize(cw, ch, Image.INTERPOLATE_BILINEAR)
		out.blit_rect(c, Rect2i(0, 0, cw, ch), Vector2i((i % cols) * cw, (i / cols) * ch))
	out.save_png(path)
	print("saved ", path)


func _blacken(list: Array, black: Material) -> void:
	for m in list:
		for n: Node in (m as Node).find_children("*", "", true, false):
			if n is GPUParticles3D or n.name == &"Shadow" or n is Light3D:
				(n as Node3D).visible = false
			elif n is GeometryInstance3D:
				(n as GeometryInstance3D).material_override = black
				(n as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _two_zoom(focus: Vector3, near_z: float, nw: int, nh: int, fw: int, fh: int) -> Image:
	_game_cam(near_z, focus)
	await _wait(0.3)
	await RenderingServer.frame_post_draw
	var near := root.get_texture().get_image()
	_game_cam(40.0, focus)
	await _wait(0.3)
	await RenderingServer.frame_post_draw
	var far := root.get_texture().get_image()
	near.convert(Image.FORMAT_RGBA8)
	far.convert(Image.FORMAT_RGBA8)
	# near view on top, the 40 m view below (cropped, upscaled x2 nearest so the pixels stay honest)
	var top := near.get_region(Rect2i((near.get_width() - nw) / 2, (near.get_height() - nh) / 2 - 30, nw, nh))
	var bot := far.get_region(Rect2i((far.get_width() - fw) / 2, (far.get_height() - fh) / 2 - 8, fw, fh))
	bot.resize(fw * 2, fh * 2, Image.INTERPOLATE_NEAREST)
	var out := Image.create(maxi(nw, fw * 2), nh + fh * 2 + 12, false, Image.FORMAT_RGBA8)
	out.fill(Color.WHITE)
	out.blit_rect(top, Rect2i(0, 0, nw, nh), Vector2i((out.get_width() - nw) / 2, 0))
	out.fill_rect(Rect2i(0, nh + 4, out.get_width(), 3), Color(0.75, 0.75, 0.75))
	out.blit_rect(bot, Rect2i(0, 0, fw * 2, fh * 2), Vector2i((out.get_width() - fw * 2) / 2, nh + 12))
	return out


## Unlit black on white. Mender sheet: A front, B front, A side, B back-3/4 (zoom 12 above, 40 m below).
## Contact sheet: the four champion scenes that exist, each front + side, under the same camera.
func _silhouette() -> void:
	var white := StandardMaterial3D.new()
	white.albedo_color = Color.BLACK
	white.emission_enabled = true
	white.emission = Color.WHITE
	white.emission_energy_multiplier = 8.0
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	black.cull_mode = BaseMaterial3D.CULL_DISABLED
	var base := Vector3(0, 0, -90)
	var plane := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(200, 200)
	plane.mesh = pm
	plane.material_override = white
	plane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	plane.position = base + Vector3(0, 0.01, 0)
	_world.add_child(plane)
	_env.glow_enabled = false
	var sil: Array = []
	sil.append(_spawn(0, base + Vector3(-2.7, 0, 0), FIRE))
	sil.append(_spawn(1, base + Vector3(-0.9, 0, 0), FIRE))
	var s3 := _spawn(0, base + Vector3(0.9, 0, 0), FIRE)
	s3.get_parent().rotation.y = PI * 0.5
	var s4 := _spawn(1, base + Vector3(2.7, 0, 0), FIRE)
	s4.get_parent().rotation.y = PI * 0.8
	sil.append_array([s3, s4])
	await _wait(1.2)
	_blacken(sil, black)
	var img: Image = await _two_zoom(base + Vector3(0, 0.9, 0), 12.0, 1000, 560, 250, 140)
	img.save_png("res://docs/art/screens/champion_mender_silhouette.png")
	print("saved champion_mender_silhouette.png")
	for m in sil:
		(m as Node).get_parent().queue_free()

	# the four champions, same camera
	var row := base + Vector3(0, 0, -20)
	var ids: Array[String] = ["wayfinder", "oathwall", "coin_cutter", "mender"]
	var champs: Array = []
	var missing: PackedStringArray = []
	var k := 0
	for id: String in ids:
		var path := "res://art/units/champions/%s/%s.tscn" % [id, id]
		if not ResourceLoader.exists(path):
			missing.append(id)
			continue
		for side: int in 2:
			var holder := Node3D.new()
			holder.position = row + Vector3((k - 3.5) * 2.0, 0, 0)
			holder.rotation.y = 0.0 if side == 0 else PI * 0.5
			_world.add_child(holder)
			var m: Node3D = (load(path) as PackedScene).instantiate()
			if m.has_method(&"set_team_color"):
				m.call(&"set_team_color", FIRE)
			holder.add_child(m)
			champs.append(m)
			k += 1
	if not missing.is_empty():
		print("contact sheet: missing scenes ", missing)
	await _wait(1.2)
	_blacken(champs, black)
	var sheet: Image = await _two_zoom(row + Vector3(0, 0.9, 0), 15.0, 1500, 560, 520, 130)
	sheet.save_png("res://docs/art/screens/champions_silhouette.png")
	print("saved champions_silhouette.png (order: wayfinder, oathwall, coin_cutter, mender; front then side) missing=", missing)
	_env.glow_enabled = true
