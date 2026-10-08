class_name Mission04
extends MissionBase
## Mission 4 "The Hollow Throne", the finale of Episode 1 (docs/design/mission-04.md, tasks 19.C5a-c): Crown Hollow at
## war with the river on. Phase 0 is a normal battle against Malrik (bot profile `mission_04`) while the Hollow meter
## fills (every death +1 %, Malrik +8 %, time +0.1 % / s); Vessa takes the Master's seat on Crown Isle (3 s on the
## Throne stone, no Shadow on the isle) or the meter reaches 100 %: the Rise. Phase 1: four Keystone Pylons ward the
## Keystone Colossus; phase 2: it walks to the Fire keep; the darkest hour brings Old Vey; phase 3: Turn the Key beside
## him until the Colossus falls. Boss, pylons and Vey live in M04Keystone; this script is the story (E1-E18, the 25
## lines, the 6 cinematic hooks with their skip end states and fallback cards, the crash-safe ending).
## Mission-time clock (MissionBase.after / mission_time; held time excluded).

const MISSION_ID := &"m04"
const MISSION_TITLE := "The Hollow Throne"

const EMBER_HALL_POS := Vector3(-27.0, 0.0, 45.0)
const EMBER_SPIRE_POS := Vector3(-37.0, 0.0, 29.0)
const HEARTH_SPOTS: Array[Vector3] = [Vector3(-50.0, 0.0, 46.0), Vector3(-50.0, 0.0, 52.0)]
const GLOOM_HALL_POS := Vector3(27.0, 0.0, -45.0)
const NIGHT_SPIRE_POS := Vector3(37.0, 0.0, -29.0)
const HOVEL_SPOTS: Array[Vector3] = [Vector3(50.0, 0.0, -46.0), Vector3(50.0, 0.0, -52.0)]
const DUSK_KEEP_HP := 1500.0
const SHADOW_RALLY := Vector3(30.0, 0.0, -30.0)
const GLOOM_SPAWN := Vector3(24.0, 0.0, -40.0)
const NORTH_EDGE := Vector3(-20.0, 0.0, -58.0)
const ARMY_POS := Vector3(-30.0, 0.0, 30.0)
const THRONE_POS := Vector3.ZERO
const ISLE_RADIUS := 11.0          ## No ENEMY unit within this of (0, 0): the seat fills.
const ISLE_PUSH_FROM := 14.6       ## The Rise: every other unit within this goes to the bank...
const ISLE_PUSH_TO := 16.5         ## ...this far out, on its own bearing.
const SEAT_RADIUS := 3.0
const SEAT_TIME := 3.0
const ISLE_HINT_RADIUS := 16.0
const PELL_POS := Vector3(-22.0, 0.0, -22.0)
const PELL_RADIUS := 10.0
## P1 (west, lane), P2 (west, Reed Ford), P3 / P4 their point mirrors (mission-04.md "Map", clearance checked there).
const PYLON_SPOTS: Array[Vector3] = [Vector3(-12.75, 0.0, 21.25), Vector3(-15.0, 0.0, -34.0),
		Vector3(12.75, 0.0, -21.25), Vector3(15.0, 0.0, 34.0)]
const RISE_VESSA := Vector3(-11.0, 0.0, 11.0)
## The phase-2 walk: the West Crown Bridge, then the lane to the Fire keep (61 m).
const WALK_PATH: Array[Vector3] = [Vector3(-9.02, 0.0, 9.02), Vector3(-18.0, 0.0, 18.0), Vector3(-28.0, 0.0, 28.0),
		Vector3(-38.0, 0.0, 38.0)]
## Pacing (2026-10-06): the spec's home nodes 1 500 / 1 500 ran dry at ~4:30 with a full worker line (the scripted run
## then had to mine the natural beside Crown Isle, inside the isle guard's and later the Colossus's reach); 2 500 each
## keeps the home economy alive into phase 1 (spec total 7 000 -> 9 000).
const M4_NODE_AMOUNTS := {&"a": 2500, &"b": 2500, &"mid": 2000, &"rich": 2000}

const ISLE_GUARD_UNTIL := 300.0
const FIRST_ATTACK_AT := 330.0     ## The bot may launch attacks from here (its first one lands ~6:00).
const STRIKE_DELAY := 20.0
const STRIKE_RECRUIT_EVERY := 60.0   ## Phase 1: the bot's new soldiers at its rally join the pylon strike this often.
const STRIKE_RECRUIT_RADIUS := 16.0
const RAID_EVERY := 180.0
const MALRIK_RESPAWN := 60.0
const DEFEAT_DELAY := 3.0
const HOLLOW_PER_DEATH := 1.0
const HOLLOW_MALRIK := 8.0
const HOLLOW_PER_SECOND := 0.1
const HOLLOW_MESSAGES: Array[int] = [25, 50, 75]
const DARKEST_BOSS_PCT := 0.4
const DARKEST_KEEP_PCT := 0.5
const KEEP_LOW_PCT := 0.3
const DARKEST_CLEAR_RADIUS := 25.0
const VEY_OFFSET := 3.0
const LEVEL_CAP := 8
const NO_SAVE_ESSENCE := 600
const FLASH_RADIUS := 12.0
const FLASH_COLOR := Color(1.0, 0.75, 0.3)

const COUNT_MULT: Array[float] = [0.6, 1.0, 1.4]
const START_CRYSTALS: Array[int] = [500, 400, 300]
const HOLLOW_RISE: Array[float] = [120.0, 100.0, 100.0]
const MALRIK_LEVEL: Array[int] = [4, 5, 6]
const MALRIK_SPELLS := [
	[&"shadow_lance", &"soul_siphon", &"umbral_shroud", &"shadow_lance"],
	[&"shadow_lance", &"soul_siphon", &"umbral_shroud", &"shadow_lance", &"soul_siphon"],
	[&"shadow_lance", &"soul_siphon", &"umbral_shroud", &"shadow_lance", &"soul_siphon", &"umbral_shroud"],
]
const HALL_UNITS: Array[StringName] = [&"flame_guard", &"ember_archer", &"blaze_rider", &"ash_hurler"]
const TIER2_HALL_UNITS: Array[StringName] = [&"pyre_adept", &"cinder_arbalest"]

const SPEAKER_COLORS := {
	&"vessa": Color(1.0, 0.45, 0.1),
	&"malrik": Color(0.7, 0.3, 1.0),
	&"narrator": Color(0.9, 0.85, 0.7),
	&"whisper": Color(1.0, 0.80, 0.25),
	&"obren": Color(1.0, 0.80, 0.25),
	&"vey": Color(0.95, 0.95, 0.55),
	&"pell": Color(0.85, 0.75, 0.5),
}
const SPEAKER_NAMES := {&"vessa": "Vessa", &"malrik": "Malrik", &"narrator": "Narrator", &"whisper": "???",
		&"obren": "Obren", &"vey": "Vey", &"pell": "Pell"}
## The 25 lines (L22 unused); LINE_IDS[i] is the spec id of DIALOGUE[i] (say_id says each once).
const LINE_IDS: Array[StringName] = [&"L1", &"L2", &"L3", &"L4", &"L5", &"L6", &"L7", &"L8", &"L9", &"L10", &"L11",
		&"L12", &"L13", &"L14", &"L15", &"L16", &"L17", &"L18", &"L19", &"L20", &"L21", &"L23", &"L24", &"L25", &"L26"]
const DIALOGUE := [
	[&"narrator", "Crown Hollow. Where the Master once sat, two armies wait for the sun."],
	[&"malrik", "Three relics, little ember. Hand them over and I'll let you keep the hat."],
	[&"vessa", "Come and take them, Bishop. You owe me for Emberfall. And for Vey."],
	[&"whisper", "Yes. Come, both of you. Fight on my roof."],
	[&"obren", "Yes. Fight. Every fallen soldier is a step on my stair."],
	[&"vessa", "The ground is breathing. That can't be good."],
	[&"obren", "A hundred years in the dark. I had time to practise my entrance."],
	[&"vessa", "I had ten minutes to practise running. Those pillars feed it. Break them all!"],
	[&"malrik", "A giant made of rubble, in MY war? Shades, kill the pillars. Then kill Vessa."],
	[&"vessa", "Two down. Keep hitting the glowing parts. It's always the glowing parts."],
	[&"obren", "Enough. I will walk to your little fire and put it out myself."],
	[&"obren", "This body... cracks... No matter. Stone is patient."],
	[&"vessa", "Not the keep! I JUST had it redecorated!"],
	[&"vessa", "Everyone, back to the keep! BACK!"],
	[&"vey", "Stay close, girl. Whatever it throws at you, I'll ground it."],
	[&"vessa", "Crown, orb, signet. Let's see what you do together."],
	[&"obren", "His storm? Impossible! That light should have faded a hundred years ago!"],
	[&"vessa", "Nobody stays faded around here. Ask Vey."],
	[&"vey", "The spark was yours, Vessa. NOW the storm!"],
	[&"vessa", "Somebody... finish my war..."],
	[&"obren", "The Hollow... remembers..."],
	[&"vey", "Just resting my knees. Keep turning that key!"],
	[&"malrik", "One pillar down. You're welcome, little ember. Don't get used to it."],
	[&"malrik", "An old man and a thunderstorm. Shades, fall back. I'll collect whatever is left."],
	[&"pell", "Last stall before the end of the world! Everything must go. Including me, quickly."],
]
const BRIEFING_PARAGRAPHS: Array[String] = [
	"The parley failed. Ice and Nature walked away, and Malrik named the place himself: Crown Hollow, at dawn, where the Master once sat and where this war began over a crown.",
	"Vessa carries all three relics now: the Ember Crown, the Stillwater Orb and the Master's Signet. They have stopped humming. They are pulling, toward the ruined throne on Crown Isle, and the voice inside them sounds very pleased.",
	"Ysolde called the relics a lock. Somewhere under the isle, something has been counting every soldier who falls. Vessa means to end the war today. She is about to find out what the war has been feeding.",
]
const BRIEFING_HOLLOW_LINE := "Every fallen soldier feeds the Hollow."
const HINT_START := "Every death feeds the Hollow. Take the Master's seat on Crown Isle when YOU are ready."
const HINT_ISLE := "Clear the isle of Shadow, then stand on the Throne stone for 3 s."
const HINT_PYLONS := "Break the four Keystone Pylons. The Colossus cannot be hurt while one stands."
const HINT_KEY := "Stand within 4 m of the Colossus for 3 s with Vessa. Keep Old Vey close: the Hollow Pulse can't break the key while he grounds it."
const MSG_HOLLOW_25 := "The ground under Crown Hollow is warm."
const MSG_GUARD_FALLS_BACK := "Malrik's isle guard falls back to his army."
const MSG_MALRIK_FELL := "Malrik has fallen back into the shadows"
const MSG_STAGGER := "The Colossus staggers!"
const HINT_SPOTLIGHT := "Kilnwarden: Slag Rain the Colossus. Its stone armour melts from 25 to 5."
const MSG_VEY_DOWN := "Old Vey is down! The storm will return."
const MSG_SEAT_BLOCKED := "Shadow still holds the isle"
## Cinematic fallback cards (ep1 7.4 placeholders until the films exist): [id, title, sub, lines [speaker, text, s]].
const CARD_RISE_TEXT := "The Throne stone cracks. Amber light pours up through the isle, the pillars fall into the moat, and a giant of rubble and old stone climbs out of the Hollow, a burning heart in its chest. Four pillars rise around the water, each feeding it a golden thread."
const CARD_STORM_TEXT := "The Colossus raises its fist over Vessa. Thunder answers. A bolt splits the sky, the giant staggers to its knees, and out of the storm walks an old man with a sword that hums like a struck bell. Old Vey is alive."
const CARD_ENDING_TEXT := "Fire and lightning shatter the heart. Obren's body falls. In the grey dawn Malrik picks up the still-pulsing heart-stone and melts into the mist with it while the Shadow army withdraws. Vey tells Vessa the Master is alive below, and the three relics turn white-gold and point down."
const CARD_CREDITS_TEXT := "Episode 1: The Hollow Throne. Thank you for playing. Episode 2 begins where the relics point: down."

## Test / menu switch (before the tree): campaign flags to use instead of the save ({} = read the save).
var flag_override: Dictionary = {}
## Test switch (before the tree): crystals per Fire / Shadow node suffix (a, b, mid, rich).
var node_amounts: Dictionary = M4_NODE_AMOUNTS.duplicate()

var phase := 0                            ## Read only: 0 war, 1 ward, 2 walk, 3 storm, 4 fallen (-1 while rising).
var hollow := 0.0                         ## Read only: the Hollow meter in percent.
var hollow_shown := true                  ## Read only: false from the Rise on.
var seat_progress := 0.0                  ## Read only: 0-1 while Vessa sits.
var seat_blocked := false                 ## Read only: an ENEMY unit is on the isle.
var seat_taken := false                   ## Read only: the Rise came from the seat.
var keystone: M04Keystone                 ## Read only.
var ember_hall: TrainingBuilding          ## Read only.
var gloom_hall: Building                  ## Read only.
var isle_guard: Array = []                ## Read only.
var strike_units: Array = []              ## Read only: the pylon strike (bot army + scripted).
var raids_sent := 0                       ## Read only.
var push_units: Array = []                ## Read only.
var pylons_broken := 0                    ## Read only.
var shadow_pylons := 0                    ## Read only: pylons broken by the ENEMY team.
var said_ids: Array[StringName] = []      ## Read only: the line ids said, in order.
var peddler_freed := false                ## Read only.
var no_save_fallback := false             ## Read only.
var heart_stone: Node3D                   ## Read only: the ending actor.
var darkest_by := &""                     ## Read only: &"boss" / &"keep" (what triggered the darkest hour).
var story_films := false                  ## Read only: the ending films play after the victory (first story win).
var rise_time := -1.0                     ## Read only: mission time of the Rise.
var walk_time := -1.0                     ## Read only: mission time of phase 2.
var storm_time := -1.0                    ## Read only: mission time of phase 3.
var cards_played: Array[StringName] = []  ## Read only: fallback cards that actually played.

var _flags_read := false
var _hall_type: BuildingType
var _said: Dictionary = {}
var _hollow_msgs: Dictionary = {}
var _isle_hint_shown := false
var _raid_left := RAID_EVERY
var _throne: Node3D
var _seat_ring: MeshInstance3D
var _seat_mat: StandardMaterial3D
var _card_actors := {}
var _storm_dark := false
var _hollow_clock := -1.0
var _recruit_left := STRIKE_RECRUIT_EVERY


# ---------------------------------------------------------------- setup

func _init() -> void:
	super()
	tavern_enabled = true   # the west tavern only (_add_taverns)
	river_enabled = true    # Hollowmere and its 8 crossings; no camps / points / beasts / trade
	dialogue_lines = DIALOGUE
	speaker_colors = SPEAKER_COLORS.duplicate()
	speaker_names = SPEAKER_NAMES.duplicate()
	briefing_paragraphs = BRIEFING_PARAGRAPHS.duplicate()
	define_objectives([[&"obj_isle", "primary"], [&"obj_pylons", "primary"], [&"obj_colossus", "primary"],
			[&"obj_key", "primary"], [&"obj_vessa", "primary"], [&"obj_keep", "primary"], [&"sec_seat", "secondary"],
			[&"sec_hall", "secondary"]])


func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	c.mission_id = MISSION_ID
	c.title = MISSION_TITLE
	c.count_mult = COUNT_MULT.duplicate()
	c.defeat_on_keep_lost = false   # E17 (obj_keep failed, defeat after 3 s)
	c.tiers_enabled = true
	c.max_tier = 2
	c.bots_upgrade = false
	c.start_tiers = {Unit.Team.PLAYER: 2}
	c.casters_enabled = true
	c.start_crystals = START_CRYSTALS.duplicate()
	c.start_level = 4
	c.start_spell_points = 3
	c.level_cap = LEVEL_CAP
	c.instant_loss_on_wizard_death = true
	c.defeat_delay = DEFEAT_DELAY
	c.bot_profile_id = &"mission_04"
	c.bot_team = Unit.Team.ENEMY
	c.victory_banner = "VICTORY\nThe Hollow Throne is broken"
	c.defeat_banner = "DEFEAT"
	c.rewards = {"flags": {"m4_seat_taken": "sec_seat", "m4_hall_burned": "sec_hall"},
			"bonus_essence": {"sec_seat": 300, "sec_hall": 300},
			"set_flags": {"ep1_complete": true, "ep1_vey_returned": true, "ep1_shard_to_malrik": true}, "next": &"e2m1"}
	c.spotlight = {"id": &"kilnwarden", "trigger": &"start", "key_hint": "Keep: B",
			"card": "Kilnwarden. Melts armour, burns mana: it makes big things soft and casters empty."}
	return c


func _ready() -> void:
	_hall_type = _make_hall_type()
	get_tree().node_added.connect(_on_m4_node_added)
	super()
	_apply_storm_dusk()


func _exit_tree() -> void:
	if get_tree().node_added.is_connected(_on_m4_node_added):
		get_tree().node_added.disconnect(_on_m4_node_added)


func _title_line() -> String:
	return "Mission 4: %s" % MISSION_TITLE


## Only the west tavern ("The Lantern at the Ford"), hiring from 0:00.
func _add_taverns(spots: Array[Vector3]) -> void:
	var west: Array[Vector3] = [spots[0]]
	super(west)
	for t in taverns:
		t.open_time = 0.0


## The ruined pillar ring, tagged so the Rise can take it away (plain obstacles, not the shared prop batch).
func _add_pillar(pos: Vector3, height: float) -> void:
	var shape := CylinderShape3D.new()
	shape.radius = 0.7
	shape.height = height
	var body := _static_obstacle(pos, shape, height * 0.5)
	body.add_to_group(&"m4_pillars")
	if _SIM.enabled:
		return
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.55
	cyl.bottom_radius = 0.7
	cyl.height = height
	cyl.radial_segments = 8
	_mesh(body, cyl, Color(0.55, 0.52, 0.6), height * 0.5)


# ---------------------------------------------------------------- the map

func _build_map() -> void:
	_read_flags()
	super()   # Crown Hollow with the river (skirmish seed), its keeps, nodes, peddlers, the west tavern
	for id: StringName in crystal_nodes:
		var n := crystal_nodes[id] as CrystalNode
		var suffix := String(id).get_slice("_", 2)
		if n and node_amounts.has(StringName(suffix)):
			n.crystals_left = int(node_amounts[StringName(suffix)])
	shadow_keep.max_hp = DUSK_KEEP_HP
	shadow_keep.hp = DUSK_KEEP_HP
	ember_hall = build_grid.spawn_complete(BuildingType.find("fire_barracks"), EMBER_HALL_POS,
			Unit.Team.PLAYER) as TrainingBuilding
	build_grid.spawn_complete(BuildingType.find("fire_tower"), EMBER_SPIRE_POS, Unit.Team.PLAYER)
	for p in HEARTH_SPOTS:
		build_grid.spawn_complete(BuildingType.find("fire_hearth"), p, Unit.Team.PLAYER)
	gloom_hall = build_grid.spawn_complete(BuildingType.find("shadow_barracks"), GLOOM_HALL_POS, Unit.Team.ENEMY)
	build_grid.spawn_complete(BuildingType.find("shadow_tower"), NIGHT_SPIRE_POS, Unit.Team.ENEMY)
	for p in HOVEL_SPOTS:
		build_grid.spawn_complete(BuildingType.find("shadow_hovel"), p, Unit.Team.ENEMY)
	# The west peddler spot: Pell (m1_peddler_freed) or empty.
	for ped in peddlers.duplicate():
		var p3 := ped as Node3D
		if p3 == null or p3.position.distance_to(PELL_POS) > 1.0:
			continue
		if peddler_freed:
			p3.name = "Pell"
			p3.set(&"display_name", "Pell, Ruin Peddler")
		else:
			peddlers.erase(ped)
			p3.get_parent().remove_child(p3)
			p3.queue_free()
	_add_throne()


func _read_flags() -> void:
	if _flags_read:
		return
	_flags_read = true
	var flags := {}
	if not flag_override.is_empty():
		flags = flag_override
	else:
		var cs := CampaignState.open(campaign_save_path)
		no_save_fallback = not cs.is_completed(&"m03") and not cs.is_completed(&"m02")
		if not no_save_fallback:
			flags = cs.flags
		story_films = not cs.is_completed(MISSION_ID)
	peddler_freed = bool(flags.get("m1_peddler_freed", false))


## The Throne stone (no collider: the seat is stood on) and the seat ring.
func _add_throne() -> void:
	_throne = Node3D.new()
	_throne.name = "ThroneStone"
	add_child(_throne)
	_throne.position = THRONE_POS
	if not _SIM.enabled:
		var slab := CylinderMesh.new()
		slab.top_radius = 1.6
		slab.bottom_radius = 1.9
		slab.height = 0.35
		slab.radial_segments = 8
		_mesh(_throne, slab, Color(0.42, 0.40, 0.44), 0.17)
		var back := BoxMesh.new()
		back.size = Vector3(2.4, 2.6, 0.5)
		var b := _mesh(_throne, back, Color(0.38, 0.36, 0.40), 1.6)
		b.position.z = -1.4
	var disc := CylinderMesh.new()
	disc.top_radius = SEAT_RADIUS
	disc.bottom_radius = SEAT_RADIUS
	disc.height = 0.04
	disc.radial_segments = 40
	_seat_mat = StandardMaterial3D.new()
	_seat_mat.albedo_color = Color(1.0, 0.75, 0.3, 0.15)
	_seat_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_seat_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_seat_ring = MeshInstance3D.new()
	_seat_ring.mesh = disc
	_seat_ring.material_override = _seat_mat
	_throne.add_child(_seat_ring)
	_seat_ring.position.y = 0.05


## Storm dusk (mission-04.md "Map"): a low amber sun and a violet-grey sky on the warm rig.
func _apply_storm_dusk() -> void:
	var rig := get_node_or_null(^"LightingRig")
	if rig == null:
		return
	var sun := rig.get(&"sun") as DirectionalLight3D
	if sun:
		sun.light_color = Color(1.0, 0.72, 0.45)
		sun.light_energy *= 0.8
		sun.rotation_degrees.x = -22.0
	var we := rig.get(&"world_environment") as WorldEnvironment
	if we and we.environment:
		var env := we.environment
		env.ambient_light_color = Color(0.62, 0.55, 0.70)
		var sky_mat := env.sky.sky_material as ProceduralSkyMaterial if env.sky else null
		if sky_mat:
			sky_mat.sky_top_color = Color(0.30, 0.27, 0.38)
			sky_mat.sky_horizon_color = Color(0.78, 0.55, 0.42)


## The darkest hour: storm clouds (darker, colder light).
func _apply_storm_layer() -> void:
	if _storm_dark:
		return
	_storm_dark = true
	var rig := get_node_or_null(^"LightingRig")
	var sun := rig.get(&"sun") as DirectionalLight3D if rig else null
	if sun:
		sun.light_color = Color(0.75, 0.78, 0.95)
		sun.light_energy *= 0.7


# ---------------------------------------------------------------- start state

func _on_navigation_ready() -> void:
	fog.reveal(Unit.Team.ENEMY, SHADOW_START, FogOfWar.START_REVEAL)
	var diff := clampi(mission_difficulty, 0, 2)
	hero = _make_wizard(Unit.Team.PLAYER)
	_spawn(hero, Unit.Team.PLAYER, PLAYER_START)
	_claim_wizard(hero, Unit.Team.PLAYER)
	ItemDrops.ensure_inventory(hero)
	_apply_campaign_start()
	for i in 6:
		var cinder := _spawn(make_unit("cinder_hand"), Unit.Team.PLAYER,
				PLAYER_START + Vector3(-4.0 + i * 1.2, 0.0, 4.0 - i * 1.2))
		cinder.call(&"command_gather", node_of(Unit.Team.PLAYER, "a" if i < 3 else "b"))
	var army: Array[String] = []
	for row in [["flame_guard", 8], ["ember_archer", 5], ["blaze_rider", 2], ["ash_hurler", 3]]:
		for k in int(row[1]):
			army.append(String(row[0]))
	for i in army.size():
		_spawn(make_unit(army[i]), Unit.Team.PLAYER, ARMY_POS + Vector3(-4.5 + (i % 6) * 1.6, 0.0, -2.0 + (i / 6) * 1.7))

	shadow_hero = _make_wizard(Unit.Team.ENEMY)
	_spawn(shadow_hero, Unit.Team.ENEMY, SHADOW_RALLY + Vector3(2.0, 0.0, -2.0))
	_claim_wizard(shadow_hero, Unit.Team.ENEMY)
	raise_wizard(shadow_hero, MALRIK_LEVEL[diff], MALRIK_SPELLS[diff])
	ItemDrops.ensure_inventory(shadow_hero)
	shadow_hero.died.connect(_on_malrik_died)
	for i in 6:
		var thrall := _spawn(make_unit("gloom_thrall"), Unit.Team.ENEMY,
				SHADOW_START + Vector3(4.0 - i * 1.2, 0.0, -4.0 + i * 1.2))
		thrall.call(&"command_gather", node_of(Unit.Team.ENEMY, "a" if i < 3 else "b"))
	var shadow_army: Array[String] = []
	for row in [["shade", 8], ["nightbolt", 4], ["shadow_knight", 2]]:
		for k in int(row[1]):
			shadow_army.append(String(row[0]))
	for i in shadow_army.size():
		_spawn(make_unit(shadow_army[i]), Unit.Team.ENEMY,
				SHADOW_RALLY + Vector3(-4.0 + (i % 5) * 1.6, 0.0, 2.0 - (i / 5) * 1.7))
	isle_guard = spawn_group([["shade", 6], ["nightbolt", 3]], THRONE_POS, 5.0, Unit.Team.ENEMY, true)

	_spawn_caches()
	_setup_champions()
	keystone = M04Keystone.new()
	keystone.name = "Keystone"
	add_child(keystone)
	keystone.setup(self, diff)
	keystone.pylon_destroyed.connect(_on_pylon_destroyed)
	keystone.exposed.connect(_on_exposed)
	keystone.vey_down.connect(_on_vey_down)
	keystone.colossus_died.connect(_on_colossus_died)
	keystone.cracked_leg.connect(_on_cracked_leg)
	var ev := get_node_or_null(^"/root/Events")
	if ev:
		ev.unit_died.connect(_on_any_unit_died)
	wizard_respawned.connect(_on_m4_wizard_respawned)
	_add_events()
	begin_mission([&"obj_isle", &"obj_vessa", &"obj_keep", &"sec_seat", &"sec_hall"])
	_set_bot_knob(&"launch_attacks", false)   # 19.A1: the first attack around 6:00, not with the start army
	after(FIRST_ATTACK_AT, func() -> void:
		if phase >= 0 and phase < 3:
			_set_bot_knob(&"launch_attacks", true))


## CampaignState.apply_to_start (items, carried essence, companion, flags meta). No save from missions 2-3 (menu
## debug, tests): the three relics owned, Signet + Crown equipped, essence 150 + 600, no companion, flags false.
func _apply_campaign_start() -> void:
	_read_flags()
	if no_save_fallback or not flag_override.is_empty():
		set_meta(&"campaign_flags", {"m1_peddler_freed": peddler_freed})
		force_artifacts(hero, ["masters_signet", "ember_crown"])
		if no_save_fallback:
			var bank := EssenceBank.for_team(Unit.Team.PLAYER)
			if bank:
				bank.add(NO_SAVE_ESSENCE)
		return
	CampaignState.open(campaign_save_path).apply_to_start(self)


func _add_events() -> void:
	add_event(&"E2", func() -> bool: return peddler_freed and hero_alive() \
			and _flat(hero.global_position, PELL_POS) <= PELL_RADIUS, func() -> void: say_id(&"L26"))
	add_event(&"E4", func() -> bool: return phase == 0 and hero_alive() \
			and _flat(hero.global_position, THRONE_POS) <= ISLE_HINT_RADIUS, func() -> void:
				_isle_hint_shown = true
				hud.show_message(HINT_ISLE, 8.0))
	after(ISLE_GUARD_UNTIL, _e5_guard_falls_back)
	add_event(&"E11", func() -> bool: return _keep_pct() < KEEP_LOW_PCT and _keep_pct() > 0.0,
			func() -> void: say_id(&"L13"))
	add_event(&"E12", func() -> bool:
		return phase == 2 and (keystone.colossus_hp_pct() <= DARKEST_BOSS_PCT or _keep_pct() <= DARKEST_KEEP_PCT),
			_e12_darkest_hour)
	add_event(&"E17", func() -> bool: return keep == null or not is_instance_valid(keep) or not keep.is_alive(),
			_e17_keep_lost)
	add_event(&"sec_hall", func() -> bool: return gloom_hall == null or not is_instance_valid(gloom_hall) \
			or not gloom_hall.is_alive(), func() -> void: set_objective(&"sec_hall", "done"))


# ---------------------------------------------------------------- briefing, objectives, lines

func briefing() -> Dictionary:
	return {
		"title": _title_line(),
		"paragraphs": BRIEFING_PARAGRAPHS.duplicate(),
		"objectives": [objective_text(&"obj_isle", false), objective_text(&"obj_keep"), BRIEFING_HOLLOW_LINE],
		"rule": objective_text(&"obj_vessa"),
	}


func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_isle":
			if with_counter and hollow_shown:
				return "Take the Master's seat on Crown Isle (the Hollow stirs: %d %%)" % int(hollow)
			return "Take the Master's seat on Crown Isle"
		&"obj_pylons":
			return "Break the Keystone Pylons (%d / 4)" % pylons_broken if with_counter else "Break the Keystone Pylons"
		&"obj_colossus":
			if with_counter and keystone and keystone.colossus_alive():
				return "Stop the Keystone Colossus (%d %%)" % int(round(keystone.colossus_hp_pct() * 100.0))
			return "Stop the Keystone Colossus"
		&"obj_key":
			return "Turn the key: Vessa by the Colossus's heart, with Old Vey beside her"
		&"obj_vessa":
			return "Vessa must survive"
		&"obj_keep":
			return "The Fire keep must stand"
		&"sec_seat":
			return "Take the seat before the Hollow wakes on its own"
		&"sec_hall":
			return "Burn Malrik's Gloom Hall"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_isle":
			if not hollow_shown:
				return {"position": THRONE_POS}
			return {"progress": int(hollow), "goal": 100, "counter": "Hollow %d %%" % int(hollow), "position": THRONE_POS}
		&"obj_pylons":
			var standing: Array = []
			if keystone:
				for p in keystone.pylons:
					if is_instance_valid(p) and p.is_alive():
						standing.append(p.global_position)
			return {"progress": pylons_broken, "goal": 4, "counter": "%d / 4" % pylons_broken, "positions": standing}
		&"obj_colossus", &"obj_key":
			if keystone and keystone.colossus_alive():
				var pct := int(round(keystone.colossus_hp_pct() * 100.0))
				return {"progress": pct, "goal": 100, "counter": "%d %%" % pct,
						"position": keystone.colossus.global_position}
		&"sec_hall":
			return {"position": GLOOM_HALL_POS}
	return {}


## Says the spec line `id` (L1..L26) once per run.
func say_id(id: StringName) -> void:
	if _said.has(id):
		return
	var i := LINE_IDS.find(id)
	if i < 0:
		push_error("Mission04: unknown line %s" % id)
		return
	_said[id] = true
	said_ids.append(id)
	say_line(i + 1)


# ---------------------------------------------------------------- the tick

func _physics_process(delta: float) -> void:
	super(delta)
	if not match_started or game_over or world_is_held:
		return
	tick_scripted(delta)
	if phase == 0:
		var now := mission_time()   # mission time, so held cinematic time never feeds the Hollow
		if _hollow_clock < 0.0:
			_hollow_clock = now
		_add_hollow(HOLLOW_PER_SECOND * maxf(0.0, now - _hollow_clock))
		_hollow_clock = now
		if phase == 0:
			_tick_seat(delta)
	elif phase == 1:
		_raid_left -= delta
		if _raid_left <= 0.0:
			_raid_left = RAID_EVERY
			_send_raid()
		if has_fired(&"E7"):
			_recruit_left -= delta
			if _recruit_left <= 0.0:
				_recruit_left = STRIKE_RECRUIT_EVERY
				_recruit_strike()


func _add_hollow(amount: float) -> void:
	if phase != 0 or is_ending():
		return
	var before := int(hollow)
	hollow = minf(hollow + amount, 999.0)
	var now := int(hollow)
	if now != before:
		set_objective(&"obj_isle", "active")   # the counter
		for m in HOLLOW_MESSAGES:
			if now >= m and not _hollow_msgs.has(m):
				_hollow_msgs[m] = true
				_hollow_message(m)
	if hollow >= HOLLOW_RISE[clampi(mission_difficulty, 0, 2)]:
		_rise(false)


func _hollow_message(pct: int) -> void:
	match pct:
		25:
			hud.show_message(MSG_HOLLOW_25, 4.0)
		50:
			say_id(&"L5")
		75:
			say_id(&"L6")


func _on_any_unit_died(u: Node) -> void:
	if phase != 0 or world_is_held or game_over or u == null:
		return
	var unit := u as Unit
	if unit == null or unit.has_meta(&"m4_no_hollow") or unit.has_meta(&"m4_buried") or unit == hero:
		return
	if unit.unit_type and (unit.unit_type.id == &"ruin_warden" or unit.unit_type.id == &"sapling"):
		return
	_add_hollow(HOLLOW_MALRIK if unit == shadow_hero else HOLLOW_PER_DEATH)


## The Master's seat: Vessa within 3 m of the Throne stone for 3 s, no ENEMY unit on the isle (r < 11).
func _tick_seat(delta: float) -> void:
	if not hero_alive() or _flat(hero.global_position, THRONE_POS) > SEAT_RADIUS:
		seat_progress = 0.0
		seat_blocked = false
		_update_seat_ring()
		return
	seat_blocked = _enemy_on_isle()
	if not seat_blocked:
		seat_progress = minf(1.0, seat_progress + delta / SEAT_TIME)
		if seat_progress >= 1.0:
			_rise(true)
			return
	elif fire_once(&"seat_blocked_msg"):
		hud.show_message(MSG_SEAT_BLOCKED, 3.0)
	_update_seat_ring()


func _enemy_on_isle() -> bool:
	for n in get_tree().get_nodes_in_group("units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == Unit.Team.ENEMY and _flat(u.global_position, THRONE_POS) < ISLE_RADIUS:
			return true
	return false


func _update_seat_ring() -> void:
	if _seat_mat == null:
		return
	if seat_blocked:
		_seat_mat.albedo_color = Color(0.9, 0.2, 0.15, 0.35)
	else:
		_seat_mat.albedo_color = Color(1.0, 0.75, 0.3, 0.15 + 0.6 * seat_progress)


## Pillars of the ring still standing (test hook: 0 after the Rise).
func pillars_left() -> int:
	var n := 0
	for p in get_tree().get_nodes_in_group(&"m4_pillars"):
		if not (p as Node).is_queued_for_deletion():
			n += 1
	return n


func _keep_pct() -> float:
	if keep == null or not is_instance_valid(keep) or not keep.is_alive():
		return 0.0
	return keep.hp / maxf(1.0, keep.max_hp)


# ---------------------------------------------------------------- phase 0

## E1 (after the briefing): m4_war (HOLD 0:30, L1-L4 as its subtitles), then the camera on Vessa and the hint.
func _intro() -> void:
	fire_once(&"E1")
	_card_actors = {&"vessa": hero, &"malrik": shadow_hero}
	var lines: Array = []
	for id: StringName in [&"L1", &"L2", &"L3", &"L4"]:
		var row: Array = DIALOGUE[LINE_IDS.find(id)]
		lines.append([row[0], row[1], 5.5])
	var card := _card(&"m4_war", "Mission 4", MISSION_TITLE, lines, THRONE_POS, Vector3(-40.0, 34.0, 46.0),
			Vector3(-22.0, 18.0, 26.0), 30.0)
	_play_card(&"m4_war", card, _war_end_state, [&"L1", &"L2", &"L3", &"L4"])


func _war_end_state() -> void:
	camera_rig.focus_on(hero.global_position)
	hud.show_message(HINT_START, 10.0)


func _e5_guard_falls_back() -> void:
	if phase != 0 or is_ending():
		return
	fire_once(&"E5")
	var any := false
	for u in isle_guard:
		if not is_instance_valid(u) or not (u as Unit).is_alive():
			continue
		any = true
		(u as Unit).remove_from_group(SCRIPTED_GROUP)
		(u as Unit).remove_meta(SCRIPTED_GROUP)
		(u as Unit).remove_meta(META_HOME)
		_guards.erase(u)
		(u as Unit).command_move(SHADOW_RALLY)
	if any:
		hud.show_message(MSG_GUARD_FALLS_BACK, 4.0)


## E18: Malrik falls (+8 % Hollow in phase 0 through the death hook), back at the Dusk Keep after 60 s.
func _on_malrik_died(_unit: Unit) -> void:
	if game_over or is_ending():
		return
	fire_once(&"E18")
	hud.show_message(MSG_MALRIK_FELL, 4.0)
	_respawn_left[Unit.Team.ENEMY] = MALRIK_RESPAWN


func _on_m4_wizard_respawned(wiz: Wizard) -> void:
	if wiz == shadow_hero and phase >= 3:
		wiz.command_move(SHADOW_RALLY)


func respawn_point(team: int) -> Vector3:
	if team == Unit.Team.ENEMY:
		var k := keep_of(team)
		return k.spawn_point() if k else SHADOW_START
	return super(team)


# ---------------------------------------------------------------- the Rise (E6)

func _rise(by_seat: bool) -> void:
	if phase != 0 or is_ending():
		return
	phase = -1
	fire_once(&"E6")
	seat_taken = by_seat
	rise_time = mission_time()
	set_objective(&"obj_isle", "done")
	set_objective(&"sec_seat", "done" if by_seat else "failed")
	_play_card(&"m4_rise", _text_card(&"m4_rise", "The Rise", CARD_RISE_TEXT, THRONE_POS, 45.0), _rise_end_state)


## E6 end state (also on skip / no film): isle guard buried, the isle cleared to the banks, the ring and the stone
## gone (rebake), Vessa at the West Crown Bridge, the pylons risen, the Colossus at (0, 0) in phase 1; L7-L8.
func _rise_end_state() -> void:
	if phase != -1:
		return
	hollow_shown = false
	for u in isle_guard:
		if is_instance_valid(u) and (u as Unit).is_alive() and _flat((u as Unit).global_position, THRONE_POS) < ISLE_PUSH_FROM:
			(u as Unit).set_meta(&"m4_buried", true)
			(u as Unit).leave_map()
	for n in get_tree().get_nodes_in_group("units"):
		var u := n as Unit
		if u == null or u == hero or not u.is_alive() or u.has_meta(&"m4_buried"):
			continue
		var d := _flat(u.global_position, THRONE_POS)
		if d < ISLE_PUSH_FROM:
			var dir := Vector3(u.global_position.x, 0.0, u.global_position.z)
			dir = dir.normalized() if dir.length() > 0.1 else Vector3(-1.0, 0.0, 1.0).normalized()
			u.global_position = THRONE_POS + dir * ISLE_PUSH_TO
			u.command_stop()
	for p in get_tree().get_nodes_in_group(&"m4_pillars"):
		(p as Node).queue_free()
	if _throne:
		_throne.queue_free()
		_throne = null
	_add_isle_pit()
	build_grid.request_rebake()
	if hero_alive():
		hero.global_position = RISE_VESSA
		hero.command_stop()
	keystone.rise(THRONE_POS, PYLON_SPOTS)
	for p in keystone.pylons:
		SightMarker.spawn(Unit.Team.PLAYER, p.global_position, 4.0, 0.0, p)
	SightMarker.spawn(Unit.Team.PLAYER, keystone.colossus.global_position, 8.0, 0.0, keystone.colossus)
	phase = 1
	_raid_left = RAID_EVERY
	say_id(&"L7")
	say_id(&"L8")
	set_objective(&"obj_pylons", "active")
	hud.show_message(HINT_PYLONS, 8.0)
	camera_rig.focus_on(RISE_VESSA)
	after(STRIKE_DELAY, _e7_strike)


func _add_isle_pit() -> void:
	if _SIM.enabled:
		return
	var disc := CylinderMesh.new()
	disc.top_radius = 9.0
	disc.bottom_radius = 9.0
	disc.height = 0.04
	disc.radial_segments = 48
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.10, 0.08, 0.07)
	m.roughness = 1.0
	m.emission_enabled = true
	m.emission = Color(0.55, 0.25, 0.06)
	m.emission_energy_multiplier = 0.12
	var mi := MeshInstance3D.new()
	mi.name = "IslePit"
	mi.mesh = disc
	mi.material_override = m
	add_child(mi)
	mi.position = Vector3(0.0, 0.03, 0.0)


# ---------------------------------------------------------------- phase 1

## E7: L9; Malrik's army (and 4 Shades + 2 Nightbolts from the Gloom Hall) goes for P3, then P4.
func _e7_strike() -> void:
	if phase != 1 or is_ending():
		return
	fire_once(&"E7")
	say_id(&"L9")
	for n in get_tree().get_nodes_in_group("units"):
		var u := n as Unit
		if u == null or not u.is_alive() or int(u.team) != Unit.Team.ENEMY or u.has_meta(SCRIPTED_GROUP) \
				or u.is_worker() or u is Wizard:
			continue
		u.set_meta(&"m4_strike", true)
		mark_scripted(u)
		strike_units.append(u)
	var spawn := GLOOM_SPAWN if gloom_hall and is_instance_valid(gloom_hall) and gloom_hall.is_alive() else SHADOW_START
	for u in spawn_wave_at([["shade", 4], ["nightbolt", 2]], spawn):
		strike_units.append(u)
	for u in strike_units:
		order_wave(u as Unit, &"strike", _strike_target_pos())
	_recruit_left = STRIKE_RECRUIT_EVERY


## Pacing (2026-10-06): the strike is "a scripted override of the Commander's army orders until both east pylons fall"
## (mission-04.md): soldiers the bot musters at its rally during phase 1 join it too, so a player who waits for
## Malrik (the legal slow path) is not stuck forever once the first strike has died. The rally only: the bot's
## raiders and defenders elsewhere keep their own orders.
func _recruit_strike() -> void:
	if phase != 1 or is_ending() or _strike_pylon() == null:
		return
	for n in get_tree().get_nodes_in_group("units"):
		var u := n as Unit
		if u == null or not u.is_alive() or int(u.team) != Unit.Team.ENEMY or u.has_meta(SCRIPTED_GROUP) \
				or u.is_worker() or u is Wizard or _flat(u.global_position, SHADOW_RALLY) > STRIKE_RECRUIT_RADIUS:
			continue
		u.set_meta(&"m4_strike", true)
		mark_scripted(u)
		strike_units.append(u)
		order_wave(u, &"strike", _strike_target_pos())
	strike_units = strike_units.filter(func(s: Variant) -> bool: return is_instance_valid(s) and (s as Unit).is_alive())


func _strike_pylon() -> Unit:
	if keystone == null or keystone.pylons.size() < 4:
		return null
	for i in [2, 3]:
		var p: Unit = keystone.pylons[i]
		if is_instance_valid(p) and p.is_alive():
			return p
	return null


func _strike_target_pos() -> Vector3:
	var p := _strike_pylon()
	return p.global_position if p else SHADOW_RALLY


func _refresh_wave_unit(u: Unit, mode: StringName, hero_at: Vector3) -> bool:
	match mode:
		&"strike":
			var p := _strike_pylon()
			if p == null or phase >= 2:
				_release_strike_unit(u)
				return true
			if u.attack_target == null or not (u.attack_target is Unit) \
					or _flat(u.global_position, p.global_position) < 14.0:
				if u.attack_target != p and _flat(u.global_position, p.global_position) < 14.0:
					u.command_attack(p)
				elif u.attack_target == null and not u.is_attack_moving():
					u.command_attack_move(p.global_position)
			return true
		&"raid":
			if u.attack_target == null and not u.is_attack_moving():
				var w := _nearest_worker(u.global_position)
				u.command_attack_move(w.global_position if w else _alive_pos(keep, hero_at))
			return true
		&"rally":
			return true
	return false


## The strike ends (both east pylons down, or phase 2): the bot's units go back to the Commander, the scripted ones
## push on to the Fire keep.
func _release_strike_unit(u: Unit) -> void:
	if u.has_meta(&"m4_strike"):
		u.remove_meta(&"m4_strike")
		u.remove_from_group(SCRIPTED_GROUP)
		u.remove_meta(SCRIPTED_GROUP)
		u.remove_meta(META_MODE)
		u.command_move(SHADOW_RALLY)
	else:
		u.set_meta(META_MODE, &"point")
		u.command_attack_move(_alive_pos(keep, PLAYER_START))


func _nearest_worker(at: Vector3) -> Unit:
	var best: Unit = null
	var best_d := INF
	for w in workers_of(Unit.Team.PLAYER):
		var d := _flat(w.global_position, at)
		if d < best_d:
			best_d = d
			best = w
	return best


## Raids (phase 1, every 180 s): 4 Grave Hounds (2 once the Gloom Hall burned) for the nearest Fire worker.
func _send_raid() -> void:
	if is_ending():
		return
	raids_sent += 1
	var n := 2 if objective_state("sec_hall") == "done" else 4
	for u in spawn_wave_at([["grave_hound", n]], SHADOW_START + Vector3(-6.0, 0.0, 6.0)):
		var w := _nearest_worker((u as Unit).global_position)
		order_wave(u as Unit, &"raid", w.global_position if w else _alive_pos(keep, PLAYER_START))


## E8: a pylon broke.
func _on_pylon_destroyed(_pylon: Unit, by_team: int) -> void:
	if is_ending():
		return
	pylons_broken += 1
	fire_once(&"E8")
	set_objective(&"obj_pylons", "active")
	if pylons_broken == 2:
		say_id(&"L10")
	if by_team == Unit.Team.ENEMY:
		shadow_pylons += 1
		if shadow_pylons == 1:
			say_id(&"L24")
			set_mission_flag("m4_malrik_pylons", true)
	if pylons_broken >= 4:
		_e9_walk()


## E9: phase 2. The ward shatters; the Colossus walks to the Fire keep; Wardens, the Shadow push; raids stop.
func _e9_walk() -> void:
	if phase != 1:
		return
	fire_once(&"E9")
	phase = 2
	walk_time = mission_time()
	_seal_flash()
	say_id(&"L11")
	set_objective(&"obj_pylons", "done")
	set_objective(&"obj_colossus", "active")
	keystone.start_walk(WALK_PATH)
	for u in strike_units:
		if is_instance_valid(u) and (u as Unit).is_alive():
			_release_strike_unit(u as Unit)
	var knights := 1 if objective_state("sec_hall") == "done" else 2
	push_units = spawn_wave_at([["shade", 6], ["shadow_knight", knights]], NORTH_EDGE)
	for u in push_units:
		order_wave(u as Unit, &"point", _alive_pos(keep, PLAYER_START))


func _seal_flash() -> void:
	flash_ring(THRONE_POS, FLASH_RADIUS)
	var mi := get_child(get_child_count() - 1) as MeshInstance3D   # the ring flash_ring just added: amber
	if mi and mi.material_override is StandardMaterial3D:
		(mi.material_override as StandardMaterial3D).albedo_color = Color(FLASH_COLOR, 0.7)


func _on_cracked_leg() -> void:
	if is_ending():
		return
	fire_once(&"E10")
	hud.show_message(MSG_STAGGER, 4.0)
	say_id(&"L12")
	after(4.0, func() -> void:   # the spotlight moment (unit-spotlights.md 2.1): the Kilnwarden on the boss
		if is_ending() or not keystone.colossus_alive():
			return
		flash_ring(keystone.colossus.global_position, 5.0)
		hud.show_message(HINT_SPOTLIGHT, 8.0))


# ---------------------------------------------------------------- the darkest hour (E12) and phase 3

func _e12_darkest_hour() -> void:
	if phase != 2 or is_ending():
		return
	phase = -2
	darkest_by = &"boss" if keystone.colossus_hp_pct() <= DARKEST_BOSS_PCT else &"keep"
	say_id(&"L14")
	after(3.0, func() -> void:
		if is_ending():
			return
		_play_card(&"m4_storm", _text_card(&"m4_storm", "The Darkest Hour", CARD_STORM_TEXT, hero_pos(), 105.0),
				_storm_end_state))


## E12 end state: the Colossus kneels (HP <= 40 %, phase 3), Wardens near Vessa gone, Old Vey 3 m from her, her
## mana >= 50 %, the storm layer; L15, L25; obj_key; the Shadow pull-back; the hint.
func _storm_end_state() -> void:
	if phase != -2:
		return
	phase = 3
	storm_time = mission_time()
	keystone.start_kneel(DARKEST_BOSS_PCT)
	var at := hero_pos()
	for w in get_tree().get_nodes_in_group(&"m4_wardens"):
		var u := w as Unit
		if u and u.is_alive() and _flat(u.global_position, at) <= DARKEST_CLEAR_RADIUS:
			u.leave_map()
	var dir := Vector3(1.0, 0.0, -1.0).normalized()
	if keystone.colossus_alive():
		dir = (keystone.colossus.global_position - at)
		dir.y = 0.0
		dir = dir.normalized() if dir.length() > 0.1 else Vector3(1.0, 0.0, -1.0).normalized()
	keystone.spawn_vey(at + dir.rotated(Vector3.UP, 0.6) * VEY_OFFSET)
	if hero_alive() and &"mana" in hero:
		var max_mana := hero.get_stat(&"max_mana")
		hero.set(&"mana", maxf(float(hero.get(&"mana")), max_mana * 0.5))
	_apply_storm_layer()
	say_id(&"L15")
	say_id(&"L25")
	set_objective(&"obj_colossus", "done")
	set_objective(&"obj_key", "active")
	_pull_back()
	hud.show_message(HINT_KEY, 10.0)


## Phase 3: every Shadow unit walks to the rally; the bot defends only.
func _pull_back() -> void:
	_set_bot_knob(&"min_attack_pop", 99)
	_set_bot_knob(&"launch_attacks", false)
	for n in get_tree().get_nodes_in_group("units"):
		var u := n as Unit
		if u == null or not u.is_alive() or int(u.team) != Unit.Team.ENEMY or u.is_worker():
			continue
		u.set_meta(META_MODE, &"rally")
		u.command_move(SHADOW_RALLY + Vector3(randf_range(-4.0, 4.0), 0.0, randf_range(-4.0, 4.0)))


## Sets an AIProfile knob on the Commander's profile in use (its `ai`).
func _set_bot_knob(knob: StringName, value: Variant) -> void:
	for bot in _all_commanders():
		var prof: Variant = bot.get(&"ai")
		if prof == null:
			prof = bot.get(&"profile")
		if prof is Resource:
			(prof as Resource).set(knob, value)


## The bot never ends this mission by conceding: Malrik beaten is allowed, the boss phases go on (mission-04.md
## "Win / lose"). The player's surrender still ends it.
func surrender(team: int, message: String = "") -> void:
	if team == Unit.Team.PLAYER:
		super(team, message)
		return
	for bot in _all_commanders():
		if int(bot.get(&"team")) == team:
			bot.set(&"enabled", false)
	if fire_once(&"bot_beaten"):
		hud.show_message("Malrik's army is broken. The Hollow is not.", 4.0)


func _on_exposed(count: int) -> void:
	if is_ending():
		return
	fire_once(&"E13")
	match count:
		1:
			say_id(&"L16")
		2:
			say_id(&"L17")
			say_id(&"L18")
		3:
			say_id(&"L19")


func _on_vey_down() -> void:
	if is_ending():
		return
	fire_once(&"E14")
	say_id(&"L23")
	hud.show_message(MSG_VEY_DOWN, 4.0)


# ---------------------------------------------------------------- the end

## E15: the Colossus falls. m4_fall (PAUSE 0:06, L21) closes on the heart-stone; then the victory (saved first) and,
## on the first story victory, ep1_ending and ep1_credits (fallback cards until the films exist).
func _on_colossus_died() -> void:
	if is_ending() or phase != 3:
		return
	fire_once(&"E15")
	phase = 4
	for bot in _all_commanders():
		bot.set(&"enabled", false)
	keystone.clear_decals()
	var chest: Vector3 = keystone.colossus.global_position if is_instance_valid(keystone.colossus) else THRONE_POS
	heart_stone = M04Look.packed(&"heart_stone").instantiate() as Node3D
	heart_stone.name = "HeartStone"
	add_child(heart_stone)
	heart_stone.global_position = Vector3(chest.x + 1.5, 0.0, chest.z + 1.5)
	_card_actors = {&"colossus": keystone.colossus, &"heart_stone": heart_stone}
	var card := _card(&"m4_fall", "", "", [[&"obren", DIALOGUE[LINE_IDS.find(&"L21")][1], 3.0]],
			heart_stone.global_position, Vector3(6.0, 7.0, 7.0), Vector3(2.0, 1.6, 2.4), 6.0)
	_play_card(&"m4_fall", card, _fall_end_state, [&"L21"])


func _fall_end_state() -> void:
	set_objective(&"obj_key", "done")
	set_objective(&"obj_vessa", "done")
	set_objective(&"obj_keep", "done")
	if objective_state("sec_hall") == "active" and gloom_hall and is_instance_valid(gloom_hall) and gloom_hall.is_alive():
		set_objective(&"sec_hall", "failed")
	win(0.0)
	if story_films and cinematics_enabled and save_campaign_on_victory:
		_play_card(&"ep1_ending", _text_card(&"ep1_ending", "Episode 1", CARD_ENDING_TEXT, heart_stone.global_position,
				90.0), func() -> void:
			_play_card(&"ep1_credits", _text_card(&"ep1_credits", "Episode 1 complete", CARD_CREDITS_TEXT,
					THRONE_POS, 20.0), Callable()))


func _on_player_hero_fell() -> void:
	fire_once(&"E16")
	say_id(&"L20")
	set_objective(&"obj_vessa", "failed")
	super()


func _e17_keep_lost() -> void:
	if is_ending():
		return
	set_objective(&"obj_keep", "failed")
	hud.show_message("The Fire keep has fallen", 4.0)
	lose(DEFEAT_DELAY)


# ---------------------------------------------------------------- the Ember Hall (mission 2's copy)

func _make_hall_type() -> BuildingType:
	var base := BuildingType.find("fire_barracks")
	if base == null:
		return null
	var t := base.duplicate() as BuildingType
	var trains: Array[UnitType] = []
	for id in HALL_UNITS + TIER2_HALL_UNITS:
		var ut := UnitType.find(String(id))
		if ut:
			trains.append(ut)
	t.trains = trains
	return t


func _on_m4_node_added(node: Node) -> void:
	var b := node as TrainingBuilding
	if b != null and _hall_type != null and b.building_type != null and b.building_type != _hall_type \
			and b.building_type.id == &"fire_barracks" and int(b.team) == Unit.Team.PLAYER:
		b.building_type = _hall_type


# ---------------------------------------------------------------- cutscenes and fallback cards

## Plays `id` from data/cinematics/<id>.tres when it exists (MissionBase.play_cutscene), else `card` (a PAUSE fallback
## card on the cinematic runtime); `end_state` runs once at the end, skipped or not, or at once with cinematics off.
## `lines` (spec ids) are the card's subtitles: said through the dialogue log when no card plays.
func _play_card(id: StringName, card: CinematicScript, end_state: Callable, lines: Array = []) -> void:
	if cinematics_enabled and card != null and CinematicScript.find(id) == null:
		var player := CinematicPlayer.instance(get_tree())
		for tag: StringName in _card_actors:
			if is_instance_valid(_card_actors[tag]):
				player.register_actor(tag, _card_actors[tag])
		if player.play(card, self) == "":
			cards_played.append(id)
			for l: StringName in lines:   # shown as subtitles: logged, never repeated in the dialogue box
				_said[l] = true
				said_ids.append(l)
				var row: Array = DIALOGUE[LINE_IDS.find(l)]
				dialogue_log.append("%s: %s" % [row[0], row[1]])
			player.finished.connect(func(_fid: StringName, _skipped: bool) -> void:
				if end_state.is_valid():
					end_state.call(), CONNECT_ONE_SHOT)
			return
	# A film (data/cinematics/<id>.tres) or no film: the lines are said in the end state, never before the film (they
	# would queue up behind it); a line the film showed is not repeated as a card (MissionBase._cine_said).
	play_cutscene(id, func() -> void:
		for l: StringName in lines:
			say_id(l)
		if end_state.is_valid():
			end_state.call())


## A one-shot card: title + lines as subtitles over a slow push-in on `focus` (world frozen: PAUSE).
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
	shot.look_from = focus + Vector3(0.0, 1.0, 0.0)
	shot.look_to = focus + Vector3(0.0, 1.0, 0.0)
	shot.fov_from = 42.0
	shot.fov_to = 38.0
	shot.transition_in = CinematicShot.Transition.FADE_BLACK
	shot.transition_time = 0.6
	if title != "":
		shot.add_action(0.0, &"title", &"", Vector3.ZERO, {"text": title, "sub": sub, "time": 2.5})
	var t := 0.6 if title == "" else 3.0
	for l: Array in lines:
		shot.add_line(t, StringName(l[0]), String(l[1]), float(l[2]))
		t += float(l[2]) + 0.25
	s.shots = [shot]
	return s


## A film's fallback card (ep1 7.4): the film's text as narrator subtitles in sentence-sized chunks.
func _text_card(id: StringName, title: String, text: String, focus: Vector3, length: float) -> CinematicScript:
	var lines: Array = []
	var sentences := text.split(". ")
	var per := 5.0
	for i in sentences.size():
		var sentence := sentences[i] + ("." if i < sentences.size() - 1 else "")
		per = clampf(float(sentence.length()) / 16.0, 3.5, 7.0)
		lines.append([&"narrator", sentence, per])
	var total := 3.5
	for l: Array in lines:
		total += float(l[2]) + 0.25
	return _card(id, title, "", lines, focus, Vector3(-26.0, 24.0, 30.0), Vector3(-14.0, 12.0, 16.0),
			minf(length, total + 1.0))
