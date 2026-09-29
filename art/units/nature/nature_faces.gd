class_name NatureFaces
extends RefCounted
## Faces for the Nature army (face rework 2026-09-28, on the shared FaceKit): eyes, lips, expressions, ears and leafy
## hair for every Nature unit with a face. The units call FaceKit.attach with a spec built here, so the palette, the
## lean settings and the cheap hair / ear pieces are shared. NatureModel ticks the rig (`_face_tick`) and resets it on
## revive.
##
## Vertex budget (Art Lab B4: soldiers / workers <= 2500): a stock `detail low` face is ~540 vertices, kit ears ~220 a
## pair and a kit hair preset 500-1100, which no Nature soldier can afford (they sit at 2200-2450 before the face). So:
##   lean_x()      no cheek blush (-66) and, with bold > 1, the bold RTS lines at every distance (no eye highlights / lid
##                 creases: -66). Neutral face ~410-475 vertices.
##   blade()       a leaf-shaped hair lock / ear: flat-shaded diamond, 18 vertices (a kit lock is 84-144).
##   spike()       a 4-sided flat-shaded spike, 12 vertices (thorn hair, pointed ears).
##   ear_round()   one low sphere, 28 vertices.
## Colours: nature units read badly on the meadow (docs/art/ingame_grade/under_90.md), so hair is PALE and WARM
## (straw, blossom, new growth, amber, chestnut): a light cap on top of each head, never mid-green, never team cloth.

const SKIN := Color(0.78, 0.66, 0.48)          # nature_skin
const BARK := Color(0.40, 0.28, 0.16)          # nature_bark
const HEARTWOOD := Color(0.80, 0.66, 0.44)     # nature_sec_sprigling (pale heartwood)
# hair palette (sRGB, face shader COLOR)
const STRAW := Color(0.86, 0.76, 0.46)
const STRAW_TIP := Color(0.96, 0.90, 0.64)
const BLOSSOM := Color(0.95, 0.62, 0.74)
const BLOSSOM_TIP := Color(1.0, 0.86, 0.90)
const NEW_GROWTH := Color(0.80, 0.88, 0.48)
const NEW_GROWTH_TIP := Color(0.94, 0.98, 0.70)
const AMBER := Color(0.80, 0.52, 0.20)
const AMBER_TIP := Color(0.96, 0.78, 0.40)
const CHESTNUT := Color(0.58, 0.30, 0.14)      # nature_hair
const CHESTNUT_TIP := Color(0.80, 0.52, 0.26)
const MOSS := Color(0.52, 0.64, 0.28)
const MOSS_TIP := Color(0.78, 0.86, 0.46)
# irises
const EYE_LEAF := Color(0.32, 0.58, 0.20)
const EYE_AMBER := Color(0.78, 0.52, 0.14)
const EYE_HAZEL := Color(0.50, 0.40, 0.18)
const EYE_SAP := Color(0.75, 1.0, 0.40)        # nature_glow (glowing eyes of the bark creatures)


## Per-expression overrides for mass units: no blush; bold > 1 also drops the eye highlights and lid creases (the bold
## lines of the kit's FAR face at every distance). `extra` = {expression: {key: value}} merged on top.
static func lean_x(bold: float = 1.0, extra: Dictionary = {}) -> Dictionary:
	var x := {}
	for id: StringName in FaceKit.EXPRESSIONS:
		x[id] = {"blush": 0.0}
		if bold > 1.0:
			x[id]["bold"] = bold
	for id: StringName in extra:
		if not x.has(id):
			x[id] = {}
		for k: String in extra[id]:
			x[id][k] = extra[id][k]
	return x


## Beast / mount faces ("eyes + a simple expression"): the kit always paints a mouth, so a beast's goes where its own
## muzzle hides it (`mouth_at`, face 2D) at a hair's width in the hide colour; the eyes and brows carry the
## expressions (fierce on attacks, worried when dying). `glow_eyes` > 0: sap-glowing irises (the beast's glow point).
static func beast_palette(hide: Color, iris: Color, glow_eyes: float = 0.0) -> Dictionary:
	var p := {"lip_line": hide.darkened(0.1), "lip": hide, "mouth_in": hide.darkened(0.2), "teeth": hide, "tongue": hide,
		"lash": hide.darkened(0.7), "brow": hide.darkened(0.55), "sclera": Color(0.92, 0.88, 0.74)}
	if glow_eyes > 0.0:
		p["sclera"] = FaceKit.glow(iris.lerp(Color(1, 1, 0.85), 0.5), glow_eyes * 0.6)
		p["iris_in"] = FaceKit.glow(iris.lerp(Color(1, 1, 1), 0.45), glow_eyes)
		p["iris_out"] = FaceKit.glow(iris, glow_eyes * 0.8)
		p["pupil"] = hide.darkened(0.8)
	return p


static func beast_mouth(at: Vector2) -> Dictionary:
	return {"c": at, "hw": 0.006, "lip": 0.0006}


## A full FaceKit style from a spec whose head part is ROTATED (rot_deg, as add_part's rot_deg) and / or needs its decals
## lifted off coarse facets (`lift` m): FaceKit.style_from has no rotation / lift keys, so its canvas is rebuilt here.
static func style(spec: Dictionary, rot_deg: Vector3 = Vector3.ZERO, lift: float = 0.0) -> Dictionary:
	var st := FaceKit.style_from(spec)
	st["canvas"] = canvas(spec, rot_deg, lift)
	return st


## The canvas of such a spec (for `base` / `extra` painters that must match the style's canvas).
static func canvas(spec: Dictionary, rot_deg: Vector3 = Vector3.ZERO, lift: float = 0.0) -> Dictionary:
	var r: float = spec["radius"]
	return FaceKit.canvas(spec["center"], r, spec.get("head_mesh", CharacterModel.sphere(r, 12, 6)),
		spec.get("head_scale", Vector3.ONE), spec.get("head_at", Vector3.INF), Basis.from_euler(rot_deg * (PI / 180.0)), lift)


## Palette overrides for pale hair: dark lashes (the eye outline is the read at 40 m) and brows a shade darker than
## the hair so they still show on tan skin.
static func pal(hair: Color, lash: Color = Color(0.16, 0.10, 0.05)) -> Dictionary:
	return {"lash": lash, "brow": hair.darkened(0.45).lerp(lash, 0.25)}


## A triangle whose front faces away from `inside` (flat-shaded, per-corner colours).
static func tri_out(acc: Dictionary, a: Vector3, b: Vector3, c: Vector3, inside: Vector3, ca: Color, cb: Color, cc: Color) -> void:
	var n := (c - a).cross(b - a)
	if n.dot((a + b + c) / 3.0 - inside) < 0.0:
		FaceKit.tri_flat(acc, a, c, b, ca, cc, cb)
	else:
		FaceKit.tri_flat(acc, a, b, c, ca, cb, cc)


## A leaf-shaped lock (hair, leaf ears): a flat diamond from `root` to `tip`, widest (half width w) at 40 %, a ridge
## lifted t along `up` (the side that shows); `bend` pushes the middle out along `up` (m) so a long lock follows a round
## head instead of cutting into it. 6 triangles, 18 vertices.
static func blade(acc: Dictionary, root: Vector3, tip: Vector3, w: float, t: float, up: Vector3, col: Color, tip_col: Color,
		bend: float = 0.0) -> void:
	var d := tip - root
	var side := d.cross(up).normalized()
	var u := side.cross(d).normalized()
	if u.dot(up) < 0.0:
		u = -u
	var m := root + d * 0.4 + u * bend
	var l := m + side * w
	var r := m - side * w
	var rg := m + u * t
	var mc := col.lerp(tip_col, 0.45)
	var below := m - u * 1.0
	var above := m + u * 1.0
	tri_out(acc, root, l, rg, below, col, mc, mc)
	tri_out(acc, root, rg, r, below, col, mc, mc)
	tri_out(acc, rg, l, tip, below, mc, mc, tip_col)
	tri_out(acc, rg, tip, r, below, mc, tip_col, mc)
	var under := col.darkened(0.35)
	tri_out(acc, root, l, tip, above, under, under, under)
	tri_out(acc, root, tip, r, above, under, under, under)


## A 4-sided spike (thorn lock, pointed ear): base half width w (across `up`) and half thickness t (along `up`) at
## `root`, to `tip`. 4 triangles, 12 vertices (the base sits inside the head).
static func spike(acc: Dictionary, root: Vector3, tip: Vector3, w: float, t: float, up: Vector3, col: Color, tip_col: Color) -> void:
	var d := tip - root
	var side := d.cross(up).normalized()
	var u := side.cross(d).normalized()
	var ring: Array[Vector3] = [root + side * w, root + u * t, root - side * w, root - u * t]
	for k: int in 4:
		tri_out(acc, ring[k], ring[(k + 1) % 4], tip, root, col, col, tip_col)


## A round ear: one low sphere (28 vertices) on side sx of a head centred at c (radius r), facing forward-out.
static func ear_round(acc: Dictionary, c: Vector3, r: float, sx: float, skin: Color, at: Vector3 = Vector3.INF) -> void:
	var pos := c + Vector3(0.93 * r * sx, -0.08 * r, -0.08 * r) if at == Vector3.INF else Vector3(at.x * sx, at.y, at.z)
	var yaw := Basis(Vector3.UP, deg_to_rad(28.0 * sx))
	FaceKit.put_mesh(acc, CharacterModel.sphere(1.0, 6, 3), Transform3D(yaw.scaled_local(Vector3(0.10 * r, 0.26 * r, 0.18 * r)), pos),
		skin.darkened(0.06))


## A leafy fringe: n blades from the front of the crown falling forward onto the forehead (head centre c, radius r;
## `spread` = x extent in head radii; `length` scales the blades). 18 vertices a blade.
static func fringe(acc: Dictionary, c: Vector3, r: float, n: int, col: Color, tip: Color, spread: float = 0.5,
		length: float = 1.0, width: float = 0.17) -> void:
	for k: int in n:
		var u := 0.0 if n == 1 else (float(k) / float(n - 1)) * 2.0 - 1.0
		var x := u * spread
		var root := c + Vector3(x * 0.8, 0.80, 0.32) * r
		var tipp := c + Vector3(x * 1.25, 0.80 - 0.36 * length, 0.32 + 0.62 * length) * r
		var up := (root.lerp(tipp, 0.5) - c).normalized()
		blade(acc, root, tipp, width * r, 0.06 * r, up, col, tip, 0.06 * r * length)


## Leafy crown hair: n blades swept back over the top of the head (a pale cap seen from the RTS camera): roots near
## the crown (fanned over `spread_deg`), tips down the back of the head at `length` x r, each blade bent out over the
## skull.
static func crown(acc: Dictionary, c: Vector3, r: float, n: int, col: Color, tip: Color, length: float = 1.0,
		width: float = 0.24, spread_deg: float = 150.0) -> void:
	for k: int in n:
		var u := 0.0 if n == 1 else (float(k) / float(n - 1)) * 2.0 - 1.0
		var a := deg_to_rad(u * spread_deg * 0.5)
		var root := c + Vector3(sin(a) * 0.22, 0.95, 0.30 * cos(a)).normalized() * (0.97 * r)
		var tdir := Vector3(sin(a) * 0.75, 0.55 - 0.45 * length, -0.75 * length).normalized()
		var tipp := c + tdir * (1.06 * r)
		var up := (root.lerp(tipp, 0.5) - c).normalized()
		blade(acc, root, tipp, width * r, 0.07 * r, up, col, tip, 0.22 * root.distance_to(tipp))


## A pointed (elfin / leaf) ear on side sx: a leaf blade from inside the head out, back and up. 18 vertices.
static func ear_leaf(acc: Dictionary, c: Vector3, r: float, sx: float, skin: Color, length: float = 0.55, lift: float = 0.35,
		back: float = 0.30) -> void:
	var root := c + Vector3(0.80 * r * sx, -0.06 * r, -0.08 * r)
	var tip := c + Vector3((0.95 + length) * r * sx, (-0.06 + lift) * r, (-0.08 - back) * r)
	blade(acc, root, tip, 0.13 * r, 0.05 * r, Vector3(0, 0.2, 1.0).normalized(), skin, skin.lightened(0.08))
