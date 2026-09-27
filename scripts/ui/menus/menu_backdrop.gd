class_name MenuBackdrop
extends Control
## The main menu's animated background: a painted dusk gradient, a dark ridge line with a keep
## silhouette and embers drifting up. Drawn in 2D, so it costs almost nothing.

const EMBER_COUNT := 70
const TOP := Color(0.05, 0.03, 0.09)
const MIDDLE := Color(0.22, 0.07, 0.08)
const HORIZON := Color(0.75, 0.3, 0.08)
const RIDGE := Color(0.03, 0.02, 0.04)

var _embers: Array[Vector4] = []   # x, y, speed, size (x / y in 0-1 of the screen)
var _time := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.seed = 7
	for i in EMBER_COUNT:
		_embers.append(_new_ember(_rng.randf()))


func _process(delta: float) -> void:
	_time += delta
	for i in _embers.size():
		var e := _embers[i]
		e.y -= e.z * delta
		e.x += sin(_time * 0.7 + float(i)) * 0.004 * delta
		if e.y < -0.02:
			e = _new_ember(1.02)
		_embers[i] = e
	queue_redraw()


func _draw() -> void:
	var s := size
	var mid_y := s.y * 0.45
	var hor_y := s.y * 0.78
	_band(0.0, mid_y, TOP, MIDDLE)
	_band(mid_y, hor_y, MIDDLE, HORIZON)
	_band(hor_y, s.y, HORIZON.darkened(0.3), RIDGE)
	# Soft glow behind the title.
	for r in 6:
		draw_circle(Vector2(s.x * 0.5, s.y * 0.72), s.x * (0.34 - r * 0.045),
				Color(1.0, 0.45, 0.12, 0.035))
	# Ridge with a keep silhouette on the right.
	var ridge := PackedVector2Array([Vector2(0, s.y * 0.8), Vector2(s.x * 0.12, s.y * 0.76),
			Vector2(s.x * 0.25, s.y * 0.81), Vector2(s.x * 0.4, s.y * 0.78), Vector2(s.x * 0.55, s.y * 0.83),
			Vector2(s.x * 0.7, s.y * 0.77), Vector2(s.x * 0.86, s.y * 0.8), Vector2(s.x, s.y * 0.75),
			Vector2(s.x, s.y), Vector2(0, s.y)])
	draw_colored_polygon(ridge, RIDGE)
	var kx := s.x * 0.78
	var ky := s.y * 0.78
	draw_rect(Rect2(kx - 40, ky - 110, 80, 115), RIDGE)
	draw_rect(Rect2(kx - 70, ky - 60, 30, 65), RIDGE)
	draw_rect(Rect2(kx + 40, ky - 70, 30, 75), RIDGE)
	draw_colored_polygon(PackedVector2Array([Vector2(kx - 48, ky - 110), Vector2(kx, ky - 170),
			Vector2(kx + 48, ky - 110)]), RIDGE)
	var flicker := 0.7 + 0.3 * sin(_time * 5.0)
	draw_rect(Rect2(kx - 6, ky - 90, 12, 18), Color(1.0, 0.6, 0.2, flicker))
	# Embers.
	for e in _embers:
		var p := Vector2(e.x * s.x, e.y * s.y)
		var glow := 0.55 + 0.45 * sin(_time * 3.0 + e.x * 40.0)
		draw_circle(p, e.w * 2.2, Color(1.0, 0.4, 0.1, 0.12 * glow))
		draw_circle(p, e.w, Color(1.0, 0.75, 0.3, 0.8 * glow))


func _band(y0: float, y1: float, c0: Color, c1: Color) -> void:
	var w := size.x
	draw_polygon(PackedVector2Array([Vector2(0, y0), Vector2(w, y0), Vector2(w, y1), Vector2(0, y1)]),
			PackedColorArray([c0, c0, c1, c1]))


func _new_ember(y: float) -> Vector4:
	return Vector4(_rng.randf(), y, _rng.randf_range(0.02, 0.07), _rng.randf_range(1.0, 2.6))
