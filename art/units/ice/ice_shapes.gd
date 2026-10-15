class_name IceUnitShapes
extends RefCounted
## G-C leftovers (2026-10-15, docs/art/gc_leftovers.md): small helpers for the Ice units reshaped from boxes / capsules
## into ChampionShapes tubes, lathes and bevelled plates. A pivot's pieces are built ONCE per process into one
## SurfaceTool per material (`build(acc)`, acc = {Material: SurfaceTool}), committed, cached by key, and added with
## the kit's add_part (they merge into the pivot like any primitive: vertices, never draw calls). Model space.

static var _parts: Dictionary = {}     # key -> Array of [Material, Mesh]


## Builds the pieces once (cached by key) and adds one part per material to `pivot` of `model`.
static func put(model: CharacterModel, pivot: Node3D, key: String, build: Callable) -> void:
	if not _parts.has(key):
		var acc: Dictionary = {}
		build.call(acc)
		var out: Array = []
		for m: Material in acc:
			out.append([m, ChampionShapes.commit(acc[m])])
		_parts[key] = out
	for pr: Array in _parts[key]:
		model.add_part(pivot, pr[1], pr[0], Vector3.ZERO)


## One mesh (all surfaces of one material) for a keep_separate piece or a bake: cached by key.
static func mesh(key: String, build: Callable) -> Mesh:
	if not _parts.has(key):
		var st := ChampionShapes.begin()
		build.call(st)
		_parts[key] = [[null, ChampionShapes.commit(st)]]
	return _parts[key][0][1]


## The SurfaceTool of material m in acc (created on first use).
static func st(acc: Dictionary, m: Material) -> SurfaceTool:
	if not acc.has(m):
		acc[m] = ChampionShapes.begin()
	return acc[m]


## Local +Y along dir, origin at `at`.
static func on(dir: Vector3, at: Vector3) -> Transform3D:
	var n := dir.normalized()
	if n.dot(Vector3.DOWN) > 0.999:
		return Transform3D(Basis(Vector3.RIGHT, PI), at)
	return Transform3D(Basis(Quaternion(Vector3.UP, n)), at)


## Euler degrees (YXZ like rotation_degrees) + scale.
static func xf(at: Vector3, rot_deg: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot_deg * (PI / 180.0)).scaled_local(scl), at)


## A faceted ice crystal along dir: prism and point, flat shaded.
static func crystal(s: SurfaceTool, base: Vector3, dir: Vector3, r: float, h: float, seg: int = 5) -> void:
	ChampionShapes.lathe(s, PackedVector2Array([Vector2(r, 0.0), Vector2(r * 0.8, h * 0.6), Vector2(0.0, h)]), seg,
		on(dir, base), 1.0, 1.0, false, 0.0, TAU, true)


## An egg (shell, mitt, pebble, pouch) along local +Y of t: radius r, height h.
static func egg(s: SurfaceTool, t: Transform3D, r: float, h: float, seg: int = 6) -> void:
	ChampionShapes.lathe(s, PackedVector2Array([Vector2(0.0, -h * 0.42), Vector2(r, -h * 0.12), Vector2(r * 0.78, h * 0.32),
		Vector2(0.0, h * 0.58)]), seg, t, 1.0, 1.0, false)


## A flat strap following pts (width w, thickness th): a tube whose section is stretched across.
static func strap(s: SurfaceTool, pts: PackedVector3Array, w: float, th: float, seg: int = 4) -> void:
	var radii := PackedFloat32Array()
	for i: int in pts.size():
		radii.append(th * 0.5)
	ChampionShapes.tube(s, pts, radii, seg, false, w / maxf(th, 0.001))


## A limb through a -> b -> c (radii ra rb rc), open ends (a cuff / glove / boot covers them).
static func limb(s: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, ra: float, rb: float, rc: float, seg: int = 6) -> void:
	ChampionShapes.tube(s, PackedVector3Array([a, b, c]), PackedFloat32Array([ra, rb, rc]), seg, false)
