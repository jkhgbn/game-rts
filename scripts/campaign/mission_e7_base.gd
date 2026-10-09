class_name MissionE7Base
extends MissionE6Base
## Episode 7 "Gold for Fire" shared rules (docs/design/mission-e7-01.md .. -04.md, campaign-outline.md 3.7), used by
## MissionE7_01..MissionE7_04 (each still a MissionBase through MissionE6Base / MissionE5Base: lines by id, local unit
## types saved by id, story helpers, scripted targets, waves):
## - Torvald's track: flags only (CampaignState "save_items": false), his essence (50 %, cap 1 500) in the int flag
##   CampaignState.TORVALD_ESSENCE_FLAG, the Heartfrost Splinter as a mission-side modifier on Torvald (no ItemType yet);
## - "Two Harbours" (e7m1 / e7m2 / e7m4) is Crown Hollow's own ground re-dressed (no two_harbours.map yet): the river is
##   the strait, the Crown Isle is the Tollrock (a side capture zone, the toll), the west bank is Adamarch (Torvald south-
##   west, Malrik north-west), the east bank Aurivane (Ysolde north-east = the ENEMY keep, Vessa south-east); the real
##   trade stack (posts renamed: Diamond Harbour, Admiralty Quay...), no Magpies / Lodges;
## - the Dragon Auction (mission-e7-01.md 6) and the auction dragons (6.3) as mission code: bids by a mission button
##   panel (not the Bazaar card), Aurivane's scripted curve and ceiling, the rock's word, a 3:00 bond, the 15 % rest;
## - the episode's story kinds as local unit types (Gilded Spear, Facetguard, gold knife, Seraphine, Dacian, the dragons,
##   Mother Hush as a boss, the herald, the Outwall people, the masks, the War Mammoth) on existing models.

const TORVALD_ESSENCE_CAP := 1500
const E7_SEED := 71

## Crown Hollow re-dressed as the Coinwater.
const ROCK := Vector3.ZERO                          ## The Tollrock (Crown Isle centre); the lighthouse point.
const ROCK_R := 6.0
const ROCK_CAPTURE := 15.0
const ROOST := Vector3(4.0, 0.0, -4.0)              ## Where an auctioned dragon lands (east half of the isle).
const CHAIR := Vector3(-5.0, 0.0, 5.0)              ## The Master's stone chair on the west rim.
const NORTH_CAUSEWAY := Vector3(-9.0, 0.0, 9.0)     ## Adamarch's causeway (West Crown Bridge).
const SOUTH_CAUSEWAY := Vector3(9.0, 0.0, -9.0)     ## Aurivane's causeway (East Crown Bridge).
const NORTH_FOOT := Vector3(-16.0, 0.0, 16.0)
const SOUTH_FOOT := Vector3(16.0, 0.0, -16.0)
const GOLD_SHOAL := Vector3(8.5, 0.0, 34.0)         ## Willow Ford: Vessa's way to Torvald's harbour.
const SILVER_SHOAL := Vector3(-8.5, 0.0, -34.0)     ## Reed Ford: Ysolde's way to Malrik's quarter.
const RIME_KEEP := Vector3(-43.0, 0.0, 43.0)
const FROST_HALL := Vector3(-27.0, 0.0, 45.0)
const SNOW_LODGE := Vector3(-50.0, 0.0, 46.0)
const BAZAAR_SPOT := Vector3(-45.0, 0.0, 27.0)
const PLAYER_RALLY := Vector3(-28.0, 0.0, 28.0)
const ALDRA_SPOT := Vector3(-38.0, 0.0, 39.0)
const HARBOUR := Vector3(-55.0, 0.0, 10.0)          ## The Diamond Harbour target, beside the Heron Ford post.
const MALRIK_KEEP := Vector3(-30.0, 0.0, -34.0)
const MALRIK_HALL := Vector3(-38.0, 0.0, -22.0)
const MALRIK_HOVEL := Vector3(-22.0, 0.0, -42.0)
const MALRIK_START := Vector3(-24.0, 0.0, -28.0)
const MALRIK_RALLY := Vector3(-22.0, 0.0, -20.0)
const MALRIK_NODE_B := Vector3(-46.0, 0.0, -28.0)
const YSOLDE_KEEP := Vector3(43.0, 0.0, -43.0)      ## Crown Hollow's ENEMY keep (Skirmish builds it).
const GROVE_HALL := Vector3(27.0, 0.0, -45.0)
const YSOLDE_RALLY := Vector3(28.0, 0.0, -28.0)
const VESSA_KEEP := Vector3(32.0, 0.0, 34.0)
const EMBER_HALL := Vector3(38.0, 0.0, 22.0)
const VESSA_RALLY := Vector3(24.0, 0.0, 26.0)
const AURIVANE_GATES: Array[Vector3] = [Vector3(56.0, 0.0, -20.0), Vector3(56.0, 0.0, 20.0)]

const POST_NAMES := {&"heron_ford": "Diamond Harbour", &"saltgate": "Admiralty Quay", &"millstone_cross": "Gilt Quay",
		&"lantern_wharf": "Sun Harbour"}

## Heartfrost Splinter (mission-e7-01.md "The Heartfrost Splinter"): stats as a named modifier.
const SPLINTER_ID := &"artifact:heartfrost_splinter"
const SPLINTER_STATS := {"max_hp": 80.0, "armor": 10.0, "mana_regen": 0.5}

const AUCTION_WINDOW := 45.0
const DRAGON_BOND := 180.0
const DRAGON_REST := 0.15
const DRAGON_RANGE := 25.0

const E7_SPEAKER_COLORS := {&"torvald": Color(0.55, 0.80, 1.00), &"aldra": Color(0.62, 0.95, 0.88),
		&"malrik": Color(0.7, 0.3, 1.0), &"ossavar": Color(0.95, 0.70, 0.30), &"herald": Color(0.85, 0.80, 0.60),
		&"dacian": Color(1.00, 0.80, 0.35), &"seraphine": Color(0.80, 0.88, 1.00), &"vessa": Color(1.0, 0.45, 0.1),
		&"ysolde": Color(0.55, 0.90, 0.35), &"obren": Color(1.0, 0.80, 0.25), &"hush": Color(0.60, 0.50, 0.75),
		&"brannet": Color(0.75, 0.62, 0.45), &"diamond_archon": Color(0.92, 0.94, 1.00)}
const E7_SPEAKER_NAMES := {&"torvald": "Torvald", &"aldra": "Aldra", &"malrik": "Malrik", &"ossavar": "Ossavar",
		&"herald": "Herald", &"dacian": "Dacian", &"seraphine": "Seraphine", &"vessa": "Vessa", &"ysolde": "Ysolde",
		&"obren": "Obren", &"hush": "Mother Hush", &"brannet": "Brannet", &"diamond_archon": "The Diamond Archon"}

const MSG_NO_BAZAAR := "No Bazaar"
const MSG_NO_GOLD := "Not enough gold"
const MSG_LEAD := "You already lead"
const MSG_NO_AUCTION := "No auction"
const MSG_SHORT := "Your coffers are short"
const MSG_HESITATES := "Aurivane hesitates..."

signal auction_closed(dragon_id: StringName, side: int, price: int)

var flag_override: Dictionary = {}       ## Tests: campaign flags used instead of the save.
var no_save_fallback := false            ## Read only: the previous mission is not won in the save.
var rock: MissionZone                    ## Read only: the Tollrock point (Two Harbours missions).
var rock_word_pct := 0.10
var toll_paid := 0                       ## Read only: gold the toll paid side 0.
var auction := {}                        ## Read only: the open auction (empty = none).
var auction_log: Array[String] = []      ## Read only: "id:side:price" per hammer.
var dragons := {}                        ## Read only: id -> {unit, side, until, rest_until}
var harbour: MissionE6Base.E6Target                    ## Read only: the Diamond Harbour (e7m1 / e7m4).

var _toll_t := 0.0
var _dragon_t := 0.0
var _bid_panel: Control
var _ai_rng := RandomNumberGenerator.new()


func _init() -> void:
	super()
	player_kingdom = &"ice"
	enemy_kingdom = &"nature"
	speaker_colors = E7_SPEAKER_COLORS.duplicate()
	speaker_names = E7_SPEAKER_NAMES.duplicate()
	_ai_rng.seed = E7_SEED
	make_e7_units()


## The Two Harbours switches (Crown Hollow's river and trade stack on; points, camps, beasts, taverns off).
func use_two_harbours() -> void:
	trade_enabled = true
	river_enabled = true


## Tier, casters, titans and the instant loss of Torvald; the Episode's essence trickle and kill essence.
static func e7_config(c: MissionConfig, max_tier: int) -> void:
	c.tiers_enabled = true
	c.max_tier = max_tier
	c.bots_upgrade = false
	c.casters_enabled = true
	c.t3_enabled = max_tier >= 3
	c.helpers_enabled = max_tier >= 3
	c.titans_enabled = false
	c.instant_loss_on_wizard_death = true
	c.essence_trickle = true
	c.kill_essence = true


func _use_map_dressing() -> bool:
	return true


func _lighting_preset() -> StringName:
	return &"warm"


# ---------------------------------------------------------------- the episode's story kinds

func make_e7_units() -> void:
	local_unit("flame_guard", "gilded_spear", "Gilded Spear", {"max_hp": 180.0, "armor": 10.0, "attack_damage": 14.0,
			"attack_range": 2.2, "attack_cooldown": 1.2, "move_speed": 4.6, "cost": 120, "commandable": false,
			"faction": &"fire"})
	local_unit("rimeshield", "facetguard", "Facetguard", {"max_hp": 220.0, "armor": 20.0, "attack_damage": 16.0,
			"attack_range": 2.0, "attack_cooldown": 1.4, "move_speed": 4.0, "cost": 140, "commandable": false,
			"pop": 0})
	local_unit("shade", "gold_knife", "Gold-cloaked Knife", {"max_hp": 150.0, "armor": 5.0, "attack_damage": 14.0,
			"attack_cooldown": 1.0, "move_speed": 5.4, "cost": 110, "commandable": false})
	local_unit("shardguard", "seraphine_story", "Seraphine", {"max_hp": 1000.0, "armor": 25.0, "attack_damage": 28.0,
			"attack_range": 1.7, "attack_cooldown": 1.1, "move_speed": 4.6, "pop": 0, "kill_xp": 0, "cost": 600,
			"commandable": false, "aggro_range": 7.0})
	local_unit("flame_guard", "dacian_story", "Dacian", {"max_hp": 950.0, "armor": 10.0, "attack_damage": 36.0,
			"attack_range": 1.9, "attack_cooldown": 1.4, "move_speed": 5.0, "pop": 0, "kill_xp": 0, "cost": 600,
			"commandable": false, "aggro_range": 7.0})
	var fly := {"pop": 0, "kill_xp": 0, "commandable": false, "attack_range": 6.0, "aggro_range": 12.0}
	_dragon_type("gilt_dragon", "Kesh", fly, 1400.0, 5.0, 16.0, 2.2, 5.5)
	_dragon_type("prism_dragon", "Morrow-of-Glass", fly, 1700.0, 10.0, 14.0, 2.4, 5.0)
	_dragon_type("sunwake", "Sunwake", fly, 1400.0, 5.0, 16.0, 2.2, 5.5)
	_dragon_type("ossavar_story", "Ossavar", fly, 3600.0, 20.0, 30.0, 2.6, 4.8)
	local_unit("mother_hush", "hush_story", "Mother Hush", {"max_hp": 1100.0, "armor": 10.0, "attack_damage": 39.0,
			"attack_cooldown": 1.0, "move_speed": 5.4, "pop": 0, "kill_xp": 0, "cost": 700, "commandable": false})
	local_unit("cinder_hand", "herald_story", "Herald", {"is_worker": false, "attack_damage": 0.0, "aggro_range": 0.0,
			"pop": 0, "kill_xp": 0, "commandable": false})
	local_unit("rime_seer", "aldra_npc", "Aldra", {"attack_damage": 0.0, "aggro_range": 0.0, "pop": 0, "kill_xp": 0,
			"commandable": false})
	local_unit("rime_hauler", "outwall_docker", "Outwall Docker", {"is_worker": false, "max_hp": 45.0, "armor": 0.0,
			"attack_damage": 0.0, "aggro_range": 0.0, "move_speed": 4.2, "pop": 0, "kill_xp": 15, "cost": 30,
			"commandable": false})
	local_unit("rime_hauler", "brannet_story", "Brannet", {"is_worker": false, "max_hp": 400.0, "attack_damage": 0.0,
			"aggro_range": 0.0, "move_speed": 4.2, "pop": 0, "kill_xp": 0, "commandable": false})
	local_unit("hollow_oathsworn", "mask_captain", "Mask Captain", {"max_hp": 900.0, "armor": 15.0,
			"attack_damage": 30.0, "attack_cooldown": 1.2, "move_speed": 4.6, "kill_xp": 300, "cost": 800,
			"commandable": false})
	local_unit("ironhide_tusker", "war_mammoth", "War Mammoth", {"max_hp": 2000.0, "armor": 30.0, "attack_damage": 40.0,
			"attack_range": 2.4, "attack_cooldown": 2.2, "move_speed": 3.4, "pop": 0, "kill_xp": 0, "cost": 650,
			"commandable": true, "faction": &"ice", "neutral_leash": false})
	for row: Array in [["shade", "Masked Shade"], ["grave_hound", "Masked Hound"], ["nightbolt", "Masked Nightbolt"],
			["barrow_ghoul", "Masked Ghoul"], ["hexweaver", "Masked Hexweaver"], ["shadow_knight", "Masked Knight"]]:
		local_unit(String(row[0]), "masked_" + String(row[0]), String(row[1]), {"commandable": false})


func _dragon_type(id: String, display: String, base: Dictionary, hp: float, armor: float, dmg: float, cd: float,
		speed: float) -> void:
	var f := base.duplicate()
	f["max_hp"] = hp
	f["armor"] = armor
	f["attack_damage"] = dmg
	f["attack_cooldown"] = cd
	f["move_speed"] = speed
	f["cost"] = int(hp * 0.5)
	local_unit("stormcrest_roc", id, display, f)


## A wizard of `kingdom` on `team` (an enemy city's second wizard on the ENEMY team; not a seat hero).
func make_kingdom_wizard(kingdom: StringName, team: int) -> Wizard:
	var had := seat_kingdoms.has(team)
	var old: Variant = seat_kingdoms.get(team)
	seat_kingdoms[team] = kingdom
	var w := _make_wizard(team)
	if had:
		seat_kingdoms[team] = old
	else:
		seat_kingdoms.erase(team)
	return w


## A story wizard (enemy or ally) at `at`, raised to `level` with `spells`, items, and the scripted mark.
func story_wizard(kingdom: StringName, team: int, at: Vector3, level: int, spells: Array) -> Wizard:
	var w := make_kingdom_wizard(kingdom, team)
	_spawn(w, team as Unit.Team, at)
	_claim_wizard(w, team)
	raise_wizard(w, level, spells)
	ItemDrops.ensure_inventory(w)
	mark_scripted(w)
	return w


## An unkillable story unit: at 0 HP it stays at 1 HP and `on_down` (Callable(u)) runs once per fall.
func guard_life(u: Unit, on_down: Callable = Callable()) -> void:
	if u == null:
		return
	u.death_guard = func(_a: Variant) -> bool:
		u.hp = 1.0
		if on_down.is_valid():
			on_down.call(u)
		return true


## A story NPC: dormant, at peace with everyone, never a target.
func story_npc(type_id: String, at: Vector3, team: int = Unit.Team.PLAYER) -> Unit:
	var u := make_unit(type_id)
	_spawn(u, team as Unit.Team, at)
	mark_scripted(u)
	set_truce([u], true, Unit.TRUCE_ALL)
	set_dormant(u, true)
	return u


# ---------------------------------------------------------------- Torvald's track

func _flags() -> Dictionary:
	if not flag_override.is_empty():
		return flag_override
	return CampaignState.open(campaign_save_path).flags


func flag_on(id: String) -> bool:
	if no_save_fallback and flag_override.is_empty():
		return false
	var v: Variant = _flags().get(id, false)
	return v == true or (v is int and int(v) != 0)


func flag_int(id: String, default := 0) -> int:
	if no_save_fallback and flag_override.is_empty():
		return default
	var v: Variant = _flags().get(id, default)
	return int(v) if (v is int or v is float) else (1 if v == true else default)


## no_save_fallback = `previous` is not completed in the save (and no flag override).
func read_save(previous: StringName) -> void:
	if previous == &"":
		no_save_fallback = false
		return
	no_save_fallback = flag_override.is_empty() and not CampaignState.open(campaign_save_path).is_completed(previous)


## Adds Torvald's carried essence (the flag; `fallback` without a save) on top of the mission's start essence.
func carry_torvald_essence(fallback: int) -> void:
	var bank := EssenceBank.for_team(Unit.Team.PLAYER)
	if bank == null:
		return
	var carried := fallback if no_save_fallback else int(_flags().get(CampaignState.TORVALD_ESSENCE_FLAG, 0))
	if carried > 0:
		bank.add(carried)


## Torvald's essence at victory (+ the `bonus` of done secondaries), 50 %, cap 1 500, into the track flag.
func record_torvald_essence(bonus: int) -> void:
	var bank := EssenceBank.for_team(Unit.Team.PLAYER)
	var essence := (bank.essence if bank else 0) + bonus
	set_mission_flag(CampaignState.TORVALD_ESSENCE_FLAG, mini(TORVALD_ESSENCE_CAP, essence / 2))


## The Heartfrost Splinter on Torvald (mission-side until the items owner adds the ItemType).
func apply_splinter(w: Unit) -> void:
	if w == null:
		return
	w.add_modifier(SPLINTER_ID, SPLINTER_STATS)
	w.hp = w.max_hp


# ---------------------------------------------------------------- Two Harbours: seats

func start_position(team: int) -> Vector3:
	if team == Teams.ALLY:
		return MALRIK_START
	return super(team)


func base_center(team: int) -> Vector3:
	if team == Teams.ALLY:
		return MALRIK_KEEP
	return super(team)


func respawn_point(team: int) -> Vector3:
	var k := keep_of(team)
	if k:
		return k.spawn_point()
	if team == Teams.ALLY:
		return MALRIK_KEEP + Vector3(4.0, 0.0, 4.0)
	return super(team)


func node_of(team: int, suffix: String) -> CrystalNode:
	if team != Teams.ALLY:
		return super(team, suffix)
	var id: StringName = &"node_fire_rich" if suffix == "a" else &"e7_malrik_b"
	var v: Variant = crystal_nodes.get(id)
	if v == null or not is_instance_valid(v):
		return null
	var n := v as CrystalNode
	return n if n != null and not n.is_depleted() else null


## Commander (MT2 contract): a Crown Hollow point (ENEMY frame, north-east) mirrored into the seat's corner.
func bot_point(team: int, p: Vector3) -> Vector3:
	if team == Teams.ALLY:
		return Vector3(-p.x, p.y, p.z)
	if team == Unit.Team.PLAYER:
		return -p
	return p


func bot_vector(team: int, v: Vector3) -> Vector3:
	return bot_point(team, v)


func natural_hall_spot(team: int) -> Vector3:
	return Vector3.INF if team == Teams.ALLY else super(team)


func rich_hall_spot(team: int) -> Vector3:
	return Vector3.INF if team == Teams.ALLY else super(team)


func market_slot(team: int) -> Vector3:
	return Vector3.INF if team == Teams.ALLY else super(team)


func tower_slot(team: int, which: StringName) -> Vector3:
	return Vector3.INF if team == Teams.ALLY else super(team, which)


## Malrik's Commander profile: Shadow knobs, never attacks (the mission's pushes are its attacks), few workers, no
## expansion, `soldiers` at most, no trade / champions / map fill.
func ally_profile(id: StringName, soldiers: int) -> AIProfile:
	var diff := clampi(mission_difficulty, 0, 2)
	var p := AIProfile.for_difficulty(diff)
	p.id = id
	p.profile_id = id
	p.min_attack_pop = 99
	p.launch_attacks = false
	p.attack_full_pop = 0
	p.first_attack_by = 0.0
	p.worker_target_home = 5
	p.worker_target_expanded = 5
	p.worker_target_x2 = 5
	p.second_expansion = false
	p.expand_time = 1.0e6
	p.max_soldiers = soldiers
	p.build_rows = PackedStringArray(["H1"])
	p.rebuild = false
	p.hero_stays_home = true
	p.malrik_joins = AIProfile.MalrikJoins.NEVER
	p.champion_max = 0
	p.trade = false
	p.map_fill = false
	p.item_build = PackedStringArray()
	return p


func add_seat_commander(seat: int, profile: AIProfile) -> Node:
	var path := "res://scripts/ai/commander.gd"
	if not ResourceLoader.exists(path):
		return null
	var script := load(path) as Script
	if script == null or not script.can_instantiate():
		return null
	var bot: Node = script.new()
	bot.name = "Bot%d" % seat
	bot.set(&"team", seat)
	bot.set(&"profile", profile)
	add_child(bot)
	commanders.append(bot)
	return bot


## The Two Harbours additions under the nav region (call from _build_map after super): Malrik's second node.
func add_two_harbours_map() -> void:
	_add_crystal_node(&"e7_malrik_b", MALRIK_NODE_B, 2000)
	ground_disc(ROCK, ROCK_R, Color(0.95, 0.85, 0.55, 0.22), 0.04)
	ground_disc(CHAIR, 1.2, Color(0.70, 0.68, 0.62, 0.9), 0.05)
	box_prop(CHAIR, Vector3(1.2, 1.6, 1.0), Color(0.72, 0.70, 0.66), PI * 0.25)


## A building of `type_id` near `at` (the nearest free spot), complete, for `team`.
func place_building(type_id: String, at: Vector3, team: int) -> Building:
	var t := BuildingType.find(type_id)
	if t == null:
		return null
	var p := build_grid.find_spot(t, at, team)
	if p == Vector3.INF:
		p = at
	return build_grid.spawn_complete(t, p, team)


# ---------------------------------------------------------------- trade (the real stack, re-dressed)

## Posts renamed, Magpies and the Hunters' Lodge removed, the posts' clock shifted so they open at `open_at`
## (skirmish 4:00), side 0's gold at 0.
func setup_e7_trade(open_at: float) -> void:
	_setup_trade()
	for p: TradePost in trade_posts:
		if POST_NAMES.has(p.post_id):
			p.display_name = String(POST_NAMES[p.post_id])
	for s: Variant in [thieves_guild, hunters_guild]:
		if s != null and is_instance_valid(s):
			(s as Node).queue_free()
	thieves_guild = null
	hunters_guild = null
	if trade_network:
		var shift := 240.0 - open_at
		trade_network.match_time_source = func() -> float: return mission_time() + shift
	var gb := GoldBank.for_team(Unit.Team.PLAYER)
	if gb:
		gb.gold = 0
		gb.changed.emit(0)


func post_named(id: StringName) -> TradePost:
	for p: TradePost in trade_posts:
		if p.post_id == id:
			return p
	return null


func gold() -> int:
	var gb := GoldBank.for_team(Unit.Team.PLAYER)
	return gb.gold if gb else 0


func add_gold(n: int) -> void:
	var gb := GoldBank.for_team(Unit.Team.PLAYER)
	if gb and n > 0:
		gb.add(n, &"reward")


# ---------------------------------------------------------------- the Tollrock

func add_rock_zone() -> MissionZone:
	rock = MissionZone.new()
	rock.zone_id = &"tollrock"
	rock.display_name = "The Tollrock"
	rock.radius = ROCK_R
	rock.capture_time = ROCK_CAPTURE
	add_child(rock)
	rock.global_position = ROCK
	return rock


func rock_owner() -> int:
	return rock.owner_side if rock else -1


## The rock's tick: the capture, then the toll (+30 gold / min to side 0, 5 every 10 s).
func tick_rock(dt: float) -> void:
	if rock == null:
		return
	rock.tick(dt)
	_toll_t += dt
	if _toll_t >= 10.0:
		_toll_t -= 10.0
		if rock.owner_side == 0:
			add_gold(5)
			toll_paid += 5


# ---------------------------------------------------------------- the auction dragons (6.3)

## Spawns dragon `id` (a local type) at `at`, NEUTRAL, asleep and at peace (not yet bonded).
func spawn_dragon(id: String, at: Vector3) -> Unit:
	var u := make_unit(id)
	_spawn(u, Unit.Team.NEUTRAL, at)
	mark_scripted(u)
	set_truce([u], true, Unit.TRUCE_ALL)
	set_dormant(u, true)
	var m := u.get_model()
	if m:
		m.scale = Vector3.ONE * (2.0 if id == "ossavar_story" else 1.5)
	dragons[id] = {"unit": u, "side": -1, "until": 0.0, "rest_until": 0.0}
	u.death_guard = func(_a: Variant) -> bool:
		u.hp = maxf(1.0, u.max_hp * DRAGON_REST)
		_rest_dragon(StringName(id), 30.0)
		return true
	return u


func dragon(id: String) -> Unit:
	var d: Dictionary = dragons.get(id, {})
	var u: Variant = d.get("unit")
	return u as Unit if u != null and is_instance_valid(u) else null


## Bonds dragon `id` to `side` (0 = Torvald's, 1 = the enemy) for `seconds` (<= 0 = until released).
func bind_dragon(id: String, side: int, seconds: float) -> void:
	var u := dragon(id)
	if u == null:
		return
	var d: Dictionary = dragons[id]
	d["side"] = side
	d["until"] = mission_time() + seconds if seconds > 0.0 else 1.0e9
	d["rest_until"] = 0.0
	u.team = (Unit.Team.PLAYER if side == 0 else Unit.Team.ENEMY) as Unit.Team
	set_truce([u], false, Unit.TRUCE_ALL)
	set_dormant(u, false)


## `u` leaves the map after `seconds` if still alive (a weak reference: a freed unit is simply skipped).
func leave_later(u: Unit, seconds: float) -> void:
	var ref: WeakRef = weakref(u)
	after(seconds, func() -> void:
		var x := ref.get_ref() as Unit
		if x and x.is_alive():
			x.leave_map())


## Releases dragon `id`: back to the roost, NEUTRAL, at peace (`leave` = it flies off the map for good).
func release_dragon(id: String, leave := false) -> void:
	var u := dragon(id)
	if u == null:
		return
	var d: Dictionary = dragons[id]
	d["side"] = -1
	u.team = Unit.Team.NEUTRAL
	u.command_stop()
	set_truce([u], true, Unit.TRUCE_ALL)
	if leave:
		u.command_move(Vector3(-20.0, 0.0, -62.0))
		leave_later(u, 12.0)
		dragons.erase(id)
	else:
		u.command_move(ROOST)


func _rest_dragon(id: StringName, seconds: float) -> void:
	var d: Dictionary = dragons.get(String(id), {})
	if d.is_empty():
		return
	d["rest_until"] = mission_time() + seconds
	var u := dragon(String(id))
	if u:
		set_truce([u], true, Unit.TRUCE_ALL)
		u.command_move(ROOST + Vector3(0.0, 0.0, -50.0) if int(d["side"]) == 1 else CHAIR + Vector3(-50.0, 0.0, 0.0))


## Side 0's largest army group centre (soldiers only) or the hero.
func _side0_center() -> Vector3:
	var pts: Array[Vector3] = []
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and Teams.side_of(int(u.team)) == 0 and not u.is_worker() and not is_dormant(u) \
				and not dragons_has_unit(u):
			pts.append(u.global_position)
	if pts.is_empty():
		return hero_pos()
	var best := pts[0]
	var best_n := 0
	for p in pts:
		var c := 0
		for q in pts:
			if _flat(p, q) < 14.0:
				c += 1
		if c > best_n:
			best_n = c
			best = p
	return best


func dragons_has_unit(u: Unit) -> bool:
	for id: String in dragons:
		if (dragons[id] as Dictionary).get("unit") == u:
			return true
	return false


## Override: where a dragon bonded to side 1 strikes first (e7m1: the Diamond Harbour).
func _dragon_enemy_goal() -> Node3D:
	return harbour if harbour != null and is_instance_valid(harbour) and harbour.is_alive() else keep


func _tick_dragons() -> void:
	var t := mission_time()
	for id: String in dragons.keys():
		var d: Dictionary = dragons[id]
		var u := dragon(id)
		if u == null or not u.is_alive():
			continue
		var side := int(d["side"])
		if side < 0:
			continue
		if t >= float(d["until"]):
			release_dragon(id)
			_on_dragon_bond_ended(StringName(id), side)
			continue
		if float(d["rest_until"]) > 0.0:
			if t < float(d["rest_until"]):
				continue
			d["rest_until"] = 0.0
			u.hp = maxf(u.hp, u.max_hp * 0.5)
			set_truce([u], false, Unit.TRUCE_ALL)
		if u.attack_target != null and is_instance_valid(u.attack_target) and _flat(u.global_position, u.attack_target.global_position) < 10.0:
			continue
		if side == 0:
			var c := _side0_center()
			var foe := foe_near(c, DRAGON_RANGE, Unit.Team.PLAYER)
			if foe:
				u.command_attack(foe)
			elif _flat(u.global_position, c) > 8.0:
				u.command_move(c + Vector3(2.0, 0.0, -2.0))
		else:
			var goal := _dragon_enemy_goal()
			var foe := _player_near(goal.global_position if goal else u.global_position, 20.0)
			if foe:
				u.command_attack(foe)
			elif goal and goal.has_method(&"take_damage"):
				u.command_attack(goal)
			elif goal and _flat(u.global_position, goal.global_position) > 6.0:
				u.command_attack_move(goal.global_position)


## The nearest living side-0 unit within `r` of `at`.
func _player_near(at: Vector3, r: float) -> Unit:
	var best: Unit = null
	var dd := r
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or not u.is_alive() or is_dormant(u) or Teams.side_of(int(u.team)) != 0 \
				or StringName(u.get_meta(Unit.TRUCE_META, &"")) == Unit.TRUCE_ALL:
			continue
		var d := _flat(u.global_position, at)
		if d < dd:
			dd = d
			best = u
	return best


## Override: a dragon's bond ran out.
func _on_dragon_bond_ended(_id: StringName, _side: int) -> void:
	pass


# ---------------------------------------------------------------- the Dragon Auction (6)

## Opens an auction for dragon `id` (`display` name), Aurivane's `ceiling`; the dragon lands on the roost.
func open_auction(id: String, display: String, ceiling: int) -> void:
	var u := dragon(id)
	if u:
		u.global_position = ROOST
		u.command_stop()
	auction = {"id": id, "name": display, "ceiling": ceiling, "opened": mission_time(),
			"ends": mission_time() + AUCTION_WINDOW, "bids": [0, 0], "next_ai": mission_time() + 5.0, "hesitant": false}
	if hud:
		_bid_panel = mission_button_panel("AuctionPanel", [[Loc.t("Bid +50"), func() -> void: _ui_bid(50)],
				[Loc.t("Bid +100"), func() -> void: _ui_bid(100)]])
	objectives_changed.emit()


func auction_open() -> bool:
	return not auction.is_empty()


## True once dragon `id` went under the hammer.
func sold(id: String) -> bool:
	for row: String in auction_log:
		if row.begins_with(id + ":"):
			return true
	return false


func _ui_bid(n: int) -> void:
	var r := player_bid(n)
	if r != "" and hud:
		hud.show_message(Loc.sink(r), 2.5)


## Side 0 raises its bid by `add`: "" or the refusal ("No auction", "No Bazaar", "Not enough gold", "You already lead").
func player_bid(add: int) -> String:
	if auction.is_empty():
		return MSG_NO_AUCTION
	if Market.of_team(Unit.Team.PLAYER) == null:
		return MSG_NO_BAZAAR
	var bids: Array = auction["bids"]
	# a lead refuses a raise, except while Aurivane holds the rock (its word would still win within the margin)
	if int(bids[0]) > int(bids[1]) and int(bids[0]) > 0 and rock_owner() != 1:
		return MSG_LEAD
	var want := maxi(int(bids[1]), int(bids[0])) + add
	if gold() < want:
		return MSG_NO_GOLD
	bids[0] = want
	auction["next_ai"] = mission_time() + _ai_rng.randf_range(3.0, 6.0)
	objectives_changed.emit()
	return ""


func _tick_auction() -> void:
	if auction.is_empty():
		return
	var t := mission_time()
	var bids: Array = auction["bids"]
	var ceiling := int(auction["ceiling"])
	if t >= float(auction["next_ai"]):
		if int(bids[1]) == 0 and int(bids[0]) + 50 <= ceiling:
			bids[1] = maxi(100, int(bids[0]) + 50)
			auction["next_ai"] = t + 1.0e9
		elif int(bids[0]) >= int(bids[1]):
			var want := int(bids[0]) + 50
			if want <= ceiling:
				bids[1] = want
				auction["next_ai"] = t + 1.0e9
			elif not bool(auction["hesitant"]):
				auction["hesitant"] = true
				if hud:
					hud.show_message(MSG_HESITATES, 4.0)
		objectives_changed.emit()
	if t >= float(auction["ends"]):
		_hammer()


## The hammer: the top bid wins, the rock's word lets the Tollrock's master win within `rock_word_pct`; side 0 pays
## (short coffers = the auction goes to Aurivane).
func _hammer() -> void:
	var a := auction
	auction = {}
	if _bid_panel and is_instance_valid(_bid_panel):
		_bid_panel.queue_free()
	_bid_panel = null
	var bids: Array = a["bids"]
	var b0 := int(bids[0])
	var b1 := int(bids[1])
	var winner := 0 if b0 > b1 else 1
	var owner := rock_owner()
	if owner >= 0 and owner != winner:
		var top := float(maxi(b0, b1))
		var mine := float(b0 if owner == 0 else b1)
		if mine > 0.0 and mine >= top * (1.0 - rock_word_pct):
			winner = owner
	var price := b0 if winner == 0 else b1
	if winner == 0:
		var gb := GoldBank.for_team(Unit.Team.PLAYER)
		if gb == null or not gb.spend(price):
			winner = 1
			price = b1
			if hud:
				hud.show_message(MSG_SHORT, 4.0)
	auction_log.append("%s:%d:%d" % [a["id"], winner, price])
	auction_closed.emit(StringName(a["id"]), winner, price)
	objectives_changed.emit()


## "Kesh: you 300 · Aurivane 350 · 0:21" for the objectives panel ("" = no auction).
func auction_line() -> String:
	if auction.is_empty():
		return ""
	var bids: Array = auction["bids"]
	return Loc.t("Auction for {name}: you {mine} · Aurivane {theirs} · {left}", {"name": auction["name"],
			"mine": int(bids[0]), "theirs": int(bids[1]), "left": mmss(float(auction["ends"]) - mission_time())})


# ---------------------------------------------------------------- waves on a route

## Spawns `rows` at `at` for `team` (scaled, a spiral), each walks `route` (waypoints) then attack-moves `goal`.
func route_wave(rows: Array, at: Vector3, route: Array, goal: Vector3, team: int = Unit.Team.ENEMY) -> Array:
	var out := spawn_rows(rows, at, 0.0, team as Unit.Team, false, true)
	for v: Variant in out:
		send_route(v as Unit, route, goal)
	return out


func send_route(u: Unit, route: Array, goal: Vector3) -> void:
	if u == null:
		return
	u.set_meta(&"e7_route", route.duplicate())
	order_wave(u, &"route", goal)
	if not route.is_empty():
		u.command_attack_move(route[0])


func _refresh_wave_unit(u: Unit, mode: StringName, hero_at: Vector3) -> bool:
	if mode != &"route":
		return _refresh_e7_mode(u, mode, hero_at)
	var route: Array = u.get_meta(&"e7_route", [])
	if not route.is_empty():
		if _flat(u.global_position, route[0]) < 4.0:
			route.pop_front()
			u.set_meta(&"e7_route", route)
		if not route.is_empty():
			if u.attack_target == null and not u.is_attack_moving():
				u.command_attack_move(route[0])
			return true
	var goal: Vector3 = u.get_meta(META_TARGET, hero_at)
	if u.attack_target == null and not u.is_attack_moving():
		if _flat(u.global_position, goal) < 5.0:
			u.set_meta(META_MODE, &"keep")
			u.command_attack_move(_alive_pos(keep, hero_at))
		else:
			u.command_attack_move(goal)
	return true


## Override: the subclass's own wave modes.
func _refresh_e7_mode(_u: Unit, _mode: StringName, _hero_at: Vector3) -> bool:
	return false


## A channel spot's state (the MissionBrazier rule: the hero within `r` for `need` s, leaving resets, damage does not,
## refused while an enemy is within 8 m). Returns the new progress; `dt` added when allowed.
func channel_step(progress: float, at: Vector3, r: float, need: float, dt: float, refuse_msg := "") -> float:
	if not hero_alive() or _flat(hero.global_position, at) > r:
		return 0.0
	if foe_near(at, 8.0) != null:
		if refuse_msg != "" and hud and progress <= 0.0 and fire_once(StringName("refuse_%d_%d" % [int(at.x), int(at.z)])):
			hud.show_message(refuse_msg, 4.0)
		return 0.0
	return minf(need, progress + dt)


# ---------------------------------------------------------------- save / load

func save_state(ids: Dictionary = {}) -> Dictionary:
	var d := super(ids)
	d["e7_toll"] = toll_paid
	d["e7_auction_log"] = auction_log.duplicate()
	if rock:
		d["e7_rock"] = rock.owner_side
	return d


func load_state(d: Dictionary, nodes: Dictionary = {}) -> void:
	super(d, nodes)
	toll_paid = int(d.get("e7_toll", 0))
	auction_log.assign(d.get("e7_auction_log", []))
	if rock and d.has("e7_rock"):
		rock.set_owner_side(int(d["e7_rock"]))
	auction = {}
