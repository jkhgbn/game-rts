extends SceneTree
## Task 12.V17: the watchtower capture point model (art/buildings/capture/watchtower/watchtower.tscn).
## Run: $GODOT --headless --path . -s tests/test_12_v17.gd --fixed-fps 60 --quit-after 3000
## Checks: instantiation; budget against the tavern (draw instances, vertices), 0 lights, no particles, shared .tres
## materials, one indexed surface, meshes shared between towers; size (~9 m, 4 x 4 footprint, decor inside the r 4
## clearing); hooks before _ready applied without a transition; neutral / owned / capturing states through the
## instance uniforms (banner, drapes, cresset, flames, ring, rising banner); 1 Hz capture updates shown smoothly;
## capture completion hands the rising banner to the owner banner; play_captured pulse; neutralised; selection;
## glow_for per kingdom; the body faces world +Z under a rotated parent; processing stops when idle.
## Prints "PASS 12.v17" or "FAIL 12.v17: <reasons>".

const TASK_ID := "12.v17"
const SCENE := "res://art/buildings/capture/watchtower/watchtower.tscn"
const DIR := "res://art/buildings/capture/watchtower/"
const TAVERN := "res://art/buildings/tavern/tavern_model.tscn"
const FIRE := Color(0.85, 0.30, 0.12)
const SHADOW := Color(0.42, 0.22, 0.60)
const ICE := Color(0.45, 0.75, 1.0)
const NATURE := Color(0.45, 0.8, 0.35)

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
	for i: int in int(ceil(sec * 60.0)):
		await process_frame


func _spawn(at: Vector3, yaw: float = 0.0) -> Node3D:
	var holder := Node3D.new()
	holder.position = at
	holder.rotation.y = yaw
	_world.add_child(holder)
	var m: Node3D = (load(SCENE) as PackedScene).instantiate()
	holder.add_child(m)
	return m


func _p(n: Node, node_name: String, param: StringName) -> Variant:
	var g := n.find_child(node_name, true, false) as GeometryInstance3D
	if g == null:
		return null
	return g.get_instance_shader_parameter(param)


func _node(n: Node, node_name: String) -> Node3D:
	return n.find_child(node_name, true, false) as Node3D


func _near(a: Variant, b: float, tol: float) -> bool:
	return a != null and absf(float(a) - b) <= tol


func _col_near(a: Variant, b: Color) -> bool:
	return a is Color and Vector3((a as Color).r - b.r, (a as Color).g - b.g, (a as Color).b - b.b).length() < 0.02


func _run() -> void:
	_check(ResourceLoader.exists(SCENE), "watchtower.tscn exists")
	var t0: int = Time.get_ticks_usec()
	var a: Node3D = _spawn(Vector3.ZERO)
	var build_ms: float = float(Time.get_ticks_usec() - t0) / 1000.0
	var t1: int = Time.get_ticks_usec()
	var b: Node3D = _spawn(Vector3(12, 0, 0))
	var second_ms: float = float(Time.get_ticks_usec() - t1) / 1000.0
	print("first tower %.1f ms (loads / builds the meshes), second %.2f ms" % [build_ms, second_ms])
	await process_frame
	_check_budget(a, b)
	_check_size(a)
	await _check_states(a)
	await _check_before_ready()
	await _check_facing()
	_check_glows(a)
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


# ------------------------------------------------------------------------------------------------ budget

func _geoms(n: Node) -> Array[GeometryInstance3D]:
	var out: Array[GeometryInstance3D] = []
	for g: Node in n.find_children("*", "GeometryInstance3D", true, false):
		out.append(g as GeometryInstance3D)
	return out


func _vertices(n: Node) -> int:
	var c := 0
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mesh := (g as MeshInstance3D).mesh
		if mesh:
			for s: int in mesh.get_surface_count():
				c += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return c


func _check_budget(a: Node3D, b: Node3D) -> void:
	var tav: Node3D = null
	if ResourceLoader.exists(TAVERN):
		tav = (load(TAVERN) as PackedScene).instantiate()
		var h := Node3D.new()
		h.position = Vector3(-30, 0, 0)
		_world.add_child(h)
		h.add_child(tav)
	var inst: int = _geoms(a).size()
	var verts: int = _vertices(a)
	var t_inst: int = _geoms(tav).size() if tav else 99
	var t_verts: int = _vertices(tav) if tav else 999999
	var t_draws := 0
	if tav:
		for g: GeometryInstance3D in _geoms(tav):
			var mi := g as MeshInstance3D
			t_draws += mi.mesh.get_surface_count() if mi and mi.mesh else 1
	var draws := 0
	for g: GeometryInstance3D in _geoms(a):
		var mi2 := g as MeshInstance3D
		draws += mi2.mesh.get_surface_count() if mi2 and mi2.mesh else 1
	print("watchtower: %d draw instances, %d surfaces (draw calls max), %d vertices | tavern: %d instances, %d surfaces, %d vertices"
		% [inst, draws, verts, t_inst, t_draws, t_verts])
	_check(inst <= 6, "<= 6 draw instances (got %d)" % inst)
	_check(inst <= t_inst and draws <= t_draws, "within the tavern budget (instances %d / %d, surfaces %d / %d)" % [inst, t_inst, draws, t_draws])
	_check(verts <= t_verts, "vertices within the tavern's (%d / %d)" % [verts, t_verts])
	_check(a.find_children("*", "Light3D", true, false).is_empty(), "0 lights")
	_check(a.find_children("*", "GPUParticles3D", true, false).is_empty() and a.find_children("*", "CPUParticles3D", true, false).is_empty(),
		"no particles (emissive cards only)")
	var mats: Array = []
	for g: GeometryInstance3D in _geoms(a):
		var m: Material = g.material_override
		_check(m != null and m.resource_path.begins_with(DIR) and m.resource_path.ends_with(".tres"),
			"%s uses a shared .tres material (%s)" % [g.name, m.resource_path if m else "none"])
		if m and not mats.has(m):
			mats.append(m)
		var mi := g as MeshInstance3D
		if mi and mi.mesh:
			for s: int in mi.mesh.get_surface_count():
				_check(mi.get_surface_override_material(s) == null, "%s: no per-surface runtime material" % g.name)
	_check(mats.size() <= 5, "<= 5 materials (got %d)" % mats.size())
	for g2: GeometryInstance3D in _geoms(a):
		var other := b.find_child(g2.name, true, false) as GeometryInstance3D
		_check(other != null and other.material_override == g2.material_override, "%s material shared between towers" % g2.name)
		if g2 is MeshInstance3D:
			_check(other is MeshInstance3D and (other as MeshInstance3D).mesh == (g2 as MeshInstance3D).mesh, "%s mesh shared between towers" % g2.name)
	var st := _node(a, "Structure") as MeshInstance3D
	_check(st != null and st.mesh.get_surface_count() == 1, "structure = one surface")
	if st:
		var idx: PackedInt32Array = st.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX]
		var sv: int = (st.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		print("structure: %d vertices, %d triangles (indexed)" % [sv, idx.size() / 3])
		_check(idx.size() > 0, "structure mesh is indexed")
		_check(st.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON, "structure casts the sun shadow")
	for nm: String in ["Flames", "CaptureRing", "ContactDecal", "CaptureBanner"]:
		var g3 := _node(a, nm) as GeometryInstance3D
		_check(g3 != null and g3.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "%s casts no shadow" % nm)


func _check_size(a: Node3D) -> void:
	var st := _node(a, "Structure") as MeshInstance3D
	if st == null:
		_fails.append("no Structure node")
		return
	var verts: PackedVector3Array = st.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var top := 0.0
	var low_r := 0.0
	var body_r := 0.0
	for v: Vector3 in verts:
		top = maxf(top, v.y)
		var r: float = Vector2(v.x, v.z).length()
		if v.y < 2.5:
			low_r = maxf(low_r, maxf(absf(v.x), absf(v.z)))
		if v.y > 1.0 and v.y < 4.5 and r < 1.9:
			body_r = maxf(body_r, r)
	print("height %.2f m, decor below 2.5 m reaches %.2f m, tower body radius %.2f m" % [top, low_r, body_r])
	_check(top > 8.6 and top < 9.8, "about 9 m tall (%.2f)" % top)
	_check(low_r <= 4.0, "everything below 2.5 m inside the r 4 clearing (%.2f)" % low_r)
	_check(body_r > 1.3 and body_r <= 2.0, "tower body (shaft, door, jambs) inside the 4 x 4 footprint (r %.2f)" % body_r)


# ------------------------------------------------------------------------------------------------ states

func _check_states(a: Node3D) -> void:
	# Neutral.
	_check(not a.call(&"is_owned") and a.call(&"get_owner_color") == null, "starts neutral")
	_check(_near(_p(a, "Structure", &"owner_k"), 0.0, 0.001) and _near(_p(a, "Banner", &"owner_k"), 0.0, 0.001),
		"neutral: grey torn banner and drapes (owner_k 0)")
	_check(_near(_p(a, "Structure", &"glow_energy"), 0.0, 0.001) and not _node(a, "Flames").visible, "neutral: cold cresset, no flame")
	_check(not _node(a, "CaptureBanner").visible and not _node(a, "CaptureRing").visible, "neutral: no capture banner / ring")
	await _wait(0.2)
	_check(not a.is_processing(), "idle tower does not process")
	# Owned by Fire.
	a.call(&"set_owner_color", FIRE)
	await _wait(0.25)
	var mid_k: Variant = _p(a, "Banner", &"owner_k")
	_check(mid_k != null and float(mid_k) > 0.1 and float(mid_k) < 0.95, "ownership blends in (owner_k %s after 0.25 s)" % str(mid_k))
	await _wait(1.2)
	_check(a.call(&"is_owned") and _col_near(a.call(&"get_owner_color"), FIRE), "owned by fire")
	_check(_near(_p(a, "Banner", &"owner_k"), 1.0, 0.001) and _col_near(_p(a, "Banner", &"cloth_color"), FIRE), "owned: team colour banner")
	_check(_col_near(_p(a, "Structure", &"owner_color"), FIRE) and _near(_p(a, "Structure", &"owner_k"), 1.0, 0.001), "owned: team colour drapes")
	_check(_node(a, "Flames").visible and _near(_p(a, "Flames", &"energy"), 2.7, 0.05), "owned: the cresset burns (energy 2.7)")
	_check(_col_near(_p(a, "Flames", &"flame_color"), Color(1.0, 0.55, 0.15)) and _col_near(_p(a, "Structure", &"glow_color"), Color(1.0, 0.55, 0.15)),
		"owned: fire glow colour on flame and embers")
	_check(not a.is_processing(), "owned tower idle again after the transition")
	# Capturing by Shadow, 1 Hz updates.
	var cb: Node3D = _node(a, "CaptureBanner")
	a.call(&"set_capture", SHADOW, 0.25)
	await _wait(0.5)
	var d_half: float = float(a.call(&"get_displayed_capture"))
	_check(d_half > 0.05 and d_half < 0.24, "capture display moves toward 0.25 (%.2f after 0.5 s)" % d_half)
	await _wait(0.55)
	_check(absf(float(a.call(&"get_displayed_capture")) - 0.25) < 0.01, "capture display reaches 0.25 in ~1 s")
	_check(cb.visible and _col_near(_p(a, "CaptureBanner", &"cloth_color"), SHADOW), "capture banner in the capturer's colour")
	_check(_node(a, "CaptureRing").visible and _near(_p(a, "CaptureRing", &"ratio"), 0.25, 0.01) and _col_near(_p(a, "CaptureRing", &"ring_color"), SHADOW),
		"progress ring at 0.25 in the capturer's colour")
	var y25: float = cb.position.y
	var ys: Array[float] = []
	for step: int in 3:
		a.call(&"set_capture", SHADOW, 0.25 + 0.25 * float(step + 1))
		for i: int in 60:
			await process_frame
			if i % 15 == 7:
				ys.append(cb.position.y)
	var rising := true
	for i2: int in range(1, ys.size()):
		if ys[i2] <= ys[i2 - 1]:
			rising = false
	_check(rising and ys.size() >= 10, "banner rises continuously between 1 Hz updates (%s)" % str(ys))
	_check(cb.position.y > y25 + 2.0, "banner climbed the pole (%.2f -> %.2f)" % [y25, cb.position.y])
	_check(_near(_p(a, "CaptureRing", &"ratio"), 1.0, 0.02), "ring full at 1.0")
	# Abandoned: slides down and disappears.
	a.call(&"set_capture", SHADOW, 0.5)
	await _wait(1.1)
	a.call(&"set_capture", null, 0.0)
	_check(a.call(&"get_capture_color") == null and float(a.call(&"get_capture_ratio")) == 0.0, "capture cleared")
	await _wait(0.4)
	_check(cb.visible and float(a.call(&"get_displayed_capture")) < 0.45, "abandoned: the banner slides down")
	await _wait(1.2)
	_check(not cb.visible and not _node(a, "CaptureRing").visible, "abandoned: banner and ring gone")
	# Neutralised by Shadow (owner -> neutral), then captured by Shadow.
	a.call(&"set_capture", SHADOW, 1.0)
	await _wait(1.2)
	a.call(&"set_owner_color", null)
	a.call(&"set_capture", null, 0.0)
	await _wait(1.3)
	_check(not a.call(&"is_owned") and _near(_p(a, "Banner", &"owner_k"), 0.0, 0.001), "neutralised: grey torn banner again")
	_check(not _node(a, "Flames").visible and _near(_p(a, "Structure", &"glow_energy"), 0.0, 0.001), "neutralised: the cresset dies")
	a.call(&"set_capture", SHADOW, 1.0)
	await _wait(1.2)
	_check(cb.visible and float(a.call(&"get_displayed_capture")) > 0.99, "captured: the capture banner at the top")
	a.call(&"set_owner_color", SHADOW)
	_check(float(a.call(&"get_displayed_capture")) == 0.0, "captured: the rising banner becomes the owner banner at once")
	a.call(&"set_capture", null, 0.0)
	a.call(&"play_captured")
	await _wait(0.1)
	_check(not cb.visible, "captured: capture banner hidden")
	_check(_node(a, "CaptureRing").visible and float(_p(a, "CaptureRing", &"burst")) > 0.5 and _col_near(_p(a, "CaptureRing", &"ring_color"), SHADOW),
		"play_captured: ring pulse in the new owner's colour")
	_check(float(_p(a, "Structure", &"flash")) > 0.1 and float(_p(a, "Flames", &"height_k")) > 0.4, "play_captured: flash and flare")
	_check(_node(a, "Banner").scale.y > 1.01, "play_captured: the banner pops")
	await _wait(1.6)
	_check(not _node(a, "CaptureRing").visible and _near(_p(a, "Structure", &"flash"), 0.0, 0.001), "pulse over")
	_check(_col_near(_p(a, "Banner", &"cloth_color"), SHADOW) and _col_near(_p(a, "Flames", &"flame_color"), Color(0.70, 0.30, 1.00)),
		"owned by shadow: violet banner and fire")
	_check(not a.is_processing(), "idle after the capture")
	# Selection.
	a.call(&"set_selected", true)
	await _wait(0.3)
	_check(_near(_p(a, "Structure", &"select_k"), 1.0, 0.001), "selected: rim on")
	a.call(&"set_selected", false)
	await _wait(0.4)
	_check(_near(_p(a, "Structure", &"select_k"), 0.0, 0.001), "deselected: rim off")
	# Anchors.
	var beacon: Vector3 = a.call(&"get_beacon_point")
	_check(beacon.y > 7.9 and beacon.y < 8.8 and Vector2(beacon.x, beacon.z).distance_to(Vector2(1.72, 1.72)) < 0.1, "beacon anchor on the pole top (%s)" % beacon)
	var bp: Vector3 = a.call(&"get_banner_point")
	_check(bp.y > 4.5 and bp.y < 7.5, "banner anchor (%s)" % bp)


func _check_before_ready() -> void:
	var m: Node3D = (load(SCENE) as PackedScene).instantiate()
	m.call(&"set_owner_color", ICE)
	m.call(&"set_capture", NATURE, 0.3)
	m.call(&"set_selected", true)
	m.call(&"play_captured")
	var holder := Node3D.new()
	holder.position = Vector3(0, 0, 14)
	_world.add_child(holder)
	holder.add_child(m)
	await process_frame
	_check(_near(_p(m, "Banner", &"owner_k"), 1.0, 0.001) and _col_near(_p(m, "Banner", &"cloth_color"), ICE), "before _ready: owned by ice at once")
	_check(_col_near(_p(m, "Flames", &"flame_color"), Color(0.75, 0.92, 1.0)) and _node(m, "Flames").visible, "before _ready: ice fire lit")
	_check(absf(float(m.call(&"get_displayed_capture")) - 0.3) < 0.001 and _node(m, "CaptureBanner").visible, "before _ready: capture 0.3 shown")
	_check(_near(_p(m, "Structure", &"select_k"), 1.0, 0.001), "before _ready: selected")
	await _wait(1.5)
	_check(not m.is_processing(), "before-ready tower settles")


func _check_facing() -> void:
	var m: Node3D = _spawn(Vector3(0, 0, -14), PI)
	await process_frame
	var body: Node3D = m.get_node("Body")
	_check(body.global_basis.is_equal_approx(Basis.IDENTITY), "rotated parent: the body still faces world +Z")
	(m.get_parent() as Node3D).rotation.y = 1.1
	await process_frame
	_check(body.global_basis.is_equal_approx(Basis.IDENTITY), "re-aligned after the parent turns")
	var beacon: Vector3 = m.call(&"get_beacon_point")
	_check(beacon.z > -14.0, "pole on the camera side (+Z) of a rotated tower")


func _check_glows(a: Node3D) -> void:
	var s: Script = a.get_script()
	var cases: Array = [[FIRE, Color(1.0, 0.55, 0.15)], [SHADOW, Color(0.70, 0.30, 1.00)], [ICE, Color(0.75, 0.92, 1.0)],
		[Color(0.45, 0.75, 0.95), Color(0.75, 0.92, 1.0)], [NATURE, Color(0.75, 1.0, 0.40)], [Color(0.35, 0.70, 0.25), Color(0.75, 1.0, 0.40)]]
	for c: Array in cases:
		_check(_col_near(s.call(&"glow_for", c[0]), c[1]), "glow_for(%s)" % str(c[0]))
	var odd: Color = s.call(&"glow_for", Color(0.3, 1.0, 0.4))
	_check(odd.v > 0.99 and absf(odd.h - Color(0.3, 1.0, 0.4).h) < 0.02, "glow_for(unknown) = the bright same hue")
