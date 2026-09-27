extends SceneTree
## Task 13.V26: the Dread Paddock, Shadow's Lair model (art/buildings/lair/shadow/, cavalry-mounts.md 2.1 + 10,
## art-keep.md 0). DreadPaddockModel extends ShadowHallModel (the Gloom Hall / Gloom Bazaar builder).
## Run:  $GODOT --headless --path . -s tests/test_13_v26.gd --fixed-fps 60 --quit-after 4000
## Checks: headless instantiation (plus one with every hook called before _ready); the building hooks
## (set_team_color, set_construction_progress, set_health_ratio, play_training_pulse, play_destroyed + destroyed_finished,
## set_selected) and the Lair hooks (play_raise / is_raising + raise_opened, play_call / is_calling, get_call_point);
## budget (0 lights, draw-only, mesh nodes, particle systems, materials, triangles); footprint (x / z inside 3.3 m below
## 2.5 m, overhangs above it inside 3.6 m) and the dominant gatehouse; the clear call circle (no prop inside CALL_CLEAR of
## CALL_POINT between 0.13 and 3.5 m above the dais); construction, damage, raise, call and collapse states; the
## instance-uniform slot audit. Prints PASS 13.v26 / FAIL 13.v26: <reason>.

const TASK_ID := "13.v26"
const SCENE := "res://art/buildings/lair/shadow/dread_paddock.tscn"
const DT := 1.0 / 60.0
const BLUE := Color(0.20, 0.45, 0.95)
## Flat / additive helpers left out of the solid-geometry checks.
const NON_SOLID := ["ContactDecal", "ScorchDecal", "LightPool", "LightPoolBack", "LightPoolGate", "CirclePool",
	"BuildOutline", "Halo0", "Halo1", "Halo2"]

var _fails: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  check failed: ", what)


func _frames(n: int) -> void:
	for _i: int in n:
		await process_frame


static func _const(m: Node, nm: String) -> Variant:
	return (m.get_script() as Script).get_script_constant_map()[nm]


static func _surf_mat(gi: GeometryInstance3D, mesh: Mesh, s: int) -> Material:
	if gi.material_override:
		return gi.material_override
	var mi := gi as MeshInstance3D
	if mi:
		var mt := mi.get_surface_override_material(s)
		if mt:
			return mt
	return mesh.surface_get_material(s)


static func _visible_in_tree(n: Node3D, stop: Node) -> bool:
	var c: Node = n
	while c != null and c != stop:
		if c is Node3D and not (c as Node3D).visible:
			return false
		c = c.get_parent()
	return true


## Model-space vertices of every visible solid mesh (name -> PackedVector3Array).
func _solid_vertices(m: Node3D) -> Dictionary:
	var out := {}
	var inv := m.global_transform.affine_inverse()
	for n: Node in m.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or mi.name in NON_SOLID or not _visible_in_tree(mi, m):
			continue
		var xf := inv * mi.global_transform
		var pts := PackedVector3Array()
		for s: int in mi.mesh.get_surface_count():
			for v: Vector3 in (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				pts.append(xf * v)
		out[String(mi.get_path())] = pts
	return out


func _run() -> void:
	var ps := load(SCENE) as PackedScene
	_check(ps != null, "scene loads")
	if ps == null:
		_finish()
		return
	var world := Node3D.new()
	root.add_child(world)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 30, 25)
	world.add_child(cam)
	cam.make_current()
	var m: Node3D = ps.instantiate()
	world.add_child(m)
	# Every hook before _ready (Building calls them before adding the model).
	var early: Node3D = ps.instantiate()
	early.call(&"set_team_color", BLUE)
	early.call(&"set_construction_progress", 0.4)
	early.call(&"set_health_ratio", 0.3)
	early.call(&"set_selected", true)
	early.call(&"play_raise")
	early.call(&"play_call")
	early.position = Vector3(20, 0, 0)
	world.add_child(early)
	await _frames(3)

	# ---- hooks
	for hk: String in ["set_team_color", "set_construction_progress", "set_health_ratio", "play_training_pulse",
			"play_destroyed", "set_selected", "play_raise", "is_raising", "play_call", "is_calling", "get_call_point"]:
		_check(m.has_method(hk), "hook %s" % hk)
	for sg: String in ["destroyed_finished", "raise_opened"]:
		_check(m.has_signal(sg), "signal %s" % sg)

	# ---- budget / draw-only
	_check(m.find_children("*", "Light3D", true, false).is_empty(), "0 lights in the tree")
	_check(m.find_children("*", "CollisionObject3D", true, false).is_empty()
		and m.find_children("*", "CollisionShape3D", true, false).is_empty(), "draw-only: no physics nodes")
	_check(m.find_children("*", "NavigationRegion3D", true, false).is_empty()
		and m.find_children("*", "NavigationObstacle3D", true, false).is_empty(), "draw-only: no navigation nodes")
	var meshes := 0
	var multis := 0
	var particles := 0
	var mats := {}
	var tris := 0
	for n: Node in m.find_children("*", "GeometryInstance3D", true, false):
		if n is GPUParticles3D:
			particles += 1
			continue
		var gi := n as GeometryInstance3D
		var vis: bool = _visible_in_tree(gi, m)
		var mesh: Mesh = null
		if gi is MeshInstance3D:
			mesh = (gi as MeshInstance3D).mesh
			if vis:
				meshes += 1
		elif gi is MultiMeshInstance3D:
			mesh = (gi as MultiMeshInstance3D).multimesh.mesh
			if vis:
				multis += 1
		if mesh == null or not vis:
			continue
		for s: int in mesh.get_surface_count():
			mats[_surf_mat(gi, mesh, s)] = true
			var arr := mesh.surface_get_arrays(s)
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			tris += idx.size() / 3 if idx.size() > 0 else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	print("visible mesh nodes %d, multimesh nodes %d, particle systems %d, materials %d, triangles %d"
		% [meshes, multis, particles, mats.size(), tris])
	_check(meshes <= 24, "visible mesh nodes %d <= 24 (hall budget + halos / pools)" % meshes)
	_check(particles <= 14, "particle systems %d <= 14" % particles)
	_check(mats.size() <= 20, "materials %d <= 20" % mats.size())
	_check(tris <= 20000, "triangles %d <= 20000" % tris)
	# The merged meshes are shared between instances (built once per class).
	var a1 := m.find_child("GateStack", true, false) as MeshInstance3D
	var a2 := early.find_child("GateStack", true, false) as MeshInstance3D
	_check(a1 != null and a2 != null and a1.mesh == a2.mesh, "merged meshes shared between instances")

	# ---- instance-uniform slot audit (one MeshInstance never mixes two uniforms on one slot)
	var collisions := 0
	for n: Node in m.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		var by_slot := {}
		var seen := {}
		for s: int in mi.mesh.get_surface_count():
			var mat := _surf_mat(mi, mi.mesh, s)
			if not mat is ShaderMaterial:
				continue
			for u: Array in _instance_uniforms((mat as ShaderMaterial).shader):
				if seen.has(u[0]):
					continue
				seen[u[0]] = true
				if by_slot.has(u[1]):
					collisions += 1
					print("  COLLISION %s slot %d: %s / %s" % [mi.name, u[1], by_slot[u[1]], u[0]])
				by_slot[u[1]] = u[0]
	_check(collisions == 0, "instance uniform slot collisions %d" % collisions)
	if collisions == 0:
		print("KITFIX AUDIT OK (dread paddock: painted / banner / rune_glow slots, no collision)")

	# ---- footprint, heights, dominant gatehouse
	var verts: Dictionary = _solid_vertices(m)
	var lo := Vector3(INF, INF, INF)
	var hi := Vector3(-INF, -INF, -INF)
	var low_out := 0.0
	var gate_top := 0.0
	var stall_top := 0.0
	for key: String in verts:
		var plinth: bool = key.contains("PlinthBase") or key.contains("Rubble") or key.contains("Scaffold")
		for p: Vector3 in (verts[key] as PackedVector3Array):
			if key.contains("SpireL") or key.contains("GateStack"):
				gate_top = maxf(gate_top, p.y)
			if key.contains("StallRoof") or key.contains("/Stalls"):
				stall_top = maxf(stall_top, p.y)
			if plinth:
				continue
			lo = lo.min(p)
			hi = hi.max(p)
			if p.y < 2.5:
				low_out = maxf(low_out, maxf(absf(p.x), absf(p.z)))
	print("bounds (no plinth / rubble): x %.2f..%.2f, y %.2f..%.2f, z %.2f..%.2f; below 2.5 m max |x|,|z| %.2f"
		% [lo.x, hi.x, lo.y, hi.y, lo.z, hi.z, low_out])
	print("gatehouse top %.2f, stall top %.2f" % [gate_top, stall_top])
	_check(lo.y > -0.01, "nothing below the ground")
	_check(maxf(absf(lo.x), absf(hi.x)) <= 3.6 and maxf(absf(lo.z), absf(hi.z)) <= 3.6,
		"overhangs (spikes, torches, eaves) inside 3.6 m of the centre")
	_check(low_out <= 3.3, "below 2.5 m inside 3.3 m of the centre (%.2f)" % low_out)
	_check(hi.y >= 10.5 and hi.y <= 12.0, "top %.2f in 10.5..12 m" % hi.y)
	_check(gate_top - stall_top >= 4.0, "the gatehouse dominates (%.2f vs stalls %.2f)" % [gate_top, stall_top])

	# ---- clear call circle
	var cp: Vector3 = _const(m, "CALL_POINT")
	var clear: float = _const(m, "CALL_CLEAR")
	var yard: float = _const(m, "YARD")
	var intruders := {}
	for key: String in verts:
		for p: Vector3 in (verts[key] as PackedVector3Array):
			if p.y <= yard + 0.13 or p.y >= yard + 3.5:
				continue
			if Vector2(p.x - cp.x, p.z - cp.z).length() < clear:
				intruders[key.get_file()] = true
	print("circle at %s r %.2f: intruders %s" % [cp, clear, intruders.keys()])
	_check(intruders.is_empty(), "the call circle is clear (%s)" % ", ".join(PackedStringArray(intruders.keys())))
	var gp: Vector3 = m.call(&"get_call_point")
	_check(gp.distance_to(m.global_transform * cp) < 0.001, "get_call_point = the circle centre")
	var holder := Node3D.new()
	holder.position = Vector3(-30, 0, 10)
	holder.rotation.y = -PI * 0.5
	world.add_child(holder)
	var turned: Node3D = ps.instantiate()
	holder.add_child(turned)
	await _frames(1)
	var tp: Vector3 = turned.call(&"get_call_point")
	var want: Vector3 = holder.position + Basis(Vector3.UP, -PI * 0.5) * cp
	_check(tp.distance_to(want) < 0.001, "get_call_point follows the model's yaw (%s vs %s)" % [tp, want])

	# ---- idle (built)
	var halo := m.find_child("Halo0", true, false) as MeshInstance3D
	var smoke := m.find_child("StallSmoke1", true, false) as GPUParticles3D
	_check(halo != null and halo.visible, "built: torch halos on")
	_check(smoke != null and smoke.emitting, "built: smoke from the stalls")
	var rune := m.find_child("RuneRing", true, false) as Node3D
	var r0: float = rune.rotation.y
	await _frames(30)
	_check(absf(wrapf(rune.rotation.y - r0, -PI, PI)) > 0.05, "the rune ring turns (idle)")

	# ---- team colour, selection, training pulse
	m.call(&"set_team_color", BLUE)
	var mat_team: ShaderMaterial = m.get(&"mat_team")
	_check((mat_team.get_shader_parameter(&"base_color") as Color).is_equal_approx(BLUE), "team colour on the team slate")
	m.call(&"set_selected", true)
	await _frames(20)
	var mat_stone: ShaderMaterial = m.get(&"mat_stone")
	_check(absf(float(mat_stone.get_shader_parameter(&"rim_strength")) - 0.9) < 0.01, "selected: rim 0.9")
	m.call(&"set_selected", false)
	await _frames(20)
	m.call(&"play_training_pulse")
	_check((m.find_child("TrainBurst", true, false) as GPUParticles3D).emitting, "training pulse: spark burst")
	await _frames(40)

	# ---- raise
	var opened := [-1.0, Vector3.ZERO]
	var rt := [0.0]
	m.connect(&"raise_opened", func(at: Vector3) -> void:
		opened[0] = rt[0]
		opened[1] = at, CONNECT_ONE_SHOT)
	var port := m.find_child("PortcullisPivot", true, false) as Node3D
	var mat_gate: ShaderMaterial = m.get(&"mat_gate")
	var g_torch: ShaderMaterial = m.get(&"_g_torch")
	var heads: Array = m.get(&"_heads")
	var max_lift := 0.0
	var lift_at_1 := 0.0
	var gate_peak := 0.0
	var torch_peak := 0.0
	var head_min := 0.0
	var smoke_on := false
	m.call(&"play_raise")
	_check(bool(m.call(&"is_raising")), "play_raise starts")
	for i: int in 200:
		await process_frame
		var t := float(i + 1) * DT
		rt[0] = t
		max_lift = maxf(max_lift, port.position.y)
		if absf(t - 1.0) < 0.01:
			lift_at_1 = port.position.y
		gate_peak = maxf(gate_peak, float(mat_gate.get_shader_parameter(&"boost")))
		torch_peak = maxf(torch_peak, float(g_torch.get_shader_parameter(&"boost")))
		head_min = minf(head_min, (heads[0] as Node3D).rotation.z)
		if t < 1.0 and (m.find_child("RaiseSmoke", true, false) as GPUParticles3D).emitting:
			smoke_on = true
	print("raise: portcullis max %.2f (%.2f at 1 s), opened at %.2f s at %s, veil boost peak %.2f, torch peak %.2f, head toss %.2f"
		% [max_lift, lift_at_1, opened[0], opened[1], gate_peak, torch_peak, head_min])
	_check(max_lift >= 1.3 and lift_at_1 >= 1.3, "the portcullis hauls up")
	_check(absf(float(opened[0]) - 0.7) < 0.04, "raise_opened at 0.7 s")
	_check((opened[1] as Vector3).distance_to(m.global_transform * Vector3(-0.55, 0.8, -3.2)) < 0.01, "raise_opened at the gate")
	_check(smoke_on, "smoke billows out of the gate")
	_check(gate_peak > 2.5 and torch_peak > 1.8, "veil and torches flare")
	_check(head_min < -0.3, "the nightmares toss their heads")
	_check(not bool(m.call(&"is_raising")) and absf(port.position.y) < 0.001, "portcullis down, raise over after 3 s")

	# ---- call
	var g_circle: ShaderMaterial = m.get(&"_g_circle")
	var call_peak := 0.0
	var spin := 0.0
	var prev: float = rune.rotation.y
	m.call(&"play_call")
	_check(bool(m.call(&"is_calling")) and (m.find_child("CallColumn", true, false) as GPUParticles3D).emitting,
		"play_call: rune column rises")
	for i: int in 140:
		await process_frame
		call_peak = maxf(call_peak, float(g_circle.get_shader_parameter(&"boost")))
		spin = maxf(spin, absf(wrapf(rune.rotation.y - prev, -PI, PI)) / DT)
		prev = rune.rotation.y
	print("call: rune boost peak %.2f, spin peak %.2f rad/s, now %.2f" % [call_peak, spin,
		float(g_circle.get_shader_parameter(&"boost"))])
	_check(call_peak > 3.0, "the circle flares on the call")
	_check(spin > 2.5, "the rune ring spins fast on the call")
	_check(not bool(m.call(&"is_calling")) and absf(float(g_circle.get_shader_parameter(&"boost")) - 1.0) < 0.05,
		"call over after 2 s, back to idle")

	# ---- construction
	m.call(&"set_construction_progress", 0.0)
	await _frames(2)
	var scaffold := m.find_child("Scaffold", true, false) as Node3D
	_check(not (m.find_child("Gatehouse", true, false) as Node3D).visible, "site at 0: gatehouse not up")
	m.call(&"set_construction_progress", 0.45)
	await _frames(2)
	_check(scaffold.visible, "site: scaffolding up")
	_check(not halo.visible and not smoke.emitting, "site: no halos, no stall smoke")
	m.call(&"play_raise")
	m.call(&"play_call")
	_check(not bool(m.call(&"is_raising")) and not bool(m.call(&"is_calling")), "raise / call ignored on a site")
	m.call(&"set_construction_progress", 1.0)
	_check((m.find_child("BuildFlash", true, false) as GPUParticles3D).emitting, "complete: build flash")
	await _frames(2)
	_check(not scaffold.visible and halo.visible and smoke.emitting, "complete: scaffold gone, halos and smoke on")

	# ---- damage
	m.call(&"set_health_ratio", 0.4)
	await _frames(1)
	_check((m.find_child("Smoke1", true, false) as GPUParticles3D).emitting, "< 50 %: smoke")
	_check((m.find_child("RoofHoleL", true, false) as Node3D).visible, "< 50 %: caved stall roof")
	_check(not (m.find_child("SpireLCrown", true, false) as Node3D).visible, "< 50 %: the spire loses its crown")
	m.call(&"set_health_ratio", 0.2)
	await _frames(1)
	_check((m.find_child("Blaze1", true, false) as GPUParticles3D).emitting, "< 25 %: fire")
	_check((m.find_child("RoofHoleR", true, false) as Node3D).visible, "< 25 %: burning roof hole")
	_check(not (m.find_child("TowerBanner", true, false) as Node3D).visible, "< 25 %: tower banner lost")
	m.call(&"set_health_ratio", 1.0)
	await _frames(1)
	_check(not (m.find_child("Smoke1", true, false) as GPUParticles3D).emitting
		and (m.find_child("SpireLCrown", true, false) as Node3D).visible
		and not (m.find_child("RoofHoleL", true, false) as Node3D).visible, "healed: reverts")

	# ---- the early instance (hooks before _ready)
	_check(((early.get(&"mat_team") as ShaderMaterial).get_shader_parameter(&"base_color") as Color).is_equal_approx(BLUE),
		"early: team colour kept")
	_check((early.find_child("Scaffold", true, false) as Node3D).visible, "early: site at 40 %")
	_check(not bool(early.call(&"is_raising")) and not bool(early.call(&"is_calling")), "early: pending raise / call dropped on a site")

	# ---- perf: idle animation of 10 paddocks
	var many: Array[Node3D] = []
	for i: int in 10:
		var a: Node3D = ps.instantiate()
		a.position = Vector3(-40.0 + 8.0 * i, 0, 40)
		world.add_child(a)
		many.append(a)
	await _frames(2)
	for a: Node3D in many:
		a.call(&"play_raise")
	var us := Time.get_ticks_usec()
	for i: int in 60:
		for a: Node3D in many:
			a.call(&"_process", DT)
	print("paddock _process (raising): %.4f ms per paddock per frame" % (float(Time.get_ticks_usec() - us) / 600.0 / 1000.0))

	# ---- collapse
	var done := [-1.0]
	var ct := [0.0]
	m.connect(&"destroyed_finished", func() -> void: done[0] = ct[0], CONNECT_ONE_SHOT)
	m.call(&"play_raise")
	await _frames(20)
	m.call(&"play_destroyed")
	var spire := m.find_child("SpireL", true, false) as Node3D
	var spire_moved := false
	for i: int in 200:
		await process_frame
		ct[0] = float(i + 1) * DT
		if spire.visible and spire.rotation.length() > 0.2:
			spire_moved = true
	print("collapse: destroyed_finished at %.2f s" % done[0])
	_check(absf(float(done[0]) - 3.0) < 0.1, "destroyed_finished after 3 s")
	_check(spire_moved and not spire.visible, "the tall spire topples, then goes")
	_check(not halo.visible and (m.find_child("Wreck", true, false) as Node3D).visible, "wreck shown, torches out")
	_check(absf(port.position.y) < 0.001, "portcullis down on the wreck")
	m.call(&"play_raise")
	_check(not bool(m.call(&"is_raising")), "no raise on a wreck")

	world.queue_free()
	await _frames(2)
	_finish()


static func _instance_uniforms(sh: Shader) -> Array:
	var out: Array = []
	if sh == null:
		return out
	var re := RegEx.create_from_string("instance\\s+uniform\\s+\\w+\\s+(\\w+)\\s*(:[^=;]*)?[=;]")
	var idx_re := RegEx.create_from_string("instance_index\\s*\\(\\s*(\\d+)\\s*\\)")
	var implicit := 0
	for line: String in sh.code.split("\n"):
		var l := line.strip_edges()
		if l.begins_with("//"):
			continue
		var r := re.search(l)
		if r == null:
			continue
		var ir := idx_re.search(r.get_string(2))
		if ir:
			out.append([r.get_string(1), int(ir.get_string(1))])
		else:
			out.append([r.get_string(1), implicit])
			implicit += 1
	return out


func _finish() -> void:
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()
