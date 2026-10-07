class_name MissionE2_05
extends MissionBase
## Episode 2, mission 5 "The Light Below" (docs/design/mission-e2-05.md): the Episode 2 finale. A 2v2 in the Master's
## cavern (PLAYER Fire south-west + ALLY Ysolde's Nature south-east vs ENEMY Malrik's Shadow north-west + ENEMY_2
## Torvald's Ice north-east). Phase 1 "The Race": Vessa kindles the four seals of the Deep Door (Ysolde takes the east
## one), Malrik cracks them with the shard; the Wake meter fills (faster per amber seal) and the jailer-statue, the
## Doorwarden, wakes at 100 % after 9:00 or at 16:00. Then the boss: B1 walks to the Door and slams it, B2 is fed by
## Malrik's tether (kill him or drive him off), B3 the Door answers: Vessa at the Door with Old Vey = the Sunlance.
## The Door must hold. Fire titan: the Cinder Dragon (Dragon Roost from 8:00, the spotlight).
##
## Built deviations (2026-10-06, recorded in the spec's "Built" note):
## - The map is built in code on a 150 x 150 MapInfo (no World Forge `deep_door.map`): the Rift is a rock strip along
##   z = 0 (|x| 16-75) with the two Rift Bridges at x = +-45 and the dais (r 16) open in the centre; flyers do not cross
##   it (no flying in the engine yet): the Cinder Dragon walks the bridges. M0 night lighting.
## - The Dragon Roost is a mission building (the Ember Hall's type renamed, 300 crystals, 70 s, 1 500 HP) placed from a
##   mission button from 8:00 once the Ember Stables stand; it trains the Cinder Dragon, a story UnitType built in code
##   (cavalry-mounts.md 5 numbers, the 13.V13 model, breath = a 3 m splash on each hit). No Ember Crucible.
## - The Doorwarden is a scripted Unit (placeholder capsule 3.5 x 16 m, 15 000 HP, armor 25); its damage multipliers
##   (amber seals x 0.85 each, tether x 0.5, Exposed x 1.5) are applied on `damage_taken` (heal back / extra hit).
## - The bots are Commanders that never attack (the scripted waves are their attacks); Ysolde is scripted for the E seal
##   and the Door order; Maelis and Aldra are bonded story helpers back 45 s after a fall. No cine timelines.

const MISSION_ID := &"e2m5"
const MISSION_TITLE := "The Light Below"
const CAVERN_SIZE := 150.0
const PLAYER_SEAT := Unit.Team.PLAYER
const ALLY_SEAT := Unit.Team.ALLY
const SHADOW_SEAT := Unit.Team.ENEMY
const ICE_SEAT := Unit.Team.ENEMY_2
const SEAT_NAMES := {0: "fire", 3: "ally", 1: "shadow", 4: "ice"}

## Fire's canonical points (south-west); the other seats are images (seat_xf).
const KEEP_POS := Vector3(-52.0, 0.0, 56.0)
const VESSA_START := Vector3(-45.0, 0.0, 47.0)
const HALL_POS := Vector3(-36.0, 0.0, 60.0)
const SPIRE_POS := Vector3(-44.0, 0.0, 38.0)
const HOUSE_SPOTS: Array[Vector3] = [Vector3(-62.0, 0.0, 62.0), Vector3(-62.0, 0.0, 68.0)]
const ARMY_POS := Vector3(-40.0, 0.0, 44.0)
const RALLY := Vector3(-38.0, 0.0, 40.0)
const ROOST_SPOT := Vector3(-60.0, 0.0, 44.0)
const NODES := {&"a": [Vector3(-56.0, 0.0, 46.0), 2000], &"b": [Vector3(-44.0, 0.0, 62.0), 2000],
		&"mid": [Vector3(-30.0, 0.0, 34.0), 2500], &"seep": [Vector3(-70.0, 0.0, 20.0), 1500]}
const RIFT_HALF := 5.0
const RIFT_INNER := 16.0
const BRIDGE_X := 45.0
const BRIDGE_HALF := 4.0
const DAIS_R := 16.0
const DOOR_POS := Vector3.ZERO
const DOOR_R := 5.0
const SEALS := {&"N": Vector3(0, 0, -11), &"E": Vector3(11, 0, 0), &"S": Vector3(0, 0, 11), &"W": Vector3(-11, 0, 0)}
const SEAL_ORDER: Array[StringName] = [&"N", &"W", &"E", &"S"]
const SEAL_RANGE := 3.0
const SEAL_TIME := 4.0
const SEAL_BLOCK := 6.0
const SEAL_RESET_DAMAGE := 30.0
const STATUE_POS := Vector3(0.0, 0.0, -24.0)
const DOOR_RIM_N := Vector3(0.0, 0.0, -7.0)
const MALRIK_TETHER_SPOT := Vector3(0.0, 0.0, -24.0)   ## Spec (0, -28) is 21 m from the boss at the rim: inside 20 m here.
const NORTH_RAMP := Vector3(0.0, 0.0, -16.0)
const SOUTH_RIM := Vector3(0.0, 0.0, 7.5)
const SE_RIM := Vector3(7.0, 0.0, 7.0)
const ALCOVES: Array[Vector3] = [Vector3(-14, 0, -14), Vector3(14, 0, -14), Vector3(-14, 0, 14), Vector3(14, 0, 14)]
const SUNSTONES: Array[Vector3] = [Vector3(-28, 0, 20), Vector3(-12, 0, 30), Vector3(12, 0, 30), Vector3(28, 0, 20)]
const NW_TUNNEL := Vector3(-72.0, 0.0, -40.0)

const W1_AT := 240.0
const W2_AT := 420.0
const COVER_TIMES: Array[float] = [300.0, 540.0]
const COVER_HOLD := 90.0
const SEAL_RUN_AT := 180.0
const YSOLDE_AT := 150.0
const ROOST_AT := 480.0
const W3_AT := 660.0
const WAKE_FLOOR := 540.0
const WAKE_PUSH_DELAY := 20.0
const ICE_PRESSURE_DELAY := 90.0
const ICE_PRESSURE_EVERY := 120.0
const HOST_EVERY := 40.0
const HOST_MAX := 6
const WIZARD_RESPAWN := 60.0
const STORY_HELPER_BACK := 45.0
const DEFEAT_DELAY := 3.0
const VICTORY_DELAY := 2.0
const LEVEL_CAP := 8
const NO_SAVE_ESSENCE := 800
const ROOST_COST := 300
const DOOR_REGEN := 5.0
const DOOR_REGEN_QUIET := 5.0
const HOLD_HEAL := 1000.0
const DOOR_ARMOR := 30.0

## The boss (normal unless an array).
## Spec values. 2026-10-07 scripted runs: a ~40-unit army burnt 15 000 in 59 s (the spec's maths assumed ~145 DPS), but
## x 4 / x 2 / x 1.5 let the Door fall in every run (6 / 6): the tuning waits for a better scripted player.
const BOSS_HP: Array[float] = [11000.0, 15000.0, 19000.0]
const BOSS_ARMOR := 25.0
const SLAM_DAMAGE: Array[float] = [90.0, 120.0, 150.0]
const SLAM_EVERY_B1 := 6.0
const SLAM_EVERY := 5.0
const SLAM_WINDUP := 1.0
const SLAM_FIST := 60.0
const STONEHURL_EVERY_B1 := 10.0
const STONEHURL_EVERY_B3 := 8.0
const STONEHURL_WINDUP := 1.6
const STONEHURL_R := 3.5
const STONEHURL_DAMAGE := 70.0
const CALL_EVERY := 30.0
const CALL_EVERY_B3 := 20.0
const QUAKE_EVERY := 14.0
const QUAKE_R := 8.0
const QUAKE_DAMAGE := 55.0
const TETHER_RANGE := 20.0
const TETHER_FACTOR: Array[float] = [0.6, 0.5, 0.4]
const TETHER_HEAL: Array[float] = [10.0, 20.0, 30.0]
const AMBER_FACTOR := 0.85
const EXPOSED_FACTOR := 1.5
const EXPOSED_S := 8.0
const LANCE_EVERY: Array[float] = [12.0, 15.0, 18.0]
const LANCE_DAMAGE := 300.0
const LANCE_DOOR := 6.0
const VEY_RANGE := 8.0
const DOOR_HP: Array[float] = [7000.0, 6000.0, 5500.0]
const DOOR_PER_SEAL: Array[float] = [600.0, 500.0, 400.0]
const WAKE_BASE: Array[float] = [0.08, 0.10, 0.12]
const WAKE_CAP: Array[float] = [1080.0, 960.0, 840.0]
const WIZARD_LEVEL: Array[int] = [5, 6, 7]
const COUNT_MULT: Array[float] = [0.6, 1.0, 1.4]
const START_CRYSTALS: Array[int] = [600, 500, 400]
const MALRIK_SPELLS := [&"shadow_lance", &"shadow_lance", &"soul_siphon", &"soul_siphon", &"umbral_shroud"]
const TORVALD_SPELLS := [&"rime_bolt", &"rime_bolt", &"flash_freeze", &"flash_freeze", &"rime_aegis"]
const YSOLDE_SPELLS := [&"thornburst", &"thornburst", &"wild_bloom", &"wild_bloom", &"call_the_thicket"]

const WAVES := {
	&"ESCORT": [["shade", 4]],
	&"W1": [["shade", 4], ["grave_hound", 2]],
	&"W2": [["rimeshield", 5], ["shardcaster", 2], ["rime_seer", 1]],
	&"HUSH": [["shade", 3]],
	&"W3S": [["shade", 5], ["nightbolt", 2], ["shadow_knight", 1]],
	&"W3I": [["rimeshield", 4], ["shardcaster", 2], ["frost_mortar", 1]],
	&"PUSH": [["shade", 6], ["nightbolt", 3], ["shadow_knight", 1]],
	&"ICE": [["rimeshield", 4], ["shardcaster", 2], ["rime_colossus", 1]],
	&"GUARD": [["shade", 4], ["gloom_deacon", 1]],
}

const SPEAKER_COLORS := {
	&"vessa": Color(1.0, 0.45, 0.1), &"vey": Color(0.95, 0.95, 0.55), &"ysolde": Color(0.55, 0.90, 0.35),
	&"maelis": Color(0.60, 0.85, 0.50), &"malrik": Color(0.7, 0.3, 1.0), &"torvald": Color(0.55, 0.80, 1.00),
	&"aldra": Color(0.62, 0.95, 0.88), &"hush": Color(0.60, 0.50, 0.75), &"obren": Color(1.0, 0.80, 0.25),
	&"master": Color(0.95, 0.93, 0.85), &"messenger": Color(0.80, 0.92, 0.60), &"narrator": Color(0.9, 0.85, 0.7),
}
const SPEAKER_NAMES := {&"vessa": "Vessa", &"vey": "Old Vey", &"ysolde": "Ysolde", &"maelis": "Maelis",
		&"malrik": "Malrik", &"torvald": "Torvald", &"aldra": "Aldra", &"hush": "Mother Hush", &"obren": "Obren",
		&"master": "The Master", &"messenger": "Wren", &"narrator": "Narrator"}
## L1-L35 (index n - 1), then L12b = 36, L13b = 37, L17b = 38.
const DIALOGUE := [
	[&"narrator", "Under the roots of the world, a door. And on the other side of it, the one who made it."],
	[&"vessa", "That's it. That's the door. Vey, he's right there. Under my feet."],
	[&"vey", "Four seals. Wake them with the relics and the door stands. Let Malrik break them and it falls."],
	[&"malrik", "Good evening, Vessa. Mind the statue. It's been waiting a hundred years to stretch its legs."],
	[&"vessa", "One seal! See, Vey? I can be patient. For four seconds at a time."],
	[&"malrik", "Crack. Do you hear it, Vessa? That is the sound of a lock giving up."],
	[&"vey", "Kindle it again, girl. The relics are stronger than his pebble. If you hold them."],
	[&"ysolde", "The east seal is mine. Hold the west, Vessa. We have done this before."],
	[&"ysolde", "Torvald is on my bridge with half of winter. I could use some fire."],
	[&"torvald", "I will hold the north stair, Bishop. Do what you came to do, and quickly."],
	[&"aldra", "Rime on the ramp, Torvald. They will not climb it twice."],
	[&"hush", "Did you miss me, little ember? I missed you. Twice now."],
	[&"vessa", "A dragon! An actual dragon! Vey, I have a DRAGON."],
	[&"obren", "Wake, my jailer. The door was always mine to open."],
	[&"malrik", "Torvald, now. Both bridges. Let them choose which kingdom to lose."],
	[&"vey", "Obren's Wardens. They guarded this door before he turned. Now they guard nothing."],
	[&"master", "...Vessa?"],
	[&"malrik", "Dying in the dark. Twice in one war. I am starting to keep count."],
	[&"narrator", "A hundred years the jailer stood over the door. Tonight Malrik's stone told it to open it."],
	[&"malrik", "Open it, Mason. Let me see what the Master was so busy guarding."],
	[&"vessa", "Everyone on the door! Nobody touches it but us!"],
	[&"malrik", "Feed, old stone. Take what you need from me. I have plenty."],
	[&"vey", "He's holding it up with the shard! Cut the line, girl! Get to Malrik!"],
	[&"master", "Hold."],
	[&"ysolde", "The line is cut! Now, before he crawls back!"],
	[&"vey", "Feel that? He's pushing back from below. The spark first, Vessa. Then the storm."],
	[&"vessa", "Then let's give him something to push with. Door! Light! NOW!"],
	[&"torvald", "This is not what you promised, Bishop. You said a door. Not a jailer."],
	[&"aldra", "Winter goes home, Torvald. Let the Bishop dig his own grave."],
	[&"vessa", "It answered! The Door hit it! He's helping us!"],
	[&"messenger", "The Heartwood's down! But we're still with you!"],
	[&"malrik", "Keep your door, Vessa. I have the key, and all the time in the world."],
	[&"ysolde", "It held. Vessa. It held."],
	[&"vessa", "Master... I was... so close..."],
	[&"vey", "Sunfoot's burning! Back to the stair, girl, now!"],
	[&"vey", "No knives at our backs tonight. Hush is still licking her wounds. Good."],
	[&"vey", "So you do. Point it at the big statue, and try not to name it."],
	[&"vessa", "Master?! Master, I'm here! I'm right here!"],
]
const BRIEFING_PARAGRAPHS: Array[String] = [
	"At the bottom of the Sunrise Road the world opens into a cavern so big it has its own weather: warm wind rising from a chasm, and in the middle, set in the floor, a round white door that glows like a sunrise.",
	"The Master is on the other side, holding it shut. Four old seals ring the door; the relics can wake them. Malrik came down his own stair with Torvald, and the stone in his hand wants that door open.",
	"Ysolde's army came down behind Vessa. Two kingdoms on each side of the chasm, and between them, standing over the door like a jailer, a statue as tall as a tower. Its eyes are closed. For now.",
]
const BRIEFING_LINE := "Kindle the seals around the Door with Vessa. Each seal Malrik cracks brings the jailer closer to waking."
const HINT_SEALS := "Kindle a seal: Vessa beside it for 4 s. Malrik can crack them back. Ping Ysolde to help hold them."
const HINT_ROOST := "The Dragon Roost can be built: Ember Stables first, then the \"Raise the Dragon Roost\" button. A Cinder Dragon burns the jailer's Wardens."
const HINT_NO_STORM := "The Door answers only the storm"
const MSG_HALF := "The statue's eyes are warm."
const MSG_MALRIK_FELL := "Malrik has fallen back into the shadows"
const MSG_TORVALD_FELL := "Torvald has fallen, the frost will bring him back"
const BUTTON_ROOST := "Raise the Dragon Roost (300)"
const REFUSE_EARLY := "Available at 8:00"
const REFUSE_STABLES := "Needs Ember Stables"
const REFUSE_BUILT := "Already built"
const REFUSE_CRYSTALS := "Not enough crystals"
const REFUSE_WORKER := "No free Cinder Hand"
const REFUSE_SPOT := "No room for the Roost"

## Test / menu switch (before the tree): campaign flags to use instead of the save ({} = read the save).
var flag_override: Dictionary = {}

## Read only.
var seals := {}                        ## id -> &"grey" / &"gold" / &"amber"
var seal_progress := {}                ## id -> [side, progress 0-1] of the channel running there
var wake := 0.0                        ## 0-100
var woke := false
var wake_time := -1.0
var boss: Unit = null
var boss_phase := 0                    ## 0 asleep, 1 B1, 2 B2, 3 B3, 4 fallen
var door: Building = null
var door_dipped := false
var door_held := false
var tether_on := false
var exposed_left := 0.0
var lances := 0
var cover_active := false             ## Torvald's 90 s cover of the north ramp is on.
var vey: Unit = null
var ysolde: Wizard = null
var torvald: Wizard = null
var maelis: Helper = null
var aldra: Helper = null
var host: Array = []                   ## the Warden host (NEUTRAL before the wake, ENEMY after)
var roost: Building = null
var dragons := 0
var sunstones: Array[MissionBrazier] = []
var no_save_fallback := false
var waves_fired: Array[StringName] = []
var wave_units := {}
var said: Array[int] = []
var ember_hall: TrainingBuilding

var _flags_read := false
var _said := {}
var _tick := 0.0
var _host_left := HOST_EVERY
var _host_i := 0
var _slam_left := SLAM_EVERY_B1
var _hurl_left := STONEHURL_EVERY_B1
var _call_left := CALL_EVERY
var _quake_left := QUAKE_EVERY
var _lance_left := 0.0
var _door_quiet := 0.0
var _boss_guard := false
var _malrik_run := false
var _malrik_target: StringName = &""
var _escort: Array = []
var _ysolde_goal: StringName = &""
var _ice_cover_until := -1.0
var _ice_cover_units: Array = []
var _hall_type: BuildingType
var _roost_type: BuildingType
var _dragon_type: UnitType
var _door_type: BuildingType
var _boss_type: UnitType
var _sunwarden_type: UnitType
var _seal_meshes := {}
var _hush_cast: M00Cast = null
var _panel: Control
var _last_obj_text := ""
var _no_storm_said := false


# ---------------------------------------------------------------- setup

func _init() -> void:
	super()
	dialogue_lines = DIALOGUE
	speaker_colors = SPEAKER_COLORS.duplicate()
	speaker_names = SPEAKER_NAMES.duplicate()
	briefing_paragraphs = BRIEFING_PARAGRAPHS.duplicate()
	tavern_enabled = false
	trade_enabled = false
	river_enabled = false
	points_enabled = false
	camps_enabled = false
	beasts_enabled = false
	define_objectives([[&"obj_seals", "primary"], [&"obj_door", "primary"], [&"obj_doorwarden", "primary"],
			[&"obj_tether", "primary"], [&"obj_lance", "primary"], [&"obj_vessa", "primary"], [&"obj_keep", "primary"],
			[&"sec_seals", "secondary"], [&"sec_door", "secondary"], [&"sec_dragon", "secondary"]])


func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	c.mission_id = MISSION_ID
	c.title = MISSION_TITLE
	c.count_mult = COUNT_MULT.duplicate()
	c.defeat_on_keep_lost = false   # E24 is the mission's own
	c.tiers_enabled = true
	c.max_tier = 3
	c.bots_upgrade = false
	c.start_tiers = {PLAYER_SEAT: 3, ALLY_SEAT: 2, SHADOW_SEAT: 2, ICE_SEAT: 2}
	c.casters_enabled = true
	c.t3_enabled = true
	c.helpers_enabled = true
	c.cavalry_enabled = true
	c.titans_enabled = true
	c.start_level = 5
	c.start_spell_points = 4
	c.level_cap = LEVEL_CAP
	c.start_crystals = START_CRYSTALS.duplicate()
	c.instant_loss_on_wizard_death = true
	c.defeat_delay = DEFEAT_DELAY
	c.victory_banner = "VICTORY\nThe Door held"
	c.defeat_banner = "DEFEAT"
	c.seat_sides = {PLAYER_SEAT: 0, ALLY_SEAT: 0, SHADOW_SEAT: 1, ICE_SEAT: 1}
	c.seat_opponents = {SHADOW_SEAT: PLAYER_SEAT, ICE_SEAT: ALLY_SEAT, ALLY_SEAT: ICE_SEAT, PLAYER_SEAT: SHADOW_SEAT}
	c.seat_kingdoms = {ALLY_SEAT: &"nature", ICE_SEAT: &"ice"}
	c.rewards = {"flags": {"e2m5_seals_kindled": "sec_seals", "e2m5_door_bright": "sec_door",
			"e2m5_dragon_raised": "sec_dragon"}, "bonus_essence": {"sec_seals": 300, "sec_door": 300, "sec_dragon": 150},
			"set_flags": {"ep2_complete": true, "ep2_door_held": true, "fire_titans_unlocked": true,
			"ep2_torvald_doubts": true}, "next": &"ep2_ending"}
	c.spotlight = {"id": &"cinder_dragon", "trigger": &"unlock", "key_hint": "Dragon Roost: Z",
			"card": "Cinder Dragon. Fire from the sky: it flies over the Rift and burns what walks below."}
	return c


func _map_size() -> Vector2:
	return Vector2(CAVERN_SIZE, CAVERN_SIZE)


func _player_start() -> Vector3:
	return VESSA_START


func _use_map_dressing() -> bool:
	return false


func _title_line() -> String:
	return "Episode 2, Mission 5: %s" % MISSION_TITLE


func _ready() -> void:
	_hall_type = _make_hall_type()
	_dragon_type = _make_dragon_type()
	_roost_type = _make_roost_type()
	_door_type = _make_door_type()
	_boss_type = _make_boss_type()
	_sunwarden_type = _make_sunwarden_type()
	get_tree().node_added.connect(_on_e5_node_added)
	super()
	if camera_rig:
		camera_rig.focus_on(VESSA_START)
	EmberfallNight.apply_to(self, EmberfallNight.night())


func _exit_tree() -> void:
	if get_tree().node_added.is_connected(_on_e5_node_added):
		get_tree().node_added.disconnect(_on_e5_node_added)


# ---------------------------------------------------------------- types

## The cavalry Ember Hall card (cavalry-mounts.md 2.1): Z Flame Guard, X Ember Archer, C Ash Hurler, B Pyre Adept,
## N Cinder Arbalest (the Blaze Rider trains at the Stables).
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


## The Cinder Dragon (cavalry-mounts.md 5): 1 400 HP, breath 16 every 2.2 s (a 3 m splash here), 5.5 m/s, 700 / pop 6 / 85 s.
func _make_dragon_type() -> UnitType:
	var base := UnitType.find("briar_roc")
	var t := (base.duplicate() as UnitType) if base else UnitType.new()
	t.id = &"cinder_dragon"
	t.display_name = "Cinder Dragon"
	t.faction = &"fire"
	t.cost = 700
	t.pop = 6
	t.train_time = 85.0
	t.kill_xp = 350
	t.max_hp = 1400.0
	t.armor = 0.0
	t.attack_damage = 16.0
	t.attack_range = 4.0
	t.attack_cooldown = 2.2
	t.move_speed = 5.5
	t.aggro_range = 11.0
	t.sight_radius = 14.0
	t.requires_tier = 3
	t.card_key = "Z"
	t.radius = 1.4
	t.body_height = 4.0
	t.body_color = Color(0.15, 0.08, 0.06)
	t.projectile_color = Color(1.0, 0.45, 0.1)
	var model := "res://art/units/titans/cinder_dragon/cinder_dragon.tscn"
	if ResourceLoader.exists(model):
		t.model_scene = load(model) as PackedScene
		t.model_path = model
	return t


func _make_roost_type() -> BuildingType:
	var base := BuildingType.find("fire_barracks")
	if base == null:
		return null
	var t := base.duplicate() as BuildingType
	t.id = &"fire_lair"
	t.display_name = "Dragon Roost"
	t.cost = ROOST_COST
	t.build_time = 70.0
	t.max_hp = 1500.0
	t.max_count = 1
	var trains: Array[UnitType] = []
	if _dragon_type:
		trains.append(_dragon_type)
	t.trains = trains
	var model := "res://art/buildings/lair/fire/dragon_roost.tscn"
	if ResourceLoader.exists(model):
		t.model_path = model
	return t


## The Deep Door: a side-0 target in the floor (a plain Building, team PLAYER, never a defeat building).
func _make_door_type() -> BuildingType:
	var base := BuildingType.find("fire_hearth")
	if base == null:
		return null
	var t := base.duplicate() as BuildingType
	t.id = &"deep_door"
	t.display_name = "The Deep Door"
	t.kind = &"door"
	t.cost = 0
	t.max_hp = float(by_difficulty(DOOR_HP))
	t.footprint = Vector2i(3, 3)
	t.height = 0.6
	t.counts_for_defeat = false
	t.model_path = ""
	t.body_color = Color(0.95, 0.92, 0.80)
	t.color = Color(1.0, 0.93, 0.70)
	if &"pop_bonus" in t:
		t.set(&"pop_bonus", 0)
	return t


## The Doorwarden: a 3.5 m x 16 m jailer-statue (placeholder capsule).
func _make_boss_type() -> UnitType:
	var base := UnitType.find("ruin_warden")
	var t := (base.duplicate() as UnitType) if base else UnitType.new()
	t.id = &"doorwarden"
	t.display_name = "The Doorwarden"
	t.faction = &"neutral"
	t.max_hp = float(by_difficulty(BOSS_HP))
	t.armor = BOSS_ARMOR
	t.move_speed = 1.4
	t.radius = 3.5
	t.body_height = 16.0
	t.attack_damage = 60.0
	t.attack_range = 4.5
	t.attack_cooldown = 2.0
	t.aggro_range = 6.0
	t.sight_radius = 22.0
	t.kill_xp = 0
	t.commandable = false
	t.model_scene = null
	t.model_path = ""
	t.body_color = Color(0.30, 0.30, 0.32)
	t.eye_color = Color(1.0, 0.55, 0.1)
	return t


func _make_sunwarden_type() -> UnitType:
	var base := UnitType.find("ruin_warden")
	var t := (base.duplicate() as UnitType) if base else UnitType.new()
	t.display_name = "Sunwarden"
	t.pop = 0
	t.cost = 0
	t.commandable = true
	t.eye_color = Color(1.0, 0.92, 0.65)
	return t


func _on_e5_node_added(node: Node) -> void:
	var b := node as TrainingBuilding
	if b != null and _hall_type != null and b.building_type != null and b.building_type != _hall_type \
			and b.building_type.id == &"fire_barracks" and int(b.team) == PLAYER_SEAT:
		b.building_type = _hall_type
	var u := node as Unit
	if u != null and u.unit_type == _dragon_type:
		_on_dragon.call_deferred(u)


# ---------------------------------------------------------------- seats

## Fire's canonical point `p` placed in `seat`'s quadrant (ALLY mirror in x, ENEMY mirror in z, ENEMY_2 both).
static func seat_xf(seat: int, p: Vector3) -> Vector3:
	match seat:
		Unit.Team.ALLY:
			return Vector3(-p.x, p.y, p.z)
		Unit.Team.ENEMY:
			return Vector3(p.x, p.y, -p.z)
		Unit.Team.ENEMY_2:
			return Vector3(-p.x, p.y, -p.z)
	return p


## Commander (MT2 contract): a Crown Hollow Shadow-side point for this seat (Fire's canonical point is its image).
func bot_point(team: int, p: Vector3) -> Vector3:
	return seat_xf(team, Vector3(-p.x * 1.2, 0.0, -p.z * 1.3))


func bot_vector(team: int, v: Vector3) -> Vector3:
	return seat_xf(team, Vector3(-v.x, 0.0, -v.z))


func node_of(team: int, suffix: String) -> CrystalNode:
	var id := StringName("node_%s_%s" % [SEAT_NAMES.get(team, "fire"), suffix])
	var v: Variant = crystal_nodes.get(id)
	if v == null or not is_instance_valid(v):
		crystal_nodes.erase(id)
		return null
	var n := v as CrystalNode
	return n if n != null and not n.is_depleted() else null


func natural_hall_spot(team: int) -> Vector3:
	return seat_xf(team, Vector3(-36.0, 0.0, 30.0))


func rich_hall_spot(team: int) -> Vector3:
	return seat_xf(team, Vector3(-64.0, 0.0, 24.0))


func market_slot(_team: int) -> Vector3:
	return Vector3.INF


func tower_slot(team: int, which: StringName) -> Vector3:
	if which == &"natural" or which == &"S3":
		return seat_xf(team, Vector3(-32.0, 0.0, 28.0))
	return Vector3.INF


func start_position(team: int) -> Vector3:
	if team != PLAYER_SEAT:
		return seat_xf(team, VESSA_START)
	return super(team)


func base_center(team: int) -> Vector3:
	if seat_bases.has(team):
		return seat_bases[team]
	return seat_xf(team, KEEP_POS)


func respawn_point(team: int) -> Vector3:
	var k := keep_of(team)
	if k:
		return k.spawn_point()
	return seat_xf(team, KEEP_POS + Vector3(-6.0, 0.0, 6.0))


# ---------------------------------------------------------------- the map

func _build_map() -> void:
	_read_flags()
	_build_rift()
	for seat: int in [PLAYER_SEAT, ALLY_SEAT, SHADOW_SEAT, ICE_SEAT]:
		for suffix: StringName in NODES:
			var row: Array = NODES[suffix]
			_add_crystal_node(StringName("node_%s_%s" % [SEAT_NAMES[seat], suffix]), seat_xf(seat, row[0]), int(row[1]))
	var kinds := {PLAYER_SEAT: ["fire_keep", "fire_barracks", "fire_tower", "fire_hearth"],
			ALLY_SEAT: ["nature_keep", "nature_barracks", "nature_tower", "nature_hollow"],
			SHADOW_SEAT: ["shadow_keep", "shadow_barracks", "shadow_tower", "shadow_hovel"],
			ICE_SEAT: ["ice_keep", "ice_barracks", "ice_tower", "ice_lodge"]}
	for seat: int in kinds:
		var ids: Array = kinds[seat]
		var k := build_grid.spawn_complete(BuildingType.find(String(ids[0])), seat_xf(seat, KEEP_POS), seat) as Keep
		var hall := build_grid.spawn_complete(BuildingType.find(String(ids[1])), seat_xf(seat, HALL_POS), seat)
		build_grid.spawn_complete(BuildingType.find(String(ids[2])), seat_xf(seat, SPIRE_POS), seat)
		for p in HOUSE_SPOTS:
			build_grid.spawn_complete(BuildingType.find(String(ids[3])), seat_xf(seat, p), seat)
		match seat:
			PLAYER_SEAT:
				keep = k
				ember_hall = hall as TrainingBuilding
			SHADOW_SEAT:
				shadow_keep = k
			_:
				seat_keeps[seat] = k
		seat_bases[seat] = k.global_position if k else seat_xf(seat, KEEP_POS)
		seat_starts[seat] = seat_xf(seat, VESSA_START)
		if hall:
			hall.set_meta(&"e2m5_hall", true)
	door = build_grid.spawn_complete(_door_type, DOOR_POS, PLAYER_SEAT)
	if door:
		door.name = "DeepDoor"
		mark_scripted(door)
		door.damaged.connect(_on_door_damaged)
	for id: StringName in SEALS:
		seals[id] = &"grey"
		_add_seal_look(id)
	for p in SUNSTONES:
		var b := MissionBrazier.new()
		b.brazier_id = StringName("sun_%d" % sunstones.size())
		b.display_name = "Sunstone"
		nav_region.add_child(b)
		b.position = p
		sunstones.append(b)


## The Rift: rock (navmesh obstacles) along z = 0 for 16 <= |x| <= 75, except the two bridges at x = +-45.
func _build_rift() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.05, 0.07)
	var half := CAVERN_SIZE * 0.5
	var spans := [[-half, -BRIDGE_X - BRIDGE_HALF], [-BRIDGE_X + BRIDGE_HALF, -RIFT_INNER],
			[RIFT_INNER, BRIDGE_X - BRIDGE_HALF], [BRIDGE_X + BRIDGE_HALF, half]]
	for s: Array in spans:
		var x0 := float(s[0])
		var x1 := float(s[1])
		var size := Vector3(x1 - x0, 2.0, RIFT_HALF * 2.0)
		var shape := BoxShape3D.new()
		shape.size = size
		var body := _static_obstacle(Vector3((x0 + x1) * 0.5, 0.0, 0.0), shape, 1.0)
		body.add_to_group(&"navigation_geometry")
		if not _SIM.enabled:
			var mi := MeshInstance3D.new()
			var m := BoxMesh.new()
			m.size = Vector3(size.x, 0.2, size.z)
			mi.mesh = m
			mi.material_override = mat
			mi.position.y = 0.05
			body.add_child(mi)


func is_rift(p: Vector3) -> bool:
	if absf(p.z) > RIFT_HALF or absf(p.x) < RIFT_INNER:
		return false
	return absf(absf(p.x) - BRIDGE_X) > BRIDGE_HALF


func _add_seal_look(id: StringName) -> void:
	var mi := MeshInstance3D.new()
	var m := CylinderMesh.new()
	m.top_radius = 0.6
	m.bottom_radius = 0.9
	m.height = 1.4
	mi.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.5, 0.5)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.3, 0.3)
	mi.material_override = mat
	add_child(mi)
	mi.position = SEALS[id] + Vector3(0.0, 0.7, 0.0)
	_seal_meshes[id] = mi


func _paint_seal(id: StringName) -> void:
	var mi: MeshInstance3D = _seal_meshes.get(id)
	if mi == null:
		return
	var mat := mi.material_override as StandardMaterial3D
	match seals[id]:
		&"gold":
			mat.albedo_color = Color(1.0, 0.93, 0.70)
			mat.emission = Color(1.0, 0.85, 0.5)
		&"amber":
			mat.albedo_color = Color(1.0, 0.55, 0.1)
			mat.emission = Color(0.9, 0.4, 0.05)
		_:
			mat.albedo_color = Color(0.5, 0.5, 0.5)
			mat.emission = Color(0.3, 0.3, 0.3)


func _read_flags() -> void:
	if _flags_read:
		return
	_flags_read = true
	if not flag_override.is_empty():
		return
	no_save_fallback = not CampaignState.open(campaign_save_path).is_completed(&"e2m4")


func _flag(name: StringName) -> bool:
	_read_flags()
	if not flag_override.is_empty():
		return bool(flag_override.get(String(name), flag_override.get(name, false)))
	if no_save_fallback:
		return false
	var v: Variant = CampaignState.open(campaign_save_path).flag_value(String(name), false)
	return v == true or (v is int and int(v) != 0)


# ---------------------------------------------------------------- start state

func _on_navigation_ready() -> void:
	var diff := clampi(mission_difficulty, 0, 2)
	for seat: int in [SHADOW_SEAT, ICE_SEAT, ALLY_SEAT]:
		fog.reveal(seat, seat_xf(seat, VESSA_START), FogOfWar.START_REVEAL)
	fog.reveal(PLAYER_SEAT, DOOR_POS, 22.0)
	_setup_champions()
	# --- Fire.
	hero = _make_wizard(PLAYER_SEAT)
	_spawn(hero, PLAYER_SEAT, VESSA_START)
	_claim_wizard(hero, PLAYER_SEAT)
	ItemDrops.ensure_inventory(hero)
	_apply_campaign_start()
	hero.damage_taken.connect(_on_channeller_hit.bind(hero))
	for i in 6:
		var w := _spawn(make_unit("cinder_hand"), PLAYER_SEAT, VESSA_START + Vector3(-6.0 + i, 0.0, 6.0))
		w.call(&"command_gather", node_of(PLAYER_SEAT, "a" if i < 3 else "b"))
	var rows := [["flame_guard", 8 + (2 if diff == 0 else 0)], ["ember_archer", 4], ["pyre_adept", 2],
			["cinder_arbalest", 2], ["kilnwarden", 1], ["ashveil_saboteur", 1]]
	var army: Array[String] = []
	for row in rows:
		for k in int(row[1]):
			army.append(String(row[0]))
	for i in army.size():
		_spawn(make_unit(army[i]), PLAYER_SEAT, ARMY_POS + Vector3(-5.0 + (i % 7) * 1.6, 0.0, -1.0 + (i / 7) * 1.7))
	if _flag(&"e2m4_sunwardens"):
		for i in 4:
			_spawn(Worker.make_unit(_sunwarden_type), PLAYER_SEAT, VESSA_START + Vector3(3.0, 0.0, -2.0 + i * 1.5))
	for b in sunstones:
		b.lighter = hero
		if _flag(&"e2m4_road_lit"):
			b.light()
	# --- Nature (ALLY): Ysolde, Maelis, her base, army.
	var ally := activate_seat(ALLY_SEAT, &"nature", {"crystals": 400,
			"workers": [["sprigling", 3, node_of(ALLY_SEAT, "a")], ["sprigling", 3, node_of(ALLY_SEAT, "b")]],
			"units": [["thornling", 6, seat_xf(ALLY_SEAT, ARMY_POS)], ["burr_slinger", 3, seat_xf(ALLY_SEAT, ARMY_POS)],
					["bloomtender", 2 + (2 if _flag(&"e2m2_carriers_kept") else 0), seat_xf(ALLY_SEAT, ARMY_POS)],
					["bramblehorn", 1 + (1 if _flag(&"e2m2_carriers_kept") else 0), seat_xf(ALLY_SEAT, ARMY_POS)]],
			"wizard": {"level": 5, "spells": YSOLDE_SPELLS, "pos": seat_xf(ALLY_SEAT, VESSA_START)}})
	ysolde = ally.get("wizard") as Wizard
	if ysolde:
		mark_scripted(ysolde)
		ysolde.damage_taken.connect(_on_channeller_hit.bind(ysolde))
		maelis = _story_helper(&"helper_maelis", ysolde, ALLY_SEAT)
	_add_seat_commander(ALLY_SEAT)
	# --- Shadow (ENEMY): Malrik and his army.
	shadow_hero = _make_wizard(SHADOW_SEAT)
	_spawn(shadow_hero, SHADOW_SEAT, seat_xf(SHADOW_SEAT, VESSA_START))
	_claim_wizard(shadow_hero, SHADOW_SEAT)
	raise_wizard(shadow_hero, WIZARD_LEVEL[diff], MALRIK_SPELLS)
	ItemDrops.ensure_inventory(shadow_hero)
	mark_scripted(shadow_hero)
	shadow_hero.died.connect(_on_malrik_died)
	shadow_hero.damage_taken.connect(_on_channeller_hit.bind(shadow_hero))
	var robbed := _flag(&"e2m3_malrik_robbed")
	var eco := Economy.for_team(SHADOW_SEAT)
	if eco:
		eco.crystals = 100 if robbed else 400
	for i in 6:
		var t := _spawn(make_unit("gloom_thrall"), SHADOW_SEAT, seat_xf(SHADOW_SEAT, VESSA_START + Vector3(-6.0 + i, 0.0, 6.0)))
		t.call(&"command_gather", node_of(SHADOW_SEAT, "a" if i < 3 else "b"))
	var srows := [["shade", 8], ["nightbolt", 3], ["shadow_knight", 0 if robbed else 2], ["gloom_deacon", 1]]
	var si := 0
	for row in srows:
		for k in int(row[1]):
			_spawn(make_unit(String(row[0])), SHADOW_SEAT, seat_xf(SHADOW_SEAT, ARMY_POS) + Vector3((si % 7) * 1.6 - 5.0, 0.0, (si / 7) * 1.7))
			si += 1
	# --- Ice (ENEMY_2): Torvald, Aldra, his army.
	var ice := activate_seat(ICE_SEAT, &"ice", {"crystals": 400,
			"workers": [["rime_hauler", 3, node_of(ICE_SEAT, "a")], ["rime_hauler", 3, node_of(ICE_SEAT, "b")]],
			"units": [["rimeshield", 6, seat_xf(ICE_SEAT, ARMY_POS)], ["shardcaster", 3, seat_xf(ICE_SEAT, ARMY_POS)],
					["frost_mortar", 1, seat_xf(ICE_SEAT, ARMY_POS)], ["rimecarver", 1, seat_xf(ICE_SEAT, ARMY_POS)]],
			"wizard": {"level": WIZARD_LEVEL[diff], "spells": TORVALD_SPELLS, "pos": seat_xf(ICE_SEAT, VESSA_START)}})
	torvald = ice.get("wizard") as Wizard
	if torvald:
		mark_scripted(torvald)
		torvald.died.connect(_on_torvald_died)
		aldra = _story_helper(&"helper_aldra", torvald, ICE_SEAT)
	_add_seat_commander(SHADOW_SEAT)
	_add_seat_commander(ICE_SEAT)
	wizard_respawned.connect(_on_e5_wizard_respawned)
	# --- The Warden host on the dais (NEUTRAL, leash 12), the statue asleep.
	for i in HOST_MAX:
		var a := float(i) * TAU / float(HOST_MAX)
		_add_host_warden(Vector3(cos(a) * 8.0, 0.0, sin(a) * 8.0), Unit.Team.NEUTRAL)
	_spawn_statue()
	if keep:
		keep.destroyed.connect(_on_keep_destroyed)
	var ch := AllyChannel.instance(get_tree(), self)
	if ch:
		ch.time_source = mission_time
	_add_events()
	begin_mission([&"obj_seals", &"obj_vessa", &"obj_keep", &"sec_seals"])
	_grant_vey()
	_build_panel()


func _apply_campaign_start() -> void:
	_read_flags()
	if no_save_fallback or not flag_override.is_empty():
		set_meta(&"campaign_flags", flag_override.duplicate())
		force_artifacts(hero, ["ember_crown", "masters_signet"])
		if no_save_fallback:
			var bank := EssenceBank.for_team(PLAYER_SEAT)
			if bank:
				bank.add(NO_SAVE_ESSENCE)
		return
	CampaignState.open(campaign_save_path).apply_to_start(self)


func _grant_vey() -> void:
	var roster := HelperRoster.for_team(PLAYER_SEAT)
	if roster == null:
		return
	vey = roster.grant(VESSA_START + Vector3(2.0, 0.0, 1.0))
	if vey == null:
		vey = roster.helper


## A bonded story helper (Maelis / Aldra): Escort, back beside its wizard 45 s after a fall.
func _story_helper(id: StringName, wiz: Wizard, seat: int) -> Helper:
	var ht := HelperType.find(id)
	if ht == null or wiz == null:
		return null
	var hp := Helper.new()
	hp.apply_helper_type(ht, wiz.level)
	hp.name = "%sStory" % String(id).trim_prefix("helper_").capitalize()
	_spawn(hp, seat as Unit.Team, wiz.global_position + Vector3(-2.0, 0.0, 2.0))
	hp.bond_to(wiz)
	hp.set_stance(&"escort")
	mark_scripted(hp)
	hp.died.connect(func(_u: Unit) -> void:
		after(STORY_HELPER_BACK, func() -> void:
			if is_instance_valid(hp) and not hp.is_alive() and is_instance_valid(wiz):
				hp.respawn(wiz.global_position + Vector3(-2.0, 0.0, 2.0))))
	return hp


## The seat's Commander profile: the kingdom's normal knobs, never attacks (the scripted waves are the attacks), 7
## workers, no expansion, at most 14 soldiers at the rally, no champions / trade / map fill.
func seat_profile(seat: int) -> AIProfile:
	var diff := clampi(mission_difficulty, 0, 2)
	var p: AIProfile
	match seat_kingdoms.get(seat, &"shadow"):
		&"ice":
			p = AIProfile.ice(diff)
		&"nature":
			p = AIProfile.nature(diff)
		_:
			p = AIProfile.for_difficulty(diff)
	p.id = StringName("mission_e2_05_%s" % SEAT_NAMES.get(seat, "bot"))
	p.profile_id = p.id
	p.min_attack_pop = 99
	p.launch_attacks = false
	p.attack_full_pop = 0
	p.first_attack_by = 0.0
	p.worker_target_home = 7
	p.worker_target_expanded = 7
	p.worker_target_x2 = 7
	p.second_expansion = false
	p.expand_time = 1.0e6
	p.max_soldiers = 16 if seat == ALLY_SEAT else 14
	p.build_rows = PackedStringArray(["H1", "V1", "S1", "V2"])
	p.rebuild = false
	p.hero_stays_home = true
	p.malrik_joins = AIProfile.MalrikJoins.NEVER
	p.champion_max = 0
	p.trade = false
	p.map_fill = false
	return p


func _add_seat_commander(seat: int) -> Node:
	var path := "res://scripts/ai/commander.gd"
	if not ResourceLoader.exists(path):
		return null
	var script := load(path) as Script
	if script == null or not script.can_instantiate():
		return null
	var bot: Node = script.new()
	bot.name = "ShadowBot" if seat == SHADOW_SEAT else "Bot%d" % seat
	bot.set(&"team", seat)
	bot.set(&"profile", seat_profile(seat))
	add_child(bot)
	commanders.append(bot)
	return bot


func _add_host_warden(at: Vector3, team: int) -> Unit:
	var u := _spawn(make_unit("ruin_warden"), team as Unit.Team, at)
	mark_scripted(u)
	if team == Unit.Team.NEUTRAL:
		u.set_meta(META_HOME, at)
	host.append(u)
	return u


func _spawn_statue() -> void:
	boss = _spawn(Worker.make_unit(_boss_type), Unit.Team.NEUTRAL, STATUE_POS)
	boss.name = "Doorwarden"
	boss.add_to_group(&"boss")
	boss.add_to_group(&"titans")
	mark_scripted(boss)
	set_dormant(boss, true)
	set_truce([door], true, Unit.TRUCE_ALL)   # untargetable before the wake


# ---------------------------------------------------------------- briefing, objectives, lines

func briefing() -> Dictionary:
	return {
		"title": _title_line(),
		"paragraphs": BRIEFING_PARAGRAPHS.duplicate(),
		"objectives": [objective_text(&"obj_seals", false), objective_text(&"obj_door", false),
				objective_text(&"obj_vessa", false), objective_text(&"obj_keep", false), BRIEFING_LINE],
		"rule": "%s · %s" % [Loc.sink(objective_text(&"obj_vessa")), Loc.sink(objective_text(&"obj_keep"))],
	}


func seal_count(state: StringName) -> int:
	var n := 0
	for id: StringName in seals:
		if seals[id] == state:
			n += 1
	return n


func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_seals":
			if with_counter:
				var head := "Kindle the Door's seals (%d / 4 white-gold · %d amber)" % [seal_count(&"gold"), seal_count(&"amber")]
				return "%s\n%s" % [head, "The Doorwarden stirs: %d %%" % int(wake)]
			return "Kindle the Door's seals"
		&"obj_door":
			if with_counter and door and is_instance_valid(door):
				return "The Deep Door must hold (%d %%)" % int(100.0 * door.hp / maxf(1.0, door.max_hp))
			return "The Deep Door must hold"
		&"obj_doorwarden":
			if with_counter and boss and is_instance_valid(boss):
				return "Stop the Doorwarden (%d %%)" % int(100.0 * boss.hp / maxf(1.0, boss.max_hp))
			return "Stop the Doorwarden"
		&"obj_tether":
			return "Break Malrik's tether: kill him or drive him off"
		&"obj_lance":
			return "Stand Vessa by the Door with Old Vey: the Door will strike"
		&"obj_vessa":
			return "Vessa must survive"
		&"obj_keep":
			return "Sunfoot must stand"
		&"sec_seals":
			return "All four seals white-gold when the jailer wakes"
		&"sec_door":
			return "Keep the Door above half its light"
		&"sec_dragon":
			return "Raise a Cinder Dragon"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_seals":
			return {"progress": int(wake), "goal": 100, "position": DOOR_POS}
		&"obj_door":
			if door and is_instance_valid(door):
				return {"progress": int(door.hp), "goal": int(door.max_hp), "position": DOOR_POS}
		&"obj_doorwarden":
			if boss and is_instance_valid(boss):
				return {"progress": int(boss.hp), "goal": int(boss.max_hp), "marks": [100, 70, 35]}
	return {}


func say_l(n: int) -> void:
	if _said.has(n):
		return
	_said[n] = true
	said.append(n)
	say_line(n)


# ---------------------------------------------------------------- events

func _intro() -> void:
	fire_once(&"E1")
	play_cutscene(&"e2m5_cavern", func() -> void:
		if camera_rig and hero_alive():
			camera_rig.focus_on(hero.global_position)
		say_l(1)
		say_l(2)
		say_l(3)
		say_l(4)
		if hud:
			hud.show_message(HINT_SEALS, 10.0))


func _add_events() -> void:
	after(YSOLDE_AT, func() -> void:
		if is_ending():
			return
		fire_once(&"E4")
		_ysolde_goal = &"E"
		say_l(8))
	after(SEAL_RUN_AT, func() -> void: _malrik_run = true)
	after(W1_AT, _fire_wave.bind(&"W1"))
	after(W2_AT, _fire_wave.bind(&"W2"))
	for t in COVER_TIMES:
		after(t, _torvald_cover)
	after(ROOST_AT, _roost_open)
	after(W3_AT, _fire_wave.bind(&"W3"))
	add_event(&"E11", func() -> bool:
		if not hero_alive() or woke:
			return false
		for u: Variant in host:
			if is_instance_valid(u) and (u as Unit).is_alive() and (u as Unit).attack_target != null \
					and _flat((u as Unit).global_position, hero.global_position) <= 10.0:
				return true
		return false, func() -> void: say_l(16))
	add_event(&"E12", func() -> bool: return hero_alive() and not woke and _flat(hero.global_position, DOOR_POS) <= 6.0 + DOOR_R,
			func() -> void:
				say_l(17)
				say_l(38))


# ---------------------------------------------------------------- seals and the wake meter

func _side_of(team: int) -> int:
	return Teams.side_of(team) if Teams.multi else (0 if team == PLAYER_SEAT else 1)


## Units of side `side` within `r` of `at` (living, not dormant, not NEUTRAL).
func _side_units_near(at: Vector3, r: float, side: int) -> int:
	var n := 0
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u and u.is_alive() and int(u.team) != Unit.Team.NEUTRAL and _side_of(int(u.team)) == side \
				and _flat(u.global_position, at) <= r:
			n += 1
	return n


func _on_channeller_hit(amount: float, _attacker: Node3D, who: Unit) -> void:
	if amount < SEAL_RESET_DAMAGE:
		return
	for id: StringName in seal_progress:
		var row: Array = seal_progress[id]
		if row[2] == who:
			row[1] = 0.0


## Kindle (Vessa / Ysolde, side 0) or crack (Malrik, side 1): within 3 m for 4 s, paused while the other side is within
## 6 m, reset by 30+ damage to the channeller.
func _tick_seals(delta: float) -> void:
	for id: StringName in SEALS:
		var at: Vector3 = SEALS[id]
		var row: Array = seal_progress.get(id, [-1, 0.0, null])
		var who: Unit = null
		var side := -1
		for cand: Variant in [hero, ysolde, shadow_hero]:
			if cand == null or not is_instance_valid(cand) or not (cand as Unit).is_alive():
				continue
			var u := cand as Unit
			if _flat(u.global_position, at) > SEAL_RANGE:
				continue
			var s := _side_of(int(u.team))
			if (s == 0 and seals[id] == &"gold") or (s == 1 and seals[id] == &"amber"):
				continue
			who = u
			side = s
			break
		if who == null:
			seal_progress.erase(id)
			continue
		if row[0] != side or row[2] != who:
			row = [side, 0.0, who]
		if _side_units_near(at, SEAL_BLOCK, 1 - side) == 0:
			row[1] = float(row[1]) + delta / SEAL_TIME
		seal_progress[id] = row
		if float(row[1]) >= 1.0:
			seal_progress.erase(id)
			_set_seal(id, &"gold" if side == 0 else &"amber", who)


func _set_seal(id: StringName, state: StringName, by: Unit) -> void:
	seals[id] = state
	_paint_seal(id)
	flash_ring(SEALS[id], 3.0)
	if not woke:
		set_objective(&"obj_seals", "active")
	if state == &"gold" and by == hero and fire_once(&"E2"):
		say_l(5)
	if state == &"amber" and fire_once(&"E3"):
		say_l(6)
		say_l(7)


## The Wake meter (%): 0.10 / s + 0.10 per amber seal - 0.05 per white-gold seal (min 0.05); wakes at 100 % after 9:00,
## or at the cap (16:00 on normal).
func wake_rate() -> float:
	return maxf(0.05, float(by_difficulty(WAKE_BASE)) + 0.10 * seal_count(&"amber") - 0.05 * seal_count(&"gold"))


func _tick_wake(delta: float) -> void:
	if woke:
		return
	wake = minf(100.0, wake + wake_rate() * delta)
	if wake >= 50.0 and fire_once(&"wake_50") and hud:
		hud.show_message(MSG_HALF, 4.0)
	if wake >= 80.0 and fire_once(&"E9"):
		say_l(14)
	var t := mission_time()
	if (wake >= 100.0 and t >= WAKE_FLOOR) or t >= float(by_difficulty(WAKE_CAP)):
		wake_up()


## E14: the wake: seal effects, the host turns ENEMY, the Door targetable, B1, the wake push at +0:20.
func wake_up() -> void:
	if woke:
		return
	woke = true
	wake = 100.0
	wake_time = mission_time()
	fire_once(&"E14")
	var gold := seal_count(&"gold")
	if door and is_instance_valid(door):
		set_truce([door], false, Unit.TRUCE_ALL)
		var extra := float(by_difficulty(DOOR_PER_SEAL)) * gold
		door.max_hp += extra
		door.hp = door.max_hp
	set_objective(&"obj_seals", "done")
	set_objective(&"sec_seals", "done" if gold >= 4 else "failed")
	set_objective(&"obj_door", "active")
	set_objective(&"obj_doorwarden", "active")
	set_objective(&"sec_door", "active")
	for u: Variant in host.duplicate():
		if is_instance_valid(u) and (u as Unit).is_alive() and int((u as Unit).team) == Unit.Team.NEUTRAL:
			var at := (u as Unit).global_position
			host.erase(u)
			(u as Unit).leave_map()
			var w := _add_host_warden(at, Unit.Team.ENEMY)
			order_wave(w, &"hero", hero_pos())
	if boss and is_instance_valid(boss):
		set_dormant(boss, false)
		boss.team = Unit.Team.ENEMY
		boss.damage_taken.connect(_on_boss_hit)
		boss.died.connect(_on_boss_fell)
		boss.command_move(DOOR_RIM_N)
	boss_phase = 1
	play_cutscene(&"e2m5_wake", func() -> void:
		say_l(19)
		say_l(20)
		say_l(21))
	after(WAKE_PUSH_DELAY, func() -> void:
		if is_ending() or boss_phase >= 4:
			return
		var push := _rows(&"PUSH")
		var units := spawn_wave_at(push, _seat_spawn(SHADOW_SEAT), SHADOW_SEAT)
		for u in units:
			order_wave(u as Unit, &"hero", SOUTH_RIM)
		wave_units[&"PUSH"] = units)
	after(ICE_PRESSURE_DELAY, _ice_pressure)
	if ysolde:
		_ally_door_order()


# ---------------------------------------------------------------- the Warden host

func _tick_host(delta: float) -> void:
	host = host.filter(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive())
	if woke:
		return
	_host_left -= delta
	if _host_left > 0.0:
		return
	_host_left = HOST_EVERY
	var at := ALCOVES[_host_i % ALCOVES.size()]
	_host_i += 1
	for i in 2:
		if host.size() >= HOST_MAX:
			return
		_add_host_warden(at + Vector3(i * 1.5, 0.0, 0.0), Unit.Team.NEUTRAL)


# ---------------------------------------------------------------- the Doorwarden

func _boss_factor() -> float:
	var f := pow(AMBER_FACTOR, seal_count(&"amber"))
	if tether_on:
		f *= float(by_difficulty(TETHER_FACTOR))
	if exposed_left > 0.0:
		f *= EXPOSED_FACTOR
	return f


func _on_boss_hit(amount: float, attacker: Node3D) -> void:
	if _boss_guard or boss == null or not boss.is_alive():
		return
	var f := _boss_factor()
	if absf(f - 1.0) < 0.01:
		return
	if f < 1.0:
		boss.hp = minf(boss.max_hp, boss.hp + amount * (1.0 - f))
	else:
		_boss_guard = true
		boss.take_damage(amount * (f - 1.0), attacker)
		_boss_guard = false


func _tick_boss(delta: float) -> void:
	if boss_phase <= 0 or boss_phase >= 4 or boss == null or not is_instance_valid(boss) or not boss.is_alive():
		return
	var pct := boss.hp / maxf(1.0, boss.max_hp)
	if boss_phase == 1 and pct <= 0.70:
		_start_b2()
	elif boss_phase == 2 and pct <= 0.35:
		_start_b3()
	if exposed_left > 0.0:
		exposed_left -= delta
	# It stays at the Door's north rim (within 7 m of the Door).
	if _flat(boss.global_position, DOOR_RIM_N) > 2.5 and boss.attack_target == null and not boss.has_move_order():
		boss.command_move(DOOR_RIM_N)
	if boss.attack_target != null and _flat(boss.global_position, DOOR_POS) > 10.0:
		boss.command_move(DOOR_RIM_N)
	var near_door := _flat(boss.global_position, DOOR_POS) <= 7.0 + 3.5
	_slam_left -= delta
	if _slam_left <= 0.0 and near_door:
		_slam_left = SLAM_EVERY_B1 if boss_phase == 1 else SLAM_EVERY
		_door_slam()
	_hurl_left -= delta
	if _hurl_left <= 0.0:
		_hurl_left = STONEHURL_EVERY_B3 if boss_phase == 3 else STONEHURL_EVERY_B1
		_stonehurl()
	_call_left -= delta
	if _call_left <= 0.0:
		_call_left = CALL_EVERY_B3 if boss_phase == 3 else CALL_EVERY
		_warden_call(3 if boss_phase == 3 else 2)
	if boss_phase == 2:
		_quake_left -= delta
		if _quake_left <= 0.0 and _side_units_near(boss.global_position, QUAKE_R, 0) >= 4:
			_quake_left = QUAKE_EVERY
			_quake()
		_tick_tether(delta)
	if boss_phase == 3:
		_tick_lance(delta)


func _door_slam() -> void:
	var fist := boss.global_position.lerp(DOOR_POS, 0.6)
	flash_ring(fist, 3.0)
	get_tree().create_timer(SLAM_WINDUP, false, true).timeout.connect(func() -> void:
		if boss == null or not is_instance_valid(boss) or not boss.is_alive() or is_ending():
			return
		if door and is_instance_valid(door) and door.is_alive():
			door.take_damage(float(by_difficulty(SLAM_DAMAGE)), boss)
			_door_quiet = 0.0
		_hit_side0(fist, 3.0, SLAM_FIST))


## Stonehurl: at the biggest side-0 clump within 25 m (Vessa's clump wins ties); 1.6 s telegraph r 3.5, 70.
func _stonehurl() -> void:
	var best := Vector3.INF
	var best_n := 0
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u == null or not u.is_alive() or int(u.team) == Unit.Team.NEUTRAL or _side_of(int(u.team)) != 0:
			continue
		if _flat(u.global_position, boss.global_position) > 25.0:
			continue
		var n := _side_units_near(u.global_position, STONEHURL_R, 0) + (1 if u == hero else 0)
		if n > best_n:
			best_n = n
			best = u.global_position
	if best == Vector3.INF:
		return
	var at := best
	flash_ring(at, STONEHURL_R)
	get_tree().create_timer(STONEHURL_WINDUP, false, true).timeout.connect(func() -> void:
		if boss and is_instance_valid(boss) and boss.is_alive() and not is_ending():
			_hit_side0(at, STONEHURL_R, STONEHURL_DAMAGE))


func _quake() -> void:
	var at := boss.global_position
	flash_ring(at, QUAKE_R)
	get_tree().create_timer(1.2, false, true).timeout.connect(func() -> void:
		if boss == null or not is_instance_valid(boss) or not boss.is_alive() or is_ending():
			return
		for node in get_tree().get_nodes_in_group(&"units"):
			var u := node as Unit
			if u and u.is_alive() and int(u.team) != Unit.Team.NEUTRAL and _side_of(int(u.team)) == 0 \
					and _flat(u.global_position, at) <= QUAKE_R:
				u.take_damage(QUAKE_DAMAGE, boss)
				u.apply_status(&"dazed", 0.5 if u is Wizard else 1.0, true))


func _hit_side0(at: Vector3, r: float, dmg: float) -> void:
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u and u.is_alive() and int(u.team) != Unit.Team.NEUTRAL and _side_of(int(u.team)) == 0 \
				and _flat(u.global_position, at) <= r:
			u.take_damage(dmg, boss)


func _warden_call(n: int) -> void:
	var best := ALCOVES[0]
	var d := INF
	for a in ALCOVES:
		var dd := _flat(a, boss.global_position)
		if dd < d:
			d = dd
			best = a
	if vey and is_instance_valid(vey) and vey.is_alive() and _flat(vey.global_position, best) <= 6.0:
		return   # never inside Vey's storm
	for i in n:
		var w := _add_host_warden(best + Vector3(i * 1.5, 0.0, 0.0), Unit.Team.ENEMY)
		order_wave(w, &"hero", hero_pos())


## E15 (70 %): B2 "Shard-fed": Malrik's guard order, the tether.
func _start_b2() -> void:
	boss_phase = 2
	fire_once(&"E15")
	say_l(22)
	say_l(23)
	set_objective(&"obj_tether", "active")
	_malrik_run = false
	if shadow_hero and shadow_hero.is_alive():
		order_wave(shadow_hero, &"tether", MALRIK_TETHER_SPOT)
	for u in spawn_wave_at(_rows(&"GUARD"), MALRIK_TETHER_SPOT + Vector3(0.0, 0.0, -4.0), SHADOW_SEAT):
		(u as Unit).set_meta(META_HOME, MALRIK_TETHER_SPOT + Vector3(0.0, 0.0, -2.0))
		_guards.append(u)


func _tick_tether(delta: float) -> void:
	var on := shadow_hero != null and is_instance_valid(shadow_hero) and shadow_hero.is_alive() \
			and _flat(shadow_hero.global_position, boss.global_position) <= TETHER_RANGE
	if tether_on and not on and fire_once(&"E17"):
		say_l(25)
	tether_on = on
	if on:
		boss.hp = minf(boss.max_hp, boss.hp + float(by_difficulty(TETHER_HEAL)) * delta)


## E18 (35 %): B3 "The Light Below": the Door answers; Torvald goes home.
func _start_b3() -> void:
	boss_phase = 3
	tether_on = false
	fire_once(&"E18")
	set_objective(&"obj_tether", "done")
	set_objective(&"obj_lance", "active")
	_lance_left = 2.0
	play_cutscene(&"e2m5_answer", func() -> void:
		say_l(26)
		say_l(27))
	say_l(28)
	say_l(29)
	_torvald_withdraw()


func _tick_lance(delta: float) -> void:
	_lance_left -= delta
	if _lance_left > 0.0:
		return
	if not hero_alive() or _flat(hero.global_position, DOOR_POS) > LANCE_DOOR + DOOR_R:
		_lance_left = 0.5
		return
	if vey == null or not is_instance_valid(vey) or not vey.is_alive() or _flat(vey.global_position, hero.global_position) > VEY_RANGE:
		if not _no_storm_said and hud:
			_no_storm_said = true
			hud.show_message(HINT_NO_STORM, 4.0)
		_lance_left = 0.5
		return
	_lance_left = float(by_difficulty(LANCE_EVERY))
	sunlance()


## The Door's Sunlance: 300 to the Doorwarden + Exposed 8 s.
func sunlance() -> void:
	if boss == null or not is_instance_valid(boss) or not boss.is_alive():
		return
	lances += 1
	flash_ring(boss.global_position, 4.0)
	exposed_left = 0.0
	boss.take_damage(LANCE_DAMAGE, hero)
	exposed_left = EXPOSED_S
	if fire_once(&"E19"):
		say_l(30)


func _on_boss_fell(_u: Unit) -> void:
	if is_ending():
		return
	boss_phase = 4
	fire_once(&"E21")
	set_objective(&"obj_doorwarden", "done")
	if objective_state("obj_lance") == "active":
		set_objective(&"obj_lance", "done")
	set_objective(&"obj_door", "done")
	if objective_state("sec_door") == "active":
		set_objective(&"sec_door", "done")
	if objective_state("sec_dragon") == "active":
		set_objective(&"sec_dragon", "failed")
	_withdraw()
	play_cutscene(&"e2m5_fall", func() -> void:
		say_l(32)
		say_l(33)
		set_objective(&"obj_vessa", "done")
		set_objective(&"obj_keep", "done")
		win(VICTORY_DELAY))


func _withdraw() -> void:
	clear_waves()
	for bot in _all_commanders():
		if int(bot.get(&"team")) != ALLY_SEAT:
			bot.set(&"enabled", false)
	for n in get_tree().get_nodes_in_group("units"):
		var u := n as Unit
		if u == null or not u.is_alive() or u.is_worker():
			continue
		if host.has(u):
			u.leave_map()   # the host crumbles
			continue
		if int(u.team) != SHADOW_SEAT and int(u.team) != ICE_SEAT:
			continue
		set_truce([u], true, Unit.TRUCE_ALL)
		u.set_meta(META_MODE, &"withdraw")
		u.command_move(NW_TUNNEL if int(u.team) == SHADOW_SEAT else seat_xf(ICE_SEAT, KEEP_POS))


# ---------------------------------------------------------------- the Door

func _tick_door(delta: float) -> void:
	if not woke or door == null or not is_instance_valid(door):
		return
	if not door.is_alive():
		return
	_door_quiet += delta
	if _door_quiet >= DOOR_REGEN_QUIET:
		door.hp = minf(door.max_hp, door.hp + DOOR_REGEN * delta)
	var pct := door.hp / maxf(1.0, door.max_hp)
	if pct < 0.5 and not door_dipped:
		door_dipped = true
		if objective_state("sec_door") == "active":
			set_objective(&"sec_door", "failed")
		if not door_held:
			door_held = true
			fire_once(&"E16")
			door.hp = minf(door.max_hp, door.hp + HOLD_HEAL)
			flash_ring(DOOR_POS, 8.0)
			say_l(24)


## The Door's armor 30 (buildings have none): every hit but the Doorwarden's own loses 30 (flat, refunded at once);
## any hit stops the regen for 5 s.
func _on_door_damaged(amount: float, attacker: Node3D) -> void:
	_door_quiet = 0.0
	if attacker == boss or door == null or not is_instance_valid(door) or not door.is_alive():
		return
	door.hp = minf(door.max_hp, door.hp + minf(amount, DOOR_ARMOR))


func _on_door_destroyed(_b: Building) -> void:
	if is_ending():
		return
	fire_once(&"E23")
	set_objective(&"obj_door", "failed")
	play_cutscene(&"e2m5_breach", func() -> void: lose(DEFEAT_DELAY))


# ---------------------------------------------------------------- Malrik, Torvald, Ysolde

func _malrik_alive() -> bool:
	return shadow_hero != null and is_instance_valid(shadow_hero) and shadow_hero.is_alive()


## Malrik's seal runs (from 3:00): the nearest non-amber seal (N, W, E, S on ties) with 4 Shades, home under 35 %.
func _tick_malrik() -> void:
	if not _malrik_alive() or woke and boss_phase >= 2:
		return
	if not _malrik_run or woke:
		return
	var pct := shadow_hero.hp / maxf(1.0, shadow_hero.max_hp)
	if pct < 0.35:
		_malrik_target = &""
		shadow_hero.command_move(seat_xf(SHADOW_SEAT, RALLY))
		return
	if _malrik_target == &"" or seals[_malrik_target] == &"amber":
		_malrik_target = &""
		var best_d := INF
		for id in SEAL_ORDER:
			if seals[id] == &"amber":
				continue
			var d := _flat(shadow_hero.global_position, SEALS[id]) + SEAL_ORDER.find(id) * 0.5
			if d < best_d:
				best_d = d
				_malrik_target = id
		if _malrik_target == &"":
			return
		_escort = _escort.filter(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive())
		if _escort.is_empty():
			_escort = spawn_wave_at(_rows(&"ESCORT"), shadow_hero.global_position, SHADOW_SEAT)
	var goal: Vector3 = SEALS[_malrik_target]
	if _flat(shadow_hero.global_position, goal) > SEAL_RANGE - 0.8:
		if not shadow_hero.has_move_order() or shadow_hero.attack_target != null:
			shadow_hero.command_move(goal)
	for e: Variant in _escort:
		if not is_instance_valid(e):
			continue
		var u := e as Unit
		if u.is_alive() and u.attack_target == null and _flat(u.global_position, goal) > 5.0:
			u.command_attack_move(goal + Vector3(0.0, 0.0, -2.0))


func _on_malrik_died(_u: Unit) -> void:
	if is_ending():
		return
	if hud:
		hud.show_message(MSG_MALRIK_FELL, 4.0)
	_respawn_left[SHADOW_SEAT] = WIZARD_RESPAWN
	_malrik_target = &""
	if fire_once(&"E13"):
		say_l(18)


func _on_torvald_died(_u: Unit) -> void:
	if is_ending():
		return
	if hud:
		hud.show_message(MSG_TORVALD_FELL, 4.0)
	_respawn_left[ICE_SEAT] = WIZARD_RESPAWN


func _on_e5_wizard_respawned(wiz: Wizard) -> void:
	if is_ending():
		return
	if wiz == shadow_hero and boss_phase == 2:
		order_wave(wiz, &"tether", MALRIK_TETHER_SPOT)


## Torvald's cover (5:00 / 9:00): his rally army + Torvald + Aldra hold the dais north ramp for 90 s, then go back.
func _torvald_cover() -> void:
	if is_ending() or woke:
		return
	if fire_once(&"E6"):
		say_l(10)
		say_l(11)
	cover_active = true
	_ice_cover_units.clear()
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == ICE_SEAT and not u.is_worker() and not u.is_in_group(SCRIPTED_GROUP):
			mark_scripted(u)
			order_wave(u, &"cover", NORTH_RAMP)
			_ice_cover_units.append(u)
	for w: Variant in [torvald, aldra]:
		if w != null and is_instance_valid(w) and (w as Unit).is_alive():
			order_wave(w as Unit, &"cover", NORTH_RAMP + Vector3(0.0, 0.0, -3.0))
	after(COVER_HOLD, func() -> void:
		cover_active = false
		for u: Variant in _ice_cover_units:
			if is_instance_valid(u) and (u as Unit).is_alive():
				(u as Unit).remove_from_group(SCRIPTED_GROUP)
				(u as Unit).remove_meta(SCRIPTED_GROUP)
				(u as Unit).set_meta(META_MODE, &"withdraw")
				(u as Unit).command_move(seat_xf(ICE_SEAT, RALLY))
		for w: Variant in [torvald, aldra]:
			if w != null and is_instance_valid(w) and (w as Unit).is_alive():
				(w as Unit).set_meta(META_MODE, &"withdraw")
				(w as Unit).command_move(seat_xf(ICE_SEAT, VESSA_START)))


func _torvald_withdraw() -> void:
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == ICE_SEAT and not u.is_worker():
			mark_scripted(u)
			u.set_meta(META_MODE, &"withdraw")
			u.command_move(seat_xf(ICE_SEAT, RALLY))


## Ysolde (scripted): to her seal, kindles it, guards it; after the wake her army holds the Door's south-east rim.
func _tick_ysolde() -> void:
	if ysolde == null or not is_instance_valid(ysolde) or not ysolde.is_alive():
		return
	if woke:
		if _flat(ysolde.global_position, SE_RIM) > 3.0 and ysolde.attack_target == null and not ysolde.has_move_order():
			ysolde.command_attack_move(SE_RIM)
		return
	if _ysolde_goal == &"":
		return
	var goal: Vector3 = SEALS[_ysolde_goal]
	if seals[_ysolde_goal] == &"gold":
		if _flat(ysolde.global_position, goal) > 5.0 and ysolde.attack_target == null and not ysolde.has_move_order():
			ysolde.command_attack_move(goal + Vector3(2.0, 0.0, 0.0))
		return
	if _flat(ysolde.global_position, goal) > SEAL_RANGE - 0.8 and (not ysolde.has_move_order() or ysolde.attack_target != null):
		ysolde.command_move(goal)


func _ally_door_order() -> void:
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == ALLY_SEAT and not u.is_worker() and u != ysolde and not u is Helper:
			mark_scripted(u)
			u.set_meta(META_HOME, SE_RIM + Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(-3.0, 3.0)))
			_guards.append(u)
			u.command_attack_move(u.get_meta(META_HOME))


# ---------------------------------------------------------------- waves

func _rows(id: StringName) -> Array:
	var out: Array = []
	var diff := clampi(mission_difficulty, 0, 2)
	for row: Array in WAVES[id]:
		var tid := String(row[0])
		if diff == 0 and (tid == "rime_colossus" or (tid == "shadow_knight" and id != &"GUARD")):
			continue
		if tid == "shadow_knight" and _flag(&"e2m3_malrik_robbed") and (id == &"W3S" or id == &"PUSH"):
			continue
		out.append(row)
	return out


func _seat_spawn(seat: int) -> Vector3:
	for b in Building.for_team(seat):
		if b.is_alive() and b.has_meta(&"e2m5_hall") and b is TrainingBuilding:
			return (b as TrainingBuilding).spawn_point()
	var k := keep_of(seat)
	return k.spawn_point() if k else seat_xf(seat, KEEP_POS + Vector3(-8.0, 0.0, 8.0))


func _fire_wave(id: StringName) -> void:
	if is_ending() or boss_phase >= 4 or waves_fired.has(id):
		return
	waves_fired.append(id)
	match id:
		&"W1":
			var units := spawn_wave_at(_rows(&"W1"), _seat_spawn(SHADOW_SEAT), SHADOW_SEAT)
			for u in units:
				order_wave(u as Unit, &"workers", _fire_workers_pos())
			wave_units[id] = units
		&"W2":
			var units := spawn_wave_at(_rows(&"W2"), _seat_spawn(ICE_SEAT), ICE_SEAT)
			for u in units:
				order_wave(u as Unit, &"point", seat_xf(ALLY_SEAT, KEEP_POS))
			wave_units[id] = units
			say_l(9)
		&"W3":
			var su := spawn_wave_at(_rows(&"W3S"), _seat_spawn(SHADOW_SEAT), SHADOW_SEAT)
			for u in su:
				order_wave(u as Unit, &"point", HALL_POS)
			var iu := spawn_wave_at(_rows(&"W3I"), _seat_spawn(ICE_SEAT), ICE_SEAT)
			for u in iu:
				order_wave(u as Unit, &"point", SEALS[&"S"])
			su.append_array(iu)
			wave_units[id] = su
			fire_once(&"E10")
			say_l(15)


func _fire_workers_pos() -> Vector3:
	var n := node_of(PLAYER_SEAT, "a")
	return n.global_position if n else _alive_pos(ember_hall, KEEP_POS)


func _ice_pressure() -> void:
	if is_ending() or boss_phase >= 3 or boss_phase == 0:
		return
	after(ICE_PRESSURE_EVERY, _ice_pressure)
	var units := spawn_wave_at(_rows(&"ICE"), _seat_spawn(ICE_SEAT), ICE_SEAT)
	for u in units:
		order_wave(u as Unit, &"point", seat_xf(ALLY_SEAT, KEEP_POS))


func _refresh_wave_unit(u: Unit, mode: StringName, _hero_at: Vector3) -> bool:
	match mode:
		&"workers":
			if u.attack_target == null and not u.is_attack_moving():
				u.set_meta(META_MODE, &"point")
				u.command_attack_move(_alive_pos(ember_hall, KEEP_POS))
			return true
		&"cover":
			if u.attack_target == null and _flat(u.global_position, NORTH_RAMP) > 5.0 and not u.is_attack_moving():
				u.command_attack_move(NORTH_RAMP)
			return true
		&"tether":
			if u == shadow_hero and u.is_alive():
				var pct := u.hp / maxf(1.0, u.max_hp)
				var to := seat_xf(SHADOW_SEAT, RALLY) if pct < 0.35 else MALRIK_TETHER_SPOT
				if _flat(u.global_position, to) > 2.0 and (u.attack_target == null or pct < 0.35):
					u.command_move(to)
			return true
		&"withdraw":
			return true
	return false


## 8:00: the Roost opens (button + message), sec_dragon, Hush's raid (or L12b).
func _roost_open() -> void:
	if is_ending():
		return
	fire_once(&"E7")
	if hud:
		hud.show_message(HINT_ROOST, 12.0)
	set_objective(&"sec_dragon", "active")
	show_spotlight()
	if _flag(&"e2m4_hush_driven"):
		say_l(36)
		return
	say_l(12)
	if _hush_cast == null:
		_hush_cast = M00Cast.new()
		_hush_cast.setup(self, mission_difficulty)
		add_child(_hush_cast)
	var hp := _spawn(make_unit("mother_hush"), SHADOW_SEAT, NW_TUNNEL)
	mark_scripted(hp)
	_hush_cast.bind_hush(hp)
	hp.set_base_stat(&"max_hp", 1400.0)
	hp.hp = hp.max_hp
	order_wave(hp, &"workers", _fire_workers_pos())
	for u in spawn_wave_at(_rows(&"HUSH"), NW_TUNNEL, SHADOW_SEAT):
		order_wave(u as Unit, &"workers", _fire_workers_pos())


## M00Cast: where Hush runs.
func nearest_spawn(_at: Vector3) -> Vector3:
	return NW_TUNNEL


# ---------------------------------------------------------------- the Dragon Roost

func _build_panel() -> void:
	_panel = mission_button_panel("RoostPanel", [[Loc.t(BUTTON_ROOST), func() -> void:
		var r := raise_roost()
		if r != "" and hud:
			hud.show_message(r, 3.0)]])


## The mission button: "" or the refusal ("Available at 8:00", "Needs Ember Stables", "Already built", "Not enough
## crystals", "No free Cinder Hand", "No room for the Roost").
func raise_roost() -> String:
	if mission_time() < ROOST_AT:
		return REFUSE_EARLY
	if roost != null and is_instance_valid(roost) and roost.is_alive():
		return REFUSE_BUILT
	var stables := false
	for b in Building.for_team(PLAYER_SEAT):
		if b.is_alive() and b.is_constructed() and b.building_type and b.building_type.kind == &"stables":
			stables = true
	if not stables:
		return REFUSE_STABLES
	var eco := Economy.for_team(PLAYER_SEAT)
	if eco == null or eco.crystals < ROOST_COST:
		return REFUSE_CRYSTALS
	var workers := workers_of(PLAYER_SEAT)
	if workers.is_empty():
		return REFUSE_WORKER
	var spot := build_grid.find_spot(_roost_type, ROOST_SPOT, PLAYER_SEAT)
	if spot == Vector3.INF:
		return REFUSE_SPOT
	roost = build_grid.place(_roost_type, spot, PLAYER_SEAT, [workers[0]])
	return "" if roost != null else REFUSE_SPOT


func _on_dragon(u: Unit) -> void:
	if not is_instance_valid(u) or int(u.team) != PLAYER_SEAT:
		return
	dragons += 1
	u.add_to_group(&"titans")
	u.attack_landed.connect(_on_breath.bind(u))
	if fire_once(&"E8"):
		say_l(13)
		say_l(37)
		if objective_state("sec_dragon") == "active":
			set_objective(&"sec_dragon", "done")


## Breath: 11 to every other hostile unit within 3 m of the target (cavalry-mounts.md 5, a cone stand-in).
func _on_breath(target: Node3D, _amount: float, dragon: Unit) -> void:
	if target == null or not is_instance_valid(target):
		return
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u != target and u.is_alive() and Teams.is_hostile(int(u.team), PLAYER_SEAT) \
				and _flat(u.global_position, target.global_position) <= 3.0:
			u.take_damage(11.0, dragon)


# ---------------------------------------------------------------- defeat

func _on_keep_destroyed(_b: Building) -> void:
	if is_ending():
		return
	fire_once(&"E24")
	say_l(35)
	set_objective(&"obj_keep", "failed")
	lose(DEFEAT_DELAY)


func _on_player_hero_fell() -> void:
	fire_once(&"E22")
	say_l(34)
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
	_tick_seals(delta)
	_tick_wake(delta)
	_tick_boss(delta)
	_tick_door(delta)
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.5
		_tick_host(0.5)
		_tick_malrik()
		_tick_ysolde()
		if door and is_instance_valid(door) and not door.destroyed.is_connected(_on_door_destroyed):
			door.destroyed.connect(_on_door_destroyed)
		if seat_out(ALLY_SEAT) and fire_once(&"E20"):
			say_l(31)
		var t := "%s|%s|%s" % [objective_text(&"obj_seals"), objective_text(&"obj_door"), objective_text(&"obj_doorwarden")]
		if t != _last_obj_text:
			_last_obj_text = t
			objectives_changed.emit()
			if hud and mission_hud == null:
				hud.set_objective(_objective_text())
