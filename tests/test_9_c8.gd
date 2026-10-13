extends SceneTree
## Task 9.C8 (champions.md 9, ui-champions.md 4 / 6-10): bounty mode R (chip text per kind, raise, refusals, Shift
## stays, Esc / right click leave, minimap Explore), flag card (rect, Z / Shift+Z / Delete, refund tooltip, enemy
## variant), selection filter (box, double-click, groups, F2, right-click never include / order a champion; click =
## inspect), command card inspect text, world stake labels, minimap icons + hunt ping, barks.
## Champions and boards are stubs defined here (they only follow the frozen contracts), so the test does not depend
## on the gameplay / systems tasks.
## Run:  godot --headless --path . -s tests/test_9_c8.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "9.C8"
const TIMEOUT_FRAMES := 5000

var main: Node
var sel: Node
var hud: Node
var card: Node
var mode: Node
var barks: Node
var minimap: Node
var frame := 0
var _wait := 0
var _started := false
var _done := false
var _errors: Array[String] = []
var _messages: Array[String] = []

var own_ch: Unit
var enemy_ch: Unit
var soldiers: Array = []
var board: Node
var enemy_board: Node
var bank: Node


# ---------------------------------------------------------------- stubs

## A champion following the contract: in "champions", `is_commandable()` false, display_name, champion_type,
## intent, level. Counts every order it receives (none may come from the UI).
class StubChampion extends Unit:
	var display_name := "Sable Quint"
	var champion_type: Resource
	var intent: StringName = &"idle"
	var intent_target: Node3D = null
	var is_unpaid := false
	var purse := 50
	var inventory: Node = null
	var orders := 0

	func _ready() -> void:
		super._ready()
		add_to_group(&"champions")

	func is_commandable() -> bool:
		return false

	func command_move(p: Vector3) -> void:
		orders += 1
		super.command_move(p)

	func command_attack(t) -> void:
		orders += 1
		super.command_attack(t)

	func command_stop() -> void:
		orders += 1
		super.command_stop()

	func command_attack_move(p: Vector3) -> void:
		orders += 1

	func command_hold() -> void:
		orders += 1


class StubType extends Resource:
	var id: StringName = &"coin_cutter"
	var barks: Dictionary = {}


class StubInventory extends Node:
	signal item_bought(type: Variant)


## A bounty flag as bounty.gd: group "bounties", team / kind / target / stake / paid / pursuers, time_left(),
## refund_preview(), a ClickBody on layer 2.
class StubFlag extends Node3D:
	signal changed
	var team := 0
	var kind := 1
	var target: Node3D = null
	var stake := 0
	var paid := 0
	var pursuers: Array = []
	var ended := false
	var unseen_time := 0.0
	var elapsed := 0.0

	func _ready() -> void:
		add_to_group(&"bounties")
		var body := StaticBody3D.new()
		body.name = "ClickBody"
		body.collision_layer = 2
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.9, 2.4, 0.9)
		shape.shape = box
		body.add_child(shape)
		body.position.y = 1.2
		add_child(body)

	func time_left() -> float:
		if kind == 2 or kind == 3:
			return maxf(180.0 - elapsed, 0.0)
		if kind == 0 and unseen_time > 0.0:
			return maxf(60.0 - unseen_time, 0.0)
		return -1.0

	func active_pursuers() -> Array:
		return pursuers.filter(func(p: Variant) -> bool: return p != null and is_instance_valid(p))

	func refund_preview() -> int:
		var rest := maxi(stake - paid, 0)
		return rest if active_pursuers().is_empty() else rest - rest / 2


## A bounty board as bounty_board.gd (group "bounty_boards"): place / raise / remove with the 6.2 reasons.
class StubBoard extends Node:
	signal bounty_placed(b: Node)
	signal bounty_paid(b: Node, champion: Node3D, amount: int)
	signal bounty_ended(b: Node, reason: StringName)
	var team := 0
	var bounties: Array = []
	var removed_refunds: Array[int] = []

	func _ready() -> void:
		add_to_group(&"bounty_boards")

	func kind_for(t: Node3D) -> int:
		if t == null:
			return 1
		if t.is_in_group(&"taverns"):
			return -1
		if int(t.get("team")) != team:
			return 0
		if t is Unit:
			return -1 if t.is_in_group(&"champions") else 3
		return 2

	func min_stake(k: int) -> int:
		return [75, 25, 50, 50][k] if k >= 0 and k < 4 else 0

	func _roster() -> int:
		var n := 0
		for c in get_tree().get_nodes_in_group(&"champions"):
			if int(c.get("team")) == team:
				n += 1
		return n

	func bounty_on(t: Node3D) -> Node:
		for b in bounties:
			if b.target == t and t != null:
				return b
		return null

	func place(k: int, t: Node3D, pos: Vector3) -> String:
		if _roster() == 0:
			return "No champions"
		var existing: Node = null
		if k == 1:
			for b in bounties:
				if b.kind == 1 and Vector2(b.global_position.x - pos.x, b.global_position.z - pos.z).length() <= 8.0:
					existing = b
		else:
			existing = bounty_on(t)
		if existing != null:
			return raise(existing, 25)
		if bounties.size() >= 5:
			return "Too many bounties"
		if k < 0 or kind_for(t) != k:
			return "Invalid target"
		var bank := EssenceBank.for_team(team)
		if not bank.spend(min_stake(k)):
			return "Not enough essence"
		var f := StubFlag.new()
		f.team = team
		f.kind = k
		f.target = t if k != 1 else null
		f.stake = min_stake(k)
		f.position = Vector3(pos.x, 0.0, pos.z) if k == 1 else Vector3(t.global_position.x, 0.0, t.global_position.z)
		add_child(f)
		bounties.append(f)
		bounty_placed.emit(f)
		return ""

	func raise(b: Node, amount: int) -> String:
		if not bounties.has(b):
			return "Invalid target"
		if b.stake >= 500:
			return "Max bounty"
		var add := mini(amount, 500 - b.stake)
		if not EssenceBank.for_team(team).spend(add):
			return "Not enough essence"
		b.stake += add
		b.changed.emit()
		return ""

	func remove(b: Node) -> int:
		if not bounties.has(b):
			return 0
		var refund: int = b.refund_preview()
		EssenceBank.for_team(team).add(refund)
		bounties.erase(b)
		b.ended = true
		b.remove_from_group(&"bounties")
		bounty_ended.emit(b, &"removed")
		b.queue_free()
		removed_refunds.append(refund)
		return refund

	func hunts_on(victim: int) -> Array:
		return bounties.filter(func(b: Node) -> bool:
			return b.kind == 0 and b.target != null and is_instance_valid(b.target) \
					and int(b.target.get("team")) == victim)


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
	await _test_selection_filter()
	await _test_bounty_mode()
	await _test_flag_card()
	await _test_world_and_minimap()
	await _test_barks()
	await _test_real_board()
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
	mode = sel.bounty_mode
	barks = sel.barks
	minimap = hud.minimap
	main.camera_rig.edge_pan_enabled = false
	sel.message.connect(func(t: String) -> void: _messages.append(t))
	var fog := FogOfWar.find()
	if fog != null:
		fog.enabled = false
		fog.process_mode = Node.PROCESS_MODE_DISABLED   # the test hides things by hand (visible = false)
	bank = EssenceBank.for_team(0)
	bank.trickle_enabled = false
	bank.essence = 1000
	board = StubBoard.new()
	board.team = 0
	main.add_child(board)
	enemy_board = StubBoard.new()
	enemy_board.team = 1
	main.add_child(enemy_board)
	barks.chance_override = 1.0
	for u in get_nodes_in_group(&"units"):
		if u.team == 0 and not u.is_in_group(&"heroes") and not u.has_method(&"command_gather"):
			soldiers.append(u)
			u.command_stop()
	var start: Vector3 = main.hero.global_position
	own_ch = _make_champion(0, start + Vector3(5.0, 0.0, 0.0), "Sable Quint")
	enemy_ch = _make_champion(1, start + Vector3(26.0, 0.0, -16.0), "Silas Quint")
	enemy_ch.process_mode = Node.PROCESS_MODE_DISABLED   # stays put, never aggroes
	enemy_ch.hp = 1.0e9
	await _frames(12)
	_expect(mode != null and mode is BountyMode, "SelectionManager has no BountyMode")
	_expect(barks != null and barks is ChampionBarks, "SelectionManager has no ChampionBarks")
	_expect(get_nodes_in_group(&"bounty_mode").size() == 1, "not exactly one bounty mode in the scene")
	_expect(card.flag_card != null and card.flag_card.is_inside_tree(), "the command card did not attach the flag card")


func _make_champion(team: int, at: Vector3, n: String) -> Unit:
	var ch := StubChampion.new()
	ch.apply_type(UnitType.find("flame_guard"))
	ch.display_name = n
	ch.unit_name = n
	ch.champion_type = StubType.new()
	ch.team = team
	main.add_child(ch)
	ch.global_position = at
	return ch


func _focus(p: Vector3) -> void:
	main.camera_rig.focus_on(p)
	await _frames(2)


func _screen(p: Vector3, h := 0.8) -> Vector2:
	return main.camera_rig.camera.unproject_position(p + Vector3.UP * h)


# ---------------------------------------------------------------- selection filter

func _test_selection_filter() -> void:
	await _focus(own_ch.global_position)
	var c: Vector2 = _screen(own_ch.global_position)
	_expect(Rect2(200, 150, 1200, 450).has_point(c), "champion not on screen for the clicks (%s)" % c)
	# Box select over the whole battlefield part of the screen: soldiers yes, champion never.
	_drag(Vector2(20, 60), Vector2(1580, 610))
	_expect(not sel.selected.is_empty(), "box select took nothing")
	_expect(not sel.selected.has(own_ch), "box select included the champion")
	_expect(sel.inspected == null, "box select inspected the champion")
	# select_units never keeps a champion either (group recall, the multi view, the champion bar...).
	sel.select_units([own_ch, soldiers[0]])
	_expect(sel.selected.size() == 1 and sel.selected[0] == soldiers[0], "select_units kept the champion: %s" % [sel.selected])
	# Ctrl+1 on soldiers, then inspect the champion and Ctrl+1 again: the group is not wiped nor joined.
	sel.select_units(soldiers.slice(0, 3))
	_key(KEY_1, KEY_AMPERSAND, "ctrl")
	_click(_screen(own_ch.global_position))
	_expect(sel.inspected == own_ch and sel.selected.is_empty(), "click on the champion: inspected %s, selected %d" % [
			sel.inspected, sel.selected.size()])
	_key(KEY_1, KEY_AMPERSAND, "ctrl")
	_key(KEY_2, KEY_2, "shift")
	_expect(sel.get_control_group(1).size() == 3 and not sel.get_control_group(1).has(own_ch),
			"Ctrl+1 while inspecting changed group 1 (%d)" % sel.get_control_group(1).size())
	_expect(sel.get_control_group(2).is_empty(), "Shift+2 while inspecting put the champion in a group")
	# The command card: empty with the inspect text.
	card.refresh()
	_expect(card.slot_ids().all(func(s: String) -> bool: return s == ""), "card not empty while inspecting: %s" % [card.slot_ids()])
	_expect(card.inspect_text() == "Champions act on their own.\nBounty  [R]", "inspect text '%s'" % card.inspect_text())
	# Right click (move / attack) with the champion inspected: no order.
	var before: int = (own_ch as StubChampion).orders
	_right_click(_screen(own_ch.global_position + Vector3(4, 0, 4), 0.0))
	_key(KEY_C, KEY_C)
	_key(KEY_H, KEY_H)
	_key(KEY_X, KEY_X)
	_click(_screen(own_ch.global_position + Vector3(-4, 0, 4), 0.0))
	sel.formation_move(own_ch.global_position + Vector3(3, 0, 0))
	_expect((own_ch as StubChampion).orders == before, "the inspected champion received %d order(s)" % [
			(own_ch as StubChampion).orders - before])
	# Esc drops the inspect view.
	_click(_screen(own_ch.global_position))
	_key(KEY_ESCAPE, KEY_ESCAPE)
	_expect(sel.inspected == null, "Esc did not clear the inspect view")
	# Double-click on the champion = inspect only; on a soldier = all soldiers of the type, no champion.
	_click(_screen(own_ch.global_position), true)
	_expect(sel.inspected == own_ch and sel.selected.is_empty(), "double-click on the champion selected it")
	await _focus(soldiers[0].global_position)
	_click(_screen(soldiers[0].global_position), true)
	_expect(not sel.selected.is_empty() and not sel.selected.has(own_ch) and sel.inspected == null,
			"double-click on a soldier: %d selected, champion in: %s" % [sel.selected.size(), sel.selected.has(own_ch)])
	# F2: the army without the champion.
	_key(KEY_F2, KEY_F2)
	_expect(sel.selected.has(main.hero) and not sel.selected.has(own_ch), "F2 included the champion / missed the wizard")
	# Right click with soldiers selected still orders them (existing behaviour), never the champion.
	before = (own_ch as StubChampion).orders
	_right_click(_screen(main.hero.global_position + Vector3(2, 0, -3), 0.0))
	_expect((own_ch as StubChampion).orders == before, "right click with the army ordered the champion")
	_key(KEY_C, KEY_C)   # the army stops where it is
	# An enemy champion in sight: inspect with the enemy line.
	await _focus(enemy_ch.global_position)
	_click(_screen(enemy_ch.global_position))
	_expect(sel.inspected == enemy_ch, "click on the enemy champion did not inspect it")
	card.refresh()
	_expect(card.inspect_text() == "Champions act on their own.\nHunt it with a bounty  [R]",
			"enemy inspect text '%s'" % card.inspect_text())
	# Hidden by the fog (visible false): the inspect view drops it, and it can't be clicked.
	enemy_ch.visible = false
	await _frames(2)
	_expect(sel.inspected == null, "a fogged enemy champion stayed inspected")
	enemy_ch.visible = true
	sel.select_units([])


# ---------------------------------------------------------------- bounty mode

func _test_bounty_mode() -> void:
	await _focus(main.hero.global_position + Vector3(10, 0, -14))
	var ground: Vector3 = main.hero.global_position + Vector3(10.0, 0.0, -14.0)
	var gp := _screen(ground, 0.0)
	_move(gp)
	_key(KEY_R, KEY_R)
	_expect(mode.active, "R did not enter bounty mode")
	await _frames(4)
	_expect(mode.chip_text() == "Explore · 25 essence", "ground chip '%s'" % mode.chip_text())
	_expect(mode.chip.visible and mode.chip.position.distance_to(gp + Vector2(18, 12)) < 1.5,
			"chip at %s, expected mouse + (18, 12) = %s" % [mode.chip.position, gp + Vector2(18, 12)])
	# The kinds (the board's kind_for): enemy unit Hunt, own building Guard, own soldier Escort, own champion none.
	_expect(mode.chip_parts(mode.preview_for(enemy_ch, enemy_ch.global_position)) == ["", "Hunt", " · 75 essence"],
			"hunt chip %s" % [mode.chip_parts(mode.preview_for(enemy_ch, enemy_ch.global_position))])
	_expect("".join(mode.chip_parts(mode.preview_for(main.keep, main.keep.global_position))) == "Guard · 50 essence",
			"guard chip '%s'" % "".join(mode.chip_parts(mode.preview_for(main.keep, main.keep.global_position))))
	_expect("".join(mode.chip_parts(mode.preview_for(soldiers[1], soldiers[1].global_position))) == "Escort · 50 essence",
			"escort chip")
	_expect(mode.pick_at(_screen(own_ch.global_position))[0] != own_ch, "own champion taken as a bounty target")
	_expect(sel._target_ring.visible, "no ring under the bounty target")
	# Left click: an Explore flag, mode left.
	_click(gp)
	_expect(board.bounties.size() == 1 and board.bounties[0].kind == 1, "left click did not place an Explore flag")
	_expect(not mode.active, "left click did not leave the mode")
	_expect(bank.essence == 975, "stake not paid (essence %d)" % bank.essence)
	# Raise preview on the same spot (within 8 m), then Shift+click raises and stays.
	_key(KEY_R, KEY_R)
	await _frames(4)
	_expect(mode.chip_text() == "Raise +25 · Explore 25 -> 50", "raise chip '%s'" % mode.chip_text())
	var far: Vector3 = main.hero.global_position + Vector3(0.0, 0.0, -20.0)
	_move(_screen(far, 0.0))
	_click(_screen(far, 0.0), false, "shift")
	_expect(board.bounties.size() == 2 and mode.active, "Shift+click: %d flags, active %s" % [board.bounties.size(), mode.active])
	# Esc and right click leave.
	_key(KEY_ESCAPE, KEY_ESCAPE)
	_expect(not mode.active, "Esc did not leave bounty mode")
	_key(KEY_R, KEY_R)
	_right_click(gp)
	_expect(not mode.active, "right click did not leave bounty mode")
	# Minimap click in the mode = an Explore flag there.
	_key(KEY_R, KEY_R)
	sel.confirm_pending_at(Vector3(20.0, 0.0, 20.0))
	_expect(board.bounties.size() == 3 and board.bounties[2].kind == 1, "minimap click did not place Explore")
	# Refusal: not enough essence -> red reason, click refused with the message, mode stays.
	bank.essence = 10
	var spot: Vector3 = main.hero.global_position + Vector3(20.0, 0.0, -6.0)   # > 8 m from every Explore flag
	await _focus(spot)
	var rp := _screen(spot, 0.0)
	_key(KEY_R, KEY_R)
	_move(rp)
	await _frames(4)
	_expect(mode.chip_text() == "Explore · Not enough essence", "refusal chip '%s'" % mode.chip_text())
	_expect(mode.chip_labels[2].get_theme_color("font_color") == UIStyle.WARN, "refusal not in red")
	_messages.clear()
	_click(rp)
	_expect(mode.active and _messages.has("Not enough essence"), "refused click: active %s, messages %s" % [mode.active, _messages])
	_key(KEY_ESCAPE, KEY_ESCAPE)
	bank.essence = 1000
	# No champions: R refused at once with the message.
	own_ch.remove_from_group(&"champions")
	_messages.clear()
	_key(KEY_R, KEY_R)
	_expect(not mode.active and _messages.has("No champions"), "R with no champion: active %s, %s" % [mode.active, _messages])
	own_ch.add_to_group(&"champions")


# ---------------------------------------------------------------- flag card

func _test_flag_card() -> void:
	var flag: Node3D = board.bounties[0]
	await _focus(flag.global_position)
	_click(_screen(flag.global_position, 1.2))
	_expect(sel.selected_bounty == flag, "click on the flag did not select it (%s)" % sel.selected_bounty)
	await _frames(2)
	var fc: Control = card.flag_card
	_expect(fc.visible, "flag card hidden with a flag selected")
	var r: Rect2 = fc.get_global_rect()
	# SC2.U1: in the console's selection block content (ui-sc2-console.md 6).
	_expect(r.position.distance_to(Vector2(252, 696)) < 1.0 and r.size.distance_to(Vector2(872, 192)) < 1.0,
			"flag card rect %s, expected (252, 696) 872 x 192" % r)
	_expect(fc.title_label.text == "EXPLORE BOUNTY", "title '%s'" % fc.title_label.text)
	_expect(fc.target_label.text == "Point: explored ground", "target line '%s'" % fc.target_label.text)
	_expect(fc.time_label.text == "Until a champion reaches it", "time line '%s'" % fc.time_label.text)
	_expect(fc.none_label.visible, "'none yet' not shown without pursuers")
	card.refresh()
	_expect(card.slot_ids()[0] == "raise" and card.slot_ids()[1] == "remove", "flag card slots %s" % [card.slot_ids()])
	_expect(card.key_labels[0].text == "Z" and card.key_labels[1].text == "Del", "flag slot keys")
	# Z = +25, Shift+Z = +100 (the flag was raised to 50 above).
	var stake: int = flag.stake
	_key(KEY_Z, KEY_W)
	_expect(flag.stake == stake + 25, "Z raised to %d, expected %d" % [flag.stake, stake + 25])
	_key(KEY_Z, KEY_W, "shift")
	_expect(flag.stake == stake + 125, "Shift+Z raised to %d, expected %d" % [flag.stake, stake + 125])
	await _frames(20)
	fc.refresh()
	_expect(fc.stake_label.text == str(flag.stake), "card stake '%s'" % fc.stake_label.text)
	card.refresh()
	var tip: String = card.buttons[1].tooltip_text
	_expect(tip.begins_with("Remove  [Delete]\nRefund %d (100 %%): nobody pursues it." % flag.stake), "remove tooltip '%s'" % tip)
	flag.pursuers.append(own_ch)
	fc.refresh()
	card.refresh()
	tip = card.buttons[1].tooltip_text
	var rest: int = flag.stake
	_expect(tip.begins_with("Remove  [Delete]\nRefund %d (50 %%) · %d to the 1 pursuer" % [rest - rest / 2, rest / 2]),
			"remove tooltip with a pursuer '%s'" % tip)
	_expect(fc.chips[0].visible and fc.chips[0].tooltip_text.begins_with("Sable Quint · "), "pursuer chip")
	# Max bounty: raise refused.
	flag.stake = 500
	card.refresh()
	_expect(card.buttons[0].disabled and card.buttons[0].tooltip_text.ends_with("Max bounty"), "raise at 500 not refused")
	flag.stake = rest
	# Delete removes with the refund; the card closes.
	_key(KEY_DELETE, KEY_DELETE)
	_expect(board.removed_refunds == [rest - rest / 2], "Delete refunds %s" % [board.removed_refunds])
	_expect(sel.selected_bounty == null, "the flag is still selected after Delete")
	await _frames(2)
	_expect(not fc.visible, "flag card still shown after Delete")
	# Z / Delete without a flag: no raise, no removal.
	var count: int = board.bounties.size()
	var stakes: Array = board.bounties.map(func(b: Node) -> int: return b.stake)
	sel.select_units([soldiers[0]])
	_key(KEY_Z, KEY_W)
	_key(KEY_DELETE, KEY_DELETE)
	_expect(board.bounties.size() == count and board.bounties.map(func(b: Node) -> int: return b.stake) == stakes,
			"Z / Delete acted on a flag that was not selected")
	# An enemy flag in sight: read-only card, no buttons.
	var ef := StubFlag.new()
	ef.team = 1
	ef.kind = 0
	ef.target = soldiers[2]
	ef.stake = 150
	enemy_board.add_child(ef)
	enemy_board.bounties.append(ef)
	ef.global_position = main.hero.global_position + Vector3(14.0, 0.0, -22.0)   # a clear spot
	await _focus(ef.global_position)
	_click(_screen(ef.global_position, 1.2))
	_expect(sel.selected_bounty == ef, "click on the enemy flag did not select it")
	await _frames(2)
	_expect(fc.visible and fc.title_label.text == "ENEMY HUNT BOUNTY", "enemy card title '%s'" % fc.title_label.text)
	_expect(fc.hint_label.text == "An enemy bounty: kill or protect its target." and not fc.pursuers_label.visible,
			"enemy card hint / pursuers")
	card.refresh()
	_expect(card.slot_ids().all(func(s: String) -> bool: return s == ""), "enemy flag has card buttons")
	_key(KEY_ESCAPE, KEY_ESCAPE)
	_expect(sel.selected_bounty == null, "Esc did not clear the selected flag")


# ---------------------------------------------------------------- world labels and minimap

func _test_world_and_minimap() -> void:
	# A Guard flag on the keep via the board, labels refreshed at 2 Hz.
	_expect(board.place(2, main.keep, main.keep.global_position) == "", "guard place refused")
	await _frames(40)
	for b in board.bounties:
		var l: Label3D = ChampionBarks.stake_label_of(b)
		_expect(l != null, "flag without a stake label")
		if l == null:
			continue
		if b.kind == 2:
			_expect(l.text.begins_with("50 · 2:5") or l.text.begins_with("50 · 3:00"), "guard label '%s'" % l.text)
		else:
			_expect(l.text == str(b.stake), "stake label '%s' for %d" % [l.text, b.stake])
		_expect(l.font_size == 40 and is_equal_approx(l.pixel_size, 0.006) and is_equal_approx(l.position.y, 2.3),
				"stake label look")
	# Minimap: 2 champions (own + visible enemy), own flags + the visible enemy flag, taverns once explored.
	var tavern := Node3D.new()
	tavern.add_to_group(&"taverns")
	main.add_child(tavern)
	tavern.global_position = Vector3(-15.0, 0.0, -15.0)
	await _frames(15)
	_expect(minimap.drawn_champions == 2, "minimap champions %d, expected 2" % minimap.drawn_champions)
	_expect(minimap.drawn_flags == board.bounties.size() + 1, "minimap flags %d, expected %d" % [
			minimap.drawn_flags, board.bounties.size() + 1])
	_expect(minimap.drawn_taverns == 1, "minimap taverns %d" % minimap.drawn_taverns)
	enemy_ch.visible = false
	var ef: Node3D = enemy_board.bounties[0]
	ef.visible = false
	await _frames(15)
	_expect(minimap.drawn_champions == 1, "a hidden enemy champion is drawn (%d)" % minimap.drawn_champions)
	_expect(minimap.drawn_flags == board.bounties.size(), "a hidden enemy flag is drawn (%d)" % minimap.drawn_flags)
	enemy_ch.visible = true
	ef.visible = true
	# Hunt ping: a new enemy Hunt on the player's soldier.
	var pings: int = minimap.hunt_pings
	var h := StubFlag.new()
	h.team = 1
	h.kind = 0
	h.target = soldiers[3]
	h.stake = 100
	enemy_board.add_child(h)
	enemy_board.bounties.append(h)
	await _frames(40)
	_expect(minimap.hunt_pings > pings, "no minimap ping for a new hunt on the player")
	tavern.queue_free()


# ---------------------------------------------------------------- barks

func _test_barks() -> void:
	# Both champions barked "hired" when first seen (the enemy one was visible).
	var hired: Array = barks.bark_log.filter(func(e: Dictionary) -> bool: return e["trigger"] == &"hired")
	_expect(hired.size() == 2, "hired barks %d, expected 2" % hired.size())
	# A fresh champion: the hired line (fallback table), Label3D look, 3 s life.
	var ch := _make_champion(0, main.hero.global_position + Vector3(-4.0, 0.0, 2.0), "Tamsin Farrow")
	(ch.champion_type as StubType).id = &"wayfinder"
	await _frames(20)
	var l: Label3D = ChampionBarks.label_of(ch)
	_expect(l != null and l.text == "Maps are just rumours with lines. Let's draw some.", "hired bark '%s'" % (l.text if l else "none"))
	if l:
		_expect(l.font_size == 32 and l.outline_size == 2 and is_equal_approx(l.pixel_size, 0.006)
				and is_equal_approx(l.width, 560.0) and is_equal_approx(l.position.y, ch.body_height + 1.1),
				"bark label look (size %d outline %d px %.3f w %.0f y %.2f)" % [l.font_size, l.outline_size,
				l.pixel_size, l.width, l.position.y])
	# 20 s cooldown: a flee right after is silent.
	ch.intent = &"fleeing"
	await _frames(20)
	_expect(barks.bark_log.back()["champion"] == ch and barks.bark_log.back()["trigger"] == &"hired",
			"a second bark within 20 s")
	# Label gone after 3 s.
	await _frames(180)
	_expect(ChampionBarks.label_of(ch) == null, "bark label still there after 3 s")
	# Cooldown over (tests skip the wait): level up, bounty intent, a purchase.
	barks.reset_cooldown(ch)
	ch.level = 2
	await _frames(20)
	_expect(barks.bark_log.back()["trigger"] == &"level_up" and ChampionBarks.label_of(ch).text == "I've seen more. I am more.",
			"level-up bark")
	barks.reset_cooldown(ch)
	ch.intent = &"hunting_bounty"
	await _frames(20)
	_expect(barks.bark_log.back()["trigger"] == &"bounty", "bounty bark (%s)" % barks.bark_log.back()["trigger"])
	barks.reset_cooldown(ch)
	var inv := StubInventory.new()
	ch.add_child(inv)
	ch.inventory = inv
	await _frames(20)
	inv.item_bought.emit(null)
	_expect(barks.bark_log.back()["trigger"] == &"buy", "buy bark")
	# Flee (from a non-flee intent).
	barks.reset_cooldown(ch)
	ch.intent = &"fleeing"
	await _frames(20)
	_expect(barks.bark_log.back()["trigger"] == &"flee" and ChampionBarks.label_of(ch).text == "Nope. Mapping the way home!",
			"flee bark")
	# Only when visible to the local team: a hidden enemy champion stays silent.
	barks.reset_cooldown(enemy_ch)
	enemy_ch.visible = false
	_expect(not barks.bark(enemy_ch, &"flee"), "a hidden enemy champion barked")
	enemy_ch.visible = true
	_expect(barks.bark(enemy_ch, &"flee"), "a visible enemy champion did not bark")


# ---------------------------------------------------------------- the real board (when 9.C4's scripts exist)

## Same flow against scripts/world/bounty_board.gd + bounty.gd (reached untyped): place through R + click, the
## flag's own "Stake" label, select it, Z, Delete. Skipped while those scripts are missing.
func _test_real_board() -> void:
	const PATH := "res://scripts/world/bounty_board.gd"
	if not ResourceLoader.exists(PATH):
		print("  (real BountyBoard missing: section skipped)")
		return
	for b in [board, enemy_board]:
		b.remove_from_group(&"bounty_boards")
	var real: Node = load(PATH).call(&"for_team", 0)
	await _frames(2)
	_expect(real != null and BountyMode.board_for(0) == real, "BountyMode does not use the real board")
	if real == null:
		return
	bank.essence = 1000
	var spot: Vector3 = main.hero.global_position + Vector3(-2.0, 0.0, -26.0)
	await _focus(spot)
	var sp := _screen(spot, 0.0)
	_move(sp)
	_key(KEY_R, KEY_R)
	await _frames(4)
	_expect(mode.chip_text() == "Explore · 25 essence", "real board chip '%s'" % mode.chip_text())
	_click(sp)
	var list: Array = real.get("bounties")
	_expect(list.size() == 1, "real board: %d flags after the click" % list.size())
	if list.size() != 1:
		return
	var f: Node3D = list[0]
	await _frames(40)
	var l: Label3D = ChampionBarks.stake_label_of(f)
	_expect(l != null and l.text == "25", "real flag stake label '%s'" % (l.text if l else "none"))
	_click(_screen(f.global_position, 1.2))
	_expect(sel.selected_bounty == f, "click on the real flag did not select it")
	await _frames(2)
	_expect(card.flag_card.visible and card.flag_card.title_label.text == "EXPLORE BOUNTY", "real flag card")
	_key(KEY_Z, KEY_W)
	_expect(int(f.get("stake")) == 50, "Z on the real flag: stake %d" % int(f.get("stake")))
	var before: int = bank.essence
	_key(KEY_DELETE, KEY_DELETE)
	_expect(bank.essence == before + 50 and sel.selected_bounty == null, "Delete on the real flag: essence %d -> %d" % [
			before, bank.essence])


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
