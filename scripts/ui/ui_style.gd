class_name UIStyle
extends RefCounted
## Shared HUD look (spec: docs/design/ui-style.md, layout: docs/design/ui-hud.md).
##
## SKIN API (6.U1). The player's kingdom skins the HUD; gameplay colours never change.
##   set_kingdom(k: StringName)        &"fire" (default) / &"shadow" / &"ice" / &"nature"; GameHUD.setup calls it. Rebuilds tokens,
##                                      clears the texture cache and bumps `skin_version`.
##   get_kingdom() -> StringName
##   token(name: StringName) -> Color  Skin tokens: frame_metal, frame_light, frame_dark, groove, trim_glow,
##                                      panel_bg, panel_inner, slate_bg, title, text, text_muted.
##   skin_version: int                  Static counter; compare it to know when to rebuild your styles.
## Frames and boxes (all generated in code, cached per kingdom):
##   frame_texture() -> ImageTexture    The 48 x 48 heavy frame image (rings, trim line, 4 gem studs).
##   frame_style(margin := 10.0)        StyleBoxTexture, texture margins 16, content margin `margin`.
##   add_drop_shadow(panel: Control)    Adds the soft shadow Panel behind a framed panel (grown 6 px).
##   slate_style(margin := 10.0, border := frame_dark) -> StyleBoxFlat   quiet secondary panel.
##   tooltip_style() -> StyleBoxFlat    slate, frame_metal border, margin 8.
##   button_frame(state, rim := auto) -> StyleBoxTexture   state: &"normal", &"hover", &"pressed",
##                                      &"disabled", &"selected" (GOLD rim). 24 x 24 image, margins 8; hover has a
##                                      1 px trim_glow halo outside (expand margin 1). `rim` overrides the rim colour.
##                                      Content margin 2 (set your own if you need more).
##   style_button(b, border := PANEL_BORDER)  Applies the frame states (normal/hover/pressed/disabled/focus).
##                                      PANEL_BORDER (or no arg) = skin metal; any other colour = that rim (GOLD = selected).
##   primary_button_frame() -> StyleBoxTexture  trim_glow rim, inside tinted trim_glow 0.18 (shop Buy).
## Fonts / labels:
##   game_theme() -> Theme              U7: assets/ui/four_wizards_theme.tres (Alegreya body, Cinzel headers), or null.
##   title_font() -> Font               U7: Cinzel bold from the game theme, or null.
##   display_font() -> Font             Titles/names/badges: Cinzel when the game theme loads, else the default
##                                      font embolden 0.8, spacing_glyph 1 (display_label also uppercases).
##   number_font() -> Font              Default font embolden 0.5 (crystals, pop, timer, bar text).
##   label(text, size)                  Outlined label (outline 3: text over the world or over a bar fill).
##   panel_label(text, size, color := text)    No outline (inside framed panels).
##   display_label(text, size, color := title) Uppercased display font, no outline.
##   number_label(text, size, color := text)   Number font, no outline.
## Bars:  bar(color, height := 22.0) -> [ProgressBar, Label]  gradient fill, groove border, 25/50/75 % ticks.
##        set_bar_color(bar, color) / bar_color(bar)   Recolour a bar made by bar() (cheap; for pulses/flashes).
## Tooltips: make_tooltip(text) -> Control  Section 8 layout from an unchanged `tooltip_text`; return it from
##        `_make_custom_tooltip(for_text)`. hud_theme() -> Theme sets TooltipPanel to tooltip_style().
## Kingdoms (8.U1): kingdom_color(k) -> Color (KINGDOM_COLORS), draw_emblem(canvas, k, centre, radius, col).
## Colours (never skinned): GOLD, WARN, HP_COLOR, MANA_COLOR, CRYSTAL, CRYSTAL_TEXT, ESSENCE, ESSENCE_TEXT, DEFEAT.
## Legacy (unchanged names): panel_style (now a skinned flat panel), panel, button_style, abbrev, health_color,
##        PANEL_BG, PANEL_BORDER.

const PANEL_BG := Color(0.06, 0.05, 0.08, 0.78)
const PANEL_BORDER := Color(0.75, 0.55, 0.25, 0.8)
const GOLD := Color(1.0, 0.85, 0.4)
const WARN := Color(0.95, 0.35, 0.3)
const HP_COLOR := Color(0.8, 0.2, 0.2)
const MANA_COLOR := Color(0.25, 0.45, 0.95)
const CRYSTAL := Color(0.45, 0.85, 1.0)
const CRYSTAL_TEXT := Color(0.75, 0.92, 1.0)
const ESSENCE := Color(0.75, 0.45, 1.0)
const ESSENCE_TEXT := Color(0.9, 0.8, 1.0)
const DEFEAT := Color(0.85, 0.30, 0.30)

const SKINS := {
	&"fire": {
		&"frame_metal": Color(0.62, 0.40, 0.16), &"frame_light": Color(0.85, 0.62, 0.30),
		&"frame_dark": Color(0.36, 0.22, 0.09), &"groove": Color(0.04, 0.03, 0.03),
		&"trim_glow": Color(1.00, 0.55, 0.15), &"panel_bg": Color(0.10, 0.08, 0.09, 0.92),
		&"panel_inner": Color(0.14, 0.11, 0.11), &"slate_bg": Color(0.06, 0.05, 0.08, 0.72),
		&"title": Color(1.00, 0.80, 0.45), &"text": Color(0.94, 0.92, 0.88),
		&"text_muted": Color(0.66, 0.60, 0.55),
	},
	&"shadow": {
		&"frame_metal": Color(0.55, 0.52, 0.66), &"frame_light": Color(0.78, 0.76, 0.88),
		&"frame_dark": Color(0.30, 0.28, 0.40), &"groove": Color(0.03, 0.02, 0.05),
		&"trim_glow": Color(0.70, 0.30, 1.00), &"panel_bg": Color(0.09, 0.07, 0.13, 0.92),
		&"panel_inner": Color(0.13, 0.11, 0.18), &"slate_bg": Color(0.05, 0.04, 0.09, 0.72),
		&"title": Color(0.85, 0.70, 1.00), &"text": Color(0.92, 0.92, 0.96),
		&"text_muted": Color(0.60, 0.58, 0.70),
	},
	# ui-style.md 1: Ice = icy silver metal (0.70, 0.78, 0.88), glow (0.75, 0.92, 1.00), bg (0.30, 0.38, 0.48) x 0.35.
	&"ice": {
		&"frame_metal": Color(0.70, 0.78, 0.88), &"frame_light": Color(0.88, 0.93, 0.98),
		&"frame_dark": Color(0.38, 0.45, 0.55), &"groove": Color(0.02, 0.03, 0.05),
		&"trim_glow": Color(0.75, 0.92, 1.00), &"panel_bg": Color(0.105, 0.133, 0.168, 0.92),
		&"panel_inner": Color(0.14, 0.18, 0.23), &"slate_bg": Color(0.05, 0.07, 0.10, 0.72),
		&"title": Color(0.80, 0.93, 1.00), &"text": Color(0.92, 0.95, 0.98),
		&"text_muted": Color(0.58, 0.65, 0.74),
	},
	# ui-style.md 1 (8.U1): Nature = bark metal (0.40, 0.28, 0.16), leafy glow (0.75, 1.00, 0.40),
	# bg (0.22, 0.20, 0.14) darkened x0.35 like Ice, slightly greener.
	&"nature": {
		&"frame_metal": Color(0.40, 0.28, 0.16), &"frame_light": Color(0.62, 0.52, 0.32),
		&"frame_dark": Color(0.22, 0.15, 0.08), &"groove": Color(0.03, 0.03, 0.02),
		&"trim_glow": Color(0.75, 1.00, 0.40), &"panel_bg": Color(0.077, 0.080, 0.049, 0.92),
		&"panel_inner": Color(0.12, 0.13, 0.08), &"slate_bg": Color(0.04, 0.05, 0.03, 0.72),
		&"title": Color(0.82, 1.00, 0.55), &"text": Color(0.93, 0.95, 0.88),
		&"text_muted": Color(0.62, 0.66, 0.52),
	},
}

## Signature colour of each kingdom (8.U1 kingdom cards, emblems): its trim glow / team colour.
const KINGDOM_COLORS := {
	&"fire": Color(1.00, 0.55, 0.15),
	&"shadow": Color(0.66, 0.36, 1.00),
	&"ice": Color(0.62, 0.86, 1.00),
	&"nature": Color(0.52, 0.85, 0.30),
}

static var skin_version: int = 0
static var _kingdom: StringName = &"fire"
static var _cache: Dictionary = {}
static var _display_font: FontVariation
static var _number_font: FontVariation
const GAME_THEME_PATH := "res://assets/ui/four_wizards_theme.tres"
static var _game_theme: Theme
static var _game_theme_tried := false


# --- Skin ---------------------------------------------------------------------------------------

static func set_kingdom(k: StringName) -> void:
	var next: StringName = k if SKINS.has(k) else &"fire"
	if next == _kingdom and skin_version > 0:
		return
	_kingdom = next
	_cache.clear()
	skin_version += 1


static func get_kingdom() -> StringName:
	return _kingdom


static func token(name: StringName) -> Color:
	var skin: Dictionary = SKINS[_kingdom]
	return skin.get(name, Color.MAGENTA)


# --- Heavy frame (3.1) ----------------------------------------------------------------------------

static func frame_texture() -> ImageTexture:
	var key := "frame"
	if _cache.has(key):
		return _cache[key]
	var n := 48
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var bg := token(&"panel_bg")
	var groove := token(&"groove")
	var glow := token(&"trim_glow")
	var trim := bg.lerp(Color(glow.r, glow.g, glow.b, bg.a), 0.55)
	var shade := bg.lerp(Color(groove.r, groove.g, groove.b, bg.a), 0.5)
	for y in n:
		for x in n:
			var d: int = mini(mini(x, y), mini(n - 1 - x, n - 1 - y))
			var c: Color
			match d:
				0:
					c = Color(0, 0, 0, 0.55)
				1:
					var top_left := (x == 1 or y == 1) and x < n - 2 and y < n - 2
					c = token(&"frame_light") if top_left else token(&"frame_dark")
				2, 3:
					c = token(&"frame_metal")
				4:
					c = groove
				5:
					c = trim
				6:
					c = shade
				_:
					c = bg
			img.set_pixel(x, y, c)
	for corner: Vector2i in [Vector2i(5, 5), Vector2i(n - 6, 5), Vector2i(5, n - 6), Vector2i(n - 6, n - 6)]:
		_stud(img, corner, 4)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


static func _stud(img: Image, c: Vector2i, r: int) -> void:
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var m := absi(dx) + absi(dy)
			if m > r:
				continue
			var col := token(&"frame_light")
			if dx > 0 and dy > 0 and m >= r - 1:
				col = token(&"frame_dark")
			if m == 0:
				col = token(&"trim_glow")
			img.set_pixel(c.x + dx, c.y + dy, col)


static func frame_style(margin := 10.0) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = frame_texture()
	s.set_texture_margin_all(16)
	s.set_content_margin_all(margin)
	s.draw_center = true
	return s


## Soft drop shadow behind a framed panel (an internal Panel drawn behind its parent).
static func add_drop_shadow(panel: Control) -> Panel:
	for c in panel.get_children(true):
		if c.name == &"DropShadow":
			return c as Panel
	var sh := Panel.new()
	sh.name = "DropShadow"
	sh.show_behind_parent = true
	sh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sh.set_anchors_preset(Control.PRESET_FULL_RECT)
	sh.offset_left = -6
	sh.offset_top = -6
	sh.offset_right = 6
	sh.offset_bottom = 6
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0, 0, 0, 0)
	st.shadow_size = 8
	st.shadow_color = Color(0, 0, 0, 0.45)
	st.shadow_offset = Vector2(0, 3)
	sh.add_theme_stylebox_override("panel", st)
	panel.add_child(sh, false, Node.INTERNAL_MODE_FRONT)
	return sh


# --- Slate (3.2) ----------------------------------------------------------------------------------

static func slate_style(margin := 10.0, border := Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = token(&"slate_bg")
	s.border_color = border if border.a > 0.0 else token(&"frame_dark")
	s.set_border_width_all(1)
	s.set_corner_radius_all(2)
	s.set_content_margin_all(margin)
	return s


static func tooltip_style() -> StyleBoxFlat:
	var s := slate_style(8.0, token(&"frame_metal"))
	s.bg_color.a = 0.94
	return s


# --- Button / slot frames (3.3) -------------------------------------------------------------------

static func button_frame(state: StringName = &"normal", rim := Color(0, 0, 0, 0)) -> StyleBoxTexture:
	var inner := token(&"panel_inner")
	var r := rim
	if r.a <= 0.0:
		match state:
			&"hover":
				r = token(&"frame_light")
			&"pressed", &"disabled":
				r = token(&"frame_dark")
			&"selected":
				r = GOLD
			_:
				r = token(&"frame_metal")
	match state:
		&"hover":
			inner = inner.lightened(0.12)
		&"pressed":
			inner = inner.darkened(0.25)
	var halo := state == &"hover"
	var s := StyleBoxTexture.new()
	s.texture = _button_texture(r, inner, halo)
	s.set_texture_margin_all(9 if halo else 8)
	if halo:
		s.set_expand_margin_all(1)
	s.set_content_margin_all(2)
	return s


static func _button_texture(rim: Color, inner: Color, halo: bool) -> ImageTexture:
	var key := "btn_%s_%s_%s" % [rim.to_html(), inner.to_html(), halo]
	if _cache.has(key):
		return _cache[key]
	var o := 1 if halo else 0
	var n := 24 + 2 * o
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var glow := token(&"trim_glow")
	for y in n:
		for x in n:
			var d: int = mini(mini(x, y), mini(n - 1 - x, n - 1 - y)) - o
			var c: Color
			if d < 0:
				c = Color(glow.r, glow.g, glow.b, 0.6)
			elif d == 0:
				c = Color(0, 0, 0, 0.8)
			elif d == 1:
				var top_left := (x - o == 1 or y - o == 1) and x < n - 2 - o and y < n - 2 - o
				c = rim.lightened(0.3) if top_left else rim.darkened(0.35)
			elif d == 2:
				c = rim
			elif d == 3:
				c = token(&"groove")
			else:
				c = inner
			img.set_pixel(x, y, c)
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


static func primary_button_frame() -> StyleBoxTexture:
	var glow := token(&"trim_glow")
	var s := StyleBoxTexture.new()
	s.texture = _button_texture(glow, token(&"panel_inner").lerp(glow, 0.18), false)
	s.set_texture_margin_all(8)
	s.set_content_margin_all(2)
	return s


## Skinned frame states. `border` = PANEL_BORDER (default) uses the kingdom metal; any other colour is the rim
## (GOLD = selected / pending / active).
static func style_button(b: Button, border := PANEL_BORDER) -> void:
	var custom := border != PANEL_BORDER
	var rim := border if custom else Color(0, 0, 0, 0)
	b.add_theme_stylebox_override("normal", button_frame(&"normal", rim))
	b.add_theme_stylebox_override("hover", button_frame(&"hover", border.lightened(0.25) if custom else rim))
	b.add_theme_stylebox_override("pressed", button_frame(&"pressed", border.darkened(0.2) if custom else rim))
	b.add_theme_stylebox_override("hover_pressed", button_frame(&"pressed", border.darkened(0.2) if custom else rim))
	b.add_theme_stylebox_override("disabled", button_frame(&"disabled", rim))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", token(&"text"))
	b.add_theme_color_override("font_hover_color", token(&"text"))
	b.add_theme_color_override("font_pressed_color", token(&"frame_light"))


# --- Fonts and labels (2) -------------------------------------------------------------------------

## U7: the game Theme (assets/ui/four_wizards_theme.tres): Alegreya default font (body text), Cinzel on the
## Label type variations TitleLabel / HeaderLarge / HeaderMedium / HeaderSmall. Load-guarded: null if missing.
static func game_theme() -> Theme:
	if not _game_theme_tried:
		_game_theme_tried = true
		if ResourceLoader.exists(GAME_THEME_PATH):
			_game_theme = load(GAME_THEME_PATH) as Theme
	return _game_theme


## U7: the title face (Cinzel bold from the game Theme), or null when the theme / font is missing.
static func title_font() -> Font:
	var t := game_theme()
	if t != null and t.has_font(&"font", &"TitleLabel"):
		return t.get_font(&"font", &"TitleLabel")
	return null


## U7: gives a title / header label the Cinzel face (no-op when the game theme is missing). Returns `l`.
static func use_title_font(l: Label) -> Label:
	var f := title_font()
	if f != null:
		l.add_theme_font_override("font", f)
	return l


static func display_font() -> Font:
	if _display_font == null:
		_display_font = FontVariation.new()
		var title := title_font() as FontVariation
		if title != null and title.base_font != null:
			# U7: Cinzel (already a display face: bold weight, no fake embolden).
			_display_font.base_font = title.base_font
			_display_font.variation_opentype = title.variation_opentype
			_display_font.spacing_glyph = 1
		else:
			_display_font.base_font = ThemeDB.fallback_font
			_display_font.variation_embolden = 0.8
			_display_font.spacing_glyph = 1
	return _display_font


static func number_font() -> Font:
	if _number_font == null:
		_number_font = FontVariation.new()
		_number_font.base_font = ThemeDB.fallback_font
		_number_font.variation_embolden = 0.5
	return _number_font


## Outlined label: text over the 3D world or over a bar fill.
static func label(text: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	return l


## Label inside a framed panel: no outline.
static func panel_label(text: String, font_size: int, color := Color(0, 0, 0, 0)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color if color.a > 0.0 else token(&"text"))
	return l


static func display_label(text: String, font_size: int, color := Color(0, 0, 0, 0)) -> Label:
	var l := panel_label(text, font_size, color if color.a > 0.0 else token(&"title"))
	l.uppercase = true
	l.add_theme_font_override("font", display_font())
	return l


static func number_label(text: String, font_size: int, color := Color(0, 0, 0, 0)) -> Label:
	var l := panel_label(text, font_size, color)
	l.add_theme_font_override("font", number_font())
	return l


# --- Bars (5.3) -----------------------------------------------------------------------------------

## A ProgressBar with a centred text label. Returns [bar, label].
static func bar(color: Color, height := 22.0) -> Array:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.custom_minimum_size = Vector2(0, height)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = token(&"panel_inner")
	bg.border_color = token(&"groove")
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(2)
	b.add_theme_stylebox_override("background", bg)
	var grad := Gradient.new()
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 4
	tex.height = maxi(int(height), 4)
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	var fill := StyleBoxTexture.new()
	fill.texture = tex
	b.add_theme_stylebox_override("fill", fill)
	b.set_meta(&"fill_gradient", grad)
	set_bar_color(b, color)
	var ticks := Control.new()
	ticks.name = "Ticks"
	ticks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ticks.set_anchors_preset(Control.PRESET_FULL_RECT)
	ticks.draw.connect(_draw_ticks.bind(ticks))
	b.add_child(ticks)
	var text := label("", 13)
	text.add_theme_font_override("font", number_font())
	text.add_theme_color_override("font_color", token(&"text"))
	text.set_anchors_preset(Control.PRESET_FULL_RECT)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	b.add_child(text)
	return [b, text]


static func _draw_ticks(c: Control) -> void:
	var s := c.size
	c.draw_line(Vector2(1, 1.5), Vector2(s.x - 1, 1.5), Color(0, 0, 0, 0.35), 1.0)
	for f: float in [0.25, 0.5, 0.75]:
		var x: float = roundf(s.x * f) + 0.5
		c.draw_line(Vector2(x, 1), Vector2(x, s.y - 1), Color(0, 0, 0, 0.35), 1.0)


## Recolour the gradient fill of a bar made by bar(): top 40 % lightened 0.25, bottom darkened 0.15.
static func set_bar_color(b: ProgressBar, color: Color) -> void:
	var grad: Gradient = b.get_meta(&"fill_gradient", null)
	if grad == null:
		return
	if b.has_meta(&"fill_color") and b.get_meta(&"fill_color") == color:
		return
	b.set_meta(&"fill_color", color)
	var light := color.lightened(0.25)
	grad.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	grad.colors = PackedColorArray([light, color.lerp(light, 0.4), color.darkened(0.15)])


static func bar_color(b: ProgressBar) -> Color:
	return b.get_meta(&"fill_color", Color.WHITE)


# --- Tooltips (8) ---------------------------------------------------------------------------------

## Builds the section-8 tooltip from an unchanged tooltip_text: line 1 name (+ key badge / rank), line 2 numbers,
## then description; reason lines in WARN, "Ctrl+" learn hints in gold, "Active:" in trim_glow.
static func make_tooltip(text: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var lines := text.split("\n")
	for i in lines.size():
		var line: String = lines[i]
		if i == 0:
			box.add_child(_tooltip_title(line))
			continue
		var l := panel_label(line, 13, token(&"text") if i == 1 else token(&"text_muted"))
		if _is_reason(line):
			l.add_theme_color_override("font_color", WARN)
		elif line.begins_with("Ctrl+"):
			l.add_theme_color_override("font_color", GOLD)
		elif line.begins_with("Active:"):
			l.add_theme_color_override("font_color", token(&"trim_glow"))
		if line.length() > 44:
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size.x = 304
		box.add_child(l)
	return box


static func _is_reason(line: String) -> bool:
	for p: String in ["Not enough", "Population cap", "No shop", "Needs ", "Not learned", "Cannot", "Can't"]:
		if line.begins_with(p):
			return true
	return false


static func _tooltip_title(line: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var name_part := line
	var key := ""
	var rest := ""
	var open := line.find("[")
	var close := line.find("]", open) if open >= 0 else -1
	if open > 0 and close > open:
		name_part = line.substr(0, open).strip_edges()
		key = line.substr(open + 1, close - open - 1)
		rest = line.substr(close + 1).strip_edges()
	row.add_child(display_label(name_part, 15))
	if key != "":
		var badge := PanelContainer.new()
		var st := StyleBoxFlat.new()
		st.bg_color = GOLD
		st.set_corner_radius_all(2)
		st.content_margin_left = 3
		st.content_margin_right = 3
		badge.add_theme_stylebox_override("panel", st)
		badge.add_child(panel_label(key, 11, Color.BLACK))
		badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(badge)
	if rest != "":
		var r := panel_label(rest, 12, WARN if rest.contains("Not learned") else token(&"text_muted"))
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(r)
	return row


## Theme for the HUD root: tooltip panel in the slate style, on top of the game Theme (U7 fonts) when present.
static func hud_theme() -> Theme:
	var t := Theme.new()
	var game := game_theme()
	if game != null:
		t.merge_with(game)
		t.default_font = game.default_font
	t.set_stylebox(&"panel", &"TooltipPanel", tooltip_style())
	t.set_color(&"font_color", &"TooltipLabel", token(&"text"))
	t.set_font_size(&"font_size", &"TooltipLabel", 13)
	return t


# --- Legacy helpers (names kept) ------------------------------------------------------------------

## Flat skinned panel (menus and anything not on the heavy frame).
static func panel_style(margin := 10.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = token(&"panel_bg")
	style.border_color = token(&"frame_metal")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(margin)
	return style


static func panel(parent: Control, margin := 10.0) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", panel_style(margin))
	parent.add_child(p)
	return p


## Flat dark button style; `border` is the frame colour (gold for a pending order).
static func button_style(border: Color, bg := Color(0.14, 0.12, 0.16, 0.95)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(4)
	return s


## "Flame Guard" -> "FG", "Shade" -> "SH".
static func abbrev(display_name: String) -> String:
	var words := display_name.strip_edges().split(" ", false)
	if words.is_empty():
		return "?"
	if words.size() == 1:
		return words[0].left(2).to_upper()
	return (words[0].left(1) + words[1].left(1)).to_upper()


## The kingdom's signature colour (menu cards, emblems). Never skinned.
static func kingdom_color(k: StringName) -> Color:
	return KINGDOM_COLORS.get(k, KINGDOM_COLORS[&"fire"])


## Draws a kingdom emblem centred on `c` (fits a circle of `radius`; the ring is drawn at `radius`).
## Fire: three flames in a ring; Shadow: crescent over a spire; Ice: snowflake in a ring; Nature: a leaf
## with two sprouts in a ring. `col` fills the shapes; veins use `detail` (default: col darkened).
## Every filled shape comes from emblem_polygons() (simple, counter-clockwise, no duplicate points).
static func draw_emblem(ci: CanvasItem, k: StringName, c: Vector2, radius: float, col: Color,
		detail := Color(0, 0, 0, 0)) -> void:
	var s := radius / 56.0
	if detail.a <= 0.0:
		detail = Color(col.darkened(0.55), col.a)
	if k != &"shadow":
		ci.draw_arc(c, radius, 0.0, TAU, 48, col, 5.0 * s, true)
	for poly: PackedVector2Array in emblem_polygons(k, c, radius):
		if poly.size() >= 3:
			ci.draw_colored_polygon(poly, col)
	match k:
		&"shadow":
			ci.draw_line(c + Vector2(-10, 22) * s, c + Vector2(10, 22) * s, col, 3.0 * s, true)
		&"ice":
			for i in 6:
				var d := Vector2.from_angle(i * TAU / 6.0 - PI * 0.5)
				ci.draw_line(c, c + d * 44.0 * s, col, 5.0 * s, true)
				for side: float in [-1.0, 1.0]:
					ci.draw_line(c + d * 26.0 * s, c + (d * 26.0 + d.rotated(side * 0.8) * 14.0) * s, col, 4.0 * s, true)
		&"nature":
			var base := c + Vector2(0, 30) * s
			for tip: Vector2 in [Vector2(4, -44), Vector2(-34, 10), Vector2(34, 6)]:
				var axis := c + tip * s - base
				ci.draw_line(base + axis * 0.08, base + axis * 0.85, detail,
						maxf(1.0, (20.0 if tip.y < 0.0 else 9.0) * s * 0.14), true)
			ci.draw_line(base, c + Vector2(0, 46) * s, col, 5.0 * s, true)


## The filled shapes of a kingdom emblem (see draw_emblem). Each one is cleaned by _clean_polygon, so
## draw_colored_polygon can always triangulate it; a shape that would be degenerate (tiny sizes) is left out.
static func emblem_polygons(k: StringName, c: Vector2, radius: float) -> Array[PackedVector2Array]:
	var s := radius / 56.0
	var raw: Array[PackedVector2Array] = []
	match k:
		&"shadow":
			raw.append(PackedVector2Array([c + Vector2(-7, 50) * s, c + Vector2(7, 50) * s,
					c + Vector2(2.5, 2) * s, c + Vector2(0, -6) * s, c + Vector2(-2.5, 2) * s]))
			raw.append(_crescent(c + Vector2(-4, -20) * s, 26.0 * s, c + Vector2(7, -28) * s, 22.0 * s))
		&"ice":
			pass   # lines only
		&"nature":
			var base := c + Vector2(0, 30) * s
			raw.append(_leaf_points(base, c + Vector2(4, -44) * s, 20.0 * s))
			raw.append(_leaf_points(base, c + Vector2(-34, 10) * s, 9.0 * s))
			raw.append(_leaf_points(base, c + Vector2(34, 6) * s, 9.0 * s))
		_:
			for i in 3:
				var x := (i - 1) * 22.0
				var h := 60.0 if i == 1 else 42.0
				raw.append(PackedVector2Array([c + Vector2(x - 12, 30) * s,
						c + Vector2(x - 8, 30 - h * 0.5) * s, c + Vector2(x, 30 - h) * s,
						c + Vector2(x + 8, 30 - h * 0.5) * s, c + Vector2(x + 12, 30) * s]))
	var out: Array[PackedVector2Array] = []
	for poly in raw:
		var clean := _clean_polygon(poly)
		if clean.size() >= 3:
			out.append(clean)
	return out


## Drops points closer than 0.3 px to the previous one (and a closing duplicate), makes the winding
## counter-clockwise, and returns an empty array if the result still can't be triangulated.
static func _clean_polygon(poly: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in poly:
		if out.is_empty() or out[out.size() - 1].distance_to(p) > 0.3:
			out.append(p)
	while out.size() > 3 and out[0].distance_to(out[out.size() - 1]) <= 0.3:
		out.remove_at(out.size() - 1)
	if out.size() < 3:
		return PackedVector2Array()
	if Geometry2D.is_polygon_clockwise(out):
		out.reverse()
	if Geometry2D.triangulate_polygon(out).is_empty():
		return PackedVector2Array()
	return out


## The crescent = disc A (centre `ca`, radius `ra`) minus disc B: the largest outline Geometry2D returns.
static func _crescent(ca: Vector2, ra: float, cb: Vector2, rb: float) -> PackedVector2Array:
	var best := PackedVector2Array()
	var best_area := 0.0
	for poly: PackedVector2Array in Geometry2D.clip_polygons(_circle(ca, ra, 40), _circle(cb, rb, 40)):
		var area := absf(_area(poly))
		if area > best_area:
			best_area = area
			best = poly
	return best


static func _circle(c: Vector2, r: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		pts.append(c + Vector2.from_angle(TAU * i / n) * r)
	return pts


static func _area(poly: PackedVector2Array) -> float:
	var a := 0.0
	for i in poly.size():
		a += poly[i].cross(poly[(i + 1) % poly.size()])
	return a * 0.5


## A pointed leaf outline from `base` to `tip`, `half_width` at its widest (a little narrower on one side).
static func _leaf_points(base: Vector2, tip: Vector2, half_width: float) -> PackedVector2Array:
	var axis := tip - base
	var side := axis.orthogonal().normalized()
	var pts := PackedVector2Array()
	var n := 12
	for i in n + 1:
		var t := float(i) / n
		pts.append(base + axis * t + side * sin(PI * t) * half_width)
	for i in range(n - 1, 0, -1):
		var t := float(i) / n
		pts.append(base + axis * t - side * sin(PI * t) * half_width * 0.85)
	return pts

## Green above 50 %, yellow above 25 %, else red.
static func health_color(ratio: float) -> Color:
	if ratio > 0.5:
		return Color(0.3, 0.9, 0.35)
	if ratio > 0.25:
		return Color(0.95, 0.85, 0.25)
	return WARN
