class_name Mission03
extends MissionBase
## Campaign mission 3, "The Signet in the Sighing Wood" (docs/design/mission-03.md = source of truth; M3.S1-S3).
## Fire against Shadow in Ysolde's neutral wood: map "Sighing Wood" (the main.gd generator, seed 1303, not mirrored,
## 16 broadleaf clusters), the Oldroot at (0, 0) behind an 18-segment thorn ring, three NEUTRAL Root Hearts (RootHeart:
## 900 HP, regen, Shadow drains, credit by killing blow, an Ember Stake where the player burns one), their wood
## guardians (G1-G3 with Maelis and her wolves, Old Mossjaw from 6:00), the first tavern of the campaign (the Crooked
## Lantern, opens 0:30, first hire 0 crystals + 75 essence), the race for the Master's Signet (muster, march, carry
## at 1.6 m/s, drop on death), the two Warden Gates and their tides, events E1-E15 and the 21 lines.
## Built on MissionBase. Placeholder art in code (M3.V1 replaces it): the Oldroot, the thorn ring, hearts, stakes,
## gates, the Signet glow; the four cinematics are engine cards (mission 0's fallback-card pattern).

signal signet_taken(wizard: Wizard)

const MISSION_ID := &"m03"
const MISSION_TITLE := "The Signet in the Sighing Wood"
const MAP_SEED := 1303

const EMBER_HALL_POS := Vector3(-27.0, 0.0, 45.0)
const HEARTH_POS := Vector3(-50.0, 0.0, 46.0)
const GLOOM_HALL_POS := Vector3(27.0, 0.0, -45.0)
const NIGHT_SPIRE_POS := Vector3(37.0, 0.0, -29.0)
const HOVEL_POS := Vector3(50.0, 0.0, -46.0)
const DUSK_KEEP_POS := Vector3(43.0, 0.0, -43.0)
const DUSK_KEEP_HP := 2500.0
const SHADOW_RALLY := Vector3(30.0, 0.0, -30.0)
const FALLBACK_SPAWN := Vector3(54.0, 0.0, -54.0)
const ARMY_POS := Vector3(-32.0, 0.0, 32.0)
## id -> [position, crystals]
const M3_NODES := {
	&"m3_fire_a": [Vector3(-46.0, 0.0, 34.0), 1500],
	&"m3_fire_b": [Vector3(-34.0, 0.0, 46.0), 1500],
	&"m3_west": [Vector3(-50.0, 0.0, 8.0), 2000],
	&"m3_south": [Vector3(4.0, 0.0, 50.0), 1500],
	&"node_shadow_a": [Vector3(46.0, 0.0, -34.0), 1500],
	&"node_shadow_b": [Vector3(34.0, 0.0, -46.0), 1500],
}
const M3_FIRE_SUFFIXES := {&"a": &"m3_fire_a", &"b": &"m3_fire_b", &"mid": &"m3_south", &"rich": &"m3_west"}
const M3_SHADOW_SUFFIXES := {&"a": &"node_shadow_a", &"b": &"node_shadow_b"}
const WEST_HALL_SPOT := Vector3(-43.0, 0.0, 9.0)
const SOUTH_HALL_SPOT := Vector3(-3.0, 0.0, 51.0)
const TAVERN_POS := Vector3(-15.0, 0.0, -15.0)
const TAVERN_OPEN := 30.0
const PELL_POS := Vector3(-21.0, 0.0, -9.0)
const M3_CACHE_SPOTS: Array[Vector3] = [Vector3(-12.0, 0.0, 30.0), Vector3(26.0, 0.0, 8.0)]

## The Oldroot and the Signet.
const OLDROOT_POS := Vector3.ZERO
const OLDROOT_CLEARING := 12.0
const TRUNK_RADIUS := 1.6
const SIGNET_POS := Vector3(0.0, 1.6, 0.0)
const SIGNET_LOOK_OFFSET := Vector3(0.0, 0.5, 1.15)   ## The glow sits in the front of the split (seen from the camera).
## Claim radius at the tree: the spec's 2.2 m from (0, 0) is the navmesh edge itself (trunk 1.6 + agent 0.5 = 2.1),
## so the tree claim gets 0.4 m of slack; a dropped Signet uses the spec's 2.2 m.
const TREE_CLAIM := 2.6
const GROUND_CLAIM := 2.2
const THORN_RING := 7.0
const THORN_SIZE := Vector3(2.6, 1.6, 1.2)   ## long (tangent) x tall x deep (radial)
const THORN_STEP_DEG := 20

## Root Hearts: id -> [name, position]; the drain order (nearest the Shadow camp first) is HEART_ORDER.
const HEARTS := {
	&"rh1": ["Mossgate", Vector3(-44.0, 0.0, -18.0)],
	&"rh2": ["Hollowfen", Vector3(18.0, 0.0, 44.0)],
	&"rh3": ["Stagwatch", Vector3(44.0, 0.0, 14.0)],
}
const HEART_ORDER: Array[StringName] = [&"rh3", &"rh2", &"rh1"]
const HEART_CLEARING := 8.0
## Wood guardians (pacing 2026-10-04: the spec's G2 = 2 Bloomtenders + 4 Thornlings and G3 = 4 Thornlings (+ Maelis,
## wolves) fell in seconds to a scripted army; about x1.5, G1 unchanged so the start army still takes it whole).
const G2_ROWS := [["bloomtender", 3], ["thornling", 6], ["burr_slinger", 2]]
const G3_ROWS := [["thornling", 6], ["burr_slinger", 3]]
const BRAMBLE_SPIRE_POS := Vector3(22.0, 0.0, 40.0)
const BRAMBLE_SPIRE_HP := 540.0
const MOSSJAW_POS := Vector3(10.0, 0.0, 36.0)
const MOSSJAW_ROAM := 12.0
const GATES := {&"wg1": Vector3(-30.0, 0.0, -36.0), &"wg2": Vector3(32.0, 0.0, 32.0)}
const DRAIN_REACH := 3.2        ## A Thrall drains within this of the heart's centre (radius 1.4 + 1.8 m).
const DRAIN_RING := 2.4         ## Where Thralls stand.
const DRAIN_PER_THRALL := 4.0   ## HP/s.
const STAKE_HP := 400.0
const STAKE_SIGHT := 10.0
const E9_RADIUS := 18.0
const MALRIK_RESPAWN := 60.0
const MALRIK_LEASH_ARMY := 10.0
const CARRY_LEASH := 6.0
const HOME_RADIUS := 8.0
const DROP_DELAY := 3.0
const DROP_HOLD := 6.0
const TIDE_MAX_ALIVE := 8
const TIDE_COUNT := 3
const LATE_DRAIN_START := 660.0
const LATE_DRAIN_EVERY := 240.0
const DRAIN_TIMES: Array[float] = [180.0, 420.0, 660.0]
## Drain squads D1 / D2 / D3 and the late drains (pacing, 2026-10-04: the spec's 3 Thralls + 3 Shades die to G3 in
## 4 s and the wood guardians regenerate 1 % / s between squads, so an ignoring player never lost the race; D2 / D3
## and the late drains bring a real escort, see mission-03.md "Changes" / the build report).
const DRAIN_ROWS := [
	[["gloom_thrall", 3], ["shade", 3]],
	[["gloom_thrall", 3], ["shade", 10], ["nightbolt", 4], ["shadow_knight", 2]],
	[["gloom_thrall", 3], ["shade", 10], ["nightbolt", 4], ["shadow_knight", 2]],
]
const LATE_DRAIN_ROWS := [["gloom_thrall", 4], ["shade", 10], ["nightbolt", 4], ["shadow_knight", 2]]
const STAGE_BACK := 16.0       ## Thralls wait this far from their heart while its guardians live.
const GUARD_NEAR := 10.0
const W1_TIME := 270.0
const STAKE_RAID_DELAY := 30.0
const MOSSJAW_TIME := 360.0
const DEFEAT_DELAY := 3.0
const VICTORY_DELAY := 3.0
const LEVEL_CAP := 7
const MAX_TIER := 2
const FIREBALL_TRAVEL := 0.3
const NO_SAVE_ESSENCE := 400

## Difficulty tables [easy, normal, hard].
const COUNT_MULT: Array[float] = [0.6, 1.0, 1.4]
const START_CRYSTALS_BY_DIFF: Array[int] = [400, 300, 250]
const MUSTER: Array[float] = [90.0, 75.0, 60.0]
const CARRY_SPEED: Array[float] = [1.3, 1.6, 2.0]
## Pacing (2026-10-04): the spec's 1 400 / 1 800 / 2 200 fell in ~25 s each to a 25-unit army (the spec plans
## 6:30 of tide); x3.3 and a 3-Warden tide.
const GATE_HP: Array[float] = [4500.0, 6000.0, 7500.0]
const TIDE_EVERY: Array[float] = [30.0, 25.0, 20.0]
const MAELIS_LEVEL: Array[int] = [3, 3, 5]
const MOSSJAW_TYPE: Array[String] = ["grizzlemaw", "elder_grizzlemaw", "elder_grizzlemaw"]
const MALRIK_START_LEVEL: Array[int] = [4, 4, 5]
const MALRIK_RACE_LEVEL: Array[int] = [4, 5, 6]
const MALRIK_START_SPELLS := [
	[&"shadow_lance", &"shadow_lance", &"soul_siphon", &"umbral_shroud"],
	[&"shadow_lance", &"shadow_lance", &"soul_siphon", &"umbral_shroud"],
	[&"shadow_lance", &"shadow_lance", &"soul_siphon", &"umbral_shroud", &"soul_siphon"],
]
const MALRIK_RACE_SPELLS := [[], [&"umbral_shroud"], [&"umbral_shroud"]]

## Tiers (mission-03.md "Tiers"): the mission 2 Hall copy.
const HALL_UNITS: Array[StringName] = [&"flame_guard", &"ember_archer", &"blaze_rider", &"ash_hurler"]
const TIER2_HALL_UNITS: Array[StringName] = [&"pyre_adept", &"cinder_arbalest"]
const HINT_STRONGHOLD := "Your Keep can become a Stronghold: select the Keep and press %s (%d crystals). It opens %s."
const HINT_STRONGHOLD_SECONDS := 12.0

const SPEAKER_COLORS := {
	&"vessa": Color(1.0, 0.45, 0.1),
	&"malrik": Color(0.7, 0.3, 1.0),
	&"narrator": Color(0.9, 0.85, 0.7),
	&"pell": Color(0.85, 0.75, 0.5),
	&"bettany": Color(0.80, 0.65, 0.45),
	&"ysolde": Color(0.55, 0.90, 0.35),
	&"maelis": Color(0.60, 0.85, 0.50),
	&"whisper": Color(1.0, 0.80, 0.25),
	&"obren": Color(1.0, 0.80, 0.25),
	&"master": Color(0.95, 0.95, 0.85),
}
const SPEAKER_NAMES := {&"vessa": "Vessa", &"malrik": "Malrik", &"narrator": "Narrator", &"pell": "Pell",
		&"bettany": "Bettany Crook", &"ysolde": "Ysolde", &"maelis": "Maelis", &"whisper": "???", &"obren": "Obren",
		&"master": "The Master"}
## The 21 lines (L9 unused); LINE_IDS[i] is the spec id of DIALOGUE[i] (say_id(&"L20") says it once).
const LINE_IDS: Array[StringName] = [&"L1", &"L2", &"L3", &"L20", &"L4", &"L5", &"L6", &"L7", &"L21", &"L8", &"L10",
		&"L11", &"L12", &"L13", &"L14", &"L19", &"L22", &"L15", &"L16", &"L17", &"L18"]
const DIALOGUE := [
	[&"narrator", "The Sighing Wood has kept out of every quarrel for a hundred years. Today two armies walked in."],
	[&"vessa", "Malrik's already here. Of course he is. Then I'll borrow a forest."],
	[&"whisper", "The third one sleeps in the old tree. Wake it before he does."],
	[&"pell", "A war! Terrible. Wonderful for business. Terrible."],
	[&"bettany", "The Crooked Lantern is open! Sellswords, cheap ale, no questions. First hire's on the house."],
	[&"vessa", "Sellswords who won't take orders. Perfect. I'll pay them to want what I want."],
	[&"bettany", "Mind the flags, Firelady. Coin on a flag is the only order that lot understands."],
	[&"vessa", "A heart made of roots, pumping green. That's the most Nature thing I have ever seen."],
	[&"vessa", "His Thralls are draining the hearts. If he opens that tree first, I lose it."],
	[&"ysolde", "Fire and Shadow, burning my wood for a trinket. I will remember you both."],
	[&"narrator", "Old Mossjaw wakes in the Hollowfen, and he is hungry."],
	[&"vessa", "Somebody tell the sellswords their bounty's ready. And tell the bear I'm sorry."],
	[&"maelis", "Turn back, fire-child. The wolves already have your scent."],
	[&"ysolde", "Stop, both of you! You don't know what you're opening!"],
	[&"vessa", "A tree. I'm opening a tree. Before HE does."],
	[&"malrik", "Mine. Thank you for the escort, little ember."],
	[&"vessa", "Dropped something, Bishop? Finders keepers."],
	[&"obren", "Three. Thank you, little ember. I'll take it from here."],
	[&"malrik", "Rubble with eyes. Your mess, Vessa. I'll be at my camp, enjoying the view."],
	[&"vessa", "One gate down. Stone breaks. Good to know."],
	[&"vessa", "Tell Malrik... he still dresses like a funeral."],
]
## Cutscene lines (story-episode-1.md 7.2): [cutscene id, speaker, text, seconds].
const CINE_LINES := [
	[&"m3_plea", &"ysolde", "Vessa. Stop. Please.", 4.0],
	[&"m3_plea", &"vessa", "NOW you want to talk? Your wood tried to eat me.", 4.0],
	[&"m3_plea", &"ysolde", "My wood tries to eat everyone. It's very fair.", 4.0],
	[&"m3_plea", &"ysolde", "Those relics aren't a prize. They're a lock. Put three together near the Hollow and the door opens.", 8.0],
	[&"m3_plea", &"vessa", "Everyone says that about the things I want. And if I leave it, Malrik takes it.", 7.0],
	[&"m3_memory", &"ysolde", "The Master had a first apprentice. Before any of us. Obren. The Mason.", 4.0],
	[&"m3_memory", &"ysolde", "He wanted the Master's seat. So the Master sealed him under the earth, with the regalia as the lock.", 3.5],
	[&"m3_memory", &"obren", "And you picked them up. All three. Thank you, little ember.", 2.5],
	[&"m3_parting", &"ysolde", "I warned you. You didn't listen. Neither did he.", 5.0],
	[&"m3_parting", &"vessa", "Then help me stop it. Please.", 3.5],
	[&"m3_parting", &"ysolde", "Nature doesn't take sides, Vessa.", 4.0],
	[&"m3_parting", &"ysolde", "But when your war comes for my wood, and it will, remember that I warned you both.", 8.0],
	[&"m3_parting", &"narrator", "Fire at war with Shadow. Ice and Nature watching. And under the world, something counting.", 8.0],
]
const BRIEFING_PARAGRAPHS: Array[String] = [
	"Two relics answer to fire now, and both hum toward the same place: the Sighing Wood, Ysolde's border forest, which has kept out of every quarrel for a hundred years.",
	"The Master's third relic, the Master's Signet, sleeps inside the Oldroot, an oak older than the kingdoms. Three Root Hearts feed the thorns that guard it. Malrik's scouts are already in the wood, and his Thralls are draining them.",
	"Vessa cannot burn a whole forest and win. So she will do what Malrik never would: pay people. The Crooked Lantern is full of sellswords who take no orders, only coin.",
]
const BRIEFING_RACE_LINE := "Malrik is racing you. If he carries the Signet home, the mission is lost."
const HINT_START := "Hire champions at the Crooked Lantern. Find the Root Hearts in the fog before Malrik does."
const HINT_HIRE := "%s: hire a champion. Champions choose their own jobs; bounty flags (%s) pay them to do yours."
const HINT_EXPLORE := "%s, then click the fog: an Explore flag. Explorers find the Root Hearts."
const HINT_HUNT := "Put a Hunt bounty on the drain squad (%s, then click a Thrall)."
const HINT_GUARD := "Guard your Ember Stake (%s, then click it): it shows you who is coming."
const HINT_E11 := "The Wardens come for the Signet. Break both gates."
const MSG_TAVERN := "The Crooked Lantern opens its doors"
const MSG_DRAINED := "Malrik's Thralls drained the Root Heart of %s"
const MSG_MARCH := "Malrik marches on the Oldroot"
const MSG_MALRIK_FELL := "Malrik has fallen back into the shadows"
const MSG_MOSSJAW := "Old Mossjaw wakes"

## Test hook: the campaign flags to use instead of the save's ({} = read the save).
var flag_override: Dictionary = {}

var ember_hall: TrainingBuilding          ## Read only.
var gloom_hall: Building                  ## Read only.
var hearts := {}                          ## Read only: &"rh1".."rh3" -> RootHeart.
var gates := {}                           ## Read only: &"wg1" / &"wg2" -> WardenGate.
var stakes: Array = []                    ## Read only: Ember Stakes planted (living or not).
var thorns: Array = []                    ## Read only: the 18 thorn segments (StaticBody3D) until the wither.
var guard_groups := {}                    ## Read only: &"G1".."G3" -> Array of units.
var maelis: Unit                          ## Read only (Helper, or null on the fallback).
var mossjaw: Unit                         ## Read only.
var bramble_spire: Building               ## Read only.
var pell: RuinPeddler                     ## Read only: Pell when m1_peddler_freed, else null.
var pell_cache: LostCache                 ## Read only: the cache at Pell's spot when he is not here.
var squads: Array = []                    ## Read only: drain squads {id, thralls, shades, heart}.
var race_army: Array = []                 ## Read only.
var tide_units := {}                      ## Read only: gate id -> Array of its Wardens.
var waves_fired: Array[StringName] = []   ## Read only.
var said_ids: Array[StringName] = []      ## Read only.
var hearts_down := 0                      ## Read only.
var heart_credit := {}                    ## Read only: heart id -> team of the killing blow.
var race_phase: StringName = &""          ## Read only: "", &"muster", &"march", &"over".
var signet_state: StringName = &"sealed"  ## Read only: sealed, tree, malrik, dropping, ground, vessa.
var signet_ground := Vector3.INF          ## Read only: where a dropped Signet lies.
var barrier_down := false                 ## Read only: the E10 end state ran.
var signet_taken_by_vessa := false        ## Read only.
var gates_down := 0                       ## Read only.
var stake_fell := false                   ## Read only.
var peddler_freed := false                ## Read only.
var no_save_fallback := false             ## Read only: no mission 2 victory in the save (debug start).
var muster_ends_at := INF                 ## Read only: mission time the march starts.
var stronghold_hint_shown := false        ## Read only.

var _flags_read := false
var _hall_type: BuildingType
var _stake_type: BuildingType
var _tide_type: UnitType
var _said: Dictionary = {}
var _tick := 0.0
var _late_drains := 0
var _signet_mesh: Node3D
var _oldroot: Node3D
var _ysolde: Node3D
var _last_obj_text := ""
var _mossjaw_roam_left := 0.0
var _malrik_base_speed := 0.0
var _card_actors := {}
var _homebound: Array = []   # Shadow units walking back to the rally after E11 (guards on arrival)


# ---------------------------------------------------------------- setup

func _init() -> void:
	super()
	dialogue_lines = DIALOGUE
	speaker_colors = SPEAKER_COLORS.duplicate()
	speaker_names = SPEAKER_NAMES.duplicate()
	briefing_paragraphs = BRIEFING_PARAGRAPHS.duplicate()
	tavern_enabled = true
	define_objectives([[&"obj_hearts", "primary"], [&"obj_signet", "primary"], [&"obj_gates", "primary"],
			[&"obj_vessa", "primary"], [&"sec_champion", "secondary"], [&"sec_mossjaw", "secondary"],
			[&"sec_stakes", "secondary"]])


func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	c.mission_id = MISSION_ID
	c.title = MISSION_TITLE
	c.count_mult = COUNT_MULT.duplicate()
	c.defeat_on_keep_lost = true
	c.keep_lost_message = "The Fire keep has fallen"
	c.tiers_enabled = true
	c.max_tier = MAX_TIER
	c.bots_upgrade = false
	c.casters_enabled = true
	c.start_crystals = START_CRYSTALS_BY_DIFF.duplicate()
	c.start_level = 3
	c.start_spell_points = 2
	c.level_cap = LEVEL_CAP
	c.instant_loss_on_wizard_death = true
	c.defeat_delay = DEFEAT_DELAY
	c.bot_profile_id = bot_profile()
	c.bot_team = Unit.Team.ENEMY
	c.victory_banner = "VICTORY\nThe Master's Signet is yours"
	c.defeat_banner = "DEFEAT"
	c.rewards = {"artifact": "masters_signet", "flags": {"m3_mossjaw_slain": "sec_mossjaw",
			"m3_stakes_held": "sec_stakes", "m3_hired": "sec_champion"},
			"bonus_essence": {"sec_stakes": 300, "sec_mossjaw": 150}, "next": &"m04"}
	return c


## AIProfile.mission_03() when the ai-coder added it (M3.A1), else mission 1's (the same Shadow bot: never attacks,
## 4 workers, 8 soldiers at the rally, no towers past S1, champion_max 0 = never hires).
static func bot_profile() -> StringName:
	var script := load("res://scripts/ai/ai_profile.gd") as Script
	if script:
		for m in script.get_script_method_list():
			if StringName(m["name"]) == &"mission_03":
				return &"mission_03"
	return &"mission_01"


func _ready() -> void:
	_hall_type = _make_hall_type()
	_stake_type = _make_stake_type()
	_tide_type = _make_tide_type()
	get_tree().node_added.connect(_on_m3_node_added)
	super()


func _exit_tree() -> void:
	if get_tree().node_added.is_connected(_on_m3_node_added):
		get_tree().node_added.disconnect(_on_m3_node_added)


func _lighting_preset() -> StringName:
	return &"warm"   # M3.V1: the forest preset (green-gold sun) when the lighting rig has it


func _lane_end() -> Vector3:
	return SHADOW_START


func _title_line() -> String:
	return "Mission 3: %s" % MISSION_TITLE


func _ground_spots() -> Array[Vector4]:
	var out: Array[Vector4] = [Vector4(PLAYER_START.x, PLAYER_START.z, 13.0, 0.0),
			Vector4(SHADOW_START.x, SHADOW_START.z, 13.0, 0.0), Vector4(0.0, 0.0, 10.0, 1.0),
			Vector4(TAVERN_POS.x, TAVERN_POS.z, 5.0, 0.0), Vector4(PELL_POS.x, PELL_POS.z, 4.0, 0.0)]
	for id: StringName in HEARTS:
		var p: Vector3 = HEARTS[id][1]
		out.append(Vector4(p.x, p.z, 6.0, 0.0))
	return out


func node_of(team: int, suffix: String) -> CrystalNode:
	var table: Dictionary = M3_SHADOW_SUFFIXES if team == Unit.Team.ENEMY else M3_FIRE_SUFFIXES
	var id: StringName = table.get(StringName(suffix), &"")
	if id == &"":
		return null
	var v: Variant = crystal_nodes.get(id)
	if v == null or not is_instance_valid(v):
		crystal_nodes.erase(id)
		return null
	var n := v as CrystalNode
	return n if n != null and not n.is_depleted() else null


func natural_hall_spot(team: int) -> Vector3:
	return SOUTH_HALL_SPOT if team == Unit.Team.PLAYER else super(team)


func rich_hall_spot(team: int) -> Vector3:
	return WEST_HALL_SPOT if team == Unit.Team.PLAYER else super(team)


## Malrik comes back at the Dusk Keep, or at the fallback corner once it is gone.
func respawn_point(team: int) -> Vector3:
	if team == Unit.Team.ENEMY:
		var k := keep_of(team)
		return k.spawn_point() if k else FALLBACK_SPAWN
	return super(team)


# ---------------------------------------------------------------- the map

func _build_map() -> void:
	_read_flags()
	var rng := RandomNumberGenerator.new()
	rng.seed = MAP_SEED
	var clearings := map_clearings()
	var keep_out := func(p: Vector3) -> bool:
		return _in_clearing(p, clearings) or _in_path_lane(p)

	for cluster in 16:   # broadleaf only (no fir / pine)
		var center := Vector3(rng.randf_range(-52, 52), 0.0, rng.randf_range(-52, 52))
		for i in rng.randi_range(6, 10):
			var p := center + Vector3(rng.randf_range(-6, 6), 0.0, rng.randf_range(-6, 6))
			var s := rng.randf_range(0.9, 1.5)
			if absf(p.x) > 57.0 or absf(p.z) > 57.0 or keep_out.call(p):
				continue
			_add_wood_tree(p, s)
	for i in 18:
		var p := Vector3(rng.randf_range(-54, 54), 0.0, rng.randf_range(-54, 54))
		var s := rng.randf_range(0.8, 2.0)
		var rot := rng.randf() * TAU
		if keep_out.call(p):
			continue
		_add_rock(p, s, rot)

	_add_oldroot()
	for k in 360 / THORN_STEP_DEG:
		_add_thorn(float(k * THORN_STEP_DEG))

	# Bases (finished buildings, navmesh obstacles before the bake).
	keep = build_grid.spawn_complete(BuildingType.find("fire_keep"), PLAYER_START + KEEP_OFFSET,
			Unit.Team.PLAYER) as Keep
	ember_hall = build_grid.spawn_complete(BuildingType.find("fire_barracks"), EMBER_HALL_POS,
			Unit.Team.PLAYER) as TrainingBuilding
	build_grid.spawn_complete(BuildingType.find("fire_hearth"), HEARTH_POS, Unit.Team.PLAYER)
	shadow_keep = build_grid.spawn_complete(BuildingType.find("shadow_keep"), SHADOW_START - KEEP_OFFSET,
			Unit.Team.ENEMY) as Keep
	shadow_keep.max_hp = DUSK_KEEP_HP
	shadow_keep.hp = DUSK_KEEP_HP
	gloom_hall = build_grid.spawn_complete(BuildingType.find("shadow_barracks"), GLOOM_HALL_POS, Unit.Team.ENEMY)
	build_grid.spawn_complete(BuildingType.find("shadow_tower"), NIGHT_SPIRE_POS, Unit.Team.ENEMY)
	build_grid.spawn_complete(BuildingType.find("shadow_hovel"), HOVEL_POS, Unit.Team.ENEMY)
	for id: StringName in M3_NODES:
		_add_crystal_node(id, M3_NODES[id][0], int(M3_NODES[id][1]))

	# The wood: hearts, the Bramble Spire, the gates (obstacles before the bake).
	for id: StringName in HEARTS:
		var h := RootHeart.new()
		h.heart_id = id
		h.display_name = String(HEARTS[id][0])
		h.name = "RootHeart%s" % h.display_name
		h.position = HEARTS[id][1]
		nav_region.add_child(h)
		h.heart_down.connect(_on_heart_down)
		hearts[id] = h
	var nt := BuildingType.find("nature_tower")
	if nt:
		bramble_spire = build_grid.spawn_complete(nt, BRAMBLE_SPIRE_POS, Unit.Team.NEUTRAL)
		bramble_spire.max_hp = BRAMBLE_SPIRE_HP
		bramble_spire.hp = BRAMBLE_SPIRE_HP
		mark_scripted(bramble_spire)
	var diff := clampi(mission_difficulty, 0, 2)
	for id: StringName in GATES:
		var g := WardenGate.new()
		g.gate_id = id
		g.name = "WardenGate%s" % String(id).to_upper()
		g.face_toward = OLDROOT_POS
		g.position = GATES[id]
		g.setup(GATE_HP[diff], TIDE_EVERY[diff])
		g.spawner = _spawn_tide
		nav_region.add_child(g)
		g.gate_down.connect(_on_gate_down)
		gates[id] = g
		tide_units[id] = []

	# The Crooked Lantern (the only tavern) and Pell or his cache.
	var tavern_spots: Array[Vector3] = [TAVERN_POS]
	_add_taverns(tavern_spots)
	for t in taverns:
		t.open_time = TAVERN_OPEN
		t.match_time_source = mission_time
	if peddler_freed:
		pell = RuinPeddler.new()
		pell.name = "Pell"
		nav_region.add_child(pell)
		pell.display_name = "Pell, Ruin Peddler"
		pell.position = PELL_POS
		pell.rotation.y = atan2(-PELL_POS.x, -PELL_POS.z)
		peddlers.append(pell)


## Every clearing of the generator (checked by test_m3_map): [position, radius].
func map_clearings() -> Array:
	var out := [[PLAYER_START, 18.0], [SHADOW_START, 18.0], [EMBER_HALL_POS, 4.0], [HEARTH_POS, 3.0],
			[GLOOM_HALL_POS, 4.0], [NIGHT_SPIRE_POS, 3.0], [HOVEL_POS, 4.0], [WEST_HALL_SPOT, 4.0],
			[SOUTH_HALL_SPOT, 4.0], [M3_NODES[&"m3_west"][0], 7.0], [M3_NODES[&"m3_south"][0], 7.0],
			[TAVERN_POS, 6.0], [PELL_POS, 6.0], [OLDROOT_POS, OLDROOT_CLEARING], [MOSSJAW_POS, 6.0],
			[FALLBACK_SPAWN, 4.0]]
	for id: StringName in HEARTS:
		out.append([HEARTS[id][1], HEART_CLEARING])
	for id: StringName in GATES:
		out.append([GATES[id], 6.0])
	for p: Vector3 in M3_CACHE_SPOTS:
		out.append([p, CACHE_CLEARING])
	return out


## The campaign flags this run uses (flag_override first; no m02 victory in the save = all false).
func _read_flags() -> void:
	if _flags_read:
		return
	_flags_read = true
	var flags := {}
	if not flag_override.is_empty():
		flags = flag_override
	else:
		var cs := CampaignState.open(campaign_save_path)
		no_save_fallback = not cs.is_completed(&"m02")
		if not no_save_fallback:
			flags = cs.flags
	peddler_freed = bool(flags.get("m1_peddler_freed", false))


func _add_wood_tree(p: Vector3, s: float) -> void:
	if env_props == null:
		_add_tree(p, s)
		return
	var shape := CylinderShape3D.new()
	shape.radius = 0.45 * s
	shape.height = 2.0
	_static_obstacle(p, shape, 1.0)
	env_props.add_tree_kind("tree_broadleaf", p, s)


## The Oldroot: trunk collider r 1.6 (the only collider), a split trunk, roots and a wide canopy (placeholder).
func _add_oldroot() -> void:
	var shape := CylinderShape3D.new()
	shape.radius = TRUNK_RADIUS
	shape.height = 6.0
	var body := _static_obstacle(OLDROOT_POS, shape, 3.0)
	body.name = "Oldroot"
	body.add_to_group(&"navigation_geometry")
	_oldroot = body
	if _SIM.enabled:
		return
	var bark := Color(0.30, 0.22, 0.15)
	for side in [-1.0, 1.0]:   # the split trunk: two halves leaning apart
		var half := CylinderMesh.new()
		half.top_radius = 0.9
		half.bottom_radius = 1.25
		half.height = 9.0
		half.radial_segments = 9
		var mi := _mesh(body, half, bark, 4.5)
		mi.position.x = side * 0.75
		mi.rotation.z = -side * 0.08
	for i in 7:   # great roots
		var root := CylinderMesh.new()
		root.top_radius = 0.15
		root.bottom_radius = 0.55
		root.height = 4.0
		root.radial_segments = 6
		var a := float(i) * TAU / 7.0 + 0.3
		var mi := _mesh(body, root, bark.darkened(0.1), 0.6)
		mi.position = Vector3(cos(a) * 2.4, 0.5, sin(a) * 2.4)
		mi.rotation = Vector3(0.0, -a, 0.0)
		mi.rotate_object_local(Vector3.FORWARD, 1.2)
	# A high, broken canopy (small crowns) so the RTS camera still sees the clearing, the thorns and the Signet.
	var leaf := Color(0.26, 0.42, 0.18)
	for c: Vector3 in [Vector3(0.0, 11.5, -1.5), Vector3(3.2, 10.6, -0.5), Vector3(-3.0, 10.8, -1.8),
			Vector3(1.0, 10.2, -4.2), Vector3(-2.6, 9.8, 1.2)]:
		var crown := SphereMesh.new()
		crown.radius = 2.4
		crown.height = 2.8
		var mi := _mesh(body, crown, leaf, 0.0)
		mi.position = c
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	# The Signet: a white-gold glow inside the split, shown at E10.
	var sig := SphereMesh.new()
	sig.radius = 0.35
	sig.height = 0.7
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(1.0, 0.92, 0.6)
	smat.emission_enabled = true
	smat.emission = Color(1.0, 0.85, 0.45)
	smat.emission_energy_multiplier = 4.0
	var smi := MeshInstance3D.new()
	smi.name = "Signet"
	smi.mesh = sig
	smi.material_override = smat
	add_child(smi)
	smi.position = SIGNET_POS + SIGNET_LOOK_OFFSET
	smi.visible = false
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.85, 0.5)
	light.light_energy = 1.5
	light.omni_range = 6.0
	smi.add_child(light)
	_signet_mesh = smi


## One thorn segment at `deg` on the ring r 7, tangent to it (static, layer 1, "navigation_geometry").
func _add_thorn(deg: float) -> void:
	var a := deg_to_rad(deg)
	var shape := BoxShape3D.new()
	shape.size = THORN_SIZE
	var body := _static_obstacle(Vector3(cos(a) * THORN_RING, 0.0, sin(a) * THORN_RING), shape, THORN_SIZE.y * 0.5)
	body.name = "Thorn%d" % int(deg)
	body.rotation.y = -(a + PI * 0.5)   # local x along the tangent
	body.add_to_group(&"navigation_geometry")
	body.add_to_group(&"thorn_barrier")
	thorns.append(body)
	if _SIM.enabled:
		return
	var look := Node3D.new()
	look.name = "Look"
	body.add_child(look)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.30, 0.12)
	mat.roughness = 0.9
	for i in 5:   # bramble spikes
		var spike := CylinderMesh.new()
		spike.top_radius = 0.0
		spike.bottom_radius = 0.35
		spike.height = THORN_SIZE.y * randf_range(1.0, 1.5)
		spike.radial_segments = 5
		var mi := MeshInstance3D.new()
		mi.mesh = spike
		mi.material_override = mat
		mi.position = Vector3(-1.1 + i * 0.55, spike.height * 0.5, randf_range(-0.3, 0.3))
		mi.rotation = Vector3(randf_range(-0.35, 0.35), 0.0, randf_range(-0.35, 0.35))
		look.add_child(mi)
	var hedge := BoxMesh.new()
	hedge.size = Vector3(THORN_SIZE.x, THORN_SIZE.y * 0.6, THORN_SIZE.z)
	var hmi := MeshInstance3D.new()
	hmi.mesh = hedge
	hmi.material_override = mat
	hmi.position.y = THORN_SIZE.y * 0.3
	look.add_child(hmi)


## The thorns lose a third of their height per fallen heart (visual only).
func _shrink_thorns() -> void:
	var f := clampf(1.0 - float(hearts_down) / 3.0, 0.15, 1.0)
	for t: Variant in thorns:
		if not is_instance_valid(t):
			continue
		var look := (t as Node3D).get_node_or_null(^"Look") as Node3D
		if look:
			look.create_tween().tween_property(look, "scale:y", f, 1.0)


## E10: the thorns sink (5 s visual) and their colliders go now; the navmesh rebakes.
func wither_barrier() -> void:
	for t: Variant in thorns:
		if not is_instance_valid(t):
			continue
		var body := t as StaticBody3D
		body.collision_layer = 0
		body.remove_from_group(&"navigation_geometry")
		for c in body.get_children():
			if c is CollisionShape3D:
				(c as CollisionShape3D).disabled = true
		var look := body.get_node_or_null(^"Look") as Node3D
		if look and is_inside_tree():
			var tw := look.create_tween()
			tw.tween_property(look, "position:y", -THORN_SIZE.y * 1.6, 5.0)
			tw.tween_callback(body.queue_free)
		else:
			body.queue_free()
	thorns.clear()
	build_grid.request_rebake()


# ---------------------------------------------------------------- start state

func _on_navigation_ready() -> void:
	fog.reveal(Unit.Team.ENEMY, SHADOW_START, FogOfWar.START_REVEAL)
	var diff := clampi(mission_difficulty, 0, 2)
	_setup_champions()   # the guilds first: apply_to_start may add the companion
	var guild := ChampionGuild.for_team(Unit.Team.PLAYER)
	if guild:
		guild.first_hire_crystals = 0

	# --- Fire (player): Vessa, then the campaign save, then the branch content.
	hero = _make_wizard(Unit.Team.PLAYER)
	_spawn(hero, Unit.Team.PLAYER, PLAYER_START)
	_claim_wizard(hero, Unit.Team.PLAYER)
	ItemDrops.ensure_inventory(hero)
	_apply_campaign_start()
	for i in 5:
		var cinder := _spawn(make_unit("cinder_hand"), Unit.Team.PLAYER,
				PLAYER_START + Vector3(-4.0 + i * 1.2, 0.0, 4.0 - i * 1.2))
		cinder.call(&"command_gather", crystal_nodes[&"m3_fire_a" if i < 3 else &"m3_fire_b"])
	var soldiers: Array[String] = ["flame_guard", "flame_guard", "flame_guard", "flame_guard", "ember_archer",
			"ember_archer", "blaze_rider", "blaze_rider", "ash_hurler", "ash_hurler"]
	for i in soldiers.size():
		_spawn(make_unit(soldiers[i]), Unit.Team.PLAYER,
				ARMY_POS + Vector3(-3.0 + (i % 5) * 1.5, 0.0, -1.0 + (i / 5) * 1.8))

	# --- Malrik's forward camp (the bot's base)
	shadow_hero = _make_wizard(Unit.Team.ENEMY)
	_spawn(shadow_hero, Unit.Team.ENEMY, SHADOW_RALLY)
	_claim_wizard(shadow_hero, Unit.Team.ENEMY)
	raise_wizard(shadow_hero, MALRIK_START_LEVEL[diff], MALRIK_START_SPELLS[diff])
	ItemDrops.ensure_inventory(shadow_hero)
	shadow_hero.died.connect(_on_malrik_died)
	wizard_respawned.connect(_on_m3_wizard_respawned)
	for i in 4:
		var thrall := _spawn(make_unit("gloom_thrall"), Unit.Team.ENEMY,
				SHADOW_START + Vector3(4.0 - i * 1.2, 0.0, -4.0 + i * 1.2))
		thrall.call(&"command_gather", crystal_nodes[&"node_shadow_a" if i < 2 else &"node_shadow_b"])
	for i in 8:
		var a := float(i) * TAU / 8.0
		_spawn(make_unit("shade" if i < 6 else "nightbolt"), Unit.Team.ENEMY,
				SHADOW_RALLY + Vector3(cos(a) * 2.5, 0.0, sin(a) * 2.5))

	_spawn_guards(diff)
	_spawn_caches()
	var caster := hero.get_node_or_null(^"SpellCaster")
	if caster and caster.has_signal(&"spell_effect"):
		caster.connect(&"spell_effect", _on_hero_spell_effect)
	_add_events()
	begin_mission([&"obj_hearts", &"obj_vessa", &"sec_champion"])


## CampaignState.apply_to_start (items, carried essence, companion, flags meta); with no mission 2 victory in the save
## (menu debug, tests): the Ember Crown and the Stillwater Orb equipped, empty slots, essence 150 + 400, flags false.
func _apply_campaign_start() -> void:
	_read_flags()
	if no_save_fallback or not flag_override.is_empty():
		set_meta(&"campaign_flags", {"m1_peddler_freed": peddler_freed})
		force_artifacts(hero, ["ember_crown", "stillwater_orb"])
		if no_save_fallback:
			var bank := EssenceBank.for_team(Unit.Team.PLAYER)
			if bank:
				bank.add(NO_SAVE_ESSENCE)
		return
	CampaignState.open(campaign_save_path).apply_to_start(self)


func _spawn_guards(diff: int) -> void:
	var p1: Vector3 = HEARTS[&"rh1"][1]
	var p2: Vector3 = HEARTS[&"rh2"][1]
	var p3: Vector3 = HEARTS[&"rh3"][1]
	guard_groups[&"G1"] = spawn_group([["thornling", 3], ["burr_slinger", 2]], p1, 3.0, Unit.Team.NEUTRAL, true, true)
	guard_groups[&"G2"] = spawn_group(G2_ROWS, p2, 3.0, Unit.Team.NEUTRAL, true, true)
	var g3 := spawn_group(G3_ROWS, p3, 3.0, Unit.Team.NEUTRAL, true, true)
	maelis = _spawn_maelis(MAELIS_LEVEL[diff], p3 + Vector3(2.5, 0.0, 0.0))
	if maelis:
		g3.append(maelis)
		for i in 2:
			var wolf := _spawn(make_unit("spirit_wolf"), Unit.Team.NEUTRAL, p3 + Vector3(-2.0, 0.0, -2.0 + i * 4.0))
			if wolf:
				wolf.set_lifetime(0.0)   # permanent, scripted
				mark_scripted(wolf)
				wolf.set_meta(META_HOME, wolf.global_position)
				_guards.append(wolf)
				g3.append(wolf)
	else:   # fallback (13c / TH missing): 2 Bramblehorns + 1 Bloomtender
		g3.append_array(spawn_group([["bramblehorn", 2], ["bloomtender", 1]], p3, 1.5, Unit.Team.NEUTRAL, true, true))
	guard_groups[&"G3"] = g3


## Maelis Oakenhollow on team NEUTRAL (a Helper with no bond), holding RH3 as a guard; null when the kit is missing.
func _spawn_maelis(level: int, at: Vector3) -> Unit:
	var ht := HelperType.find(&"helper_maelis")
	if ht == null:
		return null
	var m := Helper.new()
	m.apply_helper_type(ht, level)
	m.name = "Maelis"
	_spawn(m, Unit.Team.NEUTRAL, at)
	m.set_level(level)
	m.set_stance(&"home")
	mark_scripted(m)
	m.set_meta(META_HOME, at)
	_guards.append(m)
	return m


func _spawn_caches() -> void:
	for i in M3_CACHE_SPOTS.size():
		var cache := LostCache.new()
		cache.name = "LostCache%d" % i
		cache.rng.seed = MAP_SEED + i
		cache.match_time_source = match_time
		add_child(cache)
		cache.global_position = M3_CACHE_SPOTS[i]
		cache.opened.connect(_on_cache_opened)
		caches.append(cache)
	if pell == null:   # Pell not freed in mission 1: a Lost Cache at his spot, openable at once
		pell_cache = LostCache.new()
		pell_cache.name = "PellsCache"
		pell_cache.first_delay = 0.0
		pell_cache.rng.seed = MAP_SEED + 7
		pell_cache.match_time_source = match_time
		add_child(pell_cache)
		pell_cache.global_position = PELL_POS
		pell_cache.opened.connect(_on_cache_opened)
		caches.append(pell_cache)


func _make_hall_type() -> BuildingType:
	var base := BuildingType.find("fire_barracks")
	if base == null:
		return null
	var t := base.duplicate() as BuildingType
	var trains: Array[UnitType] = []
	for id in HALL_UNITS:   # Z X C V
		var ut := UnitType.find(String(id))
		if ut:
			trains.append(ut)
	if tiers_enabled and TierSystem.ENABLED:   # B N, greyed "Requires Stronghold" until then
		for id in TIER2_HALL_UNITS:
			var ut := UnitType.find(String(id))
			if ut:
				trains.append(ut)
	t.trains = trains
	return t


## The Ember Stake (mission-03.md): a pre-built PLAYER building, 400 HP, 1 x 1, sight 10, never counts for defeat.
func _make_stake_type() -> BuildingType:
	var t := BuildingType.new()
	t.id = &"ember_stake"
	t.display_name = "Ember Stake"
	t.faction = &"fire"
	t.kind = &"stake"
	t.max_hp = STAKE_HP
	t.footprint = Vector2i(1, 1)
	t.height = 2.6
	t.sight_radius = STAKE_SIGHT
	t.counts_for_defeat = false
	t.color = Color(1.0, 0.45, 0.1)
	t.body_color = Color(0.18, 0.12, 0.08)
	return t


## The tide's Ruin Warden: the normal type with `neutral_leash` off (they roam after Vessa).
func _make_tide_type() -> UnitType:
	var base := UnitType.find("ruin_warden")
	if base == null:
		return null
	var t := base.duplicate() as UnitType
	t.neutral_leash = false
	return t


func _on_m3_node_added(node: Node) -> void:
	var b := node as TrainingBuilding
	if b != null and _hall_type != null and b.building_type != null and b.building_type != _hall_type \
			and b.building_type.id == &"fire_barracks":
		b.building_type = _hall_type


# ---------------------------------------------------------------- briefing, objectives

func briefing() -> Dictionary:
	return {
		"title": _title_line(),
		"paragraphs": BRIEFING_PARAGRAPHS.duplicate(),
		"objectives": [objective_text(&"obj_hearts", false), "Take the Master's Signet before Malrik",
				BRIEFING_RACE_LINE],
		"rule": objective_text(&"obj_vessa"),
	}


func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_hearts":
			var base := "Bring down the Root Hearts before Malrik"
			return "%s (%d / 3)" % [base, hearts_down] if with_counter else base
		&"obj_signet":
			match signet_state:
				&"malrik":
					return "Kill Malrik before he gets home (%d m)" % int(malrik_home_distance()) if with_counter \
							else "Kill Malrik before he gets home"
				_:
					if race_phase == &"muster" and with_counter:
						var left := maxi(0, int(ceil(muster_ends_at - mission_time())))
						return "Take the Master's Signet (Malrik marches in %d:%02d)" % [left / 60, left % 60]
					return "Take the Master's Signet (Malrik is racing you)"
		&"obj_gates":
			var base := "Break the Warden Gates"
			return "%s (%d / 2)" % [base, gates_down] if with_counter else base
		&"obj_vessa":
			return "Vessa must survive"
		&"sec_champion":
			return "Hire a champion at the Crooked Lantern"
		&"sec_mossjaw":
			return "Put down Old Mossjaw"
		&"sec_stakes":
			return "Keep every Ember Stake standing"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_hearts":
			var credits: Array = []
			for hid in HEART_ORDER:
				credits.append(heart_credit.get(hid, -1))
			return {"progress": hearts_down, "goal": 3, "counter": "%d / 3" % hearts_down, "credits": credits}
		&"obj_signet":
			if signet_state == &"malrik":
				return {"progress": int(maxf(0.0, 60.0 - malrik_home_distance())), "goal": 60,
						"position": shadow_hero.global_position if shadow_hero else DUSK_KEEP_POS}
			if race_phase == &"muster":
				return {"time_left": maxf(0.0, muster_ends_at - mission_time()), "position": OLDROOT_POS}
			return {"position": signet_ground if signet_state == &"ground" else OLDROOT_POS}
		&"obj_gates":
			return {"progress": gates_down, "goal": 2, "counter": "%d / 2" % gates_down}
		&"sec_mossjaw":
			return {"position": mossjaw.global_position if mossjaw and is_instance_valid(mossjaw) else MOSSJAW_POS}
	return {}


## Says the spec line `id` (L1..L22) once per run.
func say_id(id: StringName) -> void:
	if _said.has(id):
		return
	var i := LINE_IDS.find(id)
	if i < 0:
		push_error("Mission03: unknown line %s" % id)
		return
	_said[id] = true
	said_ids.append(id)
	say_line(i + 1)


# ---------------------------------------------------------------- the intro and the timed events

## E1, once the briefing is closed: camera on Vessa, L1-L3 (+ L20 with Pell), the hint.
func _intro() -> void:
	fire_once(&"E1")
	camera_rig.focus_on(hero.global_position)
	say_id(&"L1")
	say_id(&"L2")
	say_id(&"L3")
	if pell != null:
		say_id(&"L20")
	hud.show_message(HINT_START, 10.0)


func _add_events() -> void:
	for i in DRAIN_TIMES.size():
		after(DRAIN_TIMES[i], _fire_drain_squad.bind(StringName("D%d" % (i + 1)), false))
	after(LATE_DRAIN_START + LATE_DRAIN_EVERY, _late_drain)
	after(W1_TIME, _fire_w1)
	after(MOSSJAW_TIME, _e7_mossjaw)
	add_event(&"E3", func() -> bool:
		var g := ChampionGuild.for_team(Unit.Team.PLAYER)
		return g != null and g.hires_made > 0, _e3_first_hire)
	add_event(&"E4", func() -> bool:
		for id: StringName in hearts:
			if (hearts[id] as RootHeart).discovered:
				return true
		return false, func() -> void: say_id(&"L7"))
	add_event(&"E5", _drain_unit_seen, _e5_hunt_hint)
	add_event(&"E9", func() -> bool:
		var p: Vector3 = HEARTS[&"rh3"][1]
		for n in get_tree().get_nodes_in_group(&"units"):
			var u := n as Unit
			if u and u.team == Unit.Team.PLAYER and u.is_alive() and _flat(u.global_position, p) <= E9_RADIUS:
				return true
		return false, func() -> void: say_id(&"L12"))


## E2 (0:30): the tavern opens (the mission's message replaces the skirmish one), L4-L5 and the hint.
func _on_tavern_opened(_tavern: Tavern) -> void:
	if game_over or not fire_once(&"E2"):
		return
	_taverns_announced = true
	hud.show_message(MSG_TAVERN, 4.0)
	say_id(&"L4")
	say_id(&"L5")
	after(4.0, func() -> void:
		if not is_ending():
			hud.show_message(HINT_HIRE % [KeyLabels.of(KEY_Y), KeyLabels.of(KEY_R)], 10.0))


func _e3_first_hire() -> void:
	say_id(&"L6")
	set_objective(&"sec_champion", "done")
	hud.show_message(HINT_EXPLORE % KeyLabels.of(KEY_R), 10.0)


func _drain_unit_seen() -> bool:
	if fog == null:
		return false
	for sq: Dictionary in squads:
		for u: Variant in sq["thralls"] + sq["shades"]:
			if is_instance_valid(u) and (u as Unit).is_alive() \
					and fog.is_visible(Unit.Team.PLAYER, (u as Unit).global_position):
				return true
	return false


func _e5_hunt_hint() -> void:
	say_id(&"L21")
	hud.show_message(HINT_HUNT % KeyLabels.of(KEY_R), 10.0)


## E7 (6:00): Old Mossjaw (an Elder Grizzlemaw; easy: a Grizzlemaw) in the Hollowfen, roaming r 12, never respawns.
func _e7_mossjaw() -> void:
	if is_ending() or not fire_once(&"E7"):
		return
	var type_id: String = MOSSJAW_TYPE[clampi(mission_difficulty, 0, 2)]
	if UnitType.find(type_id) == null:
		type_id = "hollow_stag"
	var g := spawn_group([[type_id, 1]], MOSSJAW_POS, 0.0, Unit.Team.NEUTRAL, true)
	if g.is_empty():
		return
	mossjaw = g[0]
	mossjaw.name = "OldMossjaw"
	mossjaw.unit_name = "Old Mossjaw"
	mossjaw.died.connect(_on_mossjaw_died)
	say_id(&"L10")
	hud.show_message(MSG_MOSSJAW, 4.0)
	set_objective(&"sec_mossjaw", "active")


func _on_mossjaw_died(_u: Unit) -> void:
	if game_over or not fire_once(&"E8"):
		return
	var at := mossjaw.global_position
	say_id(&"L11")
	ItemDrops.spawn_pickup(self, &"warden_scale", at + Vector3(-1.0, 0.0, 0.8))
	ItemDrops.spawn_pickup(self, &"vital_root", at + Vector3(1.0, 0.0, 0.8))
	var bank := EssenceBank.for_team(Unit.Team.PLAYER)
	if bank:
		bank.add(150)
	set_objective(&"sec_mossjaw", "done")


# ---------------------------------------------------------------- the hearts

## E6 / E6b / E10: a heart is down. The player's kill plants an Ember Stake; Shadow's shows a message.
func _on_heart_down(h: RootHeart, by_team: int) -> void:
	if game_over:
		return
	hearts_down += 1
	heart_credit[h.heart_id] = by_team
	build_grid.request_rebake()
	_shrink_thorns()
	if by_team == Unit.Team.PLAYER:
		fire_once(&"E6")
		_plant_stake(h.global_position)
		if not _said.has(&"L8"):
			say_id(&"L8")
			hud.show_message(HINT_GUARD % KeyLabels.of(KEY_R), 10.0)
	else:
		hud.show_message(MSG_DRAINED % h.display_name, 4.0)
	set_objective(&"obj_hearts", "active")
	_counter_text_changed()
	if hearts_down == 2:
		fire_once(&"E6b")
		_fire_w2()
	if hearts_down >= 3:
		_e10_hearts_down()


func _plant_stake(at: Vector3) -> void:
	if _stake_type == null:
		return
	var s := build_grid.spawn_complete(_stake_type, at, Unit.Team.PLAYER)
	if s == null:
		return
	s.name = "EmberStake%d" % stakes.size()
	stakes.append(s)
	s.destroyed.connect(_on_stake_destroyed)
	if objective_state("sec_stakes") == "" and not stake_fell:
		set_objective(&"sec_stakes", "active")
	after(STAKE_RAID_DELAY, _fire_stake_raid.bind(s))


func _on_stake_destroyed(_b: Building) -> void:
	stake_fell = true
	if objective_state("sec_stakes") == "active":
		set_objective(&"sec_stakes", "failed")


# ---------------------------------------------------------------- waves

func _wave_spawn_point() -> Vector3:
	if gloom_hall and is_instance_valid(gloom_hall) and gloom_hall.is_alive() and gloom_hall is TrainingBuilding:
		return (gloom_hall as TrainingBuilding).spawn_point()
	if shadow_keep and is_instance_valid(shadow_keep) and shadow_keep.is_alive():
		return shadow_keep.spawn_point()
	return FALLBACK_SPAWN


func living_hearts() -> Array[RootHeart]:
	var out: Array[RootHeart] = []
	for id in HEART_ORDER:
		var h: RootHeart = hearts.get(id)
		if h and h.is_alive():
			out.append(h)
	return out


## D1 / D2 / D3 and the late drains: Thralls drain the first living heart in the order RH3, RH2, RH1; Shades escort.
func _fire_drain_squad(id: StringName, late: bool) -> void:
	if is_ending() or barrier_down or living_hearts().is_empty():
		return
	waves_fired.append(id)
	var at := _wave_spawn_point()
	var rows: Array = LATE_DRAIN_ROWS if late else DRAIN_ROWS[clampi(squads.size(), 0, DRAIN_ROWS.size() - 1)]
	var units := spawn_wave_at(rows, at)
	var sq := {"id": id, "thralls": [], "shades": [], "heart": living_hearts()[0]}
	for u: Unit in units:
		u.set_meta(&"squad", id)
		if u.unit_type and u.unit_type.id == &"gloom_thrall":
			u.aggro_range = 0.0   # Thralls never attack units
			u.set_meta(&"drain_slot", (sq["thralls"] as Array).size())
			(sq["thralls"] as Array).append(u)
		else:
			(sq["shades"] as Array).append(u)
			order_wave(u, &"drain_escort", (sq["heart"] as RootHeart).global_position)
	squads.append(sq)


func _late_drain() -> void:
	if is_ending() or barrier_down or living_hearts().is_empty():
		return
	_late_drains += 1
	_fire_drain_squad(StringName("late%d" % _late_drains), true)
	after(LATE_DRAIN_EVERY, _late_drain)


## Every frame: Thralls within reach drain their squad's heart (4 HP/s each); the others walk to their ring spot, or
## wait STAGE_BACK m out (toward the Shadow camp) while wood guardians still stand within GUARD_NEAR m of the heart.
func _tick_drains(delta: float, reorder: bool) -> void:
	var guarded := {}
	for sq: Dictionary in squads:
		var h: RootHeart = sq["heart"]
		if h == null or not h.is_alive():
			var alive := living_hearts()
			h = alive[0] if not alive.is_empty() and not barrier_down else null
			sq["heart"] = h
		if reorder and h != null and not guarded.has(h):
			guarded[h] = heart_guarded(h)
		if reorder and h != null and bool(guarded[h]):
			var back := (SHADOW_RALLY - h.global_position)
			back.y = 0.0
			var stage := h.global_position + back.normalized() * STAGE_BACK
			for t: Variant in sq["thralls"]:
				if is_instance_valid(t) and (t as Unit).is_alive() and _flat((t as Unit).global_position, stage) > 3.0 \
						and not (t as Unit).has_move_order():
					(t as Unit).command_move(stage + Vector3(randf_range(-2, 2), 0.0, randf_range(-2, 2)))
			continue
		for t: Variant in sq["thralls"]:
			if not is_instance_valid(t) or not (t as Unit).is_alive():
				continue
			var u := t as Unit
			if h == null:
				if reorder and not u.has_move_order():
					u.command_move(_alive_pos(shadow_keep, FALLBACK_SPAWN) + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3)))
				continue
			if _flat(u.global_position, h.global_position) <= DRAIN_REACH:
				if u.attack_target != null:
					u.command_stop()
				h.drain(DRAIN_PER_THRALL * delta, u)
			elif reorder and (not u.has_move_order() or u.attack_target != null):
				var a := float(int(u.get_meta(&"drain_slot", 0))) * TAU / 4.0 + 0.4
				u.command_move(h.global_position + Vector3(cos(a), 0.0, sin(a)) * DRAIN_RING)


## True while one of the heart's own guardians (G1 / G2 + the Bramble Spire / G3) lives within GUARD_NEAR m of it.
## Old Mossjaw is not a guardian: he roams, and a drain under his nose is the Hollowfen's three-way fight.
func heart_guarded(h: RootHeart) -> bool:
	var group: StringName = {&"rh1": &"G1", &"rh2": &"G2", &"rh3": &"G3"}.get(h.heart_id, &"")
	var list: Array = (guard_groups.get(group, []) as Array).duplicate()
	if h.heart_id == &"rh2":
		list.append(bramble_spire)
	for v: Variant in list:
		if v != null and is_instance_valid(v) and bool(v.call(&"is_alive")) \
				and _flat((v as Node3D).global_position, h.global_position) <= GUARD_NEAR:
			return true
	return false


func squad_of(u: Unit) -> Dictionary:
	var id: StringName = u.get_meta(&"squad", &"")
	for sq: Dictionary in squads:
		if sq["id"] == id:
			return sq
	return {}


func _fire_w1() -> void:
	if is_ending() or waves_fired.has(&"W1") or barrier_down:
		return
	waves_fired.append(&"W1")
	var target := _alive_pos(ember_hall, _alive_pos(keep, PLAYER_START))
	for u in spawn_wave_at([["shade", 5], ["nightbolt", 2]], _wave_spawn_point()):
		order_wave(u, &"point", target)


func _fire_w2() -> void:
	if is_ending() or waves_fired.has(&"W2") or signet_taken_by_vessa:
		return
	waves_fired.append(&"W2")
	var target := _alive_pos(keep, PLAYER_START)
	for u in spawn_wave_at([["shade", 6], ["nightbolt", 3], ["shadow_knight", 1]], _wave_spawn_point()):
		order_wave(u, &"point", target)


func _fire_stake_raid(stake: Building) -> void:
	if is_ending() or signet_taken_by_vessa:
		return
	waves_fired.append(&"stake_raid")
	var target := _alive_pos(stake, hero_pos())
	for u in spawn_wave_at([["grave_hound", 3], ["shade", 2]], _wave_spawn_point()):
		order_wave(u, &"point", target)


func _refresh_wave_unit(u: Unit, mode: StringName, _vessa: Vector3) -> bool:
	match mode:
		&"drain_escort":
			var sq := squad_of(u)
			var h: RootHeart = sq.get("heart")
			var thralls_alive := false
			for t: Variant in sq.get("thralls", []):
				if is_instance_valid(t) and (t as Unit).is_alive():
					thralls_alive = true
			var goal := Vector3.INF
			if thralls_alive and h != null and h.is_alive():
				goal = h.global_position
			else:
				goal = _nearest_stake_pos(u.global_position)
				if goal == Vector3.INF:
					u.set_meta(META_MODE, &"home")
					u.command_attack_move(SHADOW_RALLY)
					return true
			if u.attack_target == null and (not u.is_attack_moving() or _flat(u.get_meta(META_TARGET, goal), goal) > 1.0) \
					and _flat(u.global_position, goal) > 5.0:
				u.set_meta(META_TARGET, goal)
				u.command_attack_move(goal)
			return true
		&"race":
			_refresh_race_unit(u)
			return true
		&"home":
			if u.attack_target == null and not u.is_attack_moving() and _flat(u.global_position, SHADOW_RALLY) > 6.0:
				u.command_attack_move(SHADOW_RALLY)
			return true
	return false


func _nearest_stake_pos(from: Vector3) -> Vector3:
	var best := Vector3.INF
	var best_d := INF
	for s: Variant in stakes:
		if is_instance_valid(s) and (s as Building).is_alive():
			var d := _flat((s as Node3D).global_position, from)
			if d < best_d:
				best_d = d
				best = (s as Node3D).global_position
	return best


# ---------------------------------------------------------------- E10: the barrier falls, the race

func _e10_hearts_down() -> void:
	if not fire_once(&"E10"):
		return
	say_id(&"L13")
	say_id(&"L14")
	if objective_state("sec_stakes") == "active" and not stake_fell:
		set_objective(&"sec_stakes", "done")
	set_objective(&"obj_hearts", "done")
	_play_card(&"m3_oldroot", _oldroot_card(), _e10_end_state)


## E10's end state (played, skipped or missing = the same): barrier gone + rebake, Signet glow, obj_signet with the
## muster countdown (from when control returns), the race army spawns and musters at the rally.
func _e10_end_state() -> void:
	if barrier_down:
		return
	barrier_down = true
	wither_barrier()
	signet_state = &"tree"
	if _signet_mesh:
		_signet_mesh.visible = true
	flash_ring(OLDROOT_POS, OLDROOT_CLEARING)
	race_phase = &"muster"
	var muster: float = MUSTER[clampi(mission_difficulty, 0, 2)]
	muster_ends_at = mission_time() + muster
	set_objective(&"obj_signet", "active")
	after(muster, _e10a_march)
	_spawn_race_army()
	_malrik_joins_race()


func _spawn_race_army() -> void:
	waves_fired.append(&"race")
	race_army = spawn_wave_at([["shade", 8], ["nightbolt", 3], ["shadow_knight", 1]], _wave_spawn_point())
	if mission_difficulty >= 2:
		race_army.append_array(spawn_wave_at([["shadow_knight", 1]], _wave_spawn_point(), Unit.Team.ENEMY,
				func(_n: int) -> int: return 1))
	for u: Unit in race_army:
		order_wave(u, &"race", SHADOW_RALLY)


func _malrik_joins_race() -> void:
	if shadow_hero == null or not is_instance_valid(shadow_hero):
		return
	var diff := clampi(mission_difficulty, 0, 2)
	raise_wizard(shadow_hero, MALRIK_RACE_LEVEL[diff], MALRIK_RACE_SPELLS[diff])
	mark_scripted(shadow_hero)   # the mission leads him now; the Commander still casts for him
	if &"ai_auto_cast" in shadow_hero:
		shadow_hero.set(&"ai_auto_cast", true)
	if shadow_hero.is_alive():
		shadow_hero.command_move(SHADOW_RALLY)


## E10a: the muster ends, Malrik and his army march on the Oldroot.
func _e10a_march() -> void:
	if is_ending() or race_phase != &"muster":
		return
	race_phase = &"march"
	fire_once(&"E10a")
	hud.show_message(MSG_MARCH, 4.0)
	_counter_text_changed()


## Where Malrik grabs the Signet at the tree: the trunk's edge on his side.
func tree_grab_point() -> Vector3:
	var d := SHADOW_RALLY.normalized()
	return OLDROOT_POS + Vector3(d.x, 0.0, d.z) * 2.0


func malrik_home_distance() -> float:
	if shadow_hero == null or not is_instance_valid(shadow_hero):
		return 60.0
	return _flat(shadow_hero.global_position, DUSK_KEEP_POS)


## Malrik's orders (every 0.5 s from E10 to E11).
func _tick_malrik() -> void:
	var m := shadow_hero
	if m == null or not is_instance_valid(m) or not m.is_alive():
		return
	match race_phase:
		&"muster":
			if _flat(m.global_position, SHADOW_RALLY) > 4.0 and not m.has_move_order():
				m.command_move(SHADOW_RALLY)
		&"march":
			var goal := SHADOW_RALLY
			match signet_state:
				&"tree":
					goal = tree_grab_point()
				&"ground", &"dropping":
					goal = signet_ground
				&"malrik":
					goal = DUSK_KEEP_POS
			if _flat(m.global_position, goal) > 0.8 and (not m.has_move_order() or m.attack_target != null):
				m.command_move(goal)
		&"over":
			if m.attack_target == null and not m.is_attack_moving() and _flat(m.global_position, SHADOW_RALLY) > 6.0:
				m.command_attack_move(SHADOW_RALLY)


func _refresh_race_unit(u: Unit) -> void:
	var m := shadow_hero
	var malrik_ok := m != null and is_instance_valid(m) and m.is_alive()
	var goal := SHADOW_RALLY
	var leash := 6.0
	if race_phase == &"march":
		match signet_state:
			&"tree":
				goal = m.global_position if malrik_ok else OLDROOT_POS
				leash = MALRIK_LEASH_ARMY
			&"malrik":
				goal = m.global_position if malrik_ok else DUSK_KEEP_POS
				leash = CARRY_LEASH
			&"ground", &"dropping":
				goal = signet_ground
				leash = DROP_HOLD
	var d := _flat(u.global_position, goal)
	if d > leash + 6.0 or (u.attack_target == null and not u.is_attack_moving() and d > leash):
		u.command_attack_move(goal)


## The Signet's carry (every frame): who takes it, Malrik's way home.
func _tick_signet() -> void:
	match signet_state:
		&"tree", &"ground":
			var at := OLDROOT_POS if signet_state == &"tree" else signet_ground
			var r := TREE_CLAIM if signet_state == &"tree" else GROUND_CLAIM
			if hero_alive() and _flat(hero.global_position, at) <= r:
				_vessa_takes_signet()
				return
			var m := shadow_hero
			if race_phase == &"march" and m and is_instance_valid(m) and m.is_alive() and _flat(m.global_position, at) <= r:
				_malrik_takes_signet()
		&"malrik":
			if malrik_home_distance() <= HOME_RADIUS:
				_e15_signet_home()
	if _signet_mesh and is_instance_valid(_signet_mesh):
		match signet_state:
			&"tree":
				_signet_mesh.position = SIGNET_POS + SIGNET_LOOK_OFFSET + Vector3(0.0, sin(mission_time() * 2.0) * 0.1, 0.0)
			&"malrik":
				if shadow_hero and is_instance_valid(shadow_hero):
					_signet_mesh.position = shadow_hero.global_position + Vector3(0.0, 2.8, 0.0)
			&"ground", &"dropping":
				_signet_mesh.position = signet_ground + Vector3(0.0, 0.5, 0.0)


## E10b: Malrik takes the Signet: x 0.35 speed (difficulty table speed), walks home.
func _malrik_takes_signet() -> void:
	signet_state = &"malrik"
	fire_once(&"E10b")
	say_id(&"L19")
	var m := shadow_hero
	if _malrik_base_speed <= 0.0:
		_malrik_base_speed = maxf(0.1, m.get_stat(&"move_speed"))
	var speed: float = CARRY_SPEED[clampi(mission_difficulty, 0, 2)]
	m.add_modifier(&"signet_carry", {&"move_speed_pct": speed / _malrik_base_speed - 1.0})
	m.command_move(DUSK_KEEP_POS)
	_counter_text_changed()


func _on_malrik_died(_unit: Unit) -> void:
	if game_over or is_ending():
		return
	hud.show_message(MSG_MALRIK_FELL, 4.0)
	_respawn_left[Unit.Team.ENEMY] = MALRIK_RESPAWN
	if signet_state == &"malrik":   # E10c: the Signet drops after 3 s at the nearest navmesh point
		shadow_hero.remove_modifier(&"signet_carry")
		signet_state = &"dropping"
		signet_ground = _nav_point(shadow_hero.global_position)
		fire_once(&"E10c")
		after(DROP_DELAY, func() -> void:
			if signet_state == &"dropping":
				signet_state = &"ground"
				say_id(&"L22")
				_counter_text_changed())


func _on_m3_wizard_respawned(wiz: Wizard) -> void:
	if wiz != shadow_hero or is_ending():
		return
	wiz.remove_modifier(&"signet_carry")
	if race_phase == &"":
		wiz.command_move(SHADOW_RALLY)


func _nav_point(p: Vector3) -> Vector3:
	var nav_map := nav_region.get_navigation_map() if nav_region else RID()
	if nav_map.is_valid():
		var q := NavigationServer3D.map_get_closest_point(nav_map, p)
		return Vector3(q.x, 0.0, q.z)
	return p


# ---------------------------------------------------------------- E11: Vessa takes the Signet

func _vessa_takes_signet() -> void:
	if signet_taken_by_vessa or is_ending():
		return
	signet_taken_by_vessa = true
	signet_state = &"vessa"
	fire_once(&"E11")
	if _signet_mesh:
		_signet_mesh.visible = false
	_show_ysolde(Vector3(3.0, 0.0, -3.0))
	_play_card(&"m3_plea", _plea_card(), func() -> void:
		_play_card(&"m3_memory", _memory_card(), _e11_end_state))


## E11's end state: the Signet in artifact slot 2 (the free one first), L15-L16, every Shadow unit pulls back to the
## rally and holds it, both gates crack open and spawn, obj_signet done, obj_gates active, Ysolde sinks.
func _e11_end_state() -> void:
	if race_phase == &"over":
		return
	race_phase = &"over"
	_give_signet()
	speaker_names[&"whisper"] = "Obren"
	say_id(&"L15")
	say_id(&"L16")
	signet_taken.emit(hero)
	_pull_back_shadow()
	for id: StringName in gates:
		(gates[id] as WardenGate).open()
	set_objective(&"obj_signet", "done")
	set_objective(&"obj_gates", "active")
	_hide_ysolde()
	hud.show_message(HINT_E11, 8.0)


func _give_signet() -> void:
	var inv := ItemDrops.inventory_of(hero) as Inventory
	var slot := 1
	if inv:
		for i in inv.artifacts.size():
			if inv.artifacts[i] == null:
				slot = i
				break
	var ids := ["", ""]
	ids[slot] = "masters_signet"
	force_artifacts(hero, ids)


func _pull_back_shadow() -> void:
	clear_waves()
	for sq: Dictionary in squads:
		sq["heart"] = null
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or not u.is_alive() or u.team != Unit.Team.ENEMY or not u.is_in_group(SCRIPTED_GROUP):
			continue
		var spot := SHADOW_RALLY + Vector3(randf_range(-5.0, 5.0), 0.0, randf_range(-5.0, 5.0))
		u.command_move(spot)   # a walk, not a fight; it becomes a guard once there (_tick_homebound)
		u.set_meta(&"m3_home", spot)
		_guards.erase(u)
		_homebound.append(u)
	if shadow_hero and is_instance_valid(shadow_hero):
		shadow_hero.remove_modifier(&"signet_carry")
		if shadow_hero.is_alive():
			shadow_hero.command_move(SHADOW_RALLY)


## One tide of `gate` (WardenGate.spawner): 2 Ruin Wardens (max 8 alive per gate), NEUTRAL, after Vessa.
func _spawn_tide(gate: WardenGate) -> void:
	if is_ending() or _tide_type == null:
		return
	var list: Array = tide_units.get(gate.gate_id, [])
	list = list.filter(func(v: Variant) -> bool: return is_instance_valid(v) and (v as Unit).is_alive())
	var n := mini(TIDE_COUNT, TIDE_MAX_ALIVE - list.size())
	var front := gate.front_point()
	for i in n:
		var u := Worker.make_unit(_tide_type)
		_spawn(u, Unit.Team.NEUTRAL, front + Vector3(-0.8 + 1.6 * i, 0.0, 0.0))
		mark_scripted(u)
		order_wave(u, &"hero", hero_pos())
		list.append(u)
	tide_units[gate.gate_id] = list


## E12 / E13.
func _on_gate_down(gate: WardenGate) -> void:
	if game_over:
		return
	gates_down += 1
	set_objective(&"obj_gates", "active")
	_counter_text_changed()
	if gates_down == 1:
		fire_once(&"E12")
		say_id(&"L17")
		return
	if not fire_once(&"E13"):
		return
	set_objective(&"obj_gates", "done")
	for id: StringName in tide_units:
		for v: Variant in tide_units[id]:
			if is_instance_valid(v) and (v as Unit).is_alive():
				flash_ring((v as Unit).global_position, 1.5)
				(v as Unit).take_damage(1.0e9, null)
	_show_ysolde(hero_pos() + Vector3(3.0, 0.0, 0.0))
	_play_card(&"m3_parting", _parting_card(), _e13_end_state)


func _e13_end_state() -> void:
	_hide_ysolde()
	set_objective(&"obj_vessa", "done")
	win(VICTORY_DELAY)


# ---------------------------------------------------------------- defeat

## E14: Vessa falls.
func _on_player_hero_fell() -> void:
	fire_once(&"E14")
	say_id(&"L18")
	set_objective(&"obj_vessa", "failed")
	lose(DEFEAT_DELAY)


## E15 (Signet): Malrik home with it.
func _e15_signet_home() -> void:
	if is_ending() or not fire_once(&"E15"):
		return
	set_objective(&"obj_signet", "failed")
	hud.show_message("Malrik carried the Signet home", 4.0)
	lose(DEFEAT_DELAY)


# ---------------------------------------------------------------- every frame

func _physics_process(delta: float) -> void:
	super(delta)   # MissionBase: the Skirmish tick, the timers, the E-list
	if not match_started or game_over or world_is_held:
		return
	tick_scripted(delta)
	if is_ending():
		return
	_tick -= delta
	var slow := _tick <= 0.0
	if slow:
		_tick = 0.5
	_tick_drains(delta, slow)
	_tick_signet()
	if slow:
		_tick_malrik()
		_tick_mossjaw()
		_tick_maelis()
		_tick_homebound()
		_check_stronghold_hint()
		var t := _objective_text_now()
		if t != _last_obj_text:
			_last_obj_text = t
			_counter_text_changed()


func _objective_text_now() -> String:
	return objective_text(&"obj_signet") if objective_state("obj_signet") == "active" else ""


## A counter moved: the panel re-reads the texts (no Events.objective_changed: the state did not change).
func _counter_text_changed() -> void:
	objectives_changed.emit()
	if hud and mission_hud == null:
		hud.set_objective(_objective_text())


func _tick_mossjaw() -> void:
	if mossjaw == null or not is_instance_valid(mossjaw) or not mossjaw.is_alive():
		return
	_mossjaw_roam_left -= 0.5
	if _mossjaw_roam_left > 0.0:
		return
	_mossjaw_roam_left = randf_range(12.0, 20.0)
	var a := randf() * TAU
	var r := randf() * MOSSJAW_ROAM
	mossjaw.set_meta(META_HOME, _nav_point(MOSSJAW_POS + Vector3(cos(a) * r, 0.0, sin(a) * r)))


## After E11 the Shadow units walk to the rally (a move: no fight on the way) and hold it as guards once there.
func _tick_homebound() -> void:
	var still: Array = []
	for v: Variant in _homebound:
		if not is_instance_valid(v) or not (v as Unit).is_alive():
			continue
		var u := v as Unit
		var spot: Vector3 = u.get_meta(&"m3_home", SHADOW_RALLY)
		if _flat(u.global_position, spot) <= 3.0:
			u.set_meta(META_HOME, spot)
			_guards.append(u)
			continue
		if not u.has_move_order():
			u.command_move(spot)
		still.append(u)
	_homebound = still


## Maelis holds RH3 with a 2x leash: past it she walks home.
func _tick_maelis() -> void:
	if maelis == null or not is_instance_valid(maelis) or not maelis.is_alive():
		return
	var home: Vector3 = HEARTS[&"rh3"][1]
	if _flat(maelis.global_position, home) > maelis.aggro_range * 2.0:
		maelis.command_move(home + Vector3(2.5, 0.0, 0.0))


func _check_stronghold_hint() -> void:
	if stronghold_hint_shown or tier_system == null or hud == null:
		return
	var st := TierSystem.status(Unit.Team.PLAYER)
	if st.is_empty() or int(st["tier"]) != 1 or bool(st["upgrading"]) or int(st["next"]) != 2 or String(st["reason"]) != "":
		return
	stronghold_hint_shown = true
	var opens := TierSystem.unlock_text(Unit.Team.PLAYER, 2)
	hud.show_message(HINT_STRONGHOLD % [KeyLabels.of(KEY_X), int(st["crystals"]), opens if opens != "" else "new units"],
			HINT_STRONGHOLD_SECONDS)


# ---------------------------------------------------------------- right-click on hearts and gates, Fireball

func _input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_RIGHT or selection == null \
			or selection.selected_building != null or selection.get_pending_order() != &"" \
			or selection.pending_spell() != &"":
		return
	var target := _ray_target(mb.position)
	if target == null:
		return
	var units := selection.orderable_units()
	if units.is_empty():
		return
	for v: Variant in units:
		var u := v as Unit
		if u and u.is_alive():
			u.command_attack(target)
	get_viewport().set_input_as_handled()


## The heart or open gate under the screen point (vertical cylinders), or null.
func _ray_target(screen: Vector2) -> Node3D:
	var cam := camera_rig.camera if camera_rig else null
	if cam == null:
		return null
	var from := cam.project_ray_origin(screen)
	var dir := cam.project_ray_normal(screen)
	if absf(dir.y) < 0.001:
		return null
	var cands: Array = []
	for id: StringName in hearts:
		var h: RootHeart = hearts[id]
		if h.is_alive() and h.discovered:
			cands.append([h, RootHeart.RADIUS + 0.4, RootHeart.HEIGHT])
	for id: StringName in gates:
		var g: WardenGate = gates[id]
		if g.is_open and g.is_alive():
			cands.append([g, 2.4, WardenGate.SIZE.y])
	for k in 11:
		for c: Array in cands:
			var y := float(c[2]) * k / 10.0
			var t := (y - from.y) / dir.y
			if t <= 0.0:
				continue
			if _flat(from + dir * t, (c[0] as Node3D).global_position) <= float(c[1]):
				return c[0]
	return null


## Vessa's Fireball also burns a heart / an open gate its blast reaches (they are not units).
func _on_hero_spell_effect(id: StringName, pos: Vector3) -> void:
	if id == &"fireball":
		get_tree().create_timer(FIREBALL_TRAVEL, false, true).timeout.connect(_fireball_lands.bind(pos))


func _fireball_lands(pos: Vector3) -> void:
	if game_over or not is_instance_valid(hero):
		return
	var caster := hero.get_node_or_null(^"SpellCaster") as SpellCaster
	var t := SpellType.find(&"fireball")
	if caster == null or t == null:
		return
	var rank := maxi(1, caster.rank_of(&"fireball"))
	var targets: Array = []
	for id: StringName in hearts:
		targets.append([hearts[id], RootHeart.RADIUS])
	for id: StringName in gates:
		targets.append([gates[id], 1.8])
	for row: Array in targets:
		var n := row[0] as Node3D
		if bool(n.call(&"is_alive")) and _flat(pos, n.global_position) <= t.radius_at(rank) + float(row[1]):
			n.call(&"take_damage", caster.spell_damage(t, rank), hero)


# ---------------------------------------------------------------- cinematic cards (engine fallback cards, M3.V1 later)

## Plays `id` from data/cinematics/<id>.tres when it exists (MissionBase.play_cutscene), else `card` (a PAUSE card on
## the cinematic runtime); `end_state` runs once at the end, skipped or not, or at once with cinematics off (tests).
func _play_card(id: StringName, card: CinematicScript, end_state: Callable) -> void:
	if cinematics_enabled and card != null and CinematicScript.find(id) == null:
		var player := CinematicPlayer.instance(get_tree())
		for tag: StringName in _card_actors:
			if is_instance_valid(_card_actors[tag]):
				player.register_actor(tag, _card_actors[tag])
		if player.play(card, self) == "":
			player.finished.connect(func(_fid: StringName, _skipped: bool) -> void: end_state.call(), CONNECT_ONE_SHOT)
			return
	play_cutscene(id, end_state)


func _cine_lines(id: StringName) -> Array:
	var out: Array = []
	for row: Array in CINE_LINES:
		if row[0] == id:
			out.append([row[1], row[2], row[3]])
	return out


## A one-shot card: title + the lines as subtitles over a slow push-in on `focus` (world frozen: PAUSE).
func _card(id: StringName, title: String, sub: String, lines: Array, focus: Vector3, from: Vector3, to: Vector3,
		min_length := 4.0) -> CinematicScript:
	var s := CinematicScript.new()
	s.id = id
	s.title = title
	s.kind = CinematicScript.Kind.ENGINE
	s.world_mode = CinematicScript.WorldMode.PAUSE
	s.letterbox_aspect = 2.39
	s.skippable = true
	s.return_focus = focus
	var total := 1.0
	for l: Array in lines:
		total += float(l[2]) + 0.25
	var shot := CinematicShot.make(StringName("%s_card" % id), maxf(min_length, total), CinematicShot.CameraMode.DOLLY)
	shot.from_pos = focus + from
	shot.to_pos = focus + to
	shot.look_from = focus + Vector3(0.0, 1.5, 0.0)
	shot.look_to = focus + Vector3(0.0, 1.5, 0.0)
	shot.fov_from = 42.0
	shot.fov_to = 38.0
	shot.transition_in = CinematicShot.Transition.FADE_BLACK
	shot.transition_time = 0.6
	if title != "":
		shot.add_action(0.0, &"title", &"", Vector3.ZERO, {"text": title, "sub": sub, "time": 2.5})
	var t := 0.6
	for l: Array in lines:
		shot.add_line(t, StringName(l[0]), String(l[1]), float(l[2]))
		t += float(l[2]) + 0.25
	shot.blend_to_game = true
	s.shots = [shot]
	return s


func _oldroot_card() -> CinematicScript:
	_card_actors = {}
	return _card(&"m3_oldroot", "The Oldroot Opens", "", [], OLDROOT_POS, Vector3(16.0, 20.0, 16.0),
			Vector3(5.0, 6.0, 5.0), 12.0)


func _plea_card() -> CinematicScript:
	_card_actors = {&"vessa": hero}
	return _card(&"m3_plea", "Ysolde's Plea", "", _cine_lines(&"m3_plea"), OLDROOT_POS, Vector3(7.0, 4.0, 8.0),
			Vector3(4.0, 2.6, 5.0), 40.0)


## m3_memory is a VIDEO (later production): the 10 s fallback card.
func _memory_card() -> CinematicScript:
	_card_actors = {}
	return _card(&"m3_memory", "The Signet's Memory", "", _cine_lines(&"m3_memory"), OLDROOT_POS,
			Vector3(2.0, 3.0, 3.0), Vector3(1.2, 2.2, 1.8), 10.0)


func _parting_card() -> CinematicScript:
	_card_actors = {&"vessa": hero}
	var at := hero_pos()
	return _card(&"m3_parting", "The Wood Will Remember", "", _cine_lines(&"m3_parting"), at, Vector3(6.0, 4.0, 7.0),
			Vector3(10.0, 14.0, 12.0), 40.0)


## Ysolde as a story actor (not a unit: nothing targets her): a placeholder figure rising out of the roots.
func _show_ysolde(at: Vector3) -> void:
	if _SIM.enabled:
		return
	if _ysolde == null or not is_instance_valid(_ysolde):
		_ysolde = Node3D.new()
		_ysolde.name = "Ysolde"
		add_child(_ysolde)
		var body := CapsuleMesh.new()
		body.radius = 0.35
		body.height = 1.9
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.40, 0.62, 0.30)
		mat.emission_enabled = true
		mat.emission = Color(0.55, 0.90, 0.35)
		mat.emission_energy_multiplier = 0.4
		var mi := MeshInstance3D.new()
		mi.mesh = body
		mi.material_override = mat
		mi.position.y = 0.95
		_ysolde.add_child(mi)
	_ysolde.global_position = _nav_point(at) + Vector3(0.0, -1.9, 0.0)
	_ysolde.visible = true
	_ysolde.create_tween().tween_property(_ysolde, "position:y", 0.0, 1.0)


func _hide_ysolde() -> void:
	if _ysolde and is_instance_valid(_ysolde):
		var tw := _ysolde.create_tween()
		tw.tween_property(_ysolde, "position:y", -2.0, 1.0)
		tw.tween_callback(_ysolde.hide)
