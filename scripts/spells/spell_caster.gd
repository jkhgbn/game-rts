class_name SpellCaster
extends Node
## A wizard's spells (CLAUDE.md "Spells" contract, docs/design/spells.md + levels.md).
## A child node named "SpellCaster" of each wizard: the wizard calls setup(self) in _ready, then
## Wizard.command_cast(id, target) delegates to cast(). Learning lives in Wizard and calls set_rank().
##
## cast(id, target) -> String: "" = accepted, else, in this order: "Dead", "Unknown spell",
## "Not learned", "On cooldown", "Not enough mana", "Invalid target".
## Targets: point / area = a Vector3 (a Node3D counts as its position), unit = an enemy Unit or
## building, self = anything (pass null). Out of range is not a refusal: the wizard walks (her own
## command_move) and casts when in range; mana and cooldown are paid at that moment. Any new order
## cancels the walk: the wizard should call cancel_pending() from its command_* functions (this node
## also notices direct control, an attack order, hold and attack-move by itself). A unit target that
## dies on the way cancels the cast at no cost. Ember Step never walks: its point is clamped to range.
## Not done yet: the fog-of-war rule for "Invalid target" (no fog system exists; wave 5).
##
## Malrik's AI: suggest_cast() returns the spells.md rule that applies now (see its comment); the
## bot / ShadowWizard calls it every 0.5 s and then cast(). Placeholder visuals only; effects hook
## on spell_cast / spell_effect / healed (tech-artist, 3.U2).
## Torvald (kingdom-ice.md 4, 7.G3): Rime Bolt, Flash Freeze, Rime Aegis; suggest_cast() follows his
## rules (4.3) when his spell ids are set. `chill` / `frozen` go through the unit's apply_status (a
## unit without those statuses simply isn't chilled / frozen). A frozen wizard (can_act() false)
## refuses with "Frozen" (right after "Dead") and a walk-then-cast waits until he thaws.
## Ysolde (kingdom-nature.md 3, 8.G2): Thornburst (damage + `rooted`), Wild Bloom (heal over time,
## SpellHot), Call the Thicket (Saplings with a lifetime, SummonSprout); suggest_cast() follows her
## rules (3.3) when her spell ids are set. Spell heals x heal_multiplier() (spell power, then the
## item passive Blossom through ItemPassives.heal_multiplier; Rime Aegis shields get Blossom only).

signal spell_cast(id: StringName)
signal cooldown_started(id: StringName, seconds: float)
## Where a spell's effect happens: fireball = impact point, ember_step = origin (the scorch) then
## `&"ember_step_arrive"` at the destination, kindle / umbral_shroud = the wizard, shadow_lance = the
## target when cast, soul_siphon = the circle centre. Ice: rime_bolt = the target when cast, then
## `&"rime_bolt_hit"` where it lands; flash_freeze = the circle centre; rime_aegis = Torvald, then
## `&"rime_aegis_shield"` once per shielded unit (its position). Nature: thornburst = the circle
## centre; wild_bloom = the circle centre, then `&"wild_bloom_heal"` on each healed unit every tick
## (its position); call_the_thicket = the point, then `&"call_the_thicket_sprout"` once per Sapling.
signal spell_effect(id: StringName, position: Vector3)
## Call the Thicket created these units (already in the tree, grow time running).
signal summoned(id: StringName, units: Array)
## The wizard is walking into range to cast `id`.
signal cast_pending(id: StringName, target: Variant)
signal cast_cancelled(id: StringName)
## Life drain healed the wizard (Shadow Lance hit, Soul Siphon tick).
signal healed(amount: float)

const VESSA_SPELLS: Array[StringName] = [&"fireball", &"ember_step", &"kindle"]
const MALRIK_SPELLS: Array[StringName] = [&"shadow_lance", &"soul_siphon", &"umbral_shroud"]
const TORVALD_SPELLS: Array[StringName] = [&"rime_bolt", &"flash_freeze", &"rime_aegis"]
const YSOLDE_SPELLS: Array[StringName] = [&"thornburst", &"wild_bloom", &"call_the_thicket"]

const REASON_DEAD := "Dead"
const REASON_FROZEN := "Frozen"
const REASON_UNKNOWN := "Unknown spell"
const REASON_NOT_LEARNED := "Not learned"
const REASON_COOLDOWN := "On cooldown"
const REASON_MANA := "Not enough mana"
const REASON_TARGET := "Invalid target"

const FIRE_COLOR := Color(1.0, 0.45, 0.1)
const SCORCH_COLOR := Color(0.6, 0.18, 0.05)
const SHADOW_COLOR := Color(0.7, 0.3, 1.0)
const SIPHON_COLOR := Color(0.25, 0.08, 0.4)
const LANCE_SPEED := 30.0
const LANCE_SIZE := 0.14
const RIME_COLOR := Color(0.75, 0.92, 1.0)
const RIME_BOLT_SPEED := 26.0
const RIME_BOLT_SIZE := 0.16
const REPATH_DISTANCE := 1.0   # a walked-to unit target that moved this far gets a new move order
const MAX_CDR := 40.0          # items.md cap on cooldown_reduction (percent)

## Malrik's AI rules (spells.md "AI casting rules").
const AI_SHROUD_HP_RATIO := 0.35
const AI_NEARBY := 12.0
const AI_CLUSTER_SIZE := 3
const AI_LANCE_LOW_HP := 50.0
const AI_LANCE_LOW_SELF := 0.6
## Torvald's AI rules (kingdom-ice.md 4.3).
const AI_AEGIS_HP_RATIO := 0.5
const AI_AEGIS_ALLY_RANGE := 8.0
const AI_AEGIS_ALLIES := 4
const AI_AEGIS_ENEMY_RANGE := 10.0
const AI_AEGIS_ENEMIES := 3
const AI_FREEZE_CLUSTER := 3
const AI_RETREAT_HP_RATIO := 0.35
## Ysolde's AI rules (kingdom-nature.md 3.3).
const AI_BLOOM_SELF_HP_RATIO := 0.45
const AI_BLOOM_HURT_RATIO := 0.6
const AI_BLOOM_GROUP_RANGE := 5.0
const AI_BLOOM_HURT_COUNT := 3
const AI_THICKET_RANGE := 12.0
const AI_THICKET_ENEMIES := 4
const AI_THICKET_OFFSET := 3.0
const AI_THORN_CLUSTER := 2
const THICKET_SEEK_RANGE := 10.0   # Saplings attack-move to the point's nearest enemy within this
## Built in code when data/units/sapling.tres is missing (kingdom-nature.md 2 numbers).
static var _fallback_sapling: UnitType = null

var wizard: Node3D

var _ids: Array[StringName] = []
var _types: Dictionary = {}       # id -> SpellType
var _ranks: Dictionary = {}       # id -> int (0 = not learned)
var _cooldown_left: Dictionary = {}
var _cooldown_total: Dictionary = {}
var _pending_id: StringName = &""
var _pending_target: Variant = null
var _pending_walk_to := Vector3.INF
var _pending_nav_target := Vector3.INF
var _walking := false   # inside our own command_move call: ignore cancel_pending()
var _after_freeze: Array = []   # [unit, status id, seconds]: applied once the unit is no longer frozen


## `ids`: the three spells in slot order F / Q / E; empty = Malrik's for a ShadowWizard, else the
## wizard's `default_spell_ids` (Torvald sets TORVALD_SPELLS there), else Vessa's.
## Spell 1 starts at rank 1 (known at level 1), the others at 0.
func setup(p_wizard: Node3D, ids: Array[StringName] = []) -> void:
	wizard = p_wizard
	if ids.is_empty():
		var defaults: Variant = p_wizard.get(&"default_spell_ids")
		if p_wizard is ShadowWizard:
			ids = MALRIK_SPELLS
		elif defaults is Array and not (defaults as Array).is_empty():
			ids.assign(defaults)
		else:
			ids = VESSA_SPELLS
	_ids = ids.duplicate()
	_types.clear()
	for i in _ids.size():
		var id := _ids[i]
		var t := SpellType.find(id)
		if t == null:
			push_error("SpellCaster: missing data/spells/%s.tres" % id)
			continue
		_types[id] = t
		if not _ranks.has(id):
			_ranks[id] = 1 if i == 0 else 0
		_cooldown_left[id] = 0.0
		_cooldown_total[id] = 0.0


func spell_ids() -> Array[StringName]:
	return _ids.duplicate()


func spell_type(id: StringName) -> SpellType:
	return _types.get(id) as SpellType


func rank_of(id: StringName) -> int:
	return int(_ranks.get(id, 0))


## Called by Wizard.learn_spell (and tests). Clamped to 0..max_rank.
func set_rank(id: StringName, rank: int) -> void:
	var t := spell_type(id)
	if t == null:
		return
	_ranks[id] = clampi(rank, 0, t.max_rank)


func mana_cost(id: StringName) -> float:
	var t := spell_type(id)
	return t.mana_cost if t else 0.0


func cooldown_left(id: StringName) -> float:
	return float(_cooldown_left.get(id, 0.0))


## The full length of the cooldown now running (0 when none ran yet); before any cast, the rank's
## cooldown after cooldown reduction.
func cooldown_total(id: StringName) -> float:
	var running := float(_cooldown_total.get(id, 0.0))
	return running if running > 0.0 else _cooldown_for(id)


## The rank's numbers, for the UI and the bot (rank 1 when not learned).
func range_of(id: StringName) -> float:
	var t := spell_type(id)
	return t.range_at(maxi(1, rank_of(id))) if t else 0.0


func radius_of(id: StringName) -> float:
	var t := spell_type(id)
	return t.radius_at(maxi(1, rank_of(id))) if t else 0.0


## The reason cast() would give right now, ignoring the target ("" = castable).
func can_cast(id: StringName) -> String:
	if not _alive(wizard):
		return REASON_DEAD
	if not _can_act(wizard):
		return REASON_FROZEN
	var t := spell_type(id)
	if t == null or not _ids.has(id):
		return REASON_UNKNOWN
	if rank_of(id) <= 0:
		return REASON_NOT_LEARNED
	if cooldown_left(id) > 0.0:
		return REASON_COOLDOWN
	if _mana() < t.mana_cost:
		return REASON_MANA
	return ""


func cast(id: StringName, target: Variant) -> String:
	var reason := can_cast(id)
	if reason != "":
		return reason
	var t := spell_type(id)
	if not _target_ok(t, target):
		return REASON_TARGET
	cancel_pending()
	if t.target_type == SpellType.TargetType.SELF or id == &"ember_step" or _in_range(id, target):
		_execute(id, target)
		return ""
	# Walk into range first (today's Fireball behaviour).
	_pending_id = id
	_pending_target = target
	_walk_toward(_target_position(target))
	cast_pending.emit(id, target)
	return ""


func has_pending() -> bool:
	return _pending_id != &""


func pending_spell() -> StringName:
	return _pending_id


## Drops a walk-then-cast order (no cost). The wizard calls it from its command_* functions.
func cancel_pending() -> void:
	if _pending_id == &"" or _walking:
		return
	var id := _pending_id
	_pending_id = &""
	_pending_target = null
	_pending_walk_to = Vector3.INF
	_pending_nav_target = Vector3.INF
	cast_cancelled.emit(id)


## Respawn: every cooldown ready, no pending cast. Ranks are kept.
func reset() -> void:
	cancel_pending()
	for id in _cooldown_left.keys():
		_cooldown_left[id] = 0.0
		_cooldown_total[id] = 0.0


## Same as reset() (the name Wizard._reset_spells calls).
func reset_cooldowns() -> void:
	reset()


func _physics_process(delta: float) -> void:
	for id: Variant in _cooldown_left:   # existing keys only: no keys() copy per frame
		var left := float(_cooldown_left[id])
		if left > 0.0:
			_cooldown_left[id] = maxf(0.0, left - delta)
	if not _after_freeze.is_empty():
		_update_after_freeze()
	if _pending_id != &"":
		_update_pending()


# Flash Freeze's follow-up status (chill) lands the moment `frozen` is gone (a wizard thaws after
# half the time; a unit immune to frozen is chilled at once).
func _update_after_freeze() -> void:
	for i in range(_after_freeze.size() - 1, -1, -1):
		var entry: Array = _after_freeze[i]
		var u: Variant = entry[0]
		if not _alive(u):
			_after_freeze.remove_at(i)
			continue
		if (u as Object).has_method(&"has_status") and bool((u as Object).call(&"has_status", &"frozen")):
			continue
		_after_freeze.remove_at(i)
		apply_status_to(u as Node3D, entry[1], entry[2])


func _update_pending() -> void:
	var id := _pending_id
	if not _alive(wizard) or not _target_ok(spell_type(id), _pending_target) or _order_overridden():
		cancel_pending()
		return
	if not _can_act(wizard):
		return   # frozen: the order is kept and resumes
	if _in_range(id, _pending_target):
		var target: Variant = _pending_target
		_pending_id = &""
		_pending_target = null
		if wizard.has_method(&"command_stop"):
			wizard.call(&"command_stop")
		if can_cast(id) == "":
			_execute(id, target)
		else:
			cast_cancelled.emit(id)
		return
	var pos := _target_position(_pending_target)
	if _flat(pos - _pending_walk_to).length() > REPATH_DISTANCE:
		_walk_toward(pos)


## Another order replaced our walk: direct control, an attack order, hold, attack-move, or a move
## elsewhere (the wizard's NavigationAgent3D target changed).
func _order_overridden() -> bool:
	if wizard.has_method(&"get_move_input") and wizard.call(&"get_move_input") != Vector3.ZERO:
		return true
	if wizard.get(&"attack_target") != null:
		return true
	if wizard.has_method(&"is_holding") and bool(wizard.call(&"is_holding")):
		return true
	if wizard.has_method(&"is_attack_moving") and bool(wizard.call(&"is_attack_moving")):
		return true
	var agent := _nav_agent()
	if agent and _pending_nav_target != Vector3.INF \
			and agent.target_position.distance_to(_pending_nav_target) > 0.6:
		return true
	return false


func _walk_toward(pos: Vector3) -> void:
	_pending_walk_to = pos
	_walking = true   # the wizard's command_move may call cancel_pending(): ignored
	if wizard.has_method(&"command_move"):
		wizard.call(&"command_move", pos)
	_walking = false
	var agent := _nav_agent()
	_pending_nav_target = agent.target_position if agent else Vector3.INF


func _nav_agent() -> NavigationAgent3D:
	for child in wizard.get_children():
		if child is NavigationAgent3D:
			return child
	return null


# ---------------------------------------------------------------- the six spells

func _execute(id: StringName, target: Variant) -> void:
	var t := spell_type(id)
	var rank := maxi(1, rank_of(id))
	wizard.set(&"mana", _mana() - t.mana_cost)
	var cd := _cooldown_for(id)
	_cooldown_left[id] = cd
	_cooldown_total[id] = cd
	var pos := _target_position(target)
	match id:
		&"fireball":
			_cast_fireball(t, rank, pos)
		&"ember_step":
			_cast_ember_step(t, rank, pos)
		&"kindle":
			_cast_kindle(t, rank)
		&"shadow_lance":
			_cast_shadow_lance(t, rank, target as Node3D)
		&"soul_siphon":
			_cast_soul_siphon(t, rank, pos)
		&"umbral_shroud":
			SpellStatus.apply(wizard, t.status_id, t.duration_at(rank))
			spell_effect.emit(id, wizard.global_position)
		&"rime_bolt":
			_cast_rime_bolt(t, rank, target as Node3D)
		&"flash_freeze":
			_cast_flash_freeze(t, rank, pos)
		&"rime_aegis":
			_cast_rime_aegis(t, rank)
		&"thornburst":
			_cast_thornburst(t, rank, pos)
		&"wild_bloom":
			_cast_wild_bloom(t, rank, pos)
		&"call_the_thicket":
			_cast_call_the_thicket(t, rank, pos)
	spell_cast.emit(id)
	if cd > 0.0:
		cooldown_started.emit(id, cd)


func _cast_fireball(t: SpellType, rank: int, pos: Vector3) -> void:
	var ball := Projectile.new()
	ball.is_spell = true   # Blitz spell factor on each hit, like deal_damage
	_world().add_child(ball)
	var color: Variant = wizard.get(&"orb_color")
	ball.launch_at_point(wizard, wizard.global_position + Vector3.UP * _height(), pos,
			spell_damage(t, rank), t.radius_at(rank), color if color is Color else FIRE_COLOR)
	ball.hit_area.connect(_report_hit.bind(t.id))
	spell_effect.emit(t.id, pos)


func _cast_ember_step(t: SpellType, rank: int, pos: Vector3) -> void:
	var origin := wizard.global_position
	var offset := _flat(pos - origin)
	var reach := t.range_at(rank)
	if offset.length() > reach:
		offset = offset.normalized() * reach
	var dest := origin + offset
	var map := wizard.get_world_3d().navigation_map
	if NavigationServer3D.map_get_iteration_id(map) > 0:
		var on_mesh := NavigationServer3D.map_get_closest_point(map, dest)
		if _flat(on_mesh - origin).length() <= reach + 0.5:
			dest = on_mesh
	wizard.global_position = dest
	if wizard.has_method(&"command_stop"):
		wizard.call(&"command_stop")   # her order is cleared; home = the new spot
	var zone := _make_zone(t, rank, SCORCH_COLOR, 0.0)
	zone.global_position = origin
	spell_effect.emit(t.id, origin)
	spell_effect.emit(&"ember_step_arrive", dest)


func _cast_kindle(t: SpellType, rank: int) -> void:
	var center := wizard.global_position
	var r := t.radius_at(rank)
	var team: Variant = wizard.get(&"team")
	for node in wizard.get_tree().get_nodes_in_group(&"units"):
		var u := node as Node3D
		if u == null or not _friend_team(u, team) or not _alive(u):
			continue
		if u.has_method(&"is_worker") and bool(u.call(&"is_worker")):
			continue
		if _flat(u.global_position - center).length() <= r:
			SpellStatus.apply(u, t.status_id, t.duration_at(rank))
	spell_effect.emit(t.id, center)


func _cast_shadow_lance(t: SpellType, rank: int, target: Node3D) -> void:
	var bolt := Projectile.new()
	bolt.is_spell = true   # Blitz spell factor on each hit, like deal_damage
	_world().add_child(bolt)
	bolt.launch_at_target(wizard, wizard.global_position + Vector3.UP * _height(), target,
			spell_damage(t, rank), SHADOW_COLOR, LANCE_SIZE, LANCE_SPEED, 0.0)
	var ratio := t.heal_ratio
	bolt.hit_unit.connect(func(hit: Node3D, dealt: float) -> void:
		if not is_instance_valid(wizard) or not _alive(wizard) or dealt <= 0.0:
			return
		wizard.call(&"heal", dealt * ratio)
		healed.emit(dealt * ratio)
		_report_hit(hit, dealt, t.id))
	spell_effect.emit(t.id, target.global_position)


func _cast_soul_siphon(t: SpellType, rank: int, pos: Vector3) -> void:
	var zone := _make_zone(t, rank, SIPHON_COLOR, t.heal_ratio)
	zone.global_position = pos
	zone.ticked.connect(func(dealt: float) -> void:
		if dealt > 0.0 and is_instance_valid(wizard) and _alive(wizard):
			healed.emit(dealt * t.heal_ratio))
	spell_effect.emit(t.id, pos)


## Rime Bolt: an ice shard that follows the target; on hit, damage + `chill` (rank duration).
func _cast_rime_bolt(t: SpellType, rank: int, target: Node3D) -> void:
	var bolt := Projectile.new()
	bolt.is_spell = true   # Blitz spell factor on each hit, like deal_damage
	_world().add_child(bolt)
	bolt.launch_at_target(wizard, wizard.global_position + Vector3.UP * _height(), target,
			spell_damage(t, rank), RIME_COLOR, RIME_BOLT_SIZE, RIME_BOLT_SPEED, 0.0)
	var chill_id := t.status_id
	var chill_time := t.duration_at(rank)
	bolt.hit_unit.connect(func(hit: Node3D, dealt: float) -> void:
		if not is_instance_valid(hit):
			return
		apply_status_to(hit, chill_id, chill_time)
		spell_effect.emit(&"rime_bolt_hit", hit.global_position)
		_report_hit(hit, dealt, t.id))
	spell_effect.emit(t.id, target.global_position)


## Flash Freeze: every enemy unit whose edge is inside the circle takes the damage, is `frozen` for
## the rank's duration (the unit halves it on wizards), then gets `chill` 3 s once it thaws.
func _cast_flash_freeze(t: SpellType, rank: int, pos: Vector3) -> void:
	var r := t.radius_at(rank)
	var dmg := spell_damage(t, rank)
	var hits: Array[Node3D] = []
	for node in wizard.get_tree().get_nodes_in_group(&"units"):
		var u := node as Node3D
		if u == null or u == wizard or not _alive(u) or not _is_enemy(u):
			continue
		if _flat(u.global_position - pos).length() <= r + edge_radius(u):
			hits.append(u)
	for u in hits:
		var dealt := deal_damage(u, dmg, wizard)
		_report_hit(u, dealt, t.id)
		if not _alive(u):
			continue
		apply_status_to(u, t.status_id, t.duration_at(rank))
		if t.secondary_status_id != &"" and t.secondary_duration > 0.0:
			_after_freeze.append([u, t.secondary_status_id, t.secondary_duration])
	spell_effect.emit(t.id, pos)


## Rime Aegis: Torvald and every friendly non-worker unit within the radius get the rank's shield.
func _cast_rime_aegis(t: SpellType, rank: int) -> void:
	var center := wizard.global_position
	var r := t.radius_at(rank)
	var amount := t.shield_at(rank) * blossom_multiplier()
	var seconds := t.duration_at(rank)
	var team: Variant = wizard.get(&"team")
	spell_effect.emit(t.id, center)
	for node in wizard.get_tree().get_nodes_in_group(&"units"):
		var u := node as Node3D
		if u == null or not _friend_team(u, team) or not _alive(u) or not u.has_method(&"add_shield"):
			continue
		if u != wizard and (_is_worker(u) or _flat(u.global_position - center).length() > r):
			continue
		u.call(&"add_shield", amount, seconds)
		spell_effect.emit(&"rime_aegis_shield", u.global_position)


## Thornburst: every enemy unit and building whose edge is inside the circle takes the damage; the
## enemy units still alive are `rooted` for the rank's duration (the unit halves it on wizards).
func _cast_thornburst(t: SpellType, rank: int, pos: Vector3) -> void:
	var r := t.radius_at(rank)
	var dmg := spell_damage(t, rank)
	var hits: Array[Node3D] = []
	var is_unit: Dictionary = {}
	for group: StringName in [&"units", &"buildings"]:
		for node in wizard.get_tree().get_nodes_in_group(group):
			var u := node as Node3D
			if u == null or u == wizard or is_unit.has(u) or not _alive(u) or not _is_enemy(u) \
					or not u.has_method(&"take_damage"):
				continue
			if _flat(u.global_position - pos).length() <= r + edge_radius(u):
				hits.append(u)
				is_unit[u] = group == &"units"
	for u in hits:
		var dealt := deal_damage(u, dmg, wizard)
		_report_hit(u, dealt, t.id)
		if bool(is_unit[u]) and _alive(u):
			apply_status_to(u, t.status_id, t.duration_at(rank))
	spell_effect.emit(t.id, pos)


## Wild Bloom: every friendly unit (soldiers, workers, wizards; not summons, not buildings) whose edge
## is inside the circle at cast heals the rank's total over its duration, one tick every 0.5 s.
func _cast_wild_bloom(t: SpellType, rank: int, pos: Vector3) -> void:
	var r := t.radius_at(rank)
	var team: Variant = wizard.get(&"team")
	var targets: Array[Node3D] = []
	for node in wizard.get_tree().get_nodes_in_group(&"units"):
		var u := node as Node3D
		if u == null or not _friend_team(u, team) or not _alive(u) or is_summon(u):
			continue
		if _flat(u.global_position - pos).length() <= r + edge_radius(u):
			targets.append(u)
	spell_effect.emit(t.id, pos)
	if targets.is_empty():
		return
	var hot := SpellHot.new()
	hot.name = "WildBloom"
	hot.spell_id = t.id
	hot.setup(targets, t.heal_at(rank) * heal_multiplier(), t.duration_at(rank), t.tick_interval)
	hot.healed_target.connect(_on_bloom_healed)
	_world().add_child(hot)


func _on_bloom_healed(target: Node3D, _amount: float) -> void:
	if is_instance_valid(target):
		spell_effect.emit(&"wild_bloom_heal", target.global_position)


## Call the Thicket: the rank's Saplings sprout on a ring around the point (caster's team, lifetime =
## the rank's duration, pop 0, kill_xp 0 so their death gives no XP and no essence). They hold for the
## 0.5 s grow time, then attack-move to the point's nearest enemy within 10 m (SummonSprout).
func _cast_call_the_thicket(t: SpellType, rank: int, pos: Vector3) -> void:
	var type := summon_type(t.summon_unit_id)
	var count := t.summon_count_at(rank)
	var ring := t.radius_at(rank)
	var life := t.duration_at(rank)
	var world := _world()
	var map := wizard.get_world_3d().navigation_map
	var has_nav := NavigationServer3D.map_get_iteration_id(map) > 0
	var units: Array = []
	spell_effect.emit(t.id, pos)
	for i in count:
		var angle := TAU * float(i) / float(maxi(1, count))
		var spot := pos + Vector3(cos(angle) * ring, 0.0, sin(angle) * ring)
		if has_nav:
			var on_mesh := NavigationServer3D.map_get_closest_point(map, spot)
			if _flat(on_mesh - spot).length() <= 2.0:
				spot = on_mesh
		var u := type.create_unit()
		u.team = wizard.get(&"team")
		u.set_lifetime(life)
		world.add_child(u)
		u.global_position = spot
		u.command_hold()
		var sprout := SummonSprout.new()
		sprout.name = "Sprout"
		sprout.point = pos
		sprout.seek_range = THICKET_SEEK_RANGE
		u.add_child(sprout)
		units.append(u)
		spell_effect.emit(&"call_the_thicket_sprout", spot)
	summoned.emit(t.id, units)


## The UnitType a summon spell spawns: data/units/<id>.tres (or nature_<id>.tres); if neither exists,
## a Sapling built from kingdom-nature.md section 2 (pop 0, kill_xp 0, lifetime 25).
static func summon_type(id: StringName = &"sapling") -> UnitType:
	var key := String(id) if id != &"" else "sapling"
	var found := UnitType.find(key)
	if found == null:
		found = UnitType.find("nature_" + key)
	if found:
		return found
	if _fallback_sapling == null:
		var s := UnitType.new()
		s.id = &"sapling"
		s.display_name = "Sapling"
		s.faction = &"nature"
		s.cost = 0
		s.pop = 0
		s.kill_xp = 0
		s.max_hp = 90.0
		s.attack_damage = 9.0
		s.attack_range = 1.5
		s.attack_cooldown = 1.0
		s.move_speed = 4.8
		s.aggro_range = 10.0
		s.radius = 0.4
		s.body_height = 1.2
		s.body_color = Color(0.45, 0.75, 0.30)
		s.idle_regen_pct = 1.0   # balance-2
		s.lifetime = 25.0
		_fallback_sapling = s
	return _fallback_sapling


## True for a summoned unit (a lifetime, e.g. a Sapling): Wild Bloom skips them.
static func is_summon(u: Node3D) -> bool:
	if u.has_method(&"lifetime_total") and float(u.call(&"lifetime_total")) > 0.0:
		return true
	var ut: Variant = u.get(&"unit_type")
	return ut is UnitType and (ut as UnitType).lifetime > 0.0


## Puts status `id` (`chill`, `frozen`...) on `target` through its apply_status. Returns true when the
## target now has it (false: no such method, unknown status on this unit, building, immune, dead).
static func apply_status_to(target: Node3D, id: StringName, seconds: float) -> bool:
	if id == &"" or seconds <= 0.0 or not _alive(target) or not target.has_method(&"apply_status"):
		return false
	target.call(&"apply_status", id, seconds)
	if target.has_method(&"has_status"):
		return bool(target.call(&"has_status", id))
	return true


func _make_zone(t: SpellType, rank: int, color: Color, heal_ratio: float) -> SpellZone:
	var zone := SpellZone.new()
	zone.spell_id = t.id
	zone.setup(wizard, int(wizard.get(&"team")), t.radius_at(rank), t.duration_at(rank),
			spell_damage(t, rank), t.tick_interval, heal_ratio, color)
	zone.hit_target.connect(_report_hit.bind(t.id))
	_world().add_child(zone)
	return zone


## A spell's damage (per hit / per tick) at `rank` after the wizard's spell_power (items.md:
## x (1 + spell_power / 100), spell power capped at 60 by balance-1).
func spell_damage(t: SpellType, rank: int) -> float:
	return t.damage_at(rank) * spell_power_multiplier()


func spell_power_multiplier() -> float:
	if wizard and wizard.has_method(&"get_stat"):
		return 1.0 + clampf(float(wizard.call(&"get_stat", &"spell_power")), -100.0, 60.0) / 100.0
	return 1.0


## Spell heals (Wild Bloom): x spell power (kingdom-nature.md 3.1), then x the Blossom passive
## (Bloomcaller Staff, x1.25: rank 1 heals 75).
func heal_multiplier() -> float:
	return spell_power_multiplier() * blossom_multiplier()


## The item passive Blossom alone (ItemPassives.heal_multiplier): spell heals and shields (Rime Aegis).
func blossom_multiplier() -> float:
	if wizard == null or not is_instance_valid(wizard):
		return 1.0
	return ItemPassives.heal_multiplier(wizard)


# Every damage path of the six spells ends here: Wizard.spell_hit (item passives listen to it).
func _report_hit(target: Node3D, dealt: float, id: StringName) -> void:
	if dealt <= 0.0 or not is_instance_valid(wizard) or not is_instance_valid(target):
		return
	if wizard.has_method(&"notify_spell_hit"):
		wizard.call(&"notify_spell_hit", target, dealt, id)


# ---------------------------------------------------------------- Malrik's AI rules

## The spells.md rule that applies now, or {} for none. Returns
## {"spell_id": StringName, "target": Variant, "retreat": bool}; "retreat" = rule 1 (Umbral Shroud):
## the caller also walks Malrik to his anchor. Skips spells that are not learned, on cooldown or
## too expensive. P = enemies of the wizard (not neutral) within 12 m. Rules:
## 1. Umbral Shroud if HP < 35 % of max. 2. Soul Siphon on the P unit with the most P units within the
## spell radius (at least 3, itself included; ties: nearest). 3. Shadow Lance (enemy units in lance
## range, neutrals included): the unit with HP <= 50 and the most HP; else, if HP < 60 %, the unit
## with the most HP; else an enemy wizard; else the nearest. Call it at most every 0.5 s and cast once.
func suggest_cast() -> Dictionary:
	if not _alive(wizard) or not _can_act(wizard):
		return {}
	var hp := float(wizard.get(&"hp"))
	var max_hp := _max_hp()
	if _is_torvald():
		return _suggest_torvald(hp, max_hp)
	if _is_ysolde():
		return _suggest_ysolde(hp, max_hp)
	if _ids.has(&"umbral_shroud") and hp < max_hp * AI_SHROUD_HP_RATIO and can_cast(&"umbral_shroud") == "":
		return {"spell_id": &"umbral_shroud", "target": null, "retreat": true}
	if _ids.has(&"soul_siphon") and can_cast(&"soul_siphon") == "":
		var center: Variant = _best_cluster(radius_of(&"soul_siphon"))
		if center != null:
			return {"spell_id": &"soul_siphon", "target": center, "retreat": false}
	if _ids.has(&"shadow_lance") and can_cast(&"shadow_lance") == "":
		var lance_target := _pick_lance_target(hp, max_hp)
		if lance_target:
			return {"spell_id": &"shadow_lance", "target": lance_target, "retreat": false}
	return {}


func _is_torvald() -> bool:
	for id in TORVALD_SPELLS:
		if _ids.has(id):
			return true
	return false


## Torvald's rules (kingdom-ice.md 4.3), first that applies; skips unlearned / cooldown / mana.
## "retreat" = HP < 35 % (ai.md rule 8: Rime Aegis first if ready, then the caller retreats).
## 1. Rime Aegis: HP < 50 %, or >= 4 own soldiers within 8 m and >= 3 enemy units within 10 m.
## 2. Flash Freeze: the enemy unit within range with the most enemy units within the spell radius of it
##    (itself included, at least 3); ties: the group holding an enemy wizard, then the nearest centre.
## 3. Rime Bolt (units in range, neutrals included): an enemy wizard not chilled; else the highest-cost
##    unit not chilled; else the nearest.
## Enemy counts for 1-2 skip neutrals (as Malrik's Soul Siphon).
func _suggest_torvald(hp: float, max_hp: float) -> Dictionary:
	var retreat := hp < max_hp * AI_RETREAT_HP_RATIO
	if _ids.has(&"rime_aegis") and can_cast(&"rime_aegis") == "":
		var want := hp < max_hp * AI_AEGIS_HP_RATIO
		if not want:
			want = _count_own_soldiers(AI_AEGIS_ALLY_RANGE) >= AI_AEGIS_ALLIES \
					and _enemies_near(wizard.global_position, AI_AEGIS_ENEMY_RANGE).size() >= AI_AEGIS_ENEMIES
		if want:
			return {"spell_id": &"rime_aegis", "target": null, "retreat": retreat}
	if _ids.has(&"flash_freeze") and can_cast(&"flash_freeze") == "":
		var center: Variant = _best_cluster_in_range(&"flash_freeze", AI_FREEZE_CLUSTER)
		if center != null:
			return {"spell_id": &"flash_freeze", "target": center, "retreat": retreat}
	if _ids.has(&"rime_bolt") and can_cast(&"rime_bolt") == "":
		var bolt_target := _pick_rime_bolt_target()
		if bolt_target:
			return {"spell_id": &"rime_bolt", "target": bolt_target, "retreat": retreat}
	return {}


func _is_ysolde() -> bool:
	for id in YSOLDE_SPELLS:
		if _ids.has(id):
			return true
	return false


## Ysolde's rules (kingdom-nature.md 3.3), first that applies; skips unlearned / cooldown / mana.
## "retreat" = HP < 35 % (ai.md rule 8): Wild Bloom on herself first if ready, then the caller retreats.
## 1. Wild Bloom: an own soldier within the spell range with >= 3 own soldiers under 60 % HP within
##    5 m of it (itself included): centre there (most hurt, then nearest); or HP < 45 %: centre on her.
## 2. Call the Thicket: >= 4 enemy units within 12 m of her; point = 3 m from the nearest one toward
##    her, clamped to the spell range.
## 3. Thornburst: the enemy unit within range with the most enemy units within the spell radius of it
##    (itself included, at least 2; ties: the group holding an enemy wizard, then the nearest); else the
##    enemy wizard if in range.
## Soldiers = own non-worker, non-wizard, non-summon units. Enemy counts skip neutrals.
func _suggest_ysolde(hp: float, max_hp: float) -> Dictionary:
	var retreat := hp < max_hp * AI_RETREAT_HP_RATIO
	if _ids.has(&"wild_bloom") and can_cast(&"wild_bloom") == "":
		if retreat:
			return {"spell_id": &"wild_bloom", "target": wizard.global_position, "retreat": true}
		var center: Variant = _best_bloom_center()
		if center != null:
			return {"spell_id": &"wild_bloom", "target": center, "retreat": false}
		if hp < max_hp * AI_BLOOM_SELF_HP_RATIO:
			return {"spell_id": &"wild_bloom", "target": wizard.global_position, "retreat": false}
	if _ids.has(&"call_the_thicket") and can_cast(&"call_the_thicket") == "":
		var foes := _enemies_near(wizard.global_position, AI_THICKET_RANGE)
		if foes.size() >= AI_THICKET_ENEMIES:
			return {"spell_id": &"call_the_thicket", "target": _thicket_point(foes), "retreat": retreat}
	if _ids.has(&"thornburst") and can_cast(&"thornburst") == "":
		var center: Variant = _best_cluster_in_range(&"thornburst", AI_THORN_CLUSTER)
		if center == null:
			var foe_wizard := _enemy_wizard_within(range_of(&"thornburst"))
			if foe_wizard:
				center = foe_wizard.global_position
		if center != null:
			return {"spell_id": &"thornburst", "target": center, "retreat": retreat}
	return {}


func _own_soldiers() -> Array[Node3D]:
	var team: Variant = wizard.get(&"team")
	var out: Array[Node3D] = []
	for node in wizard.get_tree().get_nodes_in_group(&"units"):
		var u := node as Node3D
		if u == null or u == wizard or u is Wizard or u.get(&"team") != team or not _alive(u) \
				or _is_worker(u) or is_summon(u):
			continue
		out.append(u)
	return out


func _best_bloom_center() -> Variant:
	var soldiers := _own_soldiers()
	var hurt: Array[Node3D] = []
	for u in soldiers:
		var mhp: float = float(u.call(&"get_stat", &"max_hp")) if u.has_method(&"get_stat") else float(u.get(&"max_hp"))
		if float(u.get(&"hp")) < mhp * AI_BLOOM_HURT_RATIO:
			hurt.append(u)
	if hurt.size() < AI_BLOOM_HURT_COUNT:
		return null
	var reach := range_of(&"wild_bloom")
	var best: Node3D = null
	var best_count := 0
	var best_dist := INF
	for u in soldiers:
		var d := _flat(u.global_position - wizard.global_position).length()
		if d > reach:
			continue
		var count := 0
		for v in hurt:
			if _flat(v.global_position - u.global_position).length() <= AI_BLOOM_GROUP_RANGE:
				count += 1
		if count > best_count or (count == best_count and d < best_dist):
			best = u
			best_count = count
			best_dist = d
	if best == null or best_count < AI_BLOOM_HURT_COUNT:
		return null
	return best.global_position


# 3 m from the nearest foe toward Ysolde (never past her), clamped to Call the Thicket's range.
func _thicket_point(foes: Array[Node3D]) -> Vector3:
	var me := wizard.global_position
	var nearest: Node3D = null
	var nearest_dist := INF
	for u in foes:
		var d := _flat(u.global_position - me).length()
		if d < nearest_dist:
			nearest = u
			nearest_dist = d
	var foe_pos := nearest.global_position
	var to_me := _flat(me - foe_pos)
	var p := foe_pos
	if to_me.length() > 0.001:
		p = foe_pos + to_me.normalized() * minf(AI_THICKET_OFFSET, to_me.length())
	var offset := _flat(p - me)
	var reach := range_of(&"call_the_thicket")
	if offset.length() > reach:
		offset = offset.normalized() * reach
	return Vector3(me.x + offset.x, me.y, me.z + offset.z)


func _enemy_wizard_within(reach: float) -> Node3D:
	var best: Node3D = null
	var best_dist := INF
	for node in wizard.get_tree().get_nodes_in_group(&"units"):
		var u := node as Node3D
		if u == null or not u is Wizard or not _alive(u) or not _is_enemy(u):
			continue
		var d := _flat(u.global_position - wizard.global_position).length()
		if d <= reach and d < best_dist:
			best = u
			best_dist = d
	return best


func _count_own_soldiers(r: float) -> int:
	var team: Variant = wizard.get(&"team")
	var count := 0
	for node in wizard.get_tree().get_nodes_in_group(&"units"):
		var u := node as Node3D
		if u == null or u == wizard or u is Wizard or u.get(&"team") != team or not _alive(u) or _is_worker(u):
			continue
		if _flat(u.global_position - wizard.global_position).length() <= r:
			count += 1
	return count


# Living enemy units (not neutral) within `r` of `pos`.
func _enemies_near(pos: Vector3, r: float) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for node in wizard.get_tree().get_nodes_in_group(&"units"):
		var u := node as Node3D
		if u == null or not _alive(u) or not _is_enemy(u) or int(u.get(&"team")) == Unit.Team.NEUTRAL:
			continue
		if _flat(u.global_position - pos).length() <= r:
			out.append(u)
	return out


## The enemy unit (not neutral) within `spell_id`'s range with the most enemy units within its radius
## (itself included, at least `min_count`); ties: the group holding an enemy wizard, then the nearest.
## Its position, or null.
func _best_cluster_in_range(spell_id: StringName, min_count: int) -> Variant:
	var reach := range_of(spell_id)
	var r := radius_of(spell_id)
	var candidates := _enemies_near(wizard.global_position, reach)
	var pool := _enemies_near(wizard.global_position, reach + r)
	var best: Node3D = null
	var best_count := 0
	var best_wiz := false
	var best_dist := INF
	for u in candidates:
		var count := 0
		var has_wiz := false
		for v in pool:
			if _flat(v.global_position - u.global_position).length() <= r:
				count += 1
				has_wiz = has_wiz or v is Wizard
		var d := _flat(u.global_position - wizard.global_position).length()
		var better := count > best_count
		if count == best_count:
			better = (has_wiz and not best_wiz) or (has_wiz == best_wiz and d < best_dist)
		if better:
			best = u
			best_count = count
			best_wiz = has_wiz
			best_dist = d
	if best == null or best_count < min_count:
		return null
	return best.global_position


func _pick_rime_bolt_target() -> Node3D:
	var reach := range_of(&"rime_bolt")
	var in_range: Array[Node3D] = []
	for node in wizard.get_tree().get_nodes_in_group(&"units"):
		var u := node as Node3D
		if u == null or not _alive(u) or not _is_enemy(u):
			continue
		if _flat(u.global_position - wizard.global_position).length() <= reach + edge_radius(u):
			in_range.append(u)
	if in_range.is_empty():
		return null
	for u in in_range:
		if u is Wizard and not _has_status(u, &"chill"):
			return u
	var best: Node3D = null
	var best_cost := -1
	for u in in_range:
		if u is Wizard or _has_status(u, &"chill"):
			continue
		var c := _unit_cost(u)
		if c > best_cost:
			best = u
			best_cost = c
	if best:
		return best
	var best_dist := INF
	for u in in_range:
		var d := _flat(u.global_position - wizard.global_position).length()
		if d < best_dist:
			best_dist = d
			best = u
	return best


static func _unit_cost(u: Node3D) -> int:
	var ut: Variant = u.get(&"unit_type")
	if ut is Resource and (ut as Resource).get(&"cost") != null:
		return int((ut as Resource).get(&"cost"))
	return 0


static func _has_status(u: Node3D, id: StringName) -> bool:
	return u.has_method(&"has_status") and bool(u.call(&"has_status", id))


## Casts what suggest_cast() proposes. Returns the suggestion that was cast ({} if none).
func auto_cast() -> Dictionary:
	var s := suggest_cast()
	if s.is_empty() or cast(s["spell_id"], s["target"]) != "":
		return {}
	return s


func _best_cluster(r: float) -> Variant:
	var near: Array[Node3D] = []
	for node in wizard.get_tree().get_nodes_in_group(&"units"):
		var u := node as Node3D
		if u == null or not _is_enemy(u) or int(u.get(&"team")) == Unit.Team.NEUTRAL:
			continue
		if _flat(u.global_position - wizard.global_position).length() <= AI_NEARBY:
			near.append(u)
	var best: Node3D = null
	var best_count := 0
	var best_dist := INF
	for u in near:
		var count := 0
		for v in near:
			if _flat(v.global_position - u.global_position).length() <= r:
				count += 1
		var d := _flat(u.global_position - wizard.global_position).length()
		if count > best_count or (count == best_count and d < best_dist):
			best = u
			best_count = count
			best_dist = d
	if best == null or best_count < AI_CLUSTER_SIZE:
		return null
	return best.global_position


func _pick_lance_target(hp: float, max_hp: float) -> Node3D:
	var reach := range_of(&"shadow_lance")
	var in_range: Array[Node3D] = []
	for node in wizard.get_tree().get_nodes_in_group(&"units"):
		var u := node as Node3D
		if u and _is_enemy(u) and _flat(u.global_position - wizard.global_position).length() <= reach:
			in_range.append(u)
	if in_range.is_empty():
		return null
	var best: Node3D = null
	for u in in_range:
		var uhp := float(u.get(&"hp"))
		if uhp <= AI_LANCE_LOW_HP and (best == null or uhp > float(best.get(&"hp"))):
			best = u
	if best:
		return best
	if hp < max_hp * AI_LANCE_LOW_SELF:
		for u in in_range:
			if best == null or float(u.get(&"hp")) > float(best.get(&"hp")):
				best = u
		return best
	for u in in_range:
		if u is Wizard:
			return u
	var best_dist := INF
	for u in in_range:
		var d := _flat(u.global_position - wizard.global_position).length()
		if d < best_dist:
			best_dist = d
			best = u
	return best


# ---------------------------------------------------------------- helpers

## Damage `target` (unit or building) and return what was really dealt (capped by its HP).
static func deal_damage(target: Node3D, amount: float, attacker: Node3D) -> float:
	if PaceSwitch.spell_mods_on:
		amount *= PaceSwitch.spell_damage_x(target, attacker)   # Blitz only (blitz_2026-10-10.md)
	var before: Variant = target.get(&"hp")
	target.call(&"take_damage", amount, attacker)
	var after: Variant = target.get(&"hp")
	if before == null or after == null:
		return amount
	return float(before) - maxf(0.0, float(after))


## How far from its centre a unit or building can be touched (target_radius(), else a default).
static func edge_radius(target: Node3D) -> float:
	return Unit.radius_of(target)


func _cooldown_for(id: StringName) -> float:
	var t := spell_type(id)
	if t == null:
		return 0.0
	var cd := t.cooldown_at(maxi(1, rank_of(id)))
	if wizard and wizard.has_method(&"get_stat"):
		cd *= cooldown_multiplier(float(wizard.call(&"get_stat", &"cooldown_reduction")))
	return cd


## items.md: cooldowns x (1 - cdr / 100), cdr (percent) capped at 40. Item actives use it too.
static func cooldown_multiplier(cdr_percent: float) -> float:
	return 1.0 - clampf(cdr_percent, 0.0, MAX_CDR) / 100.0


func _target_ok(t: SpellType, target: Variant) -> bool:
	if t == null:
		return false
	match t.target_type:
		SpellType.TargetType.SELF:
			return true
		SpellType.TargetType.UNIT:
			if typeof(target) != TYPE_OBJECT or not is_instance_valid(target) or not target is Node3D:
				return false
			var node := target as Node3D
			return node.has_method(&"take_damage") and _alive(node) and _is_enemy(node)
		_:
			if target is Vector3:
				return true
			return typeof(target) == TYPE_OBJECT and is_instance_valid(target) and target is Node3D


func _target_position(target: Variant) -> Vector3:
	if target is Vector3:
		return target
	if typeof(target) == TYPE_OBJECT and is_instance_valid(target) and target is Node3D:
		return (target as Node3D).global_position
	return wizard.global_position


func _in_range(id: StringName, target: Variant) -> bool:
	var t := spell_type(id)
	if t.target_type == SpellType.TargetType.SELF:
		return true
	var reach := range_of(id)
	if t.target_type == SpellType.TargetType.UNIT:
		reach += edge_radius(target as Node3D)
	return _flat(_target_position(target) - wizard.global_position).length() <= reach


## 2v2: an allied seat's unit counts as a friend for heals, shields and buffs (map-2v2.md 4.2).
static func _friend_team(u: Node, team: Variant) -> bool:
	var t: Variant = u.get(&"team")
	return t != null and team != null and Teams.is_allied_fast(int(t), int(team))


func _is_enemy(node: Node3D) -> bool:
	if wizard.has_method(&"is_enemy_of"):
		return bool(wizard.call(&"is_enemy_of", node))
	var a: Variant = wizard.get(&"team")
	var b: Variant = node.get(&"team")
	return a != null and b != null and not Teams.is_allied_fast(int(a), int(b))


func _mana() -> float:
	var m: Variant = wizard.get(&"mana")
	return float(m) if m != null else 0.0


func _max_hp() -> float:
	if wizard.has_method(&"get_stat"):
		return float(wizard.call(&"get_stat", &"max_hp"))
	return float(wizard.get(&"max_hp"))


func _height() -> float:
	var h: Variant = wizard.get(&"body_height")
	return float(h) if h != null else 2.0


func _world() -> Node:
	var scene := wizard.get_tree().current_scene
	return scene if scene else wizard.get_parent()


## True for a valid node whose is_alive() says so (units, buildings, wizards).
static func is_target_alive(node: Variant) -> bool:
	return _alive(node)


static func _alive(node: Variant) -> bool:
	return node != null and is_instance_valid(node) and (node as Object).has_method(&"is_alive") \
			and bool((node as Object).call(&"is_alive"))


## False only while the unit says it can't act (frozen, Unit.can_act from 7.G1).
static func _can_act(node: Variant) -> bool:
	if node == null or not is_instance_valid(node) or not (node as Object).has_method(&"can_act"):
		return true
	return bool((node as Object).call(&"can_act"))


static func _is_worker(node: Node3D) -> bool:
	return node.has_method(&"is_worker") and bool(node.call(&"is_worker"))


static func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)
