class_name KingdomCard
extends Button
## One kingdom card of the skirmish setup (task 8.U1): a toggle button showing the kingdom colour
## (top stripe, border, tint), its emblem (IconLibrary "emblems/<kingdom>" when an icon exists, else
## drawn by UIStyle.draw_emblem), the wizard's name, the kingdom name and a short play-style line.
## The tooltip lists the wizard's title and spells. Selected = gold rim + kingdom glow.

const CARD_SIZE := Vector2(206, 138)
const EMBLEM_SIZE := 46.0
## Order of the cards (Fire, Shadow, Ice, Nature).
const ORDER: Array[StringName] = [&"fire", &"shadow", &"ice", &"nature"]
## Per kingdom: display name, wizard, kingdom line, "<wizard> of <kingdom>", wizard title, play-style line, spells
## F / Q / E (spell names are proper names: never translated). Text goes through Loc (localization.md).
const INFO := {
	&"fire": {
		"name": "Fire", "wizard": "Vessa", "kingdom_line": "Fire kingdom", "of_line": "Vessa of Fire", "title": "Vessa, Fire Wizard",
		"style": "Hard-hitting soldiers and blazing spells. Push early, burn it all down.",
		"spells": ["Fireball", "Ember Step", "Kindle"],
	},
	&"shadow": {
		"name": "Shadow", "wizard": "Malrik", "kingdom_line": "Shadow kingdom", "of_line": "Malrik of Shadow", "title": "Malrik, Shadow Wizard",
		"style": "Few but elite warriors that drain life. Strike hard from the dark.",
		"spells": ["Shadow Lance", "Soul Siphon", "Umbral Shroud"],
	},
	&"ice": {
		"name": "Ice", "wizard": "Torvald", "kingdom_line": "Ice kingdom", "of_line": "Torvald of Ice", "title": "Torvald, Ice Wizard",
		"style": "A fortress that walks forward. Tough, armored, and everything chills.",
		"spells": ["Rime Bolt", "Flash Freeze", "Rime Aegis"],
	},
	&"nature": {
		"name": "Nature", "wizard": "Ysolde", "kingdom_line": "Nature kingdom", "of_line": "Ysolde of Nature", "title": "Ysolde, Nature Wizard",
		"style": "The swarm that grows back. Cheap, many, and heals between fights.",
		"spells": ["Thornburst", "Wild Bloom", "Call the Thicket"],
	},
}

var kingdom: StringName = &"fire"
var wizard_label: Label
var kingdom_label: Label
var style_label: Label
var emblem: Control
var _stripe: StyleBoxFlat


## A card for kingdom `k` (unknown kingdoms read as Fire).
static func create(k: StringName) -> KingdomCard:
	var card := KingdomCard.new()
	card.kingdom = k if INFO.has(k) else &"fire"
	return card


## "Vessa", "Malrik", "Torvald", "Ysolde".
static func wizard_name_of(k: StringName) -> String:
	return str((INFO.get(k, INFO[&"fire"]) as Dictionary)["wizard"])


## "Fire", "Shadow", "Ice", "Nature" (English: an id-like name; `Loc.t` it to show it).
static func kingdom_name_of(k: StringName) -> String:
	return str((INFO.get(k, INFO[&"fire"]) as Dictionary)["name"])


## "Vessa of Fire" in the current language.
static func of_line(k: StringName) -> String:
	return Loc.t(str((INFO.get(k, INFO[&"fire"]) as Dictionary)["of_line"]))


## The card tooltip: title, play style, spells with their keys.
static func tooltip_for(k: StringName) -> String:
	var info: Dictionary = INFO.get(k, INFO[&"fire"])
	var spells: Array = info["spells"]
	return Loc.t("%s\n%s\nSpells: %s [%s] · %s [%s] · %s [%s]") % [Loc.t(info["title"]), Loc.t(info["style"]), spells[0], KeyLabels.of(KEY_F),
			spells[1], KeyLabels.of(KEY_Q), spells[2], KeyLabels.of(KEY_E)]   # keyboard labels (UX.1)


func _ready() -> void:
	var info: Dictionary = INFO[kingdom]
	var col := UIStyle.kingdom_color(kingdom)
	name = "Card_%s" % kingdom
	toggle_mode = true
	text = ""
	custom_minimum_size = CARD_SIZE
	focus_mode = Control.FOCUS_ALL
	tooltip_text = tooltip_for(kingdom)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_apply_styles(col)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["margin_left", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 12)
	margin.add_theme_constant_override("margin_top", 14)
	add_child(margin)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var head := HBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_theme_constant_override("separation", 10)
	box.add_child(head)
	emblem = _make_emblem(col)
	head.add_child(emblem)
	var names := VBoxContainer.new()
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	names.add_theme_constant_override("separation", 0)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(names)
	wizard_label = UIStyle.display_label(str(info["wizard"]), 22, col.lightened(0.25))
	wizard_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wizard_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	wizard_label.add_theme_constant_override("outline_size", 4)
	names.add_child(wizard_label)
	kingdom_label = UIStyle.panel_label(str(info["kingdom_line"]), 13, Color(0.78, 0.74, 0.70))
	kingdom_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	names.add_child(kingdom_label)

	style_label = UIStyle.panel_label(str(info["style"]), 13, Color(0.92, 0.90, 0.86))
	style_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	style_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	style_label.custom_minimum_size = Vector2(CARD_SIZE.x - 24.0, 0)
	box.add_child(style_label)

	toggled.connect(_on_toggled)
	_on_toggled(button_pressed)


## The emblem: an IconLibrary texture ("emblems/<kingdom>") when there is one, else drawn in code.
func _make_emblem(col: Color) -> Control:
	var tex: Texture2D = IconLibrary.icon_for(&"emblems", kingdom)
	if tex != null:
		var rect := TextureRect.new()
		rect.texture = tex
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		rect.custom_minimum_size = Vector2(EMBLEM_SIZE, EMBLEM_SIZE)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return rect
	var c := Control.new()
	c.custom_minimum_size = Vector2(EMBLEM_SIZE, EMBLEM_SIZE)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func() -> void:
		var centre := c.size * 0.5
		var r := EMBLEM_SIZE * 0.5 - 3.0
		c.draw_circle(centre, r + 2.0, Color(0, 0, 0, 0.45))
		c.draw_circle(centre, r, Color(col.darkened(0.7), 0.95))
		UIStyle.draw_emblem(c, kingdom, centre, r - 3.0, col.lightened(0.15), Color(col.darkened(0.75), 1.0))
		c.draw_arc(centre, r, 0.0, TAU, 40, Color(col, 0.9), 1.5, true))
	return c


## Selects / clears the card without emitting `pressed` / `toggled`.
func set_selected(on: bool) -> void:
	set_pressed_no_signal(on)
	_on_toggled(on)


## Greys the card out (Skirmish.kingdom_available is false): not clickable, "Coming soon" line.
func set_unavailable() -> void:
	disabled = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	tooltip_text = Loc.t("%s\nComing soon: this kingdom can't start a skirmish yet.") % tooltip_for(kingdom).get_slice("\n", 0)
	if style_label:
		style_label.text = "Coming soon"
	_on_toggled(false)


## Live language switch: the tooltip is built in code (the labels redraw by themselves).
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		tooltip_text = Loc.t("%s\nComing soon: this kingdom can't start a skirmish yet.") % tooltip_for(kingdom).get_slice(
				"\n", 0) if disabled else tooltip_for(kingdom)


func _on_toggled(on: bool) -> void:
	# Unselected cards are a little dimmer, so the chosen one reads first; unavailable ones are grey.
	if disabled:
		modulate = Color(0.55, 0.55, 0.55, 0.8)
	else:
		modulate = Color.WHITE if on else Color(0.82, 0.82, 0.82)
	queue_redraw()
	if kingdom_label:
		kingdom_label.add_theme_color_override("font_color", UIStyle.GOLD if on and not disabled else Color(0.78, 0.74, 0.70))


func _apply_styles(col: Color) -> void:
	var base := Color(0.10, 0.08, 0.09, 0.95)
	var normal := _card_box(base.lerp(col, 0.10), Color(col, 0.55), 2, 0)
	var hover := _card_box(base.lerp(col, 0.18), Color(col, 0.95), 2, 0)
	var selected := _card_box(base.lerp(col, 0.26), UIStyle.GOLD, 3, 10)
	selected.shadow_color = Color(col, 0.45)
	var disabled := _card_box(Color(0.08, 0.08, 0.08, 0.9), Color(0.3, 0.3, 0.3), 2, 0)
	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", selected)
	add_theme_stylebox_override("hover_pressed", selected)
	add_theme_stylebox_override("disabled", disabled)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = Color(1, 1, 1, 0.35)
	focus.set_border_width_all(1)
	focus.set_corner_radius_all(8)
	focus.set_expand_margin_all(3)
	add_theme_stylebox_override("focus", focus)


## Card background: tinted fill and rim (the top stripe is drawn over it in _draw).
func _card_box(bg: Color, rim: Color, rim_width: int, shadow: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = rim
	s.set_border_width_all(rim_width)
	s.set_corner_radius_all(8)
	s.shadow_size = shadow
	s.anti_aliasing = true
	return s


## The 6 px kingdom-colour stripe along the top (kept in the kingdom colour even when the rim is gold),
## and a soft glow under it.
func _draw() -> void:
	var col := UIStyle.kingdom_color(kingdom)
	if _stripe == null:
		_stripe = StyleBoxFlat.new()
		_stripe.draw_center = false
		_stripe.border_width_top = 6
		_stripe.set_corner_radius_all(8)
		_stripe.anti_aliasing = true
	_stripe.border_color = col if not disabled else Color(0.35, 0.35, 0.35)
	draw_style_box(_stripe, Rect2(Vector2.ZERO, size))
	var glow_a := 0.22 if button_pressed else 0.10
	for i in 4:
		draw_rect(Rect2(3, 6 + i * 4, size.x - 6, 4), Color(col, glow_a * (1.0 - i / 4.0)))
