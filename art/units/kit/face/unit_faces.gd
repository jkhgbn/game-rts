class_name UnitFaces
extends RefCounted
## Small shared helpers for the army units' FaceKit faces (faces pass 2026-09-28, Fire + Ice units). The face itself is
## FaceKit.attach (face_kit.gd); these only build extra hair / beard pieces for the spec's "hair_fn" / "extra".


## A swept fringe peeking out of a hood: ONE wide lock from under the hood edge across the forehead to the temple
## (`side` +1 = sweeps to model +X). Hugs the face sphere (centre c, radius r; `zs` = the face's depth scale for
## flattened faces). ~84 vertices. For hooded units, where the kit's hair cap would hide inside the hood.
static func hood_fringe(acc: Dictionary, c: Vector3, r: float, col: Color, tip: Color, side: float = 1.0, zs: float = 1.0) -> void:
	var pts: Array = []
	for q: Vector2 in [Vector2(-0.44, 0.82), Vector2(-0.14, 0.80), Vector2(0.28, 0.62), Vector2(0.54, 0.36)]:
		var z := sqrt(maxf(0.0, 1.0 - q.x * q.x - q.y * q.y)) + 0.07
		pts.append(c + Vector3(q.x * side, q.y, z * zs) * r)
	FaceKit.lock(acc, pts, Vector3(0, 0.45, 1).normalized(), 0.58 * r, 0.12 * r, col, tip, 4, 0.55, -20.0 * side)


## A cheaper face (~130 vertices less; ~200 with blush false) for mass units whose model already fills its vertex budget:
## no tiny eye highlights / lid creases at rest (bold 1.001: the kit skips them above 1.0; the lines keep their width).
## Pass FaceKit.style_from(spec) and give the result to FaceKit.attach. `blush` false = no cheek fills either.
static func lean(style: Dictionary, blush: bool = true, density: float = 4.5) -> Dictionary:
	style["density"] = density   # coarser outlines (the kit's low detail is 3.0): fine on the small army heads
	var xo: Dictionary = style.get("x", {})
	for id: StringName in FaceKit.EXPRESSIONS:
		if not xo.has(id):
			xo[id] = {}
		xo[id]["bold"] = 1.001
		if not blush:
			xo[id]["blush"] = 0.0
	style["x"] = xo
	return style


static var _lean_cache: Dictionary = {}


## FaceKit.attach with a lean() style (built once per key, like attach's own cache: later instances reuse it).
static func attach_lean(model: Node3D, head: Node3D, key: String, spec: Dictionary, blush: bool = true) -> FaceRig:
	if not _lean_cache.has(key):
		_lean_cache[key] = lean(FaceKit.style_from(spec), blush)
	return FaceKit.attach(model, head, key, _lean_cache[key])
