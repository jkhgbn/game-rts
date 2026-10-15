extends SceneTree
## G-E fog look (docs/art/ge_review.md item 2): the fog-of-war overlay ignores the environment depth fog
## (render_mode fog_disabled), its tier uniform defaults to 0 (Low = no cloud noise, no FOG_RICH screen read),
## the FogOfWar API and the overlay parameters other systems read (vis_tex / exp_tex / map_half on "FogOverlay")
## are unchanged, and the visibility rules still hold on the mission 1 map.
## Run:  tools\godot_run.ps1 --headless --path . -s tests/test_ge_fog_look.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "ge_fog_look"
const TIMEOUT_FRAMES := 2400
const API := [&"set_enabled", &"state_at", &"is_visible", &"is_explored", &"get_state", &"grid_image", &"reveal",
		&"update_team", &"cell_origin", &"cell_of", &"explored_cells", &"set_explored_cells"]

var main: Node
var frame := 0
var _wait := 0
var _fails: Array[String] = []


func _initialize() -> void:
	_static_checks()
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _static_checks() -> void:
	var code: String = FogOfWar.OVERLAY_SHADER
	var rm := ""
	for line in code.split("\n"):
		if line.strip_edges().begins_with("render_mode"):
			rm = line
	if not "fog_disabled" in rm:
		_fails.append("overlay render_mode has no fog_disabled: '%s'" % rm)
	for flag in ["unshaded", "cull_front", "depth_test_disabled", "depth_draw_never", "blend_mix"]:
		if not flag in rm:
			_fails.append("overlay render_mode lost %s" % flag)
	var re := RegEx.create_from_string("uniform\\s+float\\s+cloud_amount\\s*=\\s*([-0-9.]+)")
	var m := re.search(code)
	if m == null or float(m.get_string(1)) != 0.0:
		_fails.append("cloud_amount (tier uniform) must default to 0")
	for name in ["vis_tex", "exp_tex", "map_half", "explored_alpha", "depth_tex"]:
		if not ("uniform" in code and name in code):
			_fails.append("overlay uniform %s missing" % name)
	if "dFdx" in code or "dFdy" in code or "fwidth" in code:
		_fails.append("overlay uses derivatives")
	var dummy := FogOfWar.new()
	for f: StringName in API:
		if not dummy.has_method(f):
			_fails.append("FogOfWar.%s missing" % f)
	if not dummy.has_signal(&"updated"):
		_fails.append("FogOfWar signal updated missing")
	var consts := (load("res://scripts/world/fog_of_war.gd") as Script).get_script_constant_map()
	for c: String in ["UNEXPLORED", "EXPLORED", "VISIBLE", "CELL", "EXPLORED_ALPHA", "GRID_BYTES"]:
		if not consts.has(c):
			_fails.append("FogOfWar.%s missing" % c)
	dummy.free()


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	if frame < 30:
		return false
	_runtime_checks()
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	return true


func _runtime_checks() -> void:
	var fog := FogOfWar.find()
	if fog == null:
		_fails.append("no FogOfWar in group fog")
		return
	var ov := fog.get_node_or_null(^"FogOverlay") as MeshInstance3D
	var mat := ov.material_override as ShaderMaterial if ov else null
	if mat == null:
		_fails.append("FogOverlay / its ShaderMaterial missing")
		return
	if not mat.get_shader_parameter(&"vis_tex") is Texture2D or not mat.get_shader_parameter(&"exp_tex") is Texture2D:
		_fails.append("vis_tex / exp_tex not set")
	if not mat.get_shader_parameter(&"map_half") is Vector2:
		_fails.append("map_half not set")
	# Headless runs are Low: the pre-G1 cost (no screen read, no cloud noise).
	if "#define FOG_RICH" in mat.shader.code:
		_fails.append("Low tier compiled the FOG_RICH variant")
	if float(mat.get_shader_parameter(&"cloud_amount")) != 0.0:
		_fails.append("Low tier has cloud_amount > 0")
	if mat.render_priority != -100:
		_fails.append("overlay render_priority changed")
	var hero := main.hero as Node3D
	if not fog.is_visible(Unit.Team.PLAYER, hero.global_position):
		_fails.append("hero cell not VISIBLE")
	var far := Vector3(-hero.global_position.x, 0.0, -hero.global_position.z)
	if far.distance_to(hero.global_position) > 60.0 and fog.state_at(Unit.Team.PLAYER, far) != FogOfWar.UNEXPLORED:
		_fails.append("far side not UNEXPLORED")
	fog.reveal(Unit.Team.PLAYER, far, 6.0)
	if fog.state_at(Unit.Team.PLAYER, far) != FogOfWar.EXPLORED:
		_fails.append("reveal did not make EXPLORED")
	fog.enabled = false
	if ov.visible or fog.state_at(Unit.Team.PLAYER, far) != FogOfWar.VISIBLE:
		_fails.append("fog off did not hide the overlay / show everything")
	fog.enabled = true
