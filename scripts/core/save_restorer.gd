extends Node
## Applies a save to the freshly rebuilt level it is a child of (docs/design/save-load.md). Created by
## SaveGame.instantiate_level before the level enters the tree. Waits for the level's match to run, then
## SaveWorld.apply_phase1 (teams, buildings, units), PHASE2_DELAY frames later apply_phase2 (HP, modifiers, orders,
## clock, mission), then frees itself. Runs while the tree is paused (the STR / INT panel pauses a skirmish start).

signal finished(ok: bool)

const PHASE2_DELAY := 2
const TIMEOUT_FRAMES := 7200   ## About 2 min at 60 fps: the navmesh never baked.

var data: Dictionary = {}
var _level: Node
var _ctx: Dictionary = {}
var _phase := 0
var _wait := 0
var _restore_cinematics := true


## Before the level enters the tree: briefing, films and dialogue off while the save rebuilds it.
func prepare(level: Node) -> void:
	_level = level
	if &"cinematics_enabled" in level:
		_restore_cinematics = bool(level.get(&"cinematics_enabled"))
		level.set(&"cinematics_enabled", false)
	if &"show_briefing" in level:
		level.set(&"show_briefing", false)
	if &"save_restoring" in level:
		level.set(&"save_restoring", true)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _level == null:
		_level = get_parent()


func _process(_delta: float) -> void:
	_wait += 1
	match _phase:
		0:
			if _level_ready():
				_ctx = SaveWorld.apply_phase1(_level, data.get("world", {}))
				_phase = 1
				_wait = 0
			elif _wait > TIMEOUT_FRAMES:
				_done(false)
		1:
			if _wait >= PHASE2_DELAY:
				SaveWorld.apply_phase2(_level, data.get("world", {}), _ctx)
				_done(true)


func _level_ready() -> bool:
	if _level.get(&"hero") == null:
		return false
	if &"match_started" in _level:
		return bool(_level.get(&"match_started"))
	var dir: Variant = _level.get(&"director")
	if dir is Object and &"running" in dir:
		return bool(dir.get(&"running"))
	return true


func _done(ok: bool) -> void:
	if &"save_restoring" in _level:
		_level.set(&"save_restoring", false)
	if &"cinematics_enabled" in _level:
		_level.set(&"cinematics_enabled", _restore_cinematics)
	var hud: Variant = _level.get(&"hud")
	if hud is Object and is_instance_valid(hud) and hud.has_method(&"show_message"):
		hud.call(&"show_message", SaveGame.MSG_LOADED if ok else SaveGame.REASON_BAD_FILE, 3.0)
	_phase = 2
	set_process(false)
	finished.emit(ok)
	queue_free()
