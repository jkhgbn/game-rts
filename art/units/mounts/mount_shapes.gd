class_name MountShapes
## G-C mounts pass (docs/art/gc_mounts_titans.md): shared anatomy helpers for the MountModel sculpts in
## art/units/mounts/ (static, no state; the meshes go through MountModel's cached tube / sphere builders).
## - leg(): ONE continuous tube from the leg root to the coronet through anatomical joints (forearm, knee, cannon,
##   fetlock, pastern; hind: stifle, gaskin, hock, cannon...), flattened side to side like a real leg (wide from the
##   side, narrow from the front), radii swelling at the joints. Replaces stacked tube + ball + tube legs (a kink and a
##   seam at every joint) with about the same vertex count.
## - muscle(): an ellipsoid muscle mass (shoulder, triceps, haunch, gaskin) oriented along a direction.
## Joint tables: Vector3(y, z offset, radius) rows, top to bottom, in model space relative to the leg's x / z.


## Leg tube at model x / z of the pivot `p` (y absolute) through `rows` = [Vector3(y, dz, r), ...]; `w` scales every
## radius, `flat` squashes the side (x) axis. Key must be unique per shape.
## No end caps: the top hides in the body, the coronet in the hoof, a band joint in the next band (saves 2 rings).
static func leg(s: Dictionary, key: String, p: Vector3, rows: Array[Vector3], mat: Material, w: float = 1.0,
		flat: float = 0.78, seg: int = 8) -> void:
	var pts := PackedVector3Array()
	var rad := PackedFloat32Array()
	for r: Vector3 in rows:
		pts.append(Vector3(0, r.x, r.y))
		rad.append(r.z * w)
	MountModel.sculpt_add(s, MountModel.tube_mesh(key, pts, rad, seg, false, flat), Transform3D(Basis.IDENTITY,
		Vector3(p.x, 0, p.z)), mat)


## The same leg in coloured bands (coat / socks / stockings): rows split at the row indices `cuts` (each cut row is
## shared by the two bands, so the outline stays continuous); mats has cuts.size() + 1 entries, top to bottom.
static func leg_bands(s: Dictionary, key: String, p: Vector3, rows: Array[Vector3], cuts: Array, mats: Array,
		w: float = 1.0, flat: float = 0.78, seg: int = 8) -> void:
	var start: int = 0
	for b: int in cuts.size() + 1:
		var stop: int = int(cuts[b]) if b < cuts.size() else rows.size() - 1
		var part: Array[Vector3] = []
		for i: int in range(start, stop + 1):
			part.append(rows[i])
		leg(s, "%s_b%d" % [key, b], p, part, mats[b] as Material, w, flat, seg)
		start = stop


## Ellipsoid muscle mass centred at `c` (model space), radii `r` (x side, y along `dir`, z), its long axis along `dir`.
static func muscle(s: Dictionary, mat: Material, c: Vector3, r: Vector3, dir: Vector3 = Vector3.UP, seg: int = 10,
		rings: int = 5) -> void:
	var y := dir.normalized()
	var x := Vector3.RIGHT - y * Vector3.RIGHT.dot(y)
	if x.length_squared() < 0.01:
		x = Vector3.BACK - y * Vector3.BACK.dot(y)
	x = x.normalized()
	var z := x.cross(y).normalized()
	MountModel.sculpt_add(s, CharacterModel.sphere(1.0, seg, rings), Transform3D(Basis(x * r.x, y * r.y, z * r.z), c), mat)


## Rows scaled from a template: y = y0 + (row.y - y0) * ky above `y0` (the fetlock and hoof stay put), dz * kz,
## radius * kr. Lets one horse template serve a gaunt steed, a cob and a stag.
static func scaled(rows: Array[Vector3], y0: float, ky: float, kz: float = 1.0, kr: float = 1.0) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for r: Vector3 in rows:
		var yy: float = r.x if r.x <= y0 else y0 + (r.x - y0) * ky
		out.append(Vector3(yy, r.y * kz, r.z * kr))
	return out


## Horse fore leg (withers ~1.6 m): elbow + forearm muscle, a bony knee, a flat cannon, the fetlock knob, a sloping
## pastern into the coronet (hoof added by the caller at y ~0.05, dz +0.05).
const HORSE_FORE: Array[Vector3] = [Vector3(1.17, 0.0, 0.125), Vector3(1.02, -0.025, 0.118), Vector3(0.88, -0.005, 0.098),
	Vector3(0.74, 0.008, 0.074), Vector3(0.62, 0.016, 0.058), Vector3(0.56, 0.024, 0.062), Vector3(0.50, 0.022, 0.058),
	Vector3(0.45, 0.014, 0.046), Vector3(0.32, 0.006, 0.041), Vector3(0.215, 0.0, 0.046), Vector3(0.18, -0.004, 0.053),
	Vector3(0.14, 0.012, 0.046), Vector3(0.105, 0.032, 0.044), Vector3(0.08, 0.046, 0.052)]
## Horse hind leg: haunch into the stifle (forward), gaskin sloping back to the HOCK (point behind), a vertical
## cannon, fetlock, pastern, coronet (hoof at dz -0.045).
const HORSE_HIND: Array[Vector3] = [Vector3(1.17, 0.0, 0.15), Vector3(1.03, 0.045, 0.138), Vector3(0.90, 0.02, 0.112),
	Vector3(0.78, -0.045, 0.082), Vector3(0.67, -0.105, 0.064), Vector3(0.60, -0.14, 0.058), Vector3(0.555, -0.15, 0.064),
	Vector3(0.51, -0.14, 0.055), Vector3(0.45, -0.125, 0.046), Vector3(0.32, -0.11, 0.042), Vector3(0.215, -0.1, 0.047),
	Vector3(0.18, -0.098, 0.054), Vector3(0.14, -0.084, 0.046), Vector3(0.105, -0.064, 0.044), Vector3(0.08, -0.05, 0.052)]
