class_name ShadowHallModel
extends FireHallModel
## Visual model of Malrik's barracks, the Gloom Hall (task 5.V1, polished in A.9): a grim crypt-barracks under a
## steep slate roof in the team colour (tile courses, a crest of iron spikes on the ridge, spiked finials), a tall
## bell tower with glowing lantern slits, corner pinnacles and a slender pyramid spire (dominant vertical), stone
## buttresses on the right, a pointed glowing gate under a rose window, lancet windows, a rack of silver pikes,
## a soul brazier with a bobbing orb and three leaning tombstones at the back-right corner.
## Same hooks and state machine as FireHallModel (see fire_hall.gd); only the palette and parts differ.
## Tiers are merged meshes (BuildingMerge): PlinthBase, Walls, Roof, BellTower (stack + top), PikeRack.

const GX := 0.4   ## hall axis x
const GZ := 0.2   ## hall axis z
const G_HALF := 3.1
const G_EAVE := 4.12
const G_RISE := 3.45

var _orb: Node3D
var _orb_y: float = 0.0
const TEAM_DARK := 0.74   ## G-B: the darker slate courses = team colour x this (unmerged material and merged multiplier)

var mat_team_dark: ShaderMaterial   ## G-B: the darker slate courses (team colour x TEAM_DARK)
const TEAM_MID := 0.87   ## G-F round 2: the middle slate shade (team colour x this)
var mat_team_mid: ShaderMaterial    ## G-F round 2: the middle slate shade
const SITE_HALF := 3.0       ## G-F round 2: site pad half size (6 x 6 m footprint)
const SITE_PLINTH_AT := 0.07 ## G-F round 2: below this progress (the walls start) the squashed plinth stays hidden
var _site_pad: Node3D
var _dress: ShadowDress


func _setup_palette() -> void:
	kingdom_color = Color(0.42, 0.22, 0.60)
	glow_color = Color(0.70, 0.30, 1.00)
	stone_color = Color(0.20, 0.17, 0.26)
	dark_color = Color(0.09, 0.07, 0.13)
	metal_color = Color(0.47, 0.45, 0.57)   # G-B: darker iron-silver (was 0.55 0.52 0.66)
	stripe_color = Color(0.55, 0.52, 0.66)
	glyph_color = Color(0.70, 0.30, 1.00)
	glyph_shape = 1
	smoke_color = Color(0.12, 0.09, 0.16)
	dust_color = Color(0.18, 0.15, 0.22)
	decal_color = Color(0.07, 0.03, 0.10)
	crack_strength = 0.45
	light_color = Color(0.62, 0.30, 1.0)
	light_energy = 1.6
	danger_ramp_hot = Color(0.95, 0.75, 1.0)
	danger_ramp_mid = Color(0.8, 0.4, 1.0)
	danger_ramp_end = Color(0.3, 0.1, 0.5)


## G-B: the darker slate courses follow the team colour (x TEAM_DARK; G-F round 2: x TEAM_MID too). Subclasses with
## their own list keep theirs.
func _vc_team() -> Array:
	var out: Array = [mat_team]
	if mat_team_dark:
		out.append([mat_team_dark, TEAM_DARK])
	if mat_team_mid:
		out.append([mat_team_mid, TEAM_MID])
	return out


## G-F round 2 (docs/art/gf_r2_buildings_fs.md, gf_review2 item 3): a slate gable along Z (ridge at x = cx), the same
## outline as FireHallModel._gable_roof (so _gable_point / the roof holes still fit). A stone core (the gables), then
## per slope `courses` rows of single slates about `slate_w` wide, every other row offset half a slate, each slate
## tilted flatter than the roof so its lower edge stands proud (a shadow line per row), in three team shades (dark,
## mid, team) picked per slate with a lighter row every other course; a thick dark eave board; the eave row's slates
## alternate long / short (sawtooth); a dark ridge cap; iron bargeboards on the gable ends. Appended to `items`
## (one painted surface after the merge: no new draw call). Sets mat_team_dark / mat_team_mid.
func _slate_roof(items: Array, cx: float, cz: float, half: float, eave_y: float, rise: float, depth: float,
		core_depth: float, courses: int, slate_w: float, rng_seed: int) -> void:
	if mat_team_dark == null:
		mat_team_dark = _painted_mat(kingdom_color.darkened(1.0 - TEAM_DARK), 0.1, 0.0)
	if mat_team_mid == null:
		mat_team_mid = _painted_mat(kingdom_color.darkened(1.0 - TEAM_MID), 0.1, 0.0)
	var box1: BoxMesh = _boxm(Vector3.ONE)
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var slope_l: float = sqrt(half * half + rise * rise)
	var a: float = atan2(rise, half)
	var hc: float = half - 0.35
	var ch: float = hc * tan(a) - 0.05
	items.append(BMG.item(_prism(Vector3(hc * 2.0, ch, core_depth), 0.5), Vector3(cx, eave_y + 0.08 + ch * 0.5, cz),
		mat_stone))
	var course_l: float = slope_l / float(courses)
	var n_across: int = maxi(int(round(depth / slate_w)), 2)
	var sw: float = depth / float(n_across)
	var z0: float = cz - depth * 0.5
	var z1: float = cz + depth * 0.5
	var shades: Array[ShaderMaterial] = [mat_team_dark, mat_team_mid, mat_team]
	for s: float in [-1.0, 1.0]:
		var e := Vector3(cx + s * half, eave_y, cz)
		var u := Vector3(-s * cos(a), sin(a), 0.0)   # up the slope
		var n := Vector3(s * sin(a), cos(a), 0.0)    # out of the slope
		var tilt: Basis = Basis(Vector3.BACK, -s * (a - deg_to_rad(7.0)))
		# Eave board: a thick dark fascia under the first row (the roof's edge has a thickness from above).
		items.append(BMG.item_xf(box1, Transform3D(Basis(Vector3.BACK, -s * a).scaled_local(Vector3(0.5, 0.24, depth + 0.16)),
			e + u * 0.12 + n * 0.02), mat_dark))
		for k: int in courses:
			var off: float = 0.5 * sw if k % 2 == 1 else 0.0
			var row_base: int = 1 if k % 2 == 0 else 2   # value step per course: mid / light rows
			for j: int in range(-1, n_across + 1):
				var za: float = maxf(z0 + sw * float(j) + off, z0)
				var zb: float = minf(z0 + sw * float(j + 1) + off, z1)
				if zb - za < 0.18:
					continue
				var shade: int = row_base
				var r: float = rng.randf()
				if r < 0.22:
					shade = 0
				elif r < 0.36:
					shade = 2 if row_base == 1 else 1
				var long_l: float = course_l + 0.16
				var dl: float = rng.randf_range(-0.04, 0.04)
				if k == 0 and j % 2 == 0:
					long_l += 0.2   # sawtooth eave
					dl -= 0.1
				var p: Vector3 = e + u * ((float(k) + 0.5) * course_l + dl) + n * (0.13 + 0.015 * float(k % 2))
				p.z = (za + zb) * 0.5
				var yaw := Basis(n, deg_to_rad(rng.randf_range(-2.5, 2.5)))
				items.append(BMG.item_xf(box1, Transform3D((yaw * tilt).scaled_local(Vector3(long_l, 0.09, zb - za - 0.05)), p),
					shades[shade]))
		# Iron bargeboards on the gable ends.
		for z: float in [z0 - 0.1, z1 + 0.1]:
			var bp: Vector3 = e + u * (slope_l * 0.5) + n * 0.24
			items.append(BMG.item_xf(box1, Transform3D(Basis(Vector3.BACK, -s * a).scaled_local(
				Vector3(slope_l + 0.2, 0.3, 0.22)), Vector3(bp.x, bp.y, z)), mat_metal))
	# Dark ridge cap (a saddle of dark slate) with a thin iron ridge line on top.
	items.append(BMG.item(_prism(Vector3(1.0, 0.46, depth + 0.14), 0.5), Vector3(cx, eave_y + rise + 0.1, cz), mat_dark))
	items.append(BMG.item(box1, Vector3(cx, eave_y + rise + 0.36, cz), mat_metal, Vector3.ZERO, Vector3(0.1, 0.08, depth + 0.1)))


## G-B: tier-scaled dressing (dead ground, mist, wisps, embers from the damage points, a soft light at Ultra;
## nothing at Low). The Gloom Bazaar and the Dread Paddock inherit it (same 6 x 6 m footprint).
func _post_build() -> void:
	super()
	var pts: Array = []
	pts.append_array(_smoke_points)
	pts.append_array(_blaze_points)
	var lp: Vector3 = _light.position if _light else Vector3(1.4, 2.6, -3.5)
	_dress = ShadowDress.attach(self, {"radius": 6.3, "inner": 3.3, "top": _top_y, "mist": 3.7, "seed": 4.1,
		"wisp_r": 3.3, "wisp_y": Vector2(1.0, 6.0), "glow": _dress_glow(), "embers": pts.slice(0, 3), "light": lp,
		"light_energy": 1.0, "light_range": 7.0})


func set_construction_progress(p: float) -> void:
	super(p)
	_site_look()
	if _dress and not _destroyed:
		_dress.sync(_progress, _health_ratio, false)


func set_health_ratio(r: float) -> void:
	super(r)
	if _dress and not _destroyed:
		_dress.sync(_progress, _health_ratio, false)


func play_destroyed() -> void:
	super()
	if _site_pad:
		_site_pad.visible = false
	if _dress:
		_dress.sync(1.0, 0.0, true)


## G-F round 2 (gf_review2 item 8): the site pad (ShadowDress.site_pad_items) under every Shadow hall-type site, built
## before the painted merge so it draws with the merged material. The Bazaar / Paddock / Forge inherit it.
func _build_state_nodes() -> void:
	super()
	var flag_a: ShaderMaterial = _painted_mat(stone_color.lightened(0.26), 0.0, 0.0)
	var flag_b: ShaderMaterial = _painted_mat(stone_color.lightened(0.12), 0.0, 0.0)
	_site_pad = Node3D.new()
	_site_pad.name = "SitePad"
	add_child(_site_pad)
	_merged("SitePadParts", "site_pad", ShadowDress.site_pad_items(SITE_HALF, 6650, flag_a, flag_b, _scaffold_mat(),
		mat_dark), _site_pad, false)
	_site_pad.visible = false


## A site: the pad and the scaffold from the first frame; below SITE_PLINTH_AT the plinth (a flat black slab when
## squashed) stays hidden, so a fresh site is worked ground, not a hole.
func _site_look() -> void:
	if not _ready_done or _destroyed:
		return
	var building: bool = _progress < 1.0
	if _site_pad:
		_site_pad.visible = building
	if _scaffold:
		_scaffold.visible = building
	var plinth := _body.get_node_or_null(^"PlinthBase") as Node3D
	if plinth and building and _progress < SITE_PLINTH_AT:
		plinth.visible = false


func set_team_color(c: Color) -> void:
	super(c)
	if _dress:
		_dress.set_glow(_dress_glow())


func _dress_glow() -> Color:
	return glow_color if _team_color.is_equal_approx(kingdom_color) else _team_color.lightened(0.35)


func _cloth_of(c: Color) -> Color:
	return c.darkened(0.4)


func _light_wave(_n: float) -> float:
	var speed: float = 4.0 * TAU if _flicker_amp > 0.2 else 2.1
	var amp: float = 0.25 if _flicker_amp > 0.2 else 0.15
	return 1.0 - amp + amp * sin(_t * speed)


func _idle_motion(_delta: float) -> void:
	if _orb:
		_orb.position.y = _orb_y + 0.12 * sin(_t * 2.5)
		_orb.rotation.y = _t * 0.8


## Gloom Hall parts (Body space, gate -Z). Heights: plinth 0.8, walls 4.2, roof ridge 7.6, spire finial 11.9.
func _build_structure() -> void:
	_top_y = 12.2
	var box1: BoxMesh = _boxm(Vector3.ONE)
	var rng := RandomNumberGenerator.new()
	rng.seed = 6602
	# --- Plinth: two dark tiers, corner blocks, steps, flagstones and a little graveyard at the back-right.
	var it: Array = []
	it.append(BMG.item(box1, Vector3(0, 0.25, 0), mat_dark, Vector3.ZERO, Vector3(6.4, 0.5, 6.4)))
	it.append(BMG.item(box1, Vector3(0, 0.65, 0), mat_dark, Vector3.ZERO, Vector3(5.8, 0.3, 5.8)))
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1)]:
		it.append(BMG.item(box1, Vector3(c.x * 2.72, 0.95, c.y * 2.72), mat_dark, Vector3.ZERO, Vector3(0.75, 0.4, 0.75)))
	it.append(BMG.item(box1, Vector3(0.6, 0.14, -3.45), mat_dark, Vector3.ZERO, Vector3(2.6, 0.28, 0.55)))
	for i: int in 3:
		var p := Vector3(0.6 + rng.randf_range(-0.3, 0.3), 0.04, -4.0 - 0.7 * i)
		it.append(BMG.item(box1, p, mat_dark, Vector3(0, rng.randf_range(-20, 20), 0),
			Vector3(rng.randf_range(0.8, 1.0), 0.1, rng.randf_range(0.55, 0.65))))
	for g: Array in [[Vector3(2.35, 0.8, 2.45), Vector3(-8, 20, 6)], [Vector3(3.3, 0.5, 1.7), Vector3(10, 75, -4)],
			[Vector3(1.35, 0.8, 2.6), Vector3(6, -10, -10)]]:
		var b := Basis.from_euler(Vector3(deg_to_rad(g[1].x), deg_to_rad(g[1].y), deg_to_rad(g[1].z)))
		it.append(BMG.item_xf(box1, Transform3D(b.scaled_local(Vector3(0.62, 0.8, 0.22)), g[0] + b * Vector3(0, 0.4, 0)),
			mat_stone))
		it.append(BMG.item_xf(_cyl(0.31, 0.31, 0.22, 8), Transform3D(b * Basis(Vector3.RIGHT, PI * 0.5),
			g[0] + b * Vector3(0, 0.8, 0)), mat_stone))
	# 2026-09-30 detail pass (Art Lab C2 / C3): a rim of cracked grave-slabs on the upper plinth tier in two shades
	# (extra painted shades cost nothing: the hall draws with one merged material), two more small headstones.
	var drng := RandomNumberGenerator.new()   # its own seed: the older parts keep their layout
	drng.seed = 6611
	var slab_a: ShaderMaterial = _painted_mat(stone_color.lightened(0.14), 0.0, 0.0)
	var slab_b: ShaderMaterial = _painted_mat(dark_color.lightened(0.1), 0.1, 0.0)
	for k: int in 16:
		var side: int = k / 4
		var t: float = -2.2 + 1.47 * float(k % 4)
		var fp: Vector3 = [Vector3(t, 0, -2.62), Vector3(2.62, 0, t), Vector3(-t, 0, 2.62), Vector3(-2.62, 0, -t)][side]
		if fp.distance_to(Vector3(0.6, 0, -2.62)) < 1.2 or fp.distance_to(Vector3(2.4, 0, 2.3)) < 1.3:
			continue   # the gate steps, the little graveyard
		it.append(BMG.item(box1, fp + Vector3(0, 0.815, 0), slab_a if k % 3 != 1 else slab_b,
			Vector3(drng.randf_range(-1.5, 1.5), drng.randf_range(-6, 6), drng.randf_range(-1.5, 1.5)),
			Vector3(1.3, 0.07, 0.5) if side % 2 == 0 else Vector3(0.5, 0.07, 1.3)))
	for g2: Array in [[Vector3(3.0, 0.8, 2.85), -14.0], [Vector3(1.8, 0.8, 3.0), 9.0]]:
		var gb := Basis.from_euler(Vector3(deg_to_rad(float(g2[1])), deg_to_rad(float(g2[1]) * 2.0), 0))
		it.append(BMG.item_xf(box1, Transform3D(gb.scaled_local(Vector3(0.42, 0.55, 0.16)), g2[0] + gb * Vector3(0, 0.27, 0)),
			slab_a))
	_merged("PlinthBase", "plinth", it)
	# --- Walls tier: stone box, base course, corner pillars, pointed gate, lancet windows, buttresses, brazier bowl.
	it = []
	it.append(BMG.item(box1, Vector3(GX, 2.5, GZ), mat_stone, Vector3.ZERO, Vector3(4.4, 3.4, 4.8)))
	it.append(BMG.item(box1, Vector3(GX, 1.02, GZ), mat_dark, Vector3.ZERO, Vector3(4.7, 0.45, 5.1)))
	for c: Vector2 in [Vector2(-1.8, -2.2), Vector2(2.6, -2.2), Vector2(-1.8, 2.6), Vector2(2.6, 2.6)]:
		it.append(BMG.item(box1, Vector3(c.x, 2.6, c.y), mat_dark, Vector3.ZERO, Vector3(0.6, 3.6, 0.6)))
	# Gate (-Z): dark frame, pointed arch, glowing slits (box + point), silver arch trims and a spike on top.
	it.append(BMG.item(box1, Vector3(0.6, 2.1, -2.3), mat_dark, Vector3.ZERO, Vector3(2.3, 2.6, 0.7)))
	it.append(BMG.item(_prism(Vector3(2.3, 1.5, 0.7), 0.5), Vector3(0.6, 4.15, -2.3), mat_dark))
	it.append(BMG.item(box1, Vector3(0.6, 1.85, -2.7), mat_gate, Vector3.ZERO, Vector3(1.4, 2.1, 0.12)))
	it.append(BMG.item(_prism(Vector3(1.4, 0.8, 0.12), 0.5), Vector3(0.6, 3.3, -2.7), mat_gate))
	var arch_a: float = atan2(1.5, 1.15)
	for s: float in [-1.0, 1.0]:
		it.append(BMG.item_xf(box1, Transform3D(Basis(Vector3.BACK, -s * arch_a).scaled_local(Vector3(1.95, 0.26, 0.8)),
			Vector3(0.6 + s * 0.6, 4.18, -2.32)), mat_metal))
	it.append(BMG.item(_cyl(0.0, 0.2, 0.9, 4), Vector3(0.6, 5.3, -2.3), mat_metal, Vector3(0, 45, 0)))
	# Lancet windows (portcullis glow): right, back x2, left front.
	for w: Array in [[Vector3(2.66, 2.7, 0.2), true], [Vector3(-1.86, 2.7, -1.0), true],
			[Vector3(-0.1, 2.7, 2.66), false], [Vector3(1.4, 2.7, 2.66), false]]:
		var p: Vector3 = w[0]
		var side: bool = w[1]
		var fsz := Vector3(0.2, 1.9, 0.7) if side else Vector3(0.7, 1.9, 0.2)
		var gsz := Vector3(0.1, 1.4, 0.36) if side else Vector3(0.36, 1.4, 0.1)
		var inward := Vector3(-signf(p.x - GX) * 0.06, 0, 0) if side else Vector3(0, 0, -0.06)
		it.append(BMG.item(box1, p + inward, mat_dark, Vector3.ZERO, fsz))
		it.append(BMG.item(box1, p, mat_gate, Vector3.ZERO, gsz))
		it.append(BMG.item(_cyl(0.0, 0.5, 0.55, 4), p + inward + Vector3(0, 1.2, 0), mat_dark, Vector3.ZERO,
			Vector3(1.0, 1.0, 0.4) if not side else Vector3(0.4, 1.0, 1.0)))
	# Buttresses (right side, +X): stone wedges leaning on the wall, a silver cap along each slope.
	var ba: float = atan2(3.0, 0.8)
	for z: float in [-1.0, 1.4]:
		it.append(BMG.item(_prism(Vector3(0.8, 3.0, 0.62), 0.0), Vector3(3.0, 2.3, z), mat_dark))
		it.append(BMG.item_xf(box1, Transform3D(Basis(Vector3.BACK, PI * 0.5 - ba).scaled_local(Vector3(0.22, 3.2, 0.72)),
			Vector3(3.1, 2.33, z)), mat_metal))
	# Soul brazier bowl (front right) with a silver rim; the orb floats above it (own node, animated).
	it.append(BMG.item(_cyl(0.55, 0.35, 1.0, 6), Vector3(2.65, 1.3, -2.7), mat_dark))
	it.append(BMG.item(_cyl(0.62, 0.62, 0.14, 6), Vector3(2.65, 1.82, -2.7), mat_metal))
	# Detail pass: quoins up the four corner pillars (alternating long / short, two shades).
	for c: Vector2 in [Vector2(-1.8, -2.2), Vector2(2.6, -2.2), Vector2(-1.8, 2.6), Vector2(2.6, 2.6)]:
		for q: int in 6:
			var long_x: bool = (q % 2 == 0)
			it.append(BMG.item(box1, Vector3(c.x, 1.25 + 0.58 * q, c.y), slab_a if q % 2 == 0 else mat_stone,
				Vector3(0, drng.randf_range(-3, 3), 0), Vector3(0.8 if long_x else 0.68, 0.24, 0.68 if long_x else 0.8)))
	_merged("Walls", "walls", it)
	# --- Roof tier: stone gables, 4 slate courses a side, silver ridge + crest of spikes, finials, rose window.
	it = []
	# G-F round 2 (gf_review2 item 3): real slates (staggered rows of single slates in three team shades, a dark ridge
	# cap, a thick eave board and a sawtooth eave course) instead of six flat team planks a side.
	_slate_roof(it, GX, GZ, G_HALF, G_EAVE, G_RISE, 5.8, 5.0, 6, 0.62, 6630)
	# G-B: iron spikes jutting from both eaves.
	for sx: float in [-1.0, 1.0]:
		for k: int in 5:
			var ep := Vector3(GX + sx * (G_HALF + 0.05), G_EAVE - 0.05, GZ - 2.4 + 1.2 * k)
			var eb: Basis = Basis(Quaternion(Vector3.UP, Vector3(sx, -0.35, 0).normalized()))
			it.append(BMG.item_xf(_cyl(0.0, 0.08, 0.5, 4), Transform3D(eb, ep + eb * Vector3(0, 0.22, 0)), mat_metal))

	var ridge_y: float = G_EAVE + G_RISE
	for i: int in 8:
		it.append(BMG.item(_cyl(0.0, 0.18, 0.7, 4), Vector3(GX, ridge_y + 0.55, GZ - 2.45 + 0.7 * i), mat_metal,
			Vector3(0, 45, 0)))
	for z: float in [GZ - 3.0, GZ + 3.0]:
		it.append(BMG.item(_cyl(0.0, 0.32, 1.5, 4), Vector3(GX, ridge_y + 0.7, z), mat_metal, Vector3(0, 45, 0)))
	it.append(BMG.item(_cyl(0.72, 0.72, 0.2, 12), Vector3(GX, 6.0, GZ - 2.52), mat_dark, Vector3(90, 0, 0)))
	it.append(BMG.item(_cyl(0.54, 0.54, 0.1, 12), Vector3(GX, 6.0, GZ - 2.64), mat_gate, Vector3(90, 0, 0)))
	it.append(BMG.item(_cyl(0.5, 0.5, 0.18, 10), Vector3(GX, 5.6, GZ + 2.55), mat_dark, Vector3(90, 0, 0)))
	var roof := _merged("Roof", "roof", it)
	_hide_on_collapse.append(roof)
	var hole_l: Vector3 = _gable_point(GX, G_HALF, G_EAVE, G_RISE, -1.0, 0.55, 0.34, GZ - 0.6)
	var hole_r: Vector3 = _gable_point(GX, G_HALF, G_EAVE, G_RISE, 1.0, 0.4, 0.34, GZ + 1.0)
	_show_below_50.append(_roof_hole("RoofHoleL", roof, hole_l, -1.0, G_HALF, G_RISE, false))
	_show_below_25.append(_roof_hole("RoofHoleR", roof, hole_r, 1.0, G_HALF, G_RISE, true))
	# --- Dominant vertical: the bell tower (back left): lantern slits, pinnacles, a slender spire.
	var tower := Node3D.new()
	tower.name = "BellTower"
	tower.position = Vector3(-2.15, PLINTH_TOP, 1.5)
	_body.add_child(tower)
	it = []
	it.append(BMG.item(box1, Vector3(0, 0.6, 0), mat_dark, Vector3.ZERO, Vector3(1.95, 1.2, 1.95)))
	it.append(BMG.item(box1, Vector3(0, 3.7, 0), mat_stone, Vector3.ZERO, Vector3(1.6, 7.4, 1.6)))
	it.append(BMG.item(box1, Vector3(0, 5.2, 0), mat_metal, Vector3.ZERO, Vector3(1.95, 0.4, 1.95)))
	it.append(BMG.item(box1, Vector3(0, 6.4, 0), mat_glow, Vector3.ZERO, Vector3(1.7, 1.1, 0.5)))
	it.append(BMG.item(box1, Vector3(0, 6.4, 0), mat_glow, Vector3.ZERO, Vector3(0.5, 1.1, 1.7)))
	# Detail pass: the tower's stones stand proud in courses (two shades).
	for k: int in 16:
		var face: int = k % 4
		var fy: float = 1.6 + 0.85 * float(k / 4) + 0.3 * float(face % 2)
		var fd: Vector3 = [Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0), Vector3(0, 0, -1)][face]
		var along := Vector3(absf(fd.z), 0, absf(fd.x))
		it.append(BMG.item(box1, fd * 0.82 + along * drng.randf_range(-0.45, 0.45) + Vector3(0, fy, 0),
			slab_a if k % 2 == 0 else slab_b, Vector3.ZERO, along * 0.55 + fd.abs() * 0.1 + Vector3(0, 0.28, 0)))
	_merged("TowerStack", "tower_stack", it, tower)
	it = []
	it.append(BMG.item(box1, Vector3(0, 7.4, 0), mat_dark, Vector3.ZERO, Vector3(2.05, 0.4, 2.05)))
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		it.append(BMG.item(_cyl(0.0, 0.2, 1.0, 4), Vector3(c.x * 0.85, 8.1, c.y * 0.85), mat_metal, Vector3(0, 45, 0)))
	it.append(BMG.item(_cyl(0.0, 1.25, 3.6, 4), Vector3(0, 9.4, 0), mat_team, Vector3(0, 45, 0)))
	it.append(BMG.item(_cyl(0.0, 0.14, 1.0, 4), Vector3(0, 11.4, 0), mat_metal, Vector3(0, 45, 0)))
	var spire := _merged("TowerTop", "tower_top", it, tower)
	var tower_banner := _banner("TowerBanner", Vector2(1.0, 2.0), Vector3(0, 4.0, -0.85), 0.0, tower)
	_falling = tower
	_fall_axis = Vector3.RIGHT
	_fall_deg = 30.0
	_hide_below_50.append(spire)
	_hide_below_25.append(tower_banner)
	_hide_on_collapse.append(tower_banner)
	var bl := _banner("BannerL", Vector2(0.85, 2.0), Vector3(-0.95, 3.2, -2.32), 0.0)
	var br := _banner("BannerR", Vector2(0.85, 2.0), Vector3(2.15, 3.2, -2.32), 0.0)
	_hide_on_collapse.append(bl)
	_hide_on_collapse.append(br)
	# --- Pike rack (front left): a bar on two posts and four tall silver pikes.
	var rack := Node3D.new()
	rack.name = "PikeRack"
	_body.add_child(rack)
	it = []
	it.append(BMG.item(box1, Vector3(-2.2, 1.9, -2.75), mat_metal, Vector3.ZERO, Vector3(2.0, 0.3, 0.3)))
	for x: float in [-3.05, -1.35]:
		it.append(BMG.item(box1, Vector3(x, 1.2, -2.75), mat_dark, Vector3.ZERO, Vector3(0.3, 1.4, 0.3)))
	for i: int in 4:
		it.append(BMG.item(_cyl(0.0, 0.19, 3.0, 4), Vector3(-3.0 + 0.53 * i, 2.3, -2.75), mat_metal,
			Vector3(0, 45, -6.0 + 4.0 * i)))
	_merged("RackParts", "rack", it, rack)
	_hide_on_collapse.append(rack)
	# --- Soul orb (animated) over the brazier.
	_orb_y = 2.2
	var orb := _part("SoulOrb", _sphere(0.36), Vector3(2.65, _orb_y, -2.7), mat_glow)
	orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_orb = orb
	_hide_on_collapse.append(orb)
	_light = _omni(Vector3(1.4, 2.6, -3.5), 7.5)
	# Idle particles: soul flame at the brazier, motes rising around the hall, ground mist (~44).
	var flame := _pm(Vector3.UP, 14.0, 0.9, 1.4, Vector3.ZERO, 0.45, 0.1, _fire_ramp)
	flame.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	flame.emission_sphere_radius = 0.25
	_idle_fx.append(_particles("SoulFlame", _body, Vector3(2.65, 1.9, -2.7), 14, 0.8, flame, _add_quad, false))
	var motes := _pm(Vector3.UP, 30.0, 0.3, 0.7, Vector3.ZERO, 0.12, 0.05,
		_ramp(Color(0.55, 0.32, 0.78), Color(0.25, 0.08, 0.42), false))   # G-B leftovers: under the bloom (no white puffs)
	motes.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	motes.emission_ring_axis = Vector3.UP
	motes.emission_ring_radius = 3.0
	motes.emission_ring_inner_radius = 2.0
	motes.emission_ring_height = 0.1
	motes.orbit_velocity_min = 0.08
	motes.orbit_velocity_max = 0.12
	_idle_fx.append(_particles("VoidMotes", _body, Vector3(0, 1.0, 0), 22, 4.0, motes, _add_quad, false))
	var mist := _pm(Vector3(1, 0, 0), 180.0, 0.1, 0.25, Vector3.ZERO, 1.2, 2.4,
		_ramp(Color(0.25, 0.12, 0.38, 0.28), Color(0.25, 0.12, 0.38), false))
	mist.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	mist.emission_ring_axis = Vector3.UP
	mist.emission_ring_radius = 3.4
	mist.emission_ring_inner_radius = 2.6
	mist.emission_ring_height = 0.05
	_idle_fx.append(_particles("GroundMist", self, Vector3(0, 0.35, 0), 8, 6.0, mist, _mix_quad, false))
	_build_scaffold(GX, GZ, 5.3, 5.7, 4.6)
	_build_wreck(GX, GZ, 4.4, 4.8, PLINTH_TOP + 3.4 * 0.3, Vector3(-2.15, 1.75, 1.5), Vector3(1.6, 1.9, 1.6), 6161)
	_scorch_decal(Vector3(2.2, 0.035, 2.6), 3.2, Color(0.12, 0.04, 0.18, 0.5))
	_smoke_points = [hole_l + Vector3(0, 0.3, 0), Vector3(-0.8, 4.8, -1.0)]
	_blaze_points = [hole_r + Vector3(0, 0.2, 0), Vector3(-2.15, 8.0, 1.5)]
	_rubble2_points = [Vector3(-3.0, 0.9, 2.8), Vector3(-2.2, 0.9, 3.2), Vector3(-3.35, 0.5, 1.4), Vector3(-1.2, 1.2, 2.9)]
	_gate_pos = Vector3(0.6, 1.6, -2.9)


func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 12
	s.rings = 6
	return s
