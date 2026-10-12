class_name T3Kit
extends RefCounted
## Tier-3 content glue (docs/design/t3-helpers.md, plan docs/plan/tiers-wave.md "T3 agent"): the 4 helpers called at the
## Citadel keep (HelperRoster / Helper), one T3 unit per kingdom trained at the keep (`requires_tier = 3`), the neutral
## Stormbottle Genie hired at a tavern, and the bot's use of all three. Everything hangs on ENABLED (and only in the
## plain skirmish: missions and old test scenes see nothing unless a test sets `force_enabled`).
## Hooks: TrainingBuilding (keep_types / gate_reason / on_queued / on_cancelled / on_trained / is_paused), Unit._ready
## (attach), Unit.kill_xp_value (helpers), commander._think (bot_tick).

## THE switch: false = no helper slot, no T3 unit, no Genie, bots skip it all.
const ENABLED := true

## Kingdom -> its tier-3 unit (trained at the keep once it is a Citadel).
const KEEP_UNITS := {
	&"fire": &"ashveil_saboteur",
	&"shadow": &"nightblood_reaver",
	&"ice": &"shardguard",
	&"nature": &"briar_roc",
}
const GENIE_ID := &"stormbottle_genie"
const UNIT_IDS: Array[StringName] = [&"ashveil_saboteur", &"nightblood_reaver", &"shardguard", &"briar_roc",
		&"stormbottle_genie"]
const DESCRIPTIONS := {
	&"ashveil_saboteur": "Tier 3 spy. Looks like an enemy worker out of combat; plants Powder Charges (250, pauses training 10 s). Max 4.",
	&"nightblood_reaver": "Tier 3 vampire duelist. Heals 35 % of its damage (halved 4 s by fire); Blood Frenzy under 40 % HP.",
	&"shardguard": "Tier 3 halberdier. Hold the Line: stops a charge and freezes the rider 1 s; taunts divers off your archers.",
	&"briar_roc": "Tier 3 thorn bird. Seed Storm every 16 s: 30 and roots ground enemies 1 s.",
	&"stormbottle_genie": "Neutral tier-3 hire. Lightning chains to 2 more; Tempest Bolt 120 (x1.5 on titans).",
}
const SABOTEUR_MAX := 4
const REASON_SABOTEUR_MAX := "Max 4 Saboteurs"
const SKIRMISH_SCRIPT := "res://scripts/world/skirmish.gd"
const META_PAUSED := &"t3_paused_until"

# Genie (tavern "Wonders"): 400 crystals (250 + 150 gold folded in, no trade), 45 s, pop 4, 1 per team.
const GENIE_COST := 400
const GENIE_TIME := 45.0
const GENIE_REVIVE_ESSENCE := 150
const GENIE_REVIVE_TIME := 40.0
const REASON_GENIE_ALREADY := "Already hired"
const REASON_NO_TAVERN := "No open tavern"

# Bot (section 9): normal / hard only.
const BOT_T3_UNITS := {1: 1, 2: 2}          ## difficulty -> T3 units kept alive (NORMAL 1, HARD 2)
const BOT_RESERVE := 100                    ## crystals kept after a helper / T3 purchase
const BOT_GENIE_RESERVE := 200

## Tests on any scene set this true (the keep lists T3 content only in a real skirmish otherwise).
static var force_enabled := false


## T3 units (and the Genie, and the bot's T3 use) here: the plain skirmish, a test's `force_enabled`, or a campaign
## mission that opts in with `t3_enabled = true` (mission-e2-01.md E2M1.G1, like CasterKit reads `casters_enabled`).
static func enabled_here() -> bool:
	if not ENABLED:
		return false
	if force_enabled:
		return true
	var scene := _scene()
	if scene == null:
		return false
	if _is_skirmish(scene):
		return true
	return &"t3_enabled" in scene and bool(scene.get(&"t3_enabled"))


## The helper call / revive on the keep card here: wherever T3 is on in the skirmish (or forced), or a mission with
## `helpers_enabled = true` (independent of `t3_enabled`: e2m4 has helpers but no T3 unit).
static func helpers_here() -> bool:
	if not ENABLED:
		return false
	if force_enabled:
		return true
	var scene := _scene()
	if scene == null:
		return false
	if &"helpers_enabled" in scene:
		return bool(scene.get(&"helpers_enabled"))
	return _is_skirmish(scene)


static func _scene() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.current_scene if tree else null


## The plain skirmish or a generated map (LayoutLevel), never a mission (CasterKit.is_plain_skirmish;
## thornwater_2026-10-11.md: layout maps had no T3).
static func _is_skirmish(scene: Node) -> bool:
	return CasterKit.is_plain_skirmish(scene)


static func is_t3_unit(type_id: StringName) -> bool:
	return ENABLED and UNIT_IDS.has(type_id)


static func description(type_id: StringName) -> String:
	if type_id == HelperRoster.CALL_ID:
		return "Tier 3 helper: your kingdom's ally fights beside your wizard (autonomous, stance on its card). 200 essence. Level = your wizard's."
	if type_id == HelperRoster.REVIVE_ID:
		return "Bring your helper back at the keep (essence)."
	return String(DESCRIPTIONS.get(type_id, ""))


# ---------------------------------------------------------------- keep hooks (TrainingBuilding)

## Extra keep slots (appended after the worker and the tier upgrade): the kingdom's T3 unit, then Call / Revive helper.
static func keep_types(building: Building) -> Array[UnitType]:
	var out: Array[UnitType] = []
	if building == null or building.building_type == null or building.building_type.kind != &"keep":
		return out
	var t3 := enabled_here()
	if not t3 and not helpers_here():
		return out
	var t := UnitType.find(String(KEEP_UNITS.get(building.building_type.faction, &""))) if t3 else null
	if t:
		if not t.has_meta(&"card_text"):   # command card tooltip line (stub / extra types)
			t.set_meta(&"card_text", description(t.id))
		out.append(t)
	var roster := HelperRoster.for_team(int(building.team)) if helpers_here() else null
	if roster:
		var stub := roster.card_type()
		if stub:
			var ht := roster.helper_type()
			var text := description(stub.id)
			if stub.id == HelperRoster.CALL_ID and ht:
				text = "%s, %s. %d essence too. Autonomous; its level is your wizard's. Stance on its card." % [
						ht.display_name, ht.title, roster.call_essence()]
			elif ht:
				text = "%d essence. %s returns at the keep." % [roster.revive_cost(), ht.display_name]
			stub.set_meta(&"card_text", text)
			out.append(stub)
	return out


## Extra refusal after the tier gate ("" = fine).
static func gate_reason(type: UnitType, team: int) -> String:
	if type == null or not ENABLED:
		return ""
	if type.id == HelperRoster.CALL_ID or type.id == HelperRoster.REVIVE_ID:
		var roster := HelperRoster.for_team(team)
		return roster.gate_reason(type) if roster else ""
	if type.id == &"ashveil_saboteur" and count_alive(team, type.id, true) >= SABOTEUR_MAX:
		return REASON_SABOTEUR_MAX
	return ""


static func on_queued(type: UnitType, team: int) -> void:
	if type and (type.id == HelperRoster.CALL_ID or type.id == HelperRoster.REVIVE_ID):
		var roster := HelperRoster.for_team(team)
		if roster:
			roster.on_queued(type)


static func on_cancelled(type: UnitType, team: int) -> void:
	if type and (type.id == HelperRoster.CALL_ID or type.id == HelperRoster.REVIVE_ID):
		var roster := HelperRoster.for_team(team)
		if roster:
			roster.on_cancelled(type)


## A stub finished at `building`: the roster spawns / revives the helper. True = handled (no unit to spawn).
static func on_trained(building: Node3D, type: UnitType) -> bool:
	if type == null or (type.id != HelperRoster.CALL_ID and type.id != HelperRoster.REVIVE_ID):
		return false
	var roster := HelperRoster.for_team(int(building.get(&"team")))
	if roster:
		roster.on_trained(type, building.call(&"spawn_point"))
	return true


## Powder Charge: `building`'s training / research stops for `seconds`.
static func pause_building(building: Node3D, seconds: float) -> void:
	building.set_meta(META_PAUSED, _now() + seconds)


static func is_paused(building: Node3D) -> bool:
	return ENABLED and building.has_meta(META_PAUSED) and float(building.get_meta(META_PAUSED)) > _now()


# ---------------------------------------------------------------- units (Unit._ready / Unit.is_disguised_for)

static func attach(u: Unit) -> void:
	if u == null or u.unit_type == null or not is_t3_unit(u.unit_type.id) or u.has_node(T3UnitAbility.NODE_NAME):
		return
	var n := T3UnitAbility.new()
	n.name = T3UnitAbility.NODE_NAME
	n.unit = u
	n.id = u.unit_type.id
	u.add_child(n)


static func ability_of(u: Node) -> T3UnitAbility:
	return u.get_node_or_null(T3UnitAbility.NODE_NAME) as T3UnitAbility if u else null


## True for hits that burn a Nightblood Reaver: Fire units, the Fire wizard, Fire towers / keeps.
static func is_fire_source(attacker: Node3D) -> bool:
	if attacker == null or not is_instance_valid(attacker):
		return false
	if attacker is Unit:
		var u := attacker as Unit
		if u.unit_type:
			return u.unit_type.faction == &"fire"
		return StringName(str(u.get(&"kingdom"))) == &"fire"
	var bt: Variant = attacker.get(&"building_type")
	return bt is BuildingType and (bt as BuildingType).faction == &"fire"


## Enemy buildings within 12 m of a disguised Saboteur of `team` (Eavesdrop: the UI shows their queues).
static func eavesdropped(team: int) -> Array[Node3D]:
	var out: Array[Node3D] = []
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return out
	for n in tree.get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or int(u.team) != team or not u.is_alive() or u.unit_type == null or u.unit_type.id != &"ashveil_saboteur":
			continue
		var ab := ability_of(u)
		if ab == null or not ab.disguised:
			continue
		for b in tree.get_nodes_in_group(&"buildings"):
			var bn := b as Node3D
			if bn and u.is_enemy_of(bn) and not out.has(bn) and T3UnitAbility._flat(bn.global_position, u.global_position) <= 12.0:
				out.append(bn)
	return out


## Living (and, with `queued`, queued) units of `type_id` for `team`.
static func count_alive(team: int, type_id: StringName, queued: bool = false) -> int:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return 0
	var n := 0
	for node in tree.get_nodes_in_group(&"units"):
		var u := node as Unit
		if u and int(u.team) == team and u.is_alive() and u.unit_type and u.unit_type.id == type_id:
			n += 1
	if queued:
		for node in tree.get_nodes_in_group(&"buildings"):
			var b := node as TrainingBuilding
			if b and int(b.team) == team:
				for t in b.queue:
					if t and t.id == type_id:
						n += 1
	return n


# ---------------------------------------------------------------- Stormbottle Genie (tavern "Wonders")

## The tier-3 wonders a team may hire at a tavern (the Genie), [] when off.
static func wonders_for(_team: int) -> Array[UnitType]:
	var out: Array[UnitType] = []
	if enabled_here():
		var g := UnitType.find(String(GENIE_ID))
		if g:
			out.append(g)
	return out


## "" when `team` may hire (or re-bottle) its Genie now. Refusals: "Requires Citadel", "Already hired", "No open
## tavern", pop, crystals (hire) / essence (revive).
static func can_hire_genie(team: int) -> String:
	if not enabled_here():
		return "Can't hire that here"
	var g := UnitType.find(String(GENIE_ID))
	if g == null:
		return "Can't hire that here"
	var tier := TierSystem.gate_reason(g.requires_tier, team)
	if tier != "":
		return tier
	var roster := HelperRoster.for_team(team)
	var st := roster.genie_state if roster else &"none"
	if st == &"hiring" or st == &"alive":
		return REASON_GENIE_ALREADY
	if _open_tavern_door(team) == Vector3.INF:
		return REASON_NO_TAVERN
	var eco := Economy.for_team(team)
	if eco and not eco.has_pop_for(g.pop):
		return TrainingBuilding.REASON_POP_CAP
	if st == &"bottled":
		var bank := EssenceBank.for_team(team)
		if bank and not bank.can_afford(GENIE_REVIVE_ESSENCE):
			return HelperRoster.REASON_NO_ESSENCE
		return ""
	if eco and not eco.can_afford(GENIE_COST):
		return TrainingBuilding.REASON_NO_CRYSTALS
	return ""


## Pays and starts the Genie (45 s; a bottled one: 150 essence, 40 s); it walks out of the nearest open tavern.
static func hire_genie(team: int) -> String:
	var reason := can_hire_genie(team)
	if reason != "":
		return reason
	var roster := HelperRoster.for_team(team)
	var g := UnitType.find(String(GENIE_ID))
	var wait := GENIE_TIME
	var eco := Economy.for_team(team)
	if roster.genie_state == &"bottled":
		var bank := EssenceBank.for_team(team)
		if bank:
			bank.spend(GENIE_REVIVE_ESSENCE)
		wait = GENIE_REVIVE_TIME
	elif eco:
		eco.spend(GENIE_COST)
	if eco:
		eco.reserve_pop(g.pop)
	roster.genie_state = &"hiring"
	roster.get_tree().create_timer(wait, false, true).timeout.connect(func() -> void: _genie_arrives(team))
	return ""


static func _genie_arrives(team: int) -> void:
	var roster := HelperRoster.for_team(team)
	var g := UnitType.find(String(GENIE_ID))
	if roster == null or g == null:
		return
	var door := _open_tavern_door(team)
	if door == Vector3.INF:
		var k := Keep.nearest(team, Vector3.ZERO)
		door = k.spawn_point() if k else Vector3.ZERO
	var eco := Economy.for_team(team)
	if eco:
		eco.release_pop(g.pop)   # the living Genie counts its own pop
	var u := Unit.new()
	u.apply_type(g)
	u.team = team as Unit.Team
	var parent := roster.get_tree().current_scene
	parent.add_child(u)
	u.global_position = door
	u.command_stop()
	roster.set_genie(u)


static func _open_tavern_door(team: int) -> Vector3:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return Vector3.INF
	var k := Keep.nearest(team, Vector3.ZERO)
	var from := k.global_position if k else Vector3.ZERO
	var best := Vector3.INF
	var bd := INF
	for t in tree.get_nodes_in_group(&"taverns"):
		if t.has_method(&"is_open") and not bool(t.call(&"is_open")):
			continue
		var door: Vector3 = t.call(&"door_point") if t.has_method(&"door_point") else (t as Node3D).global_position
		var d := from.distance_to(door)
		if d < bd:
			bd = d
			best = door
	return best


# ---------------------------------------------------------------- the bot (section 9)

## Called by the Commander every decision tick. Normal / hard: call and revive the helper at the Citadel, pick its
## stance, keep 1 (normal) / 2 (hard) T3 units, send Saboteurs at enemy buildings, hire the Genie after the helper.
static func bot_tick(team: int, difficulty: int, keep: Keep, now: float) -> void:
	if not enabled_here() or difficulty <= 0 or keep == null or not is_instance_valid(keep) or not keep.is_alive():
		return
	var roster := HelperRoster.for_team(team)
	if roster == null:
		return
	var eco := Economy.for_team(team)
	if eco == null:
		return
	# Call / revive (before any research: section 9).
	var stub := roster.card_type()
	if stub and not keep.queue.has(stub) and keep.can_queue(stub) == "":
		if stub.id == HelperRoster.REVIVE_ID or eco.crystals >= stub.cost + BOT_RESERVE:
			keep.queue_unit(stub)
	# Stance.
	var h := roster.helper
	if h and is_instance_valid(h) and h.is_alive():
		var want := &"escort"
		if _enemies_near_count(team, keep.global_position, 22.0) >= 3:
			want = &"home"
		elif h.bonded_wizard and is_instance_valid(h.bonded_wizard) \
				and h.bonded_wizard.global_position.distance_to(keep.global_position) < 25.0:
			want = &"vanguard"
		h.set_stance(want)
	# T3 units: 1-2 kept alive (only while the helper is not waiting for crystals).
	if roster.state() == &"none" and TierSystem.tier_of(team) >= 3:
		return   # the helper comes first
	var t := UnitType.find(String(KEEP_UNITS.get(keep.building_type.faction if keep.building_type else &"", &"")))
	if t and count_alive(team, t.id, true) < int(BOT_T3_UNITS.get(difficulty, 1)) and keep.queue.size() < 2 \
			and eco.crystals >= t.cost + BOT_RESERVE and keep.can_queue(t) == "":
		keep.queue_unit(t)
	_bot_saboteurs(team, now)
	# Genie after the helper.
	if roster.state() == &"alive" and eco.crystals >= GENIE_COST + BOT_GENIE_RESERVE and can_hire_genie(team) == "":
		hire_genie(team)
	elif roster.genie_state == &"bottled" and can_hire_genie(team) == "":
		hire_genie(team)


## Commander rule 5 (train), right after the keep upgrade: at the Citadel, normal / hard bots call the helper before any
## other spending. &"called" = queued now, &"saving" = keeps its crystals for it (skip training), &"" = nothing to do.
static func bot_try_helper(team: int, keep: Keep, eco: Economy, difficulty: int) -> StringName:
	if not enabled_here() or difficulty <= 0 or keep == null or not is_instance_valid(keep) or not keep.is_alive() \
			or eco == null or TierSystem.tier_of(team) < 3:
		return &""
	var roster := HelperRoster.for_team(team)
	if roster == null or roster.state() != &"none":
		return &""
	var stub := roster.call_type()
	if stub == null:
		return &""
	var bank := EssenceBank.for_team(team)
	if bank and not bank.can_afford(roster.call_essence()):
		return &""   # essence comes by itself: keep training meanwhile
	var r := keep.can_queue(stub)
	if r == "":
		return &"called" if keep.queue_unit(stub) == "" else &""
	if r == TrainingBuilding.REASON_NO_CRYSTALS:
		return &"saving"
	return &""


# Saboteurs walk (disguised) to the enemy's nearest non-keep building; the charge autocasts on arrival.
static func _bot_saboteurs(team: int, _now_s: float) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	for n in tree.get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or int(u.team) != team or not u.is_alive() or u.unit_type == null or u.unit_type.id != &"ashveil_saboteur":
			continue
		if u.attack_target != null and _alive(u.attack_target):
			continue
		var best: Node3D = null
		var bd := INF
		for b in tree.get_nodes_in_group(&"buildings"):
			var bn := b as Building
			if bn == null or not u.is_enemy_of(bn) or not bn.is_alive() or int(bn.team) == 2 or bn.building_type == null:
				continue
			if bn.building_type.kind == &"keep" or bn.building_type.attack_damage > 0.0:
				continue   # towers and keeps reveal it
			var d := u.global_position.distance_to(bn.global_position)
			if d < bd:
				bd = d
				best = bn
		if best:
			u.command_attack(best)


static func _enemies_near_count(team: int, at: Vector3, r: float) -> int:
	var tree := Engine.get_main_loop() as SceneTree
	var n := 0
	for node in tree.get_nodes_in_group(&"units"):
		var u := node as Unit
		# 2v2: an allied seat's army is not a threat (Teams.is_hostile); NEUTRAL creatures never count.
		if u and u.is_alive() and int(u.team) != 2 and Teams.is_hostile(int(u.team), team) and not u.is_worker() \
				and Vector2(u.global_position.x - at.x, u.global_position.z - at.z).length() <= r:
			n += 1
	return n


static func _alive(n: Variant) -> bool:
	return n != null and is_instance_valid(n) and (n as Object).has_method(&"is_alive") and bool((n as Object).call(&"is_alive"))


static func _now() -> float:
	return float(Engine.get_physics_frames()) / float(maxi(1, Engine.physics_ticks_per_second))
