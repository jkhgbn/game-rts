extends SceneTree
## Task 12.V19: the Essence well capture-point model (art/buildings/capture/essence_well/essence_well.tscn).
## Run: godot --headless --path . -s tests/test_12_v19.gd --fixed-fps 60 --quit-after 600
## Checks: the scene instantiates headless; every hook is callable before _ready and its value shows once the well
## enters the tree; 0 lights; 4 draw nodes, shared baked meshes (indexed) and shared .tres materials (no material made
## at runtime, no override); the body fits the 3 x 3 footprint (+0.3 m below 2.5 m, low decor within the 3.5 m
## clearing) and is ~4 m tall; mist particles are few and near-camera only; owner / capture / pulse / selection reach
## the shaders and blend; the model stops processing when idle.

const TASK_ID := "12.v19"
const WELL_PATH := "res://art/buildings/capture/essence_well/essence_well.tscn"
const DIR := "res://art/buildings/capture/essence_well/"
const FIRE := Color(0.85, 0.30, 0.12)
const ICE := Color(0.45, 0.75, 1.0)
const NATURE := Color(0.45, 0.8, 0.35)
const FIRE_GLOW := Color(1.0, 0.55, 0.15)
const NATURE_GLOW := Color(0.75, 1.0, 0.40)
const NEUTRAL := Color(0.52, 0.36, 0.80)

var frame := 0
var _a: Node3D   # hooks set before _ready: fire owner, ice capturing 50 %, selected, pulse
var _b: Node3D   # plain neutral
var _extra: Array[Node3D] = []
var _errors: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	var scene := load(WELL_PATH) as PackedScene
	if scene == null:
		_fail("scene does not load")
		return
	var world := Node3D.new()
	world.name = "World"
	root.add_child(world)
	_a = scene.instantiate() as Node3D
	for m: StringName in [&"set_owner_color", &"get_owner_color", &"set_capture", &"get_capture_ratio", &"play_pulse",
			&"is_pulse_playing", &"set_selected"]:
		_check(_a.has_method(m), "well lacks %s" % m)
	_a.call(&"set_owner_color", FIRE)
	_a.call(&"set_capture", ICE, 0.5)
	_a.call(&"set_selected", true)
	_a.call(&"play_pulse")
	_a.position = Vector3(-8, 0, 0)
	world.add_child(_a)
	_b = scene.instantiate() as Node3D
	_b.position = Vector3(8, 0, 0)
	world.add_child(_b)
	for i: int in 6:
		var w := scene.instantiate() as Node3D
		w.position = Vector3(-20.0 + i * 8.0, 0, 20.0)
		world.add_child(w)
		_extra.append(w)


func _process(_delta: float) -> bool:
	if not _errors.is_empty():
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return true
	frame += 1
	match frame:
		3:
			_check_static()
			_check_early_hooks()
		5:
			_b.call(&"set_owner_color", NATURE)
			_a.call(&"set_capture", null, 0.0)
			_a.call(&"set_selected", false)
		8:
			_check(_param(_b, "Body", &"flare") > 0.0, "no flare when the owner changes")
			_check(_b.is_processing(), "the well must process while it blends")
		150:
			_check_blended()
			_b.call(&"set_owner_color", null)
			_b.call(&"set_capture", FIRE, 7.0)
			_b.call(&"play_pulse")
		162:
			var p: float = _param(_b, "Fx", &"pulse")
			_check(p > 0.05 and p < 0.3, "pulse not running on the ring (pulse %.2f)" % p)
			_check(bool(_b.call(&"is_pulse_playing")), "is_pulse_playing() false during the pulse")
		320:
			_check_after()
			if _errors.is_empty():
				print("PASS %s" % TASK_ID)
			else:
				print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
			return true
	return false


func _fail(msg: String) -> void:
	_errors.append(msg)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_errors.append(msg)


func _count_lights(n: Node) -> int:
	var c: int = 1 if n is Light3D else 0
	for ch: Node in n.get_children():
		c += _count_lights(ch)
	return c


func _param(w: Node3D, node: String, p: StringName) -> float:
	var gi := w.get_node_or_null(NodePath(node)) as GeometryInstance3D
	if gi == null:
		return NAN
	var v: Variant = gi.get_instance_shader_parameter(p)
	return float(v) if v != null else NAN


func _color(w: Node3D, node: String, p: StringName) -> Color:
	var gi := w.get_node_or_null(NodePath(node)) as GeometryInstance3D
	var v: Variant = gi.get_instance_shader_parameter(p) if gi else null
	return v if v is Color else Color(-1, -1, -1)


func _near(a: Color, b: Color, tol: float = 0.02) -> bool:
	return absf(a.r - b.r) < tol and absf(a.g - b.g) < tol and absf(a.b - b.b) < tol


func _check_static() -> void:
	_check(_count_lights(root) == 0, "expected 0 lights, found %d" % _count_lights(root))
	var geo: Array[Node] = _a.find_children("*", "GeometryInstance3D", true, false)
	_check(geo.size() == 4, "expected 4 draw nodes (Body, Essence, Fx, Mist), found %d" % geo.size())
	for nm: String in ["Body", "Essence", "Fx"]:
		var mi := _a.get_node_or_null(NodePath(nm)) as MeshInstance3D
		var mi2 := _b.get_node_or_null(NodePath(nm)) as MeshInstance3D
		_check(mi != null and mi2 != null, "no %s mesh" % nm)
		if mi == null or mi2 == null:
			continue
		_check(mi.mesh == mi2.mesh, "%s mesh not shared between wells" % nm)
		_check(mi.mesh.resource_path.begins_with(DIR), "%s mesh is not the baked .res (%s)" % [nm, mi.mesh.resource_path])
		_check(mi.material_override == null, "%s has a material override" % nm)
		for s: int in mi.mesh.get_surface_count():
			var mat: Material = mi.mesh.surface_get_material(s)
			_check(mat != null and mat.resource_path.ends_with(".tres"), "%s surface %d material not a shared .tres" % [nm, s])
			_check(mi.get_surface_override_material(s) == null, "%s surface %d has an override material" % [nm, s])
			var idx: Variant = mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_INDEX]
			_check(idx is PackedInt32Array and (idx as PackedInt32Array).size() > 0, "%s surface %d not indexed" % [nm, s])
		if nm != "Body":
			_check(mi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "%s must not cast shadows" % nm)
	var body := _a.get_node(^"Body") as MeshInstance3D
	_check(body.mesh.get_surface_count() == 2, "body should have 2 surfaces (painted + contact shadow)")
	var painted: Material = body.mesh.surface_get_material(0)
	_check(painted.resource_path == DIR + "essence_well_painted_mat.tres", "body material %s" % painted.resource_path)
	# Footprint and height: everything above 0.6 m within the 3 x 3 footprint + 0.3 m (roof eaves above 2.5 m up to
	# 0.6 m out, like the tavern); low decor (apron, rubble, fallen boards, prop log foot) within the 3.5 m clearing.
	var verts: PackedVector3Array = body.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var top: float = -INF
	var worst_mid: float = 0.0
	var worst_high: float = 0.0
	var worst_r: float = 0.0
	for v: Vector3 in verts:
		top = maxf(top, v.y)
		var ext: float = maxf(absf(v.x), absf(v.z)) - 1.5
		if v.y > 2.5:
			worst_high = maxf(worst_high, ext)
		elif v.y > 0.6:
			worst_mid = maxf(worst_mid, ext)
		worst_r = maxf(worst_r, Vector2(v.x, v.z).length())
	_check(top > 3.6 and top < 4.8, "well height %.2f (want ~4 m: roof over the winch)" % top)
	_check(worst_mid <= 0.3, "parts between 0.6 and 2.5 m stick out %.2f m past the footprint (> 0.3)" % worst_mid)
	_check(worst_high <= 0.6, "roof sticks out %.2f m past the footprint (> 0.6)" % worst_high)
	_check(worst_r <= 3.4, "decor reaches r %.2f (clearing 3.5)" % worst_r)
	var total: int = verts.size()
	for nm2: String in ["Essence", "Fx"]:
		total += ((_a.get_node(NodePath(nm2)) as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	_check(total <= 9000, "too many vertices: %d" % total)
	# Mist particles: few, near the camera only, cheap.
	var mist := _a.get_node_or_null(^"Mist") as GPUParticles3D
	_check(mist != null, "no Mist particles")
	if mist:
		_check(mist.amount <= 16, "mist amount %d > 16" % mist.amount)
		_check(mist.visibility_range_end > 0.0 and mist.visibility_range_end <= 45.0,
			"mist must be near-camera only (visibility_range_end %.1f)" % mist.visibility_range_end)
		_check(mist.fixed_fps == 30, "mist fixed_fps %d" % mist.fixed_fps)
		_check(mist.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "mist casts shadows")
		_check(mist.process_material.resource_path.ends_with(".tres"), "mist process material not shared")
		var mist_b := _b.get_node(^"Mist") as GPUParticles3D
		_check(mist_b.process_material == mist.process_material and mist_b.draw_pass_1 == mist.draw_pass_1,
			"mist materials not shared")


func _check_early_hooks() -> void:
	# Values given before _ready show at once (no fade in).
	var rc: Color = _color(_a, "Body", &"rune_color")
	_check(_near(rc, FIRE_GLOW), "owner colour set before _ready not on the runes (%s)" % rc)
	_check(absf(_param(_a, "Body", &"rune_energy") - 2.3) < 0.05, "owned rune energy %.2f" % _param(_a, "Body", &"rune_energy"))
	_check(_near(_color(_a, "Fx", &"rune_color"), FIRE_GLOW), "owner colour not on the ground glow")
	_check(absf(_param(_a, "Body", &"cap_ratio") - 0.5) < 0.01, "capture ratio set before _ready lost (%.2f)" % _param(_a, "Body", &"cap_ratio"))
	_check(absf(_param(_a, "Fx", &"cap_ratio") - 0.5) < 0.01, "capture ratio not on the ground arc")
	var cc: Color = _color(_a, "Body", &"cap_color")
	_check(cc.b > 0.9 and cc.r > 0.6, "capture colour (ice glow) wrong: %s" % cc)
	_check(absf(_param(_a, "Body", &"select_k") - 1.0) < 0.01, "set_selected before _ready lost")
	_check(_param(_a, "Fx", &"pulse") >= 0.0, "play_pulse before _ready lost")
	_check(_a.call(&"get_owner_color") is Color, "get_owner_color() should be a Color when owned")
	_check(absf(float(_a.call(&"get_capture_ratio")) - 0.5) < 0.001, "get_capture_ratio() wrong")
	# Neutral: dim violet, idle, not processing.
	_check(_near(_color(_b, "Body", &"rune_color"), NEUTRAL), "neutral runes not dim violet")
	_check(absf(_param(_b, "Body", &"rune_energy") - 0.45) < 0.02, "neutral rune energy %.2f" % _param(_b, "Body", &"rune_energy"))
	_check(_param(_b, "Body", &"cap_ratio") == 0.0, "neutral well shows a capture")
	_check(_param(_b, "Fx", &"pulse") < 0.0, "neutral well shows a pulse")
	_check(_b.call(&"get_owner_color") == null, "get_owner_color() should be null when neutral")
	_check(not _b.is_processing(), "an idle well must not process")
	for w: Node3D in _extra:
		_check(not w.is_processing(), "idle wells must not process")


func _check_blended() -> void:
	_check(_near(_color(_b, "Body", &"rune_color"), NATURE_GLOW), "owner colour did not blend in (%s)" % _color(_b, "Body", &"rune_color"))
	_check(absf(_param(_b, "Body", &"rune_energy") - 2.3) < 0.05, "owned energy not reached")
	_check(_param(_a, "Body", &"cap_ratio") == 0.0, "capture not cleared by set_capture(null, 0)")
	_check(_param(_a, "Body", &"select_k") == 0.0, "selection not cleared")
	_check(_param(_a, "Fx", &"pulse") < 0.0, "pulse did not end")
	_check(not _a.is_processing() and not _b.is_processing(), "wells still processing after settling")


func _check_after() -> void:
	_check(_near(_color(_b, "Body", &"rune_color"), NEUTRAL), "set_owner_color(null) did not return to neutral")
	_check(absf(float(_b.call(&"get_capture_ratio")) - 1.0) < 0.001, "set_capture must clamp the ratio to 1")
	_check(absf(_param(_b, "Body", &"cap_ratio") - 1.0) < 0.02, "capture ratio 1 not shown")
	_check(_param(_b, "Fx", &"pulse") < 0.0 and not bool(_b.call(&"is_pulse_playing")), "pulse did not end")
	_check(not _b.is_processing(), "well still processing after settling")
	_check(_count_lights(root) == 0, "lights appeared")
