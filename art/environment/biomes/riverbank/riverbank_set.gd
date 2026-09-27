extends RefCounted
## Riverbank biome decor set (map-fill.md 3.1 biome 2 "Riverbank" + the water biome's reeds / lily pads; task 12.V7).
## Read by MapDressingArt / BiomeMap (12.V6). No class dependency: load() it and read the constants.
## Meshes are built by build_riverbank.gd with the shared nature_mat.tres (wind in the vertex shader, 3 shape
## variants per mesh picked by the shader from the instance position: one MultiMesh per mesh and chunk shows all 3).
##
## ENTRIES keys (map-fill.md section 10 format, plus optional hints this set uses):
##   mesh        res path of the mesh (origin = where it touches the ground / the water surface)
##   per_100m2   instances per 100 m2 of the entry's OWN placement zone (below), before Map detail Low (x0.5)
##   scale       uniform scale range (min, max); yaw is free (random)
##   cluster     0 = even sprinkle, 1 = tight patches (clumps of 3-6 around a seed point)
##   shadow      casts shadows (map-fill.md 9: only logs / big rocks / trees do)
##   range       visibility range end in metres (fade 10 m)
##   place       &"bank" = land 0-2.5 m from the water edge; &"land" = the whole riverbank biome (land 0-6 m from the
##               water); &"water" = on the water surface (deep water, not fords / bridges)
##   y           (optional) instance height: WATER_Y (-0.35, RiverSystem.WATER_Y) for everything on the water; land
##               entries sit at y 0
##   shore       (optional, place &"water") only within this many metres of the water's edge (the channel middle
##               stays open; reeds hug the trench edge, lily pads the calm margins)
## Zone areas on Crown Hollow (both halves, rivers + moat, crossings removed; ~315 m of bank line): bank ~820 m2,
## land ~2 000 m2, water ~790 m2 (shore 0.7 m: ~220 m2, shore 1.8 m: ~650 m2). Expected total ~950 instances
## (budget 1 800; Map detail Low halves it).

const BIOME_ID := &"riverbank"
## Lush, cool, damp grass for the riverbank ground tint (12.V2 biome_tints); the wet earth -> sand band at the lip is
## the ground shader's own bank band.
const GROUND_TINT := Color(0.17, 0.32, 0.18)
const WATER_Y := -0.35
const INSTANCE_BUDGET := 1800

const ENTRIES := [
	# Reed clumps along the bank (the band's main mass) and a few further up the biome.
	{"mesh": "res://art/environment/biomes/riverbank/rb_reeds.res", "per_100m2": 40.0, "scale": Vector2(0.8, 1.25),
		"cluster": 0.75, "shadow": false, "range": 90.0, "place": &"bank"},
	{"mesh": "res://art/environment/biomes/riverbank/rb_reeds.res", "per_100m2": 5.0, "scale": Vector2(0.7, 1.05),
		"cluster": 0.6, "shadow": false, "range": 90.0, "place": &"land"},
	# Reeds standing in the water at the trench edge (stems reach 0.5 m below their origin: no floating clumps).
	{"mesh": "res://art/environment/biomes/riverbank/rb_reeds.res", "per_100m2": 30.0, "scale": Vector2(0.85, 1.2),
		"cluster": 0.7, "shadow": false, "range": 90.0, "place": &"water", "y": -0.35, "shore": 0.7},
	# Cattails: bank and water edge.
	{"mesh": "res://art/environment/biomes/riverbank/rb_cattails.res", "per_100m2": 16.0, "scale": Vector2(0.85, 1.2),
		"cluster": 0.8, "shadow": false, "range": 90.0, "place": &"bank"},
	{"mesh": "res://art/environment/biomes/riverbank/rb_cattails.res", "per_100m2": 10.0, "scale": Vector2(0.85, 1.15),
		"cluster": 0.8, "shadow": false, "range": 90.0, "place": &"water", "y": -0.35, "shore": 0.7},
	# Lily pads (with white / pink flowers and buds) on the calm margins.
	{"mesh": "res://art/environment/biomes/riverbank/rb_lily_pads.res", "per_100m2": 15.0, "scale": Vector2(0.8, 1.3),
		"cluster": 0.85, "shadow": false, "range": 65.0, "place": &"water", "y": -0.35, "shore": 1.8},
	# River-worn stones at the lip, a few further up.
	{"mesh": "res://art/environment/biomes/riverbank/rb_river_stones.res", "per_100m2": 14.0,
		"scale": Vector2(0.7, 1.4), "cluster": 0.5, "shadow": false, "range": 65.0, "place": &"bank"},
	{"mesh": "res://art/environment/biomes/riverbank/rb_river_stones.res", "per_100m2": 3.0,
		"scale": Vector2(0.8, 1.3), "cluster": 0.3, "shadow": false, "range": 65.0, "place": &"land"},
	# Driftwood washed up on the bank (logs cast shadows).
	{"mesh": "res://art/environment/biomes/riverbank/rb_driftwood.res", "per_100m2": 1.6, "scale": Vector2(0.8, 1.15),
		"cluster": 0.0, "shadow": true, "range": 90.0, "place": &"bank"},
	{"mesh": "res://art/environment/biomes/riverbank/rb_driftwood.res", "per_100m2": 0.6, "scale": Vector2(0.8, 1.1),
		"cluster": 0.0, "shadow": true, "range": 90.0, "place": &"land"},
]

## The willow is a real tree (map-fill.md 2.5 / 3.1: mirrored, with a collider), placed by 12.C1 through
## EnvProps.add_tree_kind("tree_willow", pos, s), not by the decor scatter. Footprint like every tree:
## collider cylinder radius 0.45 s, height 2 (centre y 1), at the trunk foot (the mesh origin).
## tree_willow.res: 3 variants in one mesh (the shader picks one from the position hash: V0 classic weeping, V1 leaning
## over the water toward local +X with a deeper curtain there, V2 old pollard); tree_willow_v0/_v1/_v2.res = one
## variant each (for code that picks the variant itself); tree_willow_far.res = ~110-triangle stand-in (border /
## distant rings, "lite" shading, no contact disc).
const WILLOW := {
	"mesh": "res://art/environment/meshes/tree_willow.res",
	"variants": ["res://art/environment/meshes/tree_willow_v0.res", "res://art/environment/meshes/tree_willow_v1.res",
		"res://art/environment/meshes/tree_willow_v2.res"],
	"far": "res://art/environment/meshes/tree_willow_far.res",
	"collider_radius": 0.45,   # x s
	"collider_height": 2.0,
	"scale": Vector2(0.95, 1.2),
	## Trunk foot 1.5-4 m from the water edge: the crown (radius ~2.3 s, curtain hem 0.6-1.6 m above the ground)
	## overhangs the water; keep >= 3 m from crossings so the curtain never hides a bridge / ford entrance.
	"water_distance": Vector2(1.5, 4.0),
	## Optional: yaw so local +X points at the nearest water (the crown and V1's lean hang over the river).
	"lean_axis": Vector3(1, 0, 0),
	## Crown centre (x s) in local space per variant, for fireflies "under willows" (map-fill.md 3.3).
	"crown_centre": [Vector3(0.25, 3.75, 0.0), Vector3(1.15, 3.45, 0.0), Vector3(0.0, 4.0, 0.0)],
}
