class_name RiderShapes
extends RefCounted
## G-C leftovers (docs/art/gc_leftovers.md): shaped pieces for the MountModel-style sculpts ({"by", "order"} dictionaries
## merged per material) the cavalry riders, the Nature mounts and a few foot units are built from. Each call builds a
## smooth / bevelled mesh with ChampionShapes (tubes with parallel-transported rings and taper-leaning normals, bevelled
## plates whose chamfer ring catches a light line, lames with a rolled lip, banner-UV cloth, studs) and adds it to the
## sculpt with MountModel.sculpt_add. The callers cache the whole sculpt per part (once per process), so nothing here
## is cached and nothing is built at runtime per instance.
## Drop-in replacements for the old primitives:
##   box(Vector3) at / rot_deg            -> box_plate(s, mat, size, at, rot_deg)   (bevelled, optional taper / pointed hem)
##   _seg(a, b) + joint sphere + _seg(b, c) -> limb(s, mat, a, b, c, ra, rb, rc)   (one tube, muscle swell, no kink)
##   capsule foot                         -> boot(s, mat, heel, toe, r)             (rounded toe-forward foot)
## Model space in, model space out. UV stays (0, 0) except cloth (banner shader: x across, y 0 at the top edge), so no
## piece ever falls in the Nature shader's negative UV tag ranges.


static func _add(s: Dictionary, st: SurfaceTool, mat: Material) -> void:
	st.index()
	var m := st.commit()
	if m.get_surface_count() > 0:
		MountModel.sculpt_add(s, m, Transform3D.IDENTITY, mat)


## Smooth tapered tube through pts (radius per point, 0 = pointed end); sx flattens the ring across.
static func tube(s: Dictionary, mat: Material, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int = 8,
		caps: bool = true, sx: float = 1.0) -> void:
	var st := ChampionShapes.begin()
	ChampionShapes.tube(st, pts, radii, seg, caps, sx)
	_add(s, st, mat)


## A limb from a (root) through the joint b to c (wrist / ankle) as ONE tube: the upper segment swells (bicep / thigh),
## the joint narrows a little, the lower one swells near its top (forearm / calf) and tapers to c. ra / rb / rc = radii
## at a / b / c; swell = how much the muscles bulge (1 = straight cones).
static func limb(s: Dictionary, mat: Material, a: Vector3, b: Vector3, c: Vector3, ra: float, rb: float, rc: float,
		seg: int = 8, swell: float = 1.12, caps: bool = true) -> void:
	var pts := PackedVector3Array([a, a.lerp(b, 0.42), b.lerp(a, 0.12), b, b.lerp(c, 0.28), b.lerp(c, 0.72), c])
	var radii := PackedFloat32Array([ra, lerpf(ra, rb, 0.4) * swell, rb * 1.02, rb * 0.97, lerpf(rb, rc, 0.2) * swell,
		lerpf(rb, rc, 0.75), rc])
	tube(s, mat, pts, radii, seg, caps)


## Bevelled plate in place of box(size) put at `at` with rot_deg (YXZ, like sculpt_put) and scl: a size.x x size.y
## outline, size.z thick, its front face (+Z) inset by the bevel. taper = bottom width / top width; point = how far
## the bottom edge drops to a point at the centre (0 = straight hem, share of size.y); back = chamfer both faces.
static func box_plate(s: Dictionary, mat: Material, size: Vector3, at: Vector3, rot_deg: Vector3 = Vector3.ZERO,
		scl: Vector3 = Vector3.ONE, taper: float = 1.0, point: float = 0.0, back: bool = false, bevel: float = -1.0) -> void:
	var w := size.x * 0.5
	var h := size.y * 0.5
	var wb := w * taper
	var poly := PackedVector2Array([Vector2(-w, h), Vector2(w, h)])
	if point > 0.0:
		var p := size.y * point
		poly.append_array([Vector2(wb, -h + p), Vector2(0, -h), Vector2(-wb, -h + p)])
	else:
		poly.append_array([Vector2(wb, -h), Vector2(-wb, -h)])
	var bv: float = bevel if bevel >= 0.0 else minf(size.z * 0.6, minf(size.x, size.y) * 0.14)
	var xf := Transform3D(Basis.from_euler(rot_deg * (PI / 180.0)) * Basis.from_scale(scl), at)
	plate(s, mat, poly, size.z, bv, xf, back)


## Bevelled plate from an outline (plate space: x right, y up, face +Z), depth thick, placed by xf.
static func plate(s: Dictionary, mat: Material, poly: PackedVector2Array, depth: float, bevel: float, xf: Transform3D,
		back: bool = false) -> void:
	var st := ChampionShapes.begin()
	ChampionShapes.plate(st, poly, depth, bevel, xf, back)
	_add(s, st, mat)


## Surface of revolution (profile Vector2(radius, y) bottom to top) placed by xf; a0 / a1 cut an open arc (0 = +Z).
static func lathe(s: Dictionary, mat: Material, prof: PackedVector2Array, seg: int, xf: Transform3D = Transform3D.IDENTITY,
		sx: float = 1.0, sz: float = 1.0, caps: bool = true, a0: float = 0.0, a1: float = TAU, flat: bool = false) -> void:
	var st := ChampionShapes.begin()
	ChampionShapes.lathe(st, prof, seg, xf, sx, sz, caps, a0, a1, flat)
	_add(s, st, mat)


## Curved armour lame with a rolled lower lip (see ChampionShapes.lame): pauldron plates, faulds, greaves, tassets.
static func lame(s: Dictionary, mat: Material, r0: float, r1: float, y0: float, y1: float, a0: float, a1: float, seg: int,
		thick: float, xf: Transform3D = Transform3D.IDENTITY, sx: float = 1.0, sz: float = 1.0) -> void:
	var st := ChampionShapes.begin()
	ChampionShapes.lame(st, r0, r1, y0, y1, a0, a1, seg, thick, xf, sx, sz)
	_add(s, st, mat)


## Hanging cloth with banner UVs (top edge along `top`, falls `drop`, flares, leans back, folds); both faces drawn.
static func cloth(s: Dictionary, mat: Material, top: PackedVector3Array, drop: float, flare: float, lean: float,
		cols: int = 5, rows: int = 3, folds: float = 2.0, fold: float = 0.02, curl: float = 0.0) -> void:
	var st := ChampionShapes.begin()
	ChampionShapes.cloth(st, top, drop, flare, lean, cols, rows, folds, fold, curl)
	_add(s, st, mat)


## Domed studs (rivets / bolts) at each point of `at`, facing dir.
static func studs(s: Dictionary, mat: Material, at: PackedVector3Array, dir: Vector3, r: float) -> void:
	var st := ChampionShapes.begin()
	for p: Vector3 in at:
		ChampionShapes.stud(st, p, dir, r)
	_add(s, st, mat)


## A flat band ring (rims, bracers, grip wraps) around the local Y of xf.
static func band(s: Dictionary, mat: Material, r: float, h: float, thick: float, seg: int, xf: Transform3D,
		sx: float = 1.0, sz: float = 1.0) -> void:
	var st := ChampionShapes.begin()
	ChampionShapes.band(st, r, h, thick, seg, xf, sx, sz)
	_add(s, st, mat)


## A rounded toe-forward foot from the heel to the toe (radius r at the ball), flattened top-bottom, with a short
## shaft ring at the heel so it seats into the leg. Replaces capsule / box feet.
static func boot(s: Dictionary, mat: Material, heel: Vector3, toe: Vector3, r: float, seg: int = 8) -> void:
	var l := heel.distance_to(toe)
	if l < 0.001:
		return
	# built along +Z (ring ref +X, so the 0.72 squash is vertical), then turned onto heel -> toe with +Y kept up
	var pts := PackedVector3Array([Vector3.ZERO, Vector3(0, 0, l * 0.3), Vector3(0, 0, l * 0.68), Vector3(0, 0, l * 0.9),
		Vector3(0, 0, l)])
	var radii := PackedFloat32Array([r * 0.78, r * 1.0, r * 0.98, r * 0.78, r * 0.32])
	var st := ChampionShapes.begin()
	ChampionShapes.tube(st, pts, radii, seg, true, 0.72)
	st.index()
	var z := (toe - heel) / l
	var y := Vector3.UP - z * z.y
	if y.length_squared() < 1e-4:
		y = Vector3.BACK
	y = y.normalized()
	MountModel.sculpt_add(s, st.commit(), Transform3D(Basis(y.cross(z), y, z), heel), mat)


## Cylinder-section helper for a sculpt: a frame whose +Y runs from a to b (for lathes / bands along a bone).
static func along(a: Vector3, b: Vector3, z_hint: Vector3 = Vector3.BACK) -> Transform3D:
	return MountModel.frame(a, b - a, z_hint)
