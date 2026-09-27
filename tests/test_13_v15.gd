extends SceneTree
## Task 13.V15: the Nightmare Knight titan model (art/units/titans/nightmare_knight/nightmare_knight.tscn).
## Run: $GODOT --headless --path . -s tests/test_13_v15.gd --fixed-fps 60 --quit-after 3000
## Checks: instantiation (2 instances: build + cache), MountModel base, pivots, hooks (exact names), titan budget of
## cavalry-mounts.md 10 (<= 36 authored meshes, <= 20 draw instances incl. particles, <= 2 particle systems, 0 lights),
## materials (own <= 4 in the folder, the rest Shadow / kit palette), size vs the Shadow Knight ("titan" read),
## rider glued to the Seat through the gallop, lance carried high / level at the gallop, gallop smoke toggle (auto,
## on, off), lance strike attack, charge (lance level, lunge, charge_struck with the tip ahead), hit flash on horse and
## rider, team colour (caparison, tabard / cape, pennon), glows driven by the kit (crest, hooves), death (dissolve,
## death_finished at 1.7 s < 2.0), revive, the kit slot audit.
## Prints "PASS 13.v15" or "FAIL 13.v15: <reasons>".

const TASK_ID := "13.v15"
const SCENE := "res://art/units/titans/nightmare_knight/nightmare_knight.tscn"
const OWN_DIR := "res://art/units/titans/nightmare_knight/"
const KNIGHT := "res://art/units/shadow/shadow_knight.tscn"
const KITFIX := "res://art/units/kit/tools/kitfix_glow_check.gd"

var _fails: PackedStringArray = PackedStringArray()
var _world: Node3D


func _initialize() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 6, 12)
	_world.add_child(cam)
	cam.look_at_from_position(cam.position, Vector3.ZERO)
	_run()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAILED: ", what)


func _wait(sec: float) -> void:
	for i: int in int(ceil(sec * 60.0)):
		await process_frame


func _spawn(at: Vector3, path: String = SCENE) -> Node3D:
	var holder := Node3D.new()
	holder.position = at
	_world.add_child(holder)
	var m: Node3D = (load(path) as PackedScene).instantiate()
	holder.add_child(m)
	return m


func _run() -> void:
	_check(ResourceLoader.exists(SCENE), "scene exists")
	var a := _spawn(Vector3(0, 0, 0))
	var b := _spawn(Vector3(6, 0, 0))
	await _wait(0.3)
	_check(a is MountModel and a is CharacterModel, "extends MountModel")
	for p: String in ["Root", "Root/Mount", "Root/Mount/Head", "Root/Mount/Neck", "Root/Mount/LegFL", "Root/Mount/LegFR",
			"Root/Mount/LegBL", "Root/Mount/LegBR", "Root/Mount/Tail", "Root/Mount/Seat", "Root/Chest", "Root/Chest/Head",
			"Root/Chest/ArmL", "Root/Chest/ArmR", "Root/Chest/ArmR/Lance", "Fx", "Fx/SmokeTrail", "Shadow"]:
		_check(a.get_node_or_null(p) != null, "node %s" % p)
	for h: String in ["set_team_color", "set_moving", "play_attack", "play_hit", "play_death", "play_cast", "play_level_up",
			"set_veterancy", "set_status", "revive", "play_charge", "set_gallop_smoke", "is_gallop_smoke", "get_lance_tip",
			"lance_pitch", "seat_transform", "seat_node", "gait_phase", "gallop_blend", "is_galloping", "authored_mesh_count"]:
		_check(a.has_method(h), "hook %s" % h)
	_check(a.has_signal(&"death_finished") and a.has_signal(&"charge_struck"), "signals death_finished + charge_struck")
	_check(a.get(&"attack_style") == &"knight_lance" and float(a.get(&"attack_windup")) == 0.0, "melee lance attack style")
	# ---- budgets (titan: <= 36 meshes, <= 20 draw instances, <= 2 particle systems, 0 lights)
	var authored_a: int = int(a.call(&"authored_mesh_count"))
	var authored_b: int = int(b.call(&"authored_mesh_count"))
	var inst := _draw_instances(b)
	var parts := b.find_children("*", "GPUParticles3D", true, false).size()
	var verts := _vertices(b)
	print("authored meshes %d / %d, draw instances %d (incl. %d particle systems), vertices %d, lights %d" % [authored_a,
		authored_b, inst, parts, verts, b.find_children("*", "Light3D", true, false).size()])
	for g: Node in b.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh:
			print("  %s: %d surfaces, %d vertices" % [b.get_path_to(mi), mi.mesh.get_surface_count(), _mesh_verts(mi.mesh)])
	_check(authored_a == authored_b, "authored count stable for the cached instance")
	_check(authored_a <= 36, "authored meshes <= 36 (got %d)" % authored_a)
	_check(inst <= 20, "draw instances <= 20 (got %d)" % inst)
	_check(parts <= 2, "<= 2 particle systems (got %d)" % parts)
	_check(b.find_children("*", "Light3D", true, false).is_empty(), "0 lights")
	_check(verts <= 24000, "vertices <= 24000 (got %d)" % verts)
	# ---- materials
	var own: Array = []
	for mat: Material in _materials(b):
		var path := mat.resource_path
		if path.begins_with(OWN_DIR):
			if not (path.get_file() in own):
				own.append(path.get_file())
		else:
			_check(path.begins_with("res://art/units/kit/materials/") or path.begins_with("res://art/units/shadow/materials/"),
				"material %s is a kit / Shadow palette entry" % path)
	print("own materials: ", own)
	_check(own.size() <= 4, "<= 4 own materials")
	# ---- size: a titan next to the Shadow Knight
	var box := _vert_bounds(b, b.get_parent() as Node3D, true)
	var sk := _spawn(Vector3(-6, 0, 0), KNIGHT)
	await _wait(0.1)
	var skb := _vert_bounds(sk, sk.get_parent() as Node3D, false)
	var body_box := _vert_bounds(b, b.get_parent() as Node3D, false)
	print("knight (no lance) y %.2f..%.2f, z %.2f..%.2f, x %.2f..%.2f; with the lance top %.2f; Shadow Knight top %.2f" % [
		body_box.position.y, body_box.end.y, body_box.position.z, body_box.end.z, body_box.position.x, body_box.end.x,
		box.end.y, skb.end.y])
	_check(body_box.position.y >= -0.03, "nothing below the ground (%.3f)" % body_box.position.y)
	_check(body_box.end.y >= 3.9 and body_box.end.y <= 4.5, "crest top 3.9-4.5 m (%.2f)" % body_box.end.y)
	_check(body_box.end.y >= skb.end.y * 1.25 and box.end.y >= skb.end.y * 1.6, "taller than the Shadow Knight: 1.25 x (crest), 1.6 x (lance)")
	var fp := body_box.size.x * body_box.size.z
	var skfp := skb.size.x * skb.size.z
	print("footprint %.1f m2 vs Shadow Knight %.1f m2" % [fp, skfp])
	_check(fp >= skfp * 2.5, "footprint >= 2.5 x the Shadow Knight's")
	_check(box.end.y >= 5.2, "the carried lance rises above 5.2 m (%.2f)" % box.end.y)
	_check(body_box.size.z >= 3.6 and body_box.size.z <= 5.0, "length 3.6-5.0 m (%.2f)" % body_box.size.z)
	sk.get_parent().queue_free()
	# ---- rider glued to the Seat, lance level at the gallop, smoke auto
	var chest: Node3D = a.get_node("Root/Chest")
	var seat: Node3D = a.call(&"seat_node")
	var rest_off := chest.global_position - seat.global_position
	var trail := a.get_node("Fx/SmokeTrail") as GPUParticles3D
	_check(float(a.call(&"lance_pitch")) < -45.0, "lance carried high at rest (%.1f)" % float(a.call(&"lance_pitch")))
	_check(not trail.emitting, "no smoke standing")
	a.call(&"set_moving", 8.0)
	await _wait(0.8)
	var dev := 0.0
	var ymin := 99.0
	var ymax := -99.0
	for i: int in 60:
		await process_frame
		dev = maxf(dev, (chest.global_position - seat.global_position - rest_off).length())
		ymin = minf(ymin, chest.global_position.y)
		ymax = maxf(ymax, chest.global_position.y)
	var pitch_gal := float(a.call(&"lance_pitch"))
	print("gallop: rider-seat drift %.3f m, rider bob %.3f m, lance %.1f deg, smoke %s, galloping %s" % [dev, ymax - ymin,
		pitch_gal, trail.emitting, a.call(&"is_galloping")])
	_check(bool(a.call(&"is_galloping")), "gallops at 8 m/s")
	_check(dev < 0.02, "the knight stays on the seat (drift %.3f)" % dev)
	_check(ymax - ymin > 0.03, "the knight bobs with the gallop")
	_check(pitch_gal > -15.0, "the lance levels at the gallop (%.1f)" % pitch_gal)
	_check(trail.emitting, "smoke trail while galloping (auto)")
	a.call(&"set_gallop_smoke", false)
	await process_frame
	_check(not trail.emitting and not bool(a.call(&"is_gallop_smoke")), "set_gallop_smoke(false) stops the trail")
	a.call(&"set_moving", 0.0)
	await _wait(1.0)
	a.call(&"set_gallop_smoke", true)
	await process_frame
	_check(trail.emitting, "set_gallop_smoke(true) runs the trail standing")
	a.call(&"set_gallop_smoke", false)
	await process_frame
	_check(float(a.call(&"lance_pitch")) < -45.0, "lance back up after stopping")
	# ---- hit: horse and rider flash
	a.call(&"play_hit")
	await _wait(0.05)
	var fb := float((a.get_node("Root/Mount/Merged") as MeshInstance3D).get_instance_shader_parameter(&"hit_flash"))
	var fc := float((a.get_node("Root/Chest/Merged") as MeshInstance3D).get_instance_shader_parameter(&"hit_flash"))
	var fl := float((a.get_node("Root/Chest/ArmL/Merged") as MeshInstance3D).get_instance_shader_parameter(&"hit_flash"))
	print("hit flash: horse %.2f, rider %.2f, shield arm %.2f" % [fb, fc, fl])
	_check(fb > 0.3 and fc > 0.3 and fl > 0.3, "horse and rider flash on a hit")
	await _wait(0.5)
	# ---- attack: the lance strike
	a.call(&"play_attack")
	await _wait(0.14)
	var p_att := float(a.call(&"lance_pitch"))
	var arm_z := (a.get_node("Root/Chest/ArmR") as Node3D).position.z - 0.02
	print("attack: lance %.1f deg at 0.14 s, thrust %.2f m" % [p_att, arm_z])
	_check(absf(p_att) < 10.0, "the lance is level on the strike")
	_check(arm_z > 0.2, "the arm thrusts forward")
	await _wait(0.8)
	_check(a.get(&"_action") == &"", "attack finished")
	# ---- charge
	var got_hit: Array = [null]
	a.connect(&"charge_struck", func(at: Vector3) -> void: got_hit[0] = at, CONNECT_ONE_SHOT)
	var head_mi := a.get_node("Root/Chest/Head/Merged") as MeshInstance3D
	var g0 := float(head_mi.get_instance_shader_parameter(&"glow_boost"))
	a.call(&"play_charge")
	await _wait(0.12)
	var p_ch := float(a.call(&"lance_pitch"))
	var g1 := float(head_mi.get_instance_shader_parameter(&"glow_boost"))
	var lean := chest.rotation.x
	var tip_local := Vector3.ZERO
	if got_hit[0] != null:
		tip_local = (a.get_parent() as Node3D).global_transform.affine_inverse() * (got_hit[0] as Vector3)
	print("charge: lance %.1f deg, chest lean %.1f deg, crest glow %.2f -> %.2f, struck at %s (local)" % [p_ch,
		rad_to_deg(lean), g0, g1, tip_local])
	_check(absf(p_ch) < 6.0, "the lance is dead level on the charge")
	_check(lean > deg_to_rad(8.0), "the knight leans into the charge")
	_check(g1 > g0 + 0.3, "fires flare on the charge")
	_check(got_hit[0] != null and tip_local.z > 3.5 and tip_local.y > 1.8 and tip_local.y < 3.2,
		"charge_struck at the lance tip, ahead of the horse")
	await _wait(0.9)
	_check(a.get(&"_action") == &"", "charge finished")
	# ---- glows driven by the kit: crest, hooves, eyes, lance fuller
	var glows: Array = a.get(&"_glow_nodes")
	for pth: String in ["Root/Chest/Head/Merged", "Root/Mount/LegFL/Merged", "Root/Mount/Head/Merged", "Root/Chest/ArmR/Lance"]:
		_check(glows.has(a.get_node(pth)), "%s is a kit glow node" % pth)
	# ---- team colour
	var red := Color(0.85, 0.30, 0.12)
	b.call(&"set_team_color", red)
	await process_frame
	for pth: String in ["Root/Mount/Merged", "Root/Chest/Merged", "Root/Chest/ArmR/Lance"]:
		_check(_has_team(b.get_node(pth) as MeshInstance3D, red), "%s takes the team colour" % pth)
	b.call(&"set_team_color", Color(0.42, 0.22, 0.6))
	await process_frame
	var any := false
	for pth: String in ["Root/Mount/Merged", "Root/Chest/Merged", "Root/Chest/ArmR/Lance"]:
		var mi := b.get_node(pth) as MeshInstance3D
		for s: int in mi.mesh.get_surface_count():
			if mi.get_surface_override_material(s) != null:
				any = true
	_check(not any, "the kingdom colour restores the scene's own cloth")
	# ---- kit slot audit
	var K: GDScript = load(KITFIX)
	var slots: Dictionary = CharacterModel.INSTANCE_SLOTS
	var collisions := 0
	for g: Node in b.find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		if gi == b.get(&"_shadow") or gi is GPUParticles3D:
			continue
		var by_slot: Dictionary = {}
		var names: Array[String] = []
		for mat: Material in b.call(&"_materials_of", gi):
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
			_check((b.get(&"_flash_all_targets") as Array).has(gi), "%s flashed by the kit" % b.get_path_to(gi))
	_check(collisions == 0, "no instance-uniform slot collision (%d)" % collisions)
	# ---- death: dissolve, death_finished at ~1.7 s
	var done: Array = [-1.0]
	var t0 := Time.get_ticks_msec()
	var frames: Array = [0]
	a.connect(&"death_finished", func() -> void: done[0] = float(frames[0]) / 60.0, CONNECT_ONE_SHOT)
	a.call(&"set_moving", 6.0)
	await _wait(0.3)
	a.call(&"play_death")
	var body_mi := a.get_node("Root/Mount/Merged") as MeshInstance3D
	var mid_flash := 0.0
	var smoke_seen := false
	for i: int in 120:
		await process_frame
		frames[0] += 1
		mid_flash = maxf(mid_flash, float(body_mi.get_instance_shader_parameter(&"hit_flash")))
		smoke_seen = smoke_seen or trail.emitting
	var fade := body_mi.transparency
	var roll := (a.get_node("Root") as Node3D).rotation.z
	print("death: finished at %.2f s, roll %.0f deg, violet flare %.2f, fade %.2f, smoke %s (%d ms)" % [done[0],
		rad_to_deg(roll), mid_flash, fade, smoke_seen, Time.get_ticks_msec() - t0])
	_check(done[0] >= 1.55 and done[0] <= 1.85, "death_finished at 1.6-1.8 s (< 2.0 fallback)")
	_check(absf(roll) > deg_to_rad(70.0), "the horse falls onto its side")
	_check(mid_flash > 0.3, "violet dissolve flare")
	_check(fade > 0.9, "dissolved at the end")
	_check(smoke_seen, "smoke billows on the death")
	a.call(&"revive")
	await _wait(0.3)
	_check(body_mi.transparency < 0.01 and float(body_mi.get_instance_shader_parameter(&"hit_flash")) < 0.05,
		"revive clears the dissolve")
	_check(absf((a.get_node("Root") as Node3D).rotation.z) < 0.03, "revive resets the pose")
	_check(float(a.call(&"lance_pitch")) < -45.0, "revive: lance carried again")
	a.call(&"play_level_up")
	a.call(&"set_veterancy", 3)
	a.call(&"play_cast", &"none")
	a.call(&"play_fidget")
	await _wait(0.5)
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


func _has_team(mi: MeshInstance3D, c: Color) -> bool:
	for s: int in mi.mesh.get_surface_count():
		var ov := mi.get_surface_override_material(s) as ShaderMaterial
		if ov:
			var v: Variant = ov.get_shader_parameter(&"base_color")
			if v == null:
				v = ov.get_shader_parameter(&"cloth_color")
			if v is Color and (v as Color).is_equal_approx(c):
				return true
	return false


func _draw_instances(n: Node) -> int:
	var c := 0
	for g: Node in n.find_children("*", "GeometryInstance3D", true, false):
		if g is MeshInstance3D and (g as MeshInstance3D).mesh == null:
			continue
		c += 1
	return c


func _mesh_verts(mesh: Mesh) -> int:
	var c := 0
	for s: int in mesh.get_surface_count():
		c += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return c


func _vertices(n: Node) -> int:
	var c := 0
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		if (g as MeshInstance3D).mesh:
			c += _mesh_verts((g as MeshInstance3D).mesh)
	return c


func _materials(n: Node) -> Array:
	var out: Array = []
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow":
			continue
		for s: int in mi.mesh.get_surface_count():
			var mat := mi.get_surface_override_material(s)
			if mat == null:
				mat = mi.mesh.surface_get_material(s)
			if mat and not (mat in out):
				out.append(mat)
	return out


## Exact bounds of every vertex (blob skipped; the lance only when with_lance) in `frame` space.
func _vert_bounds(n: Node, frame: Node3D, with_lance: bool) -> AABB:
	var inv := frame.global_transform.affine_inverse()
	var lo := Vector3(INF, INF, INF)
	var hi := -lo
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow" or (mi.name == "Lance" and not with_lance):
			continue
		var xf := inv * mi.global_transform
		for s: int in mi.mesh.get_surface_count():
			for v: Vector3 in (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				var w := xf * v
				lo = lo.min(w)
				hi = hi.max(w)
	return AABB(lo, hi - lo)
