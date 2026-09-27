class_name FlockKinds
extends RefCounted
## Flyer kinds of the dragon flock (art/cinematics/flocks/README.md) and the impostor bake.
## Every kind reuses an existing FlyerModel scene (art/units/...): the bake instantiates it once, puts every pivot back
## at its rest pose, merges all its meshes into ONE mesh (colours read from its materials, wing / hand / tail parts
## tagged in UV2.x for flock_impostor.gdshader) and a clustered far LOD of it. Cached per process (static).

const SHADER := preload("res://art/cinematics/flocks/flock_impostor.gdshader")

## style: "bat" (dragons), "bird" (roc), "serpent" (wyrm, no wings: S-wave body). hero = can be drawn with the real
## model (pivot-driven by the flock); the wyrm is skinned and runs its own clock, so it is impostor-only.
const KINDS := {
	"cinder_dragon": {"scene": "res://art/units/titans/cinder_dragon/cinder_dragon.tscn", "variant": -1,
		"style": "bat", "hero": true, "period": 1.2, "amp": 40.0, "mid": 6.0, "hand": 24.0, "bank": 34.0},
	"frost_dragon": {"scene": "res://art/units/titans/frost_dragon/frost_dragon.tscn", "variant": -1,
		"style": "bat", "hero": true, "period": 1.3, "amp": 40.0, "mid": 6.0, "hand": 24.0, "bank": 32.0},
	"roc": {"scene": "res://art/units/neutral/beasts/roc/roc.tscn", "variant": 0,
		"style": "bird", "hero": true, "period": 1.3, "amp": 34.0, "mid": 8.0, "hand": 18.0, "bank": 30.0},
	"roc_dusk": {"scene": "res://art/units/neutral/beasts/roc/roc.tscn", "variant": 1,
		"style": "bird", "hero": true, "period": 1.3, "amp": 34.0, "mid": 8.0, "hand": 18.0, "bank": 30.0},
	"frost_wyrm": {"scene": "res://art/units/neutral/beasts/frost_wyrm/frost_wyrm.tscn", "variant": 0,
		"style": "serpent", "hero": false, "period": 2.6, "amp": 0.0, "mid": 0.0, "hand": 0.0, "bank": 18.0},
	"hoarfang": {"scene": "res://art/units/neutral/beasts/frost_wyrm/frost_wyrm.tscn", "variant": 1,
		"style": "serpent", "hero": false, "period": 2.6, "amp": 0.0, "mid": 0.0, "hand": 0.0, "bank": 18.0},
}

const PART_OF := {"WingL": 1, "WingL2": 2, "WingR": 3, "WingR2": 4, "Tail1": 5, "Tail2": 5, "Tail3": 5}

static var _cache: Dictionary = {}


static func has_kind(kind: String) -> bool:
	return KINDS.has(kind)


static func info(kind: String) -> Dictionary:
	return KINDS.get(kind, KINDS["cinder_dragon"])


## The baked impostor of a kind: {near: ArrayMesh, far: ArrayMesh, material: ShaderMaterial, centre: Vector3 (model
## space body centre), span, length (m, scale 1), verts_near, verts_far, hinge: {wl, wl2, wr, wr2: [pos, axis]}}.
## `host` must be inside the tree (the model's _ready builds its meshes); the temporary model is freed at once.
static func baked(kind: String, host: Node) -> Dictionary:
	if _cache.has(kind):
		return _cache[kind]
	var k := info(kind)
	var ps := load(String(k["scene"])) as PackedScene
	if ps == null:
		push_warning("[flock] missing scene for kind %s" % kind)
		return {}
	var m := ps.instantiate() as Node3D
	var rest := rest_pose(m)
	host.add_child(m)
	m.set_process(false)
	m.set_physics_process(false)
	if int(k["variant"]) >= 0 and m.has_method(&"set_variant"):
		m.call(&"set_variant", int(k["variant"]))
	apply_rest(m, rest)
	var inv := m.global_transform.affine_inverse()
	var body := m.get_node_or_null(^"Root/Body") as Node3D
	var centre := (inv * body.global_position) if body else Vector3(0.0, 4.0, 0.0)
	var hinge := {}
	for pair: Array in [["wl", "Root/Body/WingL", 0, false], ["wl2", "Root/Body/WingL/WingL2", 0, true],
			["wr", "Root/Body/WingR", 1, false], ["wr2", "Root/Body/WingR/WingR2", 1, true]]:
		var n := m.get_node_or_null(NodePath(String(pair[1]))) as Node3D
		var axes: Variant = m.get(&"hand_axis") if bool(pair[3]) else m.get(&"wing_axis")
		var ax := Vector3(0, 0, -1)
		if axes is Array and (axes as Array).size() > int(pair[2]):
			ax = (axes as Array)[int(pair[2])]
		hinge[pair[0]] = [(inv * n.global_position - centre) if n else Vector3.ZERO, ax]
	var V := PackedVector3Array()
	var N := PackedVector3Array()
	var C := PackedColorArray()
	var U2 := PackedVector2Array()
	var I := PackedInt32Array()
	var kc: Variant = m.get(&"kingdom_color")
	var kingdom: Color = kc if kc is Color else Color(0.5, 0.4, 0.35)
	for node: Node in m.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree() or _skip(mi, m):
			continue
		var part := _part_of(mi, m)
		var xf := Transform3D(Basis.IDENTITY, -centre) * inv * mi.global_transform
		var nb := xf.basis.inverse().transposed()
		for s: int in mi.mesh.get_surface_count():
			if mi.mesh.surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:
				continue
			var arr := mi.mesh.surface_get_arrays(s)
			var sv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			if sv.is_empty():
				continue
			var sn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL] if arr[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
			var sc: PackedColorArray = arr[Mesh.ARRAY_COLOR] if arr[Mesh.ARRAY_COLOR] != null else PackedColorArray()
			var si: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
			var mi_info := _mat_info(mi.get_active_material(s), kingdom)
			if bool(mi_info.get("skip", false)):
				continue
			var base_i := V.size()
			var alb: Color = mi_info["albedo"]
			var belly: Color = mi_info.get("belly", alb)
			var emit := bool(mi_info["emit"])
			var use_vc := bool(mi_info.get("vc", false)) and sc.size() == sv.size()
			for j: int in sv.size():
				var nn := (nb * sn[j]).normalized() if sn.size() == sv.size() else Vector3.UP
				var col: Color
				if emit:
					col = Color(alb.r, alb.g, alb.b, 0.0)
				else:
					col = alb.lerp(belly, clampf((-nn.y - 0.15) / 0.5, 0.0, 1.0))
					if use_vc:
						col = col * sc[j]
					col.a = 1.0
				V.append(xf * sv[j])
				N.append(nn)
				C.append(col)
				U2.append(Vector2(float(part), 0.0))
			if si.is_empty():
				for j: int in sv.size():
					I.append(base_i + j)
			else:
				for x: int in si:
					I.append(base_i + x)
	host.remove_child(m)
	m.free()
	var aabb := AABB()
	if not V.is_empty():
		aabb = AABB(V[0], Vector3.ZERO)
		for p: Vector3 in V:
			aabb = aabb.expand(p)
	var span := maxf(aabb.size.x, 0.5)
	var length := maxf(aabb.size.z, 0.5)
	var near := _mesh(V, N, C, U2, I)
	var d := _decimate(V, N, C, U2, I, maxf(span, length) * 0.045)
	var far := _mesh(d["v"], d["n"], d["c"], d["u2"], d["i"])
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	var hk: Array = ["wl", "wl2", "wr", "wr2"]
	for key: String in hk:
		mat.set_shader_parameter(key + "_pos", hinge[key][0])
		mat.set_shader_parameter(key + "_axis", hinge[key][1])
	mat.set_shader_parameter(&"flap_amp", float(k["amp"]))
	mat.set_shader_parameter(&"flap_mid", float(k["mid"]))
	mat.set_shader_parameter(&"hand_amp", float(k["hand"]))
	var serp := String(k["style"]) == "serpent"
	mat.set_shader_parameter(&"serpent", 1.0 if serp else 0.0)
	mat.set_shader_parameter(&"wave_amp", length * 0.05)
	mat.set_shader_parameter(&"wave_k", TAU / maxf(length * 0.55, 1.0))
	mat.set_shader_parameter(&"tail_start", length * 0.12)
	mat.set_shader_parameter(&"tail_sway", 0.0 if serp else 0.09)
	var out := {"near": near, "far": far, "material": mat, "centre": centre, "span": span, "length": length,
		"aabb": aabb, "verts_near": V.size(), "verts_far": (d["v"] as PackedVector3Array).size(), "hinge": hinge}
	_cache[kind] = out
	return out


## Pivot rest positions of a FlyerModel read from the scene BEFORE it enters the tree (= its _rest_pos).
static func rest_pose(m: Node3D) -> Dictionary:
	var rest := {}
	for path: String in FlyerModel.PIVOT_PATHS:
		var n := m.get_node_or_null(NodePath(path)) as Node3D
		if n:
			rest[path] = n.position
	return rest


static func apply_rest(m: Node3D, rest: Dictionary) -> void:
	for path: String in rest:
		var n := m.get_node_or_null(NodePath(path)) as Node3D
		if n:
			n.transform = Transform3D(Basis.IDENTITY, rest[path])


static func _skip(mi: Node, m: Node) -> bool:
	var n := mi
	while n and n != m:
		var nm := String(n.name)
		if nm == "Shadow" or nm == "Fx" or nm.begins_with("Blob"):
			return true
		n = n.get_parent()
	return false


static func _part_of(mi: Node, m: Node) -> int:
	var n := mi.get_parent()
	while n and n != m:
		if PART_OF.has(String(n.name)):
			return int(PART_OF[String(n.name)])
		n = n.get_parent()
	return 0


static func _col(v: Variant) -> Variant:
	if v is Color:
		return v
	if v is Vector3:
		return Color(v.x, v.y, v.z)
	if v is Vector4:
		return Color(v.x, v.y, v.z, v.w)
	return null


static func _param(mat: ShaderMaterial, name: StringName) -> Variant:
	var v: Variant = mat.get_shader_parameter(name)
	if v == null and mat.shader:
		v = RenderingServer.shader_get_parameter_default(mat.shader.get_rid(), name)
	return v


## Flat colour of a material for the impostor: {albedo, belly?, emit, vc?, skip?}.
static func _mat_info(mat: Material, kingdom: Color) -> Dictionary:
	if mat is BaseMaterial3D:
		var bm := mat as BaseMaterial3D
		if bm.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED and bm.albedo_color.a < 0.5:
			return {"skip": true}
		if bm.emission_enabled and bm.emission_energy_multiplier > 0.5:
			return {"albedo": bm.emission, "emit": true}
		if bm.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED and bm.albedo_color.get_luminance() > 0.5:
			return {"albedo": bm.albedo_color, "emit": true, "vc": bm.vertex_color_use_as_albedo}
		return {"albedo": bm.albedo_color, "emit": false, "vc": bm.vertex_color_use_as_albedo}
	if mat is ShaderMaterial:
		var sm := mat as ShaderMaterial
		var path := sm.shader.resource_path.get_file() if sm.shader else ""
		var base: Variant = _col(_param(sm, &"base_color"))
		var glow: Variant = _col(_param(sm, &"glow_color"))
		if path.contains("glow") or (base == null and glow != null and _param(sm, &"energy") != null):
			return {"albedo": glow if glow != null else Color(1, 0.6, 0.2), "emit": true}
		if base != null:
			var belly: Variant = _col(_param(sm, &"belly_color"))
			if belly == null:
				belly = _col(_param(sm, &"pale_color"))
			var out := {"albedo": base, "emit": false}
			if belly != null:
				out["belly"] = (base as Color).lerp(belly, 0.75)
			return out
		var root: Variant = _col(_param(sm, &"root_color"))
		if root != null:
			var edge: Variant = _col(_param(sm, &"edge_color"))
			return {"albedo": (root as Color).lerp(edge if edge != null else root, 0.45), "emit": false}
		if path.contains("membrane"):
			var bright: Variant = _param(sm, &"tint_bright")
			var bone: Variant = _col(_param(sm, &"bone_shade"))
			var tint := kingdom if kingdom.a > 0.01 else Color(0.45, 0.35, 0.3)
			var c := tint * (float(bright) if bright != null else 0.6)
			if bone != null:
				c = c.lerp(bone, 0.25)
			c.a = 1.0
			return {"albedo": c, "emit": false}
		if glow != null:
			return {"albedo": (glow as Color).lerp(Color.WHITE, 0.3), "emit": false}
		var alb: Variant = _col(_param(sm, &"albedo"))
		if alb == null:
			alb = _col(_param(sm, &"color"))
		return {"albedo": alb if alb != null else Color(0.35, 0.3, 0.28), "emit": false}
	return {"albedo": Color(0.35, 0.3, 0.28), "emit": false}


static func _mesh(v: PackedVector3Array, n: PackedVector3Array, c: PackedColorArray, u2: PackedVector2Array,
		idx: PackedInt32Array) -> ArrayMesh:
	var am := ArrayMesh.new()
	if v.is_empty() or idx.is_empty():
		return am
	var a := []
	a.resize(Mesh.ARRAY_MAX)
	a[Mesh.ARRAY_VERTEX] = v
	a[Mesh.ARRAY_NORMAL] = n
	a[Mesh.ARRAY_COLOR] = c
	a[Mesh.ARRAY_TEX_UV2] = u2
	a[Mesh.ARRAY_INDEX] = idx
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
	return am


## Far LOD: vertex clustering on a grid of `cell` m, per part (wings never merge with the body, so they still beat).
static func _decimate(v: PackedVector3Array, n: PackedVector3Array, c: PackedColorArray, u2: PackedVector2Array,
		idx: PackedInt32Array, cell: float) -> Dictionary:
	var key_of := {}
	var remap := PackedInt32Array()
	remap.resize(v.size())
	var sv := PackedVector3Array()
	var sn := PackedVector3Array()
	var sc: Array[Color] = []
	var su := PackedVector2Array()
	var cnt := PackedInt32Array()
	for j: int in v.size():
		var p := v[j]
		var key := Vector4i(floori(p.x / cell), floori(p.y / cell), floori(p.z / cell), int(u2[j].x))
		var ci: int
		if key_of.has(key):
			ci = key_of[key]
		else:
			ci = sv.size()
			key_of[key] = ci
			sv.append(Vector3.ZERO)
			sn.append(Vector3.ZERO)
			sc.append(Color(0, 0, 0, 0))
			su.append(u2[j])
			cnt.append(0)
		sv[ci] += p
		sn[ci] += n[j]
		sc[ci] = Color(sc[ci].r + c[j].r, sc[ci].g + c[j].g, sc[ci].b + c[j].b, sc[ci].a + c[j].a)
		cnt[ci] += 1
		remap[j] = ci
	var outc := PackedColorArray()
	for ci: int in sv.size():
		var k := float(cnt[ci])
		sv[ci] /= k
		sn[ci] = sn[ci].normalized() if sn[ci].length() > 0.0001 else Vector3.UP
		var cc := sc[ci]
		outc.append(Color(cc.r / k, cc.g / k, cc.b / k, 1.0 if cc.a / k >= 0.5 else 0.0))
	var oi := PackedInt32Array()
	var seen := {}
	for t: int in range(0, idx.size() - 2, 3):
		var a := remap[idx[t]]
		var b := remap[idx[t + 1]]
		var d := remap[idx[t + 2]]
		if a == b or b == d or a == d:
			continue
		var tk := Vector3i(mini(a, mini(b, d)), a + b + d, maxi(a, maxi(b, d)))
		if seen.has(tk):
			continue
		seen[tk] = true
		oi.append(a)
		oi.append(b)
		oi.append(d)
	return {"v": sv, "n": sn, "c": outc, "u2": su, "i": oi}
