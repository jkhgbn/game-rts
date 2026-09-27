class_name SummonSprout
extends Node
## Lives under a freshly summoned unit (Call the Thicket's Saplings, kingdom-nature.md 3.1) for its
## grow time: the unit holds its spot, then attack-moves to the enemy nearest to `point` within
## `seek_range` of it (units first, then buildings), else keeps holding. If the owner gave the unit
## another order meanwhile (it no longer holds), that order is kept. Frees itself.

const GROW_TIME := 0.5

var point := Vector3.ZERO
var seek_range := 10.0

var _left := GROW_TIME


func _physics_process(delta: float) -> void:
	_left -= delta
	if _left > 0.0:
		return
	set_physics_process(false)
	var unit := get_parent() as Node3D
	if SpellCaster.is_target_alive(unit) and unit.has_method(&"is_holding") and bool(unit.call(&"is_holding")):
		var foe := nearest_enemy(unit, point, seek_range)
		if foe and unit.has_method(&"command_attack_move"):
			unit.call(&"command_attack_move", foe.global_position)
	queue_free()


## The living enemy of `unit` nearest to `pos` within `reach` (units first, then buildings), or null.
static func nearest_enemy(unit: Node3D, pos: Vector3, reach: float) -> Node3D:
	for group: StringName in [&"units", &"buildings"]:
		var best: Node3D = null
		var best_dist := reach
		for node in unit.get_tree().get_nodes_in_group(group):
			var t := node as Node3D
			if t == null or not SpellCaster.is_target_alive(t) or not bool(unit.call(&"is_enemy_of", t)):
				continue
			var d := Vector2(t.global_position.x - pos.x, t.global_position.z - pos.z).length()
			if d <= best_dist:
				best = t
				best_dist = d
		if best:
			return best
	return null
