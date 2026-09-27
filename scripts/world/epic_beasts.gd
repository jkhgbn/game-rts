class_name EpicBeasts
extends Node
## Epic beasts (docs/design/map-fill.md section 5.5, contract section 13, task 12.C11). One node per match in group
## "epic_beasts"; find it with `EpicBeasts.instance(tree)` (null when beasts are off). It owns the LAIRS and decides
## WHEN a beast appears and WHAT it leaves behind; the BeastBrain (res://scripts/ai/beast_brain.gd, 12.A3, loaded by
## path) does all the moving and fighting.
## - Lairs (`setup(lairs)` / `add_lair(...)`): {id, name, kind, center, radius, patrol, first_spawn, respawn}; kinds
##   &"tusker", &"roc", &"direwolf", &"grizzlemaw". One beast per lair, so at most 8 alive on Crown Hollow.
## - Schedule: the first spawn at `first_spawn` s of match time (6:30 / 7:30 / 8:30 / 10:00 on Crown Hollow); after a
##   death the next one `respawn` s later (600 / 720), delayed while any PLAYER / ENEMY unit is within BLOCK_RADIUS
##   (25 m) of the centre (retry every RETRY_DELAY = 5 s). First spawns are never delayed.
## - Variants: spawns 1, 3, 5... of a lair are variant A (0), spawns 2, 4... variant B (1). The UnitType is
##   KIND_TYPES[kind][variant] (data/units/<id>.tres, 12.C4); a missing .tres skips the spawn with a warning and
##   retries every 5 s. The model gets `set_variant(variant)`.
## - The beast: an ordinary Unit, team NEUTRAL, groups "units" + "beasts" (towers / keeps never shoot "beasts"), meta
##   &"lair_id" / &"beast_variant". A child "CreatureAbilities" (res://scripts/units/creature_abilities.gd, 12.C4,
##   load-guarded) gets `setup(beast, ABILITIES[type id])`, then a BeastBrain (a child of this node) gets
##   `setup(beast, lair_for_brain)` in the same frame (the lair dictionary + `leash`, `nest`, `variant`, patrol points
##   snapped to the navmesh).
## - Death: the normal kill XP / essence / champion loot happen in Unit / Wizard / EssenceBank. Here: the underdog
##   bonus (+25 % of the kill's XP when the killing team's wizard is a LOWER level than the other wizard: to that
##   wizard with the 20 m / 25 % share rule, and to the killing soldier or champion), the drop table on the ground
##   (DROP_TABLES; trophy ids only when `ItemType.find(id)` exists), the `reward` dictionary through `grant`
##   (REWARDS: empty today, step 15 adds food), the message, `beast_slain`.
## Messages (`message(text, seconds)`, the local team's view): the level may connect it to hud.show_message; if nothing
## is connected this node calls the parent's `hud.show_message` itself.
## Look (12.C8): each lair gets its dressing (LairArt, res://art/environment/lairs/, 12.V32; load-guarded, draw-only) as
## a child of this node at the lair centre, turned by `LairArt.yaw_for(id)`; `set_occupied(true)` on `beast_spawned`,
## `false` when the beast dies (`beast_slain`) or leaves the tree. Its `decor_clear_circles()` go to the map dressing's
## `clear_area` (MapDressingArt also clears them by itself). `lair_art(lair_id)` returns the node.

signal beast_spawned(beast: Node, lair_id: StringName, variant: int)
## `team` = the team of the killing blow (PLAYER / ENEMY; -1 when nobody); `drops` = the item ids put on the ground.
signal beast_slain(beast: Node, team: int, drops: Array)
## A line for the HUD message area (the local team's view).
signal message(text: String, seconds: float)

const KINDS: Array[StringName] = [&"tusker", &"roc", &"direwolf", &"grizzlemaw"]

## UnitType id per kind: [variant A, variant B] (contract section 13 "Beasts").
const KIND_TYPES := {
	&"tusker": [&"ironhide_tusker", &"old_scarback"],
	&"roc": [&"stormcrest_roc", &"duskwing_roc"],
	&"direwolf": [&"greymane_direwolf", &"moonpelt_direwolf"],
	&"grizzlemaw": [&"grizzlemaw", &"elder_grizzlemaw"],
}

## CreatureAbilities ids per beast type (map-fill.md 5.5). Variant differences in numbers live in CreatureAbilities.
const ABILITIES := {
	&"ironhide_tusker": [&"gore_charge", &"bristle_hide"],
	&"old_scarback": [&"gore_charge", &"bristle_hide"],
	&"stormcrest_roc": [&"gale_swoop", &"updraft"],
	&"duskwing_roc": [&"shrieking_dive", &"updraft"],
	&"greymane_direwolf": [&"pounce", &"hamstring"],
	&"moonpelt_direwolf": [&"pounce", &"hamstring"],
	&"grizzlemaw": [&"maul", &"rending_roar", &"enrage"],
	&"elder_grizzlemaw": [&"maul", &"rending_roar", &"enrage"],
}

## Fight strength per beast type (map-fill.md 5.5 "Strength (A / B)"), for the bot and the champions' danger checks.
const STRENGTH := {
	&"ironhide_tusker": 900.0, &"old_scarback": 1080.0,
	&"stormcrest_roc": 800.0, &"duskwing_roc": 800.0,
	&"greymane_direwolf": 700.0, &"moonpelt_direwolf": 780.0,
	&"grizzlemaw": 1300.0, &"elder_grizzlemaw": 1500.0,
}

## Names used in messages: [spawn line with %s = lair name, "slew ..." name]. Beasts keep their own names even when
## the .tres is missing (tests).
const NAMES := {
	&"ironhide_tusker": ["An Ironhide Tusker roams the %s", "the Ironhide Tusker"],
	&"old_scarback": ["Old Scarback, an alpha Tusker, roams the %s!", "Old Scarback"],
	&"stormcrest_roc": ["A Stormcrest Roc roams the %s", "the Stormcrest Roc"],
	&"duskwing_roc": ["A Duskwing Roc, a dark breed, roams the %s!", "the Duskwing Roc"],
	&"greymane_direwolf": ["A Greymane Direwolf roams the %s", "the Greymane Direwolf"],
	&"moonpelt_direwolf": ["A Moonpelt Direwolf, a silver breed, roams the %s!", "the Moonpelt Direwolf"],
	&"grizzlemaw": ["A Grizzlemaw roams the %s", "the Grizzlemaw"],
	&"elder_grizzlemaw": ["An Elder Grizzlemaw roams the %s!", "the Elder Grizzlemaw"],
}

## Drop tables (map-fill.md 5.5). Each row drops ONE random item of `items` with probability `chance`; `variant`
## -1 = both variants, 0 = A only, 1 = B only. `trophy` = [A id, B id], dropped only when the ItemType exists.
const DROP_TABLES := {
	&"tusker": {
		"rows": [
			{"items": [&"ironbark_plate", &"bone_charm", &"swiftsoles"], "chance": 1.0, "variant": -1},
			{"items": [&"vital_root"], "chance": 0.3, "variant": -1},
			{"items": [&"ironbark_plate", &"bone_charm", &"swiftsoles"], "chance": 1.0, "variant": 1},
		],
		"trophy": [&"ironhide_tusk", &"scarback_tusk"],
	},
	&"roc": {
		"rows": [
			{"items": [&"swiftsoles", &"cinder_ring", &"mana_thread"], "chance": 1.0, "variant": 0},
			{"items": [&"duskglass", &"gloom_ink", &"mana_thread"], "chance": 1.0, "variant": 1},
			{"items": [&"warden_scale"], "chance": 0.3, "variant": -1},
		],
		"trophy": [&"stormcrest_plume", &"duskwing_plume"],
	},
	&"direwolf": {
		"rows": [
			{"items": [&"whetted_fang", &"ember_shard", &"swiftsoles"], "chance": 1.0, "variant": -1},
			{"items": [&"vital_root"], "chance": 0.4, "variant": 1},
		],
		"trophy": [&"greymane_pelt", &"moonpelt_pelt"],
	},
	&"grizzlemaw": {
		"rows": [
			{"items": [&"ember_shard", &"ironbark_plate", &"bone_charm"], "chance": 1.0, "variant": -1},
			{"items": [&"warden_scale", &"vital_root"], "chance": 0.6, "variant": -1},
			{"items": [&"warden_scale"], "chance": 1.0, "variant": 1},
		],
		"trophy": [&"grizzlemaw_claw", &"elder_grizzlemaw_claw"],
	},
}

## The `reward` dictionary per kind, paid through `grant` at each kill: empty today; step 15 adds food
## (e.g. tusker {&"food": 40}, grizzlemaw {&"food": 60}).
const REWARDS := {&"tusker": {}, &"roc": {}, &"direwolf": {}, &"grizzlemaw": {}}

## Crown Hollow's lairs, player bank (map-fill.md 5.5); `default_lairs()` adds the point mirrors.
const DEFAULT_LAIRS := [
	{"id": &"lair_heath_w", "name": "West Heath", "mirror_id": &"lair_heath_e", "mirror_name": "East Heath",
		"kind": &"tusker", "center": Vector2(-53, 13), "radius": 4.0,
		"patrol": [Vector2(-53, 9), Vector2(-57, 13), Vector2(-52, 17), Vector2(-49, 13)],
		"first_spawn": 390.0, "respawn": 600.0},
	{"id": &"lair_crag_w", "name": "Colossus Crag", "mirror_id": &"lair_crag_e", "mirror_name": "Colossus Crag",
		"kind": &"roc", "center": Vector2(-53, -18), "radius": 5.0,
		"patrol": [Vector2(-53, -13), Vector2(-48, -18), Vector2(-53, -23), Vector2(-57, -21)],
		"first_spawn": 510.0, "respawn": 600.0},
	{"id": &"lair_hollow_w", "name": "Greymane Hollow", "mirror_id": &"lair_hollow_e", "mirror_name": "Greymane Hollow",
		"kind": &"direwolf", "center": Vector2(-56, -34), "radius": 4.0,
		"patrol": [Vector2(-57, -38), Vector2(-56, -30), Vector2(-53, -34)],
		"first_spawn": 450.0, "respawn": 600.0},
	{"id": &"lair_den_w", "name": "Old Wood Den", "mirror_id": &"lair_den_e", "mirror_name": "Old Wood Den",
		"kind": &"grizzlemaw", "center": Vector2(-26, -54), "radius": 5.0,
		"patrol": [Vector2(-26, -49), Vector2(-31, -54), Vector2(-26, -59), Vector2(-21, -54)],
		"first_spawn": 600.0, "respawn": 720.0},
]

const BLOCK_RADIUS := 25.0          ## Respawn delayed while a PLAYER / ENEMY unit is this close to the centre...
const RETRY_DELAY := 5.0            ## ...retried this often (also a missing .tres).
const LEASH_EXTRA := 10.0           ## Leash = territory radius + this, around the centre (handed to the brain).
const UNDERDOG_XP := 0.25           ## +25 % of the kill's XP for the lower-level wizard's team.
const TICK := 0.25                  ## Schedule checks per second: 4.
const DROP_RING := 1.2              ## Drops lie on a ring this wide around the body.
const NAV_SNAP := 4.0
const DEFAULT_SEED := 1255
const MESSAGE_SECONDS := 4.0

const LAIR_ART_PATH := "res://art/environment/lairs/lair_art.gd"
const _SIM := preload("res://scripts/core/sim_mode.gd")   # Bot Lab sim mode: no lair art (docs/plan/bot-lab.md)
const BRAIN_PATH := "res://scripts/ai/beast_brain.gd"
const ABILITIES_PATH := "res://scripts/units/creature_abilities.gd"
const BEAST_GROUP := &"beasts"
const LAIR_META := &"lair_id"
const VARIANT_META := &"beast_variant"

const PLAYER_TEAM := 0
const ENEMY_TEAM := 1
const NEUTRAL_TEAM := 2

## False: nothing spawns (a living beast stays). The level's `beasts_enabled == false` also stops spawns.
var enabled := true
## The team whose view the `message` lines take ("Your army..." vs "The enemy...").
var local_team := PLAYER_TEAM
## Returns the match time in seconds. Unset: the parent's match_time(), else this node's own age.
var match_time_source: Callable
## Seeded rng for the drop rolls (the skirmish may reseed it).
var rng := RandomNumberGenerator.new()
## Where beasts and drops are added (default: this node's parent, the level).
var spawn_parent: Node
## The reward per kind paid at each kill (a copy of REWARDS; step 15 or a mission may change it).
var rewards: Dictionary = REWARDS.duplicate(true)
## Hooks for tests and tools: UnitType per type id (default UnitType.find), the brain Script (default BRAIN_PATH),
## the abilities Script (default ABILITIES_PATH).
var unit_types: Dictionary = {}
var brain_script: Script
var abilities_script: Script
## Reward keys `grant` could not pay (unknown today: food...), kept for step 15: team -> {key: amount}.
var granted_totals: Dictionary = {}
## Reward keys `grant` paid: team -> {key: amount}.
var paid_totals: Dictionary = {}

var _age := 0.0
var _tick_left := 0.0
var _lairs: Array[Dictionary] = []      # {lair, spawns, beast, brain, next_at, retry_at, died_at, art}
var _warned: Dictionary = {}


## The match's EpicBeasts, or null (beasts off on this map).
static func instance(tree: SceneTree) -> EpicBeasts:
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("epic_beasts"):
		var e := node as EpicBeasts
		if e and not e.is_queued_for_deletion():
			return e
	return null


## Crown Hollow's 8 lairs (DEFAULT_LAIRS + their point mirrors) in the `setup` shape.
static func default_lairs() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for mirror: bool in [false, true]:
		for src: Dictionary in DEFAULT_LAIRS:
			var s := -1.0 if mirror else 1.0
			var c: Vector2 = src["center"] * s
			var patrol := PackedVector3Array()
			for p: Vector2 in src["patrol"]:
				patrol.append(Vector3(p.x * s, 0.0, p.y * s))
			out.append({"id": src["mirror_id"] if mirror else src["id"],
					"name": src["mirror_name"] if mirror else src["name"], "kind": src["kind"],
					"center": Vector3(c.x, 0.0, c.y), "radius": src["radius"], "patrol": patrol,
					"first_spawn": src["first_spawn"], "respawn": src["respawn"]})
	return out


func _init() -> void:
	add_to_group("epic_beasts")
	rng.seed = DEFAULT_SEED


func _ready() -> void:
	add_to_group("epic_beasts")
	if not match_time_source.is_valid():
		var p := get_parent()
		if p and p.has_method(&"match_time"):
			match_time_source = Callable(p, &"match_time")
	for st in _lairs:
		_build_lair_art(st)


func _physics_process(delta: float) -> void:
	_age += delta
	_tick_left -= delta
	if _tick_left > 0.0:
		return
	_tick_left = TICK
	if not spawns_allowed():
		return
	var now := match_time()
	for st in _lairs:
		if _beast_alive(st):
			continue
		if now < float(st["next_at"]) or now < float(st["retry_at"]):
			continue
		_try_spawn(st, now)


# ---------------------------------------------------------------- public

## Replaces every lair (living beasts of removed lairs are freed). Each: {id, name, kind, center (Vector3 or
## Vector2 x/z), radius, patrol (PackedVector3Array or Array of Vector3 / Vector2), first_spawn, respawn}.
func setup(lairs: Array) -> void:
	for st in _lairs:
		_despawn(st)
		_free_lair_art(st)
	_lairs.clear()
	for l: Variant in lairs:
		if l is Dictionary:
			var d: Dictionary = l
			add_lair(StringName(str(d.get("id", ""))), str(d.get("name", "")), StringName(str(d.get("kind", ""))),
					_v3(d.get("center", Vector3.ZERO)), float(d.get("radius", 5.0)), _patrol_of(d.get("patrol", [])),
					float(d.get("first_spawn", 0.0)), float(d.get("respawn", 600.0)))


## Adds one lair (missions: "a lone Grizzlemaw makes a good optional mission boss"). Returns the lair dictionary, or
## {} when the id is taken or the kind unknown.
func add_lair(id: StringName, display_name: String, kind: StringName, center: Vector3, radius: float = 5.0,
		patrol: PackedVector3Array = PackedVector3Array(), first_spawn: float = 0.0, respawn: float = 600.0) -> Dictionary:
	if not KIND_TYPES.has(kind):
		push_warning("EpicBeasts: unknown beast kind '%s' for lair '%s'" % [kind, id])
		return {}
	if id == &"" or _state(id) != null:
		push_warning("EpicBeasts: lair id '%s' is empty or already used" % id)
		return {}
	var c := Vector3(center.x, 0.0, center.z)
	if patrol.is_empty():
		patrol.append(c)
	var lair := {"id": id, "name": display_name if display_name != "" else String(id), "kind": kind, "center": c,
			"radius": radius, "patrol": patrol, "first_spawn": first_spawn, "respawn": respawn}
	var st := {"lair": lair, "spawns": 0, "beast": null, "brain": null, "next_at": first_spawn,
			"retry_at": 0.0, "died_at": -1.0, "art": null}
	_lairs.append(st)
	if is_inside_tree():
		_build_lair_art(st)
	return lair.duplicate()


## Every lair dictionary (copies), in setup order.
func lairs() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for st in _lairs:
		out.append((st["lair"] as Dictionary).duplicate())
	return out


## The living beasts.
func beasts() -> Array:
	var out: Array = []
	for st in _lairs:
		if _beast_alive(st):
			out.append(st["beast"])
	return out


## The living beast of a lair, or null.
func beast_of(lair_id: StringName) -> Node:
	var st: Variant = _state(lair_id)
	return st["beast"] if st != null and _beast_alive(st) else null


## The lair's dressing (LairArt), or null (unknown lair, or no art).
func lair_art(lair_id: StringName) -> Node3D:
	var st: Variant = _state(lair_id)
	if st == null:
		return null
	var art: Variant = st["art"]
	return art as Node3D if art != null and is_instance_valid(art) else null


## The lair of a beast (a copy), or {} when `beast` is not one of ours.
func lair_of(beast: Node) -> Dictionary:
	if beast == null or not is_instance_valid(beast):
		return {}
	for st in _lairs:
		if st["beast"] == beast:
			return (st["lair"] as Dictionary).duplicate()
	if beast.has_meta(LAIR_META):
		var st: Variant = _state(StringName(str(beast.get_meta(LAIR_META))))
		if st != null:
			return (st["lair"] as Dictionary).duplicate()
	return {}


## How many beasts this lair has spawned so far (0 before its first spawn).
func spawn_count(lair_id: StringName) -> int:
	var st: Variant = _state(lair_id)
	return int(st["spawns"]) if st != null else 0


## The variant (0 = A, 1 = B) of the lair's living beast, else of its next spawn. -1 for an unknown lair.
func variant_of(lair_id: StringName) -> int:
	var st: Variant = _state(lair_id)
	if st == null:
		return -1
	if _beast_alive(st):
		return _variant_for_spawn(int(st["spawns"]))
	return _variant_for_spawn(int(st["spawns"]) + 1)


## Seconds until the lair's next spawn (first spawn or respawn); 0 while its beast lives or when the spawn is due
## and waits (blocked by nearby units / a missing .tres). -1 for an unknown lair.
func respawn_left(lair_id: StringName) -> float:
	var st: Variant = _state(lair_id)
	if st == null:
		return -1.0
	if _beast_alive(st):
		return 0.0
	return maxf(0.0, float(st["next_at"]) - match_time())


## Fight strength of a beast (STRENGTH by its type: 700-1500), 0 for anything else.
func strength_of(beast: Node) -> float:
	if beast == null or not is_instance_valid(beast):
		return 0.0
	var type: Variant = beast.get(&"unit_type")
	if type is Resource:
		return float(STRENGTH.get(StringName(str((type as Resource).get(&"id"))), 0.0))
	return 0.0


## The kind (&"tusker"...) of a beast, or &"".
func kind_of(beast: Node) -> StringName:
	var lair := lair_of(beast)
	return lair.get("kind", &"")


## Pays `reward` to `team` (same shape as CritterHerds.grant): every key it knows is paid now (&"essence" through
## EssenceBank, &"crystals" through Economy, &"gold" through GoldBank) and summed in `paid_totals`; unknown keys
## (step 15: &"food"...) and keys whose bank is missing are kept in `granted_totals[team]`. `by` = the killer.
func grant(team: int, reward: Dictionary, by: Node) -> void:
	if team != PLAYER_TEAM and team != ENEMY_TEAM:
		return
	for key: Variant in reward:
		var k := StringName(str(key))
		var amount: Variant = reward[key]
		if not (amount is int or amount is float) or float(amount) == 0.0:
			continue
		if _pay(team, k, int(round(float(amount))), by):
			_add_total(paid_totals, team, k, float(amount))
		else:
			_add_total(granted_totals, team, k, float(amount))


## True when beasts may spawn now: `enabled` and the level's `beasts_enabled` is not false.
func spawns_allowed() -> bool:
	if not enabled:
		return false
	var p := get_parent()
	if p != null:
		var flag: Variant = p.get(&"beasts_enabled")
		if flag is bool and not flag:
			return false
	return true


## Seconds of match time (match_time_source, else the parent's match_time(), else this node's age).
func match_time() -> float:
	return float(match_time_source.call()) if match_time_source.is_valid() else _age


## Spawns the lair's next beast right now, ignoring the schedule and the block (missions, tests). Returns the beast,
## or null (unknown lair, a beast still alive, no .tres).
func spawn_now(lair_id: StringName) -> Node:
	var st: Variant = _state(lair_id)
	if st == null or _beast_alive(st):
		return null
	return _spawn(st)


## The team whose wizard is the lower level (-1 when equal or a wizard is missing): it gets the +25 % XP.
func underdog_team() -> int:
	var lp := _wizard_level(PLAYER_TEAM)
	var le := _wizard_level(ENEMY_TEAM)
	if lp < 0 or le < 0 or lp == le:
		return -1
	return PLAYER_TEAM if lp < le else ENEMY_TEAM


# ---------------------------------------------------------------- schedule

func _try_spawn(st: Dictionary, now: float) -> void:
	# Respawns (not first spawns) wait while a PLAYER / ENEMY unit is near the centre.
	if int(st["spawns"]) > 0 and _blocked((st["lair"] as Dictionary)["center"]):
		st["retry_at"] = now + RETRY_DELAY
		return
	if _spawn(st) == null:
		st["retry_at"] = now + RETRY_DELAY


func _spawn(st: Dictionary) -> Node:
	var lair: Dictionary = st["lair"]
	var variant := _variant_for_spawn(int(st["spawns"]) + 1)
	var type_id: StringName = (KIND_TYPES[lair["kind"]] as Array)[variant]
	var type := _type(type_id)
	if type == null:
		return null
	var beast := Worker.make_unit(type)
	if beast == null:
		return null
	beast.team = NEUTRAL_TEAM as Unit.Team
	beast.name = "Beast_%s" % String(type_id)
	beast.add_to_group(BEAST_GROUP)
	beast.set_meta(LAIR_META, lair["id"])
	beast.set_meta(VARIANT_META, variant)
	var parent := spawn_parent if spawn_parent != null and is_instance_valid(spawn_parent) else get_parent()
	if parent == null:
		beast.free()
		return null
	parent.add_child(beast, true)
	beast.global_position = _snap(lair["center"])
	beast.command_stop()
	beast.model_call(&"set_variant", [variant])
	st["spawns"] = int(st["spawns"]) + 1
	st["beast"] = beast
	st["died_at"] = -1.0
	beast.died.connect(_on_beast_died.bind(lair["id"]), CONNECT_ONE_SHOT)
	beast.tree_exiting.connect(_on_beast_exiting.bind(lair["id"], beast), CONNECT_ONE_SHOT)
	_add_abilities(beast, type_id)
	st["brain"] = _add_brain(beast, lair, variant)
	_vfx(&"beast_spawn", lair["center"], beast)
	var names: Array = NAMES.get(type_id, ["A beast roams the %s", "the beast"])
	_say(str(names[0]) % str(lair["name"]))
	_set_lair_occupied(st, true)
	beast_spawned.emit(beast, lair["id"], variant)
	return beast


func _add_abilities(beast: Unit, type_id: StringName) -> void:
	if beast.get_node_or_null(^"CreatureAbilities") != null:
		return
	var script := abilities_script
	if script == null and ResourceLoader.exists(ABILITIES_PATH):
		script = load(ABILITIES_PATH) as Script
	if script == null or not script.can_instantiate():
		_warn_once("abilities", "EpicBeasts: no CreatureAbilities (%s) yet, beasts fight without abilities" % ABILITIES_PATH)
		return
	var node := script.new() as Node
	if node == null:
		return
	node.name = "CreatureAbilities"
	beast.add_child(node)
	var ids: Array[StringName] = []
	for id: Variant in ABILITIES.get(type_id, []):
		ids.append(StringName(str(id)))
	if node.has_method(&"setup"):
		node.call(&"setup", beast, ids)


func _add_brain(beast: Unit, lair: Dictionary, variant: int) -> Node:
	var script := brain_script
	if script == null and ResourceLoader.exists(BRAIN_PATH):
		script = load(BRAIN_PATH) as Script
	if script == null or not script.can_instantiate():
		_warn_once("brain", "EpicBeasts: no BeastBrain (%s) yet, beasts stand at their lairs" % BRAIN_PATH)
		return null
	var brain := script.new() as Node
	if brain == null:
		return null
	brain.name = "BeastBrain_%s" % String(lair["id"])
	add_child(brain, true)
	if brain.has_method(&"setup"):
		brain.call(&"setup", beast, _lair_for_brain(lair, variant))
	return brain


## The lair as the brain gets it: + `leash` (radius + 10), `nest` (the centre: the Roc's Updraft goal), `variant`,
## and the patrol points snapped to the navmesh.
func _lair_for_brain(lair: Dictionary, variant: int) -> Dictionary:
	var d := lair.duplicate()
	var patrol := PackedVector3Array()
	for p: Vector3 in lair["patrol"]:
		patrol.append(_snap(p))
	d["patrol"] = patrol
	d["leash"] = float(lair["radius"]) + LEASH_EXTRA
	d["nest"] = _snap(lair["center"])
	d["variant"] = variant
	return d


func _on_beast_died(beast: Unit, lair_id: StringName) -> void:
	var st: Variant = _state(lair_id)
	if st == null:
		return
	var lair: Dictionary = st["lair"]
	var now := match_time()
	st["died_at"] = now
	st["next_at"] = now + float(lair["respawn"])
	st["retry_at"] = 0.0
	_free_brain(st)
	_set_lair_occupied(st, false)
	var team := EssenceBank.killer_team_of(beast)
	if team != PLAYER_TEAM and team != ENEMY_TEAM:
		beast_slain.emit(beast, -1, [])
		return
	var variant := int(beast.get_meta(VARIANT_META, 0))
	var kind: StringName = lair["kind"]
	var underdog := _award_underdog(beast, team)
	var drops := _drop_items(kind, variant, beast.global_position)
	grant(team, rewards.get(kind, {}), beast.killer)
	_say(_slain_text(beast, team, drops, underdog))
	beast_slain.emit(beast, team, drops)


func _on_beast_exiting(lair_id: StringName, beast: Node) -> void:
	var st: Variant = _state(lair_id)
	if st == null or st["beast"] != beast:
		return
	# Removed without dying (a test, a mission): the respawn counts from now.
	if float(st["died_at"]) < 0.0 and beast is Unit and (beast as Unit).is_alive():
		st["next_at"] = match_time() + float((st["lair"] as Dictionary)["respawn"])
		_free_brain(st)
	st["beast"] = null
	_set_lair_occupied(st, false)


func _despawn(st: Dictionary) -> void:
	_free_brain(st)
	var b: Variant = st["beast"]
	st["beast"] = null
	if b != null and is_instance_valid(b) and not (b as Node).is_queued_for_deletion():
		(b as Node).queue_free()


func _free_brain(st: Dictionary) -> void:
	var brain: Variant = st["brain"]
	st["brain"] = null
	if brain != null and is_instance_valid(brain) and not (brain as Node).is_queued_for_deletion():
		(brain as Node).queue_free()


# ---------------------------------------------------------------- rewards

## +25 % of the kill's XP for the underdog team (map-fill.md 5.3 / 5.5): its wizard (20 m full / 25 % share like
## Wizard.credit_kill) and the killing soldier or champion. Returns true when paid.
func _award_underdog(beast: Unit, team: int) -> bool:
	if underdog_team() != team:
		return false
	var extra := roundi(float(Unit.kill_xp_value(beast)) * UNDERDOG_XP)
	if extra <= 0:
		return false
	var wizard := _wizard_of(team)
	if wizard != null and wizard.has_method(&"add_xp"):
		var amount := extra
		var alive: bool = not wizard.has_method(&"is_alive") or bool(wizard.call(&"is_alive"))
		if not alive or _flat_d(wizard.global_position, beast.global_position) > Wizard.XP_FULL_SHARE_RANGE:
			amount = maxi(1, roundi(extra * Wizard.XP_FAR_SHARE))
		wizard.call(&"add_xp", amount)
	var killer: Variant = beast.killer
	if killer is Unit and is_instance_valid(killer) and killer != wizard:
		var k := killer as Unit
		if int(k.team) == team and k.is_alive() and k.can_gain_veterancy():
			k.add_xp(extra)
	return true


## Rolls the kind's table for `variant` and puts the items on the ground around `at`. Returns the dropped ids.
func _drop_items(kind: StringName, variant: int, at: Vector3) -> Array:
	var ids := roll_drops(kind, variant)
	var parent := spawn_parent if spawn_parent != null and is_instance_valid(spawn_parent) else get_parent()
	for i in ids.size():
		var type := ItemType.find(ids[i])
		if type == null or parent == null:
			continue
		var a := TAU * float(i) / float(maxi(1, ids.size()))
		ItemPickup.spawn(type, at + Vector3(cos(a), 0.0, sin(a)) * DROP_RING, 1, parent)
	return ids


## One roll of a drop table (no side effect besides the rng): item ids that exist (`ItemType.find`), trophy last.
func roll_drops(kind: StringName, variant: int) -> Array:
	var out: Array = []
	var table: Dictionary = DROP_TABLES.get(kind, {})
	for row: Dictionary in table.get("rows", []):
		var v := int(row.get("variant", -1))
		if v >= 0 and v != variant:
			continue
		var chance := float(row.get("chance", 1.0))
		if chance < 1.0 and rng.randf() >= chance:
			continue
		var pool: Array = []
		for id: Variant in row.get("items", []):
			if ItemType.find(StringName(str(id))) != null:
				pool.append(StringName(str(id)))
		if not pool.is_empty():
			out.append(pool[rng.randi_range(0, pool.size() - 1)])
	var trophy: Array = table.get("trophy", [])
	if variant >= 0 and variant < trophy.size():
		var tid := StringName(str(trophy[variant]))
		if ItemType.find(tid) != null:
			out.append(tid)
	return out


func _pay(team: int, key: StringName, amount: int, _by: Node) -> bool:
	match key:
		&"essence":
			var bank := EssenceBank.for_team(team)
			if bank:
				bank.add(amount)
				return true
		&"crystals":
			var eco := Economy.for_team(team)
			if eco:
				eco.add(amount)
				return true
		&"gold":
			var gold := GoldBank.for_team(team)
			if gold:
				gold.add(amount, &"loot")
				return true
	return false


static func _add_total(totals: Dictionary, team: int, key: StringName, amount: float) -> void:
	var t: Dictionary = totals.get(team, {})
	t[key] = float(t.get(key, 0.0)) + amount
	totals[team] = t


func _slain_text(beast: Unit, team: int, drops: Array, underdog: bool) -> String:
	var type_id := StringName(str(beast.unit_type.id)) if beast.unit_type else &""
	var names: Array = NAMES.get(type_id, ["", "the beast"])
	var who := str(names[1])
	if team != local_team:
		return "The enemy slew %s" % who
	var text := "Your army slew %s" % who
	if not drops.is_empty():
		var parts: Array[String] = []
		for id: Variant in drops:
			var it := ItemType.find(StringName(str(id)))
			parts.append(it.display_name if it and it.display_name != "" else String(id))
		text += " + %s dropped" % ", ".join(parts)
	if underdog:
		text += " (underdog bonus: +25 % XP)"
	return text


# ---------------------------------------------------------------- helpers

func _state(lair_id: StringName) -> Variant:
	for st in _lairs:
		if (st["lair"] as Dictionary)["id"] == lair_id:
			return st
	return null


static func _variant_for_spawn(n: int) -> int:
	return 0 if n % 2 == 1 else 1


func _beast_alive(st: Dictionary) -> bool:
	var b: Variant = st["beast"]
	if b == null or not is_instance_valid(b) or (b as Node).is_queued_for_deletion():
		return false
	return not (b is Unit) or (b as Unit).is_alive()


func _blocked(center: Vector3) -> bool:
	if not is_inside_tree():
		return false
	for node in get_tree().get_nodes_in_group("units"):
		var u := node as Unit
		if u == null or not u.is_alive():
			continue
		if int(u.team) != PLAYER_TEAM and int(u.team) != ENEMY_TEAM:
			continue
		if _flat_d(u.global_position, center) < BLOCK_RADIUS:
			return true
	return false


func _type(type_id: StringName) -> UnitType:
	var t: Variant = unit_types.get(type_id)
	if t is UnitType:
		return t
	var found := UnitType.find(String(type_id))
	if found == null:
		_warn_once("type:" + String(type_id),
				"EpicBeasts: no data/units/%s.tres yet, that beast does not spawn" % String(type_id))
	return found


## The wizard of `team` (groups "heroes" / "enemy_heroes"), or null.
func _wizard_of(team: int) -> Node3D:
	if not is_inside_tree():
		return null
	for group: StringName in [&"heroes", &"enemy_heroes"]:
		for node in get_tree().get_nodes_in_group(group):
			if node is Node3D and is_instance_valid(node) and node.get(&"team") != null and int(node.get(&"team")) == team:
				return node
	return null


func _wizard_level(team: int) -> int:
	var w := _wizard_of(team)
	if w == null:
		return -1
	var lvl: Variant = w.get(&"level")
	return int(lvl) if lvl != null else 1


static func _v3(v: Variant) -> Vector3:
	if v is Vector3:
		return v
	if v is Vector2:
		return Vector3((v as Vector2).x, 0.0, (v as Vector2).y)
	return Vector3.ZERO


static func _patrol_of(v: Variant) -> PackedVector3Array:
	var out := PackedVector3Array()
	if v is PackedVector3Array:
		return v
	if v is Array or v is PackedVector2Array:
		for p: Variant in v:
			if p is Vector3 or p is Vector2:
				out.append(_v3(p))
	return out


static func _flat_d(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## `p` moved onto the navmesh when a navmesh point is within NAV_SNAP.
func _snap(p: Vector3) -> Vector3:
	if not is_inside_tree() or get_viewport() == null:
		return p
	var map := get_viewport().find_world_3d().navigation_map
	if not map.is_valid() or NavigationServer3D.map_get_iteration_id(map) == 0:
		return p
	var q := NavigationServer3D.map_get_closest_point(map, p)
	if Vector2(q.x - p.x, q.z - p.z).length() <= NAV_SNAP:
		return Vector3(q.x, p.y, q.z)
	return p


## The lair's dressing (LairArt scene by lair id, else by kind) as a child of this node, at the centre, yaw 0 / PI.
func _build_lair_art(st: Dictionary) -> void:
	var art: Variant = st.get("art")
	if art != null and is_instance_valid(art):
		return
	if not ResourceLoader.exists(LAIR_ART_PATH) or _SIM.enabled:
		return
	var lair_script := load(LAIR_ART_PATH) as Script
	if lair_script == null:
		return
	var lair: Dictionary = st["lair"]
	var path := str(lair_script.call(&"scene_path_for", lair["id"], lair["kind"]))
	if path == "" or not ResourceLoader.exists(path):
		return
	var scene := load(path) as PackedScene
	var node := scene.instantiate() as Node3D if scene else null
	if node == null:
		return
	node.name = "Lair_%s" % String(lair["id"])
	var c: Vector3 = lair["center"]
	node.transform = Transform3D(Basis(Vector3.UP, float(lair_script.call(&"yaw_for", lair["id"]))),
			Vector3(c.x, 0.0, c.z))
	add_child(node)
	st["art"] = node
	_set_lair_occupied(st, _beast_alive(st))
	_clear_decor.call_deferred(node)


func _free_lair_art(st: Dictionary) -> void:
	var art: Variant = st.get("art")
	st["art"] = null
	if art != null and is_instance_valid(art) and not (art as Node).is_queued_for_deletion():
		(art as Node).queue_free()


func _set_lair_occupied(st: Dictionary, occupied: bool) -> void:
	var art: Variant = st.get("art")
	if art != null and is_instance_valid(art) and (art as Node).has_method(&"set_occupied"):
		(art as Node).call(&"set_occupied", occupied)


## The lair's decor-free circles to the level's map dressing (MapDressingArt.clear_area; it also does it itself).
func _clear_decor(art: Node) -> void:
	if not is_instance_valid(art) or not art.has_method(&"decor_clear_circles") or not is_inside_tree():
		return
	var level := get_parent()
	if level == null:
		return
	for n: Node in level.get_children():
		if n.has_method(&"clear_area") and n.has_method(&"decor_count"):
			for circle: Vector3 in (art.call(&"decor_clear_circles") as PackedVector3Array):
				n.call(&"clear_area", Vector3(circle.x, 0.0, circle.y), circle.z)


func _vfx(id: StringName, at: Vector3, target: Node) -> void:
	if not is_inside_tree():
		return
	var vfx := get_tree().get_first_node_in_group(&"mapfill_vfx")
	if vfx and vfx.has_method(&"play"):
		vfx.call(&"play", id, at, target)


func _warn_once(key: String, text: String) -> void:
	if not _warned.has(key):
		_warned[key] = true
		push_warning(text)


func _say(text: String) -> void:
	if text == "":
		return
	if not message.get_connections().is_empty():
		message.emit(text, MESSAGE_SECONDS)
		return
	var level := get_parent()
	var hud: Variant = level.get(&"hud") if level else null
	if hud is Object and is_instance_valid(hud) and (hud as Object).has_method(&"show_message"):
		(hud as Object).call(&"show_message", text, MESSAGE_SECONDS)
