class_name CrownIsleVariant
extends Node3D
## G-F crown isle variants (docs/art/gf_crown_isle.md): one map's own look of the Crown Isle, art only. Created by
## crown_isle_look.gd (from the Ember Crown's altar, CrownPedestalArt), a child of the level named "CrownIsleVariant".
## Variants: &"thornwater" a drowned, overgrown ruin; &"quartermeet" a harvest-highland stone circle; &"neutral" a
## weathered ruin (every other layout map). Crown Hollow, the missions and the menus never get one.
##
## Every tier (no new draw, material, shader, light or particle; level-local nodes only, nothing shared is changed):
##   - the isle's ruin pillars (EnvProps "RuinPillar" MultiMesh): a level-local MultiMesh copy drawing a repainted
##     copy of the pillar mesh (crown_isle_meshes.gd)
##   - the altar's rubble ring ("RuinDressing") and the crown bridges / steps near the isle: repainted mesh copies
##     (stone only: the gold trims, the ember coals, the altar, its runes, seal and beacon are untouched, so the Ember
##     Crown reads the same on every map)
##   - the isle paving: the level's own ground material `paving_color`
## Medium+ (MultiMeshes, draw-only, no collider, nothing on nav layers; ~4-7 draws):
##   thornwater   about half the pillars broken to mossy stumps (the collider stays: a stump still reads as the
##                obstacle) with their fallen drums beside them, rushes along the isle rim, lily pads at its
##                waterline, rain puddles and sunk flagstones on the paving, mossy boulders
##   quartermeet  every pillar standing, a straw harvest garland on each, a low drystone edging round the isle rim
##                (gaps at the crossings), small stooks at the pillar feet, heather and lichen stones on the rim
##   neutral      a quarter of the pillars broken, fallen drums, sunk flagstones, a few boulders
## Kept clear: the altar dais (r < 3.8), the lanes from each crossing to the crown (2.6 m either side), the water,
## the bridges. Leaving the tree puts every swapped mesh / multimesh / paving value back on the level's nodes.

const MESHES := "res://art/environment/crown_variants/crown_isle_meshes.gd"
const B := "res://art/environment/biomes/"
const PILLAR_MESH := "res://art/environment/meshes/ruin_pillar.res"
const PILLAR_ART_HEIGHT := 3.0    ## EnvProps.PILLAR_ART_HEIGHT
const DRUMS := B + "ruins/ruins_drums.res"
const FLAGS := B + "ruins/ruins_flagstones.res"
const RUSHES := B + "marsh/marsh_rushes.res"
const PUDDLES := B + "marsh/marsh_puddles.res"
const BOULDERS := B + "old_wood/ow_moss_boulders.res"
const LILY := B + "riverbank/rb_lily_pads.res"
const HEATHER := B + "heath/heath_heather.res"
const LICHEN := B + "heath/heath_lichen_stones.res"
const QM_MESHES := "res://art/environment/quartermeet/quartermeet_meshes.gd"
## Kinds built in code, keyed like a path.
const STUMP := "isle:stump"
const GARLAND := "isle:garland"
const EDGING := "quartermeet:wall"
const STOOK := "quartermeet:stook"
const SHADOW_KINDS: Array[String] = [STUMP, DRUMS, BOULDERS, EDGING, STOOK, LICHEN]
const RECOLOR_KINDS: Array[String] = [DRUMS, FLAGS]
const WATER_Y := -0.35
const DAIS_CLEAR := 3.8
const LANE_HALF := 2.6
const PAVING := {
	&"thornwater": Color(0.37, 0.39, 0.33),
	&"quartermeet": Color(0.55, 0.565, 0.565),
	&"neutral": Color(0.50, 0.48, 0.44),
}
## Share of the isle pillars broken to stumps (Medium+).
const STUMP_SHARE := {&"thornwater": 0.5, &"quartermeet": 0.0, &"neutral": 0.25}

var variant: StringName = &""
var quality := 0
var counts := {}                       ## kind -> instances placed (tests)
var center := Vector2.ZERO             ## isle centre (xz)
var inner_r := 11.0                    ## the isle's land radius (moat inner edge)
var pillars: Array[Dictionary] = []    ## isle pillars {pos: Vector3, h: float, stump: bool}
var _level: Node
var _pedestal: Node
var _river: Node
var _crossings: Array[Dictionary] = [] ## isle crossings {a: angle, half: half angle, c: Vector2}
var _swapped: Array = []               ## [object, property, original value]
var _lists := {}                       ## kind -> Array[Transform3D]
var _mmis: Array[MultiMeshInstance3D] = []
var _rng := RandomNumberGenerator.new()
var _built := false


## Sets the variant up (before add_child): `level` the LayoutLevel, `pedestal` the CrownPedestalArt (may be null).
func setup(level: Node, pedestal: Node, v: StringName, q: int) -> void:
	_level = level
	_pedestal = pedestal
	variant = v
	quality = clampi(q, 0, 3)


func _ready() -> void:
	add_to_group(&"lighting_rigs")   # GameSettings.apply_graphics -> set_quality (Medium+ props on / off)
	build()


func _exit_tree() -> void:
	_restore()


## GameSettings.apply_graphics (group "lighting_rigs").
func set_quality(q: int) -> void:
	q = clampi(q, 0, 3)
	if q == quality and _built:
		return
	quality = q
	build()


## (Re)builds everything for the current variant and tier. Returns the instances placed (Medium+ props).
func build() -> int:
	_restore()
	_clear_props()
	counts.clear()
	_built = true
	if _level == null or not _variant_ok():
		return 0
	_read_isle()
	_rng.seed = hash("crown_isle:%s" % variant)
	_paving()
	_recolor_crossings()
	_recolor_rubble()
	_pillars()
	if quality >= 1:
		match variant:
			&"thornwater":
				_thornwater_props()
			&"quartermeet":
				_quartermeet_props()
			_:
				_neutral_props()
		_commit()
	var n := 0
	for k: Variant in counts:
		n += int(counts[k])
	return n


func _variant_ok() -> bool:
	return PAVING.has(variant)


## CPU copies of one kind's instance transforms (tests: the headless renderer keeps no MultiMesh data).
func instance_transforms(kind: String) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	for xf: Variant in _lists.get(kind, []):
		out.append(xf as Transform3D)
	return out


## The draws this node added (Medium+ only; Low = 0).
func draw_count() -> int:
	return _mmis.size()


## True when `p` (xz) is on a lane from an isle crossing to the crown, on the dais, or off the isle's land.
func blocked(p: Vector2, pad: float = 0.0) -> bool:
	var d := p.distance_to(center)
	if d < DAIS_CLEAR + pad or d > inner_r - 0.25 - pad:
		return true
	for c: Dictionary in _crossings:
		var cp: Vector2 = c["c"]
		var seg := center - cp
		var t := clampf((p - cp).dot(seg) / maxf(seg.length_squared(), 0.001), 0.0, 1.0)
		if p.distance_to(cp + seg * t) < LANE_HALF + pad:
			return true
	return false


# ---------------------------------------------------------------- reading the isle

func _read_isle() -> void:
	center = Vector2.ZERO
	var crown: Variant = _level.get(&"crown") if &"crown" in _level else null
	if _pedestal is Node3D and (_pedestal as Node3D).is_inside_tree():
		var gp := (_pedestal as Node3D).global_position
		center = Vector2(gp.x, gp.z)
	elif crown is Node3D:
		center = Vector2((crown as Node3D).global_position.x, (crown as Node3D).global_position.z)
	_river = null
	if _level.is_inside_tree():
		for r: Node in _level.get_tree().get_nodes_in_group(&"river"):
			if _level.is_ancestor_of(r) and not r.is_queued_for_deletion():
				_river = r
				break
	inner_r = 11.0
	if _river and _river.has_method(&"moat"):
		var m: Vector4 = _river.call(&"moat")
		if m.z > 0.0 and Vector2(m.x, m.y).distance_to(center) < 2.0:
			inner_r = m.z - m.w
	_crossings.clear()
	if _river and _river.has_method(&"crossings"):
		for c: Dictionary in _river.call(&"crossings"):
			var cc: Vector3 = c.get("center", Vector3.ZERO)
			var cp := Vector2(cc.x, cc.z)
			if cp.distance_to(center) > inner_r + 6.0:
				continue
			var w := float(c.get("width", float(c.get("radius", 2.0)) * 2.0))
			_crossings.append({"a": atan2(cp.y - center.y, cp.x - center.x), "c": cp,
				"half": atan((w * 0.5 + 1.4) / inner_r)})
	pillars.clear()
	var plan: Variant = _level.get(&"forest_plan") if &"forest_plan" in _level else null
	if plan is Dictionary:
		for pl: Dictionary in (plan as Dictionary).get("pillars", []):
			var pp: Vector3 = pl.get("pos", Vector3.ZERO)
			if Vector2(pp.x, pp.z).distance_to(center) <= inner_r:
				pillars.append({"pos": pp, "h": float(pl.get("h", 3.0)), "stump": false})


func _crossing_gap(a: float, extra: float = 0.0) -> bool:
	for c: Dictionary in _crossings:
		if absf(angle_difference(a, float(c["a"]))) < float(c["half"]) + extra:
			return true
	return false


func _is_water(p: Vector2) -> bool:
	return _river != null and _river.has_method(&"is_water") and bool(_river.call(&"is_water", Vector3(p.x, 0.0, p.y)))


# ---------------------------------------------------------------- every tier: swaps

func _swap(obj: Object, prop: StringName, value: Variant) -> void:
	_swapped.append([obj, prop, obj.get(prop)])
	obj.set(prop, value)


func _restore() -> void:
	for i: int in range(_swapped.size() - 1, -1, -1):
		var e: Array = _swapped[i]
		var obj: Object = e[0]
		if is_instance_valid(obj):
			if obj is ShaderMaterial:
				(obj as ShaderMaterial).set_shader_parameter(e[1], e[2])
			else:
				obj.set(e[1], e[2])
	_swapped.clear()


## The isle paving on the level's own ground material(s) (never the shared ground_material.tres).
func _paving() -> void:
	var seen := {}
	for node: Node in _level.find_children("*", "GeometryInstance3D", true, false):
		var gi := node as GeometryInstance3D
		var sm := gi.material_override as ShaderMaterial
		if sm == null or seen.has(sm) or sm.shader == null or not sm.shader.resource_path.ends_with("ground.gdshader"):
			continue
		if sm.resource_path != "" and not sm.resource_path.contains("::"):
			continue   # a shared .tres: never touched
		seen[sm] = true
		_swapped.append([sm, &"paving_color", sm.get_shader_parameter(&"paving_color")])
		sm.set_shader_parameter(&"paving_color", PAVING[variant])
	counts["paving"] = seen.size()


func _recolor_crossings() -> void:
	if _river == null:
		return
	var cm := load(MESHES) as Script
	var n := 0
	for node: Node in (_river as Node).find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null or not mi.is_inside_tree():
			continue
		var gp := mi.global_position
		if Vector2(gp.x, gp.z).distance_to(center) > inner_r + 6.5:
			continue
		var painted := false
		for s: int in mi.mesh.get_surface_count():
			painted = painted or bool(cm.call(&"is_painted_surface", mi.mesh, s))
		if not painted:
			continue
		_swap(mi, &"mesh", cm.call(&"recolored", mi.mesh, variant))
		n += 1
	counts["crossings"] = n


func _recolor_rubble() -> void:
	if _pedestal == null:
		return
	var rd := (_pedestal as Node).get_node_or_null(^"RuinDressing") as MeshInstance3D
	if rd and rd.mesh:
		_swap(rd, &"mesh", (load(MESHES) as Script).call(&"recolored", rd.mesh, variant))
		counts["rubble"] = 1


## The isle pillars: a level-local MultiMesh copy with the repainted mesh (every tier) and, Medium+, the stumps
## moved to their own MultiMesh.
func _pillars() -> void:
	var env: Variant = _level.get(&"env_props") if &"env_props" in _level else null
	var mmi := (env as Node).get_node_or_null(^"RuinPillar") as MultiMeshInstance3D if env is Node else null
	if mmi == null or mmi.multimesh == null or mmi.multimesh.mesh == null or pillars.is_empty():
		counts["pillars"] = 0
		return
	var mm := mmi.multimesh
	var all := _pillar_transforms(mm)
	var isle_only := true
	for xf: Transform3D in all:
		if Vector2(xf.origin.x, xf.origin.z).distance_to(center) > inner_r:
			isle_only = false
	if not isle_only and quality < 1:
		counts["pillars"] = 0
		return   # mixed MultiMesh: Low keeps it as it is (splitting it would add a draw)
	var cm := load(MESHES) as Script
	var src := mm.mesh
	# Medium+: stumps (symmetric pairs: the hash of the angle modulo PI, so the point mirror matches).
	var share: float = STUMP_SHARE[variant]
	if quality >= 1 and share > 0.0:
		var order: Array = []
		for i: int in pillars.size():
			var pp: Vector3 = pillars[i]["pos"]
			var a := fposmod(atan2(pp.z - center.y, pp.x - center.x), PI)
			order.append([_hash1(snappedf(a, 0.01) + 0.37), i])
		order.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
		var want := int(roundf(pillars.size() * share))
		for k: int in order.size():
			pillars[order[k][1]]["stump"] = k < want
	var keep: Array[Transform3D] = []
	var stumps: Array[Transform3D] = []
	var isle_xf: Array[Transform3D] = []
	for xf: Transform3D in all:
		var p2 := Vector2(xf.origin.x, xf.origin.z)
		var on_isle := p2.distance_to(center) <= inner_r
		var is_stump := false
		if on_isle:
			for pl: Dictionary in pillars:
				var pp: Vector3 = pl["pos"]
				if Vector2(pp.x, pp.z).distance_to(p2) < 0.05:
					is_stump = bool(pl["stump"])
		if is_stump:
			var yaw := xf.basis.get_euler().y
			stumps.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(1.0, 1.0 + _hash1(p2.x + p2.y) * 0.25, 1.0)),
				Vector3(xf.origin.x, 0.0, xf.origin.z)))
		elif on_isle and not isle_only:
			isle_xf.append(xf)
		else:
			keep.append(xf)
	var copy := MultiMesh.new()
	copy.transform_format = MultiMesh.TRANSFORM_3D
	copy.mesh = cm.call(&"recolored", src, variant) if isle_only else src
	copy.instance_count = keep.size()
	for i: int in keep.size():
		copy.set_instance_transform(i, keep[i])
	_swap(mmi, &"multimesh", copy)
	counts["pillars"] = keep.size() if isle_only else isle_xf.size()
	if not isle_xf.is_empty():
		_lists["isle:pillar"] = isle_xf
	if not stumps.is_empty():
		_lists[STUMP] = stumps
		counts[STUMP] = stumps.size()
		for xf: Transform3D in stumps:   # fallen drums beside each stump, lying on the outer side
			var out := (Vector2(xf.origin.x, xf.origin.z) - center).normalized()
			for j: int in 1 + int(_rng.randf() < 0.6):
				var side := out.rotated(_rng.randf_range(-1.1, 1.1))
				var q := Vector2(xf.origin.x, xf.origin.z) + side * _rng.randf_range(1.1, 1.8)
				if not blocked(q, 0.3) and not _is_water(q):
					_add(DRUMS, Vector3(q.x, -0.04, q.y), _rng.randf_range(0.95, 1.25))
	pillars_mesh_src = src


var pillars_mesh_src: Mesh   ## the original pillar mesh (stumps are cut from it)


## The pillar MultiMesh's transforms; the headless dummy renderer keeps none (all identity), so they are rebuilt from
## the plan with EnvProps.add_pillar's formula.
func _pillar_transforms(mm: MultiMesh) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	var real := false
	for i: int in mm.instance_count:
		var xf := mm.get_instance_transform(i)
		out.append(xf)
		real = real or xf.origin.length_squared() > 0.0001
	if real:
		return out
	out.clear()
	var plan: Variant = _level.get(&"forest_plan") if &"forest_plan" in _level else null
	if plan is Dictionary:
		for pl: Dictionary in (plan as Dictionary).get("pillars", []):
			var pos: Vector3 = pl.get("pos", Vector3.ZERO)
			var h01 := fposmod(sin(pos.x * 12.9898 + pos.z * 78.233) * 43758.5453, 1.0)
			out.append(Transform3D(Basis(Vector3.UP, h01 * TAU).scaled(
				Vector3(1.0, float(pl.get("h", 3.0)) / PILLAR_ART_HEIGHT, 1.0)), pos))
	return out


# ---------------------------------------------------------------- Medium+: props

func _thornwater_props() -> void:
	_rim(RUSHES, 30, 0.75, 1.15, 0.25, 1.4)
	_paving_scatter(PUDDLES, 7, 0.7, 1.0, 1.4, -0.03)
	_paving_scatter(FLAGS, 12, 0.8, 1.1, 0.9, -0.09)
	_rim(BOULDERS, 5, 0.42, 0.62, 0.6, 1.6)
	# Lily pads at the isle's waterline (in the moat, clear of the crossings).
	var placed := 0
	for k: int in 40:
		if placed >= 8:
			break
		var a := _rng.randf() * TAU
		if _crossing_gap(a, 0.25):
			continue
		var p := center + Vector2(cos(a), sin(a)) * (inner_r + _rng.randf_range(0.5, 1.3))
		if _is_water(p):
			_add(LILY, Vector3(p.x, WATER_Y + 0.02, p.y), _rng.randf_range(0.55, 0.8))
			placed += 1


func _quartermeet_props() -> void:
	# A straw garland on every standing isle pillar, ~58 % up its height.
	for pl: Dictionary in pillars:
		if bool(pl["stump"]):
			continue
		var pp: Vector3 = pl["pos"]
		var h: float = pl["h"]
		var xf := Transform3D(Basis(Vector3.UP, _hash1(pp.x * 3.1 + pp.z) * TAU), pp + Vector3(0.0, h * 0.58, 0.0))
		_lists[GARLAND] = _lists.get(GARLAND, []) + [xf]
		counts[GARLAND] = int(counts.get(GARLAND, 0)) + 1
		# A small stook at the foot of every other pillar (outer side).
		if _hash1(pp.x + pp.z * 1.7) < 0.55:
			var out := (Vector2(pp.x, pp.z) - center).normalized().rotated(_rng.randf_range(-0.6, 0.6))
			var q := Vector2(pp.x, pp.z) + out * 1.15
			if not blocked(q, 0.2) and not _is_water(q):
				_add(STOOK, Vector3(q.x, 0.0, q.y), _rng.randf_range(0.62, 0.78))
	# The drystone edging: low wall segments round the rim, gaps at the crossings and a few fallen gaps.
	var r := inner_r - 0.7
	var step := 2.3 / r
	var a := 0.0
	while a < TAU - step * 0.5:
		var mid := a + step * 0.5
		if not _crossing_gap(mid, step * 0.6) and _hash1(mid * 5.3) > 0.12:
			var p := center + Vector2(cos(mid), sin(mid)) * r
			if not _is_water(p):
				var wb := Basis(Vector3.UP, -mid - PI * 0.5).scaled(Vector3(0.95, 0.55 + _hash1(mid) * 0.12, 0.62))
				_lists[EDGING] = _lists.get(EDGING, []) + [Transform3D(wb, Vector3(p.x, -0.02, p.y))]
				counts[EDGING] = int(counts.get(EDGING, 0)) + 1
		a += step
	_rim(HEATHER, 16, 0.55, 0.85, 0.2, 1.2, 1.6)
	_rim(LICHEN, 6, 0.5, 0.7, 0.3, 1.8, 1.8)


func _neutral_props() -> void:
	_paving_scatter(FLAGS, 9, 0.8, 1.1, 0.9, -0.08)
	_rim(BOULDERS, 3, 0.4, 0.55, 0.6, 1.6)


## `n` pieces of `kind` near the rim (from inner_r - reach_in to inner_r - reach_out), in clumps, clear of lanes.
func _rim(kind: String, n: int, s0: float, s1: float, reach_out: float, reach_in: float, clump: float = 1.0) -> void:
	var placed := 0
	var tries := 0
	var seed_a := _rng.randf() * TAU
	while placed < n and tries < n * 12:
		tries += 1
		var a := seed_a + _rng.randfn(0.0, 0.25 * clump) if tries % 4 != 0 else _rng.randf() * TAU
		if tries % 4 == 0:
			seed_a = a
		var p := center + Vector2(cos(a), sin(a)) * (inner_r - _rng.randf_range(reach_out, reach_in))
		if blocked(p, 0.0) or _is_water(p) or _near_pillar(p, 0.9):
			continue
		_add(kind, Vector3(p.x, 0.0, p.y), _rng.randf_range(s0, s1))
		placed += 1


## `n` pieces on the paving (r 4.6 to inner_r - 1.5), clear of lanes and pillars.
func _paving_scatter(kind: String, n: int, s0: float, s1: float, pillar_gap: float, y: float) -> void:
	var placed := 0
	var tries := 0
	while placed < n and tries < n * 15:
		tries += 1
		var a := _rng.randf() * TAU
		var p := center + Vector2(cos(a), sin(a)) * _rng.randf_range(DAIS_CLEAR + 0.8, inner_r - 1.5)
		if blocked(p, 0.2) or _is_water(p) or _near_pillar(p, pillar_gap):
			continue
		_add(kind, Vector3(p.x, y, p.y), _rng.randf_range(s0, s1))
		placed += 1


func _near_pillar(p: Vector2, gap: float) -> bool:
	for pl: Dictionary in pillars:
		var pp: Vector3 = pl["pos"]
		if Vector2(pp.x, pp.z).distance_to(p) < gap:
			return true
	return false


func _add(kind: String, pos: Vector3, s: float) -> void:
	var xf := Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s, s)), pos)
	if not _lists.has(kind):
		_lists[kind] = []
	(_lists[kind] as Array).append(xf)
	counts[kind] = int(counts.get(kind, 0)) + 1


func _mesh_for(kind: String) -> Mesh:
	var cm := load(MESHES) as Script
	match kind:
		STUMP:
			var src: Mesh = pillars_mesh_src if pillars_mesh_src else load(PILLAR_MESH) as Mesh
			return cm.call(&"stump", src, variant) as Mesh
		GARLAND:
			return cm.call(&"garland") as Mesh
		EDGING, STOOK:
			if not ResourceLoader.exists(QM_MESHES):
				return null
			return (load(QM_MESHES) as Script).call(&"wall" if kind == EDGING else &"stook") as Mesh
		"isle:pillar":
			return cm.call(&"recolored", pillars_mesh_src, variant) as Mesh
	if not ResourceLoader.exists(kind):
		return null
	var m := load(kind) as Mesh
	return cm.call(&"recolored", m, variant) as Mesh if RECOLOR_KINDS.has(kind) else m


func _commit() -> void:
	for kind: Variant in _lists:
		var list: Array = _lists[kind]
		var mesh := _mesh_for(String(kind))
		if mesh == null or list.is_empty():
			counts.erase(kind)
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = list.size()
		for i: int in list.size():
			mm.set_instance_transform(i, list[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = String(kind).get_file().get_basename().replace(":", "_").to_pascal_case()
		mmi.multimesh = mm
		mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if SHADOW_KINDS.has(String(kind)) \
				else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
		_mmis.append(mmi)


func _clear_props() -> void:
	for m: MultiMeshInstance3D in _mmis:
		if is_instance_valid(m):
			m.queue_free()
	_mmis.clear()
	_lists.clear()
	for pl: Dictionary in pillars:
		pl["stump"] = false


static func _hash1(x: float) -> float:
	return fposmod(sin(x * 91.7351 + 3.17) * 43758.5453, 1.0)
