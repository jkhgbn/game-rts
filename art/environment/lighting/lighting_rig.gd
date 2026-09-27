class_name LightingRig
extends Node3D
## The whole global look of a map in one node (task A.11, docs/art/lighting.md): WorldEnvironment,
## the sun (shadows), a cool shadowless fill light and a screen vignette under the HUD.
## main.gd `_build_environment` adds one (see docs/art/lighting.md for the exact lines):
##   var rig := LightingRig.new(); rig.preset_id = &"ice"; add_child(rig)
## `preset_id`: &"warm" (default, every map) or &"ice" (Ice missions). `preset` wins if set.
## `apply(preset)` can switch the mood at runtime (e.g. a mission turning to night later).

const PRESET_PATHS := {
	&"warm": "res://art/environment/lighting/preset_warm.tres",
	&"ice": "res://art/environment/lighting/preset_ice.tres",
}
const VIGNETTE_SHADER_PATH := "res://art/environment/lighting/vignette.gdshader"
const VIGNETTE_LAYER := -1   ## Below every HUD CanvasLayer (they are >= 0), above the 3D world.

@export var preset_id: StringName = &"warm"
@export var preset: LightingPreset

var world_environment: WorldEnvironment
var sun: DirectionalLight3D
var fill: DirectionalLight3D
var vignette: CanvasLayer
var _vignette_mat: ShaderMaterial


## The preset resource for an id (&"warm", &"ice"); unknown ids give the warm one.
static func load_preset(id: StringName) -> LightingPreset:
	var path: String = PRESET_PATHS.get(id, PRESET_PATHS[&"warm"])
	return load(path) as LightingPreset


func _ready() -> void:
	name = "LightingRig"
	world_environment = WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	add_child(world_environment)

	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_blend_splits = false
	sun.light_specular = 0.5
	add_child(sun)

	fill = DirectionalLight3D.new()
	fill.name = "Fill"
	fill.shadow_enabled = false
	fill.light_specular = 0.0
	fill.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY   # not in the sky shader's LIGHT0
	add_child(fill)

	vignette = CanvasLayer.new()
	vignette.name = "Vignette"
	vignette.layer = VIGNETTE_LAYER
	add_child(vignette)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette_mat = ShaderMaterial.new()
	_vignette_mat.shader = load(VIGNETTE_SHADER_PATH) as Shader
	rect.material = _vignette_mat
	vignette.add_child(rect)

	apply(preset if preset else load_preset(preset_id))


## Applies a preset to the environment, the lights and the vignette.
func apply(p: LightingPreset) -> void:
	if p == null:
		return
	preset = p
	world_environment.environment = p.environment
	sun.light_color = p.sun_color
	sun.light_energy = p.sun_energy
	sun.rotation_degrees = p.sun_rotation_degrees
	sun.shadow_blur = p.shadow_blur
	sun.shadow_opacity = p.shadow_opacity
	sun.shadow_normal_bias = p.shadow_normal_bias
	sun.directional_shadow_max_distance = p.shadow_max_distance
	fill.visible = p.fill_energy > 0.0
	fill.light_color = p.fill_color
	fill.light_energy = p.fill_energy
	fill.rotation_degrees = p.fill_rotation_degrees
	vignette.visible = p.vignette_strength > 0.0 or p.haze_strength > 0.0
	_vignette_mat.set_shader_parameter(&"tint", p.vignette_color)
	_vignette_mat.set_shader_parameter(&"strength", p.vignette_strength)
	_vignette_mat.set_shader_parameter(&"inner", p.vignette_inner)
	_vignette_mat.set_shader_parameter(&"outer", p.vignette_outer)
	_vignette_mat.set_shader_parameter(&"haze_color", p.haze_color)
	_vignette_mat.set_shader_parameter(&"haze_strength", p.haze_strength)
	_vignette_mat.set_shader_parameter(&"haze_height", p.haze_height)
