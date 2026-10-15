class_name Mission00
extends MissionBase
## Campaign mission 0, "The Night of Knives" (docs/design/mission-00.md = source of truth; tasks 19.C7a / 19.C7b).
## Mission 1's map (seed 1101, every tree where it stands at dawn) at night, played only in the player's corner
## (x -58..-8, z 8..58, two invisible bound walls baked into the navmesh). Vessa (level 2, 45 % HP, cap 3) and her
## escort (4 Flame Guards, 4 Ember Archers) with Old Vey must live until dawn (8:00 of mission time) inside the
## Emberfall watch while Malrik's assassins (waves A1-A5, the Fall, the Dark hold) and Mother Hush come for her.
## Three watch braziers (MissionBrazier) give light (a SightMarker r 23.3 = r 14 at night), warmth (2 HP / s within
## 6 m) and a 10 s warning for the side they face; dawn waits for all three. Two story cutscenes (`m0_fall` PAUSE,
## `m0_dawn` HOLD) play from data/cinematics/<id>.tres when it exists, else a code-built fallback card (PAUSE) on the
## cinematic runtime; skipped or not, the same end state runs (MissionBase.play_cutscene's 19.C9 rule).
## Story units and their kits: M00Cast (scripts/campaign/m00_cast.gd). Effects: art/vfx/m00/. Night / dawn lighting:
## art/environment/lighting/emberfall_night.gd. Voice lines: data/voice/lines/m00.json (L1-L14, C1-C7).

signal brazier_lit(brazier: MissionBrazier, lit_count: int)
signal wave_spawned(id: StringName, units: Array)

const MISSION_ID := &"m00"
const MISSION_TITLE := "The Night of Knives"
const MAP_SEED := 1101
const CAMERA_BOUNDS := Rect2(-58.0, 8.0, 50.0, 50.0)
## Inside the bound walls (the navmesh edge sits about 1 m inside them).
const PLAY_MIN := Vector2(-58.0, 8.5)
const PLAY_MAX := Vector2(-8.5, 58.0)
const WALL_EAST_X := -7.0
const WALL_NORTH_Z := 7.0
const WALL_THICKNESS := 1.0
const WALL_HEIGHT := 4.0

const WATCH_KEEP_POS := Vector3(-43.0, 0.0, 43.0)
const VESSA_START := Vector3(-38.0, 0.0, 40.0)
const VEY_START := Vector3(-37.0, 0.0, 41.0)
const SEAM_CENTER := Vector3(-36.0, 0.0, 39.0)
const SEAM_LENGTH := 6.0
const ESCORT_GUARDS: Array[Vector3] = [Vector3(-34.0, 0.0, 39.0), Vector3(-34.0, 0.0, 41.0), Vector3(-33.0, 0.0, 40.0),
		Vector3(-33.0, 0.0, 42.0)]
const ESCORT_ARCHERS: Array[Vector3] = [Vector3(-39.0, 0.0, 36.0), Vector3(-41.0, 0.0, 36.0), Vector3(-39.0, 0.0, 34.0),
		Vector3(-41.0, 0.0, 34.0)]
const ESCORT_SIZE := 8
## [id, name, position, side it watches]
const WATCH_BRAZIERS := [
	[&"bell", "Bell", Vector3(-43.0, 0.0, 27.0), &"n"],
	[&"gate", "Gate", Vector3(-32.0, 0.0, 32.0), &"ne"],
	[&"crag", "Crag", Vector3(-27.0, 0.0, 43.0), &"e"],
]
const HEARTHWARD_POS := Vector3(-22.0, 0.0, 22.0)
const SPAWN_POINTS := {&"ne": Vector3(-12.0, 0.0, 12.0), &"e": Vector3(-9.0, 0.0, 28.0), &"n": Vector3(-44.0, 0.0, 10.0)}
const SPAWN_N_CLEARING := 4.0          ## The one M0-only clearing (a filter after generation: no other tree moves).
const SPAWN_TOLERANCE := 1.5           ## A resolved spawn point must be this close to its table value (19.C7a test).
const EMBERGUARD_ENTRY := Vector3(-56.0, 0.0, 56.0)
const SIDE_ORDER: Array[StringName] = [&"n", &"ne", &"e"]   ## The Dark hold's darkest side first.
const SIDE_NAMES := {&"n": "north", &"ne": "north-east", &"e": "east"}

const LIGHT_MARKER_RADIUS := 23.3      ## x 0.6 at night = r 14.
const NIGHT_SIGHT := 0.6
const WARMTH_RADIUS := 6.0
const WARMTH_TICK := 0.5
const WARMTH_HPS: Array[float] = [3.0, 2.0, 1.5]
const WARNING_LEAD := 10.0
const WARNING_SECONDS := 3.0
const DAWN_TIME := 480.0
const DARK_HOLD_EVERY := 30.0
const KNIFE_TICK := 1.0
const KNIFE_RANGE := 10.0
const HOUND_RANGE := 14.0
const L10_TIME := 360.0
const FALL_TIME := 400.0
const GRIEF_SECONDS := 80.0
const GRIEF_MOD := &"story:grief"
const GRIEF_STATS := {"spell_power": 50.0, "mana_regen": 2.0}
const START_HP_PCT: Array[float] = [0.6, 0.45, 0.35]
const COUNT_MULT: Array[float] = [0.6, 1.0, 1.4]
const LEVEL_CAP := 3
const VICTORY_DELAY := 2.0
const DEFEAT_DELAY := 3.0

## Waves: [id, mission time, [[side, [[type, normal count], ...]], ...]] (A3 also brings Mother Hush at SP_N).
const WAVES := [
	[&"A1", 15.0, [[&"ne", [["shade", 4]]]]],
	[&"A2", 90.0, [[&"e", [["grave_hound", 3]]], [&"n", [["shade", 2]]]]],
	[&"A3", 180.0, [[&"n", [["shade", 2]]], [&"e", [["shade", 2]]]]],
	[&"A4", 300.0, [[&"ne", [["shade", 3]]], [&"n", [["shade", 3]]], [&"e", [["nightbolt", 2], ["grave_hound", 2]]]]],
	[&"A5", 420.0, [[&"ne", [["shade", 5], ["nightbolt", 2]]]]],
]
const DARK_HOLD_ROWS := [["shade", 3]]
const FALL_ROWS := [["shade", 3]]
## m0_fall marks (at == 0) and end state.
const FALL_VESSA := Vector3(-36.0, 0.0, 39.0)
const FALL_VEY := Vector3(-34.0, 0.0, 40.0)
const FALL_MARKS: Array[Vector3] = [Vector3(-32.0, 0.0, 37.0), Vector3(-33.0, 0.0, 35.0), Vector3(-31.0, 0.0, 39.0),
		Vector3(-31.5, 0.0, 36.0)]
const FALL_VESSA_END := Vector3(-37.5, 0.0, 40.5)
## m0_dawn end state: Captain Ashby and 4 Blaze Riders by the courtyard (its north-east side: the tall keep south-west
## of the courtyard would hide them from the game camera).
const DAWN_ASHBY := Vector3(-35.0, 0.0, 37.0)
const DAWN_RIDERS: Array[Vector3] = [Vector3(-33.5, 0.0, 35.5), Vector3(-36.5, 0.0, 35.0), Vector3(-32.0, 0.0, 37.5),
		Vector3(-35.5, 0.0, 33.0)]
const DAWN_MEET := Vector3(-33.0, 0.0, 38.6)    ## Vessa beside Ashby in the card's shot 3 and the end state.
const DAWN_ARRIVAL := Vector3(-5.0, 0.0, -1.0)  ## The card opens with the riders this far west of their marks.
const DAWN_FADE := 6.0

const SPEAKER_COLORS := {
	&"vessa": Color(1.0, 0.45, 0.1),
	&"vey": Color(0.95, 0.95, 0.55),
	&"torren": Color(0.95, 0.95, 0.55),
	&"hush": Color(0.60, 0.50, 0.75),
	&"ashby": Color(0.95, 0.60, 0.35),
	&"narrator": Color(0.9, 0.85, 0.7),
	&"malrik": Color(0.7, 0.3, 1.0),
}
const SPEAKER_NAMES := {&"vessa": "Vessa", &"vey": "Vey", &"torren": "Vey", &"hush": "Mother Hush",
		&"ashby": "Captain Ashby", &"narrator": "Narrator", &"malrik": "Malrik"}
## L1-L14 (index 0 = L1); data/voice/lines/m00.json has the same lines (+ the cinematic C1-C7).
const DIALOGUE := [
	[&"vey", "Stay behind my sword, girl. Knives hate a long reach."],
	[&"vessa", "I've been stabbed ONE time and I already hate it."],
	[&"vey", "Good. Light pushes back the dark. Always has."],
	[&"vessa", "Dogs! Why is it always dogs?"],
	[&"hush", "Hold still, little queen. It's kinder."],
	[&"vey", "Over my dead body, knife-woman."],
	[&"hush", "The old man bites. How charming."],
	[&"hush", "Another night, little queen. There is always another night."],
	[&"vessa", "How many knives does one Bishop OWN?"],
	[&"vey", "Two more hours, girl. Dawn always comes. It's the one thing it's good at."],
	[&"vessa", "You want me? Come and get me. ALL of you."],
	[&"vessa", "Vey... I'm sorry..."],
	[&"vessa", "You're going to explain the lightning."],
	[&"vey", "Later. Duck."],
]
## Cinematic lines C1-C7: [cutscene, speaker, text, seconds] (subtitles of the two cutscenes / fallback cards).
const CINE_LINES := [
	[&"m0_fall", &"vey", "Vessa, MOVE!", 2.5],
	[&"m0_fall", &"vessa", "VEY!", 2.0],
	[&"m0_fall", &"vessa", "...Malrik.", 2.5],
	[&"m0_dawn", &"narrator", "Dawn came to Emberfall, and so did the Emberguard.", 4.0],
	[&"m0_dawn", &"ashby", "My queen! You're hurt-", 2.5],
	[&"m0_dawn", &"vessa", "I'm not the one who's hurt, Captain.", 3.0],
	[&"m0_dawn", &"vessa", "Get the army up. We take the crown today.", 3.5],
]
const EP1_INTRO_ID := &"ep1_intro"
const EP1_INTRO_TEXT := "The Master vanished and left four apprentices. Years later, Vessa of Fire answered her old teacher's letter and rode to Emberfall. That night Malrik of Shadow sent assassins to kill her. Old Vey's sword, and a crack of lightning no kingdom can explain, saved her life. Now they must survive until dawn."
const EP1_INTRO_SECONDS := 10.0
const BRIEFING_PARAGRAPHS: Array[String] = [
	"Twelve years after the Master vanished, Old Vey, his old sword, wrote to the apprentice he once taught to strike a spark: the crown sealed in the ruins of Emberfall is waking. Vessa rode out that day with four guards.",
	"Malrik of Shadow read the letter too. That night his knives came over the walls of the Emberfall watch: Mother Hush, the knife that never misses, and every assassin he owns. The first blade only grazed Vessa. Old Vey's sword, and a crack of lightning no kingdom can explain, turned the second.",
	"Vessa is wounded and the watch is small. Light the watch-fires so the Emberguard can find you, keep behind Vey's sword, and live until dawn.",
]
const HINT_START := "Keep Vessa behind Old Vey's sword. Light the watch braziers to see the knives coming."
const HINT_FIRST_LIT := "A lit brazier shows its side and warms whoever stands near it."
const HINT_HUSH := "A violet ring means Hush is coming: Ember Step (Q) out of it."
const HINT_SPOTLIGHT := "Stand the Guards between Vessa and the gate: the hounds hit the shields, not her."
const HINT_LEVEL3 := "Level 3: Ctrl+F ranks up Fireball, Ctrl+Q ranks up Ember Step."
const MSG_FIRES := "The watch-fires burn. The Emberguard will see them at dawn."
const MSG_WATCH_FALLEN := "The watch has fallen."
const MSG_WARNING := "Knives from the %s!"
const TEXT_DARK_HOLD := "Light the last watch-fires: the Emberguard is looking for your signal"

## Read only.
var braziers: Array[MissionBrazier] = []    ## WATCH_BRAZIERS order.
var hearthward: MissionBrazier              ## The cold bowl (never lit).
var lit_count := 0
var cast: M00Cast                           ## Old Vey and Mother Hush.
var vey: Unit
var escort: Array[Unit] = []
var seam: Node3D                            ## M00Seam (null without the art script).
var waves_fired: Array[StringName] = []     ## &"A1".. &"A5", &"fall", &"dark_1"..
var dark_hold := false                      ## True while 8:00 has passed with fewer than 3 fires.
var dark_waves := 0
var dawn_reached := false                   ## The 8:00 countdown ran out.
var fall_done := false                      ## m0_fall's end state ran.
var dawn_done := false                      ## m0_dawn's end state ran.
var lighting_mood: StringName = &"night"    ## &"night" / &"dawn".
var grief_left := 0.0                       ## Seconds of Grief's Fire left.
var warnings: Array[String] = []            ## "A2:e" for each side warning shown.
var fall_units: Array = []
var emberguard: Array = []                  ## Ashby + riders (m0_dawn).

var _warm_left := WARMTH_TICK
var _knife_left := KNIFE_TICK
var _dark_next := INF
var _intro_card := false
var _light_markers: Array[Node3D] = []
var _card_hidden: Array = []               ## Units hidden while a card plays (_hide_for_card).
var _card_actors := {}                      ## tag -> Node3D registered on the cinematic player for the next card.


# ---------------------------------------------------------------- setup

func _init() -> void:
	super()
	dialogue_lines = DIALOGUE
	speaker_colors = SPEAKER_COLORS.duplicate()
	speaker_names = SPEAKER_NAMES.duplicate()
	briefing_paragraphs = BRIEFING_PARAGRAPHS.duplicate()
	define_objectives([[&"obj_dawn", "primary"], [&"obj_braziers", "primary"], [&"obj_vessa", "primary"],
			[&"sec_hush", "secondary"], [&"sec_guards", "secondary"]])


func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	c.mission_id = MISSION_ID
	c.title = MISSION_TITLE
	c.count_mult = COUNT_MULT.duplicate()
	c.defeat_on_keep_lost = false   # E12 says its own line and waits 3 s
	c.instant_loss_on_wizard_death = true
	c.defeat_delay = DEFEAT_DELAY
	c.start_level = 2
	c.start_spells = [&"ember_step"]
	c.start_spell_points = 0
	c.level_cap = LEVEL_CAP
	c.economy_enabled = false
	c.resources_hidden = true
	c.essence_trickle = false
	c.kill_essence = false
	c.victory_banner = "VICTORY\nThe night is over"
	c.defeat_banner = "DEFEAT"
	c.rewards = {"flags": {"m0_hush_driven": "sec_hush", "m0_escort_saved": "sec_guards"}, "next": &"m01",
			"save_items": false}
	c.spotlight = {"id": &"flame_guard", "trigger": &"start",
			"card": "Flame Guard. Shields first, spark second: a Guard wall keeps the knives off Vessa."}
	return c


func _ready() -> void:
	# The ep1_intro fallback card replaces the briefing on the very first start of the campaign (V1 is the briefing;
	# retries and the Missions list after it show the briefing). Tests (no save, no cinematics) never see it.
	_intro_card = show_briefing and cinematics_enabled and save_campaign_on_victory \
			and not CampaignState.open(campaign_save_path).is_seen(EP1_INTRO_ID)
	cast = M00Cast.new()
	cast.setup(self, mission_difficulty)
	add_child(cast)
	cast.vey_first_spark.connect(_on_vey_first_spark)
	cast.hush_smoked.connect(_on_hush_smoked)
	cast.hush_fled.connect(_on_hush_fled)
	register_actor("cast", cast)
	super()
	camera_rig.bounds = CAMERA_BOUNDS
	camera_rig.focus_on(VESSA_START)
	if fog and &"sight_scale" in fog:
		var scale: Array[float] = [NIGHT_SIGHT, 1.0]
		fog.set(&"sight_scale", scale)
	EmberfallNight.apply_to(self, EmberfallNight.night())


func _title_line() -> String:
	return "Prologue: %s" % MISSION_TITLE


## No briefing screen on the campaign's first start (the ep1_intro card is it); else the 3 paragraphs + objectives.
func briefing() -> Dictionary:
	if _intro_card:
		return {}
	return {
		"title": _title_line(),
		"paragraphs": BRIEFING_PARAGRAPHS.duplicate(),
		"objectives": [objective_text(&"obj_dawn"), objective_text(&"obj_braziers", false)],
		"rule": objective_text(&"obj_vessa"),
	}


## No keep healing in this mission (Vessa heals at the braziers and on level-up).
func _home_healing(_delta: float) -> void:
	pass


func _ground_spots() -> Array[Vector4]:
	return [Vector4(-39.0, 41.0, 12.0, 0.0), Vector4(SEAM_CENTER.x, SEAM_CENTER.z, 4.5, 1.0),
			Vector4(HEARTHWARD_POS.x, HEARTHWARD_POS.z, 4.0, 0.0)]


func _build_map() -> void:
	# Mission 1's generator, draws and clearings, unchanged (every tree stands where it will at dawn), then the one
	# M0 clearing (SP_N) as a filter after each draw; mission 1's buildings, nodes, caches and pillars are not built.
	var rng := RandomNumberGenerator.new()
	rng.seed = MAP_SEED
	var clearings := [[PLAYER_START, 18.0], [SHADOW_START, 18.0], [ARTIFACT_POS, Mission01.CROWN_CLEARING],
			[Mission01.PELL_POS, Mission01.PELL_CLEARING], [Mission01.EMBER_HALL_POS, 4.0],
			[Mission01.GLOOM_HALL_POS, 4.0], [Mission01.SHADOW_SPIRE_POS, 3.0], [Mission01.HOVEL_POS, 4.0],
			[Mission01.WESTWATCH_SPIRE_POS, 3.0], [Mission01.WEST_HALL_SPOT, 4.0], [Mission01.SOUTH_HALL_SPOT, 4.0],
			[Mission01.M1_NODES[&"m1_west"][0], 7.0], [Mission01.M1_NODES[&"m1_south"][0], 7.0]]
	for row in Mission01.BRAZIER_TABLE:
		clearings.append([row[2], row[3]])
	for p: Vector3 in Mission01.M1_CACHE_SPOTS:
		clearings.append([p, CACHE_CLEARING])
	var m0_only := [[SPAWN_POINTS[&"n"], SPAWN_N_CLEARING]]
	for cluster in 10:
		var center := Vector3(rng.randf_range(-52, 52), 0.0, rng.randf_range(-52, 52))
		for i in rng.randi_range(5, 9):
			var p := center + Vector3(rng.randf_range(-6, 6), 0.0, rng.randf_range(-6, 6))
			var s := rng.randf_range(0.8, 1.3)
			if absf(p.x) > 57.0 or absf(p.z) > 57.0 or _in_clearing(p, clearings) or _in_path_lane(p):
				continue
			if _in_clearing(p, m0_only):
				continue
			_add_tree(p, s)
	for i in 22:
		var p := Vector3(rng.randf_range(-54, 54), 0.0, rng.randf_range(-54, 54))
		var s := rng.randf_range(0.8, 2.2)
		var rot := rng.randf() * TAU
		if _in_clearing(p, clearings) or _in_path_lane(p) or _in_clearing(p, m0_only):
			continue
		_add_rock(p, s, rot)

	_add_bound_walls()

	# The watch-keep (2 000 HP, shoots, trains nothing): a navmesh obstacle before the bake.
	var keep_type := BuildingType.find("fire_watch_keep")
	var wk := WatchKeep.new()
	wk.building_type = keep_type
	wk.name = "EmberfallWatch"
	wk.team = Unit.Team.PLAYER
	wk.team_color = FIRE_COLOR
	wk.front_toward = SEAM_CENTER
	wk.position = build_grid.snap(WATCH_KEEP_POS, keep_type.footprint) if keep_type else WATCH_KEEP_POS
	nav_region.add_child(wk, true)
	keep = wk

	for row in WATCH_BRAZIERS:
		var b := MissionBrazier.new()
		b.brazier_id = row[0]
		b.display_name = row[1]
		b.name = "WatchBrazier%s" % String(row[1])
		b.flame_target = SPAWN_POINTS[row[3]]
		b.set_meta(&"side", row[3])
		nav_region.add_child(b)
		b.position = row[2]
		b.lit_up.connect(_on_brazier_lit)
		braziers.append(b)
		register_actor("brazier_%s" % String(row[0]), b)
	hearthward = MissionBrazier.new()   # mission 1's Brazier 1, cold: nobody can light it tonight (lighter stays null)
	hearthward.brazier_id = &"hearthward"
	hearthward.display_name = "Hearthward"
	hearthward.name = "BrazierHearthward"
	nav_region.add_child(hearthward)
	hearthward.position = HEARTHWARD_POS
	hearthward.remove_from_group("braziers")

	if ResourceLoader.exists("res://art/vfx/m00/m00_seam.gd"):
		seam = M00Seam.new()
		seam.name = "CourtyardSeam"
		add_child(seam)
		seam.global_position = SEAM_CENTER + Vector3(0.0, 0.01, 0.0)
		seam.rotation.y = PI * 0.25   # local +X runs south-west -> north-east


## The two invisible bound walls (layer 1, group "navigation_geometry", no mesh): east x = -7, north z = 7.
func _add_bound_walls() -> void:
	var east := BoxShape3D.new()
	east.size = Vector3(WALL_THICKNESS, WALL_HEIGHT, 54.0)
	var e := _static_obstacle(Vector3(WALL_EAST_X, 0.0, 33.0), east, WALL_HEIGHT * 0.5)
	e.name = "BoundWallEast"
	e.add_to_group(&"navigation_geometry")
	var north := BoxShape3D.new()
	north.size = Vector3(54.0, WALL_HEIGHT, WALL_THICKNESS)
	var n := _static_obstacle(Vector3(-33.0, 0.0, WALL_NORTH_Z), north, WALL_HEIGHT * 0.5)
	n.name = "BoundWallNorth"
	n.add_to_group(&"navigation_geometry")


func _on_navigation_ready() -> void:
	hero = Wizard.new()
	_spawn(hero, Unit.Team.PLAYER, VESSA_START)
	_claim_wizard(hero, Unit.Team.PLAYER)
	for p in ESCORT_GUARDS:
		escort.append(_spawn(make_unit("flame_guard"), Unit.Team.PLAYER, p))
	for p in ESCORT_ARCHERS:
		escort.append(_spawn(make_unit("ember_archer"), Unit.Team.PLAYER, p))
	for u in escort:
		u.add_to_group(&"m0_escort")
		u.died.connect(_on_escort_died)
		u.face_direction(Vector3(1.0, 0.0, -1.0))
	vey = _spawn(make_unit("torren_vey"), Unit.Team.PLAYER, VEY_START)
	cast.bind_vey(vey)
	for b in braziers:
		b.lighter = hero
	hero.level_changed.connect(_on_vessa_level)
	if keep:
		keep.destroyed.connect(_on_watch_fallen)
	# Waves and their side warnings (10 s before, watched sides only), the fixed beats of the night.
	for w: Array in WAVES:
		var id: StringName = w[0]
		var at: float = w[1]
		after(maxf(0.0, at - WARNING_LEAD), _warn.bind(id, _sides_of(w)))
		after(at, _fire_wave.bind(id))
	after(L10_TIME, func() -> void:
		if fire_once(&"E8"):
			say_line(10))
	after(FALL_TIME, _fall)
	begin_mission([&"obj_dawn", &"obj_braziers", &"obj_vessa", &"sec_guards"])
	# Start state after begin_mission (raise_wizard heals by the level gain): the wound.
	hero.hp = roundf(hero.max_hp * float(START_HP_PCT[clampi(mission_difficulty, 0, 2)]))
	hero.mana = hero.max_mana
	if hud and hud.inventory_bar:
		hud.inventory_bar.visible = false   # items_locked: no slots, no shop, nothing from the save
	selection.select_units([hero])


## E1 (after the ep1_intro card on the campaign's first start).
func _intro() -> void:
	if _intro_card:
		_intro_card = false
		_play_card(EP1_INTRO_ID, _ep1_intro_card(), func() -> void:
			if save_campaign_on_victory:
				CampaignState.open(campaign_save_path).mark_seen(EP1_INTRO_ID)
			_e1())
		return
	_e1()


func _e1() -> void:
	if fire_once(&"E1"):
		camera_rig.focus_on(hero.global_position)
		say_line(1)
		say_line(2)
		hud.show_message(HINT_START, 10.0)


# ---------------------------------------------------------------- public helpers (M00Cast, UI, tests)

## Clamps a point into the play area (inside the bound walls).
func clamp_to_play_area(p: Vector3) -> Vector3:
	return Vector3(clampf(p.x, PLAY_MIN.x, PLAY_MAX.x), p.y, clampf(p.z, PLAY_MIN.y, PLAY_MAX.y))


## The navmesh point of a spawn side (&"n", &"ne", &"e"), the table value when the map is not synced yet.
func spawn_point(side: StringName) -> Vector3:
	var p: Vector3 = SPAWN_POINTS[side]
	var q := resolve_on_navmesh(p)
	return q if _flat(q, p) <= 3.0 else p


func resolve_on_navmesh(p: Vector3) -> Vector3:
	if nav_region == null or not nav_region.is_inside_tree():
		return p
	var map := nav_region.get_navigation_map()
	if not map.is_valid() or NavigationServer3D.map_get_iteration_id(map) == 0:
		return p
	return NavigationServer3D.map_get_closest_point(map, p)


## The closest spawn point to `at` (Hush flees to it, assassins leave by it).
func nearest_spawn(at: Vector3) -> Vector3:
	var best := spawn_point(&"ne")
	for side: StringName in SIDE_ORDER:
		var p := spawn_point(side)
		if _flat(p, at) < _flat(best, at):
			best = p
	return best


## While Vessa stands lighting a brazier: the spawn point of the side it faces (Vey guards that way), else null.
func brazier_in_progress() -> Variant:
	for b in braziers:
		if not b.lit and b.progress > 0.0:
			return spawn_point(StringName(b.get_meta(&"side")))
	return null


func brazier(id: StringName) -> MissionBrazier:
	for b in braziers:
		if b.brazier_id == id:
			return b
	return null


## True when the brazier that faces `side` burns (its side is "watched").
func side_watched(side: StringName) -> bool:
	for b in braziers:
		if b.lit and StringName(b.get_meta(&"side")) == side:
			return true
	return false


func assassins() -> Array[Unit]:
	var out: Array[Unit] = []
	for n in get_tree().get_nodes_in_group(&"assassins"):
		var u := n as Unit
		if u and u.is_alive():
			out.append(u)
	return out


func escort_alive() -> int:
	var n := 0
	for u in escort:
		if is_instance_valid(u) and u.is_alive():
			n += 1
	return n


func hush() -> Unit:
	return cast.hush if cast else null


func dawn_time_left() -> float:
	return maxf(0.0, DAWN_TIME - mission_time())


static func speaker_color(speaker: StringName) -> Color:
	return SPEAKER_COLORS.get(speaker, Color.WHITE)


static func speaker_name(speaker: StringName) -> String:
	return SPEAKER_NAMES.get(speaker, String(speaker).capitalize())


# ---------------------------------------------------------------- objectives

func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_dawn":
			return TEXT_DARK_HOLD if dark_hold else "Survive until dawn (8:00)"
		&"obj_braziers":
			return "Light the watch braziers (%d / 3)" % lit_count if with_counter else "Light the watch braziers"
		&"obj_vessa":
			return "Vessa must survive"
		&"sec_hush":
			return "Drive off Mother Hush"
		&"sec_guards":
			return "Keep your escort alive (%d)" % escort_alive()
	return String(id)


func _objective_extra(id: StringName, o: Dictionary) -> Dictionary:
	match id:
		&"obj_braziers":
			return {"progress": lit_count, "goal": 3, "counter": "%d / 3" % lit_count}
		&"obj_dawn":
			var t := dawn_time_left() if o["state"] == "active" and not dark_hold and match_started else -1.0
			return {"time_left": t, "countdown": t, "dark_hold": dark_hold}
	return {}


# ---------------------------------------------------------------- every frame

func _physics_process(delta: float) -> void:
	super(delta)   # MissionBase: the Skirmish tick, then the `after` timers and the E-list
	if not match_started or game_over or world_is_held:
		return
	tick_scripted(delta)   # waves re-aim every 3 s (_refresh_wave_unit)
	if grief_left > 0.0:
		grief_left -= delta
		if grief_left <= 0.0 and hero and is_instance_valid(hero):
			hero.remove_modifier(GRIEF_MOD)
	_warm_left -= delta
	if _warm_left <= 0.0:
		_warm_left += WARMTH_TICK
		_tick_warmth()
	_knife_left -= delta
	if _knife_left <= 0.0:
		_knife_left += KNIFE_TICK
		_knife_focus()
	if _ending:
		return
	if not dawn_reached and mission_time() >= DAWN_TIME:
		_dawn_clock_ran_out()
	if dark_hold and mission_time() >= _dark_next:
		_dark_next = mission_time() + DARK_HOLD_EVERY
		_fire_dark_wave()


## Brazier warmth: every own unit (not buildings) within 6 m of a lit watch brazier, WARMTH_HPS per second.
func _tick_warmth() -> void:
	var hps: float = WARMTH_HPS[clampi(mission_difficulty, 0, 2)]
	var lit_spots: Array[Vector3] = []
	for b in braziers:
		if b.lit:
			lit_spots.append(b.global_position)
	if lit_spots.is_empty():
		return
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or not u.is_alive() or int(u.team) != Unit.Team.PLAYER or u.hp >= u.max_hp:
			continue
		for p in lit_spots:
			if _flat(u.global_position, p) <= WARMTH_RADIUS:
				u.heal(hps * WARMTH_TICK)
				break


## Knife focus (1 s): an assassin that is not taunted and sees Vessa within 10 m (Grave Hounds 14 m) goes for her.
func _knife_focus() -> void:
	if not hero_alive() or dawn_done:
		return
	for u in assassins():
		if u.has_status(&"taunted") or u.has_meta(&"m0_leaving"):
			continue
		if u == cast.hush and cast.hush_busy():
			continue
		var reach := HOUND_RANGE if u.unit_type and u.unit_type.id == &"grave_hound" else KNIFE_RANGE
		if _flat(u.global_position, hero.global_position) <= reach and u.attack_target != hero:
			u.command_attack(hero)


## Wave mode &"knife": attack-move to Vessa, refreshed every 3 s unless already on a living unit.
func _refresh_wave_unit(u: Unit, mode: StringName, vessa: Vector3) -> bool:
	if mode == &"leave":
		return true
	if mode != &"knife":
		return false
	if u == cast.hush and cast.hush_busy():
		return true
	if u.has_status(&"taunted"):
		return true
	var t: Unit = u.attack_target as Unit if is_instance_valid(u.attack_target) else null
	if t != null and is_instance_valid(t) and t.is_alive():
		return true
	u.command_attack_move(clamp_to_play_area(vessa))
	return true


# ---------------------------------------------------------------- braziers

func _on_brazier_lit(b: MissionBrazier) -> void:
	if is_ending():   # a pending defeat (keep fell, Vessa fell) stays a defeat: no dawn from a late 3rd brazier
		return
	lit_count += 1
	brazier_lit.emit(b, lit_count)
	_light_markers.append(SightMarker.spawn(Unit.Team.PLAYER, b.global_position, LIGHT_MARKER_RADIUS, 0.0, self))
	M00Vfx.warmth_ring(self, b.global_position, WARMTH_RADIUS)
	set_objective(&"obj_braziers", "active" if lit_count < 3 else "done")
	if lit_count == 1 and fire_once(&"E2"):
		say_line(3)
		hud.show_message(HINT_FIRST_LIT, 6.0)
	if lit_count >= 3 and fire_once(&"E2b"):
		hud.show_message(MSG_FIRES, 5.0)
		if dawn_reached:
			_dawn()


# ---------------------------------------------------------------- waves

func _sides_of(w: Array) -> Array[StringName]:
	var out: Array[StringName] = []
	for part: Array in w[2]:
		if not out.has(part[0]):
			out.append(StringName(part[0]))
	if w[0] == &"A3" and not out.has(&"n"):
		out.append(&"n")
	return out


## 10 s before a wave: a red minimap ping and a message for each side whose brazier burns.
func _warn(id: StringName, sides: Array[StringName]) -> void:
	if game_over or _ending or dawn_reached:
		return
	for side in sides:
		if not side_watched(side):
			continue
		warnings.append("%s:%s" % [id, side])
		if hud and hud.minimap:
			hud.minimap.ping(spawn_point(side))
		hud.show_message(MSG_WARNING % SIDE_NAMES[side], WARNING_SECONDS)


func _fire_wave(id: StringName) -> void:
	if game_over or _ending or dawn_reached or waves_fired.has(id):
		return
	var w: Array = []
	for row: Array in WAVES:
		if row[0] == id:
			w = row
	if w.is_empty():
		return
	waves_fired.append(id)
	var units: Array = []
	for part: Array in w[2]:
		units.append_array(_spawn_assassins(part[1], spawn_point(part[0])))
	if id == &"A3":
		var h := _spawn(make_unit("mother_hush"), Unit.Team.ENEMY, spawn_point(&"n") + Vector3(1.5, 0.0, 1.5))
		mark_scripted(h)
		cast.bind_hush(h)
		_make_assassin(h)
		units.append(h)
	wave_spawned.emit(id, units)
	match id:
		&"A2":
			if fire_once(&"E3"):
				say_line(4)
				hud.show_message(HINT_SPOTLIGHT, 8.0)   # the spotlight moment (unit-spotlights.md 2.1)
				flash_ring(spawn_point(&"e"), 4.0)
		&"A3":
			if fire_once(&"E4"):
				say_line(5)
				say_line(6)
				set_objective(&"sec_hush", "active")
				hud.show_message(HINT_HUSH, 8.0)
		&"A4":
			if fire_once(&"E7"):
				say_line(9)


func _spawn_assassins(rows: Array, at: Vector3) -> Array:
	var out := spawn_wave_at(rows, at)
	for u: Unit in out:
		_make_assassin(u)
	return out


func _make_assassin(u: Unit) -> void:
	u.add_to_group(&"assassins")
	order_wave(u, &"knife", clamp_to_play_area(hero_pos()))


## Dark hold: 3 Shades at the spawn of the darkest unlit side (N, then NE, then E), every 30 s after 8:00.
func _fire_dark_wave() -> void:
	var side: StringName = &""
	for s: StringName in SIDE_ORDER:
		if not side_watched(s):
			side = s
			break
	if side == &"":
		return
	dark_waves += 1
	var id := StringName("dark_%d" % dark_waves)
	waves_fired.append(id)
	wave_spawned.emit(id, _spawn_assassins(DARK_HOLD_ROWS, spawn_point(side)))


# ---------------------------------------------------------------- m0_fall (E9)

func _fall() -> void:
	if game_over or _ending or not hero_alive() or not fire_once(&"E9"):
		return
	waves_fired.append(&"fall")
	# Teleports at == 0 (the cutscene opens on them; a skip leaves the end state below).
	hero.command_stop()
	hero.global_position = FALL_VESSA
	if cast.vey_alive():
		vey.command_stop()
		vey.global_position = FALL_VEY
	fall_units.clear()
	var n := scaled(int(FALL_ROWS[0][1]), "shade")
	for i in n:
		var u := _spawn(make_unit("shade"), Unit.Team.ENEMY, FALL_MARKS[i % FALL_MARKS.size()]
				+ Vector3(0.6 * float(i / FALL_MARKS.size()), 0.0, 0.0))
		mark_scripted(u)
		u.add_to_group(&"assassins")
		u.command_stop()
		fall_units.append(u)
	if seam and seam.has_method(&"set_state"):
		seam.call(&"set_state", &"opening")
	_hide_for_card(FALL_VESSA, 6.5, [hero, vey] + fall_units)
	_play_card(&"m0_fall", _fall_card(), _fall_end_state)


## m0_fall end state (played, skipped or missing): Vey gone (no death, no XP), Vessa pushed clear and standing (HP
## unchanged), the Fall Shades alive at their marks attacking her, the seam sealed, Grief's Fire on, L11 queued.
func _fall_end_state() -> void:
	if fall_done:
		return
	fall_done = true
	_show_after_card()
	cast.remove_vey()
	if hero_alive():
		hero.global_position = FALL_VESSA_END
		hero.command_stop()
		for u: Variant in fall_units:
			if is_instance_valid(u) and (u as Unit).is_alive():
				order_wave(u as Unit, &"knife", hero.global_position)
				(u as Unit).command_attack(hero)
		_grief_fire()
	if seam and seam.has_method(&"set_state"):
		seam.call(&"set_state", &"sealed")
	say_line(11)


func _grief_fire() -> void:
	hero.add_modifier(GRIEF_MOD, GRIEF_STATS)
	grief_left = GRIEF_SECONDS
	M00Vfx.grief_hands(hero, GRIEF_SECONDS)


# ---------------------------------------------------------------- dawn (E10)

func _dawn_clock_ran_out() -> void:
	dawn_reached = true   # the scheduled waves and warnings check it: none after 8:00
	if lit_count >= 3:
		_dawn()
		return
	# Dawn waits for the fires: the Dark hold runs until the third is lit.
	dark_hold = true
	_dark_next = mission_time()
	set_objective(&"obj_dawn", "active")


func _dawn() -> void:
	if is_ending() or not fire_once(&"E10"):   # never turn a pending defeat into the forced dawn victory
		return
	dark_hold = false
	if cast.hush_on_field():
		say_line(8)
		set_objective(&"sec_hush", "failed")
	elif objective_state("sec_hush") == "":
		set_objective(&"sec_hush", "failed")
	set_objective(&"sec_guards", "done" if escort_alive() == ESCORT_SIZE else "failed")
	set_objective(&"obj_dawn", "done")
	set_objective(&"obj_vessa", "done")
	_ending = true   # no other ending from now on (win() below forces the victory)
	# The cutscene's opening: the Emberguard at SP_SW, every assassin turns for SP_NE.
	clear_waves()
	for u in assassins():
		u.set_meta(&"m0_leaving", true)
		u.set_meta(META_MODE, &"leave")
		u.command_move(spawn_point(&"ne"))
	# The Emberguard rides in from SP_SW; the (PAUSE) fallback card opens on them at the courtyard's south-west gate.
	emberguard.clear()
	var arrive := DAWN_ASHBY + DAWN_ARRIVAL if cinematics_enabled else EMBERGUARD_ENTRY
	var ashby := _spawn(make_unit("blaze_rider"), Unit.Team.PLAYER, arrive)
	ashby.unit_name = "Captain Ashby"
	ashby.scale = Vector3.ONE * 1.12
	ashby.set_meta(&"m0_ashby", true)
	emberguard.append(ashby)
	for i in DAWN_RIDERS.size():
		var at: Vector3 = (DAWN_RIDERS[i] + DAWN_ARRIVAL) if cinematics_enabled \
				else EMBERGUARD_ENTRY + Vector3(-1.5 + 1.0 * float(i), 0.0, 1.5)
		emberguard.append(_spawn(make_unit("blaze_rider"), Unit.Team.PLAYER, at))
	for u: Variant in emberguard:
		(u as Unit).face_direction(Vector3(1.0, 0.0, -1.0))
		(u as Unit).command_move(DAWN_ASHBY)
	# m0_dawn shot 1: the dawn preset fades in over 6 s (it also runs while the PAUSE card holds the tree).
	EmberfallNight.fade_to(self, EmberfallNight.dawn(), DAWN_FADE, true)
	_hide_for_card(Vector3(-36.0, 0.0, 38.0), 6.5, [hero] + emberguard)
	_play_card(&"m0_dawn", _dawn_card(), _dawn_end_state)


## m0_dawn end state: no assassin left, Ashby and the riders by the courtyard, the dawn preset fully on, victory 2 s
## later.
func _dawn_end_state() -> void:
	if dawn_done:
		return
	dawn_done = true
	_show_after_card()
	for u in assassins():
		u.leave_map()
	cast.hush_leave()
	for i in emberguard.size():
		if not is_instance_valid(emberguard[i]):
			continue
		var u := emberguard[i] as Unit
		if u == null or not is_instance_valid(u) or not u.is_alive():
			continue
		u.global_position = DAWN_ASHBY if i == 0 else DAWN_RIDERS[(i - 1) % DAWN_RIDERS.size()]
		u.command_stop()
		u.face_direction(Vector3(1.0, 0.0, 0.5))
	if hero_alive():   # beside Ashby, as the card leaves her (played or skipped: the same end state)
		hero.global_position = DAWN_MEET
		hero.command_stop()
	lighting_mood = &"dawn"
	EmberfallNight.apply_to(self, EmberfallNight.dawn())
	if fog and &"sight_scale" in fog:
		var scale: Array[float] = [1.0, 1.0]
		fog.set(&"sight_scale", scale)
	win(VICTORY_DELAY, true)


# ---------------------------------------------------------------- save / load

## C2-8 / C2-9: the braziers' rows (lit, quiet) and the cast's row (Hush re-bound) ran before this; put back what the
## lit handlers and the Fall left on the world (sight markers, Grief's Fire, the sealed seam).
func _after_load(_nodes: Dictionary) -> void:
	for m in _light_markers:
		if is_instance_valid(m):
			m.queue_free()
	_light_markers.clear()
	for b in braziers:
		if b.lit:
			_light_markers.append(SightMarker.spawn(Unit.Team.PLAYER, b.global_position, LIGHT_MARKER_RADIUS, 0.0, self))
	if grief_left > 0.0 and hero and is_instance_valid(hero):
		hero.add_modifier(GRIEF_MOD, GRIEF_STATS)
	if fall_done:
		cast.remove_vey()
		if seam and seam.has_method(&"set_state"):
			seam.call(&"set_state", &"sealed")


# ---------------------------------------------------------------- losses and story beats

## E11: Vessa dies.
func _on_player_hero_fell() -> void:
	if game_over or _ending:
		return
	fire_once(&"E11")
	say_line(12)
	set_objective(&"obj_vessa", "failed")
	lose(DEFEAT_DELAY)


## E12: the watch-keep falls.
func _on_watch_fallen(b: Building) -> void:
	if b.cancelled or game_over or _ending:
		return
	fire_once(&"E12")
	hud.show_message(MSG_WATCH_FALLEN, 4.0)
	lose(DEFEAT_DELAY)


func _on_escort_died(_u: Unit) -> void:
	if objective_state("sec_guards") == "active":
		set_objective(&"sec_guards", "failed")
	else:
		objectives_changed.emit()


func _on_vessa_level(_u: Unit, lvl: int) -> void:
	if lvl >= 3 and fire_once(&"E6b"):
		hud.show_message(HINT_LEVEL3, 8.0)


func _on_vey_first_spark() -> void:
	if fire_once(&"E1b"):
		say_line(13)
		say_line(14)


func _on_hush_smoked() -> void:
	if fire_once(&"E5"):
		say_line(7)


func _on_hush_fled() -> void:
	if not fire_once(&"E6"):
		return
	say_line(8)
	if not has_fired(&"E10"):
		set_objective(&"sec_hush", "done")


# ---------------------------------------------------------------- cutscenes and fallback cards

## Plays `id` from data/cinematics/<id>.tres when it exists (MissionBase.play_cutscene), else `card` (a PAUSE
## fallback card on the cinematic runtime); `end_state` runs once at the end, skipped or not, or at once with
## cinematics off / a refused play (tests, the 19.C9 skip rule).
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
	shot.look_from = focus + Vector3(0.0, 1.0, 0.0)
	shot.look_to = focus + Vector3(0.0, 1.0, 0.0)
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
	s.shots = [shot]
	return s


func _ep1_intro_card() -> CinematicScript:
	# The fallback text (ep1 7.4) as three subtitle lines (one long line runs past the bottom bar).
	var lines: Array = []
	var sentences := EP1_INTRO_TEXT.split(". ")
	var chunks: Array[String] = [". ".join(sentences.slice(0, 2)) + ".", ". ".join(sentences.slice(2, 3)) + ".",
			". ".join(sentences.slice(3))]
	for c in chunks:
		lines.append([&"narrator", c, EP1_INTRO_SECONDS / 3.0])
	return _card(EP1_INTRO_ID, "Episode 1", "The Night of Knives", lines, VESSA_START, Vector3(14.0, 22.0, 18.0),
			Vector3(8.0, 12.0, 11.0), EP1_INTRO_SECONDS + 1.0)


## m0_fall (PAUSE, 0:35, mission-00.md "Cinematic hooks"): five shots on the courtyard. The knives close in, Vey
## shouts and throws himself between them and Vessa (lightning, white flash), he is gone, the seam seals, Vessa
## rises. The world is frozen: only the actors these actions name move. The end state (_fall_end_state) is applied
## when it ends or is skipped.
func _fall_card() -> CinematicScript:
	_card_actors = {&"vessa": hero, &"vey": vey}
	for i in mini(fall_units.size(), 3):
		_card_actors[StringName("shade%d" % (i + 1))] = fall_units[i]
	var s := _card_script(&"m0_fall", FALL_VESSA_END)
	var c := FALL_VESSA
	# 1. Wide: the courtyard at night, the three knives step out of the dark toward her.
	var s1 := _shot(s, &"fall_wide", 6.0, CinematicShot.CameraMode.CRANE, c + Vector3(10.0, 13.0, 11.0),
			c + Vector3(7.0, 6.5, 7.5), c + Vector3(1.5, 0.6, -1.0), c + Vector3(1.0, 0.8, -0.5), 40.0, 36.0)
	s1.transition_in = CinematicShot.Transition.FADE_BLACK
	s1.transition_time = 0.6
	for i in 3:
		_cine_call(s1, 0.6 + 0.3 * i, "cine_face", [StringName("shade%d" % (i + 1)), c])
	_cine_call(s1, 0.2, "cine_face", [&"vessa", FALL_MARKS[0]])
	# 2. Vey sees the blades: "Vessa, MOVE!"
	var s2 := _shot(s, &"fall_vey", 6.0, CinematicShot.CameraMode.DOLLY, FALL_VEY + Vector3(3.4, 2.0, 1.2),
			FALL_VEY + Vector3(2.4, 1.7, 0.6), Vector3.ZERO, Vector3.ZERO, 38.0, 34.0)
	s2.look_actor = &"vey"
	_cine_call(s2, 0.0, "cine_face", [&"vey", FALL_MARKS[0]])
	s2.add_line(0.8, &"vey", String(CINE_LINES[0][2]), 2.5)
	_fx_call(s2, 2.6, [&"crackle", FALL_VEY])
	s2.add_action(3.0, &"anim", &"vey", Vector3.ZERO, {"hook": "play_attack"})
	# 3. Low and wide: he steps into the knives, lightning, a white flash; she is thrown clear.
	var s3 := _shot(s, &"fall_strike", 7.0, CinematicShot.CameraMode.STATIC, c + Vector3(1.0, 1.3, 6.0),
			c + Vector3(1.0, 1.3, 6.0), c + Vector3(2.5, 1.0, -0.5), c + Vector3(2.5, 1.0, -0.5), 44.0, 44.0)
	var strike := c.lerp(FALL_MARKS[0], 0.55)
	_cine_call(s3, 0.4, "cine_move", [&"vey", strike, 0.5])
	_fx_call(s3, 1.3, [&"spark", strike, FALL_MARKS[0]])
	_fx_call(s3, 1.4, [&"spark", strike, FALL_MARKS[2]])
	s3.add_action(1.5, &"shake", &"", Vector3.ZERO, {"amount": 0.6})
	for i in 3:
		s3.add_action(1.6 + 0.15 * i, &"anim", StringName("shade%d" % (i + 1)), Vector3.ZERO, {"hook": "play_attack"})
	s3.add_action(2.4, &"fade", &"", Vector3.ZERO, {"color": Color(1.0, 0.97, 0.9), "alpha": 0.85, "time": 0.2})
	s3.add_action(2.8, &"fade", &"", Vector3.ZERO, {"color": Color(1.0, 0.97, 0.9), "alpha": 0.0, "time": 1.2})
	_cine_call(s3, 2.7, "cine_move", [&"vessa", FALL_VESSA_END, 0.6, true])
	s3.add_action(3.2, &"anim", &"vey", Vector3.ZERO, {"hook": "play_hit"})
	# 4. Close on Vessa: where he stood there is only the smoke. "VEY!"
	var s4 := _shot(s, &"fall_gone", 8.0, CinematicShot.CameraMode.DOLLY, FALL_VESSA_END + Vector3(5.0, 4.4, 5.6),
			FALL_VESSA_END + Vector3(3.8, 3.6, 4.4), Vector3.ZERO, Vector3.ZERO, 36.0, 32.0)
	s4.look_actor = &"vessa"
	s4.add_action(0.2, &"despawn", &"vey", Vector3.ZERO, {"fade": 1.6})
	_fx_call(s4, 0.3, [&"smoke", strike])
	_cine_call(s4, 0.4, "cine_face", [&"vessa", strike])
	s4.add_line(0.9, &"vessa", String(CINE_LINES[1][2]), 2.0)
	s4.add_action(4.0, &"call", &"", Vector3.ZERO, {"method": "cine_seam", "args": [&"sealed"]})
	# 5. She stands up into the firelight: "...Malrik." and back to the game.
	var s5 := _shot(s, &"fall_rise", 8.0, CinematicShot.CameraMode.CRANE, FALL_VESSA_END + Vector3(3.8, 3.2, 4.6),
			FALL_VESSA_END + Vector3(7.0, 8.0, 10.0), Vector3.ZERO, Vector3.ZERO, 38.0, 42.0)
	s5.look_actor = &"vessa"
	_cine_call(s5, 0.5, "cine_face", [&"vessa", FALL_MARKS[1]])
	s5.add_line(1.4, &"vessa", String(CINE_LINES[2][2]), 2.5)
	s5.add_action(3.8, &"anim", &"vessa", Vector3.ZERO, {"hook": "play_cast", "arg": &"fireball"})
	s5.blend_to_game = true
	s5.transition_time = 1.0
	return s


## m0_dawn (0:30; the spec's HOLD runs as PAUSE until the player supports HOLD): four shots. The sky pales and the
## knives melt into the trees, the Emberguard rides in, Ashby and Vessa, the vow. End state: _dawn_end_state.
func _dawn_card() -> CinematicScript:
	_card_actors = {&"vessa": hero}
	var knives := assassins()
	for i in mini(knives.size(), 12):
		_card_actors[StringName("knife%d" % i)] = knives[i]
	for i in emberguard.size():
		_card_actors[&"ashby" if i == 0 else StringName("rider%d" % i)] = emberguard[i]
	var s := _card_script(&"m0_dawn", VESSA_START)
	var yard := Vector3(-39.5, 0.0, 39.0)
	# 1. High over the watch as the sky pales; the knives slip away.
	var s1 := _shot(s, &"dawn_sky", 7.0, CinematicShot.CameraMode.CRANE, yard + Vector3(16.0, 22.0, 20.0),
			yard + Vector3(11.0, 13.0, 14.0), yard + Vector3(2.0, 0.0, -2.0), yard, 46.0, 40.0)
	s1.transition_in = CinematicShot.Transition.FADE_BLACK
	s1.transition_time = 0.8
	s1.add_action(0.3, &"title", &"", Vector3.ZERO, {"text": "Dawn", "sub": "Emberfall", "time": 2.5})
	s1.add_line(1.2, &"narrator", String(CINE_LINES[3][2]), 4.0)
	for i in mini(knives.size(), 12):
		s1.add_action(1.5 + 0.25 * i, &"despawn", StringName("knife%d" % i), Vector3.ZERO, {"fade": 1.5})
	# 2. The Emberguard rides through the south-west gate.
	var s2 := _shot(s, &"dawn_riders", 8.0, CinematicShot.CameraMode.DOLLY, DAWN_ASHBY + Vector3(6.0, 2.6, 7.0),
			DAWN_ASHBY + Vector3(4.0, 2.2, 4.5), DAWN_ASHBY + DAWN_ARRIVAL * 0.6 + Vector3(0.0, 1.2, 0.0),
			DAWN_ASHBY + Vector3(0.0, 1.2, 0.0), 42.0, 38.0)
	if emberguard.size() > 0:
		_cine_call(s2, 0.3, "cine_move", [&"ashby", DAWN_ASHBY, 3.5])
	for i in range(1, emberguard.size()):
		_cine_call(s2, 0.5 + 0.2 * i, "cine_move", [StringName("rider%d" % i), DAWN_RIDERS[(i - 1) % DAWN_RIDERS.size()],
				3.5])
	# 3. Ashby and Vessa.
	var meet := DAWN_MEET
	var s3 := _shot(s, &"dawn_ashby", 8.0, CinematicShot.CameraMode.DOLLY, meet + Vector3(-1.0, 3.4, 5.2),
			meet + Vector3(-0.6, 3.0, 4.4), meet.lerp(DAWN_ASHBY, 0.5) + Vector3(0.0, 1.3, 0.0),
			meet.lerp(DAWN_ASHBY, 0.5) + Vector3(0.0, 1.3, 0.0), 40.0, 36.0)
	_cine_call(s3, 0.0, "cine_move", [&"vessa", meet, 0.0])
	_cine_call(s3, 0.02, "cine_face", [&"vessa", DAWN_ASHBY])
	_cine_call(s3, 0.02, "cine_face", [&"ashby", meet])
	s3.add_line(0.5, &"ashby", String(CINE_LINES[4][2]), 2.5)
	s3.add_line(3.3, &"vessa", String(CINE_LINES[5][2]), 3.0)
	# 4. The vow; the camera rises over the courtyard and hands back.
	var s4 := _shot(s, &"dawn_vow", 7.0, CinematicShot.CameraMode.CRANE, meet + Vector3(1.6, 1.7, 2.4),
			meet + Vector3(6.0, 7.5, 8.0), Vector3.ZERO, Vector3.ZERO, 36.0, 44.0)
	s4.look_actor = &"vessa"
	s4.add_line(0.5, &"vessa", String(CINE_LINES[6][2]), 3.5)
	s4.blend_to_game = true
	s4.transition_time = 1.0
	return s


func _card_script(id: StringName, focus: Vector3) -> CinematicScript:
	var s := CinematicScript.new()
	s.id = id
	s.kind = CinematicScript.Kind.ENGINE
	s.world_mode = CinematicScript.WorldMode.PAUSE
	s.letterbox_aspect = 2.39
	s.skippable = true
	s.return_focus = focus
	return s


func _shot(s: CinematicScript, id: StringName, seconds: float, mode: CinematicShot.CameraMode, from: Vector3,
		to: Vector3, look_from: Vector3, look_to: Vector3, fov_from: float, fov_to: float) -> CinematicShot:
	var shot := CinematicShot.make(id, seconds, mode)
	shot.from_pos = from
	shot.to_pos = to
	shot.look_from = look_from
	shot.look_to = look_to
	shot.fov_from = fov_from
	shot.fov_to = fov_to
	s.shots.append(shot)
	return shot


## Card staging: the frozen units that would stand in the close shots (the escort crowds the courtyard) are hidden
## while a card plays (cinematics on only) and shown again by its end state. Gameplay is untouched (PAUSE).
func _hide_for_card(center: Vector3, radius: float, keep: Array) -> void:
	if not cinematics_enabled:
		return
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or keep.has(u) or not u.is_alive() or not u.visible or _flat(u.global_position, center) > radius:
			continue
		u.visible = false
		_card_hidden.append(u)


func _show_after_card() -> void:
	for u: Variant in _card_hidden:
		if is_instance_valid(u):
			(u as Node3D).visible = true
	_card_hidden.clear()


## A cosmetic effect at `at` seconds of `shot` (never replayed by a skip).
func _fx_call(shot: CinematicShot, at: float, args: Array) -> void:
	_cine_call(shot, at, "cine_fx", args)


## A cosmetic `call` action (not replayed by a skip: the card's end state places everyone). Units are staged through
## cine_move / cine_face, never the player's move / face actions: those turn the unit's root node, while a Unit
## turns its visual child (face_direction), so they would leave it walking backwards after the card.
func _cine_call(shot: CinematicShot, at: float, method: String, args: Array) -> void:
	var a := shot.add_action(at, &"call", &"", Vector3.ZERO, {"method": method, "args": args})
	a.on_skip = false


## Card staging: slides the actor `tag` to `to` over `seconds` (0 = at once) while the PAUSE card holds the tree,
## facing the way (`backwards`: facing where it came from, a push).
func cine_move(tag: StringName, to: Vector3, seconds: float, backwards := false) -> void:
	var a: Variant = _card_actors.get(tag)
	var u: Unit = a as Unit if is_instance_valid(a) else null
	if u == null or not is_instance_valid(u):
		return
	var dir := to - u.global_position
	_cine_turn(u, -dir if backwards else dir)
	if seconds <= 0.0:
		_cine_place(to, u)
		return
	u.reset_physics_interpolation()
	var tw := u.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_method(_cine_place.bind(u), u.global_position, to, seconds).set_trans(Tween.TRANS_SINE) \
			.set_ease(Tween.EASE_OUT)


func cine_face(tag: StringName, at: Vector3) -> void:
	var a: Variant = _card_actors.get(tag)
	var u: Unit = a as Unit if is_instance_valid(a) else null
	if u and is_instance_valid(u):
		_cine_turn(u, at - u.global_position)


## Faces `u` along `dir` for a card. Old Vey's helper model shows its back along face_direction(dir) in the
## 2026-10-04 card screenshots (it is built facing -Z), so he is turned by -dir.
func _cine_turn(u: Unit, dir: Vector3) -> void:
	u.face_direction(-dir if u == vey else dir)
	u.reset_physics_interpolation()


static func _cine_place(p: Vector3, u: Unit) -> void:
	if is_instance_valid(u):
		u.global_position = p
		u.reset_physics_interpolation()


## Card effects (`call` actions): the M0 VFX, kept running while the PAUSE card holds the tree.
func cine_fx(kind: StringName, at: Vector3, to: Vector3 = Vector3.ZERO) -> void:
	var n: Node = null
	match kind:
		&"crackle":
			n = M00Vfx.crackle_blink(self, at)
		&"spark":
			n = M00Vfx.spark_arc(self, at + Vector3(0.0, 1.2, 0.0), to + Vector3(0.0, 1.0, 0.0))
		&"smoke":
			n = M00Vfx.smoke_burst(self, at)
	if n:
		n.process_mode = Node.PROCESS_MODE_ALWAYS


func cine_seam(state: StringName) -> void:
	if seam and seam.has_method(&"set_state"):
		seam.process_mode = Node.PROCESS_MODE_ALWAYS
		seam.call(&"set_state", state)
