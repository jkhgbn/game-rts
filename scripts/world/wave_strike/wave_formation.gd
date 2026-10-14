class_name WaveFormation
extends RefCounted
## One seat's wave of one horn marching as a block (docs/design/wave-strike.md 15.3). LaneSpawner makes one per seat
## per horn, adds every copy it spawns (`add_member`), calls `start_march()` when the last copy is out + the muster hold
## (rules.muster_hold_extra), and ticks it with the director's clock (`tick`): `release()` after
## rules.march_release_after s of march. Contact (a target / HP lost) is seen on the unit side and calls `release()`.
##
## Unit-side interface (LaneMarch, scripts/units/lane_march.gd, WS3.G1 / WS4.G1; every call is has_method-guarded):
## - `LaneMarch.hold(formation)`: right after attach, the unit stands on its cell (no order, auto-aggro on) until
##   `march` or `release`; it keeps `formation` and calls `formation.release()` on the first trigger (an attack target,
##   HP below the spawn HP).
## - `LaneMarch.march(speed)`: the hold is over; speed > 0 = locked: modifier `ws_lock` (flat move_speed = speed - own
##   speed, only when the own speed is higher), then the lane march from the first waypoint ahead; speed <= 0 = no lock.
## - `LaneMarch.release(effects: Array)`: once: `ws_lock` removed, normal march, then `effects` applied
##   ({"status": id, "duration": s} -> apply_status, {"shield": n, "duration": s} -> add_shield).
## Without that side (no `hold` on LaneMarch) units march at spawn as before and this class applies the lock, watches
## the triggers every TICK s and applies the effects itself.

signal released(formation: WaveFormation)

enum State { MUSTER, MARCH, RELEASED }

const TICK := 0.25                      ## s between fallback trigger checks (fallback only)
const LOCK_ID := &"ws_lock"

var seat := 0
var horn := 0
var lock := true
var speed_floor := 4.0
var release_after := 45.0
var state: State = State.MUSTER
var speed := 0.0                        ## the locked march speed (0 = not locked / not marching yet)
var march_time := 0.0                   ## s since start_march
var release_reason := ""
var members: Array[Unit] = []

var _effects: Dictionary = {}           ## Unit -> Array (its release effects)
var _hp0: Dictionary = {}               ## Unit -> HP at spawn (fallback trigger)
var _unit_side := false                 ## LaneMarch has the hold / march / release API
var _check_left := 0.0


func _init(p_seat: int = 0, p_horn: int = 0, rules: WaveStrikeRules = null) -> void:
	seat = p_seat
	horn = p_horn
	if rules != null:
		lock = rules.march_lock
		speed_floor = rules.march_speed_floor
		release_after = rules.march_release_after


## Adds a spawned copy (its LaneMarch child must exist). `effects` = its release list (WS4: upgrades).
func add_member(u: Unit, effects: Array = []) -> void:
	if u == null or state == State.RELEASED:
		return
	members.append(u)
	if not effects.is_empty():
		_effects[u] = effects
	_hp0[u] = u.hp
	var lm := u.get_node_or_null(^"LaneMarch")
	if lm != null and lm.has_method(&"hold"):
		_unit_side = true
		lm.call(&"hold", self)


func is_member(u: Unit) -> bool:
	return _hp0.has(u)


func release_effects_of(u: Unit) -> Array:
	return _effects.get(u, [])


func is_released() -> bool:
	return state == State.RELEASED


func living() -> Array[Unit]:
	var out: Array[Unit] = []
	for u in members:
		if is_instance_valid(u) and u.is_alive():
			out.append(u)
	return out


## The hold is over: the wave walks at its slowest living copy's speed (>= speed_floor), or each at its own when the
## lock is off.
func start_march() -> void:
	if state != State.MUSTER:
		return
	state = State.MARCH
	march_time = 0.0
	var alive := living()
	speed = 0.0
	if lock and not alive.is_empty():
		var slow := INF
		for u in alive:
			slow = minf(slow, u.get_stat(&"move_speed"))
		speed = maxf(slow, speed_floor)
	for u in alive:
		var lm := u.get_node_or_null(^"LaneMarch")
		if _unit_side and lm != null and lm.has_method(&"march"):
			lm.call(&"march", speed)
		elif not _unit_side and speed > 0.0:
			var own := u.get_stat(&"move_speed")
			if own > speed:
				u.add_modifier(LOCK_ID, {"move_speed": speed - own})


## Breaks the formation for every member at once (contact, timeout, load). Once.
func release(reason: String = "contact") -> void:
	if state == State.RELEASED:
		return
	state = State.RELEASED
	release_reason = reason
	for u in members:
		if not is_instance_valid(u) or not u.is_alive():
			continue
		var fx: Array = _effects.get(u, [])
		var lm := u.get_node_or_null(^"LaneMarch")
		if _unit_side and lm != null and lm.has_method(&"release"):
			lm.call(&"release", fx)
		else:
			u.remove_modifier(LOCK_ID)
			apply_effects(u, fx)
	released.emit(self)


## The release effects on one unit (the fallback; LaneMarch.release does the same on the unit side).
static func apply_effects(u: Unit, fx: Array) -> void:
	for e: Variant in fx:
		if not e is Dictionary:
			continue
		var d := e as Dictionary
		if d.has("status"):
			u.apply_status(StringName(str(d["status"])), float(d.get("duration", 0.0)))
		elif d.has("shield"):
			u.add_shield(float(d["shield"]), float(d.get("duration", 0.0)))


## Advances the march clock (LaneSpawner.tick). True = done (released or every member gone).
func tick(delta: float) -> bool:
	if state == State.RELEASED:
		return true
	if state == State.MARCH:
		march_time += delta
		if march_time >= release_after:
			release("timeout")
			return true
	if not _unit_side:
		_check_left -= delta
		if _check_left <= 0.0:
			_check_left = TICK
			_fallback_triggers()
	return state == State.RELEASED


func _fallback_triggers() -> void:
	var any := false
	for u in members:
		if not is_instance_valid(u) or not u.is_alive():
			if is_instance_valid(u) and _hp0.has(u):
				any = true   # a member died: contact
			continue
		if u.attack_target != null or u.hp < float(_hp0.get(u, u.hp)) - 0.01:
			any = true
			break
	if any:
		release("contact")
	elif not members.is_empty() and living().is_empty():
		release("gone")
