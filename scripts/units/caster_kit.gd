class_name CasterKit
extends RefCounted
## Caster units (docs/design/caster-units.md, JS 2026-09-30): one spell-casting support unit per kingdom, trained at the
## keep on slot 5 (key B) from the Stronghold: Kilnwarden (Fire), Rimecarver (Ice), Bramblesage (Nature), Gloom Deacon
## (Shadow). Static side: the CASTERS / SPELLS tables (no new UnitType field: the .tres set only the standard fields),
## where they are trained (keep_types / gate_reason), the attach hook (Unit._ready), the team registries shared by the
## spells (Rime Bulwarks, Scrying Runes, Blood Tithe tethers) and the smart-cast pick used by the UI and the bots.
## Instance side: CasterAbility (scripts/units/caster_ability.gd), the node "CasterAbility" on each caster.
## Everything hangs on ENABLED (and only in the plain skirmish, or a mission that sets `casters_enabled` (mission 1 from
## 2026-09-30); scenes/main.tscn never lists them; tests set `force_enabled`).
## Hooks: TrainingBuilding.trainable_types (keep_types, after T3Kit's), TrainingBuilding.can_queue (gate_reason),
## Unit._ready (attach), Unit.displace (bulwark_blocks), T3UnitAbility / HelperAbilities (revealed_for: Scrying Rune),
## AIMemory.strength_of (bot_strength), commander._think / _rule_train (AICasters).

## THE switch: false = no keep slot, no card buttons, bots never train them.
const ENABLED := true
const SKIRMISH_SCRIPT := "res://scripts/world/skirmish.gd"

## Caster id -> kingdom, its two spells (key Z, key V), its passive, the tooltip line.
const CASTERS := {
	&"kilnwarden": {"faction": &"fire", "spells": [&"slag_rain", &"mana_scald"], "passive": &"stoke",
			"text": "Caster: Slag Rain melts armour; Mana Scald burns an enemy caster's mana."},
	&"rimecarver": {"faction": &"ice", "spells": [&"rime_bulwark", &"scrying_rune"], "passive": &"stillness",
			"text": "Caster: Rime Bulwark raises an ice wall for 8 s; Scrying Rune sees and reveals."},
	&"bramblesage": {"faction": &"nature", "spells": [&"snagroot", &"pollen_haze"], "passive": &"seedcloak",
			"text": "Caster: Snagroot pulls one enemy; Pollen Haze blinds ranged units."},
	&"gloom_deacon": {"faction": &"shadow", "spells": [&"blood_tithe", &"umbral_passage"], "passive": &"vigil",
			"text": "Caster: Blood Tithe heals an ally and drains a foe; Umbral Passage recalls soldiers."},
}
## Kingdom -> its caster id.
const BY_FACTION := {&"fire": &"kilnwarden", &"ice": &"rimecarver", &"nature": &"bramblesage",
		&"shadow": &"gloom_deacon"}
const IDS: Array[StringName] = [&"kilnwarden", &"rimecarver", &"bramblesage", &"gloom_deacon"]

## Spell numbers (caster-units.md 5, level 1). target: &"point" (ground), &"enemy" (an enemy unit), &"ally" (an own
## unit). "autocast" = the player's default (bots: all on). "fog": true = the point may be in the fog (Scrying Rune).
## "stop": false = the caster keeps walking while it casts (Blood Tithe, Scrying Rune).
const SPELLS := {
	&"slag_rain": {"name": "Slag Rain", "key": "Z", "mana": 75.0, "range": 10.0, "target": &"point", "radius": 3.0,
			"autocast": true, "damage": 12.0, "slag": 10.0, "slag_big": 5.0, "flight": 0.6,
			"text": "Flings molten slag: 12 damage in 3 m, armour -20 (never below 0), slower, +10 % damage taken for 10 s."},
	&"mana_scald": {"name": "Mana Scald", "key": "V", "mana": 50.0, "range": 9.0, "target": &"enemy", "radius": 0.0,
			"autocast": true, "burn": 60.0, "scalded": 6.0, "lash": 0.3,
			"text": "Burns up to 60 mana of an enemy wizard or caster and deals that much damage."},
	&"rime_bulwark": {"name": "Rime Bulwark", "key": "Z", "mana": 50.0, "range": 10.0, "target": &"point", "radius": 0.0,
			"autocast": false, "length": 4.0, "thick": 0.9, "height": 2.2, "time": 8.0, "max": 4, "shatter_pop": 3,
			"shatter_time": 1.0,
			"text": "An ice wall 4 m long for 8 s: blocks ground units of both teams (not arrows or spells)."},
	&"scrying_rune": {"name": "Scrying Rune", "key": "V", "mana": 25.0, "range": 12.0, "target": &"point", "radius": 10.0,
			"autocast": false, "time": 20.0, "sight": 10.0, "max": 3, "fog": true, "stop": false,
			"text": "A rune-stone for 20 s: sight 10 m and reveals hidden enemies there. Max 3."},
	&"snagroot": {"name": "Snagroot", "key": "Z", "mana": 75.0, "range": 9.0, "target": &"enemy", "radius": 0.0,
			"autocast": true, "hit": 0.25, "drag": 7.0, "drag_hero": 4.0, "drag_time": 0.5, "root": 1.0,
			"root_hero": 0.5, "immune_pop": 4,
			"text": "A vine drags one enemy 7 m toward the Bramblesage (heroes 4 m) and roots it 1 s."},
	&"pollen_haze": {"name": "Pollen Haze", "key": "V", "mana": 100.0, "range": 10.0, "target": &"point", "radius": 3.5,
			"autocast": true, "time": 6.0, "linger": 0.5, "tick": 0.25,
			"text": "A pollen cloud for 6 s: enemy ground units inside only shoot targets within 2.5 m."},
	&"blood_tithe": {"name": "Blood Tithe", "key": "Z", "mana": 10.0, "range": 7.0, "target": &"ally", "radius": 0.0,
			"autocast": true, "per_second": 2.5, "break": 9.0, "heal": 10.0, "drain": 5.0, "drain_radius": 5.0,
			"max_tethers": 2, "tick": 0.25, "stop": false,
			"text": "Channel: an ally heals 10 HP/s and the nearest enemy by it loses 5 HP/s. 2.5 mana/s (10 to start)."},
	&"umbral_passage": {"name": "Umbral Passage", "key": "V", "mana": 100.0, "range": 45.0, "target": &"point",
			"radius": 4.0, "autocast": false, "cooldown": 45.0, "channel": 2.5, "max_pop": 10, "cancel_cooldown": 5.0,
			"text": "Channel 2.5 s: your soldiers within 4 m of the point (up to 10 pop) step out beside the Deacon."},
}
## Passives (5.x): Stoke (+8 mana when a unit it slagged dies slagged, once per 0.5 s), Stillness (mana regen x1.5 after
## 3 s standing), Seedcloak (under 50 % HP: a free 2.5 m haze on itself for 3 s, once per 45 s), Vigil (+5 mana when
## an own soldier dies within 8 m, once per 0.5 s).
const PASSIVES := {
	&"stoke": {"name": "Stoke", "mana": 8.0, "every": 0.5,
			"text": "Stoke: +8 mana when an enemy it slagged dies slagged."},
	&"stillness": {"name": "Stillness", "still": 3.0, "mult": 1.5,
			"text": "Stillness: mana regen x1.5 after 3 s without moving."},
	&"seedcloak": {"name": "Seedcloak", "hp_pct": 0.5, "radius": 2.5, "time": 3.0, "cooldown": 45.0,
			"text": "Seedcloak: under 50 % HP, a free 2.5 m Pollen Haze on itself (every 45 s)."},
	&"vigil": {"name": "Vigil", "mana": 5.0, "radius": 8.0, "every": 0.5,
			"text": "Vigil: +5 mana when one of your soldiers dies within 8 m."},
}

## Mana (3.1): max 200, start 50, 0.8 / s. Levels (3.4): +20 max mana, +0.05 / s per level above 1.
const MAX_MANA := 200.0
const START_MANA := 50.0
const MANA_REGEN := 0.8
const LEVEL_MANA := 20.0
const LEVEL_REGEN := 0.05
const CAST_TIME := 0.4          ## the cast animation; the caster stops (Tithe / Rune excepted)
const GLOBAL_COOLDOWN := 1.0
const AUTOCAST_TICK := 0.5
## Spell XP (3.4): per enemy hit / slagged / pulled / hazed / drained, per 20 HP healed, per unit carried; max per cast.
const XP_PER_HIT := 3
const XP_PER_HEAL := 20.0
const XP_PER_CARRY := 4
const XP_MAX_PER_CAST := 20

## Refusals (3.2), shown on the message line like the wizard's cast reasons.
const REASON_MANA := "Not enough mana"
const REASON_RANGE := "Out of range"
const REASON_NO_TARGET := "No target"
const REASON_RECHARGING := "Recharging"
const REASON_CANT := "Can't cast now"
const REASON_INVALID := "Invalid target"

## Knobs (caster-units.md 8.1 / 13 Q5).
const MAX_PER_TEAM := 0                      ## 0 = no cap
const BOT_KEEP := {0: 0, 1: 1, 2: 2}         ## difficulty -> casters kept alive at tier 2 (+1 at the Citadel)
const BOT_SHARE_CAP := 0.10                  ## casters <= 10 % of soldier pop (rounded up)
const BOT_RESERVE := 100

## Tests on any scene set this true (the keep lists casters only in a real skirmish otherwise).
static var force_enabled := false

## Team registries (shared by every CasterAbility): Rime Bulwarks {team: [RimeBulwark]}, Scrying Runes {team: [rune
## dictionaries]}. Pruned when read.
static var _bulwarks: Dictionary = {}
static var _runes: Dictionary = {}


static func enabled_here() -> bool:
	if not ENABLED:
		return false
	if force_enabled:
		return true
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return false
	var s: Variant = tree.current_scene.get_script()
	if s is Script and (s as Script).resource_path == SKIRMISH_SCRIPT:
		return true
	# A campaign mission opts in with `casters_enabled = true` (mission-01.md "Tiers": its Stronghold opens the caster).
	return &"casters_enabled" in tree.current_scene and bool(tree.current_scene.get(&"casters_enabled"))


static func is_caster(type_id: StringName) -> bool:
	return ENABLED and CASTERS.has(type_id)


## True for a living Unit carrying a CasterAbility.
static func is_caster_unit(u: Variant) -> bool:
	return u is Unit and is_instance_valid(u) and (u as Unit).has_node(CasterAbility.NODE_NAME)


static func ability_of(u: Variant) -> CasterAbility:
	if not (u is Node) or not is_instance_valid(u):
		return null
	return (u as Node).get_node_or_null(CasterAbility.NODE_NAME) as CasterAbility


## The caster id of `faction` (&"" when none).
static func caster_for(faction: StringName) -> StringName:
	return BY_FACTION.get(faction, &"")


## The Z / V spells of caster `type_id`.
static func spells_of(type_id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for s: StringName in (CASTERS.get(type_id, {}) as Dictionary).get("spells", []):
		out.append(s)
	return out


static func passive_of(type_id: StringName) -> StringName:
	return (CASTERS.get(type_id, {}) as Dictionary).get("passive", &"")


## The caster id a spell belongs to (&"" when unknown).
static func caster_of_spell(spell_id: StringName) -> StringName:
	for cid: StringName in CASTERS:
		if (CASTERS[cid]["spells"] as Array).has(spell_id):
			return cid
	return &""


static func spell(spell_id: StringName) -> Dictionary:
	return SPELLS.get(spell_id, {})


static func spell_value(spell_id: StringName, key: String, default: Variant = 0.0) -> Variant:
	return (SPELLS.get(spell_id, {}) as Dictionary).get(key, default)


static func spell_name(spell_id: StringName) -> String:
	return String(spell_value(spell_id, "name", String(spell_id).capitalize()))


static func target_kind(spell_id: StringName) -> StringName:
	return StringName(spell_value(spell_id, "target", &"point"))


## Card / tooltip line of a caster type (3.3).
static func description(type_id: StringName) -> String:
	return String((CASTERS.get(type_id, {}) as Dictionary).get("text", ""))


## Tooltip of a spell button: `Slag Rain  [Z]\n75 mana · range 10 · autocast on\n<text>\nRight-click or Ctrl+Z: autocast`.
static func spell_tooltip(spell_id: StringName, autocast_on: Variant = null) -> String:
	var key := String(spell_value(spell_id, "key", ""))
	var s := spell(spell_id)
	var cost := "%d mana" % roundi(float(s.get("mana", 0.0)))
	if spell_id == &"blood_tithe":
		cost = "%s mana/s (%d to start)" % [str(snappedf(float(s.get("per_second", 0.0)), 0.1)), roundi(float(s.get("mana", 0.0)))]
	var line2 := "%s · range %d" % [cost, roundi(float(s.get("range", 0.0)))]
	if float(s.get("cooldown", 0.0)) > 0.0:
		line2 += " · cooldown %d s" % roundi(float(s.get("cooldown", 0.0)))
	if autocast_on != null:
		line2 += " · autocast %s" % ("on" if bool(autocast_on) else "off")
	return "%s  [%s]\n%s\n%s\nRight-click or Ctrl+%s: autocast on / off" % [spell_name(spell_id), key, line2,
			String(s.get("text", "")), key]


# ---------------------------------------------------------------- keep hooks (TrainingBuilding)

## The keep's caster slot (after the worker, the tier button, the tier-3 unit and the helper: slot 5 = key B). [] when
## off, in missions, or for a kingdom without a caster.
static func keep_types(building: Building) -> Array[UnitType]:
	var out: Array[UnitType] = []
	if building == null or building.building_type == null or building.building_type.kind != &"keep" or not enabled_here():
		return out
	var t := UnitType.find(String(caster_for(building.building_type.faction)))
	if t:
		out.append(t)
	return out


## True when `type` is a caster listed by keep_types (the card places it on slot 5 whatever the slots before it hold).
static func is_keep_caster(type: Variant) -> bool:
	return type is UnitType and is_caster((type as UnitType).id)


## Extra refusal after the tier gate ("" = fine): the optional per-team cap (MAX_PER_TEAM, 0 = none).
static func gate_reason(type: UnitType, team: int) -> String:
	if type == null or not is_caster(type.id) or MAX_PER_TEAM <= 0:
		return ""
	if T3Kit.count_alive(team, type.id, true) >= MAX_PER_TEAM:
		return "Max %d %ss" % [MAX_PER_TEAM, type.display_name]
	return ""


# ---------------------------------------------------------------- units (Unit._ready)

static func attach(u: Unit) -> void:
	if u == null or u.unit_type == null or not is_caster(u.unit_type.id) or u.has_node(CasterAbility.NODE_NAME):
		return
	var n := CasterAbility.new()
	n.name = CasterAbility.NODE_NAME
	n.unit = u
	n.id = u.unit_type.id
	u.add_child(n)


## Casters of `team` (living), optionally only of `type_id`.
static func casters_of(team: int, type_id: StringName = &"") -> Array[Unit]:
	var out: Array[Unit] = []
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return out
	for n in tree.get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or int(u.team) != team or not u.is_alive() or u.unit_type == null or not is_caster(u.unit_type.id):
			continue
		if type_id != &"" and u.unit_type.id != type_id:
			continue
		out.append(u)
	return out


## Heroes for the casters' shorter durations: wizards, champions, helpers, titans (pop >= 6).
static func is_big_target(u: Unit) -> bool:
	if u == null:
		return false
	return u.is_in_group(&"heroes") or u.is_in_group(&"enemy_heroes") or u.has_method(&"command_cast") \
			or u.is_in_group(&"champions") or u.is_in_group(&"helpers") or is_titan(u)


static func is_titan(u: Unit) -> bool:
	return u != null and (u.is_in_group(&"titans") or (u.unit_type != null and u.unit_type.pop >= 6))


## Mana a unit holds: a wizard's `mana`, a caster's CasterAbility.mana, else -1 (no mana: Mana Scald refuses it).
static func mana_of(u: Unit) -> float:
	if u == null or not is_instance_valid(u):
		return -1.0
	var ab := ability_of(u)
	if ab:
		return ab.mana
	if u is Wizard:
		return float((u as Wizard).mana)
	return -1.0


## Burns up to `amount` mana of `u` (a wizard or a caster). Returns what was burnt.
static func burn_mana(u: Unit, amount: float) -> float:
	var ab := ability_of(u)
	if ab:
		return ab.burn_mana(amount)
	if u is Wizard:
		var w := u as Wizard
		var b := clampf(amount, 0.0, maxf(0.0, w.mana))
		w.mana -= b
		return b
	return 0.0


# ---------------------------------------------------------------- smart-cast (3.2)

## The caster among `casters` that casts `spell_id` at `target` on one click: the one with the most mana among those in
## range that can cast now, else the nearest that could cast once in range (it walks there). null when none can
## (`reason_out[0]` = the refusal of the best candidate, for the message line).
static func pick_caster(casters: Array, spell_id: StringName, target: Variant, reason_out: Array = []) -> Unit:
	var in_range: Unit = null
	var best_mana := -1.0
	var nearest: Unit = null
	var nearest_d := INF
	var first_reason := ""
	for c: Variant in casters:
		var u := c as Unit
		if u == null or not is_instance_valid(u) or not u.is_alive():
			continue
		var ab := ability_of(u)
		if ab == null or not ab.spell_ids().has(spell_id):
			continue
		var r := ab.can_cast(spell_id, target)
		if r == "":
			if ab.mana > best_mana:
				best_mana = ab.mana
				in_range = u
		elif r == REASON_RANGE:
			var d := ab.distance_to_target(target)
			if d < nearest_d:
				nearest_d = d
				nearest = u
		elif first_reason == "":
			first_reason = r
	if in_range != null:
		return in_range
	if nearest != null:
		return nearest
	if reason_out.is_empty():
		reason_out.append(first_reason if first_reason != "" else REASON_CANT)
	return null


# ---------------------------------------------------------------- Rime Bulwark registry

static func register_bulwark(team: int, wall: Node3D) -> void:
	var list: Array = _bulwarks.get(team, [])
	list.append(wall)
	_bulwarks[team] = list


## The team's living Bulwarks, oldest first.
static func bulwarks_of(team: int) -> Array:
	var list: Array = _bulwarks.get(team, [])
	var alive: Array = []
	for w: Variant in list:
		if is_instance_valid(w) and (w as Node).is_inside_tree() and not bool((w as Object).get(&"ended")):
			alive.append(w)
	_bulwarks[team] = alive
	return alive


## Every living Bulwark (both teams).
static func all_bulwarks() -> Array:
	var out: Array = []
	for t: Variant in _bulwarks.keys():
		out.append_array(bulwarks_of(int(t)))
	return out


## True when a unit of `unit_radius` standing at `p` would be inside a living Bulwark (Unit.displace stops there).
static func bulwark_blocks(p: Vector3, unit_radius: float = 0.0) -> bool:
	if _bulwarks.is_empty():
		return false
	for w: Variant in all_bulwarks():
		if (w as Object).call(&"contains", p, unit_radius * 0.5):
			return true
	return false


# ---------------------------------------------------------------- Scrying Rune registry (reveal)

## A rune of `team` at `pos` until match time `until` (s), vision `radius`. `owner` = the Rimecarver (max 3 each).
static func register_rune(team: int, pos: Vector3, radius: float, until: float, owner: Node, marker: Node) -> Dictionary:
	var r := {"team": team, "pos": pos, "radius": radius, "until": until, "owner": owner, "marker": marker}
	var list: Array = _runes.get(team, [])
	list.append(r)
	_runes[team] = list
	return r


static func remove_rune(r: Dictionary) -> void:
	for t: Variant in _runes.keys():
		(_runes[t] as Array).erase(r)
	var m: Variant = r.get("marker")
	if is_instance_valid(m):
		(m as Node).queue_free()


## Living runes of `team` (all teams when -1).
static func runes_of(team: int) -> Array:
	var now := now_s()
	var out: Array = []
	for t: Variant in _runes.keys():
		if team >= 0 and int(t) != team:
			continue
		var keep: Array = []
		for r: Dictionary in _runes[t]:
			if float(r["until"]) > now:
				keep.append(r)
				out.append(r)
		_runes[t] = keep
	return out


## True when a Scrying Rune of a team hostile to `u` covers it: veils and disguises (Mother Hush, the Ashveil Saboteur)
## do not work there (caster-units.md 5.2).
static func revealed_for(u: Node3D) -> bool:
	if not ENABLED or _runes.is_empty() or u == null or not is_instance_valid(u):
		return false
	var team: Variant = u.get(&"team")
	if team == null:
		return false
	var at := u.global_position
	for r: Dictionary in runes_of(-1):
		if int(r["team"]) == int(team) or int(r["team"]) == 2:
			continue
		var p: Vector3 = r["pos"]
		if Vector2(p.x - at.x, p.z - at.z).length() <= float(r["radius"]):
			return true
	return false


## Clears the registries (a new level, tests).
static func reset() -> void:
	_bulwarks.clear()
	_runes.clear()


# ---------------------------------------------------------------- the bot (AIMemory hook)

## A caster's worth in the commander's strength (8.2): cost x 0.5, x 1.0 when its mana >= twice its cheapest spell.
static func bot_strength(u: Unit) -> float:
	var t := u.unit_type
	if t == null:
		return 0.0
	var ab := ability_of(u)
	var cheapest := INF
	for s in spells_of(t.id):
		cheapest = minf(cheapest, float(spell_value(s, "mana", 0.0)))
	var full := ab != null and cheapest < INF and ab.mana >= cheapest * 2.0
	return float(t.cost) * (1.0 if full else 0.5)


static func now_s() -> float:
	return float(Engine.get_physics_frames()) / float(maxi(1, Engine.physics_ticks_per_second))
