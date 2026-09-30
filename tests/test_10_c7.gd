extends SceneTree
## Task 10.C7 (ui-trade.md 4-8, market-trade.md 4 / 8 / 12): build menu B (Bazaar at r2c2 with the grid's reasons),
## the Bazaar card (Caravan Z, Set Route, Wares U, 4 route buttons with value / near-far / current / held / closed)
## and panel block, right-click post / ground hint, Set Route order, minimap right-click, the hover preview + chip,
## the route ribbon (no per-frame rebuild), caravan card / orders (G, right click post / Bazaar / enemy), caravan
## single and multi views, tracker and Magpie inspect views, post / guild house clicks (selected_neutral + signal),
## the minimap trade layers, and no `_private` call between scripts/ui files.
## TradeNetwork, TradePost, GuildHouse, GoldBank, caravans, trackers, contracts, Magpies and loot sacks are stubs
## defined here (they follow the frozen contracts of market-trade.md 12); the Bazaar is the real Market.
## Run:  godot --headless --path . -s tests/test_10_c7.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "10.C7"
const TIMEOUT_FRAMES := 5000

var main: Node
var sel: Node
var hud: Node
var card: Node
var panel: Node
var minimap: Node
var line: Node
var grid: Node
var eco: Node
var frame := 0
var _wait := 0
var _started := false
var _done := false
var _errors: Array[String] = []
var _notes: Array[String] = []
var _messages: Array[String] = []
var _neutral_clicks: Array = []

var net: Node
var bank: Node
var posts := {}          # id -> StubPost
var den: Node3D
var lodge: Node3D
var market: Node3D
var workers: Array = []
var soldier: Node


# ---------------------------------------------------------------- stubs

## TradeNetwork as market-trade.md 12 (only what the UI reads): straight routes Bazaar -> door.
class StubNetwork extends Node:
	var open := false
	var post_list: Array = []
	var keep_pos := Vector3.ZERO
	var income := 620

	func _init() -> void:
		add_to_group(&"trade_network")

	func is_open() -> bool:
		return open

	func time_until_open() -> float:
		return 0.0 if open else 72.0

	func posts() -> Array:
		return post_list.filter(func(p: Variant) -> bool: return is_instance_valid(p))

	func road_segments() -> Array[PackedVector3Array]:
		var out: Array[PackedVector3Array] = []
		out.append(PackedVector3Array([Vector3(-40, 0, 20), Vector3(-50, 0, 14)]))
		out.append(PackedVector3Array([Vector3(-40, 0, 20), Vector3(-10, 0, 54)]))
		out.append(PackedVector3Array([Vector3(-10, 0, 54), Vector3(30, 0, 24)]))
		return out

	func route_points(_market: Node3D, post: Node3D) -> PackedVector3Array:
		return PackedVector3Array([post.call(&"door_point")])

	func route_length(market: Node3D, post: Node3D) -> float:
		var d: Vector3 = post.call(&"door_point")
		return Vector2(d.x - market.global_position.x, d.z - market.global_position.z).length()

	func route_value(market: Node3D, post: Node3D) -> int:
		var l := minf(route_length(market, post), 140.0)
		return roundi(10.0 + l * l / 136.0)

	func route_reason(market: Node3D, post: Node3D) -> String:
		if post == null or not post.is_in_group(&"trade_posts"):
			return "Not a trading post"
		if not open:
			return "Trading posts open at 4:00"
		if route_length(market, post) < 20.0:
			return "Route too short"
		if bool(post.call(&"is_held_by_enemy_of", int(market.get(&"team")))):
			return "Held by the enemy"
		return ""

	func is_far(_team: int, post: Node3D) -> bool:
		var d: Vector3 = post.call(&"door_point")
		return Vector2(d.x - keep_pos.x, d.z - keep_pos.z).length() >= 60.0

	func trade_income(_team: int, _seconds := 180.0) -> int:
		return income

	func trips(_team: int, _post: Node, _seconds := 120.0) -> int:
		return 0


## A trading post: group "trade_posts", 6 x 6 click body on layer 2, door 4 m along +Z.
class StubPost extends StaticBody3D:
	var post_id: StringName = &""
	var display_name := ""
	var holder := -1
	var selected_flag := false

	func _init() -> void:
		add_to_group(&"trade_posts")
		collision_layer = 2
		collision_mask = 0
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(6, 4, 6)
		shape.shape = box
		shape.position = Vector3(0, 2, 0)
		add_child(shape)

	func door_point() -> Vector3:
		return Vector3(global_position.x, 0.0, global_position.z + 4.0)

	func holder_team() -> int:
		return holder

	func is_held_by_enemy_of(team: int) -> bool:
		return holder >= 0 and holder != 2 and holder != team

	func set_selected(v: bool) -> void:
		selected_flag = v

	func is_open() -> bool:
		return true


## A guild house: group "guilds", kind den / lodge.
class StubGuild extends StaticBody3D:
	var kind: StringName = &"den"
	var selected_flag := false

	func _init() -> void:
		add_to_group(&"guilds")
		collision_layer = 2
		collision_mask = 0
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(6, 4, 6)
		shape.shape = box
		shape.position = Vector3(0, 2, 0)
		add_child(shape)

	func set_selected(v: bool) -> void:
		selected_flag = v


class StubBank extends Node:
	signal changed(gold: int)
	signal spend_failed
	signal ware_bought(id: StringName)
	var team := 0
	var gold := 500
	var owned_wares: Array[StringName] = [&"iron_axles"]

	func can_afford(n: int) -> bool:
		return gold >= n

	func spend(n: int) -> bool:
		if gold < n:
			spend_failed.emit()
			return false
		gold -= n
		changed.emit(gold)
		return true

	func _init() -> void:
		add_to_group(&"gold_banks")

	func earned(source: StringName = &"") -> int:
		return 2140 if source == &"trade" else 2300


class StubCaravan extends Unit:
	var cargo := 0
	var home_market: Node3D = null
	var route_post: Node3D = null
	var trade_state: StringName = &"idle"
	var state := "Idle"
	var trades: Array = []
	var moves := 0
	var attacks := 0

	func _init() -> void:
		add_to_group(&"caravans")

	func command_trade(target: Node3D) -> String:
		trades.append(target)
		return ""

	func is_loaded() -> bool:
		return cargo > 0

	func state_text() -> String:
		return state

	func command_move(_p: Vector3) -> void:
		moves += 1

	func command_attack(_t) -> void:
		attacks += 1

	func command_attack_move(_p: Vector3) -> void:
		attacks += 1

	func command_stop() -> void:
		pass

	func command_hold() -> void:
		pass


class StubTracker extends Unit:
	func _init() -> void:
		add_to_group(&"trackers")

	func is_commandable() -> bool:
		return false


class StubContract extends Node:
	var kind: StringName = &"outriders"
	var trackers: Array = []
	var left := 102.0

	func _init() -> void:
		add_to_group(&"tracker_contracts")

	func time_left() -> float:
		return left


class StubTradeWindow extends Control:
	var opened: Array = []

	func _init() -> void:
		add_to_group(&"trade_window")

	func open(tab: StringName = &"") -> bool:
		opened.append(tab)
		return true


# ---------------------------------------------------------------- run

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
	frame += 1
	if not _started:
		_started = true
		_run()
	if _done:
		for n in _notes:
			print("  note: " + n)
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			for e in _errors:
				print("  - " + e)
			print("FAIL %s: %d check(s) failed" % [TASK_ID, _errors.size()])
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out (%d errors so far: %s)" % [TASK_ID, _errors.size(), _errors])
		return true
	return false


func _run() -> void:
	await _setup()
	await _test_build_menu()
	await _test_market_card_and_panel()
	await _test_route_orders()
	await _test_hover_and_ribbon()
	await _test_caravans()
	await _test_inspect_views()
	await _test_neutral_clicks()
	await _test_minimap()
	_test_no_private_calls()
	_done = true


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_errors.append(what)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _setup() -> void:
	root.size = Vector2i(1600, 900)
	sel = main.selection
	hud = main.hud
	card = hud.command_card
	panel = hud.selection_panel
	minimap = hud.minimap
	grid = main.build_grid
	eco = main.economy
	main.camera_rig.edge_pan_enabled = false
	sel.message.connect(func(t: String) -> void: _messages.append(t))
	sel.neutral_building_clicked.connect(func(n: Node3D) -> void: _neutral_clicks.append(n))
	var fog := FogOfWar.find()
	if fog != null:
		fog.enabled = false
		fog.process_mode = Node.PROCESS_MODE_DISABLED   # the test hides things by hand (visible = false)
	eco.crystals = 5000
	net = StubNetwork.new()
	net.keep_pos = main.keep.global_position
	main.add_child(net)
	bank = StubBank.new()
	main.add_child(bank)
	# Keep at (-43, 43). Doors: Heron Ford (-50, 14) and Millstone Cross (-10, 54) near, Saltgate (-20, -26) and
	# Lantern Wharf (30, 24) far (>= 60 m from the keep).
	for spec: Array in [[&"heron_ford", "Heron Ford", Vector3(-50, 0, 10)],
			[&"millstone_cross", "Millstone Cross", Vector3(-10, 0, 50)],
			[&"saltgate", "Saltgate", Vector3(-20, 0, -30)],
			[&"lantern_wharf", "Lantern Wharf", Vector3(30, 0, 20)]]:
		var p := StubPost.new()
		p.post_id = spec[0]
		p.display_name = spec[1]
		p.name = String(spec[0])
		main.add_child(p)
		p.global_position = spec[2]
		posts[spec[0]] = p
		net.post_list.append(p)
	den = StubGuild.new()
	den.kind = &"den"
	main.add_child(den)
	den.global_position = Vector3(-54, 0, -44)
	lodge = StubGuild.new()
	lodge.kind = &"lodge"
	main.add_child(lodge)
	lodge.global_position = Vector3(-44, 0, -54)
	for u in get_nodes_in_group(&"units"):
		if u.team == 0 and u.has_method(&"command_build"):
			workers.append(u)
		elif u.team == 0 and soldier == null and not u.is_in_group(&"heroes") and not u.has_method(&"command_gather"):
			soldier = u
	await _frames(4)
	line = get_first_node_in_group(&"route_line")
	_expect(line != null and line is RouteLine, "no RouteLine in group route_line after the HUD setup")
	_expect(card.route_line == line, "the command card did not attach the route line")
	_expect(RouteLine.attach(hud, sel) == line and get_nodes_in_group(&"route_line").size() == 1,
			"a second RouteLine.attach made another node")
	_expect(not workers.is_empty() and soldier != null, "main.tscn has no workers / soldier")


func _focus(p: Vector3) -> void:
	main.camera_rig.focus_on(p)
	await _frames(2)


func _screen(p: Vector3, h := 0.8) -> Vector2:
	return main.camera_rig.camera.unproject_position(p + Vector3.UP * h)


## Line `i` of the Bazaar block ("" when missing).
func _bl(i: int) -> String:
	var parts: PackedStringArray = (panel.market_block_text() as String).split("\n")
	return parts[i] if i < parts.size() else ""


func _value(m: Node3D, p: Node3D) -> int:
	return net.route_value(m, p)


func _per_min(m: Node3D, p: Node3D) -> int:
	var l: float = net.route_length(m, p)
	return roundi(_value(m, p) * 60.0 / (l / 4.0 + l / 3.6 + 4.0))


# ---------------------------------------------------------------- build menu

func _test_build_menu() -> void:
	var bazaar := BuildingType.find("fire_market")
	var hall_t := BuildingType.find("fire_barracks")
	if bazaar == null or hall_t == null:
		_errors.append("fire_market / fire_barracks data missing")
		return
	sel.select_units(workers)
	sel.open_build_menu()
	card.refresh()
	_expect(card.slot_ids()[5] == "build_fire_market", "Bazaar not at r2c2: %s" % [card.slot_ids()])
	_expect(card.key_labels[5].text == "B", "Bazaar key '%s'" % card.key_labels[5].text)
	var tip: String = card.buttons[5].tooltip_text
	_expect(tip.begins_with("Ember Bazaar  [B]\nCost 175 crystals · 40 s · 1000 HP\nSends caravans to the trading posts for "
			+ "gold. Within 20 m of your keep. One per kingdom."), "Bazaar tooltip '%s'" % tip)
	var hall_needed := BuildGrid.prerequisite_reason(bazaar, 0) != ""
	if hall_needed:
		_expect(card.buttons[5].disabled and tip.ends_with("\nNeeds a completed Hall"), "no-Hall reason: '%s'" % tip)
		_messages.clear()
		_key(KEY_B, KEY_B)
		_expect(sel.placing_type == null and _messages.has("Needs a completed Hall"), "B without a Hall: %s %s" % [
				sel.placing_type, _messages])
		var hs: Vector3 = grid.find_spot(hall_t, main.keep.global_position + Vector3(12, 0, -4), 0)
		if hs == Vector3.INF:
			_errors.append("no spot for a Hall")
			return
		var hall: Node = grid.spawn_complete(hall_t, hs, 0)
		_expect(hall != null and hall.is_constructed(), "could not spawn a Hall")
	eco.crystals = 5000
	card.refresh()
	_expect(not card.buttons[5].disabled, "Bazaar button disabled with a Hall: '%s'" % card.buttons[5].tooltip_text)
	# B in the open build menu = the Bazaar ghost; the grid's reason shows for a spot 25 m from the keep.
	_key(KEY_B, KEY_B)
	_expect(sel.placing_type == bazaar and sel.get_pending_order() == &"build", "B did not start the Bazaar placement")
	var free := bazaar.duplicate() as BuildingType
	free.requires_kind = &""
	free.max_keep_distance = 0.0
	free.max_count = 0
	var k: Vector3 = main.keep.global_position
	var far := Vector3.INF
	for r in [25.0, 27.0, 24.0]:
		for i in 24:
			var a := TAU * i / 24.0
			var p: Vector3 = grid.snap(k + Vector3(cos(a), 0, sin(a)) * float(r), bazaar.footprint)
			if Vector2(p.x - k.x, p.z - k.z).length() > 20.5 and grid.check(free, p, 0) == "" \
					and absf(p.x) < 55.0 and absf(p.z) < 55.0:
				far = p
				break
		if far != Vector3.INF:
			break
	if far == Vector3.INF:
		_notes.append("no free spot 24-27 m from the keep: ghost reason not checked")
	else:
		await _focus(far)
		_move(_screen(far, 0.0))
		await _frames(2)
		sel.refresh_ghost()
		_expect(sel.ghost_reason() == "Must be within 20 m of your keep", "ghost reason '%s'" % sel.ghost_reason())
	_key(KEY_ESCAPE, KEY_ESCAPE)
	_expect(sel.placing_type == null, "Esc did not end the placement")
	# The real Bazaar, near the keep.
	var spot: Vector3 = grid.find_spot(free, k + Vector3(8, 0, -8), 0)
	if spot == Vector3.INF:
		_errors.append("no spot for the Bazaar")
		return
	market = grid.spawn_complete(bazaar, spot, 0)
	grid.request_rebake()
	_expect(market != null and market.is_in_group(&"markets") and market.is_constructed(), "spawn_complete Bazaar")
	_expect(sel.build_reason(bazaar) == "Only one Bazaar", "limit reason '%s'" % sel.build_reason(bazaar))
	sel.close_build_menu()


# ---------------------------------------------------------------- Bazaar card and panel

func _test_market_card_and_panel() -> void:
	if market == null:
		return
	var hf: Node3D = posts[&"heron_ford"]
	var mc: Node3D = posts[&"millstone_cross"]
	var sg: Node3D = posts[&"saltgate"]
	var lw: Node3D = posts[&"lantern_wharf"]
	sel.select_building(market)
	await _frames(2)
	card.refresh()
	var want := ["train_caravan", "route", "wares", "", "route_heron_ford", "route_millstone_cross", "route_saltgate",
			"route_lantern_wharf", "", "", "", ""]
	_expect(card.slot_ids() == want, "Bazaar card %s" % [card.slot_ids()])
	_expect(card.key_labels[0].text == "Z" and card.key_labels[1].text == "" and card.key_labels[2].text == "U",
			"card keys '%s' '%s' '%s'" % [card.key_labels[0].text, card.key_labels[1].text, card.key_labels[2].text])
	_expect(not card.slot_ids().has("rally"), "the Bazaar shows Set Rally")
	_expect([card.buttons[4].text, card.buttons[5].text, card.buttons[6].text, card.buttons[7].text] == ["HF", "MC", "SG", "LW"],
			"route button letters %s" % [[card.buttons[4].text, card.buttons[5].text, card.buttons[6].text, card.buttons[7].text]])
	_expect((card.buttons[0].tooltip_text as String).begins_with(
			"Caravan  [Z]\nCost 75 crystals · Pop 0 · 20 s\nTrades with a post and brings gold back. Max 6."),
			"caravan tooltip '%s'" % card.buttons[0].tooltip_text)
	# Posts closed: Set Route and the route buttons refused.
	_expect(card.buttons[1].disabled and (card.buttons[1].tooltip_text as String).ends_with("\nTrading posts open at 4:00"),
			"Set Route not refused while closed: '%s'" % card.buttons[1].tooltip_text)
	for i in range(4, 8):
		_expect(card.buttons[i].disabled and (card.buttons[i].tooltip_text as String).ends_with("\nOpens at 4:00"),
				"route button %d while closed: '%s'" % [i, card.buttons[i].tooltip_text])
	_expect(_bl(1) == "Posts open at 4:00 · caravans wait",
			"closed block line '%s'" % panel.market_block_text())
	# Open.
	net.open = true
	card.refresh()
	for i in range(4, 8):
		_expect(not card.buttons[i].disabled, "route button %d still disabled: '%s'" % [i, card.buttons[i].tooltip_text])
	var order: Array = [hf, mc, sg, lw]
	for j in 4:
		var p: Node3D = order[j]
		_expect(card.cost_tags[4 + j].visible and card.cost_tags[4 + j].text == str(_value(market, p)),
				"value tag %d '%s' want %d" % [j, card.cost_tags[4 + j].text, _value(market, p)])
		var far: bool = net.is_far(0, p)
		_expect(card.near_chips[4 + j].visible and card.near_chips[4 + j].text == ("far" if far else "near"),
				"near / far chip %d '%s'" % [j, card.near_chips[4 + j].text])
	_expect(_value(market, hf) < _value(market, mc) and _value(market, mc) < _value(market, sg) \
			and _value(market, sg) < _value(market, lw), "stub values not ascending (test setup)")
	# The default route (near, best value) = Millstone Cross: its button selected, "Current route" in the tooltip.
	_expect(market.route_post == mc, "default route %s" % market.route_post)
	_expect(bool(card.slots[5].get("active")) and not bool(card.slots[4].get("active")), "current route not selected")
	var tip: String = card.buttons[5].tooltip_text
	_expect(tip == "Millstone Cross · near\n%d gold per trip · ~%d / min per caravan\nCurrent route" % [_value(market, mc),
			_per_min(market, mc)], "current route tooltip '%s'" % tip)
	_expect((card.buttons[4].tooltip_text as String).ends_with("\nRight-click the post does the same."),
			"route tooltip line 3 '%s'" % card.buttons[4].tooltip_text)
	# Held by the enemy.
	sg.holder = 1
	card.refresh()
	_expect(card.buttons[6].disabled and (card.buttons[6].tooltip_text as String).ends_with("\nHeld by the enemy")
			and bool(card.slots[6].get("held")), "held route button: '%s'" % card.buttons[6].tooltip_text)
	# A route button sets the route.
	card.press_slot(7)
	_expect(market.route_post == lw, "route button did not set Lantern Wharf (%s)" % market.route_post)
	card.refresh()
	_expect(bool(card.slots[7].get("active")) and not bool(card.slots[5].get("active")), "route button state after the click")
	# Wares U: the trade window on the Bazaar tab.
	var real_window: Variant = hud.get("trade_window")
	if real_window == null:
		var w := StubTradeWindow.new()
		hud.add_child(w)
		card.press_slot(2)
		_expect(w.opened == [&"bazaar"], "Wares did not open the trade window on the Bazaar tab (%s)" % [w.opened])
		w.queue_free()
	else:
		card.press_slot(2)
		var opened: bool = real_window.call(&"is_open") if (real_window as Object).has_method(&"is_open") else false
		_expect(opened, "Wares did not open the real trade window")
		if (real_window as Object).has_method(&"current_tab"):
			_expect(real_window.call(&"current_tab") == &"bazaar", "Wares opened the tab '%s'" % real_window.call(&"current_tab"))
		if (real_window as Object).has_method(&"close"):
			real_window.call(&"close")
	# The panel: keep view + the Bazaar block.
	await _frames(2)
	_expect(panel.current_view() == "keep", "Bazaar view '%s'" % panel.current_view())
	_expect(not panel.rally_label.visible, "the Bazaar shows a rally line")
	_expect(not panel.building_info.visible or panel.building_info.text == "", "building_info '%s'" % panel.building_info.text)
	var lines: PackedStringArray = panel.market_block_text().split("\n")
	var want_lines := ["Route: Lantern Wharf (far)",
			"%d gold per trip · ~%d / min each" % [_value(market, lw), _per_min(market, lw)],
			"Caravans 0 / 6", "Gold traded, last 3 min: 620 · total 2 140", "Wares 1 / 4 owned · U"]
	_expect(Array(lines) == want_lines, "Bazaar block %s, want %s" % [lines, want_lines])
	_expect(panel.market_block.get_global_rect().position.distance_to(Vector2(1000, 676)) < 1.5,
			"Bazaar block at %s" % panel.market_block.get_global_rect().position)
	# Held route: the waiting line; a queued caravan; the 6 / 6 warning.
	market.route_post = sg
	await _frames(1)
	_expect(_bl(1) == "Held by the enemy · caravans wait", "held block line")
	sg.holder = -1
	var ctype := UnitType.find("caravan")
	if ctype != null:
		var r: String = market.queue_unit(ctype)
		await _frames(1)
		_expect(r == "" and _bl(2) == "Caravans 0 / 6 (1 queued)",
				"queued caravan: '%s' / '%s'" % [r, panel.market_block_text()])
		market.cancel(0)
	# Enemy Bazaar and other buildings: no block.
	var free := BuildingType.find("shadow_market")
	var es := Vector3.INF
	if free != null:
		var f2 := free.duplicate() as BuildingType
		f2.requires_kind = &""
		f2.max_keep_distance = 0.0
		f2.max_count = 0
		es = grid.find_spot(f2, Vector3(20, 0, -20), 1)
	if es != Vector3.INF:
		var enemy_market: Node3D = grid.spawn_complete(free, es, 1)
		sel.select_building(enemy_market)
		await _frames(1)
		_expect(panel.current_view() == "keep" and panel.market_block_text() == "", "enemy Bazaar block '%s'" % panel.market_block_text())
		enemy_market.queue_free()
	sel.select_building(main.keep)
	await _frames(1)
	_expect(panel.market_block_text() == "", "keep shows the Bazaar block")


# ---------------------------------------------------------------- right click, Set Route, minimap

func _test_route_orders() -> void:
	if market == null:
		return
	var hf: Node3D = posts[&"heron_ford"]
	var mc: Node3D = posts[&"millstone_cross"]
	sel.select_building(market)
	await _focus(hf.global_position)
	# Right click a post = its route.
	_right_click(_screen(hf.global_position, 2.0))
	_expect(market.route_post == hf, "right click on Heron Ford: route %s" % market.route_post)
	# Right click the ground = the hint, throttled (once per 2 s).
	_messages.clear()
	var ground: Vector3 = hf.global_position + Vector3(9, 0, -9)
	_right_click(_screen(ground, 0.0))
	_right_click(_screen(ground, 0.0))
	_expect(_messages.count("Right-click a trading post to set the route") == 1, "ground hint messages %s" % [_messages])
	_expect(market.route_post == hf, "a ground right click changed the route")
	# A refusal goes to the message line: a post too close (L < 20).
	var short := StubPost.new()
	short.post_id = &"short"
	short.display_name = "Short"
	main.add_child(short)
	short.global_position = market.global_position + Vector3(0, 0, -12)
	await _focus(short.global_position)
	_messages.clear()
	_right_click(_screen(short.global_position, 2.0))
	_expect(_messages.has("Route too short") and market.route_post == hf, "short route: %s, route %s" % [_messages, market.route_post])
	short.queue_free()
	await _frames(2)
	# Set Route (r1c2): pending order; the ground keeps it with the hint; a post confirms.
	sel.select_building(market)
	card.refresh()
	card.press_slot(1)
	_expect(sel.get_pending_order() == &"route", "Set Route did not start ORDER_ROUTE ('%s')" % sel.get_pending_order())
	card.refresh()
	_expect(bool(card._pending[1]), "Set Route button not pulsing while pending")
	await _focus(mc.global_position)
	await _frames(130)   # the hint throttle (2 s) has passed
	_messages.clear()
	_click(_screen(mc.global_position + Vector3(9, 0, -9), 0.0))
	_expect(sel.get_pending_order() == &"route" and _messages.has("Right-click a trading post to set the route"),
			"ground click while pending: '%s' %s" % [sel.get_pending_order(), _messages])
	_click(_screen(mc.global_position, 2.0))
	_expect(market.route_post == mc and sel.get_pending_order() == &"", "left click on a post while pending: %s '%s'" % [
			market.route_post, sel.get_pending_order()])
	card.press_slot(1)
	_right_click(_screen(mc.global_position + Vector3(9, 0, -9), 0.0))
	_expect(sel.get_pending_order() == &"", "right click did not cancel Set Route")
	# Minimap: a right click within 4 m of a post sets the route; with Set Route pending a left click too.
	sel.order_at(hf.global_position + Vector3(2.5, 0, 2.5))
	_expect(market.route_post == hf, "minimap right click near Heron Ford: %s" % market.route_post)
	card.press_slot(1)
	sel.confirm_pending_at(mc.global_position + Vector3(-2, 0, 3))
	_expect(market.route_post == mc and sel.get_pending_order() == &"", "minimap left click with Set Route pending")


# ---------------------------------------------------------------- hover preview, chip, ribbon

func _test_hover_and_ribbon() -> void:
	if market == null:
		return
	var hf: Node3D = posts[&"heron_ford"]
	var mc: Node3D = posts[&"millstone_cross"]
	var sg: Node3D = posts[&"saltgate"]
	_move(Vector2(800, 40))   # the mouse away from every post
	sel.select_building(market)
	await _frames(6)
	# The ribbon: Bazaar centre -> door, dashed gold, 0.25 m wide at y 0.30, two end rings.
	_expect(line.is_showing(&"route"), "no route ribbon with the Bazaar selected")
	var pts: PackedVector3Array = line.shown_points(&"route")
	var mp: Vector3 = market.global_position
	_expect(pts.size() == 2 and pts[0].distance_to(Vector3(mp.x, 0, mp.z)) < 0.01 and pts[1].distance_to(mc.door_point()) < 0.01,
			"ribbon points %s" % [pts])
	var mat: StandardMaterial3D = line.route_material()
	_expect(mat.albedo_color.is_equal_approx(Color(1.0, 0.85, 0.3, 0.8)) and is_equal_approx(mat.uv1_scale.x, 1.0 / 1.6)
			and mat.albedo_texture != null and mat.albedo_texture.get_width() == 32
			and mat.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED and mat.cull_mode == BaseMaterial3D.CULL_DISABLED,
			"route material")
	var mi: MeshInstance3D = line.get_node("Route")
	var aabb: AABB = mi.mesh.get_aabb() if mi.mesh else AABB()
	_expect(mi.mesh != null and mi.mesh.get_surface_count() == 2 and absf(aabb.position.y - 0.30) < 0.01
			and aabb.size.y < 0.01 and mi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
			"ribbon mesh (surfaces %d, aabb %s)" % [mi.mesh.get_surface_count() if mi.mesh else 0, aabb])
	var img := (mat.albedo_texture as Texture2D).get_image()
	_expect(img.get_pixel(19, 1).a > 0.9 and img.get_pixel(20, 1).a < 0.1, "dash texture 20 on / 12 off")
	# No per-frame rebuild; the dashes scroll.
	var count: int = line.rebuild_count
	var off := mat.uv1_offset.x
	await _frames(130)
	_expect(line.rebuild_count == count, "the ribbon was rebuilt %d time(s) without a change" % (line.rebuild_count - count))
	_expect(not is_equal_approx(mat.uv1_offset.x, off), "the dashes do not scroll")
	# route_changed redraws it.
	market.route_post = hf
	await _frames(1)
	pts = line.shown_points(&"route")
	_expect(line.rebuild_count == count + 1 and pts.size() == 2 and pts[1].distance_to(hf.door_point()) < 0.01,
			"route_changed: %d rebuilds, points %s" % [line.rebuild_count - count, pts])
	# Hover a far, a held and the current post: preview ribbon + chip texts.
	await _focus(sg.global_position)
	var at := _screen(sg.global_position, 2.0)
	_move(at)
	await _frames(6)
	_expect(sel.hovered_post == sg, "hovered_post %s" % sel.hovered_post)
	_expect(line.is_showing(&"preview") and line.shown_points(&"preview")[1].distance_to(sg.door_point()) < 0.01,
			"no preview ribbon over Saltgate")
	_expect(line.preview_material().albedo_color.is_equal_approx(Color(1.0, 0.85, 0.3, 0.45)), "preview colour")
	var chip: Control = line.chip
	_expect(chip.chip_text() == "Saltgate · far · %d gold / trip · ~%d / min" % [_value(market, sg), _per_min(market, sg)],
			"far chip '%s'" % chip.chip_text())
	_expect(chip.position.distance_to(at + Vector2(18, 12)) < 1.5, "chip at %s, want %s" % [chip.position, at + Vector2(18, 12)])
	sg.holder = 1
	await _frames(20)
	_expect(chip.chip_text().ends_with(" · Held by the enemy"), "held chip '%s'" % chip.chip_text())
	sg.holder = -1
	await _focus(hf.global_position)
	_move(_screen(hf.global_position, 2.0))
	await _frames(20)
	_expect(chip.chip_text() == "Heron Ford · near · %d gold / trip · ~%d / min · Current route" % [_value(market, hf),
			_per_min(market, hf)], "current chip '%s'" % chip.chip_text())
	_expect(not line.is_showing(&"preview"), "preview shown over the current route")
	_move(_screen(hf.global_position + Vector3(12, 0, 12), 0.0))
	await _frames(6)
	_expect(not chip.visible and not line.is_showing(&"preview"), "chip / preview stay off the posts")
	# Deselect: no ribbon.
	sel.select_units([])
	await _frames(1)
	_expect(not line.is_showing(&"route"), "ribbon still shown with nothing selected")


# ---------------------------------------------------------------- caravans

## Selects `units` and walks every unit subgroup with Tab (cycle_active_unit_type): {"caravan" / "worker" / "soldier":
## [slot ids, slot 4 tooltip]} for each subgroup the card showed.
func _subgroup_cards(units: Array) -> Dictionary:
	sel.select_units(units)
	var out := {}
	var n: int = (sel.selected_unit_types() as Array).size()
	for i in n:
		card.refresh()
		var first: Unit = (sel.active_type_units() as Array)[0]
		var kind := "caravan" if SelectionManager.is_caravan(first) else (
				"worker" if SelectionManager.is_worker_unit(first) else "soldier")
		out[kind] = [card.slot_ids(), String(card.buttons[3].tooltip_text)]
		sel.cycle_active_unit_type(1)
	return out


func _make_caravan(at: Vector3, cargo: int, post: Node3D) -> StubCaravan:
	var c := StubCaravan.new()
	var t := UnitType.find("caravan")
	c.apply_type(t if t != null else UnitType.find("flame_guard"))
	c.team = 0
	c.cargo = cargo
	c.home_market = market
	c.route_post = post
	main.add_child(c)
	c.global_position = at
	c.process_mode = Node.PROCESS_MODE_DISABLED
	return c


func _test_caravans() -> void:
	if market == null:
		return
	var sg: Node3D = posts[&"saltgate"]
	var mc: Node3D = posts[&"millstone_cross"]
	var base: Vector3 = market.global_position + Vector3(0, 0, 7)
	var c1 := _make_caravan(base, 119, sg)
	var c2 := _make_caravan(base + Vector3(2, 0, 0), 0, sg)
	c1.state = "Returning with 119"
	await _frames(2)
	# Card: Move Stop Hold Trade.
	sel.select_units([c1, c2])
	card.refresh()
	var ids: Array = card.slot_ids()
	_expect(ids.slice(0, 4) == ["move", "stop", "hold", "trade"] and ids.slice(4).all(func(s: String) -> bool: return s == ""),
			"caravan card %s" % [ids])
	_expect(card.key_labels[3].text == "G" and (card.buttons[3].tooltip_text as String).begins_with(
			"Trade  [G]\nClick a trading post: trade there from now on.\nClick your Bazaar: go home and deliver."),
			"trade slot '%s'" % card.buttons[3].tooltip_text)
	# Mixed selections (2026-09-27 "Tab by unit type", SC2 subgroups): the card shows the ACTIVE subgroup's slots and
	# Tab cycles them. Caravan + worker: the caravan subgroup shows Trade (G), the worker subgroup Gather (G), both at
	# r1c4; caravan + soldier: the soldier subgroup shows Attack-move and no Trade, the caravan one Trade and no attack.
	var seen := _subgroup_cards([c1, workers[0]])
	_expect(seen.size() == 2 and seen.has("caravan") and seen.has("worker"), "caravan + worker subgroups %s" % [seen.keys()])
	if seen.has("caravan"):
		_expect(seen["caravan"][0][3] == "trade" and not (seen["caravan"][0] as Array).has("gather")
				and String(seen["caravan"][1]).begins_with("Trade  [G]\n"), "caravan subgroup card %s" % [seen["caravan"]])
	if seen.has("worker"):
		_expect(seen["worker"][0][3] == "gather" and not (seen["worker"][0] as Array).has("trade")
				and String(seen["worker"][1]).begins_with("Gather  [G]\n"), "worker subgroup card %s" % [seen["worker"]])
	seen = _subgroup_cards([c1, soldier])
	_expect(seen.size() == 2 and seen.has("caravan") and seen.has("soldier"), "caravan + soldier subgroups %s" % [seen.keys()])
	if seen.has("soldier"):
		_expect(seen["soldier"][0][3] == "attack" and not (seen["soldier"][0] as Array).has("trade"),
				"soldier subgroup card %s" % [seen["soldier"][0]])
	if seen.has("caravan"):
		_expect(seen["caravan"][0][3] == "trade" and not (seen["caravan"][0] as Array).has("attack"),
				"caravan subgroup card %s" % [seen["caravan"][0]])
	# The route ribbon of the first caravan (its Bazaar -> its post).
	sel.select_units([c1, c2])
	await _frames(2)
	_expect(line.is_showing(&"route") and line.shown_points(&"route")[1].distance_to(sg.door_point()) < 0.01,
			"caravan route ribbon")
	# G then a post / the own Bazaar.
	await _focus(mc.global_position)
	_key(KEY_G, KEY_G)
	_expect(sel.get_pending_order() == &"gather", "G with caravans: '%s'" % sel.get_pending_order())
	_click(_screen(mc.global_position, 2.0))
	_expect(c1.trades.back() == mc and c2.trades.back() == mc, "G + post: %s / %s" % [c1.trades, c2.trades])
	await _focus(market.global_position)
	_key(KEY_G, KEY_G)
	_click(_screen(market.global_position, 1.5))
	_expect(c1.trades.back() == market and c2.trades.back() == market, "G + Bazaar: %s" % [c1.trades])
	# G with workers too: a crystal node still makes the workers gather.
	var node: Node3D = null
	for n in get_nodes_in_group(&"crystal_nodes"):
		if node == null or (n as Node3D).global_position.distance_to(main.keep.global_position) \
				< node.global_position.distance_to(main.keep.global_position):
			node = n
	var w: Node = workers[0]
	sel.select_units([c1, w])
	await _focus(node.global_position)
	_key(KEY_G, KEY_G)
	_click(_screen(node.global_position, 0.6))
	await _frames(2)
	_expect(w.get("gather_node") == node or (w.has_method(&"is_gathering") and w.is_gathering()),
			"G + node with a caravan selected: the worker does not gather")
	_expect(c1.trades.back() == market, "the node click sent the caravan to trade")
	# Right click: a post = trade, the own Bazaar = go home, an enemy = a move (never an attack).
	sel.select_units([c1, c2])
	await _focus(mc.global_position)
	_right_click(_screen(mc.global_position, 2.0))
	_expect(c1.trades.back() == mc, "right click on a post with caravans: %s" % [c1.trades])
	await _focus(market.global_position)
	_right_click(_screen(market.global_position, 1.5))
	_expect(c1.trades.back() == market, "right click on the own Bazaar: %s" % [c1.trades])
	var enemy := StubCaravan.new()   # any enemy unit
	enemy.apply_type(UnitType.find("flame_guard"))
	enemy.team = 1
	main.add_child(enemy)
	enemy.global_position = market.global_position + Vector3(-6, 0, 8)
	enemy.process_mode = Node.PROCESS_MODE_DISABLED
	enemy.remove_from_group(&"caravans")
	await _focus(enemy.global_position)
	var moves := c1.moves
	_right_click(_screen(enemy.global_position, 0.9))
	_expect(c1.attacks == 0 and c1.moves > moves, "right click on an enemy: caravan attacks %d, moves %d" % [c1.attacks,
			c1.moves - moves])
	_key(KEY_X, KEY_X)
	_expect(sel.get_pending_order() != &"attack_move", "X with caravans only started an attack-move")
	sel.cancel_targeting()
	# Minimap right click near a post with caravans = trade.
	sel.order_at(mc.global_position + Vector3(2, 0, -2))
	_expect(c1.trades.back() == mc, "minimap right click near a post with caravans")
	# Single view: cargo + route + state.
	sel.select_units([c1])
	await _frames(2)
	_expect(panel.current_view() == "single", "caravan view '%s'" % panel.current_view())
	_expect(panel.single_lines() == "Cargo 119 gold · Route: Saltgate (far)\nReturning with 119",
			"loaded caravan lines '%s'" % panel.single_lines())
	_expect(panel.cargo_coin_shown(), "no coin on a loaded caravan")
	_expect(panel.single_state.get_theme_color("font_color") == UIStyle.GOLD, "Returning not in gold")
	c1.cargo = 0
	c1.state = "Waiting: Saltgate is held"
	await _frames(1)
	_expect(panel.single_lines() == "Empty · Route: Saltgate (far)\nWaiting: Saltgate is held", "empty caravan '%s'" % panel.single_lines())
	_expect(not panel.cargo_coin_shown(), "coin on an empty caravan")
	_expect(panel.single_state.get_theme_color("font_color") == UIStyle.WARN, "Waiting not in WARN")
	c1.route_post = null
	c1.state = "Idle"
	await _frames(1)
	_expect(panel.single_lines() == "Empty · No route: right-click a post\nIdle", "no-route caravan '%s'" % panel.single_lines())
	c1.route_post = mc
	# Multi view: the loaded one carries the 6 px coin.
	c2.cargo = 28
	sel.select_units([c1, c2])
	await _frames(1)
	_expect(panel.current_view() == "multi" and not panel.icon_coin_shown(0) and panel.icon_coin_shown(1),
			"multi coins %s / %s" % [panel.icon_coin_shown(0), panel.icon_coin_shown(1)])
	_expect((panel.multi_header.text as String).begins_with("2 selected:"), "multi header '%s'" % panel.multi_header.text)
	# Caravans count in the Bazaar block.
	sel.select_building(market)
	await _frames(1)
	_expect(_bl(2) == "Caravans 2 / 6", "block with 2 caravans '%s'" % panel.market_block_text())
	enemy.queue_free()
	sel.select_units([])


# ---------------------------------------------------------------- tracker, Magpie

## A ground point near `near` with no unit, building, crystal node, post or guild house within 5 m.
func _free_spot(near: Vector3) -> Vector3:
	for r in range(0, 30, 3):
		for i in 12:
			var a := TAU * i / 12.0
			var p := near + Vector3(cos(a), 0, sin(a)) * float(r)
			if absf(p.x) > 55.0 or absf(p.z) > 55.0:
				continue
			var ok := true
			for g: StringName in [&"units", &"buildings", &"crystal_nodes", &"trade_posts", &"guilds"]:
				for n in get_nodes_in_group(g):
					if n is Node3D and Vector2((n as Node3D).global_position.x - p.x,
							(n as Node3D).global_position.z - p.z).length() < (9.0 if g == &"buildings" else 5.0):
						ok = false
						break
				if not ok:
					break
			if ok:
				return p
	return near


func _test_inspect_views() -> void:
	var at: Vector3 = _free_spot(main.keep.global_position + Vector3(10, 0, -18))
	var t := StubTracker.new()
	var tt := UnitType.find("greywater_tracker")
	t.apply_type(tt if tt != null else UnitType.find("ember_archer"))
	t.team = 0
	main.add_child(t)
	t.global_position = at
	t.process_mode = Node.PROCESS_MODE_DISABLED
	var contract := StubContract.new()
	contract.trackers = [t]
	main.add_child(contract)
	await _focus(at)
	_click(_screen(at, 0.9))
	await _frames(2)
	_expect(sel.inspected == t and sel.selected.is_empty(), "click on a tracker: inspected %s" % sel.inspected)
	_expect(panel.current_view() == "single", "tracker view '%s'" % panel.current_view())
	var lines: PackedStringArray = (panel.single_lines() as String).split("\n")
	_expect(lines.size() == 2 and lines[0].begins_with("Damage ") and lines[1] == "Contract: Outriders · 1:42 left",
			"tracker lines %s" % [lines])
	card.refresh()
	_expect(card.slot_ids().all(func(s: String) -> bool: return s == ""), "tracker card not empty %s" % [card.slot_ids()])
	_expect(card.inspect_text() == "Hired hunters act on their own.\n[U]: trade & hunters", "tracker inspect '%s'" % card.inspect_text())
	t.team = 1
	await _frames(1)
	card.refresh()
	_expect((panel.single_lines() as String).ends_with("\nEnemy hunters"), "enemy tracker line '%s'" % panel.single_lines())
	_expect(card.inspect_text() == "Hired hunters act on their own.\nHunt it with a bounty  [R]",
			"enemy tracker inspect '%s'" % card.inspect_text())
	sel.select_units([])
	t.queue_free()
	contract.queue_free()
	# A Magpie (neutral, commandable but never ours): the ordinary read-only single view + its loot.
	var m := Unit.new()
	var mt := UnitType.find("magpie")
	m.apply_type(mt if mt != null else UnitType.find("flame_guard"))
	m.team = Unit.Team.NEUTRAL
	m.add_to_group(&"magpies")
	main.add_child(m)
	m.global_position = at
	m.process_mode = Node.PROCESS_MODE_DISABLED
	m.set_meta(&"loot", 60)
	await _frames(2)
	_click(_screen(at, 0.9))
	await _frames(2)
	_expect(sel.inspected == m and panel.current_view() == "single", "click on a Magpie: %s '%s'" % [sel.inspected,
			panel.current_view()])
	_expect((panel.single_lines() as String).ends_with(" · Carrying 60 gold"), "Magpie line '%s'" % panel.single_lines())
	card.refresh()
	_expect(card.inspect_text() == "" and card.slot_ids().all(func(s: String) -> bool: return s == ""),
			"Magpie card: '%s' %s" % [card.inspect_text(), card.slot_ids()])
	m.visible = false   # into the fog: dropped
	await _frames(2)
	_expect(sel.inspected == null, "a hidden Magpie stays inspected")
	m.queue_free()
	sel.select_units([])


# ---------------------------------------------------------------- posts / guild houses

func _test_neutral_clicks() -> void:
	var sg: Node3D = posts[&"saltgate"]
	sel.select_units([workers[0]])
	await _focus(sg.global_position)
	_neutral_clicks.clear()
	_click(_screen(sg.global_position, 2.0))
	_expect(sel.selected_neutral == sg and _neutral_clicks == [sg] and sg.selected_flag, "post click: %s %s %s" % [
			sel.selected_neutral, _neutral_clicks, sg.selected_flag])
	_expect(sel.selected.is_empty() and sel.selected_building == null and sel.inspected == null and sel.selected_bounty == null,
			"a post click kept another selection")
	card.refresh()
	_expect(card.slot_ids().all(func(s: String) -> bool: return s == "") and card.inspect_text() == "",
			"card with a post selected %s" % [card.slot_ids()])
	_key(KEY_ESCAPE, KEY_ESCAPE)
	_expect(sel.selected_neutral == null and not sg.selected_flag, "Esc did not clear the post")
	# Ground next to the footprint (inside 3.5 m) counts; a click elsewhere clears it.
	_click(_screen(sg.global_position + Vector3(2.8, 0, -2.8), 0.0))
	_expect(sel.selected_neutral == sg, "footprint ground click did not select the post")
	_click(_screen(sg.global_position + Vector3(10, 0, -10), 0.0))
	_expect(sel.selected_neutral == null and not sg.selected_flag, "a ground click kept the post")
	await _focus(den.global_position)
	_click(_screen(den.global_position, 2.0))
	_expect(sel.selected_neutral == den and den.selected_flag and _neutral_clicks.back() == den, "Den click")
	_drag(Vector2(20, 60), Vector2(200, 200))
	_expect(sel.selected_neutral == null and not den.selected_flag, "a box select kept the Den")
	await _focus(lodge.global_position)
	_click(_screen(lodge.global_position, 2.0))
	_expect(sel.selected_neutral == lodge and _neutral_clicks.back() == lodge, "Lodge click")
	sel.select_units([])


# ---------------------------------------------------------------- minimap

func _test_minimap() -> void:
	if market == null:
		return
	var sg: Node3D = posts[&"saltgate"]
	sg.holder = 1
	var sack := Node3D.new()
	sack.add_to_group(&"loot_sacks")
	main.add_child(sack)
	sack.global_position = Vector3(0, 0, 0)
	var mag := Unit.new()
	mag.apply_type(UnitType.find("flame_guard"))
	mag.team = Unit.Team.NEUTRAL
	mag.add_to_group(&"magpies")
	main.add_child(mag)
	mag.global_position = Vector3(5, 0, 5)
	mag.process_mode = Node.PROCESS_MODE_DISABLED
	sel.select_building(market)
	await _frames(15)
	_expect(minimap.drawn_roads == 3, "minimap roads %d" % minimap.drawn_roads)
	_expect(minimap.drawn_posts == 4 and minimap.drawn_held_posts == 1, "minimap posts %d held %d" % [minimap.drawn_posts,
			minimap.drawn_held_posts])
	_expect(minimap.drawn_guilds == 2, "minimap guild houses %d" % minimap.drawn_guilds)
	_expect(minimap.drawn_sacks == 1, "minimap sacks %d" % minimap.drawn_sacks)
	_expect(minimap.drawn_caravans == 2 and minimap.drawn_loaded_caravans == 1, "minimap caravans %d loaded %d" % [
			minimap.drawn_caravans, minimap.drawn_loaded_caravans])
	_expect(minimap.drawn_magpies == 1, "minimap Magpies %d" % minimap.drawn_magpies)
	_expect(minimap.route_drawn, "minimap route not drawn with the Bazaar selected")
	# Fogged Magpie / sack: not drawn. Nothing selected: no route.
	sack.visible = false
	mag.visible = false
	sel.select_units([])
	await _frames(15)
	_expect(minimap.drawn_sacks == 0 and minimap.drawn_magpies == 0, "fogged sack / Magpie drawn")
	_expect(not minimap.route_drawn, "minimap route drawn with nothing selected")
	sg.holder = -1
	sack.queue_free()
	mag.queue_free()


# ---------------------------------------------------------------- code rule

## Nothing in scripts/ui/ (nor route_line.gd) calls a `_private` function of another script: no `x._name(` and no
## `call(&"_name"` on another object.
func _test_no_private_calls() -> void:
	var files := ["res://scripts/vfx/route_line.gd"]
	for f in DirAccess.get_files_at("res://scripts/ui"):
		if f.ends_with(".gd"):
			files.append("res://scripts/ui/" + f)
	var re := RegEx.create_from_string("[A-Za-z0-9_\\]\\)]\\._[a-z]\\w*\\(|call\\(&?\"_")
	for path: String in files:
		var text := FileAccess.get_file_as_string(path)
		var n := 0
		for l in text.split("\n"):
			n += 1
			var code := l.get_slice("#", 0)
			var m := re.search(code)
			if m != null and not code.contains("super."):
				_errors.append("%s:%d calls a private function: %s" % [path.get_file(), n, l.strip_edges()])


# ---------------------------------------------------------------- input helpers

func _key(physical: Key, printed: Key, mods := "") -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = physical
	ev.keycode = printed
	ev.ctrl_pressed = mods.contains("ctrl")
	ev.shift_pressed = mods.contains("shift")
	ev.alt_pressed = mods.contains("alt")
	ev.pressed = true
	root.push_input(ev)
	var up := ev.duplicate() as InputEventKey
	up.pressed = false
	root.push_input(up)


func _move(pos: Vector2) -> void:
	var move := InputEventMouseMotion.new()
	move.position = pos
	move.global_position = pos
	root.push_input(move)


func _click(pos: Vector2, double := false, mods := "") -> void:
	_move(pos)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.position = pos
	ev.global_position = pos
	ev.pressed = true
	ev.double_click = double
	ev.shift_pressed = mods.contains("shift")
	root.push_input(ev)
	var up := ev.duplicate() as InputEventMouseButton
	up.pressed = false
	up.double_click = false
	root.push_input(up)


func _right_click(pos: Vector2) -> void:
	_move(pos)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_RIGHT
	ev.position = pos
	ev.global_position = pos
	ev.pressed = true
	root.push_input(ev)
	var up := ev.duplicate() as InputEventMouseButton
	up.pressed = false
	root.push_input(up)


func _drag(a: Vector2, b: Vector2) -> void:
	_move(a)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.position = a
	ev.global_position = a
	ev.pressed = true
	root.push_input(ev)
	var m := InputEventMouseMotion.new()
	m.position = b
	m.global_position = b
	m.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(m)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.position = b
	up.global_position = b
	up.pressed = false
	root.push_input(up)
