extends SceneTree
## UR.U1 (unit-upgrades.md 11, ui-sc2-console.md 7.1-7.3): the research pages on the command card.
## Fire skirmish: Hall, Stables and keep show `+` on r3c5 (key =/+); the research page puts each unit on its training key
## (the key opens its unit page, never trains); a unit page holds Z = "+", X C V B = rows, then the Stables rank-3, max 5
## (checked on every unit of the table too); header r3c1, Back r3c5 (Esc: unit page -> research page -> closed);
## locked rows (`Requires Stronghold`, `Needs Heavy Draw`) are greyed with the lock and refuse with the reason; a busy slot
## says `Busy with another upgrade`; short of crystals stays bright and refuses; a key again on a running row cancels it
## with a full refund and the message `Research cancelled: ...`; a done row answers `Already researched`.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_research_card.gd --fixed-fps 60 --quit-after 30000

const TASK_ID := "research_card"
const SCENE := "res://scenes/skirmish.tscn"
const PLAYER := 0

var main: Node
var sel: SelectionManager
var card: CommandCard
var _errors: Array[String] = []
var _msgs: Array[String] = []
var _paused_seen := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	GameSettings.ensure_read()
	GameSettings.set_control_scheme(GameSettings.CONTROLS_CLASSIC, false)
	KeyLabels.overrides = {}
	_static_checks()
	await _game()
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors.slice(0, 30))])
	quit(0 if _errors.is_empty() else 1)


func _fail(what: String) -> void:
	_errors.append(what)
	print("  x " + what)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


## Every unit of the table: Z ("+" or empty) + its rows + a Stables rank-3 fit on row 1 (max 5).
func _static_checks() -> void:
	var units := {}
	for id: StringName in UnitResearch.ROWS:
		for u: StringName in (UnitResearch.ROWS[id] as Dictionary)["units"]:
			units[u] = true
	for u: StringName in units:
		var n := 1 + UnitResearch.rows_for_unit(u).size() + (1 if Stables16.has_rank_up(u) else 0)
		if n > SelectionManager.RESEARCH_PAGE_MAX:
			_fail("%s: %d buttons on its unit page (max %d)" % [u, n, SelectionManager.RESEARCH_PAGE_MAX])


func _game() -> void:
	main = load(SCENE).instantiate()
	main.set(&"player_kingdom", &"fire")
	main.set(&"enemy_kingdom", &"shadow")
	main.set(&"camps_enabled", false)
	main.set(&"beasts_enabled", false)
	root.add_child(main)
	current_scene = main
	var t0 := Time.get_ticks_msec()
	while not bool(main.get(&"match_started")):
		await process_frame
		if Time.get_ticks_msec() - t0 > 180000:
			_fail("the skirmish never started")
			return
	await _frames(5)
	sel = main.get(&"selection")
	card = (main.get(&"hud") as GameHUD).command_card
	sel.message.connect(func(t: String) -> void: _msgs.append(t))
	var path := StrIntPath.of(main.get(&"hero"))
	if path != null and not path.is_locked():
		path.choose(&"str")
	paused = false
	if not UnitResearch.enabled_here():
		_fail("UnitResearch is off in the skirmish")
		return
	var eco := Economy.for_team(PLAYER)
	eco.add(20000)
	var ts := TierSystem.instance()
	ts.time_gates = false
	ts.set_tier(PLAYER, 1)
	var keep: Keep = main.get(&"keep")
	var grid: BuildGrid = main.get(&"build_grid")
	var hall := _spawn(grid, BuildingType.find("fire_barracks"), keep, 16, 0)
	var stables := _spawn(grid, Stables16.stables_type(&"fire"), keep, 16, 14)
	if hall == null or stables == null:
		_fail("Hall / Stables not placed")
		return
	await _frames(3)

	# ---- Hall main card: + on r3c5, its tooltip; a training tooltip counts the unit's research.
	await _show(func() -> void: sel.select_building(hall))
	if _slot_id(CommandCard.PLUS_SLOT) != "plus_page" or _key(CommandCard.PLUS_SLOT) != "+":
		_fail("Hall main card r3c5 = '%s' key '%s' (want plus_page +)" % [_slot_id(CommandCard.PLUS_SLOT),
				_key(CommandCard.PLUS_SLOT)])
	var fg_slot := sel.train_slot_of(&"flame_guard")
	if not card.buttons[fg_slot].tooltip_text.contains("Research: 0 / 3 done"):
		_fail("Flame Guard training tooltip lacks 'Research: 0 / 3 done': %s" % card.buttons[fg_slot].tooltip_text)

	# ---- Research page: units on their training keys; header r3c1, Back r3c5; keys never train.
	_press(KEY_EQUAL)
	await _frames(2)
	if not sel.upgrades_open():
		_fail("+ did not open the Hall's research page")
	var ids := card.slot_ids()
	for i in sel.train_slots().size():
		var t: Variant = sel.train_slots()[i]
		if t == null:
			continue
		var uid := String((t as UnitType).id)
		var want := "research_unit_" + uid if SelectionManager.research_units(hall).has(StringName(uid)) else ""
		if ids[i] != want:
			_fail("research page slot %d = '%s' (want '%s')" % [i, ids[i], want])
		elif want != "" and _key(i) != sel.train_key(t, i):
			_fail("research page %s key '%s' (its training key is '%s')" % [uid, _key(i), sel.train_key(t, i)])
	if ids[CommandCard.RALLY_KEEP_SLOT] != "research_header" or _key(CommandCard.RALLY_KEEP_SLOT) != "":
		_fail("research page r3c1 = '%s' (want the header tile, no key)" % ids[CommandCard.RALLY_KEEP_SLOT])
	if ids[CommandCard.PLUS_SLOT] != "plus_back" or _key(CommandCard.PLUS_SLOT) != "Esc":
		_fail("research page r3c5 = '%s' key '%s' (want Back Esc)" % [ids[CommandCard.PLUS_SLOT], _key(CommandCard.PLUS_SLOT)])
	var q0 := (hall.get(&"queue") as Array).size()
	_press(_code_for(fg_slot))
	await _frames(2)
	if (hall.get(&"queue") as Array).size() != q0:
		_fail("the Flame Guard key on the research page trained a unit")
	if sel.open_research_unit_id() != &"flame_guard":
		_fail("the Flame Guard key did not open its unit page (%s)" % sel.open_research_unit_id())

	# ---- Flame Guard page: Z "+", X Kindled Mail, C Backdraft; tier 1 = "+" and Backdraft locked.
	ids = card.slot_ids()
	var want_page := ["plus_flame_guard", "research_flame_guard_kindled_mail", "research_flame_guard_backdraft"]
	for i in want_page.size():
		if ids[i] != want_page[i] or _key(i) != "ZXC"[i]:
			_fail("Flame Guard page slot %d = '%s' key '%s' (want %s %s)" % [i, ids[i], _key(i), want_page[i], "ZXC"[i]])
	for i in range(3, CommandCard.COLUMNS * CommandCard.ROWS):
		if ids[i] != "" and i != CommandCard.RALLY_KEEP_SLOT and i != CommandCard.PLUS_SLOT:
			_fail("Flame Guard page has '%s' on slot %d" % [ids[i], i])
	if ids[CommandCard.PLUS_SLOT] != "research_back":
		_fail("unit page r3c5 = '%s' (want research_back)" % ids[CommandCard.PLUS_SLOT])
	_check_locked(2, TierSystem.MSG_T2, "Backdraft at tier 1")
	_check_locked(0, TierSystem.MSG_T2, "Flame Guard+ at tier 1")
	if not card.buttons[1].tooltip_text.contains("Cost 75 crystals · 30 s") \
			or not card.buttons[1].tooltip_text.contains("+5 armor") or not card.buttons[1].tooltip_text.contains("For: Flame Guard"):
		_fail("Kindled Mail tooltip: %s" % card.buttons[1].tooltip_text)
	_msgs.clear()
	_press(KEY_C)
	await _frames(2)
	if not _msgs.has(TierSystem.MSG_T2):
		_fail("C on locked Backdraft did not answer '%s' (%s)" % [TierSystem.MSG_T2, str(_msgs)])

	# ---- X buys Kindled Mail (75); X again cancels with a full refund.
	var bank := UnitResearch.for_team(PLAYER)
	var c0 := eco.crystals
	_press(KEY_X)
	await _frames(2)
	if not bank.is_working(&"flame_guard_kindled_mail") or eco.crystals != c0 - 75:
		_fail("X did not start Kindled Mail (working %s, crystals %d -> %d)" % [bank.is_working(&"flame_guard_kindled_mail"),
				c0, eco.crystals])
	card.refresh()
	if not card.slots[1].has("research_progress") or card.buttons[1].disabled:
		_fail("Kindled Mail in progress: no progress sweep (or greyed)")
	if not card.buttons[1].tooltip_text.contains("press again to cancel"):
		_fail("in-progress tooltip lacks the cancel line: %s" % card.buttons[1].tooltip_text)
	# Busy slot: Backdraft at tier 2 while Kindled Mail runs here.
	ts.set_tier(PLAYER, 2)
	await _show(func() -> void: pass)
	if str(card.slots[2].get("reason", "")) != UnitResearch.REASON_BUSY or card.is_locked(2) \
			or not is_equal_approx(card.buttons[2].modulate.a, 0.45):
		_fail("Backdraft while busy: reason '%s', lock %s, alpha %.2f" % [card.slots[2].get("reason", ""), card.is_locked(2),
				card.buttons[2].modulate.a])
	_msgs.clear()
	_press(KEY_X)
	await _frames(2)
	if bank.is_working(&"flame_guard_kindled_mail") or eco.crystals != c0:
		_fail("X again did not cancel with a full refund (crystals %d, want %d)" % [eco.crystals, c0])
	if not _msgs.has("Research cancelled: Kindled Mail"):
		_fail("no 'Research cancelled: Kindled Mail' message (%s)" % str(_msgs))

	# ---- Short of crystals: bright, presses, refused with the reason (top bar shake through spend_failed).
	var keep_crystals := eco.crystals
	eco.crystals = 10
	var failed := [0]
	eco.spend_failed.connect(func() -> void: failed[0] += 1)
	await _show(func() -> void: pass)
	if str(card.slots[1].get("reason", "")) != UnitResearch.REASON_NO_CRYSTALS or card.buttons[1].disabled \
			or not is_equal_approx(card.buttons[1].modulate.a, 1.0):
		_fail("Kindled Mail short of crystals: reason '%s', disabled %s" % [card.slots[1].get("reason", ""),
				card.buttons[1].disabled])
	_msgs.clear()
	_press(KEY_X)
	await _frames(2)
	if not _msgs.has(UnitResearch.REASON_NO_CRYSTALS) or failed[0] == 0 or bank.is_working(&"flame_guard_kindled_mail"):
		_fail("X short of crystals: msgs %s, spend_failed %d" % [str(_msgs), failed[0]])
	eco.crystals = keep_crystals

	# ---- Done: grant it; the button shows done and answers "Already researched".
	bank.grant(&"flame_guard_kindled_mail")
	await _show(func() -> void: pass)
	if not bool(card.slots[1].get("done", false)) or card.cost_tags[1].visible:
		_fail("Kindled Mail done: no done look (or the cost tag still shows)")
	_msgs.clear()
	_press(KEY_X)
	await _frames(2)
	if not _msgs.has(UnitResearch.REASON_DONE):
		_fail("X on a done row did not answer '%s' (%s)" % [UnitResearch.REASON_DONE, str(_msgs)])

	# ---- Esc: unit page -> research page -> closed (never the pause menu).
	_press(KEY_ESCAPE)
	await _frames(2)
	if not sel.upgrades_open() or sel.open_research_unit_id() != &"":
		_fail("Esc on the unit page did not go back to the research page")
	_press(KEY_ESCAPE)
	await _frames(2)
	if sel.upgrades_open() or paused:
		_fail("Esc on the research page did not close it (or paused)")
		paused = false
	# The research page chip: Flame Guard 1/3 done.
	sel.open_upgrades()
	await _show(func() -> void: pass)
	if str(card.slots[fg_slot].get("chip", "")) != "1/3":
		_fail("Flame Guard research chip '%s' (want 1/3)" % card.slots[fg_slot].get("chip", ""))
	# + on a unit page closes both pages.
	sel.open_research_unit(&"flame_guard")
	_press(KEY_EQUAL)
	await _frames(2)
	if sel.upgrades_open():
		_fail("+ on a unit page did not close the pages")

	# ---- Chain lock: Scorchbow's Pitch Arrows needs Heavy Draw.
	var sb_slot := sel.train_slot_of(&"scorchbow")
	if sb_slot >= 0:
		sel.open_upgrades()
		sel.open_research_unit(&"scorchbow")
		await _show(func() -> void: pass)
		var pi := card.slot_ids().find("research_scorchbow_pitch_arrows")
		if pi < 1 or pi > 4:
			_fail("Scorchbow page has no Pitch Arrows on X-B: %s" % str(card.slot_ids()))
		else:
			_check_locked(pi, "Needs Heavy Draw", "Pitch Arrows")
		sel.close_upgrades()

	# ---- Stables: Blaze Rider page = X Running Start ... then its rank-3 (Z empty: the "+" is bought at the Hall).
	ts.set_tier(PLAYER, 3)
	await _show(func() -> void: sel.select_building(stables))
	if _slot_id(CommandCard.PLUS_SLOT) != "plus_page":
		_fail("Stables main card has no + on r3c5 (%s)" % str(card.slot_ids()))
	sel.open_upgrades()
	sel.open_research_unit(&"blaze_rider")
	await _show(func() -> void: pass)
	ids = card.slot_ids()
	var n_rows := UnitResearch.rows_for_unit(&"blaze_rider").size()
	if ids[0] != "" or ids[1 + n_rows] != "rank_blaze_rider" or _key(1 + n_rows) != "ZXCVB"[1 + n_rows]:
		_fail("Blaze Rider page at the Stables: %s (rank-3 on %s)" % [str(ids), "ZXCVB"[1 + n_rows]])
	sel.close_upgrades()

	# ---- Keep: + on r3c5; the caster on B.
	await _show(func() -> void: sel.select_building(keep))
	if _slot_id(CommandCard.PLUS_SLOT) != "plus_page":
		_fail("keep main card has no + on r3c5 (%s)" % str(card.slot_ids()))
	sel.open_upgrades()
	await _show(func() -> void: pass)
	var caster := CasterKit.caster_for(&"fire")
	if card.slot_ids()[4] != "research_unit_" + String(caster) or _key(4) != "B":
		_fail("keep research page: caster not on B (%s)" % str(card.slot_ids()))
	sel.close_upgrades()

	# ---- Enemy building selected: no page, and buy / rank / cancel never act for the enemy (review 2026-10-14).
	var ekeep: Node3D = main.call(&"keep_of", 1) if main.has_method(&"keep_of") else null
	var et := BuildingType.find("shadow_barracks")
	var espot := grid.find_spot(et, ekeep.global_position + (Vector3.ZERO - ekeep.global_position).normalized() * 16.0,
			1) if ekeep != null and et != null else Vector3.INF
	var ehall: Building = grid.spawn_complete(et, espot, 1) if espot != Vector3.INF else null
	if ehall == null:
		_fail("enemy Hall not placed")
	else:
		await _frames(2)
		sel.select_building(ehall)
		await _show(func() -> void: pass)
		if sel.can_open_upgrades() or card.slot_ids()[CommandCard.PLUS_SLOT] == "plus_page":
			_fail("an enemy Hall offers the research page")
		var eeco := Economy.for_team(1)   # read right before the calls: no frame runs between (the bot spends too)
		var ec0 := eeco.crystals if eeco else 0
		var ebank0 := UnitResearch.for_team(1, false)
		var r1 := sel.buy_research(&"shade_siphoning_blades")
		var r2 := sel.buy_upgrade(&"shade")
		var r3 := sel.rank_up_research(&"gloam_rider")
		var c3 := sel.cancel_research_at(ehall)
		var ebank := UnitResearch.for_team(1, false)
		if r1 != SelectionManager.MSG_NO_UPGRADE or r2 != SelectionManager.MSG_NO_UPGRADE \
				or r3 != SelectionManager.MSG_NO_UPGRADE or c3:
			_fail("enemy Hall: buy '%s', '+' '%s', rank '%s', cancel %s (want refusals)" % [r1, r2, r3, c3])
		if (ebank0 == null and ebank != null) or (ebank != null and ebank.working_at(ehall) != &"") \
				or (eeco != null and eeco.crystals != ec0):
			_fail("enemy Hall: research acted for the enemy (node made %s, crystals %d -> %d)" % [
					ebank0 == null and ebank != null, ec0, eeco.crystals if eeco else 0])

	# ---- AZERTY: the unit page badges print the AZERTY letters (Z -> W).
	KeyLabels.overrides = {KEY_Z: KEY_W, KEY_W: KEY_Z}
	sel.select_building(hall)
	sel.open_upgrades()
	sel.open_research_unit(&"flame_guard")
	await _show(func() -> void: pass)
	if _key(0) != "W" or not card.buttons[0].tooltip_text.get_slice("\n", 0).contains("[W]"):
		_fail("AZERTY: the unit page's Z shows '%s' (%s)" % [_key(0), card.buttons[0].tooltip_text.get_slice("\n", 0)])
	KeyLabels.overrides = {}
	sel.close_upgrades()
	main.queue_free()
	await _frames(3)


func _check_locked(i: int, reason: String, what: String) -> void:
	var r := str(card.slots[i].get("reason", ""))
	if r != reason or not card.is_locked(i) or not card.buttons[i].disabled \
			or not is_equal_approx(card.buttons[i].modulate.a, 0.45) \
			or not card.buttons[i].tooltip_text.ends_with(reason):
		_fail("%s: reason '%s' (want '%s'), lock %s, alpha %.2f, tooltip end '%s'" % [what, r, reason, card.is_locked(i),
				card.buttons[i].modulate.a, card.buttons[i].tooltip_text.get_slice("\n", -1)])


func _show(setup: Callable) -> void:
	setup.call()
	card.refresh()
	await _frames(1)
	card.refresh()


func _slot_id(i: int) -> String:
	return str(card.slots[i].get("id", ""))


func _key(i: int) -> String:
	return card.key_labels[i].text if card.buttons[i].visible and card.key_labels[i].visible else ""


func _code_for(slot: int) -> Key:
	return SelectionManager.SLOT_KEYS[slot]


func _spawn(grid: BuildGrid, type: BuildingType, keep: Node3D, fwd: float, side: float) -> Building:
	if type == null:
		return null
	var dir := -Vector3(keep.global_position.x, 0.0, keep.global_position.z).normalized()
	var spot := grid.find_spot(type, keep.global_position + dir * fwd + Vector3(dir.z, 0, -dir.x) * side, PLAYER)
	return grid.spawn_complete(type, spot, PLAYER) if spot != Vector3.INF else null


func _press(code: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.keycode = code
	ev.pressed = true
	root.push_input(ev)
	var up := ev.duplicate() as InputEventKey
	up.pressed = false
	root.push_input(up)
