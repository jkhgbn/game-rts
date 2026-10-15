extends SceneTree
## G-D menu diorama (graphics week, docs/art/gd_menu.md): the four kingdoms' landmark keeps and the graphics tiers of
## art/environment/menu_diorama/menu_diorama.tscn.
## Run:  tools\godot_run.ps1 --headless --path . -s tests/test_gd_menu.gd --fixed-fps 60 --quit-after 1500
## Checks (headless = Low):
## - four landmark keeps (Fire / Shadow / Ice / Nature) on their hills, no far tree inside a hill's clearing;
## - the diorama joins "lighting_rigs", starts on Low, builds no tier dressing and adds nothing to the authored
##   environment at Low (its own copy of the .tres, every tier key equal to the .tres), the SubViewport AA untouched,
##   live particles within the A2.10 budget;
## - set_quality(3): volumetric light + SSAO + SSIL on the copy only (the .tres and a second diorama untouched), the
##   SubViewport takes the tier's AA, the dressing appears (birds, pond, weather, keep lights), particles within budget;
## - set_paused(true) freezes the dressing's particles and birds too;
## - set_quality(1) keeps only the Medium parts; set_quality(0) gives back the Low look exactly (env, AA, dressing off).

const TASK_ID := "gd_menu"
const SCENE := "res://art/environment/menu_diorama/menu_diorama.tscn"
const ENV_PATH := "res://art/environment/menu_diorama/menu_diorama_env.tres"
const KEEPS: Array[String] = ["Fire", "Shadow", "Ice", "Nature"]
const LOW_PARTICLE_BUDGET := 200   ## same as test_a2_10 (live looping particles at Low)
const ULTRA_PARTICLE_BUDGET := 1200

var _vp: SubViewport
var _dio: Node3D
var _other: Node3D
var _frame := 0
var _fail := ""
var _bird_t := 0.0
var _aniso0 := -1


func _initialize() -> void:
	if not ResourceLoader.exists(SCENE):
		_fail = "scene missing"
		return
	_vp = SubViewport.new()
	_vp.size = Vector2i(1920, 1080)
	_vp.own_world_3d = true
	_vp.msaa_3d = Viewport.MSAA_2X   # main_menu.gd's set-up
	root.add_child(_vp)
	if &"anisotropic_filtering_level" in _vp:
		_aniso0 = int(_vp.get(&"anisotropic_filtering_level"))
	_dio = (load(SCENE) as PackedScene).instantiate() as Node3D
	_vp.add_child(_dio)
	# A second diorama in the root viewport: tiers on the first must never reach it (per-instance environment).
	_other = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(_other)


func _process(_delta: float) -> bool:
	if _fail != "":
		print("FAIL %s: %s" % [TASK_ID, _fail])
		return true
	_frame += 1
	match _frame:
		5:
			_check_low_start()
		10:
			_dio.call(&"set_quality", 3)
			_check_ultra()
		40:
			_dio.call(&"set_paused", true)
			_bird_t = _bird_time()
		60:
			_check_paused()
			_dio.call(&"set_paused", false)
		80:
			if is_equal_approx(_bird_time(), _bird_t):
				_fail = "the birds did not resume after set_paused(false)"
			_dio.call(&"set_quality", 1)
			_check_medium()
		90:
			_dio.call(&"set_quality", 0)
			_check_low_again()
		95:
			_check_exit()
		100:
			print("PASS %s" % TASK_ID)
			return true
	return false


func _env() -> Environment:
	return (_dio.get_node(^"WorldEnvironment") as WorldEnvironment).environment


func _base_env() -> Environment:
	return load(ENV_PATH) as Environment


func _dressing(path: String) -> Node:
	return _dio.get_node_or_null(NodePath("TierDressing/" + path))


func _live_particles(n: Node) -> int:
	var total := 0
	for p: Node in n.find_children("*", "GPUParticles3D", true, false):
		var g := p as GPUParticles3D
		if g.emitting and not g.one_shot and g.is_visible_in_tree():
			total += int(ceil(float(g.amount) * g.amount_ratio))
	return total


func _bird_time() -> float:
	var b := _dressing("Birds_5") as GeometryInstance3D
	if b == null or not (b.material_override is ShaderMaterial):
		return -1.0
	return float((b.material_override as ShaderMaterial).get_shader_parameter(&"anim_time"))


## Every key the tiers touch equals the authored .tres value.
func _env_matches_base() -> String:
	var env := _env()
	var base := _base_env()
	for k: String in ["ssao_enabled", "ssil_enabled", "volumetric_fog_enabled", "volumetric_fog_density",
			"ssao_radius", "ssao_intensity"]:
		if env.get(k) != base.get(k):
			return "env %s is %s, the .tres has %s" % [k, env.get(k), base.get(k)]
	return ""


func _check_low_start() -> void:
	if not _dio.is_in_group(&"lighting_rigs"):
		_fail = "diorama not in group lighting_rigs (Settings changes would not reach it)"
		return
	if int(_dio.call(&"get_quality")) != 0:
		_fail = "headless run should start on Low, got %d" % int(_dio.call(&"get_quality"))
		return
	for k: String in KEEPS:
		var site := _dio.get_node_or_null(NodePath("Landmarks/" + k)) as Node3D
		if site == null or site.get_node_or_null(^"Keep") == null:
			_fail = "landmark keep %s missing" % k
			return
		if _dio.get_node_or_null(NodePath("Landmarks/Hill_" + k)) == null:
			_fail = "landmark hill %s missing" % k
			return
		if site.position.y < 1.0:
			_fail = "landmark %s does not stand on its hill" % k
			return
		# The keep's gate (local -Z) looks at the crown.
		var gate := -site.global_transform.basis.z.normalized()
		var to_crown := (Vector3.ZERO - site.global_position)
		to_crown.y = 0.0
		if gate.dot(to_crown.normalized()) < 0.95:
			_fail = "landmark %s does not face the crown" % k
			return
	if _dio.get_node_or_null(^"TierDressing") != null:
		_fail = "tier dressing built at Low"
		return
	if _env() == _base_env():
		_fail = "the diorama shows the shared .tres environment (a tier would change it for everyone)"
		return
	var e := _env_matches_base()
	if e != "":
		_fail = "Low: " + e
		return
	if _vp.msaa_3d != Viewport.MSAA_2X or _vp.screen_space_aa != Viewport.SCREEN_SPACE_AA_DISABLED:
		_fail = "Low changed the SubViewport's AA"
		return
	if _keep_lights_on() > 0:
		_fail = "Low: %d landmark keep lights on (High+ only)" % _keep_lights_on()
		return
	var n := _live_particles(_dio)
	if n > LOW_PARTICLE_BUDGET:
		_fail = "too many live particles at Low (%d > %d)" % [n, LOW_PARTICLE_BUDGET]
		return
	# Far trees keep out of the landmark clearings.
	var lms: Array = MenuDiorama.LANDMARKS
	var clear := MenuDiorama.LANDMARK_CLEAR
	for mmi: Node in _dio.get_node(^"FarTreeline").find_children("*", "MultiMeshInstance3D", true, false):
		var mm := (mmi as MultiMeshInstance3D).multimesh
		for i: int in mm.instance_count:
			var p := mm.get_instance_transform(i).origin
			for lm: Dictionary in lms:
				var c: Vector3 = lm["pos"]
				if Vector2(p.x - c.x, p.z - c.z).length() < float(lm["radius"]) * clear - 0.01:
					_fail = "a far tree stands in the %s landmark's clearing" % lm["kingdom"]
					return


func _check_ultra() -> void:
	var env := _env()
	if not (env.volumetric_fog_enabled and env.ssao_enabled and env.ssil_enabled):
		_fail = "Ultra: volumetric light / SSAO / SSIL not on"
		return
	if _base_env().volumetric_fog_enabled or _base_env().ssao_enabled:
		_fail = "Ultra wrote into the shared menu_diorama_env.tres"
		return
	var other_env := (_other.get_node(^"WorldEnvironment") as WorldEnvironment).environment
	if other_env.volumetric_fog_enabled:
		_fail = "Ultra on one diorama reached another diorama's environment"
		return
	if _vp.msaa_3d != Viewport.MSAA_4X or _vp.screen_space_aa != Viewport.SCREEN_SPACE_AA_SMAA:
		_fail = "Ultra: the SubViewport did not take the tier's AA (msaa %d, ssaa %d)" % [_vp.msaa_3d,
				_vp.screen_space_aa]
		return
	if (_dio.get_node(^"Sun") as DirectionalLight3D).light_angular_distance <= 0.0:
		_fail = "Ultra: no soft sun shadows"
		return
	for p: String in ["Birds_5", "Birds_9", "Pond", "Reeds", "Weather_Ice", "Weather_Fire", "Smoke_Fire",
			"Weather_Nature", "Weather_Shadow", "LandmarkLight_Fire", "WizardWeather_Ice"]:
		var n := _dressing(p) as Node3D
		if n == null:
			_fail = "Ultra: dressing part %s missing" % p
			return
		if not n.visible:
			_fail = "Ultra: dressing part %s hidden" % p
			return
	for l: Node in _dio.find_children("*", "OmniLight3D", true, false):
		if (l as OmniLight3D).shadow_enabled:
			_fail = "omni light %s casts shadows" % l.name
			return
	var suns := 0
	for s: Node in _dio.find_children("*", "DirectionalLight3D", true, false):
		suns += 1
	if suns != 1:
		_fail = "expected one sun, found %d" % suns
		return
	if _keep_lights_on() == 0:
		_fail = "Ultra: the landmark keeps' own lights stay hidden"
		return
	var n := _live_particles(_dio)
	if n > ULTRA_PARTICLE_BUDGET:
		_fail = "too many live particles at Ultra (%d > %d)" % [n, ULTRA_PARTICLE_BUDGET]
		return
	if _live_particles(_other) > LOW_PARTICLE_BUDGET:
		_fail = "the second diorama got the first one's tier"


func _check_paused() -> void:
	for p: Node in _dio.find_children("*", "GPUParticles3D", true, false):
		if (p as GPUParticles3D).speed_scale != 0.0:
			_fail = "particles %s still running while paused" % p.name
			return
	if not is_equal_approx(_bird_time(), _bird_t):
		_fail = "the birds kept flying while paused"


func _check_medium() -> void:
	var env := _env()
	if env.volumetric_fog_enabled or not env.ssao_enabled or env.ssil_enabled:
		_fail = "Medium: expected SSAO only (volumetric %s, ssil %s)" % [env.volumetric_fog_enabled, env.ssil_enabled]
		return
	for p: String in ["Birds_5", "Pond", "Weather_Ice"]:
		if not (_dressing(p) as Node3D).visible:
			_fail = "Medium: %s hidden" % p
			return
	for p: String in ["Birds_9", "LandmarkLight_Fire", "WizardWeather_Ice"]:
		if (_dressing(p) as Node3D).visible:
			_fail = "Medium: %s shown (High / Ultra only)" % p
			return
	if (_dio.get_node(^"Sun") as DirectionalLight3D).light_angular_distance != 0.0:
		_fail = "Medium: soft sun shadows still on"


func _check_low_again() -> void:
	var e := _env_matches_base()
	if e != "":
		_fail = "back to Low: " + e
		return
	if _vp.msaa_3d != Viewport.MSAA_2X or _vp.screen_space_aa != Viewport.SCREEN_SPACE_AA_DISABLED:
		_fail = "back to Low: the SubViewport's AA was not given back"
		return
	for n: Node in _dio.get_node(^"TierDressing").get_children():
		if (n as Node3D).visible:
			_fail = "back to Low: dressing part %s still shown" % n.name
			return
		if n is GPUParticles3D and (n as GPUParticles3D).emitting:
			_fail = "back to Low: %s still emitting" % n.name
			return
	if (_dio.get_node(^"Sun") as DirectionalLight3D).light_angular_distance != 0.0:
		_fail = "back to Low: soft sun shadows still on"
		return
	if &"anisotropic_filtering_level" in _vp and int(_vp.get(&"anisotropic_filtering_level")) != _aniso0:
		_fail = "back to Low: the SubViewport's anisotropic filtering was not given back"
		return
	if _keep_lights_on() > 0:
		_fail = "back to Low: %d landmark keep lights still on" % _keep_lights_on()
		return
	if bool(_dio.get(&"_shadow_filter_set")):
		_fail = "back to Low: the global soft-shadow filter is still the tier's"


## Exit path: at Ultra the diorama owns the global soft-shadow filter; leaving the tree gives the project's value
## back (RenderingServer has no getter for it, so the check reads the diorama's own flag, set / cleared only next
## to the RenderingServer calls).
func _check_exit() -> void:
	_dio.call(&"set_quality", 3)
	if not bool(_dio.get(&"_shadow_filter_set")):
		_fail = "Ultra did not set the global soft-shadow filter"
		return
	_vp.remove_child(_dio)
	if bool(_dio.get(&"_shadow_filter_set")):
		_fail = "leaving the tree at Ultra did not reset the global soft-shadow filter"
	_dio.free()


## Landmark keeps' own lights shown now.
func _keep_lights_on() -> int:
	var n := 0
	for l: Node in _dio.get_node(^"Landmarks").find_children("*", "Light3D", true, false):
		if (l as Light3D).is_visible_in_tree():
			n += 1
	return n
