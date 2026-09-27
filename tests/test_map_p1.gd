extends SceneTree
## Task MAP.P1 (skirmish map art polish): the real skirmish scene loads with the polished ground and cliffs,
## the shaders parse with their new uniforms, no light was added, and the map art stays cheap (shared saved
## materials, one sampler per shader, decor budget, shadow casting unchanged, no colliders in the dressing).
## Run: $GODOT --headless --path . -s tests/test_map_p1.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "MAP.P1"
const GROUND_SHADER := "res://art/environment/ground.gdshader"
const PAINTED_SHADER := "res://art/environment/env_painted.gdshader"
const CLIFF_MAT := "res://art/environment/cliff_mat.tres"
const PAINTED_MAT := "res://art/environment/env_painted_mat.tres"
const PRESET_WARM := "res://art/environment/lighting/preset_warm.tres"
const GROUND_UNIFORMS: Array[String] = ["patch_contrast", "edge_soft", "edge_lip", "cliff_ao", "cliff_ao_width",
		"outer_cool", "sun_dir", "road_segs", "road_count"]
const PAINTED_UNIFORMS: Array[String] = ["cliff_paint", "cliff_foot", "cliff_foot_height", "cliff_top_smooth",
		"cliff_sun_xz"]
const MAX_DECOR := 4000            ## decor instances scattered by MapDressingArt
const MAX_DRESSING_DRAWS := 140    ## MultiMesh / mesh instances under MapDressing (one draw each, before culling)
const TIMEOUT_FRAMES := 5000

var main: Node
var _fails: PackedStringArray = PackedStringArray()
var _frame := 0
var _ready_frame := -1


func _initialize() -> void:
	_check_shaders()
	_check_materials()
	main = (load("res://scenes/skirmish.tscn") as PackedScene).instantiate()
	var bot: Node = main.get_node_or_null(^"ShadowBot")
	if bot:
		bot.set(&"enabled", false)
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	_frame += 1
	if _ready_frame < 0:
		if main.get(&"hero") != null:
			_ready_frame = _frame
		elif _frame > TIMEOUT_FRAMES:
			_fail("the skirmish never finished loading")
			return _finish()
		return false
	if _frame < _ready_frame + 30:   # let MapDressingArt populate (deferred)
		return false
	_check_scene()
	return _finish()


func _finish() -> bool:
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for f: String in _fails:
			print("  - %s" % f)
		print("FAIL %s: %s" % [TASK_ID, _fails[0]])
	return true


func _fail(msg: String) -> void:
	_fails.append(msg)


func _check(ok: bool, msg: String) -> void:
	if not ok:
		_fail(msg)


# ---------------------------------------------------------------- shaders

func _check_shaders() -> void:
	_check_shader(GROUND_SHADER, GROUND_UNIFORMS)
	_check_shader(PAINTED_SHADER, PAINTED_UNIFORMS)


## The shader parses (the renderer lists its uniforms; the dummy headless one may not, then the source is read),
## has the new uniforms, and still samples exactly one texture (the shared paint noise): no extra texture cost.
func _check_shader(path: String, wanted: Array[String]) -> void:
	var sh := load(path) as Shader
	if sh == null:
		_fail("%s does not load" % path)
		return
	var names: Array[String] = []
	var samplers := 0
	for u: Dictionary in sh.get_shader_uniform_list():
		names.append(String(u["name"]))
		if int(u["type"]) == TYPE_OBJECT:
			samplers += 1
	var code: String = sh.code
	if names.is_empty():   # headless dummy renderer: read the declarations
		for line: String in code.split("\n"):
			var l := line.strip_edges()
			if l.begins_with("uniform "):
				var decl := l.get_slice("=", 0).get_slice(":", 0).strip_edges()
				var nm := decl.get_slice(" ", decl.get_slice_count(" ") - 1).get_slice("[", 0)
				names.append(nm)
				if l.contains("sampler2D"):
					samplers += 1
	for w: String in wanted:
		_check(names.has(w), "%s: uniform %s missing" % [path.get_file(), w])
	_check(samplers == 1, "%s: %d samplers (must stay 1: the shared paint noise)" % [path.get_file(), samplers])
	_check(code.count("{") == code.count("}"), "%s: unbalanced braces" % path.get_file())
	_check(not code.contains("SCREEN_TEXTURE") and not code.contains("hint_screen_texture")
			and not code.contains("hint_depth_texture"), "%s: no screen / depth reads" % path.get_file())


func _check_materials() -> void:
	var cliff := load(CLIFF_MAT) as ShaderMaterial
	_check(cliff != null, "cliff_mat.tres missing")
	if cliff:
		_check(cliff.shader != null and cliff.shader.resource_path == PAINTED_SHADER, "cliff_mat uses env_painted")
		_check(float(cliff.get_shader_parameter(&"cliff_paint")) > 0.5, "cliff_mat has cliff_paint on")
		_check(cliff.get_shader_parameter(&"noise_tex") is Texture2D, "cliff_mat has the paint noise")
	# Every other prop keeps the plain painted look (cliff layer off by default).
	var painted := load(PAINTED_MAT) as ShaderMaterial
	if painted:
		var cp: Variant = painted.get_shader_parameter(&"cliff_paint")
		_check(cp == null or float(cp) == 0.0, "env_painted_mat.tres must keep cliff_paint off")
	# The ground's painted sun direction matches the warm preset's sun (shadow side of tufts / pebbles).
	var preset: Resource = load(PRESET_WARM)
	var ground := load("res://art/environment/ground_material.tres") as ShaderMaterial
	if preset and ground:
		var rot: Vector3 = preset.get(&"sun_rotation_degrees")
		var fwd: Vector3 = Basis.from_euler(Vector3(deg_to_rad(rot.x), deg_to_rad(rot.y), deg_to_rad(rot.z))) * Vector3.FORWARD
		var to_sun := Vector2(-fwd.x, -fwd.z).normalized()
		var sd: Variant = ground.get_shader_parameter(&"sun_dir")
		if sd == null:
			sd = _uniform_default(GROUND_SHADER, "sun_dir")
		_check(sd is Vector2 and (sd as Vector2).normalized().dot(to_sun) > 0.995,
				"ground sun_dir %s != preset sun %s" % [str(sd), str(to_sun)])


func _uniform_default(path: String, uname: String) -> Variant:
	var sh := load(path) as Shader
	var v: Variant = RenderingServer.shader_get_parameter_default(sh.get_rid(), StringName(uname))
	if v != null:
		return v
	for line: String in sh.code.split("\n"):
		if line.strip_edges().begins_with("uniform vec2 %s " % uname):
			var rhs := line.get_slice("=", 1).strip_edges().trim_suffix(";")
			var nums := rhs.trim_prefix("vec2(").trim_suffix(")").split(",")
			return Vector2(float(nums[0]), float(nums[1]))
	return null


# ---------------------------------------------------------------- the live map

func _check_scene() -> void:
	# No light added: the lighting rig's sun + fill are the only directional lights; the map art has none.
	# (UI portraits render in their own SubViewport world with their own light: not counted.)
	var dirs := 0
	var others := 0
	for l: Node in main.find_children("*", "Light3D", true, false):
		if l.get_viewport() != root:
			continue
		if l is DirectionalLight3D:
			dirs += 1
		else:
			others += 1
	_check(dirs <= 2, "%d directional lights in the world (sun + fill only)" % dirs)
	# Omni / spot lights belong to other tasks' scenes (buildings...); MAP.P1 found 15 and added none. The map art
	# (dressing, ground) itself must have none: checked below.
	_check(others <= 15, "%d omni / spot lights in the skirmish world (MAP.P1 baseline 15)" % others)
	print("lights: %d directional, %d omni / spot" % [dirs, others])
	var dressing: Node = main.find_child("MapDressing", true, false)
	_check(dressing != null, "MapDressing missing from the skirmish")
	if dressing:
		_check(dressing.find_children("*", "Light3D", true, false).is_empty(), "MapDressing has a light")
		_check(dressing.find_children("*", "CollisionObject3D", true, false).is_empty(), "MapDressing has a collider")
		_check(dressing.find_children("*", "GPUParticles3D", true, false).is_empty(), "MapDressing has particles")
		var cliffs := dressing.get_node_or_null(^"Cliffs") as MeshInstance3D
		_check(cliffs != null, "Cliffs missing")
		if cliffs:
			_check(cliffs.material_override != null and cliffs.material_override.resource_path == CLIFF_MAT,
					"Cliffs must use the saved cliff_mat.tres")
			_check(cliffs.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Cliffs keep their shadows")
		var plateau := dressing.get_node_or_null(^"Plateau") as MeshInstance3D
		if plateau:
			_check(plateau.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Plateau casts no shadow")
		var n: int = int(dressing.call(&"decor_count")) if dressing.has_method(&"decor_count") else -1
		_check(n > 500 and n <= MAX_DECOR, "decor count %d (500-%d)" % [n, MAX_DECOR])
		var draws := dressing.find_children("*", "GeometryInstance3D", true, false).size()
		_check(draws <= MAX_DRESSING_DRAWS, "MapDressing has %d draw nodes (max %d)" % [draws, MAX_DRESSING_DRAWS])
		# Only the listed decor meshes cast shadows (grass, flowers, stones, mushrooms stay shadowless).
		var decor: Node = dressing.get_node_or_null(^"Decor")
		if decor:
			for c: Node in decor.get_children():
				var mmi := c as MultiMeshInstance3D
				if mmi and not (String(mmi.name).begins_with("DecorBush") or String(mmi.name).begins_with("DecorFern")
						or String(mmi.name).begins_with("DecorLog") or String(mmi.name).begins_with("DecorStump")):
					_check(mmi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
							"%s must not cast shadows" % mmi.name)
	# The ground: one plane with the painted ground shader, roads on.
	var found := false
	for mi: Node in main.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var sm := m.material_override as ShaderMaterial
		if m.mesh is PlaneMesh and sm and sm.shader and sm.shader.resource_path == GROUND_SHADER:
			found = true
			_check(int(sm.get_shader_parameter(&"road_count")) > 0, "the skirmish ground paints the trade roads")
			_check(m.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON
					or m.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "ground shadow mode sane")
	_check(found, "no ground plane with ground.gdshader in the skirmish")
