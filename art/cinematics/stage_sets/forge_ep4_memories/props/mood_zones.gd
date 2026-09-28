extends Node3D
## Four memories, four moods in one stage set. A set has ONE LightingPreset, so this node re-applies the LightingRig with
## the preset of the corner the camera is in (nearest corner x): winter blue hour (x -45), spring gold (x -15), frost
## pre-dawn (x 15), burned wood under frost (x 45). Idea borrowed from the Sonnet trial (forge_ep4_memories_sonnet), but
## whole presets are applied (no per-frame lerps, nothing mutated), so a cut is one clean switch.
## Deterministic: a function of the camera x only. Driven by cine's pose (group "cine_timed": stills, sheet, record)
## and by _process (the in-game CinematicPlayer), and only while the set is shown (the Evenmead shots keep their light).

const CORNERS := [-45.0, -15.0, 15.0, 45.0]
const PRESETS := [
	preload("res://art/cinematics/stage_sets/forge_ep4_memories/mood_winter.tres"),
	preload("res://art/cinematics/stage_sets/forge_ep4_memories/mood_spring.tres"),
	preload("res://art/cinematics/stage_sets/forge_ep4_memories/mood_frost.tres"),
	preload("res://art/cinematics/stage_sets/forge_ep4_memories/mood_ash.tres"),
]

var _rig: Node = null


func _ready() -> void:
	add_to_group(&"cine_timed")


func set_cine_time(_t: float) -> void:
	_update()


func _process(_dt: float) -> void:
	_update()


## The preset for a camera at world x (tests / tools).
static func preset_for_x(x: float) -> Resource:
	var best := 0
	for i: int in CORNERS.size():
		if absf(x - float(CORNERS[i])) < absf(x - float(CORNERS[best])):
			best = i
	return PRESETS[best]


func _update() -> void:
	if not is_inside_tree() or not is_visible_in_tree():
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	if _rig == null or not is_instance_valid(_rig) or not _rig.is_inside_tree():
		_rig = _find_rig()
		if _rig == null:
			return
	var want := preset_for_x(cam.global_position.x)
	if _rig.get(&"preset") != want:
		_rig.call(&"apply", want)


## The LightingRig that lights this set: a sibling of the set (cine's stage, the runtime CinematicStage) or anywhere
## under the scene root.
func _find_rig() -> Node:
	var n: Node = get_parent()
	while n != null:
		for c: Node in n.get_children():
			if c is LightingRig:
				return c
		n = n.get_parent()
	return null
