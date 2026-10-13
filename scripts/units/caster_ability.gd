class_name CasterAbility
extends Node
## One caster unit's mana, two spells and passive (docs/design/caster-units.md 3-5): the child "CasterAbility" of each
## Kilnwarden, Rimecarver, Bramblesage and Gloom Deacon (Unit._ready -> CasterKit.attach). Numbers: CasterKit.SPELLS.
## Mana: max 200 (stat `max_mana`), starts at 50, regen 0.8 / s (stat `mana_regen`); levels +20 / +0.05 each.
## A cast: can_cast() checks (3.2 refusals), then a 0.4 s cast (the caster stands still, set_cast_lock; Blood Tithe and
## Scrying Rune excepted), then the effect; `dazed` / `frozen` during the cast cancel it (nothing spent). Global
## cooldown 1 s. Autocast: every 0.5 s (staggered), only while the caster is not walking on a plain move order and not
## casting / channelling; the first rule that applies, one cast per check (player defaults: SPELLS "autocast";
## `bot_controlled` = every spell on, walking or not). Smart-cast / walk into range: order_cast().
## Effects are wired to UnitVfx ids (art/vfx/caster_*_vfx.gd): slag_rain, slagged, mana_scald, stoke, rime_bulwark
## (RimeBulwark), scrying_rune(_end), snagroot, pollen_haze, hazed (CasterHaze), seedcloak, blood_tithe(_end),
## umbral_passage, passage_step, vigil; model hooks play_cast(id), set_channeling(on) (the Deacon).

signal mana_changed(mana: float, max_mana: float)
signal spell_cast(id: StringName)
signal autocast_changed(id: StringName, on: bool)
signal channel_changed(id: StringName, on: bool)

const NODE_NAME := "CasterAbility"
const TICK := 0.1
const RELEASE_SLACK := 2.0          ## a target may drift this much out of range during the 0.4 s cast
const APPROACH_REPATH := 0.5
const SIEGE_IDS: Array[StringName] = [&"ash_hurler", &"frost_mortar", &"cinder_arbalest"]
const LEVEL_MODIFIER := &"caster_level"
const MANA_BAR_HEIGHT := 0.07
const MANA_COLOR := Color(0.35, 0.55, 1.0)

var unit: Unit
var id: StringName = &""
## Current mana (0 .. max_mana()).
var mana := CasterKit.START_MANA
## Spell id -> casts landed (tests, logs, the bot's `last_cast`).
var casts := {}
## The target of the last cast (a Vector3 or a Unit), its spell and match time.
var last_target: Variant = null
var last_spell: StringName = &""
var last_cast_time := -INF
## XP earned from spells so far (3.4).
var spell_xp := 0
## Bots (AICasters): every spell autocasts, also while walking; `reaction` = the autocast tick (difficulty).
var bot_controlled := false
var reaction := CasterKit.AUTOCAST_TICK
## Hard bots: the Kilnwarden holds Mana Scald for an enemy caster's cast (1.5 s), the Bramblesage holds Pollen Haze for
## 5 ranged units in the first 5 s of a fight.
var bot_hard := false
## Wave Strike lane casters (wave-strike.md 14.1, set by LaneSpawner): cast while walking like `bot_controlled`, every
## spell through autocast_target() (Rime Bulwark on its dive-guard rule) whatever the autocast toggles, except
## Umbral Passage and Scrying Rune (never). Default false: skirmish / missions unchanged.
var lane_mode := false
## Spawn order of this caster in the match (CasterKit.attach): the deterministic stagger of its autocast tick.
var serial := 0

## Spells whose target the team claims while they are cast / in flight (CasterKit.claim, code review M2), and the
## claim radius of a point spell (another caster's point within it counts as the same clump).
const CLAIMED_SPELLS := [&"slag_rain", &"mana_scald", &"snagroot", &"pollen_haze"]

var _autocast := {}          # spell id -> bool
var _cd := {}                # spell id -> seconds left (Umbral Passage)
var _cd_total := {}
var _gcd := 0.0
var _auto_left := CasterKit.AUTOCAST_TICK
var _tick_left := TICK
var _pending: Dictionary = {}    # the cast in its 0.4 s: {id, target, left}
var _approach: Dictionary = {}   # walking into range: {id, target, serial, repath}
var _channel: Dictionary = {}    # Blood Tithe / Umbral Passage while it runs
var _timed: Array = []           # delayed effects: {left, fn: Callable, args: Array}
var _still_time := 0.0
var _last_pos := Vector3.INF
var _stoke_at := -INF
var _vigil_at := -INF
var _seedcloak_at := -INF
var _above_half := true
var _slagged := {}               # victim instance id -> match time its slag (from me) ends
var _runes: Array = []           # my Scrying Runes (CasterKit rune dictionaries), oldest first
var _scald_wait := {}            # hard bot: enemy caster instance id -> time first seen in range
var _fight_since := -INF         # first enemy within 12 m (hard Bramblesage)
var _slag_inflight: Array[Vector3] = []   # Slag Rain globs in the air (autocast never doubles one)
var _wall_facing := Vector3.ZERO  # the Bulwark being raised lies across this (a {at, facing} target), else caster -> point
var _mana_bar: MeshInstance3D
var _mana_mat: ShaderMaterial
var _last_emit := -1.0

static var _mana_shader: Shader


func _ready() -> void:
	if unit == null:
		unit = get_parent() as Unit
	if id == &"" and unit and unit.unit_type:
		id = unit.unit_type.id
	unit.set_base_stat(&"max_mana", CasterKit.MAX_MANA)
	unit.set_base_stat(&"mana_regen", CasterKit.MANA_REGEN)
	mana = minf(CasterKit.START_MANA, max_mana())
	for s in spell_ids():
		_autocast[s] = bool(CasterKit.spell_value(s, "autocast", false))
	_auto_left = CasterKit.AUTOCAST_TICK * float(serial % 5) / 5.0   # spawn order, never the instance id (replays)
	unit.level_changed.connect(_on_level_changed)
	unit.displaced.connect(_on_displaced)
	unit.damage_taken.connect(_on_damage_taken)
	unit.died.connect(_on_died)
	var events := get_node_or_null(^"/root/Events")
	if events and events.has_signal(&"unit_died"):
		events.connect(&"unit_died", _on_any_unit_died)
	_last_pos = unit.global_position
	_build_mana_bar()


# ---------------------------------------------------------------- public API (CLAUDE.md "Casters")

## The Z / V spells, in card order.
func spell_ids() -> Array[StringName]:
	return CasterKit.spells_of(id)


func passive_id() -> StringName:
	return CasterKit.passive_of(id)


func max_mana() -> float:
	return unit.get_stat(&"max_mana") if unit else CasterKit.MAX_MANA


func mana_regen() -> float:
	var r := unit.get_stat(&"mana_regen") if unit else CasterKit.MANA_REGEN
	if passive_id() == &"stillness" and is_still():
		r *= float(CasterKit.PASSIVES[&"stillness"]["mult"])
	return r


## Rimecarver's Stillness: 3 s without moving.
func is_still() -> bool:
	return _still_time >= float(CasterKit.PASSIVES[&"stillness"]["still"])


func add_mana(amount: float) -> void:
	mana = clampf(mana + amount, 0.0, max_mana())
	_emit_mana(true)


## Mana Scald on this caster: burns up to `amount`, returns what was burnt.
func burn_mana(amount: float) -> float:
	var b := clampf(amount, 0.0, mana)
	mana -= b
	_emit_mana(true)
	return b


func mana_cost(spell_id: StringName) -> float:
	return float(CasterKit.spell_value(spell_id, "mana", 0.0))


func autocast(spell_id: StringName) -> bool:
	return bool(_autocast.get(spell_id, false))


func set_autocast(spell_id: StringName, on: bool) -> void:
	if not spell_ids().has(spell_id) or autocast(spell_id) == on:
		return
	_autocast[spell_id] = on
	autocast_changed.emit(spell_id, on)


func toggle_autocast(spell_id: StringName) -> void:
	set_autocast(spell_id, not autocast(spell_id))


func cooldown_left(spell_id: StringName) -> float:
	return maxf(0.0, float(_cd.get(spell_id, 0.0)))


func cooldown_total(spell_id: StringName) -> float:
	return float(_cd_total.get(spell_id, CasterKit.spell_value(spell_id, "cooldown", 0.0)))


func gcd_left() -> float:
	return maxf(0.0, _gcd)


## True during the 0.4 s cast.
func is_casting() -> bool:
	return not _pending.is_empty()


func is_channelling() -> bool:
	return not _channel.is_empty()


func channel_id() -> StringName:
	return _channel.get("id", &"")


## The ally a Blood Tithe tethers now (null when none).
func tithe_target() -> Unit:
	if _channel.get("id", &"") != &"blood_tithe":
		return null
	var t: Variant = _channel.get("target")
	return t as Unit if is_instance_valid(t) else null


## Ends a channel now (Blood Tithe, or cancels an Umbral Passage: mana kept, 5 s cooldown).
func stop_channel() -> void:
	if _channel.is_empty():
		return
	if _channel["id"] == &"umbral_passage":
		_cancel_passage()
	else:
		_end_tithe()


## "" when `spell_id` may be cast at `target` now (in range), else the refusal (CasterKit.REASON_*).
func can_cast(spell_id: StringName, target: Variant) -> String:
	if not spell_ids().has(spell_id):
		return CasterKit.REASON_INVALID
	if unit == null or not unit.is_alive() or not unit.can_act() or unit.is_displaced() or is_casting():
		return CasterKit.REASON_CANT
	if cooldown_left(spell_id) > 0.0 or _gcd > 0.0:
		# Only the 1 s global cooldown blocks and the target is out of range: "Out of range", so smart-cast and
		# order_cast walk it in (the cast waits for the cooldown on arrival, _tick_approach). Code review L1.
		if cooldown_left(spell_id) <= 0.0 and _channel.get("id", &"") != &"umbral_passage" \
				and mana + 0.001 >= mana_cost(spell_id) and target_reason(spell_id, target) == "" \
				and distance_to_target(target) > float(CasterKit.spell_value(spell_id, "range", 0.0)) + 0.1:
			return CasterKit.REASON_RANGE
		return CasterKit.REASON_RECHARGING
	if _channel.get("id", &"") == &"umbral_passage":
		return CasterKit.REASON_CANT
	if mana + 0.001 < mana_cost(spell_id):
		return CasterKit.REASON_MANA
	var r := target_reason(spell_id, target)
	if r != "":
		return r
	if distance_to_target(target) > float(CasterKit.spell_value(spell_id, "range", 0.0)) + 0.1:
		return CasterKit.REASON_RANGE
	return ""


## The target checks alone (no mana, cooldown or range): "" or No target / Invalid target.
func target_reason(spell_id: StringName, target: Variant) -> String:
	var kind := CasterKit.target_kind(spell_id)
	if target == null or (target is Object and not is_instance_valid(target)):
		return CasterKit.REASON_NO_TARGET
	if kind == &"point":
		var p: Variant = point_of(target)
		if p == null:
			return CasterKit.REASON_NO_TARGET
		if not bool(CasterKit.spell_value(spell_id, "fog", false)) and not _team_sees(p):
			return CasterKit.REASON_INVALID
		if spell_id == &"rime_bulwark" and not _wall_spot_ok(p):
			return CasterKit.REASON_INVALID
		return ""
	if not (target is Unit):
		return CasterKit.REASON_NO_TARGET
	var u := target as Unit
	if not u.is_alive() or not u.is_inside_tree():
		return CasterKit.REASON_INVALID
	if kind == &"enemy":
		if not unit.is_enemy_of(u) or not _team_sees(u.global_position):
			return CasterKit.REASON_INVALID
		match spell_id:
			&"mana_scald":
				if CasterKit.mana_of(u) < 0.0 or u.has_status(&"scalded"):
					return CasterKit.REASON_INVALID
			&"snagroot":
				if snagroot_immune(u):
					return CasterKit.REASON_INVALID
		return ""
	# ally (the 2v2 rule, same as wizard / support spells: own seat or an allied seat)
	if u == unit or not Teams.is_allied_fast(int(u.team), int(unit.team)):
		return CasterKit.REASON_INVALID
	if spell_id == &"blood_tithe":
		if u.hp >= u.max_hp - 0.01 or tethers_on(u) >= int(CasterKit.spell_value(spell_id, "max_tethers", 2)):
			return CasterKit.REASON_INVALID
	return ""


## Flat distance from the caster to the target (a unit's edge, a point).
func distance_to_target(target: Variant) -> float:
	var p: Variant = point_of(target)
	if p == null or unit == null:
		return INF
	var d := _flat((p as Vector3), unit.global_position)
	if target is Unit and is_instance_valid(target):
		d -= (target as Unit).radius
	return maxf(0.0, d)


## Casts now (in range) and returns "" or the refusal (it never walks).
func cast(spell_id: StringName, target: Variant) -> String:
	var r := can_cast(spell_id, target)
	if r != "":
		return r
	_begin(spell_id, target)
	return ""


## The player's / smart-cast order: casts now, or walks into range first (a new order cancels the walk). "" or the
## refusal (never "Out of range").
func order_cast(spell_id: StringName, target: Variant) -> String:
	var r := can_cast(spell_id, target)
	if r == "":
		_begin(spell_id, target)
		return ""
	if r != CasterKit.REASON_RANGE:
		return r
	_approach = {"id": spell_id, "target": target, "repath": 0.0}
	_walk_toward(target)
	_approach["serial"] = unit.order_serial
	return ""


## True while walking into range for an ordered cast.
func is_approaching() -> bool:
	return not _approach.is_empty()


## Blood Tithe tethers of any Gloom Deacon on `ally` now.
static func tethers_on(ally: Unit) -> int:
	if ally == null:
		return 0
	var n := 0
	for d in CasterKit.casters_of(int(ally.team), &"gloom_deacon"):
		var ab := CasterKit.ability_of(d)
		if ab and ab.tithe_target() == ally:
			n += 1
	return n


## Snagroot immunity: titans, epic beasts, units of pop >= 4 (buildings are never units).
static func snagroot_immune(u: Unit) -> bool:
	return u == null or CasterKit.is_titan(u) or u.is_in_group(&"beasts") \
			or (u.unit_type != null and u.unit_type.pop >= int(CasterKit.spell_value(&"snagroot", "immune_pop", 4)))


# ---------------------------------------------------------------- the loop

func _physics_process(delta: float) -> void:
	_run_timed(delta)
	if unit == null or not unit.is_alive():
		return
	_gcd -= delta
	if not _above_half and unit.hp >= unit.max_hp * float(CasterKit.PASSIVES[&"seedcloak"]["hp_pct"]):
		_above_half = true   # healed back over half: the next drop can burst again (R3-8)
	for k: Variant in _cd:   # existing keys only: no keys() copy per frame
		_cd[k] = float(_cd[k]) - delta
	# Stillness (and the regen it boosts).
	var pos := unit.global_position
	if _last_pos == Vector3.INF or _flat(pos, _last_pos) > 0.02:
		_still_time = 0.0
	else:
		_still_time += delta
	_last_pos = pos
	var m := max_mana()
	if mana < m:
		mana = minf(m, mana + mana_regen() * delta)
	elif mana > m:
		mana = m
	if not _pending.is_empty():
		_tick_pending(delta)
	_tick_left -= delta
	if _tick_left <= 0.0:
		_tick_left += TICK
		_emit_mana(false)
		_update_mana_bar()
		if not _approach.is_empty():
			_tick_approach()
	if not _channel.is_empty():
		_tick_channel(delta)
	_auto_left -= delta
	if _auto_left <= 0.0:
		_auto_left += reaction if bot_controlled else CasterKit.AUTOCAST_TICK
		_autocast_check()


func _emit_mana(force: bool) -> void:
	if force or absf(mana - _last_emit) >= 1.0 or (mana >= max_mana() and _last_emit < max_mana()):
		_last_emit = mana
		mana_changed.emit(mana, max_mana())


func _run_timed(delta: float) -> void:
	if _timed.is_empty():
		return
	var due: Array = []
	for e: Dictionary in _timed:
		e["left"] = float(e["left"]) - delta
		if float(e["left"]) <= 0.0:
			due.append(e)
	for e: Dictionary in due:
		_timed.erase(e)
		(e["fn"] as Callable).callv(e["args"])


func _after(seconds: float, fn: Callable, args: Array = []) -> void:
	_timed.append({"left": seconds, "fn": fn, "args": args})


# ---------------------------------------------------------------- casting

func _begin(spell_id: StringName, target: Variant) -> void:
	_approach = {}
	if not _channel.is_empty():
		stop_channel()
	var p: Variant = point_of(target)
	if p != null:
		unit.face_direction((p as Vector3) - unit.global_position)
	_gcd = CasterKit.GLOBAL_COOLDOWN
	match spell_id:
		&"blood_tithe":
			_start_tithe(target as Unit)
			return
		&"umbral_passage":
			_start_passage(p as Vector3)
			return
	if bool(CasterKit.spell_value(spell_id, "stop", true)):
		unit.set_cast_lock(CasterKit.CAST_TIME)
	unit.model_call(&"play_cast", [spell_id])
	_pending = {"id": spell_id, "target": target, "left": CasterKit.CAST_TIME}
	if CLAIMED_SPELLS.has(spell_id):
		CasterKit.claim(int(unit.team), spell_id, target, self, CasterKit.now_s() + CasterKit.CAST_TIME
				+ _claim_after_release(spell_id))


# How long the team claim outlives the release: Slag Rain until the glob lands, Snagroot until the pull ends (the
# status that tells the others, `slagged` / `rooted`, comes then); Mana Scald and Pollen Haze mark at release.
static func _claim_after_release(spell_id: StringName) -> float:
	match spell_id:
		&"slag_rain":
			return float(CasterKit.spell_value(&"slag_rain", "flight", 0.6)) + 0.1
		&"snagroot":
			return float(CasterKit.spell_value(&"snagroot", "hit", 0.25)) \
					+ float(CasterKit.spell_value(&"snagroot", "drag_time", 0.5)) + 0.1
	return 0.1


# The 0.4 s cast ends without a release (interrupted, target gone): nothing spent, the team claim dropped.
func _clear_pending() -> void:
	if _pending.is_empty():
		return
	var sid: StringName = _pending["id"]
	_pending = {}
	if CLAIMED_SPELLS.has(sid) and unit != null and is_instance_valid(unit):
		CasterKit.release_claim(int(unit.team), sid, self)


## True when another caster of this team is already casting `spell_id` at `target` (the same unit, or for a point
## spell a point within its radius): autocast and the bot's fight casts skip it (code review M2).
func claimed_elsewhere(spell_id: StringName, target: Variant) -> bool:
	if unit == null:
		return false
	var r := float(CasterKit.spell_value(spell_id, "radius", 0.0)) if CasterKit.target_kind(spell_id) == &"point" else 0.0
	return CasterKit.is_claimed(int(unit.team), spell_id, target, self, r)


func _tick_pending(delta: float) -> void:
	if not unit.can_act() or unit.is_displaced():
		_clear_pending()   # dazed / frozen / pulled: cancelled, nothing spent
		return
	_pending["left"] = float(_pending["left"]) - delta
	if float(_pending["left"]) > 0.0:
		return
	var sid: StringName = _pending["id"]
	var target: Variant = _pending["target"]
	# The target may have died, hidden or drifted during the cast: re-check (a little range slack), nothing spent if not.
	if target_reason(sid, target) != "" or mana + 0.001 < mana_cost(sid) \
			or distance_to_target(target) > float(CasterKit.spell_value(sid, "range", 0.0)) + RELEASE_SLACK:
		_clear_pending()
		return
	_pending = {}
	if CLAIMED_SPELLS.has(sid):
		if sid == &"mana_scald" or sid == &"pollen_haze":
			CasterKit.release_claim(int(unit.team), sid, self)   # `scalded` / the haze mark it from now on
		else:
			CasterKit.claim(int(unit.team), sid, target, self, CasterKit.now_s() + _claim_after_release(sid))
	mana -= mana_cost(sid)
	_emit_mana(true)
	var ctx := {"xp": 0}
	match sid:
		&"slag_rain":
			_release_slag_rain(point_of(target) as Vector3, ctx)
		&"mana_scald":
			_release_mana_scald(target as Unit, ctx)
		&"rime_bulwark":
			_wall_facing = (target as Dictionary).get("facing", Vector3.ZERO) if target is Dictionary else Vector3.ZERO
			_release_bulwark(point_of(target) as Vector3)
		&"scrying_rune":
			_release_rune(point_of(target) as Vector3)
		&"snagroot":
			_release_snagroot(target as Unit, ctx)
		&"pollen_haze":
			_release_haze(point_of(target) as Vector3, ctx)
	_landed(sid, target)


func _landed(sid: StringName, target: Variant) -> void:
	casts[sid] = int(casts.get(sid, 0)) + 1
	last_spell = sid
	last_target = target
	last_cast_time = CasterKit.now_s()
	spell_cast.emit(sid)


## Spell XP (3.4), at most XP_MAX_PER_CAST per cast (`ctx` = that cast).
func _award(ctx: Dictionary, amount: int) -> void:
	var allowed := mini(amount, CasterKit.XP_MAX_PER_CAST - int(ctx.get("xp", 0)))
	if allowed <= 0 or unit == null or not unit.is_alive():
		return
	ctx["xp"] = int(ctx.get("xp", 0)) + allowed
	spell_xp += allowed
	unit.add_xp(allowed)


func _walk_toward(target: Variant) -> void:
	var p: Variant = point_of(target)
	if p == null:
		return
	unit.command_move(p as Vector3)


func _tick_approach() -> void:
	var sid: StringName = _approach["id"]
	var target: Variant = _approach["target"]
	if unit.order_serial != int(_approach.get("serial", -1)) or target_reason(sid, target) != "":
		_approach = {}   # another order, or the target is gone
		return
	var r := can_cast(sid, target)
	if r == "":
		_approach = {}
		unit.command_stop()
		_begin(sid, target)
		return
	if r != CasterKit.REASON_RANGE and r != CasterKit.REASON_RECHARGING and r != CasterKit.REASON_CANT:
		_approach = {}
		return
	_approach["repath"] = float(_approach.get("repath", 0.0)) - TICK
	if target is Unit and float(_approach["repath"]) <= 0.0:
		_approach["repath"] = APPROACH_REPATH
		_walk_toward(target)
		_approach["serial"] = unit.order_serial


# ---------------------------------------------------------------- Kilnwarden

func _release_slag_rain(point: Vector3, ctx: Dictionary) -> void:
	var r := float(CasterKit.spell_value(&"slag_rain", "radius", 3.0))
	_vfx(&"slag_rain", point, {"from": unit, "radius": r, "team": int(unit.team)})
	_slag_inflight.append(point)
	_after(float(CasterKit.spell_value(&"slag_rain", "flight", 0.6)), _slag_land, [point, ctx])


func _slag_land(point: Vector3, ctx: Dictionary) -> void:
	_slag_inflight.erase(point)
	if not is_inside_tree():
		return
	var s := CasterKit.spell(&"slag_rain")
	var src: Node3D = unit if is_instance_valid(unit) and unit.is_alive() else null
	var now := CasterKit.now_s()
	for key: Variant in _slagged.keys():
		if float(_slagged[key]) < now:
			_slagged.erase(key)
	for e in _enemies_near(point, float(s["radius"])):
		e.take_damage(float(s["damage"]), src)
		if not e.is_alive():
			continue
		var t := float(s["slag_big"]) if CasterKit.is_big_target(e) else float(s["slag"])
		e.apply_status(&"slagged", t, true)
		_slagged[e.get_instance_id()] = now + t
		_vfx(&"slagged", e, t)
		_award(ctx, CasterKit.XP_PER_HIT)


func _release_mana_scald(target: Unit, ctx: Dictionary) -> void:
	var s := CasterKit.spell(&"mana_scald")
	var burnt := CasterKit.burn_mana(target, float(s["burn"]))
	target.apply_status(&"scalded", float(s["scalded"]), true)
	if burnt > 0.0:
		target.take_damage(burnt, unit)
	_vfx(&"mana_scald", unit, target)
	_award(ctx, CasterKit.XP_PER_HIT)


# ---------------------------------------------------------------- Rimecarver

func _release_bulwark(point: Vector3) -> void:
	var s := CasterKit.spell(&"rime_bulwark")
	var facing := point - unit.global_position
	if _wall_facing != Vector3.ZERO:
		facing = _wall_facing
	var wall := RimeBulwark.spawn(_level(), point, facing, int(unit.team), s)
	CasterKit.register_bulwark(int(unit.team), wall)
	var alive := CasterKit.bulwarks_of(int(unit.team))
	while alive.size() > int(s["max"]):
		(alive[0] as RimeBulwark).finish(&"melt")   # max 4 per team: the oldest melts
		alive.remove_at(0)
	wall.play_rise(unit)


func _release_rune(point: Vector3) -> void:
	var s := CasterKit.spell(&"scrying_rune")
	var marker := SightMarker.spawn(int(unit.team), point, float(s["sight"]), float(s["time"]), _level())
	var r := CasterKit.register_rune(int(unit.team), point, float(s["sight"]), CasterKit.now_s() + float(s["time"]),
			unit, marker)
	_runes.append(r)
	_vfx(&"scrying_rune", point, {"team": int(unit.team), "time": float(s["time"]), "from": unit})
	var now := CasterKit.now_s()
	_runes = _runes.filter(func(x: Dictionary) -> bool: return float(x["until"]) > now)
	while _runes.size() > int(s["max"]):
		var old: Dictionary = _runes.pop_front()
		_vfx(&"scrying_rune_end", old["pos"])
		CasterKit.remove_rune(old)


## My living Scrying Runes (tests / UI).
func rune_count() -> int:
	var now := CasterKit.now_s()
	_runes = _runes.filter(func(x: Dictionary) -> bool: return float(x["until"]) > now)
	return _runes.size()


# ---------------------------------------------------------------- Bramblesage

func _release_snagroot(target: Unit, ctx: Dictionary) -> void:
	_vfx(&"snagroot", unit, target)
	_award(ctx, CasterKit.XP_PER_HIT)
	_after(float(CasterKit.spell_value(&"snagroot", "hit", 0.25)), _snag_hit, [weakref(target)])


func _snag_hit(ref: WeakRef) -> void:
	var target := ref.get_ref() as Unit
	if target == null or not target.is_alive() or unit == null or not is_instance_valid(unit):
		return
	var s := CasterKit.spell(&"snagroot")
	var big := CasterKit.is_big_target(target)
	var drag := float(s["drag_hero"]) if big else float(s["drag"])
	var from := unit.global_position
	var to := target.global_position
	var flat := Vector3(from.x - to.x, 0.0, from.z - to.z)
	var dist := flat.length()
	var keep := unit.radius + target.radius + 0.6
	var move := minf(drag, dist - keep)
	if move > 0.05:
		target.displace(to + flat.normalized() * move, float(s["drag_time"]))
	else:
		target.displaced.emit(target)   # no room to pull: still breaks its channel
	var root := float(s["root_hero"]) if big else float(s["root"])
	_after(float(s["drag_time"]), _snag_root, [ref, root])


func _snag_root(ref: WeakRef, seconds: float) -> void:
	var target := ref.get_ref() as Unit
	if target and target.is_alive():
		target.apply_status(&"rooted", seconds, true)


func _release_haze(point: Vector3, ctx: Dictionary) -> void:
	var s := CasterKit.spell(&"pollen_haze")
	var h := CasterHaze.spawn(_level(), point, int(unit.team), float(s["radius"]), float(s["time"]))
	h.tick = float(s["tick"])
	h.linger = float(s["linger"])
	h.unit_hazed.connect(func(_u: Unit) -> void: _award(ctx, CasterKit.XP_PER_HIT))
	_vfx(&"pollen_haze", point, {"radius": float(s["radius"]), "time": float(s["time"]), "team": int(unit.team)})


## Seedcloak (passive): the first drop under 50 % HP bursts a free 2.5 m haze on itself for 3 s, once per 45 s.
func _on_damage_taken(_amount: float, _attacker: Node3D) -> void:
	if passive_id() != &"seedcloak" or unit == null or not unit.is_alive():
		return
	var p: Dictionary = CasterKit.PASSIVES[&"seedcloak"]
	var below := unit.hp < unit.max_hp * float(p["hp_pct"])
	var now := CasterKit.now_s()
	if below and _above_half and now >= _seedcloak_at:
		_seedcloak_at = now + float(p["cooldown"])
		CasterHaze.spawn(_level(), unit.global_position, int(unit.team), float(p["radius"]), float(p["time"]), unit)
		unit.model_call(&"play_cast", [&"seedcloak"])
		_vfx(&"seedcloak", unit)
		casts[&"seedcloak"] = int(casts.get(&"seedcloak", 0)) + 1
	_above_half = not below


# ---------------------------------------------------------------- Gloom Deacon

func _start_tithe(ally: Unit) -> void:
	_channel = {"id": &"blood_tithe", "target": ally, "tick_left": 0.0, "healed": 0.0, "drained": {}, "ctx": {"xp": 0},
			"heal_xp": 0.0}
	unit.attacks_blocked = true
	if unit.model_has(&"set_channeling"):
		unit.model_call(&"set_channeling", [true])
	else:
		unit.model_call(&"play_cast", [&"blood_tithe"])
	ally.apply_status(&"tithed", 0.5, true)
	channel_changed.emit(&"blood_tithe", true)
	_landed(&"blood_tithe", ally)


func _tick_channel(delta: float) -> void:
	if _channel["id"] == &"umbral_passage":
		_tick_passage(delta)
		return
	_channel["tick_left"] = float(_channel["tick_left"]) - delta
	if float(_channel["tick_left"]) > 0.0:
		return
	var s := CasterKit.spell(&"blood_tithe")
	var step := float(s["tick"])
	_channel["tick_left"] = step
	var ally := tithe_target()
	var cost := float(s["per_second"]) * step
	if ally == null or not ally.is_alive() or not unit.can_act() or ally.hp >= ally.max_hp - 0.01 \
			or _flat(ally.global_position, unit.global_position) > float(s["break"]) or mana < 1.0:
		_end_tithe()
		return
	mana = maxf(0.0, mana - cost)
	var before := ally.hp
	ally.heal(float(s["heal"]) * step)
	ally.apply_status(&"tithed", 0.5, true)
	var ctx: Dictionary = _channel["ctx"]
	_channel["heal_xp"] = float(_channel["heal_xp"]) + (ally.hp - before)
	while float(_channel["heal_xp"]) >= CasterKit.XP_PER_HEAL:
		_channel["heal_xp"] = float(_channel["heal_xp"]) - CasterKit.XP_PER_HEAL
		_award(ctx, 1)
	_channel["healed"] = float(_channel["healed"]) + (ally.hp - before)
	var foe := _nearest_enemy_unit(ally.global_position, float(s["drain_radius"]))
	if foe:
		foe.take_damage(float(s["drain"]) * step, unit)
		var drained: Dictionary = _channel["drained"]
		if not drained.has(foe.get_instance_id()):
			drained[foe.get_instance_id()] = true
			_award(ctx, CasterKit.XP_PER_HIT)
	_vfx(&"blood_tithe", unit, {"to": ally, "drain": foe, "duration": step * 2.0})
	if unit.model_has(&"set_channeling"):
		unit.model_call(&"set_channeling", [true])


## HP the current tether healed so far (tests).
func tithe_healed() -> float:
	return float(_channel.get("healed", 0.0))


func _end_tithe() -> void:
	if _channel.get("id", &"") != &"blood_tithe":
		return
	var ally: Variant = _channel.get("target")
	_channel = {}
	if unit and is_instance_valid(unit):
		unit.attacks_blocked = false
		if unit.model_has(&"set_channeling"):
			unit.model_call(&"set_channeling", [false])
	_vfx(&"blood_tithe_end", unit, ally if is_instance_valid(ally) else null)
	channel_changed.emit(&"blood_tithe", false)


func _start_passage(point: Vector3) -> void:
	var s := CasterKit.spell(&"umbral_passage")
	unit.command_stop()
	unit.set_cast_lock(float(s["channel"]))   # it stands still (no chase, no attack) while the rifts open
	_channel = {"id": &"umbral_passage", "point": point, "left": float(s["channel"]), "from": unit.global_position,
			"serial": unit.order_serial}
	unit.model_call(&"play_cast", [&"umbral_passage"])
	_vfx(&"umbral_passage", point, {"deacon": unit, "duration": float(s["channel"])})
	channel_changed.emit(&"umbral_passage", true)


func _tick_passage(delta: float) -> void:
	if not unit.can_act() or unit.order_serial != int(_channel["serial"]) or unit.is_displaced() \
			or _flat(unit.global_position, _channel["from"]) > 0.5:
		_cancel_passage()
		return
	_channel["left"] = float(_channel["left"]) - delta
	if float(_channel["left"]) > 0.0:
		return
	var s := CasterKit.spell(&"umbral_passage")
	var point: Vector3 = _channel["point"]
	_channel = {}
	if mana + 0.001 < mana_cost(&"umbral_passage"):
		_cd[&"umbral_passage"] = float(s["cancel_cooldown"])
		_cd_total[&"umbral_passage"] = float(s["cancel_cooldown"])
		channel_changed.emit(&"umbral_passage", false)
		return
	mana -= mana_cost(&"umbral_passage")
	_emit_mana(true)
	_cd[&"umbral_passage"] = float(s["cooldown"])
	_cd_total[&"umbral_passage"] = float(s["cooldown"])
	var carried := passage_candidates(point)
	var ctx := {"xp": 0}
	var spots := _ring_spots(carried.size())
	for i in carried.size():
		var u: Unit = carried[i]
		_vfx(&"passage_step", u.global_position)
		u.global_position = Vector3(spots[i].x, u.global_position.y, spots[i].z)
		u.command_stop()
		_vfx(&"passage_step", u)
		_award(ctx, CasterKit.XP_PER_CARRY)
	casts[&"passage_units"] = int(casts.get(&"passage_units", 0)) + carried.size()
	channel_changed.emit(&"umbral_passage", false)
	_landed(&"umbral_passage", point)


## The own soldiers an Umbral Passage at `point` carries now: within 4 m, nearest first, up to 10 pop (not wizards,
## champions, helpers, workers, caravans, titans, not this Deacon).
func passage_candidates(point: Vector3) -> Array[Unit]:
	var s := CasterKit.spell(&"umbral_passage")
	var list: Array[Unit] = []
	for n in unit.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		# Own seat only (not the 2v2 ally rule): a Passage moves units, and an allied seat's army stays its own.
		if u == null or u == unit or not u.is_alive() or int(u.team) != int(unit.team) or u.unit_type == null:
			continue
		if u.is_worker() or u.unit_type.is_caravan or not u.is_commandable() or CasterKit.is_big_target(u):
			continue
		if _flat(u.global_position, point) > float(s["radius"]) + u.radius:
			continue
		list.append(u)
	list.sort_custom(func(a: Unit, b: Unit) -> bool: return _flat(a.global_position, point) < _flat(b.global_position, point))
	var out: Array[Unit] = []
	var pop := 0
	for u in list:
		if pop + u.unit_type.pop > int(s["max_pop"]):
			continue
		pop += u.unit_type.pop
		out.append(u)
	return out


# Free spots in rings around the Deacon (2.2 m, then 3.6 m...), snapped to the navmesh, never in water.
func _ring_spots(count: int) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var centre := unit.global_position
	var map := RID()
	var world := unit.get_world_3d()
	if world and world.navigation_map.is_valid() and NavigationServer3D.map_get_iteration_id(world.navigation_map) > 0:
		map = world.navigation_map
	var river := unit.get_tree().get_first_node_in_group(&"river")
	var ring := 0
	while out.size() < count and ring < 6:
		var r := 2.2 + 1.4 * ring
		var n := maxi(6, floori(TAU * r / 1.3))
		for i in n:
			if out.size() >= count:
				break
			var a := TAU * float(i) / float(n) + 0.3 * ring
			var p := centre + Vector3(cos(a), 0.0, sin(a)) * r
			if map.is_valid():
				var q := NavigationServer3D.map_get_closest_point(map, p)
				if Vector2(q.x - p.x, q.z - p.z).length() > 0.8:
					continue
				p = Vector3(q.x, centre.y, q.z)
			if river and river.has_method(&"is_water") and bool(river.call(&"is_water", p)):
				continue
			if CasterKit.bulwark_blocks(p, 0.5):
				continue
			out.append(p)
		ring += 1
	while out.size() < count:
		out.append(centre + Vector3(0.6 * out.size(), 0.0, 0.0))
	return out


func _cancel_passage() -> void:
	if _channel.get("id", &"") != &"umbral_passage":
		return
	_channel = {}
	if unit and is_instance_valid(unit):
		unit.clear_cast_lock()
	var cd := float(CasterKit.spell_value(&"umbral_passage", "cancel_cooldown", 5.0))
	_cd[&"umbral_passage"] = cd
	_cd_total[&"umbral_passage"] = cd
	casts[&"passage_cancelled"] = int(casts.get(&"passage_cancelled", 0)) + 1
	channel_changed.emit(&"umbral_passage", false)


## Seconds left of the running Umbral Passage (0 when none).
func passage_left() -> float:
	return float(_channel.get("left", 0.0)) if _channel.get("id", &"") == &"umbral_passage" else 0.0


# ---------------------------------------------------------------- passives: Stoke, Vigil

func _on_any_unit_died(victim: Variant) -> void:
	if unit == null or not is_instance_valid(unit) or not unit.is_alive() or not (victim is Unit):
		return
	var v := victim as Unit
	if v == unit:
		return
	var now := CasterKit.now_s()
	match passive_id():
		&"stoke":
			var key := v.get_instance_id()
			if _slagged.has(key):
				var slag_until := float(_slagged[key])
				_slagged.erase(key)
				if slag_until > now and now >= _stoke_at:
					_stoke_at = now + float(CasterKit.PASSIVES[&"stoke"]["every"])
					add_mana(float(CasterKit.PASSIVES[&"stoke"]["mana"]))
					_vfx(&"stoke", v, unit)
					casts[&"stoke"] = int(casts.get(&"stoke", 0)) + 1
		&"vigil":
			var p: Dictionary = CasterKit.PASSIVES[&"vigil"]
			if not Teams.is_allied_fast(int(v.team), int(unit.team)) or v.unit_type == null or v.is_worker() \
					or v is Wizard \
					or not v.can_gain_veterancy() or _flat(v.global_position, unit.global_position) > float(p["radius"]):
				return
			if now >= _vigil_at:
				_vigil_at = now + float(p["every"])
				add_mana(float(p["mana"]))
				_vfx(&"vigil", v, unit)
				casts[&"vigil"] = int(casts.get(&"vigil", 0)) + 1


# ---------------------------------------------------------------- autocast (section 5 rules)

func _autocast_check() -> void:
	if unit == null or not unit.is_alive() or not unit.can_act() or is_casting() or is_channelling() \
			or not _approach.is_empty() or unit.is_displaced():
		return
	if not (bot_controlled or lane_mode) and unit.has_move_order():
		return
	if _gcd > 0.0:
		return
	if bot_hard:
		_note_fight()
	for sid in spell_ids():
		if lane_mode:
			if sid == &"umbral_passage" or sid == &"scrying_rune":
				continue   # off in the lane (wave-strike.md 14.1)
		elif not (bot_controlled or autocast(sid)):
			continue
		elif bot_controlled and (sid == &"umbral_passage" or sid == &"rime_bulwark" or sid == &"scrying_rune"):
			continue   # AICasters' own rules (8.3)
		if cooldown_left(sid) > 0.0 or mana + 0.001 < mana_cost(sid):
			continue
		var target: Variant = autocast_target(sid)
		if target == null:
			continue
		if cast(sid, target) == "":
			return


## The target the section-5 autocast rule picks for `sid` now (null = the rule does not apply).
func autocast_target(sid: StringName) -> Variant:
	match sid:
		&"slag_rain":
			return _auto_slag_point()
		&"mana_scald":
			return _auto_scald_target()
		&"snagroot":
			return _auto_snag_target()
		&"pollen_haze":
			return _auto_haze_point()
		&"blood_tithe":
			return _auto_tithe_target()
		&"rime_bulwark":
			return dive_guard_spot()
		&"scrying_rune":
			return _auto_rune_point()
	return null


# Slag Rain: a point in range with >= 4 enemies within 3 m, or >= 2 with armour >= 10, or a titan; skipped when half
# of them are already slagged for more than 4 s.
func _auto_slag_point() -> Variant:
	var s := CasterKit.spell(&"slag_rain")
	var r := float(s["radius"])
	var rng := float(s["range"])
	# One scan of "units" per decision (code review M3): every unit within r (+ its radius) of a candidate in range is
	# within range + r of the caster, so the groups are counted from this list (O(E^2) on a small list, no new array).
	var enemies := _enemies_near(unit.global_position, rng + r)
	var info: Array = []   # per enemy: [armored, titan, slagged > 4 s]
	info.resize(enemies.size())
	for i in enemies.size():
		var g := enemies[i]
		info[i] = [g.get_stat(&"armor") >= 10.0, CasterKit.is_titan(g), g.status_time_left(&"slagged") > 4.0]
	var best: Variant = null
	var best_score := 0
	for e in enemies:
		if _flat(e.global_position, unit.global_position) > rng or not _team_sees(e.global_position):
			continue
		var count := 0
		var armored := 0
		var titan := false
		var slagged := 0
		for j in enemies.size():
			var g := enemies[j]
			if _flat(g.global_position, e.global_position) > r + g.radius:
				continue
			count += 1
			var gi: Array = info[j]
			if gi[0]:
				armored += 1
			if gi[1]:
				titan = true
			if gi[2]:
				slagged += 1
		if count < 4 and armored < 2 and not titan:
			continue
		var landing := false
		for q in _slag_inflight:
			if _flat(q, e.global_position) <= r:
				landing = true
		if landing or claimed_elsewhere(&"slag_rain", e.global_position):
			continue   # mine or a teammate's glob is already on its way there
		if slagged * 2 >= count:
			continue
		var score := count + armored + (3 if titan else 0)
		if score > best_score:
			best_score = score
			best = e.global_position
	return best


# Mana Scald: an enemy caster in range with >= 50 mana (most mana first), else the enemy wizard with >= 40.
func _auto_scald_target() -> Variant:
	var rng := float(CasterKit.spell_value(&"mana_scald", "range", 9.0))
	var best: Unit = null
	var best_mana := 49.999
	var wizard: Unit = null
	var now := CasterKit.now_s()
	for e in _enemies_near(unit.global_position, rng + 1.5):
		if distance_to_target(e) > rng or target_reason(&"mana_scald", e) != "" or claimed_elsewhere(&"mana_scald", e):
			continue
		var ab := CasterKit.ability_of(e)
		if ab:
			if ab.mana > best_mana:
				best_mana = ab.mana
				best = e
		elif e is Wizard and (e as Wizard).mana >= 40.0:
			wizard = e
	if best != null and bot_hard and wizard != null:
		# 8.3 hard: with the enemy wizard in range too, wait for the caster's next cast (or 1.5 s), then hit it.
		for k: Variant in _scald_wait.keys():   # stale waits (a target that left, a dead one) never carry over (review L2)
			if now - float(_scald_wait[k]) > 3.0:
				_scald_wait.erase(k)
		var key := best.get_instance_id()
		if not _scald_wait.has(key):
			_scald_wait[key] = now
		var ab := CasterKit.ability_of(best)
		if ab.last_cast_time < float(_scald_wait[key]) and now - float(_scald_wait[key]) < 1.5:
			return null
		_scald_wait.erase(key)
	return best if best != null else wizard


# Snagroot: an enemy caster -> siege (Ash Hurler, Frost Mortar, Cinder Arbalest) -> the enemy wizard under 50 % HP when
# >= 3 own soldiers stand within 6 m. Never a unit already within 4 m.
func _auto_snag_target() -> Variant:
	var rng := float(CasterKit.spell_value(&"snagroot", "range", 9.0))
	var caster: Unit = null
	var siege: Unit = null
	var wizard: Unit = null
	for e in _enemies_near(unit.global_position, rng + 1.5):
		if distance_to_target(e) > rng or _flat(e.global_position, unit.global_position) <= 4.0:
			continue
		if target_reason(&"snagroot", e) != "" or claimed_elsewhere(&"snagroot", e):
			continue
		if CasterKit.is_caster_unit(e):
			caster = e
		elif e.unit_type and SIEGE_IDS.has(e.unit_type.id):
			siege = e
		elif e is Wizard and e.hp < e.max_hp * 0.5:
			wizard = e
	if caster:
		return caster
	if siege:
		return siege
	if wizard and _own_soldiers_near(unit.global_position, 6.0) >= 3:
		return wizard
	return null


# Pollen Haze: >= 4 enemy ranged ground units (range > 3) within 3.5 m of a point in range (hard bot, first 5 s of a
# fight: >= 5). Never on a point one of our hazes already covers.
func _auto_haze_point() -> Variant:
	var s := CasterKit.spell(&"pollen_haze")
	var r := float(s["radius"])
	var rng := float(s["range"])
	var need := 4
	if bot_hard and _fight_since > -INF and CasterKit.now_s() - _fight_since < 5.0:
		need = 5
	var ranged: Array[Unit] = []
	for e in _enemies_near(unit.global_position, rng + r):
		if e.attack_range > 3.0 and not HelperAbilities.is_flyer(e) and not e.has_status(&"hazed"):
			ranged.append(e)
	if ranged.size() < need:
		return null
	var best: Variant = null
	var best_n := need - 1
	for e in ranged:
		if _flat(e.global_position, unit.global_position) > rng or not _team_sees(e.global_position):
			continue
		var n := 0
		for o in ranged:
			if _flat(o.global_position, e.global_position) <= r:
				n += 1
		if n > best_n and not _haze_covers(e.global_position) and not claimed_elsewhere(&"pollen_haze", e.global_position):
			best_n = n
			best = e.global_position
	return best


# Blood Tithe: the own non-worker unit within 7 m with the lowest HP % under 85 % (a wizard / champion / helper first
# when under 50 %).
func _auto_tithe_target() -> Variant:
	var rng := float(CasterKit.spell_value(&"blood_tithe", "range", 7.0))
	var max_tethers := int(CasterKit.spell_value(&"blood_tithe", "max_tethers", 2))
	var best: Unit = null
	var best_score := INF
	# The team's tethers, counted once per decision from the same "units" scan (target_reason's tethers_on() rescans
	# every unit for each candidate: code review M3).
	var tethers := {}   # ally instance id -> tethers on it
	var candidates: Array[Unit] = []
	for n in unit.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or not u.is_alive() or not Teams.is_allied_fast(int(u.team), int(unit.team)):
			continue
		if u.unit_type != null and u.unit_type.id == &"gloom_deacon":
			var ab := CasterKit.ability_of(u)
			var t := ab.tithe_target() if ab else null
			if t != null:
				tethers[t.get_instance_id()] = int(tethers.get(t.get_instance_id(), 0)) + 1
		if u == unit or u.is_worker():
			continue
		if u.unit_type != null and (u.unit_type.is_caravan or u.unit_type.lifetime > 0.0):
			continue
		if distance_to_target(u) > rng:
			continue
		candidates.append(u)
	for u in candidates:
		var pct := u.hp / maxf(1.0, u.max_hp)
		if pct >= 0.85 or u.hp >= u.max_hp - 0.01 or not u.is_inside_tree() \
				or int(tethers.get(u.get_instance_id(), 0)) >= max_tethers:
			continue   # = target_reason(&"blood_tithe", u) without its per-candidate scan
		var score := pct
		if CasterKit.is_big_target(u) and pct < 0.5:
			score -= 1.0
		if score < best_score:
			best_score = score
			best = u
	return best


## Rime Bulwark dive guard (8.3 a, also the player's autocast when turned on): an enemy melee or mounted unit within 9 m
## whose target is an own ranged unit, caster or the wizard, 3-9 m from it -> a wall 2.5 m in front of the victim,
## across the diver's approach. The wall centre (Vector3), or null.
func dive_guard_spot() -> Variant:
	var rng := float(CasterKit.spell_value(&"rime_bulwark", "range", 10.0))
	for e in _enemies_near(unit.global_position, rng + 9.0):
		if e.attack_range > 3.0:
			continue
		if not is_instance_valid(e.attack_target):
			continue   # none, or freed this frame (casting a freed object is a script error)
		var v := e.attack_target as Unit
		if v == null or not v.is_alive() or not Teams.is_allied_fast(int(v.team), int(unit.team)):
			continue
		if not (v.attack_range > 3.0 or CasterKit.is_caster_unit(v) or v is Wizard):
			continue
		var d := _flat(e.global_position, v.global_position)
		if d < 3.0 or d > 9.0 or _flat(v.global_position, unit.global_position) > 9.0 + rng:
			continue
		var dir := Vector3(e.global_position.x - v.global_position.x, 0.0, e.global_position.z - v.global_position.z)
		var spot := v.global_position + dir.normalized() * 2.5
		spot.y = 0.0
		if _flat(spot, unit.global_position) > rng or not _team_sees(spot) or not _wall_spot_ok(spot):
			continue
		return {"at": spot, "facing": -dir}   # the wall lies across the diver's line
	return null


# Scrying Rune (autocast when the player turns it on): an own unit hit in the last second by an unseen attacker, or
# an enemy near that is veiled / disguised -> a rune on it.
func _auto_rune_point() -> Variant:
	var rng := float(CasterKit.spell_value(&"scrying_rune", "range", 12.0))
	for n in unit.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or not u.is_alive() or _flat(u.global_position, unit.global_position) > rng:
			continue
		if unit.is_enemy_of(u) and (u.is_hidden_from_auto_target() or u.is_disguised_for(int(unit.team))) \
				and not CasterKit.revealed_for(u):
			return u.global_position
	return null


func _note_fight() -> void:
	if _enemies_near(unit.global_position, 12.0).is_empty():
		_fight_since = -INF
	elif _fight_since == -INF:
		_fight_since = CasterKit.now_s()


# ---------------------------------------------------------------- levels (3.4)

func _on_level_changed(_u: Unit, lvl: int) -> void:
	var steps := float(maxi(0, lvl - 1))
	# Casters grow in HP and mana, never in damage: the veterancy modifier keeps only its HP part.
	unit.add_modifier(Unit.VETERANCY_MODIFIER, {&"max_hp_pct": Unit.VETERANCY_BONUS * steps})
	unit.add_modifier(LEVEL_MODIFIER, {&"max_mana": CasterKit.LEVEL_MANA * steps,
			&"mana_regen": CasterKit.LEVEL_REGEN * steps})
	_emit_mana(true)


func _on_displaced(_u: Unit) -> void:
	_clear_pending()
	_approach = {}
	if not _channel.is_empty():
		stop_channel()


func _on_died(_u: Unit) -> void:
	_clear_pending()
	_approach = {}
	if not _channel.is_empty():
		stop_channel()
	if _mana_bar:
		_mana_bar.visible = false


# ---------------------------------------------------------------- world mana bar (under the HP bar)

func _build_mana_bar() -> void:
	if _mana_shader == null:
		_mana_shader = Shader.new()
		_mana_shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, depth_test_disabled, shadows_disabled;
uniform float fill = 1.0;
uniform vec4 fill_color : source_color = vec4(0.35, 0.55, 1.0, 1.0);
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
	bool border = UV.y < 0.2 || UV.y > 0.8 || UV.x < 0.02 || UV.x > 0.98;
	vec4 c = border ? vec4(0.0, 0.0, 0.0, 1.0) : (UV.x < fill ? fill_color : vec4(0.08, 0.08, 0.1, 0.85));
	ALBEDO = c.rgb;
	ALPHA = c.a;
}
"""
	_mana_mat = ShaderMaterial.new()
	_mana_mat.shader = _mana_shader
	_mana_mat.set_shader_parameter("fill_color", MANA_COLOR)
	_mana_bar = MeshInstance3D.new()
	_mana_bar.name = "ManaBar"
	var quad := QuadMesh.new()
	quad.size = Vector2(maxf(1.0, unit.radius * 2.6), MANA_BAR_HEIGHT)
	_mana_bar.mesh = quad
	_mana_bar.material_override = _mana_mat
	_mana_bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mana_bar.position.y = unit.body_height + 0.5 - Unit.HP_BAR_HEIGHT * 0.5 - MANA_BAR_HEIGHT * 0.5 - 0.01
	_mana_bar.visible = false
	unit.add_child.call_deferred(_mana_bar)


func _update_mana_bar() -> void:
	if _mana_bar == null or not _mana_bar.is_inside_tree():
		return
	var hp_bar := unit.get_node_or_null(^"HPBar") as Node3D
	_mana_bar.visible = unit.is_alive() and (unit.selected or (hp_bar != null and hp_bar.visible))
	_mana_mat.set_shader_parameter("fill", clampf(mana / maxf(1.0, max_mana()), 0.0, 1.0))


# ---------------------------------------------------------------- helpers

func _vfx(effect: StringName, at: Variant, target: Variant = null) -> void:
	if not is_inside_tree():
		return
	var vfx := get_tree().get_first_node_in_group(&"unit_vfx")
	if vfx:
		vfx.call(&"play", effect, at, target)


func _level() -> Node:
	var tree := get_tree()
	return tree.current_scene if tree.current_scene else unit.get_parent()


## A point target may be a Vector3, a Node3D (its position) or {at: Vector3, facing: Vector3} (a Bulwark laid across
## `facing` instead of the caster -> point line).
static func point_of(target: Variant) -> Variant:
	if target is Vector3:
		return target
	if target is Dictionary and (target as Dictionary).get("at") is Vector3:
		return (target as Dictionary)["at"]
	if target is Node3D and is_instance_valid(target):
		return (target as Node3D).global_position
	return null


func _team_sees(p: Vector3) -> bool:
	var fog := FogOfWar.find()
	return fog == null or fog.is_visible(int(unit.team), p)


# Not on water, not on a building (5.2).
func _wall_spot_ok(p: Vector3) -> bool:
	var river := get_tree().get_first_node_in_group(&"river") if is_inside_tree() else null
	if river and river.has_method(&"is_water") and bool(river.call(&"is_water", p)):
		return false
	for n in get_tree().get_nodes_in_group(&"buildings"):
		var b := n as Node3D
		if b == null or not b.has_method(&"is_alive") or not bool(b.call(&"is_alive")):
			continue
		if _flat(b.global_position, p) < Unit.radius_of(b) + 0.5:
			return false
	return true


func _haze_covers(p: Vector3) -> bool:
	for h in get_tree().get_nodes_in_group(&"pollen_hazes"):
		var hz := h as CasterHaze
		if hz and hz.team == int(unit.team) and hz.time_left() > 1.0 and hz.covers(p):
			return true
	return false


func _enemies_near(at: Vector3, r: float) -> Array[Unit]:
	var out: Array[Unit] = []
	for n in unit.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or not u.is_alive() or not unit.is_enemy_of(u):
			continue
		if _flat(u.global_position, at) <= r + u.radius:
			out.append(u)
	return out


func _nearest_enemy_unit(at: Vector3, r: float) -> Unit:
	var best: Unit = null
	var bd := INF
	for e in _enemies_near(at, r):
		var d := _flat(e.global_position, at)
		if d < bd:
			bd = d
			best = e
	return best


func _own_soldiers_near(at: Vector3, r: float) -> int:
	var n := 0
	for node in unit.get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u and u != unit and u.is_alive() and Teams.is_allied_fast(int(u.team), int(unit.team)) and not u.is_worker() \
				and u.can_gain_veterancy() and _flat(u.global_position, at) <= r:
			n += 1
	return n


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
