class_name NeutralFlickerLight
extends OmniLight3D
## Task G-B neutral: a warm point light for lanterns, hearths, braziers and capture beacons (made by
## NeutralBuildingLook.add_light, Ultra tier only). No shadows, fades out with camera distance, small specular.
## Owners drive it with set_level(k) (0 = off, eases in ~0.4 s), set_tint(c) and flash(k) (a short boost).

var base_energy: float = 1.0
var flicker: float = 0.15
var speed: float = 1.0
var _level: float = 1.0
var _shown: float = 1.0
var _flash: float = 0.0
var _t: float = 0.0


func _ready() -> void:
	shadow_enabled = false
	light_specular = 0.25
	omni_attenuation = 1.4
	distance_fade_enabled = true
	distance_fade_begin = 110.0
	distance_fade_length = 30.0
	_t = randf() * 50.0
	_update(0.0)


func _process(delta: float) -> void:
	_t += delta * speed
	_shown = move_toward(_shown, _level, delta / 0.4)
	_flash = maxf(_flash - delta * 1.6, 0.0)
	_update(delta)
	# Off and settled (level 0, hidden, no flash): stop ticking until set_level / flash wake it.
	if _level <= 0.0 and _shown <= 0.0 and _flash <= 0.0 and not visible:
		set_process(false)


## Target brightness 0..1 (eased).
func set_level(k: float, snap: bool = false) -> void:
	_level = clampf(k, 0.0, 2.0)
	if snap or not is_inside_tree():
		_shown = _level
		_update(0.0)
	if _level > 0.0 or _shown > 0.0:
		set_process(true)


func set_tint(c: Color) -> void:
	light_color = c


## A short extra burst (k = peak multiplier added, decays in ~0.6 s).
func flash(k: float = 1.0) -> void:
	_flash = maxf(_flash, k)
	if _flash > 0.0:
		set_process(true)


func _update(_delta: float) -> void:
	var w: float = sin(_t * 7.3) * 0.5 + sin(_t * 13.1 + 1.7) * 0.3 + sin(_t * 2.3 + 0.4) * 0.2
	light_energy = base_energy * _shown * (1.0 + flicker * w) * (1.0 + _flash)
	visible = light_energy > 0.01
