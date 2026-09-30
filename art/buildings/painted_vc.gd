class_name PaintedVC
extends RefCounted
## One painted material per building (B8 budget, art-keep.md 9: <= 8 materials): after a building model is built,
## `convert()` moves every painted.gdshader material's look into the VERTEX data of the meshes that use it and draws
## them all with ONE painted_vc.gdshader material (the shading is painted.gdshader's, so the look does not change).
## The same approach as the Stables (one vertex-coloured material), done as a post-pass so the build code of each
## building stays as it is (it still says mat_stone / mat_dark / mat_metal / mat_team...).
##   COLOR.rgb = the part material's base_color, COLOR.a 0 = team part (x the team colour) / 1 = plain,
##   UV2.x = its crack_strength (< -0.5 = hole: unlit dark), UV2.y = its spec_strength.
## The body material is the building's TEAM material itself (its shader switched to painted_vc), so everything that
## already drives it keeps working: set_team_color writes base_color, the selection rim / damage loops over the
## painted materials reach it. A painted surface of a merged tier folds into ONE surface (fewer draw calls too);
## other surfaces (glows, banners) stay as they are. Converted meshes are cached (shared by every instance).
## Parts whose painted material changes at run time by itself (not through the shared loops) must be left out
## (`skip` materials).

const PAINTED: Shader = preload("res://art/shaders/painted.gdshader")
const PAINTED_VC: Shader = preload("res://art/shaders/painted_vc.gdshader")
const HOLE := -1.0
const RUNE_GLOW: Shader = preload("res://art/shaders/rune_glow.gdshader")
const GLOW_VC: Shader = preload("res://art/shaders/rune_glow_vc.gdshader")
const GLOW_MAX := 8

static var _cache: Dictionary = {}   ## "<mesh id>|<surface descs>" -> [source mesh, baked mesh, surface materials map]


## Converts every painted part under `root` to vertex colours drawn by `body` (a painted.gdshader ShaderMaterial,
## normally the team material; its shader becomes painted_vc). `team` = the materials whose base_color is the team
## colour (their parts get COLOR.a 0): a material, or [material, multiplier] for a darker team shade. `holes` = unshaded dark StandardMaterial3Ds to fold in as holes. `skip` =
## painted materials to leave alone. Returns false (and changes nothing) when `body` is not a painted material.
static func convert(root: Node, body: ShaderMaterial, team: Array = [], holes: Array = [], skip: Array = []) -> bool:
	if body == null or not (body.shader == PAINTED or body.shader == PAINTED_VC):
		return false
	if body.shader == PAINTED:
		var crack_src: ShaderMaterial = _crack_source(root, skip)
		if crack_src:
			for p: StringName in [&"crack_color", &"crack_speed", &"crack_scale"]:
				var v: Variant = crack_src.get_shader_parameter(p)
				if v != null:
					body.set_shader_parameter(p, v)
		# The body's own look as a part: remembered before its uniforms change meaning.
		body.set_meta(&"vc_desc", _desc(body, team, holes))
		body.shader = PAINTED_VC
		body.set_shader_parameter(&"crack_strength", 1.0)
	_prune()
	var nodes: Array[Node] = root.find_children("*", "GeometryInstance3D", true, false)
	if root is GeometryInstance3D:
		nodes.push_front(root)
	for n: Node in nodes:
		if n is MeshInstance3D:
			_convert_mi(n as MeshInstance3D, body, team, holes, skip)
		elif n is MultiMeshInstance3D:
			_convert_mmi(n as MultiMeshInstance3D, body, team, holes, skip)
		elif n is GPUParticles3D:
			_convert_particles(n as GPUParticles3D, body, team, holes, skip)
	return true


## Mesh particles (debris splinters...): a draw pass whose mesh is all painted gets a baked copy, and the emitter
## draws with `body` (material_override: the cached mesh itself carries no material).
static func _convert_particles(p: GPUParticles3D, body: ShaderMaterial, team: Array, holes: Array, skip: Array) -> void:
	if p.material_override != null or p.draw_passes != 1:
		return
	for i: int in p.draw_passes:
		var dm: Mesh = p.get_draw_pass_mesh(i)
		if dm == null or dm.get_surface_count() == 0:
			continue
		var descs: PackedStringArray = []
		for s: int in dm.get_surface_count():
			var m: Material = dm.surface_get_material(s)
			var d := "" if skip.has(m) else _desc(m, team, holes)
			if d == "":
				descs = PackedStringArray()
				break
			descs.append(d)
		if descs.is_empty():
			continue
		p.set_draw_pass_mesh(i, _bake(dm, descs)[0])
		p.material_override = body


## A part's vertex data for material `m` ("" = not convertible).
static func _desc(m: Material, team: Array, holes: Array) -> String:
	if m == null:
		return ""
	if m.has_meta(&"vc_desc"):
		return String(m.get_meta(&"vc_desc"))
	if m is ShaderMaterial and (m as ShaderMaterial).shader == PAINTED:
		var sm := m as ShaderMaterial
		var c: Color = _col(sm.get_shader_parameter(&"base_color"), Color(0.3, 0.26, 0.24))
		var mult: float = _team_mult(m, team)
		var is_team: bool = mult >= 0.0
		if is_team:
			c = Color(mult, mult, mult)
		return "%s,%s,%s,%s,%s,%s,%s,%s" % [c.r, c.g, c.b, 0.0 if is_team else 1.0,
			_num(sm.get_shader_parameter(&"crack_strength"), 0.0), _num(sm.get_shader_parameter(&"spec_strength"), 0.0),
			_num(sm.get_shader_parameter(&"crack_scale"), 0.8), _num(sm.get_shader_parameter(&"crack_speed"), 1.2)]
	if holes.has(m) and m is BaseMaterial3D:
		var hc: Color = (m as BaseMaterial3D).albedo_color
		return "%s,%s,%s,1.0,%s,0.0,0.8,1.2" % [hc.r, hc.g, hc.b, HOLE]
	return ""


## The team multiplier of `m` (-1 = not a team material). `team` holds materials (x1) or [material, multiplier]
## pairs (a material whose base_color is the team colour darkened: Color.darkened(k) = x (1 - k)).
static func _team_mult(m: Material, team: Array) -> float:
	for e: Variant in team:
		if e is Array and (e as Array).size() == 2 and (e as Array)[0] == m:
			return float((e as Array)[1])
		if e is Material and e == m:
			return 1.0
	return -1.0


static func _col(v: Variant, fallback: Color) -> Color:
	if v is Color:
		return v
	if v is Vector3:
		return Color((v as Vector3).x, (v as Vector3).y, (v as Vector3).z)
	return fallback


static func _num(v: Variant, fallback: float) -> float:
	return float(v) if v != null else fallback


static func _crack_source(root: Node, skip: Array) -> ShaderMaterial:
	var best: ShaderMaterial = null
	var best_c: float = 0.0
	for n: Node in root.find_children("*", "GeometryInstance3D", true, false):
		for m: Material in _surface_mats(n as GeometryInstance3D):
			if m is ShaderMaterial and (m as ShaderMaterial).shader == PAINTED and not skip.has(m):
				var c: float = _num((m as ShaderMaterial).get_shader_parameter(&"crack_strength"), 0.0)
				if c > best_c:
					best_c = c
					best = m
	return best


## The material drawn on each surface (override wins).
static func _surface_mats(g: GeometryInstance3D) -> Array[Material]:
	var out: Array[Material] = []
	var mesh: Mesh = null
	if g is MeshInstance3D:
		mesh = (g as MeshInstance3D).mesh
	elif g is MultiMeshInstance3D and (g as MultiMeshInstance3D).multimesh:
		mesh = (g as MultiMeshInstance3D).multimesh.mesh
	if mesh == null:
		return out
	for s: int in mesh.get_surface_count():
		var m: Material = g.material_override
		if m == null and g is MeshInstance3D:
			m = (g as MeshInstance3D).get_surface_override_material(s)
		if m == null:
			m = mesh.surface_get_material(s)
		out.append(m)
	return out


static func _convert_mi(mi: MeshInstance3D, body: ShaderMaterial, team: Array, holes: Array, skip: Array) -> void:
	if mi.mesh == null or mi.mesh.get_surface_count() == 0:
		return
	var mats := _surface_mats(mi)
	var descs: PackedStringArray = []
	var any := false
	for m: Material in mats:
		var d := "" if skip.has(m) else _desc(m, team, holes)
		if m == body and d == "":
			d = _desc(body, team, holes)
		descs.append(d)
		any = any or d != ""
	if not any:
		return
	var baked: Array = _bake(mi.mesh, descs)
	var am: ArrayMesh = baked[0]
	var src_of: Array = baked[1]   # per new surface: source surface index, -1 = the painted surface
	mi.material_override = null
	mi.mesh = am
	for s: int in am.get_surface_count():
		var src: int = src_of[s]
		mi.set_surface_override_material(s, body if src < 0 else mats[src])


static func _convert_mmi(mmi: MultiMeshInstance3D, body: ShaderMaterial, team: Array, holes: Array, skip: Array) -> void:
	var mm := mmi.multimesh
	if mm == null or mm.mesh == null:
		return
	var mats := _surface_mats(mmi)
	var descs: PackedStringArray = []
	for m: Material in mats:
		var d := "" if skip.has(m) else _desc(m, team, holes)
		if m == body and d == "":
			d = _desc(body, team, holes)
		if d == "":
			return   # a multimesh draws one material override: convert only when all of it is painted
		descs.append(d)
	var baked: Array = _bake(mm.mesh, descs)
	mm.mesh = baked[0]
	mmi.material_override = body


## [ArrayMesh, source surface per new surface (-1 = the merged painted surface, -2 = the merged glow surface)],
## cached per mesh + descs.
static func _bake(mesh: Mesh, descs: PackedStringArray) -> Array:
	var key := "%d|%s" % [mesh.get_instance_id(), "|".join(descs)]
	if _cache.has(key):
		var hit: Array = _cache[key]
		return [hit[1], hit[2]]
	var am := ArrayMesh.new()
	var src_of: Array = []
	# The painted surfaces first, as one surface.
	var V := PackedVector3Array()
	var N := PackedVector3Array()
	var C := PackedColorArray()
	var U := PackedVector2Array()
	var U2 := PackedVector2Array()
	var K := PackedFloat32Array()
	var I := PackedInt32Array()
	for s: int in mesh.get_surface_count():
		if descs[s] == "" or descs[s].begins_with("G"):
			continue
		var f := descs[s].split(",")
		var col := Color(float(f[0]), float(f[1]), float(f[2]), float(f[3]))
		var k2 := Vector2(float(f[4]), float(f[5]))
		var ss := Vector2(float(f[6]), float(f[7])) if f.size() >= 8 else Vector2.ZERO
		var a: Array = mesh.surface_get_arrays(s)
		var sv: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var sn: Variant = a[Mesh.ARRAY_NORMAL]
		var su: Variant = a[Mesh.ARRAY_TEX_UV]
		var sc: Variant = a[Mesh.ARRAY_COLOR]
		var si: Variant = a[Mesh.ARRAY_INDEX]
		var has_n: bool = sn is PackedVector3Array and (sn as PackedVector3Array).size() == sv.size()
		var has_uv: bool = su is PackedVector2Array and (su as PackedVector2Array).size() == sv.size()
		var has_c: bool = sc is PackedColorArray and (sc as PackedColorArray).size() == sv.size()
		var base: int = V.size()
		V.append_array(sv)
		for k: int in sv.size():
			N.append((sn as PackedVector3Array)[k] if has_n else Vector3.UP)
			U.append((su as PackedVector2Array)[k] if has_uv else Vector2.ZERO)
			C.append(col * (sc as PackedColorArray)[k] if has_c else col)
			U2.append(k2)
			K.append(ss.x)
			K.append(ss.y)
		if si is PackedInt32Array and (si as PackedInt32Array).size() > 0:
			for idx: int in (si as PackedInt32Array):
				I.append(base + idx)
		else:
			for t: int in sv.size():
				I.append(base + t)
	if not V.is_empty():
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = V
		arr[Mesh.ARRAY_NORMAL] = N
		arr[Mesh.ARRAY_COLOR] = C
		arr[Mesh.ARRAY_TEX_UV] = U
		arr[Mesh.ARRAY_TEX_UV2] = U2
		arr[Mesh.ARRAY_CUSTOM0] = K
		arr[Mesh.ARRAY_INDEX] = I
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {},
			Mesh.ARRAY_CUSTOM_RG_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
		src_of.append(-1)
	# The glow surfaces (desc "G,<channel>"), as one surface: UV kept (rune bands), UV2.x = the channel.
	var GV := PackedVector3Array()
	var GN := PackedVector3Array()
	var GU := PackedVector2Array()
	var GU2 := PackedVector2Array()
	var GI := PackedInt32Array()
	for s: int in mesh.get_surface_count():
		if not descs[s].begins_with("G"):
			continue
		var ch := float(descs[s].split(",")[1])
		var a3: Array = mesh.surface_get_arrays(s)
		var gv: PackedVector3Array = a3[Mesh.ARRAY_VERTEX]
		var gn: Variant = a3[Mesh.ARRAY_NORMAL]
		var gu: Variant = a3[Mesh.ARRAY_TEX_UV]
		var gi: Variant = a3[Mesh.ARRAY_INDEX]
		var gbase: int = GV.size()
		GV.append_array(gv)
		for k: int in gv.size():
			GN.append((gn as PackedVector3Array)[k] if gn is PackedVector3Array and (gn as PackedVector3Array).size() == gv.size() else Vector3.UP)
			GU.append((gu as PackedVector2Array)[k] if gu is PackedVector2Array and (gu as PackedVector2Array).size() == gv.size() else Vector2.ZERO)
			GU2.append(Vector2(ch, 0.0))
		if gi is PackedInt32Array and (gi as PackedInt32Array).size() > 0:
			for idx: int in (gi as PackedInt32Array):
				GI.append(gbase + idx)
		else:
			for t: int in gv.size():
				GI.append(gbase + t)
	if not GV.is_empty():
		var garr := []
		garr.resize(Mesh.ARRAY_MAX)
		garr[Mesh.ARRAY_VERTEX] = GV
		garr[Mesh.ARRAY_NORMAL] = GN
		garr[Mesh.ARRAY_TEX_UV] = GU
		garr[Mesh.ARRAY_TEX_UV2] = GU2
		garr[Mesh.ARRAY_INDEX] = GI
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, garr)
		src_of.append(-2)
	# The other surfaces, as they were.
	for s: int in mesh.get_surface_count():
		if descs[s] != "":
			continue
		var a2: Array = mesh.surface_get_arrays(s)
		am.add_surface_from_arrays(mesh.surface_get_primitive_type(s), a2, [], {}, _custom_flags(mesh, s))
		am.surface_set_material(am.get_surface_count() - 1, mesh.surface_get_material(s))
		src_of.append(s)
	_cache[key] = [mesh, am, src_of]
	return [am, src_of]


# --- Glow merge ----------------------------------------------------------------------------------------------------

## Merges every rune_glow.gdshader material under `root` (coals, gate / window glow, lanterns, the construction
## outline...) into ONE rune_glow_vc.gdshader material: each source keeps its own channel (colour, energy, pulse,
## bands, boost, phase in uniform arrays; UV2.x of its vertices = the channel), so the look and every state the code
## drives on the sources stays the same, as long as the owner calls `sync_glow()` each frame (it copies the sources'
## current values). Returns the merged material (null = fewer than 2 glow materials, nothing changed).
static func convert_glow(root: Node, skip: Array = []) -> ShaderMaterial:
	var nodes: Array[Node] = root.find_children("*", "GeometryInstance3D", true, false)
	if root is GeometryInstance3D:
		nodes.push_front(root)
	var src: Array = []
	for n: Node in nodes:
		if not (n is MeshInstance3D or n is MultiMeshInstance3D):
			continue
		for m: Material in _surface_mats(n as GeometryInstance3D):
			var ok: bool = m is ShaderMaterial and (m as ShaderMaterial).shader == RUNE_GLOW
			if ok and not skip.has(m) and not src.has(m) and src.size() < GLOW_MAX:
				src.append(m as ShaderMaterial)
	if src.size() < 2:
		return null
	var g := ShaderMaterial.new()
	g.resource_name = "GlowMerged"
	g.shader = GLOW_VC
	g.set_meta(&"glow_src", src)
	sync_glow(g)
	for n: Node in nodes:
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			if mi.mesh == null:
				continue
			var mats := _surface_mats(mi)
			var descs: PackedStringArray = []
			var any := false
			for m: Material in mats:
				var ch: int = src.find(m)
				descs.append("G,%d" % ch if ch >= 0 else "")
				any = any or ch >= 0
			if not any:
				continue
			var baked: Array = _bake(mi.mesh, descs)
			var am: ArrayMesh = baked[0]
			var src_of: Array = baked[1]
			mi.material_override = null
			mi.mesh = am
			for s: int in am.get_surface_count():
				var from: int = src_of[s]
				mi.set_surface_override_material(s, g if from == -2 else mats[from])
		elif n is MultiMeshInstance3D:
			var mmi := n as MultiMeshInstance3D
			if mmi.multimesh == null or mmi.multimesh.mesh == null:
				continue
			var mats2 := _surface_mats(mmi)
			var descs2: PackedStringArray = []
			for m: Material in mats2:
				var ch2: int = src.find(m)
				if ch2 < 0:
					descs2 = PackedStringArray()
					break
				descs2.append("G,%d" % ch2)
			if descs2.is_empty():
				continue
			mmi.multimesh.mesh = _bake(mmi.multimesh.mesh, descs2)[0]
			mmi.material_override = g
	return g


## Copies the source glow materials' current values into the merged one (call it once per frame while it lives).
static func sync_glow(g: ShaderMaterial) -> void:
	if g == null or not g.has_meta(&"glow_src"):
		return
	var src: Array = g.get_meta(&"glow_src")
	var cols := PackedVector3Array()
	var en := PackedFloat32Array()
	var sp := PackedFloat32Array()
	var bd := PackedInt32Array()
	var bo := PackedFloat32Array()
	var ph := PackedFloat32Array()
	for i: int in GLOW_MAX:
		var m: ShaderMaterial = src[mini(i, src.size() - 1)]
		var c: Color = _col(m.get_shader_parameter(&"glow_color"), Color(1.0, 0.55, 0.15)).srgb_to_linear()
		cols.append(Vector3(c.r, c.g, c.b))
		en.append(_num(m.get_shader_parameter(&"energy"), 3.0))
		sp.append(_num(m.get_shader_parameter(&"pulse_speed"), 2.0))
		bd.append(int(_num(m.get_shader_parameter(&"rune_bands"), 0.0)))
		bo.append(_num(m.get_shader_parameter(&"boost"), 1.0))
		ph.append(_num(m.get_shader_parameter(&"phase"), 0.0))
	g.set_shader_parameter(&"glow_colors", cols)
	g.set_shader_parameter(&"energies", en)
	g.set_shader_parameter(&"pulse_speeds", sp)
	g.set_shader_parameter(&"bands", bd)
	g.set_shader_parameter(&"boosts", bo)
	g.set_shader_parameter(&"phases", ph)


## The custom-channel format bits of a source surface (a painted-vc surface kept by the glow pass keeps CUSTOM0).
static func _custom_flags(mesh: Mesh, s: int) -> int:
	if not (mesh is ArrayMesh):
		return 0
	var f: int = (mesh as ArrayMesh).surface_get_format(s)
	var out: int = 0
	for c: int in 4:
		var shift: int = Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT + c * Mesh.ARRAY_FORMAT_CUSTOM_BITS
		out |= f & (Mesh.ARRAY_FORMAT_CUSTOM_MASK << shift)
	return out


## A flat ground plane (PlaneMesh layout, facing up) whose vertices carry `col`: decals / stains sharing one
## vertex-coloured material (vertex_color_use_as_albedo + vertex_color_is_srgb), each with its own tint. Cached.
static func tinted_plane(size: Vector2, col: Color) -> ArrayMesh:
	var key := "plane|%s|%s" % [size, col]
	if _cache.has(key):
		return (_cache[key] as Array)[1]
	var pm := PlaneMesh.new()
	pm.size = size
	var a: Array = pm.surface_get_arrays(0)
	var n: int = (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	var C := PackedColorArray()
	C.resize(n)
	C.fill(col)
	a[Mesh.ARRAY_COLOR] = C
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
	_cache[key] = [am, am, []]
	return am


## Drops cached bakes whose source mesh only the cache still holds (per-instance meshes of freed buildings).
static func _prune() -> void:
	if _cache.size() < 256:
		return
	for k: String in _cache.keys():
		var src: Mesh = (_cache[k] as Array)[0]
		if src.get_reference_count() <= 2:
			_cache.erase(k)
