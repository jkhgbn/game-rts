class_name ForgeKit
extends Node
## The Forge's research (docs/design/unit-upgrades.md; JS 2026-10-06 "an upgrade building where you upgrade units" +
## "also some UNIT-SPECIFIC upgrades"). Static side: the research lines, the card stubs (UnitType stand-ins the Forge
## queues like units), apply_to (modifier `forge` + the range meta), the bot. Instance side: one node per team (group
## "forge_upgrades") holding the levels; it applies them to every living soldier when a level lands and to every new one
## (SceneTree.node_added, end of frame). The Unit Lab never creates one: its fights run at level 0.
## The whole feature hangs on ENABLED.
## 2026-10-14 (unit-upgrades.md 7, UR.S2): the 12 unit-specific lines (V B N) moved to UnitResearch (same ids and
## numbers, researched at the building that trains the unit); the Forge card keeps Z X C. An old save's moved line
## (set_level, a queued stub) maps to UnitResearch: a level loads as the granted row, a queued one is refunded.

signal research_completed(line: StringName, level: int)

## THE switch: false = no Forge in the build menu, no research, bots never build one.
const ENABLED := true
const FORGE_IDS := {
	&"fire": &"fire_forge", &"shadow": &"shadow_forge", &"ice": &"ice_forge", &"nature": &"nature_forge",
}
const MODIFIER := &"forge"
const RANGE_META := &"_forge_range"
const SIG_META := &"_forge_sig"
const STUB_PREFIX := "forge_"
const SKIRMISH_SCRIPT := "res://scripts/world/skirmish.gd"

## Generic lines (3 levels): price / time / keep tier per level.
const LEVEL_PRICE: Array[int] = [100, 150, 200]
const LEVEL_TIME: Array[float] = [35.0, 45.0, 55.0]
const LEVEL_TIER: Array[int] = [1, 2, 3]
## The moved unit-specific lines (UnitResearch rows with "forge": true; old saves, Unit Guide until UR.U2).
const UNIT_PRICE := 125
const UNIT_TIME := 40.0
const UNIT_TIER := 2

## Generic lines: stats are per level. Weapons / Armor for every kingdom, then each kingdom's own line.
const LINES := {
	&"weapons": {"name": "Weapons", "stats": {&"attack_damage_pct": 0.06}, "text": "+6 % attack damage"},
	&"armor": {"name": "Armor", "stats": {&"armor": 6.0}, "text": "+6 armor"},
	&"fire_fury": {"name": "Kindled Fury", "stats": {&"attack_cooldown_pct": -0.04}, "text": "+4 % attack speed"},
	&"shadow_shroud": {"name": "Shroudstep", "stats": {&"move_speed_pct": 0.04}, "text": "+4 % move speed"},
	&"ice_hide": {"name": "Rimeforged Hide", "stats": {&"max_hp_pct": 0.05}, "text": "+5 % max HP"},
	&"nature_sap": {"name": "Sapblood", "stats": {&"hp_regen": 0.25}, "text": "+0.25 HP regeneration per second"},
}
const KINGDOM_LINE := {
	&"fire": &"fire_fury", &"shadow": &"shadow_shroud", &"ice": &"ice_hide", &"nature": &"nature_sap",
}
## Card order (keys Z X C) per kingdom.
const CARD := {
	&"fire": [&"weapons", &"armor", &"fire_fury"],
	&"shadow": [&"weapons", &"armor", &"shadow_shroud"],
	&"ice": [&"weapons", &"armor", &"ice_hide"],
	&"nature": [&"weapons", &"armor", &"nature_sap"],
}

## Research tooltips (logic text, shown through Loc.sink: printf msgids in game_logic.po).
const CARD_TEXT_LEVEL := "Level %d of %d: %s per level for every soldier of your kingdom."
const CARD_TEXT_UNIT := "%s for every %s, living and future."
const REASON_MAX := "Max level"
const REASON_WORKING := "Already in progress"

## Bot (unit-upgrades.md 4), by difficulty 0 easy / 1 normal / 2 hard.
const BOT_BUILD_AT := {0: 540.0, 1: 390.0, 2: 300.0}
const BOT_MAX_LEVEL := {0: 1, 1: 2, 2: 3}
const BOT_RESERVE := {0: 300, 1: 200, 2: 150}
const BOT_EVERY := 8.0
## After a failed Forge spot search (17 x 17 placement checks), the bot waits this long before searching again
## (review 2026-10-08 L7).
const BOT_SPOT_BACKOFF := 60.0

## Tests may set this true (the build menu lists the Forge only in a skirmish-type game otherwise).
static var force_enabled := false
static var _stubs: Dictionary = {}     # "line:level" -> stub UnitType
static var _bot_next: Dictionary = {}  # team -> next bot check (match s)
static var _bot_spot_failed: Dictionary = {}  # team -> match s of the last failed Forge spot search

var team := 0
var levels: Dictionary = {}   ## line id -> level done (read only; set_level / complete change it).
var _pending: Array = []
var _flush_queued := false


# ---------------------------------------------------------------- static: game / lines

## True when the current game has the Forge: a scene whose script inherits skirmish.gd (layout maps too), never a
## mission (MissionBase: define_objectives) nor Wave Strike; or force_enabled.
static func enabled_here() -> bool:
	if not ENABLED:
		return false
	if force_enabled:
		return true
	var tree := Engine.get_main_loop() as SceneTree
	return tree != null and enabled_for(tree.current_scene)


## The rule of enabled_here for a level node (tests call it on scenes outside the tree).
static func enabled_for(scene: Node) -> bool:
	if scene == null or not ENABLED:
		return false
	if scene.has_method(&"define_objectives"):   # a mission: its forge_enabled knob (MissionConfig, e2m4)
		return &"forge_enabled" in scene and bool(scene.get(&"forge_enabled"))
	var s := scene.get_script() as Script
	while s != null:
		if s.resource_path == SKIRMISH_SCRIPT:
			return true
		s = s.get_base_script()
	return false


static func forge_type(faction: StringName) -> BuildingType:
	var id: Variant = FORGE_IDS.get(faction)
	return BuildingType.find(String(id)) if id != null else null


static func card_lines(faction: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for l: StringName in CARD.get(faction, []):
		out.append(l)
	return out


## True for a line that moved to UnitResearch (UR.S2; same id).
static func is_unit_line(line: StringName) -> bool:
	return bool(UnitResearch.row(line).get("forge", false))


static func line_data(line: StringName) -> Dictionary:
	return UnitResearch.row(line) if is_unit_line(line) else LINES.get(line, {})


static func max_level(line: StringName) -> int:
	return 1 if is_unit_line(line) else (LEVEL_PRICE.size() if LINES.has(line) else 0)


static func line_name(line: StringName) -> String:
	return str(line_data(line).get("name", String(line).capitalize()))


## Effect of ONE level ("+6 % attack damage").
static func line_text(line: StringName) -> String:
	return str(line_data(line).get("text", ""))


static func price_of(line: StringName, level: int) -> int:
	return UNIT_PRICE if is_unit_line(line) else LEVEL_PRICE[clampi(level - 1, 0, LEVEL_PRICE.size() - 1)]


static func time_of(line: StringName, level: int) -> float:
	return UNIT_TIME if is_unit_line(line) else LEVEL_TIME[clampi(level - 1, 0, LEVEL_TIME.size() - 1)]


static func tier_of(line: StringName, level: int) -> int:
	return UNIT_TIER if is_unit_line(line) else LEVEL_TIER[clampi(level - 1, 0, LEVEL_TIER.size() - 1)]


## The unit-specific line of a unit id (&"" = none) in the kingdom of `faction` (&"" = any kingdom).
## (Moved lines: UnitResearch rows with "forge": true, ids start with the kingdom.)
static func unit_line_of(unit_id: StringName, faction: StringName = &"") -> StringName:
	for line in UnitResearch.rows_for_unit(unit_id):
		if not is_unit_line(line):
			continue
		if faction != &"" and not String(line).begins_with(String(faction) + "_"):
			continue
		return line
	return &""


## "Ember Archer, Scorchbow" for a unit line (display names from the data).
static func units_text(line: StringName) -> String:
	var names: PackedStringArray = []
	for uid: StringName in line_data(line).get("units", []):
		var t := UnitType.find(String(uid))
		names.append(t.display_name if t else String(uid).capitalize())
	return ", ".join(names)


## The research button for `line` at `level`: a stub UnitType (never trained; ForgeBuilding completes the research).
static func stub(line: StringName, level: int) -> UnitType:
	var key := "%s:%d" % [line, level]
	if _stubs.has(key):
		return _stubs[key]
	var s := UnitType.new()
	s.id = StringName("%s%s_%d" % [STUB_PREFIX, line, level])
	var unit_line := is_unit_line(line)
	s.display_name = line_name(line) if unit_line else "%s %d" % [line_name(line), level]
	s.cost = price_of(line, level)
	s.pop = 0
	s.train_time = time_of(line, level)
	s.requires_tier = tier_of(line, level)
	s.set_meta(&"forge_line", line)
	s.set_meta(&"forge_level", level)
	# Logic text (English); the card shows it through Loc.sink (numeric templates in the .po files).
	if unit_line:
		s.set_meta(&"card_text", CARD_TEXT_UNIT % [line_text(line), units_text(line)])
	else:
		s.set_meta(&"card_text", CARD_TEXT_LEVEL % [level,
				max_level(line), line_text(line)])
	_stubs[key] = s
	return s


static func is_stub(type: Variant) -> bool:
	return type is UnitType and (type as UnitType).has_meta(&"forge_line")


static func stub_line(type: UnitType) -> StringName:
	return StringName(type.get_meta(&"forge_line")) if is_stub(type) else &""


# ---------------------------------------------------------------- static: teams / units

## The team's node (created under the current scene when missing and `create`).
static func for_team(for_team_id: int, create: bool = true) -> ForgeKit:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	for n in tree.get_nodes_in_group(&"forge_upgrades"):
		var b := n as ForgeKit
		if b and b.team == for_team_id and not b.is_queued_for_deletion():
			return b
	if not create or tree.current_scene == null or not ENABLED:
		return null
	var node := ForgeKit.new()
	node.name = "ForgeUpgrades%d" % for_team_id
	node.team = for_team_id
	node.add_to_group(&"forge_upgrades")
	tree.current_scene.add_child(node)
	return node


static func level_of(for_team_id: int, line: StringName) -> int:
	if is_unit_line(line):
		return 1 if UnitResearch.team_has(for_team_id, line) else 0
	var b := for_team(for_team_id, false)
	return int(b.levels.get(line, 0)) if b else 0


## A soldier the Forge upgrades (GoldBank.is_soldier_unit: not workers, wizards, champions, caravans, trackers).
static func is_upgraded_unit(u: Unit) -> bool:
	return u != null and is_instance_valid(u) and u.unit_type != null and int(u.team) != int(Unit.Team.NEUTRAL) \
			and GoldBank.is_soldier_unit(u)


## Puts the team's Forge levels on `u` (idempotent; a changed level replaces the modifier). TrainingBuilding-made,
## summoned and test units alike: the team node calls it for every unit that enters the tree.
static func apply_to(u: Unit) -> void:
	if not is_upgraded_unit(u):
		return
	var b := for_team(int(u.team), false)
	if b == null or b.levels.is_empty():
		return
	var stats := b.stats_for(u.unit_type.id)
	var want_range := b.range_for(u.unit_type.id)
	var sig := "%s|%s" % [str(stats), want_range]
	# The sig is a runtime marker ("_": never saved, review R4-1); the modifier check also covers a stale marker.
	if u.has_meta(SIG_META) and str(u.get_meta(SIG_META)) == sig and (stats.is_empty() or u.has_modifier(MODIFIER)):
		return
	u.set_meta(SIG_META, sig)
	if stats.is_empty():
		u.remove_modifier(MODIFIER)
	else:
		u.add_modifier(MODIFIER, stats)
	var have := float(u.get_meta(RANGE_META, 0.0))
	if not is_equal_approx(have, want_range):
		u.attack_range += want_range - have
		u.set_meta(RANGE_META, want_range)


## [[name, level, max]] of the lines that touch `u` with a level > 0 (selection panel).
static func summary_for(u: Unit) -> Array:
	var out: Array = []
	if not is_upgraded_unit(u):
		return out
	var b := for_team(int(u.team), false)
	if b == null:
		return out
	for line: StringName in b.levels:
		var lv := int(b.levels[line])
		if lv <= 0 or not b._touches(line, u.unit_type.id):
			continue
		out.append([line_name(line), lv, max_level(line)])
	return out


# ---------------------------------------------------------------- instance

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)


func level(line: StringName) -> int:
	return int(levels.get(line, 0))


## The summed `forge` stats for a unit id: every generic line, and its unit line.
func stats_for(unit_id: StringName) -> Dictionary:
	var out := {}
	for line: StringName in levels:
		var lv := int(levels[line])
		if lv <= 0 or not _touches(line, unit_id):
			continue
		var per: Dictionary = line_data(line).get("stats", {})
		for k: StringName in per:
			out[k] = float(out.get(k, 0.0)) + float(per[k]) * lv
	return out


func range_for(unit_id: StringName) -> float:
	var r := 0.0
	for line: StringName in levels:
		if int(levels[line]) > 0 and _touches(line, unit_id):
			r += float(line_data(line).get("range", 0.0)) * int(levels[line])
	return r


func _touches(line: StringName, _unit_id: StringName) -> bool:
	return LINES.has(line)


## One more level of `line` (the Forge's research finished). Re-applies to every living soldier of the team.
func complete(line: StringName) -> void:
	set_level(line, level(line) + 1)
	research_completed.emit(line, level(line))


## Tests / cheats: sets `line` to `lv` (clamped) and re-applies.
## A moved unit line (an old save / old test) grants the UnitResearch row instead (lv > 0).
func set_level(line: StringName, lv: int) -> void:
	if is_unit_line(line):
		if lv <= 0:
			return
		var ur := UnitResearch.for_team(team)
		if ur:
			ur.grant(line)
		else:
			# No unit research here (a mission with forge_enabled only, e2m4): the paid level is refunded. Deferred: a
			# load restores the saved crystals after this call in the same frame (SaveWorld phase 1).
			_refund_moved.call_deferred(line)
		return
	levels[line] = clampi(lv, 0, max_level(line))
	refresh_units()


func _refund_moved(line: StringName) -> void:
	var eco := Economy.for_team(team)
	if eco:
		eco.add(price_of(line, 1))


func refresh_units() -> void:
	if not is_inside_tree():
		return
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and int(u.team) == team and u.is_alive():
			apply_to(u)


func _on_node_added(node: Node) -> void:
	if levels.is_empty() or not (node is Unit):
		return
	_pending.append(node)
	if not _flush_queued:
		_flush_queued = true
		_flush.call_deferred()


func _flush() -> void:
	_flush_queued = false
	var batch := _pending
	_pending = []
	for n: Variant in batch:
		if is_instance_valid(n) and n is Unit and int((n as Unit).team) == team and (n as Unit).is_alive():
			apply_to(n as Unit)


# ---------------------------------------------------------------- bot (Commander rule 5)

## Builds the Forge from BOT_BUILD_AT (only with cost + reserve in hand: never saves), then, every BOT_EVERY s with an
## empty Forge queue, queues the cheapest open research up to BOT_MAX_LEVEL while crystals >= price + BOT_RESERVE
## (the unit lines moved to UnitResearch: the bot buys them through ai_research, UR.A1). `skip`: a champion hire waits for crystals. True = spent.
static func bot_step(for_team_id: int, faction: StringName, eco: Economy, now: float, grid: BuildGrid, workers: Array,
		keep: Node3D, difficulty: int, skip: bool = false) -> bool:
	if not ENABLED or skip or eco == null or grid == null or not enabled_here():
		return false
	var next := float(_bot_next.get(for_team_id, 0.0))
	if next - now > BOT_EVERY * 2.0:   # a new match in the same process
		next = 0.0
	if now < next:
		return false
	_bot_next[for_team_id] = now + BOT_EVERY
	var d := clampi(difficulty, 0, 2)
	var reserve := int(BOT_RESERVE[d])
	var type := forge_type(faction)
	if type == null:
		return false
	var forge: ForgeBuilding = null
	for b in Building.for_team(for_team_id):
		if b is ForgeBuilding and b.is_alive():
			forge = b as ForgeBuilding
	if forge == null:
		if now < float(BOT_BUILD_AT[d]) or eco.crystals < type.cost + reserve:
			return false
		if spot_backing_off(for_team_id, now):
			return false
		return _bot_build(for_team_id, type, grid, workers, keep, now)
	if not forge.is_constructed() or not forge.queue.is_empty():
		return false
	var pick: UnitType = null
	for line in card_lines(faction):
		var lv := level_of(for_team_id, line)
		if lv >= mini(max_level(line), int(BOT_MAX_LEVEL[d])):
			continue
		var s := stub(line, lv + 1)
		var r := forge.can_queue(s)
		if r != "" and r != TrainingBuilding.REASON_NO_CRYSTALS:
			continue
		if pick == null or s.cost < pick.cost:
			pick = s
	if pick == null or eco.crystals < pick.cost + reserve:
		return false
	return forge.queue_unit(pick) == ""


## True while the bot of `for_team_id` waits after a failed Forge spot search (a failure "in the future" = a new match
## in the same process: ignored).
static func spot_backing_off(for_team_id: int, now: float) -> bool:
	if not _bot_spot_failed.has(for_team_id):
		return false
	var failed := float(_bot_spot_failed[for_team_id])
	return failed <= now and now - failed < BOT_SPOT_BACKOFF


static func _bot_build(for_team_id: int, type: BuildingType, grid: BuildGrid, workers: Array, keep: Node3D,
		now: float = 0.0) -> bool:
	if keep == null or not is_instance_valid(keep) or BuildGrid.prerequisite_reason(type, for_team_id) != "":
		return false
	var toward := Vector3(-keep.global_position.x, 0.0, -keep.global_position.z).normalized()
	var spot := grid.find_spot(type, keep.global_position + toward * 10.0 - Vector3(toward.z, 0, -toward.x) * 10.0,
			for_team_id, 8)
	if spot == Vector3.INF:
		_bot_spot_failed[for_team_id] = now
		return false
	_bot_spot_failed.erase(for_team_id)
	var best: Node3D = null
	for w: Variant in workers:
		if not is_instance_valid(w) or not (w as Node).has_method(&"command_build"):
			continue
		if (w as Node).has_method(&"is_building") and bool((w as Node).call(&"is_building")):
			continue
		var wn := w as Node3D
		if best == null or wn.global_position.distance_to(spot) < best.global_position.distance_to(spot):
			best = wn
	if best == null:
		return false
	return grid.place(type, spot, for_team_id, [best]) != null
