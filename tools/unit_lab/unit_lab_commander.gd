extends Node
## Unit Lab: the stand-in Commander a side's REAL AICasters (scripts/ai/ai_casters.gd, caster-units.md 8.2 / 8.3)
## talks to when the side's casters run in "bot" mode. It answers only what AICasters asks (duck typing: own_casters,
## own_soldiers, seen_enemies, army_group, rally_point, group_out, is_retreating, defending, home_keep, ...) from the
## arena's units; it never trains (queued_this_tick = true) and gives no orders itself.
## Child of the UnitLabArena (AICasters reads match_started / game_over on the commander's parent).

var team := 0
var difficulty := 1
var faction: StringName = &"fire"
var enabled := true
var arena: Node = null
var side := 0
var retreating := false
var home := Vector3.ZERO
var casters_node: Node = null


func setup(p_arena: Node, p_side: int, p_team: int, p_faction: StringName, p_home: Vector3, p_retreat: bool,
		p_difficulty: int = 1) -> void:
	arena = p_arena
	side = p_side
	team = p_team
	faction = p_faction
	home = p_home
	retreating = p_retreat
	difficulty = p_difficulty
	name = "LabCommander%d" % p_side


## Creates the real AICasters child (call after this node is in the tree).
func start_casters() -> void:
	var script := load("res://scripts/ai/ai_casters.gd") as Script
	if script == null:
		return
	casters_node = script.new(self)
	add_child(casters_node)


func _units(own: bool) -> Array:
	var out: Array = []
	if arena == null:
		return out
	for u: Variant in arena.call(&"living_units", side if own else 1 - side):
		out.append(u)
	return out


func own_casters() -> Array:
	return _units(true).filter(func(u: Unit) -> bool: return CasterKit.is_caster_unit(u))


func own_soldiers() -> Array:
	return _units(true).filter(func(u: Unit) -> bool: return not CasterKit.is_caster_unit(u))


func seen_enemies() -> Array:
	return _units(false)


func army_group() -> Array:
	return own_soldiers()


func group_out() -> bool:
	return not retreating


func is_retreating() -> bool:
	return retreating


func defending() -> bool:
	return false


func rally_point() -> Vector3:
	return home


func home_keep() -> Node3D:
	return null


func own_wizard() -> Variant:
	return null


func queued_this_tick() -> bool:
	return true   # never trains


func can_spend_now(_cost: int) -> bool:
	return false


func build_waiting() -> bool:
	return false


func note_log(_text: String) -> void:
	pass
