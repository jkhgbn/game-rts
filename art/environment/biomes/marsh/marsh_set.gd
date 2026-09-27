class_name MarshSet
extends RefCounted
## Marsh decor set (task 12b.V5; terrain.md 2 "Marsh" (mud), 4.2 the 4 patches at both fords, 7.2 row 12b.V5). Pure
## data for the terrain decor scatter (12b.V6, MapDressingArt reading TerrainSystem.patches() / the mask), no class
## dependency, the same format as the step-12 biome sets:
##     var set_script: GDScript = load("res://art/environment/biomes/marsh/marsh_set.gd")
##     set_script.ENTRIES / set_script.GROUND_TINT / set_script.BIOME_ID      (section-10 format, paths)
##     set_script.items()                                                     (loaded format, see below)
## Meshes (2 new kinds + 2 reused, terrain.md 7.2 "<= 2 new kinds"):
##   marsh_puddles.res  NEW, built by build_marsh.gd. A puddle decal: surface 0 = a flat bean-shaped pool (~1.9 x
##                      1.1 m, within PUDDLE_REACH of the origin, y 0.045, 66 triangles) drawn with the SHARED ford film
##                      art/environment/water/water_ford_mat.tres (water.gdshader `shallow` = 1: light water over
##                      painted pebbles and sand, a wet dark-earth rim, a broken light lip, slow caustics / ripples);
##                      surface 1 = a soft wet-mud halo round every pool (nature_contact_mat.tres, multiplied onto the
##                      ground, it melts the film's edge into the mud); surface 2 = small rim dressing in nature_mat.tres
##                      with the 3 variants of the variant mask (V0 pebbles + a rush tuft, V1 a sunken dead reed stalk
##                      + a sedge tuft, V2 a mossy stone + a floating duckweed mat). The film itself cannot use the
##                      variant mask (water.gdshader has none): its variety comes from the random yaw / scale and the
##                      film's world-space pattern (no two pools show the same pebbles).
##   marsh_rushes.res   NEW, built by build_marsh.gd (nature_mat.tres + contact disc): soft rush / sedge tussocks on
##                      mossy mud hummocks, 3 variants (big rush tussock / two small tussocks + snapped dry stalks /
##                      an arching sedge fan beside a half-sunk mossy stone). 0.4-0.85 m tall, darker and bluer than
##                      the riverbank reeds so the marsh reads as its own patch.
##   rb_cattails.res    REUSED 12.V7 riverbank cattails (brown heads + arching leaves, 3 variants, 1.0-1.35 m, stems
##                      rooted 0.5 m below the origin: fine on land). No new kind.
##   rb_reeds.res       REUSED 12.V7 riverbank reeds (plumes), a few, mostly on the edge. No new kind.
## No lights, nothing casts shadows (flat pools and knee-high plants).
## ENTRIES keys (the heath / riverbank keys):
##   mesh        mesh path (origin = where it touches the ground)
##   per_100m2   instances per 100 m2 of the entry's OWN placement zone (below), before Map detail Low (x0.5)
##   scale       uniform scale, random in [x, y]
##   cluster     0 = even sprinkle, 1 = everything in patches (~8 per patch, gaussian ~1.2 m; the marsh is small, so
##               a scatter may use ~5 per patch like the riverbank)
##   shadow      casts shadows (false for the whole set)
##   range       visibility range end in metres (fade 10 m): rushes 65 (small), puddles / cattails / reeds 90 (the
##               puddles and cattails ARE the marsh's read from the game camera; a puddle is 60 triangles of film)
##   place       &"marsh" = inside a marsh patch (terrain mask weight > 0.5, i.e. cells whose id is `mud`);
##               &"marsh_edge" = the patch's rim (mask weight 0.2-0.5), taken as the one-cell ring of land cells
##               round the mud cells on the 0.5 m TerrainSystem grid (8-neighbours; not water / ford / road; riverbank
##               cells count): ~11 m2 per patch. A scatter using a wider band should scale the edge rows by
##               0.5 m / its band width. terrain.md 7.2 place values.
##   gap         (optional, puddles) minimum distance in metres between two instances of this entry. REQUIRED for
##               the puddles: two pools' films at the same height must never overlap (z-fight); 2.4 m = 2 x the
##               1.0 m film reach x the max scale 1.2. They need ~gap / 2 of clearance from roads and the ford.
## Placement notes for 12b.V6: a puddle's centre on a mud cell, and nothing within PUDDLE_REACH x scale of it over
## deep water (< 0.3 m from it), a road, or a ford circle + 0.5 m (its film would meet the river's / ford's film or sit
## in the ruts; and the shared film draws rapids foam within 0.5 m outside every ford circle it knows); spilling onto
## grass or the riverbank band is fine (the wet halo melts it in). The shared material also draws foam collars round
## its `foam_rocks` (bridge piers, stones): the marsh patches are far from all of them. Instance y = 0 (the meshes
## carry their own heights). Nothing needs clearing for units: all of it is walk-through decor.
## Budget (terrain.md 7.2: marsh 300 instances): the 4 patches hold ~72 m2 of `mud` cells once the riverbank (3 m
## from deep water) and the fords take their share, + ~44 m2 of edge ring; sum per_100m2 (marsh) 105 + (edge) 120
## -> ~128 instances before the puddle gap (~100 placed in marsh_preview.gd mode=map); tests/test_12b_v5.gd computes it
## from terrain.md 4.2 with the 4.1 priorities. Mesh kinds: +2 (marsh_puddles, marsh_rushes) of the +8 terrain.md 10
## grants.

const BIOME_ID := &"marsh"
## Wet dark mud (terrain.md 7.1 marsh layer `(0.24, 0.18, 0.11)`): the ground colour the set is dressed for.
const GROUND_TINT := Color(0.24, 0.18, 0.11)
const MESH_DIR := "res://art/environment/biomes/marsh/"
const INSTANCE_BUDGET := 300
## Shape variants per mesh (nature_painted.gdshader variant mask; the puddle film has one shape, its rim dressing 3).
const VARIANTS := 3
const PUDDLES := "res://art/environment/biomes/marsh/marsh_puddles.res"
const RUSHES := "res://art/environment/biomes/marsh/marsh_rushes.res"
const CATTAILS := "res://art/environment/biomes/riverbank/rb_cattails.res"
const REEDS := "res://art/environment/biomes/riverbank/rb_reeds.res"
## The shared ford film the puddles use (surface 0 of marsh_puddles.res; never duplicated at runtime).
const WATER_MAT := "res://art/environment/water/water_ford_mat.tres"
## Furthest any part of the puddle film reaches from the mesh origin at scale 1 (m).
const PUDDLE_REACH := 1.0

const ENTRIES := [
	# Puddles: the marsh's light, glinting read from the game camera (3-5 per full patch).
	{"mesh": PUDDLES, "per_100m2": 30.0, "scale": Vector2(0.7, 1.2), "cluster": 0.0, "shadow": false,
		"range": 90.0, "place": &"marsh", "gap": 2.4},
	# Rush tussocks: dotted between the pools, thicker along the rim.
	{"mesh": RUSHES, "per_100m2": 40.0, "scale": Vector2(0.8, 1.3), "cluster": 0.5, "shadow": false,
		"range": 65.0, "place": &"marsh"},
	{"mesh": RUSHES, "per_100m2": 70.0, "scale": Vector2(0.7, 1.05), "cluster": 0.4, "shadow": false,
		"range": 65.0, "place": &"marsh_edge"},
	# Cattail stands: tall brown-headed verticals in a few clumps (open mud and water between them).
	{"mesh": CATTAILS, "per_100m2": 30.0, "scale": Vector2(0.8, 1.15), "cluster": 0.85, "shadow": false,
		"range": 90.0, "place": &"marsh"},
	{"mesh": CATTAILS, "per_100m2": 30.0, "scale": Vector2(0.75, 1.05), "cluster": 0.6, "shadow": false,
		"range": 90.0, "place": &"marsh_edge"},
	# Reeds: a few plumes, mostly where the marsh meets the grass.
	{"mesh": REEDS, "per_100m2": 5.0, "scale": Vector2(0.7, 1.0), "cluster": 0.5, "shadow": false,
		"range": 90.0, "place": &"marsh"},
	{"mesh": REEDS, "per_100m2": 20.0, "scale": Vector2(0.7, 1.0), "cluster": 0.5, "shadow": false,
		"range": 90.0, "place": &"marsh_edge"},
]


## The same entries as loaded resources (the shared format of every biome set, 12.V7-12.V12). Keys:
##   mesh: Mesh, material: Material (surface 0's shared material: water_ford_mat.tres for the puddles, nature_mat.tres
##   for the plants; the other surfaces keep their own), density: float (instances per 100 m2 of the place zone =
##   per_100m2), scale: Vector2, vis_end: float (= range, fade margin 10 m), shadow: bool, variants: int (3).
## Plus the optional hints of ENTRIES when present: path, cluster, place, gap.
## One item per ENTRIES row (a reused mesh appears once per place). Rows whose mesh fails to load are skipped
## (push_warning).
static func items() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e: Dictionary in ENTRIES:
		var path: String = e["mesh"]
		var mesh: Mesh = load(path) as Mesh if ResourceLoader.exists(path) else null
		if mesh == null:
			push_warning("MarshSet: mesh missing %s" % path)
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
		for k: String in ["cluster", "place", "gap", "yaw", "yaw_jitter", "y"]:
			if e.has(k):
				d[k] = e[k]
		out.append(d)
	return out
