extends SceneTree
## Campaign review 2026-10-16 (e8m3): the Hollow King's own look (art/units/titans/hollow_king/hollow_king_art.gd).
## Builds a Rime Colossus unit (the mission's base), scales its model x 2.2 like MissionE6Base.arm_enemy, calls
## HollowKingArt.dress(unit) and checks:
##   A. silhouette parts: a merged HollowKing mesh on every pivot, 4 chain nodes, the crown above the head, chains on the
##      ground, the mantle / throne / void / glow surfaces; no visible Colossus (ice) draw is left;
##   B. draw budget: instances and surfaces <= the Colossus's + 4;
##   C. VfxCap: every visible emitter under its cap, no HDR albedo / glow colour, no alpha-blended mesh over 0.72;
##   D. gameplay untouched: hp / max_hp / collision layer + mask / collision shapes identical;
##   E. tiers: Low (headless) = no ember emitter; Medium (forced) = one, VfxCap-fitted;
##   F. API: dress twice = no doubling, set_chain_color / set_chain_broken, hooks (walk / attack / hit) run;
##   G. the model scene hollow_king.tscn dresses itself.
## Run: $GODOT --headless --path . -s tests/test_cr_hollow_king.gd --fixed-fps 60 --quit-after 3000
## Prints "PASS cr_hollow_king" or "FAIL cr_hollow_king: <reasons>".

const TASK_ID := "cr_hollow_king"
const EXTRA_DRAWS := 4

var _fails: PackedStringArray = PackedStringArray()
var _world: Node3D


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)


func _initialize() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 8, 14)
	_world.add_child(cam)
	cam.look_at_from_position(cam.position, Vector3(0, 2, 0))
	_run()


func _run() -> void:
	await _check_unit()
	await _check_tiers()
	await _check_scene()
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


func _colossus() -> Unit:
	var t := UnitType.find("rime_colossus")
	if t == null:
		return null
	var u := t.create_unit()
	u.team = Unit.Team.NEUTRAL
	_world.add_child(u)
	return u


func _check_unit() -> void:
	HollowKingArt.quality_override = -1
	var u := _colossus()
	if u == null:
		_fails.append("no rime_colossus UnitType")
		return
	await process_frame
	await process_frame
	var m := u.get_model()
	_check(m != null, "the Colossus unit has a model")
	if m == null:
		return
	m.scale = Vector3.ONE * 2.2
	var before := _draws(m)
	var gp := _gameplay(u)
	HollowKingArt.dress(u)
	await process_frame
	var after := _draws(m)
	print("draws: Colossus %d instances / %d surfaces -> Hollow King %d / %d" % [before.x, before.y, after.x, after.y])
	var vk := _verts_visible(m)
	print("vertices: Hollow King %d (the Colossus budget: 6000)" % vk)
	_check(vk <= 6000, "vertices %d > 6000" % vk)
	# A. parts
	_check(HollowKingArt.is_dressed(u), "dressed")
	for path: String in HollowKingArt.PIVOTS:
		var mi := m.get_node_or_null(path + "/HollowKing") as MeshInstance3D
		_check(mi != null and mi.visible and mi.mesh != null, "merged part on " + path)
	var mats := {}
	for n: Node in m.find_children("HollowKing", "MeshInstance3D", true, false):
		var mesh := (n as MeshInstance3D).mesh
		for s: int in mesh.get_surface_count():
			var mt := mesh.surface_get_material(s)
			if mt:
				mats[mt.resource_name] = true
	for want: String in ["hk_pale", "hk_dark", "hk_stone", "hk_metal", "hk_gold", "hk_void", "hk_mantle", "hk_glow"]:
		_check(mats.has(want), "a %s surface" % want)
	var head := m.get_node_or_null(^"Root/Chest/Head/HollowKing") as MeshInstance3D
	if head:
		var top := (head.get_parent() as Node3D).position.y + (m.get_node(^"Root/Chest") as Node3D).position.y \
				+ head.mesh.get_aabb().end.y
		_check(top > 3.0, "the crown tops the head (model y %.2f > 3.0)" % top)
	for limb: StringName in HollowKingArt.LIMBS:
		var c := HollowKingArt.chain_node(u, limb)
		_check(c != null and c.visible, "chain %s" % limb)
		if c:
			var low := c.global_transform * c.mesh.get_aabb().position
			_check(low.y - m.global_position.y < 0.4, "chain %s reaches the ground (%.2f)" % [limb, low.y])
	for n: Node in m.find_children("*", "GeometryInstance3D", true, false):
		var gi := n as GeometryInstance3D
		if not gi.is_visible_in_tree():
			continue
		var nm := String(gi.name)
		_check(nm == "HollowKing" or nm.begins_with("HKChain_") or nm == "HKEmbers" or nm == "Shadow" or nm == "SlamRing",
			"Colossus draw still visible: %s" % m.get_path_to(gi))
	# B. draws
	_check(after.x <= before.x + EXTRA_DRAWS, "instances %d > Colossus %d + %d" % [after.x, before.x, EXTRA_DRAWS])
	_check(after.y <= before.y + EXTRA_DRAWS, "surfaces %d > Colossus %d + %d" % [after.y, before.y, EXTRA_DRAWS])
	# C. caps
	_check_caps(m)
	# D. gameplay
	var gp2 := _gameplay(u)
	_check(gp == gp2, "gameplay changed: %s -> %s" % [gp, gp2])
	# F. API
	HollowKingArt.dress(u)
	var again := _draws(m)
	_check(again == after, "dress twice doubled the parts (%s -> %s)" % [after, again])
	HollowKingArt.set_chain_color(u, &"arm_r", Color(0.2, 0.9, 0.3))
	var cm := HollowKingArt.chain_node(u, &"arm_r").material_override as ShaderMaterial
	_check(cm.get_shader_parameter(&"glow_color") == Color(0.2, 0.9, 0.3), "set_chain_color")
	_check(HollowKingArt.chain_node(u, &"arm_l").material_override != cm, "chains own their materials")
	var full := HollowKingArt.chain_node(u, &"leg_l").mesh
	HollowKingArt.set_chain_broken(u, &"leg_l", true)
	var stub := HollowKingArt.chain_node(u, &"leg_l").mesh
	_check(stub != full and stub.get_aabb().size.length() < full.get_aabb().size.length(), "set_chain_broken stub")
	var lit := HollowKingArt.chain_node(u, &"leg_l")
	_check(float((lit.material_override as ShaderMaterial).get_shader_parameter(&"energy")) < 1.0, "a broken chain dims")
	var leg_mat_before := lit.material_override
	HollowKingArt.set_chain_broken(u, &"leg_l", false)
	_check(HollowKingArt.chain_node(u, &"leg_l").mesh == full, "chain rebinds")
	_check(HollowKingArt.chain_node(u, &"leg_l").material_override != leg_mat_before, "a rebound chain is lit again")
	# Art Lab B9: a 2nd King with the same colours builds no new chain material.
	var u2 := _colossus()
	await process_frame
	HollowKingArt.dress(u2)
	await process_frame
	HollowKingArt.set_chain_color(u2, &"arm_r", Color(0.2, 0.9, 0.3))
	_check(HollowKingArt.chain_node(u2, &"arm_r").material_override == cm, "chain materials shared across Kings")
	u2.queue_free()
	m.call(&"set_moving", 3.0)
	for i: int in 20:
		await process_frame
	m.call(&"set_moving", 0.0)
	m.call(&"play_attack")
	m.call(&"play_hit")
	for i: int in 70:
		await process_frame
	_check(_gameplay(u) == gp, "gameplay changed after the hooks")
	_check(m.find_child("HKEmbers", true, false) == null, "no ember emitter at Low (headless)")
	u.queue_free()
	await process_frame


func _check_tiers() -> void:
	HollowKingArt.quality_override = 1
	var u := _colossus()
	await process_frame
	var m := u.get_model()
	var before := _draws(m)
	HollowKingArt.dress(u)
	await process_frame
	var e := m.find_child("HKEmbers", true, false) as GPUParticles3D
	_check(e != null, "Medium: one ember emitter")
	var after := _draws(m)
	print("Medium: %d instances / %d surfaces (+ %d emitters)" % [after.x, after.y, after.z])
	_check(after.z <= before.z + 1, "Medium: at most one new emitter")
	_check_caps(m)
	HollowKingArt.quality_override = -1
	u.queue_free()
	await process_frame


func _check_scene() -> void:
	var ps := load("res://art/units/titans/hollow_king/hollow_king.tscn") as PackedScene
	_check(ps != null, "hollow_king.tscn loads")
	if ps == null:
		return
	var a := ps.instantiate() as Node3D
	_world.add_child(a)
	await process_frame
	_check(HollowKingArt.is_dressed(a), "hollow_king.tscn dresses itself")
	_check(a.get_node_or_null(^"Root/Chest/Head/HollowKing") != null, "hollow_king.tscn has the crowned head")
	a.queue_free()
	await process_frame


func _verts_visible(m: Node3D) -> int:
	var total := 0
	for n: Node in m.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.is_visible_in_tree() and mi.mesh:
			for s: int in mi.mesh.get_surface_count():
				total += (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return total


## Vector3i(visible mesh instances, their surfaces, visible emitters) under the model.
func _draws(m: Node3D) -> Vector3i:
	var inst := 0
	var surf := 0
	var emit := 0
	for n: Node in m.find_children("*", "GeometryInstance3D", true, false):
		var gi := n as GeometryInstance3D
		if not gi.is_visible_in_tree():
			continue
		if gi is GPUParticles3D or gi is CPUParticles3D:
			emit += 1
			continue
		if gi is MeshInstance3D and (gi as MeshInstance3D).mesh:
			inst += 1
			surf += (gi as MeshInstance3D).mesh.get_surface_count()
		elif gi is MultiMeshInstance3D and (gi as MultiMeshInstance3D).multimesh:
			inst += 1
			surf += maxi(1, (gi as MultiMeshInstance3D).multimesh.mesh.get_surface_count())
	return Vector3i(inst, surf, emit)


func _check_caps(m: Node3D) -> void:
	for n: Node in m.find_children("*", "GeometryInstance3D", true, false):
		var gi := n as GeometryInstance3D
		if not gi.is_visible_in_tree():
			continue
		if gi is GPUParticles3D or gi is CPUParticles3D:
			var r := VfxCap.measure(gi)
			if not r.is_empty():
				_check(float(r["value"]) <= float(r["cap"]) + 0.001, "emitter %s over VfxCap (%.2f > %.2f)" % [gi.name,
					float(r["value"]), float(r["cap"])])
			continue
		for mt: Material in _materials(gi):
			var bm := mt as BaseMaterial3D
			if bm:
				_check(maxf(bm.albedo_color.r, maxf(bm.albedo_color.g, bm.albedo_color.b)) <= 1.0, "HDR albedo on %s" % gi.name)
				if bm.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED and bm.blend_mode == BaseMaterial3D.BLEND_MODE_MIX:
					_check(bm.albedo_color.a <= VfxCap.MIX, "alpha %.2f > 0.72 on %s" % [bm.albedo_color.a, gi.name])
			var sm := mt as ShaderMaterial
			if sm and sm.resource_name.begins_with("hk_"):
				for p: StringName in [&"glow_color", &"base_color"]:
					var v: Variant = sm.get_shader_parameter(p)
					if v is Color:
						var c := v as Color
						_check(maxf(c.r, maxf(c.g, c.b)) <= 1.0, "HDR %s on %s" % [p, sm.resource_name])


func _materials(gi: GeometryInstance3D) -> Array[Material]:
	var out: Array[Material] = []
	if gi.material_override:
		out.append(gi.material_override)
		return out
	var mesh: Mesh = null
	if gi is MeshInstance3D:
		mesh = (gi as MeshInstance3D).mesh
	elif gi is MultiMeshInstance3D and (gi as MultiMeshInstance3D).multimesh:
		mesh = (gi as MultiMeshInstance3D).multimesh.mesh
	if mesh:
		for s: int in mesh.get_surface_count():
			var mt := mesh.surface_get_material(s)
			if mt:
				out.append(mt)
	return out


## What the King's gameplay reads: HP, collision layers and every collision shape.
func _gameplay(u: Unit) -> Array:
	var shapes: Array = []
	for c: Node in u.find_children("*", "CollisionShape3D", true, false):
		var cs := c as CollisionShape3D
		shapes.append([str(cs.get_path()), cs.shape, cs.transform, cs.disabled])
	return [u.hp, u.get_stat(&"max_hp"), u.collision_layer, u.collision_mask, shapes]
