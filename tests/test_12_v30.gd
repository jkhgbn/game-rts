extends SceneTree
## Task 12.V30: the Grizzlemaw epic beast model, both variants in one scene
## (art/units/neutral/beasts/grizzlemaw/grizzlemaw.tscn).
## Run: $GODOT --headless --path . -s tests/test_12_v30.gd --fixed-fps 60 --quit-after 3600
## Checks: headless instantiation (several instances: the first builds and caches the meshes), the hero budget of
## map-fill.md 10 for BOTH variants (<= 26 authored meshes, <= 16 draw instances, 0 lights; keep_separate <= 6),
## own materials only, one glow material shown at a time (amber eyes; red when enraged), sizes (hump ~2.15 m, ~3.3 m
## long, feet on the ground), set_variant (before / after _ready, back and forth: x1.15 scale, body_height 3.0, Elder
## materials streak / white muzzle / rust chain only on B, moss mostly on A, the same instances), set_team_color is a
## no-op, the kit hooks, walk (legs swing, paws fold), attack `claw_swipe` (alternating paws, raised in the windup,
## lunge at the 0.12 s strike, one strike each), cast `maul` (rears, right paw up, then down), cast `rending_roar`
## (rears up > 45 deg about the hips with the hind feet on the ground, jaw wide, breath burst, slam + dust, ends),
## the enrage look (set_enraged, play_cast(&"enrage"), and the owning unit's `beast:enrage` modifier polled), the
## sniff fidget, hit, death (rolls onto its side, eyes dark, not through the ground, death_finished within 1.3 s),
## revive resets. Prints "PASS 12.v30" or "FAIL 12.v30: <reasons>".

const TASK_ID := "12.v30"
const SCENE := "res://art/units/neutral/beasts/grizzlemaw/grizzlemaw.tscn"
const OWN_DIR := "res://art/units/neutral/beasts/grizzlemaw/"
const FAKE_UNIT_SRC := "extends Node3D\nvar enraged := false\nfunc has_modifier(id: StringName) -> bool:\n\treturn enraged and id == &\"beast:enrage\"\n"

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


func _spawn(at: Vector3, variant: int = -1, holder: Node3D = null) -> Node3D:
	if holder == null:
		holder = Node3D.new()
		_world.add_child(holder)
	holder.position = at
	var m: Node3D = (load(SCENE) as PackedScene).instantiate()
	if variant >= 0:
		m.call(&"set_variant", variant)      # before _ready: kept and applied then
	holder.add_child(m)
	return m


func _run() -> void:
	_check(ResourceLoader.exists(SCENE), "scene exists")
	var a := _spawn(Vector3(0, 0, 0))
	var b := _spawn(Vector3(8, 0, 0), 1)
	await _wait(0.2)
	_check(a is CharacterModel, "extends CharacterModel")
	for m: Node3D in [a, b]:
		m.set(&"fidget_every", 0.0)
	_check(int(a.call(&"get_variant")) == 0 and int(b.call(&"get_variant")) == 1, "variants 0 / 1 (set before _ready)")
	# ---- structure / budgets (both variants)
	var authored: int = int(a.call(&"authored_mesh_count"))
	print("authored meshes: ", authored)
	_check(authored >= 8 and authored <= 26, "authored meshes <= 26 (got %d)" % authored)
	for m: Node3D in [a, b]:
		var inst := _draw_instances(m)
		var verts := _vertices(m)
		var tris := _triangles(m)
		var lights := m.find_children("*", "Light3D", true, false).size()
		var sep := 0
		for g: Node in m.find_children("*", "MeshInstance3D", true, false):
			if g.has_meta(&"keep_separate"):
				sep += 1
		print("variant %d: draw instances %d, vertices %d, triangles %d, keep_separate %d, lights %d" % [
			int(m.call(&"get_variant")), inst, verts, tris, sep, lights])
		_check(inst <= 16, "draw instances <= 16 (got %d)" % inst)
		_check(verts <= 8000, "vertices <= 8000 (got %d)" % verts)
		_check(sep <= 6, "keep_separate <= 6 (got %d)" % sep)
		_check(lights == 0, "0 lights")
		for n: String in ["Root/Mount/Head/Jaw/JawMesh", "Root/Mount/LegFL/Lower/Paw", "Root/Mount/LegBR/Lower/Paw",
				"Fx/Dust", "Fx/Breath", "Shadow"]:
			_check(m.get_node_or_null(n) != null, "part %s on every instance" % n)
	var mats_a := _materials(a)
	var mats_b := _materials(b)
	var names_a := _names(mats_a)
	var names_b := _names(mats_b)
	print("A materials (%d): %s" % [names_a.size(), ", ".join(names_a)])
	print("B materials (%d): %s" % [names_b.size(), ", ".join(names_b)])
	for mat: Material in mats_a + mats_b:
		_check(mat.resource_path.begins_with(OWN_DIR), "own material only (%s)" % mat.resource_path)
	_check(names_a.size() >= 7 and names_a.size() <= 10, "A: 7-10 materials (got %d)" % names_a.size())
	for nm: String in ["grizzlemaw_elder_streak.tres", "grizzlemaw_elder_muzzle.tres", "grizzlemaw_rust.tres",
			"grizzlemaw_elder_fur.tres"]:
		_check(nm in names_b and not (nm in names_a), "%s on B only" % nm)
	_check("grizzlemaw_moss.tres" in names_a and "grizzlemaw_muzzle.tres" in names_a, "A: moss + tan muzzle")
	_check(_glows(mats_a) == ["grizzlemaw_eye_glow.tres"] and _glows(mats_b) == ["grizzlemaw_eye_glow.tres"],
		"one glow material shown: the amber eyes")
	var eg: ShaderMaterial = load(OWN_DIR + "materials/grizzlemaw_eye_glow.tres")
	var gc: Color = eg.get_shader_parameter(&"glow_color")
	_check(float(eg.get_shader_parameter(&"energy")) >= 2.5 and gc.r > 0.9 and gc.g > 0.4 and gc.b < 0.3,
		"amber eyes, energy >= 2.5")
	var moss_a := _area_of(a, "grizzlemaw_moss.tres")
	var moss_b := _area_of(b, "grizzlemaw_moss.tres")
	print("moss triangles A %d, B %d" % [moss_a, moss_b])
	_check(moss_a > moss_b * 2, "A carries the moss saddle, B only a little")
	# ---- sizes (rest pose, holder space: the Elder's x1.15 is included)
	var box_a := _aabb(a, a.get_parent())
	var box_b := _aabb(b, b.get_parent())
	var top_a := _top_of(a, "Root/Mount/Merged", "grizzlemaw_fur.tres")
	var top_b := _top_of(b, "Root/Mount/Merged", "grizzlemaw_elder_fur.tres")
	print("A AABB %s (w %.2f, h %.2f, l %.2f), hump top (fur) %.2f" % [box_a, box_a.size.x, box_a.size.y,
		box_a.size.z, top_a])
	print("B AABB %s (w %.2f, h %.2f, l %.2f), hump top (fur) %.2f" % [box_b, box_b.size.x, box_b.size.y,
		box_b.size.z, top_b])
	_check(top_a >= 2.05 and top_a <= 2.35, "shoulder hump ~2.2 m (got %.2f)" % top_a)
	_check(box_a.size.z >= 3.0 and box_a.size.z <= 3.8, "length ~3.3 m (got %.2f)" % box_a.size.z)
	_check(box_a.size.x >= 1.2 and box_a.size.x <= 1.9, "width 1.2-1.9 m (got %.2f)" % box_a.size.x)
	_check(top_b > top_a * 1.12 and box_b.size.z > box_a.size.z * 1.1, "the Elder is larger (x1.15)")
	for m: Node3D in [a, b]:
		var low := _lowest_vertex(m, [], [])
		_check(low >= -0.02 and low <= 0.03, "feet on the ground at rest (variant %d: %.3f)" % [
			int(m.call(&"get_variant")), low])
	_check(absf(float(b.get(&"body_height")) - 2.99) < 0.02 and absf(float(a.get(&"body_height")) - 2.6) < 0.01,
		"body_height 2.6 / 3.0 (the data files)")
	_check(b.scale.is_equal_approx(Vector3.ONE * 1.15) and a.scale.is_equal_approx(Vector3.ONE), "B scale x1.15")
	_check(a.get(&"attack_style") == &"claw_swipe" and float(a.get(&"attack_windup")) == 0.0, "attack claw_swipe, melee")
	_check(bool(a.get(&"is_quadruped")), "quadruped")
	# ---- set_variant after _ready swaps meshes on the same instances, and back
	var c := _spawn(Vector3(16, 0, 0))
	await _wait(0.1)
	c.set(&"fidget_every", 0.0)
	var inst_before := _draw_instances(c)
	var body_mi := c.get_node("Root/Mount/Merged") as MeshInstance3D
	var head_mi := c.get_node("Root/Mount/Head/Merged") as MeshInstance3D
	var mesh_a: Mesh = body_mi.mesh
	var head_a: Mesh = head_mi.mesh
	c.call(&"set_variant", 1)
	await process_frame
	_check(body_mi.mesh != mesh_a and head_mi.mesh != head_a, "set_variant(1) swaps the body and head meshes")
	_check(_draw_instances(c) == inst_before, "same draw instances after the swap")
	_check("grizzlemaw_rust.tres" in _names(_materials(c)), "set_variant(1): the chain appears")
	_check(c.scale.is_equal_approx(Vector3.ONE * 1.15), "set_variant(1): x1.15")
	c.call(&"set_variant", 0)
	await process_frame
	_check(body_mi.mesh == mesh_a and head_mi.mesh == head_a, "set_variant(0) swaps back")
	_check(not ("grizzlemaw_rust.tres" in _names(_materials(c))) and c.scale.is_equal_approx(Vector3.ONE),
		"set_variant(0): no chain, x1")
	c.get_parent().queue_free()
	# ---- team colour: none (neutral)
	var before := _materials(b)
	b.call(&"set_team_color", Color(0.42, 0.22, 0.60))
	await process_frame
	var after := _materials(b)
	_check(before.size() == after.size(), "set_team_color keeps the materials")
	for mat: Material in after:
		_check(mat in before, "set_team_color must not recolour %s" % mat.resource_path.get_file())
	# ---- hooks
	for m: Node3D in [a, b]:
		for h: String in ["set_team_color", "set_moving", "play_attack", "play_cast", "play_hit", "play_death",
				"play_level_up", "set_veterancy", "set_carrying", "play_mine", "set_status", "revive", "play_fidget",
				"set_variant", "set_enraged", "is_enraged"]:
			_check(m.has_method(h), "hook %s" % h)
		_check(m.has_signal(&"death_finished"), "signal death_finished")
	var root_n: Node3D = a.get_node("Root")
	var head: Node3D = a.get_node("Root/Mount/Head")
	var jaw: Node3D = a.get_node("Root/Mount/Head/Jaw")
	var leg_fl: Node3D = a.get_node("Root/Mount/LegFL")
	var leg_fr: Node3D = a.get_node("Root/Mount/LegFR")
	var low_fl: Node3D = a.get_node("Root/Mount/LegFL/Lower")
	await _wait(0.3)
	_check(float(a.call(&"eye_glow")) > 0.8, "the eyes glow (%.2f)" % float(a.call(&"eye_glow")))
	# walk: legs swing, paws fold
	a.call(&"set_moving", 5.0)
	var max_leg := 0.0
	var max_fold := 0.0
	for i: int in 60:
		await process_frame
		max_leg = maxf(max_leg, absf(leg_fl.rotation.x))
		max_fold = maxf(max_fold, low_fl.rotation.x)
	a.call(&"set_moving", 0.0)
	print("walk: max fore-leg swing %.1f deg, paw fold %.1f deg" % [rad_to_deg(max_leg), rad_to_deg(max_fold)])
	_check(max_leg > deg_to_rad(14.0), "the legs swing in the amble (%.1f deg)" % rad_to_deg(max_leg))
	_check(max_fold > deg_to_rad(30.0), "the paws fold back (%.1f deg)" % rad_to_deg(max_fold))
	await _wait(0.5)
	# attack: alternating paws
	var sides: Array = []
	for k: int in 2:
		var strikes0: int = int(a.call(&"strike_count"))
		a.call(&"play_attack")
		var s: float = float(a.call(&"swipe_side"))
		sides.append(s)
		await _until_t(a, 0.08)
		var paw_leg: Node3D = leg_fr if s > 0.0 else leg_fl
		var raised := paw_leg.rotation.x
		await _until_t(a, 0.125)
		var lunge := root_n.position.z
		print("swipe %d (side %+.0f): paw leg %.1f deg in the windup, lunge z %.2f" % [k, s, rad_to_deg(raised), lunge])
		_check(raised < deg_to_rad(-40.0), "swipe: the paw goes up in the windup (%.1f)" % rad_to_deg(raised))
		_check(lunge > 0.15, "swipe: lunge forward at the strike (%.2f)" % lunge)
		_check(int(a.call(&"strike_count")) == strikes0 + 1, "one strike per swipe")
		await _wait(0.8)
		_check(a.get(&"_action") == &"", "swipe finished")
	_check(sides.size() == 2 and float(sides[0]) == -float(sides[1]), "swipes alternate paws")
	await _wait(0.2)
	# maul
	a.call(&"play_cast", &"maul")
	await _until_t(a, 0.09)
	var m_pitch := root_n.rotation.x
	var m_leg := leg_fr.rotation.x
	await _until_t(a, 0.17)
	var m_leg2 := leg_fr.rotation.x
	print("maul: pitch %.1f, right leg %.1f -> %.1f, mauls %d" % [rad_to_deg(m_pitch), rad_to_deg(m_leg),
		rad_to_deg(m_leg2), int(a.call(&"maul_count"))])
	_check(m_pitch < deg_to_rad(-15.0), "maul: rears")
	_check(m_leg < deg_to_rad(-60.0) and m_leg2 > deg_to_rad(-10.0), "maul: right paw up then crashing down")
	_check(int(a.call(&"maul_count")) == 1, "maul: one heavy strike")
	await _wait(1.0)
	_check(a.get(&"_action") == &"", "maul finished")
	await _wait(0.2)
	# rending roar
	var breath0: int = int(a.call(&"breath_count"))
	var dust0: int = int(a.call(&"dust_count"))
	a.call(&"play_cast", &"rending_roar")
	await _until_t(a, 0.6)
	var r_pitch := root_n.rotation.x
	var head_y := head.global_position.y
	var jaw_open := jaw.rotation.x
	var hind_low := _lowest_vertex(a, ["Paw"], ["Root/Mount/LegFL", "Root/Mount/LegFR"])
	var top_now := _aabb(a, a.get_parent()).end.y
	print("roar 0.6 s: pitch %.1f, head y %.2f, jaw %.1f, hind paws lowest %.3f, top %.2f, breath %d" % [
		rad_to_deg(r_pitch), head_y, rad_to_deg(jaw_open), hind_low, top_now, int(a.call(&"breath_count"))])
	_check(r_pitch < deg_to_rad(-45.0), "roar: rears up on the hind legs")
	_check(top_now > 3.3, "roar: towers over 3.3 m (%.2f)" % top_now)
	_check(jaw_open > deg_to_rad(30.0), "roar: jaw wide open")
	_check(hind_low > -0.15 and hind_low < 0.3, "roar: hind feet stay on the ground (%.3f)" % hind_low)
	_check(int(a.call(&"breath_count")) == breath0 + 1 and int(a.call(&"roar_count")) == 1, "roar: one breath burst")
	await _until_t(a, 1.3)
	print("roar 1.3 s: pitch %.1f, slams %d, dust %d" % [rad_to_deg(root_n.rotation.x), int(a.call(&"slam_count")),
		int(a.call(&"dust_count"))])
	_check(int(a.call(&"slam_count")) == 1 and int(a.call(&"dust_count")) == dust0 + 1, "roar: slam + dust")
	_check(root_n.rotation.x > deg_to_rad(-10.0), "roar: back on all fours after the slam")
	await _wait(0.8)
	_check(a.get(&"_action") == &"", "roar finished")
	# ---- enrage: hook, cast id, and the owning unit's modifier
	var eye0 := float(a.call(&"eye_glow"))
	a.call(&"set_enraged", true)
	await _wait(0.6)
	var mats_r := _materials(a)
	print("enraged: glows %s, eye %.2f (calm %.2f)" % [_glows(mats_r), float(a.call(&"eye_glow")), eye0])
	_check(_glows(mats_r) == ["grizzlemaw_eye_rage.tres"], "enraged: red eyes (mesh swap)")
	_check(float(a.call(&"eye_glow")) > eye0 * 1.2, "enraged: brighter eyes")
	_check(jaw.rotation.x > deg_to_rad(5.0), "enraged: snarl (jaw ajar)")
	a.call(&"set_enraged", false)
	await _wait(0.1)
	_check(_glows(_materials(a)) == ["grizzlemaw_eye_glow.tres"], "calm again: amber eyes")
	b.call(&"play_cast", &"enrage")
	await _wait(0.1)
	_check(bool(b.call(&"is_enraged")), "play_cast(&\"enrage\") turns the enrage look on")
	await _wait(1.0)
	_check(b.get(&"_action") == &"", "snarl finished")
	b.call(&"set_enraged", false)
	var script := GDScript.new()
	script.source_code = FAKE_UNIT_SRC
	script.reload()
	var unit := Node3D.new()
	unit.set_script(script)
	_world.add_child(unit)
	var visual := Node3D.new()
	unit.add_child(visual)
	var u := _spawn(Vector3(-8, 0, 0), 1, visual)   # model under Unit/_visual as in the game
	await _wait(0.3)
	_check(not bool(u.call(&"is_enraged")), "unit modifier off: calm")
	unit.set(&"enraged", true)
	await _wait(1.2)
	_check(bool(u.call(&"is_enraged")), "unit modifier beast:enrage on: enraged (polled)")
	unit.set(&"enraged", false)
	await _wait(1.2)
	_check(not bool(u.call(&"is_enraged")), "unit modifier off again: calm")
	unit.queue_free()
	# ---- fidget
	a.call(&"play_fidget")
	await _wait(0.9)
	print("fidget: pitch %.1f" % rad_to_deg(root_n.rotation.x))
	_check(a.get(&"_action") == &"fidget" and root_n.rotation.x < deg_to_rad(-30.0), "fidget: stands up to sniff")
	a.call(&"set_moving", 3.0)
	await _wait(0.1)
	_check(a.get(&"_action") == &"", "moving cancels the fidget")
	a.call(&"set_moving", 0.0)
	await _wait(0.5)
	# hit
	a.call(&"play_hit")
	await _wait(0.1)
	print("hit: jaw %.1f, neck %.1f" % [rad_to_deg(jaw.rotation.x), rad_to_deg(head.rotation.x)])
	_check(jaw.rotation.x > deg_to_rad(8.0), "hit: the jaw snaps open")
	a.call(&"play_level_up")
	_check(bool(a.call(&"set_status", &"haste", true)), "set_status haste handled")
	_check(not bool(a.call(&"set_status", &"rooted", true)), "set_status rooted left to the placeholder")
	a.call(&"set_status", &"haste", false)
	a.call(&"set_veterancy", 2)
	a.call(&"set_carrying", true)
	a.call(&"play_mine")
	await _wait(0.5)
	a.call(&"set_carrying", false)
	a.call(&"set_veterancy", 0)
	await _wait(0.3)
	# ---- death mid-attack + revive (both variants)
	for m: Node3D in [a, b]:
		m.call(&"play_attack")
		await _wait(0.1)
		var got: Array = [false]
		m.connect(&"death_finished", func() -> void: got[0] = true, CONNECT_ONE_SHOT)
		var dust1: int = int(m.call(&"dust_count"))
		m.call(&"play_death")
		await _until_death(m, 0.78)
		var rn: Node3D = m.get_node("Root")
		var low_body := _lowest_vertex(m, ["Merged"], [])
		var low_all := _lowest_vertex(m, [], [])
		print("death v%d 0.78 s: roll %.1f, root y %.2f, eyes %.2f, lowest body %.3f, lowest all %.3f" % [
			int(m.call(&"get_variant")), rad_to_deg(rn.rotation.z), rn.position.y, float(m.call(&"eye_glow")),
			low_body, low_all])
		_check(absf(rn.rotation.z) > deg_to_rad(60.0), "rolls onto its side")
		_check(float(m.call(&"eye_glow")) == 0.0, "eyes dark once dead")
		_check(int(m.call(&"dust_count")) > dust1, "dust when it lands")
		_check(low_body > -0.2 and low_body < 0.35, "lying on the ground, not through it (lowest body %.3f)" % low_body)
		_check(low_all > -0.35, "nothing digs deep into the ground (%.3f)" % low_all)
		await _wait(0.6)
		_check(got[0], "death_finished emitted within 1.3 s")
		m.call(&"revive")
		await _wait(0.3)
		_check(absf(rn.rotation.x) < 0.05 and absf(rn.rotation.z) < 0.05 and absf(rn.position.y) < 0.08,
			"revive resets the pose")
		_check(float(m.call(&"eye_glow")) > 0.5 and not bool(m.call(&"is_enraged")), "revive: eyes back, calm")
	# ---- transparency (Unit.leave_map fade / shroud) is tolerated on every part
	for g: Node in b.find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).transparency = 0.5
	await _wait(0.1)
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


## Waits (max 2.5 s) until the model's action clock reaches t (headless: no camera, tier 1, half rate).
func _until_t(m: Node, t: float) -> void:
	for i: int in 150:
		if float(m.get(&"_action_t")) >= t:
			return
		await process_frame


func _until_death(m: Node, t: float) -> void:
	for i: int in 90:
		if float(m.get(&"_death_t")) >= t:
			return
		await process_frame


## Lowest vertex (holder space) of the meshes whose node name is in `names` (empty = all), skipping the blob and any
## mesh under a path in `skip`.
func _lowest_vertex(model: Node3D, names: Array, skip: Array) -> float:
	var inv := (model.get_parent() as Node3D).global_transform.affine_inverse()
	var low := INF
	for g: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow":
			continue
		if not names.is_empty() and not (String(mi.name) in names):
			continue
		var path := String(model.get_path_to(mi))
		var skipped := false
		for s: String in skip:
			if path.begins_with(s):
				skipped = true
		if skipped:
			continue
		var xf := inv * mi.global_transform
		for s: int in mi.mesh.get_surface_count():
			for v: Vector3 in (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				low = minf(low, (xf * v).y)
	return low


func _top_of(model: Node3D, path: String, mat_file: String) -> float:
	var mi := model.get_node(path) as MeshInstance3D
	var xf := (model.get_parent() as Node3D).global_transform.affine_inverse() * mi.global_transform
	var top := -INF
	for s: int in mi.mesh.get_surface_count():
		if mi.mesh.surface_get_material(s).resource_path.get_file() != mat_file:
			continue
		for v: Vector3 in (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
			top = maxf(top, (xf * v).y)
	return top


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


## Triangles drawn with the material file `file` on the model.
func _area_of(n: Node, file: String) -> int:
	var c := 0
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mesh := (g as MeshInstance3D).mesh
		if mesh == null or g.name == "Shadow":
			continue
		for s: int in mesh.get_surface_count():
			var mat := mesh.surface_get_material(s)
			if mat and mat.resource_path.get_file() == file:
				c += (mesh.surface_get_arrays(s)[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
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


func _names(mats: Array) -> PackedStringArray:
	var out := PackedStringArray()
	for m: Material in mats:
		out.append(m.resource_path.get_file())
	return out


func _glows(mats: Array) -> Array:
	var out: Array = []
	for m: Material in mats:
		var sm := m as ShaderMaterial
		if sm and sm.shader and sm.shader.resource_path.ends_with("unit_glow.gdshader"):
			out.append(m.resource_path.get_file())
	return out


func _aabb(n: Node, space: Node3D) -> AABB:
	var inv := space.global_transform.affine_inverse()
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
