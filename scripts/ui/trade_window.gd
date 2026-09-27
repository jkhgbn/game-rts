class_name TradeWindow
extends PanelContainer
## The trade window (step 10, task 10.C8; spec: docs/design/market-trade.md 3 + 6.2 + 8, layout: docs/design/ui-trade.md 10).
## 760 x 464 at (420, 156) (the tavern's rect: the shop, the tavern and this window never show together), heavy frame.
## Opened with U (physical key), the Bazaar's Wares button (`open(&"bazaar")`) and a Greywater Lodge click
## (`open(&"lodge")`); U, Esc and the stud X close it, and it closes when the match ends (GameHUD.show_banner).
## `open()` refuses (false) when the player's team has no GoldBank: trade is off.
## Title bar: TRADE, the two tabs (BAZAAR, GREYWATER LODGE), gold / crystals / essence, X.
## - Bazaar tab: the 4 one-time wares (GoldBank `can_buy_ware` / `buy_ware`), the exchange (100 gold -> 80 crystals /
##   40 essence, Shift = x5, GoldBank `exchange`), the gold ledger; footer with the own Bazaar or the `No Bazaar` warning.
## - Lodge tab: Outriders and Sweep (HuntersGuild `can_hire` / `hire` / `contract_time_left` / `cooldown_left`) in four
##   states (hireable, refused, running + time bar, cooldown), the Lodge reward line, tips, visible Magpies.
## Every step-10 part (GoldBank, Market, HuntersGuild, TradeNetwork) is reached untyped: groups, has_method, get.
## This file also holds the shared trade looks (GOLD_COIN, GOLD_TEXT, NEAR, FAR, OWNED, draw_coin) and the lookups
## the other 10.C8 files use (gold_bank_of, market_of, hunters_guild_of, trade_network_of).

signal message(text: String)
signal opened
signal closed

# ---------------------------------------------------------------- shared looks (ui-trade.md 16)
const GOLD_COIN := Color(1.0, 0.78, 0.25)
const GOLD_TEXT := Color(1.0, 0.88, 0.5)
const COIN_RING := Color(0.55, 0.42, 0.10)
const COIN_INNER := Color(0.85, 0.62, 0.18)
const COIN_SHINE := Color(1.0, 0.93, 0.65)
const NEAR := Color(0.4, 0.9, 0.4)
const FAR := Color(1.0, 0.55, 0.2)
const OWNED := Color(0.4, 0.95, 0.4)

# ---------------------------------------------------------------- layout (inner coordinates: (430, 166) on screen)
const POS := Vector2(420, 156)
const SIZE := Vector2(760, 464)
const INNER := Vector2(740, 444)
const TAB_A := Rect2(86, 0, 100, 28)
const TAB_B := Rect2(192, 0, 176, 28)
const RES_END_X := 704.0          ## The resources block ends at x 1134 on screen.
const CLOSE_AT := Vector2(716, 2)
const RULE_Y := 32.0
const FOOTER_Y := 422.0
const WARE_Y := 38.0              ## y 204 on screen; rows every 70 px.
const WARE_STEP := 70.0
const WARE_SIZE := Vector2(740, 64)
const EXCHANGE_Y := 320.0         ## y 486 on screen.
const EXCHANGE_BUTTON := Vector2(220, 36)
const CONTRACT_Y := 62.0          ## y 228 on screen; rows every 96 px.
const CONTRACT_STEP := 96.0
const CONTRACT_SIZE := Vector2(740, 90)
const BUTTON := Vector2(104, 24)
const REFRESH_TIME := 0.25
const FLASH_TIME := 0.4
const ROW_FLASH := 0.3
const POP_TIME := 0.2

const PLAYER_TEAM := 0
const BAZAAR := &"bazaar"
const LODGE := &"lodge"
const EXCHANGE_STEP := 100
const EXCHANGE_RATES := {&"crystals": 80, &"essence": 40}
const WARE_IDS: Array[StringName] = [&"iron_axles", &"masons_charter", &"tempered_steel", &"gambesons"]
const WARE_INFO := {
	&"iron_axles": {"name": "Iron-shod Axles", "abbr": "IA", "price": 150,
			"effect": "Caravans move 0.5 m/s faster and gain 60 HP",
			"who": "Applies to caravans alive now and built later"},
	&"masons_charter": {"name": "Masons' Charter", "abbr": "MC", "price": 350,
			"effect": "Every building of yours gets +15 % max HP, now and later",
			"who": "Existing, under construction and future buildings; the gain is healed"},
	&"tempered_steel": {"name": "Tempered Steel", "abbr": "TS", "price": 350,
			"effect": "Your soldiers deal +8 % damage",
			"who": "Soldiers only: not workers, caravans, wizards, champions or hunters"},
	&"gambesons": {"name": "Quilted Gambesons", "abbr": "QG", "price": 350,
			"effect": "Your soldiers take 9 % less damage (+10 armor)",
			"who": "Soldiers only: not workers, caravans, wizards, champions or hunters"},
}
const CONTRACT_KINDS: Array[StringName] = [&"outriders", &"sweep"]
const CONTRACT_INFO := {
	&"outriders": {"name": "Outriders", "abbr": "OR", "cost": 120, "trackers": 2, "duration": 180.0,
			"desc": "Each tracker shadows one of your caravans and shoots any Magpie that comes near it."},
	&"sweep": {"name": "Sweep", "abbr": "SW", "cost": 100, "trackers": 3, "duration": 120.0,
			"desc": "Three trackers walk your mines and roads in turn, attack every Magpie they find and chase looters."},
}
const LODGE_OPEN_TIME := 300.0
const REWARD_PER_MAGPIE := 10
const NO_BAZAAR := "No Bazaar"
const NO_GOLD := "Not enough gold"
const NO_LODGE := "No Greywater Lodge"
const LODGE_HEADER := "Greywater Lodge (Hunters' Guild) · contracts paid in gold · open from 5:00"
const TIPS: Array[String] = [
	"Bands lurk on the roads from 5:00 and raid remote mines from 8:00.",
	"Bands skip spots within 20 m of your towers. Soldiers, Hunt flags and hunters kill them.",
	"A dead Magpie drops its loot. Walk any unit over a sack to take it.",
]

var hud: Node = null
var team := PLAYER_TEAM
## Read only (tests): the parts.
var title_label: Label
var tab_buttons: Array[Button] = []          ## [Bazaar, Greywater Lodge].
var gold_label: Label
var crystals_label: Label
var essence_label: Label
var ware_rows: Array[WareRow] = []
var exchange_buttons: Array[Button] = []     ## [-> crystals, -> essence].
var exchange_title: Label
var exchange_hint: Label
var ledger_labels: Array[Label] = []         ## `Gold earned`, sources, `Gold traded, last 3 min`.
var contract_rows: Array[ContractRow] = []
var lodge_header: Label
var reward_label: Label                      ## `The Lodge pays 10 gold for every Magpie slain`.
var rewards_received_label: Label            ## `Rewards received: 50 gold` (right-aligned).
var tip_labels: Array[Label] = []
var footer_left: Label
var footer_right: Label
var last_result := ""                        ## The last buy / exchange / hire answer ("" = done).

var _tab: StringName = BAZAAR
var _inner: Control
var _bazaar_page: Control
var _lodge_page: Control
var _rule: ColorRect
var _exchange_rule: Control
var _close_button: Button
var _refresh_left := 0.0
var _skin := -1
var _bank: Object = null
var _gold_flash_left := 0.0
var _last_gold := -1
var _pops := {}                              ## Label -> seconds left of its pop.
var _button_flash := {}                      ## Button -> seconds left of its WARN rim.
var _shift := false


## Builds the window under the HUD (hidden until `open()`); messages go to `hud.show_message`.
static func attach(p_hud: Node) -> TradeWindow:
	var w := TradeWindow.new()
	w.name = "TradeWindow"
	w.hud = p_hud
	p_hud.add_child(w)
	if p_hud.has_method(&"show_message"):
		w.message.connect(func(t: String) -> void: p_hud.call(&"show_message", t))
	return w


func _ready() -> void:
	position = POS
	size = SIZE
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	UIStyle.add_drop_shadow(self)
	_inner = Control.new()
	_inner.custom_minimum_size = INNER
	_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_inner)
	_build_title_bar()
	_bazaar_page = _page()
	_lodge_page = _page()
	_build_bazaar()
	_build_lodge()
	footer_left = _label(_inner, "", 12, Vector2(0, FOOTER_Y), 520)
	footer_right = _label(_inner, "", 12, Vector2(520, FOOTER_Y), 220)
	footer_right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	apply_skin()
	_show_tab(BAZAAR)


func _page() -> Control:
	var p := Control.new()
	p.size = INNER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inner.add_child(p)
	return p


func _build_title_bar() -> void:
	title_label = UIStyle.display_label("Trade", 20)
	title_label.position = Vector2.ZERO
	title_label.size = Vector2(80, 28)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_inner.add_child(title_label)
	for spec: Array in [[TAB_A, "Bazaar", BAZAAR, "Bazaar: wares and the gold exchange"],
			[TAB_B, "Greywater Lodge", LODGE, "Hunters' Guild: contracts paid in gold"]]:
		var b := TabButton.new()
		var r: Rect2 = spec[0]
		b.text = str(spec[1]).to_upper()
		b.tab_id = spec[2]
		b.tooltip_text = str(spec[3])
		b.position = r.position
		b.size = r.size
		b.custom_minimum_size = r.size
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_override("font", UIStyle.display_font())
		b.add_theme_font_size_override("font_size", 14)
		b.pressed.connect(_show_tab.bind(b.tab_id))
		_inner.add_child(b)
		tab_buttons.append(b)
	# Resources: coin + gold, crystal + crystals, flame + essence, right-aligned ending at x 1134, y 170.
	var money := HBoxContainer.new()
	money.alignment = BoxContainer.ALIGNMENT_END
	money.add_theme_constant_override("separation", 0)
	money.position = Vector2(RES_END_X - 330.0, 4)
	money.size = Vector2(330, 20)
	money.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inner.add_child(money)
	money.add_child(coin_control(16.0))
	money.add_child(_spacer(6))
	gold_label = UIStyle.number_label("0", 16, GOLD_TEXT)
	gold_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	money.add_child(gold_label)
	money.add_child(_spacer(12))
	money.add_child(_icon(16.0, true))
	money.add_child(_spacer(6))
	crystals_label = UIStyle.number_label("0", 16, UIStyle.CRYSTAL_TEXT)
	crystals_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	money.add_child(crystals_label)
	money.add_child(_spacer(12))
	money.add_child(_icon(16.0, false))
	money.add_child(_spacer(6))
	essence_label = UIStyle.number_label("0", 16, UIStyle.ESSENCE_TEXT)
	essence_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	money.add_child(essence_label)
	_close_button = Button.new()
	_close_button.text = "x"
	_close_button.tooltip_text = "Close  [U]"
	_close_button.position = CLOSE_AT
	_close_button.size = Vector2(24, 24)
	_close_button.custom_minimum_size = Vector2(24, 24)
	_close_button.focus_mode = Control.FOCUS_NONE
	_close_button.add_theme_font_size_override("font_size", 13)
	_close_button.pressed.connect(close)
	_inner.add_child(_close_button)
	_rule = ColorRect.new()
	_rule.position = Vector2(0, RULE_Y)
	_rule.size = Vector2(INNER.x, 1)
	_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inner.add_child(_rule)
	_rule.move_to_front()


func _build_bazaar() -> void:
	for k in WARE_IDS.size():
		var r := WareRow.new()
		r.window = self
		r.index = k
		r.id = WARE_IDS[k]
		r.position = Vector2(0, WARE_Y + WARE_STEP * k)
		_bazaar_page.add_child(r)
		ware_rows.append(r)
	# Exchange block, 740 x 96 at (430, 486).
	exchange_title = UIStyle.display_label("Exchange", 13)
	exchange_title.position = Vector2(8, EXCHANGE_Y + 4)
	exchange_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bazaar_page.add_child(exchange_title)
	_exchange_rule = Control.new()
	_exchange_rule.position = Vector2(90, EXCHANGE_Y + 12)
	_exchange_rule.size = Vector2(380, 1)
	_exchange_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_exchange_rule.draw.connect(func() -> void:
		_exchange_rule.draw_rect(Rect2(0, 0, 380, 1), UIStyle.token(&"frame_dark")))
	_bazaar_page.add_child(_exchange_rule)
	for spec: Array in [[&"crystals", Vector2(8, EXCHANGE_Y + 30)], [&"essence", Vector2(242, EXCHANGE_Y + 30)]]:
		var b := TipButton.new()
		b.position = spec[1]
		b.size = EXCHANGE_BUTTON
		b.custom_minimum_size = EXCHANGE_BUTTON
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 13)
		b.set_meta(&"to", spec[0])
		b.pressed.connect(_on_exchange_pressed.bind(StringName(spec[0])))
		_bazaar_page.add_child(b)
		exchange_buttons.append(b)
	exchange_hint = _label(_bazaar_page, "Shift+click: 500 gold at once · no reverse exchange · needs your Bazaar", 12,
			Vector2(8, EXCHANGE_Y + 72), 470)
	for i in 3:
		ledger_labels.append(_label(_bazaar_page, "", 12, Vector2(490, EXCHANGE_Y + 30 + 18 * i), 250))


func _build_lodge() -> void:
	lodge_header = _label(_lodge_page, LODGE_HEADER, 13, Vector2(8, 40), 724)
	for k in CONTRACT_KINDS.size():
		var r := ContractRow.new()
		r.window = self
		r.kind = CONTRACT_KINDS[k]
		r.position = Vector2(0, CONTRACT_Y + CONTRACT_STEP * k)
		_lodge_page.add_child(r)
		contract_rows.append(r)
	reward_label = _label(_lodge_page, "The Lodge pays %d gold for every Magpie slain" % REWARD_PER_MAGPIE, 12,
			Vector2(8, 260), 420)
	rewards_received_label = _label(_lodge_page, "Rewards received: 0 gold", 12, Vector2(432, 260), 300)
	rewards_received_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for i in TIPS.size():
		tip_labels.append(_label(_lodge_page, TIPS[i], 12, Vector2(8, 286 + 18 * i), 724))


func apply_skin() -> void:
	_skin = UIStyle.skin_version
	theme = UIStyle.hud_theme()   # slate tooltips (the window sits on the HUD layer, outside its root)
	add_theme_stylebox_override("panel", UIStyle.frame_style(10.0))
	title_label.add_theme_color_override("font_color", UIStyle.token(&"title"))
	_rule.color = UIStyle.token(&"frame_light")
	style_stud(_close_button)
	exchange_title.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
	exchange_hint.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
	for l in tip_labels:
		l.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
	reward_label.add_theme_color_override("font_color", UIStyle.token(&"text"))
	rewards_received_label.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
	for b in exchange_buttons:
		TavernWindow.style_primary(b)
	for b in tab_buttons:
		(b as TabButton).restyle()
	_exchange_rule.queue_redraw()
	for r in ware_rows:
		r.apply_skin()
	for r in contract_rows:
		r.apply_skin()
	fix_button_sizes(self)


## Buttons are sized before their styles and fonts apply, so a stale (bigger) default minimum can stick; once
## styled, every button under `root` with a custom_minimum_size gets exactly that size again.
static func fix_button_sizes(root_control: Node) -> void:
	for b in root_control.find_children("*", "Button", true, false):
		var c := b as Control
		if c.custom_minimum_size != Vector2.ZERO:
			c.size = c.custom_minimum_size


## The round stud X (ui-style.md 6.4, as the shop's and the tavern's).
static func style_stud(b: Button) -> void:
	for state in ["normal", "hover", "pressed", "disabled"]:
		var s := StyleBoxFlat.new()
		s.bg_color = UIStyle.token(&"frame_metal").darkened(0.2 if state == "pressed" else 0.0)
		s.border_color = UIStyle.WARN if state == "hover" else UIStyle.token(&"frame_light")
		s.set_border_width_all(2)
		s.set_corner_radius_all(12)
		s.set_content_margin_all(0)
		b.add_theme_stylebox_override(state, s)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", UIStyle.token(&"text"))
	b.add_theme_color_override("font_hover_color", UIStyle.token(&"text"))


## The primary button with a GOLD_COIN rim instead of trim_glow (gold payments: tavern `HIRE · GOLD`).
static func style_gold(b: Button) -> void:
	b.add_theme_stylebox_override("normal", UIStyle.button_frame(&"normal", GOLD_COIN))
	b.add_theme_stylebox_override("hover", UIStyle.button_frame(&"hover", GOLD_COIN.lightened(0.25)))
	b.add_theme_stylebox_override("pressed", UIStyle.button_frame(&"pressed", GOLD_COIN.darkened(0.2)))
	b.add_theme_stylebox_override("hover_pressed", UIStyle.button_frame(&"pressed", GOLD_COIN.darkened(0.2)))
	b.add_theme_stylebox_override("disabled", UIStyle.button_frame(&"disabled"))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", UIStyle.token(&"text"))
	b.add_theme_color_override("font_hover_color", UIStyle.token(&"text"))
	b.add_theme_color_override("font_disabled_color", UIStyle.token(&"text_muted"))


# ---------------------------------------------------------------- shared helpers (other 10.C8 files use them)

## The gold coin glyph (ui-trade.md 16.2): disc GOLD_COIN, a dark ring, an inner ring (dropped under 12 px), a
## highlight arc from 200 to 290 degrees.
static func draw_coin(ci: CanvasItem, centre: Vector2, radius: float) -> void:
	ci.draw_circle(centre, radius, GOLD_COIN)
	ci.draw_arc(centre, radius - 0.5, 0.0, TAU, 24, COIN_RING, 1.0, true)
	if radius >= 6.0:
		ci.draw_arc(centre, radius * 0.62, 0.0, TAU, 20, COIN_INNER, 1.0, true)
	ci.draw_arc(centre, radius * 0.75, deg_to_rad(200.0), deg_to_rad(290.0), 8, COIN_SHINE, 1.5, true)


## A `h` px Control drawing the coin (vertically centred in rows).
static func coin_control(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(h, h)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func() -> void: TradeWindow.draw_coin(c, Vector2(h, h) * 0.5, h * 0.5))
	return c


## `12345` -> `12 345` (the end screen's thousands).
static func thousands(n: int) -> String:
	var digits := str(absi(n))
	var out := ""
	while digits.length() > 3:
		out = " " + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return ("-" if n < 0 else "") + digits + out


## Seconds as `m:ss` (rounded up).
static func mmss(seconds: float) -> String:
	var s := maxi(ceili(maxf(seconds, 0.0)), 0)
	return "%d:%02d" % [s / 60, s % 60]


## The team's GoldBank (group "gold_banks", matched on `team`), or null when trade is off.
static func gold_bank_of(tree: SceneTree, p_team: int) -> Node:
	if tree == null:
		return null
	for b in tree.get_nodes_in_group(&"gold_banks"):
		if is_instance_valid(b) and not b.is_queued_for_deletion() and b.get(&"team") != null \
				and int(b.get(&"team")) == p_team:
			return b
	return null


## The team's completed, living Bazaar (group "markets"; `Market.of_team`), or null.
static func market_of(tree: SceneTree, p_team: int) -> Node3D:
	if tree == null:
		return null
	for m in tree.get_nodes_in_group(&"markets"):
		if not is_instance_valid(m) or m.is_queued_for_deletion() or not (m is Node3D) or m.get(&"team") == null \
				or int(m.get(&"team")) != p_team:
			continue
		if m.has_method(&"is_alive") and not bool(m.call(&"is_alive")):
			continue
		if m.has_method(&"is_constructed") and not bool(m.call(&"is_constructed")):
			continue
		return m as Node3D
	return null


## The match's HuntersGuild (group "hunters_guild"), or null.
static func hunters_guild_of(tree: SceneTree) -> Node:
	return _first(tree, &"hunters_guild")


## The match's TradeNetwork (group "trade_network"), or null.
static func trade_network_of(tree: SceneTree) -> Node:
	return _first(tree, &"trade_network")


static func _first(tree: SceneTree, group: StringName) -> Node:
	if tree == null:
		return null
	for n in tree.get_nodes_in_group(group):
		if is_instance_valid(n) and not n.is_queued_for_deletion():
			return n
	return null


## A Bazaar's name (`Ember Bazaar`) from its BuildingType.
static func building_name(b: Node) -> String:
	if b == null or not is_instance_valid(b):
		return ""
	var t: Variant = b.get(&"building_type")
	if t is Object and (t as Object).get(&"display_name") != null:
		return str((t as Object).get(&"display_name"))
	var n: Variant = b.get(&"display_name")
	return str(n) if n != null else "Bazaar"


## Visible Magpies (group "magpies", alive, `is_visible_in_tree()`: the fog hides the others).
static func visible_magpies(tree: SceneTree) -> int:
	if tree == null:
		return 0
	var n := 0
	for m in tree.get_nodes_in_group(&"magpies"):
		if not is_instance_valid(m) or not (m is Node3D) or not (m as Node3D).is_visible_in_tree():
			continue
		if m.has_method(&"is_alive") and not bool(m.call(&"is_alive")):
			continue
		n += 1
	return n


# ---------------------------------------------------------------- small builders

func _label(parent: Control, text: String, font_size: int, at: Vector2, w: float) -> Label:
	var l := UIStyle.panel_label(text, font_size)
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.position = at
	l.size = Vector2(w, font_size + 5)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _spacer(w: float) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(w, 0)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


func _icon(h: float, crystal: bool) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(h, h)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if crystal:
		c.draw.connect(func() -> void: ChampionBar.draw_crystal(c, Vector2.ZERO, h))
	else:
		c.draw.connect(func() -> void: ChampionBar.draw_flame(c, Vector2(h * 0.1, 0), h))
	return c


# ---------------------------------------------------------------- open / close

## Opens the window on `tab` (&"bazaar" / &"lodge"; empty = the last tab, the Bazaar at first). Closes the shop and
## the tavern. Returns false (and shows nothing) when the player's team has no GoldBank (trade off).
func open(tab: StringName = &"") -> bool:
	if gold_bank() == null:
		return false
	if tab == BAZAAR or tab == LODGE:
		_show_tab(tab)
	for key: StringName in [&"shop_window", &"tavern_window"]:
		var w: Variant = hud.get(key) if hud != null and is_instance_valid(hud) else null
		if is_instance_valid(w) and w is Node and w.has_method(&"is_open") and bool(w.call(&"is_open")):
			w.call(&"close")
	var was_open := visible
	visible = true
	refresh()
	if not was_open:
		opened.emit()
	return true


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


## U: open when closed, close when open.
func toggle() -> void:
	if visible:
		close()
	else:
		open()


func is_open() -> bool:
	return visible


func current_tab() -> StringName:
	return _tab


func _show_tab(tab: StringName) -> void:
	_tab = tab
	_bazaar_page.visible = tab == BAZAAR
	_lodge_page.visible = tab == LODGE
	for b in tab_buttons:
		(b as TabButton).set_active(b.get(&"tab_id") == tab)
	if visible:
		refresh()


## U toggles (physical key, no modifiers); ignored while the game is paused (pause menu, briefing) or a text field
## has the focus.
func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.ctrl_pressed or key.alt_pressed or key.shift_pressed \
			or key.meta_pressed:
		return
	var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	if code != KEY_U or get_tree().paused:
		return
	var focus := get_viewport().gui_get_focus_owner()
	if focus is LineEdit or focus is TextEdit:
		return
	if not visible and gold_bank() == null:
		return   # trade off: U does nothing
	toggle()
	get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo \
			and (event as InputEventKey).physical_keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _skin != UIStyle.skin_version:
		apply_skin()
	_tick_effects(delta)
	if not visible:
		return
	if gold_bank() == null:
		close()
		return
	var shift := Input.is_key_pressed(KEY_SHIFT)
	_refresh_left -= delta
	if _refresh_left <= 0.0 or shift != _shift:
		refresh()


func _tick_effects(delta: float) -> void:
	if _gold_flash_left > 0.0:
		_gold_flash_left -= delta
		if _gold_flash_left <= 0.0:
			gold_label.add_theme_color_override("font_color", GOLD_TEXT)
	for l: Label in _pops.keys():
		var left := float(_pops[l]) - delta
		if left <= 0.0:
			_pops.erase(l)
			l.scale = Vector2.ONE
		else:
			_pops[l] = left
			var s := 1.0 + 0.15 * sin(PI * (1.0 - left / POP_TIME))
			l.scale = Vector2(s, s)
	for b: Button in _button_flash.keys():
		var left := float(_button_flash[b]) - delta
		if left <= 0.0:
			_button_flash.erase(b)
			TavernWindow.style_primary(b)
		else:
			_button_flash[b] = left


# ---------------------------------------------------------------- data (duck-typed)

## The player's GoldBank, or null (trade off).
func gold_bank() -> Node:
	if not is_inside_tree():
		return null
	var b := gold_bank_of(get_tree(), team)
	if b != _bank:
		_bank = b
		if b != null and b.has_signal(&"spend_failed") and not b.is_connected(&"spend_failed", flash_gold):
			b.connect(&"spend_failed", flash_gold)
	return b


## The player's completed Bazaar, or null.
func market() -> Node3D:
	return market_of(get_tree(), team) if is_inside_tree() else null


func hunters_guild() -> Node:
	return hunters_guild_of(get_tree()) if is_inside_tree() else null


func gold() -> int:
	var b := gold_bank()
	return int(b.get(&"gold")) if b != null else 0


## Gold price of a ware (the bank's `ware_price` when it has one, else the spec's).
func ware_price(id: StringName) -> int:
	var b := gold_bank()
	if b != null and b.has_method(&"ware_price"):
		var p := int(b.call(&"ware_price", id))
		if p > 0:
			return p
	return int((WARE_INFO.get(id, {}) as Dictionary).get("price", 0))


func owns_ware(id: StringName) -> bool:
	var b := gold_bank()
	if b == null:
		return false
	if b.has_method(&"owns_ware"):
		return bool(b.call(&"owns_ware", id))
	var owned: Variant = b.get(&"owned_wares")
	return owned is Array and (owned as Array).has(id)


## "" if the ware can be bought, else the bank's reason (`No Bazaar`, `Already owned`, `Not enough gold`).
func ware_reason(id: StringName) -> String:
	var b := gold_bank()
	if b == null:
		return "Trade is off"
	if b.has_method(&"can_buy_ware"):
		return str(b.call(&"can_buy_ware", id))
	if market() == null:
		return NO_BAZAAR
	if owns_ware(id):
		return "Already owned"
	return NO_GOLD if gold() < ware_price(id) else ""


## "" if `amount` gold can be exchanged into `to` now, else the reason (`No Bazaar`, `Not enough gold`).
func exchange_reason(amount: int, to: StringName) -> String:
	var b := gold_bank()
	if b == null:
		return "Trade is off"
	if b.has_method(&"can_exchange"):
		return str(b.call(&"can_exchange", amount, to))
	if market() == null:
		return NO_BAZAAR
	return NO_GOLD if gold() < amount else ""


# ---------------------------------------------------------------- actions

## Ware row `i`'s Buy button: `GoldBank.buy_ware(id)`. "" = bought (the row flashes gold; the message comes from the
## HUD listener on `ware_bought`), else the reason (message line + the row's note).
func press_buy(i: int) -> String:
	var b := gold_bank()
	if b == null or i < 0 or i >= ware_rows.size() or not b.has_method(&"buy_ware"):
		return "Trade is off"
	last_result = str(b.call(&"buy_ware", WARE_IDS[i]))
	if last_result == "":
		ware_rows[i].flash(UIStyle.GOLD, ROW_FLASH)
		_pop(gold_label)
	else:
		message.emit(last_result)
	refresh()
	if last_result != "":
		ware_rows[i].show_refusal(last_result)
	return last_result


## An exchange button: `times` x 100 gold into `to` (&"crystals" / &"essence"). "" = done (message `Exchanged 100 gold
## for 80 crystals`, the target number pops), else the reason (message + a WARN flash of the button's rim).
func press_exchange(to: StringName, times := 1) -> String:
	var b := gold_bank()
	var amount := EXCHANGE_STEP * maxi(times, 1)
	if b == null or not b.has_method(&"exchange"):
		return "Trade is off"
	last_result = str(b.call(&"exchange", amount, to))
	var button := exchange_buttons[0] if to == &"crystals" else exchange_buttons[1]
	if last_result == "":
		var received := amount / EXCHANGE_STEP * int(EXCHANGE_RATES.get(to, 0))
		message.emit("Exchanged %d gold for %d %s" % [amount, received, String(to)])
		_pop(crystals_label if to == &"crystals" else essence_label)
	else:
		message.emit(last_result)
		_flash_button(button)
	refresh()
	return last_result


## A contract row's Hire button: `HuntersGuild.hire(0, kind)`. "" = hired (the row flashes gold; the guild sends
## the message, the listener plays the horn), else the reason (message line + the row's reason).
func press_hire(kind: StringName) -> String:
	var g := hunters_guild()
	var row: ContractRow = null
	for r in contract_rows:
		if r.kind == kind:
			row = r
	if g == null or row == null or not g.has_method(&"hire"):
		return NO_LODGE
	last_result = str(g.call(&"hire", team, kind))
	if last_result == "":
		row.flash(UIStyle.GOLD, ROW_FLASH)
		_pop(gold_label)
	else:
		message.emit(last_result)
	refresh()
	if last_result != "":
		row.show_refusal(last_result)
	return last_result


func _on_exchange_pressed(to: StringName) -> void:
	press_exchange(to, 5 if Input.is_key_pressed(KEY_SHIFT) else 1)


## Failed gold spend: the title-bar gold number turns WARN for 0.4 s.
func flash_gold() -> void:
	_gold_flash_left = FLASH_TIME
	gold_label.add_theme_color_override("font_color", UIStyle.WARN)


func is_gold_flashing() -> bool:
	return _gold_flash_left > 0.0


func _pop(l: Label) -> void:
	l.pivot_offset = l.size * 0.5
	_pops[l] = POP_TIME


func _flash_button(b: Button) -> void:
	_button_flash[b] = ROW_FLASH
	for state in ["normal", "hover", "disabled"]:
		b.add_theme_stylebox_override(state, UIStyle.button_frame(&"normal", UIStyle.WARN))


# ---------------------------------------------------------------- refresh

## Updates the title bar and the shown tab (4 Hz by itself while open; tests may call it).
func refresh() -> void:
	_refresh_left = REFRESH_TIME
	_shift = Input.is_key_pressed(KEY_SHIFT)
	var b := gold_bank()
	var g := gold()
	gold_label.text = thousands(g)
	if _last_gold >= 0 and g >= _last_gold + 10:
		_pop(gold_label)
	_last_gold = g
	var eco := Economy.for_team(team) if is_inside_tree() else null
	var c := int(eco.crystals) if eco != null else 0
	crystals_label.text = thousands(c)
	var ebank := TopBar.find_essence_bank(get_tree(), team) if is_inside_tree() else null
	var e := int(ebank.get(&"essence")) if ebank != null else 0
	essence_label.text = thousands(e)
	if b == null:
		return
	if _tab == BAZAAR:
		_refresh_bazaar(b)
	else:
		_refresh_lodge(b)


func _refresh_bazaar(b: Node) -> void:
	var m := market()
	for r in ware_rows:
		r.refresh()
	var times := 5 if _shift else 1
	var amount := EXCHANGE_STEP * times
	for button in exchange_buttons:
		var to: StringName = button.get_meta(&"to")
		var received := times * int(EXCHANGE_RATES[to])
		button.text = "%d gold  ->  %d %s" % [amount, received, String(to)]
		var why := exchange_reason(amount, to)
		button.disabled = why != ""
		button.modulate.a = 0.45 if why != "" else 1.0
		button.tooltip_text = "Exchange\n100 gold -> %d %s · Shift: x5%s" % [int(EXCHANGE_RATES[to]), String(to),
				"\n" + why if why != "" else ""]
	var earned := _earned(b, &"")
	ledger_labels[0].text = "Gold earned %s" % thousands(earned)
	ledger_labels[1].text = "trade %s · loot %s · rewards %s" % [thousands(_earned(b, &"trade")),
			thousands(_earned(b, &"loot")), thousands(_earned(b, &"reward"))]
	var net := trade_network_of(get_tree())
	var income := int(net.call(&"trade_income", team, 180.0)) if net != null and net.has_method(&"trade_income") else 0
	ledger_labels[2].text = "Gold traded, last 3 min: %s" % thousands(income)
	ledger_labels[0].add_theme_color_override("font_color", UIStyle.token(&"text"))
	ledger_labels[1].add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
	ledger_labels[2].add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
	if m == null:
		footer_left.text = "Build a Bazaar to buy wares and exchange gold"
		footer_left.add_theme_color_override("font_color", UIStyle.WARN)
		footer_right.text = NO_BAZAAR
		footer_right.add_theme_color_override("font_color", UIStyle.WARN)
	else:
		footer_left.text = "Wares are bought once and apply to units made later too"
		footer_left.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
		footer_right.text = "Bazaar: %s" % building_name(m)
		footer_right.add_theme_color_override("font_color", UIStyle.token(&"text"))


func _refresh_lodge(b: Node) -> void:
	var g := hunters_guild()
	if g == null:
		lodge_header.text = "The Greywater Lodges are not here"
		lodge_header.add_theme_color_override("font_color", UIStyle.WARN)
	elif g.has_method(&"is_open") and not bool(g.call(&"is_open")):
		lodge_header.text = "The Lodge opens at 5:00 · in %s" % mmss(lodge_time_until_open(g))
		lodge_header.add_theme_color_override("font_color", UIStyle.WARN)
	else:
		lodge_header.text = LODGE_HEADER
		lodge_header.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
	for r in contract_rows:
		r.refresh(g)
	rewards_received_label.text = "Rewards received: %s gold" % thousands(_earned(b, &"reward"))
	footer_left.text = "Trackers act on their own for the contract's time, then leave"
	footer_left.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
	var n := visible_magpies(get_tree())
	footer_right.text = "Magpies you can see: %d" % n
	footer_right.add_theme_color_override("font_color", UIStyle.token(&"text"))


## Seconds until the Lodges open (the guild's `time_until_open`, else its match time against 5:00).
static func lodge_time_until_open(g: Node) -> float:
	if g == null:
		return 0.0
	if g.has_method(&"time_until_open"):
		return float(g.call(&"time_until_open"))
	if g.has_method(&"match_time"):
		return maxf(0.0, LODGE_OPEN_TIME - float(g.call(&"match_time")))
	return 0.0


static func _earned(b: Node, source: StringName) -> int:
	if b == null or not b.has_method(&"earned"):
		return 0
	return int(b.call(&"earned", source))


# ---------------------------------------------------------------- tabs, buttons

## A tab (ui-trade.md 10.1): slot look with the two top corners chamfered 6 px; active = GOLD rim + a 2 px gold line
## along the bottom edge, text `title`; inactive = frame_metal rim, text `text_muted`, hover frame_light.
class TabButton extends Button:
	var tab_id: StringName = &""
	var active := false

	func _ready() -> void:
		draw.connect(func() -> void:
			if active:
				draw_rect(Rect2(0, size.y - 2.0, size.x, 2.0), UIStyle.GOLD))

	func set_active(v: bool) -> void:
		active = v
		restyle()

	func restyle() -> void:
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			var s := StyleBoxFlat.new()
			var inner := UIStyle.token(&"panel_inner")
			s.bg_color = inner.lightened(0.08) if state == "hover" else inner
			var rim := UIStyle.GOLD if active else (UIStyle.token(&"frame_light") if state == "hover"
					else UIStyle.token(&"frame_metal"))
			s.border_color = rim
			s.set_border_width_all(2)
			s.border_width_bottom = 0
			s.corner_radius_top_left = 6
			s.corner_radius_top_right = 6
			s.corner_detail = 1   # 45 degree chamfers
			s.set_content_margin_all(0)   # the 14 px display font fills the 28 px tab by itself
			add_theme_stylebox_override(state, s)
			add_theme_stylebox_override(state + "_mirrored", s)   # the button's min size counts these too
		add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var col := UIStyle.token(&"title") if active else UIStyle.token(&"text_muted")
		add_theme_color_override("font_color", col)
		add_theme_color_override("font_hover_color", UIStyle.token(&"title"))
		add_theme_color_override("font_pressed_color", col)
		queue_redraw()


## A button whose tooltip uses the styled slate (ui-style.md 8).
class TipButton extends Button:
	func _make_custom_tooltip(for_text: String) -> Object:
		return UIStyle.make_tooltip(for_text)


## The row background shared by both tabs: panel_inner alpha 0.55 (hover 0.8), radius 3; a rim colour; a flash tints
## the rim and the fill for a moment.
class TradeRow extends Panel:
	var window: TradeWindow
	var rim := Color(0, 0, 0, 0)
	var _hovered := false
	var _flash_color := Color(0, 0, 0, 0)
	var _flash_left := 0.0
	var _flash_total := 0.0

	func _init_row(row_size: Vector2) -> void:
		size = row_size
		custom_minimum_size = row_size
		mouse_filter = Control.MOUSE_FILTER_PASS
		mouse_entered.connect(func() -> void:
			_hovered = true
			_style())
		mouse_exited.connect(func() -> void:
			_hovered = false
			_style())

	func _style() -> void:
		var s := StyleBoxFlat.new()
		var inner := UIStyle.token(&"panel_inner")
		s.bg_color = Color(inner.r, inner.g, inner.b, 0.8 if _hovered else 0.55)
		s.set_corner_radius_all(3)
		var r := rim
		if _flash_left > 0.0 and _flash_total > 0.0:
			var k := _flash_left / _flash_total
			r = (r if r.a > 0.0 else Color(_flash_color, 0.0)).lerp(_flash_color, k)
			s.bg_color = s.bg_color.lerp(Color(_flash_color, 0.8), 0.35 * k)
		if r.a > 0.0:
			s.border_color = r
			s.set_border_width_all(1)
		add_theme_stylebox_override("panel", s)

	func flash(color: Color, seconds: float) -> void:
		_flash_color = color
		_flash_left = seconds
		_flash_total = seconds
		_style()

	func is_flashing() -> bool:
		return _flash_left > 0.0

	func _process(delta: float) -> void:
		if _flash_left > 0.0:
			_flash_left = maxf(_flash_left - delta, 0.0)
			_style()

	func _row_label(text: String, font_size: int, at: Vector2, w: float) -> Label:
		var l := UIStyle.panel_label(text, font_size)
		l.clip_text = true
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		l.position = at
		l.size = Vector2(w, font_size + 5)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(l)
		return l

	func _row_button(text: String, at: Vector2) -> Button:
		var b := TipButton.new()
		b.text = text
		b.focus_mode = Control.FOCUS_NONE
		b.position = at
		b.size = TradeWindow.BUTTON
		b.custom_minimum_size = TradeWindow.BUTTON
		b.add_theme_font_size_override("font_size", 13)
		b.add_theme_font_override("font", UIStyle.display_font())
		add_child(b)
		return b

	## A slot-framed tile: portrait gradient, the icon `art/icons/<kind>/<id>.png` or the abbreviation.
	func _tile(at: Vector2, side: float, icon_kind: StringName, icon_id: StringName, abbr: String,
			letter: int) -> Tile:
		var t := Tile.new()
		t.position = at
		t.size = Vector2(side, side)
		t.icon = IconLibrary.icon_for(icon_kind, icon_id)
		t.abbr = abbr
		t.letter_size = letter
		add_child(t)
		return t


## A square tile: portrait gradient (trim_glow alpha 0.35 -> panel_inner), the icon (inset 4) or the abbreviation in
## the display font, a slot-frame rim in `rim`.
class Tile extends Control:
	var icon: Texture2D = null
	var abbr := ""
	var letter_size := 16
	var rim := Color(0, 0, 0, 0)

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_rim(c: Color) -> void:
		if c != rim:
			rim = c
			queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var inner := UIStyle.token(&"panel_inner")
		var glow := UIStyle.token(&"trim_glow")
		draw_rect(r, inner)
		for i in 6:
			var k := float(i) / 6.0
			draw_rect(Rect2(0, size.y * k * 0.5, size.x, size.y * 0.5 / 6.0 + 1.0),
					Color(glow.r, glow.g, glow.b, 0.35 * (1.0 - k)))
		if icon != null:
			draw_texture_rect(icon, r.grow(-4.0), false)
		elif abbr != "":
			var font := UIStyle.display_font()
			var w := font.get_string_size(abbr, HORIZONTAL_ALIGNMENT_LEFT, -1, letter_size).x
			var pos := Vector2((size.x - w) * 0.5, size.y * 0.5 + letter_size * 0.35)
			draw_string(font, pos, abbr, HORIZONTAL_ALIGNMENT_LEFT, -1, letter_size, UIStyle.token(&"title"))
		draw_rect(r.grow(-1.0), UIStyle.token(&"groove"), false, 1.0)
		draw_rect(r.grow(-2.5), rim if rim.a > 0.0 else UIStyle.token(&"frame_metal"), false, 2.0)


## One 740 x 64 ware row (ui-trade.md 10.2).
class WareRow extends TradeRow:
	var index := 0
	var id: StringName = &""
	var owned := false
	var reason := ""
	var tile: Tile
	var name_label: Label
	var owned_tag: Label           ## ` · Owned` after the name.
	var effect_label: Label
	var who_label: Label
	var price_box: HBoxContainer
	var price_label: Label
	var note_label: Label          ## `one-time`, or the refusal in WARN.
	var buy_button: Button
	var owned_label: Label         ## `Owned` centred in column C.

	func _ready() -> void:
		_init_row(TradeWindow.WARE_SIZE)
		var info: Dictionary = TradeWindow.WARE_INFO.get(id, {})
		tile = _tile(Vector2(8, 8), 48.0, &"wares", id, str(info.get("abbr", "")), 16)
		var name_row := HBoxContainer.new()
		name_row.add_theme_constant_override("separation", 0)
		name_row.position = Vector2(68, 6)
		name_row.size = Vector2(540, 20)
		name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(name_row)
		name_label = UIStyle.display_label(str(info.get("name", id)), 15)
		name_row.add_child(name_label)
		owned_tag = UIStyle.panel_label(" · Owned", 12, TradeWindow.OWNED)
		owned_tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		name_row.add_child(owned_tag)
		effect_label = _row_label(str(info.get("effect", "")), 12, Vector2(68, 26), 550)
		who_label = _row_label(str(info.get("who", "")), 11, Vector2(68, 44), 550)
		price_box = HBoxContainer.new()
		price_box.add_theme_constant_override("separation", 4)
		price_box.position = Vector2(628, 4)
		price_box.size = Vector2(104, 16)
		price_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(price_box)
		price_box.add_child(TradeWindow.coin_control(10.0))
		price_label = UIStyle.number_label("", 12, TradeWindow.GOLD_TEXT)
		price_box.add_child(price_label)
		note_label = _row_label("one-time", 10, Vector2(628, 20), 104)
		note_label.size.y = 12
		buy_button = _row_button("Buy", Vector2(628, 34))
		buy_button.pressed.connect(func() -> void: window.press_buy(index))
		owned_label = _row_label("Owned", 13, Vector2(628, 38), 104)
		owned_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		owned_label.add_theme_color_override("font_color", TradeWindow.OWNED)
		apply_skin()

	func apply_skin() -> void:
		name_label.add_theme_color_override("font_color", UIStyle.token(&"title"))
		effect_label.add_theme_color_override("font_color", UIStyle.token(&"text"))
		who_label.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
		TavernWindow.style_primary(buy_button)
		tile.queue_redraw()
		_style()

	func refresh() -> void:
		var info: Dictionary = TradeWindow.WARE_INFO.get(id, {})
		owned = window.owns_ware(id)
		reason = "" if owned else window.ware_reason(id)
		var price := window.ware_price(id)
		price_label.text = str(price)
		price_label.add_theme_color_override("font_color", UIStyle.WARN if window.gold() < price
				else TradeWindow.GOLD_TEXT)
		owned_tag.visible = owned
		price_box.visible = not owned
		note_label.visible = not owned
		buy_button.visible = not owned
		owned_label.visible = owned
		show_refusal(reason)
		buy_button.disabled = reason != ""
		buy_button.modulate.a = 0.45 if reason != "" else 1.0
		buy_button.tooltip_text = "Buy %s\n%d gold · once\n%s%s" % [str(info.get("name", id)), price,
				str(info.get("effect", "")), "\n" + reason if reason != "" else ""]
		rim = Color(UIStyle.GOLD, 0.6) if owned else Color(0, 0, 0, 0)
		tile.set_rim(UIStyle.GOLD if owned else UIStyle.token(&"frame_metal"))
		_style()

	## The note line: `one-time`, or the refusal in WARN.
	func show_refusal(text: String) -> void:
		reason = text if not owned else ""
		note_label.text = reason if reason != "" else "one-time"
		note_label.tooltip_text = reason
		note_label.add_theme_color_override("font_color", UIStyle.WARN if reason != ""
				else UIStyle.token(&"text_muted"))


## One 740 x 90 contract row (ui-trade.md 10.3): hireable, refused, running (time bar) or cooldown.
class ContractRow extends TradeRow:
	var kind: StringName = &""
	var state := &"hireable"       ## &"hireable", &"refused", &"running", &"cooldown".
	var reason := ""
	var tile: Tile
	var name_label: Label
	var sub_label: Label
	var desc_label: Label
	var price_box: HBoxContainer
	var price_label: Label
	var pop_label: Label           ## `No pop cost`.
	var reason_label: Label
	var status_label: Label        ## `Running` / `On cooldown`.
	var time_label: Label          ## `1:42 left` / `24 s`.
	var time_bar: Control          ## 104 x 6, fill = time left / duration.
	var hire_button: Button
	var time_ratio := 0.0

	func _ready() -> void:
		_init_row(TradeWindow.CONTRACT_SIZE)
		var info: Dictionary = TradeWindow.CONTRACT_INFO.get(kind, {})
		tile = _tile(Vector2(6, 7), 76.0, &"contracts", kind, str(info.get("abbr", "")), 22)
		name_label = UIStyle.display_label(str(info.get("name", kind)), 16)
		name_label.position = Vector2(92, 4)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(name_label)
		sub_label = _row_label("", 12, Vector2(92, 26), 530)
		desc_label = UIStyle.panel_label(str(info.get("desc", "")), 12)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.max_lines_visible = 2
		desc_label.position = Vector2(92, 44)
		desc_label.size = Vector2(530, 32)
		desc_label.custom_minimum_size = Vector2(530, 0)
		desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(desc_label)
		price_box = HBoxContainer.new()
		price_box.add_theme_constant_override("separation", 4)
		price_box.position = Vector2(628, 4)
		price_box.size = Vector2(104, 16)
		price_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(price_box)
		price_box.add_child(TradeWindow.coin_control(10.0))
		price_label = UIStyle.number_label("", 12, TradeWindow.GOLD_TEXT)
		price_box.add_child(price_label)
		pop_label = _row_label("No pop cost", 11, Vector2(628, 22), 106)
		reason_label = UIStyle.panel_label("", 11, UIStyle.WARN)
		reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		reason_label.max_lines_visible = 2
		reason_label.position = Vector2(628, 36)
		reason_label.size = Vector2(106, 26)
		reason_label.custom_minimum_size = Vector2(106, 0)
		reason_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(reason_label)
		status_label = _row_label("", 12, Vector2(628, 4), 106)
		time_label = _row_label("", 12, Vector2(628, 22), 106)
		time_bar = Control.new()
		time_bar.position = Vector2(628, 42)
		time_bar.size = Vector2(104, 6)
		time_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		time_bar.draw.connect(func() -> void:
			var r := Rect2(Vector2.ZERO, time_bar.size)
			time_bar.draw_rect(r, UIStyle.token(&"panel_inner"))
			time_bar.draw_rect(Rect2(0, 0, time_bar.size.x * clampf(time_ratio, 0.0, 1.0), time_bar.size.y), UIStyle.GOLD)
			time_bar.draw_rect(r, UIStyle.token(&"groove"), false, 1.0))
		add_child(time_bar)
		hire_button = _row_button("Hire", Vector2(628, 62))
		hire_button.pressed.connect(func() -> void: window.press_hire(kind))
		apply_skin()

	func apply_skin() -> void:
		name_label.add_theme_color_override("font_color", UIStyle.token(&"title"))
		sub_label.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
		desc_label.add_theme_color_override("font_color", UIStyle.token(&"text"))
		pop_label.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
		TavernWindow.style_primary(hire_button)
		tile.queue_redraw()
		_style()

	func refresh(g: Node) -> void:
		var info: Dictionary = TradeWindow.CONTRACT_INFO.get(kind, {})
		var cost := int(g.call(&"contract_cost", kind)) if g != null and g.has_method(&"contract_cost") \
				else int(info.get("cost", 0))
		var trackers := int(g.call(&"contract_trackers", kind)) if g != null and g.has_method(&"contract_trackers") \
				else int(info.get("trackers", 0))
		var duration := float(g.call(&"contract_duration", kind)) if g != null and g.has_method(&"contract_duration") \
				else float(info.get("duration", 0.0))
		if trackers <= 0:
			trackers = int(info.get("trackers", 0))
		if duration <= 0.0:
			duration = float(info.get("duration", 0.0))
		sub_label.text = "%d Greywater Trackers · %d s" % [trackers, roundi(duration)]
		var left := 0.0
		var cooldown := 0.0
		if g != null:
			if g.has_method(&"contract_time_left"):
				left = float(g.call(&"contract_time_left", window.team, kind))
			if g.has_method(&"cooldown_left"):
				cooldown = float(g.call(&"cooldown_left", window.team, kind))
		var running := left > 0.0 or (g != null and g.has_method(&"is_running")
				and bool(g.call(&"is_running", window.team, kind)))
		if running:
			state = &"running"
			reason = "Contract already running"
		elif cooldown > 0.0:
			state = &"cooldown"
			reason = "On cooldown"
		else:
			reason = str(g.call(&"can_hire", window.team, kind)) if g != null and g.has_method(&"can_hire") \
					else TradeWindow.NO_LODGE
			state = &"refused" if reason != "" else &"hireable"
		var not_hired := state == &"hireable" or state == &"refused"
		price_box.visible = not_hired
		pop_label.visible = not_hired
		reason_label.visible = state == &"refused"
		status_label.visible = not not_hired
		time_label.visible = not not_hired
		time_bar.visible = state == &"running"
		hire_button.visible = state != &"running"
		price_label.text = str(cost)
		price_label.add_theme_color_override("font_color", UIStyle.WARN if window.gold() < cost
				else TradeWindow.GOLD_TEXT)
		if state == &"running":
			status_label.text = "Running"
			status_label.add_theme_color_override("font_color", TradeWindow.NEAR)
			time_label.text = "%s left" % TradeWindow.mmss(left)
			time_label.add_theme_color_override("font_color", UIStyle.WARN if left < 10.0 else UIStyle.token(&"text"))
			time_ratio = left / duration if duration > 0.0 else 0.0
			time_bar.queue_redraw()
		elif state == &"cooldown":
			status_label.text = "On cooldown"
			status_label.add_theme_color_override("font_color", UIStyle.WARN)
			time_label.text = "%d s" % ceili(cooldown)
			time_label.add_theme_color_override("font_color", UIStyle.token(&"text"))
		reason_label.text = reason if state == &"refused" else ""
		hire_button.disabled = state != &"hireable"
		hire_button.modulate.a = 0.45 if hire_button.disabled else 1.0
		hire_button.tooltip_text = "Hire %s\n%d gold · %d trackers · %d s%s" % [str(info.get("name", kind)), cost,
				trackers, roundi(duration), "\n" + reason if reason != "" else ""]
		var glow := UIStyle.token(&"trim_glow")
		rim = Color(glow.r, glow.g, glow.b, 0.6) if state == &"running" else Color(0, 0, 0, 0)
		tile.set_rim(glow if state == &"running" else UIStyle.token(&"frame_metal"))
		_style()

	## A refusal after a click: shown on the reason line (hireable / refused rows).
	func show_refusal(text: String) -> void:
		if state == &"hireable" or state == &"refused":
			reason = text
			reason_label.text = text
			reason_label.visible = text != ""
