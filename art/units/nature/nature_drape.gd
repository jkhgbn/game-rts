class_name NatureDrape
extends RefCounted
## Draped cloth panels for the Nature riders (G-E fixes D, docs/art/ge_fixes_d.md): a drop-in for the flat team-cloth
## boxes (tabards, capes, mantles, sashes) with a shaped, hanging look: tapered or flared width, a body wrap (bulge
## across), a bow along the length, folds that deepen toward the hem and a leaf-point / scalloped hem.
## Local frame like the box it replaces: centred at the origin, width along X, length along Y (top +Y), the front face
## toward +Z (wrap > 0 bulges toward +Z; a cape whose outside is -Z passes wrap < 0).
## Cost: a (cols + 1) x (rows + 1) grid per face (default 7 x 4, 56 vertices two-sided vs the box's 24), merged into the
## part's existing material surface by the sculpt (no extra draw). Cached per key (static, shared by every unit).
## UV = (across 0..1, top 0 .. hem 1), >= 0: no NatureModel UV tag (plain cloth look).

static var _cache: Dictionary = {}


## w_top / w_bot: width at the top / at the hem; h: length (top to the hem's corners); wrap: bulge across (m, centre vs
## edges); bow: bulge along the length (m, middle vs the ends); folds: number of fold waves across; fold_amp: fold depth
## at the hem (m, 0 at the top); hem_point: extra length at the centre of the hem (m, the leaf point); hem_scallop:
## extra length per fold crest (m); thick: front-to-back gap of the two faces (m).
## win: the part of the panel to build (u -1..1 across, v 0..1 down), e.g. a centre stripe or a hem band;
## lift: offset along the front normal (m; a stripe / trim on the panel); faces: 0 both, 1 the front (+Z) face only,
## -1 the back face only (a stripe on a cape whose outside is -Z: lift < 0).
static func panel(key: String, w_top: float, w_bot: float, h: float, wrap: float, bow: float, folds: float,
		fold_amp: float, hem_point: float, hem_scallop: float, thick: float, win: Rect2 = Rect2(-1.0, 0.0, 2.0, 1.0),
		lift: float = 0.0, faces: int = 0) -> Mesh:
	if _cache.has(key):
		return _cache[key]
	var cols: int = clampi(int(ceil(6.0 * win.size.x * 0.5)), 1, 8)
	if folds > 0.0 and win.size.x >= 1.0:
		cols = maxi(cols, 6)
	var rows: int = clampi(int(ceil(3.0 * win.size.y)), 1, 4)
	var sh := [w_top, w_bot, h, wrap, bow, folds, fold_amp, hem_point, hem_scallop]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := PackedFloat32Array([1.0, -1.0]) if faces == 0 else PackedFloat32Array([float(signi(faces))])
	var base := 0
	for side: float in sides:
		for ir: int in rows + 1:
			var v: float = win.position.y + win.size.y * float(ir) / float(rows)
			for ic: int in cols + 1:
				var u: float = win.position.x + win.size.x * float(ic) / float(cols)
				var p := _surf(sh, u, v)
				var n := _normal(sh, u, v)
				var off: float = lift - thick if side < 0.0 and faces == 0 else lift
				st.set_uv(Vector2(u * 0.5 + 0.5, v))
				st.set_normal(n * side)
				st.add_vertex(p + n * off)
		var row := cols + 1
		for ir: int in rows:
			for ic: int in cols:
				var i0 := base + ir * row + ic
				var i1 := i0 + 1
				var i2 := i0 + row
				var i3 := i2 + 1
				# front (+Z) faces wind clockwise seen from +Z (Godot front = clockwise); the back face the other way
				if side > 0.0:
					st.add_index(i0); st.add_index(i1); st.add_index(i3)
					st.add_index(i0); st.add_index(i3); st.add_index(i2)
				else:
					st.add_index(i0); st.add_index(i3); st.add_index(i1)
					st.add_index(i0); st.add_index(i2); st.add_index(i3)
		base += (rows + 1) * row
	var mesh := st.commit()
	_cache[key] = mesh
	return mesh


## Surface point at (u -1..1 across, v 0 top .. 1 hem).
static func _surf(sh: Array, u: float, v: float) -> Vector3:
	var w_top: float = sh[0]
	var w_bot: float = sh[1]
	var h: float = sh[2]
	var wrap: float = sh[3]
	var bow: float = sh[4]
	var folds: float = sh[5]
	var fold_amp: float = sh[6]
	var hem_point: float = sh[7]
	var hem_scallop: float = sh[8]
	var half_w: float = lerpf(w_top, w_bot, v) * 0.5
	var crest: float = absf(sin(u * folds * PI * 0.5)) if folds > 0.0 else 0.0
	var hem: float = hem_point * (1.0 - absf(u)) + hem_scallop * crest
	var y: float = h * 0.5 - v * h - hem * v * v
	var z: float = wrap * (1.0 - u * u) + bow * (1.0 - (2.0 * v - 1.0) * (2.0 * v - 1.0))
	if folds > 0.0:
		z += fold_amp * v * cos(u * folds * PI)
	return Vector3(u * half_w, y, z)


static func _normal(sh: Array, u: float, v: float) -> Vector3:
	var e := 0.01
	var du := _surf(sh, u + e, v) - _surf(sh, u - e, v)
	var dv := _surf(sh, u, v + e) - _surf(sh, u, v - e)
	var n := dv.cross(du)
	if n.z < 0.0:
		n = -n
	return n.normalized() if n.length_squared() > 1e-12 else Vector3.BACK
