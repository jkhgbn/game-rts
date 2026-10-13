class_name MissionE5_02
extends MissionE5Base
## Episode 5, mission 2 "Burn a Door" (docs/design/mission-e5-02.md): a flashback. Vessa at fifteen, her first command,
## besieges Rookhold, Gannet Rook's black-timber fort in the fens. Her weakness is the rule: running into the reeds
## without her army springs an ambush; waiting for it spots the band. Her strength is the other rule: wood burns (fire
## sources do double damage to every Rookhold building), and a wall is only a door she has not burned yet. Sergeant
## Ashby (commandable, never dies) drills the Ember Archers into volleys. Spotlight: the Ember Archer.
##
## Built deviations (2026-10-08, from the spec):
## - Rookhold is the main.gd generator look with seed 5102; the palisade is a ring of 4 m timber blocks (32 plain
##   Buildings, 600 HP) around (34, 34) with the Rook Gate on the north-west block (22, 22) and the Postern on the east
##   one (50, 34); the watchtowers stand 1 m inside the spec spots (21, 31) / (31, 21) so they clear the ring. A burned
##   piece rebakes the navmesh (BuildGrid). Gates never open: sallies and the Postern raids step out beside their gate.
## - Wood x2: every Rookhold building takes its damage again when the attacker is a fire source (Vessa: Fireball,
##   scorch, her bolts; an Ash Hurler; a drilled Ember Archer).
## - Drill / volley as an aura: while 4+ Ember Archers stand within 10 m of Ashby they carry +25 % damage
##   (`mission:drill`) and their arrows burn (fire source); no shared volley timing.
## - Hidden bands are dormant and invisible until the first player soldier (or Vessa) comes within 12 m of their reed
##   field; then they spring on Vessa (ring r 6, taunted on her for 6 s) or are spotted where they hid.
## - Reivers / slingers / war-boars / Gannet are the e5m1 mission-local types (Gannet 1 100 HP here); Ashby is a
##   flame_guard copy (450 HP, armor 10, 16 damage, pop 0), wounded at 0 HP: gone 60 s, back at the field camp at 50 %.
## - Hearth max 2 (a third site is refunded).
## - Tuning (the army-first sim reached the gate with ~30 pop by 9:00 and burned the Nest in seconds): camp nodes 1 200,
##   the Nest 2 200 / 3 200 / 4 000 HP, the garrison 6 Reivers + 3 Slingers, the Final's Postern group 5 + 2.
## - Fen-wet timber (rush floor): the Nest does not burn past half before NEST_DRY_AT (12:00 / 14:00 / 16:00); the tent
##   calls go on until then and after the Final they come for Vessa. A Causeway rush with the start army had burned the
##   gate by 2:30 and the Nest by 5:41 (tests/test_e5m2_rush_sim.gd must not win before 14:00 play time).

const MISSION_ID := &"e5m2"
const MISSION_TITLE := "Burn a Door"
const MAP_SEED := 5102

const VESSA_START := Vector3(-32.0, 0.0, -32.0)
const ASHBY_START := Vector3(-30.0, 0.0, -32.0)
const ARMY_START := Vector3(-26.0, 0.0, -30.0)
const FIELD_CAMP := Vector3(-40.0, 0.0, -40.0)
const EMBER_HALL := Vector3(-28.0, 0.0, -44.0)
const NODES := [[&"rk_camp_a", Vector3(-50.0, 0.0, -34.0), 1200], [&"rk_camp_b", Vector3(-34.0, 0.0, -52.0), 1200],
		[&"rk_dyke", Vector3(-6.0, 0.0, -42.0), 1500]]
const CAUSEWAY: Array[Vector3] = [Vector3(-26.0, 0.0, -26.0), Vector3(22.0, 0.0, 22.0)]
const LONG_DYKE: Array[Vector3] = [Vector3(-26.0, 0.0, -40.0), Vector3(40.0, 0.0, -40.0), Vector3(50.0, 0.0, -10.0),
		Vector3(52.0, 0.0, 24.0)]
## Reed field id -> [name, centre, radius].
const REEDS := {
	&"R1": ["Near Reeds", Vector3(-14.0, 0.0, -12.0), 9.0],
	&"R2": ["Heron Pools", Vector3(2.0, 0.0, 2.0), 9.0],
	&"R3": ["Gatereeds", Vector3(12.0, 0.0, 13.0), 7.0],
}
const BANDS := {
	&"R1": [["reiver", 4]],
	&"R2": [["reiver", 3], ["reiver_slinger", 2]],
	&"R3": [["reiver", 4], ["war_boar", 1]],
}
const FORT := Vector3(34.0, 0.0, 34.0)
const FORT_R := 16.0                 ## inside the ring
const GATE := Vector3(22.0, 0.0, 22.0)
const POSTERN := Vector3(50.0, 0.0, 34.0)
const GATE_OUT := Vector3(16.0, 0.0, 16.0)
const POSTERN_OUT := Vector3(56.0, 0.0, 34.0)
const TOWERS: Array[Vector3] = [Vector3(21.0, 0.0, 31.0), Vector3(31.0, 0.0, 21.0)]
const NEST := Vector3(38.0, 0.0, 40.0)
const TENTS: Array[Vector3] = [Vector3(30.0, 0.0, 40.0), Vector3(43.0, 0.0, 29.0)]
const GRAIN := Vector3(35.0, 0.0, 28.0)
const SP_FEN := Vector3(56.0, 0.0, 56.0)
const GANNET_HOME := Vector3(34.0, 0.0, 33.0)
const GATE_TOP := Vector3(26.0, 0.0, 26.0)

const TRIGGER_R := 12.0
const HINT_R := 18.0
const SPRING_RING := 6.0
const SPRING_NEAR := 10.0
const SPRING_FEWER: Array[int] = [2, 4, 5]     ## springs with fewer than this many soldiers within 10 m of Vessa
const SPRING_FOCUS: Array[float] = [4.0, 6.0, 8.0]
const DRILL_R := 10.0
const DRILL_MIN := 4
const DRILL_BONUS := 0.25
const W1_AT := 270.0
const TAUNT_AT := 480.0
const TAUNT_TIME := 8.0
const TENT_CALL_FROM := 360.0
const TENT_CALL_EVERY := 90.0
const TENT_CALL_SLOW := 150.0
const TENT_EXTRA_MAX := 12
const SALLY_GATE := 0.60
const FINAL_NEST := 0.50
const NEST_DRY_AT: Array[float] = [720.0, 840.0, 960.0]   ## the Nest's fen-wet timber won't burn past half before this
const FINAL_EXTRA_AFTER := 20.0
const HORN_R := 12.0
const HORN_TIME := 8.0
const GANNET_FLEE := 0.25
const ASHBY_BACK := 60.0
const GUARD_LEASH := 14.0
const DEFEAT_DELAY := 3.0
const LEVEL_CAP := 4
const COUNT_MULT: Array[float] = [0.6, 1.0, 1.4]
const START_CRYSTALS: Array[int] = [400, 300, 250]
const GATE_HP: Array[float] = [1800.0, 2400.0, 3000.0]
const POSTERN_HP: Array[float] = [1000.0, 1400.0, 1800.0]
const NEST_HP: Array[float] = [2200.0, 3200.0, 4000.0]
const GANNET_HP: Array[float] = [850.0, 1100.0, 1400.0]
const PALISADE_HP := 600.0
const YOUNG_SCALE := 0.9
const FIRE_SOURCES: Array[StringName] = [&"ash_hurler"]

const GUARDS := {
	&"G1a": [Vector3(17.0, 0.0, 25.0), 1.5, [["reiver", 2]]],
	&"G1b": [Vector3(25.0, 0.0, 17.0), 1.5, [["reiver", 2]]],
	&"G2": [Vector3(33.0, 0.0, 35.0), 2.5, [["reiver", 6], ["reiver_slinger", 3]]],
}
const WAVES := {
	&"W1": [["reiver", 3], ["war_boar", 1]],
	&"S1": [["reiver", 5], ["reiver_slinger", 2], ["war_boar", 2]],
	&"TENT": [["reiver", 2]],
	&"FINAL2": [["reiver", 5], ["reiver_slinger", 2]],
}

const SPEAKER_COLORS := {&"vessa": Color(1.0, 0.45, 0.1), &"ashby": Color(0.95, 0.60, 0.35),
		&"gannet": Color(0.62, 0.55, 0.40), &"narrator": Color(0.9, 0.85, 0.7)}
const SPEAKER_NAMES := {&"vessa": "Vessa", &"ashby": "Sergeant Ashby", &"gannet": "Gannet Rook", &"narrator": "Narrator"}
## The spec's 25 lines (data/voice/lines/e5m2.json): LINE_IDS[n - 1] = id of line n.
const LINE_IDS: Array[String] = ["L1", "L2", "L3", "L4", "L5", "L6", "L7", "L8", "L9", "L10", "L11", "L12", "L13",
		"L14", "L15", "L16", "L17", "L18", "L19", "L20", "L21", "L22", "L23", "L24", "L25"]
const DIALOGUE := [
	[&"narrator", "Three summers on, the reivers built a fort in the fens. Vessa was sent to knock."],
	[&"ashby", "Sergeant Ashby, my lady. Vey says I'm to keep you alive. He says it's a full-time job."],
	[&"vessa", "Vey worries. I've been practising. Give me a wall and I'll burn a door through it."],
	[&"ashby", "Yes, my lady. With the army, my lady. The army's the bit that walks behind you."],
	[&"ashby", "Reeds, my lady. Lovely place to hide a knife. Let the lads go in first."],
	[&"gannet", "Little match! Three years, and you still run in alone!"],
	[&"vessa", "Okay. OKAY. Bad idea. Very bad idea!"],
	[&"ashby", "There! In the reeds! That's what waiting buys you, my lady."],
	[&"gannet", "Burn my tents, would you? I'll have your diggers and their shovels too."],
	[&"ashby", "Hurlers! Now we're talking. They throw farther than those towers can shoot."],
	[&"gannet", "Come on, match! Come and knock! I'm right here! Just you!"],
	[&"vessa", "One tower down! Ashby, did you see? Write it down somewhere!"],
	[&"gannet", "Out, boys! Knock the fire-throwers flat!"],
	[&"vessa", "See? A door! I said there'd be a door!"],
	[&"ashby", "There already was a door, my lady. It had a latch."],
	[&"ashby", "You're glowing, my lady. More than usual, I mean."],
	[&"gannet", "My nest! My lovely nest! The horn, boys! Blow the horn!"],
	[&"gannet", "Keep the fort! Keep the fens! I'm keeping my neck!"],
	[&"narrator", "Rookhold burned until morning. So, by accident, did the grain it had stolen."],
	[&"vessa", "Ashby. That was the grain. That was the grain we came here to take back."],
	[&"ashby", "It was, my lady. It's toast now. Very good toast."],
	[&"vessa", "The Master's going to say it. I know he is. \"Fire that will not wait...\""],
	[&"ashby", "\"...burns its own house.\" Yes, my lady. We've all heard him say it."],
	[&"ashby", "Just a scratch! Carry on, my lady, I'll catch you up!"],
	[&"vessa", "I should have... waited..."],
]
const BRIEFING_PARAGRAPHS: Array[String] = [
	"Winter, the truce. Vessa laughs at something nobody else heard. Ashby, grey now, knows exactly which day she means.",
	"Three summers after the Vale of Bells, Gannet Rook was back: a fort of black timber in the southern fens, Rookhold, and in it the grain of half the south border. The Master sent his youngest apprentice to fetch it back.",
	"Vessa was fifteen. She had an army, a sergeant called Ashby, and one piece of advice from Vey: wait for your soldiers. She was sure she would remember it.",
]
const BRIEFING_BOYS := "The miller's boys from the Vale of Bells, three years older, march with her."
const HINT_START := "Rookhold is south-east. The Causeway is short but runs through the reeds. The Long Dyke goes round."
const HINT_REEDS := "Reeds hide ambushes. Send soldiers in first, or walk Vessa in with at least 4 of them."
const HINT_SHOP := "Shop: walk Vessa within 12 m of the camp or the Ember Hall and press T."
const HINT_DRILL := "Sergeant Ashby drills the archers: within 10 m of him, 4 or more Ember Archers loose together. Their burning arrows hit wood twice as hard."
const HINT_HURLER := "Ash Hurlers throw 12 m, the watchtowers shoot 11. Wood burns: Fireball, Hurlers and burning volleys deal double damage to it."
const HINT_KINDLE := "Ctrl+E learns Kindle: E makes nearby soldiers strike and run faster."
const MSG_AMBUSH := "Ambush!"
const MSG_SPOTTED := "Ambush spotted in the reeds!"
const MSG_ASHBY_BACK := "Sergeant Ashby is back at the field camp"
const MSG_GANNET_FLEES := "Gannet Rook flees into the fens"
const MSG_TWO_HEARTHS := "The field camp has room for two Hearths"
const MSG_WET := "The Nest's timber is fen-wet: it won't burn past half before {time}"

## Read only.
var ashby: Unit = null
var gannet: Unit = null
var gannet_fled := false
var band_units := {}                    ## reed id -> Array of units
var band_state := {}                    ## reed id -> "hidden" / "sprung" / "spotted"
var bands_sprung := 0
var bands_spotted := 0
var palisade: Array = []                ## timber blocks (Building), gates excluded
var rook_gate: Building = null
var postern: Building = null
var towers: Array = []
var nest: Building = null
var tents: Array = []
var towers_burned := 0
var breach_at := Vector3.INF             ## where the first door was burned
var guard_groups := {}
var waves_fired: Array[String] = []
var tent_extra: Array = []
var victory_time := -1.0
var ashby_wounds := 0

var _tick := 0.0
var _tent_call_at := -1.0
var _final_extra_at := -1.0
var _taunt_back_at := -1.0
var _ashby_back_left := 0.0
var _horn_left := 0.0
var _wet_msg_at := -100.0
var _drilled: Array = []
var _palisade_type: BuildingType
var _gate_type: BuildingType
var _postern_type: BuildingType
var _tower_type: BuildingType
var _nest_type: BuildingType
var _tent_type: BuildingType
var _camp_type: BuildingType


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
	define_objectives([[&"obj_door", "primary"], [&"obj_nest", "primary"], [&"obj_vessa", "primary"],
			[&"sec_patience", "secondary"], [&"sec_towers", "secondary"]])
	_make_types()


func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	MissionE5Base.e5_config(c)
	c.mission_id = MISSION_ID
	c.title = MISSION_TITLE
	c.count_mult = COUNT_MULT.duplicate()
	c.easy_skip_types = [&"war_boar"]
	c.defeat_on_keep_lost = true
	c.keep_lost_message = "The field camp has fallen"
	c.start_level = 2
	c.start_spells = [&"fireball", &"ember_step"]
	c.start_spell_points = 0
	c.level_cap = LEVEL_CAP
	c.start_crystals = START_CRYSTALS.duplicate()
	c.start_essence = 150
	c.defeat_delay = DEFEAT_DELAY
	c.victory_banner = "VICTORY\nRookhold burns"
	c.defeat_banner = "DEFEAT"
	c.rewards = CampaignState.MISSION_REWARDS.get(MISSION_ID, {})
	c.spotlight = {"id": &"ember_archer", "trigger": &"manual", "key_hint": "Ember Hall: X",
			"card": "Ember Archer. Alone, a bow. Drilled, a volley: keep four together behind the Guards."}
	return c


func _make_types() -> void:
	local_unit("magpie", "reiver", "Reiver", {"aggro_range": 8.0, "kill_xp": 20, "commandable": false,
			"body_color": Color(0.36, 0.33, 0.24)})
	local_unit("nightbolt", "reiver_slinger", "Reiver Slinger", {"max_hp": 70.0, "attack_damage": 9.0,
			"attack_range": 9.0, "aggro_range": 10.0, "cost": 0, "pop": 0, "kill_xp": 25, "commandable": false,
			"body_color": Color(0.40, 0.36, 0.26)})
	local_unit("bristleback", "war_boar", "War-boar", {"neutral_leash": false, "aggro_range": 8.0, "kill_xp": 30,
			"commandable": false})
	local_unit("magpie", "reiver_chief", "Gannet Rook", {"max_hp": 1100.0, "armor": 10.0, "attack_damage": 22.0,
			"attack_cooldown": 1.2, "move_speed": 5.2, "aggro_range": 10.0, "kill_xp": 0, "commandable": false,
			"body_color": Color(0.45, 0.38, 0.22)})
	local_unit("flame_guard", "ashby_sergeant", "Sergeant Ashby", {"max_hp": 450.0, "armor": 10.0,
			"attack_damage": 16.0, "attack_cooldown": 1.1, "move_speed": 5.0, "sight_radius": 11.0, "cost": 0, "pop": 0,
			"kill_xp": 0, "commandable": true})
	_camp_type = MissionE5Base.local_building("fire_keep", "fire_keep", "Field Camp", 2000.0, true)
	if _camp_type:
		_camp_type.pop_bonus = 20
	_palisade_type = _wood_type("reiver_palisade", "Rookhold Palisade", PALISADE_HP, Vector2i(2, 2), 3.6)
	_gate_type = _wood_type("reiver_gate", "Rook Gate", 2400.0, Vector2i(2, 2), 4.4)
	_postern_type = _wood_type("reiver_postern", "Postern", 1400.0, Vector2i(2, 2), 4.0)
	_nest_type = _wood_type("rook_nest", "The Rook's Nest", 2400.0, Vector2i(3, 3), 5.0)
	_tent_type = MissionE5Base.local_building("shadow_hovel", "reiver_tent", "Reiver Tent", 450.0)
	var tb := BuildingType.find("shadow_tower")
	if tb:
		_tower_type = tb.duplicate() as BuildingType
		_tower_type.id = &"reiver_watchtower"
		_tower_type.display_name = "Reiver Watchtower"
		_tower_type.max_hp = 600.0
		_tower_type.attack_damage = 14.0
		_tower_type.attack_range = 11.0
		_tower_type.attack_cooldown = 1.5
		_tower_type.cost = 0
		_tower_type.max_count = 0
		_tower_type.counts_for_defeat = false


## A plain timber Building type (no model: the placeholder box in black timber), not counted for defeat.
static func _wood_type(id: String, display: String, hp: float, footprint: Vector2i, height: float) -> BuildingType:
	var t := BuildingType.new()
	t.id = StringName(id)
	t.display_name = display
	t.faction = &"neutral"
	t.kind = &"wood"
	t.max_hp = hp
	t.footprint = footprint
	t.height = height
	t.sight_radius = 6.0
	t.body_color = Color(0.20, 0.16, 0.12)
	t.color = Color(0.30, 0.22, 0.14)
	t.counts_for_defeat = false
	return t


func _map_size() -> Vector2:
	return Vector2(120.0, 120.0)


func _player_start() -> Vector3:
	return VESSA_START


func _title_line() -> String:
	return "Episode 5, Mission 2: %s" % MISSION_TITLE


func _ground_spots() -> Array[Vector4]:
	return [Vector4(FIELD_CAMP.x, FIELD_CAMP.z, 12.0, 0.0), Vector4(FORT.x, FORT.z, 13.0, 0.0)]


func _ready() -> void:
	super()
	# fen_noon stand-in: overcast noon
	tint_light(Color(0.92, 0.92, 0.88), 0.85, -60.0, Color(0.66, 0.68, 0.66), Color(0.52, 0.56, 0.60),
			Color(0.80, 0.80, 0.76))
	if camera_rig:
		camera_rig.focus_on(VESSA_START)


# ---------------------------------------------------------------- seats

func start_position(_team: int) -> Vector3:
	return VESSA_START


func base_center(_team: int) -> Vector3:
	return FIELD_CAMP


func node_of(_team: int, suffix: String) -> CrystalNode:
	var id := &"rk_dyke" if suffix == "dyke" else StringName("rk_camp_" + suffix)
	var v: Variant = crystal_nodes.get(id)
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


# ---------------------------------------------------------------- the map

## The palisade's 4 m blocks: FORT + 4 (i, j) with i^2 + j^2 in 13..18 (a closed ring ~16 m out).
static func palisade_spots() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for i in range(-4, 5):
		for j in range(-4, 5):
			var r2 := i * i + j * j
			if r2 >= 11 and r2 <= 18:
				out.append(FORT + Vector3(4.0 * i, 0.0, 4.0 * j))
	return out


func _build_map() -> void:
	var clearings: Array = [[VESSA_START, 8.0], [FIELD_CAMP, 16.0], [FORT, 22.0], [SP_FEN, 5.0], [POSTERN_OUT, 4.0],
			[GATE_OUT, 5.0]]
	for row: Array in NODES:
		clearings.append([row[1], 7.0])
	for id: StringName in REEDS:
		clearings.append([REEDS[id][1], float(REEDS[id][2]) + 2.0])
	var lanes: Array = [[CAUSEWAY[0], CAUSEWAY[1], 4.0], [FIELD_CAMP, CAUSEWAY[0], 5.0], [VESSA_START, LONG_DYKE[0], 4.0],
			[EMBER_HALL, LONG_DYKE[0], 4.0]]
	for i in LONG_DYKE.size() - 1:
		lanes.append([LONG_DYKE[i], LONG_DYKE[i + 1], 4.0])
	lanes.append([LONG_DYKE[3], POSTERN_OUT, 4.0])
	lanes.append([POSTERN_OUT, SP_FEN, 4.0])
	scatter_props(MAP_SEED, clearings, lanes, 12, 18)
	for row: Array in NODES:
		_add_crystal_node(StringName(row[0]), row[1], int(row[2]))
	keep = build_grid.spawn_complete(_camp_type, FIELD_CAMP, Unit.Team.PLAYER) as Keep
	if keep:
		keep.name = "FieldCamp"
		seat_keeps[Unit.Team.PLAYER] = keep
	seat_bases[Unit.Team.PLAYER] = FIELD_CAMP
	var hall := build_grid.spawn_complete(BuildingType.find("fire_barracks"), EMBER_HALL, Unit.Team.PLAYER)
	if hall:
		hall.name = "EmberHall"
	var diff := clampi(mission_difficulty, 0, 2)
	_gate_type.max_hp = float(GATE_HP[diff])
	_postern_type.max_hp = float(POSTERN_HP[diff])
	_nest_type.max_hp = float(NEST_HP[diff])
	for p in palisade_spots():
		var piece: Building
		if _flat(p, GATE) < 1.0:
			piece = _wood(_gate_type, p)
			rook_gate = piece
			piece.name = "RookGate"
			piece.damaged.connect(_on_gate_damaged.bind(piece))
		elif _flat(p, POSTERN) < 1.0:
			piece = _wood(_postern_type, p)
			postern = piece
			piece.name = "Postern"
			piece.damaged.connect(_on_gate_damaged.bind(piece))
		else:
			piece = _wood(_palisade_type, p)
			palisade.append(piece)
		piece.destroyed.connect(_on_wall_burned)
	for p in TOWERS:
		var t := _wood(_tower_type, p)
		towers.append(t)
		t.destroyed.connect(_on_tower_destroyed)
	nest = _wood(_nest_type, NEST)
	nest.name = "RookNest"
	nest.destroyed.connect(_on_nest_destroyed)
	nest.damaged.connect(_on_nest_damaged)
	for p in TENTS:
		var t := _wood(_tent_type, p)
		tents.append(t)
	if not _SIM.enabled:
		box_prop(GRAIN, Vector3(3.0, 2.2, 2.6), Color(0.62, 0.52, 0.30))
		for id: StringName in REEDS:
			ground_disc(REEDS[id][1], float(REEDS[id][2]), Color(0.42, 0.48, 0.22, 0.45))


## A Rookhold building (team ENEMY, scripted) that burns twice as fast under fire.
func _wood(type: BuildingType, at: Vector3) -> Building:
	var b := build_grid.spawn_complete(type, at, Unit.Team.ENEMY)
	mark_scripted(b)
	b.set_meta(&"e5m2_wood", true)
	b.damaged.connect(_on_wood_damaged.bind(b))
	return b


# ---------------------------------------------------------------- start state

func _on_navigation_ready() -> void:
	var diff := clampi(mission_difficulty, 0, 2)
	local_type("reiver_chief").max_hp = float(GANNET_HP[diff])
	for p: Vector3 in [CAUSEWAY[0], CAUSEWAY[1], FORT, GATE, POSTERN] + LONG_DYKE:
		fog.reveal(Unit.Team.PLAYER, p, 8.0)
	for p in palisade_spots():
		fog.reveal(Unit.Team.PLAYER, p, 3.0)
	_setup_champions()
	hero = _make_wizard(Unit.Team.PLAYER)
	_spawn(hero, Unit.Team.PLAYER, VESSA_START)
	_claim_wizard(hero, Unit.Team.PLAYER)
	ItemDrops.ensure_inventory(hero)
	MissionE5Base.young_look(hero, &"young", YOUNG_SCALE)
	hero.level_changed.connect(_on_vessa_level)
	for i in 5:
		var w := _spawn(make_unit("cinder_hand"), Unit.Team.PLAYER, FIELD_CAMP + Vector3(-3.0 + i * 1.5, 0.0, 5.0))
		w.call(&"command_gather", node_of(Unit.Team.PLAYER, "a" if i < 3 else "b"))
	var rows: Array = [["flame_guard", 4 + (2 if diff == 0 else 0)], ["ember_archer", 3 if diff == 2 else 4]]
	if bool(_save_flags().get("e5m1_farms_saved", false)):
		rows.append(["ember_archer", 2])   # the miller's boys, three years older
	var k := 0
	for row: Array in rows:
		for i in int(row[1]):
			_spawn(make_unit(String(row[0])), Unit.Team.PLAYER, ARMY_START + Vector3(-3.0 + (k % 5) * 1.5, 0.0, (k / 5) * 1.6))
			k += 1
	ashby = _spawn(make_unit("ashby_sergeant"), Unit.Team.PLAYER, ASHBY_START)
	ashby.name = "SergeantAshby"
	ashby.death_guard = _ashby_guard
	for gid: StringName in GUARDS:
		var g: Array = GUARDS[gid]
		guard_groups[gid] = spawn_rows(g[2], g[0], float(g[1]), Unit.Team.ENEMY, true)
	for i in tents.size():
		guard_groups[StringName("G3_%d" % i)] = spawn_rows([["reiver_slinger", 1]], TENTS[i] + Vector3(0.0, 0.0, -3.0),
				0.0, Unit.Team.ENEMY, true)
	_spawn_gannet()
	for id: StringName in BANDS:
		var rows_b: Array = (BANDS[id] as Array).duplicate(true)
		if id == &"R3" and diff == 2:
			rows_b.append(["war_boar", 1])
		var units := spawn_rows(rows_b, REEDS[id][1], 3.0, Unit.Team.ENEMY, false)
		for u: Variant in units:
			_hide(u as Unit)
		band_units[id] = units
		band_state[id] = "hidden"
	_tent_call_at = TENT_CALL_FROM
	begin_mission([&"obj_door", &"obj_vessa", &"sec_patience", &"sec_towers"])
	selection.select_units([hero])


func _save_flags() -> Dictionary:
	var cs := CampaignState.open(campaign_save_path)
	return cs.flags.duplicate()


func _spawn_gannet() -> void:
	gannet = make_unit("reiver_chief")
	if gannet == null:
		return
	gannet.name = "GannetRook"
	_spawn(gannet, Unit.Team.ENEMY, GANNET_HOME)
	mark_scripted(gannet)
	gannet.set_meta(META_HOME, GANNET_HOME)
	_guards.append(gannet)
	gannet.death_guard = _gannet_guard


func _hide(u: Unit) -> void:
	set_dormant(u, true)
	u.visible = false


func _intro() -> void:
	fire_once(&"E1")
	play_cutscene(&"e5m2_rookhold", _rookhold_end)


## e5m2_rookhold end state: Vessa at the start, Ashby 2 m east, the army at its spot, the bands hidden.
func _rookhold_end() -> void:
	for id in ["L1", "L2", "L3", "L4"]:
		say_l(id)
	if hud:
		hud.show_message(HINT_START, 12.0)
	if camera_rig and hero_alive():
		camera_rig.focus_on(hero.global_position)


# ---------------------------------------------------------------- briefing, objectives

func briefing() -> Dictionary:
	var paras := BRIEFING_PARAGRAPHS.duplicate()
	if bool(_save_flags().get("e5m1_farms_saved", false)):
		paras[2] = "%s %s" % [paras[2], BRIEFING_BOYS]
	return {
		"title": _title_line(),
		"paragraphs": paras,
		"objectives": [objective_text(&"obj_door", false), objective_text(&"obj_nest", false)],
		"rule": Loc.sink(objective_text(&"obj_vessa")),
	}


func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_door":
			return "Burn a door into Rookhold"
		&"obj_nest":
			if with_counter and mission_time() < nest_dry_at() and objective_state("obj_nest") == "active":
				var s := int(nest_dry_at())
				return "Burn the Rook's Nest (wet until %d:%02d)" % [s / 60, s % 60]
			return "Burn the Rook's Nest"
		&"obj_vessa":
			return "Vessa must survive"
		&"sec_patience":
			if with_counter:
				return "Don't let an ambush catch Vessa alone (spotted %d / 3)" % bands_spotted
			return "Don't let an ambush catch Vessa alone"
		&"sec_towers":
			if with_counter:
				return "Burn the watchtowers (%d / 2)" % towers_burned
			return "Burn the watchtowers"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_door":
			return {"position": GATE}
		&"obj_nest":
			if nest and is_instance_valid(nest):
				return {"progress": int(100.0 * (1.0 - nest.hp / maxf(1.0, nest.max_hp))), "goal": 100, "position": NEST}
		&"sec_patience":
			return {"counter": bands_spotted, "goal": 3}
		&"sec_towers":
			return {"counter": towers_burned, "goal": 2}
	return {}


# ---------------------------------------------------------------- wood, drill

## D3: a fire source (Vessa, an Ash Hurler, a drilled Ember Archer) burns wood twice: the hit lands again (no attacker).
func _on_wood_damaged(amount: float, attacker: Node3D, b: Building) -> void:
	if attacker == null or not is_instance_valid(attacker) or not is_instance_valid(b) or not b.is_alive():
		return
	if is_fire_source(attacker):
		b.take_damage(amount, null)


func is_fire_source(n: Node3D) -> bool:
	if n == hero:
		return true
	var u := n as Unit
	if u == null or u.unit_type == null:
		return false
	if FIRE_SOURCES.has(u.unit_type.id):
		return true
	return u.unit_type.id == &"ember_archer" and _drilled.has(u)


## D5 (aura form): 4+ Ember Archers within 10 m of Ashby gain +25 % damage and burning arrows.
func _tick_drill() -> void:
	var near: Array = []
	if ashby and is_instance_valid(ashby) and ashby.is_alive() and not is_dormant(ashby):
		for u in units_of(Unit.Team.PLAYER, true):
			if u.unit_type and u.unit_type.id == &"ember_archer" and _flat(u.global_position, ashby.global_position) <= DRILL_R:
				near.append(u)
	if near.size() < DRILL_MIN:
		near.clear()
	for u: Variant in _drilled:
		if is_instance_valid(u) and not near.has(u):
			(u as Unit).remove_modifier(&"mission:drill")
	for u: Variant in near:
		if not _drilled.has(u):
			(u as Unit).add_modifier(&"mission:drill", {"attack_damage_pct": DRILL_BONUS})
	_drilled = near
	if not near.is_empty() and fire_once(&"E6"):
		show_spotlight()
		if hud:
			hud.show_message(HINT_DRILL, 12.0)


# ---------------------------------------------------------------- the reeds

func _tick_reeds() -> void:
	var soldiers := units_of(Unit.Team.PLAYER, true)
	var movers: Array = soldiers.duplicate()
	if hero_alive():
		movers.append(hero)
	for id: StringName in REEDS:
		var c: Vector3 = REEDS[id][1]
		if not has_fired(&"E2"):
			for u: Variant in movers:
				if _flat((u as Unit).global_position, c) <= HINT_R:
					fire_once(&"E2")
					say_l("L5")
					if hud:
						hud.show_message(HINT_REEDS, 12.0)
					break
		if band_state[id] != "hidden":
			continue
		var first := false
		for u: Variant in movers:
			if _flat((u as Unit).global_position, c) <= TRIGGER_R:
				first = true
				break
		if not first:
			continue
		var vessa_in := hero_alive() and _flat(hero.global_position, c) <= TRIGGER_R
		var guard := 0
		if hero_alive():
			for s in soldiers:
				if _flat(s.global_position, hero.global_position) <= SPRING_NEAR:
					guard += 1
		if vessa_in and guard < int(by_difficulty(SPRING_FEWER)):
			_spring(id)
		else:
			_spot(id)


func _band_alive(id: StringName) -> Array[Unit]:
	var out: Array[Unit] = []
	for v: Variant in band_units.get(id, []):
		if is_instance_valid(v) and (v as Unit).is_alive():
			out.append(v as Unit)
	return out


## The band springs: a ring r 6 around Vessa, they attack only her for 6 s. sec_patience fails.
func _spring(id: StringName) -> void:
	band_state[id] = "sprung"
	bands_sprung += 1
	var units := _band_alive(id)
	var at := hero.global_position
	for i in units.size():
		var u := units[i]
		var a := TAU * float(i) / maxf(1.0, float(units.size()))
		var p := at + Vector3(cos(a) * SPRING_RING, 0.0, sin(a) * SPRING_RING)
		set_dormant(u, false)
		u.visible = true
		u.global_position = p
		u.apply_status(&"taunted", float(by_difficulty(SPRING_FOCUS)), true, hero)
		u.command_attack(hero)
		order_wave(u, &"hero", at)
	flash_ring(at, SPRING_RING)
	if hud:
		hud.show_message(MSG_AMBUSH, 4.0)
	if fire_once(&"E3"):
		say_l("L6")
		say_l("L7")
	if objective_state("sec_patience") == "active":
		set_objective(&"sec_patience", "failed")


## The band is spotted where it hid and attack-moves to the nearest player unit.
func _spot(id: StringName) -> void:
	band_state[id] = "spotted"
	bands_spotted += 1
	for u in _band_alive(id):
		set_dormant(u, false)
		u.visible = true
		order_wave(u, &"nearest", u.global_position)
	if hud:
		hud.show_message(MSG_SPOTTED, 4.0)
	if fire_once(&"E4"):
		say_l("L8")
	if objective_state("sec_patience") == "active":
		set_objective(&"sec_patience", "active")


# ---------------------------------------------------------------- waves

func _fire_wave(id: StringName, at := Vector3.INF) -> void:
	if is_ending():
		return
	if id != &"TENT":
		if waves_fired.has(String(id)):
			return
		waves_fired.append(String(id))
	match id:
		&"W1":
			fire_once(&"E5")
			say_l("L9")
			if hud:
				hud.show_message(HINT_SHOP, 12.0)
			for u in spawn_rows(WAVES[&"W1"], POSTERN_OUT, 0.0, Unit.Team.ENEMY, false, true):
				order_wave(u as Unit, &"cinder", LONG_DYKE[3])
		&"S1":
			fire_once(&"E10")
			say_l("L13")
			var out := GATE_OUT if at == Vector3.INF or _flat(at, GATE) <= _flat(at, POSTERN) else POSTERN_OUT
			if at != Vector3.INF and _flat(at, GATE) > 8.0 and _flat(at, POSTERN) > 8.0:
				out = FORT + (at - FORT).normalized() * (FORT_R + 4.0)
			for u in spawn_rows(WAVES[&"S1"], out, 0.0, Unit.Team.ENEMY, false, true):
				order_wave(u as Unit, &"sally", out)
		&"TENT":
			tent_extra = tent_extra.filter(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive())
			for t: Variant in tents:
				if not is_instance_valid(t) or not (t as Building).is_alive() or tent_extra.size() >= TENT_EXTRA_MAX:
					continue
				for u in spawn_rows(WAVES[&"TENT"], (t as Node3D).global_position + Vector3(0.0, 0.0, -3.0), 0.0,
						Unit.Team.ENEMY, false, true):
					var unit := u as Unit
					tent_extra.append(unit)
					if has_fired(&"E13"):
						order_wave(unit, &"hero", hero_pos())
						continue
					unit.set_meta(META_HOME, GANNET_HOME + Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(-3.0, 3.0)))
					_guards.append(unit)
					unit.command_move(unit.get_meta(META_HOME))
		&"FINAL2":
			for u in spawn_rows(WAVES[&"FINAL2"], POSTERN_OUT, 0.0, Unit.Team.ENEMY, false, true):
				order_wave(u as Unit, &"hero", hero_pos())


func _refresh_wave_unit(u: Unit, mode: StringName, hero_at: Vector3) -> bool:
	match mode:
		&"cinder":
			var best: Unit = null
			var d := INF
			for c in units_of(Unit.Team.PLAYER):
				if c.is_worker():
					var dd := _flat(c.global_position, u.global_position)
					if dd < d:
						d = dd
						best = c
			if best == null:
				u.set_meta(META_MODE, &"hero")
			elif u.attack_target == null:
				u.command_attack_move(best.global_position)
			return true
		&"nearest":
			if u.attack_target == null:
				var best: Unit = null
				var d := INF
				for c in units_of(Unit.Team.PLAYER):
					var dd := _flat(c.global_position, u.global_position)
					if dd < d:
						d = dd
						best = c
				if best:
					u.command_attack_move(best.global_position)
			return true
		&"sally":
			if u.attack_target == null or not u.attack_target is Unit:
				var target: Unit = null
				for want: StringName in [&"ash_hurler", &"ember_archer"]:
					var d := INF
					for c in units_of(Unit.Team.PLAYER, true):
						if c.unit_type and c.unit_type.id == want:
							var dd := _flat(c.global_position, u.global_position)
							if dd < d:
								d = dd
								target = c
					if target:
						break
				u.command_attack_move(target.global_position if target else hero_at)
			return true
		&"fled":
			return true
	return false


# ---------------------------------------------------------------- the fort

func _on_gate_damaged(_amount: float, _attacker: Node3D, g: Building) -> void:
	if is_ending() or not is_instance_valid(g):
		return
	if g == rook_gate and g.hp < g.max_hp * SALLY_GATE:
		_fire_wave(&"S1", g.global_position)


## Any piece of the ring burned (palisade block, Rook Gate, Postern): obj_door (E11), and the sally if not yet.
func _on_wall_burned(b: Building) -> void:
	if is_ending():
		return
	var at := b.global_position
	_fire_wave(&"S1", at)
	if objective_state("obj_door") == "active":
		breach_at = at
		_door_burned()


func _door_burned() -> void:
	if not fire_once(&"E11"):
		return
	set_objective(&"obj_door", "done")
	play_cutscene(&"e5m2_door", _door_end)


## e5m2_door end state: the 3 nearest soldiers stand 4 m inside the breach with their old orders cleared; Vessa's red
## banner in the breach (a pole prop, decor).
func _door_end() -> void:
	say_l("L14")
	say_l("L15")
	if objective_state("obj_nest") == "":
		set_objective(&"obj_nest", "active")
	var inward := (FORT - breach_at)
	inward.y = 0.0
	inward = inward.normalized() if inward.length() > 0.1 else Vector3(1.0, 0.0, 1.0).normalized()
	var soldiers := units_of(Unit.Team.PLAYER, true)
	soldiers.sort_custom(func(a: Unit, b: Unit) -> bool: return _flat(a.global_position, breach_at) < _flat(b.global_position, breach_at))
	for i in mini(3, soldiers.size()):
		var u := soldiers[i]
		if u == ashby:
			continue
		u.command_stop()
		u.command_move(breach_at + inward * 4.0 + Vector3(float(i) - 1.0, 0.0, 0.0))
	if not _SIM.enabled:
		var pole := box_prop(breach_at + inward * 1.0, Vector3(0.12, 3.2, 0.12), Color(0.35, 0.25, 0.15))
		if pole:
			pole.name = "VessaBanner"
			var cloth := MeshInstance3D.new()
			var cm := BoxMesh.new()
			cm.size = Vector3(0.9, 0.6, 0.04)
			cloth.mesh = cm
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.85, 0.15, 0.08)
			cloth.material_override = mat
			pole.add_child(cloth)
			cloth.position = Vector3(0.5, 2.8, 0.0)


func _on_tower_destroyed(_b: Building) -> void:
	towers_burned += 1
	if is_ending():
		return
	if fire_once(&"E9"):
		say_l("L12")
	set_objective(&"sec_towers", "done" if towers_burned >= TOWERS.size() else "active")


func nest_dry_at() -> float:
	return float(by_difficulty(NEST_DRY_AT))


func _on_nest_damaged(_amount: float, _attacker: Node3D) -> void:
	if is_ending() or nest == null or not is_instance_valid(nest):
		return
	var floor_hp := nest.max_hp * FINAL_NEST
	if mission_time() < nest_dry_at() and nest.hp < floor_hp:
		nest.heal(floor_hp - nest.hp)   # wet timber: the hit does not take it past half (damaged comes before the death check)
		if hud and mission_time() - _wet_msg_at > 10.0:
			_wet_msg_at = mission_time()
			var s := int(nest_dry_at())
			hud.show_message(Loc.t(MSG_WET, {"time": "%d:%02d" % [s / 60, s % 60]}), 4.0)
	if nest.hp <= nest.max_hp * FINAL_NEST + 1.0:
		_final()


## E13: the Nest below 50 %: L17, Gannet's War Horn, every reiver inside goes for Vessa; +20 s the Postern group
## (not sent when both towers burned before).
func _final() -> void:
	if not fire_once(&"E13"):
		return
	say_l("L17")
	_horn_left = HORN_TIME
	if gannet and is_instance_valid(gannet) and gannet.is_alive() and not gannet_fled:
		for u in units_of(Unit.Team.ENEMY):
			if _flat(u.global_position, gannet.global_position) <= HORN_R:
				u.add_modifier(&"mission:war_horn", {"attack_cooldown_pct": -0.20})
	for u in units_of(Unit.Team.ENEMY):
		if _flat(u.global_position, FORT) <= FORT_R + 2.0 and u != gannet:
			_guards.erase(u)
			order_wave(u, &"hero", hero_pos())
	if gannet and is_instance_valid(gannet) and not gannet_fled:
		_guards.erase(gannet)
		order_wave(gannet, &"hero", hero_pos())
	if objective_state("sec_towers") != "done":
		_final_extra_at = mission_time() + FINAL_EXTRA_AFTER


func _on_nest_destroyed(_b: Building) -> void:
	if is_ending() or not fire_once(&"E15"):
		return
	victory_time = mission_time()
	if objective_state("obj_door") == "active":
		set_objective(&"obj_door", "done")
	set_objective(&"obj_nest", "done")
	if objective_state("sec_patience") == "active":
		set_objective(&"sec_patience", "done")
	if objective_state("sec_towers") == "active":
		set_objective(&"sec_towers", "failed")
	set_mission_flag("e5m2_time", int(victory_time))
	set_mission_flag("e5m2_bands_sprung", bands_sprung)
	clear_waves()
	for u in units_of(Unit.Team.ENEMY):
		u.leave_map()
	for id: StringName in band_units:
		for v: Variant in band_units[id]:
			if is_instance_valid(v) and (v as Unit).is_alive():
				(v as Unit).leave_map()
	if gannet and is_instance_valid(gannet):
		gannet.leave_map()
	play_cutscene(&"e5m2_morning", _morning_end)


func _morning_end() -> void:
	for id in ["L19", "L20", "L21", "L22", "L23"]:
		say_l(id)
	set_objective(&"obj_vessa", "done")
	win(1.0)


# ---------------------------------------------------------------- Gannet

func _gannet_guard(_attacker: Variant) -> bool:
	if gannet == null or not is_instance_valid(gannet):
		return false
	_gannet_flees()
	return true


## E14: Gannet below 25 %: L18, he slips out of the Postern to the fens (untargetable) and is gone.
func _gannet_flees() -> void:
	if gannet_fled or gannet == null or not is_instance_valid(gannet):
		return
	gannet_fled = true
	fire_once(&"E14")
	say_l("L18")
	if hud:
		hud.show_message(MSG_GANNET_FLEES, 4.0)
	_wave_units.erase(gannet)
	_guards.erase(gannet)
	set_dormant(gannet, true)
	gannet.set_meta(META_MODE, &"fled")
	gannet.global_position = POSTERN_OUT
	gannet.command_move(SP_FEN)


func _tick_gannet() -> void:
	if gannet == null or not is_instance_valid(gannet):
		return
	if gannet_fled:
		if _flat(gannet.global_position, SP_FEN) < 3.0 or not gannet.has_move_order():
			gannet.leave_map()
			gannet = null
		return
	if gannet.is_alive() and gannet.hp < gannet.max_hp * GANNET_FLEE:
		_gannet_flees()
		return
	var t := mission_time()
	if t >= TAUNT_AT and fire_once(&"E8"):
		say_l("L11")
		if not has_fired(&"E13"):
			gannet.set_meta(META_HOME, GATE_TOP)
			gannet.command_move(GATE_TOP)
			_taunt_back_at = t + TAUNT_TIME
	if _taunt_back_at > 0.0 and t >= _taunt_back_at:
		_taunt_back_at = -1.0
		if not has_fired(&"E13"):
			gannet.set_meta(META_HOME, GANNET_HOME)
			gannet.command_move(GANNET_HOME)


# ---------------------------------------------------------------- Ashby

func _ashby_guard(_attacker: Variant) -> bool:
	if ashby == null or not is_instance_valid(ashby):
		return false
	ashby.hp = 1.0
	if _ashby_back_left <= 0.0:
		_ashby_wounded()
	return true


## Wounded: he kneels and fades (no death), walks out of the field camp 60 s later at 50 % HP. L24 the first time.
func _ashby_wounded() -> void:
	ashby_wounds += 1
	_ashby_back_left = ASHBY_BACK
	set_dormant(ashby, true)
	ashby.command_stop()
	ashby.visible = false
	if fire_once(&"E16"):
		say_l("L24")


func _tick_ashby(dt: float) -> void:
	if ashby == null or not is_instance_valid(ashby) or _ashby_back_left <= 0.0:
		return
	_ashby_back_left -= dt
	if _ashby_back_left > 0.0:
		return
	var at := keep.spawn_point() if keep and is_instance_valid(keep) and keep.is_alive() else FIELD_CAMP
	ashby.global_position = at
	set_dormant(ashby, false)
	ashby.visible = true
	ashby.death_guard = _ashby_guard
	ashby.hp = ashby.max_hp * 0.5
	if hud:
		hud.show_message(MSG_ASHBY_BACK, 4.0)


func _on_vessa_level(_u: Unit, level: int) -> void:
	if level >= 4 and fire_once(&"E12"):
		say_l("L16")
		if hud:
			hud.show_message(HINT_KINDLE, 12.0)


func _on_player_hero_fell() -> void:
	fire_once(&"E17")
	say_l("L25")
	set_objective(&"obj_vessa", "failed")
	super()


# ---------------------------------------------------------------- ticks

func _tick_events() -> void:
	var t := mission_time()
	if t >= W1_AT and not waves_fired.has("W1"):
		_fire_wave(&"W1")
	if _tent_call_at > 0.0 and t >= _tent_call_at:
		_tent_call_at = t + (TENT_CALL_SLOW if objective_state("sec_towers") == "done" else TENT_CALL_EVERY)
		_fire_wave(&"TENT")
	if _final_extra_at > 0.0 and t >= _final_extra_at:
		_final_extra_at = -1.0
		_fire_wave(&"FINAL2")
	if not has_fired(&"E7"):
		for u in units_of(Unit.Team.PLAYER, true):
			if u.unit_type and u.unit_type.id == &"ash_hurler":
				fire_once(&"E7")
				say_l("L10")
				if hud:
					hud.show_message(HINT_HURLER, 12.0)
				break
	if _horn_left > 0.0:
		_horn_left -= 0.5
		if _horn_left <= 0.0:
			for u in units_of(Unit.Team.ENEMY):
				u.remove_modifier(&"mission:war_horn")
	enforce_max(&"fire_hearth", 2, MSG_TWO_HEARTHS)


func _tick_leash() -> void:
	for gid: StringName in guard_groups:
		for g: Variant in guard_groups[gid]:
			if not is_instance_valid(g) or not (g as Unit).is_alive() or not (g as Unit).has_meta(META_HOME):
				continue
			var u := g as Unit
			if u.has_meta(META_MODE):
				continue
			if _flat(u.global_position, u.get_meta(META_HOME)) > GUARD_LEASH:
				u.command_move(u.get_meta(META_HOME))


# ---------------------------------------------------------------- save / load

## The rebuilt start hides every band and Ashby is up: put back what the save says (decided bands awake and seen,
## a wounded Ashby away, Gannet's guard, the drill bonus).
func load_state(d: Dictionary, nodes: Dictionary = {}) -> void:
	super(d, nodes)
	for id: StringName in band_units:
		if String(band_state.get(id, "hidden")) == "hidden":
			continue
		for v: Variant in band_units[id]:
			if is_instance_valid(v) and (v as Unit).is_alive():
				if is_dormant(v):
					set_dormant(v as Unit, false)
				(v as Unit).visible = true
	if ashby and is_instance_valid(ashby):
		restore_guard(ashby, _ashby_guard)
		if _ashby_back_left > 0.0:
			set_dormant(ashby, true)
			ashby.visible = false
	if gannet and is_instance_valid(gannet):
		if gannet_fled:
			gannet.leave_map()
			gannet = null
		else:
			restore_guard(gannet, _gannet_guard)
	# C5-7: the saved `mission:drill` modifiers stay on their archers: _drilled lists exactly those, so the next
	# _tick_drill takes the bonus off the ones out of Ashby's reach.
	_drilled.clear()
	for u in units_of(Unit.Team.PLAYER, true):
		if u.unit_type and u.unit_type.id == &"ember_archer" and u.has_modifier(&"mission:drill"):
			_drilled.append(u)


# ---------------------------------------------------------------- every frame

func _physics_process(delta: float) -> void:
	super(delta)
	if not match_started or game_over or world_is_held or save_restoring:
		return
	tick_scripted(delta)
	if is_ending():
		return
	_tick_ashby(delta)
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.5
		_tick_reeds()
		_tick_drill()
		_tick_gannet()
		_tick_events()
		_tick_leash()
		objectives_changed.emit()
		if hud and mission_hud == null:
			hud.set_objective(_objective_text())
