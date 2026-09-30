class_name IceWallModel
extends SmallBuildingModel
## Ice Wall segment (kingdom-ice.md 5 + 8.1: 1 x 1 cell = 2 x 2 m, height 2.5, no glow). Task 7.V2, epic pass A2.4.
## Read from the RTS camera: a battered ice-stone block on a dark footing, capped with snow and crowned by three
## tilted team crystals (the "3 tilted prisms" of the brief), in the Rime Keep's language.
## Tiling: the segment is built in WORLD axes (its Body ignores the gate yaw the Building gives it) and knows its
## four neighbours. Toward a finished Ice Wall on the next cell (2 m along world X or Z) it grows a snow-capped
## curtain to the cell edge, so two segments meet in one continuous wall with a crystal-topped block every 2 m;
## toward a finished Rime Spire (IceSpireModel, group ANCHOR_GROUP) the curtain reaches the spire's shaft; a free
## side gets a sloped glacis and an icicle fringe instead. Each neighbour layout is one merged mesh (cached per
## layout + one of 3 crystal variants chosen from the cell), so a segment is 2 geometry nodes whatever its shape.
## Links update when a neighbour is placed, finished, destroyed or freed. Hooks: see SmallBuildingModel.

const GROUP := &"ice_wall_models"
const ANCHOR_GROUP := &"ice_wall_anchors"
const CELL := 2.0
const DIRS: Array[Vector3] = [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]
## 2026-09-30 (Art Lab R1: the 40 m read was 55 % of a building's): the block grew ~20 % (wider core, taller block
## and curtains, crystals x1.6) inside its 2 m cell.
const CORE := 0.74        ## core block apothem at its foot
const CORE_TOP := 2.7
const ARM_TOP := 2.0
const ARM_HALF := 0.64    ## curtain half-thickness
const CRYSTAL_SCALE := 1.6
const SPIRE_REACH := 1.45 ## curtain length toward a Rime Spire (up to its shaft)

var _m_snow: ShaderMaterial
var _m_block_a: ShaderMaterial   ## ice-stone courses: a paler and a deeper block (one vertex-coloured material in-game)
var _m_block_b: ShaderMaterial
var _m_block_c: ShaderMaterial   ## frost-glazed block (pale)
var _m_snow_sh: ShaderMaterial   ## snow in shade (drifts at the foot)
var _wall_mi: MeshInstance3D
var _plinth_mi: MeshInstance3D
var _codes: PackedInt32Array = PackedInt32Array([0, 0, 0, 0])   ## per DIRS: 0 free, 1 wall, 2 spire
var _variant: int = 0


func _setup() -> void:
	kingdom_color = Color(0.45, 0.75, 0.95)
	glow_color = Color(0.75, 0.92, 1.00)
	stone_color = Color(0.40, 0.49, 0.63)
	dark_color = Color(0.27, 0.31, 0.39)
	trim_color = Color(0.70, 0.78, 0.88)
	smoke_color = Color(0.25, 0.28, 0.34)
	blaze_a = Color(0.95, 1.0, 1.0)
	blaze_b = Color(0.45, 0.75, 1.0)
	stain_color = Color(0.85, 0.92, 1.00, 0.35)
	footprint = 2.0
	vc_merge = true   # B8: one vertex-coloured painted material (PaintedVC; _swap re-merges a relinked layout)
	crack_strength = 0.2
	plinth_top = 0.3
	wreck_top = 0.75
	smoke_points = [Vector3(0.1, 2.3, -0.1)]   # no glow on walls: smoke only, no frost flare
	blaze_points = []


func _build_parts() -> void:
	_m_snow = _painted_mat(Color(0.86, 0.92, 1.0), 0.15, 0.0)
	_m_team.set_shader_parameter(&"spec_strength", 0.5)
	_m_team.set_shader_parameter(&"crack_strength", 0.9)
	_m_team.set_shader_parameter(&"crack_scale", 1.2)
	_m_team.set_shader_parameter(&"crack_speed", 0.9)
	_m_stone.set_shader_parameter(&"crack_scale", 1.8)
	_m_block_a = _painted_mat(stone_color.lightened(0.14), 0.12, crack_strength)
	_m_block_b = _painted_mat(stone_color.darkened(0.1), 0.05, crack_strength)
	_m_block_c = _painted_mat(Color(0.62, 0.7, 0.82), 0.3, crack_strength)
	_m_snow_sh = _painted_mat(Color(0.64, 0.72, 0.84), 0.1, 0.0)
	for m: ShaderMaterial in [_m_block_a, _m_block_b, _m_block_c]:
		m.set_shader_parameter(&"crack_scale", 1.8)
	# World-aligned Body: walls have no gate, and neighbours must line up whatever yaw the Building chose.
	if is_inside_tree():
		_body.global_basis = Basis.IDENTITY
		var c := Vector2i(roundi(global_position.x * 0.5), roundi(global_position.z * 0.5))
		_variant = absi(c.x * 7 + c.y * 13) % 3
	var free := PackedInt32Array([0, 0, 0, 0])
	_plinth_mi = _merged("Plinth", _plinth_key(free), _plinth_items(free))
	_plinth_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF   # 0.3 m footing: no visible shadow
	_no_collapse.append(_plinth_mi)
	_wall_mi = _merged("Wall", _wall_key(free), _wall_items(free))
	_build_wreck(0.72, 0.8, _m_team, 5051, 4)


## No rubble ring for walls (it would litter the neighbours' cells).
func _build_ground() -> void:
	super()
	var rubble := get_node_or_null(^"Rubble")
	if rubble:
		remove_child(rubble)
		rubble.queue_free()


# --- Geometry per neighbour layout ---

func _plinth_key(codes: PackedInt32Array) -> String:
	return "plinth_%d%d%d%d" % [codes[0], codes[1], codes[2], codes[3]]


func _wall_key(codes: PackedInt32Array) -> String:
	return "wall_%d%d%d%d_v%d" % [codes[0], codes[1], codes[2], codes[3], _variant]


## Dark footing: 1.84 m square, reaching the cell edge on joined sides; a low snow bank along each free side.
func _plinth_items(codes: PackedInt32Array) -> Array:
	var box1: Mesh = _box(Vector3.ONE)
	var ext: Array[float] = []
	for i: int in 4:
		ext.append(1.0 if codes[i] > 0 else 0.92)   # joined: flush with the neighbour's (no overlap = no z-fight)
	var it: Array = []
	it.append(_it(box1, Vector3((ext[0] - ext[1]) * 0.5, 0.15, (ext[2] - ext[3]) * 0.5), _m_dark, Vector3.ZERO,
		Vector3(ext[0] + ext[1], 0.3, ext[2] + ext[3])))
	for i: int in 4:
		if codes[i] > 0:
			continue
		var d: Vector3 = DIRS[i]
		var side := Vector3(absf(d.z), 0.0, absf(d.x))
		var s: float = 0.3 if i % 2 == 0 else -0.25
		it.append(_itx(IceShapes.mound(), Transform3D(Basis(Vector3.UP, atan2(d.x, d.z)).scaled_local(Vector3(0.5, 0.13, 0.22)),
			d * 0.93 + side * s), _m_snow))
		# A second, smaller drift in the wall's shadow (blue-grey snow).
		it.append(_itx(IceShapes.mound(), Transform3D(Basis(Vector3.UP, atan2(d.x, d.z) + 0.4).scaled_local(Vector3(0.3, 0.1, 0.16)),
			d * 0.9 - side * s * 1.6 + Vector3(0, 0.02, 0)), _m_snow_sh))
	return it


## Core block + snow cap + crystals, then per side a curtain (joined) or a glacis with icicles (free).
## Material order is fixed (dark, stone, snow, team) so every layout's surfaces match the same overrides.
func _wall_items(codes: PackedInt32Array) -> Array:
	var box1: Mesh = _box(Vector3.ONE)
	var it: Array = []
	it.append(_it(IceShapes.prism(CORE + 0.09, CORE + 0.09, 0.26, 4), Vector3(0, 0.3, 0), _m_dark))
	# The block: a dark core (it shows in the joints) laid in five courses of ice-stone blocks, 2 x 2 a course,
	# each a little off square and of its own shade, snow caught on two course ledges, frost crystals in the joints.
	it.append(_it(IceShapes.prism(CORE - 0.06, CORE - 0.16, CORE_TOP - 0.3, 4), Vector3(0, 0.3, 0), _m_dark))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7700 + _variant * 31
	var courses: int = 5
	var ch: float = (CORE_TOP - 0.3) / float(courses)
	for k: int in courses:
		var half: float = lerpf(CORE, CORE - 0.1, (float(k) + 0.5) / float(courses))
		var y0: float = 0.3 + ch * float(k)
		var shift: float = 0.12 * (1.0 if k % 2 == 0 else -1.0)
		for bx: int in 2:
			for bz: int in 2:
				var wx: float = half + (shift if bx == 0 else -shift)
				var cx: float = -half + wx * 0.5 if bx == 0 else half - wx * 0.5
				var cz: float = half * (-0.5 if bz == 0 else 0.5)
				var m: ShaderMaterial = [_m_stone, _m_block_a, _m_block_b, _m_stone, _m_block_c][rng.randi() % 5]
				it.append(_it(box1, Vector3(cx, y0 + ch * 0.5, cz), m,
					Vector3(rng.randf_range(-3.0, 3.0), rng.randf_range(-5.0, 5.0), rng.randf_range(-3.0, 3.0)),
					Vector3(wx - 0.04, ch - 0.035, half - 0.04)))
		if k == 1 or k == 3:
			var ledge_y: float = y0 + ch + 0.005
			var face: int = (k + _variant) % 4
			var fd: Vector3 = DIRS[face]
			var fs := Vector3(absf(fd.z), 0.0, absf(fd.x))
			it.append(_it(box1, fd * (half - 0.08) + Vector3(0, ledge_y, 0), _m_snow, Vector3.ZERO,
				fs * (half * 1.5) + Vector3(0, 0.07, 0) + Vector3(absf(fd.x), 0, absf(fd.z)) * 0.2))
	for c2: Vector2 in [Vector2(1, 1), Vector2(-1, -1)]:
		var cp := Vector3(c2.x * (CORE - 0.1), 0.3 + ch * (2.3 + 0.8 * c2.x), c2.y * (CORE - 0.1))
		var out := Vector3(c2.x, 0.4, c2.y).normalized()
		it.append(_itx(IceShapes.crystal(0.1, 0.16, 0.22, 0.05), Transform3D(IceShapes.lean(out, 35.0), cp), _m_team))
		it.append(_itx(IceShapes.crystal(0.07, 0.1, 0.16, 0.04), Transform3D(IceShapes.lean(out + Vector3(0.3, 0, -0.3), 50.0),
			cp + Vector3(0, -0.12, 0)), _m_team))
	it.append(_it(IceShapes.prism(CORE - 0.02, CORE - 0.12, 0.18, 4), Vector3(0, CORE_TOP, 0), _m_snow))
	it.append(_it(IceShapes.mound(), Vector3(-0.05, CORE_TOP + 0.16, 0.04), _m_snow, Vector3(0, 30.0 * _variant, 0),
		Vector3(0.58, 0.16, 0.52)))
	# Three tilted crystals on the core (rotated per variant so a long wall doesn't repeat).
	var vb := Basis(Vector3.UP, TAU / 3.0 * _variant + 0.3)
	for c: Array in [[Vector3(0.05, 0.0, 0.02), Vector3(1, 0, 0.3), 9.0, IceShapes.crystal(0.34, 0.42, 0.66, 0.0)],
			[Vector3(-0.3, -0.02, 0.22), Vector3(-1, 0, 0.6), 28.0, IceShapes.crystal(0.23, 0.3, 0.48, 0.0)],
			[Vector3(0.27, -0.02, -0.3), Vector3(0.6, 0, -1), 32.0, IceShapes.crystal(0.2, 0.24, 0.42, 0.0)]]:
		var p: Vector3 = vb * (c[0] as Vector3) * 1.15 + Vector3(0, CORE_TOP + 0.1, 0)
		it.append(_itx(c[3], Transform3D((IceShapes.lean(vb * (c[1] as Vector3), c[2]) * vb).scaled_local(
			Vector3.ONE * CRYSTAL_SCALE), p), _m_team))
	for i: int in 4:
		var d: Vector3 = DIRS[i]
		var side := Vector3(absf(d.z), 0.0, absf(d.x))
		var along := Vector3(absf(d.x), 0.0, absf(d.z))
		if codes[i] > 0:
			var reach: float = 1.0 if codes[i] == 1 else SPIRE_REACH   # flush at the cell edge with the neighbour's
			var inner: float = CORE - 0.2
			var length: float = reach - inner
			var mid: Vector3 = d * (inner + length * 0.5)
			var h: float = ARM_TOP - 0.3
			it.append(_it(box1, mid + Vector3(0, 0.42, 0), _m_dark, Vector3.ZERO,
				along * length + side * (ARM_HALF + 0.07) * 2.0 + Vector3(0, 0.24, 0)))
			it.append(_it(box1, mid + Vector3(0, 0.3 + h * 0.5, 0), _m_stone, Vector3.ZERO,
				along * length + side * ARM_HALF * 2.0 + Vector3(0, h, 0)))
			it.append(_it(box1, mid + Vector3(0, ARM_TOP + 0.06, 0), _m_snow, Vector3.ZERO,
				along * length + side * (ARM_HALF + 0.05) * 2.0 + Vector3(0, 0.13, 0)))
			for s: float in [-1.0, 1.0]:
				it.append(_itx(IceShapes.icicle_strip(0.5, 3, 0.32, 0.07, 40 + i * 2 + int(s > 0.0)),
					Transform3D(Basis(Vector3.UP, 0.0 if d.x != 0.0 else PI * 0.5), mid + side * s * (ARM_HALF + 0.05)
					+ Vector3(0, ARM_TOP, 0)), _m_snow))
		else:
			var yb := Basis(Vector3.UP, atan2(-d.z, d.x))
			it.append(_itx(_prism(Vector3(0.42, 1.0, 1.34), 0.0), Transform3D(yb, d * (CORE + 0.16) + Vector3(0, 0.8, 0)),
				_m_stone))
			it.append(_itx(IceShapes.icicle_strip(1.2, 5, 0.5, 0.1, 50 + i), Transform3D(Basis(Vector3.UP,
				0.0 if d.x == 0.0 else PI * 0.5), d * (CORE - 0.06) + Vector3(0, CORE_TOP + 0.02, 0)), _m_snow))
	return it


# --- Auto-join ---

func _enter_tree() -> void:
	add_to_group(GROUP)


func _exit_tree() -> void:
	remove_from_group(GROUP)
	_refresh_neighbours()


func _on_progress(_building: bool) -> void:
	refresh_links()
	_refresh_neighbours()


func _on_destroy_start() -> void:
	_refresh_neighbours()   # this wall keeps its curtains: they sink with it


func _on_team_color(_g: Color) -> void:
	refresh_links()
	_refresh_neighbours()


## True when this wall is a finished, standing segment (links only join those).
func is_joinable() -> bool:
	return _ready_done and not _destroyed and _progress >= 1.0 and is_inside_tree()


## Wall joints: the team colour neighbours compare with.
func joint_color() -> Color:
	return _team_color


## Re-reads the four neighbours and swaps to the matching merged meshes. Frozen once the collapse started.
func refresh_links() -> void:
	if _wall_mi == null or _destroyed or not is_inside_tree():
		return
	var codes := PackedInt32Array([0, 0, 0, 0])
	if is_joinable():
		var here: Vector3 = global_position
		for i: int in 4:
			var pos: Vector3 = here + DIRS[i] * CELL
			if _find(GROUP, pos) != null:
				codes[i] = 1
			elif _find(ANCHOR_GROUP, pos) != null:
				codes[i] = 2
	if codes == _codes:
		return
	_codes = codes
	_swap(_plinth_mi, _plinth_key(codes), _plinth_items(codes))
	_swap(_wall_mi, _wall_key(codes), _wall_items(codes))


## Asks every Ice Wall next to `node` (a wall or a Rime Spire) to re-read its neighbours.
static func refresh_around(node: Node3D) -> void:
	if node == null or not node.is_inside_tree():
		return
	var here: Vector3 = node.global_position
	for n: Node in node.get_tree().get_nodes_in_group(GROUP):
		var w := n as IceWallModel
		if w == null or w == node:
			continue
		var d: Vector3 = here - w.global_position
		if absf(absf(d.x) + absf(d.z) - CELL) < 0.1 and absf(d.y) < 0.5:
			w.refresh_links()


func _refresh_neighbours() -> void:
	IceWallModel.refresh_around(self)


func _swap(mi: MeshInstance3D, key: String, items: Array) -> void:
	mi.mesh = BMG.mesh_for("%s/%s" % [get_script().resource_path, key], items)
	var mats: Array[Material] = BMG.materials_of(items)
	for i: int in mats.size():
		mi.set_surface_override_material(i, mats[i])
	if vc_merge and _ready_done and _m_team.shader == PVC.PAINTED_VC:
		PVC.convert(mi, _m_team, _vc_team(), [_m_hole] if _m_hole else [], _vc_skip())


## A joinable wall (group GROUP) or Rime Spire (ANCHOR_GROUP) of this team standing at `pos`, else null.
func _find(group: StringName, pos: Vector3) -> Node3D:
	for n: Node in get_tree().get_nodes_in_group(group):
		var w := n as Node3D
		if w == null or w == self or not w.has_method(&"is_joinable") or not w.has_method(&"joint_color"):
			continue
		if w.get_world_3d() != get_world_3d() or (w.global_position - pos).length() > 0.1:
			continue
		if w.call(&"is_joinable") and (w.call(&"joint_color") as Color).is_equal_approx(_team_color):
			return w
	return null


## The keep's cold idle rim instead of the base one (selection still turns it to the team colour).
func _apply_rim_and_glow() -> void:
	super()
	if _ready_done and _body != null:
		IceShapes.apply_ice_rim(_painted, _team_color, _sel_k, _progress < 1.0 and not _destroyed)
