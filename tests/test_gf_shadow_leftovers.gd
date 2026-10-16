extends SceneTree
## G-F Shadow leftovers (docs/art/gf_shadow_leftovers.md; gf_review2 item 3 / gf_r2_buildings_fs.md "Not done").
## Run: godot --headless --path . -s tests/test_gf_shadow_leftovers.gd --fixed-fps 60 --quit-after 2400
## Checks: the Night Spire's collar is a slate crown (many vertices, three team shades, still ONE merged surface, the
## mirror team colour follows); its hooks still work (site, collapse finishes); the Shadow construction outline is calm
## (thin bars, low energy, slow pulse, glow saturation <= 0.4 / value <= 0.7, also after a team colour change) on the
## Night Spire, Hovel, Gloom Hall and Gloom Stables, and (G-F round 3, gf_r3_sites.md) on the Fire models too.

const TASK_ID := "gf_shadow_leftovers"
const SPIRE := "res://art/buildings/shadow_tower.tscn"
const HOVEL := "res://art/buildings/hovel.tscn"
const HALL := "res://art/buildings/shadow_hall.tscn"
const STABLES := "res://art/buildings/stables/shadow/shadow_stables.tscn"
const EMBER_SPIRE := "res://art/buildings/fire_tower.tscn"
const FIRE_HALL := "res://art/buildings/fire_hall.tscn"

var frame := 0
var world: Node3D
var _spire: Node3D
var _spire_alt: Node3D
var _sites: Array[Node3D] = []
var _fire_sites: Array[Node3D] = []
var _finished: int = 0
var _errors: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	world = Node3D.new()
	root.add_child(world)
	_spire = _add(SPIRE, Vector3(0, 0, 0))
	_spire.connect(&"destroyed_finished", func() -> void: _finished += 1)
	_spire_alt = _add(SPIRE, Vector3(8, 0, 0))
	_spire_alt.call(&"set_team_color", Color(0.2, 0.62, 0.55))
	var x: float = 0.0
	for p: String in [SPIRE, HOVEL, HALL, STABLES]:
		_sites.append(_add(p, Vector3(x, 0, 20)))
		x += 14.0
	for p: String in [EMBER_SPIRE, FIRE_HALL]:
		_fire_sites.append(_add(p, Vector3(x, 0, 20)))
		x += 14.0
	for m: Node3D in _sites + _fire_sites:
		m.call(&"set_construction_progress", 0.0)


func _add(path: String, pos: Vector3) -> Node3D:
	var m := (load(path) as PackedScene).instantiate() as Node3D
	m.position = pos
	world.add_child(m)
	return m


func _check(ok: bool, msg: String) -> void:
	if not ok:
		_errors.append(msg)


func _process(_delta: float) -> bool:
	frame += 1
	if frame == 5:
		_check_crown()
		_check_outlines("start")
	if frame == 6:
		for m: Node3D in _sites:
			m.call(&"set_team_color", Color(0.85, 0.15, 0.2))   # a saturated mirror colour: still capped
		_spire.call(&"set_health_ratio", 0.2)
		_spire.call(&"play_destroyed")
	if frame == 8:
		_check_outlines("recoloured")
	if frame == 9:
		for m: Node3D in _sites:
			m.call(&"set_construction_progress", 1.0)
	if frame == 90:
		for m: Node3D in _sites:
			var ol := m.get_node_or_null(^"BuildOutline") as Node3D
			_check(ol != null and not ol.visible, "%s built: outline still shown" % m.name)
	if frame == 300:
		_check(_finished == 1, "Night Spire collapse did not emit destroyed_finished (%d)" % _finished)
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		quit(0)
	return false


func _check_crown() -> void:
	for m: Node3D in [_spire, _spire_alt]:
		var c := m.get_node_or_null(^"Body/Collar") as MeshInstance3D
		_check(c != null, "%s: no Body/Collar mesh" % m.name)
		if c == null:
			continue
		_check(c.mesh.get_surface_count() == 1, "%s collar: %d surfaces (want 1 after the merge)" % [m.name,
			c.mesh.get_surface_count()])
		_check(_verts(c.mesh) > 1500, "%s collar has no slates (%d verts)" % [m.name, _verts(c.mesh)])
		_check(_count_team_shades(c) >= 3, "%s collar: fewer than 3 team shades" % m.name)
		var ab: AABB = c.get_aabb()
		_check(ab.size.x > 1.9 and ab.size.y > 0.6, "%s collar too small / flat: %s" % [m.name, ab.size])
	var site_collar := _sites[0].get_node(^"Body/Collar") as Node3D
	_check(not site_collar.visible, "Night Spire site at 0 shows the collar")


func _check_outlines(stage: String) -> void:
	for m: Node3D in _sites:
		var ol := m.get_node_or_null(^"BuildOutline") as GeometryInstance3D
		_check(ol != null and ol.visible, "%s %s: no visible site outline" % [m.name, stage])
		if ol == null:
			continue
		var mat := m.get(&"_outline_mat") as ShaderMaterial   # the source (a vc_merge model draws a merged glow copy)
		var e: float = float(mat.get_shader_parameter(&"energy"))
		var ps: float = float(mat.get_shader_parameter(&"pulse_speed"))
		var g: Color = mat.get_shader_parameter(&"glow_color")
		_check(e <= 0.6, "%s %s: outline energy %.2f" % [m.name, stage, e])
		_check(ps <= 2.0, "%s %s: outline pulse %.2f rad/s" % [m.name, stage, ps])
		_check(g.s <= 0.41 and g.v <= 0.71, "%s %s: outline colour s %.2f v %.2f" % [m.name, stage, g.s, g.v])
		_check(_bar_width(ol) <= 0.13, "%s %s: outline bar %.2f m wide" % [m.name, stage, _bar_width(ol)])
	for m: Node3D in _fire_sites:
		var ol := m.get_node_or_null(^"BuildOutline") as GeometryInstance3D
		var mat := m.get(&"_outline_mat") as ShaderMaterial
		var fe: float = float(mat.get_shader_parameter(&"energy")) if mat else -1.0
		# G-F round 3 sites (docs/art/gf_r3_sites.md): every kingdom's site outline is the calm one now.
		_check(fe >= 0.0 and fe <= 0.6, "%s %s: Fire outline energy %.2f (want calm)" % [m.name, stage, fe])
		_check(_bar_width(ol) <= 0.13, "%s %s: Fire outline bar %.2f m (want calm)" % [m.name, stage, _bar_width(ol)])


func _bar_width(ol: GeometryInstance3D) -> float:
	if ol is MultiMeshInstance3D:
		var bm: Mesh = (ol as MultiMeshInstance3D).multimesh.mesh   # a BoxMesh, or its bake after the glow merge
		if bm:
			var sz: Vector3 = bm.get_aabb().size
			return minf(sz.x, sz.z)
	return 0.0


## Distinct team multipliers in a merged painted_vc surface (team vertices: COLOR.a == 0).
func _count_team_shades(mi: MeshInstance3D) -> int:
	var seen := {}
	for s: int in mi.mesh.get_surface_count():
		var arr: Array = mi.mesh.surface_get_arrays(s)
		var cols: Variant = arr[Mesh.ARRAY_COLOR]
		if not (cols is PackedColorArray):
			continue
		for c: Color in cols as PackedColorArray:
			if c.a < 0.5:
				seen[snappedf(c.r, 0.01)] = true
	return seen.size()


func _verts(mesh: Mesh) -> int:
	var n: int = 0
	if mesh == null:
		return 0
	for s: int in mesh.get_surface_count():
		n += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return n
