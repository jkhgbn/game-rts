class_name MissionE7_04
extends MissionE7Base
## Episode 7, mission 4 "The Year of Two Skies" (docs/design/mission-e7-04.md): the episode's finale on the whole
## Coinwater. P1 "The Full Strait": Torvald + Malrik (ALLY) against Aurivane, take the Tollrock (or 11:00). P2 "Two
## Skies": Malrik buys every dragon, Aurivane withdraws, a truce on the sand (0:40). P3 "The Turn": Malrik orders the
## strait burnt, Torvald says no; Malrik's seat turns enemy, Ossavar joins Torvald. P4 "Hold the Rock" against Malrik's
## assaults (pay his dragons home at the Bazaar). P5 "Still the Sea" from 22:00 (spec 21:00, see below): three channels at the lighthouse.
## Then ep7_ending. Spotlight: the Shardguard.
##
## Built deviations (2026-10-09, from the spec):
## - Two Harbours = Crown Hollow re-dressed (MissionE7Base). Aurivane is one ENEMY team (Ysolde's north-east keep +
##   Vessa's south-east quarter; no Commanders, scripted waves). Malrik is the ALLY seat with a Commander until the turn;
##   switch_seat_side moves his seat to ENEMY_2 (10 s grace) and his Commander is paused (his waves are scripted).
## - Galleys are tower buildings on the river banks (crimson: Aurivane's, east bank; silver: Malrik's, west bank): their
##   tower shot is the broadside, melee can hit them, a frozen galley is put at peace (silent).
## - The stone's hunger counts deaths within 20 m of the river line (|x| <= 20); Hollow Surge = +15 % damage modifier.
## - Pay-offs are a mission button panel (needs the Bazaar). The strait thirds are the river's north reach (west),
##   south reach (east) and the moat ring.
## - Story floor: Still the Sea opens at 22:00 (spec 21:00; the scripted run won at 24:22 play time with 21:00), "the
##   sea stills at the noon slack tide".

const MISSION_ID := &"e7m4"
const MISSION_TITLE := "The Year of Two Skies"

const ROCK_CAP_AT := 660.0
const W1_AT := 210.0
const SUNWAKE_AT := 300.0
const W2_AT := 360.0
const MALRIK_PUSH_AT := 450.0
const W3_AT := 510.0
const TRUCE_LEN := 40.0
const GRACE := 10.0
const SILVER_FIRE := 20.0
const STILL_AT := 1320.0
const STILL_AFTER_TURN := 630.0
const STAGE_GAP := 30.0
const STAGE_NEED: Array[float] = [10.0, 15.0, 20.0]
const ROCK_LOST: Array[float] = [45.0, 30.0, 20.0]
const PAY := {"gilt_dragon": [300, 400, 500], "prism_dragon": [350, 500, 650], "sunwake": [350, 450, 550]}
const PAY_NAMES := {"gilt_dragon": "Kesh", "prism_dragon": "Morrow", "sunwake": "Sunwake"}
const GALLEY_HP: Array[float] = [700.0, 900.0, 1100.0]
const METER_STEP: Array[float] = [0.75, 1.0, 1.25]
const SUNWAKE_CEILING: Array[int] = [450, 600, 750]
const WIZARD_LEVEL: Array[int] = [6, 7, 8]
const START_CRYSTALS: Array[int] = [600, 450, 350]
const COUNT_MULT: Array[float] = [0.6, 1.0, 1.4]
const LEVEL_CAP := 8
const DEFEAT_DELAY := 3.0
const NO_SAVE_ESSENCE := 600
const MALRIK_SOLDIERS: Array[int] = [10, 8, 6]
const CRIMSON := {&"CG-W": Vector3(2.0, 0.0, -30.0), &"CG-M": Vector3(9.0, 0.0, -20.0), &"CG-E": Vector3(14.0, 0.0, 30.0)}
const SILVER := {&"SG-W": Vector3(-15.0, 0.0, -30.0), &"SG-E": Vector3(-4.0, 0.0, 30.0), &"SG-M": Vector3(-14.0, 0.0, -18.0)}
const BAND := {&"west": 0, &"east": 1, &"moat": 2}
const SHORE_WEST := Vector3(-48.0, 0.0, 0.0)
const MALRIK_HOME := Vector3(-38.0, 0.0, -42.0)   ## after the turn his field army stands behind his keep (away from the rock)
const MALRIK_SPELLS: Array[StringName] = [&"shadow_lance", &"shadow_lance", &"shadow_lance", &"soul_siphon", &"soul_siphon", &"soul_siphon", &"umbral_shroud", &"umbral_shroud"]
const VESSA_SPELLS: Array[StringName] = [&"fireball", &"fireball", &"fireball", &"ember_step", &"ember_step", &"kindle", &"kindle"]
const YSOLDE_SPELLS: Array[StringName] = [&"thornburst", &"thornburst", &"thornburst", &"wild_bloom", &"wild_bloom", &"call_the_thicket"]
const TORVALD_PROFILE := &"mission_e7_04_ally"

const WAVES := {
	&"G1": [["gilded_spear", 4], ["flame_guard", 3], ["ember_archer", 2], ["thornling", 2]],
	&"G2": [["gilded_spear", 3], ["wildwood_archer", 2]],
	&"W1": [["blaze_rider", 4]],
	&"W2": [["thornling", 6], ["wildwood_archer", 3], ["vinelasher", 2], ["bramblesage", 1]],
	&"W3": [["flame_guard", 6], ["ember_archer", 3], ["pyre_adept", 2], ["kilnwarden", 1]],
	&"M1": [["shade", 6], ["nightbolt", 3], ["shadow_knight", 1], ["gloom_deacon", 1]],
	&"M2": [["grave_hound", 6], ["barrow_ghoul", 4]],
	&"M3": [["shade", 6], ["hexweaver", 3], ["hollow_oathsworn", 2]],
	&"M4": [["shadow_knight", 2], ["shade", 4], ["nightbolt", 3]],
	&"M5": [["shade", 8], ["nightbolt", 4], ["shadow_knight", 2], ["hexweaver", 2], ["gloom_deacon", 1]],
	&"M6": [["grave_hound", 4], ["barrow_ghoul", 3]],
	&"S1": [["shade", 6], ["barrow_ghoul", 2], ["nightbolt", 2]],
	&"S2": [["grave_hound", 4], ["shadow_knight", 2]],
	&"S3": [["shade", 8], ["nightbolt", 4], ["hollow_oathsworn", 2], ["shadow_knight", 1]],
}
## Malrik's assaults after the turn: [seconds after T, wave, kind (rock / base / raid), dragon or ""].
const ASSAULTS := [[90.0, &"M1", "rock", "gilt_dragon"], [180.0, &"M2", "raid", ""], [270.0, &"M3", "rock", "prism_dragon"],
		[360.0, &"M4", "base", "sunwake"], [450.0, &"M5", "rock", "all"], [540.0, &"M6", "raid", ""]]

const LINE_IDS: Array[String] = ["L1", "L2", "L3", "L4", "L5", "L6", "L7", "L8", "L9", "L10", "L11", "L12", "L13", "L14", "L15", "L16", "L17", "L18", "L19", "L20", "L21", "L22", "L23", "L24", "L25", "L25a", "L25b", "L26", "L27", "L28", "L29", "L30", "L31", "L32", "L32b", "L33", "L33b", "L34", "L35", "L36", "L37", "L38", "L39", "L40", "L41", "L42", "L43"]
const DIALOGUE := [
	[&"ossavar", "The Year of Two Skies comes round again. Every ship. Every dragon. One strait."],
	[&"malrik", "Today we finish Aurivane, Torvald. Take the rock. I will handle the sky."],
	[&"torvald", "You handled the Laurel too, Malrik. I have not forgotten whose knives they were."],
	[&"malrik", "Then remember it after we win. Victory is a wonderful eraser."],
	[&"aldra", "Crimson sails on the water. They will shell the shore road. Sink them, or stay off it."],
	[&"vessa", "Last chance to pick the right side, Torvald! I'm told I'm very forgiving!"],
	[&"torvald", "You are told many things, Vessa. Most of them by people standing behind you."],
	[&"ossavar", "One small sale before the great one. Sunwake, Aurivane's pride. Who pays?"],
	[&"torvald", "Sunwake flies with us. For the morning, at least."],
	[&"ossavar", "Sunwake keeps her old masters. For now."],
	[&"ysolde", "Malrik! Every grave you dig, I will plant over. Every single one!"],
	[&"malrik", "Then you will be a very busy gardener, Ysolde."],
	[&"aldra", "One red sail under. The sea keeps the coin, as usual."],
	[&"seraphine", "The rock is Adamarch's! The Archon is watching from the spire, Ice-king. So is everyone."],
	[&"diamond_archon", "Empty the pits. All of them. Let the sky be white and silver by noon."],
	[&"ossavar", "Every dragon on the Coinwater changes sides in one morning. I have seen this before."],
	[&"vessa", "He bought the whole SKY? Ysolde, pull back! Everyone, back to the ships!"],
	[&"dacian", "Enough. Seraphine, the cloth. We end this on the sand, the old way."],
	[&"seraphine", "A truce, Sunblade. No bets. No knives. Just us."],
	[&"malrik", "Burn them. Both fleets, the sand, the cloth. A strait of dead feeds the stone for years."],
	[&"obren", "Yes, Bishop. A whole sea of them. Feed me, and I will crown you king of the deep."],
	[&"torvald", "No."],
	[&"malrik", "You said that once before, in your hall. \"For now,\" you said."],
	[&"torvald", "I am done waiting, Malrik. Aldra. Everyone. To the rock."],
	[&"ossavar", "You paid me once, Ice-king, in clean coin. That bond still holds. I fly with you."],
	[&"ossavar", "You never bought me, Ice-king. That is why I will fly with you."],
	[&"ossavar", "And you sheltered the Outwall when nobody paid. I remember debts."],
	[&"vessa", "Torvald? You're fighting HIM? ...Fine. Aurivane stands down. Don't make me regret it."],
	[&"malrik", "Kesh. Morrow. Sunwake. I filled your hoards to the brim. Earn them."],
	[&"aldra", "My lord, the Bazaar. A dragon serves whoever filled the hoard last. Pay them to fly away."],
	[&"ossavar", "Paid to go home. The one price he never tried."],
	[&"hush", "There is always another night, Ice-king. Tonight it is yours."],
	[&"torvald", "Then I will spend it awake."],
	[&"brannet", "Those oars were ours! Nobody from the Outwall rows for the candle-man!"],
	[&"aldra", "Silver sinks the same as crimson, my lord. Slower, perhaps. Heavier pride."],
	[&"obren", "More, Bishop. The sea is generous tonight."],
	[&"malrik", "Do you hear it, Torvald? Every one of them is mine now. Every single one."],
	[&"ossavar", "He walked out once, and the sea went still. Your turn, Ice-king. Go to the light."],
	[&"aldra", "The west water is glass. Their galleys are stuck fast."],
	[&"seraphine", "The east is frozen! Dacian, back to back!"],
	[&"malrik", "Torvald! You never said no to anyone in your life. Why start with me?"],
	[&"torvald", "Because I finally saw what you were buying."],
	[&"torvald", "Enough."],
	[&"ossavar", "I have heard that word once before. It sounded better from you."],
	[&"torvald", "The sea... was never mine to hold."],
	[&"aldra", "The rock is his. The stone will drink the whole strait now."],
	[&"hush", "The Bishop sends his regrets. I will deliver them in person, later."],
]
const BRIEFING_PARAGRAPHS: Array[String] = [
	"Nearly four hundred years ago, in the Year of Two Skies, Adamarch emptied its diamond pits in one night, and every dragon on the Coinwater changed sides by morning. Tonight the Diamond Archon signs the same order, with Malrik's hand on her pen.",
	"At dawn both cities sail everything they own into the strait. Aurivane holds the Tollrock with Vessa and Ysolde. Adamarch attacks it with Torvald and Malrik. The truce of the Stilled Sea is a hundred and thirty years old, and it ends today.",
	"Torvald knows whose knives broke the Laurel. He knows whose masks walked out of the old adit. He has waited for Malrik to become someone else. Today he will find out how long a patient man can wait.",
]
const BRIEFING_LINE := "Crimson galleys shell the shore: sink them or stay off the shore road."
const HINT_START := "Crimson galleys shell the shore. Shardcasters on the bank, Frost Mortars and Rime Spires reach them."
const HINT_PAY := "Dragons serve whoever filled the hoard last. Pay them home with the buttons on the right (a Bazaar is needed)."
const MSG_GRACE := "Malrik pulls back to his harbour"
const MSG_MALRIK_FELL := "Malrik sinks into the shadows of his hull"
const MSG_SURGE := "Hollow Surge: Malrik's soldiers strike harder"
const MSG_STAGE_READY := "The lighthouse is ready: channel the next stage"
const MSG_SUNWAKE_SOON := "A dragon is landing on the Tollrock. Auction in 0:30: bid with the Bid buttons"

## Read only.
var phase := 1
var turn_time := -1.0
var vessa: Wizard
var ysolde: Wizard
var malrik: Wizard
var hush: Unit
var dacian: Unit
var seraphine: Unit
var crimson := {}
var silver := {}
var red_sunk := 0
var silver_sunk := 0
var paid: Array[String] = []
var meter := 0.0
var meter_peak := 0.0
var rock_lost_for := 0.0
var stage := 0                          ## stages done (0-3)
var stage_progress := 0.0
var stage_ready_at := 0.0
var victory_time := -1.0
var waves_fired: Array[String] = []
var people := false
var pits := false

var _tick := 0.0
var _fast := 0.0
var _pay_panel: Control
var _surge_until := 0.0
var _hush_returned := false
var _malrik_cmd: Node
var _galley_type_red: BuildingType
var _galley_type_silver: BuildingType


# ---------------------------------------------------------------- setup

func _init() -> void:
	super()
	use_two_harbours()
	line_ids = LINE_IDS.duplicate()
	dialogue_lines = DIALOGUE
	briefing_paragraphs = BRIEFING_PARAGRAPHS.duplicate()
	define_objectives([[&"obj_rock", "primary"], [&"obj_truce", "primary"], [&"obj_hold", "primary"],
			[&"obj_still", "primary"], [&"obj_torvald", "primary"], [&"sec_red", "secondary"],
			[&"sec_dragons", "secondary"], [&"sec_silver", "secondary"]])
	_galley_type_red = MissionE5Base.local_building("fire_tower", "crimson_galley", "Crimson Galley", 900.0)
	_galley_type_silver = MissionE5Base.local_building("shadow_tower", "silver_galley", "Silver Galley", 900.0)


func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	MissionE7Base.e7_config(c, 3)
	c.mission_id = MISSION_ID
	c.title = MISSION_TITLE
	c.count_mult = COUNT_MULT.duplicate()
	c.easy_skip_types = [&"hollow_oathsworn", &"kilnwarden"]
	c.defeat_on_keep_lost = true
	c.keep_lost_message = "The Rime Keep has fallen."
	c.start_tiers = {Unit.Team.PLAYER: 3, Teams.ALLY: 3, Unit.Team.ENEMY: 2}
	c.helper_start_called = true
	c.start_level = 6
	c.start_spell_points = 5
	c.start_spells = [&"rime_bolt"]
	c.level_cap = LEVEL_CAP
	c.start_crystals = START_CRYSTALS.duplicate()
	c.start_essence = 150
	c.defeat_delay = DEFEAT_DELAY
	c.victory_banner = "VICTORY\nThe sea is still"
	c.defeat_banner = "DEFEAT"
	c.seat_sides = {Unit.Team.PLAYER: 0, Teams.ALLY: 0, Unit.Team.ENEMY: 1, Teams.ENEMY_2: 1}
	c.seat_opponents = {Unit.Team.PLAYER: Unit.Team.ENEMY, Teams.ALLY: Unit.Team.ENEMY, Teams.ENEMY_2: Unit.Team.PLAYER}
	c.seat_kingdoms = {Unit.Team.PLAYER: &"ice", Teams.ALLY: &"shadow", Unit.Team.ENEMY: &"nature", Teams.ENEMY_2: &"shadow"}
	c.rewards = CampaignState.MISSION_REWARDS.get(MISSION_ID, {})
	c.spotlight = {"id": &"shardguard", "trigger": &"manual", "key_hint": "Rime Keep: C",
			"card": "Shardguard. The halberd that says no: charges stop, divers turn, archers live."}
	return c


func _title_line() -> String:
	return "Episode 7, Mission 4: %s" % MISSION_TITLE


func _ready() -> void:
	super()
	tint_light(Color(1.0, 0.86, 0.70), 0.95, -22.0, Color(0.62, 0.60, 0.64), Color(0.38, 0.52, 0.78), Color(0.98, 0.78, 0.58))
	var ev := get_node_or_null(^"/root/Events")
	if ev and ev.has_signal(&"unit_died"):
		ev.unit_died.connect(_on_any_unit_died)
	auction_closed.connect(_on_hammer)


# ---------------------------------------------------------------- the map

func _build_map() -> void:
	super()
	add_two_harbours_map()
	place_building("ice_barracks", FROST_HALL, Unit.Team.PLAYER)
	place_building("ice_lodge", SNOW_LODGE, Unit.Team.PLAYER)
	place_building("ice_lodge", SNOW_LODGE + Vector3(0.0, 0.0, 6.0), Unit.Team.PLAYER)
	place_building("ice_market", BAZAAR_SPOT, Unit.Team.PLAYER)
	place_building("ice_tower", Vector3(-30.0, 0.0, 30.0), Unit.Team.PLAYER)
	var mk := place_building("shadow_keep", MALRIK_KEEP, Teams.ALLY) as Keep
	if mk:
		seat_keeps[Teams.ALLY] = mk
	seat_bases[Teams.ALLY] = MALRIK_KEEP
	seat_starts[Teams.ALLY] = MALRIK_START
	place_building("shadow_barracks", MALRIK_HALL, Teams.ALLY)
	place_building("shadow_hovel", MALRIK_HOVEL, Teams.ALLY)
	place_building("shadow_tower", MALRIK_KEEP + Vector3(8.0, 0.0, 4.0), Teams.ALLY)
	place_building("nature_barracks", GROVE_HALL, Unit.Team.ENEMY)
	place_building("fire_barracks", EMBER_HALL, Unit.Team.ENEMY)
	place_building("fire_hearth", VESSA_KEEP + Vector3(6.0, 0.0, 6.0), Unit.Team.ENEMY)
	place_building("fire_tower", VESSA_KEEP, Unit.Team.ENEMY)
	var hp := float(by_difficulty(GALLEY_HP))
	if _galley_type_red:
		_galley_type_red.max_hp = hp
		for id: StringName in CRIMSON:
			var g := build_grid.spawn_complete(_galley_type_red, CRIMSON[id], Unit.Team.ENEMY)
			if g:
				crimson[id] = g
				g.destroyed.connect(_on_red_sunk)
	if _galley_type_silver:
		_galley_type_silver.max_hp = hp


# ---------------------------------------------------------------- start state

func _on_navigation_ready() -> void:
	read_save(&"e7m3")
	people = flag_on("e7m3_people")
	pits = flag_on("e7m3_pits")
	var diff := clampi(mission_difficulty, 0, 2)
	_setup_champions()
	hero = _make_wizard(Unit.Team.PLAYER)
	_spawn(hero, Unit.Team.PLAYER, PLAYER_START)
	_claim_wizard(hero, Unit.Team.PLAYER)
	ItemDrops.ensure_inventory(hero)
	apply_splinter(hero)
	carry_torvald_essence(NO_SAVE_ESSENCE)
	var haulers := 6 + (4 if people else 0)
	for i in haulers:
		var w := _spawn(make_unit("rime_hauler"), Unit.Team.PLAYER, RIME_KEEP + Vector3(4.0 + (i % 6) * 1.2, 0.0, -4.0 - (i / 6)))
		w.call(&"command_gather", node_of(Unit.Team.PLAYER, "a" if i % 2 == 0 else "b"))
	var army := [["rimeshield", 8 + (2 if diff == 0 else 0)], ["shardcaster", 4], ["rime_seer", 2], ["rimecarver", 1],
			["frost_mortar", 1 if diff == 2 else 2], ["shardguard", 2]]
	if pits:
		army.append(["facetguard", 4])
	var k := 0
	for row: Array in army:
		for j in int(row[1]):
			_spawn(make_unit(String(row[0])), Unit.Team.PLAYER, PLAYER_RALLY + Vector3((k % 6) * 1.6 - 4.0, 0.0, (k / 6) * 1.7))
			k += 1
	for i in mini(2, flag_int("e7m3_mammoths", 0)):
		_spawn(make_unit("war_mammoth"), Unit.Team.PLAYER, PLAYER_RALLY + Vector3(-6.0 - i * 4.0, 0.0, 4.0))
	for i in 2:
		_spawn(make_unit("caravan"), Unit.Team.PLAYER, BAZAAR_SPOT + Vector3(3.0 + i * 1.5, 0.0, 3.0))
	if pits:
		add_gold(600)
	# Malrik (ALLY until the turn) with Hush.
	activate_seat(Teams.ENEMY_2, &"shadow", {"crystals": 0})
	var sh := activate_seat(Teams.ALLY, &"shadow", {"crystals": 400,
			"workers": [["gloom_thrall", 3, node_of(Teams.ALLY, "a")], ["gloom_thrall", 3, node_of(Teams.ALLY, "b")]],
			"units": [["shade", 6, MALRIK_RALLY], ["nightbolt", 3, MALRIK_RALLY], ["hexweaver", 2, MALRIK_RALLY],
					["shadow_knight", 1, MALRIK_RALLY], ["gloom_deacon", 1, MALRIK_RALLY]],
			"wizard": {"level": int(WIZARD_LEVEL[diff]), "spells": MALRIK_SPELLS, "pos": MALRIK_START}})
	malrik = sh.get("wizard") as Wizard
	if malrik:
		malrik.died.connect(_on_malrik_died)
	hush = make_unit("hush_story")
	_spawn(hush, Teams.ALLY as Unit.Team, MALRIK_START + Vector3(2.0, 0.0, 2.0))
	mark_scripted(hush)
	guard_life(hush, _on_hush_down)
	_malrik_cmd = add_seat_commander(Teams.ALLY, ally_profile(TORVALD_PROFILE, int(MALRIK_SOLDIERS[diff])))
	add_seat(&"malrik", Teams.ALLY, _malrik_cmd)
	# Aurivane.
	ysolde = _make_wizard(Unit.Team.ENEMY)
	_spawn(ysolde, Unit.Team.ENEMY, YSOLDE_RALLY)
	_claim_wizard(ysolde, Unit.Team.ENEMY)
	raise_wizard(ysolde, int(WIZARD_LEVEL[diff]), YSOLDE_SPELLS)
	ItemDrops.ensure_inventory(ysolde)
	mark_scripted(ysolde)
	vessa = story_wizard(&"fire", Unit.Team.ENEMY, VESSA_RALLY, int(WIZARD_LEVEL[diff]), VESSA_SPELLS)
	for w: Wizard in [ysolde, vessa]:
		w.set_meta(META_HOME, w.global_position)
		_guards.append(w)
		w.died.connect(_on_enemy_wizard_died.bind(w))
	for i in 6:
		var s := _spawn(make_unit("sprigling"), Unit.Team.ENEMY, YSOLDE_KEEP + Vector3(-4.0, 0.0, 4.0 + i))
		s.call(&"command_gather", node_of(Unit.Team.ENEMY, "a" if i < 3 else "b"))
	spawn_rows([["thornling", 6], ["wildwood_archer", 3], ["bramblesage", 1]], YSOLDE_RALLY, 3.0, Unit.Team.ENEMY, true)
	spawn_rows([["flame_guard", 4], ["ember_archer", 3], ["blaze_rider", 2]], VESSA_RALLY, 3.0, Unit.Team.ENEMY, true)
	spawn_rows(WAVES[&"G1"], ROCK + Vector3(2.0, 0.0, -2.0), 4.0, Unit.Team.ENEMY, true)
	spawn_rows(WAVES[&"G2"], SOUTH_FOOT, 2.5, Unit.Team.ENEMY, true)
	# The dragons: Kesh with Aurivane, Morrow with Malrik, Sunwake on the roost, Ossavar on the chair.
	spawn_dragon("gilt_dragon", ROCK + Vector3(6.0, 0.0, -10.0))
	spawn_dragon("prism_dragon", MALRIK_RALLY + Vector3(-4.0, 0.0, 0.0))
	spawn_dragon("sunwake", Vector3(30.0, 0.0, -58.0))
	spawn_dragon("ossavar_story", CHAIR + Vector3(-1.5, 0.0, 1.5))
	bind_dragon("gilt_dragon", 1, 0.0)
	bind_dragon("prism_dragon", 0, 0.0)
	var morrow := dragon("prism_dragon")
	if morrow:
		morrow.team = Teams.ALLY as Unit.Team
	# Dacian and Seraphine wait at the gates (story units, at peace).
	dacian = story_npc("dacian_story", AURIVANE_GATES[0], Unit.Team.NEUTRAL)
	seraphine = story_npc("seraphine_story", Vector3(-56.0, 0.0, 20.0), Unit.Team.PLAYER)
	add_rock_zone()
	rock.set_owner_side(1)
	rock.captured.connect(_on_rock_captured)
	for team: int in [Unit.Team.PLAYER, Teams.ALLY]:
		for p: Vector3 in [ROCK, NORTH_CAUSEWAY, SOUTH_CAUSEWAY, GOLD_SHOAL, SILVER_SHOAL] + CRIMSON.values():
			fog.reveal(team, p, 8.0)
	setup_e7_trade(0.0)
	var mkt := Market.of_team(Unit.Team.PLAYER)
	var post := post_named(&"heron_ford")
	if mkt and post:
		mkt.set_route(post)
	begin_mission([&"obj_rock", &"obj_torvald", &"sec_red"])
	selection.select_units([hero])


func _intro() -> void:
	fire_once(&"E1")
	play_cutscene(&"e7m4_dawn", _dawn_end)


func _dawn_end() -> void:
	for id in ["L1", "L2", "L3", "L4", "L5"]:
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
		"objectives": [objective_text(&"obj_rock", false), BRIEFING_LINE],
		"rule": Loc.sink(objective_text(&"obj_torvald")),
	}


func silver_goal() -> int:
	return 2 if people else 3


func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_rock":
			return "Take the Tollrock"
		&"obj_truce":
			if with_counter and turn_time < 0.0 and has_fired(&"E8"):
				return "Guard the truce on the sand (%s)" % mmss(float(get_meta(&"truce_end", mission_time())) - mission_time())
			return "Guard the truce on the sand"
		&"obj_hold":
			if with_counter and rock_lost_for > 0.0:
				return "Hold the Tollrock against Malrik (lost for %d s)" % int(rock_lost_for)
			if with_counter:
				return "Hold the Tollrock against Malrik (the stone's hunger %d %%)" % int(meter)
			return "Hold the Tollrock against Malrik"
		&"obj_still":
			if with_counter:
				return "Still the sea at the lighthouse (%d / 3)" % stage
			return "Still the sea at the lighthouse"
		&"obj_torvald":
			return "Torvald must survive"
		&"sec_red":
			if with_counter:
				return "Sink Aurivane's crimson galleys (%d / 3)" % red_sunk
			return "Sink Aurivane's crimson galleys"
		&"sec_dragons":
			if with_counter:
				return "Pay Malrik's dragons home (%d / 3)" % paid.size()
			return "Pay Malrik's dragons home"
		&"sec_silver":
			if with_counter:
				return "Sink Malrik's silver galleys (%d / %d)" % [silver_sunk, silver_goal()]
			return "Sink Malrik's silver galleys"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_rock", &"obj_hold", &"obj_still":
			return {"positions": [ROCK]}
		&"sec_red":
			return {"counter": red_sunk, "goal": 3, "positions": _alive_pos_of(crimson)}
		&"sec_silver":
			return {"counter": silver_sunk, "goal": silver_goal(), "positions": _alive_pos_of(silver)}
		&"sec_dragons":
			return {"counter": paid.size(), "goal": 3}
	return {}


func _alive_pos_of(d: Dictionary) -> Array:
	var out: Array = []
	for k: Variant in d:
		var b: Variant = d[k]
		if is_instance_valid(b) and (b as Building).is_alive():
			out.append((b as Node3D).global_position)
	return out


# ---------------------------------------------------------------- P1

func _on_red_sunk(_b: Building) -> void:
	red_sunk += 1
	if not is_ending() and phase == 1:
		if fire_once(&"E6"):
			say_l("L13")
		if red_sunk >= 3:
			set_objective(&"sec_red", "done")
			set_mission_flag("e7m4_red_sunk", true)


func _on_hammer(id: StringName, side: int, _price: int) -> void:
	if id != &"sunwake" or is_ending():
		return
	fire_once(&"E4")
	say_l("L9" if side == 0 else "L10")
	set_mission_flag("e7m4_sunwake_won", side == 0)
	bind_dragon("sunwake", side, 0.0)


func _tick_p1() -> void:
	var t := mission_time()
	if t >= W1_AT and fire_once(&"E2"):
		waves_fired.append("W1")
		say_l("L6")
		say_l("L7")
		route_wave(WAVES[&"W1"], EMBER_HALL + Vector3(-6.0, 0.0, 0.0), [GOLD_SHOAL], BAZAAR_SPOT)
		_enemy_wizard_wave(vessa, [GOLD_SHOAL], BAZAAR_SPOT)
	if t >= SUNWAKE_AT - 30.0 and fire_once(&"E3"):
		say_l("L8")
		if hud:
			hud.show_message(MSG_SUNWAKE_SOON, 6.0)
	if t >= SUNWAKE_AT and fire_once(&"A_sunwake"):
		open_auction("sunwake", "Sunwake", int(by_difficulty(SUNWAKE_CEILING)))
	if t >= W2_AT and fire_once(&"E5"):
		waves_fired.append("W2")
		say_l("L11")
		say_l("L12")
		route_wave(WAVES[&"W2"], GROVE_HALL + Vector3(-6.0, 0.0, 6.0), [SILVER_SHOAL], MALRIK_KEEP)
		_enemy_wizard_wave(ysolde, [SILVER_SHOAL], MALRIK_KEEP)
	if t >= W3_AT and fire_once(&"W3"):
		waves_fired.append("W3")
		route_wave(WAVES[&"W3"], EMBER_HALL + Vector3(-6.0, 0.0, 0.0), [SOUTH_CAUSEWAY, ROCK, NORTH_CAUSEWAY], HARBOUR)
		_enemy_wizard_wave(vessa, [SOUTH_CAUSEWAY, ROCK], HARBOUR)
	if t >= MALRIK_PUSH_AT and t < MALRIK_PUSH_AT + 150.0:
		_ally_push(ROCK)
	elif t >= MALRIK_PUSH_AT + 150.0 and fire_once(&"push_home"):
		_ally_push(MALRIK_RALLY)
	if t >= ROCK_CAP_AT:
		_two_skies()


func _enemy_wizard_wave(w: Wizard, route: Array, goal: Vector3) -> void:
	if w == null or not w.is_alive():
		return
	_guards.erase(w)
	send_route(w, route, goal)


func _tick_enemy_wizards() -> void:
	for w: Wizard in [vessa, ysolde]:
		if w == null or not is_instance_valid(w) or not w.is_alive() or _guards.has(w) or phase > 1:
			continue
		if w.hp < w.max_hp * 0.35:
			_wave_units.erase(w)
			w.remove_meta(META_MODE)
			w.command_move(w.get_meta(META_HOME, VESSA_RALLY))
			_guards.append(w)


func _on_enemy_wizard_died(_u: Unit, w: Wizard) -> void:
	_guards.erase(w)
	_wave_units.erase(w)
	w.set_meta(&"e7_back_at", mission_time() + 60.0)
	after(60.0, _enemy_wizards_back)


## The enemy wizards come back 60 s after their fall (a named timer: saving stays allowed, review 2026-10-10 #8).
func _enemy_wizards_back() -> void:
	for w: Wizard in [vessa, ysolde]:
		if w and is_instance_valid(w) and not w.is_alive() and not is_ending() 				and mission_time() >= float(w.get_meta(&"e7_back_at", 0.0)) - 0.05:
			w.respawn(VESSA_KEEP if w == vessa else YSOLDE_KEEP)
			_guards.append(w)
			if phase > 1:
				set_truce([w], true, Unit.TRUCE_ALL)


func _ally_push(at: Vector3) -> void:
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or not u.is_alive() or int(u.team) != Teams.ALLY or u.is_worker() or u is Wizard or dragons_has_unit(u):
			continue
		if u.attack_target == null and not u.is_attack_moving() and _flat(u.global_position, at) > 6.0:
			u.command_attack_move(at)


func _on_rock_captured(_z: MissionZone, side: int) -> void:
	if is_ending():
		return
	if side == 0 and phase == 1:
		_two_skies()


# ---------------------------------------------------------------- P2, P3

func _two_skies() -> void:
	if not fire_once(&"E7"):
		return
	phase = 2
	say_l("L14")
	set_objective(&"obj_rock", "done")
	if objective_state("sec_red") == "active":
		set_objective(&"sec_red", "failed")
	if auction_open():
		auction["ends"] = mission_time()
		_tick_auction()
	fire_once(&"E8")
	play_cutscene(&"e7m4_two_skies", _two_skies_end)


func _two_skies_end() -> void:
	for id in ["L15", "L16", "L17", "L18", "L19"]:
		say_l(id)
	clear_waves()
	# every dragon goes to Malrik (circling the Admiralty, at peace until the turn)
	for id: String in ["gilt_dragon", "prism_dragon", "sunwake"]:
		release_dragon(id)
		var u := dragon(id)
		if u:
			u.command_move(Vector3(2.0, 0.0, -50.0))
	# the crimson galleys leave; Aurivane withdraws (field units home and gone, buildings and wizards at peace)
	for id: StringName in crimson:
		var g: Variant = crimson[id]
		if is_instance_valid(g) and (g as Building).is_alive():
			(g as Node3D).visible = false
			set_truce([g as Node], true, Unit.TRUCE_ALL)
	for group: String in ["units", "buildings"]:
		for n in get_tree().get_nodes_in_group(group):
			if n.get(&"team") == null or int(n.get(&"team")) != Unit.Team.ENEMY:
				continue
			_guards.erase(n)
			set_truce([n as Node], true, Unit.TRUCE_ALL)
			var u := n as Unit
			if u == null or not u.is_alive() or u.is_worker():
				continue
			if u is Wizard:
				u.command_move(u.get_meta(META_HOME, VESSA_RALLY))
				continue
			var gate: Vector3 = AURIVANE_GATES[0] if u.global_position.z < 0.0 else AURIVANE_GATES[1]
			u.command_move(gate)
			leave_later(u, 40.0)
	# Dacian and Seraphine on the sand with the white cloth
	for u: Unit in [dacian, seraphine]:
		if u and is_instance_valid(u):
			set_dormant(u, false)
			u.command_move(CHAIR + Vector3(2.0, 0.0, -2.0))
	_push_out_ring()
	set_meta(&"truce_end", mission_time() + TRUCE_LEN)
	set_objective(&"obj_truce", "active")
	after(TRUCE_LEN, _turn)


func _push_out_ring() -> void:
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or not u.is_alive() or u == dacian or u == seraphine or dragons_has_unit(u) or not u.can_move():
			continue
		if Teams.side_of(int(u.team)) == 0 and _flat(u.global_position, ROCK) < 8.0:
			var out := u.global_position - ROCK
			out.y = 0.0
			if out.length() < 0.1:
				out = Vector3(-1.0, 0.0, 1.0)
			u.displace(ROCK + out.normalized() * 10.0, 0.6)


func _turn() -> void:
	if is_ending() or not fire_once(&"E9"):
		return
	set_objective(&"obj_truce", "done")
	play_cutscene(&"e7m4_turn", _turn_end)


func _turn_end() -> void:
	phase = 4
	turn_time = mission_time()
	for id in ["L20", "L21", "L22", "L23", "L24"]:
		say_l(id)
	say_l("L25" if flag_on("e7m1_ossavar_won") else "L25a")
	if people:
		say_l("L25b")
	say_l("L26")
	switch_seat_side(&"malrik", Teams.ENEMY_2, GRACE)
	if _malrik_cmd and is_instance_valid(_malrik_cmd):
		_malrik_cmd.set(&"enabled", false)
	for n in seat_nodes(&"malrik"):
		var u := n as Unit
		if u and u.is_alive() and not u.is_worker():
			var home := MALRIK_HOME + Vector3(randf_range(-4.0, 4.0), 0.0, randf_range(-4.0, 4.0))
			u.command_move(home)
			u.set_meta(META_HOME, home)
			if u != hush and not dragons_has_unit(u):
				_guards.append(u)
	if hud:
		hud.show_message(MSG_GRACE, GRACE)
	# Ossavar with Torvald, the dragons with Malrik
	bind_dragon("ossavar_story", 0, 0.0)
	for id: String in ["gilt_dragon", "prism_dragon", "sunwake"]:
		var u := dragon(id)
		if u:
			set_dormant(u, true)
	# Dacian and Seraphine hold the sand for side 0
	for u: Unit in [dacian, seraphine]:
		if u and is_instance_valid(u):
			u.team = Unit.Team.PLAYER
			set_truce([u], false, Unit.TRUCE_ALL)
			set_dormant(u, false)
			u.set_meta(META_HOME, ROCK + Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(-3.0, 3.0)))
			_guards.append(u)
			guard_life(u, _on_rock_holder_down)
	# the silver galleys
	var ids: Array = [&"SG-W", &"SG-E"] if people else [&"SG-W", &"SG-E", &"SG-M"]
	for id: StringName in ids:
		var g := build_grid.spawn_complete(_galley_type_silver, SILVER[id], Teams.ENEMY_2) if _galley_type_silver else null
		if g:
			silver[id] = g
			set_truce([g], true, Unit.TRUCE_ALL)
			g.destroyed.connect(_on_silver_sunk)
	after(SILVER_FIRE, _silver_open_fire)
	set_objective(&"obj_hold", "active")
	set_objective(&"sec_dragons", "active")
	set_objective(&"sec_silver", "active")
	_build_pay_panel()


## The silver galleys open fire SILVER_FIRE s after the turn (a named timer: saving stays allowed).
func _silver_open_fire() -> void:
	for g: Variant in silver.values():
		if is_instance_valid(g) and (g as Building).is_alive() and not (g as Node).has_meta(&"frozen"):
			set_truce([g as Node], false, Unit.TRUCE_ALL)


func _build_pay_panel() -> void:
	if hud == null or (_pay_panel != null and is_instance_valid(_pay_panel)):
		return
	var rows: Array = []
	for id: String in ["gilt_dragon", "prism_dragon", "sunwake"]:
		var did := id
		rows.append([Loc.t("Pay {name} home ({price})", {"name": PAY_NAMES[id], "price": pay_price(id)}),
				func() -> void:
					var r := pay_home(did)
					if r != "" and hud:
						hud.show_message(Loc.sink(r), 2.5)])
	_pay_panel = mission_button_panel("PayPanel", rows)


func pay_price(id: String) -> int:
	return int(by_difficulty(PAY[id]))


## Pays dragon `id` home: "" or the refusal ("No Bazaar", "Not enough gold", "No auction" = not Malrik's any more).
func pay_home(id: String) -> String:
	if turn_time < 0.0 or paid.has(id) or dragon(id) == null:
		return MSG_NO_AUCTION
	if Market.of_team(Unit.Team.PLAYER) == null:
		return MSG_NO_BAZAAR
	var gb := GoldBank.for_team(Unit.Team.PLAYER)
	if gb == null or not gb.spend(pay_price(id)):
		return MSG_NO_GOLD
	paid.append(id)
	_wave_units.erase(dragon(id))
	release_dragon(id, true)
	fire_once(&"E12")
	say_l("L29")
	set_mission_flag("e7m4_dragons_paid", paid.size())
	if paid.size() >= 3:
		set_objective(&"sec_dragons", "done")
		set_mission_flag("e7m4_all_paid", true)
	return ""


func _on_silver_sunk(_b: Building) -> void:
	silver_sunk += 1
	if is_ending():
		return
	if fire_once(&"E14"):
		say_l("L32" if people else "L32b")
	if silver_sunk >= silver_goal():
		set_objective(&"sec_silver", "done")
		set_mission_flag("e7m4_silver_sunk", true)


# ---------------------------------------------------------------- P4: Malrik's assaults

func _tick_p4(dt: float) -> void:
	if turn_time < 0.0:
		return
	var t := mission_time()
	if t >= turn_time + 30.0 and fire_once(&"E10"):
		say_l("L28")
		if hud:
			hud.show_message(HINT_PAY, 10.0)
	for row: Array in ASSAULTS:
		if t >= turn_time + float(row[0]) and t < still_at() + 1.0 and fire_once(StringName(row[1])):
			_assault(row[1], String(row[2]), String(row[3]), 1.0)
	# the rock: Malrik's side 30 s in a row = defeat
	if rock_owner() == 1 and t >= turn_time + GRACE:
		rock_lost_for += dt
		if rock_lost_for >= float(by_difficulty(ROCK_LOST)) and fire_once(&"E23"):
			say_l("L42")
			set_objective(&"obj_hold", "failed")
			lose(DEFEAT_DELAY)
	else:
		rock_lost_for = 0.0
	if _surge_until > 0.0 and t >= _surge_until:
		_surge_until = 0.0
		for n in get_tree().get_nodes_in_group(&"units"):
			if n is Unit:
				(n as Unit).remove_modifier(&"mission:hollow_surge")


func _assault(wave_id: StringName, kind: String, dragon_id: String, mult: float) -> void:
	waves_fired.append(String(wave_id))
	var rows: Array = WAVES[wave_id]
	if mult > 1.0:
		var more: Array = []
		for r: Array in rows:
			more.append([r[0], int(ceil(float(r[1]) * mult))])
		rows = more
	var hall := MALRIK_HALL + Vector3(4.0, 0.0, 4.0)
	var out: Array
	match kind:
		"rock":
			out = route_wave(rows, hall, [NORTH_FOOT, NORTH_CAUSEWAY], ROCK, Teams.ENEMY_2)
		"base":
			out = route_wave(rows, hall, [SHORE_WEST], RIME_KEEP, Teams.ENEMY_2)
		_:
			out = route_wave(rows, hall, [SHORE_WEST], BAZAAR_SPOT, Teams.ENEMY_2)
	if wave_id == &"M1":
		fire_once(&"E11")
		say_l("L27")
	if wave_id == &"M3":
		fire_once(&"E13")
		say_l("L30")
		say_l("L31")
	if wave_id in [&"M3", &"M5", &"S3"]:
		for w: Variant in [malrik, hush]:
			if is_instance_valid(w) and (w as Unit).is_alive() and int((w as Unit).team) == Teams.ENEMY_2 \
					and not (w == hush and bool(hush.get_meta(&"fled", false))):
				_guards.erase(w)
				send_route(w as Unit, [NORTH_FOOT, NORTH_CAUSEWAY], ROCK)
	var ids: Array = ["gilt_dragon", "prism_dragon", "sunwake"] if dragon_id == "all" else ([dragon_id] if dragon_id != "" else [])
	for id: String in ids:
		if paid.has(id) or dragon(id) == null:
			continue
		bind_dragon(id, 1, 0.0)
		var u := dragon(id)
		if u:
			u.team = Teams.ENEMY_2 as Unit.Team
	if mult > 1.0:
		say_l("L33b")
	for v: Variant in out:
		if _surge_until > 0.0:
			(v as Unit).add_modifier(&"mission:hollow_surge", {"attack_damage_pct": 0.15})


func _dragon_enemy_goal() -> Node3D:
	return rock if rock != null else keep


func _tick_dragons_goal() -> void:
	# Malrik's dragons strike the rock's attackers; Ossavar hunts dragons first.
	var oss := dragon("ossavar_story")
	if oss == null or turn_time < 0.0:
		return
	var d: Dictionary = dragons.get("ossavar_story", {})
	if float(d.get("rest_until", 0.0)) > 0.0:
		return
	for id: String in ["gilt_dragon", "prism_dragon", "sunwake"]:
		var u := dragon(id)
		if u and u.is_alive() and int(u.team) == Teams.ENEMY_2 and not is_dormant(u) and _flat(u.global_position, oss.global_position) < 30.0:
			if oss.attack_target != u:
				oss.command_attack(u)
			return


# ---------------------------------------------------------------- the stone's hunger, Hush, Malrik

func _on_any_unit_died(u: Node) -> void:
	var unit := u as Unit
	if unit == null or is_ending() or turn_time < 0.0 or absf(unit.global_position.x) > 20.0:
		return
	meter = minf(100.0, meter + float(by_difficulty(METER_STEP)))
	meter_peak = maxf(meter_peak, meter)
	if meter >= 50.0 and fire_once(&"E15"):
		say_l("L33")
		_surge_until = mission_time() + 60.0
		if hud:
			hud.show_message(MSG_SURGE, 5.0)
		for n in get_tree().get_nodes_in_group(&"units"):
			var x := n as Unit
			if x and x.is_alive() and int(x.team) == Teams.ENEMY_2:
				x.add_modifier(&"mission:hollow_surge", {"attack_damage_pct": 0.15})
	if meter >= 100.0:
		meter = 50.0
		fire_once(&"E16")
		for row: Array in ASSAULTS:
			if not has_fired(StringName(row[1])) and mission_time() < still_at():
				fire_once(StringName(row[1]))
				_assault(row[1], String(row[2]), String(row[3]), 1.25)
				break


func _on_hush_down(_u: Unit) -> void:
	_hush_flees()


## Dacian / Seraphine on the rock: they kneel 10 s, then stand at half HP (named methods: the pause survives a save).
func _on_rock_holder_down(x: Unit) -> void:
	set_dormant(x, true)
	x.set_meta(&"e7_up_at", mission_time() + 10.0)
	after(10.0, _rock_holders_up)


func _rock_holders_up() -> void:
	for x: Unit in [dacian, seraphine]:
		if x and is_instance_valid(x) and x.is_alive() and is_dormant(x) 				and mission_time() >= float(x.get_meta(&"e7_up_at", 0.0)) - 0.05:
			x.hp = x.max_hp * 0.5
			set_dormant(x, false)


func _hush_flees() -> void:
	if hush == null or not is_instance_valid(hush) or bool(hush.get_meta(&"fled", false)):
		return
	if int(hush.team) != Teams.ENEMY_2:
		hush.hp = hush.max_hp * 0.5   # still Malrik's ally: she only steps back
		return
	hush.set_meta(&"fled", true)
	fire_once(&"E25")
	say_l("L43")
	_wave_units.erase(hush)
	set_truce([hush], true, Unit.TRUCE_ALL)
	set_dormant(hush, false)
	hush.command_move(MALRIK_KEEP)
	if not _hush_returned:
		after(90.0, func() -> void:
			if is_instance_valid(hush) and not is_ending():
				_hush_returned = true
				hush.hp = hush.max_hp
				hush.set_meta(&"fled", false)
				set_truce([hush], false, Unit.TRUCE_ALL)
				send_route(hush, [NORTH_FOOT, NORTH_CAUSEWAY], ROCK))
	else:
		after(8.0, func() -> void:
			if is_instance_valid(hush) and hush.is_alive():
				hush.leave_map())


func _tick_hush() -> void:
	if hush and is_instance_valid(hush) and hush.is_alive() and int(hush.team) == Teams.ENEMY_2 \
			and not bool(hush.get_meta(&"fled", false)) and hush.hp < hush.max_hp * 0.25:
		_hush_flees()


func _on_malrik_died(_u: Unit) -> void:
	if hud and not is_ending():
		hud.show_message(MSG_MALRIK_FELL, 4.0)
	after(60.0, _malrik_back)


func _malrik_back() -> void:
	if malrik and is_instance_valid(malrik) and not malrik.is_alive() and not is_ending():
		malrik.respawn(MALRIK_KEEP + Vector3(4.0, 0.0, 4.0))
		malrik.set_meta(META_HOME, MALRIK_RALLY)
		if not _guards.has(malrik):
			_guards.append(malrik)


# ---------------------------------------------------------------- P5: Still the Sea

func still_at() -> float:
	if turn_time < 0.0:
		return 1.0e9
	return maxf(STILL_AT, turn_time + STILL_AFTER_TURN)


func _tick_p5(dt: float) -> void:
	var t := mission_time()
	if t < still_at() or stage >= 3:
		return
	if fire_once(&"E17"):
		phase = 5
		say_l("L34")
		set_objective(&"obj_still", "active")
		flash_ring(ROCK, 3.0)
	if t < stage_ready_at:
		return
	var need := float(by_difficulty(STAGE_NEED))
	var before := stage_progress
	if hero_alive() and _flat(hero.global_position, ROCK) <= 3.0:
		stage_progress = minf(need, stage_progress + dt)   # damage does not reset it
	else:
		stage_progress = 0.0
	if before <= 0.0 and stage_progress > 0.0 and fire_once(StringName("stage_start_%d" % stage)):
		_stage_wave(stage)
	if stage_progress >= need:
		_stage_done()


func _stage_wave(i: int) -> void:
	match i:
		0:
			waves_fired.append("S1")
			route_wave(WAVES[&"S1"], MALRIK_HALL + Vector3(4.0, 0.0, 4.0), [NORTH_FOOT, NORTH_CAUSEWAY], ROCK, Teams.ENEMY_2)
		1:
			waves_fired.append("S2")
			route_wave(WAVES[&"S2"], MALRIK_HALL + Vector3(4.0, 0.0, 4.0), [SHORE_WEST], RIME_KEEP, Teams.ENEMY_2)
		2:
			fire_once(&"E20")
			say_l("L37")
			say_l("L38")
			_assault(&"S3", "rock", "all", 1.0)


func _stage_done() -> void:
	stage += 1
	stage_progress = 0.0
	stage_ready_at = mission_time() + STAGE_GAP
	var band_x: float = [-1.0, 1.0, 0.0][stage - 1]
	for g: Variant in silver.values() + crimson.values():
		if not is_instance_valid(g) or not (g as Building).is_alive():
			continue
		var p := (g as Node3D).global_position
		if (band_x < 0.0 and p.z < -14.0) or (band_x > 0.0 and p.z > 14.0) or (band_x == 0.0 and absf(p.z) <= 14.0):
			(g as Node).set_meta(&"frozen", true)
			set_truce([g as Node], true, Unit.TRUCE_ALL)
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == Teams.ENEMY_2 and absf(u.global_position.x) < 22.0:
			u.apply_status(&"chill", 6.0)
	flash_ring(ROCK, 6.0 + 4.0 * stage)
	objectives_changed.emit()
	match stage:
		1:
			fire_once(&"E18")
			say_l("L35")
		2:
			fire_once(&"E19")
			say_l("L36")
		3:
			_victory()
	if stage < 3 and hud:
		after(STAGE_GAP, func() -> void:
			if hud and not is_ending():
				hud.show_message(MSG_STAGE_READY, 4.0))


func _victory() -> void:
	if is_ending() or not fire_once(&"E21"):
		return
	victory_time = mission_time()
	set_objective(&"obj_still", "done")
	set_objective(&"obj_hold", "done")
	set_objective(&"obj_torvald", "done")
	for id: StringName in [&"sec_dragons", &"sec_silver"]:
		if objective_state(id) == "active":
			set_objective(id, "failed")
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and Teams.side_of(int(u.team)) == 1:
			u.apply_status(&"frozen", 3.0)
	clear_waves()
	set_mission_flag("e7m4_dragons_paid", paid.size())
	set_mission_flag("e7m4_galleys_sunk", red_sunk + silver_sunk)
	set_mission_flag("e7m4_meter_peak", int(meter_peak))
	set_mission_flag("e7m4_time", int(victory_time))
	var bonus := 0
	if objective_state("sec_dragons") == "done":
		bonus += 300
	if objective_state("sec_silver") == "done":
		bonus += 200
	if objective_state("sec_red") == "done":
		bonus += 150
	record_torvald_essence(bonus)
	if _pay_panel and is_instance_valid(_pay_panel):
		_pay_panel.queue_free()
	play_cutscene(&"e7m4_still", func() -> void:
		say_l("L39")
		say_l("L40")
		win(1.0))


func _on_player_hero_fell() -> void:
	fire_once(&"E22")
	say_l("L41")
	set_objective(&"obj_torvald", "failed")
	super()


# ---------------------------------------------------------------- save / load

func save_state(ids: Dictionary = {}) -> Dictionary:
	var d := super(ids)
	d["e7m4"] = {"phase": phase, "turn": turn_time, "red": red_sunk, "silver": silver_sunk, "paid": paid.duplicate(),
			"meter": meter, "peak": meter_peak, "stage": stage}
	return d


func load_state(d: Dictionary, nodes: Dictionary = {}) -> void:
	super(d, nodes)
	var m: Dictionary = d.get("e7m4", {})
	phase = int(m.get("phase", 1))
	turn_time = float(m.get("turn", -1.0))
	red_sunk = int(m.get("red", 0))
	silver_sunk = int(m.get("silver", 0))
	paid.assign(m.get("paid", []))
	meter = float(m.get("meter", 0.0))
	meter_peak = float(m.get("peak", 0.0))
	stage = int(m.get("stage", 0))
	# Review 2026-10-10 #3: guards and hooks on units the load rebuilt (a seat that changed sides spawns new ones).
	if malrik and is_instance_valid(malrik) and not malrik.died.is_connected(_on_malrik_died):
		malrik.died.connect(_on_malrik_died)
	if hush and is_instance_valid(hush):
		guard_life(hush, _on_hush_down)
	if turn_time >= 0.0:
		for u: Unit in [dacian, seraphine]:
			if u and is_instance_valid(u):
				guard_life(u, _on_rock_holder_down)
		for g: Variant in silver.values():
			if is_instance_valid(g) and g is Building and (g as Building).is_alive() 					and not (g as Building).destroyed.is_connected(_on_silver_sunk):
				(g as Building).destroyed.connect(_on_silver_sunk)


## After a load (phase convention: the effects of the reached phases again, quietly): from the Two Skies the crimson
## galleys are gone from sight (C6-12); from the turn the pay panel is back (C6-2) and Malrik's Commander stays paused
## (C6-9: the framework restores `enabled`, kept here as a guard).
func _after_load(nodes: Dictionary) -> void:
	super(nodes)
	if has_fired(&"E8") and phase >= 2:
		for id: StringName in crimson:
			var g: Variant = crimson[id]
			if is_instance_valid(g) and (g as Building).is_alive():
				(g as Node3D).visible = false
	if turn_time >= 0.0:
		if _malrik_cmd and is_instance_valid(_malrik_cmd):
			_malrik_cmd.set(&"enabled", false)
		if not is_ending() and not has_fired(&"E21"):
			_build_pay_panel()


func save_block_reason() -> String:
	if phase == 2 or phase == 3 or (has_fired(&"E9") and turn_time < 0.0):
		return "Not during the turn"
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
		if phase != 2:
			tick_rock(0.25)
		_tick_auction()
		_tick_p4(0.25)
		_tick_p5(0.25)
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.5
		if phase == 1:
			_tick_p1()
			_tick_enemy_wizards()
		_tick_dragons()
		_tick_dragons_goal()
		_tick_hush()
		objectives_changed.emit()
		if hud and mission_hud == null:
			hud.set_objective(_objective_text())
