class_name MapDressingArt
extends Node3D
## Map dressing for the 120 x 120 maps (task A.10, biome scatter 12.V6), scene art/environment/map_dressing.tscn:
## - Cliffs + Plateau + BorderForest + CrestRocks (static, built by build_env.gd): the map sits in a hollow ringed
##   by rock cliffs (tall at the north / west, low at the south so they never hide units), with a forest on the
##   plateau above and a painted canopy fading into haze. Everything is outside the playable square (|x|, |z| > 60).
## - Biome decor (12.V6, runtime, node "Biomes"): each biome set of art/environment/biomes/<id>/<id>_set.gd scattered
##   where the ground paints that biome (BiomeMap = the CPU mirror of ground.gdshader's analytic zones: ruins >
##   riverbank > Hearth Meadow > Old Wood > heath > Wildflower Glade, 4 m blends), plus the undergrowth round trees /
##   rocks and the MAP.P1 cliff-foot clumps, both drawn with the local biome's kinds (never glade tufts on the heath).
##   River aware: no decor in deep water or on crossings; riverbank `bank` items on the 0-2.5 m band, `water` items
##   on the surface (`y`, within `shore` of the edge). One MultiMesh per kind and 40 m chunk (3 x 3), sparse kinds
##   in one MultiMesh; visibility ranges from the sets (+ the chunk's half diagonal, measured from the chunk centre);
##   materials stay on the mesh surfaces (no override: the variant collapse and contact discs keep working).
##   Map detail Low (GameSettings.map_detail, or `map_detail_override`) halves every count.
## - Legacy decor ("Decor": grass clumps, flower patches, undergrowth, edge strip with the art/environment/meshes
##   decor_* kinds) only when no biome set exists.
## No colliders, no navmesh effect, no gameplay logic; it only draws.
##
## How the level plugs it in (main.gd `_ready`, right after `env_props.commit()`):
##     if ResourceLoader.exists(MapDressingArt.SCENE_PATH):
##         add_child(load(MapDressingArt.SCENE_PATH).instantiate())
## It then reads the map by itself (deferred, once): the lane, spots, trade roads, river cut and biome zones from the
## painted ground material, the trees / rocks / pillars from EnvProps, crystal nodes, buildings, taverns, trade posts,
## guild houses, capture points, landmarks (`decor_clear_radius`), the river's crossings and the level's spot
## constants (PEDDLER_SPOTS, CACHE_SPOTS, slots, POINT_SPOTS, CAMP_SPOTS, LAIR_SPOTS). Construction sites, camp sites
## and lairs added later clear the decor under them automatically.
## Public: `clear_area(center: Vector3, radius: float)`, `decor_count() -> int`, `biome_counts() -> Dictionary`,
## `kind_paths() -> PackedStringArray`, `instance_positions(kind_path := "") -> PackedVector3Array` and
## `instance_transforms(kind_path) -> Array[Transform3D]` (CPU copies, work headless), `biome_map() -> RefCounted`
## (BiomeMap), `populate_msec() -> float`, static `map_detail() -> StringName`.

const SCENE_PATH := "res://art/environment/map_dressing.tscn"
const MESH_DIR := "res://art/environment/meshes/"
const GROUND_SHADER := "res://art/environment/ground.gdshader"
const BIOME_MAP := preload("res://art/environment/biomes/biome_map.gd")
const GAME_SETTINGS_PATH := "res://scripts/ui/menus/game_settings.gd"
const MAP_HALF := 60.0
const CHUNK := 40.0
const CHUNKS := 3
const LANE_CLEAR := 5.2                 ## Decor-free half width around the lane line (the dirt meanders +-2.4 m).
const LOW_DETAIL := 0.5                 ## Map detail Low: this fraction of every count.
## Kinds with fewer instances than this on the map get ONE MultiMesh (no chunks, no range): sparse kinds, whose
## chunks would hold a handful each (keeps MapDressing under the 140 draw nodes of test_map_p1 / test_12_v5).
const SPARSE_KIND := 64
const PATCH_SPREAD := 1.2               ## Gaussian sigma (m) of a patch (x2 for kinds with a `gap`).
const WATER_SPREAD := 0.7               ## Sigma of the `bank` / `water` patches (narrow bands).
const MAX_MARGIN := 1.6                 ## Clearance cap of the big (`gap`) kinds from objects, roads and slots.
const BIG_GAP := 2.5                    ## Kinds with at least this `gap` retry a blocked spot nearby...
const BIG_RETRIES := 4                  ## ...this many times in all.
const PATCH_SIZES := {&"riverbank": 5, &"ruins": 6}   ## Instances per patch (default 8, the sets' "~8").
## Mesh-kind budget (map-fill.md 9: <= 24 decor kinds). The six sets ship 28; the four least visible at game zoom
## are folded away (their density moves to a look-alike, or they are dropped). Empty both to get all 28 back.
const B := "res://art/environment/biomes/"
const KIND_MERGE := {
	B + "meadow/meadow_clover.res": B + "meadow/meadow_tufts.res",          # dark flat mats: invisible from 30 m
	B + "meadow/meadow_dandelions.res": B + "meadow/meadow_daisies.res",    # a second flower speck
}
const KIND_DROP: Array[String] = [
	B + "old_wood/ow_cobwebs.res",     # pale cards, unreadable at 40 m, the only transparent decor pass
	B + "old_wood/ow_roots.res",       # low dark roots, lost on the dark forest floor at 40 m
]
## Undergrowth / cliff-foot roles -> the kind each biome uses for it ("" = none there).
const ROLE_KINDS := {
	&"glade": {&"grass": B + "glade/glade_tall_grass.res", &"fern": B + "glade/glade_tall_grass.res",
		&"bush": B + "glade/glade_butterfly_bush.res", &"small": B + "glade/glade_flowers.res",
		&"stones": B + "heath/heath_lichen_stones.res", &"log": ""},
	&"meadow": {&"grass": B + "meadow/meadow_tufts.res", &"fern": B + "meadow/meadow_tufts.res",
		&"bush": B + "meadow/meadow_fruit_bush.res", &"small": B + "meadow/meadow_daisies.res",
		&"stones": B + "heath/heath_lichen_stones.res", &"log": ""},
	&"heath": {&"grass": B + "heath/heath_tall_grass.res", &"fern": B + "heath/heath_heather.res",
		&"bush": B + "heath/heath_gorse.res", &"small": B + "heath/heath_heather.res",
		&"stones": B + "heath/heath_lichen_stones.res", &"log": ""},
	&"old_wood": {&"grass": B + "old_wood/ow_ferns.res", &"fern": B + "old_wood/ow_ferns.res",
		&"bush": B + "old_wood/ow_ferns.res", &"small": B + "old_wood/ow_glowcaps.res",
		&"stones": B + "old_wood/ow_moss_boulders.res", &"log": B + "old_wood/ow_fallen_trunk.res"},
	&"riverbank": {&"grass": B + "riverbank/rb_reeds.res", &"fern": B + "riverbank/rb_cattails.res",
		&"bush": B + "riverbank/rb_reeds.res", &"small": B + "riverbank/rb_reeds.res",
		&"stones": B + "riverbank/rb_river_stones.res", &"log": B + "riverbank/rb_driftwood.res"},
	&"ruins": {&"grass": B + "ruins/ruins_ember_moss.res", &"fern": B + "ruins/ruins_ember_moss.res",
		&"bush": B + "ruins/ruins_drums.res", &"small": B + "ruins/ruins_ember_moss.res",
		&"stones": B + "ruins/ruins_flagstones.res", &"log": B + "ruins/ruins_drums.res"},
}
const AVOID_CELL := 4.0                 ## Spatial hash cell for the decor-free circles.
const AVOID_PAD := 4.0                  ## Largest margin a query adds (circles are hashed with it).
const ISLE_DAIS_CLEAR := 3.8            ## ruins_set.gd: the crown dais round a kind-1 paving centre.
const PILLAR_CLEAR := 1.2               ## ruins_set.gd: round each crown pillar.
const CAMP_CLEAR := 4.7                 ## Camp sites without a scene: the largest decor_clear_radius of 12.V24.
const CAMP_SITE := "res://art/environment/camps/%s_site.tscn"
const LAIR_ART := "res://art/environment/lairs/lair_art.gd"
const EPIC_BEASTS := "res://scripts/world/epic_beasts.gd"
# Legacy decor (no biome set).
const SHADOW_MESHES: Array[String] = ["decor_bush", "decor_bush_berry", "decor_fern", "decor_log", "decor_stump"]
const FLOWERS: Array[String] = ["decor_flowers_w", "decor_flowers_y", "decor_flowers_p"]

## Tests / tools: &"low" or &"high" here beats the settings store (empty = read GameSettings.map_detail).
static var map_detail_override: StringName = &""

@export var decor_enabled := true
@export var biomes_enabled := true     ## False = the legacy decor even when the biome sets exist.
@export var all_kinds := false         ## True = ignore KIND_MERGE / KIND_DROP (all 28 kinds; for measuring).
## Global multiplier of every biome / undergrowth / cliff-foot count (x0.5 more on Map detail Low). The one knob if
## the decor must get cheaper (its GPU cost scales with the instances on screen, see the 12.V6 report).
@export_range(0.0, 2.0, 0.05) var density_scale := 1.0
@export var grass_clumps := 1500       ## Legacy field.
@export var flower_patches := 42       ## Legacy field.
@export var random_seed := 11
## Border forest + crest rocks, written by build_env.gd: [mesh name, node name, PackedFloat32Array of
## transforms (12 floats each), casts shadows]. Built into MultiMeshes under BorderForest in _ready.
@export var border_sets: Array = []

var _rng := RandomNumberGenerator.new()
var _lane_a := Vector2(-36.0, 36.0)
var _lane_b := Vector2(36.0, -36.0)
var _has_lane := false
var _spots: Array[Vector4] = []
var _roads: Array[Vector4] = []        # trade road segments (x0, z0, x1, z1) from the ground's road_segs (10.V10)
var _road_clear := 2.3                 # decor-free half width around a road centre line
var _avoid: Array[Vector3] = []        # Vector3(x, z, radius)
var _avoid_grid := {}                  # Vector2i -> Array[Vector3]
var _crossing_circles: Array[Vector3] = []   # fords / Crown Steps (x, z, r)
var _crossing_rects: Array[Dictionary] = []  # bridges {c: Vector2, u: Vector2 (along), hl: half length, hw: half width}
var _trees: Array[Transform3D] = []
var _rocks: Array[Transform3D] = []
var _bm: BIOME_MAP                     # the ground's zones + river cut
var _items: Array[Dictionary] = []     # every biome item to scatter (merged / dropped kinds applied)
var _kinds := {}                       # mesh path -> {mesh, shadow, vis_end, scale, gap, yaw, yaw_jitter, y, biome}
var _gap_grids := {}                   # mesh path -> {Vector2i: PackedVector2Array}
var _big_grid := {}                    # Vector2i -> Array[Vector3] (x, z, gap) of every gap item (cross-kind spacing)
var _lists := {}                       # "cx:cz|path" -> Array[Transform3D] (while building)
var _list_biome := {}                  # same key -> Array[StringName] (biome per instance, for the counts)
var _chunks := {}                      # key -> {"mm": MultiMesh, "pos": PackedVector3Array, "path": String}
var _biome_counts := {}
var _count := 0
var _detail := 1.0
var _populated := false
var _populate_ms := 0.0
var _timings := {}
var _legacy := false


func _ready() -> void:
	_rng.seed = random_seed
	_build_border()
	get_tree().node_added.connect(_on_node_added)
	_populate.call_deferred()


## Hides every decor instance within `radius` of `center` (world x/z). Cheap; call it for new buildings.
func clear_area(center: Vector3, radius: float) -> void:
	var r2: float = radius * radius
	for key: String in _chunks:
		var entry: Dictionary = _chunks[key]
		var mm: MultiMesh = entry["mm"]
		var pos: PackedVector3Array = entry["pos"]
		for i: int in pos.size():
			var d := Vector2(pos[i].x - center.x, pos[i].z - center.z)
			if d.length_squared() < r2 and pos[i].y > -10.0:
				mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(0.001, 0.001, 0.001)),
					Vector3(pos[i].x, -20.0, pos[i].z)))
				pos[i].y = -20.0
		entry["pos"] = pos


## Decor instances placed (0 until the deferred populate ran).
func decor_count() -> int:
	return _count


## Instances placed per biome id (&"ruins", &"riverbank", &"meadow", &"old_wood", &"heath", &"glade"; legacy: &"legacy").
func biome_counts() -> Dictionary:
	return _biome_counts.duplicate()


## The distinct decor mesh paths drawn (legacy kinds: their mesh path too).
func kind_paths() -> PackedStringArray:
	var seen := {}
	for key: String in _chunks:
		seen[String(_chunks[key]["path"])] = true
	return PackedStringArray(seen.keys())


## World positions of the decor instances still shown (one kind by mesh path, or all). CPU-side: works headless.
func instance_positions(kind_path: String = "") -> PackedVector3Array:
	var out := PackedVector3Array()
	for key: String in _chunks:
		if kind_path != "" and String(_chunks[key]["path"]) != kind_path:
			continue
		for p: Vector3 in (_chunks[key]["pos"] as PackedVector3Array):
			if p.y > -10.0:
				out.append(p)
	return out


## Transforms of the decor instances still shown for one kind (mesh path). CPU-side: works headless.
func instance_transforms(kind_path: String) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	for key: String in _chunks:
		if String(_chunks[key]["path"]) != kind_path:
			continue
		var pos: PackedVector3Array = _chunks[key]["pos"]
		var xfs: Array = _chunks[key]["xf"]
		for i: int in pos.size():
			if pos[i].y > -10.0:
				out.append(xfs[i])
	return out


## The BiomeMap built from the ground (null before the populate).
func biome_map() -> RefCounted:
	return _bm


## Milliseconds the populate (read + scatter + MultiMeshes) took.
func populate_msec() -> float:
	return _populate_ms


## The populate's phases: {read_ms, scatter_ms, commit_ms}.
func populate_timings() -> Dictionary:
	return _timings.duplicate()


## The Map detail the next populate uses: map_detail_override, else GameSettings.map_detail (load-guarded), else high.
static func map_detail() -> StringName:
	if map_detail_override != &"":
		return map_detail_override
	if not ResourceLoader.exists(GAME_SETTINGS_PATH):
		return &"high"
	var gs := load(GAME_SETTINGS_PATH) as Script
	if gs == null:
		return &"high"
	if gs.has_method(&"ensure_read"):
		gs.call(&"ensure_read")
	var v: Variant = gs.get(&"map_detail")
	if v == null:
		return &"high"
	return StringName(str(v))


# ---------------------------------------------------------------- reading the map

func _build_border() -> void:
	var parent: Node3D = get_node_or_null(^"BorderForest") as Node3D
	if parent == null:
		parent = self
	for s: Array in border_sets:
		var mesh := load(MESH_DIR + String(s[0]) + ".res") as Mesh
		var data: PackedFloat32Array = s[2]
		var n: int = int(data.size() / 12.0)
		if mesh == null or n == 0:
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = n
		for i: int in n:
			var o: int = i * 12
			mm.set_instance_transform(i, Transform3D(Vector3(data[o], data[o + 1], data[o + 2]),
				Vector3(data[o + 3], data[o + 4], data[o + 5]), Vector3(data[o + 6], data[o + 7], data[o + 8]),
				Vector3(data[o + 9], data[o + 10], data[o + 11])))
		var mmi := MultiMeshInstance3D.new()
		mmi.name = String(s[1])
		mmi.multimesh = mm
		mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		if not bool(s[3]):
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mmi)


func _read_map() -> void:
	var level: Node = get_parent()
	var ground: ShaderMaterial = null
	# Lane + spots + roads + river + biomes from the painted ground (EnvProps.ground_material).
	for mi: Node in level.find_children("*", "MeshInstance3D", true, false):
		var sm := (mi as MeshInstance3D).material_override as ShaderMaterial
		if sm and sm.shader and sm.shader.resource_path == GROUND_SHADER and (mi as MeshInstance3D).mesh is PlaneMesh:
			var la: Variant = sm.get_shader_parameter(&"lane_a")
			var lb: Variant = sm.get_shader_parameter(&"lane_b")
			if la is Vector2 and lb is Vector2:
				_lane_a = la
				_lane_b = lb
				_has_lane = true
			for i: int in 4:
				var s: Variant = sm.get_shader_parameter(StringName("spot_%d" % i))
				if s is Vector4 and (s as Vector4).z > 0.0:
					_spots.append(s)
			_read_roads(sm)
			ground = sm
			break
	_bm = BIOME_MAP.from_ground(ground)
	# Trees / rocks / pillars drawn by EnvProps.
	var env: Node = level.get(&"env_props") if &"env_props" in level else null
	if env:
		for c: Node in env.get_children():
			var mmi := c as MultiMeshInstance3D
			if mmi == null or mmi.multimesh == null:
				continue
			var nm: String = String(mmi.name)
			for i: int in mmi.multimesh.instance_count:
				var xf: Transform3D = mmi.multimesh.get_instance_transform(i)
				if nm.begins_with("Tree"):
					_trees.append(xf)
					_avoid.append(Vector3(xf.origin.x, xf.origin.z, 0.5 * xf.basis.get_scale().x))
				elif nm.begins_with("Rock"):
					_rocks.append(xf)
					_avoid.append(Vector3(xf.origin.x, xf.origin.z, 0.8 * xf.basis.get_scale().x))
				else:
					_avoid.append(Vector3(xf.origin.x, xf.origin.z, PILLAR_CLEAR))
	for n: Node in get_tree().get_nodes_in_group(&"crystal_nodes"):
		if n is Node3D:
			var p: Vector3 = (n as Node3D).global_position
			_avoid.append(Vector3(p.x, p.z, 2.3))
	for b: Node in get_tree().get_nodes_in_group(&"buildings"):
		if b is Node3D:
			var pb: Vector3 = (b as Node3D).global_position
			_avoid.append(Vector3(pb.x, pb.z, _building_radius(b)))
	# Neutral sites with a footprint (taverns, trade posts, guild houses, capture points).
	for grp: StringName in [&"taverns", &"trade_posts", &"guilds", &"capture_points"]:
		for n2: Node in get_tree().get_nodes_in_group(grp):
			if n2 is Node3D:
				var p2: Vector3 = (n2 as Node3D).global_position
				var r2 := 3.5
				if n2.has_method(&"footprint_rect"):
					var rect: Rect2 = n2.call(&"footprint_rect")
					r2 = maxf(rect.size.x, rect.size.y) * 0.5 + 0.8
				_avoid.append(Vector3(p2.x, p2.z, r2))
	# Landmarks, lairs, camp sites: their own decor-free radius / circles.
	for n3: Node in level.find_children("*", "Node3D", true, false):
		_add_clear_of(n3)
	# The river's crossings (bridge decks, fords, Crown Steps).
	var crossings: Array = []
	var river: Node = get_tree().get_first_node_in_group(&"river")
	if river and river.has_method(&"crossings"):
		crossings = river.call(&"crossings")
	var script: Script = level.get_script() as Script
	var consts: Dictionary = script.get_script_constant_map() if script else {}
	if crossings.is_empty() and river != null and consts.has("CROSSINGS"):
		crossings = consts["CROSSINGS"]
	for c: Variant in crossings:
		if c is Dictionary:
			_add_crossing(c)
	# The level's item / build spots (skirmish), mirrored for the other side.
	for key: String in ["PEDDLER_SPOTS", "CACHE_SPOTS"]:
		if consts.has(key):
			for p2: Variant in consts[key]:
				if p2 is Vector3:
					_avoid.append(Vector3((p2 as Vector3).x, (p2 as Vector3).z, 3.6 if key == "PEDDLER_SPOTS" else 2.0))
	for key2: String in ["HOUSE_SLOT", "RICH_HALL_SPOT", "NATURAL_HALL_SPOT", "MARKET_SLOT"]:
		if consts.has(key2) and consts[key2] is Vector3:
			var p3: Vector3 = consts[key2]
			_avoid.append(Vector3(p3.x, p3.z, 4.2))
			_avoid.append(Vector3(-p3.x, -p3.z, 4.2))
	if consts.has("TOWER_SLOTS") and consts["TOWER_SLOTS"] is Dictionary:
		for p4: Variant in (consts["TOWER_SLOTS"] as Dictionary).values():
			if p4 is Vector3:
				_avoid.append(Vector3((p4 as Vector3).x, (p4 as Vector3).z, 3.0))
				_avoid.append(Vector3(-(p4 as Vector3).x, -(p4 as Vector3).z, 3.0))
	# Map-fill spots (only when the level turned that system on).
	if consts.has("POINT_SPOTS") and level.get(&"points_enabled") == true:
		var clearing: Dictionary = consts.get("POINT_CLEARING", {})
		for spot: Variant in consts["POINT_SPOTS"]:
			var ps: Vector3 = (spot as Dictionary)["pos"]
			_avoid.append(Vector3(ps.x, ps.z, float(clearing.get((spot as Dictionary)["kind"], 3.5))))
	if consts.has("CAMP_SPOTS") and level.get(&"camps_enabled") == true:
		for spot2: Variant in consts["CAMP_SPOTS"]:
			var cs: Vector3 = (spot2 as Dictionary)["pos"]
			var site: String = CAMP_SITE % String((spot2 as Dictionary).get("kind", ""))
			_avoid.append(Vector3(cs.x, cs.z, float(_scene_root_meta(site, "decor_clear_radius", CAMP_CLEAR)) + 0.2))
	if level.get(&"beasts_enabled") == true:
		_add_lairs(consts)
	# The crown dais on the kind-1 paving (the Crown Isle).
	for s2: Vector4 in _spots:
		if s2.w > 0.5:
			_avoid.append(Vector3(s2.x, s2.y, ISLE_DAIS_CLEAR))
	_hash_avoid()


## The epic-beast lairs (the level's LAIR_SPOTS, else EpicBeasts.default_lairs()): the decor-free circles of each
## lair scene (LairArt metadata `decor_clear`, local, turned by LairArt.yaw_for), else 0.6 x the lair radius.
func _add_lairs(consts: Dictionary) -> void:
	var lairs: Array = consts.get("LAIR_SPOTS", [])
	if lairs.is_empty() and ResourceLoader.exists(EPIC_BEASTS):
		var eb := load(EPIC_BEASTS) as Script
		if eb and eb.has_method(&"default_lairs"):
			lairs = eb.call(&"default_lairs")
	var lair_art: Script = load(LAIR_ART) as Script if ResourceLoader.exists(LAIR_ART) else null
	for l: Variant in lairs:
		if not (l is Dictionary):
			continue
		var lair: Dictionary = l
		var c: Vector3 = lair.get("center", Vector3.ZERO)
		var circles := PackedVector3Array()
		if lair_art and lair_art.has_method(&"scene_path_for"):
			var path: String = lair_art.call(&"scene_path_for", StringName(lair.get("id", &"")),
				StringName(lair.get("kind", &"")))
			var local: Variant = _scene_root_meta(path, "decor_clear", null) if path != "" else null
			if local is PackedVector3Array:
				var yaw: float = float(lair_art.call(&"yaw_for", StringName(lair.get("id", &""))))
				for lc: Vector3 in (local as PackedVector3Array):
					var w: Vector3 = Basis(Vector3.UP, yaw) * Vector3(lc.x, 0.0, lc.y)
					circles.append(Vector3(c.x + w.x, c.z + w.z, lc.z + 0.2))
		if circles.is_empty():
			circles.append(Vector3(c.x, c.z, float(lair.get("radius", 4.0)) * 0.6))
		for cc: Vector3 in circles:
			_avoid.append(cc)


## A metadata value of a scene's root node. Fast path: the text .tscn's first `metadata/<key> = ...` line (the camp
## sites and lairs keep it on their root), so nothing is loaded at map start; else (an exported, binary scene) the
## PackedScene's state (a load, no instancing).
static func _scene_root_meta(path: String, key: String, fallback: Variant) -> Variant:
	if path == "" or not ResourceLoader.exists(path):
		return fallback
	if path.ends_with(".tscn") and FileAccess.file_exists(path):
		var text: String = FileAccess.get_file_as_string(path)
		var at: int = text.find("\nmetadata/" + key + " = ")
		if at >= 0:
			var start: int = text.find("=", at) + 1
			var end: int = text.find("\n", start)
			var v: Variant = str_to_var(text.substr(start, (end if end > 0 else text.length()) - start).strip_edges())
			if v != null:
				return v
	var scene := load(path) as PackedScene
	if scene == null:
		return fallback
	var state: SceneState = scene.get_state()
	for i: int in state.get_node_property_count(0):
		if state.get_node_property_name(0, i) == "metadata/" + key:
			return state.get_node_property_value(0, i)
	return fallback


## A node's decor-free footprint: LairArt circles, CampSite radius, `decor_clear_radius` metadata (landmarks).
func _add_clear_of(n: Node) -> void:
	if not (n is Node3D):
		return
	var p: Vector3 = (n as Node3D).global_position
	if n.has_method(&"decor_clear_circles"):
		for c: Vector3 in (n.call(&"decor_clear_circles") as PackedVector3Array):
			_avoid.append(c)
	elif n.has_method(&"clear_radius") and n.has_method(&"set_cleared"):
		_avoid.append(Vector3(p.x, p.z, float(n.call(&"clear_radius"))))
	elif n.has_meta(&"decor_clear_radius"):
		_avoid.append(Vector3(p.x, p.z, float(n.get_meta(&"decor_clear_radius"))))
	elif n.is_in_group(&"landmarks"):
		_avoid.append(Vector3(p.x, p.z, 3.5))


func _add_crossing(c: Dictionary) -> void:
	var center: Vector3 = c.get("center", Vector3.ZERO)
	var kind: StringName = StringName(c.get("kind", &""))
	var width: float = float(c.get("width", 6.0))
	if String(kind).begins_with("bridge"):
		var dir: Vector3 = c.get("dir", Vector3.RIGHT)
		var u := Vector2(dir.x, dir.z).normalized()
		_crossing_rects.append({"c": Vector2(center.x, center.z), "u": u, "hl": float(c.get("length", 8.0)) * 0.5,
			"hw": width * 0.5})
	else:
		_crossing_circles.append(Vector3(center.x, center.z, width * 0.5))


## The trade roads painted by the ground (road_segs / road_count, 10.V10), so no decor grows on them.
func _read_roads(sm: ShaderMaterial) -> void:
	var count: Variant = sm.get_shader_parameter(&"road_count")
	var segs: Variant = sm.get_shader_parameter(&"road_segs")
	if not (count is int) or int(count) <= 0 or segs == null:
		return
	var width: Variant = sm.get_shader_parameter(&"road_width")
	if width is float:
		_road_clear = float(width) * 0.5 + 0.8
	var list: Array = []
	if segs is PackedVector4Array or segs is Array:
		list = Array(segs)
	for i: int in mini(int(count), list.size()):
		if list[i] is Vector4:
			_roads.append(list[i])


func _building_radius(b: Node) -> float:
	if b.has_method(&"target_radius"):
		return float(b.call(&"target_radius")) + 1.0
	return 4.0


func _hash_avoid() -> void:
	_avoid_grid.clear()
	for a: Vector3 in _avoid:
		var r: float = a.z + AVOID_PAD
		var lo := Vector2i(floori((a.x - r) / AVOID_CELL), floori((a.y - r) / AVOID_CELL))
		var hi := Vector2i(floori((a.x + r) / AVOID_CELL), floori((a.y + r) / AVOID_CELL))
		for cx: int in range(lo.x, hi.x + 1):
			for cz: int in range(lo.y, hi.y + 1):
				var k := Vector2i(cx, cz)
				if not _avoid_grid.has(k):
					_avoid_grid[k] = []
				(_avoid_grid[k] as Array).append(a)


func _near_avoid(q: Vector2, margin: float) -> bool:
	var cell: Variant = _avoid_grid.get(Vector2i(floori(q.x / AVOID_CELL), floori(q.y / AVOID_CELL)))
	if cell == null:
		return false
	for a: Vector3 in (cell as Array):
		if q.distance_to(Vector2(a.x, a.y)) < a.z + margin:
			return true
	return false


func _on_crossing(q: Vector2, grow: float) -> bool:
	for c: Vector3 in _crossing_circles:
		if q.distance_to(Vector2(c.x, c.y)) < c.z + grow:
			return true
	for r: Dictionary in _crossing_rects:
		var d: Vector2 = q - (r["c"] as Vector2)
		var u: Vector2 = r["u"]
		if absf(d.dot(u)) < float(r["hl"]) + grow and absf(d.dot(Vector2(-u.y, u.x))) < float(r["hw"]) + grow:
			return true
	return false


## True where land decor must not go: off the map, on the lane, on dirt / paved spots (kind-1 paving allowed for
## `paving` items, with `lane_paving` as their lane clearance there), on roads, crossings, near objects.
func _blocked(x: float, z: float, margin: float, paving: bool = false, lane_paving: float = 0.0) -> bool:
	if absf(x) > MAP_HALF - 0.4 or absf(z) > MAP_HALF - 0.4:
		return true
	var q := Vector2(x, z)
	if _has_lane:
		var lane_clear := LANE_CLEAR
		if paving and lane_paving > 0.0:
			for s0: Vector4 in _spots:
				if s0.w > 0.5 and q.distance_to(Vector2(s0.x, s0.y)) < s0.z:
					lane_clear = lane_paving
		var c: Vector2 = Geometry2D.get_closest_point_to_segment(q, _lane_a, _lane_b)
		if q.distance_to(c) < lane_clear + margin:
			return true
	for s: Vector4 in _spots:
		if paving and s.w > 0.5:
			continue   # kind-1 flagstone paving (Crown Isle): ruins decor belongs there
		if q.distance_to(Vector2(s.x, s.y)) < s.z + 0.8 + margin:
			return true
	for r: Vector4 in _roads:
		var c2: Vector2 = Geometry2D.get_closest_point_to_segment(q, Vector2(r.x, r.y), Vector2(r.z, r.w))
		if q.distance_to(c2) < _road_clear + margin:
			return true
	if _on_crossing(q, 0.8 + margin):
		return true
	return _near_avoid(q, margin)


## True where water decor must not go: off the map, under a bridge / on a ford (with its rapids), by a landmark.
func _blocked_water(x: float, z: float) -> bool:
	if absf(x) > MAP_HALF - 0.4 or absf(z) > MAP_HALF - 0.4:
		return true
	var q := Vector2(x, z)
	return _on_crossing(q, 1.2) or _near_avoid(q, 0.2)


# ---------------------------------------------------------------- scattering

func _populate() -> void:
	if _populated or not is_inside_tree():
		return
	_populated = true
	var t0: int = Time.get_ticks_usec()
	_read_map()
	var t1: int = Time.get_ticks_usec()
	var t2: int = t1
	if decor_enabled:
		_detail = (LOW_DETAIL if map_detail() == &"low" else 1.0) * maxf(density_scale, 0.0)
		if biomes_enabled:
			_load_items()
		if _items.is_empty():
			_legacy = true
			_undergrowth_legacy()
			_field()
			_flowers()
			_edge_strip_legacy()
		else:
			for it: Dictionary in _items:
				_scatter_item(it)
			_undergrowth()
			_edge_strip()
		t2 = Time.get_ticks_usec()
		_commit()
	var t3: int = Time.get_ticks_usec()
	_populate_ms = float(t3 - t0) / 1000.0
	_timings = {"read_ms": (t1 - t0) / 1000.0, "scatter_ms": (t2 - t1) / 1000.0, "commit_ms": (t3 - t2) / 1000.0}


## Every biome set's items (BiomeMap.load_items), with the kind budget applied (KIND_MERGE / KIND_DROP).
func _load_items() -> void:
	for biome: StringName in BIOME_MAP.BIOMES:
		for it: Dictionary in BIOME_MAP.load_items(biome):
			var path: String = it["path"]
			if not all_kinds:
				if path in KIND_DROP:
					continue
				if KIND_MERGE.has(path):
					var target: String = KIND_MERGE[path]
					if not ResourceLoader.exists(target):
						continue
					it["mesh"] = load(target)
					it["path"] = target
					path = target
			_items.append(it)
			if not _kinds.has(path):
				_kinds[path] = it
	# Kinds the roles use that no scattered item registered (all of them normally).
	for biome2: StringName in ROLE_KINDS:
		for role: StringName in (ROLE_KINDS[biome2] as Dictionary):
			var rp: String = ROLE_KINDS[biome2][role]
			if rp != "" and not _kinds.has(rp) and ResourceLoader.exists(rp):
				_kinds[rp] = {"mesh": load(rp), "path": rp, "scale": Vector2(0.85, 1.2), "vis_end": 90.0,
					"shadow": false, "biome": biome2}


func _round_rand(x: float) -> int:
	var n: int = int(floor(x))
	return n + (1 if _rng.randf() < x - float(n) else 0)


## One biome item over its zone: `density` per 100 m2 at full weight (x Map detail), a fraction `cluster` in
## patches, `gap` spacing, `place` land / bank / water.
func _scatter_item(it: Dictionary) -> void:
	var biome: StringName = it["biome"]
	var bi: int = BIOME_MAP.BIOMES.find(biome)
	var place: StringName = StringName(it.get("place", &"land"))
	var density: float = float(it["density"]) * _detail
	if density <= 0.0 or bi < 0:
		return
	var rects: Array[Rect2] = []
	var bm: BIOME_MAP = _bm
	match place:
		&"water":
			if not bm.has_water():
				return
			rects = bm.water_domain(0.2)
		&"bank":
			if not bm.has_water():
				return
			rects = bm.water_domain(2.7)
		_:
			rects = bm.domain(biome)
	var gap: float = float(it.get("gap", 0.0))
	var cluster: float = clampf(float(it.get("cluster", 0.0)), 0.0, 1.0)
	var psize: int = int(PATCH_SIZES.get(biome, 8))
	var spread: float = PATCH_SPREAD * (2.0 if gap > 0.0 else 1.0)
	if place != &"land":
		spread = WATER_SPREAD   # the bank / shore bands are only 1-2.5 m wide: tight clumps along them
	for r: Rect2 in rects:
		var n_full: float = density * r.get_area() / 100.0
		for i: int in _round_rand(n_full * (1.0 - cluster)):
			_try_item(it, Vector2(_rng.randf_range(r.position.x, r.end.x), _rng.randf_range(r.position.y, r.end.y)),
				bi, place)
		for k: int in _round_rand(n_full * cluster / float(psize)):
			var pc := Vector2(_rng.randf_range(r.position.x, r.end.x), _rng.randf_range(r.position.y, r.end.y))
			if _rng.randf() >= _item_weight(it, pc, bi, place):
				continue
			for j: int in psize:
				# A member that falls outside the zone (the narrow bank / shore bands, a biome edge) draws again (3x).
				var p2: Vector2 = pc
				var w2 := 0.0
				for attempt: int in 3:
					p2 = pc + Vector2(_rng.randfn(0.0, spread), _rng.randfn(0.0, spread))
					w2 = _item_weight(it, p2, bi, place)
					if w2 > 0.0:
						break
				_try_item(it, p2, bi, place, w2)


## How much of the item belongs at p (0-1): its biome's weight on land, the 0-2.5 m band for `bank`, the shore band
## of deep water for `water`.
func _item_weight(it: Dictionary, p: Vector2, bi: int, place: StringName) -> float:
	var bm: BIOME_MAP = _bm
	match place:
		&"water":
			if bm.water_far(p, 0.05):
				return 0.0
			var wd: float = bm.water_distance(p)
			var shore: float = float(it.get("shore", 2.5))
			if wd > -0.1 or wd < -shore or bm.in_ford(p, 1.0):
				return 0.0
			return 1.0
		&"bank":
			if bm.water_far(p, 2.6):
				return 0.0
			var wd2: float = bm.water_distance(p)
			if wd2 < 0.1 or wd2 > 2.5 or bm.in_ford(p, 0.4):
				return 0.0
			return bm.weights(p)[bi]
	var w: float = bm.weights(p)[bi]
	if w <= 0.0:
		return 0.0
	if bm.has_water():
		var need: float = 0.25 if bi == BIOME_MAP.RIVERBANK else 0.6
		if not bm.water_far(p, need) and (bm.water_distance(p) < need or bm.in_ford(p, 0.3)):
			return 0.0
	return w


## One candidate: kept with probability = its weight (`w` when the caller already has it), then the blocking and
## spacing rules.
func _try_item(it: Dictionary, p: Vector2, bi: int, place: StringName, w: float = -1.0) -> void:
	if w < 0.0:
		w = _item_weight(it, p, bi, place)
	if w <= 0.0 or _rng.randf() >= w:
		return
	var gap: float = float(it.get("gap", 0.0))
	var path: String = it["path"]
	var margin: float = 0.25
	if gap > 0.0:
		margin = 0.6 if bi == BIOME_MAP.RUINS else minf(gap * 0.5, MAX_MARGIN)
	# Big sparse props (gap >= BIG_GAP: trunks, hay, boulders, bushes, monuments) are few per zone and the zones are
	# cluttered (the Old Wood's trees): a blocked one looks for room nearby, up to BIG_RETRIES times.
	var tries: int = BIG_RETRIES if gap >= BIG_GAP else 1
	for t: int in tries:
		if t > 0:
			p += Vector2(_rng.randf_range(-gap, gap), _rng.randf_range(-gap, gap))
			if _item_weight(it, p, bi, place) <= 0.0:
				continue
		var blocked: bool
		if place == &"water":
			blocked = _blocked_water(p.x, p.y)
		else:
			blocked = _blocked(p.x, p.y, margin, bool(it.get("paving_ok", false)), float(it.get("lane_clear_paving", 0.0)))
		if blocked or not _space_ok(path, p, gap):
			continue
		_place(path, p, it, 1.0, BIOME_MAP.BIOMES[bi])
		return


## Spacing: `gap` between two instances of a kind, and half the summed gaps between two big items of any kinds.
func _space_ok(path: String, p: Vector2, gap: float) -> bool:
	if gap <= 0.0:
		return true
	var grid: Dictionary = _gap_grids.get(path, {})
	var cell := Vector2i(floori(p.x / gap), floori(p.y / gap))
	for dx: int in [-1, 0, 1]:
		for dz: int in [-1, 0, 1]:
			var pts: Variant = grid.get(cell + Vector2i(dx, dz))
			if pts != null:
				for q: Vector2 in (pts as PackedVector2Array):
					if q.distance_to(p) < gap:
						return false
	var bcell := Vector2i(floori(p.x / 4.0), floori(p.y / 4.0))
	for dx2: int in [-1, 0, 1]:
		for dz2: int in [-1, 0, 1]:
			var bigs: Variant = _big_grid.get(bcell + Vector2i(dx2, dz2))
			if bigs != null:
				for b: Vector3 in (bigs as Array):
					if p.distance_to(Vector2(b.x, b.y)) < minf((gap + b.z) * 0.35, 3.0):
						return false
	return true


func _remember_space(path: String, p: Vector2, gap: float) -> void:
	if gap <= 0.0:
		return
	if not _gap_grids.has(path):
		_gap_grids[path] = {}
	var grid: Dictionary = _gap_grids[path]
	var cell := Vector2i(floori(p.x / gap), floori(p.y / gap))
	var pts: PackedVector2Array = grid.get(cell, PackedVector2Array())
	pts.append(p)
	grid[cell] = pts
	var bcell := Vector2i(floori(p.x / 4.0), floori(p.y / 4.0))
	if not _big_grid.has(bcell):
		_big_grid[bcell] = []
	(_big_grid[bcell] as Array).append(Vector3(p.x, p.y, gap))


## One instance of a kind: its scale range (x `scale_mul`), its yaw hint (`yaw` + `yaw_jitter`: the heath's
## wind-combed tall grass) or a random yaw, its height (`y`: the water surface).
func _place(path: String, p: Vector2, info: Dictionary, scale_mul: float, biome: StringName) -> void:
	var sc: Vector2 = info.get("scale", Vector2(0.85, 1.2))
	var s: float = _rng.randf_range(sc.x, sc.y) * scale_mul
	var a: float
	if info.has("yaw"):
		var jit: float = float(info.get("yaw_jitter", 0.0))
		a = float(info["yaw"]) + _rng.randf_range(-jit, jit)
	else:
		a = _rng.randf() * TAU
	var y: float = float(info.get("y", 0.0))
	_remember_space(path, p, float(info.get("gap", 0.0)))
	_add_xf(path, Transform3D(Basis(Vector3.UP, a).scaled(Vector3(s, s, s)), Vector3(p.x, y, p.y)), biome)


func _add_xf(path: String, xf: Transform3D, biome: StringName) -> void:
	var cx: int = clampi(int(floor((xf.origin.x + MAP_HALF) / CHUNK)), 0, CHUNKS - 1)
	var cz: int = clampi(int(floor((xf.origin.z + MAP_HALF) / CHUNK)), 0, CHUNKS - 1)
	var key: String = "%d:%d|%s" % [cx, cz, path]
	if not _lists.has(key):
		_lists[key] = []
		_list_biome[key] = []
	(_lists[key] as Array).append(xf)
	(_list_biome[key] as Array).append(biome)


## A role (grass / fern / bush / small / stones / log) at p with the local biome's kind (drawn by weight, so the
## borders mix). Land rules of _blocked (or only the objects for the cliff foot), no water, spacing.
func _place_role(role: StringName, p: Vector2, scale_mul: float, margin: float, objects_only: bool = false) -> void:
	var bm: BIOME_MAP = _bm
	var biome: StringName = bm.pick(p, _rng.randf())
	var path: String = String((ROLE_KINDS.get(biome, {}) as Dictionary).get(role, ""))
	if path == "" or not _kinds.has(path):
		return
	var info: Dictionary = _kinds[path]
	var gap: float = float(info.get("gap", 0.0))
	var m: float = maxf(margin, minf(gap * 0.5, MAX_MARGIN)) if gap > 0.0 else margin
	if objects_only:
		if absf(p.x) > MAP_HALF - 0.45 or absf(p.y) > MAP_HALF - 0.45 or _near_avoid(p, m) or _on_crossing(p, 0.8 + m):
			return
		for r: Vector4 in _roads:
			var c2: Vector2 = Geometry2D.get_closest_point_to_segment(p, Vector2(r.x, r.y), Vector2(r.z, r.w))
			if p.distance_to(c2) < _road_clear + m:
				return
	elif _blocked(p.x, p.y, m, bool(info.get("paving_ok", false)), float(info.get("lane_clear_paving", 0.0))):
		return
	if bm.has_water() and not bm.water_far(p, 0.6) and (bm.water_distance(p) < 0.4 or bm.in_ford(p, 0.3)):
		return
	if not _space_ok(path, p, gap):
		return
	_place(path, p, info, scale_mul, biome)


func _ring_point(c: Vector3, rmin: float, rmax: float) -> Vector2:
	var a: float = _rng.randf() * TAU
	var r: float = _rng.randf_range(rmin, rmax)
	return Vector2(c.x + cos(a) * r, c.z + sin(a) * r)


## Undergrowth round the trees (ferns / bushes / small plants / grass, now and then a log) and round the rocks
## (stones, grass, ferns), each from the local biome.
func _undergrowth() -> void:
	for xf: Transform3D in _trees:
		var s: float = xf.basis.get_scale().x
		for i: int in _round_rand(_rng.randf_range(2.0, 4.0) * _detail):
			var p: Vector2 = _ring_point(xf.origin, 0.8 * s, 2.3 * s)
			var roll: float = _rng.randf()
			var role: StringName = &"fern" if roll < 0.38 else (&"bush" if roll < 0.55 else
				(&"small" if roll < 0.68 else &"grass"))
			_place_role(role, p, 1.0, 0.3)
		if _rng.randf() < 0.1 * _detail:
			_place_role(&"log", _ring_point(xf.origin, 1.5 * s, 3.0 * s), 1.0, 1.2)
	for xf2: Transform3D in _rocks:
		var s2: float = xf2.basis.get_scale().x
		for i: int in _round_rand(_rng.randf_range(1.0, 3.0) * _detail):
			var p3: Vector2 = _ring_point(xf2.origin, 0.9 * s2, 1.6 * s2)
			var roll2: float = _rng.randf()
			_place_role(&"stones" if roll2 < 0.4 else (&"grass" if roll2 < 0.8 else &"fern"), p3, 1.0, 0.2)


## MAP.P1 cliff-foot clumps inside the map's last ~3 m: they gather in clumps along the wall (no even row), scree
## stones hug the cliff foot, grass / bushes / ferns a little further in; every piece from the local biome's set.
func _edge_strip() -> void:
	var s: float = -MAP_HALF
	while s < MAP_HALF:
		for side: int in 4:
			var inset: float = _rng.randf_range(0.5, 3.2)
			var t: float = s + _rng.randf_range(0.0, 1.6)
			var clump: float = 0.5 + 0.5 * sin(t * 0.23 + side * 1.7) * sin(t * 0.081 + side * 0.9 + 1.1)
			var keep: bool = _rng.randf() < (0.2 + 0.95 * clump) * _detail
			var roll: float = _rng.randf()
			if not keep:
				continue
			var p: Vector2
			match side:
				0: p = Vector2(t, -MAP_HALF + inset)
				1: p = Vector2(MAP_HALF - inset, t)
				2: p = Vector2(-t, MAP_HALF - inset)
				_: p = Vector2(-MAP_HALF + inset, -t)
			if inset < 1.3:   # right at the cliff foot: scree and tufts
				if roll < 0.45:
					_place_role(&"stones", p, 1.25, 0.0, true)
				else:
					_place_role(&"grass", p, 1.15, 0.0, true)
			elif roll < 0.45:
				_place_role(&"grass", p, 1.15, 0.0, true)
			elif roll < 0.7:
				_place_role(&"bush", p, 1.05, 0.0, true)
			elif roll < 0.8:
				_place_role(&"stones", p, 1.15, 0.0, true)
			else:
				_place_role(&"fern", p, 1.1, 0.0, true)
		s += 1.6


func _commit() -> void:
	var parent_name: String = "Decor" if _legacy else "Biomes"
	var decor: Node3D = get_node_or_null(NodePath(parent_name)) as Node3D
	if decor == null:
		decor = Node3D.new()
		decor.name = parent_name
		add_child(decor)
	# Instances per kind: sparse kinds go into one MultiMesh.
	var per_kind := {}
	for key: String in _lists:
		var path: String = key.get_slice("|", 1)
		per_kind[path] = int(per_kind.get(path, 0)) + (_lists[key] as Array).size()
	var merged := {}   # final key -> [Array[Transform3D], Array biomes]
	for key2: String in _lists:
		var path2: String = key2.get_slice("|", 1)
		var fk: String = ("all|" + path2) if int(per_kind[path2]) < SPARSE_KIND else key2
		if not merged.has(fk):
			merged[fk] = [[], []]
		(merged[fk][0] as Array).append_array(_lists[key2])
		(merged[fk][1] as Array).append_array(_list_biome[key2])
	var meshes := {}
	for key3: String in merged:
		var cell: String = key3.get_slice("|", 0)
		var path3: String = key3.get_slice("|", 1)
		if not meshes.has(path3):
			meshes[path3] = _mesh_for(path3)
		var mesh: Mesh = meshes[path3]
		var list: Array = merged[key3][0]
		if mesh == null or list.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = list.size()
		var pos := PackedVector3Array()
		pos.resize(list.size())
		for i: int in list.size():
			var xf: Transform3D = list[i]
			mm.set_instance_transform(i, xf)
			pos[i] = xf.origin
		var mmi := MultiMeshInstance3D.new()
		var base: String = path3.get_file().get_basename()
		mmi.name = "%s_%s" % [base.to_pascal_case(), cell.replace(":", "_")]
		mmi.multimesh = mm
		mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		var info: Dictionary = _kinds.get(path3, {})
		var shadow: bool = bool(info.get("shadow", false)) if not _legacy else base in SHADOW_MESHES
		if not shadow:
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if not _legacy and cell != "all":
			# The range is measured from the chunk's centre: add its half diagonal so nothing within `vis_end` of the
			# camera pops; margin = hysteresis (no fade: a faded chunk would go through the transparent pass).
			mmi.visibility_range_end = float(info.get("vis_end", 90.0)) + CHUNK * 0.7072
			mmi.visibility_range_end_margin = 10.0
			mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		decor.add_child(mmi)
		_chunks[key3] = {"mm": mm, "pos": pos, "path": path3, "xf": list}
		_count += list.size()
		for b: Variant in (merged[key3][1] as Array):
			_biome_counts[b] = int(_biome_counts.get(b, 0)) + 1
	_lists.clear()
	_list_biome.clear()


func _mesh_for(path: String) -> Mesh:
	if _kinds.has(path) and _kinds[path].get("mesh") is Mesh:
		return _kinds[path]["mesh"]
	return load(path) as Mesh if ResourceLoader.exists(path) else null


# ---------------------------------------------------------------- legacy decor (no biome set)

func _add(mesh: String, x: float, z: float, s: float, yaw: float = -1.0) -> void:
	var a: float = _rng.randf() * TAU if yaw < 0.0 else yaw
	_add_xf(MESH_DIR + mesh + ".res", Transform3D(Basis(Vector3.UP, a).scaled(Vector3(s, s, s)), Vector3(x, 0.0, z)),
		&"legacy")


func _undergrowth_legacy() -> void:
	for xf: Transform3D in _trees:
		var s: float = xf.basis.get_scale().x
		for i: int in _rng.randi_range(2, 4):
			var p: Vector2 = _ring_point(xf.origin, 0.7 * s, 2.3 * s)
			if _blocked(p.x, p.y, 0.3):
				continue
			var roll: float = _rng.randf()
			if roll < 0.38:
				_add("decor_fern", p.x, p.y, _rng.randf_range(0.8, 1.3))
			elif roll < 0.58:
				_add("decor_bush" if _rng.randf() < 0.7 else "decor_bush_berry", p.x, p.y, _rng.randf_range(0.7, 1.2))
			elif roll < 0.68:
				_add("decor_mushrooms", p.x, p.y, _rng.randf_range(0.8, 1.3))
			else:
				_add("decor_grass", p.x, p.y, _rng.randf_range(0.9, 1.4))
		if _rng.randf() < 0.1:
			var p2: Vector2 = _ring_point(xf.origin, 1.5 * s, 3.0 * s)
			if not _blocked(p2.x, p2.y, 1.2):
				_add("decor_log" if _rng.randf() < 0.55 else "decor_stump", p2.x, p2.y, _rng.randf_range(0.85, 1.15))
	for xf2: Transform3D in _rocks:
		var s2: float = xf2.basis.get_scale().x
		for i: int in _rng.randi_range(1, 3):
			var p3: Vector2 = _ring_point(xf2.origin, 0.9 * s2, 1.6 * s2)
			if _blocked(p3.x, p3.y, 0.2):
				continue
			var roll2: float = _rng.randf()
			_add("decor_stones" if roll2 < 0.4 else ("decor_grass" if roll2 < 0.8 else "decor_fern"), p3.x, p3.y,
				_rng.randf_range(0.8, 1.3))


## Patch density in the open field (0-1): clumps gather in loose patches instead of an even sprinkle.
static func _patch(x: float, z: float) -> float:
	return clampf(0.5 + 0.28 * sin(x * 0.11 + 1.3) * sin(z * 0.13 + 0.7) + 0.22 * sin(x * 0.047 - z * 0.061 + 2.1), 0.0, 1.0)


func _field() -> void:
	var placed: int = 0
	var tries: int = 0
	var target: int = int(grass_clumps * _detail)
	while placed < target and tries < target * 6:
		tries += 1
		var x: float = _rng.randf_range(-MAP_HALF, MAP_HALF)
		var z: float = _rng.randf_range(-MAP_HALF, MAP_HALF)
		if _rng.randf() > _patch(x, z) * _patch(x, z) * 1.6:
			continue
		if _blocked(x, z, 0.5):
			continue
		_add("decor_grass", x, z, _rng.randf_range(0.8, 1.35))
		placed += 1
		if _rng.randf() < 0.35:
			var x2: float = x + _rng.randf_range(-0.6, 0.6)
			var z2: float = z + _rng.randf_range(-0.6, 0.6)
			if not _blocked(x2, z2, 0.5):
				_add("decor_grass", x2, z2, _rng.randf_range(0.7, 1.1))
	for i: int in 26:
		var x3: float = _rng.randf_range(-56.0, 56.0)
		var z3: float = _rng.randf_range(-56.0, 56.0)
		if _blocked(x3, z3, 2.0):
			continue
		_add("decor_stones" if i % 3 == 0 else "decor_bush", x3, z3, _rng.randf_range(0.8, 1.2))


func _flowers() -> void:
	for i: int in int(flower_patches * _detail):
		var cx: float = _rng.randf_range(-55.0, 55.0)
		var cz: float = _rng.randf_range(-55.0, 55.0)
		if _blocked(cx, cz, 2.0):
			continue
		var mesh: String = FLOWERS[_rng.randi() % FLOWERS.size()]
		for k: int in _rng.randi_range(6, 12):
			var a: float = _rng.randf() * TAU
			var r: float = sqrt(_rng.randf()) * 2.6
			var x: float = cx + cos(a) * r
			var z: float = cz + sin(a) * r
			if _blocked(x, z, 0.3):
				continue
			_add(mesh if _rng.randf() < 0.8 else FLOWERS[_rng.randi() % FLOWERS.size()], x, z, _rng.randf_range(0.8, 1.25))


func _edge_strip_legacy() -> void:
	var s: float = -MAP_HALF
	while s < MAP_HALF:
		for side: int in 4:
			var inset: float = _rng.randf_range(0.5, 3.2)
			var t: float = s + _rng.randf_range(0.0, 1.6)
			var clump: float = 0.5 + 0.5 * sin(t * 0.23 + side * 1.7) * sin(t * 0.081 + side * 0.9 + 1.1)
			var keep: bool = _rng.randf() < (0.2 + 0.95 * clump) * _detail
			var p: Vector2
			match side:
				0: p = Vector2(t, -MAP_HALF + inset)
				1: p = Vector2(MAP_HALF - inset, t)
				2: p = Vector2(-t, MAP_HALF - inset)
				_: p = Vector2(-MAP_HALF + inset, -t)
			if not keep or absf(p.x) > MAP_HALF - 0.45 or absf(p.y) > MAP_HALF - 0.45 or _near_avoid(p, 0.0):
				continue
			var roll: float = _rng.randf()
			if inset < 1.3:
				_add("decor_stones" if roll < 0.45 else "decor_grass", p.x, p.y, _rng.randf_range(1.0, 1.7) if roll < 0.45
					else _rng.randf_range(1.0, 1.5))
			elif roll < 0.45:
				_add("decor_grass", p.x, p.y, _rng.randf_range(1.0, 1.5))
			elif roll < 0.7:
				_add("decor_bush", p.x, p.y, _rng.randf_range(0.8, 1.3))
			elif roll < 0.8:
				_add("decor_stones", p.x, p.y, _rng.randf_range(1.0, 1.5))
			else:
				_add("decor_fern", p.x, p.y, _rng.randf_range(0.9, 1.3))
		s += 1.6


# ---------------------------------------------------------------- objects placed later

func _on_node_added(n: Node) -> void:
	if n.has_method(&"construction_progress") and n.has_method(&"target_radius"):
		_clear_for.call_deferred(n)
	elif n.has_method(&"decor_clear_circles") or (n.has_method(&"clear_radius") and n.has_method(&"set_cleared")):
		_clear_site.call_deferred(n)


func _clear_for(n: Node) -> void:
	if is_instance_valid(n) and n is Node3D and (n as Node3D).is_inside_tree():
		clear_area((n as Node3D).global_position, _building_radius(n) - 0.4)


## Lairs (LairArt.decor_clear_circles) and camp sites (CampSite.clear_radius) placed after the scatter.
func _clear_site(n: Node) -> void:
	if not is_instance_valid(n) or not (n is Node3D) or not (n as Node3D).is_inside_tree():
		return
	if n.has_method(&"decor_clear_circles"):
		for c: Vector3 in (n.call(&"decor_clear_circles") as PackedVector3Array):
			clear_area(Vector3(c.x, 0.0, c.y), c.z)
	else:
		clear_area((n as Node3D).global_position, float(n.call(&"clear_radius")))
