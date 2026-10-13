class_name WizardControl
extends Node
## Direct control of the player's wizard (CLAUDE.md "Keys", ui-hud.md): W A S D (physical keys, so
## Z Q S D on AZERTY) walk her camera-relative on the ground plane through `Wizard.set_move_input`,
## every frame while a key is held; releasing every key sends Vector3.ZERO once. While a key is held
## the camera follows her. Works whatever is selected (the selection never changes), never while a
## text field has focus or while she is dead. SelectionManager creates it as a child.
## Only in the Hero WASD control scheme (GameSettings.hero_wasd(), UX.1): in Classic the keys do nothing here
## (physical A is attack-move there) and a walk in progress stops when the scheme changes.

const WALK_KEYS: Array[Key] = [KEY_W, KEY_A, KEY_S, KEY_D]
## Replay Lab (docs/plan/replay-lab.md): the walk is noted for replays (a no-op without a replay session).
const _REPLAY := preload("res://scripts/core/replay/replay_hooks.gd")

var selection: SelectionManager
## When false the camera does not follow her (the keys still walk her).
var follow_camera := true

var _held: Dictionary = {}     # physical Key -> true while held
var _sending := false          # a non-zero input was sent and not released yet
var _walker: Wizard = null     # U1-7: the wizard that got that input (a hero swap releases her first)


## True for the physical W A S D keys.
static func is_walk_key(code: Key) -> bool:
	return WALK_KEYS.has(code)


## True when W A S D walk the wizard (the Hero WASD control scheme).
static func walk_enabled() -> bool:
	return GameSettings.hero_wasd()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or event.is_echo():
		return
	if not walk_enabled():
		return
	var key := event as InputEventKey
	var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	if not is_walk_key(code):
		return
	if key.pressed:
		if not _text_focused() and not key.ctrl_pressed:   # Ctrl+A = select all units, never a step

			_held[code] = true
	else:
		_held.erase(code)


func _notification(what: int) -> void:
	# A key released while the window is not focused never arrives: forget every held key.
	# Same while the tree is paused (pause menu, briefing): this node gets no _input then, so a key
	# released during the pause would stay "held" after Resume (review 2026-10-08 M1).
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT 			or what == NOTIFICATION_PAUSED or what == NOTIFICATION_UNPAUSED:
		_held.clear()


func _process(_delta: float) -> void:
	if _text_focused() or not walk_enabled():
		_held.clear()
	var hero := _hero()
	if _sending and _walker != hero:
		# U1-7: the hero changed (swap, death) while a key was held: the old one stops walking
		if _walker != null and is_instance_valid(_walker):
			_REPLAY.note(&"call", [_walker, &"set_move_input", Vector3.ZERO])   # replays stop the OLD wizard
			_walker.set_move_input(Vector3.ZERO)
		_sending = false
		_walker = null
	var dir := input_direction() if hero != null else Vector3.ZERO
	if dir != Vector3.ZERO:
		if not _sending:
			# Workaround (docs/handoff/for-gameplay-coder.md): a wizard whose NavigationAgent3D never
			# had a target (fresh spawn) gets a zero avoidance velocity. A move order to her own
			# spot gives the agent one; set_move_input drops that order at once.
			_REPLAY.note(&"hero_move", [hero.global_position])
			hero.command_move(hero.global_position)
		_REPLAY.note(&"move_input", [dir])   # the session keeps only changes
		hero.set_move_input(dir)
		_sending = true
		_walker = hero
		if follow_camera:
			_follow(hero)
	elif _sending:
		_sending = false
		if hero != null:
			_REPLAY.note(&"move_input", [Vector3.ZERO])
			hero.set_move_input(Vector3.ZERO)
		_walker = null


## True while a walk key is held (and the wizard can walk).
func is_walking() -> bool:
	return _sending


## The world-space walk direction (length 0 or 1) of the held keys, relative to the camera:
## W = away from the camera, S = toward it, A / D = screen left / right.
func input_direction() -> Vector3:
	var v := Vector2.ZERO   # x = right, y = forward
	if _held.has(KEY_W):
		v.y += 1.0
	if _held.has(KEY_S):
		v.y -= 1.0
	if _held.has(KEY_D):
		v.x += 1.0
	if _held.has(KEY_A):
		v.x -= 1.0
	if v == Vector2.ZERO or selection == null or selection.camera == null:
		return Vector3.ZERO
	var basis := selection.camera.global_transform.basis
	var forward := Vector3(-basis.z.x, 0.0, -basis.z.z).normalized()
	var right := Vector3(basis.x.x, 0.0, basis.x.z).normalized()
	var dir := forward * v.y + right * v.x
	return dir.normalized() if dir.length() > 0.001 else Vector3.ZERO


## The living player wizard, or null.
func _hero() -> Wizard:
	if selection == null or not selection.enabled:
		return null
	var hero := selection.hero
	if hero == null or not is_instance_valid(hero) or not hero.is_alive():
		return null
	return hero


func _follow(hero: Wizard) -> void:
	var rig := selection.camera.get_parent() if selection.camera else null
	if rig and rig.has_method(&"focus_on"):
		rig.call(&"focus_on", hero.global_position)


func _text_focused() -> bool:
	var vp := get_viewport()
	if vp == null:
		return false
	var focus := vp.gui_get_focus_owner()
	return focus is LineEdit or focus is TextEdit
