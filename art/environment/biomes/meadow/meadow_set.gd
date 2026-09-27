class_name MeadowSet
extends RefCounted
## Hearth Meadow decor set (task 12.V8; map-fill.md 3.1 biome 4 and section 10 "Biome set files"). Pure data for the
## biome scatter (12.V6, MapDressingArt / BiomeMap), no class dependency: read it with
##     var set_script: GDScript = load("res://art/environment/biomes/meadow/meadow_set.gd")
##     set_script.ENTRIES / set_script.GROUND_TINT / set_script.BIOME_ID
## Meshes: art/environment/biomes/meadow/meadow_*.res, built by build_meadow.gd with the shared nature_mat.tres
## (nature_painted.gdshader: vertex wind, 3 shape variants per mesh picked from the instance position, so place
## them with ONE MultiMesh per mesh and chunk, random yaw, uniform scale, y = 0). Hay and fruit bushes have a second
## surface (the soft contact disc, nature_contact_mat.tres).
## Entry keys:
##   mesh       mesh path
##   per_100m2  instances per 100 m2 at full meadow weight (scale it by the biome weight inside the 4 m blend)
##   scale      uniform scale, random in [x, y]
##   cluster    0 = even sprinkle, 1 = everything in patches: a fraction `cluster` of the instances go into patches
##              (about 8 per patch, gaussian spread ~1.2 m around the patch centre), the rest is even
##   shadow     casts shadows (only the hay, a big log-like prop with few instances)
##   range      visibility range end in metres (fade 10 m): tufts / flowers 65, bushes / hay 90 (map-fill.md 9)
##   place      &"land" (open ground; the set has no bank / water / under-tree pieces)
##   gap        (optional, the two big props only) minimum distance in metres between two instances of this entry,
##              and the clearance it needs from roads / slots / buildings is about gap / 2 (hay ~1.2 m, bush ~0.9 m)
## Footprints: tufts ~0.8 m, clover mats ~0.9 m, flower drifts ~0.95 m, fruit bush ~1.8 m (1.3-1.5 m tall), hay
## ~2.5 m (round bale 1.2 m tall, bale stack 0.9 m, haystack 2.5 m to the pole tip).
## Budget (map-fill.md 10: meadow <= 1 800 instances): sum per_100m2 = 52 -> at most ~1 280 instances on the
## ~2 460 m2 (weighted, both hubs, 22 m + the 4 m blend) left after the base paving and the lane (tests/test_12_v8.gd);
## ~1 010 once roads, trees, crystals and buildings are cleared too (meadow_preview.gd mode=map on the skirmish map).

const BIOME_ID := &"meadow"
## Ground tint for the biome mask (12.V2 `biome_tints`): a short, bright, slightly yellow lawn.
const GROUND_TINT := Color(0.40, 0.56, 0.20)
const MESH_DIR := "res://art/environment/biomes/meadow/"

const ENTRIES := [
	{"mesh": "res://art/environment/biomes/meadow/meadow_tufts.res", "per_100m2": 30.0, "scale": Vector2(0.8, 1.3),
		"cluster": 0.5, "shadow": false, "range": 65.0, "place": &"land"},
	{"mesh": "res://art/environment/biomes/meadow/meadow_clover.res", "per_100m2": 10.0, "scale": Vector2(0.8, 1.3),
		"cluster": 0.75, "shadow": false, "range": 65.0, "place": &"land"},
	{"mesh": "res://art/environment/biomes/meadow/meadow_daisies.res", "per_100m2": 6.0, "scale": Vector2(0.85, 1.2),
		"cluster": 0.85, "shadow": false, "range": 65.0, "place": &"land"},
	{"mesh": "res://art/environment/biomes/meadow/meadow_dandelions.res", "per_100m2": 4.5,
		"scale": Vector2(0.85, 1.2), "cluster": 0.8, "shadow": false, "range": 65.0, "place": &"land"},
	{"mesh": "res://art/environment/biomes/meadow/meadow_fruit_bush.res", "per_100m2": 1.0,
		"scale": Vector2(0.85, 1.15), "cluster": 0.3, "shadow": false, "range": 90.0, "place": &"land", "gap": 2.5},
	{"mesh": "res://art/environment/biomes/meadow/meadow_hay.res", "per_100m2": 0.45, "scale": Vector2(0.9, 1.1),
		"cluster": 0.5, "shadow": true, "range": 90.0, "place": &"land", "gap": 3.5},
]
