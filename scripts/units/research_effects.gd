class_name ResearchEffects
extends RefCounted
## The H kinds of unit research (docs/design/unit-upgrades.md 10, tasks UR.G1 / UR.G2). Everything is static.
## UnitResearch.apply_to(u) calls on_applied(u) whenever the rows on a unit change (completion, a new unit, a load):
## it sorts the unit's H effects into `Unit.research_hit_fx` (attacker side) and `Unit.research_hurt_fx` (victim side)
## and sets up the passive ones (pack aura, idle regen). Unit only calls the hooks while those arrays are not empty, so
## a unit without research pays one is_empty() per hit.
## Hit path (Unit._on_attack_hit): pre_hit (bonus_vs_status, read before any on-hit status lands), on_hit
## (on_hit_status, every_nth, first_hit, bonus damage, splash, dot, kill_status).
## Damage path (Unit.take_damage): before_damage (combat_shield), after_damage (thorns, low_hp_status).
## Runtime state lives in `_` metas (never saved): `_rs_nth`, `_rs_first_hit`, `_rs_thorns`, `_rs_cd_<kind>`
## (absolute CasterKit.now_s() times), `_rs_idle_regen`.

const HIT_KINDS: Array[StringName] = [&"on_hit_status", &"every_nth", &"first_hit", &"bonus_vs_status", &"splash",
		&"dot", &"kill_status"]
const HURT_KINDS: Array[StringName] = [&"thorns", &"combat_shield", &"low_hp_status"]

const NTH_META := &"_rs_nth"
const FIRST_HIT_META := &"_rs_first_hit"
const THORNS_META := &"_rs_thorns"
const CD_FIRST_HIT := &"_rs_cd_first_hit"
const CD_COMBAT_SHIELD := &"_rs_cd_combat_shield"
const CD_LOW_HP := &"_rs_cd_low_hp_status"
const IDLE_REGEN_META := &"_rs_idle_regen"

const FIRST_HIT_MEMORY := 6.0     # a target hit in the last 6 s is not "fresh"
const FIRST_HIT_COOLDOWN := 4.0   # at most one first-hit bonus per 4 s per unit
const THORNS_RANGE := 3.5
const THORNS_MAX_ATTACK_RANGE := 2.5
const THORNS_PER_ATTACKER := 0.5
const MEMORY_PRUNE_AT := 24       # entries before old ones are pruned (rare)
const DOT_INTERVAL := 0.5
const PACK_AURA_ID := &"research_pack_hunger"
const SPLASH_MAX_RESULTS := 32
const UNITS_LAYER := 2

static var _splash_query: PhysicsShapeQueryParameters3D = null
static var _splash_shape: SphereShape3D = null


# ---------------------------------------------------------------- apply (UnitResearch.apply_to)

## The unit's rows changed: cache its H effects and set up the passive kinds (pack_aura, idle_regen).
static func on_applied(u: Unit) -> void:
	if u == null or not is_instance_valid(u):
		return
	var hit: Array[Dictionary] = []
	var hurt: Array[Dictionary] = []
	var pack: Dictionary = {}
	var regen: Dictionary = {}
	for e in UnitResearch.effects_of(u):
		var kind := StringName(e.get("kind", &""))
		if HIT_KINDS.has(kind):
			hit.append(e)
		elif HURT_KINDS.has(kind):
			hurt.append(e)
		elif kind == &"pack_aura":
			pack = e
		elif kind == &"idle_regen":
			regen = e
	u.research_hit_fx = hit
	u.research_hurt_fx = hurt
	for e in hit:
		if e["kind"] == &"first_hit" and not u.has_meta(FIRST_HIT_META):
			u.set_meta(FIRST_HIT_META, {})
	for e in hurt:
		if e["kind"] == &"thorns" and not u.has_meta(THORNS_META):
			u.set_meta(THORNS_META, {})
	# pack_aura: every carrier gives the others of its type within radius the stats (one source wins per id).
	if not pack.is_empty():
		var me_id: StringName = u.unit_type.id
		var me := u
		u.apply_aura(PACK_AURA_ID, float(pack.get("radius", 5.0)), pack.get("stats", {}),
				func(r: Unit) -> bool: return r != me and r.unit_type != null and r.unit_type.id == me_id and r.is_alive())
	elif u.has_aura(PACK_AURA_ID):
		u.remove_aura(PACK_AURA_ID)
	# idle_regen: the row's fraction per second -> Unit's percent; back to the type's value when the row goes.
	if not regen.is_empty():
		u.set_meta(IDLE_REGEN_META, true)
		u.set_idle_regen_pct(maxf(u.get_idle_regen_pct(), float(regen.get("pct", 0.0)) * 100.0))
	elif u.has_meta(IDLE_REGEN_META):
		u.remove_meta(IDLE_REGEN_META)
		u.set_idle_regen_pct(u.unit_type.idle_regen_pct if u.unit_type else 0.0)


# ---------------------------------------------------------------- hit path (attacker side)

## Before the hit's on-hit statuses land: the bonus damage of bonus_vs_status (0 = none).
static func pre_hit(u: Unit, target: Node3D) -> float:
	if target == null or not is_instance_valid(target):
		return 0.0
	var victim := target as Unit
	if victim == null or not victim.is_alive():
		return 0.0
	for e in u.research_hit_fx:
		if e["kind"] != &"bonus_vs_status":
			continue
		for s: StringName in e["statuses"]:
			if victim.has_status(s):
				return u.attack_damage * float(e["pct"])
	return 0.0


## After a landed hit (`dealt` = what it really took off): the hit kinds in table order, then kill_status.
static func on_hit(u: Unit, target: Node3D, dealt: float, bonus: float) -> void:
	if target == null or not is_instance_valid(target) or not is_instance_valid(u):
		return
	var victim := target as Unit
	var src: Node3D = u if is_instance_valid(u) else null
	if bonus > 0.0 and victim and victim.is_alive():
		victim.take_damage(bonus, src)
	var kill_i := -1
	var i := -1
	for e in u.research_hit_fx:
		i += 1
		match e["kind"]:
			&"on_hit_status":
				if victim and victim.is_alive():
					victim.apply_status(e["status"], float(e["seconds"]))
			&"every_nth":
				if victim and victim.is_alive():
					var n := maxi(1, int(e["n"]))
					var c := int(u.get_meta(NTH_META, 0)) + 1
					if c >= n:
						c = 0
						victim.apply_status(e["status"], float(e["seconds"]))
					u.set_meta(NTH_META, c)
			&"first_hit":
				_first_hit(u, target, victim, e)
			&"splash":
				if dealt > 0.0:
					_splash(u, target, dealt * float(e["ratio"]), float(e["radius"]))
			&"dot":
				if victim and victim.is_alive():
					victim.apply_dot(e["id"], float(e["dps"]) * DOT_INTERVAL, DOT_INTERVAL, float(e["seconds"]), src)
			&"kill_status":
				kill_i = i
	if kill_i >= 0 and victim and not victim.is_alive() and u.is_alive():
		var k: Dictionary = u.research_hit_fx[kill_i]
		u.apply_status(k["status"], float(k["seconds"]))


static func _first_hit(u: Unit, target: Node3D, victim: Unit, e: Dictionary) -> void:
	if not u.has_meta(FIRST_HIT_META):   # set by on_applied
		return
	var memory: Dictionary = u.get_meta(FIRST_HIT_META)
	var now := CasterKit.now_s()
	var key := target.get_instance_id()
	var last := float(memory.get(key, -INF))
	memory[key] = now
	if memory.size() > MEMORY_PRUNE_AT:
		_prune(memory, now - FIRST_HIT_MEMORY)
	if now - last < FIRST_HIT_MEMORY or now < float(u.get_meta(CD_FIRST_HIT, -INF)):
		return
	if not _target_alive(target):
		return
	u.set_meta(CD_FIRST_HIT, now + FIRST_HIT_COOLDOWN)
	target.call(&"take_damage", float(e["damage"]), u if is_instance_valid(u) else null)
	if victim and victim.is_alive() and e.has("status"):
		victim.apply_status(e["status"], float(e.get("seconds", 0.0)))


## ratio x dealt to every other enemy Unit within radius of the target (no buildings, no further on-hit).
static func _splash(u: Unit, target: Node3D, amount: float, radius: float) -> void:
	if amount <= 0.0 or not target.is_inside_tree():
		return
	var world := target.get_world_3d()
	if world == null:
		return
	if _splash_query == null:
		_splash_shape = SphereShape3D.new()
		_splash_query = PhysicsShapeQueryParameters3D.new()
		_splash_query.shape = _splash_shape
		_splash_query.collision_mask = UNITS_LAYER
		_splash_query.collide_with_areas = false
	_splash_shape.radius = radius + 1.0   # bodies are checked against radius + their own radius below
	var at := target.global_position
	_splash_query.transform = Transform3D(Basis.IDENTITY, at)
	var hits := world.direct_space_state.intersect_shape(_splash_query, SPLASH_MAX_RESULTS)
	var src: Node3D = u if is_instance_valid(u) else null
	for h: Dictionary in hits:
		var other := h["collider"] as Unit
		if other == null or other == target or not other.is_alive() or not u.is_enemy_of(other):
			continue
		var dx := other.global_position.x - at.x
		var dz := other.global_position.z - at.z
		var r := radius + other.radius
		if dx * dx + dz * dz <= r * r:
			other.take_damage(amount, src)


# ---------------------------------------------------------------- damage path (victim side)

## Top of take_damage (before the shield absorbs): combat_shield.
static func before_damage(u: Unit, amount: float) -> void:
	if amount <= 0.0:
		return
	for e in u.research_hurt_fx:
		if e["kind"] != &"combat_shield":
			continue
		if u.seconds_since_damage() < float(e["idle"]):
			continue
		# Never replace a shield as large or larger (Snow Shield, Vow, Rime Aegis, items; R3-2): no shield, no cooldown.
		if u.shield >= float(e["amount"]):
			continue
		var now := CasterKit.now_s()
		if now < float(u.get_meta(CD_COMBAT_SHIELD, -INF)):
			continue
		u.set_meta(CD_COMBAT_SHIELD, now + float(e["cooldown"]))
		u.add_shield(float(e["amount"]), float(e["seconds"]))


## After HP went down (the unit may be dead): thorns, low_hp_status.
static func after_damage(u: Unit, attacker: Node3D) -> void:
	for e in u.research_hurt_fx:
		match e["kind"]:
			&"thorns":
				_thorns(u, attacker, float(e["damage"]))
			&"low_hp_status":
				if u.is_alive() and u.hp < float(e["pct"]) * u.max_hp:
					var now := CasterKit.now_s()
					if now >= float(u.get_meta(CD_LOW_HP, -INF)):
						u.set_meta(CD_LOW_HP, now + float(e["cooldown"]))
						u.apply_status(e["status"], float(e["seconds"]), true)


## A melee strike (Unit.melee_strike_active) of an enemy Unit with attack_range <= 2.5 within 3.5 m: it takes
## `damage` (armor applies), once per attacker per 0.5 s. Buildings, spells and DoT ticks never trigger it.
static func _thorns(u: Unit, attacker: Node3D, damage: float) -> void:
	if attacker == null or not is_instance_valid(attacker):
		return
	var a := attacker as Unit
	if a == null or not a.is_alive() or not a.melee_strike_active:
		return
	if a.attack_range > THORNS_MAX_ATTACK_RANGE or not u.is_enemy_of(a):
		return
	var dx := a.global_position.x - u.global_position.x
	var dz := a.global_position.z - u.global_position.z
	if dx * dx + dz * dz > THORNS_RANGE * THORNS_RANGE:
		return
	if not u.has_meta(THORNS_META):   # set by on_applied
		return
	var memory: Dictionary = u.get_meta(THORNS_META)
	var now := CasterKit.now_s()
	var key := a.get_instance_id()
	if now - float(memory.get(key, -INF)) < THORNS_PER_ATTACKER:
		return
	memory[key] = now
	if memory.size() > MEMORY_PRUNE_AT:
		_prune(memory, now - THORNS_PER_ATTACKER)
	a.take_damage(damage, u)


# ---------------------------------------------------------------- helpers

static func _prune(memory: Dictionary, older_than: float) -> void:
	for k: Variant in memory.keys():
		if float(memory[k]) < older_than:
			memory.erase(k)


static func _target_alive(target: Node3D) -> bool:
	return is_instance_valid(target) and target.has_method(&"is_alive") and bool(target.call(&"is_alive"))
