extends RefCounted
## G-F review 2 item 9 (docs/art/gf_thornwater.md): Thornwater's own palette, a WET MARSH-MEADOW so it no longer reads
## as Crown Hollow's sunny lawn. Pure data (sRGB colours, the uniforms are `source_color`). Reach it with load():
##     var tp: GDScript = load("res://art/environment/thornwater/thornwater_palette.gd")
##     tp.ground_params(layout)      # ground.gdshader uniforms: colours + the biome zones (wet banks, fen corners, rush rim)
##     tp.WATER                      # water.gdshader colour keys (peaty dark tea-green water)
##     tp.NATURE                     # nature_painted.gdshader keys (no random autumn crowns, wetter moss)
## Value plan (units must still read): grass mean ~0.30 value (Crown Hollow ~0.36), roads lighter peat-brown (~0.42)
## so the ring road reads; the wide wet bank band along the water is the darkest land (~0.24); water darker than all.

## Grass: deeper and bluer greens, little dry / warm grass.
const GRASS_DARK := Color(0.13, 0.245, 0.15)
const GRASS_LIGHT := Color(0.25, 0.37, 0.19)
const GRASS_WARM := Color(0.33, 0.38, 0.19)
const GRASS_COOL := Color(0.10, 0.24, 0.20)
const GRASS_DRY := Color(0.39, 0.39, 0.26)
const CLOVER := Color(0.08, 0.22, 0.12)
## Wet-meadow flowers: meadowsweet cream, marsh marigold, purple loosestrife, ragged-robin pink (fewer than the lawn).
const FLOWER_A := Color(0.92, 0.92, 0.84)
const FLOWER_B := Color(0.95, 0.80, 0.28)
const FLOWER_C := Color(0.66, 0.38, 0.70)
const FLOWER_D := Color(0.86, 0.48, 0.60)
## Peat earth: darker, cooler brown dirt; the road a step lighter so it still reads on the dark grass.
const DIRT := Color(0.33, 0.27, 0.20)
const DIRT_DARK := Color(0.21, 0.17, 0.125)
const ROAD := Color(0.44, 0.37, 0.27)
const ROAD_DARK := Color(0.28, 0.23, 0.17)
const COBBLE := Color(0.47, 0.47, 0.44)
const PEBBLE := Color(0.40, 0.40, 0.37)
const PAVING := Color(0.50, 0.50, 0.47)
const ROCK := Color(0.34, 0.37, 0.28)          ## mossy bank stone on the border rim (reads as a bank, not a wall)
const CANOPY_DARK := Color(0.035, 0.10, 0.08)
const CANOPY_LIGHT := Color(0.12, 0.25, 0.15)
const HAZE := Color(0.34, 0.44, 0.44)
## Banks: black-brown wet mud and damp moss, no pale sand lip (a marsh bank, not a beach).
const BANK_WET := Color(0.085, 0.09, 0.07)
const BANK_DAMP := Color(0.19, 0.21, 0.14)
const BANK_SAND := Color(0.34, 0.33, 0.24)
## Biome accents: the rim band = rush heath (dark rush clumps + dry sedge instead of heather / gorse), the corners =
## peat fen floor (old-wood layer), the wet bank band = deep lush green.
const HEATHER := Color(0.17, 0.25, 0.15)
const GORSE := Color(0.44, 0.41, 0.24)
const BLOSSOM := Color(0.86, 0.80, 0.46)
const NEEDLE := Color(0.20, 0.17, 0.11)
const MOSS := Color(0.12, 0.25, 0.10)
## biome_tints order of GroundParams.TINT_SETS: meadow (round the keeps), heath (rim), old wood (fen corners), riverbank.
const BIOME_TINTS: Array[Color] = [Color(0.29, 0.43, 0.20), Color(0.27, 0.33, 0.20), Color(0.15, 0.19, 0.12),
	Color(0.10, 0.25, 0.17)]
## Biome zones (ground.gdshader 12.V2): a WIDE wet band along the water (9 m, Crown Hollow 6), fen corners on the lair
## corners, the rush rim in the last 9 m. The hubs / ruins are read from the layout (keeps, crown isle).
const BANK_REACH := 9.0
const WOOD_RADIUS := 22.0
const HEATH_EDGE := 51.0
const HUB_RADIUS := 20.0
const BLEND := 5.0

## Water (water.gdshader keys): peaty, darker and murkier; a muted sky reflection; foam a little greyer.
const WATER: Dictionary = {
	&"deep_color": Color(0.025, 0.085, 0.075),
	&"water_color": Color(0.06, 0.18, 0.15),
	&"bank_color": Color(0.14, 0.28, 0.20),
	&"sky_color": Color(0.40, 0.52, 0.54),
	&"foam_color": Color(0.76, 0.82, 0.75),
	&"glint_color": Color(0.95, 0.93, 0.82),
	&"film_color": Color(0.15, 0.31, 0.25),
	&"sand_color": Color(0.36, 0.32, 0.23),
	&"shallow_tint": Color(0.30, 0.56, 0.46),
	&"bed_sand": Color(0.32, 0.28, 0.20),
	&"bed_silt": Color(0.15, 0.17, 0.11),
	&"sky_zenith": Color(0.46, 0.60, 0.62),
	&"clarity": 3.8,
}
## Shared foliage (nature_painted.gdshader keys): no random autumn crowns, wetter moss on stones.
const NATURE: Dictionary = {
	&"autumn_chance": 0.02,
	&"moss_color": Color(0.24, 0.42, 0.12),
	&"moss_dark": Color(0.10, 0.25, 0.07),
}


## Every Thornwater ground uniform: colours + the biome zones. `layout` (MapLayout, optional) gives the keep hubs and
## the crown isle; without it the Crown Hollow numbers stand in.
static func ground_params(layout: Resource = null) -> Dictionary:
	var tints := PackedColorArray()
	for c: Color in BIOME_TINTS:
		tints.append(c)
	var hubs := Vector4(-41.1, 43.9, 41.1, -43.9)
	var crown := Vector2.ZERO
	var woods := Vector4(-47.0, -45.0, 47.0, 45.0)
	if layout and layout.has_method(&"spots_of"):
		var keeps: Array = layout.call(&"spots_of", "keep")
		if keeps.size() >= 2:
			var a: Vector3 = (keeps[0] as Dictionary).get("pos", Vector3.ZERO)
			var b: Vector3 = (keeps[1] as Dictionary).get("pos", Vector3.ZERO)
			hubs = Vector4(a.x, a.z, b.x, b.z)
			# The fen corners: the two corners the keeps do NOT sit in (Thornwater: the lair corners).
			woods = Vector4(signf(a.x) * 47.0, -signf(a.z) * 45.0, signf(b.x) * 47.0, -signf(b.z) * 45.0)
		var cr: Array = layout.call(&"spots_of", "crown")
		if not cr.is_empty():
			var cp: Vector3 = (cr[0] as Dictionary).get("pos", Vector3.ZERO)
			crown = Vector2(cp.x, cp.z)
	var ruins := PackedVector4Array([Vector4(crown.x, crown.y, 11.0, 0.0)])
	var n_ruins := ruins.size()
	ruins.resize(8)
	return {
		&"grass_dark": GRASS_DARK, &"grass_light": GRASS_LIGHT, &"grass_warm": GRASS_WARM,
		&"grass_cool": GRASS_COOL, &"grass_dry": GRASS_DRY, &"patch_contrast": 0.66,
		&"clover_color": CLOVER, &"flower_a": FLOWER_A, &"flower_b": FLOWER_B, &"flower_c": FLOWER_C,
		&"flower_d": FLOWER_D, &"flower_amount": 0.55, &"tuft_density": 0.7,
		&"dirt_color": DIRT, &"dirt_dark": DIRT_DARK, &"road_color": ROAD, &"road_dark": ROAD_DARK,
		&"cobble_color": COBBLE, &"pebble_color": PEBBLE, &"paving_color": PAVING, &"rock_color": ROCK,
		&"canopy_dark": CANOPY_DARK, &"canopy_light": CANOPY_LIGHT, &"haze_color": HAZE,
		&"bank_wet": BANK_WET, &"bank_damp": BANK_DAMP, &"bank_sand": BANK_SAND, &"bank_width": 3.2,
		&"heather_color": HEATHER, &"gorse_color": GORSE, &"blossom_color": BLOSSOM, &"needle_color": NEEDLE,
		&"moss_color": MOSS,
		&"biome_amount": 1.0, &"biome_tints": tints, &"biome_tint_strength": 0.7,
		&"biome_hubs": hubs, &"biome_hub_radius": HUB_RADIUS, &"biome_woods": woods,
		&"biome_wood_radius": WOOD_RADIUS, &"biome_heath_edge": HEATH_EDGE, &"biome_bank_reach": BANK_REACH,
		&"biome_blend": BLEND, &"biome_ruins": ruins, &"biome_ruin_count": n_ruins,
	}


## Sets every key the material's shader declares (unknown keys skipped). Returns how many uniforms were set.
static func apply_ground(mat: ShaderMaterial, layout: Resource = null) -> int:
	if mat == null or mat.shader == null:
		return 0
	var names: Dictionary = GroundParams.uniform_names(mat.shader)
	var n := 0
	var params: Dictionary = ground_params(layout)
	for k: Variant in params:
		if names.has(String(k)):
			mat.set_shader_parameter(StringName(k), params[k])
			n += 1
	return n
