class_name MissionE7_03
extends MissionE7Base
## Episode 7, mission 3 "The Outwall" (docs/design/mission-e7-03.md): one night in Adamarch's poor harbour quarter.
## Ring the five Dock Bells and shelter the lanes at the Glass Hall while Aurivane's landing boats, Adamarch's press-gangs
## and Malrik's masked raiders come for the dockers; at 9:00 the Diamond Archon orders the pits held (the diamond tithe).
## At the Night Tide (17:00) the pits and the returning fishers are attacked at once: the people or the pits. Hold until
## dawn (22:00). Spotlight: the War Mammoth (freed from the Hauling Yard).
##
## Built deviations (2026-10-09, from the spec):
## - The Outwall is built in code (no adamarch_outwall.map): a 140 x 110 MapInfo, the white wall and the sea as bound
##   walls (no piers, no RiverSystem sea), the spec table's positions; shanties are box props.
## - Masks are Shadow units renamed "Masked ..." on the ENEMY team (no grey look); the Mask Captain has boss numbers (no
##   Hook Chain / Grey Veil). Press-gangs are 4 Facetguards at peace with everyone (they never fight).
## - A row is "taken" when enemies stand within 8 m of its bell 20 s with no side-0 unit there: Aurivane burns it (its
##   dockers lost), masks seize it (its dockers are led to the adit; killing every mask within 10 m frees them).
## - Brannet stays at Net Lane's bell (no walk with the crew); the girl rings the Tar Steps bell when Torvald comes within
##   15 m of it after dusk. Gold: GoldBank + the pre-built Bazaar only (no posts, no caravans).

const MISSION_ID := &"e7m3"
const MISSION_TITLE := "The Outwall"
const MAP_W := 140.0
const MAP_D := 110.0
const MAP_SEED := 73

const START := Vector3(-46.0, 0.0, -28.0)
const KEEP_POS := Vector3(-54.0, 0.0, -36.0)
const HALL_POS := Vector3(-62.0, 0.0, -22.0)
const LODGES: Array[Vector3] = [Vector3(-42.0, 0.0, -42.0), Vector3(-64.0, 0.0, -30.0)]
const BAZAAR_POS := Vector3(-44.0, 0.0, -18.0)
const RALLY := Vector3(-36.0, 0.0, -24.0)
const NODES := [[&"e7m3_rope_a", Vector3(-64.0, 0.0, -44.0), 1500], [&"e7m3_rope_b", Vector3(-40.0, 0.0, -32.0), 1500],
		[&"e7m3_saltworks", Vector3(-58.0, 0.0, 6.0), 2000]]
const ROWS := {&"R1": Vector3(-30.0, 0.0, -18.0), &"R2": Vector3(-14.0, 0.0, -8.0), &"R3": Vector3(12.0, 0.0, -24.0),
		&"R4": Vector3(-28.0, 0.0, 26.0), &"R5": Vector3(14.0, 0.0, 26.0)}
const ROW_NAMES := {&"R1": "Rope Row", &"R2": "Net Lane", &"R3": "Saltpan Court", &"R4": "Low Quay", &"R5": "Tar Steps"}
const DUSK_ROWS: Array[StringName] = [&"R4", &"R5"]
const LANDINGS := {&"L1": Vector3(-56.0, 0.0, 34.0), &"L2": Vector3(-28.0, 0.0, 34.0), &"L3": Vector3(14.0, 0.0, 34.0)}
const PITS := {&"P1": Vector3(46.0, 0.0, -30.0), &"P2": Vector3(58.0, 0.0, -10.0), &"P3": Vector3(48.0, 0.0, 14.0)}
const YARD := Vector3(60.0, 0.0, -36.0)
const CHAIN := Vector3(55.0, 0.0, -38.0)
const ADIT := Vector3(64.0, 0.0, -46.0)
const TUNNEL := Vector3(66.0, 0.0, 4.0)
const GATE := Vector3(-4.0, 0.0, -42.0)
const WALL_Z := -46.0
const SEA_Z := 40.0
const SHELTER_R := 10.0
const BELL_R := 3.0
const ROW_R := 8.0
const BELL_NEED: Array[float] = [2.0, 3.0, 4.0]
const TAKE_AFTER: Array[float] = [30.0, 20.0, 15.0]
const LOST_DEFEAT: Array[int] = [34, 30, 26]
const PEOPLE_NEED: Array[int] = [26, 30, 32]
const TITHE_PER_MIN: Array[int] = [50, 40, 30]
const CAPTAIN_HP: Array[float] = [700.0, 900.0, 1200.0]
const DOCKERS_PER_ROW := 8
const ARCHON_AT := 540.0
const DUSK_AT := 990.0
const NT1_AT := 1020.0
const NT2_AT := 1110.0
const NT3_AT := 1200.0
const DAWN_AT := 1320.0
const START_CRYSTALS: Array[int] = [500, 400, 300]
const COUNT_MULT: Array[float] = [0.6, 1.0, 1.4]
const LEVEL_CAP := 8
const DEFEAT_DELAY := 3.0
const NO_SAVE_ESSENCE := 500

## [time, id, rows, spawn, default target (row id / pit id / point), kind].
const SCHEDULE := [
	[150.0, "LA1", [["flame_guard", 3], ["gilded_spear", 2]], &"L2", HALL_POS, "land"],
	[330.0, "MK1", [["masked_shade", 4], ["masked_grave_hound", 2]], &"adit", &"R3", "mask"],
	[450.0, "LA2", [["flame_guard", 4], ["ember_archer", 3], ["gilded_spear", 2]], &"L1", Vector3(-58.0, 0.0, 6.0), "land"],
	[600.0, "MK2", [["masked_shade", 5], ["masked_nightbolt", 2], ["masked_barrow_ghoul", 2]], &"tunnel", &"P2", "mask"],
	[750.0, "LA3", [["flame_guard", 5], ["ember_archer", 3], ["pyre_adept", 1], ["gilded_spear", 3]], &"L3", KEEP_POS, "land"],
	[840.0, "MK3", [["masked_shade", 4], ["masked_grave_hound", 3], ["masked_nightbolt", 2]], &"adit", &"P1", "mask"],
	[1020.0, "NT1s", [["flame_guard", 6], ["ember_archer", 4], ["cinder_arbalest", 2], ["gilded_spear", 4]], &"L2L3", &"R4", "land"],
	[1020.0, "NT1e", [["masked_shade", 6], ["masked_nightbolt", 3], ["masked_shadow_knight", 1]], &"adit", &"P1", "mask"],
	[1110.0, "NT2", [["mask_captain", 1], ["masked_shade", 4], ["masked_hexweaver", 2], ["masked_grave_hound", 2]], &"adit", &"P1", "mask"],
	[1200.0, "NT3s", [["flame_guard", 6], ["ember_archer", 4], ["pyre_adept", 2], ["kilnwarden", 1], ["gilded_spear", 4]], &"L1L2", KEEP_POS, "land"],
	[1200.0, "NT3e", [["masked_shade", 4], ["masked_nightbolt", 2], ["masked_barrow_ghoul", 2]], &"tunnel", &"P3", "mask"],
]
const PRESS := [[240.0, &"R1"], [480.0, &"R2"], [660.0, &"R3"]]
const G1 := [["masked_shade", 3], ["masked_nightbolt", 2]]
const G2 := [["masked_shade", 4], ["masked_shadow_knight", 1], ["masked_grave_hound", 2]]

const LINE_IDS: Array[String] = ["L1", "L2", "L3", "L4", "L5", "L6", "L7", "L7b", "L8", "L9", "L10", "L11", "L12", "L13", "L14", "L15", "L16", "L17", "L18", "L19", "L20", "L21", "L22", "L23", "L24", "L25", "L26", "L27", "L28", "L29", "L30", "L31"]
const DIALOGUE := [
	[&"ossavar", "The Outwall. Where the coin is earned, and never spent."],
	[&"brannet", "You're the ice-king? We've had kings before. They stand on the wall and watch."],
	[&"torvald", "Then I will stand down here. Ring your bells when I tell you, and bring your people to me."],
	[&"aldra", "The Glass Hall is open, my lord. It holds more than you think. Winter is roomy."],
	[&"brannet", "Rope Row's coming. Mind the old ones, they walk slow. Like you, no offence."],
	[&"aldra", "Crimson lanterns on the water. Aurivane burns what it cannot buy."],
	[&"brannet", "Facetguards, turned back by an ice-king. I'll be telling that one in the tavern for years."],
	[&"brannet", "The Archon's press took a whole lane. They'll dig till they drop, and nobody'll count them."],
	[&"aldra", "Men in grey masks, out of the old adit. They do not take coin. They take people."],
	[&"diamond_archon", "Ice-king. Adamarch did not open its harbour to you so you could herd fishermen."],
	[&"diamond_archon", "Guard my pits. The diamonds pay for your dragons. The Outwall can look after itself."],
	[&"torvald", "It has been looking after itself for a thousand years, Your Radiance. Look where it got them."],
	[&"aldra", "Diamond tithe. Every minute you stand there, my lord, the Archon pays. Every minute."],
	[&"diamond_archon", "Those beasts are the property of the Diamond Hall. You will answer for them."],
	[&"torvald", "Then I will answer for them. They will answer to nobody."],
	[&"brannet", "Net Lane, out! Follow the cold, it's the only thing tonight that isn't lying to us."],
	[&"brannet", "The boats are in. Two crews, sixteen souls, and the whole night coming for them."],
	[&"seraphine", "The Archon forbade this. The Hall of Silence can fine me. These are Adamarch's people too."],
	[&"torvald", "Pits to the east, fishers to the south. Aldra, I cannot stand in two places."],
	[&"aldra", "Their captain comes himself. Break his mask, my lord. I want to see what is under it."],
	[&"torvald", "Violet. And a candle sigil. Malrik, you are taking rowers from the gutter now."],
	[&"aldra", "His gift at the auction was their wages. Tonight he came back for the men."],
	[&"ossavar", "The last tide, Ice-king. The cities always send the biggest boats just before morning."],
	[&"brannet", "Half the Outwall gone! Ice-king, whatever you're guarding, it isn't us!"],
	[&"brannet", "Every bell's rung. I never heard all five at once. Sounds like a festival."],
	[&"brannet", "Dawn, and the Outwall's still here. Nobody on the wall will ever thank you. So: thank you."],
	[&"diamond_archon", "The pits held. Adamarch pays its debts, Ice-king. It never forgets them, either."],
	[&"diamond_archon", "My pits stood empty all night. Remember that I asked you, and that you chose."],
	[&"ossavar", "You did not pay for that, Ice-king. Nobody paid for that. I will remember."],
	[&"torvald", "I waited too long again. The lanes are quiet. Too quiet, for a morning."],
	[&"torvald", "Not here... not in front of them..."],
	[&"aldra", "The lanes are empty, my lord. There is nobody left to shelter."],
]
const BRIEFING_PARAGRAPHS: Array[String] = [
	"Adamarch admits nobody who has not paid in gold and proved it in blood. Everyone else lives outside the white wall, in the Outwall: dockers, net-menders, rowers, the hands that make the Diamond City rich. Tonight nobody is guarding them.",
	"Aurivane's boats are landing raiders on the quays. Adamarch's own press-gangs are emptying the lanes to dig the pits deeper. And masked men come out of the old diamond adit and take people into the dark.",
	"Torvald camps against the wall with Aldra and what is left of his army. The Diamond Archon will send her orders soon. He already knows what she will ask. He does not yet know what he will answer.",
]
const BRIEFING_LINE := "Ring a Dock Bell and its lane follows you to the shelter by your Keep."
const HINT_START := "Ring a Dock Bell: hold Torvald beside it (3 s). Its lane walks to the shelter by your Keep. Raiders hunt anyone walking."
const MSG_MASKS := "Masked men out of the old adit"
const MSG_DUSK := "The fishing crews are home. The Night Tide comes at 17:00."
const MSG_EMPTYING := "The Outwall is emptying: 10 more lost and the night is lost"
const MSG_BELL_REFUSED := "The lane won't open its doors with raiders in the street"
const MSG_BURNT := "%s burns"
const MSG_SEIZED := "Masks take %s into the dark"
const MSG_PRESSED := "The Archon's press takes %s"
const MSG_TITHE := "The pits pay their tithe while you hold them (+%d gold / min each)"
const HINT_MAMMOTHS := "Two hauling mammoths are chained in the Hauling Yard: hold Torvald at the chain post (4 s) to free them."

## Read only.
var sheltered := 0
var lost := 0
var pressed := 0
var bells_rung: Array[StringName] = []
var rows_taken: Array[StringName] = []
var row_people := {}                  ## row id -> dockers still inside (not out yet)
var walkers: Array = []               ## walking dockers (to the shelter or led away)
var tithe_paid := 0
var pits_held := {}                   ## pit id -> bool (now)
var mammoths: Array = []
var mammoths_free := false
var captain: Unit
var seraphine: Unit
var brannet: Unit
var victory_time := -1.0
var waves_fired: Array[String] = []

var _tick := 0.0
var _fast := 0.0
var _bell_progress := {}
var _take_clock := {}
var _chain_progress := 0.0
var _tithe_t := 0.0
var _gangs: Array = []                ## [units, row, state, until]
var _lost_at_dawn := 0


# ---------------------------------------------------------------- setup

func _init() -> void:
	super()
	trade_enabled = true
	enemy_kingdom = &"fire"
	line_ids = LINE_IDS.duplicate()
	dialogue_lines = DIALOGUE
	briefing_paragraphs = BRIEFING_PARAGRAPHS.duplicate()
	define_objectives([[&"obj_bells", "primary"], [&"obj_dawn", "primary"], [&"obj_people", "primary"],
			[&"obj_torvald", "primary"], [&"sec_people", "secondary"], [&"sec_pits", "secondary"],
			[&"sec_mammoths", "secondary"], [&"sec_mask", "secondary"]])
	for id: StringName in ROWS:
		row_people[id] = DOCKERS_PER_ROW


func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	MissionE7Base.e7_config(c, 3)
	c.mission_id = MISSION_ID
	c.title = MISSION_TITLE
	c.count_mult = COUNT_MULT.duplicate()
	c.easy_skip_types = [&"cinder_arbalest", &"kilnwarden", &"masked_shadow_knight"]
	c.defeat_on_keep_lost = true
	c.keep_lost_message = "The Glass Hall has fallen."
	c.start_tiers = {Unit.Team.PLAYER: 3}
	c.helper_start_called = true
	c.start_level = 5
	c.start_spell_points = 4
	c.start_spells = [&"rime_bolt"]
	c.level_cap = LEVEL_CAP
	c.start_crystals = START_CRYSTALS.duplicate()
	c.start_essence = 150
	c.defeat_delay = DEFEAT_DELAY
	c.victory_banner = "VICTORY\nDawn over the Outwall"
	c.defeat_banner = "DEFEAT"
	c.rewards = CampaignState.MISSION_REWARDS.get(MISSION_ID, {})
	c.spotlight = {"id": &"war_mammoth", "trigger": &"manual", "key_hint": "Free them at the Hauling Yard",
			"card": "War Mammoth. A titan of the far north: it walks through a line like snow through a fence."}
	return c


func _map_size() -> Vector2:
	return Vector2(MAP_W, MAP_D)


func _player_start() -> Vector3:
	return START


func _title_line() -> String:
	return "Episode 7, Mission 3: %s" % MISSION_TITLE


func _ground_spots() -> Array[Vector4]:
	var out: Array[Vector4] = [Vector4(KEEP_POS.x, KEEP_POS.z, 12.0, 0.0)]
	for id: StringName in PITS:
		out.append(Vector4((PITS[id] as Vector3).x, (PITS[id] as Vector3).z, 6.0, 1.0))
	return out


func _ready() -> void:
	super()
	tint_light(Color(0.62, 0.68, 0.95), 0.55, -24.0, Color(0.36, 0.38, 0.52), Color(0.10, 0.12, 0.24), Color(0.42, 0.36, 0.48))
	var ev := get_node_or_null(^"/root/Events")
	if ev and ev.has_signal(&"unit_died"):
		ev.unit_died.connect(_on_any_unit_died)


# ---------------------------------------------------------------- seats

func start_position(_team: int) -> Vector3:
	return START


func base_center(team: int) -> Vector3:
	return KEEP_POS if team == Unit.Team.PLAYER else ADIT


func respawn_point(team: int) -> Vector3:
	var k := keep_of(team)
	return k.spawn_point() if k else KEEP_POS + Vector3(5.0, 0.0, 5.0)


func node_of(team: int, suffix: String) -> CrystalNode:
	if team != Unit.Team.PLAYER:
		return null
	var id: StringName = {"a": &"e7m3_rope_a", "b": &"e7m3_rope_b", "mid": &"e7m3_saltworks"}.get(suffix, &"")
	var v: Variant = crystal_nodes.get(id)
	if v == null or not is_instance_valid(v):
		return null
	var n := v as CrystalNode
	return n if n != null and not n.is_depleted() else null


func natural_hall_spot(_team: int) -> Vector3:
	return Vector3(-50.0, 0.0, 8.0)


func rich_hall_spot(_team: int) -> Vector3:
	return Vector3.INF


func market_slot(_team: int) -> Vector3:
	return BAZAAR_POS


func tower_slot(_team: int, _which: StringName) -> Vector3:
	return Vector3.INF


# ---------------------------------------------------------------- the map

func _build_map() -> void:
	var clearings: Array = [[START, 6.0], [KEEP_POS, 16.0], [RALLY, 6.0], [YARD, 9.0], [ADIT, 6.0], [TUNNEL, 5.0], [GATE, 6.0]]
	for row: Array in NODES:
		clearings.append([row[1], 7.0])
	for id: StringName in ROWS:
		clearings.append([ROWS[id], 9.0])
	for id: StringName in PITS:
		clearings.append([PITS[id], 7.0])
	for id: StringName in LANDINGS:
		clearings.append([LANDINGS[id], 7.0])
	var lanes: Array = []
	for id: StringName in ROWS:
		lanes.append([KEEP_POS, ROWS[id], 4.0])
	for id: StringName in PITS:
		lanes.append([ROWS[&"R3"], PITS[id], 4.0])
		lanes.append([ROWS[&"R5"], PITS[id], 4.0])
	for id: StringName in LANDINGS:
		lanes.append([LANDINGS[id], KEEP_POS, 4.0])
	lanes.append([ADIT, ROWS[&"R3"], 4.0])
	lanes.append([TUNNEL, ROWS[&"R5"], 4.0])
	scatter_props(MAP_SEED, clearings, lanes, 4, 16, 64.0)
	bound_wall(Vector3(-70.0, 0.0, WALL_Z), Vector3(34.0, 0.0, WALL_Z), 9.0)
	bound_wall(Vector3(34.0, 0.0, WALL_Z), Vector3(40.0, 0.0, -55.0), 9.0)
	bound_wall(Vector3(-70.0, 0.0, SEA_Z), Vector3(70.0, 0.0, SEA_Z), 1.5)
	box_prop(Vector3(-18.0, 0.0, WALL_Z - 1.0), Vector3(104.0, 9.0, 4.0), Color(0.90, 0.90, 0.88))
	ground_disc(Vector3(0.0, -0.02, SEA_Z + 8.0), 72.0, Color(0.10, 0.18, 0.28, 0.85), 0.0)
	for id: StringName in ROWS:
		var p: Vector3 = ROWS[id]
		for k in 3:
			var a := TAU * float(k) / 3.0 + 0.5
			box_prop(p + Vector3(cos(a) * 5.5, 0.0, sin(a) * 5.5), Vector3(3.0, 2.4, 2.6), Color(0.46, 0.38, 0.30), a)
		box_prop(p, Vector3(0.5, 2.4, 0.5), Color(0.72, 0.60, 0.30))   # the bell frame
	for id: StringName in PITS:
		ground_disc(PITS[id], 6.0, Color(0.95, 0.85, 0.45, 0.28), 0.04)
	box_prop(CHAIN, Vector3(0.5, 1.6, 0.5), Color(0.40, 0.40, 0.42))
	for row: Array in NODES:
		_add_crystal_node(StringName(row[0]), row[1], int(row[2]))
	keep = build_grid.spawn_complete(BuildingType.find("ice_keep"), KEEP_POS, Unit.Team.PLAYER) as Keep
	if keep:
		keep.name = "GlassHall"
		seat_keeps[Unit.Team.PLAYER] = keep
	seat_bases[Unit.Team.PLAYER] = KEEP_POS
	seat_starts[Unit.Team.PLAYER] = START
	build_grid.spawn_complete(BuildingType.find("ice_barracks"), HALL_POS, Unit.Team.PLAYER)
	for p in LODGES:
		build_grid.spawn_complete(BuildingType.find("ice_lodge"), p, Unit.Team.PLAYER)
	build_grid.spawn_complete(BuildingType.find("ice_market"), BAZAAR_POS, Unit.Team.PLAYER)


# ---------------------------------------------------------------- start state

func _on_navigation_ready() -> void:
	read_save(&"e7m2")
	var diff := clampi(mission_difficulty, 0, 2)
	_setup_champions()
	hero = _make_wizard(Unit.Team.PLAYER)
	_spawn(hero, Unit.Team.PLAYER, START)
	_claim_wizard(hero, Unit.Team.PLAYER)
	ItemDrops.ensure_inventory(hero)
	apply_splinter(hero)
	carry_torvald_essence(NO_SAVE_ESSENCE)
	for i in 6:
		var w := _spawn(make_unit("rime_hauler"), Unit.Team.PLAYER, KEEP_POS + Vector3(4.0 + i * 1.2, 0.0, -2.0))
		w.call(&"command_gather", node_of(Unit.Team.PLAYER, "a" if i < 3 else "b"))
	var army := [["rimeshield", 6 + (2 if diff == 0 else 0)], ["shardcaster", 4], ["rime_seer", 2], ["rimecarver", 1],
			["shardguard", 1 if diff == 2 else 2]]
	var k := 0
	for row: Array in army:
		for j in int(row[1]):
			_spawn(make_unit(String(row[0])), Unit.Team.PLAYER, RALLY + Vector3((k % 5) * 1.6 - 3.2, 0.0, (k / 5) * 1.7))
			k += 1
	brannet = story_npc("brannet_story", ROWS[&"R2"] + Vector3(1.5, 0.0, 1.5))
	guard_life(brannet)
	for i in 2:
		var m := make_unit("war_mammoth")
		_spawn(m, Unit.Team.NEUTRAL, YARD + Vector3(i * 4.0 - 2.0, 0.0, 2.0))
		mark_scripted(m)
		set_truce([m], true, Unit.TRUCE_ALL)
		set_dormant(m, true)
		var mm := m.get_model()
		if mm:
			mm.scale = Vector3.ONE * 1.6
		mammoths.append(m)
	spawn_rows(G1, ADIT + Vector3(-2.0, 0.0, 2.0), 2.5, Unit.Team.ENEMY, true)
	spawn_rows(G2, YARD + Vector3(-2.0, 0.0, 0.0), 3.0, Unit.Team.ENEMY, true)
	for id: StringName in ROWS:
		fog.reveal(Unit.Team.PLAYER, ROWS[id], 9.0)
	for id: StringName in PITS:
		fog.reveal(Unit.Team.PLAYER, PITS[id], 7.0)
	var gb := GoldBank.for_team(Unit.Team.PLAYER)
	if gb:
		gb.gold = 0
		gb.changed.emit(0)
	begin_mission([&"obj_bells", &"obj_dawn", &"obj_people", &"obj_torvald", &"sec_people", &"sec_mammoths"])
	selection.select_units([hero])


func _intro() -> void:
	fire_once(&"E1")
	play_cutscene(&"e7m3_outwall", _outwall_end)


func _outwall_end() -> void:
	for id in ["L1", "L2", "L3", "L4"]:
		say_l(id)
	if hud:
		hud.show_message(HINT_START, 10.0)
		after(20.0, func() -> void:
			if hud and not is_ending():
				hud.show_message(HINT_MAMMOTHS, 8.0))
	if camera_rig and hero_alive():
		camera_rig.focus_on(hero.global_position)


# ---------------------------------------------------------------- briefing, objectives

func briefing() -> Dictionary:
	return {
		"title": _title_line(),
		"paragraphs": BRIEFING_PARAGRAPHS.duplicate(),
		"objectives": [objective_text(&"obj_bells", false), objective_text(&"obj_dawn", false), BRIEFING_LINE],
		"rule": Loc.sink(objective_text(&"obj_people", false)),
	}


func lost_limit() -> int:
	return int(by_difficulty(LOST_DEFEAT))


func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_bells":
			if with_counter:
				return "Ring the Dock Bells (%d / 5): sheltered %d, lost %d, pressed %d (of 40)" % [bells_rung.size(), sheltered, lost, pressed]
			return "Ring the Dock Bells"
		&"obj_dawn":
			if with_counter:
				return "Hold the Outwall until dawn (%s)" % mmss(DAWN_AT - mission_time())
			return "Hold the Outwall until dawn"
		&"obj_people":
			if with_counter:
				return "Do not lose %d of the Outwall's 40 people (lost %d)" % [lost_limit(), lost]
			return "Do not lose %d of the Outwall's 40 people" % lost_limit()
		&"obj_torvald":
			return "Torvald must survive"
		&"sec_people":
			return "Shelter %d of the Outwall's people" % int(by_difficulty(PEOPLE_NEED))
		&"sec_pits":
			if with_counter:
				return "Hold the Diamond Archon's pits at dawn (%d / 3)" % _held_count()
			return "Hold the Diamond Archon's pits at dawn"
		&"sec_mammoths":
			return "Free the hauling mammoths"
		&"sec_mask":
			return "Unmask the Mask Captain"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_bells":
			var pos: Array = []
			for rid: StringName in ROWS:
				if not bells_rung.has(rid) and not rows_taken.has(rid) and (not DUSK_ROWS.has(rid) or mission_time() >= DUSK_AT):
					pos.append(ROWS[rid])
			return {"counter": bells_rung.size(), "goal": 5, "positions": pos}
		&"obj_people":
			return {"counter": lost, "goal": lost_limit()}
		&"sec_pits":
			return {"counter": _held_count(), "goal": 3, "positions": PITS.values()}
		&"sec_mammoths":
			return {"positions": [CHAIN]}
	return {}


func _held_count() -> int:
	var n := 0
	for id: StringName in pits_held:
		if bool(pits_held[id]):
			n += 1
	return n


# ---------------------------------------------------------------- bells, dockers, the shelter

func _tick_bells(dt: float) -> void:
	var need := float(by_difficulty(BELL_NEED))
	for rid: StringName in ROWS:
		if bells_rung.has(rid) or rows_taken.has(rid):
			continue
		if DUSK_ROWS.has(rid) and mission_time() < DUSK_AT:
			continue
		if rid == &"R5" and hero_alive() and _flat(hero.global_position, ROWS[rid]) < 15.0 and has_fired(&"E10"):
			_ring(rid)   # the girl rings it herself
			continue
		var p := channel_step(float(_bell_progress.get(rid, 0.0)), ROWS[rid], BELL_R, need, dt, MSG_BELL_REFUSED)
		_bell_progress[rid] = p
		if p >= need:
			_ring(rid)


func _ring(rid: StringName) -> void:
	if bells_rung.has(rid):
		return
	bells_rung.append(rid)
	flash_ring(ROWS[rid], 4.0)
	if fire_once(&"E2"):
		say_l("L5")
	if rid == &"R2" and fire_once(&"E9"):
		say_l("L15")
	if bells_rung.size() >= 5 and fire_once(&"E16"):
		say_l("L24")
		set_objective(&"obj_bells", "done")
	_release_row(rid, &"shelter")


## The row's dockers come out: walking to the shelter (`mode` shelter) or led to the adit (captive).
func _release_row(rid: StringName, mode: StringName) -> void:
	var n := int(row_people.get(rid, 0))
	row_people[rid] = 0
	for i in n:
		var d := make_unit("outwall_docker")
		var a := TAU * float(i) / maxf(1.0, float(n))
		_spawn(d, Unit.Team.PLAYER, (ROWS[rid] as Vector3) + Vector3(cos(a) * 2.0, 0.0, sin(a) * 2.0))
		mark_scripted(d)
		d.set_meta(&"e7_mode", mode)
		d.died.connect(_on_docker_died)
		walkers.append(d)
		d.command_move(KEEP_POS if mode == &"shelter" else ADIT)


func _on_docker_died(u: Unit) -> void:
	walkers.erase(u)
	if not is_ending():
		_add_lost(1)


func _add_lost(n: int) -> void:
	lost += n
	if lost >= 20 and fire_once(&"E15"):
		say_l("L23")
		if hud:
			hud.show_message(MSG_EMPTYING, 6.0)
	if lost >= lost_limit() and fire_once(&"E21"):
		say_l("L31")
		set_objective(&"obj_people", "failed")
		lose(DEFEAT_DELAY)


func _tick_walkers() -> void:
	for v: Variant in walkers.duplicate():
		if not is_instance_valid(v) or not (v as Unit).is_alive():
			walkers.erase(v)
			continue
		var d := v as Unit
		var mode: StringName = d.get_meta(&"e7_mode", &"shelter")
		if mode == &"shelter":
			if _flat(d.global_position, KEEP_POS) < SHELTER_R:
				walkers.erase(d)
				sheltered += 1
				var bank := EssenceBank.for_team(Unit.Team.PLAYER)
				if bank:
					bank.add(3)
				d.leave_map()
			elif not d.has_move_order():
				d.command_move(KEEP_POS)
		elif mode == &"captive":
			if _flat(d.global_position, ADIT) < 5.0:
				walkers.erase(d)
				_add_lost(1)
				d.leave_map()
			elif _masks_near(d.global_position, 10.0) == 0:
				d.set_meta(&"e7_mode", &"shelter")
				d.command_move(KEEP_POS)
			elif not d.has_move_order():
				d.command_move(ADIT)
		elif mode == &"pressed":
			if _flat(d.global_position, GATE) < 4.0:
				walkers.erase(d)
				d.leave_map()


static func is_mask(u: Unit) -> bool:
	return u != null and u.unit_type != null and (String(u.unit_type.id).begins_with("masked_") or u.unit_type.id == &"mask_captain")


func _masks_near(at: Vector3, r: float) -> int:
	var n := 0
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u and u.is_alive() and int(u.team) == Unit.Team.ENEMY and is_mask(u) and _flat(u.global_position, at) <= r:
			n += 1
	return n


func _side0_near(at: Vector3, r: float) -> bool:
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u and u.is_alive() and int(u.team) == Unit.Team.PLAYER and not is_dormant(u) and u.is_commandable() \
				and not u.is_worker() and _flat(u.global_position, at) <= r:
			return true
	return false


## A row with enemies at its bell for TAKE_AFTER s and no side-0 soldier there is taken (burnt / seized).
func _tick_rows(dt: float) -> void:
	for rid: StringName in ROWS:
		if bells_rung.has(rid) or rows_taken.has(rid) or int(row_people.get(rid, 0)) <= 0:
			continue
		if DUSK_ROWS.has(rid) and mission_time() < DUSK_AT:
			continue
		var at: Vector3 = ROWS[rid]
		if enemies_near(at, ROW_R) > 0 and not _side0_near(at, ROW_R):
			_take_clock[rid] = float(_take_clock.get(rid, 0.0)) + dt
		else:
			_take_clock[rid] = 0.0
		if float(_take_clock[rid]) >= float(by_difficulty(TAKE_AFTER)):
			rows_taken.append(rid)
			var name_s := String(ROW_NAMES[rid])
			if _masks_near(at, ROW_R) > 0:
				if hud:
					hud.show_message(MSG_SEIZED % name_s, 5.0)
				_release_row(rid, &"captive")
			else:
				if hud:
					hud.show_message(MSG_BURNT % name_s, 5.0)
				var n := int(row_people[rid])
				row_people[rid] = 0
				_add_lost(n)


# ---------------------------------------------------------------- press-gangs

func _press_gang(rid: StringName) -> void:
	if bells_rung.has(rid) or rows_taken.has(rid) or int(row_people.get(rid, 0)) <= 0:
		return
	var units := _gang_units()
	for u: Variant in units:
		(u as Unit).command_move(ROWS[rid])
	_gangs.append([units, rid, "walk", mission_time() + 60.0])


func _gang_units() -> Array:
	var out: Array = []
	for i in 4:
		var u := make_unit("facetguard")
		_spawn(u, Unit.Team.NEUTRAL, GATE + Vector3(i * 1.2 - 1.8, 0.0, 1.0))
		mark_scripted(u)
		set_truce([u], true, Unit.TRUCE_ALL)
		out.append(u)
	return out


func _tick_gangs() -> void:
	for g: Array in _gangs.duplicate():
		var units: Array = (g[0] as Array).filter(func(x: Variant) -> bool: return is_instance_valid(x) and (x as Unit).is_alive())
		if units.is_empty():
			_gangs.erase(g)
			continue
		var rid: StringName = g[1]
		match String(g[2]):
			"walk":
				if bells_rung.has(rid) or rows_taken.has(rid):
					g[2] = "leave"
				elif _flat((units[0] as Unit).global_position, ROWS[rid]) < 6.0 or mission_time() > float(g[3]):
					if _side0_near(ROWS[rid], ROW_R) or (hero_alive() and _flat(hero.global_position, ROWS[rid]) < ROW_R):
						if fire_once(&"E4"):
							say_l("L7")
						if has_fired(&"E6"):
							_tithe_t -= 15.0   # "Her Radiance notes your interference"
						g[2] = "leave"
					else:
						var n := int(row_people.get(rid, 0))
						row_people[rid] = 0
						rows_taken.append(rid)
						pressed += n
						if fire_once(&"E20"):
							say_l("L7b")
						if hud:
							hud.show_message(MSG_PRESSED % String(ROW_NAMES[rid]), 5.0)
						g[2] = "leave"
				if String(g[2]) == "leave":
					for u: Variant in units:
						(u as Unit).command_move(GATE)
			"leave":
				for u: Variant in units:
					if _flat((u as Unit).global_position, GATE) < 4.0:
						(u as Unit).leave_map()


# ---------------------------------------------------------------- the pits, the mammoths

func _tick_pits(dt: float) -> void:
	for pid: StringName in PITS:
		var at: Vector3 = PITS[pid]
		pits_held[pid] = _side0_near(at, 6.0) and enemies_near(at, 6.0) == 0
	if not has_fired(&"E6"):
		return
	_tithe_t += dt
	if _tithe_t >= 15.0:
		_tithe_t -= 15.0
		var per := int(by_difficulty(TITHE_PER_MIN)) / 4
		var n := _held_count()
		if n > 0:
			add_gold(per * n)
			tithe_paid += per * n
			if fire_once(&"E7"):
				say_l("L12")


func _tick_chain(dt: float) -> void:
	if mammoths_free:
		return
	_chain_progress = channel_step(_chain_progress, CHAIN, 3.0, 4.0, dt, MSG_BELL_REFUSED)
	if _chain_progress >= 4.0:
		mammoths_free = true
		fire_once(&"E8")
		for m: Variant in mammoths:
			var u := m as Unit
			if is_instance_valid(u) and u.is_alive():
				set_truce([u], false, Unit.TRUCE_ALL)
				set_dormant(u, false)
				u.team = Unit.Team.PLAYER
		say_l("L13")
		say_l("L14")
		set_objective(&"sec_mammoths", "done")
		show_spotlight()


# ---------------------------------------------------------------- waves

func _spawn_point(key: StringName) -> Array[Vector3]:
	match key:
		&"adit":
			return [ADIT]
		&"tunnel":
			return [TUNNEL]
		&"L2L3":
			return [LANDINGS[&"L2"], LANDINGS[&"L3"]]
		&"L1L2":
			return [LANDINGS[&"L1"], LANDINGS[&"L2"]]
	return [LANDINGS.get(key, ADIT)]


func _tick_waves() -> void:
	var t := mission_time()
	for row: Array in SCHEDULE:
		if t < float(row[0]) or not fire_once(StringName(row[1])):
			continue
		var id := String(row[1])
		waves_fired.append(id)
		var rows: Array = row[2]
		if id == "NT3e" and objective_state("sec_mask") == "done":
			rows = _cut(rows, 0.4)
		if id == "NT1e" and mammoths_free:
			rows = rows + [["masked_shadow_knight", 1]]
		var spots := _spawn_point(row[3])
		var share := spots.size()
		for i in share:
			var part: Array = rows if share == 1 else _half(rows, i)
			var out := spawn_rows(part, spots[i], 0.0, Unit.Team.ENEMY, false, true)
			for v: Variant in out:
				var u := v as Unit
				u.set_meta(&"e7_default", row[4])
				order_wave(u, &"raid3", _target_point(row[4]))
				if u.unit_type and u.unit_type.id == &"mask_captain":
					captain = u
					u.add_modifier(&"mission:e7_difficulty", {"max_hp": float(by_difficulty(CAPTAIN_HP)) - 900.0})
					u.hp = u.max_hp
					u.died.connect(_on_captain_died)
		match id:
			"LA1":
				fire_once(&"E3")
				say_l("L6")
			"MK1":
				fire_once(&"E5")
				say_l("L8")
				if hud:
					hud.show_message(MSG_MASKS, 5.0)
			"NT2":
				fire_once(&"E12")
				say_l("L19")
				set_objective(&"sec_mask", "active")
			"NT3s":
				fire_once(&"E14")
				say_l("L22")
	for p: Array in PRESS:
		if t >= float(p[0]) and fire_once(StringName("PG_%s" % p[1])):
			_press_gang(p[1])
	if t >= ARCHON_AT and fire_once(&"E6"):
		for id in ["L9", "L10", "L11"]:
			say_l(id)
		set_objective(&"sec_pits", "active")
		if hud:
			hud.show_message(MSG_TITHE % int(by_difficulty(TITHE_PER_MIN)), 8.0)
	if t >= DUSK_AT and fire_once(&"E10"):
		play_cutscene(&"e7m3_boats", _boats_end)
	if t >= NT1_AT and fire_once(&"E11"):
		_seraphine_arrives()
	if t >= DAWN_AT:
		_dawn()


func _half(rows: Array, i: int) -> Array:
	var out: Array = []
	for r: Array in rows:
		var n := int(r[1])
		var a := n / 2 if i == 0 else n - n / 2
		if a > 0:
			out.append([r[0], a])
	return out


func _cut(rows: Array, share: float) -> Array:
	var out: Array = []
	for r: Array in rows:
		out.append([r[0], int(r[1]) - int(floor(float(r[1]) * share))])
	return out


func _target_point(t: Variant) -> Vector3:
	if t is Vector3:
		return t
	if ROWS.has(t):
		return ROWS[t]
	if PITS.has(t):
		return PITS[t]
	return KEEP_POS


## Raiders: the nearest walking docker within 20 m, else the nearest row still holding people (landings) or the default
## (masks go to their pit first), else the keep.
func _refresh_e7_mode(u: Unit, mode: StringName, _hero_at: Vector3) -> bool:
	if mode != &"raid3":
		return false
	if u.attack_target != null and is_instance_valid(u.attack_target) and u.attack_target is Unit:
		return true
	var prey: Unit = null
	var best := 20.0
	for v: Variant in walkers:
		if not is_instance_valid(v):
			continue
		var d := v as Unit
		if d.get_meta(&"e7_mode", &"shelter") == &"captive":
			continue
		var dd := _flat(d.global_position, u.global_position)
		if dd < best:
			best = dd
			prey = d
	if prey:
		u.command_attack(prey)
		return true
	var goal := _target_point(u.get_meta(&"e7_default", KEEP_POS))
	var default_v: Variant = u.get_meta(&"e7_default", KEEP_POS)
	if PITS.has(default_v) and is_mask(u):
		if _flat(u.global_position, goal) < 5.0 and enemies_near(goal, 6.0) > 0 and not _side0_near(goal, 8.0):
			var row := _nearest_row(u.global_position, true)
			u.set_meta(&"e7_default", row if row != Vector3.INF else KEEP_POS)
			return true
	elif not is_mask(u) or not PITS.has(default_v):
		var r := _nearest_row(u.global_position, false)
		if r != Vector3.INF:
			goal = r
	if goal == Vector3.INF:   # C6-8: every row rung / taken and no default left: the keep
		goal = KEEP_POS
	if not u.is_attack_moving() or _flat(u.global_position, goal) > 4.0 and u.attack_target == null:
		if _flat(u.global_position, goal) > 3.0:
			u.command_attack_move(goal)
	return true


func _nearest_row(at: Vector3, any: bool) -> Vector3:
	var best := Vector3.INF
	var d := 1.0e9
	for rid: StringName in ROWS:
		if bells_rung.has(rid) or rows_taken.has(rid) or int(row_people.get(rid, 0)) <= 0:
			continue
		if DUSK_ROWS.has(rid) and mission_time() < DUSK_AT and not any:
			continue
		var dd := _flat(ROWS[rid], at)
		if dd < d:
			d = dd
			best = ROWS[rid]
	return best


func _boats_end() -> void:
	say_l("L16")
	if hud:
		hud.show_message(MSG_DUSK, 6.0)
	for rid: StringName in DUSK_ROWS:
		ground_disc(ROWS[rid], 2.0, Color(1.0, 0.85, 0.5, 0.5), 0.06)


func _seraphine_arrives() -> void:
	seraphine = make_unit("seraphine_story")
	_spawn(seraphine, Unit.Team.PLAYER, ROWS[&"R4"] + Vector3(2.0, 0.0, 4.0))
	mark_scripted(seraphine)
	seraphine.set_meta(META_HOME, seraphine.global_position)
	_guards.append(seraphine)
	guard_life(seraphine, _on_seraphine_down)
	var guards: Array = []
	for i in 4:
		var f := make_unit("facetguard")
		_spawn(f, Unit.Team.PLAYER, ROWS[&"R4"] + Vector3(i * 1.4 - 2.0, 0.0, 6.0))
		mark_scripted(f)
		f.set_meta(META_HOME, f.global_position)
		_guards.append(f)
		guards.append(f)
	say_l("L17")
	say_l("L18")


## Seraphine falls: she kneels 10 s, then stands at half HP (named methods: the pause survives a save).
func _on_seraphine_down(u: Unit) -> void:
	set_dormant(u, true)
	after(10.0, _seraphine_up)


func _seraphine_up() -> void:
	if seraphine and is_instance_valid(seraphine):
		seraphine.hp = seraphine.max_hp * 0.5
		set_dormant(seraphine, false)


func _on_captain_died(_u: Unit) -> void:
	if is_ending() or not fire_once(&"E13"):
		return
	set_objective(&"sec_mask", "done")
	set_mission_flag("e7m3_mask", true)
	play_cutscene(&"e7m3_unmask", func() -> void:
		say_l("L20")
		say_l("L21"))


func _on_any_unit_died(_u: Node) -> void:
	pass


# ---------------------------------------------------------------- the end

func _dawn() -> void:
	if is_ending() or not fire_once(&"E17"):
		return
	victory_time = mission_time()
	var people := sheltered >= int(by_difficulty(PEOPLE_NEED))
	var pits := has_fired(&"E6") and _held_count() >= 3
	set_objective(&"sec_people", "done" if people else "failed")
	if objective_state("sec_pits") == "active":
		set_objective(&"sec_pits", "done" if pits else "failed")
	if objective_state("sec_mask") == "active":
		set_objective(&"sec_mask", "failed")
	if objective_state("sec_mammoths") == "active":
		set_objective(&"sec_mammoths", "failed")
	if objective_state("obj_bells") == "active":
		set_objective(&"obj_bells", "failed")
	set_objective(&"obj_dawn", "done")
	set_objective(&"obj_people", "done")
	set_objective(&"obj_torvald", "done")
	var alive := 0
	for m: Variant in mammoths:
		if mammoths_free and is_instance_valid(m) and (m as Unit).is_alive():
			alive += 1
	set_mission_flag("e7m3_sheltered", sheltered)
	set_mission_flag("e7m3_mammoths", alive)
	set_mission_flag("e7m3_time", int(victory_time))
	var bonus := 0
	if people:
		bonus += 300
	if objective_state("sec_mask") == "done":
		bonus += 150
	if mammoths_free:
		bonus += 100
	record_torvald_essence(bonus)
	clear_waves()
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == Unit.Team.ENEMY:
			u.leave_map()
	play_cutscene(&"e7m3_dawn", func() -> void:
		if people:
			say_l("L25")
		say_l("L26" if pits else "L27")
		say_l("L28")
		if not people:
			say_l("L29")
		win(1.0))


func _on_player_hero_fell() -> void:
	fire_once(&"E18")
	say_l("L30")
	set_objective(&"obj_torvald", "failed")
	super()


# ---------------------------------------------------------------- save / load

func save_state(ids: Dictionary = {}) -> Dictionary:
	var d := super(ids)
	var rung: Array = []
	for r: StringName in bells_rung:
		rung.append(String(r))
	var taken: Array = []
	for r: StringName in rows_taken:
		taken.append(String(r))
	var people := {}
	for r: StringName in row_people:
		people[String(r)] = row_people[r]
	d["e7m3"] = {"sheltered": sheltered, "lost": lost, "pressed": pressed, "rung": rung, "taken": taken,
			"people": people, "tithe": tithe_paid, "free": mammoths_free}
	return d


func load_state(d: Dictionary, nodes: Dictionary = {}) -> void:
	super(d, nodes)
	var m: Dictionary = d.get("e7m3", {})
	sheltered = int(m.get("sheltered", 0))
	lost = int(m.get("lost", 0))
	pressed = int(m.get("pressed", 0))
	bells_rung.clear()
	for r: Variant in m.get("rung", []):
		bells_rung.append(StringName(str(r)))
	rows_taken.clear()
	for r: Variant in m.get("taken", []):
		rows_taken.append(StringName(str(r)))
	var people: Dictionary = m.get("people", {})
	for r: Variant in people:
		row_people[StringName(str(r))] = int(people[r])
	tithe_paid = int(m.get("tithe", 0))
	mammoths_free = bool(m.get("free", false))
	walkers.clear()
	_restore_gangs()
	# Review 2026-10-10 #3: guards and hooks set mid-mission are not part of the rebuilt start.
	if brannet and is_instance_valid(brannet):
		guard_life(brannet)
	if seraphine and is_instance_valid(seraphine):
		guard_life(seraphine, _on_seraphine_down)
	if captain and is_instance_valid(captain) and captain.is_alive() and not captain.died.is_connected(_on_captain_died):
		captain.died.connect(_on_captain_died)


## C6-5: press-gangs restored by the load (`_gangs` is a saved variable) keep their state: dead units dropped, the order
## given again (walk -> their row, leave -> the gate).
func _restore_gangs() -> void:
	var kept: Array = []
	for v: Variant in _gangs:
		var g := v as Array
		if g == null or g.size() < 4:
			continue
		var units: Array = (g[0] as Array).filter(func(x: Variant) -> bool: return x is Unit and is_instance_valid(x) and (x as Unit).is_alive())
		if units.is_empty():
			continue
		var rid := StringName(str(g[1]))
		var state := String(g[2]) if String(g[2]) == "walk" and ROWS.has(rid) else "leave"
		for u: Variant in units:
			(u as Unit).command_move(ROWS[rid] if state == "walk" else GATE)
		kept.append([units, rid, state, float(g[3])])
	_gangs = kept


func save_block_reason() -> String:
	if not walkers.is_empty():
		return "Not while the Outwall's people are walking"
	return super()


# ---------------------------------------------------------------- every frame

func _physics_process(delta: float) -> void:
	super(delta)
	if not match_started or game_over or world_is_held or save_restoring:
		return
	tick_scripted(delta)
	if is_ending():
		return
	_fast -= delta
	if _fast <= 0.0:
		_fast = 0.25
		_tick_bells(0.25)
		_tick_chain(0.25)
		_tick_rows(0.25)
		_tick_pits(0.25)
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.5
		_tick_waves()
		_tick_walkers()
		_tick_gangs()
		objectives_changed.emit()
		if hud and mission_hud == null:
			hud.set_objective(_objective_text())
