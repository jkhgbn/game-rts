class_name CinematicInput
extends Node
## Cinematic keys (cinematics.md 6.4, prologue 2.5): `cinematic_skip` (Esc, Space), `cinematic_advance` (Enter,
## Keypad Enter), `cinematic_pause` (P), physical keycodes. A child of CinematicPlayer while it plays; handled in
## `_input` (before any gameplay `_unhandled_input`) and consumed, so Space never reaches the game.

const SKIP := &"cinematic_skip"
const ADVANCE := &"cinematic_advance"
const PAUSE := &"cinematic_pause"

var player: Node = null


func _init() -> void:
	name = "CinematicInput"
	process_mode = Node.PROCESS_MODE_ALWAYS


## Adds the three actions at runtime when the project file lacks them (tests, old builds).
static func ensure_actions() -> void:
	_ensure(SKIP, [KEY_ESCAPE, KEY_SPACE])
	_ensure(ADVANCE, [KEY_ENTER, KEY_KP_ENTER])
	_ensure(PAUSE, [KEY_P])


static func _ensure(action: StringName, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for k: int in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k as Key
		InputMap.action_add_event(action, ev)


func _ready() -> void:
	ensure_actions()


func _input(event: InputEvent) -> void:
	if player == null or not is_instance_valid(player) or not player.call(&"is_playing"):
		return
	if bool(player.get(&"recording")):
		return   # recording mode: no input at all
	var handled := false
	if event.is_action_pressed(SKIP, false, true):
		player.call(&"press_skip")
		handled = true
	elif event.is_action_pressed(ADVANCE, false, true):
		player.call(&"end_line")
		handled = true
	elif event.is_action_pressed(PAUSE, false, true):
		player.call(&"set_paused", not bool(player.call(&"is_paused")))
		handled = true
	elif event.is_action(SKIP) or event.is_action(ADVANCE) or event.is_action(PAUSE):
		handled = true   # releases / echoes never reach the game either
	if handled:
		get_viewport().set_input_as_handled()
