class_name MissionE4_03
extends MissionBase
## Episode 4, mission 3 "The Frozen Ashes" (docs/design/mission-e4-03.md): Ysolde goes back to the Sighing Wood and
## regrows five frozen groves while Torvald (Ice bot) and Aldra (enemy story unit, her own scripted camp) hold the wood.
## Break a grove's Rime Totems, plant it (Ysolde 4 s at its centre, nothing hostile within 10 m), keep enemies out while
## it grows (60 s, faster with soldiers in it); five green at once, then hold 1:30 with at least four standing. Maelis is
## called from 0:00 (helper_start_called). Reward: the Heartwood Seed (a campaign flag until its ItemType exists).
## Spotlight: the Briar Roc.
##
## Built deviations (2026-10-08, from the spec):
## - e2m1's map positions on a flat 120 x 120 ground (no burnt-and-frozen generator trees, no snow / moss paint).
## - The groves are mission state (frozen / thawed / planting / growing / grown) with a MissionGrove building as the
##   Grove Heart (900 HP, Sap Ward r 8, idle regen; no thorn bolt).
## - Aldra is the helper_aldra Helper on the enemy team at Torvald's level, escorting an invisible anchor the mission
##   moves (the Heartglade, then her Glass Spire, then the wave that carries her); she flees at 25 % HP (hidden, back
##   at the spire after 90 s; never before the Final once the spire is shattered).
## - The Glass Spire is an Ice tower copy (2 500 HP, 14 damage, range 11). Emberwatch is a Fire fort building of the
##   player's team (invulnerable, no shop).
## - The Heartwood Seed: `heartwood_seed_owned` flag (data/items has no heartwood_seed ItemType yet).
## - Balance (JS 2026-10-08, after a rush won in ~7:00 at the spec's numbers): grove guards are rime-bound
##   (GUARD_HP_MULT x HP, GUARD_DMG_MULT x damage, +GUARD_ARMOR armour) and one unit bigger (Stagwatch + Rime Seer,
##   the Heartglade / Fernhollow / Mossgate + Shardguard, Mossgate + Rime Colossus); Rime Totems 3 000 HP with the
##   Verdant regrowth (TOTEM_REGEN). A grown-out grove is "rooting": it must be held ROOT_TIME (30 s) by the capture
##   rules (ours alone = progress, both = frozen, nobody = decay, the enemy alone re-rimes it) before it counts as
##   grown. The home nodes hold 4 000 / 4 000 / 3 500 (spec 2 500 each): a player who loses armies to the sturdier
##   guards ran dry at ~20:00 with a grove still frozen. Checked by tests/test_e4m3_sim.gd (paced) and
##   tests/test_e4m3_rush_sim.gd (rush, >= 16:00).

const MISSION_ID := &"e4m3"
const MISSION_TITLE := "The Frozen Ashes"
const ENEMY := Unit.Team.ENEMY

const YSOLDE_START := Vector3(36.0, 0.0, 36.0)
const HEARTWOOD := Vector3(43.0, 0.0, 43.0)
const GROVE_HALL := Vector3(43.0, 0.0, 27.0)
const SEED_HOLLOWS: Array[Vector3] = [Vector3(56.0, 0.0, 50.0), Vector3(46.0, 0.0, 58.0)]
const ARMY_POS := Vector3(36.0, 0.0, 32.0)
const NODES := [[&"e4m3_green_a", Vector3(52.0, 0.0, 35.0), 4000], [&"e4m3_green_b", Vector3(35.0, 0.0, 50.0), 4000],
		[&"e4m3_charred", Vector3(26.0, 0.0, 28.0), 3500], [&"e2m1_south", Vector3(4.0, 0.0, 50.0), 2000],
		[&"e4m3_ember_a", Vector3(-46.0, 0.0, 34.0), 1500], [&"e4m3_ember_b", Vector3(-34.0, 0.0, 46.0), 1500],
		[&"e4m3_rime_a", Vector3(-46.0, 0.0, -34.0), 2000], [&"e4m3_rime_b", Vector3(-34.0, 0.0, -46.0), 2000]]
const EMBERWATCH := Vector3(-43.0, 0.0, 43.0)
const RIME_KEEP := Vector3(-43.0, 0.0, -43.0)
const RIME_HALL := Vector3(-27.0, 0.0, -45.0)
const RIME_SPIRE := Vector3(-37.0, 0.0, -29.0)
const RIME_LODGE := Vector3(-50.0, 0.0, -46.0)
const TORVALD_RALLY := Vector3(-30.0, 0.0, -30.0)
const GLASS_SPIRE := Vector3(43.0, 0.0, -43.0)
const ALDRA_HALL := Vector3(27.0, 0.0, -45.0)
const ALDRA_SPIRE := Vector3(37.0, 0.0, -29.0)
const ALDRA_LODGE := Vector3(50.0, 0.0, -46.0)
const ALDRA_RALLY := Vector3(30.0, 0.0, -30.0)
const HUSH_ENTRY := Vector3(58.0, 0.0, 0.0)
## Groves: id -> [name, centre, totems, guard group rows].
const GROVES := {
	&"hollowfen": ["Hollowfen", Vector3(18.0, 0.0, 44.0), [Vector3(18.0, 0.0, 37.0)], []],
	&"stagwatch": ["Stagwatch", Vector3(44.0, 0.0, 14.0), [Vector3(38.0, 0.0, 9.0), Vector3(50.0, 0.0, 9.0)],
			[["rimeshield", 3], ["shardcaster", 2], ["rime_seer", 1]]],
	&"heartglade": ["Heartglade", Vector3(0.0, 0.0, 9.0), [Vector3(-7.0, 0.0, 9.0), Vector3(7.0, 0.0, 9.0), Vector3(0.0, 0.0, 16.0)],
			[["rimeshield", 4], ["shardcaster", 2], ["rime_seer", 1], ["frost_mortar", 1], ["shardguard", 1]]],
	&"fernhollow": ["Fernhollow", Vector3(-30.0, 0.0, -4.0), [Vector3(-35.0, 0.0, -9.0), Vector3(-25.0, 0.0, -9.0)],
			[["rimeling", 3], ["shardcaster", 2], ["rimecarver", 1], ["shardguard", 1]]],
	&"mossgate": ["Mossgate", Vector3(-44.0, 0.0, -18.0), [Vector3(-50.0, 0.0, -14.0), Vector3(-38.0, 0.0, -14.0),
			Vector3(-44.0, 0.0, -11.0)], [["rimeshield", 4], ["hoarlight_magebow", 2], ["shardguard", 1], ["rime_colossus", 1]]],
}
const GROVE_R := 8.0
const PLANT_R := 4.0
const PLANT_TIME := 4.0
const PLANT_CLEAR := 10.0
const REPLANT_AFTER := 30.0
const HEART_HP := 900.0
const SAP_STATS := {"hp_regen": 3.0}
const TOTEM_HP := 3000.0
const TOTEM_REGEN := 2.0                 ## % of max HP per s, 10 s after the last hit (the Verdant rule)
const GUARD_HP_MULT := 2.15             ## grove guards: rime-bound, much sturdier than a wave (tests may override)
const GUARD_DMG_MULT := 1.1
const GUARD_ARMOR := 5.0
const ROOT_TIME := 30.0                 ## a grown-out grove must be held this long (capture rules) before it counts
const ROOT_DECAY := 0.10                ## of the bar per s when nobody holds it
const GROW_TIME: Array[float] = [45.0, 60.0, 75.0]
const RERIME_TIME: Array[float] = [15.0, 10.0, 7.0]
const HOLD_TIME: Array[float] = [60.0, 90.0, 120.0]
const HOLD_MIN: Array[int] = [3, 4, 4]
const R1_AT := 210.0
const COUNTER_DELAY := 45.0
const HUSH_AT := 540.0
const FROST_AT := 720.0
const MARCH_AT := 960.0
const FINAL_SECOND := 30.0
const SHOOT_AT := 45.0
const ALDRA_FLEE := 0.27
const ALDRA_BACK: Array[float] = [90.0, 90.0, 60.0]
const TORVALD_BACK := 60.0
const WIZARD_RETREAT := 0.35
const WIZARD_LEVEL: Array[int] = [5, 6, 7]
const DEFEAT_DELAY := 3.0
const VICTORY_DELAY := 2.0
const LEVEL_CAP := 8
const ESSENCE_CAP := 1500
const NO_SAVE_ESSENCE := 600
const COUNT_MULT: Array[float] = [0.6, 1.0, 1.4]
const START_CRYSTALS: Array[int] = [500, 400, 300]
const TORVALD_SPELLS := [&"rime_bolt", &"rime_bolt", &"flash_freeze", &"flash_freeze", &"rime_aegis"]

const WAVES := {
	&"R1": [["rimeshield", 3], ["rime_seer", 1], ["rimecarver", 1]],
	&"C1": [["rimeshield", 3], ["shardcaster", 2]],
	&"C2": [["rimeshield", 3], ["shardcaster", 2], ["rime_seer", 1]],
	&"C3": [["rimeshield", 3], ["shardcaster", 2], ["rime_seer", 1], ["frost_mortar", 1]],
	&"C4": [["rimeshield", 3], ["shardcaster", 2], ["rime_seer", 1], ["frost_mortar", 1], ["rime_colossus", 1]],
	&"HUSH": [["shade", 4]],
	&"FROST": [["rimeshield", 4], ["shardcaster", 2], ["frost_mortar", 1]],
	&"MARCH": [["rimeshield", 4], ["shardcaster", 2], ["rime_seer", 1], ["rime_colossus", 1]],
	&"FINAL_T": [["rimeshield", 3], ["shardcaster", 2], ["rime_colossus", 1]],
	&"FINAL_A": [["rimeshield", 3], ["shardcaster", 1], ["frost_mortar", 1]],
	&"FINAL_2": [["rimeling", 4], ["hoarlight_magebow", 2]],
}

const SPEAKER_COLORS := {&"ysolde": Color(0.55, 0.90, 0.35), &"maelis": Color(0.60, 0.85, 0.50),
		&"torvald": Color(0.55, 0.80, 1.00), &"aldra": Color(0.62, 0.95, 0.88), &"hush": Color(0.60, 0.50, 0.75),
		&"messenger": Color(0.80, 0.92, 0.60), &"narrator": Color(0.9, 0.85, 0.7)}
const SPEAKER_NAMES := {&"ysolde": "Ysolde", &"maelis": "Maelis", &"torvald": "Torvald", &"aldra": "Aldra",
		&"hush": "Mother Hush", &"messenger": "Wren", &"narrator": "Narrator"}
const DIALOGUE := [
	[&"narrator", "The Sighing Wood, at the edge of winter. Burnt by Shadow, frozen by Ice, and not dead yet."],
	[&"ysolde", "Five glades still remember being green. Break the rime, plant, and keep them warm."],
	[&"maelis", "Torvald holds the west. His glass warden holds the east. They're both very tidy."],
	[&"messenger", "My lady, the hollow by the camp... it's frosted, but it's... it's still breathing."],
	[&"ysolde", "Grow. Slowly, if you must. Just grow."],
	[&"narrator", "Green, in the Sighing Wood. For the first time since the fire."],
	[&"aldra", "They're planting. Go and put the frost back. Gently. Nothing here should grow strong."],
	[&"aldra", "Ysolde. Torvald asked me to keep this wood quiet. I keep what I'm asked to keep."],
	[&"ysolde", "You froze a grave, Aldra. I've come to open it."],
	[&"ysolde", "They broke it. Then we plant it again. Roots don't count how often."],
	[&"maelis", "Tall enough for birds now. Big ones, with thorns."],
	[&"ysolde", "The Last Heartwood. You held on all winter, didn't you?"],
	[&"torvald", "Aldra. Let her plant. We will see what the frost thinks of it."],
	[&"aldra", "Cracked. Not broken. I'll be back before your seedlings are."],
	[&"hush", "One more night, Ysolde. The Bishop pays for every one."],
	[&"aldra", "Enough green. This wood is ours by treaty, and by winter."],
	[&"maelis", "Her glass is sand now. She'll have to sulk somewhere warmer."],
	[&"torvald", "Ysolde. You were always the patient one. Why can you not wait for spring?"],
	[&"ysolde", "Because you froze the spring, Torvald. Somebody has to go and get it."],
	[&"narrator", "Five glades, green at once. Deep under the ash, something old turns over."],
	[&"ysolde", "Hold them. All of them. Just a little longer."],
	[&"torvald", "Aldra. Look. A shoot, in the ash. After all of that."],
	[&"aldra", "It's a weed, Torvald."],
	[&"torvald", "We were all weeds once. Pull back."],
	[&"ysolde", "You see, Maelis? It always comes back."],
	[&"maelis", "Mm. And it brought you a present."],
	[&"ysolde", "The wood can, now. Thank you, Vessa."],
	[&"narrator", "Under the frost, very slowly, the Sighing Wood began to breathe again."],
	[&"ysolde", "The wood... will remember..."],
	[&"maelis", "The new Heartwood's fallen. The wood has nothing left to grow from."],
]
const BRIEFING_PARAGRAPHS: Array[String] = [
	"The people are safe behind Vessa's border. Ysolde did not stay. She walked back east, into the wood she was born to keep, with a seed-pod in her hand that Vessa had kept for her all year.",
	"The Sighing Wood is still ash under rime. Torvald holds its west; Aldra Stillwater, his Glass Warden, holds its east, and her totems keep five old glades frozen so that nothing grows there again.",
	"Break the frost. Plant. Keep the young groves alive until all five are green at once. A wood that grows back cannot be held by anyone who wants it dead.",
]
const BRIEFING_LINE := "Groves grow only while no enemy stands in them. Guard them while they grow."
const HINT_START := "Break the Rime Totems at a glade, then hold Ysolde at its centre to plant. Keep enemies out while it grows."
const HINT_SAGE := "Bramblesage: Snagroot pulls a shield-caster out of the frost. Pollen Haze silences archers while you break totems."
const HINT_GROWN := "A green grove heals your soldiers. The Ice will come to freeze it again."
const HINT_CITADEL := "Your Stronghold can become a Citadel: select the Heartwood and press X (300 crystals, 90 s). It opens the Briar Roc (C): its Seed Storm roots from the air, out of the totems' reach."
const HINT_ROOTING := "A grove that has grown out must take root: keep soldiers or Ysolde in it for 30 s with no enemy inside."
const MSG_CLEAR := "Clear the glade first: the roots won't open while the enemy stands in it"
const MSG_TORVALD_FELL := "Torvald has fallen, the frost will bring him back"

## Read only.
var flag_override: Dictionary = {}
var no_save_fallback := false
var groves := {}                  ## id -> {state, meter, plant, rime, root, heart, totems, guards, replant_at, grown_once}
var guard_hp_mult := GUARD_HP_MULT
var guard_dmg_mult := GUARD_DMG_MULT
var grown_count := 0              ## groves that became grown at least once (counter-waves)
var hold_left := -1.0
var hold_paused := false
var torvald: Wizard = null
var aldra: Helper = null
var maelis: Unit = null
var hush: Unit = null
var glass_spire: Building
var aldra_hall: Building
var rime_hall: Building
var waves_fired: Array[StringName] = []
var said: Array[int] = []
var victory_time := -1.0
var lost_a_grove := false
var torvald_holds := false

var _said := {}
var _tick := 0.0
var _totem_type: BuildingType
var _spire_type: BuildingType
var _fort_type: BuildingType
var _aldra_anchor: Unit = null
var _aldra_goal := Vector3(0.0, 0.0, 9.0)
var _aldra_back_left := -1.0
var _aldra_fled := false
var _final_t_units: Array = []
var _last_obj_text := ""


# ---------------------------------------------------------------- setup

func _init() -> void:
	super()
	player_kingdom = &"nature"
	enemy_kingdom = &"ice"
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
	define_objectives([[&"obj_groves", "primary"], [&"obj_hold", "primary"], [&"obj_ysolde", "primary"],
			[&"sec_spire", "secondary"], [&"sec_unbroken", "secondary"]])


func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	c.mission_id = MISSION_ID
	c.title = MISSION_TITLE
	c.count_mult = COUNT_MULT.duplicate()
	c.easy_skip_types = [&"rime_colossus", &"shardguard", &"frost_mortar"]
	c.defeat_on_keep_lost = true
	c.keep_lost_message = "The new Heartwood has fallen"
	c.tiers_enabled = true
	c.max_tier = 3
	c.bots_upgrade = false
	c.start_tiers = {Unit.Team.PLAYER: 2, ENEMY: 2}
	c.casters_enabled = true
	c.t3_enabled = true
	c.helpers_enabled = true
	c.helper_start_called = true
	c.start_level = 5
	c.start_spells = [&"thornburst"]
	c.start_spell_points = 4
	c.level_cap = LEVEL_CAP
	c.start_crystals = START_CRYSTALS.duplicate()
	c.start_essence = 150
	c.instant_loss_on_wizard_death = true
	c.defeat_delay = DEFEAT_DELAY
	c.victory_banner = "VICTORY\nThe Sighing Wood breathes again"
	c.defeat_banner = "DEFEAT"
	c.rewards = CampaignState.MISSION_REWARDS.get(MISSION_ID, {})
	c.spotlight = {"id": &"briar_roc", "trigger": &"manual", "key_hint": "Heartwood: C",
			"card": "Briar Roc. A thorn bird: walls don't stop it, and its seed storm roots the crowd below."}
	return c


func _player_start() -> Vector3:
	return YSOLDE_START


func _use_map_dressing() -> bool:
	return false


func _lighting_preset() -> StringName:
	return &"warm"


func _title_line() -> String:
	return "Episode 4, Mission 3: %s" % MISSION_TITLE


func _ready() -> void:
	_totem_type = _make_totem_type()
	_spire_type = _make_spire_type()
	_fort_type = _make_fort_type()
	super()
	if camera_rig:
		camera_rig.focus_on(YSOLDE_START)


func _make_totem_type() -> BuildingType:
	var t := BuildingType.new()
	t.id = &"rime_totem"
	t.display_name = "Rime Totem"
	t.faction = &"ice"
	t.kind = &"totem"
	t.max_hp = TOTEM_HP
	t.idle_regen_pct = TOTEM_REGEN
	t.footprint = Vector2i(1, 1)
	t.height = 2.6
	t.sight_radius = 6.0
	t.counts_for_defeat = false
	t.color = Color(0.55, 0.80, 1.00)
	t.body_color = Color(0.75, 0.88, 0.98)
	return t


func _make_spire_type() -> BuildingType:
	var base := BuildingType.find("ice_tower")
	if base == null:
		return null
	var t := base.duplicate() as BuildingType
	t.id = &"glass_spire"
	t.display_name = "Glass Spire"
	t.max_hp = 2500.0
	t.attack_damage = 14.0
	t.attack_range = 11.0
	t.attack_cooldown = 1.4
	t.cost = 0
	t.counts_for_defeat = false
	return t


func _make_fort_type() -> BuildingType:
	var base := BuildingType.find("fire_keep")
	if base == null:
		return null
	var t := base.duplicate() as BuildingType
	t.id = &"emberwatch_fort"
	t.display_name = "Emberwatch"
	t.kind = &"fort"
	t.trains = []
	t.train_ids = []
	t.pop_bonus = 0
	t.attack_damage = 0.0
	t.counts_for_defeat = false
	return t


# ---------------------------------------------------------------- seats

func start_position(team: int) -> Vector3:
	return YSOLDE_START if team == Unit.Team.PLAYER else TORVALD_RALLY


func base_center(team: int) -> Vector3:
	return HEARTWOOD if team == Unit.Team.PLAYER else RIME_KEEP


func respawn_point(team: int) -> Vector3:
	var k := keep_of(team)
	return k.spawn_point() if k else (Vector3(-56.0, 0.0, -56.0) if team == ENEMY else HEARTWOOD)


func node_of(team: int, suffix: String) -> CrystalNode:
	var ids := {"a": &"e4m3_green_a", "b": &"e4m3_green_b", "x": &"e4m3_charred", "y": &"e2m1_south",
			"c": &"e4m3_ember_a", "d": &"e4m3_ember_b"} if team == Unit.Team.PLAYER else {"a": &"e4m3_rime_a", "b": &"e4m3_rime_b"}
	var v: Variant = crystal_nodes.get(ids.get(suffix, &""))
	if v == null or not is_instance_valid(v):
		return null
	var n := v as CrystalNode
	return n if n != null and not n.is_depleted() else null


func bot_point(team: int, p: Vector3) -> Vector3:
	var c := base_center(team)
	return c + Vector3(absf(p.x) * 0.25, 0.0, absf(p.z) * 0.25)


func bot_vector(_team: int, v: Vector3) -> Vector3:
	return Vector3(absf(v.x), 0.0, absf(v.z))


func natural_hall_spot(team: int) -> Vector3:
	return Vector3(20.0, 0.0, 22.0) if team == Unit.Team.PLAYER else Vector3.INF


func rich_hall_spot(_team: int) -> Vector3:
	return Vector3.INF


func market_slot(_team: int) -> Vector3:
	return Vector3.INF


func tower_slot(_team: int, _which: StringName) -> Vector3:
	return Vector3.INF


# ---------------------------------------------------------------- the map

func _build_map() -> void:
	for row: Array in NODES:
		_add_crystal_node(StringName(row[0]), row[1], int(row[2]))
	keep = build_grid.spawn_complete(BuildingType.find("nature_keep"), HEARTWOOD, Unit.Team.PLAYER) as Keep
	if keep:
		keep.destroyed.connect(func(_b: Building) -> void: say_l(30))
	build_grid.spawn_complete(BuildingType.find("nature_barracks"), GROVE_HALL, Unit.Team.PLAYER)
	for p in SEED_HOLLOWS:
		build_grid.spawn_complete(BuildingType.find("nature_hollow"), p, Unit.Team.PLAYER)
	if _fort_type:
		var fort := build_grid.spawn_complete(_fort_type, EMBERWATCH, Unit.Team.PLAYER)
		if fort:
			mark_scripted(fort)
			set_truce([fort], true, Unit.TRUCE_ALL)
	shadow_keep = build_grid.spawn_complete(BuildingType.find("ice_keep"), RIME_KEEP, ENEMY) as Keep
	rime_hall = build_grid.spawn_complete(BuildingType.find("ice_barracks"), RIME_HALL, ENEMY)
	build_grid.spawn_complete(BuildingType.find("ice_tower"), RIME_SPIRE, ENEMY)
	build_grid.spawn_complete(BuildingType.find("ice_lodge"), RIME_LODGE, ENEMY)
	if _spire_type:
		glass_spire = build_grid.spawn_complete(_spire_type, GLASS_SPIRE, ENEMY)
		if glass_spire:
			mark_scripted(glass_spire)
			glass_spire.destroyed.connect(_on_spire_destroyed)
	aldra_hall = build_grid.spawn_complete(BuildingType.find("ice_barracks"), ALDRA_HALL, ENEMY)
	if aldra_hall:
		mark_scripted(aldra_hall)
		aldra_hall.set_meta(TrainingBuilding.META_LOCKED, true)
	var sp := build_grid.spawn_complete(BuildingType.find("ice_tower"), ALDRA_SPIRE, ENEMY)
	var lg := build_grid.spawn_complete(BuildingType.find("ice_lodge"), ALDRA_LODGE, ENEMY)
	for b: Variant in [sp, lg]:
		if b != null:
			mark_scripted(b as Node)
	for id: StringName in GROVES:
		var totems: Array = []
		for p: Vector3 in GROVES[id][2]:
			var t := build_grid.spawn_complete(_totem_type, p, ENEMY)
			if t:
				mark_scripted(t)
				t.destroyed.connect(_on_totem_destroyed.bind(id))
				totems.append(t)
		groves[id] = {"state": &"frozen", "meter": 0.0, "plant": 0.0, "rime": 0.0, "root": 0.0, "heart": null, "totems": totems,
				"guards": [], "replant_at": -1.0, "grown_once": false}


# ---------------------------------------------------------------- start state

func _on_navigation_ready() -> void:
	var diff := clampi(mission_difficulty, 0, 2)
	for id: StringName in GROVES:
		fog.reveal(Unit.Team.PLAYER, GROVES[id][1], 10.0)
	fog.reveal(Unit.Team.PLAYER, EMBERWATCH, 12.0)
	_setup_champions()
	hero = _make_wizard(Unit.Team.PLAYER)
	_spawn(hero, Unit.Team.PLAYER, YSOLDE_START)
	_claim_wizard(hero, Unit.Team.PLAYER)
	ItemDrops.ensure_inventory(hero)
	var f := _flags()
	set_meta(&"campaign_flags", f.duplicate())
	_carry_essence()
	for i in 6:
		var w := _spawn(make_unit("sprigling"), Unit.Team.PLAYER, HEARTWOOD + Vector3(-5.0 + i * 1.5, 0.0, -6.0))
		w.call(&"command_gather", node_of(Unit.Team.PLAYER, "a" if i < 3 else "b"))
	var rows := [["thornling", 6 + (2 if diff == 0 else 0)], ["burr_slinger", 3], ["bloomtender", 2], ["vinelasher", 2],
			["greenheart_oathkeeper", 1], ["bramblehorn", 0 if diff == 2 else 1], ["bramblesage", 1]]
	var k := 0
	for row: Array in rows:
		for j in int(row[1]):
			_spawn(make_unit(String(row[0])), Unit.Team.PLAYER, ARMY_POS + Vector3((k % 6) * 1.6 - 4.0, 0.0, (k / 6) * 1.7))
			k += 1
	if bool(f.get("e4m2_volunteers", false)):
		for j in 4:
			var v := _spawn(make_unit("thornling"), Unit.Team.PLAYER, ARMY_POS + Vector3(j * 1.6 - 2.4, 0.0, -2.5))
			v.add_xp(400)   # veterancy 2
	# --- Torvald (the Ice bot) and his camp's army.
	torvald = _make_wizard(ENEMY)
	_spawn(torvald, ENEMY, TORVALD_RALLY)
	_claim_wizard(torvald, ENEMY)
	ItemDrops.ensure_inventory(torvald)
	raise_wizard(torvald, int(by_difficulty(WIZARD_LEVEL)), TORVALD_SPELLS)
	torvald.level_cap = int(by_difficulty(WIZARD_LEVEL))
	torvald.set_meta(META_HOME, TORVALD_RALLY)
	mark_scripted(torvald)
	shadow_hero = torvald
	torvald.died.connect(_on_torvald_died)
	for i in 5:
		var w := _spawn(make_unit("rime_hauler"), ENEMY, RIME_KEEP + Vector3(4.0 + i, 0.0, 6.0))
		w.call(&"command_gather", node_of(ENEMY, "a" if i < 3 else "b"))
	spawn_group([["rimeshield", 4], ["shardcaster", 2], ["rime_seer", 1]], TORVALD_RALLY, 3.0, ENEMY, true)
	_add_commander_e4m3()
	# --- Aldra at the Heartglade, the grove guards.
	_spawn_aldra()
	for id: StringName in GROVES:
		if (GROVES[id][3] as Array).is_empty():
			continue
		groves[id]["guards"] = spawn_group(GROVES[id][3], GROVES[id][1] + Vector3(0.0, 0.0, -2.0), 3.5, ENEMY, true)
		for v: Variant in groves[id]["guards"]:
			var gu := v as Unit
			gu.set_base_stat(&"max_hp", gu.get_base_stat(&"max_hp") * guard_hp_mult)
			gu.set_base_stat(&"attack_damage", gu.get_base_stat(&"attack_damage") * guard_dmg_mult)
			gu.set_base_stat(&"armor", gu.get_base_stat(&"armor") + GUARD_ARMOR)
			gu.hp = gu.max_hp
	_add_events()
	begin_mission([&"obj_groves", &"obj_ysolde", &"sec_spire"])
	maelis = _find_maelis()


func _find_maelis() -> Unit:
	for n in get_tree().get_nodes_in_group(&"units"):
		if n is Helper and int((n as Helper).team) == Unit.Team.PLAYER:
			return n as Unit
	return null


func _flags() -> Dictionary:
	if not flag_override.is_empty():
		return flag_override
	return CampaignState.open(campaign_save_path).flags


## Ysolde's essence (her track, CampaignState.YSOLDE_ESSENCE_FLAG); the no-save fallback: 150 + 600.
func _carry_essence() -> void:
	var cs := CampaignState.open(campaign_save_path)
	no_save_fallback = not cs.is_completed(&"e4m2") and flag_override.is_empty()
	var bank := EssenceBank.for_team(Unit.Team.PLAYER)
	if bank:
		bank.add(NO_SAVE_ESSENCE if no_save_fallback else int(_flags().get(CampaignState.YSOLDE_ESSENCE_FLAG, 0)))


func _add_commander_e4m3() -> void:
	var path := "res://scripts/ai/commander.gd"
	if not ResourceLoader.exists(path):
		return
	var script := load(path) as Script
	if script == null or not script.can_instantiate():
		return
	var p := AIProfile.ice(clampi(mission_difficulty, 0, 2))
	p.id = &"mission_e4_03"
	p.profile_id = p.id
	p.min_attack_pop = 99
	p.launch_attacks = false
	p.attack_full_pop = 0
	p.first_attack_by = 0.0
	p.worker_target_home = 5
	p.worker_target_expanded = 5
	p.worker_target_x2 = 5
	p.second_expansion = false
	p.expand_time = 1.0e6
	p.max_soldiers = 10
	p.defend_radius = 12.0
	p.build_rows = PackedStringArray(["H1"])
	p.rebuild = false
	p.hero_stays_home = true
	p.champion_max = 0
	p.trade = false
	p.map_fill = false
	p.item_build = PackedStringArray()
	var bot: Node = script.new()
	bot.name = "ShadowBot"
	bot.set(&"team", ENEMY)
	bot.set(&"profile", p)
	add_child(bot)
	commanders.append(bot)


## Aldra (D3): helper_aldra at Torvald's level on the enemy team, escorting an invisible anchor the mission moves.
func _spawn_aldra() -> void:
	var ht := HelperType.find(&"helper_aldra")
	if ht == null:
		return
	_aldra_anchor = make_unit("rimeling")
	_spawn(_aldra_anchor, ENEMY, GROVES[&"heartglade"][1])
	set_dormant(_aldra_anchor, true)
	_aldra_anchor.visible = false
	_aldra_anchor.collision_layer = 0
	_aldra_anchor.collision_mask = 0
	_aldra_anchor.process_mode = Node.PROCESS_MODE_DISABLED
	mark_scripted(_aldra_anchor)
	aldra = Helper.new()
	aldra.apply_helper_type(ht, torvald.level if torvald else 6)
	aldra.name = "Aldra"
	_spawn(aldra, ENEMY, GROVES[&"heartglade"][1] + Vector3(0.0, 0.0, -2.0))
	aldra.set_level(torvald.level if torvald else 6)
	aldra.bond_to(_aldra_anchor)
	aldra.set_stance(&"escort")
	mark_scripted(aldra)
	aldra.death_guard = func(_a: Variant) -> bool:
		_aldra_flee()
		return true
	_aldra_goal = GROVES[&"heartglade"][1]


func _aldra_flee() -> void:
	if aldra == null or is_dormant(aldra):
		return
	aldra.hp = aldra.max_hp
	set_dormant(aldra, true)
	aldra.visible = false
	aldra.global_position = GLASS_SPIRE + Vector3(0.0, 0.0, 6.0)
	_aldra_goal = GLASS_SPIRE + Vector3(0.0, 0.0, 6.0)
	if fire_once(&"E10"):
		say_l(14)
	_aldra_fled = true
	var spire_up := glass_spire != null and is_instance_valid(glass_spire) and glass_spire.is_alive()
	_aldra_back_left = float(by_difficulty(ALDRA_BACK)) if spire_up else -1.0


func _aldra_return(at: Vector3) -> void:
	if aldra == null or not is_instance_valid(aldra):
		return
	if is_dormant(aldra):
		set_dormant(aldra, false)
	aldra.visible = true
	aldra.hp = aldra.max_hp
	aldra.global_position = at
	_aldra_back_left = -1.0
	_aldra_fled = false


func _tick_aldra(dt: float) -> void:
	if aldra == null or not is_instance_valid(aldra):
		return
	if not is_dormant(aldra) and aldra.hp < aldra.max_hp * ALDRA_FLEE:
		_aldra_flee()
	if _aldra_back_left > 0.0:
		_aldra_back_left -= dt
		if _aldra_back_left <= 0.0:
			_aldra_return(GLASS_SPIRE + Vector3(0.0, 0.0, 6.0))
	if _aldra_anchor and is_instance_valid(_aldra_anchor):
		_aldra_anchor.global_position = _aldra_goal


# ---------------------------------------------------------------- briefing, objectives, lines

func briefing() -> Dictionary:
	return {
		"title": _title_line(),
		"paragraphs": BRIEFING_PARAGRAPHS.duplicate(),
		"objectives": [objective_text(&"obj_groves", false), objective_text(&"obj_ysolde", false), BRIEFING_LINE],
		"rule": Loc.sink(objective_text(&"obj_ysolde")),
	}


func groves_grown() -> int:
	var n := 0
	for id: StringName in groves:
		if groves[id]["state"] == &"grown":
			n += 1
	return n


func grove_state(id: StringName) -> StringName:
	return groves[id]["state"]


func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_groves":
			if with_counter:
				return "Regrow the groves of the Sighing Wood (%d / 5 green at once)" % groves_grown()
			return "Regrow the groves of the Sighing Wood"
		&"obj_hold":
			var need := int(by_difficulty(HOLD_MIN))
			if with_counter and hold_left >= 0.0:
				var s := int(ceil(hold_left))
				if hold_paused:
					return "Hold the groves until the wood answers (%d:%02d · at least %d standing, paused)" % [s / 60, s % 60, need]
				return "Hold the groves until the wood answers (%d:%02d · at least %d standing)" % [s / 60, s % 60, need]
			return "Hold the groves until the wood answers"
		&"obj_ysolde":
			return "Ysolde must survive"
		&"sec_spire":
			return "Shatter Aldra's Glass Spire"
		&"sec_unbroken":
			return "Lose no grove once it is green"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_groves":
			var parts: Array[String] = []
			for gid: StringName in GROVES:
				var g: Dictionary = groves[gid]
				var st := String(g["state"])
				if g["state"] == &"growing":
					st = "%d %%" % int(100.0 * float(g["meter"]))
				elif g["state"] == &"rooting":
					st = "rooting %d %%" % int(100.0 * float(g["root"]))
				parts.append("%s: %s" % [Loc.sink(String(GROVES[gid][0])), Loc.sink(st)])
			return {"counter": groves_grown(), "goal": 5, "detail": " · ".join(parts)}
		&"obj_hold":
			if hold_left >= 0.0:
				return {"time_left": hold_left}
	return {}


func say_l(n: int) -> void:
	if _said.has(n):
		return
	_said[n] = true
	said.append(n)
	say_line(n)


# ---------------------------------------------------------------- events

func _intro() -> void:
	fire_once(&"E1")
	play_cutscene(&"e4m3_arrival", func() -> void:
		say_l(1)
		if camera_rig and hero_alive():
			camera_rig.focus_on(hero.global_position))
	for n in [2, 3, 4]:
		say_l(n)
	if hud:
		hud.show_message(HINT_START, 12.0)


func _add_events() -> void:
	after(40.0, func() -> void:
		if fire_once(&"E3") and hud and not is_ending():
			hud.show_message(HINT_SAGE, 10.0))
	after(345.0, func() -> void:
		if not is_ending() and hud and keep and keep.tier < 3:
			hud.show_message(HINT_CITADEL, 12.0))
	after(R1_AT, _fire_wave.bind(&"R1"))
	if not bool(_flags().get("e4m2_hollow_burned", false)):
		after(HUSH_AT, _fire_wave.bind(&"HUSH"))
	after(FROST_AT, func() -> void:
		var hg: Dictionary = groves[&"heartglade"]
		if hg["state"] == &"grown" or hg["state"] == &"rooting" or hg["state"] == &"growing" and float(hg["meter"]) > 0.5:
			_fire_wave(&"FROST")
		else:
			add_event(&"frost_late", func() -> bool: return groves[&"heartglade"]["state"] == &"grown",
					func() -> void: after(30.0, _fire_wave.bind(&"FROST")))
			after(240.0, _fire_wave.bind(&"FROST")))
	after(MARCH_AT, _fire_wave.bind(&"MARCH"))
	add_event(&"E6", func() -> bool: return _side0_near(GROVES[&"heartglade"][1], 18.0), func() -> void:
		play_cutscene(&"e4m3_aldra", func() -> void:
			say_l(8)
			say_l(9)))
	add_event(&"E8", func() -> bool: return keep != null and is_instance_valid(keep) and keep.tier >= 3, func() -> void:
		say_l(11)
		show_spotlight())


func _side0_near(at: Vector3, r: float) -> bool:
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == Unit.Team.PLAYER and _flat(u.global_position, at) <= r \
				and not u.is_in_group(SCRIPTED_GROUP):
			return true
	return false


## "The target grove": the growing grove with the highest meter, else the grown grove nearest `from`, else the Grove Hall.
func target_grove(from: Vector3) -> Vector3:
	var best := Vector3.INF
	var m := -1.0
	for id: StringName in groves:
		var g: Dictionary = groves[id]
		var gm := 1.0 + float(g["root"]) if g["state"] == &"rooting" else float(g["meter"])
		if (g["state"] == &"growing" or g["state"] == &"rooting") and gm > m:
			m = gm
			best = GROVES[id][1]
	if best != Vector3.INF:
		return best
	var d := INF
	for id: StringName in groves:
		if groves[id]["state"] == &"grown":
			var dd := _flat(GROVES[id][1], from)
			if dd < d:
				d = dd
				best = GROVES[id][1]
	return best if best != Vector3.INF else GROVE_HALL


func _grown_by_hp(most: bool) -> Vector3:
	var best := Vector3.INF
	var v := -1.0 if most else INF
	for id: StringName in groves:
		var h: Variant = groves[id]["heart"]
		if groves[id]["state"] != &"grown" or h == null or not is_instance_valid(h):
			continue
		var hp := (h as Building).hp
		if (most and hp > v) or (not most and hp < v):
			v = hp
			best = GROVES[id][1]
	return best if best != Vector3.INF else target_grove(ALDRA_HALL)


func _aldra_spawn() -> Vector3:
	if aldra_hall and is_instance_valid(aldra_hall) and aldra_hall.is_alive() and aldra_hall is TrainingBuilding:
		return (aldra_hall as TrainingBuilding).spawn_point()
	if glass_spire and is_instance_valid(glass_spire) and glass_spire.is_alive():
		return GLASS_SPIRE + Vector3(0.0, 0.0, 6.0)
	return Vector3(56.0, 0.0, -56.0)


func _torvald_spawn() -> Vector3:
	if rime_hall and is_instance_valid(rime_hall) and rime_hall.is_alive() and rime_hall is TrainingBuilding:
		return (rime_hall as TrainingBuilding).spawn_point()
	var k := keep_of(ENEMY)
	return k.spawn_point() if k else Vector3(-56.0, 0.0, -56.0)


## The camp nearer `at` (Aldra's unless sec_spire is done: then Torvald's).
func _camp_spawn(at: Vector3) -> Vector3:
	if objective_state("sec_spire") == "done":
		return _torvald_spawn()
	return _aldra_spawn() if _flat(at, ALDRA_HALL) < _flat(at, RIME_HALL) else _torvald_spawn()


func _fire_wave(id: StringName) -> void:
	if is_ending() or waves_fired.has(id):
		return
	waves_fired.append(id)
	match id:
		&"R1":
			fire_once(&"E5")
			say_l(7)
			for u in spawn_wave_at(WAVES[&"R1"], _aldra_spawn(), ENEMY):
				order_wave(u as Unit, &"grove", target_grove(_aldra_spawn()))
		&"C1", &"C2", &"C3", &"C4":
			var at: Vector3 = _camp_spawn(GROVE_HALL)
			for u in spawn_wave_at(WAVES[id], at, ENEMY):
				order_wave(u as Unit, &"grove", target_grove(at))
		&"HUSH":
			fire_once(&"E11")
			say_l(15)
			var units := spawn_wave_at(WAVES[&"HUSH"], HUSH_ENTRY, ENEMY)
			if UnitType.find("mother_hush"):
				hush = _spawn(make_unit("mother_hush"), ENEMY, HUSH_ENTRY + Vector3(0.0, 0.0, 2.0))
				mark_scripted(hush)
				hush.death_guard = func(_a: Variant) -> bool:
					_hush_gone()
					return true
				units.append(hush)
			for u in units:
				order_wave(u as Unit, &"hero", YSOLDE_START)
		&"FROST":
			fire_once(&"E12")
			say_l(16)
			var at := _aldra_spawn()
			var units := spawn_wave_at(WAVES[&"FROST"], at, ENEMY)
			if aldra and is_instance_valid(aldra) and (not _aldra_fled or objective_state("sec_spire") != "done"):
				_aldra_return(at + Vector3(1.5, 0.0, 1.0))
				_aldra_goal = _grown_by_hp(true)
			for u in units:
				order_wave(u as Unit, &"grove_hp", _grown_by_hp(true))
		&"MARCH":
			fire_once(&"E14")
			say_l(18)
			say_l(19)
			var at := _torvald_spawn()
			var units := spawn_wave_at(WAVES[&"MARCH"], at, ENEMY)
			if torvald and is_instance_valid(torvald) and torvald.is_alive():
				units.append(torvald)
			var hg: Dictionary = groves[&"heartglade"]
			var to: Vector3 = GROVES[&"heartglade"][1] if _planted(hg) else target_grove(at)
			for u in units:
				order_wave(u as Unit, &"march", to)
		&"FINAL":
			var tat := _torvald_spawn()
			_final_t_units = spawn_wave_at(WAVES[&"FINAL_T"], tat, ENEMY)
			if torvald and is_instance_valid(torvald) and torvald.is_alive():
				_final_t_units.append(torvald)
			for u in _final_t_units:
				order_wave(u as Unit, &"heartglade", GROVES[&"heartglade"][1])
			var aat := _aldra_spawn()
			if aldra and is_instance_valid(aldra):
				_aldra_return(aat + Vector3(1.5, 0.0, 1.0))
				_aldra_goal = _grown_by_hp(false)
			for u in spawn_wave_at(WAVES[&"FINAL_A"], aat, ENEMY):
				order_wave(u as Unit, &"grove_low", _grown_by_hp(false))
			after(FINAL_SECOND, func() -> void:
				if is_ending():
					return
				for u in spawn_wave_at(WAVES[&"FINAL_2"], _torvald_spawn(), ENEMY):
					order_wave(u as Unit, &"grove", target_grove(_torvald_spawn())))
			after(SHOOT_AT, _shoot)


func _hush_gone() -> void:
	if hush and is_instance_valid(hush):
		_wave_units.erase(hush)
		hush.queue_free()
	hush = null


## E16 (Final + 45 s): e4m3_shoot (L22-L24); Torvald's group holds where it stands until the Withdraw.
func _shoot() -> void:
	if is_ending():
		return
	fire_once(&"E16")
	torvald_holds = true
	for v: Variant in _final_t_units:
		if v != null and is_instance_valid(v) and (v as Unit).is_alive():
			order_wave(v as Unit, &"hold", (v as Unit).global_position)
	play_cutscene(&"e4m3_shoot", func() -> void:
		say_l(22)
		say_l(23)
		say_l(24))


func _push(u: Unit, at: Vector3, near := 4.0) -> void:
	if u.attack_target == null and _flat(u.global_position, at) > near and not u.is_attack_moving():
		u.command_attack_move(at)


func _refresh_wave_unit(u: Unit, mode: StringName, _hero_at: Vector3) -> bool:
	if u == torvald and u.hp < u.max_hp * WIZARD_RETREAT and mode != &"withdraw":
		u.set_meta(META_MODE, &"anchor")
		u.command_move(TORVALD_RALLY)
		return true
	match mode:
		&"grove":
			_push(u, target_grove(u.global_position), 3.0)
			return true
		&"grove_hp":
			_push(u, _grown_by_hp(true), 3.0)
			return true
		&"grove_low":
			_push(u, _grown_by_hp(false), 3.0)
			return true
		&"march", &"heartglade":
			var hg: Dictionary = groves[&"heartglade"]
			var to: Vector3 = GROVES[&"heartglade"][1] if mode == &"heartglade" or _planted(hg) \
					else target_grove(u.global_position)
			_push(u, to, 3.0)
			return true
		&"hold":
			var at: Vector3 = u.get_meta(META_TARGET, u.global_position)
			if u.attack_target == null and _flat(u.global_position, at) > 5.0:
				u.command_attack_move(at)
			return true
		&"withdraw", &"anchor":
			return true
	return false


# ---------------------------------------------------------------- groves

func _on_totem_destroyed(_b: Building, id: StringName) -> void:
	var g: Dictionary = groves[id]
	var left := (g["totems"] as Array).filter(func(t: Variant) -> bool: return is_instance_valid(t) and (t as Building).is_alive())
	if left.is_empty() and g["state"] == &"frozen":
		g["state"] = &"thawed"
		flash_ring(GROVES[id][1], 4.0)


func _enemy_within(at: Vector3, r: float, count_totems := false) -> int:
	var n := 0
	for u in get_tree().get_nodes_in_group(&"units"):
		var e := u as Unit
		if e and e.is_alive() and int(e.team) == ENEMY and not is_dormant(e) and _flat(e.global_position, at) <= r:
			n += 1
	if count_totems:
		for id: StringName in groves:
			for t: Variant in groves[id]["totems"]:
				if is_instance_valid(t) and (t as Building).is_alive() and _flat((t as Building).global_position, at) <= r:
					n += 1
	return n


func _own_within(at: Vector3, r: float) -> int:
	var n := 0
	for u in get_tree().get_nodes_in_group(&"units"):
		var e := u as Unit
		if e and e.is_alive() and int(e.team) == Unit.Team.PLAYER and not e.is_worker() and e != hero \
				and _flat(e.global_position, at) <= r:
			n += 1
	return n


func _tick_groves(dt: float) -> void:
	var grow_time := float(by_difficulty(GROW_TIME))
	var rerime := float(by_difficulty(RERIME_TIME))
	for id: StringName in groves:
		var g: Dictionary = groves[id]
		var at: Vector3 = GROVES[id][1]
		match g["state"]:
			&"thawed":
				if float(g["replant_at"]) > mission_time():
					continue
				if hero_alive() and _flat(hero.global_position, at) <= PLANT_R:
					if _enemy_within(at, PLANT_CLEAR, true) > 0:
						g["plant"] = 0.0
						if hud and fire_once(StringName("clear_%s" % id)):
							hud.show_message(MSG_CLEAR, 4.0)
						continue
					g["plant"] = float(g["plant"]) + dt / PLANT_TIME
					if float(g["plant"]) >= 1.0:
						g["plant"] = 0.0
						g["state"] = &"growing"
						g["meter"] = 0.0
						g["rime"] = 0.0
						if fire_once(&"E2"):
							say_l(5)
				else:
					g["plant"] = 0.0
			&"growing":
				var foes := _enemy_within(at, GROVE_R)
				var own := _own_within(at, GROVE_R)
				if foes > 0:
					if own == 0:
						g["rime"] = float(g["rime"]) + dt
						if float(g["rime"]) >= rerime:
							g["state"] = &"thawed"
							g["meter"] = 0.0
							g["rime"] = 0.0
							if fire_once(&"E7"):
								say_l(10)
					continue
				g["rime"] = 0.0
				var mult := minf(2.0, 1.0 + 0.25 * own)
				g["meter"] = minf(1.0, float(g["meter"]) + dt * mult / grow_time)
				if float(g["meter"]) >= 1.0:
					g["state"] = &"rooting"
					g["root"] = 0.0
					if hud and fire_once(&"rooting_hint"):
						hud.show_message(HINT_ROOTING, 8.0)
			&"rooting":
				# The capture rules (MissionZone): ours alone = progress, both = frozen, nobody = decay; the enemy
				# alone re-rimes it as in a growing grove.
				var foes := _enemy_within(at, GROVE_R)
				var own := _own_within(at, GROVE_R) + (1 if hero_alive() and _flat(hero.global_position, at) <= GROVE_R else 0)
				if foes > 0:
					if own == 0:
						g["rime"] = float(g["rime"]) + dt
						if float(g["rime"]) >= rerime:
							g["state"] = &"thawed"
							g["meter"] = 0.0
							g["root"] = 0.0
							g["rime"] = 0.0
							if fire_once(&"E7"):
								say_l(10)
					continue
				g["rime"] = 0.0
				if own == 0:
					g["root"] = maxf(0.0, float(g["root"]) - ROOT_DECAY * dt)
					continue
				g["root"] = minf(1.0, float(g["root"]) + dt / ROOT_TIME)
				if float(g["root"]) >= 1.0:
					_grow(id)


## Planted: growing, rooting or grown.
static func _planted(g: Dictionary) -> bool:
	return g["state"] == &"growing" or g["state"] == &"rooting" or g["state"] == &"grown"


func _grow(id: StringName) -> void:
	var g: Dictionary = groves[id]
	g["state"] = &"grown"
	g["root"] = 0.0
	var heart := MissionGrove.new()
	heart.building_type = MissionGrove.make_type(HEART_HP, GROVE_R, SAP_STATS)
	heart.name = "GroveHeart_%s" % String(id)
	heart.team = Unit.Team.PLAYER
	heart.position = build_grid.snap(GROVES[id][1], heart.building_type.footprint)
	nav_region.add_child(heart, true)
	heart.destroyed.connect(_on_heart_destroyed.bind(id))
	g["heart"] = heart
	fog.reveal(Unit.Team.PLAYER, GROVES[id][1], 14.0)
	if fire_once(&"E4"):
		say_l(6)
		set_objective(&"sec_unbroken", "active")
		if hud:
			hud.show_message(HINT_GROWN, 8.0)
	if id == &"heartglade" and fire_once(&"E9"):
		say_l(12)
		say_l(13)
	if not bool(g["grown_once"]):
		g["grown_once"] = true
		grown_count += 1
		var wid := StringName("C%d" % mini(4, grown_count))
		after(COUNTER_DELAY, _fire_wave.bind(wid))
	set_objective(&"obj_groves", "active")
	if groves_grown() >= 5 and objective_state("obj_groves") == "active":
		_groves_done()


func _on_heart_destroyed(_b: Building, id: StringName) -> void:
	if is_ending():
		return
	var g: Dictionary = groves[id]
	g["state"] = &"thawed"
	g["meter"] = 0.0
	g["heart"] = null
	g["replant_at"] = mission_time() + REPLANT_AFTER
	lost_a_grove = true
	if fire_once(&"E7"):
		say_l(10)
	if objective_state("sec_unbroken") == "active":
		set_objective(&"sec_unbroken", "failed")


## E15: five grown at once: obj_hold (pauses under the minimum, never resets) and the Final.
func _groves_done() -> void:
	fire_once(&"E15")
	set_objective(&"obj_groves", "done")
	say_l(20)
	say_l(21)
	hold_left = float(by_difficulty(HOLD_TIME))
	set_objective(&"obj_hold", "active")
	_fire_wave(&"FINAL")


func _tick_hold(dt: float) -> void:
	if hold_left < 0.0 or objective_state("obj_hold") != "active":
		return
	hold_paused = groves_grown() < int(by_difficulty(HOLD_MIN))
	if hold_paused:
		return
	hold_left = maxf(0.0, hold_left - dt)
	if hold_left <= 0.0:
		_hold_done()


## E17: the wood answers: Withdraw, e4m3_spring, the Heartwood Seed, victory.
func _hold_done() -> void:
	fire_once(&"E17")
	victory_time = mission_time()
	set_objective(&"obj_hold", "done")
	if objective_state("sec_unbroken") == "active":
		set_objective(&"sec_unbroken", "done")
	if objective_state("sec_spire") == "active":
		set_objective(&"sec_spire", "failed")
	_record_flags()
	clear_waves()
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == ENEMY and not u.is_worker():
			set_truce([u], true, Unit.TRUCE_ALL)
			u.set_meta(META_MODE, &"withdraw")
			u.command_move(TORVALD_RALLY if u.global_position.x < 0.0 else ALDRA_RALLY)
	play_cutscene(&"e4m3_spring", func() -> void:
		for n in [25, 26, 27, 28]:
			say_l(n)
		set_objective(&"obj_ysolde", "done")
		win(VICTORY_DELAY))


func _record_flags() -> void:
	set_mission_flag("e4m3_time", int(victory_time))
	var bank := EssenceBank.for_team(Unit.Team.PLAYER)
	var essence := bank.essence if bank else 0
	if objective_state("sec_spire") == "done":
		essence += 300
	if objective_state("sec_unbroken") == "done":
		essence += 300
	set_mission_flag(CampaignState.YSOLDE_ESSENCE_FLAG, mini(ESSENCE_CAP, essence / 2))


func _on_spire_destroyed(_b: Building) -> void:
	if is_ending():
		return
	fire_once(&"E13")
	say_l(17)
	set_objective(&"sec_spire", "done")


func _on_torvald_died(_u: Unit) -> void:
	if is_ending():
		return
	if hud:
		hud.show_message(MSG_TORVALD_FELL, 4.0)
	after(TORVALD_BACK, func() -> void:
		if torvald and is_instance_valid(torvald) and not torvald.is_alive() and not is_ending():
			torvald.respawn(respawn_point(ENEMY))
			torvald.set_meta(META_MODE, &"anchor")
			torvald.command_move(TORVALD_RALLY))


func _on_player_hero_fell() -> void:
	fire_once(&"E18")
	say_l(29)
	set_objective(&"obj_ysolde", "failed")
	super()


func _tick_torvald() -> void:
	if torvald == null or not is_instance_valid(torvald) or not torvald.is_alive() or _wave_units.has(torvald):
		return
	if torvald.attack_target == null and _flat(torvald.global_position, TORVALD_RALLY) > 5.0 and not torvald.has_move_order():
		torvald.command_move(TORVALD_RALLY)


# ---------------------------------------------------------------- every frame

func _physics_process(delta: float) -> void:
	super(delta)
	if not match_started or game_over or world_is_held:
		return
	tick_scripted(delta)
	if is_ending():
		return
	_tick_aldra(delta)
	_tick_hold(delta)
	_tick -= delta
	if _tick <= 0.0:
		_tick_groves(0.5 - _tick)
		_tick = 0.5
		_tick_torvald()
		if maelis == null or not is_instance_valid(maelis):
			maelis = _find_maelis()
		var t := "%s|%s|%s" % [objective_text(&"obj_groves"), objective_text(&"obj_hold"), _grove_sig()]
		if t != _last_obj_text:
			_last_obj_text = t
			objectives_changed.emit()
			if hud and mission_hud == null:
				hud.set_objective(_objective_text())


func _grove_sig() -> String:
	var s := ""
	for id: StringName in groves:
		var g: Dictionary = groves[id]
		s += "%s%d%d," % [String(g["state"]).left(2), int(10.0 * float(g["meter"])), int(10.0 * float(g["root"]))]
	return s
