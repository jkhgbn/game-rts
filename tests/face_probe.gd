extends RefCounted
## Shared probes for the art tests that predate the faces pass (2026-09-28, art/units/kit/face/): every unit now has a
## FaceKit face (eyes, lips, ears, hair) = ONE extra surface on the shared material unit_face.tres (own Face node, or
## appended inside a merged pivot mesh by CreatureFaceRig "host" mode), and the old glowing eye meshes / materials are
## now the face's glowing irises: FaceKit.glow() writes vertex alpha = 1 - glow on that surface.
## Usage in a test:  const FaceProbe := preload("res://tests/face_probe.gd")

const FACE_MAT := "res://art/units/kit/face/unit_face.tres"
## A glow POINT: face vertices with glow >= 0.5 (alpha <= 0.5): the irises (iris_glow 0.75-0.9) and glowing mouths.
## The kit's tiny eye highlights (glow 0.35) and a faintly glowing sclera (0.25) do not count.
const GLOW_ALPHA := 0.5


static func is_face_mat(mat: Material) -> bool:
	return mat != null and mat.resource_path == FACE_MAT


## Every face surface under `n` (n included): [[MeshInstance3D, surface index], ...]. visible_only skips hidden nodes.
static func face_surfaces(n: Node, visible_only: bool = false) -> Array:
	var out: Array = []
	var nodes: Array = n.find_children("*", "MeshInstance3D", true, false)
	if n is MeshInstance3D:
		nodes.push_front(n)
	for g: Node in nodes:
		var mi := g as MeshInstance3D
		if mi.mesh == null or (visible_only and not mi.is_visible_in_tree()):
			continue
		for s: int in mi.mesh.get_surface_count():
			if is_face_mat(mi.mesh.surface_get_material(s)):
				out.append([mi, s])
	return out


## Glowing face vertices under `n`: {"count": int, "color": mean sRGB colour of the most glowing ones (alpha within
## 0.1 of the lowest: the iris cores), "min_alpha": float}.
static func glow(n: Node, visible_only: bool = false) -> Dictionary:
	var cols: Array[Color] = []
	var lo := 1.0
	for fs: Array in face_surfaces(n, visible_only):
		var mi: MeshInstance3D = fs[0]
		var arr: Variant = mi.mesh.surface_get_arrays(int(fs[1]))[Mesh.ARRAY_COLOR]
		if not (arr is PackedColorArray):
			continue
		for c: Color in (arr as PackedColorArray):
			if c.a <= GLOW_ALPHA:
				cols.append(c)
				lo = minf(lo, c.a)
	var sum := Color(0, 0, 0, 0)
	var k := 0
	for c: Color in cols:
		if c.a <= lo + 0.1:
			sum += c
			k += 1
	var mean := Color(sum.r / k, sum.g / k, sum.b / k) if k > 0 else Color(0, 0, 0)
	return {"count": cols.size(), "color": mean, "min_alpha": lo}


## True when the faces under `n` have a glow point (glowing irises / mouth).
static func glows(n: Node, visible_only: bool = false) -> bool:
	return int(glow(n, visible_only)["count"]) > 0


## glow_boost of a node, the shader default (1.0) while nothing wrote it (get_instance_shader_parameter = null).
static func boost(gi: GeometryInstance3D) -> float:
	if gi == null:
		return 0.0
	var v: Variant = gi.get_instance_shader_parameter(&"glow_boost")
	return 1.0 if v == null else float(v)
