extends SceneTree
## E34 Ep3 polish (docs/design/episode3-4-opening.md 4.2 + 8): props the first memory bake did not have. Kept out of
## memory_bake.gd (shared with Ep4) so the two episodes never edit one file.
##   props/boy.tscn             the gravedigger's boy (young Malrik, ~1.25 m): shaggy black hair over one eye, pale face,
##                              a too-big grey-violet smock with a rope belt, a long violet scarf, boots. NOT the adult kit
##                              model scaled down (that read as a small knight).
##   props/heart_stone_hand.tscn  the heart-stone as Malrik holds it on the ridge (forge_evenmead actor `stone`): the same
##                              cracked amber cluster as the Hollow's, hand-sized, glows beating (mem_glow mode 2), no pool.
##   props/heart_pulse.tscn     vfx scene (cine `vfx ... scene=`): one lub-dub shock of amber light per 1.15 s, posed by
##                              set_cine_age(age) (props/heart_pulse.gd), so stills / seek / record agree with the thumps.
##   props/memory_grade.tscn    a full-screen memory grade for shots in sets without one (W02 in forge_watch_keep):
##                              desaturate + violet lift (mix pass), warm-violet tint + heavy vignette (multiply pass).
## Run: tools\godot_run.ps1 --headless --path . -s res://art/cinematics/stage_sets/forge_ep3_memories/tools/ep3_extras.gd --quit-after 3000

const MB3 := preload("res://art/cinematics/stage_sets/forge_ep3_memories/tools/memory_bake.gd")
const IB := preload("res://art/cinematics/stage_sets/forge_intro_vessa/tools/intro_bake.gd")
const EP3 := "res://art/cinematics/stage_sets/forge_ep3_memories/props/"
const PAINT_PATH := "res://art/environment/env_painted_mat.tres"

var paint: Material


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	paint = load(PAINT_PATH)
	_boy()
	_heart_stone_hand()
	_heart_pulse()
	_memory_grade()
	print("ep3_extras: done")
	quit(0)


func add_paint(parent: Node3D, owner: Node, nm: String, pb: MB3.PB, shadows := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = pb.mesh()
	mi.material_override = paint
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	parent.add_child(mi)
	mi.owner = owner
	return mi


static func sph(pb: MB3.PB, c: Vector3, r: Vector3, col: Color, seg := 12, top := Color(-1, 0, 0)) -> void:
	# an ellipsoid (lathe of a half circle), radii r
	var prof := PackedVector2Array()
	var cols := PackedColorArray()
	for i in 9:
		var a := -PI * 0.5 + PI * float(i) / 8.0
		prof.append(Vector2(cos(a) * r.x, sin(a) * r.y))
		cols.append(col if top.r < 0.0 else col.lerp(top, float(i) / 8.0))
	pb.lathe(Transform3D(Basis().scaled(Vector3(1.0, 1.0, r.z / r.x)), c), prof, seg, cols)


# ================================================================ the boy

func _boy() -> void:
	var r := IB.fx_root("Boy")
	var pb := MB3.PB.new()
	var id := Transform3D()
	var skin := Color(0.86, 0.76, 0.74)
	var skin_d := Color(0.7, 0.58, 0.6)
	var hair := Color(0.07, 0.06, 0.09)
	var smock := Color(0.36, 0.33, 0.4)
	var smock_d := Color(0.24, 0.22, 0.28)
	var patch := Color(0.42, 0.36, 0.3)
	var scarf := Color(0.42, 0.24, 0.55)
	var legs := Color(0.14, 0.13, 0.17)
	var boot := Color(0.2, 0.14, 0.1)
	var rope := Color(0.55, 0.45, 0.3)
	# legs + boots (too big: hand-me-downs)
	for sx in [-1.0, 1.0]:
		pb.tube(id, PackedVector3Array([Vector3(sx * 0.075, 0.08, 0.0), Vector3(sx * 0.072, 0.28, 0.0), Vector3(sx * 0.07, 0.46, 0.0)]),
			PackedFloat32Array([0.05, 0.047, 0.055]), 8, legs)
		pb.lathe(MB3.xf_at(Vector3(sx * 0.078, 0.0, 0.03), 0.0).scaled_local(Vector3(1.0, 1.0, 1.55)),
			PackedVector2Array([Vector2(0.075, 0.0), Vector2(0.08, 0.05), Vector2(0.066, 0.11), Vector2(0.056, 0.15), Vector2(0.0, 0.155)]), 10,
			PackedColorArray([boot.darkened(0.3), boot, boot, boot.lightened(0.05)]))
	# the smock: a long bell of cloth, knee length, folds, hem ragged (wob), a patch on the front
	pb.lathe(id, PackedVector2Array([Vector2(0.25, 0.3), Vector2(0.235, 0.36), Vector2(0.2, 0.5), Vector2(0.17, 0.62), Vector2(0.17, 0.72),
		Vector2(0.18, 0.78), Vector2(0.14, 0.83), Vector2(0.07, 0.86), Vector2(0.0, 0.865)]), 20,
		PackedColorArray([smock_d, smock_d, smock, smock, smock, smock, smock, smock]), 0.0, 0.06, 7.0, 0.12, 5)
	pb.box(Transform3D(Basis(Vector3.RIGHT, -0.12), Vector3(-0.07, 0.43, 0.21)), Vector3.ZERO, Vector3(0.05, 0.055, 0.012), patch)
	pb.box(Transform3D(Basis(Vector3.RIGHT, -0.12), Vector3(0.09, 0.37, 0.22)), Vector3.ZERO, Vector3(0.035, 0.04, 0.012), patch.darkened(0.15))
	# rope belt, knot and a hanging end
	pb.tube(id, _ring(Vector3(0, 0.58, 0), 0.185, 0.2, 18), _const(19, 0.018), 5, rope)
	pb.tube(id, PackedVector3Array([Vector3(0.1, 0.57, 0.16), Vector3(0.12, 0.47, 0.18), Vector3(0.13, 0.4, 0.17)]), PackedFloat32Array([0.016, 0.014, 0.01]), 5, rope)
	# arms: sleeves too long, small hands; the left hangs, the right half-raised (a finger on the words he reads)
	pb.tube(id, PackedVector3Array([Vector3(-0.16, 0.78, 0.0), Vector3(-0.21, 0.66, 0.03), Vector3(-0.23, 0.53, 0.06), Vector3(-0.23, 0.47, 0.07)]),
		PackedFloat32Array([0.055, 0.05, 0.052, 0.06]), 8, smock)
	sph(pb, Vector3(-0.23, 0.44, 0.075), Vector3(0.035, 0.04, 0.035), skin, 8)
	pb.tube(id, PackedVector3Array([Vector3(0.16, 0.78, 0.0), Vector3(0.22, 0.67, 0.06), Vector3(0.21, 0.6, 0.17), Vector3(0.2, 0.6, 0.21)]),
		PackedFloat32Array([0.055, 0.05, 0.052, 0.058]), 8, smock)
	sph(pb, Vector3(0.195, 0.61, 0.245), Vector3(0.034, 0.036, 0.04), skin, 8)
	# neck + the scarf: two turns round the neck, one long tail down the front-left, one short tail over the back
	pb.tube(id, PackedVector3Array([Vector3(0, 0.82, 0), Vector3(0, 0.9, 0.0)]), PackedFloat32Array([0.05, 0.048]), 8, skin_d)
	pb.tube(id, _ring(Vector3(0, 0.845, 0.0), 0.095, 0.02, 16), _const(17, 0.042), 7, scarf)
	pb.tube(id, _ring(Vector3(0, 0.81, 0.0), 0.11, -0.02, 16), _const(17, 0.04), 7, scarf.darkened(0.1))
	pb.tube(id, PackedVector3Array([Vector3(-0.06, 0.82, 0.1), Vector3(-0.09, 0.7, 0.17), Vector3(-0.1, 0.55, 0.2), Vector3(-0.095, 0.44, 0.21)]),
		PackedFloat32Array([0.045, 0.042, 0.04, 0.036]), 7, scarf, 0.0, 0.45)
	pb.tube(id, PackedVector3Array([Vector3(0.05, 0.83, -0.1), Vector3(0.09, 0.74, -0.17), Vector3(0.1, 0.64, -0.2)]),
		PackedFloat32Array([0.042, 0.04, 0.034]), 7, scarf.darkened(0.08), 0.0, 0.45)
	# head: big (a child's proportions), pale, a small chin; ears
	var hc := Vector3(0, 1.03, 0.01)
	sph(pb, hc, Vector3(0.155, 0.165, 0.15), skin, 16, skin.lightened(0.04))
	sph(pb, hc + Vector3(0, -0.085, 0.045), Vector3(0.1, 0.07, 0.09), skin, 12)
	for sx in [-1.0, 1.0]:
		sph(pb, hc + Vector3(sx * 0.152, -0.005, -0.01), Vector3(0.025, 0.04, 0.02), skin_d, 8)
	# face: big dark eyes with a pale glint (the future Malrik's eyes: faint violet), small nose, a straight mouth
	for sx in [-1.0, 1.0]:
		sph(pb, hc + Vector3(sx * 0.058, 0.0, 0.133), Vector3(0.03, 0.036, 0.012), Color(0.05, 0.04, 0.08), 10)
		sph(pb, hc + Vector3(sx * 0.058 + 0.01, 0.012, 0.143), Vector3(0.009, 0.009, 0.004), Color(0.8, 0.72, 0.95), 6)
		pb.box(Transform3D(Basis(Vector3.FORWARD, sx * 0.22), hc + Vector3(sx * 0.06, 0.05, 0.138)), Vector3.ZERO, Vector3(0.028, 0.006, 0.006), hair)
	sph(pb, hc + Vector3(0, -0.035, 0.15), Vector3(0.016, 0.02, 0.016), skin_d, 6)
	pb.box(id, hc + Vector3(0, -0.085, 0.132), Vector3(0.026, 0.004, 0.006), Color(0.35, 0.2, 0.24))
	# hair: a crown cap (top + back only, never over the face) and shaggy clumps; the fringe falls over the right eye
	pb.lathe(Transform3D(Basis(), hc + Vector3(0, 0.0, -0.012)), PackedVector2Array([Vector2(0.158, 0.06), Vector2(0.163, 0.1),
		Vector2(0.135, 0.145), Vector2(0.08, 0.172), Vector2(0.0, 0.185)]), 16, PackedColorArray([hair]), 0.0, 0.0, 7.0, 0.16, 8)
	sph(pb, hc + Vector3(0, 0.02, -0.035), Vector3(0.162, 0.165, 0.14), hair, 16)
	for k in 16:
		var a := TAU * float(k) / 16.0 + 0.2
		var dir := Vector3(sin(a), 0, cos(a))
		if dir.z > 0.55:
			continue   # the fringe is drawn below
		var root := hc + Vector3(0, 0.15, 0) + dir * 0.06
		var ln := 0.1 + 0.07 * MB3.h(k, 1, 77)
		var tip := hc + dir * 0.19 + Vector3(0, 0.02 - ln * 0.7, -0.02)
		var mid := (root + tip) * 0.5 + dir * 0.06 + Vector3(0, 0.03, 0)
		pb.tube(id, PackedVector3Array([root, mid, tip]), PackedFloat32Array([0.05, 0.04, 0.0]), 6, hair, 0.0, 0.6)
	# the fringe: five clumps over the forehead, the longest over the right eye (his left in frame when he faces us)
	var fr := [[-0.1, 0.07, 0.04], [-0.05, 0.1, 0.05], [0.0, 0.1, 0.06], [0.05, 0.16, 0.12], [0.1, 0.12, 0.09]]
	for k in fr.size():
		var x: float = fr[k][0]
		var drop: float = fr[k][1]
		var root := hc + Vector3(x * 0.6, 0.16, 0.05)
		var tip := hc + Vector3(x + 0.015, 0.1 - drop, 0.16 + fr[k][2] * 0.1)
		var mid := (root + tip) * 0.5 + Vector3(0, 0.02, 0.05)
		pb.tube(id, PackedVector3Array([root, mid, tip]), PackedFloat32Array([0.045, 0.036, 0.0]), 6, hair, 0.0, 0.55)
	add_paint(r, r, "Body", pb)
	var head := Node3D.new()
	head.name = "Head"   # cine / Lens read the face height from it
	head.position = hc
	r.add_child(head)
	head.owner = r
	# a faint rim of the memory's candle-light on him (additive shell, very low): keeps him readable in the dark set
	MB3.glow_ball(r, r, "Rim", Vector3(0, 0.75, 0), 0.62, MB3.mem(Color(0.95, 0.7, 0.5), 0.05, 1, 0.0, 2.0, 3.5))
	MB3.save_scene(EP3, r, "boy")


static func _ring(c: Vector3, rad: float, tilt: float, n: int) -> PackedVector3Array:
	var p := PackedVector3Array()
	for i in n + 1:
		var a := TAU * float(i) / n
		p.append(c + Vector3(sin(a) * rad, tilt * cos(a), cos(a) * rad))
	return p


static func _const(n: int, v: float) -> PackedFloat32Array:
	var a := PackedFloat32Array()
	for i in n:
		a.append(v)
	return a


# ================================================================ the heart-stone in Malrik's hand (Evenmead)

func _heart_stone_hand() -> void:
	var r := IB.fx_root("HeartStoneHand")
	var hd := Node3D.new()
	hd.name = "Head"   # cine / Lens framing point = the stone's heart
	hd.position = Vector3(0, 0.06, 0)
	r.add_child(hd)
	hd.owner = r
	var cb := IB.MB.new()
	var dirs := [Vector3(0, 1, 0), Vector3(0.7, 0.55, 0.2), Vector3(-0.6, 0.6, 0.3), Vector3(0.2, 0.5, -0.8), Vector3(-0.3, 0.45, -0.6), Vector3(0.5, 0.35, 0.7)]
	var s := 0.62
	for k in dirs.size():
		var d: Vector3 = dirs[k]
		_crystal(cb, (Vector3(0, 0.07, 0) + d.normalized() * 0.02) * s, d, (0.08 + 0.06 * MB3.h(k, 1, 91)) * s, (0.045 + 0.02 * MB3.h(k, 2, 91)) * s, 5,
			Color(0.9, 0.5, 0.16, MB3.h(k, 3, 91)))
		# and the same cluster mirrored below: in the air the stone is seen from every side (the Hollow's sits in rock)
		var dd := Vector3(d.x, -d.y, d.z)
		_crystal(cb, (Vector3(0, 0.05, 0) + dd.normalized() * 0.02) * s, dd, (0.06 + 0.04 * MB3.h(k, 4, 91)) * s, (0.04 + 0.02 * MB3.h(k, 5, 91)) * s, 5,
			Color(0.85, 0.45, 0.14, MB3.h(k, 6, 91)))
	_crystal(cb, Vector3(0, 0.0, 0), Vector3.UP, 0.13 * s, 0.085 * s, 6, Color(0.75, 0.38, 0.12, 0.5))
	IB.add_mesh(r, r, "Stone", cb, IB.smat(IB.SH_SOLID, {"vein": Color(1.0, 0.55, 0.12), "energy": 3.6, "tiling": Vector2(2, 3), "scroll": Vector2(0.0, 0.08),
		"vein_w": 0.58, "rough": 0.28, "spec": 0.8, "rim": 0.6, "tip_glow": 1.8}), false)
	MB3.glow_ball(r, r, "Core", Vector3(0, 0.06, 0), 0.05, MB3.mem(Color(1, 0.62, 0.2), 2.4, 2, 0.0, 2.0, 1.2))
	MB3.glow_ball(r, r, "Halo", Vector3(0, 0.06, 0), 0.24, MB3.mem(Color(1, 0.55, 0.18), 0.55, 2, 0.0, 2.0, 2.6))
	MB3.glow_ball(r, r, "Aura", Vector3(0, 0.06, 0), 0.6, MB3.mem(Color(1, 0.5, 0.2), 0.12, 2, 0.0, 2.0, 3.5))
	IB.particles(r, r, "Motes", {"amount": 8, "life": 2.6, "shape": "sphere", "ext": Vector3(0.08, 0, 0), "pos": Vector3(0, 0.06, 0),
		"dir": Vector3.UP, "spread": 35.0, "v": Vector2(0.04, 0.14), "size": Vector2(0.5, 1.0), "quad": 0.02, "seed": 93, "turb": 0.3,
		"cols": PackedColorArray([Color(4, 2, 0.6, 0), Color(4, 2, 0.5, 1), Color(1.5, 0.5, 0.1, 0)]),
		"aabb": AABB(Vector3(-1, -1, -1), Vector3(2, 3, 2))})
	MB3.save_scene(EP3, r, "heart_stone_hand")


## IB.MB.crystal buries 0.4 m of root below its base (fine in rock, a long spike in the air): a short root here.
static func _crystal(mb: IB.MB, base: Vector3, dir: Vector3, hh: float, r: float, sides: int, col: Color) -> void:
	var d := dir.normalized()
	mb.tube(PackedVector3Array([base - d * r * 0.8, base + d * hh * 0.72, base + d * hh]), PackedFloat32Array([r * 0.7, r * 0.92, 0.0]), sides, col)


# ================================================================ the heartbeat shock (vfx scene, posed by age)

func _heart_pulse() -> void:
	var r := IB.fx_root("HeartPulse")
	r.set_script(load(EP3 + "heart_pulse.gd"))
	MB3.glow_ball(r, r, "Flash", Vector3.ZERO, 0.16, MB3.mem(Color(1, 0.66, 0.26), 0.0, 0, 0.0, 2.0, 1.4))
	MB3.glow_ball(r, r, "Wave", Vector3.ZERO, 0.5, MB3.mem(Color(1, 0.55, 0.2), 0.0, 0, 0.0, 2.0, 0.0))
	# the wave is a thin shell: bright at its rim (inverse fresnel = the edge-on part), so it reads as a ring from any side
	var wm: ShaderMaterial = (r.get_node("Wave") as MeshInstance3D).material_override
	wm.shader = load(EP3 + "heart_wave.gdshader")
	MB3.save_scene(EP3, r, "heart_pulse")


# ================================================================ full-screen memory grade (W02)

func _memory_grade() -> void:
	var r := IB.fx_root("MemoryGrade")
	r.set_script(load(EP3 + "memory_grade.gd"))
	for k in 2:
		var q := QuadMesh.new()
		q.size = Vector2(1, 1)
		var mi := MeshInstance3D.new()
		mi.name = ["Desat", "Tint"][k]
		mi.mesh = q
		var m := ShaderMaterial.new()
		m.shader = load(EP3 + ["memory_grade_mix.gdshader", "memory_grade_mul.gdshader"][k])
		m.render_priority = 126 + k
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		mi.extra_cull_margin = 16384.0
		mi.ignore_occlusion_culling = true
		r.add_child(mi)
		mi.owner = r
	MB3.save_scene(EP3, r, "memory_grade")
