class_name MissionE7_01
extends MissionE7Base
## Episode 7, mission 1 "The Dragon Auction" (docs/design/mission-e7-01.md): the first Ice mission of the story. Torvald
## (player, Adamarch west) and Malrik (ALLY Shadow bot, Adamarch east) against Aurivane (Ysolde and Vessa) across the
## Coinwater. Hold the Diamond Harbour, win 2 of the 3 Dragon Auctions (Kesh 8:00, Morrow-of-Glass 14:00, Ossavar
## 20:00), bring Seraphine home from the broken Laurel, then hold the harbour 2:00 until Aurivane's fleet turns.
## Spotlight: the Rimecarver (a map of doors).
##
## Built deviations (2026-10-09, from the spec):
## - Two Harbours is Crown Hollow re-dressed (MissionE7Base): the river is the strait, the Crown Isle the Tollrock, the
##   bridges / fords its causeways and shoals; Torvald south-west, Malrik north-west, Ysolde north-east (the ENEMY keep),
##   Vessa's quarter south-east (an Ember Hall, a Hearth, a Spire on the ENEMY team; she is a second ENEMY wizard).
## - Aurivane has no Commander: its quarters train nothing, guards hold the rallies, every attack is a scripted wave.
## - The Diamond Harbour is a scripted target beside the Heron Ford post (renamed Diamond Harbour); the caravans' route
##   value is the trade code's own (no x1.5).
## - Bids are a mission button panel ("Bid +50" / "Bid +100") shown during the 45 s window; a Bazaar is still needed.
## - The dragons are mission unit types on the Stormcrest Roc model (scaled), not commandable; they never die (rest at
##   15 %). The Laurel duel is a 20 s stand-off (no blows); Dacian walks off east and leaves the map.
## - The G3 gate guards and the boat clue (Scrying Rune) are not built: e7m1_rune_saw_boat is set when a Rimecarver
##   stands within 10 m of the knives' rim when they drop (the "it saw the boat" moment).

const MISSION_ID := &"e7m1"
const MISSION_TITLE := "The Dragon Auction"

const A_TIMES: Array[float] = [480.0, 840.0, 1200.0]
const A_DRAGONS: Array[String] = ["gilt_dragon", "prism_dragon", "ossavar_story"]
const A_NAMES: Array[String] = ["Kesh", "Morrow-of-Glass", "Ossavar"]
const CEILINGS := [[350, 600, 850], [500, 800, 1100], [600, 950, 1300]]
const ROCK_WORD: Array[float] = [0.15, 0.10, 0.05]
const HARBOUR_HP: Array[float] = [3000.0, 2500.0, 2200.0]
const HARBOUR_REGEN := 25.0          ## 1 % / s of 2 500 while no enemy within 12 m.
const SERAPHINE_HP: Array[float] = [1200.0, 1000.0, 900.0]
const HOLD_LEN: Array[float] = [90.0, 120.0, 150.0]
const MALRIK_SOLDIERS: Array[int] = [10, 8, 6]
const START_CRYSTALS: Array[int] = [450, 350, 250]
const COUNT_MULT: Array[float] = [0.6, 1.0, 1.4]
const STRONGHOLD_AT := 210.0
const W1_AT := 270.0
const W2_AT := 420.0
const W3_AT := 570.0
const HERALD_AT := 660.0
const DUEL_AT := 720.0
const KNIVES_AT := 740.0
const GUARD_AT := 760.0
const GIFT_AT := 830.0
const W4_AT := 930.0
const W5_AT := 1050.0
const FINAL_LATE := 45.0
const LEVEL_CAP := 7
const DEFEAT_DELAY := 3.0
const VESSA_SPELLS: Array[StringName] = [&"fireball", &"fireball", &"ember_step", &"ember_step", &"kindle"]
const YSOLDE_SPELLS: Array[StringName] = [&"thornburst", &"thornburst", &"wild_bloom", &"call_the_thicket"]
const MALRIK_SPELLS: Array[StringName] = [&"shadow_lance", &"shadow_lance", &"soul_siphon", &"soul_siphon", &"umbral_shroud"]
const RIM := Vector3(3.0, 0.0, 3.0)
const DUEL_S := Vector3(-2.5, 0.0, 2.5)
const DUEL_D := Vector3(2.5, 0.0, -2.5)
const DACIAN_EXIT := Vector3(58.0, 0.0, -10.0)
const FACET_POST := Vector3(-50.0, 0.0, 16.0)

const WAVES := {
	&"W1": [["blaze_rider", 3]],
	&"W2": [["thornling", 5], ["burr_slinger", 3], ["bloomtender", 1]],
	&"W3": [["flame_guard", 4], ["ember_archer", 3], ["pyre_adept", 1]],
	&"knives": [["gold_knife", 4]],
	&"guard": [["gilded_spear", 4], ["ember_archer", 2]],
	&"W4": [["thornling", 6], ["wildwood_archer", 3], ["vinelasher", 2], ["bramblehorn", 1]],
	&"W5": [["blaze_rider", 4], ["thistle_darter", 2]],
	&"final_fire": [["flame_guard", 6], ["ember_archer", 4]],
	&"final_nature": [["thornling", 6], ["greenheart_oathkeeper", 2]],
	&"final_late": [["cinder_arbalest", 2], ["gilded_spear", 4]],
	&"G1": [["gilded_spear", 3], ["ember_archer", 2]],
	&"G2": [["thornling", 3], ["burr_slinger", 2]],
}

const LINE_IDS: Array[String] = ["L1", "L2", "L3", "L4", "L5", "L6", "L7", "L8", "L9", "L10", "L11", "L12", "L13", "L14", "L15", "L16", "L17", "L16b", "L18", "L19", "L20", "L21", "L22", "L22b", "L23a", "L23", "L24", "L25", "L26", "L27", "L28", "L29", "L30", "L31", "L32", "L34", "L33", "L35", "L36", "L37", "L38"]
const DIALOGUE := [
	[&"ossavar", "Two harbours, one rock, a sky for sale. Bring gold. I take no promises."],
	[&"malrik", "The west harbour is yours, Torvald, the east is mine. Together we outbid the sun."],
	[&"torvald", "I came to keep the Coinwater's peace, Malrik. Not to buy a dragon like a cart-horse."],
	[&"aldra", "Then keep it with gold, my lord. Winter is patient. Markets are not."],
	[&"aldra", "Send the wagons to the harbour. And watch the shoals. The sun's riders are faster than ice."],
	[&"aldra", "The first coin is home. It smells of fish and diamonds."],
	[&"vessa", "Torvald! You came south for the sunshine? I'll show you sunshine."],
	[&"torvald", "Vessa. Still never waiting. One day, child, the road will be longer than you are."],
	[&"herald", "The rock is held! By the old law, its master speaks last at the hammer."],
	[&"ossavar", "The first of my brood. Kesh burns bright, and cheap. Who pays?"],
	[&"torvald", "Fly with us, then. And try not to enjoy it."],
	[&"ossavar", "Gold from the south. Kesh, burn the north."],
	[&"herald", "The Laurel at noon! By the Truce of the Stilled Sea: first blood, and no further!"],
	[&"dacian", "No crowd worth the name today, Diamond Wall. Just us, and a great deal of money."],
	[&"seraphine", "Then let us disappoint the money."],
	[&"seraphine", "Gold cloaks, behind me. So this is how Aurivane wins now."],
	[&"dacian", "Those aren't mine! Seraphine, those are NOT mine!"],
	[&"torvald", "That smoke is violet. Gold cloaks do not bleed violet."],
	[&"seraphine", "Walls don't run, Ice-king. But they can walk, if you walk beside them."],
	[&"seraphine", "The harbour, then. I will hold it. It is the one thing today that hasn't lied to me."],
	[&"malrik", "For the second bid, Torvald. A gift. Two hundred, in good gold."],
	[&"torvald", "This coin carries the Outwall's stamp, Malrik. Dockers' wages. Where did you find it?"],
	[&"malrik", "Lying in the street, Torvald. Where coin usually lies."],
	[&"obren", "Count it, Ice-king. Count all of it. Someone is counting you."],
	[&"ossavar", "Morrow-of-Glass, my daughter. She remembers both your grandfathers' coin."],
	[&"torvald", "Glass and frost. At least one of us will match the banners."],
	[&"ossavar", "Diamonds were never enough for her. Morrow, fly south."],
	[&"ysolde", "Torvald. You let me go once, on your wall. I remember. I will not hold back today."],
	[&"torvald", "Good. Holding back has always been my fault, not yours."],
	[&"ossavar", "And now the old price. Me. Whoever pays the most, I burn for."],
	[&"torvald", "I have never owned anything this old. Except my regrets."],
	[&"ossavar", "Twice each, I said. Let us make it three."],
	[&"vessa", "Everything we have, Ysolde! Take that harbour while the sky is still for sale!"],
	[&"seraphine", "Adamarch will remember who stood on the quay with her. Even if the Archon will not."],
	[&"torvald", "Remember who paid for it, Seraphine. I would like to know myself."],
	[&"ossavar", "The Laurel was broken by knives. Gold cloaks. Violet smoke. Somebody lied on my rock."],
	[&"ossavar", "The sky has chosen its master, and it is not you."],
	[&"aldra", "The harbour is burning, my lord. Adamarch does not forgive a guest who loses its harbour."],
	[&"dacian", "No... she was the best of us. Both cities killed her today."],
	[&"torvald", "Too slow. Again... the ice gives way."],
	[&"aldra", "Steel and quilting. Adamarch's coin, wearing our colours."],
]
const BRIEFING_PARAGRAPHS: Array[String] = [
	"The winter truce holds on the green fields of Evenmead. It says nothing about the south. On the Coinwater, two harbour cities who have hated each other for a thousand years have just watched their duel end, and a dragon land on the Master's empty chair.",
	"Ossavar the Twice-Sold has named the old price: gold for fire. Three auctions, three skies for sale. Adamarch, the Diamond City, has opened its harbour to Malrik and to Torvald. Across the water, Aurivane flies Vessa's red sails and Ysolde's green ones.",
	"Torvald came to keep a peace. Malrik came to buy a war. Hold the Diamond Harbour, win the sky, and count the coin carefully. Somebody else is counting too.",
]
const BRIEFING_LINE := "Gold comes by caravan from the Diamond Harbour. Bid when a dragon lands on the Tollrock (the Bid buttons, top right)."
const HINT_START := "Your gold comes from the Diamond Harbour. Build a Frost Bazaar near the Keep (worker B, then B) and train caravans (Z)."
const HINT_POSTS := "Posts open at 2:00. Caravans walk the ring road: the Diamond Harbour is near, the Admiralty Quay pays more per trip."
const HINT_STRONGHOLD := "Your Rime Keep can become a Stronghold: select it and press X (200 crystals). It opens Hoarlight Magebow, Frost Mortar (Frost Hall) and the Rimecarver (Keep)."
const HINT_ROCK := "Hold the Tollrock when the hammer falls: its master wins a bid within 10 %."
const HINT_CARVER := "Rimecarver: Z Rime Bulwark raises a wall for 8 s (two close a causeway). V Scrying Rune sees through fog."
const MSG_RIDERS := "Riders on the Gold Shoal: they want your caravans"
const MSG_AUCTION_SOON := "A dragon is landing on the Tollrock. Auction in 0:30: bid with the Bid buttons"
const MSG_LAUREL := "The Laurel duel begins at noon on the Tollrock (12:00)"
const MSG_RING := "The Laurel ring is closed to soldiers."
const MSG_GIFT := "Malrik adds 200 gold to your coffers"
const MSG_MALRIK_FELL := "Malrik falls back to the Admiralty"

## Read only.
var wins := 0
var losses := 0
var rock_hammers := 0
var seraphine: Unit
var dacian: Unit
var vessa: Wizard
var ysolde: Wizard
var malrik: Wizard
var aldra: Unit
var knives: Array = []
var wares_bought := 0
var victory_time := -1.0
var hold_started := -1.0
var seraphine_home := false
var waves_fired: Array[String] = []

var _tick := 0.0
var _fast := 0.0
var _seraphine_following := false
var _kneel_until := 0.0
var _retreating: Dictionary = {}         # Wizard -> rally


# ---------------------------------------------------------------- setup

func _init() -> void:
	super()
	use_two_harbours()
	line_ids = LINE_IDS.duplicate()
	dialogue_lines = DIALOGUE
	briefing_paragraphs = BRIEFING_PARAGRAPHS.duplicate()
	define_objectives([[&"obj_auction", "primary"], [&"obj_harbour", "primary"], [&"obj_seraphine", "primary"],
			[&"obj_hold", "primary"], [&"obj_torvald", "primary"], [&"sec_rock", "secondary"], [&"sec_wares", "secondary"]])


func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	MissionE7Base.e7_config(c, 2)
	c.mission_id = MISSION_ID
	c.title = MISSION_TITLE
	c.count_mult = COUNT_MULT.duplicate()
	c.easy_skip_types = [&"bramblehorn", &"cinder_arbalest"]
	c.defeat_on_keep_lost = true
	c.keep_lost_message = "The Rime Keep has fallen."
	c.start_tiers = {Teams.ALLY: 2, Unit.Team.ENEMY: 2}
	c.start_level = 4
	c.start_spell_points = 3
	c.start_spells = [&"rime_bolt"]
	c.level_cap = LEVEL_CAP
	c.start_crystals = START_CRYSTALS.duplicate()
	c.start_essence = 400
	c.defeat_delay = DEFEAT_DELAY
	c.victory_banner = "VICTORY\nThe sky is Adamarch's"
	c.defeat_banner = "DEFEAT"
	c.seat_sides = {Unit.Team.PLAYER: 0, Teams.ALLY: 0, Unit.Team.ENEMY: 1}
	c.seat_opponents = {Unit.Team.PLAYER: Unit.Team.ENEMY, Teams.ALLY: Unit.Team.ENEMY}
	c.seat_kingdoms = {Unit.Team.PLAYER: &"ice", Teams.ALLY: &"shadow", Unit.Team.ENEMY: &"nature"}
	c.rewards = CampaignState.MISSION_REWARDS.get(MISSION_ID, {})
	c.spotlight = {"id": &"rimecarver", "trigger": &"manual", "key_hint": "Rime Keep: B",
			"card": "Rimecarver. The wall comes to you: close a door in front of the charge, see what hides behind it."}
	return c


func _title_line() -> String:
	return "Episode 7, Mission 1: %s" % MISSION_TITLE


func _ready() -> void:
	super()
	tint_light(Color(1.0, 0.88, 0.66), 1.0, -38.0, Color(0.62, 0.62, 0.66), Color(0.30, 0.50, 0.78), Color(0.95, 0.82, 0.60))
	if tier_system:
		tier_system.max_tier = 1   # the Stronghold opens at 3:30
	rock_word_pct = float(by_difficulty(ROCK_WORD))
	auction_closed.connect(_on_hammer)
	var ev := get_node_or_null(^"/root/Events")
	if ev and ev.has_signal(&"unit_died"):
		ev.unit_died.connect(_on_any_unit_died)


# ---------------------------------------------------------------- the map

func _build_map() -> void:
	super()   # Crown Hollow: river, isle, ring road, posts, keeps, nodes
	add_two_harbours_map()
	place_building("ice_barracks", FROST_HALL, Unit.Team.PLAYER)
	place_building("ice_lodge", SNOW_LODGE, Unit.Team.PLAYER)
	var mk := place_building("shadow_keep", MALRIK_KEEP, Teams.ALLY) as Keep
	if mk:
		seat_keeps[Teams.ALLY] = mk
	seat_bases[Teams.ALLY] = MALRIK_KEEP
	seat_starts[Teams.ALLY] = MALRIK_START
	place_building("shadow_barracks", MALRIK_HALL, Teams.ALLY)
	place_building("shadow_hovel", MALRIK_HOVEL, Teams.ALLY)
	place_building("nature_barracks", GROVE_HALL, Unit.Team.ENEMY)
	place_building("fire_barracks", EMBER_HALL, Unit.Team.ENEMY)
	place_building("fire_hearth", VESSA_KEEP + Vector3(6.0, 0.0, 6.0), Unit.Team.ENEMY)
	place_building("fire_tower", VESSA_KEEP, Unit.Team.ENEMY)
	harbour = add_target(HARBOUR, float(by_difficulty(HARBOUR_HP)), HARBOUR_REGEN, _harbour_mends, "The Diamond Harbour")


func _harbour_mends() -> bool:
	return enemies_near(HARBOUR, 12.0) == 0


# ---------------------------------------------------------------- start state

func _on_navigation_ready() -> void:
	read_save(&"")
	var diff := clampi(mission_difficulty, 0, 2)
	_setup_champions()
	hero = _make_wizard(Unit.Team.PLAYER)
	_spawn(hero, Unit.Team.PLAYER, PLAYER_START)
	_claim_wizard(hero, Unit.Team.PLAYER)
	ItemDrops.ensure_inventory(hero)
	apply_splinter(hero)
	for i in 5:
		var w := _spawn(make_unit("rime_hauler"), Unit.Team.PLAYER, RIME_KEEP + Vector3(4.0 + i * 1.2, 0.0, -4.0))
		w.call(&"command_gather", node_of(Unit.Team.PLAYER, "a" if i < 3 else "b"))
	var army := [["rimeshield", 6 + (2 if diff == 0 else 0)], ["shardcaster", 3], ["rime_seer", 0 if diff == 2 else 1]]
	_spawn_fixed(army, PLAYER_RALLY, Unit.Team.PLAYER, false)
	aldra = story_npc("aldra_npc", ALDRA_SPOT)
	_spawn_fixed([["facetguard", 4]], FACET_POST, Unit.Team.PLAYER, true)
	# Malrik (ALLY Shadow bot).
	var sh := activate_seat(Teams.ALLY, &"shadow", {"crystals": 300,
			"workers": [["gloom_thrall", 3, node_of(Teams.ALLY, "a")], ["gloom_thrall", 2, node_of(Teams.ALLY, "b")]],
			"units": [["shade", 5, MALRIK_RALLY], ["nightbolt", 2, MALRIK_RALLY], ["shadow_knight", 1, MALRIK_RALLY],
					["gloom_deacon", 1, MALRIK_RALLY]],
			"wizard": {"level": 5, "spells": MALRIK_SPELLS, "pos": MALRIK_START}})
	malrik = sh.get("wizard") as Wizard
	if malrik:
		malrik.died.connect(_on_malrik_died)
	add_seat_commander(Teams.ALLY, ally_profile(&"mission_e7_01_ally", int(MALRIK_SOLDIERS[diff])))
	# Aurivane: Ysolde (the ENEMY seat's wizard) and Vessa (a second ENEMY wizard), guards at their rallies.
	ysolde = _make_wizard(Unit.Team.ENEMY)
	_spawn(ysolde, Unit.Team.ENEMY, YSOLDE_RALLY)
	_claim_wizard(ysolde, Unit.Team.ENEMY)
	raise_wizard(ysolde, 5, YSOLDE_SPELLS)
	ItemDrops.ensure_inventory(ysolde)
	mark_scripted(ysolde)
	vessa = story_wizard(&"fire", Unit.Team.ENEMY, VESSA_RALLY, 5, VESSA_SPELLS)
	for w: Wizard in [ysolde, vessa]:
		_guard_home(w)
		w.died.connect(_on_enemy_wizard_died.bind(w))
	for i in 5:
		var s := _spawn(make_unit("sprigling"), Unit.Team.ENEMY, YSOLDE_KEEP + Vector3(-4.0, 0.0, 4.0 + i))
		s.call(&"command_gather", node_of(Unit.Team.ENEMY, "a" if i < 3 else "b"))
	spawn_rows([["thornling", 6], ["wildwood_archer", 3]], YSOLDE_RALLY, 3.0, Unit.Team.ENEMY, true)
	spawn_rows([["flame_guard", 4], ["ember_archer", 2], ["blaze_rider", 2]], VESSA_RALLY, 3.0, Unit.Team.ENEMY, true)
	spawn_rows(WAVES[&"G1"], ROCK, 4.0, Unit.Team.ENEMY, true)
	spawn_rows(WAVES[&"G2"], GOLD_SHOAL + Vector3(8.0, 0.0, 2.0), 2.5, Unit.Team.ENEMY, true)
	# The dragons wait off the field; Ossavar on the chair.
	spawn_dragon("gilt_dragon", Vector3(30.0, 0.0, -58.0))
	spawn_dragon("prism_dragon", Vector3(38.0, 0.0, -58.0))
	spawn_dragon("ossavar_story", CHAIR + Vector3(-1.5, 0.0, 1.5))
	add_rock_zone()
	rock.set_owner_side(1)
	rock.captured.connect(_on_rock_captured)
	for team: int in [Unit.Team.PLAYER, Teams.ALLY]:
		for p: Vector3 in [ROCK, NORTH_CAUSEWAY, SOUTH_CAUSEWAY, GOLD_SHOAL, SILVER_SHOAL, HARBOUR, VESSA_KEEP, YSOLDE_KEEP]:
			fog.reveal(team, p, 8.0)
	setup_e7_trade(120.0)
	if trade_network:
		trade_network.delivered.connect(_on_delivered)
	var gb := GoldBank.for_team(Unit.Team.PLAYER)
	if gb:
		gb.ware_bought.connect(_on_ware_bought)
	harbour.melted.connect(_on_harbour_lost)
	begin_mission([&"obj_auction", &"obj_harbour", &"obj_torvald", &"sec_rock", &"sec_wares"])
	selection.select_units([hero])


## Spawns `rows` unscaled around `center` (allies keep their spec counts on every difficulty).
func _spawn_fixed(rows: Array, center: Vector3, team: int, hold_spot: bool) -> Array:
	var out: Array = []
	var k := 0
	for row: Array in rows:
		for j in int(row[1]):
			var p := center + Vector3((k % 5) * 1.6 - 3.2, 0.0, (k / 5) * 1.7)
			var u := _spawn(make_unit(String(row[0])), team as Unit.Team, p)
			if u and hold_spot:
				mark_scripted(u)
				u.set_meta(META_HOME, u.global_position)
				_guards.append(u)
			out.append(u)
			k += 1
	return out


func _guard_home(u: Unit) -> void:
	u.set_meta(META_HOME, u.global_position)
	if not _guards.has(u):
		_guards.append(u)


func _intro() -> void:
	fire_once(&"E1")
	play_cutscene(&"e7m1_arrival", _arrival_end)


## e7m1_arrival end state: Torvald at the start, L1-L4, the first hint.
func _arrival_end() -> void:
	for id in ["L1", "L2", "L3", "L4"]:
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
		"objectives": [objective_text(&"obj_auction", false), objective_text(&"obj_harbour", false), BRIEFING_LINE],
		"rule": Loc.sink(objective_text(&"obj_torvald")),
	}


func next_auction_index() -> int:
	for i in A_TIMES.size():
		if mission_time() < A_TIMES[i]:
			return i
	return -1


func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_auction":
			if not with_counter:
				return "Win the Dragon Auctions (2 of 3)"
			if auction_open():
				return auction_line()
			var i := next_auction_index()
			if i >= 0:
				return "Win the Dragon Auctions (%d / 2 of 3), next at %s" % [wins, mmss(A_TIMES[i])]
			return "Win the Dragon Auctions (%d / 2 of 3)" % wins
		&"obj_harbour":
			if with_counter and harbour:
				return "Hold the Diamond Harbour (%d %%)" % int(round(harbour.ratio() * 100.0))
			return "Hold the Diamond Harbour"
		&"obj_seraphine":
			return "Keep Seraphine alive: bring her to the Diamond Harbour"
		&"obj_hold":
			if with_counter and hold_started >= 0.0:
				return "Hold the harbour until Aurivane's fleet turns (%s)" % mmss(hold_started + float(by_difficulty(HOLD_LEN)) - mission_time())
			return "Hold the harbour until Aurivane's fleet turns"
		&"obj_torvald":
			return "Torvald must survive"
		&"sec_rock":
			if with_counter:
				return "Hold the Tollrock when the hammer falls (%d / 3)" % rock_hammers
			return "Hold the Tollrock when the hammer falls"
		&"sec_wares":
			if with_counter:
				return "Arm Adamarch's guests: buy 2 wares (%d / 2)" % mini(wares_bought, 2)
			return "Arm Adamarch's guests: buy 2 wares"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_auction":
			return {"counter": wins, "goal": 2}
		&"obj_harbour":
			if harbour:
				return {"counter": int(harbour.hp), "goal": int(harbour.max_hp), "positions": [HARBOUR]}
		&"obj_seraphine":
			if seraphine and is_instance_valid(seraphine):
				return {"positions": [seraphine.global_position, HARBOUR]}
		&"sec_rock":
			return {"counter": rock_hammers, "goal": 3, "positions": [ROCK]}
		&"sec_wares":
			return {"counter": mini(wares_bought, 2), "goal": 2}
	return {}


# ---------------------------------------------------------------- the auctions

func _on_hammer(id: StringName, side: int, _price: int) -> void:
	var i := A_DRAGONS.find(String(id))
	if i < 0 or is_ending():
		return
	fire_once(StringName("E9a_%d" % i))
	if rock_owner() == 0:
		rock_hammers += 1
		if rock_hammers >= 3:
			set_objective(&"sec_rock", "done")
	elif objective_state("sec_rock") == "active":
		set_objective(&"sec_rock", "failed")
	if side == 0:
		wins += 1
		say_l(["L11", "L23", "L28"][i])
		set_mission_flag("e7m1_%s_won" % ["kesh", "morrow", "ossavar"][i], true)
	else:
		losses += 1
		say_l(["L12", "L24", "L29"][i])
	bind_dragon(String(id), side, DRAGON_BOND)
	objectives_changed.emit()
	if losses >= 2:
		fire_once(&"E22")
		say_l("L33")
		set_objective(&"obj_auction", "failed")
		lose(DEFEAT_DELAY)
		return
	if wins >= 2 and objective_state("obj_auction") == "active":
		set_objective(&"obj_auction", "done")
	if i == 2:
		_final()


func _on_dragon_bond_ended(id: StringName, _side: int) -> void:
	if id == &"ossavar_story":
		var u := dragon(String(id))
		if u:
			u.command_move(CHAIR + Vector3(-1.5, 0.0, 1.5))
		return
	release_dragon(String(id), true)


## True while a dragon fights for Aurivane (its waves lose 40 % / the Final 30 %).
func aurivane_dragon() -> bool:
	for id: String in dragons:
		if int((dragons[id] as Dictionary)["side"]) == 1:
			return true
	return false


func _cut(rows: Array, share: float) -> Array:
	if share <= 0.0:
		return rows
	var out: Array = []
	for row: Array in rows:
		var n := int(row[1])
		out.append([row[0], n - int(floor(float(n) * share))])
	return out


func _dragon_enemy_goal() -> Node3D:
	if harbour != null and is_instance_valid(harbour) and harbour.is_alive():
		return harbour
	return keep


# ---------------------------------------------------------------- the waves

func _wave_rows(id: StringName) -> Array:
	return _cut(WAVES[id], 0.4 if aurivane_dragon() else 0.0)


func _tick_waves() -> void:
	var t := mission_time()
	if t >= STRONGHOLD_AT and fire_once(&"E4"):
		if tier_system:
			tier_system.max_tier = 2
		if hud:
			hud.show_message(HINT_STRONGHOLD, 12.0)
	if t >= 60.0 and fire_once(&"E2"):
		say_l("L5")
		if hud:
			hud.show_message(HINT_POSTS, 8.0)
		flash_ring(BAZAAR_SPOT, 3.0)
	if t >= W1_AT and fire_once(&"E5"):
		waves_fired.append("W1")
		say_l("L7")
		say_l("L8")
		if hud:
			hud.show_message(MSG_RIDERS, 5.0)
		for u: Variant in spawn_rows(_wave_rows(&"W1"), EMBER_HALL + Vector3(-6.0, 0.0, 0.0), 0.0, Unit.Team.ENEMY, false, true):
			_raider(u as Unit)
	if t >= W2_AT and fire_once(&"W2"):
		waves_fired.append("W2")
		route_wave(_wave_rows(&"W2"), GROVE_HALL + Vector3(-6.0, 0.0, 6.0), [SOUTH_CAUSEWAY, ROCK, NORTH_CAUSEWAY], HARBOUR)
	for i in A_TIMES.size():
		if t >= A_TIMES[i] - 30.0 and fire_once(StringName("pre_A%d" % i)):
			say_l(["L10", "L23a", "L27"][i])
			if hud:
				hud.show_message(MSG_AUCTION_SOON, 6.0)
		if t >= A_TIMES[i] and not auction_open() and fire_once(StringName("A%d" % i)) and not sold(A_DRAGONS[i]):
			open_auction(A_DRAGONS[i], A_NAMES[i], int(by_difficulty(CEILINGS[i])))
	if t >= W3_AT and fire_once(&"W3"):
		waves_fired.append("W3")
		route_wave(_wave_rows(&"W3"), EMBER_HALL + Vector3(-6.0, 0.0, 0.0), [GOLD_SHOAL], HARBOUR)
		_wizard_to_wave(vessa, [GOLD_SHOAL], HARBOUR)
	if t >= HERALD_AT and fire_once(&"E9"):
		say_l("L13")
		if hud:
			hud.show_message(MSG_LAUREL, 6.0)
		flash_ring(ROCK, 5.0)
	if t >= DUEL_AT and fire_once(&"E10"):
		_laurel_duel()
	if t >= KNIVES_AT and fire_once(&"E11"):
		play_cutscene(&"e7m1_laurel", _laurel_end)
	if t >= GUARD_AT and fire_once(&"guard"):
		var target := seraphine.global_position if seraphine and is_instance_valid(seraphine) else HARBOUR
		route_wave(_wave_rows(&"guard"), SOUTH_FOOT + Vector3(6.0, 0.0, -6.0), [SOUTH_CAUSEWAY], target)
	if t >= GIFT_AT and fire_once(&"E14"):
		for id in ["L20", "L21", "L22", "L22b"]:
			say_l(id)
		add_gold(200)
		if hud:
			hud.show_message(MSG_GIFT, 5.0)
	if t >= W4_AT and fire_once(&"E16"):
		waves_fired.append("W4")
		say_l("L25")
		say_l("L26")
		route_wave(_wave_rows(&"W4"), GROVE_HALL + Vector3(-6.0, 0.0, 6.0), [SILVER_SHOAL, MALRIK_RALLY, Vector3(-40.0, 0.0, 0.0)], HARBOUR)
		_wizard_to_wave(ysolde, [SILVER_SHOAL, MALRIK_RALLY], HARBOUR)
	if t >= W5_AT and fire_once(&"W5"):
		waves_fired.append("W5")
		for u: Variant in spawn_rows(_wave_rows(&"W5"), EMBER_HALL + Vector3(-6.0, 0.0, 0.0), 0.0, Unit.Team.ENEMY, false, true):
			_raider(u as Unit)
	if hold_started >= 0.0 and t >= hold_started + FINAL_LATE and fire_once(&"final_late"):
		route_wave(_cut(WAVES[&"final_late"], 0.3 if aurivane_dragon() else 0.0), SOUTH_FOOT, [SOUTH_CAUSEWAY, ROCK, NORTH_CAUSEWAY], HARBOUR)
	if hold_started >= 0.0 and t >= hold_started + float(by_difficulty(HOLD_LEN)):
		_hold_done()


## A raider (W1 / W5): crosses the Gold Shoal, hunts the nearest caravan, else a Rime Hauler; home after 60 s or under
## 40 % HP.
func _raider(u: Unit) -> void:
	if u == null:
		return
	u.set_meta(&"e7_raid_until", mission_time() + 60.0)
	u.set_meta(&"e7_route", [GOLD_SHOAL])
	order_wave(u, &"raid", GOLD_SHOAL)


func _refresh_e7_mode(u: Unit, mode: StringName, _hero_at: Vector3) -> bool:
	match mode:
		&"raid":
			var route: Array = u.get_meta(&"e7_route", [])
			if not route.is_empty():
				if _flat(u.global_position, route[0]) < 5.0:
					route.pop_front()
				elif u.attack_target == null and not u.is_attack_moving():
					u.command_attack_move(route[0])
				return true
			if mission_time() > float(u.get_meta(&"e7_raid_until", 0.0)) or u.hp < u.max_hp * 0.4:
				u.set_meta(META_MODE, &"home")
				u.command_move(EMBER_HALL)
				return true
			if u.attack_target == null or not (u.attack_target is Unit):
				var prey := _nearest_of(u.global_position, func(x: Unit) -> bool:
					return int(x.team) == Unit.Team.PLAYER and (Market.is_caravan_unit(x) or x.is_worker()))
				if prey:
					u.command_attack(prey)
			return true
		&"home":
			if _flat(u.global_position, EMBER_HALL) < 8.0:
				u.leave_map()
			return true
		&"knife":
			if seraphine and is_instance_valid(seraphine) and seraphine.is_alive() and not seraphine_home:
				if u.attack_target != seraphine and (u.attack_target == null or not u.attack_target is Unit):
					u.command_attack(seraphine)
				return true
			return false
	return false


func _nearest_of(at: Vector3, pred: Callable) -> Unit:
	var best: Unit = null
	var d := 1.0e9
	for n in get_tree().get_nodes_in_group(&"units"):
		var x := n as Unit
		if x == null or not x.is_alive() or is_dormant(x) or not bool(pred.call(x)):
			continue
		var dd := _flat(x.global_position, at)
		if dd < d:
			d = dd
			best = x
	return best


## An enemy wizard leaves its post with a wave (retreats home under 35 %).
func _wizard_to_wave(w: Wizard, route: Array, goal: Vector3) -> void:
	if w == null or not w.is_alive():
		return
	_guards.erase(w)
	send_route(w, route, goal)
	_retreating.erase(w)


func _tick_enemy_wizards() -> void:
	for w: Wizard in [vessa, ysolde]:
		if w == null or not is_instance_valid(w) or not w.is_alive():
			continue
		var home := VESSA_RALLY if w == vessa else YSOLDE_RALLY
		if _retreating.has(w):
			if _flat(w.global_position, home) < 4.0 and w.hp >= w.max_hp * 0.9:
				_retreating.erase(w)
				_guard_home(w)
			continue
		if not _guards.has(w) and w.hp < w.max_hp * 0.35:
			_wave_units.erase(w)
			w.remove_meta(META_MODE)
			_retreating[w] = true
			w.command_move(home)


func _on_enemy_wizard_died(_u: Unit, w: Wizard) -> void:
	_retreating.erase(w)
	_guards.erase(w)
	_wave_units.erase(w)
	w.set_meta(&"e7_back_at", mission_time() + 60.0)
	after(60.0, _enemy_wizards_back)


## The enemy wizards come back 60 s after their fall (a named timer: saving stays allowed, review 2026-10-10 #8).
func _enemy_wizards_back() -> void:
	for w: Wizard in [vessa, ysolde]:
		if w and is_instance_valid(w) and not w.is_alive() and not is_ending() \
				and mission_time() >= float(w.get_meta(&"e7_back_at", 0.0)) - 0.05:
			w.respawn(VESSA_KEEP if w == vessa else YSOLDE_KEEP)
			w.command_move(VESSA_RALLY if w == vessa else YSOLDE_RALLY)
			_retreating[w] = true


func _on_malrik_died(_u: Unit) -> void:
	if hud and not is_ending():
		hud.show_message(MSG_MALRIK_FELL, 4.0)
	after(45.0, _malrik_back)


func _malrik_back() -> void:
	if malrik and is_instance_valid(malrik) and not malrik.is_alive() and not is_ending():
		malrik.respawn(respawn_point(Teams.ALLY))


## Malrik's scripted pushes (A1 / A3: the North Causeway foot; W4: the shore road; the Final: the harbour's side).
func _tick_malrik() -> void:
	var t := mission_time()
	var spot := MALRIK_RALLY
	if (t >= A_TIMES[0] - 20.0 and t < A_TIMES[0] + 60.0) or (t >= A_TIMES[2] - 20.0 and t < A_TIMES[2] + 60.0):
		spot = NORTH_FOOT
	elif t >= W4_AT and t < W4_AT + 150.0:
		spot = Vector3(-26.0, 0.0, -14.0)
	elif hold_started >= 0.0:
		spot = HARBOUR + Vector3(10.0, 0.0, 0.0)
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or not u.is_alive() or int(u.team) != Teams.ALLY or u.is_worker() or u is Wizard:
			continue
		if u.attack_target != null or u.is_attack_moving():
			continue
		if _flat(u.global_position, spot) > 7.0:
			u.command_attack_move(spot)


# ---------------------------------------------------------------- the Laurel and Seraphine

func _laurel_duel() -> void:
	seraphine = make_unit("seraphine_story")
	_spawn(seraphine, Unit.Team.PLAYER, DUEL_S)
	seraphine.add_modifier(&"mission:e7_difficulty", {"max_hp": float(by_difficulty(SERAPHINE_HP)) - 1000.0})
	seraphine.hp = seraphine.max_hp
	seraphine.add_modifier(&"mission:wounded", {"move_speed": -1.6})
	mark_scripted(seraphine)
	dacian = make_unit("dacian_story")
	_spawn(dacian, Unit.Team.NEUTRAL, DUEL_D)
	mark_scripted(dacian)
	set_truce([seraphine, dacian], true, Unit.TRUCE_ALL)
	set_dormant(dacian, true)
	set_dormant(seraphine, true)
	say_l("L14")
	say_l("L15")
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and u != seraphine and u != dacian and _flat(u.global_position, ROCK) < 6.0 \
				and Teams.side_of(int(u.team)) == 0 and u.can_move():
			u.displace(ROCK + (u.global_position - ROCK).normalized() * 9.0, 0.6)
			if fire_once(&"ring_msg") and hud:
				hud.show_message(MSG_RING, 4.0)


## e7m1_laurel end state: the knives on the rim, Dacian led away east, obj_seraphine active, the knives on her.
func _laurel_end() -> void:
	say_l("L16")
	say_l("L17")
	if seraphine == null or not is_instance_valid(seraphine):
		_laurel_duel()
	set_dormant(seraphine, false)
	set_truce([seraphine], false, Unit.TRUCE_ALL)
	seraphine.died.connect(_on_seraphine_died)
	if dacian and is_instance_valid(dacian):
		dacian.command_move(DACIAN_EXIT)
		set_dormant(dacian, false)
		after(25.0, func() -> void:
			if is_instance_valid(dacian) and dacian.is_alive():
				dacian.leave_map())
	knives = spawn_rows(WAVES[&"knives"], RIM, 2.0, Unit.Team.ENEMY, false)
	for v: Variant in knives:
		order_wave(v as Unit, &"knife", DUEL_S)
		(v as Unit).command_attack(seraphine)
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == Unit.Team.PLAYER and u.unit_type and u.unit_type.id == &"rimecarver" \
				and _flat(u.global_position, RIM) < 10.0:
			set_mission_flag("e7m1_rune_saw_boat", true)
	set_objective(&"obj_seraphine", "active")


func _tick_seraphine() -> void:
	if seraphine == null or not is_instance_valid(seraphine) or not seraphine.is_alive() or not has_fired(&"E11"):
		return
	if seraphine_home:
		if _kneel_until > 0.0 and mission_time() >= _kneel_until:
			_kneel_until = 0.0
			seraphine.hp = seraphine.max_hp * 0.5
			set_dormant(seraphine, false)
		elif _kneel_until <= 0.0 and _flat(seraphine.global_position, HARBOUR) > 8.0 and seraphine.attack_target == null:
			seraphine.command_attack_move(HARBOUR + Vector3(3.0, 0.0, 0.0))
		return
	if not _seraphine_following:
		for n in get_tree().get_nodes_in_group(&"units"):
			var u := n as Unit
			if u and u.is_alive() and u != seraphine and int(u.team) == Unit.Team.PLAYER and not u.is_worker() \
					and u.is_commandable() and _flat(u.global_position, seraphine.global_position) < 6.0:
				_seraphine_following = true
				fire_once(&"E12")
				say_l("L18")
				break
		return
	if _flat(seraphine.global_position, HARBOUR) < 8.0:
		seraphine_home = true
		fire_once(&"E13")
		say_l("L19")
		set_objective(&"obj_seraphine", "done")
		_guards.erase(seraphine)
		guard_life(seraphine, _on_seraphine_home_down)
		return
	if seraphine.attack_target != null and is_instance_valid(seraphine.attack_target):
		return
	var lead := hero.global_position if hero_alive() else HARBOUR
	var goal := lead if _flat(lead, HARBOUR) > 6.0 and _flat(seraphine.global_position, lead) > 4.0 else HARBOUR
	if _flat(seraphine.global_position, goal) > 3.0:
		seraphine.command_move(goal)


## Seraphine at home: she kneels 10 s instead of dying.
func _on_seraphine_home_down(_u: Unit) -> void:
	if _kneel_until <= 0.0:
		_kneel_until = mission_time() + 10.0
		set_dormant(seraphine, true)


func _on_seraphine_died(_u: Unit) -> void:
	if is_ending() or seraphine_home:
		return
	fire_once(&"E21")
	say_l("L36")
	set_objective(&"obj_seraphine", "failed")
	lose(DEFEAT_DELAY)


func _on_any_unit_died(u: Node) -> void:
	var unit := u as Unit
	if unit == null or is_ending() or unit.unit_type == null:
		return
	if unit.unit_type.id == &"gold_knife":
		flash_ring(unit.global_position, 1.5)
		if fire_once(&"E24"):
			say_l("L16b")


# ---------------------------------------------------------------- the end

func _final() -> void:
	if wins < 2 or not fire_once(&"E18"):
		return
	hold_started = mission_time()
	set_objective(&"obj_hold", "active")
	say_l("L30")
	waves_fired.append("Final")
	var share := 0.3 if int((dragons.get("ossavar_story", {"side": -1}) as Dictionary)["side"]) == 1 else 0.0
	route_wave(_cut(WAVES[&"final_fire"], share), EMBER_HALL + Vector3(-6.0, 0.0, 0.0), [GOLD_SHOAL], HARBOUR)
	route_wave(_cut(WAVES[&"final_nature"], share), GROVE_HALL + Vector3(-6.0, 0.0, 6.0), [SOUTH_CAUSEWAY, ROCK, NORTH_CAUSEWAY], HARBOUR)
	_wizard_to_wave(vessa, [GOLD_SHOAL], HARBOUR)
	_wizard_to_wave(ysolde, [SOUTH_CAUSEWAY, ROCK, NORTH_CAUSEWAY], HARBOUR)


func _hold_done() -> void:
	if is_ending() or not fire_once(&"E19"):
		return
	victory_time = mission_time()
	set_objective(&"obj_hold", "done")
	for id: StringName in [&"obj_harbour", &"obj_torvald"]:
		set_objective(id, "done")
	if objective_state("sec_wares") == "active":
		set_objective(&"sec_wares", "failed")
	_record_flags()
	clear_waves()
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == Unit.Team.ENEMY and not u is Wizard and _flat(u.global_position, VESSA_KEEP) > 20.0 \
				and _flat(u.global_position, YSOLDE_KEEP) > 20.0:
			u.leave_map()
	play_cutscene(&"e7m1_dusk", _dusk_end)


func _dusk_end() -> void:
	for id in ["L31", "L32", "L34"]:
		say_l(id)
	win(1.0)


func _record_flags() -> void:
	set_mission_flag("e7m1_auctions_won", wins)
	set_mission_flag("e7m1_time", int(victory_time))
	var bonus := 0
	if objective_state("sec_rock") == "done":
		bonus += 250
	if objective_state("sec_wares") == "done":
		bonus += 150
	record_torvald_essence(bonus)


func _on_harbour_lost(_h: Heartfrost) -> void:
	if is_ending():
		return
	fire_once(&"E20")
	say_l("L35")
	set_objective(&"obj_harbour", "failed")
	lose(DEFEAT_DELAY)


func _on_player_hero_fell() -> void:
	fire_once(&"E23")
	say_l("L37")
	set_objective(&"obj_torvald", "failed")
	super()


func _on_rock_captured(_z: MissionZone, side: int) -> void:
	if side == 0 and not is_ending() and fire_once(&"E6"):
		say_l("L9")
		if hud:
			hud.show_message(HINT_ROCK, 8.0)


func _on_delivered(team: int, _caravan: Node, _amount: int, _post: Node) -> void:
	if team == Unit.Team.PLAYER and not is_ending() and fire_once(&"E3"):
		say_l("L6")


func _on_ware_bought(_id: StringName) -> void:
	wares_bought += 1
	if wares_bought >= 2 and not is_ending() and objective_state("sec_wares") == "active":
		fire_once(&"E25")
		say_l("L38")
		set_objective(&"sec_wares", "done")


func _tick_events() -> void:
	if not has_fired(&"E8"):
		for n in get_tree().get_nodes_in_group(&"units"):
			var u := n as Unit
			if u and int(u.team) == Unit.Team.PLAYER and u.unit_type and u.unit_type.id == &"rimecarver":
				fire_once(&"E8")
				if hud:
					hud.show_message(HINT_CARVER, 12.0)
				show_spotlight()
				break


# ---------------------------------------------------------------- save / load

func save_state(ids: Dictionary = {}) -> Dictionary:
	var d := super(ids)
	d["e7m1"] = {"wins": wins, "losses": losses, "rock": rock_hammers, "wares": wares_bought, "hold": hold_started,
			"home": seraphine_home, "harbour": harbour.hp if harbour else 0.0}
	return d


func load_state(d: Dictionary, nodes: Dictionary = {}) -> void:
	super(d, nodes)
	var m: Dictionary = d.get("e7m1", {})
	wins = int(m.get("wins", 0))
	losses = int(m.get("losses", 0))
	rock_hammers = int(m.get("rock", 0))
	wares_bought = int(m.get("wares", 0))
	hold_started = float(m.get("hold", -1.0))
	seraphine_home = bool(m.get("home", false))
	if harbour and m.has("harbour"):
		harbour.hp = float(m["harbour"])
	if tier_system:
		tier_system.max_tier = 2 if has_fired(&"E4") else 1
	# Review 2026-10-10 #3: the hooks set mid-mission (_laurel_end, Seraphine home) are not part of the rebuilt start.
	if seraphine and is_instance_valid(seraphine) and has_fired(&"E11"):
		if not seraphine.died.is_connected(_on_seraphine_died):
			seraphine.died.connect(_on_seraphine_died)
		if seraphine_home:
			guard_life(seraphine, _on_seraphine_home_down)


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
		tick_rock(0.25)
		_tick_auction()
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.5
		_tick_waves()
		_tick_dragons()
		_tick_enemy_wizards()
		_tick_seraphine()
		_tick_malrik()
		_tick_events()
		objectives_changed.emit()
		if hud and mission_hud == null:
			hud.set_objective(_objective_text())
