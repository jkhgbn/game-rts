class_name RouteLine
extends Node3D
## The trade route ribbon (ui-trade.md 7, task 10.C7): a dashed gold strip on the ground from the selected own
## Bazaar (or the first selected own caravan's Bazaar) along the road waypoints to its trading post, with a flat
## ring at each end; the dashes flow from the Bazaar toward the post. A second, fainter, still ribbon previews the
## route to the post under the mouse while an own Bazaar is selected, together with the RouteChip text
## (`Saltgate · far · 119 gold / trip · ~104 / min`) that follows the mouse.
## One node per level, group "route_line". `RouteLine.attach(hud, selection)` creates it (the command card calls it
## on setup; hud.gd may call it too through attach_optional: a second call returns the same node).
## The meshes are rebuilt only on selection_changed, on the Bazaar's route_changed, and once per second while shown
## (a caravan re-routed with G), never per frame (`rebuild_count` counts the rebuilds). The only per-frame work is
## the material's UV scroll and the chip position.
## Step-10 classes of other tasks (Market, Caravan, TradeNetwork, TradePost) are reached untyped: groups
## "markets" / "caravans" / "trade_network" / "trade_posts", get() and has_method().

const GROUP := &"route_line"
const KIND_ROUTE := &"route"
const KIND_PREVIEW := &"preview"

const WIDTH := 0.25                ## Strip width (m).
const HEIGHT := 0.30               ## Above the ground (m).
const OVERLAP := 0.15              ## Each quad runs this far past its end point (hides the bends' gaps).
const DASH_PERIOD := 1.6           ## 1.0 m dash + 0.6 m gap.
const SCROLL_SPEED := 1.5          ## m/s, Bazaar -> post.
const RING_RADIUS := 0.6
const RING_WIDTH := 0.12
const RING_SEGMENTS := 16
const ROUTE_COLOR := Color(1.0, 0.85, 0.3, 0.8)
const PREVIEW_COLOR := Color(1.0, 0.85, 0.3, 0.45)
const REFRESH_INTERVAL := 1.0      ## While shown: the route is re-read once per second.
const HOVER_INTERVAL := 0.05       ## 20 Hz: the preview follows selection.hovered_post.

var selection: Node                ## The SelectionManager (untyped: tests may pass a stub).
var hud: Node
var chip: RouteChip
## Meshes rebuilt since the start (tests: proves there is no per-frame rebuild).
var rebuild_count := 0

var _meshes := {}                  # kind -> MeshInstance3D
var _points := {}                  # kind -> PackedVector3Array (shown points; empty = hidden)
var _dash_mat: StandardMaterial3D
var _ring_mat: StandardMaterial3D
var _preview_mat: StandardMaterial3D
var _preview_ring_mat: StandardMaterial3D
var _refresh_left := REFRESH_INTERVAL
var _hover_left := 0.0
var _market: Node3D = null         # the Bazaar whose route_changed we listen to
var _preview_post: Node3D = null


## Creates the level's route line (or returns the existing one): the 3D node under `hud.get_parent()` (the level),
## the chip under `hud`. `selection` = the SelectionManager.
static func attach(p_hud: Node, p_selection: Node) -> RouteLine:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		for n in tree.get_nodes_in_group(GROUP):
			if n is RouteLine and not n.is_queued_for_deletion():
				var existing := n as RouteLine
				existing.bind_to(p_hud, p_selection)
				return existing
	var line := RouteLine.new()
	line.name = "RouteLine"
	line.add_to_group(GROUP)   # before entering the tree: a second attach in the same frame finds it
	var parent: Node = p_hud.get_parent() if p_hud != null and p_hud.get_parent() != null else p_hud
	if parent != null:
		parent.add_child(line)
	line.bind_to(p_hud, p_selection)
	return line


func _init() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	_dash_mat = _material(ROUTE_COLOR, true)
	_ring_mat = _material(ROUTE_COLOR, false)
	_preview_mat = _material(PREVIEW_COLOR, true)
	_preview_ring_mat = _material(PREVIEW_COLOR, false)
	for kind: StringName in [KIND_ROUTE, KIND_PREVIEW]:
		var mi := MeshInstance3D.new()
		mi.name = "Route" if kind == KIND_ROUTE else "Preview"
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visible = false
		add_child(mi)
		_meshes[kind] = mi
		_points[kind] = PackedVector3Array()
	_refresh_route()


## Sets the HUD (the chip's parent) and the SelectionManager to follow (attach calls it).
func bind_to(p_hud: Node, p_selection: Node) -> void:
	if p_hud != null:
		hud = p_hud
	if p_selection != null and p_selection != selection:
		if selection != null and is_instance_valid(selection) and selection.has_signal(&"selection_changed") \
				and selection.is_connected(&"selection_changed", _on_selection_changed):
			selection.disconnect(&"selection_changed", _on_selection_changed)
		selection = p_selection
		if selection.has_signal(&"selection_changed"):
			selection.connect(&"selection_changed", _on_selection_changed)
	if hud != null and (chip == null or not is_instance_valid(chip)):
		chip = RouteChip.new()
		chip.name = "RouteChip"
		hud.add_child(chip)
	if chip != null:
		chip.line = self
	if is_inside_tree():
		_refresh_route()


# ---------------------------------------------------------------- public

## Shows the ribbon of `kind` (&"route" / &"preview") along `points` (world, y ignored). Fewer than 2 points hides it.
func show_route(points: PackedVector3Array, kind: StringName = KIND_ROUTE) -> void:
	if points.size() < 2:
		hide_route(kind)
		return
	if not _meshes.has(kind):
		return
	var flat := PackedVector3Array()
	for p in points:
		flat.append(Vector3(p.x, 0.0, p.z))
	if flat == _points[kind] and (_meshes[kind] as MeshInstance3D).visible:
		return   # same route: no rebuild
	_points[kind] = flat
	var mi: MeshInstance3D = _meshes[kind]
	mi.mesh = _build_mesh(flat, kind)
	mi.visible = true
	rebuild_count += 1


func hide_route(kind: StringName = KIND_ROUTE) -> void:
	if not _meshes.has(kind):
		return
	_points[kind] = PackedVector3Array()
	var mi: MeshInstance3D = _meshes[kind]
	mi.visible = false
	mi.mesh = null


func is_showing(kind: StringName = KIND_ROUTE) -> bool:
	return _meshes.has(kind) and (_meshes[kind] as MeshInstance3D).visible


## The points of the shown ribbon (the Bazaar first, the post door last; empty when hidden).
func shown_points(kind: StringName = KIND_ROUTE) -> PackedVector3Array:
	return _points.get(kind, PackedVector3Array())


## The dashed route material (tests read its colour, texture and scroll).
func route_material() -> StandardMaterial3D:
	return _dash_mat


func preview_material() -> StandardMaterial3D:
	return _preview_mat


## Re-reads the route to show now (selection change, route change; also once per second while shown).
func refresh_now() -> void:
	_refresh_route()


## The Bazaar and post the ribbon should show for the current selection: [market, post] or [] (nothing).
func current_route() -> Array:
	if selection == null or not is_instance_valid(selection):
		return []
	var market := _selected_market()
	if market != null:
		var post: Variant = market.get(&"route_post")
		return [market, post] if valid_node(post) else []
	var sel: Variant = selection.get(&"selected")
	if sel is Array:
		for u: Variant in sel:
			if not valid_node(u) or not (u as Node).is_in_group(&"caravans") or int((u as Node).get(&"team")) != 0:
				continue
			var home: Variant = (u as Node).get(&"home_market")
			var post: Variant = (u as Node).get(&"route_post")
			if valid_node(home) and valid_node(post):
				return [home, post]
			return []   # the first caravan decides; nothing if either end is missing
	return []


## The waypoints Bazaar -> post (TradeNetwork.route_points, prefixed with the Bazaar's centre), or the straight
## line Bazaar -> door without a network.
static func route_points_for(market: Node3D, post: Node3D) -> PackedVector3Array:
	var out := PackedVector3Array()
	if not valid_node(market) or not valid_node(post):
		return out
	out.append(market.global_position)
	var tree := market.get_tree()
	var net: Node = tree.get_first_node_in_group(&"trade_network") if tree != null else null
	if net != null and net.has_method(&"route_points"):
		var pts: Variant = net.call(&"route_points", market, post)
		if pts is PackedVector3Array and not (pts as PackedVector3Array).is_empty():
			out.append_array(pts)
			return out
	out.append(door_of(post))
	return out


static func door_of(post: Node3D) -> Vector3:
	if post.has_method(&"door_point"):
		var d: Variant = post.call(&"door_point")
		if d is Vector3:
			return d
	return post.global_position


# ---------------------------------------------------------------- update

func _on_selection_changed() -> void:
	_refresh_route()
	_update_preview(true)


func _on_route_changed(_market_node: Variant = null, _post: Variant = null) -> void:
	_refresh_route()
	_update_preview(true)


func _process(delta: float) -> void:
	if is_showing(KIND_ROUTE) and _dash_mat != null:
		var off := _dash_mat.uv1_offset
		off.x = fposmod(off.x - SCROLL_SPEED / DASH_PERIOD * delta, 1.0)
		_dash_mat.uv1_offset = off
		_refresh_left -= delta
		if _refresh_left <= 0.0:
			_refresh_left = REFRESH_INTERVAL
			_refresh_route()
	elif _market != null or _caravans_selected():
		_refresh_left -= delta
		if _refresh_left <= 0.0:   # nothing shown yet (no route / home): look again once per second
			_refresh_left = REFRESH_INTERVAL
			_refresh_route()
	_hover_left -= delta
	if _hover_left <= 0.0:
		_hover_left = HOVER_INTERVAL
		_update_preview(false)


func _refresh_route() -> void:
	_watch_market(_selected_market())
	var r := current_route()
	if r.is_empty():
		hide_route(KIND_ROUTE)
		return
	var pts := route_points_for(r[0], r[1])
	if pts.size() < 2:
		hide_route(KIND_ROUTE)
		return
	show_route(pts, KIND_ROUTE)


## The preview ribbon + the chip: an own Bazaar selected and the mouse over a post (selection.hovered_post).
func _update_preview(force: bool) -> void:
	var market := _selected_market()
	var post: Node3D = null
	if market != null:
		var h: Variant = selection.get(&"hovered_post")
		if valid_node(h):
			post = h
	var current: Variant = market.get(&"route_post") if market != null else null
	var preview_post: Node3D = post if post != null and post != current else null
	if preview_post != _preview_post or force:
		_preview_post = preview_post
		if preview_post != null:
			show_route(route_points_for(market, preview_post), KIND_PREVIEW)
		else:
			hide_route(KIND_PREVIEW)
	if chip != null and is_instance_valid(chip):
		chip.show_for(market if post != null and not _window_open() else null, post)


func _selected_market() -> Node3D:
	if selection == null or not is_instance_valid(selection):
		return null
	var b: Variant = selection.get(&"selected_building")
	if not valid_node(b) or not (b as Node).is_in_group(&"markets"):
		return null
	var m := b as Node3D
	if int(m.get(&"team")) != 0:
		return null
	if m.has_method(&"is_constructed") and not bool(m.call(&"is_constructed")):
		return null
	if m.has_method(&"is_alive") and not bool(m.call(&"is_alive")):
		return null
	return m


func _caravans_selected() -> bool:
	if selection == null or not is_instance_valid(selection):
		return false
	var sel: Variant = selection.get(&"selected")
	if sel is Array:
		for u: Variant in sel:
			if valid_node(u) and (u as Node).is_in_group(&"caravans"):
				return true
	return false


func _watch_market(m: Node3D) -> void:
	if m == _market:
		return
	if valid_node(_market) and _market.has_signal(&"route_changed") and _market.is_connected(&"route_changed", _on_route_changed):
		_market.disconnect(&"route_changed", _on_route_changed)
	_market = m
	if m != null and m.has_signal(&"route_changed") and not m.is_connected(&"route_changed", _on_route_changed):
		m.connect(&"route_changed", _on_route_changed)


## A HUD window (shop, tavern, trade) is open: no chip.
func _window_open() -> bool:
	if hud == null or not is_instance_valid(hud):
		return false
	for n: StringName in [&"shop_window", &"tavern_window", &"trade_window"]:
		var w: Variant = hud.get(n)
		if is_instance_valid(w) and w is CanvasItem:
			if (w as Object).has_method(&"is_open"):
				if bool((w as Object).call(&"is_open")):
					return true
			elif (w as CanvasItem).visible:
				return true
	return false


## A living Node3D in the tree (checks is_instance_valid before the type: a freed post / caravan is fine).
static func valid_node(n: Variant) -> bool:
	return is_instance_valid(n) and n is Node3D and (n as Node).is_inside_tree()


# ---------------------------------------------------------------- mesh

func _build_mesh(points: PackedVector3Array, kind: StringName) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	# Surface 0: the strip, one quad per segment, UV.x = metres along the route.
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	var along := 0.0
	var half := WIDTH * 0.5
	for i in range(points.size() - 1):
		var a := points[i]
		var b := points[i + 1]
		var d := Vector3(b.x - a.x, 0.0, b.z - a.z)
		var length := d.length()
		if length < 0.01:
			continue
		var dir := d / length
		var side := Vector3(-dir.z, 0.0, dir.x) * half
		var extra := OVERLAP if i < points.size() - 2 else 0.0
		var end := b + dir * extra
		var base := verts.size()
		for v in [a - side, a + side, end + side, end - side]:
			verts.append(Vector3((v as Vector3).x, HEIGHT, (v as Vector3).z))
		var u1 := along + length + extra
		uvs.append_array(PackedVector2Array([Vector2(along, 0.0), Vector2(along, 1.0), Vector2(u1, 1.0), Vector2(u1, 0.0)]))
		idx.append_array(PackedInt32Array([base, base + 1, base + 2, base, base + 2, base + 3]))
		along += length
	if verts.is_empty():
		return mesh
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, _dash_mat if kind == KIND_ROUTE else _preview_mat)
	# Surface 1: the two end rings (the Bazaar's centre and the post door).
	var rv := PackedVector3Array()
	var ri := PackedInt32Array()
	for c in [points[0], points[points.size() - 1]]:
		var base := rv.size()
		for k in RING_SEGMENTS:
			var ang := TAU * float(k) / RING_SEGMENTS
			var o := Vector3(cos(ang), 0.0, sin(ang))
			var cc := c as Vector3
			rv.append(Vector3(cc.x, HEIGHT, cc.z) + o * (RING_RADIUS - RING_WIDTH * 0.5))
			rv.append(Vector3(cc.x, HEIGHT, cc.z) + o * (RING_RADIUS + RING_WIDTH * 0.5))
		for k in RING_SEGMENTS:
			var i0 := base + k * 2
			var i1 := base + ((k + 1) % RING_SEGMENTS) * 2
			ri.append_array(PackedInt32Array([i0, i0 + 1, i1 + 1, i0, i1 + 1, i1]))
	var ring_arrays := []
	ring_arrays.resize(Mesh.ARRAY_MAX)
	ring_arrays[Mesh.ARRAY_VERTEX] = rv
	ring_arrays[Mesh.ARRAY_INDEX] = ri
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, ring_arrays)
	mesh.surface_set_material(1, _ring_mat if kind == KIND_ROUTE else _preview_ring_mat)
	return mesh


## Unshaded, alpha, both faces, no shadows; `dashed` = the 32 x 4 dash texture repeating every 1.6 m.
func _material(color: Color, dashed: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = color
	m.no_depth_test = false
	if dashed:
		m.albedo_texture = dash_texture()
		m.texture_repeat = true
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		m.uv1_scale = Vector3(1.0 / DASH_PERIOD, 1.0, 1.0)
	return m


static var _dash_tex: ImageTexture

## 32 x 4: pixels 0-19 white, 20-31 transparent (1.0 m dash, 0.6 m gap at uv1_scale 1 / 1.6).
static func dash_texture() -> ImageTexture:
	if _dash_tex != null:
		return _dash_tex
	var img := Image.create(32, 4, true, Image.FORMAT_RGBA8)
	for x in 32:
		for y in 4:
			img.set_pixel(x, y, Color(1, 1, 1, 1) if x < 20 else Color(1, 1, 1, 0))
	img.generate_mipmaps()
	_dash_tex = ImageTexture.create_from_image(img)
	return _dash_tex


# ---------------------------------------------------------------- the hover chip (ui-trade.md 7.2)

## `Saltgate · far · 119 gold / trip · ~104 / min` (+ ` · Held by the enemy` in WARN, or ` · Current route` in gold),
## at mouse + (18, 12), height 26, flipped left at the right edge like the bounty chip.
class RouteChip extends PanelContainer:
	const OFFSET := Vector2(18, 12)
	const MARGIN := 4.0
	const HEIGHT := 26.0
	const FONT := 13
	const NEAR := Color(0.4, 0.9, 0.4)
	const FAR := Color(1.0, 0.55, 0.2)
	const CURRENT := "Current route"

	var line: RouteLine
	var labels: Array[Label] = []   ## name, near / far, value, reason / current
	var market: Node3D = null
	var post: Node3D = null
	var _mouse := Vector2.ZERO

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		z_index = 10
		visible = false
		custom_minimum_size = Vector2(0, HEIGHT)
		var s := UIStyle.slate_style(4.0, UIStyle.token(&"frame_metal"))
		var bg := UIStyle.token(&"slate_bg")
		s.bg_color = Color(bg.r, bg.g, bg.b, 0.94)
		s.content_margin_left = 6
		s.content_margin_right = 6
		s.content_margin_top = 4
		s.content_margin_bottom = 4
		s.set_corner_radius_all(2)
		add_theme_stylebox_override("panel", s)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 0)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(row)
		for i in 4:
			var l := UIStyle.panel_label("", FONT)
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			row.add_child(l)
			labels.append(l)

	func _input(event: InputEvent) -> void:
		if event is InputEventMouse:
			_mouse = (event as InputEventMouse).position

	## Shows the chip for `p_post` seen from `p_market` (null market or post = hidden).
	func show_for(p_market: Node3D, p_post: Node3D) -> void:
		if p_market == null or p_post == null:
			visible = false
			market = null
			post = null
			return
		market = p_market
		post = p_post
		_set_texts()   # 20 Hz: a post taken or opened shows at once
		visible = true
		_place()

	func _process(_delta: float) -> void:
		if visible:
			_place()

	## [name, " · near", " · 119 gold / trip · ~104 / min", " · Held by the enemy" / " · Current route" / ""].
	static func parts_for(p_market: Node3D, p_post: Node3D) -> Array[String]:
		var out: Array[String] = ["", "", "", ""]
		if not RouteLine.valid_node(p_market) or not RouteLine.valid_node(p_post):
			return out
		out[0] = RouteLine.post_name(p_post)
		out[1] = " · far" if RouteLine.is_far(p_market, p_post) else " · near"
		var value := RouteLine.value_of(p_market, p_post)
		out[2] = " · %d gold / trip · ~%d / min" % [value, RouteLine.per_minute(p_market, p_post)]
		if p_market.get(&"route_post") == p_post:
			out[3] = " · " + CURRENT
		else:
			var reason := RouteLine.route_reason(p_market, p_post)
			if reason != "":
				out[3] = " · " + RouteLine.short_reason(reason)
		return out

	## The chip's whole line, for tests ("" while hidden).
	func chip_text() -> String:
		if not visible:
			return ""
		var parts := PackedStringArray()
		for l in labels:
			if l.visible:
				parts.append(l.text)
		return "".join(parts)

	func _set_texts() -> void:
		var p := parts_for(market, post)
		for i in 4:
			labels[i].text = p[i]
		labels[0].add_theme_color_override("font_color", UIStyle.GOLD)
		labels[1].add_theme_color_override("font_color", FAR if p[1] == " · far" else NEAR)
		labels[2].add_theme_color_override("font_color", UIStyle.token(&"text"))
		labels[3].add_theme_color_override("font_color", UIStyle.GOLD if p[3].ends_with(CURRENT) else UIStyle.WARN)
		labels[3].visible = p[3] != ""
		reset_size()

	func _place() -> void:
		reset_size()
		var screen := get_viewport_rect().size
		var w := size.x
		var p := _mouse + OFFSET
		if p.x + w > screen.x - MARGIN:
			p.x = _mouse.x - w - 6.0
		p.x = clampf(p.x, MARGIN, maxf(MARGIN, screen.x - w - MARGIN))
		p.y = clampf(p.y, MARGIN, maxf(MARGIN, screen.y - size.y - MARGIN))
		position = p


# ---------------------------------------------------------------- shared route texts (card, panel, chip)

## The post's display name ("Millstone Cross").
static func post_name(post: Node) -> String:
	if post == null or not is_instance_valid(post):
		return ""
	var n: Variant = post.get(&"display_name")
	return str(n) if n != null and str(n) != "" else String(post.name)


static func _network_of(n: Node) -> Node:
	if n == null or not n.is_inside_tree():
		return null
	return n.get_tree().get_first_node_in_group(&"trade_network")


## Gold per trip from `market` to `post` (Market.route_value_to, else the network, else 0).
static func value_of(market: Node, post: Node) -> int:
	if market == null or post == null:
		return 0
	if market.has_method(&"route_value_to"):
		return int(market.call(&"route_value_to", post))
	var net := _network_of(market)
	if net != null and net.has_method(&"route_value"):
		return int(net.call(&"route_value", market, post))
	return 0


## Route length L (metres) from `market` to `post`.
static func length_of(market: Node, post: Node) -> float:
	if market == null or post == null:
		return 0.0
	if market.has_method(&"route_length_to"):
		return float(market.call(&"route_length_to", post))
	var net := _network_of(market)
	if net != null and net.has_method(&"route_length"):
		return float(net.call(&"route_length", market, post))
	return 0.0


## True when `post` is far for the market's team (Market.is_far_post, else TradeNetwork.is_far).
static func is_far(market: Node, post: Node) -> bool:
	if market == null or post == null:
		return false
	if market.has_method(&"is_far_post"):
		return bool(market.call(&"is_far_post", post))
	var net := _network_of(market)
	if net != null and net.has_method(&"is_far"):
		return bool(net.call(&"is_far", int(market.get(&"team")), post))
	return false


## Gold per minute per caravan: value * 60 / (L / 4.0 + L / 3.6 + 4), rounded (ui-trade.md 5.2).
static func per_minute(market: Node, post: Node) -> int:
	var l := length_of(market, post)
	if l <= 0.0 or l == INF or is_nan(l):
		return 0
	return roundi(value_of(market, post) * 60.0 / (l / 4.0 + l / 3.6 + 4.0))


## TradeNetwork.route_reason(market, post): "", "Trading posts open at 4:00", "Route too short", "Held by the enemy".
## Without a network: the post's own held flag.
static func route_reason(market: Node, post: Node) -> String:
	if market == null or post == null:
		return ""
	var net := _network_of(market)
	if net != null and net.has_method(&"route_reason"):
		return str(net.call(&"route_reason", market, post))
	if post.has_method(&"is_held_by_enemy_of") and bool(post.call(&"is_held_by_enemy_of", int(market.get(&"team")))):
		return "Held by the enemy"
	return ""


## The short button form: "Trading posts open at 4:00" -> "Opens at 4:00" (the others unchanged).
static func short_reason(reason: String) -> String:
	if reason.begins_with("Trading posts open at"):
		return "Opens at" + reason.trim_prefix("Trading posts open at")
	return reason
