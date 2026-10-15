class_name MusterPadView
extends Node3D
## The 3D view of one seat's Muster Pad (docs/design/ui-wave-strike.md 7, tasks WS3.U1 / WS4.U1; rules wave-strike.md
## 15): the stone plate, the cell grid with its front edge (gold line, chevron, FRONT), row numbers, one token per copy
## (2 MultiMeshes of discs 1x1 / 2x2 with a role-coloured rim, the rank band and the upgrade ticks drawn by the token
## shader, + one flat Sprite3D icon each), the held / moved glyphs, selection rings, the hover / place ghosts (the
## unit's real model at 50 %), footprint quads, the Line zone shading and the lane's spawn-box outline.
## Zero per-frame cost when idle: tokens are rebuilt on `MusterPad.changed` / `MusterRoster.changed` only; _process
## runs only while an animation plays. MusterPadInput (own pad) drives the hover / drag / ghost calls.

const PLATE_H := 0.3
const PLATE_MAT := "res://art/environment/lane_dressing/muster_plate_mat.tres"   ## tech-artist, G-F r2 item 10
const RIM := 1.0
const ROLE_COLORS := {
	&"melee": Color(0.85, 0.35, 0.30), &"ranged": Color(0.35, 0.70, 0.95), &"rider": Color(0.95, 0.75, 0.30),
	&"heavy": Color(0.70, 0.50, 0.90), &"support": Color(0.45, 0.85, 0.50), &"caster": Color(0.95, 0.50, 0.85),
}
const STONE := Color(0.30, 0.28, 0.27)
const STONE_RIM := Color(0.22, 0.20, 0.19)
const FREE := Color(0.45, 0.85, 0.50)
## Token sizes (7.1): [disc diameter, height, rim, icon, rank band, tick] for footprint 1 and 2.
const SIZES := {1: [1.3, 0.15, 0.12, 0.9, 0.10, 0.25], 2: [2.8, 0.2, 0.2, 2.0, 0.15, 0.4]}
const PLACED_TIME := 0.35
const SOLD_TIME := 0.35
const FLIGHT_TIME := 0.3
const FLIGHT_STAGGER := 0.01
const SNAP_TIME := 0.15
const HOVER_FADE := 0.08
const LIFT := 0.4
const BLINK_TIME := 0.2
const ZONE_FADE := 0.15

## The unit icon lying on a token: the texture masked to a disc with a soft dark edge; per-copy alpha / tint.
const ICON_SHADER := preload("res://scripts/ui/wave_strike/pad_icon.gdshader")

## Tokens / flags changed (the mini-pad redraws).
signal rebuilt

const TOKEN_SHADER := preload("res://scripts/ui/wave_strike/pad_token.gdshader")

var roster: MusterRoster
var pad: MusterPad
var director: WaveDirector
var own := true
var kingdom: StringName = &"fire"
## Copies past the field cap this horn (the back-most ones get the held marker, 15.3).
var held := 0

var _forward := Vector3.RIGHT
var _right := Vector3.BACK
var _basis := Basis.IDENTITY
var _y := 0.0
var _mm: Dictionary = {}            ## size -> MultiMeshInstance3D
var _rings: MultiMeshInstance3D
var _tokens: Array[Dictionary] = []  ## per copy (pad order): id, cell, size, pos, from, t, dur, ... (see _token)
var _dying: Array[Dictionary] = []   ## sold tokens fading out
var _icons: Array[MeshInstance3D] = []
var _icon_mats: Dictionary = {}     ## id -> ShaderMaterial (the icon texture, circle-masked)
var _icon_meshes: Dictionary = {}   ## footprint -> QuadMesh
var _glyphs: Array[Sprite3D] = []
var _abbrevs: Dictionary = {}       ## token index -> Label3D (no icon)
var _selected: Array[Vector2i] = []
var _hover := -1
var _hover_ghost: Node3D
var _hover_alpha := 0.0
var _hover_id: StringName = &""
var _models: Dictionary = {}        ## id -> Node3D (ghost model cache)
var _place_ghost: Node3D
var _place_quad: MeshInstance3D
var _quads: Array[MeshInstance3D] = []
var _outline: MeshInstance3D        ## dashed source-cell outline while dragging
var _zone: MeshInstance3D
var _zone_alpha := 0.0
var _zone_on := false
var _spawn_box: MeshInstance3D
var _spawn_alpha := 0.0
var _spawn_state := 0               ## 0 hidden, 1 warning (pulse), 2 horn flash, 3 fading out
var _spawn_t := 0.0
var _snapshot: Dictionary = {}      ## "id@x,y" -> count at the last horn (hourglass for the others)
var _have_snapshot := false
var _blink := 0.0
var _drag_cells: Array[Vector2i] = []
var _drag_offset := Vector3.ZERO
var _drag_target: Dictionary = {}   ## drop: old anchor -> visual position (flights start there)
var _flash: Dictionary = {}         ## anchor cell -> [time left, sign (+1 glow / -1 warn)]
var _quad_shake := 0.0
var _anim := false
var _dirty := false
var _mats: Array[Material] = []

static var _glyph_tex: Dictionary = {}


func setup(p_roster: MusterRoster, p_own: bool, p_director: WaveDirector) -> void:
	roster = p_roster
	pad = roster.pad
	director = p_director
	own = p_own
	kingdom = roster.kingdom
	name = "MusterPadView%d" % roster.seat  # LOC_IGNORE
	_forward = pad.forward
	_right = pad.right()
	_basis = Basis.looking_at(_forward, Vector3.UP)
	_y = pad.pad_center.y + PLATE_H
	_build_plate()
	_build_grid()
	_build_tokens()
	if own:
		_build_zones()
	_build_spawn_box()
	pad.changed.connect(_mark_dirty)
	roster.changed.connect(_mark_dirty)
	if director != null:
		director.horn_soon.connect(_on_horn_soon)
		director.horn.connect(_on_horn)
	rebuild()


func _mark_dirty() -> void:
	if not _dirty:
		_dirty = true
		_rebuild_deferred.call_deferred()


func _rebuild_deferred() -> void:
	if _dirty and is_inside_tree():
		rebuild()


# ---------------------------------------------------------------- frame helpers

## World position (plate top) of a copy anchored at `cell` with footprint `size`.
func cell_pos(cell: Vector2i, size: int) -> Vector3:
	var p := pad.cell_to_pad(cell, size)
	return Vector3(p.x, _y, p.z)


## The world point of a pad-local (lateral, forward) offset from the pad centre, at plate height + `h`.
func _local(lat: float, fwd: float, h := 0.0) -> Vector3:
	var c := pad.pad_center
	return Vector3(c.x, _y + h, c.z) + _right * lat + _forward * fwd


## The pad-local offset of the cell corner (c, r) (top-left corner seen from behind = front-left).
func _corner(c: float, r: float) -> Vector2:
	return Vector2((c - MusterPad.COLS * 0.5) * MusterPad.CELL, (MusterPad.ROWS * 0.5 - r) * MusterPad.CELL)


## The cell under a world point on the plate (NONE off the pad).
func cell_at(p: Vector3) -> Vector2i:
	return pad.pad_to_cell(p)


## The ray hit on the plate top plane (null-like Vector3.INF when the ray is parallel).
func plate_hit(origin: Vector3, dir: Vector3) -> Vector3:
	if absf(dir.y) < 0.0001:
		return Vector3.INF
	var t := (_y - origin.y) / dir.y
	return origin + dir * t if t > 0.0 else Vector3.INF


func half_extents() -> Vector2:
	return Vector2(MusterPad.COLS * MusterPad.CELL * 0.5, MusterPad.ROWS * MusterPad.CELL * 0.5)


# ---------------------------------------------------------------- static parts

## A skin token of this pad's kingdom (own pad = the player's skin, enemy pad = the enemy kingdom's).
func _tok(token_name: StringName) -> Color:
	if own:
		return UIStyle.token(token_name)
	var skin: Dictionary = UIStyle.SKINS.get(kingdom, UIStyle.SKINS[&"fire"])
	return skin.get(token_name, Color.MAGENTA)


static func unlit(col: Color, transparent := false, vertex := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	m.vertex_color_use_as_albedo = vertex
	m.vertex_color_is_srgb = true
	if transparent or col.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _mesh_node(mesh: Mesh, mat: Material, nm: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


## A flat quad (pad-local corners a / b, height h) into SurfaceTool `st`.
func _quad(st: SurfaceTool, a: Vector2, b: Vector2, h: float, col: Color) -> void:
	var p0 := _local(a.x, a.y, h)
	var p1 := _local(b.x, a.y, h)
	var p2 := _local(b.x, b.y, h)
	var p3 := _local(a.x, b.y, h)
	for v: Vector3 in [p0, p1, p2, p0, p2, p3]:
		st.set_color(col)
		st.add_vertex(v - global_position)


func _build_plate() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var he := half_extents()
	var o := Vector2(he.x + RIM, he.y + RIM)
	var ground := -PLATE_H
	# top: stone, then the 1 m rim ring (four strips)
	_quad(st, Vector2(-he.x, he.y), Vector2(he.x, -he.y), 0.0, STONE)
	_quad(st, Vector2(-o.x, o.y), Vector2(o.x, he.y), 0.0, STONE_RIM)
	_quad(st, Vector2(-o.x, -he.y), Vector2(o.x, -o.y), 0.0, STONE_RIM)
	_quad(st, Vector2(-o.x, he.y), Vector2(-he.x, -he.y), 0.0, STONE_RIM)
	_quad(st, Vector2(he.x, he.y), Vector2(o.x, -he.y), 0.0, STONE_RIM)
	# sides (darker, fake shading)
	var side := STONE_RIM.darkened(0.35)
	var corners: Array[Vector2] = [Vector2(-o.x, o.y), Vector2(o.x, o.y), Vector2(o.x, -o.y), Vector2(-o.x, -o.y)]
	for i in 4:
		var a := corners[i]
		var b := corners[(i + 1) % 4]
		var p0 := _local(a.x, a.y, 0.0) - global_position
		var p1 := _local(b.x, b.y, 0.0) - global_position
		var p2 := _local(b.x, b.y, ground) - global_position
		var p3 := _local(a.x, a.y, ground) - global_position
		for v: Vector3 in [p0, p1, p2, p0, p2, p3]:
			st.set_color(side)
			st.add_vertex(v)
	# G-F r2 item 10: the tech-artist's lit flagstone material (load-guarded; the old unlit vertex-colour look otherwise).
	var plate_mat: Material = load(PLATE_MAT) as Material if ResourceLoader.exists(PLATE_MAT) else null
	if plate_mat != null:
		st.generate_normals()   # lit: the shader takes the sun (cull disabled, back faces flip their normal)
	_mesh_node(st.commit(), plate_mat if plate_mat else unlit(Color.WHITE, false, true), "Plate")  # LOC_IGNORE
	if own:   # the own pad's rim lit with trim_glow alpha 0.25 (a thin inner frame)
		var gl := SurfaceTool.new()
		gl.begin(Mesh.PRIMITIVE_TRIANGLES)
		var g := Color(UIStyle.token(&"trim_glow"), 0.25)
		var w := 0.12
		_quad(gl, Vector2(-he.x - w, he.y + w), Vector2(he.x + w, he.y), 0.004, g)
		_quad(gl, Vector2(-he.x - w, -he.y), Vector2(he.x + w, -he.y - w), 0.004, g)
		_quad(gl, Vector2(-he.x - w, he.y), Vector2(-he.x, -he.y), 0.004, g)
		_quad(gl, Vector2(he.x, he.y), Vector2(he.x + w, -he.y), 0.004, g)
		_mesh_node(gl.commit(), unlit(Color.WHITE, true, true), "PlateGlow")  # LOC_IGNORE


func _build_grid() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var he := half_extents()
	var light := _tok(&"frame_light")
	var base_a := 0.18 if own else 0.10
	var h := 0.006
	for c in MusterPad.COLS + 1:
		var x := -he.x + c * MusterPad.CELL
		var heavy := c % 4 == 0 and c > 0 and c < MusterPad.COLS
		var w := 0.05 if heavy else 0.03
		_quad(st, Vector2(x - w * 0.5, he.y), Vector2(x + w * 0.5, -he.y), h, Color(light, 0.30 if heavy else base_a))
	for r in MusterPad.ROWS + 1:
		var z := he.y - r * MusterPad.CELL
		_quad(st, Vector2(-he.x, z + 0.015), Vector2(he.x, z - 0.015), h, Color(light, base_a))
	# front edge (row 0 side): 0.12 m gold line + a 2 m chevron 1 m ahead; back edge 0.06 m frame_dark
	_quad(st, Vector2(-he.x, he.y + 0.06), Vector2(he.x, he.y - 0.06), h * 2.0, UIStyle.GOLD)
	var dark := _tok(&"frame_dark")
	_quad(st, Vector2(-he.x, -he.y + 0.03), Vector2(he.x, -he.y - 0.03), h * 2.0, dark)
	_chevron(st, he.y + RIM + 1.0, 2.0, 0.22, Color(UIStyle.GOLD, 0.9), h - PLATE_H + 0.05)
	_mesh_node(st.commit(), unlit(Color.WHITE, true, true), "Grid")  # LOC_IGNORE
	if own:
		var tf := UIStyle.title_font()
		for r in MusterPad.ROWS:
			var l := _label3d(str(r), 100, Color(UIStyle.token(&"text_muted"), 0.5), null)
			l.position = _local(-he.x - RIM * 0.5, he.y - (r + 0.5) * MusterPad.CELL, 0.01) - global_position
		var front := _label3d(Loc.t("FRONT"), 120, Color(UIStyle.GOLD, 0.7), tf)
		front.position = _local(0.0, he.y + RIM + 2.4, 0.06 - PLATE_H) - global_position
		front.name = "FrontLabel"  # LOC_IGNORE


## A flat chevron pointing forward: tip at pad-local forward `at`, `width` wide, stroke `w`.
func _chevron(st: SurfaceTool, at: float, width: float, w: float, col: Color, h: float) -> void:
	var tip := Vector2(0.0, at)
	for s: float in [-1.0, 1.0]:
		var back := Vector2(s * width * 0.5, at - width * 0.5)
		var d := (tip - back).normalized()
		var n := Vector2(-d.y, d.x) * w * 0.5
		var pts: Array[Vector2] = [back + n, tip + n, tip - n, back - n]
		var v: Array[Vector3] = []
		for p in pts:
			v.append(_local(p.x, p.y, h) - global_position)
		for q: Vector3 in [v[0], v[1], v[2], v[0], v[2], v[3]]:
			st.set_color(col)
			st.add_vertex(q)


func _label3d(text: String, font_size: int, col: Color, font: Font) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = font_size
	l.pixel_size = 0.005
	l.outline_size = 0
	l.modulate = col
	l.shaded = false
	l.double_sided = false
	l.no_depth_test = false
	l.alpha_cut = Label3D.ALPHA_CUT_DISABLED
	l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	if font != null:
		l.font = font
	l.basis = _basis * Basis(Vector3.RIGHT, -PI * 0.5)
	add_child(l)
	return l


## Line zone shading (15.4, own pad only): every Line zone tinted in its role colour; alpha fades with the Arrange hover.
func _build_zones() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var zones: Dictionary = MusterPad.ZONES[&"line"]
	for role: StringName in MusterPad.ROLE_ORDER:
		var z: Array = zones[role]
		var spans: Array = z[2]
		if spans.is_empty():
			spans = [[0, MusterPad.COLS - 1]]
		for s: Variant in spans:
			var a := _corner(float(s[0]), float(z[0]))
			var b := _corner(float(s[1]) + 1.0, float(z[1]) + 1.0)
			_quad(st, a, b, 0.003, Color(ROLE_COLORS[role], 1.0))
	_zone = _mesh_node(st.commit(), unlit(Color(1, 1, 1, 0.0), true, true), "ZoneShading")  # LOC_IGNORE
	_zone.visible = false


## The lane spawn box outline (7.2): 24 x 18 m, 0.4 m stroke, 0.6 m front edge + chevron (own only), 12 row lines.
func _build_spawn_box() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var he := half_extents()
	var col := UIStyle.GOLD if own else _tok(&"frame_light")
	var off := pad.spawn_center - pad.pad_center
	var h := 0.08 - PLATE_H + off.y
	off.y = 0.0
	var sq := func(a: Vector2, b: Vector2, c: Color) -> void:
		var p: Array[Vector3] = [_local(a.x, a.y, h) + off, _local(b.x, a.y, h) + off, _local(b.x, b.y, h) + off,
				_local(a.x, b.y, h) + off]
		for v: Vector3 in [p[0], p[1], p[2], p[0], p[2], p[3]]:
			st.set_color(c)
			st.add_vertex(v - global_position)
	var w := 0.4
	sq.call(Vector2(-he.x, he.y), Vector2(he.x, he.y - 0.6), col)          # front edge 0.6 m
	sq.call(Vector2(-he.x, -he.y + w), Vector2(he.x, -he.y), col)
	sq.call(Vector2(-he.x, he.y), Vector2(-he.x + w, -he.y), col)
	sq.call(Vector2(he.x - w, he.y), Vector2(he.x, -he.y), col)
	for r in range(1, MusterPad.ROWS):
		var z := he.y - r * MusterPad.CELL
		sq.call(Vector2(-he.x + w, z + 0.05), Vector2(he.x - w, z - 0.05), Color(col, 0.35))
	if own:
		var st2 := st
		var tip := he.y + 2.0
		for s: float in [-1.0, 1.0]:
			var back := Vector2(s * 1.0, tip - 1.0)
			var d := (Vector2(0.0, tip) - back).normalized()
			var n := Vector2(-d.y, d.x) * 0.15
			var pts: Array[Vector2] = [back + n, Vector2(0.0, tip) + n, Vector2(0.0, tip) - n, back - n]
			var v: Array[Vector3] = []
			for p in pts:
				v.append(_local(p.x, p.y, h) + off - global_position)
			for q: Vector3 in [v[0], v[1], v[2], v[0], v[2], v[3]]:
				st2.set_color(col)
				st2.add_vertex(q)
	_spawn_box = _mesh_node(st.commit(), unlit(Color(1, 1, 1, 0.0), true, true), "SpawnBox")  # LOC_IGNORE
	_spawn_box.visible = false


# ---------------------------------------------------------------- tokens

func _disc_mesh(d: float, h: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 40
	var r := d * 0.5
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var p0 := Vector3(cos(a0) * r, h, sin(a0) * r)
		var p1 := Vector3(cos(a1) * r, h, sin(a1) * r)
		# top fan (Godot's front faces wind clockwise seen from the outside)
		st.add_vertex(Vector3(0, h, 0))
		st.add_vertex(p0)
		st.add_vertex(p1)
		# side wall
		var q0 := Vector3(p0.x, 0.0, p0.z)
		var q1 := Vector3(p1.x, 0.0, p1.z)
		st.add_vertex(p0)
		st.add_vertex(q1)
		st.add_vertex(p1)
		st.add_vertex(p0)
		st.add_vertex(q0)
		st.add_vertex(q1)
	return st.commit()


func _token_material(size: int) -> ShaderMaterial:
	var s: Array = SIZES[size]
	var m := ShaderMaterial.new()
	m.shader = TOKEN_SHADER
	var body := _tok(&"panel_inner").lightened(0.15)
	m.set_shader_parameter(&"body_color", body)
	m.set_shader_parameter(&"gold", UIStyle.GOLD)
	m.set_shader_parameter(&"glow", UIStyle.token(&"trim_glow"))
	m.set_shader_parameter(&"warn", UIStyle.WARN)
	m.set_shader_parameter(&"radius", float(s[0]) * 0.5)
	m.set_shader_parameter(&"rim_w", float(s[2]))
	m.set_shader_parameter(&"band_w", float(s[4]))
	m.set_shader_parameter(&"tick", float(s[5]))
	m.set_shader_parameter(&"height", float(s[1]))
	_mats.append(m)
	return m


func _build_tokens() -> void:
	for size: int in [1, 2]:
		var s: Array = SIZES[size]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.use_custom_data = true
		mm.mesh = _disc_mesh(float(s[0]), float(s[1]))
		mm.instance_count = 0
		var mi := MultiMeshInstance3D.new()
		mi.name = "Tokens%dx%d" % [size, size]  # LOC_IGNORE
		mi.multimesh = mm
		mi.material_override = _token_material(size)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_mm[size] = mi
	var torus := TorusMesh.new()
	torus.inner_radius = 0.92
	torus.outer_radius = 1.0
	torus.rings = 40
	torus.ring_segments = 4
	var rm := MultiMesh.new()
	rm.transform_format = MultiMesh.TRANSFORM_3D
	rm.use_colors = true
	rm.mesh = torus
	_rings = MultiMeshInstance3D.new()
	_rings.name = "Rings"  # LOC_IGNORE
	_rings.multimesh = rm
	_rings.material_override = unlit(Color.WHITE, true, true)
	_rings.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_rings)


func _key(id: StringName, cell: Vector2i) -> String:
	return "%s@%d,%d" % [id, cell.x, cell.y]  # LOC_IGNORE


## Rebuilds the token list from the pad (diff with the shown one: new copies pop in, removed ones fade out, a copy of
## the same card that changed cell flies there).
func rebuild() -> void:
	_dirty = false
	if pad == null:
		return
	var copies := pad.copies()
	var old := _tokens
	var old_left: Array[Dictionary] = []
	var keep: Dictionary = {}
	for t in old:
		keep[_key(t["id"], t["cell"])] = int(keep.get(_key(t["id"], t["cell"]), 0)) + 1
	var fresh: Array[Dictionary] = []
	var matched: Dictionary = {}
	for c in copies:
		var k := _key(c["id"], c["cell"])
		var t := _token(c)
		if int(keep.get(k, 0)) > int(matched.get(k, 0)):
			matched[k] = int(matched.get(k, 0)) + 1
			for o in old:   # carry the running animation of the same copy
				if _key(o["id"], o["cell"]) == k and not o.has("_used"):
					o["_used"] = true
					t["from"] = o["from"]
					t["t"] = o["t"]
					t["dur"] = o["dur"]
					t["pop"] = o["pop"]
					break
		else:
			t["new"] = true
		fresh.append(t)
	for o in old:
		if not o.has("_used"):
			old_left.append(o)
		o.erase("_used")
	# pair removed and added copies of the same card: flights (moves, swaps, arrange), else pop in / fade out
	var delay := 0.0
	for t in fresh:
		if not t.has("new"):
			continue
		var best := -1
		var best_d := INF
		for j in old_left.size():
			if StringName(old_left[j]["id"]) != StringName(t["id"]):
				continue
			var d := (_cur_pos(old_left[j]) - Vector3(t["pos"])).length_squared()
			if d < best_d:
				best_d = d
				best = j
		if best >= 0:
			var o: Dictionary = old_left[best]
			old_left.remove_at(best)
			var cell: Vector2i = o["cell"]
			if _drag_target.has(cell):
				t["from"] = _drag_target[cell]
				t["dur"] = SNAP_TIME
				t["t"] = 0.0
			else:
				t["from"] = _cur_pos(o)
				t["dur"] = FLIGHT_TIME
				t["t"] = -delay
				delay += FLIGHT_STAGGER
		else:
			t["pop"] = PLACED_TIME
			_flash[t["cell"]] = [PLACED_TIME, 1.0]
		t.erase("new")
	for o in old_left:
		o["sold"] = SOLD_TIME
		_dying.append(o)
	_drag_target.clear()
	_tokens = fresh
	for i in _tokens.size():
		_tokens[i]["i"] = i
	_refresh_flags()
	_upload()
	_start_anim()
	rebuilt.emit()


func _token(c: Dictionary) -> Dictionary:
	var id: StringName = c["id"]
	var size := int(c["size"])
	var pos := cell_pos(c["cell"], size)
	return {"id": id, "cell": c["cell"], "size": size, "pos": pos, "from": pos, "t": 1.0, "dur": 0.0, "pop": 0.0,
			"role": roster.table.role_of(id) if roster.table else &"melee", "rank": roster.rank(id),
			"up": (1 if roster.has_upgrade(id, 0) else 0) + (2 if roster.has_upgrade(id, 1) else 0)}


## Held (back-most past the field cap) and moved-after-the-horn flags.
func _refresh_flags() -> void:
	var order: Array[int] = []
	for i in _tokens.size():
		order.append(i)
	order.sort_custom(func(a: int, b: int) -> bool:
		var ca: Vector2i = _tokens[a]["cell"]
		var cb: Vector2i = _tokens[b]["cell"]
		if ca.y != cb.y:
			return ca.y < cb.y
		var da := absf(ca.x + int(_tokens[a]["size"]) * 0.5 - MusterPad.COLS * 0.5)
		var db := absf(cb.x + int(_tokens[b]["size"]) * 0.5 - MusterPad.COLS * 0.5)
		return da < db if da != db else ca.x < cb.x)
	for t in _tokens:
		t["held"] = false
		t["moved"] = false
	for k in mini(held, order.size()):
		_tokens[order[order.size() - 1 - k]]["held"] = true
	if own and _have_snapshot:
		var left := _snapshot.duplicate()
		for t in _tokens:
			var k := _key(t["id"], t["cell"])
			if int(left.get(k, 0)) > 0:
				left[k] = int(left[k]) - 1
			else:
				t["moved"] = true


## Sets the held count (copies past the field cap); a change refreshes the markers.
func set_held(n: int) -> void:
	if n == held:
		return
	held = n
	_refresh_flags()
	_upload()
	rebuilt.emit()


func token_count() -> int:
	return _tokens.size()


## The shown tokens (tests / tooltips): [{id, cell, size, held, moved, rank, up}].
func tokens() -> Array[Dictionary]:
	return _tokens


func _cur_pos(t: Dictionary) -> Vector3:
	var dur := float(t["dur"])
	var p: Vector3 = t["pos"]
	if dur > 0.0 and float(t["t"]) < dur:
		var k := clampf(float(t["t"]) / dur, 0.0, 1.0)
		k = 1.0 - pow(1.0 - k, 3.0)
		p = (t["from"] as Vector3).lerp(t["pos"], k)
	return p


func _visual(t: Dictionary, dying: bool) -> Array:
	var pos := _cur_pos(t)
	var sc := 1.0
	var a := 1.0
	var pop := float(t.get("pop", 0.0))
	if pop > 0.0:
		sc = lerpf(1.0, 1.15, pop / PLACED_TIME)
	if dying:
		var k := 1.0 - float(t["sold"]) / SOLD_TIME
		sc = lerpf(1.0, 0.6, k)
		a = 1.0 - k
	var cell: Vector2i = t["cell"]
	if not dying and _drag_cells.has(cell):
		pos += _drag_offset + Vector3.UP * LIFT
		a = 0.7
	elif bool(t.get("held", false)):
		a = 0.55
	return [pos, sc, a]


func _upload() -> void:
	var per: Dictionary = {1: [], 2: []}
	for t in _tokens:
		(per[int(t["size"])] as Array).append([t, false])
	for t in _dying:
		(per[int(t["size"])] as Array).append([t, true])
	var idx := 0
	var rings: Array = []
	for size: int in [1, 2]:
		var mm := (_mm[size] as MultiMeshInstance3D).multimesh
		var list: Array = per[size]
		if mm.instance_count < list.size():
			mm.instance_count = maxi(list.size(), mm.instance_count * 2)
		mm.visible_instance_count = list.size()
		for i in list.size():
			var t: Dictionary = list[i][0]
			var dying: bool = list[i][1]
			var v := _visual(t, dying)
			var tr := Transform3D(_basis.scaled(Vector3(v[1], 1.0, v[1])), v[0])
			mm.set_instance_transform(i, tr)
			var role_c: Color = ROLE_COLORS.get(t["role"], ROLE_COLORS[&"melee"])
			mm.set_instance_color(i, Color(role_c, float(v[2])))
			var hi := 0.0
			if not dying and int(t.get("i", -1)) == _hover and _hover >= 0:
				hi = 0.3
			var fl := 0.0
			var f: Variant = _flash.get(t["cell"])
			if f is Array and not dying:
				fl = clampf(float(f[0]) / 0.3, 0.0, 1.0) * float(f[1])
			if dying:
				fl = -clampf(float(t["sold"]) / SOLD_TIME * 2.0, 0.0, 1.0)
			if _blink > 0.0 and own and not dying:
				fl = maxf(fl, sin(_blink / BLINK_TIME * PI))
			mm.set_instance_custom_data(i, Color(float(t["rank"]) - 1.0, float(t["up"]), hi, fl))
			if not dying and _selected.has(t["cell"] as Vector2i):
				var s: Array = SIZES[size]
				rings.append([Vector3(v[0]) + Vector3.UP * 0.05, float(s[0]) * 0.5 + 0.3, Color(UIStyle.GOLD, 1.0)])
			var pop := float(t.get("pop", 0.0))
			if pop > 0.0 and not dying:
				var k := 1.0 - pop / PLACED_TIME
				rings.append([Vector3(v[0]) + Vector3.UP * 0.03, lerpf(0.4, 0.8, k) * size,
						Color(UIStyle.token(&"trim_glow"), 1.0 - k)])
			_place_icon(idx, t, v, dying)
			idx += 1
	for j in range(idx, _icons.size()):
		_icons[j].visible = false
		if j < _glyphs.size():
			_glyphs[j].visible = false
	for j: int in _abbrevs.keys():
		if j >= idx:
			(_abbrevs[j] as Label3D).visible = false
	var rm := _rings.multimesh
	if rm.instance_count < rings.size():
		rm.instance_count = maxi(rings.size(), 16)
	rm.visible_instance_count = rings.size()
	for i in rings.size():
		var r: Array = rings[i]
		var rad := float(r[1])
		rm.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3(rad, 0.4, rad)), r[0]))
		rm.set_instance_color(i, r[2])


func _place_icon(i: int, t: Dictionary, v: Array, dying: bool) -> void:
	while _icons.size() <= i:
		var q := MeshInstance3D.new()
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(q)
		_icons.append(q)
	var spr := _icons[i]
	var size := int(t["size"])
	var s: Array = SIZES[size]
	var id: StringName = t["id"]
	var tex := UnitGuideData.icon_of(id)
	var sc := float(v[1])
	var pos: Vector3 = v[0]
	pos.y += float(s[1]) + 0.012
	var a := float(v[2])
	if tex != null:
		if not _icon_meshes.has(size):
			var qm := QuadMesh.new()
			qm.size = Vector2(float(s[3]), float(s[3]))
			_icon_meshes[size] = qm
		spr.mesh = _icon_meshes[size]
		if not _icon_mats.has(id):
			var m := ShaderMaterial.new()
			m.shader = ICON_SHADER
			m.set_shader_parameter(&"tex", tex)
			m.render_priority = 1
			_icon_mats[id] = m
		spr.material_override = _icon_mats[id]
		spr.global_transform = Transform3D(_basis * Basis(Vector3.RIGHT, -PI * 0.5) * Basis.from_scale(Vector3(sc, sc, 1.0)), pos)
		spr.set_instance_shader_parameter(&"alpha", a)
		spr.set_instance_shader_parameter(&"tint", 1.15 if _selected.has(t["cell"] as Vector2i) and not dying else 1.0)
		spr.visible = true
		if _abbrevs.has(i):
			(_abbrevs[i] as Label3D).visible = false
	else:
		spr.visible = false
		if not _abbrevs.has(i):
			_abbrevs[i] = _label3d("", 90, UIStyle.token(&"title"), UIStyle.title_font())
		var l := _abbrevs[i] as Label3D
		var t_type := UnitType.find(String(t["id"]))
		l.text = UIStyle.abbrev(Loc.t(t_type.display_name) if t_type else String(t["id"]))
		l.font_size = 90 * size
		l.global_position = pos
		l.modulate.a = a
		l.visible = true
	# held (pause) / moved (hourglass) glyph on the icon
	var g := &""
	if not dying and bool(t.get("held", false)):
		g = &"pause"
	elif not dying and bool(t.get("moved", false)):
		g = &"hourglass"
	while _glyphs.size() <= i:
		var gs := Sprite3D.new()
		gs.shaded = false
		gs.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
		gs.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		gs.basis = _basis * Basis(Vector3.RIGHT, -PI * 0.5)
		gs.render_priority = 2
		add_child(gs)
		_glyphs.append(gs)
	var glyph := _glyphs[i]
	glyph.visible = g != &""
	if g != &"":
		glyph.texture = glyph_texture(g)
		var gsize := 0.4 if g == &"pause" else 0.3
		glyph.pixel_size = gsize * (2.0 if size == 2 else 1.0) / 32.0
		glyph.global_position = pos + Vector3.UP * 0.01 + _right * float(s[3]) * 0.3 + _forward * float(s[3]) * 0.3
		glyph.modulate = Color(1, 1, 1, maxf(a, 0.8))


## Small code-drawn glyph textures (32 x 32): &"pause" (WARN bars), &"hourglass" (text_muted).
static func glyph_texture(kind: StringName) -> Texture2D:
	if _glyph_tex.has(kind):
		return _glyph_tex[kind]
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	if kind == &"pause":
		img.fill_rect(Rect2i(2, 2, 28, 28), Color(0, 0, 0, 0.75))
		img.fill_rect(Rect2i(8, 7, 6, 18), UIStyle.WARN)
		img.fill_rect(Rect2i(18, 7, 6, 18), UIStyle.WARN)
	else:
		var col := Color(0.85, 0.82, 0.78)
		img.fill_rect(Rect2i(3, 1, 26, 30), Color(0, 0, 0, 0.7))
		img.fill_rect(Rect2i(7, 4, 18, 2), col)
		img.fill_rect(Rect2i(7, 26, 18, 2), col)
		for y in range(6, 26):
			var k := absf(y - 16.0) / 10.0
			var half := int(1.0 + 7.0 * k)
			var fill := y < 12 or y > 19
			for x in range(16 - half, 16 + half):
				var edge := x == 16 - half or x == 16 + half - 1
				if edge or fill:
					img.set_pixel(x, y, col)
	var tex := ImageTexture.create_from_image(img)
	_glyph_tex[kind] = tex
	return tex


# ---------------------------------------------------------------- animation

func _start_anim() -> void:
	_anim = true
	set_process(true)


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	var busy := false
	for t in _tokens:
		if float(t["dur"]) > 0.0 and float(t["t"]) < float(t["dur"]):
			t["t"] = float(t["t"]) + delta
			busy = true
		if float(t["pop"]) > 0.0:
			t["pop"] = maxf(0.0, float(t["pop"]) - delta)
			busy = true
	for i in range(_dying.size() - 1, -1, -1):
		_dying[i]["sold"] = float(_dying[i]["sold"]) - delta
		if float(_dying[i]["sold"]) <= 0.0:
			_dying.remove_at(i)
		busy = true
	for k: Vector2i in _flash.keys():
		var f: Array = _flash[k]
		f[0] = float(f[0]) - delta
		if float(f[0]) <= 0.0:
			_flash.erase(k)
		busy = true
	if _blink > 0.0:
		_blink = maxf(0.0, _blink - delta)
		busy = true
	if not _drag_cells.is_empty():
		busy = true
	busy = _anim_hover(delta) or busy
	busy = _anim_zone(delta) or busy
	busy = _anim_spawn(delta) or busy
	if _quad_shake > 0.0:
		_quad_shake = maxf(0.0, _quad_shake - delta)
		busy = true
	_upload()
	if not busy:
		_anim = false
		set_process(false)


func _anim_hover(delta: float) -> bool:
	if _hover_ghost == null:
		return false
	var want := 1.0 if _hover >= 0 else 0.0
	if is_equal_approx(_hover_alpha, want):
		_hover_ghost.visible = want > 0.0
		return false
	_hover_alpha = move_toward(_hover_alpha, want, delta / HOVER_FADE)
	_set_ghost_alpha(_hover_ghost, 1.0 - 0.5 * _hover_alpha)
	_hover_ghost.visible = _hover_alpha > 0.0
	return true


func _anim_zone(delta: float) -> bool:
	if _zone == null:
		return false
	var want := 0.12 if _zone_on else 0.0
	if is_equal_approx(_zone_alpha, want):
		_zone.visible = want > 0.0
		return false
	_zone_alpha = move_toward(_zone_alpha, want, delta * 0.12 / ZONE_FADE)
	(_zone.material_override as StandardMaterial3D).albedo_color.a = _zone_alpha / 0.12 * 0.12
	_zone.visible = _zone_alpha > 0.0
	return true


func _anim_spawn(delta: float) -> bool:
	if _spawn_state == 0:
		return false
	_spawn_t += delta
	var base := 0.35 if own else 0.25
	match _spawn_state:
		1:
			var fade := clampf(_spawn_t / 0.3, 0.0, 1.0)
			var pulse := lerpf(0.25, 0.45, 0.5 + 0.5 * sin(_spawn_t * TAU)) / 0.35 * base
			_spawn_alpha = pulse * fade
		2:
			_spawn_alpha = lerpf(0.8, base, clampf(_spawn_t / 0.25, 0.0, 1.0))
			if _spawn_t >= 0.25:
				_spawn_state = 3
				_spawn_t = 0.0
		3:
			_spawn_alpha = lerpf(base, 0.0, clampf(_spawn_t / 0.5, 0.0, 1.0))
			if _spawn_t >= 0.5:
				_spawn_state = 0
	(_spawn_box.material_override as StandardMaterial3D).albedo_color.a = _spawn_alpha
	_spawn_box.visible = _spawn_alpha > 0.001
	return _spawn_state != 0


func _on_horn_soon(_s: float) -> void:
	_spawn_state = 1
	_spawn_t = 0.0
	_start_anim()


func _on_horn(_i: int) -> void:
	_spawn_state = 2
	_spawn_t = 0.0
	take_snapshot()
	if own:
		_blink = BLINK_TIME
		_selected.clear()
	_start_anim()


## The horn read the pad: tokens moved after now get the hourglass until the next horn.
func take_snapshot() -> void:
	_snapshot.clear()
	for t in pad.copies():
		var k := _key(t["id"], t["cell"])
		_snapshot[k] = int(_snapshot.get(k, 0)) + 1
	_have_snapshot = true
	_refresh_flags()
	rebuilt.emit()


## True while the spawn box outline is shown (tests).
func spawn_box_visible() -> bool:
	return _spawn_box != null and _spawn_box.visible


## Every own token blinks its rim (an Armoury buy, 8.2).
func blink_all() -> void:
	_blink = BLINK_TIME
	_start_anim()


# ---------------------------------------------------------------- hover, selection, drag

## Index of the token covering `cell` (-1 none).
func token_at(cell: Vector2i) -> int:
	var c := pad.copy_at(cell)
	if c.is_empty():
		return -1
	for i in _tokens.size():
		if _tokens[i]["cell"] == c["cell"]:
			return i
	return -1


func set_hover(i: int) -> void:
	if i == _hover:
		return
	_hover = i
	if i >= 0:
		var t := _tokens[i]
		var id: StringName = t["id"]
		if _hover_ghost == null or _hover_id != id:
			if _hover_ghost != null:
				_hover_ghost.visible = false
			_hover_ghost = ghost_model(id)
			_hover_id = id
			_hover_alpha = 0.0
		_hover_ghost.global_position = Vector3(t["pos"]) + Vector3.UP * float(SIZES[int(t["size"])][1])
		_hover_ghost.basis = _basis
		_set_ghost_alpha(_hover_ghost, 1.0)
	_start_anim()


func hovered() -> int:
	return _hover


func set_selected(cells: Array[Vector2i]) -> void:
	_selected = cells.duplicate()
	_upload()


func selected() -> Array[Vector2i]:
	return _selected


## Drag preview: the tokens anchored at `cells` lift and follow `offset` (world); empty = no drag.
func set_drag(cells: Array[Vector2i], offset: Vector3) -> void:
	_drag_cells = cells.duplicate()
	_drag_offset = offset
	if _outline != null:
		_outline.visible = false
	if not cells.is_empty():
		_show_outline(cells)
		_start_anim()
	else:
		_upload()


## The drop: the next rebuild's flights for `cells` start at their dragged position (SNAP_TIME).
func end_drag(refused: bool) -> void:
	for c in _drag_cells:
		var i := token_at(c)
		if i >= 0:
			var p := Vector3(_tokens[i]["pos"]) + _drag_offset + Vector3.UP * LIFT
			if refused:   # snap back: fly home with a WARN rim flash
				_tokens[i]["from"] = p
				_tokens[i]["t"] = 0.0
				_tokens[i]["dur"] = SNAP_TIME
				_flash[c] = [0.3, -1.0]
			else:
				_drag_target[c] = p
	_drag_cells.clear()
	if _outline != null:
		_outline.visible = false
	hide_quads()
	_start_anim()


## Flashes the token at `cell` (WARN when `warn`).
func flash_cell(cell: Vector2i, warn := true) -> void:
	var i := token_at(cell)
	if i >= 0:
		_flash[_tokens[i]["cell"]] = [0.3, -1.0 if warn else 1.0]
		_start_anim()


func _show_outline(cells: Array[Vector2i]) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var col := Color(UIStyle.token(&"frame_light"), 0.9)
	for cell in cells:
		var i := token_at(cell)
		var s := int(_tokens[i]["size"]) if i >= 0 else 1
		var a := _corner(cell.x, cell.y)
		var b := _corner(cell.x + s, cell.y + s)
		var w := 0.05
		for edge: Array in [[a, Vector2(b.x, a.y)], [Vector2(a.x, b.y), b], [a, Vector2(a.x, b.y)], [Vector2(b.x, a.y), b]]:
			var p0: Vector2 = edge[0]
			var p1: Vector2 = edge[1]
			var length := p0.distance_to(p1)
			var n := int(length / 0.3)
			for k in n:
				if k % 2 == 1:
					continue
				var q0 := p0.lerp(p1, float(k) / n)
				var q1 := p0.lerp(p1, float(k + 1) / n)
				_quad(st, Vector2(minf(q0.x, q1.x) - w, maxf(q0.y, q1.y) + w), Vector2(maxf(q0.x, q1.x) + w,
						minf(q0.y, q1.y) - w), 0.012, col)
	if _outline == null:
		_outline = _mesh_node(st.commit(), unlit(Color.WHITE, true, true), "DragOutline")  # LOC_IGNORE
	else:
		_outline.mesh = st.commit()
	_outline.visible = true


## Footprint quads: rows [cell, size, state] (&"free" green, &"blocked" WARN, &"swap" GOLD).
func show_quads(rows: Array) -> void:
	while _quads.size() < rows.size():
		var pm := PlaneMesh.new()
		pm.size = Vector2(1, 1)
		var q := _mesh_node(pm, unlit(Color(1, 1, 1, 0.45), true), "Quad%d" % _quads.size())  # LOC_IGNORE
		_quads.append(q)
	for i in _quads.size():
		var q := _quads[i]
		if i >= rows.size():
			q.visible = false
			continue
		var r: Array = rows[i]
		var cell: Vector2i = r[0]
		var s := int(r[1])
		var col := FREE
		var a := 0.45
		match StringName(r[2]):
			&"blocked":
				col = UIStyle.WARN
			&"swap":
				col = UIStyle.GOLD
				a = 0.35
		(q.material_override as StandardMaterial3D).albedo_color = Color(col, a)
		var p := cell_pos(cell, s) + Vector3.UP * 0.02
		if _quad_shake > 0.0:
			p += _right * sin(_quad_shake * 70.0) * 0.15 * (_quad_shake / 0.2)
		q.global_position = p
		q.basis = _basis.scaled(Vector3(s * MusterPad.CELL - 0.08, 1.0, s * MusterPad.CELL - 0.08))
		q.visible = true


func hide_quads() -> void:
	for q in _quads:
		q.visible = false


## `Cell blocked` (7.4): the quads shake ±0.15 m for 0.2 s.
func shake_quads() -> void:
	_quad_shake = 0.2
	_start_anim()


## The place ghost (7.3): the unit model at 50 % on `cell` + its footprint quad; `cell` NONE = hidden.
func show_place_ghost(id: StringName, cell: Vector2i, ok: bool) -> void:
	if cell == MusterPad.NONE:
		hide_place_ghost()
		return
	var s := pad.footprint(id)
	if _place_ghost == null or StringName(_place_ghost.get_meta(&"_id", &"")) != id:
		if _place_ghost != null:
			_place_ghost.visible = false
		_place_ghost = ghost_model(id)
	_place_ghost.global_position = cell_pos(cell, s)
	_place_ghost.basis = _basis
	_set_ghost_alpha(_place_ghost, 0.5)
	_place_ghost.visible = true
	show_quads([[cell, s, &"free" if ok else &"blocked"]])


func hide_place_ghost() -> void:
	if _place_ghost != null:
		_place_ghost.visible = false
	hide_quads()


func place_ghost_visible() -> bool:
	return _place_ghost != null and _place_ghost.visible


## A cached 50 % copy of `id`'s model (the real model scene, else the placeholder capsule).
func ghost_model(id: StringName) -> Node3D:
	if _models.has(id) and is_instance_valid(_models[id]):
		return _models[id]
	var root := Node3D.new()
	root.name = "Ghost_%s" % id  # LOC_IGNORE
	root.set_meta(&"_id", id)
	var t := UnitType.find(String(id))
	var m: Node3D = null
	if t != null and t.model_scene != null:
		m = t.model_scene.instantiate() as Node3D
	if m == null:
		var mi := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = t.radius if t else 0.45
		cap.height = maxf(t.body_height if t else 1.6, cap.radius * 2.0)
		mi.mesh = cap
		mi.position.y = cap.height * 0.5
		var mat := StandardMaterial3D.new()
		mat.albedo_color = t.body_color if t else Color.GRAY
		mi.material_override = mat
		m = mi
	if m.has_method(&"set_team_color"):
		m.call(&"set_team_color", Unit.kingdom_color_for(roster.team, kingdom) if roster else UIStyle.kingdom_color(kingdom))
	root.add_child(m)
	m.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(root)
	for n in root.find_children("*", "GeometryInstance3D", true, false):
		(n as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if m is GeometryInstance3D:
		(m as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.visible = false
	_models[id] = root
	return root


func _set_ghost_alpha(g: Node3D, transparency: float) -> void:
	for n in g.find_children("*", "GeometryInstance3D", true, false):
		(n as GeometryInstance3D).transparency = transparency
	for c in g.get_children():
		if c is GeometryInstance3D:
			(c as GeometryInstance3D).transparency = transparency


## Line zone shading on / off (the Arrange button hover).
func set_zone_shading(on: bool) -> void:
	if _zone == null or on == _zone_on:
		return
	_zone_on = on
	_start_anim()


func zone_shading_on() -> bool:
	return _zone_on


## The pad centre (camera pivot) and the yaw that looks from behind the pad toward its front edge.
func camera_pose() -> Array:
	var f := _forward
	return [Vector3(pad.pad_center.x, 0.0, pad.pad_center.z) + f * 0.5, atan2(-f.x, -f.z)]
