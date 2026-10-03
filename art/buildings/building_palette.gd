class_name BuildingPalette
extends RefCounted
## B8 material merge for the building models that paint with their own `*_painted.gdshader` (in-game grade
## 2026-09-30: Magpie Den, Greywater Lodge, tavern). Those shaders have a PALETTE mode (uniform `palette` + the pal_*
## arrays, see magpie_den_painted.gdshader): ONE palette material per building instance draws every painted part and
## every plain rune_glow part; the part meshes are copied once with UV.x = the palette index of their material.
## The building keeps creating its per-instance source materials exactly as before (and keeps changing them: selection
## rim, glow boost, open / closed lamps); they are just not drawn any more: call `refresh(pal)` after changing them and
## the palette re-reads every source (values, rim, glow energy x boost).
## Use (per instance, before the merged meshes are built):
##     var pal := BuildingPalette.create(PAINTED, some_painted_source)
##     items = BuildingPalette.fold_items(pal, items)          # BuildingMerge items [mesh, xf, material]
##     BuildingPalette.fold_instance(pal, mi)                  # a separate part (after its materials are set)
## Indices follow the order in which sources are first folded (deterministic build code = the same on every
## instance), so the folded meshes are cached per (mesh, index) and shared by all instances (B9).

const GLOW_PATH := "res://art/shaders/rune_glow.gdshader"
const PAL_MAX := 24
const PAINTED_KEYS: Array[StringName] = [&"base_color", &"spec_strength", &"moss_color", &"moss_top", &"patch_color",
	&"moss_foot", &"moss_cut", &"pattern", &"course_height", &"block_length"]

static var _meshes: Dictionary = {}   # "mesh id|override id or index map" -> Mesh


## A palette material for `shader` (a building painted shader with the palette mode); shared uniforms (noise, noise
## scales, rim) are copied from `template`.
static func create(shader: Shader, template: ShaderMaterial) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader
	for p: StringName in [&"noise_tex", &"noise_scale_a", &"noise_scale_b", &"rim_color", &"rim_strength"]:
		var v: Variant = template.get_shader_parameter(p) if template else null
		if v != null:
			m.set_shader_parameter(p, v)
	m.set_shader_parameter(&"palette", true)
	m.set_meta(&"pal_srcs", [])
	m.set_meta(&"pal_ids", {})
	return m


## True when `src` can be drawn by `pal`: a material of the palette's own shader, or a plain rune_glow (no bands).
static func foldable(pal: ShaderMaterial, src: Material) -> bool:
	if not src is ShaderMaterial or (src as ShaderMaterial).shader == null:
		return false
	var sh := (src as ShaderMaterial).shader
	if sh == pal.shader:
		return true
	if sh.resource_path == GLOW_PATH:
		var bands: Variant = (src as ShaderMaterial).get_shader_parameter(&"rune_bands")
		return bands == null or int(bands) <= 0
	return false


## Palette index of `src` (added on first use; -1 when full or not foldable).
static func index_of(pal: ShaderMaterial, src: Material) -> int:
	var ids: Dictionary = pal.get_meta(&"pal_ids")
	var id := src.get_instance_id()
	if ids.has(id):
		return int(ids[id])
	var srcs: Array = pal.get_meta(&"pal_srcs")
	if srcs.size() >= PAL_MAX or not foldable(pal, src):
		return -1
	srcs.append(src)
	ids[id] = srcs.size() - 1
	refresh(pal)
	return srcs.size() - 1


## Re-reads every source material into the palette arrays (+ the rim of the first painted source). Only changed values
## are uploaded, so the per-new-source refresh of index_of while a building is folded stays cheap.
static func refresh(pal: ShaderMaterial) -> void:
	var srcs: Array = pal.get_meta(&"pal_srcs")
	var a := PackedVector4Array()
	var b := PackedVector4Array()
	var c := PackedVector4Array()
	var d := PackedVector4Array()
	var e := PackedVector4Array()
	for arr: PackedVector4Array in [a, b, c, d, e]:
		arr.resize(PAL_MAX)
	var rim_done := false
	for i: int in srcs.size():
		var sm := srcs[i] as ShaderMaterial
		if sm.shader.resource_path == GLOW_PATH:
			var gc: Color = _p(sm, &"glow_color", Color(1.0, 0.55, 0.15))
			var lg := gc.srgb_to_linear()
			a[i] = Vector4(lg.r, lg.g, lg.b, 0.0)
			e[i] = Vector4(maxf(0.001, float(_p(sm, &"energy", 3.0)) * float(_p(sm, &"boost", 1.0))),
				float(_p(sm, &"pulse_speed", 2.0)), float(_p(sm, &"phase", 0.0)), 0.0)
			continue
		var bc: Color = (_p(sm, &"base_color", Color(0.42, 0.42, 0.4)) as Color).srgb_to_linear()
		var mc: Color = (_p(sm, &"moss_color", Color(0.3, 0.4, 0.17)) as Color).srgb_to_linear()
		var pc: Color = (_p(sm, &"patch_color", Color(0.45, 0.35, 0.24)) as Color).srgb_to_linear()
		a[i] = Vector4(bc.r, bc.g, bc.b, float(_p(sm, &"spec_strength", 0.0)))
		b[i] = Vector4(mc.r, mc.g, mc.b, float(_p(sm, &"moss_top", 0.0)))
		c[i] = Vector4(pc.r, pc.g, pc.b, float(_p(sm, &"moss_foot", 0.0)))
		d[i] = Vector4(float(_p(sm, &"moss_cut", 0.5)), float(_p(sm, &"pattern", 0)), float(_p(sm, &"course_height", 0.4)),
			float(_p(sm, &"block_length", 0.7)))
		if not rim_done:
			rim_done = true
			for rp: StringName in [&"rim_color", &"rim_strength"]:
				var rv: Variant = sm.get_shader_parameter(rp)
				if rv != null:
					MatSync.put(pal, rp, rv)
	# uploads only what changed (a selection rim fade changes the rim, not the 5 arrays)
	MatSync.put(pal, &"pal_a", a)
	MatSync.put(pal, &"pal_b", b)
	MatSync.put(pal, &"pal_c", c)
	MatSync.put(pal, &"pal_d", d)
	MatSync.put(pal, &"pal_e", e)


## A material parameter, else the shader's own default, else `fallback`.
static func _p(sm: ShaderMaterial, name: StringName, fallback: Variant) -> Variant:
	var v: Variant = MatSync.param(sm, name)   # value, else the shader's cached default
	if v == null:
		return fallback
	if v is Vector3 and fallback is Color:
		return Color(v.x, v.y, v.z)
	return v


## BuildingMerge items [mesh, xf, material] with every foldable material replaced by `pal` (the mesh copied with
## UV.x = the index). Other items unchanged.
static func fold_items(pal: ShaderMaterial, items: Array) -> Array:
	var out: Array = []
	for it: Array in items:
		var i := index_of(pal, it[2]) if it[2] != null else -1
		if i < 0:
			out.append(it)
		else:
			out.append([_uv_mesh(it[0], [i]), it[1], pal])
	return out


## Folds a separate MeshInstance3D (its override, else its surface overrides / mesh surface materials): the mesh is
## swapped for the cached UV copy and every foldable surface draws with `pal` (surface override, per instance).
static func fold_instance(pal: ShaderMaterial, mi: MeshInstance3D) -> void:
	if mi == null or mi.mesh == null:
		return
	var mesh := mi.mesh
	var idx: Array = []
	var srcs: Array = []
	for s: int in mesh.get_surface_count():
		var src: Material = mi.material_override
		if src == null:
			src = mi.get_surface_override_material(s)
		if src == null:
			src = mesh.surface_get_material(s)
		srcs.append(src)
		idx.append(index_of(pal, src) if src else -1)
	if idx.max() < 0:
		return
	var ov := mi.material_override
	mi.material_override = null
	mi.mesh = _uv_mesh(mesh, idx)
	for s2: int in idx.size():
		mi.set_surface_override_material(s2, pal if int(idx[s2]) >= 0 else srcs[s2])
	if ov and idx.min() >= 0:
		mi.material_override = pal


## Folds every MeshInstance3D / MultiMeshInstance3D under `root` (skipping `skip` nodes and their children).
## Returns the number of nodes that now draw with `pal`.
static func fold_tree(pal: ShaderMaterial, root: Node, skip: Array = []) -> int:
	var n := 0
	for c: Node in root.get_children():
		if c in skip:
			continue
		if c is MeshInstance3D:
			fold_instance(pal, c as MeshInstance3D)
		elif c is MultiMeshInstance3D:
			fold_multimesh(pal, c as MultiMeshInstance3D)
		if c is GeometryInstance3D and _draws_with(c as GeometryInstance3D, pal):
			n += 1
		n += fold_tree(pal, c, skip)
	return n


static func _draws_with(gi: GeometryInstance3D, pal: ShaderMaterial) -> bool:
	if gi.material_override == pal:
		return true
	if gi is MeshInstance3D and (gi as MeshInstance3D).mesh:
		for s: int in (gi as MeshInstance3D).mesh.get_surface_count():
			if (gi as MeshInstance3D).get_surface_override_material(s) == pal:
				return true
	return false


## A MultiMeshInstance3D drawn with one foldable override: its multimesh gets the UV copy of the mesh.
static func fold_multimesh(pal: ShaderMaterial, mmi: MultiMeshInstance3D) -> void:
	if mmi == null or mmi.multimesh == null or mmi.multimesh.mesh == null or mmi.material_override == null:
		return
	var i := index_of(pal, mmi.material_override)
	if i < 0:
		return
	mmi.multimesh.mesh = _uv_mesh(mmi.multimesh.mesh, [i])
	mmi.material_override = pal


## A copy of `mesh` whose surface s has UV.x = idx[s] (idx[s] < 0: that surface untouched; one index = all surfaces).
## Cached per mesh + indices (shared by every instance).
static func _uv_mesh(mesh: Mesh, idx: Array) -> Mesh:
	var key := "%d|%s" % [mesh.get_instance_id(), str(idx)]
	if _meshes.has(key):
		return _meshes[key]
	var am := ArrayMesh.new()
	for s: int in mesh.get_surface_count():
		var i: int = int(idx[s] if s < idx.size() else idx[0])
		var arr := mesh.surface_get_arrays(s)
		if i >= 0:
			var n: int = (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			var uv := PackedVector2Array()
			uv.resize(n)
			uv.fill(Vector2(float(i), 0.0))
			arr[Mesh.ARRAY_TEX_UV] = uv
		# a PrimitiveMesh (BoxMesh...) has no surface_get_primitive_type: its surfaces are triangles
		var prim: Mesh.PrimitiveType = (mesh as ArrayMesh).surface_get_primitive_type(s) if mesh is ArrayMesh else Mesh.PRIMITIVE_TRIANGLES
		am.add_surface_from_arrays(prim, arr, [], {}, MeshBake.custom_flags(mesh, s))
		am.surface_set_material(s, mesh.surface_get_material(s))
	_meshes[key] = am
	return am
