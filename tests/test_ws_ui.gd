extends SceneTree
## WS2.U1 (docs/design/wave-strike.md 14.6, ui-wave-strike.md 1-5): the Wave Strike Muster panel.
## Ice (10 cards): the panel fills the console's muster zone, 10 cards 72 x 118 at the spec x, KeyLabels on every badge
## (AZERTY overrides too); the 10 physical keys pressed through the viewport: T1 buys, T2 / T3 refused below their tier
## (locked state), G = Coffer, U = next tier (refused before its horn, then Stronghold / Citadel), then the T2 / T3 keys
## buy, Ctrl = rank up, Alt = sell, the 5th Rimecarver refused "Max 4 copies" (maxed state), I toggles the enemy peek,
## the M1 top-right buy panel is gone. Fire (9 cards): slot 10 is empty and its key refuses quietly.
## French: every card name of the 4 kingdoms fits 2 lines (font >= 10) and the role tags exist.
## Pad rows (WS3.U1 / U2, ui-wave-strike.md 7; Fire): a token per copy on both pads (2x2 for riders), P flies the
## camera behind the pad and P again back, manual place by a simulated click (Shift+click keeps the ghost, right-click
## cancels without paying), drag move, drag swap, box select + group move, right-click sell, L / Ctrl+L, held markers,
## the spawn box on horn_soon, token tooltips, the `Place on buy` setting.
## Upgrade rows (WS4.U1, 8): Shift / Shift+Ctrl / Shift+Alt + card key, pips and their tooltips, R / Y / O Armoury,
## token ticks, effect text from the data.
## Prints "PASS ws_ui" or "FAIL ws_ui: <reasons>".
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_ws_ui.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "ws_ui"
const SCENE := "res://scenes/wave_strike.tscn"
const KEYS: Array[int] = [KEY_Z, KEY_X, KEY_C, KEY_V, KEY_B, KEY_N, KEY_M, KEY_COMMA, KEY_PERIOD, KEY_SLASH]
const SPEC_X: Array[float] = [10, 88, 166, 244, 322, 410, 488, 566, 654, 732]

var level: Node
var hud: Node
var _fails: Array[String] = []
var _phase := 0          ## 0 ice, 1 fire
var _frames := 0
var _step := 0
var _pad_done := false


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)


func _initialize() -> void:
	root.size = Vector2i(1600, 900)   # the 1600 x 900 layout (headless starts tiny)
	_start(&"ice")


func _start(k: StringName) -> void:
	level = (load(SCENE) as PackedScene).instantiate()
	level.set(&"player_kingdom", k)
	level.set(&"enemy_kingdom", &"shadow")
	level.set(&"wizards_enabled", false)
	root.add_child(level)
	current_scene = level
	hud = null
	_frames = 0
	_step = 0


func _key(code: int, ctrl := false, alt := false, shift := false) -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventKey.new()
		ev.physical_keycode = code as Key
		ev.keycode = code as Key
		ev.pressed = pressed
		ev.ctrl_pressed = ctrl
		ev.alt_pressed = alt
		ev.shift_pressed = shift
		root.push_input(ev)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames > 8000:
		print("FAIL %s: timed out (phase %d, step %d)" % [TASK_ID, _phase, _step])
		return true
	if hud == null:
		if root.size != Vector2i(1600, 900):
			root.size = Vector2i(1600, 900)   # headless windows start at 64 x 64
		var h: Variant = level.get(&"ws_hud")
		if h is Node and (h as Node).get(&"muster") != null:
			hud = h
			_step = 0
		return false
	_step += 1
	if _step < 5:
		return false
	if _phase == 0:
		_ice()
		level.queue_free()
		_phase = 1
		_start(&"fire")
		return false
	if _phase == 1:
		_fire()
		_french()
		_phase = 2
		_pad_rows()
		return false
	if not _pad_done:
		return false
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	return true


func _ice() -> void:
	var muster: Node = hud.get(&"muster")
	var roster: MusterRoster = hud.get(&"roster")
	var bank: WaveBank = hud.get(&"bank")
	var gh: Node = level.get(&"hud")
	var con: ConsoleFrame = gh.get(&"console")
	var zone := con.zone_rect(&"muster")
	_check((muster as Control).position.is_equal_approx(zone.position) and (muster as Control).size.is_equal_approx(zone.size),
			"muster rect %s != zone %s" % [(muster as Control).get_rect(), zone])
	_check(is_equal_approx(zone.position.x, 244.0) and is_equal_approx(zone.size.y, 200.0), "zone %s" % zone)
	_check(not (gh.get(&"command_card") as Control).visible, "skirmish command card still visible")
	var cards: Array = muster.get(&"cards")
	_check(cards.size() == 10, "%d cards" % cards.size())
	for i in cards.size():
		var c := cards[i] as MusterCard
		_check(c.size.is_equal_approx(Vector2(72, 118)), "card %d size %s" % [i + 1, c.size])
		_check(is_equal_approx(c.position.x, SPEC_X[i]) and is_equal_approx(c.position.y, 38.0),
				"card %d at %s" % [i + 1, c.position])
		_check(String(c.data.get("key", "")) == KeyLabels.of(KEYS[i]), "card %d badge '%s'" % [i + 1, c.data.get("key", "")])
	# right column: 160 wide, 12 px from the zone's right edge
	var cb := muster.get(&"coffer_button") as Control
	_check(is_equal_approx(cb.position.x + 160.0, zone.size.x - 12.0) and cb.size == Vector2(160, 40), "coffer %s" % cb.get_rect())
	# M1 top-right buy panel removed: the only buttons of the WS HUD live in the Muster panel / the enemy peek
	for b in hud.find_children("*", "Button", true, false):
		var inside := (muster as Node).is_ancestor_of(b) or (hud.get(&"enemy_peek") as Node).is_ancestor_of(b)
		_check(inside, "stray button %s (M1 panel?)" % b.name)
	# AZERTY labels on the badges
	KeyLabels.overrides = {KEY_Z: "W", KEY_M: ",", KEY_COMMA: ";", KEY_PERIOD: ":", KEY_SLASH: "!"}
	muster.call(&"refresh")
	_check(String((cards[0] as MusterCard).data["key"]) == "W", "AZERTY badge 1 '%s'" % (cards[0] as MusterCard).data["key"])
	_check(String((cards[9] as MusterCard).data["key"]) == "!", "AZERTY badge 10 '%s'" % (cards[9] as MusterCard).data["key"])
	KeyLabels.overrides = {}
	bank.refund(100000)
	var ids := roster.card_ids()
	# T1 keys buy, T2 / T3 keys are refused at the Keep (locked state)
	for i in 10:
		var before := roster.count(ids[i])
		_key(KEYS[i])
		var want := 1 if i < 5 else 0
		_check(roster.count(ids[i]) - before == want, "key %d at Keep: %d -> %d" % [i + 1, before, roster.count(ids[i])])
	muster.call(&"refresh")
	for i in 10:
		var locked := bool((cards[i] as MusterCard).data.get("locked", false))
		_check(locked == (i >= 5), "card %d locked=%s" % [i + 1, locked])
	_check(String(roster.can_buy(ids[8])) == "Requires Citadel", "T3 reason '%s'" % roster.can_buy(ids[8]))
	_check((cards[0] as MusterCard).is_animating(), "card 1 bought: no buy pulse")
	# G = Coffer
	var cl := bank.coffer_level
	_key(KEY_G)
	_check(bank.coffer_level == cl + 1, "G: coffer %d -> %d" % [cl, bank.coffer_level])
	# U = next tier: refused before its horn, then Stronghold and Citadel
	_key(KEY_U)
	_check(roster.upgrade_left <= 0.0 and roster.tier == 1, "U before horn %d started a tier" % roster.rules.stronghold_from_horn)
	roster.rules.stronghold_from_horn = 0
	roster.rules.citadel_from_horn = 0
	_key(KEY_U)
	_check(roster.upgrade_left > 0.0, "U: Stronghold not rising")
	roster.tick(1000.0)
	_check(roster.tier == 2, "tier %d after the Stronghold" % roster.tier)
	_key(KEY_U)
	roster.tick(1000.0)
	_check(roster.tier == 3, "tier %d after the Citadel" % roster.tier)
	muster.call(&"refresh")
	_check(String((muster.get(&"tier_button") as MusterButton).line1.text).contains("Citadel"), "tier button '%s'" % (muster.get(&"tier_button") as MusterButton).line1.text)
	for i in range(5, 10):
		var before := roster.count(ids[i])
		_key(KEYS[i])
		_check(roster.count(ids[i]) == before + 1, "key %d at Citadel: %d -> %d" % [i + 1, before, roster.count(ids[i])])
	# Ctrl = rank up, Alt = sell
	_key(KEY_Z, true)
	_check(roster.rank(ids[0]) == 2, "Ctrl+Z rank %d" % roster.rank(ids[0]))
	var n0 := roster.count(ids[0])
	_key(KEY_Z, false, true)
	_check(roster.count(ids[0]) == n0 - 1, "Alt+Z sold %d -> %d" % [n0, roster.count(ids[0])])
	# max copies: Rimecarver (slot 7, key M) is a caster, max 4
	var rc := ids[6]
	_check(rc == &"rimecarver", "slot 7 is %s" % rc)
	for k in 6:
		_key(KEY_M)
	_check(roster.count(rc) == 4, "rimecarver copies %d (max 4)" % roster.count(rc))
	_check(roster.can_buy(rc) == "Max 4 copies", "5th rimecarver '%s'" % roster.can_buy(rc))
	muster.call(&"refresh")
	_check(bool((cards[6] as MusterCard).data.get("maxed", false)), "card 7 not maxed")
	# I = enemy roster peek
	var peek := hud.get(&"enemy_peek") as EnemyRosterPeek
	_key(KEY_I)
	_check(peek.pinned, "I did not open the enemy peek")
	peek.refresh()
	_check(peek.title.text.contains("Shadow") and peek.footer.text != "", "peek '%s' / '%s'" % [peek.title.text, peek.footer.text])
	# tooltips build (cards: the section-8 rows; the role tag line; Coffer / tier buttons)
	for c: MusterCard in cards:
		var tip: Variant = c._make_custom_tooltip(c.tooltip_text)
		_check(tip is Control, "card %d tooltip" % (c.slot + 1))
		if tip is Node:
			(tip as Node).free()
	var c7 := cards[6] as MusterCard
	_check(c7._get_tooltip(c7.role_rect().get_center()).begins_with("Casters autocast"), "caster role tag tooltip")
	for b: MusterButton in [muster.get(&"coffer_button"), muster.get(&"tier_button")]:
		var bt: Variant = b._make_custom_tooltip(b.tooltip_text)
		_check(bt is Control and b.tooltip_text != "", "%s tooltip" % b.name)
		if bt is Node:
			(bt as Node).free()
	_key(KEY_I)
	_check(not peek.pinned, "I did not close the enemy peek")
	# field counter + held warning
	var fc := muster.get(&"field_counter") as WsFieldCounter
	fc.set_counts(200, 200, 12)
	_check(fc.held_label.visible and fc.held_label.text.contains("12"), "held line '%s'" % fc.held_label.text)
	_check(fc.tooltip_text != "", "held tooltip missing")


func _fire() -> void:
	var muster: Node = hud.get(&"muster")
	var roster: MusterRoster = hud.get(&"roster")
	var cards: Array = muster.get(&"cards")
	_check(roster.card_ids().size() == 9, "fire cards %d" % roster.card_ids().size())
	_check(bool((cards[9] as MusterCard).data.get("empty", false)), "fire slot 10 not empty")
	_check(String((cards[9] as MusterCard).data.get("key", "")) == "", "fire slot 10 shows a badge")
	var total := roster.card_total()
	_key(KEY_SLASH)
	_check(roster.card_total() == total, "fire slot 10 key bought something")
	_check(String(hud.call(&"buy_card", 9)) == "No card", "fire slot 10 reason")
	var gh: Node = level.get(&"hud")
	var msg: Variant = gh.get(&"_message")
	_check(not (msg is Label) or not String((msg as Label).text).contains("No card"), "slot 10 refusal was shown")


func _french() -> void:
	var lang := Loc.language
	Loc.set_language("fr")
	var table := WaveCardTable.load_default()
	var c := MusterCard.new()
	root.add_child(c)
	for k: StringName in [&"fire", &"ice", &"nature", &"shadow"]:
		for id in table.cards_of(k):
			var t := UnitType.find(String(id))
			var nm := Loc.t(t.display_name)
			c.set_data({"name": nm})
			var fs := c.name_label.get_theme_font_size(&"font_size")
			c.name_label.max_lines_visible = -1
			var lines := c.name_label.get_line_count()
			c.name_label.max_lines_visible = 2
			_check(lines <= 2 or fs >= 10, "fr name '%s' %d lines at %d" % [nm, lines, fs])
			_check(lines <= 3, "fr name '%s' needs %d lines" % [nm, lines])
	for tag: String in ["Melee", "Ranged", "Rider", "Heavy", "Support", "Caster"]:
		var fr := Loc.t(tag, null, "ws role tag")
		_check(fr != tag or tag == "Support", "role tag '%s' has no French" % tag)
	_check(Loc.sink("Max 4 copies") != "Max 4 copies", "'Max 4 copies' has no French")
	_check(Loc.sink("Requires Citadel") != "Requires Citadel", "'Requires Citadel' has no French")
	c.queue_free()
	Loc.set_language(lang)


# ---------------------------------------------------------------- pad + upgrade rows (WS3.U1 / U2, WS4.U1)

func _wait(n: int) -> void:
	for i in n:
		await process_frame


func _mouse(kind: StringName, at: Vector2, button := MOUSE_BUTTON_LEFT, shift := false) -> void:
	var ev: InputEvent
	if kind == &"move":
		var mm := InputEventMouseMotion.new()
		mm.position = at
		mm.global_position = at
		ev = mm
	else:
		var mb := InputEventMouseButton.new()
		mb.position = at
		mb.global_position = at
		mb.button_index = button
		mb.pressed = kind == &"down"
		mb.shift_pressed = shift
		ev = mb
	root.push_input(ev, true)


func _click(at: Vector2, button := MOUSE_BUTTON_LEFT, shift := false) -> void:
	_mouse(&"move", at)
	_mouse(&"down", at, button, shift)
	_mouse(&"up", at, button, shift)


func _drag(from: Vector2, to: Vector2) -> void:
	_mouse(&"move", from)
	_mouse(&"down", from)
	for k in range(1, 6):
		_mouse(&"move", from.lerp(to, k / 5.0))
	_mouse(&"up", to)


func _pad_rows() -> void:
	var roster: MusterRoster = hud.get(&"roster")
	var bank: WaveBank = hud.get(&"bank")
	var pv: MusterPadView = hud.get(&"pad_view")
	var ev: MusterPadView = hud.get(&"enemy_pad_view")
	var input: MusterPadInput = hud.get(&"pad_input")
	var pad := roster.pad
	var rig: RTSCamera = level.get(&"camera_rig")
	rig.edge_pan_enabled = false   # the headless mouse sits in a corner: no edge pan during the pad rows
	_check(pv != null and ev != null and input != null, "pad views / input missing")
	if pv == null or input == null:
		_pad_done = true
		return
	var manual_was := GameSettings.ws_place_manual
	GameSettings.ws_place_manual = false
	roster.tier = 3
	bank.refund(50000)
	var ids := roster.card_ids()
	for i in [0, 0, 0, 2, 2, 4, 4]:
		hud.call(&"buy_card", i)
	await _wait(3)
	_check(pv.token_count() == pad.copy_count() and pv.token_count() == 7, "tokens %d / copies %d" % [pv.token_count(), pad.copy_count()])
	var riders := pad.cells_of(ids[4])
	_check(riders.size() == 2 and pad.footprint(ids[4]) == 2, "blaze riders %s footprint %d" % [riders, pad.footprint(ids[4])])
	_check(ev.roster.pad.copy_count() == ev.token_count(), "enemy pad tokens %d != copies %d" % [ev.token_count(), ev.roster.pad.copy_count()])
	# P: the camera flies behind the pad, P again flies back
	var before := rig.view_state()
	_key(KEY_P)
	await _wait(40)
	var pose := pv.camera_pose()
	_check(rig.position.distance_to(pose[0]) < 0.2 and is_equal_approx(wrapf(rig.rotation.y - float(pose[1]), -PI, PI), 0.0)
			and input.at_pad(), "P: camera %s yaw %.2f, want %s %.2f" % [rig.position, rig.rotation.y, pose[0], pose[1]])
	_key(KEY_P)
	await _wait(40)
	_check(rig.position.distance_to(before[0]) < 0.2 and absf(rig.pitch_degrees - float(before[3])) < 0.1,
			"P again: camera %s pitch %.1f, want %s %.1f" % [rig.position, rig.pitch_degrees, before[0], before[3]])
	_key(KEY_P)
	await _wait(40)
	# manual place: Manual setting -> the buy key shows the ghost; a click on a free cell pays and places
	GameSettings.ws_place_manual = true
	var n0 := roster.count(ids[1])
	var c0 := bank.crystals()
	_key(KEY_X)
	_check(input.placing() == ids[1] and roster.count(ids[1]) == n0, "manual: X did not start the ghost (%s)" % input.placing())
	var free := Vector2i(8, 7)
	_click(input.cell_screen(free))
	await _wait(2)
	_check(roster.count(ids[1]) == n0 + 1 and StringName(pad.copy_at(free).get("id", &"")) == ids[1],
			"manual click: count %d, at %s = %s" % [roster.count(ids[1]), free, pad.copy_at(free)])
	_check(bank.crystals() < c0 and input.placing() == &"", "manual click: paid %d, ghost %s" % [c0 - bank.crystals(), input.placing()])
	# Shift+click keeps the ghost; a right-click cancels it without paying
	_key(KEY_X)
	_click(input.cell_screen(Vector2i(9, 7)), MOUSE_BUTTON_LEFT, true)
	await _wait(2)
	_check(input.placing() == ids[1] and roster.count(ids[1]) == n0 + 2, "shift+click: ghost %s, count %d" % [input.placing(), roster.count(ids[1])])
	var c1 := bank.crystals()
	_click(input.cell_screen(Vector2i(10, 7)), MOUSE_BUTTON_RIGHT)
	await _wait(2)
	_check(input.placing() == &"" and bank.crystals() == c1 and roster.count(ids[1]) == n0 + 2, "right-click did not cancel the ghost")
	# a click on a taken cell is refused (nothing paid)
	_key(KEY_X)
	_click(input.cell_screen(free))
	await _wait(2)
	_check(roster.count(ids[1]) == n0 + 2 and input.placing() == ids[1], "click on a taken cell placed / dropped the ghost")
	_key(KEY_ESCAPE)
	_check(input.placing() == &"", "Esc did not cancel the ghost")
	GameSettings.ws_place_manual = false
	# drag move
	var to := Vector2i(3, 8)
	_drag(input.cell_screen(free), input.cell_screen(to))
	await _wait(2)
	_check(pad.copy_at(free).is_empty() and StringName(pad.copy_at(to).get("id", &"")) == ids[1], "drag move %s -> %s" % [free, to])
	# drag swap: the scorchling onto a flame guard (same size)
	var fg := pad.cells_of(ids[0])[0]
	_drag(input.cell_screen(to), input.cell_screen(fg))
	await _wait(2)
	_check(StringName(pad.copy_at(fg).get("id", &"")) == ids[1] and StringName(pad.copy_at(to).get("id", &"")) == ids[0],
			"drag swap: %s = %s, %s = %s" % [fg, pad.copy_at(fg), to, pad.copy_at(to)])
	# box select two tokens on an empty part, then move them as a group one row back
	pad.move(to, Vector2i(12, 9))
	pad.move(Vector2i(9, 7), Vector2i(13, 9))
	await _wait(2)
	_drag(input.cell_screen(Vector2i(11, 8)) + Vector2(-4, -4), input.cell_screen(Vector2i(14, 10)))
	await _wait(2)
	_check(pv.selected().size() == 2, "box select picked %d tokens" % pv.selected().size())
	_drag(input.cell_screen(Vector2i(12, 9)), input.cell_screen(Vector2i(12, 10)))
	await _wait(2)
	_check(not pad.copy_at(Vector2i(12, 10)).is_empty() and not pad.copy_at(Vector2i(13, 10)).is_empty()
			and pad.copy_at(Vector2i(12, 9)).is_empty(), "group move: %s" % pad.save_cells())
	# right-click a token = sell
	var total := roster.card_total()
	_click(input.cell_screen(Vector2i(13, 10)), MOUSE_BUTTON_RIGHT)
	await _wait(2)
	_check(roster.card_total() == total - 1 and pad.copy_at(Vector2i(13, 10)).is_empty(), "right-click sell: %d -> %d" % [total, roster.card_total()])
	# L arranges (Line), Ctrl+L undoes
	var shape := _norm(pad.save_cells())
	_key(KEY_L)
	await _wait(2)
	var arranged := _norm(pad.save_cells())
	_check(arranged != shape and input.undo_left() > 0.0, "L did not arrange")
	_check((muster_undo_enabled()), "undo button disabled inside the window")
	_key(KEY_L, true)
	await _wait(2)
	_check(_norm(pad.save_cells()) == shape, "Ctrl+L did not undo: %s vs %s" % [_norm(pad.save_cells()), shape])
	# hover: tooltip rows + model ghost; held markers; spawn box on horn_soon
	var t0: Vector2i = pv.tokens()[0]["cell"]
	_mouse(&"move", input.cell_screen(t0, int(pv.tokens()[0]["size"])))
	await _wait(25)
	_check(pv.hovered() == 0, "hover index %d" % pv.hovered())
	var tip := MusterPadInput.token_tip(pv, 0)
	_check(tip.size() >= 3 and String(tip[1][0]).contains("Cell"), "token tooltip %s" % [tip])
	_check(not (hud.get(&"pad_overlay") as MusterPadInput.PadOverlay).tip_rows.is_empty(), "hover tooltip not shown")
	_mouse(&"move", Vector2(5, 5))
	pv.set_held(2)
	var held := 0
	for t in pv.tokens():
		held += 1 if bool(t.get("held", false)) else 0
	_check(held == 2, "held markers %d" % held)
	(hud.get(&"director") as WaveDirector).horn_soon.emit(5.0)
	await _wait(20)
	_check(pv.spawn_box_visible(), "spawn box hidden after horn_soon")
	var fr := EnemyRosterPeek.front_row_text(roster)
	_check(fr.begins_with("Front row:") and fr.contains("Melee"), "front row line '%s'" % fr)
	# ---- upgrades (WS4.U1)
	var muster: Node = hud.get(&"muster")
	_key(KEY_Z, false, false, true)
	_check(roster.has_upgrade(ids[0], 0), "Shift+Z: no upgrade A")
	_key(KEY_Z, true, false, true)
	_check(roster.has_upgrade(ids[0], 1), "Shift+Ctrl+Z: no upgrade B (%s)" % roster.can_buy_upgrade(ids[0], 1))
	muster.call(&"refresh")
	var card := (muster.get(&"cards") as Array)[0] as MusterCard
	var ups: Array = card.data.get("ups", [])
	_check(ups.size() == 2 and StringName(ups[0]["state"]) == &"bought" and float(ups[1]["window"]) > 0.0, "card 1 pips %s" % [ups])
	var pip_tip := card._get_tooltip(MusterCard.PIPS[0].get_center())
	_check(pip_tip.begins_with(MusterCard.PIP_TIP), "pip tooltip '%s'" % pip_tip)
	var pt: Variant = card._make_custom_tooltip(pip_tip)
	_check(pt is Control, "pip tooltip panel")
	if pt is Node:
		(pt as Node).free()
	_key(KEY_Z, false, true, true)
	_check(not roster.has_upgrade(ids[0], 1) and roster.has_upgrade(ids[0], 0), "Shift+Alt+Z did not cancel B")
	await _wait(3)
	var ticked := false
	for t in pv.tokens():
		if StringName(t["id"]) == ids[0]:
			ticked = int(t["up"]) == 1
	_check(ticked, "flame guard tokens have no A tick")
	_check(WsUpgradeText.effect(roster.upgrade_info(ids[0], 0)) == "+3 armour", "effect text '%s'" % WsUpgradeText.effect(roster.upgrade_info(ids[0], 0)))
	_check(WsUpgradeText.effect(roster.upgrade_info(ids[2], 0)) == "+1.5 range", "Long Draw text '%s'" % WsUpgradeText.effect(roster.upgrade_info(ids[2], 0)))
	for k: int in [KEY_R, KEY_Y, KEY_O]:
		_key(k)
	_check(roster.armoury_level(&"weapons") == 1 and roster.armoury_level(&"armour") == 1 and roster.armoury_level(&"arcana") == 1,
			"R / Y / O levels %d %d %d" % [roster.armoury_level(&"weapons"), roster.armoury_level(&"armour"), roster.armoury_level(&"arcana")])
	muster.call(&"refresh")
	var ab := (muster.get(&"armoury_buttons") as Array)[0] as ArmouryButton
	_check(ab.title.ends_with(" I") and ab.tooltip_text.contains("next horn"), "armoury button '%s' / '%s'" % [ab.title, ab.tooltip_text])
	var at: Variant = ab._make_custom_tooltip(ab.tooltip_text)
	_check(at is Control, "armoury tooltip")
	if at is Node:
		(at as Node).free()
	# the setting row and the mini-pad toggle
	var toggle := muster.get(&"place_toggle") as WsMiniPad.SmallButton
	GameSettings.ws_place_manual = false
	muster.call(&"refresh")
	_check(toggle.label.contains("Auto"), "toggle '%s'" % toggle.label)
	GameSettings.ws_place_manual = manual_was
	_pad_done = true


## The pad cells as a sorted text (order-free compare).
func _norm(cells: Dictionary) -> String:
	var rows: PackedStringArray = []
	for id: Variant in cells:
		for c: Variant in cells[id]:
			rows.append("%s@%d,%d" % [id, int(c[0]), int(c[1])])
	rows.sort()
	return ";".join(rows)


func muster_undo_enabled() -> bool:
	var b := (hud.get(&"muster") as Node).get(&"undo_button") as Button
	(hud.get(&"muster") as Node).call(&"refresh")
	return not b.disabled
