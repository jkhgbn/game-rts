extends SceneTree
## Task 12.V18: the Wayshrine model (art/buildings/capture/wayshrine/wayshrine.tscn).
## Run: godot --headless --path . -s tests/test_12_v18.gd --fixed-fps 60 --quit-after 1200
## Checks:
## - the scene instantiates headless; the hooks exist; 0 lights, 0 colliders, 0 particle nodes;
## - shapes: waist-high standing stone (~1.3-1.6 m), rune stone floating at y 1.6 and spinning, everything within the r 3
##   clearing, triangle budget; meshes indexed and shared between shrines; only shared .tres materials (no runtime ones);
## - hooks before _ready are kept (state, owner, capture) and shown at once;
## - asleep neutral = dark and every effect hidden; awake = gold runes + column + rune circle; owned (asleep) = the owner
##   colour, no column; awake overrides the owner colour with gold; set_capture fills the rune circle and the runes in the
##   capturer's colour, null clears it; play_blessing shows the burst for ~1.8 s then hides it; unknown states ignored.

const TASK_ID := "12.v18"
const SCENE := "res://art/buildings/capture/wayshrine/wayshrine.tscn"
const GOLD := Color(1.0, 0.72, 0.28)
const FIRE := Color(0.85, 0.30, 0.12)
const SHADOW := Color(0.42, 0.22, 0.60)

var frame := 0
var _a: Node3D          # plain, set up after _ready
var _b: Node3D          # hooks called before _ready
var _errors: PackedStringArray = PackedStringArray()
var _spin0: float = 0.0


func _initialize() -> void:
	var scene := load(SCENE) as PackedScene
	if scene == null:
		_errors.append("wayshrine.tscn does not load")
		return
	var world := Node3D.new()
	world.name = "World"
	root.add_child(world)
	_a = scene.instantiate() as Node3D
	_a.position = Vector3(-22, 0, -6)
	world.add_child(_a)
	_b = scene.instantiate() as Node3D
	_b.call(&"set_state", &"awake")
	_b.call(&"set_owner_color", SHADOW)
	_b.call(&"set_capture", FIRE, 0.5)
	_b.call(&"set_selected", true)
	_b.position = Vector3(22, 0, 6)
	world.add_child(_b)


func _process(_delta: float) -> bool:
	if not _errors.is_empty() and frame == 0:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return true
	frame += 1
	match frame:
		2:
			_check_static()
			_check_early()
			_check_asleep(_a, "neutral asleep")
			_spin0 = (_a.get_node(^"Float/RuneStone") as Node3D).rotation.y
			_a.call(&"set_state", &"awake")
		100:
			_check_awake(_a)
			_check(absf((_a.get_node(^"Float/RuneStone") as Node3D).rotation.y - _spin0) > 0.3, "the rune stone does not spin")
			var fy: float = (_a.get_node(^"Float") as Node3D).position.y
			# 1.6 x the read scale 1.1 (wayshrine.gd FLOAT_Y 1.76 since the in-game grade pass, 2026-09-30)
			_check(absf(fy - 1.76) < 0.08, "rune stone floats at y %.2f (want 1.76)" % fy)
			_a.call(&"set_state", &"capturing")   # not a model state: ignored
			_check(_a.call(&"get_state") == &"awake", "an unknown state must be ignored")
			_a.call(&"set_capture", SHADOW, 0.4)
		160:
			var ring := _a.get_node(^"Ring") as GeometryInstance3D
			_check(ring.visible, "rune circle hidden while captured")
			var cr: float = float(ring.get_instance_shader_parameter(&"cap_ratio"))
			_check(absf(cr - 0.4) < 0.03, "rune circle cap_ratio %.2f (want 0.4)" % cr)
			_check(_col(ring, &"cap_color").is_equal_approx(SHADOW), "rune circle not in the capturer's colour")
			var stone := _a.get_node(^"Stone") as GeometryInstance3D
			_check(absf(float(stone.get_instance_shader_parameter(&"cap_ratio")) - 0.4) < 0.03, "runes not filling")
			_check(is_equal_approx(float(_a.call(&"get_capture_ratio")), 0.4), "get_capture_ratio")
			# Captured: blessing, back to sleep in the capturer's colour.
			_a.call(&"set_capture", SHADOW, 1.0)
			_a.call(&"play_blessing", SHADOW)
			_a.call(&"set_capture", null, 0.0)
			_a.call(&"set_state", &"asleep")
			_a.call(&"set_owner_color", SHADOW)
		170:
			_check(bool(_a.call(&"is_blessing_playing")), "play_blessing not playing")
			var burst := _a.get_node(^"Burst") as GeometryInstance3D
			_check(burst.visible, "blessing burst hidden")
			_check(_col(burst, &"fx_color").is_equal_approx(SHADOW), "blessing burst not in the given colour")
			_check(float(burst.get_instance_shader_parameter(&"burst")) > 0.0, "burst progress not moving")
			_check((_a.get_node(^"Column") as GeometryInstance3D).visible, "the column must flash on the blessing")
		330:
			_check(not bool(_a.call(&"is_blessing_playing")), "blessing still playing after 2.7 s")
			_check(not (_a.get_node(^"Burst") as GeometryInstance3D).visible, "burst still visible")
			_check_owned(_a, SHADOW)
			_check(float(_a.call(&"get_capture_ratio")) == 0.0, "set_capture(null) must clear")
			var ring2 := _a.get_node(^"Ring") as GeometryInstance3D
			_check(float(ring2.get_instance_shader_parameter(&"cap_ratio")) < 0.01, "capture arc not cleared")
			# Neutral again, awake again: gold even though it was owned before.
			_a.call(&"set_owner_color", null)
			_check(_a.call(&"get_owner_color") == null, "set_owner_color(null) must make it neutral")
			_b.call(&"set_capture", null, 0.0)
			_b.call(&"set_state", &"asleep")
		450:
			_check_asleep(_a, "neutral again")
			_check_owned(_b, SHADOW)
			_check(_count(root, "Light3D") == 0, "lights appeared")
			if _errors.is_empty():
				print("PASS %s" % TASK_ID)
			else:
				print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
			return true
	return false


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_errors.append(msg)


func _col(gi: GeometryInstance3D, p: StringName) -> Color:
	var v: Variant = gi.get_instance_shader_parameter(p)
	return v if v is Color else Color(0, 0, 0, 0)


func _count(n: Node, cls: String) -> int:
	var c: int = 1 if n.is_class(cls) else 0
	for ch: Node in n.get_children():
		c += _count(ch, cls)
	return c


func _check_static() -> void:
	for m: StringName in [&"set_state", &"get_state", &"is_awake", &"set_owner_color", &"get_owner_color", &"set_capture",
			&"get_capture_ratio", &"play_blessing", &"is_blessing_playing", &"set_selected"]:
		_check(_a.has_method(m), "wayshrine lacks %s" % m)
	_check(_count(root, "Light3D") == 0, "expected 0 lights, found %d" % _count(root, "Light3D"))
	_check(_count(root, "CollisionObject3D") + _count(root, "CollisionShape3D") == 0, "the wayshrine must have no collider")
	_check(_count(root, "GPUParticles3D") + _count(root, "CPUParticles3D") == 0, "no particle nodes expected")
	for nm: String in ["Stone", "Contact", "Ring", "Burst", "Column", "Motes", "Float", "Float/RuneStone", "Float/Halo",
			"Float/Orbit/Shards"]:
		_check(_a.get_node_or_null(NodePath(nm)) != null, "wayshrine lacks %s" % nm)
	var stone := _a.get_node_or_null(^"Stone") as MeshInstance3D
	var rune := _a.get_node_or_null(^"Float/RuneStone") as MeshInstance3D
	if stone == null or rune == null:
		return
	# Shapes.
	var sb: AABB = stone.mesh.get_aabb()
	_check(sb.end.y > 1.2 and sb.end.y < 1.65, "standing stone top %.2f (waist-high: 1.2-1.65)" % sb.end.y)
	_check(maxf(maxf(-sb.position.x, sb.end.x), maxf(-sb.position.z, sb.end.z)) < 3.0, "stones outside the r 3 clearing: %s" % sb)
	var rb: AABB = rune.mesh.get_aabb()
	_check(rb.size.y > 0.6 and rb.size.y < 1.3, "rune stone height %.2f" % rb.size.y)
	_check(1.6 + rb.position.y > sb.end.y - 0.35, "rune stone sinks into the standing stone")
	var tris: int = 0
	for gi: Node in _a.find_children("*", "MeshInstance3D", true, false):
		var mi := gi as MeshInstance3D
		for s: int in mi.mesh.get_surface_count():
			var n_idx: int = mi.mesh.surface_get_array_index_len(s)
			_check(n_idx > 0, "%s surface %d is not indexed" % [mi.name, s])
			tris += n_idx / 3
	_check(tris < 2600, "wayshrine has %d triangles (budget 2 600)" % tris)
	# Shared meshes and shared .tres materials only (no runtime materials).
	for nm2: String in ["Stone", "Float/RuneStone", "Column", "Ring"]:
		var ma := _a.get_node(NodePath(nm2)) as MeshInstance3D
		var mb := _b.get_node(NodePath(nm2)) as MeshInstance3D
		_check(ma.mesh == mb.mesh, "%s mesh not shared between shrines" % nm2)
	for g: Node in _a.find_children("*", "GeometryInstance3D", true, false):
		var mi2 := g as MeshInstance3D
		_check(mi2.material_override == null, "%s has a material override" % mi2.name)
		for s2: int in mi2.mesh.get_surface_count():
			var mat: Material = mi2.get_active_material(s2)
			_check(mat != null and mat.resource_path.ends_with(".tres"), "%s uses a non-.tres material" % mi2.name)
			_check(mi2.get_surface_override_material(s2) == null, "%s has a surface override" % mi2.name)
	_check(stone.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "the stones should cast shadows")
	for fx: String in ["Contact", "Ring", "Burst", "Column", "Motes", "Float/Halo"]:
		_check((_a.get_node(NodePath(fx)) as GeometryInstance3D).cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
			"%s must not cast shadows" % fx)


func _check_early() -> void:
	_check(_b.call(&"get_state") == &"awake", "set_state before _ready lost")
	var oc: Variant = _b.call(&"get_owner_color")
	_check(oc is Color and (oc as Color).is_equal_approx(SHADOW), "set_owner_color before _ready lost")
	_check(is_equal_approx(float(_b.call(&"get_capture_ratio")), 0.5), "set_capture before _ready lost")
	# Shown at once (no fade from dark at spawn).
	var col := _b.get_node(^"Column") as GeometryInstance3D
	_check(col.visible and float(col.get_instance_shader_parameter(&"fx_energy")) > 1.0, "early awake: column not lit at once")
	var ring := _b.get_node(^"Ring") as GeometryInstance3D
	_check(absf(float(ring.get_instance_shader_parameter(&"cap_ratio")) - 0.5) < 0.01, "early capture not shown at once")
	var stone := _b.get_node(^"Stone") as GeometryInstance3D
	_check(float(stone.get_instance_shader_parameter(&"select_k")) > 0.99, "set_selected before _ready lost")
	_check(_col(stone, &"rune_color").is_equal_approx(GOLD), "awake must show gold over the owner colour")


func _check_asleep(s: Node3D, label: String) -> void:
	for fx: String in ["Column", "Motes", "Ring", "Burst", "Float/Halo"]:
		_check(not (s.get_node(NodePath(fx)) as GeometryInstance3D).visible, "%s: %s should be hidden" % [label, fx])
	var stone := s.get_node(^"Stone") as GeometryInstance3D
	_check(float(stone.get_instance_shader_parameter(&"rune_energy")) <= 0.2, "%s: runes not dark" % label)
	_check(not bool(s.call(&"is_awake")), "%s: is_awake" % label)


func _check_awake(s: Node3D) -> void:
	var stone := s.get_node(^"Stone") as GeometryInstance3D
	_check(_col(stone, &"rune_color").is_equal_approx(GOLD), "awake runes not gold")
	_check(float(stone.get_instance_shader_parameter(&"rune_energy")) >= 2.5, "awake runes too dim")
	var rune := s.get_node(^"Float/RuneStone") as GeometryInstance3D
	_check(float(rune.get_instance_shader_parameter(&"rune_energy")) >= 3.0, "awake rune stone too dim")
	for fx: String in ["Column", "Motes", "Ring", "Float/Halo"]:
		var gi := s.get_node(NodePath(fx)) as GeometryInstance3D
		_check(gi.visible, "awake: %s hidden" % fx)
	var col := s.get_node(^"Column") as GeometryInstance3D
	_check(_col(col, &"fx_color").is_equal_approx(GOLD), "awake column not gold")
	_check(float(col.get_instance_shader_parameter(&"grow")) > 0.99, "the column did not finish rising")


func _check_owned(s: Node3D, c: Color) -> void:
	var stone := s.get_node(^"Stone") as GeometryInstance3D
	_check(_col(stone, &"rune_color").is_equal_approx(c), "owned runes not in the owner colour (%s)" % _col(stone, &"rune_color"))
	var e: float = float(stone.get_instance_shader_parameter(&"rune_energy"))
	_check(e > 1.0 and e < 2.2, "owned rune energy %.2f (want a calm ~1.5)" % e)
	_check(not (s.get_node(^"Column") as GeometryInstance3D).visible, "owned asleep: the column should be off")
	_check((s.get_node(^"Ring") as GeometryInstance3D).visible, "owned: the rune circle should show the owner colour")
	_check(_col(s.get_node(^"Ring") as GeometryInstance3D, &"fx_color").is_equal_approx(c), "owned ring not in the owner colour")
