extends SceneTree
## forge_citadel lighting: World Forge's "dawn" mood with a cloud-sea lower sky (so the horizon past the 250 m far
## plane stays pale cloud, not brown ground). Polish round (15:00 playtest pass): the haze is pushed into the distance
## (depth fog from 70 m + a low height fog over the cloud sea) so the citadel reads crisp; a low warm sun from the
## west-north-west (3/4 back light: rim-lit towers against the sky, the sun disc in the S03 / S04 skies), a cool fill
## from the east, less sky ambient, glow only on real highlights (lanterns, glints), a touch of contrast.
## Saves parts/materials/citadel_dawn.tres (set light=).
## Run: tools\godot_run.ps1 --headless --path . -s res://art/cinematics/stage_sets/forge_citadel/tools/make_light.gd --quit-after 300

const FSet := preload("res://tools/world_forge/forge_set.gd")


func _initialize() -> void:
	var p: LightingPreset = FSet.mood_preset("dawn")
	var sky := p.environment.sky.sky_material as ProceduralSkyMaterial
	sky.ground_horizon_color = Color(0.94, 0.80, 0.74)
	sky.ground_bottom_color = Color(0.62, 0.58, 0.74)
	sky.sky_horizon_color = Color(1.0, 0.72, 0.50)
	sky.sky_top_color = Color(0.17, 0.27, 0.56)
	sky.sky_curve = 0.09
	sky.sun_angle_max = 14.0
	sky.sun_curve = 0.08
	var env := p.environment
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.5
	env.ambient_light_sky_contribution = 0.85
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_density = 0.62
	env.fog_depth_begin = 70.0
	env.fog_depth_end = 330.0
	env.fog_depth_curve = 1.7
	env.fog_light_color = Color(0.93, 0.80, 0.76)
	env.fog_sun_scatter = 0.25
	env.fog_height = 16.0
	env.fog_height_density = 0.035
	env.fog_sky_affect = 0.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.tonemap_white = 5.0
	env.glow_enabled = true
	env.glow_intensity = 0.85
	env.glow_strength = 1.0
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.05
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.12
	env.adjustment_saturation = 1.12
	env.adjustment_brightness = 0.98
	p.sun_color = Color(1.0, 0.76, 0.52)
	p.sun_energy = 1.35
	p.sun_rotation_degrees = Vector3(-13.0, -112.0, 0.0)
	p.shadow_max_distance = 220.0
	p.fill_color = Color(0.52, 0.62, 0.98)
	p.fill_energy = 0.32
	p.fill_rotation_degrees = Vector3(-28.0, 70.0, 0.0)
	p.vignette_color = Color(0.05, 0.03, 0.08)
	p.vignette_strength = 0.4
	ResourceSaver.save(p, "res://art/cinematics/stage_sets/forge_citadel/parts/materials/citadel_dawn.tres")
	print("LIGHT saved")
	quit()
