extends SceneTree
## G-F review 2 item 13, art half (docs/art/gf_menu_fire.md): the main menu diorama's glows never bloom to white.
## Run:  tools\godot_run.ps1 --headless --path . -s tests/test_gf_menu_fire.gd --fixed-fps 60 --quit-after 1500
## For every tier (set_quality 0..3, then back to 0):
## - the cap: MenuDiorama.GLOW_CAP is under the diorama environment's glow_hdr_threshold;
## - the altar beacon (and the High+ BeaconCore, absent below High) wears menu_beacon.gdshader: alpha-blended (never
##   blend_add), core / rim colours <= BEACON_MAX per channel, alpha <= 1;
## - every additive emitter of the diorama (fireflies, kingdom motes, landmark / wizard weather, the wizards' and
##   champions' own motes, the altar embers with the pedestal's EMBERS_GOLD / EMBERS_RED material colour) peaks
##   <= GLOW_CAP per channel (draw albedo x ramp x process colour);
##   the landmark keeps' own emitters (keep art, used read-only) are not the diorama's;
## - every glow pool (kingdom pools at their focus level, landmark pools) peaks <= GLOW_CAP;
## - centred menu framing: a stand-in menu with column_on_side = false makes the wide shot pull back (camera further
##   from the crown), column_on_side = true leaves the shot as authored.

const TASK_ID := "gf_menu_fire"
const SCENE := "res://art/environment/menu_diorama/menu_diorama.tscn"
const BEACON_SHADER := "res://art/environment/menu_diorama/menu_beacon.gdshader"
const EPS := 0.002
const MENU_STUB := "extends Control\nvar column_on_side := true\nvar main_panel: Control\n"

var _vp: SubViewport
var _dio: Node3D
var _menu: Control
var _frame := 0
var _fail := ""
var _checked := 0
var _dist_side := 0.0


func _initialize() -> void:
	if not ResourceLoader.exists(SCENE):
		_fail = "scene missing"
		return
	_vp = SubViewport.new()
	_vp.size = Vector2i(1152, 648)
	_vp.own_world_3d = true
	root.add_child(_vp)
	_dio = (load(SCENE) as PackedScene).instantiate() as Node3D
	_vp.add_child(_dio)
	# A stand-in for MainMenu next to the diorama (the shots script's layout): column_on_side + main_panel.
	var s := GDScript.new()
	s.source_code = MENU_STUB
	s.reload()
	_menu = Control.new()
	_menu.set_script(s)
	var panel := Control.new()
	_menu.add_child(panel)
	_menu.set(&"main_panel", panel)
	_vp.add_child(_menu)


func _process(_delta: float) -> bool:
	if _fail != "":
		print("FAIL %s: %s" % [TASK_ID, _fail])
		return true
	_frame += 1
	match _frame:
		5:
			_check_tier(0)
			_dio.call(&"set_quality", 1)
		8:
			_check_tier(1)
			_dio.call(&"set_quality", 2)
		11:
			_check_tier(2)
			_dio.call(&"set_quality", 3)
		14:
			_check_tier(3)
			_dio.call(&"set_quality", 0)
		17:
			_check_tier(0)
			_dist_side = _cam_dist()
			_menu.set(&"column_on_side", false)
		120:
			var d := _cam_dist()
			if d < _dist_side + 2.0:
				_fail = "centred menu: the wide shot did not pull back (%.1f m -> %.1f m)" % [_dist_side, d]
			else:
				print("centred menu framing: camera %.1f m -> %.1f m from the crown" % [_dist_side, d])
			_menu.set(&"column_on_side", true)
		240:
			var d2 := _cam_dist()
			if absf(d2 - _dist_side) > 1.5:
				_fail = "side menu: the wide shot did not come back (%.1f m, authored %.1f m)" % [d2, _dist_side]
			if _fail == "":
				print("PASS %s (%d glow checks over 5 tier passes)" % [TASK_ID, _checked])
			else:
				print("FAIL %s: %s" % [TASK_ID, _fail])
			return true
	return false


func _cam_dist() -> float:
	var cam := _dio.call(&"get_camera") as Camera3D
	return cam.global_position.distance_to(Vector3(0.0, 1.7, 0.0))


func _cap() -> float:
	return float(_dio.get_script().get_script_constant_map()["GLOW_CAP"])


func _const(n: String) -> Variant:
	return _dio.get_script().get_script_constant_map()[n]


func _err(msg: String) -> void:
	if _fail == "":
		_fail = msg


static func _maxc(c: Color) -> float:
	return maxf(c.r, maxf(c.g, c.b))


func _check_tier(q: int) -> void:
	if _fail != "":
		return
	var cap := _cap()
	var env := (_dio.get_node(^"WorldEnvironment") as WorldEnvironment).environment
	if not (cap < env.glow_hdr_threshold):
		_err("GLOW_CAP %.2f is not under glow_hdr_threshold %.2f" % [cap, env.glow_hdr_threshold])
		return
	# Beacon + core.
	var altar := _dio.get_node_or_null(^"Altar")
	if altar == null:
		_err("no Altar")
		return
	_check_beacon(altar.get_node_or_null(^"Beacon") as GeometryInstance3D, "Beacon", q)
	var core := altar.get_node_or_null(^"BeaconCore") as GeometryInstance3D
	if q >= 2:
		_check_beacon(core, "BeaconCore", q)
	elif core != null and not core.is_queued_for_deletion():
		_err("tier %d: BeaconCore present below High" % q)
	# Additive emitters.
	var landmarks := _dio.get_node_or_null(^"Landmarks")
	for n: Node in _dio.find_children("*", "GPUParticles3D", true, false):
		var p := n as GPUParticles3D
		if landmarks and landmarks.is_ancestor_of(p):
			continue   # the landmark keeps' own emitters (keep art)
		if p.one_shot and not p.emitting:
			continue   # the altar's seal burst (never fires in the menu)
		var mat := _draw_material(p)
		if mat == null or mat.blend_mode != BaseMaterial3D.BLEND_MODE_ADD:
			continue
		var albedo := mat.albedo_color
		var gain := 1.0
		if altar.is_ancestor_of(p):
			# The pedestal writes EMBERS_GOLD / EMBERS_RED into its embers' material every frame.
			var consts: Dictionary = (altar.get_script() as Script).get_script_constant_map()
			gain = maxf(_maxc(consts["EMBERS_GOLD"]), _maxc(consts["EMBERS_RED"]))
			albedo = Color(1, 1, 1)
		var ramp := 1.0
		var pr := p.process_material as ParticleProcessMaterial
		if pr and pr.color_ramp is GradientTexture1D and (pr.color_ramp as GradientTexture1D).gradient:
			ramp = 0.0
			for c: Color in (pr.color_ramp as GradientTexture1D).gradient.colors:
				ramp = maxf(ramp, _maxc(c))
		if pr:
			ramp *= _maxc(pr.color)
		var peak := _maxc(albedo) * gain * ramp
		_checked += 1
		if peak > cap + EPS:
			_err("tier %d: emitter %s peaks at %.2f (> %.2f)" % [q, _dio.get_path_to(p), peak, cap])
			print("  over cap: tier %d %s %.2f" % [q, _dio.get_path_to(p), peak])
	# Glow pools (glow_pool.gdshader): colour x strength x the largest intensity they get.
	var focus_level := float(_const("POOL_FOCUS_LEVEL"))
	for n: Node in _dio.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if not mi.is_visible_in_tree() or not (mi.mesh is PlaneMesh):
			continue
		if not (mi.name.begins_with("Pool_") or mi.name.begins_with("LandmarkPool_")):
			continue
		var sm := (mi.mesh as PlaneMesh).material as ShaderMaterial
		if sm == null:
			continue
		var col: Color = sm.get_shader_parameter(&"color")
		var level := focus_level if mi.name.begins_with("Pool_") else 1.0
		var peak := _maxc(col) * float(sm.get_shader_parameter(&"strength")) * level
		_checked += 1
		if peak > cap + EPS:
			_err("tier %d: pool %s peaks at %.2f (> %.2f)" % [q, mi.name, peak, cap])
			return
	print("tier %d: glows under the cap %.2f (threshold %.2f)" % [q, cap, env.glow_hdr_threshold])


func _draw_material(p: GPUParticles3D) -> StandardMaterial3D:
	if p.material_override is StandardMaterial3D:
		return p.material_override as StandardMaterial3D
	if p.draw_pass_1 == null:
		return null
	return p.draw_pass_1.surface_get_material(0) as StandardMaterial3D


func _check_beacon(gi: GeometryInstance3D, label: String, q: int) -> void:
	if gi == null:
		_err("tier %d: %s missing" % [q, label])
		return
	var sm := gi.material_override as ShaderMaterial
	if sm == null or sm.shader == null or sm.shader.resource_path != BEACON_SHADER:
		_err("tier %d: %s does not wear menu_beacon.gdshader" % [q, label])
		return
	var code := sm.shader.code
	if code.find("blend_add") >= 0 or code.find("blend_mix") < 0:
		_err("menu_beacon.gdshader must be blend_mix, never blend_add")
		return
	var vmax := float(_const("BEACON_MAX"))
	for key: StringName in [&"core_color", &"rim_color"]:
		var v: Variant = sm.get_shader_parameter(key)
		var c := Color(v.x, v.y, v.z) if v is Vector3 else (v as Color)
		_checked += 1
		if _maxc(c) > vmax + EPS:
			_err("tier %d: %s %s = %s (> %.2f)" % [q, label, key, c, vmax])
			return
	var ma: Variant = sm.get_shader_parameter(&"max_alpha")
	if ma != null and float(ma) > 1.0:
		_err("tier %d: %s max_alpha > 1" % [q, label])
