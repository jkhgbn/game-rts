extends SceneTree
## Task 13.V9 (Stagrunner model): art/units/nature/stagrunner/.
## Run: $GODOT --headless --path . -s tests/test_13_v9.gd --fixed-fps 60 --quit-after 5000
## Checks: headless instantiation (2 models: build + cache), the pair (Grove Stag MountModel + a CharacterModel rider
## seated with set_seated, hips on the Seat), unit hooks + signals on the root, attack_style lance_charge / windup 0,
## the cavalry rider budget (<= 20 parts, <= 12 draw instances, 0 lights, 0 particles) and the stag's own budget,
## materials (own <= 4, the rest Nature / kit palette), size (spear 2.0-2.4 m, blade above the head at rest), the
## spear carried upright at rest and couched level past the stag's nose at the gallop, the cloak draped at rest and
## streaming at the gallop, the lance_charge thrust in 3 directions at the gallop (the spear on the target line, the
## thrust, spear_struck once), play_charge (the stag's charge, a level couched lunge, spear_struck(charge), blade
## flare, is_charging; an attack during a charge keeps the stag's charge), the auto-aim from the owning unit's
## attack_target, glows, hit flash, team colour (cowl + pennon), the kit slot audit, death / revive, hooks before
## _ready, transparency. Prints "PASS 13.v9" or "FAIL 13.v9: <reasons>".

const TASK_ID := "13.v9"
const SCENE := "res://art/units/nature/stagrunner/stagrunner.tscn"
const STAG_SCENE := "res://art/units/mounts/grove_stag/grove_stag.tscn"
const OWN_DIR := "res://art/units/nature/stagrunner/"
## Faces pass 2026-09-28: the shared FaceKit face material (eyes / brows / lips, 1 draw call) + glow probe.
const FaceProbe := preload("res://tests/face_probe.gd")
const KITFIX := "res://art/units/kit/tools/kitfix_glow_check.gd"
const SPEED := 7.8
## Targets for the gallop thrust (unit frame, +Z forward, +X right) and the expected spear yaw (deg).
const DIRS: Array[Vector3] = [Vector3(0, 0, 1), Vector3(-0.42, 0, 0.9), Vector3(0.82, 0, 0.57)]
const NAMES: Array[String] = ["front", "front-left", "front-right"]

var _fails: PackedStringArray = PackedStringArray()
var _world: Node3D
var _cam: Camera3D


func _initialize() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	_cam = Camera3D.new()   # tier 0 (close) so the full animation runs
	_cam.position = Vector3(0, 8, 12)
	_world.add_child(_cam)
	_cam.look_at_from_position(_cam.position, Vector3.ZERO)
	_cam.make_current()
	_run()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAILED: ", what)


func _wait(sec: float) -> void:
	for i: int in int(ceil(sec * 60.0)):
		await process_frame


func _spawn(at: Vector3, yaw_deg: float = 0.0, pre: Callable = Callable()) -> Node3D:
	var holder := Node3D.new()
	holder.position = at
	holder.rotation.y = deg_to_rad(yaw_deg)
	_world.add_child(holder)
	var m: Node3D = (load(SCENE) as PackedScene).instantiate()
	if pre.is_valid():
		pre.call(m)
	holder.add_child(m)
	return m


## Waits until the rider's attack time reaches t (s), max 1 s.
func _until_attack(rider: Node, t: float) -> void:
	for i: int in 60:
		if rider.get(&"_action") != &"attack" or float(rider.get(&"_action_t")) >= t:
			return
		await process_frame


func _until_charge(rider: Node, t: float) -> void:
	for i: int in 60:
		if float(rider.get(&"_chg_t")) >= t:
			return
		await process_frame


## Horizontal yaw (deg) of a world direction in the holder's frame (+ = right).
func _yaw_in(holder: Node3D, d: Vector3) -> float:
	var l := holder.global_transform.basis.inverse() * d
	return rad_to_deg(atan2(l.x, l.z))


func _run() -> void:
	_check(ResourceLoader.exists(SCENE), "scene exists")
	var a := _spawn(Vector3(0, 0, 0))
	var b := _spawn(Vector3(10, 0, 0))
	await _wait(0.3)
	var stag: Node3D = a.call(&"mount_model")
	var rider: Node3D = a.call(&"rider_model")
	var holder := a.get_parent() as Node3D
	_check(stag is MountModel, "Stag is the Grove Stag MountModel")
	_check(rider is CharacterModel and not (rider is MountModel), "Rider is a CharacterModel")
	_check(stag != null and stag.scene_file_path == STAG_SCENE, "the 13.V5 stag scene")
	_check(bool(rider.call(&"is_seated")) and rider.call(&"seat_mount") == stag, "rider seated on the stag (set_seated)")
	_check(bool(a.call(&"is_seated")), "is_seated on the root")
	for hk: String in ["set_moving", "play_attack", "play_charge", "play_hit", "play_death", "set_team_color",
			"set_status", "revive", "play_cast", "play_level_up", "set_veterancy", "set_barded", "is_barded", "play_fidget",
			"set_seated", "is_seated", "set_carrying", "set_aim_target", "get_spear_tip", "get_spear_dir",
			"spear_elevation", "is_charging", "gait_phase", "gallop_blend", "is_galloping", "authored_mesh_count",
			"rider_model", "mount_model"]:
		_check(a.has_method(hk), "hook %s" % hk)
	_check(a.has_signal(&"death_finished") and a.has_signal(&"spear_struck"), "signals death_finished, spear_struck")
	_check(a.get(&"attack_style") == &"lance_charge" and rider.get(&"attack_style") == &"lance_charge",
		"attack_style lance_charge")
	_check(float(a.get(&"attack_windup")) == 0.0 and float(rider.get(&"attack_windup")) == 0.0, "melee windup 0")
	_check(&"stride_speed" in a, "stride_speed property (Unit writes it)")
	# ---- hips on the seat
	var seat: Node3D = stag.call(&"seat_node")
	var hips: Node3D = rider.get_node("Root/Hips")
	var hd := hips.global_position.distance_to(seat.global_position)
	print("hips to seat %.3f m" % hd)
	_check(hd < 0.12, "the rider's hips sit on the stag's Seat (%.3f)" % hd)
	# ---- budgets
	var rb: Node3D = b.call(&"rider_model")
	var sb: Node3D = b.call(&"mount_model")
	var parts := int(rb.call(&"authored_mesh_count"))
	var inst := _draw_instances(rb)
	var s_inst := _draw_instances(sb)
	var lights := b.find_children("*", "Light3D", true, false).size()
	var particles := rb.find_children("*", "GPUParticles3D", true, false).size()
	var verts := _vertices(rb)
	print("rider budget: parts %d, draw instances %d, vertices %d, lights %d, particles %d; stag instances %d" % [parts,
		inst, verts, lights, particles, s_inst])
	for g: Node in rb.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh:
			print("  %s: %d surfaces, %d vertices, shadow %s" % [rb.get_path_to(mi), mi.mesh.get_surface_count(),
				_mesh_verts(mi.mesh), mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF])
	_check(int(rider.call(&"authored_mesh_count")) == parts, "authored count equal for the cached instance")
	_check(parts <= 20, "rider parts %d <= 20" % parts)
	_check(inst <= 12, "rider draw instances %d <= 12" % inst)
	_check(s_inst <= 8, "stag draw instances unchanged (%d <= 8)" % s_inst)
	_check(lights == 0, "0 lights")
	_check(particles == 0, "0 particle systems on the rider")
	_check(verts <= 12000, "rider vertices %d <= 12000" % verts)
	# ---- materials
	var own: Array = []
	for mat: Material in _materials(rb):
		var path := mat.resource_path
		if path.begins_with(OWN_DIR):
			if not own.has(path.get_file()):
				own.append(path.get_file())
		else:
			_check(path.begins_with("res://art/units/nature/materials/") or path.begins_with("res://art/units/kit/materials/")
				or FaceProbe.is_face_mat(mat), "material %s is a Nature / kit palette entry (or the face)" % path)
	print("own materials (%d): %s" % [own.size(), ", ".join(PackedStringArray(own))])
	_check(own.size() <= 4, "<= 4 own materials")
	# ---- size, the carry at rest
	var hb := b.get_parent() as Node3D
	var spear := rider.get_node("Root/Chest/Spear") as MeshInstance3D
	var sp_len := spear.mesh.get_aabb().size.y
	var head := rider.get_node("Root/Chest/Head") as Node3D
	var tip0 := a.call(&"get_spear_tip") as Vector3
	var el0 := float(a.call(&"spear_elevation"))
	var rbox := _vert_bounds(rb, hb)
	print("rider bounds y %.2f..%.2f; spear %.2f m, rest elevation %.1f, tip y %.2f (head %.2f)" % [rbox.position.y,
		rbox.end.y, sp_len, el0, tip0.y, head.global_position.y])
	_check(sp_len >= 2.0 and sp_len <= 2.4, "shortspear 2.0-2.4 m (%.2f)" % sp_len)
	_check(rbox.position.y > 0.6, "rider off the ground (feet at %.2f)" % rbox.position.y)
	_check(rbox.end.y >= 2.8 and rbox.end.y <= 3.6, "rider + spear top 2.8-3.6 m (%.2f)" % rbox.end.y)
	_check(el0 > 60.0, "spear carried upright at rest (%.1f)" % el0)
	_check(tip0.y > head.global_position.y + 0.8, "the blade stands above the rider's head at rest")
	var cloak := rider.get_node("Root/Chest/Cloak") as Node3D
	var tail := rider.get_node("Root/Chest/Cloak/CloakTail") as Node3D
	var drape := rad_to_deg(cloak.rotation.x + tail.rotation.x)
	# ---- walk vs gallop from set_moving: couch + streaming cloak
	a.call(&"set_moving", 1.7)
	await _wait(1.2)
	var g_walk := float(a.call(&"gallop_blend"))
	var el_walk := float(a.call(&"spear_elevation"))
	a.call(&"set_moving", SPEED)
	await _wait(1.0)
	var y_min := 99.0
	var y_max := -99.0
	var st_max := 0.0
	for i: int in 60:
		await process_frame
		y_min = minf(y_min, hips.global_position.y)
		y_max = maxf(y_max, hips.global_position.y)
		st_max = maxf(st_max, rad_to_deg(cloak.rotation.x + tail.rotation.x))
	var g_gal := float(a.call(&"gallop_blend"))
	var el_gal := float(a.call(&"spear_elevation"))
	var tip_l := holder.global_transform.affine_inverse() * (a.call(&"get_spear_tip") as Vector3)
	# the stag's nose: its skull axis front point SK_F (model space; the stag shares the holder's frame)
	var nose_l: Vector3 = stag.get_script().get_script_constant_map().get("SK_F", Vector3(0, 1.84, 1.48))
	print("gait: walk gallop %.2f (spear %.1f), gallop %.2f (spear %.1f), tip z %.2f vs nose z %.2f, bob %.3f, cloak drape %.1f -> stream %.1f" % [
		g_walk, el_walk, g_gal, el_gal, tip_l.z, nose_l.z, y_max - y_min, drape, st_max])
	_check(g_walk < 0.2 and el_walk > 55.0, "walks at 1.7 m/s with the spear carried upright")
	_check(g_gal > 0.8 and bool(a.call(&"is_galloping")), "gallops at 7.8 m/s")
	_check(absf(el_gal) < 15.0, "the spear is couched level at the gallop (%.1f)" % el_gal)
	_check(tip_l.z > nose_l.z + 0.15, "the couched blade reaches past the stag's nose")
	_check(y_max - y_min > 0.04, "the rider bobs with the gallop")
	_check(drape > 45.0 and drape < 85.0, "the cloak drapes over the rump at rest (%.1f)" % drape)
	_check(st_max > 85.0, "the leaf cloak streams back at the gallop (%.1f)" % st_max)
	# ---- lance_charge thrust at the gallop in 3 directions
	var struck: Array = []
	a.connect(&"spear_struck", func(tip: Vector3, dir: Vector3, charge: bool) -> void: struck.append([tip, dir, charge]))
	var tgt := Node3D.new()
	_world.add_child(tgt)
	for i: int in 3:
		tgt.global_position = holder.global_transform * (DIRS[i].normalized() * 8.0)
		a.call(&"set_aim_target", tgt)
		await _wait(0.2)
		struck.clear()
		a.call(&"play_attack")
		await _until_attack(rider, 0.06)
		var tip_a := a.call(&"get_spear_tip") as Vector3
		await _until_attack(rider, 0.125)
		await process_frame
		var tip_b := a.call(&"get_spear_tip") as Vector3
		var d := a.call(&"get_spear_dir") as Vector3
		var yaw := _yaw_in(holder, d)
		var want := clampf(_yaw_in(holder, tgt.global_position - (a.call(&"get_spear_tip") as Vector3)), -28.0, 70.0)
		var el := float(a.call(&"spear_elevation"))
		var push := (tip_b - tip_a).dot(d)
		await _wait(0.5)
		print("thrust %s: spear yaw %.1f (target %.1f), elevation %.1f, thrust %.2f m, struck %d" % [NAMES[i], yaw, want,
			el, push, struck.size()])
		_check(absf(yaw - want) < 22.0, "%s: the spear points at the target" % NAMES[i])
		_check(el < 5.0 and el > -35.0, "%s: the spear is levelled for the thrust" % NAMES[i])
		_check(push > 0.15, "%s: the spear drives forward at the strike (%.2f)" % [NAMES[i], push])
		_check(struck.size() == 1 and not bool(struck[0][2]), "%s: spear_struck once (attack)" % NAMES[i])
	# ---- the charge
	tgt.global_position = holder.global_transform * Vector3(0, 0, 8)
	await _wait(0.6)
	var sp_gl0 := float(spear.get_instance_shader_parameter(&"glow_boost"))
	struck.clear()
	a.call(&"play_charge")
	await process_frame
	var st_charge: bool = stag.get(&"_action") == &"charge"
	var charging := bool(a.call(&"is_charging"))
	a.call(&"play_attack")   # the hit arrives with the charge: the stag keeps its charge
	await process_frame
	var st_keep: bool = stag.get(&"_action") == &"charge"
	await _until_charge(rider, 0.11)
	await process_frame
	var el_c := float(a.call(&"spear_elevation"))
	var sp_gl1 := float(spear.get_instance_shader_parameter(&"glow_boost"))
	await _wait(1.0)
	var charged_struck := 0
	for s: Array in struck:
		if bool(s[2]):
			charged_struck += 1
	print("charge: stag %s (kept %s), is_charging %s, elevation %.1f, blade glow %.2f -> %.2f, charge strikes %d, after %s" % [
		st_charge, st_keep, charging, el_c, sp_gl0, sp_gl1, charged_struck, a.call(&"is_charging")])
	_check(st_charge and st_keep, "play_charge plays the stag's charge; an attack meanwhile keeps it")
	_check(charging and not bool(a.call(&"is_charging")), "is_charging during the 0.85 s charge only")
	_check(el_c < 5.0 and el_c > -20.0, "the charge couches the spear level (%.1f)" % el_c)
	_check(sp_gl0 > 0.5 and sp_gl1 > sp_gl0 * 1.5, "the blade flares at the charge")
	_check(charged_struck == 1, "spear_struck(charge = true) once")
	a.call(&"set_moving", 0.0)
	await _wait(0.8)
	# ---- glows: the brow seed (head) and the spear
	var head_mi := rider.get_node("Root/Chest/Head/Merged") as MeshInstance3D
	_check(float(head_mi.get_instance_shader_parameter(&"glow_boost")) > 0.5, "the brow seed glows")
	# ---- auto aim from the owning unit's attack_target
	var us := GDScript.new()
	us.source_code = "extends Node3D\nvar attack_target: Node3D = null\n"
	us.reload()
	var unit := Node3D.new()
	unit.set_script(us)
	unit.position = Vector3(-10, 0, 0)
	_world.add_child(unit)
	var vis := Node3D.new()
	unit.add_child(vis)
	var c: Node3D = (load(SCENE) as PackedScene).instantiate()
	vis.add_child(c)
	var t2 := Node3D.new()
	_world.add_child(t2)
	t2.global_position = Vector3(-10, 0, 0) + Vector3(0.8, 0, 0.6).normalized() * 8.0
	unit.set(&"attack_target", t2)
	await _wait(0.2)
	c.call(&"play_attack")
	await _wait(0.13)
	var yaw_auto := _yaw_in(unit, c.call(&"get_spear_dir") as Vector3)
	print("auto aim (target 53 deg right): spear yaw %.1f" % yaw_auto)
	_check(yaw_auto > 30.0, "play_attack aims at the owner's attack_target by itself")
	# ---- hit flash on rider and stag
	a.call(&"play_hit")
	await _wait(0.05)
	var f_r := float((rider.get_node("Root/Chest/Merged") as MeshInstance3D).get_instance_shader_parameter(&"hit_flash"))
	var f_s := float((stag.get_node("Root/Mount/Merged") as MeshInstance3D).get_instance_shader_parameter(&"hit_flash"))
	print("hit flash rider %.2f, stag %.2f" % [f_r, f_s])
	_check(f_r > 0.3 and f_s > 0.3, "rider and stag flash on hits")
	await _wait(0.4)
	# ---- team colour: cloth only (cowl on the head, the pennon on the spear)
	var red := Color(0.85, 0.30, 0.12)
	b.call(&"set_team_color", red)
	await process_frame
	for path: String in ["Root/Chest/Head/Merged", "Root/Chest/Spear"]:
		var mi := rb.get_node(path) as MeshInstance3D
		var got_red := false
		var only_cloth := true
		for s: int in mi.mesh.get_surface_count():
			var ov := mi.get_surface_override_material(s) as ShaderMaterial
			if ov:
				var bn := mi.mesh.surface_get_material(s).resource_path.get_file().get_basename()
				if not (bn.ends_with("_cloth") or bn.ends_with("_cloth_dark")):
					only_cloth = false
				if ov.get_shader_parameter(&"base_color") == red:
					got_red = true
		_check(got_red and only_cloth, "%s takes the team colour (cloth surfaces only)" % path)
	# ---- kit slot audit (KITFIX rules) on rider + stag
	var K: GDScript = load(KITFIX)
	var slots: Dictionary = CharacterModel.INSTANCE_SLOTS
	var collisions := 0
	for owner: Node3D in [rider, stag]:
		for g: Node in owner.find_children("*", "GeometryInstance3D", true, false):
			var gi := g as GeometryInstance3D
			if gi == owner.get(&"_shadow") or gi is GPUParticles3D:
				continue
			var by_slot: Dictionary = {}
			var names: Array[String] = []
			for mat: Material in owner.call(&"_materials_of", gi):
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
				_check((owner.get(&"_flash_all_targets") as Array).has(gi), "%s flashed by the kit" % owner.get_path_to(gi))
	print("slot collisions: ", collisions)
	_check(collisions == 0, "no instance-uniform slot collision")
	# ---- misc hooks run
	a.call(&"play_level_up")
	a.call(&"set_veterancy", 4)
	_check(bool(a.call(&"set_status", &"haste", true)), "set_status haste handled")
	a.call(&"play_cast", &"any_spell")
	await _wait(0.3)
	var el_cast := float(a.call(&"spear_elevation"))
	a.call(&"set_barded", true)
	await _wait(0.6)
	_check(el_cast > 70.0, "play_cast raises the spear (%.1f)" % el_cast)
	_check(bool(a.call(&"is_barded")), "barding on the stag")
	a.call(&"set_status", &"haste", false)
	a.call(&"set_barded", false)
	# ---- death: the rider rides the stag's fall; revive re-seats
	var done: Array = [false]
	a.connect(&"death_finished", func() -> void: done[0] = true, CONNECT_ONE_SHOT)
	a.call(&"set_moving", SPEED)
	await _wait(0.3)
	a.call(&"play_death")
	await _wait(0.6)
	var hd2 := hips.global_position.distance_to(seat.global_position)
	var gl_dead := float(head_mi.get_instance_shader_parameter(&"glow_boost"))
	var sp_dead := float(spear.get_instance_shader_parameter(&"glow_boost"))
	print("death 0.6 s: hips to seat %.2f, glow head %.2f, spear %.2f" % [hd2, gl_dead, sp_dead])
	_check(hd2 < 0.2, "the rider rides the stag's fall")
	_check(gl_dead == 0.0 and sp_dead == 0.0, "glows die")
	await _wait(0.7)
	_check(done[0], "death_finished within 1.3 s")
	a.call(&"revive")
	await _wait(0.5)
	_check(bool(rider.call(&"is_seated")) and hips.global_position.distance_to(seat.global_position) < 0.12,
		"revive: seated again")
	_check(float(a.call(&"spear_elevation")) > 60.0, "revive: spear carried")
	# ---- hooks before _ready
	var e := _spawn(Vector3(-20, 0, 8), 0.0, func(m: Node3D) -> void:
		m.call(&"set_team_color", Color(0.85, 0.30, 0.12))
		m.call(&"set_aim_target", Vector3(0, 0, 100))
		m.call(&"set_moving", SPEED))
	await _wait(0.6)
	_check(bool((e.call(&"rider_model") as Node).call(&"is_seated")) and float(e.call(&"gallop_blend")) > 0.5,
		"hooks before _ready are kept")
	# ---- transparency (Unit fade) tolerated
	for g: Node in b.find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).transparency = 0.5
	await _wait(0.1)
	_finish()


func _finish() -> void:
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


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
			var mat := mi.mesh.surface_get_material(s)
			if mat and not (mat in out):
				out.append(mat)
	return out


## Exact bounds of every vertex (the blob skipped) in `frame` space.
func _vert_bounds(n: Node, frame: Node3D) -> AABB:
	var inv := frame.global_transform.affine_inverse()
	var lo := Vector3(INF, INF, INF)
	var hi := -lo
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow" or not mi.is_visible_in_tree():
			continue
		var xf := inv * mi.global_transform
		for s: int in mi.mesh.get_surface_count():
			for v: Vector3 in (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				var w := xf * v
				lo = lo.min(w)
				hi = hi.max(w)
	return AABB(lo, hi - lo)
