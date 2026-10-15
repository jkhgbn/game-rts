extends SceneTree
## Task G-B Fire (docs/art/gb_fire_buildings.md): the Fire buildings' look layer and keep tiers.
##   - Fire Hall / Hearth / Ember Spire / Bazaar / Dragon Roost / Ember Crucible draw their painted parts with
##     fire_painted_vc.gdshader (gb_detail = the graphics tier); the other kingdoms' models built on the same scripts
##     (Ice / Nature / Shadow halls, Hovel, Night Spire) keep painted_vc.
##   - Hearth: one merged painted material (B8 <= 8 unique materials).
##   - Fire Keep: set_tier / set_upgrading / play_tier_up; tier 2 / 3 parts show only when built, the scaffold only while
##     upgrading; each keep's tier parts use that keep's own materials; the collapse hides them.
##   - No heat-haze quad at Low (headless runs are Low).
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_gb_fire.gd --fixed-fps 60 --quit-after 1200

const TASK_ID := "gb_fire"
const FIRE_VC := "res://art/buildings/fire/fire_painted_vc.gdshader"
const PAINTED_VC := "res://art/shaders/painted_vc.gdshader"

var _models: Dictionary = {}
var _keeps: Array[Node3D] = []
var _frame := 0
var _fails: Array[String] = []


func _initialize() -> void:
	var scenes := {
		"hall": "res://art/buildings/fire_hall.tscn",
		"hearth": "res://art/buildings/hearth.tscn",
		"spire": "res://art/buildings/fire_tower.tscn",
		"market": "res://art/buildings/market/fire/market_fire.tscn",
		"roost": "res://art/buildings/lair/fire/dragon_roost.tscn",
		"crucible": "res://art/buildings/fire/ember_crucible/ember_crucible.tscn",
		"crucible2": "res://art/buildings/fire/ember_crucible/ember_crucible.tscn",   # shared .tres: 2nd annex
		"ice_hall": "res://art/buildings/ice_hall.tscn",
		"shadow_hall": "res://art/buildings/shadow_hall.tscn",
		"hovel": "res://art/buildings/hovel.tscn",
		"night_spire": "res://art/buildings/shadow_tower.tscn",
	}
	var x := 0.0
	for k: String in scenes:
		var n: Node3D = (load(scenes[k]) as PackedScene).instantiate()
		n.position = Vector3(x, 0, 20)
		x += 12.0
		root.add_child(n)
		_models[k] = n
	for i: int in 2:
		var kp: Node3D = (load("res://art/buildings/fire_keep.tscn") as PackedScene).instantiate()
		kp.position = Vector3(-20.0 - 12.0 * i, 0, 0)
		root.add_child(kp)
		_keeps.append(kp)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 5:
		_check_materials()
		_check_keep_tiers()
	if _frame == 6:
		_keeps[1].call(&"play_destroyed")
	if _frame == 6 + 150:   # 2.5 s: past the 1.6 s hide step of the collapse
		var t2: Node3D = _keeps[1].find_child("TierStronghold", true, false)
		_check(t2 != null and not t2.visible, "collapse hides the tier parts")
		if _fails.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
		return true
	return false


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  fail: " + what)


func _body_shaders(n: Node) -> Array[String]:
	var out: Array[String] = []
	for g: Node in n.find_children("*", "GeometryInstance3D", true, false):
		for m: Material in _mats_of(g as GeometryInstance3D):
			if m is ShaderMaterial and (m as ShaderMaterial).shader:
				var p: String = (m as ShaderMaterial).shader.resource_path
				if (p == FIRE_VC or p == PAINTED_VC) and not out.has(p):
					out.append(p)
	return out


func _mats_of(g: GeometryInstance3D) -> Array[Material]:
	var out: Array[Material] = []
	if g.material_override:
		out.append(g.material_override)
	if g is MeshInstance3D and (g as MeshInstance3D).mesh:
		var mi := g as MeshInstance3D
		for s: int in mi.mesh.get_surface_count():
			var m: Material = mi.get_surface_override_material(s)
			if m == null:
				m = mi.mesh.surface_get_material(s)
			if m:
				out.append(m)
	return out


func _check_materials() -> void:
	for k: String in ["hall", "hearth", "spire", "market", "roost", "crucible", "crucible2"]:
		var sh: Array[String] = _body_shaders(_models[k])
		_check(sh == [FIRE_VC], "%s paints with fire_painted_vc (got %s)" % [k, str(sh)])
	for k: String in ["ice_hall", "shadow_hall", "hovel", "night_spire"]:
		var sh: Array[String] = _body_shaders(_models[k])
		_check(not sh.has(FIRE_VC), "%s keeps its own look (got %s)" % [k, str(sh)])
	var hall_team: ShaderMaterial = _models["hall"].get(&"mat_team")
	_check(hall_team != null and is_equal_approx(float(hall_team.get_shader_parameter(&"gb_detail")),
		float(GameSettings.effective_graphics_quality())), "hall gb_detail = the graphics tier")
	# Hearth B8 budget (was 11 unique materials).
	var uniq: Dictionary = {}
	for g: Node in (_models["hearth"] as Node).find_children("*", "GeometryInstance3D", true, false):
		for m: Material in _mats_of(g as GeometryInstance3D):
			uniq[m] = true
	_check(uniq.size() <= 8, "hearth unique materials <= 8 (got %d)" % uniq.size())
	# No heat haze at Low (headless).
	for k: String in _models:
		_check((_models[k] as Node).find_child("HeatHaze", true, false) == null, "%s: no heat haze at Low" % k)


func _check_keep_tiers() -> void:
	var k: Node3D = _keeps[0]
	for m: String in ["set_tier", "set_upgrading", "play_tier_up"]:
		_check(k.has_method(m), "keep model has %s" % m)
	var t2: Node3D = k.find_child("TierStronghold", true, false)
	var t3: Node3D = k.find_child("TierCitadel", true, false)
	var crown: Node3D = k.find_child("CitadelCrown", true, false)
	var sc: Node3D = k.find_child("UpgradeScaffold", true, false)
	_check(t2 != null and t3 != null and crown != null and sc != null, "keep tier nodes built")
	if t2 == null or t3 == null or crown == null or sc == null:
		return
	_check(not t2.visible and not t3.visible and not sc.visible, "tier 1: no tier parts")
	k.call(&"set_tier", 2)
	_check(t2.visible and not t3.visible, "tier 2: Stronghold parts only")
	k.call(&"set_tier", 3)
	_check(t2.visible and t3.visible and crown.visible, "tier 3: Stronghold + Citadel parts")
	k.call(&"set_upgrading", true)
	_check(sc.visible, "upgrading: scaffold shown")
	k.call(&"play_tier_up")
	k.call(&"set_construction_progress", 0.5)
	_check(not t2.visible and not t3.visible and not sc.visible, "a rising site hides the tier parts")
	k.call(&"set_construction_progress", 1.0)
	k.call(&"set_upgrading", false)
	_check(t2.visible and not sc.visible, "built again: tier parts back, scaffold gone")
	# Each keep's tier parts draw with that keep's own painted material.
	var k2: Node3D = _keeps[1]
	k2.call(&"set_tier", 2)
	var a: MeshInstance3D = t2.get_node(^"Buttresses") as MeshInstance3D
	var b: MeshInstance3D = (k2.find_child("TierStronghold", true, false) as Node3D).get_node(^"Buttresses") as MeshInstance3D
	_check(a.get_surface_override_material(0) == k.get(&"cap_material"), "keep 1 tier parts use keep 1's material")
	_check(b.get_surface_override_material(0) == k2.get(&"cap_material"), "keep 2 tier parts use keep 2's material")
	_check(a.get_surface_override_material(0) != b.get_surface_override_material(0), "keeps do not share tier materials")
	var pm: ShaderMaterial = k.get(&"cap_material")
	_check(pm != null and pm.get_shader_parameter(&"gb_detail") != null, "keep painted material has gb_detail")
