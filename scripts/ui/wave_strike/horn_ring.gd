class_name HornRing
extends Control
## Horn countdown ring (docs/design/ui-wave-strike.md 1.4): a 3 px arc clockwise from 12 o'clock, the remaining fraction
## in GOLD over a frame_dark track; inside the warning seconds it turns hot and pulses (2 Hz); at the horn a trim_glow
## ring expands 20 -> 48 px over 0.5 s while fading. Last Horns: WARN.

const HOT := Color(1.0, 0.55, 0.35)
const BURST_TIME := 0.5

var fraction := 1.0        ## time left / interval
var hot := false
var last_horns := false
var _pulse := 0.0
var _burst := 0.0
var _scale_burst := 1.0


func _init(diameter := 20.0) -> void:
	custom_minimum_size = Vector2(diameter, diameter)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scale_burst = diameter / 20.0


func set_state(p_fraction: float, p_hot: bool, p_last: bool) -> void:
	fraction = clampf(p_fraction, 0.0, 1.0)
	hot = p_hot
	last_horns = p_last
	queue_redraw()


## The horn: the expanding glow ring.
func burst() -> void:
	_burst = BURST_TIME


func is_bursting() -> bool:
	return _burst > 0.0


func _process(delta: float) -> void:
	if hot:
		_pulse += delta
	if _burst > 0.0:
		_burst = maxf(0.0, _burst - delta)
	if hot or _burst > 0.0:
		queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 2.0
	var w := 3.0 * clampf(size.x / 20.0, 1.0, 1.6)
	draw_arc(c, r, 0.0, TAU, 32, UIStyle.token(&"frame_dark"), w, true)
	var col := UIStyle.GOLD
	if last_horns:
		col = UIStyle.WARN
	elif hot:
		col = Color(HOT, 0.8 + 0.2 * sin(_pulse * TAU * 2.0))
	if fraction > 0.0:
		var start := -PI * 0.5
		draw_arc(c, r, start, start + TAU * fraction, maxi(4, int(32 * fraction)), col, w, true)
	if _burst > 0.0:
		var k := 1.0 - _burst / BURST_TIME
		var rr := lerpf(10.0, 24.0, k) * _scale_burst
		draw_arc(c, rr, 0.0, TAU, 40, Color(UIStyle.token(&"trim_glow"), 1.0 - k), 2.0, true)
