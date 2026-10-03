class_name Mission01
extends MissionBase
## Campaign mission 1, "The Crown in the Ashes" (docs/design/mission-01.md = source of truth).
## Map "Emberfall" (seed 1101, not mirrored), 3 braziers that break the Ember Crown's seal, Pell the
## caged Ruin Peddler, scripted guards G1-G5 and waves W1 / Raid / W2 / W3 / Final, events E1-E9,
## the 15 dialogue lines. Built on MissionBase (M9.S1: objectives, dialogue, timers, guards / waves, the level
## cap, the Commander, the MissionHud, the end + campaign save; docs/design/mission-framework.md), which reuses
## Skirmish (keeps, Commander helpers, match timer, home healing, Malrik's respawn) and main.gd (world, camera, HUD).
## UI API (MissionBase): objectives() / briefing() / objective_state(id) / briefing_done() / speaker_color(),
## signal objectives_changed; global Events.objective_changed(id, state) and Events.dialogue(speaker, text).
## Scripted units (guards and waves) are in group "scripted" (and have meta "scripted" = true): the
## Commander must leave them alone. Malrik joins that group when the Final wave starts.

signal brazier_lit(brazier: MissionBrazier, lit_count: int)

const MISSION_ID := &"m01"
const MISSION_TITLE := "The Crown in the Ashes"
const MAP_SEED := 1101
const BOT_PROFILE_ID := &"mission_01"

const EMBER_HALL_POS := Vector3(-27.0, 0.0, 45.0)
const GLOOM_HALL_POS := Vector3(27.0, 0.0, -45.0)
const SHADOW_SPIRE_POS := Vector3(37.0, 0.0, -29.0)
const HOVEL_POS := Vector3(50.0, 0.0, -46.0)
const WESTWATCH_SPIRE_POS := Vector3(-39.0, 0.0, -25.0)
const WESTWATCH_SPIRE_HP := 750.0
const MALRIK_POS := Vector3(36.0, 0.0, -36.0)
const SHADOW_RALLY := Vector3(30.0, 0.0, -30.0)
const ARMY_POS := Vector3(-32.0, 0.0, 32.0)          ## PLAYER_START + (4, -4)
const M0_ESCORT_FLAG := "m0_escort_saved"             ## mission-00.md: + M0_ESCORT_GUARDS Flame Guards at ARMY_POS.
const M0_ESCORT_GUARDS := 2
## id -> [position, crystals]
const M1_NODES := {
	&"m1_fire_a": [Vector3(-46.0, 0.0, 34.0), 1500],
	&"m1_fire_b": [Vector3(-34.0, 0.0, 46.0), 1500],
	&"m1_west": [Vector3(-48.0, 0.0, -4.0), 2000],
	&"m1_south": [Vector3(6.0, 0.0, 46.0), 1500],
	&"node_shadow_a": [Vector3(46.0, 0.0, -34.0), 1500],
	&"node_shadow_b": [Vector3(34.0, 0.0, -46.0), 1500],
}
## Skirmish.node_of() suffixes (the Commander uses them) -> node ids.
const M1_FIRE_SUFFIXES := {&"a": &"m1_fire_a", &"b": &"m1_fire_b", &"mid": &"m1_south", &"rich": &"m1_west"}
const M1_SHADOW_SUFFIXES := {&"a": &"node_shadow_a", &"b": &"node_shadow_b"}
const WEST_HALL_SPOT := Vector3(-41.0, 0.0, -3.0)
const SOUTH_HALL_SPOT := Vector3(-1.0, 0.0, 47.0)

const HEARTHWARD := &"hearthward"
const WESTWATCH := &"westwatch"
const SOUTHGATE := &"southgate"
## [id, name, position, clearing radius]
const BRAZIER_TABLE := [
	[&"hearthward", "Hearthward", Vector3(-22.0, 0.0, 22.0), 6.0],
	[&"westwatch", "Westwatch", Vector3(-44.0, 0.0, -20.0), 8.0],
	[&"southgate", "Southgate", Vector3(22.0, 0.0, 44.0), 8.0],
]
const PELL_POS := Vector3(-24.0, 0.0, -6.0)
const PELL_CLEARING := 6.0
const PELL_FREE_RADIUS := 4.0
const PELL_GIFT := &"vital_root"
const M1_CACHE_SPOTS: Array[Vector3] = [Vector3(-8.0, 0.0, 28.0), Vector3(30.0, 0.0, 20.0)]
const CROWN_CLEARING := 12.0
const WARDEN_CAMP_RING := 3.0
const CROWN_WARDEN_RING := 4.0
const CROWN_WARDENS := 4
const SEAL_FLASH_RADIUS := 12.0

const E2_RADIUS := 16.0
const W1_TIME := 240.0
const RAID_INTERVAL := 150.0
const W3_TIME := 720.0
const FINAL_SECOND_DELAY := 45.0
const GUARD_TICK := 1.0
const MALRIK_RESPAWN := 60.0
const DEFEAT_DELAY := 3.0
const VICTORY_DELAY := 4.0
const LEVEL_CAP := 5
const OUTPOST_CUT := 0.4

## 0 easy, 1 normal, 2 hard (difficulty notes).
const COUNT_MULT: Array[float] = [0.6, 1.0, 1.4]
const HOLD_TIMES: Array[float] = [90.0, 120.0, 150.0]
const START_CRYSTALS_BY_DIFF: Array[int] = [400, 300, 250]

const SPEAKER_COLORS := {
	&"vessa": Color(1.0, 0.45, 0.1),
	&"malrik": Color(0.7, 0.3, 1.0),
	&"narrator": Color(0.9, 0.85, 0.7),
	&"pell": Color(0.85, 0.75, 0.5),
}
const SPEAKER_NAMES := {&"vessa": "Vessa", &"malrik": "Malrik", &"narrator": "Narrator", &"pell": "Pell"}
## L1-L15 (index 0 = L1).
const DIALOGUE := [
	[&"narrator", "The Master is gone. His crown is not."],
	[&"vessa", "An Ember Crown, in a place called Emberfall. I'm not saying it was left for me. I'm not NOT saying it."],
	[&"vessa", "Three braziers, one seal. How hard can it be to light things? It's my whole personality."],
	[&"malrik", "Little Vessa. You came a long way to lose something you never had."],
	[&"vessa", "One lit. Malrik, you still dress like a funeral that got lost on the way."],
	[&"pell", "Free at last! Buy something, would you? Shadow soldiers are terrible customers. They never pay, they just loom."],
	[&"narrator", "The Westwatch fire rises. Riders who remember the old kingdom ride to meet it."],
	[&"malrik", "Light all the candles you like. The dark just gets a better view."],
	[&"narrator", "Three flames answer. The seal cracks, and the old wardens wake up grumpy."],
	[&"vessa", "I'm here for the crown, not a lecture. Fine. Both."],
	[&"malrik", "Put it down. That crown was never meant for someone who throws fire at her problems."],
	[&"vessa", "Then it's in the right hands. I throw fire at ALL my problems."],
	[&"malrik", "Keep it warm for me. The other three will come for it now."],
	[&"narrator", "Far away, three apprentices feel the crown wake up, and begin to worry."],
	[&"vessa", "Tell the others... I was winning."],
]
const BRIEFING_PARAGRAPHS: Array[String] = [
	"The God Wizard vanished between one breath and the next. He left four apprentices, four kingdoms and not one word of instruction. His regalia fell across the world like sparks from a kicked fire.",
	"One spark still glows: the Ember Crown, sealed in Emberfall, the Master's burnt-out observatory on the border between the Fire and Shadow kingdoms. Three old braziers hold the seal shut.",
	"Vessa, the youngest and least patient apprentice, rides out the night she hears of it. Malrik of Shadow got there first and is camped at the far end of the ruins. He cannot light a brazier. She can.",
]
const HINT_START := "Walk Vessa with W A S D. Light the brazier to the north-east."
const HINT_FIRST_LIT := "Train more soldiers at the Ember Hall (Z / X)."
## Keep tiers in this mission (mission-01.md "Tiers", 2026-09-30): the Stronghold only (the Citadel comes later in the
## campaign), same price / time / 3:30 floor as the skirmish; Malrik's keep never upgrades. It opens the Hall's
## tier-2 units (TIER2_HALL_UNITS, listed after the tier-1 ones so Blaze Rider's later slot never moves them) and the
## Kilnwarden caster at the keep (key B).
const MAX_TIER := 2
const TIER2_HALL_UNITS: Array[StringName] = [&"pyre_adept", &"cinder_arbalest"]
const HINT_STRONGHOLD := "Your Keep can become a Stronghold: select the Keep and press %s (%d crystals). It opens %s."
const HINT_STRONGHOLD_SECONDS := 12.0
const MSG_SEALED_M1 := "The seal holds. Light the three braziers of Emberfall."
const MSG_MALRIK_FELL := "Malrik has fallen back into the shadows"

## Objective ids in panel order (define_objectives in _init).
const OBJ_ORDER: Array[StringName] = [&"obj_braziers", &"obj_crown", &"obj_hold", &"obj_vessa",
		&"sec_peddler", &"sec_outpost"]

var stronghold_hint_shown := false         ## Read only: the "Your Keep can become a Stronghold" message was shown.

var braziers: Array[MissionBrazier] = []   ## Read only, BRAZIER_TABLE order.
var pell: MissionCagedPeddler              ## Read only.
var ember_hall: TrainingBuilding           ## Read only: the pre-built Ember Hall.
var gloom_hall: Building                   ## Read only: Malrik's Gloom Hall (sec_outpost).
var westwatch_spire: Building              ## Read only: G3's Night Spire.
var guard_groups := {}                     ## Read only: &"G1".."G5" -> Array of units.
var waves_fired: Array[StringName] = []    ## Read only: &"W1", &"raid", &"W2", &"W3", &"final", &"final_2".
var lit_count := 0                         ## Read only.
var seal_broken := false                   ## Read only.
var riders_unlocked := false               ## Read only.
var hold_left := -1.0                      ## Read only: seconds left of obj_hold (-1 = not running).

var _w1_armed := false
var _next_raid := INF
var _crown_wardens: Array = []
var _jailers: Array = []
var _hall_type: BuildingType     # this mission's Ember Hall type (Blaze Rider locked until E5)
var _malrik_scripted := false


# ---------------------------------------------------------------- public API (UI, tests)

## objectives() rows (MissionBase, MissionHud format): progress + goal (braziers 0-3 / 3, else 0 / 0), time_left
## (obj_hold while running, else -1), counter ("1 / 3" or ""), countdown (= time_left).
func _objective_extra(id: StringName, o: Dictionary) -> Dictionary:
	var braz := id == &"obj_braziers"
	var t := hold_left if id == &"obj_hold" and o["state"] == "active" else -1.0
	return {
		"progress": lit_count if braz else 0,
		"goal": 3 if braz else 0,
		"time_left": t,
		"counter": "%d / 3" % lit_count if braz else "",
		"countdown": t,
	}


## The briefing screen: {title, paragraphs (3), objectives (3 primary texts), rule}.
func briefing() -> Dictionary:
	return {
		"title": "Mission 1: %s" % MISSION_TITLE,
		"paragraphs": BRIEFING_PARAGRAPHS.duplicate(),
		"objectives": [objective_text(&"obj_braziers"), objective_text(&"obj_crown"), objective_text(&"obj_hold")],
		"rule": objective_text(&"obj_vessa"),
	}


static func speaker_color(speaker: StringName) -> Color:
	return SPEAKER_COLORS.get(speaker, Color.WHITE)


static func speaker_name(speaker: StringName) -> String:
	return SPEAKER_NAMES.get(speaker, String(speaker).capitalize())


func brazier(id: StringName) -> MissionBrazier:
	for b in braziers:
		if b.brazier_id == id:
			return b
	return null


func hold_time() -> float:
	return HOLD_TIMES[clampi(mission_difficulty, 0, 2)]


# ---------------------------------------------------------------- setup

func _init() -> void:
	super()
	dialogue_lines = DIALOGUE
	speaker_colors = SPEAKER_COLORS.duplicate()
	speaker_names = SPEAKER_NAMES.duplicate()
	briefing_paragraphs = BRIEFING_PARAGRAPHS.duplicate()
	define_objectives([[&"obj_braziers", "primary"], [&"obj_crown", "primary"], [&"obj_hold", "primary"],
			[&"obj_vessa", "primary"], [&"sec_peddler", "secondary"], [&"sec_outpost", "secondary"]])


## Mission 1's knobs: the Stronghold only (MAX_TIER, Malrik's keep never upgrades), the Kilnwarden on the keep (B),
## start crystals by difficulty, level cap 5, Malrik's "mission_01" Commander, the end texts.
func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	c.mission_id = MISSION_ID
	c.title = MISSION_TITLE
	c.count_mult = COUNT_MULT.duplicate()
	c.easy_skip_types = [&"shadow_knight"]   # no Shadow Knights on easy (mission-01.md difficulty table)
	c.defeat_on_keep_lost = true
	c.tiers_enabled = true   # Skirmish._init turns tiers off for missions; this one has the Stronghold (MAX_TIER)
	c.max_tier = MAX_TIER
	c.bots_upgrade = false
	c.casters_enabled = true   # CasterKit.enabled_here: the keep lists the Kilnwarden (tier 2, key B)
	c.start_crystals = START_CRYSTALS_BY_DIFF.duplicate()
	c.level_cap = LEVEL_CAP
	c.bot_profile_id = BOT_PROFILE_ID
	c.bot_team = Unit.Team.ENEMY
	c.keep_lost_message = "The Fire keep has fallen"
	c.victory_banner = "VICTORY\nThe Ember Crown is yours"
	c.defeat_banner = "DEFEAT"
	return c


func _ready() -> void:
	_hall_type = _make_hall_type()
	get_tree().node_added.connect(_on_m1_node_added)
	super()


func _exit_tree() -> void:
	if get_tree().node_added.is_connected(_on_m1_node_added):
		get_tree().node_added.disconnect(_on_m1_node_added)


## Commander helper: this map's node ids ("a", "b" home; Fire also "mid" = south, "rich" = west).
func node_of(team: int, suffix: String) -> CrystalNode:
	var table: Dictionary = M1_SHADOW_SUFFIXES if team == Unit.Team.ENEMY else M1_FIRE_SUFFIXES
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


func _title_line() -> String:
	return "Mission 1: %s" % MISSION_TITLE


func _ground_spots() -> Array[Vector4]:
	return [Vector4(PLAYER_START.x, PLAYER_START.z, 13.0, 0.0), Vector4(SHADOW_START.x, SHADOW_START.z, 13.0, 0.0),
			Vector4(ARTIFACT_POS.x, ARTIFACT_POS.z, PILLAR_RING + 1.5, 1.0), Vector4(PELL_POS.x, PELL_POS.z, 5.0, 0.0)]


func _build_map() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = MAP_SEED
	var clearings := [[PLAYER_START, 18.0], [SHADOW_START, 18.0], [ARTIFACT_POS, CROWN_CLEARING],
			[PELL_POS, PELL_CLEARING], [EMBER_HALL_POS, 4.0], [GLOOM_HALL_POS, 4.0], [SHADOW_SPIRE_POS, 3.0],
			[HOVEL_POS, 4.0], [WESTWATCH_SPIRE_POS, 3.0], [WEST_HALL_SPOT, 4.0], [SOUTH_HALL_SPOT, 4.0],
			[M1_NODES[&"m1_west"][0], 7.0], [M1_NODES[&"m1_south"][0], 7.0]]
	for row in BRAZIER_TABLE:
		clearings.append([row[2], row[3]])
	for p: Vector3 in M1_CACHE_SPOTS:
		clearings.append([p, CACHE_CLEARING])

	for cluster in 10:
		var center := Vector3(rng.randf_range(-52, 52), 0.0, rng.randf_range(-52, 52))
		for i in rng.randi_range(5, 9):
			var p := center + Vector3(rng.randf_range(-6, 6), 0.0, rng.randf_range(-6, 6))
			var s := rng.randf_range(0.8, 1.3)
			if absf(p.x) > 57.0 or absf(p.z) > 57.0 or _in_clearing(p, clearings) or _in_path_lane(p):
				continue
			_add_tree(p, s)
	for i in 22:
		var p := Vector3(rng.randf_range(-54, 54), 0.0, rng.randf_range(-54, 54))
		var s := rng.randf_range(0.8, 2.2)
		var rot := rng.randf() * TAU
		if _in_clearing(p, clearings) or _in_path_lane(p):
			continue
		_add_rock(p, s, rot)
	# Pillar ring r 8 around the crown, gaps facing (-1, 1) and (1, -1) (pillars 4 and 9 left out).
	for i in 10:
		var h := rng.randf_range(2.0, 4.5)
		if i == PILLAR_GAP or i == PILLAR_GAP + 5:
			continue
		var a := float(i) * TAU / 10.0
		_add_pillar(ARTIFACT_POS + Vector3(cos(a) * PILLAR_RING, 0.0, sin(a) * PILLAR_RING), h)

	# Bases (finished buildings, navmesh obstacles before the bake).
	keep = build_grid.spawn_complete(BuildingType.find("fire_keep"), PLAYER_START + KEEP_OFFSET,
			Unit.Team.PLAYER) as Keep
	ember_hall = build_grid.spawn_complete(BuildingType.find("fire_barracks"), EMBER_HALL_POS,
			Unit.Team.PLAYER) as TrainingBuilding
	shadow_keep = build_grid.spawn_complete(BuildingType.find("shadow_keep"), SHADOW_START - KEEP_OFFSET,
			Unit.Team.ENEMY) as Keep
	gloom_hall = build_grid.spawn_complete(BuildingType.find("shadow_barracks"), GLOOM_HALL_POS, Unit.Team.ENEMY)
	build_grid.spawn_complete(BuildingType.find("shadow_tower"), SHADOW_SPIRE_POS, Unit.Team.ENEMY)
	build_grid.spawn_complete(BuildingType.find("shadow_hovel"), HOVEL_POS, Unit.Team.ENEMY)
	westwatch_spire = build_grid.spawn_complete(BuildingType.find("shadow_tower"), WESTWATCH_SPIRE_POS,
			Unit.Team.ENEMY)
	westwatch_spire.max_hp = WESTWATCH_SPIRE_HP
	westwatch_spire.hp = WESTWATCH_SPIRE_HP
	mark_scripted(westwatch_spire)
	gloom_hall.destroyed.connect(_on_gloom_hall_destroyed)
	for id: StringName in M1_NODES:
		_add_crystal_node(id, M1_NODES[id][0], int(M1_NODES[id][1]))

	for row in BRAZIER_TABLE:
		var b := MissionBrazier.new()
		b.brazier_id = row[0]
		b.display_name = row[1]
		b.name = "Brazier%s" % String(row[1])
		b.flame_target = ARTIFACT_POS
		nav_region.add_child(b)
		b.position = row[2]
		b.lit_up.connect(_on_brazier_lit)
		braziers.append(b)

	pell = MissionCagedPeddler.new()
	pell.name = "Pell"
	nav_region.add_child(pell)
	pell.position = PELL_POS
	pell.rotation.y = atan2(-PELL_POS.x, -PELL_POS.z)
	peddlers.append(pell)


func _on_navigation_ready() -> void:
	fog.reveal(Unit.Team.ENEMY, SHADOW_START, FogOfWar.START_REVEAL)
	var diff := clampi(mission_difficulty, 0, 2)

	# --- Fire (player)
	hero = Wizard.new()
	_spawn(hero, Unit.Team.PLAYER, PLAYER_START)
	for i in 5:
		var cinder := _spawn(make_unit("cinder_hand"), Unit.Team.PLAYER,
				PLAYER_START + Vector3(-4.0 + i * 1.2, 0.0, 4.0 - i * 1.2))
		cinder.call(&"command_gather", crystal_nodes[&"m1_fire_a" if i < 3 else &"m1_fire_b"])
	var guards := 6 if diff == 0 else 4
	var soldiers: Array[String] = []
	for i in guards:
		soldiers.append("flame_guard")
	soldiers.append_array(["ember_archer", "ember_archer"])
	for i in soldiers.size():
		_spawn(make_unit(soldiers[i]), Unit.Team.PLAYER,
				ARMY_POS + Vector3(-3.0 + (i % 4) * 1.5, 0.0, -1.0 + (i / 4) * 1.6))
	# Mission 0's escort (mission-00.md "Reward"): all 8 alive at dawn = 2 more Flame Guards ("the ones who stood with
	# you"). Read from the campaign save in real play only (tests keep save_campaign_on_victory off).
	if save_campaign_on_victory and CampaignState.open(campaign_save_path).flag(M0_ESCORT_FLAG):
		for i in M0_ESCORT_GUARDS:
			var g := _spawn(make_unit("flame_guard"), Unit.Team.PLAYER, ARMY_POS + Vector3(-2.25 + i * 1.5, 0.0, 2.6))
			g.set_meta(&"m0_escort", true)

	# --- Shadow (the bot's base)
	shadow_hero = ShadowWizard.new()
	_spawn(shadow_hero, Unit.Team.ENEMY, MALRIK_POS)
	raise_wizard(shadow_hero, 3, [&"shadow_lance", &"soul_siphon"])
	for i in 4:
		var thrall := _spawn(make_unit("gloom_thrall"), Unit.Team.ENEMY,
				SHADOW_START + Vector3(4.0 - i * 1.2, 0.0, -4.0 + i * 1.2))
		thrall.call(&"command_gather", crystal_nodes[&"node_shadow_a" if i < 2 else &"node_shadow_b"])
	for i in 4:
		_spawn(make_unit("shade"), Unit.Team.ENEMY, SHADOW_RALLY + Vector3(cos(i * 1.57) * 1.5, 0.0, sin(i * 1.57) * 1.5))

	# --- Guards G1-G5
	_spawn_guards()

	# --- The crown (sealed until the 3 braziers burn)
	crown = EmberCrown.new()
	crown.name = "EmberCrown"
	crown.seal_time = 1.0e12
	crown.match_time_source = match_time
	add_child(crown)
	crown.global_position = ARTIFACT_POS
	artifact = crown
	crown.claimed.connect(_on_m1_crown_claimed)
	crown.seal_refused.connect(_on_m1_seal_refused)

	for b in braziers:
		b.lighter = hero
	hero.died.connect(_on_vessa_died)
	shadow_hero.died.connect(_on_malrik_died)
	wizard_respawned.connect(_on_m1_wizard_respawned)
	for wiz: Wizard in [hero, shadow_hero]:
		ItemDrops.ensure_inventory(wiz)
	_spawn_m1_caches()

	# HUD, match clock, Commander, then the objectives appear (E1), in panel order; the briefing holds the intro.
	begin_mission([&"obj_braziers", &"obj_vessa", &"sec_peddler", &"sec_outpost"])


## E1, once the briefing is closed: camera on Vessa, lines L1-L3 and the first hint.
func _intro() -> void:
	camera_rig.focus_on(hero.global_position)
	say_line(1)
	say_line(2)
	say_line(3)
	# UX.1: the walk hint follows the Controls setting (Classic = right-click, Hero WASD = W A S D).
	var start_hint := HINT_START
	if hud.has_method(&"walk_hint"):
		start_hint = "%s. Light the brazier to the north-east." % str(hud.call(&"walk_hint", "Vessa"))
	hud.show_message(start_hint, 10.0)


func _spawn_guards() -> void:
	var b3: Vector3 = BRAZIER_TABLE[2][2]
	guard_groups[&"G1"] = spawn_group([["shade", 2], ["grave_hound", 1]], Vector3(-19.0, 0.0, 19.0), 1.5,
			Unit.Team.ENEMY, true)
	_jailers = spawn_group([["shade", 3]], Vector3(-24.0, 0.0, -9.0), 1.5, Unit.Team.ENEMY, true)
	guard_groups[&"G2"] = _jailers
	guard_groups[&"G3"] = spawn_group([["shade", 3], ["nightbolt", 2]], Vector3(-42.0, 0.0, -22.0), 2.5,
			Unit.Team.ENEMY, true)
	guard_groups[&"G4"] = spawn_group([["ruin_warden", 3]], b3, WARDEN_CAMP_RING, Unit.Team.NEUTRAL, true, true)
	_crown_wardens = spawn_group([["ruin_warden", CROWN_WARDENS]], ARTIFACT_POS, CROWN_WARDEN_RING,
			Unit.Team.NEUTRAL, false, true)
	guard_groups[&"G5"] = _crown_wardens
	for w: Unit in _crown_wardens:
		set_dormant(w, true)


func _spawn_m1_caches() -> void:
	for i in M1_CACHE_SPOTS.size():
		var cache := LostCache.new()
		cache.name = "LostCache%d" % i
		cache.rng.seed = MAP_SEED + i
		cache.match_time_source = match_time
		add_child(cache)
		cache.global_position = M1_CACHE_SPOTS[i]
		cache.opened.connect(_on_cache_opened)
		caches.append(cache)


## A copy of the Ember Hall type with the locked units left out (Ash Hurler: mission 2; Blaze Rider
## until Westwatch burns) and the tier-2 pair added (Stronghold). Every Fire hall of this mission gets it
## (_on_m1_node_added).
func _make_hall_type() -> BuildingType:
	var base := BuildingType.find("fire_barracks")
	if base == null:
		return null
	var t := base.duplicate() as BuildingType
	_hall_type = t
	_apply_hall_unlocks()
	return t


func _apply_hall_unlocks() -> void:
	var base := BuildingType.find("fire_barracks")
	if base == null or _hall_type == null:
		return
	var trains: Array[UnitType] = []
	for t in base.trains:
		if t == null or t.id == &"ash_hurler" or t.id == &"blaze_rider":
			continue
		trains.append(t)
	# Tier 2 (greyed "Requires Stronghold" until the keep upgrade), then the Blaze Rider once Westwatch burns: the
	# keys never move (Z X guard / archer, C V the tier-2 pair, B the rider).
	if tiers_enabled and TierSystem.ENABLED:
		for id in TIER2_HALL_UNITS:
			var t2 := UnitType.find(String(id))
			if t2:
				trains.append(t2)
	if riders_unlocked:
		var rider := UnitType.find("blaze_rider")
		if rider:
			trains.append(rider)
	_hall_type.trains = trains


func _on_m1_node_added(node: Node) -> void:
	var b := node as TrainingBuilding
	if b == null or _hall_type == null or b.building_type == null or b.building_type == _hall_type:
		return
	if b.building_type.id == &"fire_barracks":
		b.building_type = _hall_type


# ---------------------------------------------------------------- every frame

func _physics_process(delta: float) -> void:
	super(delta)   # MissionBase: the Skirmish tick, then the `after` timers
	if not match_started or game_over:
		return
	var now := match_time()
	if game_over or _ending:
		return
	_guard_tick -= delta
	if _guard_tick <= 0.0:
		_guard_tick = GUARD_TICK
		_tick_guards()
		_check_events()
		_check_stronghold_hint()
	_refresh_tick -= delta
	if _refresh_tick <= 0.0:
		_refresh_tick = REFRESH_INTERVAL
		_refresh_waves()
	_check_wave_triggers(now)
	for w in _crown_wardens:
		if is_dormant(w):
			(w as Unit).hp = (w as Unit).max_hp
	if hold_left >= 0.0:
		hold_left -= delta
		if hold_left <= 0.0:
			hold_left = 0.0
			_hold_done()


# The keep-lost defeat ("The Fire keep has fallen", MissionConfig.keep_lost_message) is MissionBase._check_end.

func _check_events() -> void:
	if not hero_alive():
		return
	# E2: Vessa comes near Hearthward.
	var b1 := brazier(HEARTHWARD)
	if not has_fired(&"E2") and b1 and _flat(hero.global_position, b1.global_position) <= E2_RADIUS:
		fire_once(&"E2")
		say_line(4)
	# E4: the jailers are dead and Vessa stands at the cage.
	if not has_fired(&"E4") and pell and _all_dead(_jailers) \
			and _flat(hero.global_position, pell.global_position) <= PELL_FREE_RADIUS:
		fire_once(&"E4")
		pell.open_cage()
		say_line(6)
		if ItemDrops.item_type(PELL_GIFT) != null:
			ItemDrops.spawn_pickup(self, PELL_GIFT, pell.global_position + Vector3(0.0, 0.0, 1.5))
		set_objective(&"sec_peddler", "done")


## Once, when the Stronghold can start (3:30, the Ember Hall standing): a message naming the key, price and new units
## (the tier chip under the top bar and the keep's X button pulse gold at the same time).
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


# ---------------------------------------------------------------- braziers, seal, crown

func _on_brazier_lit(b: MissionBrazier) -> void:
	if game_over:
		return
	lit_count += 1
	brazier_lit.emit(b, lit_count)
	set_objective(&"obj_braziers", "active" if lit_count < 3 else "done")
	if lit_count == 1:   # E3
		say_line(5)
		hud.show_message(HINT_FIRST_LIT, 8.0)
		_w1_armed = true
	if b.brazier_id == WESTWATCH:   # E5
		say_line(7)
		say_line(8)
		_unlock_riders()
		for i in 2:
			var rider := _spawn(make_unit("blaze_rider"), Unit.Team.PLAYER,
					b.global_position + Vector3(2.0 + i * 1.5, 0.0, 2.0))
			rider.set_meta(&"m1_free_rider", true)
		_fire_w2()
	if lit_count == 3:   # E6
		say_line(9)
		say_line(10)
		_break_seal()
		_fire_w3()


func _unlock_riders() -> void:
	if riders_unlocked:
		return
	riders_unlocked = true
	_apply_hall_unlocks()
	for node in get_tree().get_nodes_in_group("buildings"):
		var t := node as TrainingBuilding
		if t and t.building_type == _hall_type:
			t.queue_changed.emit()


func _break_seal() -> void:
	if seal_broken:
		return
	seal_broken = true
	if crown:
		crown.seal_time = 0.0
	for w in _crown_wardens:
		if is_instance_valid(w) and (w as Unit).is_alive():
			set_dormant(w as Unit, false)
	_seal_flash()
	set_objective(&"obj_crown", "active")


## 1 s white ring of radius 12 around the crown plus a light flash.
func _seal_flash() -> void:
	flash_ring(ARTIFACT_POS, SEAL_FLASH_RADIUS)


func _on_m1_seal_refused(_crown: EmberCrown, wizard: Wizard) -> void:
	if not game_over and wizard == hero:
		hud.show_message(MSG_SEALED_M1, 3.0)


func _on_m1_crown_claimed(claimed: Artifact, by: Wizard) -> void:
	var events := get_node_or_null(^"/root/Events")
	if events:
		events.artifact_claimed.emit(claimed, by)
	if game_over or by != hero or not fire_once(&"E7"):
		return
	hud.show_message("%s wears the %s" % [EmberCrown.short_name(by), claimed.artifact_name], 4.0)
	say_line(11)
	say_line(12)
	set_objective(&"obj_crown", "done")
	hold_left = hold_time()
	set_objective(&"obj_hold", "active")
	_next_raid = INF
	_fire_final()


# ---------------------------------------------------------------- waves

func _check_wave_triggers(now: float) -> void:
	if _w1_armed and not waves_fired.has(&"W1") and now >= W1_TIME:
		_fire_w1()
	if waves_fired.has(&"W1") and not has_fired(&"E7") and now >= _next_raid:
		_next_raid = now + RAID_INTERVAL
		_fire_raid()
	if not waves_fired.has(&"W3") and now >= W3_TIME:
		_fire_w3()


func _fire_w1() -> void:
	waves_fired.append(&"W1")
	_next_raid = match_time() + RAID_INTERVAL
	var target := _alive_pos(ember_hall, _alive_pos(keep, PLAYER_START))
	for u in _spawn_wave([["shade", 3], ["nightbolt", 1]]):
		order_wave(u, &"point", target)


func _fire_raid() -> void:
	waves_fired.append(&"raid")
	var target := _nearest_fire_worker_pos(_wave_spawn_point())
	for u in _spawn_wave([["grave_hound", 2]]):
		order_wave(u, &"point", target)


func _fire_w2() -> void:
	if waves_fired.has(&"W2"):
		return
	waves_fired.append(&"W2")
	var target := _alive_pos(keep, PLAYER_START)
	for u in _spawn_wave([["shade", 4], ["nightbolt", 2], ["grave_hound", 2]]):
		order_wave(u, &"point", target)


func _fire_w3() -> void:
	if waves_fired.has(&"W3"):
		return
	waves_fired.append(&"W3")
	var rows := [["shade", 5], ["nightbolt", 3]]
	if not _outpost_burned():
		rows.append(["shadow_knight", 1])
	for u in _spawn_wave(rows):
		order_wave(u, &"crown_then_vessa", ARTIFACT_POS)


func _fire_final() -> void:
	if waves_fired.has(&"final"):
		return
	waves_fired.append(&"final")
	var to := hero_pos()
	for u in _spawn_wave([["shade", 6], ["nightbolt", 4]]):
		order_wave(u, &"hero", to)
	_malrik_joins()
	after(FINAL_SECOND_DELAY, func() -> void:
		if game_over or _ending:
			return
		waves_fired.append(&"final_2")
		for u in _spawn_wave([["shadow_knight", 2], ["nightbolt", 2]]):
			order_wave(u, &"hero", hero_pos()))


## Malrik (level 4, hard 5: + Shroud) leaves his base and follows the Final wave.
func _malrik_joins() -> void:
	if shadow_hero == null or not is_instance_valid(shadow_hero):
		return
	if not _malrik_scripted:
		_malrik_scripted = true
		raise_wizard(shadow_hero, 5 if mission_difficulty >= 2 else 4, [&"umbral_shroud"])
		mark_scripted(shadow_hero)
	if shadow_hero.is_alive():
		order_wave(shadow_hero, &"hero", hero_pos())


## Spawns a wave at the Gloom Hall (counts through scaled(); sec_outpost: every later wave loses 40 %, rounded down).
func _spawn_wave(rows: Array) -> Array:
	return spawn_wave_at(rows, _wave_spawn_point(), Unit.Team.ENEMY, func(n: int) -> int:
		if _outpost_burned():
			n -= int(floor(float(n) * OUTPOST_CUT))
		return n)


## Every 3 s (MissionBase._refresh_waves): the Final wave (and Malrik) re-aim at Vessa (mode "hero"); W3 goes to
## Vessa once at the crown (this mode); other waves that ran out of orders push on to the Fire keep.
func _refresh_wave_unit(u: Unit, mode: StringName, vessa: Vector3) -> bool:
	if mode != &"crown_then_vessa":
		return false
	if _flat(u.global_position, ARTIFACT_POS) <= PILLAR_RING or not u.is_attack_moving() and u.attack_target == null:
		u.set_meta(META_MODE, &"hero")
		u.command_attack_move(vessa)
	return true


func _wave_spawn_point() -> Vector3:
	if gloom_hall and is_instance_valid(gloom_hall) and gloom_hall.is_alive() and gloom_hall is TrainingBuilding:
		return (gloom_hall as TrainingBuilding).spawn_point()
	if shadow_keep and is_instance_valid(shadow_keep) and shadow_keep.is_alive():
		return shadow_keep.spawn_point()
	return SHADOW_START


func _nearest_fire_worker_pos(from: Vector3) -> Vector3:
	var best := _alive_pos(keep, PLAYER_START)
	var best_d := INF
	for u in workers_of(Unit.Team.PLAYER):
		var d := _flat(u.global_position, from)
		if d < best_d:
			best_d = d
			best = u.global_position
	return best


# ---------------------------------------------------------------- objectives

func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_braziers":
			if not with_counter:
				return "Light the braziers of Emberfall"
			return "Light the braziers of Emberfall (%d / 3)" % lit_count
		&"obj_crown":
			return "Claim the Ember Crown"
		&"obj_hold":
			return "Survive Malrik's counterattack (%s)" % _clock(hold_time())
		&"obj_vessa":
			return "Vessa must survive"
		&"sec_peddler":
			return "Free the Ruin Peddler"
		&"sec_outpost":
			return "Burn Malrik's Gloom Hall"
	return String(id)


func _outpost_burned() -> bool:
	return _objs[&"sec_outpost"]["state"] == "done"


func _on_gloom_hall_destroyed(b: Building) -> void:
	if b.cancelled or game_over:
		return
	set_objective(&"sec_outpost", "done")


# ---------------------------------------------------------------- end of the mission

func _hold_done() -> void:
	if has_fired(&"E8") or _ending:
		return
	fire_once(&"E8")
	_ending = true
	hold_left = -1.0
	say_line(13)
	say_line(14)
	set_objective(&"obj_hold", "done")
	_shadow_walk_home()
	after(VICTORY_DELAY, func() -> void:
		_end_game(true)
		_shadow_walk_home())


func _shadow_walk_home() -> void:
	var home := _alive_pos(shadow_keep, SHADOW_START)
	for node in get_tree().get_nodes_in_group("units"):
		var u := node as Unit
		if u and u.is_alive() and int(u.team) == Unit.Team.ENEMY:
			u.set_meta(META_MODE, &"home")
			u.command_move(home + Vector3(randf_range(-4.0, 4.0), 0.0, randf_range(-4.0, 4.0)))
	clear_waves()


func _on_vessa_died(_unit: Unit) -> void:
	if game_over or _ending:
		return
	_ending = true
	hold_left = -1.0
	fire_once(&"E9")
	say_line(15)
	set_objective(&"obj_vessa", "failed")
	after(DEFEAT_DELAY, func() -> void: _end_game(false))


func _on_malrik_died(_unit: Unit) -> void:
	if game_over or _ending:
		return
	if hold_left > 0.0:   # killed during the hold: the hold is won
		_hold_done()
		return
	hud.show_message(MSG_MALRIK_FELL, 4.0)
	_respawn_left[Unit.Team.ENEMY] = MALRIK_RESPAWN


func _on_m1_wizard_respawned(wiz: Wizard) -> void:
	if wiz == shadow_hero and _malrik_scripted and not _ending:
		order_wave(wiz, &"hero", hero_pos())


# The end (_end_game: campaign save on victory, banners), the level cap (LEVEL_CAP), the dialogue lines and the
# helpers (hero_alive, hero_pos, _alive_pos, _all_dead, _flat) are MissionBase's.
