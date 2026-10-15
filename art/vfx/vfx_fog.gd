class_name VfxFog
extends RefCounted
## Fog rule shared by the spell / combat VFX hubs (fog-leak pass 2026-10-15, tests/test_fog_leak.gd).
## The fog overlay draws at render_priority -100, so transparent / additive effects draw ON TOP of the black fog:
## an effect must be skipped (or hidden) where the local player does not see it.
## Rule (same as SpellFxG and the caster families):
##   - no FogOfWar in the level, or fog off: everything shows;
##   - the local team's own effects (and its 2v2 allies', Teams.is_allied_fast) always show;
##   - any other team's effect (or an unknown team, -1) shows only where the local team sees the point now
##     (FogOfWar.is_visible), so enemy spells cast in black or grey fog draw nothing;
##   - an effect that follows a node (trail, hand glow, aura) also hides while that node is not visible_in_tree
##     (the fog hides enemy units it does not see).
## Cost: one cached group lookup (re-done only when the cached fog is freed; "no fog" is cached for the frame) and
## one grid read per check. Hubs check one-shot effects at spawn and re-check moving / long-lived ones a few times
## a second (RECHECK).

const RECHECK := 0.2   ## seconds between re-checks of moving / long-lived effects (5 Hz, the fog's own rate)

static var _node: Node = null       # the node in group "fog" (a FogOfWar, or a duck-typed stand-in in tests)
static var _fog: FogOfWar = null    # the same node when it is a real FogOfWar (fast typed path)
static var _none_frame := -1        # process frame on which the last lookup found no fog


## The node in group "fog" (cached; a FogOfWar or any node with enabled / local_team / is_visible), or null.
static func fog_node() -> Node:
	if is_instance_valid(_node) and _node.is_inside_tree():
		return _node
	_node = null
	_fog = null
	var frame := Engine.get_process_frames()
	if _none_frame == frame:
		return null
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		_node = tree.get_first_node_in_group(&"fog")
	if _node == null:
		_none_frame = frame
	else:
		_fog = _node as FogOfWar
	return _node


## The level's FogOfWar (cached), or null (no fog, or a stand-in that is not a FogOfWar).
static func fog() -> FogOfWar:
	fog_node()
	return _fog


## True when an effect of `team` (-1 = unknown) at `pos` may draw for the local player.
static func ok(team: int, pos: Vector3) -> bool:
	var n := fog_node()
	if n == null:
		return true
	if _fog:
		if not _fog.enabled:
			return true
		if team >= 0 and Teams.is_allied_fast(team, _fog.local_team):   # own (or, in 2v2, an ally's) effect
			return true
		return _fog.is_visible(_fog.local_team, pos)
	# Duck-typed stand-in (tests): same rule through get / call.
	if not bool(n.get(&"enabled")):
		return true
	var local: Variant = n.get(&"local_team")
	if local == null or (team >= 0 and Teams.is_allied_fast(team, int(local))) or not n.has_method(&"is_visible"):
		return true
	return bool(n.call(&"is_visible", int(local), pos))


## Follow rule: `n` is in the tree, visible (the fog shows it) and its point passes `ok`. Null / freed = false.
static func node_ok(n: Variant, team: int = -2) -> bool:
	if not is_instance_valid(n):
		return false
	var n3 := n as Node3D
	if n3 == null or not n3.is_inside_tree() or not n3.is_visible_in_tree():
		return false
	return ok(team_of(n3) if team == -2 else team, n3.global_position)


## The `team` of a unit / building / projectile-like node (Variant-safe), -1 when it has none.
static func team_of(n: Variant) -> int:
	if is_instance_valid(n):
		var t: Variant = (n as Object).get(&"team")
		if t != null and (t is int or t is float):
			return int(t)
	return -1
