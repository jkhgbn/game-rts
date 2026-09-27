extends SceneTree
## Task 11.V5: the Mender with the champion class weapons (art/units/champions/mender/).
## Headless:  $GODOT --headless --path . -s tests/test_11_v5.gd --fixed-fps 60 --quit-after 6000
##   the censer staff is tagged (hidden with every class, back with &""), identity props kept (wicker pack, jars,
##   pennant), budgets per class (<= 26 authored, <= 16 draw instances, <= 5 own materials, 0 lights), her grips (hand_r
##   = the staff fist, hand_l = the left fist, the quiver on the pack's left side, clear of the basket),
##   get_beam_origin() = the weapon tip with a class (the censer without), no censer puff on a class attack release,
##   the class casts: Mending Draught (draught shown, tossed, breaks ahead), Soothing Circle (jar out of the pack, thrown,
##   lands 5 m ahead or at set_cast_point), Lifeline (burst at the free hand, weapon raised per class), interrupted throw
##   and death give the jar back, the 12 class skills play and end, archetype casts swing the censer again after &"".
##   Prints "PASS 11.v5" or "FAIL 11.v5: <reasons>".
## Shots (windowed):  Godot_v4.7.2-stable_win64.exe --path . -s tests/test_11_v5.gd --fixed-fps 60 --quit-after 9000 -- --shots
##   docs/art/screens/champion_mender_classes.png: 5 columns (archetype, spear, sword_shield, two_hand, wizard) x rows
##   front 3/4, back 3/4, Mending Draught, Soothing Circle (jar cocked), Soothing Circle (jar in flight), Lifeline, then
##   the 40 m game camera strip (colour, then unlit black silhouettes, nearest x2).

const TASK_ID := "11.v5"
const SCENE := "res://art/units/champions/mender/mender.tscn"
const OWN_DIR := "res://art/units/champions/mender/"
const CLASSES: Array[StringName] = [&"", &"spear", &"sword_shield", &"two_hand", &"wizard"]
const SKILLS: Dictionary = {
	&"spear": [&"lunge", &"hobbling_javelin", &"skewer"],
	&"sword_shield": [&"riposte", &"second_wind", &"shield_throw"],
	&"two_hand": [&"cleave", &"crushing_blow", &"whirlwind"],
	&"wizard": [&"arc_bolt", &"slipstep", &"starfall"],
}
const SKILL_LEN: Dictionary = {&"riposte": 4.0, &"whirlwind": 2.0, &"second_wind": 1.4, &"starfall": 1.2}
const GRIP := Vector3(0.535, 0.94, 0.22)
const HAND_L := Vector3(-0.55, 0.78, 0.125)
const FIRE := Color(0.85, 0.30, 0.12)
const SHADOW := Color(0.42, 0.22, 0.60)
const ICE := Color(0.45, 0.75, 0.95)
const NATURE := Color(0.35, 0.70, 0.25)
const KINGDOMS: Array[Color] = [FIRE, SHADOW, ICE, NATURE, FIRE]
const SENTINEL := Vector3(99, 99, 99)

var _fails: PackedStringArray = PackedStringArray()
var _world: Node3D
var _cam: Camera3D
var _env: Environment


func _initialize() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	if "--shots" in OS.get_cmdline_user_args():
		_shots.call_deferred()
	else:
		_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAILED: ", what)


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _wait(sec: float) -> void:
	await _frames(int(ceil(sec * 60.0)))


func _spawn(at: Vector3, variant: int = 0, team: Color = FIRE, yaw: float = 0.0) -> Node3D:
	var holder := Node3D.new()
	holder.position = at
	holder.rotation.y = yaw
	_world.add_child(holder)
	var m: Node3D = (load(SCENE) as PackedScene).instantiate()
	m.call(&"set_variant", variant)
	m.call(&"set_team_color", team)
	holder.add_child(m)
	return m


# ================================================================ headless test

func _run() -> void:
	var a := _spawn(Vector3(0, 0, 0))
	var b := _spawn(Vector3(4, 0, 0), 1, SHADOW)
	# a class set before _ready: applied without the pop, the censer hidden from the start
	var c: Node3D = (load(SCENE) as PackedScene).instantiate()
	c.call(&"set_weapon_class", &"wizard")
	var hc := Node3D.new()
	hc.position = Vector3(-4, 0, 0)
	_world.add_child(hc)
	hc.add_child(c)
	await _frames(4)
	_check(c.call(&"weapon_class") == &"wizard" and not (c.get_node(^"Root/Chest/ArmR/Staff") as Node3D).visible,
		"class before _ready: censer staff hidden")
	_check(a.has_method(&"set_cast_point"), "set_cast_point hook")

	await _check_classes(a)
	await _check_puff(a)
	await _check_casts(a)
	await _check_interrupt(b)
	await _check_skills(b)
	await _check_back_to_censer(a)
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


## Per class: tag, identity props, budgets, grips, beam origin.
func _check_classes(m: Node3D) -> void:
	var staff := m.get_node(^"Root/Chest/ArmR/Staff") as Node3D
	var jars := m.get_node(^"Root/Chest/Jars") as Node3D
	var authored: int = m.call(&"authored_mesh_count")
	var chest_v0 := _verts(m.get_node(^"Root/Chest/Merged") as MeshInstance3D)
	print("authored meshes: %d, archetype chest vertices %d" % [authored, chest_v0])
	_check(authored <= 26, "authored meshes <= 26 (%d)" % authored)
	for cls: StringName in CLASSES:
		m.call(&"set_weapon_class", cls, false)
		await _frames(3)
		var nm := String(cls) if cls != &"" else "(archetype)"
		_check(m.call(&"weapon_class") == cls, "%s: weapon_class()" % nm)
		_check(staff.visible == (cls == &""), "%s: censer staff %s" % [nm, "shown" if cls == &"" else "hidden"])
		_check(jars.visible, "%s: the jars stay on the pack" % nm)
		_check(_pivot_has(m, "Root/Chest", "mender_painted") and _pivot_has(m, "Root/Chest", "mender_pennon"),
			"%s: wicker pack, apron and pennant kept (Chest)" % nm)
		var chest_v := _verts(m.get_node(^"Root/Chest/Merged") as MeshInstance3D)
		_check(chest_v >= chest_v0, "%s: no pack part dropped (chest %d vs %d)" % [nm, chest_v, chest_v0])
		_check(not (m.get_node(^"Root/Chest/ArmL/Jar") as Node3D).visible, "%s: the throw jar hidden at rest" % nm)
		var draws := _draw_instances(m)
		_check(draws <= 16, "%s: <= 16 draw instances (%d)" % [nm, draws])
		_check(m.find_children("*", "Light3D", true, false).is_empty(), "%s: 0 lights" % nm)
		var own := 0
		for p: String in _materials(m):
			if p.begins_with(OWN_DIR):
				own += 1
		_check(own <= 5, "%s: <= 5 own materials (%d)" % [nm, own])
		_check(int(m.call(&"authored_mesh_count")) == authored, "%s: authored count unchanged" % nm)
		var steam := m.get_node(^"Root/Chest/ArmR/Staff/Censer/Steam") as GPUParticles3D
		if cls != &"":
			await _frames(2)
			_check(not steam.emitting, "%s: censer steam off while hidden" % nm)
		var beam: Vector3 = m.call(&"get_beam_origin")
		var tip: Variant = m.call(&"get_weapon_tip")
		if cls == &"":
			var censer := m.get_node(^"Root/Chest/ArmR/Staff/Censer") as Node3D
			_check(tip == null and beam.y < censer.global_position.y - 0.15, "archetype: beam origin at the kettle")
		else:
			_check(tip is Vector3 and beam.distance_to(tip) < 0.001, "%s: get_beam_origin = the weapon tip" % nm)
			var lt := m.to_local(beam)
			print("  %-12s beam origin (model) %s" % [nm, lt])
			_check(lt.y > 0.35 and lt.length() < 3.2, "%s: tip near her (%s)" % [nm, lt])
		if cls == &"spear":
			_check(_pivot_has(m, "Root/Chest", "weapon_leather"), "spear: the quiver merged on the Chest")
	# grips (constant per scene)
	var gr: Transform3D = m.call(&"weapon_slot_xf", &"hand_r")
	var gl: Transform3D = m.call(&"weapon_slot_xf", &"hand_l")
	_check(gr.origin.is_equal_approx(GRIP), "hand_r = the censer-staff fist (%s)" % gr.origin)
	_check(gl.origin.is_equal_approx(HAND_L), "hand_l = the left fist (%s)" % gl.origin)
	# the quiver is lashed on the pack's left side: its whole mesh left of the basket (x < -0.28 below the rim flare)
	var q: Transform3D = m.call(&"weapon_grip_xf", &"quiver")
	var qm: Mesh = (load("res://art/units/champions/weapons/champion_weapon_kit.gd") as GDScript).call(&"piece_mesh", &"quiver")
	var max_x := -INF
	for s: int in qm.get_surface_count():
		for v: Vector3 in (qm.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
			var w := q * v
			if w.y < 1.45:
				max_x = maxf(max_x, w.x)
	print("quiver grip %s, inner edge below the rim x = %.3f" % [q.origin, max_x])
	_check(max_x < -0.28, "quiver clear of the wicker basket (inner edge x %.3f)" % max_x)
	_check(q.origin.z < -0.3 and q.origin.x < -0.35, "quiver on the pack's left side (%s)" % q.origin)


## No censer puff on the release of a class attack; the archetype jab still puffs.
func _check_puff(m: Node3D) -> void:
	var burst := m.get_node(^"Fx/Burst") as GPUParticles3D
	for cls: StringName in [&"two_hand", &"wizard", &""]:
		m.call(&"set_weapon_class", cls, false)
		await _frames(50)
		burst.emitting = false
		burst.position = SENTINEL
		m.call(&"play_attack")
		await _wait(0.3)
		var puffed := burst.position != SENTINEL
		if cls == &"":
			_check(puffed, "archetype jab: censer puff")
		else:
			_check(not puffed, "%s attack release: no censer puff" % cls)
		await _wait(0.6)


## The three archetype casts with each class weapon.
func _check_casts(m: Node3D) -> void:
	var burst := m.get_node(^"Fx/Burst") as GPUParticles3D
	var jar := m.get_node(^"Root/Chest/ArmL/Jar") as Node3D
	var arm_l := m.get_node(^"Root/Chest/ArmL") as Node3D
	var arm_r := m.get_node(^"Root/Chest/ArmR") as Node3D
	var fx := m.get_node(^"Fx")
	for cls: StringName in CLASSES.slice(1):
		m.call(&"set_weapon_class", cls, false)
		await _frames(40)
		# ---- Soothing Circle: the jar out of the pack, thrown, lands 5 m ahead
		burst.position = SENTINEL
		m.call(&"play_cast", &"soothing_circle")
		await _until(m, 0.38)
		_check(jar.visible and jar.get_parent() == arm_l, "%s soothing: the jar in the left hand" % cls)
		var held := m.to_local(jar.global_position)
		_check(held.y > 1.35, "%s soothing: jar cocked over the shoulder (y %.2f)" % [cls, held.y])
		await _until(m, 0.62)
		_check(jar.visible and jar.get_parent() == fx, "%s soothing: the jar flies (under Fx)" % cls)
		var fly := m.to_local(jar.global_position)
		_check(fly.z > 0.8 and fly.y > 1.0, "%s soothing: jar in the air ahead (%s)" % [cls, fly])
		await _wait(0.8)
		_check(not jar.visible and jar.get_parent() == arm_l, "%s soothing: jar back in the hand, hidden" % cls)
		_check(burst.position.distance_to(Vector3(0, 0.08, 5.0)) < 0.05, "%s soothing: shatters 5 m ahead (%s)" % [cls, burst.position])
		_check(m.get(&"_action") == &"", "%s soothing: finished" % cls)
		# with a cast point (2 m right, 7 m ahead, in world space)
		m.call(&"set_cast_point", m.to_global(Vector3(2.0, 0.0, 7.0)))
		m.call(&"play_cast", &"soothing_circle")
		await _wait(1.3)
		_check(burst.position.distance_to(Vector3(2.0, 0.08, 7.0)) < 0.05, "%s soothing: lands at the cast point (%s)" % [cls, burst.position])
		# ---- Mending Draught: shown at the chest, tossed, breaks 3 m ahead at chest height
		burst.position = SENTINEL
		m.call(&"play_cast", &"mending_draught")
		await _until(m, 0.30)
		_check(jar.visible and jar.get_parent() == arm_l, "%s draught: in the hand" % cls)
		await _wait(0.9)
		_check(not jar.visible, "%s draught: gone after the toss" % cls)
		_check(burst.position.distance_to(Vector3(0, 1.0, 3.0)) < 0.05, "%s draught: breaks ahead (%s)" % [cls, burst.position])
		# ---- Lifeline: the free hand reaches out (burst there), the weapon is raised
		burst.position = SENTINEL
		m.call(&"play_cast", &"lifeline")
		await _until(m, 0.56)
		var rx := arm_r.rotation.x
		var lx := arm_l.rotation.x
		_check(lx < deg_to_rad(-60.0), "%s lifeline: free arm reaches out (%.0f deg)" % [cls, rad_to_deg(lx)])
		var raised := rx > deg_to_rad(20.0) if cls == &"two_hand" else rx < deg_to_rad(-15.0)
		_check(raised, "%s lifeline: weapon raised (arm %.0f deg)" % [cls, rad_to_deg(rx)])
		_check(burst.position != SENTINEL and burst.position.z > 0.25 and burst.position.x < 0.0,
			"%s lifeline: burst at the free hand (%s)" % [cls, burst.position])
		await _wait(0.6)
		_check(m.get(&"_action") == &"", "%s lifeline: finished" % cls)


## An attack interrupting the throw, and a death, give the jar back.
func _check_interrupt(m: Node3D) -> void:
	var jar := m.get_node(^"Root/Chest/ArmL/Jar") as Node3D
	m.call(&"set_weapon_class", &"spear", false)
	await _frames(20)
	m.call(&"play_cast", &"soothing_circle")
	await _until(m, 0.3)
	_check(jar.visible, "interrupt: jar in hand before")
	m.call(&"play_attack")
	await _frames(3)
	_check(not jar.visible, "interrupt: an attack puts the jar away")
	await _wait(0.7)
	m.call(&"play_cast", &"mending_draught")
	await _until(m, 0.3)
	var done: Array = [false]
	m.connect(&"death_finished", func() -> void: done[0] = true, CONNECT_ONE_SHOT)
	m.call(&"play_death")
	await _frames(3)
	_check(not jar.visible, "death: the jar put away")
	await _wait(1.2)
	_check(done[0], "death_finished with a class weapon")
	m.call(&"revive")
	await _frames(5)
	_check(m.call(&"weapon_class") == &"spear" and not (m.get_node(^"Root/Chest/ArmR/Staff") as Node3D).visible,
		"revive keeps the class (censer still hidden)")


## The 12 class skills (kit poses with her grips) play and end.
func _check_skills(m: Node3D) -> void:
	for cls: StringName in SKILLS:
		m.call(&"set_weapon_class", cls, false)
		await _frames(10)
		m.call(&"play_attack")
		await _wait(0.9)
		_check(m.get(&"_action") == &"", "%s attack style ends" % cls)
		for id: StringName in SKILLS[cls]:
			m.call(&"play_cast", id)
			await _wait(0.2)
			_check(m.get(&"_action") == &"cast", "%s plays" % id)
			await _wait(float(SKILL_LEN.get(id, 1.1)))
			_check(m.get(&"_action") == &"", "%s ends" % id)
		_check((m.get_node(^"Root") as Node3D).scale.is_equal_approx(Vector3.ONE), "%s: back to full size" % cls)


## Back to &"": the censer returns, hangs under the hook, the archetype casts swing it again and it puffs.
func _check_back_to_censer(m: Node3D) -> void:
	m.call(&"set_weapon_class", &"")
	await _wait(0.6)
	var censer := m.get_node(^"Root/Chest/ArmR/Staff/Censer") as Node3D
	var staff := m.get_node(^"Root/Chest/ArmR/Staff") as Node3D
	_check(staff.visible and m.get(&"attack_style") == &"staff", "&\"\": censer staff and its attack back")
	var o: Vector3 = m.call(&"get_beam_origin")
	_check(o.y < censer.global_position.y - 0.15, "&\"\": kettle hangs under the hook again")
	m.call(&"play_cast", &"soothing_circle")
	var max_tilt := 0.0
	for i: int in 50:
		await process_frame
		var d: Vector3 = (m.call(&"get_beam_origin") as Vector3) - censer.global_position
		max_tilt = maxf(max_tilt, rad_to_deg(Vector3.DOWN.angle_to(d.normalized())))
	_check(max_tilt > 35.0, "&\"\": soothing circle swings the censer (%.0f deg)" % max_tilt)
	_check(not (m.get_node(^"Root/Chest/ArmL/Jar") as Node3D).visible, "&\"\": no jar in the archetype circle")
	await _wait(0.8)


# ================================================================ helpers

func _until(m: Node3D, t: float) -> void:
	var guard := 0
	while float(m.get(&"_action_t")) < t and guard < 400:
		await process_frame
		guard += 1


func _pivot_has(m: Node3D, pivot: String, mat_part: String) -> bool:
	var node := m.get_node_or_null(pivot + "/Merged") as MeshInstance3D
	if node == null or node.mesh == null:
		return false
	for s: int in node.mesh.get_surface_count():
		var mat := node.mesh.surface_get_material(s)
		if mat and mat.resource_path.get_file().contains(mat_part):
			return true
	return false


func _verts(mi: MeshInstance3D) -> int:
	var n := 0
	if mi and mi.mesh:
		for s: int in mi.mesh.get_surface_count():
			n += (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return n


func _draw_instances(n: Node) -> int:
	var c := 0
	for g: Node in n.find_children("*", "GeometryInstance3D", true, false):
		if g is MeshInstance3D and (g as MeshInstance3D).mesh == null:
			continue
		c += 1
	return c


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
				seen[mat.resource_path] = true
	return PackedStringArray(seen.keys())


# ================================================================ shots (windowed)

const CELL_W := 300
const CELL_H := 360


func _shots() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art/screens"))
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
	_cam.fov = 40.0
	_cam.far = 500.0
	_world.add_child(_cam)
	_cam.make_current()
	await _wait(0.5)

	# rows x columns of cells
	var rows: Array = []
	for r: int in 6:
		rows.append([])
	for k: int in CLASSES.size():
		var cls := CLASSES[k]
		var m := _spawn(Vector3(0, 0, 0), k % 2, KINGDOMS[k])
		for p: String in ["_idle_left", "_fidget_wait"]:
			if p in m:
				m.set(p, 1.0e9)
		m.call(&"set_weapon_class", cls, false)
		var holder := m.get_parent() as Node3D
		await _wait(0.8)
		# front 3/4, back 3/4
		holder.rotation.y = deg_to_rad(-30.0)
		_orbit(Vector3(0, 1.15, 0), 5.0, 10.0, 0.0)
		rows[0].append(await _grab_cell(1.0))
		holder.rotation.y = deg_to_rad(150.0)
		rows[1].append(await _grab_cell(1.0))
		# casts, side 3/4 (she faces screen left-ish)
		holder.rotation.y = deg_to_rad(-60.0)
		_orbit(Vector3(0, 1.2, 0.2), 5.4, 14.0, 0.0)
		await _wait(0.3)
		m.call(&"play_cast", &"mending_draught")
		await _until(m, 0.30)
		rows[2].append(await _grab_now())
		await _wait(0.8)
		# jar cocked behind the head: seen from her back-left (the archetype: the censer overhead, same view)
		holder.rotation.y = deg_to_rad(150.0)
		await _wait(0.2)
		m.call(&"play_cast", &"soothing_circle")
		await _until(m, 0.40 if cls != &"" else 0.55)
		rows[3].append(await _grab_now())
		await _wait(1.2)
		# jar in flight: side view, wide
		holder.rotation.y = deg_to_rad(-90.0)
		m.call(&"set_cast_point", holder.to_global(Vector3(0, 0, 4.0)))
		_orbit(Vector3(-1.8, 1.3, 0.0), 9.0, 8.0, 0.0)
		await _wait(0.3)
		m.call(&"play_cast", &"soothing_circle")
		await _until(m, 0.66 if cls != &"" else 0.9)
		rows[4].append(await _grab_now())
		await _wait(1.2)
		holder.rotation.y = deg_to_rad(-60.0)
		_orbit(Vector3(0, 1.2, 0.2), 5.4, 14.0, 0.0)
		await _wait(0.3)
		m.call(&"play_cast", &"lifeline")
		await _until(m, 0.55)
		rows[5].append(await _grab_now())
		await _wait(1.0)
		holder.queue_free()
		await _wait(0.2)

	# 40 m strip: the 5 looks side by side at the game camera (pitch 55), colour then black silhouettes
	var base := Vector3(0, 0, -60)
	var strip: Array[Node3D] = []
	for k: int in CLASSES.size():
		var m := _spawn(base + Vector3(-5.0 + 2.5 * k, 0, 0), k % 2, KINGDOMS[k], deg_to_rad(20.0))
		m.call(&"set_weapon_class", CLASSES[k], false)
		strip.append(m)
	await _wait(1.0)
	_cam.fov = 50.0
	_orbit(base + Vector3(0, 0.8, 0), 40.0, 55.0, 0.0)
	await _wait(0.3)
	var col40 := await _grab_strip()
	var white := StandardMaterial3D.new()
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.albedo_color = Color.WHITE
	var plane := MeshInstance3D.new()
	var pp := PlaneMesh.new()
	pp.size = Vector2(60, 60)
	plane.mesh = pp
	plane.material_override = white
	plane.position = base + Vector3(0, 0.01, 0)
	_world.add_child(plane)
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	black.cull_mode = BaseMaterial3D.CULL_DISABLED
	_env.glow_enabled = false
	for m: Node3D in strip:
		for n: Node in m.find_children("*", "", true, false):
			if n is GPUParticles3D or n.name == &"Shadow":
				(n as Node3D).visible = false
			elif n is GeometryInstance3D:
				(n as GeometryInstance3D).material_override = black
				(n as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	await _wait(0.3)
	var sil40 := await _grab_strip()

	# compose: 6 rows of cells + 2 strips
	var cols := CLASSES.size()
	var sw := cols * CELL_W
	var sh: int = col40.get_height()
	var out := Image.create(sw, 6 * CELL_H + 2 * sh + 8, false, Image.FORMAT_RGBA8)
	out.fill(Color(0.1, 0.1, 0.1))
	for r: int in 6:
		for k: int in cols:
			var img: Image = rows[r][k]
			img.resize(CELL_W, CELL_H, Image.INTERPOLATE_BILINEAR)
			out.blit_rect(img, Rect2i(0, 0, CELL_W, CELL_H), Vector2i(k * CELL_W, r * CELL_H))
	for i: int in 2:
		var s: Image = col40 if i == 0 else sil40
		out.blit_rect(s, Rect2i(0, 0, mini(s.get_width(), sw), sh), Vector2i((sw - mini(s.get_width(), sw)) / 2, 6 * CELL_H + 4 + i * (sh + 4)))
	out.save_png("res://docs/art/screens/champion_mender_classes.png")
	print("saved docs/art/screens/champion_mender_classes.png (columns: archetype, spear, sword_shield, two_hand, wizard)")
	print("11.V5 SHOTS DONE")
	quit()


func _orbit(focus: Vector3, dist: float, pitch_deg: float, yaw_deg: float) -> void:
	var pitch := deg_to_rad(pitch_deg)
	var yaw := deg_to_rad(yaw_deg)
	_cam.position = focus + Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * dist
	_cam.look_at(focus, Vector3.UP)


func _grab_cell(settle: float) -> Image:
	await create_timer(settle * 0.3).timeout
	return await _grab_now()


## Centre crop of the viewport, 5:6.
func _grab_now(frac: float = 0.92) -> Image:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	var h := int(img.get_height() * frac)
	var w := int(h * float(CELL_W) / float(CELL_H))
	return img.get_region(Rect2i((img.get_width() - w) / 2, (img.get_height() - h) / 2, w, h))


## The 40 m row: a thin centre band, nearest x2 (the pixels stay honest).
func _grab_strip() -> Image:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	var w := 750
	var h := 110
	var crop := img.get_region(Rect2i((img.get_width() - w) / 2, (img.get_height() - h) / 2 - 6, w, h))
	crop.resize(w * 2, h * 2, Image.INTERPOLATE_NEAREST)
	return crop
