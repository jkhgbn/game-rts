extends SceneTree
## Campaign review 2026-10-16 (part3.md "ending"): ep8_ending_b's "Nobody sits. Not ever again." is said by the player's
## wizard on each of the four roads (shot `branch=` flags e8_road_<k>), and the player's own fate shot plays last; the
## ep8 credits roll lasts about 1:30 (ROLL_SECONDS), lists the four wizards with the player's road last, and Esc / a
## click skip it to the end panel.
## Run:  godot --headless --path . -s tests/test_cr_ending.gd --fixed-fps 60 --quit-after 9000

const TASK_ID := "cr_ending"
const SAVE := "user://test_cr_ending.json"
const FILM := &"ep8_ending_b"
const CREDITS := "res://missions/ep8_credits.tscn"
## road -> [speaker of the turn line, the shot ids in play order]
const ROADS := {
	&"fire": [&"vessa", [&"E15V", &"E15", &"E16", &"E17", &"E18", &"E18B", &"E19", &"E20", &"E21", &"E22"]],
	&"shadow": [&"malrik", [&"E15M", &"E15", &"E16", &"E17", &"E18", &"E18B", &"E20", &"E19L", &"E21", &"E22"]],
	&"ice": [&"torvald", [&"E15T", &"E15", &"E16", &"E18", &"E18B", &"E19", &"E20", &"E17L", &"E21", &"E22"]],
	&"nature": [&"ysolde", [&"E15Y", &"E15", &"E16", &"E17", &"E19", &"E20", &"E18L", &"E18BL", &"E21", &"E22"]],
}

var fails: Array[String] = []
var step := 0
var step_frame := 0
var frame := 0
var screen: Node


func _check(cond: bool, what: String) -> void:
	if not cond:
		fails.append(what)


func _initialize() -> void:
	CampaignState.default_path = SAVE
	CampaignState.open(SAVE).reset()


func _set_road(k: StringName) -> void:
	var cs := CampaignState.open(SAVE)
	var flags := {"e8_road": MissionE8Base.road_index(k)}
	for r: StringName in ROADS:
		flags["e8_road_%s" % r] = r == k
	cs.set_flags(flags)
	cs.save()


func _check_film() -> void:
	var script := CinematicScript.find(FILM)
	if script == null:
		fails.append("no baked %s" % FILM)
		return
	var ctx := Node3D.new()
	root.add_child(ctx)
	for k: StringName in ROADS:
		_set_road(k)
		var p := CinematicPlayer.new()
		p.use_overlay = false
		p.emit_events = false
		p.log_enabled = false
		root.add_child(p)
		var err := p.play(script, ctx)
		if err != "":
			fails.append("%s play: %s" % [k, err])
			p.queue_free()
			continue
		p.seek(3.0)
		var line: Dictionary = p.debug_state()["line"]
		var want: StringName = ROADS[k][0]
		_check(StringName(line.get("speaker", &"")) == want and String(line.get("text", "")) == "Nobody sits. Not ever again.",
				"%s road: the turn line is %s, want %s" % [k, str(line), want])
		var total := float(p.debug_state()["total"])
		_check(total >= 64.0 and total <= 70.0, "%s road: film %.1f s, want 64..70" % [k, total])
		var ids: Array[StringName] = []
		var t := 0.05
		while t < total:
			p.seek(t)
			var sid := StringName(p.debug_state()["shot_id"])
			if ids.is_empty() or ids[-1] != sid:
				ids.append(sid)
			t += 0.5
		var want_ids: Array = ROADS[k][1]
		_check(str(ids) == str(want_ids), "%s road: shots %s, want %s" % [k, str(ids), str(want_ids)])
		p.stop()
		p.queue_free()
	ctx.queue_free()


func _new_credits() -> Node:
	var c := (load(CREDITS) as PackedScene).instantiate()
	c.set(&"save_path", SAVE)
	root.add_child(c)
	return c


func _key(code: Key) -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventKey.new()
		ev.physical_keycode = code
		ev.keycode = code
		ev.pressed = pressed
		root.push_input(ev)


func _click() -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.position = Vector2(400, 300)
		ev.global_position = ev.position
		ev.pressed = pressed
		root.push_input(ev)


func _process(_d: float) -> bool:
	frame += 1
	step_frame += 1
	if frame > 8500:
		fails.append("timed out at step %d" % step)
		return _end()
	match step:
		0:
			if step_frame < 2:
				return false
			_check_film()
			_check(E8StoryScreen.ROLL_SECONDS >= 80.0 and E8StoryScreen.ROLL_SECONDS <= 100.0,
					"credits roll %.0f s, want about 90" % E8StoryScreen.ROLL_SECONDS)
			for k: StringName in ROADS:
				var order := E8StoryScreen.roll_order(k)
				_check(order.size() == 4 and order[-1] == k, "roll order for %s: %s" % [k, str(order)])
				_check(E8StoryScreen.relic_name(k) != "", "relic name of %s" % k)
			_set_road(&"ice")
			screen = _new_credits()
			_next()
		1:   # Esc skips
			if step_frame == 3:
				_check(bool(screen.call(&"is_rolling")), "the credits roll at start")
				_key(KEY_ESCAPE)
			if step_frame < 6:
				return false
			_check(not bool(screen.call(&"is_rolling")), "Esc did not skip the credits")
			_check(CampaignState.open(SAVE).is_seen(&"ep8_credits"), "skipped credits not marked seen")
			screen.queue_free()
			screen = _new_credits()
			_next()
		2:   # a click skips
			if step_frame == 3:
				_check(bool(screen.call(&"is_rolling")), "the second roll rolls")
				_click()
			if step_frame < 6:
				return false
			_check(not bool(screen.call(&"is_rolling")), "a click did not skip the credits")
			screen.queue_free()
			screen = _new_credits()
			_next()
		3:   # the full roll: still rolling at ROLL_SECONDS - 3, the end panel by ROLL_SECONDS + 1
			var rt := float(screen.call(&"roll_time"))
			var rolling := bool(screen.call(&"is_rolling"))
			if rolling and rt > E8StoryScreen.ROLL_SECONDS + 0.5:
				fails.append("the roll outlived ROLL_SECONDS")
				return _end()
			if not rolling:
				_check(step_frame >= int((E8StoryScreen.ROLL_SECONDS - 3.0) * 60.0),
						"the roll ended after %d frames, want about %d" % [step_frame, int(E8StoryScreen.ROLL_SECONDS * 60.0)])
				return _end()
	return false


func _next() -> void:
	step += 1
	step_frame = 0


func _end() -> bool:
	CampaignState.open(SAVE).reset()
	CampaignState.default_path = ""
	for p: String in [SAVE, SAVE + ".bak", SAVE + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	if fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for f in fails:
			print("  x ", f)
		print("FAIL %s: %s" % [TASK_ID, fails[0]])
	return true
