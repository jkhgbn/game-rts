extends RefCounted
## G-F crown isle variants (docs/art/gf_crown_isle.md): the meshes, built in code once per run (static cache). No new
## material, shader, light or particle: every mesh is a copy of an existing one with its vertex colours (and, on the
## nature_mat stone kind, its moss amount) repainted, or a new mesh in the shared nature_mat.tres vertex format
## (nature_painted.gdshader header: COLOR.rgb sRGB colour, COLOR.a height gradient, UV.x wind / stone moss amount,
## UV.y local height, UV2 = (variant mask, kind)). Reach it with load():
##     var cm: GDScript = load("res://art/environment/crown_variants/crown_isle_meshes.gd")
##     cm.recolored(mesh, &"thornwater")   # a repainted copy (stone surfaces only; gold, embers, glass untouched)
##     cm.stump(mesh, &"thornwater")       # the ruin pillar broken off at ~1.1 m, jagged top, repainted
##     cm.garland()                        # Quartermeet: a straw harvest rope round a pillar shaft (r 0.66, 2 tails)
## Variants: &"thornwater" (peat-dark wet stone, moss climbing from the waterline, mossy tops), &"quartermeet" (cool
## granite, yellow / orange lichen rosettes, dry), &"neutral" (weathered grey-brown, sparse moss). Unknown = unchanged.

const NATURE_SHADER := "nature_painted.gdshader"
## AutumnSwap (Quartermeet, Ashwind) points the shared nature_mat at this shader: same vertex format.
const NATURE_AUTUMN_SHADER := "nature_autumn.gdshader"
const ENV_SHADER := "env_painted.gdshader"
const NATURE_MAT := "res://art/environment/nature_props/nature_mat.tres"
const KIND_BARK := 0
const KIND_STONE := 3
const VARIANTS: Array[StringName] = [&"thornwater", &"quartermeet", &"neutral"]

## Stone palettes (sRGB; the source value is kept: base x source luminance / REF_LUM).
const REF_LUM := 0.47
const STONE := {
	&"thornwater": Color(0.335, 0.33, 0.285),
	&"quartermeet": Color(0.50, 0.515, 0.52),
	&"neutral": Color(0.47, 0.45, 0.405),
}
const MOSS := {
	&"thornwater": Color(0.17, 0.22, 0.11),
	&"quartermeet": Color(0.40, 0.44, 0.22),
	&"neutral": Color(0.27, 0.31, 0.17),
}
## Share of the surface that takes the painted moss / lichen patch (value-noise threshold, 0 = none).
const MOSS_COVER := {&"thornwater": 0.30, &"quartermeet": 0.0, &"neutral": 0.16}
## The nature_mat stone moss amount (UV.x): thornwater lush, quartermeet dry, neutral a little.
const MOSS_UV := {&"thornwater": 0.55, &"quartermeet": 0.12, &"neutral": 0.35}
const LICHEN_Y := Color(0.74, 0.69, 0.40)
const LICHEN_O := Color(0.72, 0.48, 0.24)
const WET_FOOT := 0.62          ## thornwater: the wet dark band below this local height (m)
const STUMP_CUT := 1.05          ## local height of the break (m)
const SHAFT_R := 0.6             ## ruin pillar shaft radius (m)
const STRAW := Color(0.74, 0.65, 0.40)
const STRAW_L := Color(0.86, 0.79, 0.55)
const STRAW_D := Color(0.55, 0.47, 0.28)

static var _cache: Dictionary = {}


static func clear_cache() -> void:
	_cache.clear()


## A copy of `src` with every nature / env painted surface repainted for `variant` (other surfaces shared as they
## are). Returns `src` itself for an unknown variant.
static func recolored(src: Mesh, variant: StringName) -> Mesh:
	if src == null or not VARIANTS.has(variant):
		return src
	var key := "rc:%d:%s" % [src.get_instance_id(), variant]
	if _cache.has(key):
		return _cache[key]
	var out := _rebuild(src, variant, -1.0)
	_cache[key] = out
	return out


## The pillar `src` broken off at about STUMP_CUT (a jagged top, the shaft pulled in so the capital never flares out
## at the break), repainted for `variant` (the break face lighter: fresh stone; thornwater: mossy).
static func stump(src: Mesh, variant: StringName) -> Mesh:
	if src == null:
		return null
	var key := "st:%d:%s" % [src.get_instance_id(), variant]
	if _cache.has(key):
		return _cache[key]
	var out := _rebuild(src, variant, STUMP_CUT)
	_cache[key] = out
	return out


## True when surface `s` of `m` uses one of the painted prop shaders (the ones this script repaints).
static func is_painted_surface(m: Mesh, s: int) -> bool:
	var mat := m.surface_get_material(s) as ShaderMaterial
	return mat != null and mat.shader != null and (is_nature(mat) or mat.shader.resource_path.ends_with(ENV_SHADER))


## True for the nature_painted vertex format (the shared nature_mat, whatever shader a map look gave it).
static func is_nature(mat: Material) -> bool:
	var sm := mat as ShaderMaterial
	if sm == null or sm.shader == null:
		return false
	var sp := sm.shader.resource_path
	return sm.resource_path == NATURE_MAT or sp.ends_with(NATURE_SHADER) or sp.ends_with(NATURE_AUTUMN_SHADER)


static func _rebuild(src: Mesh, variant: StringName, cut: float) -> ArrayMesh:
	var out := ArrayMesh.new()
	for s: int in src.get_surface_count():
		var arrays: Array = src.surface_get_arrays(s)
		var mat := src.surface_get_material(s)
		var painted := is_painted_surface(src, s)
		if cut > 0.0:
			arrays = _cut_arrays(arrays, cut)
		if painted:
			var nature := is_nature(mat)
			_paint(arrays, variant, nature, cut)
		out.add_surface_from_arrays(src.surface_get_primitive_type(s), arrays)
		out.surface_set_material(out.get_surface_count() - 1, mat)
	return out


## The break: every vertex above the jagged cut height drops onto it and is pulled in to the shaft radius.
static func _cut_arrays(arrays: Array, cut: float) -> Array:
	var a := arrays.duplicate()
	var v: PackedVector3Array = (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).duplicate()
	var n: PackedVector3Array = PackedVector3Array()
	if a[Mesh.ARRAY_NORMAL] is PackedVector3Array:
		n = (a[Mesh.ARRAY_NORMAL] as PackedVector3Array).duplicate()
	var uv := PackedVector2Array()
	if a[Mesh.ARRAY_TEX_UV] is PackedVector2Array:
		uv = (a[Mesh.ARRAY_TEX_UV] as PackedVector2Array).duplicate()
	for i: int in v.size():
		var p := v[i]
		var ang := atan2(p.z, p.x)
		var h := cut + 0.2 * sin(ang * 3.0 + 0.7) + 0.11 * sin(ang * 7.0 + 2.1)
		if p.y <= h:
			continue
		var r := Vector2(p.x, p.z).length()
		var k := minf(1.0, SHAFT_R * 0.96 / maxf(r, 0.001))
		v[i] = Vector3(p.x * k, h - 0.08 * (1.0 - k), p.z * k)
		if i < n.size():
			n[i] = (n[i] * 0.35 + Vector3.UP).normalized()
		if i < uv.size():
			uv[i].y = v[i].y
	a[Mesh.ARRAY_VERTEX] = v
	if not n.is_empty():
		a[Mesh.ARRAY_NORMAL] = n
	if not uv.is_empty():
		a[Mesh.ARRAY_TEX_UV] = uv
	return a


static func _paint(a: Array, variant: StringName, nature: bool, cut: float) -> void:
	if not (a[Mesh.ARRAY_COLOR] is PackedColorArray):
		return
	var c: PackedColorArray = (a[Mesh.ARRAY_COLOR] as PackedColorArray).duplicate()
	var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = a[Mesh.ARRAY_NORMAL] if a[Mesh.ARRAY_NORMAL] is PackedVector3Array else PackedVector3Array()
	var uv := PackedVector2Array()
	if a[Mesh.ARRAY_TEX_UV] is PackedVector2Array:
		uv = (a[Mesh.ARRAY_TEX_UV] as PackedVector2Array).duplicate()
	var uv2 := PackedVector2Array()
	if a[Mesh.ARRAY_TEX_UV2] is PackedVector2Array:
		uv2 = a[Mesh.ARRAY_TEX_UV2]
	var base: Color = STONE[variant]
	var moss: Color = MOSS[variant]
	var cover: float = MOSS_COVER[variant]
	for i: int in c.size():
		var col := c[i]
		var kind := int(roundf(uv2[i].y)) if i < uv2.size() else KIND_STONE
		var stone := kind == KIND_STONE if nature else true
		var sat := maxf(col.r, maxf(col.g, col.b)) - minf(col.r, minf(col.g, col.b))
		if not stone or sat > 0.14:
			continue   # moss / ivy / leaves / gold / painted accents keep their colour
		var p := v[i]
		var nrm := n[i] if i < n.size() else Vector3.UP
		var lum := col.r * 0.3 + col.g * 0.59 + col.b * 0.11
		var k := clampf(lum / REF_LUM, 0.45, 1.2)
		var nz := _vnoise(p * 1.6)
		var out := Color(base.r * k, base.g * k, base.b * k) * (0.94 + 0.12 * _vnoise(p * 4.3 + Vector3(3.1, 7.7, 1.3)))
		var broken := cut > 0.0 and absf(p.y - cut) < 0.35 and nrm.y > 0.6
		match variant:
			&"thornwater":
				if p.y < WET_FOOT:   # wet dark foot: the water stood here
					out = out.lerp(Color(0.17, 0.17, 0.13), 0.55 * (1.0 - p.y / WET_FOOT))
				var climb := cover + 0.2 * (1.0 - smoothstep(0.0, 1.6, p.y))
				if nrm.y > 0.7 and p.y < 0.3:
					climb *= 0.35   # walked tops (bridge decks, steps) stay stone: moss keeps to the joints
				if nz < climb:
					out = out.lerp(moss * (0.85 + 0.3 * nz), clampf((climb - nz) * 4.0, 0.0, 0.72))
			&"quartermeet":
				var lz := _vnoise(p * 3.2 + Vector3(11.0, 2.0, 5.0))
				if nrm.y > -0.3 and lz > 0.74:
					out = out.lerp(LICHEN_Y if _vnoise(p * 0.9) > 0.45 else LICHEN_O, clampf((lz - 0.74) * 6.0, 0.0, 0.75))
			_:
				if nz < cover + 0.08 * maxf(nrm.y, 0.0):
					out = out.lerp(moss, 0.45)
		if broken:
			out = moss.lerp(out, 0.4) if variant == &"thornwater" else out.lightened(0.16)
		out.a = col.a
		c[i] = out
		if nature and i < uv.size() and stone:
			if variant == &"quartermeet" or (nrm.y > 0.7 and p.y < 0.3):
				uv[i].x = minf(uv[i].x, MOSS_UV[variant])   # dry granite; walked tops never gain moss
			else:
				uv[i].x = lerpf(uv[i].x, MOSS_UV[variant], 0.6)
	a[Mesh.ARRAY_COLOR] = c
	if not uv.is_empty():
		a[Mesh.ARRAY_TEX_UV] = uv


## 3D value noise 0-1 (trilinear, smooth), deterministic.
static func _vnoise(p: Vector3) -> float:
	var i := p.floor()
	var f := p - i
	f = f * f * (Vector3.ONE * 3.0 - f * 2.0)
	var n000 := _h(i)
	var n100 := _h(i + Vector3(1, 0, 0))
	var n010 := _h(i + Vector3(0, 1, 0))
	var n110 := _h(i + Vector3(1, 1, 0))
	var n001 := _h(i + Vector3(0, 0, 1))
	var n101 := _h(i + Vector3(1, 0, 1))
	var n011 := _h(i + Vector3(0, 1, 1))
	var n111 := _h(i + Vector3(1, 1, 1))
	var x00 := lerpf(n000, n100, f.x)
	var x10 := lerpf(n010, n110, f.x)
	var x01 := lerpf(n001, n101, f.x)
	var x11 := lerpf(n011, n111, f.x)
	return lerpf(lerpf(x00, x10, f.y), lerpf(x01, x11, f.y), f.z)


static func _h(p: Vector3) -> float:
	return fposmod(sin(p.dot(Vector3(12.9898, 78.233, 37.719))) * 43758.5453, 1.0)


# ---------------------------------------------------------------- the Quartermeet garland

## A straw rope round a pillar shaft at y 0 (the instance puts it at the right height): r 0.66, sagging on one side,
## two sheaf tails hanging from the low side. ~230 triangles, nature_mat bark kind (no wind, no moss).
static func garland() -> ArrayMesh:
	if _cache.has("garland"):
		return _cache["garland"]
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var uv := PackedVector2Array()
	var uv2 := PackedVector2Array()
	var seg := 16
	var path: Array[Vector3] = []
	var radii: Array[float] = []
	for i: int in seg + 1:
		var a := i * TAU / seg
		var sag := 0.2 * maxf(0.0, cos(a - 0.5))
		path.append(Vector3(cos(a) * 0.66, -sag, sin(a) * 0.66))
		radii.append(0.075 + 0.015 * sin(a * 5.0))
	_tube(path, radii, 5, STRAW, STRAW_L, v, n, c, uv, uv2)
	for k: int in 2:
		var a := 0.5 + (k - 0.5) * 0.8
		var out := Vector3(cos(a), 0.0, sin(a))
		var p := Vector3(cos(a) * 0.66, -0.2 * maxf(0.0, cos(a - 0.5)), sin(a) * 0.66)
		var tail: Array[Vector3] = [p, p + out * 0.07 - Vector3(0, 0.28, 0), p + out * 0.1 - Vector3(0, 0.55, 0)]
		var tr: Array[float] = [0.05, 0.075, 0.11]
		_tube(tail, tr, 5, STRAW_D, STRAW_L, v, n, c, uv, uv2)
	var miny := INF
	var maxy := -INF
	for p: Vector3 in v:
		miny = minf(miny, p.y)
		maxy = maxf(maxy, p.y)
	for i: int in c.size():
		var cc := c[i]
		cc.a = clampf((v[i].y - miny) / maxf(maxy - miny, 0.01), 0.0, 1.0)
		c[i] = cc
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = v
	arrays[Mesh.ARRAY_NORMAL] = n
	arrays[Mesh.ARRAY_COLOR] = c
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_TEX_UV2] = uv2
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if ResourceLoader.exists(NATURE_MAT):
		mesh.surface_set_material(0, load(NATURE_MAT) as Material)
	_cache["garland"] = mesh
	return mesh


## A tube along `path`; front faces checked against the outward ring direction (winding from BoxMesh, as the
## Quartermeet builder does).
static func _tube(path: Array[Vector3], radii: Array[float], sides: int, col0: Color, col1: Color,
		v: PackedVector3Array, n: PackedVector3Array, c: PackedColorArray, uv: PackedVector2Array,
		uv2: PackedVector2Array) -> void:
	var conv := _winding()
	var rings: Array = []
	for i: int in path.size():
		var t: Vector3 = (path[mini(i + 1, path.size() - 1)] - path[maxi(i - 1, 0)]).normalized()
		var side := t.cross(Vector3.UP)
		if side.length() < 0.01:
			side = t.cross(Vector3.RIGHT)
		side = side.normalized()
		var up := side.cross(t).normalized()
		var ring: Array[Vector3] = []
		for s: int in sides:
			var a := s * TAU / sides
			ring.append(side * cos(a) + up * sin(a))
		rings.append(ring)
	for i: int in path.size() - 1:
		var ra: Array = rings[i]
		var rb: Array = rings[i + 1]
		var col := col0.lerp(col1, float(i % 3) / 2.0 * 0.6 + float(i) / maxf(path.size() - 2, 1.0) * 0.4)
		for s: int in sides:
			var s2 := (s + 1) % sides
			var a0: Vector3 = path[i] + (ra[s] as Vector3) * radii[i]
			var a1: Vector3 = path[i] + (ra[s2] as Vector3) * radii[i]
			var b0: Vector3 = path[i + 1] + (rb[s] as Vector3) * radii[i + 1]
			var b1: Vector3 = path[i + 1] + (rb[s2] as Vector3) * radii[i + 1]
			var out: Vector3 = (ra[s] as Vector3) + (ra[s2] as Vector3)
			_tri(a0, a1, b1, ra[s], ra[s2], rb[s2], out, col, conv, v, n, c, uv, uv2)
			_tri(a0, b1, b0, ra[s], rb[s2], rb[s], out, col, conv, v, n, c, uv, uv2)


static func _tri(a: Vector3, b: Vector3, cc: Vector3, na: Vector3, nb: Vector3, nc: Vector3, out: Vector3, col: Color,
		conv: float, v: PackedVector3Array, n: PackedVector3Array, c: PackedColorArray, uv: PackedVector2Array,
		uv2: PackedVector2Array) -> void:
	if (b - a).cross(cc - a).dot(out) * conv < 0.0:
		var t := b
		b = cc
		cc = t
		var tn := nb
		nb = nc
		nc = tn
	for pr: Array in [[a, na], [b, nb], [cc, nc]]:
		var pos: Vector3 = pr[0]
		v.append(pos)
		n.append((pr[1] as Vector3).normalized())
		c.append(Color(col.r, col.g, col.b, 1.0))
		uv.append(Vector2(0.0, 2.0 + pos.y))   # off the contact band (the garland hangs ~2 m up)
		uv2.append(Vector2(0.0, KIND_BARK))


static func _winding() -> float:
	if _cache.has("conv"):
		return _cache["conv"]
	var arr: Array = BoxMesh.new().get_mesh_arrays()
	var bv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var bn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var bi: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var fn: Vector3 = (bv[bi[1]] - bv[bi[0]]).cross(bv[bi[2]] - bv[bi[0]])
	var conv := 1.0 if fn.dot(bn[bi[0]]) >= 0.0 else -1.0
	_cache["conv"] = conv
	return conv
