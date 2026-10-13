class_name MissionE6_02
extends MissionE6Base
## Episode 6, mission 2 "The Rider at the Gate" (docs/design/mission-e6-02.md): forty winters ago, the Hollow burns
## Hearthwick to draw Torvald's army out through his ice gate while it strikes the Heartfrost from below the mere. At
## 5:30 a rider begs at the Frostgate: open it (the townsfolk come through, two fronts) or keep it shut (the town burns,
## a wall defence). The choice is saved (`e6m2_gate_opened`, `e6m2_town_saved`, `e6m2_saved_count`) for Episode 8.
## Spotlight: the Frostbow (the first road column after the choice).
##
## Built deviations (2026-10-09, from the spec):
## - Frostgate map: the main.gd generator look with seed 1602 (snow theme); the Long Ice is an invisible baked wall
##   (z -10, x -60..-3 and 3..60) under a placeholder glacier strip; no Lost Caches, no fog occluder.
## - The Frostgate is a scripted PLAYER target (FrostGate, 3 600 HP, armor 20) whose leaves are a navigation obstacle:
##   opening / closing frees / rebuilds them and rebakes (no 4 s slide; units in the footprint are pushed out). The choice
##   is a mission button panel (Open the gate / Keep it shut, then one toggle), not the gate's own card.
## - Townsfolk are a hauler copy (60 HP, no attack, not commandable, pop 0); a soldier within 6 m gives +20 % speed.
## - Adult Aldra is the helper_aldra Helper at Torvald's level holding an invisible anchor at the Heartfrost (prime look
##   when the model has it); a fall hides her 45 s.
## - Rush floor (story: "the Hollow comes up through the floor"): breaking both Warden Gates stops the columns, but the
##   victory waits for dawn's last push: the Final (16:00) rises at the mere when no gate lives, and the night ends when
##   it is dead (or at 20:00). Both gates down + the Final dead = the early dawn.

const MISSION_ID := &"e6m2"
const MISSION_TITLE := "The Rider at the Gate"
const MAP_SEED := 1602

const TORVALD_START := Vector3(0.0, 0.0, -32.0)
const KEEP_POS := Vector3(0.0, 0.0, -44.0)
const HALL_POS := Vector3(-14.0, 0.0, -42.0)
const LODGE_POS := Vector3(14.0, 0.0, -40.0)
const NODES := [[&"e6g_a", Vector3(-10.0, 0.0, -52.0), 1500], [&"e6g_b", Vector3(9.0, 0.0, -53.0), 1500],
		[&"e6g_west", Vector3(-44.0, 0.0, -40.0), 2000]]
const WEST_HALL_SPOT := Vector3(-38.0, 0.0, -32.0)
const HEART_POS := Vector3(44.0, 0.0, -46.0)
const ALDRA_START := Vector3(40.0, 0.0, -40.0)
const ALDRA_BACK_AT := Vector3(38.0, 0.0, -36.0)
const LAKE_SPIRE := Vector3(34.0, 0.0, -34.0)
const CRACK_MERE := Vector3(54.0, 0.0, -24.0)
const WALL_Z := -10.0
const GATE_POS := Vector3(0.0, 0.0, -10.0)
const GATE_SIZE := Vector3(6.0, 6.0, 3.0)
const GATE_SPIRES: Array[Vector3] = [Vector3(-7.0, 0.0, -15.0), Vector3(7.0, 0.0, -15.0)]
const FIRE_POS := Vector3(4.0, 0.0, -5.0)
const GATE_WAIT := Vector3(0.0, 0.0, -4.0)
const TOWN := Vector3(0.0, 0.0, 28.0)
const HOUSES: Array[Vector3] = [Vector3(11.1, 0.0, 32.6), Vector3(4.6, 0.0, 39.1), Vector3(-4.6, 0.0, 39.1),
		Vector3(-11.1, 0.0, 32.6), Vector3(-11.1, 0.0, 23.4), Vector3(-4.6, 0.0, 16.9), Vector3(4.6, 0.0, 16.9),
		Vector3(11.1, 0.0, 23.4)]
const WGATES := {&"wgate_sw": Vector3(-40.0, 0.0, 50.0), &"wgate_se": Vector3(40.0, 0.0, 50.0)}
const ARMY_START := Vector3(0.0, 0.0, -24.0)
const SAFE_Z := -12.0
const FOLK_HOME := Vector3(0.0, 0.0, -34.0)
const SOUTH_EDGE := Vector3(0.0, 0.0, 58.0)

const CHOICE_AT := 330.0
const WINDOW: Array[float] = [120.0, 90.0, 60.0]
const DAWN := 1200.0
const W0A_AT := 210.0
const W0B_AT := 270.0
const ROAD_EVERY := 50.0
const SIEGE_EVERY := 60.0
const BREACH_AT := 720.0
const LAKE2_AT := 870.0
const FINAL_AT := 960.0
const TELEGRAPH := 20.0
const FOLK_GROUPS := 3
const FOLK_PER_GROUP := 8
const FOLK_EVERY := 40.0
const SAVED_NEED: Array[int] = [8, 12, 16]
const HEART_HP: Array[float] = [4000.0, 3000.0, 2400.0]
const HEART_REGEN := 10.0
const ELITE_HP: Array[float] = [1800.0, 2400.0, 3200.0]
const GATE_HP := 3600.0
const WGATE_HP := 1800.0
const BURN_DPS := 10.0
const ESCORT_R := 6.0
const ALDRA_BACK := 45.0
const COUNT_MULT: Array[float] = [0.6, 1.0, 1.4]
const START_CRYSTALS: Array[int] = [450, 350, 300]
const LEVEL_CAP := 6
const DEFEAT_DELAY := 3.0
const PRIME_SCALE := 1.0

const SPEAKER_COLORS := {&"torvald": Color(0.55, 0.80, 1.00), &"aldra": Color(0.62, 0.95, 0.88),
		&"rider": Color(0.80, 0.82, 0.88), &"obren": Color(1.0, 0.80, 0.25), &"narrator": Color(0.9, 0.85, 0.7)}
const SPEAKER_NAMES := {&"torvald": "Torvald", &"aldra": "Aldra", &"rider": "Bren", &"obren": "Obren",
		&"narrator": "Narrator"}
## The spec's 31 lines (data/voice/lines/e6m2.json): LINE_IDS[n - 1] = id of line n.
const LINE_IDS: Array[String] = ["L1", "L2", "L3", "L4", "L5", "L5b", "L6", "L7", "L8", "L9", "L10", "L11", "L12", "L13", "L14", "L15", "L16", "L17", "L18", "L19", "L20", "L21", "L22", "L23", "L24", "L25", "L26", "L27", "L28", "L29", "L30"]
const DIALOGUE := [
	[&"narrator", "Forty winters ago. The gate had stood for sixty years, and never once opened."],
	[&"torvald", "Sixty winters I have kept this gate. I can keep it one more."],
	[&"aldra", "Torvald. The Heartfrost hums when the stone-men are near. It is humming now."],
	[&"torvald", "Then the gate stays shut, and the lake stays quiet."],
	[&"narrator", "South of the wall, the lamps of Hearthwick went out one by one."],
	[&"aldra", "They are not coming for the lake. Why are they not coming for the lake?"],
	[&"rider", "Lord Torvald! Open the gate! The stone-men are in Hearthwick!"],
	[&"rider", "They're burning the houses. Two hundred people, my lord. Children."],
	[&"aldra", "It is bait. They want the gate open. They want the mere."],
	[&"torvald", "I know what they want."],
	[&"torvald", "Open the gate. All of it."],
	[&"rider", "Thank you, my lord! I'll bring them home!"],
	[&"aldra", "Then I hold the mere alone. Do not be long."],
	[&"torvald", "...No. The gate stays shut."],
	[&"rider", "You can see the smoke from up there! You can SEE it!"],
	[&"narrator", "The snow buried his signal fire. Torvald watched it go out."],
	[&"obren", "Thank you for opening the door, frost-man."],
	[&"obren", "Keep your gate, then. I will come up through your floor."],
	[&"rider", "They're through! Keep it open, the last ones are coming!"],
	[&"torvald", "Their door is broken. Go home, stones."],
	[&"aldra", "Torvald! The big one is at your gate!"],
	[&"torvald", "Close it now. Gently. Everyone is home."],
	[&"rider", "Hearthwick will remember this gate, my lord."],
	[&"torvald", "The lake is safe. The lake is always safe."],
	[&"aldra", "And the town?"],
	[&"torvald", "...Ask me in a hundred winters."],
	[&"torvald", "The ice... gives..."],
	[&"obren", "Mine."],
	[&"aldra", "Cracked. Not broken."],
	[&"torvald", "Hearthwick still sends me bread every midwinter. Burnt, usually."],
	[&"torvald", "Some nights I still see the smoke."],
]
const BRIEFING_PARAGRAPHS: Array[String] = [
	"Forty winters ago. For sixty years Torvald's ice gate has stood across the south road, and in sixty years it has never once opened. Behind it lie his keep, his lake, and the Heartfrost he promised to keep cold.",
	"South of the wall lies Hearthwick: two hundred people, a mill, and a signal fire they light when they need their lord. Tonight the stone-men have come back up out of the ground, and they are not walking toward the lake.",
	"Aldra watches the mere. Torvald watches the gate. Somewhere in the snow, a rider is coming. Decide what the gate is for.",
]
const HINT_START := "The Frostgate is sealed for winter. Build up: the Wardens are somewhere south."
const HINT_CHOICE := "The rider begs you to open the gate. Open the gate, or keep it shut (the buttons on the right). His fire burns for %s."
const MSG_CRACK := "The ice is cracking at the mere!"
const MSG_GATE_FELL := "The Frostgate has fallen. Hold the keep."
const MSG_ONE_LODGE := "Torvald's land has room for three lodges"
const MAX_LODGES := 3                     ## Snow Lodges max 3, the pre-built one included (spec 38)
const MSG_WALLS := "No more ice for walls this winter"
const BTN_OPEN := "Open the gate"
const BTN_SHUT := "Keep it shut"
const BTN_CLOSE := "Close the gate"

## Read only.
var heartfrost: E6Target
var aldra: Helper
var gate: FrostGate
var wgates := {}                          ## id -> WardenGate
var houses: Array = []                    ## the 8 town houses + the Hall (Building)
var town_hall: Building
var rider: Unit
var branch := &""                         ## &"" before the choice, &"open" / &"shut"
var choice_at := -1.0                     ## mission time the window opened
var chose_at := -1.0
var gate_opened := false                  ## opened inside the window (the flag)
var folk: Array = []                      ## townsfolk (Unit)
var saved := 0
var folk_sent := 0
var gates_broken := 0
var final_units: Array = []
var victory_time := -1.0
var heart_min := 1.0
var waves_fired: Array[String] = []

var _tick := 0.0
var _fast := 0.0
var _next_road := {}                      # wgate id -> mission time of its next road / siege column
var _siege_flip := 0
var _lake_at: Array = []                  # [[telegraph time, spawn time, rows, id], ...]
var _aldra_anchor: Unit
var _aldra_back_left := -1.0
var _panel: Control
var _rime_keep_type: BuildingType
var _hall_type: BuildingType
var _house_type: BuildingType


## The Frostgate (systems placeholder): a PLAYER scripted target whose leaves block the road while closed.
class FrostGate:
	extends Node3D
	signal shattered(g: FrostGate)
	var team: int = Unit.Team.PLAYER
	var max_hp := 3600.0
	var hp := 3600.0
	var armor := 20.0
	var is_closed := true
	var is_shattered := false
	var display_name := "The Frostgate"
	var nav_parent: Node
	var build_grid: BuildGrid
	var _leaves: StaticBody3D
	var _look: Node3D

	func _ready() -> void:
		add_to_group(&"scripted")
		set_meta(&"scripted", true)
		_add_leaves(false)

	## Open = not a target (C5-2): attackers drop it and walk through the gap.
	func is_alive() -> bool:
		return not is_shattered and is_closed and hp > 0.0

	func target_radius() -> float:
		return 3.0

	func take_damage(amount: float, _attacker: Node3D = null) -> void:
		if not is_alive() or amount <= 0.0:
			return
		hp = maxf(0.0, hp - amount * Unit.armor_multiplier(armor))
		if hp <= 0.0:
			is_shattered = true
			set_closed(false)
			shattered.emit(self)

	func set_closed(on: bool) -> void:
		if on == is_closed or (on and is_shattered):
			return
		is_closed = on
		if on:
			_add_leaves(true)
		else:
			if _leaves and is_instance_valid(_leaves):
				# out of the tree now: the rebake's geometry parse can run this same frame (before queue_free lands)
				if _leaves.get_parent():
					_leaves.get_parent().remove_child(_leaves)
				_leaves.queue_free()
			_leaves = null
			if _look:
				_look.visible = false
			_rebake()

	func _add_leaves(push: bool) -> void:
		if push and is_inside_tree():   # units in the footprint go to the nearer side
			for n in get_tree().get_nodes_in_group(&"units"):
				var u := n as Unit
				if u and absf(u.global_position.x - global_position.x) < 3.5 \
						and absf(u.global_position.z - global_position.z) < 2.5:
					var side := -1.0 if u.global_position.z < global_position.z else 1.0
					u.global_position = Vector3(u.global_position.x, u.global_position.y, global_position.z + side * 2.8)
		var body := StaticBody3D.new()
		body.name = "FrostgateLeaves"
		body.collision_layer = 1
		body.collision_mask = 0
		body.add_to_group(&"navigation_geometry")
		var col := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = GATE_SIZE
		col.shape = box
		col.position.y = GATE_SIZE.y * 0.5
		body.add_child(col)
		var parent: Node = nav_parent if nav_parent != null else self
		parent.add_child(body)
		body.global_position = global_position
		_leaves = body
		if _look == null:
			var mesh := BoxMesh.new()
			mesh.size = Vector3(GATE_SIZE.x, GATE_SIZE.y, 1.2)
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.62, 0.82, 0.98, 0.85)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			var mi := MeshInstance3D.new()
			mi.mesh = mesh
			mi.material_override = mat
			mi.position.y = GATE_SIZE.y * 0.5
			add_child(mi)
			_look = mi
		_look.visible = true
		if push:
			_rebake()

	func _rebake() -> void:
		if build_grid and is_inside_tree():
			await get_tree().process_frame
			if is_instance_valid(build_grid):
				build_grid.request_rebake()


# ---------------------------------------------------------------- setup

func _init() -> void:
	super()
	player_kingdom = &"ice"
	enemy_kingdom = &"shadow"
	snow_theme = true
	line_ids = LINE_IDS.duplicate()
	dialogue_lines = DIALOGUE
	speaker_colors = SPEAKER_COLORS.duplicate()
	speaker_names = SPEAKER_NAMES.duplicate()
	briefing_paragraphs = BRIEFING_PARAGRAPHS.duplicate()
	define_objectives([[&"obj_dawn", "primary"], [&"obj_heartfrost", "primary"], [&"obj_torvald", "primary"],
			[&"obj_choice", "primary"], [&"obj_town", "primary"], [&"sec_gates", "secondary"], [&"sec_lake", "secondary"]])
	make_breakers("gate_breaker", "The Gate-Breaker", 2400.0)
	local_unit("rime_hauler", "townsfolk", "Hearthwick Folk", {"max_hp": 60.0, "move_speed": 4.2, "attack_damage": 0.0,
			"is_worker": false, "commandable": false, "pop": 0, "cost": 0, "kill_xp": 0, "aggro_range": 0.0,
			"body_color": Color(0.45, 0.33, 0.22)})
	local_unit("snowdrift_rider", "hearthwick_rider", "Bren of Hearthwick", {"commandable": false, "pop": 0,
			"attack_damage": 0.0, "aggro_range": 0.0, "body_color": Color(0.45, 0.32, 0.22)})
	_rime_keep_type = MissionE5Base.local_building("ice_keep", "ice_keep", "Rime Keep", 3000.0, true)
	if _rime_keep_type:
		_rime_keep_type.pop_bonus = 20
	_hall_type = MissionE5Base.local_building("ice_lodge", "town_hall", "Hearthwick Hall", 1200.0)
	_house_type = MissionE5Base.local_building("ice_lodge", "town_house", "Hearthwick House", 400.0)


func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	MissionE6Base.e6_config(c)
	c.mission_id = MISSION_ID
	c.title = MISSION_TITLE
	c.count_mult = COUNT_MULT.duplicate()
	c.defeat_on_keep_lost = true
	c.keep_lost_message = "The Rime Keep has fallen"
	c.start_level = 3
	c.start_spells = [&"rime_bolt", &"flash_freeze"]
	c.level_cap = LEVEL_CAP
	c.start_crystals = START_CRYSTALS.duplicate()
	c.defeat_delay = DEFEAT_DELAY
	c.victory_banner = "VICTORY\nDawn over the Frostgate"
	c.defeat_banner = "DEFEAT"
	c.rewards = CampaignState.MISSION_REWARDS.get(MISSION_ID, {})
	c.spotlight = {"id": &"frostbow", "trigger": &"manual", "key_hint": "Frost Hall: B",
			"card": "Frostbow. Every arrow chills: what walks toward it walks slower, and slower."}
	return c


func _map_size() -> Vector2:
	return Vector2(120.0, 120.0)


func _player_start() -> Vector3:
	return TORVALD_START


func _lighting_preset() -> StringName:
	return &"ice"


func _title_line() -> String:
	return "Episode 6, Mission 2: %s" % MISSION_TITLE


func _ground_spots() -> Array[Vector4]:
	return [Vector4(KEEP_POS.x, KEEP_POS.z, 12.0, 0.0), Vector4(TOWN.x, TOWN.z, 14.0, 0.0)]


func _ready() -> void:
	super()
	tint_light(Color(0.70, 0.78, 1.0), 0.6, -30.0, Color(0.38, 0.44, 0.60), Color(0.10, 0.12, 0.24), Color(0.30, 0.34, 0.50))
	if camera_rig:
		camera_rig.focus_on(TORVALD_START)


# ---------------------------------------------------------------- the map

func start_position(_team: int) -> Vector3:
	return TORVALD_START


func base_center(_team: int) -> Vector3:
	return KEEP_POS


func node_of(_team: int, suffix: String) -> CrystalNode:
	var id: StringName = {"a": &"e6g_a", "b": &"e6g_b", "rich": &"e6g_west"}.get(suffix, &"")
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
	var clearings: Array = [[TORVALD_START, 8.0], [KEEP_POS, 16.0], [TOWN, 16.0], [HEART_POS, 14.0], [CRACK_MERE, 6.0],
			[LAKE_SPIRE, 4.0], [WEST_HALL_SPOT, 5.0], [FIRE_POS, 4.0], [ARMY_START, 6.0]]
	for row: Array in NODES:
		clearings.append([row[1], 7.0])
	for id: StringName in WGATES:
		clearings.append([WGATES[id], 7.0])
	var lanes: Array = [[GATE_POS + Vector3(0.0, 0.0, -30.0), SOUTH_EDGE, 4.5], [Vector3(-60.0, 0.0, WALL_Z),
			Vector3(60.0, 0.0, WALL_Z), 5.0], [WGATES[&"wgate_sw"], TOWN, 4.0], [WGATES[&"wgate_se"], TOWN, 4.0],
			[CRACK_MERE, HEART_POS, 4.0], [KEEP_POS, HEART_POS, 4.0], [KEEP_POS, NODES[2][1], 4.0]]
	scatter_props(MAP_SEED, clearings, lanes, 10, 16)
	# The Long Ice: two baked walls with the gate gap between them.
	bound_wall(Vector3(-75.0, 0.0, WALL_Z), Vector3(-GATE_SIZE.x * 0.5, 0.0, WALL_Z), 6.0)
	bound_wall(Vector3(GATE_SIZE.x * 0.5, 0.0, WALL_Z), Vector3(75.0, 0.0, WALL_Z), 6.0)
	box_prop(Vector3(-31.5, 0.0, WALL_Z), Vector3(57.0, 6.0, 3.0), Color(0.72, 0.85, 0.96))
	box_prop(Vector3(31.5, 0.0, WALL_Z), Vector3(57.0, 6.0, 3.0), Color(0.72, 0.85, 0.96))
	ground_disc(HEART_POS + Vector3(2.0, 0.0, -2.0), 15.0, Color(0.70, 0.85, 0.98, 0.55))
	ground_disc(FIRE_POS, 1.2, Color(1.0, 0.55, 0.15, 0.8))
	for row: Array in NODES:
		_add_crystal_node(StringName(row[0]), row[1], int(row[2]))
	keep = build_grid.spawn_complete(_rime_keep_type, KEEP_POS, Unit.Team.PLAYER) as Keep
	if keep:
		keep.name = "RimeKeep"
		seat_keeps[Unit.Team.PLAYER] = keep
	seat_bases[Unit.Team.PLAYER] = KEEP_POS
	build_grid.spawn_complete(BuildingType.find("ice_barracks"), HALL_POS, Unit.Team.PLAYER)
	build_grid.spawn_complete(BuildingType.find("ice_lodge"), LODGE_POS, Unit.Team.PLAYER)
	for p in GATE_SPIRES + [LAKE_SPIRE]:
		build_grid.spawn_complete(BuildingType.find("ice_tower"), p, Unit.Team.PLAYER)
	if _hall_type:
		town_hall = build_grid.spawn_complete(_hall_type, TOWN, Unit.Team.PLAYER)
		if town_hall:
			mark_scripted(town_hall)
			houses.append(town_hall)
	for p in HOUSES:
		var b := build_grid.spawn_complete(_house_type, p, Unit.Team.PLAYER) if _house_type else null
		if b:
			mark_scripted(b)
			houses.append(b)
	var diff := clampi(mission_difficulty, 0, 2)
	heartfrost = add_target(HEART_POS, float(HEART_HP[diff]), HEART_REGEN, _heart_regens, "The Heartfrost")
	gate = FrostGate.new()
	gate.name = "Frostgate"
	gate.nav_parent = nav_region
	gate.build_grid = build_grid
	gate.max_hp = GATE_HP
	gate.hp = GATE_HP
	gate.position = GATE_POS   # before add_child: _ready places the leaves at the gate (they sat at the origin before)
	nav_region.add_child(gate)
	gate.global_position = GATE_POS
	gate.shattered.connect(_on_gate_shattered)
	for id: StringName in WGATES:
		var g := add_warden_gate(id, WGATES[id], TOWN, WGATE_HP, 0.0, Callable())
		g.gate_down.connect(_on_wgate_down)
		wgates[id] = g


# ---------------------------------------------------------------- start state

func _on_navigation_ready() -> void:
	var diff := clampi(mission_difficulty, 0, 2)
	local_type("gate_breaker").max_hp = float(ELITE_HP[diff])
	fog.reveal(Unit.Team.PLAYER, TOWN, 18.0)
	fog.reveal(Unit.Team.PLAYER, GATE_POS + Vector3(0.0, 0.0, 10.0), 12.0)
	fog.reveal(Unit.Team.PLAYER, HEART_POS, 14.0)
	_setup_champions()
	hero = _make_wizard(Unit.Team.PLAYER)
	_spawn(hero, Unit.Team.PLAYER, TORVALD_START)
	_claim_wizard(hero, Unit.Team.PLAYER)
	ItemDrops.ensure_inventory(hero)
	for i in 6:
		var w := _spawn(make_unit("rime_hauler"), Unit.Team.PLAYER, KEEP_POS + Vector3(-4.0 + i * 1.5, 0.0, -5.0))
		w.call(&"command_gather", node_of(Unit.Team.PLAYER, "a" if i < 3 else "b"))
	var army: Array[String] = ["rimeshield", "rimeshield", "rimeshield", "rimeshield", "shardcaster", "shardcaster",
			"shardcaster", "frostbow", "frostbow", "rime_seer"]
	for i in army.size():
		_spawn(make_unit(army[i]), Unit.Team.PLAYER, ARMY_START + Vector3(-4.0 + (i % 5) * 2.0, 0.0, (i / 5) * 2.0))
	for i in 2:
		_spawn(make_unit("rimeshield"), Unit.Team.PLAYER, ALDRA_START + Vector3(-1.5 + i * 3.0, 0.0, -2.0))
	_aldra_anchor = story_anchor(HEART_POS + Vector3(-4.0, 0.0, 4.0))
	aldra = story_helper(&"helper_aldra", "Aldra", ALDRA_START, hero.level, _aldra_anchor, &"escort")
	if aldra:
		MissionE6Base.set_story_look(aldra, &"prime", PRIME_SCALE)
		aldra.death_guard = _aldra_guard
	heartfrost.melted.connect(_on_heart_melted)
	begin_mission([&"obj_dawn", &"obj_heartfrost", &"obj_torvald", &"sec_gates", &"sec_lake"])
	selection.select_units([hero])


func _intro() -> void:
	fire_once(&"E1")
	for id in ["L1", "L2", "L3", "L4"]:
		say_l(id)
	if hud:
		hud.show_message(HINT_START, 8.0)
	if camera_rig:
		camera_rig.focus_on(GATE_POS + Vector3(0.0, 0.0, -8.0))


# ---------------------------------------------------------------- briefing, objectives

func briefing() -> Dictionary:
	return {
		"title": _title_line(),
		"paragraphs": BRIEFING_PARAGRAPHS.duplicate(),
		"objectives": [objective_text(&"obj_dawn", false), objective_text(&"obj_heartfrost", false)],
		"rule": Loc.sink(objective_text(&"obj_torvald")),
	}


func window_left() -> float:
	if choice_at < 0.0 or branch != &"":
		return 0.0
	return maxf(0.0, choice_at + float(by_difficulty(WINDOW)) - mission_time())


func saved_needed() -> int:
	return int(by_difficulty(SAVED_NEED))


func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_dawn":
			if with_counter:
				return "Hold until dawn (%s)" % MissionE5Base.mmss(DAWN - mission_time())
			return "Hold until dawn"
		&"obj_heartfrost":
			if with_counter and heartfrost:
				return "The Heartfrost must not fall (%d %%)" % int(round(heartfrost.ratio() * 100.0))
			return "The Heartfrost must not fall"
		&"obj_torvald":
			return "Torvald must survive"
		&"obj_choice":
			if with_counter and branch == &"":
				return "The rider's fire: %s" % MissionE5Base.mmss(window_left())
			return "The rider's fire"
		&"obj_town":
			if branch == &"shut":
				return "Hearthwick burns."
			if with_counter:
				return "Bring Hearthwick's people through the gate (%d / %d)" % [saved, FOLK_GROUPS * FOLK_PER_GROUP]
			return "Bring Hearthwick's people through the gate"
		&"sec_gates":
			if with_counter:
				return "Break the Warden Gates (%d / 2)" % gates_broken
			return "Break the Warden Gates"
		&"sec_lake":
			return "Keep the stone-men off the Heartfrost"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_dawn":
			return {"time_left": maxf(0.0, DAWN - mission_time())}
		&"obj_heartfrost":
			if heartfrost:
				return {"counter": int(heartfrost.hp), "goal": int(heartfrost.max_hp)}
		&"obj_choice":
			if branch == &"":
				return {"time_left": window_left()}
		&"obj_town":
			if branch == &"open":
				return {"counter": saved, "goal": FOLK_GROUPS * FOLK_PER_GROUP}
		&"sec_gates":
			var pos: Array = []
			for g: Variant in wgates.values():
				if (g as WardenGate).is_alive():
					pos.append((g as Node3D).global_position)
			return {"counter": gates_broken, "goal": 2, "positions": pos}
	return {}


# ---------------------------------------------------------------- the choice

## E4: the rider at the gate (5:30): e6m2_rider, then the window and the buttons.
func _e4_rider() -> void:
	if not fire_once(&"E4"):
		return
	rider = make_unit("hearthwick_rider")
	if rider:
		_spawn(rider, Unit.Team.PLAYER, FIRE_POS)
		rider.name = "Bren"
		mark_scripted(rider)
		set_dormant(rider, true)
	if hero_alive():
		hero.global_position = Vector3(0.0, 0.0, -16.0)
		hero.command_stop()
	play_cutscene(&"e6m2_rider", _rider_end)


## e6m2_rider end state: Torvald (0, -16), the rider at the lit fire, the window running, the buttons, L6-L9 once.
func _rider_end() -> void:
	for id in ["L6", "L7", "L8", "L9"]:
		say_l(id)
	choice_at = mission_time()
	set_objective(&"obj_choice", "active")
	_show_choice_panel()
	if hud:
		hud.show_message(Loc.t(HINT_CHOICE) % MissionE5Base.mmss(float(by_difficulty(WINDOW))), 12.0)


func _show_choice_panel() -> void:
	if _panel and is_instance_valid(_panel):
		_panel.queue_free()
	_panel = null
	if branch == &"":
		_panel = mission_button_panel("FrostgatePanel", [[Loc.t(BTN_OPEN), choose_open], [Loc.t(BTN_SHUT), choose_shut]])
	elif gate and not gate.is_shattered:
		_panel = mission_button_panel("FrostgatePanel", [[Loc.t(BTN_OPEN if gate.is_closed else BTN_CLOSE), toggle_gate]])


## Z "Open the gate" in the window: branch open (E5a). After the window it only opens the gate.
func choose_open() -> void:
	if is_ending() or choice_at < 0.0:
		return
	if branch == &"":
		_branch_open()
	set_gate_open(true)


## X "Keep it shut" (or the fire dies): branch shut (E5b).
func choose_shut() -> void:
	if is_ending() or choice_at < 0.0 or branch != &"":
		return
	_branch_shut()


## The toggle after the choice.
func toggle_gate() -> void:
	if gate and not gate.is_shattered:
		set_gate_open(gate.is_closed)


func set_gate_open(on: bool) -> void:
	if gate == null or gate.is_shattered:
		return
	gate.set_closed(not on)
	_show_choice_panel()


func _branch_open() -> void:
	branch = &"open"
	chose_at = mission_time()
	gate_opened = true
	fire_once(&"E5a")
	set_objective(&"obj_choice", "done")
	set_objective(&"obj_town", "active")
	for id in ["L10", "L11", "L12"]:
		say_l(id)
	if rider:
		rider.command_move(TOWN)
	_next_road[&"wgate_sw"] = chose_at + ROAD_EVERY * 0.5
	_next_road[&"wgate_se"] = chose_at + ROAD_EVERY
	_lake_at.append([chose_at + 40.0, chose_at + 60.0, [[WARDEN_ID, 4], [BREAKER_ID, 1]], "lake1"])
	_queue_shared_lakes()
	show_spotlight()


func _branch_shut() -> void:
	branch = &"shut"
	chose_at = mission_time()
	fire_once(&"E5b")
	set_objective(&"obj_choice", "done")
	set_objective(&"obj_town", "failed")
	for id in ["L13", "L14", "L15"]:
		say_l(id)
	if rider and is_instance_valid(rider):
		rider.command_move(SOUTH_EDGE)
	ground_disc(FIRE_POS, 1.6, Color(0.95, 0.97, 1.0, 0.95), 0.05)   # the snow buries the signal fire
	_next_road[&"wgate_sw"] = chose_at + SIEGE_EVERY
	_next_road[&"wgate_se"] = INF
	_lake_at.append([chose_at + 160.0, chose_at + 180.0, [[WARDEN_ID, 4], [BREAKER_ID, 1]], "lake1"])
	_queue_shared_lakes()
	_show_choice_panel()
	show_spotlight()


func _queue_shared_lakes() -> void:
	_lake_at.append([LAKE2_AT - TELEGRAPH, LAKE2_AT, [[WARDEN_ID, 3], [BREAKER_ID, 1]], "lake2"])


func _tick_choice() -> void:
	if not has_fired(&"E4") and mission_time() >= CHOICE_AT:
		_e4_rider()
	if branch == &"" and choice_at >= 0.0 and window_left() <= 0.0:
		_branch_shut()
	if branch == &"" and choice_at < 0.0 and not has_fired(&"E4"):
		return
	if hud and branch == &"" and choice_at >= 0.0:
		objectives_changed.emit()


# ---------------------------------------------------------------- the town and its people

func _tick_town(dt: float) -> void:
	if branch == &"shut":
		for b: Variant in houses:
			if is_instance_valid(b) and (b as Building).is_alive():
				(b as Building).take_damage(BURN_DPS * dt, null)
	if branch != &"open":
		return
	var t := mission_time()
	var due := clampi(int(floor((t - chose_at) / FOLK_EVERY)) + 1, 0, FOLK_GROUPS)
	while folk_sent < due * FOLK_PER_GROUP:
		_send_folk()
	var army := units_of(Unit.Team.PLAYER, true)
	for v: Variant in folk.duplicate():
		var f: Unit = v as Unit if is_instance_valid(v) else null
		if f == null or not is_instance_valid(f) or not f.is_alive():
			folk.erase(v)
			continue
		if f.global_position.z < SAFE_Z:
			saved += 1
			folk.erase(v)
			f.command_move(FOLK_HOME + Vector3(randf_range(-4.0, 4.0), 0.0, randf_range(-2.0, 2.0)))
			if saved >= FOLK_PER_GROUP and fire_once(&"E7"):
				say_l("L18")
			continue
		var escorted := false
		for u in army:
			if u.is_in_group(&"townsfolk") or not u.is_commandable():
				continue   # only Torvald's soldiers escort (C5-6)
			if _flat(u.global_position, f.global_position) <= ESCORT_R:
				escorted = true
				break
		if escorted:
			f.add_modifier(&"escort", {"move_speed_pct": 0.2})
		else:
			f.remove_modifier(&"escort")
		if gate.is_closed and f.global_position.z < GATE_WAIT.z + 3.0:
			if _flat(f.global_position, GATE_WAIT) > 3.0 and not f.has_move_order():
				f.command_move(GATE_WAIT)
		elif not f.has_move_order():
			f.command_move(FOLK_HOME if not gate.is_closed else GATE_WAIT)


func _send_folk() -> void:
	var i := folk_sent
	folk_sent += 1
	var f := make_unit("townsfolk")
	if f == null:
		return
	_spawn(f, Unit.Team.PLAYER, TOWN + Vector3(-2.0 + (i % 4) * 1.3, 0.0, -9.0 + (i % FOLK_PER_GROUP) / 4 * 1.3))
	mark_scripted(f)
	f.add_to_group(&"townsfolk")
	folk.append(f)
	f.command_move(GATE_WAIT if gate.is_closed else FOLK_HOME)


# ---------------------------------------------------------------- the Host

func _living_wgates() -> Array:
	return wgates.values().filter(func(g: Variant) -> bool: return (g as WardenGate).is_alive())


func _column(gid: StringName, rows: Array, id: String) -> Array:
	var g := wgates.get(gid) as WardenGate
	if g == null or not g.is_alive():
		return []
	waves_fired.append(id)
	return wave(rows, g.front_point(), &"road", GATE_WAIT)


func _tick_host() -> void:
	var t := mission_time()
	if t >= W0A_AT and not waves_fired.has("w0a"):
		waves_fired.append("w0a")
		wave([[WARDEN_ID, 3]], (wgates[&"wgate_sw"] as WardenGate).front_point(), &"houses_w", TOWN)
		fire_once(&"E2")
		say_l("L5")
	if t >= W0B_AT and not waves_fired.has("w0b"):
		waves_fired.append("w0b")
		wave([[WARDEN_ID, 3]], (wgates[&"wgate_se"] as WardenGate).front_point(), &"houses_e", TOWN)
		fire_once(&"E3")
		say_l("L5b")
	for gid: StringName in _next_road.keys():
		if t < float(_next_road[gid]):
			continue
		if branch == &"open":
			_next_road[gid] = t + ROAD_EVERY
			_column(gid, [[WARDEN_ID, 3]], "road")
		else:   # shut: one column every 60 s, alternating gates
			_next_road[gid] = INF
			var order: Array[StringName] = [&"wgate_sw", &"wgate_se"]
			var pick := order[_siege_flip % 2]
			_siege_flip += 1
			if not (wgates[pick] as WardenGate).is_alive():
				pick = order[_siege_flip % 2]
			_column(pick, [[WARDEN_ID, 3]], "siege")
			_next_road[order[_siege_flip % 2]] = t + SIEGE_EVERY
	for row: Array in _lake_at.duplicate():
		if t >= float(row[0]) and not waves_fired.has("t_" + String(row[3])):
			waves_fired.append("t_" + String(row[3]))
			_telegraph()
		if t >= float(row[1]):
			_lake_at.erase(row)
			waves_fired.append(String(row[3]))
			wave(row[2], CRACK_MERE, &"heart", HEART_POS)
	if t >= BREACH_AT and not waves_fired.has("breach"):
		waves_fired.append("breach")
		var living := _living_wgates()
		if living.is_empty():
			wave([[BREAKER_ID, 2], [WARDEN_ID, 6]], CRACK_MERE, &"heart", HEART_POS)
		else:
			for i in living.size():
				var n_w := 6 / living.size()
				var n_b := 2 / living.size()
				wave([[BREAKER_ID, n_b], [WARDEN_ID, n_w]], (living[i] as WardenGate).front_point(), &"road", GATE_WAIT)
	if t >= FINAL_AT and not waves_fired.has("final"):
		waves_fired.append("final")
		fire_once(&"E9")
		say_l("L20")
		var living := _living_wgates()
		if living.is_empty():   # the rush floor: the Hollow comes up through the floor
			final_units = wave([["gate_breaker", 1], [WARDEN_ID, 8]], CRACK_MERE, &"heart", HEART_POS)
		else:
			final_units = wave([["gate_breaker", 1], [WARDEN_ID, 8]], (living[0] as WardenGate).front_point(), &"road", GATE_WAIT)
	if t >= DAWN:
		_dawn()
	elif gates_broken >= 2 and waves_fired.has("final") and MissionBase._all_dead(final_units):
		_dawn()


## Mission time of the next lake telegraph (INF = none pending).
func next_lake_telegraph() -> float:
	var best := INF
	for row: Array in _lake_at:
		best = minf(best, float(row[0]))
	return best


func _telegraph() -> void:
	if hud:
		hud.show_message(MSG_CRACK, 6.0)
	ground_disc(CRACK_MERE, 3.0, Color(1.0, 0.62, 0.18, 0.6))
	if fire_once(&"E6"):
		say_l("L16" if branch == &"open" else "L17")


func _nearest_house(from: Vector3, west: bool) -> Building:
	var best: Building = null
	var d := INF
	for v: Variant in houses:
		if not is_instance_valid(v) or not (v as Building).is_alive() or v == town_hall:
			continue
		var b := v as Building
		if (b.global_position.x < 0.0) != west:
			continue
		var dd := _flat(b.global_position, from)
		if dd < d:
			d = dd
			best = b
	return best


func _refresh_wave_unit(u: Unit, mode: StringName, _hero_at: Vector3) -> bool:
	match mode:
		&"houses_w", &"houses_e":
			var b := _nearest_house(u.global_position, mode == &"houses_w")
			if b == null:
				u.set_meta(META_MODE, &"road")
				return true
			if u.attack_target == null:
				if _flat(u.global_position, b.global_position) < 6.0:
					u.command_attack(b)
				elif not u.is_attack_moving():
					u.command_attack_move(b.global_position)
			return true
		&"road":
			if u.attack_target == null or not u.attack_target is Unit:
				for v: Variant in folk:
					if is_instance_valid(v) and (v as Unit).is_alive() and _flat((v as Unit).global_position, u.global_position) <= 8.0:
						u.command_attack(v as Unit)
						return true
			if u.attack_target != null:
				return true
			if gate.is_closed and not gate.is_shattered:
				if _flat(u.global_position, GATE_POS) < 8.0:
					u.command_attack(gate)
				elif not u.is_attack_moving():
					u.command_attack_move(GATE_WAIT)
			elif keep and is_instance_valid(keep) and keep.is_alive():
				if _flat(u.global_position, keep.global_position) < 9.0:
					u.command_attack(keep)
				elif not u.is_attack_moving():
					u.command_attack_move(KEEP_POS)
			return true
		&"heart":
			if heartfrost == null or not heartfrost.is_alive():
				return false
			if u.attack_target == null:
				if _flat(u.global_position, HEART_POS) < 10.0:
					u.command_attack(heartfrost)
				elif not u.is_attack_moving():
					u.command_attack_move(HEART_POS)
			return true
	return false


func _on_wgate_down(_g: WardenGate) -> void:
	gates_broken += 1
	if is_ending():
		return
	if fire_once(&"E8"):
		say_l("L19")
	set_objective(&"sec_gates", "done" if gates_broken >= 2 else "active")


func _on_gate_shattered(_g: FrostGate) -> void:
	if hud:
		hud.show_message(MSG_GATE_FELL, 5.0)
	_show_choice_panel()


# ---------------------------------------------------------------- the Heartfrost, Aldra

func _heart_regens() -> bool:
	return enemies_near(HEART_POS, 8.0) == 0


func _on_heart_melted(_h: Heartfrost) -> void:
	if is_ending():
		return
	fire_once(&"E12")
	say_l("L27")
	set_objective(&"obj_heartfrost", "failed")
	lose(DEFEAT_DELAY)


func _aldra_guard(_attacker: Variant) -> bool:
	if aldra == null or not is_instance_valid(aldra):
		return false
	aldra.hp = aldra.max_hp
	set_dormant(aldra, true)
	aldra.visible = false
	aldra.global_position = ALDRA_BACK_AT
	_aldra_back_left = ALDRA_BACK
	if fire_once(&"E13"):
		say_l("L28")
	return true


func _tick_aldra(dt: float) -> void:
	if _aldra_back_left < 0.0 or aldra == null or not is_instance_valid(aldra):
		return
	_aldra_back_left -= dt
	if _aldra_back_left > 0.0:
		return
	_aldra_back_left = -1.0
	set_dormant(aldra, false)
	aldra.visible = true
	aldra.hp = aldra.max_hp
	aldra.global_position = ALDRA_BACK_AT
	aldra.death_guard = _aldra_guard


# ---------------------------------------------------------------- the end

## E10: dawn (20:00), or both Warden Gates broken and the last push dead.
func _dawn() -> void:
	if is_ending() or not fire_once(&"E10"):
		return
	if branch == &"":
		_branch_shut()
	victory_time = mission_time()
	set_objective(&"obj_dawn", "done")
	if branch == &"open":
		set_objective(&"obj_town", "done" if saved >= saved_needed() else "failed")
	if objective_state("sec_gates") == "active":
		set_objective(&"sec_gates", "failed")
	if objective_state("sec_lake") == "active":
		set_objective(&"sec_lake", "done" if heart_min >= 0.5 else "failed")
	set_mission_flag("e6m2_time", int(victory_time))
	set_mission_flag("e6m2_gate_opened", gate_opened)
	set_mission_flag("e6m2_town_saved", branch == &"open" and saved >= saved_needed())
	set_mission_flag("e6m2_saved_count", saved)
	crumble_enemies()
	if _panel and is_instance_valid(_panel):
		_panel.queue_free()
	if hero_alive():
		hero.global_position = Vector3(0.0, 0.0, -30.0) if branch == &"open" else Vector3(0.0, 0.0, -16.0)
		hero.command_stop()
	if branch == &"open":
		play_cutscene(&"e6m2_dawn_open", _dawn_open_end)
	else:
		play_cutscene(&"e6m2_dawn_shut", _dawn_shut_end)


func _dawn_open_end() -> void:
	say_l("L21")
	say_l("L22")
	win(1.0)


func _dawn_shut_end() -> void:
	for id in ["L23", "L24", "L25"]:
		say_l(id)
	win(1.0)


func _on_player_hero_fell() -> void:
	fire_once(&"E11")
	say_l("L26")
	set_objective(&"obj_torvald", "failed")
	super()


# ---------------------------------------------------------------- save / load

func save_state(ids: Dictionary = {}) -> Dictionary:
	var d := super(ids)
	if heartfrost:
		d["heart_hp"] = heartfrost.hp
	if gate:
		d["gate"] = [gate.hp, gate.is_closed, gate.is_shattered]
	return d


## The rebuilt mission gets back the Heartfrost's HP, the gate's state, the panel and Aldra's guard.
func load_state(d: Dictionary, nodes: Dictionary = {}) -> void:
	super(d, nodes)
	if heartfrost and d.has("heart_hp"):
		heartfrost.hp = float(d["heart_hp"])
	if gate and d.has("gate"):
		var g: Array = d["gate"]
		gate.hp = float(g[0])
		gate.is_shattered = bool(g[2])
		gate.set_closed(bool(g[1]) and not gate.is_shattered)
	if choice_at >= 0.0:
		_show_choice_panel()
	if aldra and is_instance_valid(aldra):
		restore_guard(aldra, _aldra_guard)
		if _aldra_back_left > 0.0 and not is_dormant(aldra):
			set_dormant(aldra, true)
			aldra.visible = false


# ---------------------------------------------------------------- every frame

func _physics_process(delta: float) -> void:
	super(delta)
	if not match_started or game_over or world_is_held or save_restoring:
		return
	tick_scripted(delta)
	if is_ending():
		return
	_tick_aldra(delta)
	if heartfrost:
		heart_min = minf(heart_min, heartfrost.ratio())
		if heart_min < 0.5 and objective_state("sec_lake") == "active":
			set_objective(&"sec_lake", "failed")
	_fast -= delta
	if _fast <= 0.0:
		_fast = 0.25
		_tick_town(0.25)
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.5
		_tick_choice()
		_tick_host()
		enforce_max(&"ice_lodge", MAX_LODGES, MSG_ONE_LODGE)
		enforce_max(&"ice_wall", 16, MSG_WALLS)
		objectives_changed.emit()
		if hud and mission_hud == null:
			hud.set_objective(_objective_text())
