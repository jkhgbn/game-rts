class_name GloomStablesModel
extends StablesModel
## Visual model of Malrik's Stables, the Gloom Stables (docs/design/stables.md; cavalry-mounts.md 13.V22), in the
## Gloom Hall / Dusk Keep language: dark crypt stone (a tall stone lower course), near-black timber with tarnished
## silver straps, a STEEP slate roof in the team colour with a crest of iron spikes and spiked finials, the loft tower's
## tall spire cone crowned with a violet lantern cage (the high glow point, violet wisps), black iron fence posts with
## spear points and silver collars, a violet lantern at the gate, a horse skull over the barn door, leaning
## tombstones and a bone urn by the tower, pale withered straw.
## The mount is the Gloam Riders' DUSK STEED (a near-black violet horse with a spiked mane, pale eyes) with a team
## saddle cloth; another looks out of the middle stall. Warm candle-lit windows against the violet.
## Layout, hooks, states, budgets: StablesModel (stables_model.gd).

const BONE := Color(0.80, 0.76, 0.66)
const IRON := Color(0.10, 0.09, 0.13)
const STEED := Color(0.17, 0.12, 0.23)
const STEED_DK := Color(0.08, 0.06, 0.11)
const MANE := Color(0.36, 0.22, 0.52)

var _dress: ShadowDress


func _setup_palette() -> void:
	outline_calm = true   # G-F Shadow leftovers: the site outline under the flagstones (SiteOutline)
	kingdom_color = Color(0.42, 0.22, 0.60)
	glow_color = Color(0.70, 0.30, 1.00)
	stone_color = Color(0.20, 0.17, 0.26)
	dark_color = Color(0.09, 0.07, 0.13)
	metal_color = Color(0.55, 0.52, 0.66)
	stripe_color = Color(0.55, 0.52, 0.66)
	glyph_color = Color(0.70, 0.30, 1.00)
	glyph_shape = 1
	smoke_color = Color(0.12, 0.09, 0.16)
	dust_color = Color(0.18, 0.15, 0.22)
	decal_color = Color(0.07, 0.03, 0.10)
	light_color = Color(0.62, 0.30, 1.0)
	light_energy = 1.0
	danger_ramp_hot = Color(0.95, 0.75, 1.0)
	danger_ramp_mid = Color(0.8, 0.4, 1.0)
	danger_ramp_end = Color(0.3, 0.1, 0.5)
	c_found = Color(0.11, 0.09, 0.14)
	c_stone = Color(0.25, 0.22, 0.31)
	c_wall = Color(0.19, 0.15, 0.20)
	c_beam = Color(0.09, 0.07, 0.10)
	c_wood = Color(0.30, 0.24, 0.28)
	c_trim = Color(0.60, 0.57, 0.70)
	c_straw = Color(0.74, 0.67, 0.48)
	c_straw_dk = Color(0.50, 0.44, 0.32)
	c_earth = Color(0.22, 0.19, 0.20)
	c_water = Color(0.10, 0.10, 0.16)
	c_leather = Color(0.18, 0.11, 0.12)
	c_roof_core = Color(0.14, 0.12, 0.17)
	window_color = Color(1.0, 0.64, 0.32)
	lower_h = 1.05
	roof_rise = 2.25
	tower_rise = 2.6
	tile_courses = 5
	seed_base = 7301


## G-B: tier-scaled dressing (dead ground, mist, wisps, embers, a soft light at Ultra; nothing at Low).
func _post_build() -> void:
	super()
	var pts: Array = []
	pts.append_array(_smoke_points)
	pts.append_array(_blaze_points)
	var lp: Vector3 = _light.position if _light else Vector3(0.0, 2.4, -3.2)
	_dress = ShadowDress.attach(self, {"radius": 6.2, "inner": 3.3, "top": _top_y, "mist": 3.7, "seed": 5.3,
		"wisp_r": 3.2, "wisp_y": Vector2(1.0, 5.0), "glow": _dress_glow(), "embers": pts.slice(0, 3), "light": lp,
		"light_energy": 0.9, "light_range": 7.0})


func set_construction_progress(p: float) -> void:
	super(p)
	if _dress and not _destroyed:
		_dress.sync(_progress, _health_ratio, false)


func set_health_ratio(r: float) -> void:
	super(r)
	if _dress and not _destroyed:
		_dress.sync(_progress, _health_ratio, false)


func play_destroyed() -> void:
	super()
	if _dress:
		_dress.sync(1.0, 0.0, true)


func set_team_color(c: Color) -> void:
	super(c)
	if _dress:
		_dress.set_glow(_dress_glow())


func _dress_glow() -> Color:
	return glow_color if _team_color.is_equal_approx(kingdom_color) else _team_color.lightened(0.35)


## A horse skull over the barn door (+X gable), silver studs on the stall lintels.
func _k_wall_extra(it: Array, _rng: RandomNumberGenerator) -> void:
	var cz: float = (BZ0 + BZ1) * 0.5
	var p := Vector3(BX1 + 0.22, 3.2, cz)
	it.append(_i(_sp(8, 4), p, BONE, Vector3(0, 0, 0), Vector3(0.16, 0.34, 0.3)))
	it.append(_i(_cyc(0.07, 0.11, 0.42, 6), p + Vector3(0.02, -0.3, 0), BONE, Vector3(0, 0, 0)))
	for s: float in [-1.0, 1.0]:
		it.append(_i(_sp(6, 3), p + Vector3(0.08, 0.02, s * 0.08), Color.BLACK, Vector3.ZERO, Vector3(0.05, 0.08, 0.07), K_HOLE))
		it.append(_i(_cyc(0.0, 0.05, 0.3, 4), p + Vector3(0.0, 0.26, s * 0.14), BONE, Vector3(s * 30.0, 0, 0)))


## A crest of iron spikes along the barn ridge, spiked finials at both gables.
func _k_roof_extra(it: Array, cz: float, _hd: float, x0: float, x1: float) -> void:
	var top: float = EAVE + roof_rise + 0.3
	for k: int in 7:
		var x: float = x0 + 0.35 + (x1 - x0 - 0.7) * k / 6.0
		if absf(x - 1.05) < 0.5:
			continue
		it.append(_i(_cy(0.0, 0.07, 0.42, 4), Vector3(x, top + 0.14, cz), IRON, Vector3(0, 45, 0), Vector3.ONE, K_METAL))
	for x: float in [x0 - 0.05, x1 + 0.05]:
		it.append(_i(_cyc(0.0, 0.11, 0.8, 4), Vector3(x, top + 0.3, cz), c_trim, Vector3(0, 45, 0), Vector3.ONE, K_METAL))
		it.append(_i(_sp(6, 3), Vector3(x, top, cz), c_trim, Vector3.ZERO, Vector3(0.2, 0.2, 0.2), K_METAL))


## A silver crescent vane.
func _k_vane(it: Array, p: Vector3) -> void:
	it.append(_i(_torus(0.16, 0.24), p + Vector3(0, 0.05, 0), c_trim, Vector3(90, 30, 0), Vector3(1, 1, 1), K_METAL))
	it.append(_i(_bx(), p + Vector3(0.12, 0.05, 0.0), IRON, Vector3(0, 30, 0), Vector3(0.24, 0.3, 0.1)))


## Tall spire cone topped by a violet lantern cage and an iron needle; violet wisps.
func _k_tower_top(it: Array, tower: Node3D, h: float) -> void:
	var box: BoxMesh = _bx()
	var apex: float = h + tower_rise + 0.5
	var lc := Vector3(0, apex + 0.25, 0)
	it.append(_i(_cyc(0.2, 0.26, 0.12, 6), lc + Vector3(0, -0.2, 0), c_trim, Vector3.ZERO, Vector3.ONE, K_METAL))
	it.append(_i(box, lc + Vector3(0, 0.08, 0), Color.WHITE, Vector3(0, 45, 0), Vector3(0.24, 0.42, 0.24), K_PLAIN, mat_glow))
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		it.append(_i(box, lc + Vector3(c.x * 0.15, 0.08, c.y * 0.15), c_trim, Vector3.ZERO, Vector3(0.04, 0.5, 0.04), K_METAL))
	it.append(_i(_cyc(0.0, 0.2, 0.26, 6), lc + Vector3(0, 0.46, 0), c_trim, Vector3.ZERO, Vector3.ONE, K_METAL))
	it.append(_i(_cy(0.0, 0.035, 0.7, 4), lc + Vector3(0, 0.92, 0), IRON, Vector3.ZERO, Vector3.ONE, K_METAL))
	var w := _pm(Vector3.UP, 20.0, 0.25, 0.5, Vector3(0.1, 0.1, 0.0), 0.35, 0.8,
		_ramp(Color(0.62, 0.34, 0.95, 0.35), Color(0.4, 0.2, 0.7, 0.0), false))
	w.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	w.emission_sphere_radius = 0.2
	_idle_fx.append(_particles("Wisps", tower, lc + Vector3(0, 0.2, 0), 8, 2.4, w, _mix_quad, false))


## Leaning tombstones and a bone urn at the back of the paddock, by the tower.
func _k_yard_extra(it: Array, _rng: RandomNumberGenerator) -> void:
	var box: BoxMesh = _bx()
	var t: Array = [[Vector3(-2.55, 0.0, -2.35), 8.0, -10.0], [Vector3(-1.95, 0.0, -2.5), -6.0, 14.0]]
	for e: Array in t:
		var p: Vector3 = e[0]
		it.append(_i(box, p + Vector3(0, 0.38, 0), c_stone.lightened(0.18), Vector3(e[1], e[2], 0), Vector3(0.42, 0.8, 0.14), K_STONE))
		it.append(_i(_cyc(0.21, 0.21, 0.14, 8), p + Vector3(0, 0.78, 0), c_stone.lightened(0.18), Vector3(e[1] + 90.0, e[2], 0), Vector3.ONE, K_STONE))
		it.append(_i(box, p + Vector3(0, 0.5, 0.08), IRON, Vector3(e[1], e[2], 0), Vector3(0.22, 0.05, 0.02)))
	var u := Vector3(-1.45, 0.0, -2.2)
	it.append(_i(_cyc(0.16, 0.24, 0.5, 8), u + Vector3(0, 0.25, 0), BONE.darkened(0.2)))
	it.append(_i(_sp(8, 4), u + Vector3(0, 0.52, 0), BONE, Vector3.ZERO, Vector3(0.3, 0.2, 0.3)))


func _k_lantern_cage() -> Color:
	return c_trim


## Black iron post with a silver collar and a spear point.
func _k_post(it: Array, p: Vector3) -> void:
	it.append(_i(_cy(0.07, 0.08, 1.15, 6), p + Vector3(0, 0.575, 0), IRON))
	it.append(_i(_cy(0.0, 0.1, 0.34, 4), p + Vector3(0, 1.3, 0), IRON, Vector3(0, 45, 0), Vector3.ONE, K_METAL))


func _k_rail(it: Array, a: Vector3, b: Vector3) -> void:
	it.append(_ix(_bx(), _seg(a, b, 0.07, 0.09), IRON))


# --- The Dusk Steed -----------------------------------------------------------------------------------------------

func _k_mount_prof() -> Dictionary:
	return {"len": 1.95, "height": 1.5, "girth": 0.56, "coat": STEED, "dark": STEED_DK, "hoof": Color(0.05, 0.04, 0.06),
		"leg_r": 0.07, "neck_h": 0.62, "neck_f": 0.3, "neck_r": 0.4}


func _k_mount_extra(body: Array, tail: Array, bh: float, L: float, G: float) -> void:
	# Spiked mane down the neck (violet), silver chest strap.
	for k: int in 5:
		var t: float = float(k) / 4.0
		var p := Vector3(0, bh + G * 0.35 + 0.55 * t, -L * 0.36 - 0.26 * t + 0.08)
		body.append(_i(_cy(0.0, 0.06, 0.32 - 0.04 * k, 4), p, MANE.lerp(STEED, 0.3 * t), Vector3(-35.0 + 10.0 * k, 45, 0)))
	body.append(_i(_bx(), Vector3(0, bh + 0.05, -L * 0.42), c_trim, Vector3(-20, 0, 0), Vector3(G * 0.95, 0.06, 0.06), K_METAL))
	tail.append(_i(_cy(0.03, 0.09, 0.62, 5), Vector3(0, -0.25, 0.12), MANE.darkened(0.3), Vector3(-25, 0, 0)))
	tail.append(_i(_cy(0.0, 0.07, 0.3, 4), Vector3(0, -0.55, 0.24), MANE, Vector3(-20, 0, 0)))


## Horse head in pivot space (neck top at the origin, muzzle toward -Z), transformed by `xf`.
func _k_head(it: Array, xf: Transform3D) -> void:
	var parts: Array = []
	parts.append(_i(_sp(10, 5), Vector3(0, 0.02, -0.1), STEED, Vector3(-20, 0, 0), Vector3(0.3, 0.36, 0.42)))
	parts.append(_i(_cyc(0.1, 0.14, 0.5, 8), Vector3(0, -0.12, -0.38), STEED, Vector3(-62, 0, 0)))
	parts.append(_i(_cyc(0.1, 0.1, 0.06, 8), Vector3(0, -0.23, -0.6), STEED_DK, Vector3(-62, 0, 0)))
	for s: float in [-1.0, 1.0]:
		parts.append(_i(_cy(0.0, 0.05, 0.22, 4), Vector3(s * 0.09, 0.26, -0.02), STEED_DK, Vector3(-10, 0, s * -12.0)))
		parts.append(_i(_sp(6, 3), Vector3(s * 0.14, 0.06, -0.2), Color(0.85, 0.72, 1.0), Vector3.ZERO, Vector3(0.05, 0.05, 0.06)))
	parts.append(_i(_bx(), Vector3(0, -0.02, -0.34), c_trim, Vector3(-62, 0, 0), Vector3(0.24, 0.04, 0.05), K_METAL))
	for p: Array in parts:
		p[1] = xf * (p[1] as Transform3D)
		it.append(p)
