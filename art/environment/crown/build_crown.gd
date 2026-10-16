extends SceneTree
## Generates the Ember Crown centrepiece (task A2.3): the ruined altar art/environment/crown_pedestal.tscn and
## the crown model art/environment/crown/ember_crown_mesh.res. Run it WINDOWED (headless drops mesh data):
##   Godot_v4.7.2-stable_win64_console.exe --path . -s res://art/environment/crown/build_crown.gd --quit-after 120
## Local space: metres, y up, root = the crown's spot on the ground; the crown gem floats at y 1.8.
## Footprint: stepped octagonal dais r 2.3 (0.42 m high, walkable-looking: the crown's pickup radius is 2.2),
## 4 curved "fang" monoliths at the diagonals (tips 3.1 m, one broken), 4 rune stones at r 2.95 on the
## cardinals (the seal chains are anchored to them), the ruin dressing ring (r 8-10.6) from build_env.gd.

const Kit := preload("res://art/environment/crown/mesh_kit.gd")
const DIR := "res://art/environment/crown/"
const SCENE_PATH := "res://art/environment/crown_pedestal.tscn"
const ART_SCRIPT := "res://art/environment/crown/crown_pedestal_art.gd"
const DRESSING := "res://art/environment/meshes/crown_ruin_dressing.res"
const CROWN_Y := 1.8

# Palette (sRGB). Stone keeps saturation <= 0.2 (art-keep 0.2), gold and ember are the accents.
const STONE_P := Color(0.64, 0.61, 0.64)     # pale ruin stone (fangs, rune stones)
const STONE := Color(0.53, 0.50, 0.55)
const STONE_D := Color(0.39, 0.36, 0.41)
const BASALT := Color(0.17, 0.14, 0.19)      # dark core (makes the glow pop)
const BASALT_L := Color(0.27, 0.23, 0.29)
const FANG := Color(0.30, 0.26, 0.33)         # dark fangs frame the bright crown (value contrast)
const FANG_L := Color(0.42, 0.37, 0.45)
const GOLD := Color(0.9, 0.64, 0.24)
const GOLD_D := Color(0.64, 0.4, 0.13)
const MOSS := Color(0.26, 0.40, 0.17, 0.55)
const MOSS_L := Color(0.30, 0.42, 0.20, 0.35)
const W := Color.WHITE

var mats: Dictionary = {}


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	_make_materials()
	var crown: ArrayMesh = _build_crown_mesh()
	var altar: Array = _build_altar()
	var ring: ArrayMesh = _build_seal_ring()
	_pack_scene(altar[0], altar[1], altar[2], ring)
	print("crown mesh surfaces: %d" % crown.get_surface_count())
	print("CROWN BUILD OK")
	quit()


# ------------------------------------------------------------------------------------------ materials

func _save(res: Resource, path: String) -> void:
	var err: int = ResourceSaver.save(res, path, ResourceSaver.FLAG_CHANGE_PATH)
	if err != OK:
		push_error("save failed %s: %d" % [path, err])
	if not res is PackedScene:
		res.take_over_path(path)   # packed scenes then reference the file instead of embedding a copy


func _rune_mat(name: String, glow: Color, core: Color, energy: float, focus: Vector3, flow_speed: float,
		flow_scale: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(DIR + "crown_rune.gdshader") as Shader
	m.set_shader_parameter("glow_color", glow)
	m.set_shader_parameter("core_color", core)
	m.set_shader_parameter("energy", energy)
	m.set_shader_parameter("focus", focus)
	m.set_shader_parameter("flow_speed", flow_speed)
	m.set_shader_parameter("flow_scale", flow_scale)
	_save(m, DIR + name + ".tres")
	return m


func _make_materials() -> void:
	mats["stone"] = load("res://art/environment/env_painted_mat.tres") as Material
	var gold := ShaderMaterial.new()
	gold.shader = load(DIR + "crown_gold.gdshader") as Shader
	gold.set_shader_parameter("noise_tex", load("res://art/shaders/paint_noise.tres") as Texture2D)
	_save(gold, DIR + "crown_gold_mat.tres")
	mats["gold"] = gold
	mats["rune"] = _rune_mat("crown_rune_mat", Color(1.0, 0.50, 0.12), Color(1.0, 0.86, 0.52), 3.2,
			Vector3(0, CROWN_Y, 0), 2.2, 3.2)
	mats["seal"] = _rune_mat("crown_seal_mat", Color(0.85, 0.03, 0.03), Color(1.0, 0.22, 0.14), 2.7,
			Vector3(0, CROWN_Y, 0), 3.2, 4.5)
	mats["lava"] = _rune_mat("crown_lava_mat", Color(0.9, 0.2, 0.04), Color(1.0, 0.6, 0.16), 2.3,
			Vector3(0, CROWN_Y, 0), 1.3, 7.0)
	mats["jewel"] = _rune_mat("crown_jewel_mat", Color(1.0, 0.38, 0.06), Color(1.0, 0.78, 0.4), 3.0,
			Vector3.ZERO, 3.0, 14.0)
	var beacon := ShaderMaterial.new()
	beacon.shader = load(DIR + "crown_beacon.gdshader") as Shader
	_save(beacon, DIR + "crown_beacon_mat.tres")
	mats["beacon"] = beacon
	var pool := ShaderMaterial.new()
	pool.shader = load(DIR + "glow_pool.gdshader") as Shader
	pool.set_shader_parameter("color", Color(1.0, 1.0, 1.0))
	pool.set_shader_parameter("strength", 0.62)
	pool.set_shader_parameter("inner", 0.0)
	pool.set_shader_parameter("falloff", 1.7)
	_save(pool, DIR + "crown_pool_mat.tres")
	mats["pool"] = pool


# ------------------------------------------------------------------------------------------ helpers

static func _lp(p: Vector2, a: float) -> Vector3:
	return Vector3(cos(a) * p.x, p.y, sin(a) * p.x)


## Surface of revolution from a (radius, y) profile. Walk the profile with the solid on the RIGHT
## (up the outside, over the top, down the inside) so the faces point outward. `cols[i]` = band i.
func _lathe(k: Kit, s: String, prof: Array, cols: Array, sides: int, phase: float, top: Color = Kit.NO_TOP,
		jitter: float = 0.0, seed: float = 0.0, surfs: Array = []) -> void:
	for i: int in prof.size() - 1:
		var p0: Vector2 = prof[i]
		var p1: Vector2 = prof[i + 1]
		var d: Vector2 = p1 - p0
		var nrm := Vector2(d.y, -d.x)
		var col: Color = cols[mini(i, cols.size() - 1)]
		var sf: String = s if surfs.is_empty() else String(surfs[mini(i, surfs.size() - 1)])
		for j: int in sides:
			var a0: float = phase + j * TAU / sides
			var a1: float = phase + (j + 1) * TAU / sides
			var am: float = (a0 + a1) * 0.5
			var q: Array = [_lp(p0, a0), _lp(p0, a1), _lp(p1, a1), _lp(p1, a0)]
			if jitter > 0.0:
				for n: int in 4:
					var qp: Vector3 = q[n]
					if Vector2(qp.x, qp.z).length() > 0.001:
						q[n] = qp + Kit.h3(qp.snappedf(0.001) + Vector3(seed, seed, seed)) * jitter
			var hint := Vector3(cos(am) * nrm.x, nrm.y, sin(am) * nrm.x)
			k.quad(sf, q[0], q[1], q[2], q[3], col, hint, top)


## A flat lozenge (rune glyph) lying on a surface: centre `c`, `up` / `side` in the surface, `out` = normal.
func _glyph(k: Kit, s: String, c: Vector3, up: Vector3, side: Vector3, out: Vector3, w: float, h: float) -> void:
	var base: Array = [c - up * h * 0.5, c + side * w * 0.5, c + up * h * 0.5, c - side * w * 0.5]
	var inset: Array = []
	var raised: Array = []
	for p: Vector3 in base:
		inset.append(p - out * 0.02)
		raised.append(c + (p - c) * 0.78 + out * 0.03)
	k.block(s, inset, raised, W)


## An octahedron (jewel / chain link): tips along `axis` (half length `l`), waist `wx` along x_dir, `wz`.
func _octa(k: Kit, s: String, c: Vector3, axis: Vector3, x_dir: Vector3, l: float, wx: float, wz: float,
		col: Color = W) -> void:
	axis = axis.normalized()
	var z_dir: Vector3 = axis.cross(x_dir).normalized()
	x_dir = z_dir.cross(axis).normalized()
	var tips: Array = [c + axis * l, c - axis * l]
	var waist: Array = [c + x_dir * wx, c + z_dir * wz, c - x_dir * wx, c - z_dir * wz]
	for t: Vector3 in tips:
		for i: int in 4:
			var a: Vector3 = waist[i]
			var b: Vector3 = waist[(i + 1) % 4]
			k.tri(s, t, a, b, col, (t + a + b) / 3.0 - c)


## Sector slab of an octagonal step between angles a0..a1, radii r_in..r_out, heights y0..y1.
func _slab(k: Kit, a0: float, a1: float, r_in: float, r_out: float, y0: float, y1: float, batter: float,
		col: Color, top: Color, drop_out: float = 0.0, push: float = 0.0) -> void:
	var d0 := Vector3(cos(a0), 0, sin(a0))
	var d1 := Vector3(cos(a1), 0, sin(a1))
	var dm: Vector3 = (d0 + d1).normalized() * push
	var bot: Array = [d0 * r_in + dm + Vector3(0, y0, 0), d0 * r_out + dm + Vector3(0, y0, 0),
			d1 * r_out + dm + Vector3(0, y0, 0), d1 * r_in + dm + Vector3(0, y0, 0)]
	var tp: Array = [d0 * r_in + dm + Vector3(0, y1, 0), d0 * (r_out - batter) + dm + Vector3(0, y1 - drop_out, 0),
			d1 * (r_out - batter) + dm + Vector3(0, y1 - drop_out, 0), d1 * r_in + dm + Vector3(0, y1, 0)]
	k.block("stone", bot, tp, col, top, col.darkened(0.12))


# ------------------------------------------------------------------------------------------ altar

## Returns [altar mesh (stone + gold), runes mesh, chains mesh].
func _build_altar() -> Array:
	var k := Kit.new()
	k.surf("stone")
	k.surf("gold")
	var r := Kit.new()
	r.face_var = 0.0
	r.surf("rune")   # surface 0: EmberCrown duplicates this one to tint the runes red while sealed
	r.surf("lava")
	var ch := Kit.new()
	ch.face_var = 0.0
	ch.surf("seal")
	var ph: float = TAU / 16.0

	# --- Step 1: 8 slabs (r 2.3, 0.2 m). Slab 3 (-x) has subsided, slab 6 (+x -z, under the broken fang) lost
	# its outer corner. An ember channel runs down the middle of each slab (continuing the ground grooves).
	for i: int in 8:
		var a0: float = ph + i * TAU / 8.0 + 0.012
		var a1: float = ph + (i + 1) * TAU / 8.0 - 0.012
		var am: float = (a0 + a1) * 0.5
		var hh: float = Kit.h(Vector3(i, 1, 1))
		var y1: float = 0.19 + (hh - 0.5) * 0.035
		var col: Color = STONE_D.lerp(STONE, hh * 0.35)
		if i == 3:
			_slab(k, a0, am - 0.01, 1.2, 2.3, -0.02, y1, 0.07, col, MOSS_L)
			_slab(k, am + 0.01, a1, 1.2, 2.26, -0.06, y1 - 0.02, 0.07, col.darkened(0.06), MOSS_L, 0.11, 0.05)
			_channel(r, am - 0.07, 1.64, 2.12, y1)
		elif i == 6:
			_slab(k, a0, a1, 1.2, 1.98, -0.02, y1, 0.05, col, MOSS_L)
			_channel(r, am, 1.64, 1.86, y1)
		else:
			_slab(k, a0, a1, 1.2, 2.3, -0.02, y1, 0.07, col, MOSS_L)
			_channel(r, am, 1.64, 2.14, y1)
	# --- Step 2: 8 slabs (r 1.62, top 0.42), with the inner half of the channels.
	for i: int in 8:
		var a0: float = ph + i * TAU / 8.0 + 0.014
		var a1: float = ph + (i + 1) * TAU / 8.0 - 0.014
		var hh: float = Kit.h(Vector3(i, 2, 5))
		var y2: float = 0.42 + (hh - 0.5) * 0.02
		_slab(k, a0, a1, 0.6, 1.62, 0.15, y2, 0.05, STONE_D.lerp(STONE, 0.5 + hh * 0.4), Kit.NO_TOP)
		_channel(r, (a0 + a1) * 0.5, 1.02, 1.5, y2)
	# --- Core plinth (dark basalt drum with a ledge), then the gold bowl rim and the ember bed.
	_lathe(k, "stone", [Vector2(1.03, 0.36), Vector2(1.05, 0.47), Vector2(0.93, 0.5), Vector2(0.88, 0.84)],
			[BASALT_L, BASALT_L, BASALT], 8, ph, Kit.NO_TOP, 0.012, 3.0)
	_lathe(k, "gold", [Vector2(0.9, 0.8), Vector2(0.99, 0.9), Vector2(0.98, 0.97), Vector2(0.92, 1.01),
			Vector2(0.77, 1.0), Vector2(0.74, 0.9)], [GOLD_D, GOLD, GOLD, GOLD, GOLD_D], 8, ph)
	# Molten ember pool in the bowl (glows, dims when the crown is gone) under a broken dark crust.
	_lathe(r, "lava", [Vector2(0.76, 0.9), Vector2(0.45, 0.875), Vector2(0.0, 0.865)], [W, W], 16, 0.0)
	_lathe(k, "stone", [Vector2(0.76, 0.84), Vector2(0.0, 0.84)], [BASALT], 8, ph)
	for i: int in 17:
		var a2: float = i * 2.39996 + 0.9
		var rr: float = 0.08 + sqrt(float(i) / 17.0) * 0.6
		var s: float = 0.1 + Kit.h(Vector3(i, 4, 4)) * 0.09
		var p := Vector3(cos(a2) * rr, 0.885, sin(a2) * rr)
		k.prim("stone", _sph(s, 6, 3), _xf(p, Vector3(0.1, a2, 0.08), Vector3(1.35, 0.42, 1.1)),
				BASALT_L.lerp(BASALT, Kit.h(Vector3(i, 7, 1))), 0.03, Kit.NO_TOP, 30.0 + i)
	# Plinth glyphs: a lozenge on each of the 8 faces.
	for i: int in 8:
		var a: float = i * TAU / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var fd: float = 0.905 * cos(PI / 8.0)
		_glyph(r, "rune", d * fd + Vector3(0, 0.66, 0), Vector3(0, 1, 0.0), Vector3(-sin(a), 0, cos(a)), d, 0.2, 0.3)

	# --- Fangs: the two toward the default camera (+z) are lower, the back pair taller (a throne back).
	for i: int in 4:
		_fang(k, r, PI / 4.0 + i * PI / 2.0, i == 3, 100.0 + i * 17.0, 0.8 if i < 2 else 1.06)

	# --- Rune stones on the cardinals + the seal chains anchored to them.
	for i: int in 4:
		var b: float = i * PI / 2.0
		var anchor: Vector3 = _stub(k, r, b, i == 1, 0.14 if i == 3 else 0.04 * (i - 1.5), 200.0 + i * 11.0)
		var d := Vector3(cos(b), 0, sin(b))
		_chain(ch, anchor, d * 0.98 + Vector3(0, CROWN_Y - 0.05, 0), 300.0 + i)

	# --- Rubble on and around the dais (low, flat, where it broke).
	var rub: Array = [[Vector3(2.05, 0.08, -1.25), 0.26], [Vector3(2.45, 0.05, -0.55), 0.2], [Vector3(-2.5, 0.05, 0.6), 0.22],
			[Vector3(-1.9, 0.22, -1.2), 0.16], [Vector3(0.9, 0.06, 2.45), 0.18], [Vector3(-0.6, 0.05, -2.55), 0.2],
			[Vector3(1.55, 0.26, -1.95), 0.14]]
	for j: int in rub.size():
		var p: Vector3 = rub[j][0]
		var s2: float = rub[j][1]
		k.prim("stone", _box(Vector3(s2 * 1.5, s2, s2 * 1.1), 1), _xf(p, Vector3(0.25, j * 1.3, 0.15)),
				STONE_D.lerp(STONE, Kit.h(Vector3(j, 9, 9))), 0.035, MOSS, 60.0 + j)

	var stone_mesh: ArrayMesh = k.commit(DIR + "crown_altar.res", {"stone": mats["stone"], "gold": mats["gold"]})
	var rune_mesh: ArrayMesh = r.commit(DIR + "crown_runes.res", {"rune": mats["rune"], "lava": mats["lava"]})
	var chain_mesh: ArrayMesh = ch.commit(DIR + "crown_seal_chains.res", {"seal": mats["seal"]})
	return [stone_mesh, rune_mesh, chain_mesh]


## A glowing channel (ember inlay) along the top of a dais slab, radial at angle `a` from r0 to r1.
func _channel(r: Kit, a: float, r0: float, r1: float, y: float) -> void:
	var d := Vector3(cos(a), 0, sin(a))
	var t := Vector3(-sin(a), 0, cos(a))
	var w0: float = 0.05
	var w1: float = 0.035
	var bot: Array = [d * r0 - t * w0 + Vector3(0, y - 0.02, 0), d * r1 - t * w1 + Vector3(0, y - 0.02, 0),
			d * r1 + t * w1 + Vector3(0, y - 0.02, 0), d * r0 + t * w0 + Vector3(0, y - 0.02, 0)]
	var tp: Array = []
	for p: Vector3 in bot:
		tp.append(p + Vector3(0, 0.032, 0))
	r.block("rune", bot, tp, W)


## A curved monolith leaning over the crown: basalt collar, dark stone body, two gold bands, gold claw tip,
## three glyphs on the side facing the crown. `broken`: snapped at 1.8 m, its top lies on the ground.
## `hs` scales its height (front pair 0.8, back pair 1.06).
func _fang(k: Kit, r: Kit, a: float, broken: bool, seed: float, hs: float = 1.0) -> void:
	var d := Vector3(cos(a), 0, sin(a))
	var ctrl: Array = [Vector2(1.30, 0.26), Vector2(1.43, 0.95), Vector2(1.41, 1.65), Vector2(1.25, 2.30),
			Vector2(0.99, 2.78), Vector2(0.78, 3.08)]
	var rad: Array[float] = [0.29, 0.26, 0.215, 0.165, 0.1, 0.0]
	var cp: Array = []
	for c: Vector2 in ctrl:
		cp.append(d * c.x + Vector3(0, 0.26 + (c.y - 0.26) * hs, 0))
	var tip_y: float = 0.26 + (3.08 - 0.26) * hs
	var sp: Array = Kit.spline(cp, 3)
	var n: int = sp.size()
	var rings: Array = []
	var frames: Array = []
	var radii: Array[float] = []
	for i: int in n:
		var tp: float = float(i) / float(n - 1) * float(rad.size() - 1)
		var i0: int = mini(int(floor(tp)), rad.size() - 2)
		var rr: float = lerpf(rad[i0], rad[i0 + 1], tp - i0)
		var tan: Vector3 = (sp[mini(i + 1, n - 1)] - sp[maxi(i - 1, 0)]).normalized()
		var fr: Array = Kit.frame(tan, d)
		frames.append([tan, fr[0], fr[1]])
		radii.append(rr)
		rings.append(Kit.ring(sp[i], fr[0], fr[1], rr * 0.85, rr, 6, PI / 6.0, 0.018 if rr > 0.01 else 0.0, seed + i))
	var cut: int = n - 1
	if broken:
		for i: int in n:
			if (sp[i] as Vector3).y >= 1.8:
				cut = i
				break
	var surfs: Array = []
	var cols: Array = []
	for i: int in n - 1:
		var y: float = ((sp[i] as Vector3).y + (sp[i + 1] as Vector3).y) * 0.5
		if y > tip_y - 0.5:
			surfs.append("gold")
			cols.append(GOLD)
		elif y < 0.5:
			surfs.append("stone")
			cols.append(BASALT)
		else:
			surfs.append("stone")
			cols.append(FANG.lerp(FANG_L, Kit.h(Vector3(i, seed, 2)) * 0.6 + float(i) / n * 0.4))
	if not broken:
		k.sweep(rings, sp, surfs, cols, true, false)
	else:
		var low: Array = rings.slice(0, cut + 1)
		k.sweep(low, sp.slice(0, cut + 1), surfs, cols, true, false)
		_jagged_cap(k, low[cut], sp[cut], frames[cut][0], seed, FANG_L)
		# The snapped top lies on the ground beside the dais (on its side, half sunk).
		var hi: Array = rings.slice(cut)
		var hc: Array = sp.slice(cut)
		var axis: Vector3 = ((hc[hc.size() - 1] as Vector3) - (hc[0] as Vector3)).normalized()
		var a2: float = a - 0.52
		var target: Vector3 = Vector3(-sin(a2), -0.12, cos(a2)).normalized()
		var rot := Basis(Quaternion(axis, target)) * Basis(axis, 0.0)
		var at: Vector3 = Vector3(cos(a2), 0, sin(a2)) * 2.62 + Vector3(0, 0.2, 0)
		var xf := Transform3D(Basis(target, 0.7) * rot, at) * Transform3D(Basis.IDENTITY, -(hc[0] as Vector3))
		var hr: Array = []
		var hcc: Array = []
		for ring: PackedVector3Array in hi:
			var t := PackedVector3Array()
			for p: Vector3 in ring:
				t.append(xf * p)
			hr.append(t)
		for p: Vector3 in hc:
			hcc.append(xf * p)
		k.sweep(hr, hcc, surfs.slice(cut), cols.slice(cut), false, false, MOSS)
		_jagged_cap(k, hr[0], hcc[0], -((hcc[1] as Vector3) - (hcc[0] as Vector3)).normalized(), seed + 5.0, FANG_L)
	# Gold bands (sleeves) at ~0.62 m and ~1.5 m (scaled with the fang).
	for band_y: float in [0.26 + 1.24 * hs]:
		var bi: int = 0
		for i: int in n:
			if (sp[i] as Vector3).y >= band_y:
				bi = i
				break
		if broken and bi >= cut:
			continue
		var c: Vector3 = sp[bi]
		var tan2: Vector3 = frames[bi][0]
		var rr2: float = radii[bi] * 1.13
		var br: Array = []
		var bc: Array = []
		for off: float in [-0.09, 0.09]:
			var cc: Vector3 = c + tan2 * off
			br.append(Kit.ring(cc, frames[bi][1], frames[bi][2], rr2 * 0.85, rr2, 6, PI / 6.0))
			bc.append(cc)
		k.sweep(br, bc, ["gold"], [GOLD], true, true)
	# Glyphs on the face turned to the crown (-x of the frame).
	for gy: float in [0.26 + 0.69 * hs, 0.26 + 0.96 * hs, 0.26 + 1.76 * hs]:
		var gi: int = 0
		for i: int in n:
			if (sp[i] as Vector3).y >= gy:
				gi = i
				break
		if broken and gi >= cut:
			continue
		var tan3: Vector3 = frames[gi][0]
		var inward: Vector3 = -(frames[gi][1] as Vector3)
		var side: Vector3 = frames[gi][2]
		var c2: Vector3 = (sp[gi] as Vector3) + inward * (radii[gi] * 0.85 * 0.866 + 0.004)
		_glyph(r, "rune", c2, tan3, side, inward, 0.17, 0.28)


## Jagged broken end: rim points pushed along `out` by a hashed amount, a sunken centre.
func _jagged_cap(k: Kit, ring: PackedVector3Array, centre: Vector3, out: Vector3, seed: float, col: Color) -> void:
	var m: int = ring.size()
	var rim: Array = []
	for j: int in m:
		var hh: float = Kit.h(Vector3(j, seed, 7))
		rim.append(ring[j] + out * (0.04 + hh * 0.22 * (0.4 if j % 3 == 1 else 1.0)))
	var mid: Vector3 = centre + out * 0.03
	for j: int in m:
		var jn: int = (j + 1) % m
		# Break face wall between the clean ring and the jagged rim, then the rough top.
		k.quad("stone", ring[j], ring[jn], rim[jn], rim[j], col, ((ring[j] + ring[jn]) * 0.5 - centre))
		k.tri("stone", mid, rim[j], rim[jn], col.darkened(0.1), out)


## A rune stone at angle b (r 2.95) with a gold anchor band and a glyph facing the crown. Returns the
## chain anchor point.
func _stub(k: Kit, r: Kit, b: float, broken: bool, tilt: float, seed: float) -> Vector3:
	var d := Vector3(cos(b), 0, sin(b))
	var t := Vector3(-sin(b), 0, cos(b))
	var base: Vector3 = d * 2.95
	var bs := Basis(t, -tilt)
	var hgt: float = 0.58 if broken else 0.86
	var pts := func(hx: float, hz: float, y: float) -> Array:
		return [base + bs * (t * -hx + d * -hz + Vector3(0, y, 0)), base + bs * (t * hx + d * -hz + Vector3(0, y, 0)),
				base + bs * (t * hx + d * hz + Vector3(0, y, 0)), base + bs * (t * -hx + d * hz + Vector3(0, y, 0))]
	k.block("stone", pts.call(0.27, 0.23, -0.08), pts.call(0.2, 0.17, hgt), STONE_P.lerp(STONE, Kit.h(Vector3(seed, 1, 1)) * 0.5),
			MOSS, STONE)
	if broken:
		# Snapped top: a tilted jagged chunk on it and one on the ground.
		k.prim("stone", _box(Vector3(0.36, 0.16, 0.3), 1), Transform3D(bs * Basis.from_euler(Vector3(0.35, 0.4, 0.2)),
				base + bs * Vector3(0, hgt + 0.03, 0)), STONE_P, 0.04, MOSS, seed)
		k.prim("stone", _box(Vector3(0.34, 0.24, 0.28), 1), _xf(base + t * 0.5 + d * 0.25 + Vector3(0, 0.07, 0),
				Vector3(0.3, b + 0.7, 0.4)), STONE_P.darkened(0.05), 0.04, MOSS, seed + 1.0)
	else:
		var apex: Vector3 = base + bs * Vector3(0, hgt + 0.28, 0)
		var top_pts: Array = pts.call(0.2, 0.17, hgt)
		for j: int in 4:
			k.tri("gold", apex, top_pts[j], top_pts[(j + 1) % 4], GOLD, (apex + top_pts[j] + top_pts[(j + 1) % 4]) / 3.0
					- (base + bs * Vector3(0, hgt, 0)))
	# Gold anchor band.
	var band_y: float = hgt - 0.24
	var f: float = lerpf(1.0, 0.2 / 0.27, (band_y + 0.08) / (hgt + 0.08))
	k.block("gold", pts.call(0.27 * f + 0.035, 0.23 * f + 0.035, band_y - 0.07),
			pts.call(0.27 * f + 0.035, 0.23 * f + 0.035, band_y + 0.07), GOLD, Kit.NO_TOP, GOLD_D)
	# Glyph on the inner face.
	var gy: float = band_y - 0.28
	var fz: float = lerpf(0.23, 0.17, (gy + 0.08) / (hgt + 0.08))
	_glyph(r, "rune", base + bs * (-d * (fz + 0.003) + Vector3(0, gy, 0)), bs * Vector3.UP, t, -(bs * d), 0.17, 0.26)
	return base + bs * (Vector3(0, band_y, 0) - d * 0.3)


## A glowing chain from `a` to `b`, sagging a little: alternating octahedral links.
func _chain(k: Kit, a: Vector3, b: Vector3, seed: float) -> void:
	var mid: Vector3 = (a + b) * 0.5 - Vector3(0, 0.22, 0)
	var length: float = a.distance_to(b) * 1.08
	var count: int = int(ceil(length / 0.2))
	for i: int in count:
		var t0: float = float(i) / count
		var t1: float = float(i + 1) / count
		var p0: Vector3 = _qb(a, mid, b, t0)
		var p1: Vector3 = _qb(a, mid, b, t1)
		var axis: Vector3 = (p1 - p0).normalized()
		var side: Vector3 = axis.cross(Vector3.UP).normalized()
		if i % 2 == 1:
			side = axis.cross(side).normalized()
		_octa(k, "seal", (p0 + p1) * 0.5, axis, side, 0.13, 0.085, 0.042)
	# Shackle rings where the chain meets the stone.
	_octa(k, "seal", a, Vector3.UP, (b - a).normalized(), 0.1, 0.1, 0.1)


static func _qb(a: Vector3, m: Vector3, b: Vector3, t: float) -> Vector3:
	return a.lerp(m, t).lerp(m.lerp(b, t), t)


# ------------------------------------------------------------------------------------------ seal ring

## One seal ring (radius 1, centred): 8 flat runic arcs with gaps, a tooth on every other arc. The scene uses it
## 3 times (scaled 0.95 / 1.07 / 1.19, tilted like an armillary cage around the crown).
func _build_seal_ring() -> ArrayMesh:
	var k := Kit.new()
	k.face_var = 0.0
	k.surf("seal")
	var arcs: int = 8
	for i: int in arcs:
		var a0: float = i * TAU / arcs + 0.09
		var a1: float = (i + 1) * TAU / arcs - 0.09
		var rings: Array = []
		var cs: Array = []
		for s: int in 6:
			var a: float = lerpf(a0, a1, s / 5.0)
			var d := Vector3(cos(a), 0, sin(a))
			var c: Vector3 = d
			var ring := PackedVector3Array([c - d * 0.045 - Vector3(0, 0.11, 0), c + d * 0.045 - Vector3(0, 0.11, 0),
					c + d * 0.045 + Vector3(0, 0.11, 0), c - d * 0.045 + Vector3(0, 0.11, 0)])
			rings.append(ring)
			cs.append(c)
		k.sweep(rings, cs, ["seal"], [W], true, true)
		# A tooth (rune notch) sticking out in the middle of every other arc.
		var am: float = (a0 + a1) * 0.5
		var dm := Vector3(cos(am), 0, sin(am))
		var tm := Vector3(-sin(am), 0, cos(am))
		if i % 2 == 1:
			continue
		var hh: float = 0.17
		var bot: Array = [dm * 1.03 - tm * 0.045 - Vector3(0, hh, 0), dm * 1.13 - tm * 0.045 - Vector3(0, hh, 0),
				dm * 1.13 + tm * 0.045 - Vector3(0, hh, 0), dm * 1.03 + tm * 0.045 - Vector3(0, hh, 0)]
		var tp: Array = []
		for p: Vector3 in bot:
			tp.append(p + Vector3(0, hh * 2.0, 0))
		k.block("seal", bot, tp, W)
	return k.commit(DIR + "crown_seal_ring.res", {"seal": mats["seal"]})


# ------------------------------------------------------------------------------------------ the crown

## The Ember Crown model, centred on the gem anchor (Artifact._gem: y 1.8 on the altar, scale 0.55 worn):
## a gold circlet with 8 flame-shaped tines (tall / short), jewels on the band, and a floating ember heart.
func _build_crown_mesh() -> ArrayMesh:
	var k := Kit.new()
	k.surf("gold")
	k.surf("jewel")
	var S: float = 1.35
	var sv := func(v: Vector2) -> Vector2:
		return v * S
	# Band (closed profile walked clockwise: up the outside, over the top, down the inside, back along the bottom).
	var prof: Array = [Vector2(0.41, -0.17), Vector2(0.45, -0.13), Vector2(0.43, -0.09), Vector2(0.43, 0.02),
			Vector2(0.47, 0.06), Vector2(0.44, 0.085), Vector2(0.36, 0.085), Vector2(0.35, -0.17), Vector2(0.41, -0.17)]
	var sp: Array = []
	for p: Vector2 in prof:
		sp.append(sv.call(p))
	_lathe(k, "gold", sp, [GOLD_D, GOLD, GOLD, GOLD, GOLD, GOLD, GOLD_D, GOLD_D], 16, 0.0)
	# Tines.
	for i: int in 8:
		var a: float = i * TAU / 8.0
		var d := Vector3(cos(a), 0, sin(a))
		var tall: bool = i % 2 == 0
		var ctrl: Array = [Vector2(0.43, 0.04), Vector2(0.48, 0.19), Vector2(0.455, 0.35), Vector2(0.40, 0.49)] if tall \
				else [Vector2(0.43, 0.04), Vector2(0.47, 0.15), Vector2(0.445, 0.26), Vector2(0.415, 0.33)]
		var wid: Array[float] = [0.09, 0.075, 0.045, 0.0]
		if not tall:
			wid = [0.075, 0.06, 0.035, 0.0]
		var cp: Array = []
		for c: Vector2 in ctrl:
			cp.append((d * c.x + Vector3(0, c.y, 0)) * S)
		var spl: Array = Kit.spline(cp, 3)
		var rings: Array = []
		for q: int in spl.size():
			var tp: float = float(q) / float(spl.size() - 1) * 3.0
			var i0: int = mini(int(floor(tp)), 2)
			var w: float = lerpf(wid[i0], wid[i0 + 1], tp - i0) * S
			var tan: Vector3 = (spl[mini(q + 1, spl.size() - 1)] - spl[maxi(q - 1, 0)]).normalized()
			var fr: Array = Kit.frame(tan, d)
			rings.append(Kit.ring(spl[q], fr[0], fr[1], w * 0.42 + (0.012 * S if w > 0.0 else 0.0), w, 4, 0.0))
		k.sweep(rings, spl, ["gold"], [GOLD], false, false)
		# Jewel at the foot of each tall tine, small jewels on the band between tines.
		if tall:
			_octa(k, "jewel", (d * 0.49 + Vector3(0, 0.13, 0)) * S, d, Vector3.UP, 0.035 * S, 0.06 * S, 0.06 * S)
		var ab: float = a + TAU / 16.0
		var db := Vector3(cos(ab), 0, sin(ab))
		_octa(k, "jewel", (db * 0.445 + Vector3(0, -0.035, 0)) * S, db, Vector3.UP, 0.025 * S, 0.045 * S, 0.045 * S)
	# The ember heart floating inside the circlet (6-sided bipyramid).
	var top_tip := Vector3(0, 0.31, 0) * S
	var bot_tip := Vector3(0, -0.2, 0) * S
	var waist: Array = []
	for i: int in 6:
		var a3: float = i * TAU / 6.0
		waist.append(Vector3(cos(a3) * 0.17, 0.05, sin(a3) * 0.17) * S)
	var hc := Vector3(0, 0.05, 0) * S
	for i: int in 6:
		var p0: Vector3 = waist[i]
		var p1: Vector3 = waist[(i + 1) % 6]
		k.tri("jewel", top_tip, p0, p1, W, (top_tip + p0 + p1) / 3.0 - hc)
		k.tri("jewel", bot_tip, p0, p1, W, (bot_tip + p0 + p1) / 3.0 - hc)
	return k.commit(DIR + "ember_crown_mesh.res", {"gold": mats["gold"], "jewel": mats["jewel"]})


# ------------------------------------------------------------------------------------------ primitives

func _sph(r: float, segs: int = 7, rings: int = 4) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = segs
	m.rings = rings
	return m


func _box(size: Vector3, sub: int = 0) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	m.subdivide_width = sub
	m.subdivide_height = sub
	m.subdivide_depth = sub
	return m


func _xf(pos: Vector3, rot: Vector3 = Vector3.ZERO, s: Vector3 = Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot) * Basis.from_scale(s), pos)


# ------------------------------------------------------------------------------------------ scene

func _mi(parent: Node3D, mesh: Mesh, name: String, shadow: bool, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh
	mi.position = pos
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	if not shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


## Open cone for the beacon: bottom radius r0 at y 0, top r1 at y h. UV.x = angle 0-1, UV.y = 0 bottom -> 1 top,
## smooth outward normals. Saved as crown_beacon.res with the beacon material.
func _beacon_mesh(r0: float, r1: float, h: float, segs: int) -> ArrayMesh:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var uv := PackedVector2Array()
	var idx := PackedInt32Array()
	var rows: int = 4
	for row: int in rows + 1:
		var t: float = float(row) / rows
		var rr: float = lerpf(r0, r1, t)
		for s: int in segs + 1:
			var a: float = float(s) / segs * TAU
			v.append(Vector3(cos(a) * rr, t * h, sin(a) * rr))
			n.append(Vector3(cos(a), (r0 - r1) / h, sin(a)).normalized())
			uv.append(Vector2(float(s) / segs, t))
	for row: int in rows:
		for s: int in segs:
			var i0: int = row * (segs + 1) + s
			var i1: int = i0 + 1
			var i2: int = i0 + segs + 1
			var i3: int = i2 + 1
			idx.append_array([i0, i2, i1, i1, i2, i3])
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = n
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	mesh.surface_set_material(0, mats["beacon"])
	_save(mesh, DIR + "crown_beacon.res")
	return mesh


func _soft_dot() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.35, Color(1, 1, 1, 0.55))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 32
	t.height = 32
	return t


func _spark_mat(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.disable_fog = true  # G-E 5: an additive quad must not fog
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.billboard_keep_scale = true   # G-F billboard pass: the particle scale applies (docs/art/gf_billboard.md)
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _soft_dot()
	m.albedo_color = col
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	return m


func _fade_curve() -> CurveTexture:
	var c := Curve.new()
	c.add_point(Vector2(0.0, 0.2))
	c.add_point(Vector2(0.15, 1.0))
	c.add_point(Vector2(0.7, 0.7))
	c.add_point(Vector2(1.0, 0.0))
	var ct := CurveTexture.new()
	ct.curve = c
	return ct


func _ramp(cols: Array[Color], offs: Array[float]) -> GradientTexture1D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(offs)
	g.colors = PackedColorArray(cols)
	var t := GradientTexture1D.new()
	t.gradient = g
	return t


func _pack_scene(altar: ArrayMesh, runes: ArrayMesh, chains: ArrayMesh, ring: ArrayMesh) -> void:
	var root := Node3D.new()
	root.name = "CrownPedestal"
	root.set_script(load(ART_SCRIPT))
	_mi(root, altar, "Stone", true)
	_mi(root, runes, "Runes", false)
	if ResourceLoader.exists(DRESSING):
		_mi(root, load(DRESSING) as Mesh, "RuinDressing", true)
	# Seal: 3 rings around the crown (armillary cage) + 4 chains to the rune stones.
	var rings_root := Node3D.new()
	rings_root.name = "SealRings"
	rings_root.position = Vector3(0, CROWN_Y + 0.02, 0)
	root.add_child(rings_root)
	var tilts: Array[Vector3] = [Vector3(0.38, 0.0, 0.0), Vector3(0.0, 1.1, -0.5), Vector3(-0.3, 2.2, 0.62)]
	var scales: Array[float] = [0.95, 1.07, 1.19]
	for i: int in 3:
		var rm: MeshInstance3D = _mi(rings_root, ring, "Ring%d" % i, false)
		rm.basis = Basis.from_euler(tilts[i]).scaled(Vector3.ONE * scales[i])
	_mi(root, chains, "SealChains", false)
	# Beacon: open cone of soft light above the claimable crown.
	_mi(root, _beacon_mesh(0.6, 1.25, 7.0, 24), "Beacon", false, Vector3(0, 1.0, 0))
	# Glow pool on the plaza.
	var plane := PlaneMesh.new()
	plane.size = Vector2(12.0, 12.0)
	plane.material = mats["pool"]
	_mi(root, plane, "GroundGlow", false, Vector3(0, 0.03, 0))
	# Embers rising from the bowl.
	var quad := QuadMesh.new()
	quad.size = Vector2(0.13, 0.13)
	quad.material = _spark_mat(Color(2.6, 1.55, 0.7))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = Vector3.UP
	pm.emission_ring_radius = 0.55
	pm.emission_ring_inner_radius = 0.1
	pm.emission_ring_height = 0.05
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 14.0
	pm.initial_velocity_min = 0.45
	pm.initial_velocity_max = 1.0
	pm.gravity = Vector3(0, 0.22, 0)
	pm.orbit_velocity_min = 0.04
	pm.orbit_velocity_max = 0.1
	pm.scale_min = 0.55
	pm.scale_max = 1.15
	pm.scale_curve = _fade_curve()
	pm.color_ramp = _ramp([Color(1, 1, 0.85, 1), Color(1, 0.7, 0.35, 0.9), Color(1, 0.35, 0.1, 0)], [0.0, 0.45, 1.0])
	var em := GPUParticles3D.new()
	em.name = "Embers"
	em.amount = 22
	em.lifetime = 2.6
	em.preprocess = 2.6
	em.randomness = 0.4
	em.fixed_fps = 30
	em.interpolate = true
	em.local_coords = true
	em.process_material = pm
	em.draw_pass_1 = quad
	em.position = Vector3(0, 0.95, 0)
	em.visibility_aabb = AABB(Vector3(-2, -1, -2), Vector3(4, 5, 4))
	em.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(em)
	# The seal shattering (one shot, fired by crown_pedestal_art.gd when it unseals).
	var quad2 := QuadMesh.new()
	quad2.size = Vector2(0.2, 0.2)
	quad2.material = _spark_mat(Color(3.0, 0.9, 0.45))
	var pb := ParticleProcessMaterial.new()
	pb.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pb.emission_sphere_radius = 0.8
	pb.direction = Vector3(0, 1, 0)
	pb.spread = 180.0
	pb.initial_velocity_min = 3.0
	pb.initial_velocity_max = 6.5
	pb.gravity = Vector3(0, -7.0, 0)
	pb.damping_min = 1.0
	pb.damping_max = 2.0
	pb.scale_min = 0.6
	pb.scale_max = 1.4
	pb.scale_curve = _fade_curve()
	pb.color_ramp = _ramp([Color(1, 0.95, 0.8, 1), Color(1, 0.3, 0.12, 1), Color(0.8, 0.1, 0.05, 0)], [0.0, 0.35, 1.0])
	var burst := GPUParticles3D.new()
	burst.name = "SealBurst"
	burst.amount = 56
	burst.lifetime = 1.2
	burst.one_shot = true
	burst.explosiveness = 0.95
	burst.emitting = false
	burst.fixed_fps = 30
	burst.interpolate = true
	burst.local_coords = true
	burst.process_material = pb
	burst.draw_pass_1 = quad2
	burst.position = Vector3(0, CROWN_Y, 0)
	burst.visibility_aabb = AABB(Vector3(-6, -3, -6), Vector3(12, 8, 12))
	burst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(burst)

	_own(root, root)
	var ps := PackedScene.new()
	var err: int = ps.pack(root)
	if err != OK:
		push_error("pack failed %d" % err)
	_save(ps, SCENE_PATH)
	root.free()


func _own(n: Node, root: Node) -> void:
	for c: Node in n.get_children():
		c.owner = root
		_own(c, root)
