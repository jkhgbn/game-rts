class_name LaneMarch
extends Node
## Wave Strike auto-march (docs/design/wave-strike.md 7.1): a child node "LaneMarch" of a lane unit. The unit
## attack-moves from waypoint to waypoint along the lane (with its own lateral offset, so a wave spreads across the
## lane), fights what it meets through its own auto-aggro (units first, then buildings), and at the lane's end goes for
## the enemy Bastion. Rules:
## - waypoints: the next point is taken within ADVANCE_DIST m or once the unit is past the point's plane;
## - leash: a unit pulled more than `leash` m off its lane line drops its target and walks back (no re-aggro for
##   LEASH_COOLDOWN s);
## - no stall: idle (no target, not moving) for IDLE_REISSUE s = the waypoint order again; stuck (moved < STUCK_DIST m
##   in STUCK_TIME s with no target) = a 2 m side-step, then on. `stall_events` counts units stuck past STALL_REPORT s.
## Uses command_attack_move / command_move / set_auto_target only (never writes attack_target).
## Perf (wave-strike.md 14.2): P2 = the unit's auto-aggro scan and this node's think run on fixed physics-frame buckets
## (Unit.SCAN_BUCKETS) picked from the spawn serial, so a horn's burst never scans / thinks on one frame; P3 = every
## GATE_EVERY s the unit's RVO avoidance is turned off while no enemy unit is within GATE_RANGE m (and it is not
## fighting, nor near the enemy Bastion), and back on as soon as one is.

const TICK := 0.25
const ADVANCE_DIST := 5.0
const LEASH_COOLDOWN := 1.5
const IDLE_REISSUE := 2.0
const STUCK_TIME := 4.0
const STUCK_DIST := 0.5
const SIDE_STEP := 2.0
const STALL_REPORT := 10.0      ## s without progress and without a fight = one stall event (tests want 0)
const BASTION_REACH := 30.0     ## at the lane's end, a Bastion this close becomes the target
const GATE_RANGE := 30.0        ## P3: no enemy unit this close = avoidance off
const GATE_EVERY := 0.5         ## s between two avoidance-gate checks
## The think runs this many buckets after the unit's scan bucket (never on the same frame as its own scan).
const THINK_BUCKET_OFFSET := 7

## Global counters (tests / labs): units that stalled, and the longest stall seen (s).
static var stall_events := 0
static var longest_stall := 0.0
## P2: lane units attached since the last reset_counters (their bucket = serial mod Unit.SCAN_BUCKETS).
static var spawn_serial := 0

var unit: Unit
var path: PackedVector3Array = PackedVector3Array()   ## in this unit's walking order
var lateral := 0.0              ## m, + = left of the walking direction
var leash := 12.0
var bastion: Node3D = null      ## the enemy Bastion (the final target)
var index := 0                  ## next waypoint

var _goal := Vector3.INF        ## the point of the last order
var _return_left := 0.0         ## > 0: walking back to the lane (leash), no aggro
var _idle_for := 0.0
var _stuck_ref := Vector3.ZERO
var _stuck_for := 0.0
var _no_progress := 0.0
var _reported := false
var _sidestep_left := 0.0
var _bucket := 0                ## physics-frame bucket of the think
var _last_think := -1           ## physics frame of the last think
var _gate_left := 0.0           ## s to the next avoidance-gate check


static func reset_counters() -> void:
	stall_events = 0
	longest_stall = 0.0
	spawn_serial = 0


## Attaches a LaneMarch to `u` (already in the tree) and starts the march. `phase` is unused since P2 (the spawn
## serial picks the frame buckets); kept for the callers.
static func attach(u: Unit, lane: PackedVector3Array, p_lateral: float, p_leash: float, enemy_bastion: Node3D,
		_phase: float = 0.0) -> LaneMarch:
	var lm := LaneMarch.new()
	lm.name = "LaneMarch"
	lm.unit = u
	lm.path = lane
	lm.lateral = p_lateral
	lm.leash = p_leash
	lm.bastion = enemy_bastion
	var serial := spawn_serial
	spawn_serial += 1
	u.scan_bucket = serial % Unit.SCAN_BUCKETS
	lm._bucket = (serial + THINK_BUCKET_OFFSET) % Unit.SCAN_BUCKETS
	lm._last_think = Engine.get_physics_frames()
	lm._gate_left = float(serial % 2) * TICK   # gate checks alternate between two thinks
	u.add_child(lm)
	lm._stuck_ref = u.global_position
	lm._issue()
	lm._update_gate()
	return lm


func _physics_process(delta: float) -> void:
	if unit == null or not is_instance_valid(unit) or not unit.is_alive():
		set_physics_process(false)
		return
	if _return_left > 0.0:
		_return_left -= delta
	if _sidestep_left > 0.0:
		_sidestep_left -= delta
	var f := Engine.get_physics_frames()
	if f % Unit.SCAN_BUCKETS != _bucket or f == _last_think:
		return
	var dt := float(f - _last_think) / float(Engine.physics_ticks_per_second)
	_last_think = f
	_think(dt)
	_gate_left -= dt
	if _gate_left <= 0.0:
		_gate_left += GATE_EVERY
		_update_gate()


## P3: avoidance only where it matters (an enemy unit near, a fight, the Bastion's crowd).
func _update_gate() -> void:
	var pos := unit.global_position
	var near := unit.attack_target != null or unit.has_enemy_within(GATE_RANGE)
	if not near and _bastion_alive():
		var b := bastion.global_position
		near = Vector2(b.x - pos.x, b.z - pos.z).length() <= GATE_RANGE + BASTION_REACH
	unit.set_avoidance_gated(not near)


## The point of waypoint `i` for this unit (lane point + its lateral offset); past the end = the Bastion.
func waypoint(i: int) -> Vector3:
	if i >= path.size():
		return bastion.global_position if _bastion_alive() else path[path.size() - 1]
	return path[i] + _side(i) * lateral


func _dir(i: int) -> Vector3:
	var a := path[maxi(i - 1, 0)]
	var b := path[mini(maxi(i, 1), path.size() - 1)]
	var d := b - a
	d.y = 0.0
	return d.normalized() if d.length() > 0.01 else Vector3.RIGHT


func _side(i: int) -> Vector3:
	var d := _dir(i)
	return Vector3(-d.z, 0.0, d.x)


func _bastion_alive() -> bool:
	return bastion != null and is_instance_valid(bastion) and bastion.has_method(&"is_alive") and bool(bastion.call(&"is_alive"))


## Distance from the unit to its own lane line (the polyline shifted by `lateral`), on the ground.
func off_lane() -> float:
	var p := Vector2(unit.global_position.x, unit.global_position.z)
	var best := INF
	for i in range(1, path.size()):
		var s := _side(i) * lateral
		var a := Vector2(path[i - 1].x + s.x, path[i - 1].z + s.z)
		var b := Vector2(path[i].x + s.x, path[i].z + s.z)
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b)))
	return best


func _nearest_lane_point() -> Vector3:
	var p := Vector2(unit.global_position.x, unit.global_position.z)
	var best := INF
	var out := waypoint(index)
	for i in range(1, path.size()):
		var s := _side(i) * lateral
		var a := Vector2(path[i - 1].x + s.x, path[i - 1].z + s.z)
		var b := Vector2(path[i].x + s.x, path[i].z + s.z)
		var c := Geometry2D.get_closest_point_to_segment(p, a, b)
		if p.distance_to(c) < best:
			best = p.distance_to(c)
			out = Vector3(c.x, 0.0, c.y)
	return out


func _issue() -> void:
	_goal = waypoint(index)
	unit.command_attack_move(_goal)


func _think(dt: float) -> void:
	var pos := unit.global_position
	var fighting := unit.attack_target != null
	# advance along the lane
	while index < path.size():
		var wp := waypoint(index)
		var to := Vector2(wp.x - pos.x, wp.z - pos.z)
		var d := _dir(mini(index + 1, path.size() - 1)) if index + 1 < path.size() else _dir(index)
		var past := index > 0 and Vector2(pos.x - wp.x, pos.z - wp.z).dot(Vector2(d.x, d.z)) > 0.0
		if to.length() <= ADVANCE_DIST or past:
			index += 1
			if not fighting and _return_left <= 0.0:
				_issue()
		else:
			break
	# the lane's end: the Bastion
	if index >= path.size() and not fighting and _bastion_alive() \
			and Vector2(bastion.global_position.x - pos.x, bastion.global_position.z - pos.z).length() <= BASTION_REACH:
		unit.set_auto_target(bastion)
		fighting = unit.attack_target != null
	# leash: too far off the lane line while fighting = walk back
	if fighting and _return_left <= 0.0 and off_lane() > leash:
		_return_left = LEASH_COOLDOWN
		_goal = _nearest_lane_point()
		unit.command_move(_goal)
		fighting = false
	elif _return_left <= 0.0 and not unit.is_attack_moving() and not fighting and _sidestep_left <= 0.0:
		_issue()   # back from a leash walk / a side-step / an arrived order: march on
	# no stall
	var moved := pos.distance_to(_stuck_ref)
	if fighting:
		_idle_for = 0.0
		_stuck_for = 0.0
		_no_progress = 0.0
		_stuck_ref = pos
		return
	var speed := Vector2(unit.velocity.x, unit.velocity.z).length()
	_idle_for = _idle_for + dt if speed < 0.2 else 0.0
	if _idle_for >= IDLE_REISSUE:
		_idle_for = 0.0
		_issue()
	_stuck_for += dt
	if _stuck_for >= STUCK_TIME:
		if moved < STUCK_DIST:
			_no_progress += _stuck_for
			var side := _side(mini(index, path.size() - 1)) * (SIDE_STEP if randf() < 0.5 else -SIDE_STEP)
			_goal = pos + side
			unit.command_move(_goal)
			_sidestep_left = 1.0
		else:
			_no_progress = 0.0
		_stuck_for = 0.0
		_stuck_ref = pos
	if _no_progress > longest_stall:
		longest_stall = _no_progress
	if _no_progress >= STALL_REPORT and not _reported:
		_reported = true
		stall_events += 1
