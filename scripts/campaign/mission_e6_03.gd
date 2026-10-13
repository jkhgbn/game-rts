class_name MissionE6_03
extends MissionE6Base
## Episode 6, mission 3 "The Year Nothing Grew" (docs/design/mission-e6-03.md): thirty-two winters ago, fifteen-year-old
## Ysolde keeps four seed-gardens alive under the Evenmead snow through three frost nights while frost wolves come down
## from the north ridge; young Maelis keeps the Well Garden. At spring the Master finds her ("show me again").
## Spotlight: the Thornling (N1, 3:30).
##
## Built deviations (2026-10-09, from the spec):
## - Evenmead in winter is the main.gd generator look (150 x 120, seed 34, snow theme) with the spec table's positions;
##   no evenmead.map layout, no frozen-river decal, no Lost Caches, the Larkholt cottages are placeholder boxes.
## - Seed-gardens are scripted PLAYER targets (SeedGarden, Life 500, radius 2.5). Tending is "a Sprigling standing within
##   3 m of the garden" (move them onto it) instead of the gather order; a tender mines nothing while it stands there.
## - Wild Bloom heals a garden within 6 m of its centre +36 Life / s for 5 s (180, the spec's x 3).
## - Frostfang / Old Whitepelt are local Moonpelt Direwolf copies (scale 0.55 / 1.0) with the seed-hunger brain; Old
##   Whitepelt's Pounce / Hamstring are the Direwolf's own abilities when the copy keeps them.
## - Young Maelis is the helper_maelis Helper at level 3 holding an invisible anchor at the Well Garden; when that
##   garden is lost she escorts Ysolde. A fall hides her 40 s.

const MISSION_ID := &"e6m3"
const MISSION_TITLE := "The Year Nothing Grew"
const MAP_SEED := 34

const YSOLDE_START := Vector3(-24.0, 0.0, 40.0)
const KEEP_POS := Vector3(-32.0, 0.0, 48.0)
const HALL_POS := Vector3(-44.0, 0.0, 40.0)
const ARMY_START := Vector3(-22.0, 0.0, 36.0)
const NODES := [[&"e6y_a", Vector3(-41.0, 0.0, 44.0), 1500], [&"e6y_b", Vector3(-36.0, 0.0, 56.0), 1500],
		[&"e6y_west", Vector3(-56.0, 0.0, 26.0), 2000]]
const WEST_HALL_SPOT := Vector3(-50.0, 0.0, 20.0)
## The four gardens [name, position, clearing].
const GARDENS := [["Mother's Garden", Vector3(-14.0, 0.0, 38.0)], ["Crest Garden", Vector3(-4.0, 0.0, 32.0)],
		["Clover Garden", Vector3(-28.0, 0.0, 20.0)], ["Well Garden", Vector3(24.0, 0.0, 18.0)]]
const SAPLING_POS := Vector3(-16.0, 0.0, 48.5)
const COTTAGES := Vector3(20.0, 0.0, 50.0)
const DENS := {&"den_w": Vector3(-48.0, 0.0, -32.0), &"den_n": Vector3(0.0, 0.0, -44.0), &"den_e": Vector3(52.0, 0.0, -34.0)}
const MAELIS_START := Vector3(22.0, 0.0, 22.0)

## Phases [start, kind]: day, night 1 3:30-4:30, night 2 8:00-9:15, night 3 12:30-14:00, the thaw, spring 16:00.
const NIGHTS := [[210.0, 270.0], [480.0, 555.0], [750.0, 840.0]]
const THAW_AT := 840.0
const SPRING_AT := 960.0
const NIGHT_WARN := 10.0
const NIGHT_SIGHT := 0.7
## Waves [id, time, rows, den, garden index].
const WAVES := [
	[&"r1", 120.0, [["frostfang", 3]], &"den_n", 1],
	[&"n1a", 210.0, [["frostfang", 4]], &"den_w", 2],
	[&"n1b", 225.0, [["frostfang", 3]], &"den_e", 3],
	[&"r2", 360.0, [["frostfang", 4]], &"den_e", 3],
	[&"r2b", 360.0, [["frostfang", 3]], &"den_n", 1],
	[&"n2a", 480.0, [["frostfang", 5]], &"den_n", 1],
	[&"n2b", 495.0, [["frostfang", 4]], &"den_w", 2],
	[&"n2c", 510.0, [["frostfang", 4]], &"den_e", 3],
	[&"r3", 645.0, [["frostfang", 5]], &"den_w", 0],
	[&"n3a", 750.0, [["frostfang", 5]], &"den_n", 1],
	[&"n3a2", 750.0, [["frostfang", 4]], &"den_e", 3],
	[&"n3b", 780.0, [["whitepelt", 1], ["frostfang", 4]], &"den_n", 0],
]
const GARDEN_LIFE: Array[float] = [600.0, 500.0, 400.0]
const FROST_LOSS: Array[float] = [2.0, 3.0, 4.0]
const FROST_LOSS_LONG: Array[float] = [3.0, 4.0, 5.0]
const GARDENS_NEEDED: Array[int] = [1, 2, 3]
const WHITEPELT_HP: Array[float] = [750.0, 1000.0, 1300.0]
const TEND_R := 3.0
const TEND_REGROW := 2.0
const TOUCH_R := 6.0
const TOUCH_REGROW := 2.0
const THAW_REGROW := 1.0
const BLOOM_R := 6.0
const BLOOM_HEAL := 36.0
const BLOOM_TIME := 5.0
const SPROUT_AT := 0.8
const SPROUT_R := 10.0
const SPROUT_EVERY := 30.0
const WOLF_BITE_R := 10.0
const WOLF_HIT_MEMORY := 3.0
const MAELIS_LEVEL := 3
const MAELIS_BACK := 40.0
const COUNT_MULT: Array[float] = [0.6, 1.0, 1.4]
const START_CRYSTALS: Array[int] = [350, 250, 200]
const LEVEL_CAP := 4
const DEFEAT_DELAY := 3.0
const YOUNG_SCALE := 0.85

const SPEAKER_COLORS := {&"ysolde": Color(0.55, 0.90, 0.35), &"maelis": Color(0.60, 0.85, 0.50),
		&"master": Color(0.95, 0.93, 0.85), &"narrator": Color(0.9, 0.85, 0.7)}
const SPEAKER_NAMES := {&"ysolde": "Ysolde", &"maelis": "Maelis", &"master": "The Master", &"narrator": "Narrator"}
## The spec's 25 lines (data/voice/lines/e6m3.json): LINE_IDS[n - 1] = id of line n.
const LINE_IDS: Array[String] = ["L1", "L2", "L3", "L4", "L5", "L6", "L7", "L8", "L9", "L10", "L11", "L12", "L13", "L14", "L15", "L16", "L17", "L18", "L19", "L20", "L21", "L22", "L23", "L24", "L25"]
const DIALOGUE := [
	[&"narrator", "Thirty-two winters ago, the frost came back to Evenmead. Nothing grew. Again."],
	[&"ysolde", "They say I was born the year nothing grew. I won't let there be two."],
	[&"maelis", "Seed in the snow, little one? The whole village is laughing at you."],
	[&"ysolde", "My mother did it. In spring it came up green. Help me keep the wolves off."],
	[&"maelis", "Fine. I'll take the well. The wolves always come to the well."],
	[&"narrator", "When the sun went down, the frost bit through everything that was not covered."],
	[&"ysolde", "Cover the gardens! Sit on them if you have to!"],
	[&"maelis", "Wolves off the north ridge. Thin ones. Hungry ones."],
	[&"ysolde", "See? It fights back. Things that grow always fight back."],
	[&"ysolde", "No. No, no. I'll plant it again. Next year. I will."],
	[&"maelis", "Colder than last night. The river froze to the bottom."],
	[&"ysolde", "Then we'll be warmer than the river."],
	[&"narrator", "On the longest night, the pack's old leader came down from the ridge."],
	[&"maelis", "Old Whitepelt. I've hunted him nine winters. He's never been this hungry."],
	[&"maelis", "Nine winters. And a girl with a seed sack beats me to him."],
	[&"narrator", "And then, one grey morning, the snow began to turn to water."],
	[&"master", "A sapling, coaxed through the frost. In this cold?"],
	[&"ysolde", "It wants to grow. It only needs someone to wait with it."],
	[&"master", "Show me."],
	[&"master", "...Show me again."],
	[&"narrator", "She did. For twenty years, until he was gone."],
	[&"ysolde", "I'm sorry... I couldn't keep them warm."],
	[&"ysolde", "Nothing grew. Nothing at all."],
	[&"maelis", "I'm fine! Bitten. Fine. Keep planting."],
	[&"ysolde", "Twelve years ago he sent for me one last time. Torvald too. Only us."],
]
const BRIEFING_PARAGRAPHS: Array[String] = [
	"Thirty-two winters ago. Evenmead remembers the year nothing grew: the year the frost never lifted, the year a girl was born on Lark Hill. Fifteen winters later, the frost has come back.",
	"The village sleeps inside the Hollow Oak and eats its last seed corn. Ysolde does not. She has buried the seed in the snow, in four gardens across the hill, the way her mother did. The village laughs.",
	"The wolves are not laughing. They have come down from the north ridge, thin and hungry, and they can smell seed under snow. Keep the gardens alive until spring.",
]
const HINT_START := "Move Spriglings onto a garden to tend it: a tended garden does not freeze at night and grows back. Tending Spriglings carry no seed home."
const HINT_NIGHT := "Night is coming. Cover the gardens."
const HINT_THICKET := "Call the Thicket (E) is ready: three Saplings at a point. Save it for the long night."
const MSG_ONE_HOLLOW := "The village has room for one Seed Hollow"
const MSG_MAELIS_BACK := "Maelis is back at the Hollow Oak"

## Read only.
var gardens: Array = []                  ## SeedGarden x4 (GARDENS order)
var maelis: Helper
var whitepelt: Unit
var waves_fired: Array[String] = []
var night := -1                          ## index in NIGHTS while a night is on, else -1
var nights_seen := 0
var thaw := false
var sprouts := 0
var victory_time := -1.0
var gardens_lost := 0

var _tick := 0.0
var _fast := 0.0
var _wolves: Array = []
var _maelis_anchor: Unit
var _maelis_back_left := -1.0
var _warned := {}
var _keep_type_e6: BuildingType
var _sapling_prop: Node3D


## A seed-garden (systems placeholder): a PLAYER scripted target with Life, frost, tending and sprouts.
class SeedGarden:
	extends Node3D
	signal lost(g: SeedGarden)
	var team: int = Unit.Team.PLAYER
	var index := 0
	var display_name := "Garden"
	var max_hp := 500.0
	var hp := 500.0
	var is_lost := false
	var bloom_left := 0.0
	var sprout_ready_at := 0.0
	var _shoots: MeshInstance3D
	var _mat: StandardMaterial3D

	func _ready() -> void:
		add_to_group(&"scripted")
		add_to_group(&"gardens")
		set_meta(&"scripted", true)
		var disc := CylinderMesh.new()
		disc.top_radius = 2.2
		disc.bottom_radius = 2.6
		disc.height = 0.5
		_mat = StandardMaterial3D.new()
		_mat.albedo_color = Color(0.92, 0.95, 0.98)
		_shoots = MeshInstance3D.new()
		_shoots.mesh = disc
		_shoots.material_override = _mat
		_shoots.position.y = 0.2
		_shoots.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_shoots)
		var pole := BoxMesh.new()
		pole.size = Vector3(0.15, 1.8, 0.15)
		var pm := MeshInstance3D.new()
		pm.mesh = pole
		pm.position = Vector3(1.0, 0.9, 0.6)
		add_child(pm)
		_update_look()

	func is_alive() -> bool:
		return not is_lost and hp > 0.0

	func target_radius() -> float:
		return 2.5

	func ratio() -> float:
		return clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)

	func take_damage(amount: float, _attacker: Node3D = null) -> void:
		change(-amount)

	func change(amount: float) -> void:
		if is_lost or amount == 0.0:
			return
		hp = clampf(hp + amount, 0.0, max_hp)
		_update_look()
		if hp <= 0.0:
			is_lost = true
			_mat.albedo_color = Color(0.12, 0.13, 0.16)
			lost.emit(self)

	## A load (C5-9): Life `value` back without a signal; 0 = lost again, quietly (the mission's counters are saved).
	func restore_hp(value: float) -> void:
		hp = clampf(value, 0.0, max_hp)
		is_lost = hp <= 0.0
		if is_lost and _mat:
			_mat.albedo_color = Color(0.12, 0.13, 0.16)
		_update_look()

	func _update_look() -> void:
		if _mat and not is_lost:
			_mat.albedo_color = Color(0.92, 0.95, 0.98).lerp(Color(0.35, 0.62, 0.25), ratio())


# ---------------------------------------------------------------- setup

func _init() -> void:
	super()
	player_kingdom = &"nature"
	enemy_kingdom = &"shadow"
	snow_theme = true
	line_ids = LINE_IDS.duplicate()
	dialogue_lines = DIALOGUE
	speaker_colors = SPEAKER_COLORS.duplicate()
	speaker_names = SPEAKER_NAMES.duplicate()
	briefing_paragraphs = BRIEFING_PARAGRAPHS.duplicate()
	define_objectives([[&"obj_spring", "primary"], [&"obj_ysolde", "primary"], [&"sec_all", "secondary"],
			[&"sec_whitepelt", "secondary"]])
	local_unit("moonpelt_direwolf", "frostfang", "Frostfang", {"max_hp": 120.0, "armor": 0.0, "attack_damage": 12.0,
			"attack_range": 1.3, "attack_cooldown": 1.0, "move_speed": 6.2, "aggro_range": 10.0, "kill_xp": 30,
			"cost": 65, "pop": 1, "neutral_leash": false, "commandable": false})
	_scales["frostfang"] = 0.55
	local_unit("moonpelt_direwolf", "whitepelt", "Old Whitepelt", {"max_hp": 1000.0, "armor": 10.0, "attack_damage": 22.0,
			"attack_range": 1.6, "attack_cooldown": 1.0, "move_speed": 7.0, "aggro_range": 12.0, "kill_xp": 300,
			"cost": 600, "pop": 2, "neutral_leash": false, "commandable": false})
	_keep_type_e6 = MissionE5Base.local_building("nature_keep", "nature_keep", "The Hollow Oak", 2250.0, true)
	if _keep_type_e6:
		_keep_type_e6.pop_bonus = 20


func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	MissionE6Base.e6_config(c)
	c.mission_id = MISSION_ID
	c.title = MISSION_TITLE
	c.count_mult = COUNT_MULT.duplicate()
	c.defeat_on_keep_lost = true
	c.keep_lost_message = "The Hollow Oak has fallen"
	c.start_level = 1
	c.start_spells = [&"thornburst"]
	c.level_cap = LEVEL_CAP
	c.start_crystals = START_CRYSTALS.duplicate()
	c.defeat_delay = DEFEAT_DELAY
	c.victory_banner = "VICTORY\nIt came up green"
	c.defeat_banner = "DEFEAT"
	c.rewards = CampaignState.MISSION_REWARDS.get(MISSION_ID, {})
	c.spotlight = {"id": &"thornling", "trigger": &"manual", "key_hint": "Grove Hall: Z",
			"card": "Thornling. Small, cheap, stubborn: plant them where it matters and they never move."}
	return c


func _map_size() -> Vector2:
	return Vector2(150.0, 120.0)


func _player_start() -> Vector3:
	return YSOLDE_START


func _lighting_preset() -> StringName:
	return &"ice"


func _title_line() -> String:
	return "Episode 6, Mission 3: %s" % MISSION_TITLE


func _ground_spots() -> Array[Vector4]:
	return [Vector4(KEEP_POS.x, KEEP_POS.z, 12.0, 0.0), Vector4(COTTAGES.x, COTTAGES.z, 8.0, 0.0)]


func _ready() -> void:
	super()
	_day_light()
	if camera_rig:
		camera_rig.focus_on(YSOLDE_START)


func _day_light() -> void:
	tint_light(Color(1.0, 0.97, 0.92), 0.95, -26.0, Color(0.72, 0.74, 0.80), Color(0.50, 0.60, 0.78), Color(0.88, 0.90, 0.94))


func _night_light() -> void:
	tint_light(Color(0.62, 0.70, 0.95), 0.5, -30.0, Color(0.30, 0.36, 0.52), Color(0.06, 0.08, 0.18), Color(0.22, 0.26, 0.40))


func _thaw_light() -> void:
	tint_light(Color(1.0, 0.86, 0.62), 1.0, -22.0, Color(0.78, 0.74, 0.66), Color(0.46, 0.56, 0.74), Color(0.96, 0.84, 0.66))


# ---------------------------------------------------------------- the map

func start_position(_team: int) -> Vector3:
	return YSOLDE_START


func base_center(_team: int) -> Vector3:
	return KEEP_POS


func node_of(_team: int, suffix: String) -> CrystalNode:
	var id: StringName = {"a": &"e6y_a", "b": &"e6y_b", "rich": &"e6y_west"}.get(suffix, &"")
	var v: Variant = crystal_nodes.get(id)
	if v == null or not is_instance_valid(v):
		return null
	var n := v as CrystalNode
	return n if n != null and not n.is_depleted() else null


func natural_hall_spot(_team: int) -> Vector3:
	return WEST_HALL_SPOT


func rich_hall_spot(_team: int) -> Vector3:
	return WEST_HALL_SPOT


func market_slot(_team: int) -> Vector3:
	return Vector3.INF


func tower_slot(_team: int, _which: StringName) -> Vector3:
	return Vector3.INF


func _build_map() -> void:
	var clearings: Array = [[YSOLDE_START, 8.0], [KEEP_POS, 16.0], [HALL_POS, 5.0], [WEST_HALL_SPOT, 5.0],
			[SAPLING_POS, 6.0], [COTTAGES, 12.0], [ARMY_START, 5.0], [MAELIS_START, 4.0]]
	for row: Array in NODES:
		clearings.append([row[1], 7.0])
	for row: Array in GARDENS:
		clearings.append([row[1], 6.0])
	var lanes: Array = []
	for id: StringName in DENS:
		clearings.append([DENS[id], 7.0])
		for row: Array in GARDENS:
			lanes.append([DENS[id], row[1], 3.5])
	lanes.append([KEEP_POS, GARDENS[3][1], 4.0])
	scatter_props(MAP_SEED, clearings, lanes, 9, 14, 56.0)
	for row: Array in NODES:
		_add_crystal_node(StringName(row[0]), row[1], int(row[2]))
	keep = build_grid.spawn_complete(_keep_type_e6, KEEP_POS, Unit.Team.PLAYER) as Keep
	if keep:
		keep.name = "HollowOak"
		seat_keeps[Unit.Team.PLAYER] = keep
	seat_bases[Unit.Team.PLAYER] = KEEP_POS
	build_grid.spawn_complete(BuildingType.find("nature_barracks"), HALL_POS, Unit.Team.PLAYER)
	var diff := clampi(mission_difficulty, 0, 2)
	for i in GARDENS.size():
		var g := SeedGarden.new()
		g.index = i
		g.display_name = String(GARDENS[i][0])
		g.name = "Garden%d" % (i + 1)
		g.max_hp = float(GARDEN_LIFE[diff])
		g.hp = g.max_hp
		add_child(g)
		g.global_position = GARDENS[i][1]
		g.lost.connect(_on_garden_lost)
		gardens.append(g)
	_sapling_prop = box_prop(SAPLING_POS, Vector3(0.3, 0.5, 0.3), Color(0.40, 0.55, 0.32))
	for i in 6:
		var a := TAU * float(i) / 6.0
		box_prop(COTTAGES + Vector3(cos(a) * 7.0, 0.0, sin(a) * 7.0), Vector3(3.0, 2.4, 3.0), Color(0.55, 0.47, 0.40), a)


# ---------------------------------------------------------------- start state

func _on_navigation_ready() -> void:
	var diff := clampi(mission_difficulty, 0, 2)
	local_type("whitepelt").max_hp = float(WHITEPELT_HP[diff])
	for row: Array in GARDENS:
		fog.reveal(Unit.Team.PLAYER, row[1], 8.0)
	fog.reveal(Unit.Team.PLAYER, Vector3(-4.0, 0.0, 34.8), 10.0)
	_setup_champions()
	hero = _make_wizard(Unit.Team.PLAYER)
	_spawn(hero, Unit.Team.PLAYER, YSOLDE_START)
	_claim_wizard(hero, Unit.Team.PLAYER)
	ItemDrops.ensure_inventory(hero)
	MissionE6Base.set_story_look(hero, &"young", YOUNG_SCALE)
	hero.level_changed.connect(_on_ysolde_level)
	var caster := hero.get_node_or_null(^"SpellCaster")
	if caster and caster.has_signal(&"spell_effect"):
		caster.connect(&"spell_effect", _on_ysolde_spell)
	for i in 4:
		var w := _spawn(make_unit("sprigling"), Unit.Team.PLAYER, KEEP_POS + Vector3(-3.0 + i * 1.5, 0.0, -5.0))
		w.call(&"command_gather", node_of(Unit.Team.PLAYER, "a" if i < 2 else "b"))
	var army: Array[String] = ["thornling", "thornling", "thornling", "thornling", "burr_slinger", "burr_slinger"]
	if diff == 0:
		army.append_array(["thornling", "thornling"])
	elif diff == 2:
		army.erase("thornling")
	for i in army.size():
		_spawn(make_unit(army[i]), Unit.Team.PLAYER, ARMY_START + Vector3(-3.0 + (i % 4) * 1.5, 0.0, (i / 4) * 1.8))
	_maelis_anchor = story_anchor(GARDENS[3][1] + Vector3(-2.0, 0.0, 2.0))
	maelis = story_helper(&"helper_maelis", "Maelis", MAELIS_START, MAELIS_LEVEL, _maelis_anchor, &"escort")
	if maelis:
		MissionE6Base.set_story_look(maelis, &"young", 1.0)
		maelis.death_guard = _maelis_guard
	begin_mission([&"obj_spring", &"obj_ysolde", &"sec_all"])
	selection.select_units([hero])


func _intro() -> void:
	fire_once(&"E1")
	for id in ["L1", "L2", "L3", "L4", "L5"]:
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
		"objectives": [objective_text(&"obj_spring", false), objective_text(&"sec_all", false)],
		"rule": Loc.sink(objective_text(&"obj_ysolde")),
	}


func gardens_alive() -> int:
	return gardens.filter(func(g: Variant) -> bool: return (g as SeedGarden).is_alive()).size()


func gardens_needed() -> int:
	return int(by_difficulty(GARDENS_NEEDED))


## Seconds to the next night (0 during one, INF after the last).
func night_in() -> float:
	if night >= 0:
		return 0.0
	for n: Array in NIGHTS:
		if mission_time() < float(n[0]):
			return float(n[0]) - mission_time()
	return INF


func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_spring":
			if not with_counter:
				return "Keep the seed-gardens alive until spring"
			if night >= 0:
				return "Keep the seed-gardens alive until spring (%d / 4, night: %s left)" % [gardens_alive(),
						MissionE5Base.mmss(float(NIGHTS[night][1]) - mission_time())]
			return "Keep the seed-gardens alive until spring (%d / 4, spring in %s)" % [gardens_alive(),
					MissionE5Base.mmss(SPRING_AT - mission_time())]
		&"obj_ysolde":
			return "Ysolde must survive"
		&"sec_all":
			return "Bring all four gardens to spring"
		&"sec_whitepelt":
			return "Drive off Old Whitepelt"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_spring":
			var pos: Array = []
			for g: Variant in gardens:
				if (g as SeedGarden).is_alive():
					pos.append((g as Node3D).global_position)
			return {"counter": gardens_alive(), "goal": 4, "time_left": maxf(0.0, SPRING_AT - mission_time()),
					"positions": pos}
	return {}


# ---------------------------------------------------------------- the gardens

## Frost, tending, Ysolde's touch, Wild Bloom, the thaw, sprouts; every 0.25 s.
func _tick_gardens(dt: float) -> void:
	var tenders_by := {}
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or not u.is_alive() or int(u.team) != Unit.Team.PLAYER or u.unit_type == null \
				or u.unit_type.id != &"sprigling":
			continue
		for g: Variant in gardens:
			if (g as SeedGarden).is_alive() and _flat(u.global_position, (g as Node3D).global_position) <= TEND_R:
				tenders_by[g] = int(tenders_by.get(g, 0)) + 1
				break
	var loss := 0.0
	if night >= 0:
		loss = float(by_difficulty(FROST_LOSS_LONG if night == 2 else FROST_LOSS))
	for v: Variant in gardens:
		var g := v as SeedGarden
		if not g.is_alive():
			continue
		var tenders := mini(int(tenders_by.get(g, 0)), 2)
		var delta := 0.0
		if tenders == 0:
			delta -= loss
		delta += TEND_REGROW * tenders
		if hero_alive() and _flat(hero.global_position, g.global_position) <= TOUCH_R:
			delta += TOUCH_REGROW
		if thaw:
			delta += THAW_REGROW
		if g.bloom_left > 0.0:
			g.bloom_left -= dt
			delta += BLOOM_HEAL
		g.change(delta * dt)
		if g.is_alive() and g.ratio() > SPROUT_AT and mission_time() >= g.sprout_ready_at \
				and enemies_near(g.global_position, SPROUT_R) > 0:
			g.sprout_ready_at = mission_time() + SPROUT_EVERY
			_sprout(g)


func _sprout(g: SeedGarden) -> void:
	var s := make_unit("sapling")
	if s == null:
		return
	_spawn(s, Unit.Team.PLAYER, g.global_position + Vector3(1.5, 0.0, 1.5))
	sprouts += 1
	if fire_once(&"E4"):
		say_l("L9")


func _on_ysolde_spell(id: StringName, pos: Vector3) -> void:
	if id != &"wild_bloom":
		return
	for v: Variant in gardens:
		var g := v as SeedGarden
		if g.is_alive() and _flat(g.global_position, pos) <= BLOOM_R:
			g.bloom_left = BLOOM_TIME


func _on_garden_lost(g: SeedGarden) -> void:
	gardens_lost += 1
	if is_ending():
		return
	if fire_once(&"E5"):
		say_l("L10")
	if objective_state("sec_all") == "active":
		set_objective(&"sec_all", "failed")
	if g.index == 3 and maelis and is_instance_valid(maelis):
		maelis.bond_to(hero)   # the Well is lost: Maelis escorts Ysolde
	if gardens_alive() < gardens_needed():
		fire_once(&"E14")
		say_l("L23")
		set_objective(&"obj_spring", "failed")
		lose(DEFEAT_DELAY)


# ---------------------------------------------------------------- nights

func _tick_nights() -> void:
	var t := mission_time()
	var want := -1
	for i in NIGHTS.size():
		var n: Array = NIGHTS[i]
		if t >= float(n[0]) - NIGHT_WARN and t < float(n[0]) and not _warned.has(i):
			_warned[i] = true
			if hud:
				hud.show_message(HINT_NIGHT, 6.0)
		if t >= float(n[0]) and t < float(n[1]):
			want = i
	if want != night:
		night = want
		set_cold(night >= 0, NIGHT_SIGHT, 0.0, false)
		if night >= 0:
			nights_seen += 1
			_night_light()
			match night:
				0:
					fire_once(&"E2")
					say_l("L6")
					say_l("L7")
				1:
					fire_once(&"E6")
					say_l("L11")
					say_l("L12")
				2:
					fire_once(&"E8")
					say_l("L13")
		elif not thaw:
			_day_light()
	if not thaw and t >= THAW_AT:
		thaw = true
		fire_once(&"E11")
		say_l("L16")
		_thaw_light()
	if t >= SPRING_AT:
		_spring()


# ---------------------------------------------------------------- the wolves

func _tick_waves() -> void:
	var t := mission_time()
	for row: Array in WAVES:
		var id := String(row[0])
		if waves_fired.has(id) or t < float(row[1]):
			continue
		waves_fired.append(id)
		var units := wave(row[2], DENS[row[3]], &"garden", (gardens[int(row[4])] as Node3D).global_position)
		for v: Variant in units:
			var u := v as Unit
			u.set_meta(&"garden", int(row[4]))
			u.damage_taken.connect(_on_wolf_hit.bind(u))
			_wolves.append(u)
			if String(u.unit_type.id) == "whitepelt":
				whitepelt = u
				u.died.connect(_on_whitepelt_died)
		match id:
			"r1":
				fire_once(&"E3")
				say_l("L8")
			"n1a":
				show_spotlight()
			"n3b":
				fire_once(&"E9")
				say_l("L14")
				set_objective(&"sec_whitepelt", "active")


func _on_wolf_hit(_amount: float, _attacker: Node3D, u: Unit) -> void:
	if is_instance_valid(u):
		u.set_meta(&"hit_at", mission_time())


func _garden_for(u: Unit) -> SeedGarden:
	var i := int(u.get_meta(&"garden", 0))
	var g := gardens[i] as SeedGarden
	if g.is_alive():
		return g
	var best: SeedGarden = null
	var d := INF
	for v: Variant in gardens:
		var o := v as SeedGarden
		if o.is_alive() and _flat(o.global_position, u.global_position) < d:
			d = _flat(o.global_position, u.global_position)
			best = o
	if best:
		u.set_meta(&"garden", best.index)
	return best


## Seed hunger: within 10 m of its garden a wolf bites it unless it was hit in the last 3 s; never a building.
func _refresh_wave_unit(u: Unit, mode: StringName, _hero_at: Vector3) -> bool:
	if mode != &"garden":
		return false
	_wolf_brain(u)
	return true


func _wolf_brain(u: Unit) -> void:
	if u == null or not is_instance_valid(u) or not u.is_alive():
		return
	var g := _garden_for(u)
	if g == null:
		return
	if u.attack_target is Building:
		u.command_attack(g)
		return
	var hit := mission_time() - float(u.get_meta(&"hit_at", -100.0)) < WOLF_HIT_MEMORY
	if hit and u.attack_target is Unit:
		return
	if _flat(u.global_position, g.global_position) <= WOLF_BITE_R:
		if u.attack_target != g:
			u.command_attack(g)
	elif u.attack_target == null and not u.is_attack_moving():
		u.command_attack_move(g.global_position)


func _tick_wolves() -> void:
	var alive: Array = []
	for v: Variant in _wolves:
		if is_instance_valid(v) and (v as Unit).is_alive():
			alive.append(v)
			_wolf_brain(v as Unit)
	_wolves = alive


func _on_whitepelt_died(_u: Unit) -> void:
	if is_ending():
		return
	fire_once(&"E10")
	say_l("L15")
	set_objective(&"sec_whitepelt", "done")


# ---------------------------------------------------------------- Maelis

func _maelis_guard(_attacker: Variant) -> bool:
	if maelis == null or not is_instance_valid(maelis):
		return false
	maelis.hp = maelis.max_hp
	set_dormant(maelis, true)
	maelis.visible = false
	maelis.global_position = KEEP_POS + Vector3(6.0, 0.0, -4.0)
	_maelis_back_left = MAELIS_BACK
	if fire_once(&"E15"):
		say_l("L24")
	return true


func _tick_maelis(dt: float) -> void:
	if _maelis_back_left < 0.0 or maelis == null or not is_instance_valid(maelis):
		return
	_maelis_back_left -= dt
	if _maelis_back_left > 0.0:
		return
	_maelis_back_left = -1.0
	set_dormant(maelis, false)
	maelis.visible = true
	maelis.hp = maelis.max_hp
	maelis.global_position = KEEP_POS + Vector3(6.0, 0.0, -4.0)
	maelis.death_guard = _maelis_guard
	if hud:
		hud.show_message(MSG_MAELIS_BACK, 4.0)


func _on_ysolde_level(_u: Unit, level: int) -> void:
	if level >= 4 and fire_once(&"E7") and hud:
		hud.show_message(HINT_THICKET, 8.0)


# ---------------------------------------------------------------- the end

## E12: spring: e6m3_spring, then the victory.
func _spring() -> void:
	if is_ending() or not fire_once(&"E12"):
		return
	victory_time = mission_time()
	set_objective(&"obj_spring", "done")
	if objective_state("sec_all") == "active":
		set_objective(&"sec_all", "done" if gardens_alive() == 4 else "failed")
	if objective_state("sec_whitepelt") == "active":
		set_objective(&"sec_whitepelt", "failed")
	set_mission_flag("e6m3_gardens", gardens_alive())
	crumble_enemies()
	set_cold(false, 1.0, 0.0, false)
	if hero_alive():
		hero.global_position = Vector3(-15.0, 0.0, 47.0)
		hero.command_stop()
	play_cutscene(&"e6m3_spring", _spring_end)


## e6m3_spring end state: L17-L21 once, the gold sapling in place, victory.
func _spring_end() -> void:
	for id in ["L17", "L18", "L19", "L20", "L21"]:
		say_l(id)
	if _sapling_prop and is_instance_valid(_sapling_prop):
		_sapling_prop.queue_free()
	_sapling_prop = box_prop(SAPLING_POS, Vector3(0.6, 1.2, 0.6), Color(0.95, 0.80, 0.30))
	set_objective(&"obj_ysolde", "done")
	win(1.0)


func _on_player_hero_fell() -> void:
	fire_once(&"E13")
	say_l("L22")
	set_objective(&"obj_ysolde", "failed")
	super()


# ---------------------------------------------------------------- save / load

func save_state(ids: Dictionary = {}) -> Dictionary:
	var d := super(ids)
	var life: Array = []
	for g: Variant in gardens:
		life.append((g as SeedGarden).hp)
	d["gardens"] = life
	return d


## The rebuilt mission gets back each garden's Life, the night's cold, the wolves' brain and Maelis' guard.
func load_state(d: Dictionary, nodes: Dictionary = {}) -> void:
	super(d, nodes)
	var life: Array = d.get("gardens", [])
	for i in mini(life.size(), gardens.size()):
		var g := gardens[i] as SeedGarden
		g.restore_hp(float(life[i]))
	if gardens.size() > 3 and (gardens[3] as SeedGarden).is_lost and maelis and is_instance_valid(maelis) and hero:
		maelis.bond_to(hero)   # the Well was lost before the save: Maelis escorts Ysolde (_on_garden_lost)
	if night >= 0:
		set_cold(true, NIGHT_SIGHT, 0.0, false)
		_night_light()
	elif thaw:
		_thaw_light()
	_wolves.clear()
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and int(u.team) == Unit.Team.ENEMY and u.unit_type and String(u.unit_type.id) in ["frostfang", "whitepelt"]:
			_wolves.append(u)
			if not MissionBase.is_hooked(u.damage_taken, &"_on_wolf_hit"):
				u.damage_taken.connect(_on_wolf_hit.bind(u))
			if String(u.unit_type.id) == "whitepelt":
				whitepelt = u
				if not u.died.is_connected(_on_whitepelt_died):
					u.died.connect(_on_whitepelt_died)
	if maelis and is_instance_valid(maelis):
		restore_guard(maelis, _maelis_guard)
		if _maelis_back_left > 0.0 and not is_dormant(maelis):
			set_dormant(maelis, true)
			maelis.visible = false


# ---------------------------------------------------------------- every frame

func _physics_process(delta: float) -> void:
	super(delta)
	if not match_started or game_over or world_is_held or save_restoring:
		return
	tick_scripted(delta)
	if is_ending():
		return
	_tick_maelis(delta)
	_fast -= delta
	if _fast <= 0.0:
		_fast = 0.25
		_tick_gardens(0.25)
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.5
		_tick_nights()
		_tick_waves()
		_tick_wolves()
		enforce_max(&"nature_hollow", 1, MSG_ONE_HOLLOW)
		objectives_changed.emit()
		if hud and mission_hud == null:
			hud.set_objective(_objective_text())
