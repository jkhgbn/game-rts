class_name BountyMode
extends Control
## Bounty mode (champions.md 6.2 / section 9, layout ui-champions.md section 6).
## **R** (physical, handled by the SelectionManager, which owns the one instance: it is created in the selection
## manager's canvas layer, group "bounty_mode") enters the mode unless the roster is empty (`No champions`) or 5
## flags are up (`Too many bounties`). In the mode: cross cursor, a chip follows the mouse at + (18, 12) with the kind
## and price of what is under it (enemy / neutral target = Hunt, own building = Guard, own unit = Escort, ground =
## Explore, something that already carries your flag = `Raise +25 · Hunt 150 -> 175`) or the kind + the refusal in red;
## a gold ring marks the target (red when refused). Left click places at the minimum stake and leaves the mode,
## Shift+click places and stays, right click / Esc leave. A minimap click places an Explore flag there.
## The step-9 classes are reached untyped: `board_for(team)` = a node in group "bounty_boards" of that team, else
## `BountyBoard.for_team(team)` through `load()` when the script exists. Messages about payments, refunds, pursuers and
## hunt warnings come from the board itself; this node only reports refusals.

## The mode was entered or left.
signal mode_changed(active: bool)
## A flag was placed or raised: the preview dictionary that was committed.
signal placed(result: Dictionary)

## Bounty kinds (Bounty.HUNT / EXPLORE / GUARD / ESCORT, the flag model's set_kind order).
const HUNT := 0
const EXPLORE := 1
const GUARD := 2
const ESCORT := 3
const KIND_NAMES: Array[String] = ["Hunt", "Explore", "Guard", "Escort"]
## Minimum stakes (6.1), used when the board is missing.
const MIN_STAKES: Array[int] = [75, 25, 50, 50]
## Kind word colours (ui-champions.md 13.2 = the intent colours).
const KIND_COLORS: Array[Color] = [Color(1.0, 0.85, 0.4), Color(0.45, 0.85, 1.0), Color(0.6, 0.75, 1.0),
		Color(0.6, 0.75, 1.0)]
const COIN_COLOR := Color(1.0, 0.85, 0.3)
const COIN_RING := Color(0.55, 0.42, 0.1)
const ICON_INK := Color(0.35, 0.25, 0.05)
const RING_COLOR := Color(1.0, 0.85, 0.3, 0.8)
const RAISE_STEP := 25
const RAISE_BIG := 100
const MAX_STAKE := 500
const MAX_ACTIVE := 5
const EXPLORE_MERGE := 8.0

const MSG_NO_CHAMPIONS := "No champions"
const MSG_TOO_MANY := "Too many bounties"
const MSG_INVALID := "Invalid target"
const MSG_NO_ESSENCE := "Not enough essence"
const MSG_MAX := "Max bounty"
const MSG_NO_BOARD := "No champions"

const BOARD_PATH := "res://scripts/world/bounty_board.gd"
const GUILD_PATH := "res://scripts/world/champion_guild.gd"
const BOARD_GROUP := &"bounty_boards"
const GUILD_GROUP := &"champion_guilds"
const GROUP := &"bounty_mode"

## The chip (ui-champions.md 6.2).
const CHIP_OFFSET := Vector2(18, 12)
const CHIP_HEIGHT := 26.0
const CHIP_FONT := 13
const SCREEN_MARGIN := 4.0
const FLASH_TIME := 0.2
const SHAKE_TIME := 0.2
const SHAKE_PX := 3.0

var selection: SelectionManager
## The team placing flags (the local player).
var team: int = Unit.Team.PLAYER
## Read only: true while bounty mode is on.
var active := false
## Read only: what a click would do now ({kind, target, pos, raise, amount, text, reason}).
var preview: Dictionary = {}
## Read only: the last place / raise result ("" = ok).
var last_result := ""
## The chip and its parts (read only; tests read the text).
var chip: PanelContainer
var glyph: Control
var chip_labels: Array[Label] = []   ## prefix, kind word, rest

var _mouse := Vector2.ZERO
var _preview_left := 0.0
var _flash_left := 0.0
var _shake_left := 0.0
var _duplicate := false


func _enter_tree() -> void:
	# One bounty mode per scene: a second instance (e.g. HUD glue) steps aside for the selection manager's.
	for other in get_tree().get_nodes_in_group(GROUP):
		if other != self and is_instance_valid(other) and not other.is_queued_for_deletion():
			_duplicate = true
			queue_free()
			return
	add_to_group(GROUP)


func _ready() -> void:
	if _duplicate:
		return
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip = PanelContainer.new()
	chip.name = "BountyChip"
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.z_index = 10
	chip.visible = false
	chip.custom_minimum_size = Vector2(0, CHIP_HEIGHT)
	chip.add_theme_stylebox_override("panel", _chip_style())
	add_child(chip)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(row)
	glyph = Control.new()
	glyph.custom_minimum_size = Vector2(20, 20)
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.draw.connect(_draw_glyph)
	row.add_child(glyph)
	var text_row := HBoxContainer.new()
	text_row.add_theme_constant_override("separation", 0)
	text_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text_row)
	for i in 3:
		var l := UIStyle.panel_label("", CHIP_FONT)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		text_row.add_child(l)
		chip_labels.append(l)


## HUD glue (ui-champions.md 13.4): returns the scene's bounty mode (the selection manager's), creating one under
## `hud` only when none exists.
static func attach(hud: Node) -> BountyMode:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		for m in tree.get_nodes_in_group(GROUP):
			if m is BountyMode and not m.is_queued_for_deletion():
				return m
	var mode := BountyMode.new()
	mode.name = "BountyMode"
	if hud != null:
		hud.add_child(mode)
		var sel: Variant = null
		if hud.get_parent() != null:
			sel = hud.get_parent().get("selection")   # the level's SelectionManager (main.gd `selection`)
		if sel is SelectionManager:
			mode.selection = sel
			(sel as SelectionManager).bounty_mode = mode
	return mode


func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		_mouse = (event as InputEventMouse).position


func _process(delta: float) -> void:
	if _duplicate or not active:
		return
	_preview_left -= delta
	if _preview_left <= 0.0:
		_preview_left = 0.05   # 20 Hz is plenty for the text and the ring
		update_preview(_mouse)
	_flash_left = maxf(_flash_left - delta, 0.0)
	_shake_left = maxf(_shake_left - delta, 0.0)
	_place_chip()
	if _flash_left > 0.0 or _shake_left > 0.0:
		_style_labels()


# ---------------------------------------------------------------- mode

## For the HUD's tavern click check.
func is_active() -> bool:
	return active


## R: bounty mode on (other targeting and the build menu close). Refused with a message when the roster is
## empty or 5 flags are up. Returns "" or the reason.
func enter() -> String:
	if active:
		return ""
	var reason := ""
	if roster_size(team) <= 0:
		reason = MSG_NO_CHAMPIONS
	elif active_flags(team).size() >= MAX_ACTIVE:
		reason = MSG_TOO_MANY
	if reason != "":
		_message(reason)
		return reason
	if selection != null:
		selection.cancel_targeting()
		selection.close_build_menu()
	active = true
	_preview_left = 0.0
	_flash_left = 0.0
	_shake_left = 0.0
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)
	update_preview(_mouse)
	chip.visible = true
	_place_chip()
	mode_changed.emit(true)
	if selection != null:
		selection.mode_changed.emit()
	return ""


## Right click / Esc / another order: bounty mode off.
func exit() -> void:
	if not active:
		return
	active = false
	preview = {}
	chip.visible = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	if selection != null:
		selection.hide_bounty_ring()
	mode_changed.emit(false)
	if selection != null:
		selection.mode_changed.emit()


func toggle() -> void:
	if active:
		exit()
	else:
		enter()


## Left click in the world while active: place (or raise) at `screen_pos`. `keep_mode` (Shift) stays in the mode;
## otherwise a success leaves it. A refusal shakes the chip, shows its reason and stays. Returns "" or the reason.
func click(screen_pos: Vector2, keep_mode := false) -> String:
	_mouse = screen_pos
	var d := update_preview(screen_pos)
	if d.is_empty():
		return ""
	return _commit_and_leave(d, keep_mode)


## A click on a world point without a target (the minimap): an Explore flag there, or a raise of your Explore flag
## within 8 m. Same Shift / refusal rules as `click`.
func click_world(point: Vector3, keep_mode := false) -> String:
	preview = preview_for(null, point)
	_show_preview()
	return _commit_and_leave(preview, keep_mode)


func _commit_and_leave(d: Dictionary, keep_mode: bool) -> String:
	var result := commit(d)
	if result == "":
		if not keep_mode:
			exit()
		else:
			_flash_left = FLASH_TIME   # the chip stays: its text flashes gold 0.2 s
			_preview_left = 0.0
	else:
		_shake_left = SHAKE_TIME
	return result


# ---------------------------------------------------------------- preview

## Recomputes `preview` for what is under `screen_pos` (empty when the mouse is off the ground) and updates the
## chip and the ring.
func update_preview(screen_pos: Vector2) -> Dictionary:
	preview = preview_at(screen_pos)
	_show_preview()
	return preview


## What a click at `screen_pos` would do (see preview_for).
func preview_at(screen_pos: Vector2) -> Dictionary:
	var pick := pick_at(screen_pos)
	if pick.is_empty():
		return {}
	return preview_for(pick[0], pick[1])


## [target: Node3D or null, pos: Vector3] under `screen_pos`: one of your flags, a unit (not your own champion: the
## ground under it), a building (not a tavern), else the ground point. Empty when the ray misses the ground.
func pick_at(screen_pos: Vector2) -> Array:
	if selection == null or selection.camera == null:
		return []
	var flag := selection.flag_at(screen_pos)
	if flag != null and flag.get("team") != null and int(flag.get("team")) == team:
		return [flag, flag.global_position]
	# A visible game critter (12.C6's selection ray): picked so kind_for refuses it ("Hunt · Invalid target").
	if selection.has_method(&"critter_at"):
		var c: Variant = selection.call(&"critter_at", screen_pos)
		if c is Node3D and is_instance_valid(c):
			return [c, (c as Node3D).global_position]
	var u := selection.unit_at(screen_pos)
	if u != null and not (u.team == team and u.is_in_group(&"champions")):
		return [u, u.global_position]
	var b := selection.building_at(screen_pos)
	if b != null and not b.is_in_group(&"taverns"):
		return [b, b.global_position]
	var p: Variant = selection.ground_point(screen_pos)
	if p == null:
		return []
	return [null, p]


## The kind, price and refusal for placing on `target` (null = the ground at `pos`):
## {kind, target, pos, raise (the flag raised, or null), amount, stake, text, reason}. `text` is the chip line
## (`Hunt · 75 essence`, `Raise +25 · Hunt 150 -> 175`, or `Guard · Invalid target` when refused) and `reason` the
## refusal ("" = allowed).
func preview_for(target: Node3D, pos: Vector3) -> Dictionary:
	var board := board_for(team)
	var d := {"kind": -1, "target": target, "pos": pos, "raise": null, "amount": 0, "stake": 0, "text": "",
			"reason": ""}
	var existing := _existing_flag(target, pos, board)
	if existing != null:
		var k := flag_kind(existing)
		var stake := flag_stake(existing)
		d["raise"] = existing
		d["kind"] = k
		d["amount"] = RAISE_STEP
		d["stake"] = stake
		d["reason"] = raise_reason(existing, RAISE_STEP)
		if d["reason"] == "":
			d["text"] = "Raise +%d · %s %d -> %d" % [RAISE_STEP, kind_name(k), stake, mini(stake + RAISE_STEP, MAX_STAKE)]
		else:
			d["text"] = "Raise · %s" % d["reason"]
		return d
	var kind := kind_for(target, board)
	d["kind"] = kind
	var shown := kind if kind >= 0 else _guess_kind(target)
	var price := min_stake(shown, board)
	d["amount"] = price
	d["stake"] = price
	d["reason"] = place_reason(kind, target, pos, board)
	if d["reason"] == "":
		d["text"] = "%s · %d essence" % [kind_name(shown), price]
	else:
		d["text"] = "%s · %s" % [kind_name(shown), d["reason"]]
	return d


## Why placing `kind` on `target` / `pos` would be refused, in the 6.2 order ("" = ok): `No champions`,
## `Too many bounties`, `Invalid target`, `Not enough essence`. The board's `can_place` wins when it has one.
func place_reason(kind: int, target: Node3D, pos: Vector3, board: Node = null) -> String:
	if board == null:
		board = board_for(team)
	if board != null and board.has_method(&"can_place"):
		return str(board.call(&"can_place", kind, target, pos))
	if roster_size(team) <= 0:
		return MSG_NO_CHAMPIONS
	if active_flags(team).size() >= MAX_ACTIVE:
		return MSG_TOO_MANY
	if kind < 0 or not _valid_target(kind, target, pos):
		return MSG_INVALID
	if essence_of(team) < min_stake(kind, board):
		return MSG_NO_ESSENCE
	return ""


## Why raising `flag` by `amount` would be refused ("" = ok): `Max bounty`, `Not enough essence`.
func raise_reason(flag: Node, amount: int) -> String:
	if flag == null or not is_instance_valid(flag):
		return MSG_INVALID
	var board := board_for(team)
	if board != null and board.has_method(&"can_raise"):
		return str(board.call(&"can_raise", flag, amount))
	if flag_stake(flag) >= MAX_STAKE:
		return MSG_MAX
	if essence_of(team) < mini(amount, MAX_STAKE - flag_stake(flag)):
		return MSG_NO_ESSENCE
	return ""


## Places / raises what `d` (a preview) describes through the board. Returns "" or the reason (sent as a message).
func commit(d: Dictionary) -> String:
	var board := board_for(team)
	var result := ""
	if board == null:
		result = str(d.get("reason", "")) if str(d.get("reason", "")) != "" else MSG_NO_BOARD
	elif d.get("raise") != null:
		result = str(board.call(&"raise", d["raise"], int(d.get("amount", RAISE_STEP))))
	else:
		var target: Node3D = d.get("target")
		var pos: Vector3 = d.get("pos", Vector3.ZERO)
		var kind := int(d.get("kind", -1))
		if kind < 0:
			result = MSG_INVALID
		else:
			result = str(board.call(&"place", kind, target, pos))
	last_result = result
	if result != "":
		_message(result)
	else:
		placed.emit(d)
	return result


# ---------------------------------------------------------------- flags (raise / remove, used by the flag card)

## Z (+25) / Shift+Z (+100) on the selected flag, or the card button. Returns "" or the reason (also a message).
func raise_flag(flag: Node, amount: int) -> String:
	var board := board_for(team)
	var result := ""
	if flag == null or not is_instance_valid(flag) or flag.get("team") == null or int(flag.get("team")) != team:
		result = MSG_INVALID
	elif board == null:
		result = MSG_NO_BOARD
	else:
		result = str(board.call(&"raise", flag, amount))
	if result != "":
		_message(result)
	return result


## Delete on the selected flag: removes it and returns the refund (-1 when refused). The board says
## `Bounty refunded: N`.
static func remove_flag(flag: Node) -> int:
	if flag == null or not is_instance_valid(flag) or flag.get("team") == null:
		return -1
	var board := board_for(int(flag.get("team")))
	if board == null:
		return -1
	return int(board.call(&"remove", flag))


## What removing `flag` now would give back: the unpaid part, 100 % with no pursuer, else 50 % (6.2).
static func refund_preview(flag: Node) -> int:
	if flag == null or not is_instance_valid(flag):
		return 0
	if flag.has_method(&"refund_preview"):
		return int(flag.call(&"refund_preview"))
	var unpaid := maxi(0, flag_stake(flag) - flag_paid(flag))
	if flag_pursuers(flag).is_empty():
		return unpaid
	return unpaid - unpaid / 2


# ---------------------------------------------------------------- lookups (static, untyped step-9 classes)

## The BountyBoard of `for_team`: a node in group "bounty_boards" with that team, else BountyBoard.for_team().
static func board_for(for_team: int) -> Node:
	return _find_system(BOARD_GROUP, BOARD_PATH, for_team)


## The ChampionGuild of `for_team` (group "champion_guilds", else ChampionGuild.for_team()).
static func guild_for(for_team: int) -> Node:
	return _find_system(GUILD_GROUP, GUILD_PATH, for_team)


static func _find_system(group: StringName, path: String, for_team: int) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	for n in tree.get_nodes_in_group(group):
		if n.get("team") != null and int(n.get("team")) == for_team and not n.is_queued_for_deletion():
			return n
	var script := static_script(path)
	if script == null:
		return null
	var found: Variant = script.call(&"for_team", for_team)
	return found as Node if found is Node else null


static var _script_cache: Dictionary = {}   # path -> Script that has a static for_team


static func static_script(path: String) -> Script:
	if _script_cache.has(path):
		return _script_cache[path]
	var out: Script = null
	if ResourceLoader.exists(path):
		var s := load(path) as Script
		if s != null and s.can_instantiate():
			for m in s.get_script_method_list():
				if str(m.get("name", "")) == "for_team":
					out = s
					break
	if out != null:
		_script_cache[path] = out   # a missing script is looked up again later (it may appear)
	return out


## Champions in the roster of `for_team` (alive, reviving or fallen): the guild's `champions`, else group "champions".
static func roster_size(for_team: int) -> int:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return 0
	for guild in tree.get_nodes_in_group(GUILD_GROUP):
		if guild.get("team") != null and int(guild.get("team")) == for_team and guild.get("champions") is Array:
			var n := 0
			for ch: Variant in guild.get("champions"):
				if ch != null and is_instance_valid(ch):
					n += 1
			return n
	var count := 0
	for c in tree.get_nodes_in_group(&"champions"):
		if c.get("team") != null and int(c.get("team")) == for_team and not c.is_queued_for_deletion():
			count += 1
	return count


## The essence in the bank of `for_team` (0 without a bank; never creates one).
static func essence_of(for_team: int) -> int:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return 0
	for n in tree.get_nodes_in_group(&"essence_banks"):
		if n.get("team") != null and int(n.get("team")) == for_team:
			return int(n.get("essence"))
	return 0


## The active flags of `for_team`: the board's `bounties`, else the nodes in group "bounties" of that team.
static func active_flags(for_team: int) -> Array:
	var out: Array = []
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return out
	var source: Array = []
	var board: Node = null
	for n in tree.get_nodes_in_group(BOARD_GROUP):   # never creates a board just to count
		if n.get("team") != null and int(n.get("team")) == for_team:
			board = n
			break
	if board != null and board.get("bounties") is Array:
		source = board.get("bounties")
	else:
		source = tree.get_nodes_in_group(&"bounties")
	for b in source:
		if is_instance_valid(b) and b is Node and not (b as Node).is_queued_for_deletion() \
				and b.get("team") != null and int(b.get("team")) == for_team and not bool(b.get("ended")):
			out.append(b)
	return out


## The minimum stake of `kind` (the board's `min_stake`, else 75 / 25 / 50 / 50).
static func min_stake(kind: int, board: Node = null) -> int:
	if board != null and board.has_method(&"min_stake"):
		return int(board.call(&"min_stake", kind))
	return MIN_STAKES[kind] if kind >= 0 and kind < MIN_STAKES.size() else 0


static func kind_name(kind: int) -> String:
	return KIND_NAMES[kind] if kind >= 0 and kind < KIND_NAMES.size() else "Bounty"


## A team's pennant colour: BountyBoard.team_color (the kingdom colour) when the board script exists, else
## Unit.team_color.
static func pennant_color(t: int) -> Color:
	var s := static_script(BOARD_PATH)
	if s != null:
		for m in s.get_script_method_list():
			if str(m.get("name", "")) == "team_color":
				var c: Variant = s.call(&"team_color", t)
				if c is Color:
					return c
				break
	return Unit.team_color(t)


static func kind_color(kind: int) -> Color:
	return KIND_COLORS[kind] if kind >= 0 and kind < KIND_COLORS.size() else UIStyle.GOLD


static func flag_kind(flag: Node) -> int:
	var k: Variant = flag.get("kind") if flag != null and is_instance_valid(flag) else null
	return int(k) if k != null else -1


static func flag_stake(flag: Node) -> int:
	var v: Variant = flag.get("stake") if flag != null and is_instance_valid(flag) else null
	return int(v) if v != null else 0


static func flag_paid(flag: Node) -> int:
	var v: Variant = flag.get("paid") if flag != null and is_instance_valid(flag) else null
	return int(v) if v != null else 0


static func flag_team(flag: Node) -> int:
	var v: Variant = flag.get("team") if flag != null and is_instance_valid(flag) else null
	return int(v) if v != null else -1


## Living pursuers of `flag` (the flag's `active_pursuers()` when it has it).
static func flag_pursuers(flag: Node) -> Array:
	var out: Array = []
	if flag == null or not is_instance_valid(flag):
		return out
	var v: Variant = flag.call(&"active_pursuers") if flag.has_method(&"active_pursuers") else flag.get("pursuers")
	if v is Array:
		for p in v:
			if is_instance_valid(p) and p is Node:
				out.append(p)
	return out


## The flag's target node, or null (Explore, or the target is gone).
static func flag_target(flag: Node) -> Node3D:
	var t: Variant = flag.get("target") if flag != null and is_instance_valid(flag) else null
	if is_instance_valid(t) and t is Node3D:
		return t
	return null


## Seconds left on a Guard / Escort / lost Hunt flag, or -1 when it does not run out.
static func flag_time_left(flag: Node) -> float:
	if flag == null or not is_instance_valid(flag) or not flag.has_method(&"time_left"):
		return -1.0
	var t := float(flag.call(&"time_left"))
	return t if t >= 0.0 and t < 1.0e6 else -1.0


## True while a Hunt flag's target is unseen by its team (the refund countdown runs).
static func flag_target_lost(flag: Node) -> bool:
	return flag_kind(flag) == HUNT and flag.get("unseen_time") != null and float(flag.get("unseen_time")) > 0.0


## Whether the local team sees `flag` (own flags always; `Bounty.is_shown()` when it exists).
static func flag_shown(flag: Node3D, local_team: int) -> bool:
	if flag == null or not is_instance_valid(flag) or not flag.is_inside_tree():
		return false
	if flag_team(flag) == local_team:
		return true
	if flag.has_method(&"is_visible_to"):
		return bool(flag.call(&"is_visible_to", local_team))
	if flag.has_method(&"is_shown"):
		return bool(flag.call(&"is_shown"))
	return flag.is_visible_in_tree()


## The name to show for a target: champions their display name, wizards their short name ("Vessa"), buildings
## their type's display name, units their unit name.
static func target_name(node: Node) -> String:
	if node == null or not is_instance_valid(node):
		return ""
	var dn: Variant = node.get("display_name")
	if dn != null and str(dn) != "":
		return str(dn)
	var bt: Variant = node.get("building_type")
	if bt is Object and (bt as Object).get("display_name") != null:
		return str((bt as Object).get("display_name"))
	var un: Variant = node.get("unit_name")
	if un != null:
		return str(un).get_slice(",", 0).strip_edges()
	return str(node.name)


static func is_building(node: Node) -> bool:
	return node != null and node.is_in_group(&"buildings")


## Draws a bounty kind icon (ui-champions.md 13.2) in a coin of radius `r` centred at `c`; kind -1 = "+" (raise).
static func draw_kind_icon(ci: CanvasItem, c: Vector2, r: float, kind: int, ink: Color) -> void:
	var w := maxf(1.0, r / 4.0)
	match kind:
		HUNT:
			ci.draw_line(c + Vector2(-0.55, -0.55) * r, c + Vector2(0.55, 0.55) * r, ink, w, true)
			ci.draw_line(c + Vector2(-0.55, 0.55) * r, c + Vector2(0.55, -0.55) * r, ink, w, true)
		EXPLORE:
			var pts := PackedVector2Array()
			for i in 17:
				var a := TAU * float(i) / 16.0
				pts.append(c + Vector2(cos(a) * 0.65 * r, sin(a) * 0.4 * r))
			ci.draw_polyline(pts, ink, w, true)
			ci.draw_circle(c, 0.18 * r, ink)
		GUARD:
			var s := PackedVector2Array([c + Vector2(-0.5, -0.55) * r, c + Vector2(0.5, -0.55) * r,
					c + Vector2(0.5, 0.05) * r, c + Vector2(0.0, 0.6) * r, c + Vector2(-0.5, 0.05) * r,
					c + Vector2(-0.5, -0.55) * r])
			ci.draw_polyline(s, ink, w, true)
		ESCORT:
			ci.draw_arc(c + Vector2(-0.2 * r, 0.0), 0.32 * r, 0.0, TAU, 16, ink, w, true)
			ci.draw_arc(c + Vector2(0.2 * r, 0.0), 0.32 * r, 0.0, TAU, 16, ink, w, true)
		_:
			ci.draw_line(c + Vector2(-0.5 * r, 0.0), c + Vector2(0.5 * r, 0.0), ink, w, true)
			ci.draw_line(c + Vector2(0.0, -0.5 * r), c + Vector2(0.0, 0.5 * r), ink, w, true)


## The flag glyph (ui-champions.md 6.2, x `k` for the flag card's tile): pole, pennant in `pennant`, gold coin with the
## kind icon. `o` = the top-left of the 20 x 20 (x k) box.
static func draw_flag_glyph(ci: CanvasItem, o: Vector2, k: float, kind: int, pennant: Color) -> void:
	ci.draw_line(o + Vector2(5, 2) * k, o + Vector2(5, 18) * k, UIStyle.token(&"frame_dark"), 2.0 if k <= 1.0 else 3.0)
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(7, 3) * k, o + Vector2(17, 7) * k,
			o + Vector2(7, 11) * k]), pennant)
	var c := o + Vector2(13, 14) * k
	var r := 5.0 * k
	ci.draw_circle(c, r, COIN_COLOR)
	ci.draw_arc(c, r, 0.0, TAU, 24, COIN_RING, maxf(1.0, k * 0.5), true)
	draw_kind_icon(ci, c, r * 1.1, kind, ICON_INK)


# ---------------------------------------------------------------- internals

## Your flag already on `target` (or, on the ground, your Explore flag within 8 m of `pos`), or null. A flag under
## the cursor is itself.
func _existing_flag(target: Node3D, pos: Vector3, board: Node) -> Node:
	if target != null and target.is_in_group(&"bounties"):
		return target if flag_team(target) == team else null
	if target != null and board != null and board.has_method(&"bounty_on"):
		var b: Variant = board.call(&"bounty_on", target)
		return b as Node if b is Node else null
	for f in active_flags(team):
		if target != null:
			if flag_target(f) == target:
				return f
		elif flag_kind(f) == EXPLORE:
			var fp: Vector3 = (f as Node3D).global_position
			if Vector2(fp.x - pos.x, fp.z - pos.z).length() <= EXPLORE_MERGE:
				return f
	return null


## The kind for `target` (board.kind_for when it exists): enemy / neutral = Hunt, own building = Guard, own unit =
## Escort, ground (null) = Explore; -1 = nothing can go there.
func kind_for(target: Node3D, board: Node = null) -> int:
	if target == null:
		return EXPLORE
	if board != null and board.has_method(&"kind_for"):
		return int(board.call(&"kind_for", target))
	if target.is_in_group(&"taverns") or (target.is_in_group(&"champions") and target.get("team") != null \
			and int(target.get("team")) == team):
		return -1
	return _guess_kind(target)


func _guess_kind(target: Node3D) -> int:
	if target == null:
		return EXPLORE
	var t: Variant = target.get("team")
	if t == null:
		return EXPLORE
	if int(t) != team:
		return HUNT
	return GUARD if is_building(target) else ESCORT


## Local target rules of 6.1 / 6.2 (used only when the board has no `can_place`).
func _valid_target(kind: int, target: Node3D, pos: Vector3) -> bool:
	match kind:
		EXPLORE:
			return MapInfo.contains(pos)   # MT1: the running map's size
		HUNT:
			if target == null or not is_instance_valid(target) or not target.is_inside_tree():
				return false
			if target.has_method(&"is_alive") and not bool(target.call(&"is_alive")):
				return false
			var fog := FogOfWar.find()
			if fog == null or not fog.enabled:
				return target.is_visible_in_tree() or is_building(target)
			if is_building(target):
				return fog.is_explored(team, target.global_position)
			return fog.is_visible(team, target.global_position)
		GUARD:
			if target == null or int(target.get("team")) != team:
				return false
			if target.has_method(&"is_constructed") and not bool(target.call(&"is_constructed")):
				return false
			return not target.has_method(&"is_alive") or bool(target.call(&"is_alive"))
		ESCORT:
			if target == null or int(target.get("team")) != team or target.is_in_group(&"champions"):
				return false
			return not target.has_method(&"is_alive") or bool(target.call(&"is_alive"))
	return false


func _message(text: String) -> void:
	if selection != null:
		selection.message.emit(text)


## Chip text + the ring under the target.
func _show_preview() -> void:
	if chip == null:
		return
	_style_labels()
	if selection == null:
		return
	if preview.is_empty() or not active:
		selection.hide_bounty_ring()
		return
	var refused := str(preview.get("reason", "")) != ""
	var col := Color(UIStyle.WARN, 0.6) if refused else RING_COLOR
	var t: Variant = preview.get("target")
	var pos: Vector3 = preview.get("pos", Vector3.ZERO)
	var radius := 1.0
	if is_instance_valid(t) and t is Node3D:
		pos = (t as Node3D).global_position
		if (t as Node).has_method(&"target_radius"):
			radius = float((t as Node).call(&"target_radius")) + 0.3
		elif (t as Node).get("radius") != null:
			radius = float((t as Node).get("radius")) + 0.3
		else:
			radius = 0.8
	selection.show_bounty_ring(pos, radius, col)


## The chip's three labels: prefix (`Raise +25 · `), kind word (kind colour), rest (price in `text`, or the reason
## in WARN). Gold while the success flash plays.
func _style_labels() -> void:
	if chip_labels.size() < 3:
		return
	var parts := chip_parts(preview)
	var text_col := UIStyle.token(&"text")
	for i in 3:
		chip_labels[i].text = parts[i]
	var refused := str(preview.get("reason", "")) != ""
	chip_labels[0].add_theme_color_override("font_color", text_col)
	chip_labels[1].add_theme_color_override("font_color", kind_color(int(preview.get("kind", -1))) \
			if parts[1] != "Raise" else text_col)
	chip_labels[2].add_theme_color_override("font_color", UIStyle.WARN if refused else text_col)
	if _flash_left > 0.0:
		for l in chip_labels:
			l.add_theme_color_override("font_color", UIStyle.GOLD)
	if glyph:
		glyph.queue_redraw()


## [prefix, kind word, rest] of the chip for a preview (tests join them: `chip_text()`).
static func chip_parts(d: Dictionary) -> Array[String]:
	if d.is_empty():
		return ["", "", ""]
	var kind := int(d.get("kind", -1))
	var reason := str(d.get("reason", ""))
	var word := kind_name(kind if kind >= 0 else EXPLORE)
	if d.get("raise") != null:
		if reason != "":
			return ["", "Raise", " · " + reason]
		var stake := int(d.get("stake", 0))
		var amount := int(d.get("amount", RAISE_STEP))
		return ["Raise +%d · " % amount, word, " %d -> %d" % [stake, mini(stake + amount, MAX_STAKE)]]
	if reason != "":
		return ["", word, " · " + reason]
	return ["", word, " · %d essence" % int(d.get("amount", 0))]


## The chip's whole line (`Hunt · 75 essence`), for tests.
func chip_text() -> String:
	return "".join(chip_parts(preview))


func _place_chip() -> void:
	if chip == null or not chip.visible:
		return
	chip.reset_size()
	var screen := get_viewport_rect().size
	var w := chip.size.x
	var p := _mouse + CHIP_OFFSET
	if p.x + w > screen.x - SCREEN_MARGIN:
		p.x = _mouse.x - w - 6.0
	p.x = clampf(p.x, SCREEN_MARGIN, maxf(SCREEN_MARGIN, screen.x - w - SCREEN_MARGIN))
	p.y = clampf(p.y, SCREEN_MARGIN, maxf(SCREEN_MARGIN, screen.y - chip.size.y - SCREEN_MARGIN))
	if _shake_left > 0.0:
		p.x += SHAKE_PX * sin((SHAKE_TIME - _shake_left) / SHAKE_TIME * TAU * 3.0)
	chip.position = p


func _chip_style() -> StyleBoxFlat:
	var s := UIStyle.slate_style(4.0, UIStyle.token(&"frame_metal"))
	var bg := UIStyle.token(&"slate_bg")
	s.bg_color = Color(bg.r, bg.g, bg.b, 0.94)
	s.content_margin_left = 6
	s.content_margin_right = 6
	s.content_margin_top = 4
	s.content_margin_bottom = 4
	s.set_corner_radius_all(2)
	return s


func _draw_glyph() -> void:
	var kind := int(preview.get("kind", -1))
	if preview.get("raise") != null:
		kind = -1
	draw_flag_glyph(glyph, Vector2.ZERO, 1.0, kind, Unit.team_color(team))
