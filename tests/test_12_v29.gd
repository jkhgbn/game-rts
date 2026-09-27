extends SceneTree
## Task 12.V29: the Direwolf epic beast model, both variants in one scene (art/units/neutral/beasts/direwolf/).
## Run: $GODOT --headless --path . -s tests/test_12_v29.gd --fixed-fps 60 --quit-after 3000
## Checks: headless instantiation (A, B set after ready, B set before entering the tree), hero budget of map-fill.md 10
## (<= 26 authored meshes, <= 16 draw instances, 0 lights, vertices <= 4 500) for both variants, materials (own only;
## A: 0 glow, B: exactly 1 pale-blue unit_glow = the eyes), A grey vs B silver-white (value gap), B leaner and without
## the big mane, horse-sized (withers ~1.65 m, ears ~2.1 m, ~3.4 m long), clearly bigger than the Grave Hound, set_variant swaps both ways
## (the same nodes, other meshes), the data .tres point at the scene, set_team_color is a no-op, the kit hooks, trot vs
## gallop, attack `hamstring_bite` (head low and jaws open in the windup, lunge + snap at 0.12 s, one strike per attack,
## a sideways rip), cast `pounce` (crouch, leap arc ~0.85 m, jaws wide in the air, one pinning bite, B eyes flare, ends),
## the howl fidget, hit, death (topples, eyes dark, not through the ground, death_finished within 1.3 s), revive resets.
## Prints "PASS 12.v29" or "FAIL 12.v29: <reasons>".

const TASK_ID := "12.v29"
const SCENE := "res://art/units/neutral/beasts/direwolf/direwolf.tscn"
const OWN_DIR := "res://art/units/neutral/beasts/direwolf/"
const HOUND := "res://art/units/shadow/grave_hound.tscn"
const DATA: Array[String] = ["res://data/units/greymane_direwolf.tres", "res://data/units/moonpelt_direwolf.tres"]

var _fails: PackedStringArray = PackedStringArray()
var _world: Node3D


func _initialize() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	_run()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAILED: ", what)


func _wait(sec: float) -> void:
	var n := int(ceil(sec * 60.0))
	for i: int in n:
		await process_frame


func _spawn(path: String, at: Vector3, variant: int = -1) -> Node3D:
	var holder := Node3D.new()
	holder.position = at
	_world.add_child(holder)
	var m: Node3D = (load(path) as PackedScene).instantiate()
	if variant >= 0 and m.has_method(&"set_variant"):
		m.call(&"set_variant", variant)
	holder.add_child(m)
	return m


func _run() -> void:
	_check(ResourceLoader.exists(SCENE), "scene exists")
	var a := _spawn(SCENE, Vector3(0, 0, 0))
	var b := _spawn(SCENE, Vector3(6, 0, 0))
	var c := _spawn(SCENE, Vector3(12, 0, 0), 1)      # variant set before _ready
	await _wait(0.2)
	b.call(&"set_variant", 1)                           # variant set after _ready
	await _wait(0.1)
	_check(a is CharacterModel, "extends CharacterModel")
	for m: Node3D in [a, b, c]:
		m.set(&"fidget_every", 0.0)
	_check(int(a.call(&"get_variant")) == 0 and int(b.call(&"get_variant")) == 1 and int(c.call(&"get_variant")) == 1,
		"get_variant")
	# ---- data points at the scene
	for p: String in DATA:
		if ResourceLoader.exists(p):
			var ut: Resource = load(p)
			_check(String(ut.get(&"model_path")) == SCENE, "%s model_path -> the direwolf scene" % p.get_file())
		else:
			_check(false, "%s exists" % p)
	# ---- structure / budgets
	var authored: int = int(a.call(&"authored_mesh_count"))
	print("authored meshes: ", authored)
	_check(authored >= 10 and authored <= 26, "authored meshes <= 26 (got %d)" % authored)
	for m: Node3D in [a, b, c]:
		var inst := _draw_instances(m)
		var verts := _vertices(m)
		var tris := _triangles(m)
		var lights := m.find_children("*", "Light3D", true, false).size()
		print("%s (variant %d): draw instances %d, vertices %d, triangles %d, lights %d" % [m.name,
			int(m.call(&"get_variant")), inst, verts, tris, lights])
		_check(inst <= 16, "draw instances <= 16 (got %d)" % inst)
		_check(verts <= 4500, "vertices <= 4500 (got %d)" % verts)
		_check(lights == 0, "0 lights")
	for n: String in ["Root/Mount/Body", "Root/Mount/Head/Neck", "Root/Mount/Head/Skull/Cranium",
			"Root/Mount/Head/Skull/Jaw/Mandible", "Root/Mount/Tail/Brush", "Root/Mount/LegFL/Thigh",
			"Root/Mount/LegBR/Lower/Shin"]:
		for m: Node3D in [a, b, c]:
			_check(m.get_node_or_null(n) != null, "part %s on every instance" % n)
	# ---- materials per variant
	var mats_a := _materials(a)
	var mats_b := _materials(b)
	var mats_c := _materials(c)
	for pair: Array in [["A", mats_a], ["B", mats_b]]:
		var own: Array = []
		var foreign: Array = []
		for mat: Material in pair[1]:
			if mat.resource_path.begins_with(OWN_DIR):
				own.append(mat.resource_path.get_file())
			else:
				foreign.append(mat.resource_path if mat.resource_path != "" else "<built-in>")
		print("%s materials (%d): %s" % [pair[0], own.size(), ", ".join(PackedStringArray(own))])
		_check(foreign.is_empty(), "%s: only own materials (%s)" % [pair[0], ", ".join(PackedStringArray(foreign))])
		_check(own.size() >= 5 and own.size() <= 8, "%s: 5-8 materials (got %d)" % [pair[0], own.size()])
	_check(_same_set(mats_b, mats_c), "B set before / after ready gives the same materials")
	var glows_a := _glows(mats_a)
	var glows_b := _glows(mats_b)
	_check(glows_a.is_empty(), "Greymane: no glow material (got %d)" % glows_a.size())
	_check(glows_b.size() == 1, "Moonpelt: exactly 1 glow material = the eyes (got %d)" % glows_b.size())
	if glows_b.size() == 1:
		var gm: ShaderMaterial = glows_b[0]
		var gc: Color = gm.get_shader_parameter(&"glow_color")
		var en: float = float(gm.get_shader_parameter(&"energy"))
		print("B eye glow %s energy %.2f" % [gc, en])
		_check(gc.b > 0.9 and gc.b > gc.r + 0.25 and en >= 2.0 and en <= 3.2, "B: pale-blue eyes, faint (energy 2-3.2)")
	var fa: Color = (load(OWN_DIR + "materials/direwolf_fur_a.tres") as ShaderMaterial).get_shader_parameter(&"base_color")
	var fb: Color = (load(OWN_DIR + "materials/direwolf_fur_b.tres") as ShaderMaterial).get_shader_parameter(&"base_color")
	var ma: Color = (load(OWN_DIR + "materials/direwolf_mane_a.tres") as ShaderMaterial).get_shader_parameter(&"base_color")
	print("fur A %s (v %.2f s %.2f), fur B %s (v %.2f s %.2f), mane A v %.2f" % [fa, fa.v, fa.s, fb, fb.v, fb.s, ma.v])
	_check(fa.s < 0.15 and fa.v > 0.35 and fa.v < 0.6, "A: a grey coat")
	_check(fb.s < 0.15 and fb.v > 0.78, "B: a silver-white coat")
	_check(fb.v - fa.v > 0.3, "A / B coat values far apart (readable at 40 m)")
	_check(ma.v < fa.v - 0.15, "A: the mane darker than the coat")
	# ---- size (rest pose, Root frame), A vs B, the Grave Hound
	var box_a := _aabb(a, a.get_node("Root"))
	var box_b := _aabb(b, b.get_node("Root"))
	print("A AABB x %.2f..%.2f y %.2f..%.2f z %.2f..%.2f" % [box_a.position.x, box_a.end.x, box_a.position.y,
		box_a.end.y, box_a.position.z, box_a.end.z])
	print("B AABB x %.2f..%.2f y %.2f..%.2f z %.2f..%.2f" % [box_b.position.x, box_b.end.x, box_b.position.y,
		box_b.end.y, box_b.position.z, box_b.end.z])
	_check(box_a.position.y >= -0.005 and box_b.position.y >= -0.005, "nothing below y 0")
	_check(box_a.end.y >= 1.9 and box_a.end.y <= 2.4, "ear tips 1.9-2.4 m (got %.2f)" % box_a.end.y)
	_check(box_a.size.z >= 3.0 and box_a.size.z <= 3.9, "length 3.0-3.9 m (got %.2f)" % box_a.size.z)
	var body_a := _aabb_node(a.get_node("Root/Mount/Body") as MeshInstance3D, a.get_node("Root"))
	var body_b := _aabb_node(b.get_node("Root/Mount/Body") as MeshInstance3D, b.get_node("Root"))
	var neck_a := _aabb_node(a.get_node("Root/Mount/Head/Neck") as MeshInstance3D, a.get_node("Root"))
	var neck_b := _aabb_node(b.get_node("Root/Mount/Head/Neck") as MeshInstance3D, b.get_node("Root"))
	print("body width A %.2f B %.2f, withers A %.2f B %.2f; neck/mane width A %.2f B %.2f, top A %.2f B %.2f" % [
		body_a.size.x, body_b.size.x, body_a.end.y, body_b.end.y, neck_a.size.x, neck_b.size.x, neck_a.end.y,
		neck_b.end.y])
	_check(body_b.size.x < body_a.size.x * 0.9, "B leaner than A")
	_check(neck_a.size.x > neck_b.size.x * 1.35, "A's mane much wider than B's collar")
	_check(body_a.end.y > 1.7 and body_a.end.y < 2.2, "A withers hump 1.7-2.2 m (got %.2f)" % body_a.end.y)
	if ResourceLoader.exists(HOUND):
		var h := _spawn(HOUND, Vector3(-6, 0, 0))
		await _wait(0.1)
		var hb := _aabb(h, h)
		print("grave hound AABB h %.2f l %.2f" % [hb.size.y, hb.size.z])
		_check(box_a.size.y > hb.size.y * 1.4 and box_a.size.z > hb.size.z * 1.4, "much bigger than the Grave Hound")
		h.get_parent().queue_free()
	_check(a.get(&"attack_style") == &"hamstring_bite" and float(a.get(&"attack_windup")) == 0.0,
		"attack hamstring_bite, melee")
	_check(bool(a.get(&"is_quadruped")), "quadruped")
	_check(absf(float(a.get(&"body_height")) - 1.8) < 0.01, "body_height 1.8 (data)")
	# ---- variant swap back and forth: the same nodes, other meshes
	var body_node: MeshInstance3D = b.get_node("Root/Mount/Body")
	var mesh_b := body_node.mesh
	b.call(&"set_variant", 0)
	await process_frame
	_check(body_node.mesh != mesh_b and _same_set(_materials(b), mats_a), "set_variant(0) swaps B back to A")
	_check(float(b.call(&"eye_glow")) == 0.0, "A: eyes not glowing")
	b.call(&"set_variant", 1)
	await process_frame
	_check(body_node.mesh == mesh_b and _same_set(_materials(b), mats_b), "set_variant(1) swaps to B again")
	_check(float(b.call(&"eye_glow")) > 0.8, "B: eyes glow (%.2f)" % float(b.call(&"eye_glow")))
	# ---- team colour: none (neutral)
	var before := _materials(b)
	b.call(&"set_team_color", Color(0.42, 0.22, 0.60))
	await process_frame
	_check(_same_set(before, _materials(b)), "set_team_color keeps the materials")
	# ---- hooks
	for m: Node3D in [a, b]:
		for hk: String in ["set_team_color", "set_moving", "play_attack", "play_cast", "play_hit", "play_death",
				"play_level_up", "set_veterancy", "set_carrying", "play_mine", "set_status", "revive", "play_fidget",
				"set_variant", "get_variant"]:
			_check(m.has_method(hk), "hook %s" % hk)
		_check(m.has_signal(&"death_finished"), "signal death_finished")
	var root_n: Node3D = b.get_node("Root")
	var head: Node3D = b.get_node("Root/Mount/Head")
	var skull: Node3D = b.get_node("Root/Mount/Head/Skull")
	var tail: Node3D = b.get_node("Root/Mount/Tail")
	var fl: Node3D = b.get_node("Root/Mount/LegFL")
	var fr: Node3D = b.get_node("Root/Mount/LegFR")
	var br: Node3D = b.get_node("Root/Mount/LegBR")
	var shin: Node3D = b.get_node("Root/Mount/LegFL/Lower")
	# ---- gaits: trot at patrol speed (FL with BR, against FR), gallop at fight speed (FL with FR)
	b.call(&"set_moving", 4.2)
	await _wait(0.4)
	var trot := await _corr(fl, fr, br)
	b.call(&"set_moving", 7.0)
	await _wait(0.4)
	var gallop := await _corr(fl, fr, br)
	var max_fold := 0.0
	var tail_up := 0.0
	for i: int in 40:
		await process_frame
		max_fold = maxf(max_fold, shin.rotation.x)
		tail_up = maxf(tail_up, tail.rotation.x)
	b.call(&"set_moving", 0.0)
	print("trot: FL~FR %.2f FL~BR %.2f; gallop: FL~FR %.2f; fold %.1f deg, tail %.1f deg" % [trot.x, trot.y, gallop.x,
		rad_to_deg(max_fold), rad_to_deg(tail_up)])
	_check(trot.x < -0.5 and trot.y > 0.5, "trot: diagonal pairs")
	_check(gallop.x > 0.4, "gallop: the fronts move together")
	_check(max_fold > deg_to_rad(30.0), "the front paws fold back in the swing")
	_check(tail_up > deg_to_rad(20.0), "the tail streams out in the gallop")
	await _wait(0.5)
	# ---- attack: head low + jaws open in the windup, lunge + snap at the strike, a rip sideways
	var strikes0: int = int(b.call(&"strike_count"))
	b.call(&"play_attack")
	await _until_t(b, 0.065)
	var hx_wind := head.rotation.x
	var jaw_wind := float(b.call(&"jaw_open"))
	await _until_t(b, 0.125)
	var rz_hit := root_n.position.z
	var jaw_hit := float(b.call(&"jaw_open"))
	await _until_t(b, 0.22)
	var hy_rip := head.rotation.y
	print("bite: neck windup %.1f, jaw %.1f -> %.1f, lunge z %.2f, rip yaw %.1f" % [rad_to_deg(hx_wind), jaw_wind,
		jaw_hit, rz_hit, rad_to_deg(hy_rip)])
	_check(hx_wind > deg_to_rad(15.0) and jaw_wind > 25.0, "head low, jaws open in the windup")
	_check(rz_hit > 0.2 and jaw_hit < 12.0, "lunge + snap at the strike")
	_check(hy_rip < deg_to_rad(-15.0), "the rip: head yanked sideways")
	_check(int(b.call(&"strike_count")) == strikes0 + 1, "one strike per attack")
	await _wait(0.6)
	_check(b.get(&"_action") == &"", "attack finished")
	await _wait(0.3)
	# ---- pounce
	var p0: int = int(b.call(&"pounce_count"))
	b.call(&"play_cast", &"pounce")
	await _until_t(b, 0.05)
	var ry_crouch := root_n.position.y
	await _until_t(b, 0.26)
	var ry_peak := root_n.position.y
	var jaw_air := float(b.call(&"jaw_open"))
	var fl_reach := fl.rotation.x
	await _until_t(b, 0.58)
	var flare := float(b.call(&"glow_flare"))
	var eye := float(b.call(&"eye_glow"))
	print("pounce: crouch y %.2f, peak y %.2f, jaw %.1f, fore legs %.1f, flare %.2f, eye %.2f, pounces %d -> %d" % [
		ry_crouch, ry_peak, jaw_air, rad_to_deg(fl_reach), flare, eye, p0, int(b.call(&"pounce_count"))])
	_check(ry_crouch < -0.06, "pounce: the crouch")
	_check(ry_peak > 0.6, "pounce: the leap arc")
	_check(jaw_air > 25.0 and fl_reach < deg_to_rad(-30.0), "pounce: jaws wide, fore legs reaching")
	_check(int(b.call(&"pounce_count")) == p0 + 1, "pounce: one pinning bite")
	_check(flare > 0.8 and eye > 1.5, "pounce: B's eyes flare")
	await _wait(0.6)
	_check(b.get(&"_action") == &"", "cast finished")
	await _wait(0.3)
	# ---- howl fidget
	var h0: int = int(b.call(&"howl_count"))
	b.call(&"play_fidget")
	await _wait(1.0)
	print("howl: neck %.1f, skull %.1f, jaw %.1f" % [rad_to_deg(head.rotation.x), rad_to_deg(skull.rotation.x),
		float(b.call(&"jaw_open"))])
	_check(b.get(&"_action") == &"fidget", "howl plays")
	_check(head.rotation.x < deg_to_rad(-20.0) and float(b.call(&"jaw_open")) > 15.0, "howl: head thrown back, jaws open")
	_check(int(b.call(&"howl_count")) == h0 + 1, "howl counted")
	b.call(&"set_moving", 3.0)
	await _wait(0.1)
	_check(b.get(&"_action") == &"", "moving cancels the howl")
	b.call(&"set_moving", 0.0)
	await _wait(0.4)
	# ---- hit
	b.call(&"play_hit")
	await _wait(0.1)
	print("hit: neck %.1f, tail %.1f, jaw %.1f" % [rad_to_deg(head.rotation.x), rad_to_deg(tail.rotation.x),
		float(b.call(&"jaw_open"))])
	_check(head.rotation.x < deg_to_rad(-3.0) and tail.rotation.x < 0.0, "hit: head jerks up, tail tucks")
	b.call(&"play_level_up")
	_check(bool(b.call(&"set_status", &"haste", true)), "set_status haste handled")
	_check(not bool(b.call(&"set_status", &"rooted", true)), "set_status rooted left to the placeholder")
	b.call(&"set_status", &"haste", false)
	b.call(&"set_veterancy", 2)
	b.call(&"set_carrying", true)
	b.call(&"play_mine")
	await _wait(0.5)
	b.call(&"set_carrying", false)
	b.call(&"set_veterancy", 0)
	await _wait(0.3)
	# ---- death mid-attack + revive (both variants)
	for m: Node3D in [a, b]:
		m.call(&"play_attack")
		await _wait(0.1)
		var got: Array = [false]
		m.connect(&"death_finished", func() -> void: got[0] = true, CONNECT_ONE_SHOT)
		m.call(&"play_death")
		await _until_death(m, 0.76)
		var rn: Node3D = m.get_node("Root")
		var low := _lowest_vertex(m)
		print("death %d at 0.76 s: root roll %.1f deg, root y %.2f, eye %.2f, lowest %.3f" % [int(m.call(&"get_variant")),
			rad_to_deg(rn.rotation.z), rn.position.y, float(m.call(&"eye_glow")), low])
		_check(absf(rn.rotation.z) > deg_to_rad(55.0), "topples onto its side")
		_check(float(m.call(&"eye_glow")) == 0.0, "eyes dark once dead")
		_check(low > -0.14 and low < 0.25, "lying on the ground, not through it (lowest %.3f)" % low)
		await _wait(0.6)
		_check(got[0], "death_finished emitted within 1.3 s")
		m.call(&"revive")
		await _wait(0.3)
		_check(absf(rn.rotation.x) < 0.05 and absf(rn.rotation.z) < 0.05 and absf(rn.position.y) < 0.06,
			"revive resets the pose")
	_check(float(b.call(&"eye_glow")) > 0.5, "revive: B eyes glow again")
	# ---- transparency (Unit.leave_map fade / shroud) is tolerated on every part
	for g: Node in c.find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).transparency = 0.5
	await _wait(0.1)
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


## Correlation of the FL leg swing with FR (x) and with BR (y) over ~1.2 s.
func _corr(fl: Node3D, fr: Node3D, br: Node3D) -> Vector2:
	var a: Array[float] = []
	var b: Array[float] = []
	var c: Array[float] = []
	for i: int in 72:
		await process_frame
		a.append(fl.rotation.x)
		b.append(fr.rotation.x)
		c.append(br.rotation.x)
	return Vector2(_pearson(a, b), _pearson(a, c))


func _pearson(x: Array[float], y: Array[float]) -> float:
	var n := float(x.size())
	var mx := 0.0
	var my := 0.0
	for i: int in x.size():
		mx += x[i]
		my += y[i]
	mx /= n
	my /= n
	var sxy := 0.0
	var sxx := 0.0
	var syy := 0.0
	for i: int in x.size():
		sxy += (x[i] - mx) * (y[i] - my)
		sxx += (x[i] - mx) * (x[i] - mx)
		syy += (y[i] - my) * (y[i] - my)
	return sxy / maxf(sqrt(sxx * syy), 1e-9)


## Waits (max 1 s) until the model's action clock reaches t (the headless run has no camera: tier 1, half rate).
func _until_t(m: Node, t: float) -> void:
	for i: int in 60:
		if float(m.get(&"_action_t")) >= t:
			return
		await process_frame


func _until_death(m: Node, t: float) -> void:
	for i: int in 90:
		if float(m.get(&"_death_t")) >= t:
			return
		await process_frame


## Lowest vertex (model space) of every mesh but the blob.
func _lowest_vertex(model: Node3D) -> float:
	var inv := model.global_transform.affine_inverse()
	var low := INF
	var who := ""
	for g: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow":
			continue
		var xf := inv * mi.global_transform
		for s: int in mi.mesh.get_surface_count():
			for v: Vector3 in (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				var y := (xf * v).y
				if y < low:
					low = y
					who = String(model.get_path_to(mi))
	print("  lowest vertex: %s %.3f" % [who, low])
	return low


func _draw_instances(n: Node) -> int:
	var c := 0
	for g: Node in n.find_children("*", "GeometryInstance3D", true, false):
		if g is MeshInstance3D and (g as MeshInstance3D).mesh == null:
			continue
		c += 1
	return c


func _vertices(n: Node) -> int:
	var c := 0
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mesh := (g as MeshInstance3D).mesh
		if mesh:
			for s: int in mesh.get_surface_count():
				c += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return c


func _triangles(n: Node) -> int:
	var c := 0
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mesh := (g as MeshInstance3D).mesh
		if mesh:
			for s: int in mesh.get_surface_count():
				var arr := mesh.surface_get_arrays(s)
				if arr[Mesh.ARRAY_INDEX] != null and (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() > 0:
					c += (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
				else:
					c += (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return c


## Unique materials on the model's meshes (surface overrides > material_override > mesh surfaces); the blob skipped.
func _materials(n: Node) -> Array:
	var out: Array = []
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow":
			continue
		if mi.material_override:
			if not (mi.material_override in out):
				out.append(mi.material_override)
			continue
		for s: int in mi.mesh.get_surface_count():
			var mat := mi.get_surface_override_material(s)
			if mat == null:
				mat = mi.mesh.surface_get_material(s)
			if mat and not (mat in out):
				out.append(mat)
	return out


func _same_set(x: Array, y: Array) -> bool:
	if x.size() != y.size():
		return false
	for m in x:
		if not (m in y):
			return false
	return true


func _glows(mats: Array) -> Array:
	var out: Array = []
	for mat: Material in mats:
		var sm := mat as ShaderMaterial
		if sm and sm.shader and sm.shader.resource_path.ends_with("unit_glow.gdshader"):
			out.append(sm)
	return out


func _aabb(n: Node, model: Node3D) -> AABB:
	var inv := model.global_transform.affine_inverse()
	var box := AABB()
	var first := true
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow":
			continue
		var bx := (inv * mi.global_transform) * mi.mesh.get_aabb()
		box = bx if first else box.merge(bx)
		first = false
	return box


func _aabb_node(mi: MeshInstance3D, model: Node3D) -> AABB:
	return (model.global_transform.affine_inverse() * mi.global_transform) * mi.mesh.get_aabb()
