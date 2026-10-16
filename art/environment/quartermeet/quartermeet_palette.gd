extends RefCounted
## G-F Quartermeet identity (docs/art/gf_quartermeet.md): Quartermeet's own palette, a HARVEST HIGHLAND on top of the
## autumn swap, so it stops reading as Ashwind Reach (both maps are biome "autumn": olive grass, red-brown roads,
## orange crowns). Pure data (sRGB colours, the uniforms are `source_color`). Reach it with load():
##     var qp: GDScript = load("res://art/environment/quartermeet/quartermeet_palette.gd")
##     qp.ground_params(layout)      # ground.gdshader uniforms: colours + the biome zones (infield, heather moor rim)
##     qp.WATER                      # water.gdshader colour keys (a cold clear slate-teal highland river)
##     qp.NATURE                     # nature_autumn.gdshader keys (golden-yellow birch crowns instead of orange)
## Hue plan: Ashwind = olive grass (hue ~70 deg) + red-brown roads (hue ~20 deg) + orange / russet crowns.
## Quartermeet = straw-gold stubble with sage patches (hue ~45 deg), cool grey-brown granite gravel roads (low
## saturation), purple heather on the moor rim, lemon-gold crowns, slate-blue water.
## Value plan (units must still read): grass mean ~0.5 (as the autumn maps), roads >= 0.15 darker than the lit grass so
## the long roads read; the straw is kept at saturation <= 0.55 so the Fire kingdom's red-orange stays apart from it.

## Grass: straw-gold stubble, amber patches, a sage-green cool accent (the patch noise reads as a field patchwork).
const GRASS_DARK := Color(0.40, 0.355, 0.20)
const GRASS_LIGHT := Color(0.62, 0.545, 0.32)
const GRASS_WARM := Color(0.66, 0.52, 0.27)
const GRASS_COOL := Color(0.37, 0.41, 0.27)
const GRASS_DRY := Color(0.72, 0.65, 0.44)
const CLOVER := Color(0.33, 0.37, 0.21)
## Field-margin flowers: yarrow cream, tansy gold, heather purple, cornflower blue.
const FLOWER_A := Color(0.93, 0.90, 0.80)
const FLOWER_B := Color(0.92, 0.74, 0.22)
const FLOWER_C := Color(0.52, 0.38, 0.52)
const FLOWER_D := Color(0.40, 0.52, 0.84)
## Granite earth: cool grey-brown dirt and gravel roads (Ashwind's are red-brown).
const DIRT := Color(0.37, 0.325, 0.27)
const DIRT_DARK := Color(0.25, 0.215, 0.18)
const ROAD := Color(0.39, 0.355, 0.31)
const ROAD_DARK := Color(0.27, 0.245, 0.215)
const COBBLE := Color(0.58, 0.57, 0.54)
const PEBBLE := Color(0.50, 0.49, 0.46)
const PAVING := Color(0.60, 0.59, 0.55)
const ROCK := Color(0.44, 0.43, 0.41)           ## grey granite on the border rim
const CANOPY_DARK := Color(0.17, 0.13, 0.06)
const CANOPY_LIGHT := Color(0.50, 0.44, 0.21)
const HAZE := Color(0.72, 0.70, 0.64)
## Banks: dark peat by the water, damp sage, a pale gravel lip (a highland burn).
const BANK_WET := Color(0.13, 0.12, 0.10)
const BANK_DAMP := Color(0.30, 0.32, 0.22)
const BANK_SAND := Color(0.56, 0.53, 0.45)
## Biome accents: the rim = heather moor (purple heather + yellow gorse), the hubs round the keeps = green in-bye
## pasture, the water band = lush sage.
const HEATHER := Color(0.42, 0.31, 0.38)
const GORSE := Color(0.74, 0.60, 0.22)
const BLOSSOM := Color(0.93, 0.80, 0.30)
const NEEDLE := Color(0.42, 0.32, 0.16)
const MOSS := Color(0.30, 0.34, 0.15)
## biome_tints order of GroundParams.TINT_SETS: meadow (round the keeps), heath (rim), old wood (off here), riverbank.
const BIOME_TINTS: Array[Color] = [Color(0.44, 0.49, 0.26), Color(0.42, 0.37, 0.34), Color(0.30, 0.24, 0.14),
	Color(0.33, 0.42, 0.25)]
## Biome zones: green infield round the two live keeps, the heather moor in the last 11 m, a 7 m sage water band.
const BANK_REACH := 7.0
const HEATH_INSET := 11.0
const HUB_RADIUS := 21.0
const BLEND := 6.0

## Water (water.gdshader keys): a cold, clear slate-teal highland river, a pale grey-blue sky in it.
const WATER: Dictionary = {
	&"deep_color": Color(0.035, 0.10, 0.14),
	&"water_color": Color(0.09, 0.23, 0.28),
	&"bank_color": Color(0.24, 0.36, 0.33),
	&"sky_color": Color(0.66, 0.73, 0.78),
	&"foam_color": Color(0.92, 0.93, 0.90),
	&"glint_color": Color(1.0, 0.94, 0.80),
	&"film_color": Color(0.26, 0.40, 0.40),
	&"sand_color": Color(0.56, 0.53, 0.45),
	&"shallow_tint": Color(0.40, 0.70, 0.72),
	&"bed_sand": Color(0.50, 0.47, 0.40),
	&"bed_silt": Color(0.26, 0.27, 0.22),
	&"sky_zenith": Color(0.60, 0.72, 0.80),
	&"clarity": 6.0,
}
## Shared foliage (nature_autumn.gdshader keys, live while the autumn swap is on): golden-yellow birch / lemon crowns
## instead of russet / orange, straw undergrowth, a lighter sun tint.
const NATURE: Dictionary = {
	&"crown_russet": Color(0.70, 0.45, 0.10),
	&"crown_amber": Color(0.88, 0.66, 0.13),
	&"crown_gold": Color(0.95, 0.82, 0.28),
	&"crown_late_green": Color(0.52, 0.53, 0.20),
	&"crown_weights": Vector4(0.12, 0.34, 0.42, 0.12),
	&"under_bracken": Color(0.62, 0.44, 0.16),
	&"under_straw": Color(0.66, 0.56, 0.28),
	&"willow_tone": Color(0.66, 0.58, 0.20),
	&"sun_tint": Color(1.0, 0.94, 0.70),
	&"moss_color": Color(0.38, 0.44, 0.16),
	&"moss_dark": Color(0.19, 0.25, 0.08),
}


## Every Quartermeet ground uniform: colours + the biome zones. `layout` (MapLayout, optional) gives the keeps (the
## infield hubs: the first two keep spots of seats 0 and 1, the live ones while 4-seat maps play 1v1), the crown isle
## and the size; `keeps` (optional, x / z of the live keeps) beats the layout.
static func ground_params(layout: Resource = null, keeps: Array[Vector3] = []) -> Dictionary:
	var tints := PackedColorArray()
	for c: Color in BIOME_TINTS:
		tints.append(c)
	var hubs := Vector4(-71.6, 32.4, 71.6, -32.4)
	var crown := Vector2.ZERO
	var half := 88.0
	if layout:
		if &"size_x" in layout:
			half = minf(float(layout.get(&"size_x")), float(layout.get(&"size_z"))) * 0.5
		if layout.has_method(&"spots_of"):
			var ks: Array = layout.call(&"spots_of", "keep")
			var a := Vector3.INF
			var b := Vector3.INF
			for s: Dictionary in ks:
				var t := int(s.get("team", -1))
				if t == 0 and a == Vector3.INF:
					a = s.get("pos", Vector3.ZERO)
				elif t == 1 and b == Vector3.INF:
					b = s.get("pos", Vector3.ZERO)
			if a != Vector3.INF and b != Vector3.INF:
				hubs = Vector4(a.x, a.z, b.x, b.z)
			var cr: Array = layout.call(&"spots_of", "crown")
			if not cr.is_empty():
				var cp: Vector3 = (cr[0] as Dictionary).get("pos", Vector3.ZERO)
				crown = Vector2(cp.x, cp.z)
	if keeps.size() >= 2:
		hubs = Vector4(keeps[0].x, keeps[0].z, keeps[1].x, keeps[1].z)
	var ruins := PackedVector4Array([Vector4(crown.x, crown.y, 11.0, 0.0)])
	var n_ruins := ruins.size()
	ruins.resize(8)
	return {
		&"grass_dark": GRASS_DARK, &"grass_light": GRASS_LIGHT, &"grass_warm": GRASS_WARM,
		&"grass_cool": GRASS_COOL, &"grass_dry": GRASS_DRY, &"patch_contrast": 0.9,
		&"clover_color": CLOVER, &"flower_a": FLOWER_A, &"flower_b": FLOWER_B, &"flower_c": FLOWER_C,
		&"flower_d": FLOWER_D, &"flower_amount": 0.6, &"tuft_density": 0.55,
		&"dirt_color": DIRT, &"dirt_dark": DIRT_DARK, &"road_color": ROAD, &"road_dark": ROAD_DARK,
		&"cobble_color": COBBLE, &"pebble_color": PEBBLE, &"paving_color": PAVING, &"rock_color": ROCK,
		&"canopy_dark": CANOPY_DARK, &"canopy_light": CANOPY_LIGHT, &"haze_color": HAZE,
		&"bank_wet": BANK_WET, &"bank_damp": BANK_DAMP, &"bank_sand": BANK_SAND, &"bank_width": 2.6,
		&"heather_color": HEATHER, &"gorse_color": GORSE, &"blossom_color": BLOSSOM, &"needle_color": NEEDLE,
		&"moss_color": MOSS,
		&"biome_amount": 1.0, &"biome_tints": tints, &"biome_tint_strength": 0.6,
		&"biome_hubs": hubs, &"biome_hub_radius": HUB_RADIUS, &"biome_woods": Vector4(0.0, 0.0, 0.0, 0.0),
		&"biome_wood_radius": 0.0, &"biome_heath_edge": half - HEATH_INSET, &"biome_bank_reach": BANK_REACH,
		&"biome_blend": BLEND, &"biome_ruins": ruins, &"biome_ruin_count": n_ruins,
	}


## Sets every key the material's shader declares (unknown keys skipped). Returns how many uniforms were set.
static func apply_ground(mat: ShaderMaterial, layout: Resource = null, keeps: Array[Vector3] = []) -> int:
	if mat == null or mat.shader == null:
		return 0
	var names: Dictionary = GroundParams.uniform_names(mat.shader)
	var n := 0
	var params: Dictionary = ground_params(layout, keeps)
	for k: Variant in params:
		if names.has(String(k)):
			mat.set_shader_parameter(StringName(k), params[k])
			n += 1
	return n
