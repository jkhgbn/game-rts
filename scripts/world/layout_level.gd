class_name LayoutLevel
extends Skirmish
## A playable skirmish level built from a MapLayout (docs/design/map-production.md 2.8, tool task MT2; new-maps.md
## NM.C1): `data/maps/<id>.map` -> World Forge `map <id>` -> `data/maps/<id>_layout.tres` -> this level. Everything
## Skirmish (scripts/world/skirmish.gd) builds from Crown Hollow constants comes from the layout instead:
## - size (MapInfo, fog, BuildGrid, camera, minimap), keeps per seat (open seats only: the first seat of side 0 is
##   the PLAYER, the first of side 1 the ENEMY; `closed_seat` and every other seat stay neutral land, their nodes
##   included), wizard starts (a `start` spot, else 9.9 m from the keep toward the centre), crystal nodes with roles
##   (`role=` or the id suffix _a / _b / _mid / _rich / _third), the crown + Ruin Wardens, peddlers, taverns, caches;
## - the river, moat and crossings (RiverSystem), roads (TradeNetwork ring + ground paint), trade posts, guild
##   houses, capture points, camps, lairs, herds / rabbits (`slot sub=graze` / `sub=rabbit`), landmark props,
##   blocks (colliders, layer 1, before the bake);
## - the forest: MapForest.plan(layout) = the main.gd / skirmish.gd generator with the layout's seeds (so
##   `crown_hollow_level.map` rebuilds Crown Hollow tree for tree);
## - the bot's fixed slots: `bot_point(team, p)` maps Commander's Crown-Hollow Shadow-side points onto this map
##   (a rigid move of Crown Hollow's base district onto the seat's keep), `natural_hall_spot` / `rich_hall_spot` /
##   `market_slot` / `tower_slot` read `slot` spots (sub natural_hall, rich_hall, market, tower_natural,
##   tower_rich) of the team's image.
## Set `layout_path` (a `_layout.tres`, or a `.map` that is compiled on load: tools/world_forge is needed then) or
## `layout` before the node enters the tree. Scene: scenes/layout_level.tscn (the skirmish scene with this script).
## Mission scripts may extend it and read `layout.mark(id)` / `trigger(id)` / `path(id)`.

const FORGE_MAP_PATH := "res://tools/world_forge/forge_map.gd"
const CH_KEEP := Vector3(-43.0, 0.0, 43.0)        ## Crown Hollow's player keep (PLAYER_START + KEEP_OFFSET).
const CH_TO_CENTRE := Vector3(0.70710678, 0.0, -0.70710678)
## Default crystals per node role (balance-1.md 2a; third / extra = a remote node).
const ROLE_AMOUNTS := {"a": 2000, "b": 2000, "mid": 2500, "rich": 2500, "third": 1500}
const CAMP_KINDS := {"wallow": [&"bristleback", 1, 0.0, "Bristleback Wallow"], "nest": [&"mirefang", 2, 0.0, "Ford Nest"],
	"hollow": [&"gloomcap", 2, 150.0, "Gloomcap Hollow"], "stag": [&"hollow_stag", 3, 210.0, "Stag Glade"]}
const LAIR_KINDS := {"heath": [&"tusker", 4.0, 390.0, 600.0, "Heath"], "crag": [&"roc", 5.0, 510.0, 600.0, "Crag"],
	"hollow": [&"direwolf", 4.0, 450.0, 600.0, "Greymane Hollow"], "den": [&"grizzlemaw", 5.0, 600.0, 720.0, "Old Wood Den"]}
const POINT_NAMES := {"watchtower": "Watch", "well": "Well", "shrine": "Wayshrine"}

## The layout file: res://data/maps/<id>_layout.tres (or a .map, compiled on load).
@export var layout_path: String = ""
## The layout itself (set directly by tests / tools; else loaded from layout_path).
@export var layout: MapLayout

var forest_plan: Dictionary = {}     ## MapForest.plan() result (read only).
var seat_of_team := {}               ## Unit.Team -> seat dict of the layout (PLAYER, ENEMY).
var closed_teams: Array[int] = []    ## Layout seats that do not play (their districts are neutral land).
var _keep_pos := {}                  ## team -> Vector3
var _start_pos := {}                 ## team -> Vector3
var _canon_keep := CH_KEEP
var _canon_rot := Basis()            ## turns Crown Hollow's base district onto the canonical keep
var _node_role := {}                 ## team -> {role -> node id}
var _lairs: Array[Dictionary] = []
var _layout_error := ""


func _init() -> void:
	super()
	# Skirmish._init turns the map systems on only for skirmish.gd itself; a layout level plays the full skirmish.
	var s := get_script() as Script
	var full := s == null or s.resource_path == "res://scripts/world/layout_level.gd"
	tavern_enabled = full
	trade_enabled = full
	river_enabled = full
	points_enabled = full
	camps_enabled = full
	beasts_enabled = full
	tiers_enabled = full


func _ready() -> void:
	if layout == null:
		layout = load_layout(layout_path)
	if layout == null:
		_layout_error = "LayoutLevel: no layout (layout_path=%s)" % layout_path
		push_error(_layout_error)
		layout = MapLayout.new()
	_assign_seats()
	var crown_spot := _first("crown")
	if not crown_spot.is_empty():
		MID_CAMP = crown_spot["pos"]
		ARTIFACT_POS = crown_spot["pos"]
	super()


## A MapLayout from a `_layout.tres` path, or a `.map` compiled by World Forge (tools needed); null on failure.
static func load_layout(path: String) -> MapLayout:
	if path == "":
		return null
	if path.ends_with(".map"):
		if not ResourceLoader.exists(FORGE_MAP_PATH):
			return null
		var fm: RefCounted = (load(FORGE_MAP_PATH) as GDScript).new()
		if not bool(fm.call(&"compile", path)):
			for l: String in fm.get(&"spec").call(&"error_lines"):
				push_error(l)
			return null
		return fm.get(&"layout") as MapLayout
	if not ResourceLoader.exists(path):
		return null
	return load(path) as MapLayout


## The layout this level plays (Map Lab / World Forge read it).
func map_layout() -> MapLayout:
	return layout


## Why the layout could not be loaded ("" = fine). Set: the level shows it on the HUD and never starts the match
## (review M2); tools (lab_match) check `load_layout` themselves before building the level.
func layout_error() -> String:
	return _layout_error


# ---------------------------------------------------------------- seats

func _assign_seats() -> void:
	seat_of_team.clear()
	closed_teams.clear()
	for s: Dictionary in layout.seats:
		var t := int(s["team"])
		if layout.closed_seats.has(t):
			closed_teams.append(t)
			continue
		var side := int(s["side"])
		var team: int = Unit.Team.PLAYER if side == 0 else Unit.Team.ENEMY
		if seat_of_team.has(team):
			closed_teams.append(t)   # one seat per side plays (a 2v2 map in a 1v1: the others are neutral land)
			continue
		seat_of_team[team] = s
	for team: int in [Unit.Team.PLAYER, Unit.Team.ENEMY]:
		var k := _keep_spot(team)
		if k.is_empty():
			push_error("LayoutLevel %s: no keep for the %s seat" % [layout.id, "player" if team == 0 else "enemy"])
			_keep_pos[team] = Vector3(-30, 0, 30) if team == 0 else Vector3(30, 0, -30)
			_start_pos[team] = _keep_pos[team]
			continue
		_keep_pos[team] = k["pos"]
		_start_pos[team] = MapForest.start_of(layout, k)
	# the canonical keep (image identity) and the turn of Crown Hollow's district onto it (bot slots)
	for k: Dictionary in layout.spots_of("keep"):
		if String(k.get("image", "identity")) == "identity":
			_canon_keep = k["pos"]
			break
	var d := Vector2(-_canon_keep.x, -_canon_keep.z)
	if d.length() > 0.01:
		var a_ch := atan2(CH_TO_CENTRE.x, CH_TO_CENTRE.z)
		var a_k := atan2(d.x, d.y)
		var turn := a_k - a_ch
		_canon_rot = Basis() if absf(turn) < 1e-6 else Basis(Vector3.UP, turn)
	# node roles per team
	for team: int in seat_of_team:
		_node_role[team] = _roles_for(team)


func _seat_frame(team: int) -> Transform3D:
	var s: Dictionary = seat_of_team.get(team, {})
	return s.get("frame", Transform3D.IDENTITY)


func _seat_image(team: int) -> String:
	var s: Dictionary = seat_of_team.get(team, {})
	return String(s.get("frame_name", "identity"))


func _keep_spot(team: int) -> Dictionary:
	var s: Dictionary = seat_of_team.get(team, {})
	if s.is_empty():
		return {}
	for k: Dictionary in layout.spots_of("keep"):
		if int(k["team"]) == int(s["team"]):
			return k
	return {}


func _first(kind: String) -> Dictionary:
	var l := layout.spots_of(kind)
	return l[0] if not l.is_empty() else {}


## Role -> node id for the team's image (role= prop, id suffix, else ranked by distance to its keep).
func _roles_for(team: int) -> Dictionary:
	var out := {}
	var img := _seat_image(team)
	var mine: Array[Dictionary] = []
	for n: Dictionary in layout.spots_of("node"):
		if String(n.get("image", "identity")) == img:
			mine.append(n)
	var free: Array[Dictionary] = []
	for n in mine:
		var role := _role_of(n)
		if role != "" and not out.has(role):
			out[role] = String(n["id"])
		else:
			free.append(n)
	var kp: Vector3 = _keep_pos.get(team, Vector3.ZERO)
	free.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return kp.distance_to(a["pos"]) < kp.distance_to(b["pos"]))
	for n in free:
		for role: String in ["a", "b", "mid", "rich", "third"]:
			if not out.has(role):
				out[role] = String(n["id"])
				break
	return out


static func _role_of(n: Dictionary) -> String:
	var props: Dictionary = n.get("props", {})
	if props.has("role"):
		return String(props["role"])
	var base := String(n.get("twin_of", n["id"]))
	for role: String in ["rich", "mid", "third", "a", "b"]:
		if base.ends_with("_" + role):
			return role
	return ""


func _slot(team: int, sub: String) -> Vector3:
	var img := _seat_image(team)
	for s: Dictionary in layout.spots_of("slot"):
		if String(s.get("sub", "")) == sub and String(s.get("image", "identity")) == img:
			return s["pos"]
	return Vector3.INF


# ---------------------------------------------------------------- public helpers (Skirmish API on the layout)

func _map_size() -> Vector2:
	return Vector2(layout.size_x, layout.size_z)


func _map_id() -> StringName:
	return layout.id


func _player_start() -> Vector3:
	return _start_pos.get(Unit.Team.PLAYER, PLAYER_START)


func start_position(team: int) -> Vector3:
	return _start_pos.get(team, Vector3.ZERO)


func base_center(team: int) -> Vector3:
	return _keep_pos.get(team, Vector3.ZERO)


func node_of(team: int, suffix: String) -> CrystalNode:
	var roles: Dictionary = _node_role.get(team, {})
	if not roles.has(suffix):
		return null
	var id := StringName(roles[suffix])
	var v: Variant = crystal_nodes.get(id)
	if v == null or not is_instance_valid(v):
		crystal_nodes.erase(id)
		return null
	var n := v as CrystalNode
	return n if n != null and not n.is_depleted() else null


func natural_hall_spot(team: int) -> Vector3:
	var p := _slot(team, "natural_hall")
	if p != Vector3.INF:
		return p
	return _hall_near(team, "mid", 7.6, true)


func rich_hall_spot(team: int) -> Vector3:
	var p := _slot(team, "rich_hall")
	if p != Vector3.INF:
		return p
	return _hall_near(team, "rich", 9.9, false)


func market_slot(team: int) -> Vector3:
	var p := _slot(team, "market")
	return p if p != Vector3.INF else bot_point(team, -MARKET_SLOT)


func tower_slot(team: int, which: StringName) -> Vector3:
	var key := "natural" if which in [&"natural", &"S3"] else ("rich" if which in [&"rich", &"S4"] else "")
	if key == "":
		return Vector3.INF
	var p := _slot(team, "tower_" + key)
	if p != Vector3.INF:
		return p
	var hall := natural_hall_spot(team) if key == "natural" else rich_hall_spot(team)
	var node_pos: Vector3 = _node_spot_pos(team, "mid" if key == "natural" else "rich")
	return MapInfo.clamp_point(node_pos + (node_pos - hall).normalized().rotated(Vector3.UP, PI * 0.5) * 6.0, 4.0) \
			if node_pos != Vector3.INF else bot_point(team, -(TOWER_SLOTS[StringName(key)] as Vector3))


func cache_spots() -> Array[Vector3]:
	var out: Array[Vector3] = []
	var caches := layout.spots_of("cache")
	caches.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["id"]) < String(b["id"]))
	for c in caches:
		out.append(c["pos"])
	return out


## Commander's fixed points (Crown Hollow, Shadow side) on this map for `team`: Crown Hollow's base district moved
## rigidly onto the canonical keep (turned to face the centre the same way), then the seat's frame; clamped 3 m inside.
## Crown Hollow itself: identity (the bot plays exactly as on skirmish.tscn).
func bot_point(team: int, p: Vector3) -> Vector3:
	var fire := -p   # Crown Hollow constants are Shadow-side; the canonical seat is the Fire (south-west) one
	var local := _canon_rot * (fire - CH_KEEP) + _canon_keep
	return MapInfo.clamp_point(_seat_frame(team) * local, 3.0)


## Commander's relative offsets (Crown Hollow, Shadow side: slot shifts, wall offsets) on this map for `team`: the
## turn of `bot_point` without its translation or clamp (review H3), so `bot_point(t, p + v) - bot_point(t, p) ==
## bot_vector(t, v)` away from the map edge. Crown Hollow: `v` for the enemy, `-v` for the player.
func bot_vector(team: int, v: Vector3) -> Vector3:
	return _seat_frame(team).basis * (_canon_rot * -v)


## The epic-beast lairs (Map Lab / World Forge read them here instead of a LAIR_SPOTS constant).
func lair_spots() -> Array[Dictionary]:
	return _lairs


func _node_spot_pos(team: int, role: String) -> Vector3:
	var roles: Dictionary = _node_role.get(team, {})
	if not roles.has(role):
		return Vector3.INF
	var s := layout.spot(String(roles[role]))
	return s["pos"] if not s.is_empty() else Vector3.INF


## A hall spot `dist` m from the team's `role` node, toward its keep (natural) or toward the map centre (rich).
func _hall_near(team: int, role: String, dist: float, toward_keep: bool) -> Vector3:
	var np := _node_spot_pos(team, role)
	if np == Vector3.INF:
		return bot_point(team, -(NATURAL_HALL_SPOT if toward_keep else RICH_HALL_SPOT))
	var goal: Vector3 = _keep_pos.get(team, Vector3.ZERO) if toward_keep else ARTIFACT_POS
	var d := Vector3(goal.x - np.x, 0.0, goal.z - np.z)
	if d.length() < 0.01:
		return np
	return MapInfo.clamp_point(np + d.normalized() * dist, 4.0)


func _objective_text() -> String:
	var line := "Ember Crown: unclaimed"
	if crown and crown.is_sealed():
		line = "Ember Crown: sealed until 6:00"
	elif crown and crown.is_worn():
		line = "Ember Crown: worn by %s" % crown.wearer_name()
	elif crown == null:
		line = ""
	return "Skirmish: %s\nDestroy every %s building. Keep one of yours standing.\n" % [layout.title,
			_kingdom_info(Unit.Team.ENEMY, "name")] + line


func _lane_end() -> Vector3:
	return _start_pos.get(Unit.Team.ENEMY, SHADOW_START)


func _ground_spots() -> Array[Vector4]:
	var out: Array[Vector4] = []
	for team: int in [Unit.Team.PLAYER, Unit.Team.ENEMY]:
		var p: Vector3 = _start_pos.get(team, Vector3.ZERO)
		out.append(Vector4(p.x, p.z, 13.0, 0.0))
	var c := _first("crown")
	if not c.is_empty():
		out.append(Vector4(c["pos"].x, c["pos"].z, PILLAR_RING + 1.5, 1.0))
	return out


## The map's road segments as Vector4(a.x, a.z, b.x, b.z) (ground paint, waystones).
func layout_road_param() -> PackedVector4Array:
	var out := PackedVector4Array()
	for r: Dictionary in layout.roads:
		var poly: PackedVector3Array = r["poly"]
		for i in poly.size() - 1:
			out.append(Vector4(poly[i].x, poly[i].z, poly[i + 1].x, poly[i + 1].z))
	return out


func _build_ground() -> void:
	super()
	if not trade_enabled:
		return
	var mat := _ground_material()
	if mat:
		EnvProps.set_roads(mat, layout_road_param())


func _is_crown_hollow() -> bool:
	return String(layout.id).begins_with("crown_hollow")


## The Crown Hollow edge dressing reads Crown Hollow's constants: only on Crown Hollow layouts.
func _use_map_dressing() -> bool:
	return _is_crown_hollow()


# ---------------------------------------------------------------- the map

func _build_map() -> void:
	# Review M6: the layout's terrain (river, moat, crossings, landmark props) is part of the map the Map Lab approved,
	# so it is built whatever the gameplay switches say; `river_enabled` (missions: false) only turns the ford slow off
	# (the map-fill services have their own switches).
	_add_river()
	if river and not river_enabled:
		river.ford_modifier_enabled = false
	_mapfill_clearings = []
	# blocks: cliffs / walls / ruins as colliders (layer 1) before the bake
	for b: Dictionary in layout.blocks:
		_add_block(b)
	# the forest, in skirmish.gd's order: forest trees, rocks, landmarks (props), groves, willows, pillars
	var t0 := Time.get_ticks_usec()
	forest_plan = MapForest.plan(layout, river)
	forest_plan["usec"] = Time.get_ticks_usec() - t0
	_add_planned_trees("forest")
	for r: Dictionary in forest_plan["rocks"]:
		_add_rock(r["pos"], float(r["s"]), float(r["rot"]))
	_add_landmarks()
	_add_planned_trees("grove")
	_add_planned_trees("willow")
	for pl: Dictionary in forest_plan["pillars"]:
		_add_pillar(pl["pos"], float(pl["h"]))
	# keeps (open seats), nodes, peddlers, taverns, trade, points
	keep = build_grid.spawn_complete(_keep_type(Unit.Team.PLAYER), _keep_pos[Unit.Team.PLAYER], Unit.Team.PLAYER) as Keep
	shadow_keep = build_grid.spawn_complete(_keep_type(Unit.Team.ENEMY), _keep_pos[Unit.Team.ENEMY], Unit.Team.ENEMY) as Keep
	for n: Dictionary in layout.spots_of("node"):
		var role := _role_of(n)
		var amount := int((n.get("props", {}) as Dictionary).get("amount", ROLE_AMOUNTS.get(role, 1500)))
		_add_crystal_node(StringName(n["id"]), n["pos"], amount)
	for p: Dictionary in layout.spots_of("peddler"):
		var peddler := RuinPeddler.new()
		peddler.name = "RuinPeddler%s" % _image_name(p)
		nav_region.add_child(peddler)
		var pp: Vector3 = p["pos"]
		peddler.position = pp
		var face := ARTIFACT_POS - pp
		peddler.rotation.y = atan2(face.x, face.z)   # the counter (local +Z) faces the map centre
		peddlers.append(peddler)
	if tavern_enabled:
		var spots: Array[Vector3] = []
		var tspots := layout.spots_of("tavern")
		for t: Dictionary in tspots:
			spots.append(t["pos"])
		var first := taverns.size()
		_add_taverns(spots)
		# review L2: skirmish.gd names a tavern Fire / Shadow by its half of the map; on a fourfold map that gives two of
		# each (Godot auto-renames the second). The mirror images are named by image, as the peddlers are.
		for k in range(first, mini(taverns.size(), first + tspots.size())):
			var img := String(tspots[k - first].get("image", "identity"))
			if img in ["mirror_x", "mirror_z"] and is_instance_valid(taverns[k]):
				taverns[k].name = "Tavern%s" % _image_name(tspots[k - first])
	if trade_enabled:
		_add_trade_map()
	if points_enabled:
		_add_capture_points()


func _add_planned_trees(stage: String) -> void:
	for t: Dictionary in forest_plan["trees"]:
		if String(t.get("stage", "forest")) != stage:
			continue
		if String(t["kind"]) == "willow":
			_add_willow(t["pos"], float(t["s"]), float(t["yaw"]))
		else:
			_add_tree(t["pos"], float(t["s"]))


static func _image_name(s: Dictionary) -> String:
	return {"identity": "Fire", "rot180": "Shadow", "mirror_x": "East", "mirror_z": "North"}.get(String(s.get("image", "identity")), "")


func _add_block(b: Dictionary) -> void:
	var shape := BoxShape3D.new()
	var hb: Vector3 = b["half"]
	var h := float(b.get("height", 3.0))
	shape.size = Vector3(hb.x * 2.0, h, hb.z * 2.0)
	var body := _static_obstacle(b["center"], shape, h * 0.5)
	body.name = "Block_%s" % String(b["id"]).validate_node_name()
	body.rotation.y = deg_to_rad(float(b.get("yaw", 0.0)))
	body.add_to_group(&"map_blocks")
	body.set_meta(&"kind", String(b.get("kind", "rock")))
	if _SIM.enabled:
		return
	var box := BoxMesh.new()
	box.size = shape.size
	var col: Color = {"cliff": Color(0.42, 0.38, 0.34), "wall": Color(0.55, 0.52, 0.48), "ruin": Color(0.5, 0.48, 0.52),
		"city": Color(0.5, 0.45, 0.4), "forest": Color(0.16, 0.3, 0.15), "ice": Color(0.75, 0.85, 0.92)}.get(String(b.get("kind", "rock")), Color(0.46, 0.44, 0.42))
	_mesh(body, box, col, h * 0.5)


func _add_river() -> void:
	if layout.river.is_empty() and layout.moat.is_empty():
		return
	river = RiverSystem.new()
	river.name = "River"
	river.player_bank_point = _start_pos.get(Unit.Team.PLAYER, PLAYER_START)
	nav_region.add_child(river)
	river.setup(river_lines(layout), river_half_width(layout), moat_of(layout), crossings_of(layout))
	var mat := _ground_material()
	if mat:
		EnvProps.set_river(mat, river.shader_params())
		if _is_crown_hollow() and ResourceLoader.exists(GROUND_PARAMS_PATH):   # the biome tints of Crown Hollow's zones
			var gp: Script = load(GROUND_PARAMS_PATH)
			var names := {}
			if gp:
				for m: Dictionary in gp.get_script_method_list():
					names[String(m.get("name", ""))] = true
			if names.has("skirmish_biomes") and names.has("apply"):
				gp.call(&"apply", mat, gp.call(&"skirmish_biomes"))


## The layout's river arms as RiverSystem polylines (x, z).
static func river_lines(lay: MapLayout) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for arm: Dictionary in lay.river:
		var line := PackedVector2Array()
		for p: Vector3 in (arm["poly"] as PackedVector3Array):
			line.append(Vector2(p.x, p.z))
		out.append(line)
	return out


static func river_half_width(lay: MapLayout) -> float:
	return float(lay.river[0].get("half_width", 2.5)) if not lay.river.is_empty() else 2.5


static func moat_of(lay: MapLayout) -> Vector4:
	if lay.moat.is_empty():
		return Vector4.ZERO
	var c: Vector3 = lay.moat["center"]
	return Vector4(c.x, c.z, float(lay.moat["radius"]), float(lay.moat["half_width"]))


static func crossings_of(lay: MapLayout) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c: Dictionary in lay.crossings:
		var d := c.duplicate()
		d["id"] = StringName(String(c["id"]))
		d["kind"] = StringName(String(c.get("kind", "ford")))
		out.append(d)
	return out


func _map_fill_clearings() -> Array:
	return []


## The layout's props (landmarks): the art scene (its colliders cut the navmesh) or fallback cylinders.
func _add_landmarks() -> void:
	var foam := PackedVector4Array()
	for p: Dictionary in layout.props:
		var path := String(p.get("scene", ""))
		var root: Node3D = null
		if path != "" and ResourceLoader.exists(path):
			var scene := load(path) as PackedScene
			root = scene.instantiate() as Node3D if scene else null
		if root == null:
			root = Node3D.new()
			root.add_to_group(&"landmarks")
			root.set_meta(&"landmark_id", StringName(p["id"]))
			for col: Vector3 in p.get("colliders", []):
				var shape := CylinderShape3D.new()
				shape.radius = col.z
				shape.height = 1.8
				var body := StaticBody3D.new()
				body.collision_layer = 1
				body.collision_mask = 0
				var cs := CollisionShape3D.new()
				cs.shape = shape
				cs.position = Vector3(col.x, 0.9, col.y)
				body.add_child(cs)
				root.add_child(body)
		root.name = String(p["id"]).to_pascal_case()
		nav_region.add_child(root)
		var pos: Vector3 = p["pos"]
		root.position = Vector3(pos.x, 0.0, pos.z)
		root.rotation.y = float(p.get("yaw", 0.0))
		landmarks.append(root)
		var circles: Variant = root.get_meta(&"foam_rocks") if root.has_meta(&"foam_rocks") else null
		if circles is PackedVector3Array:
			var take := 1 if String(p["id"]).begins_with("lm_aqueduct") else (circles as PackedVector3Array).size()
			for k in mini(take, (circles as PackedVector3Array).size()):
				var c: Vector3 = (circles as PackedVector3Array)[k]
				var w := root.transform * Vector3(c.x, 0.0, c.y)
				foam.append(Vector4(w.x, w.z, c.z, 0.0))
	if river and not foam.is_empty():
		river.add_foam_rocks(foam)


## Capture points: the layout's `point` spots ({id, name, kind, pos}).
func point_spots() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var n := {}
	for s: Dictionary in layout.spots_of("point"):
		var kind := MapForest.point_kind(s)
		n[kind] = int(n.get(kind, 0)) + 1
		var props: Dictionary = s.get("props", {})
		out.append({"id": StringName(s["id"]), "name": String(props.get("name", "%s %d" % [POINT_NAMES.get(kind, "Point"), n[kind]])),
			"kind": StringName(kind), "pos": s["pos"]})
	return out


func camp_spots() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s: Dictionary in layout.spots_of("camp"):
		var props: Dictionary = s.get("props", {})
		var info: Array = _camp_info(s)
		out.append({"id": StringName(s["id"]), "name": String(props.get("name", info[3])), "kind": StringName(props.get("kind", info[0])),
			"tier": int(props.get("tier", info[1])), "pos": s["pos"], "first_spawn": float(props.get("first", info[2]))})
	return out


static func _camp_info(s: Dictionary) -> Array:
	var sub := String(s.get("sub", ""))
	var base := String(s.get("twin_of", s["id"]))
	for k: String in CAMP_KINDS:
		if sub == String(CAMP_KINDS[k][0]) or sub == k or base.contains(k):
			return CAMP_KINDS[k]
	return CAMP_KINDS["wallow"]


func _build_lairs() -> void:
	_lairs.clear()
	for s: Dictionary in layout.spots_of("lair"):
		var sub := String(s.get("sub", ""))
		var base := String(s.get("twin_of", s["id"]))
		var info: Array = LAIR_KINDS["heath"]
		for k: String in LAIR_KINDS:
			if sub == String(LAIR_KINDS[k][0]) or sub == k or base.contains(k):
				info = LAIR_KINDS[k]
				break
		var c: Vector3 = s["pos"]
		var r := float(info[1])
		var patrol: Array[Vector3] = []
		for i in 4:
			var a := TAU * float(i) / 4.0 + 0.4
			patrol.append(MapInfo.clamp_point(c + Vector3(cos(a), 0.0, sin(a)) * r, 2.0))
		_lairs.append({"id": StringName(s["id"]), "name": String(info[4]), "kind": info[0], "center": c, "radius": r,
			"patrol": patrol, "first_spawn": float(info[2]), "respawn": float(info[3])})


func _add_capture_points() -> void:
	capture_points = _add_mapfill_service(CAPTURE_POINTS_PATH, "CapturePoints", &"capture_points_service")
	if capture_points == null:
		return
	if capture_points.has_method(&"setup"):
		capture_points.call(&"setup", point_spots())
	if capture_points.has_signal(&"blessing_started"):
		capture_points.connect(&"blessing_started", _on_blessing_started)


func _setup_map_fill() -> void:
	_build_lairs()
	if camps_enabled and _service(camp_manager) == null:
		camp_manager = _add_mapfill_service(CAMP_MANAGER_PATH, "CampManager", &"camp_manager")
		if camp_manager and camp_manager.has_method(&"setup"):
			camp_manager.call(&"setup", camp_spots())
	if beasts_enabled and _service(epic_beasts) == null and not _lairs.is_empty():
		epic_beasts = _add_mapfill_service(EPIC_BEASTS_PATH, "EpicBeasts", &"epic_beasts")
		if epic_beasts and epic_beasts.has_method(&"setup"):
			epic_beasts.call(&"setup", _lairs)
	var herds := _herds()
	if beasts_enabled and _service(critter_herds) == null and (not herds[0].is_empty() or not herds[1].is_empty()):
		critter_herds = _add_mapfill_service(CRITTER_HERDS_PATH, "CritterHerds", &"critter_herds")
		if critter_herds and critter_herds.has_method(&"setup"):
			critter_herds.call(&"setup", herds[0], herds[1])
	var cm := _service(camp_manager)
	if cm and not cm.has_method(&"cleared_count") and cm.has_signal(&"camp_cleared"):
		cm.connect(&"camp_cleared", _on_camp_cleared)
	var reveal: Array[Vector3] = []
	if _service(capture_points):
		for spot: Dictionary in point_spots():
			reveal.append(spot["pos"])
	for lm in landmarks:
		if is_instance_valid(lm):
			reveal.append(lm.global_position)
	for p in reveal:
		for team: int in [Unit.Team.PLAYER, Unit.Team.ENEMY]:
			fog.reveal(team, p, MAPFILL_REVEAL)
	for s: Node in [_service(capture_points), cm, _service(epic_beasts), _service(critter_herds)]:
		if s and s.has_signal(&"message") and not s.is_connected(&"message", _on_guild_message):
			s.connect(&"message", _on_guild_message)


## [herds, rabbit homes] from `slot sub=graze` (one herd per symmetry image) and `slot sub=rabbit`.
func _herds() -> Array:
	var by_img := {}
	var rabbits: Array[Vector3] = []
	for s: Dictionary in layout.spots_of("slot"):
		match String(s.get("sub", "")):
			"graze":
				var img := String(s.get("image", "identity"))
				if not by_img.has(img):
					by_img[img] = []
				(by_img[img] as Array).append(s["pos"])
			"rabbit":
				rabbits.append(s["pos"])
	var herds: Array[Dictionary] = []
	for img: String in by_img:
		herds.append({"id": StringName("herd_" + img), "name": "%s herd" % img.capitalize(), "count": 3, "respawn": 120.0,
			"spots": by_img[img]})
	return [herds, rabbits]


# ---------------------------------------------------------------- trade (roads, posts, guild houses)

func _add_trade_map() -> void:
	var posts := layout.spots_of("post")
	for i in posts.size():
		var s: Dictionary = posts[i]
		var post := TradePost.new()
		post.post_id = StringName(s["id"])
		post.display_name = String((s.get("props", {}) as Dictionary).get("name", String(s["id"]).capitalize()))
		post.sign_index = int((s.get("props", {}) as Dictionary).get("sign", i % 4))
		post.name = "TradePost_%s" % String(s["id"]).to_pascal_case()
		_place_facing(post, s["pos"], _door_of(s))
		trade_posts.append(post)
	for s: Dictionary in layout.spots_of("guild"):
		var house := GuildHouse.new()
		var base := String(s.get("twin_of", s["id"])).to_lower()
		var den := String(s.get("sub", "")) == "den" or base.contains("den") or base.contains("magpie")
		house.kind = GuildHouse.DEN if den else GuildHouse.LODGE
		var gp: Vector3 = s["pos"]
		var where := ("NorthWest" if gp.x < 0.0 else "SouthEast") if layout.symmetry == "rot180" else _image_name(s)
		house.name = "%s%s" % ["MagpieDen" if den else "GreywaterLodge", where]
		_place_facing(house, s["pos"], _door_of(s))
		guild_houses.append(house)
	var graph := road_graph()
	trade_network = TradeNetwork.new()
	trade_network.name = "TradeNetwork"
	trade_network.match_time_source = match_time
	trade_network.base_positions = {Unit.Team.PLAYER: base_center(Unit.Team.PLAYER),
			Unit.Team.ENEMY: base_center(Unit.Team.ENEMY)}
	add_child(trade_network)
	trade_network.setup(trade_posts, graph["nodes"], graph["segments"], {&"road": _slot_dict("ambush", graph), &"worker": _slot_dict("worker_spot", {})})
	trade_network.posts_opened.connect(_on_posts_opened)
	_add_layout_waystones()


## The road graph of the layout: {nodes: {id: Vector3}, segments: [[a, b]]}; vertices within 0.5 m merge; the vertex
## nearest each playing start (within 12 m) is a hub ("hub_t<team>").
func road_graph() -> Dictionary:
	var nodes := {}
	var segments: Array = []
	var ids: Array[StringName] = []
	var pts: Array[Vector3] = []
	for r: Dictionary in layout.roads:
		var poly: PackedVector3Array = r["poly"]
		var prev := &""
		for i in poly.size():
			var p := Vector3(poly[i].x, 0.0, poly[i].z)
			var id := &""
			for k in pts.size():
				if pts[k].distance_to(p) < 0.5:
					id = ids[k]
					break
			if id == &"":
				id = StringName("%s_%d" % [String(r["id"]), i])
				ids.append(id)
				pts.append(p)
			if prev != &"" and prev != id:
				segments.append([prev, id])
			prev = id
	# hubs
	var rename := {}
	for team: int in [Unit.Team.PLAYER, Unit.Team.ENEMY]:
		var st: Vector3 = _start_pos.get(team, Vector3.INF)
		var best := -1
		var bd := 12.0
		for k in pts.size():
			var d := pts[k].distance_to(st)
			if d < bd:
				bd = d
				best = k
		if best >= 0:
			rename[ids[best]] = StringName("hub_t%d" % team)
	for k in pts.size():
		var id: StringName = rename.get(ids[k], ids[k])
		nodes[id] = pts[k]
	var segs: Array = []
	for s: Array in segments:
		segs.append([rename.get(s[0], s[0]), rename.get(s[1], s[1])])
	return {"nodes": nodes, "segments": segs}


## {id: Vector3} of `slot sub=<sub>` spots; ambush spots default to the road nodes' midpoints of long segments.
func _slot_dict(sub: String, graph: Dictionary) -> Dictionary:
	var out := {}
	for s: Dictionary in layout.spots_of("slot"):
		if String(s.get("sub", "")) == sub:
			out[StringName(s["id"])] = s["pos"]
	if out.is_empty() and sub == "ambush" and graph.has("segments"):
		var k := 0
		for seg: Array in graph["segments"]:
			var a: Vector3 = graph["nodes"][seg[0]]
			var b: Vector3 = graph["nodes"][seg[1]]
			if a.distance_to(b) >= 30.0:
				out[StringName("A%d" % k)] = a.lerp(b, 0.5)
				k += 1
	return out


## A post / guild house's door: `door=` on the spot, else the nearest road point (posts) or 4 m toward it (guilds).
func _door_of(s: Dictionary) -> Vector3:
	var props: Dictionary = s.get("props", {})
	if props.get("door") is Vector3:
		return props["door"]
	var c: Vector3 = s["pos"]
	var best := Vector3.INF
	var bd := INF
	var q := Vector2(c.x, c.z)
	for r: Dictionary in layout.roads:
		var poly: PackedVector3Array = r["poly"]
		for i in poly.size() - 1:
			var cp := Geometry2D.get_closest_point_to_segment(q, Vector2(poly[i].x, poly[i].z), Vector2(poly[i + 1].x, poly[i + 1].z))
			if cp.distance_to(q) < bd:
				bd = cp.distance_to(q)
				best = Vector3(cp.x, 0.0, cp.y)
	if best == Vector3.INF or bd < 0.5:
		var to_c := ARTIFACT_POS - c
		return c + (to_c.normalized() if to_c.length() > 0.1 else Vector3.FORWARD) * 4.0
	return c + (best - c).normalized() * minf(4.0, bd)


func _add_layout_waystones() -> void:
	const WAYSTONE_ROW_PATH := "res://art/environment/meshes/waystone_row.gd"
	if not ResourceLoader.exists(WAYSTONE_ROW_PATH):
		return
	var clear := PackedVector3Array([base_center(Unit.Team.PLAYER), base_center(Unit.Team.ENEMY)])
	var radii := PackedFloat32Array([14.0, 14.0])
	for kind: String in ["post", "guild"]:
		for s: Dictionary in layout.spots_of(kind):
			clear.append(s["pos"])
			radii.append(7.0)
	if river:
		for c: Dictionary in river.crossings():
			if c["kind"] == RiverSystem.KIND_BRIDGE_ROAD:
				clear.append(c["center"])
				radii.append(WAYSTONE_BRIDGE_GAP)
	var row: Script = load(WAYSTONE_ROW_PATH)
	var stones: Variant = row.call(&"build", layout_road_param(), 10.0, 2.2, 5.0, clear, radii, 6.0)
	if stones is Node3D:
		add_child(stones)


# ---------------------------------------------------------------- start

func _on_navigation_ready() -> void:
	var p_start: Vector3 = _start_pos[Unit.Team.PLAYER]
	var e_start: Vector3 = _start_pos[Unit.Team.ENEMY]
	fog.reveal(Unit.Team.ENEMY, e_start, FogOfWar.START_REVEAL)
	hero = _make_wizard(Unit.Team.PLAYER)
	_spawn(hero, Unit.Team.PLAYER, p_start)
	_claim_wizard(hero, Unit.Team.PLAYER)
	shadow_hero = _make_wizard(Unit.Team.ENEMY)
	_spawn(shadow_hero, Unit.Team.ENEMY, e_start)
	_claim_wizard(shadow_hero, Unit.Team.ENEMY)
	var workers := {}
	for team: int in [Unit.Team.PLAYER, Unit.Team.ENEMY]:
		workers[team] = _worker_type_for(kingdom_of(team), _keep_type(team))
	for i in 3:
		var offset := Vector3(-4.0 + i * 1.2, 0.0, 4.0 - i * 1.2)   # Crown Hollow's, turned onto each seat
		var suffix := "a" if i < 2 else "b"
		for team: int in [Unit.Team.PLAYER, Unit.Team.ENEMY]:
			var start: Vector3 = _start_pos[team]
			var w := _spawn(Worker.make_unit(workers[team]), team, start + _seat_frame(team).basis * (_canon_rot * offset))
			var node := node_of(team, suffix)
			if node:
				w.call(&"command_gather", node)
	if not _first("crown").is_empty():
		_spawn_wardens()
		crown = EmberCrown.new()
		crown.name = "EmberCrown"
		crown.match_time_source = match_time
		add_child(crown)
		crown.global_position = ARTIFACT_POS
		artifact = crown
		crown.claimed.connect(_on_crown_claimed)
		crown.dropped.connect(_on_crown_dropped)
		crown.seal_refused.connect(_on_crown_seal_refused)
		crown.stirring.connect(_on_crown_stirring)
		crown.unsealed.connect(_on_crown_unsealed)
	for wiz: Wizard in [hero, shadow_hero]:
		wiz.died.connect(_on_wizard_died)
		ItemDrops.ensure_inventory(wiz)
	_spawn_caches()
	_setup_map_fill()
	if tavern_enabled:
		_setup_champions()
	if trade_enabled:
		_setup_trade()
	_setup_hud()
	hud.set_objective(_objective_text())
	if _layout_error != "":
		# review M2: no bogus match on an empty map: the HUD says why and the match never starts
		hud.show_message(_layout_error, 3600.0)
		return
	hud.show_message(SKIRMISH_HINT % _barracks_name(Unit.Team.PLAYER), 10.0)
	_start_match()
