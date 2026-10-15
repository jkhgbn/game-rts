class_name FrostStablesModel
extends StablesModel
## Visual model of Torvald's Stables, the Frost Stables (docs/design/stables.md; cavalry-mounts.md 13.V23), in the
## Rime Keep / Frost Hall language but kept in STEEL-BLUE MID-TONES (under_90.md: Ice turns white in-game): an
## ice-stone foundation and lower course, steel-blue timber walls with dark blue-grey beams and silver-blue straps,
## a roof of glazed team-ice tiles with only a thin hard-edged snow line on the ridges and a short fringe of small
## icicles, the loft tower's cone crowned with a faceted team-ice crystal around a cold glowing core (the high glow
## point, a few frost motes), timber fence posts with silver bands and small snow caps, a frost lantern at the gate,
## a stack of cut ice blocks and a sledge in the paddock, frozen blue-grey earth. White is kept to thin edges.
## The mount is the Rimehorn Riders' RIMEHORN (a woolly war rhino, slate wool, one great ice horn) with a team
## saddle cloth; another looks out of the middle stall. Warm windows against the cold blues.
## Layout, hooks, states, budgets: StablesModel (stables_model.gd).

const SNOW := Color(0.84, 0.88, 0.94)
const ICE := Color(0.60, 0.78, 0.92)
const WOOL := Color(0.42, 0.45, 0.54)
const WOOL_DK := Color(0.23, 0.25, 0.31)
const HORN := Color(0.70, 0.84, 0.95)


const ICE_STABLES_PAINT: Shader = preload("res://art/buildings/stables/ice/ice_stables_painted.gdshader")


## G-B Ice: the one body material takes the Ice paint layer (same vertex data; docs/art/gb_ice_buildings.md).
func _post_build() -> void:
	if IceShapes.legacy or mat_body == null or mat_body.shader != PAINT:
		return
	mat_body.shader = ICE_STABLES_PAINT
	mat_body.set_shader_parameter(&"gb_detail", float(IceShapes.detail_tier()))


func _setup_palette() -> void:
	kingdom_color = Color(0.45, 0.75, 0.95)
	glow_color = Color(0.62, 0.88, 1.00)
	stone_color = Color(0.40, 0.49, 0.63)
	dark_color = Color(0.27, 0.31, 0.39)
	metal_color = Color(0.70, 0.78, 0.88)
	stripe_color = Color(0.15, 0.35, 0.60)
	glyph_color = Color(0.75, 0.92, 1.00)
	glyph_shape = 1
	smoke_color = Color(0.25, 0.28, 0.34)
	dust_color = Color(0.55, 0.60, 0.68)
	decal_color = Color(0.10, 0.14, 0.22)
	light_color = Color(0.70, 0.88, 1.00)
	light_energy = 1.0
	danger_ramp_hot = Color(1.0, 0.85, 0.55)
	danger_ramp_mid = Color(1.0, 0.5, 0.15)
	danger_ramp_end = Color(0.4, 0.1, 0.05)
	c_found = Color(0.22, 0.27, 0.35)
	c_stone = Color(0.38, 0.46, 0.58)
	c_wall = Color(0.31, 0.38, 0.48)
	c_beam = Color(0.15, 0.18, 0.25)
	c_wood = Color(0.42, 0.47, 0.55)
	c_trim = Color(0.54, 0.62, 0.74)
	roof_tile = Color(0.8, 0.8, 0.8, 0.0)
	c_straw = Color(0.82, 0.72, 0.46)
	c_straw_dk = Color(0.58, 0.49, 0.30)
	c_earth = Color(0.33, 0.36, 0.42)
	c_water = Color(0.30, 0.46, 0.60)
	c_leather = Color(0.24, 0.17, 0.14)
	c_roof_core = Color(0.20, 0.25, 0.33)
	window_color = Color(1.0, 0.72, 0.38)
	glow_energy = 3.4
	roof_rise = 1.85
	tower_rise = 1.6
	seed_base = 7401


## Frost rime on the stall lintels: thin pale strips only.
func _k_wall_extra(it: Array, _rng: RandomNumberGenerator) -> void:
	for x: float in STALLS:
		it.append(_i(_bx(), Vector3(x, 2.82, BZ0 - 0.11), SNOW, Vector3.ZERO, Vector3(1.1, 0.05, 0.1)))


## A thin hard snow line on the ridge and a short fringe of small icicles under the front eave.
func _k_roof_extra(it: Array, cz: float, hd: float, x0: float, x1: float) -> void:
	it.append(_i(_bx(), Vector3((x0 + x1) * 0.5, EAVE + roof_rise + 0.29, cz), SNOW, Vector3.ZERO, Vector3(x1 - x0 - 0.2, 0.08, 0.34)))
	for k: int in 7:
		var x: float = x0 + 0.4 + (x1 - x0 - 0.8) * k / 6.0
		var hgt: float = 0.22 + 0.12 * float((k * 5) % 3)
		it.append(_i(_cy(0.0, 0.06, hgt, 4), Vector3(x, EAVE - 0.02 - hgt * 0.5, cz - hd - 0.02), ICE, Vector3(180, 45, 0)))


## A silver snowflake vane.
func _k_vane(it: Array, p: Vector3) -> void:
	for k: int in 3:
		it.append(_i(_bx(), p, c_trim, Vector3(0, 30, 60.0 * k), Vector3(0.04, 0.44, 0.06), K_METAL))


## A faceted team-ice crystal on the cone, a glowing core, frost motes.
func _k_tower_top(it: Array, tower: Node3D, h: float) -> void:
	var apex: float = h + tower_rise + 0.45
	var c := Vector3(0, apex + 0.5, 0)
	it.append(_i(_cyc(0.0, 0.26, 0.75, 6), c + Vector3(0, 0.3, 0), T(1.05), Vector3(0, 0, 0)))
	it.append(_i(_cyc(0.26, 0.2, 0.35, 6), c + Vector3(0, -0.24, 0), T(0.85), Vector3(0, 0, 0)))
	for s: float in [-1.0, 1.0]:
		it.append(_i(_cyc(0.0, 0.11, 0.5, 5), c + Vector3(s * 0.22, -0.1, 0.05), T(0.95), Vector3(0, 20, s * -28.0)))
	it.append(_i(_sp(8, 4), c + Vector3(0, 0.0, 0), Color.WHITE, Vector3.ZERO, Vector3(0.22, 0.3, 0.22), K_PLAIN, mat_glow))
	it.append(_i(_cy(0.28, 0.24, 0.1, 6), c + Vector3(0, -0.44, 0), c_trim, Vector3.ZERO, Vector3.ONE, K_METAL))
	var m := _pm(Vector3.UP, 60.0, 0.15, 0.35, Vector3(0, -0.1, 0), 0.08, 0.03,
		_ramp(Color(0.75, 0.9, 1.0, 0.8), Color(0.5, 0.75, 1.0, 0.0), false))
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = 0.35
	_idle_fx.append(_particles("FrostMotes", tower, c, 8, 1.8, m, _add_quad, false))


## Cut ice blocks and a sledge by the tower.
func _k_yard_extra(it: Array, _rng: RandomNumberGenerator) -> void:
	var box: BoxMesh = _bx()
	var b := Vector3(-2.3, 0.0, -2.3)
	it.append(_i(box, b + Vector3(0, 0.22, 0), ICE.darkened(0.15), Vector3(0, 12, 0), Vector3(0.62, 0.44, 0.5), K_STONE))
	it.append(_i(box, b + Vector3(0.5, 0.2, 0.15), ICE.darkened(0.25), Vector3(0, -15, 0), Vector3(0.5, 0.4, 0.46), K_STONE))
	it.append(_i(box, b + Vector3(0.18, 0.62, 0.05), ICE.darkened(0.05), Vector3(0, 30, 0), Vector3(0.5, 0.38, 0.44), K_STONE))
	it.append(_i(box, b + Vector3(0.18, 0.83, 0.05), SNOW, Vector3(0, 30, 0), Vector3(0.52, 0.04, 0.46)))
	var sl := Vector3(-1.35, 0.0, -2.35)
	for s: float in [-1.0, 1.0]:
		it.append(_i(box, sl + Vector3(0, 0.06, s * 0.28), c_trim, Vector3.ZERO, Vector3(1.2, 0.06, 0.06), K_METAL))
		it.append(_i(_cy(0.06, 0.06, 0.12, 6), sl + Vector3(-0.62, 0.12, s * 0.28), c_trim, Vector3(90, 0, 0), Vector3.ONE, K_METAL))
	it.append(_i(box, sl + Vector3(0.05, 0.22, 0), c_wood, Vector3.ZERO, Vector3(1.0, 0.08, 0.68)))
	for x: float in [-0.35, 0.35]:
		it.append(_i(box, sl + Vector3(x, 0.13, 0), c_beam, Vector3.ZERO, Vector3(0.08, 0.14, 0.62)))
	it.append(_i(box, sl + Vector3(0.05, 0.34, 0), T(0.8), Vector3(0, 6, 0), Vector3(0.8, 0.12, 0.6)))


func _k_lantern_cage() -> Color:
	return c_trim


## Timber post with a silver band and a small hard snow cap.
func _k_post(it: Array, p: Vector3) -> void:
	it.append(_i(_cy(0.1, 0.11, 1.1, 6), p + Vector3(0, 0.55, 0), c_beam))
	it.append(_i(_cy(0.04, 0.12, 0.1, 6), p + Vector3(0, 1.15, 0), SNOW))


# --- The Rimehorn -------------------------------------------------------------------------------------------------

func _k_mount_prof() -> Dictionary:
	return {"len": 2.05, "height": 1.2, "girth": 0.95, "coat": WOOL, "dark": WOOL_DK, "hoof": Color(0.12, 0.13, 0.16),
		"leg_r": 0.13, "neck_h": 0.12, "neck_f": 0.34, "neck_r": 0.5}


func _k_mount_extra(body: Array, tail: Array, bh: float, L: float, G: float) -> void:
	# Towering shaggy shoulder hump with rimed wool on its crest, shaggy fur boots.
	body.append(_i(_sp(10, 5), Vector3(0, bh + G * 0.36, -L * 0.24), WOOL.lightened(0.05), Vector3(-10, 0, 0), Vector3(G * 0.82, G * 0.7, L * 0.34)))
	body.append(_i(_sp(8, 4), Vector3(0, bh + G * 0.66, -L * 0.24), Color(0.62, 0.68, 0.78), Vector3(-10, 0, 0), Vector3(G * 0.5, G * 0.25, L * 0.22)))
	for k: int in 3:
		body.append(_i(_cyc(0.0, 0.07, 0.24, 5), Vector3(0.05 * (k - 1), bh + G * 0.8, -L * 0.3 + 0.12 * k), ICE, Vector3(-20 + 18 * k, 20 * k, 0)))
	for lx: float in [-1.0, 1.0]:
		for lz: float in [-1.0, 1.0]:
			body.append(_i(_sp(8, 4), Vector3(lx * G * 0.3, 0.3, lz * L * 0.33), WOOL_DK.lightened(0.1), Vector3.ZERO, Vector3(0.3, 0.3, 0.3)))
	tail.append(_i(_cy(0.02, 0.06, 0.34, 5), Vector3(0, -0.14, 0.1), WOOL_DK, Vector3(-30, 0, 0)))


## Rimehorn head: a heavy wedge head, one great ice horn sweeping forward and up, small ears.
func _k_head(it: Array, xf: Transform3D) -> void:
	var parts: Array = []
	parts.append(_i(_sp(10, 5), Vector3(0, -0.06, -0.2), WOOL, Vector3(-10, 0, 0), Vector3(0.56, 0.5, 0.6)))
	parts.append(_i(_cyc(0.2, 0.26, 0.36, 8), Vector3(0, -0.14, -0.52), WOOL_DK.lightened(0.15), Vector3(-80, 0, 0)))
	parts.append(_i(_cyc(0.0, 0.13, 0.75, 6), Vector3(0, 0.12, -0.72), HORN, Vector3(-38, 0, 0)))
	parts.append(_i(_cyc(0.0, 0.06, 0.26, 5), Vector3(0, 0.04, -0.42), HORN.darkened(0.1), Vector3(-20, 0, 0)))
	for s: float in [-1.0, 1.0]:
		parts.append(_i(_pr(), Vector3(s * 0.22, 0.2, -0.05), WOOL_DK, Vector3(0, 0, s * -30.0), Vector3(0.12, 0.16, 0.06)))
		parts.append(_i(_sp(6, 3), Vector3(s * 0.2, 0.02, -0.34), Color(0.1, 0.12, 0.16), Vector3.ZERO, Vector3(0.06, 0.05, 0.05)))
	for p: Array in parts:
		p[1] = xf * (p[1] as Transform3D)
		it.append(p)
