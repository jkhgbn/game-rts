extends SceneTree
## forge_evenmead hosts (set-only tech-art tool): the four armies of the Battle of Evenmead as REAL unit models (their
## own scenes, idle-posed at staggered frames so no two soldiers breathe alike), feet on this set's terrain, merged
## into one mesh per host (painted parts -> vertex colours on one lit material, glowing parts -> one unshaded glow
## surface, special shaders kept as their own surface). Formations: em_layout.gd ARMIES. Same merge as
## forge_intro_vessa/tools/intro_bake.gd (read-only reference), rewritten here so this set owns its tool.
## Output: parts/army_<kingdom>.tscn (+ .res). The set loads them as puppets army_shadow / army_ice / army_nature / army_fire.
## Run: tools\godot_run.ps1 --headless --path . -s res://art/cinematics/stage_sets/forge_evenmead/tools/bake_armies.gd
##          --fixed-fps 30 --quit-after 30000 '--' [only=shadow,ice]

const FSet := preload("res://tools/world_forge/forge_set.gd")
const L := preload("res://art/cinematics/stage_sets/forge_evenmead/tools/em_layout.gd")
const SPEC := "res://art/cinematics/stage_sets/forge_evenmead/forge_evenmead.set"
const DIR := "res://art/cinematics/stage_sets/forge_evenmead/parts"
const SH_GLOW := DIR + "/materials/em_army_glow.gdshader"
const FRAMES := 64

var T
var only: PackedStringArray = PackedStringArray(["shadow", "ice", "nature", "fire"])
var _paint: StandardMaterial3D
var _glow: ShaderMaterial


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("only="):
			only = a.substr(5).split(",")
	_run.call_deferred()


func gh(x: float, z: float) -> float:
	var fx := clampf((x - T.x0) / T.step, 0.0, T.nx - 1.001)
	var fz := clampf((z - T.z0) / T.step, 0.0, T.nz - 1.001)
	var i := int(fx)
	var j := int(fz)
	var tx := fx - i
	var tz := fz - j
	var a: float = T.h[j * T.nx + i]
	var b: float = T.h[j * T.nx + i + 1]
	var d: float = T.h[(j + 1) * T.nx + i]
	var e: float = T.h[(j + 1) * T.nx + i + 1]
	if tx >= tz:
		return a + (b - a) * tx + (e - b) * tz
	return a + (d - a) * tz + (e - d) * tx


func _run() -> void:
	var fs := FSet.new()
	fs.compile(SPEC)
	T = fs.terrain
	await process_frame
	_paint = StandardMaterial3D.new()
	_paint.vertex_color_use_as_albedo = true
	_paint.vertex_color_is_srgb = true
	_paint.roughness = 0.8
	_paint.rim_enabled = true
	_paint.rim = 0.3
	_paint.rim_tint = 0.4
	ResourceSaver.save(_paint, DIR + "/materials/em_army_paint.tres")
	_paint = load(DIR + "/materials/em_army_paint.tres")
	_glow = ShaderMaterial.new()
	_glow.shader = load(SH_GLOW)
	ResourceSaver.save(_glow, DIR + "/materials/em_army_glow.tres")
	_glow = load(DIR + "/materials/em_army_glow.tres")
	for army: String in only:
		print("BAKE start ", army)
		await _bake(army)
	print("ARMIES done")
	quit(0)


func _bake(army: String) -> void:
	var holder := Node3D.new()
	holder.name = "Bake"
	root.add_child(holder)
	var list: Array = []
	for u: Dictionary in L.units_of(army):
		var ps := load(u["scene"]) as PackedScene
		if ps == null:
			push_warning("bake_armies: missing " + String(u["scene"]))
			continue
		var n := ps.instantiate() as Node3D
		var p: Vector2 = u["pos"]
		# feet on the lowest ground under the footprint (no hovering on slopes)
		var y := minf(gh(p.x, p.y), minf(gh(p.x + 0.3, p.y), minf(gh(p.x - 0.3, p.y), minf(gh(p.x, p.y + 0.3), gh(p.x, p.y - 0.3)))))
		n.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(float(u["yaw"]))).scaled(Vector3.ONE * float(u["scale"])), Vector3(p.x, y - 0.02, p.y))
		holder.add_child(n)
		list.append([n, u])
	for k in 3:
		await process_frame
	# let the idle animations run (each model starts its own idle phase)
	for fr in 48:
		await process_frame
	var bk := {"paint": _Bucket.new(), "glow": _Bucket.new()}
	var keep := {}
	var idx := 0
	for pr: Array in list:
		idx += 1
		_collect(pr[0], holder, bk, keep, float(idx % 17) / 17.0)
	var mesh := ArrayMesh.new()
	var tris := 0
	tris += (bk["paint"] as _Bucket).commit(mesh, _paint)
	tris += (bk["glow"] as _Bucket).commit(mesh, _glow)
	for key in keep:
		var b: _Bucket = keep[key]
		tris += b.commit(mesh, b.mat)
	var mp := DIR + "/army_%s.res" % army
	ResourceSaver.save(mesh, mp, ResourceSaver.FLAG_COMPRESS)
	mesh.take_over_path(mp)
	var sroot := Node3D.new()
	sroot.name = "Army_%s" % army
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = mesh
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	sroot.add_child(mi)
	mi.owner = sroot
	var ps2 := PackedScene.new()
	ps2.pack(sroot)
	ResourceSaver.save(ps2, DIR + "/army_%s.tscn" % army)
	print("ARMY %s units %d surfaces %d tris %d kept %d" % [army, list.size(), mesh.get_surface_count(), tris, keep.size()])
	sroot.free()
	holder.queue_free()
	await process_frame


class _Bucket:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var uv := PackedVector2Array()
	var idx := PackedInt32Array()
	var mat: Material

	func add(mesh: Mesh, s: int, xf: Transform3D, col: Variant) -> void:
		if mesh is ArrayMesh and (mesh as ArrayMesh).surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:
			return
		var arr := mesh.surface_get_arrays(s)
		if arr.is_empty():
			return
		var sv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		if sv.is_empty():
			return
		var sn: Variant = arr[Mesh.ARRAY_NORMAL]
		var sc: Variant = arr[Mesh.ARRAY_COLOR]
		var suv: Variant = arr[Mesh.ARRAY_TEX_UV]
		var base := v.size()
		var nb := xf.basis.inverse().transposed()
		var flip := xf.basis.determinant() < 0.0
		for i in sv.size():
			v.append(xf * sv[i])
			n.append((nb * (sn[i] as Vector3)).normalized() if sn is PackedVector3Array and (sn as PackedVector3Array).size() > i else Vector3.UP)
			if col is Color:
				c.append(col)
			else:
				c.append(sc[i] if sc is PackedColorArray and (sc as PackedColorArray).size() > i else Color.WHITE)
			uv.append(suv[i] if suv is PackedVector2Array and (suv as PackedVector2Array).size() > i else Vector2.ZERO)
		var si: Variant = arr[Mesh.ARRAY_INDEX]
		if si is PackedInt32Array and not (si as PackedInt32Array).is_empty():
			var ii: PackedInt32Array = si
			for k in range(0, ii.size(), 3):
				if flip:
					idx.append_array([base + ii[k], base + ii[k + 2], base + ii[k + 1]])
				else:
					idx.append_array([base + ii[k], base + ii[k + 1], base + ii[k + 2]])
		else:
			for k in range(0, sv.size(), 3):
				if flip:
					idx.append_array([base + k, base + k + 2, base + k + 1])
				else:
					idx.append_array([base + k, base + k + 1, base + k + 2])

	func commit(mesh: ArrayMesh, m: Material) -> int:
		if v.is_empty():
			return 0
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = v
		arr[Mesh.ARRAY_NORMAL] = n
		arr[Mesh.ARRAY_COLOR] = c
		arr[Mesh.ARRAY_TEX_UV] = uv
		arr[Mesh.ARRAY_INDEX] = idx
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		mesh.surface_set_material(mesh.get_surface_count() - 1, m)
		return idx.size() / 3


func _collect(n: Node, holder: Node3D, bk: Dictionary, keep: Dictionary, phase: float) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh and mi.is_visible_in_tree():
			var xf := holder.global_transform.affine_inverse() * mi.global_transform
			for s in mi.mesh.get_surface_count():
				var mat := mi.get_active_material(s)
				var cl := _classify(mat)
				match cl[0]:
					"paint":
						(bk["paint"] as _Bucket).add(mi.mesh, s, xf, Color(cl[1].r, cl[1].g, cl[1].b, 1.0))
					"glow":
						(bk["glow"] as _Bucket).add(mi.mesh, s, xf, Color(cl[1].r, cl[1].g, cl[1].b, phase))
					"keep":
						var key := str(mat.get_instance_id())
						if not keep.has(key):
							var b := _Bucket.new()
							b.mat = mat
							keep[key] = b
						(keep[key] as _Bucket).add(mi.mesh, s, xf, null)
	for c in n.get_children():
		_collect(c, holder, bk, keep, phase)


static func _param(mat: ShaderMaterial, name: String) -> Variant:
	var v: Variant = mat.get_shader_parameter(name)
	if v == null and mat.shader:
		v = RenderingServer.shader_get_parameter_default(mat.shader.get_rid(), name)
	if v is Vector3:
		return Color(v.x, v.y, v.z)
	if v is Vector4:
		return Color(v.x, v.y, v.z, v.w)
	return v


static func _classify(mat: Material) -> Array:
	if mat == null:
		return ["paint", Color(0.5, 0.5, 0.5)]
	if mat is ShaderMaterial:
		var sm := mat as ShaderMaterial
		var path := sm.shader.resource_path if sm.shader else ""
		if path.get_file().contains("blob"):
			return ["skip", null]
		var g: Variant = _param(sm, "glow_color")
		if g is Color:
			return ["glow", g]
		for k in ["base_color", "albedo", "albedo_color", "color", "tint", "body_color"]:
			var b: Variant = _param(sm, k)
			if b is Color:
				return ["paint", b]
		return ["keep", null]
	if mat is BaseMaterial3D:
		var bm := mat as BaseMaterial3D
		if bm.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or bm.blend_mode != BaseMaterial3D.BLEND_MODE_MIX:
			return ["skip", null]
		if bm.emission_enabled and bm.emission.get_luminance() > 0.05:
			return ["glow", bm.emission]
		if bm.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
			return ["glow", bm.albedo_color]
		return ["paint", bm.albedo_color]
	return ["keep", null]
