class_name Minimap
extends Control
## Top-down map of the whole battlefield (spec: docs/design/ui-hud.md, "Minimap"). Neutral units and
## buildings use Unit.team_color(NEUTRAL); the Ember Crown is a gold square on the ground or a gold
## ring around the wizard wearing it.
## World x -> right, world z -> down, (0, 0) at the centre. Redraws 10 times a second.
## Fog of war (fog-of-war.md "Minimap", ui-style.md 7.1): the player's fog grid as a NEAREST texture
## over the ground (rebuilt on FogOfWar.updated only); enemy / neutral things with visible == false are
## not drawn; grey squares for the "fog_ghosts"; crystal nodes and the crown only once explored.
## Left click / drag = move the camera there. Right click = move the selected units there
## (gather near a crystal node with workers; rally point with a building selected).
## With a targeted order pending (X attack-move, M, G, F, Set Rally): left click = that order on the spot,
## right click = cancel it.
## Mission extras (8.U2, mission-01.md): braziers (group "braziers": cold stone ring, orange progress arc,
## lit = orange fire dot) and their lit flame lines toward the crown (minimap_flame_line()); the caged
## peddler (MissionCagedPeddler: a cage, then a coin once freed); a pulsing ring on the current primary
## objective when the mission's objectives() rows carry "position" / "positions"; and a flashing WARN
## arrow at the map edge + ring at the spawn when new Shadow units join group "scripted" (checked at 2 Hz).
## Mission markers are shown through the fog (they are objectives). The pulse / flash is drawn on a child
## overlay redrawn every frame only while something animates; the map itself stays at 10 Hz.
## Trade (10.C7, ui-trade.md 8): roads (TradeNetwork.road_segments, cached) under the fog; trading posts with the
## holder's border, Magpie Dens / Greywater Lodges once explored; visible loot sacks; caravans (4 x 3, a gold dot
## when loaded); visible Magpies; the selected route (RouteLine) as a gold polyline. A right click within 4 m of a
## post sets the Bazaar's route / sends the selected caravans to trade (SelectionManager.order_at).
## Map fill (12.C6, ui-mapfill.md 9): the river, fords and bridges from RiverSystem.mask_image() (built once into a
## LINEAR texture on a child layer drawn behind the map, with the ground fill: under the roads and the fog); own
## watchtower sight rings (after the fog); monster lairs (dashed circle once explored + a paw while the beast is known
## alive) and camps (tier colour, outline only when last seen cleared: CaptureRings.camp_state) after the trade
## buildings; capture points always (tower square / well circle / shrine diamond in own / enemy / neutral, awake shrine
## gold with a pulsing ring on the overlay, asleep shrine faded, the selected point with a gold outline); visible
## beasts as 6 x 6 paws after the champions (no neutral square for them); a BEAST ping at the lair on beast_spawned.
## Step-12 services are reached untyped (groups "river", "capture_points", "neutral_camps", "epic_beasts",
## "capture_rings"); any of them missing = its layer is absent.
## Zoom (JS request 2026-09-27): the mouse wheel over the minimap zooms it 1x-3x (steps of 0.5) around the point
## under the mouse (the wheel elsewhere still zooms the 3D camera). The zoomed view (`view_center`, world x / z) is
## clamped to the map and follows the camera: when the camera moves out of the middle 60 % of the view, the view
## slides to keep it inside (not while dragging on the minimap). All drawing and clicks go through world_to_map /
## map_to_world, so clicks, orders and icon sizes work the same at any zoom.

const SIZE := 220.0
const ZOOM_MIN := 1.0
const ZOOM_MAX := 3.0
const ZOOM_STEP := 0.5
const FOLLOW_INNER := 0.6   ## The camera is kept inside this fraction of the zoomed view.
const REDRAW_INTERVAL := 0.1

const GROUND_COLOR := Color(0.20, 0.30, 0.15)
const CRYSTAL_COLOR := Color(0.45, 0.85, 1.0)
const ARTIFACT_COLOR := Color(1.0, 0.85, 0.3)
const OWN_COLOR := Color(0.3, 1.0, 0.4)
const OWN_HERO_COLOR := Color(1.0, 0.85, 0.3)
const ENEMY_COLOR := Color(1.0, 0.3, 0.3)
const ENEMY_HERO_COLOR := Color(0.8, 0.4, 1.0)
const PLAYER_TEAM_COLOR := Color(0.85, 0.3, 0.12)
const ENEMY_TEAM_COLOR := Color(0.42, 0.22, 0.6)
const CAMERA_COLOR := Color(1, 1, 1, 0.8)
const GHOST_COLOR := Color(0.55, 0.55, 0.6)   ## Last-seen enemy buildings (fog-of-war.md).
## Fog alpha per grid_image value (0 unexplored = black, 140 explored = ground x0.45, 255 visible = clear).
const FOG_ALPHA_UNEXPLORED := 255
const FOG_ALPHA_EXPLORED := 140
## Sunken-map lines (ui-style.md 7.1), fire skin values; UIStyle tokens win when 6.U1 adds them.
const GROOVE_FALLBACK := Color(0.04, 0.03, 0.03)
const FRAME_DARK_FALLBACK := Color(0.36, 0.22, 0.09)
## Mission extras (8.U2).
const MISSION_SCAN_INTERVAL := 0.5          ## 2 Hz: scripted-wave check + objective positions.
const FLAME_LINE_COLOR := Color(1.0, 0.5, 0.15)   ## for-ui-coder.md (M7.S1): each lit brazier's line.
const FLAME_LINE_WIDTH := 2.0
const BRAZIER_COLD_COLOR := Color(0.78, 0.74, 0.66)
const BRAZIER_BOWL_COLOR := Color(0.2, 0.18, 0.16)
const BRAZIER_LIT_COLOR := Color(1.0, 0.5, 0.15)
const BRAZIER_CORE_COLOR := Color(1.0, 0.9, 0.5)
const BRAZIER_RADIUS := 3.5
const PEDDLER_COLOR := Color(0.85, 0.75, 0.5)
const CAGE_COLOR := Color(0.78, 0.74, 0.66)
const OBJECTIVE_RING_COLOR := Color(1.0, 0.97, 0.85)
const OBJECTIVE_PULSE_PERIOD := 1.2
const WAVE_FLASH_TIME := 4.0
const WAVE_BLINK_HZ := 3.0
const WAVE_ARROW_INSET := 11.0
## Champions and bounties (9.C8, ui-champions.md 9).
const TAVERN_COLOR := Color(1.0, 0.75, 0.35)
const TAVERN_SIZE := 6.0
const CHAMPION_RADIUS := 2.5
const CHAMPION_RING := 3.0
const CHAMPION_RING_COLOR := Color(1.0, 0.85, 0.4)   ## GOLD
const FLAG_COIN_COLOR := Color(1.0, 0.85, 0.3)
const FLAG_RADIUS := 2.0
const FLAG_RING := 2.5
const FLAG_SELECTED_RADIUS := 3.0
const FLAG_SELECTED_RING := 4.0
const PING_TIME := 0.9
const PING_RINGS := 3
const PING_MAX_RADIUS := 12.0
## Trade (10.C7, ui-trade.md 8, market-trade.md 2.5).
const ROAD_COLOR := Color(0.55, 0.45, 0.30)
const ROAD_WIDTH := 2.0
const ROAD_RETRY := 2.0                       ## Roads are cached; re-read every 2 s while there are none.
const POST_COLOR := Color(0.85, 0.65, 0.30)
const POST_SIZE := 5.0
const DEN_COLOR := Color(0.45, 0.35, 0.55)
const LODGE_COLOR := Color(0.40, 0.62, 0.35)
const GUILD_SIZE := 6.0
const SACK_COLOR := Color(1.0, 0.85, 0.3)
const MAGPIE_COLOR := Color(1.0, 0.65, 0.2)
const ROUTE_COLOR := Color(1.0, 0.85, 0.3)
## Map fill (12.C6, ui-mapfill.md 9 / 15.1).
const WATER_COLOR := Color(0.25, 0.45, 0.65)
const FORD_COLOR := Color(0.45, 0.62, 0.72)
const BRIDGE_COLOR := ROAD_COLOR
const MAPFILL_RETRY := 2.0                    ## River mask / beast service looked up every 2 s while missing.
const POINT_NEUTRAL_COLOR := Color(0.62, 0.64, 0.70)
const POINT_SIZE := 5.0
const SHRINE_GOLD := Color(1.0, 0.85, 0.4)    ## GOLD
const ASLEEP_ALPHA := 0.5
const SHRINE_PULSE_PERIOD := 1.0
const SHRINE_PULSE_FROM := 4.0
const SHRINE_PULSE_TO := 7.0
const SIGHT_RING_ALPHA := 0.35
const BEAST_COLOR := Color(1.0, 0.75, 0.2)
const TIER_COLORS: Array[Color] = [Color(0.85, 0.85, 0.75), Color(1.0, 0.6, 0.25), Color(1.0, 0.3, 0.25)]
const CAMP_SIZE := 4.0
const LAIR_EXTRA := 3.0                       ## Lair circle radius = (radius + 3) m.
const LAIR_ARCS := 16                         ## Drawn every other one: 8 dashes.
const LAIR_ALPHA := 0.45
const LAIR_PAW := 4.0
const LAIR_PAW_ALPHA := 0.7
const BEAST_PAW := 6.0

var map_size := 120.0
var selection: SelectionManager
var camera_rig: RTSCamera
var artifact: Node3D
var redraw_count := 0          # for tests
var fog_texture_updates := 0   # for tests: times the fog texture was rebuilt
var drawn_enemy_icons := 0     # for tests: enemy / neutral units and buildings in the last draw
var drawn_ghosts := 0          # for tests: fog ghosts in the last draw
## The mission node (objectives() source); found from the current scene when null. Tests may set it.
var mission: Node
var drawn_braziers := 0        # for tests: braziers in the last draw
var drawn_lit_braziers := 0    # for tests
var drawn_flame_lines := 0     # for tests
var drawn_peddler := ""        # for tests: "" none, "caged", "free"
var objective_points: Array[Vector3] = []   ## Read only: where the objective ring pulses (world).
var wave_flash_count := 0      ## Read only: scripted waves seen since setup.
var wave_flash_left := 0.0     ## Read only: seconds the wave arrow still flashes.
var wave_from := Vector3.ZERO  ## Read only: centre of the last scripted wave (world).
var overlay_draws := 0         # for tests: overlay redraws
var drawn_champions := 0       # for tests: champion circles in the last draw
var drawn_flags := 0           # for tests: bounty coins in the last draw
var drawn_taverns := 0         # for tests: tavern squares in the last draw
var hunt_pings := 0            ## Read only: hunt-warning pings started since setup.
# For tests (trade layers, counts of the last draw):
var drawn_roads := 0           # road segments
var drawn_posts := 0
var drawn_held_posts := 0
var drawn_guilds := 0
var drawn_sacks := 0
var drawn_caravans := 0
var drawn_loaded_caravans := 0
var drawn_magpies := 0
var route_drawn := false
# For tests (map-fill layers, counts of the last draw; ui-mapfill.md 9.1):
var drawn_points := 0
var drawn_held_points := 0
var drawn_awake_shrines := 0
var drawn_camps := 0
var drawn_cleared_camps := 0
var drawn_lairs := 0
var drawn_lair_paws := 0
var drawn_beasts := 0
var drawn_sight_rings := 0
var water_drawn := false       ## True once the river mask texture is drawn under the map.
var beast_pings := 0           ## Read only: lair pings started on beast_spawned since setup.
var _water_tex: ImageTexture
var _water_world := Rect2()   # the river mask's world rect (x, z)
## Read only (set_zoom): 1 = the whole map, up to ZOOM_MAX.
var zoom := 1.0
## Read only: the world point (x, z) at the centre of the minimap (0, 0 at zoom 1).
var view_center := Vector2.ZERO
var _last_cam := Vector2(INF, INF)
var _water_layer: Control
var _mapfill_left := 0.0
var _beasts_svc: Node          # EpicBeasts (group "epic_beasts")
var _lairs: Array = []         # cached EpicBeasts.lairs() (dictionaries)
var _lair_alive := {}          # lair id -> true while the beast is known alive (spawn / slain announcements)
var _awake_shrines: Array[Vector3] = []   # world positions of awake shrines in the last draw (overlay pulse)
var _roads: Array = []         # cached TradeNetwork.road_segments() (PackedVector3Array each)
var _roads_left := 0.0
var _pings: Array = []         # [world Vector3, seconds left]
var _hunt_stakes := {}         # enemy Hunt bounty id -> last stake seen (warning pings)
var _hunts_baseline := false

var _mission_scan_left := 0.0
var _scripted_seen := {}       # instance id -> true
var _scripted_baseline := false
var _overlay: Control
var _anim_time := 0.0
var _overlay_dirty := false

var _redraw_left := 0.0
var _dragging := false
var _fog: FogOfWar
var _fog_img: Image
var _fog_tex: ImageTexture
var _fog_src := PackedByteArray()   # the last grid_image data turned into the texture
var _groove := GROOVE_FALLBACK
var _frame_dark := FRAME_DARK_FALLBACK


func _ready() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # fog cells stay crisp
	_read_style_tokens()
	# Ground + river layer (12.C6): drawn behind this control's own drawing, LINEAR filtered (the fog stays NEAREST).
	_water_layer = Control.new()
	_water_layer.name = "GroundLayer"
	_water_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_water_layer.show_behind_parent = true
	_water_layer.position = Vector2.ZERO
	_water_layer.size = Vector2(SIZE, SIZE)
	_water_layer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_water_layer.draw.connect(_draw_ground_layer)
	add_child(_water_layer)
	# Mission overlay: objective pulse and wave arrow, redrawn per frame only while they animate.
	_overlay = Control.new()
	_overlay.name = "MissionOverlay"
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.position = Vector2.ZERO
	_overlay.size = Vector2(SIZE, SIZE)
	_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)


func setup(p_selection: SelectionManager, p_camera_rig: RTSCamera, p_map_size: float, p_artifact: Node3D) -> void:
	selection = p_selection
	camera_rig = p_camera_rig
	map_size = p_map_size
	artifact = p_artifact
	_clamp_view()
	_last_cam = Vector2(INF, INF)
	_read_style_tokens()   # after the HUD picked the kingdom skin
	_connect_fog()
	# The wave check starts from the units on the map now (the mission's start guards are not a wave).
	_scripted_baseline = false
	_scripted_seen = {}
	_mission_scan_left = 0.0
	_roads = []
	_roads_left = 0.0
	_refresh_roads()
	_water_tex = null
	water_drawn = false
	_beasts_svc = null
	_lairs = []
	_lair_alive = {}
	_refresh_mapfill()
	queue_redraw()


## Caches TradeNetwork.road_segments() (group "trade_network"); called at setup and every 2 s while empty.
func _refresh_roads() -> void:
	_roads_left = ROAD_RETRY
	if not is_inside_tree():
		return
	var net := get_tree().get_first_node_in_group(&"trade_network")
	if net == null or not net.has_method(&"road_segments"):
		return
	var segs: Variant = net.call(&"road_segments")
	if segs is Array:
		_roads = (segs as Array).duplicate()


## The level's FogOfWar (it may be created after the HUD): the fog texture follows its `updated`
## signal (5 Hz per team, and at once on the F11 toggle), never per frame.
func _connect_fog() -> void:
	if _fog != null and is_instance_valid(_fog):
		return
	_fog = FogOfWar.find() if is_inside_tree() else null
	if _fog == null:
		return
	if not _fog.updated.is_connected(_on_fog_updated):
		_fog.updated.connect(_on_fog_updated)
	_on_fog_updated()


func _on_fog_updated() -> void:
	if _fog == null or not is_instance_valid(_fog):
		return
	var src := _fog.grid_image(Unit.Team.PLAYER)
	var data := src.get_data()
	if data == _fog_src and _fog_tex != null:
		return   # the other team's pass: nothing changed for the player
	_fog_src = data
	var n := data.size()
	var out := PackedByteArray()
	out.resize(n * 2)   # LA8: black, alpha from the state
	for i in n:
		var v := data[i]
		out[i * 2 + 1] = 0 if v >= 255 else (FOG_ALPHA_EXPLORED if v > 0 else FOG_ALPHA_UNEXPLORED)
	var w := src.get_width()
	var h := src.get_height()
	if _fog_img == null or _fog_img.get_width() != w or _fog_img.get_height() != h:
		_fog_img = Image.create_from_data(w, h, false, Image.FORMAT_LA8, out)
		_fog_tex = ImageTexture.create_from_image(_fog_img)
	else:
		_fog_img.set_data(w, h, false, Image.FORMAT_LA8, out)
		_fog_tex.update(_fog_img)
	fog_texture_updates += 1
	queue_redraw()


## Fog alpha (0-1) drawn at a world point, for tests: 1 unexplored, 0.55 explored, 0 visible / no fog.
func fog_alpha_at(world: Vector3) -> float:
	if _fog_img == null or _fog == null or not is_instance_valid(_fog):
		return 0.0
	var i := clampi(floori(world.x / FogOfWar.CELL) + FogOfWar.HALF, 0, _fog_img.get_width() - 1)
	var j := clampi(floori(world.z / FogOfWar.CELL) + FogOfWar.HALF, 0, _fog_img.get_height() - 1)
	return _fog_img.get_pixel(i, j).a


## Skin colours from UIStyle (6.U1) when it has them, else the fire values of ui-style.md.
func _read_style_tokens() -> void:
	var script := UIStyle as Script
	var consts := script.get_script_constant_map()
	for pair in [[&"groove", "GROOVE"], [&"frame_dark", "FRAME_DARK"]]:
		var v: Variant = consts.get(pair[1], null)
		if not v is Color:
			v = script.get(pair[0])
		if v is Color:
			if pair[0] == &"groove":
				_groove = v
			else:
				_frame_dark = v


func world_to_map(world: Vector3) -> Vector2:
	return (Vector2(world.x, world.z) - view_center) * _scale() + Vector2(SIZE, SIZE) * 0.5


func map_to_world(point: Vector2) -> Vector3:
	var p := point.clamp(Vector2.ZERO, Vector2(SIZE, SIZE))
	var w := (p - Vector2(SIZE, SIZE) * 0.5) / _scale() + view_center
	return Vector3(w.x, 0.0, w.y)


## Zooms the minimap to `z` (clamped 1-3); the world point under `anchor` (minimap pixels; the centre when omitted)
## stays under it. The view is then clamped to the map.
func set_zoom(z: float, anchor := Vector2(-1.0, -1.0)) -> void:
	if anchor.x < 0.0:
		anchor = Vector2(SIZE, SIZE) * 0.5
	var at := map_to_world(anchor)
	zoom = clampf(z, ZOOM_MIN, ZOOM_MAX)
	view_center = Vector2(at.x, at.z) - (anchor.clamp(Vector2.ZERO, Vector2(SIZE, SIZE)) - Vector2(SIZE, SIZE) * 0.5) \
			/ _scale()
	_clamp_view()
	_view_changed()


## Centres the zoomed view on a world point (clamped to the map).
func center_view_on(world: Vector3) -> void:
	view_center = Vector2(world.x, world.z)
	_clamp_view()
	_view_changed()


func _clamp_view() -> void:
	var room := map_size * 0.5 - map_size * 0.5 / zoom
	view_center = view_center.clamp(Vector2(-room, -room), Vector2(room, room))


func _view_changed() -> void:
	queue_redraw()
	if _water_layer:
		_water_layer.queue_redraw()
	_overlay_dirty = true


## Zoomed in: when the camera left the middle of the view since the last check, slide the view to keep it inside.
func _follow_camera() -> void:
	if camera_rig == null or not is_instance_valid(camera_rig) or not camera_rig.is_inside_tree():
		return
	var p := camera_rig.global_position
	var cam := Vector2(p.x, p.z)
	if cam == _last_cam:
		return
	_last_cam = cam
	if zoom <= ZOOM_MIN or _dragging:
		return
	var inner := map_size * 0.5 / zoom * FOLLOW_INNER
	var c := view_center
	c.x = clampf(c.x, cam.x - inner, cam.x + inner)
	c.y = clampf(c.y, cam.y - inner, cam.y + inner)
	if c != view_center:
		view_center = c
		_clamp_view()
		_view_changed()


func _process(delta: float) -> void:
	_follow_camera()
	if _roads.is_empty():
		_roads_left -= delta
		if _roads_left <= 0.0:
			_refresh_roads()
	_mapfill_left -= delta
	if _mapfill_left <= 0.0:
		_refresh_mapfill()
	_redraw_left -= delta
	if _redraw_left <= 0.0:
		_redraw_left = REDRAW_INTERVAL
		if _fog == null or not is_instance_valid(_fog):
			_fog = null
			_connect_fog()
		queue_redraw()
	_mission_scan_left -= delta
	if _mission_scan_left <= 0.0:
		_mission_scan_left = MISSION_SCAN_INTERVAL
		_scan_mission()
	# Overlay: every frame while the ring pulses or the wave arrow flashes, once more to clear it.
	_anim_time += delta
	if wave_flash_left > 0.0:
		wave_flash_left = maxf(0.0, wave_flash_left - delta)
	for p: Array in _pings:
		p[1] = float(p[1]) - delta
	_pings = _pings.filter(func(p: Array) -> bool: return float(p[1]) > 0.0)
	var animating := wave_flash_left > 0.0 or not objective_points.is_empty() or not _pings.is_empty() \
			or not _awake_shrines.is_empty()
	if animating or _overlay_dirty:
		_overlay_dirty = animating
		if _overlay:
			_overlay.queue_redraw()


# ---------------------------------------------------------------- mission extras (8.U2)

## 2 Hz: new Shadow units in group "scripted" (a wave spawned) and the objective ring positions.
func _scan_mission() -> void:
	if not is_inside_tree():
		return
	if selection != null:   # after setup(): the level has spawned its start units
		_scan_scripted()
	_update_objective_points()
	_scan_hunt_pings()


## Enemy Hunt bounties on the player's things: a new one (or a raise of +100 or more) pings the hunted thing with 3
## expanding WARN rings (ui-champions.md 9, the minimap side of `A bounty of 150 is on Vessa!`).
func _scan_hunt_pings() -> void:
	var seen := {}
	for node in get_tree().get_nodes_in_group(&"bounty_boards"):
		if node.get("team") == null or int(node.get("team")) == Unit.Team.PLAYER or not node.has_method(&"hunts_on"):
			continue
		var hunts: Variant = node.call(&"hunts_on", Unit.Team.PLAYER)
		if not hunts is Array:
			continue
		for b: Variant in hunts:
			if not b is Node or not is_instance_valid(b):
				continue
			var id := (b as Node).get_instance_id()
			seen[id] = true
			var stake := BountyMode.flag_stake(b)
			var fresh := not _hunt_stakes.has(id) or stake - int(_hunt_stakes[id]) >= BountyMode.RAISE_BIG
			_hunt_stakes[id] = stake
			var target := BountyMode.flag_target(b)
			if fresh and _hunts_baseline and target != null:
				ping(target.global_position)
	for id in _hunt_stakes.keys():
		if not seen.has(id):
			_hunt_stakes.erase(id)
	_hunts_baseline = true


## 3 expanding WARN rings at a world point for 0.9 s (overlay).
func ping(world: Vector3) -> void:
	_pings.append([world, PING_TIME, UIStyle.WARN])
	hunt_pings += 1
	_overlay_dirty = true


## The same 3 expanding rings in BEAST at a lair centre (ui-mapfill.md 6.4: a beast spawned there).
func beast_ping(world: Vector3) -> void:
	_pings.append([world, PING_TIME, BEAST_COLOR])
	beast_pings += 1
	_overlay_dirty = true


# ---------------------------------------------------------------- map fill (12.C6)

## Every 2 s while missing: the river mask texture and the EpicBeasts service (its lairs are re-read each time).
func _refresh_mapfill() -> void:
	_mapfill_left = MAPFILL_RETRY
	if not is_inside_tree():
		return
	if _water_tex == null:
		_build_water()
	_connect_beasts()


## RiverSystem.mask_image() (240 x 240 RGB8, 0.5 m / px: R water, G ford, B bridge) -> an RGBA texture (alpha 0
## where all channels are 0; bridge wins, then ford), drawn once by the ground layer over the mask's world rect.
func _build_water() -> void:
	var river: Node = null
	for n in get_tree().get_nodes_in_group(&"river"):
		if n.has_method(&"mask_image") and not n.is_queued_for_deletion():
			river = n
			break
	if river == null:
		return
	var mask: Variant = river.call(&"mask_image")
	if not mask is Image or (mask as Image).is_empty():
		return
	var img := mask as Image
	if img.get_format() != Image.FORMAT_RGB8:
		img = img.duplicate() as Image
		img.convert(Image.FORMAT_RGB8)
	var w := img.get_width()
	var h := img.get_height()
	var src := img.get_data()
	var out := PackedByteArray()
	out.resize(w * h * 4)   # zero = transparent
	var cols: Array[PackedByteArray] = []
	for c: Color in [WATER_COLOR, FORD_COLOR, BRIDGE_COLOR]:
		cols.append(PackedByteArray([c.r8, c.g8, c.b8, 255]))
	for i in w * h:
		var k := i * 3
		var pick := -1
		if src[k + 2] > 0:
			pick = 2
		elif src[k + 1] > 0:
			pick = 1
		elif src[k] > 0:
			pick = 0
		if pick < 0:
			continue
		var col := cols[pick]
		var o := i * 4
		out[o] = col[0]
		out[o + 1] = col[1]
		out[o + 2] = col[2]
		out[o + 3] = 255
	var tex_img := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, out)
	_water_tex = ImageTexture.create_from_image(tex_img)
	var cell := 0.5
	var script := river.get_script() as Script
	if script != null:
		cell = float(script.get_script_constant_map().get("MASK_CELL", cell))
	var half_w := float(w) * cell * 0.5
	var half_h := float(h) * cell * 0.5
	_water_world = Rect2(-half_w, -half_h, half_w * 2.0, half_h * 2.0)
	if _water_layer:
		_water_layer.queue_redraw()


## The ground fill and the river texture (the child layer drawn behind this control).
func _draw_ground_layer() -> void:
	_water_layer.draw_rect(Rect2(Vector2.ZERO, Vector2(SIZE, SIZE)), GROUND_COLOR, true)
	if _water_tex != null:
		var a := world_to_map(Vector3(_water_world.position.x, 0.0, _water_world.position.y))
		var b := world_to_map(Vector3(_water_world.end.x, 0.0, _water_world.end.y))
		_water_layer.draw_texture_rect(_water_tex, Rect2(a, b - a), false)
		water_drawn = true


## EpicBeasts (group "epic_beasts"): its lairs, and the spawn / slain announcements for the "known alive" paw and
## the lair ping.
func _connect_beasts() -> void:
	if _beasts_svc == null or not is_instance_valid(_beasts_svc) or _beasts_svc.is_queued_for_deletion():
		_beasts_svc = null
		for n in get_tree().get_nodes_in_group(&"epic_beasts"):
			if n.has_method(&"lairs") and not n.is_queued_for_deletion():
				_beasts_svc = n
				break
		if _beasts_svc == null:
			_lairs = []
			return
		if _beasts_svc.has_signal(&"beast_spawned") and not _beasts_svc.is_connected(&"beast_spawned", _on_beast_spawned):
			_beasts_svc.connect(&"beast_spawned", _on_beast_spawned)
		if _beasts_svc.has_signal(&"beast_slain") and not _beasts_svc.is_connected(&"beast_slain", _on_beast_slain):
			_beasts_svc.connect(&"beast_slain", _on_beast_slain)
		_lair_alive = {}
		_read_lairs()
		for l: Variant in _lairs:
			var id := StringName(str((l as Dictionary).get("id", "")))
			if _beasts_svc.has_method(&"beast_of") and _beasts_svc.call(&"beast_of", id) != null:
				_lair_alive[id] = true
		return
	_read_lairs()


func _read_lairs() -> void:
	var list: Variant = _beasts_svc.call(&"lairs") if _beasts_svc != null else []
	_lairs = (list as Array).duplicate() if list is Array else []


func _on_beast_spawned(_beast: Variant, lair_id: StringName, _variant: int) -> void:
	_lair_alive[lair_id] = true
	for l: Variant in _lairs:
		if StringName(str((l as Dictionary).get("id", ""))) == lair_id:
			var c: Variant = (l as Dictionary).get("center", null)
			if c is Vector3:
				beast_ping(c as Vector3)
			break
	queue_redraw()


func _on_beast_slain(_beast: Variant, _team: int, _drops: Variant) -> void:
	# The slain beast's lair: every lair whose living beast is gone is no longer "known alive".
	if _beasts_svc == null or not is_instance_valid(_beasts_svc) or not _beasts_svc.has_method(&"beast_of"):
		return
	for id in _lair_alive.keys():
		if _beasts_svc.call(&"beast_of", id) == null:
			_lair_alive.erase(id)
	queue_redraw()


## True while the lair's beast is known alive (announced spawn, no slain yet).
func lair_known_alive(lair_id: StringName) -> bool:
	return bool(_lair_alive.get(lair_id, false))


func _scale() -> float:
	return SIZE / map_size * zoom


func _relation_color(team: int) -> Color:
	if team == Unit.Team.PLAYER:
		return OWN_COLOR
	if team == Unit.Team.ENEMY:
		return ENEMY_COLOR
	return POINT_NEUTRAL_COLOR


## Own watchtower sight rings (after the fog, before the buildings): radius sight_radius() (22 m), OWN at 0.35.
func _draw_sight_rings(tree: SceneTree) -> void:
	for node in tree.get_nodes_in_group(&"capture_points"):
		var p := node as Node3D
		if p == null or not p.is_inside_tree() or StringName(str(p.get(&"kind"))) != &"watchtower":
			continue
		if p.get(&"owner_team") == null or int(p.get(&"owner_team")) != Unit.Team.PLAYER:
			continue
		var sight := float(p.call(&"sight_radius")) if p.has_method(&"sight_radius") else 22.0
		draw_arc(world_to_map(p.global_position), sight * _scale(), 0.0, TAU, 48, Color(OWN_COLOR, SIGHT_RING_ALPHA),
				1.0, true)
		drawn_sight_rings += 1


## Lairs (dashed BEAST circle once the centre is explored, + a 4 px paw while the beast is known alive), then the
## camps (tier colour with a groove border; last seen cleared = the outline only).
func _draw_lairs_and_camps(tree: SceneTree) -> void:
	for l: Variant in _lairs:
		var d := l as Dictionary
		var c: Variant = d.get("center", null)
		if not c is Vector3 or not _explored(c):
			continue
		var at := world_to_map(c)
		var r := (float(d.get("radius", 5.0)) + LAIR_EXTRA) * _scale()
		var col := Color(BEAST_COLOR, LAIR_ALPHA)
		var step := TAU / float(LAIR_ARCS)
		for k in range(0, LAIR_ARCS, 2):
			var a0 := float(k) * step
			draw_arc(at, r, a0, a0 + step, 4, col, 1.0, true)
		drawn_lairs += 1
		if lair_known_alive(StringName(str(d.get("id", "")))):
			_paw(at, LAIR_PAW, Color(BEAST_COLOR, LAIR_PAW_ALPHA), false)
			drawn_lair_paws += 1
	var rings := tree.get_first_node_in_group(&"capture_rings")
	if rings != null and not rings.has_method(&"camp_state"):
		rings = null
	for node in tree.get_nodes_in_group(&"neutral_camps"):
		var camp := node as Node3D
		if camp == null or not camp.is_inside_tree() or not _explored(camp.global_position):
			continue
		var tier := clampi(int(camp.get(&"tier")) if camp.get(&"tier") != null else 1, 1, TIER_COLORS.size())
		var col := TIER_COLORS[tier - 1]
		var cleared := false
		if rings != null:
			cleared = StringName(rings.call(&"camp_state", camp)) == &"cleared"
		elif _fog == null or not is_instance_valid(_fog) or _fog.is_visible(Unit.Team.PLAYER, camp.global_position):
			cleared = camp.has_method(&"is_cleared") and bool(camp.call(&"is_cleared"))
		var r := _rect_at(camp.global_position, CAMP_SIZE)
		if cleared:
			draw_rect(r.grow(-0.5), col, false, 1.0)
			drawn_cleared_camps += 1
		else:
			draw_rect(r.grow(1.0), _groove, true)
			draw_rect(r, col, true)
		drawn_camps += 1


## Capture points (always: explored for both teams from 0:00): tower square, well circle, shrine diamond, 5 px, in
## own / enemy / neutral with a groove outline; awake shrine gold (+ the overlay pulse), asleep shrine faded; the
## selected point gets a gold outline 2 px outside.
func _draw_points(tree: SceneTree) -> void:
	_awake_shrines.clear()
	var chosen: Variant = selection.selected_neutral if selection != null else null
	for node in tree.get_nodes_in_group(&"capture_points"):
		var p := node as Node3D
		if p == null or not p.is_inside_tree():
			continue
		var kind := StringName(str(p.get(&"kind")))
		var held := int(p.get(&"owner_team")) if p.get(&"owner_team") != null else -1
		var fill := _relation_color(held)
		if held == Unit.Team.PLAYER or held == Unit.Team.ENEMY:
			drawn_held_points += 1
		var at := world_to_map(p.global_position)
		var h := POINT_SIZE * 0.5
		if kind == &"shrine":
			var awake: bool = p.has_method(&"is_awake") and bool(p.call(&"is_awake"))
			if awake:
				fill = SHRINE_GOLD
				_awake_shrines.append(p.global_position)
				drawn_awake_shrines += 1
			else:
				fill = Color(fill, ASLEEP_ALPHA)
			_diamond(p.global_position, POINT_SIZE, fill)
		elif kind == &"well":
			draw_circle(at, h, fill)
			draw_arc(at, h, 0.0, TAU, 16, _groove, 1.0, true)
		else:
			var r := Rect2(at - Vector2(h, h), Vector2(POINT_SIZE, POINT_SIZE))
			draw_rect(r, fill, true)
			draw_rect(r, _groove, false, 1.0)
		if chosen != null and is_instance_valid(chosen) and chosen == p:
			if kind == &"shrine":
				var s := h + 2.5
				var pts := PackedVector2Array([at + Vector2(0, -s), at + Vector2(s, 0), at + Vector2(0, s), at + Vector2(-s, 0),
						at + Vector2(0, -s)])
				draw_polyline(pts, SHRINE_GOLD, 1.0)
			elif kind == &"well":
				draw_arc(at, h + 2.0, 0.0, TAU, 16, SHRINE_GOLD, 1.0, true)
			else:
				draw_rect(Rect2(at - Vector2(h, h), Vector2(POINT_SIZE, POINT_SIZE)).grow(2.0), SHRINE_GOLD, false, 1.0)
		drawn_points += 1


## The paw glyph (ui-mapfill.md 9.3), box `s` centred on `c`: main pad r 0.28 s at c + (0, 0.15 s), three toes
## r 0.14 s. `outline`: a groove circle 0.5 px larger behind each pad.
func _paw(c: Vector2, s: float, color: Color, outline: bool) -> void:
	var pads := [[c + Vector2(0.0, 0.15 * s), 0.28 * s], [c + Vector2(-0.30 * s, -0.18 * s), 0.14 * s],
			[c + Vector2(0.0, -0.32 * s), 0.14 * s], [c + Vector2(0.30 * s, -0.18 * s), 0.14 * s]]
	if outline:
		for pad: Array in pads:
			draw_circle(pad[0], float(pad[1]) + 0.5, _groove)
	for pad: Array in pads:
		draw_circle(pad[0], maxf(float(pad[1]), 0.5), color)


## A scripted unit not seen before = a wave: flash the arrow toward the centre of the new Shadow units.
## The first scan only records the guards already on the map.
func _scan_scripted() -> void:
	var seen := {}
	var sum := Vector3.ZERO
	var fresh := 0
	for node in get_tree().get_nodes_in_group("scripted"):
		var id := node.get_instance_id()
		seen[id] = true
		if not _scripted_baseline or _scripted_seen.has(id):
			continue
		var u := node as Unit
		if u == null or not u.is_alive() or u.team != Unit.Team.ENEMY:
			continue
		sum += u.global_position
		fresh += 1
	_scripted_seen = seen
	if not _scripted_baseline:
		_scripted_baseline = true
		return
	if fresh > 0:
		wave_from = sum / float(fresh)
		wave_flash_left = WAVE_FLASH_TIME
		wave_flash_count += 1


## The mission node: `mission` if set, else the current scene when it answers objectives().
func _mission_node() -> Node:
	if mission != null and is_instance_valid(mission):
		return mission
	var scene := get_tree().current_scene if is_inside_tree() else null
	if scene != null and scene.has_method(&"objectives"):
		mission = scene
		return scene
	return null


## First active primary objective whose row has "position" (Vector3) or "positions" (Array of Vector3).
func _update_objective_points() -> void:
	var points: Array[Vector3] = []
	var m := _mission_node()
	if m != null:
		var rows: Variant = m.call(&"objectives")
		if rows is Array:
			for row: Variant in rows:
				if not row is Dictionary:
					continue
				var d := row as Dictionary
				var primary := bool(d.get("primary", String(d.get("type", "primary")) == "primary"))
				if not primary or String(d.get("state", "")) != "active":
					continue
				var pos: Variant = d.get("position", null)
				if pos is Vector3:
					points.append(pos)
				var many: Variant = d.get("positions", null)
				if many is Array:
					for p: Variant in many:
						if p is Vector3:
							points.append(p)
				if not points.is_empty():
					break
	if points != objective_points:
		_overlay_dirty = true
	objective_points = points


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			# Minimap zoom around the mouse; the 3D camera never sees these wheel events.
			if mb.pressed:
				var dir := 1.0 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0
				set_zoom(zoom + dir * ZOOM_STEP, mb.position)
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			# With a targeted order waiting (X, M, G, F, rally), the click gives that order on the map
			# spot, like a click in the world; otherwise it moves the camera (drag keeps moving it).
			if mb.pressed and selection and selection.confirm_pending_at(map_to_world(mb.position)):
				_dragging = false
			else:
				_dragging = mb.pressed
				if mb.pressed:
					_focus_camera(mb.position)
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			if selection:
				if selection.bounty_mode != null and selection.bounty_mode.active:
					selection.bounty_mode.exit()
				elif selection.get_pending_order() != &"":
					selection.cancel_targeting()
				else:
					selection.order_at(map_to_world(mb.position))
			accept_event()
	elif event is InputEventMouseMotion and _dragging:
		_focus_camera((event as InputEventMouseMotion).position)
		accept_event()


func _focus_camera(point: Vector2) -> void:
	if camera_rig:
		camera_rig.focus_on(map_to_world(point))
		queue_redraw()


func _draw() -> void:
	redraw_count += 1
	drawn_enemy_icons = 0
	drawn_ghosts = 0
	drawn_braziers = 0
	drawn_lit_braziers = 0
	drawn_flame_lines = 0
	drawn_peddler = ""
	drawn_champions = 0
	drawn_flags = 0
	drawn_taverns = 0
	drawn_roads = 0
	drawn_posts = 0
	drawn_held_posts = 0
	drawn_guilds = 0
	drawn_sacks = 0
	drawn_caravans = 0
	drawn_loaded_caravans = 0
	drawn_magpies = 0
	route_drawn = false
	drawn_points = 0
	drawn_held_points = 0
	drawn_awake_shrines = 0
	drawn_camps = 0
	drawn_cleared_camps = 0
	drawn_lairs = 0
	drawn_lair_paws = 0
	drawn_beasts = 0
	drawn_sight_rings = 0
	# The ground fill and the river are drawn by the GroundLayer child (behind this control, LINEAR filtered).
	if _water_layer == null:
		draw_rect(Rect2(Vector2.ZERO, Vector2(SIZE, SIZE)), GROUND_COLOR, true)
	var tree := get_tree()

	# Trade roads: ground paint, under the fog (black while unexplored).
	for seg: Variant in _roads:
		if seg is PackedVector3Array and (seg as PackedVector3Array).size() >= 2:
			var pts := PackedVector2Array()
			for p in (seg as PackedVector3Array):
				pts.append(world_to_map(p))
			draw_polyline(pts, ROAD_COLOR, ROAD_WIDTH)
			drawn_roads += 1

	# Fog of war (fog-of-war.md "Minimap"): one 60 x 60 texture over the ground, under the icons.
	# Things the fog hides have visible == false (FogOfWar sets it): they are skipped below.
	if _fog_tex != null and _fog != null and is_instance_valid(_fog):
		var a := world_to_map(Vector3(-FogOfWar.MAP_HALF, 0.0, -FogOfWar.MAP_HALF))
		var b := world_to_map(Vector3(FogOfWar.MAP_HALF, 0.0, FogOfWar.MAP_HALF))
		draw_texture_rect(_fog_tex, Rect2(a, b - a), false)

	_draw_sight_rings(tree)

	for node in tree.get_nodes_in_group("crystal_nodes"):
		if node is Node3D and (node as Node3D).is_visible_in_tree():
			_square((node as Node3D).global_position, 4.0, CRYSTAL_COLOR)

	_draw_braziers(tree)
	_draw_mission_peddlers(tree)

	# Grey ghosts of enemy buildings seen once and now in the fog.
	for node in tree.get_nodes_in_group("fog_ghosts"):
		if node is Node3D:
			_square((node as Node3D).global_position, 6.0, GHOST_COLOR)
			drawn_ghosts += 1

	# Buildings: kingdom colour (neutral: Unit.team_color), size from the footprint (keep / hall 6 px,
	# hearth 4, spire 3); construction sites are drawn hollow. Hidden (fogged) ones are skipped.
	for node in tree.get_nodes_in_group("buildings"):
		if node is Node3D and (node as Node3D).is_visible_in_tree() and not node.is_in_group(&"taverns"):
			var team: int = int(node.get("team")) if node.get("team") != null else int(Unit.Team.PLAYER)
			var color := PLAYER_TEAM_COLOR
			if team == Unit.Team.ENEMY:
				color = ENEMY_TEAM_COLOR
			elif team == Unit.Team.NEUTRAL:
				color = Unit.team_color(team)
			var size := 6.0
			var type: Variant = node.get("building_type")
			if type is BuildingType:
				size = clampf(float((type as BuildingType).footprint.x) * 2.0, 3.0, 6.0)
			var site: bool = node.has_method("is_constructed") and not bool(node.call("is_constructed"))
			_square((node as Node3D).global_position, size, color, not site)
			if team != Unit.Team.PLAYER:
				drawn_enemy_icons += 1
	_draw_taverns(tree)
	_draw_trade_buildings(tree)
	_draw_lairs_and_camps(tree)
	_draw_points(tree)
	# Loot sacks (only where the player sees them).
	for node in tree.get_nodes_in_group(&"loot_sacks"):
		if node is Node3D and (node as Node3D).is_visible_in_tree():
			_square((node as Node3D).global_position, 3.0, SACK_COLOR)
			drawn_sacks += 1

	var worn_by: Node3D = _crown_wearer()
	if worn_by == null and _artifact_on_ground() and artifact.is_visible_in_tree():
		_square(artifact.global_position, 5.0, ARTIFACT_COLOR)

	# Units: plain squares first, heroes on top. Neutral units (Ruin Wardens) in their own colour.
	# Enemy / neutral units out of sight are hidden by the fog (visible == false): not drawn.
	var heroes: Array[Unit] = []
	var champions: Array[Unit] = []
	var beasts: Array[Unit] = []
	for node in tree.get_nodes_in_group("units"):
		var u := node as Unit
		if u == null or not u.is_alive() or not u.is_visible_in_tree():
			continue
		if u.team != Unit.Team.PLAYER:
			drawn_enemy_icons += 1
		if u.is_in_group(&"beasts"):
			beasts.append(u)   # a paw after the champions, never the neutral square
		elif u.is_in_group(&"champions"):
			champions.append(u)
		elif u.is_in_group("heroes") or u.is_in_group("enemy_heroes"):
			heroes.append(u)
		elif u.is_in_group(&"caravans"):
			_draw_caravan(u)
		elif u.is_in_group(&"magpies"):
			_square(u.global_position, 3.0, MAGPIE_COLOR)
			drawn_magpies += 1
		elif u.team == Unit.Team.PLAYER:
			_square(u.global_position, 4.0 if u.selected else 3.0, OWN_COLOR)
		elif u.team == Unit.Team.ENEMY:
			_square(u.global_position, 3.0, ENEMY_COLOR)
		else:
			_square(u.global_position, 3.0, Unit.team_color(u.team))
	_draw_flags(tree)
	# Champions: a circle in the own / enemy colour with a 1 px gold ring (enemy ones only when shown).
	for u in champions:
		var p := world_to_map(u.global_position)
		draw_circle(p, CHAMPION_RADIUS, OWN_COLOR if u.team == Unit.Team.PLAYER else ENEMY_COLOR)
		draw_arc(p, CHAMPION_RING, 0.0, TAU, 16, CHAMPION_RING_COLOR, 1.0, true)
		drawn_champions += 1
	# Visible epic beasts: a 6 x 6 BEAST paw with a groove outline.
	for u in beasts:
		_paw(world_to_map(u.global_position), BEAST_PAW, BEAST_COLOR, true)
		drawn_beasts += 1
	for u in heroes:
		_diamond(u.global_position, 6.0, OWN_HERO_COLOR if u.team == Unit.Team.PLAYER else ENEMY_HERO_COLOR)
	# The Ember Crown on its wearer: a gold ring around the wizard's diamond (not while fogged).
	if worn_by != null and worn_by.is_visible_in_tree():
		draw_arc(world_to_map(worn_by.global_position), 6.0, 0.0, TAU, 16, ARTIFACT_COLOR, 1.5)
	_draw_route(tree)

	_draw_camera_quad()
	# Sunken map (ui-style.md 7.1): a frame_dark line on the edge and a groove line just inside it.
	draw_rect(Rect2(Vector2(0.5, 0.5), Vector2(SIZE - 1.0, SIZE - 1.0)), _frame_dark, false, 1.0)
	draw_rect(Rect2(Vector2(1.5, 1.5), Vector2(SIZE - 3.0, SIZE - 3.0)), _groove, false, 1.0)
	# Zoomed in: the factor in the bottom-right corner ("2x").
	if zoom > ZOOM_MIN:
		var font := ThemeDB.fallback_font
		var txt := ("%dx" % int(zoom)) if is_equal_approx(zoom, roundf(zoom)) else ("%.1fx" % zoom)
		var at := Vector2(SIZE - 6.0 - font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x, SIZE - 6.0)
		draw_string_outline(font, at, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, _groove)
		draw_string(font, at, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, CAMERA_COLOR)


## Braziers (mission 1): flame lines first (under every icon), then the bowls. Cold = stone ring with a
## dark bowl, plus an orange arc while Vessa is lighting it; lit = orange fire dot with a bright core.
func _draw_braziers(tree: SceneTree) -> void:
	var braziers := tree.get_nodes_in_group("braziers")
	if braziers.is_empty():
		return
	for node in braziers:
		if not node.has_method(&"minimap_flame_line"):
			continue
		var line: Variant = node.call(&"minimap_flame_line")
		if line is Array and (line as Array).size() >= 2 and line[0] is Vector3 and line[1] is Vector3:
			var a := world_to_map(line[0])
			var b := world_to_map(line[1])
			draw_line(a, b, Color(_groove, 0.6), FLAME_LINE_WIDTH + 2.0, true)   # dark edge: reads on fog
			draw_line(a, b, FLAME_LINE_COLOR, FLAME_LINE_WIDTH, true)
			drawn_flame_lines += 1
	for node in braziers:
		if not node is Node3D:
			continue
		var p := world_to_map((node as Node3D).global_position)
		drawn_braziers += 1
		if bool(node.get(&"lit")):
			drawn_lit_braziers += 1
			draw_circle(p, BRAZIER_RADIUS + 1.0, _groove)
			draw_circle(p, BRAZIER_RADIUS, BRAZIER_LIT_COLOR)
			draw_circle(p, BRAZIER_RADIUS * 0.45, BRAZIER_CORE_COLOR)
		else:
			draw_circle(p, BRAZIER_RADIUS, BRAZIER_BOWL_COLOR)
			draw_arc(p, BRAZIER_RADIUS, 0.0, TAU, 16, BRAZIER_COLD_COLOR, 1.5, true)
			var prog: Variant = node.get(&"progress")
			if prog != null and float(prog) > 0.0:
				draw_arc(p, BRAZIER_RADIUS + 2.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(float(prog), 0.0, 1.0),
						20, BRAZIER_LIT_COLOR, 2.0, true)


## Taverns (group "taverns"): 6 x 6 amber squares with a groove outline, once their spot is explored.
func _draw_taverns(tree: SceneTree) -> void:
	for node in tree.get_nodes_in_group(&"taverns"):
		var t := node as Node3D
		if t == null or not t.is_inside_tree():
			continue
		if _fog != null and is_instance_valid(_fog) and not _fog.is_explored(Unit.Team.PLAYER, t.global_position):
			continue
		var p := world_to_map(t.global_position)
		var r := Rect2(p - Vector2(TAVERN_SIZE, TAVERN_SIZE) * 0.5, Vector2(TAVERN_SIZE, TAVERN_SIZE))
		draw_rect(r, TAVERN_COLOR, true)
		draw_rect(r, _groove, false, 1.0)
		drawn_taverns += 1


## Trading posts (5 x 5, a 1 px border: groove, or the holder's team colour) then the Magpie Dens / Greywater Lodges
## (6 x 6 with a groove outline); landmarks, drawn once their spot is explored.
func _draw_trade_buildings(tree: SceneTree) -> void:
	for node in tree.get_nodes_in_group(&"trade_posts"):
		var p := node as Node3D
		if p == null or not p.is_inside_tree() or not _explored(p.global_position):
			continue
		var holder := int(p.call(&"holder_team")) if p.has_method(&"holder_team") else -1
		var border := _groove
		if holder == Unit.Team.PLAYER:
			border = PLAYER_TEAM_COLOR
		elif holder == Unit.Team.ENEMY:
			border = ENEMY_TEAM_COLOR
		var r := _rect_at(p.global_position, POST_SIZE)
		draw_rect(r, POST_COLOR, true)
		draw_rect(r, border, false, 1.0)
		drawn_posts += 1
		if holder == Unit.Team.PLAYER or holder == Unit.Team.ENEMY:
			drawn_held_posts += 1
	for node in tree.get_nodes_in_group(&"guilds"):
		var g := node as Node3D
		if g == null or not g.is_inside_tree() or not _explored(g.global_position):
			continue
		var r := _rect_at(g.global_position, GUILD_SIZE)
		draw_rect(r, LODGE_COLOR if StringName(str(g.get(&"kind"))) == &"lodge" else DEN_COLOR, true)
		draw_rect(r, _groove, false, 1.0)
		drawn_guilds += 1


## A caravan: a 4 x 3 px rect (5 x 4 selected) in the own / enemy colour, a 1 px gold dot while loaded.
func _draw_caravan(u: Unit) -> void:
	var color := OWN_COLOR if u.team == Unit.Team.PLAYER else (ENEMY_COLOR if u.team == Unit.Team.ENEMY \
			else Unit.team_color(u.team))
	var s := Vector2(5.0, 4.0) if u.selected else Vector2(4.0, 3.0)
	var p := world_to_map(u.global_position)
	draw_rect(Rect2(p - s * 0.5, s), color, true)
	drawn_caravans += 1
	if u.has_method(&"is_loaded") and bool(u.call(&"is_loaded")):
		draw_rect(Rect2(p - Vector2(0.5, 0.5), Vector2(1.0, 1.0)), SACK_COLOR, true)
		drawn_loaded_caravans += 1


## The route of the selected Bazaar / caravans (RouteLine, group "route_line") as a 1 px gold polyline.
func _draw_route(tree: SceneTree) -> void:
	var line := tree.get_first_node_in_group(&"route_line")
	if line == null or not line.has_method(&"is_showing") or not bool(line.call(&"is_showing", &"route")):
		return
	var pts: Variant = line.call(&"shown_points", &"route")
	if not pts is PackedVector3Array or (pts as PackedVector3Array).size() < 2:
		return
	var out := PackedVector2Array()
	for p in (pts as PackedVector3Array):
		out.append(world_to_map(p))
	draw_polyline(out, ROUTE_COLOR, 1.0)
	route_drawn = true


func _explored(world: Vector3) -> bool:
	return _fog == null or not is_instance_valid(_fog) or _fog.is_explored(Unit.Team.PLAYER, world)


func _rect_at(world: Vector3, size: float) -> Rect2:
	var p := world_to_map(world)
	return Rect2(p - Vector2(size, size) * 0.5, Vector2(size, size))


## Bounty flags (group "bounties"): a gold coin with a 1 px ring in the flag's team colour; own flags always, enemy
## flags only while the player sees them; the selected flag bigger with a gold ring.
func _draw_flags(tree: SceneTree) -> void:
	var chosen: Node = selection.selected_bounty if selection != null else null
	for node in tree.get_nodes_in_group(&"bounties"):
		var f := node as Node3D
		if f == null or not BountyMode.flag_shown(f, Unit.Team.PLAYER):
			continue
		var p := world_to_map(f.global_position)
		var own := BountyMode.flag_team(f) == Unit.Team.PLAYER
		var ring := PLAYER_TEAM_COLOR if own else ENEMY_TEAM_COLOR
		if f == chosen:
			draw_circle(p, FLAG_SELECTED_RADIUS, FLAG_COIN_COLOR)
			draw_arc(p, FLAG_SELECTED_RADIUS + 0.5, 0.0, TAU, 16, ring, 1.0, true)
			draw_arc(p, FLAG_SELECTED_RING, 0.0, TAU, 16, CHAMPION_RING_COLOR, 1.0, true)
		else:
			draw_circle(p, FLAG_RADIUS, FLAG_COIN_COLOR)
			draw_arc(p, FLAG_RING, 0.0, TAU, 16, ring, 1.0, true)
		drawn_flags += 1


## Mission peddlers (MissionCagedPeddler: they have `caged`): a cage (square + 2 bars) around a small coin,
## then a bigger coin once freed. Skirmish peddlers stay off the map, as before.
func _draw_mission_peddlers(tree: SceneTree) -> void:
	for node in tree.get_nodes_in_group("peddlers"):
		if not node is Node3D or not &"caged" in node:
			continue
		var p := world_to_map((node as Node3D).global_position)
		if bool(node.get(&"caged")):
			drawn_peddler = "caged"
			var h := 4.0
			draw_rect(Rect2(p - Vector2(h, h), Vector2(h, h) * 2.0), BRAZIER_BOWL_COLOR, true)
			draw_circle(p, 1.8, PEDDLER_COLOR)
			draw_rect(Rect2(p - Vector2(h, h), Vector2(h, h) * 2.0), CAGE_COLOR, false, 1.0)
			for x in [-2.0, 2.0]:
				draw_line(p + Vector2(x, -h), p + Vector2(x, h), CAGE_COLOR, 1.0)
		else:
			drawn_peddler = "free"
			draw_circle(p, 3.5, _groove)
			draw_circle(p, 2.8, PEDDLER_COLOR)


## Overlay (child Control, drawn over the map): the objective pulse and the wave warning.
func _draw_overlay() -> void:
	overlay_draws += 1
	# Hunt warning pings: 3 WARN rings expanding from the hunted thing over 0.9 s.
	for pg: Array in _pings:
		var t := 1.0 - float(pg[1]) / PING_TIME
		var at := world_to_map(pg[0])
		var ping_col: Color = pg[2] if pg.size() > 2 else UIStyle.WARN
		for k in PING_RINGS:
			var tk := t - float(k) * 0.2
			if tk <= 0.0 or tk >= 1.0:
				continue
			_overlay.draw_arc(at, lerpf(2.0, PING_MAX_RADIUS, tk), 0.0, TAU, 24, Color(ping_col, 1.0 - tk), 1.5, true)
	# Awake shrines: a gold ring growing 4 -> 7 px while it fades 0.8 -> 0, every 1.0 s.
	if not _awake_shrines.is_empty():
		var st := fposmod(_anim_time, SHRINE_PULSE_PERIOD) / SHRINE_PULSE_PERIOD
		var sr := lerpf(SHRINE_PULSE_FROM, SHRINE_PULSE_TO, st)
		var sc := Color(SHRINE_GOLD, 0.8 * (1.0 - st))
		for w in _awake_shrines:
			_overlay.draw_arc(world_to_map(w), sr, 0.0, TAU, 20, sc, 1.0, true)
	# Pulsing ring on the current primary objective: grows 4 -> 10 px and fades, 1.2 s loop.
	if not objective_points.is_empty():
		var t := fposmod(_anim_time, OBJECTIVE_PULSE_PERIOD) / OBJECTIVE_PULSE_PERIOD
		var r := lerpf(4.0, 10.0, t)
		var col := Color(OBJECTIVE_RING_COLOR, 1.0 - t * 0.85)
		for w in objective_points:
			var p := world_to_map(w)
			_overlay.draw_arc(p, r + 1.0, 0.0, TAU, 24, Color(_groove, col.a * 0.6), 1.0, true)
			_overlay.draw_arc(p, r, 0.0, TAU, 24, col, 1.5, true)
	# Wave incoming: a blinking WARN arrow on the map edge toward the wave (pointing in) + a ring on it.
	if wave_flash_left > 0.0 and fposmod(_anim_time * WAVE_BLINK_HZ, 1.0) < 0.6:
		var spawn := world_to_map(wave_from)
		var centre := Vector2(SIZE, SIZE) * 0.5
		var dir := spawn - centre
		if dir.length() < 1.0:
			dir = Vector2.UP
		dir = dir.normalized()
		var reach := SIZE * 0.5 - WAVE_ARROW_INSET
		var edge := centre + dir * reach / maxf(absf(dir.x), absf(dir.y))
		# Arrow pointing in (toward the centre): a 10 px head, 5 px half-width, and a 5 px tail outward.
		var tip := edge - dir * 6.0
		var base := tip + dir * 10.0
		var side := Vector2(-dir.y, dir.x) * 5.0
		var tail := base + dir * 5.0
		_overlay.draw_line(base, tail, _groove, 4.0, true)
		_overlay.draw_line(base, tail, UIStyle.WARN, 2.0, true)
		var tri := PackedVector2Array([tip, base + side, base - side])
		_overlay.draw_colored_polygon(tri, UIStyle.WARN)
		tri.append(tip)
		_overlay.draw_polyline(tri, _groove, 1.0, true)
		_overlay.draw_arc(spawn, 7.0, 0.0, TAU, 24, UIStyle.WARN, 2.0, true)


## The living wizard wearing the artifact (the Ember Crown), or null.
func _crown_wearer() -> Node3D:
	if artifact == null or not is_instance_valid(artifact) or not "wearer" in artifact:
		return null
	var w: Variant = artifact.get("wearer")
	if w is Unit and is_instance_valid(w) and (w as Unit).is_alive():
		return w
	return null


## True when the artifact lies somewhere and can be taken (not while it is dropping).
func _artifact_on_ground() -> bool:
	if artifact == null or not is_instance_valid(artifact) or not artifact.is_inside_tree():
		return false
	if artifact.has_method(&"is_available"):
		return bool(artifact.call(&"is_available"))
	return true


func _square(world: Vector3, size: float, color: Color, filled := true) -> void:
	var p := world_to_map(world)
	draw_rect(Rect2(p - Vector2(size, size) * 0.5, Vector2(size, size)), color, filled, -1.0 if filled else 1.0)


func _diamond(world: Vector3, size: float, color: Color) -> void:
	var p := world_to_map(world)
	var h := size * 0.5
	var pts := PackedVector2Array([p + Vector2(0, -h), p + Vector2(h, 0), p + Vector2(0, h), p + Vector2(-h, 0)])
	draw_colored_polygon(pts, color)
	# 1 px groove outline so the wizard reads over the gold artifact (ui-style.md 7.1).
	pts.append(pts[0])
	draw_polyline(pts, _groove, 1.0)


## The part of the ground the camera sees: the 4 screen corners projected on y = 0.
func _draw_camera_quad() -> void:
	if camera_rig == null or camera_rig.camera == null:
		return
	var cam := camera_rig.camera
	var screen := cam.get_viewport().get_visible_rect().size
	var ground := Plane(Vector3.UP, 0.0)
	var points := PackedVector2Array()
	for corner in [Vector2.ZERO, Vector2(screen.x, 0), screen, Vector2(0, screen.y)]:
		var hit: Variant = ground.intersects_ray(cam.project_ray_origin(corner), cam.project_ray_normal(corner))
		if hit == null:
			return
		points.append(world_to_map(hit))
	points.append(points[0])
	draw_polyline(points, CAMERA_COLOR, 1.0)
