class_name RTSCamera
extends Node3D
## Top-down RTS camera.
## Arrow keys or mouse at screen edge = pan. Mouse wheel = zoom.
## Hold middle mouse and drag = rotate. Home = reset rotation.
## RTS camera (WASD) control scheme (GameSettings.rts_wasd()): physical W A S D pan too. Shift + a pan key = faster.

@export var pan_speed := 30.0
@export var fast_pan_factor := 2.0   ## Shift held with a pan key (arrows / W A S D).
@export var edge_margin := 10.0
@export var edge_pan_enabled := true
@export var min_zoom := 10.0
@export var max_zoom := 55.0
@export var zoom_step := 4.0
@export var pitch_degrees := 55.0
@export var bounds := Rect2(-58.0, -58.0, 116.0, 116.0)

var camera: Camera3D
var _zoom := 30.0
var _target_zoom := 30.0
var _rotating := false
## Bumped every frame the player pans (keys / edge): a saved "back" view (Wave Strike's P) is dropped after a pan.
var pan_serial := 0
var _fly_t := -1.0
var _fly_time := 0.35
var _fly_from: Array = []
var _fly_to: Array = []


func _ready() -> void:
	camera = Camera3D.new()
	camera.fov = 50.0
	camera.far = 500.0
	add_child(camera)
	camera.make_current()
	_apply_zoom()


func focus_on(pos: Vector3) -> void:
	_fly_t = -1.0
	position = Vector3(pos.x, 0.0, pos.z)


## [position, yaw, zoom, pitch degrees] (the view to come back to after fly_to).
func view_state() -> Array:
	return [position, rotation.y, _target_zoom, pitch_degrees]


## Eases the camera to `pos` (ground pivot), `yaw` (radians), `zoom` and `pitch` (degrees; NAN = keep) over `seconds`
## (0 = at once); a pan during the flight takes the position over (yaw / zoom / pitch keep easing).
func fly_to(pos: Vector3, yaw: float, zoom: float, seconds := 0.35, pitch := NAN) -> void:
	_fly_from = view_state()
	_fly_to = [Vector3(pos.x, 0.0, pos.z), yaw, clampf(zoom, min_zoom, max_zoom),
			pitch_degrees if is_nan(pitch) else pitch]
	_fly_time = maxf(seconds, 0.001)
	_fly_t = 0.0
	if seconds <= 0.0:
		_fly_step(1.0)


func is_flying() -> bool:
	return _fly_t >= 0.0


func _fly_step(delta: float) -> void:
	_fly_t += delta
	var k := clampf(_fly_t / _fly_time, 0.0, 1.0)
	var e := k * k * (3.0 - 2.0 * k)
	position = (_fly_from[0] as Vector3).lerp(_fly_to[0], e)
	rotation.y = lerp_angle(float(_fly_from[1]), float(_fly_to[1]), e)
	_target_zoom = lerpf(float(_fly_from[2]), float(_fly_to[2]), e)
	_zoom = _target_zoom
	pitch_degrees = lerpf(float(_fly_from[3]), float(_fly_to[3]), e)
	if k >= 1.0:
		_fly_t = -1.0


func _process(delta: float) -> void:
	var input := Vector2.ZERO
	var focus := get_viewport().gui_get_focus_owner()
	if not (focus is LineEdit or focus is TextEdit):   # arrows move the caret while the chat line is open
		if Input.is_key_pressed(KEY_LEFT):
			input.x -= 1.0
		if Input.is_key_pressed(KEY_RIGHT):
			input.x += 1.0
		if Input.is_key_pressed(KEY_UP):
			input.y -= 1.0
		if Input.is_key_pressed(KEY_DOWN):
			input.y += 1.0
	var keys := input != Vector2.ZERO
	var wasd := wasd_input()
	if wasd != Vector2.ZERO:
		input += wasd
		keys = true

	if edge_pan_enabled and DisplayServer.window_is_focused():
		var vp := get_viewport()
		var mouse := vp.get_mouse_position()
		var size := vp.get_visible_rect().size
		if Rect2(Vector2.ZERO, size).has_point(mouse):
			if mouse.x < edge_margin:
				input.x -= 1.0
			elif mouse.x > size.x - edge_margin:
				input.x += 1.0
			if mouse.y < edge_margin:
				input.y -= 1.0
			elif mouse.y > size.y - edge_margin:
				input.y += 1.0

	if input != Vector2.ZERO:
		pan_serial += 1
		if _fly_t >= 0.0:   # a pan takes the position over; yaw / zoom / pitch keep easing
			_fly_from[0] = position
			_fly_to[0] = position
	if _fly_t >= 0.0:
		_fly_step(delta)
	if input != Vector2.ZERO:
		var dir := Vector3(input.x, 0.0, input.y).normalized().rotated(Vector3.UP, rotation.y)
		var fast := fast_pan_factor if keys and Input.is_key_pressed(KEY_SHIFT) else 1.0
		position += dir * pan_speed * fast * (_zoom / 30.0) * delta

	position.x = clamp(position.x, bounds.position.x, bounds.end.x)
	position.z = clamp(position.z, bounds.position.y, bounds.end.y)

	_zoom = lerp(_zoom, _target_zoom, clamp(10.0 * delta, 0.0, 1.0))
	_apply_zoom()


## RTS camera (WASD) control scheme only: physical W A S D (Z Q S D on AZERTY) as a pan direction (x right, y down
## the screen), same speed as the arrows / edge pan. Nothing while Ctrl / Alt is held or a text field has focus.
func wasd_input() -> Vector2:
	if not GameSettings.rts_wasd():
		return Vector2.ZERO
	if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_ALT):
		return Vector2.ZERO
	var focus := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	if focus is LineEdit or focus is TextEdit:
		return Vector2.ZERO
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A):
		v.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		v.x += 1.0
	if Input.is_physical_key_pressed(KEY_W):
		v.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		v.y += 1.0
	return v


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_target_zoom = clamp(_target_zoom - zoom_step, min_zoom, max_zoom)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_target_zoom = clamp(_target_zoom + zoom_step, min_zoom, max_zoom)
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			_rotating = mb.pressed
	elif event is InputEventMouseMotion and _rotating:
		rotation.y -= (event as InputEventMouseMotion).relative.x * 0.006
	elif event is InputEventKey and event.pressed and (event as InputEventKey).keycode == KEY_HOME:
		rotation.y = 0.0


func _apply_zoom() -> void:
	var pitch := deg_to_rad(pitch_degrees)
	camera.position = Vector3(0.0, sin(pitch) * _zoom, cos(pitch) * _zoom)
	camera.rotation = Vector3(-pitch, 0.0, 0.0)
