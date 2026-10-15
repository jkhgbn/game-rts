class_name ChampionPalette
extends RefCounted
## B8 material merge for the champions (champions.md 4.6: <= 5 materials per champion; in-game grade 2026-09-30).
## Every part painted with the kit's `unit_painted.gdshader` (the champion's own leather / coat / iron / skin .tres and
## the shared kit palette entries) is FOLDED into one per-champion ShaderMaterial (`champion_palette.gdshader`): the
## part's mesh is copied once with UV.x = the palette index of its material (the kit merge keeps UV), and the palette
## arrays take that material's base_color / spec_strength / rim_strength. The authored .tres files stay the source of
## the colours (change a colour there, not here). Not folded (they need their own material): team cloth (banner shader,
## recoloured by set_team_color), glows (unit_glow: glow_boost / rune bands), the face kit, the shadow blob, particles
## and any painted material with cracks / damage.
## Static, cached per champion key: a 2nd instance gets the same material and the same meshes (B9: 0 per instance).
## Use: `var r := ChampionPalette.fold(key, mesh, mat)` -> [mesh, material_override] for add_part (the override is
## null when the mesh carries per-surface materials); `ChampionPalette.fold_mesh(key, mesh)` for a mesh swapped at
## runtime (variant pieces).

const SHADER := preload("res://art/units/champions/champion_palette.gdshader")
const PAINTED_PATH := "res://art/units/kit/unit_painted.gdshader"
const GLOW_PATH := "res://art/units/kit/unit_glow.gdshader"
const NOISE_PATH := "res://art/shaders/paint_noise.tres"
const PAL_MAX := 32

static var _mats: Dictionary = {}       # key -> ShaderMaterial
static var _index: Dictionary = {}      # key -> {material instance id: palette index}
static var _colors: Dictionary = {}     # key -> PackedVector4Array
static var _extras: Dictionary = {}     # key -> PackedVector4Array
static var _meshes: Dictionary = {}     # "key|mesh id|override id" -> Mesh
static var _tints: Dictionary = {}      # key -> {material file basename: sRGB Color} (per-champion colour of a shared entry)


## Per-champion colour for a SHARED palette material (e.g. a kit `nature_bark_dark` entry): this champion's palette
## entry takes `color` (sRGB) instead of the material's base_color; the shared .tres stays untouched for everyone else.
## Call it before the first fold of that key (the model's _build_parts start).
static func tint(key: String, material_name: String, color: Color) -> void:
	if not _tints.has(key):
		_tints[key] = {}
	(_tints[key] as Dictionary)[material_name] = color


## The champion's shared palette material (built on first use).
static func material(key: String) -> ShaderMaterial:
	if not _mats.has(key):
		var m := ShaderMaterial.new()
		m.shader = SHADER
		m.resource_name = key + "_palette"
		m.set_meta(&"pal_srcs", [])   # palette index -> the folded source material (tools / tests: source_of)
		if ResourceLoader.exists(NOISE_PATH):
			m.set_shader_parameter(&"noise_tex", load(NOISE_PATH))
		var c := PackedVector4Array()
		var e := PackedVector4Array()
		c.resize(PAL_MAX)
		e.resize(PAL_MAX)
		for i: int in PAL_MAX:
			c[i] = Vector4(0.2, 0.2, 0.2, 1.0)
			e[i] = Vector4(0.0, 0.25, 0.0, 0.0)
		_mats[key] = m
		_index[key] = {}
		_colors[key] = c
		_extras[key] = e
		m.set_shader_parameter(&"pal_color", c)
		m.set_shader_parameter(&"pal_extra", e)
	return _mats[key]


## True when `mat` is a plain painted material (or a plain kit glow) that the palette can stand in for.
static func foldable(mat: Material) -> bool:
	if not mat is ShaderMaterial:
		return false
	var sm := mat as ShaderMaterial
	if sm.shader == null or is_team(mat):
		return false
	if sm.shader.resource_path == GLOW_PATH:
		var bands: Variant = sm.get_shader_parameter(&"rune_bands")
		return bands == null or int(bands) <= 0
	if sm.shader.resource_path != PAINTED_PATH:
		return false
	var crack: Variant = sm.get_shader_parameter(&"crack_strength")
	var dmg: Variant = sm.get_shader_parameter(&"damage")
	return (crack == null or float(crack) <= 0.0) and (dmg == null or float(dmg) <= 0.0)


## True for the kit's team-coloured materials (CharacterModel._team_variant: `*_cloth`, `*_cloth_dark`, `*_cape`,
## `*_cape_plain`, `*_pennon`): set_team_color swaps them per colour, so they keep their own material.
static func is_team(mat: Material) -> bool:
	if mat == null:
		return false
	var nm := mat.resource_path.get_file().get_basename()
	return nm.ends_with("_cloth") or nm.ends_with("_cloth_dark") or nm.ends_with("_cape") \
		or nm.ends_with("_cape_plain") or nm.ends_with("_pennon")


## Palette index of a painted material (added on first use; -1 when the palette is full).
static func index_of(key: String, mat: Material) -> int:
	var pm := material(key)
	var idx: Dictionary = _index[key]
	var id := mat.get_instance_id()
	if idx.has(id):
		return int(idx[id])
	# Look-alike entries (same colour, spec and rim) share one index.
	var sm := mat as ShaderMaterial
	var glow := sm.shader.resource_path == GLOW_PATH
	var bc: Variant = sm.get_shader_parameter(&"glow_color" if glow else &"base_color")
	var col: Color = bc if bc is Color else (Color(bc.x, bc.y, bc.z) if bc is Vector3 else Color(0.3, 0.26, 0.24))
	var tk: Dictionary = _tints.get(key, {})
	var bn := mat.resource_path.get_file().get_basename()
	if tk.has(bn):
		col = tk[bn]
	var lin := col.srgb_to_linear()
	var cv := Vector4(lin.r, lin.g, lin.b, 1.0)
	var ev: Vector4
	if glow:
		var en: Variant = sm.get_shader_parameter(&"energy")
		var bo: Variant = sm.get_shader_parameter(&"boost")
		var ps: Variant = sm.get_shader_parameter(&"pulse_speed")
		ev = Vector4(0.0, 0.0, maxf(0.01, (float(en) if en != null else 3.0) * (float(bo) if bo != null else 1.0)),
			float(ps) if ps != null else 2.0)
	else:
		var sp: Variant = sm.get_shader_parameter(&"spec_strength")
		var rs: Variant = sm.get_shader_parameter(&"rim_strength")
		ev = Vector4(float(sp) if sp != null else 0.0, float(rs) if rs != null else 0.25, 0.0, 0.0)
	var c: PackedVector4Array = _colors[key]
	var e: PackedVector4Array = _extras[key]
	for other: int in idx:
		var j := int(idx[other])
		if c[j].is_equal_approx(cv) and e[j].is_equal_approx(ev):
			idx[id] = j
			return j
	var n := 0
	for other2: int in idx:
		n = maxi(n, int(idx[other2]) + 1)
	if n >= PAL_MAX:
		push_warning("ChampionPalette %s: palette full" % key)
		return -1
	c[n] = cv
	e[n] = ev
	var srcs: Array = pm.get_meta(&"pal_srcs")
	while srcs.size() <= n:
		srcs.append(null)
	srcs[n] = mat
	_colors[key] = c
	_extras[key] = e
	pm.set_shader_parameter(&"pal_color", c)
	pm.set_shader_parameter(&"pal_extra", e)
	idx[id] = n
	return n


## [mesh, material_override] for a part: painted parts (override or per-surface) move onto the palette material.
static func fold(key: String, mesh: Mesh, mat: Material) -> Array:
	if mesh == null:
		return [mesh, mat]
	if mat != null:
		if not foldable(mat):
			return [mesh, mat]
		var i := index_of(key, mat)
		if i < 0:
			return [mesh, mat]
		return [_folded(key, mesh, mat), material(key)]
	return [fold_mesh(key, mesh), null]


## A copy of `mesh` whose painted surfaces draw with the palette material (other surfaces unchanged). Cached.
static func fold_mesh(key: String, mesh: Mesh) -> Mesh:
	if mesh == null:
		return null
	var any := false
	for s: int in mesh.get_surface_count():
		if foldable(mesh.surface_get_material(s)):
			any = true
			break
	if not any:
		return mesh
	return _folded(key, mesh, null)


static func _folded(key: String, mesh: Mesh, override: Material) -> Mesh:
	var ck := "%s|%d|%d" % [key, mesh.get_instance_id(), override.get_instance_id() if override else 0]
	if _meshes.has(ck):
		return _meshes[ck]
	var pm := material(key)
	var am := ArrayMesh.new()
	# Surfaces that end on the same material are appended into one surface (fewer draw calls).
	var groups: Dictionary = {}   # Material -> arrays accumulators
	var order: Array = []
	for s: int in mesh.get_surface_count():
		var src: Material = override if override else mesh.surface_get_material(s)
		var arr := mesh.surface_get_arrays(s)
		var dst: Material = src
		var idx := -1
		if foldable(src):
			idx = index_of(key, src)
			if idx >= 0:
				dst = pm
		var key2: Variant = dst
		if not groups.has(key2):
			groups[key2] = [PackedVector3Array(), PackedVector3Array(), PackedFloat32Array(), PackedVector2Array(),
				PackedInt32Array(), dst, PackedColorArray()]
			order.append(key2)
		var acc: Array = groups[key2]
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var nr: PackedVector3Array = arr[Mesh.ARRAY_NORMAL] if arr[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
		var tg: PackedFloat32Array = arr[Mesh.ARRAY_TANGENT] if arr[Mesh.ARRAY_TANGENT] != null else PackedFloat32Array()
		var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
		var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var co: PackedColorArray = arr[Mesh.ARRAY_COLOR] if arr[Mesh.ARRAY_COLOR] != null else PackedColorArray()
		var base: int = (acc[0] as PackedVector3Array).size()
		for j: int in v.size():
			acc[0].append(v[j])
			acc[1].append(nr[j] if j < nr.size() else Vector3.UP)
			if j * 4 + 3 < tg.size():
				acc[2].append_array(PackedFloat32Array([tg[j * 4], tg[j * 4 + 1], tg[j * 4 + 2], tg[j * 4 + 3]]))
			else:
				acc[2].append_array(PackedFloat32Array([1.0, 0.0, 0.0, 1.0]))
			if idx >= 0:
				acc[3].append(Vector2(float(idx), 0.0))
			else:
				acc[3].append(uv[j] if j < uv.size() else Vector2.ZERO)
			acc[6].append(co[j] if j < co.size() else Color.WHITE)
		if ix.is_empty():
			for j: int in v.size():
				acc[4].append(base + j)
		else:
			for j: int in ix.size():
				acc[4].append(base + ix[j])
	for k: Variant in order:
		var acc2: Array = groups[k]
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = acc2[0]
		arrays[Mesh.ARRAY_NORMAL] = acc2[1]
		arrays[Mesh.ARRAY_TANGENT] = acc2[2]
		arrays[Mesh.ARRAY_TEX_UV] = acc2[3]
		arrays[Mesh.ARRAY_INDEX] = acc2[4]
		arrays[Mesh.ARRAY_COLOR] = acc2[6]
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		am.surface_set_material(am.get_surface_count() - 1, acc2[5])
	am.resource_name = mesh.resource_name
	_meshes[ck] = am
	return am


static var _mote_mat: Dictionary = {}   # key -> the champion's one mote draw material
static var _mote_quads: Dictionary = {} # "key|size" -> QuadMesh drawing with it

## One mote draw material per champion (B8): every GPUParticles3D of the model built with the kit's make_motes() draws
## with the material of the first one passed here (same additive round mote; its colour wins), each at its own quad
## size. Call it first on the system whose colour the champion should keep.
static func share_motes(key: String, p: GPUParticles3D) -> void:
	if p == null or not p.draw_pass_1 is QuadMesh:
		return
	var q := p.draw_pass_1 as QuadMesh
	if not _mote_mat.has(key):
		_mote_mat[key] = q.material
		return
	if q.material == _mote_mat[key]:
		return
	var mk := "%s|%s" % [key, q.size]
	if not _mote_quads.has(mk):
		var nq := QuadMesh.new()
		nq.size = q.size
		nq.material = _mote_mat[key]
		_mote_quads[mk] = nq
	p.draw_pass_1 = _mote_quads[mk]



# ================================================================ read-back (tests, tools)

## The source material a palette vertex stands for (`uv_x` = its UV.x), or null when `mat` is not a palette material.
static func source_of(mat: Material, uv_x: float) -> Material:
	if mat == null or not mat.has_meta(&"pal_srcs"):
		return null
	var srcs: Array = mat.get_meta(&"pal_srcs")
	var i := int(uv_x + 0.5)
	return srcs[i] if i >= 0 and i < srcs.size() else null


## Vertices of `mesh` drawn with a material whose file name contains `part`: plain surfaces by their material, palette
## surfaces per vertex by the source material of its palette entry. `overrides` = per-surface override materials.
static func vertices_of(mesh: Mesh, part: String, overrides: Array = []) -> PackedVector3Array:
	var out := PackedVector3Array()
	if mesh == null:
		return out
	for s: int in mesh.get_surface_count():
		var mat: Material = overrides[s] if s < overrides.size() and overrides[s] != null else mesh.surface_get_material(s)
		if mat == null:
			continue
		var arr := mesh.surface_get_arrays(s)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		if mat.has_meta(&"pal_srcs"):
			var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
			for j: int in mini(v.size(), uv.size()):
				var src := source_of(mat, uv[j].x)
				if src and src.resource_path.get_file().contains(part):
					out.append(v[j])
		elif mat.resource_path.get_file().contains(part):
			out.append_array(v)
	return out


## True when some part of `mesh` is drawn with (or folded from) a material whose file name contains `part`.
static func mesh_has(mesh: Mesh, part: String) -> bool:
	return not vertices_of(mesh, part).is_empty()


## The materials a model really draws with, the palette material replaced by its folded sources (for material
## budget / folder tests written before the fold).
static func unfold(mats: Array) -> Array:
	var out: Array = []
	for m: Material in mats:
		if m and m.has_meta(&"pal_srcs"):
			for src: Variant in m.get_meta(&"pal_srcs"):
				if src and not (src in out):
					out.append(src)
		elif not (m in out):
			out.append(m)
	return out


# ================================================================ class weapon crystal glow

## The kit drives a class weapon's glow (the Wizard staff crystal: WEAPON_GLOW_BASE x the level + the pose flares)
## only on a pivot whose archetype merge had no glow material. With the palette material every merged pivot declares
## `glow_boost`, so the kit would leave the crystal to the plain glow level: each champion calls this from its
## `_on_weapon_class` to hand the crystal pivot (ArmR) back to the kit's weapon-glow drive (and back again on &"").
static func claim_crystal_glow(m: CharacterModel, class_id: StringName) -> void:
	var arm: MeshInstance3D = m._merged_nodes.get(CharacterModel.P_ARM_R)
	if arm == null:
		return
	if class_id == &"wizard":
		m._glow_nodes.erase(arm)
		if not m._wk_glow_added.has(arm):
			m._wk_glow_added.append(arm)
		arm.set_meta(&"own_glow", true)
		arm.set_instance_shader_parameter(&"glow_boost", m.glow_level() * CharacterModel.WEAPON_GLOW_BASE)
		m._wk_flare_written = -1.0
	elif m._wk_glow_added.has(arm):
		m._wk_glow_added.erase(arm)
		arm.remove_meta(&"own_glow")
		if not m._glow_nodes.has(arm):
			m._glow_nodes.append(arm)
