class_name HeathSet
extends RefCounted
## Heath decor set (task 12.V9; map-fill.md 3.1 biome 6 "Heath": `max(|x|, |z|) > 44`, the flanks by the posts; section
## 10 "Biome set files"). Pure data for the biome scatter (12.V6, MapDressingArt / BiomeMap), no class dependency:
##     var set_script: GDScript = load("res://art/environment/biomes/heath/heath_set.gd")
##     set_script.ENTRIES / set_script.GROUND_TINT / set_script.BIOME_ID      (section-10 format, paths)
##     set_script.items()                                                     (loaded format, see below)
## Meshes: art/environment/biomes/heath/heath_*.res, built by build_heath.gd with the shared nature_mat.tres
## (nature_painted.gdshader: vertex wind, 3 shape variants per mesh picked from the instance position, so place them
## with ONE MultiMesh per mesh and chunk, uniform scale, y = 0). Gorse and lichen stones have a second surface (the
## soft contact disc, nature_contact_mat.tres). No lights, nothing casts shadows (no trees / logs / big rocks here).
## ENTRIES keys:
##   mesh        mesh path (origin = where it touches the ground)
##   per_100m2   instances per 100 m2 at full heath weight (scale it by the biome weight inside the 4 m blend)
##   scale       uniform scale, random in [x, y]
##   cluster     0 = even sprinkle, 1 = everything in patches (a fraction `cluster` of the instances go into patches
##               of ~8, gaussian spread ~1.2 m around the patch centre, x2 for entries with a `gap`)
##   shadow      casts shadows (false for the whole set)
##   range       visibility range end in metres (fade 10 m): tall grass 65, heather / gorse / stones 90 (map-fill.md 9)
##   place       &"land" (open ground; the heath has no bank / water / under-tree pieces)
##   gap         (optional, gorse and stones) minimum distance in metres between two instances of this entry; they need
##               about gap / 2 of clearance from roads / slots / buildings
##   yaw         (optional, tall grass) fixed yaw in radians instead of a random one: it turns the mesh's local +X (the
##               way every blade is combed) to the shader's wind_dir (0.8, 0.6), so the whole heath leans one way and
##               the gusts push the bend further. `yaw_jitter` = random +- spread around it (radians). A scatter that
##               ignores both keys still looks fine (random yaw), just less windswept.
## Footprints: tall grass ~0.8 m (leans 0.5 m downwind, 0.6-0.94 m tall), heather cushions ~0.9-1.3 m (0.3-0.48 m tall),
## gorse ~1.4-2.0 m (0.8-1.5 m tall), lichen stones ~1.1-2.0 m incl. pebbles (0.6 m tall at most).
## Budget (map-fill.md 10: heath <= 1 600 instances): sum per_100m2 = 59.6 -> at most ~1 400 instances on the ~2 350 m2 of weighted heath;
## ~700 once roads, trade posts, trees, landmarks and buildings are cleared (heath_preview.gd mode=map); tests/test_12_v9.gd computes the weighted
## heath area of Crown Hollow (after ruins, riverbank, meadow and Old Wood take their share, lane and map edge out) and
## checks the instance count; heath_preview.gd mode=map scatters it on the real skirmish map.

const BIOME_ID := &"heath"
## Ground tint for the biome mask (12.V2 `biome_tints` slot 1): warm, dry, sun-bleached grass. The ground shader adds
## its own purple heather / yellow gorse blotches on top.
const GROUND_TINT := Color(0.52, 0.47, 0.25)
const MESH_DIR := "res://art/environment/biomes/heath/"
const INSTANCE_BUDGET := 1600
## Shape variants per mesh (nature_painted.gdshader variant mask).
const VARIANTS := 3
## Yaw (radians) that turns local +X to nature_painted.gdshader's default wind_dir (0.8, 0.6):
## Basis(Vector3.UP, WIND_YAW) * Vector3.RIGHT == Vector3(0.8, 0, 0.6).
const WIND_YAW := -0.6435

const ENTRIES := [
	{"mesh": "res://art/environment/biomes/heath/heath_tall_grass.res", "per_100m2": 36.0, "scale": Vector2(0.8, 1.25),
		"cluster": 0.6, "shadow": false, "range": 65.0, "place": &"land", "yaw": -0.6435, "yaw_jitter": 0.35},
	{"mesh": "res://art/environment/biomes/heath/heath_heather.res", "per_100m2": 18.0, "scale": Vector2(0.8, 1.35),
		"cluster": 0.8, "shadow": false, "range": 90.0, "place": &"land"},
	{"mesh": "res://art/environment/biomes/heath/heath_gorse.res", "per_100m2": 3.2, "scale": Vector2(0.85, 1.2),
		"cluster": 0.5, "shadow": false, "range": 90.0, "place": &"land", "gap": 2.2},
	{"mesh": "res://art/environment/biomes/heath/heath_lichen_stones.res", "per_100m2": 2.4,
		"scale": Vector2(0.75, 1.3), "cluster": 0.3, "shadow": false, "range": 90.0, "place": &"land", "gap": 1.8},
]


## The same entries as loaded resources (the shared format of every biome set, 12.V7-12.V12). Keys:
##   mesh: Mesh, material: Material (surface 0's shared nature_mat.tres; the contact disc keeps its own surface
##   material), density: float (instances per 100 m2 at full weight = per_100m2), scale: Vector2, vis_end: float
##   (= range, fade margin 10 m), shadow: bool, variants: int (3).
## Plus the optional hints of ENTRIES when present: path, cluster, place, gap, yaw, yaw_jitter.
## Entries whose mesh fails to load are skipped (push_warning).
static func items() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e: Dictionary in ENTRIES:
		var path: String = e["mesh"]
		var mesh: Mesh = load(path) as Mesh if ResourceLoader.exists(path) else null
		if mesh == null:
			push_warning("HeathSet: mesh missing %s" % path)
			continue
		var d := {
			"mesh": mesh,
			"material": mesh.surface_get_material(0),
			"density": float(e["per_100m2"]),
			"scale": e["scale"] as Vector2,
			"vis_end": float(e["range"]),
			"shadow": bool(e["shadow"]),
			"variants": VARIANTS,
			"path": path,
		}
		for k: String in ["cluster", "place", "gap", "yaw", "yaw_jitter"]:
			if e.has(k):
				d[k] = e[k]
		out.append(d)
	return out
