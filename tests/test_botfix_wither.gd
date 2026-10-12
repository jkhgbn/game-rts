extends SceneTree
## R3-1 (code-review-2026-10-12): Wither Hex's -20 % attack modifier is removed after its duration at Blitz pace
## (Engine.time_scale 1.3) and at normal pace; a re-cast before expiry extends it (the first timer leaves the new
## cast alone); the timer is safe when the target was freed.
## Run:  godot --headless --path . -s tests/test_botfix_wither.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "botfix_wither"
const TIMEOUT_FRAMES := 2400

var main: Node
var frame := 0
var _wait := 0
var _started := false
var _done := false
var _errors: Array[String] = []


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
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
		Engine.time_scale = 1.0
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return true
	if frame > TIMEOUT_FRAMES:
		Engine.time_scale = 1.0
		print("FAIL %s: timed out; %s" % [TASK_ID, "; ".join(_errors)])
		return true
	return false


func _check(ok: bool, what: String) -> void:
	if not ok:
		_errors.append(what)
		print("  x " + what)


func _game_wait(seconds: float) -> void:
	await create_timer(seconds, false, true).timeout


func _spawn() -> Unit:
	var u := UnitType.find("shadow_knight").create_unit()
	u.team = Unit.Team.PLAYER
	u.aggro_range = 0.0
	main.add_child(u)
	u.global_position = main.hero.global_position + Vector3(3.0, 0, 3.0)
	return u


func _run() -> void:
	var t := float(NewUnits12.WITHER_HEX["time"])
	for scale: float in [1.3, 1.0]:
		Engine.time_scale = scale
		var u := _spawn()
		await _game_wait(0.1)
		var dmg0 := u.attack_damage
		NewUnits12.apply_withered(u, t)
		_check(u.has_modifier(NewUnits12.WITHER_MOD), "scale %.1f: modifier not applied" % scale)
		_check(is_equal_approx(u.attack_damage, dmg0 * 0.8), "scale %.1f: damage %.1f want %.1f"
				% [scale, u.attack_damage, dmg0 * 0.8])
		await _game_wait(t - 0.5)
		_check(u.has_modifier(NewUnits12.WITHER_MOD), "scale %.1f: modifier gone early" % scale)
		await _game_wait(0.7)
		_check(not u.has_modifier(NewUnits12.WITHER_MOD), "scale %.1f: modifier still there after %.1f s" % [scale, t])
		_check(is_equal_approx(u.attack_damage, dmg0), "scale %.1f: damage not restored (%.1f)" % [scale, u.attack_damage])
		var now := float(Engine.get_physics_frames()) / float(maxi(1, Engine.physics_ticks_per_second))
		_check(float(u.get_meta(NewUnits12.WITHER_META, 0.0)) <= now,
				"scale %.1f: unit still marked withered after expiry (can't be hexed again)" % scale)
		_check(not String(NewUnits12.WITHER_META).begins_with("nu12") and String(NewUnits12.WITHER_META).begins_with("_")
				and String(NewUnits12.WITHER_SERIAL_META).begins_with("_"), "wither metas must start with _ (not saved)")
		u.queue_free()

	# Re-cast before expiry (Blitz pace): the first timer must not remove the second cast's modifier.
	Engine.time_scale = 1.3
	var r := _spawn()
	await _game_wait(0.1)
	NewUnits12.apply_withered(r, t)
	await _game_wait(3.0)
	NewUnits12.apply_withered(r, t)
	await _game_wait(t - 3.0 + 0.5)   # first timer has fired
	_check(r.has_modifier(NewUnits12.WITHER_MOD), "re-cast: first timer removed the refreshed modifier")
	await _game_wait(3.0)   # 6.5 s after the re-cast
	_check(not r.has_modifier(NewUnits12.WITHER_MOD), "re-cast: modifier still there after the second duration")
	r.queue_free()

	# Freed target: the timer must not crash.
	var f := _spawn()
	await _game_wait(0.1)
	NewUnits12.apply_withered(f, 1.0)
	f.queue_free()
	await _game_wait(1.5)
	Engine.time_scale = 1.0
	_done = true
