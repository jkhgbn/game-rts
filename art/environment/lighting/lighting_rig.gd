class_name LightingRig
extends Node3D
## The whole global look of a map in one node (task A.11, docs/art/lighting.md): WorldEnvironment,
## the sun (shadows), a cool shadowless fill light and a screen vignette under the HUD.
## main.gd `_build_environment` adds one (see docs/art/lighting.md for the exact lines):
##   var rig := LightingRig.new(); rig.preset_id = &"ice"; add_child(rig)
## `preset_id`: &"warm" (default, every map) or &"ice" (Ice missions). `preset` wins if set.
## `apply(preset)` can switch the mood at runtime (e.g. a mission turning to night later).
## Graphics tiers (task G1, docs/art/lighting.md "Quality tiers"): `set_quality(q)` (0 Low = the preset exactly as
## authored, 1 Medium, 2 High, 3 Ultra) layers SSAO / SSIL / soft sun shadows (PCSS) and finer shadow / AO quality on top of the preset.
## The rig shows a per-rig copy of the preset's Environment, so tiers (and missions tinting it) never touch the
## shared .tres. Group "lighting_rigs" (GameSettings.apply_graphics calls set_quality on every rig).

const PRESET_PATHS := {
	&"warm": "res://art/environment/lighting/preset_warm.tres",
	&"ice": "res://art/environment/lighting/preset_ice.tres",
}
const VIGNETTE_SHADER_PATH := "res://art/environment/lighting/vignette.gdshader"
const VIGNETTE_LAYER := -1   ## Below every HUD CanvasLayer (they are >= 0), above the 3D world.
const GROUP := &"lighting_rigs"
const GAME_SETTINGS_PATH := "res://scripts/ui/menus/game_settings.gd"

const QUALITY_LOW := 0
const QUALITY_MEDIUM := 1
const QUALITY_HIGH := 2
const QUALITY_ULTRA := 3
const QUALITY_DEFAULT := QUALITY_HIGH   ## When GameSettings has no tier (should not happen in the game).

## Environment properties each tier sets on top of the preset (Low = none: the preset as authored). Every key of
## every tier goes back to the preset's own value when a lower tier is chosen, so the switch works both ways.
## SSAO is tuned for small units seen from 10-55 m: a short radius (ground contact, crevices of buildings) and no
## effect on direct light (light_affect 0), so sunlit tops keep their painted colour.
const ENV_TIERS: Array[Dictionary] = [
	{},
	{
		"ssao_enabled": true, "ssao_radius": 1.2, "ssao_intensity": 1.8, "ssao_power": 1.4,
		"ssao_detail": 0.6, "ssao_horizon": 0.06, "ssao_sharpness": 0.98,
		"ssao_light_affect": 0.0, "ssao_ao_channel_affect": 0.0,
	},
	{
		"ssao_enabled": true, "ssao_radius": 1.4, "ssao_intensity": 2.2, "ssao_power": 1.5,
		"ssao_detail": 0.7, "ssao_horizon": 0.06, "ssao_sharpness": 0.98,
		"ssao_light_affect": 0.05, "ssao_ao_channel_affect": 0.0,
		"ssil_enabled": true, "ssil_radius": 4.0, "ssil_intensity": 1.0, "ssil_sharpness": 0.98,
		"ssil_normal_rejection": 1.0,
	},
	{
		"ssao_enabled": true, "ssao_radius": 1.5, "ssao_intensity": 2.4, "ssao_power": 1.55,
		"ssao_detail": 0.8, "ssao_horizon": 0.06, "ssao_sharpness": 0.98,
		"ssao_light_affect": 0.05, "ssao_ao_channel_affect": 0.0,
		"ssil_enabled": true, "ssil_radius": 5.0, "ssil_intensity": 1.1, "ssil_sharpness": 0.98,
		"ssil_normal_rejection": 1.0,
	},
]
## Sun properties per tier (light_angular_distance > 0 = PCSS: hard at the feet, softer further away).
## shadow_blur_mult scales the preset's shadow_blur (PCSS already softens).
const SUN_TIERS: Array[Dictionary] = [
	{"light_angular_distance": 0.0, "shadow_blur_mult": 1.0},
	{"light_angular_distance": 0.0, "shadow_blur_mult": 1.0},
	{"light_angular_distance": 1.2, "shadow_blur_mult": 0.75},
	{"light_angular_distance": 1.4, "shadow_blur_mult": 0.75},
]
## Global (RenderingServer) shadow / effect quality per tier; -1 = the project's value (Low = today).
## *_filter: RenderingServer.ShadowQuality (2 Soft Low ... 5 Soft Ultra); ssao_q / ssil_q: 0 Very low ... 3 High.
const GLOBAL_TIERS: Array[Dictionary] = [
	{"dir_atlas": -1, "dir_filter": -1, "pos_filter": -1, "ssao_q": -1, "ssao_half": -1, "ssil_q": -1,
			"ssil_half": -1},
	{"dir_atlas": 4096, "dir_filter": 3, "pos_filter": 3, "ssao_q": 1, "ssao_half": 1, "ssil_q": -1,
			"ssil_half": -1},
	{"dir_atlas": 4096, "dir_filter": 4, "pos_filter": 3, "ssao_q": 2, "ssao_half": 1, "ssil_q": 1,
			"ssil_half": 1},
	{"dir_atlas": 8192, "dir_filter": 5, "pos_filter": 4, "ssao_q": 3, "ssao_half": 0, "ssil_q": 2,
			"ssil_half": 1},
]

@export var preset_id: StringName = &"warm"
@export var preset: LightingPreset

var world_environment: WorldEnvironment
var sun: DirectionalLight3D
var fill: DirectionalLight3D
var vignette: CanvasLayer
var quality: int = -1               ## The tier applied now (-1 = none yet).
var _vignette_mat: ShaderMaterial
var _env_copies := {}             ## preset Environment -> this rig's copy (same copy each time it comes back)
var _prop_mats: Array[ShaderMaterial] = []   ## G-D: the prop materials PropsLook wrote (held while the rig lives)


## The preset resource for an id (&"warm", &"ice"); unknown ids give the warm one.
static func load_preset(id: StringName) -> LightingPreset:
	var path: String = PRESET_PATHS.get(id, PRESET_PATHS[&"warm"])
	return load(path) as LightingPreset


## The tier the game asks for: GameSettings.effective_graphics_quality() (Low in tests / labs unless --gfx), else
## its graphics_quality, else QUALITY_DEFAULT. Read through the script so this file compiles without it.
static func settings_quality() -> int:
	if not ResourceLoader.exists(GAME_SETTINGS_PATH):
		return QUALITY_DEFAULT
	var gs := load(GAME_SETTINGS_PATH) as Script
	if gs == null:
		return QUALITY_DEFAULT
	if gs.has_method(&"effective_graphics_quality"):
		return clampi(int(gs.call(&"effective_graphics_quality")), QUALITY_LOW, QUALITY_ULTRA)
	var v: Variant = gs.get(&"graphics_quality")
	if v is int:
		return clampi(v as int, QUALITY_LOW, QUALITY_ULTRA)
	return QUALITY_DEFAULT


func _ready() -> void:
	name = "LightingRig"
	add_to_group(GROUP)
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

	quality = settings_quality()
	apply(preset if preset else load_preset(preset_id))
	# G-D: the shared map-prop materials take the tier on every level with a rig (Wave Strike, stage sets too); the
	# rig keeps them referenced for its lifetime so the cached instances (and their tier) stay until the level leaves.
	_prop_mats = PropsLook.apply(quality)


func _exit_tree() -> void:
	# The global shadow settings outlive the rig: the last rig to leave puts the project's values back
	# (menus, portraits and labs after a match see today's settings).
	if is_inside_tree() and get_tree().get_nodes_in_group(GROUP).size() <= 1:
		_apply_global(QUALITY_LOW)


## Applies a preset to the environment, the lights and the vignette (at the current quality tier).
func apply(p: LightingPreset) -> void:
	if p == null:
		return
	preset = p
	world_environment.environment = _env_copy(p.environment)
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
	_apply_quality(quality if quality >= 0 else settings_quality())


## This rig's copy of a preset Environment: made once, then the same object every time that preset is applied again
## (callers that compare environments by identity, like the Art Lab stage, keep working).
func _env_copy(src: Environment) -> Environment:
	if src == null:
		return null
	if not _env_copies.has(src):
		_env_copies[src] = src.duplicate() as Environment
	return _env_copies[src] as Environment


## Sets the graphics tier (0 Low, 1 Medium, 2 High, 3 Ultra). Any time, both ways, idempotent.
func set_quality(q: int) -> void:
	q = clampi(q, QUALITY_LOW, QUALITY_ULTRA)
	_prop_mats = PropsLook.apply(q)   # G-D: the shared map-prop materials follow the tier (docs/art/gd_props.md)
	if world_environment == null:   # before _ready: _ready applies it
		quality = q
		return
	_apply_quality(q)


## Puts tier `q`'s environment values on `env` (preset values from `base` for the keys `q` does not set).
## EmberfallNight.fade_to uses it on its blend copy so a fade keeps the tier.
func apply_quality_to(env: Environment, base: Environment = null) -> void:
	if env == null:
		return
	if base == null:
		base = preset.environment if preset else null
	var q := clampi(quality, QUALITY_LOW, QUALITY_ULTRA)
	var wanted: Dictionary = ENV_TIERS[q]
	for key: String in _all_env_keys():
		if wanted.has(key):
			env.set(key, wanted[key])
		elif base:
			env.set(key, base.get(key))


func _apply_quality(q: int) -> void:
	quality = clampi(q, QUALITY_LOW, QUALITY_ULTRA)
	apply_quality_to(world_environment.environment)
	var s: Dictionary = SUN_TIERS[quality]
	sun.light_angular_distance = float(s["light_angular_distance"])
	sun.shadow_blur = (preset.shadow_blur if preset else sun.shadow_blur) * float(s["shadow_blur_mult"])
	_apply_global(quality)


static func _all_env_keys() -> Array[String]:
	var out: Array[String] = []
	for t: Dictionary in ENV_TIERS:
		for k: String in t:
			if not out.has(k):
				out.append(k)
	return out


## The global shadow / effect quality (project values for -1).
static func _apply_global(q: int) -> void:
	var g: Dictionary = GLOBAL_TIERS[clampi(q, QUALITY_LOW, QUALITY_ULTRA)]
	var atlas := int(g["dir_atlas"])
	if atlas < 0:
		atlas = int(ProjectSettings.get_setting("rendering/lights_and_shadows/directional_shadow/size", 4096))
	RenderingServer.directional_shadow_atlas_set_size(atlas, bool(ProjectSettings.get_setting(
			"rendering/lights_and_shadows/directional_shadow/16_bits", true)))
	RenderingServer.directional_soft_shadow_filter_set_quality(_pick(g, "dir_filter",
			"rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality", 2)
			as RenderingServer.ShadowQuality)
	RenderingServer.positional_soft_shadow_filter_set_quality(_pick(g, "pos_filter",
			"rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality", 2)
			as RenderingServer.ShadowQuality)
	RenderingServer.environment_set_ssao_quality(
			_pick(g, "ssao_q", "rendering/environment/ssao/quality", 2) as RenderingServer.EnvironmentSSAOQuality,
			bool(_pick(g, "ssao_half", "rendering/environment/ssao/half_size", 1)),
			float(ProjectSettings.get_setting("rendering/environment/ssao/adaptive_target", 0.5)),
			int(ProjectSettings.get_setting("rendering/environment/ssao/blur_passes", 2)),
			float(ProjectSettings.get_setting("rendering/environment/ssao/fadeout_from", 50.0)),
			float(ProjectSettings.get_setting("rendering/environment/ssao/fadeout_to", 300.0)))
	RenderingServer.environment_set_ssil_quality(
			_pick(g, "ssil_q", "rendering/environment/ssil/quality", 2) as RenderingServer.EnvironmentSSILQuality,
			bool(_pick(g, "ssil_half", "rendering/environment/ssil/half_size", 1)),
			float(ProjectSettings.get_setting("rendering/environment/ssil/adaptive_target", 0.5)),
			int(ProjectSettings.get_setting("rendering/environment/ssil/blur_passes", 4)),
			float(ProjectSettings.get_setting("rendering/environment/ssil/fadeout_from", 50.0)),
			float(ProjectSettings.get_setting("rendering/environment/ssil/fadeout_to", 300.0)))


static func _pick(g: Dictionary, key: String, setting: String, fallback: int) -> int:
	var v := int(g[key])
	if v >= 0:
		return v
	return int(ProjectSettings.get_setting(setting, fallback))
