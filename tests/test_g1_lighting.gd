extends SceneTree
## Task G1 (graphics tiers on the lighting rig, docs/art/lighting.md "Quality tiers"):
## - the rig joins "lighting_rigs"; a scripted run starts on Low;
## - Low = today's look: every stored Environment property equals world_env.tres / world_env_ice.tres, sun as preset;
## - each tier sets its flags (SSAO from Medium, SSIL + PCSS sun from High, stronger AO / wider PCSS on Ultra);
## - set_quality works both ways and is idempotent; the shared .tres is never touched;
## - Emberfall night and the Ice preset keep the tier.
## Run: godot --headless --path . -s tests/test_g1_lighting.gd --fixed-fps 60 --quit-after 600

const TASK_ID := "g1_lighting"
const WARM_ENV := "res://art/environment/world_env.tres"
const ICE_ENV := "res://art/environment/lighting/world_env_ice.tres"

var _fails: Array[String] = []
var _frame := 0
var _rig: LightingRig


func _initialize() -> void:
	_rig = LightingRig.new()
	root.add_child(_rig)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 2:
		_run()
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)] if not _fails.is_empty() else "PASS %s" % TASK_ID)
		return true
	return false


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)


func _run() -> void:
	_check(_rig.is_in_group(&"lighting_rigs"), "rig not in group lighting_rigs")
	_check(_rig.quality == 0, "scripted run should start on Low, got %d" % _rig.quality)
	_check_low(WARM_ENV, "warm start")

	_rig.set_quality(1)
	var env := _rig.world_environment.environment
	_check(env.ssao_enabled and not env.ssil_enabled and not env.volumetric_fog_enabled, "Medium flags")
	_check(is_zero_approx(_rig.sun.light_angular_distance), "Medium has no PCSS")

	_rig.set_quality(2)
	env = _rig.world_environment.environment
	_check(env.ssao_enabled and env.ssil_enabled and not env.volumetric_fog_enabled, "High flags")
	_check(_rig.sun.light_angular_distance > 0.0, "High has PCSS sun")
	var high := _snapshot(env)
	_rig.set_quality(2)
	_check(_snapshot(_rig.world_environment.environment) == high, "set_quality(2) twice is not idempotent")

	_rig.set_quality(3)
	env = _rig.world_environment.environment
	_check(env.ssao_enabled and env.ssil_enabled and not env.volumetric_fog_enabled, "Ultra flags")
	_check(env.ssao_intensity > high["ssao_intensity"], "Ultra AO stronger than High")
	_check(_rig.sun.light_angular_distance > 1.2, "Ultra has the wider PCSS sun")

	_rig.set_quality(0)
	_check_low(WARM_ENV, "Ultra -> Low")

	var shared := load(WARM_ENV) as Environment
	_check(not shared.ssao_enabled and not shared.ssil_enabled and not shared.volumetric_fog_enabled,
			"world_env.tres was modified in memory")

	# Ice preset: same tiers, Low = world_env_ice.tres.
	_rig.apply(LightingRig.load_preset(&"ice"))
	_check_low(ICE_ENV, "ice Low")
	_rig.set_quality(2)
	_check(_rig.world_environment.environment.ssao_enabled, "ice High has SSAO")
	_rig.set_quality(0)
	_check_low(ICE_ENV, "ice High -> Low")

	# Emberfall night: applying a preset keeps the tier.
	_rig.set_quality(3)
	var holder := Node.new()
	root.add_child(holder)
	_rig.reparent(holder)
	EmberfallNight.apply_to(holder, EmberfallNight.night())
	env = _rig.world_environment.environment
	_check(env.ssao_enabled and env.ssil_enabled, "night keeps Ultra")
	_check(env.ambient_light_energy < 0.5, "night preset not applied")
	_rig.set_quality(0)
	env = _rig.world_environment.environment
	_check(not env.ssao_enabled and not env.ssil_enabled, "night back to Low")


## Low = the preset exactly: every stored Environment property equals the .tres, the sun matches the preset.
func _check_low(path: String, label: String) -> void:
	var ref := load(path) as Environment
	var env := _rig.world_environment.environment
	_check(env != ref, "%s: the rig shows the shared .tres (tiers would edit it)" % label)
	var a := _snapshot(ref)
	var b := _snapshot(env)
	for k: String in a:
		if a[k] != b.get(k):
			_fails.append("%s: %s is %s, preset has %s" % [label, k, str(b.get(k)), str(a[k])])
	var p := _rig.preset
	_check(is_zero_approx(_rig.sun.light_angular_distance), "%s: sun angular distance not 0" % label)
	_check(is_equal_approx(_rig.sun.shadow_blur, p.shadow_blur), "%s: sun shadow_blur changed" % label)


func _snapshot(env: Environment) -> Dictionary:
	var out := {}
	for prop: Dictionary in env.get_property_list():
		if int(prop["usage"]) & PROPERTY_USAGE_STORAGE and String(prop["name"]) != "resource_local_to_scene" \
				and not String(prop["name"]).begins_with("resource_"):
			out[prop["name"]] = env.get(prop["name"])
	return out
