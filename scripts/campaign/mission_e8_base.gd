class_name MissionE8Base
extends MissionE7Base
## Episode 8 "The Four Keys" shared rules (docs/design/mission-e8-01.md 1, mission-e8-02.md, mission-e8-03.md), used by
## the four roads (MissionE8_01 and its variants), MissionE8_02 and MissionE8_03 (each a MissionBase through
## MissionE7Base / E6Base / E5Base: lines by id, local unit types saved by id, story helpers, waves on routes, Warden
## Gates, scripted targets).
## - The road: the player's kingdom. e8m1_<k> fixes it; e8m2 / e8m3 read the campaign flag `e8_road` (int 0 fire,
##   1 shadow, 2 ice, 3 nature; the CampaignState flags turn strings into bools, so the road is an index) and
##   `e8_road_<k>`; `forced_road` (tests) wins over the save.
## - The key relic is forced in artifact slot 1 (config.forced_artifacts); an empty slot 2 gives +300 essence once.
## - The Hollow Host (`hollow_warden`, `rubble_sentinel`) and the Stone-sworn (Shadow copies, +15 % HP, +10 % damage)
##   are local unit types; `host_team` is ENEMY on the roads and NEUTRAL in e8m2 / e8m3 (hostile to all four seats).
## - The map is the main.gd generator look at 120 x 120 (no .map files for Duskbarrow / the Hundredwinter Gate / the
##   Closed Road / Fourfold Hollow yet): each mission places its own things on the spec's positions, scaled to it.
## - Every line comes from data/voice/lines (E8Lines, generated): the voice key is the text.

const E8_KINGDOMS: Array[StringName] = [&"fire", &"shadow", &"ice", &"nature"]
const WIZARD_OF := {&"fire": "vessa", &"shadow": "malrik", &"ice": "torvald", &"nature": "ysolde"}
const WIZARD_NAME := {&"fire": "Vessa", &"shadow": "Malrik", &"ice": "Torvald", &"nature": "Ysolde"}
const KEY_OF := {&"fire": "ember_crown", &"shadow": "keystone_shard", &"ice": "stillwater_orb", &"nature": "masters_signet"}
const SPELLS_OF := {&"fire": [&"fireball", &"ember_step", &"kindle"], &"shadow": [&"shadow_lance", &"soul_siphon", &"umbral_shroud"],
		&"ice": [&"rime_bolt", &"flash_freeze", &"rime_aegis"], &"nature": [&"thornburst", &"wild_bloom", &"call_the_thicket"]}
const BUILD_OF := {
	&"fire": {"keep": "fire_keep", "hall": "fire_barracks", "tower": "fire_tower", "house": "fire_hearth", "worker": "cinder_hand"},
	&"shadow": {"keep": "shadow_keep", "hall": "shadow_barracks", "tower": "shadow_tower", "house": "shadow_hovel", "worker": "gloom_thrall"},
	&"ice": {"keep": "ice_keep", "hall": "ice_barracks", "tower": "ice_tower", "house": "ice_lodge", "worker": "rime_hauler"},
	&"nature": {"keep": "nature_keep", "hall": "nature_barracks", "tower": "nature_tower", "house": "nature_hollow", "worker": "sprigling"},
}
## The muster armies (mission-e8-02.md 3.1).
const MUSTER_ARMY := {
	&"fire": [["flame_guard", 10], ["ember_archer", 6], ["blaze_rider", 4], ["pyre_adept", 2], ["cinder_arbalest", 2], ["kilnwarden", 1], ["ashveil_saboteur", 1]],
	&"shadow": [["shade", 8], ["nightbolt", 4], ["shadow_knight", 2], ["hexweaver", 3], ["hollow_oathsworn", 2], ["gloom_deacon", 1], ["nightblood_reaver", 2]],
	&"ice": [["rimeshield", 8], ["shardcaster", 4], ["frostbow", 3], ["rime_seer", 1], ["hoarlight_magebow", 2], ["frost_mortar", 2], ["rimecarver", 1], ["shardguard", 2]],
	&"nature": [["thornling", 12], ["burr_slinger", 4], ["wildwood_archer", 6], ["bloomtender", 3], ["vinelasher", 2], ["greenheart_oathkeeper", 1], ["bramblehorn", 1], ["bramblesage", 1], ["briar_roc", 1]],
}
const ESSENCE_CAP := 1500
const NO_SAVE_ESSENCE := 900
const EMPTY_SLOT_ESSENCE := 300
const HOST_WARDEN := "hollow_warden"
const SENTINEL := "rubble_sentinel"
const STONE_SWORN := ["shade", "nightbolt", "grave_hound", "shadow_knight", "barrow_ghoul", "barrow_knight", "hexweaver", "gloom_deacon"]

const E8_SPEAKER_COLORS := {&"vey": Color(0.95, 0.95, 0.55), &"ashby": Color(0.95, 0.60, 0.35), &"shade": Color(0.62, 0.60, 0.70),
		&"maelis": Color(0.60, 0.85, 0.50), &"messenger": Color(0.80, 0.92, 0.60), &"master": Color(0.95, 0.93, 0.85),
		&"pell": Color(0.90, 0.75, 0.45), &"narrator": Color(0.90, 0.85, 0.70)}
const E8_SPEAKER_NAMES := {&"vey": "Old Vey", &"ashby": "Captain Ashby", &"shade": "Shade Captain", &"maelis": "Maelis",
		&"messenger": "Wren", &"master": "The Master", &"pell": "Pell", &"narrator": "Narrator"}
const MSG_KEY_LOCKED := "Your key. It goes where you go."
const MSG_SLOT_EMPTY := "The relics went home. The road provides."

## Tests: the road used instead of the save (&"" = the save's `e8_road`).
static var forced_road: StringName = &""

## Read only: the player's kingdom on this playthrough.
var road: StringName = &"fire"
## Read only: the Host's team (ENEMY on the roads, NEUTRAL in e8m2 / e8m3).
var host_team: int = Unit.Team.ENEMY


func _init() -> void:
	super()
	speaker_colors.merge(E8_SPEAKER_COLORS, true)
	speaker_names.merge(E8_SPEAKER_NAMES, true)
	make_host_units()


## The lines of mission `id` (E8Lines): line_ids + dialogue_lines.
func use_lines(id: StringName) -> void:
	line_ids.assign(E8Lines.IDS[id])
	dialogue_lines = E8Lines.LINES[id]


## The road of this playthrough: `forced_road`, else the save's `e8_road` index, else fire.
static func saved_road(save_path := "") -> StringName:
	if forced_road != &"":
		return forced_road
	var v: Variant = CampaignState.open(save_path).flag_value("e8_road", 0)
	var i := int(v) if (v is int or v is float) else 0
	return E8_KINGDOMS[clampi(i, 0, 3)]


static func road_index(k: StringName) -> int:
	return maxi(0, E8_KINGDOMS.find(k))


func wizard_id() -> String:
	return String(WIZARD_OF[road])


func wizard_name() -> String:
	return String(WIZARD_NAME[road])


## Says `<prefix>_<wizard>` (the `<W>` sets: L9_vessa...).
func say_w(prefix: String) -> void:
	say_l("%s_%s" % [prefix, wizard_id()])


## The common Episode 8 config: tiers to the Citadel, casters, tier 3, helpers, the instant loss of the wizard, the
## forced key relic, essence trickle and kills.
func e8_config(c: MissionConfig) -> void:
	c.tiers_enabled = true
	c.max_tier = 3
	c.bots_upgrade = false
	c.casters_enabled = true
	c.t3_enabled = true
	c.helpers_enabled = true
	c.titans_enabled = false
	c.instant_loss_on_wizard_death = true
	c.essence_trickle = true
	c.kill_essence = true
	c.level_cap = 8
	c.defeat_delay = 3.0
	c.forced_artifacts.assign([String(KEY_OF[road]), ""])
	c.start_spells.assign([SPELLS_OF[road][0]])
	c.helper_call_price = {"crystals": [250, 250, 250], "essence": [100, 100, 100], "time": [30.0, 30.0, 30.0]}
	c.count_mult.assign([0.6, 1.0, 1.4])


# ---------------------------------------------------------------- the Host and the Stone-sworn (e8m1 1.4)

func make_host_units() -> void:
	local_unit("ruin_warden", HOST_WARDEN, "Ruin Warden", {"aggro_range": 10.0, "commandable": false, "cost": 150,
			"pop": 2, "neutral_leash": false, "kill_xp": 30})
	local_unit("ruin_warden", SENTINEL, "Rubble Sentinel", {"max_hp": 900.0, "armor": 20.0, "attack_damage": 30.0,
			"attack_range": 2.5, "attack_cooldown": 2.2, "move_speed": 3.4, "aggro_range": 12.0, "pop": 4, "kill_xp": 120,
			"cost": 400, "commandable": false, "neutral_leash": false})
	_scales[SENTINEL] = 1.6
	for id: String in STONE_SWORN:
		var base := UnitType.find(id)
		if base == null:
			continue
		local_unit(id, "sworn_" + id, "Stone-sworn %s" % base.display_name, {"max_hp": base.max_hp * 1.15,
				"attack_damage": base.attack_damage * 1.10, "cost": int(base.cost * 1.15), "commandable": false,
				"neutral_leash": false})


## `rows` of Host / Stone-sworn kinds ("warden", "sentinel", or a Shadow id = its Stone-sworn copy).
static func host_rows(rows: Array) -> Array:
	var out: Array = []
	for r: Array in rows:
		var id := String(r[0])
		if id == "warden":
			id = HOST_WARDEN
		elif id == "sentinel":
			id = SENTINEL
		elif STONE_SWORN.has(id):
			id = "sworn_" + id
		out.append([id, r[1]])
	return out


## A Host wave at `at` (scaled), armed, walking `route` then attack-moving `goal`.
func host_wave(rows: Array, at: Vector3, route: Array, goal: Vector3) -> Array:
	var out := route_wave(host_rows(rows), at, route, goal, host_team)
	for v: Variant in out:
		arm_enemy(v as Unit)
	return out


## Host guards at `at` (they hold the spot).
func host_guards(rows: Array, at: Vector3, ring: float) -> Array:
	var out := spawn_rows(host_rows(rows), at, ring, host_team as Unit.Team, true)
	for v: Variant in out:
		arm_enemy(v as Unit)
	return out


func is_host(u: Variant) -> bool:
	var x: Unit = u as Unit if is_instance_valid(u) else null
	return x != null and is_instance_valid(x) and int(x.team) == host_team


## Living Host units within `r` of `at`.
func host_near(at: Vector3, r: float) -> Array[Unit]:
	var out: Array[Unit] = []
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == host_team and not is_dormant(u) and _flat(u.global_position, at) <= r:
			out.append(u)
	return out


## Every Host unit leaves (no XP): the end of a road.
func clear_host() -> void:
	clear_waves()
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == host_team:
			u.leave_map()


# ---------------------------------------------------------------- seats and bases

## Pre-built base of `kingdom` for `team` around `keep_pos`: keep (tier), hall, tower, `houses` houses; returns the keep.
## `out` (Dictionary) gets "keep", "hall", "tower".
func build_base(team: int, kingdom: StringName, keep_pos: Vector3, hall_pos: Vector3, tower_pos: Vector3,
		house_pos: Array, tier := 2) -> Keep:
	var b: Dictionary = BUILD_OF[kingdom]
	var k := build_grid.spawn_complete(BuildingType.find(String(b["keep"])), keep_pos, team) as Keep
	if k:
		seat_keeps[team] = k
		if tier > 1:
			k.set_start_tier(tier)
	seat_bases[team] = keep_pos
	build_grid.spawn_complete(BuildingType.find(String(b["hall"])), hall_pos, team)
	if tower_pos != Vector3.INF:
		build_grid.spawn_complete(BuildingType.find(String(b["tower"])), tower_pos, team)
	for p: Vector3 in house_pos:
		build_grid.spawn_complete(BuildingType.find(String(b["house"])), p, team)
	return k


## The player's wizard of the road at `at`, with its inventory (no track load).
func spawn_player_wizard(at: Vector3) -> Wizard:
	hero = _make_wizard(Unit.Team.PLAYER)
	_spawn(hero, Unit.Team.PLAYER, at)
	_claim_wizard(hero, Unit.Team.PLAYER)
	ItemDrops.ensure_inventory(hero)
	return hero


## Rows of units for `team` in a grid at `at`; returns them.
func spawn_army(rows: Array, at: Vector3, team: int = Unit.Team.PLAYER) -> Array:
	var out: Array = []
	var k := 0
	for row: Array in rows:
		for j in int(row[1]):
			var u := _spawn(make_unit(String(row[0])), team as Unit.Team, at + Vector3((k % 6) * 1.6 - 4.0, 0.0, (k / 6) * 1.7))
			if u:
				out.append(u)
			k += 1
	return out


## Workers of the road's kingdom gathering on `nodes` (alternating).
func spawn_workers(team: int, kingdom: StringName, n: int, at: Vector3, nodes: Array) -> void:
	for i in n:
		var w := _spawn(make_unit(String(BUILD_OF[kingdom]["worker"])), team as Unit.Team, at + Vector3((i % 6) * 1.2, 0.0, -(i / 6) * 1.2))
		var node: Variant = nodes[i % nodes.size()] if not nodes.is_empty() else null
		if w and node != null and w.has_method(&"command_gather"):
			w.call(&"command_gather", node)


# ---------------------------------------------------------------- the track

## The track load (D2 / D8): Vessa's road and every e8m2 / e8m3 start read the saved items, essence and companion;
## the other roads carry their wizard's essence flag (Episodes 3 / 4 / 7 kept those tracks as flags). No save: the
## fallback essence. Then the key relic (config.forced_artifacts, at begin_mission) and +300 for an empty slot 2.
func load_track(use_items: bool, prev_mission: StringName) -> void:
	var cs := CampaignState.open(campaign_save_path)
	var has_save := prev_mission == &"" or cs.is_completed(prev_mission)
	var bank := EssenceBank.for_team(Unit.Team.PLAYER)
	if use_items and has_save and not cs.items.is_empty():
		cs.apply_to_start(self)
	elif bank:
		var flag: String = {&"shadow": CampaignState.MALRIK_ESSENCE_FLAG, &"nature": CampaignState.YSOLDE_ESSENCE_FLAG,
				&"ice": CampaignState.TORVALD_ESSENCE_FLAG}.get(road, "")
		var carried := int(cs.flag_value(flag, 0)) if has_save and flag != "" else 0
		bank.add(carried if carried > 0 else NO_SAVE_ESSENCE)


## +300 essence once when artifact slot 2 is empty after the key relic was forced (call after begin_mission).
func empty_slot_bonus() -> bool:
	var inv := ItemDrops.inventory_of(hero) as Inventory
	if inv == null or inv.get_type(Inventory.ARTIFACT_SLOT + 1) != null:
		return false
	var bank := EssenceBank.for_team(Unit.Team.PLAYER)
	if bank:
		bank.add(EMPTY_SLOT_ESSENCE)
	if hud:
		hud.show_message(MSG_SLOT_EMPTY, 5.0)
	return true


## D4: the key relic never leaves slot 1 (checked on the mission tick: put back if moved, sold or dropped).
func keep_key_relic() -> void:
	if not hero_alive():
		return
	var inv := ItemDrops.inventory_of(hero) as Inventory
	if inv == null:
		return
	var t := inv.get_type(Inventory.ARTIFACT_SLOT)
	if t != null and String(t.id) == String(KEY_OF[road]):
		return
	force_artifacts(hero, [String(KEY_OF[road]), ""])
	if hud:
		hud.show_message(MSG_KEY_LOCKED, 3.0)


## The helper of the player's kingdom on the field (null = none yet / fallen).
func player_helper() -> Helper:
	for n in get_tree().get_nodes_in_group(&"helpers"):
		var h := n as Helper
		if h and h.is_alive() and int(h.team) == Unit.Team.PLAYER:
			return h
	return null


# ---------------------------------------------------------------- small shared rules

## The hero (or any `who`) inside the ring at `at` for `need` s with no Host within `clear` m: the new progress.
func ring_step(who: Unit, progress: float, at: Vector3, r: float, need: float, clear: float, dt: float) -> float:
	if who == null or not is_instance_valid(who) or not who.is_alive() or _flat(who.global_position, at) > r:
		return 0.0
	if not host_near(at, clear).is_empty():
		return 0.0
	return minf(need, progress + dt)


## A kneeling story wizard / ally (the M4 Vey rule): at 0 HP it stays at 1 HP, at peace, for `seconds`, then stands
## at 50 %. `on_kneel` (Callable(u)) runs once per fall.
func kneel_guard(u: Unit, seconds: float, on_kneel: Callable = Callable()) -> void:
	if u == null:
		return
	u.death_guard = func(_a: Variant) -> bool:
		u.hp = 1.0
		if not u.has_meta(&"kneeling"):
			u.set_meta(&"kneeling", mission_time() + seconds)
			set_truce([u], true, Unit.TRUCE_ALL)
			u.command_stop()
			if on_kneel.is_valid():
				on_kneel.call(u)
		return true


## Stands kneeling units back up when their time is over (call from the mission tick).
func tick_kneelers(units: Array) -> void:
	for v: Variant in units:
		var u: Unit = v as Unit if is_instance_valid(v) else null
		if u == null or not is_instance_valid(u) or not u.has_meta(&"kneeling"):
			continue
		if mission_time() >= float(u.get_meta(&"kneeling")):
			u.remove_meta(&"kneeling")
			u.hp = maxf(u.hp, u.max_hp * 0.5)
			set_truce([u], false, Unit.TRUCE_ALL)


## A keep that never drops under `pct` of its HP (allied keeps, mission-e8-02.md D5).
static func keep_floor(b: Building, pct: float) -> void:
	if b and is_instance_valid(b) and b.is_alive() and b.hp < b.max_hp * pct:
		b.hp = b.max_hp * pct


## A thin amber pillar (cosmetic): a lit keyhole, a stake, a knot.
func pillar(at: Vector3, color: Color, height := 6.0, radius := 0.35) -> MeshInstance3D:
	if _SIM.enabled:
		return null
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = height
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.global_position = at + Vector3(0.0, height * 0.5, 0.0)
	return mi
