extends SceneTree
## Determinism guard (root-cause pass 2026-10-16, docs/ci/playtest-2026-10-16/ci.md): gameplay must never read a
## model's animated pose. The art models seed their animation phase from hash(get_instance_id()), so one extra Object
## created anywhere (a cosmetic commit: a cached HP-bar material) shifted the bow-tip pose, a shot's flight time, the
## frame a unit died and the whole e3m2 / e2m2 / e7m4 / e8m3 mission sims. Here the same ranged fight runs twice in
## one process several times, with extra Objects created before some rounds (every instance id differs each round):
## each shooter's hits must land on the same frames (relative to the fight start) with the same damage. Round 0 is a
## warm-up (the first fight in a fresh scene lands one ember_archer hit a frame later, with or without extra Objects:
## a history effect, not an instance-id one); rounds 2+ are compared with round 1. A small pose offset rarely moves a
## hit across a frame boundary, so every shot is also checked directly: its gameplay start (Projectile._start) is the
## shooter's fixed chest point, never a model point (the bow tip / staff only moves the drawn shot).
## Run:  godot --headless --path . -s tests/test_det_model_pose.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "det_model_pose"
const SCENE := "res://scenes/skirmish.tscn"
const PLAYER := 0
const ENEMY := 1
const TIMEOUT_FRAMES := 4000
const FIGHT_FRAMES := 420
## Shooters with a model that gives a shot origin (bow tip) and plain ranged soldiers.
const SHOOTERS := ["wildwood_archer", "scorchbow", "frostbow", "bleakbow", "ember_archer", "burr_slinger"]
const PADS := [0, 0, 7, 1]   # extra Objects created before each round (round 0 = warm-up, round 1 = reference)

var main: Node
var frame := 0
var _wait := 0
var _started := false
var _done := false
var _errors: Array[String] = []
var _pad: Array = []
var _log: Array[String] = []
var _t0 := 0
var _shots: Array = []   # projectiles launched this round, checked one frame later
var _shooters: Dictionary = {}   # shooter -> its id
var _starts_checked := 0


func _initialize() -> void:
	main = load(SCENE).instantiate()
	main.camps_enabled = false
	main.beasts_enabled = false
	main.child_entered_tree.connect(_on_child)
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	if frame == 5 and not _started:
		_started = true
		_run()
	if _done:
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out; %s" % [TASK_ID, "; ".join(_errors)])
		return true
	return false


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _run() -> void:
	var keep: Node3D = main.keep
	var dir := -Vector3(keep.global_position.x, 0.0, keep.global_position.z).normalized()
	var side := dir.cross(Vector3.UP)
	var spot := keep.global_position + dir * 22.0
	var rounds: Array = []
	for r in PADS.size():
		for k in int(PADS[r]):
			_pad.append(RefCounted.new())
		rounds.append(await _fight(spot, dir, side))
	var counted := 0
	for r in range(2, rounds.size()):
		var a: Array = rounds[1]
		var b: Array = rounds[r]
		if a != b:
			var i := 0
			while i < mini(a.size(), b.size()) and a[i] == b[i]:
				i += 1
			_errors.append("round %d (%d extra objects) differs at hit %d: %s vs %s" % [r, int(PADS[r]),
					i, a[i] if i < a.size() else "-", b[i] if i < b.size() else "-"])
			print("  round 1: %s\n  round %d: %s" % [", ".join(PackedStringArray(a)), r, ", ".join(PackedStringArray(b))])
	if _starts_checked < SHOOTERS.size() * 3:
		_errors.append("only %d shot starts checked" % _starts_checked)
	counted = (rounds[1] as Array).size()
	if counted < SHOOTERS.size() * 3:
		_errors.append("only %d hits in round 1 (shooters did not fight)" % counted)
	print("  %d hits per round, %d rounds, %d shot starts checked" % [counted, rounds.size(), _starts_checked])
	_done = true


## One fight: each shooter vs a 5000 HP dummy 7 m away (in range, no walking). Returns the sorted hit rows
## "shooter frame damage", frames counted from the fight start.
func _fight(spot: Vector3, dir: Vector3, side: Vector3) -> Array:
	_log = []
	var nodes: Array = []
	var pairs: Array = []
	while Engine.get_physics_frames() % 60 != 0:   # same frame phase every round (scan buckets, staggers)
		await physics_frame
	var i := 0
	for id: String in SHOOTERS:
		var t := UnitType.find(id)
		if t == null:
			_errors.append("missing unit type %s" % id)
			continue
		var base := spot + side * (-12.5 + 5.0 * i)
		var s := t.create_unit()
		s.team = PLAYER as Unit.Team
		main.add_child(s)
		_shooters[s] = id
		s.global_position = base
		var d := _dummy(base + dir * 7.0)
		nodes.append(s)
		nodes.append(d)
		pairs.append([s, d])
		d.damage_taken.connect(_on_hit.bind(id))
		i += 1
	await _frames(2)
	_t0 = Engine.get_physics_frames()
	for p: Array in pairs:
		(p[0] as Unit).command_attack(p[1] as Unit)
	for f in FIGHT_FRAMES:
		await physics_frame
		_check_starts()
	_shooters.clear()
	for n in nodes:
		if is_instance_valid(n):
			n.queue_free()
	for b in get_nodes_in_group(&"projectiles"):
		b.queue_free()
	await _frames(30)
	var out := _log.duplicate()
	out.sort()
	return out


func _on_child(n: Node) -> void:
	if n is Projectile:
		_shots.append(n)


## Every shot of a shooter starts (for gameplay) at its chest point: global_position + UP * body_height * 0.75.
func _check_starts() -> void:
	for b: Variant in _shots:
		if not is_instance_valid(b):
			continue
		var p := b as Projectile
		if not _shooters.has(p.source):
			continue
		var u := p.source as Unit
		var want := u.global_position + Vector3.UP * u.body_height * 0.75
		var got: Vector3 = p.get(&"_start")
		_starts_checked += 1
		if got.distance_to(want) > 0.01 and _errors.size() < 8:
			_errors.append("%s shot starts at %s, not its chest point %s (a model pose feeds the flight time)"
					% [_shooters[p.source], got, want])
	_shots.clear()


func _on_hit(amount: float, attacker: Node3D, id: String) -> void:
	if attacker == null:
		return
	_log.append("%s f%04d %.2f" % [id, Engine.get_physics_frames() - _t0, amount])


## A punching bag: 5000 HP, no fighting back, never auto-targeted by others, never walks (the enemy bot orders its
## team's units; a walking target adds avoidance noise that has nothing to do with the model pose).
func _dummy(pos: Vector3) -> Unit:
	var u := Unit.new()
	u.team = ENEMY as Unit.Team
	u.max_hp = 5000.0
	u.aggro_range = 0.0
	u.attack_damage = 0.0
	u.move_speed = 0.0
	main.add_child(u)
	u.global_position = pos
	u.command_hold()
	u.hide_from_auto_target(9999.0)
	return u
