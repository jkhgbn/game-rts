class_name MissionE5_01
extends MissionE5Base
## Episode 5, mission 1 "The First Spark" (docs/design/mission-e5-01.md): a flashback. Twelve-year-old Vessa takes
## Torren Vey's first trial in the Vale of Bells: light the five old signal beacons (any order) while Duskfen reivers
## loot the farms, then hold the vale 1:30 until the south watch rides in (or drive Gannet Rook off). Old Vey in his
## prime walks with her (sword only: his lightning is never shown, F6). Doubles as the basics refresher. Spotlight:
## the Ember Spire (the first Millrace farm raid).
##
## Built deviations (2026-10-08, from the spec):
## - The Vale is the main.gd generator look with seed 5101 (trees / rocks kept out of the clearings and of lanes
##   between the beacons); no cliff or stream-bed decor yet (E5M1.V2); afternoon -> dusk is a sun tint on the warm rig.
## - Valewatch is a Fire keep copy (2 000 HP, same id); the Ember Hall the player builds trains its tier-1 roster
##   (the Blaze Rider / Ash Hurler lock is not built).
## - Beacons are MissionBraziers (Vessa within 3 m for 3 s, sight 16 once lit). A beacon does not catch while a
##   hostile unit stands within 8 m of it (the guards must be cleared or drawn off: no beacon rush past its guard).
## - Reivers / slingers / war-boars / Gannet are mission-local UnitTypes from the Magpie / Nightbolt / Bristleback
##   numbers (F11); Old Vey is a not-commandable torren_vey copy driven by this script (escort, Old Steel sweep,
##   Intercept, The Lesson as a 10 mana refund, kneel 8 s -> 40 %, never attacks buildings, the teaching bark).
## - Gannet's Hook Throw pulls through Unit.displace; he flees at 40 % (untargetable at once) and despawns at SP_SE.
##   He comes with the Final's +40 s group (not at 0 s): a big army drove him off in seconds, the hold was no fight.
## - The south watch rides home at dusk: the hold lasts until max(5th beacon + 1:30, DUSK_AT) (9:00 / 10:00 / 11:00),
##   the Final's second group comes 50 s before its end and the camp calls go on until then (a beacon rush lit four
##   beacons by 3:30 with Vey and the start army; it must not win before ~10 min, tests/test_e5m1_rush_sim.gd).
## - Hearth max 1: a second Hearth site is cancelled at once with a full refund ("Valewatch has room for one Hearth").
## - Items locked: no essence, the inventory bar hidden (the keep / Hall still answer is_shop()).

const MISSION_ID := &"e5m1"
const MISSION_TITLE := "The First Spark"
const MAP_SEED := 5101

const VESSA_START := Vector3(-30.0, 0.0, -34.0)
const VEY_START := Vector3(-28.0, 0.0, -34.0)
const ARMY_START := Vector3(-27.0, 0.0, -37.0)
const VALEWATCH := Vector3(-38.0, 0.0, -42.0)
const NODES := [[&"v_home_a", Vector3(-48.0, 0.0, -36.0), 1200], [&"v_home_b", Vector3(-30.0, 0.0, -52.0), 1200],
		[&"v_mill", Vector3(-46.0, 0.0, 2.0), 1500]]
## Beacon id -> [name, position].
const BEACONS := {
	&"hearthstone": ["Hearthstone", Vector3(-18.0, 0.0, -24.0)],
	&"millrace": ["Millrace", Vector3(-42.0, 0.0, 14.0)],
	&"bridge": ["Old Bridge", Vector3(2.0, 0.0, 0.0)],
	&"knoll": ["Shepherd's Knoll", Vector3(36.0, 0.0, -18.0)],
	&"bellmouth": ["Bellmouth", Vector3(26.0, 0.0, 34.0)],
}
const BEACON_ORDER: Array[StringName] = [&"hearthstone", &"millrace", &"bridge", &"knoll", &"bellmouth"]
const FARMS: Array[Vector3] = [Vector3(-34.0, 0.0, 22.0), Vector3(-50.0, 0.0, 20.0), Vector3(-28.0, 0.0, 30.0)]
const CAMP := Vector3(44.0, 0.0, 46.0)
const TENTS: Array[Vector3] = [Vector3(40.0, 0.0, 48.0), Vector3(48.0, 0.0, 42.0)]
const SP_SE := Vector3(52.0, 0.0, 54.0)
const SP_W := Vector3(-56.0, 0.0, 30.0)
const SCOUT_ENTRY := Vector3(54.0, 0.0, -18.0)
const CITADEL := Vector3(0.0, 0.0, -64.0)

const BEACON_SIGHT := 16.0
const BEACON_BLOCK_R := 8.0       ## a hostile unit this close keeps a beacon from catching
const NEAR_BEACON_HINT := 12.0
const KNOLL_HINT_R := 14.0
const GUARD_LEASH := 16.0         ## 2x the guards' aggro
const W1_EARLIEST := 240.0
const W1_AFTER_B1 := 60.0
const RAID_EVERY := 120.0
const CAMP_CALL_EVERY := 150.0
const FINAL_EXTRA_AFTER := 40.0
const HOLD_TIME: Array[float] = [60.0, 90.0, 120.0]
const DUSK_AT: Array[float] = [540.0, 600.0, 660.0]   ## the watch is never home before dusk (rush floor)
const GANNET_FLEE := 0.40
const GANNET_HP: Array[float] = [550.0, 700.0, 900.0]
const HOOK_CD: Array[float] = [15.0, 12.0, 10.0]
const HOOK_RANGE := 8.0
const HOOK_PULL := 6.0
const HOOK_DAMAGE := 15.0
const VEY_NEAR := 3.0
const VEY_FAR := 7.0
const VEY_GUARD_R := 9.0
const VEY_KNEEL := 8.0
const VEY_STAND_HP := 0.40
const INTERCEPT_EVERY := 8.0
const INTERCEPT_R := 10.0
const LESSON_R := 10.0
const LESSON_REFUND := 10.0        ## Fireball 40 -> 30 mana within 10 m of Vey
const SWEEP_R := 2.5
const BARK_ALONE_R := 14.0
const BARK_BASE_R := 24.0
const BARK_DELAY := 5.0
const BARK_EVERY := 60.0
const DEFEAT_DELAY := 3.0
const LEVEL_CAP := 3
const COUNT_MULT: Array[float] = [0.6, 1.0, 1.4]
const START_CRYSTALS: Array[int] = [350, 250, 200]
const START_GUARDS: Array[int] = [4, 3, 2]
const YOUNG_SCALE := 0.82

const GUARDS := {
	&"G1": [Vector3(-15.0, 0.0, -20.0), 1.5, Unit.Team.ENEMY, [["reiver", 2]]],
	&"G2": [Vector3(-42.0, 0.0, 14.0), 4.0, Unit.Team.ENEMY, [["reiver", 3], ["reiver_slinger", 1]]],
	&"G3": [Vector3(4.0, 0.0, 4.0), 3.0, Unit.Team.ENEMY, [["reiver", 3], ["reiver_slinger", 2]]],
	&"G4": [Vector3(36.0, 0.0, -18.0), 4.0, Unit.Team.NEUTRAL, [["bristleback", 2], ["mirefang", 1]]],
	&"G5": [Vector3(26.0, 0.0, 34.0), 4.0, Unit.Team.ENEMY, [["reiver", 3], ["reiver_slinger", 2]]],
}
const WAVES := {
	&"W1": [["reiver", 3]],
	&"W2": [["reiver", 3], ["war_boar", 1]],
	&"RAID": [["reiver", 2]],
	&"W3": [["reiver", 4], ["reiver_slinger", 2], ["war_boar", 1]],
	&"CAMP": [["reiver", 2]],
	&"FINAL": [["reiver", 5], ["reiver_slinger", 2], ["war_boar", 2]],
	&"FINAL2": [["reiver", 3], ["reiver_slinger", 1]],
}

const SPEAKER_COLORS := {&"vessa": Color(1.0, 0.45, 0.1), &"vey": Color(0.95, 0.95, 0.55),
		&"gannet": Color(0.62, 0.55, 0.40), &"master": Color(1.0, 0.92, 0.70), &"narrator": Color(0.9, 0.85, 0.7)}
const SPEAKER_NAMES := {&"vessa": "Vessa", &"vey": "Old Vey", &"gannet": "Gannet Rook", &"master": "The Master",
		&"narrator": "Narrator"}
## The spec's 26 lines (data/voice/lines/e5m1.json, French in data/i18n/fr): LINE_IDS[n - 1] = id of line n.
const LINE_IDS: Array[String] = ["L1", "L2", "L3", "L4", "L5", "L6", "L7", "L8", "L9", "L10", "L11", "L12", "L13",
		"L14", "L15", "L16", "L17", "L18", "L19", "L20", "L21", "L22", "L23", "L24", "L25", "L26"]
const DIALOGUE := [
	[&"narrator", "Long before the war, a girl with soot on her hands came down into the Vale of Bells."],
	[&"vey", "Five beacons, Vessa. Light them all and the south watch comes home. That is the trial."],
	[&"vessa", "Five? I could light fifty. Can I light the bridge too? It looks very flammable."],
	[&"vey", "Stand close and hold still. Fire comes when you stop chasing it."],
	[&"vessa", "Ha! One! Did you see? Tell me you saw that."],
	[&"vey", "I saw. Now build something to guard it. A beacon on its own is just a target."],
	[&"gannet", "Pretty lights in the vale! Keep lighting them, little match. We'll follow them home."],
	[&"vey", "You're getting stronger. Learn to step out of trouble before you learn to start it."],
	[&"vessa", "Millrace is lit! And the mill is... mostly not on fire. Mostly."],
	[&"narrator", "The miller's boys took down their bows from the wall. Nobody had asked them to."],
	[&"vey", "Halfway. Your soldiers are tired, Vessa. Let them catch up."],
	[&"vey", "Leave the boars their hill and they'll leave you yours. Take the beacon, not the fight."],
	[&"narrator", "On the far road, the south watch's scouts saw the fire and turned their horses home."],
	[&"vey", "Vessa! A spark that runs off alone goes out. Wait for your soldiers."],
	[&"vessa", "Oops. Tents are very flammable. Who knew? ...Everyone. Everyone knew."],
	[&"gannet", "All five lit? Then the whole vale can watch you lose. Boys! Fetch me that match!"],
	[&"vessa", "Come on, then! I've got five fires and a really bad temper."],
	[&"gannet", "She burned my good coat! Back to the fens! Back to the fens!"],
	[&"narrator", "At dusk the south watch rode home along a road of fire."],
	[&"vey", "Not bad, girl. Remember it: the spark first. Then the storm."],
	[&"vessa", "What storm? I don't have a storm. Do YOU have a storm?"],
	[&"vey", "Ha. Go and wash your face. You look like a chimney."],
	[&"master", "Not yet, old friend. Let her find her own fire first."],
	[&"vey", "Just catching my breath. Keep lighting!"],
	[&"vessa", "Vey... I didn't wait..."],
	[&"vessa", "No, no, no! That was somebody's house!"],
]
const BRIEFING_PARAGRAPHS: Array[String] = [
	"Winter, the truce. In Emberfall, Vessa turns an old sword-knot in her fingers. Vey's. She remembers the first time he made her wait.",
	"Twenty years before the crown, the Master's citadel rose above the clouds and the world was at peace, nearly. In the Vale of Bells below it, the old signal beacons had gone cold, and reivers from the southern fens had noticed.",
	"Torren Vey, the Master's sword, set his youngest apprentice her first trial: light all five beacons and call the south watch home. Vessa was twelve. She had never waited for anything in her life.",
]
const HINT_START := "Right-click to walk Vessa (Hero WASD: W A S D). Light the beacon to the south-east: stand beside it."
const HINT_BEACON := "Stay within 3 m of the beacon for 3 seconds. Only Vessa can light it."
const HINT_BUILD := "Select the Keep and press Z to train a Cinder Hand. Then select a Cinder Hand: B, then X, builds an Ember Hall."
const HINT_HALL := "Select the Ember Hall: Z trains a Flame Guard, X an Ember Archer. Right-click the ground to set their rally point."
const HINT_W1 := "Select your soldiers, press X (or A) and click: they attack everything on the way. F then click: Fireball."
const HINT_LEVEL := "Level up! Ctrl+Q learns Ember Step, then Q and click to jump. Ctrl+1 puts your selection in group 1."
const HINT_KNOLL := "Neutral beasts guard their ground but never chase far. Draw them off the beacon, or pass by."
const HINT_RIDERS := "Blaze Riders are fast: send them after the slingers."
const HINT_SPIRE := "Build an Ember Spire by the Millrace farms (worker, B then C)."
const MSG_BLOCKED := "Reivers stand by the beacon: it won't catch until they are gone"
const MSG_VOLUNTEERS := "The Millrace volunteers join you"
const MSG_SCOUTS := "The south watch's scouts ride in"
const MSG_GANNET_FLEES := "Gannet Rook flees to the fens"
const MSG_ONE_HEARTH := "Valewatch has room for one Hearth"

## Read only.
var beacons := {}                       ## id -> MissionBrazier
var lit: Array[String] = []             ## beacon ids lit, in order
var farms: Array = []                   ## the 3 Millrace farms (Building)
var tents: Array = []                   ## the 2 Reiver Tents (Building)
var tents_burned := 0
var farms_burned := 0
var vey: Unit = null
var gannet: Unit = null
var gannet_fled := false
var guard_groups := {}                  ## group id -> Array of units
var waves_fired: Array[String] = []
var hold_ends_at := -1.0                ## mission time the hold ends (-1 = not started)
var victory_time := -1.0
var bark_count := 0
var vey_kneels := 0

var _tick := 0.0
var _fast := 0.0
var _w1_at := -1.0
var _raid_at := -1.0
var _camp_at := -1.0
var _final_extra_at := -1.0
var _vey_kneel_left := 0.0
var _intercept_left := 0.0
var _vey_strikes := 0
var _hook_left := 0.0
var _alone_for := 0.0
var _bark_ready_at := 0.0
var _blocked_msg_at := -100.0
var _markers := {}                      # beacon id -> SightMarker (rebuilt on load)
var _dusk := false
var _vale_keep_type: BuildingType
var _farm_type: BuildingType
var _tent_type: BuildingType


# ---------------------------------------------------------------- setup

func _init() -> void:
	super()
	player_kingdom = &"fire"
	enemy_kingdom = &"shadow"
	line_ids = LINE_IDS.duplicate()
	dialogue_lines = DIALOGUE
	speaker_colors = SPEAKER_COLORS.duplicate()
	speaker_names = SPEAKER_NAMES.duplicate()
	briefing_paragraphs = BRIEFING_PARAGRAPHS.duplicate()
	define_objectives([[&"obj_beacons", "primary"], [&"obj_hold", "primary"], [&"obj_vessa", "primary"],
			[&"sec_farms", "secondary"], [&"sec_tents", "secondary"]])
	_make_types()


func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	MissionE5Base.e5_config(c)
	c.mission_id = MISSION_ID
	c.title = MISSION_TITLE
	c.count_mult = COUNT_MULT.duplicate()
	c.easy_skip_types = [&"war_boar"]
	c.defeat_on_keep_lost = true
	c.keep_lost_message = "Valewatch has fallen"
	c.start_level = 1
	c.start_spells = [&"fireball"]
	c.level_cap = LEVEL_CAP
	c.start_crystals = START_CRYSTALS.duplicate()
	c.start_essence = 0
	c.essence_trickle = false
	c.kill_essence = false
	c.defeat_delay = DEFEAT_DELAY
	c.victory_banner = "VICTORY\nThe south watch rides home"
	c.defeat_banner = "DEFEAT"
	c.rewards = CampaignState.MISSION_REWARDS.get(MISSION_ID, {})
	c.spotlight = {"id": &"fire_tower", "trigger": &"manual", "key_hint": "Worker: B then C",
			"card": "Ember Spire. A tower that watches while you're away: raiders hate it."}
	return c


## F11 story kinds (Duskfen Reivers) and Old Vey in his prime, from existing numbers.
func _make_types() -> void:
	local_unit("magpie", "reiver", "Reiver", {"aggro_range": 8.0, "kill_xp": 20, "commandable": false,
			"body_color": Color(0.36, 0.33, 0.24)})
	local_unit("nightbolt", "reiver_slinger", "Reiver Slinger", {"max_hp": 70.0, "attack_damage": 9.0,
			"attack_range": 9.0, "aggro_range": 10.0, "cost": 0, "pop": 0, "kill_xp": 25, "commandable": false,
			"body_color": Color(0.40, 0.36, 0.26)})
	local_unit("bristleback", "war_boar", "War-boar", {"neutral_leash": false, "aggro_range": 8.0, "kill_xp": 30,
			"commandable": false})
	local_unit("magpie", "reiver_chief", "Gannet Rook", {"max_hp": 700.0, "armor": 10.0, "attack_damage": 20.0,
			"attack_cooldown": 1.2, "move_speed": 5.2, "aggro_range": 10.0, "kill_xp": 0, "commandable": false,
			"body_color": Color(0.45, 0.38, 0.22)})
	local_unit("torren_vey", "vey_prime", "Torren Vey", {"max_hp": 1400.0, "armor": 25.0, "attack_damage": 32.0,
			"attack_cooldown": 1.2, "move_speed": 5.0, "sight_radius": 13.0, "aggro_range": 9.0, "commandable": false})
	_vale_keep_type = MissionE5Base.local_building("fire_keep", "fire_keep", "Valewatch", 2000.0, true)
	if _vale_keep_type:
		_vale_keep_type.pop_bonus = 20
	_farm_type = MissionE5Base.local_building("fire_hearth", "millrace_farm", "Millrace Farm", 500.0)
	_tent_type = MissionE5Base.local_building("shadow_hovel", "reiver_tent", "Reiver Tent", 450.0)


func _map_size() -> Vector2:
	return Vector2(120.0, 120.0)


func _player_start() -> Vector3:
	return VESSA_START


func _lighting_preset() -> StringName:
	return &"warm"   # E5M1.V2: vale_afternoon -> vale_dusk when the lighting rig has them


func _title_line() -> String:
	return "Episode 5, Mission 1: %s" % MISSION_TITLE


func _ground_spots() -> Array[Vector4]:
	return [Vector4(VALEWATCH.x, VALEWATCH.z, 12.0, 0.0), Vector4(2.0, 0.0, 6.0, 1.0), Vector4(CAMP.x, CAMP.z, 10.0, 0.0)]


func _ready() -> void:
	super()
	_apply_afternoon()
	if camera_rig:
		camera_rig.focus_on(VESSA_START)


func _apply_afternoon() -> void:
	tint_light(Color(1.0, 0.86, 0.66), 1.0, -38.0, Color(0.72, 0.66, 0.58), Color(0.42, 0.52, 0.72),
			Color(0.92, 0.78, 0.58))


## E13: the light turns to dusk (vale_dusk stand-in).
func _apply_dusk() -> void:
	if _dusk:
		return
	_dusk = true
	tint_light(Color(1.0, 0.62, 0.40), 0.75, -16.0, Color(0.62, 0.50, 0.58), Color(0.30, 0.26, 0.42),
			Color(0.95, 0.55, 0.36))


# ---------------------------------------------------------------- the map

func start_position(_team: int) -> Vector3:
	return VESSA_START


func base_center(_team: int) -> Vector3:
	return VALEWATCH


func node_of(_team: int, suffix: String) -> CrystalNode:
	var v: Variant = crystal_nodes.get(StringName("v_home_" + suffix)) if suffix in ["a", "b"] else crystal_nodes.get(&"v_mill")
	if v == null or not is_instance_valid(v):
		return null
	var n := v as CrystalNode
	return n if n != null and not n.is_depleted() else null


func natural_hall_spot(_team: int) -> Vector3:
	return Vector3.INF


func rich_hall_spot(_team: int) -> Vector3:
	return Vector3.INF


func market_slot(_team: int) -> Vector3:
	return Vector3.INF


func tower_slot(_team: int, _which: StringName) -> Vector3:
	return Vector3.INF


func _build_map() -> void:
	var clearings: Array = [[VESSA_START, 8.0], [VALEWATCH, 16.0], [CAMP, 14.0], [SP_SE, 6.0], [SP_W, 6.0],
			[SCOUT_ENTRY, 5.0], [Vector3(-46.0, 0.0, 2.0), 7.0]]
	for row: Array in NODES:
		clearings.append([row[1], 6.0])
	for id: StringName in BEACONS:
		clearings.append([BEACONS[id][1], 9.0])
	for p in FARMS:
		clearings.append([p, 5.0])
	var b := func(id: StringName) -> Vector3: return BEACONS[id][1]
	var lanes: Array = [[VESSA_START, b.call(&"hearthstone"), 4.0], [b.call(&"hearthstone"), b.call(&"bridge"), 4.0],
			[b.call(&"hearthstone"), b.call(&"millrace"), 4.0], [b.call(&"bridge"), b.call(&"knoll"), 4.0],
			[b.call(&"bridge"), b.call(&"bellmouth"), 4.0], [b.call(&"bellmouth"), CAMP, 4.0], [CAMP, SP_SE, 4.0],
			[b.call(&"millrace"), SP_W, 4.0], [b.call(&"millrace"), FARMS[2], 4.0], [VALEWATCH, VESSA_START, 5.0],
			[b.call(&"knoll"), SCOUT_ENTRY, 4.0], [b.call(&"bridge"), b.call(&"millrace"), 4.0],
			[b.call(&"bellmouth"), FARMS[2], 4.0], [VALEWATCH, b.call(&"millrace"), 4.0]]
	scatter_props(MAP_SEED, clearings, lanes, 11, 20)
	for row: Array in NODES:
		_add_crystal_node(StringName(row[0]), row[1], int(row[2]))
	keep = build_grid.spawn_complete(_vale_keep_type, VALEWATCH, Unit.Team.PLAYER) as Keep
	if keep:
		keep.name = "Valewatch"
		seat_keeps[Unit.Team.PLAYER] = keep
	seat_bases[Unit.Team.PLAYER] = VALEWATCH
	for p in FARMS:
		var f := build_grid.spawn_complete(_farm_type, p, Unit.Team.PLAYER) if _farm_type else null
		if f:
			mark_scripted(f)
			farms.append(f)
			f.destroyed.connect(_on_farm_destroyed)
	for p in TENTS:
		var t := build_grid.spawn_complete(_tent_type, p, Unit.Team.ENEMY) if _tent_type else null
		if t:
			mark_scripted(t)
			tents.append(t)
			t.destroyed.connect(_on_tent_destroyed)
	for id: StringName in BEACON_ORDER:
		var br := MissionBrazier.new()
		br.brazier_id = id
		br.display_name = String(BEACONS[id][0])
		br.name = "Beacon_%s" % String(id)
		br.position = BEACONS[id][1]
		br.flame_target = CITADEL
		nav_region.add_child(br)
		br.lit_up.connect(_on_beacon_lit)
		beacons[id] = br
	if not _SIM.enabled:   # E5M1.V2 placeholders: the ruined bell-tower, the old bridge
		box_prop(Vector3(30.0, 0.0, 30.0), Vector3(2.4, 6.0, 2.4), Color(0.55, 0.52, 0.48))
		box_prop(Vector3(2.0, 0.0, 4.5), Vector3(6.0, 0.3, 2.4), Color(0.50, 0.47, 0.42), 0.6)


# ---------------------------------------------------------------- start state

func _on_navigation_ready() -> void:
	var diff := clampi(mission_difficulty, 0, 2)
	local_type("reiver_chief").max_hp = float(GANNET_HP[diff])   # before any Gannet (a load rebuilds him from it)
	for id: StringName in BEACONS:
		fog.reveal(Unit.Team.PLAYER, BEACONS[id][1], 6.0)
	_setup_champions()
	hero = _make_wizard(Unit.Team.PLAYER)
	_spawn(hero, Unit.Team.PLAYER, VESSA_START)
	_claim_wizard(hero, Unit.Team.PLAYER)
	ItemDrops.ensure_inventory(hero)
	MissionE5Base.young_look(hero, &"young", YOUNG_SCALE)
	hero.spell_cast.connect(_on_vessa_cast)
	hero.level_changed.connect(_on_vessa_level)
	for i in 4:
		var w := _spawn(make_unit("cinder_hand"), Unit.Team.PLAYER, VALEWATCH + Vector3(-3.0 + i * 1.5, 0.0, 5.0))
		w.call(&"command_gather", node_of(Unit.Team.PLAYER, "a" if i < 2 else "b"))
	for i in int(START_GUARDS[diff]):
		_spawn(make_unit("flame_guard"), Unit.Team.PLAYER, ARMY_START + Vector3(-1.5 + i * 1.5, 0.0, 0.0))
	vey = _spawn(make_unit("vey_prime"), Unit.Team.PLAYER, VEY_START)
	mark_scripted(vey)
	vey.death_guard = _vey_guard
	vey.attack_landed.connect(_on_vey_struck)
	for gid: StringName in GUARDS:
		var row: Array = GUARDS[gid]
		guard_groups[gid] = spawn_rows(row[3], row[0], float(row[1]), int(row[2]) as Unit.Team, true)
	for t: Variant in tents:
		guard_groups[StringName("G6_%d" % tents.find(t))] = spawn_rows([["reiver", 2]],
				(t as Node3D).global_position + Vector3(0.0, 0.0, -4.0), 1.5, Unit.Team.ENEMY, true)
	for id: StringName in beacons:
		(beacons[id] as MissionBrazier).lighter = hero
	begin_mission([&"obj_beacons", &"obj_vessa", &"sec_tents"])
	if hud and hud.inventory_bar:
		hud.inventory_bar.visible = false   # D6 items_locked
	selection.select_units([hero])


func _intro() -> void:
	fire_once(&"E1")
	play_cutscene(&"e5m1_valley", _valley_end)


## e5m1_valley end state (also the skip / no-film fallback): Vessa at the start, Vey 2 m east, no orders.
func _valley_end() -> void:
	for id in ["L1", "L2", "L3"]:
		say_l(id)
	if hud:
		hud.show_message(HINT_START, 12.0)
	if camera_rig and hero_alive():
		camera_rig.focus_on(hero.global_position)


# ---------------------------------------------------------------- briefing, objectives

func briefing() -> Dictionary:
	return {
		"title": _title_line(),
		"paragraphs": BRIEFING_PARAGRAPHS.duplicate(),
		"objectives": [objective_text(&"obj_beacons", false), objective_text(&"obj_hold", false)],
		"rule": Loc.sink(objective_text(&"obj_vessa")),
	}


func hold_time() -> float:
	return float(by_difficulty(HOLD_TIME))


func hold_left() -> float:
	return maxf(0.0, hold_ends_at - mission_time()) if hold_ends_at > 0.0 else hold_time()


func farms_standing() -> int:
	return farms.filter(func(f: Variant) -> bool: return is_instance_valid(f) and (f as Building).is_alive()).size()


func tents_standing() -> int:
	return tents.filter(func(t: Variant) -> bool: return is_instance_valid(t) and (t as Building).is_alive()).size()


func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_beacons":
			if with_counter:
				return "Light the beacons of the Vale (%d / 5)" % lit.size()
			return "Light the beacons of the Vale"
		&"obj_hold":
			if with_counter and objective_state("obj_hold") == "active":
				var s := int(ceil(hold_left()))
				return "Hold the Vale until the south watch rides in (%d:%02d)" % [s / 60, s % 60]
			return "Hold the Vale until the south watch rides in"
		&"obj_vessa":
			return "Vessa must survive"
		&"sec_farms":
			if with_counter:
				return "Keep the Millrace farms standing (%d)" % farms_standing()
			return "Keep the Millrace farms standing"
		&"sec_tents":
			if with_counter:
				return "Burn the reivers' tents (%d / 2)" % tents_burned
			return "Burn the reivers' tents"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_beacons":
			var pos: Array = []
			for bid: StringName in BEACON_ORDER:
				if not lit.has(String(bid)):
					pos.append(BEACONS[bid][1])
			return {"counter": lit.size(), "goal": 5, "positions": pos}
		&"obj_hold":
			if objective_state("obj_hold") == "active":
				return {"time_left": hold_left()}
		&"sec_farms":
			return {"counter": farms_standing(), "goal": 3}
		&"sec_tents":
			return {"counter": tents_burned, "goal": 2}
	return {}


# ---------------------------------------------------------------- beacons

func _on_beacon_lit(br: MissionBrazier) -> void:
	var id := String(br.brazier_id)
	if lit.has(id):
		return
	lit.append(id)
	_beacon_sight(id)
	flash_ring(br.global_position, 3.0)
	if is_ending():
		return
	set_objective(&"obj_beacons", "active")
	if fire_once(&"E3"):
		say_l("L5")
		say_l("L6")
		if hud:
			hud.show_message(HINT_BUILD, 12.0)
		_w1_at = maxf(W1_EARLIEST, mission_time() + W1_AFTER_B1)
	match br.brazier_id:
		&"millrace":
			_e7_millrace()
		&"bridge":
			_e8_bridge()
		&"knoll":
			_e10_knoll()
	if lit.size() >= 5:
		_e13_final()


func _beacon_sight(id: String) -> void:
	if _markers.has(id) or not BEACONS.has(StringName(id)):
		return
	_markers[id] = SightMarker.spawn(Unit.Team.PLAYER, BEACONS[StringName(id)][1], BEACON_SIGHT, 0.0, self)


## A beacon catches only while no hostile unit stands within 8 m (its guard must be cleared or drawn off).
func _tick_beacons() -> void:
	for id: StringName in beacons:
		var br := beacons[id] as MissionBrazier
		if br.lit:
			continue
		var blocked := foe_near(br.global_position, BEACON_BLOCK_R) != null
		br.lighter = null if blocked or not hero_alive() else hero
		if not hero_alive():
			continue
		var d := _flat(hero.global_position, br.global_position)
		if d <= NEAR_BEACON_HINT and fire_once(&"E2"):
			say_l("L4")
			if hud:
				hud.show_message(HINT_BEACON, 12.0)
		if blocked and d <= MissionBrazier.LIGHT_RADIUS and mission_time() - _blocked_msg_at > 8.0:
			_blocked_msg_at = mission_time()
			if hud:
				hud.show_message(MSG_BLOCKED, 4.0)


## E7: Millrace lit: L9-L10, the Millrace volunteers (2 Ember Archers), sec_farms, W2.
func _e7_millrace() -> void:
	if not fire_once(&"E7"):
		return
	say_l("L9")
	say_l("L10")
	var f0 := FARMS[0]
	for i in 2:
		_spawn(make_unit("ember_archer"), Unit.Team.PLAYER, f0 + Vector3(-1.0 + i * 2.0, 0.0, -4.0))
	if hud:
		hud.show_message(MSG_VOLUNTEERS, 4.0)
	set_objective(&"sec_farms", "active" if farms_standing() == FARMS.size() else "failed")
	_fire_wave(&"W2")


## E8: Old Bridge lit: L11, W3, the farm raids stop, the camp calls start.
func _e8_bridge() -> void:
	if not fire_once(&"E8"):
		return
	say_l("L11")
	_raid_at = -1.0
	_fire_wave(&"W3")
	_camp_at = mission_time() + CAMP_CALL_EVERY


## E10: the Knoll lit: L13, 2 Blaze Riders ride in from the east edge.
func _e10_knoll() -> void:
	if not fire_once(&"E10"):
		return
	say_l("L13")
	for i in 2:
		var r := _spawn(make_unit("blaze_rider"), Unit.Team.PLAYER, SCOUT_ENTRY + Vector3(0.0, 0.0, -1.5 + i * 3.0))
		r.command_move(BEACONS[&"knoll"][1] + Vector3(4.0, 0.0, -2.0 + i * 2.0))
	if hud:
		hud.show_message(HINT_RIDERS, 10.0)
		hud.show_message(MSG_SCOUTS, 4.0)


## E13: the 5th beacon: L16-L17, obj_hold (1:30), the Final, dusk.
func _e13_final() -> void:
	if not fire_once(&"E13"):
		return
	set_objective(&"obj_beacons", "done")
	say_l("L16")
	say_l("L17")
	hold_ends_at = maxf(mission_time() + hold_time(), float(by_difficulty(DUSK_AT)))
	set_objective(&"obj_hold", "active")
	_apply_dusk()
	_fire_wave(&"FINAL")
	_final_extra_at = maxf(mission_time() + FINAL_EXTRA_AFTER, hold_ends_at - (hold_time() - FINAL_EXTRA_AFTER))


# ---------------------------------------------------------------- waves

## The Final loses 30 % of its units (rounded down, Gannet stays) when both tents burned before it.
func _final_rows(rows: Array) -> Array:
	var out: Array = []
	var tents_done := objective_state("sec_tents") == "done"
	for row: Array in rows:
		var n := int(row[1])
		if clampi(mission_difficulty, 0, 2) == 2 and String(row[0]) == "war_boar" and rows == WAVES[&"FINAL"]:
			n += 1
		out.append([row[0], n])
	if not tents_done:
		return out
	var cut: Array = []
	for row: Array in out:
		var n := int(row[1])
		cut.append([row[0], n - int(floor(float(n) * 0.3))])
	return cut


func _fire_wave(id: StringName) -> void:
	if is_ending():
		return
	if id != &"RAID" and id != &"CAMP":
		if waves_fired.has(String(id)):
			return
		waves_fired.append(String(id))
	match id:
		&"W1":
			fire_once(&"E5")
			say_l("L7")
			if hud:
				hud.show_message(HINT_W1, 12.0)
			for u in spawn_rows(WAVES[&"W1"], SP_SE, 0.0, Unit.Team.ENEMY, false, true):
				order_wave(u as Unit, &"cinder", VALEWATCH)
		&"W2":
			_first_farm_raid()
			for u in spawn_rows(WAVES[&"W2"], SP_W, 0.0, Unit.Team.ENEMY, false, true):
				order_wave(u as Unit, &"farm", FARMS[1])
			_raid_at = mission_time() + RAID_EVERY
		&"RAID":
			_first_farm_raid()
			for u in spawn_rows(WAVES[&"RAID"], SP_W, 0.0, Unit.Team.ENEMY, false, true):
				order_wave(u as Unit, &"farm", FARMS[1])
		&"W3":
			for u in spawn_rows(WAVES[&"W3"], SP_SE, 0.0, Unit.Team.ENEMY, false, true):
				order_wave(u as Unit, &"keep", VALEWATCH)
		&"CAMP":
			for t: Variant in tents:
				if is_instance_valid(t) and (t as Building).is_alive():
					for u in spawn_rows(WAVES[&"CAMP"], (t as Node3D).global_position + Vector3(-3.0, 0.0, -3.0), 0.0,
							Unit.Team.ENEMY, false, true):
						order_wave(u as Unit, &"beacon", (t as Node3D).global_position)
		&"FINAL":
			for u in spawn_rows(_final_rows(WAVES[&"FINAL"]), SP_SE, 0.0, Unit.Team.ENEMY, false, true):
				order_wave(u as Unit, &"hero", hero_pos())
		&"FINAL2":
			_spawn_gannet()   # built deviation: Gannet leads the +40 s group (the hold is a fight, not a duel)
			for u in spawn_rows(_final_rows(WAVES[&"FINAL2"]), SP_SE, 0.0, Unit.Team.ENEMY, false, true):
				order_wave(u as Unit, &"hero", hero_pos())


## The spotlight moment (unit-spotlights.md 2.5): the first raid on the Millrace farms (W2's farm torches).
func _first_farm_raid() -> void:
	if not fire_once(&"E_raid1"):
		return
	show_spotlight()
	if hud:
		hud.show_message(HINT_SPIRE, 12.0)


func _spawn_gannet() -> void:
	var t := local_type("reiver_chief")
	if t == null:
		return
	t.max_hp = float(by_difficulty(GANNET_HP))
	gannet = make_unit("reiver_chief")
	gannet.name = "GannetRook"
	_spawn(gannet, Unit.Team.ENEMY, SP_SE + Vector3(-2.0, 0.0, -2.0))
	mark_scripted(gannet)
	_arm_gannet()
	order_wave(gannet, &"gannet", hero_pos())
	_hook_left = float(by_difficulty(HOOK_CD)) * 0.5


func _arm_gannet() -> void:
	if gannet and is_instance_valid(gannet):
		gannet.death_guard = _gannet_guard


func _gannet_guard(_attacker: Variant) -> bool:
	if gannet == null or not is_instance_valid(gannet):
		return false
	_gannet_flees()
	return true


## E14: Gannet below 40 %: L18, he walks off to SP_SE (untargetable) and despawns; obj_hold done at once.
func _gannet_flees() -> void:
	if gannet_fled or gannet == null or not is_instance_valid(gannet):
		return
	gannet_fled = true
	fire_once(&"E14")
	say_l("L18")
	if hud:
		hud.show_message(MSG_GANNET_FLEES, 4.0)
	_wave_units.erase(gannet)
	set_dormant(gannet, true)
	gannet.set_meta(META_MODE, &"fled")
	gannet.command_move(SP_SE)
	if objective_state("obj_hold") == "active":
		_hold_done()


func _tick_gannet(dt: float) -> void:
	if gannet == null or not is_instance_valid(gannet):
		return
	if gannet_fled:
		if _flat(gannet.global_position, SP_SE) < 3.0 or not gannet.has_move_order():
			gannet.leave_map()
			gannet = null
		return
	if not gannet.is_alive():
		return
	if gannet.hp < gannet.max_hp * GANNET_FLEE:
		_gannet_flees()
		return
	_hook_left -= dt
	if _hook_left > 0.0:
		return
	var target: Unit = null
	if hero_alive() and _flat(hero.global_position, gannet.global_position) <= HOOK_RANGE:
		target = hero
	else:
		var d := HOOK_RANGE
		for u in units_of(Unit.Team.PLAYER, true):
			var dd := _flat(u.global_position, gannet.global_position)
			if dd <= d and u.attack_range >= 4.0:
				d = dd
				target = u
	if target == null:
		_hook_left = 1.0
		return
	_hook_left = float(by_difficulty(HOOK_CD))
	var dir := gannet.global_position - target.global_position
	dir.y = 0.0
	var dist := dir.length()
	if dist > 0.1:
		var pull := minf(HOOK_PULL, maxf(0.0, dist - 1.5))
		target.displace(target.global_position + dir / dist * pull, 0.4)
	target.take_damage(HOOK_DAMAGE, gannet)


func _refresh_wave_unit(u: Unit, mode: StringName, hero_at: Vector3) -> bool:
	match mode:
		&"cinder":
			var w: Unit = null
			var d := INF
			for n in get_tree().get_nodes_in_group(&"units"):
				var c := n as Unit
				if c and c.is_alive() and int(c.team) == Unit.Team.PLAYER and c.is_worker():
					var dd := _flat(c.global_position, u.global_position)
					if dd < d:
						d = dd
						w = c
			if w == null:
				u.set_meta(META_MODE, &"hero")
			elif u.attack_target == null:
				u.command_attack_move(w.global_position)
			return true
		&"farm":
			var f := _nearest_farm(u.global_position)
			if f == null:
				u.set_meta(META_MODE, &"hero")
				return true
			if u.attack_target == null:
				if _flat(u.global_position, f.global_position) < 7.0:
					u.command_attack(f)
				else:
					u.command_attack_move(f.global_position)
			return true
		&"keep":
			if keep == null or not is_instance_valid(keep) or not keep.is_alive():
				u.set_meta(META_MODE, &"hero")
				return true
			if u.attack_target == null:
				if _flat(u.global_position, keep.global_position) < 9.0:
					u.command_attack(keep)
				elif not u.is_attack_moving():
					u.command_attack_move(keep.global_position)
			return true
		&"beacon":
			var to := _nearest_lit(u.global_position)
			if to == Vector3.INF or _flat(u.global_position, to) < 6.0:
				u.set_meta(META_MODE, &"hero")
				return true
			if u.attack_target == null and not u.is_attack_moving():
				u.command_attack_move(to)
			return true
		&"gannet":
			if u.attack_target == null or not u.attack_target is Unit:
				u.command_attack_move(hero_at)
			return true
		&"fled":
			return true
	return false


func _nearest_farm(from: Vector3) -> Building:
	var best: Building = null
	var d := INF
	for f: Variant in farms:
		if is_instance_valid(f) and (f as Building).is_alive():
			var dd := _flat((f as Node3D).global_position, from)
			if dd < d:
				d = dd
				best = f as Building
	return best


func _nearest_lit(from: Vector3) -> Vector3:
	var best := Vector3.INF
	var d := INF
	for id: String in lit:
		var p: Vector3 = BEACONS[StringName(id)][1]
		var dd := _flat(p, from)
		if dd < d:
			d = dd
			best = p
	return best


func _tick_waves() -> void:
	var t := mission_time()
	if _w1_at > 0.0 and t >= _w1_at and not waves_fired.has("W1"):
		_fire_wave(&"W1")
	if _raid_at > 0.0 and t >= _raid_at:
		_raid_at = t + RAID_EVERY
		_fire_wave(&"RAID")
	if _camp_at > 0.0 and t >= _camp_at:
		_camp_at = t + CAMP_CALL_EVERY
		_fire_wave(&"CAMP")
	if _final_extra_at > 0.0 and t >= _final_extra_at:
		_final_extra_at = -1.0
		_camp_at = -1.0
		_fire_wave(&"FINAL2")
	if objective_state("obj_hold") == "active" and t >= hold_ends_at:
		_hold_done()


## Guards (2x leash) walk home when they chased too far.
func _tick_leash() -> void:
	for gid: StringName in guard_groups:
		for g: Variant in guard_groups[gid]:
			if not is_instance_valid(g) or not (g as Unit).is_alive() or not (g as Unit).has_meta(META_HOME):
				continue
			var u := g as Unit
			if _flat(u.global_position, u.get_meta(META_HOME)) > GUARD_LEASH:
				u.command_move(u.get_meta(META_HOME))


# ---------------------------------------------------------------- Old Vey in his prime

func _vey_ok() -> bool:
	return vey != null and is_instance_valid(vey) and vey.is_alive() and not is_dormant(vey)


func _vey_guard(_attacker: Variant) -> bool:
	if vey == null or not is_instance_valid(vey):
		return false
	vey.hp = 1.0
	if _vey_kneel_left <= 0.0:
		_vey_kneel_left = VEY_KNEEL
		vey_kneels += 1
		set_dormant(vey, true)
		vey.command_stop()
		if fire_once(&"E16"):
			say_l("L24")
	return true


## Old Steel: every 3rd strike also hits every other enemy within 2.5 m of the target for 50 % (no spark).
func _on_vey_struck(target: Node3D, amount: float) -> void:
	_vey_strikes += 1
	if _vey_strikes % 3 != 0 or target == null or not is_instance_valid(target):
		return
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u != target and u.is_alive() and vey.is_enemy_of(u) and not is_dormant(u) \
				and _flat(u.global_position, target.global_position) <= SWEEP_R:
			u.take_damage(amount * 0.5, vey)


## The Lesson: Fireball costs 30 instead of 40 within 10 m of Vey (the 10 back right after the cast).
func _on_vessa_cast(spell_id: StringName) -> void:
	if spell_id == &"fireball" and _vey_ok() and hero_alive() and _flat(vey.global_position, hero.global_position) <= LESSON_R:
		hero.mana = minf(hero.get_stat(&"max_mana"), hero.mana + LESSON_REFUND)


func _on_vessa_level(_u: Unit, level: int) -> void:
	if level >= 2 and fire_once(&"E6"):
		say_l("L8")
		if hud:
			hud.show_message(HINT_LEVEL, 12.0)


## The escort brain (19.A2 shape): 3-7 m from Vessa, fights what comes at her, Intercept every 8 s, never a building.
func _tick_vey(dt: float) -> void:
	if vey == null or not is_instance_valid(vey):
		return
	if _vey_kneel_left > 0.0:
		_vey_kneel_left -= dt
		if _vey_kneel_left <= 0.0:
			set_dormant(vey, false)
			vey.death_guard = _vey_guard
			vey.hp = vey.max_hp * VEY_STAND_HP
		return
	if not _vey_ok() or not hero_alive():
		return
	_intercept_left -= dt
	if vey.attack_target is Building:
		vey.command_stop()
	var at := hero.global_position
	if _intercept_left <= 0.0:
		for n in get_tree().get_nodes_in_group(&"units"):
			var e := n as Unit
			if e and e.is_alive() and e.attack_target == hero and vey.is_enemy_of(e) \
					and _flat(e.global_position, vey.global_position) <= INTERCEPT_R:
				var dir := (e.global_position - vey.global_position)
				dir.y = 0.0
				if dir.length() > 1.6:
					vey.displace(e.global_position - dir.normalized() * 1.2, 0.3)
				e.apply_status(&"taunted", 3.0, false, vey)
				vey.command_attack(e)
				_intercept_left = INTERCEPT_EVERY
				break
	var foe := foe_near(at, VEY_GUARD_R)
	if foe != null and foe.team != Unit.Team.NEUTRAL or (foe != null and foe.attack_target != null):
		if vey.attack_target == null or not vey.attack_target is Unit:
			vey.command_attack(foe)
		return
	if vey.attack_target != null and vey.attack_target is Unit and _flat(vey.global_position, at) < VEY_FAR + 4.0:
		return
	var d := _flat(vey.global_position, at)
	if d > VEY_FAR or (d < 1.5 and not vey.has_move_order()):
		var side := Vector3(2.0, 0.0, 1.0).normalized() * VEY_NEAR
		vey.command_move(at + side)


## E11 (the teaching bark): Vessa > 14 m from every own soldier, outside the base ring, for 5 s: L14 (once per 60 s).
func _tick_bark(dt: float) -> void:
	if not hero_alive() or keep == null or not is_instance_valid(keep):
		return
	var p := hero.global_position
	var alone := _flat(p, keep.global_position) > BARK_BASE_R
	if alone:
		for u in units_of(Unit.Team.PLAYER, true):
			if u != vey and _flat(u.global_position, p) <= BARK_ALONE_R:
				alone = false
				break
	_alone_for = _alone_for + dt if alone else 0.0
	if _alone_for >= BARK_DELAY and mission_time() >= _bark_ready_at:
		_bark_ready_at = mission_time() + BARK_EVERY
		_alone_for = 0.0
		bark_count += 1
		fire_once(&"E11")
		say_again("L14")


## Hearth max 1 (spec Start state): a second Hearth site is cancelled with a full refund.
func _tick_hearths() -> void:
	enforce_max(&"fire_hearth", 1, MSG_ONE_HEARTH)


# ---------------------------------------------------------------- farms, tents

func _on_farm_destroyed(_b: Building) -> void:
	farms_burned += 1
	if is_ending():
		return
	if fire_once(&"E18"):
		say_l("L26")
	if objective_state("sec_farms") == "active":
		set_objective(&"sec_farms", "failed")


func _on_tent_destroyed(_b: Building) -> void:
	tents_burned += 1
	if is_ending():
		return
	if fire_once(&"E12"):
		say_l("L15")
	if tents_burned >= TENTS.size():
		set_objective(&"sec_tents", "done")
	else:
		set_objective(&"sec_tents", "active")


# ---------------------------------------------------------------- the end

## E15: the hold is over (90 s, or Gannet fled): e5m1_watch, then the victory.
func _hold_done() -> void:
	if is_ending() or not fire_once(&"E15"):
		return
	victory_time = mission_time()
	set_objective(&"obj_hold", "done")
	if objective_state("sec_farms") == "active":
		set_objective(&"sec_farms", "done" if farms_standing() == FARMS.size() else "failed")
	if objective_state("sec_tents") == "active":
		set_objective(&"sec_tents", "failed")
	set_mission_flag("e5m1_time", int(victory_time))
	set_mission_flag("e5m1_vey_kneels", vey_kneels)
	clear_waves()
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == Unit.Team.ENEMY:
			u.leave_map()   # every reiver leaves for the fens
	if gannet and is_instance_valid(gannet):
		gannet.leave_map()
	play_cutscene(&"e5m1_watch", _watch_end)


func _watch_end() -> void:
	for id in ["L19", "L20", "L21", "L22", "L23"]:
		say_l(id)
	set_objective(&"obj_vessa", "done")
	win(1.0)


func _on_player_hero_fell() -> void:
	fire_once(&"E17")
	say_l("L25")
	set_objective(&"obj_vessa", "failed")
	super()


# ---------------------------------------------------------------- save / load

## The rebuilt mission gets back what lives outside units / objectives: lit beacons (flame, sight), dusk, Gannet's
## guard (a rebuilt Gannet is a plain unit), Vey's kneel.
func load_state(d: Dictionary, nodes: Dictionary = {}) -> void:
	super(d, nodes)
	for id: String in lit:
		var br := beacons.get(StringName(id)) as MissionBrazier
		if br and not br.lit:
			br.light()   # _on_beacon_lit returns early: the id is already in `lit`
		_beacon_sight(id)
	if has_fired(&"E13"):
		_apply_dusk()
	if gannet and is_instance_valid(gannet):
		if gannet_fled:
			gannet.leave_map()
			gannet = null
		else:
			_arm_gannet()
	if vey and is_instance_valid(vey):
		vey.death_guard = _vey_guard
		if _vey_kneel_left > 0.0 and not is_dormant(vey):
			set_dormant(vey, true)


# ---------------------------------------------------------------- every frame

func _physics_process(delta: float) -> void:
	super(delta)
	if not match_started or game_over or world_is_held or save_restoring:
		return
	tick_scripted(delta)
	if is_ending():
		return
	_tick_vey(delta)
	_tick_gannet(delta)
	_fast -= delta
	if _fast <= 0.0:
		_fast = 0.25
		_tick_beacons()
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.5
		_tick_waves()
		_tick_leash()
		_tick_hearths()
		_tick_bark(0.5)
		if hero_alive() and fire_once_near_knoll():
			say_l("L12")
			if hud:
				hud.show_message(HINT_KNOLL, 12.0)
		objectives_changed.emit()
		if hud and mission_hud == null:
			hud.set_objective(_objective_text())


## E9: Vessa within 14 m of the knoll beasts the first time.
func fire_once_near_knoll() -> bool:
	if has_fired(&"E9"):
		return false
	for g: Variant in guard_groups.get(&"G4", []):
		if is_instance_valid(g) and (g as Unit).is_alive() and _flat((g as Unit).global_position, hero.global_position) <= KNOLL_HINT_R:
			return fire_once(&"E9")
	return false
