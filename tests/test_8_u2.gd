extends SceneTree
## 8.U2: minimap mission extras on mission 1 + a short scripted play (QA).
## Opens missions/mission_01.tscn with its briefing, clicks Begin (a real mouse event), walks Vessa and the
## army to Hearthward, then checks the minimap: 3 brazier markers, the caged peddler, flame lines once lit
## (Hearthward by Vessa, Westwatch by light()), the wave arrow when W2 spawns (group "scripted"), the
## freed peddler, and the objective pulse ring from rows with "positions" (fake mission rows: mission 1's
## objectives() has no positions yet).
## Run:  godot --headless --path . -s tests/test_8_u2.gd --fixed-fps 60 --quit-after 6000
## Windowed (no --headless): also saves user://8_u2_briefing.png, 8_u2_early.png, 8_u2_brazier.png, 8_u2_wave.png,
## 8_u2_ring.png. Headless, the Begin click misses (64 x 64 window) and the test falls back to begin().

const TASK_ID := "8.U2"
const TIMEOUT_FRAMES := 4000
const LIGHT_WAIT_FRAMES := 1500   # Vessa lights Hearthward herself; after this the test calls light()


class FakeObjectives extends Node:
	func objectives() -> Array:
		return [
			{id = &"obj_vessa", primary = true, state = "active"},
			{id = &"obj_braziers", primary = true, state = "active",
					positions = [Vector3(-44.0, 0.0, -20.0), Vector3(22.0, 0.0, 44.0)]},
			{id = &"sec_peddler", type = "secondary", state = "active", position = Vector3(-24.0, 0.0, -6.0)},
		]


var main: Node
var minimap: Node
var frame := 0
var _wait := 0
var step := 0
var step_frame := 0
var windowed := false
var clicked_begin := false
var lit_by_vessa := false
var _fake: Node
var _overlay_before := 0
var _errors: Array[String] = []


func _initialize() -> void:
	windowed = DisplayServer.get_name() != "headless"
	if not windowed:
		root.size = Vector2i(1600, 900)   # the headless window is 64 x 64: lay the UI out at the real size
	main = load("res://missions/mission_01.tscn").instantiate()
	main.set(&"save_campaign_on_victory", false)
	main.set(&"cinematics_enabled", false)   # the m1_* films freeze the tree (test_cine_m01 covers them)
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			return _finish("navigation never finished baking")
		return false
	frame += 1
	if frame > TIMEOUT_FRAMES:
		return _finish("timed out at step %d" % step)
	return _run()


func _next() -> void:
	step += 1
	step_frame = frame


func _check(cond: bool, what: String) -> void:
	if not cond:
		_errors.append(what)
		print("  x ", what)


func _run() -> bool:
	var since := frame - step_frame
	match step:
		0:   # the briefing is up and the game is paused
			var mh: Node = main.get(&"mission_hud")
			if mh == null:
				return _finish("no MissionHud attached")
			if since < 20:
				return false
			_check(bool(mh.call(&"is_briefing_open")), "briefing not open")
			_check(paused, "the briefing does not pause the game")
			minimap = main.hud.minimap
			_shot("briefing")
			_click_begin(mh)
			_next()
		1:   # Begin was clicked by a mouse event
			if since < 10:
				return false
			var mh: Node = main.get(&"mission_hud")
			if bool(mh.call(&"is_briefing_open")):
				print("  note: the mouse click did not press Begin, calling begin()")
				mh.get(&"briefing").call(&"begin")
				return false
			clicked_begin = since == 10
			_check(not paused, "still paused after Begin")
			_next()
		2:   # early game: markers drawn, no wave, no objective positions from mission 1
			if since < 60:
				return false
			_check(int(minimap.drawn_braziers) == 3, "braziers drawn: %d (want 3)" % minimap.drawn_braziers)
			_check(int(minimap.drawn_lit_braziers) == 0, "a brazier drawn lit at start")
			_check(int(minimap.drawn_flame_lines) == 0, "flame line before any brazier is lit")
			_check(String(minimap.drawn_peddler) == "caged", "peddler drawn '%s' (want caged)" % minimap.drawn_peddler)
			_check(int(minimap.wave_flash_count) == 0, "wave arrow flashed for the start guards")
			print("mission objective points: %d (mission 1 rows have no position yet)" % minimap.objective_points.size())
			_walk_to_hearthward()
			_next()
		3:   # walking: screenshot with objectives + dialogue
			if since == 150:
				main.camera_rig.focus_on(main.hero.global_position)
				_shot("early")
			var b: Node = main.brazier(&"hearthward")
			if bool(b.get(&"lit")):
				lit_by_vessa = true
				_next()
			elif since > LIGHT_WAIT_FRAMES:
				print("  note: Vessa did not light Hearthward in time (hero at %s), calling light()" % main.hero.global_position)
				b.call(&"light")
				_next()
			elif since % 120 == 60 and main.hero.is_alive():
				main.hero.command_move(b.global_position + Vector3(-0.9, 0.0, 0.9))
		4:   # one flame line
			if since < 20:
				return false
			_check(int(minimap.drawn_lit_braziers) == 1, "lit braziers drawn: %d (want 1)" % minimap.drawn_lit_braziers)
			_check(int(minimap.drawn_flame_lines) == 1, "flame lines drawn: %d (want 1)" % minimap.drawn_flame_lines)
			main.camera_rig.focus_on(main.brazier(&"hearthward").global_position)
			if since < 50:
				return false
			_shot("brazier")
			_overlay_before = int(minimap.wave_flash_count)
			main.brazier(&"westwatch").call(&"light")   # E5: W2 spawns (scripted Shadow units)
			_next()
		5:   # the wave arrow flashes toward the Gloom Hall
			if int(minimap.wave_flash_count) == _overlay_before and since < 90:
				return false
			_check(int(minimap.wave_flash_count) == _overlay_before + 1, "no wave flash after W2 spawned")
			_check(float(minimap.wave_flash_left) > 0.0, "wave arrow not flashing")
			var from: Vector3 = minimap.wave_from
			_check(from.x > 0.0 and from.z < 0.0, "wave comes from %s (want the Shadow side x > 0, z < 0)" % from)
			_check(int(minimap.drawn_flame_lines) == 2, "flame lines drawn: %d (want 2)" % minimap.drawn_flame_lines)
			_overlay_before = int(minimap.overlay_draws)
			_next()
		6:
			if since < 20:
				return false
			_check(int(minimap.overlay_draws) >= _overlay_before + 15, "overlay not redrawn while flashing")
			_shot("wave")
			main.pell.open_cage()
			_fake = FakeObjectives.new()
			minimap.mission = _fake
			_next()
		7:   # freed peddler + pulse ring on the first active primary with positions
			if since < 40:
				return false
			_check(String(minimap.drawn_peddler) == "free", "peddler drawn '%s' after open_cage (want free)" % minimap.drawn_peddler)
			var pts: Array = minimap.objective_points
			_check(pts.size() == 2 and pts[0] == Vector3(-44.0, 0.0, -20.0), "objective points %s" % [pts])
			_overlay_before = int(minimap.overlay_draws)
			_next()
		8:
			if since < 30:
				return false
			_check(int(minimap.overlay_draws) >= _overlay_before + 25, "objective ring not animated")
			_shot("ring")
			minimap.mission = main
			_fake.free()
			_next()
		9:
			if since < 40:
				return false
			_check(minimap.objective_points.is_empty(), "ring still shown with the real mission rows")
			print("begin clicked by mouse=%s, Hearthward lit by Vessa=%s" % [clicked_begin, lit_by_vessa])
			return _finish("")
	return false


func _click_begin(mh: Node) -> void:
	var br: Node = mh.get(&"briefing")
	var button := br.get(&"begin_button") as Control
	# Viewport-local pixels (1600 x 900 canvas), pushed with in_local_coords = true: the headless window
	# is only 64 x 64, so window pixels could not reach the button.
	var at: Vector2 = button.get_global_transform_with_canvas() * (button.size * 0.5)
	var move := InputEventMouseMotion.new()
	move.position = at
	move.global_position = at
	root.push_input(move, true)
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		ev.pressed = pressed
		ev.position = at
		ev.global_position = at
		root.push_input(ev, true)
	print("clicked Begin at %s (window %s)" % [at, root.size])


func _walk_to_hearthward() -> void:
	var b: Node3D = main.brazier(&"hearthward")
	var spot := b.global_position + Vector3(-0.9, 0.0, 0.9)
	for node in get_nodes_in_group("units"):
		var u := node as Node3D
		if u == null or int(u.get(&"team")) != 0 or u.has_method(&"command_gather"):
			continue
		if u == main.hero:
			u.call(&"command_move", spot)
		else:
			u.call(&"command_attack_move", b.global_position + Vector3(2.0, 0.0, -2.0))


func _shot(tag: String) -> void:
	if not windowed:
		return
	var img := root.get_texture().get_image()
	var path := ProjectSettings.globalize_path("user://8_u2_%s.png" % tag)
	img.save_png(path)
	print("screenshot: " + path)


func _finish(error: String) -> bool:
	if error != "":
		_errors.append(error)
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	return true
