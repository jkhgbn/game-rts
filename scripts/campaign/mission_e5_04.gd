class_name MissionE5_04
extends MissionE5Base
## Episode 5, mission 4 "Leftovers" (docs/design/mission-e5-04.md): the episode's finale, a flashback. On the Master's
## Proving Green below the citadel, Malrik (18, the player) and Vessa (17, the bot) play a friendly 1v1: five banners,
## the first side to hold three while the bell counts thirty wins. The citadel's long shadow lies on Malrik's half
## (his units hidden there, the e5m3 rule), his side neutralises Vessa's banners twice as fast and each one pays 100
## crystals (Spoils); hers takes empty banners faster. Vessa's banner plan is scripted (V1-V7): she takes the field
## fast, holds the centre, then charges and leaves her home banner thin. Spotlight: the Grave Hound.
##
## Built deviations (2026-10-08, from the spec):
## - The Proving Green is a flat 120 x 120 map with the main.gd tree / rock look (seed 5104) kept off the lawn's lanes;
##   the banners are MissionZones (radius 6, 12 s, the map-fill 4.3 rules by side; D3 multipliers as per-tick time
##   factors); the shadow (half-plane x + z < -36, the Hedge Garden, the North Walk, the Old Orchard) is mission-side:
##   a Malrik unit inside it and unseen is hidden from Vessa's auto-targets and seen only within 2.5 m.
## - Vessa's Commander (economy, training, at most 16 soldiers) never attacks; this script moves her army every 4 s (V1
##   east, V2 centre, V3 hold, V4 the charge with 70 % and <= 2 at home, V5 one retake group, V6 rider raids from 6:00,
##   V7 the yards from 12:00). She yields at 0 HP (the Skirmish respawn, 45 / 30 / 20 s). V2 waits for 4:30 (the spec's
##   "or 10 soldiers" trigger came at ~1:00 and her bell counted from ~2:00).
## - Her soldier cap is 8 / 12 / 18 (spec 10 / 16 / 22): while capped her Commander banks crystals and refills an army
##   lost in one fight within a minute: while capped she keeps at most 250 crystals (Vessa never saves).
## - The yards are out of the fight until 6:00 (truce on both keeps and Halls); Hovel / Hearth max 2 for both sides.
## - The counting bell (rush floor): Old Vey counts only from 12:00 / 15:00 / 18:00 (the Master lets them warm up); the
##   banners can be taken before. The scripted steal run won at 6:40 with the count open from 0:00.
## - sec_unseen: a banner taken by Malrik's side while no Vessa unit saw any of its takers during the capture.

const MISSION_ID := &"e5m4"
const MISSION_TITLE := "Leftovers"
const MAP_SEED := 5104
const MALRIK_SEAT := Unit.Team.PLAYER
const VESSA_SEAT := Unit.Team.ENEMY

const MALRIK_START := Vector3(-34.0, 0.0, -34.0)
const VESSA_START := Vector3(34.0, 0.0, 34.0)
const MALRIK_KEEP := Vector3(-42.0, 0.0, -42.0)
const VESSA_KEEP := Vector3(42.0, 0.0, 42.0)
const GLOOM_HALL := Vector3(-28.0, 0.0, -46.0)
const EMBER_HALL := Vector3(28.0, 0.0, 46.0)
const MALRIK_ARMY := Vector3(-30.0, 0.0, -28.0)
const VESSA_ARMY := Vector3(30.0, 0.0, 28.0)
const NODES := [[&"g_shadow_a", Vector3(-50.0, 0.0, -32.0)], [&"g_shadow_b", Vector3(-32.0, 0.0, -52.0)],
		[&"g_shadow_x", Vector3(-48.0, 0.0, 2.0)], [&"g_fire_a", Vector3(50.0, 0.0, 32.0)], [&"g_fire_b", Vector3(32.0, 0.0, 52.0)],
		[&"g_fire_x", Vector3(48.0, 0.0, -2.0)]]
const NODE_AMOUNT := 1500
## Banner id -> [name, position, radius, owner side at 0:00].
const BANNERS := {
	&"bn_shadow": ["Shadow Banner", Vector3(-22.0, 0.0, -22.0), 5.0, 0],
	&"bn_west": ["West Banner", Vector3(-28.0, 0.0, 20.0), 5.0, -1],
	&"bn_orrery": ["Orrery Banner", Vector3(0.0, 0.0, 0.0), 6.0, -1],
	&"bn_east": ["East Banner", Vector3(28.0, 0.0, -20.0), 5.0, -1],
	&"bn_fire": ["Fire Banner", Vector3(22.0, 0.0, 22.0), 5.0, 1],
}
const CIRCLES := [[Vector3(-18.0, 0.0, 4.0), 7.0], [Vector3(6.0, 0.0, -18.0), 7.0], [Vector3(14.0, 0.0, 31.0), 6.0]]
const LONG_SHADOW := -36.0              ## x + z below this = the citadel's long shadow
const CAPTURE_TIME := 12.0
const BANNER_SIGHT := 12.0
const SPOILS := 100
const HIDDEN_SEEN := 2.5
const BELL_GOAL := 30.0
const BELL_FROM: Array[float] = [720.0, 900.0, 1080.0]   ## Old Vey counts from the twelfth / fifteenth / eighteenth bell
const VESSA_BELL: Array[float] = [40.0, 30.0, 30.0]
const NEUTRAL_BONUS: Array[float] = [1.0, 1.25, 1.5]
const STEAL_BONUS := 2.0
const YARDS_OPEN := 360.0
const V1_AT := 90.0
const V2_AT := 270.0
const V2_ARMY := 10
const V4_DELAY: Array[float] = [20.0, 20.0, 10.0]
const V4_AT: Array[float] = [540.0, 540.0, 450.0]
const V4_EVERY := 150.0
const V4_SHARE: Array[float] = [0.85, 0.70, 0.55]
const V4_HOME_MAX: Array[int] = [1, 2, 4]
const V6_FROM := 360.0
const V6_EVERY := 120.0
const V7_FROM := 720.0
const CHARGE_TIME := 60.0
const RETAKE_TIME := 60.0
const RAID_TIME := 40.0
const ORDER_EVERY := 4.0
const VESSA_BACK: Array[float] = [45.0, 30.0, 20.0]
const VESSA_SOLDIERS: Array[int] = [8, 12, 18]   ## spec 10 / 16 / 22: a capped Commander banks crystals and refills at once
const VESSA_RETREAT := 0.35
const VESSA_BANK := 250              ## her crystals while her soldier cap holds
const MAX_HOUSES := 2
const LEVEL_CAP := 5
const START_CRYSTALS: Array[int] = [400, 300, 250]
const MALRIK_SPELLS := [&"shadow_lance", &"shadow_lance", &"soul_siphon"]
const VESSA_SPELLS := [&"fireball", &"fireball", &"ember_step"]
const DEFEAT_DELAY := 3.0

const SPEAKER_COLORS := {&"malrik": Color(0.7, 0.3, 1.0), &"vessa": Color(1.0, 0.45, 0.1), &"master": Color(1.0, 0.92, 0.70),
		&"vey": Color(0.95, 0.95, 0.55), &"torvald": Color(0.55, 0.80, 1.00), &"ysolde": Color(0.55, 0.90, 0.35),
		&"narrator": Color(0.9, 0.85, 0.7)}
const SPEAKER_NAMES := {&"malrik": "Malrik", &"vessa": "Vessa", &"master": "The Master", &"vey": "Old Vey",
		&"torvald": "Torvald", &"ysolde": "Ysolde", &"narrator": "Narrator"}
## The spec's 23 lines (data/voice/lines/e5m4.json): LINE_IDS[n - 1] = id of line n.
const LINE_IDS: Array[String] = ["L1", "L2", "L3", "L4", "L5", "L6", "L7", "L8", "L9", "L10", "L11", "L12", "L13",
		"L14", "L15", "L16", "L17", "L18", "L19", "L20", "L21", "L22", "L23"]
const DIALOGUE := [
	[&"narrator", "Five years later, below the citadel. A friendly match. Supposedly."],
	[&"master", "Five banners. The first to hold three while the bell counts thirty wins. Nobody gets hurt."],
	[&"vessa", "Define hurt. ...Kidding! Malrik, you take the shady side. You like it there."],
	[&"malrik", "Of course. The side nobody picked. I have had a great deal of practice with those."],
	[&"torvald", "She'll take the field in five minutes. He'll take it in the last one."],
	[&"ysolde", "I'm cheering for the grass. Nobody ever cheers for the grass."],
	[&"vessa", "Three! Ring it, Vey! Ring it, ring it, ring it!"],
	[&"vey", "Thirty, girl. Count with me. One..."],
	[&"malrik", "There she goes. She never looks behind her. Somebody should."],
	[&"vessa", "Hey! That's MY banner! You can't just take it!"],
	[&"malrik", "I was given the leftovers, Vessa. I have learned to take the rest."],
	[&"master", "The bell counts for Malrik."],
	[&"vessa", "Ow! Fine! I yield! This counts as a tie!"],
	[&"vey", "It does not count as a tie."],
	[&"torvald", "Did anyone see him move? No. Nobody ever does."],
	[&"malrik", "Her banner, her crystals. Fire is generous when it isn't looking."],
	[&"master", "Malrik wins. By taking."],
	[&"malrik", "You taught us to use what we were given. I was given leftovers. I used them."],
	[&"master", "...Yes. Well played."],
	[&"vessa", "Rematch. Now. Best of three. Best of five!"],
	[&"master", "Later, my joy. Both of you, come up to the orrery. I have something for you."],
	[&"malrik", "I yield. ...This time."],
	[&"vessa", "Thirty! Fair and square! Malrik, you can keep the shade!"],
]
const BRIEFING_PARAGRAPHS: Array[String] = [
	"Winter, the truce. Malrik counts something on his fingers. It is always the same list.",
	"Five years after Wickmoor, the Master's youngest apprentices were nearly grown, and still keeping score. Below the citadel lies the Proving Green, his practice field. On the terrace above it, the Master, Torvald and Ysolde sat to watch, and Old Vey took the bell-rope.",
	"Five banners. The first to hold three while the bell counts thirty wins. Vessa chose her side first, the sunny one. Malrik got the other. He was used to that.",
]
const HINT_START := "Hold three of the five banners while the bell counts 30. Stand in a banner's ring to take it; more soldiers take it faster."
const HINT_SHADOW := "The citadel's shadow is yours: in the violet shade your units are hidden unless an enemy comes within 2.5 m."
const HINT_STEAL := "Your side takes Vessa's banners twice as fast, and each one pays 100 crystals. She takes empty banners faster."
const HINT_CHARGE := "She left her home banner thin. The Old Orchard's shade is 11 m from it."
const HINT_SHROUD := "Ctrl+E learns Umbral Shroud: E halves the damage Malrik takes for 5 s and speeds him up."
const MSG_YARDS_OPEN := "The sixth bell: the practice yards may be burned."
const MSG_SPOILS := "Spoils! +{n}"
const MSG_VESSA_ASH := "Vessa's yard is ash. The banners still decide."
const MSG_TWO_HOUSES := "Two houses at most on the practice field"

## Read only.
var banners := {}                       ## id -> MissionZone
var vessa: Wizard = null
var bell := [0.0, 0.0]                  ## the bell count per side (s)
var spoils := 0
var victory_time := -1.0
var v_phase := 0                        ## 0 waiting, 1 east, 2 centre, 3 hold, 4 charge
var charges := 0
var vessa_yields := 0

var _tick := 0.0
var _order_left := 0.0
var _v3_at := -1.0
var _next_charge_at := -1.0
var _charge_until := -1.0
var _charge_target := &""
var _retake_target := &""
var _retake_until := -1.0
var _raid_until := -1.0
var _next_raid_at := V6_FROM
var _yards_open := false
var _seen_capture := {}                 # banner id -> true once a Vessa unit saw a Malrik taker during the capture
var _yards: Array = []
var _vessa_capped := false


# ---------------------------------------------------------------- setup

func _init() -> void:
	super()
	player_kingdom = &"shadow"
	enemy_kingdom = &"fire"
	line_ids = LINE_IDS.duplicate()
	dialogue_lines = DIALOGUE
	speaker_colors = SPEAKER_COLORS.duplicate()
	speaker_names = SPEAKER_NAMES.duplicate()
	briefing_paragraphs = BRIEFING_PARAGRAPHS.duplicate()
	define_objectives([[&"obj_banners", "primary"], [&"obj_malrik", "primary"], [&"obj_vessa_count", "primary"],
			[&"sec_take", "secondary"], [&"sec_unseen", "secondary"]])


func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	MissionE5Base.e5_config(c)
	c.mission_id = MISSION_ID
	c.title = MISSION_TITLE
	c.defeat_on_keep_lost = true
	c.keep_lost_message = "Malrik's yard has burned"
	c.start_level = 3
	c.start_spells.assign(MALRIK_SPELLS)
	c.start_spell_points = 0
	c.level_cap = LEVEL_CAP
	c.start_crystals = START_CRYSTALS.duplicate()
	c.enemy_start_crystals = [300, 300, 300]
	c.start_essence = 250
	c.defeat_delay = DEFEAT_DELAY
	c.victory_banner = "VICTORY\nMalrik wins. By taking."
	c.defeat_banner = "DEFEAT"
	c.rewards = CampaignState.MISSION_REWARDS.get(MISSION_ID, {})
	c.spotlight = {"id": &"grave_hound", "trigger": &"manual", "key_hint": "Gloom Hall: C",
			"card": "Grave Hound. Fast teeth: go where her army isn't, take the banner, be gone."}
	return c


func _map_size() -> Vector2:
	return Vector2(120.0, 120.0)


func _player_start() -> Vector3:
	return MALRIK_START


func _title_line() -> String:
	return "Episode 5, Mission 4: %s" % MISSION_TITLE


func _ground_spots() -> Array[Vector4]:
	return [Vector4(MALRIK_KEEP.x, MALRIK_KEEP.z, 12.0, 0.0), Vector4(VESSA_KEEP.x, VESSA_KEEP.z, 12.0, 0.0),
			Vector4(0.0, 0.0, 7.0, 1.0)]


func _ready() -> void:
	super()
	# green_afternoon stand-in: low sun from the south-east, long shadows to the north-west
	tint_light(Color(1.0, 0.86, 0.62), 1.0, -24.0, Color(0.70, 0.66, 0.58), Color(0.44, 0.56, 0.74), Color(0.95, 0.80, 0.60))
	if camera_rig:
		camera_rig.focus_on(MALRIK_START)


# ---------------------------------------------------------------- seats

func start_position(team: int) -> Vector3:
	return VESSA_START if team == VESSA_SEAT else MALRIK_START


func base_center(team: int) -> Vector3:
	return VESSA_KEEP if team == VESSA_SEAT else MALRIK_KEEP


func node_of(team: int, suffix: String) -> CrystalNode:
	var id := StringName("g_%s_%s" % ["fire" if team == VESSA_SEAT else "shadow", "x" if suffix in ["mid", "x", "rich"] else suffix])
	var v: Variant = crystal_nodes.get(id)
	if v == null or not is_instance_valid(v):
		return null
	var n := v as CrystalNode
	return n if n != null and not n.is_depleted() else null


func bot_point(team: int, p: Vector3) -> Vector3:
	return base_center(team) + (p - base_center(team)) * 0.25


func bot_vector(_team: int, v: Vector3) -> Vector3:
	return v


func natural_hall_spot(team: int) -> Vector3:
	return Vector3(42.0, 0.0, -6.0) if team == VESSA_SEAT else Vector3(-42.0, 0.0, 6.0)


func rich_hall_spot(_team: int) -> Vector3:
	return Vector3.INF


func market_slot(_team: int) -> Vector3:
	return Vector3.INF


func tower_slot(_team: int, _which: StringName) -> Vector3:
	return Vector3.INF


## D5: Vessa yields and walks out of her keep 45 / 30 / 20 s later.
func next_respawn_delay(team: int) -> float:
	if team == VESSA_SEAT:
		return float(by_difficulty(VESSA_BACK))
	return super(team)


# ---------------------------------------------------------------- the map

func _build_map() -> void:
	var clearings: Array = [[MALRIK_KEEP, 16.0], [VESSA_KEEP, 16.0], [MALRIK_START, 8.0], [VESSA_START, 8.0],
			[GLOOM_HALL, 6.0], [EMBER_HALL, 6.0]]
	for row: Array in NODES:
		clearings.append([row[1], 7.0])
	for id: StringName in BANNERS:
		clearings.append([BANNERS[id][1], float(BANNERS[id][2]) + 5.0])
	var lanes: Array = []
	for a: StringName in BANNERS:
		for b: StringName in BANNERS:
			if String(a) < String(b):
				lanes.append([BANNERS[a][1], BANNERS[b][1], 4.0])
	lanes.append([MALRIK_START, BANNERS[&"bn_shadow"][1], 4.0])
	lanes.append([VESSA_START, BANNERS[&"bn_fire"][1], 4.0])
	scatter_props(MAP_SEED, clearings, lanes, 8, 12)
	for row: Array in NODES:
		_add_crystal_node(StringName(row[0]), row[1], NODE_AMOUNT)
	var mk := build_grid.spawn_complete(BuildingType.find("shadow_keep"), MALRIK_KEEP, MALRIK_SEAT) as Keep
	var vk := build_grid.spawn_complete(BuildingType.find("fire_keep"), VESSA_KEEP, VESSA_SEAT) as Keep
	var gh := build_grid.spawn_complete(BuildingType.find("shadow_barracks"), GLOOM_HALL, MALRIK_SEAT)
	var eh := build_grid.spawn_complete(BuildingType.find("fire_barracks"), EMBER_HALL, VESSA_SEAT)
	keep = mk
	shadow_keep = vk
	seat_keeps[MALRIK_SEAT] = mk
	seat_keeps[VESSA_SEAT] = vk
	seat_bases[MALRIK_SEAT] = MALRIK_KEEP
	seat_bases[VESSA_SEAT] = VESSA_KEEP
	_yards = [mk, vk, gh, eh]
	if vk:
		vk.destroyed.connect(func(_b: Building) -> void:
			if hud and not is_ending():
				hud.show_message(MSG_VESSA_ASH, 4.0))
	if not _SIM.enabled:
		ground_disc(Vector3(-30.0, 0.0, -30.0), 26.0, Color(0.30, 0.12, 0.45, 0.22))   # the long shadow (corner stand-in)
		for c: Array in CIRCLES:
			ground_disc(c[0], float(c[1]), Color(0.30, 0.12, 0.45, 0.30))
		box_prop(Vector3.ZERO, Vector3(1.6, 1.4, 1.6), Color(0.72, 0.58, 0.30))   # the orrery sundial


# ---------------------------------------------------------------- start state

func _on_navigation_ready() -> void:
	var diff := clampi(mission_difficulty, 0, 2)
	for id: StringName in BANNERS:
		for team: int in [MALRIK_SEAT, VESSA_SEAT]:
			fog.reveal(team, BANNERS[id][1], 8.0)
	fog.reveal(VESSA_SEAT, VESSA_START, FogOfWar.START_REVEAL)
	_setup_champions()
	hero = _make_wizard(MALRIK_SEAT)
	_spawn(hero, MALRIK_SEAT, MALRIK_START)
	_claim_wizard(hero, MALRIK_SEAT)
	ItemDrops.ensure_inventory(hero)
	MissionE5Base.young_look(hero, &"apprentice", 1.0)
	hero.level_changed.connect(_on_malrik_level)
	for i in 5:
		var w := _spawn(make_unit("gloom_thrall"), MALRIK_SEAT, MALRIK_KEEP + Vector3(4.0, 0.0, -3.0 + i * 1.3))
		w.call(&"command_gather", node_of(MALRIK_SEAT, "a" if i < 3 else "b"))
	var rows: Array = [["shade", 4 + (2 if diff == 0 else 0)], ["nightbolt", 2]]
	if diff != 2:
		rows.append(["grave_hound", 2])
	var k := 0
	for row: Array in rows:
		for i in int(row[1]):
			_spawn(make_unit(String(row[0])), MALRIK_SEAT, MALRIK_ARMY + Vector3(-3.0 + (k % 5) * 1.4, 0.0, (k / 5) * 1.5))
			k += 1
	# Vessa (the bot): wizard L3, workers, the start army; her Commander trains, this script moves the army.
	vessa = _make_wizard(VESSA_SEAT)
	_spawn(vessa, VESSA_SEAT, VESSA_START)
	_claim_wizard(vessa, VESSA_SEAT)
	raise_wizard(vessa, 3, VESSA_SPELLS)
	ItemDrops.ensure_inventory(vessa)
	MissionE5Base.young_look(vessa, &"apprentice", 1.0)
	mark_scripted(vessa)
	shadow_hero = vessa
	seat_heroes[VESSA_SEAT] = vessa
	vessa.died.connect(_on_vessa_died)
	for i in 5:
		var w := _spawn(make_unit("cinder_hand"), VESSA_SEAT, VESSA_KEEP + Vector3(-4.0, 0.0, 3.0 - i * 1.3))
		w.call(&"command_gather", node_of(VESSA_SEAT, "a" if i < 3 else "b"))
	k = 0
	for row: Array in [["flame_guard", 4], ["ember_archer", 2], ["blaze_rider", 2]]:
		for i in int(row[1]):
			_spawn(make_unit(String(row[0])), VESSA_SEAT, VESSA_ARMY + Vector3(-3.0 + (k % 5) * 1.4, 0.0, -(k / 5) * 1.5))
			k += 1
	_add_banners()
	set_truce(_yards.filter(func(b: Variant) -> bool: return b != null), true, Unit.TRUCE_ALL)   # D6
	_add_vessa_commander()
	begin_mission([&"obj_banners", &"obj_malrik", &"obj_vessa_count", &"sec_take", &"sec_unseen"])
	selection.select_units([hero])


func _add_banners() -> void:
	for id: StringName in BANNERS:
		var row: Array = BANNERS[id]
		var z := MissionZone.new()
		z.zone_id = id
		z.display_name = String(row[0])
		z.radius = float(row[2])
		z.capture_time = CAPTURE_TIME
		z.has_pole = true
		add_child(z)
		z.global_position = row[1]
		z.set_owner_side(int(row[3]))
		z.captured.connect(_on_banner_captured)
		z.neutralised.connect(_on_banner_neutralised)
		banners[id] = z


## Vessa's Commander (19.A / ai.md, profile mission_e5_04): economy and training only, never attacks.
func _add_vessa_commander() -> void:
	var path := "res://scripts/ai/commander.gd"
	if not ResourceLoader.exists(path):
		return
	var script := load(path) as Script
	if script == null or not script.can_instantiate():
		return
	var diff := clampi(mission_difficulty, 0, 2)
	var p := AIProfile.for_difficulty(diff)
	p.id = &"mission_e5_04"
	p.profile_id = p.id
	p.min_attack_pop = 99
	p.launch_attacks = false
	p.attack_full_pop = 0
	p.first_attack_by = 0.0
	p.worker_target_home = 8
	p.worker_target_expanded = 10
	p.worker_target_x2 = 10
	p.second_expansion = false
	p.expand_time = 480.0
	p.max_soldiers = int(VESSA_SOLDIERS[diff])
	p.tower1_time = 1.0e6
	p.tower2_time = 1.0e6
	p.hero_stays_home = true
	p.malrik_joins = AIProfile.MalrikJoins.NEVER
	p.champion_max = 0
	p.trade = false
	p.map_fill = false
	p.item_build = PackedStringArray()
	var bot: Node = script.new()
	bot.name = "ShadowBot"
	bot.set(&"team", VESSA_SEAT)
	bot.set(&"profile", p)
	add_child(bot)
	commanders.append(bot)


func _intro() -> void:
	fire_once(&"E1")
	play_cutscene(&"e5m4_green", _green_end)
	after(30.0, _e2_hint)
	after(120.0, _e4_hint)


## e5m4_green end state: both wizards at their starts, armies at their spots, no orders, banners as at 0:00.
func _green_end() -> void:
	for id in ["L1", "L2", "L3", "L4"]:
		say_l(id)
	if hud:
		hud.show_message(HINT_START, 12.0)
	if camera_rig and hero_alive():
		camera_rig.focus_on(hero.global_position)


func _e2_hint() -> void:
	if fire_once(&"E2") and hud:
		hud.show_message(HINT_SHADOW, 12.0)


func _e4_hint() -> void:
	if fire_once(&"E4") and hud:
		hud.show_message(HINT_STEAL, 12.0)


# ---------------------------------------------------------------- briefing, objectives

func briefing() -> Dictionary:
	return {
		"title": _title_line(),
		"paragraphs": BRIEFING_PARAGRAPHS.duplicate(),
		"objectives": [objective_text(&"obj_banners", false), objective_text(&"obj_vessa_count", false)],
		"rule": Loc.sink(objective_text(&"obj_malrik")),
	}


func owned(side: int) -> int:
	var n := 0
	for id: StringName in banners:
		if (banners[id] as MissionZone).owner_side == side:
			n += 1
	return n


func vessa_goal() -> float:
	return float(by_difficulty(VESSA_BELL))


func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_banners":
			if with_counter and mission_time() < bell_from():
				return "Hold three banners while the bell counts thirty (Malrik %d · Vessa %d · the bell from %s)" % [owned(0),
						owned(1), MissionE5Base.mmss(bell_from())]
			if with_counter:
				if bell[0] > 0.0:
					return "Hold three banners while the bell counts thirty (Malrik %d · Vessa %d · the bell %d)" % [owned(0),
							owned(1), int(bell[0])]
				return "Hold three banners while the bell counts thirty (Malrik %d · Vessa %d)" % [owned(0), owned(1)]
			return "Hold three banners while the bell counts thirty"
		&"obj_malrik":
			return "Malrik must not yield"
		&"obj_vessa_count":
			if with_counter and bell[1] > 0.0:
				return "Don't let Vessa's bell finish (the bell counts for Vessa: %d)" % int(bell[1])
			return "Don't let Vessa's bell finish"
		&"sec_take":
			return "Take Vessa's home banner"
		&"sec_unseen":
			return "Take a banner unseen"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_banners":
			var pos: Array = []
			for bid: StringName in banners:
				if (banners[bid] as MissionZone).owner_side != 0:
					pos.append((banners[bid] as MissionZone).global_position)
			return {"counter": owned(0), "goal": 3, "positions": pos, "countdown": BELL_GOAL - bell[0] if bell[0] > 0.0 else -1.0}
		&"obj_vessa_count":
			if bell[1] > 0.0:
				return {"countdown": vessa_goal() - bell[1]}
	return {}


# ---------------------------------------------------------------- banners and the bell

## D3 as time factors: Malrik's side x2 on a Vessa-owned banner, Vessa's side x1.25 on a neutral one.
func _tick_banners(dt: float) -> void:
	var nb := float(by_difficulty(NEUTRAL_BONUS))
	for id: StringName in banners:
		var z := banners[id] as MissionZone
		z.time_factor[0] = 1.0 / STEAL_BONUS if z.owner_side == 1 else 1.0
		z.time_factor[1] = 1.0 / nb if z.owner_side == -1 else 1.0
		z.tick(dt)
		if z.capture_side == 0 and z.progress > 0.0 and _malrik_seen_at(z):
			_seen_capture[id] = true
		elif z.capture_side != 0 and z.progress <= 0.0:
			_seen_capture.erase(id)


func _malrik_seen_at(z: MissionZone) -> bool:
	for u in units_of(MALRIK_SEAT):
		if u.is_worker() or _flat(u.global_position, z.global_position) > z.radius:
			continue
		if _seen(u):
			return true
	return false


func _on_banner_neutralised(z: MissionZone, old_side: int) -> void:
	if is_ending():
		return
	if old_side == 1:
		spoils += 1
		if economy:
			economy.add(SPOILS)
		if hud:
			hud.show_message(Loc.t(MSG_SPOILS, {"n": SPOILS}), 3.0)
		if fire_once(&"E8"):
			say_l("L16")
		if _retake_target == &"" and v_phase >= 2:
			_retake_target = z.zone_id
			_retake_until = mission_time() + RETAKE_TIME


func _on_banner_captured(z: MissionZone, side: int) -> void:
	if is_ending():
		return
	if side == 0:
		if z.zone_id == &"bn_fire" and fire_once(&"E7"):
			say_l("L10")
			say_l("L11")
			set_objective(&"sec_take", "done")
		if not _seen_capture.has(z.zone_id) and objective_state("sec_unseen") == "active":
			set_objective(&"sec_unseen", "done")
			fire_once(&"E9")
			say_l("L15")
	_seen_capture.erase(z.zone_id)
	fog.reveal(Unit.Team.PLAYER if side == 0 else VESSA_SEAT, z.global_position, BANNER_SIGHT)


## The bell (D2): 3+ banners count one toll per second; below 3 resets. First count to finish wins.
func bell_from() -> float:
	return float(by_difficulty(BELL_FROM))


func _tick_bell(dt: float) -> void:
	var open := mission_time() >= bell_from()
	for side in 2:
		if owned(side) >= 3 and open:
			if bell[side] <= 0.0:
				if side == 1 and fire_once(&"E5"):
					say_l("L7")
					say_l("L8")
				elif side == 0 and fire_once(&"E10"):
					say_l("L12")
				if side == 1 and v_phase == 2:
					v_phase = 3
					if _v3_at < 0.0:
						_v3_at = mission_time()
			bell[side] += dt
		else:
			bell[side] = 0.0
	if bell[0] >= BELL_GOAL:
		_malrik_wins()
	elif bell[1] >= vessa_goal():
		_vessa_wins()


func _malrik_wins() -> void:
	if is_ending() or not fire_once(&"E14"):
		return
	victory_time = mission_time()
	set_objective(&"obj_banners", "done")
	set_objective(&"obj_vessa_count", "done")
	if objective_state("sec_take") == "active":
		set_objective(&"sec_take", "failed")
	if objective_state("sec_unseen") == "active":
		set_objective(&"sec_unseen", "failed")
	set_mission_flag("e5m4_time", int(victory_time))
	set_mission_flag("e5m4_spoils", spoils)
	_stand_down()
	play_cutscene(&"e5m4_bell", _bell_end)


func _bell_end() -> void:
	for id in ["L17", "L18", "L19", "L20", "L21"]:
		say_l(id)
	set_objective(&"obj_malrik", "done")
	win(1.0)


func _vessa_wins() -> void:
	if is_ending() or not fire_once(&"E16"):
		return
	say_l("L23")
	set_objective(&"obj_vessa_count", "failed")
	lose(DEFEAT_DELAY)


## Both sides stop fighting (the match is over): a truce on every unit and building.
func _stand_down() -> void:
	clear_waves()
	for bot in commanders:
		if is_instance_valid(bot):
			bot.set(&"enabled", false)
	var all: Array = []
	for n in get_tree().get_nodes_in_group(&"units"):
		if n is Unit and (n as Unit).is_alive():
			all.append(n)
			(n as Unit).command_stop()
	set_truce(all, true, Unit.TRUCE_ALL)


# ---------------------------------------------------------------- the shadow (D3, the e5m3 hidden rule)

func in_shadow(p: Vector3) -> bool:
	if p.x + p.z < LONG_SHADOW:
		return true
	for c: Array in CIRCLES:
		if _flat(c[0], p) <= float(c[1]):
			return true
	return false


## True when some Vessa unit sees `u` (a hidden one only within 2.5 m).
func _seen(u: Unit) -> bool:
	var hidden := in_shadow(u.global_position)
	for e in units_of(VESSA_SEAT):
		if e.is_worker():
			continue
		var r := HIDDEN_SEEN if hidden else (14.0 if e is Wizard else 10.0)
		if _flat(e.global_position, u.global_position) <= r:
			return true
	return false


func _tick_shadow() -> void:
	for u in units_of(MALRIK_SEAT):
		if not in_shadow(u.global_position):
			continue
		if not _seen(u):
			u.hide_from_auto_target(0.6)
		u.apply_status(&"concealed", 0.6, true)


# ---------------------------------------------------------------- Vessa's banner plan (V1-V7)

func _vessa_army() -> Array[Unit]:
	var out: Array[Unit] = []
	for u in units_of(VESSA_SEAT, true):
		if not u.has_meta(SCRIPTED_GROUP):
			mark_scripted(u)   # new trainees: the script moves them, never her Commander
		out.append(u)
	# Scripted soldiers are not counted by her Commander: the soldier cap is held here (her Halls wait at the cap).
	var at_cap := out.size() >= int(by_difficulty(VESSA_SOLDIERS))
	var veco := Economy.for_team(VESSA_SEAT)
	if at_cap and veco and veco.crystals > VESSA_BANK:
		veco.crystals = VESSA_BANK   # she never saves: what the capped Halls cannot spend is gone (no instant refill)
		veco.changed.emit()
	if at_cap != _vessa_capped:
		_vessa_capped = at_cap
		for b in Building.for_team(VESSA_SEAT):
			var tb := b as TrainingBuilding
			if tb and not tb is Keep:
				if at_cap:
					tb.set_meta(TrainingBuilding.META_LOCKED, true)
				else:
					tb.remove_meta(TrainingBuilding.META_LOCKED)
	return out


func _banner_pos(id: StringName) -> Vector3:
	return (banners[id] as MissionZone).global_position


func _nearest_banner(from: Vector3, side: int) -> StringName:
	var best := &""
	var d := INF
	for id: StringName in banners:
		if (banners[id] as MissionZone).owner_side != side:
			continue
		var dd := _flat(_banner_pos(id), from)
		if dd < d:
			d = dd
			best = id
	return best


func _go(u: Unit, at: Vector3, near := 4.0) -> void:
	if u.attack_target == null and _flat(u.global_position, at) > near:
		u.command_attack_move(at + Vector3(randf_range(-2.0, 2.0), 0.0, randf_range(-2.0, 2.0)))


func _tick_vessa() -> void:
	var t := mission_time()
	var diff := clampi(mission_difficulty, 0, 2)
	var army := _vessa_army()
	# Phases.
	if v_phase == 0 and t >= V1_AT:
		v_phase = 1
		fire_once(&"E3")
		say_l("L5")
		say_l("L6")
	if v_phase == 1 and t >= V2_AT:
		v_phase = 2   # V2 at 4:30 (the spec's "or 10 soldiers" came at ~1:00: her bell then counted from ~2:00)
	if v_phase == 3 and _next_charge_at < 0.0:
		_next_charge_at = minf(_v3_at + float(V4_DELAY[diff]), float(V4_AT[diff]))
	if v_phase >= 2 and _next_charge_at < 0.0 and t >= float(V4_AT[diff]):
		_next_charge_at = t
	if _next_charge_at > 0.0 and t >= _next_charge_at:
		_next_charge_at = t + V4_EVERY
		_charge()
	if _charge_until > 0.0 and (t >= _charge_until or _charge_target == &"" \
			or (banners[_charge_target] as MissionZone).owner_side == 1):
		_charge_until = -1.0
		_charge_target = &""
	if _retake_target != &"" and (t >= _retake_until or (banners[_retake_target] as MissionZone).owner_side == 1):
		_retake_target = &""
	if t >= _next_raid_at:
		_next_raid_at = t + V6_EVERY
		_raid_until = t + RAID_TIME
	# Who goes where.
	var home := _banner_pos(&"bn_fire")
	var centre := _banner_pos(&"bn_orrery")
	var main_at := VESSA_ARMY
	match v_phase:
		1:
			main_at = _banner_pos(&"bn_east")
		2, 3, 4:
			main_at = centre
	army.sort_custom(func(a: Unit, b: Unit) -> bool: return _flat(a.global_position, home) < _flat(b.global_position, home))
	var home_max := int(V4_HOME_MAX[diff])
	var n := army.size()
	var charging := _charge_until > 0.0 and _charge_target != &""
	var charge_n := int(round(float(n) * float(V4_SHARE[diff]))) if charging else 0
	var retake_n := n / 2 if _retake_target != &"" else 0
	var raid_left := 3 if _raid_until > t else 0
	var yards := t >= V7_FROM and owned(0) >= 3
	var yard_left := 6 if yards else 0
	var gloom: Building = null
	for b in Building.for_team(MALRIK_SEAT):
		if b.is_alive() and b.building_type and b.building_type.id == &"shadow_barracks":
			gloom = b
			break
	var homers := 0
	for i in n:
		var u := army[i]
		# raiders: the fastest units go for Malrik's workers
		if raid_left > 0 and u.unit_type and u.unit_type.id == &"blaze_rider":
			raid_left -= 1
			var w := _nearest_worker(u.global_position)
			if w:
				_go(u, w.global_position, 2.0)
				continue
		if yard_left > 0 and gloom and i >= n / 2:
			yard_left -= 1
			if u.attack_target == null:
				u.command_attack(gloom)
			continue
		if retake_n > 0:
			retake_n -= 1
			_go(u, _banner_pos(_retake_target))
			continue
		if charging:
			if homers < home_max and i < n - charge_n:
				homers += 1
				_go(u, home)
				continue
			if i >= n - charge_n:
				_go(u, _banner_pos(_charge_target))
				continue
		_go(u, main_at)
	_order_vessa(charging, main_at)


func _nearest_worker(from: Vector3) -> Unit:
	var best: Unit = null
	var d := INF
	for u in units_of(MALRIK_SEAT):
		if u.is_worker():
			var dd := _flat(u.global_position, from)
			if dd < d:
				d = dd
				best = u
	return best


## V4: Vessa + the charge share go for the Malrik-owned banner nearest her army (the home banner keeps <= 2).
func _charge() -> void:
	var army := _vessa_army()
	var c := MissionBase._alive_pos(vessa, _banner_pos(&"bn_orrery"))
	if not army.is_empty():
		c = Vector3.ZERO
		for u in army:
			c += u.global_position
		c /= float(army.size())
	var target := _nearest_banner(c, 0)
	if target == &"":
		target = _nearest_banner(c, -1)
	if target == &"":
		return
	charges += 1
	v_phase = 4
	_charge_target = target
	_charge_until = mission_time() + CHARGE_TIME
	if fire_once(&"E6"):
		say_l("L9")
		show_spotlight()
		if hud:
			hud.show_message(HINT_CHARGE, 12.0)


func _order_vessa(charging: bool, main_at: Vector3) -> void:
	if vessa == null or not is_instance_valid(vessa) or not vessa.is_alive():
		return
	if vessa.hp < vessa.max_hp * VESSA_RETREAT:
		if _flat(vessa.global_position, VESSA_KEEP) > 6.0:
			vessa.command_move(VESSA_KEEP + Vector3(-4.0, 0.0, -4.0))
		return
	var to := main_at
	if charging:
		to = _banner_pos(_charge_target)
	if _retake_target == &"bn_fire":
		to = _banner_pos(&"bn_fire")
	if vessa.attack_target == null and _flat(vessa.global_position, to) > 4.0:
		vessa.command_attack_move(to)


func _on_vessa_died(_u: Unit) -> void:
	if is_ending():
		return
	vessa_yields += 1
	if fire_once(&"E11"):
		say_l("L13")
		say_l("L14")
	_respawn_left[VESSA_SEAT] = next_respawn_delay(VESSA_SEAT)
	_deaths[VESSA_SEAT] = int(_deaths.get(VESSA_SEAT, 0)) + 1


func _on_malrik_level(_u: Unit, level: int) -> void:
	if level >= 4 and fire_once(&"E12") and hud:
		hud.show_message(HINT_SHROUD, 12.0)


func _on_player_hero_fell() -> void:
	fire_once(&"E15")
	say_l("L22")
	set_objective(&"obj_malrik", "failed")
	super()


# ---------------------------------------------------------------- save / load

func load_state(d: Dictionary, nodes: Dictionary = {}) -> void:
	super(d, nodes)
	_apply_banner_owners(d)
	if not _yards_open:
		set_truce(_yards.filter(func(b: Variant) -> bool: return b != null and is_instance_valid(b)), true, Unit.TRUCE_ALL)


func save_state(ids: Dictionary = {}) -> Dictionary:
	var d := super(ids)
	var owners := {}
	for id: StringName in banners:
		owners[String(id)] = (banners[id] as MissionZone).owner_side
	d["banner_owners"] = owners
	return d


func _apply_banner_owners(d: Dictionary) -> void:
	var owners: Dictionary = d.get("banner_owners", {})
	for k: Variant in owners:
		var id := StringName(str(k))
		if banners.has(id):
			(banners[id] as MissionZone).set_owner_side(int(owners[k]))


# ---------------------------------------------------------------- every frame

func _physics_process(delta: float) -> void:
	super(delta)
	if not match_started or game_over or world_is_held or save_restoring:
		return
	tick_scripted(delta)
	if is_ending():
		return
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = 0.25
	_tick_banners(0.25)
	_tick_bell(0.25)
	_tick_shadow()
	if is_ending():
		return
	if not _yards_open and mission_time() >= YARDS_OPEN:
		_yards_open = true
		set_truce(_yards.filter(func(b: Variant) -> bool: return b != null and is_instance_valid(b)), false, Unit.TRUCE_ALL)
		fire_once(&"E13")
		if hud:
			hud.show_message(MSG_YARDS_OPEN, 6.0)
	_order_left -= 0.25
	if _order_left <= 0.0:
		_order_left = ORDER_EVERY
		_tick_vessa()
		enforce_max(&"shadow_hovel", MAX_HOUSES, MSG_TWO_HOUSES, MALRIK_SEAT)
		enforce_max(&"fire_hearth", MAX_HOUSES, MSG_TWO_HOUSES, VESSA_SEAT)
	objectives_changed.emit()
	if hud and mission_hud == null:
		hud.set_objective(_objective_text())
