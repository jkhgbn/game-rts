class_name LightingPreset
extends Resource
## One map mood (task A.11, docs/art/lighting.md): the Environment plus the sun, the cool fill light
## and the vignette that LightingRig builds from it. Presets: preset_warm.tres (default, every map),
## preset_ice.tres (Ice missions / snowy maps).

@export var environment: Environment

@export_group("Sun")
@export var sun_color: Color = Color(1.0, 0.89, 0.74)
@export var sun_energy: float = 1.35
## Pitch (x, negative = from above) and yaw (y) in degrees. The RTS camera looks toward -Z.
@export var sun_rotation_degrees: Vector3 = Vector3(-52.0, 40.0, 0.0)
@export var shadow_blur: float = 1.6
@export var shadow_opacity: float = 1.0
@export var shadow_normal_bias: float = 2.0
@export var shadow_max_distance: float = 110.0

@export_group("Fill light")
## A second, shadowless directional light from the opposite side: cool light on the faces the sun
## misses (painted "cool shadow side"). 0 = off.
@export var fill_color: Color = Color(0.55, 0.66, 0.95)
@export var fill_energy: float = 0.25
@export var fill_rotation_degrees: Vector3 = Vector3(-30.0, -140.0, 0.0)

@export_group("Vignette")
@export var vignette_color: Color = Color(0.10, 0.06, 0.05)
@export var vignette_strength: float = 0.35
@export var vignette_inner: float = 0.55
@export var vignette_outer: float = 1.15
@export var haze_color: Color = Color(0.95, 0.85, 0.70)
@export var haze_strength: float = 0.0
@export var haze_height: float = 0.25
