extends RefCounted
## Crown Isle ruins decor set (task 12.V12; map-fill.md 3.1 biome 3 "Crown Isle ruins" and section 10 "Biome set
## files"). Pure data for the biome scatter (12.V6, MapDressingArt / BiomeMap), no class dependency: load() it, then
##     var set_script: GDScript = load("res://art/environment/biomes/ruins/ruins_set.gd")
##     for item: Dictionary in set_script.items(): ...          # the shared step-12 format (meshes loaded)
##     set_script.ENTRIES / set_script.BIOME_ID / set_script.GROUND_TINT   # the map-fill.md section 10 format (paths)
## Both describe the same 4 kinds. Meshes: art/environment/biomes/ruins/ruins_*.res, built by build_ruins.gd. Stone,
## iron and grass use the shared nature_mat.tres (nature_painted.gdshader); the ember moss uses ruins_ember_mat.tres
## (emission only, no lights). Every mesh has ONE surface whose material is the item's `material` (so that material is
## also safe as a material_override; any OTHER override material must repeat the shaders' variant collapse, or all 3
## variants draw on top of each other) and 3 shape variants picked by the shader from the instance position: place ONE
## MultiMesh per kind and chunk, random yaw, uniform scale, y = 0. No colliders: everything is decor the units walk
## through (meshes: flagstones <= 0.3 m, drums / moss <= 0.38 m, plinths and the brazier <= 0.85 m; `max_height`
## = mesh top x the largest scale, drums stay < 0.4 m as map-fill.md 3.1 asks).
## The existing art/environment/meshes/crown_ruin_dressing.res (rubble ring round the crown, fallen drums at r 10.2)
## stays as it is; this set adds to it.
##
## items() keys (shared format read by 12.V6):
##   mesh      Mesh
##   material  Material (surface 0 of the mesh)
##   density   instances per 100 m2 at full ruins weight (scale it by the biome weight inside the blend)
##   scale     uniform scale, random in [x, y]
##   vis_end   visibility range end in metres (fade margin 10 m): small pieces 65, bigger 90 (map-fill.md 9)
##   shadow    casts shadows (only the plinths / brazier, the one big item)
##   variants  shape variants inside the mesh (3; the shader picks one per instance position)
## Optional extra keys (a reader may ignore them): id, cluster (0 = even sprinkle .. 1 = all in patches of ~6 round a
## seed point, gaussian ~1.2 m), gap (min distance between two instances of this kind, m; clearance from roads / slots /
## the lane ~0.6 m more than the small pieces), place (&"land"), paving_ok, max_height (m), lane_clear_paving (m, flat
## kinds only: on the kind-1 paving they may come this close to the lane line instead of LANE_CLEAR 5.2, since units
## walk over them; the isle's inner plaza lies almost entirely inside the 5.2 m corridor).
##
## Where (map-fill.md 3.1): the ruins zone = the Crown Isle (r < 11) + 3 m around the Fallen Colossus, the Giant's
## Stump and the Standing Stones (GroundParams.RUINS). IMPORTANT for 12.V6: the isle is the skirmish's paved spot kind 1
## (Skirmish spot `(0, 0, PILLAR_RING + 1.5 = 9.5, 1)`), which MapDressingArt._blocked() keeps decor-free: ruins items
## have `paving_ok = true` and must be allowed on kind-1 paving (still off the lane corridor (flat kinds: `lane_clear_paving`
## there), off crossings, off the crown dais r < ISLE_DAIS_CLEAR and >= PILLAR_CLEAR m from each pillar). Everything
## else in _blocked() applies. The ruins zone wins over every other biome (GroundParams: first match wins, ruins first).
## Budget (map-fill.md 10: ruins <= 300 instances): sum density 34 -> <= ~290 instances on Crown Hollow's ruins zone
## (weighted, lane / dais / landmark footprints removed; tests/test_12_v12.gd); ~170 once pillars, crossings, roads,
## trees and rocks are cleared too (ruins_preview.gd mode=map on the skirmish map: 70 flagstones, 69 moss, 22 drums,
## 6 monuments; GPU cost within noise, <= ~0.15 ms at 40 m over the isle on the GTX 1660).

const BIOME_ID := &"ruins"
## Ember-scorched grass (the ruins ground itself is the painted flagstone spot + GroundParams.RUINS circles; this tint is
## for a reader that wants one colour for the zone, e.g. a minimap or a future biome_tints slot).
const GROUND_TINT := Color(0.36, 0.34, 0.17)
const DIR := "res://art/environment/biomes/ruins/"
const NATURE_MAT := "res://art/environment/nature_props/nature_mat.tres"
const EMBER_MAT := "res://art/environment/biomes/ruins/ruins_ember_mat.tres"
const INSTANCE_BUDGET := 300
const VARIANTS := 3
## Keep the crown's dais, fang monoliths and rune stones (r 2.3-3.1) and the wardens' feet clear.
const ISLE_DAIS_CLEAR := 3.8
## Clearance round each pillar of the crown ring (r 8, collider r 0.7).
const PILLAR_CLEAR := 1.2
## Lane clearance of the flat kinds (flagstones, ember moss) on the kind-1 paving (see lane_clear_paving).
const LANE_CLEAR_FLAT := 2.6

const ENTRIES := [
	# Broken flagstones lifted off the paving: the main mass of the set.
	{"id": &"flagstones", "mesh": "res://art/environment/biomes/ruins/ruins_flagstones.res", "material": NATURE_MAT,
		"per_100m2": 15.0, "scale": Vector2(0.9, 1.4), "cluster": 0.45, "shadow": false, "range": 65.0,
		"place": &"land", "paving_ok": true, "max_height": 0.4, "lane_clear_paving": LANE_CLEAR_FLAT},
	# Ember moss patches (faint orange smoulder), in loose patches.
	{"id": &"ember_moss", "mesh": "res://art/environment/biomes/ruins/ruins_ember_moss.res", "material": EMBER_MAT,
		"per_100m2": 13.0, "scale": Vector2(0.8, 1.25), "cluster": 0.6, "shadow": false, "range": 65.0,
		"place": &"land", "paving_ok": true, "max_height": 0.48, "lane_clear_paving": LANE_CLEAR_FLAT},
	# Low column drums (walk-through, < 0.4 m).
	{"id": &"drums", "mesh": "res://art/environment/biomes/ruins/ruins_drums.res", "material": NATURE_MAT,
		"per_100m2": 4.5, "scale": Vector2(0.85, 1.05), "cluster": 0.2, "shadow": false, "range": 90.0,
		"place": &"land", "paving_ok": true, "max_height": 0.38, "gap": 1.6},
	# Cracked statue plinths (statue feet / split plinth) and cold braziers: the one big item, a few per zone.
	{"id": &"monuments", "mesh": "res://art/environment/biomes/ruins/ruins_monuments.res", "material": NATURE_MAT,
		"per_100m2": 1.5, "scale": Vector2(0.9, 1.1), "cluster": 0.0, "shadow": true, "range": 90.0,
		"place": &"land", "paving_ok": true, "max_height": 0.94, "gap": 4.0},
]


## The shared step-12 decor format: one Dictionary per kind with the mesh and material LOADED.
static func items() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e: Dictionary in ENTRIES:
		var mesh := load(String(e["mesh"])) as Mesh
		var material := load(String(e["material"])) as Material
		if mesh == null or material == null:
			push_warning("ruins_set: missing %s / %s" % [e["mesh"], e["material"]])
			continue
		out.append({
			"mesh": mesh,
			"material": material,
			"density": float(e["per_100m2"]),
			"scale": e["scale"] as Vector2,
			"vis_end": float(e["range"]),
			"shadow": bool(e["shadow"]),
			"variants": VARIANTS,
			"id": e["id"],
			"cluster": float(e["cluster"]),
			"gap": float(e.get("gap", 0.0)),
			"place": e["place"],
			"paving_ok": true,
			"max_height": float(e["max_height"]),
			"lane_clear_paving": float(e.get("lane_clear_paving", 0.0)),
		})
	return out
