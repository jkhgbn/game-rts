extends SceneTree
## forge_citadel lighting: World Forge's "dawn" mood with a cloud-sea lower sky (so the horizon past the 250 m far
## plane stays pale cloud, not brown ground) and thinner fog. Saves parts/materials/citadel_dawn.tres (set light=).
## Run: tools\godot_run.ps1 --headless --path . -s res://art/cinematics/stage_sets/forge_citadel/tools/make_light.gd --quit-after 300

const FSet := preload("res://tools/world_forge/forge_set.gd")


func _initialize() -> void:
	var p: LightingPreset = FSet.mood_preset("dawn")
	var sky := p.environment.sky.sky_material as ProceduralSkyMaterial
	sky.ground_horizon_color = Color(0.93, 0.85, 0.84)
	sky.ground_bottom_color = Color(0.80, 0.76, 0.86)
	sky.sky_horizon_color = Color(1.0, 0.80, 0.60)
	sky.sky_top_color = Color(0.28, 0.40, 0.68)
	p.environment.fog_density = 0.0016
	p.environment.fog_light_color = Color(0.92, 0.84, 0.82)
	p.environment.fog_sky_affect = 0.0
	p.environment.tonemap_exposure = 1.0
	ResourceSaver.save(p, "res://art/cinematics/stage_sets/forge_citadel/parts/materials/citadel_dawn.tres")
	print("LIGHT saved")
	quit()
