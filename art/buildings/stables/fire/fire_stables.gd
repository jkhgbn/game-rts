class_name EmberStablesModel
extends StablesModel
## Visual model of Vessa's Stables, the Ember Stables (docs/design/stables.md; cavalry-mounts.md 13.V21), in the
## Ember Hall / Fire Keep language: a battered basalt foundation with dim lava veins, dark stone lower walls under
## charred timber planking with bronze straps, bell-cast gable roofs of red team tiles, the Hall's crossed bronze
## bargeboard horns on both gables, a stone farrier's chimney on the loft tower with a horned bronze crown and
## glowing coals (the high glow point, fire + smoke), an ember lantern at the paddock gate, bronze-spiked iron fence
## posts, a farrier's anvil on a stump with horseshoes, a quench barrel, horseshoes nailed over the stall doors.
## The mount is the Blaze Riders' EMBER BOAR (russet, a crest of embers down the spine, bone tusks), standing in the
## paddock with a team saddle cloth; boars also look out of the middle stall and the back stall.
## Layout, hooks, states, budgets: StablesModel (stables_model.gd).

const BOAR_COAT := Color(0.46, 0.18, 0.09)
const BOAR_DARK := Color(0.17, 0.07, 0.05)
const EMBER := Color(1.0, 0.52, 0.16)
const BONE := Color(0.92, 0.86, 0.70)
const IRON := Color(0.16, 0.14, 0.15)


func _setup_palette() -> void:
	kingdom_color = Color(0.85, 0.30, 0.12)
	glow_color = Color(1.0, 0.58, 0.16)
	stone_color = Color(0.30, 0.26, 0.24)
	dark_color = Color(0.10, 0.08, 0.09)
	metal_color = Color(0.62, 0.40, 0.16)
	stripe_color = Color(0.55, 0.08, 0.05)
	glyph_color = Color(1.0, 0.75, 0.30)
	glyph_shape = 0
	smoke_color = Color(0.16, 0.14, 0.13)
	dust_color = Color(0.24, 0.21, 0.19)
	decal_color = Color(0.09, 0.04, 0.02)
	light_color = Color(1.0, 0.5, 0.15)
	light_energy = 1.0
	c_found = Color(0.15, 0.12, 0.12)
	c_stone = Color(0.34, 0.29, 0.27)
	c_wall = Color(0.30, 0.19, 0.12)
	c_beam = Color(0.13, 0.09, 0.08)
	c_wood = Color(0.52, 0.32, 0.17)
	c_trim = Color(0.70, 0.46, 0.18)
	c_straw = Color(0.90, 0.72, 0.34)
	c_straw_dk = Color(0.64, 0.46, 0.20)
	c_earth = Color(0.33, 0.24, 0.17)
	c_water = Color(0.14, 0.22, 0.26)
	c_leather = Color(0.28, 0.15, 0.09)
	c_roof_core = Color(0.24, 0.2, 0.19)
	window_color = Color(1.0, 0.66, 0.28)
	crack_on = 0.3
	hot_energy = 0.45
	roof_rise = 1.75
	seed_base = 7101


# --- Kingdom pieces -------------------------------------------------------------------------------------------------

## Horseshoes over the front stalls (luck, the farrier's kingdom).
func _k_wall_extra(it: Array, _rng: RandomNumberGenerator) -> void:
	for x: float in [STALLS[0], STALLS[2]]:
		it.append(_i(_torus(0.07, 0.14), Vector3(x, 2.52, BZ0 - 0.17), IRON.lightened(0.15), Vector3(90, 0, 0), Vector3(1, 1, 1.1), K_METAL))


## The Hall's crossed bronze horns past the ridge at both gables.
func _k_roof_extra(it: Array, cz: float, hd: float, x0: float, x1: float) -> void:
	var a: float = atan2(roof_rise, hd)
	for x: float in [x0 - 0.05, x1 + 0.05]:
		for s: float in [-1.0, 1.0]:
			var top := Vector3(x, EAVE + roof_rise + 0.1, cz)
			var tip: Vector3 = top + Vector3(0, sin(a) * 0.8, s * -cos(a) * 0.8)
			it.append(_ix(_bx(), _seg(top + Vector3(0, -0.15, s * 0.1), tip, 0.2, 0.22), c_trim, K_METAL))
			it.append(_i(_cyc(0.0, 0.1, 0.38, 4), tip + Vector3(0, 0.12, -s * 0.1), c_trim, Vector3(s * 40.0, 0, 0), Vector3.ONE, K_METAL))


## A bronze boar weathervane (flat plates + tusk).
func _k_vane(it: Array, p: Vector3) -> void:
	var box: BoxMesh = _bx()
	var r := Basis(Vector3.UP, deg_to_rad(30.0))
	it.append(_ix(box, Transform3D(r.scaled_local(Vector3(0.05, 0.26, 0.5)), p + r * Vector3(0, 0, 0.05)), c_trim, K_METAL))
	it.append(_ix(box, Transform3D((r * Basis(Vector3.RIGHT, 0.35)).scaled_local(Vector3(0.05, 0.16, 0.2)), p + r * Vector3(0, -0.02, -0.28)), c_trim, K_METAL))
	it.append(_ix(_pr(), Transform3D((r * Basis(Vector3.UP, PI * 0.5)).scaled_local(Vector3(0.14, 0.18, 0.05)), p + r * Vector3(0, 0.21, -0.12)), c_trim, K_METAL))
	it.append(_ix(_cyc(0.0, 0.04, 0.18, 4), Transform3D(r * Basis(Vector3.RIGHT, deg_to_rad(-70.0)), p + r * Vector3(0, -0.02, -0.42)), BONE))


## The farrier's chimney at the back (+Z) end of the tower ridge: stone stack, bronze band, horned crown, coals,
## fire + smoke.
func _k_tower_top(it: Array, tower: Node3D, h: float) -> void:
	var box: BoxMesh = _bx()
	var ch := Vector3(0.3, h + 1.15, 0.45)
	it.append(_frustum(ch + Vector3(0, -0.65, 0), 0.34, 0.34, 1.75, 0.08, c_stone, K_STONE))
	it.append(_i(box, ch + Vector3(0, 0.75, 0), c_trim, Vector3.ZERO, Vector3(0.7, 0.1, 0.7), K_METAL))
	it.append(_i(_cyc(0.58, 0.36, 0.36, 4), ch + Vector3(0, 1.25, 0), c_beam, Vector3(0, 45, 0)))
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var d := Vector3(c.x, 0.0, c.y).normalized()
		var bb: Basis = Basis(Vector3.UP.cross(d).normalized(), deg_to_rad(26.0))
		it.append(_ix(_cyc(0.0, 0.1, 0.55, 4), Transform3D(bb, ch + d * 0.38 + Vector3(0, 1.48, 0) + bb * Vector3(0, 0.24, 0)),
			c_trim, K_METAL))
	it.append(_i(_sp(8, 4), ch + Vector3(0, 1.52, 0), Color.WHITE, Vector3.ZERO, Vector3(0.7, 0.36, 0.7), K_PLAIN, mat_glow))
	var up_fire := _pm(Vector3.UP, 12.0, 1.0, 1.5, Vector3.ZERO, 0.42, 0.1, _fire_ramp)
	up_fire.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	up_fire.emission_box_extents = Vector3(0.18, 0.04, 0.18)
	_idle_fx.append(_particles("ChimneyFire", tower, ch + Vector3(0, 1.5, 0), 12, 0.6, up_fire, _add_quad, false))
	var sm := _pm(Vector3.UP, 10.0, 0.7, 1.0, Vector3(0.25, 0.0, 0.0), 0.45, 1.5,
		_ramp(Color(smoke_color, 0.4), Color(smoke_color, 0.0), false))
	_idle_fx.append(_particles("ChimneySmoke", tower, ch + Vector3(0, 2.05, 0), 8, 3.0, sm, _mix_quad, false))


## Farrier's corner: an anvil on a stump, horseshoes, tongs; a quench barrel; a coal bucket.
func _k_yard_extra(it: Array, _rng: RandomNumberGenerator) -> void:
	var box: BoxMesh = _bx()
	var an := Vector3(-2.35, 0.0, -2.3)
	it.append(_i(_cyc(0.3, 0.34, 0.5, 8), an + Vector3(0, 0.25, 0), c_wood.darkened(0.3)))
	it.append(_i(box, an + Vector3(0, 0.6, 0), IRON, Vector3(0, 20, 0), Vector3(0.5, 0.2, 0.25), K_METAL))
	it.append(_i(_pr(), an + Vector3(0.28, 0.63, 0.1), IRON, Vector3(0, 20, -90), Vector3(0.18, 0.2, 0.2), K_METAL))
	it.append(_i(box, an + Vector3(-0.05, 0.47, 0), IRON, Vector3(0, 20, 0), Vector3(0.24, 0.1, 0.18), K_METAL))
	for k: int in 1:
		it.append(_i(_torus(0.06, 0.13), an + Vector3(0.45 + 0.2 * k, 0.05, 0.25), IRON.lightened(0.2), Vector3(0, 30 * k, 0), Vector3.ONE, K_METAL))
	it.append(_ix(box, _seg(an + Vector3(-0.1, 0.72, -0.05), an + Vector3(0.3, 0.72, -0.35), 0.04, 0.04), IRON))
	var qb := Vector3(-1.55, 0.0, -1.75)
	it.append(_i(_cyc(0.28, 0.3, 0.6, 10), qb + Vector3(0, 0.3, 0), c_wood.darkened(0.15)))
	it.append(_i(_cyc(0.25, 0.25, 0.02, 10), qb + Vector3(0, 0.6, 0), c_water))
	for y: float in [0.12, 0.48]:
		it.append(_i(_cy(0.31, 0.31, 0.06, 10), qb + Vector3(0, y, 0), IRON))


func _k_lantern_cage() -> Color:
	return IRON


## Iron post with a bronze spike cap and collar.
func _k_post(it: Array, p: Vector3) -> void:
	it.append(_i(_cy(0.09, 0.11, 1.1, 6), p + Vector3(0, 0.55, 0), c_beam))
	it.append(_i(_cy(0.0, 0.12, 0.28, 4), p + Vector3(0, 1.24, 0), c_trim, Vector3(0, 45, 0), Vector3.ONE, K_METAL))


# --- The Ember Boar ------------------------------------------------------------------------------------------------

func _k_mount_prof() -> Dictionary:
	return {"len": 1.75, "height": 1.08, "girth": 0.8, "coat": BOAR_COAT, "dark": BOAR_DARK, "hoof": Color(0.08, 0.05, 0.05),
		"leg_r": 0.1, "neck_h": 0.18, "neck_f": 0.32, "neck_r": 0.4}


func _k_mount_extra(body: Array, tail: Array, bh: float, L: float, G: float) -> void:
	# Shoulder hump + a crest of embers from the poll down the spine (self-lit, under the bloom).
	body.append(_i(_sp(10, 5), Vector3(0, bh + G * 0.3, -L * 0.28), BOAR_COAT.darkened(0.08), Vector3(-15, 0, 0), Vector3(G * 0.8, G * 0.55, L * 0.35)))
	for k: int in 6:
		var z: float = -L * 0.42 + L * 0.13 * k
		var hgt: float = 0.38 - 0.035 * k
		body.append(_i(_cyc(0.0, 0.1, hgt, 4), Vector3(0, bh + G * 0.52 + hgt * 0.4 - 0.02 * k, z),
			EMBER.lerp(Color(1.0, 0.8, 0.35), 0.4 * float(k % 2)), Vector3(-28 + 4 * k, 45, 0), Vector3(1.0, 1.0, 0.6), K_HOT))
	for s: float in [-1.0, 1.0]:
		body.append(_i(_bx(), Vector3(s * G * 0.34, bh - G * 0.42, -0.05), BOAR_DARK, Vector3(0, 0, s * 20.0), Vector3(0.1, 0.12, L * 0.7)))
	tail.append(_i(_cy(0.02, 0.05, 0.36, 5), Vector3(0, -0.12, 0.1), BOAR_DARK, Vector3(-30, 0, 0)))
	tail.append(_i(_cyc(0.0, 0.07, 0.16, 4), Vector3(0, -0.26, 0.2), EMBER, Vector3(150, 0, 0), Vector3.ONE, K_HOT))


## Boar head in pivot space (neck top at the origin, snout toward -Z), transformed by `xf`.
func _k_head(it: Array, xf: Transform3D) -> void:
	var parts: Array = []
	parts.append(_i(_sp(10, 5), Vector3(0, -0.02, -0.18), BOAR_COAT, Vector3(-12, 0, 0), Vector3(0.5, 0.46, 0.56)))
	parts.append(_i(_cyc(0.14, 0.2, 0.4, 8), Vector3(0, -0.12, -0.5), BOAR_COAT.darkened(0.1), Vector3(-80, 0, 0)))
	parts.append(_i(_cyc(0.15, 0.15, 0.06, 8), Vector3(0, -0.17, -0.71), Color(0.3, 0.12, 0.1), Vector3(-80, 0, 0)))
	for s: float in [-1.0, 1.0]:
		parts.append(_i(_cyc(0.0, 0.05, 0.3, 5), Vector3(s * 0.16, -0.1, -0.62), BONE, Vector3(-25, 0, s * -35.0)))
		parts.append(_i(_pr(), Vector3(s * 0.18, 0.22, -0.08), BOAR_DARK, Vector3(-10, 0, s * -25.0), Vector3(0.14, 0.22, 0.06)))
		parts.append(_i(_sp(6, 3), Vector3(s * 0.17, 0.06, -0.36), Color(0.95, 0.6, 0.2), Vector3.ZERO, Vector3(0.07, 0.05, 0.05)))
	for p: Array in parts:
		p[1] = xf * (p[1] as Transform3D)
		it.append(p)
