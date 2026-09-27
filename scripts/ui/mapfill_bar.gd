class_name MapfillBar
extends Control
## The top-centre map-fill HUD (step 12, task 12.C7; spec: map-fill.md 8, layout: docs/design/ui-mapfill.md 2, 5.2,
## 6.1, 15-17). A zero-size holder anchored at the top centre of the screen (children are placed in 1600 x 900
## virtual pixels relative to x 800), mouse-transparent; made once by `MapfillBar.attach(hud, selection)`
## (GameHUD._setup_map_fill). It owns:
## - the objectives strip (300 x 50 at (650, 52) with 8 points; width follows the point count): one 28 px icon per
##   capture point in map order (watchtowers, wells, shrines; west to east), the owner colour, the states of 2.4
##   (hover, selected, own point being taken, awake / asleep shrine, contested, owner-change pop), row 2 = the capture
##   progress strip (only where the local team sees the point) or the shrine / well countdown; click = centre the
##   camera; the 5-line tooltip. Hidden while there is no CapturePoints service or it has no points;
## - the two blessing chips (144 x 22 at (958, 54) / (958, 78)): own `Blessing 38 s`, enemy `Enemy blessing 38 s`;
## - the epic-beast boss bars (456 x 50 at (572, 156) and (572, 212); the reusable BossBar class): visible beasts
##   that are engaged (damaged, or hit a local-team unit, in the last 5 s) or on screen, engaged first, then the nearest
##   to the screen centre, max 2; fade in 0.2 s, out 0.3 s (1.5 s after they stop qualifying, at once when the fog
##   hides them), death = drain + white flash + 0.5 s fade; click = centre the camera;
## - the camp hover chip (mouse + (18, 12)): `Gloomcap Hollow · Tier 2 · ~86 XP · +25 essence` after the mouse rests
##   0.25 s over a visible camp creature (no window, pending order, bounty mode or route chip).
## Step-12 services are reached untyped (groups "capture_points_service", "camp_manager", "beasts"), retried while
## missing; nothing here errors on a map without them.

const GROUP := &"mapfill_bar"
const PLAYER_TEAM := 0
const ENEMY_TEAM := 1
## Relation colours (ui-mapfill.md 15.1; never skinned).
const OWN := Color(0.3, 1.0, 0.4)
const ENEMY := Color(1.0, 0.3, 0.3)
const POINT_NEUTRAL := Color(0.62, 0.64, 0.70)
const BEAST := Color(1.0, 0.75, 0.2)
const TIER_COLORS := {1: Color(0.85, 0.85, 0.75), 2: Color(1.0, 0.6, 0.25), 3: Color(1.0, 0.3, 0.25)}
const WADE := Color(0.60, 0.78, 0.88)
const NEAR := Color(0.4, 0.9, 0.4)
const FAR := Color(1.0, 0.55, 0.2)
const WELL_MIST := Color(0.35, 0.20, 0.50)
const KIND_ORDER: Array[StringName] = [&"watchtower", &"well", &"shrine"]
const KIND_NAMES := {&"watchtower": "Watchtower", &"well": "Essence well", &"shrine": "Wayshrine"}
const CENTER_X := 800.0
const ICON := 28.0
const ICON_GAP := 4.0
const PAD := 11.0                 ## 22 px of padding split left / right.
const SEP := 17.0                 ## 8 px, the 1 px line, 8 px.
const STRIP_Y := 52.0
const STRIP_H := 50.0
const ICON_Y := 6.0               ## y 58 on screen.
const ROW2_Y := 35.0              ## the countdown at y 87 (height 13).
const PROGRESS_Y := 38.0          ## the progress strip at y 90 (height 3).
const GLYPH := 18.0
const CHIP_POS: Array[Vector2] = [Vector2(958, 54), Vector2(958, 78)]
const CHIP_SIZE := Vector2(144, 22)
const BOSS_POS: Array[Vector2] = [Vector2(572, 156), Vector2(572, 212)]
const BOSS_SIZE := Vector2(456, 50)
const REFRESH := 0.1              ## 10 Hz strip / chips.
const FIND_RETRY := 1.0
const BOSS_TICK := 0.25           ## 4 Hz beast choice.
const ENGAGE_MEMORY := 5.0
const LEAVE_DELAY := 1.5
const HOVER_POLL := 0.1
const HOVER_DELAY := 0.25
const HOVER_OFFSET := Vector2(18, 12)
const BLESSING_OWN_TIP := ("Wayfarer's Blessing %d s\n+12 %% speed, +1.5 HP / s for your soldiers, wizard and champions\n"
		+ "Take another awake shrine to reset it to 60 s")
const BLESSING_ENEMY_TIP := "Enemy blessing %d s\n+12 %% speed, +1.5 HP / s for their soldiers, wizard and champions"
const CLICK_HINT := "Click: centre the camera"
## Beast type id -> [kind, variant] (EpicBeasts.KIND_TYPES read backwards; the meta wins when set).
const BEAST_TYPES := {
	&"ironhide_tusker": [&"tusker", 0], &"old_scarback": [&"tusker", 1],
	&"stormcrest_roc": [&"roc", 0], &"duskwing_roc": [&"roc", 1],
	&"greymane_direwolf": [&"direwolf", 0], &"moonpelt_direwolf": [&"direwolf", 1],
	&"grizzlemaw": [&"grizzlemaw", 0], &"elder_grizzlemaw": [&"grizzlemaw", 1],
}
const VARIANT_WORDS := {&"tusker": "alpha", &"roc": "dark breed", &"direwolf": "silver breed", &"grizzlemaw": "elder"}

var hud: Node
var selection: Node
## Read only (tests).
var service: Node                         ## The CapturePoints service shown, or null.
var strip: Panel
var icons: Array[PointIcon] = []          ## In map order.
var shown_points: Array = []              ## The points of `icons`, same order.
var countdowns: Array[Label] = []
var progress_rects: Array[ColorRect] = []
var separators: Array[float] = []         ## Strip-local x of each separator line.
var blessing_chips: Array[PanelContainer] = []
var bars: Array[BossBar] = []
var hover_chip: PanelContainer
var hover_labels: Array[Label] = []

var _clock := 0.0
var _refresh_left := 0.0
var _find_left := 0.0
var _boss_left := 0.0
var _hover_left := 0.0
var _hover_unit: Node = null
var _hover_since := 0.0
var _last_owner := {}                     # point instance id -> owner seen at the last refresh
var _chip_team: Array[int] = [-1, -1]     # the team each chip shows (-1 = hidden)
var _chip_left := {PLAYER_TEAM: 0.0, ENEMY_TEAM: 0.0}
var _engaged_at := {}                     # beast instance id -> _clock of its last fight event
var _qualified_at := {}                   # beast instance id -> _clock it last qualified for a bar
var _hooked := {}                         # beast instance id -> true once its signals are connected
var _cp_hooked: Node = null


## Adds the holder under `hud` once (a second call returns the same one).
static func attach(p_hud: Node, p_selection: Node = null) -> MapfillBar:
	var tree := Engine.get_main_loop() as SceneTree
	var bar: MapfillBar = null
	if tree != null:
		for n in tree.get_nodes_in_group(GROUP):
			if n is MapfillBar and not n.is_queued_for_deletion():
				bar = n
				break
	if bar == null:
		bar = MapfillBar.new()
		bar.name = "MapfillBar"
		bar.hud = p_hud
		if p_hud != null:
			p_hud.add_child(bar)
	if p_selection != null:
		bar.selection = p_selection
	return bar


func _init() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	theme = UIStyle.hud_theme()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = 0.0
	offset_right = 0.0
	offset_top = 0.0
	offset_bottom = 0.0
	strip = Panel.new()
	strip.name = "ObjectivesStrip"
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.add_theme_stylebox_override("panel", _strip_style())
	strip.draw.connect(_draw_strip)
	strip.visible = false
	add_child(strip)
	for i in 2:
		blessing_chips.append(_make_blessing_chip(i))
	for i in 2:
		var b := BossBar.new()
		b.name = "BossBar%d" % (i + 1)
		b.position = BOSS_POS[i] - Vector2(CENTER_X, 0.0)
		b.size = BOSS_SIZE
		b.visible = false
		b.clicked.connect(_on_boss_clicked)
		add_child(b)
		bars.append(b)
	_build_hover_chip()


func apply_skin() -> void:
	if strip == null:
		return
	strip.add_theme_stylebox_override("panel", _strip_style())
	for i in blessing_chips.size():
		_style_blessing_chip(i)
	for b in bars:
		b.apply_skin()
	if hover_chip != null:
		hover_chip.add_theme_stylebox_override("panel", _hover_style())
		hover_labels[2].add_theme_color_override("font_color", UIStyle.token(&"text"))
	for ic in icons:
		ic.apply_skin()


func _strip_style() -> StyleBoxFlat:
	var s := UIStyle.slate_style(0.0)
	s.border_color = UIStyle.token(&"frame_dark")
	return s


func _process(delta: float) -> void:
	_clock += delta
	_find_left -= delta
	if service == null or not is_instance_valid(service):
		if _find_left <= 0.0:
			_find_left = FIND_RETRY
			_find_service()
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH
		refresh()
	elif not icons.is_empty():
		for ic in icons:
			ic.overlay.queue_redraw()   # pulses run every frame
	_boss_left -= delta
	if _boss_left <= 0.0:
		_boss_left = BOSS_TICK
		refresh_bosses()
	_hover_left -= delta
	if _hover_left <= 0.0:
		_hover_left = HOVER_POLL
		_update_hover()
	if hover_chip.visible:
		_place_hover_chip()
	_pulse_chips()


# ---------------------------------------------------------------- service

## The CapturePoints service (class list, then group "capture_points_service"), or null.
static func capture_points_of(tree: SceneTree) -> Node:
	if tree == null:
		return null
	return tree.get_first_node_in_group(&"capture_points_service")


func _find_service() -> void:
	if not is_inside_tree():
		return
	var cp := capture_points_of(get_tree())
	if cp == null or not cp.has_method(&"points"):
		return
	service = cp
	if _cp_hooked != cp:
		_cp_hooked = cp
		if cp.has_signal(&"blessing_started"):
			cp.connect(&"blessing_started", _on_blessing_started)
		if cp.has_signal(&"blessing_ended"):
			cp.connect(&"blessing_ended", _on_blessing_ended)
	rebuild_strip()


## The local team (the fog's), else PLAYER.
func local_team() -> int:
	var fog := FogOfWar.find() if is_inside_tree() else null
	return fog.local_team if fog != null else PLAYER_TEAM


## True when the local team sees `pos` now (no fog = seen).
func is_seen(pos: Vector3) -> bool:
	var fog := FogOfWar.find() if is_inside_tree() else null
	return fog == null or fog.is_visible(fog.local_team, pos)


func match_time() -> float:
	if service != null and is_instance_valid(service) and service.has_method(&"match_time"):
		return float(service.call(&"match_time"))
	return _clock


## Map order: watchtowers, wells, shrines; inside a kind west to east (x, then z).
static func map_order(pts: Array) -> Array:
	var out := pts.filter(func(p: Variant) -> bool: return p is Node3D and is_instance_valid(p))
	out.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		var ka := KIND_ORDER.find(StringName(str(a.get(&"kind"))))
		var kb := KIND_ORDER.find(StringName(str(b.get(&"kind"))))
		if ka != kb:
			return ka < kb
		if not is_equal_approx(a.global_position.x, b.global_position.x):
			return a.global_position.x < b.global_position.x
		return a.global_position.z < b.global_position.z)
	return out


## Strip width for groups of `counts` icons: 22 + sum(28 n + 4 (n - 1)) + 17 per separator.
static func strip_width(counts: Array[int]) -> float:
	var w := PAD * 2.0
	var groups := 0
	for n in counts:
		if n <= 0:
			continue
		w += ICON * n + ICON_GAP * (n - 1)
		groups += 1
	return w + SEP * maxi(groups - 1, 0)


## (Re)builds the icons from the service's points (they never move; a mission with one shrine gets one icon).
func rebuild_strip() -> void:
	for ic in icons:
		ic.queue_free()
	for l in countdowns:
		l.queue_free()
	for r in progress_rects:
		r.queue_free()
	icons.clear()
	countdowns.clear()
	progress_rects.clear()
	separators.clear()
	shown_points.clear()
	_last_owner.clear()
	if service == null or not is_instance_valid(service):
		strip.visible = false
		return
	shown_points = map_order(service.call(&"points"))
	if shown_points.is_empty():
		strip.visible = false
		return
	var counts: Array[int] = []
	for k in KIND_ORDER:
		counts.append(shown_points.filter(func(p: Node3D) -> bool: return StringName(str(p.get(&"kind"))) == k).size())
	var w := strip_width(counts)
	strip.position = Vector2(-w * 0.5, STRIP_Y)
	strip.size = Vector2(w, STRIP_H)
	var x := PAD
	var last_kind := &""
	for p: Node3D in shown_points:
		var k := StringName(str(p.get(&"kind")))
		if last_kind != &"" and k != last_kind:
			x += SEP - ICON_GAP   # 17 px between groups instead of 4
		last_kind = k
		var ic := PointIcon.new()
		ic.point = p
		ic.kind = k
		ic.position = Vector2(x, ICON_Y)
		ic.pressed.connect(_on_icon_pressed.bind(ic))
		strip.add_child(ic)
		icons.append(ic)
		var cd := UIStyle.number_label("", 11)
		cd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cd.position = Vector2(x + ICON * 0.5 - 20.0, ROW2_Y)
		cd.size = Vector2(40, 13)
		cd.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strip.add_child(cd)
		countdowns.append(cd)
		var pr := ColorRect.new()
		pr.position = Vector2(x, PROGRESS_Y)
		pr.size = Vector2(0, 3)
		pr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pr.visible = false
		strip.add_child(pr)
		progress_rects.append(pr)
		_last_owner[p.get_instance_id()] = int(p.get(&"owner_team"))
		x += ICON + ICON_GAP
	# Separators: 8 px after the last icon of a group (x of the 1 px line, strip-local).
	for i in range(1, icons.size()):
		if icons[i].kind != icons[i - 1].kind:
			separators.append(icons[i - 1].position.x + ICON + 8.0)
	strip.visible = true
	strip.queue_redraw()
	refresh()


func _draw_strip() -> void:
	var c := UIStyle.token(&"frame_dark")
	for sx in separators:
		strip.draw_rect(Rect2(sx, 10, 1, 20), c)


# ---------------------------------------------------------------- strip refresh (10 Hz)

## Colours, states, timers and progress of every icon, then the blessing chips.
func refresh() -> void:
	_refresh_blessings()
	if icons.is_empty():
		return
	if service == null or not is_instance_valid(service):
		strip.visible = false
		return
	var team := local_team()
	var now := match_time()
	var sel: Variant = selection.get(&"selected_neutral") if selection != null and is_instance_valid(selection) else null
	for i in icons.size():
		var ic := icons[i]
		var p := ic.point
		if p == null or not is_instance_valid(p):
			continue
		var owner := int(p.get(&"owner_team"))
		var id := p.get_instance_id()
		if _last_owner.has(id) and int(_last_owner[id]) != owner:
			ic.pop()
		_last_owner[id] = owner
		var seen := is_seen(p.global_position)
		var st := StringName(str(p.get(&"state")))
		var cap := int(p.get(&"capture_team"))
		var prog := float(p.get(&"progress"))
		var shrine := ic.kind == &"shrine"
		var awake := shrine and st == &"awake"
		ic.awake = awake
		ic.asleep = shrine and not awake
		ic.fill = GameColors.relation(owner, team)
		ic.contested = seen and st == &"contested"
		ic.taken = seen and owner == team and cap != -1 and cap != team and (st == &"capturing" or st == &"neutralising")
		ic.selected = sel != null and is_instance_valid(sel) and sel == p
		ic.tooltip_text = tooltip_for(p, team, seen, now)
		# Row 2: the progress strip (visible cells only) wins over the countdown.
		var pr := progress_rects[i]
		var cd := countdowns[i]
		var show_prog := seen and cap != -1 and prog > 0.0
		pr.visible = show_prog
		if show_prog:
			pr.size = Vector2(roundf(clampf(prog, 0.0, 1.0) * ICON), 3)
			pr.color = GameColors.relation(cap, team)
		var left := -1.0
		if not show_prog:
			if shrine and not awake:
				var t := float(p.call(&"time_until_awake")) if p.has_method(&"time_until_awake") else INF
				if t != INF:
					left = t
			elif ic.kind == &"well" and now < WELL_START:
				left = WELL_START - now
		cd.visible = left >= 0.0
		if left >= 0.0:
			cd.text = mmss(left)
			cd.add_theme_color_override("font_color", UIStyle.GOLD if left <= 10.0 else UIStyle.token(&"text_muted"))
		ic.overlay.queue_redraw()


const WELL_START := 150.0   ## CapturePoints.WELL_START (2:30).


## The 5-line tooltip of a point (lines joined by "\n"): name · kind, owner · state, effect, far bank, click hint.
func tooltip_for(p: Node3D, team: int, seen: bool, now: float) -> String:
	var lines: PackedStringArray = []
	lines.append("%s · %s" % [str(p.get(&"display_name")), KIND_NAMES.get(StringName(str(p.get(&"kind"))), "Point")])
	var owner_line: String = PointPanel.owner_segment(p, team)[0]
	var state: String = PointPanel.state_segment(p, team, seen)[0]
	lines.append(owner_line + (" · " + state if state != "" else ""))
	lines.append(PointPanel.effect_text(p, now))
	var far := PointPanel.far_bank_text(p, team)
	if far != "":
		lines.append(far)
	lines.append(CLICK_HINT)
	return "\n".join(lines)


func _on_icon_pressed(ic: PointIcon) -> void:
	if ic.point != null and is_instance_valid(ic.point):
		focus_camera(ic.point.global_position)


## Centres the RTS camera on `pos` (the rig the selection's camera hangs from, as minimap.setup finds it).
func focus_camera(pos: Vector3) -> bool:
	var rig := camera_rig()
	if rig == null:
		return false
	rig.call(&"focus_on", pos)
	return true


func camera_rig() -> Node:
	if selection == null or not is_instance_valid(selection):
		return null
	var cam: Variant = selection.get(&"camera")
	if cam is Node and is_instance_valid(cam):
		var rig := (cam as Node).get_parent()
		if rig != null and rig.has_method(&"focus_on"):
			return rig
	return null


## 72.4 -> "1:13" (ceil).
static func mmss(seconds: float) -> String:
	var s := maxi(ceili(seconds), 0)
	return "%d:%02d" % [s / 60, s % 60]


# ---------------------------------------------------------------- blessing chips

func _make_blessing_chip(i: int) -> PanelContainer:
	var chip := TipPanel.new()
	chip.name = "BlessingChip%d" % (i + 1)
	chip.position = CHIP_POS[i] - Vector2(CENTER_X, 0.0)
	chip.custom_minimum_size = CHIP_SIZE
	chip.size = CHIP_SIZE
	chip.pivot_offset = CHIP_SIZE * 0.5
	chip.mouse_filter = Control.MOUSE_FILTER_STOP
	chip.visible = false
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(row)
	var glyph := Control.new()
	glyph.name = "Glyph"
	glyph.custom_minimum_size = Vector2(12, 12)
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.draw.connect(func() -> void:
		var c := UIStyle.GOLD if _chip_team[i] != ENEMY_TEAM else ENEMY
		draw_point_glyph(glyph, &"shrine", Vector2.ZERO, 12.0, c, true))
	row.add_child(glyph)
	var text_row := HBoxContainer.new()   # `Blessing` + ` 38 s` with no gap between them
	text_row.add_theme_constant_override("separation", 0)
	text_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text_row)
	var word := UIStyle.panel_label("Blessing", 12, UIStyle.GOLD)
	word.mouse_filter = Control.MOUSE_FILTER_IGNORE
	word.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_row.add_child(word)
	var secs := UIStyle.panel_label("", 12)
	secs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	secs.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_row.add_child(secs)
	add_child(chip)
	_style_blessing_chip_node(chip, UIStyle.GOLD)
	return chip


func _style_blessing_chip(i: int) -> void:
	_style_blessing_chip_node(blessing_chips[i], ENEMY if _chip_team[i] == ENEMY_TEAM else UIStyle.GOLD)


func _style_blessing_chip_node(chip: PanelContainer, border: Color) -> void:
	var s := UIStyle.slate_style(4.0, border)
	s.content_margin_left = 6.0
	s.content_margin_right = 6.0
	s.content_margin_top = 2.5      # 22 px tall with the font-12 line
	s.content_margin_bottom = 2.5
	chip.add_theme_stylebox_override("panel", s)


## Parts of chip `i`: [glyph, word label, seconds label].
func _chip_parts(i: int) -> Array:
	var row := blessing_chips[i].get_child(0)
	var text_row := row.get_child(1)
	return [row.get_child(0), text_row.get_child(0), text_row.get_child(1)]


func _blessing_left(team: int) -> float:
	if service == null or not is_instance_valid(service) or not service.has_method(&"blessing_time_left"):
		return 0.0
	return float(service.call(&"blessing_time_left", team))


## Own first: the first running blessing takes the upper slot.
func _refresh_blessings() -> void:
	var own := local_team()
	var other := ENEMY_TEAM if own == PLAYER_TEAM else PLAYER_TEAM
	var running: Array[int] = []
	for t: int in [own, other]:
		var left := _blessing_left(t)
		_chip_left[t] = left
		if left > 0.0:
			running.append(t)
	for i in 2:
		var chip := blessing_chips[i]
		var t := running[i] if i < running.size() else -1
		if t == -1:
			chip.visible = false
			_chip_team[i] = -1
			continue
		if _chip_team[i] != t:
			_chip_team[i] = t
			_style_blessing_chip(i)
		chip.visible = true
		var parts := _chip_parts(i)
		var secs := ceili(float(_chip_left[t]))
		(parts[1] as Label).text = "Blessing" if t == own else "Enemy blessing"
		(parts[1] as Label).add_theme_color_override("font_color", UIStyle.GOLD if t == own else ENEMY)
		(parts[2] as Label).text = " %d s" % secs
		(parts[2] as Label).add_theme_color_override("font_color", UIStyle.WARN if secs <= 10 else UIStyle.token(&"text"))
		(parts[0] as Control).queue_redraw()
		chip.tooltip_text = (BLESSING_OWN_TIP if t == own else BLESSING_ENEMY_TIP) % secs


## The last 10 s: chip alpha pulse 0.6-1.0 at 2 Hz.
func _pulse_chips() -> void:
	for i in 2:
		var chip := blessing_chips[i]
		if not chip.visible or chip.has_meta(&"popping"):
			continue
		var t := _chip_team[i]
		var left := float(_chip_left.get(t, 0.0))
		chip.modulate.a = (0.8 + 0.2 * sin(_clock * TAU * 2.0)) if left > 0.0 and left <= 10.0 else 1.0


## blessing_started (a new blessing or a refresh to 60 s): fade in 0.2 s + scale 1.1 -> 1.0.
func _on_blessing_started(team: int, _seconds: float) -> void:
	_refresh_blessings()
	for i in 2:
		if _chip_team[i] == team:
			var chip := blessing_chips[i]
			chip.set_meta(&"popping", true)
			chip.modulate.a = 0.0
			chip.scale = Vector2(1.1, 1.1)
			var tw := chip.create_tween().set_parallel(true)
			tw.tween_property(chip, "modulate:a", 1.0, 0.2)
			tw.tween_property(chip, "scale", Vector2.ONE, 0.2)
			tw.chain().tween_callback(func() -> void: chip.remove_meta(&"popping"))


func _on_blessing_ended(_team: int) -> void:
	_refresh_blessings()


## The chip texts shown (tests): e.g. ["Blessing 38 s", "Enemy blessing 12 s"].
func blessing_texts() -> PackedStringArray:
	var out: PackedStringArray = []
	for i in 2:
		if blessing_chips[i].visible:
			var parts := _chip_parts(i)
			out.append((parts[1] as Label).text + (parts[2] as Label).text)
	return out


# ---------------------------------------------------------------- boss bars (4 Hz)

## Picks the beasts to show (engaged first, then nearest to the screen centre; max 2) and updates the bars.
func refresh_bosses() -> void:
	if not is_inside_tree():
		return
	var candidates: Array = []
	for b in get_tree().get_nodes_in_group(&"beasts"):
		if not (b is Node3D) or not is_instance_valid(b) or b.is_queued_for_deletion():
			continue
		var beast := b as Node3D
		_hook_beast(beast)
		if beast.has_method(&"is_alive") and not bool(beast.call(&"is_alive")):
			continue
		if not beast.is_visible_in_tree():
			_qualified_at.erase(beast.get_instance_id())   # hidden by the fog: leaves at once
			continue
		var id := beast.get_instance_id()
		var engaged := _clock - float(_engaged_at.get(id, -1.0e9)) <= ENGAGE_MEMORY
		if engaged or on_screen(beast.global_position):
			_qualified_at[id] = _clock
		if _clock - float(_qualified_at.get(id, -1.0e9)) <= LEAVE_DELAY:
			candidates.append([beast, engaged, _screen_distance(beast.global_position)])
	candidates.sort_custom(func(a: Array, b: Array) -> bool:
		if bool(a[1]) != bool(b[1]):
			return bool(a[1])
		return float(a[2]) < float(b[2]))
	var chosen: Array = []
	for c: Array in candidates:
		if chosen.size() >= bars.size():
			break
		chosen.append(c[0])
	# Bars keep their beast while it stays chosen; the others leave (dead ones play their death).
	for bar in bars:
		if bar.target == null or bar.dying:
			continue
		if not is_instance_valid(bar.target):
			bar.leave()
			continue
		if bar.target.has_method(&"is_alive") and not bool(bar.target.call(&"is_alive")):
			bar.play_death()
			continue
		if not chosen.has(bar.target):
			bar.leave()
		else:
			chosen.erase(bar.target)
	for beast: Node3D in chosen:
		for bar in bars:
			if bar.is_free():
				bar.show_for(beast, beast_title(beast), variant_word(beast))
				break
	for bar in bars:
		if bar.target != null and is_instance_valid(bar.target) and not bar.dying:
			bar.state_text = beast_state(bar.target)


func _hook_beast(beast: Node3D) -> void:
	var id := beast.get_instance_id()
	if _hooked.has(id):
		return
	_hooked[id] = true
	if beast.has_signal(&"damage_taken"):
		beast.connect(&"damage_taken", func(_a: float, _by: Node3D) -> void: _engaged_at[id] = _clock)
	if beast.has_signal(&"attack_landed"):
		beast.connect(&"attack_landed", func(target: Node3D, _a: float) -> void: _on_beast_hit(id, target))
	var ab := beast.get_node_or_null(^"CreatureAbilities")
	if ab != null and ab.has_signal(&"ability_hit"):
		ab.connect(&"ability_hit", func(_aid: StringName, target: Node3D, _a: float) -> void: _on_beast_hit(id, target))


func _on_beast_hit(id: int, target: Node3D) -> void:
	if target != null and is_instance_valid(target) and target.get(&"team") != null \
			and int(target.get(&"team")) == local_team():
		_engaged_at[id] = _clock


## Marks a beast as engaged now (tests, and any system that knows of a fight).
func mark_engaged(beast: Node) -> void:
	if beast != null and is_instance_valid(beast):
		_engaged_at[beast.get_instance_id()] = _clock


func _on_boss_clicked(target: Node3D) -> void:
	if target != null and is_instance_valid(target):
		focus_camera(target.global_position)


## The shown beasts in bar order (tests; null for a free bar).
func bar_targets() -> Array:
	var out: Array = []
	for b in bars:
		out.append(b.target if b.visible and not b.is_free() else null)
	return out


## `OLD SCARBACK` (the type's display_name; else the NAMES-style name) as plain text (the label upper-cases it).
static func beast_title(beast: Node) -> String:
	var t: Variant = beast.get(&"unit_type")
	if t is Resource and str((t as Resource).get(&"display_name")) not in ["", "<null>"]:
		return str((t as Resource).get(&"display_name"))
	var n := str(beast.get(&"unit_name"))
	return n if n not in ["", "<null>"] else "Epic beast"


## [kind, variant] of a beast (meta beast_variant wins; type id table; else [&"", 0]).
static func beast_kind_variant(beast: Node) -> Array:
	var kind := &""
	var variant := 0
	var t: Variant = beast.get(&"unit_type")
	if t is Resource:
		var info: Variant = BEAST_TYPES.get(StringName(str((t as Resource).get(&"id"))))
		if info is Array:
			kind = info[0]
			variant = int(info[1])
	if beast.has_meta(&"beast_variant"):
		variant = int(beast.get_meta(&"beast_variant"))
	return [kind, variant]


## The variant-B word (`alpha`, `dark breed`, `silver breed`, `elder`), "" for variant A.
static func variant_word(beast: Node) -> String:
	var kv := beast_kind_variant(beast)
	return str(VARIANT_WORDS.get(kv[0], "")) if int(kv[1]) == 1 else ""


## `Enraged` (a Grizzlemaw under 30 % HP) / `Escaping` (a Roc in its Updraft shroud) / "".
static func beast_state(beast: Node) -> String:
	var kind: StringName = beast_kind_variant(beast)[0]
	var hp := float(beast.get(&"hp")) if beast.get(&"hp") != null else 0.0
	var max_hp := maxf(float(beast.get(&"max_hp")) if beast.get(&"max_hp") != null else 1.0, 1.0)
	if kind == &"grizzlemaw" and hp / max_hp < 0.3:
		return "Enraged"
	if kind == &"roc" and beast.has_method(&"has_status") and bool(beast.call(&"has_status", &"shroud")):
		return "Escaping"
	return ""


func on_screen(pos: Vector3) -> bool:
	var vp := get_viewport()
	var cam := vp.get_camera_3d() if vp != null else null
	if cam == null or cam.is_position_behind(pos):
		return false
	return vp.get_visible_rect().has_point(cam.unproject_position(pos))


func _screen_distance(pos: Vector3) -> float:
	var vp := get_viewport()
	var cam := vp.get_camera_3d() if vp != null else null
	if cam == null or cam.is_position_behind(pos):
		return 1.0e9
	return cam.unproject_position(pos).distance_to(vp.get_visible_rect().size * 0.5)


# ---------------------------------------------------------------- camp hover chip (10 Hz)

func _hover_style() -> StyleBoxFlat:
	var s := UIStyle.slate_style(4.0, UIStyle.token(&"frame_metal"))
	s.content_margin_left = 6.0
	s.content_margin_right = 6.0
	s.content_margin_top = 4.0
	s.content_margin_bottom = 4.0
	return s


func _build_hover_chip() -> void:
	hover_chip = PanelContainer.new()
	hover_chip.name = "CampHoverChip"
	hover_chip.top_level = true
	hover_chip.z_index = 10
	hover_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_chip.custom_minimum_size = Vector2(0, 26)
	hover_chip.add_theme_stylebox_override("panel", _hover_style())
	hover_chip.visible = false
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_chip.add_child(row)
	for i in 3:
		var l := UIStyle.panel_label("", 13)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(l)
		hover_labels.append(l)
	hover_labels[0].add_theme_color_override("font_color", UIStyle.GOLD)
	add_child(hover_chip)


## The camp manager (group "camp_manager"), or null.
static func camp_manager_of(tree: SceneTree) -> Node:
	return tree.get_first_node_in_group(&"camp_manager") if tree != null else null


## The camp of a creature, or null.
static func camp_of(tree: SceneTree, u: Node) -> Node:
	var cm := camp_manager_of(tree)
	if cm == null or u == null or not is_instance_valid(u) or not cm.has_method(&"camp_of"):
		return null
	var c: Variant = cm.call(&"camp_of", u)
	return c as Node if c is Node and is_instance_valid(c) else null


static func tier_color(tier: int) -> Color:
	return TIER_COLORS.get(clampi(tier, 1, 3), TIER_COLORS[1])


## The hover chip parts for a camp: [`Gloomcap Hollow`, ` · Tier 2`, ` · ~86 XP · +25 essence`].
static func hover_parts(camp: Node) -> Array[String]:
	var r: Dictionary = camp.call(&"reward_preview") if camp.has_method(&"reward_preview") else {}
	var tier := int(r.get(&"tier", camp.get(&"tier") if camp.get(&"tier") != null else 1))
	return [str(camp.get(&"display_name")), " · Tier %d" % tier,
			" · ~%d XP · +%d essence" % [int(r.get(&"xp", 0)), int(r.get(&"essence", 0))]]


## The hover chip's text (tests), "" while hidden.
func hover_text() -> String:
	if not hover_chip.visible:
		return ""
	return hover_labels[0].text + hover_labels[1].text + hover_labels[2].text


func _update_hover() -> void:
	var u: Node = null
	if _hover_allowed() and selection.has_method(&"unit_at") and selection.has_method(&"mouse_position"):
		u = selection.call(&"unit_at", selection.call(&"mouse_position"))
	var camp: Node = null
	if u != null and is_instance_valid(u) and (u as Node3D).is_visible_in_tree():
		camp = camp_of(get_tree(), u)
	if camp == null:
		_hover_unit = null
		hover_chip.visible = false
		return
	if u != _hover_unit:
		_hover_unit = u
		_hover_since = _clock
	if _clock - _hover_since + 0.001 < HOVER_DELAY:
		return
	show_hover(camp)


## Shows the chip for `camp` at the mouse (tests call it directly).
func show_hover(camp: Node) -> void:
	var parts := hover_parts(camp)
	var r: Dictionary = camp.call(&"reward_preview") if camp.has_method(&"reward_preview") else {}
	var tier := int(r.get(&"tier", camp.get(&"tier") if camp.get(&"tier") != null else 1))
	hover_labels[0].text = parts[0]
	hover_labels[1].text = parts[1]
	hover_labels[1].add_theme_color_override("font_color", tier_color(tier))
	hover_labels[2].text = parts[2]
	hover_labels[2].add_theme_color_override("font_color", UIStyle.token(&"text"))
	hover_chip.visible = true
	hover_chip.reset_size()
	_place_hover_chip()


## No window open, no pending order, not in bounty mode, no route chip.
func _hover_allowed() -> bool:
	if selection == null or not is_instance_valid(selection):
		return false
	if selection.has_method(&"get_pending_order") and StringName(selection.call(&"get_pending_order")) != &"":
		return false
	if hud != null and is_instance_valid(hud):
		for w: StringName in [&"shop_window", &"tavern_window", &"trade_window"]:
			var win: Variant = hud.get(w)
			if is_instance_valid(win) and win is Node and (win as Node).has_method(&"is_open") \
					and bool((win as Node).call(&"is_open")):
				return false
	for mode in get_tree().get_nodes_in_group(&"bounty_mode"):
		if mode.has_method(&"is_active") and bool(mode.call(&"is_active")):
			return false
	var line := get_tree().get_first_node_in_group(&"route_line")
	if line != null:
		var chip: Variant = line.get(&"chip")
		if is_instance_valid(chip) and chip is CanvasItem and (chip as CanvasItem).visible:
			return false
	return true


func _place_hover_chip() -> void:
	var vp := get_viewport_rect().size
	var m := get_global_mouse_position()
	var s := hover_chip.size
	var p := m + HOVER_OFFSET
	if p.x + s.x > vp.x - 4.0:
		p.x = m.x - HOVER_OFFSET.x - s.x   # flip left at the right edge
	p.x = clampf(p.x, 4.0, maxf(4.0, vp.x - 4.0 - s.x))
	p.y = clampf(p.y, 4.0, maxf(4.0, vp.y - 4.0 - s.y))
	hover_chip.global_position = p


# ---------------------------------------------------------------- glyphs (ui-mapfill.md 2.3, 9.3)

## The point glyph of `kind` in a box of `s` px at `o` (coordinates of the 18 px design x s / 18), filled `fill`, with
## a 1 px groove outline. A shrine's rune is GOLD while `awake`, else text_muted. `alpha` multiplies everything.
static func draw_point_glyph(ci: CanvasItem, kind: StringName, o: Vector2, s: float, fill: Color, awake: bool,
		alpha := 1.0) -> void:
	var k := s / 18.0
	var f := Color(fill, fill.a * alpha)
	var groove := UIStyle.token(&"groove")
	groove.a *= alpha
	var light := UIStyle.token(&"frame_light")
	light.a *= alpha
	match kind:
		&"watchtower":
			for r: Rect2 in [Rect2(5, 7, 8, 10), Rect2(3, 4, 12, 3), Rect2(3, 1, 3, 3), Rect2(7.5, 1, 3, 3),
					Rect2(12, 1, 3, 3)]:
				var rr := Rect2(o + r.position * k, r.size * k)
				ci.draw_rect(rr, f)
				ci.draw_rect(rr, groove, false, 1.0)
		&"well":
			var c := o + Vector2(9, 11) * k
			ci.draw_circle(c, 6.0 * k, f)
			ci.draw_arc(c, 6.0 * k, 0.0, TAU, 20, groove, 1.0, true)
			ci.draw_circle(c, 3.0 * k, Color(WELL_MIST, alpha))
			ci.draw_polyline(PackedVector2Array([o + Vector2(3, 5) * k, o + Vector2(9, 1) * k, o + Vector2(15, 5) * k]),
					light, 2.0 * k, true)
			ci.draw_line(o + Vector2(4, 5) * k, o + Vector2(4, 10) * k, light, 1.5 * k)
			ci.draw_line(o + Vector2(14, 5) * k, o + Vector2(14, 10) * k, light, 1.5 * k)
		_:
			var pts := PackedVector2Array([o + Vector2(9, 5) * k, o + Vector2(14.5, 11) * k, o + Vector2(9, 17) * k,
					o + Vector2(3.5, 11) * k])
			ci.draw_colored_polygon(pts, f)
			var closed := pts.duplicate()
			closed.append(pts[0])
			ci.draw_polyline(closed, groove, 1.0, true)
			var rune := UIStyle.GOLD if awake else UIStyle.token(&"text_muted")
			ci.draw_circle(o + Vector2(9, 2) * k, maxf(1.5 * k, 1.0), Color(rune, rune.a * alpha))


## The paw glyph (9.3): main pad r 0.28 s at c + (0, 0.15 s), toes r 0.14 s; outline (1 px groove behind each pad)
## unless `outline` is false.
static func draw_paw(ci: CanvasItem, c: Vector2, s: float, color: Color, outline := true) -> void:
	var pads: Array = [[Vector2(0, 0.15), 0.28], [Vector2(-0.30, -0.18), 0.14], [Vector2(0, -0.32), 0.14],
			[Vector2(0.30, -0.18), 0.14]]
	if outline:
		for pad: Array in pads:
			ci.draw_circle(c + (pad[0] as Vector2) * s, float(pad[1]) * s + 0.5 + 0.5, UIStyle.token(&"groove"))
	for pad: Array in pads:
		ci.draw_circle(c + (pad[0] as Vector2) * s, float(pad[1]) * s, color)


## A tooltip panel for the strip / chips (ui-style.md 8): line 1 `Name · Kind` becomes the name (Cinzel 15, title)
## with the kind right-aligned (muted); `On the enemy bank...` in FAR, `Click:` in GOLD, line 2 text, others muted.
static func tooltip_panel(text: String) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.tooltip_style())
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	var lines := text.split("\n")
	for i in lines.size():
		var line: String = lines[i]
		if i == 0 and line.contains(" · "):
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 16)
			var n := UIStyle.display_label(line.get_slice(" · ", 0), 15)
			n.uppercase = false
			n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(n)
			row.add_child(UIStyle.panel_label(line.get_slice(" · ", 1), 13, UIStyle.token(&"text_muted")))
			box.add_child(row)
			continue
		var col := UIStyle.token(&"text_muted")
		if i == 0:
			col = UIStyle.token(&"title")
		elif line.begins_with("On the enemy bank"):
			col = FAR
		elif line.begins_with("Click:"):
			col = UIStyle.GOLD
		elif i == 1:
			col = UIStyle.token(&"text")
		box.add_child(UIStyle.panel_label(line, 13, col))
	return panel


# ---------------------------------------------------------------- inner classes

## Relation colours: own / enemy / neutral (the minimap's green / red, never the kingdom colours).
class GameColors:
	static func relation(team: int, local: int) -> Color:
		if team == local and team >= 0:
			return OWN
		if team == PLAYER_TEAM or team == ENEMY_TEAM:
			return ENEMY
		return POINT_NEUTRAL


## A PanelContainer with the section-8 tooltip.
class TipPanel extends PanelContainer:
	func _make_custom_tooltip(for_text: String) -> Object:
		return MapfillBar.tooltip_panel(for_text)


## One strip icon (28 x 28 slot frame, focus none); the overlay draws the rim state, the halo and the glyph.
class PointIcon extends Button:
	var point: Node3D
	var kind: StringName = &"watchtower"
	var fill := POINT_NEUTRAL
	var awake := false
	var asleep := false
	var contested := false
	var taken := false
	var selected := false
	var overlay: Control
	var _clock := 0.0

	func _ready() -> void:
		custom_minimum_size = Vector2(ICON, ICON)
		size = Vector2(ICON, ICON)
		pivot_offset = Vector2(ICON, ICON) * 0.5
		focus_mode = Control.FOCUS_NONE
		mouse_filter = Control.MOUSE_FILTER_STOP
		overlay = Control.new()
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.draw.connect(_draw_overlay)
		add_child(overlay)
		mouse_entered.connect(overlay.queue_redraw)
		mouse_exited.connect(overlay.queue_redraw)
		apply_skin()

	func apply_skin() -> void:
		add_theme_stylebox_override("normal", UIStyle.button_frame(&"normal"))
		add_theme_stylebox_override("hover", UIStyle.button_frame(&"hover"))
		add_theme_stylebox_override("pressed", UIStyle.button_frame(&"pressed"))
		add_theme_stylebox_override("hover_pressed", UIStyle.button_frame(&"pressed"))
		add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	func _process(delta: float) -> void:
		_clock += delta

	## The rim colour of the current state (first match wins): hover none (the hover frame), selected GOLD, own point
	## being taken WARN (pulse), awake shrine GOLD (pulse), else none (frame_metal).
	func rim_color() -> Color:
		if is_hovered():
			return Color(0, 0, 0, 0)
		if selected:
			return UIStyle.GOLD
		if taken:
			return Color(UIStyle.WARN, 0.8 + 0.2 * sin(_clock * TAU * 2.0))
		if awake:
			return Color(UIStyle.GOLD, 0.85 + 0.15 * sin(_clock * TAU * 2.0))
		return Color(0, 0, 0, 0)

	## The glyph colour: GOLD while awake, the owner colour lerping to white at 3 Hz while contested.
	func glyph_color() -> Color:
		if awake:
			return UIStyle.GOLD
		if contested:
			return fill.lerp(Color.WHITE, 0.5 + 0.5 * sin(_clock * TAU * 3.0))
		return fill

	func _draw_overlay() -> void:
		if awake:
			overlay.draw_rect(Rect2(-2, -2, ICON + 4, ICON + 4), Color(UIStyle.GOLD, 0.35), false, 2.0)
		var rim := rim_color()
		if rim.a > 0.0:
			overlay.draw_rect(Rect2(2, 2, ICON - 4, ICON - 4), rim, false, 2.0)
		MapfillBar.draw_point_glyph(overlay, kind, Vector2(5, 5), GLYPH, glyph_color(), awake, 0.45 if asleep else 1.0)

	## Owner change: scale 1.0 -> 1.2 -> 1.0 in 0.25 s.
	func pop() -> void:
		var t := create_tween()
		t.tween_property(self, "scale", Vector2(1.2, 1.2), 0.125)
		t.tween_property(self, "scale", Vector2.ONE, 0.125)

	func _make_custom_tooltip(for_text: String) -> Object:
		return MapfillBar.tooltip_panel(for_text)


## A screen boss bar (ui-mapfill.md 6.1; reusable for titans and story bosses): 456 x 50 slate with a 1 px BEAST border
## (alpha 0.6) and a drop shadow; paw 14 at (10, 4); name (Cinzel 16, BEAST) + subtitle (` · Epic beast` muted + the
## variant word in GOLD, font 13); state right-aligned (right edge 446, y 4, font 12); HP bar 440 x 18 at (8, 24)
## with ghost damage, heal flash, low-HP pulse, `1 620 / 2 160`, optional phase marks. Click = `clicked(target)`.
class BossBar extends Control:
	signal clicked(target: Node3D)

	var target: Node3D
	var accent := BEAST
	var subtitle := " · Epic beast"
	var state_text := "":
		set(v):
			state_text = v
			if state_label != null:
				_apply_state()
	## Ratios (0-1) that get a 2 px frame_light tick on the bar (later bosses' phases).
	var phase_marks: Array[float] = []
	var dying := false
	var leaving := false
	var panel: Panel
	var paw: Control
	var name_label: Label
	var sub_label: Label
	var variant_label: Label
	var state_label: Label
	var hp_bar: ProgressBar
	var hp_text: Label
	var ghost: Control
	var marks: Control
	var _ghost_value := -1.0
	var _ghost_tween: Tween
	var _last_hp := -1.0
	var _heal_left := 0.0
	var _clock := 0.0
	var _fade: Tween
	var _max_hp := 1.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		panel = Panel.new()
		panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(panel)
		UIStyle.add_drop_shadow(panel)
		paw = Control.new()
		paw.position = Vector2(10, 4)
		paw.size = Vector2(14, 14)
		paw.mouse_filter = Control.MOUSE_FILTER_IGNORE
		paw.draw.connect(func() -> void: MapfillBar.draw_paw(paw, Vector2(7, 7), 14.0, accent))
		add_child(paw)
		var row := HBoxContainer.new()
		row.position = Vector2(28, 2)
		row.size = Vector2(340, 20)
		row.clip_contents = true
		row.add_theme_constant_override("separation", 0)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(row)
		name_label = UIStyle.display_label("", 16, accent)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(name_label)
		sub_label = UIStyle.panel_label("", 13)
		sub_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sub_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(sub_label)
		variant_label = UIStyle.panel_label("", 13, UIStyle.GOLD)
		variant_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		variant_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(variant_label)
		state_label = UIStyle.panel_label("", 12)
		state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		state_label.position = Vector2(346, 4)
		state_label.size = Vector2(100, 16)
		state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(state_label)
		var hb := UIStyle.bar(UIStyle.HP_COLOR, 18.0)
		hp_bar = hb[0]
		hp_text = hb[1]
		hp_bar.position = Vector2(8, 24)
		hp_bar.size = Vector2(440, 18)
		add_child(hp_bar)
		ghost = Control.new()
		ghost.set_anchors_preset(Control.PRESET_FULL_RECT)
		ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ghost.draw.connect(_draw_ghost)
		hp_bar.add_child(ghost)
		hp_bar.move_child(ghost, 0)
		marks = Control.new()
		marks.set_anchors_preset(Control.PRESET_FULL_RECT)
		marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marks.draw.connect(_draw_marks)
		hp_bar.add_child(marks)
		apply_skin()

	func apply_skin() -> void:
		if panel == null:
			return
		var s := UIStyle.slate_style(0.0, Color(accent, 0.6))
		panel.add_theme_stylebox_override("panel", s)
		sub_label.add_theme_color_override("font_color", UIStyle.token(&"text_muted"))
		_apply_state()

	func _apply_state() -> void:
		state_label.text = state_text
		var c := UIStyle.token(&"text_muted")
		if state_text == "Enraged":
			c = UIStyle.WARN
		elif state_text == "Escaping":
			c = FAR
		state_label.add_theme_color_override("font_color", c)

	## Free for a new target: hidden, or fading out after leaving (not a death still playing).
	func is_free() -> bool:
		return target == null or (not visible) or (leaving and not dying)

	## Shows the bar for `unit` (fade in 0.2 s, no slide).
	func show_for(unit: Node3D, title: String, variant: String) -> void:
		if _fade:
			_fade.kill()
		target = unit
		dying = false
		leaving = false
		name_label.text = title
		sub_label.text = subtitle
		variant_label.text = " · " + variant if variant != "" else ""
		_last_hp = -1.0
		_ghost_value = -1.0
		_heal_left = 0.0
		visible = true
		modulate = Color(1, 1, 1, 0)
		_fade = create_tween()
		_fade.tween_property(self, "modulate:a", 1.0, 0.2)
		_update_values(0.0)

	## Leaves (fade out 0.3 s).
	func leave() -> void:
		if leaving or dying or not visible:
			if not visible:
				target = null
			return
		leaving = true
		if _fade:
			_fade.kill()
		_fade = create_tween()
		_fade.tween_property(self, "modulate:a", 0.0, 0.3)
		_fade.tween_callback(_hide)

	## Death: the bar drains to 0, flashes white 0.2 s, fades out over 0.5 s.
	func play_death() -> void:
		if dying:
			return
		dying = true
		leaving = false
		if _fade:
			_fade.kill()
		_fade = create_tween()
		_fade.tween_property(hp_bar, "value", 0.0, 0.2)
		_fade.tween_callback(func() -> void:
			hp_text.text = "0 / %s" % SelectionPanel.thousands(int(_max_hp))
			modulate = Color(2.0, 2.0, 2.0, 1.0))
		_fade.tween_interval(0.2)
		_fade.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
		_fade.tween_callback(_hide)

	func _hide() -> void:
		visible = false
		target = null
		dying = false
		leaving = false
		modulate = Color.WHITE

	func _process(delta: float) -> void:
		if not visible:
			return
		_clock += delta
		if _heal_left > 0.0:
			_heal_left -= delta
		if dying or target == null or not is_instance_valid(target):
			return
		_update_values(delta)

	func _update_values(_delta: float) -> void:
		var hp := float(target.get(&"hp")) if target.get(&"hp") != null else 0.0
		_max_hp = maxf(float(target.get(&"max_hp")) if target.get(&"max_hp") != null else 1.0, 1.0)
		if _last_hp >= 0.0:
			if hp < _last_hp - 0.01:
				if _ghost_value < _last_hp:
					_ghost_value = _last_hp
				if _ghost_tween:
					_ghost_tween.kill()
				_ghost_tween = create_tween()
				_ghost_tween.tween_property(self, "_ghost_value", hp, 0.5).set_ease(Tween.EASE_OUT)
			elif hp > _last_hp + maxf(2.0, _max_hp * 0.01):
				_heal_left = 0.15
		_last_hp = hp
		hp_bar.max_value = _max_hp
		hp_bar.value = hp
		hp_text.text = "%s / %s" % [SelectionPanel.thousands(ceili(hp)), SelectionPanel.thousands(int(_max_hp))]
		var fill := UIStyle.HP_COLOR
		if _heal_left > 0.0:
			fill = Color(0.5, 1.0, 0.5)
		elif hp / _max_hp < 0.3:
			fill = UIStyle.HP_COLOR.lerp(Color(1.0, 0.45, 0.40), 0.5 + 0.5 * sin(_clock * TAU * 1.5))
		UIStyle.set_bar_color(hp_bar, fill)
		ghost.queue_redraw()

	## The ghost segment still showing (tests): the HP it shows, -1 when none.
	func ghost_value() -> float:
		return _ghost_value if _ghost_value > hp_bar.value else -1.0

	func _draw_ghost() -> void:
		if hp_bar.max_value <= 0.0 or _ghost_value <= hp_bar.value:
			return
		var w := ghost.size.x
		var x0 := w * clampf(hp_bar.value / hp_bar.max_value, 0.0, 1.0)
		var x1 := w * clampf(_ghost_value / hp_bar.max_value, 0.0, 1.0)
		ghost.draw_rect(Rect2(x0, 1, x1 - x0, ghost.size.y - 2), Color(1.0, 0.85, 0.8, 0.8))

	func _draw_marks() -> void:
		for r in phase_marks:
			var x := roundf(marks.size.x * clampf(r, 0.0, 1.0))
			marks.draw_rect(Rect2(x - 1.0, 1, 2, marks.size.y - 2), UIStyle.token(&"frame_light"))

	## Name row as plain text (tests): `Old Scarback · Epic beast · alpha`.
	func title_text() -> String:
		return name_label.text + sub_label.text + variant_label.text

	func _gui_input(event: InputEvent) -> void:
		var mb := event as InputEventMouseButton
		if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and target != null \
				and is_instance_valid(target):
			clicked.emit(target)
			accept_event()
