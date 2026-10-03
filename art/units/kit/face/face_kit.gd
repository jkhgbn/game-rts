class_name FaceKit
extends RefCounted
## FACE KIT (face rework 2026-09-28): eyes, lips / smile, expressions, ears, hair and beards for any humanoid model, as
## ONE extra node (a FaceRig under the Head pivot) drawing ONE vertex-coloured surface = 1 draw call (optionally + the
## surfaces a spec appends). Shared material (unit_face.tres / unit_face.gdshader: COLOR = sRGB colour, alpha = 1 -
## glow), meshes cached per unit type and expression (built on the first instance, never in a fight).
##
## ---- API (one call, in the model's _build_parts):
##   _face = FaceKit.attach(self, $Root/Chest/Head, "my_unit", {
##       "center": Vector3(0, 1.78, 0.02),    # model-space face centre (the head sphere's centre)      REQUIRED
##       "radius": 0.25,                      # face / head sphere radius (features scale with it)      REQUIRED
##       "head_mesh": sphere(0.25, 12, 6),    # the mesh the decals are projected on (default: that sphere)
##       "head_scale": Vector3.ONE,           # its add_part scale (non-uniform heads)
##       "preset": &"bright",                 # bright | gentle | stern | elder | hollow | plain (PRESETS)
##       "skin": Color(...), "hair": Color(...), "hair_tip": Color(...), "eyes": Color(...),   # iris colour
##       "ears": &"round",                    # round | pointed | none
##       "hair_style": &"bob",                # none | crop | fringe | bob | long | bun | ponytail | braid
##       "hairline": 0.5,                     # 0-1: how much forehead shows
##       "beard": &"none",                    # none | moustache | full | spade (+ "beard_color", "beard_tip")
##       "detail": &"low",                    # soldiers / workers: coarser decals, 3 crown locks (~40 % fewer vertices)
##       "palette": {...}, "eye": {...}, "brow": {...}, "cheek": {...}, "mouth": {...}, "x": {...},   # overrides
##       "hair_fn": func(acc): ...,           # custom hair instead of hair_style (FaceKit.lock / braid / cap / put_mesh)
##   })
##   (or pass a full style dictionary with "canvas": see the wizards' _face_style()).
## ---- expressions (one setter):  _face.set_expression(&"smile")   # neutral | smile | fierce | worried | shout
##   aliases angry -> fierce, sad -> worried, cast -> shout, happy / laugh -> smile; get_expression().
## ---- per frame (the model's _extra_process / _wizard_process):  _face.auto(self)
##   while the requested expression is neutral: cast = shout, attack = fierce, level-up = smile, dying = worried
##   (tier 0, < 30 m); at tier >= 1 (the default RTS zoom) the bold FAR face (thick lashes / brows / lips) so the eyes
##   and the smile still make pixels. _face.react(mood) for your own moods, _face.reset() after a revive.
## ---- glow: vertex alpha < 1 glows (irises, gems, glowing mouths); the kit drives glow_boost on the node, or set meta
##   own_glow and write glow_boost yourself.
## ---- budget: ~800-1400 vertices for face + short hair (DENSITY), 1 draw call; keep hair below the chin short (the cine
##   face framing reads the Head meshes' height).
## Face 2D space: metres of arc around the face centre, +x = model +X, +y = up; +x features are mirrored with sx = -1.
## Expressions (defaults X_DEFAULT): neutral (the resting look: a warm closed smile, eyes open, soft happy lower lids),
## smile (open smile, happy eyes that stay OPEN), fierce (angry), worried (sad / worried), shout (cast / shout).

const EXPRESSIONS: Array[StringName] = [&"neutral", &"smile", &"fierce", &"worried", &"shout"]
const ALIASES := {&"angry": &"fierce", &"sad": &"worried", &"cast": &"shout", &"happy": &"smile", &"laugh": &"smile"}
const MAT_PATH := "res://art/units/kit/face/unit_face.tres"
## The RTS-distance face (FaceRig shows it at kit tier >= 1, i.e. 30 m+, the default game zoom): the neutral face with
## BOLD features (lash lines, pupils, brows and lips x style "bold", default 1.9; no tiny highlights / creases) so the
## eyes and the smile still make pixels from the game camera. Cinematic / close cameras (tier 0) get the fine face.
const FAR := &"far"
## Decal sampling (steps along outlines, ring spacing): 1.0 = fine; higher = fewer vertices (facet ridges may poke
## through thin decals on coarse heads: raise the canvas lift then).
const DENSITY := 1.9
## The sampling used while a face is being built (style "density", default DENSITY; "detail": &"low" = 3.0).
static var _dens: float = DENSITY

## Default expression parameters (a style's "x" dictionary overrides any key per expression).
## open: upper lid height scale · low: lower lid lift 0-1 (happy squint) · cut_in: angry lid slant at the nose side ·
## cut_out: sad droop at the outer side · look: iris offset · brow: [inner dy, middle dy, outer dy] (m) · brow_in_dx:
## inner end moves toward the nose · mouth: kind (closed / open / frown / grimace / shout / smirk) + its numbers ·
## blush: cheek strength · lines: smile lines by the mouth corners.
const X_DEFAULT := {
	&"neutral": {"open": 1.0, "low": 0.34, "cut_in": 0.0, "cut_out": 0.0, "look": Vector2(0, 0), "brow": [0.0, 0.0, 0.0],
		"brow_in_dx": 0.0, "mouth": {"kind": "closed", "curve": 1.0, "w": 1.0}, "blush": 1.0, "lines": false},
	&"smile": {"open": 0.92, "low": 0.66, "cut_in": 0.0, "cut_out": 0.0, "look": Vector2(0, 0.001), "brow": [0.008, 0.012, 0.004],
		"brow_in_dx": 0.0, "mouth": {"kind": "open", "w": 1.12, "depth": 1.0, "top": 0.25}, "blush": 1.35, "lines": true},
	&"fierce": {"open": 0.9, "low": 0.22, "cut_in": 0.8, "cut_out": 0.0, "look": Vector2(0, 0), "brow": [-0.019, -0.006, 0.010],
		"brow_in_dx": -0.006, "mouth": {"kind": "grimace", "w": 1.05, "depth": 1.25}, "blush": 0.0, "lines": false},
	&"worried": {"open": 1.04, "low": 0.08, "cut_in": 0.0, "cut_out": 0.5, "look": Vector2(0, -0.002), "brow": [0.020, 0.010, -0.008],
		"brow_in_dx": -0.004, "mouth": {"kind": "frown", "w": 0.85, "curve": 1.9, "open": 0.85}, "blush": 0.35, "lines": false},
	&"shout": {"open": 1.22, "low": 0.0, "cut_in": 0.3, "cut_out": 0.0, "look": Vector2(0, 0.001), "brow": [-0.010, 0.004, 0.014],
		"brow_in_dx": -0.004, "mouth": {"kind": "shout", "w": 0.86, "depth": 1.8}, "blush": 0.6, "lines": false},
}

static var _cache: Dictionary = {}
static var _mat: Material


static func canonical(id: StringName) -> StringName:
	if EXPRESSIONS.has(id):
		return id
	return ALIASES.get(id, &"neutral")


static func material() -> Material:
	if _mat == null:
		_mat = load(MAT_PATH)
	return _mat


## Colour with a glow amount (0 = painted, 1 = fully emissive), as the face shader reads it.
static func glow(c: Color, amount: float) -> Color:
	return Color(c.r, c.g, c.b, 1.0 - clampf(amount, 0.0, 1.0))


## A painting canvas: face centre (model space), arc radius r, the head mesh (its triangles, scaled by scl and
## offset so they are relative to the centre: `mesh_at` = where the mesh's origin sits in model space). `lift` raises
## every decal (coarse head meshes: facet ridges poke through decals that sit only 1-2 mm out).
static func canvas(c: Vector3, r: float, head_mesh: Mesh, scl: Vector3 = Vector3.ONE, mesh_at: Vector3 = Vector3.INF,
		rot: Basis = Basis.IDENTITY, lift: float = 0.0) -> Dictionary:
	var at := c if mesh_at == Vector3.INF else mesh_at
	var tris := PackedVector3Array()
	for p: Vector3 in head_mesh.get_faces():
		tris.append(rot * (p * scl) + at - c)
	var dirs := PackedVector3Array()
	for i: int in range(0, tris.size(), 3):
		dirs.append(((tris[i] + tris[i + 1] + tris[i + 2]) / 3.0).normalized())
	return {"c": c, "r": r, "tris": tris, "dirs": dirs, "lift": lift}


static func begin() -> Dictionary:
	return {"v": PackedVector3Array(), "n": PackedVector3Array(), "col": PackedColorArray(), "i": PackedInt32Array()}


## Model-space point + normal of a 2D face point, `lift` m out of the head facets.
static func point(cv: Dictionary, p: Vector2, lift: float) -> Array:
	var r: float = cv["r"]
	var az := p.x / r
	var el := p.y / r
	var d := Vector3(sin(az) * cos(el), sin(el), cos(az) * cos(el))
	# the 6 expressions of a face repeat most points: remember each ray's head distance while warm() runs (exact)
	var memo: Variant = cv.get("_memo")
	if memo != null and (memo as Dictionary).has(p):
		return [(cv["c"] as Vector3) + d * (float(memo[p]) + lift + float(cv.get("lift", 0.0))), d]
	var tris: PackedVector3Array = cv["tris"]
	var dirs: PackedVector3Array = cv["dirs"]
	var dist := -1.0
	for pass_i: int in 2:
		for k: int in dirs.size():
			if pass_i == 0 and dirs[k].dot(d) < 0.55:
				continue
			var i := k * 3
			var hit: Variant = Geometry3D.ray_intersects_triangle(Vector3.ZERO, d, tris[i], tris[i + 1], tris[i + 2])
			if hit != null:
				dist = maxf(dist, (hit as Vector3).length())
		if dist > 0.0:
			break
	if dist < 0.0:
		dist = r
	if memo != null:
		memo[p] = dist
	return [(cv["c"] as Vector3) + d * (dist + lift + float(cv.get("lift", 0.0))), d]


static func _v(acc: Dictionary, cv: Dictionary, p: Vector2, lift: float, col: Color) -> int:
	var pn := point(cv, p, lift)
	acc["v"].append(pn[0])
	acc["n"].append(pn[1])
	acc["col"].append(col)
	return (acc["v"] as PackedVector3Array).size() - 1


## Both windings (the inner copy is culled), shared vertices.
static func _tri(acc: Dictionary, a: int, b: int, c: int) -> void:
	acc["i"].append_array(PackedInt32Array([a, b, c, a, c, b]))


static func _col(col: Variant, p: Vector2) -> Color:
	return (col as Callable).call(p) if col is Callable else col


static func resample(pts: PackedVector2Array, step: float, closed: bool) -> PackedVector2Array:
	step *= _dens
	var out := PackedVector2Array([pts[0]])
	var n := pts.size()
	for i: int in range(1, n + (1 if closed else 0)):
		var a := pts[i - 1]
		var b := pts[i % n]
		var k := maxi(1, ceili(a.distance_to(b) / step))
		for j: int in range(1, k + 1):
			out.append(a.lerp(b, float(j) / float(k)))
	if closed:
		out.remove_at(out.size() - 1)
	return out


## A filled star-shaped polygon (centroid fan + rings so it follows the facets). col: Color or Callable(Vector2) -> Color
## (gradients: blush, iris ring, face shading).
static func fill(acc: Dictionary, cv: Dictionary, poly: PackedVector2Array, col: Variant, lift: float, step: float = 0.009) -> void:
	if poly.size() < 3:
		return
	var b := resample(poly, step, true)
	var c := Vector2.ZERO
	for q: Vector2 in poly:
		c += q
	c /= float(poly.size())
	var far := 0.0
	for q: Vector2 in b:
		far = maxf(far, q.distance_to(c))
	var rings := clampi(ceili(far / (0.022 * _dens)), 1, 4)
	if col is Callable:
		rings = maxi(rings, 2)
	var ci := _v(acc, cv, c, lift, _col(col, c))
	var prev: Array[int] = []
	var n := b.size()
	for r: int in range(1, rings + 1):
		var ring: Array[int] = []
		for k: int in n:
			var q := c.lerp(b[k], float(r) / float(rings))
			ring.append(_v(acc, cv, q, lift, _col(col, q)))
		for k: int in n:
			var k2 := (k + 1) % n
			if r == 1:
				_tri(acc, ci, ring[k], ring[k2])
			else:
				_tri(acc, prev[k], ring[k], ring[k2])
				_tri(acc, prev[k], ring[k2], prev[k2])
		prev = ring


## `poly` clipped to `mask`, each piece filled.
static func fill_clipped(acc: Dictionary, cv: Dictionary, poly: PackedVector2Array, mask: PackedVector2Array, col: Variant,
		lift: float, step: float = 0.006) -> void:
	for piece: PackedVector2Array in Geometry2D.intersect_polygons(poly, mask):
		fill(acc, cv, piece, col, lift, step)


## A tapered band along a polyline; w = half widths at start / middle / end. col: Color or Callable(t 0-1) -> Color.
static func strip(acc: Dictionary, cv: Dictionary, pts: PackedVector2Array, w: Vector3, col: Variant, lift: float, step: float = 0.007) -> void:
	var p := resample(pts, step, false)
	var n := p.size()
	if n < 2:
		return
	var accl := PackedFloat32Array([0.0])
	for i: int in range(1, n):
		accl.append(accl[i - 1] + p[i - 1].distance_to(p[i]))
	var total := maxf(accl[n - 1], 0.0001)
	var pa := -1
	var pb := -1
	for i: int in n:
		var t := accl[i] / total
		var hw := lerpf(w.x, w.y, t * 2.0) if t < 0.5 else lerpf(w.y, w.z, t * 2.0 - 1.0)
		var dir := (p[mini(i + 1, n - 1)] - p[maxi(i - 1, 0)]).normalized()
		var nrm := Vector2(-dir.y, dir.x)
		var c: Color = (col as Callable).call(t) if col is Callable else col
		var ia := _v(acc, cv, p[i] + nrm * hw, lift, c)
		var ib := _v(acc, cv, p[i] - nrm * hw, lift, c)
		if pa >= 0:
			_tri(acc, pa, pb, ib)
			_tri(acc, pa, ib, ia)
		pa = ia
		pb = ib


## 3D geometry in the face mesh (model space), one colour (Torvald's bushy brows move per expression).
static func put_mesh(acc: Dictionary, m: Mesh, xf: Transform3D, col: Color) -> void:
	var arr := m.surface_get_arrays(0)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var nr: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var ix: Variant = arr[Mesh.ARRAY_INDEX]
	var nb := xf.basis.inverse().transposed()
	var b0: int = (acc["v"] as PackedVector3Array).size()
	for j: int in v.size():
		acc["v"].append(xf * v[j])
		acc["n"].append((nb * nr[j]).normalized())
		acc["col"].append(col)
	if ix == null or (ix as PackedInt32Array).is_empty():
		for j: int in v.size():
			acc["i"].append(b0 + j)
	else:
		for j: int in (ix as PackedInt32Array).size():
			acc["i"].append(b0 + (ix as PackedInt32Array)[j])


static func bez(p0: Vector2, p1: Vector2, p2: Vector2, seg: int = 12) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i: int in seg + 1:
		var t := float(i) / float(seg)
		out.append(p0.lerp(p1, t).lerp(p1.lerp(p2, t), t))
	return out


static func ellipse(c: Vector2, r: Vector2, rot_deg: float = 0.0, n: int = 14) -> PackedVector2Array:
	var out := PackedVector2Array()
	var b := Transform2D(deg_to_rad(rot_deg), Vector2.ZERO)
	for i: int in n:
		var a := TAU * float(i) / float(n)
		out.append(c + b * Vector2(cos(a) * r.x, sin(a) * r.y))
	return out


static func mirror(pts: PackedVector2Array, sx: float) -> PackedVector2Array:
	if sx > 0.0:
		return pts
	var out := PackedVector2Array()
	for p: Vector2 in pts:
		out.append(Vector2(-p.x, p.y))
	return out


## Radial gradient colour function: `a` at the centre, `b` from `from` (0-1 of r) out to r.
static func radial(c: Vector2, r: Vector2, a: Color, b: Color, from: float = 0.35) -> Callable:
	return func(p: Vector2) -> Color:
		var d := Vector2((p.x - c.x) / r.x, (p.y - c.y) / r.y).length()
		return a.lerp(b, smoothstep(from, 1.0, d))


# ================================================================ features

## One eye (sx = +1 for the eye on the +x side). s = the style's eye: c (for +x), hw, top, bot, tilt (outer corner
## lift), ir (iris radius), lash (lash width scale), flick (lash flick length). x = expression params. P = palette.
static func eye(acc: Dictionary, cv: Dictionary, s: Dictionary, x: Dictionary, p: Dictionary, sx: float) -> void:
	var c: Vector2 = s["c"]
	c.x *= sx
	var hw: float = s["hw"]
	var top: float = s["top"] * float(x["open"])
	var bot: float = s["bot"]
	var tilt: float = s.get("tilt", 0.0)
	var low: float = x["low"]
	var cut_in: float = x["cut_in"]
	var cut_out: float = x["cut_out"]
	var bold: float = x.get("bold", 1.0)
	var up := PackedVector2Array()
	var lo := PackedVector2Array()
	const N := 12
	for i: int in N + 1:
		var t := float(i) / float(N)
		var xx := c.x + sx * (-hw + 2.0 * hw * t)
		var yb := c.y + tilt * (t - 0.5)
		var sn := pow(sin(PI * t), 0.8)
		var yu := yb + top * sn - top * sn * 1.7 * (cut_in * (1.0 - t) + cut_out * t) * 0.62
		var yl := yb - bot * sn + low * (bot + top * 0.42) * pow(sin(PI * t), 1.2)
		yl = minf(yl, yu - 0.22 * (top + bot) * sn)
		up.append(Vector2(xx, yu))
		lo.append(Vector2(xx, yl))
	var sclera := PackedVector2Array(up)
	var lr := lo.duplicate()
	lr.reverse()
	sclera.append_array(lr.slice(1, lr.size() - 1))
	fill(acc, cv, sclera, p["sclera"], 0.0024, 0.006)
	# shadow of the upper lid on the eye white (a soft band just under the lash line)
	var shade: Color = (p["sclera"] as Color).darkened(0.28)
	var ir: float = s["ir"]
	var look: Vector2 = x["look"]
	var ic := c + look + Vector2(sx * s.get("iris_dx", 0.0), (top - bot) * 0.12)
	var iris_in: Color = p["iris_in"]
	var iris_out: Color = (p["iris_out"] as Color).darkened(clampf((bold - 1.0) * 0.4, 0.0, 0.6))
	var ig: float = p.get("iris_glow", 0.0)
	fill_clipped(acc, cv, ellipse(ic, Vector2(ir, ir * 1.04), 0.0, 16), sclera,
		radial(ic, Vector2(ir, ir), glow(iris_in, ig), glow(iris_out, ig * 0.6), 0.25), 0.0031, 0.005)
	var pr: float = ir * float(s.get("pupil", 0.48)) * (1.0 + (bold - 1.0) * 0.35)
	var pupil := ellipse(ic, Vector2(pr * float(s.get("pupil_w", 1.0)), pr), 0.0, 12)
	fill_clipped(acc, cv, pupil, sclera, glow(p["pupil"], p.get("pupil_glow", 0.0)), 0.0037, 0.005)
	# lid shadow band (clipped to the eye white, over the iris top)
	var band := PackedVector2Array()
	for q: Vector2 in up:
		band.append(q + Vector2(0, 0.004))
	for i: int in range(up.size() - 1, -1, -1):
		band.append(up[i] - Vector2(0, 0.0075 + 0.0035 * sin(PI * float(i) / float(N))))
	fill_clipped(acc, cv, band, sclera, glow(shade.lerp(p["lash"], 0.35), 0.0), 0.0040, 0.005)
	# highlights: same side on both eyes (the light), a big one and a small one
	var hl: Color = p.get("highlight", Color(1, 1, 1))
	var hdir := Vector2(0.38, 0.42)
	if bold <= 1.0:
		fill(acc, cv, ellipse(ic + hdir * ir, Vector2(ir * 0.3, ir * 0.3), 0.0, 8), glow(hl, 0.35), 0.0046, 0.004)
		fill(acc, cv, ellipse(ic - Vector2(0.36, 0.34) * ir, Vector2(ir * 0.14, ir * 0.14), 0.0, 6), glow(hl, 0.35), 0.0046, 0.004)
	# upper lash line (thick, with an outer flick), a thin lower lid line, the lid crease above
	var lw: float = float(s.get("lash", 1.0)) * bold
	var lash := up.slice(1, up.size())
	var flick: float = s.get("flick", 0.010)
	if flick > 0.0:
		lash.append(up[N] + Vector2(sx * flick, flick * 0.75))
	strip(acc, cv, lash, Vector3(0.0012, 0.0034, 0.0030) * lw, p["lash"], 0.0050, 0.005)
	var lower := lo.slice(3, N + 1)
	strip(acc, cv, lower, Vector3(0.0004, 0.0011, 0.0014) * lw, glow((p["lash"] as Color).lerp(p["skin"], 0.45), 0.0), 0.0046, 0.005)
	if bold > 1.0:
		return
	var crease := PackedVector2Array()
	for i: int in range(2, N - 1):
		var t := float(i) / float(N)
		crease.append(up[i] + Vector2(0, 0.0085 + top * 0.18 * sin(PI * t)))
	strip(acc, cv, crease, Vector3(0.0004, 0.0011, 0.0006), (p["skin"] as Color).darkened(0.30), 0.0030, 0.006)
	if low > 0.5:
		# happy cheek fold under the eye
		var fold := PackedVector2Array()
		for i: int in range(3, N - 2):
			fold.append(lo[i] - Vector2(0, 0.010))
		strip(acc, cv, fold, Vector3(0.0003, 0.0010, 0.0003), (p["skin"] as Color).darkened(0.22), 0.0030, 0.006)


## One brow (sx side): s = style brow (inner, mid, outer points for +x, w = half widths inner / mid / outer).
static func brow(acc: Dictionary, cv: Dictionary, s: Dictionary, x: Dictionary, p: Dictionary, sx: float) -> void:
	if s.get("none", false):
		return   # 3D brows built by the model (Torvald)
	var dy: Array = x["brow"]
	var a: Vector2 = s["inner"] + Vector2(float(x["brow_in_dx"]) * -1.0, float(dy[0]))
	var m: Vector2 = s["mid"] + Vector2(0, float(dy[1]))
	var b: Vector2 = s["outer"] + Vector2(0, float(dy[2]))
	var pts := mirror(bez(a, m + (m - (a + b) * 0.5), b), sx)
	var w: Vector3 = s.get("w", Vector3(0.0065, 0.0062, 0.0025)) * (1.0 + (float(x.get("bold", 1.0)) - 1.0) * 0.6)
	strip(acc, cv, pts, w, p["brow"], 0.0034, 0.006)


## Cheek blush (soft: the colour fades to the skin colour at the edge).
static func blush(acc: Dictionary, cv: Dictionary, s: Dictionary, amount: float, p: Dictionary, sx: float) -> void:
	if amount <= 0.01:
		return
	var c: Vector2 = s["c"]
	c.x *= sx
	var r: Vector2 = s["r"] * lerpf(0.85, 1.1, clampf(amount - 0.5, 0.0, 1.0))
	var sk: Color = p["skin"]
	var bl: Color = sk.lerp(p["blush"], clampf(amount, 0.0, 1.4) / 1.4 * 0.95 + 0.05)
	fill(acc, cv, ellipse(c, r, 0.0, 16), radial(c, r, bl, sk, 0.15), 0.0016, 0.008)


## The mouth for one expression. s = style mouth: c (centre), hw (half width), lip (line half width).
static func mouth(acc: Dictionary, cv: Dictionary, s: Dictionary, x: Dictionary, p: Dictionary) -> void:
	var mx: Dictionary = x["mouth"]
	var kind: String = mx["kind"]
	var c: Vector2 = s["c"]
	var hw: float = float(s["hw"]) * float(mx.get("w", 1.0))
	var lip: float = float(s.get("lip", 0.0026)) * float(x.get("bold", 1.0))
	var line_col: Color = p["lip_line"]
	var lip_col: Color = p["lip"]
	var inner: Color = glow(p["mouth_in"], p.get("mouth_glow", 0.0) * (1.0 if kind == "shout" or kind == "open" else 0.5))
	match kind:
		"closed", "smirk":
			# a warm closed smile: the lip line curves up to lifted corners, a fuller lower lip under it, corner dimples
			var cu: float = hw * 0.30 * float(mx.get("curve", 1.0))
			var l := c + Vector2(-hw, cu)
			var r := c + Vector2(hw, cu)
			if kind == "smirk":
				l = c + Vector2(-hw * 0.9, -cu * 0.1)
			var line := bez(l, c + Vector2(0, -cu * 1.25), r)
			strip(acc, cv, line, Vector3(lip * 0.55, lip * 1.05, lip * 0.55), line_col, 0.0036, 0.005)
			var lower := bez(c + Vector2(-hw * 0.45, -cu * 0.95 - lip * 1.6), c + Vector2(0, -cu * 1.25 - lip * 4.2), c + Vector2(hw * 0.45, -cu * 0.95 - lip * 1.6))
			strip(acc, cv, lower, Vector3(lip * 0.3, lip * 1.2, lip * 0.3), lip_col, 0.0028, 0.005)
			for sx: float in [-1.0, 1.0]:
				if kind == "smirk" and sx < 0.0:
					continue
				var k := Vector2(sx * hw, cu) + c
				strip(acc, cv, PackedVector2Array([k + Vector2(-sx * 0.004, -0.001), k + Vector2(sx * 0.004, 0.004)]),
					Vector3(lip * 0.5, lip * 0.5, lip * 0.3), line_col, 0.0036, 0.004)
		"frown":
			var cd: float = hw * 0.26 * float(mx.get("curve", 1.0))
			var op: float = float(mx.get("open", 0.0))
			var top := bez(c + Vector2(-hw, -cd), c + Vector2(0, cd * 1.1), c + Vector2(hw, -cd))
			if op > 0.0:
				var bot := bez(c + Vector2(hw, -cd), c + Vector2(0, cd * 1.1 - hw * 0.55 * op), c + Vector2(-hw, -cd))
				var poly := PackedVector2Array(top)
				poly.append_array(bot.slice(1, bot.size() - 1))
				fill(acc, cv, poly, inner, 0.0026, 0.005)
				strip(acc, cv, bot, Vector3(lip * 0.3, lip * 0.7, lip * 0.3), line_col, 0.0036, 0.005)
				var lower := bez(c + Vector2(-hw * 0.5, cd * 0.2 - hw * 0.5 * op - lip * 2.6), c + Vector2(0, cd * 0.6 - hw * 0.5 * op - lip * 3.4), c + Vector2(hw * 0.5, cd * 0.2 - hw * 0.5 * op - lip * 2.6))
				strip(acc, cv, lower, Vector3(lip * 0.3, lip * 1.0, lip * 0.3), lip_col, 0.0028, 0.005)
			strip(acc, cv, top, Vector3(lip * 0.5, lip * 0.9, lip * 0.5), line_col, 0.0036, 0.005)
		_:
			# open mouths: open smile (D shape), grimace (wide, flat, gritted teeth, corners down), shout (tall oval)
			var depth: float = float(mx.get("depth", 1.0))
			var top_pts: PackedVector2Array
			var bot_pts: PackedVector2Array
			var teeth_top := 0.0
			var teeth_bot := 0.0
			var tongue := false
			match kind:
				"open":
					var cu: float = hw * 0.34
					var tc: float = float(mx.get("top", 0.25))
					top_pts = bez(c + Vector2(-hw, cu), c + Vector2(0, cu * (1.0 - 2.0 * tc) - hw * 0.12), c + Vector2(hw, cu))
					bot_pts = bez(c + Vector2(hw, cu), c + Vector2(0, -hw * 1.35 * depth), c + Vector2(-hw, cu))
					teeth_top = hw * 0.30
					tongue = true
				"grimace":
					# a snarl: a wide squarish mouth, corners pulled down, both teeth rows bared
					var cd: float = hw * 0.22
					var h: float = hw * 0.62 * depth
					top_pts = bez(c + Vector2(-hw, -cd), c + Vector2(0, hw * 0.30), c + Vector2(hw, -cd))
					bot_pts = PackedVector2Array([c + Vector2(hw, -cd), c + Vector2(hw * 0.86, -cd - h * 0.75), c + Vector2(hw * 0.55, -cd - h),
						c + Vector2(0, -cd - h * 1.06), c + Vector2(-hw * 0.55, -cd - h), c + Vector2(-hw * 0.86, -cd - h * 0.75), c + Vector2(-hw, -cd)])
					teeth_top = hw * 0.26
					teeth_bot = hw * 0.22
				_:
					top_pts = bez(c + Vector2(-hw, -hw * 0.05), c + Vector2(0, hw * 0.55), c + Vector2(hw, -hw * 0.05))
					bot_pts = bez(c + Vector2(hw, -hw * 0.05), c + Vector2(0, -hw * 1.45 * depth), c + Vector2(-hw, -hw * 0.05))
					teeth_top = hw * 0.26
					tongue = true
			var poly := PackedVector2Array(top_pts)
			poly.append_array(bot_pts.slice(1, bot_pts.size() - 1))
			fill(acc, cv, poly, inner, 0.0026, 0.005)
			var bb := Rect2(poly[0], Vector2.ZERO)
			for q: Vector2 in poly:
				bb = bb.expand(q)
			var teeth: Color = p["teeth"]
			if teeth_top > 0.0:
				var band := PackedVector2Array()
				for q: Vector2 in top_pts:
					band.append(q + Vector2(0, 0.01))
				for i: int in range(top_pts.size() - 1, -1, -1):
					band.append(top_pts[i] - Vector2(0, teeth_top * (0.55 + 0.45 * sin(PI * float(i) / float(top_pts.size() - 1)))))
				fill_clipped(acc, cv, band, poly, teeth, 0.0032, 0.005)
			if teeth_bot > 0.0:
				var band2 := PackedVector2Array()
				for q: Vector2 in bot_pts:
					band2.append(q - Vector2(0, 0.01))
				for i: int in range(bot_pts.size() - 1, -1, -1):
					band2.append(bot_pts[i] + Vector2(0, teeth_bot * (0.5 + 0.5 * sin(PI * float(i) / float(bot_pts.size() - 1)))))
				fill_clipped(acc, cv, band2, poly, teeth, 0.0032, 0.005)
				# the gap line between the teeth rows
				strip(acc, cv, bez(Vector2(bb.position.x, bb.get_center().y + 0.002), Vector2(bb.get_center().x, bb.get_center().y - 0.001), Vector2(bb.end.x, bb.get_center().y + 0.002)),
					Vector3(0.0008, 0.0012, 0.0008), (p["mouth_in"] as Color).darkened(0.3), 0.0035, 0.005)
			if tongue:
				var tcn := Vector2(bb.get_center().x, bb.position.y + bb.size.y * 0.22)
				var tr := Vector2(bb.size.x * 0.30, bb.size.y * 0.30)
				fill_clipped(acc, cv, ellipse(tcn, tr, 0.0, 14), poly, radial(tcn, tr, p["tongue"], (p["tongue"] as Color).darkened(0.25), 0.3), 0.0033, 0.005)
			# lip outline + a lower-lip swell
			var outline := PackedVector2Array(top_pts)
			outline.append_array(bot_pts.slice(1, bot_pts.size()))
			strip(acc, cv, outline, Vector3(lip * 0.45, lip * 0.6, lip * 0.45), line_col, 0.0036, 0.005)
			var lsw := PackedVector2Array()
			for i: int in range(3, bot_pts.size() - 3):
				lsw.append(bot_pts[i] - Vector2(0, lip * 1.6))
			strip(acc, cv, lsw, Vector3(lip * 0.3, lip * 1.15, lip * 0.3), lip_col, 0.0029, 0.005)
	if x.get("lines", false):
		for sx: float in [-1.0, 1.0]:
			var k := c + Vector2(sx * (hw + 0.010), hw * 0.30)
			strip(acc, cv, bez(k + Vector2(-sx * 0.004, 0.022), k + Vector2(sx * 0.006, 0.008), k + Vector2(-sx * 0.001, -0.010)),
				Vector3(0.0004, 0.0011, 0.0004), (p["skin"] as Color).darkened(0.25), 0.0030, 0.005)


# ================================================================ 3D pieces: hair locks, braids, caps, ears (vertex colour)

## One swept lock (hair plan 2 / 4): a flattened pentagon section along a cubic Bezier (pts = 4 model-space points, root
## first), swelling after the root and tapering to a point, optional twist (deg root -> tip), flat-shaded. The colour
## runs from `root` to `tip` (a painted gradient: ember / frost / blossom tips) starting at `tip_from` (0-1).
## `face` = where the flat side looks. ~ (rings - 1) * 30 + 24 vertices.
static func lock(acc: Dictionary, pts: Array, face: Vector3, width: float, thick: float, root: Color, tip: Color,
		rings: int = 5, tip_from: float = 0.6, twist: float = 0.0) -> void:
	const SIDES := 5
	var sec: Array = []
	var cols: Array[Color] = []
	for i: int in rings:
		var u := float(i) / float(rings)
		var p := _bez3(pts, u)
		var t := (_bez3(pts, minf(u + 0.02, 1.0)) - _bez3(pts, maxf(u - 0.02, 0.0))).normalized()
		var b := t.cross(face).normalized()
		if b.length() < 0.5:
			b = t.cross(Vector3.UP).normalized()
		var n := b.cross(t).normalized()
		var tw := deg_to_rad(twist * u)
		var bb := b * cos(tw) + n * sin(tw)
		var nn := n * cos(tw) - b * sin(tw)
		var s := lerpf(0.8, 1.0, u / 0.3) if u < 0.3 else lerpf(1.0, 0.3, pow((u - 0.3) / 0.7, 1.2))
		var ring := PackedVector3Array()
		for k: int in SIDES:
			var a := TAU * float(k) / float(SIDES) + PI * 0.5
			ring.append(p + bb * (cos(a) * width * 0.5 * s) + nn * (sin(a) * thick * 0.5 * s))
		sec.append(ring)
		cols.append(root.lerp(tip, smoothstep(tip_from, 1.0, u)))
	var tp := _bez3(pts, 1.0)
	for i: int in rings:
		var r0: PackedVector3Array = sec[i]
		if i < rings - 1:
			var r1: PackedVector3Array = sec[i + 1]
			for k: int in SIDES:
				var k1 := (k + 1) % SIDES
				quad_flat(acc, r0[k], r1[k], r1[k1], r0[k1], cols[i], cols[i + 1], cols[i + 1], cols[i])
		else:
			for k: int in SIDES:
				tri_flat(acc, r0[k], tp, r0[(k + 1) % SIDES], cols[i], tip, cols[i])
	var r: PackedVector3Array = sec[0]
	for k: int in range(1, SIDES - 1):
		tri_flat(acc, r[0], r[k + 1], r[k], root, root, root)


## A braid: alternating flattened lobes along a Catmull-Rom path (model space). Returns the end point.
static func braid(acc: Dictionary, path: Array, lobes: int, w0: float, w1: float, col: Color, tip: Color) -> Vector3:
	var lobe := CharacterModel.sphere(1.0, 6, 3)
	var total := _path_len(path)
	for i: int in lobes:
		var u := (float(i) + 0.5) / float(lobes)
		var p := _catmull(path, u)
		var t := (_catmull(path, minf(u + 0.01, 1.0)) - _catmull(path, maxf(u - 0.01, 0.0))).normalized()
		var side := t.cross(Vector3.FORWARD if absf(t.z) < 0.9 else Vector3.RIGHT).normalized()
		var w := lerpf(w0, w1, u)
		var len := total / float(lobes) * 0.78
		var lean := 0.28 if i % 2 == 0 else -0.28
		var ax := (t + side * lean).normalized()
		var bz := Basis(Quaternion(Vector3.UP, ax))
		put_mesh(acc, lobe, Transform3D(bz.scaled_local(Vector3(w * 0.55, len, w * 0.42)), p + side * w * 0.12 * signf(lean)),
			col.lerp(tip, u * 0.6))
	return _catmull(path, 1.0)


## A flat-shaded quad (a, b, c, d in order; 4 shared vertices, one averaged normal; triangles a-b-c, a-c-d wound like
## tri_flat).
static func quad_flat(acc: Dictionary, a: Vector3, b: Vector3, c: Vector3, d: Vector3, ca: Color, cb: Color, cc: Color, cd: Color) -> void:
	var n := ((c - a).cross(b - a) + (d - a).cross(c - a)).normalized()
	var b0: int = (acc["v"] as PackedVector3Array).size()
	acc["v"].append_array(PackedVector3Array([a, b, c, d]))
	acc["n"].append_array(PackedVector3Array([n, n, n, n]))
	acc["col"].append_array(PackedColorArray([ca, cb, cc, cd]))
	acc["i"].append_array(PackedInt32Array([b0, b0 + 1, b0 + 2, b0, b0 + 2, b0 + 3]))


## A flat-shaded triangle with per-corner colours (Godot front = clockwise seen from outside).
static func tri_flat(acc: Dictionary, a: Vector3, b: Vector3, c: Vector3, ca: Color, cb: Color, cc: Color) -> void:
	var n := (c - a).cross(b - a).normalized()
	var b0: int = (acc["v"] as PackedVector3Array).size()
	acc["v"].append_array(PackedVector3Array([a, b, c]))
	acc["n"].append_array(PackedVector3Array([n, n, n]))
	acc["col"].append_array(PackedColorArray([ca, cb, cc]))
	acc["i"].append_array(PackedInt32Array([b0, b0 + 1, b0 + 2]))


## An ear on side sx (+1 = model +X) of a head centred at c with radius r: `kind` round / pointed / none. The ear
## faces forward-out; an inner fold in a darker skin shade. `at` (for +x) overrides the default place.
static func ear(acc: Dictionary, c: Vector3, r: float, sx: float, skin: Color, kind: StringName, at: Vector3 = Vector3.INF) -> void:
	if kind == &"none" or kind == &"":
		return
	var pos := c + Vector3(0.93 * r * sx, -0.08 * r, -0.10 * r) if at == Vector3.INF else Vector3(at.x * sx, at.y, at.z)
	var yaw := Basis(Vector3.UP, deg_to_rad(28.0 * sx))
	var sph := CharacterModel.sphere(1.0, 8, 4)
	put_mesh(acc, sph, Transform3D(yaw.scaled_local(Vector3(0.09 * r, 0.26 * r, 0.17 * r)), pos), skin)
	put_mesh(acc, sph, Transform3D(yaw.scaled_local(Vector3(0.05 * r, 0.17 * r, 0.10 * r)), pos + yaw * Vector3(0.05 * r * sx, 0.0, 0.03 * r)),
		skin.darkened(0.22))
	if kind == &"pointed":
		var tipb := yaw * Basis(Vector3.BACK, deg_to_rad(-24.0 * sx)) * Basis(Vector3.RIGHT, deg_to_rad(-18.0))
		put_mesh(acc, CharacterModel.cyl(0.0, 0.085 * r, 0.34 * r, 5), Transform3D(tipb, pos + tipb * Vector3(0, 0.26 * r, 0)), skin)


## Tints the vertices from index `from` on whose normals face down toward `col` (a darker underside so white hair /
## beards separate from white fur and read as volume from the high camera).
static func shade_under(acc: Dictionary, from: int, col: Color, amount: float = 0.8) -> void:
	var n: PackedVector3Array = acc["n"]
	var cc: PackedColorArray = acc["col"]
	for i: int in range(from, n.size()):
		var t := clampf(-n[i].y * 1.3 + 0.15, 0.0, 1.0) * amount
		if t > 0.0:
			var a := cc[i].a
			cc[i] = cc[i].lerp(col, t)
			cc[i].a = a
	acc["col"] = cc


## A hair cap: a dome over the skull behind the hairline (hairline 0-1: higher = more forehead shows).
static func cap(acc: Dictionary, c: Vector3, r: float, col: Color, hairline: float = 0.5, back: float = 1.0) -> void:
	var up := lerpf(0.18, 0.36, hairline)
	put_mesh(acc, CharacterModel.sphere(1.0, 12, 6), Transform3D(Basis.from_scale(Vector3(1.06 * r, 0.9 * r, 1.02 * r * back)),
		c + Vector3(0, up * r, -0.16 * r)), col)


# ================================================================ hair presets

## Hair styles for the one-call attach (relative to the head centre c and radius r; +z = forward). A style that does not
## fit a model is a starting point: pass your own `hair_fn` Callable(acc) with lock / braid / cap calls instead.
## crop (short swept locks), fringe (crop + a fringe), bob (jaw-length side locks), long (front locks over the
## shoulders + back curtain), bun, ponytail, braid (one braid over the left shoulder), none.
## Beards: moustache, full, spade, none.
const HAIR_STYLES: Array[StringName] = [&"none", &"crop", &"fringe", &"bob", &"long", &"bun", &"ponytail", &"braid"]
const BEARD_STYLES: Array[StringName] = [&"none", &"moustache", &"full", &"spade"]


static func hair_preset(acc: Dictionary, style: StringName, c: Vector3, r: float, col: Color, tip: Color, hairline: float = 0.5,
		crown_locks: int = 5) -> void:
	if style == &"none" or style == &"":
		return
	var o := func(x: float, y: float, z: float) -> Vector3: return c + Vector3(x, y, z) * r
	cap(acc, c, r, col, hairline)
	# crown locks swept back over the cap (texture on top: what the RTS camera sees first)
	for k: int in crown_locks:
		var sx := sin((float(k) - float(crown_locks - 1) * 0.5) * 0.36 * 4.0 / maxf(float(crown_locks - 1), 1.0))
		lock(acc, [o.call(sx * 0.35, 0.95, 0.35), o.call(sx * 0.62, 1.02, 0.02), o.call(sx * 0.80, 0.78, -0.42), o.call(sx * 0.86, 0.40, -0.72)],
			Vector3(sx, 1.0, -0.2).normalized(), 0.62 * r, 0.20 * r, col, col.lerp(tip, 0.6), 4, 0.7, 0.0)
	match style:
		&"fringe", &"bob", &"long":
			lock(acc, [o.call(0.40, 0.86, 0.45), o.call(0.10, 0.82, 0.86), o.call(-0.30, 0.66, 0.90), o.call(-0.62, 0.42, 0.72)],
				Vector3(0, 0.3, 1).normalized(), 0.46 * r, 0.16 * r, col, tip, 4, 0.75)
	for sx: float in [-1.0, 1.0]:
		match style:
			&"crop", &"fringe":
				lock(acc, [o.call(0.70 * sx, 0.62, 0.30), o.call(0.98 * sx, 0.40, 0.15), o.call(1.02 * sx, 0.10, 0.0), o.call(0.94 * sx, -0.12, -0.10)],
					Vector3(sx, 0.1, 0.3).normalized(), 0.38 * r, 0.16 * r, col, tip, 4, 0.8)
			&"bob":
				lock(acc, [o.call(0.60 * sx, 0.80, 0.30), o.call(1.05 * sx, 0.45, 0.25), o.call(1.08 * sx, -0.20, 0.18), o.call(0.92 * sx, -0.62, 0.22)],
					Vector3(sx, 0.0, 0.4).normalized(), 0.55 * r, 0.20 * r, col, tip, 5, 0.75, 8.0 * sx)
				lock(acc, [o.call(0.40 * sx, 0.80, -0.50), o.call(0.95 * sx, 0.30, -0.55), o.call(0.98 * sx, -0.30, -0.40), o.call(0.80 * sx, -0.66, -0.20)],
					Vector3(sx, 0.0, -0.6).normalized(), 0.62 * r, 0.22 * r, col, tip, 5, 0.8)
			&"long":
				lock(acc, [o.call(0.62 * sx, 0.78, 0.25), o.call(1.12 * sx, 0.20, 0.30), o.call(0.95 * sx, -0.90, 0.72), o.call(1.00 * sx, -1.90, 0.95)],
					Vector3(0.4 * sx, 0.1, 0.9).normalized(), 0.60 * r, 0.22 * r, col, tip, 6, 0.6, -18.0 * sx)
				lock(acc, [o.call(0.50 * sx, 0.70, -0.55), o.call(1.00 * sx, 0.10, -0.75), o.call(0.90 * sx, -1.10, -0.85), o.call(0.70 * sx, -2.10, -0.80)],
					Vector3(0.5 * sx, 0.0, -1.0).normalized(), 0.75 * r, 0.24 * r, col, tip, 6, 0.65)
			&"bun", &"ponytail", &"braid":
				lock(acc, [o.call(0.62 * sx, 0.72, 0.28), o.call(0.98 * sx, 0.35, 0.28), o.call(0.98 * sx, 0.0, 0.20), o.call(0.88 * sx, -0.30, 0.20)],
					Vector3(sx, 0.0, 0.5).normalized(), 0.34 * r, 0.14 * r, col, tip, 4, 0.8, 10.0 * sx)
	match style:
		&"long":
			lock(acc, [o.call(0.0, 0.80, -0.70), o.call(0.0, 0.10, -1.08), o.call(0.0, -1.00, -1.00), o.call(0.0, -2.20, -0.90)],
				Vector3(0, 0, -1), 0.95 * r, 0.26 * r, col, tip, 6, 0.65)
		&"bun":
			put_mesh(acc, CharacterModel.sphere(1.0, 10, 5), Transform3D(Basis.from_scale(Vector3(0.46, 0.42, 0.42) * r), o.call(0.0, 0.62, -0.92)), col)
			put_mesh(acc, CharacterModel.torus(0.32, 0.46, 10), Transform3D(Basis(Vector3.RIGHT, deg_to_rad(70.0)).scaled_local(Vector3(r, r, r)), o.call(0.0, 0.58, -0.78)), tip)
		&"ponytail":
			lock(acc, [o.call(0.0, 0.70, -0.85), o.call(0.0, 0.40, -1.35), o.call(0.0, -0.50, -1.30), o.call(0.0, -1.40, -1.10)],
				Vector3(0, 0, -1), 0.60 * r, 0.30 * r, col, tip, 6, 0.7, 20.0)
		&"braid":
			var end := braid(acc, [o.call(-0.62, -0.20, -0.55), o.call(-0.95, -0.80, -0.10), o.call(-0.88, -1.40, 0.70), o.call(-0.80, -2.30, 1.00)],
				10, 0.34 * r, 0.24 * r, col, tip)
			lock(acc, [end, end + Vector3(0, -0.12, 0.02) * r, end + Vector3(0, -0.30, 0.04) * r, end + Vector3(0, -0.45, 0.06) * r],
				Vector3(0, 0, 1), 0.30 * r, 0.14 * r, col, tip, 4, 0.3)


static func beard_preset(acc: Dictionary, style: StringName, c: Vector3, r: float, col: Color, tip: Color) -> void:
	if style == &"none" or style == &"":
		return
	var o := func(x: float, y: float, z: float) -> Vector3: return c + Vector3(x, y, z) * r
	for sx: float in [-1.0, 1.0]:
		# moustache: two locks from under the nose curling out and down
		lock(acc, [o.call(0.04 * sx, -0.20, 1.0), o.call(0.30 * sx, -0.22, 1.02), o.call(0.50 * sx, -0.34, 0.90), o.call(0.58 * sx, -0.54, 0.78)],
			Vector3(0, 0.2, 1), 0.26 * r, 0.12 * r, col, tip, 4, 0.7)
	match style:
		&"full", &"spade":
			for sx: float in [-1.0, 1.0]:
				lock(acc, [o.call(0.82 * sx, 0.05, 0.40), o.call(0.90 * sx, -0.50, 0.55), o.call(0.55 * sx, -0.90, 0.80), o.call(0.28 * sx, -1.15, 0.86)],
					Vector3(sx, -0.2, 0.8).normalized(), 0.50 * r, 0.22 * r, col, tip, 5, 0.7)
			var ln := 1.2 if style == &"full" else 2.0
			for k: int in 3:
				var dx := (float(k) - 1.0) * 0.26
				lock(acc, [o.call(dx, -0.62, 0.86), o.call(dx * 1.3, -0.95, 1.00), o.call(dx * 0.9, -0.95 - ln * 0.5, 1.02), o.call(dx * 0.3, -0.95 - ln, 0.96)],
					Vector3(0, 0, 1), (0.52 if k == 1 else 0.42) * r, 0.22 * r, col, tip, 5, 0.6, (float(k) - 1.0) * 14.0)


# ================================================================ face presets (proportions relative to the face radius)

## Face presets: bright (young, big lashed eyes, blush), gentle (soft, calm), stern (older man: heavier lids, thick
## brows, no lash flick, little blush), elder (lines of age), hollow (for faces in a void / hood: no blush), plain
## (soldiers / workers: simple, readable).
const PRESETS := {
	&"bright": {"eye": [1.08, 1.12], "lash": 1.3, "flick": 1.0, "brow_w": 1.0, "blush": 1.0, "lines": false},
	&"gentle": {"eye": [1.0, 1.0], "lash": 1.1, "flick": 0.7, "brow_w": 0.9, "blush": 0.8, "lines": false},
	&"stern": {"eye": [0.92, 0.82], "lash": 0.8, "flick": 0.0, "brow_w": 1.6, "blush": 0.35, "lines": false},
	&"elder": {"eye": [0.95, 0.9], "lash": 0.9, "flick": 0.4, "brow_w": 1.1, "blush": 0.4, "lines": true},
	&"hollow": {"eye": [1.0, 0.85], "lash": 1.0, "flick": 0.6, "brow_w": 1.0, "blush": 0.0, "lines": false},
	&"plain": {"eye": [1.0, 1.0], "lash": 0.9, "flick": 0.3, "brow_w": 1.1, "blush": 0.6, "lines": false},
}


## A full style from a short spec (see the API at the top). Positions scale with the face radius (tuned on r = 0.25).
static func style_from(spec: Dictionary) -> Dictionary:
	var r: float = spec["radius"]
	var c: Vector3 = spec["center"]
	var pr: Dictionary = PRESETS.get(spec.get("preset", &"plain"), PRESETS[&"plain"])
	var k := r / 0.25
	var skin: Color = spec.get("skin", Color(0.9, 0.72, 0.58))
	var hair: Color = spec.get("hair", Color(0.30, 0.18, 0.10))
	var iris: Color = spec.get("eyes", Color(0.30, 0.45, 0.25))
	var es: Array = pr["eye"]
	var pal := {"skin": skin, "sclera": Color(0.97, 0.94, 0.89), "iris_in": iris.lightened(0.35), "iris_out": iris.darkened(0.45),
		"iris_glow": 0.0, "pupil": Color(0.08, 0.06, 0.06), "highlight": Color(1, 1, 1),
		"lash": hair.darkened(0.6).lerp(Color(0.08, 0.05, 0.05), 0.5), "brow": hair.darkened(0.15),
		"blush": skin.lerp(Color(0.92, 0.35, 0.32), 0.7), "lip_line": skin.darkened(0.55).lerp(Color(0.45, 0.12, 0.10), 0.4),
		"lip": skin.lerp(Color(0.85, 0.40, 0.38), 0.55), "mouth_in": Color(0.32, 0.07, 0.07), "teeth": Color(0.98, 0.96, 0.9),
		"tongue": Color(0.90, 0.44, 0.42)}
	var pov: Dictionary = spec.get("palette", {})
	for pk: String in pov:
		pal[pk] = pov[pk]
	var hm: Mesh = spec.get("head_mesh", CharacterModel.sphere(r, 12, 6))
	var st := {
		"canvas": canvas(c, r, hm, spec.get("head_scale", Vector3.ONE), spec.get("head_at", Vector3.INF)),
		"palette": pal,
		"eye": {"c": Vector2(0.082, 0.020) * k, "hw": 0.040 * k * float(es[0]), "top": 0.030 * k * float(es[1]),
			"bot": 0.017 * k * float(es[1]), "tilt": 0.006 * k, "ir": 0.020 * k * float(es[1]), "lash": float(pr["lash"]) * k,
			"flick": 0.013 * k * float(pr["flick"])},
		"brow": {"inner": Vector2(0.040, 0.072) * k, "mid": Vector2(0.084, 0.088) * k, "outer": Vector2(0.126, 0.074) * k,
			"w": Vector3(0.0068, 0.0064, 0.0026) * k * float(pr["brow_w"])},
		"cheek": {"c": Vector2(0.116, -0.036) * k, "r": Vector2(0.034, 0.019) * k},
		"mouth": {"c": Vector2(0.0, -0.090) * k, "hw": 0.048 * k, "lip": 0.0034 * k},
		"x": {},
	}
	var low: bool = spec.get("detail", &"normal") == &"low"
	if low:
		st["density"] = 3.0
	if spec.get("beard", &"none") != &"none":
		st["mouth"]["c"] = Vector2(0.0, -0.112) * k   # under the moustache
	for fk: String in ["eye", "brow", "cheek", "mouth"]:
		var fo: Dictionary = spec.get(fk, {})
		for kk: String in fo:
			st[fk][kk] = fo[kk]
	if float(pr["blush"]) != 1.0:
		for id: StringName in EXPRESSIONS:
			st["x"][id] = {"blush": float(X_DEFAULT[id]["blush"]) * float(pr["blush"])}
	var xo: Dictionary = spec.get("x", {})
	for id: StringName in xo:
		if not st["x"].has(id):
			st["x"][id] = {}
		for xk: String in xo[id]:
			st["x"][id][xk] = xo[id][xk]
	for ck: String in ["mouth_canvas", "base", "extra", "surfaces"]:
		if spec.has(ck):
			st[ck] = spec[ck]
	# geometry (ears, hair, beard) built once and appended to every expression's mesh
	var hair_tip: Color = spec.get("hair_tip", hair.lightened(0.25))
	var ears: StringName = spec.get("ears", &"none")
	var bs: StringName = spec.get("beard", &"none")
	var hc: Vector3 = spec.get("head_center", c)
	var hr: float = spec.get("head_radius", r)
	st["geo"] = func(acc: Dictionary) -> void:
		for sx: float in [-1.0, 1.0]:
			ear(acc, hc, hr, sx, skin, ears, spec.get("ear_at", Vector3.INF))
		if spec.get("hair_fn") is Callable:
			(spec["hair_fn"] as Callable).call(acc)
		else:
			hair_preset(acc, spec.get("hair_style", &"none"), hc, hr, hair, hair_tip, spec.get("hairline", 0.5), 3 if low else 5)
		beard_preset(acc, bs, hc, hr, spec.get("beard_color", hair), spec.get("beard_tip", hair_tip))
	if pr["lines"] and not spec.has("extra"):
		st["extra"] = func(acc: Dictionary, _id: StringName) -> void: age_lines(acc, st["canvas"], st, 1.0)
	return st


## Lines of age: crow's feet, under-eye folds, nose-to-mouth lines (placed from the style's eye / mouth).
static func age_lines(acc: Dictionary, cv: Dictionary, st: Dictionary, amount: float) -> void:
	var e: Dictionary = st["eye"]
	var m: Dictionary = st["mouth"]
	var col: Color = (st["palette"]["skin"] as Color).darkened(0.32)
	var ec: Vector2 = e["c"]
	var hw: float = e["hw"]
	var w := Vector3(0.0004, 0.0012, 0.0004) * amount
	var mc: Vector2 = m["c"]
	var mhw: float = m["hw"]
	for sx: float in [-1.0, 1.0]:
		var oc := Vector2((ec.x + hw + 0.006) * sx, ec.y)
		strip(acc, cv, PackedVector2Array([oc + Vector2(0, 0.003), oc + Vector2(0.012 * sx, 0.008)]), w, col, 0.003)
		strip(acc, cv, PackedVector2Array([oc + Vector2(0, -0.004), oc + Vector2(0.012 * sx, -0.009)]), w, col, 0.003)
		strip(acc, cv, mirror(bez(ec + Vector2(-hw * 0.6, -0.026), ec + Vector2(0, -0.032), ec + Vector2(hw * 0.6, -0.026)), sx), w, col, 0.003)
		strip(acc, cv, mirror(bez(Vector2(mhw * 0.55, mc.y + 0.05), Vector2(mhw * 1.15, mc.y + 0.02), Vector2(mhw * 1.2, mc.y - 0.01)), sx), w, col, 0.003)


# ================================================================ whole face

## Expression parameters: the defaults with the style's overrides (style["x"][id] = {key: value}).
static func params(style: Dictionary, id: StringName) -> Dictionary:
	if id == FAR:
		var xf := params(style, &"neutral")
		xf["bold"] = float(style.get("bold", 1.9))
		xf["blush"] = float(xf["blush"]) * 1.25
		return xf
	id = canonical(id)
	var x: Dictionary = (X_DEFAULT[id] as Dictionary).duplicate(true)
	var ov: Dictionary = style.get("x", {}).get(id, {})
	for k: String in ov:
		if k == "mouth" and ov[k] is Dictionary:
			var mm: Dictionary = x["mouth"]
			for mk: String in ov[k]:
				mm[mk] = ov[k][mk]
		else:
			x[k] = ov[k]
	return x


## The painted face for one expression, cached by key + id. style keys: canvas (FaceKit.canvas), mouth_canvas
## (optional, e.g. a beard), palette {skin, sclera, iris_in, iris_out, iris_glow, pupil, pupil_glow, highlight, lash,
## brow, blush, lip_line, lip, mouth_in, mouth_glow, teeth, tongue}, eye, brow, cheek, mouth (see the feature
## builders), x (per expression overrides), base / extra (optional Callable(acc, id) painting under / over the
## features), geo (optional Callable(acc): ears, hair, beard: 3D pieces built ONCE and appended to every expression),
## surfaces (optional Callable(am: ArrayMesh, id) appending own surfaces, e.g. a glowing hat gem).
static func face_mesh(key: String, style: Dictionary, id: StringName) -> ArrayMesh:
	var far := id == FAR
	id = FAR if far else canonical(id)
	var ck := key + "|" + String(id)
	if not _seen_styles.has(key):
		_seen_styles[key] = style
		_hook_exit()
	if _cache.has(ck):
		return _cache[ck]
	var x := params(style, id)
	_dens = float(style.get("density", DENSITY))
	var p: Dictionary = style["palette"]
	var cv: Dictionary = style["canvas"]
	var mcv: Dictionary = style.get("mouth_canvas", cv)
	var acc := begin()
	if style.has("base"):
		(style["base"] as Callable).call(acc, id)
	for sx: float in [1.0, -1.0]:
		blush(acc, cv, style["cheek"], float(x["blush"]), p, sx)
		eye(acc, cv, style["eye"], x, p, sx)
		brow(acc, cv, style["brow"], x, p, sx)
	mouth(acc, mcv, style["mouth"], x, p)
	if style.has("extra"):
		(style["extra"] as Callable).call(acc, id)
	if style.has("geo"):
		var gk := key + "|geo"
		if not _cache.has(gk):
			var g := begin()
			(style["geo"] as Callable).call(g)
			_cache[gk] = g
		_append(acc, _cache[gk])
	var am := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = acc["v"]
	arrays[Mesh.ARRAY_NORMAL] = acc["n"]
	arrays[Mesh.ARRAY_COLOR] = acc["col"]
	arrays[Mesh.ARRAY_INDEX] = acc["i"]
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	am.surface_set_material(0, material())
	if style.has("surfaces"):
		(style["surfaces"] as Callable).call(am, id)
	_dens = DENSITY   # back to the default: outside calls to fill / strip / resample never inherit this face's density
	_cache[ck] = am
	return am


static func _append(acc: Dictionary, src: Dictionary) -> void:
	var b0: int = (acc["v"] as PackedVector3Array).size()
	acc["v"].append_array(src["v"])
	acc["n"].append_array(src["n"])
	acc["col"].append_array(src["col"])
	var ix: PackedInt32Array = src["i"]
	for j: int in ix.size():
		acc["i"].append(b0 + ix[j])


## Builds every expression of a style now (the first attach per key does it, so a cast in battle never builds).
static func warm(key: String, style: Dictionary) -> void:
	var cvs: Array[Dictionary] = []
	for ck: String in ["canvas", "mouth_canvas"]:
		if style.get(ck) is Dictionary and not (style[ck] as Dictionary).has("_memo"):
			(style[ck] as Dictionary)["_memo"] = {}
			cvs.append(style[ck])
	for id: StringName in EXPRESSIONS:
		face_mesh(key, style, id)
	face_mesh(key, style, FAR)
	for cv: Dictionary in cvs:
		cv.erase("_memo")


# ================================================================ one-call attach

static var _styles: Dictionary = {}
static var _exit_hooked := false
static var _seen_styles: Dictionary = {}   # key -> every style dictionary face_mesh() saw (release() strips them)


## Drops every static cache (styles, meshes, material, UnitFaces' lean styles). Called once when the scene tree's root
## leaves at quit: a style holds lambdas ("extra", "hair_fn"...) and the engine crashed (0xC0000005 in ntdll) when it
## freed them with the script statics after the servers, i.e. every game / test that showed a FaceRig exited with a
## crash (2026-09-28 to 09-30: ~150 CI tests "PASS" then exit -1073741819).
static func release() -> void:
	# Other static caches keep the same style dictionaries (ChampionFaces, CreatureFaceRig, per-model styles such as
	# Vessa's): strip the lambdas out of every style face_mesh() saw, so no static anywhere still holds one at exit.
	for st: Variant in _seen_styles.values():
		_strip_callables(st)
	_seen_styles.clear()
	_styles.clear()
	_cache.clear()
	_mat = null
	UnitFaces._lean_cache.clear()


static func _strip_callables(v: Variant) -> void:
	if v is Dictionary:
		var d: Dictionary = v
		for k: Variant in d.keys():
			if d[k] is Callable:
				d.erase(k)
			else:
				_strip_callables(d[k])
	elif v is Array:
		var a: Array = v
		for i: int in range(a.size() - 1, -1, -1):
			if a[i] is Callable:
				a.remove_at(i)
			else:
				_strip_callables(a[i])


static func _hook_exit() -> void:
	if _exit_hooked:
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return
	tree.root.tree_exiting.connect(release, CONNECT_ONE_SHOT)
	_exit_hooked = true


## Adds a FaceRig (the face + ears + hair + beard: ONE node, one vertex-coloured surface = 1 draw call, plus any
## `surfaces` the spec appends) under `head` and returns it. Call it in _build_parts. `spec` is a style_from() spec OR a
## ready style dictionary (has "canvas"). The style is built once per key (the first instance of the unit type) and
## every expression with it: a one-time cost per type, never during a fight.
static func attach(model: Node3D, head: Node3D, key: String, spec: Dictionary) -> FaceRig:
	_hook_exit()
	if not _styles.has(key):
		_styles[key] = spec if spec.has("canvas") else style_from(spec)
		warm(key, _styles[key])
	var rig := FaceRig.new()
	rig.name = "Face"
	rig.setup(key, _styles[key])
	var o := Vector3.ZERO   # the head's model-space rest position (CharacterModel.model_origin)
	var n: Node = head
	while n and n != model:
		o += (n as Node3D).position
		n = n.get_parent()
	rig.position = -o
	rig.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rig.set_meta(&"keep_separate", true)
	head.add_child(rig)
	return rig


static func _bez3(p: Array, u: float) -> Vector3:
	var v := 1.0 - u
	return p[0] * v * v * v + p[1] * 3.0 * v * v * u + p[2] * 3.0 * v * u * u + p[3] * u * u * u


static func _catmull(path: Array, u: float) -> Vector3:
	var n := path.size() - 1
	var f := clampf(u, 0.0, 1.0) * float(n)
	var i := mini(int(f), n - 1)
	var t := f - float(i)
	var p0: Vector3 = path[maxi(i - 1, 0)]
	var p1: Vector3 = path[i]
	var p2: Vector3 = path[i + 1]
	var p3: Vector3 = path[mini(i + 2, n)]
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t * t * t)


static func _path_len(path: Array) -> float:
	var l := 0.0
	for i: int in range(1, path.size()):
		l += (path[i] as Vector3).distance_to(path[i - 1])
	return l
