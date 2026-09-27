extends RefCounted
## Snow decor set (task 12b.V2; terrain.md 2 "snow" + 4.2 snowfields + 7.2 decor sets, map-fill.md section 10 format).
## Pure data for the dressing scatter (12b.V6, MapDressingArt reading TerrainSystem.patches() / the terrain mask); no
## class dependency, so read it with load():
##     var set_script: GDScript = load("res://art/environment/biomes/snow/snow_set.gd")
##     for item: Dictionary in set_script.items(): ...          (loaded meshes / materials, the 12.V6 format)
##     set_script.ENTRIES / set_script.GROUND_TINT / set_script.BIOME_ID   (the map-fill.md section 10 constants)
## BiomeMap.load_items(&"snow") also works (the path follows BiomeMap.set_path).
## Meshes (built by build_snow.gd with the shared nature_mat.tres; 3 shape variants per mesh picked by the shader from
## the instance position (the variant mask of nature_painted.gdshader): place them with ONE MultiMesh per mesh and
## chunk, random yaw, uniform scale, y = 0, no collider):
##   snow_capped_rocks  cold blue-grey granite under thick snow pillows, ~1.5-2.7 m incl. its drift, <= 0.82 m tall
##                      at scale 1 (V0 capped boulder + stone in a wind drift, V1 tilted shard with an icicle fringe,
##                      V2 huddle of three capped stones); surface 1 = soft BLUE contact disc (snow_contact_mat.tres)
##   snow_frost_scrub   ~0.6-1.1 m (V0 frosted blue-green grass tuft in a snow mound, V1 frost-bleached straw tuft
##                      bent under the snow, V2 small icicle shrub: dark twigs, snow on the forks, icicles); the shrub
##                      variant has a contact disc (surface 1)
## Nothing glows, no lights; the snow sparkle is the ground shader's (12b.V1), not the decor's.
## Shadows: only the capped rocks (terrain.md 7.2: "no shadows except stumps and rocks"); ranges 90 m rocks, 65 m
## scrub (small).
## Places (terrain.md 7.2): &"snow" = inside a snow patch (mask weight > 0.5), &"snow_edge" = the patch border
## (weight 0.2-0.5). The terrain mask is a 0.5 m grid, so a bilinear 0.2-0.5 band is only ~0.15 m wide: the scatter
## should measure the edge as a band EDGE_BAND metres wide centred on the patch outline (the noisy 1 m edge of
## terrain.md 4.1); `per_100m2` of a &"snow_edge" row is per 100 m2 of that band. Grass tufts poke through there
## (frosted scrub dense at the border, a few rocks), the field inside stays mostly open white snow.
## Budget (terrain.md 7.2: snow <= 500 instances): the 4 snowfields are ~320 m2 inside (more than EDGE_BAND / 2 in)
## and ~140 m2 of edge band -> the rows ask for at most ~305 instances (tests/test_12b_v2.gd computes it from the
## terrain.md 4.2 patches); ~190 once the wells' capture points, the lairs, roads, the river and crystal nodes are
## cleared (snow_preview.gd mode=map on the real map). Kinds: +2 of the 32 decor mesh kinds.

const BIOME_ID := &"snow"
## Snow ground colour (terrain.md 7.1 snow base (0.90, 0.93, 0.98)): the minimap / mask tint of the snow layer. The
## ground shader draws the drifts, blue shade, frost rim and sparkle itself.
const GROUND_TINT := Color(0.90, 0.93, 0.98)
const DIR := "res://art/environment/biomes/snow/"
const INSTANCE_BUDGET := 500
## Shape variants per mesh (nature_painted.gdshader variant mask).
const VARIANTS := 3
## Place ids (terrain.md 7.2).
const PLACE_IN := &"snow"
const PLACE_EDGE := &"snow_edge"
## Width (m) of the &"snow_edge" band, centred on the patch outline.
const EDGE_BAND := 1.0

## map-fill.md section 10 format (keys: mesh path, per_100m2, scale, cluster, shadow, range, place) + optional keys:
##   id        a short name (the same mesh may appear on two rows: one inside, one on the edge)
##   gap       minimum distance in metres between two instances of this mesh (the rocks); clearance from roads /
##             slots / buildings / capture circles about gap / 2
##   variants  shape variants in the mesh (3: the shader picks one from the instance position)
## `cluster`: 0 = even sprinkle, 1 = everything in patches (~8 per patch, gaussian sigma ~1.2 m; x2 for gap entries).
const ENTRIES := [
	{"id": &"frost_scrub", "mesh": "res://art/environment/biomes/snow/snow_frost_scrub.res", "per_100m2": 45.0,
		"scale": Vector2(0.85, 1.35), "cluster": 0.6, "shadow": false, "range": 65.0, "place": &"snow", "variants": 3},
	{"id": &"frost_scrub", "mesh": "res://art/environment/biomes/snow/snow_frost_scrub.res", "per_100m2": 95.0,
		"scale": Vector2(0.75, 1.15), "cluster": 0.5, "shadow": false, "range": 65.0, "place": &"snow_edge",
		"variants": 3},
	{"id": &"capped_rocks", "mesh": "res://art/environment/biomes/snow/snow_capped_rocks.res", "per_100m2": 7.0,
		"scale": Vector2(1.0, 1.55), "cluster": 0.35, "shadow": true, "range": 90.0, "place": &"snow", "variants": 3,
		"gap": 2.2},
	{"id": &"capped_rocks", "mesh": "res://art/environment/biomes/snow/snow_capped_rocks.res", "per_100m2": 4.0,
		"scale": Vector2(0.75, 1.1), "cluster": 0.0, "shadow": true, "range": 90.0, "place": &"snow_edge",
		"variants": 3, "gap": 2.2},
]


## The set in the 12.V6 scatter format (shared with the heath / glade / ruins / Old Wood sets): one Dictionary per
## ENTRIES row, in order:
##   mesh: Mesh, material: Material (surface 0's shared nature_mat.tres; the contact disc keeps its own surface
##   material), density: float (instances per 100 m2 of the row's place at full weight = per_100m2), scale: Vector2
##   (uniform scale range), vis_end: float (visibility range end, fade 10 m), shadow: bool, variants: int (3)
## plus the hints path: String, id: StringName, cluster: float, place: StringName, gap: float (0 = none).
## Rows whose mesh file is missing are skipped (never a null mesh).
static func items() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e: Dictionary in ENTRIES:
		var path: String = e["mesh"]
		if not ResourceLoader.exists(path):
			push_warning("snow_set: missing mesh %s" % path)
			continue
		var mesh := load(path) as Mesh
		if mesh == null:
			continue
		out.append({
			"mesh": mesh,
			"material": mesh.surface_get_material(0),
			"density": float(e["per_100m2"]),
			"scale": e["scale"] as Vector2,
			"vis_end": float(e["range"]),
			"shadow": bool(e["shadow"]),
			"variants": int(e.get("variants", VARIANTS)),
			"path": path,
			"id": e["id"] as StringName,
			"cluster": float(e["cluster"]),
			"place": e["place"] as StringName,
			"gap": float(e.get("gap", 0.0)),
		})
	return out
