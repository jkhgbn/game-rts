extends SceneTree
## Task 12.V27: the Tusker epic beast model, both variants in one scene (art/units/neutral/beasts/tusker/tusker.tscn).
## Run: $GODOT --headless --path . -s tests/test_12_v27.gd --fixed-fps 60 --quit-after 3000
## Checks: headless instantiation (A, B and a B whose set_variant came before _ready), the hero budget of map-fill.md 10
## (<= 26 authored meshes, <= 16 draw instances, 0 lights; keep_separate <= 6), own materials only (one eye glow), the
## size (a massive boar, far bigger than the camp Bristleback) and B = x1.15, B's look (broken right tusk, scars +
## war-arrow shown, plates / bristles swapped to the B materials) and back to A, set_team_color is a no-op, the kit
## hooks + set_variant / play_fidget / play_bristle, walk, attack `tusk_gore` (head down, lunge at the 0.12 s strike,
## hooking toss, one strike), cast `gore_charge` standing (gallop, dust trail, stop at 0.7 s, toss, ends) and while
## being dashed (gallops as long as it moves, stops when it stops), `bristle_hide` (bristle spike, no pose change),
## the fidget, hit, death (onto its side, on the ground, death_finished within 1.3 s), revive.
## Prints "PASS 12.v27" or "FAIL 12.v27: <reasons>".

const TASK_ID := "12.v27"
const SCENE := "res://art/units/neutral/beasts/tusker/tusker.tscn"
const BRISTLEBACK := "res://art/units/neutral/bristleback/bristleback.tscn"
const OWN_DIR := "res://art/units/neutral/beasts/tusker/"
## Faces pass 2026-09-28: the shared face material + the glowing-iris probe (the eyes are the CreatureFaceRig's).
const FaceProbe := preload("res://tests/face_probe.gd")

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
	if variant >= 0:
		m.call(&"set_variant", variant)   # before _ready: must be kept and applied
	holder.add_child(m)
	return m


func _run() -> void:
	_check(ResourceLoader.exists(SCENE), "scene exists")
	var a := _spawn(SCENE, Vector3(0, 0, 0))
	var b := _spawn(SCENE, Vector3(8, 0, 0))
	var early := _spawn(SCENE, Vector3(16, 0, 0), 1)
	await _wait(0.2)
	b.call(&"set_variant", 1)
	await process_frame
	_check(a is CharacterModel, "extends CharacterModel")
	for m: Node3D in [a, b, early]:
		m.set(&"fidget_every", 0.0)
	# ---- structure / budgets
	var authored: int = int(a.call(&"authored_mesh_count"))
	print("authored meshes: ", authored)
	_check(authored >= 8 and authored <= 26, "authored meshes <= 26 (got %d)" % authored)
	for m: Node3D in [a, b]:
		var inst := _draw_instances(m, false)
		var vis := _draw_instances(m, true)
		var verts := _vertices(m)
		var lights := m.find_children("*", "Light3D", true, false).size()
		var sep := 0
		for g: Node in m.find_children("*", "MeshInstance3D", true, false):
			if g.has_meta(&"keep_separate"):
				sep += 1
		print("variant %d: draw instances %d (visible %d), vertices %d, triangles %d, keep_separate %d, lights %d" % [
			int(m.call(&"variant")), inst, vis, verts, _triangles(m), sep, lights])
		_check(inst <= 16, "draw instances <= 16 (got %d)" % inst)
		_check(verts <= 7000, "vertices <= 7000 (got %d)" % verts)
		_check(sep <= 6, "keep_separate <= 6 (got %d)" % sep)
		_check(lights == 0, "0 lights")
	for n: String in ["Root/Mount/Bristles", "Root/Mount/Head/TuskR", "Root/Mount/ScarB", "Fx/Dust", "Fx/Clods",
			"Fx/Trail"]:
		_check(a.get_node_or_null(n) != null and b.get_node_or_null(n) != null, "part %s on every instance" % n)
	var mats := _materials(a) + _materials(b)
	var own: Array = []
	var glows: Array = []
	for mat: Material in mats:
		if FaceProbe.is_face_mat(mat):
			continue   # the shared face (eyes + brows, inside the merged head)
		if not mat.resource_path.begins_with(OWN_DIR):
			_check(false, "foreign material %s" % mat.resource_path)
		elif not (mat.resource_path.get_file() in own):
			own.append(mat.resource_path.get_file())
		var sm := mat as ShaderMaterial
		if sm and sm.shader and sm.shader.resource_path.ends_with("unit_glow.gdshader") and not (sm in glows):
			glows.append(sm)
	print("own materials (%d): %s" % [own.size(), ", ".join(PackedStringArray(own))])
	_check(own.size() >= 8 and own.size() <= 16, "8-16 own materials (got %d)" % own.size())
	# One glow point, the eyes: since the faces pass they are the face's glowing amber irises (no glow material left).
	var face_glow := FaceProbe.glow(a)
	print("face glow: %d vertices, iris colour %s" % [face_glow["count"], face_glow["color"]])
	_check(FaceProbe.glows(a) and glows.size() == 0,
		"one glow point (the eyes = the face's glowing irises), got %d glow materials + face glow %s" % [glows.size(),
		FaceProbe.glows(a)])
	var ic: Color = face_glow["color"]
	# The iris core is the amber iris lightened toward white (CreatureFaceRig.beast_spec): an orange-yellow hue.
	_check(ic.r > 0.8 and ic.h > 0.06 and ic.h < 0.16 and ic.s > 0.3, "amber glowing eyes (%s, hue %.2f)" % [ic, ic.h])
	for g: Node in b.find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		var nv := 0
		if gi is MeshInstance3D and (gi as MeshInstance3D).mesh:
			var gm := (gi as MeshInstance3D).mesh
			for s: int in gm.get_surface_count():
				nv += (gm.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		print("  %s (%s): %d vertices, shadow %d, visible %s" % [b.get_path_to(g), g.get_class(), nv, gi.cast_shadow,
			gi.is_visible_in_tree()])
	# ---- size (rest pose, in the holder frame so B's x1.15 counts) and the Bristleback comparison
	var box := _aabb(a, a.get_parent())
	var bbox := _aabb(b, b.get_parent())
	print("A AABB top %.2f bottom %.3f, w %.2f, l %.2f (z %.2f .. %.2f)" % [box.end.y, box.position.y, box.size.x,
		box.size.z, box.position.z, box.end.z])
	print("B AABB top %.2f bottom %.3f, w %.2f, l %.2f" % [bbox.end.y, bbox.position.y, bbox.size.x, bbox.size.z])
	_check(box.position.y >= -0.005, "nothing below y 0 (got %.3f)" % box.position.y)
	_check(box.end.y >= 2.1 and box.end.y <= 2.7, "A top (bristle tips) 2.1-2.7 m (got %.2f)" % box.end.y)
	_check(box.size.z >= 3.2 and box.size.z <= 4.0, "A length 3.2-4.0 m (got %.2f)" % box.size.z)
	_check(box.size.x >= 1.3 and box.size.x <= 2.0, "A width 1.3-2.0 m (got %.2f)" % box.size.x)
	var hump_a := _top_of(a, "Root/Mount/Merged", a.get_parent())
	var hump_b := _top_of(b, "Root/Mount/Merged", b.get_parent())
	_check(absf(hump_b / hump_a - 1.15) < 0.02, "B is x1.15 taller at the hump (%.3f)" % (hump_b / hump_a))
	_check(bbox.end.y > box.end.y * 1.15, "B's top (war-arrow) above A's bristles")
	_check(absf(b.scale.x - 1.15) < 0.001 and absf(a.scale.x - 1.0) < 0.001, "model scale A 1.0 / B 1.15")
	var hump := _top_of(a, "Root/Mount/Merged", a)
	print("A body (hump) top %.2f" % hump)
	_check(hump >= 1.75 and hump <= 2.0, "A shoulder hump ~1.85 m (got %.2f)" % hump)
	if ResourceLoader.exists(BRISTLEBACK):
		var bb := _spawn(BRISTLEBACK, Vector3(-8, 0, 0))
		await _wait(0.1)
		var bx := _aabb(bb, bb)
		print("bristleback AABB w %.2f, h %.2f, l %.2f" % [bx.size.x, bx.size.y, bx.size.z])
		_check(box.size.y > bx.size.y * 1.8, "about twice the Bristleback's height")
		_check(box.size.z > bx.size.z * 1.6, "far longer than the Bristleback")
		_check(box.size.x * box.size.z * box.size.y > bx.size.x * bx.size.z * bx.size.y * 6.0, "far bulkier")
		bb.get_parent().queue_free()
	_check(a.get(&"attack_style") == &"tusk_gore" and float(a.get(&"attack_windup")) == 0.0, "attack tusk_gore, melee")
	_check(bool(a.get(&"is_quadruped")), "quadruped")
	# ---- variants
	var tusk_a: MeshInstance3D = a.get_node("Root/Mount/Head/TuskR")
	var tusk_b: MeshInstance3D = b.get_node("Root/Mount/Head/TuskR")
	var la := _surface_top(tusk_a, &"tusker_tusk")
	var lb := _surface_top(tusk_b, &"tusker_tusk")
	print("right tusk top (model y) A %.2f, B %.2f" % [la, lb])
	_check(tusk_a.mesh != tusk_b.mesh and lb < la - 0.25, "B's right tusk is the broken one")
	_check(_surface_top(tusk_b, &"tusker_scar") > 0.0 and _surface_top(tusk_a, &"tusker_scar") == -INF,
		"B's eye scar on the right side of the face")
	_check(not (a.get_node("Root/Mount/ScarB") as Node3D).visible, "A: no scars / arrow")
	_check((b.get_node("Root/Mount/ScarB") as Node3D).visible, "B: scars and the war-arrow shown")
	_check(_has_override(b, "Root/Mount/Merged", "tusker_plate_b"), "B: dark plates on the body")
	_check(_has_override(b, "Root/Mount/Head/Merged", "tusker_plate_b"), "B: dark helmet")
	_check(_has_override(b, "Root/Mount/Bristles", "tusker_bristle_b"), "B: black bristles")
	_check(_has_override(b, "Root/Mount/Bristles", "tusker_tip_b"), "B: silver bristle tips")
	_check(not _has_any_override(a), "A: no material overrides")
	_check(int(early.call(&"variant")) == 1 and absf(early.scale.x - 1.15) < 0.001
		and (early.get_node("Root/Mount/ScarB") as Node3D).visible, "set_variant before _ready is applied")
	early.call(&"set_variant", 0)
	await process_frame
	_check(absf(early.scale.x - 1.0) < 0.001 and not (early.get_node("Root/Mount/ScarB") as Node3D).visible
		and not _has_any_override(early), "set_variant(0) restores A")
	early.get_parent().queue_free()
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
				"set_variant", "play_bristle"]:
			_check(m.has_method(h), "hook %s" % h)
		_check(m.has_signal(&"death_finished"), "signal death_finished")
	var root_n: Node3D = a.get_node("Root")
	var head: Node3D = a.get_node("Root/Mount/Head")
	var leg: Node3D = a.get_node("Root/Mount/LegFL")
	var trail: GPUParticles3D = a.get_node("Fx/Trail")
	# walk
	a.call(&"set_moving", 5.5)
	var max_leg := 0.0
	var min_br := 1.0
	for i: int in 50:
		await process_frame
		max_leg = maxf(max_leg, absf(leg.rotation.x))
		min_br = minf(min_br, float(a.call(&"bristle_raise")))
	a.call(&"set_moving", 0.0)
	print("walk: max fore-leg swing %.1f deg, bristles %.2f" % [rad_to_deg(max_leg), min_br])
	_check(max_leg > deg_to_rad(15.0), "the legs swing in the trot (%.1f deg)" % rad_to_deg(max_leg))
	_check(min_br < 0.0, "bristles flatten on the trot")
	await _wait(0.5)
	# attack: head down in the windup, lunge at the strike, hooking toss
	var strikes0: int = int(a.call(&"strike_count"))
	a.call(&"play_attack")
	await _until_t(a, 0.065)
	var hx_wind := head.rotation.x
	await _until_t(a, 0.125)
	var rz_hit := root_n.position.z
	await _until_t(a, 0.25)
	var hx_toss := head.rotation.x
	print("gore: head windup %.1f, lunge z %.2f, toss %.1f" % [rad_to_deg(hx_wind), rz_hit, rad_to_deg(hx_toss)])
	_check(hx_wind > deg_to_rad(15.0), "tusks lowered in the windup")
	_check(rz_hit > 0.3, "lunge forward at the strike (%.2f)" % rz_hit)
	_check(hx_toss < deg_to_rad(-10.0), "tusks hook up after the strike (%.1f)" % rad_to_deg(hx_toss))
	_check(int(a.call(&"strike_count")) == strikes0 + 1, "one strike per attack")
	await _wait(0.8)
	_check(a.get(&"_action") == &"", "attack finished")
	await _wait(0.3)
	# gore charge, standing still (preview): gallop, trail, stop at CHARGE_IDLE, toss, end
	var charges0: int = int(a.call(&"charge_count"))
	var tosses0: int = int(a.call(&"toss_count"))
	a.call(&"play_cast", &"gore_charge")
	await _until_t(a, 0.3)
	var gal_head := head.rotation.x
	var charging := bool(a.call(&"is_charging"))
	var trail_on := trail.emitting
	var gl := 0.0
	for i: int in 12:
		await process_frame
		gl = maxf(gl, absf(leg.rotation.x))
	var br_ch := float(a.call(&"bristle_raise"))
	print("charge: head %.1f, charging %s, trail %s, leg swing %.1f, bristles %.2f" % [rad_to_deg(gal_head), charging,
		trail_on, rad_to_deg(gl), br_ch])
	_check(charging and trail_on, "gallops with a dust trail")
	_check(gal_head > deg_to_rad(15.0), "head low, tusks forward in the charge")
	_check(gl > deg_to_rad(25.0), "bounding gallop legs (%.1f deg)" % rad_to_deg(gl))
	_check(br_ch > 0.8, "bristles fully up in the charge")
	_check(int(a.call(&"charge_count")) == charges0 + 1, "one charge counted")
	await _until_t(a, 0.84)
	var t_toss := head.rotation.x
	print("toss: head %.1f, charging %s, tosses %d" % [rad_to_deg(t_toss), a.call(&"is_charging"),
		int(a.call(&"toss_count"))])
	_check(not bool(a.call(&"is_charging")), "standing charge stops by itself (0.7 s)")
	_check(t_toss < deg_to_rad(-15.0), "tusk toss after the charge (%.1f)" % rad_to_deg(t_toss))
	_check(int(a.call(&"toss_count")) == tosses0 + 1, "one toss")
	await _wait(0.1)
	_check(not trail.emitting, "trail off after the charge")
	await _wait(0.8)
	_check(a.get(&"_action") == &"", "cast finished")
	# gore charge while being dashed at 12 m/s for 1.1 s (longer than the standing 0.7 s)
	var holder: Node3D = a.get_parent()
	var start := holder.position
	a.call(&"play_cast", &"gore_charge")
	var still_at_09 := false
	var elapsed := 0.0
	while elapsed < 1.1:
		await process_frame
		elapsed += 1.0 / 60.0
		holder.position += Vector3(0, 0, 12.0 / 60.0)
		if elapsed >= 0.9 and elapsed < 0.92:
			still_at_09 = bool(a.call(&"is_charging"))
	var stop_frames := 0
	while bool(a.call(&"is_charging")) and stop_frames < 30:
		await process_frame
		stop_frames += 1
	print("dash: charging at 0.9 s %s, stopped %d frames after the unit stopped" % [still_at_09, stop_frames])
	_check(still_at_09, "keeps galloping while the unit is dashed")
	_check(stop_frames <= 10, "stops right after the dash ends (%d frames)" % stop_frames)
	await _wait(0.9)
	holder.position = start
	_check(a.get(&"_action") == &"", "dash cast finished")
	# bristle hide: a spike + shiver, no pose change
	var kicks0: int = int(a.call(&"bristle_kicks"))
	a.call(&"play_cast", &"bristle_hide")
	await _wait(0.12)
	print("bristle hide: action '%s', raise %.2f" % [a.get(&"_action"), float(a.call(&"bristle_raise"))])
	_check(a.get(&"_action") == &"", "bristle_hide keeps the current pose")
	_check(float(a.call(&"bristle_raise")) > 0.5, "bristle_hide spikes the bristles")
	_check(int(a.call(&"bristle_kicks")) == kicks0 + 1, "bristle_hide counted")
	await _wait(0.8)
	# fidget
	a.call(&"play_fidget")
	await _wait(0.5)
	_check(a.get(&"_action") == &"fidget", "fidget plays")
	a.call(&"set_moving", 3.0)
	await _wait(0.1)
	_check(a.get(&"_action") == &"", "moving cancels the fidget")
	a.call(&"set_moving", 0.0)
	await _wait(0.5)
	# hit
	a.call(&"play_hit")
	await _wait(0.1)
	print("hit: head %.1f, bristles %.2f" % [rad_to_deg(head.rotation.x), float(a.call(&"bristle_raise"))])
	_check(float(a.call(&"bristle_raise")) > 0.4, "hit: bristles spike")
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
	# ---- death mid-charge + revive (on B: the bigger one)
	var rb: Node3D = b.get_node("Root")
	b.call(&"play_cast", &"gore_charge")
	await _wait(0.2)
	var got: Array = [false]
	b.connect(&"death_finished", func() -> void: got[0] = true, CONNECT_ONE_SHOT)
	b.call(&"play_death")
	await _until_death(b, 0.7)
	var low_body := _lowest_vertex(b, ["Merged"], [])
	var low_all := _lowest_vertex(b, [], [])
	print("death 0.7 s: root roll %.1f deg, root y %.2f, lowest body %.3f, lowest all %.3f, trail %s" % [
		rad_to_deg(rb.rotation.z), rb.position.y, low_body, low_all, (b.get_node("Fx/Trail") as GPUParticles3D).emitting])
	_check(absf(rb.rotation.z) > deg_to_rad(60.0), "crashes onto its side")
	_check(low_body > -0.15 and low_body < 0.3, "lying on the ground, not through it (lowest body %.3f)" % low_body)
	_check(low_all > -0.3, "nothing digs deep into the ground (%.3f)" % low_all)
	_check(not (b.get_node("Fx/Trail") as GPUParticles3D).emitting, "no trail once dead")
	await _wait(0.6)
	_check(got[0], "death_finished emitted within 1.3 s")
	b.call(&"revive")
	await _wait(0.3)
	_check(absf(rb.rotation.x) < 0.05 and absf(rb.rotation.z) < 0.05 and absf(rb.position.y) < 0.06,
		"revive resets the pose")
	_check(int(b.call(&"variant")) == 1 and absf(b.scale.x - 1.15) < 0.001, "revive keeps the variant")
	# ---- transparency (Unit.leave_map fade / shroud) is tolerated on every part
	for g: Node in b.find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).transparency = 0.5
	await _wait(0.1)
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


## Waits (max 1.5 s) until the model's action clock reaches t (the headless run has no camera: tier 1, half rate).
func _until_t(m: Node, t: float) -> void:
	for i: int in 90:
		if float(m.get(&"_action_t")) >= t:
			return
		await process_frame


func _until_death(m: Node, t: float) -> void:
	for i: int in 90:
		if float(m.get(&"_death_t")) >= t:
			return
		await process_frame


func _has_override(m: Node, path: String, mat_name: String) -> bool:
	var mi := m.get_node_or_null(path) as MeshInstance3D
	if mi == null or mi.mesh == null:
		return false
	for s: int in mi.mesh.get_surface_count():
		var o := mi.get_surface_override_material(s)
		if o and o.resource_path.get_file().get_basename() == mat_name:
			return true
	return false


func _has_any_override(m: Node) -> bool:
	for g: Node in m.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null:
			continue
		for s: int in mi.mesh.get_surface_count():
			if mi.get_surface_override_material(s) != null:
				return true
	return false


## Top (y in the model's own frame, unscaled) of the surfaces of `mi` using material `mat_name`; -INF when none.
func _surface_top(mi: MeshInstance3D, mat_name: StringName) -> float:
	var model := mi.owner if mi.owner else mi.get_parent()
	while model and not (model is CharacterModel):
		model = model.get_parent()
	var xf := (model as Node3D).global_transform.affine_inverse() * mi.global_transform
	var top := -INF
	for s: int in mi.mesh.get_surface_count():
		var mp: Material = mi.mesh.surface_get_material(s)
		if mp == null or mp.resource_path.get_file().get_basename() != String(mat_name):
			continue
		for v: Vector3 in (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
			top = maxf(top, (xf * v).y)
	return top


## Top (y) of one mesh node, in `frame` space.
func _top_of(model: Node3D, path: String, frame: Node3D) -> float:
	var mi := model.get_node(path) as MeshInstance3D
	var xf := frame.global_transform.affine_inverse() * mi.global_transform
	var top := -INF
	for s: int in mi.mesh.get_surface_count():
		for v: Vector3 in (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
			top = maxf(top, (xf * v).y)
	return top


## Lowest vertex (holder frame: ground = 0) of the visible meshes whose node name is in `names` (empty = all), the
## blob skipped.
func _lowest_vertex(model: Node3D, names: Array, skip: Array) -> float:
	var inv := (model.get_parent() as Node3D).global_transform.affine_inverse()
	var low := INF
	for g: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow" or not mi.is_visible_in_tree():
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


func _draw_instances(n: Node, visible_only: bool) -> int:
	var c := 0
	for g: Node in n.find_children("*", "GeometryInstance3D", true, false):
		if g is MeshInstance3D and (g as MeshInstance3D).mesh == null:
			continue
		if visible_only and not (g as Node3D).is_visible_in_tree():
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


## Unique materials on the model's meshes (surface overrides > mesh surfaces); the blob skipped.
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


## Visible meshes' AABB in `frame` space (the blob skipped).
func _aabb(n: Node, frame: Node3D) -> AABB:
	var inv := frame.global_transform.affine_inverse()
	var box := AABB()
	var first := true
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow" or not mi.is_visible_in_tree():
			continue
		var bx := (inv * mi.global_transform) * mi.mesh.get_aabb()
		box = bx if first else box.merge(bx)
		first = false
	return box
