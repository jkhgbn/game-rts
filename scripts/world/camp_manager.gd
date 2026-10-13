class_name CampManager
extends Node
## The neutral monster camps of a map (docs/design/map-fill.md sections 5.1-5.3, contract section 13). One node per
## match in group "camp_manager"; find it with `CampManager.instance(tree)`. The skirmish (12.C1) creates it from
## its CAMP_SPOTS (`setup(spots)`); missions place single camps with `add_camp(...)`.
## - Owns one NeutralCamp (scripts/world/neutral_camp.gd) child per spot and ticks them every TICK s of match time:
##   first spawns at their `first_spawn` (0:00 / 0:00 / 2:30 / 3:30 in the skirmish), respawns, the reset heal.
## - Numbers: CAMP_KINDS (creatures per kind, tier, respawn, clear bonus, drops), TIER_* tables, camp levels,
##   underdog bonus (`underdog_team()`: the team whose wizard is lower level, -1 when equal / unknown).
## - Pays the clear bonus (EssenceBank through ItemDrops) and drops items on the ground (ItemDrops.spawn_pickup),
##   re-emits every camp's `cleared` as `camp_cleared(camp, team, reward)` and counts clears per team.
## - Messages (`message(text, seconds)`): the level may connect it to hud.show_message; if nothing is connected
##   the manager calls the parent's `hud.show_message` itself. Own clears (`Stag Glade cleared: +50 essence`, the
##   drops, the underdog line), enemy clears only where the local team sees the spot, `The Hollow Stags roam the
##   glades` once at the first stag spawn.
## - Match time: `match_time_source`, else the parent's `match_time()`, else this node's age.
## Creature .tres (12.C4) and CreatureAbilities (12.C4) are loaded by path / id, never as static types; a missing
## creature type skips its camp with a warning (`creature_types` lets tests and missions supply their own).

signal camp_cleared(camp: Node3D, team: int, reward: Dictionary)
## A line for the HUD message area.
signal message(text: String, seconds: float)

const TICK := 0.5

## Creatures per kind (spawn order), default tier and display name. Respawn, bonus and drops follow the tier.
const CAMP_KINDS := {
	&"bristleback": {"name": "Bristleback Wallow", "tier": 1,
			"creatures": [&"bristleback", &"bristleback"], "respawn": 120.0, "bonus": 10, "drops": 1},
	&"mirefang": {"name": "Ford Nest", "tier": 2, "amphibious": true,
			"creatures": [&"mirefang", &"mirefang", &"mirefang"], "respawn": 180.0, "bonus": 25, "drops": 2},
	&"gloomcap": {"name": "Gloomcap Hollow", "tier": 2,
			"creatures": [&"gloomcap_elder", &"gloomcap_sprout", &"gloomcap_sprout", &"gloomcap_sprout"],
			"respawn": 180.0, "bonus": 25, "drops": 2},
	&"hollow_stag": {"name": "Stag Glade", "tier": 3,
			"creatures": [&"hollow_stag"], "respawn": 240.0, "bonus": 50, "drops": 3},
}
const TIER_RESPAWN := {1: 120.0, 2: 180.0, 3: 240.0}
const TIER_BONUS := {1: 10, 2: 25, 3: 50}
## Strength column of 5.1 (the bot's camp strength) and kill_xp (fallback for previews while a .tres is missing).
const CREATURE_STRENGTH := {&"bristleback": 100.0, &"mirefang": 110.0, &"gloomcap_elder": 220.0,
		&"gloomcap_sprout": 50.0, &"hollow_stag": 700.0}
const CREATURE_KILL_XP := {&"bristleback": 25, &"mirefang": 30, &"gloomcap_elder": 50, &"gloomcap_sprout": 12,
		&"hollow_stag": 160}
const CREATURE_ABILITIES := {&"gloomcap_elder": [&"spore_burst"], &"hollow_stag": [&"antler_sweep"]}
const AMPHIBIOUS: Array[StringName] = [&"mirefang"]
const ABILITIES_PATH := "res://scripts/units/creature_abilities.gd"

const RESPAWN_BLOCK_RADIUS := 16.0
const RESPAWN_RETRY := 5.0
const LEVEL_MAX := 3
const LEVEL_HP := 0.15
const LEVEL_DAMAGE := 0.10
const LEVEL_XP := 0.10
const LEVEL_BONUS := 0.10
const LEVEL_STRENGTH := 0.15
const UNDERDOG_XP := 1.25
const UNDERDOG_BONUS := 1.5
const RESET_HOME_RADIUS := 3.0
const RESET_DELAY := 4.0
const RESET_REGEN_PCT := 0.05      ## Of max HP per second.
const RESET_FULL_DELAY := 6.0

## Drop tables (5.3). The 10 "Base" components of items.md.
const DROP_COMPONENTS: Array[StringName] = [&"ember_shard", &"whetted_fang", &"ironbark_plate", &"wisp_lantern",
		&"duskglass", &"mana_thread", &"swiftsoles", &"bone_charm", &"cinder_ring", &"gloom_ink"]
const T1_DRAUGHT_CHANCE := 0.30
const T2_COMPONENT_CHANCE := 0.35
const T2_CONSUMABLE_CHANCE := 0.50
const T3_RARE_CHANCE := 0.40
const DRAUGHT := &"ember_draught"
const VIAL := &"dusk_vial"
const SCALE := &"warden_scale"
const ROOT := &"vital_root"

const MSG_CLEARED := "%s cleared: +%d essence"
const MSG_DROPPED := " + %s dropped"
const MSG_ENEMY_CLEARED := "The enemy cleared the %s"
const MSG_UNDERDOG := "Underdog bonus: +50 %% from the %s"
const MSG_STAGS := "The Hollow Stags roam the glades"
const MSG_SECONDS := 4.0

const DEFAULT_SEED := 1203
const PLAYER_TEAM := 0
const ENEMY_TEAM := 1

## Returns the match time in seconds. Unset: the parent's match_time(), else this node's age.
var match_time_source: Callable
## Seeded rng for the drop rolls (the skirmish may reseed it).
var rng := RandomNumberGenerator.new()
## Where creatures and dropped items are added (default: this manager's parent, the level).
var spawn_parent: Node
## Type overrides by creature id (tests, missions): id -> UnitType; a key with a null value counts as missing.
var creature_types: Dictionary = {}

var _age := 0.0
var _tick_left := 0.0
var _camps: Array[NeutralCamp] = []
var _cleared_counts := {PLAYER_TEAM: 0, ENEMY_TEAM: 0}
var _stags_announced := false
var _abilities_script: Script = null
var _abilities_checked := false


## The match's camp manager, or null (no camps on this map).
static func instance(tree: SceneTree) -> CampManager:
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("camp_manager"):
		var m := node as CampManager
		if m and not m.is_queued_for_deletion():
			return m
	return null


func _init() -> void:
	add_to_group("camp_manager")
	rng.seed = DEFAULT_SEED


func _ready() -> void:
	add_to_group("camp_manager")
	if not match_time_source.is_valid():
		var p := get_parent()
		if p and p.has_method(&"match_time"):
			match_time_source = Callable(p, &"match_time")


func _physics_process(delta: float) -> void:
	_age += delta
	_tick_left -= delta
	if _tick_left > 0.0:
		return
	_tick_left += TICK
	if _tick_left <= 0.0:
		_tick_left = TICK
	var now := match_time()
	for c in _camps:
		if is_instance_valid(c):
			c.tick(now, TICK)
	if not _stags_announced:
		_check_announcements()


# ---------------------------------------------------------------- public (contract)

## Creates one camp per spot `{id, name, kind, tier, pos, first_spawn}` (tier 0 / missing = the kind's tier).
func setup(spots: Array) -> void:
	for spot: Variant in spots:
		if spot is Dictionary:
			_add(spot as Dictionary)


## Adds one camp (missions). `tier` 0 = the kind's tier. Returns the NeutralCamp.
func add_camp(kind: StringName, id: StringName, camp_name: String, pos: Vector3, first_spawn: float = 0.0,
		tier: int = 0) -> Node3D:
	return _add({"id": id, "name": camp_name, "kind": kind, "tier": tier, "pos": pos, "first_spawn": first_spawn})


## Every camp (NeutralCamp nodes), in setup order.
func camps() -> Array:
	var out: Array = []
	for c in _camps:
		if is_instance_valid(c):
			out.append(c)
	return out


## The camp a creature belongs to, or null.
func camp_of(unit: Node) -> Node:
	if unit == null or not is_instance_valid(unit) or not unit.has_meta(NeutralCamp.CAMP_META):
		return null
	var c: Variant = unit.get_meta(NeutralCamp.CAMP_META)
	return c as Node if typeof(c) == TYPE_OBJECT and is_instance_valid(c) else null


## The team whose wizard is lower level (it gets the underdog bonus), -1 when equal or unknown.
func underdog_team() -> int:
	var p := wizard_level(PLAYER_TEAM)
	var e := wizard_level(ENEMY_TEAM)
	if p < 1 or e < 1 or p == e:
		return -1
	return PLAYER_TEAM if p < e else ENEMY_TEAM


# ---------------------------------------------------------------- public (extra)

## Seconds of match time (match_time_source, else the parent's match_time(), else this node's age).
func match_time() -> float:
	return float(match_time_source.call()) if match_time_source.is_valid() else _age


## The camp with this id, or null.
func camp(id: StringName) -> Node3D:
	for c in _camps:
		if is_instance_valid(c) and c.camp_id == id:
			return c
	return null


## Camps cleared by `team` so far (end screen `Camps cleared 9`).
func cleared_count(team: int) -> int:
	return int(_cleared_counts.get(team, 0))


## Level of `team`'s wizard (the level's `wizard_of(team)`, else the "heroes" / "enemy_heroes" nodes of that
## team); 0 when unknown.
func wizard_level(team: int) -> int:
	var w: Variant = null
	var level := get_parent()
	if level and level.has_method(&"wizard_of"):
		w = level.call(&"wizard_of", team)
	if typeof(w) != TYPE_OBJECT or not is_instance_valid(w):
		w = null
		for group: StringName in [&"heroes", &"enemy_heroes"]:
			for node in get_tree().get_nodes_in_group(group):
				var t: Variant = node.get(&"team")
				if t != null and int(t) == team:
					w = node
					break
			if w != null:
				break
	if w == null:
		return 0
	var lvl: Variant = (w as Object).get(&"level")
	return int(lvl) if lvl != null else 0


## The UnitType of a creature id: `creature_types` first, else data/units/<id>.tres; null when missing.
func creature_type(id: StringName) -> UnitType:
	if creature_types.has(id):
		return creature_types[id] as UnitType
	return UnitType.find(String(id))


## scripts/units/creature_abilities.gd once it exists, else null.
func abilities_script() -> Script:
	if not _abilities_checked:
		_abilities_checked = true
		if ResourceLoader.exists(ABILITIES_PATH):
			_abilities_script = load(ABILITIES_PATH) as Script
			if _abilities_script and not _abilities_script.can_instantiate():
				_abilities_script = null
	return _abilities_script


## One roll of a tier's drop table (5.3): item ids to put on the ground.
static func roll_drops(tier: int, r: RandomNumberGenerator) -> Array[StringName]:
	var out: Array[StringName] = []
	match tier:
		1:
			if r.randf() < T1_DRAUGHT_CHANCE:
				out.append(DRAUGHT)
		2:
			if r.randf() < T2_COMPONENT_CHANCE:
				out.append(DROP_COMPONENTS[r.randi_range(0, DROP_COMPONENTS.size() - 1)])
			elif r.randf() < T2_CONSUMABLE_CHANCE:
				out.append(DRAUGHT if r.randf() < 0.5 else VIAL)
		3:
			out.append(DROP_COMPONENTS[r.randi_range(0, DROP_COMPONENTS.size() - 1)])
			if r.randf() < T3_RARE_CHANCE:
				out.append(SCALE if r.randf() < 0.5 else ROOT)
	return out


## The drop part of the camp hover line (`35 % a component`).
static func drop_text(tier: int) -> String:
	match tier:
		1:
			return "30 % Ember Draught"
		2:
			return "35 % a component"
		3:
			return "a component · 40 % Warden Scale or Vital Root"
	return ""


# ---------------------------------------------------------------- internals

func _add(spot: Dictionary) -> NeutralCamp:
	var kind := StringName(str(spot.get("kind", "")))
	if not CAMP_KINDS.has(kind):
		push_warning("CampManager: unknown camp kind '%s' (%s), skipped" % [kind, spot.get("id", "")])
		return null
	var c := NeutralCamp.new()
	c.manager = self
	c.configure(spot)
	add_child(c, true)
	_camps.append(c)
	c.cleared.connect(_on_camp_cleared)
	return c


## Skirmish save (review W3-2): clears per team, the loot roll state and every camp (by camp id).
func save_world_state(ids: Dictionary) -> Dictionary:
	var camps_d := {}
	for c in _camps:
		if is_instance_valid(c):
			camps_d[String(c.camp_id)] = c.save_world_state(ids)
	return {"cleared": _cleared_counts.duplicate(), "stags_announced": _stags_announced, "seed": rng.seed,
			"rng": rng.state, "camps": camps_d}


## Puts the saved camps back after the units are rebuilt: every camp first lets go of the creatures it spawned in
## the fresh level, then each adopts its saved ones (no late camp spawns a second time, levels kept).
func load_world_state(d: Dictionary, nodes: Dictionary) -> void:
	var cleared: Dictionary = d.get("cleared", {})
	for t: Variant in cleared:
		_cleared_counts[int(t)] = int(cleared[t])
	_stags_announced = bool(d.get("stags_announced", _stags_announced))
	if d.has("seed"):
		rng.seed = int(d["seed"])
	if d.has("rng"):
		rng.state = int(d["rng"])
	var camps_d: Dictionary = d.get("camps", {})
	for c in _camps:
		if is_instance_valid(c):
			c.release_creatures()
	for c in _camps:
		if is_instance_valid(c) and camps_d.has(String(c.camp_id)):
			c.load_world_state(camps_d[String(c.camp_id)], nodes)


func _on_camp_cleared(c: Node3D, team: int, reward: Dictionary) -> void:
	if team == PLAYER_TEAM or team == ENEMY_TEAM:
		_cleared_counts[team] = cleared_count(team) + 1
	camp_cleared.emit(c, team, reward)
	_announce_clear(c as NeutralCamp, team, reward)


func _announce_clear(c: NeutralCamp, team: int, reward: Dictionary) -> void:
	if c == null or team < 0:
		return
	var local := _local_team()
	if team == local:
		var text := MSG_CLEARED % [c.display_name, int(reward.get(&"essence", 0))]
		var names: Array[String] = []
		for id: Variant in reward.get(&"items", []):
			var t := ItemDrops.item_type(StringName(str(id)))
			var n: Variant = t.get(&"display_name") if t else null
			names.append(str(n) if n != null and str(n) != "" else String(str(id)).capitalize())
		if not names.is_empty():
			text += MSG_DROPPED % " + ".join(names)
		if bool(reward.get(&"underdog", false)):
			text += "\n" + MSG_UNDERDOG % c.display_name
		_say(text, MSG_SECONDS)
	elif _local_sees(c.position):
		_say(MSG_ENEMY_CLEARED % c.display_name, MSG_SECONDS)


## The once-per-match stag announcement, at the first Hollow Stag spawn (3:30 in the skirmish).
func _check_announcements() -> void:
	if _stags_announced:
		return
	for c in _camps:
		if is_instance_valid(c) and c.kind == &"hollow_stag" and not c.is_cleared():
			_stags_announced = true
			_say(MSG_STAGS, MSG_SECONDS)
			return


func _local_team() -> int:
	var fog := FogOfWar.find()
	return fog.local_team if fog else PLAYER_TEAM


func _local_sees(pos: Vector3) -> bool:
	var fog := FogOfWar.find()
	return fog == null or fog.is_visible(fog.local_team, pos)


func _say(text: String, seconds: float) -> void:
	if not message.get_connections().is_empty():
		message.emit(text, seconds)
		return
	var level := get_parent()
	var hud: Variant = level.get(&"hud") if level else null
	if hud is Object and is_instance_valid(hud) and (hud as Object).has_method(&"show_message"):
		(hud as Object).call(&"show_message", text, seconds)
