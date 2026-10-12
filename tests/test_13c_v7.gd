extends SceneTree
## Task 13c.V7: the Ember Crucible annex (art/buildings/fire/ember_crucible/, titans-2.md 6 + 11): Fire's base upgrade
## shown as a crucible-and-anvil forge beside the Dragon Roost's foot. Standalone child scene (the Roost art 13.V25 did
## not exist yet).
## Run:  $GODOT --headless --path . -s tests/test_13c_v7.gd --fixed-fps 60 --quit-after 3000
## Checks: headless instantiation (plus one lit before _ready); hooks set_crucible(on, instant) / play_forge() /
## is_crucible_on / is_forging / heat / get_sprue_point + signal forge_poured; budget (<= 12 mesh instances, <= 3
## particle systems, 0 lights, only the annex's own materials, no runtime materials: every mesh surface material is a
## saved .tres); instance-uniform slot audit; draw-only (no collision / physics / navigation nodes); footprint-neutral
## (mesh bounds inside FOOTPRINT_HALF, top <= 3 m, far under the Roost's 9 m crown) at any tilt; off = crust, no glow,
## no embers; lighting ramps in (~1.2 s) with a flare; forge: bellows pump, tilt >= 30 deg, the pour stream hits the
## sprue at 0.4 s (forge_poured at the sprue, sparks), the mould flashes and cools, steam at 1.3 s, back upright and
## idle (no _process) after 2.2 s; play_forge ignored while cold; going out cools to the crust in ~2 s.
## Prints PASS 13c.v7 / FAIL 13c.v7: <reason>.

const TASK_ID := "13c.v7"
const SCENE := "res://art/buildings/fire/ember_crucible/ember_crucible.tscn"
const OWN_DIR := "res://art/buildings/fire/ember_crucible/"
const DT := 1.0 / 60.0

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


static func _surf_mat(mi: MeshInstance3D, s: int) -> Material:
	if mi.material_override:
		return mi.material_override
	var mt := mi.get_surface_override_material(s)
	return mt if mt else mi.mesh.surface_get_material(s)


func _boost(m: Node, path: String) -> float:
	var gi := m.get_node(path) as GeometryInstance3D
	return float(gi.get_instance_shader_parameter(&"glow_boost"))


## Annex-space bounds of every mesh (the light pool excluded: it is a flat additive decal on the pad).
static func _bounds(m: Node3D) -> AABB:
	var a := AABB()
	var first := true
	for n: Node in m.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or mi.name == "LightPool" or not mi.visible:
			continue
		var xf := m.global_transform.affine_inverse() * mi.global_transform
		for s: int in mi.mesh.get_surface_count():
			for v: Vector3 in (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				var p := xf * v
				if first:
					a = AABB(p, Vector3.ZERO)
					first = false
				else:
					a = a.expand(p)
	return a


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
	var holder := Node3D.new()
	holder.position = Vector3(1.85, 0.6, -1.85)     # on a Roost plinth, like the Roost will place it
	world.add_child(holder)
	var m: Node3D = ps.instantiate()
	holder.add_child(m)
	var early: Node3D = ps.instantiate()
	early.call(&"set_crucible", true)                 # before _ready: applied at once
	var h2 := Node3D.new()
	h2.position = Vector3(12, 0, 0)
	world.add_child(h2)
	h2.add_child(early)
	await _frames(3)

	# ---- hooks
	for hk: String in ["set_crucible", "play_forge", "is_crucible_on", "is_forging", "heat", "get_sprue_point"]:
		_check(m.has_method(hk), "hook %s" % hk)
	_check(m.has_signal(&"forge_poured"), "signal forge_poured")

	# ---- budget / draw-only (with a non-fire team colour set: its shared ec_painted copy must count as ec_painted)
	var ice := Color(0.45, 0.75, 0.95)
	m.call(&"set_team_color", ice)
	var team_copies := 0
	var geo := m.find_children("*", "GeometryInstance3D", true, false)
	var meshes := 0
	var parts := 0
	for n: Node in geo:
		if n is GPUParticles3D:
			parts += 1
		elif n is MeshInstance3D:
			meshes += 1
	print("mesh instances %d, particle systems %d, draw instances %d" % [meshes, parts, geo.size()])
	_check(meshes <= 12, "mesh instances %d <= 12" % meshes)
	_check(parts <= 3, "particle systems %d <= 3" % parts)
	_check(m.find_children("*", "Light3D", true, false).is_empty(), "0 lights")
	_check(m.find_children("*", "CollisionObject3D", true, false).is_empty(), "draw-only: no physics bodies / areas")
	_check(m.find_children("*", "CollisionShape3D", true, false).is_empty(), "draw-only: no collision shapes")
	_check(m.find_children("*", "NavigationObstacle3D", true, false).is_empty()
		and m.find_children("*", "NavigationRegion3D", true, false).is_empty(), "draw-only: no navigation nodes")
	var mats := {}
	var verts := 0
	var tris := 0
	for n: Node in geo:
		var mi := n as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		for s: int in mi.mesh.get_surface_count():
			var mat := _surf_mat(mi, s)
			if mat and mat.has_meta(&"team_copy_of"):
				team_copies += 1
				_check(Color((mat as ShaderMaterial).get_shader_parameter(&"base_color")).is_equal_approx(ice), "team copy colour")
				mat = load(String(mat.get_meta(&"team_copy_of"))) as Material
			mats[mat.resource_path if mat else "<none>"] = true
			var arr := mi.mesh.surface_get_arrays(s)
			verts += (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			tris += idx.size() / 3 if idx.size() > 0 else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	for p: String in mats:
		_check(p.begins_with(OWN_DIR + "materials/") and p.ends_with(".tres"), "material not a saved annex .tres: '%s'" % p)
	print("materials %d (%s)" % [mats.size(), ", ".join(PackedStringArray(mats.keys()).duplicate())])
	print("triangles %d, vertices %d" % [tris, verts])
	_check(mats.size() <= 9, "materials %d <= 9" % mats.size())
	_check(tris <= 6000, "triangles %d <= 6000" % tris)
	# shared meshes: a second annex reuses the same ArrayMeshes and materials (nothing built per instance)
	_check((m.get_node("Static") as MeshInstance3D).mesh == (early.get_node("Static") as MeshInstance3D).mesh,
		"meshes shared between annexes")
	_check(team_copies > 0, "set_team_color(ice) reaches the painted surfaces (%d)" % team_copies)
	m.call(&"set_team_color", Color(0.85, 0.30, 0.12))   # back to the fire colour: the shared .tres again
	_check(_surf_mat(m.get_node("Static") as MeshInstance3D, 0).resource_path.begins_with(OWN_DIR), "fire colour: shared ec_painted")

	# ---- instance-uniform slot audit (one MeshInstance never mixes two uniforms on one slot)
	var collisions := 0
	for n: Node in geo:
		var gi := n as MeshInstance3D
		if gi == null or gi.mesh == null:
			continue
		var by_slot := {}
		var seen := {}
		for s: int in gi.mesh.get_surface_count():
			var mat := _surf_mat(gi, s)
			if not mat is ShaderMaterial:
				continue
			for u: Array in _instance_uniforms((mat as ShaderMaterial).shader):
				if seen.has(u[0]):
					continue
				seen[u[0]] = true
				if u[0] == "glow_boost" and int(u[1]) != 5:
					_check(false, "glow_boost on slot %d (kit map 5)" % u[1])
				if by_slot.has(u[1]):
					collisions += 1
					print("  COLLISION %s slot %d: %s / %s" % [gi.name, u[1], by_slot[u[1]], u[0]])
				by_slot[u[1]] = u[0]
	_check(collisions == 0, "instance uniform slot collisions %d" % collisions)

	# ---- footprint: at rest and fully tipped
	var b0 := _bounds(m)
	var fh: Vector2 = _const(m, "FOOTPRINT_HALF")
	print("bounds (cold, upright): x %.2f..%.2f, y %.2f..%.2f, z %.2f..%.2f" % [b0.position.x, b0.end.x, b0.position.y,
		b0.end.y, b0.position.z, b0.end.z])
	_check(b0.position.y > -0.01, "nothing below the ground contact")
	_check(b0.end.y <= 3.0 and b0.end.y <= float(_const(m, "TOP_Y")) + 0.02, "top %.2f <= TOP_Y / 3 m (Roost crown 9 m)" % b0.end.y)
	_check(absf(b0.position.x) <= fh.x + 0.01 and b0.end.x <= fh.x + 0.01, "x inside FOOTPRINT_HALF")
	_check(b0.position.z >= -fh.y - 0.01 and b0.end.z <= fh.y + 0.01, "z inside FOOTPRINT_HALF")
	var anchor: Vector3 = _const(m, "ROOST_ANCHOR")
	var far_corner := Vector2(absf(anchor.x) + fh.x, absf(anchor.z) + fh.y)
	print("at ROOST_ANCHOR the pad reaches (%.2f, %.2f) from the Roost centre" % [far_corner.x, far_corner.y])
	_check(far_corner.x <= 3.3 and far_corner.y <= 3.3, "at the anchor the annex stays within 3.3 m of the Roost centre")

	# ---- off: crust, no glow, no embers
	_check(not bool(m.call(&"is_crucible_on")) and float(m.call(&"heat")) == 0.0, "starts cold")
	_check((m.get_node("CruciblePivot/Crust") as Node3D).visible, "off: slag crust shown")
	_check(not (m.get_node("CruciblePivot/Molten") as Node3D).visible, "off: no molten metal")
	_check(not (m.get_node("HotGlow") as Node3D).visible and not (m.get_node("LightPool") as Node3D).visible,
		"off: coals and light pool dark")
	_check(not (m.get_node("Embers") as GPUParticles3D).emitting, "off: no embers")
	_check(not m.is_processing(), "off: idle (no _process)")
	# play_forge while cold is ignored
	m.call(&"play_forge")
	await _frames(2)
	_check(not bool(m.call(&"is_forging")), "play_forge ignored while cold")

	# ---- early (lit before _ready): applied at once
	_check(bool(early.call(&"is_crucible_on")) and float(early.call(&"heat")) >= 1.0, "set_crucible before _ready kept")
	_check((early.get_node("CruciblePivot/Molten") as Node3D).visible
		and not (early.get_node("CruciblePivot/Crust") as Node3D).visible, "early: molten, no crust")
	_check((early.get_node("Embers") as GPUParticles3D).emitting, "early: embers")

	# ---- ignite
	m.call(&"set_crucible", true)
	var max_flare := 0.0
	var heat_half := -1.0
	var sparks := m.get_node("Sparks") as GPUParticles3D
	_check(sparks.emitting, "lighting: a spark burst")
	for i: int in 96:
		await process_frame
		max_flare = maxf(max_flare, _boost(m, "CruciblePivot/Molten"))
		if heat_half < 0.0 and float(m.call(&"heat")) >= 0.5:
			heat_half = float(i + 1) * DT
	print("ignite: heat 0.5 at %.2f s, molten boost peak %.2f, now %.2f" % [heat_half, max_flare, _boost(m, "CruciblePivot/Molten")])
	_check(heat_half > 0.4 and heat_half < 0.8, "ignition ramps in (half at %.2f s)" % heat_half)
	_check(max_flare > 1.6, "ignition flare (%.2f)" % max_flare)
	_check(float(m.call(&"heat")) >= 1.0 and absf(_boost(m, "CruciblePivot/Molten") - 1.0) < 0.05, "lit: steady glow 1.0")
	_check(not (m.get_node("CruciblePivot/Crust") as Node3D).visible and (m.get_node("HotGlow") as Node3D).visible
		and (m.get_node("LightPool") as Node3D).visible, "lit: molten, coals, pool")
	_check((m.get_node("Embers") as GPUParticles3D).emitting, "lit: embers rise")
	var idle_after := await _until_idle(m, 240)
	print("lit: idle (no _process) %.2f s after the ramp" % idle_after)
	_check(idle_after >= 0.0 and idle_after < 2.0, "lit idle: no _process within 2 s (%.2f)" % idle_after)

	# ---- forge
	var poured := [-1.0, Vector3.ZERO]
	var ft := [0.0]
	m.connect(&"forge_poured", func(at: Vector3) -> void:
		poured[0] = ft[0]
		poured[1] = at, CONNECT_ONE_SHOT)
	var pivot := m.get_node("CruciblePivot") as Node3D
	var pour := m.get_node("Pour") as MeshInstance3D
	var steam := m.get_node("Steam") as GPUParticles3D
	var leather := m.get_node("BellowsLeather") as Node3D
	var min_tilt := 0.0
	var pour_first := -1.0
	var pour_last := -1.0
	var pour_bottom_at_hit := 99.0
	var mould_peak := 0.0
	var mould_at_2 := 0.0
	var steam_t := -1.0
	var pool_peak := 0.0
	var leather_lo := 9.0
	var leather_hi := 0.0
	var sparks_at_hit := false
	m.call(&"play_forge")
	_check(bool(m.call(&"is_forging")), "play_forge starts")
	for i: int in 150:
		await process_frame
		var t := float(i + 1) * DT
		ft[0] = t
		min_tilt = minf(min_tilt, pivot.rotation.x)
		leather_lo = minf(leather_lo, leather.scale.y)
		leather_hi = maxf(leather_hi, leather.scale.y)
		if pour.visible:
			if pour_first < 0.0:
				pour_first = t
			pour_last = t
			if absf(t - 0.5) < 0.01:
				pour_bottom_at_hit = pour.position.y - pour.scale.y * 0.5
		var mb := _boost(m, "MouldGlow")
		mould_peak = maxf(mould_peak, mb)
		if absf(t - 2.0) < 0.01:
			mould_at_2 = mb
		pool_peak = maxf(pool_peak, _boost(m, "LightPool"))
		if poured[0] > 0.0 and not sparks_at_hit:
			sparks_at_hit = sparks.emitting
		if steam_t < 0.0 and steam.emitting and t > 1.0:
			steam_t = t
	var sprue: Vector3 = m.call(&"get_sprue_point")
	print("forge: tilt %.0f deg, bellows %.2f..%.2f, pour %.2f..%.2f s (bottom y %.2f at 0.5 s), poured at %.2f s at %s (sprue %s), mould peak %.2f -> %.2f at 2 s, pool peak %.2f, steam at %.2f s"
		% [rad_to_deg(-min_tilt), leather_lo, leather_hi, pour_first, pour_last, pour_bottom_at_hit, poured[0], poured[1], sprue,
		mould_peak, mould_at_2, pool_peak, steam_t])
	_check(rad_to_deg(-min_tilt) >= 30.0, "the crucible tips toward the mould (%.0f deg)" % rad_to_deg(-min_tilt))
	_check(leather_hi - leather_lo > 0.4, "the bellows pump")
	_check(pour_first > 0.2 and pour_first < 0.35 and pour_last > 1.0 and pour_last < 1.3, "the pour runs ~0.26-1.2 s")
	_check(absf(pour_bottom_at_hit - float(_const(m, "SPROUT_TOP"))) < 0.05, "the stream reaches the sprue")
	_check(absf(float(poured[0]) - 0.4) < 0.04, "forge_poured at 0.4 s (%.2f)" % poured[0])
	_check((poured[1] as Vector3).distance_to(sprue) < 0.01, "forge_poured at the sprue")
	_check(sparks_at_hit and sparks.position.distance_to(_sprue_local(m)) < 0.01, "sparks burst at the sprue")
	_check(mould_peak > 2.5, "the mould flashes white-hot (%.2f)" % mould_peak)
	_check(mould_at_2 < mould_peak * 0.6, "the cast cools")
	_check(pool_peak > 1.6, "the floor flares (%.2f)" % pool_peak)
	_check(absf(steam_t - 1.3) < 0.05, "steam at 1.3 s (%.2f)" % steam_t)
	_check(not bool(m.call(&"is_forging")) and absf(pivot.rotation.x) < 0.001 and not pour.visible, "back upright after 2.2 s")
	# the tipped annex stays inside its footprint too
	m.call(&"play_forge")
	await _frames(40)
	var bt := _bounds(m)
	print("bounds (tipped, pouring): x %.2f..%.2f, y ..%.2f, z %.2f..%.2f" % [bt.position.x, bt.end.x, bt.end.y, bt.position.z, bt.end.z])
	_check(bt.position.z >= -fh.y - 0.01 and bt.end.z <= fh.y + 0.01 and absf(bt.position.x) <= fh.x + 0.01
		and bt.end.y <= 3.0, "tipped: inside the footprint")
	# retrigger restarts
	m.call(&"play_forge")
	await _frames(2)
	_check(float(m.get(&"_forge_t")) < 0.1, "retrigger restarts the forge")
	var idle_forge := await _until_idle(m, 480)
	print("forge: idle %.2f s after the retrigger (the cast cools)" % idle_forge)
	_check(idle_forge > 2.0 and idle_forge < 7.0, "idle again after the forge (mould back at rest, %.2f s)" % idle_forge)

	# ---- a lit annex costs nothing per frame; 10 annexes forging
	var many: Array[Node3D] = []
	for i: int in 10:
		var a: Node3D = ps.instantiate()
		a.position = Vector3(-20.0 + 4.0 * i, 0, 15)
		world.add_child(a)
		a.call(&"set_crucible", true, true)
		many.append(a)
	await _frames(2)
	for a: Node3D in many:
		a.call(&"play_forge")
	var us := Time.get_ticks_usec()
	for i: int in 60:
		for a: Node3D in many:
			a.call(&"_apply", DT)
	print("forging annex animation: %.4f ms per annex per frame" % (float(Time.get_ticks_usec() - us) / 600.0 / 1000.0))

	# ---- put out
	m.call(&"set_crucible", false)
	await _frames(60)
	var h1 := float(m.call(&"heat"))
	await _frames(75)
	print("cooling: heat %.2f at 1 s, %.2f at 2.25 s" % [h1, float(m.call(&"heat"))])
	_check(h1 > 0.3 and h1 < 0.7, "cools gradually (%.2f at 1 s)" % h1)
	_check(float(m.call(&"heat")) == 0.0 and (m.get_node("CruciblePivot/Crust") as Node3D).visible
		and not (m.get_node("CruciblePivot/Molten") as Node3D).visible, "out: back to the crust")
	_check(not (m.get_node("Embers") as GPUParticles3D).emitting, "out: no embers")
	var idle_out := await _until_idle(m, 300)
	_check(idle_out >= 0.0, "out: idle")
	# instant off / on (save restore, Roost destroyed)
	m.call(&"set_crucible", true, true)
	_check(float(m.call(&"heat")) >= 1.0 and (m.get_node("CruciblePivot/Molten") as Node3D).visible, "instant on")
	m.call(&"set_crucible", false, true)
	_check(float(m.call(&"heat")) == 0.0 and (m.get_node("CruciblePivot/Crust") as Node3D).visible, "instant off")

	world.queue_free()
	await _frames(2)
	_finish()


## Frames until the annex stops processing (seconds), -1 if it never does within max_frames.
func _until_idle(m: Node, max_frames: int) -> float:
	for i: int in max_frames:
		if not m.is_processing():
			return float(i) * DT
		await process_frame
	return -1.0


static func _const(m: Node, nm: String) -> Variant:
	return (m.get_script() as Script).get_script_constant_map()[nm]


## The sprue point in annex space.
static func _sprue_local(m: Node3D) -> Vector3:
	return m.global_transform.affine_inverse() * (m.call(&"get_sprue_point") as Vector3)


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
