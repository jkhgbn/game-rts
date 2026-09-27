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


func _ready() -> void:
	camera = Camera3D.new()
	camera.fov = 50.0
	camera.far = 500.0
	add_child(camera)
	camera.make_current()
	_apply_zoom()


func focus_on(pos: Vector3) -> void:
	position = Vector3(pos.x, 0.0, pos.z)


func _process(delta: float) -> void:
	var input := Vector2.ZERO
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
