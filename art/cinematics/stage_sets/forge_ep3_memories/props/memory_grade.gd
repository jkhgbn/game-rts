extends Node3D
## E34 Ep3: full-screen memory grade (props/memory_grade.tscn) shown only while the set named `follow` is on screen
## (W02 = forge_watch_keep in ep3_opening.cine). It rides as a plain cine `prop` and follows that set's visibility, so the
## same scene works in cine (stills / play / record: group "cine_timed" poses it) and in the game's CinematicStage.

@export var follow: String = "forge_watch_keep"

var _target: Node3D


func _ready() -> void:
	add_to_group(&"cine_timed")
	_sync()


func _process(_dt: float) -> void:
	_sync()


func set_cine_time(_t: float) -> void:
	_sync()


func _sync() -> void:
	if _target == null or not is_instance_valid(_target):
		_target = null
		if is_inside_tree():
			_target = get_tree().root.find_child(follow, true, false) as Node3D
	visible = _target != null and _target.is_visible_in_tree()
