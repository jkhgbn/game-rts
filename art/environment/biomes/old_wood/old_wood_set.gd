extends RefCounted
## Old Wood decor set (task 12.V10; map-fill.md 3.1 biome 5 "Old Wood": within 28 m of (-50, -50) / (50, 50), dark
## forest floor, needles, moss). Pure data for the biome scatter (12.V6, MapDressingArt / BiomeMap); no class
## dependency, so read it with load():
##     var set_script: GDScript = load("res://art/environment/biomes/old_wood/old_wood_set.gd")
##     for item: Dictionary in set_script.items(): ...          (loaded meshes / materials, the 12.V6 format)
##     set_script.ENTRIES / set_script.GROUND_TINT / set_script.BIOME_ID   (the map-fill.md section 10 constants)
## Meshes (built by build_old_wood.gd; ONE surface and ONE material each, so the mesh's own material and a
## material_override give the same result; 3 shape variants per mesh picked by the shader from the instance position
## (the variant mask of nature_painted.gdshader): place them with ONE MultiMesh per mesh and chunk, random yaw,
## uniform scale, y = 0, no collider):
##   ow_ferns          dark ferns ~1.7 m (lady fern / shuttlecock fern / bracken)          nature_mat.tres, wind
##   ow_glowcaps       blue-cap glow mushroom clusters ~0.8-1.1 m      old_wood_glow_mat.tres (emission 1.8, no lights)
##   ow_moss_boulders  moss-capped boulders ~1.6-2 m, 0.6-0.85 m tall                      nature_mat.tres, shadows
##   ow_fallen_trunk   fallen trunks ~4.5 m (root plate to 1.3 m / broken / leaning)       nature_mat.tres, shadows
##   ow_roots          surface roots ~2 m (arches / root knot round a stub / root loop)    nature_mat.tres
##   ow_cobwebs        cobweb cards on dead twigs (snag / bramble hoop / ground sheet web)  old_wood_web_mat.tres
## Budget (map-fill.md 9 / 10): 6 mesh kinds; Old Wood <= 900 instances. Sum of density = 23.0 per 100 m2 on the
## ~2 680 m2 (weighted, both woods, 4 m blend, riverbank removed, before roads / buildings / nodes are cleared:
## tests/test_12_v10.gd) -> ~620 instances at most; ~420 once the scatter clears roads, the lane, slots, crystal
## nodes, trees and buildings (old_wood_preview.gd mode=map on the skirmish map).
## Shadows only on the fallen trunks and boulders (map-fill.md 9: logs / big rocks). Ranges: ferns / mushrooms /
## roots 90 m, cobwebs 65 m (small), trunks / boulders 110 m (big pieces pop less when they fade late).

const BIOME_ID := &"old_wood"
## Dark forest floor (12.V2 biome_tints slot 2): a cool, dark moss green with a little needle brown.
const GROUND_TINT := Color(0.19, 0.21, 0.12)
const DIR := "res://art/environment/biomes/old_wood/"
const INSTANCE_BUDGET := 900

## map-fill.md section 10 format (keys: mesh path, per_100m2, scale, cluster, shadow, range, place) + optional keys:
##   id        a short name (terrain.md 12b.V6 doubles the "ferns" density in the forest thickets)
##   gap       minimum distance in metres between two instances of this entry (big pieces); clearance from roads /
##             slots / buildings about gap / 2
##   variants  shape variants in the mesh (3: the shader picks one from the instance position)
## `cluster`: 0 = even sprinkle, 1 = everything in patches (~8 per patch, gaussian sigma ~1.2 m; x2 for gap entries).
const ENTRIES := [
	{"id": &"ferns", "mesh": "res://art/environment/biomes/old_wood/ow_ferns.res", "per_100m2": 13.0,
		"scale": Vector2(0.95, 1.4), "cluster": 0.7, "shadow": false, "range": 90.0, "place": &"land", "variants": 3},
	{"id": &"glowcaps", "mesh": "res://art/environment/biomes/old_wood/ow_glowcaps.res", "per_100m2": 4.6,
		"scale": Vector2(0.9, 1.35), "cluster": 0.75, "shadow": false, "range": 90.0, "place": &"land", "variants": 3},
	{"id": &"roots", "mesh": "res://art/environment/biomes/old_wood/ow_roots.res", "per_100m2": 2.0,
		"scale": Vector2(0.8, 1.3), "cluster": 0.3, "shadow": false, "range": 90.0, "place": &"land", "variants": 3,
		"gap": 1.5},
	{"id": &"cobwebs", "mesh": "res://art/environment/biomes/old_wood/ow_cobwebs.res", "per_100m2": 1.6,
		"scale": Vector2(0.85, 1.25), "cluster": 0.4, "shadow": false, "range": 65.0, "place": &"land", "variants": 3},
	{"id": &"moss_boulders", "mesh": "res://art/environment/biomes/old_wood/ow_moss_boulders.res", "per_100m2": 1.4,
		"scale": Vector2(0.75, 1.15), "cluster": 0.3, "shadow": true, "range": 110.0, "place": &"land", "variants": 3,
		"gap": 3.0},
	{"id": &"fallen_trunk", "mesh": "res://art/environment/biomes/old_wood/ow_fallen_trunk.res", "per_100m2": 0.4,
		"scale": Vector2(0.85, 1.15), "cluster": 0.0, "shadow": true, "range": 110.0, "place": &"land", "variants": 3,
		"gap": 7.0},
]


## The set in the 12.V6 scatter format (shared with the heath / glade / ruins sets): one Dictionary per mesh kind
##   mesh: Mesh, material: Material (the mesh's only surface material), density: float (instances per 100 m2 at full
##   biome weight), scale: Vector2 (uniform scale range), vis_end: float (visibility range end, fade 10 m),
##   shadow: bool, variants: int (3)
## plus the optional hints id: StringName, cluster: float, place: StringName, gap: float (0 = none).
## Entries whose mesh file is missing are skipped (never a null mesh).
static func items() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e: Dictionary in ENTRIES:
		var path: String = e["mesh"]
		if not ResourceLoader.exists(path):
			push_warning("old_wood_set: missing mesh %s" % path)
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
			"variants": int(e.get("variants", 3)),
			"id": e["id"] as StringName,
			"cluster": float(e["cluster"]),
			"place": e["place"] as StringName,
			"gap": float(e.get("gap", 0.0)),
		})
	return out
