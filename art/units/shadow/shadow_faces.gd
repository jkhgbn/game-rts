class_name ShadowFaces
extends RefCounted
## Faces for the Shadow army (face rework 2026-09-28, on the shared FaceKit): gaunt pale faces with GLOWING violet eyes
## (the irises glow through the face shader's vertex alpha; the eye whites are a dark bruised lilac), thin lips, and
## lank silver / ash / black-violet hair where a hood or helm lets it show. Beasts (Grave Hound) get the eyes and an
## expression only. The cheap geometry (spike / blade locks, ears, lean expressions, rotated canvases) is shared with
## the Nature faces: NatureFaces' static helpers.
##
## Many Shadow heads are dark (a hood void, a dark leather mask, a helm): `base_oval` paints a pale face oval (with a
## dark rim for helm openings) on that surface first, the features go on top. Vertex budget: see NatureFaces (soldier
## B4 <= 2500).

const SKIN := Color(0.62, 0.60, 0.70)          # shadow_skin
const PALE := Color(0.76, 0.74, 0.84)          # gaunt face paint on dark heads
const VOID := Color(0.08, 0.06, 0.11)          # face-opening rim
const GLOW := Color(0.72, 0.34, 1.0)           # violet eye glow (shadow_glow)
const BLOOD := Color(0.95, 0.30, 0.55)         # the reaver's red-violet
const SILVER := Color(0.82, 0.80, 0.90)
const SILVER_TIP := Color(0.95, 0.94, 1.0)
const ASH := Color(0.52, 0.50, 0.58)
const ASH_TIP := Color(0.70, 0.68, 0.76)
const INK := Color(0.12, 0.08, 0.18)           # black-violet hair
const INK_TIP := Color(0.30, 0.20, 0.42)
const BONE := Color(0.80, 0.78, 0.70)


## Glowing-eyes palette: glowing violet eyes (whites and irises, amount 0-1), a black pupil, dark lashes and
## thin pale-grey lips (a gaunt mouth, no red).
static func pal(skin: Color, glow_col: Color = GLOW, amount: float = 1.0, brow: Color = Color(0.14, 0.10, 0.18)) -> Dictionary:
	# the whole eye glows (the old glowing eye bars were each unit's glow point at 40 m): a violet eye, a white-hot iris
	return {"sclera": FaceKit.glow(glow_col.darkened(0.25), amount * 0.9), "iris_in": FaceKit.glow(glow_col.lerp(Color(1, 1, 1), 0.55), amount),
		"iris_out": FaceKit.glow(glow_col, amount * 0.85), "pupil": FaceKit.glow(Color(0.10, 0.02, 0.16), amount * 0.2),
		"highlight": FaceKit.glow(Color(1, 0.92, 1), 0.6), "lash": Color(0.07, 0.05, 0.10), "brow": brow,
		"lip_line": skin.darkened(0.55).lerp(Color(0.25, 0.10, 0.30), 0.3), "lip": skin.darkened(0.18).lerp(Color(0.55, 0.40, 0.60), 0.25),
		"mouth_in": Color(0.10, 0.03, 0.12), "teeth": Color(0.86, 0.84, 0.80), "tongue": Color(0.45, 0.20, 0.35),
		"blush": skin}


## A pale face oval painted on a dark head (canvas cv): `rim` > 0 adds a dark opening rim that much wider (helms).
static func base_oval(acc: Dictionary, cv: Dictionary, c: Vector2, r: Vector2, skin: Color, rim: float = 0.0) -> void:
	if rim > 0.0:
		FaceKit.fill(acc, cv, FaceKit.ellipse(c, r + Vector2(rim, rim), 0.0, 16), VOID, 0.0008, 0.014)
	FaceKit.fill(acc, cv, FaceKit.ellipse(c, r, 0.0, 16), FaceKit.radial(c, r, skin, skin.darkened(0.30), 0.55), 0.0012, 0.010)


## The canvas of an authored head part: its mesh under its model-space transform (the rotation / scale of the node).
static func node_canvas(c: Vector3, r: float, mesh: Mesh, xf: Transform3D, lift: float) -> Dictionary:
	return FaceKit.canvas(c, r, mesh, Vector3.ONE, xf.origin, xf.basis, lift)


## Eye sparks: a small glowing bead in front of each painted eye (eye centre `eye_c`, face 2D, +x side), `out` m off the
## face: for faces sunk under a hood / brow the painted eyes alone do not reach the bloom from the RTS camera (10 vertices
## each).
static func sparks(acc: Dictionary, cv: Dictionary, eye_c: Vector2, r: float, out: float, col: Color = GLOW) -> void:
	for sx: float in [-1.0, 1.0]:
		var pn: Array = FaceKit.point(cv, Vector2(eye_c.x * sx, eye_c.y), out)
		FaceKit.put_mesh(acc, CharacterModel.sphere(1.0, 4, 1), Transform3D(Basis.from_scale(Vector3(r, r * 0.8, r)), pn[0]),
			FaceKit.glow(col.lerp(Color(1, 1, 1), 0.3), 1.0))


## Lank hair strands (thin spikes) hanging from `roots` (model space) by `length`, fanned by `splay`.
static func strands(acc: Dictionary, roots: Array, length: float, w: float, col: Color, tip: Color, splay: Vector3 = Vector3.ZERO) -> void:
	for i: int in roots.size():
		var r: Vector3 = roots[i]
		var s := 1.0 if r.x >= 0.0 else -1.0
		var tipp := r + Vector3(splay.x * s, -length, splay.z)
		NatureFaces.spike(acc, r, tipp, w, w * 0.45, Vector3(s, 0, 0.4).normalized(), col, tip)
