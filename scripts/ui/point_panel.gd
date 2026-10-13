class_name PointPanel
extends Control
## The capture point panel and the game-critter card (step 12, task 12.C7; spec: map-fill.md 4 / 3.4 / 8, layout:
## docs/design/ui-mapfill.md 4.2 and 7.2). 676 x 204 at (588, 670), anchored to the bottom like the post panel,
## painting an opaque `panel_bg` over the selection area. Visible only while `selection.selected_neutral` (12.C6: set
## by a click on a point or a critter) is a node in group "capture_points" (the point panel) or a game critter
## (`is_game_critter()`: the critter card). Refreshes at 10 Hz. Read only: nothing here orders anything.
## - Point: tile (owner rim, icon art/icons/points/<kind>.png or the code glyph), `ROOKWATCH · watchtower`, the owner
##   line, the state line (+ the capture bar where the local team sees the point), the effect, the far-bank line, the
##   hint. The texts are static helpers the objectives strip reuses for its tooltips.
## - Critter: tile, `RED DEER · game`, HP bar, the reward (`Hunt it: +5 essence, venison heals the hunter 40 HP`), the
##   venison line, `Grazing` / `Fleeing`, the hint.
## Step-12 nodes are reached untyped (get / has_method); without a selection side the panel simply stays hidden.

const RECT := Rect2(588, 670, 676, 204)
const BOTTOM := 900.0
const REFRESH := 0.1
const TILE := 96.0
const X_TEXT := 108.0            ## 696 - 588
const Y_HINT := 136.0            ## y 806
## Point lines: owner y 700, state y 722, effect y 746, far bank y 770.
const POINT_Y: Array[float] = [30.0, 52.0, 76.0, 100.0]
## Critter lines: reward y 730, venison y 752, state y 774 (the HP bar is at y 700).
const CRITTER_Y: Array[float] = [60.0, 82.0, 104.0, 126.0]
const CAPTURE_BAR := Rect2(272, 57, 200, 10)   ## (860, 727) on screen.
const GROUP := &"point_panel"
const PLAYER_TEAM := 0
const ENEMY_TEAM := 1
const WELL_START := 150.0
const OWN := Color(0.3, 1.0, 0.4)
const ENEMY := Color(1.0, 0.3, 0.3)
const NEAR := Color(0.4, 0.9, 0.4)
const FAR := Color(1.0, 0.55, 0.2)
const KIND_WORDS := {&"watchtower": "watchtower", &"well": "essence well", &"shrine": "wayshrine"}
const POINT_HINT := "Capture: stand in the ring with soldiers, champions or your wizard · R: Guard it when yours"
const CRITTER_HINT := "Right-click with soldiers or your wizard selected to hunt it · workers and caravans ignore it"
const FAR_BANK := "On the enemy bank: capture takes 25 % longer"
const WELL_EFFECT := "+0.4 essence / s · +3 mana / s to your wizard within 8 m"
const WELL_LATE := "  ·  pays from 2:30"
const SHRINE_EFFECT := "Blessing: +12 % speed, +1.5 HP / s for 60 s"
const VENISON_HEAL := 40.0
const VENISON_AREA_HEAL := 20.0

var selection: Node
var hud: Node
## Read only (tests): the node shown and its kind (&"point", &"critter", &"" = hidden).
var shown: Node3D
var kind: StringName = &""
var title_label: Label
var title_suffix: Label
var lines: Array[HBoxContainer] = []       ## 4 lines of coloured segments.
var hint_label: Label
var capture_bar: ProgressBar
var hp_bar: ProgressBar
var hp_text: Label

var _tile: Control
var _tile_icon: Texture2D = null
var _tile_abbr := ""
var _tile_rim := Color(0, 0, 0, 0)
var _tile_awake := false
var _refresh_left := 0.0
var _clock := 0.0


## Adds the panel under `hud` once (a second call returns the same panel).
static func attach(p_hud: Node, p_selection: Node = null) -> PointPanel:
	var tree := Engine.get_main_loop() as SceneTree
	var panel: PointPanel = null
	if tree != null:
		for n in tree.get_nodes_in_group(GROUP):
			if n is PointPanel and not n.is_queued_for_deletion():
				panel = n
				break
	if panel == null:
		panel = PointPanel.new()
		panel.name = "PointPanel"
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
	offset_top = -(BOTTOM - RECT.position.y)
	offset_bottom = -(BOTTOM - RECT.end.y)
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
	for i in 4:
		var box := HBoxContainer.new()
		box.add_theme_constant_override("separation", 0)
		box.position = Vector2(X_TEXT, POINT_Y[i])
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(box)
		lines.append(box)
	hint_label = UIStyle.panel_label("", 12)
	hint_label.position = Vector2(X_TEXT, Y_HINT)
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint_label)
	var cb := UIStyle.bar(OWN, CAPTURE_BAR.size.y)
	capture_bar = cb[0]
	(cb[1] as Label).visible = false   # no text on the capture bar
	capture_bar.position = CAPTURE_BAR.position
	capture_bar.size = CAPTURE_BAR.size
	capture_bar.max_value = 1.0
	capture_bar.get_node(^"Ticks").visible = false
	capture_bar.visible = false
	add_child(capture_bar)
	var hb := UIStyle.bar(UIStyle.HP_COLOR)
	hp_bar = hb[0]
	hp_text = hb[1]
	hp_bar.position = Vector2(X_TEXT, 30)
	hp_bar.size = Vector2(280, 22)
	hp_bar.visible = false
	add_child(hp_bar)
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
	queue_redraw()
	_tile.queue_redraw()


func _process(delta: float) -> void:
	_clock += delta
	if not visible and _selected() == null:
		return
	if _tile_awake:
		_tile.queue_redraw()
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		refresh()


func _draw() -> void:
	var bg := UIStyle.token(&"panel_bg")
	draw_rect(Rect2(Vector2.ZERO, size), Color(bg.r, bg.g, bg.b, 1.0))


## The selection's point / critter (12.C6's `selected_neutral`), or null.
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


## &"point" (group "capture_points"), &"critter" (`is_game_critter()`), or &"" for anything else.
static func kind_of(n: Node) -> StringName:
	if n == null or not is_instance_valid(n):
		return &""
	if n.is_in_group(&"capture_points"):
		return &"point"
	if n.has_method(&"is_game_critter") and bool(n.call(&"is_game_critter")):
		return &"critter"
	return &""


## Rebuilds the panel from the selected point / critter (hidden when none).
func refresh() -> void:
	_refresh_left = REFRESH
	var n := _selected()
	var k := kind_of(n)
	visible = k != &""
	if n != shown or k != kind:
		shown = n
		kind = k
		_layout(k)
	if k == &"":
		return
	match k:
		&"point":
			_refresh_point(n)
		&"critter":
			_refresh_critter(n)
	_tile.queue_redraw()


func _layout(k: StringName) -> void:
	var ys: Array[float] = CRITTER_Y if k == &"critter" else POINT_Y
	for i in lines.size():
		lines[i].position = Vector2(X_TEXT, ys[i])
	hp_bar.visible = k == &"critter"
	capture_bar.visible = false


## The shown lines (tests): title, then each line (as shown, "" when hidden) and the hint.
func panel_lines() -> PackedStringArray:
	var out: PackedStringArray = [title_label.text.to_upper() + title_suffix.text]
	for box in lines:
		out.append(line_text(box))
	out.append(hint_label.text)
	return out


static func line_text(box: HBoxContainer) -> String:
	var s := ""
	if not box.visible:
		return s
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


## Sets line `i` from [text, colour, font size] segments (labels are reused); no segments = hidden.
func _set_line(i: int, segments: Array, default_size := 14) -> void:
	var box := lines[i]
	box.visible = not segments.is_empty()
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
		l.add_theme_font_size_override("font_size", int(seg[2]) if seg.size() > 2 else default_size)


# ---------------------------------------------------------------- text helpers (also the strip's tooltips)

## The local team (the fog's), else PLAYER.
static func local_team_of(tree: SceneTree) -> int:
	var fog := FogOfWar.find() if tree != null else null
	return fog.local_team if fog != null else PLAYER_TEAM


## True when team `team` sees `pos` now (no fog = seen).
static func seen_by(team: int, pos: Vector3) -> bool:
	var fog := FogOfWar.find()
	return fog == null or fog.is_visible(team, pos)


## Match time of the CapturePoints service (group "capture_points_service"), else 0.
static func match_time_of(tree: SceneTree) -> float:
	var cp := tree.get_first_node_in_group(&"capture_points_service") if tree != null else null
	return float(cp.call(&"match_time")) if cp != null and cp.has_method(&"match_time") else 0.0


static func kind_word(k: StringName) -> String:
	return Loc.t(str(KIND_WORDS.get(k, "point")))


## [text, colour] of the owner line: towers / wells `Held by you` / `Held by the enemy` / `Neutral`; shrines `Last
## captured by you` / `Last captured by the enemy` / `Not captured yet`.
static func owner_segment(p: Node, team: int) -> Array:
	var owner := int(p.get(&"owner_team")) if p.get(&"owner_team") != null else -1
	var shrine := StringName(str(p.get(&"kind"))) == &"shrine"
	var rel := relation_of(owner, team)
	if rel == &"self":
		return [Loc.t("Last captured by you") if shrine else Loc.t("Held by you"), NEAR]
	if rel == &"ally":   # U3-7: an allied seat (2v2) is not the enemy
		return [Loc.t("Last captured by your ally") if shrine else Loc.t("Held by your ally"), NEAR]
	if rel == &"enemy":
		return [Loc.t("Last captured by the enemy") if shrine else Loc.t("Held by the enemy"), UIStyle.WARN]
	return [Loc.t("Not captured yet") if shrine else Loc.t("Neutral"), UIStyle.token(&"text_muted")]


## U3-7: &"self" / &"ally" / &"enemy" for a seat `owner` seen by `team` (Teams.relation), &"" for none / neutral.
static func relation_of(owner: int, team: int) -> StringName:
	if owner < 0 or owner == Teams.NEUTRAL:
		return &""
	return Teams.relation(team, owner)


## `7 / 12 s` for the point's current progress (T = time_for(capture team, 1), far bank included).
static func progress_text(p: Node) -> String:
	var cap := int(p.get(&"capture_team"))
	var t := float(p.call(&"time_for", cap, 1)) if p.has_method(&"time_for") else float(p.get(&"capture_time"))
	return "%d / %d s" % [floori(float(p.get(&"progress")) * t), ceili(t)]


## [text, colour] of the state line ("" = hidden): capturing / neutralising (own NEAR, enemy WARN), contested FAR,
## fading, asleep, awake GOLD; `Not in sight` when the local team does not see the point now.
static func state_segment(p: Node, team: int, seen: bool) -> Array:
	var muted := UIStyle.token(&"text_muted")
	if not seen:
		return [Loc.t("Not in sight"), muted]
	var st := StringName(str(p.get(&"state")))
	var cap := int(p.get(&"capture_team"))
	var prog := float(p.get(&"progress"))
	var own := cap == team
	var pa := {"progress": progress_text(p)} if cap != -1 or st in [&"capturing", &"neutralising"] else {}
	match st:
		&"capturing":
			return [Loc.t("Capturing {progress}", pa) if own else Loc.t("The enemy is capturing {progress}", pa),
					NEAR if own else UIStyle.WARN]
		&"neutralising":
			return [Loc.t("Neutralising {progress}", pa) if own else Loc.t("The enemy is neutralising {progress}", pa),
					NEAR if own else UIStyle.WARN]
		&"contested":
			return [Loc.t("Contested: both sides are here"), FAR]
		&"asleep":
			var t := float(p.call(&"time_until_awake")) if p.has_method(&"time_until_awake") else INF
			return [Loc.t("Asleep") if t == INF else Loc.t("Asleep: wakes in {time}", {"time": MapfillBar.mmss(t)}), muted]
		&"awake":
			return [Loc.t("Awake: capture it for the blessing"), UIStyle.GOLD]
	if cap != -1 and prog > 0.0:
		return [Loc.t("Capture fading {progress}", pa), muted]
	return ["", muted]


## The effect segments [[text, colour, size]...]: tower `Sight 22 for its owner`; well `+0.4 essence / s · +3 mana /
## s to your wizard within 8 m` (+ `  ·  pays from 2:30` in WARN before 2:30); shrine the blessing.
static func effect_segments(p: Node, now: float) -> Array:
	var text := UIStyle.token(&"text")
	match StringName(str(p.get(&"kind"))):
		&"watchtower":
			var sight := float(p.call(&"sight_radius")) if p.has_method(&"sight_radius") else 22.0
			return [[Loc.t("Sight {n} for its owner", {"n": roundi(sight)}), text, 13]]
		&"well":
			var segs: Array = [[Loc.t(WELL_EFFECT), text, 13]]
			if now < WELL_START:
				segs.append([Loc.t(WELL_LATE), UIStyle.WARN, 13])
			return segs
	return [[Loc.t(SHRINE_EFFECT), text, 13]]


static func effect_text(p: Node, now: float) -> String:
	var s := ""
	for seg: Array in effect_segments(p, now):
		s += str(seg[0])
	return s


## `On the enemy bank: capture takes 25 % longer` when the point is on the other team's bank (not the isle), else "".
static func far_bank_text(p: Node, team: int) -> String:
	var bank := int(p.get(&"bank")) if p.get(&"bank") != null else -1
	# U3-7: banks are sides (0 / 1); an allied seat shares its side's bank
	return Loc.t(FAR_BANK) if (bank == PLAYER_TEAM or bank == ENEMY_TEAM) and bank != Teams.side_of(team) else ""


# ---------------------------------------------------------------- point

func _refresh_point(p: Node3D) -> void:
	var tree := get_tree()
	var team := local_team_of(tree)
	var now := match_time_of(tree)
	var seen := seen_by(team, p.global_position)
	var k := StringName(str(p.get(&"kind")))
	title_label.text = str(p.get(&"display_name"))
	title_suffix.text = " · " + kind_word(k)
	var owner: Array = owner_segment(p, team)
	_set_line(0, [[owner[0], owner[1], 14]])
	var state: Array = state_segment(p, team, seen)
	_set_line(1, [] if str(state[0]) == "" else [[state[0], state[1], 14]])
	_set_line(2, effect_segments(p, now), 13)
	var far := far_bank_text(p, team)
	_set_line(3, [] if far == "" else [[far, FAR, 13]])
	hint_label.text = POINT_HINT
	# The capture bar: capturing / neutralising / decaying, only where the local team sees the point.
	var st := StringName(str(p.get(&"state")))
	var cap := int(p.get(&"capture_team"))
	var prog := float(p.get(&"progress"))
	var show_bar := seen and cap != -1 and prog > 0.0 and st != &"contested"
	if seen and st == &"contested" and cap != -1 and prog > 0.0:
		show_bar = true   # frozen, still shown
	capture_bar.visible = show_bar
	if show_bar:
		capture_bar.value = clampf(prog, 0.0, 1.0)
		UIStyle.set_bar_color(capture_bar, OWN if Teams.is_ally(cap, team) else ENEMY)
	# Tile.
	var owner_team := int(p.get(&"owner_team"))
	_tile_awake = k == &"shrine" and st == &"awake"
	var owner_rel := relation_of(owner_team, team)
	if owner_rel == &"self" or owner_rel == &"ally":
		_tile_rim = OWN
	elif owner_rel == &"enemy":
		_tile_rim = UIStyle.DEFEAT
	else:
		_tile_rim = UIStyle.token(&"frame_dark")
	var icon_id := k
	if k == &"shrine" and st == &"asleep":
		icon_id = &"shrine_asleep"
	_tile_icon = IconLibrary.icon_for(&"points", icon_id)
	if _tile_icon == null and icon_id == &"shrine_asleep":
		_tile_icon = IconLibrary.icon_for(&"points", &"shrine")
	_tile_abbr = ""


# ---------------------------------------------------------------- critter

## The venison numbers (CritterHerds.VENISON_HEAL / VENISON_AREA_HEAL), from the herds' script when it exists.
static func venison_numbers(tree: SceneTree) -> Vector2:
	var herds := tree.get_first_node_in_group(&"critter_herds") if tree != null else null
	var heal := VENISON_HEAL
	var area := VENISON_AREA_HEAL
	if herds != null and herds.get_script() is Script:
		var consts := (herds.get_script() as Script).get_script_constant_map()
		heal = float(consts.get("VENISON_HEAL", heal))
		area = float(consts.get("VENISON_AREA_HEAL", area))
	return Vector2(heal, area)


## The reward segments: `+5 essence` (ESSENCE_TEXT) and, for a deer, `, venison heals the hunter 40 HP`; unknown keys
## (step 15 food...) appended as `+10 food`.
static func reward_segments(c: Node, venison: Vector2) -> Array:
	var reward: Variant = c.get(&"reward")
	var r: Dictionary = reward if reward is Dictionary else {}
	var text := UIStyle.token(&"text")
	var segs: Array = []
	var essence := int(r.get(&"essence", r.get("essence", 0)))
	if essence > 0:
		segs.append([Loc.t("+{n} essence", {"n": essence}), UIStyle.ESSENCE_TEXT])
	if StringName(str(c.get(&"kind"))) == &"deer":
		segs.append([Loc.t(", venison heals the hunter "), text])
		segs.append([Loc.t("{n} HP", {"n": roundi(venison.x)}), NEAR])
	for key: Variant in r.keys():
		if str(key) == "essence":
			continue
		segs.append([", +%d %s" % [int(r[key]), str(key)] if not segs.is_empty() else "+%d %s" % [int(r[key]), str(key)],
				text])
	return segs


## The critter card as one line (tests; map-fill.md 8): `Red deer · 60 HP · Hunt it: +5 essence, venison heals the
## hunter 40 HP` / `Rabbit · +1 essence`.
static func card_line(c: Node, venison: Vector2) -> String:
	var reward := ""
	for seg: Array in reward_segments(c, venison):
		reward += str(seg[0])
	var n := str(c.get(&"display_name"))
	if StringName(str(c.get(&"kind"))) == &"deer":
		return Loc.t("{name} · {hp} HP · Hunt it: {reward}", {"name": n, "hp": roundi(float(c.get(&"max_hp"))),
				"reward": reward})
	return "%s · %s" % [n, reward]


## The shown critter's card line (tests), "" when no critter is shown.
func card_text() -> String:
	if kind != &"critter" or shown == null or not is_instance_valid(shown):
		return ""
	return card_line(shown, venison_numbers(get_tree()))


func _refresh_critter(c: Node3D) -> void:
	var venison := venison_numbers(get_tree())
	var deer := StringName(str(c.get(&"kind"))) == &"deer"
	var dn := str(c.get(&"display_name"))
	title_label.text = dn
	title_suffix.text = " · game"
	var hp := maxf(float(c.get(&"hp")), 0.0)
	var max_hp := maxf(float(c.get(&"max_hp")), 1.0)
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	hp_text.text = Loc.t("HP  {hp} / {max}", {"hp": ceili(hp), "max": int(max_hp)})
	var segs: Array = [[Loc.t("Hunt it: "), UIStyle.token(&"text_muted")]]
	segs.append_array(reward_segments(c, venison))
	_set_line(0, segs, 14)
	_set_line(1, [[Loc.t("Your units within 6 m heal {n} HP", {"n": roundi(venison.y)}), UIStyle.token(&"text_muted"), 13]] \
			if deer else [])
	var fleeing := c.has_method(&"is_fleeing") and bool(c.call(&"is_fleeing"))
	_set_line(2, [["Fleeing", FAR, 13]] if fleeing else [["Grazing", UIStyle.token(&"text"), 13]])
	_set_line(3, [])
	hint_label.text = CRITTER_HINT
	capture_bar.visible = false
	_tile_awake = false
	_tile_rim = UIStyle.token(&"frame_dark")
	_tile_icon = IconLibrary.icon_for(&"critters", StringName(str(c.get(&"kind"))))
	_tile_abbr = UIStyle.abbrev(dn)


# ---------------------------------------------------------------- tile

## The 96 px tile: slot frame with the owner rim (awake shrine: GOLD pulsing), portrait gradient, the icon (88,
## inset 4) or the fallback (point glyph 60 px, alpha 0.9; critter: the abbreviation, display font 28).
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
	elif kind == &"point" and shown != null and is_instance_valid(shown):
		var pk := StringName(str(shown.get(&"kind")))
		var team := local_team_of(get_tree()) if is_inside_tree() else PLAYER_TEAM
		var fill := MapfillBar.GameColors.relation(int(shown.get(&"owner_team")), team)
		if _tile_awake:
			fill = UIStyle.GOLD
		MapfillBar.draw_point_glyph(_tile, pk, Vector2(18, 18), 60.0, fill, _tile_awake, 0.9)
	elif _tile_abbr != "":
		var font := UIStyle.display_font()
		var w := font.get_string_size(_tile_abbr, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
		_tile.draw_string(font, Vector2((TILE - w) * 0.5, TILE * 0.5 + 10.0), _tile_abbr, HORIZONTAL_ALIGNMENT_LEFT,
				-1, 28, UIStyle.token(&"title"))
	var rim := _tile_rim
	if _tile_awake:
		rim = Color(UIStyle.GOLD, 0.85 + 0.15 * sin(_clock * TAU * 2.0))
	_tile.draw_rect(r.grow(-1.0), UIStyle.token(&"groove"), false, 1.0)
	_tile.draw_rect(r.grow(-2.5), rim if rim.a > 0.0 else UIStyle.token(&"frame_dark"), false, 2.0)


## The tile's rim colour now (tests).
func tile_rim() -> Color:
	return _tile_rim
