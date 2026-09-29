extends SceneTree
## E34-B (docs/design/episode3-4-opening.md 4.2 + 8): bakes the props of the two flashback sets, which the .set files use
## as `place` (static dressing) and `actor` lines (the cine can show / hide / move each one per shot).
##   forge_ep3_memories/props/ : graveyard, candle, master (the Master: hooded, beard of light, four-colour burning hem),
##                               orrery (dais, rune rings, brass rings, the four bowls), flame_{red,blue,green,violet},
##                               apprentices (young Vessa / Torvald / Ysolde, real kit models baked in one mesh), hollow,
##                               heart_stone (amber, beats)
##   forge_ep4_memories/props/ : winter (snowfield, village, snowy pines, the buried seed, footprints, snowfall), spring
##                               (the same village in May, the seed now a sapling), frost (H05 clearing), sapling_young,
##                               sapling_frost, burnt (the burned, frozen wood), fallen (her army, frozen: baked kit
##                               models), shoot (one green shoot in the black ash)
## Opaque parts use the shared painted environment material (art/environment/env_painted_mat.tres: vertex colour blocks,
## height gradient in COLOR.a, contact band from UV.y); glows are unshaded additive cards (props/mem_glow.gdshader and
## the prologue's fx_add / fx_solid / fx_veil). 0 lights. Deterministic: hashed jitter, fixed particle seeds.
## Run:  tools\godot_run.ps1 --headless --path . -s res://art/cinematics/stage_sets/forge_ep3_memories/tools/memory_bake.gd
##           --fixed-fps 30 --quit-after 20000 '--' only=ep3,ep4 part=props,bake

const IB := preload("res://art/cinematics/stage_sets/forge_intro_vessa/tools/intro_bake.gd")
const PAINT_PATH := "res://art/environment/env_painted_mat.tres"
const SH_MEM := "res://art/cinematics/stage_sets/forge_ep3_memories/props/mem_glow.gdshader"
const SH_ADD := IB.SH_ADD
const SH_SOLID := IB.SH_SOLID
const SH_VEIL := IB.SH_VEIL
const EP3 := "res://art/cinematics/stage_sets/forge_ep3_memories/props/"
const EP4 := "res://art/cinematics/stage_sets/forge_ep4_memories/props/"

const U := "res://art/units/"
const VESSA := U + "wizards/vessa.tscn"
const TORVALD := U + "wizards/torvald.tscn"
const YSOLDE := U + "wizards/ysolde.tscn"
const MALRIK := U + "wizards/malrik.tscn"
const WILDWOOD := U + "nature/wildwood_archer/wildwood_archer.tscn"
const VINELASHER := U + "nature/vinelasher/vinelasher.tscn"
const STAGRUNNER := U + "nature/stagrunner/stagrunner.tscn"
const THORNLING := U + "nature/thornling.tscn"
const BLOOMTENDER := U + "nature/bloomtender.tscn"

var only: PackedStringArray = PackedStringArray(["ep3", "ep4"])
var parts: PackedStringArray = PackedStringArray(["props", "bake"])
var paint: Material


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("only="):
			only = a.substr(5).split(",")
		elif a.begins_with("part="):
			parts = a.substr(5).split(",")
	_run.call_deferred()


func _run() -> void:
	await process_frame
	paint = load(PAINT_PATH)
	for d in [EP3, EP4]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(d))
	if only.has("ep3") and parts.has("props"):
		_ep3_props()
	if only.has("ep4") and parts.has("props"):
		_ep4_props()
	if only.has("ep3") and parts.has("bake"):
		await _bake(EP3 + "apprentices", _apprentices(), false)
	if only.has("ep4") and parts.has("bake"):
		await _bake(EP4 + "fallen", _fallen(), true)
		# the child (and her mother) in the winter and spring corners: baked still (the cameras barely move there)
		await _bake(EP4 + "people_winter", [IB.unit(YSOLDE, Vector3(0.1, 0.14, 1.1), 180.0, "idle", 10, 0.52),
			IB.unit(BLOOMTENDER, Vector3(2.7, 0.14, 7.6), 14.0, "idle", 10, 1.0)], false)
		await _bake(EP4 + "people_spring", [IB.unit(YSOLDE, Vector3(0.1, 0.14, 1.1), 180.0, "idle", 10, 0.52),
			IB.unit(BLOOMTENDER, Vector3(-1.05, 0.14, 1.95), 150.0, "idle", 10, 1.0)], false)
	print("memory_bake: done")
	quit(0)


static func h(a: float, b: float, s: int) -> float:
	return IB.h01(a, b, s)


# ================================================================ painted mesh builder

## Vertex-colour mesh for env_painted: COLOR.rgb = sRGB colour, COLOR.a = 0 at the part's bottom -> 1 at its top,
## UV.x = sway weight (0 stone, 1 foliage), UV.y = height above the prop's ground (contact band).
class PB:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var uv := PackedVector2Array()
	var idx := PackedInt32Array()
	var ground := 0.0

	func vert(p: Vector3, nn: Vector3, col: Color, grad: float, sway: float) -> int:
		v.append(p)
		n.append(nn.normalized() if nn.length_squared() > 0.000001 else Vector3.UP)
		c.append(Color(col.r, col.g, col.b, clampf(grad, 0.0, 1.0)))
		uv.append(Vector2(sway, maxf(p.y - ground, 0.0)))
		return v.size() - 1

	## Godot front faces are clockwise: flip a triangle whose counter-clockwise normal points along nrm.
	func tri(a: int, b: int, d: int, nrm: Vector3) -> void:
		var cr := (v[b] - v[a]).cross(v[d] - v[a])
		if cr.dot(nrm) > 0.0:
			idx.append_array([a, d, b])
		else:
			idx.append_array([a, b, d])

	func box(xf: Transform3D, ctr: Vector3, half: Vector3, col: Color, sway := 0.0) -> void:
		var nb := xf.basis.inverse().transposed()
		for f in 6:
			var ax := f / 2
			var s := 1.0 if f % 2 == 0 else -1.0
			var nrm := Vector3.ZERO
			nrm[ax] = s
			var u := Vector3.ZERO
			u[(ax + 1) % 3] = 1.0
			var w := Vector3.ZERO
			w[(ax + 2) % 3] = 1.0
			var wn := (nb * nrm).normalized()
			var ids: Array[int] = []
			for k in 4:
				var su := -1.0 if (k == 0 or k == 3) else 1.0
				var sw := -1.0 if k < 2 else 1.0
				var lp := ctr + (nrm + u * su + w * sw) * half
				var grad := (lp.y - (ctr.y - half.y)) / maxf(half.y * 2.0, 0.001)
				ids.append(vert(xf * lp, wn, col, grad, sway))
			tri(ids[0], ids[1], ids[2], wn)
			tri(ids[0], ids[2], ids[3], wn)

	## Surface of revolution: prof = (radius, y) from the bottom-outer point upward / inward. folds = vertical folds
	## (radius x (1 + folds * sin(k * angle))), wob = hashed ring jitter, cols = one colour per profile row (or 1).
	func lathe(xf: Transform3D, prof: PackedVector2Array, seg: int, cols: PackedColorArray, sway := 0.0, folds := 0.0,
			fold_k := 7.0, wob := 0.0, seed := 0) -> void:
		var nb := xf.basis.inverse().transposed()
		var ymin := INF
		var ymax := -INF
		for p in prof:
			ymin = minf(ymin, p.y)
			ymax = maxf(ymax, p.y)
		var rows: Array = []
		for i in prof.size():
			var tp := prof[maxi(i - 1, 0)]
			var tn := prof[mini(i + 1, prof.size() - 1)]
			var tg := tn - tp
			var pn := Vector2(tg.y, -tg.x).normalized()
			var col: Color = cols[mini(i, cols.size() - 1)]
			var row: Array[int] = []
			for j in seg + 1:
				var jj := j % seg
				var a := TAU * float(jj) / seg
				var r := prof[i].x * (1.0 + folds * sin(a * fold_k + seed * 0.37) + wob * (IB.h01(jj, i, seed) - 0.5))
				var dir := Vector3(cos(a), 0, sin(a))
				var lp := dir * r + Vector3(0, prof[i].y, 0)
				var ln := dir * pn.x + Vector3(0, pn.y, 0)
				row.append(vert(xf * lp, nb * ln, col, (prof[i].y - ymin) / maxf(ymax - ymin, 0.001), sway))
			rows.append(row)
		for i in prof.size() - 1:
			var r0: Array[int] = rows[i]
			var r1: Array[int] = rows[i + 1]
			for j in seg:
				var nq := n[r0[j]] + n[r1[j]] + n[r0[j + 1]] + n[r1[j + 1]]
				tri(r0[j], r1[j], r0[j + 1], nq)
				tri(r0[j + 1], r1[j], r1[j + 1], nq)

	## Tube along pts (xf applied), radii per point, optional flatten (x scale of the cross-section: leaves, blades).
	func tube(xf: Transform3D, pts: PackedVector3Array, radii: PackedFloat32Array, seg: int, col: Color, sway := 0.0,
			flat := 1.0, col_tip := Color(-1, 0, 0)) -> void:
		var nb := xf.basis.inverse().transposed()
		var cnt := pts.size()
		var side := Vector3.ZERO
		var rings: Array = []
		for i in cnt:
			var t := (pts[mini(i + 1, cnt - 1)] - pts[maxi(i - 1, 0)]).normalized()
			if side == Vector3.ZERO:
				var ref := Vector3.UP if absf(t.y) < 0.9 else Vector3.RIGHT
				side = t.cross(ref).normalized()
			else:
				side = (side - t * side.dot(t)).normalized()
			var up2 := side.cross(t).normalized()
			var fr := float(i) / maxf(cnt - 1, 1)
			var cc := col if col_tip.r < 0.0 else col.lerp(col_tip, fr)
			var ring: Array[int] = []
			for j in seg + 1:
				var a := TAU * float(j % seg) / seg
				var d := side * cos(a) * flat + up2 * sin(a)
				var dn := side * cos(a) / maxf(flat, 0.05) + up2 * sin(a)
				ring.append(vert(xf * (pts[i] + d * radii[i]), nb * dn, cc, fr, sway * fr))
			rings.append(ring)
		for i in cnt - 1:
			var ra: Array[int] = rings[i]
			var rb: Array[int] = rings[i + 1]
			for j in seg:
				var nq := n[ra[j]] + n[rb[j]] + n[ra[j + 1]] + n[rb[j + 1]]
				tri(ra[j], rb[j], ra[j + 1], nq)
				tri(ra[j + 1], rb[j], rb[j + 1], nq)

	## A low irregular mound / patch (snow, dirt, ash) of radius r and height hgt, flat base at y = 0.
	func mound(xf: Transform3D, r: float, hgt: float, col: Color, seed: int, seg := 20, wob := 0.25, col_top := Color(-1, 0, 0)) -> void:
		var ct := col if col_top.r < 0.0 else col_top
		lathe(xf, PackedVector2Array([Vector2(r, 0.0), Vector2(r * 0.85, hgt * 0.35), Vector2(r * 0.55, hgt * 0.8),
			Vector2(r * 0.22, hgt * 0.97), Vector2(0.0, hgt)]), seg, PackedColorArray([col, col, col.lerp(ct, 0.5), ct, ct]),
			0.0, 0.0, 7.0, wob, seed)

	## A faceted rock / crystal (lathe with few sides) standing on its base along xf's up.
	func rock(xf: Transform3D, r: float, hgt: float, sides: int, col: Color, seed: int, tip := 0.0) -> void:
		lathe(xf, PackedVector2Array([Vector2(r * 0.9, 0.0), Vector2(r, hgt * 0.3), Vector2(r * 0.85, hgt * 0.75),
			Vector2(maxf(tip, 0.0), hgt)]), sides, PackedColorArray([col.darkened(0.12), col, col.lightened(0.06), col.lightened(0.1)]),
			0.0, 0.0, 3.0, 0.35, seed)

	func mesh() -> ArrayMesh:
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = v
		arr[Mesh.ARRAY_NORMAL] = n
		arr[Mesh.ARRAY_COLOR] = c
		arr[Mesh.ARRAY_TEX_UV] = uv
		arr[Mesh.ARRAY_INDEX] = idx
		var m := ArrayMesh.new()
		if not v.is_empty():
			m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		return m


static func xf_at(p: Vector3, yaw_deg := 0.0, scl := 1.0, tilt := Vector3.ZERO) -> Transform3D:
	var b := Basis.from_euler(Vector3(deg_to_rad(tilt.x), deg_to_rad(yaw_deg), deg_to_rad(tilt.z)))
	return Transform3D(b.scaled(Vector3.ONE * scl), p)


func add_paint(parent: Node3D, owner: Node, nm: String, pb: PB, shadows := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = pb.mesh()
	mi.material_override = paint
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	parent.add_child(mi)
	mi.owner = owner
	return mi


static func mem(col: Color, energy: float, mode := 0, radial := 1.0, falloff := 2.0, fres := 0.0, phase := 0.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(SH_MEM)
	m.set_shader_parameter("color", col)
	m.set_shader_parameter("energy", energy)
	m.set_shader_parameter("mode", mode)
	m.set_shader_parameter("radial", radial)
	m.set_shader_parameter("falloff", falloff)
	m.set_shader_parameter("fres", fres)
	m.set_shader_parameter("phase", phase)
	return m


## A glow shell (sphere, fresnel-faded) of radius r at p.
static func glow_ball(parent: Node3D, owner: Node, nm: String, p: Vector3, r: float, mat: Material) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 20
	s.rings = 10
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = s
	mi.material_override = mat
	mi.position = p
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.owner = owner
	return mi


## A soft light pool on the ground (flat disc, radial falloff) at p.
static func pool(parent: Node3D, owner: Node, nm: String, p: Vector3, r: float, mat: Material) -> MeshInstance3D:
	var mb := IB.MB.new()
	mb.disc(p, 0.0, r, 32, Color.WHITE, 6)
	return IB.add_mesh(parent, owner, nm, mb, mat)


static func save_scene(dir: String, root_node: Node3D, file: String) -> void:
	var ps := PackedScene.new()
	ps.pack(root_node)
	var path := dir + file + ".tscn"
	var err := ResourceSaver.save(ps, path)
	print("memory_bake: %s (%s)" % [path, error_string(err)])
	root_node.free()


# ================================================================ shared pieces

## A headstone: slab + round top (a cylinder half-buried in the slab), carved cross / ring on its face (+z side),
## moss at the foot. xf = its ground spot (yaw: the face looks along local +z).
func headstone(pb: PB, xf: Transform3D, w: float, hgt: float, col: Color, seed: int, kind := 0) -> void:
	var d := 0.16
	var body := hgt - w * 0.5
	pb.box(xf, Vector3(0, body * 0.5, 0), Vector3(w * 0.5, body * 0.5, d * 0.5), col)
	if kind != 2:
		pb.tube(xf, PackedVector3Array([Vector3(0, body, -d * 0.5), Vector3(0, body, d * 0.5)]),
			PackedFloat32Array([w * 0.5, w * 0.5]), 14, col)
	else:   # a cross-shaped stone
		pb.box(xf, Vector3(0, body + w * 0.35, 0), Vector3(w * 0.14, w * 0.4, d * 0.5), col)
		pb.box(xf, Vector3(0, body + w * 0.18, 0), Vector3(w * 0.42, w * 0.12, d * 0.5), col)
	var carve := col.darkened(0.45)
	var fz := d * 0.5 + 0.004
	if kind == 0:
		pb.box(xf, Vector3(0, body * 0.72, fz), Vector3(0.025, body * 0.2, 0.006), carve)
		pb.box(xf, Vector3(0, body * 0.8, fz), Vector3(w * 0.16, 0.022, 0.006), carve)
	elif kind == 1:
		pb.tube(xf, PackedVector3Array([Vector3(0, body * 0.78, fz), Vector3(0, body * 0.78, fz + 0.01)]),
			PackedFloat32Array([w * 0.2, w * 0.2]), 12, carve)
		pb.box(xf, Vector3(0, body * 0.78, fz + 0.012), Vector3(w * 0.13, w * 0.13, 0.004), col)
	for k in 3:   # lines of an inscription
		pb.box(xf, Vector3(0, body * (0.42 - k * 0.1), fz), Vector3(w * (0.3 - k * 0.04), 0.012, 0.005), carve.lightened(0.1))
	pb.box(xf, Vector3(0, 0.04, 0.02), Vector3(w * 0.56, 0.05, d * 0.7), Color(0.2, 0.26, 0.17))   # moss foot
	pb.box(xf, Vector3(w * 0.25 * (h(seed, 1, 3) - 0.5), body * 0.3, d * 0.5 + 0.003), Vector3(w * 0.12, body * 0.15, 0.004), Color(0.24, 0.3, 0.2))


## A grave mound in front of a stone (local +z side), length l.
func grave(pb: PB, xf: Transform3D, l: float, col: Color, seed: int) -> void:
	pb.lathe(xf * Transform3D(Basis().scaled(Vector3(0.42, 1.0, l * 0.5)), Vector3(0, 0, 0.15 + l * 0.5)),
		PackedVector2Array([Vector2(1.0, 0.0), Vector2(0.9, 0.08), Vector2(0.55, 0.16), Vector2(0.0, 0.19)]), 14,
		PackedColorArray([col.darkened(0.1), col, col.lightened(0.05), col.lightened(0.08)]), 0.0, 0.0, 7.0, 0.15, seed)


## A snowy / plain pine: trunk + 3 cone tiers (+ snow caps).
func pine(pb: PB, xf: Transform3D, hgt: float, snow: bool, seed: int) -> void:
	var trunk := Color(0.24, 0.17, 0.12)
	var green := Color(0.13, 0.25, 0.2).lerp(Color(0.16, 0.3, 0.18), h(seed, 1, 9))
	var sc := Color(0.93, 0.95, 1.0)
	pb.lathe(xf, PackedVector2Array([Vector2(hgt * 0.035, 0), Vector2(hgt * 0.025, hgt * 0.35)]), 7, PackedColorArray([trunk]))
	for t in 3:
		var y0 := hgt * (0.18 + t * 0.24)
		var r := hgt * (0.26 - t * 0.065)
		var th := hgt * (0.4 - t * 0.06)
		pb.lathe(xf, PackedVector2Array([Vector2(0.0, y0 - 0.02), Vector2(r, y0), Vector2(r * 0.55, y0 + th * 0.45), Vector2(0.0, y0 + th)]),
			9, PackedColorArray([green.darkened(0.25), green.darkened(0.1), green, green.lightened(0.08)]), 1.0, 0.1, 9.0, 0.2, seed + t)
		if snow:
			pb.lathe(xf, PackedVector2Array([Vector2(r * 0.82, y0 + th * 0.12), Vector2(r * 0.6, y0 + th * 0.32), Vector2(r * 0.36, y0 + th * 0.58), Vector2(0.0, y0 + th + 0.03)]),
				9, PackedColorArray([sc.darkened(0.08), sc, sc, sc]), 1.0, 0.14, 9.0, 0.3, seed + t + 10)


## A village cottage (origin = front-door ground, facing +z): plaster walls, timber, gable roof, chimney; window glow
## quads go into glow (unshaded warm), snow on the roof when snow.
func cottage(pb: PB, glow: PB, xf: Transform3D, seed: int, snow: bool) -> void:
	var wall := Color(0.78, 0.7, 0.58).lerp(Color(0.72, 0.66, 0.6), h(seed, 2, 5))
	var timber := Color(0.28, 0.19, 0.13)
	var roof := Color(0.42, 0.3, 0.2).lerp(Color(0.36, 0.3, 0.26), h(seed, 3, 5))
	var sc := Color(0.94, 0.96, 1.0)
	var w := 2.9
	var dp := 2.4
	var wh := 1.9
	pb.box(xf, Vector3(0, wh * 0.5, -dp * 0.5), Vector3(w * 0.5, wh * 0.5, dp * 0.5), wall)
	pb.box(xf, Vector3(0, 0.12, -dp * 0.5), Vector3(w * 0.52, 0.12, dp * 0.52), Color(0.35, 0.33, 0.32))   # stone footing
	for sx in [-1.0, 1.0]:
		pb.box(xf, Vector3(sx * w * 0.5, wh * 0.5, 0.02), Vector3(0.07, wh * 0.5, 0.07), timber)
		pb.box(xf, Vector3(sx * w * 0.5, wh * 0.5, -dp + 0.02), Vector3(0.07, wh * 0.5, 0.07), timber)
	pb.box(xf, Vector3(0, wh, 0.03), Vector3(w * 0.52, 0.07, 0.07), timber)
	pb.box(xf, Vector3(0, 0.62, 0.02), Vector3(0.36, 0.62, 0.04), Color(0.3, 0.2, 0.13))   # door
	# gable roof: two slabs + the gable triangle (a thin box stack)
	var pitch := 38.0
	var rl := (w * 0.5 + 0.35) / cos(deg_to_rad(pitch))
	for sx in [-1.0, 1.0]:
		var rx := Transform3D(Basis(Vector3(0, 0, 1), deg_to_rad(-pitch * sx)), Vector3(sx * (w * 0.25 + 0.08), wh + tan(deg_to_rad(pitch)) * (w * 0.25) + 0.05, -dp * 0.5))
		pb.box(xf * rx, Vector3.ZERO, Vector3(rl * 0.5, 0.09, dp * 0.5 + 0.3), roof)
		if snow:
			pb.box(xf * rx, Vector3(0, 0.12, 0), Vector3(rl * 0.5 - 0.02, 0.06, dp * 0.5 + 0.32), sc)
	var gh := tan(deg_to_rad(pitch)) * w * 0.5
	for k in 5:
		var f := float(k) / 5.0
		pb.box(xf, Vector3(0, wh + gh * (f + 0.1), -dp * 0.5), Vector3(w * 0.5 * (1.0 - f) - 0.02, gh * 0.1, dp * 0.5 - 0.02), wall.darkened(0.04))
	pb.box(xf, Vector3(w * 0.28, wh + gh * 0.9, -dp * 0.7), Vector3(0.22, 0.55, 0.22), Color(0.4, 0.36, 0.34))   # chimney
	if snow:
		pb.box(xf, Vector3(w * 0.28, wh + gh * 0.9 + 0.57, -dp * 0.7), Vector3(0.24, 0.04, 0.24), sc)
	# windows (glow) either side of the door + a side window
	for sx in [-1.0, 1.0]:
		glow.box(xf, Vector3(sx * 0.95, 1.05, 0.035), Vector3(0.24, 0.22, 0.01), Color(1.0, 0.72, 0.36))
		pb.box(xf, Vector3(sx * 0.95, 1.05, 0.045), Vector3(0.26, 0.02, 0.012), timber)
		pb.box(xf, Vector3(sx * 0.95, 1.05, 0.045), Vector3(0.02, 0.24, 0.012), timber)
	glow.box(xf, Vector3(w * 0.5 + 0.015, 1.05, -dp * 0.5), Vector3(0.01, 0.22, 0.24), Color(1.0, 0.7, 0.34))
	if snow:   # snow banked against the walls
		pb.mound(xf * Transform3D(Basis().scaled(Vector3(1.8, 1.0, 0.5)), Vector3(0, 0, 0.35)), 1.0, 0.28, sc, seed + 40, 14, 0.3)


func window_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.albedo_color = Color(2.2, 1.7, 1.2)
	return m


func add_glowbox(parent: Node3D, owner: Node, nm: String, pb: PB) -> void:
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = pb.mesh()
	mi.material_override = window_mat()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.owner = owner


## A young tree (sapling): a thin wavy trunk, 3-4 twigs and small leaf clusters. frost = rimed with ice (pale tips).
func young_tree(pb: PB, xf: Transform3D, hgt: float, seed: int, frost: bool) -> void:
	var bark := Color(0.36, 0.26, 0.18)
	var leaf := Color(0.42, 0.72, 0.28)
	if frost:
		bark = Color(0.4, 0.36, 0.36)
		leaf = Color(0.5, 0.7, 0.52)
	var pts := PackedVector3Array()
	for i in 7:
		var t := float(i) / 6.0
		pts.append(Vector3(sin(t * 4.0 + seed) * 0.04 * t, t * hgt, cos(t * 3.0 + seed) * 0.03 * t))
	pb.tube(xf, pts, PackedFloat32Array([0.035, 0.03, 0.026, 0.021, 0.016, 0.011, 0.005]).duplicate() if hgt > 0.6 else PackedFloat32Array([0.016, 0.014, 0.012, 0.01, 0.008, 0.006, 0.003]), 7, bark, 0.3)
	var tip := pts[6]
	var twigs := 4
	for k in twigs:
		var t0 := 0.45 + 0.13 * k
		var base := pts[int(t0 * 6.0)]
		var a := k * 2.4 + seed
		var dir := Vector3(cos(a), 0.9, sin(a)).normalized()
		var l := hgt * (0.3 - k * 0.04)
		var tw := PackedVector3Array([base, base + dir * l * 0.5, base + dir * l])
		pb.tube(xf, tw, PackedFloat32Array([hgt * 0.012, hgt * 0.008, 0.002]), 5, bark, 0.6)
		leaves(pb, xf, base + dir * l, hgt * 0.09, leaf, seed + k, frost)
	leaves(pb, xf, tip, hgt * 0.11, leaf, seed + 9, frost)


func leaves(pb: PB, xf: Transform3D, at: Vector3, s: float, col: Color, seed: int, frost: bool) -> void:
	for i in 5:
		var a := TAU * i / 5.0 + seed
		var dir := Vector3(cos(a), 0.55 + 0.3 * h(i, seed, 2), sin(a)).normalized()
		var tipc := col.lightened(0.25) if not frost else Color(0.92, 0.96, 1.0)
		pb.tube(xf, PackedVector3Array([at, at + dir * s * 0.5, at + dir * s]), PackedFloat32Array([0.001, s * 0.28, 0.0]), 6,
			col, 1.0, 0.25, tipc)


# ================================================================ Episode 3: Malrik's memories

func _ep3_props() -> void:
	_ep3_graveyard()
	_ep3_candle()
	_master()
	_ep3_orrery()
	for k in [["red", Color(1, 0.36, 0.08), Color(1, 0.86, 0.45)], ["blue", Color(0.2, 0.55, 1.0), Color(0.78, 0.94, 1.0)],
			["green", Color(0.25, 0.95, 0.3), Color(0.85, 1.0, 0.6)], ["violet", Color(0.62, 0.22, 1.0), Color(0.95, 0.75, 1.0)]]:
		_flame(k[0], k[1], k[2])
	_ep3_hollow()
	_heart_stone()


## G03: the graveyard at night. Origin = where the boy kneels to read (he faces north, -z); the stone he reads stands
## at (0.1, -1.1) facing him; the camera looks south over the candle at his face, so the graveyard recedes south (+z):
## four loose rows of stones, graves, an open grave with a spade in the dirt, a dead tree, the iron fence, the moon.
func _ep3_graveyard() -> void:
	var r := IB.fx_root("Graveyard")
	var pb := PB.new()
	var stone := Color(0.46, 0.44, 0.5)
	var earth := Color(0.2, 0.16, 0.14)
	# the stone he reads (north-west of him, its face turned to him) + the ledger slab at its foot
	headstone(pb, xf_at(Vector3(-0.5, 0, -1.2), 21, 1.0, Vector3(-4, 0, 3)), 0.8, 1.2, stone.lightened(0.05), 5, 0)
	pb.box(xf_at(Vector3(-0.38, 0, -0.9), 21), Vector3(0, 0.06, 0.25), Vector3(0.42, 0.06, 0.32), stone.darkened(0.12))
	# foreground stones either side of the camera (north) for depth
	headstone(pb, xf_at(Vector3(3.3, 0, -2.3), 205, 1.0, Vector3(6, 0, -8)), 0.7, 1.0, stone.darkened(0.15), 6, 1)
	headstone(pb, xf_at(Vector3(-1.9, 0, -2.2), 170, 1.0, Vector3(-3, 0, 10)), 0.66, 0.95, stone, 7, 2)
	# the rows behind him (south): faces look north (yaw 180) toward the camera
	var i := 0
	for rz: float in [2.2, 4.6, 7.1, 9.8]:
		var nx := 5 if rz < 5.0 else 6
		for k in nx:
			var x := -5.2 + k * (10.4 / (nx - 1)) + (h(k, rz, 11) - 0.5) * 0.9 + (0.6 if int(rz) % 2 == 0 else 0.0)
			var z := rz + (h(rz, k, 12) - 0.5) * 0.7
			if absf(x) < 0.7 and rz < 3.0:
				continue   # keep the boy's silhouette clear
			if Vector2(x, z).distance_to(Vector2(0.8, 4.9)) < 1.4 or Vector2(x, z).distance_to(Vector2(3.8, 8.2)) < 1.1:
				continue   # the Master stands there
			var lean := Vector3((h(k, rz, 13) - 0.5) * 16.0, 0, (h(rz, k, 14) - 0.5) * 18.0)
			var hh := lerpf(0.85, 1.35, h(k, rz, 15))
			var ww := lerpf(0.55, 0.8, h(rz, k, 16))
			var sc := stone.lerp(Color(0.38, 0.4, 0.44), h(k, rz, 17)).darkened(0.08 * (rz / 10.0))
			headstone(pb, xf_at(Vector3(x, 0, z), 180 + (h(k, rz, 18) - 0.5) * 24.0, 1.0, lean), ww, hh, sc, i, i % 3)
			grave(pb, xf_at(Vector3(x, 0, z), 180), 1.5, earth.lerp(Color(0.18, 0.2, 0.14), h(k, rz, 19)), i)
			i += 1
	# the open grave (left, behind him): a black pit, a heap of fresh earth, the spade stuck in it
	pb.box(xf_at(Vector3(-2.3, 0, 2.3), 8), Vector3(0, 0.006, 0), Vector3(0.45, 0.006, 0.95), Color(0.03, 0.025, 0.025))
	pb.box(xf_at(Vector3(-2.3, 0, 2.3), 8), Vector3(0, 0.05, 0), Vector3(0.55, 0.05, 1.05), earth.darkened(0.2))
	pb.mound(xf_at(Vector3(-3.35, 0, 2.2), 20, 1.0), 0.75, 0.55, earth.lightened(0.05), 31, 16, 0.35)
	var spade := xf_at(Vector3(-3.25, 0.25, 2.1), 30, 1.0, Vector3(0, 0, 18))
	pb.tube(spade, PackedVector3Array([Vector3(0, 0, 0), Vector3(0, 1.25, 0)]), PackedFloat32Array([0.022, 0.02]), 6, Color(0.42, 0.3, 0.2))
	pb.box(spade, Vector3(0, 1.28, 0), Vector3(0.1, 0.022, 0.022), Color(0.4, 0.29, 0.19))
	pb.box(spade, Vector3(0, -0.12, 0), Vector3(0.12, 0.17, 0.01), Color(0.3, 0.3, 0.33))
	# the dead tree (left, far): twisted trunk + bare branches, a silhouette on the moon
	var tpts := PackedVector3Array([Vector3(0, 0, 0), Vector3(0.15, 1.2, 0.05), Vector3(-0.1, 2.4, 0.0), Vector3(0.25, 3.4, -0.1), Vector3(0.1, 4.2, 0)])
	var tx := xf_at(Vector3(3.8, 0, 8.2), 0)
	pb.tube(tx, tpts, PackedFloat32Array([0.32, 0.24, 0.18, 0.12, 0.05]), 8, Color(0.16, 0.13, 0.13))
	for b in 6:
		var bi := 1 + b % 3
		var base := tpts[bi]
		var a := b * 1.9 + 0.4
		var dir := Vector3(cos(a), 0.7 + 0.2 * h(b, 1, 21), sin(a) * 0.5).normalized()
		var l := 1.3 + h(b, 2, 21) * 0.9
		var mid := base + dir * l * 0.55 + Vector3(0, 0.1, 0)
		pb.tube(tx, PackedVector3Array([base, mid, mid + (dir + Vector3(0.3 * sin(a), 0.3, 0)).normalized() * l * 0.5]),
			PackedFloat32Array([0.09, 0.05, 0.01]), 6, Color(0.15, 0.12, 0.12))
	# the iron fence (far, z 12.5) with a gate gap, spear-tipped posts
	var iron := Color(0.1, 0.09, 0.11)
	var fx := -7.5
	while fx <= 7.5:
		if absf(fx - 1.5) > 0.8:
			var px := xf_at(Vector3(fx, 0, 12.5), 0)
			pb.box(px, Vector3(0, 0.7, 0), Vector3(0.025, 0.7, 0.025), iron)
			pb.lathe(px, PackedVector2Array([Vector2(0.05, 1.4), Vector2(0.0, 1.58)]), 4, PackedColorArray([iron]))
		fx += 0.45
	for ry in [0.35, 1.15]:
		pb.box(xf_at(Vector3(-3.0, 0, 12.5), 0), Vector3(0, ry, 0), Vector3(4.5, 0.025, 0.02), iron)
		pb.box(xf_at(Vector3(5.0, 0, 12.5), 0), Vector3(0, ry, 0), Vector3(2.5, 0.025, 0.02), iron)
	for fp in [Vector3(-7.9, 0, 12.5), Vector3(0.6, 0, 12.5), Vector3(2.4, 0, 12.5), Vector3(7.9, 0, 12.5)]:
		pb.box(xf_at(fp, 0), Vector3(0, 0.9, 0), Vector3(0.12, 0.9, 0.12), Color(0.3, 0.28, 0.32))
		pb.lathe(xf_at(fp, 0), PackedVector2Array([Vector2(0.14, 1.8), Vector2(0.0, 2.05)]), 4, PackedColorArray([Color(0.3, 0.28, 0.32)]))
	# scattered grass tufts and dead leaves near the stones
	for k in 40:
		var gp := Vector3((h(k, 1, 23) - 0.5) * 13.0, 0, lerpf(-3.0, 11.5, h(k, 2, 23)))
		if gp.distance_to(Vector3(0, 0, 0)) < 0.9:
			continue
		for b in 4:
			var a := b * 1.6 + k
			pb.tube(xf_at(gp, 0), PackedVector3Array([Vector3.ZERO, Vector3(cos(a) * 0.08, 0.22 + 0.1 * h(k, b, 24), sin(a) * 0.08)]),
				PackedFloat32Array([0.02, 0.0]), 3, Color(0.28, 0.3, 0.2).lerp(Color(0.36, 0.3, 0.2), h(k, b, 25)), 1.0)
	add_paint(r, r, "Stones", pb)
	# the moon: a pale disc behind the graveyard (south, high) + a wide halo
	var moon_at := Vector3(12.5, 16.5, 56.0)
	# discs are built flat (normal +y): turn +y toward the set (looking_at's -z, then -90 deg about x)
	var face := Basis.looking_at(Vector3(0, 1.0, 0) - moon_at) * Basis(Vector3.RIGHT, -PI * 0.5)
	var mb := IB.MB.new()
	mb.disc(Vector3.ZERO, 0.0, 3.2, 40, Color.WHITE, 3)
	var mm := IB.add_mesh(r, r, "Moon", mb, mem(Color(0.96, 0.93, 0.86), 2.4, 0, 1.0, 0.08))
	mm.transform = Transform3D(face, moon_at)
	var hb := IB.MB.new()
	hb.disc(Vector3.ZERO, 0.0, 16.0, 40, Color.WHITE, 8)
	var hm := IB.add_mesh(r, r, "MoonHalo", hb, mem(Color(0.55, 0.55, 0.8), 0.45, 0, 1.0, 3.0))
	hm.transform = Transform3D(face, moon_at + (Vector3(0, 1, 0) - moon_at).normalized() * 0.5)
	# ground mist between the stones (pale, slow)
	var mist := IB.MB.new()
	for k in 6:
		mist.disc(Vector3((h(k, 1, 27) - 0.5) * 9.0, 0.18 + k * 0.05, lerpf(1.5, 11.0, h(k, 2, 27))), 0.0, lerpf(3.0, 5.0, h(k, 3, 27)), 28, Color(1, 1, 1, h(k, 4, 27)), 4)
	IB.add_mesh(r, r, "Mist", mist, IB.smat(SH_VEIL, {"dark": Color(0.3, 0.3, 0.42), "glow": Color(0.62, 0.62, 0.78), "energy": 0.9,
		"scroll": Vector2(0.03, -0.02), "tiling": Vector2(5, 2), "twist": 0.5, "streak": 0.8, "opacity": 0.28, "fade_lo": 0.001, "fade_hi": 0.95}))
	IB.particles(r, r, "Motes", {"amount": 26, "life": 7.0, "shape": "box", "ext": Vector3(5, 0.6, 5), "pos": Vector3(0, 0.8, 4),
		"dir": Vector3.UP, "spread": 60.0, "v": Vector2(0.03, 0.12), "size": Vector2(0.5, 1.0), "quad": 0.05, "seed": 31, "turb": 0.3,
		"cols": PackedColorArray([Color(1.6, 1.6, 2.0, 0), Color(1.4, 1.4, 1.9, 0.8), Color(0.8, 0.8, 1.2, 0)]),
		"aabb": AABB(Vector3(-8, -1, -4), Vector3(16, 6, 18))})
	save_scene(EP3, r, "graveyard")


## One candle on a little brass dish, its flame, a warm halo and the pool of light it throws on the grass.
func _ep3_candle() -> void:
	var r := IB.fx_root("Candle")
	var pb := PB.new()
	var brass := Color(0.5, 0.38, 0.2)
	var wax := Color(0.93, 0.87, 0.72)
	pb.lathe(Transform3D(), PackedVector2Array([Vector2(0.11, 0.0), Vector2(0.12, 0.018), Vector2(0.105, 0.03), Vector2(0.0, 0.028)]), 16, PackedColorArray([brass]))
	pb.lathe(Transform3D(), PackedVector2Array([Vector2(0.05, 0.02), Vector2(0.048, 0.2), Vector2(0.044, 0.225), Vector2(0.018, 0.232), Vector2(0.0, 0.228)]), 14,
		PackedColorArray([wax.darkened(0.05), wax, wax.lightened(0.05), wax]))
	for k in 4:   # wax drips
		var a := k * 1.7 + 0.3
		var d := Vector3(cos(a), 0, sin(a)) * 0.05
		pb.tube(Transform3D(), PackedVector3Array([d + Vector3(0, 0.225, 0), d * 1.06 + Vector3(0, 0.16 - k * 0.025, 0), d + Vector3(0, 0.1 - k * 0.02, 0)]),
			PackedFloat32Array([0.012, 0.01, 0.006]), 5, wax.lightened(0.08))
	pb.box(Transform3D(), Vector3(0, 0.245, 0), Vector3(0.004, 0.014, 0.004), Color(0.05, 0.04, 0.04))   # wick
	add_paint(r, r, "Candle", pb)
	var fl := IB.MB.new()
	fl.tube(PackedVector3Array([Vector3(0, 0.245, 0), Vector3(0, 0.27, 0), Vector3(0.002, 0.3, 0), Vector3(0.004, 0.33, 0), Vector3(0.002, 0.36, 0), Vector3(0, 0.38, 0)]),
		PackedFloat32Array([0.008, 0.024, 0.028, 0.022, 0.011, 0.0]), 12, Color.WHITE)
	IB.add_mesh(r, r, "Flame", fl, IB.smat(SH_ADD, {"col_a": Color(1, 0.42, 0.08), "col_b": Color(1, 0.88, 0.5), "energy": 4.0, "scroll": Vector2(0.0, -1.2),
		"tiling": Vector2(3, 2), "sharp": 0.8, "base": 0.7, "fres": 0.4, "fade_lo": 0.05, "fade_hi": 0.15, "sway": 0.004, "pulse": 0.06}))
	var core := IB.MB.new()
	core.tube(PackedVector3Array([Vector3(0, 0.25, 0), Vector3(0, 0.275, 0), Vector3(0, 0.3, 0), Vector3(0, 0.325, 0)]),
		PackedFloat32Array([0.004, 0.012, 0.009, 0.0]), 10, Color.WHITE)
	IB.add_mesh(r, r, "Core", core, IB.smat(SH_ADD, {"col_a": Color(1, 0.95, 0.75), "col_b": Color(1, 1, 0.95), "energy": 4.5, "scroll": Vector2(0, -1.0),
		"tiling": Vector2(2, 2), "sharp": 0.5, "base": 0.9, "fres": 0.0, "fade_lo": 0.05, "fade_hi": 0.2}))
	glow_ball(r, r, "Halo", Vector3(0, 0.31, 0), 0.09, mem(Color(1, 0.62, 0.26), 1.1, 1, 0.0, 2.0, 2.4))
	glow_ball(r, r, "Aura", Vector3(0, 0.3, 0), 0.5, mem(Color(1, 0.55, 0.22), 0.22, 1, 0.0, 2.0, 3.4))
	pool(r, r, "Pool", Vector3(0, 0.02, 0), 2.0, mem(Color(1, 0.58, 0.24), 0.7, 1, 1.0, 2.6))
	IB.particles(r, r, "Dust", {"amount": 10, "life": 5.0, "shape": "sphere", "ext": Vector3(0.45, 0, 0), "pos": Vector3(0, 0.55, 0),
		"dir": Vector3.UP, "spread": 70.0, "v": Vector2(0.02, 0.07), "size": Vector2(0.5, 1.0), "quad": 0.025, "seed": 32, "turb": 0.2,
		"cols": PackedColorArray([Color(2.5, 1.6, 0.8, 0), Color(2.4, 1.5, 0.7, 0.9), Color(1.0, 0.5, 0.2, 0)]),
		"aabb": AABB(Vector3(-1.5, -0.5, -1.5), Vector3(3, 3, 3))})
	save_scene(EP3, r, "candle")


## The Master (ep1 2: a tall hooded figure, face in shadow, a beard of light, a four-colour burning hem, a staff).
## Origin = feet, faces +z. Shared by both memory sets (G03 behind the boy, G04 in the orrery, H05 by the child).
func _master() -> void:
	var r := IB.fx_root("Master")
	var pb := PB.new()
	var robe := Color(0.22, 0.2, 0.34)
	var robe_d := Color(0.14, 0.13, 0.22)
	var mantle := Color(0.36, 0.34, 0.46)
	var id := Transform3D()
	pb.lathe(id, PackedVector2Array([Vector2(0.8, 0.02), Vector2(0.76, 0.3), Vector2(0.64, 0.9), Vector2(0.52, 1.5), Vector2(0.45, 2.0),
		Vector2(0.48, 2.3), Vector2(0.4, 2.45), Vector2(0.18, 2.55), Vector2(0.0, 2.56)]), 28,
		PackedColorArray([robe_d, robe_d, robe, robe, robe, robe, robe, robe, robe]), 0.0, 0.07, 9.0)
	# the mantle over the shoulders (a shorter, wider shell, open at the front by a slight squash)
	pb.lathe(Transform3D(Basis().scaled(Vector3(1.0, 1.0, 0.92)), Vector3(0, 0, -0.02)), PackedVector2Array([Vector2(0.62, 1.55), Vector2(0.6, 1.9),
		Vector2(0.56, 2.25), Vector2(0.44, 2.46), Vector2(0.2, 2.58), Vector2(0.0, 2.6)]), 24, PackedColorArray([mantle.darkened(0.15), mantle, mantle, mantle.lightened(0.05)]), 0.0, 0.05, 6.0)
	# the hood: a cowl, peak falling back; the face opening is a dark oval
	pb.lathe(Transform3D(Basis().scaled(Vector3(1.0, 1.0, 1.08)), Vector3(0, 0, -0.03)), PackedVector2Array([Vector2(0.3, 2.44), Vector2(0.33, 2.62),
		Vector2(0.31, 2.82), Vector2(0.24, 2.98), Vector2(0.12, 3.08), Vector2(0.0, 3.1)]), 20, PackedColorArray([mantle, mantle, mantle.lightened(0.04), mantle, mantle]))
	pb.tube(id, PackedVector3Array([Vector3(0, 2.98, -0.02), Vector3(0, 3.18, -0.18), Vector3(0, 3.3, -0.38), Vector3(0, 3.22, -0.52)]), PackedFloat32Array([0.2, 0.13, 0.07, 0.0]), 9, mantle)
	pb.lathe(Transform3D(Basis(Vector3.RIGHT, PI * 0.5).scaled(Vector3(0.78, 1.0, 1.0)), Vector3(0, 2.74, 0.325)),
		PackedVector2Array([Vector2(0.21, 0.0), Vector2(0.15, 0.03), Vector2(0.0, 0.035)]), 18, PackedColorArray([Color(0.02, 0.02, 0.03)]))
	# sleeves: the left hangs, the right holds the staff
	pb.tube(id, PackedVector3Array([Vector3(-0.5, 2.3, 0.02), Vector3(-0.62, 1.8, 0.12), Vector3(-0.56, 1.3, 0.26), Vector3(-0.5, 1.12, 0.32)]),
		PackedFloat32Array([0.17, 0.16, 0.17, 0.2]), 10, mantle.darkened(0.08))
	pb.tube(id, PackedVector3Array([Vector3(0.5, 2.3, 0.02), Vector3(0.66, 1.9, 0.2), Vector3(0.66, 1.62, 0.36), Vector3(0.64, 1.52, 0.4)]),
		PackedFloat32Array([0.17, 0.16, 0.17, 0.2]), 10, mantle.darkened(0.08))
	pb.lathe(xf_at(Vector3(-0.49, 1.02, 0.34), 0), PackedVector2Array([Vector2(0.07, 0.0), Vector2(0.08, 0.06), Vector2(0.0, 0.12)]), 8, PackedColorArray([Color(0.72, 0.58, 0.48)]))
	pb.lathe(xf_at(Vector3(0.64, 1.48, 0.42), 0), PackedVector2Array([Vector2(0.075, 0.0), Vector2(0.085, 0.06), Vector2(0.0, 0.12)]), 8, PackedColorArray([Color(0.72, 0.58, 0.48)]))
	# the staff: dark wood, a twisted head
	var sx := xf_at(Vector3(0.66, 0.0, 0.46), 0)
	pb.tube(sx, PackedVector3Array([Vector3(0, 0, 0), Vector3(0.01, 1.6, 0), Vector3(-0.01, 3.1, 0.01), Vector3(0.04, 3.35, 0.0)]),
		PackedFloat32Array([0.035, 0.032, 0.03, 0.045]), 7, Color(0.3, 0.22, 0.16))
	for k in 3:
		var a := k * TAU / 3.0
		pb.tube(sx, PackedVector3Array([Vector3(0, 3.25, 0), Vector3(cos(a) * 0.12, 3.45, sin(a) * 0.12), Vector3(cos(a + 0.8) * 0.06, 3.62, sin(a + 0.8) * 0.06)]),
			PackedFloat32Array([0.025, 0.018, 0.008]), 5, Color(0.32, 0.23, 0.16))
	# a belt / sash in the four colours (tells who he is, readable at a distance)
	var band := [Color(0.85, 0.3, 0.12), Color(0.3, 0.5, 0.85), Color(0.3, 0.68, 0.3), Color(0.55, 0.3, 0.8)]
	for k in 4:
		var a0 := PI * 0.5 - 0.6 + k * 0.3
		var p := Vector3(cos(a0) * 0.47, 1.52, sin(a0) * 0.47)
		pb.box(Transform3D(Basis(Vector3.UP, -a0 + PI * 0.5), p), Vector3.ZERO, Vector3(0.075, 0.05, 0.02), band[k])
	add_paint(r, r, "Robe", pb)
	# the beard of light under the hood
	var beard := IB.MB.new()
	for k in 9:
		var x := (k - 4) * 0.04
		var l := 0.72 - absf(k - 4) * 0.06
		var bot := 2.64 - l
		beard.tube(PackedVector3Array([Vector3(x, 2.64, 0.335), Vector3(x * 1.1, 2.46, 0.45), Vector3(x * 0.9, lerpf(2.64, bot, 0.72), 0.56), Vector3(x * 0.55, bot, 0.6)]),
			PackedFloat32Array([0.03, 0.034, 0.024, 0.0]), 6, Color(1, 1, 1, k / 9.0))
	IB.add_mesh(r, r, "Beard", beard, IB.smat(SH_ADD, {"col_a": Color(1, 0.84, 0.58), "col_b": Color(1, 0.97, 0.88), "energy": 2.0, "scroll": Vector2(0, 0.35),
		"tiling": Vector2(2, 3), "sharp": 0.9, "base": 0.45, "fres": 0.4, "fade_lo": 0.3, "fade_hi": 0.55, "sway": 0.015}))
	# two faint eyes in the dark of the hood
	var eyes := IB.MB.new()
	for sxx in [-1.0, 1.0]:
		eyes.tube(PackedVector3Array([Vector3(sxx * 0.065, 2.77, 0.33), Vector3(sxx * 0.065 + 0.001, 2.77, 0.345)]), PackedFloat32Array([0.016, 0.016]), 8, Color.WHITE)
	IB.add_mesh(r, r, "Eyes", eyes, mem(Color(1, 0.9, 0.7), 3.0, 3, 0.0))
	# the four-colour burning hem: four arcs of fire around the foot of the robe + tongues of flame + sparks
	var hem := IB.MB.new()
	var tongues := IB.MB.new()
	var hcols := [Color(1, 0.42, 0.12), Color(0.35, 0.65, 1), Color(0.4, 1, 0.4), Color(0.75, 0.4, 1)]
	for q in 4:
		var hp := PackedVector3Array()
		var hr := PackedFloat32Array()
		for i in 10:
			var a := TAU * (q * 9 + i) / 36.0
			hp.append(Vector3(cos(a) * 0.8, 0.07 + 0.03 * sin(a * 5.0), sin(a) * 0.8))
			hr.append(0.07)
		hem.tube(hp, hr, 6, hcols[q])
		for t in 5:
			var a := TAU * (q * 9 + t * 1.8 + 0.5) / 36.0
			var b := Vector3(cos(a) * 0.8, 0.05, sin(a) * 0.8)
			var hh := 0.22 + 0.16 * h(q, t, 41)
			tongues.tube(PackedVector3Array([b, b + Vector3(0, hh * 0.4, 0) + Vector3(cos(a), 0, sin(a)) * 0.03, b + Vector3(0, hh, 0)]),
				PackedFloat32Array([0.06, 0.04, 0.0]), 6, Color(hcols[q].r, hcols[q].g, hcols[q].b, h(t, q, 42)))
	IB.add_mesh(r, r, "Hem", hem, IB.smat(SH_ADD, {"col_a": Color(0.7, 0.7, 0.7), "col_b": Color(1, 1, 1), "energy": 2.6, "scroll": Vector2(0.4, 0),
		"tiling": Vector2(10, 1), "sharp": 1.0, "base": 0.55, "fres": 0.0, "fade_lo": 0.0001, "fade_hi": 0.0001}))
	IB.add_mesh(r, r, "Tongues", tongues, IB.smat(SH_ADD, {"col_a": Color(0.8, 0.8, 0.8), "col_b": Color(1, 1, 1), "energy": 2.6, "scroll": Vector2(0, -1.5),
		"tiling": Vector2(3, 2), "sharp": 1.2, "base": 0.3, "fres": 0.5, "fade_lo": 0.05, "fade_hi": 0.5, "sway": 0.03}))
	var sp := IB.particles(r, r, "Sparks", {"amount": 44, "life": 1.8, "shape": "ring", "ext": Vector3(0.82, 0.7, 0.05), "pos": Vector3(0, 0.12, 0),
		"dir": Vector3.UP, "spread": 20.0, "v": Vector2(0.4, 1.0), "size": Vector2(0.5, 1.0), "quad": 0.07, "seed": 50, "turb": 0.6,
		"cols": PackedColorArray([Color(4, 4, 4, 0), Color(4, 4, 4, 1), Color(1, 1, 1, 0)]),
		"aabb": AABB(Vector3(-2, -1, -2), Vector3(4, 5, 4))})
	# one system, four colours: every spark draws its colour from four hard bands (red / blue / green / violet)
	var hg := Gradient.new()
	hg.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	hg.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75])
	hg.colors = PackedColorArray(hcols)
	var ht := GradientTexture1D.new()
	ht.gradient = hg
	(sp.process_material as ParticleProcessMaterial).color_initial_ramp = ht
	pool(r, r, "HemGlow", Vector3(0, 0.03, 0), 2.2, mem(Color(1, 0.72, 0.5), 0.55, 3, 1.0, 2.2))
	glow_ball(r, r, "StaffLight", Vector3(0.68, 3.5, 0.46), 0.1, mem(Color(1, 0.95, 0.8), 3.0, 3, 0.0, 2.0, 1.0))
	glow_ball(r, r, "StaffAura", Vector3(0.68, 3.5, 0.46), 0.55, mem(Color(1, 0.85, 0.6), 0.5, 3, 0.0, 2.0, 3.0))
	save_scene(EP3, r, "master")


## G04 / G06: the orrery room. A round dais (y 0.2), a rune ring, four stone pedestals with bowls on the north arc (the
## flames are separate actors so the cine can put them out one by one), brass orrery rings overhead, a colonnade on the
## north half (the south stays open for the cameras), floating dust.
const ORRERY_SPOTS := [Vector3(-3.3, 0.2, -0.6), Vector3(-1.6, 0.2, -2.9), Vector3(1.6, 0.2, -2.9), Vector3(3.3, 0.2, -0.6)]

func _ep3_orrery() -> void:
	var r := IB.fx_root("Orrery")
	var pb := PB.new()
	var st := Color(0.34, 0.32, 0.4)
	pb.lathe(Transform3D(), PackedVector2Array([Vector2(6.2, 0.0), Vector2(6.1, 0.1), Vector2(5.6, 0.11), Vector2(5.55, 0.2), Vector2(0.0, 0.2)]), 48,
		PackedColorArray([st.darkened(0.2), st.darkened(0.1), st, st.lightened(0.04), st.lightened(0.06)]))
	# floor tiles: radial seams (thin dark lines)
	for k in 16:
		var a := TAU * k / 16.0
		pb.box(Transform3D(Basis(Vector3.UP, -a), Vector3(cos(a) * 3.4, 0.2, sin(a) * 3.4)), Vector3.ZERO, Vector3(2.0, 0.004, 0.012), st.darkened(0.35))
	# pedestals + bowls
	for p: Vector3 in ORRERY_SPOTS:
		var x := Transform3D(Basis(), p)
		pb.lathe(x, PackedVector2Array([Vector2(0.38, 0.0), Vector2(0.36, 0.1), Vector2(0.22, 0.18), Vector2(0.18, 0.5), Vector2(0.17, 0.85),
			Vector2(0.26, 0.92), Vector2(0.3, 1.0), Vector2(0.0, 1.0)]), 12, PackedColorArray([st.darkened(0.1), st, st, st.lightened(0.05)]), 0.0, 0.0, 7.0, 0.0)
		pb.lathe(x, PackedVector2Array([Vector2(0.14, 1.0), Vector2(0.36, 1.12), Vector2(0.46, 1.24), Vector2(0.42, 1.26), Vector2(0.0, 1.16)]), 16,
			PackedColorArray([Color(0.5, 0.38, 0.2), Color(0.58, 0.44, 0.22), Color(0.66, 0.5, 0.26), Color(0.3, 0.24, 0.16), Color(0.12, 0.1, 0.09)]))
	# the colonnade (north half, r 9.5) + a ring lintel above
	for k in 9:
		var a := PI + PI * k / 8.0
		var cp := Vector3(cos(a) * 9.5, 0, sin(a) * 9.5)
		pb.lathe(Transform3D(Basis(), cp), PackedVector2Array([Vector2(0.75, 0.0), Vector2(0.7, 0.35), Vector2(0.5, 0.5), Vector2(0.45, 6.2),
			Vector2(0.62, 6.5), Vector2(0.72, 6.8), Vector2(0.0, 6.8)]), 12, PackedColorArray([st.darkened(0.15), st.darkened(0.05), st, st, st.lightened(0.05)]), 0.0, 0.04, 12.0)
	var lp := PackedVector3Array()
	var lr := PackedFloat32Array()
	for i in 25:
		var a := PI + PI * i / 24.0
		lp.append(Vector3(cos(a) * 9.5, 7.1, sin(a) * 9.5))
		lr.append(0.35)
	pb.tube(Transform3D(), lp, lr, 6, st.darkened(0.05))
	add_paint(r, r, "Stone", pb)
	# brass orrery: three tilted rings + a central sun + four small planets in the four colours, on a hanging rod
	var brass := IB.MB.new()
	var oc := Vector3(0, 4.6, -1.2)
	for k in 3:
		var rad := 2.2 + k * 0.7
		var tilt := Basis.from_euler(Vector3(deg_to_rad(20.0 + k * 22.0), deg_to_rad(k * 50.0), deg_to_rad(8.0 - k * 12.0)))
		var rp := PackedVector3Array()
		var rr := PackedFloat32Array()
		for i in 49:
			var a := TAU * i / 48.0
			rp.append(oc + tilt * Vector3(cos(a) * rad, 0, sin(a) * rad))
			rr.append(0.045)
		brass.tube(rp, rr, 6, Color(0.85, 0.66, 0.35, k * 0.3))
	brass.tube(PackedVector3Array([oc, oc + Vector3(0, 6, 0)]), PackedFloat32Array([0.04, 0.04]), 6, Color(0.6, 0.48, 0.3, 0.0))
	IB.add_mesh(r, r, "Rings", brass, IB.smat(SH_SOLID, {"vein": Color(1.0, 0.8, 0.4), "energy": 0.8, "tiling": Vector2(2, 12), "scroll": Vector2(0.0, 0.1),
		"vein_w": 0.82, "rough": 0.3, "spec": 0.8, "rim": 0.6, "tip_glow": 0.0}), true)
	glow_ball(r, r, "Sun", oc, 0.22, mem(Color(1, 0.85, 0.55), 3.0, 3, 0.0, 2.0, 0.8))
	glow_ball(r, r, "SunAura", oc, 1.1, mem(Color(1, 0.8, 0.5), 0.4, 3, 0.0, 2.0, 3.0))
	var pc := [Color(1, 0.4, 0.12), Color(0.35, 0.65, 1), Color(0.4, 1, 0.45), Color(0.72, 0.4, 1)]
	for k in 4:
		var rad := 2.2 + (k % 3) * 0.7
		var tilt := Basis.from_euler(Vector3(deg_to_rad(20.0 + (k % 3) * 22.0), deg_to_rad((k % 3) * 50.0), deg_to_rad(8.0 - (k % 3) * 12.0)))
		var a := 0.6 + k * 1.55
		var pp := oc + tilt * Vector3(cos(a) * rad, 0, sin(a) * rad)
		glow_ball(r, r, "Planet%d" % k, pp, 0.11, mem(pc[k], 2.8, 3, 0.0, 2.0, 0.6, k * 0.7))
	# rune rings inlaid in the dais (gold-violet, slowly running)
	var runes := IB.MB.new()
	runes.disc(Vector3(0, 0.212, 0), 4.2, 4.45, 64, Color.WHITE, 1)
	runes.disc(Vector3(0, 0.212, 0), 1.3, 1.42, 40, Color.WHITE, 1)
	IB.add_mesh(r, r, "Runes", runes, IB.smat(SH_ADD, {"col_a": Color(0.6, 0.35, 1.0), "col_b": Color(1, 0.8, 0.5), "energy": 2.0, "scroll": Vector2(0.05, 0.0),
		"tiling": Vector2(40, 1), "sharp": 2.0, "base": 0.25, "fres": 0.0, "fade_lo": 0.0001, "fade_hi": 0.0001}))
	IB.particles(r, r, "Dust", {"amount": 50, "life": 9.0, "shape": "box", "ext": Vector3(6, 2.5, 5), "pos": Vector3(0, 2.8, -1),
		"dir": Vector3.UP, "spread": 80.0, "v": Vector2(0.02, 0.08), "size": Vector2(0.5, 1.0), "quad": 0.05, "seed": 61, "turb": 0.25,
		"cols": PackedColorArray([Color(1.8, 1.5, 1.2, 0), Color(1.6, 1.4, 1.2, 0.7), Color(1, 0.8, 0.6, 0)]),
		"aabb": AABB(Vector3(-8, -1, -8), Vector3(16, 10, 16))})
	save_scene(EP3, r, "orrery")


## One of the four flames (origin = the bowl's top): two shells + a hot core, a halo, a light pool on the dais below,
## rising motes. Hidden as a whole by the cine (G06: the Master is gone, the flames go out one by one).
func _flame(nm: String, ca: Color, cb: Color) -> void:
	var r := IB.fx_root("Flame" + nm.capitalize())
	var outer := IB.MB.new()
	outer.tube(IB.column(0.85, 8, 0.05, 3, Vector3(0, 0.02, 0)), PackedFloat32Array([0.22, 0.27, 0.25, 0.2, 0.14, 0.08, 0.04, 0.0]), 16, Color.WHITE)
	IB.add_mesh(r, r, "Outer", outer, IB.smat(SH_ADD, {"col_a": ca, "col_b": cb, "energy": 2.3, "scroll": Vector2(0.05, -1.4), "tiling": Vector2(4, 3),
		"twist": 1.0, "sharp": 1.3, "base": 0.25, "fres": 1.0, "fade_lo": 0.04, "fade_hi": 0.5, "sway": 0.02}))
	var inner := IB.MB.new()
	inner.tube(IB.column(0.5, 6, 0.03, 5, Vector3(0, 0.02, 0)), PackedFloat32Array([0.1, 0.13, 0.11, 0.07, 0.03, 0.0]), 12, Color.WHITE)
	IB.add_mesh(r, r, "Core", inner, IB.smat(SH_ADD, {"col_a": cb, "col_b": Color(1, 1, 1), "energy": 2.6, "scroll": Vector2(0.0, -1.8), "tiling": Vector2(3, 3),
		"sharp": 0.8, "base": 0.5, "fres": 0.6, "fade_lo": 0.04, "fade_hi": 0.4}))
	glow_ball(r, r, "Halo", Vector3(0, 0.3, 0), 0.7, mem(ca.lerp(cb, 0.3), 0.32, 1, 0.0, 2.0, 3.0))
	pool(r, r, "Pool", Vector3(0, -1.24, 0), 2.6, mem(ca.lerp(cb, 0.2), 0.75, 1, 1.0, 2.2))
	IB.particles(r, r, "Motes", {"amount": 18, "life": 2.2, "shape": "sphere", "ext": Vector3(0.18, 0, 0), "pos": Vector3(0, 0.2, 0),
		"dir": Vector3.UP, "spread": 18.0, "v": Vector2(0.5, 1.2), "size": Vector2(0.5, 1.0), "quad": 0.06, "seed": 70 + nm.length(), "turb": 0.5,
		"cols": PackedColorArray([Color(cb.r * 3, cb.g * 3, cb.b * 3, 0), Color(ca.r * 3.5, ca.g * 3.5, ca.b * 3.5, 1), Color(ca.r, ca.g, ca.b, 0)]),
		"aabb": AABB(Vector3(-1.5, -1.5, -1.5), Vector3(3, 5, 3))})
	save_scene(EP3, r, "flame_" + nm)


## G09: the Hollow after the fall. Rubble heap, snapped pillars (one fallen), a shattered arch, violet cracks running
## out of the ground, a flat stone where he keeps his three things (a burned-down candle, a knife; the stone is an
## actor). Origin = the flat stone; the camera looks north over it.
func _ep3_hollow() -> void:
	var r := IB.fx_root("Hollow")
	var pb := PB.new()
	var st := Color(0.3, 0.27, 0.34)
	var dk := Color(0.19, 0.17, 0.22)
	# the flat stone (top at y 0.36)
	pb.box(xf_at(Vector3(0, 0, 0), 6), Vector3(0, 0.18, 0), Vector3(0.7, 0.18, 0.42), st)
	pb.box(xf_at(Vector3(0, 0, 0), 6), Vector3(0.05, 0.37, 0.02), Vector3(0.66, 0.012, 0.38), st.lightened(0.05))
	# the burned-down candle: a stub and a pool of old wax
	var cx := xf_at(Vector3(-0.38, 0.38, 0.08), 0)
	pb.lathe(cx, PackedVector2Array([Vector2(0.11, 0.0), Vector2(0.08, 0.012), Vector2(0.0, 0.014)]), 12, PackedColorArray([Color(0.78, 0.73, 0.6)]), 0.0, 0.0, 5.0, 0.4, 3)
	pb.lathe(cx, PackedVector2Array([Vector2(0.04, 0.0), Vector2(0.038, 0.06), Vector2(0.03, 0.07), Vector2(0.0, 0.066)]), 10, PackedColorArray([Color(0.8, 0.75, 0.62)]), 0.0, 0.0, 5.0, 0.2, 4)
	pb.box(cx, Vector3(0, 0.08, 0), Vector3(0.003, 0.012, 0.003), Color(0.02, 0.02, 0.02))
	# the knife: a curved blade + a wrapped hilt, lying across the stone
	var kx := xf_at(Vector3(0.36, 0.385, 0.12), -28, 1.0, Vector3(0, 0, 90))
	pb.tube(kx, PackedVector3Array([Vector3(0, 0, 0), Vector3(0.0, 0.12, 0.012), Vector3(0.0, 0.22, 0.035), Vector3(0.0, 0.3, 0.07)]),
		PackedFloat32Array([0.03, 0.028, 0.02, 0.0]), 6, Color(0.55, 0.55, 0.62), 0.0, 0.18, Color(0.72, 0.7, 0.8))
	pb.box(kx, Vector3(0, -0.005, 0), Vector3(0.045, 0.008, 0.012), Color(0.35, 0.3, 0.38))
	pb.tube(kx, PackedVector3Array([Vector3(0, -0.01, 0), Vector3(0, -0.12, 0)]), PackedFloat32Array([0.016, 0.018]), 6, Color(0.25, 0.14, 0.2))
	# the rubble heap behind (north), stones tumbled around
	for k in 46:
		var a := h(k, 1, 81) * TAU
		var d := sqrt(h(k, 2, 81)) * 3.2
		var p := Vector3(cos(a) * d, 0, -2.6 + sin(a) * d * 0.7)
		var up := (3.2 - d) * 0.35
		var sz := Vector3(lerpf(0.2, 0.55, h(k, 3, 81)), lerpf(0.15, 0.4, h(k, 4, 81)), lerpf(0.2, 0.5, h(k, 5, 81)))
		var rot := Vector3((h(k, 6, 81) - 0.5) * 60.0, h(k, 7, 81) * 180.0, (h(k, 8, 81) - 0.5) * 60.0)
		pb.box(xf_at(p + Vector3(0, up + sz.y * 0.5, 0), rot.y, 1.0, Vector3(rot.x, 0, rot.z)), Vector3.ZERO, sz, st.lerp(dk, h(k, 9, 81)))
	# snapped pillars and a fallen one
	for pp in [[Vector3(-3.6, 0, -2.2), 3.4], [Vector3(3.4, 0, -3.4), 2.1], [Vector3(-1.4, 0, -5.6), 4.6], [Vector3(4.8, 0, -1.0), 1.2]]:
		var at: Vector3 = pp[0]
		var hh: float = pp[1]
		pb.lathe(xf_at(at, 0), PackedVector2Array([Vector2(0.62, 0.0), Vector2(0.55, 0.3), Vector2(0.4, 0.45), Vector2(0.38, hh), Vector2(0.2, hh + 0.12), Vector2(0.0, hh + 0.05)]),
			10, PackedColorArray([dk, st, st, st.lightened(0.04), st, st]), 0.0, 0.05, 10.0, 0.2, int(hh * 10))
	pb.lathe(Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5) * Basis(Vector3.UP, 0.3), Vector3(-1.2, 0.38, -4.6)).rotated_local(Vector3.UP, 0.0),
		PackedVector2Array([Vector2(0.38, -2.2), Vector2(0.38, 1.6), Vector2(0.0, 1.62)]), 10, PackedColorArray([st]), 0.0, 0.05, 10.0)
	# the shattered arch: two tall piers and a broken span
	for sx in [-1.0, 1.0]:
		pb.box(xf_at(Vector3(sx * 2.6, 0, -7.5), 0), Vector3(0, 3.0 + sx * 0.4, 0), Vector3(0.55, 3.0 + sx * 0.4, 0.55), st.darkened(0.08))
	pb.box(xf_at(Vector3(-1.6, 6.3, -7.5), 0, 1.0, Vector3(0, 0, -14)), Vector3.ZERO, Vector3(1.4, 0.35, 0.5), st.darkened(0.05))
	pb.box(xf_at(Vector3(2.1, 6.9, -7.5), 0, 1.0, Vector3(0, 0, 24)), Vector3.ZERO, Vector3(0.7, 0.35, 0.5), st.darkened(0.05))
	# shards of the black-violet crystal the Hollow grew
	for k in 9:
		var a := h(k, 1, 82) * TAU
		var d := 2.0 + h(k, 2, 82) * 3.5
		var p := Vector3(cos(a) * d, 0, -2.4 + sin(a) * d * 0.8)
		if p.z > 0.2:
			p.z -= 3.0
		pb.rock(xf_at(p, h(k, 3, 82) * 90, 1.0, Vector3((h(k, 4, 82) - 0.5) * 40, 0, (h(k, 5, 82) - 0.5) * 40)), 0.14 + 0.12 * h(k, 6, 82),
			0.8 + 1.2 * h(k, 7, 82), 5, Color(0.2, 0.12, 0.3), 90 + k, 0.0)
	add_paint(r, r, "Rubble", pb)
	# the cracks: violet light leaking up out of the ground toward the flat stone
	var cr := IB.MB.new()
	for k in 7:
		var a := -PI * 0.5 + (k - 3) * 0.42 + (h(k, 1, 83) - 0.5) * 0.2
		var a0 := Vector3(cos(a) * 0.9, 0.02, -1.4 + sin(a) * 0.4)
		var b0 := Vector3(cos(a) * (4.0 + h(k, 2, 83) * 3.0), 0.02, -1.4 + sin(a) * (3.0 + h(k, 3, 83) * 2.0))
		cr.arc(a0, b0, 0.0, 0.08 + 0.05 * h(k, 4, 83), Color(1, 1, 1, h(k, 5, 83)), 14)
	IB.add_mesh(r, r, "Cracks", cr, IB.smat(SH_ADD, {"col_a": Color(0.5, 0.2, 1.0), "col_b": Color(0.9, 0.6, 1.0), "energy": 2.6, "scroll": Vector2(0, -0.3),
		"tiling": Vector2(1, 6), "sharp": 1.5, "base": 0.35, "fres": 0.0, "fade_lo": 0.1, "fade_hi": 0.3}))
	var mist := IB.MB.new()
	for k in 4:
		mist.disc(Vector3((h(k, 1, 84) - 0.5) * 6.0, 0.15 + k * 0.08, -2.5 + (h(k, 2, 84) - 0.5) * 4.0), 0.0, 3.0 + h(k, 3, 84) * 2.0, 24, Color(1, 1, 1, h(k, 4, 84)), 4)
	IB.add_mesh(r, r, "Mist", mist, IB.smat(SH_VEIL, {"dark": Color(0.18, 0.1, 0.28), "glow": Color(0.6, 0.35, 0.9), "energy": 1.2, "scroll": Vector2(0.04, -0.03),
		"tiling": Vector2(5, 2), "twist": 0.6, "streak": 0.78, "opacity": 0.35, "fade_lo": 0.001, "fade_hi": 0.95}))
	IB.particles(r, r, "Ash", {"amount": 40, "life": 8.0, "shape": "box", "ext": Vector3(5, 0.5, 4), "pos": Vector3(0, 0.6, -2),
		"dir": Vector3.UP, "spread": 40.0, "v": Vector2(0.05, 0.25), "size": Vector2(0.5, 1.0), "quad": 0.05, "seed": 85, "turb": 0.4,
		"cols": PackedColorArray([Color(1.5, 0.8, 2.5, 0), Color(1.4, 0.7, 2.4, 0.9), Color(0.6, 0.3, 1.0, 0)]),
		"aabb": AABB(Vector3(-7, -1, -8), Vector3(14, 8, 12))})
	save_scene(EP3, r, "hollow")


## Obren's heart-stone (fist-sized, cracked amber): faceted crystal lumps with glowing veins, a hot core that beats
## (lub-dub), a halo and a pool of amber light that beat with it, a few rising motes. Origin = its resting point.
func _heart_stone() -> void:
	var r := IB.fx_root("HeartStone")
	var cb := IB.MB.new()
	var dirs := [Vector3(0, 1, 0), Vector3(0.7, 0.55, 0.2), Vector3(-0.6, 0.6, 0.3), Vector3(0.2, 0.5, -0.8), Vector3(-0.3, 0.45, -0.6), Vector3(0.5, 0.35, 0.7)]
	for k in dirs.size():
		var d: Vector3 = dirs[k]
		cb.crystal(Vector3(0, 0.07, 0) + d.normalized() * 0.02, d, 0.08 + 0.06 * h(k, 1, 91), 0.045 + 0.02 * h(k, 2, 91), 5,
			Color(0.9, 0.5, 0.16, h(k, 3, 91)))
	cb.crystal(Vector3(0, 0.0, 0), Vector3.UP, 0.13, 0.085, 6, Color(0.75, 0.38, 0.12, 0.5))
	IB.add_mesh(r, r, "Stone", cb, IB.smat(SH_SOLID, {"vein": Color(1.0, 0.55, 0.12), "energy": 3.2, "tiling": Vector2(2, 3), "scroll": Vector2(0.0, 0.08),
		"vein_w": 0.58, "rough": 0.28, "spec": 0.8, "rim": 0.6, "tip_glow": 1.6}), true)
	glow_ball(r, r, "Core", Vector3(0, 0.1, 0), 0.075, mem(Color(1, 0.62, 0.2), 2.2, 2, 0.0, 2.0, 1.2))
	glow_ball(r, r, "Halo", Vector3(0, 0.1, 0), 0.45, mem(Color(1, 0.55, 0.18), 0.45, 2, 0.0, 2.0, 2.8))
	glow_ball(r, r, "Aura", Vector3(0, 0.1, 0), 1.2, mem(Color(1, 0.5, 0.2), 0.1, 2, 0.0, 2.0, 3.5))
	pool(r, r, "Pool", Vector3(0, 0.005, 0), 1.3, mem(Color(1, 0.55, 0.2), 0.5, 2, 1.0, 2.4))
	IB.particles(r, r, "Motes", {"amount": 10, "life": 3.0, "shape": "sphere", "ext": Vector3(0.12, 0, 0), "pos": Vector3(0, 0.12, 0),
		"dir": Vector3.UP, "spread": 30.0, "v": Vector2(0.05, 0.2), "size": Vector2(0.5, 1.0), "quad": 0.03, "seed": 92, "turb": 0.3,
		"cols": PackedColorArray([Color(4, 2, 0.6, 0), Color(4, 2, 0.5, 1), Color(1.5, 0.5, 0.1, 0)]),
		"aabb": AABB(Vector3(-1, -1, -1), Vector3(2, 3, 2))})
	save_scene(EP3, r, "heart_stone")


# ================================================================ Episode 4: Ysolde's memories

func _ep4_props() -> void:
	_ep4_village("winter", true)
	_ep4_village("spring", false)
	_ep4_sapling("sapling_frost", true, 0.85)
	_ep4_seed()
	_ep4_frost()
	_ep4_burnt()
	_ep4_shoot("shoot", false)
	_ep4_shoot("seedling", true)


## H03 / H04: the same place in winter and in spring (the match cut). Origin = the seed spot. The child stands just
## south of it; the camera looks south over the seed at her face, so the village sits behind her (south, z 9-15):
## three cottages with lit windows, pines around, the mother's footprints (winter) leading back to the houses.
func _ep4_village(nm: String, snow: bool) -> void:
	var r := IB.fx_root(nm.capitalize())
	var pb := PB.new()
	var glow := PB.new()
	var ground_c := Color(0.9, 0.93, 1.0) if snow else Color(0.4, 0.55, 0.26)
	# the ground patch (snowfield / spring meadow), irregular edge, slightly raised
	pb.mound(Transform3D(), 15.0, 0.16, ground_c.darkened(0.05), 101, 40, 0.18, ground_c)
	if snow:
		for k in 9:   # drifts
			var a := h(k, 1, 102) * TAU
			var d := 3.0 + h(k, 2, 102) * 9.0
			pb.mound(xf_at(Vector3(cos(a) * d, 0.1, sin(a) * d), h(k, 3, 102) * 180, 1.0), 1.0 + h(k, 4, 102) * 1.4, 0.25 + h(k, 5, 102) * 0.25,
				Color(0.86, 0.9, 0.98), 103 + k, 16, 0.3, Color(0.96, 0.97, 1.0))
	else:
		for k in 30:   # tufts of new grass
			var gp := Vector3((h(k, 1, 104) - 0.5) * 16.0, 0.12, (h(k, 2, 104) - 0.5) * 16.0)
			if gp.length() < 0.9 or (gp.z < 1.0 and absf(gp.x) < 2.5):
				continue
			for b in 5:
				var a := b * 1.3 + k
				pb.tube(xf_at(gp, 0), PackedVector3Array([Vector3.ZERO, Vector3(cos(a) * 0.1, 0.3 + 0.12 * h(k, b, 105), sin(a) * 0.1)]),
					PackedFloat32Array([0.025, 0.0]), 3, Color(0.35, 0.6, 0.22).lerp(Color(0.5, 0.68, 0.25), h(k, b, 106)), 1.0)
	# the village behind her (south)
	var houses := [[Vector3(-5.2, 0.12, 11.0), 200.0], [Vector3(0.8, 0.12, 13.6), 176.0], [Vector3(6.4, 0.12, 10.4), 160.0]]
	var i := 0
	for hv: Array in houses:
		cottage(pb, glow, xf_at(hv[0], hv[1]), 110 + i, snow)
		i += 1
	# a fence of stakes along the village edge
	for k in 14:
		var fp := Vector3(-8.0 + k * 1.1, 0.12, 8.2 + sin(k * 0.7) * 0.4)
		pb.box(xf_at(fp, k * 7.0, 1.0, Vector3(0, 0, (h(k, 1, 107) - 0.5) * 10.0)), Vector3(0, 0.45, 0), Vector3(0.05, 0.45, 0.05), Color(0.34, 0.25, 0.18))
		if snow:
			pb.box(xf_at(fp, k * 7.0), Vector3(0, 0.92, 0), Vector3(0.07, 0.03, 0.07), Color(0.95, 0.96, 1.0))
	pb.box(xf_at(Vector3(-0.3, 0.12, 8.2), 0), Vector3(0, 0.6, 0), Vector3(7.6, 0.03, 0.03), Color(0.32, 0.23, 0.17))
	# pines around the edge (not between the camera and the child)
	for k in 12:
		var a := h(k, 1, 108) * TAU
		var d := 7.5 + h(k, 2, 108) * 6.5
		var p := Vector3(cos(a) * d, 0.1, sin(a) * d)
		if p.z < -4.0 and absf(p.x) < 5.0:
			continue
		pine(pb, xf_at(p, h(k, 3, 108) * 90), 3.5 + h(k, 4, 108) * 3.0, snow, 120 + k)
	if snow:
		# the mother's footprints: from the seed back to the middle cottage
		var fprev := Vector3(0.4, 0.17, 0.5)
		for k in 16:
			var t := float(k) / 15.0
			var p := Vector3(0.4, 0.17, 0.5).lerp(Vector3(0.9, 0.17, 11.8), t)
			var side := 0.13 if k % 2 == 0 else -0.13
			pb.lathe(xf_at(p + Vector3(side, -0.005, 0), 2) * Transform3D(Basis().scaled(Vector3(0.55, 1.0, 1.0)), Vector3.ZERO), PackedVector2Array([Vector2(0.13, 0.0), Vector2(0.1, 0.014), Vector2(0.0, 0.01)]), 10, PackedColorArray([Color(0.6, 0.66, 0.82)]))
			fprev = p
		# the trowel she left stuck in the snow
		var tx := xf_at(Vector3(-0.45, 0.17, 0.35), 40, 1.0, Vector3(-20, 0, 12))
		pb.tube(tx, PackedVector3Array([Vector3(0, 0.1, 0), Vector3(0, 0.32, 0)]), PackedFloat32Array([0.018, 0.02]), 6, Color(0.4, 0.28, 0.18))
		pb.box(tx, Vector3(0, 0.04, 0), Vector3(0.05, 0.08, 0.008), Color(0.45, 0.45, 0.5))
	add_paint(r, r, "Village", pb)
	add_glowbox(r, r, "Windows", glow)
	var wg := IB.MB.new()
	for hv: Array in houses:
		var b := xf_at(hv[0], hv[1])
		for sx in [-0.95, 0.95]:
			var p: Vector3 = b * Vector3(sx, 1.05, 0.25)
			wg.disc(p, 0.0, 0.9, 16, Color.WHITE, 3)
	IB.add_mesh(r, r, "WindowGlow", wg, mem(Color(1, 0.6, 0.25), 0.28, 1, 1.0, 2.5))
	for hv: Array in houses:   # chimney smoke
		var b := xf_at(hv[0], hv[1])
		IB.particles(r, r, "Smoke%d" % houses.find(hv), {"amount": 16, "life": 6.0, "shape": "sphere", "ext": Vector3(0.12, 0, 0),
			"pos": b * Vector3(0.81, 3.6, -1.68), "dir": Vector3(0.15, 1, 0.1), "spread": 10.0, "v": Vector2(0.3, 0.5), "size": Vector2(1.5, 3.0),
			"quad": 0.6, "seed": 130 + houses.find(hv), "turb": 0.3, "additive": false,
			"cols": PackedColorArray([Color(0.75, 0.72, 0.72, 0), Color(0.72, 0.7, 0.72, 0.45), Color(0.8, 0.78, 0.8, 0)]),
			"aabb": AABB(Vector3(-5, -1, -5), Vector3(10, 10, 10))})
	if snow:
		IB.particles(r, r, "Snowfall", {"amount": 380, "life": 9.0, "shape": "box", "ext": Vector3(11, 0.5, 11), "pos": Vector3(0, 7.5, 4),
			"dir": Vector3.DOWN, "spread": 12.0, "v": Vector2(0.5, 0.9), "grav": Vector3(0.12, -0.25, 0.05), "size": Vector2(0.6, 1.2),
			"quad": 0.06, "seed": 140, "turb": 0.5, "additive": false,
			"cols": PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0.95), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0)]),
			"aabb": AABB(Vector3(-13, -2, -9), Vector3(26, 12, 26))})
	else:
		IB.particles(r, r, "Pollen", {"amount": 60, "life": 7.0, "shape": "box", "ext": Vector3(6, 1.2, 6), "pos": Vector3(0, 1.4, 2),
			"dir": Vector3.UP, "spread": 70.0, "v": Vector2(0.05, 0.2), "size": Vector2(0.5, 1.0), "quad": 0.05, "seed": 141, "turb": 0.4,
			"cols": PackedColorArray([Color(2.4, 2.0, 1.0, 0), Color(2.2, 1.9, 0.9, 0.9), Color(1.2, 1.0, 0.4, 0)]),
			"aabb": AABB(Vector3(-8, -1, -6), Vector3(16, 6, 16))})
		IB.particles(r, r, "Butterflies", {"amount": 7, "life": 6.0, "shape": "box", "ext": Vector3(3, 0.6, 3), "pos": Vector3(0, 0.9, 1.5),
			"dir": Vector3(1, 0.3, 0), "spread": 180.0, "v": Vector2(0.3, 0.6), "size": Vector2(0.8, 1.2), "quad": 0.11, "seed": 142, "turb": 1.2, "additive": false,
			"cols": PackedColorArray([Color(1, 0.85, 0.3, 0), Color(1, 0.8, 0.25, 1), Color(0.95, 0.95, 1, 1), Color(0.9, 0.9, 1, 0)]),
			"aabb": AABB(Vector3(-6, -1, -5), Vector3(12, 5, 12))})
	save_scene(EP4, r, nm)


## The seed asleep in the snow (H03): a little heap of dug black earth on the snow, the seed's faint green-gold breath.
func _ep4_seed() -> void:
	var r := IB.fx_root("Seed")
	var pb := PB.new()
	pb.mound(Transform3D(), 0.34, 0.09, Color(0.2, 0.14, 0.1), 150, 16, 0.4, Color(0.26, 0.18, 0.12))
	for k in 6:   # clods and snow crumbs
		var a := k * 1.05
		pb.rock(xf_at(Vector3(cos(a) * 0.38, 0.0, sin(a) * 0.3), k * 40), 0.04, 0.05, 5, Color(0.22, 0.16, 0.11) if k % 2 == 0 else Color(0.9, 0.93, 1.0), 151 + k)
	add_paint(r, r, "Earth", pb)
	glow_ball(r, r, "Seed", Vector3(0, 0.1, 0), 0.03, mem(Color(0.85, 1.0, 0.45), 3.0, 3, 0.0))
	glow_ball(r, r, "Breath", Vector3(0, 0.1, 0), 0.18, mem(Color(0.65, 1.0, 0.4), 0.35, 3, 0.0, 2.0, 2.5))
	pool(r, r, "Pool", Vector3(0, 0.1, 0), 0.5, mem(Color(0.6, 1.0, 0.4), 0.12, 3, 1.0, 3.0))
	save_scene(EP4, r, "seed")


func _ep4_sapling(nm: String, frost: bool, hgt: float) -> void:
	var r := IB.fx_root(nm.to_pascal_case())
	var pb := PB.new()
	young_tree(pb, Transform3D(), hgt, 160 if frost else 161, frost)
	pb.mound(Transform3D(), 0.3, 0.06, Color(0.28, 0.2, 0.13) if not frost else Color(0.78, 0.84, 0.92), 162, 14, 0.4)
	add_paint(r, r, "Tree", pb)
	if frost:   # ice on the twigs, catching the light
		var ice := IB.MB.new()
		for k in 14:
			var a := k * 2.4
			var y := 0.25 + h(k, 1, 163) * hgt * 0.75
			ice.crystal(Vector3(cos(a) * 0.05, y, sin(a) * 0.05), Vector3(cos(a), 0.3, sin(a)), 0.05 + 0.04 * h(k, 2, 163), 0.012, 4, Color(0.8, 0.92, 1.0, h(k, 3, 163)))
		IB.add_mesh(r, r, "Ice", ice, IB.smat(SH_SOLID, {"vein": Color(0.6, 0.85, 1.0), "energy": 1.4, "tiling": Vector2(2, 4), "scroll": Vector2(0, 0.1),
			"vein_w": 0.7, "rough": 0.12, "spec": 0.9, "rim": 0.7, "tip_glow": 1.0}), true)
	else:
		glow_ball(r, r, "Life", Vector3(0, hgt * 0.8, 0), 0.6, mem(Color(0.75, 1.0, 0.5), 0.25, 3, 0.0, 2.0, 2.8))
	save_scene(EP4, r, nm)


## H05: the frost clearing where the Master found her. Frosted ground with rime crystals, bare birches, a low stone,
## faint snow in the air. Origin = the sapling in frost; the child is south-east of it, the Master behind (north).
func _ep4_frost() -> void:
	var r := IB.fx_root("Frost")
	var pb := PB.new()
	pb.mound(Transform3D(), 9.0, 0.08, Color(0.72, 0.78, 0.86), 170, 36, 0.2, Color(0.84, 0.88, 0.95))
	for k in 22:   # frozen grass tufts
		var gp := Vector3((h(k, 1, 171) - 0.5) * 12.0, 0.07, (h(k, 2, 171) - 0.5) * 10.0)
		if gp.length() < 1.2:
			continue
		for b in 5:
			var a := b * 1.3 + k
			pb.tube(xf_at(gp, 0), PackedVector3Array([Vector3.ZERO, Vector3(cos(a) * 0.1, 0.28 + 0.1 * h(k, b, 172), sin(a) * 0.1)]),
				PackedFloat32Array([0.022, 0.0]), 3, Color(0.62, 0.66, 0.6), 1.0, 1.0, Color(0.95, 0.97, 1.0))
	pb.rock(xf_at(Vector3(-1.9, 0.05, 0.9), 30), 0.45, 0.5, 7, Color(0.5, 0.5, 0.55), 173)
	pb.mound(xf_at(Vector3(-1.9, 0.5, 0.9), 0), 0.38, 0.08, Color(0.9, 0.93, 1.0), 174, 12, 0.3)
	# bare birches (white bark, black marks) in a loose ring north / west / east
	for k in 9:
		var a := PI + h(k, 1, 175) * PI * 1.2 - 0.1 * PI
		var d := 4.5 + h(k, 2, 175) * 4.0
		var p := Vector3(cos(a) * d, 0.05, sin(a) * d)
		var hh := 5.0 + h(k, 3, 175) * 3.0
		var tx := xf_at(p, k * 40)
		var pts := PackedVector3Array()
		for i in 6:
			var t := float(i) / 5.0
			pts.append(Vector3(sin(t * 3.0 + k) * 0.15 * t, t * hh, cos(t * 2.0 + k) * 0.1 * t))
		pb.tube(tx, pts, PackedFloat32Array([0.16, 0.13, 0.1, 0.08, 0.05, 0.01]), 8, Color(0.88, 0.86, 0.82))
		for m in 5:   # bark marks
			pb.box(tx, Vector3(0, 0.5 + m * hh * 0.14, 0.1), Vector3(0.1, 0.025, 0.08), Color(0.12, 0.1, 0.1))
		for b in 4:
			var bi := 2 + b % 3
			var bd := Vector3(cos(b * 1.9 + k), 0.9, sin(b * 1.9 + k)).normalized()
			pb.tube(tx, PackedVector3Array([pts[bi], pts[bi] + bd * 1.2, pts[bi] + bd * 2.0 + Vector3(0, 0.4, 0)]), PackedFloat32Array([0.05, 0.025, 0.005]), 5, Color(0.3, 0.26, 0.24))
	add_paint(r, r, "Clearing", pb)
	var rime := IB.MB.new()
	for k in 60:
		var a := h(k, 1, 176) * TAU
		var d := 0.4 + sqrt(h(k, 2, 176)) * 6.0
		rime.crystal(Vector3(cos(a) * d, 0.06, sin(a) * d), Vector3((h(k, 3, 176) - 0.5), 1.0, (h(k, 4, 176) - 0.5)), 0.05 + 0.08 * h(k, 5, 176), 0.015, 4,
			Color(0.85, 0.94, 1.0, h(k, 6, 176)))
	IB.add_mesh(r, r, "Rime", rime, IB.smat(SH_SOLID, {"vein": Color(0.7, 0.9, 1.0), "energy": 1.6, "tiling": Vector2(2, 3), "scroll": Vector2(0, 0.1),
		"vein_w": 0.65, "rough": 0.1, "spec": 1.0, "rim": 0.8, "tip_glow": 1.4}), true)
	IB.particles(r, r, "Flakes", {"amount": 70, "life": 9.0, "shape": "box", "ext": Vector3(5, 0.5, 5), "pos": Vector3(0, 5.5, 0),
		"dir": Vector3.DOWN, "spread": 15.0, "v": Vector2(0.3, 0.6), "grav": Vector3(0.05, -0.1, 0), "size": Vector2(0.5, 1.0), "quad": 0.05,
		"seed": 177, "turb": 0.4, "additive": false,
		"cols": PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0)]),
		"aabb": AABB(Vector3(-7, -2, -7), Vector3(14, 10, 14))})
	save_scene(EP4, r, "frost")


## H08 / H09: the burned wood, frozen. Black ash ground, charred trunks (some snapped), frost crust and ice shards
## pushed up through the ash, fallen trunks, grey ash falling. Origin = where the green shoot comes up (H09); she
## stands north-west of it in H08.
func _ep4_burnt() -> void:
	var r := IB.fx_root("Burnt")
	var pb := PB.new()
	var ash := Color(0.075, 0.07, 0.07)
	pb.mound(Transform3D(), 14.0, 0.1, ash.darkened(0.1), 180, 40, 0.2, ash)
	for k in 14:   # frost crust patches
		var a := h(k, 1, 181) * TAU
		var d := 1.0 + h(k, 2, 181) * 10.0
		pb.mound(xf_at(Vector3(cos(a) * d, 0.08, sin(a) * d), h(k, 3, 181) * 180, 1.0), 0.4 + h(k, 4, 181) * 0.8, 0.04,
			Color(0.26, 0.29, 0.34), 182 + k, 14, 0.4, Color(0.36, 0.4, 0.47))
	# the charred trunks: black, cracked, snapped tops, frost on their tops and north faces
	for k in 34:
		var a := h(k, 1, 183) * TAU
		var d := 3.0 + h(k, 2, 183) * 10.0
		if k >= 16:   # the far ring: a wall of dead trunks behind (north, west, east), no sky gaps at eye level
			a = PI + (float(k - 16) / 17.0) * PI * 1.3 - PI * 0.15 + (h(k, 7, 183) - 0.5) * 0.2
			d = 9.0 + h(k, 2, 183) * 4.5
		var p := Vector3(cos(a) * d, 0.05, sin(a) * d)
		if p.z > 1.0 and absf(p.x) < 3.0:
			continue   # keep the H09 low camera line (south) clear
		if p.z > 3.0 and p.x > 1.0 and p.x < 8.0:
			continue   # and the H08 camera path (south-east)
		var hh := 2.5 + h(k, 3, 183) * 6.0 + (3.0 if k >= 16 else 0.0)
		var tx := xf_at(p, k * 33, 1.0, Vector3((h(k, 4, 183) - 0.5) * 10.0, 0, (h(k, 5, 183) - 0.5) * 10.0))
		var pts := PackedVector3Array()
		for i in 6:
			var t := float(i) / 5.0
			pts.append(Vector3(sin(t * 2.0 + k) * 0.12 * t, t * hh, cos(t * 3.0 + k) * 0.1 * t))
		var rr := 0.2 + h(k, 6, 183) * 0.22
		pb.tube(tx, pts, PackedFloat32Array([rr * 1.4, rr, rr * 0.9, rr * 0.8, rr * 0.65, rr * 0.3]), 9, Color(0.08, 0.07, 0.07), 0.0, 1.0, Color(0.05, 0.05, 0.05))
		pb.lathe(tx, PackedVector2Array([Vector2(rr * 0.66, hh * 0.98), Vector2(rr * 0.5, hh + 0.12), Vector2(0.0, hh + 0.2)]), 7,
			PackedColorArray([Color(0.62, 0.68, 0.78)]), 0.0, 0.0, 3.0, 0.8, k)   # frost on the snapped top
		for b in 2 + k % 3:
			var bi := 2 + b
			var bd := Vector3(cos(b * 2.1 + k), 0.5, sin(b * 2.1 + k)).normalized()
			pb.tube(tx, PackedVector3Array([pts[mini(bi, 5)], pts[mini(bi, 5)] + bd * 0.9]), PackedFloat32Array([rr * 0.35, 0.02]), 5, Color(0.07, 0.06, 0.06))
	for k in 5:   # fallen trunks
		var a := h(k, 1, 184) * TAU
		var d := 3.5 + h(k, 2, 184) * 7.0
		var p := Vector3(cos(a) * d, 0.25, sin(a) * d)
		if p.z > 1.0 and absf(p.x) < 3.0:
			p.z -= 5.0
		var dir := Vector3(cos(a + 1.3), 0.05, sin(a + 1.3))
		var l := 3.0 + h(k, 3, 184) * 3.0
		pb.tube(Transform3D(), PackedVector3Array([p, p + dir * l * 0.5, p + dir * l]), PackedFloat32Array([0.28, 0.24, 0.12]), 8, Color(0.08, 0.07, 0.07))
	# ice shards pushed up through the ash (the frost that followed the fire)
	for k in 26:
		var a := h(k, 1, 185) * TAU
		var d := 1.2 + h(k, 2, 185) * 9.0
		var p := Vector3(cos(a) * d, 0.05, sin(a) * d)
		if p.z > 0.6 and absf(p.x) < 1.2:
			continue
		pb.rock(xf_at(p, h(k, 3, 185) * 90, 1.0, Vector3((h(k, 4, 185) - 0.5) * 50, 0, (h(k, 5, 185) - 0.5) * 50)), 0.08 + 0.12 * h(k, 6, 185),
			0.3 + 0.9 * h(k, 7, 185), 5, Color(0.55, 0.68, 0.82), 186 + k, 0.0)
	add_paint(r, r, "Wood", pb)
	var cold := IB.MB.new()
	for k in 3:
		cold.disc(Vector3((h(k, 1, 187) - 0.5) * 8.0, 0.2 + k * 0.1, (h(k, 2, 187) - 0.5) * 8.0), 0.0, 4.0 + h(k, 3, 187) * 2.0, 24, Color(1, 1, 1, h(k, 4, 187)), 4)
	IB.add_mesh(r, r, "ColdMist", cold, IB.smat(SH_VEIL, {"dark": Color(0.4, 0.44, 0.52), "glow": Color(0.7, 0.78, 0.9), "energy": 0.9, "scroll": Vector2(0.03, -0.02),
		"tiling": Vector2(5, 2), "twist": 0.4, "streak": 0.85, "opacity": 0.25, "fade_lo": 0.001, "fade_hi": 0.95}))
	IB.particles(r, r, "AshFall", {"amount": 120, "life": 10.0, "shape": "box", "ext": Vector3(9, 0.5, 9), "pos": Vector3(0, 7.0, 0),
		"dir": Vector3.DOWN, "spread": 20.0, "v": Vector2(0.2, 0.45), "grav": Vector3(0.05, -0.08, 0.02), "size": Vector2(0.5, 1.1), "quad": 0.06,
		"seed": 188, "turb": 0.6, "additive": false,
		"cols": PackedColorArray([Color(0.5, 0.5, 0.52, 0), Color(0.55, 0.55, 0.58, 0.85), Color(0.6, 0.6, 0.62, 0.8), Color(0.6, 0.6, 0.62, 0)]),
		"aabb": AABB(Vector3(-11, -2, -11), Vector3(22, 12, 22))})
	save_scene(EP4, r, "burnt")


## H09: one green shoot in the black ash: a bent stem, two seed leaves and a first true leaf, a ring of melted frost
## around it, a faint green breath of light. Origin = its root; about 16 cm tall.
func _ep4_shoot(nm: String, spring: bool) -> void:
	var r := IB.fx_root("Shoot")
	var pb := PB.new()
	pb.lathe(Transform3D(), PackedVector2Array([Vector2(0.32, 0.0), Vector2(0.24, 0.012), Vector2(0.12, 0.016), Vector2(0.0, 0.012)]), 20,
		PackedColorArray([Color(0.3, 0.22, 0.15), Color(0.24, 0.17, 0.11), Color(0.2, 0.14, 0.1)]) if spring else PackedColorArray([Color(0.16, 0.15, 0.15), Color(0.09, 0.08, 0.08), Color(0.06, 0.055, 0.05)]), 0.0, 0.0, 5.0, 0.4, 190)
	for k in (0 if spring else 10):   # frost crumbs around the melted ring (winter ash only)
		var a := k * 0.63
		pb.rock(xf_at(Vector3(cos(a) * 0.36, 0.0, sin(a) * 0.36), k * 30), 0.025, 0.03, 5, Color(0.7, 0.76, 0.86), 191 + k)
	var stem := PackedVector3Array([Vector3(0, 0.0, 0), Vector3(0.004, 0.04, 0), Vector3(0.01, 0.08, 0.004), Vector3(0.006, 0.12, 0.006), Vector3(-0.004, 0.15, 0.004)])
	pb.tube(Transform3D(), stem, PackedFloat32Array([0.007, 0.0065, 0.006, 0.0055, 0.004]), 8, Color(0.42, 0.62, 0.3), 0.0, 1.0, Color(0.55, 0.85, 0.35))
	var top := stem[4]
	for sx in [-1.0, 1.0]:   # the two seed leaves
		var dir := Vector3(sx, 0.35, 0.15).normalized()
		pb.tube(Transform3D(), PackedVector3Array([top, top + dir * 0.025 + Vector3(0, 0.006, 0), top + dir * 0.05, top + dir * 0.065 - Vector3(0, 0.004, 0)]),
			PackedFloat32Array([0.002, 0.016, 0.014, 0.0]), 8, Color(0.34, 0.66, 0.26), 1.0, 0.22, Color(0.5, 0.8, 0.32))
	pb.tube(Transform3D(), PackedVector3Array([top, top + Vector3(0.004, 0.018, 0.01), top + Vector3(0.006, 0.034, 0.018)]),
		PackedFloat32Array([0.002, 0.008, 0.0]), 7, Color(0.42, 0.74, 0.28), 1.0, 0.3, Color(0.6, 0.86, 0.38))
	add_paint(r, r, "Shoot", pb, false)
	glow_ball(r, r, "Breath", top, 0.045, mem(Color(0.6, 1.0, 0.4), 0.35, 3, 0.0, 2.0, 2.2))
	glow_ball(r, r, "Aura", top, 0.22, mem(Color(0.55, 1.0, 0.4), 0.07, 3, 0.0, 2.0, 3.0))
	pool(r, r, "Pool", Vector3(0, 0.018, 0), 0.3, mem(Color(0.55, 1.0, 0.4), 0.14, 3, 1.0, 2.6))
	IB.particles(r, r, "Motes", {"amount": 5, "life": 4.0, "shape": "sphere", "ext": Vector3(0.04, 0, 0), "pos": top,
		"dir": Vector3.UP, "spread": 25.0, "v": Vector2(0.02, 0.06), "size": Vector2(0.6, 1.0), "quad": 0.012, "seed": 195, "turb": 0.2,
		"cols": PackedColorArray([Color(1.8, 3.0, 1.0, 0), Color(1.6, 2.8, 0.9, 1), Color(0.6, 1.2, 0.3, 0)]),
		"aabb": AABB(Vector3(-0.5, -0.2, -0.5), Vector3(1, 1, 1))})
	save_scene(EP4, r, nm)


# ================================================================ baked kit models (young apprentices, the fallen)

func _apprentices() -> Array:
	# young Vessa / Torvald / Ysolde beside the red / blue / green flames (ORRERY_SPOTS), facing the centre
	var out: Array = []
	var who := [VESSA, TORVALD, YSOLDE]
	for k in 3:
		var p: Vector3 = ORRERY_SPOTS[k]
		var dir := Vector3(p.x, 0, p.z).normalized()
		var at := p + dir * 0.7 + Vector3(signf(p.x) * 0.75, 0, 0)
		var yaw := rad_to_deg(atan2(-at.x, -at.z))
		out.append(IB.unit(who[k], at, yaw, "idle", 10, 0.62))
	# the boy (young Malrik) is not baked here any more: forge_ep3_memories.set actor m_boy_o (props/boy.tscn, ep3_extras.gd)
	return out


func _fallen() -> Array:
	# her army, burned and frozen in the ash (H08): archers, a vinelasher, a stagrunner, thornlings, all dead
	return [IB.unit(WILDWOOD, Vector3(-2.6, 0.08, -2.2), 140, "death", 45), IB.unit(WILDWOOD, Vector3(3.4, 0.08, -3.6), 220, "death", 45),
		IB.unit(VINELASHER, Vector3(-4.2, 0.08, 1.4), 80, "death", 45), IB.unit(STAGRUNNER, Vector3(5.2, 0.08, -0.6), 250, "death", 45),
		IB.unit(THORNLING, Vector3(-1.2, 0.08, -4.6), 30, "death", 45), IB.unit(WILDWOOD, Vector3(1.6, 0.08, -6.2), 180, "death", 45),
		IB.unit(THORNLING, Vector3(-5.8, 0.08, -3.4), 300, "death", 45)]


## Real kit models posed for a few frames (idle / death), merged into one mesh (paint = vertex colours on the painted
## material, glow parts kept only when alive). frozen = grey-blue ash tint, no glow.
func _bake(path: String, units: Array, frozen: bool) -> void:
	var holder := Node3D.new()
	holder.name = "Bake"
	root.add_child(holder)
	var list: Array = []
	for u: Dictionary in units:
		var ps := load(u["scene"]) as PackedScene
		if ps == null:
			push_warning("memory_bake: missing " + String(u["scene"]))
			continue
		var n := ps.instantiate() as Node3D
		n.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(float(u["yaw"]))).scaled(Vector3.ONE * float(u["scale"])), u["pos"])
		holder.add_child(n)
		list.append([n, u])
	for k in 3:
		await process_frame
	var frames := 60
	for fr in frames:
		for pr: Array in list:
			var u: Dictionary = pr[1]
			if frames - int(u["f"]) == fr and u["act"] == "death" and pr[0].has_method("play_death"):
				pr[0].call("play_death")
		await process_frame
	var paint_b := IB._Bucket.new()
	var glow_b := IB._Bucket.new()
	for pr: Array in list:
		_collect(pr[0], holder, paint_b, glow_b, frozen)
	var mesh := ArrayMesh.new()
	var pm := StandardMaterial3D.new()
	pm.vertex_color_use_as_albedo = true
	pm.vertex_color_is_srgb = true
	pm.roughness = 0.85
	pm.rim_enabled = true
	pm.rim = 0.3
	var tris := paint_b.commit(mesh, pm)
	if not frozen:
		var gm := ShaderMaterial.new()
		gm.shader = load(IB.SH_ARMY_GLOW)
		tris += glow_b.commit(mesh, gm)
	ResourceSaver.save(mesh, path + ".res")
	mesh.take_over_path(path + ".res")
	var sroot := Node3D.new()
	sroot.name = path.get_file().to_pascal_case()
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = mesh
	sroot.add_child(mi)
	mi.owner = sroot
	var ps2 := PackedScene.new()
	ps2.pack(sroot)
	ResourceSaver.save(ps2, path + ".tscn")
	print("memory_bake: %s.tscn  units %d  surfaces %d  tris %d" % [path, list.size(), mesh.get_surface_count(), tris])
	sroot.free()
	holder.queue_free()
	await process_frame


func _collect(n: Node, holder: Node3D, paint_b: RefCounted, glow_b: RefCounted, frozen: bool) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh and mi.is_visible_in_tree():
			var xf := holder.global_transform.affine_inverse() * mi.global_transform
			for s in mi.mesh.get_surface_count():
				var mat := mi.get_active_material(s)
				var cl: Array = IB._classify(mat)
				if _is_face(mat) and not frozen:
					# FaceKit face (+ hair / ears / beard): its colours are the vertex COLORs (unit_face.gdshader, sRGB)
					paint_b.add(mi.mesh, s, xf, null)
				elif cl[0] == "paint" or cl[0] == "keep":
					var col: Color = cl[1] if cl[1] is Color else Color(0.5, 0.5, 0.5)
					if frozen:
						var g := col.get_luminance()
						col = Color(g, g, g).lerp(Color(0.5, 0.56, 0.66), 0.5).darkened(0.45)
					paint_b.add(mi.mesh, s, xf, Color(col.r, col.g, col.b, 1.0))
				elif cl[0] == "glow" and not frozen:
					var gc: Color = cl[1]
					glow_b.add(mi.mesh, s, xf, Color(gc.r, gc.g, gc.b, 0.5))
	for c in n.get_children():
		_collect(c, holder, paint_b, glow_b, frozen)


## The face kit's material (art/units/kit/face/unit_face.gdshader, face rework 2026-09-28): colour per vertex.
static func _is_face(mat: Material) -> bool:
	return mat is ShaderMaterial and (mat as ShaderMaterial).shader != null 		and (mat as ShaderMaterial).shader.resource_path.get_file() == "unit_face.gdshader"
