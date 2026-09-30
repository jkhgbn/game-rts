extends SceneTree
## Caster units, the player's side (docs/design/caster-units.md 3.2 / 9.1, ui-hud.md; task CU.U1): a Fire skirmish with
## two Kilnwardens selected.
## - the card: Slag Rain on r2c1 [Z], Mana Scald on r2c2 [V], tooltips `Name  [key]` with the cost / range / autocast
##   line; the autocast border (state 1 = on for all); right-click on the button and Ctrl+Z / Ctrl+V toggle it for every
##   selected caster; AZERTY shows W for Z (badge, tooltip, `Ctrl+W`);
## - Z starts aiming (pending order = the spell, range ring up), Esc / right click cancels; a minimap click casts a point
##   spell with ONE caster: the one in range with the most mana (smart-cast); a unit spell on the minimap asks for a
##   unit; with no mana, Z answers "Not enough mana" and aims nothing; Shift keeps aiming for the next caster;
## - V with a caster + soldier selection whose active subgroup is the soldiers still aims the casters' spell;
## - the selection panel shows the caster's mana bar (single view) and a mana strip on its portrait (multi view);
## - the help text has the `Z / V: caster spells (Ctrl: autocast)` entry (12 lines, <= 440 px).
## Run:  godot --headless --path . -s tests/test_casters_ui.gd --fixed-fps 60 --quit-after 12000

const TASK_ID := "casters_ui"
const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER := preload("res://scripts/ai/commander.gd")
const PLAYER := 0
const ENEMY := 1

var main: Node
var sel: SelectionManager
var card: CommandCard
var hud: Node
var _errors: Array[String] = []
var _cases := 0
var _msgs: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	_cases += 1
	if not ok:
		_errors.append(what)
		print("  x " + what)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _secs(s: float) -> void:
	await _frames(roundi(s * 60.0))


func _key(code: Key, ctrl := false, shift := false) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.keycode = code
	ev.ctrl_pressed = ctrl
	ev.shift_pressed = shift
	ev.pressed = true
	root.push_input(ev)
	var up := ev.duplicate() as InputEventKey
	up.pressed = false
	root.push_input(up)


func _run() -> void:
	main = load(SCENE).instantiate()
	main.set(&"camps_enabled", false)
	main.set(&"beasts_enabled", false)
	for n in main.get_children():
		if n.get_script() == COMMANDER:
			n.set(&"enabled", false)
	root.add_child(main)
	current_scene = main
	var t0 := Time.get_ticks_msec()
	while not bool(main.get(&"match_started")):
		await process_frame
		if Time.get_ticks_msec() - t0 > 180000:
			print("FAIL %s: the skirmish never started" % TASK_ID)
			quit(1)
			return
	var hero: Wizard = main.get(&"hero")
	var path := StrIntPath.of(hero)
	if path != null and not path.is_locked():
		path.choose(&"str")
	paused = false
	await _frames(5)
	sel = main.get(&"selection")
	hud = main.get(&"hud")
	card = hud.get(&"command_card")
	sel.message.connect(func(t: String) -> void: _msgs.append(t))
	GameSettings.set_control_scheme(GameSettings.CONTROLS_CLASSIC, false)
	KeyLabels.overrides = {}
	await _checks()
	KeyLabels.overrides = {}
	if _errors.is_empty():
		print("PASS %s (%d checks)" % [TASK_ID, _cases])
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors.slice(0, 30))])
	quit(0 if _errors.is_empty() else 1)


func _spawn(id: String, team: int, pos: Vector3) -> Unit:
	var u := UnitType.find(id).create_unit()
	u.team = team as Unit.Team
	main.add_child(u)
	u.global_position = pos
	u.command_hold()
	u.add_modifier(&"test_harmless", {&"attack_damage_pct": -1.0})
	return u


func _checks() -> void:
	var keep: Node3D = main.keep
	var dir := -Vector3(keep.global_position.x, 0.0, keep.global_position.z).normalized()
	var side := dir.cross(Vector3.UP)
	var at := keep.global_position + dir * 24.0
	var a := _spawn("kilnwarden", PLAYER, at)
	var b := _spawn("kilnwarden", PLAYER, at + side * 2.0)
	var soldier := _spawn("flame_guard", PLAYER, at - side * 2.0)
	var clump: Array[Unit] = []
	for i in 4:
		var e := _spawn("flame_guard", ENEMY, at + dir * 8.0 + side * (float(i) - 1.5))
		e.set_physics_process(false)
		clump.append(e)
	await _frames(3)
	var aa := CasterKit.ability_of(a)
	var ab := CasterKit.ability_of(b)
	for x in [aa, ab]:
		for s in x.spell_ids():
			x.set_autocast(s, false)   # no autocast on the clump while the fog updates
	aa.mana = 60.0   # under Slag Rain's 75: no autocast on the clump while the toggles are checked
	ab.mana = 60.0
	await _secs(0.5)
	for x in [aa, ab]:
		for s in x.spell_ids():
			x.set_autocast(s, true)
	sel.select_units([a, b])
	card.refresh()
	await _frames(2)
	card.refresh()
	# ---- the card
	var ids := card.slot_ids()
	_check(ids[4] == "caster_slag_rain" and ids[5] == "caster_mana_scald", "caster card %s" % str(ids))
	_check(ids[0] == "move" and ids[1] == "stop" and ids[2] == "hold" and ids[3] == "attack", "caster card orders %s" % str(ids))
	_check(card.key_labels[4].text == "Z" and card.key_labels[5].text == "V", "badges %s / %s" % [card.key_labels[4].text,
			card.key_labels[5].text])
	_check(card.buttons[4].tooltip_text.begins_with("Slag Rain  [Z]\n75 mana · range 10"), "tooltip '%s'" % card.buttons[4].tooltip_text)
	_check(card.buttons[4].tooltip_text.contains("Ctrl+Z"), "tooltip names Ctrl+Z")
	_check(int(card.slots[4].get("autocast", 0)) == 1, "autocast border state %s" % card.slots[4].get("autocast", 0))
	# Right-click the button: autocast off for both; again: on.
	var rc := InputEventMouseButton.new()
	rc.button_index = MOUSE_BUTTON_RIGHT
	rc.pressed = true
	card.buttons[4].gui_input.emit(rc)
	card.refresh()
	_check(not aa.autocast(&"slag_rain") and not ab.autocast(&"slag_rain") and int(card.slots[4].get("autocast", 9)) == 0,
			"right-click did not switch Slag Rain autocast off")
	card.right_click_slot(4)
	_check(aa.autocast(&"slag_rain") and ab.autocast(&"slag_rain"), "right-click did not switch it back on")
	# Mixed state: one on, one off -> Ctrl+V turns both on; Ctrl+V again: both off.
	ab.set_autocast(&"mana_scald", false)
	card.refresh()
	_check(int(card.slots[5].get("autocast", 0)) == 2, "mixed autocast state")
	_key(KEY_V, true)
	await _frames(2)
	_check(aa.autocast(&"mana_scald") and ab.autocast(&"mana_scald"), "Ctrl+V (mixed) -> all on")
	_key(KEY_V, true)
	await _frames(2)
	_check(not aa.autocast(&"mana_scald") and not ab.autocast(&"mana_scald"), "Ctrl+V -> all off")
	_check(sel.pending_caster_spell() == &"", "Ctrl+V started aiming")
	_key(KEY_Z, true)
	await _frames(2)
	_check(not aa.autocast(&"slag_rain") and not ab.autocast(&"slag_rain"), "Ctrl+Z -> off")
	# ---- aiming: Z, Esc (autocast is off now: the mana goes back up)
	aa.mana = 120.0
	ab.mana = 180.0
	_key(KEY_Z)
	await _frames(2)
	_check(sel.pending_caster_spell() == &"slag_rain" and sel.get_pending_order() == &"slag_rain", "Z did not start aiming")
	card.refresh()
	_check(bool(card.slots[4].get("active", false)), "the Z button is not highlighted while aiming")
	_key(KEY_ESCAPE)
	await _frames(2)
	_check(sel.pending_caster_spell() == &"", "Esc did not cancel the aim")
	paused = false
	# Smart-cast from the minimap: one cast, by the in-range caster with the most mana (b).
	_key(KEY_Z)
	await _frames(2)
	var point := at + dir * 8.0
	_check(sel.confirm_pending_at(point), "minimap confirm refused")
	await _secs(1.3)
	var ca := int(aa.casts.get(&"slag_rain", 0))
	var cb := int(ab.casts.get(&"slag_rain", 0))
	_check(ca + cb == 1 and cb == 1, "smart-cast: a %d, b %d (want b once)" % [ca, cb])
	_check(clump[0].has_status(&"slagged"), "the clump was not slagged")
	# A unit spell on the minimap asks for a unit.
	_msgs.clear()
	await _secs(1.0)
	_key(KEY_V)
	await _frames(2)
	sel.confirm_pending_at(point)
	_check(_msgs.has("Pick a unit"), "unit spell on the minimap: %s" % str(_msgs))
	# Shift keeps aiming for the next caster (the unit path: a smart-cast then re-aim).
	aa.mana = 200.0
	ab.mana = 200.0
	await _secs(1.2)
	_key(KEY_Z)
	await _frames(2)
	var casts0 := int(aa.casts.get(&"slag_rain", 0)) + int(ab.casts.get(&"slag_rain", 0))
	_msgs.clear()
	sel.call(&"_confirm_caster_spell", &"mana_scald", Vector2(-1, -1), true)   # a unit spell, no unit under the click
	await _frames(2)
	_check(sel.pending_caster_spell() == &"mana_scald" and _msgs.has("Pick a unit"), "a click on no unit dropped the aim")
	sel.cancel_targeting()
	sel.cast_caster_at(&"slag_rain", point)
	sel.begin_caster_spell(&"slag_rain")
	_check(sel.pending_caster_spell() == &"slag_rain", "re-aim after a cast (Shift)")
	sel.cancel_targeting()
	await _secs(1.3)
	_check(int(aa.casts.get(&"slag_rain", 0)) + int(ab.casts.get(&"slag_rain", 0)) == casts0 + 1, "smart-cast count")
	# No mana: Z answers the refusal and aims nothing.
	aa.mana = 0.0
	ab.mana = 0.0
	_msgs.clear()
	await _frames(2)
	_key(KEY_Z)
	await _frames(2)
	_check(sel.pending_caster_spell() == &"" and _msgs.has(CasterKit.REASON_MANA), "no mana: %s" % str(_msgs))
	card.refresh()
	_check(card.buttons[4].disabled and card.slots[4]["reason"] == CasterKit.REASON_MANA, "Z button not greyed without mana")
	aa.mana = 200.0
	ab.mana = 200.0
	# V with the soldiers' subgroup active still aims the casters' spell.
	sel.select_units([a, b, soldier])
	await _frames(2)
	for i in 3:
		if sel.active_unit_type() == &"flame_guard":
			break
		sel.cycle_active_unit_type(1)
	_key(KEY_V)
	await _frames(2)
	_check(sel.pending_caster_spell() == &"mana_scald", "V with the soldiers' subgroup active (pending %s)"
			% sel.pending_caster_spell())
	sel.cancel_targeting()
	# AZERTY: W for Z on the badge, the tooltip and Ctrl+W.
	sel.select_units([a, b])
	KeyLabels.overrides = {KEY_Z: KEY_W, KEY_W: KEY_Z}
	card.refresh()
	_check(card.key_labels[4].text == "W" and card.buttons[4].tooltip_text.begins_with("Slag Rain  [W]")
			and card.buttons[4].tooltip_text.contains("Ctrl+W"), "AZERTY labels '%s' / '%s'" % [card.key_labels[4].text,
			card.buttons[4].tooltip_text.get_slice("\n", 0)])
	KeyLabels.overrides = {}
	card.refresh()
	# ---- selection panel: the mana bar (single) and the mana strip (multi).
	var panel: SelectionPanel = hud.get(&"selection_panel")
	sel.select_units([a])
	await _frames(3)
	panel.refresh()
	_check(panel.single_mana.visible and panel.single_mana_text.text == "Mana  %d / 200" % int(aa.mana),
			"single view mana '%s'" % panel.single_mana_text.text)
	sel.select_units([a, b, soldier])
	await _frames(3)
	panel.refresh()
	var strips: Array = panel.get(&"_icon_mana_strips")
	var shown := 0
	for i in 3:
		if (strips[i] as ColorRect).visible:
			shown += 1
	_check(shown == 2, "mana strips on %d portraits (want the 2 casters)" % shown)
	# ---- help text
	var lines := GameHUD.help_text("Vessa").split("\n")
	_check(lines.size() == 12, "help has %d lines" % lines.size())
	var joined := "\n".join(lines)
	_check(joined.contains("Z / V: caster spells (Ctrl: autocast)"), "help lacks the caster keys")
	var font := ThemeDB.fallback_font
	var widest := 0.0
	for l in lines:
		widest = maxf(widest, font.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x)
	_check(widest <= 440.0, "widest help line %d px" % widest)
	var dups := UILabChecks.find_duplicate_help_keys(joined).filter(func(d: Dictionary) -> bool:
		return String(d["value"]).contains("Z") or String(d["value"]).contains("V"))
	_check(dups.is_empty(), "caster help keys used twice: %s" % str(dups))
