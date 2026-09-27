extends SceneTree
## Task 13c.V5: the Wildcaller model (art/units/champions/wildcaller/, titans-2.md 5 / 11).
## Run: $GODOT --headless --path . -s tests/test_13c_v5.gd --fixed-fps 60 --quit-after 6000
## Checks: hooks exist; budgets (<= 26 authored meshes, <= 16 draw instances, 0 lights, 0 own materials, <= 8 shared
## materials, <= 1 looping particle system); the read (the staff far taller than her with its foot on the ground, a crown
## >= 0.4 m wide with a glowing heart and pink blossoms; tall narrow antlers (A on the team hood, B on a twig circlet,
## narrower than 0.8 m, over 2.3 m high); the feathered cloak reaching the ground and flaring wider than her robe; B's
## braided beard down the chest; the variants differ); weapon_override: every class keeps the staff and the thorn_bolt
## style / windup 0.15, no kit piece; the attack (the crown thrust at the target, charging glow, sparks at the release,
## get_beam_origin at the crown, ends by 0.6 s); every cast (her 3 + the 6 Wizard-tree actives: plays its length,
## thornsnare drives the staff foot into the ground in front, call_the_pack raises the crown overhead in bloom,
## wild_stampede levels the staff along the line, starfall aims the crown at the sky, astral_form holds it upright in
## bloom, gravity_well crouches, slipstep blinks, comet_rain flares 3 times; the bloom closes again); play_call (under
## the ground at the start with the crown breaking the ground first, rising, the staff planted at the end in bloom,
## call_finished, attacks ignored during the rise, safe before _ready, the blob back); team colour (hood, stole,
## ribbons: cloth surfaces only); the kit slot audit (KITFIX rules); death (falls, glows 0, death_finished) and revive.
## Prints "PASS 13c.v5" or "FAIL 13c.v5: <reasons>".

const TASK_ID := "13c.v5"
const SCENE := "res://art/units/champions/wildcaller/wildcaller.tscn"
const OWN_DIR := "res://art/units/champions/wildcaller/"
const KITFIX := "res://art/units/kit/tools/kitfix_glow_check.gd"
const CLASSES: Array[StringName] = [&"wizard", &"spear", &"sword_shield", &"two_hand", &""]
const HEART_Y := 1.50
const FOOT := 1.0
## [id, length (s), sample time of the key pose]
const CASTS: Array = [[&"thornsnare", 1.0, 0.52], [&"call_the_pack", 1.3, 0.6], [&"wild_stampede", 1.3, 0.64],
	[&"arc_bolt", 0.6, 0.2], [&"slipstep", 0.5, 0.15], [&"starfall", 1.2, 0.5], [&"gravity_well", 1.0, 0.5],
	[&"comet_rain", 1.4, 0.68], [&"astral_form", 1.2, 0.6]]

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
	for h: String in ["set_variant", "play_call", "is_calling", "weapon_override", "get_beam_origin", "get_crown_origin",
			"get_staff_foot", "play_cast", "play_attack", "set_weapon_class", "set_team_color", "set_moving", "play_hit",
			"play_death", "revive", "play_level_up", "set_veterancy", "set_seated", "authored_mesh_count"]:
		_check(m.has_method(h), "hook %s" % h)
	_check(m.has_signal(&"call_finished") and m.has_signal(&"death_finished"), "signals call_finished / death_finished")
	_check(m.call(&"weapon_override") == &"wild_staff", "weapon_override is wild_staff")
	_check(m.get(&"attack_style") == &"thorn_bolt" and is_equal_approx(float(m.get(&"attack_windup")), 0.15),
		"attack style thorn_bolt, windup 0.15")
	_check(m.get(&"death_style") == &"fall", "death style fall (Nature)")
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
	var mats := _materials(m)
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
	var staff: MeshInstance3D = m.get_node("Root/Chest/ArmR/Staff")
	var sb := _bounds_of(m, [staff])
	var body := _bounds_of(m, _body_parts(m))
	var va: MeshInstance3D = m.get_node("Root/Chest/Head/Variant")
	var vb: MeshInstance3D = b.get_node("Root/Chest/Head/Variant")
	var ha := _bounds_of(m, [va])
	var hb := _bounds_of(b, [vb])
	print("staff y %.2f..%.2f, body top %.2f (variant A top %.2f, B top %.2f)" % [sb.position.y, sb.end.y, body.end.y,
		ha.end.y, hb.end.y])
	_check(sb.end.y > ha.end.y + 0.2 and sb.end.y > 2.6, "the staff towers over her antlers (%.2f > %.2f)" % [sb.end.y, ha.end.y])
	_check(sb.position.y > -0.02 and sb.position.y < 0.08, "the staff's foot rests on the ground (%.2f)" % sb.position.y)
	var foot: Vector3 = m.to_local(m.call(&"get_staff_foot"))
	_check(foot.y > -0.02 and foot.y < 0.08, "get_staff_foot on the ground (%s)" % foot)
	# the crown: the part of the staff over the heart's cradle
	var crown := _bounds_of_above(m, staff, 1.20)
	print("crown %.2f x %.2f m, top %.2f" % [crown.size.x, crown.size.z, crown.end.y])
	_check(crown.size.x > 0.4 and crown.size.z > 0.4, "the crown is >= 0.4 m wide (%.2f x %.2f)" % [crown.size.x, crown.size.z])
	_check(_mesh_has(staff.mesh, "nature_glow") and _mesh_has(staff.mesh, "nature_blossom"),
		"the crown has the glowing heart and pink blossoms")
	var o: Vector3 = m.to_local(m.call(&"get_beam_origin"))
	_check(o.y > 2.3 and o.y < 2.8, "get_beam_origin at the crown heart (%s)" % o)
	# antlers: the pale (nature_skin) surfaces of the variant piece
	var aa := _surface_bounds(m, va, "nature_skin")
	var ab := _surface_bounds(b, vb, "nature_skin")
	print("antlers A %.2f wide, top %.2f; B %.2f wide, top %.2f" % [aa.size.x, aa.end.y, ab.size.x, ab.end.y])
	_check(aa.end.y > 2.35 and aa.size.x < 0.8 and aa.size.x > 0.45,
		"variant A: tall narrow antlers (%.2f high, %.2f wide)" % [aa.end.y, aa.size.x])
	_check(ab.end.y > 2.25 and ab.size.x < 0.8, "variant B: antlers too (%.2f high, %.2f wide)" % [ab.end.y, ab.size.x])
	_check(_mesh_has(va.mesh, "nature_cloth"), "variant A: the team hood")
	var beard := _surface_bounds(b, vb, "nature_stone")
	_check(beard.position.y < 1.1 and beard.end.z > 0.4, "variant B: the braided beard down the chest (%.2f, z %.2f)" %
		[beard.position.y, beard.end.z])
	_check(va.mesh != vb.mesh, "the variants differ")
	# the cloak and robe
	var chest := _bounds_of(m, [m.get_node("Root/Chest/Merged")])
	var hips := _bounds_of(m, [m.get_node("Root/Hips/Merged")])
	print("cloak / chest y %.2f..%.2f, x %.2f..%.2f; robe x %.2f..%.2f" % [chest.position.y, chest.end.y, chest.position.x,
		chest.end.x, hips.position.x, hips.end.x])
	_check(chest.position.y < 0.06, "the feathered cloak reaches the ground (%.2f)" % chest.position.y)
	_check(chest.size.x > hips.size.x + 0.2 and chest.size.x > 0.95, "the cloak flares wider than the robe (%.2f vs %.2f)" %
		[chest.size.x, hips.size.x])
	_check(chest.end.y < 1.9, "the mantle / ruff stays under the hood top (%.2f)" % chest.end.y)


# ---------------------------------------------------------------- team colour

func _check_team(m: Node3D) -> void:
	var red := Color(0.8, 0.1, 0.1)
	m.call(&"set_team_color", red)
	var found: Dictionary = {"hood": false, "stole": false, "ribbons": false}
	var others_ok := true
	for pair: Array in [["hood", "Root/Chest/Head/Variant"], ["stole", "Root/Chest/Merged"], ["ribbons", "Root/Chest/ArmR/Staff"]]:
		var mi: MeshInstance3D = m.get_node(pair[1])
		for s: int in mi.mesh.get_surface_count():
			var base := mi.mesh.surface_get_material(s)
			var ov := mi.get_surface_override_material(s) as ShaderMaterial
			var bn := base.resource_path.get_file().get_basename()
			if bn == "nature_cloth" and ov and (ov.get_shader_parameter(&"base_color") as Color).is_equal_approx(red):
				found[pair[0]] = true
			if ov and not (bn.ends_with("_cloth") or bn.ends_with("_cloth_dark") or bn.ends_with("_cape")):
				others_ok = false
	for k: String in found:
		_check(found[k], "the %s take(s) the team colour" % k)
	_check(others_ok, "only cloth surfaces are recoloured")


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
		print("KITFIX AUDIT OK (wildcaller: slot map, no collision)")


# ---------------------------------------------------------------- weapon override

func _check_classes(m: Node3D) -> void:
	var staff: Node3D = m.get_node("Root/Chest/ArmR/Staff")
	var arm_r: MeshInstance3D = m.get_node("Root/Chest/ArmR/Merged")
	var base_mesh := arm_r.mesh
	for cls: StringName in CLASSES:
		m.call(&"set_weapon_class", cls)
		await _wait(0.4)
		var pieces: Array = m.call(&"weapon_pieces")
		_check(staff.visible, "%s: the staff stays" % cls)
		_check(pieces.is_empty() and m.get_node("Root/Chest/ArmR").find_children("WeaponPop*", "", true, false).is_empty(),
			"%s: no kit weapon piece" % cls)
		_check(arm_r.mesh == base_mesh, "%s: the arm mesh is unchanged" % cls)
		_check(m.get(&"attack_style") == &"thorn_bolt" and is_equal_approx(float(m.get(&"attack_windup")), 0.15),
			"%s: thorn_bolt / 0.15 kept (%s, %.2f)" % [cls, m.get(&"attack_style"), float(m.get(&"attack_windup"))])
		_check(m.call(&"weapon_class") == cls, "%s: weapon_class reported" % cls)
		_check(m.call(&"get_weapon_tip") == null, "%s: no weapon tip (the beam origin stays the crown)" % cls)
	m.call(&"set_weapon_class", &"wizard")
	await _wait(0.1)


# ---------------------------------------------------------------- attack

func _check_attack(m: Node3D) -> void:
	var staff: MeshInstance3D = m.get_node("Root/Chest/ArmR/Staff")
	var spark: GPUParticles3D = m.get_node("Root/Chest/ArmR/Staff/ReleaseSparks")
	await _wait(0.2)
	var rest_glow := float(staff.get_instance_shader_parameter(&"glow_boost"))
	m.call(&"play_attack")
	await _until(m, 0.14)
	var glow := float(staff.get_instance_shader_parameter(&"glow_boost"))
	await _until(m, 0.16)
	var o := m.to_local(m.call(&"get_beam_origin") as Vector3)
	var axis := (m.global_transform.basis.inverse() * staff.global_transform.basis.y).normalized()
	print("attack release: crown %s, staff axis %s, crown glow %.2f (rest %.2f)" % [o, axis, glow, rest_glow])
	_check(o.z > 0.9 and o.y > 1.6, "attack: the crown is thrust at the target (%s)" % o)
	_check(axis.z > 0.6 and axis.y > 0.4, "attack: the staff leans toward the target, crown up (%s)" % axis)
	_check(glow > rest_glow + 0.4, "attack: the crown charges (%.2f)" % glow)
	_check(spark.emitting, "attack: sparks at the crown at the release")
	await _wait(0.45)
	_check(m.get(&"_action") == &"", "attack: finished by 0.6 s")
	await _wait(0.3)
	var ax2 := (m.global_transform.basis.inverse() * staff.global_transform.basis.y).normalized()
	_check(ax2.y > 0.97, "attack: the staff stands again (%s)" % ax2)


# ---------------------------------------------------------------- casts

func _check_casts(m: Node3D) -> void:
	var staff: MeshInstance3D = m.get_node("Root/Chest/ArmR/Staff")
	var rest_mesh := staff.mesh
	for c: Array in CASTS:
		var id: StringName = c[0]
		var ln: float = c[1]
		var sample: float = c[2]
		m.call(&"play_cast", id)
		var saw_bloom := false
		var max_g := 0.0
		var min_scale := 9.0
		var min_root := 9.0
		var max_crown_y := -9.0
		var flares := 0
		var last_g := 0.0
		var rising := false
		var at_sample: Dictionary = {}
		var t0 := 0
		while m.get(&"_action") == &"cast" and t0 < int((ln + 0.5) * 60.0):
			await process_frame
			t0 += 1
			if staff.mesh != rest_mesh:
				saw_bloom = true
			var g := float(staff.get_instance_shader_parameter(&"glow_boost"))
			if g > last_g + 0.6 and not rising:
				flares += 1
				rising = true
			elif g < last_g:
				rising = false
			last_g = g
			max_g = maxf(max_g, g)
			min_scale = minf(min_scale, (m.get_node("Root") as Node3D).scale.x)
			min_root = minf(min_root, (m.get_node("Root") as Node3D).position.y)
			var cr := m.to_local(m.call(&"get_beam_origin") as Vector3)
			max_crown_y = maxf(max_crown_y, cr.y)
			if at_sample.is_empty() and float(m.get(&"_action_t")) >= sample:
				at_sample = {"crown": cr, "foot": m.to_local(m.call(&"get_staff_foot") as Vector3),
					"axis": (m.global_transform.basis.inverse() * staff.global_transform.basis.y).normalized()}
		var took := float(t0) / 60.0
		print("%-14s %.2f s, bloom %s, glow max %.2f, flares %d, root y min %.2f, crown y max %.2f, at %.2f: %s" % [id,
			took, saw_bloom, max_g, flares, min_root, max_crown_y, sample, at_sample])
		_check(absf(took - ln) < 0.1, "%s: plays %.2f s (%.2f expected)" % [id, took, ln])
		_check(max_g > 1.8, "%s: the crown flares (%.2f)" % [id, max_g])
		if at_sample.is_empty():
			_check(false, "%s: no sample" % id)
			continue
		var cr: Vector3 = at_sample["crown"]
		var ft: Vector3 = at_sample["foot"]
		var ax: Vector3 = at_sample["axis"]
		match id:
			&"thornsnare":
				_check(ft.y < 0.06 and ft.z > 0.3 and ax.y > 0.9, "thornsnare: the staff driven into the ground in front (foot %s)" % ft)
				_check(min_root < -0.1, "thornsnare: a crouch (%.2f)" % min_root)
			&"call_the_pack":
				_check(cr.y > 3.0 and saw_bloom, "call_the_pack: the crown raised overhead in bloom (%.2f)" % cr.y)
			&"wild_stampede":
				_check(ax.z > 0.85 and absf(ax.y) < 0.45 and saw_bloom, "wild_stampede: the staff levelled along the line (%s)" % ax)
			&"arc_bolt":
				_check(cr.z > 0.9, "arc_bolt: the crown thrust forward (%s)" % cr)
			&"starfall":
				_check(ax.y > 0.95 and cr.y > 3.0, "starfall: the crown at the sky (%s, %.2f)" % [ax, cr.y])
			&"astral_form":
				_check(ax.y > 0.95 and saw_bloom and cr.x > 0.5, "astral_form: the staff upright out to the side in bloom (%s)" % cr)
			&"gravity_well":
				_check(min_root < -0.1, "gravity_well: a crouch (%.2f)" % min_root)
			&"comet_rain":
				_check(flares >= 3 and cr.y > 2.6, "comet_rain: three pumps at the sky (%d, %.2f)" % [flares, cr.y])
			&"slipstep":
				_check(min_scale < 0.2, "slipstep: the blink (root scale %.2f)" % min_scale)
		await _wait(0.3)
		_check(staff.mesh == rest_mesh, "%s: the bloom closes again" % id)
	# unknown ids still play a thrust
	m.call(&"play_cast", &"no_such_skill")
	await _wait(0.1)
	_check(m.get(&"_action") == &"cast", "an unknown id plays a quick thrust")
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
	var staff: MeshInstance3D = m.get_node("Root/Chest/ArmR/Staff")
	var rest_mesh: Mesh = m.call(&"_staff_mesh", 0)
	var y0 := root_n.position.y
	var head_y := m.to_local(head.global_position).y
	print("call start: root y %.2f, head y %.2f, calling %s" % [y0, head_y, m.call(&"is_calling")])
	_check(bool(m.call(&"is_calling")), "call: playing (asked before _ready)")
	_check(head_y < -1.0, "call: she starts under the ground (head y %.2f)" % head_y)
	m.call(&"play_attack")
	await _wait(0.05)
	_check(m.get(&"_cast_id") == &"wildcaller_call" and m.get(&"_action") == &"cast", "call: an attack does not cut the rise")
	await _until(m, 0.4)
	var crown := m.to_local(m.call(&"get_beam_origin") as Vector3)
	head_y = m.to_local(head.global_position).y
	print("call 0.4 s: crown y %.2f, head y %.2f" % [crown.y, head_y])
	_check(crown.y > 0.3 and head_y < 0.1, "call: the crown breaks the ground first (crown %.2f, head %.2f)" % [crown.y, head_y])
	_check(root_n.position.y > y0 + 1.0, "call: rising (%.2f -> %.2f)" % [y0, root_n.position.y])
	await _until(m, 1.6)
	var foot := m.to_local(m.call(&"get_staff_foot") as Vector3)
	print("call plant: foot %s, bloom %s" % [foot, staff.mesh != rest_mesh])
	_check(foot.y < 0.1 and staff.mesh != rest_mesh, "call: the staff planted beside her in bloom (foot %s)" % foot)
	await _wait(0.6)
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
	var staff: MeshInstance3D = m.get_node("Root/Chest/ArmR/Staff")
	var got: Array = [false]
	m.connect(&"death_finished", func() -> void: got[0] = true, CONNECT_ONE_SHOT)
	m.call(&"play_death")
	await _wait(1.05)
	var head_y := m.to_local((m.get_node("Root/Chest/Head") as Node3D).global_position).y
	var g1 := float(staff.get_instance_shader_parameter(&"glow_boost"))
	print("death: head y %.2f, crown glow %.2f, finished %s" % [head_y, g1, got[0]])
	_check(head_y < 0.8, "death: she falls (head y %.2f)" % head_y)
	_check(g1 == 0.0, "death: the crown dies")
	_check(got[0], "death: death_finished")
	m.call(&"revive")
	await _wait(0.2)
	g1 = float(staff.get_instance_shader_parameter(&"glow_boost"))
	_check(g1 > 0.6 and absf((m.get_node("Root") as Node3D).position.y) < 0.05, "revive: standing, the crown lit (%.2f)" % g1)


# ---------------------------------------------------------------- helpers

func _until(m: Node3D, t: float) -> void:
	var guard := 0
	while float(m.get(&"_action_t")) < t and m.get(&"_action") != &"" and guard < 240:
		await process_frame
		guard += 1


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


## Model-space AABB of the vertices of `mi` whose own-space y is above `y_min` (the staff's crown).
func _bounds_of_above(m: Node3D, mi: MeshInstance3D, y_min: float) -> AABB:
	var xf := m.global_transform.affine_inverse() * mi.global_transform
	var first := true
	var bb := AABB()
	for s: int in mi.mesh.get_surface_count():
		for v: Vector3 in mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]:
			if v.y < y_min:
				continue
			var w := xf * v
			if first:
				bb = AABB(w, Vector3.ZERO)
				first = false
			else:
				bb = bb.expand(w)
	return bb


## Model-space AABB of the surfaces of `mi` whose material file name contains `mat_part`.
func _surface_bounds(m: Node3D, mi: MeshInstance3D, mat_part: String) -> AABB:
	var xf := m.global_transform.affine_inverse() * mi.global_transform
	var first := true
	var bb := AABB()
	for s: int in mi.mesh.get_surface_count():
		var mat := mi.mesh.surface_get_material(s)
		if mat == null or not mat.resource_path.get_file().contains(mat_part):
			continue
		for v: Vector3 in mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]:
			var w := xf * v
			if first:
				bb = AABB(w, Vector3.ZERO)
				first = false
			else:
				bb = bb.expand(w)
	return bb


func _mesh_has(mesh: Mesh, mat_part: String) -> bool:
	if mesh == null:
		return false
	for s: int in mesh.get_surface_count():
		var mat := mesh.surface_get_material(s)
		if mat and mat.resource_path.get_file().contains(mat_part):
			return true
	return false


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
