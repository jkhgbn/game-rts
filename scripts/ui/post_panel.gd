class_name PostPanel
extends Control
## The trading post / Magpie Den / Greywater Lodge panel (step 10, task 10.C8; spec: market-trade.md 5.5 + 8, layout:
## docs/design/ui-trade.md 9). 676 x 204 at (588, 670), anchored to the bottom like the flag card, painting an opaque
## `panel_bg` over the selection area. Visible only while `selection.selected_neutral` (10.C7: set by a click on a post
## or a guild house) is a valid node; refreshes at 4 Hz.
## - Trading post: status (`Open` / `Opens at 4:00 · in 1:12`), value for the player (`For you: near · 28 gold per trip
##   from your Bazaar` or `Build a Bazaar to trade`), holder, traffic, hint, and the `Set as route` / `Current route`
##   button (only with an own Bazaar; calls `market.set_route(post)`).
## - Magpie Den: read-only text + the visible Magpie count.
## - Greywater Lodge: its lines + `Contracts  [U]` (opens the trade window on the Lodge tab).
## Everything step-10 (TradePost, GuildHouse, Market, TradeNetwork, HuntersGuild) is reached untyped. The selection
## side (`selected_neutral`, `neutral_building_clicked`) is 10.C7's: read with get() / has_signal(), so the panel
## simply stays hidden while it does not exist.

const RECT := Rect2(588, 670, 676, 204)
const BOTTOM := 900.0
const REFRESH := 0.25
const TILE := 96.0
const X_TEXT := 108.0            ## 696 - 588
const Y_LINES: Array[float] = [30.0, 52.0, 76.0, 100.0]   ## y 700 / 722 / 746 / 770 on screen.
const Y_HINT := 136.0            ## y 806
const BUTTON_RECT := Rect2(516, 4, 150, 32)   ## (1104, 674) on screen.
const GROUP := &"post_panel"
const PLAYER_TEAM := 0
const ENEMY_TEAM := 1
const POST_HINT := "Right-click with your Bazaar selected to set the route · G with caravans: trade here"
const DEN_TEXT := "Thieves who rob caravans and remote workers. They answer to no one."
const DEN_TIMES := "On the roads from 5:00 · raid remote mines from 8:00"
const DEN_REWARD := "Killing a Magpie pays 10 gold (Greywater Lodge)"
const LODGE_TEXT := "Sells Outriders and Sweep contracts for gold · pays 10 gold per Magpie slain"
const LODGE_NOTE := "Trackers act on their own and leave when the contract ends"
const POSTS_OPEN_TIME := 240.0

var selection: Node
var hud: Node
## Read only (tests): the node shown and its kind (&"post", &"den", &"lodge", &"" = hidden).
var shown: Node3D
var kind: StringName = &""
var title_label: Label
var title_suffix: Label
var lines: Array[HBoxContainer] = []       ## The 4 text lines (coloured segments).
var hint_label: Label
var action_button: Button                  ## `Set as route` / `Current route` / `Contracts  [U]`.

var _tile: Control
var _tile_icon: Texture2D = null
var _tile_abbr := ""
var _refresh_left := 0.0


## Adds the panel under `hud` once (a second call returns the same panel).
static func attach(p_hud: Node, p_selection: Node = null) -> PostPanel:
	var tree := Engine.get_main_loop() as SceneTree
	var panel: PostPanel = null
	if tree != null:
		for n in tree.get_nodes_in_group(GROUP):
			if n is PostPanel and not n.is_queued_for_deletion():
				panel = n
				break
	if panel == null:
		panel = PostPanel.new()
		panel.name = "PostPanel"
		panel.hud = p_hud
		if p_hud != null:
			p_hud.add_child(panel)
	if p_selection != null:
		panel.setup(p_selection)
	return panel


func _init() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	theme = UIStyle.hud_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP   # clicks on the panel don't reach the battlefield
	set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	offset_left = RECT.position.x
	offset_right = RECT.end.x
	offset_top = -(BOTTOM - RECT.position.y)          # -230
	offset_bottom = -(BOTTOM - RECT.end.y)            # -26
	visible = false
	_tile = Control.new()
	_tile.size = Vector2(TILE, TILE)
	_tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tile.draw.connect(_draw_tile)
	add_child(_tile)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 0)
	title_row.position = Vector2(X_TEXT, 0)
	title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_row)
	title_label = UIStyle.display_label("", 20)
	title_row.add_child(title_label)
	title_suffix = UIStyle.panel_label("", 14)
	title_suffix.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_row.add_child(title_suffix)
	for y in Y_LINES:
		var box := HBoxContainer.new()
		box.add_theme_constant_override("separation", 0)
		box.position = Vector2(X_TEXT, y)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(box)
		lines.append(box)
	hint_label = UIStyle.panel_label("", 12)
	hint_label.position = Vector2(X_TEXT, Y_HINT)
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint_label)
	action_button = TradeWindow.TipButton.new()
	action_button.position = BUTTON_RECT.position
	action_button.size = BUTTON_RECT.size
	action_button.custom_minimum_size = BUTTON_RECT.size
	action_button.focus_mode = Control.FOCUS_NONE
	action_button.add_theme_font_size_override("font_size", 14)
	action_button.pressed.connect(press_action)
	add_child(action_button)
	apply_skin()


func setup(p_selection: Node) -> void:
	selection = p_selection
	if selection == null:
		return
	for sig: StringName in [&"selection_changed", &"neutral_building_clicked"]:
		if selection.has_signal(sig) and not selection.is_connected(sig, _on_selection_signal):
			selection.connect(sig, _on_selection_signal)
	refresh()


func _on_selection_signal(_a: Variant = null) -> void:
	refresh()


func apply_skin() -> void:
	if title_label == null:
		return
	title_label.add_theme_color_override("font_color", UIStyle.token(&"title"))
	title_suffix.add_theme_color_override("font_color", UIStyle.token(&"text"))
	hint_label.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
	TavernWindow.style_primary(action_button)
	action_button.size = BUTTON_RECT.size
	queue_redraw()
	_tile.queue_redraw()


func _process(delta: float) -> void:
	if not visible and _selected() == null:
		return
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		refresh()


func _draw() -> void:
	var bg := UIStyle.token(&"panel_bg")
	draw_rect(Rect2(Vector2.ZERO, size), Color(bg.r, bg.g, bg.b, 1.0))


## The selection's post / guild house (10.C7's `selected_neutral`), or null.
func _selected() -> Node3D:
	if selection == null or not is_instance_valid(selection):
		return null
	var n: Variant = selection.get(&"selected_neutral")
	if n == null or not is_instance_valid(n) or not (n is Node3D):
		return null
	var node := n as Node3D
	if not node.is_inside_tree() or node.is_queued_for_deletion():
		return null
	return node


## &"post", &"den", &"lodge" or &"" for any other node.
static func kind_of(n: Node) -> StringName:
	if n == null or not is_instance_valid(n):
		return &""
	if n.is_in_group(&"trade_posts"):
		return &"post"
	if n.is_in_group(&"guilds"):
		var k := StringName(str(n.get(&"kind")))
		if k == &"den" or k == &"lodge":
			return k
	return &""


## Rebuilds the panel from the selected post / guild house (hidden when none).
func refresh() -> void:
	_refresh_left = REFRESH
	var n := _selected()
	var k := kind_of(n)
	visible = k != &""
	if n != shown:
		shown = n
		_tile_icon = null
		_tile_abbr = ""
		if n != null:
			_pick_tile(n, k)
	kind = k
	if k == &"":
		return
	match k:
		&"post":
			_refresh_post(n)
		&"den":
			_refresh_den()
		&"lodge":
			_refresh_lodge()
	_tile.queue_redraw()


## The shown lines as plain text (title first, then the 4 lines and the hint), for tests.
func panel_text() -> String:
	var out: PackedStringArray = [title_label.text + title_suffix.text]
	for box in lines:
		out.append(line_text(box))
	out.append(hint_label.text)
	return "\n".join(out)


static func line_text(box: HBoxContainer) -> String:
	var s := ""
	for c in box.get_children():
		if c is Label and (c as Label).visible:
			s += (c as Label).text
	return s


## The colour of the first segment of line `i` containing `text` (tests), or transparent.
func segment_color(i: int, text: String) -> Color:
	if i < 0 or i >= lines.size():
		return Color(0, 0, 0, 0)
	for c in lines[i].get_children():
		if c is Label and (c as Label).visible and (c as Label).text.contains(text):
			return (c as Label).get_theme_color(&"font_color")
	return Color(0, 0, 0, 0)


## Sets line `i` from [text, colour, font size] segments (labels are reused).
func _set_line(i: int, segments: Array) -> void:
	var box := lines[i]
	var have := box.get_child_count()
	for j in maxi(have, segments.size()):
		if j >= segments.size():
			(box.get_child(j) as Label).visible = false
			continue
		var seg: Array = segments[j]
		var l: Label
		if j < have:
			l = box.get_child(j) as Label
		else:
			l = UIStyle.panel_label("", 14)
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			box.add_child(l)
		l.visible = true
		l.text = str(seg[0])
		l.add_theme_color_override("font_color", seg[1])
		l.add_theme_font_size_override("font_size", int(seg[2]) if seg.size() > 2 else 14)


# ---------------------------------------------------------------- trading post

func _refresh_post(post: Node3D) -> void:
	var text := UIStyle.token(&"text")
	var muted := UIStyle.token(&"text_muted")
	title_label.text = str(post.get(&"display_name")) if post.get(&"display_name") != null else "Trading post"
	title_suffix.text = " · trading post"
	var net := TradeWindow.trade_network_of(get_tree())
	var market := TradeWindow.market_of(get_tree(), PLAYER_TEAM)
	# Status.
	var open := bool(post.call(&"is_open")) if post.has_method(&"is_open") else true
	if open:
		_set_line(0, [["Open", TradeWindow.NEAR]])
	else:
		var left := float(net.call(&"time_until_open")) if net != null and net.has_method(&"time_until_open") \
				else POSTS_OPEN_TIME
		_set_line(0, [["Opens at 4:00 · in %s" % TradeWindow.mmss(left), UIStyle.WARN]])
	# Value for the player.
	if market == null:
		_set_line(1, [["Build a Bazaar to trade", muted]])
	else:
		var far := is_far(net, market, post)
		_set_line(1, [["For you: ", text], ["far" if far else "near", TradeWindow.FAR if far else TradeWindow.NEAR],
				[" · ", text], ["%d gold" % route_value(net, market, post), TradeWindow.GOLD_TEXT],
				[" per trip from your Bazaar", text]])
	# Holder.
	var holder := int(post.call(&"holder_team")) if post.has_method(&"holder_team") else -1
	if holder == ENEMY_TEAM:
		_set_line(2, [["Held by the enemy · your caravans wait", UIStyle.WARN]])
	elif holder == PLAYER_TEAM:
		_set_line(2, [["Held by you", TradeWindow.NEAR]])
	else:
		_set_line(2, [["Not held", muted]])
	# Traffic.
	var trips := int(net.call(&"trips", PLAYER_TEAM, post, 120.0)) if net != null and net.has_method(&"trips") else 0
	_set_line(3, [["Your trips here, last 2 min: %d · caravans on this route: %d" % [trips, caravans_on(post)],
			muted, 13]])
	hint_label.text = POST_HINT
	# Button: only with an own Bazaar.
	action_button.visible = market != null
	if market != null:
		var current: Variant = market.get(&"route_post")
		var is_current: bool = current == post
		var why := ""
		if net != null and net.has_method(&"route_reason"):
			why = str(net.call(&"route_reason", market, post))
		if why != "Route too short":
			why = ""   # only a permanent refusal disables the button (closed / held posts can still be chosen)
		action_button.text = "Current route" if is_current else "Set as route"
		action_button.disabled = is_current or why != ""
		action_button.modulate.a = 0.45 if action_button.disabled else 1.0
		action_button.tooltip_text = "Set as route\nYour caravans trade here from now on.%s" % [
				"\n" + why if why != "" else ""]


## Gold per trip from `market` to `post` (TradeNetwork.route_value, else the Bazaar's own route_value_to).
static func route_value(net: Node, market: Node, post: Node) -> int:
	if net != null and net.has_method(&"route_value"):
		return int(net.call(&"route_value", market, post))
	if market != null and market.has_method(&"route_value_to"):
		return int(market.call(&"route_value_to", post))
	return 0


static func is_far(net: Node, market: Node, post: Node) -> bool:
	if net != null and net.has_method(&"is_far"):
		return bool(net.call(&"is_far", PLAYER_TEAM, post))
	if market != null and market.has_method(&"is_far_post"):
		return bool(market.call(&"is_far_post", post))
	return false


## Own living caravans whose route is `post`.
func caravans_on(post: Node) -> int:
	var n := 0
	for c in get_tree().get_nodes_in_group(&"caravans"):
		if not is_instance_valid(c) or c.get(&"team") == null or int(c.get(&"team")) != PLAYER_TEAM:
			continue
		if c.has_method(&"is_alive") and not bool(c.call(&"is_alive")):
			continue
		if c.get(&"route_post") == post:
			n += 1
	return n


# ---------------------------------------------------------------- guild houses

func _refresh_den() -> void:
	title_label.text = "Magpie Den"
	title_suffix.text = " · Thieves' Guild"
	var n := TradeWindow.visible_magpies(get_tree())
	_set_line(0, [[DEN_TEXT, UIStyle.token(&"text"), 13]])
	_set_line(1, [[DEN_TIMES, UIStyle.token(&"text_muted"), 13]])
	_set_line(2, [["Magpies you can see: ", UIStyle.token(&"text")],
			[str(n), TradeWindow.GOLD_TEXT if n > 0 else UIStyle.token(&"text_muted")]])
	_set_line(3, [[DEN_REWARD, UIStyle.token(&"text_muted"), 12]])
	hint_label.text = ""
	action_button.visible = false


func _refresh_lodge() -> void:
	title_label.text = "Greywater Lodge"
	title_suffix.text = " · Hunters' Guild"
	var g := TradeWindow.hunters_guild_of(get_tree())
	_set_line(0, [[LODGE_TEXT, UIStyle.token(&"text"), 13]])
	if g != null and g.has_method(&"is_open") and not bool(g.call(&"is_open")):
		_set_line(1, [["The Lodge opens at 5:00 · in %s" % TradeWindow.mmss(TradeWindow.lodge_time_until_open(g)),
				UIStyle.WARN]])
	else:
		_set_line(1, [["Open", TradeWindow.NEAR]])
	var running: PackedStringArray = []
	for k: StringName in TradeWindow.CONTRACT_KINDS:
		var left := float(g.call(&"contract_time_left", PLAYER_TEAM, k)) if g != null \
				and g.has_method(&"contract_time_left") else 0.0
		if left > 0.0:
			running.append("%s · %s left" % [str((TradeWindow.CONTRACT_INFO[k] as Dictionary)["name"]),
					TradeWindow.mmss(left)])
	if running.is_empty():
		_set_line(2, [["No contract running", UIStyle.token(&"text_muted")]])
	else:
		_set_line(2, [[" · ".join(running), UIStyle.token(&"text")]])
	_set_line(3, [[LODGE_NOTE, UIStyle.token(&"text_muted"), 12]])
	hint_label.text = ""
	action_button.visible = true
	action_button.disabled = false
	action_button.modulate.a = 1.0
	action_button.text = "Contracts  [U]"
	action_button.tooltip_text = "Contracts  [U]\nHire Outriders or a Sweep for gold."


## The button: `Set as route` (post) -> `market.set_route(post)`, a refusal goes to the message line;
## `Contracts  [U]` (Lodge) -> the trade window on the Lodge tab. Returns the refusal ("" = done).
func press_action() -> String:
	if shown == null or not is_instance_valid(shown):
		return "Nothing selected"
	if kind == &"lodge":
		var w: Variant = hud.get(&"trade_window") if hud != null and is_instance_valid(hud) else null
		if is_instance_valid(w) and w is Node and w.has_method(&"open"):
			w.call(&"open", &"lodge")
		return ""
	if kind != &"post":
		return "Not a trading post"
	var market := TradeWindow.market_of(get_tree(), PLAYER_TEAM)
	if market == null or not market.has_method(&"set_route"):
		return "No Bazaar"
	var why := str(market.call(&"set_route", shown))
	if why != "" and hud != null and is_instance_valid(hud) and hud.has_method(&"show_message"):
		hud.call(&"show_message", why)
	refresh()
	return why


# ---------------------------------------------------------------- tile

func _pick_tile(n: Node, k: StringName) -> void:
	match k:
		&"post":
			var pid := StringName(str(n.get(&"post_id")))
			_tile_icon = IconLibrary.icon_for(&"posts", pid) if pid != &"" else null
			var nm := str(n.get(&"display_name")) if n.get(&"display_name") != null else "Trading Post"
			_tile_abbr = UIStyle.abbrev(nm)
		&"den":
			_tile_icon = IconLibrary.icon_for(&"buildings", &"magpie_den")
			_tile_abbr = "MD"
		&"lodge":
			_tile_icon = IconLibrary.icon_for(&"buildings", &"greywater_lodge")
			_tile_abbr = "GL"


## The 96 px tile: slot frame with a neutral `frame_dark` rim, portrait gradient, the icon (88, inset 4) or the
## abbreviation (display font 28); a post's fallback has a signpost glyph behind the letters at alpha 0.25.
func _draw_tile() -> void:
	var r := Rect2(Vector2.ZERO, Vector2(TILE, TILE))
	var inner := UIStyle.token(&"panel_inner")
	var glow := UIStyle.token(&"trim_glow")
	_tile.draw_rect(r, inner)
	for i in 8:
		var k := float(i) / 8.0
		_tile.draw_rect(Rect2(0, TILE * 0.5 * k, TILE, TILE * 0.5 / 8.0 + 1.0), Color(glow.r, glow.g, glow.b,
				0.35 * (1.0 - k)))
	if _tile_icon != null:
		_tile.draw_texture_rect(_tile_icon, r.grow(-4.0), false)
	elif _tile_abbr != "":
		if kind == &"post":
			var pole := UIStyle.token(&"frame_dark")
			_tile.draw_line(Vector2(48, 20), Vector2(48, 80), Color(pole, 0.25), 3.0)
			_tile.draw_rect(Rect2(52, 30, 30, 14), Color(TradeWindow.GOLD_COIN, 0.25))
		var font := UIStyle.display_font()
		var w := font.get_string_size(_tile_abbr, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
		_tile.draw_string(font, Vector2((TILE - w) * 0.5, TILE * 0.5 + 10.0), _tile_abbr, HORIZONTAL_ALIGNMENT_LEFT,
				-1, 28, UIStyle.token(&"title"))
	_tile.draw_rect(r.grow(-1.0), UIStyle.token(&"groove"), false, 1.0)
	_tile.draw_rect(r.grow(-2.5), UIStyle.token(&"frame_dark"), false, 2.0)
