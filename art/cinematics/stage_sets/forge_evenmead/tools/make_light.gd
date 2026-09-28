extends SceneTree
## E34.V3 golden-hour preset (docs/design/episode3-4-opening.md 8): `art/environment/lighting/preset_golden.tres`, the
## light of forge_evenmead ("the same morning" of Episodes 3 and 4). A low warm sun from the east (15 deg up:
## long shadows across the meadow, Ep3's west-looking wides are front-lit, Ep4's east-looking wides are backlit with the
## sun disc in frame), a cool sky fill from the west, a peach horizon under a clear blue top, warm depth haze that glows
## toward the sun (fog sun scatter) plus a low height fog that pools in the river valley (morning mist), glow only on
## real highlights (water glints, pollen, the heart-stone), a touch of contrast and saturation.
## Run: tools\godot_run.ps1 --headless --path . -s res://art/cinematics/stage_sets/forge_evenmead/tools/make_light.gd --quit-after 300

const OUT := "res://art/environment/lighting/preset_golden.tres"


func _initialize() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.2, 0.4, 0.78)
	sky_mat.sky_horizon_color = Color(0.98, 0.82, 0.64)
	sky_mat.sky_curve = 0.11
	sky_mat.sky_energy_multiplier = 1.0
	sky_mat.ground_horizon_color = Color(0.93, 0.78, 0.60)
	sky_mat.ground_bottom_color = Color(0.36, 0.40, 0.30)
	sky_mat.ground_curve = 0.05
	sky_mat.sun_angle_max = 22.0
	sky_mat.sun_curve = 0.06
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.62
	env.ambient_light_sky_contribution = 0.8
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.02
	env.tonemap_white = 6.0
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color(0.93, 0.84, 0.75)
	env.fog_light_energy = 1.0
	env.fog_sun_scatter = 0.7
	env.fog_density = 0.42
	env.fog_depth_begin = 45.0
	env.fog_depth_end = 300.0
	env.fog_depth_curve = 1.3
	env.fog_height = 1.2
	env.fog_height_density = 0.05
	env.fog_sky_affect = 0.0
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_strength = 1.0
	env.glow_bloom = 0.02
	env.glow_hdr_threshold = 1.1
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 1.1
	env.adjustment_brightness = 1.0
	var p := LightingPreset.new()
	p.environment = env
	p.sun_color = Color(1.0, 0.80, 0.56)
	p.sun_energy = 1.55
	# light travels due west: the sun stands low in the east, 15 deg up (both hills side-lit alike)
	p.sun_rotation_degrees = Vector3(-15.0, 90.0, 0.0)
	p.shadow_blur = 1.2
	p.shadow_opacity = 0.92
	p.shadow_normal_bias = 1.6
	p.shadow_max_distance = 200.0
	p.fill_color = Color(0.50, 0.62, 0.98)
	p.fill_energy = 0.3
	p.fill_rotation_degrees = Vector3(-24.0, -110.0, 0.0)
	p.vignette_color = Color(0.10, 0.06, 0.04)
	p.vignette_strength = 0.32
	p.vignette_inner = 0.55
	p.vignette_outer = 1.2
	p.haze_color = Color(1.0, 0.86, 0.66)
	p.haze_strength = 0.06
	p.haze_height = 0.3
	var err := ResourceSaver.save(p, OUT)
	print("LIGHT preset_golden saved err=%d" % err)
	quit()
