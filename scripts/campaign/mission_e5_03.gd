class_name MissionE5_03
extends MissionE5Base
## Episode 5, mission 3 "Tombstones by Candlelight" (docs/design/mission-e5-03.md): a flashback and the hand-over from
## Vessa to Malrik. Malrik at thirteen, the gravedigger's son of Wickmoor: in one night, with a candle, his father's two
## dogs and whatever shadows answer him, he reads three secrets out of the crypts, rings the Lantern House bell at
## midnight and stands up to Reeve Pike. Light and dark: violet shadow zones hide his units unless a light touches them;
## lamps and lanterns show them to the gravewardens; his candle is a toggle (lit: he sees and reads; pinched: he hides,
## snuffs lamps and calls the dark). Spotlight: the Shade (`shade_wild`, the first old grave called).
##
## Built deviations (2026-10-08, from the spec):
## - Wickmoor is a 90 x 90 map (the churchyard inside x / z -42..42 behind four invisible bound walls), flat, no
##   generator trees; the night is a dark-blue tint of the warm rig; FogOfWar.sight_scale 0.6 for Malrik's side.
## - The hidden rule is mission-side (the e3m2 pattern): every 0.25 s a player unit inside a shadow zone and not lit is
##   seen only within 2.5 m; a unit no enemy sees is hidden from auto-targets (Unit.hide_from_auto_target) and wears
##   `concealed`. Lights: lit lamps (7 m), each awake warden's lantern (5 m, +1 m per grave gift), the Reeve's lantern
##   (7 m; 9 m during his Bell Lantern), Malrik's own candle (4 m while lit).
## - The candle is a mission toggle (J, physical, and a button): lit = a SightMarker of sight 10 on Malrik, he can read;
##   pinched = his plain sight (x 0.6), he can snuff lamps (3 m, 2 s) and call an old grave (3 m, 3 s).
## - Gravewardens / the Reeve are mission-local types (Flame Guard looks); "Out cold" = dormant 45 s (no death), back at
##   50 % HP; XP once per warden. Patrols are mission-driven (no slow walk or corner pause; a dark lamp within 4 m is
##   relit after 3 s). Crypts are open shadow zones (no walls).
## - Midnight (rush floor): the bell can only be rung from 10:00 (9:00 / 10:00 / 11:00 by difficulty), "At midnight the
##   bell of Wickmoor rang" (L18). A direct route reached the bell long before; tests/test_e5m3_rush_sim.gd.
## - The alarm counts incidents: a cry while wardens already hunt or search adds nothing (the spec's 10 s town limit let
##   one sighting by a patrol pair and its neighbours wake Wickmoor within 30 s); a cry calls the wardens within 12 m
##   (spec 20). Wardens have 120 HP / armor 3 and hit for 6 (spec 150 / 5 / 10) and the waking town sends 0 / 1 / 2 extra wardens (spec 4): a level-1 Malrik
##   caught in the open by a pair died before he could reach any shadow. The Reeve shouts the hunt from inside the
##   Lantern House (he comes out only at the bell): with him on the hunt every wake killed a level-2 Malrik. Soot and
##   Bramble are the gravedigger's grown dogs: 140 HP (a pup Grave Hound has 70). Wakes came in every scripted run: the hunters lose a hidden unit after 4 s on normal (the spec's playtest knob) and the
##   alarm drops 1 every 60 s (spec 90). The Reeve has 350 / 450 / 600 HP and hits for 12 (spec 18); wardens see 5 / 6 / 7 m (spec 7 / 8 / 9).
## - The dark looks after its own (mission rule, the theme of pro. S21): Malrik regains 3 % HP / s while hidden and seen by
##   nobody, so hiding is how he recovers from a fight (else only the hut's fire healed him, a long walk past the lanterns).
## - After the bell only the Final hunts (2026-10-11): a patrol's cry no longer calls its neighbours (a cry while the
##   Reeve fought pulled 2-3 hunting wardens into the Final and a careful scripted run lost at 12:05); the Reeve's cry
##   then calls nobody else either.

const MISSION_ID := &"e5m3"
const MISSION_TITLE := "Tombstones by Candlelight"
const HALF := 42.0

const MALRIK_START := Vector3(-28.0, 0.0, 28.0)
const HUT := Vector3(-32.0, 0.0, 32.0)
const LANTERN_HOUSE := Vector3(0.0, 0.0, 0.0)
const LH_DOOR := Vector3(0.0, 0.0, -6.0)
const BELL := Vector3(0.0, 0.0, 5.0)
const STOCKS := Vector3(4.0, 0.0, 7.0)
## Crypt id -> [name, interior centre, door, zone radius, secret spot].
const CRYPTS := {
	&"C1": ["Weeping Crypt", Vector3(-26.0, 0.0, -24.0), Vector3(-22.0, 0.0, -20.0), 7.0, Vector3(-28.0, 0.0, -27.0)],
	&"C2": ["Old Ossuary", Vector3(24.0, 0.0, -26.0), Vector3(20.0, 0.0, -22.0), 8.0, Vector3(27.0, 0.0, -29.0)],
	&"C3": ["Reeve's Vault", Vector3(26.0, 0.0, 22.0), Vector3(22.0, 0.0, 18.0), 7.0, Vector3(28.0, 0.0, 25.0)],
}
const LAMPS: Array[Vector3] = [Vector3(-14, 0, -12), Vector3(14, 0, -12), Vector3(-14, 0, 12), Vector3(14, 0, 12),
		Vector3(0, 0, -22), Vector3(0, 0, 22), Vector3(-24, 0, 0), Vector3(24, 0, 0), Vector3(-5, 0, 8), Vector3(5, 0, 8)]
## Static shadow zones [centre, r] (crypt interiors added at start).
const ZONES := [[Vector3(-34, 0, -4), 6.0], [Vector3(34, 0, -6), 6.0], [Vector3(-8, 0, 32), 6.0], [Vector3(10, 0, -34), 5.0],
		[Vector3(-14, 0, 24), 5.0], [Vector3(-30, 0, 30), 6.0]]
const GRAVES: Array[Vector3] = [Vector3(-36.0, 0.0, 14.0), Vector3(14.0, 0.0, -36.0), Vector3(36.0, 0.0, 10.0)]
const TOMBSTONES: Array[Vector3] = [Vector3(-20, 0, 26), Vector3(-30, 0, -8), Vector3(-6, 0, -30), Vector3(10, 0, 30),
		Vector3(30, 0, -14), Vector3(34, 0, 30)]
## Grave gifts [position, item id].
const GIFTS := [[Vector3(-24, 0, 12), &"dusk_vial"], [Vector3(-38, 0, -20), &"ember_draught"], [Vector3(8, 0, -26), &"dusk_vial"],
		[Vector3(30, 0, -32), &"ember_draught"], [Vector3(38, 0, 20), &"homeward_seal"], [Vector3(12, 0, 34), &"ember_draught"]]
## Patrol id -> route.
const PATROLS := {
	&"PA": [Vector3(-14, 0, -12), Vector3(0, 0, -22), Vector3(14, 0, -12), Vector3(0, 0, -6)],
	&"PB": [Vector3(-24, 0, 0), Vector3(-14, 0, 12), Vector3(-20, 0, 22), Vector3(-30, 0, -8)],
	&"PC": [Vector3(24, 0, 0), Vector3(14, 0, 12), Vector3(22, 0, 18), Vector3(34, 0, -6)],
	&"PD": [Vector3(0, 0, -6), Vector3(-22, 0, -20), Vector3(20, 0, -22), Vector3(0, 0, -6)],
}
const PORCH: Array[Vector3] = [Vector3(-2.0, 0.0, 6.0), Vector3(2.0, 0.0, 6.0)]
const VAULT_GUARD := Vector3(24.0, 0.0, 21.0)
const MAGPIE_DIG := Vector3(25.0, 0.0, -27.0)

const LAMP_R := 7.0
const CANDLE_R := 4.0
const CANDLE_SIGHT := 16.7          ## x sight_scale 0.6 = 10 m
const READ_R := 2.0
const READ_SECRET := 4.0
const READ_STONE := 3.0
const SNUFF_R := 3.0
const SNUFF_TIME := 2.0
const SHADE_SNUFF_R := 2.0
const CALL_R := 3.0
const CALL_TIME := 3.0
const RELIGHT_R := 4.0
const RELIGHT_TIME := 3.0
const GIFT_R := 1.5
const BELL_R := 3.0
const BELL_TIME := 3.0
const BELL_AT: Array[float] = [540.0, 600.0, 660.0]
const CRY_R := 12.0           ## spec 20 m: a cry pulled two patrol pairs onto a level-1 Malrik
const CRY_EVERY := 15.0
const CRY_FUSE := 1.0            ## a warden stares 1 s before he cries
const ALARM_EVERY := 10.0
const ALARM_DECAY := 60.0         ## spec 90 s
const WAKE_TIME := 90.0
const WAKE_EVERY := 240.0
const WAKE_REFRESH := 5.0
const WAKE_EXTRA: Array[int] = [0, 1, 2]   ## spec 4 (x 0.6 / x 1.4)
const OUT_COLD := 45.0
const KO_XP := 20
const STONE_XP := 30
const REEVE_XP := 150
const BELL_LANTERN_EVERY := 10.0
const BELL_LANTERN_TIME := 3.0
const HIDDEN_SEEN: Array[float] = [2.0, 2.5, 3.0]
const WARDEN_SIGHT: Array[float] = [5.0, 6.0, 7.0]   ## spec 7 / 8 / 9 (lanterns blind them past their own light)
const LANTERN_R: Array[float] = [4.0, 5.0, 6.0]
const LOSE_AFTER: Array[float] = [3.0, 4.0, 6.0]   ## the spec's own playtest knob (4 s on normal when wakes are common)
const SHADE_BURN: Array[float] = [5.0, 8.0, 10.0]
const REEVE_HP: Array[float] = [350.0, 450.0, 600.0]   ## spec 450 / 600 / 800
const PATROL_SIZE: Array[int] = [1, 2, 3]
const DEFEAT_DELAY := 3.0
const LEVEL_CAP := 3
const YOUNG_SCALE := 0.82
const MAGPIE_LEASH := 12.0
const DARK_HEAL := 0.03           ## of Malrik's max HP per second while hidden and unseen (mission rule)

const SPEAKER_COLORS := {&"malrik": Color(0.7, 0.3, 1.0), &"reeve": Color(0.80, 0.70, 0.45),
		&"master": Color(1.0, 0.92, 0.70), &"narrator": Color(0.9, 0.85, 0.7)}
const SPEAKER_NAMES := {&"malrik": "Malrik", &"reeve": "Reeve Pike", &"master": "The Master", &"narrator": "Narrator"}
## The spec's 26 lines (data/voice/lines/e5m3.json): LINE_IDS[n - 1] = id of line n.
const LINE_IDS: Array[String] = ["L1", "L2", "L3", "L4", "L5", "L6", "L7", "L8", "L9", "L10", "L11", "L12", "L13",
		"L14", "L15", "L16", "L17", "L18", "L19", "L20", "L21", "L22", "L23", "L24", "L25", "L26"]
const DIALOGUE := [
	[&"narrator", "Wickmoor buried its dead with their rings on. Lately, someone had been taking them back."],
	[&"malrik", "They say my father robs graves. My father can't rob a pie off a windowsill."],
	[&"malrik", "The Reeve hangs him at dawn. So tonight I ask the dead. The dead don't lie to me."],
	[&"reeve", "Lanterns up, lads! If the gravedigger's brat comes sniffing, bring him to me."],
	[&"malrik", "There. Dark again. The dark never asks me what I'm doing here."],
	[&"malrik", "...Hello. You came when I called. Nobody comes when I call."],
	[&"narrator", "The shadows of the old graves stood up, and waited for him to speak."],
	[&"malrik", "\"Here lies Edda Brack. She was right about the roof.\" I believe you, Edda."],
	[&"reeve", "There! Something in the yews! Hoy! Hoy!"],
	[&"reeve", "Every lantern in Wickmoor, up! Find me that boy!"],
	[&"malrik", "They don't need it any more. I do. That isn't stealing. It's... inheritance."],
	[&"narrator", "He told himself it was only one ring. It was never only one."],
	[&"malrik", "A thief's purse, sealed with the Reeve's own seal. You pay robbers, Reeve?"],
	[&"malrik", "Magpies. In my father's ossuary. Digging up my father's work."],
	[&"malrik", "Every ring in Wickmoor, in one sack. With a receipt. Thieves are so tidy."],
	[&"malrik", "A ledger. Graves, rings and prices. He sold the dead by the pound."],
	[&"malrik", "Three secrets. Now the whole town can hear them. Where's that bell?"],
	[&"narrator", "At midnight the bell of Wickmoor rang, and every window in the town lit."],
	[&"reeve", "Clever boy. Clever boys have accidents in graveyards."],
	[&"malrik", "You're not one of the Reeve's. Who are you? ...You're very tall."],
	[&"master", "Reading tombstones by one candle, at midnight. And they told you everything."],
	[&"malrik", "The dead don't lie. They've got nothing left to want."],
	[&"master", "This one, too."],
	[&"narrator", "He pinched out his candle. In the dark, he was not afraid. He never had been."],
	[&"malrik", "Let go! He's lying! He's the one- let GO!"],
	[&"malrik", "Back! Out of the light! It eats you."],
]
const BRIEFING_PARAGRAPHS: Array[String] = [
	"Winter, the truce. In the crypt city, Malrik lights a candle and lets it burn longer than he needs to.",
	"Wickmoor buried its dead with their rings on, and lately someone had been taking them back. Reeve Aldous Pike, keeper of the lanterns, named the gravedigger, and locked him in the stocks to hang at dawn.",
	"The gravedigger's son was thirteen. He knew every grave in Wickmoor by heart, and every dark corner between them. He took a candle and his father's two dogs, and went to ask the dead who was lying.",
]
const HINT_CANDLE := "Malrik's candle: J (or the button on his card). Lit, he sees far and can read. Pinched, he hides in the dark."
const HINT_SHADOW := "Violet ground is shadow: there your units are hidden unless a light touches them, and Malrik heals. Lamps and lanterns show you to the wardens."
const HINT_SNUFF := "A snuffed lamp leaves a pool of shadow. Wardens relight lamps they pass."
const HINT_SHADES := "Shades burn in any light. Keep them in the dark; send them to breathe out lamps."
const HINT_SEEN := "Seen! Get back into the dark and stay there: the wardens lose you after {n} seconds."
const HINT_BELL := "The Bell is on the Lantern House porch, between two lamps and two wardens."
const HINT_SIPHON := "Ctrl+Q learns Soul Siphon: Q, then click a crowd. It heals Malrik for half of what it drains."
const MSG_CANDLE_LIT := "Candle lit"
const MSG_CANDLE_PINCHED := "Candle pinched"
const MSG_CANDLE_OUT := "Candle out: light it to read (J)"
const MSG_MIDNIGHT := "The bell rings at midnight ({time})"
const MSG_HOY := "Hoy!"
const MSG_CAUGHT := "Malrik was caught"
const BTN_CANDLE := "Candle (J)"

## Read only.
var candle_lit := true
var alarm := 0
var wakes := 0
var secrets_read: Array[String] = []
var stones_read: Array[int] = []
var dark_lamps: Array[int] = []
var graves_called: Array[int] = []
var gifts_taken: Array[int] = []
var hounds: Array = []
var shades: Array = []
var gravewardens: Array = []                 ## every warden (patrols, porch, vault, wake extras)
var magpies: Array = []
var reeve: Unit = null
var victory_time := -1.0
var knocked_out: Array = []             ## gravewardens already knocked out once (XP once)
var cries := 0

var _tick := 0.0
var _read_progress := {}                # spot key -> seconds
var _snuff_progress := {}               # lamp index -> seconds (Malrik or a Shade)
var _relight_progress := {}             # lamp index -> seconds
var _call_progress := {}                # grave index -> seconds
var _bell_progress := 0.0
var _fuse := {}                         # warden -> seconds he has been staring at a player unit
var _last_cry_at := -100.0
var _decay_at := -1.0
var _wake_ends_at := -1.0
var _wake_ready_at := 0.0
var _wake_refresh := 0.0
var _bell_lantern_left := 0.0
var _bell_lantern_on := 0.0
var _midnight_msg_at := -100.0
var _last_seen := Vector3.INF
var _candle_marker: SightMarker = null
var _lamp_looks := {}                   # lamp index -> [warm disc, violet disc, flame]
var _spot_looks := {}                   # key -> disc
var _candle_button: Control = null


# ---------------------------------------------------------------- setup

func _init() -> void:
	super()
	player_kingdom = &"shadow"
	enemy_kingdom = &"fire"
	line_ids = LINE_IDS.duplicate()
	dialogue_lines = DIALOGUE
	speaker_colors = SPEAKER_COLORS.duplicate()
	speaker_names = SPEAKER_NAMES.duplicate()
	briefing_paragraphs = BRIEFING_PARAGRAPHS.duplicate()
	define_objectives([[&"obj_secrets", "primary"], [&"obj_bell", "primary"], [&"obj_reeve", "primary"],
			[&"obj_malrik", "primary"], [&"sec_quiet", "secondary"], [&"sec_hands", "secondary"]])
	_make_types()


func _mission_config() -> MissionConfig:
	var c := MissionConfig.new()
	MissionE5Base.e5_config(c)
	c.mission_id = MISSION_ID
	c.title = MISSION_TITLE
	c.count_mult = []
	c.defeat_on_keep_lost = false
	c.start_level = 1
	c.start_spells = [&"shadow_lance"]
	c.level_cap = LEVEL_CAP
	c.economy_enabled = false
	c.resources_hidden = true
	c.start_crystals = [0, 0, 0]
	c.start_essence = 0
	c.essence_trickle = false
	c.kill_essence = false
	c.defeat_delay = DEFEAT_DELAY
	c.victory_banner = "VICTORY\nThe dead told him everything"
	c.defeat_banner = "DEFEAT\nMalrik was caught"
	c.rewards = CampaignState.MISSION_REWARDS.get(MISSION_ID, {})
	c.spotlight = {"id": &"shade_wild", "trigger": &"manual", "key_hint": "Old grave: pinch the candle (J)",
			"card": "Shade. Cheap, quiet, many: in the dark they are everywhere. In the light they burn."}
	return c


func _make_types() -> void:
	local_unit("shade", "shade_wild", "Shade", {"cost": 0, "pop": 0, "commandable": true, "kill_xp": 10})
	local_unit("grave_hound", "soot_hound", "Soot", {"cost": 0, "pop": 0, "commandable": true, "max_hp": 140.0,
			"body_color": Color(0.10, 0.10, 0.12)})
	local_unit("grave_hound", "bramble_hound", "Bramble", {"cost": 0, "pop": 0, "commandable": true, "max_hp": 140.0,
			"body_color": Color(0.42, 0.30, 0.20)})
	local_unit("flame_guard", "gravewarden", "Gravewarden", {"max_hp": 120.0, "armor": 3.0, "attack_damage": 6.0,
			"attack_cooldown": 1.2, "move_speed": 4.6, "sight_radius": 8.0, "aggro_range": 6.0, "kill_xp": 0, "cost": 0,
			"pop": 0, "commandable": false, "body_color": Color(0.36, 0.30, 0.22)})
	local_unit("flame_guard", "reeve_pike", "Reeve Aldous Pike", {"max_hp": 600.0, "armor": 10.0, "attack_damage": 12.0,
			"attack_cooldown": 1.2, "move_speed": 4.8, "sight_radius": 10.0, "aggro_range": 8.0, "kill_xp": 0, "cost": 0,
			"pop": 0, "commandable": false, "body_color": Color(0.55, 0.45, 0.25)})
	local_unit("magpie", "grave_robber", "Magpie", {"aggro_range": 8.0, "kill_xp": 40, "commandable": false})


func _map_size() -> Vector2:
	return Vector2(90.0, 90.0)


func _player_start() -> Vector3:
	return MALRIK_START


func _use_map_dressing() -> bool:
	return false


func _title_line() -> String:
	return "Episode 5, Mission 3: %s" % MISSION_TITLE


func _ground_spots() -> Array[Vector4]:
	return [Vector4(0.0, 0.0, 9.0, 1.0), Vector4(HUT.x, HUT.z, 6.0, 0.0)]


func _ready() -> void:
	super()
	# wick_night stand-in: moonlight
	tint_light(Color(0.55, 0.62, 0.95), 0.35, -40.0, Color(0.22, 0.24, 0.40), Color(0.04, 0.05, 0.12),
			Color(0.14, 0.16, 0.30))
	if fog and &"sight_scale" in fog:
		var s: Array[float] = [0.6, 1.0]
		fog.set(&"sight_scale", s)
	if camera_rig:
		camera_rig.focus_on(MALRIK_START)


# ---------------------------------------------------------------- seats

func start_position(_team: int) -> Vector3:
	return MALRIK_START


func base_center(_team: int) -> Vector3:
	return HUT


func node_of(_team: int, _suffix: String) -> CrystalNode:
	return null


func natural_hall_spot(_team: int) -> Vector3:
	return Vector3.INF


func rich_hall_spot(_team: int) -> Vector3:
	return Vector3.INF


func market_slot(_team: int) -> Vector3:
	return Vector3.INF


func tower_slot(_team: int, _which: StringName) -> Vector3:
	return Vector3.INF


# ---------------------------------------------------------------- the map

func _build_map() -> void:
	# The gravedigger's hut is Malrik's "keep" (main.gd needs one): a Keep that trains nothing, never shoots, out of
	# every fight (truce); its home healing is the hut's fire.
	var ht := MissionE5Base.local_building("shadow_keep", "gravedigger_hut", "Gravedigger's Hut", 5000.0)
	if ht:
		ht.kind = &"keep"
		ht.trains = []
		ht.attack_damage = 0.0
		ht.attack_range = 0.0
		ht.footprint = Vector2i(2, 2)
		ht.sight_radius = 4.0
		keep = build_grid.spawn_complete(ht, HUT, Unit.Team.PLAYER) as Keep
		if keep:
			keep.name = "GravediggerHut"
			seat_keeps[Unit.Team.PLAYER] = keep
	seat_bases[Unit.Team.PLAYER] = HUT
	var c := [Vector3(-HALF, 0, -HALF), Vector3(HALF, 0, -HALF), Vector3(HALF, 0, HALF), Vector3(-HALF, 0, HALF)]
	for i in 4:
		bound_wall(c[i], c[(i + 1) % 4], 2.5)
	var lh := BoxShape3D.new()
	lh.size = Vector3(6.0, 6.0, 6.0)
	var body := _static_obstacle(LANTERN_HOUSE + Vector3(0.0, 0.0, -1.0), lh, 3.0)   # the watch-house (not targetable)
	if not _SIM.enabled:
		var box := BoxMesh.new()
		box.size = lh.size
		_mesh(body, box, Color(0.30, 0.28, 0.30), 3.0)
		var tower := BoxMesh.new()
		tower.size = Vector3(2.4, 5.0, 2.4)
		var tw := _mesh(body, tower, Color(0.26, 0.24, 0.26), 8.5)
		tw.position.z = -1.0
		box_prop(STOCKS, Vector3(1.6, 1.0, 0.4), Color(0.35, 0.26, 0.18))
		for id: StringName in CRYPTS:
			box_prop(CRYPTS[id][1], Vector3(5.0, 3.0, 5.0), Color(0.22, 0.22, 0.26), 0.0)
		for p in TOMBSTONES:
			box_prop(p, Vector3(0.9, 1.1, 0.25), Color(0.55, 0.55, 0.58))
		for p in GRAVES:
			ground_disc(p, 1.4, Color(0.05, 0.03, 0.08, 0.8), 0.04)


# ---------------------------------------------------------------- start state

func _on_navigation_ready() -> void:
	var diff := clampi(mission_difficulty, 0, 2)
	local_type("reeve_pike").max_hp = float(REEVE_HP[diff])
	for id: StringName in CRYPTS:
		fog.reveal(Unit.Team.PLAYER, CRYPTS[id][2], 4.0)
	fog.reveal(Unit.Team.PLAYER, BELL, 4.0)
	for p in GRAVES:
		fog.reveal(Unit.Team.PLAYER, p, 4.0)
	_setup_champions()
	hero = _make_wizard(Unit.Team.PLAYER)
	_spawn(hero, Unit.Team.PLAYER, MALRIK_START)
	_claim_wizard(hero, Unit.Team.PLAYER)
	ItemDrops.ensure_inventory(hero)
	MissionE5Base.young_look(hero, &"young", YOUNG_SCALE)
	hero.level_changed.connect(_on_malrik_level)
	var inv: Variant = hero.get(&"inventory")
	var vial := ItemType.find(&"dusk_vial")
	if inv and vial:
		inv.call(&"add_item", vial)
	for i in 2:
		var hd := _spawn(make_unit("soot_hound" if i == 0 else "bramble_hound"), Unit.Team.PLAYER,
				MALRIK_START + Vector3(-1.5 + 3.0 * i, 0.0, 0.0))
		hd.name = "Soot" if i == 0 else "Bramble"
		hounds.append(hd)
	_build_looks()
	var n := int(PATROL_SIZE[diff])
	for pid: StringName in PATROLS:
		var route: Array = PATROLS[pid]
		for i in n:
			var w := _warden(route[0] + Vector3(1.2 * i, 0.0, 0.0))
			w.set_meta(&"e5_route", pid)
			w.set_meta(&"e5_wp", 1 if pid != &"PD" else 1)
			w.set_meta(&"e5_mode", &"patrol")
	for p in PORCH:
		var w := _warden(p)
		w.set_meta(&"e5_post", p)
		w.set_meta(&"e5_mode", &"post")
	var vg := _warden(VAULT_GUARD)
	vg.set_meta(&"e5_post", VAULT_GUARD)
	vg.set_meta(&"e5_mode", &"post")
	for i in 3:
		var mg := _spawn(make_unit("grave_robber"), Unit.Team.NEUTRAL, MAGPIE_DIG + Vector3(cos(i * 2.1) * 2.0, 0.0, sin(i * 2.1) * 2.0))
		mark_scripted(mg)
		mg.set_meta(META_HOME, mg.global_position)
		magpies.append(mg)
	reeve = _spawn(make_unit("reeve_pike"), Unit.Team.ENEMY, LH_DOOR)
	reeve.name = "ReevePike"
	mark_scripted(reeve)
	reeve.death_guard = _reeve_guard
	_reeve_inside(true)
	if keep:
		set_truce([keep], true, Unit.TRUCE_ALL)   # nothing attacks the hut (spec: decor)
	begin_mission([&"obj_secrets", &"obj_malrik", &"sec_quiet", &"sec_hands"])
	_set_candle(true, false)
	if hud and hud.inventory_bar:
		hud.inventory_bar.visible = true   # D8: grave gifts are items (no shop)
	_candle_button = mission_button_panel("CandlePanel", [[Loc.t(BTN_CANDLE), toggle_candle]])
	selection.select_units([hero])


func _warden(at: Vector3) -> Unit:
	var w := _spawn(make_unit("gravewarden"), Unit.Team.ENEMY, at)
	mark_scripted(w)
	w.death_guard = _warden_guard.bind(w)
	gravewardens.append(w)
	return w


## The Reeve inside the Lantern House (asleep, unseen) or out on the porch.
func _reeve_inside(inside: bool) -> void:
	if reeve == null or not is_instance_valid(reeve):
		return
	if inside:
		set_dormant(reeve, true)
		reeve.visible = false
		reeve.global_position = LH_DOOR
	else:
		set_dormant(reeve, false)
		reeve.visible = true
		reeve.death_guard = _reeve_guard


func _intro() -> void:
	fire_once(&"E1")
	play_cutscene(&"e5m3_wickmoor", _wickmoor_end)
	after(20.0, _e2_hint)


## e5m3_wickmoor end state: Malrik at the start, the hounds at his sides, candle lit, no orders.
func _wickmoor_end() -> void:
	for id in ["L1", "L2", "L3", "L4"]:
		say_l(id)
	if hud:
		hud.show_message(HINT_CANDLE, 12.0)
	if camera_rig and hero_alive():
		camera_rig.focus_on(hero.global_position)


func _e2_hint() -> void:
	if fire_once(&"E2") and hud:
		hud.show_message(HINT_SHADOW, 12.0)


# ---------------------------------------------------------------- the candle

func _unhandled_input(event: InputEvent) -> void:
	super(event)
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).physical_keycode == KEY_J:
		toggle_candle()
		get_viewport().set_input_as_handled()


## J / the button: lit <-> pinched. Returns the new state.
func toggle_candle() -> bool:
	if not hero_alive() or is_ending():
		return candle_lit
	_set_candle(not candle_lit, true)
	return candle_lit


func _set_candle(lit: bool, tell: bool) -> void:
	candle_lit = lit
	if _candle_marker and is_instance_valid(_candle_marker):
		_candle_marker.queue_free()
	_candle_marker = null
	if lit and hero_alive():
		_candle_marker = SightMarker.spawn(Unit.Team.PLAYER, hero.global_position, CANDLE_SIGHT, 0.0, self)
	_read_progress.clear()
	if tell and hud:
		hud.show_message(MSG_CANDLE_LIT if lit else MSG_CANDLE_PINCHED, 2.0)


# ---------------------------------------------------------------- light and dark

func lantern_r() -> float:
	return float(by_difficulty(LANTERN_R)) + float(gifts_taken.size())


## [[centre, radius], ...] of every light now.
func lights() -> Array:
	var out: Array = []
	for i in LAMPS.size():
		if not dark_lamps.has(i):
			out.append([LAMPS[i], LAMP_R])
	var lr := lantern_r()
	for w: Variant in gravewardens:
		if is_instance_valid(w) and (w as Unit).is_alive() and not is_dormant(w):
			out.append([(w as Unit).global_position, lr])
	if reeve and is_instance_valid(reeve) and reeve.is_alive() and not is_dormant(reeve):
		out.append([reeve.global_position, 9.0 if _bell_lantern_on > 0.0 else 7.0])
	if candle_lit and hero_alive():
		out.append([hero.global_position, CANDLE_R])
	return out


func lit_at(p: Vector3, light_list: Array = []) -> bool:
	var ls := light_list if not light_list.is_empty() else lights()
	for l: Array in ls:
		if _flat(l[0], p) <= float(l[1]):
			return true
	return false


func zones() -> Array:
	var out: Array = ZONES.duplicate()
	for id: StringName in CRYPTS:
		out.append([CRYPTS[id][1], CRYPTS[id][3]])
	for i in dark_lamps:
		out.append([LAMPS[i], LAMP_R])
	return out


func in_shadow(p: Vector3) -> bool:
	for z: Array in zones():
		if _flat(z[0], p) <= float(z[1]):
			return true
	return false


## D2: inside a shadow zone and not lit.
func is_hidden(u: Unit, light_list: Array = []) -> bool:
	if u == null or not u.is_alive():
		return false
	return in_shadow(u.global_position) and not lit_at(u.global_position, light_list)


func _player_units() -> Array[Unit]:
	var out: Array[Unit] = []
	if hero_alive():
		out.append(hero)
	for u in units_of(Unit.Team.PLAYER):
		if u != hero:
			out.append(u)
	return out


func _watchers() -> Array[Unit]:
	var out: Array[Unit] = []
	for v: Variant in gravewardens + magpies + [reeve]:
		if v != null and is_instance_valid(v) and (v as Unit).is_alive() and not is_dormant(v):
			out.append(v as Unit)
	return out


## Every 0.25 s: who sees whom (the hidden rule), the cries, Shades burning in light.
func _tick_stealth(dt: float) -> void:
	var ls := lights()
	var seen_r := float(by_difficulty(HIDDEN_SEEN))
	var sight := float(by_difficulty(WARDEN_SIGHT))
	var mine := _player_units()
	var watchers := _watchers()
	var spotting := {}   # warden / Reeve -> the player unit he sees this tick
	for u in mine:
		var hidden := is_hidden(u, ls)
		var seen_by: Unit = null
		for e in watchers:
			var r := seen_r if hidden else (10.0 if e == reeve or magpies.has(e) else sight)
			if _flat(e.global_position, u.global_position) <= r:
				seen_by = e
				if not magpies.has(e) and not spotting.has(e):
					spotting[e] = u
		if seen_by == null:
			u.hide_from_auto_target(0.6)
			if hidden and u == hero:
				hero.heal(hero.max_hp * DARK_HEAL * dt)   # the dark looks after its own
		if hidden:
			u.apply_status(&"concealed", 0.6, true)
		if shades.has(u) and lit_at(u.global_position, ls):
			var burn := float(by_difficulty(SHADE_BURN)) * dt
			if reeve and _bell_lantern_on > 0.0 and _flat(reeve.global_position, u.global_position) <= 9.0:
				burn *= 2.0
			u.take_damage(burn, null)
			if fire_once(&"E15"):
				say_l("L26")
	# The cry needs a 1 s look (he stops and stares, spec "stops 1 s"); a hunter just updates the hunt.
	for e: Variant in _fuse.keys():
		if not spotting.has(e):
			_fuse.erase(e)
	for e: Variant in spotting:
		var w := e as Unit
		if w.get_meta(&"e5_mode", &"") == &"hunt":
			_cry(w, spotting[e])
			continue
		_fuse[w] = float(_fuse.get(w, 0.0)) + dt
		if float(_fuse[w]) < CRY_FUSE:
			if w.attack_target == null:
				w.command_stop()
			continue
		_fuse.erase(w)
		_cry(w, spotting[e])


## A warden (or the Reeve) sees a player unit: "Hoy!", he and every warden within 20 m hunt there; the alarm +1.
func _cry(by: Unit, target: Unit) -> void:
	# After the bell only the Final hunts (campaign notes 2026-10-11: a cry pulled its neighbours into the Reeve fight
	# and a careful run that had read everything lost at 12:05): the bell drowns every other "Hoy!", and the Reeve's
	# own cry calls nobody else (below).
	if has_fired(&"E13") and by != reeve and by.get_meta(&"e5_mode", &"") != &"final":
		return
	var t := mission_time()
	_last_seen = target.global_position
	if t - float(by.get_meta(&"e5_cry_at", -100.0)) < CRY_EVERY:
		by.set_meta(&"e5_seen_at", t)
		if by.get_meta(&"e5_mode", &"") == &"hunt":
			by.set_meta(&"e5_hunt", target.global_position)
		return
	by.set_meta(&"e5_cry_at", t)
	cries += 1
	_bark(by)
	var new_incident := not _hunting()
	for w: Variant in gravewardens:
		if not is_instance_valid(w) or not (w as Unit).is_alive() or is_dormant(w):
			continue
		var wu := w as Unit
		if wu == by or (_flat(wu.global_position, by.global_position) <= CRY_R and not has_fired(&"E13")):
			wu.set_meta(&"e5_mode", &"hunt")
			wu.set_meta(&"e5_hunt", target.global_position)
			wu.set_meta(&"e5_seen_at", t)
			wu.command_attack_move(target.global_position)
	if new_incident and t - _last_cry_at >= ALARM_EVERY:
		_last_cry_at = t
		_raise_alarm()


## True while a warden is already hunting or searching (a cry then is part of the same incident: no alarm).
func _hunting() -> bool:
	for w: Variant in gravewardens:
		if is_instance_valid(w) and (w as Unit).is_alive() and not (w as Unit).has_meta(&"e5_extra") \
				and (w as Unit).get_meta(&"e5_mode", &"") in [&"hunt", &"search"]:
			return true
	return false


func _bark(by: Unit) -> void:
	if _SIM.enabled:
		return
	var l := Label3D.new()
	l.text = Loc.t(MSG_HOY)
	l.modulate = Color(1.0, 0.25, 0.2)
	l.font_size = 48
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	by.add_child(l)
	l.position = Vector3(0.0, 2.6, 0.0)
	var tw := l.create_tween()
	tw.tween_interval(1.2)
	tw.tween_callback(l.queue_free)


func _raise_alarm() -> void:
	alarm = mini(3, alarm + 1)
	_decay_at = mission_time() + ALARM_DECAY
	if fire_once(&"E6"):
		say_l("L9")
		if hud:
			hud.show_message(Loc.t(HINT_SEEN, {"n": int(by_difficulty(LOSE_AFTER))}), 12.0)
	if alarm >= 3 and mission_time() >= _wake_ready_at and _wake_ends_at < 0.0 and not has_fired(&"E13"):
		_wickmoor_wakes()


## Alarm 3: every lamp relights; the Reeve + 4 gravewardens hunt Malrik's last seen spot for 90 s (once per 4 min).
func _wickmoor_wakes() -> void:
	wakes += 1
	_wake_ends_at = mission_time() + WAKE_TIME
	_wake_ready_at = mission_time() + WAKE_EVERY
	fire_once(&"E7")
	say_l("L10")
	if objective_state("sec_quiet") == "active":
		set_objective(&"sec_quiet", "failed")
	for i in dark_lamps.duplicate():
		_relight(i)
	for i in int(by_difficulty(WAKE_EXTRA)):
		var w := _warden(LH_DOOR + Vector3(-2.0 + i * 1.3, 0.0, -1.5))
		w.set_meta(&"e5_mode", &"hunt")
		w.set_meta(&"e5_extra", true)
		w.set_meta(&"e5_seen_at", mission_time())
	_wake_refresh = 0.0


func _tick_wake(dt: float) -> void:
	if _wake_ends_at < 0.0:
		return
	if mission_time() >= _wake_ends_at:
		_wake_ends_at = -1.0
		alarm = 2
		_decay_at = mission_time() + ALARM_DECAY
		for w: Variant in gravewardens.duplicate():
			if is_instance_valid(w) and (w as Unit).has_meta(&"e5_extra"):
				gravewardens.erase(w)
				(w as Unit).leave_map()
		return
	_wake_refresh -= dt
	if _wake_refresh > 0.0:
		return
	_wake_refresh = WAKE_REFRESH
	var to := _last_seen if _last_seen != Vector3.INF else hero_pos()
	for w: Variant in gravewardens:
		if is_instance_valid(w) and (w as Unit).has_meta(&"e5_extra") and (w as Unit).is_alive() and not is_dormant(w):
			(w as Unit).command_attack_move(to)


# ---------------------------------------------------------------- gravewardens

func _warden_guard(_attacker: Variant, w: Unit) -> bool:
	if w == null or not is_instance_valid(w):
		return false
	_out_cold(w)
	return true


## D4: Out cold for 45 s (no death), then up at 50 % and back to the Lantern House; XP once per warden.
func _out_cold(w: Unit) -> void:
	if is_dormant(w):
		return
	w.hp = 1.0
	set_dormant(w, true)
	w.command_stop()   # a sleeping unit keeps its attack order otherwise
	w.set_meta(&"e5_mode", &"out")
	w.set_meta(&"e5_wake_at", mission_time() + OUT_COLD)
	if not knocked_out.has(w) and hero_alive():
		knocked_out.append(w)
		hero.add_xp(KO_XP)


func _tick_wardens() -> void:
	var t := mission_time()
	var lose := float(by_difficulty(LOSE_AFTER))
	for v: Variant in gravewardens:
		if not is_instance_valid(v) or not (v as Unit).is_alive():
			continue
		var w := v as Unit
		var mode: StringName = w.get_meta(&"e5_mode", &"patrol")
		match mode:
			&"out":
				if t >= float(w.get_meta(&"e5_wake_at", t)):
					set_dormant(w, false)
					w.death_guard = _warden_guard.bind(w)
					w.hp = w.max_hp * 0.5
					w.set_meta(&"e5_mode", &"return")
					w.command_move(LH_DOOR)
			&"hunt":
				if w.has_meta(&"e5_extra") and _wake_ends_at > 0.0:
					continue
				if t - float(w.get_meta(&"e5_seen_at", t)) >= lose:
					w.set_meta(&"e5_mode", &"search")
					w.set_meta(&"e5_search_until", t + 8.0)
					w.command_move(w.get_meta(&"e5_hunt", w.global_position))
				elif w.attack_target == null:
					w.command_attack_move(w.get_meta(&"e5_hunt", w.global_position))
			&"search":
				if t >= float(w.get_meta(&"e5_search_until", t)):
					w.set_meta(&"e5_mode", &"return")
			&"return":
				if w.has_meta(&"e5_post"):
					w.set_meta(&"e5_mode", &"post")
				elif w.has_meta(&"e5_route"):
					w.set_meta(&"e5_mode", &"patrol")
				else:
					w.set_meta(&"e5_mode", &"post")
					w.set_meta(&"e5_post", LH_DOOR)
			&"post":
				var p: Vector3 = w.get_meta(&"e5_post", w.global_position)
				if w.attack_target == null and _flat(w.global_position, p) > 1.5 and not w.has_move_order():
					w.command_move(p)
			&"patrol":
				_patrol_step(w)


func _patrol_step(w: Unit) -> void:
	var route: Array = PATROLS.get(StringName(w.get_meta(&"e5_route", &"PA")), [])
	if route.is_empty():
		return
	var i := int(w.get_meta(&"e5_wp", 0)) % route.size()
	var to: Vector3 = route[i]
	if _flat(w.global_position, to) < 2.0:
		i = (i + 1) % route.size()
		w.set_meta(&"e5_wp", i)
		to = route[i]
		w.command_move(to)
	elif w.attack_target == null and not w.has_move_order():
		w.command_move(to)


func _tick_magpies() -> void:
	for v: Variant in magpies:
		if not is_instance_valid(v) or not (v as Unit).is_alive():
			continue
		var m := v as Unit
		var home: Vector3 = m.get_meta(META_HOME, MAGPIE_DIG)
		if _flat(m.global_position, home) > MAGPIE_LEASH * 2.0 and not m.has_meta(META_MODE):
			m.command_move(home)
	if not has_fired(&"E10") and hero_alive():
		for v: Variant in magpies:
			if is_instance_valid(v) and (v as Unit).is_alive() and _flat((v as Unit).global_position, hero.global_position) <= 10.0:
				fire_once(&"E10")
				say_l("L14")
				break


# ---------------------------------------------------------------- lamps, graves, reading, gifts

func _snuff(i: int) -> void:
	if dark_lamps.has(i):
		return
	dark_lamps.append(i)
	_lamp_look(i)
	if fire_once(&"E3"):
		say_l("L5")
		if hud:
			hud.show_message(HINT_SNUFF, 12.0)


func _relight(i: int) -> void:
	if not dark_lamps.has(i):
		return
	dark_lamps.erase(i)
	_lamp_look(i)


func _tick_lamps(dt: float) -> void:
	var malrik_ok := hero_alive() and not candle_lit
	for i in LAMPS.size():
		var p := LAMPS[i]
		if dark_lamps.has(i):
			var near_warden := false
			for v: Variant in gravewardens:
				if is_instance_valid(v) and (v as Unit).is_alive() and not is_dormant(v) \
						and _flat((v as Unit).global_position, p) <= RELIGHT_R:
					near_warden = true
					break
			if near_warden:
				_relight_progress[i] = float(_relight_progress.get(i, 0.0)) + dt
				if float(_relight_progress[i]) >= RELIGHT_TIME:
					_relight_progress.erase(i)
					_relight(i)
			else:
				_relight_progress.erase(i)
			continue
		var snuffer := malrik_ok and _flat(hero.global_position, p) <= SNUFF_R
		if not snuffer:
			for s: Variant in shades:
				if is_instance_valid(s) and (s as Unit).is_alive() and _flat((s as Unit).global_position, p) <= SHADE_SNUFF_R:
					snuffer = true
					break
		if snuffer:
			_snuff_progress[i] = float(_snuff_progress.get(i, 0.0)) + dt
			if float(_snuff_progress[i]) >= SNUFF_TIME:
				_snuff_progress.erase(i)
				_snuff(i)
		else:
			_snuff_progress.erase(i)


func _tick_graves(dt: float) -> void:
	if not hero_alive():
		return
	for i in GRAVES.size():
		if graves_called.has(i):
			continue
		if not candle_lit and _flat(hero.global_position, GRAVES[i]) <= CALL_R:
			_call_progress[i] = float(_call_progress.get(i, 0.0)) + dt
			if float(_call_progress[i]) >= CALL_TIME:
				_call_progress.erase(i)
				_call_dark(i)
		else:
			_call_progress.erase(i)


## Calling the dark: 2 Shades rise from the old grave (each grave once). E4 the first time (and the spotlight).
func _call_dark(i: int) -> void:
	graves_called.append(i)
	for k in 2:
		var s := _spawn(make_unit("shade_wild"), Unit.Team.PLAYER, GRAVES[i] + Vector3(-1.0 + 2.0 * k, 0.0, 1.0))
		shades.append(s)
	flash_ring(GRAVES[i], 2.5)
	if fire_once(&"E4"):
		say_l("L6")
		say_l("L7")
		show_spotlight()
		if hud:
			hud.show_message(HINT_SHADES, 12.0)


## The read spots: secrets S1-S3 (4 s) and the six tombstones (3 s, +30 XP), Malrik with the candle lit within 2 m.
func _tick_reading(dt: float) -> void:
	if not hero_alive():
		return
	var p := hero.global_position
	var spots: Array = []
	for id: StringName in CRYPTS:
		if not secrets_read.has(String(id)):
			spots.append([String(id), CRYPTS[id][4], READ_SECRET])
	for i in TOMBSTONES.size():
		if not stones_read.has(i):
			spots.append(["T%d" % i, TOMBSTONES[i], READ_STONE])
	for s: Array in spots:
		var key := String(s[0])
		if _flat(p, s[1]) <= READ_R:
			if not candle_lit:
				if hud and float(_read_progress.get(key, -1.0)) == -1.0:
					hud.show_message(MSG_CANDLE_OUT, 3.0)
				_read_progress[key] = -0.5
				continue
			_read_progress[key] = maxf(0.0, float(_read_progress.get(key, 0.0))) + dt
			if float(_read_progress[key]) >= float(s[2]):
				_read_progress.erase(key)
				_read(key)
		else:
			_read_progress.erase(key)


func _read(key: String) -> void:
	if key.begins_with("T"):
		var i := int(key.substr(1))
		stones_read.append(i)
		if hero_alive():
			hero.add_xp(STONE_XP)
		if fire_once(&"E5"):
			say_l("L8")
		objectives_changed.emit()
		return
	secrets_read.append(key)
	match key:
		"C1":
			fire_once(&"E9")
			say_l("L13")
		"C2":
			fire_once(&"E11")
			say_l("L15")
		"C3":
			say_l("L16")
	set_objective(&"obj_secrets", "active")
	if secrets_read.size() >= 3:
		fire_once(&"E12")
		say_l("L17")
		set_objective(&"obj_secrets", "done")
		set_objective(&"obj_bell", "active")
		if hud:
			hud.show_message(HINT_BELL, 12.0)


func _tick_gifts() -> void:
	if not hero_alive():
		return
	for i in GIFTS.size():
		if gifts_taken.has(i) or _flat(hero.global_position, GIFTS[i][0]) > GIFT_R:
			continue
		gifts_taken.append(i)
		var inv: Variant = hero.get(&"inventory")
		var it := ItemType.find(StringName(GIFTS[i][1]))
		if inv and it:
			inv.call(&"add_item", it)
		var look: Variant = _spot_looks.get("R%d" % i)
		if look and is_instance_valid(look):
			(look as Node3D).visible = false
		if fire_once(&"E8"):
			say_l("L11")
			say_l("L12")
		if objective_state("sec_hands") == "active":
			set_objective(&"sec_hands", "failed")


func bell_at() -> float:
	return float(by_difficulty(BELL_AT))


## obj_bell: Malrik, candle lit, within 3 m of the Bell for 3 s, at midnight at the earliest.
func _tick_bell(dt: float) -> void:
	if objective_state("obj_bell") != "active" or not hero_alive():
		return
	if _flat(hero.global_position, BELL) > BELL_R or not candle_lit:
		_bell_progress = 0.0
		return
	if mission_time() < bell_at():
		_bell_progress = 0.0
		if hud and mission_time() - _midnight_msg_at > 8.0:
			_midnight_msg_at = mission_time()
			hud.show_message(Loc.t(MSG_MIDNIGHT, {"time": MissionE5Base.mmss(bell_at())}), 4.0)
		return
	_bell_progress += dt
	if _bell_progress >= BELL_TIME:
		_ring_bell()


## E13: the bell rings: L18-L19, obj_reeve, every window lights, the Reeve + the porch guard come for Malrik (the spec's
## Magpie from the vault is left out: with it the Final killed a level-2 Malrik in most scripted runs).
func _ring_bell() -> void:
	if not fire_once(&"E13"):
		return
	set_objective(&"obj_bell", "done")
	if objective_state("sec_quiet") == "active":
		set_objective(&"sec_quiet", "done")
	say_l("L18")
	say_l("L19")
	set_objective(&"obj_reeve", "active")
	_reeve_inside(false)
	reeve.global_position = LH_DOOR + Vector3(0.0, 0.0, 9.0)
	order_wave(reeve, &"hero", hero_pos())
	for v: Variant in gravewardens:
		if is_instance_valid(v) and (v as Unit).has_meta(&"e5_post") and _flat((v as Unit).get_meta(&"e5_post"), BELL) < 6.0 \
				and not is_dormant(v):
			(v as Unit).set_meta(&"e5_mode", &"final")
			order_wave(v as Unit, &"hero", hero_pos())
	# Only the spec's Final fights now: the waking town's extra wardens go home, every other warden stops the hunt.
	_wake_ends_at = -1.0
	for v: Variant in gravewardens.duplicate():
		if not is_instance_valid(v):
			continue
		var w := v as Unit
		if w.has_meta(&"e5_extra"):
			gravewardens.erase(w)
			w.leave_map()
		elif w.get_meta(&"e5_mode", &"") in [&"hunt", &"search"]:
			w.set_meta(&"e5_mode", &"return")
			w.command_stop()
	_bell_lantern_left = BELL_LANTERN_EVERY


func _tick_reeve(dt: float) -> void:
	if reeve == null or not is_instance_valid(reeve) or is_dormant(reeve) or not reeve.is_alive():
		return
	_bell_lantern_on = maxf(0.0, _bell_lantern_on - dt)
	_bell_lantern_left -= dt
	if _bell_lantern_left <= 0.0:
		_bell_lantern_left = BELL_LANTERN_EVERY
		_bell_lantern_on = BELL_LANTERN_TIME


func _reeve_guard(_attacker: Variant) -> bool:
	if reeve == null or not is_instance_valid(reeve):
		return false
	reeve.hp = 1.0
	reeve.command_stop()
	if has_fired(&"E13"):
		_reeve_out_cold()
	else:
		set_dormant(reeve, true)
		_reeve_inside(true)
	return true


## E16: the Reeve is out cold: e5m3_found, then the victory.
func _reeve_out_cold() -> void:
	if is_ending() or not fire_once(&"E16"):
		return
	victory_time = mission_time()
	set_dormant(reeve, true)
	if hero_alive():
		hero.add_xp(REEVE_XP)
	set_objective(&"obj_reeve", "done")
	if objective_state("sec_hands") == "active":
		set_objective(&"sec_hands", "done")
	set_mission_flag("e5m3_time", int(victory_time))
	set_mission_flag("e5m3_pocketed", gifts_taken.size())
	set_mission_flag("e5m3_tombstones", stones_read.size())
	clear_waves()
	for v: Variant in gravewardens + magpies:
		if is_instance_valid(v) and (v as Unit).is_alive():
			set_truce([v], true, Unit.TRUCE_ALL)
			(v as Unit).command_stop()
	play_cutscene(&"e5m3_found", _found_end)


func _found_end() -> void:
	for id in ["L20", "L21", "L22", "L23", "L24"]:
		say_l(id)
	set_objective(&"obj_malrik", "done")
	win(1.0)


func _on_malrik_level(_u: Unit, level: int) -> void:
	if level >= 2 and fire_once(&"E14") and hud:
		hud.show_message(HINT_SIPHON, 12.0)


func _on_player_hero_fell() -> void:
	fire_once(&"E17")
	say_l("L25")
	set_objective(&"obj_malrik", "failed")
	if hud:
		hud.show_message(MSG_CAUGHT, 4.0)
	super()


# ---------------------------------------------------------------- briefing, objectives

func briefing() -> Dictionary:
	return {
		"title": _title_line(),
		"paragraphs": BRIEFING_PARAGRAPHS.duplicate(),
		"objectives": [objective_text(&"obj_secrets", false), objective_text(&"obj_bell", false),
				objective_text(&"obj_reeve", false)],
		"rule": Loc.sink(objective_text(&"obj_malrik")),
	}


func objective_text(id: StringName, with_counter := true) -> String:
	match id:
		&"obj_secrets":
			if with_counter:
				return "Read the Reeve's secrets in the crypts (%d / 3)" % secrets_read.size()
			return "Read the Reeve's secrets in the crypts"
		&"obj_bell":
			if with_counter and objective_state("obj_bell") == "active" and mission_time() < bell_at():
				return "Ring the Lantern House bell at midnight (%s)" % MissionE5Base.mmss(bell_at())
			return "Ring the Lantern House bell"
		&"obj_reeve":
			return "Stand up to Reeve Pike"
		&"obj_malrik":
			return "Malrik must not be caught"
		&"sec_quiet":
			if with_counter:
				return "Never wake Wickmoor (alarm %d / 3)" % alarm
			return "Never wake Wickmoor"
		&"sec_hands":
			return "Take nothing from the dead"
	return String(id)


func _objective_extra(id: StringName, _o: Dictionary) -> Dictionary:
	match id:
		&"obj_secrets":
			var pos: Array = []
			for cid: StringName in CRYPTS:
				if not secrets_read.has(String(cid)):
					pos.append(CRYPTS[cid][4])
			return {"counter": secrets_read.size(), "goal": 3, "positions": pos,
					"detail": Loc.t("Tombstones read {n} / 6", {"n": stones_read.size()})}
		&"obj_bell":
			return {"position": BELL}
		&"sec_quiet":
			return {"counter": alarm, "goal": 3}
	return {}


# ---------------------------------------------------------------- looks (placeholders: E5M3.V1)

func _build_looks() -> void:
	if _SIM.enabled:
		return
	for z: Array in ZONES:
		ground_disc(z[0], float(z[1]), Color(0.30, 0.12, 0.45, 0.35))
	for id: StringName in CRYPTS:
		ground_disc(CRYPTS[id][1], float(CRYPTS[id][3]), Color(0.30, 0.12, 0.45, 0.35))
		var s := ground_disc(CRYPTS[id][4], READ_R, Color(0.9, 0.85, 0.5, 0.45), 0.05)
		_spot_looks[String(id)] = s
	for i in LAMPS.size():
		var warm := ground_disc(LAMPS[i], LAMP_R, Color(1.0, 0.72, 0.35, 0.16), 0.035)
		var violet := ground_disc(LAMPS[i], LAMP_R, Color(0.30, 0.12, 0.45, 0.35), 0.036)
		var post := box_prop(LAMPS[i], Vector3(0.18, 2.6, 0.18), Color(0.15, 0.14, 0.14))
		var flame := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.22
		sm.height = 0.44
		flame.mesh = sm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.8, 0.4)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.7, 0.3)
		mat.emission_energy_multiplier = 3.0
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		flame.material_override = mat
		post.add_child(flame)
		flame.position = Vector3(0.0, 2.75, 0.0)
		_lamp_looks[i] = [warm, violet, flame]
		_lamp_look(i)
	for i in GIFTS.size():
		_spot_looks["R%d" % i] = ground_disc(GIFTS[i][0], 0.8, Color(1.0, 0.85, 0.3, 0.7), 0.05)


func _lamp_look(i: int) -> void:
	var l: Variant = _lamp_looks.get(i)
	if l == null:
		return
	var dark := dark_lamps.has(i)
	for k in 3:
		var n: Variant = (l as Array)[k]
		if n and is_instance_valid(n):
			(n as Node3D).visible = (k == 1) == dark


# ---------------------------------------------------------------- save / load

func load_state(d: Dictionary, nodes: Dictionary = {}) -> void:
	super(d, nodes)
	for i in LAMPS.size():
		_lamp_look(i)
	for i in gifts_taken:
		var look: Variant = _spot_looks.get("R%d" % i)
		if look and is_instance_valid(look):
			(look as Node3D).visible = false
	_set_candle(candle_lit, false)
	for v: Variant in gravewardens:
		if not is_instance_valid(v):
			continue
		var w := v as Unit
		restore_guard(w, _warden_guard.bind(w))
		if w.get_meta(&"e5_mode", &"") == &"out" and not is_dormant(w):
			set_dormant(w, true)
	if reeve and is_instance_valid(reeve):
		restore_guard(reeve, _reeve_guard)
		_reeve_inside(not has_fired(&"E13"))
	for v: Variant in shades.duplicate():
		if not is_instance_valid(v):
			shades.erase(v)



# ---------------------------------------------------------------- every frame

func _physics_process(delta: float) -> void:
	super(delta)
	if not match_started or game_over or world_is_held or save_restoring:
		return
	tick_scripted(delta)
	if is_ending():
		return
	if _candle_marker and is_instance_valid(_candle_marker) and hero_alive():
		_candle_marker.global_position = hero.global_position
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = 0.25
	shades = shades.filter(func(s: Variant) -> bool: return is_instance_valid(s) and (s as Unit).is_alive())
	_tick_stealth(0.25)
	_tick_lamps(0.25)
	_tick_graves(0.25)
	_tick_reading(0.25)
	_tick_gifts()
	_tick_bell(0.25)
	_tick_reeve(0.25)
	_tick_wake(0.25)
	_tick_wardens()
	_tick_magpies()
	if alarm > 0 and _wake_ends_at < 0.0 and _decay_at > 0.0 and mission_time() >= _decay_at:
		alarm -= 1
		_decay_at = mission_time() + ALARM_DECAY if alarm > 0 else -1.0
	objectives_changed.emit()
	if hud and mission_hud == null:
		hud.set_objective(_objective_text())
