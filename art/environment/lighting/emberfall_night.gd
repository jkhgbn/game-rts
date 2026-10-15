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
const GROUND_SHADER := "res://art/environment/ground.gdshader"
const DAY_FLOWERS := &"_day_flowers"   ## Meta on a ground material: its day flower values (runtime, not saved).
const FLOWER_KEYS: Array[StringName] = [&"flower_a", &"flower_b", &"flower_c", &"flower_d", &"flower_amount"]
## ground.gdshader defaults of FLOWER_KEYS (a material that never set one returns null).
const FLOWER_DEFAULTS := {&"flower_a": Color(0.96, 0.94, 0.86), &"flower_b": Color(1.00, 0.84, 0.26),
		&"flower_c": Color(0.72, 0.56, 0.92), &"flower_d": Color(0.95, 0.58, 0.66), &"flower_amount": 1.0}
const NIGHT_FLOWER_AMOUNT := 0.35        ## flower_amount at night = the day amount x this
## Map-dressing MultiMesh names (kind basename in PascalCase) that are flowers: muted at night.
const FLOWER_DECOR: Array[String] = ["Flower", "Daisies", "Dandelion", "Heather", "Gorse", "ButterflyBush"]
const NIGHT_DECOR_MUTE := 0.85
const GROUND_NIGHT_META := &"_ground_night"   ## Meta on the level: the night amount set_ground_night applied (runtime).

const NIGHT_SKY := {"zenith_color": Color(0.04, 0.07, 0.16), "horizon_color": Color(0.16, 0.22, 0.38),
		"ground_horizon_color": Color(0.07, 0.09, 0.14), "sun_tint": Color(0.70, 0.80, 1.0), "energy": 0.6}
const DAWN_SKY := {"zenith_color": Color(0.32, 0.42, 0.66), "horizon_color": Color(1.0, 0.70, 0.52),
		"ground_horizon_color": Color(0.36, 0.28, 0.24), "sun_tint": Color(1.0, 0.66, 0.42), "energy": 1.0}


## The cold moonlit night of Emberfall. G-E fixes B (docs/art/ge_fixes_b.md): moonlit, not black. A soft blue moon key
## from behind the camera's left (readable shadows that fall up the screen, lit unit fronts), a cool rim from the far side,
## a blue ambient that no longer comes only from the near-black sky (ground ~0.2 value), exposure back to 1; torches and
## fires stay the only warm lights. The moon stays under AmbientLife's night test (energy < 0.85, blue > red).
static func night() -> LightingPreset:
	var p := _base()
	if p == null:
		return null
	p.sun_color = Color(0.62, 0.72, 1.0)
	p.sun_energy = 0.8
	p.sun_rotation_degrees = Vector3(-50.0, -28.0, 0.0)
	p.shadow_opacity = 0.7
	p.fill_color = Color(0.42, 0.52, 0.95)
	p.fill_energy = 0.4
	p.fill_rotation_degrees = Vector3(-28.0, 165.0, 0.0)
	p.vignette_color = Color(0.01, 0.02, 0.06)
	p.vignette_strength = 0.42
	p.vignette_inner = 0.5
	p.vignette_outer = 1.1
	p.haze_color = Color(0.30, 0.38, 0.62)
	p.haze_strength = 0.1
	p.ground_night = 1.0
	var env := p.environment
	env.ambient_light_color = Color(0.34, 0.43, 0.70)
	env.ambient_light_sky_contribution = 0.35
	env.ambient_light_energy = 0.46
	env.tonemap_exposure = 1.0
	env.fog_light_color = Color(0.13, 0.17, 0.30)
	env.fog_density = 0.6
	env.adjustment_saturation = 0.7
	env.adjustment_brightness = 1.0
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
	set_ground_night(level, preset.ground_night)
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
		set_ground_night(level, preset.ground_night)
		return true
	var from := rig.preset
	var env_from := from.environment
	var env := env_from.duplicate(true) as Environment   # blended in place, then replaced by the preset's own
	rig.apply_quality_to(env, env_from)   # keep the graphics tier (SSAO, mist...) during the blend
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
		env.ambient_light_sky_contribution = lerpf(env_from.ambient_light_sky_contribution,
				preset.environment.ambient_light_sky_contribution, t)
		set_ground_night(level, lerpf(from.ground_night, preset.ground_night, t))
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
	var finish := func() -> void:
		rig.apply(preset)
		set_ground_night(level, preset.ground_night)
	tw.tween_callback(finish)
	return true


## G-E fixes B: the painted ground's flowers at night (`t` 0 = the day colours, 1 = night): dimmed, greyed toward the
## moonlight blue and fewer, on every ground.gdshader material of `level` and on the 3D grass blades' flower tips
## (GroundDetail.refresh_flowers). The day values are kept on each material (meta `_day_flowers`), so dawn gives them back.
static func set_ground_night(level: Node, t: float) -> void:
	if level == null or not is_instance_valid(level):
		return
	t = clampf(t, 0.0, 1.0)
	for n: Node in level.find_children("*", "MeshInstance3D", true, false):
		var sm := (n as MeshInstance3D).material_override as ShaderMaterial
		if sm == null or sm.shader == null or sm.shader.resource_path != GROUND_SHADER:
			continue
		if not sm.has_meta(DAY_FLOWERS):
			if t <= 0.0:
				continue   # never touched, already the day look
			var day := {}
			for k: StringName in FLOWER_KEYS:
				var cur: Variant = sm.get_shader_parameter(k)
				day[k] = cur if cur != null else FLOWER_DEFAULTS[k]   # never set = the shader's default
			sm.set_meta(DAY_FLOWERS, day)
		var d: Dictionary = sm.get_meta(DAY_FLOWERS)
		for k: StringName in FLOWER_KEYS:
			var v: Variant = d.get(k)
			if v is Color:
				sm.set_shader_parameter(k, (v as Color).lerp(_night_flower(v as Color), t))
			elif v is Vector3:
				var c := _night_flower(Color(v.x, v.y, v.z))
				sm.set_shader_parameter(k, (v as Vector3).lerp(Vector3(c.r, c.g, c.b), t))
			elif v is float:
				sm.set_shader_parameter(k, lerpf(float(v), float(v) * NIGHT_FLOWER_AMOUNT, t))
	for gd: Node in level.find_children("GroundDetail", "", false, false):
		if gd.has_method(&"refresh_flowers"):
			gd.call(&"refresh_flowers")
	# The flower decor of the map dressing (nature_painted.gdshader `night_mute`, per instance: nothing shared changes).
	# The level keeps the amount (meta) for decor chunks built later (MapDressingArt calls mute_decor).
	if t > 0.0 or level.has_meta(GROUND_NIGHT_META):
		level.set_meta(GROUND_NIGHT_META, t)
	for n: Node in level.find_children("*", "MultiMeshInstance3D", true, false):
		mute_decor(n as MultiMeshInstance3D, level)


## Mutes one map-dressing MultiMesh at night when it is a flower kind (FLOWER_DECOR) and `level` is at night (meta set by
## set_ground_night). Safe on any node / level.
static func mute_decor(mmi: MultiMeshInstance3D, level: Node) -> void:
	if mmi == null or level == null or not level.has_meta(GROUND_NIGHT_META):
		return
	var nm := String(mmi.name)
	for part: String in FLOWER_DECOR:
		if nm.contains(part):
			mmi.set_instance_shader_parameter(&"night_mute", float(level.get_meta(GROUND_NIGHT_META)) * NIGHT_DECOR_MUTE)
			return


## A flower colour under moonlight: mostly grey, a little of its hue, darker, toward the moon blue.
static func _night_flower(c: Color) -> Color:
	var l := c.r * 0.3 + c.g * 0.59 + c.b * 0.11
	var grey := Color(l * 0.62, l * 0.70, l * 0.88)
	return c.lerp(grey, 0.8) * 0.75


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
