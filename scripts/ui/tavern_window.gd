class_name TavernWindow
extends PanelContainer
## The tavern window (step 9, task 9.C7; spec: docs/design/champions.md 3 + 9, layout: docs/design/ui-champions.md 5).
## 760 x 464 at (420, 156), heavy frame. Opened with Y (ChampionBar), a tavern click, or a fallen / reviving / empty
## champion slot (`open(slot)`: a fallen champion's row is highlighted). Y, Esc or the stud X close it; it also closes
## when the match ends. It never shows together with the shop (opening one closes the other).
## Title bar: TAVERN, the closed / held line, crystals, essence, X. Four 740 x 90 rows (wayfinder, oathwall,
## coin_cutter, mender), columns A (portrait, name + title, role, level-1 stats, personality), B (the 3 abilities),
## C (price / status / buttons): not hired `Hire` (disabled + the guild's reason), hired `Hired · Level 3` + intent +
## purse + `Dismiss` (a second click within 3 s), fallen `Revive 150` + `Dismiss`, reviving `Returns in 24 s`.
## Footer: upkeep / opening time and `Roster n / 3`.
## Buttons call the player's ChampionGuild (group "champion_guilds", same team): `hire(id)`, `revive(ch)`,
## `dismiss(ch)`. Everything guild / champion side is duck-typed; never a private call.
## Gold (step 10, 10.C8, ui-trade.md 11): while the player's team has a GoldBank (trade on) the title bar shows gold
## before crystals and column C gets 22 px buttons with a second price line and `HIRE · GOLD` (`hire(id, true)`) /
## `Revive 180 gold` (`revive(ch, true)`). Without a bank the step-9 layout is untouched.
## Classes (step 11, ui-champions.md 15.4): column B has 4 lines at a 20 px step, line 4 = the class line
## (`[L2] Class · usually ...` / `· leans ... (71 %)` / glyph + `Sword and Shield · skills 2 / 3`), the hired tile shows
## the class badge, hired stats read the champion, and the row flashes gold when its champion chooses a class.
## Keys (2026-09-29, JS: each champion shows its own key), physical, only while the window is open: Z X C V = the row's
## Hire (or Revive when fallen), Shift + the key = the gold button, B = the Genie. The Hire / Revive / Genie buttons show
## the letter in the command card's key badge; Dismiss stays click-only (two clicks to confirm). Y / Esc still close.

signal message(text: String)
signal opened
signal closed

const POS := Vector2(420, 156)
const SIZE := Vector2(760, 464)
const INNER := Vector2(740, 444)
const ROW_SIZE := Vector2(740, 90)
const ROW_Y := 38.0             ## First row, relative to the inner area (y 204 on screen).
const ROW_STEP := 96.0
const FOOTER_Y := 422.0         ## y 588 on screen.
const TILE := 76.0
const BUTTON := Vector2(104, 24)
const DISMISS_CONFIRM_TIME := 3.0
const REFRESH_TIME := 0.25
const HIGHLIGHT_FLASH := 0.5
const HIRE_FLASH := 0.3
const DISMISS_TOOLTIP := "Dismiss\nThe team gets 50 % of its purse and 50 % of its items' value."
const BUTTON_GOLD := Vector2(104, 22)   ## Column-C buttons while gold is on (ui-trade.md 11).
## Row keys (physical, QWERTY positions; the badges show the player's keyboard letters): rows 1-4, then the Genie.
const ROW_KEYS: Array[Key] = [KEY_Z, KEY_X, KEY_C, KEY_V]
const GENIE_KEY := KEY_B

var hero: Node = null
var hud: Node = null
var team := 0
## Archetype of each row, in order (wayfinder, oathwall, coin_cutter, mender).
var row_ids: Array[StringName] = []
var rows: Array[Row] = []
var title_label: Label
var closed_label: Label          ## `The tavern opens at 2:00` / `Enemies hold both taverns` (WARN), else "".
var crystals_label: Label
var essence_label: Label
var footer: Label                ## `Upkeep 1 essence / 10 s per champion · Tavern opens at 2:00`.
var roster_label: Label          ## `Roster 1 / 3`.
var highlighted: StringName = &""   ## The row the window was opened at (gold rim).
var last_result := ""               ## The last hire / revive answer ("" = done).
var gold_label: Label               ## Title-bar gold (shown only with a GoldBank).
var _gold_items: Array[Control] = []
var genie_button: Button            ## Footer "Wonders" button: hire / re-bottle the Stormbottle Genie (T3Kit).
var genie_key: Label                ## Its key badge (B).

var _dismiss_left: Dictionary = {}  ## row index -> seconds left to confirm the dismiss.
var _refresh_left := 0.0
var _skin := -1
var _close_button: Button
var _inner: Control
var _rule: ColorRect


## Builds the window under the HUD (hidden until `open()`); messages go to `hud.show_message`.
static func attach(p_hud: Node, wizard: Node = null) -> TavernWindow:
	var w := TavernWindow.new()
	w.hud = p_hud
	w.set_hero(wizard)
	p_hud.add_child(w)
	if p_hud.has_method(&"show_message"):
		w.message.connect(func(t: String) -> void: p_hud.call(&"show_message", t))
	return w


func set_hero(wizard: Node) -> void:
	hero = wizard
	if hero != null and is_instance_valid(hero) and hero.get("team") != null:
		team = int(hero.get("team"))


func _ready() -> void:
	position = POS
	size = SIZE
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	row_ids.assign(ChampionBar.IDS)
	UIStyle.add_drop_shadow(self)
	_inner = Control.new()
	_inner.custom_minimum_size = INNER
	_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_inner)

	# Title bar 740 x 28: TAVERN | closed line | crystals, essence, X.
	title_label = UIStyle.display_label("Tavern", 20)
	title_label.position = Vector2(0, 0)
	title_label.size = Vector2(160, 28)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_inner.add_child(title_label)
	closed_label = UIStyle.panel_label("", 14, UIStyle.WARN)
	closed_label.position = Vector2(160, 0)
	closed_label.size = Vector2(330, 28)
	closed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	closed_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_inner.add_child(closed_label)
	var money := HBoxContainer.new()
	money.alignment = BoxContainer.ALIGNMENT_END
	money.add_theme_constant_override("separation", 6)
	money.position = Vector2(390, 0)   # right-aligned: room on the left for the gold item (step 10)
	money.size = Vector2(350, 28)
	money.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inner.add_child(money)
	# Gold (trade on only), before crystals: the block still ends at the same x.
	var coin := TradeWindow.coin_control(16.0)
	money.add_child(coin)
	gold_label = UIStyle.number_label("0", 16, TradeWindow.GOLD_TEXT)
	money.add_child(gold_label)
	var gold_gap := spacer(6)
	money.add_child(gold_gap)
	_gold_items = [coin, gold_label, gold_gap]
	for c in _gold_items:
		c.visible = false
	money.add_child(icon_control(16.0, true))
	crystals_label = UIStyle.number_label("0", 16, UIStyle.CRYSTAL_TEXT)
	money.add_child(crystals_label)
	money.add_child(spacer(6))
	money.add_child(icon_control(16.0, false))
	essence_label = UIStyle.number_label("0", 16, UIStyle.ESSENCE_TEXT)
	money.add_child(essence_label)
	money.add_child(spacer(6))
	_close_button = Button.new()
	_close_button.text = "x"
	_close_button.tooltip_text = "Close  [Y]"
	_close_button.custom_minimum_size = Vector2(24, 24)
	_close_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_close_button.focus_mode = Control.FOCUS_NONE
	_close_button.add_theme_font_size_override("font_size", 13)
	_close_button.pressed.connect(close)
	money.add_child(_close_button)
	_rule = ColorRect.new()
	_rule.position = Vector2(0, 32)
	_rule.size = Vector2(INNER.x, 1)
	_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inner.add_child(_rule)

	for i in row_ids.size():
		var r := Row.new()
		r.window = self
		r.index = i
		r.id = row_ids[i]
		r.position = Vector2(0, ROW_Y + ROW_STEP * i)
		_inner.add_child(r)
		rows.append(r)

	footer = UIStyle.panel_label("", 12)
	footer.position = Vector2(0, FOOTER_Y)
	footer.size = Vector2(420, 18)
	_inner.add_child(footer)
	# t3-helpers.md 7.1 "Wonders": the neutral Stormbottle Genie, one per team, from the Citadel (T3Kit, switch ENABLED).
	genie_button = Button.new()
	genie_button.position = Vector2(424, FOOTER_Y - 3)
	genie_button.size = Vector2(172, 22)
	genie_button.focus_mode = Control.FOCUS_NONE
	genie_button.add_theme_font_size_override("font_size", 12)
	genie_button.visible = false
	genie_button.pressed.connect(press_genie)
	_inner.add_child(genie_button)
	genie_key = CommandCard.add_key_badge(genie_button, KeyLabels.of(GENIE_KEY))
	roster_label = UIStyle.panel_label("Roster 0 / 3", 12)
	roster_label.position = Vector2(600, FOOTER_Y)
	roster_label.size = Vector2(140, 18)
	roster_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_inner.add_child(roster_label)
	apply_skin()


func apply_skin() -> void:
	_skin = UIStyle.skin_version
	theme = UIStyle.hud_theme()   # slate tooltips (the window sits on the HUD layer, outside its root)
	add_theme_stylebox_override("panel", UIStyle.frame_style(10.0))
	title_label.add_theme_color_override("font_color", UIStyle.token(&"title"))
	footer.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
	_rule.color = UIStyle.token(&"frame_light")
	_style_stud(_close_button)
	CommandCard.keep_badge_room(genie_button)
	for r in rows:
		r.apply_skin()


## The round stud X (ui-style.md 6.4, as the shop's): `frame_metal` fill, `frame_light` ring, hover `WARN` ring.
static func _style_stud(b: Button) -> void:
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


## "Primary" button (ui-style.md 6.4): trim_glow rim, inside tinted; disabled = the 3.3 disabled frame.
static func style_primary(b: Button) -> void:
	var glow := UIStyle.token(&"trim_glow")
	b.add_theme_stylebox_override("normal", UIStyle.primary_button_frame())
	b.add_theme_stylebox_override("hover", UIStyle.button_frame(&"hover", glow.lightened(0.25)))
	b.add_theme_stylebox_override("pressed", UIStyle.button_frame(&"pressed", glow.darkened(0.2)))
	b.add_theme_stylebox_override("hover_pressed", UIStyle.button_frame(&"pressed", glow.darkened(0.2)))
	b.add_theme_stylebox_override("disabled", UIStyle.button_frame(&"disabled"))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", UIStyle.token(&"text"))
	b.add_theme_color_override("font_hover_color", UIStyle.token(&"text"))
	b.add_theme_color_override("font_disabled_color", UIStyle.token(&"text_muted"))


func icon_control(h: float, crystal: bool) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(h, h)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if crystal:
		c.draw.connect(func() -> void: ChampionBar.draw_crystal(c, Vector2.ZERO, h))
	else:
		c.draw.connect(func() -> void: ChampionBar.draw_flame(c, Vector2(h * 0.1, 0), h))
	return c


func spacer(w: float) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(w, 0)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return s


# ---------------------------------------------------------------- open / close

## Opens the window. `highlight`: a champion-bar slot index (int; its fallen / reviving champion's row gets the gold
## rim) or an archetype id (StringName). Returns false when the player's team has no guild (no tavern here).
func open(highlight: Variant = -1) -> bool:
	if guild() == null:
		return false
	highlighted = _highlight_id(highlight)
	_dismiss_left.clear()
	var shop: Variant = hud.get("shop_window") if hud != null and is_instance_valid(hud) else null
	if is_instance_valid(shop) and shop is Node and shop.has_method(&"is_open") and bool(shop.call(&"is_open")):
		shop.call(&"close")
	var was_open := visible
	visible = true
	if not was_open:
		for r in rows:
			r.forget_class()
	refresh()
	if highlighted != &"":
		for r in rows:
			if r.id == highlighted:
				r.flash(UIStyle.GOLD, HIGHLIGHT_FLASH)
	if not was_open:
		opened.emit()
	return true


func _highlight_id(h: Variant) -> StringName:
	if h is StringName or h is String:
		return StringName(str(h))
	if h is int and int(h) >= 0:
		var list := ChampionBar.roster(guild())
		if int(h) < list.size():
			var ch: Node = list[int(h)]
			if not ChampionBar.is_alive(ch):
				return ChampionBar.champion_id(ch)
	return &""


func close() -> void:
	if not visible:
		return
	visible = false
	_dismiss_left.clear()
	closed.emit()


## Y: open when closed, close when open.
func toggle() -> void:
	if visible:
		close()
	else:
		open()


func is_open() -> bool:
	return visible


func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo \
			and (event as InputEventKey).physical_keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


## Z X C V (physical) = the row's Hire / Revive (Shift = the gold button), B = the Genie, while the window is open.
## Read after the GUI (a focused text field keeps its letters) and before the selection's keys (no training meanwhile).
func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not visible or key == null or not key.pressed or key.echo or key.ctrl_pressed or key.alt_pressed:
		return
	var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	var row := ROW_KEYS.find(code)
	if row >= 0 and row < rows.size():
		press_row_key(row, key.shift_pressed)
		get_viewport().set_input_as_handled()
	elif code == GENIE_KEY and genie_button != null and genie_button.visible:
		if not genie_button.disabled:
			press_genie()
		else:
			message.emit(str(genie_button.get_meta(&"reason", "")))
		get_viewport().set_input_as_handled()


## Row `i`'s key: Hire when it can be hired (or refused: the reason shows), Revive when fallen; `gold` = the gold button
## (only while it is shown). Returns the answer ("" = done), "No action" when the row has none (hired, arriving...).
func press_row_key(i: int, gold := false) -> String:
	if i < 0 or i >= rows.size():
		return "No action"
	var r := rows[i]
	var g := guild()
	if g != null:
		r.refresh(g)
	match r.state:
		&"hireable", &"refused":
			return press_hire_gold(i) if gold and has_gold() else press_hire(i)
		&"fallen":
			return press_revive_gold(i) if gold and has_gold() else press_revive(i)
	return "No action"


## The key letter of row `i` on the player's keyboard ("Z" on QWERTY, "W" on AZERTY).
static func row_key_label(i: int) -> String:
	return KeyLabels.of(ROW_KEYS[i]) if i >= 0 and i < ROW_KEYS.size() else ""


func _process(delta: float) -> void:
	if _skin != UIStyle.skin_version:
		apply_skin()
	if not visible:
		return
	if guild() == null:
		close()
		return
	for k: int in _dismiss_left.keys():
		_dismiss_left[k] = float(_dismiss_left[k]) - delta
		if float(_dismiss_left[k]) <= 0.0:
			_dismiss_left.erase(k)
			_refresh_left = 0.0
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		refresh()


# ---------------------------------------------------------------- guild side (duck-typed)

## The player's ChampionGuild (group "champion_guilds", same team), or null.
func guild() -> Node:
	if not is_inside_tree():
		return null
	return ChampionBar.guild_for_team(get_tree(), team)


## The own roster champion of archetype `id`, or null.
func champion_for(id: StringName) -> Node:
	var g := guild()
	if g != null and g.has_method(&"champion_of"):
		var c: Variant = g.call(&"champion_of", id)
		return c if is_instance_valid(c) and c is Node else null
	for ch: Node in ChampionBar.roster(g):
		if ChampionBar.champion_id(ch) == id:
			return ch
	return null


## Row `i`'s Hire button: `guild.hire(id)`; a refusal goes to the message line and the row's reason.
func press_hire(i: int) -> String:
	var g := guild()
	if g == null or i < 0 or i >= row_ids.size() or not g.has_method(&"hire"):
		return "No tavern"
	last_result = str(g.call(&"hire", row_ids[i]))
	if last_result != "":
		message.emit(last_result)
	else:
		rows[i].flash(UIStyle.GOLD, HIRE_FLASH)
	refresh()
	if last_result != "":
		rows[i].show_reason(last_result)
	return last_result


## Row `i`'s Revive button: `guild.revive(champion)`.
func press_revive(i: int) -> String:
	var g := guild()
	var ch := champion_for(row_ids[i]) if i >= 0 and i < row_ids.size() else null
	if g == null or ch == null or not g.has_method(&"revive"):
		return "Not fallen"
	last_result = str(g.call(&"revive", ch))
	if last_result != "":
		message.emit(last_result)
	refresh()
	if last_result != "":
		rows[i].show_reason(last_result)
	return last_result


## The player's GoldBank (group "gold_banks"), or null: trade off, the step-9 layout.
func gold_bank() -> Node:
	return TradeWindow.gold_bank_of(get_tree(), team) if is_inside_tree() else null


## True while gold payments are offered (a GoldBank exists).
func has_gold() -> bool:
	return gold_bank() != null


## Row `i`'s `HIRE · GOLD` button: `guild.hire(id, true)` (the crystal part paid in gold).
func press_hire_gold(i: int) -> String:
	var g := guild()
	if g == null or i < 0 or i >= row_ids.size() or not g.has_method(&"hire") or not has_gold():
		return "No tavern"
	last_result = str(g.call(&"hire", row_ids[i], true))
	if last_result != "":
		message.emit(last_result)
	else:
		rows[i].flash(UIStyle.GOLD, HIRE_FLASH)
	refresh()
	if last_result != "":
		rows[i].show_reason(last_result)
	return last_result


## Row `i`'s `Revive 180 gold` button: `guild.revive(champion, true)`.
func press_revive_gold(i: int) -> String:
	var g := guild()
	var ch := champion_for(row_ids[i]) if i >= 0 and i < row_ids.size() else null
	if g == null or ch == null or not g.has_method(&"revive") or not has_gold():
		return "Not fallen"
	last_result = str(g.call(&"revive", ch, true))
	if last_result != "":
		message.emit(last_result)
	refresh()
	if last_result != "":
		rows[i].show_reason(last_result)
	return last_result


## Row `i`'s Dismiss button: the first click arms it for 3 s (`Confirm?`), the second calls `guild.dismiss(ch)`.
## Returns true when the champion was dismissed.
func press_dismiss(i: int) -> bool:
	var g := guild()
	var ch := champion_for(row_ids[i]) if i >= 0 and i < row_ids.size() else null
	if g == null or ch == null or not g.has_method(&"dismiss"):
		return false
	if not _dismiss_left.has(i):
		_dismiss_left[i] = DISMISS_CONFIRM_TIME
		refresh()
		return false
	_dismiss_left.erase(i)
	g.call(&"dismiss", ch)
	refresh()
	return true


## True while row `i`'s Dismiss waits for its second click.
func is_dismiss_armed(i: int) -> bool:
	return _dismiss_left.has(i)


## Updates the title bar, the rows and the footer from the guild (4 Hz by itself while open; tests may call it).
func refresh() -> void:
	_refresh_left = REFRESH_TIME
	var g := guild()
	if g == null:
		return
	var open_now := ChampionBar.guild_is_open(g)
	var used := ChampionBar.roster(g).size() + ChampionBar.pending_ids(g).size()
	if g.has_method(&"roster_size"):
		used = int(g.call(&"roster_size"))
	roster_label.text = "Roster %d / %d" % [used, ChampionBar.MAX_ROSTER]
	roster_label.add_theme_color_override("font_color", UIStyle.WARN if used >= ChampionBar.MAX_ROSTER
			else UIStyle.token(&"text"))
	footer.text = "Upkeep 1 essence / 10 s per champion · Tavern opens at %s" % ChampionBar.OPENS_AT
	if not ChampionBar.data_available():
		footer.text = "Champions not available"
	var eco := Economy.for_team(team)
	crystals_label.text = str(eco.crystals) if eco != null else "0"
	var bank := EssenceBank.for_team(team)
	essence_label.text = str(bank.essence) if bank != null else "0"
	var gbank := gold_bank()
	for c in _gold_items:
		c.visible = gbank != null
	if gbank != null:
		gold_label.text = str(int(gbank.get(&"gold")))
	# "Enemies hold both taverns" when every not-hired row is refused for that reason.
	var held := open_now
	var any_free := false
	for i in row_ids.size():
		rows[i].refresh(g)
		if rows[i].state == &"hireable" or rows[i].state == &"refused":
			any_free = true
			held = held and rows[i].reason == "Enemies hold both taverns"
	_refresh_genie()
	if not open_now:
		closed_label.text = "The tavern opens at %s" % ChampionBar.OPENS_AT
	elif held and any_free:
		closed_label.text = "Enemies hold both taverns"
	else:
		closed_label.text = ""


## Hires the Stormbottle Genie (or re-bottles a fallen one). "" = done, else the refusal (also sent as a message).
func press_genie() -> String:
	var r := T3Kit.hire_genie(team)
	if r != "":
		message.emit(r)
	refresh()
	return r


func _refresh_genie() -> void:
	if genie_button == null:
		return
	var wonders := T3Kit.wonders_for(team)
	genie_button.visible = not wonders.is_empty()
	if wonders.is_empty():
		return
	var roster := HelperRoster.for_team(team)
	var st: StringName = roster.genie_state if roster else &"none"
	var reason := T3Kit.can_hire_genie(team)
	match st:
		&"hiring":
			genie_button.text = "Genie: on its way"
		&"alive":
			genie_button.text = "Genie: hired"
		&"bottled":
			genie_button.text = "Unbottle Genie  %d e" % T3Kit.GENIE_REVIVE_ESSENCE
		_:
			genie_button.text = "Stormbottle Genie  %d" % T3Kit.GENIE_COST
	genie_button.disabled = reason != ""
	genie_button.set_meta(&"reason", reason)
	var gk := KeyLabels.of(GENIE_KEY)
	genie_key.text = gk
	genie_button.tooltip_text = "Stormbottle Genie  [%s]  (tier 3, one per team)\n%s\n%s" % [gk,
			T3Kit.description(T3Kit.GENIE_ID), reason if reason != "" else "%d crystals · Pop 4 · %d s" % [
			T3Kit.GENIE_COST, roundi(T3Kit.GENIE_TIME)]]


# ---------------------------------------------------------------- one row

## One 740 x 90 row (ui-champions.md 5.2): portrait tile, column A (identity), B (abilities), C (price / status).
class Row extends Panel:
	var window: TavernWindow
	var index := 0
	var id: StringName = &""
	var state := &"hireable"      ## &"hireable", &"refused", &"arriving", &"hired", &"fallen", &"reviving".
	var reason := ""
	var champion: Node = null
	var face: ChampionBar.Face
	var medallion: Control
	var level_label: Label
	var name_label: Label
	var title_label: Label
	var role_label: Label
	var stats_label: Label
	var personality_label: Label
	var ability_labels: Array[Label] = []   ## Name + short line, one per ability.
	var lock_badge: PanelContainer
	var lock_label: Label
	# Step 11 (ui-champions.md 15.4): column B line 4 = the class line.
	var class_l2_badge: PanelContainer       ## `L2` at (372, 67) before the class.
	var class_glyph: ChampionBar.ClassBadge  ## 16 x 16 at (372, 66) once the class is chosen.
	var class_word: ChampionBar.TipLabel     ## `Class` / `Sword and Shield` (text colour), from x 396.
	var class_rest: ChampionBar.TipLabel     ## ` · usually Sword and Shield` / ` · leans ... (71 %)` / ` · skills 2 / 3`.
	var tile_badge: ChampionBar.ClassBadge   ## 16 x 16 at (6, 70) on the portrait tile (hired with a class).
	var _class_line: Control
	var _seen_champion: Node = null
	var _seen_class: StringName = &""
	var price_box: HBoxContainer
	var price_crystals: Label
	var price_essence: Label
	var pop_label: Label
	var status_label: Label        ## `Hired · Level 3` / `Fallen · Level 2`.
	var intent_label: Label        ## Hired: intent (+ target); reviving: `Returns in 24 s`.
	var purse_box: HBoxContainer
	var purse_label: Label
	var reason_label: Label
	var hire_button: Button
	var revive_button: Button
	var dismiss_button: Button
	var hire_key: Label            ## Key badges (the row key, e.g. Z) on Hire and Revive.
	var revive_key: Label
	# Gold payment (step 10, ui-trade.md 11): shown only while the window has a GoldBank.
	var gold_price_box: HBoxContainer   ## Price B: coin + gold · flame + essence (font 11).
	var gold_price_label: Label
	var gold_essence_label: Label
	var hire_gold_button: Button        ## `HIRE · GOLD`.
	var revive_gold_button: Button      ## `Revive 180 gold`.
	var gold_layout := false            ## Read only: column C uses the 22 px gold layout.

	var _hovered := false
	var _flash_color := Color(0, 0, 0, 0)
	var _flash_left := 0.0
	var _flash_total := 0.0
	var _level := 1

	func _ready() -> void:
		size = TavernWindow.ROW_SIZE
		custom_minimum_size = TavernWindow.ROW_SIZE
		mouse_filter = Control.MOUSE_FILTER_PASS
		mouse_entered.connect(func() -> void:
			_hovered = true
			_style())
		mouse_exited.connect(func() -> void:
			_hovered = false
			_style())
		var info := ChampionBar.type_info(id)
		face = ChampionBar.Face.new()
		face.inset = 4.0
		face.letter_size = 22
		face.position = Vector2(6, 7)
		face.size = Vector2(TavernWindow.TILE, TavernWindow.TILE)
		add_child(face)
		medallion = Control.new()
		medallion.mouse_filter = Control.MOUSE_FILTER_IGNORE
		medallion.position = Vector2(63, 67)
		medallion.size = Vector2(22, 22)
		medallion.draw.connect(func() -> void:
			ChampionBar.draw_hex_badge(medallion, Vector2(11, 11), 11.0,
					UIStyle.GOLD if state == &"hired" else ChampionBar.FALLEN_EDGE))
		add_child(medallion)
		level_label = UIStyle.display_label("1", 11, UIStyle.GOLD)
		level_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		medallion.add_child(level_label)
		# Column A, x 92-362 (the name row is clipped at 270 px).
		var clip := Control.new()
		clip.position = Vector2(92, 4)
		clip.size = Vector2(270, 20)
		clip.clip_contents = true
		clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(clip)
		var name_row := HBoxContainer.new()
		name_row.add_theme_constant_override("separation", 0)
		name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip.add_child(name_row)
		name_label = UIStyle.display_label("", 16)
		name_row.add_child(name_label)
		title_label = UIStyle.panel_label(" · " + str(info.get("title", "")), 13)
		title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		name_row.add_child(title_label)
		role_label = _label(str(info.get("role", "")), 12, Vector2(92, 26), 270)
		stats_label = _label("", 12, Vector2(92, 44), 270)
		stats_label.mouse_filter = Control.MOUSE_FILTER_STOP
		personality_label = _label(str(info.get("personality_line", "")), 12, Vector2(92, 64), 270)
		personality_label.tooltip_text = personality_label.text
		personality_label.mouse_filter = Control.MOUSE_FILTER_STOP
		# Column B, x 372-622: three ability lines (the third starts with the L4 badge) and the class line, 4 lines at
		# a 20 px step (y 6 / 26 / 46 / 66, height 16; ui-champions.md 15.4).
		var abilities: Array = info.get("ability_ids", [])
		for j in 3:
			var x := 372.0
			if j == 2:
				lock_badge = _badge("L4", Vector2(372, 47))
				lock_label = lock_badge.get_child(0) as Label
				x += 24.0
			var ab_id: StringName = StringName(str(abilities[j])) if j < abilities.size() else &""
			var a := ChampionBar.ability_info(ab_id)
			var l := _label("%s · %s" % [ChampionBar.ability_display_name(ab_id, id), a.get("short", "")], 12,
					Vector2(x, 6 + 20 * j), 622.0 - x)
			l.size.y = 16
			l.mouse_filter = Control.MOUSE_FILTER_STOP
			l.tooltip_text = ChampionBar.ability_tooltip(ab_id, 1, float(info.get("growth_pct", 0.08)))
			l.set_meta(&"ability_id", ab_id)
			ability_labels.append(l)
		class_l2_badge = _badge("L2", Vector2(372, 67))
		class_glyph = ChampionBar.ClassBadge.new()
		class_glyph.position = Vector2(372, 66)
		add_child(class_glyph)
		_class_line = Control.new()
		_class_line.position = Vector2(396, 66)
		_class_line.size = Vector2(622.0 - 396.0, 16)
		_class_line.clip_contents = true
		_class_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_class_line)
		var class_row := HBoxContainer.new()
		class_row.add_theme_constant_override("separation", 0)
		class_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_class_line.add_child(class_row)
		class_word = ChampionBar.TipLabel.new()
		class_rest = ChampionBar.TipLabel.new()
		for cl: Label in [class_word, class_rest]:
			cl.add_theme_font_size_override("font_size", 12)
			cl.mouse_filter = Control.MOUSE_FILTER_STOP
			class_row.add_child(cl)
		tile_badge = ChampionBar.ClassBadge.new()
		tile_badge.position = Vector2(6, 70)
		add_child(tile_badge)
		# Column C, x 626-734.
		price_box = HBoxContainer.new()
		price_box.add_theme_constant_override("separation", 3)
		price_box.position = Vector2(628, 4)
		price_box.size = Vector2(106, 16)
		price_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(price_box)
		price_box.add_child(window.icon_control(10.0, true))
		price_crystals = UIStyle.number_label("", 12, UIStyle.CRYSTAL_TEXT)
		price_box.add_child(price_crystals)
		price_box.add_child(window.spacer(5))
		price_box.add_child(window.icon_control(10.0, false))
		price_essence = UIStyle.number_label("", 12, UIStyle.ESSENCE_TEXT)
		price_box.add_child(price_essence)
		pop_label = _label("Pop %d" % ChampionBar.POP, 11, Vector2(628, 22), 106)
		status_label = _label("", 12, Vector2(628, 4), 106)
		intent_label = _label("", 11, Vector2(628, 22), 106)
		purse_box = HBoxContainer.new()
		purse_box.add_theme_constant_override("separation", 4)
		purse_box.position = Vector2(628, 40)
		purse_box.size = Vector2(106, 16)
		purse_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(purse_box)
		purse_box.add_child(window.icon_control(10.0, false))
		purse_label = UIStyle.number_label("", 11, UIStyle.ESSENCE_TEXT)
		purse_box.add_child(purse_label)
		reason_label = _label("", 11, Vector2(628, 36), 106)
		reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		reason_label.clip_text = false
		reason_label.max_lines_visible = 2
		reason_label.add_theme_color_override("font_color", UIStyle.WARN)
		hire_button = _button("Hire", Vector2(628, 62))
		hire_button.add_theme_font_override("font", UIStyle.display_font())
		hire_button.pressed.connect(func() -> void: window.press_hire(index))
		revive_button = _button("Revive", Vector2(628, 34))
		revive_button.pressed.connect(func() -> void: window.press_revive(index))
		dismiss_button = _button("Dismiss", Vector2(628, 62))
		dismiss_button.tooltip_text = TavernWindow.DISMISS_TOOLTIP
		dismiss_button.pressed.connect(func() -> void: window.press_dismiss(index))
		hire_key = CommandCard.add_key_badge(hire_button, TavernWindow.row_key_label(index))
		revive_key = CommandCard.add_key_badge(revive_button, TavernWindow.row_key_label(index))
		_build_gold()
		apply_skin()

	## The gold controls (hidden until the window has a GoldBank).
	func _build_gold() -> void:
		gold_price_box = HBoxContainer.new()
		gold_price_box.add_theme_constant_override("separation", 3)
		gold_price_box.position = Vector2(628, 16)
		gold_price_box.size = Vector2(106, 14)
		gold_price_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gold_price_box.visible = false
		add_child(gold_price_box)
		gold_price_box.add_child(TradeWindow.coin_control(10.0))
		gold_price_label = UIStyle.number_label("", 11, TradeWindow.GOLD_TEXT)
		gold_price_box.add_child(gold_price_label)
		gold_price_box.add_child(window.spacer(5))
		gold_price_box.add_child(window.icon_control(10.0, false))
		gold_essence_label = UIStyle.number_label("", 11, UIStyle.ESSENCE_TEXT)
		gold_price_box.add_child(gold_essence_label)
		hire_gold_button = _button("Hire · Gold", Vector2(628, 64))
		hire_gold_button.add_theme_font_override("font", UIStyle.display_font())
		hire_gold_button.add_theme_font_size_override("font_size", 12)
		hire_gold_button.pressed.connect(func() -> void: window.press_hire_gold(index))
		hire_gold_button.visible = false
		revive_gold_button = _button("Revive gold", Vector2(628, 42))
		revive_gold_button.add_theme_font_size_override("font_size", 12)
		revive_gold_button.pressed.connect(func() -> void: window.press_revive_gold(index))
		revive_gold_button.visible = false

	func _label(text: String, font_size: int, at: Vector2, w: float) -> Label:
		var l := UIStyle.panel_label(text, font_size)
		l.clip_text = true   # before the size: a long text would otherwise widen the label past `w`
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		l.position = at
		l.size = Vector2(w, font_size + 5)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(l)
		return l

	## A 20 x 14 level badge (`L4` / `L2`): bg (0, 0, 0, 0.75), radius 2, font 10 GOLD.
	func _badge(text: String, at: Vector2) -> PanelContainer:
		var b := PanelContainer.new()
		b.position = at
		b.custom_minimum_size = Vector2(20, 14)
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0, 0, 0, 0.75)
		s.set_corner_radius_all(2)
		b.add_theme_stylebox_override("panel", s)
		var l := UIStyle.panel_label(text, 10, UIStyle.GOLD)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		b.add_child(l)
		add_child(b)
		return b

	func _button(text: String, at: Vector2) -> Button:
		var b := Button.new()
		b.text = text
		b.focus_mode = Control.FOCUS_NONE
		b.position = at
		b.size = TavernWindow.BUTTON
		b.custom_minimum_size = TavernWindow.BUTTON
		b.add_theme_font_size_override("font_size", 13)
		add_child(b)
		return b

	func apply_skin() -> void:
		name_label.add_theme_color_override("font_color", UIStyle.token(&"title"))
		title_label.add_theme_color_override("font_color", UIStyle.token(&"text"))
		role_label.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
		stats_label.add_theme_color_override("font_color", UIStyle.token(&"text"))
		personality_label.add_theme_color_override("font_color", Color(UIStyle.token(&"title"), 0.85))
		pop_label.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
		for l in ability_labels:
			l.add_theme_color_override("font_color", UIStyle.token(&"text"))
		class_word.add_theme_color_override("font_color", UIStyle.token(&"text"))
		class_rest.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
		TavernWindow.style_primary(hire_button)
		TavernWindow.style_primary(revive_button)
		CommandCard.keep_badge_room(hire_button)
		CommandCard.keep_badge_room(revive_button)
		if hire_gold_button != null:
			TradeWindow.style_gold(hire_gold_button)
			TradeWindow.style_gold(revive_gold_button)
		_style_dismiss()
		face.apply_skin()
		_style()

	func _style_dismiss() -> void:
		var armed := window != null and window.is_dismiss_armed(index)
		UIStyle.style_button(dismiss_button, UIStyle.WARN if armed else UIStyle.PANEL_BORDER)
		if not armed:
			dismiss_button.add_theme_stylebox_override("hover", UIStyle.button_frame(&"hover", UIStyle.WARN))

	## Row background: panel_inner alpha 0.55 (hover 0.8), radius 3; rim GOLD when highlighted, trim_glow (alpha
	## 0.6) when hired; a flash tints the rim for a moment.
	func _style() -> void:
		var s := StyleBoxFlat.new()
		var inner := UIStyle.token(&"panel_inner")
		s.bg_color = Color(inner.r, inner.g, inner.b, 0.8 if _hovered else 0.55)
		s.set_corner_radius_all(3)
		var rim := Color(0, 0, 0, 0)
		if window != null and window.highlighted == id:
			rim = UIStyle.GOLD
		elif state == &"hired" or state == &"fallen" or state == &"reviving":
			var g := UIStyle.token(&"trim_glow")
			rim = Color(g.r, g.g, g.b, 0.6)
		if _flash_left > 0.0 and _flash_total > 0.0:
			var k := _flash_left / _flash_total
			rim = (rim if rim.a > 0.0 else Color(_flash_color, 0.0)).lerp(_flash_color, k)
			s.bg_color = s.bg_color.lerp(Color(_flash_color, 0.8), 0.35 * k)
		if rim.a > 0.0:
			s.border_color = rim
			s.set_border_width_all(1)
		add_theme_stylebox_override("panel", s)

	func flash(color: Color, seconds: float) -> void:
		_flash_color = color
		_flash_left = seconds
		_flash_total = seconds
		_style()

	## True while a flash (highlight, hire, class chosen) tints the row.
	func is_flashing() -> bool:
		return _flash_left > 0.0

	## `Class · usually Sword and Shield` + ` · leans ...` / `Sword and Shield · skills 2 / 3`: column B line 4.
	func class_line_text() -> String:
		return class_word.text + class_rest.text

	## Column B line 4 and the tile badge (ui-champions.md 15.4). Not hired: `[L2] Class · usually <base favourite>`;
	## hired without a class (or arriving): `[L2] Class · leans <class> (71 %)` with the live weights; with a class:
	## the glyph + `<Class> · skills n / 3`. Flashes GOLD when the class is chosen while the window is open.
	func _refresh_class(hired: bool) -> void:
		var cid := ChampionBar.class_id_of(champion) if hired else &""
		var tip := ""
		if cid != &"":
			tip = ChampionBar.class_tooltip_for(champion)
			class_word.text = ChampionBar.class_display_name(cid)
			class_rest.text = " · skills %d / 3" % TavernWindow.class_skills_unlocked(champion, cid)
		elif hired or state == &"arriving":
			var weights := ChampionBar.class_weights_for(champion if hired else id)
			tip = ChampionBar.lean_tooltip(weights, 0, true)
			class_word.text = "Class"
			class_rest.text = " · leans " + ChampionBar.lean_text(weights)
		else:
			tip = ChampionBar.lean_tooltip(ChampionBar.class_weights_for(id), 0, true)
			class_word.text = "Class"
			class_rest.text = " · usually " + ChampionBar.class_display_name(ChampionBar.usual_class(id))
		class_word.tooltip_text = tip
		class_rest.tooltip_text = tip
		class_l2_badge.visible = cid == &""
		class_glyph.set_class(cid, tip)
		tile_badge.set_class(cid, tip)
		var dim := ChampionBar.FALLEN_TINT if state == &"fallen" or state == &"reviving" else Color.WHITE
		_class_line.modulate = dim
		class_glyph.modulate = dim
		tile_badge.modulate = dim
		if champion != _seen_champion:
			_seen_champion = champion
		elif cid != _seen_class and cid != &"":
			flash(UIStyle.GOLD, TavernWindow.HIRE_FLASH)
		_seen_class = cid

	## Forgets the last class seen (the window was closed: a class chosen meanwhile does not flash on opening).
	func forget_class() -> void:
		_seen_champion = null

	func _process(delta: float) -> void:
		if _flash_left > 0.0:
			_flash_left = maxf(_flash_left - delta, 0.0)
			_style()

	## The refusal line (WARN, 2 lines max) under the price.
	func show_reason(text: String) -> void:
		reason = text
		reason_label.text = text
		reason_label.visible = text != "" and (state == &"hireable" or state == &"refused") and not gold_layout
		if gold_layout and (state == &"hireable" or state == &"refused"):
			# Gold layout: the reason replaces `Pop 2` on the font-10 line (the full text is in the tooltips).
			pop_label.text = text if text != "" else "Pop %d" % ChampionBar.POP
			pop_label.tooltip_text = text
			pop_label.add_theme_color_override("font_color", UIStyle.WARN if text != ""
					else UIStyle.token(&"text_muted"))

	func refresh(g: Node) -> void:
		var info := ChampionBar.type_info(id)
		champion = window.champion_for(id)
		var arriving := champion == null and ChampionBar.pending_ids(g).has(id)
		reason = ""
		if champion != null:
			var alive := ChampionBar.is_alive(champion)
			var left := ChampionBar.revive_left(g, champion)
			state = &"hired" if alive else (&"reviving" if left > 0.0 else &"fallen")
		elif arriving:
			state = &"arriving"
		else:
			reason = str(g.call(&"can_hire", id)) if g.has_method(&"can_hire") else ""
			state = &"refused" if reason != "" else &"hireable"
		var hired := champion != null
		var shown_name := ChampionBar.display_name_of(champion) if hired \
				else ChampionBar.hire_name(window.get_tree(), g, id, window.team)
		name_label.text = shown_name
		face.set_face(id, shown_name, state == &"fallen" or state == &"reviving")
		face.set_rim(UIStyle.token(&"frame_metal") if not hired else (UIStyle.token(&"trim_glow")
				if state == &"hired" else UIStyle.token(&"frame_dark")))
		_level = ChampionBar.level_of(champion) if hired else 1
		level_label.text = str(_level)
		level_label.add_theme_color_override("font_color", UIStyle.GOLD if state == &"hired" else ChampionBar.FALLEN_EDGE)
		medallion.visible = hired
		medallion.queue_redraw()
		stats_label.text = TavernWindow.stats_line(info, champion)
		stats_label.tooltip_text = stats_label.text   # the full line when the column clips it
		# L4 badge: dark with a gold "L4" until the champion reaches level 4, then filled gold with a black "L4".
		var unlocked := hired and _level >= 4
		var bs := StyleBoxFlat.new()
		bs.bg_color = UIStyle.GOLD if unlocked else Color(0, 0, 0, 0.75)
		bs.set_corner_radius_all(2)
		lock_badge.add_theme_stylebox_override("panel", bs)
		lock_label.add_theme_color_override("font_color", Color.BLACK if unlocked else UIStyle.GOLD)
		var growth := float(info.get("growth_pct", 0.08))
		for l in ability_labels:
			l.tooltip_text = ChampionBar.ability_tooltip(l.get_meta(&"ability_id", &""), _level, growth)
		_refresh_class(hired)
		# Column C per state.
		var not_hired := state == &"hireable" or state == &"refused"
		price_box.visible = not_hired
		pop_label.visible = not_hired
		hire_button.visible = not_hired
		status_label.visible = not not_hired
		intent_label.visible = state == &"hired" or state == &"reviving" or state == &"arriving"
		purse_box.visible = state == &"hired"
		revive_button.visible = state == &"fallen"
		dismiss_button.visible = hired
		if not_hired:
			var cost := ChampionBar.hire_cost(g, id)
			price_crystals.text = str(cost.x)
			price_essence.text = str(cost.y)
			price_crystals.add_theme_color_override("font_color", UIStyle.WARN if reason == "Not enough crystals"
					else UIStyle.CRYSTAL_TEXT)
			price_essence.add_theme_color_override("font_color", UIStyle.WARN if reason == "Not enough essence"
					else UIStyle.ESSENCE_TEXT)
			hire_button.disabled = reason != ""
			hire_button.modulate.a = 0.45 if reason != "" else 1.0
			var rk := TavernWindow.row_key_label(index)
			hire_key.text = rk
			hire_button.tooltip_text = "Hire  [%s]\n%d crystals · %d essence · %d pop%s" % [rk, cost.x, cost.y,
					ChampionBar.POP, "\n" + reason if reason != "" else ""]
		elif state == &"arriving":
			status_label.text = "Hired · Level 1"
			status_label.add_theme_color_override("font_color", UIStyle.token(&"title"))
			intent_label.text = "Arrives in %d s" % ceili(ChampionBar.hire_left(g, id))
			intent_label.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
		elif state == &"hired":
			status_label.text = "Hired · Level %d" % _level
			status_label.add_theme_color_override("font_color", UIStyle.token(&"title"))
			var t := ChampionBar.target_text(champion, g)
			intent_label.text = t
			intent_label.tooltip_text = t
			intent_label.add_theme_color_override("font_color", ChampionBar.intent_color(t))
			purse_label.text = str(ChampionBar.purse_of(champion))
		else:
			status_label.text = "Fallen · Level %d" % _level
			status_label.add_theme_color_override("font_color", UIStyle.WARN)
			if state == &"reviving":
				intent_label.position.y = 34
				intent_label.add_theme_font_size_override("font_size", 12)
				intent_label.text = "Returns in %d s" % ceili(ChampionBar.revive_left(g, champion))
				intent_label.add_theme_color_override("font_color", UIStyle.WARN)
			else:
				var rcost := ChampionBar.revive_cost(g, champion)
				revive_button.text = "Revive %d" % rcost
				var r: Variant = g.call(&"can_revive", champion) if g.has_method(&"can_revive") else ""
				var why := "" if r == null or (r is bool and r) else ("Cannot revive" if r is bool else str(r))
				revive_button.disabled = why != ""
				revive_button.modulate.a = 0.45 if why != "" else 1.0
				revive_button.add_theme_color_override("font_disabled_color", UIStyle.WARN)
				var rk := TavernWindow.row_key_label(index)
				revive_key.text = rk
				revive_button.tooltip_text = "Revive  [%s]\n%d essence · returns at your keep%s" % [rk, rcost,
						"\n" + why if why != "" else ""]
		if state != &"reviving":
			intent_label.position.y = 22
			intent_label.add_theme_font_size_override("font_size", 11)
		if hired:
			var armed := window.is_dismiss_armed(index)
			dismiss_button.text = "Confirm?" if armed else "Dismiss"
			_style_dismiss()
		_refresh_gold(g, not_hired)
		show_reason(reason)
		_style()

	## Column C with gold on (ui-trade.md 11): 22 px buttons, price B, `HIRE · GOLD`, `Revive 180 gold`. With gold off
	## (no GoldBank) the step-9 positions come back and the gold controls hide.
	func _refresh_gold(g: Node, not_hired: bool) -> void:
		var gold := window.has_gold()
		if gold != gold_layout:
			gold_layout = gold
			_place(price_box, Vector2(628, 2 if gold else 4))
			pop_label.position = Vector2(628, 29 if gold else 22)
			pop_label.size = Vector2(106, 12 if gold else 16)
			pop_label.add_theme_font_size_override("font_size", 10 if gold else 11)
			if not gold:
				pop_label.text = "Pop %d" % ChampionBar.POP
				pop_label.tooltip_text = ""
				pop_label.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
			_resize(hire_button, Vector2(628, 40) if gold else Vector2(628, 62), gold)
			_resize(revive_button, Vector2(628, 18) if gold else Vector2(628, 34), gold)
		var fallen := state == &"fallen"
		status_label.position.y = 2.0 if gold and fallen else 4.0   # `Fallen · Level 2` sits 2 px higher with gold
		# Dismiss: 22 px at y 66 under the two revive buttons while fallen; the hired look (y 62, 24 px) otherwise.
		_resize(dismiss_button, Vector2(628, 66) if gold and fallen else Vector2(628, 62), gold and fallen)
		gold_price_box.visible = gold and not_hired
		hire_gold_button.visible = gold and not_hired
		revive_gold_button.visible = gold and fallen
		if not gold:
			return
		_resize(hire_gold_button, Vector2(628, 64), true)
		_resize(revive_gold_button, Vector2(628, 42), true)
		if not_hired:
			var d: Variant = g.call(&"hire_cost", id, true) if g.has_method(&"hire_cost") else {}
			var cost: Dictionary = d if d is Dictionary else {}
			var gold_cost := int(cost.get("gold", ChampionBar.hire_cost(g, id).x))
			var ess := int(cost.get("essence", ChampionBar.hire_cost(g, id).y))
			var why := str(g.call(&"can_hire", id, true)) if g.has_method(&"can_hire") else ""
			gold_price_label.text = str(gold_cost)
			gold_essence_label.text = str(ess)
			gold_price_label.add_theme_color_override("font_color", UIStyle.WARN if why == "Not enough gold"
					else TradeWindow.GOLD_TEXT)
			gold_essence_label.add_theme_color_override("font_color", UIStyle.WARN if why == "Not enough essence"
					else UIStyle.ESSENCE_TEXT)
			hire_gold_button.disabled = why != ""
			hire_gold_button.modulate.a = 0.45 if why != "" else 1.0
			hire_gold_button.tooltip_text = "Hire with gold  [Shift+%s]\n%d gold · %d essence · %d pop%s" % [
					TavernWindow.row_key_label(index), gold_cost, ess, ChampionBar.POP, "\n" + why if why != "" else ""]
		elif fallen:
			var rcost := int(g.call(&"revive_cost", champion, true)) if g.has_method(&"revive_cost") \
					else 2 * ChampionBar.revive_cost(g, champion)
			revive_gold_button.text = "Revive %d gold" % rcost
			var r: Variant = g.call(&"can_revive", champion, true) if g.has_method(&"can_revive") else ""
			var why := "" if r == null or (r is bool and r) else ("Cannot revive" if r is bool else str(r))
			revive_gold_button.disabled = why != ""
			revive_gold_button.modulate.a = 0.45 if why != "" else 1.0
			revive_gold_button.add_theme_color_override("font_disabled_color", UIStyle.WARN)
			revive_gold_button.tooltip_text = "Revive with gold  [Shift+%s]\n%d gold · returns at your keep%s" % [
					TavernWindow.row_key_label(index), rcost, "\n" + why if why != "" else ""]

	func _place(c: Control, at: Vector2) -> void:
		c.position = at

	## Moves a column-C button and gives it the 22 px (gold) or 24 px (step 9) height.
	func _resize(b: Button, at: Vector2, short: bool) -> void:
		var s := TavernWindow.BUTTON_GOLD if short else TavernWindow.BUTTON
		b.custom_minimum_size = s
		b.size = s
		b.position = at


## Column A stats: `260 HP · 13 damage · 8.0 range · 5.8 speed` (+ ` · 20 armor` when armor > 0); level-1 numbers
## from the type, or the hired champion's own numbers (15.4: max HP, get_stat damage / speed / armor, the
## `attack_range` field), so its class shows through.
static func stats_line(info: Dictionary, ch: Node = null) -> String:
	var hp := float(info.get("max_hp", 0))
	var dmg := float(info.get("attack_damage", 0))
	var armor := float(info.get("armor", 0))
	var reach := float(info.get("attack_range", 0))
	var speed := float(info.get("move_speed", 0))
	if ch != null and is_instance_valid(ch):
		hp = ChampionBar.max_hp_of(ch)
		dmg = _champion_stat(ch, &"attack_damage", dmg)
		speed = _champion_stat(ch, &"move_speed", speed)
		armor = _champion_stat(ch, &"armor", armor)
		if ch.get("attack_range") != null:
			reach = float(ch.get("attack_range"))
	# snappedf: a stat recomputed in float (5.99999) reads 6.0, not 5.9.
	var line := "%s HP · %s damage · %s range · %s speed" % [_num(hp), _num(dmg), String.num(snappedf(reach, 0.1), 1),
			String.num(snappedf(speed, 0.1), 1)]
	if armor > 0.0:
		line += " · %s armor" % _num(armor)
	return line


static func _champion_stat(ch: Node, stat: StringName, fallback: float) -> float:
	if ch.has_method(&"get_stat"):
		return float(ch.call(&"get_stat", stat))
	var v: Variant = ch.get(stat)
	return float(v) if v != null else fallback


## How many of `cid`'s 3 skills `ch` has unlocked: its abilities' `is_unlocked` when it has them, else its level
## against the class unlock levels (2 / 3 / 5).
static func class_skills_unlocked(ch: Node, cid: StringName) -> int:
	var info := ChampionBar.class_info(cid)
	var ids: Array = info.get("ability_ids", [])
	var levels: Array = info.get("unlock_levels", ChampionBar.CLASS_UNLOCKS)
	var abilities: Variant = ch.get("abilities") if ch != null and is_instance_valid(ch) else null
	if not (is_instance_valid(abilities) and abilities is Object) and ch != null and is_instance_valid(ch):
		abilities = ch.get_node_or_null(^"ChampionAbilities")
	var n := 0
	var level := ChampionBar.level_of(ch)
	for j in ids.size():
		if is_instance_valid(abilities) and abilities is Object and (abilities as Object).has_method(&"is_unlocked"):
			if bool((abilities as Object).call(&"is_unlocked", StringName(str(ids[j])))):
				n += 1
		elif j < levels.size() and level >= int(levels[j]):
			n += 1
	return n


## One line per ability as the tavern shows them: "Signal Flare · 20 dmg, reveals a spot 6 s".
static func abilities_text(info: Dictionary) -> String:
	var lines: PackedStringArray = []
	for a: Variant in info.get("ability_ids", []):
		var aid := StringName(str(a))
		lines.append("%s · %s" % [ChampionBar.ability_display_name(aid, StringName(str(info.get("id", "")))),
				ChampionBar.ability_info(aid).get("short", "")])
	return "\n".join(lines)


static func _num(v: Variant) -> String:
	var f := float(v)
	if absf(f - roundf(f)) < 0.05:
		return str(roundi(f))
	return String.num(f, 1)
