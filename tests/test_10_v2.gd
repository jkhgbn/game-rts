extends SceneTree
## Task 10.V2: the Gloom Bazaar model (res://art/buildings/market/shadow/market_shadow.tscn).
## Run: godot --headless --path . -s tests/test_10_v2.gd --fixed-fps 60 --quit-after 1200
## Checks: the scene instantiates headless; every hook exists and is safe before _ready (cached); 0 real lights;
## the parts (dais, stall, awning, night stall, mast with scale + coin); the mast is the dominant vertical (~9 m) and
## the hooded tent the secondary; nothing below 2.5 m leaves the 6 x 6 footprint by more than 0.3 m; <= 16 visible mesh
## nodes and merged meshes shared between instances; construction 0 -> 1 (parts hidden / outline / scaffold / pools);
## HP 40 % (torn awning, coin lost), 20 % (mast banner gone), healed back; play_delivery tips the beam (pans stay level,
## glints fire) and settles; no-op on a site; team colour reaches the team and cloth materials; play_destroyed topples
## the mast, shows the wreck and emits destroyed_finished.

const TASK_ID := "10.v2"
const PATH := "res://art/buildings/market/shadow/market_shadow.tscn"
const BLUE := Color(0.2, 0.45, 0.95)

var frame := 0
var _m: Node3D          # main model (hooks exercised in order)
var _site: Node3D       # stays a construction site
var _early: Node3D      # hooks called before _ready
var _crowd: Array[Node3D] = []
var _finished: int = 0
var _errors: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	var ps := load(PATH) as PackedScene
	if ps == null:
		_errors.append("scene does not load")
		return
	var world := Node3D.new()
	world.name = "World"
	root.add_child(world)
	_m = ps.instantiate() as Node3D
	world.add_child(_m)
	_m.connect(&"destroyed_finished", func() -> void: _finished += 1)
	_site = ps.instantiate() as Node3D
	_site.position = Vector3(12, 0, 0)
	_site.call(&"set_construction_progress", 0.4)
	world.add_child(_site)
	_early = ps.instantiate() as Node3D
	_early.position = Vector3(-12, 0, 0)
	_early.call(&"set_team_color", BLUE)
	_early.call(&"set_construction_progress", 0.0)
	_early.call(&"set_health_ratio", 0.3)
	_early.call(&"set_selected", true)
	_early.call(&"play_training_pulse")
	_early.call(&"play_delivery")
	world.add_child(_early)
	for i: int in 8:
		var c := ps.instantiate() as Node3D
		c.position = Vector3(-20.0 + 6.0 * i, 0, 20.0)
		c.rotation.y = PI * 0.5 * i
		world.add_child(c)
		_crowd.append(c)


func _process(_delta: float) -> bool:
	frame += 1
	if not _errors.is_empty() and frame < 3:
		return _finish()
	match frame:
		3:
			_check_static()
			_check_early()
			_m.call(&"set_construction_progress", 0.0)
		5:
			_check_site_zero()
			_m.call(&"set_construction_progress", 0.5)
		7:
			_check_half()
			_m.call(&"play_delivery")   # a site ignores deliveries
		8:
			_check(not bool(_m.call(&"is_delivery_playing")), "play_delivery must be a no-op on a site")
			_m.call(&"set_construction_progress", 1.0)
		10:
			_check_built()
			_m.call(&"play_delivery")
		25:
			_check_delivery_peak()
		300:
			_check_delivery_settled()
			_m.call(&"set_health_ratio", 0.4)
		302:
			_check_hp40()
			_m.call(&"set_health_ratio", 0.2)
		304:
			_check_hp20()
			_m.call(&"set_health_ratio", 1.0)
		306:
			_check_healed()
			_m.call(&"set_selected", true)
			_m.call(&"set_team_color", BLUE)
			_m.call(&"play_training_pulse")
		310:
			_check_team()
			_m.call(&"play_destroyed")
			_m.call(&"play_delivery")   # ignored once dead
		400:
			_check_mid_collapse()
		520:
			_check_destroyed()
			return _finish()
	return false


func _finish() -> bool:
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	return true


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_errors.append(msg)


func _count_lights(n: Node) -> int:
	var c: int = 1 if n is Light3D else 0
	for ch: Node in n.get_children():
		c += _count_lights(ch)
	return c


func _visible_meshes(n: Node) -> int:
	var c: int = 1 if n is MeshInstance3D and (n as MeshInstance3D).visible else 0
	for ch: Node in n.get_children():
		if ch is Node3D and not (ch as Node3D).visible:
			continue
		c += _visible_meshes(ch)
	return c


func _node(m: Node, path: String) -> Node3D:
	var n := m.get_node_or_null(path) as Node3D
	_check(n != null, "missing node %s" % path)
	return n


## World-space top of every visible mesh under `n` (rotation-free models: position offsets only).
func _top_of(n: Node) -> float:
	var top: float = -INF
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if not mi.is_visible_in_tree() or mi.mesh == null:
			continue
		var box: AABB = mi.global_transform * mi.mesh.get_aabb()
		top = maxf(top, box.end.y)
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		top = maxf(top, ((n as MeshInstance3D).global_transform * (n as MeshInstance3D).mesh.get_aabb()).end.y)
	return top


func _check_static() -> void:
	var lights: int = _count_lights(root)
	_check(lights == 0, "expected 0 lights in the tree, found %d" % lights)
	for meth: StringName in [&"set_team_color", &"set_construction_progress", &"set_health_ratio", &"set_selected",
			&"play_training_pulse", &"play_destroyed", &"play_delivery", &"is_delivery_playing"]:
		_check(_m.has_method(meth), "model lacks %s" % meth)
	_check(_m.has_signal(&"destroyed_finished"), "model lacks destroyed_finished")
	for p: String in ["Body/PlinthBase", "Body/StallFrame", "Body/Awning/AwningWhole", "Body/Awning/AwningTorn",
			"Body/Awning/LanternPivot", "Body/NightStall", "Body/Mast/MastStack", "Body/Mast/MastBanner",
			"Body/Mast/CoinPivot/CoinMesh", "Body/Mast/ScalePivot/ScaleBeam/BeamMesh",
			"Body/Mast/ScalePivot/ScaleBeam/PanL/PanLMesh", "Body/Mast/ScalePivot/ScaleBeam/PanR/PanRMesh",
			"Body/BannerL", "Scaffold", "Wreck", "LightPool", "MouthPool"]:
		_node(_m, p)
	if not _errors.is_empty():
		return
	# Silhouette: the mast (with its coin) is the dominant vertical, the hooded tent the secondary.
	var mast_top: float = _top_of(_m.get_node(^"Body/Mast"))
	var tent_top: float = _top_of(_m.get_node(^"Body/NightStall"))
	var stall_top: float = _top_of(_m.get_node(^"Body/Awning"))
	_check(mast_top > 8.4 and mast_top < 9.8, "mast + coin top %.2f (want ~9 m)" % mast_top)
	_check(tent_top > 4.6 and tent_top < mast_top - 2.5, "tent top %.2f should be the secondary height" % tent_top)
	_check(stall_top < tent_top, "awning %.2f should stay below the tent %.2f" % [stall_top, tent_top])
	# Footprint: below 2.5 m nothing leaves the 6 x 6 m square by more than 0.3 m (the gate path is ground decor).
	var worst: float = 0.0
	for nm: String in ["Body/StallFrame", "Body/NightStall", "Body/Mast/MastStack", "Body/Awning/AwningWhole"]:
		var mi := _m.get_node(nm) as MeshInstance3D
		var xf: Transform3D = mi.global_transform
		for s: int in mi.mesh.get_surface_count():
			var verts: PackedVector3Array = mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
			for v: Vector3 in verts:
				var w: Vector3 = xf * v
				if w.y < 2.5:
					worst = maxf(worst, maxf(absf(w.x), absf(w.z)) - 3.0)
	_check(worst <= 0.3, "ground-level overhang %.2f m > 0.3" % worst)
	# Budget: <= 16 visible mesh nodes (the Gloom Hall's), few surfaces per merged mesh, meshes shared.
	var vis: int = _visible_meshes(_m)
	_check(vis <= 16, "%d visible mesh nodes (max 16)" % vis)
	for nm: String in ["Body/PlinthBase", "Body/StallFrame", "Body/NightStall", "Body/Mast/MastStack"]:
		var mi := _m.get_node(nm) as MeshInstance3D
		_check(mi.mesh.get_surface_count() <= 8, "%s has %d surfaces" % [nm, mi.mesh.get_surface_count()])
		var other := _crowd[3].get_node(nm) as MeshInstance3D
		_check(other.mesh == mi.mesh, "%s mesh not shared between instances" % nm)
		_check(other.get_surface_override_material(0) != mi.get_surface_override_material(0),
			"%s materials must be per instance" % nm)
	var verts_total: int = 0
	for g: Node in _m.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh is ArrayMesh:
			for s: int in mi.mesh.get_surface_count():
				verts_total += (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	_check(verts_total < 16000, "%d vertices (max 16000)" % verts_total)
	print("INFO %s: mast %.2f m, tent %.2f m, awning %.2f m, overhang %.2f m, %d mesh nodes, %d vertices" % [TASK_ID,
		mast_top, tent_top, stall_top, worst, vis, verts_total])


func _check_early() -> void:
	# Hooks called before _ready were kept: site at 0 (only the dais), blue team, HP 30 % (not applied on a site).
	var mast := _early.get_node_or_null(^"Body/Mast") as Node3D
	_check(mast != null and not mast.visible, "early set_construction_progress(0) lost")
	var team: Variant = (_early.get("mat_team") as ShaderMaterial).get_shader_parameter(&"base_color")
	_check(team is Color and (team as Color).is_equal_approx(BLUE), "early set_team_color lost")
	_check(not bool(_early.call(&"is_delivery_playing")), "a delivery on a site (before _ready) must be ignored")
	# The site model at 40 %: the dais and the stall are up, the mast top is not finished.
	var outline := _site.get_node_or_null(^"BuildOutline") as Node3D
	_check(outline != null and outline.visible, "site outline hidden")
	var sc := _site.get_node_or_null(^"Scaffold") as Node3D
	_check(sc != null and sc.visible, "site scaffold hidden")


func _check_site_zero() -> void:
	for nm: String in ["Body/Mast", "Body/Awning", "Body/NightStall", "Body/StallFrame"]:
		_check(not (_m.get_node(nm) as Node3D).visible, "%s visible at progress 0" % nm)
	_check((_m.get_node(^"BuildOutline") as Node3D).visible, "no outline at progress 0")
	_check(not (_m.get_node(^"LightPool") as Node3D).visible, "light pool on at progress 0")


func _check_half() -> void:
	_check((_m.get_node(^"Body/StallFrame") as Node3D).visible, "stall hidden at 50 %")
	_check((_m.get_node(^"Scaffold") as Node3D).visible, "scaffold hidden at 50 %")


func _check_built() -> void:
	for nm: String in ["Body/Mast", "Body/Awning", "Body/NightStall", "Body/StallFrame", "LightPool", "MouthPool"]:
		_check((_m.get_node(nm) as Node3D).visible, "%s hidden when built" % nm)
	_check(not (_m.get_node(^"Scaffold") as Node3D).visible, "scaffold visible when built")
	_check(not (_m.get_node(^"Body/Awning/AwningTorn") as Node3D).visible, "torn awning visible at full HP")


func _check_delivery_peak() -> void:
	var beam := _m.get_node(^"Body/Mast/ScalePivot/ScaleBeam") as Node3D
	_check(bool(_m.call(&"is_delivery_playing")), "delivery not playing")
	_check(beam.rotation.z > 0.12, "the beam did not tip toward the gold pan (%.3f rad)" % beam.rotation.z)
	for p: String in ["Body/Mast/ScalePivot/ScaleBeam/PanL", "Body/Mast/ScalePivot/ScaleBeam/PanR"]:
		var pan := _m.get_node(p) as Node3D
		var up: Vector3 = pan.global_transform.basis.y.normalized()
		_check(up.dot(Vector3.UP) > 0.999, "%s not level while tipping" % p)
	# (One-shot particles report emitting = false at once under the headless dummy renderer: check the node only.)
	var gl := _m.get_node_or_null(^"Body/Mast/ScalePivot/ScaleBeam/PanL/DeliveryGlints") as GPUParticles3D
	_check(gl != null and gl.one_shot, "no one-shot delivery glints on the gold pan")
	var boost: Variant = (_m.get("_g_coin") as ShaderMaterial).get_shader_parameter(&"boost")
	_check(boost != null and float(boost) > 1.8, "the coin did not flare on delivery (boost %s)" % str(boost))


func _check_delivery_settled() -> void:
	var beam := _m.get_node(^"Body/Mast/ScalePivot/ScaleBeam") as Node3D
	_check(not bool(_m.call(&"is_delivery_playing")), "delivery still playing after 4.8 s")
	_check(absf(beam.rotation.z) < 0.05, "beam did not settle (%.3f rad)" % beam.rotation.z)


func _check_hp40() -> void:
	_check(not (_m.get_node(^"Body/Awning/AwningWhole") as Node3D).visible, "whole awning still shown at 40 %")
	_check((_m.get_node(^"Body/Awning/AwningTorn") as Node3D).visible, "torn awning not shown at 40 %")
	_check(not (_m.get_node(^"Body/Mast/CoinPivot") as Node3D).visible, "coin emblem not lost at 40 %")
	_check((_m.get_node(^"Body/Smoke1") as GPUParticles3D).emitting, "no smoke at 40 %")
	_check((_m.get_node(^"Body/Mast/MastBanner") as Node3D).visible, "mast banner lost too early")


func _check_hp20() -> void:
	_check(not (_m.get_node(^"Body/Mast/MastBanner") as Node3D).visible, "mast banner still shown at 20 %")
	_check((_m.get_node(^"Body/Blaze1") as GPUParticles3D).emitting, "no fire at 20 %")


func _check_healed() -> void:
	_check((_m.get_node(^"Body/Awning/AwningWhole") as Node3D).visible, "awning not restored when healed")
	_check(not (_m.get_node(^"Body/Awning/AwningTorn") as Node3D).visible, "torn awning still shown when healed")
	_check((_m.get_node(^"Body/Mast/CoinPivot") as Node3D).visible, "coin not restored when healed")
	_check((_m.get_node(^"Body/Mast/MastBanner") as Node3D).visible, "mast banner not restored when healed")
	_check(not (_m.get_node(^"Body/Smoke1") as GPUParticles3D).emitting, "smoke still on when healed")


func _check_team() -> void:
	var team: Variant = (_m.get("mat_team") as ShaderMaterial).get_shader_parameter(&"base_color")
	_check(team is Color and (team as Color).is_equal_approx(BLUE), "team colour not on mat_team")
	var cloth: Variant = (_m.get("mat_cloth") as ShaderMaterial).get_shader_parameter(&"base_color")
	_check(cloth is Color and (cloth as Color).is_equal_approx(BLUE.darkened(0.4)), "team colour not on mat_cloth")
	var rim: Variant = (_m.get("mat_stone") as ShaderMaterial).get_shader_parameter(&"rim_strength")
	_check(rim != null and float(rim) > 0.5, "selection rim not applied (%s)" % str(rim))
	# The crowd keeps its own colour (materials per instance).
	var other: Variant = (_crowd[0].get("mat_team") as ShaderMaterial).get_shader_parameter(&"base_color")
	_check(not (other as Color).is_equal_approx(BLUE), "team colour leaked to another Bazaar")


func _check_mid_collapse() -> void:
	# 1.5 s into the collapse: the mast is down (hidden), the wreck shows, the pools went out with the lanterns.
	_check(not (_m.get_node(^"Body/Mast") as Node3D).visible, "mast still standing 1.5 s into the collapse")
	_check(not bool(_m.call(&"is_delivery_playing")), "play_delivery must be ignored once destroyed")


func _check_destroyed() -> void:
	_check(_finished == 1, "destroyed_finished emitted %d times" % _finished)
	_check((_m.get_node(^"Wreck") as Node3D).visible, "wreck hidden after the collapse")
	_check(not (_m.get_node(^"LightPool") as Node3D).visible, "light pool still on after the collapse")
	_check(not (_m.get_node(^"Body/Awning") as Node3D).visible, "awning still shown after the collapse")
	_check(_count_lights(root) == 0, "lights appeared")
