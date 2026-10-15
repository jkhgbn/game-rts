extends RefCounted
## Task 20.V0: the GOLDEN AUTUMN ground preset (docs/art/style-autumn.md 2). Colour uniforms only: it never touches the
## zones (river, lanes, spots, biome centres), so it layers on top of GroundParams.skirmish_biomes() / river() or the
## future GroundParams.fourfold_biomes() (20.V3). Reach it with `load()` (no class_name):
##     var ap: GDScript = load("res://art/environment/autumn/autumn_ground_params.gd")
##     GroundParams.apply(ground_mat, zones)          # zones first (river, biomes)
##     ap.apply(ground_mat)                            # then the autumn colours (overrides biome_tints)
## Keys = ground.gdshader uniform names (sRGB colours; the uniforms are `source_color`).

## The style bible's swatches (sRGB). style-autumn.md 1 prints the same values as hex.
const GRASS_DARK := Color(0.32, 0.35, 0.20)      # dark olive: the shade side of the grass patches (G-F r2: was umber)
const GRASS_LIGHT := Color(0.52, 0.56, 0.32)     # dry olive: the lit patches (hue ~70 deg, s 0.43)
const GRASS_WARM := Color(0.54, 0.52, 0.30)      # gold-olive (the russet moved to the trees and the fallen leaves)
const GRASS_COOL := Color(0.25, 0.32, 0.19)      # the last green (cool accent, keeps the painted temperature swing)
const GRASS_DRY := Color(0.58, 0.56, 0.38)       # pale dry grass
const CLOVER := Color(0.30, 0.34, 0.17)
const LEAF_CREAM := Color(0.93, 0.86, 0.66)      # flower_a: pale seed heads
const LEAF_GOLD := Color(0.95, 0.68, 0.20)       # flower_b: fallen gold leaves
const LEAF_MAUVE := Color(0.58, 0.36, 0.50)      # flower_c: late asters
const LEAF_RED := Color(0.78, 0.33, 0.16)        # flower_d: fallen russet leaves
## G-F review 2 item 2: dirt and roads a darker red-brown (hue ~20 deg), >= 0.12 value under the grass mean, so the
## roads and the plazas read against the olive grass (was one mustard / brown hue and value).
const DIRT := Color(0.31, 0.20, 0.14)
const DIRT_DARK := Color(0.21, 0.135, 0.10)
const ROAD := Color(0.33, 0.22, 0.155)
const ROAD_DARK := Color(0.23, 0.15, 0.11)
const COBBLE := Color(0.55, 0.51, 0.45)
const PEBBLE := Color(0.48, 0.44, 0.39)
const PAVING := Color(0.57, 0.54, 0.49)
const ROCK := Color(0.38, 0.35, 0.33)
const CANOPY_DARK := Color(0.17, 0.08, 0.05)
const CANOPY_LIGHT := Color(0.56, 0.31, 0.10)
const HAZE := Color(0.68, 0.64, 0.57)        # lighter, less saturated edge haze (G-F r2)
const BANK_WET := Color(0.16, 0.12, 0.09)
const BANK_DAMP := Color(0.32, 0.25, 0.17)
const BANK_SAND := Color(0.58, 0.49, 0.34)
const HEATHER := Color(0.47, 0.25, 0.22)         # heath: bracken red instead of heather mauve
const GORSE := Color(0.62, 0.46, 0.18)
const BLOSSOM := Color(0.95, 0.66, 0.22)
const NEEDLE := Color(0.36, 0.21, 0.11)          # old wood floor: leaf litter
const MOSS := Color(0.28, 0.30, 0.12)
## biome_tints order of GroundParams.TINT_SETS: meadow, heath, old wood, riverbank.
## G-F r2: meadow and heath olive / gold-olive (the bracken red stays in heather_color accents), old wood leaf litter.
const BIOME_TINTS: Array[Color] = [Color(0.44, 0.47, 0.26), Color(0.50, 0.46, 0.25), Color(0.25, 0.18, 0.11),
	Color(0.30, 0.37, 0.20)]


## Every autumn ground uniform (colours + the few look knobs). `amount` scales nothing but biome_amount's companion
## biome_tint_strength (1 = the bible's value).
static func ground_params(amount: float = 1.0) -> Dictionary:
	var tints := PackedColorArray()
	for c: Color in BIOME_TINTS:
		tints.append(c)
	return {
		&"grass_dark": GRASS_DARK, &"grass_light": GRASS_LIGHT, &"grass_warm": GRASS_WARM,
		&"grass_cool": GRASS_COOL, &"grass_dry": GRASS_DRY, &"patch_contrast": 0.8,
		&"clover_color": CLOVER, &"flower_a": LEAF_CREAM, &"flower_b": LEAF_GOLD, &"flower_c": LEAF_MAUVE,
		&"flower_d": LEAF_RED, &"flower_amount": 0.85, &"tuft_density": 0.5,
		&"dirt_color": DIRT, &"dirt_dark": DIRT_DARK, &"road_color": ROAD, &"road_dark": ROAD_DARK,
		&"cobble_color": COBBLE, &"pebble_color": PEBBLE, &"paving_color": PAVING, &"rock_color": ROCK,
		&"canopy_dark": CANOPY_DARK, &"canopy_light": CANOPY_LIGHT, &"haze_color": HAZE,
		&"bank_wet": BANK_WET, &"bank_damp": BANK_DAMP, &"bank_sand": BANK_SAND,
		&"heather_color": HEATHER, &"gorse_color": GORSE, &"blossom_color": BLOSSOM, &"needle_color": NEEDLE,
		&"moss_color": MOSS, &"biome_tints": tints, &"biome_tint_strength": 0.62 * amount,
	}


## Sets every key the material's shader declares (unknown keys skipped). Returns how many uniforms were set.
static func apply(mat: ShaderMaterial, amount: float = 1.0) -> int:
	if mat == null or mat.shader == null:
		return 0
	var names: Dictionary = GroundParams.uniform_names(mat.shader)
	var n := 0
	var params: Dictionary = ground_params(amount)
	for k: Variant in params:
		if names.has(String(k)):
			mat.set_shader_parameter(StringName(k), params[k])
			n += 1
	return n
