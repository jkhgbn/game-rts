class_name ArtLabCensus
extends RefCounted
## Art Lab (docs/plan/art-lab.md): counts what a model scene draws (budgets) and measures it (exact vertex bounds).
## Works headless (no rendering needed), so tests/test_art_lab.gd runs it too.

static var _mesh_cache: Dictionary = {}   # mesh instance id -> Vector2i(verts, tris)


static func clear_cache() -> void:
	_mesh_cache.clear()
	_face_cache.clear()


static func geometry(root: Node) -> Array[GeometryInstance3D]:
	var out: Array[GeometryInstance3D] = []
	if root is GeometryInstance3D:
		out.append(root as GeometryInstance3D)
	for n: Node in root.find_children("*", "GeometryInstance3D", true, false):
		out.append(n as GeometryInstance3D)
	return out


static func is_particles(n: Node) -> bool:
	return n is GPUParticles3D or n is CPUParticles3D


## True for a flat, ground-level part (shadow blob, contact decal, ground ring): hidden in silhouettes, ignored by the
## feet / height measures. `ground_y` = world y of the ground under the model.
static func is_flat_decal(gi: GeometryInstance3D, ground_y: float) -> bool:
	if is_particles(gi):
		return false
	var box := gi.global_transform * gi.get_aabb()
	return box.size.y < 0.08 and box.position.y < ground_y + 0.25


## Vertex / triangle count of a mesh (cached).
static func mesh_stats(mesh: Mesh) -> Vector2i:
	if mesh == null:
		return Vector2i.ZERO
	var id := mesh.get_instance_id()
	if _mesh_cache.has(id):
		return _mesh_cache[id]
	var v := 0
	var t := 0
	for s: int in mesh.get_surface_count():
		var arr := mesh.surface_get_arrays(s)
		if arr.is_empty():
			continue
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var nv := verts.size()
		v += nv
		var idx: Variant = arr[Mesh.ARRAY_INDEX]
		if idx is PackedInt32Array and (idx as PackedInt32Array).size() > 0:
			t += (idx as PackedInt32Array).size() / 3
		else:
			t += nv / 3
	var r := Vector2i(v, t)
	_mesh_cache[id] = r
	return r


## Face kit material (art/units/kit/face/): every unit's face (eyes, lips, ears, hair) is a surface drawn with it, on
## its own FaceRig node or appended inside a merged pivot mesh (CreatureFaceRig host mode).
const FACE_MAT := "res://art/units/kit/face/unit_face.tres"
static var _face_cache: Dictionary = {}   # mesh instance id -> face vertices


## Vertices of `mesh` on face-kit surfaces (cached per mesh).
static func face_verts(mesh: Mesh) -> int:
	if mesh == null:
		return 0
	var id := mesh.get_instance_id()
	if _face_cache.has(id):
		return int(_face_cache[id])
	var v := 0
	for s: int in mesh.get_surface_count():
		var m := mesh.surface_get_material(s)
		if m != null and m.resource_path == FACE_MAT:
			v += mesh.surface_get_array_len(s)
	_face_cache[id] = v
	return v


## Triangles of `mesh` whose face points down (world normal y < -0.7 through `basis`; a sphere has ~15 %): the RTS camera (pitch 55, from
## above) never sees them, so a big share is wasted geometry (closed-off undersides, caps under feet / plinths).
static func down_tris(mesh: Mesh, basis: Basis) -> int:
	if mesh == null:
		return 0
	var n := 0
	for s: int in mesh.get_surface_count():
		if mesh is ArrayMesh and (mesh as ArrayMesh).surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:
			continue
		var arr := mesh.surface_get_arrays(s)
		if arr.is_empty():
			continue
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var idx: Variant = arr[Mesh.ARRAY_INDEX]
		var ids := PackedInt32Array()
		if idx is PackedInt32Array and (idx as PackedInt32Array).size() > 0:
			ids = idx
		else:
			ids.resize(v.size() - v.size() % 3)
			for i: int in ids.size():
				ids[i] = i
		for t: int in range(0, ids.size() - 2, 3):
			var a := basis * v[ids[t]]
			var b := basis * v[ids[t + 1]]
			var c := basis * v[ids[t + 2]]
			# Godot front faces wind clockwise: the outward normal is (c - a) x (b - a)
			var nrm := (c - a).cross(b - a)
			var l := nrm.length()
			if l > 1e-9 and nrm.y / l < -0.7:
				n += 1
	return n


## True for a thin "line" part (spear shaft, staff, bow string: two of its three sizes < `thin` m).
static func is_line_part(size: Vector3, thin: float = 0.08) -> bool:
	var s := [size.x, size.y, size.z]
	s.sort()
	return float(s[1]) < thin


## Materials a geometry instance really draws with (override wins over the surfaces).
static func materials_of(gi: GeometryInstance3D) -> Array[Material]:
	var out: Array[Material] = []
	if gi.material_overlay:
		out.append(gi.material_overlay)
	if gi.material_override:
		out.append(gi.material_override)
		if not is_particles(gi):
			return out
	if gi is MeshInstance3D:
		var mi := gi as MeshInstance3D
		if mi.mesh:
			for s: int in mi.mesh.get_surface_count():
				var m: Material = mi.get_surface_override_material(s)
				if m == null:
					m = mi.mesh.surface_get_material(s)
				if m:
					out.append(m)
	elif gi is MultiMeshInstance3D:
		var mm := (gi as MultiMeshInstance3D).multimesh
		if mm and mm.mesh:
			for s: int in mm.mesh.get_surface_count():
				var m2 := mm.mesh.surface_get_material(s)
				if m2:
					out.append(m2)
	elif gi is GPUParticles3D:
		var gp := gi as GPUParticles3D
		if gp.process_material:
			out.append(gp.process_material)
		for i: int in gp.draw_passes:
			var dm: Mesh = gp.get_draw_pass_mesh(i)
			if dm:
				for s: int in dm.get_surface_count():
					var m3 := dm.surface_get_material(s)
					if m3:
						out.append(m3)
	elif gi is CPUParticles3D:
		var cp := gi as CPUParticles3D
		if cp.mesh:
			for s: int in cp.mesh.get_surface_count():
				var m4 := cp.mesh.surface_get_material(s)
				if m4:
					out.append(m4)
	return out


static func meshes_of(gi: GeometryInstance3D) -> Array[Mesh]:
	var out: Array[Mesh] = []
	if gi is MeshInstance3D and (gi as MeshInstance3D).mesh:
		out.append((gi as MeshInstance3D).mesh)
	elif gi is MultiMeshInstance3D and (gi as MultiMeshInstance3D).multimesh and (gi as MultiMeshInstance3D).multimesh.mesh:
		out.append((gi as MultiMeshInstance3D).multimesh.mesh)
	return out


static func _mm_count(mm: MultiMesh) -> int:
	if mm == null:
		return 0
	return mm.visible_instance_count if mm.visible_instance_count >= 0 else mm.instance_count


## Everything the budgets need, at rest. `ground_y` = world y of the ground (for the flat-decal test).
static func census(root: Node3D, ground_y: float = 0.0) -> Dictionary:
	var c := {
		"meshes": 0, "multimeshes": 0, "hidden_parts": 0, "draw": 0, "separate": 0, "verts": 0, "tris": 0,
		"lights": 0, "systems": 0, "looping": 0, "oneshots": 0, "particles": 0, "casters": 0, "materials": 0,
		"code_materials": 0, "decals": 0, "nodes": 0, "shader_names": [], "light_names": [], "caster_names": [],
		"looping_names": [], "surfaces": 0, "down_tris": 0, "mesh_list": [], "face_verts": 0,
	}
	var mats := {}
	var shaders := {}
	for gi: GeometryInstance3D in geometry(root):
		for m: Material in materials_of(gi):
			if m is ParticleProcessMaterial:
				continue   # simulation settings, not a draw material (art-keep 9 counts the particle draw materials)
			mats[m.get_instance_id()] = m
			if m is ShaderMaterial and (m as ShaderMaterial).shader:
				shaders[(m as ShaderMaterial).shader.resource_path.get_file()] = true
		if not gi.is_visible_in_tree():
			c["hidden_parts"] += 1
			continue
		if is_particles(gi):
			c["systems"] += 1
			var one_shot: bool = gi.get("one_shot")
			var emitting: bool = gi.get("emitting")
			if one_shot:
				c["oneshots"] += 1
			elif emitting:
				c["looping"] += 1
				c["particles"] += int(gi.get("amount"))
				(c["looping_names"] as Array).append(String(gi.name))
			if emitting:
				c["draw"] += 1
			continue
		var has_content := true
		if gi is MeshInstance3D:
			var mi := gi as MeshInstance3D
			has_content = mi.mesh != null
			if has_content:
				c["meshes"] += 1
				var st := mesh_stats(mi.mesh)
				c["verts"] += st.x
				c["tris"] += st.y
				c["face_verts"] += face_verts(mi.mesh)   # face kit surfaces (B4 face allowance, lab_budgets.gd)
				c["surfaces"] += mi.mesh.get_surface_count()
				var dn := down_tris(mi.mesh, gi.global_basis)
				c["down_tris"] += dn
				(c["mesh_list"] as Array).append({"name": String(root.get_path_to(gi)), "verts": st.x, "tris": st.y,
					"surfaces": mi.mesh.get_surface_count(), "down": dn, "n": 1})
		elif gi is MultiMeshInstance3D:
			var mm := (gi as MultiMeshInstance3D).multimesh
			var n := _mm_count(mm)
			has_content = n > 0 and mm.mesh != null
			if has_content:
				c["multimeshes"] += 1
				var st2 := mesh_stats(mm.mesh)
				c["verts"] += st2.x * n
				c["tris"] += st2.y * n
				c["surfaces"] += mm.mesh.get_surface_count()
				(c["mesh_list"] as Array).append({"name": String(root.get_path_to(gi)), "verts": st2.x * n,
					"tris": st2.y * n, "surfaces": mm.mesh.get_surface_count(), "down": 0, "n": n})
		if not has_content:
			continue
		c["draw"] += 1
		if gi.has_meta(&"keep_separate"):
			c["separate"] += 1
		if gi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and not is_flat_decal(gi, ground_y):
			c["casters"] += 1
			(c["caster_names"] as Array).append(String(gi.name))
	for n2: Node in root.find_children("*", "Light3D", true, false):
		if (n2 as Light3D).is_visible_in_tree():
			c["lights"] += 1
			(c["light_names"] as Array).append(String(n2.name))
	for n3: Node in root.find_children("*", "Decal", true, false):
		if (n3 as Decal).is_visible_in_tree():
			c["decals"] += 1
			c["draw"] += 1
	(c["mesh_list"] as Array).sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["verts"]) > int(b["verts"]))
	c["materials"] = mats.size()
	for id: int in mats:
		if (mats[id] as Material).resource_path == "":
			c["code_materials"] += 1
	c["shader_names"] = shaders.keys()
	c["nodes"] = root.find_children("*", "", true, false).size() + 1
	return c


## Resource ids (materials and meshes) a subtree draws with, for the "per instance" check.
static func resource_ids(root: Node) -> Dictionary:
	var out := {"materials": {}, "meshes": {}}
	for gi: GeometryInstance3D in geometry(root):
		for m: Material in materials_of(gi):
			out["materials"][m.get_instance_id()] = m.resource_path
		for me: Mesh in meshes_of(gi):
			out["meshes"][me.get_instance_id()] = me.resource_path
	return out


## Exact bounds of the drawn vertices at rest, in the space of `frame` (the model's holder: feet origin, y up).
## Flat decals and particles are skipped. Returns {min: Vector3, max: Vector3, top_parts: [{name, width, top}]} where
## top_parts lists every part with vertices above `above_y` and the width of that part above it.
static func vertex_bounds(root: Node3D, frame: Transform3D, ground_y: float, above_y: float = INF) -> Dictionary:
	var lo := Vector3(INF, INF, INF)
	var hi := Vector3(-INF, -INF, -INF)
	var inv := frame.affine_inverse()
	var tops: Array[Dictionary] = []
	var lo_t := Vector3(INF, INF, INF)   # without thin "line" parts (spear shafts, staffs): the R10 footprint
	var hi_t := Vector3(-INF, -INF, -INF)
	var lines: Array[String] = []
	for gi: GeometryInstance3D in geometry(root):
		if not gi.is_visible_in_tree() or is_particles(gi) or is_flat_decal(gi, ground_y):
			continue
		var xfs: Array[Transform3D] = []
		var mesh: Mesh = null
		if gi is MeshInstance3D:
			mesh = (gi as MeshInstance3D).mesh
			xfs.append(inv * gi.global_transform)
		elif gi is MultiMeshInstance3D:
			var mm := (gi as MultiMeshInstance3D).multimesh
			if mm == null or mm.mesh == null:
				continue
			mesh = mm.mesh
			var n := _mm_count(mm)
			if n > 256:   # big scatter: its AABB is good enough
				var box := inv * gi.global_transform * gi.get_aabb()
				lo = lo.min(box.position)
				hi = hi.max(box.end)
				continue
			for i: int in n:
				xfs.append(inv * gi.global_transform * mm.get_instance_transform(i))
		if mesh == null:
			continue
		var pmin := Vector2(INF, INF)
		var pmax := Vector2(-INF, -INF)
		var ptop := -INF
		var plo := Vector3(INF, INF, INF)
		var phi := Vector3(-INF, -INF, -INF)
		for s: int in mesh.get_surface_count():
			var arr := mesh.surface_get_arrays(s)
			if arr.is_empty():
				continue
			var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			for xf: Transform3D in xfs:
				for v: Vector3 in verts:
					var p := xf * v
					plo = plo.min(p)
					phi = phi.max(p)
					if p.y > above_y:
						pmin = pmin.min(Vector2(p.x, p.z))
						pmax = pmax.max(Vector2(p.x, p.z))
						ptop = maxf(ptop, p.y)
		if plo.x < INF:
			lo = lo.min(plo)
			hi = hi.max(phi)
			if is_line_part(phi - plo):
				lines.append(String(gi.name))
			else:
				lo_t = lo_t.min(plo)
				hi_t = hi_t.max(phi)
		if ptop > -INF:
			tops.append({"name": String(root.get_path_to(gi)), "width": maxf(pmax.x - pmin.x, pmax.y - pmin.y), "top": ptop})
	if lo.x == INF:
		lo = Vector3.ZERO
		hi = Vector3.ZERO
	if lo_t.x == INF:
		lo_t = lo
		hi_t = hi
	return {"min": lo, "max": hi, "top_parts": tops, "min_thick": lo_t, "max_thick": hi_t, "line_parts": lines}


## World AABB of the drawn, non-flat geometry (for cameras and ROIs).
static func world_aabb(root: Node3D, ground_y: float) -> AABB:
	var box := AABB()
	var first := true
	for gi: GeometryInstance3D in geometry(root):
		if not gi.is_visible_in_tree() or is_particles(gi) or is_flat_decal(gi, ground_y):
			continue
		if gi is MeshInstance3D and (gi as MeshInstance3D).mesh == null:
			continue
		var b := gi.global_transform * gi.get_aabb()
		if first:
			box = b
			first = false
		else:
			box = box.merge(b)
	if first:
		return AABB(root.global_position - Vector3(0.5, 0.0, 0.5), Vector3(1.0, 1.0, 1.0))
	return box


## Hooks a kind is expected to expose (art-units 6.1, cavalry-mounts 10, map-fill 10, art-keep 8.8).
static func expected_hooks(kind: StringName) -> Array[String]:
	match kind:
		&"unit":
			return ["set_team_color", "set_moving", "play_attack", "play_hit", "play_death", "signal:death_finished"]
		&"mount":
			return ["set_team_color", "set_moving", "play_hit", "play_death", "signal:death_finished", "set_barded",
				"play_charge", "seat_transform"]
		&"titan":
			return ["set_team_color", "set_moving", "play_attack", "play_hit", "play_death", "signal:death_finished"]
		&"beast":
			return ["set_moving", "play_attack", "play_hit", "play_death", "signal:death_finished", "set_variant", "play_cast"]
		&"critter":
			return ["play_idle", "play_move", "play_flee", "play_hit", "play_death"]
		&"building":
			return ["set_team_color", "set_selected", "set_construction_progress", "set_health_ratio", "play_destroyed"]
	return []


static func has_hook(n: Object, hook: String) -> bool:
	if hook.begins_with("signal:"):
		return n.has_signal(StringName(hook.substr(7)))
	return n.has_method(StringName(hook))
