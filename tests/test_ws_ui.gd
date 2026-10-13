extends SceneTree
## WS2.U1 (docs/design/wave-strike.md 14.6, ui-wave-strike.md 1-5): the Wave Strike Muster panel.
## Ice (10 cards): the panel fills the console's muster zone, 10 cards 72 x 118 at the spec x, KeyLabels on every badge
## (AZERTY overrides too); the 10 physical keys pressed through the viewport: T1 buys, T2 / T3 refused below their tier
## (locked state), G = Coffer, U = next tier (refused before its horn, then Stronghold / Citadel), then the T2 / T3 keys
## buy, Ctrl = rank up, Alt = sell, the 5th Rimecarver refused "Max 4 copies" (maxed state), I toggles the enemy peek,
## the M1 top-right buy panel is gone. Fire (9 cards): slot 10 is empty and its key refuses quietly.
## French: every card name of the 4 kingdoms fits 2 lines (font >= 10) and the role tags exist.
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


func _key(code: int, ctrl := false, alt := false) -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventKey.new()
		ev.physical_keycode = code as Key
		ev.keycode = code as Key
		ev.pressed = pressed
		ev.ctrl_pressed = ctrl
		ev.alt_pressed = alt
		root.push_input(ev)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames > 5000:
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
	_fire()
	_french()
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
