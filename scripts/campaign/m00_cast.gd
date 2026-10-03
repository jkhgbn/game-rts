class_name M00Cast
extends Node
## Mission 0's two story units and their kits (docs/design/mission-00.md "Allies and the mini-boss"; story numbers of
## 19.C11 / 19.C12 / 19.A2 built mission-side on plain Units with the helper models, no HelperAbilities):
## - Old Vey (`torren_vey`, team PLAYER, not commandable): Thunder-edged Blade (every 3rd strike a spark jumps to one
##   more enemy within 3 m for 20), Intercept (every 8 s: blinks next to the nearest enemy that targets Vessa within
##   10 m of him and taunts it 3 s), kneels at 1 HP for 5 s (invulnerable, untargetable) then stands at 40 %; brain:
##   2-5 m from Vessa between her and the nearest assassin, holds 3 m in front of her while she lights a brazier.
## - Mother Hush (`mother_hush`, team ENEMY, scripted): Blink Strike (the first after 2.5 s with a hero in reach, then
##   every 10 s / hard 8 s while one is: the hero with the lowest
##   HP % within 14 m, a violet ring 0.5 s / easy 0.8 s, then she appears behind its centre and strikes for 50 / easy
##   35 unless the target is > 2 m from the centre), Smoke once at 50 % (shroud 4 s, withdraws 10 m, comes back),
##   flees at 25 % (invulnerable, walks to the nearest spawn and leaves the map). Never dies.
## The mission owns this node (child of the level): it pauses with the tree (PAUSE cinematics).

signal vey_first_spark            ## E1b: Vey's first 3rd-strike spark.
signal hush_smoked                ## E5: Hush reached 50 % (Smoke).
signal hush_fled                  ## E6: Hush reached 25 % and runs.
signal blink_struck(target: Unit, hit: bool)

const BRAIN_TICK := 0.25
const SPARK_EVERY := 3
const SPARK_RADIUS := 3.0
const SPARK_DAMAGE := 20.0
const INTERCEPT_EVERY := 8.0
const INTERCEPT_RANGE := 10.0
const TAUNT_SECONDS := 3.0
const KNEEL_SECONDS := 5.0
const STAND_PCT := 0.4
const ESCORT_NEAR := 2.0
const ESCORT_FAR := 5.0
const ESCORT_LEASH := 8.0         ## Vey drops a fight that pulls him this far from Vessa.
const GUARD_FRONT := 3.0          ## While Vessa lights a brazier: this far in front of her.
const BLINK_RANGE := 14.0
const FIRST_BLINK := 2.5          ## The first Blink Strike: 2.5 s of a hero in reach (the lesson comes at once).
const BLINK_RING := 1.5
const BLINK_DODGE := 2.0
const SMOKE_PCT := 0.5
const SMOKE_SECONDS := 4.0
const SMOKE_WITHDRAW := 10.0
const FLEE_PCT := 0.25
const FLEE_TIMEOUT := 25.0
## [easy, normal, hard]
const HUSH_HP: Array[float] = [700.0, 900.0, 1200.0]
const BLINK_COOLDOWN: Array[float] = [10.0, 10.0, 8.0]
const BLINK_TELEGRAPH: Array[float] = [0.8, 0.5, 0.5]
const BLINK_DAMAGE: Array[float] = [35.0, 50.0, 50.0]

var mission: Node                 ## Mission00 (hero, assassins(), spawn points, brazier_in_progress(), bounds)
var difficulty := 1
var vey: Unit
var hush: Unit
var vey_kneeling := false         ## Read only.
var hush_state: StringName = &""  ## "" not spawned, &"fight", &"smoke", &"flee", &"gone".
var sparks := 0                   ## Read only: Vey's spark jumps so far.
var intercepts := 0               ## Read only.
var blinks := 0                   ## Read only: Blink Strikes landed or missed.
var blink_hits := 0
var blink_target: Unit = null     ## Read only: the hero the current / last ring is on.

var _brain_left := 0.0
var _strikes := 0
var _intercept_left := 2.0
var _kneel_left := 0.0
var _blink_left := 0.0
var _blink_pending := false
var _smoked := false
var _smoke_left := 0.0
var _flee_left := 0.0


func setup(m: Node, diff: int) -> void:
	mission = m
	difficulty = clampi(diff, 0, 2)
	name = "M00Cast"


# ---------------------------------------------------------------- Old Vey

## Takes `u` (already spawned, team PLAYER) as Old Vey.
func bind_vey(u: Unit) -> void:
	vey = u
	u.unit_name = "Old Vey"
	u.add_to_group(&"story_units")
	u.death_guard = _vey_guard
	u.attack_landed.connect(_on_vey_hit)
	_model(u, &"set_expression", [&"fierce"])


## Removes Vey without a death (m0_fall end state): no died signal, no XP.
func remove_vey() -> void:
	if vey and is_instance_valid(vey) and vey.is_alive():
		vey.leave_map()
	vey_kneeling = false


func vey_alive() -> bool:
	return vey != null and is_instance_valid(vey) and vey.is_alive()


func _vey_guard(_attacker: Variant) -> bool:
	if not vey_alive():
		return false
	vey.hp = 1.0
	if not vey_kneeling:
		_start_kneel()
	return true


func _start_kneel() -> void:
	vey_kneeling = true
	_kneel_left = KNEEL_SECONDS
	vey.hp = 1.0
	vey.command_stop()
	vey.hide_from_auto_target(KNEEL_SECONDS)
	for u in _enemies():
		if u.attack_target == vey:
			u.command_stop()
	_model(vey, &"play_gesture", [&"kneel"])


func _end_kneel() -> void:
	vey_kneeling = false
	if not vey_alive():
		return
	vey.hp = maxf(vey.hp, vey.max_hp * STAND_PCT)
	_model(vey, &"play_gesture", [&"stand_up"])


func _on_vey_hit(target: Node3D, _amount: float) -> void:
	_strikes += 1
	if _strikes % SPARK_EVERY != 0 or target == null or not is_instance_valid(target):
		return
	var best: Unit = null
	var best_d := INF
	for u in _enemies():
		if u == target:
			continue
		var d := _flat(u.global_position, target.global_position)
		if d <= SPARK_RADIUS and d < best_d:
			best_d = d
			best = u
	if best == null:
		return
	sparks += 1
	M00Vfx.spark_arc(mission, target.global_position, best.global_position)
	best.take_damage(SPARK_DAMAGE, vey)
	if sparks == 1:
		vey_first_spark.emit()


# ---------------------------------------------------------------- Mother Hush

## Takes `u` (spawned, team ENEMY) as Mother Hush with the difficulty's HP.
func bind_hush(u: Unit) -> void:
	hush = u
	u.unit_name = "Mother Hush"
	u.add_to_group(&"story_units")
	var hp_max: float = HUSH_HP[difficulty]
	u.set_base_stat(&"max_hp", hp_max)
	u.hp = u.max_hp
	u.death_guard = _hush_guard
	u.damage_taken.connect(_on_hush_damaged)
	hush_state = &"fight"
	_blink_left = FIRST_BLINK
	_model(u, &"set_expression", [&"fierce"])


func hush_on_field() -> bool:
	return hush != null and is_instance_valid(hush) and hush.is_alive() and hush_state != &"gone"


## True while Hush runs (she is no longer a knife: the mission's focus rules skip her).
func hush_busy() -> bool:
	return hush_state == &"flee" or hush_state == &"smoke" or _blink_pending


func _hush_guard(_attacker: Variant) -> bool:
	if hush == null or not is_instance_valid(hush):
		return false
	hush.hp = maxf(1.0, hush.max_hp * 0.05)
	if hush_state != &"flee":
		_start_flee()
	return true


func _on_hush_damaged(_amount: float, _attacker: Node3D) -> void:
	if hush == null or not is_instance_valid(hush) or not hush.is_alive():
		return
	var pct := hush.hp / maxf(1.0, hush.max_hp)
	if hush_state == &"flee":
		hush.hp = maxf(hush.hp, hush.max_hp * 0.05)
		return
	if pct <= FLEE_PCT:
		_start_flee()
	elif pct <= SMOKE_PCT and not _smoked:
		_start_smoke()


func _start_smoke() -> void:
	_smoked = true
	hush_state = &"smoke"
	_smoke_left = SMOKE_SECONDS
	hush.apply_status(&"shroud", SMOKE_SECONDS, true)
	M00Vfx.smoke_burst(mission, hush.global_position)
	var away := hush.global_position - _vessa_pos()
	away.y = 0.0
	if away.length() < 0.1:
		away = Vector3(1.0, 0.0, -1.0)
	hush.command_move(_clamp_box(hush.global_position + away.normalized() * SMOKE_WITHDRAW))
	_model(hush, &"play_cast", [&"hush_smoke"])
	hush_smoked.emit()


func _start_flee() -> void:
	if hush_state == &"flee" or hush_state == &"gone":
		return
	hush_state = &"flee"
	_blink_pending = false
	_flee_left = FLEE_TIMEOUT
	hush.hide_from_auto_target(FLEE_TIMEOUT)
	hush.apply_status(&"shroud", 3.0, true)
	M00Vfx.smoke_burst(mission, hush.global_position)
	for u in _friends():
		if u.attack_target == hush:
			u.command_stop()
	hush.command_move(_nearest_spawn(hush.global_position))
	hush_fled.emit()


## Hush leaves the field at once (dawn): no death.
func hush_leave() -> void:
	if hush and is_instance_valid(hush) and hush.is_alive():
		hush.leave_map()
	hush_state = &"gone"


func _blink_strike() -> void:
	var target := _blink_target()
	if target == null:
		_blink_left = 1.0
		return
	_blink_pending = true
	blink_target = target
	blinks += 1
	var center := target.global_position
	center.y = 0.0
	var telegraph: float = BLINK_TELEGRAPH[difficulty]
	M00Vfx.blink_ring(mission, center, telegraph, BLINK_RING)
	_model(hush, &"play_cast", [&"hush_blink"])
	hush.command_stop()
	hush.set_cast_lock(telegraph)
	var from := hush.global_position
	get_tree().create_timer(telegraph, false, true).timeout.connect(_blink_land.bind(target, center, from))


func _blink_land(target: Unit, center: Vector3, from: Vector3) -> void:
	_blink_pending = false
	if hush == null or not is_instance_valid(hush) or not hush.is_alive() or hush_state != &"fight":
		return
	var dir := center - from
	dir.y = 0.0
	dir = dir.normalized() if dir.length() > 0.1 else Vector3(1.0, 0.0, 0.0)
	M00Vfx.smoke_burst(mission, hush.global_position)
	hush.global_position = _clamp_box(center + dir * 1.0)
	hush.face_direction(-dir)
	var hit := target != null and is_instance_valid(target) and target.is_alive() \
			and _flat(target.global_position, center) <= BLINK_DODGE
	if hit:
		blink_hits += 1
		target.take_damage(BLINK_DAMAGE[difficulty], hush)
	else:
		M00Vfx.miss_text(mission, center)
	_model(hush, &"play_attack")
	blink_struck.emit(target, hit)
	if target != null and is_instance_valid(target) and target.is_alive():
		hush.command_attack(target)


## The hero (Vessa or a standing Vey) with the lowest HP % within BLINK_RANGE of Hush.
func _blink_target() -> Unit:
	var best: Unit = null
	var best_pct := INF
	var hero: Unit = mission.get(&"hero") as Unit
	for u: Unit in [hero, vey]:
		if u == null or not is_instance_valid(u) or not u.is_alive():
			continue
		if u == vey and vey_kneeling:
			continue
		if _flat(u.global_position, hush.global_position) > BLINK_RANGE:
			continue
		var pct := u.hp / maxf(1.0, u.max_hp)
		if pct < best_pct:
			best_pct = pct
			best = u
	return best


# ---------------------------------------------------------------- tick

func _physics_process(delta: float) -> void:
	if mission == null or not is_instance_valid(mission) or bool(mission.get(&"game_over")):
		return
	if not bool(mission.get(&"match_started")) or bool(mission.get(&"world_is_held")):
		return
	_tick_vey_timers(delta)
	_tick_hush(delta)
	_brain_left -= delta
	if _brain_left <= 0.0:
		_brain_left = BRAIN_TICK
		_vey_brain()


func _tick_vey_timers(delta: float) -> void:
	if not vey_alive():
		return
	_intercept_left -= delta
	if vey_kneeling:
		vey.hp = maxf(vey.hp, 1.0)
		_kneel_left -= delta
		if _kneel_left <= 0.0:
			_end_kneel()


func _tick_hush(delta: float) -> void:
	if hush == null or not is_instance_valid(hush) or not hush.is_alive():
		return
	match hush_state:
		&"fight":
			if _blink_pending:
				return
			if _blink_target() == null:   # the clock runs only while a hero is within reach
				_blink_left = maxf(_blink_left, 1.0)
				return
			_blink_left -= delta
			if _blink_left <= 0.0:
				_blink_left = BLINK_COOLDOWN[difficulty]
				_blink_strike()
		&"smoke":
			_smoke_left -= delta
			if _smoke_left <= 0.0:
				hush_state = &"fight"
				var hero: Unit = mission.get(&"hero") as Unit
				if hero and is_instance_valid(hero) and hero.is_alive():
					hush.command_attack(hero)
		&"flee":
			_flee_left -= delta
			hush.hp = maxf(hush.hp, hush.max_hp * 0.05)
			var exit := _nearest_spawn(hush.global_position)
			if _flat(hush.global_position, exit) <= 2.5 or _flee_left <= 0.0:
				hush_leave()
			elif not hush.has_move_order():
				hush.command_move(exit)


func _vey_brain() -> void:
	if not vey_alive() or vey_kneeling or not vey.can_act():
		return
	var hero: Unit = mission.get(&"hero") as Unit
	if hero == null or not is_instance_valid(hero) or not hero.is_alive():
		var near := _nearest_enemy(vey.global_position, 14.0)
		if near and vey.attack_target != near:
			vey.command_attack(near)
		return
	var vessa := hero.global_position
	# Intercept: the nearest enemy that targets Vessa within 10 m of him.
	if _intercept_left <= 0.0:
		var knife: Unit = null
		var kd := INF
		for u in _enemies():
			if u.attack_target != hero or u.has_status(&"taunted"):
				continue
			var d := _flat(u.global_position, vey.global_position)
			if d <= INTERCEPT_RANGE and d < kd:
				kd = d
				knife = u
		if knife:
			_intercept(knife)
			return
	var lighting: Variant = mission.call(&"brazier_in_progress") if mission.has_method(&"brazier_in_progress") else null
	var threat := _nearest_enemy(vessa, 10.0)
	if lighting is Vector3:
		# Holds 3 m in front of her, facing the side the knives come from.
		var face: Vector3 = lighting
		var dir := face - vessa
		dir.y = 0.0
		var spot := vessa + (dir.normalized() if dir.length() > 0.1 else Vector3(1.0, 0.0, -1.0)) * GUARD_FRONT
		spot = _clamp_box(spot)
		if threat and _flat(threat.global_position, spot) <= 4.5:
			if vey.attack_target != threat:
				vey.command_attack(threat)
		elif _flat(vey.global_position, spot) > 1.2:
			vey.command_move(spot)
		return
	var from_her := _flat(vey.global_position, vessa)
	if threat and from_her <= ESCORT_LEASH:
		if vey.attack_target != threat:
			vey.command_attack(threat)
		return
	if vey.attack_target != null and from_her > ESCORT_LEASH:
		vey.command_stop()
	if from_her > ESCORT_FAR or (from_her < ESCORT_NEAR and vey.attack_target == null):
		var toward := _nearest_enemy(vessa, 30.0)
		var dir2 := (toward.global_position - vessa) if toward else (vey.global_position - vessa)
		dir2.y = 0.0
		if dir2.length() < 0.1:
			dir2 = Vector3(1.0, 0.0, -1.0)
		var spot2 := _clamp_box(vessa + dir2.normalized() * 3.0)
		if _flat(vey.global_position, spot2) > 1.0:
			vey.command_move(spot2)


func _intercept(knife: Unit) -> void:
	_intercept_left = INTERCEPT_EVERY
	intercepts += 1
	var from := vey.global_position
	var dir := from - knife.global_position
	dir.y = 0.0
	dir = dir.normalized() if dir.length() > 0.1 else Vector3(1.0, 0.0, 0.0)
	M00Vfx.crackle_blink(mission, from)
	vey.global_position = _clamp_box(knife.global_position + dir * 1.3)
	M00Vfx.crackle_blink(mission, vey.global_position)
	knife.apply_status(&"taunted", TAUNT_SECONDS, true, vey)
	knife.command_attack(vey)
	vey.command_attack(knife)


# ---------------------------------------------------------------- helpers

func _enemies() -> Array[Unit]:
	var out: Array[Unit] = []
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == Unit.Team.ENEMY:
			out.append(u)
	return out


func _friends() -> Array[Unit]:
	var out: Array[Unit] = []
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == Unit.Team.PLAYER:
			out.append(u)
	return out


## The nearest living, targetable enemy within `radius` of `at` (Hush while fleeing excluded).
func _nearest_enemy(at: Vector3, radius: float) -> Unit:
	var best: Unit = null
	var best_d := INF
	for u in _enemies():
		if u.is_hidden_from_auto_target():
			continue
		var d := _flat(u.global_position, at)
		if d <= radius and d < best_d:
			best_d = d
			best = u
	return best


func _vessa_pos() -> Vector3:
	var hero: Unit = mission.get(&"hero") as Unit
	return hero.global_position if hero and is_instance_valid(hero) else Vector3.ZERO


func _nearest_spawn(at: Vector3) -> Vector3:
	if mission.has_method(&"nearest_spawn"):
		return mission.call(&"nearest_spawn", at)
	return at


func _clamp_box(p: Vector3) -> Vector3:
	if mission.has_method(&"clamp_to_play_area"):
		return mission.call(&"clamp_to_play_area", p)
	return p


static func _model(u: Unit, method: StringName, args: Array = []) -> void:
	if u and is_instance_valid(u) and u.model_has(method):
		u.model_call(method, args)


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
