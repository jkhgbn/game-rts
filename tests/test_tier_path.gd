extends SceneTree
## The way up must be obvious (2026-09-30, JS: "not sure there is a way to tier up / get better units"):
## Part skirmish (Fire, real match clock): the Next hint warns a minute before the Stronghold ("Soon: Stronghold at
##   3:30"), then says "upgrade your Keep to a Stronghold: select it, press X (200 crystals, 60 s)" with the exact units;
##   the tier chip reads "Tier 1 Keep · next: Stronghold at 3:30" then "... ready: X" (gold pulse); the keep's X button
##   pulses gold only while it can start; a Hall unit greyed "Requires Stronghold" tells where the way up is; X starts it;
##   the chip shows the progress; the completion message names the new units; the hint then names them with their keys
##   until one is queued; the Citadel follows the same path (hint, message with the tier-3 unit and the helper).
## Part kingdoms: for the 4 kingdoms, the Stronghold opens >= 2 Hall units + the kingdom's caster (keep, key B) and the
##   Citadel the keep's tier-3 unit + the helper; the keep tooltip lists them and what the upgrade needs.
## Part mission (mission 1): tiers on, capped at the Stronghold, the bot never upgrades; the Hall lists Pyre Adept and
##   Cinder Arbalest (greyed "Requires Stronghold") before the Blaze Rider, whose unlock keeps the keys; the keep lists
##   the Kilnwarden on B; at 3:30 the mission says how to upgrade and the chip / button pulse; X upgrades; the tier-2 units
##   and the caster open; no Citadel button; no skirmish Next hint in the mission.
## Run:  godot --headless --path . -s tests/test_tier_path.gd --fixed-fps 60 --quit-after 60000
##   Options after `--`: --only=skirmish|kingdoms|mission

const TASK_ID := "tier_path"
const SKIRMISH := "res://scenes/skirmish.tscn"
const MISSION := "res://missions/mission_01.tscn"
const PLAYER := 0
const ENEMY := 1
const SPEED := 8.0

var main: Node
var part := ""
var kingdom: StringName = &"fire"
var _queue: Array = []
var _errors: Array[String] = []
var _busy := false
var _wait := 0


func _initialize() -> void:
	var only: Array[String] = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			for p in a.trim_prefix("--only=").split(",", false):
				only.append(p)
	StrIntPath.force_auto = true
	NextStepHint.dismissed = false
	if only.is_empty() or only.has("skirmish"):
		_queue.append(["skirmish", &"fire"])
	if only.is_empty() or only.has("kingdoms"):
		for k in [&"fire", &"shadow", &"ice", &"nature"]:
			_queue.append(["kingdoms", k])
	if only.is_empty() or only.has("mission"):
		_queue.append(["mission", &"fire"])
	_next_part()


func _next_part() -> void:
	if main != null and is_instance_valid(main):
		main.queue_free()
		main = null
	Engine.time_scale = 1.0
	if _queue.is_empty():
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		quit()
		return
	var p: Array = _queue.pop_front()
	part = p[0]
	kingdom = p[1]
	_busy = false
	_wait = 0
	if part == "mission":
		main = load(MISSION).instantiate()
		main.set(&"show_briefing", false)
		main.set(&"save_campaign_on_victory", false)
	else:
		main = load(SKIRMISH).instantiate()
		main.set(&"player_kingdom", kingdom)
		main.set(&"enemy_kingdom", &"shadow" if kingdom != &"shadow" else &"fire")
		main.set(&"camps_enabled", false)
		main.set(&"beasts_enabled", false)
		_calm_bot()
	root.add_child(main)
	current_scene = main
	print("---- part %s (%s)" % [part, kingdom])


## The skirmish bot plays normal but never attacks (its 3:00 rush would kill the test's Hall and soldiers).
func _calm_bot() -> void:
	for child in main.get_children():
		if child is Commander:
			var p := AIProfile.for_difficulty(1)
			p.launch_attacks = false
			child.set(&"profile", p)
			child.set(&"profile_id", &"")


func _process(_delta: float) -> bool:
	if main == null or _busy:
		return false
	if not bool(main.get(&"match_started")) or main.get(&"hero") == null:
		_wait += 1
		if _wait > 6000:
			print("FAIL %s: %s never started" % [TASK_ID, part])
			return true
		return false
	_busy = true
	match part:
		"skirmish":
			_run_skirmish()
		"kingdoms":
			_run_kingdom()
		"mission":
			_run_mission()
	return false


func _check(ok: bool, what: String) -> void:
	if not ok:
		_errors.append("%s/%s: %s" % [part, kingdom, what])
		print("  x " + what)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


## Runs the match clock up to `t` seconds at SPEED.
func _run_to(t: float) -> void:
	Engine.time_scale = SPEED
	var guard := 0
	while float(main.call(&"match_time")) < t and guard < 20000:
		guard += 1
		await physics_frame
	Engine.time_scale = 1.0
	await _frames(2)


func _hint() -> NextStepHint:
	var hud: Node = main.get(&"hud")
	return hud.get(&"next_step_hint") as NextStepHint if hud else null


func _chip() -> TierChip:
	var hud: Node = main.get(&"hud")
	return hud.get(&"tier_chip") as TierChip if hud else null


func _card() -> CommandCard:
	return (main.get(&"hud") as Node).get(&"command_card") as CommandCard


func _message() -> String:
	var hud: Node = main.get(&"hud")
	var m: Variant = hud.get(&"_message")
	return (m as Label).text if m is Label and bool(hud.call(&"is_message_shown")) else ""


## The keep card's slot index of `id` ("train_keep_upgrade" ...), -1 when absent.
func _slot_of(id: String) -> int:
	var card := _card()
	card.refresh()
	return card.slot_ids().find(id)


func _spawn_hall() -> TrainingBuilding:
	var t := NextStepHint.building_of(kingdom, &"barracks")
	var keep: Keep = main.get(&"keep")
	var grid: BuildGrid = main.get(&"build_grid")
	var dir := -Vector3(keep.global_position.x, 0.0, keep.global_position.z).normalized()
	for r in [16.0, 19.0, 13.0, 22.0]:
		for a in [0.0, 0.5, -0.5, 1.0, -1.0]:
			var p := grid.snap(keep.global_position + dir.rotated(Vector3.UP, a) * r, t.footprint)
			if grid.check(t, p, PLAYER) == "":
				return grid.spawn_complete(t, p, PLAYER) as TrainingBuilding
	return null


# ---------------------------------------------------------------- part skirmish

func _run_skirmish() -> void:
	var keep: Keep = main.get(&"keep")
	var eco: Economy = main.get(&"economy")
	var sel: SelectionManager = main.get(&"selection")
	var ts := TierSystem.instance()
	_check(ts != null and ts.max_tier == 3 and ts.bots_upgrade, "skirmish TierSystem (cap 3, bots upgrade)")
	var chip := _chip()
	_check(chip != null, "no tier chip in the skirmish")
	if chip:
		chip.refresh()
		_check(chip.text() == "Tier 1 Keep · next: Stronghold at 3:30", "chip at start '%s'" % chip.text())
	var hall := _spawn_hall()
	_check(hall != null, "could not place a Hall")
	if hall == null:
		_next_part()
		return
	# Past the train step: three soldiers.
	var soldier: UnitType = hall.trainable_types()[0]
	for i in 3:
		var u := soldier.create_unit()
		u.team = PLAYER as Unit.Team
		main.add_child(u)
		u.global_position = hall.global_position + Vector3(4.0 + i, 0.0, 4.0)
		# Re-anchor here: _ready anchored it at the origin (the map centre), so a soldier that chased a passing enemy
		# past its leash walked "home" into the Ruin Wardens and died, and the hint fell back to "train soldiers".
		u.command_stop()
	eco.add(1000)
	await _run_to(140.0)
	var hint := _hint()
	_check(hint != null, "no Next hint")
	if hint == null:
		_next_part()
		return
	hint.refresh()
	_check(not hint.label.text.contains("Soon:"), "Soon line too early at 2:20 (%s)" % hint.label.text)
	if chip:
		chip.refresh()
		_check(chip.text() == "Tier 1 Keep · next: Stronghold at 3:30", "chip at 2:20 '%s'" % chip.text())
		_check(not chip.ready_now, "chip pulses before 3:30")
	# 3:00: the hint warns.
	await _run_to(181.0)
	hint.refresh()
	_check(hint.label.text.contains("Soon: Stronghold at 3:30") and hint.label.text.contains("200 crystals"),
			"no Soon line at 3:01 (%s)" % hint.label.text)
	sel.select_building(keep)
	await _frames(2)
	var ix := _slot_of("train_keep_upgrade")
	_check(ix == 1, "Stronghold button on r1c2 (slot %d)" % ix)
	var card := _card()
	_check(ix >= 0 and not card.attention_active(ix), "the X button pulses before 3:30")
	var tip := String(card.slots[ix]["tooltip"]) if ix >= 0 else ""
	for want in ["Opens: ", "Pyre Adept", "Cinder Arbalest", "Kilnwarden", "Needs from 3:30", "a completed Hall", "Stronghold  [X]"]:
		_check(tip.contains(want), "keep tooltip lacks '%s' (%s)" % [want, tip.replace("\n", " / ")])
	# The Hall's greyed tier-2 unit says where the way up is.
	sel.select_building(hall)
	await _frames(2)
	card.refresh()
	var adept_ix := card.slot_ids().find("train_pyre_adept")
	_check(adept_ix >= 0 and card.slots[adept_ix]["reason"] == TierSystem.MSG_T2, "Pyre Adept greyed Requires Stronghold")
	if adept_ix >= 0:
		_check(String(card.slots[adept_ix]["tooltip"]).contains("Upgrade your Keep to a Stronghold: select it, press X (from 3:30)"),
				"Hall tooltip lacks the way up (%s)" % String(card.slots[adept_ix]["tooltip"]).replace("\n", " / "))
	# 3:30: ready everywhere.
	await _run_to(211.0)
	hint.refresh()
	_check(hint.step == NextStepHint.STEP_TIER, "hint step at 3:31 = %s" % hint.step)
	var ht := hint.label.text
	for want in ["upgrade your Keep to a Stronghold: select it, press X (200 crystals, 60 s)", "it opens Pyre Adept",
			"Cinder Arbalest", "Kilnwarden"]:
		_check(ht.contains(want), "Stronghold hint lacks '%s' (%s)" % [want, ht.replace("\n", " / ")])
	_check(not ht.to_lower().contains("tier"), "the hint says 'tier' (%s)" % ht)
	if chip:
		chip.refresh()
		_check(chip.text() == "Tier 1 Keep · Stronghold ready: X" and chip.ready_now, "chip at 3:31 '%s'" % chip.text())
	sel.select_building(keep)
	await _frames(2)
	ix = _slot_of("train_keep_upgrade")
	_check(ix >= 0 and card.attention_active(ix), "the X button does not pulse at 3:31")
	# Short of crystals: the hint says to save, the button stops pulsing (it is greyed).
	var spare := eco.crystals - 100
	eco.spend(spare)
	hint.refresh()
	_check(hint.label.text.contains("save 200 crystals"), "short hint '%s'" % hint.label.text)
	card.refresh()
	_check(not card.attention_active(ix), "a greyed X button still pulses")
	eco.add(spare)
	# X on the keep.
	await _press(KEY_X)
	_check(keep.is_upgrading(), "X did not start the Stronghold (%s)" % keep.can_upgrade())
	if chip:
		chip.refresh()
		_check(chip.text().begins_with("Upgrading to Stronghold 0 %") or chip.text().begins_with("Upgrading to Stronghold 1 %"),
				"chip while upgrading '%s'" % chip.text())
	hint.refresh()
	_check(hint.step != NextStepHint.STEP_TIER, "hint still asks for the Stronghold while upgrading")
	var ps := SelectionPanel.keep_tier_text(keep)
	_check(ps.begins_with("Upgrading to Stronghold"), "selection panel keep line '%s'" % ps)
	# Done: message + new units step.
	var guard := 0
	Engine.time_scale = SPEED
	while keep.tier < 2 and guard < 3000:
		guard += 1
		await physics_frame
	Engine.time_scale = 1.0
	await _frames(2)
	var msg := _message()
	_check(msg.begins_with("The Keep is now a Stronghold. New: ") and msg.contains("Pyre Adept") and msg.contains("Kilnwarden (Keep)"),
			"Stronghold message '%s'" % msg)
	_check(SelectionPanel.keep_tier_text(keep) == "Tier 2 Stronghold", "selection panel '%s'" % SelectionPanel.keep_tier_text(keep))
	hint.refresh()
	if hint.step != NextStepHint.STEP_NEW_UNITS:
		var st := hint.read_state()
		print("  hint state: army %d trained %d pop %d/%d new_units %d" % [int(st.army), int(st.trained), int(st.pop_used),
				int(st.pop_cap), (st.new_units as Array).size()])
	_check(hint.step == NextStepHint.STEP_NEW_UNITS, "hint step after the Stronghold = %s" % hint.step)
	var nt := hint.label.text
	var adept_key := KeyLabels.letter(SelectionManager.SLOT_LETTERS[hall.trainable_types().find(UnitType.find("pyre_adept"))])
	_check(nt.contains("train your new Stronghold units") and nt.contains("%s Pyre Adept" % adept_key)
			and nt.contains("the Keep: %s Kilnwarden" % KeyLabels.of(KEY_B)), "new units hint '%s'" % nt)
	# Queue one: the step ends.
	_check(hall.queue_unit(UnitType.find("pyre_adept")) == "", "Pyre Adept refused at the Stronghold")
	hint.refresh()
	_check(hint.step != NextStepHint.STEP_NEW_UNITS, "new-units step after queueing one (%s)" % hint.step)
	if chip:
		chip.refresh()
		_check(chip.text() == "Tier 2 Stronghold · next: Citadel at 5:45", "chip at the Stronghold '%s'" % chip.text())
	# Citadel.
	eco.add(1000)
	await _run_to(346.0)
	hint.refresh()
	_check(hint.step == NextStepHint.STEP_TIER and hint.label.text.contains("to a Citadel") and hint.label.text.contains("(helper)"),
			"Citadel hint '%s'" % hint.label.text)
	sel.select_building(keep)
	await _frames(2)
	await _press(KEY_X)
	_check(keep.is_upgrading(), "X did not start the Citadel (%s)" % keep.can_upgrade())
	guard = 0
	Engine.time_scale = SPEED
	while keep.tier < 3 and guard < 4000:
		guard += 1
		await physics_frame
	Engine.time_scale = 1.0
	await _frames(2)
	msg = _message()
	_check(msg.begins_with("The Keep is now a Citadel. New: ") and msg.contains("Ashveil Saboteur") and msg.contains("Old Vey (helper)"),
			"Citadel message '%s'" % msg)
	if chip:
		chip.refresh()
		_check(chip.text() == "Tier 3 Citadel" and not chip.ready_now, "chip at the Citadel '%s'" % chip.text())
	hint.refresh()
	_check(hint.step == NextStepHint.STEP_NEW_UNITS and hint.label.text.contains("%s Ashveil Saboteur" % KeyLabels.of(KEY_C)),
			"Citadel new units hint '%s'" % hint.label.text)
	print("skirmish: hint / chip / card / messages OK")
	_next_part()


func _press(code: Key) -> void:
	for pressed in [true, false]:
		var ev := InputEventKey.new()
		ev.physical_keycode = code
		ev.keycode = code
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await process_frame
		await process_frame


# ---------------------------------------------------------------- part kingdoms

func _run_kingdom() -> void:
	var ts := TierSystem.instance()
	var keep: Keep = main.get(&"keep")
	ts.time_gates = false
	var hall := _spawn_hall()
	_check(hall != null, "could not place a Hall")
	await _frames(2)
	var t2 := TierSystem.unlocks(PLAYER, 2)
	var hall_units := t2.filter(func(d: Dictionary) -> bool: return not (d["building"] is Keep))
	var keep_units := t2.filter(func(d: Dictionary) -> bool: return d["building"] is Keep)
	_check(hall_units.size() >= 2, "Stronghold Hall units %s" % str(NextStepHint.unit_names(hall_units)))
	var caster := UnitType.find(String(CasterKit.caster_for(kingdom)))
	_check(caster != null and keep_units.any(func(d: Dictionary) -> bool: return d["type"] == caster),
			"Stronghold keep units %s (want the caster)" % str(NextStepHint.unit_names(keep_units)))
	for d: Dictionary in keep_units:
		if d["type"] == caster:
			_check(NextStepHint.slot_key(d) == KeyLabels.of(KEY_B), "caster key '%s'" % NextStepHint.slot_key(d))
	var t3 := TierSystem.unlocks(PLAYER, 3)
	var names3 := NextStepHint.unit_names(t3)
	var t3unit := UnitType.find(String(T3Kit.KEEP_UNITS.get(kingdom, &"")))
	_check(t3unit != null and names3.has(t3unit.display_name), "Citadel units %s (want %s)" % [str(names3),
			t3unit.display_name if t3unit else "?"])
	_check(names3.any(func(n: String) -> bool: return n.ends_with("(helper)")), "Citadel helper missing %s" % str(names3))
	var tip := keep.tier_card_text(2)
	_check(tip.contains(caster.display_name if caster else "?") and tip.contains("Needs "), "keep tooltip '%s'" % tip)
	_check(TierSystem.announce_text(PLAYER, 2).contains(caster.display_name if caster else "?"),
			"announce '%s'" % TierSystem.announce_text(PLAYER, 2))
	# At the Citadel the tier-3 keys are C (unit) and V (helper).
	ts.set_tier(PLAYER, 3)
	await _frames(2)
	for d: Dictionary in TierSystem.unlocks(PLAYER, 3):
		if d["building"] is Keep:
			var want := KeyLabels.of(KEY_V) if String(d["name"]).ends_with("(helper)") else KeyLabels.of(KEY_C)
			_check(NextStepHint.slot_key(d) == want, "%s key '%s' (want %s)" % [d["name"], NextStepHint.slot_key(d), want])
	print("%s: T2 %s | T3 %s" % [kingdom, TierSystem.unlock_text(PLAYER, 2), TierSystem.unlock_text(PLAYER, 3)])
	_next_part()


# ---------------------------------------------------------------- part mission

func _run_mission() -> void:
	var ts := TierSystem.instance()
	_check(ts != null, "mission 1 has no TierSystem")
	if ts == null:
		_next_part()
		return
	_check(ts.max_tier == 2 and not ts.bots_upgrade, "mission caps: max %d, bots %s" % [ts.max_tier, ts.bots_upgrade])
	_check(_hint() == null, "the skirmish Next hint shows in the mission")
	var chip := _chip()
	_check(chip != null, "no tier chip in the mission")
	var keep: Keep = main.get(&"keep")
	var hall: TrainingBuilding = main.get(&"ember_hall")
	var sel: SelectionManager = main.get(&"selection")
	var ids: Array[String] = []
	for t in hall.trainable_types():
		ids.append(String(t.id))
	_check(ids == ["flame_guard", "ember_archer", "pyre_adept", "cinder_arbalest"], "mission Hall %s" % str(ids))
	_check(hall.can_queue(UnitType.find("pyre_adept")) == TierSystem.MSG_T2, "Pyre Adept before the Stronghold: '%s'"
			% hall.can_queue(UnitType.find("pyre_adept")))
	sel.select_building(keep)
	await _frames(2)
	var card := _card()
	card.refresh()
	var slot_ids := card.slot_ids()
	_check(slot_ids[0] == "train_cinder_hand" and slot_ids[1] == "train_keep_upgrade" and slot_ids[4] == "train_kilnwarden"
			and slot_ids[8] == "rally", "mission keep card %s" % str(slot_ids))
	_check(card.slots[1]["reason"] == "Available at 3:30", "mission Stronghold before 3:30: '%s'" % card.slots[1]["reason"])
	_check(card.slots[4]["reason"] == TierSystem.MSG_T2, "Kilnwarden before the Stronghold: '%s'" % card.slots[4]["reason"])
	# Westwatch's Blaze Rider takes the next slot: the tier-2 keys never move.
	main.call(&"_unlock_riders")
	ids.clear()
	for t in hall.trainable_types():
		ids.append(String(t.id))
	_check(ids == ["flame_guard", "ember_archer", "pyre_adept", "cinder_arbalest", "blaze_rider"], "after Westwatch %s" % str(ids))
	# 3:30: the mission's message, the chip, the pulse.
	(main.get(&"economy") as Economy).add(600)
	await _run_to(213.0)
	_check(bool(main.get(&"stronghold_hint_shown")), "no Stronghold message at 3:33")
	var msg := _message()
	_check(msg.begins_with("Your Keep can become a Stronghold: select the Keep and press X (200 crystals). It opens Pyre Adept"),
			"mission message '%s'" % msg)
	if chip:
		chip.refresh()
		_check(chip.text() == "Tier 1 Keep · Stronghold ready: X" and chip.placement == &"top_bar", "mission chip '%s' (%s)"
				% [chip.text(), chip.placement])
	sel.select_building(keep)
	await _frames(2)
	card.refresh()
	_check(card.attention_active(1), "mission X button does not pulse")
	await _press(KEY_X)
	_check(keep.is_upgrading(), "X did not start the mission Stronghold (%s)" % keep.can_upgrade())
	var guard := 0
	Engine.time_scale = SPEED
	while keep.tier < 2 and guard < 3000:
		guard += 1
		await physics_frame
	Engine.time_scale = 1.0
	await _frames(2)
	_check(keep.tier == 2, "mission Stronghold never finished")
	_check(hall.can_queue(UnitType.find("pyre_adept")) in ["", TrainingBuilding.REASON_NO_CRYSTALS, "Population cap reached"],
			"Pyre Adept at the Stronghold: '%s'" % hall.can_queue(UnitType.find("pyre_adept")))
	_check(keep.can_queue(UnitType.find("kilnwarden")) in ["", TrainingBuilding.REASON_NO_CRYSTALS, "Population cap reached"],
			"Kilnwarden at the Stronghold: '%s'" % keep.can_queue(UnitType.find("kilnwarden")))
	_check(keep.tier_card_type() == null, "mission shows a Citadel button")
	_check(keep.can_upgrade() == TierSystem.MSG_NOT_HERE, "mission Citadel: '%s'" % keep.can_upgrade())
	if chip:
		chip.refresh()
		_check(chip.text() == "Tier 2 Stronghold", "mission chip at the Stronghold '%s'" % chip.text())
	var shadow_keep: Keep = main.get(&"shadow_keep")
	_check(shadow_keep != null and shadow_keep.tier == 1 and not shadow_keep.is_upgrading(), "Malrik's keep upgraded")
	_check(not bool(main.get(&"game_over")), "the mission ended during the test")
	print("mission: Stronghold path OK")
	_next_part()
