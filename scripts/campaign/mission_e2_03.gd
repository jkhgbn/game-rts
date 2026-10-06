class_name MissionE2_03
extends MissionBase
## Episode 2, mission 3 "The Salt Road" (docs/design/mission-e2-03.md): the trade mission. Build a Bazaar, run caravans,
## then pay the Greywater Lodge six tributes of gold (a caravan walks Bazaar -> w_door -> nw1 -> nw2 -> the Lodge door)
## past the Magpies and Malrik's Tollgate, and hold until the Lodge's guides reach Vessa. 1v1 (PLAYER Fire vs ENEMY
## Malrik's bot, which trades too), the Crown Hollow layout with the river and the full trade stack.
##
## Built deviations (2026-10-06, recorded in the spec's "Built" note):
## - No Ember Boar (no wizard-mount system exists): Vessa is on foot; E9 = the Ember Stables complete (the spotlight:
##   the Emberdart Harrier, Stables V through `stables_card`); E12 = Vessa picks up a loot sack (no "mounted" rule).
## - "Send tribute" is a mission button (top right, `send_tribute()`), not the Bazaar card's X slot.
## - Trade timings by shifted clocks (no constant changes in the trade code): the TradeNetwork reads mission time +
##   150 s (posts 1:30, guild houses 2:30), the Hunters' guild + 180 s (contracts 2:00), the Thieves' guild + 120 s
##   (first band 3:00; bands of 3 from 10:00, 4 from 13:00; worker raids from 6:00). No tribute weighting in ThiefBand.
## - The map is Crown Hollow's own (tree seed 7, the crown's pillars stand as the Salt Tor ruin; no crown, no wardens).

const MISSION_ID := &"e2m3"
const MISSION_TITLE := "The Salt Road"

const EMBER_HALL_POS := Vector3(-27.0, 0.0, 45.0)
const EMBER_SPIRE_POS := Vector3(-37.0, 0.0, 29.0)
const HEARTH_SPOTS: Array[Vector3] = [Vector3(-50.0, 0.0, 46.0), Vector3(-50.0, 0.0, 52.0)]
const WEST_SPIRE_POS := Vector3(-46.0, 0.0, 12.0)
const ARMY_POS := Vector3(-32.0, 0.0, 32.0)
const GLOOM_HALL_POS := Vector3(27.0, 0.0, -45.0)
const NIGHT_SPIRE_POS := Vector3(37.0, 0.0, -29.0)
const HOVEL_SPOTS: Array[Vector3] = [Vector3(50.0, 0.0, -46.0), Vector3(50.0, 0.0, -52.0)]
const GLOOM_BAZAAR_POS := Vector3(45.0, 0.0, -27.0)
const SHADOW_RALLY := Vector3(30.0, 0.0, -30.0)
const SHADOW_CORNER := Vector3(56.0, 0.0, -56.0)
const LODGE_DOOR := Vector3(-45.0, 0.0, -51.0)
const TRIBUTE_ROUTE: Array[Vector3] = [Vector3(-49.0, 0.0, 1.0), Vector3(-48.0, 0.0, -44.0), Vector3(-44.0, 0.0, -48.0),
		Vector3(-45.0, 0.0, -51.0)]
const TOLLGATE_POS := Vector3(-43.0, 0.0, -25.0)
const TOLLGATE_HP := 720.0
const MILLSTONE_DOOR := Vector3(-1.0, 0.0, 49.0)
const G1_POS := Vector3(6.0, 0.0, -44.0)
const G3_POS := Vector3(44.0, 0.0, -6.0)
const PELL_POS := Vector3(-22.0, 0.0, -22.0)
const VEY_EXIT := Vector3(-58.0, 0.0, 58.0)

const TRADE_CLOCK_SHIFT := 150.0     ## TradeNetwork: posts 4:00 -> 1:30.
const HUNTERS_CLOCK_SHIFT := 180.0   ## Lodge contracts 5:00 -> 2:00.
const THIEVES_SHIFT: Array[float] = [60.0, 120.0, 120.0]   ## First band 5:00 -> 4:00 easy / 3:00.
const TRIBUTES := 6
const TRIBUTE_PAY_TIME := 2.0
const DOOR_REACH := 2.5
const BAZAAR_TAKE_RANGE := 12.0
const W1_AT := 210.0
const RAID_FIRST := 270.0
const RAID_EVERY := 150.0
const TOLLGATE_AT := 360.0
const W2_AT := 450.0
const W3_AT := 660.0
const REBUILD_AT := 720.0
const W4_LATE := 45.0
const PELL_NEAR := 12.0
const WIZARD_RESPAWN := 60.0
const DEFEAT_DELAY := 3.0
const VICTORY_DELAY := 4.0
const LEVEL_CAP := 8
const NO_SAVE_ESSENCE := 600
const MAGPIE_GOAL := 8
const RAID_GOAL := 300
const COUNT_MULT: Array[float] = [0.6, 1.0, 1.4]
const START_CRYSTALS: Array[int] = [550, 450, 350]
## Spec 200 / 250 / 300; pacing 2026-10-06 (19.C5-style scripted run): 4 near caravans earned ~190 gold / min (the
## spec's budget assumed ~135) and the runs ended at 13:10 then (x 1.4) 16:52 against 18-24 min, so x 1.52.
const TRIBUTE_GOLD: Array[int] = [300, 380, 460]
const GUIDES_SECONDS: Array[float] = [60.0, 90.0, 120.0]
const WIZARD_LEVEL: Array[int] = [4, 5, 6]
const WIZARD_LATE_LEVEL: Array[int] = [5, 6, 7]
const MALRIK_SPELLS := [&"shadow_lance", &"shadow_lance", &"soul_siphon", &"soul_siphon", &"umbral_shroud"]
const VEY_PRICE := {"crystals": [250, 300, 350], "essence": [100, 150, 200], "time": [45.0, 45.0, 60.0]}

const WAVES := {
	&"G1": [["shade", 3], ["nightbolt", 2]],
	&"G2": [["shade", 4], ["nightbolt", 2], ["grave_hound", 2]],
	&"G3": [["shade", 2], ["shadow_knight", 1]],
	&"W1": [["shade", 3], ["grave_hound", 2]],
	&"RAID": [["grave_hound", 2], ["shade", 1]],
	&"W2": [["shade", 4], ["nightbolt", 2]],
	&"W3": [["shade", 5], ["nightbolt", 3], ["shadow_knight", 1], ["gloom_deacon", 1]],
	&"REBUILD": [["shade", 3], ["nightbolt", 2]],
	&"W4": [["shade", 6], ["nightbolt", 3], ["shadow_knight", 2]],
	&"W4B": [["grave_hound", 4], ["nightbolt", 2]],
}

const SPEAKER_COLORS := {
	&"vessa": Color(1.0, 0.45, 0.1), &"vey": Color(0.95, 0.95, 0.55), &"pell": Color(0.85, 0.75, 0.5),
	&"bettany": Color(0.80, 0.65, 0.45), &"ashby": Color(0.95, 0.60, 0.35), &"malrik": Color(0.7, 0.3, 1.0),
	&"narrator": Color(0.9, 0.85, 0.7),
}
const SPEAKER_NAMES := {&"vessa": "Vessa", &"vey": "Old Vey", &"pell": "Pell", &"bettany": "Bettany",
		&"ashby": "Captain Ashby", &"malrik": "Malrik", &"narrator": "Narrator"}
## L1-L32 (index n - 1), then L4b = 33, L5b = 34, L8b = 35, L14b = 36.
const DIALOGUE := [
	[&"narrator", "The Salt Road runs from Emberfall to the sea. Everything on it has a price, even the road."],
	[&"vessa", "Six wagons of gold. I don't own one wagon of gold. I own a lot of rocks. Shiny ones."],
	[&"pell", "Rocks become gold at a post, my queen. Gold becomes everything else. Trust a professional."],
	[&"vey", "I'll ride to Emberfall and find the old stair. Pay the hunters, then call me."],
	[&"pell", "You again! The fire one. Last time you let me out of a cage. Today I let you into a market."],
	[&"pell", "A Bazaar! Look at it. Smell it. Now put wheels on something and send it somewhere far."],
	[&"bettany", "Heads up, Firelady. The Magpies are out. They like their caravans full and their guards absent."],
	[&"vessa", "Bettany? I thought your tavern burned down."],
	[&"pell", "Gold! Your first gold. I'm not crying. It's the salt."],
	[&"malrik", "Every road charges a toll, Vessa. This one charges you."],
	[&"vessa", "A tollbooth. You built a tollbooth. That is the most Malrik thing you've ever done."],
	[&"vessa", "Stables! Javelins on horseback. Sir Crackle will have to wait for a saddle."],
	[&"bettany", "One wagon. Five to go. The hunters count slow and they count twice."],
	[&"vessa", "What do they even want all this gold for?"],
	[&"pell", "They took the tribute! Get it back! That gold has my fingerprints on it!"],
	[&"vessa", "Got it! Finders keepers, Magpies."],
	[&"vessa", "Vey, the Citadel's lit. The stair can wait. I've got thieves."],
	[&"vey", "Thieves AND a toll? Girl, you do know how to throw a party."],
	[&"ashby", "Shades sitting on Millstone Cross, my queen. No caravan's getting through there."],
	[&"malrik", "If I can't have the deep road, nobody walks it. Burn the market."],
	[&"vessa", "Toll's paid. In fire. Keep the change."],
	[&"vessa", "You rebuilt it?! You rebuilt the tollbooth?"],
	[&"bettany", "Halfway. The old hunters are starting to like you. Don't let it go to your head."],
	[&"bettany", "Eight Magpies. The Lodge remembers who clears its road."],
	[&"pell", "Robbing Malrik's wagons! You're a natural. I've never been prouder."],
	[&"bettany", "Six. Paid in full. Here's your road down: a stair under Emberfall, the Sunrise Road."],
	[&"bettany", "Two of ours will guide you. Nobody else has walked it since the Master."],
	[&"malrik", "A map to the deep. How generous. I'll take it off your body."],
	[&"bettany", "Guides are with you. Go before the Bishop buys the next one."],
	[&"vessa", "Pell, keep the Bazaar running. Fire just learned what gold is for."],
	[&"vessa", "Should have... ridden faster..."],
	[&"ashby", "The Saltwatch is lost! Get the queen out!"],
	[&"ashby", "Built you a tower on the west road, my queen. Learned that at the Millwatch."],
	[&"pell", "You again! You left me in that cage, you know. I escaped. On my own. Thank you for asking."],
	[&"bettany", "It did. The Lodge pays better, and nobody here throws fire at the furniture."],
	[&"bettany", "Arrows, mostly. And never having to go down there again."],
]
const BRIEFING_PARAGRAPHS: Array[String] = [
	"The three relics point down, under Emberfall, along roads nobody living has walked. Nobody but the Greywater hunters, who mapped the deep for a hundred years and have never sold the map.",
	"They will sell it now, for gold: six wagons of it, delivered to their Lodge's door at the far end of the Salt Road. Their neighbours across the road are the Magpies, who steal for a living. Malrik's men have started charging tolls.",
	"Fire has never needed gold. Fire has crystals, and a short temper. Pell says that is a fine start for a merchant.",
]
const BRIEFING_LINE := "Build a Bazaar, send caravans to the trading posts, then send tribute to the Greywater Lodge."
const HINT_BUILD_BAZAAR := "Build an Ember Bazaar: select a Cinder Hand, press B then B. It must stand within 20 m of the keep."
const HINT_CARAVANS := "Train caravans (Z). They walk to a trading post and bring back gold. Far posts pay more, but the road is longer."
const HINT_MAGPIES := "Magpies rob loaded caravans. Escort them, hire Outriders at the Lodge (U), or chase the loot sack before it fades."
const HINT_TRIBUTE := "Send tribute from the \"Send tribute\" button (top right) once you have {gold} gold."
const HINT_STABLES := "The Ember Stables train the Emberdart Harrier (V): javelins on a gallop, strong against slow melee."
const HINT_HARRIER := "Emberdarts: throw and fall back. The Magpies chase you, not the wagon."
const HINT_CITADEL := "Your Stronghold can become a Citadel: select the Keep and press X (300 crystals, 90 s). It opens the Ashveil Saboteur (C) and lets you call Old Vey (V)."
const HINT_CALL := "Call Old Vey: select the Keep and press V. He fights on his own; his card sets where (Escort / Vanguard / Hold home)."
const MSG_PAID := "The Greywater Lodge takes the tribute ({n} / 6)"
const MSG_QUEUED := "Tribute: next caravan home"
const MSG_MALRIK_FELL := "Malrik has fallen back into the shadows"
const BUTTON_TRIBUTE := "Send tribute ({gold} gold)"
const REFUSE_NO_BAZAAR := "No Bazaar"
const REFUSE_GOLD := "Not enough gold"
const REFUSE_CARAVAN := "No caravan"
const REFUSE_ON_ROAD := "Tribute already on the road"

## Test / menu switch (before the tree): campaign flags to use instead of the save ({} = read the save).
var flag_override: Dictionary = {}
## Stables16 / StablesBuilding read it (scene knob): the e2m3 Stables card, the Emberdart Harrier on V.
var stables_card: Array[StringName] = [&"blaze_rider", &"pyrehoof_lancer", &"sunforge_cataphract", &"emberdart_harrier"]

## Read only.
var tributes_paid := 0
var tribute_caravan: Unit = null       ## The tribute on the road (null = none).
var tribute_pending := false           ## Ordered and paid, waiting for a caravan to come home.
var tribute_lost := 0
var magpies_killed := 0
var raid_gold := 0
var tollgate: Building = null
var tollgate_falls := 0
var guides_left := -1.0
var guides_done := false
var ember_hall: TrainingBuilding
var gloom_hall: Building
var gloom_bazaar: Building
var bettany: Unit
var vey_arrived := false
var no_save_fallback := false
var guard_groups := {}
var waves_fired: Array[StringName] = []
var wave_units := {}
var said: Array[int] = []

var _flags_read := false
var _said := {}
var _tick := 0.0
var _hall_type: BuildingType
var _malrik_home := true
var _wp := 0
var _pay_left := -1.0
var _tribute_amount := 0
var _enemy_caravan_deaths: Array = []   ## [pos, msec] of Malrik's dead caravans (their sacks count for sec_raid)
var _malrik_sacks := {}                 ## LootSack instance id -> true
var _panel: Control
var _button: Button
var _last_obj_text := ""


# ---------------------------------------------------------------- setup

func _init() -> void:
	super()
	dialogue_lines = DIALOGUE
	speaker_colors = SPEAKER_COLORS.duplicate()
	speaker_names = SPEAKER_NAMES.duplicate()
	briefing_paragraphs = BRIEFING_PARAGRAPHS.duplicate()
	tavern_enabled = false
	trade_enabled = true
	river_enabled = true
	points_enabled = false
	camps_enabled = false
	beasts_enabled = false
	define_objectives([[&"obj_bazaar", "primary"], [&"obj_tribute", "primary"], [&"obj_guides", "primary"],
			[&"obj_vessa", "primary"], [&"obj_keep", "primary"], [&"sec_magpies", "secondary"],
			[&"sec_raid", "secondary"], [&"sec_toll", "secondary"]])


func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	c.mission_id = MISSION_ID
	c.title = MISSION_TITLE
	c.count_mult = COUNT_MULT.duplicate()
	c.defeat_on_keep_lost = false   # E23 is the mission's own
	c.tiers_enabled = true
	c.max_tier = 3
	c.bots_upgrade = false
	c.start_tiers = {Unit.Team.PLAYER: 2, Unit.Team.ENEMY: 2}
	c.casters_enabled = true
	c.t3_enabled = true
	c.helpers_enabled = true
	c.cavalry_enabled = true
	c.helper_call_price = VEY_PRICE.duplicate(true)
	c.start_level = 4
	c.start_spell_points = 3
	c.level_cap = LEVEL_CAP
	c.start_crystals = START_CRYSTALS.duplicate()
	c.instant_loss_on_wizard_death = true
	c.defeat_delay = DEFEAT_DELAY
	c.victory_banner = "VICTORY\nThe road down is yours"
	c.defeat_banner = "DEFEAT"
	c.rewards = {"flags": {"e2m3_magpies_hunted": "sec_magpies", "e2m3_malrik_robbed": "sec_raid",
			"e2m3_toll_broken": "sec_toll"}, "bonus_essence": {"sec_magpies": 150, "sec_raid": 300, "sec_toll": 150},
			"set_flags": {"e2m3_lodge_paid": true}, "next": &"e2m4"}
	c.spotlight = {"id": &"emberdart_harrier", "trigger": &"unlock", "key_hint": "Ember Stables: V",
			"card": "Emberdart Harrier. Javelins on a gallop: throw, turn, throw. Nothing on foot catches it."}
	return c


func _ready() -> void:
	_hall_type = _make_hall_type()
	get_tree().node_added.connect(_on_e3_node_added)
	super()


func _exit_tree() -> void:
	if get_tree().node_added.is_connected(_on_e3_node_added):
		get_tree().node_added.disconnect(_on_e3_node_added)


func _lighting_preset() -> StringName:
	return &"warm"


func _title_line() -> String:
	return "Episode 2, Mission 3: %s" % MISSION_TITLE


func respawn_point(team: int) -> Vector3:
	if team == Unit.Team.ENEMY:
		var k := keep_of(team)
		return k.spawn_point() if k else SHADOW_CORNER
	return super(team)


# ---------------------------------------------------------------- the map

func _build_map() -> void:
	_read_flags()
	super()   # the Crown Hollow layout: river, ring road, 4 posts, 2 Dens, 2 Lodges, peddlers, keeps, nodes
	ember_hall = build_grid.spawn_complete(BuildingType.find("fire_barracks"), EMBER_HALL_POS, Unit.Team.PLAYER) as TrainingBuilding
	build_grid.spawn_complete(BuildingType.find("fire_tower"), EMBER_SPIRE_POS, Unit.Team.PLAYER)
	for p in HEARTH_SPOTS:
		build_grid.spawn_complete(BuildingType.find("fire_hearth"), p, Unit.Team.PLAYER)
	if _flag(&"e2m2_points_held"):
		build_grid.spawn_complete(BuildingType.find("fire_tower"), WEST_SPIRE_POS, Unit.Team.PLAYER)
	gloom_hall = build_grid.spawn_complete(BuildingType.find("shadow_barracks"), GLOOM_HALL_POS, Unit.Team.ENEMY)
	build_grid.spawn_complete(BuildingType.find("shadow_tower"), NIGHT_SPIRE_POS, Unit.Team.ENEMY)
	for p in HOVEL_SPOTS:
		build_grid.spawn_complete(BuildingType.find("shadow_hovel"), p, Unit.Team.ENEMY)
	gloom_bazaar = build_grid.spawn_complete(BuildingType.find("shadow_market"), GLOOM_BAZAAR_POS, Unit.Team.ENEMY)


func _read_flags() -> void:
	if _flags_read:
		return
	_flags_read = true
	if not flag_override.is_empty():
		return
	no_save_fallback = not CampaignState.open(campaign_save_path).is_completed(&"e2m2")


func _flag(name: StringName) -> bool:
	_read_flags()
	if not flag_override.is_empty():
		return bool(flag_override.get(String(name), flag_override.get(name, false)))
	if no_save_fallback:
		return false
	var v: Variant = CampaignState.open(campaign_save_path).flag_value(String(name), false)
	return v == true or (v is int and int(v) != 0)


## The e2m3 Ember Hall (cavalry card, `cavalry-mounts.md` 2.1): Z Flame Guard, X Ember Archer, C Ash Hurler,
## V Pyre Adept, B Cinder Arbalest (the Blaze Rider trains at the Stables).
func _make_hall_type() -> BuildingType:
	var base := BuildingType.find("fire_barracks")
	if base == null:
		return null
	var t := base.duplicate() as BuildingType
	var trains: Array[UnitType] = []
	for id in ["flame_guard", "ember_archer", "ash_hurler", "pyre_adept", "cinder_arbalest"]:
		var ut := UnitType.find(id)
		if ut:
			trains.append(ut)
	t.trains = trains
	return t


func _on_e3_node_added(node: Node) -> void:
	var b := node as TrainingBuilding
	if b != null and _hall_type != null and b.building_type != null and b.building_type != _hall_type \
			and b.building_type.id == &"fire_barracks" and int(b.team) == Unit.Team.PLAYER:
		b.building_type = _hall_type
	var sack := node as LootSack
	if sack != null:
		_tag_sack.call_deferred(sack)
	var cv := node as Caravan
	if cv != null:
		cv.died.connect(_on_caravan_died)


# ---------------------------------------------------------------- start state

func _on_navigation_ready() -> void:
	var diff := clampi(mission_difficulty, 0, 2)
	fog.reveal(Unit.Team.ENEMY, SHADOW_START, FogOfWar.START_REVEAL)
	_setup_champions()   # the companion's guild; taverns closed

	hero = _make_wizard(Unit.Team.PLAYER)
	_spawn(hero, Unit.Team.PLAYER, PLAYER_START)
	_claim_wizard(hero, Unit.Team.PLAYER)
	ItemDrops.ensure_inventory(hero)
	_apply_campaign_start()
	for i in 6:
		var cinder := _spawn(make_unit("cinder_hand"), Unit.Team.PLAYER, PLAYER_START + Vector3(-4.0 + i * 1.2, 0.0, 4.0 - i * 1.2))
		cinder.call(&"command_gather", node_of(Unit.Team.PLAYER, "a" if i < 3 else "b"))
	var rows := [["flame_guard", 6 + (2 if diff == 0 else 0)], ["ember_archer", 4], ["blaze_rider", 2], ["kilnwarden", 1]]
	var army: Array[String] = []
	for row in rows:
		for k in int(row[1]):
			army.append(String(row[0]))
	for i in army.size():
		_spawn(make_unit(army[i]), Unit.Team.PLAYER, ARMY_POS + Vector3(-4.5 + (i % 6) * 1.6, 0.0, -2.0 + (i / 6) * 1.7))

	# Malrik: his base trades (the bot), his army at the rally.
	shadow_hero = _make_wizard(Unit.Team.ENEMY)
	_spawn(shadow_hero, Unit.Team.ENEMY, SHADOW_RALLY)
	_claim_wizard(shadow_hero, Unit.Team.ENEMY)
	raise_wizard(shadow_hero, WIZARD_LEVEL[diff], MALRIK_SPELLS)
	ItemDrops.ensure_inventory(shadow_hero)
	mark_scripted(shadow_hero)
	shadow_hero.died.connect(_on_malrik_died)
	wizard_respawned.connect(_on_e3_wizard_respawned)
	for i in 6:
		var thrall := _spawn(make_unit("gloom_thrall"), Unit.Team.ENEMY, SHADOW_START + Vector3(4.0 - i * 1.2, 0.0, -4.0 + i * 1.2))
		thrall.call(&"command_gather", node_of(Unit.Team.ENEMY, "a" if i < 3 else "b"))
	for i in 9:
		var a := float(i) * TAU / 9.0
		_spawn(make_unit("shade" if i < 6 else "nightbolt"), Unit.Team.ENEMY, SHADOW_RALLY + Vector3(cos(a) * 2.5, 0.0, sin(a) * 2.5))
	if gloom_bazaar:
		for i in 2:
			_spawn(make_unit("caravan"), Unit.Team.ENEMY, GLOOM_BAZAAR_POS + Vector3(-3.0 - i * 1.5, 0.0, 3.0))

	# Story NPC: Bettany at the Lodge door (invulnerable, not selectable).
	var bt := UnitType.find("greywater_tracker")
	if bt:
		var t := bt.duplicate() as UnitType
		t.id = &"bettany"
		t.display_name = "Bettany Crook"
		t.commandable = false
		t.attack_damage = 0.0
		t.aggro_range = 0.0
		t.pop = 0
		bettany = _spawn(Worker.make_unit(t), Unit.Team.NEUTRAL, LODGE_DOOR + Vector3(1.5, 0.0, 1.0))
		set_dormant(bettany, true)

	guard_groups[&"G1"] = spawn_group(WAVES[&"G1"], G1_POS, 2.5, Unit.Team.ENEMY, true)
	guard_groups[&"G3"] = spawn_group(WAVES[&"G3"], G3_POS, 2.0, Unit.Team.ENEMY, true)
	_spawn_caches()
	_setup_trade()
	_shift_trade_clocks()
	var gb := GoldBank.for_team(Unit.Team.PLAYER) if ResourceLoader.exists(GOLD_BANK_PATH) else null
	if gb:
		gb.gold = 0
	var roster := HelperRoster.for_team(Unit.Team.PLAYER)
	if roster:
		roster.helper_ready.connect(_on_vey_ready)
	if keep:
		keep.destroyed.connect(_on_keep_destroyed)
	_add_trade_commander()
	if trade_network:
		trade_network.delivered.connect(_on_delivered)
		trade_network.posts_opened.connect(func() -> void:
			fire_once(&"E5"))
	var ev := get_node_or_null(^"/root/Events")
	if ev:
		ev.connect(&"unit_died", _on_any_unit_died)
	_add_events()
	begin_mission([&"obj_bazaar", &"obj_tribute", &"obj_vessa", &"obj_keep"])
	_build_panel()


func _apply_campaign_start() -> void:
	_read_flags()
	if no_save_fallback or not flag_override.is_empty():
		set_meta(&"campaign_flags", flag_override.duplicate())
		force_artifacts(hero, ["ember_crown", "masters_signet"])
		if no_save_fallback:
			var bank := EssenceBank.for_team(Unit.Team.PLAYER)
			if bank:
				bank.add(NO_SAVE_ESSENCE)
		return
	CampaignState.open(campaign_save_path).apply_to_start(self)


## D5: the trade services read shifted clocks (posts 1:30, Lodge contracts 2:00, Magpies 3:00).
func _shift_trade_clocks() -> void:
	var diff := clampi(mission_difficulty, 0, 2)
	if trade_network:
		trade_network.match_time_source = func() -> float: return mission_time() + TRADE_CLOCK_SHIFT
	var hg := _service(hunters_guild)
	if hg and &"match_time_source" in hg:
		hg.set(&"match_time_source", func() -> float: return mission_time() + HUNTERS_CLOCK_SHIFT)
	var tg := _service(thieves_guild)
	if tg and &"match_time_source" in tg:
		var shift := float(THIEVES_SHIFT[diff])
		tg.set(&"match_time_source", func() -> float: return mission_time() + shift)


## Malrik's bot: Shadow normal knobs, never attacks, 6 workers, no expansion, at most 10 soldiers, trade on (the
## Bazaar pre-built, 4 caravans on his near posts), no champions / map fill.
func _add_trade_commander() -> void:
	var path := "res://scripts/ai/commander.gd"
	if not ResourceLoader.exists(path):
		return
	var p := AIProfile.for_difficulty(clampi(mission_difficulty, 0, 2))
	p.id = &"mission_e2_03"
	p.profile_id = p.id
	p.min_attack_pop = 99
	p.launch_attacks = false
	p.attack_full_pop = 0
	p.first_attack_by = 0.0
	p.worker_target_home = 6
	p.worker_target_expanded = 6
	p.worker_target_x2 = 6
	p.second_expansion = false
	p.expand_time = 1.0e6
	p.max_soldiers = 10
	p.build_rows = PackedStringArray(["H1", "V1", "S1", "V2", "M1"])
	p.rebuild = false
	p.hero_stays_home = true
	p.malrik_joins = AIProfile.MalrikJoins.NEVER
	p.champion_max = 0
	p.trade = true
	p.trade_start = 0.0
	p.caravan_target = 4
	p.caravan_target_late = 4
	p.far_route_caravans = 0
	p.hire_outriders = false
	p.hire_sweep = false
	p.map_fill = false
	var bot: Node = (load(path) as Script).new()
	bot.name = "ShadowBot"
	bot.set(&"team", Unit.Team.ENEMY)
	bot.set(&"profile", p)
	add_child(bot)
	commanders.append(bot)


func _build_panel() -> void:
	_panel = mission_button_panel("TributePanel", [[Loc.t(BUTTON_TRIBUTE, {"gold": tribute_gold()}), func() -> void:
		var r := send_tribute()
		if r != "":
			hud.show_message(r, 3.0)]])
	_button = _panel.find_children("*", "Button", true, false)[0] as Button if _panel else null


# ---------------------------------------------------------------- briefing, objectives, lines

func briefing() -> Dictionary:
	return {
		"title": _title_line(),
		"paragraphs": BRIEFING_PARAGRAPHS.duplicate(),
		"objectives": [objective_text(&"obj_tribute", false), BRIEFING_LINE],
		"rule": "%s · %s" % [Loc.sink(objective_text(&"obj_vessa")), Loc.sink(objective_text(&"obj_keep"))],
	}


func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_bazaar":
			return "Build an Ember Bazaar and send caravans to a trading post"
		&"obj_tribute":
			if with_counter:
				if tribute_caravan != null and is_instance_valid(tribute_caravan) and tribute_caravan.is_alive():
					var head := "Pay the Greywater Lodge: deliver tribute (%d / 6)" % tributes_paid
					var road := "Tribute on the road: %d m to the Lodge" % int(_flat(tribute_caravan.global_position, LODGE_DOOR))
					return "%s\n%s" % [head, road]   # two lines, each translated on its own (Loc.sink)
				return "Pay the Greywater Lodge: deliver tribute (%d / 6)" % tributes_paid
			return "Pay the Greywater Lodge: deliver tribute"
		&"obj_guides":
			if with_counter and guides_left >= 0.0:
				var s := int(ceil(guides_left))
				return "Hold until the Lodge's guides reach you (%d:%02d)" % [s / 60, s % 60]
			return "Hold until the Lodge's guides reach you"
		&"obj_vessa":
			return "Vessa must survive"
		&"obj_keep":
			return "The Saltwatch must stand"
		&"sec_magpies":
			if with_counter:
				return "Hunt the Magpies for the Lodge (%d / 8)" % mini(magpies_killed, MAGPIE_GOAL)
			return "Hunt the Magpies for the Lodge"
		&"sec_raid":
			if with_counter:
				return "Take 300 gold from Malrik's caravans (%d / 300)" % mini(raid_gold, RAID_GOAL)
			return "Take 300 gold from Malrik's caravans"
		&"sec_toll":
			if with_counter and tollgate_falls == 1 and has_fired(&"rebuild"):
				return "Break Malrik's Tollgate (1 / 2)"
			return "Break Malrik's Tollgate"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_tribute":
			return {"progress": tributes_paid, "goal": TRIBUTES, "counter": "%d / 6" % tributes_paid, "position": LODGE_DOOR}
		&"obj_guides":
			return {"countdown": guides_left, "time_left": guides_left}
		&"sec_magpies":
			return {"progress": mini(magpies_killed, MAGPIE_GOAL), "goal": MAGPIE_GOAL}
		&"sec_raid":
			return {"progress": mini(raid_gold, RAID_GOAL), "goal": RAID_GOAL}
		&"sec_toll":
			return {"position": TOLLGATE_POS}
	return {}


func say_l(n: int) -> void:
	if _said.has(n):
		return
	_said[n] = true
	said.append(n)
	say_line(n)


func tribute_gold() -> int:
	return int(by_difficulty(TRIBUTE_GOLD))


# ---------------------------------------------------------------- events

func _intro() -> void:
	fire_once(&"E1")
	play_cutscene(&"e2m3_road", func() -> void:
		if camera_rig and hero_alive():
			camera_rig.focus_on(hero.global_position)
		say_l(1)
		say_l(2)
		say_l(3)
		hud.show_message(HINT_BUILD_BAZAAR, 10.0))


func _add_events() -> void:
	after(25.0, func() -> void:
		if is_ending():
			return
		fire_once(&"E2")
		say_l(4)
		if _flag(&"e2m2_points_held"):
			say_l(33))
	after(W1_AT, _fire_w1)
	after(RAID_FIRST, _raid)
	after(TOLLGATE_AT, _raise_tollgate)
	after(W2_AT, _fire_w2)
	after(W3_AT, _fire_w3)
	after(REBUILD_AT, _rebuild_tollgate)
	add_event(&"E3", func() -> bool: return hero_alive() and _flat(hero.global_position, PELL_POS) <= PELL_NEAR,
			func() -> void: say_l(5 if _flag(&"m1_peddler_freed") or no_save_fallback else 34))
	add_event(&"E4", func() -> bool: return Market.of_team(Unit.Team.PLAYER) != null, func() -> void:
		say_l(6)
		hud.show_message(HINT_CARAVANS, 10.0))
	add_event(&"E6", func() -> bool: return not get_tree().get_nodes_in_group(&"magpies").is_empty(), func() -> void:
		say_l(7)
		say_l(8)
		say_l(35)
		set_objective(&"sec_magpies", "active")
		hud.show_message(HINT_MAGPIES, 10.0)
		after(12.0, func() -> void:
			if not is_ending() and has_fired(&"spotlight"):
				hud.show_message(HINT_HARRIER, 8.0)))
	add_event(&"E9", func() -> bool:
		for b in Building.for_team(Unit.Team.PLAYER):
			if b.is_alive() and b.is_constructed() and b.building_type and b.building_type.kind == &"stables":
				return true
		return false, func() -> void:
			say_l(12)
			hud.show_message(HINT_STABLES, 10.0)
			show_spotlight())
	add_event(&"citadel_hint", func() -> bool:
		return keep != null and is_instance_valid(keep) and keep.is_alive() and keep.can_upgrade() == "" \
				and int(keep.tier) == 2, func() -> void: hud.show_message(HINT_CITADEL, 12.0))
	add_event(&"E13", func() -> bool: return keep != null and is_instance_valid(keep) and int(keep.tier) >= 3, func() -> void:
		say_l(17)
		hud.show_message(HINT_CALL, 10.0))
	add_event(&"E14", _w2_holds, func() -> void: say_l(19))


func _on_vey_ready(_helper: Helper) -> void:
	if is_ending() or vey_arrived:
		return
	vey_arrived = true
	say_l(18)


## E7: the first caravan delivery of the player (any post).
func _on_delivered(team: int, _caravan: Node, _amount: int, _post: Node) -> void:
	if team != Unit.Team.PLAYER or is_ending():
		return
	if fire_once(&"E7"):
		set_objective(&"obj_bazaar", "done")
		say_l(9)
		set_objective(&"sec_raid", "active")
		hud.show_message(Loc.t(HINT_TRIBUTE, {"gold": tribute_gold()}), 8.0)


# ---------------------------------------------------------------- tribute

## Sends the next tribute (the button; tests): "" or the refusal ("No Bazaar", "Not enough gold", "No caravan",
## "Tribute already on the road"). Takes the first idle caravan at the Bazaar, else the next one to come home.
func send_tribute() -> String:
	var market := Market.of_team(Unit.Team.PLAYER)
	if market == null:
		return REFUSE_NO_BAZAAR
	var gb := GoldBank.for_team(Unit.Team.PLAYER)
	if gb == null or gb.gold < tribute_gold():
		return REFUSE_GOLD
	var cvs: Array = market.caravans()
	if cvs.is_empty():
		return REFUSE_CARAVAN
	if tribute_pending or (tribute_caravan != null and is_instance_valid(tribute_caravan) and tribute_caravan.is_alive()):
		return REFUSE_ON_ROAD
	if not gb.spend(tribute_gold()):
		return REFUSE_GOLD
	_tribute_amount = tribute_gold()
	var c := _caravan_at_bazaar(market)
	if c == null:
		tribute_pending = true
		hud.show_message(MSG_QUEUED, 3.0)
		return ""
	_load_tribute(c)
	return ""


func _caravan_at_bazaar(market: Node3D) -> Unit:
	for c: Variant in market.call(&"caravans"):
		var cu := c as Unit
		if cu and cu.is_alive() and int(cu.get(&"cargo")) == 0 and _flat(cu.global_position, market.global_position) <= BAZAAR_TAKE_RANGE:
			return cu
	return null


func _load_tribute(c: Unit) -> void:
	tribute_pending = false
	tribute_caravan = c
	c.set_meta(&"e2m3_tribute", true)
	c.command_move(TRIBUTE_ROUTE[0])
	c.set(&"cargo", _tribute_amount)
	_wp = 0
	_pay_left = -1.0


func _tick_tribute(delta: float) -> void:
	if tribute_pending:
		var m := Market.of_team(Unit.Team.PLAYER)
		if m:
			var c := _caravan_at_bazaar(m)
			if c:
				_load_tribute(c)
		return
	var c := tribute_caravan
	if c == null or not is_instance_valid(c) or not c.is_alive():
		return
	c.set_meta(&"e2m3_cargo", int(c.get(&"cargo")))
	if _pay_left >= 0.0:
		_pay_left -= delta
		if _pay_left <= 0.0:
			_pay_tribute()
		return
	var goal := TRIBUTE_ROUTE[_wp]
	if _flat(c.global_position, goal) <= DOOR_REACH:
		if _wp >= TRIBUTE_ROUTE.size() - 1:
			c.command_stop()
			_pay_left = TRIBUTE_PAY_TIME
			return
		_wp += 1
		c.command_move(TRIBUTE_ROUTE[_wp])
	elif not c.has_move_order():
		c.command_move(goal)


func _pay_tribute() -> void:
	var c := tribute_caravan
	tribute_caravan = null
	_pay_left = -1.0
	if c == null or not is_instance_valid(c):
		return
	c.set(&"cargo", 0)
	c.remove_meta(&"e2m3_tribute")
	var m := Market.of_team(Unit.Team.PLAYER)
	if m:
		c.call(&"command_trade", m)
	tributes_paid += 1
	hud.show_message(Loc.t(MSG_PAID, {"n": tributes_paid}), 4.0)
	set_objective(&"obj_tribute", "active")
	if tributes_paid == 1 and fire_once(&"E10"):
		play_cutscene(&"e2m3_lodge", func() -> void:
			say_l(13)
			say_l(14)
			say_l(36))
	if tributes_paid == 3 and fire_once(&"E17"):
		say_l(23)
	if tributes_paid >= TRIBUTES and fire_once(&"E20"):
		_e20_paid()


func _on_caravan_died(c: Unit) -> void:
	if int(c.team) == Unit.Team.ENEMY:
		_enemy_caravan_deaths.append([c.global_position, Time.get_ticks_msec()])
		return
	if not c.has_meta(&"e2m3_tribute") or is_ending():
		return
	# D8: a tribute drops all its gold (the caravan dropped half already).
	var amount := int(c.get_meta(&"e2m3_cargo", 0))
	var rest := amount - int(floor(amount * Caravan.LOOT_RATIO))
	if rest > 0:
		LootSack.spawn(self, c.global_position, rest)
	tribute_caravan = null
	tribute_lost += 1
	if fire_once(&"E11"):
		say_l(15)


func _tag_sack(sack: LootSack) -> void:
	if not is_instance_valid(sack):
		return
	var now := Time.get_ticks_msec()
	for d: Array in _enemy_caravan_deaths:
		if now - int(d[1]) < 2000 and _flat(sack.global_position, d[0]) < 3.0:
			_malrik_sacks[sack.get_instance_id()] = true
	sack.picked.connect(_on_sack_picked)


func _on_sack_picked(sack: LootSack, team: int, amount: int) -> void:
	if team != Unit.Team.PLAYER or is_ending():
		return
	if hero_alive() and _flat(hero.global_position, sack.global_position) <= 4.0 and fire_once(&"E12"):
		say_l(16)
	if _malrik_sacks.has(sack.get_instance_id()) and objective_state("sec_raid") == "active":
		raid_gold += amount
		set_objective(&"sec_raid", "active")
		if raid_gold >= RAID_GOAL and fire_once(&"E19"):
			say_l(25)
			set_objective(&"sec_raid", "done")


func _on_any_unit_died(u: Node) -> void:
	var unit := u as Unit
	if unit == null or is_ending() or not unit.is_in_group(&"magpies"):
		return
	var k: Variant = unit.killer
	if k == null or not is_instance_valid(k) or (k as Node).get(&"team") == null or int((k as Node).get(&"team")) != Unit.Team.PLAYER:
		return
	magpies_killed += 1
	if objective_state("sec_magpies") == "active":
		set_objective(&"sec_magpies", "active")
		if magpies_killed >= MAGPIE_GOAL and fire_once(&"E18"):
			say_l(24)
			set_objective(&"sec_magpies", "done")


# ---------------------------------------------------------------- waves, the Tollgate

func _side_spawn() -> Vector3:
	if gloom_hall and is_instance_valid(gloom_hall) and gloom_hall.is_alive() and gloom_hall is TrainingBuilding:
		return (gloom_hall as TrainingBuilding).spawn_point()
	var k := keep_of(Unit.Team.ENEMY)
	return k.spawn_point() if k else SHADOW_CORNER


func _rows(id: StringName) -> Array:
	var out: Array = []
	var diff := clampi(mission_difficulty, 0, 2)
	for row: Array in WAVES[id]:
		var tid := StringName(row[0])
		if diff == 0 and ((tid == &"shadow_knight" and id == &"W3") or tid == &"gloom_deacon"):
			continue
		if id == &"RAID" and tid == &"shade" and objective_state("sec_toll") == "done":
			continue
		out.append(row)
	return out


func _bazaar_target() -> Vector3:
	var m := Market.of_team(Unit.Team.PLAYER)
	if m:
		return m.global_position
	return _alive_pos(ember_hall, _alive_pos(keep, PLAYER_START))


func _fire_w1() -> void:
	if is_ending() or guides_done:
		return
	waves_fired.append(&"W1")
	var units := spawn_wave_at(_rows(&"W1"), _side_spawn())
	wave_units[&"W1"] = units
	for u in units:
		order_wave(u as Unit, &"bazaar", _bazaar_target())


func _raid() -> void:
	if is_ending() or guides_done:
		return
	after(RAID_EVERY, _raid)
	var units := spawn_wave_at(_rows(&"RAID"), _side_spawn())
	for u in units:
		order_wave(u as Unit, &"raid", _raid_target((u as Unit).global_position))


func _raid_target(from: Vector3) -> Vector3:
	var best := Vector3.INF
	var best_score := INF
	for c in get_tree().get_nodes_in_group(&"caravans"):
		var cu := c as Unit
		if cu == null or not cu.is_alive() or int(cu.team) != Unit.Team.PLAYER:
			continue
		var d := _flat(cu.global_position, from) - (60.0 if int(cu.get(&"cargo")) > 0 else 0.0)
		if d < best_score:
			best_score = d
			best = cu.global_position
	if best != Vector3.INF:
		return best
	for w in workers_of(Unit.Team.PLAYER):
		var d := _flat(w.global_position, from)
		if d < best_score:
			best_score = d
			best = w.global_position
	return best if best != Vector3.INF else _alive_pos(keep, PLAYER_START)


## E8 (6:00): the Tollgate rises (a Night Spire built in place) with its guard G2; L10-L11; sec_toll.
func _raise_tollgate() -> void:
	if is_ending() or guides_done:
		return
	fire_once(&"E8")
	_build_tollgate(&"G2")
	say_l(10)
	say_l(11)
	set_objective(&"sec_toll", "active")


func _build_tollgate(group: StringName) -> void:
	tollgate = build_grid.spawn_complete(BuildingType.find("shadow_tower"), TOLLGATE_POS, Unit.Team.ENEMY)
	if tollgate:
		tollgate.max_hp = TOLLGATE_HP
		tollgate.hp = TOLLGATE_HP
		mark_scripted(tollgate)
		tollgate.destroyed.connect(_on_tollgate_destroyed)
		flash_ring(TOLLGATE_POS, 4.0)
		nav_region.bake_navigation_mesh(true)
	guard_groups[group] = spawn_group(_rows(&"G2" if group == &"G2" else &"REBUILD"), TOLLGATE_POS, 4.0, Unit.Team.ENEMY, true, true)


func _on_tollgate_destroyed(_b: Building) -> void:
	if is_ending():
		return
	tollgate_falls += 1
	if tollgate_falls == 1:
		_v_toll_time = mission_time()
		say_l(21)
		if objective_state("sec_toll") == "active" and not _will_rebuild():
			set_objective(&"sec_toll", "done")
	else:
		say_l(22)
		if objective_state("sec_toll") == "active":
			set_objective(&"sec_toll", "done")


var _v_toll_time := -1.0


func _will_rebuild() -> bool:
	return _v_toll_time >= 0.0 and _v_toll_time < W3_AT and mission_time() < REBUILD_AT


## 12:00, only if the Tollgate fell before 11:00: it rises again (the counter shows 1 / 2).
func _rebuild_tollgate() -> void:
	if is_ending() or guides_done or tollgate_falls != 1 or _v_toll_time >= W3_AT:
		if tollgate_falls == 1 and objective_state("sec_toll") == "active":
			set_objective(&"sec_toll", "done")
		return
	fire_once(&"rebuild")
	_build_tollgate(&"G2b")
	set_objective(&"sec_toll", "active")


func _fire_w2() -> void:
	if is_ending() or guides_done:
		return
	waves_fired.append(&"W2")
	var units := spawn_wave_at(_rows(&"W2"), _side_spawn())
	wave_units[&"W2"] = units
	for u in units:
		order_wave(u as Unit, &"hold_post", MILLSTONE_DOOR)


func _w2_holds() -> bool:
	for u: Variant in wave_units.get(&"W2", []):
		if is_instance_valid(u) and (u as Unit).is_alive() and _flat((u as Unit).global_position, MILLSTONE_DOOR) <= 12.0:
			return true
	return false


func _fire_w3() -> void:
	if is_ending() or guides_done:
		return
	waves_fired.append(&"W3")
	var units := spawn_wave_at(_rows(&"W3"), _side_spawn())
	_malrik_home = false
	if shadow_hero and shadow_hero.is_alive():
		units.append(shadow_hero)
	wave_units[&"W3"] = units
	for u in units:
		order_wave(u as Unit, &"bazaar", _bazaar_target())
	say_l(20)


func _refresh_wave_unit(u: Unit, mode: StringName, _hero_at: Vector3) -> bool:
	match mode:
		&"bazaar":
			var m := Market.of_team(Unit.Team.PLAYER)
			var target: Node3D = m
			if target == null:
				for b in Building.for_team(Unit.Team.PLAYER):
					if b.is_alive() and b.building_type and b.building_type.kind == &"stables":
						target = b
			if target == null:
				u.set_meta(META_MODE, &"hero")
				return false
			if u.attack_target == null and not u.is_attack_moving():
				if _flat(u.global_position, target.global_position) <= 9.0:
					u.command_attack(target)
				else:
					u.command_attack_move(target.global_position)
			return true
		&"raid":
			if u.attack_target == null and not u.is_attack_moving():
				u.command_attack_move(_raid_target(u.global_position))
			return true
		&"hold_post":
			if u.attack_target == null and _flat(u.global_position, MILLSTONE_DOOR) > 4.0 and not u.is_attack_moving():
				u.command_attack_move(MILLSTONE_DOOR)
			return true
		&"withdraw":
			return true
	return false


# ---------------------------------------------------------------- the guides, the end

## E20: the 6th tribute: e2m3_paid (L26-L28), obj_tribute done, obj_guides (1:30), W4 Reprisal.
func _e20_paid() -> void:
	set_objective(&"obj_tribute", "done")
	play_cutscene(&"e2m3_paid", func() -> void:
		say_l(26)
		say_l(27)
		say_l(28))
	guides_left = float(by_difficulty(GUIDES_SECONDS))
	set_objective(&"obj_guides", "active")
	var diff := clampi(mission_difficulty, 0, 2)
	raise_wizard(shadow_hero, WIZARD_LATE_LEVEL[diff], [&"shadow_lance"])
	_malrik_home = false
	var units := spawn_wave_at(_rows(&"W4"), _side_spawn())
	if shadow_hero.is_alive():
		units.append(shadow_hero)
	wave_units[&"W4"] = units
	for u in units:
		order_wave(u as Unit, &"bazaar", _bazaar_target())
	if objective_state("sec_raid") != "done":
		after(W4_LATE, func() -> void:
			if is_ending() or guides_done:
				return
			var more := spawn_wave_at(_rows(&"W4B"), _side_spawn())
			wave_units[&"W4B"] = more
			for u in more:
				order_wave(u as Unit, &"bazaar", _bazaar_target()))


func _tick_guides(delta: float) -> void:
	if guides_left < 0.0 or guides_done:
		return
	guides_left = maxf(0.0, guides_left - delta)
	if guides_left <= 0.0:
		var market_or_keep := Market.of_team(Unit.Team.PLAYER) != null or (keep != null and is_instance_valid(keep) and keep.is_alive())
		if market_or_keep and hero_alive():
			_e21_done()


## E21: 6 Greywater Trackers walk out to Vessa; withdraw; L29-L30; victory 4 s later.
func _e21_done() -> void:
	if guides_done or is_ending():
		return
	guides_done = true
	guides_left = 0.0
	fire_once(&"E21")
	set_objective(&"obj_guides", "done")
	for id: StringName in [&"sec_magpies", &"sec_raid", &"sec_toll"]:
		if objective_state(String(id)) == "active":
			set_objective(id, "failed")
	_withdraw()
	var t := UnitType.find("greywater_tracker")
	if t and hero_alive():
		for i in 6:
			var g := _spawn(Worker.make_unit(t), Unit.Team.NEUTRAL, LODGE_DOOR + Vector3(i * 1.2 - 3.0, 0.0, 2.0))
			set_truce([g], true, Unit.TRUCE_ALL)
			g.command_move(hero.global_position + Vector3(i - 3.0, 0.0, 3.0))
			var gu := g
			after(25.0, func() -> void:
				if is_instance_valid(gu) and gu.is_alive():
					gu.leave_map())
	say_l(29)
	say_l(30)
	set_objective(&"obj_vessa", "done")
	set_objective(&"obj_keep", "done")
	win(VICTORY_DELAY)


func _withdraw() -> void:
	clear_waves()
	for bot in _all_commanders():
		bot.set(&"enabled", false)
	for n in get_tree().get_nodes_in_group("units"):
		var u := n as Unit
		if u == null or not u.is_alive() or int(u.team) != Unit.Team.ENEMY or u.is_worker() or u.is_in_group(&"caravans"):
			continue
		set_truce([u], true, Unit.TRUCE_ALL)
		u.set_meta(META_MODE, &"withdraw")
		u.command_move(SHADOW_RALLY)
		var unit := u
		after(25.0, func() -> void:
			if is_instance_valid(unit) and unit.is_alive() and unit != shadow_hero:
				unit.leave_map())


func _on_malrik_died(_u: Unit) -> void:
	if is_ending():
		return
	hud.show_message(MSG_MALRIK_FELL, 4.0)
	_respawn_left[Unit.Team.ENEMY] = WIZARD_RESPAWN


func _on_e3_wizard_respawned(wiz: Wizard) -> void:
	if wiz != shadow_hero or is_ending() or guides_done:
		return
	# He rejoins the Reprisal while it runs; after W3 he goes back to his rally (spec: he stays there except in W3 / W4).
	if guides_left >= 0.0:
		order_wave(wiz, &"bazaar", _bazaar_target())
	else:
		_malrik_home = true


func _tick_malrik_home() -> void:
	if not _malrik_home or shadow_hero == null or not is_instance_valid(shadow_hero) or not shadow_hero.is_alive():
		return
	if shadow_hero.attack_target == null and _flat(shadow_hero.global_position, SHADOW_RALLY) > 4.0 and not shadow_hero.is_attack_moving():
		shadow_hero.command_attack_move(SHADOW_RALLY)


func _on_keep_destroyed(_b: Building) -> void:
	if is_ending() or guides_done:
		return
	fire_once(&"E23")
	say_l(32)
	set_objective(&"obj_keep", "failed")
	lose(DEFEAT_DELAY)


func _on_player_hero_fell() -> void:
	fire_once(&"E22")
	say_l(31)
	set_objective(&"obj_vessa", "failed")
	super()


# ---------------------------------------------------------------- every frame

func _physics_process(delta: float) -> void:
	super(delta)
	if not match_started or game_over or world_is_held:
		return
	tick_scripted(delta)
	if is_ending():
		return
	_tick_tribute(delta)
	_tick_guides(delta)
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.5
		_tick_malrik_home()
		if _button and is_instance_valid(_button):
			_button.disabled = guides_done or tributes_paid >= TRIBUTES
		var t := "%s|%s|%s|%s" % [objective_text(&"obj_tribute"), objective_text(&"obj_guides"),
				objective_text(&"sec_magpies"), objective_text(&"sec_raid")]
		if t != _last_obj_text:
			_last_obj_text = t
			objectives_changed.emit()
			if hud and mission_hud == null:
				hud.set_objective(_objective_text())
