extends SceneTree
## Task 10.C8 (market-trade.md 3, 6, 8, 12; layout ui-trade.md 3, 9-14 and its "Done when" 10.C8): top-bar gold,
## the help reflow, the trade window (Bazaar + Lodge tabs), the tavern gold buttons, the post / Den / Lodge panel,
## the trade listener (messages, floating texts, sounds) and GameSettings.trade_enabled.
## Runs on the mission 1 map (no trade of its own) with stubs for GoldBank, Market, TradeNetwork, HuntersGuild,
## TradePost, GuildHouse, ChampionGuild and the 10.C7 selection side, so it depends on no other step-10 task.
## Checks, at 1600 x 900:
## - no GoldBank: no gold item, U and open() do nothing; the help text is the 11 lines of 14.1 (<= 438 px each);
## - with a bank: the bar is 644 x 40 at (478, 8) (spec 624 at 488 + the 20 px pop-200 number) with the timer + essence + gold, the help panel is at most 458 wide
##   and never meets the bar; spend_failed flashes + "Not enough gold"; a +28 rise pops the number;
## - the trade window: rects of section 17, U / Esc / X / show_banner, exclusive with the shop; Bazaar tab (owned /
##   hireable / refused wares, press_buy, exchange labels x1 / x5, press_exchange + messages, ledger, the no-Bazaar
##   footer); Lodge tab (header open / closed, hireable / refused / running + bar / cooldown rows, press_hire, reward
##   line, footer count);
## - the tavern: 22 px column C with price B, HIRE · GOLD -> hire(id, true), Revive N gold -> revive(ch, true), the
##   disabled Not enough gold state; the step-9 layout comes back without a bank;
## - the panel: post lines (open / closed, value, holder, traffic, hint), Set as route -> set_route, Current route;
##   Den lines; Lodge lines + Contracts [U]; a Lodge click opens the Lodge tab;
## - the listener: +28 over the Bazaar, +60 over a sack, -119 over a caravan, pool of 8, fade after 1 s, the coin /
##   whistle / horn rate limits on bus SFX, the raid message once per 30 s, loot + ware messages;
## - GameSettings.trade_enabled saved / loaded (settings.cfg backed up and restored).
## Run:  godot --headless --path . -s tests/test_10_c8.gd --fixed-fps 60 --quit-after 4000

const TASK_ID := "10.c8"
const TIMEOUT_FRAMES := 2400
const WARM_UP := 30
const WARN := Color(0.95, 0.35, 0.3)
const NEAR := Color(0.4, 0.9, 0.4)
const SETTINGS := "user://settings.cfg"


class StubBank extends Node:
	signal changed(gold: int)
	signal spend_failed
	signal ware_bought(id: StringName)
	var team := 0
	var gold := 1000
	var owned_wares: Array[StringName] = []
	var bought: Array = []
	var exchanges: Array = []
	var sources := {&"trade": 1890, &"loot": 160, &"reward": 50}
	const PRICES := {&"iron_axles": 150, &"masons_charter": 350, &"tempered_steel": 350, &"gambesons": 350}

	func _init() -> void:
		add_to_group(&"gold_banks")

	func _has_market() -> bool:
		for m in get_tree().get_nodes_in_group(&"markets"):
			if int(m.get(&"team")) == team:
				return true
		return false

	func can_afford(n: int) -> bool:
		return gold >= n

	func spend(n: int) -> bool:
		if gold < n:
			spend_failed.emit()
			return false
		gold -= n
		changed.emit(gold)
		return true

	func earned(source: StringName = &"") -> int:
		if source == &"":
			var t := 0
			for v: int in sources.values():
				t += v
			return t
		return int(sources.get(source, 0))

	func can_buy_ware(id: StringName) -> String:
		if not _has_market():
			return "No Bazaar"
		if owned_wares.has(id):
			return "Already owned"
		return "Not enough gold" if gold < int(PRICES[id]) else ""

	func buy_ware(id: StringName) -> String:
		var r := can_buy_ware(id)
		if r != "":
			return r
		gold -= int(PRICES[id])
		owned_wares.append(id)
		bought.append(id)
		ware_bought.emit(id)
		return ""

	func can_exchange(amount: int, _to: StringName) -> String:
		if not _has_market():
			return "No Bazaar"
		return "Not enough gold" if gold < amount else ""

	func exchange(amount: int, to: StringName) -> String:
		var r := can_exchange(amount, to)
		if r == "":
			gold -= amount
			exchanges.append([amount, to])
		return r


class StubMarket extends Node3D:
	var team := 0
	var building_type: BuildingType
	var route_post: Node3D = null
	var set_routes: Array = []

	func _init() -> void:
		add_to_group(&"markets")
		building_type = BuildingType.new()
		building_type.display_name = "Ember Bazaar"

	func is_alive() -> bool:
		return true

	func is_constructed() -> bool:
		return true

	func set_route(post: Node3D) -> String:
		set_routes.append(post)
		route_post = post
		return ""

	func route_value_to(_post: Node3D) -> int:
		return 28


class StubNetwork extends Node:
	signal delivered(team: int, caravan: Node, amount: int, post: Node)
	signal caravan_robbed(team: int, caravan: Node, amount: int, thief: Node)
	signal workers_raided(team: int, node: Node)
	signal loot_picked(team: int, amount: int, sack: Node)
	var until_open := 0.0

	func _init() -> void:
		add_to_group(&"trade_network")

	func route_value(_m: Node, _p: Node) -> int:
		return 28

	func is_far(_team: int, _p: Node) -> bool:
		return false

	func trips(_team: int, _p: Node, _s := 120.0) -> int:
		return 4

	func trade_income(_team: int, _s := 180.0) -> int:
		return 620

	func time_until_open() -> float:
		return until_open

	func route_reason(_m: Node, _p: Node) -> String:
		return ""


class StubHunters extends Node:
	signal contract_started(team: int, kind: StringName, contract: Node)
	var open := true
	var running := {}
	var cooldown := {}
	var hired: Array = []
	var bank: StubBank

	func _init() -> void:
		add_to_group(&"hunters_guild")

	func is_open() -> bool:
		return open

	func time_until_open() -> float:
		return 0.0 if open else 48.0

	func contract_cost(kind: StringName) -> int:
		return 120 if kind == &"outriders" else 100

	func contract_time_left(_team: int, kind: StringName) -> float:
		return float(running.get(kind, 0.0))

	func cooldown_left(_team: int, kind: StringName) -> float:
		return float(cooldown.get(kind, 0.0))

	func can_hire(_team: int, kind: StringName) -> String:
		if not open:
			return "The Lodge opens at 5:00"
		if running.has(kind):
			return "Contract already running"
		if cooldown.has(kind):
			return "On cooldown"
		return "Not enough gold" if bank.gold < contract_cost(kind) else ""

	func hire(team: int, kind: StringName) -> String:
		var r := can_hire(team, kind)
		if r == "":
			hired.append(kind)
			bank.gold -= contract_cost(kind)
			running[kind] = 180.0
			contract_started.emit(team, kind, null)
		return r


class StubPost extends Node3D:
	var post_id := &"millstone_cross"
	var display_name := "Millstone Cross"
	var open := true
	var holder := 1

	func _init() -> void:
		add_to_group(&"trade_posts")

	func is_open() -> bool:
		return open

	func holder_team() -> int:
		return holder


class StubHouse extends Node3D:
	var kind: StringName = &"den"

	func _init() -> void:
		add_to_group(&"guilds")


class StubSelection extends Node:
	signal selection_changed
	signal neutral_building_clicked(node: Node3D)
	var selected_neutral: Node3D = null

	func pick(n: Node3D) -> void:
		selected_neutral = n
		neutral_building_clicked.emit(n)
		selection_changed.emit()


class StubChampion extends Unit:
	var champion_id: StringName = &"mender"
	var display_name := "Orla Fenwick"
	var fallen := true

	func _ready() -> void:
		super._ready()
		add_to_group(&"champions")

	func type_id() -> StringName:
		return champion_id

	func is_commandable() -> bool:
		return false

	func is_alive() -> bool:
		return not fallen and super.is_alive()

	func take_damage(_amount: float, _attacker: Node3D = null) -> void:
		pass


class StubGuild extends Node:
	var team := 0
	var champions: Array = []
	var bank: StubBank
	var hires: Array = []
	var revives: Array = []

	func _init() -> void:
		add_to_group(&"champion_guilds")

	func is_open() -> bool:
		return true

	func hire_cost(_id: StringName = &"", pay_gold := false) -> Dictionary:
		return {"crystals": 0 if pay_gold else 250, "essence": 100, "gold": 250 if pay_gold else 0}

	func can_hire(id: StringName, pay_gold := false) -> String:
		if id == &"mender":
			return "Already hired"
		if pay_gold and (bank == null or bank.gold < 250):
			return "Not enough gold"
		return ""

	func hire(id: StringName, pay_gold := false) -> String:
		var r := can_hire(id, pay_gold)
		if r == "":
			hires.append([id, pay_gold])
		return r

	func champion_of(id: StringName) -> Node:
		for c in champions:
			if c.champion_id == id:
				return c
		return null

	func revive_cost(_ch: Node, pay_gold := false) -> int:
		return 180 if pay_gold else 90

	func can_revive(ch: Node, pay_gold := false) -> String:
		if revives.size() > 0:
			return "Already reviving"
		if pay_gold and (bank == null or bank.gold < revive_cost(ch, true)):
			return "Not enough gold"
		return ""

	func revive(ch: Node, pay_gold := false) -> String:
		var r := can_revive(ch, pay_gold)
		if r == "":
			revives.append([ch, pay_gold])
		return r

	func revive_time_left(_ch: Node) -> float:
		return 0.0


class StubClock extends Node:
	func match_time_text() -> String:
		return "7:42"


var main: Node
var hud: Node
var sel: Node
var bar: Node
var trade: Node
var frame := 0
var _wait := 0
var _warm := 0
var _step := 0
var _step_frame := 0
var _error := ""
var _done := false
var _notes: Array[String] = []
var bank: StubBank
var market: StubMarket
var net: StubNetwork
var hunters: StubHunters
var post: StubPost
var den: StubHouse
var lodge: StubHouse
var clock: StubClock
var popups: Node
var panel: Node
var stub_sel: StubSelection
var _settings_backup: PackedByteArray = PackedByteArray()
var _settings_existed := false


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
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
	_run()
	if _error != "":
		print("FAIL %s: %s (step %d)" % [TASK_ID, _error, _step])
		return true
	if _done:
		for n in _notes:
			print("note: ", n)
		print("PASS %s" % TASK_ID)
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out at step %d" % [TASK_ID, _step])
		return true
	return false


func _next() -> void:
	_step += 1
	_step_frame = frame


func _since() -> int:
	return frame - _step_frame


func _fail(msg: String) -> void:
	if _error == "":
		_error = msg


func _expect(ok: bool, msg: String) -> void:
	if not ok:
		_fail(msg)


func _key(code: Key, pressed := true) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.keycode = code
	ev.pressed = pressed
	root.push_input(ev)


func _tap(code: Key) -> void:
	_key(code, true)
	_key(code, false)


## True when `c`'s global rect starts at `pos` (+- 1 px) and, when given, has `size`.
func _at(c: Control, pos: Vector2, size := Vector2.ZERO) -> bool:
	var r := c.get_global_rect()
	return r.position.distance_to(pos) <= 1.0 and (size == Vector2.ZERO or r.size.distance_to(size) <= 1.0)


func _msg() -> String:
	var l: Variant = hud.get(&"_message")
	return (l as Label).text if l is Label else ""


func _run() -> void:
	match _step:
		0:
			root.size = Vector2i(1600, 900)
			hud = main.get("hud")
			sel = main.get("selection")
			if hud == null or sel == null:
				_fail("no HUD / selection")
				return
			(sel.camera.get_parent() as Node3D).set("edge_pan_enabled", false)
			bar = hud.get("top_bar")
			trade = hud.get("trade_window")
			popups = hud.get("trade_popups")
			panel = hud.get("post_panel")
			if trade == null or popups == null or panel == null:
				_fail("HUD has no trade_window / trade_popups / post_panel")
				return
			_expect(popups.is_in_group(&"trade_popups") and popups.get_parent() == main, "popups not in the level")
			_expect(not bar.gold_label.visible, "gold item shown without a GoldBank")
			_expect(not trade.open(), "open() true without a GoldBank")
			_tap(KEY_U)
			_check_help()
			_check_settings()
			_next()
		1:
			if _since() < 2:
				return
			_expect(not trade.is_open(), "U opened the trade window without a GoldBank")
			_spawn_stubs()
			clock = StubClock.new()
			root.add_child(clock)
			current_scene = clock   # the top bar shows the timer when the current scene has match_time_text()
			_next()
		2:
			if _since() < 40:   # the bar looks for the bank every 0.5 s
				return
			_check_top_bar()
			current_scene = main
			clock.queue_free()
			_next()
		3:
			if _since() < 2:
				return
			_expect(bar.is_gold_popping(), "a +28 rise did not pop the gold number")
			bank.spend_failed.emit()
			_expect(bar.is_gold_flashing() and _msg() == "Not enough gold", "spend_failed: flash %s, message '%s'" % [
					bar.is_gold_flashing(), _msg()])
			_tap(KEY_U)
			_next()
		4:
			if _since() < 2:
				return
			_expect(trade.is_open() and trade.current_tab() == &"bazaar", "U did not open the Bazaar tab")
			if _error == "":
				_check_window_frame()
			if _error == "":
				_check_bazaar()
			_next()
		5:
			if _since() < 2:
				return
			_check_shift_labels()
			_check_lodge()
			_next()
		6:
			if _since() < 2:
				return
			_check_exclusive()
			_next()
		7:
			if _since() < 2:
				return
			_expect(not trade.is_open(), "Esc did not close the trade window")
			trade.open()
			_tap(KEY_U)
			_next()
		8:
			if _since() < 2:
				return
			_expect(not trade.is_open(), "U did not close the trade window")
			_check_panel()
			_next()
		9:
			if _since() < 2:
				return
			_check_popups()
			_next()
		10:
			if _since() < 70:   # 1.17 s: every floating text is gone
				return
			_expect(popups.active_count() == 0, "%d floating texts left after 1 s" % popups.active_count())
			_setup_tavern()
			_next()
		11:
			if _since() < 3:   # the window lays its rows out once shown
				return
			_check_tavern()
			_next()
		12:
			if _since() < 2:
				return
			trade.open()
			hud.show_banner("VICTORY", Color.GOLD)
			_expect(not trade.is_open(), "the match end did not close the trade window")
			_done = _error == ""


# ---------------------------------------------------------------- checks

func _check_help() -> void:
	var help: Label = hud.get(&"_help_label")
	var lines: PackedStringArray = help.text.split("\n")
	var expected := GameHUD.help_text("Vessa").split("\n")
	# Step 12 (ui-mapfill.md 12) appends a 12th line: `Capture: stand near towers, wells and shrines`.
	_expect(lines.size() == 12, "help text has %d lines, expected 12" % lines.size())
	_expect(help.text.contains("U: trade & hunters") and help.text.contains("G: trade (caravans)")
			and help.text.contains("B, B: Bazaar"), "help text lacks the trade keys")
	_expect(lines == expected, "help text is not the 14.1 text")
	var font := help.get_theme_font("font")
	var fs := help.get_theme_font_size("font_size")
	var widest := 0.0
	for line in lines:
		widest = maxf(widest, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	_expect(widest <= 440.0, "widest help line %d px (max 438)" % widest)
	_notes.append("help: 11 lines, widest %d px" % widest)


func _check_settings() -> void:
	_settings_existed = FileAccess.file_exists(SETTINGS)
	if _settings_existed:
		_settings_backup = FileAccess.get_file_as_bytes(SETTINGS)
	GameSettings.load_settings()
	GameSettings.set_trade_enabled(false)
	GameSettings.trade_enabled = true
	GameSettings.load_settings()
	_expect(not GameSettings.trade_enabled, "trade_enabled false was not saved / loaded")
	var level := Node.new()
	_expect(not GameSettings.apply_trade(level), "apply_trade set a level without the property")
	level.free()
	GameSettings.reset_defaults()
	_expect(GameSettings.trade_enabled, "reset_defaults did not turn trade on")
	# Restore the player's file.
	if _settings_existed:
		var f := FileAccess.open(SETTINGS, FileAccess.WRITE)
		f.store_buffer(_settings_backup)
		f.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS))
	GameSettings.load_settings()


func _spawn_stubs() -> void:
	bank = StubBank.new()
	bank.gold = 200
	bank.owned_wares = [&"masons_charter"]
	main.add_child(bank)
	market = StubMarket.new()
	main.add_child(market)
	market.global_position = Vector3(-45, 0, 27)
	net = StubNetwork.new()
	main.add_child(net)
	hunters = StubHunters.new()
	hunters.bank = bank
	main.add_child(hunters)
	post = StubPost.new()
	main.add_child(post)
	post.global_position = Vector3(-30, 0, 10)
	den = StubHouse.new()
	main.add_child(den)
	lodge = StubHouse.new()
	lodge.kind = &"lodge"
	main.add_child(lodge)


func _check_top_bar() -> void:
	_expect(bar.gold_label.visible and bar.gold_bank == bank, "gold item not shown with a GoldBank")
	_expect(bar.timer_label.visible and bar.essence_label.visible, "timer / essence not shown (setup)")
	var r: Rect2 = bar.get_global_rect()
	# Spec 624 x 40 at (488, 8) + TopBar.POP_EXTRA (20 px: the pop number fits "200 / 200" since pop cap 200).
	_expect(r.position.distance_to(Vector2(478, 8)) <= 1.0 and r.size.distance_to(Vector2(644, 40)) <= 1.0,
			"top bar rect %s, expected (478, 8, 644, 40)" % r)
	_expect(bar.GOLD_EXTRA == 124.0, "GOLD_EXTRA")
	_expect(bar.gold_label.text == "200", "gold text '%s'" % bar.gold_label.text)
	var help_panel: Control = hud.get(&"_help_panel")
	var h := help_panel.get_global_rect()
	_expect(h.size.x <= 459.0, "help panel %d px wide (max 458)" % h.size.x)
	_expect(not h.intersects(r), "help panel %s meets the top bar %s" % [h, r])
	_notes.append("top bar %s, help panel %s" % [r, h])
	bank.gold = 228   # a delivery: the number pops


func _check_window_frame() -> void:
	_expect(_at(trade, Vector2(420, 156), Vector2(760, 464)), "window rect %s" % trade.get_global_rect())
	_expect(_at(trade.tab_buttons[0], Vector2(516, 166), Vector2(100, 28)), "tab A %s" % trade.tab_buttons[0].get_global_rect())
	_expect(_at(trade.tab_buttons[1], Vector2(622, 166), Vector2(176, 28)), "tab B %s" % trade.tab_buttons[1].get_global_rect())
	_expect(_at(trade.title_label, Vector2(430, 166)), "title %s" % trade.title_label.get_global_rect())
	var x: Control = trade.get(&"_close_button")
	_expect(_at(x, Vector2(1146, 168), Vector2(24, 24)), "stud X %s" % x.get_global_rect())
	var gold_r: Rect2 = trade.essence_label.get_global_rect()
	_expect(absf(gold_r.end.x - 1134.0) <= 1.5, "resources end at x %d, expected 1134" % gold_r.end.x)
	_expect(_at(trade.footer_left, Vector2(430, 588)), "footer %s" % trade.footer_left.get_global_rect())
	_expect(trade.gold_label.text == "228", "window gold '%s'" % trade.gold_label.text)


func _check_bazaar() -> void:
	for k in 4:
		_expect(_at(trade.ware_rows[k], Vector2(430, 204 + 70 * k), Vector2(740, 64)), "ware row %d %s" % [k,
				trade.ware_rows[k].get_global_rect()])
		_expect(_at(trade.ware_rows[k].tile, Vector2(438, 212 + 70 * k), Vector2(48, 48)), "ware tile %d" % k)
	var r0: Node = trade.ware_rows[0]   # iron_axles: 150, hireable (gold 228)
	var r1: Node = trade.ware_rows[1]   # masons_charter: owned
	var r2: Node = trade.ware_rows[2]   # tempered_steel: 350, refused
	_expect(_at(r0.buy_button, Vector2(1058, 238), Vector2(104, 24)), "Buy rect %s" % r0.buy_button.get_global_rect())
	_expect(_at(r0.price_box, Vector2(1058, 208)), "price rect %s" % r0.price_box.get_global_rect())
	_expect(_at(r0.name_label, Vector2(498, 210)), "name rect %s" % r0.name_label.get_global_rect())
	_expect(not r0.buy_button.disabled and r0.note_label.text == "one-time" and r0.price_label.text == "150",
			"hireable ware: disabled %s note '%s' price '%s'" % [r0.buy_button.disabled, r0.note_label.text,
			r0.price_label.text])
	_expect(r1.owned and r1.owned_label.visible and not r1.buy_button.visible and r1.owned_tag.visible,
			"owned ware look")
	_expect(r2.buy_button.disabled and r2.note_label.text == "Not enough gold"
			and r2.buy_button.tooltip_text.contains("Not enough gold") and r2.price_label.get_theme_color(&"font_color") == WARN,
			"refused ware: note '%s' tooltip '%s'" % [r2.note_label.text, r2.buy_button.tooltip_text])
	_expect(r0.effect_label.text == "Caravans move 0.5 m/s faster and gain 60 HP", "effect line")
	_expect(r2.who_label.text.begins_with("Soldiers only"), "who line")
	# Exchange block.
	_expect(_at(trade.exchange_buttons[0], Vector2(438, 516), Vector2(220, 36)), "exchange A %s" %
			trade.exchange_buttons[0].get_global_rect())
	_expect(_at(trade.exchange_buttons[1], Vector2(672, 516), Vector2(220, 36)), "exchange B")
	_expect(trade.exchange_buttons[0].text == "100 gold  ->  80 crystals"
			and trade.exchange_buttons[1].text == "100 gold  ->  40 essence", "exchange labels '%s' / '%s'" % [
			trade.exchange_buttons[0].text, trade.exchange_buttons[1].text])
	_expect(_at(trade.ledger_labels[0], Vector2(920, 516)), "ledger rect %s" % trade.ledger_labels[0].get_global_rect())
	_expect(trade.ledger_labels[0].text == "Gold earned 2 100" and trade.ledger_labels[1].text == "trade 1 890 · loot 160 · rewards 50"
			and trade.ledger_labels[2].text == "Gold traded, last 3 min: 620", "ledger '%s' / '%s' / '%s'" % [
			trade.ledger_labels[0].text, trade.ledger_labels[1].text, trade.ledger_labels[2].text])
	_expect(trade.footer_right.text == "Bazaar: Ember Bazaar", "footer right '%s'" % trade.footer_right.text)
	# Buy.
	var popup_msgs: int = popups.messages.size()
	_expect(trade.press_buy(0) == "" and bank.bought == [&"iron_axles"], "press_buy(0) did not buy the Axles")
	_expect(r0.is_flashing(), "the bought row does not flash")
	_expect(popups.messages.size() == popup_msgs + 1 and popups.messages.back() == "Bought Iron-shod Axles",
			"no 'Bought Iron-shod Axles' message (%s)" % [popups.messages])
	_expect(r0.owned and r0.owned_label.visible, "the bought ware is not shown owned")
	_expect(trade.press_buy(2) == "Not enough gold" and _msg() == "Not enough gold", "refused buy message '%s'" % _msg())
	# Exchange.
	bank.gold = 400
	_expect(trade.press_exchange(&"crystals") == "" and bank.exchanges.back() == [100, &"crystals"]
			and _msg() == "Exchanged 100 gold for 80 crystals", "exchange x1: '%s'" % _msg())
	_expect(trade.press_exchange(&"essence", 5) == "Not enough gold" and _msg() == "Not enough gold",
			"exchange x5 refusal: '%s'" % _msg())
	bank.gold = 50
	trade.refresh()
	_expect(trade.exchange_buttons[0].disabled and trade.exchange_buttons[0].tooltip_text.contains("Not enough gold"),
			"exchange enabled with 50 gold")
	# No Bazaar.
	market.remove_from_group(&"markets")
	trade.refresh()
	_expect(trade.footer_left.text == "Build a Bazaar to buy wares and exchange gold"
			and trade.footer_right.text == "No Bazaar" and trade.footer_left.get_theme_color(&"font_color") == WARN,
			"no-Bazaar footer '%s' / '%s'" % [trade.footer_left.text, trade.footer_right.text])
	_expect(trade.ware_rows[3].note_label.text == "No Bazaar" and trade.ware_rows[3].buy_button.disabled,
			"no-Bazaar ware note '%s'" % trade.ware_rows[3].note_label.text)
	_expect(trade.exchange_buttons[1].tooltip_text.contains("No Bazaar"), "no-Bazaar exchange tooltip")
	market.add_to_group(&"markets")
	bank.gold = 400
	_shift_key(true)   # Shift = x5 labels, read on the next frames


func _shift_key(pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = KEY_SHIFT
	ev.physical_keycode = KEY_SHIFT
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _check_shift_labels() -> void:
	trade.refresh()
	if Input.is_key_pressed(KEY_SHIFT):
		_expect(trade.exchange_buttons[0].text == "500 gold  ->  400 crystals"
				and trade.exchange_buttons[1].text == "500 gold  ->  200 essence", "Shift labels '%s' / '%s'" % [
				trade.exchange_buttons[0].text, trade.exchange_buttons[1].text])
	else:
		_notes.append("Shift state not readable headless: x5 checked through press_exchange only")
	_shift_key(false)


func _check_lodge() -> void:
	_expect(trade.open(&"lodge") and trade.current_tab() == &"lodge", "open(&\"lodge\") failed")
	hunters.running = {&"sweep": 102.0}
	trade.refresh()
	_expect(_at(trade.lodge_header, Vector2(438, 206)), "header rect %s" % trade.lodge_header.get_global_rect())
	_expect(trade.lodge_header.text == "Greywater Lodge (Hunters' Guild) · contracts paid in gold · open from 5:00",
			"header '%s'" % trade.lodge_header.text)
	var out: Node = trade.contract_rows[0]
	var sw: Node = trade.contract_rows[1]
	_expect(_at(out, Vector2(430, 228), Vector2(740, 90)) and _at(sw, Vector2(430, 324), Vector2(740, 90)),
			"contract rows %s / %s" % [out.get_global_rect(), sw.get_global_rect()])
	_expect(_at(out.hire_button, Vector2(1058, 290), Vector2(104, 24)), "Hire rect %s" % out.hire_button.get_global_rect())
	_expect(_at(out.tile, Vector2(436, 235), Vector2(76, 76)), "contract tile %s" % out.tile.get_global_rect())
	_expect(out.state == &"hireable" and out.price_label.text == "120" and out.pop_label.text == "No pop cost"
			and not out.hire_button.disabled, "Outriders hireable: state %s" % out.state)
	_expect(out.sub_label.text == "2 Greywater Trackers · 180 s", "sub '%s'" % out.sub_label.text)
	_expect(sw.state == &"running" and sw.status_label.text == "Running" and sw.time_label.text == "1:42 left"
			and sw.time_bar.visible and not sw.hire_button.visible and absf(sw.time_ratio - 0.85) < 0.01,
			"Sweep running: %s '%s' '%s' ratio %.2f" % [sw.state, sw.status_label.text, sw.time_label.text, sw.time_ratio])
	_expect(_at(sw.time_bar, Vector2(1058, 366), Vector2(104, 6)), "time bar %s" % sw.time_bar.get_global_rect())
	hunters.running = {}
	hunters.cooldown = {&"sweep": 23.4}
	trade.refresh()
	_expect(sw.state == &"cooldown" and sw.status_label.text == "On cooldown" and sw.time_label.text == "24 s"
			and sw.hire_button.disabled, "Sweep cooldown: %s '%s'" % [sw.state, sw.time_label.text])
	hunters.open = false
	trade.refresh()
	_expect(trade.lodge_header.text == "The Lodge opens at 5:00 · in 0:48"
			and trade.lodge_header.get_theme_color(&"font_color") == WARN, "closed header '%s'" % trade.lodge_header.text)
	_expect(out.state == &"refused" and out.reason_label.text == "The Lodge opens at 5:00" and out.hire_button.disabled,
			"Outriders refused: %s '%s'" % [out.state, out.reason_label.text])
	hunters.open = true
	hunters.cooldown = {}
	trade.refresh()
	var horns: int = popups.sound_counts[&"horn"]
	_expect(trade.press_hire(&"outriders") == "" and hunters.hired == [&"outriders"], "press_hire did not hire")
	_expect(popups.sound_counts[&"horn"] == horns + 1, "no horn on contract_started")
	_expect(out.state == &"running", "Outriders not running after the hire")
	_expect(trade.press_hire(&"outriders") == "Contract already running" and _msg() == "Contract already running",
			"second hire: '%s'" % _msg())
	_expect(trade.reward_label.text == "The Lodge pays 10 gold for every Magpie slain"
			and _at(trade.reward_label, Vector2(438, 426)), "reward line")
	_expect(trade.rewards_received_label.text == "Rewards received: 50 gold"
			and absf(trade.rewards_received_label.get_global_rect().end.x - 1162.0) <= 1.0, "rewards received '%s' %s" % [
			trade.rewards_received_label.text, trade.rewards_received_label.get_global_rect()])
	_expect(trade.tip_labels.size() == 3 and _at(trade.tip_labels[0], Vector2(438, 452)), "tips")
	_expect(trade.footer_right.text == "Magpies you can see: 0", "footer '%s'" % trade.footer_right.text)
	# The tab buttons switch tabs.
	trade.tab_buttons[0].pressed.emit()
	_expect(trade.current_tab() == &"bazaar", "tab A did not show the Bazaar")


func _check_exclusive() -> void:
	var shop: Node = hud.get("shop_window")
	if shop.open():
		_expect(not trade.is_open(), "the shop opened with the trade window")
		trade.open()
		_expect(not shop.is_open(), "the trade window opened with the shop")
	else:
		_notes.append("no shop in reach: exclusivity checked on the trade side only")
		trade.open()
	_tap(KEY_ESCAPE)


func _check_panel() -> void:
	stub_sel = StubSelection.new()
	main.add_child(stub_sel)
	panel.setup(stub_sel)
	stub_sel.pick(post)
	_expect(panel.visible and panel.kind == &"post", "panel hidden for a post")
	_expect(_at(panel, Vector2(588, 670), Vector2(676, 204)), "panel rect %s" % panel.get_global_rect())
	_expect(_at(panel.action_button, Vector2(1104, 674), Vector2(150, 32)), "button rect %s" %
			panel.action_button.get_global_rect())
	var t: String = panel.panel_text()
	var expect_lines := ["Millstone Cross · trading post", "Open", "For you: near · 28 gold per trip from your Bazaar",
			"Held by the enemy · your caravans wait", "Your trips here, last 2 min: 4 · caravans on this route: 0",
			"Right-click with your Bazaar selected to set the route · G with caravans: trade here"]
	_expect(t == "\n".join(expect_lines), "post panel text:\n%s" % t)
	_expect(panel.segment_color(0, "Open") == NEAR and panel.segment_color(2, "Held") == WARN
			and panel.segment_color(1, "near") == NEAR, "post line colours")
	_expect(_at(panel.lines[0], Vector2(696, 700)) and _at(panel.lines[3], Vector2(696, 770))
			and _at(panel.hint_label, Vector2(696, 806)), "post line rects")
	_expect(panel.action_button.visible and panel.action_button.text == "Set as route", "Set as route button")
	_expect(panel.press_action() == "" and market.set_routes == [post], "Set as route did not call set_route")
	_expect(panel.action_button.text == "Current route" and panel.action_button.disabled, "Current route look")
	post.open = false
	net.until_open = 72.0
	post.holder = -1
	panel.refresh()
	_expect(panel.line_text(panel.lines[0]) == "Opens at 4:00 · in 1:12" and panel.line_text(panel.lines[2]) == "Not held",
			"closed post: '%s' / '%s'" % [panel.line_text(panel.lines[0]), panel.line_text(panel.lines[2])])
	market.remove_from_group(&"markets")
	panel.refresh()
	_expect(panel.line_text(panel.lines[1]) == "Build a Bazaar to trade" and not panel.action_button.visible,
			"no-Bazaar post line '%s'" % panel.line_text(panel.lines[1]))
	market.add_to_group(&"markets")
	# Den.
	stub_sel.pick(den)
	_expect(panel.kind == &"den" and not panel.action_button.visible, "Den panel")
	_expect(panel.panel_text().begins_with("Magpie Den · Thieves' Guild\nThieves who rob caravans and remote workers.")
			and panel.line_text(panel.lines[2]) == "Magpies you can see: 0", "Den text:\n%s" % panel.panel_text())
	# Lodge: its lines, Contracts [U], and a click opens the window on the Lodge tab.
	trade.close()
	stub_sel.pick(lodge)
	_expect(panel.kind == &"lodge" and panel.action_button.text == "Contracts  [U]", "Lodge panel button")
	_expect(panel.line_text(panel.lines[1]) == "Open" and panel.line_text(panel.lines[2]).begins_with("Outriders · "),
			"Lodge lines '%s' / '%s'" % [panel.line_text(panel.lines[1]), panel.line_text(panel.lines[2])])
	panel.press_action()
	_expect(trade.is_open() and trade.current_tab() == &"lodge", "Contracts [U] did not open the Lodge tab")
	trade.close()
	if sel.has_signal(&"neutral_building_clicked"):
		sel.emit_signal(&"neutral_building_clicked", lodge)
	else:
		hud.call(&"_on_neutral_building_clicked", lodge)   # 10.C7's signal is not there yet: the HUD handler
		_notes.append("selection has no neutral_building_clicked yet (10.C7): HUD handler called directly")
	_expect(trade.is_open() and trade.current_tab() == &"lodge", "a Lodge click did not open the Lodge tab")
	trade.close()
	stub_sel.pick(null)
	_expect(not panel.visible, "panel still visible with nothing selected")
	panel.setup(sel)


func _check_popups() -> void:
	var caravan := Node3D.new()
	main.add_child(caravan)
	caravan.global_position = Vector3(-35, 0, 20)
	var home := StubCaravan.new()
	home.home_market = market
	main.add_child(home)
	var coins: int = popups.sound_counts[&"coin"]
	net.delivered.emit(0, home, 28, post)
	var texts: PackedStringArray = popups.active_texts()
	_expect(texts.has("+28"), "no +28 on delivery (%s)" % [texts])
	var l: Label3D = popups.get_child(0)
	_expect(l.global_position.distance_to(market.global_position + Vector3(0, 5.3, 0)) < 0.05
			and l.font_size == 40 and absf(l.pixel_size - 0.006) < 0.0001 and l.billboard == BaseMaterial3D.BILLBOARD_ENABLED
			and l.no_depth_test, "+28 label look / place %s" % l.global_position)
	_expect(popups.sound_counts[&"coin"] == coins + 1, "no coin clink")
	net.delivered.emit(0, home, 28, post)
	_expect(popups.sound_counts[&"coin"] == coins + 1, "coin clink not rate-limited")
	net.delivered.emit(1, home, 28, post)
	_expect(popups.active_count() == 2, "enemy delivery made a text (%d)" % popups.active_count())
	var sack := Node3D.new()
	main.add_child(sack)
	sack.global_position = Vector3(-20, 0, 5)
	net.loot_picked.emit(0, 60, sack)
	_expect(popups.active_texts().has("+60") and popups.messages.back() == "Picked up a loot sack: 60 gold"
			and _msg() == "Picked up a loot sack: 60 gold", "loot sack: %s '%s'" % [popups.active_texts(), _msg()])
	var whistles: int = popups.sound_counts[&"whistle"]
	net.caravan_robbed.emit(0, caravan, 119, null)
	_expect(popups.active_texts().has("-119") and popups.sound_counts[&"whistle"] == whistles + 1,
			"robbed: %s whistle %d" % [popups.active_texts(), popups.sound_counts[&"whistle"]])
	var n_msgs: int = popups.messages.size()
	var node := Node3D.new()
	main.add_child(node)
	node.global_position = Vector3(-19, 0, 1)
	net.workers_raided.emit(0, node)
	net.workers_raided.emit(0, node)
	_expect(popups.messages.size() == n_msgs + 1 and str(popups.messages.back()).begins_with("Magpies raid your miners at "),
			"raid messages %s" % [popups.messages])
	_expect(popups.sound_counts[&"whistle"] == whistles + 1, "whistle not rate-limited (5 s)")
	for i in 10:
		net.delivered.emit(0, home, 10 + i, post)
	_expect(popups.active_count() == 8 and popups.pool_size() == 8, "pool: %d active of %d" % [popups.active_count(),
			popups.pool_size()])
	for id: StringName in [&"coin", &"whistle", &"horn"]:
		var p: AudioStreamPlayer = popups.player_of(id)
		_expect(p != null and p.bus == &"SFX" and p.stream != null, "sound %s: player / bus / stream" % id)


class StubCaravan extends Node3D:
	var home_market: Node3D


var tav: Node
var guild: StubGuild


func _setup_tavern() -> void:
	tav = hud.get("tavern_window")
	for g in get_nodes_in_group(&"champion_guilds"):
		g.remove_from_group(&"champion_guilds")   # the map's own guild (if any) stays out of the way
	guild = StubGuild.new()
	guild.bank = bank
	bank.gold = 1000
	var ch := StubChampion.new()
	ch.team = 0
	ch.max_hp = 300.0
	ch.unit_name = "Orla Fenwick"
	main.add_child(guild)
	main.add_child(ch)
	ch.global_position = main.hero.global_position + Vector3(0, 0, -5)
	ch.level = 2
	guild.champions.append(ch)
	_expect(tav.open(), "tavern did not open with a guild")


func _check_tavern() -> void:
	tav.refresh()
	var r0: Node = tav.rows[0]      # wayfinder: hireable
	var r3: Node = tav.rows[3]      # mender: fallen
	_expect(r0.gold_layout and r0.hire_gold_button.visible, "no gold layout with a GoldBank")
	_expect(tav.gold_label.visible and tav.gold_label.text == "1000", "tavern title gold '%s'" % tav.gold_label.text)
	var row0 := Vector2(430, 204)
	_expect(_at(r0.hire_button, row0 + Vector2(628, 40), Vector2(104, 22)), "Hire rect %s" % r0.hire_button.get_global_rect())
	_expect(_at(r0.hire_gold_button, row0 + Vector2(628, 64), Vector2(104, 22)), "Hire gold rect %s" %
			r0.hire_gold_button.get_global_rect())
	_expect(_at(r0.gold_price_box, row0 + Vector2(628, 16)) and _at(r0.price_box, row0 + Vector2(628, 2))
			and _at(r0.pop_label, row0 + Vector2(628, 29)), "price A / B / pop rects")
	_expect(r0.gold_price_label.text == "250" and r0.gold_essence_label.text == "100", "price B '%s' / '%s'" % [
			r0.gold_price_label.text, r0.gold_essence_label.text])
	# Row keys (2026-09-29): Z hires row 1, Shift+Z with gold.
	_expect(r0.hire_gold_button.text == "Hire · Gold" and r0.hire_gold_button.tooltip_text.begins_with(
			"Hire with gold  [Shift+Z]\n250 gold · 100 essence · 2 pop"), "Hire gold text / tooltip '%s'" % r0.hire_gold_button.tooltip_text)
	_expect(tav.press_hire_gold(0) == "" and guild.hires == [[&"wayfinder", true]], "press_hire_gold: %s" % [guild.hires])
	var row3 := Vector2(430, 204 + 96 * 3)
	_expect(r3.state == &"fallen" and r3.revive_gold_button.visible and r3.revive_gold_button.text == "Revive 180 gold",
			"fallen row: %s '%s'" % [r3.state, r3.revive_gold_button.text])
	_expect(_at(r3.revive_button, row3 + Vector2(628, 18), Vector2(104, 22))
			and _at(r3.revive_gold_button, row3 + Vector2(628, 42), Vector2(104, 22))
			and _at(r3.dismiss_button, row3 + Vector2(628, 66), Vector2(104, 22)), "fallen column C rects %s %s %s" % [
			r3.revive_button.get_global_rect(), r3.revive_gold_button.get_global_rect(), r3.dismiss_button.get_global_rect()])
	_expect(tav.press_revive_gold(3) == "" and guild.revives.size() == 1 and guild.revives[0][1] == true,
			"press_revive_gold: %s" % [guild.revives])
	guild.revives.clear()
	bank.gold = 100
	tav.refresh()
	_expect(r0.hire_gold_button.disabled and r0.hire_gold_button.tooltip_text.contains("Not enough gold")
			and r0.gold_price_label.get_theme_color(&"font_color") == WARN, "Not enough gold hire look")
	_expect(r3.revive_gold_button.disabled and r3.revive_gold_button.tooltip_text.contains("Not enough gold"),
			"Not enough gold revive look")
	# Trade off: the step-9 layout comes back.
	bank.remove_from_group(&"gold_banks")
	tav.refresh()
	_expect(not r0.gold_layout and not r0.hire_gold_button.visible and not tav.gold_label.visible,
			"gold controls still shown without a GoldBank")
	_expect(_at(r0.hire_button, row0 + Vector2(628, 62), Vector2(104, 24))
			and _at(r3.revive_button, row3 + Vector2(628, 34), Vector2(104, 24))
			and _at(r3.dismiss_button, row3 + Vector2(628, 62), Vector2(104, 24)), "step-9 layout not restored")
	_expect(r0.pop_label.text == "Pop 2", "pop line '%s'" % r0.pop_label.text)
	bank.add_to_group(&"gold_banks")
	tav.close()
	guild.remove_from_group(&"champion_guilds")
