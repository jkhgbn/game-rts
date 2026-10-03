class_name NatureVC
extends RefCounted
## One painted material per Nature building (B8 budget, art-keep.md 9: <= 8 materials). NatureKit gives every Nature
## building seven painted materials (Stone, Dark, Bark, Wood, Moss, Leaves = team, Thorn) plus the unlit Void; this
## post-pass merges every surface drawn with them into ONE surface per mesh, drawn by ONE nature_vc.gdshader material
## that holds the seven materials' settings in arrays (CUSTOM0.x of each vertex = the index, -1 = Void). The shading is
## nature_keep_painted.gdshader's, so the look does not change. The seven materials stay the source of truth: the
## NatureKit helpers (apply_team / apply_rim / apply_health / apply_wreck) change them as before and then call
## `sync()`, which copies their values into the merged material. Merged meshes are cached (shared by every instance).

const SHADER: Shader = preload("res://art/buildings/nature/nature_vc.gdshader")
const KEYS: Array[String] = ["Stone", "Dark", "Bark", "Wood", "Moss", "Leaves", "Thorn"]
const VOID_KEY := "Black"
const GOLD_KEY := "Gold"    ## optional trade gold (market_nature_gold.gdshader), part kind -2
const EXTRA_KEY := "Clay"   ## an optional 8th painted material (market_nature's jars and sacks)
const KEY_VC := "_vc"
const KEY_CARDS := "_cards"
const CARD_SHADER: Shader = preload("res://art/buildings/nature/nature_cards_vc.gdshader")
const CARD_KEYS: Array[String] = ["LeafCard", "Blossom", "Petal"]
const CARD_BASE := 100
const KEEP := -99
## The card shader's uniforms (nature_keep_leaf.gdshader, generated into nature_cards_vc arrays): name, type, sRGB.
const CARD_UNIFORMS: Array = [[&"shape", "int", false], [&"base_color", "vec3", true], [&"tip_tint", "vec3", false],
	[&"edge_color", "vec3", true], [&"glow_color", "vec3", true], [&"glow_energy", "float", false],
	[&"boost", "float", false], [&"leaf_value", "float", false], [&"sway", "float", false],
	[&"sway_speed", "float", false], [&"drop", "float", false], [&"wither", "float", false],
	[&"wither_color", "vec3", true], [&"rim_color", "vec3", true], [&"rim_strength", "float", false],
	[&"damage", "float", false], [&"ao_low", "float", false], [&"ao_span", "float", false]]

static var _cache: Dictionary = {}


## The merged material of a NatureKit material set (created on first use, stored in the set under "_vc").
static func material(m: Dictionary) -> ShaderMaterial:
	if m.has(KEY_VC):
		return m[KEY_VC]
	var body := ShaderMaterial.new()
	body.resource_name = "NaturePainted"
	body.shader = SHADER
	m[KEY_VC] = body
	sync(m)
	return body


## Copies the seven painted materials' current values into the merged one (no-op when the set has none).
static func sync(m: Dictionary) -> void:
	sync_cards(m)
	if not m.has(KEY_VC):
		return
	var body: ShaderMaterial = m[KEY_VC]
	var cols := PackedVector3Array()
	var pats := PackedInt32Array()
	var na := PackedFloat32Array()
	var spec := PackedFloat32Array()
	var bs := PackedVector2Array()
	var jw := PackedFloat32Array()
	var bt := PackedFloat32Array()
	var moss := PackedFloat32Array()
	var mc := PackedVector3Array()
	for i: int in 8:
		var src: ShaderMaterial = m.get(_key(m, i))
		cols.append(_lin(_p(src, &"base_color", Color(0.45, 0.42, 0.32))))
		pats.append(int(_p(src, &"pattern", 0)))
		na.append(float(_p(src, &"noise_scale_a", 0.5)))
		spec.append(float(_p(src, &"spec_strength", 0.0)))
		bs.append(_p(src, &"block_size", Vector2(0.9, 0.45)))
		jw.append(float(_p(src, &"joint_width", 0.07)))
		bt.append(float(_p(src, &"block_tint", 0.18)))
		moss.append(float(_p(src, &"moss", 0.0)))
		mc.append(_lin(_p(src, &"moss_color", Color(0.25, 0.37, 0.12))))
	MatSync.put(body, &"base_colors", cols)
	MatSync.put(body, &"patterns", pats)
	MatSync.put(body, &"noise_scales_a", na)
	MatSync.put(body, &"spec_strengths", spec)
	MatSync.put(body, &"block_sizes", bs)
	MatSync.put(body, &"joint_widths", jw)
	MatSync.put(body, &"block_tints", bt)
	MatSync.put(body, &"mosses", moss)
	MatSync.put(body, &"moss_colors", mc)
	var stone: ShaderMaterial = m["Stone"]
	var bark: ShaderMaterial = m["Bark"]
	var leaves: ShaderMaterial = m["Leaves"]
	for p: StringName in [&"noise_tex", &"noise_scale_b", &"rim_color", &"rim_strength", &"damage", &"ao_floor"]:
		_copy(stone, body, p)
	for p: StringName in [&"sap", &"sap_color", &"sap_energy", &"sap_speed", &"bark_scale"]:
		_copy(bark, body, p)
	for p: StringName in [&"wither", &"wither_color", &"top_tint", &"shade_tint", &"leaf_scale", &"foliage_value"]:
		_copy(leaves, body, p)
	sync_gold(m)
	var black: Material = m.get(VOID_KEY)
	if black is BaseMaterial3D:
		MatSync.put(body, &"void_color", (black as BaseMaterial3D).albedo_color)


## The painted material of array slot i: the seven KEYS, then the building's extra one (the Bazaar's Clay).
static func _key(m: Dictionary, i: int) -> String:
	if i < KEYS.size():
		return KEYS[i]
	return EXTRA_KEY if m.has(EXTRA_KEY) else KEYS[KEYS.size() - 1]


## Copies the trade gold material's current values (glint flash, rim, damage) into the merged one.
static func sync_gold(m: Dictionary) -> void:
	if not m.has(KEY_VC) or not m.has(GOLD_KEY):
		return
	var body: ShaderMaterial = m[KEY_VC]
	var g: ShaderMaterial = m[GOLD_KEY]
	for pair: Array in [[&"base_color", &"gold_color"], [&"deep_color", &"gold_deep"], [&"spec_strength", &"gold_spec"],
			[&"sweep_speed", &"gold_sweep_speed"], [&"sweep_energy", &"gold_sweep_energy"], [&"glint", &"gold_glint"],
			[&"rim_color", &"gold_rim_color"], [&"rim_strength", &"gold_rim_strength"], [&"damage", &"gold_damage"]]:
		var v: Variant = g.get_shader_parameter(pair[0])
		if v != null:
			MatSync.put(body, pair[1], v)


static func _p(src: ShaderMaterial, p: StringName, fallback: Variant) -> Variant:
	if src == null:
		return fallback
	var v: Variant = src.get_shader_parameter(p)
	return fallback if v == null else v


static func _lin(c: Variant) -> Vector3:
	var col: Color = c if c is Color else Color((c as Vector3).x, (c as Vector3).y, (c as Vector3).z)
	var l := col.srgb_to_linear()
	return Vector3(l.r, l.g, l.b)


static func _copy(src: ShaderMaterial, dst: ShaderMaterial, p: StringName) -> void:
	var v: Variant = src.get_shader_parameter(p)
	if v != null:
		MatSync.put(dst, p, v)


## Merges the painted (and Void) surfaces of every MeshInstance3D under `root` drawn with the set `m` into ONE
## surface (the merged painted material), and the card surfaces (LeafCard, Blossom, Petal) into ONE more (the merged
## card material, nature_cards_vc.gdshader).
static func convert(root: Node, m: Dictionary) -> void:
	MeshBake.prune(_cache)
	var body := material(m)
	var cards := card_material(m)
	var index := {}
	for i: int in KEYS.size():
		index[m[KEYS[i]]] = i
	if m.has(EXTRA_KEY):
		index[m[EXTRA_KEY]] = KEYS.size()
	if m.has(VOID_KEY):
		index[m[VOID_KEY]] = -1
	if m.has(GOLD_KEY):
		index[m[GOLD_KEY]] = -2
	for i: int in CARD_KEYS.size():
		if m.has(CARD_KEYS[i]):
			index[m[CARD_KEYS[i]]] = CARD_BASE + i
	for n: Node in root.find_children("*", "MultiMeshInstance3D", true, false):
		# Rubble / debris cubes (one painted material override on a MultiMesh).
		var mmi := n as MultiMeshInstance3D
		var mo: Material = mmi.material_override
		if mmi.multimesh == null or mmi.multimesh.mesh == null or not index.has(mo) or int(index[mo]) >= CARD_BASE:
			continue
		var mids := PackedInt32Array()
		for s: int in mmi.multimesh.mesh.get_surface_count():
			mids.append(int(index[mo]))
		mmi.multimesh.mesh = _bake(mmi.multimesh.mesh, mids)[0]
		mmi.material_override = body
	for n: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null or mi.material_override != null:
			continue
		var ids := PackedInt32Array()
		var mats: Array[Material] = []
		var any := false
		for s: int in mi.mesh.get_surface_count():
			var mat: Material = mi.get_surface_override_material(s)
			if mat == null:
				mat = mi.mesh.surface_get_material(s)
			mats.append(mat)
			if index.has(mat):
				ids.append(int(index[mat]))
				any = true
			else:
				ids.append(KEEP)
		if not any:
			continue
		var baked: Array = _bake(mi.mesh, ids)
		var am: ArrayMesh = baked[0]
		var src_of: Array = baked[1]
		mi.mesh = am
		for s: int in am.get_surface_count():
			var src: int = src_of[s]
			mi.set_surface_override_material(s, body if src == -1 else (cards if src == -2 else mats[src]))


## The merged card material of a set (created on first use, stored under "_cards").
static func card_material(m: Dictionary) -> ShaderMaterial:
	if m.has(KEY_CARDS):
		return m[KEY_CARDS]
	var c := ShaderMaterial.new()
	c.resource_name = "NatureCards"
	c.shader = CARD_SHADER
	m[KEY_CARDS] = c
	sync_cards(m)
	return c


## Copies the three card materials' current values into the merged card material.
static func sync_cards(m: Dictionary) -> void:
	if not m.has(KEY_CARDS):
		return
	var c: ShaderMaterial = m[KEY_CARDS]
	for u: Array in CARD_UNIFORMS:
		var nm: StringName = u[0]
		var typ: String = u[1]
		var srgb: bool = u[2]
		var vals: Array = []
		for i: int in 4:
			var src: ShaderMaterial = m.get(CARD_KEYS[mini(i, CARD_KEYS.size() - 1)])
			vals.append(MatSync.param(src, nm))   # value, else the shader default (cached: no RenderingServer call)
		match typ:
			"int":
				var a := PackedInt32Array()
				for v: Variant in vals:
					a.append(int(v) if v != null else 0)
				MatSync.put(c, StringName(String(nm) + "_c"), a)
			"float":
				var f := PackedFloat32Array()
				for v: Variant in vals:
					f.append(float(v) if v != null else 0.0)
				MatSync.put(c, StringName(String(nm) + "_c"), f)
			"vec3":
				var a3 := PackedVector3Array()
				for v: Variant in vals:
					var col: Color = Color.WHITE
					if v is Color:
						col = v
					elif v is Vector3:
						col = Color((v as Vector3).x, (v as Vector3).y, (v as Vector3).z)
					if srgb:
						col = col.srgb_to_linear()
					a3.append(Vector3(col.r, col.g, col.b))
				MatSync.put(c, StringName(String(nm) + "_c"), a3)


## [ArrayMesh, source surface per new surface (-1 = merged painted, -2 = merged cards)], cached per mesh + ids.
## ids per source surface: -1..7 painted index (-1 = Void), CARD_BASE + n card channel, KEEP = left as it was.
static func _bake(mesh: Mesh, ids: PackedInt32Array) -> Array:
	var key := "%d|%s" % [mesh.get_instance_id(), ids]
	if _cache.has(key):
		var hit: Array = _cache[key]
		return [hit[1], hit[2]]
	var am := ArrayMesh.new()
	var src_of: Array = []
	for grp: int in 2:
		var V := PackedVector3Array()
		var N := PackedVector3Array()
		var U := PackedVector2Array()
		var U2 := PackedVector2Array()
		var C := PackedColorArray()
		var K := PackedFloat32Array()
		var I := PackedInt32Array()
		for s: int in mesh.get_surface_count():
			var id: int = ids[s]
			if id == KEEP or (grp == 0) != (id < CARD_BASE):
				continue
			var ch: float = float(id if grp == 0 else id - CARD_BASE)
			var a: Array = mesh.surface_get_arrays(s)
			var sv: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
			var n: int = sv.size()
			var base: int = V.size()
			V.append_array(sv)
			N.append_array(_v3(a[Mesh.ARRAY_NORMAL], n, Vector3.UP))
			U.append_array(_v2(a[Mesh.ARRAY_TEX_UV], n))
			U2.append_array(_v2(a[Mesh.ARRAY_TEX_UV2], n))
			var sc: Variant = a[Mesh.ARRAY_COLOR]
			if sc is PackedColorArray and (sc as PackedColorArray).size() == n:
				C.append_array(sc)
			else:
				for k: int in n:
					C.append(Color.WHITE)
			for k: int in n:
				K.append(ch)
			var si: Variant = a[Mesh.ARRAY_INDEX]
			if si is PackedInt32Array and (si as PackedInt32Array).size() > 0:
				for idx: int in (si as PackedInt32Array):
					I.append(base + idx)
			else:
				for t: int in n:
					I.append(base + t)
		if V.is_empty():
			continue
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = V
		arr[Mesh.ARRAY_NORMAL] = N
		arr[Mesh.ARRAY_TEX_UV] = U
		arr[Mesh.ARRAY_TEX_UV2] = U2
		arr[Mesh.ARRAY_COLOR] = C
		arr[Mesh.ARRAY_CUSTOM0] = K
		arr[Mesh.ARRAY_INDEX] = I
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {},
			Mesh.ARRAY_CUSTOM_R_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
		src_of.append(-1 - grp)
	for s: int in mesh.get_surface_count():
		if ids[s] != KEEP:
			continue
		MeshBake.copy_surface(am, mesh, s)   # keeps the custom-channel format (PaintedVC does the same)
		src_of.append(s)
	_cache[key] = [mesh, am, src_of]
	return [am, src_of]


static func _v3(v: Variant, n: int, fallback: Vector3) -> PackedVector3Array:
	if v is PackedVector3Array and (v as PackedVector3Array).size() == n:
		return v
	var out := PackedVector3Array()
	out.resize(n)
	out.fill(fallback)
	return out


static func _v2(v: Variant, n: int) -> PackedVector2Array:
	if v is PackedVector2Array and (v as PackedVector2Array).size() == n:
		return v
	var out := PackedVector2Array()
	out.resize(n)
	return out
