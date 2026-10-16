class_name MissionE8_01
extends MissionE8Base
## Episode 8, mission 1 "The Four Roads" (docs/design/mission-e8-01.md): the shared part of the four roads (D1). Each
## variant (MissionE8_01Fire / Shadow / Ice / Nature, scenes missions/mission_e8_01_<k>.tscn) sets its road, map things,
## objectives, waves and lines; this script does the start order (1.2), the Stronghold start and the Citadel hint (1.3),
## the Host / Stone-sworn types (1.4, MissionE8Base) and the road-end save (1.5).
##
## Built deviations (2026-10-09, from the spec):
## - Every road is the main.gd generator look at 120 x 120 with the player's base in the south-west corner (keep
##   (-43, 43)); Duskbarrow, the Hundredwinter Gate and the Closed Road have no .map yet: walls, rivers and bridges are
##   drawn markers, not navigation obstacles (each variant says what its rule reads instead).
## - The track: Vessa's road loads the saved items / essence / companion; the other roads carry their wizard's essence
##   flag (the per-wizard item tracks of outline D8 are not built). The key relic is forced in slot 1; slot 2 empty
##   gives +300 essence.
## - The Shadow road's V calls the Shadow helper as built (Hush's helper kit, "the Bishop's other knife"): Veyra
##   Nightquill has no HelperType yet.

const PREV_MISSION := &"e7m4"
const KEEP_POS := Vector3(-43.0, 0.0, 43.0)
const HALL_POS := Vector3(-27.0, 0.0, 45.0)
const TOWER_POS := Vector3(-37.0, 0.0, 29.0)
const HOUSE_POS := Vector3(-50.0, 0.0, 46.0)
const START := Vector3(-36.0, 0.0, 36.0)
const RALLY := Vector3(-30.0, 0.0, 30.0)
const NODES := [[&"e8_a", Vector3(-46.0, 0.0, 34.0), 1500], [&"e8_b", Vector3(-34.0, 0.0, 46.0), 1500],
		[&"e8_mid", Vector3(-22.0, 0.0, 12.0), 2000], [&"e8_rich", Vector3(-50.0, 0.0, -14.0), 2000]]
const START_CRYSTALS: Array[int] = [550, 450, 350]
const DEFEAT_DELAY := 3.0
const HINT_CITADEL := "Your Stronghold can become a Citadel: select the Keep and press X (300 crystals, 90 s). It opens the kingdom's tier-3 unit (C) and lets you call your helper (V)."
const BRIEFING_LINE := "Four keys. One door. Yours is on this road."
const SLINGER := MissionE6_04.SLINGER_ID   ## the Ruin Slinger (Host ranged; host_rows keeps the id as it is)

## Read only.
var victory_time := -1.0
var helper_arrived := false
var waves_fired: Array[String] = []

var _tick := 0.0
var _hint_t := 0.0


# ---------------------------------------------------------------- variant API (override)

func _road() -> StringName:
	return &"fire"


func _road_title() -> String:
	return ""


## The start army rows ([type_id, count]) of the road.
func _road_army() -> Array:
	return []


func _workers() -> int:
	return 5


## Extra clearings ([pos, r]) and lanes ([a, b, width]) for the prop scatter.
func _clearings() -> Array:
	return []


func _lanes() -> Array:
	return []


func _map_seed() -> int:
	return 1811


## The variant's own map things (under the nav region, before the bake).
func _variant_map() -> void:
	pass


## The variant's start (story units, guards, objectives); called before begin_mission.
func _variant_start() -> void:
	pass


## The objectives made active by begin_mission.
func _initial_objectives() -> Array:
	return []


## Every 0.25 s while the mission runs.
func _variant_tick(_dt: float) -> void:
	pass


func _on_helper_arrived() -> void:
	pass


# ---------------------------------------------------------------- setup

func _init() -> void:
	super()
	host_team = Unit.Team.ENEMY
	use_lines(StringName("e8m1_%s" % road))
	MissionE6_04.make_slinger(self)   # campaign review 2026-10-16: the Host's ranged unit (SLINGER rows)


func _mission_config() -> MissionConfig:
	road = _road()
	var c := MissionConfig.new()
	e8_config(c)
	c.mission_id = StringName("e8m1_%s" % road)
	c.title = _road_title()
	c.defeat_on_keep_lost = true
	c.start_tiers = {Unit.Team.PLAYER: 2}
	c.start_level = 5
	c.start_spell_points = 4
	c.start_crystals = START_CRYSTALS.duplicate()
	c.start_essence = 150
	c.victory_banner = "VICTORY\nThe road is open"
	c.defeat_banner = "DEFEAT"
	c.seat_kingdoms = {Unit.Team.PLAYER: road}
	c.rewards = CampaignState.MISSION_REWARDS.get(c.mission_id, {})
	return c


func _title_line() -> String:
	return "Episode 8, Mission 1: %s" % _road_title()


func _map_size() -> Vector2:
	return Vector2(120.0, 120.0)


func _player_start() -> Vector3:
	return START


func _ground_spots() -> Array[Vector4]:
	return [Vector4(KEEP_POS.x, KEEP_POS.z, 12.0, 0.0)]


func _ready() -> void:
	player_kingdom = road
	super()
	if camera_rig:
		camera_rig.focus_on(START)
	var roster := HelperRoster.for_team(Unit.Team.PLAYER)
	if roster and not roster.helper_called.is_connected(_on_helper_called):
		roster.helper_called.connect(_on_helper_called)


func start_position(_team: int) -> Vector3:
	return START


func base_center(_team: int) -> Vector3:
	return KEEP_POS


func respawn_point(team: int) -> Vector3:
	var k := keep_of(team)
	return k.spawn_point() if k else KEEP_POS + Vector3(4.0, 0.0, -4.0)


func node_of(_team: int, suffix: String) -> CrystalNode:
	var v: Variant = crystal_nodes.get(StringName("e8_" + suffix))
	if v == null or not is_instance_valid(v):
		return null
	var n := v as CrystalNode
	return n if n != null and not n.is_depleted() else null


func natural_hall_spot(_team: int) -> Vector3:
	return Vector3(-28.0, 0.0, 16.0)


func rich_hall_spot(_team: int) -> Vector3:
	return Vector3(-44.0, 0.0, -18.0)


func market_slot(_team: int) -> Vector3:
	return Vector3.INF


func tower_slot(_team: int, _which: StringName) -> Vector3:
	return Vector3.INF


# ---------------------------------------------------------------- the map

func _build_map() -> void:
	var clearings: Array = [[START, 8.0], [KEEP_POS, 18.0], [RALLY, 7.0], [Vector3(-28.0, 0.0, 16.0), 5.0]]
	for row: Array in NODES:
		clearings.append([row[1], 7.0])
	clearings.append_array(_clearings())
	scatter_props(_map_seed(), clearings, _lanes(), 10, 16)
	for row: Array in NODES:
		_add_crystal_node(StringName(row[0]), row[1], int(row[2]))
	keep = build_base(Unit.Team.PLAYER, road, KEEP_POS, HALL_POS, TOWER_POS, [HOUSE_POS], 2)
	seat_starts[Unit.Team.PLAYER] = START
	_variant_map()


# ---------------------------------------------------------------- start order (1.2)

func _on_navigation_ready() -> void:
	_setup_champions()
	spawn_player_wizard(START)
	load_track(road == &"fire", PREV_MISSION)
	spawn_workers(Unit.Team.PLAYER, road, _workers(), KEEP_POS + Vector3(4.0, 0.0, -4.0),
			[node_of(0, "a"), node_of(0, "b")])
	spawn_army(_road_army(), RALLY)
	_variant_start()
	begin_mission(_initial_objectives())
	empty_slot_bonus()
	selection.select_units([hero])


func briefing() -> Dictionary:
	var d := super()
	var objs: Array = d.get("objectives", [])
	objs.append(BRIEFING_LINE)
	d["objectives"] = objs
	return d


func _on_helper_called(team: int, _id: StringName) -> void:
	if team != Unit.Team.PLAYER or helper_arrived or is_ending():
		return
	helper_arrived = true
	_on_helper_arrived()


# ---------------------------------------------------------------- the road-end save (1.5)

## Victory: the road's flags (e8m1_done, e8_road, e8_road_<k>, e8_hush_fled), the time, then the film's end state.
func finish_road() -> void:
	victory_time = mission_time()
	set_mission_flag("e8m1_done", true)
	set_mission_flag("e8_road", road_index(road))
	for k: StringName in E8_KINGDOMS:
		set_mission_flag("e8_road_%s" % k, k == road)
	set_mission_flag("e8_hush_fled", true)
	set_mission_flag("e8m1_time", int(victory_time))
	clear_host()


func _on_player_hero_fell() -> void:
	set_objective(StringName("obj_%s" % wizard_id()), "failed")
	super()


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
	_variant_tick(0.25)
	_hint_t -= 0.25
	if _hint_t <= 0.0:
		_hint_t = 2.0
		keep_key_relic()
		if keep and keep.is_alive() and keep.tier == 2 and keep.can_upgrade() == "" and fire_once(&"hint_citadel") and hud:
			hud.show_message(HINT_CITADEL, 12.0)
		objectives_changed.emit()
		if hud and mission_hud == null:
			hud.set_objective(_objective_text())
