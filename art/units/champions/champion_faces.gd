class_name ChampionFaces
extends RefCounted
## FaceKit faces of the hired champions and the helpers that reuse their models (faces pass 2026-09-28). Champions are
## named characters with two variants (A / B: siblings); each variant gets its own face style (key "<id>_a" / "<id>_b":
## a beard, other brows...), built once per game and swapped on the ONE Face node when set_variant() changes it.
## Detail normal (not the soldiers' low): these are the heroes of the bounty board and the tavern portraits.
##
##   _face = ChampionFaces.attach(self, head, "wayfinder", _face_spec, variant)   # in _build_parts
##   ChampionFaces.switch(_face, "wayfinder", _face_spec, v)                       # in set_variant (safe before _ready)
## `spec_fn` = Callable(variant: int) -> Dictionary (a FaceKit.style_from() spec, or a full style with "canvas").

static var _styles: Dictionary = {}


## The style of one variant (built + warmed once per game: every expression and the FAR face).
static func style(base: String, spec_fn: Callable, v: int) -> Dictionary:
	var key := key_of(base, v)
	if not _styles.has(key):
		var spec: Dictionary = spec_fn.call(v)
		var st: Dictionary = spec if spec.has("canvas") else FaceKit.style_from(spec)
		FaceKit.warm(key, st)
		_styles[key] = st
	return _styles[key]


static func key_of(base: String, v: int) -> String:
	return "%s_%s" % [base, "b" if v == 1 else "a"]


## Adds the Face node (FaceKit.attach) for variant `v` under `head`.
static func attach(model: Node3D, head: Node3D, base: String, spec_fn: Callable, v: int) -> FaceRig:
	return FaceKit.attach(model, head, key_of(base, v), style(base, spec_fn, v))


## Shows variant `v`'s face on an existing rig (keeps the requested expression). No-op when rig is null.
static func switch(rig: FaceRig, base: String, spec_fn: Callable, v: int) -> void:
	if rig == null:
		return
	var keep := rig.get_expression()
	rig.setup(key_of(base, v), style(base, spec_fn, v))
	rig.set_expression(keep)


## Hair framing a face in a hood / under a hat brim, where the kit's hair cap would hide: a swept fringe across the
## forehead (`fringe` +1 sweeps to model +X, -1 to -X, 0 = none) and a lock down each cheek to the jaw (`sides`).
## Unit-sphere placement around the face centre c (radius r, `zs` = depth scale of a flattened face). ~114 + 2 x 144 v.
static func frame_locks(acc: Dictionary, c: Vector3, r: float, col: Color, tip: Color, fringe: float = 1.0,
		sides: bool = true, zs: float = 1.0, drop: float = 1.0, side_rings: int = 5) -> void:
	var o := func(x: float, y: float, z: float) -> Vector3: return c + Vector3(x, y, z * zs) * r
	if fringe != 0.0:
		var f := fringe
		FaceKit.lock(acc, [o.call(-0.42 * f, 0.74, 0.62), o.call(-0.05 * f, 0.72, 0.78), o.call(0.34 * f, 0.58, 0.80),
			o.call(0.62 * f, 0.34, 0.74)], Vector3(0, 0.35, 1).normalized(), 0.62 * r, 0.14 * r, col, tip, 4, 0.55, -18.0 * f)
	if sides:
		for sx: float in [-1.0, 1.0]:
			FaceKit.lock(acc, [o.call(0.60 * sx, 0.62, 0.58), o.call(0.88 * sx, 0.24, 0.52), o.call(0.90 * sx, -0.28 * drop, 0.44),
				o.call(0.74 * sx, -0.66 * drop, 0.40)], Vector3(sx, 0.0, 0.7).normalized(), 0.34 * r, 0.14 * r, col, tip, side_rings, 0.6,
				10.0 * sx)
