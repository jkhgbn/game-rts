class_name UILabChecks
extends RefCounted
## UI Lab (docs/plan/ui-lab.md): the measurements on a live Control tree. Pure functions: give them the scope root
## (a Control or a CanvasLayer), the viewport rect and (optional) the screenshot Image; each returns a list of
## "items" (dictionaries with `node`, `text`, `value`, `detail`). The runner turns the counts into scorecard checks.
## Thresholds live in the constants below (one place to tune).

const MIN_FONT_WARN := 11          ## Effective font size (px) under this = WARN item.
const MIN_FONT_FAIL := 9           ## ... under this = FAIL item.
const CONTRAST_SMALL := 4.5        ## WCAG AA small text.
const CONTRAST_LARGE := 3.0        ## WCAG AA large text (>= 24 px, or >= 19 px bold / display font).
const CONTRAST_HARD_FACTOR := 0.67 ## Below rule x this = FAIL item (4.5 -> 3.0, 3.0 -> 2.0), else WARN item.
const LARGE_TEXT_PX := 24
const OVERLAP_MIN_PX2 := 24.0      ## Intersections smaller than this are ignored (anti-aliasing, 1 px borders).
const OVERLAP_MIN_FRAC := 0.12     ## ... and smaller than this share of the smaller rect.
const OVERFLOW_TOL_PX := 2.0       ## Text may stick out of its frame by this much.
const SHORT_BUTTON_TEXT := 3       ## Buttons with text this short (abbreviations, icons) must have a tooltip.


# ---------------------------------------------------------------- collection

## Every visible Control under `scope` (itself included when it is a Control), skipping hidden and fully transparent
## branches (modulate alpha < 0.05).
static func visible_controls(scope: Node) -> Array[Control]:
	var out: Array[Control] = []
	_collect(scope, out)
	return out


static func _collect(n: Node, out: Array[Control]) -> void:
	if n is CanvasLayer and not (n as CanvasLayer).visible:
		return
	if n is CanvasItem:
		var ci := n as CanvasItem
		if not ci.visible or ci.modulate.a < 0.05:
			return
		if n is Control:
			out.append(n as Control)
	if n is SubViewportContainer or n is SubViewport:
		return   # 3D backdrops: not UI
	for c in n.get_children():
		_collect(c, out)


## True for controls that show text the player must read. Decorative copies drawn behind their parent (glows) and
## text drawn fully transparent (a button whose abbreviation hides behind its icon) are not text to read.
static func is_text_control(c: Control) -> bool:
	if c.show_behind_parent:
		return false
	if not (c is Label or c is Button or c is RichTextLabel or c is LineEdit):
		return false
	if (font_color_of(c) * modulate_of(c)).a < 0.1:
		return false
	if c is Label:
		return (c as Label).text.strip_edges() != "" and (c as Label).visible_ratio > 0.0
	if c is Button:
		return (c as Button).text.strip_edges() != ""
	if c is RichTextLabel:
		return (c as RichTextLabel).get_parsed_text().strip_edges() != ""
	if c is LineEdit:
		return (c as LineEdit).text != "" or (c as LineEdit).placeholder_text != ""
	return false


static func is_interactive(c: Control) -> bool:
	return c is BaseButton or c is Range and not c is ProgressBar or c is LineEdit


## Product of modulate / self_modulate from the control up to the canvas root.
static func modulate_of(c: CanvasItem) -> Color:
	var m := c.self_modulate
	var n: Node = c
	while n != null and n is CanvasItem:
		m *= (n as CanvasItem).modulate
		n = n.get_parent()
	return m


static func text_of(c: Control) -> String:
	if c is Label:
		var l := c as Label
		return l.text.to_upper() if l.uppercase else l.text
	if c is Button:
		return (c as Button).text
	if c is RichTextLabel:
		return (c as RichTextLabel).get_parsed_text()
	if c is LineEdit:
		return (c as LineEdit).text if (c as LineEdit).text != "" else (c as LineEdit).placeholder_text
	return ""


static func font_of(c: Control) -> Font:
	if c is Label and (c as Label).label_settings != null and (c as Label).label_settings.font != null:
		return (c as Label).label_settings.font
	if c is RichTextLabel:
		return c.get_theme_font(&"normal_font")
	return c.get_theme_font(&"font")


static func font_size_of(c: Control) -> int:
	if c is Label and (c as Label).label_settings != null:
		return (c as Label).label_settings.font_size
	if c is RichTextLabel:
		return c.get_theme_font_size(&"normal_font_size")
	return c.get_theme_font_size(&"font_size")


## The size the player sees: font size x the control's global scale (canvas transform included).
static func effective_font_px(c: Control) -> float:
	var s := c.get_global_transform_with_canvas().get_scale()
	return float(font_size_of(c)) * minf(absf(s.x), absf(s.y))


static func font_color_of(c: Control) -> Color:
	if c is Label and (c as Label).label_settings != null:
		return (c as Label).label_settings.font_color
	if c is RichTextLabel:
		return c.get_theme_color(&"default_color")
	if c is Button:
		var b := c as Button
		if b.disabled:
			return b.get_theme_color(&"font_disabled_color")
		if b.toggle_mode and b.button_pressed:
			return b.get_theme_color(&"font_pressed_color")
	return c.get_theme_color(&"font_color")


static func outline_of(c: Control) -> Array:
	if c is Label and (c as Label).label_settings != null:
		var ls := (c as Label).label_settings
		return [ls.outline_size, ls.outline_color]
	if c is RichTextLabel:
		return [c.get_theme_constant(&"outline_size"), c.get_theme_color(&"font_outline_color")]
	return [c.get_theme_constant(&"outline_size"), c.get_theme_color(&"font_outline_color")]


## Width x height the text needs at its font (each line measured; no wrapping).
static func text_size(c: Control) -> Vector2:
	var f := font_of(c)
	if f == null:
		return Vector2.ZERO
	var fs := font_size_of(c)
	var w := 0.0
	var lines := text_of(c).split("\n")
	for line in lines:
		w = maxf(w, f.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	var sep := 0.0
	if c is Label:
		sep = float(c.get_theme_constant(&"line_spacing"))
	return Vector2(w, lines.size() * f.get_height(fs) + maxf(0, lines.size() - 1) * sep)


## The rect the text is drawn in, in canvas coordinates (alignment inside the control applied). Autowrapped labels
## use their own width and their line count.
static func text_rect(c: Control) -> Rect2:
	var local := Rect2(Vector2.ZERO, c.size)
	var ts := text_size(c)
	var sb: StyleBox = null
	if c is Label:
		sb = c.get_theme_stylebox(&"normal")
	elif c is Button:
		sb = c.get_theme_stylebox(&"normal")
	var inner := local
	if sb != null:
		inner = Rect2(local.position + Vector2(sb.get_margin(SIDE_LEFT), sb.get_margin(SIDE_TOP)),
				local.size - sb.get_minimum_size())
	var ha := HORIZONTAL_ALIGNMENT_LEFT
	var va := VERTICAL_ALIGNMENT_TOP
	if c is Label:
		var l := c as Label
		ha = l.horizontal_alignment
		va = l.vertical_alignment
		if l.autowrap_mode != TextServer.AUTOWRAP_OFF:
			var f := font_of(c)
			var lines := maxi(1, l.get_line_count())
			if l.max_lines_visible >= 0:
				lines = mini(lines, l.max_lines_visible)
			ts = Vector2(inner.size.x, lines * (f.get_height(font_size_of(c)) if f else 16.0))
	elif c is Button:
		ha = (c as Button).alignment
		va = VERTICAL_ALIGNMENT_CENTER
		if (c as Button).icon != null:
			ts.x += (c as Button).icon.get_width() + c.get_theme_constant(&"h_separation")
	elif c is RichTextLabel:
		return c.get_global_rect()
	var x := inner.position.x
	match ha:
		HORIZONTAL_ALIGNMENT_CENTER:
			x = inner.position.x + (inner.size.x - ts.x) * 0.5
		HORIZONTAL_ALIGNMENT_RIGHT:
			x = inner.end.x - ts.x
	var y := inner.position.y
	match va:
		VERTICAL_ALIGNMENT_CENTER:
			y = inner.position.y + (inner.size.y - ts.y) * 0.5
		VERTICAL_ALIGNMENT_BOTTOM:
			y = inner.end.y - ts.y
	var r := Rect2(Vector2(x, y), ts)
	return c.get_global_transform_with_canvas() * r


static func control_rect(c: Control) -> Rect2:
	return c.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, c.size)


static func name_of(c: Node) -> String:
	var t := text_of(c as Control) if c is Control else ""
	t = t.replace("\n", " ").strip_edges()
	if t.length() > 32:
		t = t.substr(0, 30) + ".."
	# "ChampionBar > Label" (the nearest ancestor with a named script class: the file to fix) instead of "@Label@12".
	var owner_name := ""
	var n: Node = c
	while n != null:
		var s: Script = n.get_script() as Script
		if s != null and s.get_global_name() != &"":
			owner_name = String(s.get_global_name())
			break
		n = n.get_parent()
	var own := String(c.name) if not String(c.name).begins_with("@") else c.get_class()
	var path := "%s > %s" % [owner_name, own] if owner_name != "" and n != c else own
	return "%s \"%s\"" % [path, t] if t != "" else path


# ---------------------------------------------------------------- 1. overflow, truncation, off-screen

## Text that is cut (clip / ellipsis / autowrap lines hidden) or sticks out of its frame (nearest ancestor Panel,
## PanelContainer or Button; clip_contents ancestors too). Item `value` = px sticking out.
static func find_overflow(controls: Array[Control]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c in controls:
		if not is_text_control(c) or c is RichTextLabel or c is LineEdit:
			continue
		var tr := text_rect(c)
		# Cut inside its own rect (Godot keeps the rect, the player sees "..." or a clipped word).
		var cut := false
		if c is Label:
			var l := c as Label
			if l.autowrap_mode == TextServer.AUTOWRAP_OFF and (l.clip_text or l.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING):
				cut = text_size(c).x > _inner_width(c) + OVERFLOW_TOL_PX
			elif l.autowrap_mode != TextServer.AUTOWRAP_OFF and l.max_lines_visible >= 0:
				cut = l.get_line_count() > l.max_lines_visible
		elif c is Button:
			var b := c as Button
			if b.clip_text or b.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING:
				cut = text_size(c).x > _inner_width(c) + OVERFLOW_TOL_PX
		if cut:
			out.append({"node": c, "text": name_of(c), "value": snappedf(text_size(c).x - _inner_width(c), 1.0),
				"detail": "text cut inside its own rect (clip / ellipsis)", "kind": "cut"})
			continue
		var frame := _frame_of(c)
		if frame == null:
			continue
		var fr := control_rect(frame)
		var over := _sticks_out(tr, fr)
		if over > OVERFLOW_TOL_PX:
			out.append({"node": c, "text": name_of(c), "value": snappedf(over, 1.0),
				"detail": "text sticks out of %s by %.0f px" % [frame.name, over], "kind": "frame"})
	return out


static func _inner_width(c: Control) -> float:
	var sb: StyleBox = c.get_theme_stylebox(&"normal")
	var w := c.size.x - (sb.get_minimum_size().x if sb != null else 0.0)
	if c is Button and (c as Button).icon != null:
		w -= (c as Button).icon.get_width() + c.get_theme_constant(&"h_separation")
	return w


static func _frame_of(c: Control) -> Control:
	var n := c.get_parent()
	while n != null and n is Control:
		if n is Panel or n is PanelContainer or n is Button or (n as Control).clip_contents:
			return n as Control
		n = n.get_parent()
	return null


## Largest distance `r` goes outside `bounds` on any side (0 when inside).
static func _sticks_out(r: Rect2, bounds: Rect2) -> float:
	return maxf(0.0, maxf(maxf(bounds.position.x - r.position.x, r.end.x - bounds.end.x),
			maxf(bounds.position.y - r.position.y, r.end.y - bounds.end.y)))


## Text or interactive controls that are partly outside the screen. Item `value` = px outside.
static func find_offscreen(controls: Array[Control], screen: Rect2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c in controls:
		if not (is_text_control(c) or is_interactive(c)):
			continue
		var r := text_rect(c) if is_text_control(c) and not c is RichTextLabel else control_rect(c)
		if r.size.x <= 0.0 or r.size.y <= 0.0:
			continue
		var over := _sticks_out(r, screen)
		if over > OVERFLOW_TOL_PX:
			out.append({"node": c, "text": name_of(c), "value": snappedf(over, 1.0),
				"detail": "%.0f px outside the %dx%d screen" % [over, int(screen.size.x), int(screen.size.y)]})
	return out


# ---------------------------------------------------------------- 2. overlaps

## Pairs of visible text / interactive controls (neither inside the other) whose rects overlap. Only controls of the
## same canvas layer are compared. Item `value` = overlap area in px.
static func find_overlaps(controls: Array[Control]) -> Array[Dictionary]:
	var cands: Array[Dictionary] = []
	for c in controls:
		if not (is_text_control(c) or is_interactive(c)):
			continue
		if c.show_behind_parent:
			continue
		var r := text_rect(c) if is_text_control(c) and not c is BaseButton and not c is RichTextLabel else control_rect(c)
		if r.size.x < 1.0 or r.size.y < 1.0:
			continue
		cands.append({"c": c, "r": r, "layer": c.get_canvas_layer_node()})
	var out: Array[Dictionary] = []
	for i in cands.size():
		for j in range(i + 1, cands.size()):
			var a: Dictionary = cands[i]
			var b: Dictionary = cands[j]
			if a["layer"] != b["layer"]:
				continue
			var ca: Control = a["c"]
			var cb: Control = b["c"]
			if ca.is_ancestor_of(cb) or cb.is_ancestor_of(ca):
				continue
			var ra: Rect2 = a["r"]
			var rb: Rect2 = b["r"]
			var inter := ra.intersection(rb)
			var area := inter.get_area()
			if area < OVERLAP_MIN_PX2:
				continue
			var smaller := minf(ra.get_area(), rb.get_area())
			if smaller <= 0.0 or area / smaller < OVERLAP_MIN_FRAC:
				continue
			out.append({"node": ca, "other": cb, "text": "%s  x  %s" % [name_of(ca), name_of(cb)],
				"value": snappedf(area, 1.0), "detail": "%.0f px2 (%.0f %% of the smaller)" % [area, 100.0 * area / smaller]})
	return out


# ---------------------------------------------------------------- 3. font size

## Text under MIN_FONT_WARN px. Item `value` = effective px, `fail` = under MIN_FONT_FAIL.
static func find_small_fonts(controls: Array[Control]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c in controls:
		if not is_text_control(c):
			continue
		var px := effective_font_px(c)
		if px < float(MIN_FONT_WARN) - 0.01:
			out.append({"node": c, "text": name_of(c), "value": snappedf(px, 0.1), "fail": px < float(MIN_FONT_FAIL) - 0.01,
				"detail": "%.1f px (min %d)" % [px, MIN_FONT_WARN]})
	return out


# ---------------------------------------------------------------- 4. contrast

static func luminance(c: Color) -> float:
	var f := func(v: float) -> float: return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * f.call(c.r) + 0.7152 * f.call(c.g) + 0.0722 * f.call(c.b)


static func contrast_ratio(a: Color, b: Color) -> float:
	var la := luminance(a)
	var lb := luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


## The background behind a rect: median colour (by luminance) of the screenshot pixels in the rect grown by 3 px
## (glyphs cover well under half of a text rect, so the median lands on the background). Invalid colour = no image.
static func sample_background(img: Image, r: Rect2) -> Color:
	if img == null:
		return Color(0, 0, 0, -1)
	var g := r.grow(3.0).intersection(Rect2(Vector2.ZERO, Vector2(img.get_width(), img.get_height())))
	if g.size.x < 2.0 or g.size.y < 2.0:
		return Color(0, 0, 0, -1)
	var step := maxi(1, int(sqrt(g.get_area() / 900.0)))
	var px: Array[Color] = []
	var y := int(g.position.y)
	while y < int(g.end.y):
		var x := int(g.position.x)
		while x < int(g.end.x):
			px.append(img.get_pixel(x, y))
			x += step
		y += step
	if px.is_empty():
		return Color(0, 0, 0, -1)
	px.sort_custom(func(a: Color, b: Color) -> bool: return luminance(a) < luminance(b))
	return px[px.size() / 2]


## The background from the style boxes when there is no screenshot: the control's own "normal" box (labels with a
## badge, buttons) or the nearest ancestor panel's StyleBoxFlat, when it is opaque enough (alpha >= 0.6).
static func style_background(c: Control) -> Color:
	var n: Node = c
	while n != null and n is Control:
		var ctl := n as Control
		var sb: StyleBox = null
		if ctl is Button or ctl is Label:
			sb = ctl.get_theme_stylebox(&"normal")
		elif ctl is PanelContainer or ctl is Panel:
			sb = ctl.get_theme_stylebox(&"panel")
		if sb is StyleBoxFlat and (sb as StyleBoxFlat).draw_center and (sb as StyleBoxFlat).bg_color.a >= 0.6:
			return (sb as StyleBoxFlat).bg_color
		n = n.get_parent()
	return Color(0, 0, 0, -1)


## Text whose colour contrasts too little with what is behind it. `img` = the screenshot (null = style boxes only).
## Outlined text (outline >= 2 px) counts the text / outline contrast too. Disabled buttons are exempt (WCAG).
## Item: `value` = ratio, `rule`, `fail`.
static func find_low_contrast(controls: Array[Control], img: Image) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c in controls:
		if not is_text_control(c) or c is LineEdit:
			continue
		if c is BaseButton and (c as BaseButton).disabled:
			continue
		var r := text_rect(c)
		var bg := sample_background(img, r)
		if bg.a < 0.0:
			bg = style_background(c)
		if bg.a < 0.0:
			continue
		var col := font_color_of(c) * modulate_of(c)
		var eff := Color(bg.r, bg.g, bg.b).lerp(Color(col.r, col.g, col.b), clampf(col.a, 0.0, 1.0))
		var ratio := contrast_ratio(eff, bg)
		var ol: Array = outline_of(c)
		if int(ol[0]) >= 2:
			var oc: Color = ol[1]
			ratio = maxf(ratio, contrast_ratio(eff, Color(oc.r, oc.g, oc.b)) * clampf(oc.a * col.a, 0.0, 1.0))
		var px := effective_font_px(c)
		var large := px >= float(LARGE_TEXT_PX) or (px >= 19.0 and font_of(c) != null and font_of(c) != ThemeDB.fallback_font)
		var rule := CONTRAST_LARGE if large else CONTRAST_SMALL
		if ratio < rule:
			# Text inside a disabled button: WCAG exempts inactive components, so it is reported but never FAILs.
			var inactive := _in_disabled_button(c)
			out.append({"node": c, "text": name_of(c), "value": snappedf(ratio, 0.01), "rule": rule,
				"fail": ratio < rule * CONTRAST_HARD_FACTOR and not inactive, "inactive": inactive,
				"detail": "%.2f : 1 (rule %.1f; text %s on %s)%s" % [ratio, rule, eff.to_html(false), bg.to_html(false),
					" (inside a disabled button: WARN only)" if inactive else ""]})
	return out


static func _in_disabled_button(c: Control) -> bool:
	var n: Node = c.get_parent()
	while n != null and n is Control:
		if n is BaseButton and (n as BaseButton).disabled:
			return true
		n = n.get_parent()
	return false


# ---------------------------------------------------------------- 5. tooltips

## Visible buttons without a tooltip. `short` items (text <= SHORT_BUTTON_TEXT chars: abbreviations, icons) are the
## serious ones; the others only matter on in-game screens.
static func find_missing_tooltips(controls: Array[Control]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c in controls:
		if not c is BaseButton:
			continue
		var tip := c.get_tooltip(c.size * 0.5)
		if tip.strip_edges() != "":
			continue
		var t := text_of(c).strip_edges()
		out.append({"node": c, "text": name_of(c), "value": t.length(), "short": t.length() <= SHORT_BUTTON_TEXT,
			"detail": "no tooltip" + (" (abbreviation / icon button)" if t.length() <= SHORT_BUTTON_TEXT else "")})
	return out


# ---------------------------------------------------------------- 6. hotkeys

## Duplicate letters among the visible command-card key badges. `badges` = the key Labels.
static func find_duplicate_badges(badges: Array) -> Array[Dictionary]:
	var seen := {}
	var out: Array[Dictionary] = []
	for l: Variant in badges:
		if not (l is Label) or not (l as Label).is_visible_in_tree():
			continue
		var k := (l as Label).text.strip_edges().to_upper()
		if k == "":
			continue
		if seen.has(k):
			out.append({"node": l, "text": "key %s" % k, "value": k,
				"detail": "shown on 2 command-card slots (%s, %s)" % [name_of(seen[k]), name_of(l)]})
		else:
			seen[k] = l
	return out


## Parses a help text ("KEY: action    KEY: action" per line, entries split by 2+ spaces or " · ") into
## [{key, action, context, line}]. A context prefix ("Flag: Z raise", "Bazaar: Z caravan") is kept apart.
static func parse_help(text: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var re_split := RegEx.create_from_string("\\s{2,}|\\s·\\s")
	var line_no := 0
	for line in text.split("\n"):
		line_no += 1
		var context := ""
		for part in re_split.sub(line, "\t", true).split("\t", false):
			var p := part.strip_edges()
			var colon := p.find(": ")
			if colon <= 0:
				# "Z raise" after a "Flag:" context
				if context != "" and p.length() > 2 and p.substr(1, 1) == " ":
					out.append({"key": p.substr(0, 1).to_upper(), "action": p.substr(2), "context": context, "line": line_no})
				continue
			var key := p.substr(0, colon).strip_edges()
			var action := p.substr(colon + 2).strip_edges()
			if key.length() > 12 or key.contains(" / ") and key.length() > 8:
				continue
			# "Flag: Z raise": the part before the colon is a context word, the key is the action's first letter.
			if key.length() > 3 and action.length() > 2 and action.substr(1, 1) == " " and action.substr(0, 1) == action.substr(0, 1).to_upper():
				context = key
				out.append({"key": action.substr(0, 1).to_upper(), "action": action.substr(2), "context": context, "line": line_no})
				continue
			# "B, B: Bazaar" = a key sequence (B then B), bound to the first key's menu: context.
			var seq := key.contains(",")
			out.append({"key": key.to_upper(), "action": action, "context": "sequence" if seq else "", "line": line_no})
	return out


## Keys listed twice with different actions and no context ("G: gather" and "G: trade (caravans)"). Context-bound
## entries ("Flag: Z raise") are allowed to reuse a key. Items: `value` = key.
static func find_duplicate_help_keys(text: String) -> Array[Dictionary]:
	var by_key := {}
	for e: Dictionary in parse_help(text):
		if String(e["context"]) != "":
			continue
		var k: String = e["key"]
		if not by_key.has(k):
			by_key[k] = []
		(by_key[k] as Array).append(e)
	var out: Array[Dictionary] = []
	for k: String in by_key:
		var list: Array = by_key[k]
		var actions := {}
		for e: Dictionary in list:
			actions[String(e["action"])] = true
		if actions.size() > 1:
			out.append({"node": null, "text": "help key %s" % k, "value": k,
				"detail": "; ".join(PackedStringArray(actions.keys()))})
	return out
