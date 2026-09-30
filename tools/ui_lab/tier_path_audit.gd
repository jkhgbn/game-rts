extends SceneTree
## TIER PATH AUDIT (2026-09-30, JS: "not sure there is a way to tier up / get better units"): plays the new-player path
## Keep -> Stronghold -> Citadel in a real skirmish for each kingdom, then looks at every campaign mission, and writes
## what the player sees at each step (the Next hint, the tier chip, the keep / Hall cards: keys, reasons, tooltips, the
## messages) plus a screenshot of each step (windowed runs only).
## Run (windowed, for the screenshots):
##   & tools/godot_run.ps1 --path . -s res://tools/ui_lab/tier_path_audit.gd --quit-after 400000 '--' 'out=res://docs/ui/tier_audit/after'
## Args after `--` (key=value): kingdoms (default fire,shadow,ice,nature), missions (1 = look at the missions, default 1),
## out (default res://docs/ui/tier_audit), timescale (default 8), res (default 1600x900).
## Exit code 0 = every kingdom reached the Citadel and saw its tier-2 / tier-3 units; 1 = a step failed (FAIL lines).

const WATCHDOG_S := 1500.0
const MISSIONS := ["res://missions/mission_01.tscn"]

var out_dir := "res://docs/ui/tier_audit"
var timescale := 8.0
var headless := false
var lines: Array[String] = []
var fails: Array[String] = []
var shot_paths: Array[String] = []


func _initialize() -> void:
	_main.call_deferred()


func _main() -> void:
	create_timer(WATCHDOG_S, true, false, true).timeout.connect(func() -> void:
		print("TIER AUDIT ERROR: watchdog")
		Engine.time_scale = 1.0
		quit(3))
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=", true, 1)
		if kv.size() == 2:
			args[kv[0]] = kv[1]
	var kingdoms := String(args.get("kingdoms", "fire,shadow,ice,nature")).split(",", false)
	out_dir = String(args.get("out", out_dir))
	timescale = float(args.get("timescale", "8"))
	headless = DisplayServer.get_name() == "headless"
	GameSettings.ensure_loaded(self)
	StrIntPath.force_auto = true   # the STR / INT pick pauses the match until clicked: auto-pick here
	GameSettings.fullscreen = false
	GameSettings.apply_window(self)
	var res := String(args.get("res", "1600x900")).split("x")
	if not headless:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	root.size = Vector2i(int(res[0]), int(res[1]))
	await _frames(8)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	for k in kingdoms:
		await _audit_skirmish(StringName(k))
	if String(args.get("missions", "1")) == "1":
		for m in MISSIONS:
			await _audit_mission(m)
	Engine.time_scale = 1.0
	paused = false
	var f := FileAccess.open(ProjectSettings.globalize_path(out_dir.path_join("audit.txt")), FileAccess.WRITE)
	if f:
		f.store_string("\n".join(lines) + "\n")
		f.close()
	for fl in fails:
		print("FAIL ", fl)
	print("TIER AUDIT %s (%d fails) -> %s" % ["PASS" if fails.is_empty() else "FAIL", fails.size(), out_dir])
	quit(0 if fails.is_empty() else 1)


# ---------------------------------------------------------------- skirmish

func _audit_skirmish(k: StringName) -> void:
	_log("")
	_log("=== SKIRMISH %s (vs %s, easy bot)" % [k, "fire" if k == &"shadow" else "shadow"])
	NextStepHint.dismissed = false
	var level := MenuFlow.start_skirmish(self, 0, &"fire" if k == &"shadow" else &"shadow", k)
	if not await _wait_started(level):
		_fail("%s: the skirmish never started" % k)
		return
	var sel: SelectionManager = level.get(&"selection")
	var hud: Node = level.get(&"hud")
	await _frames(10)
	_log_state(level, "start")
	await _shot("%s_00_start" % k)
	var keep: Keep = level.call(&"keep_of", Unit.Team.PLAYER)
	sel.select_building(keep)
	await _frames(6)
	_log_card(level, "keep card at 0:0x")
	await _shot("%s_01_keep_t1" % k)
	# A Hall (what the Next hint asks for first), finished at once.
	await _run_to(level, 45.0)
	var hall := _spawn_hall(level, k)
	if hall == null:
		_fail("%s: could not place a Hall" % k)
		return
	await _run_to(level, 200.0)
	sel.select_building(keep)
	await _frames(6)
	_log_state(level, "3:20 (Hall done)")
	_log_card(level, "keep card at 3:20")
	await _shot("%s_02_keep_320" % k)
	await _run_to(level, 212.0)
	_eco(level).add(600)
	await _frames(20)
	_log_state(level, "3:32 (Stronghold due)")
	_log_card(level, "keep card at 3:32")
	await _shot("%s_03_keep_332" % k)
	# X on the keep card (the physical key, like the player).
	sel.select_building(keep)
	await _frames(2)
	await _press(KEY_X)
	if not keep.is_upgrading():
		_fail("%s: X on the keep did not start the Stronghold (%s)" % [k, keep.can_upgrade()])
		return
	_log("X pressed: upgrading to Stronghold (%.0f s)" % keep.upgrade_time_left())
	_log_state(level, "upgrading")
	await _shot("%s_04_upgrading" % k)
	await _run_until(level, func() -> bool: return keep.tier >= 2, 90.0)
	await _frames(4)
	_log("after the Stronghold: message '%s'" % _message(hud))
	_log_state(level, "Stronghold done")
	await _shot("%s_05_stronghold_done" % k)
	sel.select_building(hall)
	await _frames(6)
	_log_card(level, "Hall card at the Stronghold")
	var t2 := _open_types(hall, 2)
	_log("Hall tier-2 units open: %s" % ", ".join(t2))
	if t2.is_empty():
		_fail("%s: no tier-2 unit open on the Hall at the Stronghold" % k)
	await _shot("%s_06_hall_t2" % k)
	sel.select_building(keep)
	await _frames(6)
	_log_card(level, "keep card at the Stronghold")
	var caster := CasterKit.caster_for(k)
	if caster != &"" and keep.can_queue(UnitType.find(String(caster))) != "":
		_fail("%s: the caster %s is not open at the Stronghold (%s)" % [k, caster, keep.can_queue(UnitType.find(String(caster)))])
	await _shot("%s_07_keep_t2" % k)
	# Citadel.
	await _run_to(level, 347.0)
	_eco(level).add(800)
	sel.select_building(keep)
	await _frames(20)
	_log_state(level, "5:47 (Citadel due)")
	_log_card(level, "keep card at 5:47")
	await _shot("%s_08_keep_547" % k)
	await _press(KEY_X)
	if not keep.is_upgrading():
		_fail("%s: X did not start the Citadel (%s)" % [k, keep.can_upgrade()])
		return
	await _run_until(level, func() -> bool: return keep.tier >= 3, 120.0)
	await _frames(4)
	_log("after the Citadel: message '%s'" % _message(hud))
	sel.select_building(keep)
	await _frames(6)
	_log_state(level, "Citadel done")
	_log_card(level, "keep card at the Citadel")
	var t3 := _open_types(keep, 3)
	_log("keep tier-3 content open: %s" % ", ".join(t3))
	if t3.is_empty():
		_fail("%s: no tier-3 unit open on the keep at the Citadel" % k)
	await _shot("%s_09_keep_t3" % k)
	Engine.time_scale = 1.0


# ---------------------------------------------------------------- missions

func _audit_mission(path: String) -> void:
	_log("")
	_log("=== MISSION %s (normal)" % path)
	NextStepHint.dismissed = false
	var level: Node = (load(path) as PackedScene).instantiate()
	if &"show_briefing" in level:
		level.set(&"show_briefing", false)
	if &"save_campaign_on_victory" in level:
		level.set(&"save_campaign_on_victory", false)
	MenuFlow.difficulty = 1
	MenuFlow._launch(self, level, 1)
	if not await _wait_started(level):
		_fail("%s never started" % path)
		return
	await _frames(10)
	var sel: SelectionManager = level.get(&"selection")
	var keep: Keep = level.get(&"keep")
	_log("TierSystem in this mission: %s" % ("yes" if TierSystem.instance() != null else "NO"))
	_log_state(level, "start")
	sel.select_building(keep)
	await _frames(6)
	_log_card(level, "keep card at the start")
	await _shot("%s_00_keep" % path.get_file().get_basename())
	var hall: Node3D = level.get(&"ember_hall") if &"ember_hall" in level else null
	if hall:
		sel.select_building(hall)
		await _frames(6)
		_log_card(level, "Hall card at the start")
		await _shot("%s_01_hall" % path.get_file().get_basename())
	# Past the Stronghold time (the Hall is pre-built): is there any way up?
	await _run_to(level, 215.0)
	_eco(level).add(400)
	sel.select_building(keep)
	await _frames(20)
	_log_state(level, "3:35")
	_log_card(level, "keep card at 3:35")
	await _shot("%s_02_keep_335" % path.get_file().get_basename())
	var ts := TierSystem.instance()
	if ts == null:
		_log("RESULT: no TierSystem: no Stronghold button, the Hall lists only its mission units")
	else:
		await _press(KEY_X)
		_log("X on the keep: upgrading=%s (%s)" % [keep.is_upgrading(), keep.can_upgrade()])
		if keep.is_upgrading():
			await _run_until(level, func() -> bool: return keep.tier >= 2, 90.0)
			await _frames(4)
			_log("after the Stronghold: message '%s'" % _message(level.get(&"hud")))
			if hall:
				sel.select_building(hall)
				await _frames(6)
				_log_card(level, "Hall card at the Stronghold")
				_log("Hall tier-2 units open: %s" % ", ".join(_open_types(hall, 2)))
				await _shot("%s_03_hall_t2" % path.get_file().get_basename())
			sel.select_building(keep)
			await _frames(6)
			_log_card(level, "keep card at the Stronghold")
			await _shot("%s_04_keep_t2" % path.get_file().get_basename())
	_log("mission over? game_over=%s" % str(level.get(&"game_over")))
	Engine.time_scale = 1.0


# ---------------------------------------------------------------- helpers

func _wait_started(level: Node) -> bool:
	var t := Time.get_ticks_msec()
	while not bool(level.get(&"match_started")):
		await process_frame
		if Time.get_ticks_msec() - t > 120000:
			return false
	return true


func _run_to(level: Node, t: float) -> void:
	Engine.time_scale = timescale
	var t0 := Time.get_ticks_msec()
	while is_instance_valid(level) and float(level.call(&"match_time")) < t:
		await process_frame
		if Time.get_ticks_msec() - t0 > 240000:
			_fail("clock stuck at %.0f" % float(level.call(&"match_time")))
			break
	Engine.time_scale = 1.0


func _run_until(level: Node, cond: Callable, max_s: float) -> void:
	var end := float(level.call(&"match_time")) + max_s
	Engine.time_scale = timescale
	while is_instance_valid(level) and not bool(cond.call()) and float(level.call(&"match_time")) < end:
		await process_frame
	Engine.time_scale = 1.0


func _press(code: Key) -> void:
	for pressed in [true, false]:
		var ev := InputEventKey.new()
		ev.physical_keycode = code
		ev.keycode = code
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await _frames(3)


func _eco(level: Node) -> Economy:
	return level.get(&"economy")


func _spawn_hall(level: Node, k: StringName) -> Building:
	var t := NextStepHint.building_of(k, &"barracks")
	var grid: BuildGrid = level.get(&"build_grid")
	var center: Vector3 = level.call(&"base_center", Unit.Team.PLAYER)
	for r in [10.0, 13.0, 16.0, 19.0]:
		for i in 12:
			var a := TAU * float(i) / 12.0
			var p := grid.snap(center + Vector3(cos(a), 0.0, sin(a)) * r, t.footprint)
			if grid.check(t, p, Unit.Team.PLAYER) == "":
				return grid.spawn_complete(t, p, Unit.Team.PLAYER)
	return null


## Names of the building's trainable types of tier `tier` that can be queued now (or fail only on crystals / pop).
func _open_types(b: Node, tier: int) -> Array[String]:
	var out: Array[String] = []
	for t: UnitType in b.call(&"trainable_types"):
		if t == null or t.requires_tier != tier:
			continue
		var r := String(b.call(&"can_queue", t))
		if r == "" or r.begins_with("Not enough") or r.contains("population") or r.contains("Population"):
			out.append(t.display_name)
	return out


func _message(hud: Node) -> String:
	if hud == null:
		return ""
	var m: Variant = hud.get(&"_message")
	return (m as Label).text if m is Label and hud.call(&"is_message_shown") else "(none)"


func _log_state(level: Node, what: String) -> void:
	var hud: Node = level.get(&"hud")
	var hint: Node = hud.get(&"next_step_hint") if hud else null
	var hint_text := "(no hint)"
	if hint != null and is_instance_valid(hint):
		var l: Variant = hint.get(&"label")
		hint_text = (l as Label).text if l is Label else "?"
		if not (hint as Control).is_visible_in_tree():
			hint_text += " [hidden]"
	var chip: Variant = hud.get(&"tier_chip") if hud and &"tier_chip" in hud else null
	var chip_text := "(no tier chip)"
	if chip is Node and is_instance_valid(chip) and chip.has_method(&"text"):
		chip_text = String(chip.call(&"text"))
	_log("[%s | %s] hint: %s | tier chip: %s | crystals %d" % [what, level.call(&"match_time_text") if level.has_method(&"match_time_text") else "?",
			hint_text, chip_text, _eco(level).crystals])


func _log_card(level: Node, what: String) -> void:
	var hud: Node = level.get(&"hud")
	var card: CommandCard = hud.get(&"command_card") if hud else null
	if card == null:
		return
	card.refresh()
	_log("  %s:" % what)
	for i in card.slots.size():
		var s: Dictionary = card.slots[i]
		if s.is_empty():
			continue
		var tip := String(s["tooltip"]).replace("\n", " / ")
		var flag := ""
		if s.has("attention") and bool(s["attention"]):
			flag = " [GOLD PULSE]"
		_log("    r%dc%d [%s] %s%s -> %s | %s" % [i / 4 + 1, i % 4 + 1, s["key"], s["id"], flag,
				"OK" if s["reason"] == "" else s["reason"], tip.left(170)])


func _shot(name: String) -> void:
	if headless:
		return
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img == null or img.is_empty():
		return
	var path := out_dir.path_join(name + ".jpg")
	img.save_jpg(ProjectSettings.globalize_path(path), 0.8)
	shot_paths.append(ProjectSettings.globalize_path(path))
	_log("  shot: %s" % ProjectSettings.globalize_path(path))


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _log(s: String) -> void:
	lines.append(s)
	print(s)


func _fail(s: String) -> void:
	fails.append(s)
	_log("FAIL: " + s)
