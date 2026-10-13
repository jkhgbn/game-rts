class_name AlertStack
extends Control
## The alert stack (docs/design/ui-sc2-console.md 3.3, task SC2.U3): up to 5 tiles 36 x 36 at (8, 340 - 40 i) at
## 1600 x 900 (newest at the bottom), bottom-left above the champion slots. Kinds: under attack (WARN, crossed
## swords), building done (GOLD, hammer), tier reached (GOLD, crown), champion fallen (WARN, skull), horn / wave
## (trim_glow, horn), hunt bounty on you (WARN, coin). Each fades after 12 s; a new alert of the same kind near an
## existing one (same source) merges into it (count badge, timer reset). Click = centre the camera there; tooltip =
## the message. Every alert also pings the minimap (3 rings 0.9 s; the hunt bounty's own ping is the minimap's).
## Sources, all read from the outside (no hook in other owners' code): own buildings' `damaged`, own units' HP drops
## (polled), Events.building_completed, TierSystem.tier_changed, own champions dying (polled), the Wave Strike horn,
## the minimap's hunt pings.

signal alerted(kind: StringName, message: String)

const MAX_ALERTS := 5
const TILE := 36.0
const STEP := 40.0
const POS := Vector2(8, 340)        ## The newest (bottom) tile at 1600 x 900.
const LIFETIME := 12.0
const FADE := 1.0                   ## The last second fades out.
const MERGE_RADIUS := 25.0          ## Same kind within this many metres = the same source.
const POLL := 0.5
const ATTACK_REPEAT := 5.0          ## A merged under-attack alert counts again at most this often.
const KINDS := [&"attack", &"built", &"tier", &"champion", &"horn", &"hunt"]

var selection: SelectionManager
var minimap: Minimap
## Read only (tests): [{kind, message, at: Vector3, left, count, tile}], newest last.
var alerts: Array[Dictionary] = []

var _poll_left := 0.0
var _unit_hp := {}          # instance id -> last polled hp (own units)
var _champ_alive := {}      # instance id -> alive at the last poll (own champions)
var _watched_buildings := {}
var _tier_connected := false
var _horn_connected := false
var _last_attack_ms := {}   # alert index key -> ms


func _ready() -> void:
	name = "AlertStack"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	var top := POS.y - STEP * (MAX_ALERTS - 1)
	offset_left = POS.x
	offset_right = POS.x + TILE
	offset_top = -(900.0 - top)
	offset_bottom = -(900.0 - POS.y - TILE)
	var events := get_node_or_null(^"/root/Events")
	if events != null and events.has_signal(&"building_completed"):
		events.connect(&"building_completed", _on_building_completed)


func setup(p_selection: SelectionManager, p_minimap: Minimap) -> void:
	selection = p_selection
	minimap = p_minimap
	if minimap != null and minimap.has_signal(&"hunt_pinged") and not minimap.hunt_pinged.is_connected(_on_hunt_pinged):
		minimap.hunt_pinged.connect(_on_hunt_pinged)


func _process(delta: float) -> void:
	for a in alerts:
		a["left"] = float(a["left"]) - delta
	var gone := alerts.filter(func(a: Dictionary) -> bool: return float(a["left"]) <= 0.0)
	if not gone.is_empty():
		for a in gone:
			(a["tile"] as Control).queue_free()
		alerts = alerts.filter(func(a: Dictionary) -> bool: return float(a["left"]) > 0.0)
		_layout()
	for a in alerts:
		(a["tile"] as Control).modulate.a = clampf(float(a["left"]) / FADE, 0.0, 1.0)
	_poll_left -= delta
	if _poll_left <= 0.0:
		_poll_left = POLL
		_poll()


## Adds an alert (or merges it into one of the same kind near `at`). Returns the alert's dictionary.
func push(kind: StringName, message: String, at: Vector3, ping := true) -> Dictionary:
	for a in alerts:
		if a["kind"] == kind and _flat(a["at"], at) <= MERGE_RADIUS:
			a["left"] = LIFETIME
			a["count"] = int(a["count"]) + 1
			a["message"] = message
			_style_tile(a)
			return a
	var tile := AlertTile.new()
	tile.kind = kind
	tile.pressed.connect(_on_tile_pressed.bind(tile))
	add_child(tile)
	var a := {"kind": kind, "message": message, "at": at, "left": LIFETIME, "count": 1, "tile": tile}
	alerts.append(a)
	while alerts.size() > MAX_ALERTS:
		(alerts[0]["tile"] as Control).queue_free()
		alerts.remove_at(0)
	_style_tile(a)
	_layout()
	if ping and minimap != null and is_instance_valid(minimap) and minimap.has_method(&"alert_ping"):
		minimap.alert_ping(at, AlertTile.color_of(kind))
	alerted.emit(kind, message)
	return a


func _style_tile(a: Dictionary) -> void:
	var tile: AlertTile = a["tile"]
	tile.count = int(a["count"])
	tile.tooltip_text = Loc.sink(String(a["message"]))
	tile.queue_redraw()


## Newest at the bottom (y 340), older ones above.
func _layout() -> void:
	var n := alerts.size()
	for i in n:
		var tile: Control = alerts[i]["tile"]
		var slot := n - 1 - i   # 0 = newest
		tile.position = Vector2(0, size.y - TILE - STEP * slot)
		tile.size = Vector2(TILE, TILE)


func _on_tile_pressed(tile: AlertTile) -> void:
	for a in alerts:
		if a["tile"] == tile:
			var level := get_tree().current_scene if is_inside_tree() else null
			var rig: Variant = level.get(&"camera_rig") if level != null and &"camera_rig" in level else null
			if rig is Object and (rig as Object).has_method(&"focus_on"):
				(rig as Object).call(&"focus_on", a["at"])
			return


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _team() -> int:
	if selection != null and selection.hero != null and is_instance_valid(selection.hero):
		return int(selection.hero.team)
	return Unit.Team.PLAYER


# ---------------------------------------------------------------- sources

func _poll() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	var team := _team()
	# Own buildings: their `damaged` signal (connected once each).
	for b in tree.get_nodes_in_group(&"buildings"):
		if b.get("team") == null or int(b.get("team")) != team or not b.has_signal(&"damaged"):
			continue
		var id := b.get_instance_id()
		if not _watched_buildings.has(id):
			_watched_buildings[id] = true
			b.connect(&"damaged", _on_building_damaged.bind(b))
	# Own units: an HP drop since the last poll = under attack (champions fall separately).
	var seen := {}
	for u in tree.get_nodes_in_group(&"units"):
		var unit := u as Unit
		if unit == null or unit.team != team:
			continue
		var id := unit.get_instance_id()
		seen[id] = true
		if unit.is_in_group(&"champions"):
			var alive := unit.is_alive()
			if _champ_alive.get(id, true) and not alive:
				push(&"champion", Loc.t("{name} has fallen", {"name": ChampionBar.display_name_of(unit)}),
						unit.global_position)
			_champ_alive[id] = alive
		if not unit.is_alive():
			continue
		var before: float = _unit_hp.get(id, unit.hp)
		_unit_hp[id] = unit.hp
		if unit.hp < before - 0.5:
			_attack_at(unit.global_position)
	for id in _unit_hp.keys():
		if not seen.has(id):
			_unit_hp.erase(id)
	if not _tier_connected:
		var ts := TierSystem.instance()
		if ts != null:
			_tier_connected = true
			ts.tier_changed.connect(_on_tier_changed)
	if not _horn_connected:
		var wd := tree.get_first_node_in_group(&"wave_director")
		if wd != null and wd.has_signal(&"horn"):
			_horn_connected = true
			wd.connect(&"horn", _on_horn)


func _attack_at(at: Vector3) -> void:
	if _on_screen(at):
		return   # the player is looking at the fight
	var now := Time.get_ticks_msec()
	for a in alerts:
		if a["kind"] == &"attack" and _flat(a["at"], at) <= MERGE_RADIUS:
			var key := (a["tile"] as Node).get_instance_id()
			if now - int(_last_attack_ms.get(key, 0)) < int(ATTACK_REPEAT * 1000.0):
				a["left"] = LIFETIME   # still fighting: keep it up, count it again later
				return
			_last_attack_ms[key] = now
			break
	var a := push(&"attack", Loc.t("You are under attack"), at)
	_last_attack_ms[(a["tile"] as Node).get_instance_id()] = now


## True when the world point is inside the camera's view.
func _on_screen(at: Vector3) -> bool:
	var cam: Camera3D = selection.camera if selection != null else null
	if cam == null or not cam.is_inside_tree() or cam.is_position_behind(at):
		return false
	var p := cam.unproject_position(at)
	var vp := cam.get_viewport().get_visible_rect()
	return vp.grow(-8.0).has_point(p)


func _on_building_damaged(_amount: float, _attacker: Node3D, b: Node) -> void:
	if is_instance_valid(b) and b is Node3D:
		_attack_at((b as Node3D).global_position)


func _on_building_completed(b: Node3D) -> void:
	if b == null or not is_instance_valid(b) or b.get("team") == null or int(b.get("team")) != _team():
		return
	var type: Variant = b.get("building_type")
	var n := str(type.get("display_name")) if type is Object else "Building"
	push(&"built", Loc.t("{building} complete", {"building": Loc.sink(n)}), b.global_position)


func _on_tier_changed(team: int, tier: int) -> void:
	if team != _team():
		return
	var at := Vector3.ZERO
	var st := TierSystem.status(team)
	if st.get("keep") is Node3D:
		at = (st["keep"] as Node3D).global_position
	push(&"tier", Loc.t("{tier} reached", {"tier": Loc.t(TierSystem.tier_name(tier))}), at)


func _on_horn(index: int) -> void:
	var at := Vector3.ZERO
	if selection != null and selection.hero != null and is_instance_valid(selection.hero):
		at = selection.hero.global_position
	push(&"horn", Loc.t("Horn {n}: the wave marches", {"n": index + 1}), at, false)


func _on_hunt_pinged(at: Vector3) -> void:
	push(&"hunt", Loc.t("A bounty is on your head"), at, false)


## One alert tile: slate, 1 px border in the kind's colour, its 24 px glyph, the merge count (gold badge).
class AlertTile extends Button:
	var kind: StringName = &"attack"
	var count := 1

	func _ready() -> void:
		focus_mode = Control.FOCUS_NONE
		custom_minimum_size = Vector2(AlertStack.TILE, AlertStack.TILE)
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			var st := UIStyle.slate_style(0.0, AlertTile.color_of(kind))
			if state == "hover":
				st.bg_color = st.bg_color.lightened(0.1)
			add_theme_stylebox_override(state, st)

	static func color_of(k: StringName) -> Color:
		match k:
			&"built", &"tier":
				return UIStyle.GOLD
			&"horn":
				return UIStyle.token(&"trim_glow")
		return UIStyle.WARN

	func _draw() -> void:
		var col := AlertTile.color_of(kind)
		var o := Vector2(6, 6)
		match kind:
			&"attack":
				draw_line(o + Vector2(2, 2), o + Vector2(22, 22), col, 2.5, true)
				draw_line(o + Vector2(22, 2), o + Vector2(2, 22), col, 2.5, true)
				draw_line(o + Vector2(2, 16), o + Vector2(8, 22), col, 2.0, true)
				draw_line(o + Vector2(22, 16), o + Vector2(16, 22), col, 2.0, true)
			&"built":
				draw_colored_polygon(PackedVector2Array([o + Vector2(4, 3), o + Vector2(18, 3), o + Vector2(20, 9),
						o + Vector2(4, 9)]), col)
				draw_line(o + Vector2(11, 9), o + Vector2(11, 22), col, 3.0, true)
			&"tier":
				draw_colored_polygon(PackedVector2Array([o + Vector2(2, 20), o + Vector2(2, 6), o + Vector2(7, 12),
						o + Vector2(12, 3), o + Vector2(17, 12), o + Vector2(22, 6), o + Vector2(22, 20)]), col)
			&"champion":
				draw_circle(o + Vector2(12, 10), 8.0, col)
				draw_rect(Rect2(o + Vector2(7, 15), Vector2(10, 6)), col)
				draw_circle(o + Vector2(9, 10), 2.2, Color(0, 0, 0, 0.85))
				draw_circle(o + Vector2(15, 10), 2.2, Color(0, 0, 0, 0.85))
			&"horn":
				draw_colored_polygon(PackedVector2Array([o + Vector2(2, 16), o + Vector2(14, 8), o + Vector2(22, 3),
						o + Vector2(22, 21), o + Vector2(14, 16), o + Vector2(2, 20)]), col)
			_:
				draw_circle(o + Vector2(12, 12), 10.0, col)
				draw_arc(o + Vector2(12, 12), 7.0, 0.0, TAU, 20, Color(0, 0, 0, 0.5), 1.5, true)
		if count > 1:
			var f := get_theme_default_font()
			var t := str(count)
			draw_rect(Rect2(size.x - 14, size.y - 13, 13, 12), UIStyle.GOLD)
			draw_string(f, Vector2(size.x - 14, size.y - 3), t, HORIZONTAL_ALIGNMENT_CENTER, 13, 10, Color.BLACK)
