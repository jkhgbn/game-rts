class_name NeutralCamp
extends Node3D
## One neutral monster camp (docs/design/map-fill.md section 5.2-5.3, contract section 13). Group "neutral_camps".
## Made and driven by the CampManager (scripts/world/camp_manager.gd): `CampManager.add_camp(...)` creates it, and
## the manager calls `tick(now, dt)` twice per second. The camp:
## - spawns its creatures (CampManager.CAMP_KINDS) in a loose ring r 1.5-2 around the spot (a single creature at
##   the spot), team NEUTRAL, groups "creatures" (+ "amphibious" for Mirefangs), a "CreatureAbilities" child for
##   the Elder / Stag when scripts/units/creature_abilities.gd exists; missing creature .tres: warning, camp skipped;
## - camp level: 0 on the first spawn, +1 per respawn, max LEVEL_MAX: max HP +15 %, damage +10 % (modifier
##   `camp:level`), kill_xp +10 % and clear bonus +10 % per level; strength x (1 + 0.15 x level);
## - underdog (Q3): a kill by the team whose wizard is lower level is worth x1.25 XP (the victim's kill_xp is
##   raised just before it dies, so every normal rule, wizard share, soldier veterancy, champion loot and the
##   60 % essence, sees it); at the clear the bonus is x1.5;
## - clear: clear bonus essence to the team of the last killing blow, a roll of its tier's drop table as ground
##   items at the spot, signal `cleared(camp, team, reward)`; respawn after RESPAWN (120 / 180 / 240 s), blocked
##   while a PLAYER / ENEMY unit is within 16 m (retry every 5 s);
## - reset (no chip-damage farming): a creature within 3 m of home, not fighting and not damaged for 4 s heals
##   5 % max HP / s; all home and undamaged for 6 s: the camp heals in full;
## - when one creature is hit, its idle camp mates answer the attacker (inside their leash).
## Look (12.C8): the camp's site dressing res://art/environment/camps/<kind>_site.tscn (CampSite, 12.V24; load-guarded,
## draw-only) as the child "Site" at the spot: `set_cleared(false)` on every spawn, `set_cleared(true)` on the clear;
## camps whose first spawn is later than 0:00 (Gloomcap Hollow, Stag Glade) start cleared. The Ford Nest follows the
## ford's flow (the RiverSystem crossing's `dir`). The spawn / clear VFX come from MapFillVfx's own hooks.

signal cleared(camp: Node3D, team: int, reward: Dictionary)
signal respawned(camp: Node3D)
## The first hit by a PLAYER / ENEMY attacker since the camp was last at rest.
signal engaged(camp: Node3D)

const LEVEL_MODIFIER := &"camp:level"
const CAMP_META := &"neutral_camp"
const RING_RADII: Array[float] = [1.5, 2.0]
const NAV_SNAP := 3.0
const SITE_SCENE := "res://art/environment/camps/%s_site.tscn"
const _SIM := preload("res://scripts/core/sim_mode.gd")   # Bot Lab sim mode: no site art (docs/plan/bot-lab.md)
const FORD_SEARCH := 6.0             ## The Ford Nest takes the flow of a ford crossing this close to its spot.

var camp_id: StringName = &""
var kind: StringName = &""
var tier := 1
var display_name := ""
## 0 on the first spawn, +1 per respawn (max CampManager.LEVEL_MAX).
var camp_level := 0
var first_spawn := 0.0
## The CampManager driving this camp (time, underdog, rng, types, spawn parent).
var manager: CampManager = null

var _creatures: Array[Unit] = []
var _base_types: Dictionary = {}     # creature instance id -> UnitType (the shared .tres, before any kill_xp change)
var _spawned_once := false
var _alive := false                  # a spawn is on the field and not yet cleared
var _next_spawn_at := 0.0            # match time of the next (re)spawn attempt
var _respawn_at := 0.0               # match time the respawn timer ends (respawn_left)
var _engaged := false
var _disabled := false               # a creature type is missing: never spawns
var _times_cleared := 0
var _last_reward: Dictionary = {}
var _site: Node3D                    # the CampSite dressing (null without the art)


func _init() -> void:
	add_to_group("neutral_camps")


func _ready() -> void:
	_build_site()


## The camp's site dressing (CampSite), or null when the art does not exist.
func site() -> Node3D:
	return _site if _site and is_instance_valid(_site) else null


## Fills the camp from a spot dictionary `{id, name, kind, tier, pos, first_spawn}` (tier 0 / missing = the kind's).
func configure(spot: Dictionary) -> void:
	camp_id = StringName(str(spot.get("id", "")))
	kind = StringName(str(spot.get("kind", "")))
	display_name = str(spot.get("name", ""))
	var def: Dictionary = CampManager.CAMP_KINDS.get(kind, {})
	tier = int(spot.get("tier", 0))
	if tier <= 0:
		tier = int(def.get("tier", 1))
	first_spawn = float(spot.get("first_spawn", 0.0))
	_next_spawn_at = first_spawn
	_respawn_at = first_spawn
	var p: Variant = spot.get("pos", Vector3.ZERO)
	if p is Vector2:
		position = Vector3((p as Vector2).x, 0.0, (p as Vector2).y)
	elif p is Vector3:
		position = Vector3((p as Vector3).x, 0.0, (p as Vector3).z)
	if display_name == "":
		display_name = str(def.get("name", String(camp_id)))
	name = String(camp_id) if camp_id != &"" else "NeutralCamp"


# ---------------------------------------------------------------- public (contract)

## The living creatures of this camp.
func creatures() -> Array:
	var out: Array = []
	for u in _creatures:
		if is_instance_valid(u) and u.is_alive():
			out.append(u)
	return out


## True while no creature of this camp is alive (before the first spawn too).
func is_cleared() -> bool:
	return creatures().is_empty()


## Seconds until the next spawn (the first one, or the respawn after a clear); 0 while alive, or when the timer
## is over but the spawn is blocked by nearby units.
func respawn_left() -> float:
	if _alive or _disabled:
		return 0.0
	return maxf(0.0, _respawn_at - _now())


## Fight strength (map-fill.md section 7): the 5.1 Strength of every living creature x (1 + 0.15 x camp level).
## A cleared camp returns the full camp's strength at the level it will respawn with.
func strength() -> float:
	var level := camp_level
	var ids: Array = []
	var living := creatures()
	if living.is_empty():
		ids = creature_ids()
		if _spawned_once:
			level = mini(camp_level + 1, CampManager.LEVEL_MAX)
	else:
		for u: Unit in living:
			ids.append(u.unit_type.id if u.unit_type else &"")
	var total := 0.0
	for id: Variant in ids:
		total += float(CampManager.CREATURE_STRENGTH.get(StringName(str(id)), 0.0))
	return total * (1.0 + CampManager.LEVEL_STRENGTH * float(level))


## `{xp, essence, drop_text}` for the whole camp at its current level (the hover card line), plus `tier`,
## `camp_level` and `creatures` (the camp size). No underdog bonus in it.
func reward_preview() -> Dictionary:
	var xp := 0
	for id: StringName in creature_ids():
		xp += scaled_kill_xp(_base_kill_xp(id), camp_level, false)
	return {
		&"xp": xp,
		&"essence": clear_bonus(false),
		&"drop_text": CampManager.drop_text(tier),
		&"tier": tier,
		&"camp_level": camp_level,
		&"creatures": creature_ids().size(),
	}


## Spawns the creatures now (the manager calls it when the timer is over and nothing blocks it). A respawn
## raises the camp level. Does nothing while creatures are alive; a missing creature .tres disables the camp.
func spawn() -> void:
	if _disabled or not creatures().is_empty() or not is_inside_tree():
		return
	var ids := creature_ids()
	var types: Array[UnitType] = []
	for id: StringName in ids:
		var t := manager.creature_type(id) if manager else UnitType.find(String(id))
		if t == null:
			push_warning("NeutralCamp %s: no data/units/%s.tres, camp skipped" % [camp_id, id])
			_disabled = true
			_site_call(&"set_cleared", [true, true])
			return
		types.append(t)
	if types.is_empty():
		push_warning("NeutralCamp %s: unknown kind '%s', camp skipped" % [camp_id, kind])
		_disabled = true
		return
	var is_respawn := _spawned_once
	if is_respawn:
		camp_level = mini(camp_level + 1, CampManager.LEVEL_MAX)
	_spawned_once = true
	_creatures.clear()
	_base_types.clear()
	var parent := _spawn_parent()
	for i in types.size():
		var u := _make_creature(types[i])
		if u == null:
			continue
		parent.add_child(u)
		u.global_position = _snap(position + ring_offset(i, types.size()))
		u.command_stop()   # home = this spot (the leash centre)
		_add_abilities(u, types[i].id)
		_creatures.append(u)
		_base_types[u.get_instance_id()] = types[i]
	_alive = not _creatures.is_empty()
	_engaged = false
	if _alive:
		_site_call(&"set_cleared", [false])
	if is_respawn:
		respawned.emit(self)


# ---------------------------------------------------------------- public (extra)

## The creature type ids of this camp's kind (CampManager.CAMP_KINDS), in spawn order.
func creature_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	var def: Dictionary = CampManager.CAMP_KINDS.get(kind, {})
	for id: Variant in def.get("creatures", []):
		out.append(StringName(str(id)))
	return out


## Clear bonus essence at the current level (x1.5 with the underdog bonus).
func clear_bonus(underdog: bool) -> int:
	var base := float(CampManager.TIER_BONUS.get(tier, 0))
	var v := base * (1.0 + CampManager.LEVEL_BONUS * float(camp_level))
	if underdog:
		v *= CampManager.UNDERDOG_BONUS
	return roundi(v)


## `base` kill XP at camp level `level` (+10 % per level), x1.25 for the underdog, rounded.
static func scaled_kill_xp(base: int, level: int, underdog: bool) -> int:
	var v := float(base) * (1.0 + CampManager.LEVEL_XP * float(level))
	if underdog:
		v *= CampManager.UNDERDOG_XP
	return roundi(v)


## Offset of creature `i` of `count` from the spot: a single creature stands on it; otherwise a ring whose first
## slot points at the map centre, radii alternating 1.5 / 2.0 m. Point-mirrored spots get mirrored rings.
func ring_offset(i: int, count: int) -> Vector3:
	if count <= 1:
		return Vector3.ZERO
	var a0 := atan2(-position.z, -position.x) if Vector2(position.x, position.z).length() > 0.01 else 0.0
	var a := a0 + TAU * float(i) / float(count)
	var r: float = RING_RADII[i % RING_RADII.size()]
	return Vector3(cos(a) * r, 0.0, sin(a) * r)


func is_disabled() -> bool:
	return _disabled


func has_spawned() -> bool:
	return _spawned_once


func times_cleared() -> int:
	return _times_cleared


## The reward of the last clear ({} before the first one).
func last_reward() -> Dictionary:
	return _last_reward


## Called by the CampManager every TICK s with the match time: spawn / respawn and the reset heal.
func tick(now: float, dt: float) -> void:
	if _disabled:
		return
	if _alive:
		if creatures().is_empty():   # freed without dying (never happens in a match): count it as cleared
			_on_clear(-1)
			return
		_reset_heal(dt)
		return
	if now < _next_spawn_at:
		return
	if _spawned_once and _is_blocked():
		_next_spawn_at = now + CampManager.RESPAWN_RETRY
		return
	spawn()


# ---------------------------------------------------------------- spawn helpers

func _make_creature(type: UnitType) -> Unit:
	var u := Worker.make_unit(type)
	if u == null:
		return null
	u.team = Unit.Team.NEUTRAL
	u.add_to_group(&"creatures")
	var def: Dictionary = CampManager.CAMP_KINDS.get(kind, {})
	if bool(def.get("amphibious", false)) or CampManager.AMPHIBIOUS.has(type.id):
		u.add_to_group(&"amphibious")
	u.set_meta(CAMP_META, self)
	if camp_level > 0:
		u.add_modifier(LEVEL_MODIFIER, {
			&"max_hp_pct": CampManager.LEVEL_HP * float(camp_level),
			&"attack_damage_pct": CampManager.LEVEL_DAMAGE * float(camp_level),
		})
	u.died.connect(_on_creature_died)
	u.damage_taken.connect(_on_creature_damaged.bind(u))
	return u


# CreatureAbilities (12.C4, scripts/units/creature_abilities.gd): `setup(unit, ids)` then added as the child
# "CreatureAbilities" of the (already spawned) creature. Skipped while the script does not exist.
func _add_abilities(u: Unit, type_id: StringName) -> void:
	var ids: Array[StringName] = []
	for id: Variant in CampManager.CREATURE_ABILITIES.get(type_id, []):
		ids.append(StringName(str(id)))
	if ids.is_empty() or u.get_node_or_null(^"CreatureAbilities") != null:
		return
	var script: Script = manager.abilities_script() if manager else null
	if script == null:
		return
	var ab := script.new() as Node
	if ab == null:
		return
	ab.name = "CreatureAbilities"
	if ab.has_method(&"setup"):
		ab.call(&"setup", u, ids)
	u.add_child(ab)


## The CampSite dressing of this kind as the child "Site" (zero local offset, turned by CampSite.basis_for).
## Starts in the look of the camp's state: cleared until the first spawn when that spawn is later than 0:00.
func _build_site() -> void:
	if _site != null or kind == &"" or _SIM.enabled:
		return
	var path := SITE_SCENE % String(kind)
	if not ResourceLoader.exists(path):
		return
	var scene := load(path) as PackedScene
	var node := scene.instantiate() as Node3D if scene else null
	if node == null:
		return
	node.name = "Site"
	var turn := Basis.IDENTITY
	if node.has_method(&"basis_for"):
		turn = node.call(&"basis_for", kind, position, _ford_flow())
	node.transform = Transform3D(turn, Vector3.ZERO)
	var start_cleared := not _alive and (first_spawn > 0.0 or _spawned_once)
	if node.has_method(&"set_cleared"):
		node.call(&"set_cleared", start_cleared, true)   # before _ready: applied instantly there
	add_child(node)
	_site = node


## The downstream flow of the ford crossing under a Ford Nest (RiverSystem crossings), ZERO = CampSite's default.
func _ford_flow() -> Vector3:
	if kind != &"mirefang" or not is_inside_tree():
		return Vector3.ZERO
	var river := get_tree().get_first_node_in_group(&"river")
	if river == null or not river.has_method(&"crossings"):
		return Vector3.ZERO
	for c: Variant in river.call(&"crossings"):
		if not (c is Dictionary):
			continue
		var d: Dictionary = c
		if StringName(str(d.get("kind", ""))) != &"ford":
			continue
		var center: Vector3 = d.get("center", Vector3.ZERO)
		if Vector2(center.x - position.x, center.z - position.z).length() <= FORD_SEARCH:
			return d.get("dir", Vector3.ZERO)
	return Vector3.ZERO


func _site_call(method: StringName, args: Array) -> void:
	if _site and is_instance_valid(_site) and _site.has_method(method):
		_site.callv(method, args)


func _spawn_parent() -> Node:
	if manager and manager.spawn_parent and is_instance_valid(manager.spawn_parent):
		return manager.spawn_parent
	if manager and manager.get_parent():
		return manager.get_parent()
	return get_parent() if get_parent() else get_tree().current_scene


func _snap(p: Vector3) -> Vector3:
	if not is_inside_tree() or get_viewport() == null:
		return p
	var world := get_viewport().find_world_3d()
	if world == null:
		return p
	var map := world.navigation_map
	if not map.is_valid() or NavigationServer3D.map_get_iteration_id(map) == 0:
		return p
	var q := NavigationServer3D.map_get_closest_point(map, p)
	if Vector2(q.x - p.x, q.z - p.z).length() <= NAV_SNAP:
		return Vector3(q.x, p.y, q.z)
	return p


func _is_blocked() -> bool:
	var r2 := CampManager.RESPAWN_BLOCK_RADIUS * CampManager.RESPAWN_BLOCK_RADIUS
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u == null or not u.is_alive() or (u.team != Unit.Team.PLAYER and u.team != Unit.Team.ENEMY):
			continue
		var dx := u.global_position.x - position.x
		var dz := u.global_position.z - position.z
		if dx * dx + dz * dz <= r2:
			return true
	return false


func _base_kill_xp(id: StringName) -> int:
	var t := manager.creature_type(id) if manager else UnitType.find(String(id))
	if t:
		return t.kill_xp
	return int(CampManager.CREATURE_KILL_XP.get(id, 0))


func _now() -> float:
	return manager.match_time() if manager else 0.0


# ---------------------------------------------------------------- fights, deaths, reset

func _on_creature_damaged(_amount: float, attacker: Node3D, u: Unit) -> void:
	var team := _team_of(attacker)
	if team != Unit.Team.PLAYER and team != Unit.Team.ENEMY:
		return
	if u.hp <= 0.0:
		_set_kill_xp(u, team)
	if not _engaged:
		_engaged = true
		engaged.emit(self)
	# Camp mates standing idle answer the attacker (the unit leash drops it if it is too far from home).
	if u.hp > 0.0 and attacker is Node3D and is_instance_valid(attacker):
		for mate in creatures():
			var m := mate as Unit
			if m != u and m.attack_target == null and m.can_act():
				m.command_attack(attacker)


# The lethal hit: the victim's kill_xp becomes base x camp level x underdog, just before Unit.die() reads it.
func _set_kill_xp(u: Unit, killer_team: int) -> void:
	var base_type := _base_types.get(u.get_instance_id()) as UnitType
	if base_type == null:
		return
	var underdog := manager != null and manager.underdog_team() == killer_team
	var value := scaled_kill_xp(base_type.kill_xp, camp_level, underdog)
	if value == base_type.kill_xp:
		if u.unit_type != base_type:
			u.unit_type = base_type
		return
	var t := base_type.duplicate() as UnitType
	t.kill_xp = value
	u.unit_type = t


func _on_creature_died(u: Unit) -> void:
	if not _alive or not _creatures.has(u):
		return
	if creatures().is_empty():
		_on_clear(_team_of(u.killer))


func _on_clear(team: int) -> void:
	_alive = false
	_engaged = false
	_times_cleared += 1
	var now := _now()
	var respawn := float(CampManager.TIER_RESPAWN.get(tier, 180.0))
	_respawn_at = now + respawn
	_next_spawn_at = _respawn_at
	var no_items: Array[StringName] = []
	var reward := {&"essence": 0, &"items": no_items, &"underdog": false, &"camp_level": camp_level, &"tier": tier}
	if team == Unit.Team.PLAYER or team == Unit.Team.ENEMY:
		var underdog := manager != null and manager.underdog_team() == team
		var bonus := clear_bonus(underdog)
		reward[&"essence"] = bonus
		reward[&"underdog"] = underdog
		ItemDrops.give_essence(team, bonus)
		var rng := manager.rng if manager else RandomNumberGenerator.new()
		var items := CampManager.roll_drops(tier, rng)
		var dropped: Array[StringName] = []
		for i in items.size():
			var at := position + Vector3((float(i) - 0.5 * float(items.size() - 1)) * 0.9, 0.0, 0.0)
			if ItemDrops.spawn_pickup(_spawn_parent(), items[i], at) != null:
				dropped.append(items[i])
		reward[&"items"] = dropped
	else:
		team = -1
	_last_reward = reward
	_site_call(&"set_cleared", [true])
	cleared.emit(self, team, reward)


func _reset_heal(dt: float) -> void:
	var living := creatures()
	var all_home := true
	var quiet := INF
	var hurt := false
	for node in living:
		var u := node as Unit
		var home := u.home_position()
		var d := Vector2(u.global_position.x - home.x, u.global_position.z - home.z).length()
		var idle := u.attack_target == null or not is_instance_valid(u.attack_target)
		var since := u.seconds_since_damage()
		quiet = minf(quiet, since)
		if d > CampManager.RESET_HOME_RADIUS or not idle:
			all_home = false
			continue
		if u.hp < u.max_hp:
			hurt = true
			if since >= CampManager.RESET_DELAY:
				u.heal(u.max_hp * CampManager.RESET_REGEN_PCT * dt)
	if all_home and quiet >= CampManager.RESET_FULL_DELAY:
		if hurt:
			for node in living:
				var u := node as Unit
				u.heal(u.max_hp)
		_engaged = false


static func _team_of(node: Variant) -> int:
	if typeof(node) != TYPE_OBJECT or not is_instance_valid(node):
		return -1
	var t: Variant = (node as Object).get(&"team")
	return int(t) if t != null else -1
