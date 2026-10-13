class_name MissionE3_03
extends MissionBase
## Episode 3, mission 3 "The Stone's Price" (docs/design/mission-e3-03.md): Malrik comes home to Duskbarrow. The barrow
## candles are out and the city's dead walk as Obren's Wardens toward the Great Crypt where the living shelter. Malrik
## relights the four vigil candles (3 m, 4 s, blocked while a Warden stands within 8 m), the Sexton rises from the
## Gravedigger's Lodge (4th candle or 19:00) and must be laid to rest. The Keystone Shard's power arrives: Heart of the
## Hollow (J / the mission button), every use tightening the stone's hold (100 % = the stone speaks).
## Spotlight: the Nightblood Reaver (an all-melee, fireless enemy: its lifesteal is never halved).
##
## Built deviations (2026-10-07, recorded in the spec's "Built" note):
## - The map is built in code on a 120 x 120 MapInfo (no World Forge `duskbarrow.map`): flat ground, the buildings, the
##   crypt, the barrow doors (decor slabs, no walls), candles and the Lodge at the spec's positions.
## - Heart of the Hollow is mission-side (key J / a mission button; no Inventory active): `stilled` = dazed 8 s (full
##   duration) + armor -50 (x 1.5 damage taken). The Great Crypt's armor 20 is a damage refund; no vigil aura.
## - Gravewarden = the Ruin Warden type scaled (900 HP, armor 20, 34 damage); the Sexton = a scripted placeholder unit.
## - No cine timelines (fallback end states).

const MISSION_ID := &"e3m3"
const MISSION_TITLE := "The Stone's Price"
const MAP_SIZE_M := 120.0
const PLAYER_SEAT := Unit.Team.PLAYER

const MALRIK_START := Vector3(0.0, 0.0, -30.0)
const SEAT_POS := Vector3(0.0, 0.0, -42.0)
const GLOOM_HALL := Vector3(-14.0, 0.0, -40.0)
const HOVELS: Array[Vector3] = [Vector3(14.0, 0.0, -38.0), Vector3(16.0, 0.0, -46.0)]
const NIGHT_SPIRE := Vector3(0.0, 0.0, -24.0)
const MOURNERS := Vector3(0.0, 0.0, -16.0)
## Spec 1 500 / 2 000; doubled-ish as e3m1 (11 Thralls mine ~450 crystals a minute: the spec's ~3 800 by 20:00 is 9 min).
const NODES := [[&"e3m3_seat_a", Vector3(-10.0, 0.0, -51.0), 3000], [&"e3m3_seat_b", Vector3(9.0, 0.0, -51.0), 3000],
		[&"e3m3_ossuary_w", Vector3(-46.0, 0.0, -34.0), 3000], [&"e3m3_ossuary_e", Vector3(46.0, 0.0, -34.0), 3000],
		[&"e3m3_tithe", Vector3(0.0, 0.0, 26.0), 2500]]
const CRYPT_POS := Vector3(0.0, 0.0, 0.0)
const LODGE := Vector3(0.0, 0.0, 46.0)
const SEXTON_RISE := Vector3(0.0, 0.0, 48.0)
## Barrows: id -> [name, door, candle].
const BARROWS := {
	&"B1": ["Lantern Barrow", Vector3(-44.0, 0.0, 0.0), Vector3(-39.0, 0.0, 0.0)],
	&"B2": ["Weeping Barrow", Vector3(44.0, 0.0, 0.0), Vector3(39.0, 0.0, 0.0)],
	&"B3": ["Pauper's Field", Vector3(-34.0, 0.0, 38.0), Vector3(-30.7, 0.0, 34.3)],
	&"B4": ["Bishops' Rest", Vector3(34.0, 0.0, 38.0), Vector3(30.7, 0.0, 34.3)],
}
const CANDLE_RANGE := 3.0
const CANDLE_TIME := 4.0
const CANDLE_BLOCK := 8.0
const SEAL_CRUMBLE := 12.0
const FIRST_OPEN := 90.0
const SECOND_OPEN: Array[float] = [450.0, 360.0, 300.0]
const SPAWN_EVERY: Array[float] = [36.0, 30.0, 25.0]
const SPAWN_EVERY_LATE: Array[float] = [30.0, 25.0, 20.0]
const LATE_AT := 720.0
const SPAWN_MAX: Array[int] = [6, 8, 10]
const SEXTON_FORCED: Array[float] = [1260.0, 1140.0, 1020.0]
## Spec 5 000 / 7 000 / 9 000: a 31-unit army laid it to rest in 30 s in the scripted run (spec ~2:30-3:30).
const SEXTON_HP: Array[float] = [13000.0, 18000.0, 24000.0]
## A candle relights only once its barrow has given up this many of its dead (Wardens from that door killed): the
## barrow must be emptied, not just slipped past (2026-10-07: B1 was relit 13 s after it opened, the run won at 7:16).
const DOOR_KILLS := {&"B1": 10, &"B2": 10, &"B3": 26, &"B4": 26}
const MSG_STILL_FULL := "The barrow is still full of the dead. Lay more of them to rest first."
const CRYPT_HP: Array[float] = [3600.0, 3000.0, 2600.0]
const CRYPT_ARMOR := 20.0
const CRYPT_REGEN_PCT := 0.005
const HEART_COOLDOWN := 45.0
const HEART_R := 14.0
const HEART_DAMAGE := 60.0
const HEART_KNEEL := 8.0
const HOLD_PER_USE := 20.0
const HOLD_PER_DEATH := 0.5
const HOLD_RESET := 60.0
const HELD_SECONDS := 5.0
const FRENZY_SECONDS := 30.0
const TOSS_EVERY := 10.0
const CALL_EVERY := 25.0
const STAGGER := 6.0
const LEVEL_CAP := 7
const NO_SAVE_ESSENCE := 700
const ESSENCE_CAP := 1500
const COUNT_MULT: Array[float] = [0.6, 1.0, 1.4]
const START_CRYSTALS: Array[int] = [550, 400, 300]
const MALRIK_SPELLS := [&"shadow_lance", &"shadow_lance", &"soul_siphon", &"soul_siphon", &"umbral_shroud"]
const DEFEAT_DELAY := 3.0

const SPEAKER_COLORS := {&"malrik": Color(0.7, 0.3, 1.0), &"hush": Color(0.60, 0.50, 0.75),
		&"obren": Color(1.0, 0.80, 0.25), &"shade": Color(0.62, 0.58, 0.70), &"narrator": Color(0.9, 0.85, 0.7)}
const SPEAKER_NAMES := {&"malrik": "Malrik", &"hush": "Mother Hush", &"obren": "Obren", &"shade": "Shade Captain",
		&"narrator": "Narrator"}
const DIALOGUE := [
	[&"narrator", "Duskbarrow. The city of the dead, where Malrik learned to read by tombstone light."],
	[&"malrik", "Every vigil out at once. Someone has been very rude to my dead."],
	[&"shade", "Bishop. The barrows are stirring. The living are in the Great Crypt. All of them."],
	[&"malrik", "Then the living stay in the crypt, and the dead go back to bed."],
	[&"obren", "They are mine now, Bishop. Ask me nicely, and they kneel."],
	[&"malrik", "You raised my dead, and now you sell me the shovel."],
	[&"obren", "Not sell. Lend. You will hardly notice the price."],
	[&"malrik", "Sleep. You did your share of standing."],
	[&"obren", "There. Was that so hard? Again, whenever you like."],
	[&"malrik", "Useful. Do not get comfortable in there."],
	[&"obren", "Half yours, half mine. We share so nicely, you and I."],
	[&"obren", "MINE. Hold still. Let me look out of your eyes."],
	[&"malrik", "Out. OUT. I decide. I have always decided."],
	[&"shade", "The Pauper's Field and the Bishops' Rest are open! Everything is walking!"],
	[&"malrik", "Even the bishops. Of course even the bishops."],
	[&"malrik", "The dead are up, Hush. My dead."],
	[&"hush", "Then they can lie down again. I'll help them."],
	[&"shade", "The crypt doors are cracking! The families are inside!"],
	[&"narrator", "Two barrows sleep. The stone does not like the quiet."],
	[&"obren", "Your father dug these graves, Bishop. Shall I show you what I built from his work?"],
	[&"obren", "Forty years he dug here. Let me give him a body."],
	[&"malrik", "He had one. He wore it out honestly."],
	[&"malrik", "That bell. He rang it every dusk. Stop wearing my father's bell."],
	[&"hush", "Light it, Bishop. Just this once."],
	[&"malrik", "Not yet. Not while it is listening."],
	[&"narrator", "The vigils burned again in Duskbarrow. In the Bishop's pocket, the stone kept count."],
	[&"malrik", "Bury me... somewhere quiet."],
	[&"shade", "The crypt is open... the dead are among the living!"],
]
const BRIEFING_PARAGRAPHS: Array[String] = [
	"Duskbarrow keeps its dead the old way: a candle at every barrow door, lit at dusk by the gravediggers. Two nights ago the candles went out, all four at once, and the dead stood up.",
	"The living of the city have shut themselves inside the Great Crypt. The Bishop's Seat still stands above the Lantern Road. Malrik rode home through two nights to find his own dead walking toward his own people.",
	"Light the vigils again and the dead will lie down. The stone in his pocket says there is a faster way. It is very eager to show him.",
]
const BRIEFING_LINE := "Only Malrik can relight a vigil candle. Clear the barrow first."
const HINT_START := "The barrows will open. Keep the dead away from the Great Crypt, then walk Malrik to each vigil candle."
const HINT_OFFER := "The stone offers its power: J. Wardens near Malrik kneel and the rest are struck. Every use tightens its hold."
const HINT_SEXTON := "The Sexton walks on the crypt. Step out of the gravestone circles."
const HINT_REAVER := "Nightblood Reavers drink: in a long fight with no fire, they never fall."
const MSG_FIRST_OPEN := "The Lantern and Weeping Barrows open."
const MSG_BLOCKED := "The dead won't sleep while they stand over the candle. Clear the barrow first."
const MSG_PATIENCE := "The stone has lost patience."
const MSG_STAGGER := "The Sexton staggers!"
const MSG_FALLS_EARLY := "The Sexton falls. Relight the last vigils."
const BUTTON_HEART := "Heart of the Hollow (J)"
const REFUSE_DEAD := "Dead"
const REFUSE_HELD := "The stone holds you"
const REFUSE_RECHARGING := "Recharging"
const REFUSE_NOT_YET := "Not yet"
const REFUSE_ENDING := "The fight is over"   ## the mission is ending (the victory / defeat delay)

var flag_override: Dictionary = {}

## Read only.
var crypt: Building = null
var candles := {}                      ## barrow id -> true once relit
var doors_open := {}                   ## barrow id -> true while open (and not sealed)
var door_units := {}                   ## barrow id -> living Wardens from that door
var candle_progress := {}              ## barrow id -> 0-1
var door_kills := {}                   ## barrow id -> its Wardens killed (DOOR_KILLS gates the candle)
var stone_hold := 0.0                  ## 0-100
var shard_uses := 0
var seizures := 0
var heart_enabled := false
var heart_left := 0.0
var held_left := 0.0
var frenzy_left := 0.0
var sexton: Unit = null
var sexton_phase := 0                  ## 0 none, 1 walking / fighting, 2 tolled, 3 fallen
var crypt_dipped := false
var no_save_fallback := false
var said: Array[int] = []
var victory_time := -1.0

var _said := {}
var _tick := 0.0
var _spawn_left := {}
var _door_t := -1.0
var _blocked_said := {}
var _full_said := {}
var _faster := false
var _toss_left := TOSS_EVERY
var _call_left := CALL_EVERY
var _stagger_left := 0.0
var _crypt_type: BuildingType
var _grave_type: UnitType
var _sexton_type: UnitType
var _candle_meshes := {}
var _panel: Control
var _last_obj_text := ""


func _init() -> void:
	super()
	player_kingdom = &"shadow"
	enemy_kingdom = &"shadow"
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
	define_objectives([[&"obj_crypt", "primary"], [&"obj_candles", "primary"], [&"obj_sexton", "primary"],
			[&"obj_malrik", "primary"], [&"sec_refuse", "secondary"], [&"sec_whole", "secondary"]])


func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	c.mission_id = MISSION_ID
	c.title = MISSION_TITLE
	c.count_mult = COUNT_MULT.duplicate()
	c.defeat_on_keep_lost = true
	c.keep_lost_message = "The Bishop's Seat has fallen"
	c.tiers_enabled = true
	c.max_tier = 3
	c.bots_upgrade = false
	c.start_tiers = {PLAYER_SEAT: 3}
	c.casters_enabled = true
	c.t3_enabled = true
	c.helpers_enabled = true
	c.helper_call_price = {"crystals": 350, "essence": 200, "time": 60.0}
	c.start_level = 5
	c.level_cap = LEVEL_CAP
	c.start_crystals = START_CRYSTALS.duplicate()
	c.start_essence = 150
	c.instant_loss_on_wizard_death = true
	c.defeat_delay = DEFEAT_DELAY
	c.victory_banner = "VICTORY\nThe dead lie down"
	c.defeat_banner = "DEFEAT"
	c.rewards = CampaignState.MISSION_REWARDS.get(MISSION_ID, {})
	c.spotlight = {"id": &"nightblood_reaver", "trigger": &"start", "key_hint": "Bishop's Seat: C",
			"card": "Nightblood Reaver. A duelist that drinks: the longer the fight, the stronger it stands. Fear fire."}
	return c


func _map_size() -> Vector2:
	return Vector2(MAP_SIZE_M, MAP_SIZE_M)


func _player_start() -> Vector3:
	return MALRIK_START


func _use_map_dressing() -> bool:
	return false


func _title_line() -> String:
	return "Episode 3, Mission 3: %s" % MISSION_TITLE


func _ready() -> void:
	_crypt_type = _make_crypt_type()
	_grave_type = _make_grave_type()
	_sexton_type = _make_sexton_type()
	register_local_building_type(_crypt_type)
	register_local_unit_type(_grave_type)
	register_local_unit_type(_sexton_type)
	super()
	if camera_rig:
		camera_rig.focus_on(MALRIK_START)
	var ev := get_node_or_null(^"/root/Events")
	if ev and ev.has_signal(&"unit_died"):
		ev.unit_died.connect(_on_any_unit_died)


func _make_crypt_type() -> BuildingType:
	var base := BuildingType.find("shadow_hovel")
	if base == null:
		return null
	var t := base.duplicate() as BuildingType
	t.id = &"great_crypt"
	t.display_name = "Great Crypt"
	t.kind = &"crypt"
	t.cost = 0
	t.max_hp = float(by_difficulty(CRYPT_HP))
	t.footprint = Vector2i(4, 4)
	t.counts_for_defeat = false
	if &"pop_bonus" in t:
		t.set(&"pop_bonus", 0)
	t.model_path = ""
	t.body_color = Color(0.36, 0.33, 0.40)
	return t


func _make_grave_type() -> UnitType:
	var base := UnitType.find("ruin_warden")
	var t := (base.duplicate() as UnitType) if base else UnitType.new()
	t.id = &"grave_warden"
	t.display_name = "Gravewarden"
	t.max_hp = 900.0
	t.armor = 20.0
	t.attack_damage = 34.0
	t.attack_cooldown = 2.2
	t.attack_range = 2.2
	t.move_speed = 3.0
	t.kill_xp = 90
	t.radius = maxf(0.6, t.radius * 1.4)
	t.body_height = t.body_height * 1.4
	return t


func _make_sexton_type() -> UnitType:
	var base := UnitType.find("ruin_warden")
	var t := (base.duplicate() as UnitType) if base else UnitType.new()
	t.id = &"sexton"
	t.display_name = "The Sexton"
	t.faction = &"neutral"
	t.max_hp = float(by_difficulty(SEXTON_HP))
	t.armor = 20.0
	t.attack_damage = 70.0
	t.attack_range = 3.5
	t.attack_cooldown = 3.0
	t.move_speed = 1.6
	t.radius = 2.5
	t.body_height = 9.0
	t.aggro_range = 6.0
	t.sight_radius = 18.0
	t.kill_xp = 0
	t.commandable = false
	t.model_scene = null
	t.model_path = ""
	t.body_color = Color(0.32, 0.30, 0.34)
	t.eye_color = Color(1.0, 0.62, 0.2)
	return t


# ---------------------------------------------------------------- the map

func _build_map() -> void:
	for row: Array in NODES:
		_add_crystal_node(StringName(row[0]), row[1], int(row[2]))
	keep = build_grid.spawn_complete(BuildingType.find("shadow_keep"), SEAT_POS, PLAYER_SEAT) as Keep
	build_grid.spawn_complete(BuildingType.find("shadow_barracks"), GLOOM_HALL, PLAYER_SEAT)
	for p in HOVELS:
		build_grid.spawn_complete(BuildingType.find("shadow_hovel"), p, PLAYER_SEAT)
	build_grid.spawn_complete(BuildingType.find("shadow_tower"), NIGHT_SPIRE, PLAYER_SEAT)
	crypt = build_grid.spawn_complete(_crypt_type, CRYPT_POS, PLAYER_SEAT) if _crypt_type else null
	if crypt:
		crypt.name = "GreatCrypt"
		mark_scripted(crypt)
		crypt.damaged.connect(_on_crypt_damaged)
	for id: StringName in BARROWS:
		candles[id] = false
		candle_progress[id] = 0.0
		door_units[id] = []
		_add_barrow_look(id)


func _add_barrow_look(id: StringName) -> void:
	if _SIM.enabled:
		return
	var door := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(3.0, 3.2, 0.6)
	door.mesh = b
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.22, 0.21, 0.24)
	stone.emission_enabled = true
	stone.emission = Color(0.0, 0.0, 0.0)
	door.material_override = stone
	add_child(door)
	door.position = (BARROWS[id][1] as Vector3) + Vector3(0.0, 1.6, 0.0)
	door.look_at_from_position(door.position, Vector3(0.0, 1.6, 0.0))
	door.set_meta(&"door_mat", stone)
	var stand := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.12
	c.bottom_radius = 0.25
	c.height = 1.6
	stand.mesh = c
	var flame := StandardMaterial3D.new()
	flame.albedo_color = Color(0.35, 0.33, 0.30)
	flame.emission_enabled = true
	flame.emission = Color(0.0, 0.0, 0.0)
	stand.material_override = flame
	add_child(stand)
	stand.position = (BARROWS[id][2] as Vector3) + Vector3(0.0, 0.8, 0.0)
	_candle_meshes[id] = [door, stone, flame]


func _paint_barrow(id: StringName) -> void:
	var row: Array = _candle_meshes.get(id, [])
	if row.is_empty():
		return
	var stone := row[1] as StandardMaterial3D
	var flame := row[2] as StandardMaterial3D
	if candles[id]:
		stone.emission = Color(0.0, 0.0, 0.0)
		flame.albedo_color = Color(0.7, 0.4, 1.0)
		flame.emission = Color(0.55, 0.25, 0.9)
	elif doors_open.get(id, false):
		stone.emission = Color(0.9, 0.5, 0.1) * 0.6
	else:
		stone.emission = Color(0.0, 0.0, 0.0)


# ---------------------------------------------------------------- start state

func _on_navigation_ready() -> void:
	for p: Vector3 in [CRYPT_POS, LODGE]:
		fog.reveal(PLAYER_SEAT, p, 12.0)
	for id: StringName in BARROWS:
		fog.reveal(PLAYER_SEAT, BARROWS[id][1], 8.0)
	hero = _make_wizard(PLAYER_SEAT)
	_spawn(hero, PLAYER_SEAT, MALRIK_START)
	_claim_wizard(hero, PLAYER_SEAT)
	ItemDrops.ensure_inventory(hero)
	raise_wizard(hero, 5, MALRIK_SPELLS)
	set_meta(&"campaign_flags", flag_override.duplicate())
	force_artifacts(hero, ["keystone_shard", ""])
	_carry_essence()
	for i in 6:
		var w := _spawn(make_unit("gloom_thrall"), PLAYER_SEAT, SEAT_POS + Vector3(-4.0 + i * 1.5, 0.0, -6.0))
		var n := crystal_nodes.get(&"e3m3_seat_a" if i < 3 else &"e3m3_seat_b") as CrystalNode
		w.call(&"command_gather", n)
	var rows := [["shade", 6], ["nightbolt", 3], ["shadow_knight", 1], ["gloom_deacon", 1]]
	var k := 0
	for row: Array in rows:
		for j in int(row[1]):
			_spawn(make_unit(String(row[0])), PLAYER_SEAT, MOURNERS + Vector3((k % 5) * 1.6 - 3.2, 0.0, (k / 5) * 1.7))
			k += 1
	for u in spawn_group([["ruin_warden", 4]], LODGE + Vector3(0.0, 0.0, -2.0), 3.0, Unit.Team.ENEMY, true):
		_hollow(u as Unit)
		(u as Unit).set_meta(&"lodge", true)
	_add_events()
	begin_mission([&"obj_crypt", &"obj_candles", &"obj_malrik", &"sec_whole"])
	_build_panel()


## Malrik's essence (his track, campaign_state.gd MALRIK_ESSENCE_FLAG); the no-save fallback: 150 + 700.
func _carry_essence() -> void:
	var bank := EssenceBank.for_team(PLAYER_SEAT)
	if bank == null:
		return
	var cs := CampaignState.open(campaign_save_path)
	no_save_fallback = not cs.is_completed(&"e3m2") and flag_override.is_empty()
	var carried := int(flag_override.get(CampaignState.MALRIK_ESSENCE_FLAG,
			cs.flag_value(CampaignState.MALRIK_ESSENCE_FLAG, 0)))
	bank.add(NO_SAVE_ESSENCE if no_save_fallback else carried)


func _hollow(u: Unit) -> void:
	u.add_to_group(&"hollow")
	mark_scripted(u)
	if frenzy_left > 0.0:
		u.add_modifier(&"stone:frenzy", {"attack_damage_pct": 0.25})


# ---------------------------------------------------------------- briefing, objectives

func briefing() -> Dictionary:
	return {
		"title": _title_line(),
		"paragraphs": BRIEFING_PARAGRAPHS.duplicate(),
		"objectives": [objective_text(&"obj_crypt", false), objective_text(&"obj_candles", false),
				objective_text(&"obj_malrik", false), BRIEFING_LINE],
		"rule": Loc.sink(objective_text(&"obj_malrik")),
	}


func candles_lit() -> int:
	var n := 0
	for id: StringName in candles:
		if candles[id]:
			n += 1
	return n


func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_crypt":
			if with_counter and crypt and is_instance_valid(crypt):
				return "The Great Crypt must stand (%d %%)" % int(100.0 * crypt.hp / maxf(1.0, crypt.max_hp))
			return "The Great Crypt must stand"
		&"obj_candles":
			if with_counter:
				var head := "Relight the barrow vigils (%d / 4)" % candles_lit()
				if heart_enabled:
					return "%s\n%s" % [head, "The stone's hold: %d %%" % int(stone_hold)]
				return head
			return "Relight the barrow vigils"
		&"obj_sexton":
			if with_counter and sexton and is_instance_valid(sexton) and sexton.is_alive():
				return "Lay the Sexton to rest (%d %%)" % int(100.0 * sexton.hp / maxf(1.0, sexton.max_hp))
			return "Lay the Sexton to rest"
		&"obj_malrik":
			return "Malrik must survive"
		&"sec_refuse":
			return "Refuse the stone: win without its power"
		&"sec_whole":
			return "Keep the Great Crypt above half"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_crypt":
			if crypt and is_instance_valid(crypt):
				return {"progress": int(crypt.hp), "goal": int(crypt.max_hp), "position": CRYPT_POS}
		&"obj_candles":
			return {"counter": candles_lit(), "goal": 4}
		&"obj_sexton":
			if sexton and is_instance_valid(sexton):
				return {"progress": int(sexton.hp), "goal": int(sexton.max_hp), "marks": [100, 50]}
	return {}


func say_l(n: int) -> void:
	if _said.has(n):
		return
	_said[n] = true
	said.append(n)
	say_line(n)


# ---------------------------------------------------------------- events

## E1: the homecoming (e3m3_homecoming, HOLD 0:20 played as PAUSE; fallback = the camera on Malrik + L1), L2-L4, the hint.
func _intro() -> void:
	fire_once(&"E1")
	play_cutscene(&"e3m3_homecoming", func() -> void:
		if camera_rig and hero_alive():
			camera_rig.focus_on(hero.global_position)
		for n in [1, 2, 3, 4]:
			say_l(n)
		if hud:
			hud.show_message(HINT_START, 10.0))


func _add_events() -> void:
	after(FIRST_OPEN, func() -> void:
		if is_ending():
			return
		fire_once(&"E2")
		_open_door(&"B1")
		_open_door(&"B2")
		if hud:
			hud.show_message(MSG_FIRST_OPEN, 4.0))
	after(float(by_difficulty(SECOND_OPEN)), func() -> void:
		if is_ending():
			return
		fire_once(&"E8")
		_open_door(&"B3")
		_open_door(&"B4")
		say_l(14)
		say_l(15)
		if hud:
			hud.show_message(HINT_REAVER, 8.0))
	after(float(by_difficulty(SEXTON_FORCED)), func() -> void:
		if sexton_phase == 0 and not is_ending():
			if candles_lit() < 4 and hud:
				hud.show_message(MSG_PATIENCE, 4.0)
			_raise_sexton())
	add_event(&"E3", func() -> bool:
		if not hero_alive():
			return false
		for n in get_tree().get_nodes_in_group(&"hollow"):
			var u := n as Unit
			if u and u.is_alive() and not u.has_meta(&"lodge") and _flat(u.global_position, hero.global_position) <= 15.0:
				return true
		return false, _offer)
	var roster := HelperRoster.for_team(PLAYER_SEAT)
	if roster and roster.has_signal(&"helper_ready"):   # HelperRoster has no helper_arrived: Hush ready = arrived
		roster.connect(&"helper_ready", func(_h: Variant = null) -> void:
			if fire_once(&"E9"):
				say_l(16)
				say_l(17))


func _open_door(id: StringName) -> void:
	if candles[id] or doors_open.get(id, false):
		return
	doors_open[id] = true
	_spawn_left[id] = 0.0
	flash_ring(BARROWS[id][1], 3.0)
	_paint_barrow(id)


## E3: the offer (e3m3_offer fallback: L5-L7 + the power enabled, the meter shown, sec_refuse active).
func _offer() -> void:
	play_cutscene(&"e3m3_offer", func() -> void:
		say_l(5)
		say_l(6)
		say_l(7)
		heart_enabled = true
		set_objective(&"sec_refuse", "active")
		set_objective(&"obj_candles", "active")
		if hud:
			hud.show_message(HINT_OFFER, 10.0))


func _build_panel() -> void:
	_panel = mission_button_panel("HeartPanel", [[Loc.t(BUTTON_HEART), func() -> void:
		var r := use_heart()
		if r != "" and hud:
			hud.show_message(r, 3.0)]])


func _unhandled_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k and k.pressed and not k.echo and k.physical_keycode == KEY_J and match_started and not game_over:
		var r := use_heart()
		if r != "" and hud:
			hud.show_message(r, 3.0)
		get_viewport().set_input_as_handled()
		return
	super(event)


# ---------------------------------------------------------------- the barrows

func _wardens_near(at: Vector3, r: float) -> int:
	var n := 0
	for node in get_tree().get_nodes_in_group(&"hollow"):
		var u := node as Unit
		if u and u.is_alive() and _flat(u.global_position, at) <= r:
			n += 1
	return n


func _tick_doors(dt: float) -> void:
	var interval := float(by_difficulty(SPAWN_EVERY_LATE if mission_time() >= LATE_AT else SPAWN_EVERY))
	if _faster:
		interval *= 0.8
	for id: StringName in doors_open:
		if not doors_open[id] or candles[id]:
			continue
		var alive: Array = (door_units[id] as Array).filter(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive())
		door_units[id] = alive
		_spawn_left[id] = float(_spawn_left.get(id, 0.0)) - dt
		if _spawn_left[id] > 0.0:
			continue
		_spawn_left[id] = interval
		var room := int(by_difficulty(SPAWN_MAX)) - alive.size()
		if room <= 0:
			continue
		var units := spawn_wave_at([["ruin_warden", 2]], BARROWS[id][1], Unit.Team.ENEMY,
				func(n: int) -> int: return mini(n, room))
		for u in units:
			_hollow(u as Unit)
			order_wave(u as Unit, &"crypt", CRYPT_POS)
			(u as Unit).died.connect(_on_door_warden_died.bind(id))
			alive.append(u)


func _on_door_warden_died(_x: Unit, id: StringName) -> void:
	door_kills[id] = int(door_kills.get(id, 0)) + 1


## Wardens of barrow `id` to lay to rest before its candle can be relit (DOOR_KILLS through the difficulty count).
func kills_needed(id: StringName) -> int:
	return scaled(int(DOOR_KILLS.get(id, 0)))


func _tick_candles(dt: float) -> void:
	for id: StringName in BARROWS:
		if candles[id]:
			continue
		var at: Vector3 = BARROWS[id][2]
		if not hero_alive() or _flat(hero.global_position, at) > CANDLE_RANGE:
			candle_progress[id] = 0.0
			continue
		if int(door_kills.get(id, 0)) < kills_needed(id):
			if not _full_said.has(id) and hud:
				_full_said[id] = true
				hud.show_message(MSG_STILL_FULL, 4.0)
			candle_progress[id] = 0.0
			continue
		if _wardens_near(at, CANDLE_BLOCK) > 0 or (sexton and is_instance_valid(sexton) and sexton.is_alive() \
				and _flat(sexton.global_position, at) <= CANDLE_BLOCK):
			if not _blocked_said.has(id) and hud:
				_blocked_said[id] = true
				hud.show_message(MSG_BLOCKED, 4.0)
			continue
		candle_progress[id] = float(candle_progress[id]) + dt / CANDLE_TIME
		if candle_progress[id] >= 1.0:
			relight(id)


## A candle relit: the door seals, Wardens within 12 m of it crumble, the Gravewarden call at every door still open.
func relight(id: StringName) -> void:
	if candles[id]:
		return
	candles[id] = true
	doors_open[id] = false
	candle_progress[id] = 1.0
	_paint_barrow(id)
	flash_ring(BARROWS[id][2], 3.0)
	var door: Vector3 = BARROWS[id][1]
	for node in get_tree().get_nodes_in_group(&"hollow"):
		var u := node as Unit
		if u and u.is_alive() and u != sexton and _flat(u.global_position, door) <= SEAL_CRUMBLE:
			u.leave_map()
	set_objective(&"obj_candles", "active")
	match candles_lit():
		1:
			fire_once(&"E4")
			say_l(8)
		2:
			fire_once(&"E11")
			say_l(19)
		3:
			fire_once(&"E12")
			say_l(20)
	for other: StringName in doors_open:
		if doors_open[other] and not candles[other]:
			var g := _spawn(Worker.make_unit(_grave_type), Unit.Team.ENEMY, BARROWS[other][1])
			_hollow(g)
			order_wave(g, &"crypt", CRYPT_POS)
	if candles_lit() >= 4:
		set_objective(&"obj_candles", "done")
		if sexton_phase == 0:
			_raise_sexton()
		elif sexton_phase >= 3:
			_victory()


# ---------------------------------------------------------------- the Great Crypt

func _on_crypt_damaged(amount: float, _attacker: Node3D) -> void:
	if crypt == null or not is_instance_valid(crypt) or not crypt.is_alive():
		return
	crypt.hp = minf(crypt.max_hp, crypt.hp + amount * (1.0 - Unit.armor_multiplier(CRYPT_ARMOR)))   # its armor 20
	if crypt.hp < crypt.max_hp * 0.5 and not crypt_dipped:
		crypt_dipped = true
		fire_once(&"E10")
		say_l(18)
		if objective_state("sec_whole") == "active":
			set_objective(&"sec_whole", "failed")


func _tick_crypt(dt: float) -> void:
	if crypt == null or not is_instance_valid(crypt):
		return
	if not crypt.is_alive():
		if fire_once(&"E17"):
			say_l(28)
			set_objective(&"obj_crypt", "failed")
			lose(DEFEAT_DELAY)
		return
	var enemy_near := false
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == Unit.Team.ENEMY and _flat(u.global_position, CRYPT_POS) <= 12.0:
			enemy_near = true
			break
	if not enemy_near:
		crypt.hp = minf(crypt.max_hp, crypt.hp + crypt.max_hp * CRYPT_REGEN_PCT * dt)


func _refresh_wave_unit(u: Unit, mode: StringName, _hero_at: Vector3) -> bool:
	match mode:
		&"crypt":
			if u.attack_target == null and crypt and is_instance_valid(crypt) and crypt.is_alive():
				if _flat(u.global_position, CRYPT_POS) <= 8.0:
					u.command_attack(crypt)
				elif not u.is_attack_moving():
					u.command_attack_move(CRYPT_POS)
			return true
		&"malrik":
			if u.attack_target == null and hero_alive():
				u.command_attack_move(hero.global_position)
			return true
		&"sexton":
			return true
	return false


# ---------------------------------------------------------------- the stone

## Heart of the Hollow: "" or the refusal ("Dead", "The stone holds you", "Recharging", "Not yet" before the offer).
func use_heart() -> String:
	if is_ending():   # a use in the end delay would never reach the saved flags
		return REFUSE_ENDING
	if not hero_alive():
		return REFUSE_DEAD
	if not heart_enabled:
		return REFUSE_NOT_YET
	if held_left > 0.0:
		return REFUSE_HELD
	if heart_left > 0.0:
		return REFUSE_RECHARGING
	heart_left = HEART_COOLDOWN
	shard_uses += 1
	flash_ring(hero.global_position, HEART_R)
	var dealt := 0.0
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or not u.is_alive() or not Teams.is_hostile(int(u.team), PLAYER_SEAT) or u.team == Unit.Team.NEUTRAL:
			continue
		if _flat(u.global_position, hero.global_position) > HEART_R:
			continue
		if u.is_in_group(&"hollow") and u != sexton:
			u.apply_status(&"dazed", HEART_KNEEL, true)   # `stilled`: kneels, x 1.5 damage taken
			u.add_modifier(&"stone:kneel", {"armor": -50.0})
			get_tree().create_timer(HEART_KNEEL, false).timeout.connect(func() -> void:
				if is_instance_valid(u):
					u.remove_modifier(&"stone:kneel"))
		else:
			var before := u.hp
			u.take_damage(HEART_DAMAGE, hero)
			dealt += maxf(0.0, before - u.hp)
			u.apply_status(&"dazed", 1.0)
	if dealt > 0.0:
		hero.heal(dealt * 0.5)
	hero.add_modifier(&"item:artifact_1:heart", {"spell_power": 30.0})
	get_tree().create_timer(HEART_KNEEL, false).timeout.connect(func() -> void:
		if is_instance_valid(hero):
			hero.remove_modifier(&"item:artifact_1:heart"))
	if fire_once(&"E5"):
		say_l(9)
		say_l(10)
	if objective_state("sec_refuse") == "active":
		set_objective(&"sec_refuse", "failed")
	add_hold(HOLD_PER_USE)
	return ""


func add_hold(amount: float) -> void:
	stone_hold = minf(100.0, stone_hold + amount)
	if stone_hold >= 50.0 and fire_once(&"E6"):
		say_l(11)
		_faster = true
	if stone_hold >= 100.0 and held_left <= 0.0:
		_seize()


## E7: the stone speaks: Malrik held 5 s, every hollow unit +25 % damage for 30 s; then the meter to 60 %.
func _seize() -> void:
	seizures += 1
	held_left = HELD_SECONDS
	fire_once(&"E7")
	if seizures == 1:
		say_l(12)
	if hero_alive():
		hero.apply_status(&"rooted", HELD_SECONDS, true)
		hero.set_cast_lock(HELD_SECONDS)
	frenzy_left = FRENZY_SECONDS
	for n in get_tree().get_nodes_in_group(&"hollow"):
		(n as Unit).add_modifier(&"stone:frenzy", {"attack_damage_pct": 0.25})


func _tick_stone(dt: float) -> void:
	if heart_left > 0.0:
		heart_left = maxf(0.0, heart_left - dt)
	if held_left > 0.0:
		held_left -= dt
		if held_left <= 0.0:
			stone_hold = HOLD_RESET
			if seizures == 1:
				say_l(13)
	if frenzy_left > 0.0:
		frenzy_left -= dt
		if frenzy_left <= 0.0:
			for n in get_tree().get_nodes_in_group(&"hollow"):
				(n as Unit).remove_modifier(&"stone:frenzy")


func _on_any_unit_died(u: Node) -> void:
	var unit := u as Unit
	if unit == null or is_ending():
		return
	if int(unit.team) == PLAYER_SEAT and unit != hero and not unit.is_worker() and not unit is Helper:
		add_hold(HOLD_PER_DEATH)


# ---------------------------------------------------------------- the Sexton

## E13: the Sexton rises at the Lodge (the Lodge watch is buried), walks on the crypt.
func _raise_sexton() -> void:
	if sexton_phase != 0:
		return
	sexton_phase = 1
	fire_once(&"E13")
	for n in get_tree().get_nodes_in_group(&"hollow"):
		if (n as Node).has_meta(&"lodge"):
			(n as Unit).leave_map()
	sexton = _spawn(Worker.make_unit(_sexton_type), Unit.Team.ENEMY, SEXTON_RISE)
	_arm_sexton(sexton)
	sexton.set_meta(META_MODE, &"sexton")
	sexton.command_attack_move(CRYPT_POS + Vector3(0.0, 0.0, 6.0))
	set_objective(&"obj_sexton", "active")
	play_cutscene(&"e3m3_sexton", func() -> void:
		say_l(21)
		say_l(22)
		if hud:
			hud.show_message(HINT_SEXTON, 8.0))


## The Sexton's name, groups and fall hook (idempotent: the rise and a load run it).
func _arm_sexton(u: Unit) -> void:
	u.name = "Sexton"
	u.add_to_group(&"boss")
	u.add_to_group(&"titans")
	u.add_to_group(&"hollow")
	mark_scripted(u)
	if not u.died.is_connected(_on_sexton_fell):
		u.died.connect(_on_sexton_fell)


# ---------------------------------------------------------------- save / load (mission-save-hardening C4-1, C4-9)

## A saved Sexton / Gravewarden comes back from the local types (save_spawn_unit); the Sexton gets its hooks again.
func save_spawned(u: Unit, row: Dictionary) -> void:
	super(u, row)
	if String(row.get("type", "")) == String(_sexton_type.id if _sexton_type else &"sexton"):
		_arm_sexton(u)


func _after_load(_nodes: Dictionary) -> void:
	if sexton and is_instance_valid(sexton) and sexton_phase >= 1:
		_arm_sexton(sexton)
		if sexton_phase == 2 and _stagger_left > 0.0:
			sexton.add_modifier(&"sexton:heart", {"armor": -20.0})
	for id: Variant in door_units:
		for u: Variant in door_units[id]:
			if u is Unit and is_instance_valid(u) and not MissionBase.is_hooked((u as Unit).died, &"_on_door_warden_died"):
				(u as Unit).died.connect(_on_door_warden_died.bind(StringName(str(id))))


func _tick_sexton(dt: float) -> void:
	if sexton_phase < 1 or sexton_phase >= 3 or sexton == null or not is_instance_valid(sexton) or not sexton.is_alive():
		return
	if _stagger_left > 0.0:
		_stagger_left -= dt
		if _stagger_left <= 0.0:
			sexton.remove_modifier(&"sexton:heart")
	if sexton_phase == 1 and sexton.hp <= sexton.max_hp * 0.5:
		_toll()
	if sexton.attack_target == null and _flat(sexton.global_position, CRYPT_POS) > 7.0 and not sexton.is_attack_moving():
		sexton.command_attack_move(CRYPT_POS + Vector3(0.0, 0.0, 6.0))
	elif sexton.attack_target == null and crypt and is_instance_valid(crypt) and crypt.is_alive() \
			and _flat(sexton.global_position, CRYPT_POS) <= 8.0:
		sexton.command_attack(crypt)
	_toss_left -= dt
	if _toss_left <= 0.0:
		_toss_left = TOSS_EVERY
		_tomb_toss()
	_call_left -= dt
	if _call_left <= 0.0:
		_call_left = CALL_EVERY
		for u in spawn_wave_at([["ruin_warden", 4]], sexton.global_position + Vector3(0.0, 0.0, -3.0), Unit.Team.ENEMY):
			_hollow(u as Unit)
			order_wave(u as Unit, &"malrik", hero_pos())


func _tomb_toss() -> void:
	var best := Vector3.INF
	var best_n := 0
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or not u.is_alive() or int(u.team) != PLAYER_SEAT or _flat(u.global_position, sexton.global_position) > 25.0:
			continue
		var c := 0
		for o in get_tree().get_nodes_in_group(&"units"):
			var v := o as Unit
			if v and v.is_alive() and int(v.team) == PLAYER_SEAT and _flat(v.global_position, u.global_position) <= 3.0:
				c += 1
		if u == hero:
			c += 1
		if c > best_n:
			best_n = c
			best = u.global_position
	if best == Vector3.INF:
		return
	var at := best
	flash_ring(at, 3.0)
	get_tree().create_timer(1.5, false).timeout.connect(func() -> void:
		if sexton == null or not is_instance_valid(sexton) or not sexton.is_alive() or is_ending():
			return
		for n in get_tree().get_nodes_in_group(&"units"):
			var u := n as Unit
			if u and u.is_alive() and int(u.team) == PLAYER_SEAT and _flat(u.global_position, at) <= 3.0:
				u.take_damage(60.0, sexton))


## E14: Mourning Toll (once, at 50 %): r 12 daze, then a 6 s stagger at x 1.25 damage taken.
func _toll() -> void:
	sexton_phase = 2
	fire_once(&"E14")
	say_l(23)
	if hud:
		hud.show_message(MSG_STAGGER, 4.0)
	flash_ring(sexton.global_position, 12.0)
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == PLAYER_SEAT and _flat(u.global_position, sexton.global_position) <= 12.0:
			u.apply_status(&"dazed", 1.0)
	sexton.apply_status(&"dazed", STAGGER, true)
	sexton.add_modifier(&"sexton:heart", {"armor": -20.0})   # armor 20 -> 0, then x 1.25 = armor -25 net
	_stagger_left = STAGGER


func _on_sexton_fell(_u: Unit) -> void:
	if is_ending():
		return
	sexton_phase = 3
	set_objective(&"obj_sexton", "done")
	if candles_lit() >= 4:
		_victory()
	elif hud:
		hud.show_message(MSG_FALLS_EARLY, 5.0)


## E15: every hollow unit crumbles, e3m3_rest, victory 2 s after it.
func _victory() -> void:
	if not fire_once(&"E15"):
		return
	victory_time = mission_time()
	clear_waves()
	for n in get_tree().get_nodes_in_group(&"hollow"):
		var u := n as Unit
		if u and u.is_alive():
			u.leave_map()
	_record_flags()
	play_cutscene(&"e3m3_rest", func() -> void:
		say_l(24)
		say_l(25)
		say_l(26)
		set_objective(&"obj_crypt", "done")
		set_objective(&"obj_malrik", "done")
		if objective_state("sec_refuse") == "active":
			set_objective(&"sec_refuse", "done")
		if objective_state("sec_whole") == "active":
			set_objective(&"sec_whole", "done")
		win(2.0))


func _record_flags() -> void:
	set_mission_flag("e3m3_shard_uses", shard_uses)
	set_mission_flag("e3m3_seizures", seizures)
	set_mission_flag("e3m3_time", int(victory_time))
	add_track_counter("shadow_stone_uses", shard_uses)
	var bank := EssenceBank.for_team(PLAYER_SEAT)
	var essence := bank.essence if bank else 0
	if shard_uses == 0:
		essence += 300
	if not crypt_dipped:
		essence += 200
	set_mission_flag(CampaignState.MALRIK_ESSENCE_FLAG, mini(ESSENCE_CAP, essence / 2))


func _on_player_hero_fell() -> void:
	fire_once(&"E16")
	say_l(27)
	set_objective(&"obj_malrik", "failed")
	super()


# ---------------------------------------------------------------- every frame

func _physics_process(delta: float) -> void:
	super(delta)
	if not match_started or game_over or world_is_held:
		return
	tick_scripted(delta)
	if is_ending():
		return
	_tick_candles(delta)
	_tick_stone(delta)
	_tick_sexton(delta)
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.5
		var now := mission_time()
		_tick_doors(clampf(now - _door_t, 0.0, 60.0) if _door_t >= 0.0 else 0.5)   # mission time (skips count)
		_door_t = now
		_tick_crypt(0.5)
		var t := "%s|%s|%s" % [objective_text(&"obj_crypt"), objective_text(&"obj_candles"), objective_text(&"obj_sexton")]
		if t != _last_obj_text:
			_last_obj_text = t
			objectives_changed.emit()
			if hud and mission_hud == null:
				hud.set_objective(_objective_text())
