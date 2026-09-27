class_name FlagCard
extends Control
## The flag card (champions.md 9, layout ui-champions.md section 7): shown over the selection area while a bounty
## flag is selected (`selection.selected_bounty`). 676 x 204 at (588, 670), anchored to the bottom like the selection
## panel; it paints an opaque `panel_bg` so the "Nothing selected" text under it does not show.
## Tile (flag glyph), title (`HUNT BOUNTY` / `ENEMY HUNT BOUNTY`), target line, stake + paid, time line, pursuer
## chips (28 x 28, tooltip `Sable Quint · Hunting bounty`), key hint. Enemy flags: target and stake only, no paid /
## pursuers, the enemy hint. Refreshes at 4 Hz and when the flag changes (`Bounty.changed`).
## The keys (Z / Shift+Z / Delete) are the SelectionManager's; the buttons are on the command card.
## `FlagCard.attach(hud)` adds it once (the command card calls it on setup, so no HUD wiring is needed).

const RECT := Rect2(588, 670, 676, 204)
const BOTTOM := 900.0
const REFRESH := 0.25
const TILE := 96.0
const X_TEXT := 108.0            ## 696 - 588
const Y_TITLE := 0.0
const Y_TARGET := 30.0           ## 700 - 670
const Y_STAKE := 52.0            ## 722
const Y_TIME := 76.0             ## 746
const Y_PURSUERS := 100.0        ## 770
const Y_HINT := 136.0            ## 806
const CHIP := 28.0
const CHIP_X := 182.0            ## 770 - 588
const CHIP_GAP := 32.0
const MAX_CHIPS := 3
const POP_TIME := 0.2
const OWN_HINT := "Z: raise +25  ·  Shift+Z: +100  ·  Delete: remove"
const ENEMY_HINT := "An enemy bounty: kill or protect its target."
const GROUP := &"flag_card"

var selection: SelectionManager
## The flag shown (read only).
var flag: Node3D
## Read only (tests): the parts.
var title_label: Label
var target_label: Label
var stake_label: Label
var paid_label: Label
var time_label: Label
var pursuers_label: Label
var none_label: Label
var hint_label: Label
var chips: Array[Button] = []

var _tile: Control
var _coin: Control
var _refresh_left := 0.0
var _last_stake := -1
var _pop_left := 0.0
var _watched: Node = null


## Adds the card under `hud` once (a second call returns the same card). `selection` may be set later with setup().
static func attach(hud: Node, p_selection: SelectionManager = null) -> FlagCard:
	var tree := Engine.get_main_loop() as SceneTree
	var card: FlagCard = null
	if tree != null:
		for n in tree.get_nodes_in_group(GROUP):
			if n is FlagCard and not n.is_queued_for_deletion():
				card = n
				break
	if card == null:
		card = FlagCard.new()
		card.name = "FlagCard"
		if hud != null:
			hud.add_child(card)
	if p_selection != null:
		card.setup(p_selection)
	return card


func _init() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	theme = UIStyle.hud_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP   # clicks on the card don't reach the battlefield
	set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	offset_left = RECT.position.x
	offset_right = RECT.end.x
	offset_top = -(BOTTOM - RECT.position.y)          # -230
	offset_bottom = -(BOTTOM - RECT.end.y)            # -26
	visible = false

	_tile = Control.new()
	_tile.position = Vector2.ZERO
	_tile.size = Vector2(TILE, TILE)
	_tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tile.draw.connect(_draw_tile)
	add_child(_tile)

	title_label = UIStyle.display_label("", 20)
	_place(title_label, Vector2(X_TEXT, Y_TITLE))
	target_label = UIStyle.panel_label("", 14)
	_place(target_label, Vector2(X_TEXT, Y_TARGET))
	_coin = Control.new()
	_coin.position = Vector2(X_TEXT, Y_STAKE + 4.0)
	_coin.size = Vector2(14, 14)
	_coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_coin.draw.connect(func() -> void:
		_coin.draw_circle(Vector2(7, 7), 6.5, BountyMode.COIN_COLOR)
		_coin.draw_arc(Vector2(7, 7), 6.5, 0.0, TAU, 20, BountyMode.COIN_RING, 1.0, true))
	add_child(_coin)
	stake_label = UIStyle.number_label("", 18, UIStyle.GOLD)
	_place(stake_label, Vector2(X_TEXT + 20.0, Y_STAKE - 2.0))
	paid_label = UIStyle.panel_label("", 13)
	_place(paid_label, Vector2(X_TEXT + 60.0, Y_STAKE + 2.0))
	time_label = UIStyle.panel_label("", 13)
	_place(time_label, Vector2(X_TEXT, Y_TIME))
	pursuers_label = UIStyle.panel_label("Pursuers", 13)
	_place(pursuers_label, Vector2(X_TEXT, Y_PURSUERS))
	none_label = UIStyle.panel_label("none yet", 13)
	_place(none_label, Vector2(CHIP_X, Y_PURSUERS))
	for i in MAX_CHIPS:
		var b := ChipButton.new()
		b.position = Vector2(CHIP_X + CHIP_GAP * i, Y_PURSUERS - 4.0)
		b.size = Vector2(CHIP, CHIP)
		b.custom_minimum_size = Vector2(CHIP, CHIP)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 11)
		UIStyle.style_button(b)
		b.pressed.connect(_on_chip_pressed.bind(i))
		b.visible = false
		add_child(b)
		chips.append(b)
	hint_label = UIStyle.panel_label("", 12)
	_place(hint_label, Vector2(X_TEXT, Y_HINT))
	apply_skin()


func _place(l: Label, at: Vector2) -> void:
	l.position = at
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)


func setup(p_selection: SelectionManager) -> void:
	selection = p_selection
	if not selection.selection_changed.is_connected(refresh):
		selection.selection_changed.connect(refresh)
	refresh()


func apply_skin() -> void:
	if title_label == null:
		return
	title_label.add_theme_color_override("font_color", UIStyle.token(&"title"))
	for l: Label in [target_label, paid_label, pursuers_label, none_label, hint_label]:
		l.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
	for b in chips:
		UIStyle.style_button(b)
	queue_redraw()


func _process(delta: float) -> void:
	if _pop_left > 0.0:
		_pop_left = maxf(_pop_left - delta, 0.0)
		var t := 1.0 - _pop_left / POP_TIME
		var s := 1.0 + 0.3 * sin(PI * t)
		stake_label.scale = Vector2(s, s)
		stake_label.add_theme_color_override("font_color", UIStyle.GOLD.lerp(Color.WHITE, sin(PI * t)))
	if not visible and (selection == null or selection.selected_bounty == null):
		return
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH
		refresh()


func _draw() -> void:
	var bg := UIStyle.token(&"panel_bg")
	draw_rect(Rect2(Vector2.ZERO, size), Color(bg.r, bg.g, bg.b, 1.0))


## Rebuilds the texts from the selected flag (hidden when no flag is selected).
func refresh() -> void:
	var f: Node3D = selection.selected_bounty if selection != null else null
	if f != null and (not is_instance_valid(f) or not f.is_inside_tree() or f.is_queued_for_deletion()):
		f = null
	visible = f != null
	_watch(f)
	flag = f
	if f == null:
		_last_stake = -1
		return
	var own := is_own()
	var kind := BountyMode.flag_kind(f)
	var kname := BountyMode.kind_name(kind).to_upper()
	title_label.text = ("ENEMY %s BOUNTY" if not own else "%s BOUNTY") % kname
	target_label.text = target_text(f)
	var stake := BountyMode.flag_stake(f)
	stake_label.text = str(stake)
	stake_label.reset_size()
	stake_label.pivot_offset = stake_label.size * 0.5
	paid_label.position.x = stake_label.position.x + stake_label.size.x + 2.0
	var paid_text := "  ·  Paid %d" % BountyMode.flag_paid(f) if own else ""
	if stake >= BountyMode.MAX_STAKE:
		paid_text += " · max"
	paid_label.text = paid_text
	if _last_stake >= 0 and stake > _last_stake:
		_pop_left = POP_TIME   # a raise: the stake pops 1.0 -> 1.3 -> 1.0 in 0.2 s
	_last_stake = stake
	var tl := time_line(f)
	time_label.text = tl[0]
	time_label.add_theme_color_override("font_color", tl[1])
	var pursuers := BountyMode.flag_pursuers(f)
	pursuers_label.visible = own
	none_label.visible = own and pursuers.is_empty()
	for i in chips.size():
		var b := chips[i]
		b.visible = own and i < pursuers.size()
		if b.visible:
			var ch: Node = pursuers[i]
			var n := BountyMode.target_name(ch)
			b.text = UIStyle.abbrev(n)
			b.tooltip_text = "%s · %s" % [n, _intent_text(ch)]
			b.set_meta(&"champion", ch)
	# Physical Z as labelled on the player's keyboard ("W" on AZERTY, UX.1).
	hint_label.text = OWN_HINT.replace("Z", KeyLabels.of(KEY_Z)) if own else ENEMY_HINT
	_tile.queue_redraw()


## True when the shown flag is the player's (raise / remove allowed).
func is_own() -> bool:
	return flag != null and is_instance_valid(flag) and BountyMode.flag_team(flag) == Unit.Team.PLAYER


## `Target: Gloom Hall`, `Guarding: Ember Hall`, `Escorting: Vessa`, `Point: unexplored ground`.
static func target_text(f: Node) -> String:
	var kind := BountyMode.flag_kind(f)
	var t := BountyMode.flag_target(f)
	var n := BountyMode.target_name(t) if t != null else "gone"
	match kind:
		BountyMode.EXPLORE:
			var fog := FogOfWar.find()
			var explored := fog == null or not fog.enabled \
					or fog.is_explored(BountyMode.flag_team(f), (f as Node3D).global_position)
			return "Point: %s ground" % ("explored" if explored else "unexplored")
		BountyMode.GUARD:
			return "Guarding: %s" % n
		BountyMode.ESCORT:
			return "Escorting: %s" % n
	return "Target: %s" % n


## [text, colour] of the time line: `Time left 1:30` (WARN under 10 s), `Target lost · refund in 42 s` (WARN),
## `Until the target dies` / `Until a champion reaches it` (muted).
static func time_line(f: Node) -> Array:
	var kind := BountyMode.flag_kind(f)
	var left := BountyMode.flag_time_left(f)
	match kind:
		BountyMode.GUARD, BountyMode.ESCORT:
			var secs := maxi(ceili(maxf(left, 0.0)), 0)
			return ["Time left %d:%02d" % [secs / 60, secs % 60], UIStyle.WARN if secs < 10 else UIStyle.token(&"text")]
		BountyMode.HUNT:
			if BountyMode.flag_target_lost(f) and left >= 0.0:
				return ["Target lost · refund in %d s" % ceili(left), UIStyle.WARN]
			return ["Until the target dies", UIStyle.token(&"text_muted")]
	return ["Until a champion reaches it", UIStyle.token(&"text_muted")]


func _intent_text(ch: Node) -> String:
	var intent: Variant = ch.get("intent")
	if intent == null or str(intent) == "":
		return "Idle"
	var s := str(intent)
	return s.replace("_", " ").capitalize() if s.contains("_") or s == s.to_lower() else s


func _watch(f: Node) -> void:
	if _watched == f:
		return
	if _watched != null and is_instance_valid(_watched) and _watched.has_signal(&"changed") \
			and _watched.is_connected(&"changed", refresh):
		_watched.disconnect(&"changed", refresh)
	_watched = f
	if f != null and f.has_signal(&"changed") and not f.is_connected(&"changed", refresh):
		f.connect(&"changed", refresh)


## A pursuer chip: centre the camera on that champion (never selects it).
func _on_chip_pressed(i: int) -> void:
	if i >= chips.size() or selection == null:
		return
	var ch: Variant = chips[i].get_meta(&"champion", null)
	if is_instance_valid(ch) and ch is Node3D:
		selection.centre_camera_on([ch])


## The tile: slot frame (enemy: DEFEAT rim), portrait gradient, the flag glyph at 4x (pole (30, 14)-(30, 84),
## pennant (34, 16) (74, 27) (34, 40) in the flag's team colour, coin r 20 at (60, 60), kind icon 20 px).
func _draw_tile() -> void:
	var r := Rect2(Vector2.ZERO, Vector2(TILE, TILE))
	var inner := UIStyle.token(&"panel_inner")
	_tile.draw_rect(r, inner)
	var glow := UIStyle.token(&"trim_glow")
	_tile.draw_circle(r.get_center(), TILE * 0.45, Color(glow.r, glow.g, glow.b, 0.18))
	var rim := UIStyle.token(&"frame_metal") if is_own() else UIStyle.DEFEAT
	_tile.draw_rect(r.grow(-1.0), UIStyle.token(&"groove"), false, 1.0)
	_tile.draw_rect(r.grow(-2.5), rim, false, 2.0)
	if flag == null or not is_instance_valid(flag):
		return
	var team_col := BountyMode.pennant_color(BountyMode.flag_team(flag))
	_tile.draw_line(Vector2(30, 14), Vector2(30, 84), UIStyle.token(&"frame_dark"), 3.0)
	_tile.draw_colored_polygon(PackedVector2Array([Vector2(34, 16), Vector2(74, 27), Vector2(34, 40)]), team_col)
	_tile.draw_circle(Vector2(60, 60), 20.0, BountyMode.COIN_COLOR)
	_tile.draw_arc(Vector2(60, 60), 20.0, 0.0, TAU, 40, BountyMode.COIN_RING, 2.0, true)
	BountyMode.draw_kind_icon(_tile, Vector2(60, 60), 16.0, BountyMode.flag_kind(flag), BountyMode.ICON_INK)


## A pursuer chip button with the styled tooltip panel (ui-style.md 8).
class ChipButton extends Button:
	func _make_custom_tooltip(for_text: String) -> Object:
		return UIStyle.make_tooltip(for_text)
