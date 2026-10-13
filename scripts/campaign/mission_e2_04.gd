class_name MissionE2_04
extends MissionBase
## Episode 2, mission 4 "Sunrise Road" (docs/design/mission-e2-04.md): the descent. Vessa, a small army and Old Vey (the
## helper, granted free at 0:00) walk down an underground road of three halls joined by galleries. The halls are dark
## (sight x 0.7; an enemy outside every light and farther than 6 m from the player's units cannot be auto-targeted),
## Vessa lights sunstones, wakes the Master's sleeping Ruin Wardens with Vey's storm (Sunwardens, team PLAYER) while
## Mother Hush's Splinter Acolytes wake them as enemies, claims the Warden Forge in Hall 2 (it becomes the player's keep,
## tier 2), researches at an Ember Forge (ForgeKit through `forge_enabled`: the spotlight), drives Mother Hush off in
## Hall 3 and opens the Sunrise Gate with Vey (a 45 s channel that pauses, W4 on top). 1 seat vs scripted enemies only.
##
## Built deviations (2026-10-06, recorded in the spec's "Built" note):
## - The map is built in code on an 80 x 160 MapInfo (no World Forge `sunrise_road.map` / `deep_stone` biome yet): the
##   halls / galleries / branches are the walkable shapes of the spec's table, everything else is rock (merged box
##   obstacles on a 2 m grid, baked into the navmesh). Lighting: the M0 night rig; the ground keeps the house shader.
## - Research = the Ember Forge's ForgeKit lines (`unit-spotlights.md` recommends it): `obj_research` = 2 Forge
##   researches (no Cinder Sanctum building exists); level 3 needs tier 3 so the tier-2 forge caps it.
## - The dark rule is mission-side: every 0.25 s an enemy outside every light zone with no player unit within 6 m is
##   hidden from auto-targeting (`Unit.hide_from_auto_target`) for 0.3 s; direct orders still hit it.
## - The Warden Forge is the Fire keep (`fire_keep` with the Warden Forge name and 2 800 HP) spawned at the claim; before
##   it a cold stone stands there. Mother Hush uses M00Cast (Blink, Smoke at 50 % = the mission's Night of Knives, flees
##   at 25 %). No cine timelines (fallback end states); no flooded-water slow; guides follow Vessa (no fog reveal rule).

const MISSION_ID := &"e2m4"
const MISSION_TITLE := "Sunrise Road"
const MAP_SIZE_X := 80.0
const MAP_SIZE_Z := 160.0
const CELL := 2.0
const WALL_HEIGHT := 3.5
const ROCK_COLOR := Color(0.12, 0.13, 0.16)

const VESSA_START := Vector3(0.0, 0.0, 66.0)
const VEY_START := Vector3(2.0, 0.0, 66.0)
const ARMY_POS := Vector3(0.0, 0.0, 61.0)
const STAIR_FOOT := Vector3(0.0, 0.0, 72.0)
const FORGE_POS := Vector3(0.0, 0.0, -4.0)
const FORGE_HP := 2800.0
const GATE_POS := Vector3(0.0, 0.0, -76.0)
const GATE_SPOT := Vector3(0.0, 0.0, -71.0)
const CAMP_SPAWN := Vector3(20.0, 0.0, -55.0)
const NORTH_TUNNEL := Vector3(23.0, 0.0, -76.0)
const HUSH_POS := Vector3(0.0, 0.0, -60.0)
const HALL2_Z := 20.0          ## Vessa in Hall 2 (z < 20): E7.
const GALLERY1_Z := 31.0       ## E6.
const HALL3_Z := -36.0         ## E15.
const G1_POS := Vector3(6.0, 0.0, 44.0)
const G3_POS := Vector3(16.0, 0.0, -54.0)
const G4_POS := Vector3(-33.0, 0.0, -10.0)
const NIGHT_SPIRE_POS := Vector3(18.0, 0.0, -50.0)
const TENT_SPOTS: Array[Vector3] = [Vector3(22.0, 0.0, -58.0), Vector3(12.0, 0.0, -60.0)]
const SPIRE_HP := 720.0
const TENT_HP := 500.0

## Walkable shapes (the spec's map table): [kind, a, b / radii, half width].
const SHAPES := [
	[&"seg", Vector3(0, 0, 58), Vector3(0, 0, 79), 3.5],         # the stair
	[&"circle", Vector3(0, 0, 64), 6.5],                          # the stair foot / start
	[&"ellipse", Vector3(0, 0, 48), Vector2(20, 16)],             # Hall 1 "Lantern Hall"
	[&"seg", Vector3(0, 0, 34), Vector3(0, 0, 18), 3.5],          # Gallery 1
	[&"circle", Vector3(-5, 0, 25), 2.6],                         # the G1n niche
	[&"ellipse", Vector3(0, 0, 0), Vector2(26, 20)],              # Hall 2 "The Warden Forge"
	[&"seg", Vector3(-22, 0, -2), Vector3(-31, 0, -9), 2.2],      # the Ash Seep crawl
	[&"circle", Vector3(-33, 0, -12), 6.0],                       # the Ash Seep
	[&"seg", Vector3(0, 0, -18), Vector3(0, 0, -37), 4.0],        # Gallery 2
	[&"seg", Vector3(8, 0, -17), Vector3(20, 0, -30), 2.2],       # the flooded branch
	[&"seg", Vector3(20, 0, -30), Vector3(16, 0, -40), 2.2],
	[&"ellipse", Vector3(0, 0, -54), Vector2(24, 20)],            # Hall 3 "The Sunrise Gate"
	[&"seg", Vector3(19, 0, -64), Vector3(23, 0, -77), 2.6],      # the north tunnel
]
const SUNSTONES := [
	[&"S1", Vector3(-12, 0, 52)], [&"S2", Vector3(12, 0, 42)], [&"S3", Vector3(-14, 0, -12)],
	[&"S4", Vector3(14, 0, -12)], [&"S5", Vector3(-14, 0, -46)], [&"S6", Vector3(10, 0, -66)],
]
const SLEEPERS := [
	[&"H1a", Vector3(-17, 0, 40)], [&"H1b", Vector3(17, 0, 54)], [&"H1c", Vector3(0, 0, 33)],
	[&"G1n", Vector3(-5, 0, 25)], [&"H2a", Vector3(-22, 0, 10)], [&"H2b", Vector3(22, 0, 10)],
	[&"H2c", Vector3(-10, 0, 16)], [&"H2d", Vector3(10, 0, 16)], [&"H3a", Vector3(-20, 0, -58)],
	[&"H3b", Vector3(-8, 0, -67)], [&"H3c", Vector3(6, 0, -42)], [&"H3d", Vector3(20, 0, -68)],
]
const W1_SLEEPERS: Array[StringName] = [&"H2a", &"H2b", &"H2c", &"H2d", &"G1n"]
const H3_SLEEPERS: Array[StringName] = [&"H3a", &"H3b", &"H3c", &"H3d"]
const VEINS := [[&"v1", Vector3(-17, 0, 8), 1500], [&"v2", Vector3(17, 0, 8), 1500], [&"v3", Vector3(-33, 0, -12), 1000]]

const STONE_LIGHT := 14.0
const FORGE_LIGHT := 18.0
const VESSA_LIGHT := 8.0
const FIREBALL_LIGHT := 6.0
const FIREBALL_LIGHT_S := 3.0
const LANTERN_LIGHT := 5.0
const DARK_TICK := 0.25
const WAKE_RANGE := 4.0
const WAKE_TIME := 3.0
const VEY_RANGE := 8.0
const STORM_AURA := 12.0
const STORM_DAMAGE := 4.0
const SUNWARDEN_MAX := 10
const ACOLYTE_RANGE := 3.0
const ACOLYTE_INTERRUPT := 20.0
const CLAIM_RANGE := 4.0
const CLAIM_TIME := 5.0
const CLAIM_CLEAR := 12.0
const GATE_RANGE := 4.0
const GATE_CLEAR := 10.0
const VEY_KNEEL_S := 10.0
const W1_AT := 330.0
const W2_AT := 540.0
const W3_AT := 720.0
const RACE_FIRST := 630.0
const RACE_EVERY := 90.0
const LATE_SPAWN_DELAY := 15.0
const DEFEAT_DELAY := 3.0
const VICTORY_DELAY := 2.0
const LEVEL_CAP := 8
const NO_SAVE_ESSENCE := 600
const WARDEN_GOAL := 8
const STONE_GOAL := 6
const RESEARCH_GOAL := 2
const KNIVES_STRIKES := 6
const KNIVES_DAMAGE := 40.0
const KNIVES_RANGE := 10.0
const COUNT_MULT: Array[float] = [0.6, 1.0, 1.4]
const START_CRYSTALS: Array[int] = [400, 300, 200]
const SIGHT: Array[float] = [0.85, 0.7, 0.6]
const DARK_RANGE: Array[float] = [8.0, 6.0, 5.0]
const SPLINTER_TIME: Array[float] = [4.0, 3.0, 2.0]
const HUSH_HP: Array[float] = [1000.0, 1400.0, 1800.0]
const GATE_TIME: Array[float] = [35.0, 45.0, 60.0]
const W4_WARDENS: Array[int] = [2, 4, 6]

const WAVES := {
	&"G1": [["shade", 4], ["nightbolt", 2]],
	&"G2": [["shade", 3], ["hexweaver", 1]],
	&"G3": [["shade", 4], ["nightbolt", 2], ["hexweaver", 1]],
	&"G4": [["grave_hound", 3]],
	&"W1": [["shade", 4], ["grave_hound", 2]],
	&"W2": [["shade", 4], ["nightbolt", 2], ["shadow_knight", 1]],
	&"W3": [["shade", 5], ["nightbolt", 3], ["shadow_knight", 1], ["gloom_deacon", 1]],
	&"RACE": [["shade", 2]],
	&"W4": [["shade", 6], ["nightbolt", 3], ["shadow_knight", 1]],
	&"W4K": [["shadow_knight", 2]],
}
const ACOLYTES := {&"W1": 1, &"W2": 2, &"RACE": 1}

const SPEAKER_COLORS := {
	&"vessa": Color(1.0, 0.45, 0.1), &"vey": Color(0.95, 0.95, 0.55), &"ashby": Color(0.95, 0.60, 0.35),
	&"hush": Color(0.60, 0.50, 0.75), &"malrik": Color(0.7, 0.3, 1.0), &"obren": Color(1.0, 0.80, 0.25),
	&"narrator": Color(0.9, 0.85, 0.7),
}
const SPEAKER_NAMES := {&"vessa": "Vessa", &"vey": "Old Vey", &"ashby": "Captain Ashby", &"hush": "Mother Hush",
		&"malrik": "Malrik", &"obren": "Obren", &"narrator": "Narrator"}
## L1-L33 (index n - 1), then L8b = 34, L21b = 35.
const DIALOGUE := [
	[&"narrator", "The Sunrise Road. The Master cut it before the kingdoms had names. No one has walked it since."],
	[&"vessa", "It's so dark. Good thing I'm the brightest person I know."],
	[&"vey", "Stay close to the light, girl. Down here the dark has teeth."],
	[&"vey", "Sunstones. He set them for the Wardens, so they'd always see him coming home."],
	[&"vessa", "There's a Warden in the wall. Asleep. Vey, the last ones I met tried to crush me."],
	[&"vey", "Those were Obren's, woken by Obren. These are the Master's. They know whose storm I carry."],
	[&"vey", "Up, old friend. Your master's walking again. Well. His sword is."],
	[&"vessa", "Shades, in the dark. Of course. They never pick a nice, sunny cave."],
	[&"ashby", "My queen! Work crew's on the stair. Find us a hearth to build around!"],
	[&"vessa", "A forge. He built forges down here? What was he making?"],
	[&"vey", "Wardens. Doors. Things that hold. He was always better at holding than letting go."],
	[&"malrik", "Hush. The old man is with her. Wake the stones before he does."],
	[&"vessa", "The hearth's lit. Ashby, it's yours. Make me things that hit harder."],
	[&"ashby", "A Master's forge! My grandad would weep. Then he'd charge you for it."],
	[&"ashby", "First batch out of the old forge, my queen! Blades that remember the fire."],
	[&"obren", "Wake, my masons. The Bishop's hand carries my heart. Obey it."],
	[&"vessa", "That voice again. I'd hoped we buried you."],
	[&"vey", "They're throwing everything at the forge. Hold the light, and they break on it."],
	[&"vey", "Two crafts mastered. Good. The gate won't open for a fool. Or so he told me."],
	[&"hush", "The little ember, in the dark. You're a long way from your braziers."],
	[&"vessa", "Mother Hush. You missed me once. I'd hate for you to get out of practice."],
	[&"hush", "Hush now. The dark only wants to be listened to."],
	[&"hush", "There is always another night, little ember. Another night."],
	[&"vey", "Here. Hand on the sun, girl. I'll give it the storm. Hold it with me."],
	[&"vessa", "It's warm. Vey, the door is WARM. Something's on the other side."],
	[&"narrator", "And for the first time in twelve years, the Sunrise Road saw its sunrise."],
	[&"vey", "He's down there. I can feel him. And he's tired, girl. So very tired."],
	[&"vessa", "Then we go faster. Wardens, with me. We're going to fetch the Master."],
	[&"malrik", "Go on, then. Run ahead. I'll be right behind you, with the key you lack."],
	[&"vey", "Eight of his Wardens, awake for you. He'd have liked that."],
	[&"vessa", "Every stone lit. I'll admit it, the Master had good taste in caves."],
	[&"vessa", "Vey... the light... it's going out..."],
	[&"ashby", "The forge is lost! The hearth's gone cold!"],
	[&"vessa", "Shades in the dark. I know that smoke. She ran from me once."],
	[&"vessa", "Mother Hush. Last time you ran. Want to try running a second time?"],
]
const BRIEFING_PARAGRAPHS: Array[String] = [
	"Under the Emberfall observatory a stair goes down, and down, past the last root and the last bat, into halls the Master cut before there were kingdoms. The Greywater guides call it the Sunrise Road. They do not say why.",
	"The Master's old Wardens sleep in the walls. Old Vey says they will know his storm. Mother Hush went down first, with a splinter of Malrik's stone, and the Wardens she wakes have amber eyes.",
	"Somewhere below there is a forge, and past it a gate. Vessa brought a small army, a big temper and the only light for a mile. Down here, that is the same thing.",
]
const BRIEFING_LINE := "The dark hides the enemy: light the sunstones, and keep Vessa close to the fight."
const HINT_DARK := "It's dark down here: the enemy hides beyond your light. Light the sunstones (stand Vessa beside one)."
const HINT_WAKE := "Wake a Warden: Vessa beside it for 3 s, with Old Vey close to her."
const HINT_NO_VEY := "The Warden sleeps. It answers only the Master's storm: bring Old Vey."
const HINT_CLEAR := "Clear the forge hall first"
const HINT_FORGE := "Build an Ember Forge (B then M) in this hall and research there twice."
const HINT_RESEARCH := "Research makes every unit better for the whole mission. Select the Ember Forge and pick an upgrade."
const HINT_ARMOR := "Ember Mail: your Guards take less."
const MSG_GATE_PAUSED := "The gate channel pauses"
const MSG_VEY_KNEELS := "Old Vey kneels: he will stand again"

## Test / menu switch (before the tree): campaign flags to use instead of the save ({} = read the save).
var flag_override: Dictionary = {}

## Read only.
var sunstones: Array[MissionBrazier] = []
var sleepers := {}                     ## id -> Unit (sleeping, dormant NEUTRAL) while it sleeps
var sunwardens: Array = []             ## living Sunwardens
var amber_wardens: Array = []          ## living amber Wardens
var wardens_woken := 0                 ## Sunwardens woken (dead ones count)
var stones_lit := 0
var researches := 0
var forge_claimed := false
var claim_progress := 0.0
var gate_progress := 0.0               ## 0-1
var gate_open := false
var gate_paused := false
var vey: Unit = null
var guides: Array = []
var ashby: Unit = null
var camp: Array = []                   ## the Night Spire and the 2 tents
var hush_cast: M00Cast = null
var hush_state: StringName = &""       ## "" not met, &"fight", &"fled", &"gone"
var no_save_fallback := false
var guard_groups := {}
var waves_fired: Array[StringName] = []
var wave_units := {}
var said: Array[int] = []
var light_zones: Array = []            ## [pos, radius] of this tick (tests read it)

var _flags_read := false
var _said := {}
var _tick := 0.0
var _dark_tick := 0.0
var _storm_wake := {}                        ## sleeper id -> progress (0-1) of Vessa's storm wake
var _amber_wake := {}                  ## acolyte instance id -> [sleeper id, progress]
var _flashes: Array = []               ## [pos, until mission time] (Fireball impacts)
var _vey_kneel_left := 0.0
var _rings := {}                       ## id -> MeshInstance3D
var _cold_forge: StaticBody3D
var _acolyte_type: UnitType
var _sunwarden_type: UnitType
var _amber_type: UnitType
var _forge_type: BuildingType
var _ashby_type: UnitType
var forge_pop_bonus := 0               ## Read only: the claim's extra pop (a save load gives it back)
var _no_vey_said := false
var _enemy_scan := {}                  ## "x,z,r" -> [count, mission time]: the claim / gate checks scan once per 0.25 s
const ENEMY_SCAN_EVERY := 0.25
var _clear_said := false
var _camp_gone_at := -1.0
var _w4_started := false
var _last_obj_text := ""


# ---------------------------------------------------------------- setup

func _init() -> void:
	super()
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
	define_objectives([[&"obj_forge", "primary"], [&"obj_research", "primary"], [&"obj_gate", "primary"],
			[&"obj_vessa", "primary"], [&"obj_hearth", "primary"], [&"sec_wardens", "secondary"],
			[&"sec_hush", "secondary"], [&"sec_sunstones", "secondary"]])


func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	c.mission_id = MISSION_ID
	c.title = MISSION_TITLE
	c.count_mult = COUNT_MULT.duplicate()
	c.defeat_on_keep_lost = false   # E23 is the mission's own
	c.tiers_enabled = true
	c.max_tier = 2
	c.bots_upgrade = false
	c.casters_enabled = true
	c.t3_enabled = false
	c.helpers_enabled = true
	c.forge_enabled = true
	c.cavalry_enabled = false
	c.start_level = 5
	c.start_spell_points = 4
	c.level_cap = LEVEL_CAP
	c.start_crystals = START_CRYSTALS.duplicate()
	c.instant_loss_on_wizard_death = true
	c.defeat_delay = DEFEAT_DELAY
	c.victory_banner = "VICTORY\nThe Sunrise Gate is open"
	c.defeat_banner = "DEFEAT"
	c.rewards = {"flags": {"e2m4_sunwardens": "sec_wardens", "e2m4_hush_driven": "sec_hush",
			"e2m4_road_lit": "sec_sunstones"}, "bonus_essence": {"sec_wardens": 300, "sec_hush": 150, "sec_sunstones": 150},
			"set_flags": {"e2m4_gate_open": true}, "next": &"e2m5"}
	c.spotlight = {"id": &"fire_forge", "trigger": &"unlock", "key_hint": "Cinder Hand: B then M",
			"card": "Ember Forge. Make every soldier better, for good: armour and steel for the long road down."}
	return c


func _map_size() -> Vector2:
	return Vector2(MAP_SIZE_X, MAP_SIZE_Z)


func _player_start() -> Vector3:
	return VESSA_START


func _use_map_dressing() -> bool:
	return false


func _lighting_preset() -> StringName:
	return &"warm"


func _title_line() -> String:
	return "Episode 2, Mission 4: %s" % MISSION_TITLE


## No keep healing until the forge is claimed (then the keep heals as usual).
func _home_healing(delta: float) -> void:
	if forge_claimed:
		super(delta)


func _ready() -> void:
	_acolyte_type = register_local_unit_type(_make_acolyte_type())
	_ashby_type = register_local_unit_type(_make_ashby_type())
	_sunwarden_type = _make_warden_type(true)
	_amber_type = _make_warden_type(false)
	_forge_type = _make_forge_type()
	super()
	if camera_rig:
		camera_rig.focus_on(VESSA_START)
	if fog and &"sight_scale" in fog:
		var scale: Array[float] = [float(by_difficulty(SIGHT)), 1.0]
		fog.set(&"sight_scale", scale)
	EmberfallNight.apply_to(self, EmberfallNight.night())


func _make_acolyte_type() -> UnitType:
	var base := UnitType.find("hexweaver")
	var t := (base.duplicate() as UnitType) if base else UnitType.new()
	t.id = &"splinter_acolyte"
	t.display_name = "Splinter Acolyte"
	t.max_hp = 85.0
	t.kill_xp = 60
	t.cost = 0
	t.pop = 0
	t.aggro_range = 0.0
	t.attack_damage = 0.0
	t.support_kind = &""
	t.commandable = false
	t.body_color = Color(0.95, 0.65, 0.2)
	return t


## Captain Ashby (the forge crew's story NPC): a Greywater Tracker look, not commandable, no attack, pop 0.
func _make_ashby_type() -> UnitType:
	var at := UnitType.find("greywater_tracker")
	if at == null:
		return null
	var t := at.duplicate() as UnitType
	t.id = &"ashby"
	t.display_name = "Captain Ashby"
	t.commandable = false
	t.attack_damage = 0.0
	t.aggro_range = 0.0
	t.pop = 0
	return t


func _make_warden_type(friend: bool) -> UnitType:
	var base := UnitType.find("ruin_warden")
	var t := (base.duplicate() as UnitType) if base else UnitType.new()
	t.display_name = "Sunwarden" if friend else "Amber Warden"
	t.pop = 0
	t.cost = 0
	t.commandable = friend
	t.eye_color = Color(1.0, 0.92, 0.65) if friend else Color(1.0, 0.55, 0.1)
	t.aggro_range = 9.0
	return t


## The Warden Forge: the Fire keep's type under its own name, 2 800 HP (tier 2 via set_start_tier at the claim).
func _make_forge_type() -> BuildingType:
	var base := BuildingType.find("fire_keep")
	if base == null:
		return null
	var t := base.duplicate() as BuildingType
	t.display_name = "Warden Forge"
	t.max_hp = FORGE_HP
	return t


# ---------------------------------------------------------------- the map

func _build_map() -> void:
	_read_flags()
	_build_cave()
	for row in SUNSTONES:
		var b := MissionBrazier.new()
		b.brazier_id = row[0]
		b.display_name = "Sunstone %s" % String(row[0])
		b.name = "Sunstone%s" % String(row[0])
		nav_region.add_child(b)
		b.position = row[1]
		b.lit_up.connect(_on_stone_lit)
		sunstones.append(b)
		register_actor("sunstone_%s" % String(row[0]), b)
	for row in VEINS:
		_add_crystal_node(StringName(row[0]), row[1], int(row[2]))
	_cold_forge = _static_obstacle(FORGE_POS, _box(Vector3(4.0, 1.6, 4.0)), 0.8)
	_cold_forge.name = "ColdWardenForge"
	_mesh(_cold_forge, _box_mesh(Vector3(4.0, 1.6, 4.0)), Color(0.32, 0.31, 0.30), 0.8)
	_add_gate_look()
	var spire := build_grid.spawn_complete(BuildingType.find("shadow_tower"), NIGHT_SPIRE_POS, Unit.Team.ENEMY)
	if spire:
		spire.max_hp = SPIRE_HP
		spire.hp = SPIRE_HP
		camp.append(spire)
	for p in TENT_SPOTS:
		var tent := build_grid.spawn_complete(BuildingType.find("shadow_hovel"), p, Unit.Team.ENEMY)
		if tent:
			tent.max_hp = TENT_HP
			tent.hp = TENT_HP
			camp.append(tent)
	for b: Variant in camp:
		mark_scripted(b as Node)
		(b as Building).destroyed.connect(_on_camp_destroyed)
	# main.gd's _ready focuses the camera on `keep` right after the map: a stand-in (never in the tree), dropped in
	# _on_navigation_ready (no keep until the forge claim).
	keep = Keep.new()
	keep.position = VESSA_START


## True when `p` is inside a walkable shape of the cave.
static func is_walkable(p: Vector3, margin := 0.0) -> bool:
	for s: Array in SHAPES:
		match s[0]:
			&"circle":
				if _flat(p, s[1]) <= float(s[2]) + margin:
					return true
			&"ellipse":
				var c: Vector3 = s[1]
				var r: Vector2 = s[2]
				var dx := (p.x - c.x) / (r.x + margin)
				var dz := (p.z - c.z) / (r.y + margin)
				if dx * dx + dz * dz <= 1.0:
					return true
			&"seg":
				if _seg_dist(p, s[1], s[2]) <= float(s[3]) + margin:
					return true
	for row in SLEEPERS:   # each sleeper's alcove
		if _flat(p, row[1]) <= 2.2 + margin:
			return true
	return false


static func _seg_dist(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab := Vector2(b.x - a.x, b.z - a.z)
	var ap := Vector2(p.x - a.x, p.z - a.z)
	var t := clampf(ap.dot(ab) / maxf(0.0001, ab.length_squared()), 0.0, 1.0)
	return (ap - ab * t).length()


## Rock everywhere outside the walkable shapes: one box per run of rock cells in each 2 m row.
func _build_cave() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = ROCK_COLOR
	mat.roughness = 0.95
	var hx := MAP_SIZE_X * 0.5
	var hz := MAP_SIZE_Z * 0.5
	var cols := int(MAP_SIZE_X / CELL)
	var rows := int(MAP_SIZE_Z / CELL)
	for r in rows:
		var z := -hz + CELL * (r + 0.5)
		var run_start := -1
		for c in cols + 1:
			var rock := false
			if c < cols:
				rock = not is_walkable(Vector3(-hx + CELL * (c + 0.5), 0.0, z))
			if rock and run_start < 0:
				run_start = c
			elif not rock and run_start >= 0:
				var x0 := -hx + CELL * run_start
				var x1 := -hx + CELL * c
				var size := Vector3(x1 - x0, WALL_HEIGHT, CELL)
				var body := _static_obstacle(Vector3((x0 + x1) * 0.5, 0.0, z), _box(size), WALL_HEIGHT * 0.5)
				body.add_to_group(&"navigation_geometry")
				if not _SIM.enabled:
					var mi := MeshInstance3D.new()
					mi.mesh = _box_mesh(size)
					mi.material_override = mat
					mi.position.y = WALL_HEIGHT * 0.5
					body.add_child(mi)
				run_start = -1


static func _box(size: Vector3) -> BoxShape3D:
	var s := BoxShape3D.new()
	s.size = size
	return s


static func _box_mesh(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


## The Sunrise Gate: a round white stone door in the north wall (placeholder look; opens = sinks into the floor).
var _gate_mesh: MeshInstance3D

func _add_gate_look() -> void:
	var disc := CylinderMesh.new()
	disc.top_radius = 4.5
	disc.bottom_radius = 4.5
	disc.height = 0.6
	_gate_mesh = MeshInstance3D.new()
	_gate_mesh.mesh = disc
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.92, 0.9, 0.82)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.92, 0.65)
	mat.emission_energy_multiplier = 0.3
	_gate_mesh.material_override = mat
	add_child(_gate_mesh)
	_gate_mesh.position = GATE_POS + Vector3(0.0, 4.5, 1.5)
	_gate_mesh.rotation.x = PI * 0.5


func _read_flags() -> void:
	if _flags_read:
		return
	_flags_read = true
	if not flag_override.is_empty():
		return
	no_save_fallback = not CampaignState.open(campaign_save_path).is_completed(&"e2m3")


func _flag(name: StringName) -> bool:
	_read_flags()
	if not flag_override.is_empty():
		return bool(flag_override.get(String(name), flag_override.get(name, false)))
	if no_save_fallback:
		return name == &"e2m3_lodge_paid"
	var v: Variant = CampaignState.open(campaign_save_path).flag_value(String(name), false)
	return v == true or (v is int and int(v) != 0)


# ---------------------------------------------------------------- start state

func _on_navigation_ready() -> void:
	if keep != null and not keep.is_inside_tree():
		keep.free()
	keep = null
	var diff := clampi(mission_difficulty, 0, 2)
	_setup_champions()   # the companion's guild; taverns closed
	hero = _make_wizard(Unit.Team.PLAYER)
	_spawn(hero, Unit.Team.PLAYER, VESSA_START)
	_claim_wizard(hero, Unit.Team.PLAYER)
	ItemDrops.ensure_inventory(hero)
	_apply_campaign_start()
	if hero.has_signal(&"spell_hit"):
		hero.spell_hit.connect(_on_spell_hit)
	for b in sunstones:
		b.lighter = hero
	var rows := [["flame_guard", 6 + (2 if diff == 0 else 0)], ["ember_archer", 4], ["pyre_adept", 0 if diff == 2 else 2],
			["kilnwarden", 1]]
	var army: Array[String] = []
	for row in rows:
		for k in int(row[1]):
			army.append(String(row[0]))
	for i in army.size():
		_spawn(make_unit(army[i]), Unit.Team.PLAYER, ARMY_POS + Vector3(-4.5 + (i % 6) * 1.6, 0.0, -1.0 + (i / 6) * 1.7))
	_spawn_guides()
	for row in SLEEPERS:
		_add_sleeper(StringName(row[0]), row[1])
	guard_groups[&"G1"] = spawn_group(WAVES[&"G1"], G1_POS, 2.5, Unit.Team.ENEMY, true)
	var g2 := spawn_group(WAVES[&"G2"], FORGE_POS, 6.0, Unit.Team.ENEMY, true, true)
	for i in 2:
		var a := float(i) * PI + 0.6
		var w := _spawn_warden(false, FORGE_POS + Vector3(cos(a) * 6.0, 0.0, sin(a) * 6.0))
		w.set_meta(META_HOME, w.global_position)
		_guards.append(w)
		g2.append(w)
	guard_groups[&"G2"] = g2
	guard_groups[&"G3"] = spawn_group(WAVES[&"G3"], G3_POS, 6.0, Unit.Team.ENEMY, true, true)
	guard_groups[&"G4"] = spawn_group(WAVES[&"G4"], G4_POS, 2.0, Unit.Team.ENEMY, true)
	_add_events()
	begin_mission([&"obj_forge", &"obj_vessa", &"sec_wardens", &"sec_sunstones"])
	_grant_vey()


func _apply_campaign_start() -> void:
	_read_flags()
	if no_save_fallback or not flag_override.is_empty():
		set_meta(&"campaign_flags", flag_override.duplicate())
		force_artifacts(hero, ["ember_crown", "masters_signet"])
		if no_save_fallback:
			var bank := EssenceBank.for_team(Unit.Team.PLAYER)
			if bank:
				bank.add(NO_SAVE_ESSENCE)
		return
	CampaignState.open(campaign_save_path).apply_to_start(self)


## D4: Old Vey on the field from 0:00 (granted free), Escort; he cannot fall before the claim (kneels 10 s at 1 HP).
func _grant_vey() -> void:
	var roster := HelperRoster.for_team(Unit.Team.PLAYER)
	if roster == null:
		return
	vey = roster.grant(VEY_START)
	if vey == null:
		vey = roster.helper
	if vey:
		vey.death_guard = _vey_guard


func _vey_guard(_attacker: Variant) -> bool:
	if forge_claimed or vey == null or not is_instance_valid(vey):
		return false
	vey.hp = 1.0
	if _vey_kneel_left <= 0.0:
		_vey_kneel_left = VEY_KNEEL_S
		vey.command_stop()
		vey.hide_from_auto_target(VEY_KNEEL_S)
		if vey.has_method(&"set_untargetable"):
			vey.call(&"set_untargetable", VEY_KNEEL_S)
		if hud:
			hud.show_message(MSG_VEY_KNEELS, 3.0)
	return true


## The Greywater guides (2, or 3 with e2m3_magpies_hunted): not commandable, lanterns r 5.
func _spawn_guides() -> void:
	var t := UnitType.find("greywater_tracker")
	if t == null:
		return
	var gt := t.duplicate() as UnitType
	gt.commandable = false
	gt.pop = 0
	var n := 3 if _flag(&"e2m3_magpies_hunted") else 2
	for i in n:
		var g := _spawn(Worker.make_unit(gt), Unit.Team.PLAYER, VESSA_START + Vector3(-2.0 + i * 2.0, 0.0, -3.0))
		g.add_to_group(&"story_units")
		guides.append(g)


func _add_sleeper(id: StringName, at: Vector3) -> void:
	var t := UnitType.find("ruin_warden")
	if t == null:
		return
	var u := _spawn(Worker.make_unit(t), Unit.Team.NEUTRAL, at)
	u.set_meta(&"e2m4_sleeper", id)
	mark_scripted(u)
	set_dormant(u, true)
	sleepers[id] = u
	_storm_wake[id] = 0.0


func _spawn_warden(friend: bool, at: Vector3) -> Unit:
	var u := _spawn(Worker.make_unit(_sunwarden_type if friend else _amber_type),
			Unit.Team.PLAYER if friend else Unit.Team.ENEMY, at)
	if friend:
		sunwardens.append(u)
	else:
		mark_scripted(u)
		amber_wardens.append(u)
	return u


# ---------------------------------------------------------------- briefing, objectives, lines

func briefing() -> Dictionary:
	return {
		"title": _title_line(),
		"paragraphs": BRIEFING_PARAGRAPHS.duplicate(),
		"objectives": [objective_text(&"obj_forge", false), objective_text(&"obj_research", false),
				objective_text(&"obj_gate", false), BRIEFING_LINE],
		"rule": Loc.sink(objective_text(&"obj_vessa")),
	}


func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_forge":
			return "Reach the Warden Forge and light its hearth"
		&"obj_research":
			if with_counter:
				return "Research twice at the Ember Forge (%d / 2)" % mini(researches, RESEARCH_GOAL)
			return "Research twice at the Ember Forge"
		&"obj_gate":
			if with_counter:
				if gate_paused and gate_progress > 0.0:
					return "Open the Sunrise Gate: Vessa and Old Vey together (%d %%, paused)" % int(gate_progress * 100.0)
				return "Open the Sunrise Gate: Vessa and Old Vey together (%d %%)" % int(gate_progress * 100.0)
			return "Open the Sunrise Gate: Vessa and Old Vey together"
		&"obj_vessa":
			return "Vessa must survive"
		&"obj_hearth":
			return "The Warden Forge must stand"
		&"sec_wardens":
			if with_counter:
				return "Wake the Master's Wardens with the storm (%d / 8)" % mini(wardens_woken, WARDEN_GOAL)
			return "Wake the Master's Wardens with the storm"
		&"sec_hush":
			return "Drive off Mother Hush"
		&"sec_sunstones":
			if with_counter:
				return "Light every sunstone (%d / 6)" % stones_lit
			return "Light every sunstone"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_research":
			return {"progress": mini(researches, RESEARCH_GOAL), "goal": RESEARCH_GOAL}
		&"obj_gate":
			return {"progress": int(gate_progress * 100.0), "goal": 100, "position": GATE_SPOT}
		&"sec_wardens":
			return {"progress": mini(wardens_woken, WARDEN_GOAL), "goal": WARDEN_GOAL}
		&"sec_sunstones":
			return {"progress": stones_lit, "goal": STONE_GOAL}
		&"obj_forge":
			return {"position": FORGE_POS}
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
	play_cutscene(&"e2m4_descent", func() -> void:
		if camera_rig and hero_alive():
			camera_rig.focus_on(hero.global_position)
		say_l(1)
		say_l(2)
		say_l(3)
		if hud:
			hud.show_message(HINT_DARK, 10.0))


func _add_events() -> void:
	add_event(&"E3", func() -> bool:
		for id: StringName in [&"H1a", &"H1b", &"H1c"]:
			var s: Variant = sleepers.get(id)
			if s != null and is_instance_valid(s) and hero_alive() and _flat(hero.global_position, (s as Node3D).global_position) <= 10.0:
				return true
		return false, func() -> void:
			say_l(5)
			say_l(6)
			if hud:
				hud.show_message(HINT_WAKE, 8.0))
	add_event(&"E5", func() -> bool:
		for u: Variant in guard_groups.get(&"G1", []):
			if is_instance_valid(u) and (u as Unit).is_alive() and hero_alive() \
					and _flat((u as Unit).global_position, hero.global_position) <= 14.0:
				return true
		return false, func() -> void: say_l(34 if _flag(&"m0_hush_driven") else 8))
	add_event(&"E6", func() -> bool: return hero_alive() and hero.global_position.z < GALLERY1_Z, func() -> void: say_l(9))
	add_event(&"E7", func() -> bool: return hero_alive() and hero.global_position.z < HALL2_Z, func() -> void:
		say_l(10)
		say_l(11))
	add_event(&"E15", func() -> bool: return hero_alive() and hero.global_position.z < HALL3_Z, _meet_hush)
	after(W1_AT, _fire_wave.bind(&"W1"))
	after(W2_AT, _fire_wave.bind(&"W2"))
	after(W3_AT, _fire_wave.bind(&"W3"))
	after(RACE_FIRST, _hall3_race)


func _on_stone_lit(_b: MissionBrazier) -> void:
	if is_ending():
		return
	stones_lit += 1
	if fire_once(&"E2"):
		say_l(4)
	set_objective(&"sec_sunstones", "active")
	if stones_lit >= STONE_GOAL and fire_once(&"E21b"):
		say_l(31)
		set_objective(&"sec_sunstones", "done")


func _on_spell_hit(target: Node3D, _amount: float, spell_id: StringName) -> void:
	if spell_id == &"fireball" and target != null and is_instance_valid(target):
		_flashes.append([target.global_position, mission_time() + FIREBALL_LIGHT_S])


# ---------------------------------------------------------------- lights and the dark

## The light circles now: lit sunstones, the claimed forge, Vessa, Fireball impacts, the guides' lanterns.
func light_circles() -> Array:
	var out: Array = []
	for b in sunstones:
		if b.lit:
			out.append([b.global_position, STONE_LIGHT])
	if forge_claimed and keep != null and is_instance_valid(keep) and keep.is_alive():
		out.append([keep.global_position, FORGE_LIGHT])
	if hero_alive():
		out.append([hero.global_position, VESSA_LIGHT])
	var now := mission_time()
	_flashes = _flashes.filter(func(f: Array) -> bool: return float(f[1]) > now)
	for f: Array in _flashes:
		out.append([f[0], FIREBALL_LIGHT])
	for g: Variant in guides:
		if is_instance_valid(g) and (g as Unit).is_alive():
			out.append([(g as Unit).global_position, LANTERN_LIGHT])
	return out


func in_light(p: Vector3) -> bool:
	for c: Array in light_zones:
		if _flat(p, c[0]) <= float(c[1]):
			return true
	return false


## D7: an enemy outside every light and farther than the dark range from every player unit is hidden from auto-targets.
func _tick_dark() -> void:
	light_zones = light_circles()
	var near := float(by_difficulty(DARK_RANGE))
	var friends: Array[Vector3] = []
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == Unit.Team.PLAYER:
			friends.append(u.global_position)
	for n in get_tree().get_nodes_in_group(&"units"):
		var e := n as Unit
		if e == null or not e.is_alive() or int(e.team) != Unit.Team.ENEMY:
			continue
		var p := e.global_position
		if in_light(p):
			continue
		var close := false
		for f in friends:
			if _flat(f, p) <= near:
				close = true
				break
		if not close:
			e.hide_from_auto_target(DARK_TICK + 0.05)


# ---------------------------------------------------------------- the Wardens

func _vey_up() -> bool:
	return vey != null and is_instance_valid(vey) and vey.is_alive() and _vey_kneel_left <= 0.0


func _vey_near_vessa() -> bool:
	return _vey_up() and hero_alive() and _flat(vey.global_position, hero.global_position) <= VEY_RANGE


## Vessa's storm wake: within 4 m of a sleeper for 3 s with Vey within 8 m of her.
func _tick_wake(delta: float) -> void:
	if not hero_alive():
		return
	var room := -1   # Sunwarden room, counted once per frame and only when Vessa is by a sleeper
	for id: Variant in sleepers.keys():
		var s := sleepers[id] as Unit
		if s == null or not is_instance_valid(s):
			continue
		var close := _flat(hero.global_position, s.global_position) <= WAKE_RANGE
		var p: float = _storm_wake.get(id, 0.0)
		if close and room < 0:
			room = 1 if _sunwarden_count() < SUNWARDEN_MAX else 0
		if close and _vey_near_vessa() and room == 1:
			p = minf(1.0, p + delta / WAKE_TIME)
			_ring(StringName(id), s.global_position, p, Color(1.0, 0.92, 0.6, 0.6))
			if p >= 1.0:
				_wake_sleeper(StringName(id), true)
				continue
		else:
			if close and not _vey_near_vessa() and not _no_vey_said and hud:
				_no_vey_said = true
				hud.show_message(HINT_NO_VEY, 4.0)
			p = 0.0
			_ring(StringName(id), s.global_position, 0.0, Color.WHITE)
		_storm_wake[id] = p


func _sunwarden_count() -> int:
	sunwardens = sunwardens.filter(func(u: Variant) -> bool: return is_instance_valid(u) and (u as Unit).is_alive())
	return sunwardens.size()


## The sleeper `id` wakes: a Sunwarden (team PLAYER) or an amber Warden (team ENEMY). Returns the new unit.
func _wake_sleeper(id: StringName, friend: bool) -> Unit:
	var s: Variant = sleepers.get(id)
	if s == null or not is_instance_valid(s):
		return null
	var at := (s as Unit).global_position
	sleepers.erase(id)
	_storm_wake.erase(id)
	_ring(id, at, 0.0, Color.WHITE)
	(s as Unit).leave_map()
	var u := _spawn_warden(friend, at)
	flash_ring(at, 2.5)
	if friend:
		wardens_woken += 1
		set_objective(&"sec_wardens", "active")
		if fire_once(&"E4"):
			play_cutscene(&"e2m4_first_warden", func() -> void: say_l(7))
		if wardens_woken >= WARDEN_GOAL and fire_once(&"E21a"):
			say_l(30)
			set_objective(&"sec_wardens", "done")
	elif fire_once(&"E12"):
		say_l(16)
		say_l(17)
	return u


## Sunwardens hit +4 within 12 m of Old Vey (modifier aura:storm).
func _tick_storm_aura() -> void:
	for w: Variant in sunwardens:
		if not is_instance_valid(w) or not (w as Unit).is_alive():
			continue
		var u := w as Unit
		var on := _vey_up() and _flat(u.global_position, vey.global_position) <= STORM_AURA
		if on and not u.has_meta(&"e2m4_storm"):
			u.add_modifier(&"aura:storm", {"attack_damage": STORM_DAMAGE})
			u.set_meta(&"e2m4_storm", true)
		elif not on and u.has_meta(&"e2m4_storm"):
			u.remove_modifier(&"aura:storm")
			u.remove_meta(&"e2m4_storm")


func _spawn_acolyte(at: Vector3, targets: Array[StringName]) -> Unit:
	var u := _spawn(Worker.make_unit(_acolyte_type), Unit.Team.ENEMY, at)
	mark_scripted(u)
	u.set_meta(&"e2m4_targets", targets)
	_hook_acolyte(u)
	order_wave(u, &"acolyte", at)
	return u


func _hook_acolyte(u: Unit) -> void:
	var c := _on_acolyte_hit.bind(u)
	if not u.damage_taken.is_connected(c):
		u.damage_taken.connect(c)


func _on_acolyte_hit(amount: float, _attacker: Node3D, u: Unit) -> void:
	if amount >= ACOLYTE_INTERRUPT and _amber_wake.has(u.get_instance_id()):
		(_amber_wake[u.get_instance_id()] as Array)[1] = 0.0


## The nearest sleeping Warden of `ids` to `from` (&"" = none).
func _nearest_sleeper(from: Vector3, ids: Array) -> StringName:
	var best := &""
	var best_d := INF
	for id: Variant in ids:
		var s: Variant = sleepers.get(id)
		if s == null or not is_instance_valid(s):
			continue
		var d := _flat((s as Node3D).global_position, from)
		if d < best_d:
			best_d = d
			best = StringName(id)
	return best


func _tick_acolytes(delta: float) -> void:
	var t: float = float(by_difficulty(SPLINTER_TIME))
	for w: Variant in _wave_units.duplicate():
		if not is_instance_valid(w) or not (w as Unit).is_alive():
			continue
		var u := w as Unit
		if u.get_meta(META_MODE, &"") != &"acolyte":
			continue
		var targets: Array = u.get_meta(&"e2m4_targets", [])
		var key := u.get_instance_id()
		var id := _nearest_sleeper(u.global_position, targets)
		if id == &"":
			_amber_wake.erase(key)
			u.set_meta(META_MODE, &"after")
			continue
		var s := sleepers[id] as Unit
		if _flat(u.global_position, s.global_position) > ACOLYTE_RANGE:
			if not u.has_move_order():
				u.command_move(s.global_position)
			continue
		u.command_stop()
		var row: Array = _amber_wake.get(key, [id, 0.0])
		if row[0] != id:
			row = [id, 0.0]
		row[1] = float(row[1]) + delta / t
		_amber_wake[key] = row
		_ring(StringName("amber_%d" % key), s.global_position, float(row[1]), Color(1.0, 0.55, 0.1, 0.6))
		if float(row[1]) >= 1.0:
			_amber_wake.erase(key)
			_ring(StringName("amber_%d" % key), s.global_position, 0.0, Color.WHITE)
			var amber := _wake_sleeper(id, false)
			var wave: StringName = u.get_meta(&"e2m4_wave", &"")
			if amber:
				if wave == &"RACE":
					amber.set_meta(META_HOME, CAMP_SPAWN)
					_guards.append(amber)
				else:
					order_wave(amber, &"forge", _forge_or_hero())
					if wave_units.has(wave):
						(wave_units[wave] as Array).append(amber)


## A ground progress disc for a channel (`p` 0 = hidden).
func _ring(id: StringName, at: Vector3, p: float, color: Color) -> void:
	var mi: MeshInstance3D = _rings.get(id)
	if p <= 0.0:
		if mi and is_instance_valid(mi):
			mi.visible = false
		return
	if mi == null or not is_instance_valid(mi):
		var disc := CylinderMesh.new()
		disc.top_radius = 1.0
		disc.bottom_radius = 1.0
		disc.height = 0.04
		disc.radial_segments = 32
		mi = MeshInstance3D.new()
		mi.mesh = disc
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mi.material_override = mat
		add_child(mi)
		_rings[id] = mi
	mi.visible = true
	(mi.material_override as StandardMaterial3D).albedo_color = color
	mi.global_position = at + Vector3(0.0, 0.08, 0.0)
	var r := maxf(0.2, p * 3.0)
	mi.scale = Vector3(r, 1.0, r)


# ---------------------------------------------------------------- the forge

## _enemies_within, re-scanned at most every ENEMY_SCAN_EVERY s per spot (the claim and gate ticks run every frame).
func _enemies_within_cached(at: Vector3, r: float) -> int:
	var key := "%d,%d,%d" % [int(at.x), int(at.z), int(r * 10.0)]
	var now := mission_time()
	var hit: Variant = _enemy_scan.get(key)
	if hit != null and now >= float(hit[1]) and now - float(hit[1]) < ENEMY_SCAN_EVERY:
		return int(hit[0])
	var n := _enemies_within(at, r)
	_enemy_scan[key] = [n, now]
	return n


func _enemies_within(at: Vector3, r: float) -> int:
	var n := 0
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u and u.is_alive() and int(u.team) == Unit.Team.ENEMY and _flat(u.global_position, at) <= r:
			n += 1
	return n


func _tick_claim(delta: float) -> void:
	if forge_claimed or not hero_alive():
		return
	var close := _flat(hero.global_position, FORGE_POS) <= CLAIM_RANGE + 2.0
	if not close:
		claim_progress = 0.0
		_ring(&"forge", FORGE_POS, 0.0, Color.WHITE)
		return
	if _enemies_within_cached(FORGE_POS, CLAIM_CLEAR) > 0:
		if not _clear_said and hud:
			_clear_said = true
			hud.show_message(HINT_CLEAR, 4.0)
		_ring(&"forge", FORGE_POS, maxf(claim_progress, 0.05), Color(0.5, 0.5, 0.5, 0.5))
		return
	claim_progress = minf(1.0, claim_progress + delta / CLAIM_TIME)
	_ring(&"forge", FORGE_POS, claim_progress, Color(1.0, 0.55, 0.15, 0.6))
	if claim_progress >= 1.0:
		_claim_forge()


## E9: the forge turns PLAYER (the keep, tier 2), the crew comes down, obj_research / obj_gate / obj_hearth.
func claim_forge() -> void:
	_claim_forge()


func _claim_forge() -> void:
	if forge_claimed:
		return
	forge_claimed = true
	claim_progress = 1.0
	_ring(&"forge", FORGE_POS, 0.0, Color.WHITE)
	_remove_cold_forge()
	var k := build_grid.spawn_complete(_forge_type, FORGE_POS, Unit.Team.PLAYER) as Keep
	if k:
		k.name = "WardenForge"
		keep = k
		k.set_start_tier(2)
		k.max_hp = FORGE_HP   # after the tier (its HP table)
		k.hp = FORGE_HP
		k.set_rally_point(FORGE_POS + Vector3(0.0, 0.0, 6.0))
	var eco := Economy.for_team(Unit.Team.PLAYER)
	if eco and eco.pop_cap - eco.pop_used < 6:
		forge_pop_bonus = eco.pop_used + 6 - eco.pop_cap
		eco.add_pop_bonus(forge_pop_bonus)
	flash_ring(FORGE_POS, 6.0)
	fire_once(&"E9")
	set_objective(&"obj_forge", "done")
	play_cutscene(&"e2m4_forge", func() -> void:
		say_l(13)
		say_l(14))
	for i in 4:
		var w := _spawn(make_unit("cinder_hand"), Unit.Team.PLAYER, STAIR_FOOT + Vector3(-3.0 + i * 2.0, 0.0, 0.0))
		w.call(&"command_gather", crystal_nodes.get(&"v1" if i < 2 else &"v2"))
	if _ashby_type:
		ashby = _spawn(Worker.make_unit(_ashby_type), Unit.Team.PLAYER, STAIR_FOOT)
		set_dormant(ashby, true)
		ashby.command_move(FORGE_POS + Vector3(4.0, 0.0, 4.0))
	set_objective(&"obj_research", "active")
	set_objective(&"obj_gate", "active")
	set_objective(&"obj_hearth", "active")
	if hud:
		hud.show_message(HINT_FORGE, 10.0)
	show_spotlight()
	_apply_forge()


## Idempotent part of the forge claim (the claim and a save load): `keep` is the Warden Forge, its destroyed hook
## (obj_hearth), Vey's kneel guard off, the research hook (obj_research -> the gate), E10.
func _apply_forge() -> void:
	if keep == null or not is_instance_valid(keep):
		for b in Building.for_team(Unit.Team.PLAYER):
			if b is Keep and b.is_alive():
				keep = b as Keep
				break
	if keep and is_instance_valid(keep):
		keep.name = "WardenForge"
		if _forge_type and keep.building_type != _forge_type and keep.building_type \
				and keep.building_type.id == _forge_type.id:
			keep.building_type = _forge_type   # "Warden Forge" (same kind / look / pop as the Fire keep it copies)
		if not keep.destroyed.is_connected(_on_forge_destroyed):
			keep.destroyed.connect(_on_forge_destroyed)
	if vey and is_instance_valid(vey):
		vey.death_guard = Callable()
	var fk := ForgeKit.for_team(Unit.Team.PLAYER)
	if fk and not fk.research_completed.is_connected(_on_research):
		fk.research_completed.connect(_on_research)
	_add_e10()


## E10 (once): the first finished Ember Forge -> the research hint.
func _add_e10() -> void:
	if has_fired(&"E10"):
		return
	for e: Array in _events:
		if StringName(e[0]) == &"E10":
			return
	add_event(&"E10", func() -> bool:
		for b in Building.for_team(Unit.Team.PLAYER):
			if b.is_alive() and b.is_constructed() and b.building_type and b.building_type.kind == &"forge":
				return true
		return false, func() -> void:
			if hud:
				hud.show_message(HINT_RESEARCH, 10.0))


func _on_research(line: StringName, _level: int) -> void:
	if is_ending():
		return
	researches += 1
	if fire_once(&"E11"):
		say_l(15)
	if line == &"armor" and fire_once(&"spot_moment") and hud:
		hud.show_message(HINT_ARMOR, 6.0)
	set_objective(&"obj_research", "active")
	if researches >= RESEARCH_GOAL and objective_state("obj_research") == "active":
		set_objective(&"obj_research", "done")
		fire_once(&"E14")
		say_l(19)
		if _gate_mesh:
			(_gate_mesh.material_override as StandardMaterial3D).emission_energy_multiplier = 1.2


# ---------------------------------------------------------------- waves

func _forge_or_hero() -> Vector3:
	if forge_claimed and keep != null and is_instance_valid(keep) and keep.is_alive():
		return keep.global_position
	return FORGE_POS if not forge_claimed else hero_pos()


func camp_standing() -> bool:
	for b: Variant in camp:
		if is_instance_valid(b) and (b as Building).is_alive():
			return true
	return false


func _wave_spawn() -> Vector3:
	return CAMP_SPAWN if camp_standing() or _camp_gone_at < 0.0 else NORTH_TUNNEL


func _fire_wave(id: StringName) -> void:
	if is_ending() or gate_open or waves_fired.has(id):
		return
	waves_fired.append(id)
	var at := _wave_spawn()
	var diff := clampi(mission_difficulty, 0, 2)
	var rows: Array = []
	for row: Array in WAVES[id]:
		if diff == 0 and String(row[0]) == "shadow_knight":
			continue
		rows.append(row)
	var units := spawn_wave_at(rows, at)
	for u in units:
		order_wave(u as Unit, &"escort", _forge_or_hero())
	var acolytes: Array = []
	for i in int(ACOLYTES.get(id, 0)):
		var a := _spawn_acolyte(at + Vector3(i * 1.5, 0.0, 1.5), W1_SLEEPERS)
		a.set_meta(&"e2m4_wave", id)
		acolytes.append(a)
	units.append_array(acolytes)
	wave_units[id] = units
	match id:
		&"W1":
			fire_once(&"E8")
			say_l(12)
		&"W3":
			say_l(18)


## Every 90 s from 10:30 while an H3 sleeper sleeps and the camp stands: 1 acolyte + 2 Shades for the nearest one.
func _hall3_race() -> void:
	if is_ending() or gate_open or not camp_standing():
		return
	if _nearest_sleeper(CAMP_SPAWN, H3_SLEEPERS) == &"":
		return
	after(RACE_EVERY, _hall3_race)
	var a := _spawn_acolyte(CAMP_SPAWN, H3_SLEEPERS)
	a.set_meta(&"e2m4_wave", &"RACE")
	for u in spawn_wave_at(WAVES[&"RACE"], CAMP_SPAWN):
		(u as Unit).set_meta(META_HOME, CAMP_SPAWN)
		_guards.append(u)


func _refresh_wave_unit(u: Unit, mode: StringName, hero_at: Vector3) -> bool:
	match mode:
		&"acolyte":
			return true   # _tick_acolytes drives it
		&"after":
			u.set_meta(META_MODE, &"forge")
			return true
		&"escort":
			# The wave walks with its acolyte(s) until they are done, then the forge.
			var lead: Unit = null
			for a: Variant in _wave_units:
				if is_instance_valid(a) and (a as Unit).is_alive() and (a as Unit).get_meta(META_MODE, &"") == &"acolyte":
					lead = a as Unit
					break
			if lead and u.attack_target == null:
				if _flat(u.global_position, lead.global_position) > 5.0:
					u.command_attack_move(lead.global_position)
				return true
			u.set_meta(META_MODE, &"forge")
			return true
		&"forge":
			if u.attack_target == null and not u.is_attack_moving():
				var to := _forge_or_hero()
				if forge_claimed and keep != null and is_instance_valid(keep) and keep.is_alive() \
						and _flat(u.global_position, to) <= 10.0:
					u.command_attack(keep)
				elif _flat(u.global_position, to) > 4.0:
					u.command_attack_move(to)
				else:
					u.set_meta(META_MODE, &"hero")
			return true
		&"vessa":
			if u.attack_target == null or not u.attack_target is Unit:
				u.command_attack_move(hero_at)
			return true
		&"withdraw":
			return true
	return false


func _on_camp_destroyed(_b: Building) -> void:
	if camp_standing() or _camp_gone_at >= 0.0:
		return
	_camp_gone_at = mission_time()


# ---------------------------------------------------------------- Mother Hush

## E15: Vessa enters Hall 3: Hush steps out of the smoke (M00Cast kit with the e2m4 HP); sec_hush.
func _meet_hush() -> void:
	if hush_state != &"":
		return
	_spawn_hush(HUSH_POS, 1.0)
	set_objective(&"sec_hush", "active")
	play_cutscene(&"e2m4_hush", func() -> void:
		say_l(20)
		say_l(35 if _flag(&"m0_hush_driven") else 21))


func _spawn_hush(at: Vector3, hp_pct: float) -> void:
	if hush_cast == null:
		_make_hush_cast()
	var h := _spawn(make_unit("mother_hush"), Unit.Team.ENEMY, at)
	mark_scripted(h)
	hush_cast.bind_hush(h)
	h.set_base_stat(&"max_hp", float(by_difficulty(HUSH_HP)))
	h.hp = h.max_hp * hp_pct
	hush_state = &"fight"
	order_wave(h, &"vessa", hero_pos())


## Hush's kit node (mission actor "cast": a save brings her phase back through M00Cast.load_row).
func _make_hush_cast() -> M00Cast:
	hush_cast = M00Cast.new()
	hush_cast.setup(self, mission_difficulty)
	add_child(hush_cast)
	hush_cast.hush_smoked.connect(_on_hush_knives)
	hush_cast.hush_fled.connect(_on_hush_fled)
	register_actor("cast", hush_cast)
	return hush_cast


## E16 at 50 % (M00Cast's Smoke): Night of Knives, 6 strikes on units within 10 m (not on easy).
func _on_hush_knives() -> void:
	if is_ending():
		return
	say_l(22)
	if clampi(mission_difficulty, 0, 2) == 0 or hush_cast == null or hush_cast.hush == null:
		return
	var from := hush_cast.hush.global_position
	var victims: Array = []
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == Unit.Team.PLAYER and _flat(u.global_position, from) <= KNIVES_RANGE:
			victims.append(u)
		if victims.size() >= KNIVES_STRIKES:
			break
	for i in victims.size():
		var v: Unit = victims[i]
		get_tree().create_timer(1.5 + 0.25 * i, false, true).timeout.connect(func() -> void:
			if is_instance_valid(v) and v.is_alive():
				var dmg := KNIVES_DAMAGE * (1.5 if v is Wizard or v is Helper else 1.0)
				v.take_damage(dmg, null))


func _on_hush_fled() -> void:
	if is_ending():
		return
	hush_state = &"fled"
	fire_once(&"E17")
	say_l(23)
	if objective_state("sec_hush") == "active":
		set_objective(&"sec_hush", "done")


## M00Cast: where Hush runs (the north tunnel).
func nearest_spawn(_at: Vector3) -> Vector3:
	return NORTH_TUNNEL


# ---------------------------------------------------------------- the gate

## Why the gate channel waits now ("" = it runs): diagnostics for the HUD / sims.
func gate_block() -> String:
	if not hero_alive() or _flat(hero.global_position, GATE_SPOT) > GATE_RANGE:
		return "vessa"
	if not _vey_near_vessa():
		return "vey"
	var n := _enemies_within(GATE_SPOT, GATE_CLEAR)
	return "enemy %d" % n if n > 0 else ""


func _tick_gate(delta: float) -> void:
	if gate_open or not forge_claimed or objective_state("obj_research") != "done" or not hero_alive():
		return
	var at_spot := _flat(hero.global_position, GATE_SPOT) <= GATE_RANGE
	if not at_spot and gate_progress <= 0.0:
		return
	var ok := at_spot and _vey_near_vessa() and _enemies_within_cached(GATE_SPOT, GATE_CLEAR) == 0
	if at_spot and fire_once(&"E18"):
		say_l(24)
		_start_w4()
	gate_paused = not ok
	if ok:
		gate_progress = minf(1.0, gate_progress + delta / float(by_difficulty(GATE_TIME)))
		if gate_progress >= 0.5 and fire_once(&"E19"):
			say_l(25)
		if gate_progress >= 1.0:
			_open_gate()
	_ring(&"gate", GATE_SPOT, gate_progress, Color(1.0, 0.92, 0.65, 0.6) if ok else Color(0.5, 0.5, 0.5, 0.5))


## W4 "The Splinter's Call": 0 s the push, 20 s amber Wardens from the floor, 35 s Hush (or 2 Knights if she fled).
func _start_w4() -> void:
	if _w4_started:
		return
	_w4_started = true
	waves_fired.append(&"W4")
	var units := spawn_wave_at(WAVES[&"W4"], _wave_spawn())
	for u in units:
		order_wave(u as Unit, &"vessa", hero_pos())
	wave_units[&"W4"] = units
	after(20.0, func() -> void:
		if is_ending() or gate_open:
			return
		var n: int = int(by_difficulty(W4_WARDENS))
		for i in n:
			var w := _spawn_warden(false, _floor_spot(GATE_SPOT, 12.0, float(i) * TAU / float(n)))
			order_wave(w, &"vessa", hero_pos())
			(wave_units[&"W4"] as Array).append(w))
	after(35.0, func() -> void:
		if is_ending() or gate_open:
			return
		if objective_state("sec_hush") == "done" or hush_state == &"gone":
			for u in spawn_wave_at(WAVES[&"W4K"], _wave_spawn()):
				order_wave(u as Unit, &"vessa", hero_pos())
		elif hush_cast == null or not hush_cast.hush_on_field():
			_spawn_hush(_wave_spawn(), 0.6))


## A walkable point about `r` from `center` at angle `a` (pulled in toward the hall until it is off the rock).
func _floor_spot(center: Vector3, r: float, a: float) -> Vector3:
	var rr := r
	while rr > 1.0:
		var p := center + Vector3(cos(a) * rr, 0.0, sin(a) * rr)
		if is_walkable(p, -1.5):
			return p
		rr -= 1.5
	return center + Vector3(0.0, 0.0, 6.0)


func open_gate() -> void:
	_open_gate()


## E20: the gate opens: Withdraw, e2m4_sunrise (L26-L29), victory 2 s after it.
func _open_gate() -> void:
	if gate_open:
		return
	gate_open = true
	gate_progress = 1.0
	gate_paused = false
	_ring(&"gate", GATE_SPOT, 0.0, Color.WHITE)
	fire_once(&"E20")
	set_objective(&"obj_gate", "done")
	_withdraw()
	if _gate_mesh:
		create_tween().tween_property(_gate_mesh, "position:y", -1.0, 3.0)
	for id: StringName in [&"sec_wardens", &"sec_hush", &"sec_sunstones"]:
		if objective_state(String(id)) == "active":
			set_objective(id, "failed")
	play_cutscene(&"e2m4_sunrise", func() -> void:
		say_l(26)
		say_l(27)
		say_l(28)
		say_l(29)
		set_objective(&"obj_vessa", "done")
		set_objective(&"obj_hearth", "done")
		win(VICTORY_DELAY))


func _withdraw() -> void:
	clear_waves()
	if hush_cast:
		hush_cast.hush_leave()
	for n in get_tree().get_nodes_in_group("units"):
		var u := n as Unit
		if u == null or not u.is_alive() or int(u.team) != Unit.Team.ENEMY:
			continue
		if amber_wardens.has(u):
			u.leave_map()   # the amber eyes go dark
			continue
		set_truce([u], true, Unit.TRUCE_ALL)
		u.set_meta(META_MODE, &"withdraw")
		u.command_move(NORTH_TUNNEL)
		var unit := u
		after(20.0, func() -> void:
			if is_instance_valid(unit) and unit.is_alive():
				unit.leave_map())


# ---------------------------------------------------------------- defeat

func _on_forge_destroyed(_b: Building) -> void:
	if is_ending() or gate_open:
		return
	fire_once(&"E23")
	say_l(33)
	set_objective(&"obj_hearth", "failed")
	lose(DEFEAT_DELAY)


func _on_player_hero_fell() -> void:
	fire_once(&"E22")
	say_l(32)
	set_objective(&"obj_vessa", "failed")
	super()


# ---------------------------------------------------------------- save / load (mission-save-hardening-2026-10-12)

## Woken Wardens are copies of ruin_warden: PLAYER = a Sunwarden, ENEMY = an amber Warden (NEUTRAL sleepers are
## rebuilt by the start). Acolytes and Ashby are local types (register_local_unit_type).
func save_spawn_unit(row: Dictionary) -> Unit:
	if String(row.get("type", "")) == "ruin_warden":
		var team := int(row.get("team", -1))
		var t: UnitType = _sunwarden_type if team == Unit.Team.PLAYER else (_amber_type if team == Unit.Team.ENEMY else null)
		if t != null:
			var u := Worker.make_unit(t)
			u.team = team as Unit.Team
			add_child(u)
			u.global_position = row["pos"]
			u.command_stop()
			return u
	return super(row)


## Hush's kit, registered mid-mission (E15): made again for its saved row
## (M00Cast.load_row puts Hush's max HP and HP back).
func _restore_missing_actor(key: String) -> Node:
	if key != "cast":
		return null
	return _make_hush_cast()


## E10 is added mid-mission (the claim): back before the base load checks the saved E-list.
## SaveWorld phase 1 start (before the buildings and the navmesh rebake): after the claim the rebuilt start's cold
## forge goes (the saved Warden Forge stands in its place).
func save_restore_seats(m: Dictionary) -> void:
	super(m)
	if bool((m.get("vars", {}) as Dictionary).get("forge_claimed", false)):
		_remove_cold_forge()


func _remove_cold_forge() -> void:
	if _cold_forge and is_instance_valid(_cold_forge):
		if _cold_forge.get_parent():
			_cold_forge.get_parent().remove_child(_cold_forge)   # out of the tree now: the next rebake skips it
		_cold_forge.queue_free()
	_cold_forge = null


func load_state(d: Dictionary, nodes: Dictionary = {}) -> void:
	if (d.get("events", []) as Array).has("E10"):
		_add_e10()
	super(d, nodes)


## Re-runs the hookups of every phase the save had reached: acolytes' interrupt hooks, the forge claim.
func _after_load(_nodes: Dictionary) -> void:
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and u.unit_type and u.unit_type.id == &"splinter_acolyte":
			_hook_acolyte(u)
	if forge_claimed:
		_apply_forge()
		var eco := Economy.for_team(Unit.Team.PLAYER)
		if eco and forge_pop_bonus > 0:
			eco.add_pop_bonus(forge_pop_bonus)   # Economy pop bonuses are not saved


# ---------------------------------------------------------------- every frame

func _physics_process(delta: float) -> void:
	super(delta)
	if not match_started or game_over or world_is_held:
		return
	tick_scripted(delta)
	if is_ending():
		return
	if _vey_kneel_left > 0.0:
		_vey_kneel_left -= delta
		if vey and is_instance_valid(vey):
			vey.hp = maxf(vey.hp, 1.0)
			if _vey_kneel_left <= 0.0:
				vey.hp = maxf(vey.hp, vey.max_hp * 0.5)
	_tick_wake(delta)
	_tick_acolytes(delta)
	_tick_claim(delta)
	_tick_gate(delta)
	_dark_tick -= delta
	if _dark_tick <= 0.0:
		_dark_tick = DARK_TICK
		_tick_dark()
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.5
		_tick_storm_aura()
		_tick_guides()
		var t := "%s|%s|%s|%s" % [objective_text(&"obj_research"), objective_text(&"obj_gate"),
				objective_text(&"sec_wardens"), objective_text(&"sec_sunstones")]
		if t != _last_obj_text:
			_last_obj_text = t
			objectives_changed.emit()
			if hud and mission_hud == null:
				hud.set_objective(_objective_text())


## The guides walk a few metres ahead of Vessa, toward the next hall.
func _tick_guides() -> void:
	if not hero_alive():
		return
	for i in guides.size():
		var g: Variant = guides[i]
		if not is_instance_valid(g) or not (g as Unit).is_alive():
			continue
		var u := g as Unit
		var spot := hero.global_position + Vector3(-2.0 + 2.0 * i, 0.0, -4.0)
		if u.attack_target == null and _flat(u.global_position, spot) > 4.0:
			u.command_move(spot)
