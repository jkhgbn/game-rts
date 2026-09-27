class_name AshSet
extends RefCounted
## Ash / Cinder Scar decor set (task 12b.V4; docs/design/terrain.md 7.2 row 12b.V4, the format of map-fill.md section 10
## "Biome set files"). Pure data for the terrain dressing (12b.V6, MapDressingArt reads TerrainSystem.patches() / the
## mask), no class dependency: load() it, then
##     var set_script: GDScript = load("res://art/environment/biomes/ash/ash_set.gd")
##     for item: Dictionary in set_script.items(): ...          # the shared step-12 format (meshes loaded)
##     set_script.ENTRIES / set_script.BIOME_ID / set_script.GROUND_TINT   # the map-fill.md section 10 format (paths)
##     set_script.scar_fx(centre, radius)                        # the static-scar particles (one per static Cinder Scar)
## Meshes (built by build_ash.gd; ONE surface and ONE material each, so the mesh's own material and a material_override
## give the same result; 3 shape variants per mesh picked by the shader from the instance position (the variant mask of
## nature_painted.gdshader, repeated in ash_char.gdshader): place ONE MultiMesh per mesh and chunk, random yaw, uniform
## scale, y = 0, no collider: everything is decor units walk through):
##   ash_charred_wood  charred stumps and burnt logs: V0 broken stump ~0.7 m wide (splinters to ~1.1 m), V1 a fallen
##                     log broken in two (~2.3 m long, 0.4 m high), V2 a leaning burnt snag (~1.6 m, up to 1.85 with its
##                     splinters) with a short log at its foot. ash_char_mat.tres: coal-black char checks, pale ash on
##                     the tops, a few seams smouldering orange (emission only, no lights). Casts shadows (terrain.md
##                     7.2: "no shadows except stumps and rocks").
##   ash_burnt_grass   blackened grass tufts ~0.5 m wide, 0.1-0.45 m tall: V0 charred stubble with curled ash-grey tips,
##                     V1 half-burnt (black stems, scorched straw tops: reads as the burn's edge), V2 a pale "ghost" tuft
##                     of ash. The shared nature_mat.tres (stiff: wind weight <= 0.1).
## Two decor kinds (terrain.md 7.2: <= 2 new kinds per set); ENTRIES lists the grass twice (inside the scar and on its
## edge) with the SAME mesh: still one kind, a scatter may merge the two into one MultiMesh.
##
## ENTRIES keys (map-fill.md section 10) + optional hints:
##   id         short name
##   mesh       mesh path (origin = where it touches the ground)
##   material   the mesh's surface material (path)
##   per_100m2  instances per 100 m2 of the `place` area (terrain.md 7.2: &"ash" = inside the patch, ash mask weight
##              > 0.5; &"ash_edge" = weight 0.2-0.5)
##   scale      uniform scale, random in [x, y]
##   cluster    0 = even sprinkle, 1 = everything in patches (~8 per patch, gaussian ~1.0 m round a seed point)
##   shadow     casts shadows
##   range      visibility range end in metres (fade 10 m): grass 65 (small), wood 90 (stumps)
##   place      &"ash" | &"ash_edge"
##   gap        (optional) minimum distance in metres between two instances of this entry (wood: 2.6; needs about
##              gap / 2 of clearance from roads, slots, buildings, the Lost Cache)
##   max_height (optional) mesh top x the largest scale, metres
## Where: ONLY the static Cinder Scars (TerrainSystem.patches() with terrain &"ash": West / East Cinder Scar, centre
## (-31, 2) / (31, -2), r 4.5). Random wildfire / lightning ash and Fire's scorch never move decor (terrain.md 7.3).
## Budget (terrain.md 7.2: ash <= 200 instances): the two scars hold ~127 m2 of &"ash" and ~20 m2 of &"ash_edge" ->
## charred wood 5.5 x 1.27 = ~7 (3-4 per scar), burnt grass 105 x 1.27 = ~133, edge grass 90 x 0.2 = ~18: ~158 in all
## (tests/test_12b_v4.gd computes it from the patch table of terrain.md 4.2).
##
## Static-scar particles (terrain.md 7.2 "Extra"): ash_scar_fx.tscn, one per static scar, placed at the patch centre
## (y = 0): EmberMotes (GPUParticles3D, 16 additive emissive quads, drifting up over a disc of r 3.9, no light) +
## SmokeColumn (8 soft puffs, a thin wisp ~6 m tall rising from a spot 1.1 m off the centre, leaning downwind (0.8, 0.6)).
## Both local coords, fixed_fps 30, preprocessed (already going when shown), visibility range 90 m, no shadows. Made
## for r 4.5; scar_fx() scales the node for another radius (clamped 0.6-1.6 x). 4 emitters map-wide (terrain.md 10).

const BIOME_ID := &"ash"
const TERRAIN_ID := &"ash"
## Charred black-grey ground (terrain.md 7.1 ash blotches (0.20, 0.18, 0.17) / (0.34, 0.31, 0.29); minimap ash tint
## (0.25, 0.22, 0.20)): one colour for a reader that wants one (minimap, a biome_tints slot).
const GROUND_TINT := Color(0.26, 0.235, 0.22)
const DIR := "res://art/environment/biomes/ash/"
const NATURE_MAT := "res://art/environment/nature_props/nature_mat.tres"
const CHAR_MAT := "res://art/environment/biomes/ash/ash_char_mat.tres"
const SCAR_FX := "res://art/environment/biomes/ash/ash_scar_fx.tscn"
const SCAR_FX_RADIUS := 4.5
const INSTANCE_BUDGET := 200
const VARIANTS := 3

const ENTRIES := [
	# Charred stumps, broken burnt logs and snags: the few big pieces that make a scar read as "a fire was here".
	{"id": &"charred_wood", "mesh": "res://art/environment/biomes/ash/ash_charred_wood.res", "material": CHAR_MAT,
		"per_100m2": 5.5, "scale": Vector2(0.85, 1.15), "cluster": 0.0, "shadow": true, "range": 90.0,
		"place": &"ash", "gap": 2.6, "max_height": 2.15},
	# Blackened grass over the whole scar, in loose patches.
	{"id": &"burnt_grass", "mesh": "res://art/environment/biomes/ash/ash_burnt_grass.res", "material": NATURE_MAT,
		"per_100m2": 105.0, "scale": Vector2(0.8, 1.3), "cluster": 0.5, "shadow": false, "range": 65.0,
		"place": &"ash", "max_height": 0.45},
	# The same tufts along the scar's edge (half-burnt ones read as the burn line), a little thinner.
	{"id": &"burnt_grass_edge", "mesh": "res://art/environment/biomes/ash/ash_burnt_grass.res",
		"material": NATURE_MAT, "per_100m2": 90.0, "scale": Vector2(0.8, 1.2), "cluster": 0.3, "shadow": false,
		"range": 65.0, "place": &"ash_edge", "max_height": 0.42},
]


## The shared step-12 decor format: one Dictionary per entry with the mesh and material LOADED.
##   mesh: Mesh, material: Material, density: float (per 100 m2 of `place`), scale: Vector2, vis_end: float (fade 10 m),
##   shadow: bool, variants: int (3)
## plus the hints id: StringName, cluster: float, place: StringName, gap: float (0 = none), max_height: float.
## Entries whose mesh or material is missing are skipped (push_warning), never a null mesh.
static func items() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e: Dictionary in ENTRIES:
		var path: String = e["mesh"]
		var mpath: String = e["material"]
		if not ResourceLoader.exists(path) or not ResourceLoader.exists(mpath):
			push_warning("ash_set: missing %s / %s" % [path, mpath])
			continue
		var mesh := load(path) as Mesh
		var material := load(mpath) as Material
		if mesh == null or material == null:
			continue
		out.append({
			"mesh": mesh,
			"material": material,
			"density": float(e["per_100m2"]),
			"scale": e["scale"] as Vector2,
			"vis_end": float(e["range"]),
			"shadow": bool(e["shadow"]),
			"variants": VARIANTS,
			"id": e["id"] as StringName,
			"cluster": float(e["cluster"]),
			"place": e["place"] as StringName,
			"gap": float(e.get("gap", 0.0)),
			"max_height": float(e.get("max_height", 0.0)),
		})
	return out


## One static-scar particle node (ember motes + smoke column) for a scar at `centre` (world, y = 0) of `radius` metres.
## Add it to the level (any Node3D parent at the origin); null when the scene is missing. No material is created: the
## instances share the scene's resources.
static func scar_fx(centre: Vector3, radius: float = SCAR_FX_RADIUS) -> Node3D:
	if not ResourceLoader.exists(SCAR_FX):
		push_warning("ash_set: missing %s" % SCAR_FX)
		return null
	var node := (load(SCAR_FX) as PackedScene).instantiate() as Node3D
	if node == null:
		return null
	var k: float = clampf(radius / SCAR_FX_RADIUS, 0.6, 1.6)
	node.transform = Transform3D(Basis.from_scale(Vector3(k, k, k)), Vector3(centre.x, 0.0, centre.z))
	node.name = "AshScarFx"
	return node
