class_name HelperAbilities
extends Node
## The 3 abilities + passive + Bond of a tier-3 helper (docs/design/t3-helpers.md section 4). Child "HelperAbilities"
## of a Helper. Autocast every 0.5 s on the section-4 rules; `cast(id, target)` casts now (tests, story scripts).
## Amounts x helper.ability_factor(). Ability 3 (signature) needs level HelperType.signature_level (5).
## Refusals of cast(): "Dead", "Frozen", "Unknown ability", "Requires level 5", "On cooldown", "No target".

signal ability_cast(id: StringName)

const TICK := 0.5
const COOLDOWNS := {
	&"vey_lunge": 12.0, &"vey_chain": 10.0, &"vey_stormcall": 70.0,
	&"hush_blink": 10.0, &"hush_smoke": 22.0, &"hush_knives": 75.0,
	&"aldra_shatter": 11.0, &"aldra_aegis": 20.0, &"aldra_sentinel": 90.0,
	&"thornsnare": 14.0, &"call_the_pack": 28.0, &"wild_stampede": 50.0,
}
# Old Vey
const STORM_SWORN_EVERY := 3
const STORM_SWORN := {"radius": 5.0, "targets": 2, "ratio": 0.5}
const SPARK_FIRST := {"radius": 14.0, "cut": 2.0, "every": 2.0}
const LUNGE := {"range": 10.0, "damage": 60.0, "path_damage": 30.0, "path_width": 1.5, "daze": 0.5}
const CHAIN := {"range": 8.0, "jump": 8.0, "min_count": 3, "damage": [45.0, 38.0, 32.0, 27.0, 23.0]}
const STORMCALL := {"radius": 12.0, "min_count": 6, "big_radius": 8.0, "bolts": 8, "time": 3.0, "damage": 50.0,
		"haste_pct": -0.15, "haste_time": 6.0}
const STORMCALL_MOD := &"ability:vey_stormcall"
# Mother Hush
const VEIL := {"idle": 4.0, "near": 5.0, "bonus": 0.6}
const HUSH_BOND := {"time": 4.0, "bonus": 0.15}
const BLINK := {"range": 14.0, "delay": 0.5, "damage": 55.0}
const SMOKE := {"hp_pct": 0.5, "min_targeting": 3, "shroud": 3.0}
const KNIVES := {"radius": 10.0, "min_count": 4, "wizard_pct": 0.4, "vanish": 1.5, "strikes": 6, "gap": 0.25,
		"damage": 40.0, "hero_mult": 1.5, "mark": 4.0}
# Aldra Stillwater
const WARD := {"radius": 8.0, "cut": 0.12}
const ALDRA_BOND := {"radius": 12.0, "chill": 1.5}   # the +34 frost of the spec: chill (no Frostbite meter in the game)
const SHATTER := {"length": 12.0, "width": 1.5, "min_count": 3, "max": 6, "damage": 50.0, "chill": 1.5}
const AEGIS := {"radius": 10.0, "hp_pct": 0.5, "min_count": 2, "count": 4, "shield": 100.0, "time": 6.0}
const SENTINEL := {"radius": 12.0, "min_count": 5, "reach": 10.0, "life": 30.0, "unit": "rime_colossus"}
# Maelis Oakenhollow
const OPINIONS := {"radius": 12.0, "attack_cooldown_pct": -0.1667, "move_speed": 1.0}
const MAELIS_BOND := {"time": 3.0, "bonus": 0.2}
const THORNSNARE := {"range": 10.0, "radius": 2.5, "min_count": 2, "delay": 0.6, "damage": 20.0, "root": 1.2}
const PACK := {"range": 12.0, "count": 2, "life": 20.0, "unit": "spirit_wolf"}
const STAMPEDE := {"length": 16.0, "width": 1.5, "min_count": 3, "max": 8, "damage": 45.0, "push": 1.5, "daze": 0.5}
const PACK_IDS: Array[StringName] = [&"spirit_wolf", &"sapling"]
const FLYER_IDS: Array[StringName] = [&"briar_roc", &"stormcrest_roc", &"duskwing_roc"]
const META_HUSH_BOND := &"t3_hush_bond_until"
const META_MAELIS_BOND := &"t3_maelis_bond_until"

var helper: Helper
var casts := {}                 ## id -> times cast (tests, logs).
var passive_procs := 0          ## Storm-Sworn chains, veil strikes, ward saves (tests).
var veiled := false             ## Hush: read by the UI / tests.
var sentinel: Unit = null       ## Aldra's living Sentinel (max 1).
var wolves: Array[Unit] = []

var _cd := {}                   # id -> seconds left
var _tick_left := TICK
var _strikes := 0
var _spark_ready_at := 0.0
var _since_action := 0.0
var _ward_watch := {}           # Unit instance id -> true (damage_taken connected)
var _wizard: Unit = null


func setup(h: Helper) -> void:
	helper = h
	for id in ability_ids():
		_cd[id] = 0.0
	helper.attack_landed.connect(_on_attack_landed)
	helper.damage_taken.connect(_on_damage_taken)
	if passive_id() == &"maelis_opinions":
		helper.apply_aura(&"maelis_opinions", float(OPINIONS["radius"]),
				{&"attack_cooldown_pct": float(OPINIONS["attack_cooldown_pct"]), &"move_speed": float(OPINIONS["move_speed"])},
				func(u: Unit) -> bool: return u.unit_type != null and PACK_IDS.has(u.unit_type.id))
	_tick_left = TICK * float(get_instance_id() % 5) / 5.0


func ability_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	if helper and helper.helper_type:
		out.assign(helper.helper_type.ability_ids)
	return out


func passive_id() -> StringName:
	return helper.helper_type.passive_id if helper and helper.helper_type else &""


func cooldown_left(id: StringName) -> float:
	return maxf(0.0, float(_cd.get(id, 0.0)))


func cooldown_total(id: StringName) -> float:
	return float(COOLDOWNS.get(id, 0.0))


func reset_cooldowns() -> void:
	for id in _cd:
		_cd[id] = 0.0


## "" when ability `id` could be cast now (target aside), else the refusal.
func can_cast(id: StringName) -> String:
	if helper == null or not helper.is_alive():
		return "Dead"
	if not helper.can_act():
		return "Frozen"
	var ids := ability_ids()
	if not ids.has(id):
		return "Unknown ability"
	if ids.find(id) == 2 and helper.level < helper.helper_type.signature_level:
		return "Requires level %d" % helper.helper_type.signature_level
	if cooldown_left(id) > 0.0:
		return "On cooldown"
	return ""


## Casts `id` now at `target` (a Node3D, a Vector3 or null = pick like the autocast). "" = cast.
func cast(id: StringName, target: Variant = null) -> String:
	var reason := can_cast(id)
	if reason != "":
		return reason
	if not _do(id, target):
		return "No target"
	_cd[id] = cooldown_total(id)
	casts[id] = int(casts.get(id, 0)) + 1
	_since_action = 0.0
	if helper.model_has(&"play_cast"):
		helper.model_call(&"play_cast", [id])
	var vfx := helper.get_tree().get_first_node_in_group(&"helper_vfx") if helper.is_inside_tree() else null
	if vfx and vfx.has_method(&"play"):
		vfx.call(&"play", id, helper, target if target is Node3D else null)
	ability_cast.emit(id)
	return ""


## The wizard of the Bond passive (its spell hits feed the passive).
func bind_wizard(w: Unit) -> void:
	if _wizard and is_instance_valid(_wizard) and _wizard.has_signal(&"spell_hit") \
			and _wizard.is_connected(&"spell_hit", _on_wizard_spell_hit):
		_wizard.disconnect(&"spell_hit", _on_wizard_spell_hit)
	_wizard = w
	if w and w.has_signal(&"spell_hit"):
		w.connect(&"spell_hit", _on_wizard_spell_hit)


# ---------------------------------------------------------------- tick

func _physics_process(delta: float) -> void:
	if helper == null or not helper.is_alive():
		return
	for id in _cd:
		if _cd[id] > 0.0:
			_cd[id] = float(_cd[id]) - delta
	_since_action += delta
	_tick_left -= delta
	if _tick_left > 0.0:
		return
	_tick_left += TICK
	_passive_tick()
	if not helper.can_act():
		return
	for id in ability_ids():
		if can_cast(id) == "" and _wants(id):
			cast(id)
			break   # one cast per tick


func _passive_tick() -> void:
	_model_tells()
	match passive_id():
		&"hush_veil":
			var near := not _enemies_near(helper.global_position, float(VEIL["near"])).is_empty()
			veiled = _since_action >= float(VEIL["idle"]) and not near
			if veiled:
				helper.hide_from_auto_target(TICK + 0.15)
		&"aldra_ward":
			for u in _allies_near(helper.global_position, float(WARD["radius"])):
				var key := u.get_instance_id()
				if not _ward_watch.has(key):
					_ward_watch[key] = true
					u.damage_taken.connect(_on_ward_hit.bind(u))


# Model tells (helper_model.gd hooks): set_status(&"veiled", on) for Hush's veil, set_charge(0..1) = signature readiness.
var _veil_shown := false
var _charge_shown := -1.0


func _model_tells() -> void:
	if helper.model_has(&"set_status") and veiled != _veil_shown:
		_veil_shown = veiled
		helper.model_call(&"set_status", [&"veiled", veiled])
	var ids := ability_ids()
	if ids.size() == 3 and helper.model_has(&"set_charge"):
		var sig := ids[2]
		var c := 0.0 if helper.level < helper.helper_type.signature_level \
				else 1.0 - cooldown_left(sig) / maxf(0.01, cooldown_total(sig))
		c = snappedf(c, 0.05)
		if c != _charge_shown:
			_charge_shown = c
			helper.model_call(&"set_charge", [c])


## Autocast rules (section 4 "Autocast when").
func _wants(id: StringName) -> bool:
	return _pick(id) != null


# ---------------------------------------------------------------- picks (null = not now)

func _pick(id: StringName) -> Variant:
	var at := helper.global_position
	match id:
		&"vey_lunge":
			var r := float(LUNGE["range"])
			var w := _wizard if _wizard and is_instance_valid(_wizard) else null
			var best: Unit = null
			for e in _enemies_near(at, r):
				if w and e.attack_target == w:
					return e
				if best == null and e.attack_range > 3.0:
					best = e
			return best
		&"vey_chain":
			for e in _enemies_near(at, float(CHAIN["range"])):
				if _enemies_near(e.global_position, float(CHAIN["jump"])).size() >= int(CHAIN["min_count"]):
					return e
			return null
		&"vey_stormcall":
			if _enemies_near(at, float(STORMCALL["radius"])).size() >= int(STORMCALL["min_count"]):
				return at
			for e in _enemies_near(at, float(STORMCALL["big_radius"])):
				if _is_big(e):
					return at
			return null
		&"hush_blink":
			var best: Unit = null
			for e in _enemies_near(at, float(BLINK["range"])):
				if not (_is_hero(e) or e.attack_range > 3.0):
					continue
				if best == null or e.hp / maxf(1.0, e.max_hp) < best.hp / maxf(1.0, best.max_hp):
					best = e
			return best
		&"hush_smoke":
			var targeting := 0
			for e in _enemies_near(at, 15.0):
				if e.attack_target == helper:
					targeting += 1
			if helper.hp < helper.max_hp * float(SMOKE["hp_pct"]) and targeting > 0 \
					or targeting >= int(SMOKE["min_targeting"]):
				return at
			return null
		&"hush_knives":
			var near := _enemies_near(at, float(KNIVES["radius"]))
			if near.size() >= int(KNIVES["min_count"]):
				return at
			for e in near:
				if _is_wizard(e) and e.hp < e.max_hp * float(KNIVES["wizard_pct"]):
					return at
			return null
		&"aldra_shatter":
			var line := _best_line(at, float(SHATTER["length"]), float(SHATTER["width"]))
			return line[0] if (line[1] as Array).size() >= int(SHATTER["min_count"]) else null
		&"aldra_aegis":
			var low := 0
			for u in _allies_near(at, float(AEGIS["radius"])):
				if u.hp < u.max_hp * float(AEGIS["hp_pct"]):
					low += 1
			return at if low >= int(AEGIS["min_count"]) else null
		&"aldra_sentinel":
			if sentinel and is_instance_valid(sentinel) and sentinel.is_alive():
				return null
			var near := _enemies_near(at, float(SENTINEL["radius"]))
			if near.size() >= int(SENTINEL["min_count"]):
				return _centre(near)
			for e in near:
				if _is_big(e):
					return e.global_position
			return null
		&"thornsnare":
			var best_n := 0
			var best: Unit = null
			for e in _enemies_near(at, float(THORNSNARE["range"])):
				if _is_flyer(e):
					continue
				var n := _enemies_near(e.global_position, float(THORNSNARE["radius"])).size()
				if _is_hero(e):
					n += 1
				if n > best_n:
					best_n = n
					best = e
			return best if best_n >= int(THORNSNARE["min_count"]) else null
		&"call_the_pack":
			var e := _nearest_enemy(at, float(PACK["range"]))
			return e
		&"wild_stampede":
			var line := _best_line(at, float(STAMPEDE["length"]), float(STAMPEDE["width"]))
			return line[0] if (line[1] as Array).size() >= int(STAMPEDE["min_count"]) else null
	return null


# ---------------------------------------------------------------- effects

func _do(id: StringName, target: Variant) -> bool:
	var pick: Variant = target if target != null else _pick(id)
	if pick == null:
		return false
	if pick is Object and not is_instance_valid(pick):
		return false
	var f := helper.ability_factor()
	var at := helper.global_position
	match id:
		&"vey_lunge":
			var t := pick as Unit
			if t == null or not t.is_alive():
				return false
			var dir := _dir(at, t.global_position)
			var dest := t.global_position - dir * (t.radius + helper.radius + 0.3)
			for e in _enemies_near(at, _flat(at, t.global_position) + 1.0):
				if e == t or not _on_segment(e.global_position, at, dest, float(LUNGE["path_width"])):
					continue
				_hit(e, float(LUNGE["path_damage"]) * f)
				if e.is_alive():
					e.apply_status(&"dazed", float(LUNGE["daze"]))
			helper.global_position = Vector3(dest.x, helper.global_position.y, dest.z)
			_hit(t, float(LUNGE["damage"]) * f)
			if t.is_alive():
				helper.command_attack(t)
		&"vey_chain":
			var cur := pick as Unit
			if cur == null:
				return false
			var hit: Array[Unit] = []
			for amount: float in CHAIN["damage"]:
				if cur == null:
					break
				hit.append(cur)
				var from := cur.global_position
				_hit(cur, amount * f)
				cur = null
				var bd := INF
				for e in _enemies_near(from, float(CHAIN["jump"])):
					if hit.has(e):
						continue
					var d := _flat(e.global_position, from)
					if d < bd:
						bd = d
						cur = e
		&"vey_stormcall":
			var centre: Vector3 = at
			for u in _allies_near(centre, float(STORMCALL["radius"])):
				_timed_mod(u, STORMCALL_MOD, {&"attack_cooldown_pct": float(STORMCALL["haste_pct"])},
						float(STORMCALL["haste_time"]))
			var n := int(STORMCALL["bolts"])
			var gap := float(STORMCALL["time"]) / float(n)
			for i in n:
				_later(gap * float(i), func() -> void:
					var list := _enemies_near(centre, float(STORMCALL["radius"]))
					if not list.is_empty():
						_hit(list[randi() % list.size()], float(STORMCALL["damage"]) * f))
		&"hush_blink":
			var t := pick as Unit
			if t == null or not t.is_alive():
				return false
			var ref: WeakRef = weakref(t)
			_later(float(BLINK["delay"]), func() -> void:
				var v := ref.get_ref() as Unit
				if v == null or not v.is_alive() or not helper.is_alive():
					return
				var d := _dir(helper.global_position, v.global_position)
				var behind := v.global_position + d * (v.radius + helper.radius + 0.2)
				helper.global_position = Vector3(behind.x, helper.global_position.y, behind.z)
				_hit(v, float(BLINK["damage"]) * f)
				if v.is_alive():
					helper.command_attack(v))
		&"hush_smoke":
			helper.apply_status(&"shroud", float(SMOKE["shroud"]), true)
			helper.hide_from_auto_target(float(SMOKE["shroud"]))
			_drop_targeting(20.0)
		&"hush_knives":
			var vanish := float(KNIVES["vanish"])
			helper.set_untargetable(vanish + float(KNIVES["strikes"]) * float(KNIVES["gap"]))
			helper.visible = false
			_drop_targeting(20.0)
			var victims := _enemies_near(at, float(KNIVES["radius"]))
			victims.sort_custom(func(a: Unit, b: Unit) -> bool: return _flat(a.global_position, at) < _flat(b.global_position, at))
			var strikes := int(KNIVES["strikes"])
			for i in strikes:
				var last := i == strikes - 1
				var slot := i
				_later(vanish + float(KNIVES["gap"]) * float(i), func() -> void:
					if not helper.is_alive():
						helper.visible = true
						return
					var alive := victims.filter(func(v: Unit) -> bool: return is_instance_valid(v) and v.is_alive())
					if not alive.is_empty():
						var v: Unit = alive[slot % alive.size()]
						var dmg := float(KNIVES["damage"]) * f
						if _is_hero(v):
							dmg *= float(KNIVES["hero_mult"])
							v.apply_status(&"marked", float(KNIVES["mark"]))
						_hit(v, dmg)
						if last:
							var d := _dir(helper.global_position, v.global_position)
							var spot := v.global_position + d * (v.radius + helper.radius + 0.2)
							helper.global_position = Vector3(spot.x, helper.global_position.y, spot.z)
					if last:
						helper.visible = true)
		&"aldra_shatter":
			var dir: Vector3 = pick if pick is Vector3 else _dir(at, (pick as Node3D).global_position)
			if pick is Vector3 and (pick as Vector3).length() > 1.5:   # a world point: aim at it
				dir = _dir(at, pick)
			var list := _in_line(at, dir.normalized(), float(SHATTER["length"]), float(SHATTER["width"]))
			if list.is_empty():
				return false
			for i in mini(list.size(), int(SHATTER["max"])):
				_hit(list[i], float(SHATTER["damage"]) * f)
				if list[i].is_alive():
					list[i].apply_status(&"chill", maxf(float(SHATTER["chill"]), list[i].status_time_left(&"chill")))
		&"aldra_aegis":
			var allies := _allies_near(at, float(AEGIS["radius"]))
			allies.sort_custom(func(a: Unit, b: Unit) -> bool: return a.hp / maxf(1.0, a.max_hp) < b.hp / maxf(1.0, b.max_hp))
			for i in mini(allies.size(), int(AEGIS["count"])):
				allies[i].add_shield(float(AEGIS["shield"]) * f, float(AEGIS["time"]))
		&"aldra_sentinel":
			var p: Vector3 = pick if pick is Vector3 else (pick as Node3D).global_position
			var off := p - at
			off.y = 0.0
			if off.length() > float(SENTINEL["reach"]):
				p = at + off.normalized() * float(SENTINEL["reach"])
			sentinel = _summon(String(SENTINEL["unit"]), p, float(SENTINEL["life"]), 1.0)
			if sentinel == null:
				return false
		&"thornsnare":
			var p: Vector3 = pick if pick is Vector3 else (pick as Node3D).global_position
			_later(float(THORNSNARE["delay"]), func() -> void:
				for e in _enemies_near(p, float(THORNSNARE["radius"])):
					if _is_flyer(e):
						continue
					_hit(e, float(THORNSNARE["damage"]) * f)
					if e.is_alive():
						e.apply_status(&"rooted", float(THORNSNARE["root"])))
		&"call_the_pack":
			wolves = wolves.filter(func(w: Unit) -> bool: return is_instance_valid(w) and w.is_alive())
			for i in int(PACK["count"]):
				var side := Vector3(1.2 if i == 0 else -1.2, 0.0, 0.8)
				var w := _summon(String(PACK["unit"]), at + side, float(PACK["life"]), f)
				if w:
					wolves.append(w)
					if pick is Unit and (pick as Unit).is_alive():
						w.command_attack(pick)
		&"wild_stampede":
			var dir: Vector3 = pick if pick is Vector3 and (pick as Vector3).length() <= 1.5 else _dir(at, pick if pick is Vector3 else (pick as Node3D).global_position)
			var list := _in_line(at, dir.normalized(), float(STAMPEDE["length"]), float(STAMPEDE["width"]))
			if list.is_empty():
				return false
			for i in mini(list.size(), int(STAMPEDE["max"])):
				var e := list[i]
				_hit(e, float(STAMPEDE["damage"]) * f)
				if e.is_alive():
					var push := dir.normalized() * float(STAMPEDE["push"])
					e.global_position += Vector3(push.x, 0.0, push.z)
					e.apply_status(&"dazed", float(STAMPEDE["daze"]))
		_:
			return false
	return true


## Every damage of the helper (and of Maelis's wolves through _on_pack_hit) goes here: Bond bonuses on top.
func _hit(target: Unit, amount: float) -> void:
	if target == null or not target.is_alive():
		return
	target.take_damage(amount * _bond_mult(target), helper)


func _bond_mult(target: Unit) -> float:
	var now := _now()
	match passive_id():
		&"hush_veil":
			if float(target.get_meta(META_HUSH_BOND, -1.0)) >= now:
				return 1.0 + float(HUSH_BOND["bonus"])
		&"maelis_opinions":
			if float(target.get_meta(META_MAELIS_BOND, -1.0)) >= now and target.has_status(&"rooted"):
				return 1.0 + float(MAELIS_BOND["bonus"])
	return 1.0


# ---------------------------------------------------------------- passives

func _on_attack_landed(target: Node3D, dealt: float) -> void:
	var was_veiled := veiled
	_since_action = 0.0
	veiled = false
	var victim := target as Unit
	if victim == null or dealt <= 0.0:
		return
	match passive_id():
		&"vey_storm_sworn":
			_strikes += 1
			if _strikes % STORM_SWORN_EVERY != 0:
				return
			var near := _enemies_near(victim.global_position, float(STORM_SWORN["radius"]))
			near.erase(victim)
			near.sort_custom(func(a: Unit, b: Unit) -> bool:
				return _flat(a.global_position, victim.global_position) < _flat(b.global_position, victim.global_position))
			for i in mini(near.size(), int(STORM_SWORN["targets"])):
				_hit(near[i], dealt * float(STORM_SWORN["ratio"]))
			passive_procs += 1
		&"hush_veil":
			var extra := 0.0
			if was_veiled:
				extra += dealt * float(VEIL["bonus"])
				passive_procs += 1
			if victim.is_alive() and float(victim.get_meta(META_HUSH_BOND, -1.0)) >= _now():
				extra += dealt * float(HUSH_BOND["bonus"])
			if extra > 0.0 and victim.is_alive():
				victim.take_damage(extra, helper)
		&"maelis_opinions":
			if victim.is_alive() and _bond_mult(victim) > 1.0:
				victim.take_damage(dealt * float(MAELIS_BOND["bonus"]), helper)


func _on_damage_taken(_amount: float, _attacker: Node3D) -> void:
	_since_action = 0.0
	veiled = false


# Glasswater Ward: an own unit within 8 m of Aldra hit by a ranged attack or a spell gets 12 % of it back at once.
func _on_ward_hit(amount: float, attacker: Node3D, u: Unit) -> void:
	if helper == null or not is_instance_valid(helper) or not helper.is_alive() or not is_instance_valid(u) \
			or not u.is_alive() or amount <= 0.0:
		return
	if _flat(u.global_position, helper.global_position) > float(WARD["radius"]) or not _is_ranged_source(attacker):
		return
	u.heal(amount * float(WARD["cut"]))
	passive_procs += 1


func _on_wizard_spell_hit(target: Node3D, _amount: float, spell_id: StringName) -> void:
	if helper == null or not helper.is_alive() or target == null or not is_instance_valid(target):
		return
	var d := _flat(target.global_position, helper.global_position)
	match passive_id():
		&"vey_storm_sworn":
			if spell_id == &"fireball" and d <= float(SPARK_FIRST["radius"]) and _now() >= _spark_ready_at:
				_spark_ready_at = _now() + float(SPARK_FIRST["every"])
				_cd[&"vey_chain"] = maxf(0.0, float(_cd.get(&"vey_chain", 0.0)) - float(SPARK_FIRST["cut"]))
				passive_procs += 1
		&"hush_veil":
			if spell_id == &"shadow_lance" or spell_id == &"soul_siphon":
				target.set_meta(META_HUSH_BOND, _now() + float(HUSH_BOND["time"]))
		&"aldra_ward":
			if (spell_id == &"rime_bolt" or spell_id == &"flash_freeze") and d <= float(ALDRA_BOND["radius"]) \
					and target is Unit and (target as Unit).is_alive():
				var u := target as Unit
				u.apply_status(&"chill", maxf(float(ALDRA_BOND["chill"]), u.status_time_left(&"chill")))
				passive_procs += 1
		&"maelis_opinions":
			if spell_id == &"thornburst":
				target.set_meta(META_MAELIS_BOND, _now() + float(MAELIS_BOND["time"]))


# ---------------------------------------------------------------- helpers

func _summon(type_id: String, at: Vector3, life: float, hp_mult: float) -> Unit:
	var base := UnitType.find(type_id)
	if base == null or not helper.is_inside_tree():
		return null
	var t := base.duplicate() as UnitType
	t.pop = 0
	t.kill_xp = 0
	t.cost = 0
	t.lifetime = life
	t.commandable = false
	t.max_hp = base.max_hp * hp_mult
	t.faction = helper.helper_type.kingdom if helper.helper_type else base.faction
	var u := t.create_unit()
	u.team = helper.team
	var parent := helper.get_tree().current_scene if helper.get_tree().current_scene else helper.get_parent()
	parent.add_child(u)
	u.global_position = Vector3(at.x, helper.global_position.y, at.z)
	u.command_stop()
	var e := _nearest_enemy(at, 14.0)
	if e:
		u.command_attack(e)
	if type_id == String(PACK["unit"]):
		u.attack_landed.connect(func(tg: Node3D, dealt: float) -> void:
			var v := tg as Unit
			if v and v.is_alive() and dealt > 0.0 and _bond_mult(v) > 1.0:
				v.take_damage(dealt * float(MAELIS_BOND["bonus"]), u))
	return u


func _timed_mod(u: Unit, mod_id: StringName, stats: Dictionary, seconds: float) -> void:
	u.add_modifier(mod_id, stats)
	var ref: WeakRef = weakref(u)
	helper.get_tree().create_timer(seconds, false, true).timeout.connect(func() -> void:
		var v := ref.get_ref() as Unit
		if v:
			v.remove_modifier(mod_id))


func _later(seconds: float, fn: Callable) -> void:
	if seconds <= 0.0:
		fn.call()
		return
	helper.get_tree().create_timer(seconds, false, true).timeout.connect(fn)


func _drop_targeting(r: float) -> void:
	for e in _enemies_near(helper.global_position, r):
		if e.attack_target == helper:
			e.command_stop()


func _enemies_near(at: Vector3, r: float) -> Array[Unit]:
	var out: Array[Unit] = []
	if helper == null or not helper.is_inside_tree():
		return out
	for n in helper.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or u == helper or not u.is_alive() or not helper.is_enemy_of(u):
			continue
		if _flat(u.global_position, at) <= r + u.radius:
			out.append(u)
	return out


func _allies_near(at: Vector3, r: float) -> Array[Unit]:
	var out: Array[Unit] = []
	if helper == null or not helper.is_inside_tree():
		return out
	for n in helper.get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or not u.is_alive() or int(u.team) != int(helper.team):
			continue
		if _flat(u.global_position, at) <= r:
			out.append(u)
	return out


func _nearest_enemy(at: Vector3, r: float) -> Unit:
	var best: Unit = null
	var bd := INF
	for e in _enemies_near(at, r):
		var d := _flat(e.global_position, at)
		if d < bd:
			bd = d
			best = e
	return best


## [direction (Vector3, unit length), enemies in that line] of the best line from `at` toward an enemy.
func _best_line(at: Vector3, length: float, width: float) -> Array:
	var best_dir := Vector3.ZERO
	var best: Array[Unit] = []
	for e in _enemies_near(at, length):
		var dir := _dir(at, e.global_position)
		var list := _in_line(at, dir, length, width)
		if list.size() > best.size():
			best = list
			best_dir = dir
	return [best_dir, best]


## Enemies whose centre is within width / 2 (+ radius) of the segment at -> at + dir x length, nearest first.
func _in_line(at: Vector3, dir: Vector3, length: float, width: float) -> Array[Unit]:
	var out: Array[Unit] = []
	var end := at + dir * length
	for e in _enemies_near(at, length):
		if _on_segment(e.global_position, at, end, width + e.radius * 2.0):
			out.append(e)
	out.sort_custom(func(a: Unit, b: Unit) -> bool: return _flat(a.global_position, at) < _flat(b.global_position, at))
	return out


static func _on_segment(p: Vector3, a: Vector3, b: Vector3, width: float) -> bool:
	var p2 := Vector2(p.x, p.z)
	var q := Geometry2D.get_closest_point_to_segment(p2, Vector2(a.x, a.z), Vector2(b.x, b.z))
	return p2.distance_to(q) <= width * 0.5


static func _dir(a: Vector3, b: Vector3) -> Vector3:
	var d := Vector3(b.x - a.x, 0.0, b.z - a.z)
	return d.normalized() if d.length() > 0.01 else Vector3(0.0, 0.0, 1.0)


static func _centre(list: Array[Unit]) -> Vector3:
	var s := Vector3.ZERO
	for u in list:
		s += u.global_position
	return s / float(maxi(1, list.size()))


static func _is_wizard(u: Unit) -> bool:
	return u.is_in_group(&"heroes") or u.is_in_group(&"enemy_heroes")


static func _is_hero(u: Unit) -> bool:
	return _is_wizard(u) or u.is_in_group(&"champions")


## Titans and helpers (the "big" targets of Stormcall / Sentinel).
static func _is_big(u: Unit) -> bool:
	return u.is_in_group(&"helpers") or (u.unit_type != null and u.unit_type.pop >= 6)


static func _is_flyer(u: Unit) -> bool:
	return u.unit_type != null and FLYER_IDS.has(u.unit_type.id)


## Ranged auto-attacks, wizards (spells) and buildings (towers, keeps) count for Glasswater Ward.
static func _is_ranged_source(attacker: Node3D) -> bool:
	if attacker == null or not is_instance_valid(attacker):
		return false
	if attacker is Unit:
		var u := attacker as Unit
		return u.attack_range > 3.0 or _is_wizard(u)
	return attacker.is_in_group(&"buildings")


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


static func _now() -> float:
	return float(Engine.get_physics_frames()) / float(maxi(1, Engine.physics_ticks_per_second))
