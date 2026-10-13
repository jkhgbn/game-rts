class_name Unit
extends CharacterBody3D
## A basic RTS unit. It walks with pathfinding, can be selected, and fights enemies.
## Stats come from a UnitType resource (data/units/*.tres, see apply_type), so you rarely
## need to edit this file just to add a new kind of soldier.

signal died(unit: Unit)
## Any effective stat changed (a modifier was added / removed, or a base stat was set).
signal stats_changed
## Soldier veterancy went up (once per level). Wizards use their own level scale in wizard.gd.
signal level_changed(unit: Unit, level: int)
## Item hooks (items.md, task 4.G1). Emitted by the ATTACKER after one of its auto-attacks hurt
## `target` (melee at once, ranged when the projectile lands). `amount` = HP really lost (after armor
## and shield, capped by the target's HP). Lifesteal is already applied when it fires.
signal attack_landed(target: Node3D, amount: float)
## This unit was hit (after shroud / armor / shield; `amount` may be 0 when a shield took it all).
signal damage_taken(amount: float, attacker: Node3D)
## The shield pool changed (add_shield, absorbed, expired, death). 0 = no shield.
signal shield_changed(amount: float)
## leave_map() was called (a Magpie home at its Den, a tracker at its contract end): the unit is gone
## without dying (no `died`, no XP / essence / loot) and frees itself after a 1 s fade.
signal left_map(unit: Unit)
## displace() started moving this unit (Snagroot's pull, caster-units.md 5.3): channels and aims break.
signal displaced(unit: Unit)

## PLAYER = 0, ENEMY = 1 (values used in data and tests). NEUTRAL = camps hostile to both sides.
## ALLY / ENEMY_2 appended for the 2v2 seats (map-2v2.md 4.1; sides in scripts/core/teams.gd). Values only appended.
enum Team { PLAYER, ENEMY, NEUTRAL, ALLY, ENEMY_2 }

# ---- Stats (CLAUDE.md "Stats" contract). effective = (base + sum of flat) * (1 + sum of *_pct).
const STAT_NAMES: Array[StringName] = [&"max_hp", &"max_mana", &"mana_regen", &"hp_regen",
		&"attack_damage", &"attack_cooldown", &"move_speed", &"armor", &"spell_power", &"cooldown_reduction"]
const ATTACK_COOLDOWN_FLOOR := 0.4   # the cooldown never drops below 40 % of base (items.md)
const ARMOR_FLOOR := -50.0

# ---- Veterancy (levels.md "Unit veterancy"): soldiers only.
const VETERANCY_XP: Array[int] = [0, 120, 350, 800]   # total XP needed for level 1..4 (balance-1)
## Rank 4 is "Paragon" (champions.md 1: "Champion" now means the hired heroes).
const VETERANCY_NAMES: Array[String] = ["Recruit", "Veteran", "Elite", "Paragon"]
const MAX_VETERANCY := 4
const VETERANCY_BONUS := 0.1          # +10 % max HP and damage per level above 1
const VETERANCY_MODIFIER := &"veterancy"
const XP_SHARE_RADIUS := 8.0          # other friendly soldiers this close to the victim get a share
const XP_SHARE_RATIO := 0.25
const WIZARD_KILL_XP := 120           # + WIZARD_KILL_XP_PER_LEVEL x the victim wizard's level
const WIZARD_KILL_XP_PER_LEVEL := 30
const CHAMPION_KILL_XP := 100         # + CHAMPION_KILL_XP_PER_LEVEL x the victim champion's level
const CHAMPION_KILL_XP_PER_LEVEL := 25
const BUILDING_KILL_XP := {
	&"fire_keep": 200, &"shadow_keep": 200,
	&"fire_barracks": 100, &"shadow_barracks": 100,
	&"fire_tower": 80, &"shadow_tower": 80,
	&"fire_hearth": 40, &"shadow_hovel": 40,
	# Bazaars (market-trade.md 4.1, levels.md victim table).
	&"fire_market": 80, &"shadow_market": 80, &"ice_market": 80, &"nature_market": 80,
}
const CONSTRUCTION_XP_RATIO := 0.25
const GOLD := Color(1.0, 0.85, 0.4)
const GOLD_FLASH_TIME := 0.2

# ---- Character models (art-units.md 6.1, task 4.G2).
## Kingdom colour handed to the model's set_team_color (not the green / red ring colour).
const KINGDOM_COLORS := {&"fire": Color(0.85, 0.30, 0.12), &"shadow": Color(0.42, 0.22, 0.6),
		&"ice": Color(0.45, 0.75, 1.0), &"nature": Color(0.45, 0.8, 0.35)}
const MAX_ATTACK_WINDUP := 0.15      # D2: a ranged shot leaves at most this long after play_attack()
const MOVING_THRESHOLD := 0.3        # set_moving: below this the model idles
const MOVING_HYSTERESIS := 0.3       # set_moving is only called when the speed changes this much
const DEATH_FALLBACK_TIME := 2.0     # the corpse goes even if the model never emits death_finished
const HP_BAR_HEIGHT := 0.16          # world HP bar (m), billboard at body_height + 0.5

# ---- Timed statuses (spells.md "Statuses", kingdom-ice.md 2.1): a stat modifier "status_<id>" +
# damage taken multiplier. Optional keys: "cooldown_mult" (multiplies the final attack cooldown, so it
# stacks multiplicatively with haste), "speed_floor" (move speed never below it while active),
# "no_move" / "no_act" (can_move() / can_act() false), "hero_mult" (duration x this on wizards and
# champions), "wizard_immune" (never applied to a wizard), "forced_target" (the unit attacks the status
# source only: apply_status(id, seconds, false, source)).
const STATUSES := {
	&"haste": {"mods": {&"attack_cooldown_pct": -0.30, &"move_speed": 1.5}, "damage_taken": 1.0,
			"color": Color(1.0, 0.55, 0.15)},
	&"shroud": {"mods": {&"move_speed": 2.0}, "damage_taken": 0.5, "color": Color(0.55, 0.3, 0.85)},
	# Staff of Cinders (items.md): enemies damaged by a spell are slowed.
	&"smoulder": {"mods": {&"move_speed": -1.5}, "damage_taken": 1.0, "color": Color(0.45, 0.42, 0.40)},
	&"chill": {"mods": {&"move_speed": -1.5}, "damage_taken": 1.0, "cooldown_mult": 1.25,
			"speed_floor": 1.0, "color": Color(0.70, 0.85, 1.00)},
	&"frozen": {"mods": {}, "damage_taken": 1.0, "no_move": true, "no_act": true, "hero_mult": 0.5,
			"color": Color(0.75, 0.92, 1.00, 0.45)},
	&"rooted": {"mods": {}, "damage_taken": 1.0, "no_move": true, "hero_mult": 0.5,
			"color": Color(0.30, 0.45, 0.15)},
	# Champions (champions.md 4.3). taunted: attacks the source (the Oathwall) only; wizards immune.
	&"taunted": {"mods": {}, "damage_taken": 1.0, "forced_target": true, "wizard_immune": true,
			"hero_mult": 0.5, "color": Color(0.95, 0.25, 0.2)},
	# dazed: no move, no act, and (unlike frozen) no immunity afterwards.
	&"dazed": {"mods": {}, "damage_taken": 1.0, "no_move": true, "no_act": true, "hero_mult": 0.5,
			"color": Color(1.0, 0.95, 0.55)},
	&"braced": {"mods": {}, "damage_taken": 0.7, "color": Color(0.6, 0.85, 1.0)},
	&"marked": {"mods": {}, "damage_taken": 1.15, "color": Color(1.0, 0.8, 0.25)},
	# Caster units (docs/design/caster-units.md 3.5). "armor_floor_zero": the status' armour loss never takes the
	# effective armour below 0 (nor lower than it already was); "range_cap": ranged attacks (range > 3) only reach this
	# far; "sight_cap": fog sight at most this (FogOfWar.sight_of); "no_mark": no placeholder sphere (UnitVfx draws it).
	# (No "hero_mult": Slag Rain picks the hero duration itself, slag_big, and applies it with full_duration.)
	&"slagged": {"mods": {&"armor": -20.0, &"move_speed": -0.6}, "damage_taken": 1.10,
			"armor_floor_zero": true, "no_mark": true, "color": Color(0.95, 0.45, 0.10)},
	&"scalded": {"mods": {}, "damage_taken": 1.0, "no_mark": true, "color": Color(0.86, 0.94, 1.0)},
	&"hazed": {"mods": {}, "damage_taken": 1.0, "range_cap": 2.5, "sight_cap": 4.0, "no_mark": true,
			"color": Color(0.92, 0.80, 0.28)},
	&"tithed": {"mods": {}, "damage_taken": 1.0, "no_mark": true, "color": Color(0.84, 0.26, 0.92)},
	# e3m2 (mission-e3-02.md "Stealth"): out of fire-light, refreshed by the mission every tick; is_concealed() reads it.
	&"concealed": {"mods": {}, "damage_taken": 1.0, "no_mark": true, "color": Color(0.45, 0.35, 0.70)},
}
const FROZEN_IMMUNITY := 2.0     # after `frozen` ends, no new `frozen` for this long
const IDLE_REGEN_DELAY := 4.0    # UnitType.idle_regen_pct starts this long after the last damage
const IDLE_REGEN_TICK := 0.5     # idle regen is applied in steps (not every frame)

# ---- Item maths (items.md "Stats used by items"). Caps on the total of modifiers "item:*".
const ITEM_SOURCE_PREFIX := "item:"
const ITEM_FLAT_CAPS := {&"hp_regen": 12.0, &"mana_regen": 6.0, &"move_speed": 2.5, &"armor": 150.0,
		&"spell_power": 60.0, &"cooldown_reduction": 40.0}   # spell_power cap 60: balance-1
const ITEM_PCT_FLOORS := {&"attack_cooldown": -0.35}   # items make attacks at most 35 % faster
## Caps on the effective value whatever the source (percent numbers: 40 = 40 %).
const TOTAL_CAPS := {&"spell_power": 60.0, &"cooldown_reduction": 40.0, &"lifesteal": 30.0,
		&"spell_feed": 60.0}
# ---- Damage over time (apply_dot), auras (apply_aura).
const DOT_COLORS := {&"burn": Color(1.0, 0.4, 0.1), &"bleed": Color(0.6, 0.05, 0.08)}
const AURA_TICK := 0.25     # a carrier refreshes its auras 4 times per second
const AURA_LINGER := 1.0    # a received aura stays this long after the last refresh
const AURA_PREFIX := "aura:"

const GRAVITY := 20.0
const NEUTRAL_LEASH_FACTOR := 2.0   # neutral units fight only within aggro_range * this of home
## Meta {status id: multiplier} that scales statuses landing on this unit (ItemPassives "stillwater"; mission-02.md).
const STATUS_TIME_MULT_META := &"status_time_mult"
const HOME_TOLERANCE := 1.0         # a neutral unit this close to home counts as home
## Non-worker units with aggro_range 0 (Magpies, trackers: brains pick their targets) chase an attacker
## they answer this far from where they stand (aggro_range x 2 would be 0 m for them).
const FIGHT_BACK_LEASH := 15.0
const LEAVE_MAP_FADE := 1.0         # leave_map(): seconds of fade before the unit is freed
const TRUCE_META := &"truce"        # MissionBase.set_truce: meta id shared by nodes that must not fight (in_truce)
const TRUCE_ALL := &"all"           # a truce id at peace with everyone (withdrawn seats)
const LOOT_META := &"loot"          # a Magpie's carried gold (market-trade.md 5.1): get_loot / set_loot
const RETARGET_INTERVAL := 0.25
const IDLE_SLIDE_EVERY := 8         # a still unit on the floor runs move_and_slide once per this many physics frames
const IDLE_SLIDE_EPS2 := 1.0e-6     # (m/s)^2: below this the avoidance velocity counts as standing still
# RVO avoidance (perf-research-2026-10-12 P1, measured 2026-10-11): these are Godot's defaults, kept on purpose.
# A short search (3-8 m + 2 x radius, 4-8 neighbours, horizon 0.6-1 s) saved nothing measurable at 300 units (within
# +-0.2 ms noise, multi- or single-threaded) and crowds flowed worse: 11-20 % fewer units reached a formation-move goal
# in the same time. Re-measure before shrinking them.
const AVOID_NEIGHBOR_DISTANCE := 50.0   # m
const AVOID_MAX_NEIGHBORS := 10
const AVOID_TIME_HORIZON := 1.0         # s
const FACE_EPSILON := 0.0005        # rad: _face stops writing the model's rotation once this close to the goal
const MAX_UNIT_RADIUS := 1.1     # biggest unit radius (Grizzlemaw 1.1); held units search this far past their range
const DEFAULT_BOLT_SPEED := 25.0 # m/s of an auto-attack bolt when the UnitType has no projectile_speed
const DEFAULT_TARGET_RADIUS := 2.5   # for attack targets (buildings) without target_radius()

@export var team: Team = Team.PLAYER:
	set(value):
		team = value
		UnitGrid.mark_dirty()   # the grid caches teams (a switched side re-bins at the next query)
@export var unit_name := "Soldier"
## The four stats below read as the current EFFECTIVE value (base + modifiers). Writing one sets the
## base so that the effective value becomes what was written (legacy callers); new code uses
## set_base_stat / add_modifier instead. A plain write never heals.
@export var max_hp := 100.0: set = _set_max_hp
@export var move_speed := 5.0: set = _set_move_speed
@export var attack_damage := 10.0: set = _set_attack_damage
@export var attack_range := 1.6          ## More than 3.0 means the unit shoots projectiles.
@export var attack_cooldown := 1.0: set = _set_attack_cooldown
@export var aggro_range := 8.0           ## Idle units attack enemies that come this close.
@export var radius := 0.45
@export var body_height := 1.6
@export var body_color := Color(0.85, 0.3, 0.12)
@export var projectile_color := Color(1.0, 0.7, 0.3)
@export var eye_color := Color(0.95, 0.9, 0.8)
## Drop a real 3D model scene here later to replace the placeholder capsule.
@export var model_scene: PackedScene

var hp: float
var selected := false: set = set_selected
## A Unit or a building (anything with team, is_alive(), take_damage(), target_radius()).
var attack_target: Node3D = null
var unit_type: UnitType = null   ## The data this unit was built from (null for wizards).
## Veterancy level 1-4 for soldiers (wizards reuse it for their own 1-8 scale). Read only.
var level := 1
## Veterancy XP (cumulative) for soldiers; wizards reuse it for their own XP. Read only.
var xp := 0
## The Unit / building that dealt the killing blow (set just before die(); may be freed later).
## Wizard XP reads it from Events.unit_died together with Unit.kill_xp_value(victim).
var killer: Node3D = null
## Shield pool absorbed before HP (add_shield). Read only.
var shield := 0.0
## Optional: called as death_guard.call(attacker) -> bool when a hit would kill this unit; return
## true after raising hp above 0 to cancel the death (Rekindle, set by ItemPassives).
var death_guard := Callable()
## Who gave the current shield (SupportCaster sets its UnitType id; any add_shield clears it).
var shield_source: StringName = &""
## The support autocast node (units whose UnitType has support_kind), else null.
var support_caster: SupportCaster = null

var _shield_left := 0.0
var _can_move_flag := true       # false while frozen / rooted
var _can_act_flag := true        # false while frozen
var _status_cd_mult := 1.0       # chill: x1.25 on the final attack cooldown
var _status_speed_floor := 0.0   # chill: move speed floor 1.0 m/s
var _frozen_immune_left := 0.0
var _idle_regen_pct := 0.0
var _idle_regen_left := IDLE_REGEN_TICK
var _lifetime_total := 0.0       # summons: 0 = permanent
var _lifetime_left := 0.0
var _since_damage := 1000.0
var _dots: Dictionary = {}       # StringName id -> {per_tick, interval, left, next, source, jump}
var _auras: Dictionary = {}      # StringName modifier id -> {radius, stats, filter, priority} (carrier)
var _aura_tick_left := 0.0
var _aura_in: Dictionary = {}    # StringName modifier id -> {left, carrier, priority, hash} (receiver)
static var _item_source_cache: Dictionary = {}   # StringName source -> bool

var _base: Dictionary = {}       # StringName -> float, base stats (UnitType / level)
var _base_ready := false
var _mods: Dictionary = {}       # StringName source_id -> {StringName stat: float}
var _stats: Dictionary = {}      # StringName -> float, cached effective values
var _writing_stats := false      # true while _recompute_stats writes the cached properties
var _armor := 0.0
var _hp_regen := 0.0
var _gold_flash := 0.0
var _chevrons: Label3D
var _statuses: Dictionary = {}       # StringName status id -> seconds left
var _status_marks: Dictionary = {}   # StringName status id -> MeshInstance3D
var _damage_taken_mult := 1.0
## `taunted`: the enemy this unit must attack while the status lasts (null = none). Set by
## apply_status(&"taunted", s, false, source) or written directly right after apply_status (9.C2 does).
## Cleared when the status ends, the source dies, or on death / revive.
var taunted_by: Node3D = null
var _hidden_auto_left := 0.0         # hide_from_auto_target: seconds left
## Caster units (caster-units.md): +1 on every command_move / attack / attack_move / stop / hold, so a system that gave
## its own order can tell when the player (or a bot) gave another one since. Read only.
var order_serial := 0
## True = no auto-attacks (a Gloom Deacon channelling Blood Tithe walks but never attacks). Orders are kept.
var attacks_blocked := false
## Bot soldiers (AICasters sets it, caster-units.md 8.2): auto-aggro picks an enemy caster in reach first.
var prefer_casters := false
const CASTER_PREFERENCE := 100.0
## P2 (wave-strike.md 14.2): fixed physics-frame buckets for the auto-aggro scan (15 frames = 0.25 s at 60 Hz).
const SCAN_BUCKETS := 15
## -1 (default) = the 0.25 s retarget timer; 0..SCAN_BUCKETS-1 = scan only on physics frames whose index mod
## SCAN_BUCKETS is this bucket (LaneMarch sets it from the spawn serial, so a spawned wave never scans on one frame).
var scan_bucket := -1
## Auto-aggro scans run so far, all units (tests / labs count the scans per frame). Read only.
static var retarget_scans := 0
var _avoid_gated := false            # set_avoidance_gated: RVO off, the wanted velocity is applied directly
## Physics layer 3 (value 4) = caster walls (Rime Bulwark): ground units collide with it, flyers do not. Avoidance layer
## 2 (value 2) = its NavigationObstacle3D, avoided by ground units only.
const CASTER_WALL_LAYER := 4
const CASTER_WALL_AVOIDANCE := 2
var _status_range_cap := INF         # hazed: ranged attacks reach at most this far
var _status_sight_cap := INF         # hazed: fog sight at most this
var _cast_lock_left := 0.0           # set_cast_lock: no walking, no attacks (a caster's 0.4 s cast)
var _displace: Dictionary = {}       # displace(): {from, to, t, time}

var _agent: NavigationAgent3D
var _visual: Node3D
var _body_mat: StandardMaterial3D
var _ring: MeshInstance3D
var _hp_bar: MeshInstance3D
var _hp_mat: ShaderMaterial

var _has_move_order := false
var _attack_move := false        # walking to _attack_move_target, fighting enemies met on the way
var _attack_move_target := Vector3.ZERO
var _hold := false               # hold position: never move, only hit enemies already in range
var _auto_target := false        # true when we picked the target ourselves (not ordered)
## True only while this unit's melee auto-attack deals its damage (read only): a `damage_taken` listener can tell a
## melee strike from a spell, an ability or a DoT tick (Riposte, R2-6).
var melee_strike_active := false
var _anchor := Vector3.ZERO      # where the unit "lives" when idle; used for leashing
var _cooldown_left := 0.0
var _retarget_left := 0.0
var _last_nav_target := Vector3.INF
var _vertical_speed := 0.0
var _slide_phase := -1           # stagger of the idle move_and_slide refresh (-1 = not set; from the first position)
var _hit_flash := 0.0
var _dead := false
var _left_map := false
var _death_tween: Tween

## The character model instance (child of _visual) or null for the placeholder capsule.
var _model: Node3D = null
var _model_windup := 0.0          # ranged release delay read once from the model (<= 0.15 s)
var _model_speed_sent := 0.0      # last speed given to set_moving
var _model_has_moving := false
var _model_has_attack := false
var _model_has_hit := false
var _model_has_status := false
var _shot_left := -1.0            # > 0: a ranged shot waits for the model's release frame
var _shot_target: Node3D = null
var _death_done := false
var _dots_at_death: Dictionary = {}   # die(): the DoTs the unit carried, spread after the state change
var _death_serial := 0

static var _hp_shader: Shader
static var _pct_keys: Dictionary = {}   # StringName stat -> StringName "<stat>_pct"


func _ready() -> void:
	if _stats.is_empty():
		_recompute_stats(false)
	_apply_team_wares()
	hp = max_hp
	_anchor = global_position
	add_to_group("units")
	UnitGrid.mark_dirty()
	collision_layer = 2   # "units" layer, so clicks can find us
	collision_mask = 1    # only collide with the world, avoidance keeps units apart
	if not HelperAbilities.is_flyer(self):
		collision_mask |= CASTER_WALL_LAYER   # caster-units.md 5.2: Rime Bulwarks stop ground units, never flyers
	_build_collision()
	_build_visual()
	_build_selection_ring()
	_build_hp_bar()

	_agent = NavigationAgent3D.new()
	_agent.path_desired_distance = 0.6
	_agent.target_desired_distance = 0.8
	_agent.radius = radius + 0.1
	_agent.max_speed = move_speed
	_agent.avoidance_enabled = true
	_agent.neighbor_distance = AVOID_NEIGHBOR_DISTANCE
	_agent.max_neighbors = AVOID_MAX_NEIGHBORS
	_agent.time_horizon_agents = AVOID_TIME_HORIZON
	if not HelperAbilities.is_flyer(self):
		_agent.avoidance_mask |= CASTER_WALL_AVOIDANCE   # slide along a Rime Bulwark's obstacle
	_agent.velocity_computed.connect(_on_velocity_computed)
	add_child(_agent)

	if _lifetime_total > 0.0 and _lifetime_left <= 0.0:
		_lifetime_left = _lifetime_total
	if unit_type and unit_type.support_kind != &"" and support_caster == null:
		support_caster = SupportCaster.new()
		support_caster.name = "SupportCaster"
		support_caster.setup(self)
		add_child(support_caster)
	if unit_type and BowmanKit.is_bowman(unit_type.id):   # docs/design/bowmen.md: upgrades, Hamstring string
		BowmanKit.on_unit_ready(self)
	if unit_type and NewUnits12.is_new_unit(unit_type.id):   # docs/design/new-units-12.md: the unit's ability
		NewUnits12.attach(self)
	if unit_type and T3Kit.is_t3_unit(unit_type.id):   # t3-helpers.md 7.2: Saboteur, Reaver, Shardguard, Roc, Genie
		T3Kit.attach(self)
	if unit_type and CasterKit.is_caster(unit_type.id):   # caster-units.md: mana + the two spells + the passive
		CasterKit.attach(self)


# ---------------------------------------------------------------- orders

## Copies the stats of a UnitType. Call it before the unit enters the scene tree.
func apply_type(type: UnitType) -> void:
	unit_type = type
	unit_name = type.display_name
	_ensure_base()
	_base[&"max_hp"] = type.max_hp
	_base[&"move_speed"] = type.move_speed
	_base[&"attack_damage"] = type.attack_damage
	_base[&"attack_cooldown"] = type.attack_cooldown
	_base[&"armor"] = type.armor
	_recompute_stats(false)
	_idle_regen_pct = type.idle_regen_pct
	_lifetime_total = type.lifetime
	attack_range = type.attack_range
	aggro_range = type.aggro_range
	radius = type.radius
	body_height = type.body_height
	body_color = type.body_color
	projectile_color = type.projectile_color
	eye_color = type.eye_color
	model_scene = type.model_scene


func is_worker() -> bool:
	return unit_type != null and unit_type.is_worker


# market-trade.md 3.2: the team's GoldBank (group "gold_banks", only when trade is on) applies the wares
# it owns to every new unit (it decides which ones count as soldiers). Runs inside _ready, so only groups
# joined before add_child (champions: in _init) are visible to it.
func _apply_team_wares() -> void:
	if team == Team.NEUTRAL or not is_inside_tree():
		return
	for bank in get_tree().get_nodes_in_group(&"gold_banks"):
		var bank_team: Variant = bank.get(&"team")
		if bank_team != null and int(bank_team) == int(team) and bank.has_method(&"apply_wares"):
			bank.call(&"apply_wares", self)
			return


# ---------------------------------------------------------------- stats (CLAUDE.md "Stats")

## Adds (or replaces) the modifier `source_id`. `stats` maps stat names to values: flat
## (`"attack_damage": 10`) or percent (`"attack_damage_pct": 0.1`). Raising max HP heals the gain,
## lowering it clamps HP (never kills). `heal_gain` = false: a max HP gain does not heal (a modifier that
## only moves, e.g. an item swapped between slots or dropped and picked up again; R1-1).
func add_modifier(source_id: StringName, stats: Dictionary, heal_gain := true) -> void:
	var clean := {}
	for key: Variant in stats:
		clean[StringName(str(key))] = float(stats[key])
	_mods[source_id] = clean
	_recompute_stats(heal_gain)


func remove_modifier(source_id: StringName) -> void:
	if _mods.erase(source_id):
		_recompute_stats(true)


func has_modifier(source_id: StringName) -> bool:
	return _mods.has(source_id)


## The effective value (base + modifiers, floors applied). Unknown stats are 0. Cached: cheap.
func get_stat(stat: StringName) -> float:
	if _stats.is_empty():
		_recompute_stats(false)
	return float(_stats.get(stat, 0.0))


func get_base_stat(stat: StringName) -> float:
	_ensure_base()
	return float(_base.get(stat, 0.0))


## Sets a base stat (wizard levels, max_mana...). Raising max_hp this way heals the gain.
func set_base_stat(stat: StringName, value: float) -> void:
	_ensure_base()
	_base[stat] = value
	_recompute_stats(true)


## Damage multiplier for an armor value (items.md): 100 / (100 + a), or 1 - a / 100 when negative.
static func armor_multiplier(armor: float) -> float:
	if armor >= 0.0:
		return 100.0 / (100.0 + armor)
	return 1.0 - armor / 100.0


func _set_max_hp(value: float) -> void:
	if _writing_stats:
		max_hp = value
	else:
		_set_effective(&"max_hp", value)


func _set_move_speed(value: float) -> void:
	if _writing_stats:
		move_speed = value
	else:
		_set_effective(&"move_speed", value)


func _set_attack_damage(value: float) -> void:
	if _writing_stats:
		attack_damage = value
	else:
		_set_effective(&"attack_damage", value)


func _set_attack_cooldown(value: float) -> void:
	if _writing_stats:
		attack_cooldown = value
	else:
		_set_effective(&"attack_cooldown", value)


# Legacy write: pick the base that makes the effective value equal `value`. Never heals.
func _set_effective(stat: StringName, value: float) -> void:
	_ensure_base()
	var flat := 0.0
	var pct := 0.0
	var pct_key := _pct_key(stat)
	for mods: Dictionary in _mods.values():
		flat += float(mods.get(stat, 0.0))
		pct += float(mods.get(pct_key, 0.0))
	var mult := 1.0 + pct
	_base[stat] = (value / mult if absf(mult) > 0.0001 else value) - flat
	_recompute_stats(false)


# The first stats operation copies the exported values into the base table.
func _ensure_base() -> void:
	if _base_ready:
		return
	_base_ready = true
	_base[&"max_hp"] = max_hp
	_base[&"move_speed"] = move_speed
	_base[&"attack_damage"] = attack_damage
	_base[&"attack_cooldown"] = attack_cooldown


static func _pct_key(stat: StringName) -> StringName:
	var key: Variant = _pct_keys.get(stat)
	if key == null:
		key = StringName(String(stat) + "_pct")
		_pct_keys[stat] = key
	return key


static func _is_item_source(source: StringName) -> bool:
	var cached: Variant = _item_source_cache.get(source)
	if cached == null:
		cached = String(source).begins_with(ITEM_SOURCE_PREFIX)
		_item_source_cache[source] = cached
	return bool(cached)


func _compute_stat(stat: StringName) -> float:
	var base := float(_base.get(stat, 0.0))
	var flat := 0.0
	var pct := 0.0
	var item_flat := 0.0
	var item_pct := 0.0
	var pct_key := _pct_key(stat)
	for source: StringName in _mods:
		var mods: Dictionary = _mods[source]
		if _is_item_source(source):
			item_flat += float(mods.get(stat, 0.0))
			item_pct += float(mods.get(pct_key, 0.0))
		else:
			flat += float(mods.get(stat, 0.0))
			pct += float(mods.get(pct_key, 0.0))
	if ITEM_FLAT_CAPS.has(stat):
		item_flat = minf(item_flat, float(ITEM_FLAT_CAPS[stat]))
	if ITEM_PCT_FLOORS.has(stat):
		item_pct = maxf(item_pct, float(ITEM_PCT_FLOORS[stat]))
	flat += item_flat
	pct += item_pct
	var value := (base + flat) * (1.0 + pct)
	if TOTAL_CAPS.has(stat):
		value = minf(value, float(TOTAL_CAPS[stat]))
	match stat:
		&"max_hp":
			if pct != 0.0:
				value = roundf(value)   # levels.md: max_hp = round(base x mult)
			value = maxf(1.0, value)
		&"attack_cooldown":
			value = maxf(value, base * ATTACK_COOLDOWN_FLOOR) * _status_cd_mult
		&"armor":
			# caster-units.md 3.5 `slagged`: its armour loss stops at 0 (and never lowers a negative armour further).
			var slag: Dictionary = _mods.get(&"status_slagged", {})
			var loss := float(slag.get(&"armor", 0.0))
			if loss < 0.0:
				var without := value - loss * (1.0 + pct)
				value = maxf(value, minf(without, 0.0))
			value = maxf(value, ARMOR_FLOOR)
		&"move_speed":
			value = maxf(0.0, value)
			if _status_speed_floor > 0.0:
				value = maxf(value, minf(_status_speed_floor, base))
		&"attack_damage", &"max_mana", &"hp_regen", &"mana_regen":
			value = maxf(0.0, value)
	return value


# Recomputes every effective stat once (only on change) and writes the cached properties.
func _recompute_stats(heal_gain: bool) -> void:
	_ensure_base()
	var old_max := max_hp
	var names := {}
	for stat in STAT_NAMES:
		names[stat] = true
	for stat: StringName in _base:
		names[stat] = true
	for mods: Dictionary in _mods.values():
		for key: StringName in mods:
			var s := String(key)
			names[StringName(s.left(-4)) if s.ends_with("_pct") else key] = true
	var out := {}
	for stat: StringName in names:
		out[stat] = _compute_stat(stat)
	_stats = out
	_writing_stats = true
	max_hp = out[&"max_hp"]
	move_speed = out[&"move_speed"]
	attack_damage = out[&"attack_damage"]
	attack_cooldown = out[&"attack_cooldown"]
	_writing_stats = false
	_armor = out[&"armor"]
	_hp_regen = out[&"hp_regen"]
	if _agent:
		_agent.max_speed = move_speed
	if is_node_ready() and not is_equal_approx(old_max, max_hp):
		if heal_gain and max_hp > old_max and not _dead:
			hp += max_hp - old_max
		hp = minf(hp, max_hp)
		_update_hp_bar()
	stats_changed.emit()


# ---------------------------------------------------------------- statuses (spells.md)

## Applies timed status `status_id` (`&"haste"`, `&"shroud"`, `&"smoulder"`, `&"chill"`, `&"frozen"`,
## `&"rooted"`, `&"taunted"`, `&"dazed"`, `&"braced"`, `&"marked"`) for `seconds`; re-applying refreshes
## the timer to the longer of the two (never stacks, never shortens). Ignored on a dead unit or an unknown id.
## Ends on death. Crowd control
## (`frozen`, `rooted`, `dazed`, `taunted`) lasts half as long on heroes (wizards and champions), and
## `frozen` is refused for 2 s after a freeze ends. `full_duration` = true skips both rules
## (self-inflicted effects such as Glacier Shell, Bulwark Stand). `taunted` never lands on a wizard;
## `source` = the enemy the unit must attack (sets `taunted_by`; a source that is not a living enemy
## refuses the status). Without a source the status lands and `taunted_by` can be written right after.
func apply_status(status_id: StringName, seconds: float, full_duration: bool = false,
		source: Node3D = null) -> void:
	if _dead or seconds <= 0.0 or not STATUSES.has(status_id):
		return
	var data: Dictionary = STATUSES[status_id]
	if data.get("wizard_immune", false) and _is_wizard_unit():
		return
	if data.get("forced_target", false) and source != null:
		if not is_instance_valid(source) or not is_enemy_of(source) or not _target_alive(source):
			return
		taunted_by = source
	if not full_duration:
		if status_id == &"frozen" and _frozen_immune_left > 0.0:
			return
		if _is_hero_unit():
			seconds *= float(data.get("hero_mult", 1.0))
		# Item passives that shorten statuses on the wearer (Stillwater Orb: chill / frozen x 0.5), after the hero rule.
		if has_meta(STATUS_TIME_MULT_META):
			seconds *= float((get_meta(STATUS_TIME_MULT_META) as Dictionary).get(status_id, 1.0))
	var fresh := not _statuses.has(status_id)
	_statuses[status_id] = seconds if fresh else maxf(float(_statuses[status_id]), seconds)   # never shortened (R1-5)
	if not fresh:
		return
	_update_damage_taken()   # also the cooldown mult / speed floor / can_move / can_act flags
	var mods: Dictionary = data["mods"]
	if not mods.is_empty():
		add_modifier(StringName("status_" + String(status_id)), mods)
	if status_id == &"frozen":
		_set_model_paused(true)
	if not _model_status(status_id, true) and not data.get("no_mark", false):
		if status_id == &"frozen":
			_add_ice_block(data["color"])
		else:
			_add_mark(status_id, data["color"])


## False while `frozen` or `rooted` (or dead): the unit does not walk. Orders are kept.
func can_move() -> bool:
	return _can_move_flag and not _dead


## False while `frozen` (or dead): no attacks, no casts, no support autocast. Orders are kept.
func can_act() -> bool:
	return _can_act_flag and not _dead


## Seconds left of the 2 s `frozen` immunity (0 = can be frozen).
func frozen_immunity_left() -> float:
	return _frozen_immune_left


## The timed statuses currently on this unit (ids of STATUSES), for the UI.
func active_statuses() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in _statuses:
		out.append(id)
	return out


## Summons: (re)starts the lifetime; the unit withers (dies, no killer) after `seconds`. 0 = permanent.
func set_lifetime(seconds: float) -> void:
	_lifetime_total = maxf(0.0, seconds)
	_lifetime_left = _lifetime_total


## Seconds before a summon withers; 0 for permanent units.
func lifetime_left() -> float:
	return _lifetime_left if _lifetime_total > 0.0 else 0.0


## The full lifetime (0 = permanent), for the UI lifetime bar.
func lifetime_total() -> float:
	return _lifetime_total


## Idle regen in percent of max HP per second after 4 s without damage (UnitType.idle_regen_pct;
## wizards without a UnitType, e.g. Ysolde, set it here).
func set_idle_regen_pct(pct: float) -> void:
	_idle_regen_pct = maxf(0.0, pct)


func get_idle_regen_pct() -> float:
	return _idle_regen_pct


func _is_wizard_unit() -> bool:
	return is_in_group(&"heroes") or is_in_group(&"enemy_heroes") or has_method(&"command_cast")


# Heroes for status `hero_mult`: wizards and champions (champions.md 4).
func _is_hero_unit() -> bool:
	return _is_wizard_unit() or is_in_group(&"champions")


## The unit a `taunted` unit must attack (null when not taunted).
func taunt_source() -> Node3D:
	return taunted_by if _statuses.has(&"taunted") and is_instance_valid(taunted_by) else null


## For `seconds`, no unit picks this one by auto-aggro (explicit orders and current targets still hit it;
## callers clear the targets they want dropped). Smoke Pouch (champions.md 4.3). Refreshes, never shortens.
func hide_from_auto_target(seconds: float) -> void:
	_hidden_auto_left = maxf(_hidden_auto_left, seconds)


## True while `viewer_team` sees this unit as something else (the Ashveil Saboteur's worker disguise, t3-helpers.md
## 7.2): auto-aggro, the minimap and the selection panel may read it.
func is_disguised_for(viewer_team: int) -> bool:
	var ab := get_node_or_null(^"T3Ability")
	return ab != null and ab.has_method(&"is_disguised_for") and bool(ab.call(&"is_disguised_for", viewer_team))


func is_hidden_from_auto_target() -> bool:
	return _hidden_auto_left > 0.0


## e3m2: the `concealed` status runs (a squad unit out of fire-light; the mission sets it and the auto-target hiding).
func is_concealed() -> bool:
	return _statuses.has(&"concealed")


## False for units the player may never order (champions: they act on their own; Greywater Trackers:
## UnitType.commandable = false). Selection, groups, F2, right-click and the command card skip a unit that
## returns false (clicking it = inspect only). Champion overrides it (always false).
func is_commandable() -> bool:
	return unit_type == null or unit_type.commandable


## Units that never fight (caravans: no damage, aggro 0): no fight back, no auto-aggro, attack orders ignored.
func is_non_combatant() -> bool:
	return unit_type != null and (unit_type.is_caravan or unit_type.attack_damage <= 0.0)


# Frozen: the model holds its pose (its _process / animations stop) until the freeze ends.
func _set_model_paused(paused: bool) -> void:
	if _model:
		_model.process_mode = Node.PROCESS_MODE_DISABLED if paused else Node.PROCESS_MODE_INHERIT


# Placeholder look of `frozen` (kingdom-ice.md 2.1): a translucent ice block around the unit.
func _add_ice_block(color: Color) -> void:
	if _status_marks.has(&"frozen"):
		return
	var block := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(radius * 2.2, body_height * 1.1, radius * 2.2)
	block.mesh = box
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = Color(color.r, color.g, color.b)
	mat.emission_energy_multiplier = 0.5
	block.material_override = mat
	block.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	block.position.y = body_height * 0.55
	add_child(block)
	_status_marks[&"frozen"] = block


## Tells the model about a status; true = the model shows it (no placeholder sphere needed).
func _model_status(id: StringName, on: bool) -> bool:
	if not _model_has_status:
		return false
	return bool(_model.call(&"set_status", id, on))


# A small unshaded sphere above the head per status / DoT (placeholder; UI may replace it).
func _add_mark(id: StringName, color: Color) -> void:
	if _status_marks.has(id):
		return
	var mark := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	mark.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mark.material_override = mat
	mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mark.position.y = body_height + 0.3 + 0.3 * _status_marks.size()
	add_child(mark)
	_status_marks[id] = mark


func _remove_mark(id: StringName) -> void:
	var mark: Node = _status_marks.get(id)
	_status_marks.erase(id)
	if mark and is_instance_valid(mark):
		mark.queue_free()


## True for a timed status (`haste`, `shroud`, `smoulder`), a DoT (`burn`) or `shield` (items.md ids).
func has_status(status_id: StringName) -> bool:
	if status_id == &"shield":
		return shield > 0.0
	return _statuses.has(status_id) or _dots.has(status_id)


## Seconds left of a status (0 when the unit doesn't have it).
func status_time_left(status_id: StringName) -> float:
	return float(_statuses.get(status_id, 0.0))


func _tick_statuses(delta: float) -> void:
	for status_id: StringName in _statuses.keys():
		var left: float = float(_statuses[status_id]) - delta
		if left <= 0.0:
			_end_status(status_id)
		else:
			_statuses[status_id] = left


func _end_status(status_id: StringName) -> void:
	_statuses.erase(status_id)
	var old_cd_mult := _status_cd_mult
	var old_floor := _status_speed_floor
	_update_damage_taken()
	var mod_id := StringName("status_" + String(status_id))
	if _mods.has(mod_id):
		remove_modifier(mod_id)
	elif old_cd_mult != _status_cd_mult or old_floor != _status_speed_floor:
		_recompute_stats(false)
	if status_id == &"frozen":
		_set_model_paused(false)
		if not _dead:
			_frozen_immune_left = FROZEN_IMMUNITY
	elif status_id == &"taunted":
		taunted_by = null
	_model_status(status_id, false)
	_remove_mark(status_id)


# Recomputes everything the active statuses change: damage taken, cooldown mult, speed floor and
# the can_move / can_act flags. Stats are recomputed by the caller (add / remove_modifier).
func _update_damage_taken() -> void:
	_damage_taken_mult = 1.0
	_status_cd_mult = 1.0
	_status_speed_floor = 0.0
	_status_range_cap = INF
	_status_sight_cap = INF
	_can_move_flag = true
	_can_act_flag = true
	for status_id: StringName in _statuses:
		var data: Dictionary = STATUSES[status_id]
		_damage_taken_mult *= float(data["damage_taken"])
		_status_range_cap = minf(_status_range_cap, float(data.get("range_cap", INF)))
		_status_sight_cap = minf(_status_sight_cap, float(data.get("sight_cap", INF)))
		_status_cd_mult *= float(data.get("cooldown_mult", 1.0))
		_status_speed_floor = maxf(_status_speed_floor, float(data.get("speed_floor", 0.0)))
		if data.get("no_move", false):
			_can_move_flag = false
		if data.get("no_act", false):
			_can_act_flag = false


# ---------------------------------------------------------------- item hooks (items.md, 4.G1)

## Damage over time `id` (`&"burn"`): `per_tick` damage every `interval` s for `duration` s, credited
## to `source` (XP / essence / killer). Re-applying refreshes, never stacks: the timer restarts
## (never shortened) and the stronger DoT (damage per second) keeps its numbers. `jump_radius` > 0:
## when this unit dies burning, the DoT jumps to the source's enemies within that distance
## (Searing Strikes II). Armor applies to each tick. Ignored on a dead unit.
func apply_dot(id: StringName, per_tick: float, interval: float, duration: float,
		source: Node3D = null, jump_radius: float = 0.0) -> void:
	if _dead or per_tick <= 0.0 or duration <= 0.0:
		return
	interval = maxf(0.05, interval)
	var old: Dictionary = _dots.get(id, {})
	if old.is_empty():
		_dots[id] = {"per_tick": per_tick, "interval": interval, "left": duration, "next": interval,
				"source": source, "jump": jump_radius, "duration": duration}
		if not _model_status(id, true):
			_add_mark(id, DOT_COLORS.get(id, Color(1.0, 0.4, 0.1)))
		return
	if per_tick / interval >= float(old["per_tick"]) / float(old["interval"]):
		old["per_tick"] = per_tick
		old["interval"] = interval
		old["source"] = source
		old["jump"] = jump_radius
		old["duration"] = duration
	old["left"] = maxf(float(old["left"]), duration)


## Seconds left of DoT `id` (0 when none).
func dot_time_left(id: StringName) -> float:
	var d: Dictionary = _dots.get(id, {})
	return float(d.get("left", 0.0))


func _tick_dots(delta: float) -> void:
	for id: StringName in _dots.keys():
		var d: Dictionary = _dots[id]
		d["left"] = float(d["left"]) - delta
		d["next"] = float(d["next"]) - delta
		while float(d["next"]) <= 0.0001:
			d["next"] = float(d["next"]) + float(d["interval"])
			var src: Variant = d["source"]
			take_damage(float(d["per_tick"]), src as Node3D if is_instance_valid(src) else null)
			if _dead:
				return
		if float(d["left"]) <= 0.0001:
			_dots.erase(id)
			_model_status(id, false)
			_remove_mark(id)


# On death: every DoT with a jump radius spreads to the source's enemies nearby (not chained forever:
# the copies keep the radius, so a unit that dies burning passes it on once more).
func _spread_dots(dots: Dictionary, at: Vector3) -> void:
	for id: StringName in dots:
		var d: Dictionary = dots[id]
		var r := float(d["jump"])
		if r <= 0.0:
			continue
		var src: Variant = d["source"]
		var src_node: Node3D = src as Node3D if is_instance_valid(src) else null
		for node in get_tree().get_nodes_in_group(&"units"):
			var u := node as Unit
			if u == null or u == self or not u.is_alive():
				continue
			var hostile: bool = Teams.is_allied_fast(int(u.team), int(team))
			if src_node and src_node.has_method(&"is_enemy_of"):
				hostile = bool(src_node.call(&"is_enemy_of", u))
			if not hostile:
				continue
			if Vector2(u.global_position.x - at.x, u.global_position.z - at.z).length() <= r + u.radius:
				u.apply_dot(id, float(d["per_tick"]), float(d["interval"]), float(d["duration"]), src_node, r)


## A shield of `amount` for `duration` s, consumed (after armor) before HP. A new shield replaces the
## old one (items.md: a new Brace replaces the old). Ignored on a dead unit.
func add_shield(amount: float, duration: float) -> void:
	if _dead:
		return
	shield = maxf(0.0, amount)
	shield_source = &""
	_shield_left = duration if shield > 0.0 else 0.0
	shield_changed.emit(shield)
	_update_hp_bar()


func shield_time_left() -> float:
	return _shield_left if shield > 0.0 else 0.0


func _clear_shield() -> void:
	if shield <= 0.0 and _shield_left <= 0.0:
		return
	shield = 0.0
	_shield_left = 0.0
	shield_source = &""
	shield_changed.emit(0.0)
	_update_hp_bar()


## Seconds since this unit last took damage (Quiet Step). Large at spawn.
func seconds_since_damage() -> float:
	return _since_damage


## Carrier side: every 0.25 s, friendly units within `aura_radius` that pass `filter` get the stat
## modifier `"aura:<source_id>"` (`stats` = Stats contract keys). They keep it 1 s after the last
## refresh (leaving the radius, the carrier dying or remove_aura). `filter`: `&"soldiers"` (default:
## trained units, not workers, not wizards), `&"allies"` (any friendly unit, the carrier too) or a
## Callable(unit) -> bool. Calling it again with the same id replaces the aura. One source wins per
## id on each receiver: the aura with the bigger sum of |values| (Banner over Horn).
func apply_aura(source_id: StringName, aura_radius: float, stats: Dictionary,
		filter: Variant = &"soldiers") -> void:
	var prio := 0.0
	for k: Variant in stats:
		prio += absf(float(stats[k]))
	_auras[aura_modifier_id(source_id)] = {"radius": aura_radius, "stats": stats.duplicate(),
			"filter": filter, "priority": prio}
	_aura_tick_left = 0.0


func remove_aura(source_id: StringName) -> void:
	_auras.erase(aura_modifier_id(source_id))


func has_aura(source_id: StringName) -> bool:
	return _auras.has(aura_modifier_id(source_id))


## `&"rally"` -> `&"aura:rally"` (an id that already starts with "aura:" is kept).
static func aura_modifier_id(source_id: StringName) -> StringName:
	var s := String(source_id)
	return source_id if s.begins_with(AURA_PREFIX) else StringName(AURA_PREFIX + s)


## Receiver side (called by carriers): (re)applies aura modifier `modifier_id` for AURA_LINGER s.
## A weaker aura of the same id from another carrier is ignored while the stronger one holds.
func receive_aura(modifier_id: StringName, stats: Dictionary, carrier: Node, priority: float) -> void:
	if _dead:
		return
	var carrier_id := carrier.get_instance_id() if carrier else 0
	var h := stats.hash()
	var cur: Dictionary = _aura_in.get(modifier_id, {})
	if not cur.is_empty() and int(cur["carrier"]) != carrier_id and priority < float(cur["priority"]):
		return
	if cur.is_empty() or int(cur["hash"]) != h:
		add_modifier(modifier_id, stats)
	_aura_in[modifier_id] = {"left": AURA_LINGER, "carrier": carrier_id, "priority": priority, "hash": h}


func _refresh_auras() -> void:
	var units := get_tree().get_nodes_in_group(&"units")
	var me := global_position
	for mod_id: StringName in _auras:
		var a: Dictionary = _auras[mod_id]
		var r := float(a["radius"])
		var r2 := r * r
		var stats: Dictionary = a["stats"]
		var filter: Variant = a["filter"]
		var prio := float(a["priority"])
		for node in units:
			var u := node as Unit
			if u == null or not Teams.is_allied_fast(int(u.team), int(team)) or not u.is_alive():
				continue
			var dx := u.global_position.x - me.x
			var dz := u.global_position.z - me.z
			if dx * dx + dz * dz > r2 or not _aura_accepts(filter, u):
				continue
			u.receive_aura(mod_id, stats, self, prio)


func _aura_accepts(filter: Variant, u: Unit) -> bool:
	if filter is Callable:
		return bool((filter as Callable).call(u))
	if filter == &"allies":
		return true
	# soldiers
	return u != self and u.unit_type != null and not u.unit_type.is_worker and not u.is_in_group(&"heroes") \
			and not u.is_in_group(&"enemy_heroes")


func _tick_aura_in(delta: float) -> void:
	for mod_id: StringName in _aura_in.keys():
		var e: Dictionary = _aura_in[mod_id]
		var left := float(e["left"]) - delta
		if left <= 0.0:
			_aura_in.erase(mod_id)
			remove_modifier(mod_id)
		else:
			e["left"] = left


# Attacker side of attack_landed: lifesteal (stat "lifesteal", percent, cap 30) then the signal.
func _on_attack_hit(target: Node3D, dealt: float) -> void:
	# UnitType.on_hit_status (Shardcaster, Rime Colossus: chill). Units only: buildings are immune.
	# Applied even if the attacker died while its bolt was flying.
	if unit_type and unit_type.on_hit_status != &"" and unit_type.on_hit_duration > 0.0:
		var victim := target as Unit
		if victim and victim.is_alive():
			victim.apply_status(unit_type.on_hit_status, unit_type.on_hit_duration)
			# Greywater Tracker snare arrow (market-trade.md 6.1 / 9, task 10.C10): rope coils while it roots.
			if unit_type.on_hit_status == &"rooted" and victim.has_status(&"rooted"):
				_play_trade_vfx(&"snare", victim)
	if unit_type and BowmanKit.is_bowman(unit_type.id):   # bowmen.md: chill / burn / bleed
		BowmanKit.on_hit(self, target, dealt)
	if _dead:
		return
	if dealt > 0.0:
		var ls := get_stat(&"lifesteal")
		if ls > 0.0:
			heal(dealt * ls / 100.0)
	attack_landed.emit(target, dealt)


# ---------------------------------------------------------------- veterancy (levels.md)

## True for soldiers: a UnitType that is not a worker, not neutral (Ruin Wardens, Magpies), not a wizard,
## not a timed summon (Nature Saplings), not a caravan, not a non-commandable hireling (trackers).
func can_gain_veterancy() -> bool:
	return unit_type != null and not unit_type.is_worker and unit_type.faction != &"neutral" \
			and not is_in_group(&"heroes") and unit_type.lifetime <= 0.0 and not unit_type.is_caravan \
			and unit_type.commandable


## Soldiers: adds veterancy XP and levels up (once per level, level_changed each time).
## Does nothing on workers, wardens, dead units. Wizard overrides it with wizard XP.
func add_xp(amount: int) -> void:
	if amount <= 0 or _dead or not can_gain_veterancy():
		return
	xp += amount
	while level < MAX_VETERANCY and xp >= VETERANCY_XP[level]:
		_set_veterancy_level(level + 1)


## "Recruit", "Veteran", "Elite" or "Paragon".
func veterancy_name() -> String:
	return VETERANCY_NAMES[clampi(level, 1, MAX_VETERANCY) - 1]


## Total XP needed for the next veterancy level; 0 at Paragon (the UI shows "XP MAX").
func veterancy_next_xp() -> int:
	return VETERANCY_XP[level] if level < MAX_VETERANCY else 0


func _set_veterancy_level(new_level: int) -> void:
	level = new_level
	var bonus := VETERANCY_BONUS * float(new_level - 1)
	add_modifier(VETERANCY_MODIFIER, {&"max_hp_pct": bonus, &"attack_damage_pct": bonus})
	_gold_flash = GOLD_FLASH_TIME
	_model_call(&"play_level_up")
	if _model and _model.has_method(&"set_veterancy"):   # soldiers only (wizards override add_xp)
		_model.call(&"set_veterancy", level)
	_update_chevrons()
	level_changed.emit(self, level)


## XP a victim is worth (levels.md victim table): units from UnitType.kill_xp, wizards
## 120 + 30 x level, champions 100 + 25 x level, buildings by id (construction sites 25 %, rounded
## down). 0 if unknown.
static func kill_xp_value(victim: Node) -> int:
	if victim == null or not is_instance_valid(victim):
		return 0
	if victim.is_in_group(&"helpers") and victim.has_method(&"helper_kill_xp"):   # t3-helpers.md 3: 100 + 30 x level
		return int(victim.call(&"helper_kill_xp"))
	if victim.is_in_group(&"champions"):
		var clvl: Variant = victim.get(&"level")
		return CHAMPION_KILL_XP + CHAMPION_KILL_XP_PER_LEVEL * (int(clvl) if clvl != null else 1)
	# Any wizard (Vessa is in "heroes", Malrik in "enemy_heroes", a 2v2 allied bot wizard only in "ally_heroes"; R1-2).
	if victim is Wizard or victim.is_in_group(&"heroes") or victim.is_in_group(&"enemy_heroes"):
		var lvl: Variant = victim.get(&"level")
		return WIZARD_KILL_XP + WIZARD_KILL_XP_PER_LEVEL * (int(lvl) if lvl != null else 1)
	var unit := victim as Unit
	if unit:
		return unit.unit_type.kill_xp if unit.unit_type else 0
	var bt: Variant = victim.get(&"building_type")
	if bt is Resource:
		var value := int(BUILDING_KILL_XP.get((bt as Resource).get(&"id"), 0))
		if victim.has_method(&"is_constructed") and not bool(victim.call(&"is_constructed")):
			value = floori(value * CONSTRUCTION_XP_RATIO)
		return value
	return 0


## Soldier veterancy for one kill: a soldier that dealt the killing blow gets 100 % of the victim's
## XP, every OTHER soldier of the killer's team within 8 m of the victim 25 % (rounded up, min 1),
## whoever the killer is (soldier, wizard, tower). Unit.die() calls it; buildings may call it too.
## Wizard XP is NOT given here (wizard.gd listens to Events.unit_died and reads `killer`).
## Champion XP and loot are: every node in group "champions" with `credit_kill(victim, killer, value)`
## is told about the kill (champions.md 5: killing blow 100 % + loot, own kills within 12 m 25 %).
static func award_soldier_kill_xp(victim: Node3D, killer_node: Node3D) -> void:
	if victim == null or not is_instance_valid(victim) or not victim.is_inside_tree():
		return
	if killer_node == null or not is_instance_valid(killer_node):
		return
	var killer_team: Variant = killer_node.get(&"team")
	var victim_team: Variant = victim.get(&"team")
	if killer_team == null or (victim_team != null and int(victim_team) == int(killer_team)):
		return
	var value := kill_xp_value(victim)
	if value <= 0:
		return
	for ch in victim.get_tree().get_nodes_in_group(&"champions"):
		if ch != victim and ch.has_method(&"credit_kill"):
			ch.call(&"credit_kill", victim, killer_node, value)
	var killer_unit := killer_node as Unit
	if killer_unit and killer_unit.can_gain_veterancy():
		killer_unit.add_xp(value)
	var share := maxi(1, ceili(value * XP_SHARE_RATIO))
	var at := victim.global_position
	for node in victim.get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u == null or u == killer_unit or int(u.team) != int(killer_team) or not u.is_alive() \
				or not u.can_gain_veterancy():
			continue
		if Vector2(u.global_position.x - at.x, u.global_position.z - at.z).length() <= XP_SHARE_RADIUS:
			u.add_xp(share)


# The "^" / "^^" / "^^^" mark above Veteran / Elite / Paragon soldiers (hidden at Recruit).
func _update_chevrons() -> void:
	if level <= 1 or _dead:
		if _chevrons:
			_chevrons.visible = false
		return
	if _chevrons == null:
		_chevrons = Label3D.new()
		_chevrons.name = "Chevrons"
		_chevrons.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_chevrons.modulate = GOLD
		_chevrons.outline_modulate = Color.BLACK
		_chevrons.outline_size = 8
		_chevrons.font_size = 48
		_chevrons.pixel_size = 0.006
		_chevrons.position.y = body_height + 0.8   # above the HP bar (body_height + 0.5)
		_chevrons.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_chevrons.no_depth_test = true   # hats / staffs never hide it (art-units.md 7.4)
		add_child(_chevrons)
	_chevrons.text = "^".repeat(level - 1)
	_chevrons.visible = true


func command_move(target: Vector3) -> void:
	order_serial += 1
	_model_call(&"stop_clip")   # an order ends a dance (play_clip)
	attack_target = null
	_auto_target = false
	_has_move_order = true
	_attack_move = false
	_hold = false
	_set_nav_target(target)


## Attack `target`: an enemy Unit or an enemy building. An explicit order is always obeyed
## (no switching to closer units). The parameter is untyped only because Worker overrides it
## with `target: Unit`; pass a Unit or a building node.
func command_attack(target) -> void:
	if not _target_alive(target) or is_non_combatant():
		return
	var node := target as Node3D
	if node == null or not is_enemy_of(node):
		return
	order_serial += 1
	_model_call(&"stop_clip")
	attack_target = node
	_auto_target = false
	_has_move_order = false
	_attack_move = false
	_hold = false


## Points the unit's own auto-aggro at `target` (an enemy Unit or building), as if it had picked it itself: the
## attack-move "don't chase across the map" rule and the chase leash (_chase_leash() from its anchor) still apply,
## and the current order (attack-move, idle) is kept. Not a player order: order_serial does not change. Used by the
## bot's target preference (AICasters), which must never send soldiers on an unleashed chase.
func set_auto_target(target: Node3D) -> void:
	if not _target_alive(target) or is_non_combatant() or not is_enemy_of(target):
		return
	attack_target = target
	_auto_target = true


## Clears `attack_target` only when it is `target` (Smoke Pouch, Mother Hush's Smoke / Night of Knives: the enemy
## loses sight of her). The order is kept: an attack-move walks on, a hold holds, an idle unit picks a new target by
## auto-aggro. An explicit attack order on `target` ends (there is nothing left to attack). Not a player order.
func drop_target_if(target: Node3D) -> void:
	if target == null or attack_target != target:
		return
	attack_target = null
	_auto_target = false


## Puts the unit at `pos` (snapped to the navmesh), quietly: no order change, no signal, no animation. Used when a
## system must move a unit out of the way (a new building's footprint, a teleport). The leash anchor and the path
## restart from the new spot; a move / attack-move / gather order goes on from there.
func set_down(pos: Vector3) -> void:
	if not is_inside_tree():
		position = pos
		return
	var p := snap_to_navmesh(pos)
	global_position = Vector3(p.x, global_position.y, p.z)
	UnitGrid.mark_dirty()
	velocity = Vector3.ZERO
	_displace = {}
	_anchor = global_position
	var dest := _last_nav_target
	_last_nav_target = Vector3.INF
	if _agent:
		_agent.velocity = Vector3.ZERO
		if dest != Vector3.INF:
			_set_nav_target(dest)   # same destination, new path from here


## `pos` moved onto the closest point of the navmesh (and off water when a river is there); `pos` itself when the
## unit is not in the tree or the map has no navmesh yet.
func snap_to_navmesh(pos: Vector3) -> Vector3:
	if not is_inside_tree():
		return pos
	var world := get_world_3d()
	if world == null:
		return pos
	var map := world.navigation_map
	if not map.is_valid() or NavigationServer3D.map_get_iteration_id(map) <= 0 \
			or NavigationServer3D.map_get_regions(map).is_empty():
		return pos
	var q := NavigationServer3D.map_get_closest_point(map, pos)
	var river := get_tree().get_first_node_in_group(&"river")
	if river != null and river.has_method(&"is_water") and bool(river.call(&"is_water", q)) \
			and river.has_method(&"nearest_land"):
		var land: Variant = river.call(&"nearest_land", q)
		if land is Vector3:
			q = NavigationServer3D.map_get_closest_point(map, land)
	return Vector3(q.x, pos.y, q.z)


## Walk to target; fight any enemy met within aggro_range on the way, then resume the walk.
func command_attack_move(target: Vector3) -> void:
	order_serial += 1
	_model_call(&"stop_clip")
	attack_target = null
	_auto_target = false
	_has_move_order = true
	_attack_move = true
	_attack_move_target = target
	_hold = false
	_set_nav_target(target)


## Stay on this spot until another order; only attack enemies already in attack range.
func command_hold() -> void:
	command_stop()
	_hold = true


func command_stop() -> void:
	order_serial += 1
	_model_call(&"stop_clip")
	attack_target = null
	_auto_target = false
	_has_move_order = false
	_attack_move = false
	_hold = false
	_anchor = global_position


func is_attack_moving() -> bool:
	return _attack_move


func is_holding() -> bool:
	return _hold


## True while the unit walks on a plain move order (not an attack-move): caster autocast waits meanwhile.
func has_move_order() -> bool:
	return _has_move_order and not _attack_move


## Caster units: for `seconds` the unit neither walks nor attacks (its 0.4 s cast); orders are kept. Never shortens.
func set_cast_lock(seconds: float) -> void:
	_cast_lock_left = maxf(_cast_lock_left, seconds)


func cast_lock_left() -> float:
	return maxf(0.0, _cast_lock_left)


## Ends a cast lock now (a channel was cancelled by a new order).
func clear_cast_lock() -> void:
	_cast_lock_left = 0.0


## The fog sight cap of the statuses on this unit (`hazed`: 4 m), INF when none. FogOfWar.sight_of applies it.
func status_sight_cap() -> float:
	return _status_sight_cap


## The reach of this unit's attacks now: attack_range, capped by `hazed` for ranged units (range > 3).
func effective_attack_range() -> float:
	if attack_range > 3.0 and _status_range_cap < attack_range:
		return _status_range_cap
	return attack_range


## Forced movement (Snagroot's pull, caster-units.md 5.3): slides the unit in a straight line toward `to` over
## `seconds`, stopping short where the line leaves the navmesh, meets water, a Rime Bulwark or a building. Orders are
## dropped (command_stop), channels break (signal `displaced`). Returns the end point (the start when blocked at once).
func displace(to: Vector3, seconds: float) -> Vector3:
	if _dead or not is_inside_tree():
		return global_position
	var from := global_position
	var end := _displace_end(from, Vector3(to.x, from.y, to.z))
	command_stop()
	displaced.emit(self)
	if end.distance_to(from) < 0.05:
		return from
	_displace = {"from": from, "to": end, "t": 0.0, "time": maxf(0.05, seconds)}
	velocity = Vector3.ZERO
	if _agent:
		_agent.velocity = Vector3.ZERO
	return end


## True while displace() moves this unit.
func is_displaced() -> bool:
	return not _displace.is_empty()


const DISPLACE_STEP := 0.5
const DISPLACE_NAV_TOLERANCE := 0.6


# The furthest point of the line from -> to (0.5 m samples) on the navmesh, dry, outside Bulwarks and buildings.
func _displace_end(from: Vector3, to: Vector3) -> Vector3:
	var flat := Vector3(to.x - from.x, 0.0, to.z - from.z)
	var dist := flat.length()
	if dist < 0.01:
		return from
	var dir := flat / dist
	var river := get_tree().get_first_node_in_group(&"river")
	if river != null and not river.has_method(&"is_water"):
		river = null
	var map := RID()
	var world := get_world_3d()
	if world:
		map = world.navigation_map
		if not map.is_valid() or NavigationServer3D.map_get_iteration_id(map) <= 0 \
				or NavigationServer3D.map_get_regions(map).is_empty():
			map = RID()
	var buildings := get_tree().get_nodes_in_group(&"buildings")
	var last := from
	var steps := ceili(dist / DISPLACE_STEP)
	for i in range(1, steps + 1):
		var p := from + dir * minf(dist, float(i) * DISPLACE_STEP)
		p.y = from.y
		if river != null and bool(river.call(&"is_water", p)):
			break
		if map.is_valid():
			var q := NavigationServer3D.map_get_closest_point(map, p)
			if Vector2(q.x - p.x, q.z - p.z).length() > DISPLACE_NAV_TOLERANCE:
				break
		if CasterKit.bulwark_blocks(p, radius):
			break
		var hit_building := false
		for b in buildings:
			var bn := b as Node3D
			if bn == null or not bn.has_method(&"is_alive") or not bool(bn.call(&"is_alive")):
				continue
			if Vector2(bn.global_position.x - p.x, bn.global_position.z - p.z).length() < radius_of(bn) + radius * 0.5:
				hit_building = true
				break
		if hit_building:
			break
		last = p
	return last


func _tick_displace(delta: float) -> void:
	var d := _displace
	d["t"] = float(d["t"]) + delta
	var k := clampf(float(d["t"]) / float(d["time"]), 0.0, 1.0)
	var from: Vector3 = d["from"]
	var to: Vector3 = d["to"]
	var p := from.lerp(to, k)
	global_position = Vector3(p.x, global_position.y, p.z)
	velocity = Vector3.ZERO
	if _agent:
		_agent.velocity = Vector3.ZERO
	if k >= 1.0:
		_displace = {}
		_last_nav_target = Vector3.INF
		_anchor = global_position


## True for a Unit or building (anything with a `team`) of another team: PLAYER and ENEMY are
## enemies, NEUTRAL is the enemy of both, the same team never is.
func is_enemy_of(other: Node3D) -> bool:
	if other == null or not is_instance_valid(other):
		return false
	var other_team: Variant = other.get(&"team")
	if other_team == null or Teams.is_allied_fast(int(other_team), int(team)):
		return false
	if truce_count > 0 and in_truce(self, other):
		return false
	return true


## 2v2 (map-2v2.md 5): two seats of one side (or the same team). NEUTRAL is allied only with itself.
static func are_allies(a: int, b: int) -> bool:
	return Teams.is_allied_fast(a, b)


## `other` is on this unit's side (own team or an allied seat).
func is_ally_of(other: Node3D) -> bool:
	if other == null or not is_instance_valid(other):
		return false
	var other_team: Variant = other.get(&"team")
	return other_team != null and Teams.is_allied_fast(int(other_team), int(team))


## Nodes currently carrying a truce id (set_truce_id keeps it): 0 = no truce anywhere, the hot paths skip the check.
static var truce_count := 0


## Gives `node` the truce id `id` (&"" = removes it). Use this, not set_meta, so truce_count stays right.
static func set_truce_id(node: Node, id: StringName) -> void:
	if node == null:
		return
	var had := node.has_meta(TRUCE_META)
	if id == &"":
		if had:
			node.remove_meta(TRUCE_META)
			truce_count = maxi(0, truce_count - 1)
		return
	if not had:
		truce_count += 1
	node.set_meta(TRUCE_META, id)


## Mission truce (MissionBase.set_truce, mission-e7-02.md D8): two nodes with the same meta "truce" id never treat each
## other as enemies; the id &"all" (MissionBase.withdraw_seat) is at peace with everyone.
static func in_truce(a: Node, b: Node) -> bool:
	if truce_count <= 0 or a == null or b == null or (not a.has_meta(TRUCE_META) and not b.has_meta(TRUCE_META)):
		return false
	var ta: StringName = StringName(a.get_meta(TRUCE_META, &""))
	var tb: StringName = StringName(b.get_meta(TRUCE_META, &""))
	return ta == TRUCE_ALL or tb == TRUCE_ALL or (ta != &"" and ta == tb)


func is_neutral() -> bool:
	return team == Team.NEUTRAL


## True for NEUTRAL camp guardians (Ruin Wardens): they fight only inside leash_radius() of home and walk
## back there. NEUTRAL units whose UnitType has `neutral_leash = false` (Magpies) roam and keep their
## orders like PLAYER / ENEMY units.
func has_neutral_leash() -> bool:
	return team == Team.NEUTRAL and (unit_type == null or unit_type.neutral_leash)


## Where the unit lives when idle (set by command_stop(); main._spawn calls it after placing a unit).
## Neutral units always walk back here and only fight within leash_radius() of it.
func home_position() -> Vector3:
	return _anchor


## Neutral units: enemies further than this from home_position() are ignored and never chased.
func leash_radius() -> float:
	return aggro_range * NEUTRAL_LEASH_FACTOR


## Ring / minimap colour of a team (green, red, grey-gold). UI may reuse it.
static func team_color(t: int) -> Color:
	match t:
		Team.PLAYER:
			return Color(0.3, 1.0, 0.4)
		Team.NEUTRAL:
			return Color(0.9, 0.78, 0.42)
		Team.ALLY:
			return Color(0.35, 0.75, 1.0)
		Team.ENEMY_2:
			return Color(1.0, 0.55, 0.25)
	return Color(1.0, 0.3, 0.3)


## HP bar fill colour of a team.
static func team_hp_color(t: int) -> Color:
	match t:
		Team.PLAYER:
			return Color(0.25, 0.9, 0.3)
		Team.NEUTRAL:
			return Color(0.8, 0.7, 0.4)
		Team.ALLY:
			return Color(0.3, 0.65, 0.95)
		Team.ENEMY_2:
			return Color(0.95, 0.5, 0.2)
	return Color(0.9, 0.25, 0.3)


func is_alive() -> bool:
	return not _dead


## How far from our centre an attacker may stand and still reach us (on top of its own range).
func target_radius() -> float:
	return radius


## `attacker` is the Unit or building (tower) that hit us, or null.
func take_damage(amount: float, attacker: Node3D = null) -> void:
	if _dead:
		return
	amount *= _damage_taken_mult   # shroud: before armor and before the HP check (items.md order)
	if _armor != 0.0:
		amount *= armor_multiplier(_armor)
	if shield > 0.0 and amount > 0.0:   # the shield pool goes before HP (after armor)
		var absorbed := minf(shield, amount)
		shield -= absorbed
		amount -= absorbed
		if shield <= 0.0:
			shield = 0.0
			_shield_left = 0.0
		shield_changed.emit(shield)
	hp -= amount
	_since_damage = 0.0
	_hit_flash = 1.0
	if amount > 0.0 and _model_has_hit:
		_model.call(&"play_hit")
	_update_hp_bar()
	damage_taken.emit(amount, attacker if attacker != null and is_instance_valid(attacker) else null)
	if hp <= 0.0:
		if death_guard.is_valid() and bool(death_guard.call(attacker)) and hp > 0.0:
			_update_hp_bar()
			return
		killer = attacker if attacker != null and is_instance_valid(attacker) else null
		die()
		return
	# Fight back if we're just standing around (or attack-moving). Held units only hit back
	# when the attacker is in range. A unit hitting us wins over a building we picked ourselves;
	# a building (tower) hitting us is only answered when no enemy unit is near.
	if attacker == null or not is_instance_valid(attacker) or not _target_alive(attacker) \
			or not is_enemy_of(attacker) or (_has_move_order and not _attack_move) \
			or (_hold and not _in_attack_range(attacker)) or not _in_leash(attacker) or is_non_combatant():
		return
	var attacker_is_unit := attacker is Unit
	if attack_target == null:
		if attacker_is_unit or _find_nearest_enemy(aggro_range) == null:
			attack_target = attacker
			_auto_target = true
	elif attacker_is_unit and _auto_target and not attack_target is Unit:
		attack_target = attacker


## Does nothing to a dead unit.
func heal(amount: float) -> void:
	if _dead:
		return
	hp = min(max_hp, hp + amount)
	_update_hp_bar()


func die() -> void:
	if _dead:
		return
	_enter_dead_state()
	award_soldier_kill_xp(self, killer)
	_spread_dots(_dots_at_death, global_position)
	_dots_at_death = {}
	died.emit(self)
	_after_death_signals()


# The silent part of die(): dead, out of "units", not clickable, statuses / DoTs / shield / auras gone. Also used to
# restore an already fallen champion from a save (Champion.restore_fallen, no signals).
func _enter_dead_state() -> void:
	_dead = true
	hp = 0.0
	selected = false
	_displace = {}
	_cast_lock_left = 0.0
	remove_from_group("units")
	collision_layer = 0
	if _agent:
		_agent.avoidance_enabled = false
	set_physics_process(false)
	if _hp_bar:
		_hp_bar.visible = false
	_update_chevrons()   # hides them
	for status_id: StringName in _statuses.keys():
		_end_status(status_id)
	_dots_at_death = _dots
	_dots = {}
	for id: StringName in _dots_at_death:
		_remove_mark(id)
	_clear_shield()
	for mod_id: StringName in _aura_in:
		_mods.erase(mod_id)
	if not _aura_in.is_empty():
		_aura_in.clear()
		_recompute_stats(false)


# The rest of die() once `died` went out: Events.unit_died, then the death animation (or tween) and _on_death_finished.
func _after_death_signals() -> void:
	# Autoloads are looked up at runtime (not by name) so headless test scripts still compile.
	var events := get_node_or_null(^"/root/Events")
	if events:
		events.unit_died.emit(self)
	_shot_left = -1.0
	_shot_target = null
	_death_done = false
	_death_serial += 1
	if _model and _model.has_method(&"play_death"):
		if _model_has_moving:
			_model.call(&"set_moving", 0.0)
		_model_speed_sent = 0.0
		_model.call(&"play_death")
		# death_finished is connected once in _build_visual; the timer covers a model that never emits.
		get_tree().create_timer(DEATH_FALLBACK_TIME).timeout.connect(_on_death_fallback.bind(_death_serial))
		return
	_death_tween = create_tween()
	_death_tween.tween_property(_visual, "scale", Vector3(1.3, 0.05, 1.3), 0.35)
	_death_tween.tween_callback(_finish_death)


## The unit leaves the battlefield without dying (market-trade.md 5.3 / 6.1: a Magpie home at its Den, a
## tracker at its contract end). No `died`, no Events.unit_died, no XP / essence / loot / kill credit. It
## stops at once (is_alive() false, out of group "units", not clickable, statuses and auras gone), emits
## left_map(unit), fades out over LEAVE_MAP_FADE (1 s) and is freed; its pop is freed when it leaves the
## tree (Economy). Does nothing on a dead unit or one already leaving.
func leave_map() -> void:
	if _dead:
		return
	_dead = true
	_left_map = true
	killer = null
	selected = false
	attack_target = null
	_auto_target = false
	_has_move_order = false
	_attack_move = false
	_hold = false
	taunted_by = null
	_shot_left = -1.0
	_shot_target = null
	remove_from_group("units")
	collision_layer = 0
	velocity = Vector3.ZERO
	set_physics_process(false)
	if _agent:
		_agent.avoidance_enabled = false
		_agent.velocity = Vector3.ZERO
	if _hp_bar:
		_hp_bar.visible = false
	_update_chevrons()   # hides them
	for status_id: StringName in _statuses.keys():
		_end_status(status_id)
	for id: StringName in _dots.keys():
		_remove_mark(id)
	_dots.clear()
	_clear_shield()
	_auras.clear()
	if not _aura_in.is_empty():
		for mod_id: StringName in _aura_in:
			_mods.erase(mod_id)
		_aura_in.clear()
		_recompute_stats(false)
	if _model_has_moving:
		_model.call(&"set_moving", 0.0)
		_model_speed_sent = 0.0
	left_map.emit(self)
	if not is_inside_tree():
		queue_free()
		return
	_death_tween = create_tween()
	_death_tween.tween_method(_set_fade, 0.0, 1.0, LEAVE_MAP_FADE)
	_death_tween.tween_callback(queue_free)


## True once leave_map() was called (the unit is fading out or gone, it did not die).
func has_left_map() -> bool:
	return _left_map


# leave_map fade: 0 = opaque, 1 = invisible, on every mesh of the look (placeholder or model).
func _set_fade(amount: float) -> void:
	if _visual:
		_fade_tree(_visual, amount)


static func _fade_tree(node: Node, amount: float) -> void:
	for child in node.get_children():
		var geo := child as GeometryInstance3D
		if geo:
			geo.transparency = amount
		_fade_tree(child, amount)


func _on_model_death_finished() -> void:
	if _dead:
		_finish_death()


func _on_death_fallback(serial: int) -> void:
	if serial == _death_serial and _dead and is_instance_valid(self):
		_finish_death()


# Runs _on_death_finished once per death (model signal, fallback timer or placeholder tween).
func _finish_death() -> void:
	if _death_done:
		return
	_death_done = true
	_on_death_finished()


## Called when the death animation ends. Units are freed; Wizard overrides it to stay in the
## tree (hidden) so it can respawn.
func _on_death_finished() -> void:
	queue_free()


## Undoes die(): alive at `at` with full HP, no orders, back in "units", collidable, visible.
## Wizard.respawn() is the public entry point.
func _revive(at: Vector3) -> void:
	if _death_tween and _death_tween.is_valid():
		_death_tween.kill()
	_death_tween = null
	_dead = false
	_death_done = false
	_death_serial += 1   # a pending fallback timer of the last death does nothing now
	_shot_left = -1.0
	_shot_target = null
	_model_speed_sent = 0.0
	global_position = at
	attack_target = null
	_auto_target = false
	_has_move_order = false
	_attack_move = false
	_hold = false
	_anchor = at
	velocity = Vector3.ZERO
	_vertical_speed = 0.0
	_cooldown_left = 0.0
	_retarget_left = 0.0
	_hit_flash = 0.0
	_frozen_immune_left = 0.0
	_hidden_auto_left = 0.0
	_displace = {}
	_cast_lock_left = 0.0
	taunted_by = null
	hp = max_hp
	_visual.scale = Vector3.ONE
	_visual.position = Vector3.ZERO
	if _body_mat:
		_body_mat.emission_energy_multiplier = 0.0
	visible = true
	if not is_in_group("units"):
		add_to_group("units")
	UnitGrid.mark_dirty()
	collision_layer = 2
	_last_nav_target = Vector3.INF
	_set_nav_target(at)
	_avoid_gated = false
	_agent.avoidance_enabled = true
	_agent.velocity = Vector3.ZERO
	set_physics_process(true)
	_model_call(&"revive")
	_update_hp_bar()


func set_selected(value: bool) -> void:
	selected = value
	if _ring:
		_ring.visible = value
	_update_hp_bar()


# ---------------------------------------------------------------- per-frame logic

func _physics_process(delta: float) -> void:
	if _shot_left > 0.0 and _can_act_flag:   # a frozen archer holds its drawn shot
		_shot_left -= delta
		if _shot_left <= 0.0:
			_release_shot()
	_cooldown_left = max(0.0, _cooldown_left - delta)
	_retarget_left -= delta
	_since_damage += delta
	_update_hit_flash(delta)
	if not _statuses.is_empty():
		_tick_statuses(delta)
	if _frozen_immune_left > 0.0:
		_frozen_immune_left -= delta
	if not _dots.is_empty():
		_tick_dots(delta)
		if _dead:
			return
	if _lifetime_left > 0.0:
		_lifetime_left -= delta
		if _lifetime_left <= 0.0:
			_lifetime_left = 0.0
			killer = null
			die()   # the summon withers: no killer, so no XP
			return
	if _idle_regen_pct > 0.0:
		_idle_regen_left -= delta
		if _idle_regen_left <= 0.0:
			_idle_regen_left += IDLE_REGEN_TICK
			if _since_damage >= IDLE_REGEN_DELAY and hp < max_hp:
				hp = minf(max_hp, hp + max_hp * _idle_regen_pct / 100.0 * IDLE_REGEN_TICK)
				_update_hp_bar()
	if shield > 0.0:
		_shield_left -= delta
		if _shield_left <= 0.0:
			_clear_shield()
	if not _auras.is_empty():
		_aura_tick_left -= delta
		if _aura_tick_left <= 0.0:
			_aura_tick_left = AURA_TICK
			_refresh_auras()
	if not _aura_in.is_empty():
		_tick_aura_in(delta)
	if _hp_regen > 0.0 and hp < max_hp:
		hp = minf(max_hp, hp + _hp_regen * delta)
		_update_hp_bar()

	# On the floor: no downward push, floor snapping keeps us grounded. Pushing into the floor
	# (the old -1 m/s) made move_and_slide collide and re-slide every frame, ~4x its cost (task 5.P1).
	if is_on_floor():
		_vertical_speed = 0.0
	else:
		_vertical_speed -= GRAVITY * delta

	if attack_target != null and not _target_alive(attack_target):
		attack_target = null
	# Neutral camp units never leave their camp: a target outside the leash is dropped.
	if attack_target != null and has_neutral_leash() and not _in_leash(attack_target):
		attack_target = null
		_auto_target = false
	# Taunted: the source is the only target (orders are dropped; auto-aggro resumes afterwards).
	if taunted_by != null:
		if _statuses.has(&"taunted") and _target_alive(taunted_by) and is_enemy_of(taunted_by):
			attack_target = taunted_by
			_auto_target = false
			_has_move_order = false
			_attack_move = false
			_hold = false
		else:
			taunted_by = null
	if _hidden_auto_left > 0.0:
		_hidden_auto_left -= delta

	# Pulled (displace): the slide moves the unit by position; nothing else runs until it ends.
	if not _displace.is_empty():
		_tick_displace(delta)
		_agent.avoidance_priority = 1.0
		return

	# Frozen: nothing runs (no walking, no attacks, no retargeting); every order is kept and resumes.
	if not _can_act_flag:
		_agent.avoidance_priority = 1.0
		_submit_velocity(Vector3.ZERO)
		return

	# A caster's 0.4 s cast (set_cast_lock): it stands still and does not attack; orders are kept.
	if _cast_lock_left > 0.0:
		_cast_lock_left -= delta
		_agent.avoidance_priority = 1.0
		_submit_velocity(Vector3.ZERO)
		return

	# Direct control (Wizard.set_move_input): walk where we're told, no orders, no auto-aggro.
	var direct := _direct_velocity()
	if direct != Vector3.INF:
		_agent.avoidance_priority = 1.0
		_submit_velocity(direct if _can_move_flag else Vector3.ZERO)
		return

	# Held units never chase: a target that leaves attack range is dropped.
	if _hold and attack_target != null and not _in_attack_range(attack_target):
		attack_target = null

	# Idle, held and attack-moving units look for trouble a few times per second.
	# Enemy units come first: a building we picked ourselves is dropped when a unit shows up.
	if (not _has_move_order or _attack_move) and _scan_due() \
			and (attack_target == null or (_auto_target and not attack_target is Unit)) \
			and not is_non_combatant():
		_retarget_left = RETARGET_INTERVAL
		retarget_scans += 1
		var search := attack_range + radius + MAX_UNIT_RADIUS if _hold else aggro_range
		var enemy := _find_auto_target(search)
		if enemy and (not _hold or _in_attack_range(enemy)) \
				and (attack_target == null or enemy is Unit):
			attack_target = enemy
			_auto_target = true

	var desired := Vector3.ZERO

	if attack_target != null:
		if _attack_move and _auto_target \
				and _flat_distance(attack_target.global_position) > max(aggro_range, attack_range) * 2.0:
			# Attack-move: don't chase across the map, carry on walking.
			attack_target = null
			_auto_target = false
		elif _auto_target and not _attack_move and not _hold and not has_neutral_leash() \
				and _flat_distance(_anchor) > _chase_leash():
			# Leash: don't chase an enemy we picked ourselves across the whole map.
			attack_target = null
			_auto_target = false
			_has_move_order = true
			_set_nav_target(_anchor)
		elif _in_attack_range(attack_target):
			_face(attack_target.global_position - global_position)
			if _cooldown_left <= 0.0 and not attacks_blocked:
				_cooldown_left = attack_cooldown
				_perform_attack(attack_target)
		elif not _hold:
			_set_nav_target(attack_target.global_position)
			desired = _path_velocity()

	# Neutral units walk back home when nothing is left to fight in their camp (still looking
	# for trouble inside the leash on the way).
	if attack_target == null and has_neutral_leash() and not _has_move_order \
			and _flat_distance(_anchor) > HOME_TOLERANCE:
		_set_nav_target(_anchor)
		desired = _path_velocity()

	if attack_target == null and _has_move_order:
		if _attack_move:
			_set_nav_target(_attack_move_target)   # resume the walk after a fight
		if _agent.is_navigation_finished():
			_has_move_order = false
			_attack_move = false
			_anchor = global_position
		else:
			desired = _path_velocity()

	# Moving units ignore idle ones in avoidance, and idle units step aside, so a crowd of
	# idle soldiers can't block a path (for example a gap between pillars). Held units don't
	# step aside. Rooted units keep their orders (and still attack in range) but stand still.
	if not _can_move_flag:
		desired = Vector3.ZERO
	_agent.avoidance_priority = 1.0 if desired != Vector3.ZERO or _hold or not _can_move_flag else 0.5
	_submit_velocity(desired)


## The wanted velocity goes to the RVO agent (its velocity_computed answer moves us), or straight to the mover while
## avoidance is gated off (the agent sends no answer then).
func _submit_velocity(v: Vector3) -> void:
	if _avoid_gated:
		_on_velocity_computed(v)
	else:
		_agent.velocity = v


## P2: is this physics frame one where the auto-aggro scan may run?
func _scan_due() -> bool:
	if scan_bucket < 0:
		return _retarget_left <= 0.0
	return Engine.get_physics_frames() % SCAN_BUCKETS == scan_bucket


## P3 (wave-strike.md 14.2, LaneMarch only): true = RVO avoidance off (the unit walks its own path through friends),
## false = back on. Death turns avoidance off anyway; revive clears the gate.
func set_avoidance_gated(off: bool) -> void:
	if off == _avoid_gated or _dead or _agent == null:
		return
	_avoid_gated = off
	_agent.avoidance_enabled = not off


func is_avoidance_gated() -> bool:
	return _avoid_gated


## True when a living enemy unit stands within `max_distance` m on the ground (UnitGrid when the level has one, else a
## full scan). Cheap early-out query for LaneMarch's avoidance gate; no leash / hidden / caster filters.
func has_enemy_within(max_distance: float) -> bool:
	var me := global_position
	var max_d2 := max_distance * max_distance
	var grid := UnitGrid.current()
	if grid == null:
		for node in get_tree().get_nodes_in_group(&"units"):
			var o := node as Unit
			if o == null or o.team == team or o._dead:
				continue
			var dx := o.global_position.x - me.x
			var dz := o.global_position.z - me.z
			if dx * dx + dz * dz < max_d2 and is_enemy_of(o) and o.is_alive():
				return true
		return false
	grid.prepare()
	var reach := max_distance + UnitGrid.SLACK
	var reach2 := reach * reach
	var c0 := grid.col_of(me.x - reach)
	var c1 := grid.col_of(me.x + reach)
	var r0 := grid.row_of(me.z - reach)
	var r1 := grid.row_of(me.z + reach)
	var cols := grid.cols
	var start := grid.cell_start
	var items := grid.items
	var px := grid.pos_x
	var pz := grid.pos_z
	var teams := grid.teams
	for r in range(r0, r1 + 1):
		for c in range(c0, c1 + 1):
			var cell := r * cols + c
			for k in range(start[cell], start[cell + 1]):
				var i := items[k]
				if teams[i] == team:
					continue
				var bx := px[i] - me.x
				var bz := pz[i] - me.z
				if bx * bx + bz * bz >= reach2:
					continue
				var node: Variant = grid.units[i]
				if not is_instance_valid(node):
					continue
				var o := node as Unit
				if o._dead:
					continue
				var dx := o.global_position.x - me.x
				var dz := o.global_position.z - me.z
				if dx * dx + dz * dz < max_d2 and is_enemy_of(o) and o.is_alive():
					return true
	return false


func _on_velocity_computed(safe_velocity: Vector3) -> void:
	if _dead:
		return
	if _hold or not _can_move_flag:
		safe_velocity = Vector3.ZERO   # avoidance must not push a held / frozen / rooted unit around
	velocity = Vector3(safe_velocity.x, _vertical_speed, safe_velocity.z)
	# Perf pass 2026-10-09 (~10 us per call at 300 units): a unit standing still on the floor skips the slide, which
	# would not move it; every IDLE_SLIDE_EVERY physics frames (staggered per unit) it still runs once so floor
	# snapping / depenetration keep working.
	# The stagger comes from where the unit stood on its first slide (replay-stable: instance ids are not the same
	# from one process to the next, so a stagger from them broke replay determinism, fix 2026-10-09).
	if _slide_phase < 0:
		var gp := global_position
		_slide_phase = posmod(int(floorf(gp.x * 4.0)) * 7 + int(floorf(gp.z * 4.0)) * 13, IDLE_SLIDE_EVERY)
	var still := safe_velocity.x * safe_velocity.x + safe_velocity.z * safe_velocity.z <= IDLE_SLIDE_EPS2
	if not still or _vertical_speed != 0.0 or not is_on_floor() or (Engine.get_physics_frames() + _slide_phase) % IDLE_SLIDE_EVERY == 0:
		move_and_slide()
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	var speed := flat.length()
	if speed > 0.3:
		_face(flat)
	# Walk / idle for the model: only on a real change (hysteresis), never every frame.
	if _model_has_moving and (absf(speed - _model_speed_sent) > MOVING_HYSTERESIS
			or (speed >= MOVING_THRESHOLD) != (_model_speed_sent >= MOVING_THRESHOLD)):
		_model_speed_sent = speed
		_model.call(&"set_moving", speed)


## Subclasses that steer the unit themselves (Wizard direct control) return the velocity to use;
## Vector3.INF means "no, run the normal order / pathfinding logic".
func _direct_velocity() -> Vector3:
	return Vector3.INF


func _perform_attack(target: Node3D) -> void:
	if attack_range > 3.0:
		if _model_has_attack:
			_model.call(&"play_attack")
			if _model_windup > 0.0:
				if _shot_left > 0.0:   # never drop a shot still waiting (only with absurd cooldowns)
					_release_shot()
				# D2: the bolt leaves at the model's release frame; the cooldown already started.
				_shot_left = _model_windup
				_shot_target = target
				return
		_spawn_shot(target)
	else:
		if _model_has_attack:
			_model.call(&"play_attack")   # the model's strike replaces the placeholder lunge
		else:
			_lunge()
		var before: Variant = target.get(&"hp")
		melee_strike_active = true
		target.call(&"take_damage", attack_damage, self)
		melee_strike_active = false
		var after: Variant = target.get(&"hp")
		var dealt := attack_damage
		if before != null and after != null:
			dealt = float(before) - maxf(0.0, float(after))
		_on_attack_hit(target, dealt)


func _spawn_shot(target: Node3D) -> void:
	var dmg := attack_damage
	if unit_type and BowmanKit.is_bowman(unit_type.id):   # bowmen.md: crits, Hamstring Shot
		dmg = BowmanKit.shot_damage(self, target)
	var bolt := Projectile.new()
	get_tree().current_scene.add_child(bolt)
	bolt.launch_at_target(self, _shot_origin(), target, dmg, projectile_color,
			0.22 if dmg > attack_damage + 0.01 else 0.14, _bolt_speed())
	bolt.hit_unit.connect(_on_attack_hit)


# The auto-attack bolt speed: UnitType.projectile_speed (Gloomcap Elder 14), else the old 25 m/s.
func _bolt_speed() -> float:
	if unit_type != null and unit_type.projectile_speed > 0.0:
		return unit_type.projectile_speed
	return DEFAULT_BOLT_SPEED


## Where this unit's ranged bolts start (world space). Champions use their model's get_beam_origin().
func _shot_origin() -> Vector3:
	if unit_type and BowmanKit.is_bowman(unit_type.id) and model_has(&"get_bow_tip_position"):
		var tip: Variant = _model.call(&"get_bow_tip_position")   # bowmen.md: arrows leave the bow
		if tip is Vector3:
			return tip
	return global_position + Vector3.UP * body_height * 0.75


# The windup is over: shoot, unless we died or the target is gone.
func _release_shot() -> void:
	_shot_left = -1.0
	var target := _shot_target
	_shot_target = null
	if _dead or not _target_alive(target):
		return
	_spawn_shot(target)


## Calls an argument-less model hook if the model has it.
func _model_call(method: StringName) -> void:
	if _model and _model.has_method(method):
		_model.call(method)


## True when a character model replaced the placeholder capsule.
func has_model() -> bool:
	return _model != null


## The character model node (null for placeholders). Read only; tests and VFX may inspect it.
func get_model() -> Node3D:
	return _model


## Calls the model hook `method` with `args` when the model has it: the public way for other systems (ThiefBand,
## TrackerContract, LootSack, VFX) to reach model hooks without touching `_model`. Returns the hook's result, or
## null when there is no model or no such hook.
func model_call(method: StringName, args: Array = []) -> Variant:
	if _model == null or not is_instance_valid(_model) or not _model.has_method(method):
		return null
	return _model.callv(method, args)


## True when this unit has a character model that answers `method`.
func model_has(method: StringName) -> bool:
	return _model != null and is_instance_valid(_model) and _model.has_method(method)


## The kingdom colour this unit's model wears (the one `set_team_color` got). Alpha 0 = none (Magpies, wardens).
func team_kingdom_color() -> Color:
	return _kingdom_color()


## Sends the kingdom colour to the model again (e.g. the team's kingdom became known after the spawn).
## Champion overrides it with the same behaviour.
func refresh_team_color() -> void:
	var kc := _kingdom_color()
	if kc.a > 0.0:
		model_call(&"set_team_color", [kc])


# ---------------------------------------------------------------- trade model hooks (task 10.C10)

## Gold a Magpie carries (market-trade.md 5.1: meta `&"loot"`, max 60 from snatches). 0 when none.
func get_loot() -> int:
	return int(get_meta(LOOT_META, 0))


## Sets the carried loot (meta `&"loot"`, never below 0) and shows / hides the model's loot sack
## (`set_carrying(loot > 0)`). ThiefBand / LootSack call it whenever the loot changes.
func set_loot(amount: int) -> void:
	var value := maxi(0, amount)
	set_meta(LOOT_META, value)
	model_call(&"set_carrying", [value > 0])


## Magpie Snatch channel pose (1.5 s, market-trade.md 5.3). No-op without the hook.
func play_snatch() -> void:
	model_call(&"play_snatch")


## Ends the Snatch pose early (the channel broke: >= 20 damage, the thief fled). Safe to call any time.
func cancel_snatch() -> void:
	model_call(&"cancel_snatch")


## True while the model plays the Snatch channel (false without a model).
func is_snatching() -> bool:
	return bool(model_call(&"is_snatching")) if model_has(&"is_snatching") else false


# TradeVfx.play(id, at, target) through its group (never a static type: art/vfx/trade_vfx.gd may be missing).
func _play_trade_vfx(id: StringName, target: Node3D) -> void:
	if target == null or not target.is_inside_tree():
		return
	var vfx := target.get_tree().get_first_node_in_group(&"trade_vfx")
	if vfx and vfx.has_method(&"play"):
		vfx.call(&"play", id, target.global_position, target)


## Kingdom colour for the model (fire / shadow from the UnitType). Alpha 0 = none (neutral). Types shared by
## every kingdom (caravans, trackers: faction &"") take the owning team's kingdom (_team_kingdom).
func _kingdom_color() -> Color:
	if unit_type:
		if KINGDOM_COLORS.has(unit_type.faction):
			return KINGDOM_COLORS[unit_type.faction]
		if unit_type.faction == &"" and team != Team.NEUTRAL:
			return KINGDOM_COLORS[_team_kingdom()]
	return Color(0, 0, 0, 0)


# The kingdom of this unit's team (for faction-less types: caravans, hired trackers): the team's Economy
# kingdom (set by its keep), else its wizard's kingdom, else the level's player_kingdom / enemy_kingdom, else
# fire for the player and shadow for the enemy (as Champion.owner_kingdom).
func _team_kingdom() -> StringName:
	var eco := Economy.for_team(team)
	if eco and KINGDOM_COLORS.has(eco.kingdom):
		return eco.kingdom
	if is_inside_tree():
		for group: StringName in [&"heroes", &"enemy_heroes"]:
			for w in get_tree().get_nodes_in_group(group):
				if w != self and w.get(&"team") != null and int(w.get(&"team")) == int(team):
					var k: Variant = w.get(&"kingdom")
					if k != null and KINGDOM_COLORS.has(StringName(str(k))):
						return StringName(str(k))
		var scene := get_tree().current_scene
		if scene and scene.has_method(&"seat_kingdom"):   # 2v2 levels name every seat's kingdom
			var seat_k: Variant = scene.call(&"seat_kingdom", int(team))
			if seat_k is StringName and KINGDOM_COLORS.has(seat_k):
				return seat_k
		if scene:
			var sk: Variant = scene.get(&"player_kingdom" if int(team) == Team.PLAYER else &"enemy_kingdom")
			if sk != null and KINGDOM_COLORS.has(StringName(str(sk))):
				return StringName(str(sk))
	return &"fire" if int(team) == Team.PLAYER else &"shadow"


# ---------------------------------------------------------------- helpers

func _set_nav_target(pos: Vector3) -> void:
	if _last_nav_target.distance_to(pos) > 0.5:
		_last_nav_target = pos
		_agent.target_position = pos


func _path_velocity() -> Vector3:
	var next := _agent.get_next_path_position()
	var dir := next - global_position
	dir.y = 0.0
	if dir.length() < 0.01:
		return Vector3.ZERO
	return dir.normalized() * move_speed


# How far from _anchor a unit chases an enemy it picked itself: aggro_range x 2 (workers too, so a
# worker only answers what stands next to it), FIGHT_BACK_LEASH for soldiers without aggro (Magpies,
# trackers answer attackers).
func _chase_leash() -> float:
	if aggro_range > 0.0 or is_worker():
		return aggro_range * 2.0
	return FIGHT_BACK_LEASH


func _flat_distance(pos: Vector3) -> float:
	return Vector2(global_position.x - pos.x, global_position.z - pos.z).length()


func _in_attack_range(target: Node3D) -> bool:
	return _flat_distance(target.global_position) <= effective_attack_range() + radius + radius_of(target)


## The reach radius of an attack target: target_radius() if it has one, else a building default.
static func radius_of(target: Node3D) -> float:
	if target == null or not is_instance_valid(target):
		return 0.0
	if target is Unit:   # perf pass 2026-10-09: typed call for the common case (same method)
		return (target as Unit).target_radius()
	if target.has_method(&"target_radius"):
		return float(target.call(&"target_radius"))
	return DEFAULT_TARGET_RADIUS


## Untyped on purpose: a freed node may be passed (typed parameters reject freed instances).
static func _target_alive(target: Variant) -> bool:
	if is_instance_valid(target) and target is Unit:   # perf pass 2026-10-09: typed call for the common case
		return (target as Unit).is_alive()
	return target != null and is_instance_valid(target) and (target as Object).has_method(&"is_alive") \
			and bool((target as Object).call(&"is_alive"))


## Auto-aggro: the nearest enemy unit within max_distance; if there is none, the nearest enemy
## building whose edge (centre minus target radius) is within max_distance.
func _find_auto_target(max_distance: float) -> Node3D:
	var unit := _find_nearest_enemy(max_distance)
	if unit:
		return unit
	return _find_nearest_enemy_building(max_distance)


func _find_nearest_enemy_building(max_distance: float) -> Node3D:
	var best: Node3D = null
	var best_dist := max_distance
	for node in get_tree().get_nodes_in_group(&"buildings"):
		var b := node as Node3D
		if b == null or not is_enemy_of(b) or not _target_alive(b) or not _in_leash(b):
			continue
		if b.is_in_group(&"noncombatant"):   # e3m2 villager tents / wagons: only an explicit attack order hits them
			continue
		var d := _flat_distance(b.global_position) - radius_of(b)
		if d < best_dist:
			best_dist = d
			best = b
	return best


func _find_nearest_enemy(max_distance: float) -> Unit:
	var grid := UnitGrid.current()
	if grid != null:
		return _find_nearest_enemy_grid(grid, max_distance)
	return _find_nearest_enemy_scan(max_distance)


## The old full scan (no UnitGrid in the level). test_unit_grid compares the grid query against it.
func _find_nearest_enemy_scan(max_distance: float) -> Unit:
	var best: Unit = null
	var best_score := INF
	# Hot path (Wave Strike perf pass 2026-10-06: ~300 us per scan at 200 units): cheap typed checks and the squared
	# distance first; the Variant / virtual checks (is_enemy_of, is_alive, leash) only for units in range. Same result.
	var me := global_position
	var max_d2 := max_distance * max_distance
	for node in get_tree().get_nodes_in_group(&"units"):
		var other := node as Unit
		if other == null or other.team == team or other._dead or other._hidden_auto_left > 0.0:
			continue
		var op := other.global_position
		var dx := op.x - me.x
		var dz := op.z - me.z
		var d2 := dx * dx + dz * dz
		if d2 >= max_d2 or not is_enemy_of(other) or not other.is_alive() or not _in_leash(other):
			continue
		var d := sqrt(d2)
		# caster-units.md 8.2: bot soldiers (prefer_casters) take an enemy caster in reach before any nearer unit.
		var score := d - CASTER_PREFERENCE if prefer_casters and other.has_node(^"CasterAbility") else d
		if score < best_score:
			best_score = score
			best = other
	return best


## P1 (wave-strike.md 14.2): the same filters and score as _find_nearest_enemy_scan, over the grid cells within
## max_distance (+ UnitGrid.SLACK) only. Ties go to the lower group index, exactly as the scan's first-wins order.
func _find_nearest_enemy_grid(grid: UnitGrid, max_distance: float) -> Unit:
	grid.prepare()
	var best: Unit = null
	var best_score := INF
	var best_i := 1 << 30
	var me := global_position
	var max_d2 := max_distance * max_distance
	var reach := max_distance + UnitGrid.SLACK
	var c0 := grid.col_of(me.x - reach)
	var c1 := grid.col_of(me.x + reach)
	var r0 := grid.row_of(me.z - reach)
	var r1 := grid.row_of(me.z + reach)
	var cols := grid.cols
	var units := grid.units
	var start := grid.cell_start
	var items := grid.items
	var px := grid.pos_x
	var pz := grid.pos_z
	var teams := grid.teams
	var reach2 := reach * reach
	var bonus := CASTER_PREFERENCE if prefer_casters else 0.0
	var cut2 := INF   # (best_score + bonus + SLACK)^2: a binned distance beyond it cannot beat the pick
	var own := grid.row_of(me.z) * cols + grid.col_of(me.x)
	for pass_i in 2:   # own cell first (the nearest units: an early pick prunes the rest), then the others
		for r in range(r0, r1 + 1):
			var row_base := r * cols
			for c in range(c0, c1 + 1):
				var cell := row_base + c
				if (cell == own) != (pass_i == 0):
					continue
				for k in range(start[cell], start[cell + 1]):
					var i := items[k]
					if teams[i] == team:
						continue
					var bx := px[i] - me.x
					var bz := pz[i] - me.z
					var b2 := bx * bx + bz * bz
					if b2 >= reach2 or b2 > cut2:   # binned this frame: cannot have moved SLACK m since
						continue
					var node: Variant = units[i]
					if not is_instance_valid(node):
						continue
					var other := node as Unit
					if other.team == team or other._dead or other._hidden_auto_left > 0.0:
						continue
					var op := other.global_position
					var dx := op.x - me.x
					var dz := op.z - me.z
					var d2 := dx * dx + dz * dz
					if d2 >= max_d2:
						continue
					var d := sqrt(d2)
					# Its best possible score cannot beat the current pick (ties: lower index wins): skip the costly checks.
					var low := d - bonus
					if low > best_score or (low == best_score and i > best_i):
						continue
					if not other.is_in_group(&"units") or not is_enemy_of(other) or not other.is_alive() or not _in_leash(other):
						continue
					var score := d - CASTER_PREFERENCE if prefer_casters and other.has_node(^"CasterAbility") else d
					if score < best_score or (score == best_score and i < best_i):
						best_score = score
						best = other
						best_i = i
						var lim := best_score + bonus + UnitGrid.SLACK
						cut2 = lim * lim
	return best


## Always true for PLAYER / ENEMY units and roaming neutrals. For leashed neutral units: the target
## (edge of a building) is within leash_radius() of home.
func _in_leash(target: Node3D) -> bool:
	if not has_neutral_leash():
		return true
	var d := Vector2(target.global_position.x - _anchor.x, target.global_position.z - _anchor.z).length()
	return d - radius_of(target) <= leash_radius()


func _face(direction: Vector3) -> void:
	direction.y = 0.0
	if direction.length() < 0.01:
		return
	var goal := atan2(direction.x, direction.z)
	var cur := _visual.rotation.y
	# Perf pass 2026-10-09: no write once facing the goal (a rotation write re-transforms the whole model subtree).
	if absf(angle_difference(cur, goal)) > FACE_EPSILON:
		_visual.rotation.y = lerp_angle(cur, goal, 0.25)


## Turns the unit's look (model) to `direction` at once (flat). Dashes and leaps that move the unit by
## position (CreatureAbilities) call it so the beast faces where it goes.
func face_direction(direction: Vector3) -> void:
	direction.y = 0.0
	if _visual == null or direction.length() < 0.01:
		return
	_visual.rotation.y = atan2(direction.x, direction.z)


func _lunge() -> void:
	var forward := Vector3(sin(_visual.rotation.y), 0.0, cos(_visual.rotation.y))
	var tween := create_tween()
	tween.tween_property(_visual, "position", forward * 0.35, 0.08)
	tween.tween_property(_visual, "position", Vector3.ZERO, 0.15)


func _update_hit_flash(delta: float) -> void:
	if _body_mat == null:
		return
	if _gold_flash > 0.0:   # level-up: gold for 0.2 s (levels.md)
		_gold_flash = maxf(0.0, _gold_flash - delta)
		_body_mat.emission = GOLD if _gold_flash > 0.0 else Color.WHITE
		_body_mat.emission_energy_multiplier = 2.0 if _gold_flash > 0.0 else _hit_flash * 2.0
		return
	if _hit_flash > 0.0:
		_hit_flash = max(0.0, _hit_flash - delta * 5.0)
		_body_mat.emission_energy_multiplier = _hit_flash * 2.0


func _update_hp_bar() -> void:
	if _hp_bar == null:
		return
	# A shield is a white segment after the HP (the bar rescales when HP + shield > max HP).
	var total := maxf(max_hp, hp + shield)
	_hp_mat.set_shader_parameter(&"fill", clamp(hp / total, 0.0, 1.0))
	_hp_mat.set_shader_parameter(&"shield_end", clamp((hp + shield) / total, 0.0, 1.0))
	_hp_bar.visible = not _dead and (selected or hp < max_hp or shield > 0.0 or _hp_bar_always_visible())


## Subclasses return true to show the world HP bar even at full HP and unselected (champions).
func _hp_bar_always_visible() -> bool:
	return false


## The look of the world HP bar frame: {"color": Color, "height": m, "frame": m, "inner": m} ("inner" =
## a black line inside the frame). Soldiers: a thin black frame. Champion overrides it (gold, task 9.C10).
func _hp_bar_frame_style() -> Dictionary:
	return {"color": Color.BLACK, "height": HP_BAR_HEIGHT, "frame": 0.0, "inner": 0.0}


## Colour of the world HP bar frame (black; gold on champions). Read only (UI / tests).
func hp_bar_frame_color() -> Color:
	return _hp_bar_frame_style().get("color", Color.BLACK)


# ---------------------------------------------------------------- building the placeholder look

func _build_collision() -> void:
	var shape := CapsuleShape3D.new()
	shape.radius = radius
	shape.height = max(body_height, radius * 2.0)
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position.y = body_height * 0.5
	add_child(col)


func _build_visual() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	if model_scene:
		_build_model()
		return

	_body_mat = StandardMaterial3D.new()
	_body_mat.albedo_color = body_color
	_body_mat.roughness = 0.7
	_body_mat.emission_enabled = true
	_body_mat.emission = Color.WHITE
	_body_mat.emission_energy_multiplier = 0.0

	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = radius
	capsule.height = max(body_height, radius * 2.0)
	body.mesh = capsule
	body.material_override = _body_mat
	body.position.y = body_height * 0.5
	_visual.add_child(body)

	# A pale visor so you can see which way the unit is facing.
	var visor := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(radius * 1.2, 0.14, 0.12)
	visor.mesh = box
	var visor_mat := StandardMaterial3D.new()
	visor_mat.albedo_color = eye_color
	if team == Team.NEUTRAL:   # camp guardians have glowing eyes
		visor_mat.emission_enabled = true
		visor_mat.emission = eye_color
		visor_mat.emission_energy_multiplier = 1.5
	visor.material_override = visor_mat
	visor.position = Vector3(0.0, body_height * 0.8, radius * 0.9)
	_visual.add_child(visor)


# Instances the character model under _visual and caches which hooks it has (art-units.md 6.1).
func _build_model() -> void:
	var m := model_scene.instantiate() as Node3D
	if m == null:
		return
	_model = m
	# The walk plays at rate 1 at this unit's base speed (haste simply speeds the legs up).
	if &"stride_speed" in m:
		m.set(&"stride_speed", maxf(0.5, get_base_stat(&"move_speed")))
	if &"offscreen_freeze" in m:   # a game unit's model may pause off-camera (perf pass 2026-10-09)
		m.set(&"offscreen_freeze", true)
	_visual.add_child(m)
	_model_has_moving = m.has_method(&"set_moving")
	_model_has_attack = m.has_method(&"play_attack")
	_model_has_hit = m.has_method(&"play_hit")
	_model_has_status = m.has_method(&"set_status")
	var windup: Variant = m.get(&"attack_windup")
	_model_windup = clampf(float(windup), 0.0, MAX_ATTACK_WINDUP) if windup != null else 0.0
	var kc := _kingdom_color()
	if kc.a > 0.0 and m.has_method(&"set_team_color"):
		m.call(&"set_team_color", kc)
	if m.has_signal(&"death_finished"):
		m.connect(&"death_finished", _on_model_death_finished)


func _build_selection_ring() -> void:
	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius + 0.2
	torus.outer_radius = radius + 0.32
	torus.rings = 32
	_ring.mesh = torus
	_ring.scale = Vector3(1.0, 0.15, 1.0)
	_ring.position.y = 0.05
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = team_color(team)
	_ring.material_override = mat
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.visible = false
	add_child(_ring)


func _build_hp_bar() -> void:
	if _hp_shader == null:
		_hp_shader = Shader.new()
		_hp_shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, depth_test_disabled, shadows_disabled;
uniform float fill = 1.0;
uniform float shield_end = 0.0;
uniform vec4 fill_color : source_color = vec4(0.2, 0.9, 0.25, 1.0);
uniform vec4 back_color : source_color = vec4(0.08, 0.08, 0.08, 0.85);
// Frame (UV fractions): soldiers a thin black one; champions a gold one with a black inner line (9.C10).
uniform vec4 frame_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec2 frame_size = vec2(0.02, 0.12);
uniform vec2 inner_size = vec2(0.0, 0.0);
void vertex() {
	// Always face the camera (billboard).
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
	bool border = UV.x < frame_size.x || UV.x > 1.0 - frame_size.x || UV.y < frame_size.y || UV.y > 1.0 - frame_size.y;
	vec2 ie = frame_size + inner_size;
	bool inner = UV.x < ie.x || UV.x > 1.0 - ie.x || UV.y < ie.y || UV.y > 1.0 - ie.y;
	vec4 c = border ? frame_color : (inner ? vec4(0.0, 0.0, 0.0, 1.0) : (UV.x < fill ? fill_color
			: (UV.x < shield_end ? vec4(1.0, 1.0, 1.0, 1.0) : back_color)));
	ALBEDO = c.rgb;
	ALPHA = c.a;
}
"""
	_hp_mat = ShaderMaterial.new()
	_hp_mat.shader = _hp_shader
	_hp_mat.set_shader_parameter("fill_color", team_hp_color(team))
	var style := _hp_bar_frame_style()
	var bar_size := Vector2(max(1.0, radius * 2.6), float(style.get("height", HP_BAR_HEIGHT)))
	var frame_m := float(style.get("frame", 0.0))
	if frame_m > 0.0:   # metres -> UV fractions (default: the old 0.02 / 0.12 black frame)
		var inner_m := float(style.get("inner", 0.0))
		_hp_mat.set_shader_parameter("frame_color", style.get("color", Color.BLACK))
		_hp_mat.set_shader_parameter("frame_size", Vector2(frame_m / bar_size.x, frame_m / bar_size.y))
		_hp_mat.set_shader_parameter("inner_size", Vector2(inner_m / bar_size.x, inner_m / bar_size.y))
	_hp_bar = MeshInstance3D.new()
	_hp_bar.name = "HPBar"
	var quad := QuadMesh.new()
	quad.size = bar_size
	_hp_bar.mesh = quad
	_hp_bar.material_override = _hp_mat
	_hp_bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_hp_bar.position.y = body_height + 0.5
	add_child(_hp_bar)
	_update_hp_bar()


# ---------------------------------------------------------------- save / load (docs/design/save-load.md)

## Modifier sources a save keeps (the others are re-derived: level, veterancy, items, Forge, upgrades, wares, path...,
## or timed: statuses, auras, abilities).
## `rank3` (Stables rank 3) and `bowman:` (bowman upgrades) are kept too (R3-3): their researches come back through the
## saved_state rows of Stables16 / BowmanUpgrades, and the unit's HP is restored on top of the right max HP.
const SAVE_MODIFIER_PREFIXES: Array[String] = ["mission:", "save:", "rank3", "bowman:"]


## The unit as a save row (SaveWorld): `ids` maps saved nodes -> save id (targets, sites are saved as ids).
func save_snapshot(ids: Dictionary) -> Dictionary:
	var d := {
		"type": String(unit_type.id) if unit_type else "",
		"script": (get_script() as Script).resource_path if get_script() else "",
		"name": String(name),
		"team": int(team),
		"pos": global_position,
		"yaw": _visual.rotation.y if _visual else 0.0,
		"hp": hp,
		"alive": is_alive(),
		"level": level,
		"xp": xp,
		"anchor": _anchor,
		"aggro": aggro_range,
	}
	if _lifetime_total > 0.0:   # summons (R1-4): the time left survives a load
		d["lifetime_total"] = _lifetime_total
		d["lifetime_left"] = _lifetime_left
	var caster := get_node_or_null(^"CasterAbility")
	if caster and &"mana" in caster:
		d["caster_mana"] = float(caster.get(&"mana"))
	var march := get_node_or_null(^"LaneMarch")   # Wave Strike lane units
	if march:
		d["lane_index"] = int(march.get(&"index"))
		d["lane_lateral"] = float(march.get(&"lateral"))
	var mods := {}
	for src: StringName in _mods:
		for p in SAVE_MODIFIER_PREFIXES:
			if String(src).begins_with(p):
				mods[String(src)] = (_mods[src] as Dictionary).duplicate()
	d["mods"] = mods
	d["metas"] = SaveCodec.encode_metas(self, ids)
	d["groups"] = SaveCodec.custom_groups(self)
	# the order
	var order := "idle"
	if _hold:
		order = "hold"
	elif attack_target != null and not _auto_target and _target_alive(attack_target) and ids.has(attack_target):
		order = "attack"
		d["target_ref"] = ids[attack_target]
	elif _attack_move:
		order = "attack_move"
		d["target"] = _attack_move_target
	elif _has_move_order:
		order = "move"
		d["target"] = _last_nav_target if _last_nav_target != Vector3.INF else global_position
	if &"build_site" in self:
		var site: Variant = get(&"build_site")
		if site is Node and is_instance_valid(site) and ids.has(site):
			order = "build"
			d["target_ref"] = ids[site]
	if order == "idle" and &"gather_node" in self:
		var node: Variant = get(&"gather_node")
		if node is CrystalNode and is_instance_valid(node):
			order = "gather"
			d["node"] = String((node as CrystalNode).node_id)
	if &"carried" in self:
		d["carried"] = int(get(&"carried"))
	d["order"] = order
	return d


## Phase 1 of a load: identity, place, veterancy (the modifiers it adds), metas and groups. The unit is in the tree.
func load_snapshot_base(d: Dictionary, nodes: Dictionary) -> void:
	team = int(d.get("team", team)) as Team
	global_position = d.get("pos", global_position)
	_anchor = d.get("anchor", global_position)
	if _visual:
		_visual.rotation.y = float(d.get("yaw", _visual.rotation.y))
	var lv := int(d.get("level", level))
	if not is_in_group(&"heroes") and can_gain_veterancy() and lv > level:
		for l in range(level + 1, lv + 1):
			_set_veterancy_level(l)
	xp = int(d.get("xp", xp))
	SaveCodec.decode_metas(self, d.get("metas", {}), nodes)
	var groups: Array = d.get("groups", [])
	for g: Variant in groups:
		if not is_in_group(StringName(str(g))):
			add_to_group(StringName(str(g)))
	if is_alive() and not groups.has("units") and is_in_group(&"units"):
		remove_from_group(&"units")   # asleep for its mission (MissionBase.set_dormant / hold_world)
	aggro_range = float(d.get("aggro", aggro_range))
	if d.has("lifetime_total"):
		_lifetime_total = maxf(0.0, float(d["lifetime_total"]))
		_lifetime_left = clampf(float(d.get("lifetime_left", _lifetime_total)), 0.01, maxf(0.01, _lifetime_total))


## Phase 2 of a load (after the frame's upgrade / ware flushes): saved modifiers, HP, mana, carried crystals, order.
func load_snapshot_late(d: Dictionary, nodes: Dictionary, crystal_nodes: Dictionary) -> void:
	var mods: Dictionary = d.get("mods", {})
	for src: Variant in mods:
		add_modifier(StringName(str(src)), mods[src])
	if is_alive():
		hp = clampf(float(d.get("hp", hp)), 1.0, max_hp)
		_update_hp_bar()
	var caster := get_node_or_null(^"CasterAbility")
	if caster and d.has("caster_mana") and &"mana" in caster:
		caster.set(&"mana", float(d["caster_mana"]))
	if not is_alive() or not is_commandable_by_save():
		return
	var ref: Variant = nodes.get(d.get("target_ref", -1))
	match String(d.get("order", "idle")):
		"hold":
			command_hold()
		"attack":
			if ref != null and is_instance_valid(ref):
				command_attack(ref)
		"attack_move":
			command_attack_move(d.get("target", global_position))
		"move":
			command_move(d.get("target", global_position))
		"build":
			if ref != null and is_instance_valid(ref) and has_method(&"command_build"):
				call(&"command_build", ref)
		"gather":
			var node: Variant = crystal_nodes.get(StringName(str(d.get("node", ""))))
			if node != null and is_instance_valid(node) and has_method(&"command_gather"):
				call(&"command_gather", node)
		_:
			command_stop()   # idle: drop whatever the rebuilt start gave it (start workers gather)
	_anchor = d.get("anchor", _anchor)
	if &"carried" in self and d.has("carried"):
		set(&"carried", int(d["carried"]))


## Orders are restored on every unit the player or a bot could have ordered (lane units / champions run themselves).
func is_commandable_by_save() -> bool:
	return get_node_or_null(^"LaneMarch") == null and not is_in_group(&"champions")
