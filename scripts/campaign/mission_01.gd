class_name Mission01
extends Skirmish
## Campaign mission 1, "The Crown in the Ashes" (docs/design/mission-01.md = source of truth).
## Map "Emberfall" (seed 1101, not mirrored), 3 braziers that break the Ember Crown's seal, Pell the
## caged Ruin Peddler, scripted guards G1-G5 and waves W1 / Raid / W2 / W3 / Final, events E1-E9,
## the 15 dialogue lines. Reuses Skirmish (keeps, Commander helpers, match timer, home healing,
## Malrik's respawn) and main.gd (world building, camera, HUD).
## UI API: objectives() / briefing() / objective_state(id) / briefing_done() / speaker_color(),
## signal objectives_changed; global Events.objective_changed(id, state) and Events.dialogue(speaker, text).
## Scripted units (guards and waves) are in group "scripted" (and have meta "scripted" = true): the
## Commander must leave them alone. Malrik joins that group when the Final wave starts.

signal objectives_changed                                  ## Any objective state / counter changed.
signal dialogue_said(speaker: StringName, text: String)    ## Same as Events.dialogue (for tests).
signal brazier_lit(brazier: MissionBrazier, lit_count: int)

const MISSION_ID := &"m01"
const MISSION_TITLE := "The Crown in the Ashes"
const MAP_SEED := 1101
const SCRIPTED_GROUP := &"scripted"
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
const REFRESH_INTERVAL := 3.0
const GUARD_TICK := 1.0
const GUARD_HOME_TOLERANCE := 3.0
const MALRIK_RESPAWN := 60.0
const DEFEAT_DELAY := 3.0
const VICTORY_DELAY := 4.0
const LEVEL_CAP := 5
const OUTPOST_CUT := 0.4
const DIALOGUE_SECONDS := 5.0

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

## Objective ids in panel order.
const OBJ_ORDER: Array[StringName] = [&"obj_braziers", &"obj_crown", &"obj_hold", &"obj_vessa",
		&"sec_peddler", &"sec_outpost"]

## Set before the node enters the tree (menu / tests).
@export_range(0, 2) var mission_difficulty := 1
## True: MissionHud (scripts/ui/mission/) is attached with its briefing, which pauses the game; its
## `begun` signal calls briefing_done() (E1). Tests set it false before the node enters the tree
## (no MissionHud, E1 at once).
var show_briefing := true
## True while E1 waits for briefing_done().
var wait_for_briefing := false
var mission_hud: Node = null               ## Read only: the MissionHud (null in tests).
## Tests turn this off so they don't overwrite the player's campaign save.
var save_campaign_on_victory := true
## CasterKit.enabled_here reads it: the keep lists the Kilnwarden (tier 2, key B) in this mission.
var casters_enabled := true
var stronghold_hint_shown := false         ## Read only: the "Your Keep can become a Stronghold" message was shown.
var campaign_save_path := CampaignState.SAVE_PATH

var braziers: Array[MissionBrazier] = []   ## Read only, BRAZIER_TABLE order.
var pell: MissionCagedPeddler              ## Read only.
var ember_hall: TrainingBuilding           ## Read only: the pre-built Ember Hall.
var gloom_hall: Building                   ## Read only: Malrik's Gloom Hall (sec_outpost).
var westwatch_spire: Building              ## Read only: G3's Night Spire.
var guard_groups := {}                     ## Read only: &"G1".."G5" -> Array of units.
var dialogue_log: Array[String] = []       ## Read only: "speaker: text" of every line said.
var waves_fired: Array[StringName] = []    ## Read only: &"W1", &"raid", &"W2", &"W3", &"final", &"final_2".
var lit_count := 0                         ## Read only.
var seal_broken := false                   ## Read only.
var riders_unlocked := false               ## Read only.
var hold_left := -1.0                      ## Read only: seconds left of obj_hold (-1 = not running).

var _objs := {
	&"obj_braziers": {"type": "primary", "state": "hidden"},
	&"obj_crown": {"type": "primary", "state": "hidden"},
	&"obj_hold": {"type": "primary", "state": "hidden"},
	&"obj_vessa": {"type": "primary", "state": "hidden"},
	&"sec_peddler": {"type": "secondary", "state": "hidden"},
	&"sec_outpost": {"type": "secondary", "state": "hidden"},
}
var _fired := {}                 # event id -> true
var _intro_done := false
var _w1_armed := false
var _next_raid := INF
var _guards: Array = []          # Units that hold a spot (meta "m1_home")
var _wave_units: Array = []      # Units under wave orders (meta "m1_mode")
var _crown_wardens: Array = []
var _jailers: Array = []
var _timers: Array = []          # [match time, Callable]
var _guard_tick := 0.0
var _refresh_tick := 0.0
var _ending := false
var _hall_type: BuildingType     # this mission's Ember Hall type (Blaze Rider locked until E5)
var _capping := false
var _malrik_scripted := false


# ---------------------------------------------------------------- public API (UI, tests)

## Every objective, panel order (MissionHud format, docs/handoff/for-systems-coder.md): {id, text (without
## the counter), type ("primary" / "secondary"), primary (bool), state ("hidden" / "active" / "done" /
## "failed"), progress + goal (braziers 0-3 / 3, else 0 / 0), time_left (obj_hold while running, else -1),
## counter ("1 / 3" or ""), countdown (= time_left)}.
func objectives() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in OBJ_ORDER:
		var o: Dictionary = _objs[id]
		var braz := id == &"obj_braziers"
		var t := hold_left if id == &"obj_hold" and o["state"] == "active" else -1.0
		out.append({
			"id": id,
			"type": o["type"],
			"primary": o["type"] == "primary",
			"text": _objective_line(id, false),
			"state": o["state"],
			"progress": lit_count if braz else 0,
			"goal": 3 if braz else 0,
			"time_left": t,
			"counter": "%d / 3" % lit_count if braz else "",
			"countdown": t,
		})
	return out


## "active" / "done" / "failed", or "" while hidden / unknown (CampaignState reads it).
func objective_state(id: String) -> String:
	var o: Variant = _objs.get(StringName(id))
	if o == null or (o as Dictionary)["state"] == "hidden":
		return ""
	return String((o as Dictionary)["state"])


## The briefing screen: {title, paragraphs (3), objectives (3 primary texts), rule}.
func briefing() -> Dictionary:
	return {
		"title": "Mission 1: %s" % MISSION_TITLE,
		"paragraphs": BRIEFING_PARAGRAPHS.duplicate(),
		"objectives": [_objective_line(&"obj_braziers"), _objective_line(&"obj_crown"), _objective_line(&"obj_hold")],
		"rule": _objective_line(&"obj_vessa"),
	}


## The UI closed the briefing: camera on Vessa, lines L1-L3 and the first hint (E1).
func briefing_done() -> void:
	wait_for_briefing = false
	if hero != null and match_started:
		_intro()


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
	tiers_enabled = true   # Skirmish._init turns tiers off for missions; this one has the Stronghold (MAX_TIER)


func _ready() -> void:
	_hall_type = _make_hall_type()
	get_tree().node_added.connect(_on_m1_node_added)
	super()
	if tier_system:
		tier_system.max_tier = MAX_TIER
		tier_system.bots_upgrade = false
	economy.crystals = START_CRYSTALS_BY_DIFF[clampi(mission_difficulty, 0, 2)]
	economy.changed.emit()


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


func _objective_text() -> String:
	var lines: Array[String] = ["Mission 1: %s" % MISSION_TITLE]
	for id in OBJ_ORDER:
		var state: String = _objs[id]["state"]
		if state == "hidden":
			continue
		var mark := "[x] " if state == "done" else ("[!] " if state == "failed" else "- ")
		lines.append(mark + _objective_line(id))
	return "\n".join(lines)


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
	_mark_scripted(westwatch_spire)
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

	# --- Shadow (the bot's base)
	shadow_hero = ShadowWizard.new()
	_spawn(shadow_hero, Unit.Team.ENEMY, MALRIK_POS)
	_raise_wizard(shadow_hero, 3, [&"shadow_lance", &"soul_siphon"])
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
	if hero.has_signal(&"xp_changed"):
		hero.xp_changed.connect(_on_vessa_xp_changed)
	for wiz: Wizard in [hero, shadow_hero]:
		ItemDrops.ensure_inventory(wiz)
	_spawn_m1_caches()

	_setup_hud()
	_start_match()
	_add_commander()
	# Objectives appear (E1), in panel order.
	for id: StringName in [&"obj_braziers", &"obj_vessa", &"sec_peddler", &"sec_outpost"]:
		_set_objective(id, "active")
	_attach_mission_hud()
	if not wait_for_briefing:
		_intro()


## MissionHud.attach(self, self, hud): objectives panel, dialogue box and the briefing (pauses the
## game until Begin; `begun` starts E1).
func _attach_mission_hud() -> void:
	var path := "res://scripts/ui/mission/mission_hud.gd"
	if not show_briefing or not ResourceLoader.exists(path):
		return
	var script := load(path) as Script
	if script == null or not script.can_instantiate():
		return
	mission_hud = script.call(&"attach", self, self, hud) as Node
	if mission_hud and mission_hud.has_signal(&"begun"):
		wait_for_briefing = true
		mission_hud.connect(&"begun", briefing_done)


func _intro() -> void:
	if _intro_done:
		return
	_intro_done = true
	camera_rig.focus_on(hero.global_position)
	_say(1)
	_say(2)
	_say(3)
	# UX.1: the walk hint follows the Controls setting (Classic = right-click, Hero WASD = W A S D).
	var start_hint := HINT_START
	if hud.has_method(&"walk_hint"):
		start_hint = "%s. Light the brazier to the north-east." % str(hud.call(&"walk_hint", "Vessa"))
	hud.show_message(start_hint, 10.0)


func _spawn_guards() -> void:
	var b3: Vector3 = BRAZIER_TABLE[2][2]
	guard_groups[&"G1"] = _spawn_group([["shade", 2], ["grave_hound", 1]], Vector3(-19.0, 0.0, 19.0), 1.5,
			Unit.Team.ENEMY, true)
	_jailers = _spawn_group([["shade", 3]], Vector3(-24.0, 0.0, -9.0), 1.5, Unit.Team.ENEMY, true)
	guard_groups[&"G2"] = _jailers
	guard_groups[&"G3"] = _spawn_group([["shade", 3], ["nightbolt", 2]], Vector3(-42.0, 0.0, -22.0), 2.5,
			Unit.Team.ENEMY, true)
	guard_groups[&"G4"] = _spawn_group([["ruin_warden", 3]], b3, WARDEN_CAMP_RING, Unit.Team.NEUTRAL, true, true)
	_crown_wardens = _spawn_group([["ruin_warden", CROWN_WARDENS]], ARTIFACT_POS, CROWN_WARDEN_RING,
			Unit.Team.NEUTRAL, false, true)
	guard_groups[&"G5"] = _crown_wardens
	for w: Unit in _crown_wardens:
		_set_dormant(w, true)


## Spawns `rows` ([type_id, normal count]) in a ring around `center`. Counts scale with the
## difficulty (min 1; easy has no Shadow Knights). Units join group "scripted".
func _spawn_group(rows: Array, center: Vector3, ring: float, team: Unit.Team, hold_spot: bool,
		fixed_ring := false) -> Array:
	var types: Array[String] = []
	for row in rows:
		for i in _scaled(int(row[1]), String(row[0])):
			types.append(String(row[0]))
	var out: Array = []
	for i in types.size():
		if UnitType.find(types[i]) == null:
			continue
		var a := TAU / 8.0 + float(i) * TAU / maxf(1.0, float(types.size()))
		var r := ring if fixed_ring or types.size() > 1 else 0.0
		var u := _spawn(make_unit(types[i]), team, center + Vector3(cos(a) * r, 0.0, sin(a) * r))
		_mark_scripted(u)
		if hold_spot:
			u.set_meta(&"m1_home", u.global_position)
			_guards.append(u)
		out.append(u)
	return out


func _mark_scripted(n: Node) -> void:
	n.add_to_group(SCRIPTED_GROUP)
	n.set_meta(SCRIPTED_GROUP, true)


func _scaled(n: int, type_id: String = "") -> int:
	var diff := clampi(mission_difficulty, 0, 2)
	if diff == 0 and type_id == "shadow_knight":
		return 0
	return maxi(1, roundi(float(n) * COUNT_MULT[diff]))


## Dormant: out of "units" (nothing targets it), no aggro, hp kept full. Awake: normal warden.
func _set_dormant(u: Unit, dormant: bool) -> void:
	if dormant:
		u.set_meta(&"m1_aggro", u.aggro_range)
		u.aggro_range = 0.0
		u.remove_from_group("units")
		u.death_guard = func(_attacker: Variant) -> bool:
			u.hp = u.max_hp
			return true
		u.set_meta(&"m1_dormant", true)
	else:
		u.aggro_range = float(u.get_meta(&"m1_aggro", 8.0))
		if not u.is_in_group("units"):
			u.add_to_group("units")
		u.death_guard = Callable()
		u.remove_meta(&"m1_dormant")
		u.command_stop()


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


## The Shadow Commander (scripts/ai/), profile "mission_01": only gathers, trains and defends.
func _add_commander() -> void:
	var path := "res://scripts/ai/commander.gd"
	if not ResourceLoader.exists(path):
		return
	var script := load(path) as Script
	if script == null or not script.can_instantiate():
		return
	var bot: Node = script.new()
	bot.name = "ShadowBot"
	bot.set(&"team", Unit.Team.ENEMY)
	if &"profile_id" in bot:
		bot.set(&"profile_id", BOT_PROFILE_ID)
	else:
		var prof := _mission_profile()
		if prof and &"profile" in bot:
			bot.set(&"profile", prof)
	add_child(bot)


## AIProfile.mission_01() when the ai-coder added it, else easy knobs that never attack.
func _mission_profile() -> Resource:
	var script := load("res://scripts/ai/ai_profile.gd") as Script
	if script == null:
		return null
	for m in script.get_script_method_list():
		if StringName(m["name"]) == BOT_PROFILE_ID:
			return script.call(BOT_PROFILE_ID) as Resource
	var p: Resource = script.call(&"easy")
	p.set(&"id", BOT_PROFILE_ID)
	p.set(&"min_attack_pop", 99)
	p.set(&"worker_target_home", 4)
	p.set(&"worker_target_expanded", 4)
	p.set(&"second_expansion", false)
	p.set(&"malrik_joins", 0)
	return p


## Levels a wizard up to `to_level` (spell points as usual), then learns `learn` in order.
func _raise_wizard(w: Wizard, to_level: int, learn: Array) -> void:
	var guard := 0
	while w.level < to_level and guard < 20:
		guard += 1
		w.add_xp(maxi(1, w.xp_to_next() - w.xp))
	for id: StringName in learn:
		w.learn_spell(id)


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
	super(delta)
	if not match_started or game_over:
		return
	var now := match_time()
	_run_timers(now)
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
		if is_instance_valid(w) and (w as Unit).has_meta(&"m1_dormant"):
			(w as Unit).hp = (w as Unit).max_hp
	if hold_left >= 0.0:
		hold_left -= delta
		if hold_left <= 0.0:
			hold_left = 0.0
			_hold_done()


func _check_end() -> void:
	if _ending:
		return
	if keep == null or not is_instance_valid(keep) or not keep.is_alive():
		_ending = true
		hud.show_message("The Fire keep has fallen", 4.0)
		_end_game(false)


func _run_timers(now: float) -> void:
	var i := 0
	while i < _timers.size():
		if now >= float(_timers[i][0]):
			var c: Callable = _timers[i][1]
			_timers.remove_at(i)
			c.call()
		else:
			i += 1


func _after(seconds: float, c: Callable) -> void:
	_timers.append([match_time() + seconds, c])


## Scripted guards walk back to their spot when they have nothing to fight.
func _tick_guards() -> void:
	var alive: Array = []
	for g in _guards:
		if not is_instance_valid(g) or not (g as Unit).is_alive():
			continue
		alive.append(g)
		var u := g as Unit
		if u.has_meta(&"m1_dormant") or u.attack_target != null or u.is_attack_moving():
			continue
		var home: Vector3 = u.get_meta(&"m1_home")
		if Vector2(u.global_position.x - home.x, u.global_position.z - home.z).length() > GUARD_HOME_TOLERANCE:
			u.command_attack_move(home)
	_guards = alive


func _check_events() -> void:
	if not _vessa_alive():
		return
	# E2: Vessa comes near Hearthward.
	var b1 := brazier(HEARTHWARD)
	if not _fired.has(&"E2") and b1 and _flat(hero.global_position, b1.global_position) <= E2_RADIUS:
		_fired[&"E2"] = true
		_say(4)
	# E4: the jailers are dead and Vessa stands at the cage.
	if not _fired.has(&"E4") and pell and _all_dead(_jailers) \
			and _flat(hero.global_position, pell.global_position) <= PELL_FREE_RADIUS:
		_fired[&"E4"] = true
		pell.open_cage()
		_say(6)
		if ItemDrops.item_type(PELL_GIFT) != null:
			ItemDrops.spawn_pickup(self, PELL_GIFT, pell.global_position + Vector3(0.0, 0.0, 1.5))
		_set_objective(&"sec_peddler", "done")


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
	_set_objective(&"obj_braziers", "active" if lit_count < 3 else "done")
	if lit_count == 1:   # E3
		_say(5)
		hud.show_message(HINT_FIRST_LIT, 8.0)
		_w1_armed = true
	if b.brazier_id == WESTWATCH:   # E5
		_say(7)
		_say(8)
		_unlock_riders()
		for i in 2:
			var rider := _spawn(make_unit("blaze_rider"), Unit.Team.PLAYER,
					b.global_position + Vector3(2.0 + i * 1.5, 0.0, 2.0))
			rider.set_meta(&"m1_free_rider", true)
		_fire_w2()
	if lit_count == 3:   # E6
		_say(9)
		_say(10)
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
			_set_dormant(w as Unit, false)
	_seal_flash()
	_set_objective(&"obj_crown", "active")


## 1 s white ring of radius 12 around the crown plus a light flash.
func _seal_flash() -> void:
	var disc := CylinderMesh.new()
	disc.top_radius = SEAL_FLASH_RADIUS
	disc.bottom_radius = SEAL_FLASH_RADIUS
	disc.height = 0.05
	disc.radial_segments = 48
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 1.0, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var mi := MeshInstance3D.new()
	mi.mesh = disc
	mi.material_override = mat
	add_child(mi)
	mi.global_position = ARTIFACT_POS + Vector3(0.0, 0.1, 0.0)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.95, 0.85)
	light.light_energy = 6.0
	light.omni_range = SEAL_FLASH_RADIUS
	mi.add_child(light)
	light.position.y = 3.0
	var tween := create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, 1.0)
	tween.parallel().tween_property(light, "light_energy", 0.0, 1.0)
	tween.tween_callback(mi.queue_free)


func _on_m1_seal_refused(_crown: EmberCrown, wizard: Wizard) -> void:
	if not game_over and wizard == hero:
		hud.show_message(MSG_SEALED_M1, 3.0)


func _on_m1_crown_claimed(claimed: Artifact, by: Wizard) -> void:
	var events := get_node_or_null(^"/root/Events")
	if events:
		events.artifact_claimed.emit(claimed, by)
	if game_over or by != hero or _fired.has(&"E7"):
		return
	_fired[&"E7"] = true
	hud.show_message("%s wears the %s" % [EmberCrown.short_name(by), claimed.artifact_name], 4.0)
	_say(11)
	_say(12)
	_set_objective(&"obj_crown", "done")
	hold_left = hold_time()
	_set_objective(&"obj_hold", "active")
	_next_raid = INF
	_fire_final()


# ---------------------------------------------------------------- waves

func _check_wave_triggers(now: float) -> void:
	if _w1_armed and not waves_fired.has(&"W1") and now >= W1_TIME:
		_fire_w1()
	if waves_fired.has(&"W1") and not _fired.has(&"E7") and now >= _next_raid:
		_next_raid = now + RAID_INTERVAL
		_fire_raid()
	if not waves_fired.has(&"W3") and now >= W3_TIME:
		_fire_w3()


func _fire_w1() -> void:
	waves_fired.append(&"W1")
	_next_raid = match_time() + RAID_INTERVAL
	var target := _alive_pos(ember_hall, _alive_pos(keep, PLAYER_START))
	for u in _spawn_wave([["shade", 3], ["nightbolt", 1]]):
		_order_wave(u, &"point", target)


func _fire_raid() -> void:
	waves_fired.append(&"raid")
	var target := _nearest_fire_worker_pos(_wave_spawn_point())
	for u in _spawn_wave([["grave_hound", 2]]):
		_order_wave(u, &"point", target)


func _fire_w2() -> void:
	if waves_fired.has(&"W2"):
		return
	waves_fired.append(&"W2")
	var target := _alive_pos(keep, PLAYER_START)
	for u in _spawn_wave([["shade", 4], ["nightbolt", 2], ["grave_hound", 2]]):
		_order_wave(u, &"point", target)


func _fire_w3() -> void:
	if waves_fired.has(&"W3"):
		return
	waves_fired.append(&"W3")
	var rows := [["shade", 5], ["nightbolt", 3]]
	if not _outpost_burned():
		rows.append(["shadow_knight", 1])
	for u in _spawn_wave(rows):
		_order_wave(u, &"crown_then_vessa", ARTIFACT_POS)


func _fire_final() -> void:
	if waves_fired.has(&"final"):
		return
	waves_fired.append(&"final")
	var to := _vessa_pos()
	for u in _spawn_wave([["shade", 6], ["nightbolt", 4]]):
		_order_wave(u, &"vessa", to)
	_malrik_joins()
	_after(FINAL_SECOND_DELAY, func() -> void:
		if game_over or _ending:
			return
		waves_fired.append(&"final_2")
		for u in _spawn_wave([["shadow_knight", 2], ["nightbolt", 2]]):
			_order_wave(u, &"vessa", _vessa_pos()))


## Malrik (level 4, hard 5: + Shroud) leaves his base and follows the Final wave.
func _malrik_joins() -> void:
	if shadow_hero == null or not is_instance_valid(shadow_hero):
		return
	if not _malrik_scripted:
		_malrik_scripted = true
		_raise_wizard(shadow_hero, 5 if mission_difficulty >= 2 else 4, [&"umbral_shroud"])
		_mark_scripted(shadow_hero)
	if shadow_hero.is_alive():
		_order_wave(shadow_hero, &"vessa", _vessa_pos())


func _spawn_wave(rows: Array) -> Array:
	var types: Array[String] = []
	for row in rows:
		var n := _scaled(int(row[1]), String(row[0]))
		if _outpost_burned():   # sec_outpost: every later wave loses 40 % (rounded down)
			n -= int(floor(float(n) * OUTPOST_CUT))
		for i in n:
			types.append(String(row[0]))
	var at := _wave_spawn_point()
	var out: Array = []
	for i in types.size():
		if UnitType.find(types[i]) == null:
			continue
		var a := float(i) * 2.39996
		var r := 1.0 + 0.45 * sqrt(float(i))
		var u := _spawn(make_unit(types[i]), Unit.Team.ENEMY, at + Vector3(cos(a) * r, 0.0, sin(a) * r))
		_mark_scripted(u)
		out.append(u)
	return out


func _order_wave(u: Unit, mode: StringName, target: Vector3) -> void:
	u.set_meta(&"m1_mode", mode)
	u.set_meta(&"m1_target", target)
	u.command_attack_move(target)
	if not _wave_units.has(u):
		_wave_units.append(u)


## Every 3 s: the Final wave (and Malrik) re-aim at Vessa; W3 goes to Vessa once at the crown;
## other waves that ran out of orders push on to the Fire keep.
func _refresh_waves() -> void:
	var alive: Array = []
	var vessa := _vessa_pos()
	for w in _wave_units:
		if not is_instance_valid(w) or not (w as Unit).is_alive():
			continue
		alive.append(w)
		var u := w as Unit
		var mode: StringName = u.get_meta(&"m1_mode", &"point")
		match mode:
			&"vessa":
				if u.attack_target == null or not u.attack_target is Unit:
					u.command_attack_move(vessa)
			&"crown_then_vessa":
				if _flat(u.global_position, ARTIFACT_POS) <= PILLAR_RING or not u.is_attack_moving() and u.attack_target == null:
					u.set_meta(&"m1_mode", &"vessa")
					u.command_attack_move(vessa)
			_:
				if u.attack_target == null and not u.is_attack_moving():
					u.set_meta(&"m1_mode", &"keep")
					u.command_attack_move(_alive_pos(keep, vessa))
	_wave_units = alive


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

func _objective_line(id: StringName, with_counter := true) -> String:
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


## Sets the state and emits Events.objective_changed(id, state) (also for a counter change).
func _set_objective(id: StringName, state: String) -> void:
	var o: Dictionary = _objs[id]
	if o["state"] == "done" or o["state"] == "failed":
		return
	o["state"] = state
	var events := get_node_or_null(^"/root/Events")
	if events:
		events.objective_changed.emit(id, StringName(state))
	objectives_changed.emit()
	if hud and mission_hud == null:
		hud.set_objective(_objective_text())


func _outpost_burned() -> bool:
	return _objs[&"sec_outpost"]["state"] == "done"


func _on_gloom_hall_destroyed(b: Building) -> void:
	if b.cancelled or game_over:
		return
	_set_objective(&"sec_outpost", "done")


# ---------------------------------------------------------------- end of the mission

func _hold_done() -> void:
	if _fired.has(&"E8") or _ending:
		return
	_fired[&"E8"] = true
	_ending = true
	hold_left = -1.0
	_say(13)
	_say(14)
	_set_objective(&"obj_hold", "done")
	_shadow_walk_home()
	_after(VICTORY_DELAY, func() -> void:
		_end_game(true)
		_shadow_walk_home())


func _shadow_walk_home() -> void:
	var home := _alive_pos(shadow_keep, SHADOW_START)
	for node in get_tree().get_nodes_in_group("units"):
		var u := node as Unit
		if u and u.is_alive() and int(u.team) == Unit.Team.ENEMY:
			u.set_meta(&"m1_mode", &"home")
			u.command_move(home + Vector3(randf_range(-4.0, 4.0), 0.0, randf_range(-4.0, 4.0)))
	_wave_units.clear()


func _on_vessa_died(_unit: Unit) -> void:
	if game_over or _ending:
		return
	_ending = true
	hold_left = -1.0
	_fired[&"E9"] = true
	_say(15)
	_set_objective(&"obj_vessa", "failed")
	_after(DEFEAT_DELAY, func() -> void: _end_game(false))


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
		_order_wave(wiz, &"vessa", _vessa_pos())


func _end_game(victory: bool) -> void:
	if game_over:
		return
	_ending = true
	if victory and save_campaign_on_victory:
		CampaignState.open(campaign_save_path).on_mission_victory(MISSION_ID, self)
	super(victory)
	if victory:
		hud.show_banner("VICTORY\nThe Ember Crown is yours", Color(1.0, 0.85, 0.3))
	else:
		hud.show_banner("DEFEAT", Color(0.9, 0.3, 0.3))


## Level cap 5 this mission: XP past level 5 is dropped (the bar reads full).
func _on_vessa_xp_changed(_xp: int, _to_next: int) -> void:
	if _capping or hero == null or hero.level < LEVEL_CAP:
		return
	_capping = true
	hero.xp = 0
	hero.xp_changed.emit(0, 0)
	_capping = false


# ---------------------------------------------------------------- helpers

## Emits line `n` (1-15) through Events.dialogue (the UI queues them, 5 s each).
func _say(n: int) -> void:
	var line: Array = DIALOGUE[n - 1]
	var speaker: StringName = line[0]
	var text: String = line[1]
	dialogue_log.append("%s: %s" % [speaker, text])
	var events := get_node_or_null(^"/root/Events")
	if events and events.has_signal(&"dialogue"):
		events.emit_signal(&"dialogue", speaker, text)
	dialogue_said.emit(speaker, text)


func _vessa_alive() -> bool:
	return hero != null and is_instance_valid(hero) and hero.is_alive()


func _vessa_pos() -> Vector3:
	if _vessa_alive():
		return hero.global_position
	return _alive_pos(keep, PLAYER_START)


static func _alive_pos(n: Node3D, fallback: Vector3) -> Vector3:
	if n != null and is_instance_valid(n) and (not n.has_method(&"is_alive") or bool(n.call(&"is_alive"))):
		return n.global_position
	return fallback


static func _all_dead(units: Array) -> bool:
	for u in units:
		if is_instance_valid(u) and (u as Unit).is_alive():
			return false
	return true


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
