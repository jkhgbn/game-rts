class_name MissionE7_02
extends MissionE7Base
## Episode 7, mission 2 "First Blood, and No Further" (docs/design/mission-e7-02.md): the morning after the broken
## Laurel. Torvald alone (Seraphine beside him) breaks the Sun Barricade, takes the Tollrock, finds three clues (the
## knives, the ledger, the herald), settles the Laurel against Dacian (first blood: below 75 % loses), then keeps Dacian
## alive through Mother Hush's ambush. Opens the Citadel, Aldra as the callable helper and the Shardguard.
## Spotlight: Aldra (first call).
##
## Built deviations (2026-10-09, from the spec):
## - Two Harbours = Crown Hollow re-dressed (MissionE7Base); Vessa holds the north-east keep (the ENEMY seat, no
##   Commander: her quarter only guards), the Malrik / Ysolde quarters are empty ground.
## - The Sun Barricade is two gatehouses (Ember Hall shells, trains nothing) at the west bank's two ways onto the isle
##   (the West Crown Bridge and the north-west Crown Steps); while one stands, side-0 units are pushed off the isle (a
##   soft wall, the Laurel-ring rule). The island Ember Spire covers the bridge one.
## - Clue C3 (the herald) and the boxes are on the east bank (Crown Hollow's south-east quarter).
## - Story floor: Dacian comes to the sand at the afternoon bell (DUEL_FLOOR, 17:00 normal) even when the truth is found
##   earlier ("The Laurel is fought at the afternoon bell").
## - The duel is auto-attacks and spells only (no Sun Cleave / Second Wind); at E12 Aurivane stands down (its field units
##   walk home and leave, Vessa goes back to her keep at peace) instead of the D8 truce brawl; Hush has boss numbers and
##   flees at 25 % (no Blink Strike / Night of Knives; the Shardguard hint stays).

const MISSION_ID := &"e7m2"
const MISSION_TITLE := "First Blood, and No Further"

const BARRICADES: Array[Vector3] = [Vector3(-15.0, 0.0, 15.0), Vector3(-15.0, 0.0, -15.0)]
const SPIRE := Vector3(-7.0, 0.0, 3.0)
const ISLE_GUARD := Vector3(-6.0, 0.0, 5.0)
const ISLE_R := 12.0
const CLUES := {&"knives": Vector3(0.0, 0.0, 0.0), &"ledger": Vector3(6.0, 0.0, -3.0), &"herald": Vector3(26.0, 0.0, 34.0)}
const CLUE_R := 3.0
const CLUE_NEED: Array[float] = [3.0, 4.0, 5.0]
const BOXES: Array[Vector3] = [Vector3(4.0, 0.0, 6.0), Vector3(18.0, 0.0, 42.0), Vector3(2.0, 0.0, -42.0)]
const HUSH_BOAT := Vector3(0.0, 0.0, -18.0)
const DUEL_T := Vector3(-3.5, 0.0, 3.5)
const DUEL_D := Vector3(3.5, 0.0, -3.5)
const DUEL_RING := 8.0
const DUEL_LOSE := 0.75
const DUEL_DRAW := 90.0
const DUEL_FLOOR: Array[float] = [900.0, 1020.0, 1140.0]
const BARRICADE_HP: Array[float] = [2200.0, 3000.0, 3600.0]   ## two gatehouses (spec: one 1 500 barricade)
const DACIAN_HP: Array[float] = [800.0, 950.0, 1050.0]
const HUSH_HP: Array[float] = [850.0, 1100.0, 1400.0]
const HUSH_FLEE := 0.25
const ALDRA_PRICE := {"crystals": [200, 250, 300], "essence": [50, 100, 150], "time": [30.0, 30.0, 45.0]}
const VESSA_LEVEL: Array[int] = [5, 6, 7]
const START_CRYSTALS: Array[int] = [500, 400, 300]
const COUNT_MULT: Array[float] = [0.6, 1.0, 1.4]
const CITADEL_AT := 345.0
const W1_AT := 240.0
const W2_AT := 480.0
const W4_AT := 780.0
const RELIEF_EVERY := 150.0
const AMBUSH_LATE := 30.0
const LEVEL_CAP := 8
const DEFEAT_DELAY := 3.0
const NO_SAVE_ESSENCE := 500
const VESSA_SPELLS: Array[StringName] = [&"fireball", &"fireball", &"fireball", &"ember_step", &"ember_step", &"kindle"]
const EMBER_HALL_NE := Vector3(27.0, 0.0, -45.0)
const VESSA_HOME := Vector3(30.0, 0.0, -30.0)

const WAVES := {
	&"G1": [["gilded_spear", 4], ["ember_archer", 2]],
	&"G2": [["gilded_spear", 4], ["flame_guard", 2], ["ember_archer", 2]],
	&"G3": [["gilded_spear", 2], ["cinder_arbalest", 1]],
	&"G4": [["flame_guard", 3], ["ember_archer", 2], ["gilded_spear", 2]],
	&"G5": [["blaze_rider", 2], ["ember_archer", 2]],
	&"G6": [["gilded_spear", 3]],
	&"W1": [["blaze_rider", 3]],
	&"W2": [["flame_guard", 5], ["ember_archer", 3], ["kilnwarden", 1]],
	&"W3": [["gilded_spear", 3], ["flame_guard", 3], ["pyre_adept", 1]],
	&"W4": [["flame_guard", 6], ["ember_archer", 4], ["cinder_arbalest", 2], ["blaze_rider", 2]],
	&"relief": [["gilded_spear", 3], ["ember_archer", 1]],
	&"knives": [["gold_knife", 6]],
	&"knives_late": [["gold_knife", 4]],
}

const LINE_IDS: Array[String] = ["L1", "L2", "L3", "L4", "L5", "L6", "L7", "L8", "L9", "L10", "L10b", "L11", "L12", "L13", "L14", "L15", "L16", "L17", "L18a", "L18b", "L18c", "L19", "L20", "L21", "L22", "L23", "L24", "L25", "L26", "L27", "L28", "L29", "L30"]
const DIALOGUE := [
	[&"ossavar", "Two cities, two lies, one rock. The rock, at least, is honest."],
	[&"seraphine", "They say Adamarch staged it. I bled on that sand, Ice-king. I would like to know for whom."],
	[&"torvald", "So would I. Malrik sailed home before the blood was dry. That is not mourning."],
	[&"aldra", "The bettors fled with their strongboxes and dropped half of them. Coin always runs downhill."],
	[&"vessa", "Back again, Torvald? You're the slowest man I know, and you're still everywhere."],
	[&"torvald", "The Citadel stands. Aldra. I would rather not do this one alone."],
	[&"aldra", "You never do anything alone, my lord. You only think you do."],
	[&"seraphine", "The barricade is down. Walls should know when to fall. Ours never did."],
	[&"ossavar", "You hold my rock. Look under the cloths. The dead are poor liars."],
	[&"torvald", "Aurivane's cloaks, on knives forged in the dark. The edges drink the light. Shadow steel."],
	[&"torvald", "The boat my rune saw left violet smoke. Gold cloaks do not row from the north."],
	[&"aldra", "The bettors' ledger. Someone wagered against both cities, on the same night, before the duel."],
	[&"torvald", "A man who bets on the war, not the winner. I know only one with that much patience."],
	[&"herald", "Don't hurt me! I only read the names! I saw the boat, a black boat, from the north side!"],
	[&"torvald", "Easy. Who stepped out of it?"],
	[&"herald", "A woman in a white mask. She never said a word. The knives followed her like ducklings."],
	[&"torvald", "A white mask. Then I know the knife, and I know the hand that throws it."],
	[&"dacian", "You want the truth told on my sand, Ice-king? Then by the old rule. First blood, and no further."],
	[&"dacian", "Well struck. Twice now an Adamarch guest has cut me. I am starting to take it personally."],
	[&"dacian", "First blood to the Sun. Now say your truth, Ice-king, and I will listen."],
	[&"herald", "Neither bleeds! By the law, it is a draw, and the sand is quiet!"],
	[&"hush", "Hush now, Sunblade. The war only needs one more death."],
	[&"seraphine", "Behind you, Dacian! The knives again!"],
	[&"vessa", "I know those knives. I've had them at my throat. Hush! I owe you a night!"],
	[&"hush", "There is always another night, Ice-king. Ask your friend how he spends his."],
	[&"dacian", "Those were never ours. You knew before you came to the sand."],
	[&"torvald", "Mother Hush. I have stood beside this mask in Malrik's camp. They were my ally's knives."],
	[&"seraphine", "Then your ally broke a truce that held for a hundred and thirty years. For what?"],
	[&"torvald", "For a war that does not end. Wars are good for business, and better for that stone."],
	[&"ossavar", "First blood, and no further. The cities forgot. Let us see if you remember."],
	[&"aldra", "Bettors' gold. It spends the same as honest gold, which is the whole trouble with gold."],
	[&"seraphine", "The Sunblade is down. Every bell in both cities will ring for war now."],
	[&"torvald", "Too late. I always arrive... too late."],
]
const BRIEFING_PARAGRAPHS: Array[String] = [
	"The morning after the Laurel, the Coinwater woke to two lies. Aurivane says Adamarch faked an attack to steal the duel. Adamarch says Aurivane hid knives in gold cloaks. Aurivane's spears now hold the Tollrock, and a barricade shuts the North Causeway.",
	"Malrik sailed home to the Admiralty \"to mourn\". Seraphine did not: she stands at Torvald's camp with a bandaged hand and one question. Ossavar, on the Master's chair, gave his own advice: ask the herald where the knives came from.",
	"Take the rock. Find what the knives left behind. Then settle it the only way both cities still respect: first blood, and no further.",
]
const BRIEFING_LINE := "The herald saw the knives arrive. He fled to the far shore."
const HINT_START := "Break the Sun Barricade on the North Causeway. Frost Mortars hit walls hard; a Rimecarver's Scrying Rune shows what is behind it."
const HINT_CITADEL := "Your Stronghold can become a Citadel: select the Keep and press X (300 crystals, 90 s). It opens the Shardguard (C) and lets you call Aldra (V)."
const HINT_CALL := "Call Aldra: select the Keep and press V. She fights on her own; her card sets where (Escort / Vanguard / Hold home)."
const HINT_CLUE := "Hold Torvald beside a clue (4 s) with no enemy near to read it."
const HINT_SHARDGUARD := "A Shardguard beside Dacian stops her blink and freezes her."
const MSG_ISLE_SHUT := "The Sun Barricade still stands: the isle is closed."
const MSG_DACIAN := "Dacian comes to the sand."
const MSG_DACIAN_BELL := "Dacian will come to the sand at the afternoon bell (%s)."
const MSG_RING := "The Laurel ring is for the duellists alone."
const MSG_CLUE_REFUSED := "Not with the enemy this close."
const MSG_VESSA_FELL := "Vessa falls back to the Sun Gate"
const MSG_STAND_DOWN := "Aurivane lowers its spears for the Laurel."

## Read only.
var barricades: Array = []
var spire: Building
var clue_progress := {}                  ## clue id -> seconds channelled
var clues_found: Array[StringName] = []
var boxes_open := 0
var vessa: Wizard
var seraphine: Unit
var dacian: Unit
var hush: Unit
var herald: Unit
var aldra_npc: Unit
var duel_state := ""                     ## "", "on", "won", "lost", "draw"
var duel_started := -1.0
var victory_time := -1.0
var waves_fired: Array[String] = []
var knives: Array = []
var hush_gone := false
var dacian_arrived := false

var _tick := 0.0
var _fast := 0.0
var _relief_next := -1.0
var _kneel_until := 0.0
var _box_props: Array = []
var _isle_msg_t := 0.0


# ---------------------------------------------------------------- setup

func _init() -> void:
	super()
	use_two_harbours()
	enemy_kingdom = &"fire"
	line_ids = LINE_IDS.duplicate()
	dialogue_lines = DIALOGUE
	briefing_paragraphs = BRIEFING_PARAGRAPHS.duplicate()
	define_objectives([[&"obj_barricade", "primary"], [&"obj_rock", "primary"], [&"obj_truth", "primary"],
			[&"obj_duel", "primary"], [&"obj_dacian", "primary"], [&"obj_torvald", "primary"],
			[&"sec_aldra", "secondary"], [&"sec_boxes", "secondary"], [&"sec_duel", "secondary"]])
	local_building_into("fire_barracks", "sun_barricade", "Sun Barricade")


var _barricade_type: BuildingType


func local_building_into(base: String, id: String, display: String) -> void:
	_barricade_type = MissionE5Base.local_building(base, id, display, 1500.0, false)
	if _barricade_type:
		_barricade_type.set(&"trains", [] as Array[UnitType])


func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	MissionE7Base.e7_config(c, 3)
	c.mission_id = MISSION_ID
	c.title = MISSION_TITLE
	c.count_mult = COUNT_MULT.duplicate()
	c.easy_skip_types = [&"cinder_arbalest", &"kilnwarden"]
	c.defeat_on_keep_lost = true
	c.keep_lost_message = "The Rime Keep has fallen."
	c.start_tiers = {Unit.Team.PLAYER: 2, Unit.Team.ENEMY: 2}
	c.helper_call_price = ALDRA_PRICE.duplicate(true)
	c.start_level = 5
	c.start_spell_points = 4
	c.start_spells = [&"rime_bolt"]
	c.level_cap = LEVEL_CAP
	c.start_crystals = START_CRYSTALS.duplicate()
	c.start_essence = 150
	c.defeat_delay = DEFEAT_DELAY
	c.victory_banner = "VICTORY\nFirst blood, and no further"
	c.defeat_banner = "DEFEAT"
	c.rewards = CampaignState.MISSION_REWARDS.get(MISSION_ID, {})
	c.spotlight = {"id": &"helper_aldra", "trigger": &"manual", "key_hint": "Rime Keep: V",
			"card": "Aldra. The Glass Warden: she shields the army's walk and shatters the line at the end of it."}
	return c


func _title_line() -> String:
	return "Episode 7, Mission 2: %s" % MISSION_TITLE


func _ready() -> void:
	super()
	tint_light(Color(1.0, 0.92, 0.78), 1.0, -42.0, Color(0.64, 0.64, 0.68), Color(0.34, 0.54, 0.80), Color(0.92, 0.86, 0.72))
	if tier_system:
		tier_system.max_tier = 2   # the Citadel opens at 5:45
	var ev := get_node_or_null(^"/root/Events")
	if ev and ev.has_signal(&"unit_died"):
		ev.unit_died.connect(_on_any_unit_died)


# ---------------------------------------------------------------- the map

func _build_map() -> void:
	super()
	add_two_harbours_map()
	place_building("ice_barracks", FROST_HALL, Unit.Team.PLAYER)
	place_building("ice_lodge", SNOW_LODGE, Unit.Team.PLAYER)
	place_building("ice_market", BAZAAR_SPOT, Unit.Team.PLAYER)
	place_building("fire_barracks", EMBER_HALL_NE, Unit.Team.ENEMY)
	place_building("fire_hearth", YSOLDE_KEEP + Vector3(8.0, 0.0, -3.0), Unit.Team.ENEMY)
	if _barricade_type:
		_barricade_type.max_hp = float(by_difficulty(BARRICADE_HP))
	for p: Vector3 in BARRICADES:
		var b := build_grid.spawn_complete(_barricade_type, p, Unit.Team.ENEMY) if _barricade_type else null
		if b:
			b.destroyed.connect(_on_barricade_down)
			barricades.append(b)
	spire = build_grid.spawn_complete(BuildingType.find("fire_tower"), SPIRE, Unit.Team.ENEMY)
	for p: Vector3 in BOXES:
		_box_props.append(box_prop(p, Vector3(1.0, 0.7, 0.7), Color(0.72, 0.56, 0.22)))
	for id: StringName in CLUES:
		ground_disc(CLUES[id], CLUE_R, Color(0.95, 0.85, 0.45, 0.35), 0.05)


# ---------------------------------------------------------------- start state

func _on_navigation_ready() -> void:
	read_save(&"e7m1")
	var diff := clampi(mission_difficulty, 0, 2)
	_setup_champions()
	hero = _make_wizard(Unit.Team.PLAYER)
	_spawn(hero, Unit.Team.PLAYER, PLAYER_START)
	_claim_wizard(hero, Unit.Team.PLAYER)
	ItemDrops.ensure_inventory(hero)
	apply_splinter(hero)
	carry_torvald_essence(NO_SAVE_ESSENCE)
	for i in 6:
		var w := _spawn(make_unit("rime_hauler"), Unit.Team.PLAYER, RIME_KEEP + Vector3(4.0 + i * 1.2, 0.0, -4.0))
		w.call(&"command_gather", node_of(Unit.Team.PLAYER, "a" if i < 3 else "b"))
	var army := [["rimeshield", 6 + (2 if diff == 0 else 0)], ["shardcaster", 4], ["rime_seer", 1], ["rimecarver", 1],
			["frost_mortar", 0 if diff == 2 else 1]]
	var k := 0
	for row: Array in army:
		for j in int(row[1]):
			_spawn(make_unit(String(row[0])), Unit.Team.PLAYER, PLAYER_RALLY + Vector3((k % 5) * 1.6 - 3.2, 0.0, (k / 5) * 1.7))
			k += 1
	for i in 2:
		_spawn(make_unit("caravan"), Unit.Team.PLAYER, BAZAAR_SPOT + Vector3(3.0 + i * 1.5, 0.0, 3.0))
	seraphine = make_unit("seraphine_story")
	_spawn(seraphine, Unit.Team.PLAYER, PLAYER_START + Vector3(2.0, 0.0, -2.0))
	mark_scripted(seraphine)
	guard_life(seraphine, _on_seraphine_down)
	aldra_npc = story_npc("aldra_npc", ALDRA_SPOT)
	vessa = _make_wizard(Unit.Team.ENEMY)
	_spawn(vessa, Unit.Team.ENEMY, VESSA_HOME)
	_claim_wizard(vessa, Unit.Team.ENEMY)
	raise_wizard(vessa, int(VESSA_LEVEL[diff]), VESSA_SPELLS)
	ItemDrops.ensure_inventory(vessa)
	mark_scripted(vessa)
	vessa.set_meta(META_HOME, VESSA_HOME)
	_guards.append(vessa)
	vessa.died.connect(_on_vessa_died)
	for i in 5:
		var s := _spawn(make_unit("cinder_hand"), Unit.Team.ENEMY, YSOLDE_KEEP + Vector3(-4.0, 0.0, 4.0 + i))
		s.call(&"command_gather", node_of(Unit.Team.ENEMY, "a" if i < 3 else "b"))
	spawn_rows([["flame_guard", 4], ["ember_archer", 2]], VESSA_HOME, 3.0, Unit.Team.ENEMY, true)
	spawn_rows(WAVES[&"G1"], ISLE_GUARD, 2.5, Unit.Team.ENEMY, true)
	spawn_rows(WAVES[&"G2"], ROCK + Vector3(2.0, 0.0, 2.0), 3.0, Unit.Team.ENEMY, true)
	spawn_rows(WAVES[&"G3"], CLUES[&"ledger"] + Vector3(1.5, 0.0, 0.0), 1.5, Unit.Team.ENEMY, true)
	spawn_rows(WAVES[&"G4"], CLUES[&"herald"] + Vector3(2.0, 0.0, 2.0), 3.0, Unit.Team.ENEMY, true)
	spawn_rows(WAVES[&"G5"], BOXES[1] + Vector3(2.0, 0.0, 0.0), 2.0, Unit.Team.ENEMY, true)
	spawn_rows(WAVES[&"G6"], BOXES[2] + Vector3(2.0, 0.0, 0.0), 2.0, Unit.Team.ENEMY, true)
	herald = story_npc("herald_story", CLUES[&"herald"] + Vector3(0.0, 0.0, 1.5), Unit.Team.NEUTRAL)
	spawn_dragon("ossavar_story", CHAIR + Vector3(-1.5, 0.0, 1.5))
	add_rock_zone()
	rock.set_owner_side(1)
	rock.captured.connect(_on_rock_captured)
	for p: Vector3 in [ROCK, NORTH_CAUSEWAY, BARRICADES[1], CLUES[&"herald"], BOXES[1], BOXES[2]]:
		fog.reveal(Unit.Team.PLAYER, p, 8.0)
	setup_e7_trade(60.0)
	var mk := Market.of_team(Unit.Team.PLAYER)
	var post := post_named(&"heron_ford")
	if mk and post:
		mk.set_route(post)
	var roster := HelperRoster.for_team(Unit.Team.PLAYER)
	if roster:
		roster.helper_ready.connect(_on_aldra_ready)
	if flag_on("e7m1_rune_saw_boat"):
		clues_found.append(&"knives")
	begin_mission([&"obj_barricade", &"obj_torvald", &"sec_boxes", &"sec_aldra"])
	selection.select_units([hero])



func _intro() -> void:
	fire_once(&"E1")
	play_cutscene(&"e7m2_morning", _morning_end)


func _morning_end() -> void:
	for id in ["L1", "L2", "L3"]:
		say_l(id)
	if hud:
		hud.show_message(HINT_START, 10.0)
	if camera_rig and hero_alive():
		camera_rig.focus_on(hero.global_position)


# ---------------------------------------------------------------- briefing, objectives

func briefing() -> Dictionary:
	return {
		"title": _title_line(),
		"paragraphs": BRIEFING_PARAGRAPHS.duplicate(),
		"objectives": [objective_text(&"obj_rock", false), objective_text(&"obj_truth", false), BRIEFING_LINE],
		"rule": Loc.sink(objective_text(&"obj_torvald")),
	}


func barricades_left() -> int:
	var n := 0
	for b: Variant in barricades:
		if is_instance_valid(b) and (b as Building).is_alive():
			n += 1
	return n


func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_barricade":
			if with_counter:
				return "Break the Sun Barricade (%d / 2)" % (2 - barricades_left())
			return "Break the Sun Barricade"
		&"obj_rock":
			return "Take the Tollrock"
		&"obj_truth":
			if with_counter:
				return "Find the truth (%d / 3): the knives, the ledger, the herald" % clues_found.size()
			return "Find the truth: the knives, the ledger, the herald"
		&"obj_duel":
			return "Meet Dacian on the sand: first blood, and no further"
		&"obj_dacian":
			return "Keep Dacian alive"
		&"obj_torvald":
			return "Torvald must survive"
		&"sec_aldra":
			return "Raise a Citadel and call Aldra"
		&"sec_boxes":
			if with_counter:
				return "Seize the bettors' strongboxes (%d / 3)" % boxes_open
			return "Seize the bettors' strongboxes"
		&"sec_duel":
			return "Draw first blood"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_barricade":
			var pos: Array = []
			for b: Variant in barricades:
				if is_instance_valid(b) and (b as Building).is_alive():
					pos.append((b as Node3D).global_position)
			return {"counter": 2 - barricades_left(), "goal": 2, "positions": pos}
		&"obj_rock":
			return {"positions": [ROCK]}
		&"obj_truth":
			var pos: Array = []
			for cid: StringName in CLUES:
				if not clues_found.has(cid):
					pos.append(CLUES[cid])
			return {"counter": clues_found.size(), "goal": 3, "positions": pos}
		&"obj_dacian":
			if dacian and is_instance_valid(dacian):
				return {"counter": int(dacian.hp), "goal": int(dacian.max_hp), "positions": [dacian.global_position]}
		&"sec_boxes":
			return {"counter": boxes_open, "goal": 3}
	return {}


# ---------------------------------------------------------------- the barricade, the rock, the clues

func _on_barricade_down(_b: Building) -> void:
	if is_ending() or barricades_left() > 0:
		return
	fire_once(&"E7")
	say_l("L8")
	set_objective(&"obj_barricade", "done")
	set_objective(&"obj_rock", "active")
	set_objective(&"obj_truth", "active")
	_launch_w2()


## The soft wall: while a barricade stands, side-0 units on the isle are pushed back to the west bank.
func _tick_isle_wall() -> void:
	if barricades_left() == 0:
		return
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or not u.is_alive() or Teams.side_of(int(u.team)) != 0 or not u.can_move():
			continue
		if _flat(u.global_position, ROCK) < ISLE_R - 1.0:
			var out := (u.global_position - ROCK)
			out.y = 0.0
			if out.length() < 0.1:
				out = Vector3(-1.0, 0.0, 1.0)
			u.displace(ROCK + out.normalized() * (ISLE_R + 5.0), 0.8)
			if hud and mission_time() > _isle_msg_t:
				_isle_msg_t = mission_time() + 8.0
				hud.show_message(MSG_ISLE_SHUT, 4.0)


func _on_rock_captured(_z: MissionZone, side: int) -> void:
	if side != 0 or is_ending():
		return
	if objective_state("obj_rock") == "active":
		set_objective(&"obj_rock", "done")
	if fire_once(&"E8"):
		say_l("L9")
		if clues_found.has(&"knives"):
			say_l("L10b")
		waves_fired.append("W3")
		route_wave(WAVES[&"W3"], SOUTH_FOOT + Vector3(6.0, 0.0, -6.0), [SOUTH_CAUSEWAY], ROCK)
		_relief_next = mission_time() + RELIEF_EVERY


func _tick_clues(dt: float) -> void:
	if objective_state("obj_truth") != "active":
		return
	var need := float(by_difficulty(CLUE_NEED))
	for cid: StringName in CLUES:
		if clues_found.has(cid):
			continue
		var p := channel_step(float(clue_progress.get(cid, 0.0)), CLUES[cid], CLUE_R, need, dt, MSG_CLUE_REFUSED)
		clue_progress[cid] = p
		if p > 0.0 and fire_once(&"clue_hint") and hud:
			hud.show_message(HINT_CLUE, 6.0)
		if p >= need:
			_clue_found(cid)


func _clue_found(cid: StringName) -> void:
	if clues_found.has(cid):
		return
	clues_found.append(cid)
	match cid:
		&"knives":
			fire_once(&"E9")
			say_l("L10")
		&"ledger":
			fire_once(&"E10")
			say_l("L11")
			say_l("L12")
		&"herald":
			fire_once(&"E11")
			play_cutscene(&"e7m2_herald", _herald_end)
	objectives_changed.emit()
	if clues_found.size() >= 3:
		_truth_known()


func _herald_end() -> void:
	for id in ["L13", "L14", "L15"]:
		say_l(id)


func _truth_known() -> void:
	if not fire_once(&"E11b"):
		return
	say_l("L16")
	set_objective(&"obj_truth", "done")
	set_objective(&"obj_duel", "active")
	if mission_time() < duel_floor() and hud:
		hud.show_message(MSG_DACIAN_BELL % mmss(duel_floor()), 6.0)


func duel_floor() -> float:
	return float(by_difficulty(DUEL_FLOOR))


## Dacian walks to the sand once the truth is known and the afternoon bell has rung.
func _tick_dacian() -> void:
	if not has_fired(&"E11b") or dacian_arrived or mission_time() < duel_floor():
		return
	dacian_arrived = true
	if hud:
		hud.show_message(MSG_DACIAN, 5.0)
	dacian = make_unit("dacian_story")
	_spawn(dacian, Unit.Team.NEUTRAL, SOUTH_FOOT)
	mark_scripted(dacian)
	dacian.add_modifier(&"e7_difficulty", {"max_hp": float(by_difficulty(DACIAN_HP)) - 950.0})
	dacian.hp = dacian.max_hp
	set_truce([dacian], true, Unit.TRUCE_ALL)
	dacian.command_move(DUEL_D)


func _tick_duel_call() -> void:
	if not dacian_arrived or has_fired(&"E12") or dacian == null or not hero_alive():
		return
	if _flat(hero.global_position, dacian.global_position) > 10.0 or _flat(hero.global_position, ROCK) > ISLE_R:
		return
	fire_once(&"E12")
	_stand_down()
	hero.global_position = DUEL_T
	hero.command_stop()
	dacian.global_position = DUEL_D
	dacian.command_stop()
	play_cutscene(&"e7m2_laurel_call", _duel_start)


## E12: Aurivane stands down for the Laurel: its field units walk home and leave, Vessa goes back to her keep.
func _stand_down() -> void:
	clear_waves()
	_relief_next = -1.0
	if hud:
		hud.show_message(MSG_STAND_DOWN, 5.0)
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or not u.is_alive() or int(u.team) != Unit.Team.ENEMY or u.is_worker() or u == dacian:
			continue
		_guards.erase(u)
		set_truce([u], true, Unit.TRUCE_ALL)
		if u == vessa:
			u.command_move(VESSA_HOME)
			continue
		u.command_move(AURIVANE_GATES[0])
		leave_later(u, 30.0)
	for b: Variant in [spire]:
		if is_instance_valid(b):
			set_truce([b as Node], true, Unit.TRUCE_ALL)


func _duel_start() -> void:
	say_l("L17")
	duel_state = "on"
	duel_started = mission_time()
	set_truce([dacian], false, Unit.TRUCE_ALL)
	dacian.team = Unit.Team.ENEMY
	hero.death_guard = func(_a: Variant) -> bool:
		hero.hp = 1.0
		return true
	dacian.command_attack(hero)


func _tick_duel() -> void:
	if duel_state != "on":
		return
	# the ring: nobody else inside r 8
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or not u.is_alive() or u == hero or u == dacian or not u.can_move() or dragons_has_unit(u):
			continue
		if _flat(u.global_position, ROCK) < DUEL_RING:
			var out := u.global_position - ROCK
			out.y = 0.0
			u.displace(ROCK + out.normalized() * (DUEL_RING + 2.0), 0.6)
			if fire_once(&"ring_msg") and hud:
				hud.show_message(MSG_RING, 4.0)
	if dacian.attack_target == null and hero_alive():
		dacian.command_attack(hero)
	var outcome := ""
	if hero.hp < hero.max_hp * DUEL_LOSE:
		outcome = "lost"
	elif dacian.hp < dacian.max_hp * DUEL_LOSE:
		outcome = "won"
	elif mission_time() - duel_started >= DUEL_DRAW:
		outcome = "draw"
	if outcome != "":
		_duel_end(outcome)


func _duel_end(outcome: String) -> void:
	duel_state = outcome
	fire_once(&"E13")
	hero.death_guard = Callable()
	dacian.command_stop()
	hero.command_stop()
	set_truce([dacian], true, Unit.TRUCE_ALL)
	dacian.team = Unit.Team.PLAYER
	set_objective(&"obj_duel", "done")
	match outcome:
		"won":
			say_l("L18a")
			set_objective(&"sec_duel", "done")
			set_mission_flag("e7m2_duel_won", true)
		"lost":
			say_l("L18b")
			set_objective(&"sec_duel", "failed")
		_:
			say_l("L18c")
			set_objective(&"sec_duel", "failed")
	after(2.0, func() -> void:
		if not is_ending():
			play_cutscene(&"e7m2_knives", _ambush))


## The ambush: Hush and 6 knives on the rim, all on Dacian; 30 s later 4 more from Hush's boat.
func _ambush() -> void:
	if not fire_once(&"ambush"):
		return
	say_l("L19")
	say_l("L20")
	waves_fired.append("ambush")
	set_truce([dacian], false, Unit.TRUCE_ALL)
	dacian.died.connect(_on_dacian_died)
	set_objective(&"obj_dacian", "active")
	hush = make_unit("hush_story")
	_spawn(hush, Unit.Team.ENEMY, ROCK + Vector3(5.0, 0.0, 5.0))
	mark_scripted(hush)
	hush.add_modifier(&"e7_difficulty", {"max_hp": float(by_difficulty(HUSH_HP)) - 1100.0})
	hush.hp = hush.max_hp
	guard_life(hush, _on_hush_down)
	order_wave(hush, &"dacian", DUEL_D)
	knives = spawn_rows(WAVES[&"knives"], ROCK + Vector3(6.0, 0.0, 0.0), 2.5, Unit.Team.ENEMY, false)
	for v: Variant in knives:
		order_wave(v as Unit, &"dacian", DUEL_D)
	after(AMBUSH_LATE, func() -> void:
		if is_ending():
			return
		for v: Variant in spawn_rows(WAVES[&"knives_late"], HUSH_BOAT, 2.0, Unit.Team.ENEMY, false):
			knives.append(v)
			order_wave(v as Unit, &"dacian", DUEL_D))
	after(6.0, func() -> void:
		if not is_ending():
			fire_once(&"E14")
			say_l("L21")
			if hud:
				hud.show_message(HINT_SHARDGUARD, 8.0))


func _refresh_e7_mode(u: Unit, mode: StringName, _hero_at: Vector3) -> bool:
	if mode != &"dacian":
		return false
	if u == hush and hush_gone:
		return true
	if dacian and is_instance_valid(dacian) and dacian.is_alive():
		if u.attack_target == null or not (u.attack_target is Unit) or not (u.attack_target as Unit).is_alive():
			u.command_attack(dacian)
	return true


func _hush_flees() -> void:
	if hush_gone:
		return
	hush_gone = true
	fire_once(&"E15")
	say_l("L22")
	_wave_units.erase(hush)
	set_truce([hush], true, Unit.TRUCE_ALL)
	hush.command_move(HUSH_BOAT)
	add_xp_to_hero(400)
	after(6.0, func() -> void:
		if is_instance_valid(hush) and hush.is_alive():
			hush.leave_map())


func add_xp_to_hero(n: int) -> void:
	if hero_alive():
		hero.add_xp(n)


func _tick_hush() -> void:
	if hush == null or not is_instance_valid(hush) or hush_gone:
		return
	if hush.hp < hush.max_hp * HUSH_FLEE:
		_hush_flees()


func _tick_ambush_end() -> void:
	if not has_fired(&"ambush") or not hush_gone or is_ending():
		return
	for v: Variant in knives:
		if is_instance_valid(v) and (v as Unit).is_alive():
			return
	if dacian == null or not is_instance_valid(dacian) or not dacian.is_alive():
		return
	if not fire_once(&"E16"):
		return
	victory_time = mission_time()
	set_objective(&"obj_dacian", "done")
	set_objective(&"obj_torvald", "done")
	_record_flags()
	play_cutscene(&"e7m2_mask", _mask_end)


func _mask_end() -> void:
	for id in ["L23", "L24", "L25", "L26", "L27"]:
		say_l(id)
	win(1.0)


func _record_flags() -> void:
	set_mission_flag("e7m2_time", int(victory_time))
	set_mission_flag("e7m2_boxes", boxes_open)
	set_mission_flag("e7m2_aldra_called", objective_state("sec_aldra") == "done")
	if objective_state("sec_aldra") == "active":
		set_objective(&"sec_aldra", "failed")
	if objective_state("sec_boxes") == "active":
		set_objective(&"sec_boxes", "failed")
	var bonus := 0
	if objective_state("sec_boxes") == "done":
		bonus += 300
	if objective_state("sec_duel") == "done":
		bonus += 200
	if objective_state("sec_aldra") == "done":
		bonus += 150
	record_torvald_essence(bonus)


func _on_hush_down(_u: Unit) -> void:
	_hush_flees()


func _on_dacian_died(_u: Unit) -> void:
	if is_ending():
		return
	fire_once(&"E18")
	say_l("L29")
	set_objective(&"obj_dacian", "failed")
	lose(DEFEAT_DELAY)


func _on_player_hero_fell() -> void:
	fire_once(&"E19")
	say_l("L30")
	set_objective(&"obj_torvald", "failed")
	super()


# ---------------------------------------------------------------- waves

func _launch_w2() -> void:
	if not fire_once(&"W2"):
		return
	waves_fired.append("W2")
	route_wave(WAVES[&"W2"], EMBER_HALL_NE + Vector3(-6.0, 0.0, 6.0), [SILVER_SHOAL, Vector3(-40.0, 0.0, -10.0)], RIME_KEEP)
	if vessa and vessa.is_alive():
		_guards.erase(vessa)
		send_route(vessa, [SILVER_SHOAL, Vector3(-40.0, 0.0, -10.0)], RIME_KEEP)


func _tick_waves() -> void:
	var t := mission_time()
	if t >= 60.0 and fire_once(&"E2"):
		say_l("L4")
	if t >= W1_AT and fire_once(&"E3"):
		waves_fired.append("W1")
		say_l("L5")
		route_wave(WAVES[&"W1"], EMBER_HALL_NE + Vector3(-6.0, 0.0, 6.0), [SILVER_SHOAL], RIME_KEEP + Vector3(0.0, 0.0, -14.0))
	if t >= CITADEL_AT and fire_once(&"E4"):
		if tier_system:
			tier_system.max_tier = 3
		if hud:
			hud.show_message(HINT_CITADEL, 12.0)
	if t >= W2_AT:
		_launch_w2()
	if not has_fired(&"E12") and t >= W4_AT and clues_found.size() >= 2 and fire_once(&"W4"):
		waves_fired.append("W4")
		var goal := ROCK if rock_owner() == 0 else HARBOUR
		route_wave(WAVES[&"W4"], SOUTH_FOOT + Vector3(6.0, 0.0, -6.0), [SOUTH_CAUSEWAY], goal)
		if vessa and vessa.is_alive():
			_guards.erase(vessa)
			send_route(vessa, [SOUTH_CAUSEWAY], goal)
	if _relief_next > 0.0 and t >= _relief_next and not has_fired(&"E12"):
		_relief_next = t + RELIEF_EVERY
		if rock_owner() == 0:
			waves_fired.append("relief")
			route_wave(WAVES[&"relief"], SOUTH_FOOT + Vector3(6.0, 0.0, -6.0), [SOUTH_CAUSEWAY], ROCK)
	if vessa and vessa.is_alive() and not _guards.has(vessa) and not has_fired(&"E12") and vessa.hp < vessa.max_hp * 0.35:
		_wave_units.erase(vessa)
		vessa.remove_meta(META_MODE)
		vessa.command_move(VESSA_HOME)
		_guards.append(vessa)


func _on_vessa_died(_u: Unit) -> void:
	_guards.erase(vessa)
	_wave_units.erase(vessa)
	if hud and not is_ending():
		hud.show_message(MSG_VESSA_FELL, 4.0)
	after(60.0, _vessa_back)


## Vessa comes back 60 s after her fall (a named timer: saving stays allowed, review 2026-10-10 #8).
func _vessa_back() -> void:
	if is_instance_valid(vessa) and not vessa.is_alive() and not is_ending():
		vessa.respawn(YSOLDE_KEEP + Vector3(-6.0, 0.0, 6.0))
		vessa.command_move(VESSA_HOME)
		_guards.append(vessa)
		if has_fired(&"E12"):
			set_truce([vessa], true, Unit.TRUCE_ALL)


# ---------------------------------------------------------------- allies, boxes, events

func _on_seraphine_down(_u: Unit) -> void:
	if _kneel_until <= 0.0:
		_kneel_until = mission_time() + 10.0
		set_dormant(seraphine, true)


func _tick_seraphine() -> void:
	if seraphine == null or not is_instance_valid(seraphine):
		return
	if _kneel_until > 0.0:
		if mission_time() >= _kneel_until:
			_kneel_until = 0.0
			seraphine.hp = seraphine.max_hp * 0.5
			set_dormant(seraphine, false)
		return
	if duel_state == "on" or not hero_alive() or seraphine.attack_target != null:
		return
	if _flat(seraphine.global_position, hero.global_position) > 6.0:
		seraphine.command_attack_move(hero.global_position + Vector3(2.0, 0.0, 2.0))


func _on_aldra_ready(_h: Helper) -> void:
	if is_ending():
		return
	if aldra_npc and is_instance_valid(aldra_npc):
		aldra_npc.leave_map()
	if fire_once(&"E6"):
		say_l("L7")
		if objective_state("sec_aldra") == "active":
			set_objective(&"sec_aldra", "done")
		show_spotlight()


func _tick_boxes() -> void:
	for i in BOXES.size():
		if has_fired(StringName("box_%d" % i)):
			continue
		for n in get_tree().get_nodes_in_group(&"units"):
			var u := n as Unit
			if u and u.is_alive() and Teams.side_of(int(u.team)) == 0 and not is_dormant(u) \
					and _flat(u.global_position, BOXES[i]) < 2.5:
				fire_once(StringName("box_%d" % i))
				boxes_open += 1
				add_gold(150)
				var bank := EssenceBank.for_team(Unit.Team.PLAYER)
				if bank:
					bank.add(60)
				if is_instance_valid(_box_props[i]) and _box_props[i] != null:
					(_box_props[i] as Node3D).visible = false
				if fire_once(&"E17"):
					say_l("L28")
				if boxes_open >= 3 and objective_state("sec_boxes") == "active":
					set_objective(&"sec_boxes", "done")
				break


func _tick_events() -> void:
	if has_fired(&"E4") and not has_fired(&"E5") and keep and keep.tier >= 3 and fire_once(&"E5"):
		say_l("L6")
		if hud:
			hud.show_message(HINT_CALL, 10.0)


func _on_any_unit_died(u: Node) -> void:
	var unit := u as Unit
	if unit == null or is_ending() or unit.unit_type == null:
		return
	if unit.unit_type.id == &"gold_knife":
		flash_ring(unit.global_position, 1.5)


# ---------------------------------------------------------------- save / load

func save_state(ids: Dictionary = {}) -> Dictionary:
	var d := super(ids)
	var found: Array = []
	for c: StringName in clues_found:
		found.append(String(c))
	d["e7m2"] = {"clues": found, "boxes": boxes_open, "duel": duel_state, "dacian_arrived": dacian_arrived}
	return d


func load_state(d: Dictionary, nodes: Dictionary = {}) -> void:
	super(d, nodes)
	var m: Dictionary = d.get("e7m2", {})
	clues_found.clear()
	for c: Variant in m.get("clues", []):
		clues_found.append(StringName(str(c)))
	boxes_open = int(m.get("boxes", 0))
	duel_state = String(m.get("duel", ""))
	dacian_arrived = bool(m.get("dacian_arrived", false))
	if tier_system:
		tier_system.max_tier = 3 if has_fired(&"E4") else 2
	# Review 2026-10-10 #3: the ambush hooks (Dacian's death, Hush's guard) are set mid-mission.
	if has_fired(&"ambush"):
		if dacian and is_instance_valid(dacian) and not dacian.died.is_connected(_on_dacian_died):
			dacian.died.connect(_on_dacian_died)
		if hush and is_instance_valid(hush):
			guard_life(hush, _on_hush_down)


func save_block_reason() -> String:
	if duel_state == "on" or (has_fired(&"ambush") and not has_fired(&"E16")):
		return "Not during the Laurel"
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
		if duel_state != "on":
			tick_rock(0.25)
		_tick_clues(0.25)
		_tick_duel()
		_tick_isle_wall()
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.5
		_tick_waves()
		_tick_dacian()
		_tick_duel_call()
		_tick_hush()
		_tick_ambush_end()
		_tick_seraphine()
		_tick_boxes()
		_tick_events()
		objectives_changed.emit()
		if hud and mission_hud == null:
			hud.set_objective(_objective_text())
