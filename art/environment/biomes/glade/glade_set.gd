extends RefCounted
## Wildflower Glade decor set (task 12.V11; map-fill.md 3.1 biome 7 "everything else (midfields)" and section 10).
## Pure data for the biome scatter (12.V6, MapDressingArt / BiomeMap), no class dependency (no class_name):
##     var set_script: GDScript = load("res://art/environment/biomes/glade/glade_set.gd")
##     var items: Array[Dictionary] = set_script.items()      # shared step-12 format, meshes / material loaded
##     set_script.ENTRIES / set_script.GROUND_TINT / set_script.BIOME_ID   # the map-fill.md section 10 constants
## Meshes: art/environment/biomes/glade/glade_*.res, built by build_glade.gd with the shared nature_mat.tres
## (nature_painted.gdshader: vertex wind, 3 shape variants per mesh picked from the instance position, so place
## them with ONE MultiMesh per mesh and chunk, random yaw, uniform scale, y = 0). The materials are already on the
## mesh surfaces: do NOT set `material` as a material_override (the butterfly bush has a second surface, its soft
## contact disc with nature_contact_mat.tres, which the override would break).
##
## items() keys (the shared format read by 12.V6):
##   mesh      Mesh (ArrayMesh, indexed, 0 lights)
##   material  Material: nature_mat.tres (surface 0 of every mesh; informative, see above)
##   density   instances per 100 m2 at full glade weight (scale it by the biome weight inside the 4 m blend)
##   scale     uniform scale, random in [x, y]
##   vis_end   visibility range end in metres (fade margin 10 m): grass / flowers 65, bushes 90 (map-fill.md 9)
##   shadow    casts shadows: false for all three (small decor, map-fill.md 9)
##   variants  shape variants in the mesh (3, picked by the shader from the instance position)
##   optional hints (same meaning as the other sets' ENTRIES): cluster (0 = even sprinkle, 1 = everything in
##   patches of ~8 instances, gaussian sigma ~1.2 m), place (&"land"), gap (minimum distance between two instances
##   of this item; also about the clearance it wants from roads / slots: gap / 2), name (mesh file base name)
##
## Readability: the glade is the midfield where armies meet, so it is the calmest of the dressed biomes. Tall grass
## (olive / straw, mean saturation 0.49 vs the lawn's 0.53, 0.65 m tall = 0.78 m at max scale, so a 1.2 m worker's
## head and shoulders stay clear) grows in patches with open lawn between them; flowers are small specks in drifts
## (never a solid colour field); butterfly bushes are rare (gap 4 m). Footprints: grass ~1.35 m, flowers ~0.9 m,
## bush ~2.1 m (1.66 m tall at scale 1). Triangles per drawn variant: grass <= 351, flowers <= 294, bush 948.
## Budget (map-fill.md 10: glade <= 1 800 instances): sum density = 29.7 -> ~930 instances on the ~3 150 m2 of glade
## (weighted, both halves) left after the river, banks, isle, meadows, Old Wood, heath and the lane
## (tests/test_12_v11.gd computes it); fewer once roads, slots, trees and buildings are cleared too.

const BIOME_ID := &"glade"
## Ground tint for the biome mask: the glade keeps today's lawn (12.V2: "glade = today"), so 12.V2 gives it no tint
## slot; this is that lawn's mid colour (ground.gdshader grass_dark .. grass_light), for tools that want one.
const GROUND_TINT := Color(0.27, 0.38, 0.18)
const MESH_DIR := "res://art/environment/biomes/glade/"
const NATURE_MAT := "res://art/environment/nature_props/nature_mat.tres"
const VARIANTS := 3
const INSTANCE_BUDGET := 1800

const ENTRIES := [
	# Tall wild grass in patches (V0 upright + foxtails, V1 arching fountain, V2 wind-bent + bronze plumes).
	{"mesh": "res://art/environment/biomes/glade/glade_tall_grass.res", "per_100m2": 20.0, "scale": Vector2(0.8, 1.2),
		"cluster": 0.9, "shadow": false, "range": 65.0, "place": &"land"},
	# Wildflower drifts, 4 colours over the 3 variants (red poppy + yellow, blue cornflower + pink, pink campion mix).
	{"mesh": "res://art/environment/biomes/glade/glade_flowers.res", "per_100m2": 9.0, "scale": Vector2(0.85, 1.2),
		"cluster": 0.8, "shadow": false, "range": 65.0, "place": &"land"},
	# Butterfly bushes (lilac / magenta / white spikes), rare, never touching each other.
	{"mesh": "res://art/environment/biomes/glade/glade_butterfly_bush.res", "per_100m2": 0.7,
		"scale": Vector2(0.85, 1.1), "cluster": 0.2, "shadow": false, "range": 90.0, "place": &"land", "gap": 4.0},
]


## The set in the shared step-12 format (see the header). Loads the meshes and the material.
static func items() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var mat: Material = load(NATURE_MAT) as Material
	for e: Dictionary in ENTRIES:
		var path: String = e["mesh"]
		if not ResourceLoader.exists(path):
			push_warning("glade_set: missing mesh %s" % path)
			continue
		var mesh: Mesh = load(path) as Mesh
		out.append({
			"mesh": mesh,
			"material": mat,
			"density": float(e["per_100m2"]),
			"scale": e["scale"] as Vector2,
			"vis_end": float(e["range"]),
			"shadow": bool(e["shadow"]),
			"variants": VARIANTS,
			"cluster": float(e["cluster"]),
			"place": e["place"],
			"gap": float(e.get("gap", 0.0)),
			"name": path.get_file().get_basename(),
		})
	return out
