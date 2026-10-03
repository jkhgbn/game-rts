class_name EmberfallNight
extends RefCounted
## Mission 0 "The Night of Knives" moods (docs/design/mission-00.md "Night", 19.V24 moonlight + dawn presets), built in
## code from the warm preset so the painted sky, grade and fog stay the house look:
## - `night()`: the sun becomes a cold, low moon (blue-white, weak), cold ambient, deep blue sky, darker grade.
## - `dawn()`: a low rose-gold sun over a pale sky (the Emberguard rides in at first light).
## `apply_to(level, preset)` swaps the level's LightingRig to it; `fade_to(level, preset, seconds)` blends the lights,
## sky colours and exposure over `seconds` (m0_dawn shot 1: 6 s). 0 lights are added: only the rig's sun / fill change.

const WARM_PATH := "res://art/environment/lighting/preset_warm.tres"
const FADE_META := &"emberfall_fade"   ## The running fade_to tween on the rig (apply_to / a new fade stops it).

const NIGHT_SKY := {"zenith_color": Color(0.03, 0.05, 0.12), "horizon_color": Color(0.12, 0.16, 0.28),
		"ground_horizon_color": Color(0.06, 0.07, 0.10), "sun_tint": Color(0.70, 0.80, 1.0), "energy": 0.55}
const DAWN_SKY := {"zenith_color": Color(0.32, 0.42, 0.66), "horizon_color": Color(1.0, 0.70, 0.52),
		"ground_horizon_color": Color(0.36, 0.28, 0.24), "sun_tint": Color(1.0, 0.66, 0.42), "energy": 1.0}


## The cold moonlit night of Emberfall.
static func night() -> LightingPreset:
	var p := _base()
	if p == null:
		return null
	p.sun_color = Color(0.55, 0.66, 1.0)
	p.sun_energy = 0.55
	p.sun_rotation_degrees = Vector3(-38.0, -30.0, 0.0)
	p.shadow_opacity = 0.75
	p.fill_color = Color(0.30, 0.38, 0.70)
	p.fill_energy = 0.18
	p.vignette_color = Color(0.01, 0.02, 0.06)
	p.vignette_strength = 0.55
	p.vignette_inner = 0.45
	p.vignette_outer = 1.05
	p.haze_color = Color(0.25, 0.32, 0.55)
	p.haze_strength = 0.12
	var env := p.environment
	env.ambient_light_color = Color(0.30, 0.38, 0.62)
	env.ambient_light_energy = 0.42
	env.tonemap_exposure = 0.82
	env.fog_light_color = Color(0.16, 0.20, 0.34)
	env.fog_density = 0.7
	env.adjustment_saturation = 0.78
	env.adjustment_brightness = 0.92
	_set_sky(env, NIGHT_SKY)
	return p


## First light: the Emberguard's dawn.
static func dawn() -> LightingPreset:
	var p := _base()
	if p == null:
		return null
	p.sun_color = Color(1.0, 0.78, 0.58)
	p.sun_energy = 1.15
	p.sun_rotation_degrees = Vector3(-22.0, 120.0, 0.0)
	p.fill_color = Color(0.55, 0.62, 0.92)
	p.fill_energy = 0.22
	p.vignette_color = Color(0.12, 0.06, 0.06)
	p.vignette_strength = 0.35
	p.haze_color = Color(1.0, 0.80, 0.66)
	p.haze_strength = 0.14
	var env := p.environment
	env.ambient_light_color = Color(0.62, 0.56, 0.62)
	env.ambient_light_energy = 0.68
	env.tonemap_exposure = 0.95
	env.fog_light_color = Color(0.92, 0.72, 0.60)
	env.adjustment_saturation = 1.0
	_set_sky(env, DAWN_SKY)
	return p


## The level's LightingRig (main.gd adds it as a direct child), or null (Bot Lab sim, no art).
static func rig_of(level: Node) -> LightingRig:
	if level == null:
		return null
	for c in level.get_children():
		if c is LightingRig:
			return c as LightingRig
	return null


## Swaps the level's rig to `preset` at once. False when there is no rig.
static func apply_to(level: Node, preset: LightingPreset) -> bool:
	var rig := rig_of(level)
	if rig == null or preset == null:
		return false
	_stop_fade(rig)
	rig.apply(preset)
	return true


static func _stop_fade(rig: LightingRig) -> void:
	if not rig.has_meta(FADE_META):
		return
	var old: Variant = rig.get_meta(FADE_META)
	if old is Tween and (old as Tween).is_valid():
		(old as Tween).kill()
	rig.remove_meta(FADE_META)


## Blends the rig from what it shows now to `preset` over `seconds` (lights, sky colours, ambient, exposure), then
## applies `preset` exactly. Runs on a tween of the rig (stops if the level leaves the tree); `while_paused` keeps it
## running while the tree is paused (a PAUSE cinematic).
static func fade_to(level: Node, preset: LightingPreset, seconds: float, while_paused := false) -> bool:
	var rig := rig_of(level)
	if rig == null or preset == null:
		return false
	if seconds <= 0.0 or rig.preset == null:
		rig.apply(preset)
		return true
	var from := rig.preset
	var env_from := from.environment
	var env := env_from.duplicate(true) as Environment   # blended in place, then replaced by the preset's own
	rig.world_environment.environment = env
	var sky_from := _sky_values(env_from)
	var sky_to := _sky_values(preset.environment)
	var blend := func(t: float) -> void:
		rig.sun.light_color = from.sun_color.lerp(preset.sun_color, t)
		rig.sun.light_energy = lerpf(from.sun_energy, preset.sun_energy, t)
		rig.sun.rotation_degrees = from.sun_rotation_degrees.lerp(preset.sun_rotation_degrees, t)
		rig.fill.light_color = from.fill_color.lerp(preset.fill_color, t)
		rig.fill.light_energy = lerpf(from.fill_energy, preset.fill_energy, t)
		env.ambient_light_color = env_from.ambient_light_color.lerp(preset.environment.ambient_light_color, t)
		env.ambient_light_energy = lerpf(env_from.ambient_light_energy, preset.environment.ambient_light_energy, t)
		env.tonemap_exposure = lerpf(env_from.tonemap_exposure, preset.environment.tonemap_exposure, t)
		env.fog_light_color = env_from.fog_light_color.lerp(preset.environment.fog_light_color, t)
		env.adjustment_saturation = lerpf(env_from.adjustment_saturation, preset.environment.adjustment_saturation, t)
		var mat := _sky_material(env)
		if mat:
			for k: String in sky_to:
				var a: Variant = sky_from.get(k, sky_to[k])
				var b: Variant = sky_to[k]
				mat.set_shader_parameter(k, (a as Color).lerp(b as Color, t) if a is Color else lerpf(float(a), float(b), t))
	_stop_fade(rig)
	var tw := rig.create_tween()
	rig.set_meta(FADE_META, tw)
	if while_paused:
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_method(blend, 0.0, 1.0, seconds)
	tw.tween_callback(func() -> void: rig.apply(preset))
	return true


# ---------------------------------------------------------------- helpers

static func _base() -> LightingPreset:
	var warm := load(WARM_PATH) as LightingPreset
	if warm == null:
		return null
	var p := warm.duplicate() as LightingPreset
	p.environment = warm.environment.duplicate(true) as Environment
	return p


static func _sky_material(env: Environment) -> ShaderMaterial:
	if env == null or env.sky == null:
		return null
	return env.sky.sky_material as ShaderMaterial


static func _set_sky(env: Environment, values: Dictionary) -> void:
	var mat := _sky_material(env)
	if mat == null:
		return
	for k: String in values:
		mat.set_shader_parameter(k, values[k])


static func _sky_values(env: Environment) -> Dictionary:
	var out := {}
	var mat := _sky_material(env)
	if mat == null:
		return out
	for k: String in NIGHT_SKY:
		out[k] = mat.get_shader_parameter(k)
	return out
