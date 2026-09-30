extends SceneTree
## Task 13b.V5: the Mage Archer model (art/units/champions/mage_archer/, tier3-extras.md 6 / 12).
## Run: $GODOT --headless --path . -s tests/test_13b_v5.gd --fixed-fps 60 --quit-after 6000
## Checks: hooks exist; budgets (<= 26 authored meshes, <= 16 draw instances, 0 lights, 0 own materials, <= 8 shared
## materials on the body); the read (the bow taller than her, bottom tip above the ground, top tip over the hood, a glowing
## string; the rune quiver floats clear of her back with 5 glowing heads, bobbing); variant A = hood (team cloth, peak
## over the head), B = hood down (silver hair + braid, lower head top); weapon_override: every class keeps the bow and
## the arcane_bow style / windup 0.15, no kit piece; the attack (drawn arrow of light at the release, the left hand at
## the nock, release sparks, recoil, ends by 0.6 s); every cast (her 3 + the 6 Wizard-tree actives: plays, finishes,
## the shots draw the bow, starfall aims up, eclipse_volley opens the quiver fan, astral_form holds the bow upright);
## play_call (under the ground at the start, stands at the end, call_finished, attacks ignored during the rise, safe
## before _ready); get_beam_origin at the bow; team colour (hood, cape, lining only); the kit slot audit (KITFIX rules);
## death (sink under the ground, glows 0, death_finished) and revive. Prints "PASS 13b.v5" or "FAIL 13b.v5: <reasons>".

const TASK_ID := "13b.v5"
const SCENE := "res://art/units/champions/mage_archer/mage_archer.tscn"
const OWN_DIR := "res://art/units/champions/mage_archer/"
const KITFIX := "res://art/units/kit/tools/kitfix_glow_check.gd"
const CLASSES: Array[StringName] = [&"wizard", &"spear", &"sword_shield", &"two_hand", &""]
const HAND_L := Vector3(-0.40, 1.00, 0.08)
const SHOULDER_L := Vector3(-0.31, 1.50, 0.0)
const NOCK := 0.52
## [id, length (s), a shot? (the bow is drawn at some point), sample time]
const CASTS: Array = [[&"sable_shaft", 1.0, true, 0.5], [&"grave_mark", 0.8, false, 0.34],
	[&"eclipse_volley", 1.3, true, 0.5], [&"arc_bolt", 0.6, true, 0.19], [&"slipstep", 0.5, false, 0.15],
	[&"starfall", 1.2, true, 0.40], [&"gravity_well", 1.0, false, 0.5], [&"comet_rain", 1.4, true, 0.37],
	[&"astral_form", 1.2, false, 0.6]]

var _fails: PackedStringArray = PackedStringArray()
var _world: Node3D


func _initialize() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	var cam := Camera3D.new()   # within 30 m: the models animate every frame (distance tier 0)
	_world.add_child(cam)
	cam.position = Vector3(0, 6, 10)
	cam.make_current()
	_run()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAILED: ", what)


func _wait(sec: float) -> void:
	for i: int in int(ceil(sec * 60.0)):
		await process_frame


func _spawn(at: Vector3, variant: int = 0) -> Node3D:
	var holder := Node3D.new()
	holder.position = at
	_world.add_child(holder)
	var m: Node3D = (load(SCENE) as PackedScene).instantiate()
	m.call(&"set_variant", variant)
	holder.add_child(m)
	return m


func _run() -> void:
	var m := _spawn(Vector3.ZERO)
	var b := _spawn(Vector3(4, 0, 0), 1)
	await _wait(0.3)
	for h: String in ["set_variant", "play_call", "is_calling", "weapon_override", "get_beam_origin", "get_quiver_origin",
			"play_cast", "play_attack", "set_weapon_class", "set_team_color", "set_moving", "play_hit", "play_death",
			"revive", "play_level_up", "set_veterancy", "set_seated", "authored_mesh_count"]:
		_check(m.has_method(h), "hook %s" % h)
	_check(m.has_signal(&"call_finished") and m.has_signal(&"death_finished"), "signals call_finished / death_finished")
	_check(m.call(&"weapon_override") == &"mage_bow", "weapon_override is mage_bow")
	_check(m.get(&"attack_style") == &"arcane_bow" and is_equal_approx(float(m.get(&"attack_windup")), 0.15),
		"attack style arcane_bow, windup 0.15")
	_check(m.get(&"death_style") == &"sink", "death style sink (Shadow)")
	_check_budgets(m)
	_check_read(m, b)
	var tm := _spawn(Vector3(0, 0, 6))
	await _wait(0.1)
	_check_team(tm)
	tm.get_parent().queue_free()
	_check_audit(m, b)
	await _check_classes(m)
	await _check_attack(m)
	await _check_casts(m)
	await _check_call()
	await _check_death(b)
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


# ---------------------------------------------------------------- budgets

func _check_budgets(m: Node3D) -> void:
	var authored: int = int(m.call(&"authored_mesh_count"))
	var inst := _draw_instances(m)
	# B8 merge (2026-09-30): the ChampionPalette material stands for its folded sources (all kit palette entries)
	var mats := ChampionPalette.unfold(_materials(m))
	var own := 0
	var names := PackedStringArray()
	for mat: Material in mats:
		names.append(mat.resource_path.get_file().get_basename())
		if mat.resource_path.begins_with(OWN_DIR) or mat.resource_path == "":
			own += 1
	print("authored meshes %d, draw instances %d, materials %d (%s), own %d" % [authored, inst, mats.size(),
		", ".join(names), own])
	_check(authored <= 26, "authored meshes <= 26 (got %d)" % authored)
	_check(inst <= 16, "draw instances <= 16 (got %d)" % inst)
	_check(own == 0, "no own / runtime material (got %d)" % own)
	_check(mats.size() <= 8, "<= 8 shared materials (got %d)" % mats.size())
	_check(m.find_children("*", "Light3D", true, false).is_empty(), "0 lights")
	var loops := 0
	for p: Node in m.find_children("*", "GPUParticles3D", true, false):
		if not (p as GPUParticles3D).one_shot:
			loops += 1
	_check(loops <= 1, "<= 1 looping particle system (got %d)" % loops)


# ---------------------------------------------------------------- the read

func _check_read(m: Node3D, b: Node3D) -> void:
	var bow: MeshInstance3D = m.get_node("Root/Chest/ArmR/Bow")
	var quiver: MeshInstance3D = m.get_node("Root/Chest/Quiver")
	var bb := _bounds_of(m, [bow])
	var body := _bounds_of(m, _body_parts(m))
	print("bow y %.2f..%.2f (height %.2f), body top %.2f" % [bb.position.y, bb.end.y, bb.size.y, body.end.y])
	_check(bb.size.y > body.end.y, "the bow (%.2f m) is taller than her (%.2f m)" % [bb.size.y, body.end.y])
	_check(bb.position.y > 0.0, "the bow's lower tip stays above the ground (%.2f)" % bb.position.y)
	_check(bb.end.y > body.end.y + 0.05, "the bow's upper tip rises over the hood (%.2f > %.2f)" % [bb.end.y, body.end.y])
	_check(body.end.y > 1.85 and body.end.y < 2.15, "she is tall: hood top %.2f m" % body.end.y)
	_check(_mesh_has(bow.mesh, "shadow_glow"), "the bow has the glowing string")
	# body clearance: no bow vertex inside the torso / legs (rest pose)
	var legs_x := 0.0
	for p: String in ["Root/Hips/LegL/Merged", "Root/Hips/LegR/Merged"]:
		var lb := _bounds_of(m, [m.get_node(p)])
		legs_x = maxf(legs_x, lb.end.x)
	_check(bb.position.x > legs_x, "the bow stays right of the legs (%.2f > %.2f)" % [bb.position.x, legs_x])
	# quiver: floats clear of the back, 5 glowing heads
	var qb := _bounds_of(m, [quiver])
	var gap := _clearance(m, quiver, [m.get_node("Root/Chest/Merged"), m.get_node("Root/Chest/Head/Variant"),
		m.get_node("Root/Hips/Merged")])
	print("quiver z %.2f..%.2f y %.2f..%.2f, clearance to the body / cape / hood %.3f m" % [qb.position.z, qb.end.z,
		qb.position.y, qb.end.y, gap])
	_check(gap > 0.06, "the quiver floats clear of her back (%.3f m)" % gap)
	_check(_mesh_has(quiver.mesh, "shadow_glow"), "the quiver heads glow")
	_check(qb.end.y > 1.75, "the quiver heads rise behind the shoulders (%.2f)" % qb.end.y)
	var heads := _glow_clusters(quiver.mesh)
	_check(heads >= 5, "5 glowing heads (clusters %d)" % heads)
	# variants
	var va: MeshInstance3D = m.get_node("Root/Chest/Head/Variant")
	var vb: MeshInstance3D = b.get_node("Root/Chest/Head/Variant")
	var ha := _bounds_of(m, [va])
	var hb := _bounds_of(b, [vb])
	print("variant A top %.2f, variant B top %.2f" % [ha.end.y, hb.end.y])
	_check(_mesh_has(va.mesh, "shadow_cloth") and ha.end.y > 1.97, "variant A: the peaked team hood (%.2f)" % ha.end.y)
	_check(_mesh_has(vb.mesh, "shadow_silver") and hb.end.y < 1.95 and hb.position.y < 1.1,
		"variant B: hood down, hair and a braid to the waist (%.2f..%.2f)" % [hb.position.y, hb.end.y])
	_check(va.mesh != vb.mesh, "the variants differ")


# ---------------------------------------------------------------- team colour

func _check_team(m: Node3D) -> void:
	var red := Color(0.8, 0.1, 0.1)
	m.call(&"set_team_color", red)
	var hood: MeshInstance3D = m.get_node("Root/Chest/Head/Variant")
	var chest: MeshInstance3D = m.get_node("Root/Chest/Merged")
	var hood_ok := false
	for s: int in hood.mesh.get_surface_count():
		var ov := hood.get_surface_override_material(s) as ShaderMaterial
		if ov and ov.resource_path == "" and (ov.get_shader_parameter(&"base_color") as Color).is_equal_approx(red):
			hood_ok = true
	var cape_ok := false
	var others_ok := true
	for s: int in chest.mesh.get_surface_count():
		var base := chest.mesh.surface_get_material(s)
		var ov := chest.get_surface_override_material(s) as ShaderMaterial
		var bn := base.resource_path.get_file().get_basename()
		if bn == "shadow_cape" and ov and (ov.get_shader_parameter(&"cloth_color") as Color).is_equal_approx(red):
			cape_ok = true
		if ov and not (bn.ends_with("_cloth") or bn.ends_with("_cloth_dark") or bn.ends_with("_cape")):
			others_ok = false
	_check(hood_ok, "the hood takes the team colour")
	_check(cape_ok, "the half cape takes the team colour")
	_check(others_ok, "only cloth / cape surfaces are recoloured")


# ---------------------------------------------------------------- kit slot audit (KITFIX rules)

func _check_audit(m: Node3D, b: Node3D) -> void:
	var K: GDScript = load(KITFIX)
	var slots: Dictionary = {"ao_bottom": 1, "ao_height": 2, "hit_flash": 3, "flash_color": 4, "glow_boost": 5, "blob_color": 6}
	var collisions := 0
	var geos := 0
	for mm: Node3D in [m, b]:
		for g: Node in mm.find_children("*", "GeometryInstance3D", true, false):
			var gi := g as GeometryInstance3D
			if gi == mm.get(&"_shadow") or gi is GPUParticles3D:
				continue
			geos += 1
			var by_slot: Dictionary = {}
			var names: Array[String] = []
			for mat: Material in mm.call(&"_materials_of", gi):
				if not mat is ShaderMaterial:
					continue
				for u: Array in K.call(&"_instance_uniforms", (mat as ShaderMaterial).shader):
					var nm: String = u[0]
					if names.has(nm):
						continue
					names.append(nm)
					if slots.has(nm) and int(u[1]) != int(slots[nm]):
						_check(false, "%s on slot %d (map %d)" % [nm, u[1], slots[nm]])
					if by_slot.has(u[1]):
						collisions += 1
					by_slot[u[1]] = nm
			if names.has("hit_flash"):
				_check((mm.get(&"_flash_all_targets") as Array).has(gi), "%s flashed by the kit" % mm.get_path_to(gi))
	print("slot audit: %d geometries, %d collisions" % [geos, collisions])
	_check(collisions == 0, "no instance-uniform slot collision")
	if collisions == 0:
		print("KITFIX AUDIT OK (mage archer: slot map, no collision)")


# ---------------------------------------------------------------- weapon override

func _check_classes(m: Node3D) -> void:
	var bow: Node3D = m.get_node("Root/Chest/ArmR/Bow")
	var arm_r: MeshInstance3D = m.get_node("Root/Chest/ArmR/Merged")
	var base_mesh := arm_r.mesh
	for cls: StringName in CLASSES:
		m.call(&"set_weapon_class", cls)
		await _wait(0.4)
		var pieces: Array = m.call(&"weapon_pieces")
		_check(bow.visible, "%s: the bow stays" % cls)
		_check(pieces.is_empty() and m.get_node("Root/Chest/ArmR").find_children("WeaponPop*", "", true, false).is_empty(),
			"%s: no kit weapon piece" % cls)
		_check(arm_r.mesh == base_mesh, "%s: the arm mesh is unchanged" % cls)
		_check(m.get(&"attack_style") == &"arcane_bow" and is_equal_approx(float(m.get(&"attack_windup")), 0.15),
			"%s: arcane_bow / 0.15 kept (%s, %.2f)" % [cls, m.get(&"attack_style"), float(m.get(&"attack_windup"))])
		_check(m.call(&"weapon_class") == cls, "%s: weapon_class reported" % cls)
	m.call(&"set_weapon_class", &"wizard")
	await _wait(0.1)


# ---------------------------------------------------------------- attack

func _check_attack(m: Node3D) -> void:
	var bow: MeshInstance3D = m.get_node("Root/Chest/ArmR/Bow")
	var spark: GPUParticles3D = m.get_node("Root/Chest/ArmR/Bow/ReleaseSparks")
	var arm_l: Node3D = m.get_node("Root/Chest/ArmL")
	var rest_glow := float(bow.get_instance_shader_parameter(&"glow_boost"))
	m.call(&"play_attack")
	await _until(m, 0.14)
	var drawn := _mesh_verts(bow.mesh) > _mesh_verts(_bow_rest_mesh(m))
	var hand := m.to_local(arm_l.global_transform * (HAND_L - SHOULDER_L))
	var nock := m.to_local(bow.global_transform * Vector3(0, 0, -NOCK))
	var tip := m.to_local(bow.global_transform * Vector3(0.025, 0, 0.36))
	var axis := (m.global_transform.basis.inverse() * bow.global_transform.basis.y).normalized()
	var glow := float(bow.get_instance_shader_parameter(&"glow_boost"))
	print("attack draw: hand %s, nock %s (%.2f m), arrow tip %s, bow axis %s, string glow %.2f (rest %.2f)" % [hand, nock,
		hand.distance_to(nock), tip, axis, glow, rest_glow])
	_check(drawn, "attack: the arrow of light is drawn before the release")
	_check(hand.distance_to(nock) < 0.16, "attack: the left hand holds the nock (%.2f m)" % hand.distance_to(nock))
	_check(tip.z > 0.6 and tip.y > 1.25, "attack: the arrow points forward at shoulder height (%s)" % tip)
	_check(axis.y > 0.9, "attack: the bow stands upright (%s)" % axis)
	_check(glow > rest_glow + 0.5, "attack: the string charges (%.2f)" % glow)
	await _until(m, 0.18)
	_check(spark.emitting, "attack: sparks off the arrow head at the release")
	var o: Vector3 = m.call(&"get_beam_origin")
	_check(o.distance_to(bow.global_position) < 0.4, "get_beam_origin at the bow (%s)" % o)
	await _wait(0.45)
	_check(m.get(&"_action") == &"", "attack: finished by 0.6 s")
	await _wait(0.2)
	_check(_mesh_verts(bow.mesh) == _mesh_verts(_bow_rest_mesh(m)), "attack: the string is back at rest")


# ---------------------------------------------------------------- casts

func _check_casts(m: Node3D) -> void:
	var bow: MeshInstance3D = m.get_node("Root/Chest/ArmR/Bow")
	var quiver: MeshInstance3D = m.get_node("Root/Chest/Quiver")
	var rest_q := quiver.mesh
	for c: Array in CASTS:
		var id: StringName = c[0]
		var ln: float = c[1]
		m.call(&"play_cast", id)
		var saw_drawn := false
		var saw_fan := false
		var max_up := -1.0
		var max_q := 0.0
		var min_scale := 9.0
		var upright := 0.0
		var t0 := 0
		var aim_elev := -90.0
		while m.get(&"_action") == &"cast" and t0 < int((ln + 0.5) * 60.0):
			await process_frame
			t0 += 1
			if _mesh_verts(bow.mesh) > _mesh_verts(_bow_rest_mesh(m)):
				saw_drawn = true
				var d := (m.global_transform.basis.inverse() * bow.global_transform.basis.z).normalized()
				aim_elev = maxf(aim_elev, rad_to_deg(asin(clampf(d.y, -1.0, 1.0))))
			if quiver.mesh != rest_q:
				saw_fan = true
			max_q = maxf(max_q, float(quiver.get_instance_shader_parameter(&"glow_boost")))
			min_scale = minf(min_scale, (m.get_node("Root") as Node3D).scale.x)
			var ax := (m.global_transform.basis.inverse() * bow.global_transform.basis.y).normalized()
			max_up = maxf(max_up, ax.y)
			if id == &"astral_form" and float(m.get(&"_action_t")) > 0.5 and float(m.get(&"_action_t")) < 0.8:
				upright = maxf(upright, ax.y)
		var took := float(t0) / 60.0
		print("%-15s %.2f s, drawn %s, aim %.0f deg, quiver fan %s, quiver glow max %.2f, root scale min %.2f" % [id, took,
			saw_drawn, aim_elev, saw_fan, max_q, min_scale])
		_check(absf(took - ln) < 0.1, "%s: plays %.2f s (%.2f expected)" % [id, took, ln])
		if c[2]:
			_check(saw_drawn, "%s: the bow is drawn" % id)
		match id:
			&"starfall":
				_check(aim_elev > 60.0, "starfall: shot upward (%.0f deg)" % aim_elev)
			&"eclipse_volley":
				_check(saw_fan and aim_elev > 45.0, "eclipse_volley: the quiver fan opens, aimed high (%.0f deg)" % aim_elev)
			&"grave_mark":
				_check(max_q > 2.0, "grave_mark: the quiver flares (%.2f)" % max_q)
			&"slipstep":
				_check(min_scale < 0.2, "slipstep: the blink (root scale %.2f)" % min_scale)
			&"astral_form":
				_check(upright > 0.9 and saw_fan, "astral_form: the bow held upright (%.2f), the fan open" % upright)
			&"sable_shaft", &"arc_bolt":
				_check(aim_elev > -10.0 and aim_elev < 30.0, "%s: a level shot (%.0f deg)" % [id, aim_elev])
		await _wait(0.3)
		_check(quiver.mesh == rest_q, "%s: the quiver fan closes again" % id)
	# unknown ids still play a shot
	m.call(&"play_cast", &"no_such_skill")
	await _wait(0.1)
	_check(m.get(&"_action") == &"cast", "an unknown id plays a quick shot")
	await _wait(0.7)


# ---------------------------------------------------------------- call

func _check_call() -> void:
	var holder := Node3D.new()
	holder.position = Vector3(-4, 0, 0)
	_world.add_child(holder)
	var m: Node3D = (load(SCENE) as PackedScene).instantiate()
	m.call(&"play_call")            # before _ready: kept
	var got: Array = [false]
	m.connect(&"call_finished", func() -> void: got[0] = true, CONNECT_ONE_SHOT)
	holder.add_child(m)
	await process_frame
	var root_n: Node3D = m.get_node("Root")
	var head: Node3D = m.get_node("Root/Chest/Head")
	var y0 := root_n.position.y
	var head_y := m.to_local(head.global_position).y
	print("call start: root y %.2f, head y %.2f, calling %s" % [y0, head_y, m.call(&"is_calling")])
	_check(bool(m.call(&"is_calling")), "call: playing (asked before _ready)")
	_check(head_y < -0.05, "call: she starts under the ground (head y %.2f)" % head_y)
	m.call(&"play_attack")
	await _wait(0.05)
	_check(m.get(&"_cast_id") == &"mage_archer_call" and m.get(&"_action") == &"cast", "call: an attack does not cut the rise")
	await _wait(0.8)
	var mid := root_n.position.y
	_check(mid > y0 + 0.8, "call: rising (%.2f -> %.2f)" % [y0, mid])
	await _wait(1.3)
	print("call end: root y %.2f, finished %s" % [root_n.position.y, got[0]])
	_check(got[0], "call: call_finished emitted")
	_check(absf(root_n.position.y) < 0.03 and not bool(m.call(&"is_calling")), "call: she stands on the ground")
	var blob := m.get(&"_shadow") as GeometryInstance3D
	_check(blob == null or blob.transparency < 0.01, "call: the ground blob is back")
	m.call(&"play_attack")
	await _wait(0.1)
	_check(m.get(&"_action") == &"attack", "after the call: attacks play again")
	holder.queue_free()


# ---------------------------------------------------------------- death

func _check_death(m: Node3D) -> void:
	var bow: MeshInstance3D = m.get_node("Root/Chest/ArmR/Bow")
	var quiver: MeshInstance3D = m.get_node("Root/Chest/Quiver")
	var got: Array = [false]
	m.connect(&"death_finished", func() -> void: got[0] = true, CONNECT_ONE_SHOT)
	m.call(&"play_death")
	await _wait(1.05)
	var head_y := m.to_local((m.get_node("Root/Chest/Head") as Node3D).global_position).y
	var g1 := float(bow.get_instance_shader_parameter(&"glow_boost"))
	var g2 := float(quiver.get_instance_shader_parameter(&"glow_boost"))
	print("death: head y %.2f, string glow %.2f, quiver glow %.2f, finished %s" % [head_y, g1, g2, got[0]])
	_check(head_y < 0.4, "death: sinks into the ground (head y %.2f)" % head_y)
	_check(g1 == 0.0 and g2 == 0.0, "death: the glows die")
	_check(got[0], "death: death_finished")
	m.call(&"revive")
	await _wait(0.2)
	g1 = float(bow.get_instance_shader_parameter(&"glow_boost"))
	_check(g1 > 1.0 and absf((m.get_node("Root") as Node3D).position.y) < 0.05, "revive: standing, the string lit (%.2f)" % g1)


# ---------------------------------------------------------------- helpers

func _until(m: Node3D, t: float) -> void:
	var guard := 0
	while float(m.get(&"_action_t")) < t and m.get(&"_action") != &"" and guard < 240:
		await process_frame
		guard += 1


func _bow_rest_mesh(m: Node3D) -> Mesh:
	return m.call(&"_bow_mesh", false)


func _mesh_verts(mesh: Mesh) -> int:
	var n := 0
	for s: int in mesh.get_surface_count():
		n += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return n


## Clusters of glow vertices farther than 6 cm apart (the quiver's heads; the halo ticks are small and close).
func _glow_clusters(mesh: Mesh) -> int:
	var cents: Array[Vector3] = []
	if true:   # palette-aware (ChampionPalette B8 merge): the glow vertices by their source material
		for v: Vector3 in ChampionPalette.vertices_of(mesh, "glow"):
			if v.y < 0.25:
				continue   # the heads sit high; the halo ticks are at y <= 0.2
			var found := false
			for c: Vector3 in cents:
				if c.distance_to(v) < 0.09:
					found = true
					break
			if not found:
				cents.append(v)
	return cents.size()


func _body_parts(m: Node3D) -> Array:
	var out: Array = []
	for p: String in ["Root/Hips/Merged", "Root/Hips/LegL/Merged", "Root/Hips/LegR/Merged", "Root/Chest/Merged",
			"Root/Chest/Head/Merged", "Root/Chest/Head/Variant", "Root/Chest/ArmL/Merged", "Root/Chest/ArmR/Merged"]:
		var n := m.get_node_or_null(p)
		if n:
			out.append(n)
	return out


## Model-space AABB of the given MeshInstance3Ds (their vertices), current pose.
func _bounds_of(m: Node3D, nodes: Array) -> AABB:
	var inv := m.global_transform.affine_inverse()
	var first := true
	var bb := AABB()
	for n: Node in nodes:
		var mi := n as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var xf := inv * mi.global_transform
		for s: int in mi.mesh.get_surface_count():
			for v: Vector3 in mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]:
				var w := xf * v
				if first:
					bb = AABB(w, Vector3.ZERO)
					first = false
				else:
					bb = bb.expand(w)
	return bb


## Smallest distance (model space) from a vertex of `a` to a vertex of the `others` (coarse: every 2nd vertex).
func _clearance(m: Node3D, a: MeshInstance3D, others: Array) -> float:
	var inv := m.global_transform.affine_inverse()
	var pa := PackedVector3Array()
	var xa := inv * a.global_transform
	for s: int in a.mesh.get_surface_count():
		for v: Vector3 in a.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]:
			pa.append(xa * v)
	var best := INF
	for n: Node in others:
		var mi := n as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var xb := inv * mi.global_transform
		for s: int in mi.mesh.get_surface_count():
			var vs: PackedVector3Array = mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
			for j: int in range(0, vs.size(), 2):
				var w := xb * vs[j]
				if w.z > -0.1:
					continue
				for p: Vector3 in pa:
					best = minf(best, p.distance_squared_to(w))
	return sqrt(best)


func _mesh_has(mesh: Mesh, mat_part: String) -> bool:
	# palette-aware (ChampionPalette B8 merge, 2026-09-30)
	return ChampionPalette.mesh_has(mesh, mat_part)


func _draw_instances(n: Node) -> int:
	var c := 0
	for g: Node in n.find_children("*", "GeometryInstance3D", true, false):
		if g is MeshInstance3D and (g as MeshInstance3D).mesh == null:
			continue
		c += 1
	return c


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
