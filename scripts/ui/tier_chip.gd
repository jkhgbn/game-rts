class_name TierChip
extends PanelContainer
## The keep tier indicator (2026-09-30, JS: "not sure there is a way to tier up / get better units"): a small chip that
## always says where the player's keep stands and what comes next:
##   `Tier 1 Keep · next: Stronghold at 3:30`, `... Stronghold: needs a Hall`, `... Stronghold ready: X` (gold, breathing
##   border), `Upgrading to Stronghold 45 % · 33 s` (a gold progress line), `Tier 2 Stronghold · next: Citadel at 5:45`,
##   `Tier 3 Citadel`. A mission that caps the tiers shows no "next" past its cap.
## Click = select the keep and centre the camera on it (then X upgrades). Only while the game has a TierSystem (skirmish,
## mission 1). When the map-fill objectives strip sits under the top bar (skirmish) the chip moves to the top-left
## column, under the Next hint. Attached by GameHUD.setup through attach_optional; `hud.tier_chip`.

const REFRESH := 0.25
const FONT := 14
const GAP := 4.0
const PULSE_PERIOD := 1.0
const TEAM := 0   ## Unit.Team.PLAYER

var hud: Node
var label: Label
var status: Dictionary = {}   ## TierSystem.status(TEAM) at the last refresh (read only).
var ready_now := false        ## The next upgrade can start now: the border breathes gold (read only).
var placement: StringName = &""   ## &"top_bar" (under the top bar) or &"left_column" (read only, tests).
var _left := 0.0
var _clock := 0.0


## Adds the chip to `p_hud` (next to its top bar) when the game has keep tiers; returns it (or null).
static func attach(p_hud: Node) -> TierChip:
	if p_hud == null or TierSystem.instance() == null:
		return null
	var old := p_hud.find_child("TierChip", true, false) as TierChip
	if old != null and not old.is_queued_for_deletion():
		old.hud = p_hud
		return old
	var c := TierChip.new()
	c.name = "TierChip"
	c.hud = p_hud
	var bar: Variant = p_hud.get(&"top_bar")
	var parent: Node = (bar as Control).get_parent() if bar is Control else p_hud
	parent.add_child(c)
	if &"tier_chip" in p_hud:
		p_hud.set(&"tier_chip", c)
	return c


func _ready() -> void:
	add_theme_stylebox_override("panel", UIStyle.slate_style(6.0))
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	label = UIStyle.panel_label("", FONT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	refresh()
	_place.call_deferred()


## The chip's line (tests, audit).
func text() -> String:
	return label.text if label else ""


func _process(delta: float) -> void:
	_clock += delta
	if ready_now or bool(status.get("upgrading", false)):
		queue_redraw()
	_left -= delta
	if _left > 0.0:
		return
	_left = REFRESH
	refresh()
	_place()


## Re-reads the tier status and rewrites the line.
func refresh() -> void:
	if label == null:
		return
	status = TierSystem.status(TEAM)
	visible = not status.is_empty()
	if status.is_empty():
		return
	var t := line_for(status)
	ready_now = int(status["next"]) > 0 and not bool(status["upgrading"]) and String(status["reason"]) == ""
	label.add_theme_color_override("font_color", UIStyle.GOLD if ready_now else UIStyle.token(&"text"))
	if label.text != t:
		label.text = t
		reset_size()
	queue_redraw()


## The chip text for a TierSystem.status dictionary.
static func line_for(st: Dictionary) -> String:
	var tier := int(st.get("tier", 1))
	var now_name := Loc.t(TierSystem.tier_name(tier))   # tier names are translated (glossary)
	if bool(st.get("upgrading", false)):
		return Loc.t("Upgrading to %s %d %% · %d s") % [Loc.t(str(st["name"])), roundi(float(st["progress"]) * 100.0),
				ceili(float(st["left"]))]
	var head := Loc.t("Tier %d %s") % [tier, now_name]
	if int(st.get("next", 0)) == 0:
		return head
	var reason := String(st.get("reason", ""))
	var nxt := Loc.t(String(st.get("name", "")))
	if reason == "":
		return Loc.t("%s · %s ready: %s") % [head, nxt, KeyLabels.of(KEY_X)]
	if reason.begins_with("Available at"):
		return Loc.t("%s · next: %s at %s") % [head, nxt, TierSystem.clock(float(st.get("from", 0.0)))]
	if reason == TierSystem.MSG_NEEDS_HALL:
		return Loc.t("%s · next: %s (needs a Hall)") % [head, nxt]
	return Loc.t("%s · next: %s (%s)") % [head, nxt, (Loc.sink(reason) if Loc.is_french() else reason).to_lower()]


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if ready_now:
		var a := 0.45 + 0.55 * (0.5 + 0.5 * sin(_clock * TAU / PULSE_PERIOD))
		draw_rect(r.grow(1.0), Color(UIStyle.GOLD, 0.3 * a), false, 3.0)
		draw_rect(r.grow(-1.0), Color(UIStyle.GOLD, a), false, 2.0)
	elif bool(status.get("upgrading", false)):
		var p := clampf(float(status.get("progress", 0.0)), 0.0, 1.0)
		draw_rect(Rect2(2.0, size.y - 4.0, (size.x - 4.0) * p, 2.0), UIStyle.GOLD)


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		select_keep()
		accept_event()


## Selects the player's keep (the one the tier button lives on) and centres the camera on it.
func select_keep() -> void:
	var k: Keep = status.get("keep") if status.get("keep") is Keep else TierSystem.keep_of(TEAM)
	if k == null or not is_instance_valid(k):
		return
	var level: Node = hud.get_parent() if hud else null
	var sel: Variant = level.get(&"selection") if level else null
	if sel is SelectionManager:
		(sel as SelectionManager).select_building(k)
	var rig: Variant = level.get(&"camera_rig") if level else null
	if rig is Object and (rig as Object).has_method(&"focus_on"):
		(rig as Object).call(&"focus_on", k.global_position)


## Under the top bar's left end. When the map-fill objectives strip is there (skirmish), the top-left column instead:
## under the Next hint, else under the objective panel.
func _place() -> void:
	var bar: Variant = hud.get(&"top_bar") if hud else null
	if not (bar is Control):
		return
	var b := (bar as Control).get_global_rect()
	var pos := Vector2(b.position.x, b.end.y + GAP)
	var mf: Variant = hud.get(&"mapfill_bar") if &"mapfill_bar" in hud else null
	if mf is Object and is_instance_valid(mf):
		var strip: Variant = (mf as Object).get(&"strip")
		if strip is Control and (strip as Control).is_visible_in_tree() \
				and Rect2(pos, size).grow(GAP).intersects((strip as Control).get_global_rect()):
			pos = _left_column_spot()
	global_position = pos
	placement = &"top_bar" if pos.y == b.end.y + GAP else &"left_column"


## Where the chip goes in the top-left column: under a mission's objectives panel (MissionHud), the visible Next hint
## or the objective panel, else (16, 16).
func _left_column_spot() -> Vector2:
	var lvl: Node = hud.get_parent() if hud else null
	var mh: Variant = lvl.get(&"mission_hud") if lvl != null and &"mission_hud" in lvl else null
	if mh is Object and is_instance_valid(mh):
		var op: Variant = (mh as Object).get(&"objectives_panel")
		if op is Control and is_instance_valid(op) and (op as Control).is_visible_in_tree():
			var orect := (op as Control).get_global_rect()
			return Vector2(orect.position.x, orect.end.y + GAP)
	for key in [&"next_step_hint", &"objective_panel"]:
		var c: Variant = null
		if key == &"objective_panel":
			c = hud.call(&"objective_panel") if hud.has_method(&"objective_panel") else null
		else:
			c = hud.get(key) if key in hud else null
		if c is Control and is_instance_valid(c) and (c as Control).is_visible_in_tree():
			var r := (c as Control).get_global_rect()
			return Vector2(r.position.x, r.end.y + GAP)
	return Vector2(16, 16)
