extends SceneTree
## Task G-B Ice (docs/art/gb_ice_buildings.md): the Ice buildings' paint layer, warm windows and the keep's tier look.
## - every Ice model (keep, Frost Hall, Snow Lodge, Rime Spire, Ice Wall, Frost Stables, Frost Bazaar, the new Frost Forge
##   model: hooks + collapse, found by ice_forge.tres) draws its painted
##   parts with an Ice shader (ice_painted_vc / ice_painted / ice_stables_painted), gb_detail = the tier (Low = 0 here);
## - IceShapes.legacy = true keeps the old shaders (the before / after shots rely on it);
## - windows: the keep's Windows and the Hall's arrow slits are warm, the keep's crown glow stays the team glow;
## - an Ice Wall that joins a neighbour (re-merged mesh) keeps the Ice shader;
## - keep tiers: set_tier / set_upgrading / play_tier_up (safe before _ready), Stronghold and Citadel groups, the
##   upgrade grows the next tier, construction and the collapse hide them; Keep.set_tier_now reaches the model;
## - Low adds no particles (the High snowfall is off headless).
## Run:  godot --headless --path . -s tests/test_gb_ice.gd --fixed-fps 60 --quit-after 1500

const TASK_ID := "gb_ice"
const ICE_VC := "res://art/buildings/ice/ice_painted_vc.gdshader"
const ICE_PAINTED := "res://art/buildings/ice/ice_painted.gdshader"
const ICE_STABLES := "res://art/buildings/stables/ice/ice_stables_painted.gdshader"
const MODELS := {
	"keep": "res://art/buildings/ice_keep.tscn",
	"hall": "res://art/buildings/ice_hall.tscn",
	"lodge": "res://art/buildings/ice_lodge.tscn",
	"spire": "res://art/buildings/ice_spire.tscn",
	"wall": "res://art/buildings/ice_wall.tscn",
	"stables": "res://art/buildings/stables/ice/ice_stables.tscn",
	"market": "res://art/buildings/market/ice/market_ice.tscn",
	"forge": "res://art/buildings/forge/ice/ice_forge.tscn",
}

var _m := {}
var _legacy_hall: Node3D
var _keep2: Node3D
var _keep_up: Node3D
var _walls: Array[Node3D] = []
var _frame := 0
var _forge_done := false
var _errors: Array[String] = []


func _initialize() -> void:
	var x := 0.0
	for k: String in MODELS:
		var n := (load(MODELS[k]) as PackedScene).instantiate() as Node3D
		n.position = Vector3(x, 0, 0)
		x += 12.0
		root.add_child(n)
		_m[k] = n
	# Tier hooks before _ready are cached.
	_keep2 = (load(MODELS["keep"]) as PackedScene).instantiate() as Node3D
	_keep2.call(&"set_tier", 3)
	_keep2.position = Vector3(0, 0, 30)
	root.add_child(_keep2)
	_keep_up = (load(MODELS["keep"]) as PackedScene).instantiate() as Node3D
	_keep_up.position = Vector3(20, 0, 30)
	root.add_child(_keep_up)
	# Two walls that join (the second one re-merges its mesh).
	for p: Vector3 in [Vector3(61, 0, 61), Vector3(63, 0, 61)]:
		var w := (load(MODELS["wall"]) as PackedScene).instantiate() as Node3D
		w.position = p
		root.add_child(w)
		_walls.append(w)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		# The legacy look (before / after shots): _ready runs inside add_child once the tree is running.
		IceShapes.legacy = true
		_legacy_hall = (load(MODELS["hall"]) as PackedScene).instantiate() as Node3D
		_legacy_hall.position = Vector3(0, 0, -30)
		root.add_child(_legacy_hall)
		IceShapes.legacy = false
	if _frame == 3:
		_check_shaders()
		_check_windows()
		_check_tiers_start()
		(_keep_up as Node).call(&"set_upgrading", true)
	if _frame == 5:
		_check_upgrade()
		for w: Node3D in _walls:
			_expect(_shader_of(w.get(&"_m_team")) == ICE_VC, "joined wall keeps the Ice shader")
		var codes: PackedInt32Array = _walls[0].get(&"_codes")
		_expect(codes[0] == 1, "the two walls joined (codes %s)" % [Array(codes)])
		(_keep_up as Node).call(&"set_upgrading", false)
		(_keep_up as Node).call(&"set_tier", 2)
		(_keep_up as Node).call(&"play_tier_up")
		(_m["keep"] as Node).call(&"set_construction_progress", 0.5)
	if _frame == 8:
		var tr := (_m["keep"] as Node).get(&"_tier_root") as Node3D
		_expect(tr != null and not tr.visible, "tier parts hidden while the keep is a site")
		(_m["keep"] as Node).call(&"set_construction_progress", 1.0)
		_expect(tr != null and tr.visible, "tier parts back when built")
		_expect(not ((_keep_up.get(&"_sentinels") as Node3D).visible), "Stronghold: no Citadel sentinels")
		_expect((_keep_up.get(&"_outer_halo") as Node3D).visible, "Stronghold: the outer halo shows")
		_keep2.call(&"set_health_ratio", 0.2)
		var fg := _m["forge"] as Node
		fg.call(&"set_selected", true)
		fg.call(&"set_team_color", Color(0.85, 0.25, 0.25))
		fg.call(&"play_training_pulse")
		fg.call(&"set_health_ratio", 0.2)
		fg.connect(&"destroyed_finished", func() -> void: _forge_done = true)
		fg.call(&"play_destroyed")
		_keep2.call(&"play_destroyed")
	if _frame == 60 * 3:
		var tr2 := _keep2.get(&"_tier_root") as Node3D
		_expect(tr2 != null and not tr2.visible, "tier parts gone after the collapse")
		_check_keep_building()
		_expect(BuildingType.find("ice_forge").get_model_scene() != null, "ice_forge.tres finds its model")
	if _frame == 60 * 3 + 30:
		_expect(_forge_done, "Frost Forge: destroyed_finished")
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			for e: String in _errors:
				print("  ", e)
			print("FAIL %s: %s" % [TASK_ID, _errors[0]])
		return true
	return false


func _check_shaders() -> void:
	_expect(IceShapes.detail_tier() == 0, "headless runs are Low (gb_detail 0)")
	for k: String in ["hall", "market", "forge"]:
		var m: ShaderMaterial = (_m[k] as Node).get(&"mat_team")
		_expect(_shader_of(m) == ICE_VC, "%s body uses ice_painted_vc (got %s)" % [k, _shader_of(m)])
		if m:
			_expect(float(m.get_shader_parameter(&"gb_detail")) == 0.0, "%s gb_detail 0 at Low" % k)
	for k: String in ["lodge", "wall"]:
		_expect(_shader_of((_m[k] as Node).get(&"_m_team")) == ICE_VC, "%s body uses ice_painted_vc" % k)
	for nm: StringName in [&"_m_stone", &"_m_dark", &"_m_trim", &"_m_team", &"_m_snow"]:
		_expect(_shader_of((_m["spire"] as Node).get(nm)) == ICE_PAINTED, "spire %s uses ice_painted" % nm)
	_expect(int(((_m["spire"] as Node).get(&"_m_team") as ShaderMaterial).get_shader_parameter(&"ip_kind")) == IceShapes.K_ICE,
		"spire crystals are kind ICE")
	var kinds := {}
	for m: ShaderMaterial in (_m["keep"] as Node).get(&"_painted_mats"):
		_expect(_shader_of(m) == ICE_PAINTED, "keep %s uses ice_painted" % m.resource_name)
		kinds[m.resource_name] = int(m.get_shader_parameter(&"ip_kind"))
	_expect(kinds.get("Crystal", -1) == IceShapes.K_ICE and kinds.get("Snow", -1) == IceShapes.K_SNOW,
		"keep kinds by material name (%s)" % str(kinds))
	_expect(_shader_of((_m["stables"] as Node).get(&"mat_body")) == ICE_STABLES, "stables body uses ice_stables_painted")
	_expect(_shader_of(_legacy_hall.get(&"mat_team")) == "res://art/shaders/painted_vc.gdshader",
		"legacy hall keeps painted_vc (got %s)" % _shader_of(_legacy_hall.get(&"mat_team")))
	for k: String in ["lodge", "hall", "keep"]:
		var snow := (_m[k] as Node).find_child("Snowfall", true, false)
		_expect(snow == null, "%s: no High snowfall at Low" % k)


func _check_windows() -> void:
	var win := (_m["keep"] as Node).get_node(^"Model/Windows") as GeometryInstance3D
	var tint: Color = win.get_instance_shader_parameter(&"tint_color")
	_expect(tint.a > 0.5 and Color(tint, 1.0).is_equal_approx(Color(IceShapes.WARM_WINDOW, 1.0)), "keep windows are warm (%s)" % tint)
	var glow: ShaderMaterial = (_m["keep"] as Node).get(&"_glow_mat")
	_expect(win.material_override == glow and not (glow.get_shader_parameter(&"glow_color") as Color).is_equal_approx(IceShapes.WARM_WINDOW),
		"windows share the keep glow material (8-material budget), the crown keeps the team glow")
	var hw: ShaderMaterial = (_m["hall"] as Node).get(&"mat_window")
	_expect(hw != null and (hw.get_shader_parameter(&"glow_color") as Color).is_equal_approx(IceShapes.WARM_WINDOW),
		"hall arrow slits are warm")
	var lw: ShaderMaterial = _legacy_hall.get(&"mat_window")
	_expect(lw != null and not (lw.get_shader_parameter(&"glow_color") as Color).is_equal_approx(IceShapes.WARM_WINDOW),
		"legacy hall slits stay cold")


func _check_tiers_start() -> void:
	var k1 := _m["keep"] as Node
	_expect(k1.has_method(&"set_tier") and k1.has_method(&"set_upgrading") and k1.has_method(&"play_tier_up"),
		"keep has the tier hooks")
	_expect(not (k1.get(&"_t2_static") as Node3D).visible, "tier 1: no Stronghold bastions")
	_expect((_keep2.get(&"_t3_static") as Node3D).visible and (_keep2.get(&"_sentinels") as Node3D).visible,
		"set_tier(3) before _ready: Citadel parts show")
	var mm: MultiMesh = (_keep2.get(&"_outer_mm") as MultiMeshInstance3D).multimesh
	_expect(mm.visible_instance_count == -1, "Citadel: full outer halo")


func _check_upgrade() -> void:
	var b := _keep_up.get(&"_t2_static") as MultiMeshInstance3D
	_expect(b.visible, "upgrading 1 -> 2: the bastions show")
	var s: float = float((_keep_up.get(&"_grow") as Dictionary)[b])   # (MultiMesh buffers are empty headless)
	_expect(s < 0.9, "upgrading: the bastions grow (scale %.2f)" % s)
	_expect(not (_keep_up.get(&"_t3_static") as Node3D).visible, "upgrading 1 -> 2: no Citadel parts")


## A real Keep building: set_tier_now reaches the model (no placeholder gold rings).
func _check_keep_building() -> void:
	var bt := load("res://data/buildings/ice_keep.tres") as BuildingType
	var keep := Keep.new()
	keep.building_type = bt
	keep.position = Vector3(-40, 0, 0)
	root.add_child(keep)
	keep.set_tier_now(2)
	var model: Node = keep.model()
	_expect(model != null and int(model.get(&"_tier")) == 2, "Keep.set_tier_now(2) reaches the Ice keep model")
	_expect(keep.get_node_or_null(^"TierEmblem") == null, "no placeholder tier emblem on the Ice keep")


func _shader_of(m: Variant) -> String:
	if m is ShaderMaterial and (m as ShaderMaterial).shader:
		return (m as ShaderMaterial).shader.resource_path
	return "<none>"


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_errors.append(what)
