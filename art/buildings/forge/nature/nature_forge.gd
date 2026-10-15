class_name GroveForgeModel
extends NatureHallModel
## Visual model of Ysolde's Forge, the Grove Forge (task G-B leftovers, docs/art/gb_leftovers.md; unit-upgrades.md:
## kind &"forge", 3 x 3 cells = 6 x 6 m, data height 4). It replaces the ForgeBuilding placeholder through
## BuildingType.model_path (data/buildings/nature_forge.tres), in the Grove Hall's language on the G-B Nature paint
## layer (NatureKit materials, nature_paint.gdshaderinc: soft wrapped light, translucent leaves, moss velvet, wind,
## close-up relief at High+; NatureVC merge), with the Hall's ground (moss patch, fairy ring, dressing).
## Read from the RTS camera:
## - Dominant vertical (back right, ~7.6 m): a hollow chimney-tree, a thick bark trunk whose roots grip the plinth, its
##   open top glowing with sap-fire (sap embers rise from it), one living branch on its side with a leaf clump and a
##   blossom.
## - The kiln (centre left): a mossy fieldstone dome with a glowing mouth (it flares when a research completes:
##   play_training_pulse), a moss cap, a bark flue into the tree.
## - The workshop (front left, asymmetric): a lean-to of bark posts under a living hedge roof (team leaves, leaf
##   fringe), sheltering a stone anvil on a stump; a hollow-log quench trough and a stack of cut stone on the right; a
##   leaning rune stone; a leaf banner on a gnarled standard by the gate.
## Hooks (FireHallModel contract via NatureHallModel): set_team_color, set_construction_progress, set_health_ratio,
## play_training_pulse, play_destroyed (-> destroyed_finished after 3 s), set_selected. No active light.

const FKEY := "nature_forge/"
const TREE_AT := Vector3(1.95, 0.8, 1.75)   ## the chimney-tree's foot (Body space)
const TREE_TOP := 6.6                        ## tree-local height of the hollow top
const KILN_AT := Vector3(-0.6, 0.8, 1.0)     ## the kiln dome's centre on the plinth
const LEAN := Vector3(-1.7, 0.8, -1.55)      ## the lean-to's centre
const STANDARD_AT := Vector3(0.9, 0.45, -3.0)


## Grove Forge parts (Body space, gate -Z). Heights: plinth 0.8, kiln dome 2.9, lean-to hedge ~3.6, tree top ~7.4.
## Tiers: PlinthBase, Kiln (dome, flue, mouth), Workshop (posts, anvil, trough, stones), LeanHedge, ChimneyTree
## (trunk, branch clump; falls on the collapse), BranchLost (the branch clump, lost under 50 %), Banners.
func _build_structure() -> void:
	_top_y = 8.0
	_fpart("PlinthBase", "plinth", _mesh_f_plinth, _body, 0.0, 2.5)
	_fpart("Kiln", "kiln", _mesh_f_kiln, _body, 0.8, 2.4)
	_fpart("Workshop", "workshop", _mesh_f_workshop, _body, 0.8, 3.0)
	var hedge := _fpart("LeanHedge", "lean_hedge", _mesh_f_hedge, _body, 2.6, 1.6)
	_tree = Node3D.new()
	_tree.name = "ChimneyTree"
	_tree.position = TREE_AT
	_body.add_child(_tree)
	_fpart("Trunk", "trunk", _mesh_f_trunk, _tree, 0.0, 7.0)
	var branch := _fpart("Branch", "branch", _mesh_f_branch, _tree, 4.0, 3.5)
	_hide_below_50.append(branch)
	_falling = _tree
	_fall_axis = Vector3(1, 0, 0.3).normalized()
	_fall_deg = 36.0
	var bn := _fpart("Banners", "banners", _mesh_f_banners, _body, 0.0, 1.0, false)
	_hide_below_25.append(bn)
	_hide_on_collapse.append_array([hedge, bn])
	_light = _omni(Vector3(KILN_AT.x, 1.6, -0.6), 5.0)
	_light.visible = false
	_build_f_ambient()
	_build_f_scaffold()
	_build_f_wreck()
	_smoke_points = [TREE_AT + Vector3(0, TREE_TOP + 0.3, 0), LEAN + Vector3(0.2, 2.9, 0.1)]
	_blaze_points = [LEAN + Vector3(-0.3, 3.2, 0.0), TREE_AT + Vector3(-0.8, 5.6, 0.3)]
	_rubble2_points = [] as Array[Vector3]
	_gate_pos = Vector3(KILN_AT.x, 1.5, -0.5)


## One baked tier (NatureKit mesh under the forge's own keys, this building's materials) with the height gradient.
func _fpart(nm: String, key: String, build: Callable, parent: Node3D, ao_bottom: float, ao_height: float,
		shadow: bool = true) -> MeshInstance3D:
	var mi: MeshInstance3D = NatureKit.node(nm, FKEY + key, build, _mats, parent, shadow)
	mi.set_instance_shader_parameter(&"ao_bottom", ao_bottom)
	mi.set_instance_shader_parameter(&"ao_height", ao_height)
	return mi


func _mesh_f_plinth(mb: NatureKit.MB) -> void:
	mb.loft("Dark", [NatureKit.chamfer(3.15, 0.95), NatureKit.chamfer(3.08, 0.93)], [0.0, 0.45])
	mb.loft("Dark", [NatureKit.chamfer(2.95, 0.85), NatureKit.chamfer(2.9, 0.83)], [0.45, 0.8])
	mb.box("Dark", Vector3(0.0, 0.36, -3.2), Vector3(1.7, 0.72, 0.5))
	mb.box("Dark", Vector3(0.0, 0.15, -3.58), Vector3(1.8, 0.3, 0.38))
	# Mossy fieldstones round the rim (two shades), a moss mat at the kiln's foot.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7501
	for i: int in 14:
		var a: float = TAU * float(i) / 14.0 + rng.randf_range(-0.1, 0.1)
		var d := Vector3(cos(a), 0, sin(a))
		var p: Vector3 = d * rng.randf_range(2.55, 2.7) * Vector3(1.0, 0, 1.0)
		if p.z < -2.0 and absf(p.x) < 1.2:
			continue
		var s := Vector3(rng.randf_range(0.5, 0.75), rng.randf_range(0.14, 0.24), rng.randf_range(0.4, 0.55))
		mb.box("Stone" if i % 3 != 0 else "Moss", p + Vector3(0, 0.8 + s.y * 0.4, 0), s, Basis(Vector3.UP, -a + rng.randf_range(-0.3, 0.3)))
	mb.sphere("Moss", KILN_AT + Vector3(0.0, 0.0, 0.0), 1.75, 0.07, 14, 4)
	# The leaning rune stone at the back-left corner (asymmetric secondary).
	NatureKit.menhir(mb, Vector3(-2.6, 0.76, 2.35), Vector3(-0.7, 0, 0.7).normalized(), 2.0, 0.32, 10.0)


## The kiln: a fieldstone dome (lathe), a dark base course, the glowing mouth facing the yard, a moss cap, the flue.
func _mesh_f_kiln(mb: NatureKit.MB) -> void:
	var c: Vector3 = KILN_AT
	mb.loft("Dark", [NatureKit.ring_n(10, 1.62, 0.0, Vector2(c.x, c.z)), NatureKit.ring_n(10, 1.55, 0.0, Vector2(c.x, c.z))],
		[c.y, c.y + 0.35], true, false, Vector2(c.x, c.z))
	var prof: Array[Vector2] = [Vector2(1.5, 0.3), Vector2(1.48, 0.8), Vector2(1.34, 1.35), Vector2(1.05, 1.8),
		Vector2(0.62, 2.08), Vector2(0.2, 2.15)]
	mb.lathe("Stone", c, prof, 12, 3.0, 0.08, 1.3)
	# Moss cap slumping over the top.
	mb.sphere("Moss", c + Vector3(0.1, 1.95, 0.15), 0.9, 0.42, 12, 6)
	# The mouth (-Z, toward the yard): a dark arch frame, the glow, a lintel stone.
	var mz: float = c.z - 1.38
	mb.box("Dark", Vector3(c.x, c.y + 0.75, mz), Vector3(1.25, 1.05, 0.45))
	mb.box("Gate", Vector3(c.x, c.y + 0.68, mz - 0.24), Vector3(0.82, 0.7, 0.06))
	mb.box("Stone", Vector3(c.x, c.y + 1.38, mz - 0.05), Vector3(1.45, 0.24, 0.55), Basis(Vector3.BACK, 0.04))
	mb.box("Dark", Vector3(c.x, c.y + 0.12, mz - 0.4), Vector3(1.1, 0.22, 0.4))
	mb.box("Heart", Vector3(c.x, c.y + 0.25, mz - 0.4), Vector3(0.8, 0.04, 0.26))
	# Bark flue from the dome into the chimney-tree.
	var f0: Vector3 = c + Vector3(0.9, 1.4, 0.2)
	var f1: Vector3 = TREE_AT + Vector3(-0.55, 2.1, -0.1)
	mb.tube("Bark", [f0, f0.lerp(f1, 0.5) + Vector3(0, 0.45, 0), f1] as Array[Vector3], [0.24, 0.21, 0.24] as Array[float], 8,
		2.0, 0.06, 0.7, true, true)
	for t: float in [0.3, 0.7]:
		var p: Vector3 = f0.lerp(f1, t) + Vector3(0, 0.45 * sin(t * PI), 0)
		mb.tube("Wood", [p - (f1 - f0).normalized() * 0.07, p + (f1 - f0).normalized() * 0.07] as Array[Vector3],
			[0.28, 0.28] as Array[float], 8, 1.0, 0.0, 0.0, true, true)


## Workshop: four bark posts and a beam, the stone anvil on a stump, the hollow-log trough, cut stone, a stack of logs.
func _mesh_f_workshop(mb: NatureKit.MB) -> void:
	var l: Vector3 = LEAN
	for cc: Vector2 in [Vector2(-1.0, -0.95), Vector2(0.95, -0.95), Vector2(-1.0, 0.85), Vector2(0.95, 0.85)]:
		var h: float = 2.35 if cc.y < 0.0 else 2.8
		var b := Vector3(l.x + cc.x, l.y, l.z + cc.y)
		mb.tube("Bark", [b, b + Vector3(0.03, h * 0.5, 0.0), b + Vector3(0.0, h, 0.02)] as Array[Vector3],
			[0.13, 0.11, 0.1] as Array[float], 6, 1.0, 0.1, cc.x + cc.y, false, true)
	for z: float in [-0.95, 0.85]:
		var y: float = l.y + (2.35 if z < 0.0 else 2.8)
		mb.tube("Bark", [Vector3(l.x - 1.15, y, l.z + z), Vector3(l.x + 1.1, y + 0.04, l.z + z)] as Array[Vector3],
			[0.1, 0.09] as Array[float], 6, 1.0, 0.05, z, true, true)
	# Anvil: a stump (wood rings on top) and a stone anvil with a horn.
	var an: Vector3 = l + Vector3(0.1, 0.0, -0.1)
	mb.tube("Bark", [an, an + Vector3(0, 0.55, 0)] as Array[Vector3], [0.36, 0.32] as Array[float], 9, 2.0, 0.08, 2.0, false, false)
	mb.loft("Wood", [NatureKit.ring_n(9, 0.33, 0.0, Vector2(an.x, an.z)), NatureKit.ring_n(9, 0.3, 0.0, Vector2(an.x, an.z))],
		[an.y + 0.5, an.y + 0.58], true, false, Vector2(an.x, an.z))
	mb.box("Stone", an + Vector3(0, 0.72, 0), Vector3(0.62, 0.2, 0.3), Basis(Vector3.UP, 0.35))
	mb.spike("Stone", an + Vector3(-0.28, 0.73, -0.1), Vector3(-0.94, 0, -0.34), 0.36, 0.1)
	mb.box("Heart", an + Vector3(0.06, 0.84, 0.0), Vector3(0.4, 0.04, 0.07), Basis(Vector3.UP, 0.7))   # a glowing blade
	# Hollow-log quench trough (right of the gate) with a dark water face.
	var tr := Vector3(1.4, 0.8, -2.05)
	mb.tube("Bark", [tr + Vector3(-0.75, 0.3, 0), tr + Vector3(0.75, 0.3, 0.05)] as Array[Vector3], [0.33, 0.31] as Array[float],
		9, 2.0, 0.08, 3.1, true, true)
	mb.box("Dark", tr + Vector3(0, 0.6, 0.02), Vector3(1.4, 0.04, 0.4))
	# Cut stone and logs waiting by the kiln.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7502
	for i: int in 3:
		mb.box("Stone", Vector3(2.55 - 0.15 * i, 0.8 + 0.2 + 0.36 * float(i / 2), -0.55 + 0.55 * float(i % 2)),
			Vector3(0.5, 0.36, 0.5), Basis(Vector3.UP, rng.randf_range(-0.3, 0.3)))
	for i: int in 3:
		var a := Vector3(-2.65, 0.95 + 0.25 * float(i % 2), 0.0 + 0.35 * i)
		mb.tube("Bark", [a, a + Vector3(0.05, 0.02, 1.0)] as Array[Vector3], [0.13, 0.12] as Array[float], 6, 1.0, 0.0, 0.0, true, true)


## The lean-to's living hedge roof: clumps along the sloping roof with a fringe of leaf cards.
func _mesh_f_hedge(mb: NatureKit.MB) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7503
	var l: Vector3 = LEAN
	var blobs: Array = []
	for k: int in 4:
		var x: float = l.x - 0.75 + 0.5 * k
		var z: float = l.z + (0.35 if k % 2 == 0 else -0.25)
		var y: float = l.y + lerpf(2.6, 3.05, 0.5 + 0.35 * (z - l.z))
		blobs.append(NatureKit.make_blob(rng, Vector3(x, y + 0.1, z), rng.randf_range(0.55, 0.64), Vector3(1.0, 0.7, 1.2),
			0.72, Vector3(0, 1, -0.3).normalized(), 11))
	for i: int in blobs.size():
		var b: NatureKit.Blob = blobs[i]
		NatureKit.blob_mesh(mb, b, 2, 0.2 + float(i) / 10.0, blobs)
		NatureKit.clump_cards(mb, b, rng, 7, 0, blobs, 0.6, -0.55, 0.2)


## The chimney-tree (tree-local, origin at TREE_AT): a thick flared bark trunk, roots gripping the plinth, an open
## hollow top (wood rim, glowing sap-fire inside), knots and a few bare twigs.
func _mesh_f_trunk(mb: NatureKit.MB) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7504
	var pts: Array[Vector3] = []
	var rad: Array[float] = []
	for i: int in 9:
		var t: float = float(i) / 8.0
		pts.append(Vector3(0.12 * sin(t * 4.0), lerpf(-0.1, TREE_TOP, t), 0.1 * sin(t * 3.0 + 1.0)))
		rad.append(lerpf(0.82, 0.5, pow(t, 0.7)) + 0.3 * (1.0 - smoothstep(0.0, 0.25, t)))
	mb.tube("Bark", pts, rad, 12, 3.0, 0.1, 0.6, false, false)
	var top: Vector3 = pts[pts.size() - 1]
	# Open hollow top: a ragged wood rim and the sap-fire inside.
	mb.loft("Wood", [NatureKit.ring_n(12, 0.5, 0.0, Vector2(top.x, top.z)), NatureKit.ring_n(12, 0.34, 0.0, Vector2(top.x, top.z))],
		[top.y, top.y + 0.06], false, false, Vector2(top.x, top.z))
	mb.annulus("Wood", NatureKit.ring_n(12, 0.5, 0.0, Vector2(top.x, top.z)), NatureKit.ring_n(12, 0.33, 0.0, Vector2(top.x, top.z)),
		top.y + 0.06)
	mb.loft("Dark", [NatureKit.ring_n(12, 0.33, 0.0, Vector2(top.x, top.z)), NatureKit.ring_n(12, 0.32, 0.0, Vector2(top.x, top.z))],
		[top.y - 0.5, top.y + 0.06], false, false, Vector2(top.x, top.z))
	mb.sphere("Heart", top + Vector3(0, -0.1, 0), 0.3, 0.55, 10, 5)
	for i: int in 6:
		var a: float = TAU * float(i) / 6.0 + rng.randf_range(-0.2, 0.2)
		var d := Vector3(cos(a), 0, sin(a))
		var b: Vector3 = top + d * 0.42
		mb.tube("Bark", [b, b + d * 0.06 + Vector3(0, rng.randf_range(0.25, 0.6), 0)] as Array[Vector3],
			[0.11, 0.0] as Array[float], 4, 1.0, 0.0, 0.0, false, false)
	# Roots gripping the plinth.
	for i: int in 5:
		var a: float = TAU * float(i) / 5.0 + 0.5
		var d := Vector3(cos(a), 0, sin(a))
		NatureKit.root(mb, d * 0.7 + Vector3(0, 0.55, 0), d * 1.25 + Vector3(0, 0.35, 0), d * rng.randf_range(1.6, 1.9)
			+ Vector3(0, -0.1, 0), 0.24, 0.07, float(i))
	# A glowing sap seam down the trunk (toward the camera side).
	mb.box("Heart", Vector3(-0.52, 3.2, -0.45), Vector3(0.05, 1.3, 0.05), Basis(Vector3.UP, 0.8) * Basis(Vector3.BACK, 0.12))


## The living branch on the trunk's yard side: a limb, a leaf clump with a fringe, one blossom.
func _mesh_f_branch(mb: NatureKit.MB) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7505
	var s := Vector3(-0.35, 4.6, -0.3)
	var e := Vector3(-1.45, 5.7, -0.75)
	mb.tube("Bark", [s, s.lerp(e, 0.5) + Vector3(0, 0.2, 0), e] as Array[Vector3], [0.2, 0.14, 0.1] as Array[float], 7, 1.0,
		0.08, 1.2, false, true)
	var b := NatureKit.make_blob(rng, e + Vector3(-0.15, 0.35, -0.05), 0.95, Vector3(1.1, 0.85, 1.0), 0.74,
		Vector3(-0.6, 0.6, -0.4).normalized(), 12)
	NatureKit.blob_mesh(mb, b, 2, 0.75, [b])
	NatureKit.clump_cards(mb, b, rng, 10, 1, [b], 0.8)   # one blossom (R5: few glow points)


func _mesh_f_banners(mb: NatureKit.MB) -> void:
	var face := Vector3(0.35, 0, -0.94).normalized()
	var bar: Vector3 = NatureKit.standard(mb, STANDARD_AT, 3.6, face, 1.3)
	mb.banner(bar + Vector3(0, -0.06, 0) + face * 0.08, face, 0.85, 2.0, 0.4)


# ---- ambient, scaffold, wreck ----

## Sap embers rising out of the hollow top (always on when built), leaves off the hedge and fireflies (near camera).
func _build_f_ambient() -> void:
	var glow_ramp: GradientTexture1D = NatureKit.ramp([0.0, 0.15, 0.7, 1.0], [Color(glow_color, 0.0),
		Color(glow_color, 1.0), Color(glow_color, 0.8), Color(glow_color, 0.0)], _glow_ramps)
	var em := _pm(Vector3.UP, 18.0, 0.5, 1.0, Vector3(0.1, 0.15, 0), 0.1, 0.04, glow_ramp)
	em.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	em.emission_sphere_radius = 0.25
	em.color = NatureKit.MOTE_DIM
	_idle_fx.append(_particles("SapEmbers", _tree, Vector3(0, TREE_TOP + 0.2, 0), 10, 2.4, em, NatureKit.soft_quad(true), false))
	var t := kingdom_color
	var leaf_ramp: GradientTexture1D = NatureKit.ramp([0.0, 0.08, 0.8, 1.0], [Color(t, 0.0), Color(t, 1.0),
		Color(t.darkened(0.2), 1.0), Color(t.darkened(0.3), 0.0)], _leaf_ramps)
	var lv := _pm(Vector3.DOWN, 20.0, 0.3, 0.7, Vector3(0.3, -0.3, 0.1), 0.26, 0.22, leaf_ramp)
	lv.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	lv.emission_box_extents = Vector3(1.1, 0.3, 1.0)
	lv.angle_min = 0.0
	lv.angle_max = 360.0
	lv.angular_velocity_min = -120.0
	lv.angular_velocity_max = 120.0
	_ambient.append(_particles("Leaves", _body, LEAN + Vector3(0, 3.2, 0), 5, 5.0, lv, NatureKit.shape_quad(0), false))
	if NatureKit.gfx_rich():
		var ff := NatureFireflies.make(Vector3(0.0, 2.8, 0.2), Vector3(3.0, 2.0, 3.0), 8)
		_body.add_child(ff)
		_ambient.append(ff)


func _build_f_scaffold() -> void:
	_scaffold = Node3D.new()
	_scaffold.name = "Scaffold"
	add_child(_scaffold)
	var mi: MeshInstance3D = NatureKit.node("ScaffoldParts", FKEY + "scaffold", _mesh_f_scaffold, _mats, _scaffold)
	mi.set_instance_shader_parameter(&"ao_bottom", 0.0)
	mi.set_instance_shader_parameter(&"ao_height", 5.0)
	_scaffold.visible = false


func _mesh_f_scaffold(mb: NatureKit.MB) -> void:
	var top: float = 3.6
	var hx: float = 2.55
	var hz: float = 2.3
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var b := Vector3(c.x * hx, 0.0, c.y * hz)
		mb.tube("Wood", [b, b + Vector3(0.03 * c.x, top * 0.5, 0), b + Vector3(0, top + 0.5, 0)] as Array[Vector3],
			[0.09, 0.085, 0.07] as Array[float], 6, 1.0, 0.1, c.x + c.y)
	for y: float in [top * 0.5, top]:
		for s: float in [-1.0, 1.0]:
			mb.box("Wood", Vector3(0, y, s * hz), Vector3(hx * 2.0 + 0.3, 0.08, 0.45), Basis(Vector3.BACK, s * 0.03))
			mb.box("Wood", Vector3(s * hx, y, 0), Vector3(0.45, 0.08, hz * 2.0 + 0.3), Basis(Vector3.RIGHT, s * 0.03))
	for p: Vector3 in [Vector3(-3.4, 0.3, -3.4), Vector3(-2.85, 0.3, -3.65), Vector3(-3.15, 0.86, -3.5)]:
		mb.box("Stone", p, Vector3(0.6, 0.56, 0.6), Basis(Vector3.UP, p.x))
	for i: int in 3:
		var a := Vector3(2.4 + 0.25 * i, 0.12 + 0.18 * float(i % 2), -3.3)
		mb.tube("Bark", [a, a + Vector3(0.1, 0.02, -1.3)] as Array[Vector3], [0.1, 0.07] as Array[float], 6, 1.0)


func _build_f_wreck() -> void:
	_wreck = Node3D.new()
	_wreck.name = "Wreck"
	add_child(_wreck)
	var mi: MeshInstance3D = NatureKit.node("WreckParts", FKEY + "wreck", _mesh_f_wreck, _mats, _wreck)
	mi.set_instance_shader_parameter(&"ao_bottom", 0.0)
	mi.set_instance_shader_parameter(&"ao_height", 3.0)
	_wreck.visible = false


## Collapse leftovers: the chimney-tree's shattered stump, kiln stones, fallen withered clumps, splinters, sap embers.
func _mesh_f_wreck(mb: NatureKit.MB) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7506
	var t: Vector3 = TREE_AT
	mb.tube("Bark", [t, t + Vector3(0, 1.4, 0)] as Array[Vector3], [0.95, 0.75] as Array[float], 11, 3.0, 0.1, 0.6, false, false)
	mb.loft("Wood", [NatureKit.ring_n(11, 0.72, 0.0, Vector2(t.x, t.z)), NatureKit.ring_n(11, 0.6, 0.0, Vector2(t.x, t.z))],
		[t.y + 1.38, t.y + 1.48], true, false, Vector2(t.x, t.z))
	for i: int in 7:
		var a: float = TAU * float(i) / 7.0 + rng.randf_range(-0.2, 0.2)
		var d := Vector3(cos(a), 0, sin(a))
		var b: Vector3 = t + d * rng.randf_range(0.45, 0.65) + Vector3(0, 1.4, 0)
		var h: float = rng.randf_range(0.4, 1.2)
		mb.tube("Bark", [b, b + d * 0.08 + Vector3(0, h * 0.6, 0), b + d * 0.14 + Vector3(0, h, 0)] as Array[Vector3],
			[rng.randf_range(0.14, 0.22), 0.1, 0.0] as Array[float], 5, 1.0, 0.0, 0.0, false, false)
	for i: int in 8:
		var a: float = TAU * float(i) / 8.0
		var p: Vector3 = KILN_AT + Vector3(cos(a) * 1.3, 0.25, sin(a) * 1.3)
		mb.box("Stone", p, Vector3(rng.randf_range(0.4, 0.6), rng.randf_range(0.3, 0.5), rng.randf_range(0.4, 0.55)),
			Basis.from_euler(Vector3(rng.randf_range(-0.3, 0.3), rng.randf() * TAU, rng.randf_range(-0.3, 0.3))))
	var blobs: Array = []
	for p: Vector3 in [LEAN + Vector3(0.2, 0.35, 0.0), Vector3(-3.4, 0.2, 0.9)]:
		blobs.append(NatureKit.make_blob(rng, p, rng.randf_range(0.6, 0.85), Vector3(1.2, 0.8, 1.1), 0.55, Vector3.UP, 6))
	for b: NatureKit.Blob in blobs:
		NatureKit.blob_mesh(mb, b, 1, 0.9, blobs)
	for i: int in 4:
		var p := Vector3(rng.randf_range(-1.8, 1.6), 0.9, rng.randf_range(-1.8, 1.8))
		mb.box("Gate", p, Vector3.ONE * 0.22, Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, 0.3))
