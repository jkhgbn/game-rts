extends SceneTree
## Test for 3.U1 on the 1v1 map (scenes/skirmish.tscn), with real key events (physical keycodes):
## - hero column shows the level badge and "XP  x / y"; add_xp to level 2 = badge "2", level-up message,
##   points chip "+1" (SC2.U3 hero tile, ui-sc2-console.md 3.1; the spell slots r2c1-r2c3 since SC2.U1);
## - the E spell button (Kindle) is disabled with "Not learned · needs level 4";
## - Ctrl+Q learns Ember Step via learn_spell (no targeting starts), the chip disappears, Q shows pips;
## - F starts Fireball targeting, confirming casts it (mana spent);
## - Q (Ember Step) casts, then its button shows the cooldown sweep.
## Run:  godot --headless --path . -s tests/test_3_u1.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "3.u1"
const TIMEOUT_FRAMES := 600
const WARM_UP := 90

var main: Node
var sel: Node
var card: Node
var panel: Node
var hero: Node
var frame := 0
var _wait := 0
var _warm := 0
var _error := ""
var _done := false
var _mana_before := 0.0


func _initialize() -> void:
	main = load("res://scenes/skirmish.tscn").instantiate()
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	_warm += 1
	if _warm < WARM_UP:
		return false
	frame += 1
	_step()
	if _error != "":
		print("FAIL %s: %s" % [TASK_ID, _error])
		return true
	if _done:
		print("PASS %s" % TASK_ID)
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out at frame %d" % [TASK_ID, frame])
		return true
	return false


func _step() -> void:
	match frame:
		1:
			sel = main.selection
			card = main.hud.command_card
			panel = main.hud.selection_panel
			hero = main.hero
			if not hero.has_method("learn_spell") or hero.get_node_or_null("SpellCaster") == null:
				_error = "Wizard levels / SpellCaster not there yet"
				return
			if panel.hero_level.text != str(hero.level) or not panel.hero_xp.visible \
					or not panel.hero_xp_text.text.begins_with("XP  "):
				_error = "hero column: badge '%s', xp '%s'" % [panel.hero_level.text, panel.hero_xp_text.text]
				return
			if panel.points_chip.visible:
				_error = "points chip shown with 0 points"
				return
			hero.add_xp(200)
		3:
			if hero.level != 2 or panel.hero_level.text != "2":
				_error = "after 200 XP: level %d, badge '%s'" % [hero.level, panel.hero_level.text]
				return
			if not str(main.hud._message.text).contains("reaches level 2"):
				_error = "level-up message is '%s'" % main.hud._message.text
				return
			if not panel.points_chip.visible or panel.points_text.text != "+1":
				_error = "points chip: visible %s, '%s'" % [panel.points_chip.visible, panel.points_text.text]
				return
			sel.select_units([hero])
			card.refresh()
			var ids: Array = card.slot_ids()
			if ids.slice(5, 8) != ["fireball", "ember_step", "kindle"]:
				_error = "spell slots are %s" % [ids]
				return
			var ki: Button = card.buttons[7]
			if not ki.disabled or not ki.tooltip_text.ends_with("\nNot learned · needs level 4"):
				_error = "Kindle not disabled with the level reason: '%s'" % ki.tooltip_text
				return
			if not card.learn_chips[6].visible:
				_error = "no + chip on Ember Step with a point to spend"
				return
			# Ctrl+Q learns Ember Step.
			_key(KEY_Q, KEY_A, true)
		5:
			if hero.spell_rank(&"ember_step") != 1:
				_error = "Ctrl+Q did not learn Ember Step (rank %d)" % hero.spell_rank(&"ember_step")
				return
			if sel.get_pending_order() != &"":
				_error = "Ctrl+Q started targeting '%s'" % sel.get_pending_order()
				return
			card.refresh()
			if panel.points_chip.visible or card.learn_chips[6].visible:
				_error = "chips still shown after spending the point"
				return
			var pips: Array = card.rank_pips[6]
			if not pips[2].visible or pips[0].color != Color(1.0, 0.85, 0.4) or pips[1].color == pips[0].color:
				_error = "Ember Step rank pips wrong (Ember Step has 3 ranks, rank 1 learned)"
				return
			# F = Fireball targeting, then confirm 6 m away (in range): cast.
			hero.mana = hero.max_mana
			_mana_before = hero.mana
			_key(KEY_F, KEY_F)
		7:
			if sel.get_pending_order() != &"fireball":
				_error = "F did not start Fireball targeting ('%s')" % sel.get_pending_order()
				return
			sel.confirm_pending_at(hero.global_position + Vector3(6, 0, 0))
		12:
			if hero.mana > _mana_before - 30.0:
				_error = "Fireball not cast (mana %.1f -> %.1f)" % [_mana_before, hero.mana]
				return
			hero.mana = hero.max_mana
			_key(KEY_Q, KEY_A)
		14:
			if sel.get_pending_order() != &"ember_step":
				_error = "Q did not start Ember Step targeting ('%s')" % sel.get_pending_order()
				return
			sel.confirm_pending_at(hero.global_position + Vector3(0, 0, 5))
		20:
			sel.select_units([hero])
			card.refresh()
			if not card.cooldown_visible(6) or card.cooldown_labels[6].text == "":
				_error = "no cooldown sweep on Ember Step after the cast (cd left %.1f)" % \
						hero.get_node("SpellCaster").cooldown_left(&"ember_step")
				return
			if not card.buttons[6].disabled or not card.buttons[6].tooltip_text.ends_with("\nOn cooldown"):
				_error = "Ember Step button not disabled 'On cooldown'"
				return
			_done = true


func _key_event(physical: Key, printed: Key, pressed: bool, ctrl := false) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = physical
	ev.keycode = printed
	ev.pressed = pressed
	ev.ctrl_pressed = ctrl
	root.push_input(ev)


func _key(physical: Key, printed: Key, ctrl := false) -> void:
	_key_event(physical, printed, true, ctrl)
	_key_event(physical, printed, false, ctrl)
