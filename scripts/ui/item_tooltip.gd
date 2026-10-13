class_name ItemTooltip
extends PanelContainer
## Item tooltip (items.md "HUD": tooltip format, tier colours) shared by the inventory bar and ground items.
##   Blazing Edge  [Num 2]
##   +20 damage · -12 % attack cooldown
##   Searing Strikes: attacks burn for 16 over 2 s.
##   Sell 325
## Actives add `Active: ... · 60 s cooldown`, consumables `2 charges`, artifacts `Artifact (cannot be sold)`.
## The static helpers read an ItemType untyped (`get`, `has_method`), so this compiles before the items code exists.

const TIER_NAMES: Array[StringName] = [&"component", &"mid", &"top", &"consumable", &"artifact"]
const TIER_COLORS := {
	&"component": Color(0.85, 0.85, 0.85),
	&"mid": Color(0.30, 0.75, 1.00),
	&"top": Color(1.00, 0.60, 0.20),
	&"consumable": Color(0.40, 0.90, 0.40),
	&"artifact": Color(1.00, 0.85, 0.30),
}
const EMPTY_COLOR := Color(0.3, 0.3, 0.3)
## Stat key -> [label, is percent]. `_pct` keys are fractions (-0.12 = "-12 %").
const STAT_LABELS := {
	&"attack_damage": "damage",
	&"attack_damage_pct": "% damage",
	&"attack_cooldown_pct": "% attack cooldown",
	&"max_hp": "HP",
	&"max_mana": "mana",
	&"hp_regen": "HP / s",
	&"mana_regen": "mana / s",
	&"move_speed": "speed",
	&"armor": "armor",
	&"spell_power": "% spell power",
	&"cooldown_reduction": "% cooldown reduction",
}

var text_label: Label   ## Holds the raw text (hidden); the styled lines are built from it.
var _lines: VBoxContainer
var _shown_text := ""


func _ready() -> void:
	var style := HudSkin.slate_style(8.0, true)
	style.bg_color.a = 0.96   # opaque: the hero column's bars must not show through
	add_theme_stylebox_override("panel", style)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_level = true
	z_index = 20
	visible = false
	text_label = UIStyle.label("", 13)
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_label.visible = false
	add_child(text_label)
	_lines = VBoxContainer.new()
	_lines.add_theme_constant_override("separation", 1)
	_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_lines)


## Shows `text` with its bottom-left corner at `anchor` (kept on screen).
## `title_color` = the item's tier colour for line 1 (transparent = the skin's title colour).
func show_text(text: String, anchor: Vector2, title_color := Color(0, 0, 0, 0)) -> void:
	if text_label == null:
		return
	text_label.text = text
	var key := text + title_color.to_html()
	if key != _shown_text:
		_shown_text = key
		HudSkin.fill_tooltip_lines(_lines, text, title_color if title_color.a > 0.0 else HudSkin.token(&"title"), true)
	visible = true
	reset_size()
	var screen := get_viewport_rect().size
	var pos := anchor - Vector2(0, size.y)
	pos.x = clampf(pos.x, 4.0, maxf(4.0, screen.x - size.x - 4.0))
	pos.y = clampf(pos.y, 4.0, maxf(4.0, screen.y - size.y - 4.0))
	global_position = pos


func hide_tip() -> void:
	visible = false


# ---------------------------------------------------------------- ItemType helpers (untyped)

static func field(type: Variant, key: StringName, default: Variant = null) -> Variant:
	if type == null or not (type is Object) or not is_instance_valid(type):
		return default
	var v: Variant = (type as Object).get(key)
	return default if v == null else v


static func display_name(type: Variant) -> String:
	var n := str(field(type, &"display_name", ""))
	if n == "":
		n = str(field(type, &"id", "?")).capitalize()
	return n


## "component" / "mid" / "top" / "consumable" / "artifact" (the enum index or a name).
static func tier(type: Variant) -> StringName:
	if bool(field(type, &"is_artifact", false)):
		return &"artifact"
	var t: Variant = field(type, &"tier", 0)
	if t is int:
		return TIER_NAMES[clampi(t, 0, TIER_NAMES.size() - 1)]
	return StringName(str(t).to_lower())


static func tier_color(type: Variant) -> Color:
	if type == null:
		return EMPTY_COLOR
	return TIER_COLORS.get(tier(type), TIER_COLORS[&"component"])


static func abbrev(type: Variant) -> String:
	var a := str(field(type, &"icon_abbrev", ""))
	return a if a != "" else UIStyle.abbrev(display_name(type))


static func total_cost(type: Variant) -> int:
	if is_instance_valid(type) and type is Object and (type as Object).has_method(&"total_cost"):
		return int((type as Object).call(&"total_cost"))
	return int(field(type, &"cost", 0))


## True when the item has an active (a key / click does something).
static func has_active(type: Variant) -> bool:
	var a := str(field(type, &"active_id", ""))
	return a != "" or tier(type) == &"consumable"


## "none" / "self" / "point" (enum index or name).
static func active_target(type: Variant) -> StringName:
	var t: Variant = field(type, &"active_target", 0)
	if t is int:
		return [&"none", &"self", &"point"][clampi(t, 0, 2)]
	return StringName(str(t).to_lower())


## "+20 damage · -12 % attack cooldown".
static func stats_line(type: Variant) -> String:
	var stats: Variant = field(type, &"stats", {})
	if not (stats is Dictionary):
		return ""
	var parts: PackedStringArray = []
	for key in (stats as Dictionary):
		var value := float(stats[key])
		var label := Loc.t(str(STAT_LABELS.get(StringName(key), str(key).replace("_", " "))))
		if str(key).ends_with("_pct"):
			value *= 100.0
		var sign := "+" if value >= 0.0 else "-"
		var number := str(snappedf(absf(value), 0.1)).trim_suffix(".0")
		if Loc.is_french():
			number = number.replace(".", ",")
		parts.append("%s%s %s" % [sign, number, label])
	return " · ".join(parts)


## The whole tooltip. `key_label` ("Num 2") is shown in brackets after the name when not empty.
static func describe(type: Variant, key_label := "", count := 1) -> String:
	if type == null:
		return ""
	var lines: PackedStringArray = []
	var title := display_name(type)
	if key_label != "":
		title += "  [%s]" % key_label
	lines.append(title)
	var stats := stats_line(type)
	if stats != "":
		lines.append(stats)
	var extra := str(field(type, &"tooltip", "")).strip_edges()
	if extra != "":
		lines.append(Loc.sink(extra))   # the item text (data) in the player's language (game_data.po)
	var active := str(field(type, &"active_id", ""))
	var cooldown := float(field(type, &"active_cooldown", 0.0))
	if active != "" and not extra.contains("Active:"):
		var active_name := Loc.sink(active.capitalize())   # U2-7: the active's name (from data) through the sink
		if cooldown > 0.0:
			lines.append(Loc.t("Active: {name} · {n} s cooldown", {"name": active_name, "n": int(round(cooldown))}))
		else:
			lines.append(Loc.t("Active: {name}", {"name": active_name}))
	var t := tier(type)
	if t == &"consumable":
		lines.append(Loc.tn("{n} charge", "{n} charges", count))
	if t == &"artifact" or bool(field(type, &"campaign_only", false)):
		lines.append(Loc.t("Artifact (cannot be sold)"))
	else:
		lines.append(Loc.t("Sell {n}", {"n": int(floor(total_cost(type) * 0.5)) * maxi(count, 1)}))
	return "\n".join(lines)


# ---------------------------------------------------------------- skin (6.U2)

## Visual helpers for the command card, inventory, shop and tooltips (docs/design/ui-style.md 3.3, 6, 8).
## Uses `UIStyle` (6.U1) when it offers the piece (kingdom tokens as static vars, `frame_style()`,
## `slate_style()`, `display_font()`), else builds the same look here from the spec's Fire / Shadow tokens.
class HudSkin extends RefCounted:
	const UI_STYLE_PATH := "res://scripts/ui/ui_style.gd"
	const ICON_LIBRARY_PATH := "res://art/icons/icon_library.gd"
	const GOLD := Color(1.0, 0.85, 0.4)
	const WARN := Color(0.95, 0.35, 0.3)
	const CRYSTAL_TEXT := Color(0.75, 0.92, 1.0)
	const SWEEP_COLOR := Color(0, 0, 0, 0.65)
	const FIRE := {
		&"frame_metal": Color(0.62, 0.40, 0.16), &"frame_light": Color(0.85, 0.62, 0.30),
		&"frame_dark": Color(0.36, 0.22, 0.09), &"groove": Color(0.04, 0.03, 0.03),
		&"trim_glow": Color(1.00, 0.55, 0.15), &"panel_bg": Color(0.10, 0.08, 0.09, 0.92),
		&"panel_inner": Color(0.14, 0.11, 0.11), &"slate_bg": Color(0.06, 0.05, 0.08, 0.72),
		&"title": Color(1.00, 0.80, 0.45), &"text": Color(0.94, 0.92, 0.88), &"text_muted": Color(0.66, 0.60, 0.55),
	}
	const SHADOW := {
		&"frame_metal": Color(0.55, 0.52, 0.66), &"frame_light": Color(0.78, 0.76, 0.88),
		&"frame_dark": Color(0.30, 0.28, 0.40), &"groove": Color(0.03, 0.02, 0.05),
		&"trim_glow": Color(0.70, 0.30, 1.00), &"panel_bg": Color(0.09, 0.07, 0.13, 0.92),
		&"panel_inner": Color(0.13, 0.11, 0.18), &"slate_bg": Color(0.05, 0.04, 0.09, 0.72),
		&"title": Color(0.85, 0.70, 1.00), &"text": Color(0.92, 0.92, 0.96), &"text_muted": Color(0.60, 0.58, 0.70),
	}
	## Reason words that make a tooltip line red.
	const REASONS := ["Not enough", "On cooldown", "Dead", "Not learned", "Needs", "Population", "No shop",
			"can't", "Max rank", "Inventory full", "Not sold", "cannot"]

	static var _ui: Script = null
	static var _ui_methods := {}
	static var _frames := {}
	static var _icons := {}
	static var _display_font: Font = null

	static func _style_script() -> Script:
		if _ui == null and ResourceLoader.exists(UI_STYLE_PATH):
			_ui = load(UI_STYLE_PATH)
			if _ui != null:
				for m in _ui.get_script_method_list():
					_ui_methods[StringName(m.get("name", ""))] = true
		return _ui

	static func ui_has(method: StringName) -> bool:
		_style_script()
		return _ui_methods.has(method)

	## &"fire" (default) / &"shadow" / &"ice" / &"nature": `UIStyle.get_kingdom()` (or `UIStyle.kingdom`).
	static func kingdom() -> StringName:
		var s := _style_script()
		var k: Variant = s.get(&"kingdom") if s != null else null
		if k == null and ui_has(&"get_kingdom"):
			k = s.call(&"get_kingdom")
		return StringName(str(k)) if k != null and str(k) != "" else &"fire"

	## A kingdom token of ui-style.md section 1 (`frame_metal`, `trim_glow`, `panel_inner`, `title`...).
	static func token(name: StringName) -> Color:
		var s := _style_script()
		if s != null:
			var v: Variant = s.get(name)
			if v is Color:
				return v
			if ui_has(&"token"):
				v = s.call(&"token", name)
				if v is Color:
					return v
		var table: Dictionary = SHADOW if kingdom() == &"shadow" else FIRE
		return table.get(name, Color.MAGENTA)

	## The display font (Cinzel when 6.U1 ships it, else the no-file alternative: default font, embolden 0.8,
	## glyph spacing 1; callers uppercase the text).
	static func display_font() -> Font:
		if ui_has(&"display_font"):
			var f: Variant = _style_script().call(&"display_font")
			if f is Font:
				return f
		if _display_font == null:
			var fv := FontVariation.new()
			fv.base_font = ThemeDB.fallback_font
			fv.variation_embolden = 0.8
			fv.spacing_glyph = 1
			_display_font = fv
		return _display_font

	## A label with no outline (inside framed panels); `display` = the title font, uppercased.
	static func text(value: String, font_size: int, color: Color, display := false, outline := false) -> Label:
		var l := Label.new()
		l.text = value
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.add_theme_font_size_override("font_size", font_size)
		l.add_theme_color_override("font_color", color)
		if display:
			l.add_theme_font_override("font", display_font())
			l.uppercase = true
		if outline:
			l.add_theme_color_override("font_outline_color", Color.BLACK)
			l.add_theme_constant_override("outline_size", 3)
		return l

	# ------------------------------------------------------------ frames

	## The heavy panel frame (3.1): `UIStyle.frame_style()` when it exists, else a 48 x 48 image, margins 16.
	static func frame_style(margin := 10.0) -> StyleBox:
		var sb: StyleBox = null
		if ui_has(&"frame_style"):
			var v: Variant = _style_script().call(&"frame_style")
			if v is StyleBox:
				sb = (v as StyleBox).duplicate()
		if sb == null:
			var key := "heavy|%s" % kingdom()
			if not _frames.has(key):
				_frames[key] = _heavy_frame_texture()
			var st := StyleBoxTexture.new()
			st.texture = _frames[key]
			st.set_texture_margin_all(16)
			st.draw_center = true
			sb = st
		sb.set_content_margin_all(margin)
		return sb

	static func _heavy_frame_texture() -> ImageTexture:
		var n := 48
		var bg := token(&"panel_bg")
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		img.fill(bg)
		_ring(img, 0, Color(0, 0, 0, 0.55), Color(0, 0, 0, 0.55))
		_ring(img, 1, token(&"frame_light"), token(&"frame_dark"))
		_ring(img, 2, token(&"frame_metal"), token(&"frame_metal"))
		_ring(img, 3, token(&"frame_metal"), token(&"frame_metal"))
		_ring(img, 4, token(&"groove"), token(&"groove"))
		var trim := bg.blend(Color(token(&"trim_glow"), 0.55))
		_ring(img, 5, trim, trim)
		var shade := bg.lerp(token(&"groove"), 0.5)
		shade.a = bg.a
		_ring(img, 6, shade, shade)
		for corner in [Vector2i(5, 5), Vector2i(n - 6, 5), Vector2i(5, n - 6), Vector2i(n - 6, n - 6)]:
			for dy in range(-4, 5):
				for dx in range(-4, 5):
					if absi(dx) + absi(dy) > 4:
						continue
					var c := token(&"frame_light")
					if dx + dy >= 3:
						c = token(&"frame_dark")
					if dx == 0 and dy == 0:
						c = token(&"trim_glow")
					img.set_pixel(corner.x + dx, corner.y + dy, c)
		return ImageTexture.create_from_image(img)

	## Ring `r` px in from the edge: top + left rows `tl`, bottom + right rows `br`.
	static func _ring(img: Image, r: int, tl: Color, br: Color) -> void:
		var n := img.get_width()
		for i in range(r, n - r):
			img.set_pixel(i, r, tl)
			img.set_pixel(r, i, tl)
			img.set_pixel(i, n - 1 - r, br)
			img.set_pixel(n - 1 - r, i, br)

	## The slate (3.2): tooltips get the `frame_metal` border.
	static func slate_style(margin := 10.0, tooltip := false) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = token(&"slate_bg")
		s.border_color = token(&"frame_metal") if tooltip else token(&"frame_dark")
		s.set_border_width_all(1)
		s.set_corner_radius_all(2)
		s.set_content_margin_all(margin)
		return s

	## A button / slot frame (3.3): 24 x 24 image, margins 8; rim = px 1-2 (bevel lit on top / left).
	static func slot_frame(rim: Color, inside: Color) -> StyleBoxTexture:
		var key := "slot|%s|%s" % [rim.to_html(), inside.to_html()]
		if not _frames.has(key):
			var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
			img.fill(inside)
			_ring(img, 0, Color(0, 0, 0, 0.8), Color(0, 0, 0, 0.8))
			_ring(img, 1, rim.lightened(0.3), rim.darkened(0.4))
			_ring(img, 2, rim, rim)
			_ring(img, 3, token(&"groove"), token(&"groove"))
			_frames[key] = ImageTexture.create_from_image(img)
		var st := StyleBoxTexture.new()
		st.texture = _frames[key]
		st.set_texture_margin_all(8)
		st.set_content_margin_all(4)
		return st

	## The 5 states of 3.3 for a normal rim `rim` (default `frame_metal`; tier colours for item slots).
	static func state_frames(rim := Color(0, 0, 0, 0)) -> Dictionary:
		var metal := rim.a <= 0.0
		var r := token(&"frame_metal") if metal else rim
		var inner := token(&"panel_inner")
		return {
			"normal": slot_frame(r, inner),
			"hover": slot_frame(token(&"frame_light") if metal else r.lightened(0.35), inner.lightened(0.12)),
			"pressed": slot_frame(token(&"frame_dark") if metal else r.darkened(0.35), inner.darkened(0.25)),
			"disabled": slot_frame(token(&"frame_dark") if metal else r.darkened(0.3), inner),
		}

	static func style_button(b: Button, rim := Color(0, 0, 0, 0)) -> void:
		var states := state_frames(rim)
		for state in states:
			b.add_theme_stylebox_override(state, states[state])
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.add_theme_color_override("font_color", token(&"text"))
		b.add_theme_color_override("font_hover_color", token(&"text"))
		b.add_theme_color_override("font_pressed_color", token(&"text"))
		b.add_theme_color_override("font_disabled_color", token(&"text"))

	## The gold "selected / pending" frames (all states gold).
	static func style_button_selected(b: Button) -> void:
		var inner := token(&"panel_inner")
		for state in ["normal", "hover", "pressed", "disabled"]:
			b.add_theme_stylebox_override(state, slot_frame(GOLD, inner.lightened(0.06) if state == "hover" else inner))

	## The hotkey badge (6.2): black 0.75 bg, 1 px `frame_dark` border, radius 2; gold when `active`.
	static func badge_style(active := false) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = GOLD if active else Color(0, 0, 0, 0.75)
		s.border_color = token(&"frame_dark")
		s.set_border_width_all(1)
		s.set_corner_radius_all(2)
		s.content_margin_left = 3
		s.content_margin_right = 3
		s.content_margin_top = 0
		s.content_margin_bottom = 0
		return s

	# ------------------------------------------------------------ drawing

	## The radial cooldown sweep (6.2): a dark fan from 12 o'clock clockwise over the remaining `ratio`,
	## cut to `rect`, with a 1 px `trim_glow` edge on its leading radius.
	static func draw_sweep(ci: CanvasItem, rect: Rect2, ratio: float) -> void:
		if ratio <= 0.0:
			return
		if ratio >= 0.999:
			ci.draw_rect(rect, SWEEP_COLOR)
			return
		var c := rect.get_center()
		var h := rect.size * 0.5
		var start := (1.0 - ratio) * TAU
		var angles: Array[float] = []
		var steps := maxi(2, ceili(36.0 * ratio))
		for k in steps + 1:
			angles.append(lerpf(start, TAU, float(k) / steps))
		var corner := atan2(h.x, h.y)
		for a in [corner, PI - corner, PI + corner, TAU - corner]:
			if a > start and a < TAU:
				angles.append(a)
		angles.sort()
		var pts := PackedVector2Array([c])
		for a in angles:
			pts.append(_on_rect(c, h, a))
		ci.draw_colored_polygon(pts, SWEEP_COLOR)
		ci.draw_line(c, _on_rect(c, h, start), Color(token(&"trim_glow"), 0.9), 1.0)

	static func _on_rect(c: Vector2, h: Vector2, a: float) -> Vector2:
		var d := Vector2(sin(a), -cos(a))
		var m := maxf(absf(d.x) / h.x, absf(d.y) / h.y)
		return c + d / m

	## A dashed rectangle outline (the Sell zone).
	static func draw_dashed_rect(ci: CanvasItem, rect: Rect2, color: Color, dash := 6.0) -> void:
		var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
		for i in 4:
			var a: Vector2 = corners[i]
			var b: Vector2 = corners[(i + 1) % 4]
			var length := a.distance_to(b)
			var t := 0.0
			while t < length:
				ci.draw_line(a.lerp(b, t / length), a.lerp(b, minf(t + dash, length) / length), color, 1.0)
				t += dash * 2.0

	## Icon from `art/icons/` (IconLibrary.icon_for when it exists, else `<kind>/<id>.png`), or null.
	static func icon(kind: String, id: String) -> Texture2D:
		var key := kind + "/" + id
		if _icons.has(key):
			return _icons[key]
		var tex: Texture2D = null
		if ResourceLoader.exists(ICON_LIBRARY_PATH):
			var lib: Variant = load(ICON_LIBRARY_PATH)
			if lib is Script:
				for m in (lib as Script).get_script_method_list():
					if m.get("name") == "icon_for":
						var t: Variant = (lib as Script).call(&"icon_for", kind, id)
						if t is Texture2D:
							tex = t
						break
		if tex == null:
			var path := "res://art/icons/%s/%s.png" % [kind, id]
			if ResourceLoader.exists(path):
				tex = load(path) as Texture2D
		_icons[key] = tex
		return tex

	# ------------------------------------------------------------ tooltips (section 8)

	## Fills `box` with the styled lines of a tooltip `text` (the unchanged `tooltip_text` string).
	static func fill_tooltip_lines(box: Container, value: String, title_color: Color, item := false) -> void:
		for child in box.get_children():
			box.remove_child(child)
			child.queue_free()
		value = Loc.sink(value)   # an English tooltip_text shows in the player's language (localization.md)
		# Line markers in the language shown.
		var active_p := Loc.t("Active: {name}").get_slice("{", 0)
		var sell_p := Loc.t("Sell {n}").get_slice("{", 0)
		var cost_p := Loc.t("Cost {n}").get_slice("{", 0)
		var artifact_p := Loc.t("Artifact (cannot be sold)")
		var lines := value.split("\n")
		for i in lines.size():
			var line := lines[i]
			if i == 0:
				box.add_child(_title_row(line, title_color))
				continue
			var color := token(&"text_muted")
			var size := 13
			if item:
				if line.begins_with("Active:") or line.begins_with(active_p):
					color = token(&"trim_glow")
				elif line.begins_with("Sell ") or line.begins_with("Artifact") or line.begins_with(sell_p) \
						or line == artifact_p:
					size = 12
				elif i == 1 and (line.begins_with("+") or line.begins_with("-")):
					color = token(&"text")
			else:
				if line.begins_with("Ctrl+"):
					color = GOLD
				elif _is_reason(line):
					color = WARN
				elif i == 1 or line.begins_with("Cost ") or line.begins_with(cost_p):
					color = token(&"text")
			var l := text(line, size, color)
			if line.length() > 44:
				l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				l.custom_minimum_size.x = 304
			box.add_child(l)

	static func _is_reason(line: String) -> bool:
		for r: String in REASONS:
			if line.begins_with(r) or (r == "can't" and line.contains(r)):
				return true
			if Loc.is_french():   # the French reason starts (same msgids, data/i18n/fr/ui_hud_windows.po)
				var fr := Loc.t(r)
				if fr != r and (line.begins_with(fr) or (r in ["can't", "cannot"] and line.contains(fr))):
					return true
		return false

	## Line 1: name (display font 15), the key in an inline gold badge, `Rank n / m` / `Not learned` right.
	static func _title_row(line: String, title_color: Color) -> Control:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var name := line
		var key := ""
		var rest := ""
		var open := line.find("  [")
		var close := line.find("]", open) if open >= 0 else -1
		if open >= 0 and close > open:
			name = line.left(open)
			key = line.substr(open + 3, close - open - 3)
			rest = line.substr(close + 1).strip_edges()
		else:
			var paren := line.find("  (")
			if paren >= 0:
				name = line.left(paren)
				rest = line.substr(paren + 2).strip_edges()
		row.add_child(text(name, 15, title_color, true))
		if key != "":
			var k := text(key, 11, Color.BLACK)
			k.add_theme_stylebox_override("normal", badge_style(true))
			k.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(k)
		if rest != "":
			var spacer := Control.new()
			spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			spacer.custom_minimum_size.x = 8
			row.add_child(spacer)
			row.add_child(text(rest, 12, WARN if rest.begins_with("Not learned") or rest.begins_with(Loc.t("Not learned"))
					else token(&"text_muted")))
		return row

	## A custom tooltip panel (for `_make_custom_tooltip`).
	static func tooltip_panel(value: String, title_color := Color(0, 0, 0, 0), item := false) -> Control:
		if value == "":
			return null
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", slate_style(8.0, true))
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 1)
		p.add_child(box)
		fill_tooltip_lines(box, value, title_color if title_color.a > 0.0 else token(&"title"), item)
		return p
