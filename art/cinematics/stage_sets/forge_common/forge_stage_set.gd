class_name ForgeStageSet
extends Node3D
## Root script of every stage set built by World Forge (tools/world_forge/README.md). It implements the set contract of
## docs/plan/prologue-movie-plan.md 2.3 (duck-typed; the cinematic player reaches it through the group and has_method):
##   group "cinematic_sets", set_id, lighting (LightingPreset), a `Shots` child with Marker3Ds <shot>_from / _to /
##   _look_from / _look_to (metadata "fov" in degrees on _from / _to), begin_shot / end_shot / set_active / puppet.
## The same marks are in <set folder>/marks.json ({shot: {from, to, look_from, look_to, fov_from, fov_to}}).
## Generated scenes never need hand edits: change the .set spec and rebuild.

@export var set_id: StringName = &""
@export var lighting: LightingPreset
## Placed model instances whose own lights are switched off at _ready (spec `lights=off`, keeps the set at 0 lights).
@export var lights_off: Array[NodePath] = []

var _puppet_start := {}   ## tag -> Transform3D (begin_shot resets puppets here)
var _active := true


func _ready() -> void:
	add_to_group(&"cinematic_sets")
	refresh()


## Re-reads the lights to switch off and the puppets' start poses (World Forge calls it after building in memory).
func refresh() -> void:
	_puppet_start.clear()
	for np in lights_off:
		var n := get_node_or_null(np)
		if n:
			for l: Node in n.find_children("*", "Light3D", true, false):
				(l as Light3D).visible = false
	var puppets := get_node_or_null(^"Puppets")
	if puppets:
		for p: Node in puppets.get_children():
			if p is Node3D:
				_puppet_start[StringName(String(p.name).to_lower())] = (p as Node3D).transform


## Resets puppets to their start pose and plays the shot's animation (AnimationPlayer child "Acting", animation
## named after the shot) when there is one.
func begin_shot(shot_id: StringName) -> void:
	var puppets := get_node_or_null(^"Puppets")
	if puppets:
		for p: Node in puppets.get_children():
			var tag := StringName(String(p.name).to_lower())
			if p is Node3D and _puppet_start.has(tag):
				(p as Node3D).transform = _puppet_start[tag]
	var ap := get_node_or_null(^"Acting") as AnimationPlayer
	if ap and ap.has_animation(shot_id):
		ap.play(shot_id)
		ap.seek(0.0, true)


func end_shot(shot_id: StringName) -> void:
	var ap := get_node_or_null(^"Acting") as AnimationPlayer
	if ap and ap.current_animation == String(shot_id):
		ap.stop()


func set_active(on: bool) -> void:
	_active = on
	visible = on
	process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED


func is_active() -> bool:
	return _active


## The actor with this tag (spec `actor <tag> ...`), or null.
func puppet(tag: StringName) -> Node3D:
	var puppets := get_node_or_null(^"Puppets")
	if puppets == null:
		return null
	for p: Node in puppets.get_children():
		if String(p.name).to_lower() == String(tag).to_lower():
			return p as Node3D
	return null


## Shot ids that have markers in `Shots` (sorted).
func shot_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	var shots := get_node_or_null(^"Shots")
	if shots == null:
		return out
	for m: Node in shots.get_children():
		var nm := String(m.name)
		if nm.ends_with("_from") and not nm.ends_with("_look_from"):
			out.append(StringName(nm.trim_suffix("_from")))
	out.sort()
	return out


## {from, to, look_from, look_to, fov_from, fov_to} of one shot from the markers ({} when unknown).
func mark(shot_id: StringName) -> Dictionary:
	var shots := get_node_or_null(^"Shots")
	if shots == null:
		return {}
	var f := shots.get_node_or_null(NodePath(String(shot_id) + "_from")) as Marker3D
	if f == null:
		return {}
	var t := shots.get_node_or_null(NodePath(String(shot_id) + "_to")) as Marker3D
	var lf := shots.get_node_or_null(NodePath(String(shot_id) + "_look_from")) as Marker3D
	var lt := shots.get_node_or_null(NodePath(String(shot_id) + "_look_to")) as Marker3D
	var to := t if t else f
	return {"from": f.global_position, "to": to.global_position,
		"look_from": lf.global_position if lf else f.global_position + Vector3.FORWARD,
		"look_to": (lt if lt else lf).global_position if (lt or lf) else to.global_position + Vector3.FORWARD,
		"fov_from": float(f.get_meta(&"fov", 40.0)), "fov_to": float(to.get_meta(&"fov", f.get_meta(&"fov", 40.0)))}
