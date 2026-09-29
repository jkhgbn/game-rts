extends SceneTree
## Episode 4 memories, second pass (harsh review 2026-09-28): the props of forge_ep4_memories that the first pass
## (forge_ep3_memories/tools/memory_bake.gd only=ep4) did not get right, baked to NEW files (`*_v2`) so a re-run of the
## first bake never overwrites them. Uses memory_bake.gd / intro_bake.gd as libraries only (their PB / MB mesh builders,
## glow helpers); nothing of Episode 3 is touched.
##   people_winter_v2 / people_spring_v2 : the CHILD (props/child_ysolde.gd: child proportions, no staff) + her mother
##   sapling_frost_v2 : H05's rimed sapling: clear blue rime (ep4_ice), no white bars, the first green buds + a small
##                      green breath where the child's hands coax it
##   seedling_v2      : H04's seedling: a small tilled ring instead of a dark hole
##   burnt_v2         : H08 / H09 the burned wood under frost: black trunks with hoarfrost on their sun side, mottled
##                      frost over the ash, clear ice sheets and low ice clusters (no upright white shards), a fallen
##                      Nature banner and dropped bows (it was an army)
##   fallen_v2        : her army frozen where it fell: real kit models in their death pose, per-vertex hoarfrost (white
##                      on every up-facing surface, dark ash below), clear ice encasing some of them
##   shoot_v2         : H09's green shoot: bigger, two true leaves, a melted wet ring, a much smaller glow (no bloom)
## 0 lights. Deterministic (hashed jitter, fixed particle seeds).
## Run:  tools\godot_run.ps1 --headless --path . -s res://art/cinematics/stage_sets/forge_ep4_memories/tools/ep4_bake.gd
##           --fixed-fps 30 --quit-after 20000 '--' [only=people,sapling,seedling,burnt,fallen,shoot]

const MBK := preload("res://art/cinematics/stage_sets/forge_ep3_memories/tools/memory_bake.gd")
const IB := preload("res://art/cinematics/stage_sets/forge_intro_vessa/tools/intro_bake.gd")
const PB := MBK.PB
const OUT := "res://art/cinematics/stage_sets/forge_ep4_memories/props/"
const SH_ICE := OUT + "ep4_ice.gdshader"
const PAINT_PATH := "res://art/environment/env_painted_mat.tres"
const CHILD_WATCH := OUT + "child_ysolde_watch.tscn"
const CHILD_STAND := OUT + "child_ysolde_stand.tscn"
const U := "res://art/units/"
const BLOOMTENDER := U + "nature/bloomtender.tscn"
const WILDWOOD := U + "nature/wildwood_archer/wildwood_archer.tscn"
const VINELASHER := U + "nature/vinelasher/vinelasher.tscn"
const STAGRUNNER := U + "nature/stagrunner/stagrunner.tscn"
const THORNLING := U + "nature/thornling.tscn"
const BRAMBLEHORN := U + "nature/bramblehorn.tscn"

## H08 / H09 cameras in burnt_v2 space (origin = the shoot, world (45, 0)): kept clear of trunks and ice.
const CAM8 := Vector2(4.6, 5.4)
const YSOLDE8 := Vector2(-1.3, -1.7)

var only := PackedStringArray(["people", "sapling", "seedling", "burnt", "fallen", "shoot", "hem"])
var paint: Material


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("only="):
			only = a.substr(5).split(",")
	_run.call_deferred()


func _run() -> void:
	await process_frame
	paint = load(PAINT_PATH)
	if only.has("sapling"):
		_sapling_frost()
	if only.has("seedling"):
		_seedling()
	if only.has("shoot"):
		_shoot()
	if only.has("burnt"):
		_burnt()
	if only.has("hem"):
		_hem_warmth()
	if only.has("people"):
		# the child (and her mother) in the winter and spring corners (origin = the seed), baked still
		await _bake(OUT + "people_winter_v2", [IB.unit(CHILD_WATCH, Vector3(0.6, 0.14, 0.9), 210.0, "idle", 10, 0.55),
			IB.unit(BLOOMTENDER, Vector3(2.7, 0.14, 7.6), 14.0, "idle", 10, 1.0)], false)
		await _bake(OUT + "people_spring_v2", [IB.unit(CHILD_STAND, Vector3(0.6, 0.14, 0.9), 210.0, "idle", 10, 0.55),
			IB.unit(BLOOMTENDER, Vector3(-1.0, 0.14, 1.75), 150.0, "idle", 10, 1.0)], false)
	if only.has("fallen"):
		await _bake(OUT + "fallen_v2", _fallen(), true)
	print("ep4_bake: done")
	quit(0)


static func h(a: float, b: float, s: int) -> float:
	return IB.h01(a, b, s)


static func xf_at(p: Vector3, yaw_deg := 0.0, scl := 1.0, tilt := Vector3.ZERO) -> Transform3D:
	return MBK.xf_at(p, yaw_deg, scl, tilt)


func add_paint(parent: Node3D, owner: Node, nm: String, pb: RefCounted, shadows := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = pb.call(&"mesh")
	mi.material_override = paint
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	parent.add_child(mi)
	mi.owner = owner
	return mi


func ice_mat(opacity := 0.55, tint := Color(0.46, 0.66, 0.86), self_light := 0.12) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(SH_ICE)
	m.set_shader_parameter("opacity", opacity)
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("self_light", self_light)
	return m


func add_ice(parent: Node3D, owner: Node, nm: String, pb: RefCounted, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = pb.call(&"mesh")
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.owner = owner
	return mi


static func save(root_node: Node3D, file: String) -> void:
	var ps := PackedScene.new()
	ps.pack(root_node)
	var path := OUT + file + ".tscn"
	var err := ResourceSaver.save(ps, path)
	print("ep4_bake: %s (%s)" % [path, error_string(err)])
	root_node.free()


## A young tree (the first bake's young_tree, kept so H05 still reads as the same sapling), bare twigs; returns the
## twig tips so buds / rime can sit on them.
func young_tree(pb: RefCounted, xf: Transform3D, hgt: float, seed: int, bark: Color) -> PackedVector3Array:
	var pts := PackedVector3Array()
	for i in 7:
		var t := float(i) / 6.0
		pts.append(Vector3(sin(t * 4.0 + seed) * 0.04 * t, t * hgt, cos(t * 3.0 + seed) * 0.03 * t))
	pb.call(&"tube", xf, pts, PackedFloat32Array([0.035, 0.03, 0.026, 0.021, 0.016, 0.011, 0.005]), 7, bark, 0.3)
	var tips := PackedVector3Array([pts[6]])
	for k in 4:
		var t0 := 0.45 + 0.13 * k
		var base := pts[int(t0 * 6.0)]
		var a := k * 2.4 + seed
		var dir := Vector3(cos(a), 0.9, sin(a)).normalized()
		var l := hgt * (0.3 - k * 0.04)
		pb.call(&"tube", xf, PackedVector3Array([base, base + dir * l * 0.5, base + dir * l]), PackedFloat32Array([hgt * 0.012, hgt * 0.008, 0.002]), 5, bark, 0.6)
		tips.append(base + dir * l)
		# a side twig on each branch
		var sd := Vector3(cos(a + 1.2), 0.7, sin(a + 1.2)).normalized()
		var sb := base + dir * l * 0.55
		pb.call(&"tube", xf, PackedVector3Array([sb, sb + sd * l * 0.35]), PackedFloat32Array([hgt * 0.006, 0.0015]), 4, bark, 0.6)
		tips.append(sb + sd * l * 0.35)
	return tips


## A small leaf (flat tube) from at along dir.
static func leaf(pb: RefCounted, xf: Transform3D, at: Vector3, dir: Vector3, s: float, col: Color, tipc: Color) -> void:
	pb.call(&"tube", xf, PackedVector3Array([at, at + dir * s * 0.5 + Vector3(0, s * 0.08, 0), at + dir * s]), PackedFloat32Array([0.001, s * 0.3, 0.0]), 6,
		col, 1.0, 0.24, tipc)


# ================================================================ H05: the rimed sapling

func _sapling_frost() -> void:
	var r := IB.fx_root("SaplingFrostV2")
	var pb := PB.new()
	var hgt := 0.9
	var tips := young_tree(pb, Transform3D(), hgt, 160, Color(0.34, 0.3, 0.3))
	pb.mound(Transform3D(), 0.32, 0.07, Color(0.66, 0.72, 0.82), 162, 14, 0.4, Color(0.82, 0.86, 0.94))
	# a few frozen leaves still hanging (brown-grey, rime-edged) and the first green buds on the lowest tips (her doing)
	for k in tips.size():
		var tp: Vector3 = tips[k]
		if k >= 6:
			var a := k * 1.9
			leaf(pb, Transform3D(), tp, Vector3(cos(a), 0.35, sin(a)).normalized(), 0.07, Color(0.28, 0.62, 0.24), Color(0.52, 0.86, 0.34))
			leaf(pb, Transform3D(), tp, Vector3(cos(a + 2.2), 0.45, sin(a + 2.2)).normalized(), 0.06, Color(0.28, 0.62, 0.24), Color(0.52, 0.86, 0.34))
		elif k % 2 == 1:
			leaf(pb, Transform3D(), tp, Vector3(cos(k * 2.3), -0.6, sin(k * 2.3)).normalized(), 0.08, Color(0.36, 0.3, 0.26), Color(0.8, 0.86, 0.94))
	add_paint(r, r, "Tree", pb)
	# rime: small clear-blue crystals along the upper twigs (not bars: short, fat, few)
	var ice := PB.new()
	for k in 22:
		var tp: Vector3 = tips[k % 6]
		var along := h(k, 1, 163) * 0.8
		var p := tp.lerp(Vector3(0, tp.y * 0.6, 0), along)
		var a := h(k, 2, 163) * TAU
		ice.rock(xf_at(p, a * 57.0, 1.0, Vector3((h(k, 3, 163) - 0.5) * 70.0, 0, (h(k, 4, 163) - 0.5) * 70.0)), 0.012 + 0.01 * h(k, 5, 163),
			0.03 + 0.03 * h(k, 6, 163), 4, Color(1, 1, 1), 170 + k, 0.0)
	add_ice(r, r, "Rime", ice, ice_mat(0.6, Color(0.55, 0.74, 0.92), 0.18))
	# her green breath around the budding twigs (small: a hint, not a bloom)
	MBK.glow_ball(r, r, "Coax", Vector3(0.05, 0.45, 0.05), 0.24, MBK.mem(Color(0.55, 1.0, 0.45), 0.26, 3, 0.0, 2.0, 2.4))
	var motes := IB.particles(r, r, "Motes", {"amount": 9, "life": 3.5, "shape": "sphere", "ext": Vector3(0.18, 0, 0), "pos": Vector3(0, 0.4, 0.05),
		"dir": Vector3.UP, "spread": 40.0, "v": Vector2(0.03, 0.08), "size": Vector2(0.6, 1.0), "quad": 0.014, "seed": 164, "turb": 0.3,
		"cols": PackedColorArray([Color(1.4, 2.4, 0.9, 0), Color(1.3, 2.2, 0.8, 0.9), Color(0.5, 1.0, 0.3, 0)]),
		"aabb": AABB(Vector3(-0.8, -0.2, -0.8), Vector3(1.6, 1.8, 1.6))})
	motes.name = "Motes"
	save(r, "sapling_frost_v2")


## H05: the warmth of the Master's burning hem on the frost (his own prop is Episode 3's; this adds the light it would
## throw on the snow in the cold pre-dawn grade: a warm pool, a soft glow at knee height, a few rising embers). 0 lights.
func _hem_warmth() -> void:
	var r := IB.fx_root("HemWarmthV2")
	MBK.pool(r, r, "Pool", Vector3(0, 0.02, 0), 2.6, MBK.mem(Color(1.0, 0.62, 0.34), 0.42, 1, 1.0, 1.8))
	MBK.glow_ball(r, r, "Spill", Vector3(0, 0.35, 0), 1.1, MBK.mem(Color(1.0, 0.6, 0.3), 0.12, 1, 0.0, 2.0, 2.5))
	IB.particles(r, r, "Embers", {"amount": 18, "life": 2.6, "shape": "ring", "ext": Vector3(0.82, 0.6, 0.05), "pos": Vector3(0, 0.15, 0),
		"dir": Vector3.UP, "spread": 18.0, "v": Vector2(0.25, 0.6), "size": Vector2(0.5, 1.0), "quad": 0.035, "seed": 211, "turb": 0.5,
		"cols": PackedColorArray([Color(3.0, 1.6, 0.6, 0), Color(3.0, 1.5, 0.5, 1), Color(1.0, 0.4, 0.1, 0)]),
		"aabb": AABB(Vector3(-2, -1, -2), Vector3(4, 5, 4))})
	save(r, "hem_warmth_v2")


# ================================================================ H04: the seedling in spring

func _seedling() -> void:
	var r := IB.fx_root("SeedlingV2")
	var pb := PB.new()
	# a small ring of freshly turned earth, grass right up to it (not a hole)
	pb.lathe(Transform3D(), PackedVector2Array([Vector2(0.17, 0.0), Vector2(0.13, 0.018), Vector2(0.06, 0.024), Vector2(0.0, 0.02)]), 18,
		PackedColorArray([Color(0.36, 0.26, 0.17), Color(0.32, 0.23, 0.15), Color(0.28, 0.2, 0.13)]), 0.0, 0.0, 5.0, 0.4, 190)
	for k in 9:   # grass blades around the ring
		var a := k * TAU / 9.0 + 0.3
		var b := Vector3(cos(a) * 0.2, 0.0, sin(a) * 0.2)
		for j in 3:
			var d := Vector3(cos(a + j * 0.5) * 0.03, 0.09 + 0.05 * h(k, j, 191), sin(a + j * 0.5) * 0.03)
			pb.tube(Transform3D(), PackedVector3Array([b, b + d]), PackedFloat32Array([0.006, 0.0]), 3, Color(0.34, 0.56, 0.22), 1.0, 1.0, Color(0.5, 0.72, 0.3))
	var stem := PackedVector3Array([Vector3(0, 0.0, 0), Vector3(0.004, 0.04, 0), Vector3(0.01, 0.08, 0.004), Vector3(0.006, 0.12, 0.006), Vector3(-0.004, 0.15, 0.004)])
	pb.tube(Transform3D(), stem, PackedFloat32Array([0.007, 0.0065, 0.006, 0.0055, 0.004]), 8, Color(0.4, 0.62, 0.28), 0.0, 1.0, Color(0.55, 0.85, 0.35))
	var top := stem[4]
	for sx in [-1.0, 1.0]:
		leaf(pb, Transform3D(), top, Vector3(sx, 0.35, 0.15).normalized(), 0.07, Color(0.34, 0.66, 0.26), Color(0.55, 0.86, 0.34))
	leaf(pb, Transform3D(), top, Vector3(0.2, 1.0, 0.5).normalized(), 0.045, Color(0.4, 0.72, 0.28), Color(0.6, 0.9, 0.38))
	add_paint(r, r, "Seedling", pb, false)
	MBK.glow_ball(r, r, "Breath", top, 0.05, MBK.mem(Color(0.6, 1.0, 0.4), 0.22, 3, 0.0, 2.0, 2.2))
	save(r, "seedling_v2")


# ================================================================ H09: the green shoot in the black

func _shoot() -> void:
	var r := IB.fx_root("ShootV2")
	var pb := PB.new()
	# the melted ring: dark wet ash (a touch of blue sheen), frost crumbs beyond it
	pb.lathe(Transform3D(), PackedVector2Array([Vector2(0.3, 0.0), Vector2(0.22, 0.01), Vector2(0.1, 0.014), Vector2(0.0, 0.012)]), 22,
		PackedColorArray([Color(0.09, 0.09, 0.1), Color(0.05, 0.05, 0.06), Color(0.04, 0.04, 0.045)]), 0.0, 0.0, 5.0, 0.4, 190)
	for k in 16:
		var a := k * 0.4 + h(k, 1, 192) * 0.3
		var d := 0.3 + h(k, 2, 192) * 0.18
		pb.rock(xf_at(Vector3(cos(a) * d, 0.0, sin(a) * d), k * 30), 0.015 + 0.02 * h(k, 3, 192), 0.02 + 0.02 * h(k, 4, 192), 5,
			Color(0.74, 0.8, 0.9), 193 + k)
	var stem := PackedVector3Array([Vector3(0, 0.0, 0), Vector3(0.006, 0.05, 0), Vector3(0.014, 0.1, 0.005), Vector3(0.008, 0.15, 0.008),
		Vector3(-0.004, 0.19, 0.006), Vector3(-0.012, 0.215, 0.0)])
	pb.tube(Transform3D(), stem, PackedFloat32Array([0.009, 0.0085, 0.0078, 0.007, 0.006, 0.004]), 8, Color(0.5, 0.72, 0.32), 0.0, 1.0, Color(0.66, 0.92, 0.4))
	var top := stem[5]
	for sx in [-1.0, 1.0]:   # the two seed leaves
		leaf(pb, Transform3D(), top, Vector3(sx, 0.3, 0.18).normalized(), 0.085, Color(0.42, 0.76, 0.3), Color(0.7, 0.95, 0.42))
	# the first two true leaves, one a little lower on the stem
	leaf(pb, Transform3D(), top, Vector3(0.25, 1.0, 0.45).normalized(), 0.06, Color(0.48, 0.82, 0.32), Color(0.76, 0.98, 0.46))
	leaf(pb, Transform3D(), stem[3], Vector3(0.9, 0.5, -0.3).normalized(), 0.05, Color(0.44, 0.78, 0.3), Color(0.7, 0.95, 0.42))
	var sm := add_paint(r, r, "Shoot", pb, true)
	# its own material: the low sun behind shines THROUGH the leaves (backlight), a rim on the stem
	var lm := StandardMaterial3D.new()
	lm.vertex_color_use_as_albedo = true
	lm.vertex_color_is_srgb = true
	lm.roughness = 0.55
	lm.backlight_enabled = true
	lm.backlight = Color(0.55, 0.85, 0.3)
	lm.rim_enabled = true
	lm.rim = 0.7
	lm.rim_tint = 0.6
	lm.cull_mode = BaseMaterial3D.CULL_DISABLED
	sm.material_override = lm
	# a SMALL glow (the first pass bloomed): a faint core and a low pool; the backlight does the rest
	MBK.pool(r, r, "Pool", Vector3(0, 0.016, 0), 0.34, MBK.mem(Color(0.5, 1.0, 0.4), 0.1, 3, 1.0, 2.4))
	# a thin green rim on the leaves: the low sun through them (additive shell, fresnel only, no halo)
	MBK.glow_ball(r, r, "Rim", top + Vector3(0, -0.01, 0), 0.075, MBK.mem(Color(0.7, 1.0, 0.5), 0.1, 3, 0.0, 3.0, 4.0))
	IB.particles(r, r, "Motes", {"amount": 4, "life": 4.0, "shape": "sphere", "ext": Vector3(0.05, 0, 0), "pos": top,
		"dir": Vector3.UP, "spread": 25.0, "v": Vector2(0.02, 0.05), "size": Vector2(0.6, 1.0), "quad": 0.01, "seed": 195, "turb": 0.2,
		"cols": PackedColorArray([Color(1.0, 1.8, 0.6, 0), Color(0.9, 1.6, 0.5, 0.8), Color(0.4, 0.8, 0.2, 0)]),
		"aabb": AABB(Vector3(-0.5, -0.2, -0.5), Vector3(1, 1, 1))})
	save(r, "shoot_v2")


# ================================================================ H08 / H09: the burned wood under frost

## Distance from p (xz) to the segment a-b.
static func seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return p.distance_to(a + ab * t)


## Keep the H08 sight line (camera -> Ysolde) and the H09 ground camera (south of the shoot) clear.
static func in_lanes(p: Vector2, pad: float) -> bool:
	if seg_dist(p, CAM8, YSOLDE8) < 1.2 + pad:
		return true
	if p.y > -0.6 and p.y < 3.0 and absf(p.x) < 0.9 + pad:
		return true
	return false


## Hoarfrost on a painted PB: every vertex whose normal faces `side` (and up) turns frost-white, with hashed breaks.
static func frost_paint(pb: RefCounted, side: Vector3, frost: Color, amount: float, seed: int) -> void:
	var nn: PackedVector3Array = pb.get(&"n")
	var cc: PackedColorArray = pb.get(&"c")
	var vv: PackedVector3Array = pb.get(&"v")
	for i in nn.size():
		var k := nn[i].dot(side) * 0.8 + nn[i].y * 0.6
		var noise := h(floorf(vv[i].x * 7.0), floorf(vv[i].y * 5.0 + vv[i].z * 7.0), seed)
		var w := smoothstep(0.25, 0.75, k + (noise - 0.5) * 0.5) * amount
		var c0: Color = cc[i]
		cc[i] = Color(c0.r, c0.g, c0.b).lerp(frost, w)
		cc[i].a = c0.a
	pb.set(&"c", cc)


func _burnt() -> void:
	var r := IB.fx_root("BurntV2")
	var ground := PB.new()
	var ash := Color(0.055, 0.055, 0.06)
	ground.mound(Transform3D(), 15.0, 0.1, ash.darkened(0.15), 180, 44, 0.2, ash)
	# hoarfrost mottling the ash: many thin irregular patches, pale blue-white, denser in the open
	for k in 90:
		var a := h(k, 1, 181) * TAU
		var d := 0.6 + sqrt(h(k, 2, 181)) * 12.0
		var p := Vector3(cos(a) * d, 0.085, sin(a) * d)
		var rr := 0.25 + h(k, 4, 181) * 0.9
		var fc := Color(0.5, 0.55, 0.64).lerp(Color(0.78, 0.83, 0.9), h(k, 5, 181))
		ground.mound(xf_at(p, h(k, 3, 181) * 180, 1.0) * Transform3D(Basis().scaled(Vector3(1.0, 1.0, 0.55 + h(k, 6, 181) * 0.6)), Vector3.ZERO),
			rr, 0.025, fc.darkened(0.2), 182 + k, 12, 0.45, fc)
	add_paint(r, r, "Ground", ground, false)
	# the charred trunks: black, cracked, snapped tops; hoarfrost on their south / sun side and on the snapped tops
	var wood := PB.new()
	var n_trunks := 0
	for k in 60:
		var a := h(k, 1, 183) * TAU
		var d := 2.2 + h(k, 2, 183) * 11.0
		if k >= 24:   # the far ring: a wall of dead trunks behind (north, west), no sky gaps at eye level
			a = PI * 0.95 + (float(k - 24) / 35.0) * PI * 1.2 + (h(k, 7, 183) - 0.5) * 0.12
			d = 8.0 + h(k, 2, 183) * 6.0
		var p := Vector3(cos(a) * d, 0.05, sin(a) * d)
		if in_lanes(Vector2(p.x, p.z), 0.4):
			continue
		n_trunks += 1
		var hh := 2.5 + h(k, 3, 183) * 6.0 + (3.5 if k >= 24 else 0.0)
		var tx := xf_at(p, k * 33, 1.0, Vector3((h(k, 4, 183) - 0.5) * 12.0, 0, (h(k, 5, 183) - 0.5) * 12.0))
		var pts := PackedVector3Array()
		for i in 7:
			var t := float(i) / 6.0
			pts.append(Vector3(sin(t * 2.0 + k) * 0.14 * t, t * hh, cos(t * 3.0 + k) * 0.11 * t))
		var rr := 0.18 + h(k, 6, 183) * 0.24
		wood.tube(tx, pts, PackedFloat32Array([rr * 1.5, rr * 1.05, rr * 0.92, rr * 0.82, rr * 0.7, rr * 0.55, rr * 0.3]), 10, Color(0.06, 0.055, 0.055), 0.0, 1.0, Color(0.04, 0.04, 0.04))
		# root flare
		for b in 4:
			var ra := b * TAU / 4.0 + k
			wood.tube(tx, PackedVector3Array([Vector3(0, 0.35, 0), Vector3(cos(ra) * rr * 1.6, 0.08, sin(ra) * rr * 1.6), Vector3(cos(ra) * rr * 2.6, -0.02, sin(ra) * rr * 2.6)]),
				PackedFloat32Array([rr * 0.5, rr * 0.35, rr * 0.1]), 5, Color(0.055, 0.05, 0.05))
		wood.lathe(tx, PackedVector2Array([Vector2(rr * 0.4, hh * 0.985), Vector2(rr * 0.3, hh + 0.1), Vector2(0.0, hh + 0.16)]), 7,
			PackedColorArray([Color(0.8, 0.85, 0.92)]), 0.0, 0.0, 3.0, 0.8, k)   # frost cap on the snapped top
		for b in 2 + k % 3:
			var bi := 2 + b
			var bd := Vector3(cos(b * 2.1 + k), 0.45, sin(b * 2.1 + k)).normalized()
			wood.tube(tx, PackedVector3Array([pts[mini(bi, 6)], pts[mini(bi, 6)] + bd * (0.7 + 0.5 * h(k, b, 189))]), PackedFloat32Array([rr * 0.32, 0.02]), 5, Color(0.05, 0.045, 0.045))
	for k in 6:   # fallen trunks, lying across the ash
		var a := h(k, 1, 184) * TAU
		var d := 3.0 + h(k, 2, 184) * 7.0
		var p := Vector3(cos(a) * d, 0.22, sin(a) * d)
		var dir := Vector3(cos(a + 1.3), 0.03, sin(a + 1.3))
		var l := 3.0 + h(k, 3, 184) * 3.5
		if in_lanes(Vector2(p.x, p.z), 0.8) or in_lanes(Vector2(p.x + dir.x * l, p.z + dir.z * l), 0.8) or in_lanes(Vector2(p.x + dir.x * l * 0.5, p.z + dir.z * l * 0.5), 0.8):
			continue
		wood.tube(Transform3D(), PackedVector3Array([p, p + dir * l * 0.5, p + dir * l]), PackedFloat32Array([0.26, 0.22, 0.1]), 9, Color(0.06, 0.055, 0.055))
	frost_paint(wood, Vector3(-0.55, 0.0, -0.83), Color(0.8, 0.85, 0.93), 0.9, 186)
	add_paint(r, r, "Wood", wood)
	# the banner of her army, fallen: a pole leaning on a trunk stump, the green cloth frozen stiff and rimed; bows dropped
	var gear := PB.new()
	var bp := Vector3(-2.2, 0.0, 1.2)
	var top := bp + Vector3(0.9, 2.6, -0.35)
	gear.tube(Transform3D(), PackedVector3Array([bp, bp.lerp(top, 0.5), top]), PackedFloat32Array([0.045, 0.04, 0.035]), 7, Color(0.2, 0.15, 0.11))
	gear.lathe(xf_at(top, 0), PackedVector2Array([Vector2(0.06, 0.0), Vector2(0.03, 0.12), Vector2(0.0, 0.2)]), 6, PackedColorArray([Color(0.5, 0.42, 0.2)]))
	var along := (top - bp).normalized()
	var side := along.cross(Vector3(0.2, 0, 1)).normalized()
	# the standard: a crossbar near the top, a cloth panel hanging from it, stiff with frost, torn into tongues
	var bar_c := bp.lerp(top, 0.9)
	var bar_d := Vector3(0.95, 0.0, 0.3).normalized()
	gear.tube(Transform3D(), PackedVector3Array([bar_c - bar_d * 0.45, bar_c + bar_d * 0.45]), PackedFloat32Array([0.025, 0.025]), 6, Color(0.2, 0.15, 0.11))
	var cloth := Color(0.2, 0.44, 0.18)
	var cb := Basis(bar_d, Vector3.UP, bar_d.cross(Vector3.UP)).orthonormalized()
	gear.box(Transform3D(cb, bar_c + Vector3(0, -0.42, 0)), Vector3.ZERO, Vector3(0.42, 0.4, 0.015), cloth)
	for j in 4:   # the torn tongues under the panel
		var off := -0.315 + j * 0.21
		var ln := 0.22 + 0.14 * h(j, 1, 197)
		gear.box(Transform3D(cb, bar_c + bar_d * off + Vector3(0, -0.82 - ln * 0.5, 0)), Vector3.ZERO, Vector3(0.09, ln * 0.5, 0.012), cloth.darkened(0.08 * j))
	# the sigil: a gold leaf on the cloth (both faces)
	for sd in [-1.0, 1.0]:
		var n: Vector3 = bar_d.cross(Vector3.UP) * float(sd)
		gear.box(Transform3D(cb, bar_c + Vector3(0, -0.42, 0) + n * 0.018), Vector3.ZERO, Vector3(0.1, 0.2, 0.004), Color(0.8, 0.66, 0.3))
		gear.box(Transform3D(cb * Basis(Vector3.FORWARD, 0.8), bar_c + Vector3(0, -0.45, 0) + n * 0.02), Vector3.ZERO, Vector3(0.1, 0.03, 0.004), Color(0.8, 0.66, 0.3))
	for k in 5:   # dropped bows (curved staves) and a few arrows in the ash
		var a := h(k, 1, 198) * TAU
		var d := 1.6 + h(k, 2, 198) * 4.5
		var p := Vector3(cos(a) * d, 0.1, sin(a) * d)
		if in_lanes(Vector2(p.x, p.z), 0.0):
			continue
		var yaw := h(k, 3, 198) * 180.0
		var bx := xf_at(p, yaw)
		gear.tube(bx, PackedVector3Array([Vector3(-0.55, 0, 0), Vector3(-0.3, 0, 0.12), Vector3(0, 0, 0.16), Vector3(0.3, 0, 0.12), Vector3(0.55, 0, 0)]),
			PackedFloat32Array([0.012, 0.02, 0.024, 0.02, 0.012]), 5, Color(0.26, 0.2, 0.14))
		for j in 3:
			var ap := p + Vector3((h(k, j, 199) - 0.5) * 1.2, 0.0, (h(j, k, 199) - 0.5) * 1.2)
			if in_lanes(Vector2(ap.x, ap.z), 0.0):
				continue
			var ad := Vector3((h(k, j, 200) - 0.5) * 0.6, 1.0, (h(j, k, 200) - 0.5) * 0.6).normalized()
			gear.tube(Transform3D(), PackedVector3Array([ap - ad * 0.05, ap + ad * 0.5]), PackedFloat32Array([0.008, 0.008]), 4, Color(0.3, 0.24, 0.16))
			gear.lathe(xf_at(ap + ad * 0.5, 0), PackedVector2Array([Vector2(0.025, 0.0), Vector2(0.0, 0.07)]), 4, PackedColorArray([Color(0.3, 0.6, 0.26)]))
	frost_paint(gear, Vector3(-0.55, 0.0, -0.83), Color(0.82, 0.87, 0.94), 0.45, 201)
	add_paint(r, r, "Gear", gear)
	# clear ice: frozen puddles (flat sheets) and low crystal clusters at trunk feet (no upright white teeth)
	var sheets := PB.new()
	for k in 16:
		var a := h(k, 1, 185) * TAU
		var d := 1.0 + sqrt(h(k, 2, 185)) * 10.0
		var p := Vector3(cos(a) * d, 0.09, sin(a) * d)
		if in_lanes(Vector2(p.x, p.z), 0.6) or Vector2(p.x, p.z).distance_to(CAM8) < 3.5:
			continue
		sheets.mound(xf_at(p, h(k, 3, 185) * 180, 1.0) * Transform3D(Basis().scaled(Vector3(1.0, 1.0, 0.5 + h(k, 4, 185) * 0.5)), Vector3.ZERO),
			0.4 + h(k, 5, 185) * 0.8, 0.018, Color(1, 1, 1), 300 + k, 14, 0.45)
	var clusters := PB.new()
	for k in 18:
		var a := h(k, 1, 186) * TAU
		var d := 1.5 + h(k, 2, 186) * 9.0
		var c := Vector3(cos(a) * d, 0.05, sin(a) * d)
		if in_lanes(Vector2(c.x, c.z), 0.1):
			continue
		for j in 5:   # a low cluster: five crystals leaning out from one root, knee height at most
			var ja := j * TAU / 5.0 + k
			var lean := Vector3(cos(ja) * 40.0, 0, sin(ja) * 40.0)
			clusters.rock(xf_at(c + Vector3(cos(ja), 0, sin(ja)) * 0.05, ja * 57.0, 1.0, Vector3(lean.x, 0, lean.z)), 0.04 + 0.04 * h(k, j, 187),
				0.12 + 0.28 * h(j, k, 187), 5, Color(1, 1, 1), 320 + k * 5 + j, 0.0)
	add_ice(r, r, "IceSheets", sheets, ice_mat(0.5, Color(0.42, 0.6, 0.8), 0.1))
	add_ice(r, r, "IceClusters", clusters, ice_mat(0.62, Color(0.5, 0.7, 0.9), 0.16))
	# cold mist low between the trunks, ash and snow falling together
	var cold := IB.MB.new()
	for k in 3:
		cold.disc(Vector3((h(k, 1, 187) - 0.5) * 8.0 - 3.0, 0.25 + k * 0.1, (h(k, 2, 187) - 0.5) * 6.0 - 5.0), 0.0, 4.5 + h(k, 3, 187) * 2.0, 24, Color(1, 1, 1, h(k, 4, 187)), 4)
	IB.add_mesh(r, r, "ColdMist", cold, IB.smat(IB.SH_VEIL, {"dark": Color(0.36, 0.42, 0.52), "glow": Color(0.66, 0.74, 0.88), "energy": 0.8, "scroll": Vector2(0.03, -0.02),
		"tiling": Vector2(5, 2), "twist": 0.4, "streak": 0.85, "opacity": 0.18, "fade_lo": 0.001, "fade_hi": 0.95}))
	IB.particles(r, r, "AshFall", {"amount": 110, "life": 10.0, "shape": "box", "ext": Vector3(9, 0.5, 9), "pos": Vector3(0, 7.0, 0),
		"dir": Vector3.DOWN, "spread": 20.0, "v": Vector2(0.2, 0.45), "grav": Vector3(0.05, -0.08, 0.02), "size": Vector2(0.5, 1.1), "quad": 0.05,
		"seed": 188, "turb": 0.6, "additive": false,
		"cols": PackedColorArray([Color(0.7, 0.72, 0.78, 0), Color(0.75, 0.78, 0.84, 0.8), Color(0.8, 0.82, 0.88, 0.7), Color(0.8, 0.82, 0.88, 0)]),
		"aabb": AABB(Vector3(-11, -2, -11), Vector3(22, 12, 22))})
	print("ep4_bake: burnt_v2 trunks %d" % n_trunks)
	save(r, "burnt_v2")


# ================================================================ the fallen, frozen

func _fallen() -> Array:
	# the kit's death "fall" lies down by 0.55 s, then SINKS the body into the ground (gone by 1 s: why the first
	# bake's army did not read): bake at 16 frames (0.53 s at 30 fps), lying flat, lifted 0.3 m to sit on the ash.
	# her army where it fell (burnt_v2 space): flanking the H08 sight line (camera south-east -> Ysolde north-west),
	# a few in the near ground so the camera looks across them, the rest around her
	return [IB.unit(WILDWOOD, Vector3(1.13, 0.3, 3.72), 200, "death", 16), IB.unit(THORNLING, Vector3(2.8, 0.3, 1.03), 250, "death", 16),
		IB.unit(VINELASHER, Vector3(-1.56, 0.3, 2.06), 80, "death", 16), IB.unit(WILDWOOD, Vector3(1.97, 0.3, -1.53), 160, "death", 16),
		IB.unit(STAGRUNNER, Vector3(-4.1, 0.3, -0.38), 250, "death", 16), IB.unit(WILDWOOD, Vector3(-0.75, 0.3, -4.48), 190, "death", 16),
		IB.unit(THORNLING, Vector3(-2.9, 0.3, -3.6), 30, "death", 16), IB.unit(BRAMBLEHORN, Vector3(-5.6, 0.3, -3.9), 300, "death", 16),
		IB.unit(WILDWOOD, Vector3(-3.3, 0.3, 0.9), 120, "death", 16),
		IB.unit(WILDWOOD, Vector3(-0.6, 0.3, -1.7), 100, "death", 16),
		IB.unit(THORNLING, Vector3(-1.29, 0.3, -0.12), 200, "death", 16), IB.unit(WILDWOOD, Vector3(0.23, 0.3, -2.68), 300, "death", 16)]


## Real kit models posed a few frames (idle / death), merged into one mesh. frozen = per-vertex hoarfrost (frost-white
## on up-facing surfaces, dark ash-blue below) + clear ice mounds over every other one.
func _bake(path: String, units: Array, frozen: bool) -> void:
	var holder := Node3D.new()
	holder.name = "Bake"
	root.add_child(holder)
	var list: Array = []
	for u: Dictionary in units:
		var ps := load(u["scene"]) as PackedScene
		if ps == null:
			push_warning("ep4_bake: missing " + String(u["scene"]))
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
			if frames - int(u["f"]) == fr and u["act"] == "death":
				var m: Node = pr[0]
				if not m.has_method("play_death"):
					m = m.get(&"model") if m.get(&"model") != null else m
				if m.has_method("play_death"):
					m.call("play_death")
		await process_frame
	var paint_b := IB._Bucket.new()
	var glow_b := IB._Bucket.new()
	for pr: Array in list:
		_collect(pr[0], holder, paint_b, glow_b, frozen)
	if frozen:
		_rime(paint_b)
	var mesh := ArrayMesh.new()
	var pm := StandardMaterial3D.new()
	pm.vertex_color_use_as_albedo = true
	pm.vertex_color_is_srgb = true
	pm.roughness = 0.7 if frozen else 0.85
	pm.rim_enabled = true
	pm.rim = 0.45 if frozen else 0.3
	pm.rim_tint = 0.2
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
	print("ep4_bake: %s.tscn  units %d  surfaces %d  tris %d" % [path, list.size(), mesh.get_surface_count(), tris])
	sroot.free()
	holder.queue_free()
	await process_frame


## Hoarfrost: vertex colours of the merged frozen bodies = dark ash-blue (from the unit's own colour, darkened) turning
## frost-white on up-facing surfaces, broken by hashed patches; so the kit silhouettes read on the black ash.
static func _rime(b: RefCounted) -> void:
	var nn: PackedVector3Array = b.get(&"n")
	var cc: PackedColorArray = b.get(&"c")
	var vv: PackedVector3Array = b.get(&"v")
	for i in nn.size():
		var c0: Color = cc[i]
		var g := c0.get_luminance()
		var dark := Color(g, g, g).lerp(Color(0.22, 0.26, 0.34), 0.6).darkened(0.5)
		var noise := h(floorf(vv[i].x * 9.0), floorf(vv[i].z * 9.0 + vv[i].y * 5.0), 402)
		var w := smoothstep(0.1, 0.7, nn[i].y + (noise - 0.5) * 0.5)
		cc[i] = dark.lerp(Color(0.66, 0.72, 0.82), w * 0.85)
	b.set(&"c", cc)


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
					paint_b.add(mi.mesh, s, xf, Color(col.r, col.g, col.b, 1.0))
				elif cl[0] == "glow" and not frozen:
					var gc: Color = cl[1]
					glow_b.add(mi.mesh, s, xf, Color(gc.r, gc.g, gc.b, 0.5))
	for c in n.get_children():
		_collect(c, holder, paint_b, glow_b, frozen)


## The face kit's material (art/units/kit/face/unit_face.gdshader, face rework 2026-09-28): colour per vertex.
static func _is_face(mat: Material) -> bool:
	return mat is ShaderMaterial and (mat as ShaderMaterial).shader != null 		and (mat as ShaderMaterial).shader.resource_path.get_file() == "unit_face.gdshader"
