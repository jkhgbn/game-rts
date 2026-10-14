extends SceneTree
## MU14 (docs/design/music.md 4): combat intensity (GameAudio, every 0.5 s) and the drive stem curve.
## A quiet skirmish (bot off): after 20 s the intensity stays < 0.15 and the drive is silent. Then 12 enemy shades
## at the player's keep: intensity >= 0.75 within 3 s, and the drive reaches 0 dB.
## Run: godot --headless --path . -s tests/test_mu14.gd --fixed-fps 60 --quit-after 4000

const TASK_ID := "mu14"
const TIMEOUT_FRAMES := 3600

var main: Node
var md: Node = null
var frame := 0
var _wait := 0
var _phase := 0
var _phase_frame := 0
var _hit_frame := -1


func _initialize() -> void:
	main = load("res://scenes/skirmish.tscn").instantiate()
	var bot: Node = main.get_node_or_null("ShadowBot")
	if bot:
		bot.set("enabled", false)
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.get(&"hero") == null:
		_wait += 1
		return _wait > 5000 and _fail("map never ready")
	frame += 1
	if frame > TIMEOUT_FRAMES:
		return _fail("timed out in phase %d (intensity %.2f, drive %.1f dB)" % [_phase,
				float(md.call(&"combat_intensity")) if md else -1.0, float(md.call(&"drive_db")) if md else 0.0])
	if md == null:
		md = root.get_node_or_null(^"MusicDirector")
		return md == null and frame > 30 and _fail("no /root/MusicDirector in a skirmish")
	var t := frame - _phase_frame
	var inten := float(md.call(&"combat_intensity"))
	var drive := float(md.call(&"drive_db"))
	match _phase:
		0:   # empty map: 20 s of calm -> drive silent
			if inten >= 0.15:
				return _fail("quiet map: intensity %.2f at %.1f s" % [inten, t / 60.0])
			if t >= 20 * 60:
				if drive > -79.0:
					return _fail("quiet map: drive at %.1f dB after 20 s, expected silent" % drive)
				print("  quiet 20 s: intensity %.2f, drive %.1f dB (silent)" % [inten, drive])
				_spawn_raid()
				_next()
		1:   # 12 enemies at the keep
			if inten >= 0.75 and _hit_frame < 0:
				_hit_frame = t
				print("  12 enemies: intensity %.2f after %.2f s" % [inten, t / 60.0])
			if _hit_frame < 0 and t > 3 * 60:
				return _fail("intensity %.2f after 3 s (raw %.2f), expected >= 0.75" % [inten,
						_raw()])
			if _hit_frame >= 0 and drive >= -0.5:
				print("  drive at %.1f dB after %.2f s" % [drive, t / 60.0])
				print("PASS %s" % TASK_ID)
				return true
			if t > 6 * 60:
				return _fail("drive at %.1f dB 6 s into the raid (intensity %.2f)" % [drive, inten])
	return false


func _spawn_raid() -> void:
	var keep: Node3D = null
	for b in get_nodes_in_group(&"buildings"):
		if b is Keep and int(b.get(&"team")) == 0:
			keep = b
			break
	if keep == null:
		_fail("no player keep")
		return
	for i in 12:
		var a := TAU * i / 12.0
		var u: Node = main.call(&"make_unit", "shade")
		main.call(&"_spawn", u, 1, keep.global_position + Vector3(cos(a), 0.0, sin(a)) * 9.0)


func _raw() -> float:
	for c in main.get_children():
		if c.has_method(&"measure_intensity"):
			return float(c.get(&"last_intensity"))
	return -1.0


func _next() -> void:
	_phase += 1
	_phase_frame = frame


func _fail(why: String) -> bool:
	print("FAIL %s: %s" % [TASK_ID, why])
	return true
