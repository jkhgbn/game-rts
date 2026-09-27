class_name SandSet
extends RefCounted
## Sand decor set (task 12b.V3; terrain.md 7.2 row 12b.V3 "sand": dry tussock grass, half-buried pale stones / old
## bones, <= 400 instances; the 4 sand patches of terrain.md 4.2: Millwatch / Saltwatch Terrace and Heron / Lantern
## Dunes). Pure data for the terrain scatter (12b.V6, MapDressingArt reads TerrainSystem.patches() / the mask), no class
## dependency:
##     var set_script: GDScript = load("res://art/environment/biomes/sand/sand_set.gd")
##     set_script.ENTRIES / set_script.GROUND_TINT / set_script.BIOME_ID      (map-fill.md section-10 format, paths)
##     set_script.items()                                                     (loaded format, see below)
## Meshes: art/environment/biomes/sand/sand_*.res, built by build_sand.gd with the shared nature_mat.tres
## (nature_painted.gdshader: vertex wind, 3 shape variants per mesh picked from the instance position, so place them
## with ONE MultiMesh per mesh and chunk, uniform scale, random yaw, y = 0, no collider):
##   sand_tussock  dry tussock grass: V0 round fountain tussock, V1 stiff marram tuft with seed spikes, V2 wind-beaten
##                 low tussock lying flat (sage-olive heart, straw / bleached / rust tips; wind)       1 surface
##   sand_bones    half-buried pale stones / old bones: V0 banded limestone outcrop, V1 a beast's rib cage arching
##                 out of the sand (~1 m tall), V2 a horned skull + thigh bone + pale stone            2 surfaces
##                 (surface 1 = the soft contact disc, nature_contact_mat.tres)
## No lights. Tussocks cast no shadow; the stones / bones are the set's "rocks" (terrain.md 7.2: "no shadows except
## stumps and rocks") and cast one, range 90 m.
## ENTRIES keys (map-fill.md 10 + the heath / old wood optional keys):
##   id          short name (&"tussock", &"tussock_edge", &"bones")
##   mesh        mesh path (origin = where it touches the sand)
##   per_100m2   instances per 100 m2 of the entry's `place` area
##   scale       uniform scale, random in [x, y]
##   cluster     0 = even sprinkle, 1 = everything in patches (~8 per patch, gaussian ~1.2 m, x2 for `gap` entries)
##   shadow      casts shadows
##   range       visibility range end in metres (fade 10 m): tussocks 65 (small), stones / bones 90 (terrain.md 7.2)
##   place       &"sand" = inside a sand patch (terrain mask sand weight > 0.5); &"sand_edge" = the rim where the sand
##               fades into the grass (weight 0.2-0.5): the tussock fringe that stitches the patch to the meadow
##   gap         (bones) minimum distance in metres between two instances; clearance ~gap / 2 from roads / slots /
##               buildings
##   variants    3
## Footprints: tussock ~0.95 m (0.53 m tall; the marram tuft's seed spikes to 0.94 m), stones ~2.0 m incl. pebbles
## (0.45 m tall), rib cage ~2.3 x 1.3 m (1.04 m tall), skull group ~1.6 x 1.4 m (0.58 m tall at the horn tips).
## Budget (terrain.md 7.2: sand <= 400 instances): the 4 patches (6 x 5 / 5 x 6 m ellipses, 1 m noisy edge) hold about
## 376 m2 at weight > 0.5 and ~62 m2 of 0.2-0.5 rim; the densities below ask for ~321 instances there before roads,
## slots and buildings are cleared (tests/test_12b_v3.gd computes it from terrain.md 4.2's patch list); ~140 remain on
## the skirmish map once roads, the watchtower capture points and the Colossus / Roc lair are cleared
## (sand_preview.gd mode=map).

const BIOME_ID := &"sand"
## Mid-tone of the sand layer (terrain.md 7.1 light (0.86, 0.74, 0.50) / dark (0.66, 0.52, 0.32); minimap sand
## (0.85, 0.75, 0.50)). The ground shader paints the sand itself from the terrain mask; this is the set's reference
## colour for tools and tints.
const GROUND_TINT := Color(0.78, 0.66, 0.43)
const MESH_DIR := "res://art/environment/biomes/sand/"
const INSTANCE_BUDGET := 400
## Shape variants per mesh (nature_painted.gdshader variant mask).
const VARIANTS := 3

const ENTRIES := [
	{"id": &"tussock", "mesh": "res://art/environment/biomes/sand/sand_tussock.res", "per_100m2": 46.0,
		"scale": Vector2(0.85, 1.3), "cluster": 0.55, "shadow": false, "range": 65.0, "place": &"sand", "variants": 3},
	{"id": &"tussock_edge", "mesh": "res://art/environment/biomes/sand/sand_tussock.res", "per_100m2": 190.0,
		"scale": Vector2(0.9, 1.35), "cluster": 0.3, "shadow": false, "range": 65.0, "place": &"sand_edge",
		"variants": 3},
	{"id": &"bones", "mesh": "res://art/environment/biomes/sand/sand_bones.res", "per_100m2": 8.0,
		"scale": Vector2(0.8, 1.2), "cluster": 0.2, "shadow": true, "range": 90.0, "place": &"sand", "variants": 3,
		"gap": 2.6},
]


## The same entries as loaded resources (the shared format of every biome set, 12.V7-12.V12). Keys:
##   mesh: Mesh, material: Material (surface 0's shared nature_mat.tres; the contact disc keeps its own surface
##   material), density: float (instances per 100 m2 = per_100m2), scale: Vector2, vis_end: float (= range, fade
##   margin 10 m), shadow: bool, variants: int (3).
## Plus the optional hints of ENTRIES: path, id, cluster, place, gap (0 = none).
## The tussock mesh appears twice (inside and rim); both rows come out, each with its own place / density.
## Entries whose mesh fails to load are skipped (push_warning).
static func items() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e: Dictionary in ENTRIES:
		var path: String = e["mesh"]
		var mesh: Mesh = load(path) as Mesh if ResourceLoader.exists(path) else null
		if mesh == null:
			push_warning("SandSet: mesh missing %s" % path)
			continue
		out.append({
			"mesh": mesh,
			"material": mesh.surface_get_material(0),
			"density": float(e["per_100m2"]),
			"scale": e["scale"] as Vector2,
			"vis_end": float(e["range"]),
			"shadow": bool(e["shadow"]),
			"variants": VARIANTS,
			"path": path,
			"id": e["id"] as StringName,
			"cluster": float(e["cluster"]),
			"place": e["place"] as StringName,
			"gap": float(e.get("gap", 0.0)),
		})
	return out
