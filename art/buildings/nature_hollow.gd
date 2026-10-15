class_name NatureHollowModel
extends SmallBuildingModel
## Nature house "Seed Hollow" (kingdom-nature.md 4 + 7.1: 2 x 2 cells = 4 x 4 m, +10 pop). Task 8.V2, epic pass A2.6
## in the Heartwood's language (art/buildings/nature_keep*). Read from the RTS camera: a giant seed pod (a bark husk
## with raised seams, glowing sap in its furrows) grown up out of a ruined ring of mossy stones, its roots gripping
## the stones and pouring into the ground; a leaf roof on top (a lumpy team-coloured cap with baked gaps, big
## leaves draped over the husk, blossoms); a curled sprout stem rising out of the cap into a crook with a glowing
## seed-lantern swinging under it (dominant vertical); the keep's arched door in the ring wall (voussoirs, dark
## doorway, glowing vines), two round glowing windows in the husk; a team leaf banner on a standard at the
## front-right; a fiddlehead fern and glowing mushrooms at the front-left (asymmetric secondary); a moss patch with
## a fairy ring on the ground. Tiers are baked meshes (NatureKit); no active light (emissive + bloom only); the
## ambient particles only run near the camera. Hooks: see SmallBuildingModel. States: < 50 % HP a leaf of the roof
## is torn off and smoke rises, < 25 % the windows dim, the lantern shakes and withered leaves pour down.

const KEY := "nature_hollow/"
const POD_TOP := 3.62
const LANTERN_PIVOT := Vector3(1.12, 5.28, 0.42)
const STANDARD := Vector3(1.68, 0.0, -1.62)
const NEAR_ON := 42.0
const NEAR_OFF := 47.0
## Husk profile (radius, y), bottom to top.
const PROFILE: Array[Vector2] = [Vector2(0.95, 0.42), Vector2(1.34, 0.72), Vector2(1.6, 1.2), Vector2(1.68, 1.78),
	Vector2(1.58, 2.38), Vector2(1.33, 2.9), Vector2(0.98, 3.3), Vector2(0.55, 3.55), Vector2(0.12, POD_TOP)]

var _mats: Dictionary = {}
var _ground_mat: ShaderMaterial
var _lantern: Node3D
var _lost: MeshInstance3D
var _ambient: Array[GPUParticles3D] = []
var _ambient_on: bool = false
var _cam_check: float = 0.0
var _glow_ramps: Array = []
var _leaf_ramps: Array = []
var _agitated: bool = false


func _setup() -> void:
	kingdom_color = NatureKit.TEAM
	glow_color = NatureKit.GLOW
	stone_color = Color(0.5, 0.47, 0.37)
	dark_color = Color(0.26, 0.24, 0.17)
	trim_color = Color(0.40, 0.28, 0.16)
	smoke_color = Color(0.24, 0.22, 0.17)
	stain_color = Color(0.20, 0.35, 0.12, 0.45)
	footprint = 4.0
	vc_merge = true   # B8: merged glows (PaintedVC) + the NatureKit merge in _post_build
	plinth_top = 0.4
	wreck_top = 1.0
	smoke_points = [Vector3(0.5, 3.6, -0.4)]
	blaze_points = [Vector3(-0.3, 4.2, 0.3)]


## B8: the NatureKit painted / card materials drawn as one merged material each (NatureVC).
func _post_build() -> void:
	NatureKit.NVC.convert(self, _mats)


## B8: the state particles use NatureKit's soft dots (the pollen's ADD dot, the leaves / petals atlas for MIX).
func _quad_for(add: bool) -> Mesh:
	return NatureKit.soft_quad(add)


## The Heartwood's materials (per instance) in the base class slots.
func _make_materials() -> void:
	_mats = NatureKit.make_materials()
	_m_stone = _mats["Stone"]
	_m_dark = _mats["Dark"]
	_m_trim = _mats["Bark"]
	_m_team = _mats["Leaves"]
	_m_hole = _mats["Black"]
	_painted = NatureKit.surface_materials(_mats)
	_glows = [_mats["Heart"], _mats["Gate"], _mats["Blossom"], _mats["Petal"]] as Array[ShaderMaterial]
	_team_glows = [_mats["Heart"], _mats["Gate"]] as Array[ShaderMaterial]


func _build_parts() -> void:
	var plinth := _tier("Plinth", "plinth", _mesh_plinth)
	_no_collapse.append(plinth)
	_tier("Walls", "walls", _mesh_walls)
	var roof := _tier("LeafRoof", "roof", _mesh_roof.bind(false))
	_lost = _tier("LeafRoofLost", "roof_lost", _mesh_roof.bind(true))
	var banner := _tier("Banner", "banner", _mesh_banner, false)
	# The seed-lantern swings under the crook (a floater: it appears at 95 % and bursts at the collapse).
	_lantern = Node3D.new()
	_lantern.name = "LanternPivot"
	_lantern.position = LANTERN_PIVOT
	_body.add_child(_lantern)
	NatureKit.node("Lantern", KEY + "lantern", _mesh_lantern, _mats, _lantern, false)
	_floaters.append(_lantern)
	_hide_on_collapse.append_array([roof, _lost, banner])
	_build_ambient()
	_build_scaffold_nature()
	_build_wreck_nature()


func _tier(nm: String, key: String, build: Callable, shadow: bool = true) -> MeshInstance3D:
	return NatureKit.node(nm, KEY + key, build, _mats, _body, shadow)


func _mesh_plinth(mb: NatureKit.MB) -> void:
	mb.loft("Dark", [NatureKit.ring_n(10, 2.04, PI / 10.0), NatureKit.ring_n(10, 1.98, PI / 10.0)], [0.0, 0.4])
	# Door step: two flat stones down from the arch.
	mb.box("Dark", Vector3(0, 0.3, -2.02), Vector3(1.05, 0.2, 0.42))
	mb.box("Dark", Vector3(0.05, 0.1, -2.36), Vector3(0.95, 0.2, 0.36), Basis(Vector3.UP, 0.08))


func _mesh_walls(mb: NatureKit.MB) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2611
	# The ruined ring wall: a low mossy drum with a broken crown of blocks (a gap for the door).
	mb.loft("Stone", [NatureKit.ring_n(16, 1.96), NatureKit.ring_n(16, 1.9)], [0.4, 0.95], false)
	mb.annulus("Stone", NatureKit.ring_n(16, 1.9), NatureKit.ring_n(16, 1.55), 0.95)
	for k: int in 16:
		var a: float = TAU * (float(k) + 0.5) / 16.0
		var d := Vector3(cos(a), 0.0, -sin(a))
		if d.z < -0.8 or rng.randf() < 0.25:
			continue   # the door gap, and missing blocks
		var h: float = rng.randf_range(0.2, 0.5)
		mb.box("Stone", d * 1.74 + Vector3(0, 0.95 + h * 0.5 - 0.03, 0), Vector3(0.62, h, 0.34),
			Basis(Vector3.UP, a + PI * 0.5) * Basis(Vector3.FORWARD, rng.randf_range(-0.15, 0.15)))
	# The husk: a bark seed pod with sap glowing in its furrows, six raised seams running up it.
	mb.lathe("Bark", Vector3.ZERO, PROFILE, 16, 3.0, 0.035, 1.3)
	for s: int in 6:
		var a: float = TAU * float(s) / 6.0 + 0.26
		var d := Vector3(cos(a), 0.0, sin(a))
		if d.z < -0.85:
			continue   # the door side
		var pts: Array[Vector3] = []
		var rad: Array[float] = []
		for i: int in range(1, PROFILE.size()):
			var q: Vector2 = PROFILE[i]
			pts.append(d * (q.x + 0.02) + Vector3(0, q.y, 0))
			rad.append(lerpf(0.12, 0.05, float(i) / float(PROFILE.size())))
		mb.tube("Bark", pts, rad, 6, 1.0, 0.05, float(s), false, true)
	# Roots out of the husk's foot over the ring wall into the ground (clear of the door and the standard).
	var i: int = 0
	for deg: float in [74.0, 118.0, 165.0, 212.0, 262.0, 305.0]:
		var d: Vector3 = NatureKit.dir_deg(deg)
		NatureKit.root(mb, d * 1.2 + Vector3(0, 0.75, 0), d * 1.95 + Vector3(0, 1.28, 0), d * 2.35 + Vector3(0, -0.3, 0),
			0.2 - 0.02 * float(i % 2), 0.07, float(i) * 2.1)
		i += 1
	# The door: the keep's arch in the ring wall (jambs, voussoirs, keystone seed gem), a dark doorway, glowing vines.
	var zc: float = -1.93
	var spring: float = 0.98
	var ar: float = 0.42
	for sx: float in [-1.0, 1.0]:
		mb.box("Dark", Vector3(sx * (ar + 0.13), 0.7, zc + 0.05), Vector3(0.26, 0.62, 0.34))
	for k: int in 7:
		var a0: float = PI * float(k) / 7.0 + 0.02
		var a1: float = PI * float(k + 1) / 7.0 - 0.02
		var r1: float = ar + 0.24 + (0.1 if k == 3 else 0.0)
		var p: Array[Vector3] = []
		for bit: int in 8:
			var a: float = a1 if (bit & 1) != 0 else a0
			var r: float = r1 if (bit & 2) != 0 else ar
			var z: float = zc - 0.12 if (bit & 4) != 0 else zc + 0.2
			p.append(Vector3(cos(a) * r, spring + sin(a) * r, z))
		mb.hexa("Dark", p)
	var ks := Vector3(0, spring + ar + 0.17, zc - 0.14)
	var gem: Array[Vector3] = [ks + Vector3(0, 0.1, 0), ks + Vector3(0.08, 0, 0), ks + Vector3(0, -0.1, 0), ks + Vector3(-0.08, 0, 0)]
	for k: int in 4:
		mb.tri_auto("Gate", gem[k], gem[(k + 1) % 4], ks + Vector3(0, 0, -0.06), ks + Vector3(0, 0, 0.1))
	var door: Array[Vector3] = [Vector3(-ar, 0.4, zc), Vector3(ar, 0.4, zc)]
	for k: int in 9:
		var a: float = PI * float(k) / 8.0
		door.append(Vector3(cos(a) * ar, spring + sin(a) * ar, zc))
	mb.poly("Black", door, Vector3(0, 0.9, zc + 1.0))
	for k: int in 4:
		var x: float = -0.27 + 0.18 * float(k)
		var top: float = spring + sqrt(maxf(ar * ar - x * x, 0.0)) - 0.03
		var bottom: float = lerpf(0.72, 1.12, absf(sin(float(k) * 1.9)))
		mb.box("Gate", Vector3(x, (top + bottom) * 0.5, zc - 0.02), Vector3(0.04, top - bottom, 0.03))
		mb.box("Gate", Vector3(x + 0.02, bottom + 0.04, zc - 0.03), Vector3(0.08, 0.08, 0.04), Basis(Vector3.BACK, PI * 0.25))
	# Two round glowing windows in the husk, framed by bark rings.
	for yaw: float in [-1.15, 1.2]:
		var d := Vector3(sin(yaw), 0.0, -cos(yaw))
		var c: Vector3 = d * 1.66 + Vector3(0, 2.05, 0)
		var up := Vector3.UP
		var side: Vector3 = up.cross(d).normalized()
		var pane: Array[Vector3] = []
		for k: int in 10:
			var a: float = TAU * float(k) / 10.0
			pane.append(c + d * 0.04 + (side * cos(a) + up * sin(a)) * 0.24)
		mb.poly("Gate", pane, c - d)
		var ring: Array[Vector3] = []
		for k: int in 13:
			var a: float = TAU * float(k) / 12.0
			ring.append(c + d * 0.06 + (side * cos(a) + up * sin(a)) * 0.3)
		mb.tube("Bark", ring, [0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07, 0.07] as Array[float],
			5, 1.0, 0.1, yaw, false, false)
		mb.box("Dark", c + d * 0.08 + Vector3(0, 0.02, 0), Vector3(0.05, 0.5, 0.04), Basis(side, up, d))


static func _banner_face() -> Vector3:
	return Vector3(sin(deg_to_rad(35.0)), 0, -cos(deg_to_rad(35.0)))


## The leaf roof: a lumpy cap on the husk's crown (baked gaps between its lumps), big leaves draped over the husk,
## a fringe of small leaves, blossoms. `lost` = the front-right draped leaf and its tuft (torn off below 50 % HP).
func _mesh_roof(mb: NatureKit.MB, lost: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2612
	var blobs: Array = []
	blobs.append(NatureKit.make_blob(rng, Vector3(0, POD_TOP - 0.1, 0), 1.08, Vector3(1.28, 1.0, 1.28), 0.55, Vector3.UP, 13, true))
	for k: int in 5:
		var a: float = TAU * float(k) / 5.0 - 0.64   # k = 0: front-right (+X, -Z)
		var d := Vector3(cos(a), 0, sin(a))
		blobs.append(NatureKit.make_blob(rng, d * 1.05 + Vector3(0, POD_TOP - 0.45, 0), rng.randf_range(0.55, 0.68),
			Vector3.ONE, 0.7, d, 9))
	# Blob 1 (the front-right tuft) is the lost part.
	for k: int in blobs.size():
		if (k == 1) != lost:
			continue
		var b: NatureKit.Blob = blobs[k]
		NatureKit.blob_mesh(mb, b, 2, float(k) / 8.0, blobs)
		NatureKit.clump_cards(mb, b, rng, 12 if k == 0 else 6, 3 if k == 0 else 0, blobs, 0.7, -0.4, 0.2)
	# Big draped leaves between the tufts, from the cap's rim down over the husk's shoulder; the front one is lost.
	for k: int in 5:
		var a: float = TAU * float(k) / 5.0 - 0.01
		if (k == 4) != lost:
			continue
		var d := Vector3(cos(a), 0, sin(a))
		var side := Vector3(-d.z, 0, d.x)
		var pts: Array[Vector3] = []
		var nrm: Array[Vector3] = []
		for s: int in 5:
			var t: float = float(s) / 4.0
			var r: float = lerpf(0.55, 1.95, t)
			var y: float = POD_TOP + 0.35 - 1.55 * t * t
			pts.append(d * r + Vector3(0, y, 0))
			nrm.append((Vector3.UP * (1.0 - t * 0.6) + d * (0.3 + t)).normalized())
		mb.strip("LeafCard", pts, side, 1.05, nrm, rng.randf(), rng.randf())
	if not lost:
		_stem(mb)


## The sprout stem out of the cap, curling back into a crook (the dominant vertical), two leaves on it.
func _stem(mb: NatureKit.MB) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2613
	var p: Array[Vector3] = [Vector3(0.05, POD_TOP + 0.2, 0.05), Vector3(0.12, 4.55, 0.1), Vector3(0.32, 5.3, 0.22),
		Vector3(0.66, 5.78, 0.36), Vector3(1.0, 5.72, 0.44), Vector3(1.14, 5.42, 0.43), Vector3(1.1, 5.25, 0.4)]
	mb.tube("Bark", p, [0.2, 0.17, 0.14, 0.12, 0.1, 0.085, 0.075] as Array[float], 8, 1.0, 0.06, 0.7, false, true)
	for l: Array in [[p[1] + Vector3(0, -0.1, 0), Vector3(-0.8, 0.5, -0.5)], [p[2] + Vector3(0, 0.05, 0), Vector3(0.3, 0.6, -0.9)]]:
		var base: Vector3 = l[0]
		var dir: Vector3 = (l[1] as Vector3).normalized()
		var bend: Vector3 = (dir + Vector3.DOWN * 0.7).normalized()
		var side: Vector3 = dir.cross(Vector3.UP).normalized()
		var nn: Vector3 = (Vector3.UP + dir * 0.3).normalized()
		mb.strip("LeafCard", [base, base + dir * 0.5, base + dir * 0.5 + bend * 0.5] as Array[Vector3], side, 0.55,
			[nn, nn, nn] as Array[Vector3], rng.randf(), rng.randf())


func _mesh_lantern(mb: NatureKit.MB) -> void:
	NatureKit.lantern(mb, 0.28, Vector3(0.03, 0, 0.02), 1.05)


## The team banner on its standard (front-right, on the ground).
func _mesh_banner(mb: NatureKit.MB) -> void:
	var face: Vector3 = _banner_face()
	NatureKit.standard(mb, STANDARD, 3.2, face, 1.0, 0.85)
	var bar: Vector3 = STANDARD + Vector3(0, 3.2 - 0.5, 0) + face * 0.1
	mb.banner(bar + Vector3(0, -0.06, 0) + face * 0.08, face, 0.72, 1.7, 0.9)


# ============================================================ ground, scaffold, wreck

## Moss patch (round plinth, fairy ring r 2.8) instead of the plain stain; ground dressing instead of the cubes.
func _build_ground() -> void:
	super()
	var pm := PlaneMesh.new()
	pm.size = Vector2(7.6, 7.6)
	_decal.mesh = pm
	_ground_mat = NatureKit.ground_material(7.6, 2.05, 5.0, 1.0, 2.85, 18.0, 1.7)
	_decal.material_override = _ground_mat
	var rubble := get_node_or_null(^"Rubble") as Node3D
	if rubble:
		rubble.visible = false
	var mi: MeshInstance3D = NatureKit.node("GroundDressing", KEY + "dressing", _mesh_dressing, _mats, self, false)
	mi.set_instance_shader_parameter(&"ao_bottom", -0.3)
	mi.set_instance_shader_parameter(&"ao_height", 1.5)


func _mesh_dressing(mb: NatureKit.MB) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2614
	# The fiddlehead fern at the front-left (asymmetric secondary), then boulders, ferns and glowing mushrooms.
	NatureKit.fiddlehead(mb, Vector3(-1.62, 0.02, -1.55), 1.5, rng)
	NatureKit.dressing(mb, rng, 5, 3, 3, 2.3, 3.0, _dress_blocked, 0.85)


## Keep the door path and the standard clear of ground dressing.
static func _dress_blocked(p: Vector3) -> bool:
	return (p.z < -1.6 and absf(p.x) < 1.2) or p.distance_to(STANDARD) < 0.6 \
		or p.distance_to(Vector3(-1.62, 0.0, -1.55)) < 0.7


func _build_scaffold_nature() -> void:
	_scaffold = Node3D.new()
	_scaffold.name = "Scaffold"
	add_child(_scaffold)
	NatureKit.node("ScaffoldParts", KEY + "scaffold", _mesh_scaffold, _mats, _scaffold)
	_scaffold.visible = false


## Wooden poles round the rising husk, two woven decks, a brace, a heap of stones and saplings.
func _mesh_scaffold(mb: NatureKit.MB) -> void:
	var h: float = 2.2
	var top: float = 3.9
	for c: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var b := Vector3(c.x * h, 0.0, c.y * h)
		mb.tube("Wood", [b, b + Vector3(0.03 * c.x, top * 0.5, 0), b + Vector3(0, top, 0)] as Array[Vector3],
			[0.08, 0.075, 0.06] as Array[float], 6, 1.0, 0.1, c.x + c.y)
	for y: float in [1.9, 3.5]:
		for s: float in [-1.0, 1.0]:
			mb.box("Wood", Vector3(0, y, s * h), Vector3(h * 2.0 + 0.25, 0.07, 0.4), Basis(Vector3.BACK, s * 0.04))
			mb.box("Wood", Vector3(s * h, y, 0), Vector3(0.4, 0.07, h * 2.0 + 0.25), Basis(Vector3.RIGHT, s * 0.04))
	var ang: float = atan2(top * 0.8, h * 2.0)
	mb.box("Wood", Vector3(-h - 0.08, top * 0.45, 0), Vector3(0.07, 0.07, sqrt(4.0 * h * h + top * top * 0.64)),
		Basis(Vector3.RIGHT, -ang))
	for p: Vector3 in [Vector3(2.55, 0.2, -2.3), Vector3(2.25, 0.2, -2.6), Vector3(2.45, 0.56, -2.45)]:
		mb.box("Stone", p, Vector3(0.44, 0.4, 0.44), Basis(Vector3.UP, p.z * 1.7))


func _build_wreck_nature() -> void:
	_wreck = Node3D.new()
	_wreck.name = "Wreck"
	add_child(_wreck)
	NatureKit.node("WreckParts", KEY + "wreck", _mesh_wreck, _mats, _wreck)
	_wreck.visible = false


## The burst husk: jagged bark shards standing round the squashed stub, broken wall stones, the fallen withered
## cap, sap embers.
func _mesh_wreck(mb: NatureKit.MB) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2615
	var stub: float = plinth_top + (1.8 - plinth_top) * 0.3
	for k: int in 9:
		var a: float = TAU * float(k) / 9.0 + rng.randf_range(-0.15, 0.15)
		var d := Vector3(cos(a), 0, sin(a))
		var b: Vector3 = d * rng.randf_range(1.05, 1.35) + Vector3(0, plinth_top, 0)
		var h: float = rng.randf_range(0.7, 1.6)
		mb.tube("Bark", [b, b + d * 0.12 + Vector3(0, h * 0.6, 0), b + d * 0.25 + Vector3(0, h, 0)] as Array[Vector3],
			[rng.randf_range(0.18, 0.28), 0.12, 0.0] as Array[float], 5, 1.0, 0.1, float(k), false, false)
	for k: int in 6:
		var a: float = rng.randf() * TAU
		var d := Vector3(cos(a), 0, sin(a))
		mb.box("Stone", d * rng.randf_range(1.6, 2.1) + Vector3(0, 0.55, 0), Vector3(0.5, 0.36, 0.34),
			Basis(Vector3.UP, a) * Basis(Vector3.FORWARD, rng.randf_range(-0.4, 0.4)))
	var cap := NatureKit.make_blob(rng, Vector3(0.9, stub + 0.1, 1.0), 0.8, Vector3(1.2, 1.0, 1.1), 0.5, Vector3.UP, 6)
	NatureKit.blob_mesh(mb, cap, 1, 0.9, [cap])
	for k: int in 4:
		mb.box("Gate", Vector3(rng.randf_range(-0.8, 0.8), stub + 0.03, rng.randf_range(-0.8, 0.8)), Vector3.ONE * 0.2,
			Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, 0.3))


# ============================================================ particles and states

## Ambient life (only near the camera): pollen from the lantern, leaves drifting off the roof.
func _build_ambient() -> void:
	var glow_ramp: GradientTexture1D = NatureKit.ramp([0.0, 0.15, 0.7, 1.0], [Color(glow_color, 0.0),
		Color(glow_color, 1.0), Color(glow_color, 0.8), Color(glow_color, 0.0)], _glow_ramps)
	# G-F r2 item 7: smaller (0.08 -> 0.045), the MIX dot (was additive) with the near-camera fade (MoteCap.apply_own;
	# none at Low, half at Medium).
	var po := NatureKit.process(Vector3.UP, 70.0, 0.08, 0.22, Vector3(0, 0.05, 0), 0.045, 0.025, glow_ramp)
	po.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	po.emission_sphere_radius = 0.5
	po.color = NatureKit.MOTE_DIM
	var p1 := MoteCap.apply_own(_particles("Pollen", _body, LANTERN_PIVOT + Vector3(0, -0.6, 0), 8, 2.6, po, false,
		false), null, 0.045)
	var t := kingdom_color
	var leaf_ramp: GradientTexture1D = NatureKit.ramp([0.0, 0.08, 0.8, 1.0], [Color(t, 0.0), Color(t, 1.0),
		Color(t.darkened(0.2), 1.0), Color(t.darkened(0.3), 0.0)], _leaf_ramps)
	var lv := NatureKit.process(Vector3.DOWN, 25.0, 0.3, 0.7, Vector3(0.25, -0.3, 0.1), 0.26, 0.22, leaf_ramp)
	lv.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	lv.emission_ring_axis = Vector3.UP
	lv.emission_ring_radius = 1.7
	lv.emission_ring_inner_radius = 0.8
	lv.emission_ring_height = 0.2
	NatureKit.tumble(lv, 120.0)
	lv.turbulence_enabled = true
	lv.turbulence_noise_strength = 0.5
	var p2 := _particles("Leaves", _body, Vector3(0, 3.6, 0), 5, 5.0, lv, false, false)
	p2.draw_pass_1 = NatureKit.shape_quad(0)
	_ambient = [p1, p2] as Array[GPUParticles3D]
	# G-B High / Ultra: a few fireflies around the pod (ambient: near the camera only).
	if NatureKit.gfx_rich():
		var ff := NatureFireflies.make(Vector3(0.0, 2.4, 0.0), Vector3(2.3, 1.5, 2.3), 6)
		_body.add_child(ff)
		_ambient.append(ff)


## Base state nodes, then the "blaze" plume becomes withering leaves pouring off the roof.
func _build_state_nodes() -> void:
	super()
	for b: GPUParticles3D in _blaze:
		NatureKit.make_withering(b, 1.0, 14)


func _idle(delta: float) -> void:
	var fast: float = 1.0
	var amp: float = deg_to_rad(9.0) * (1.8 if _agitated else 1.0)
	var ph: float = _t * TAU / 2.8 * fast
	var jit: float = sin(_t * 17.0) * 0.04 if _agitated else 0.0
	_lantern.rotation = Vector3(sin(ph) * amp + jit, 0.0, cos(ph * 0.8) * amp * 0.6)
	_cam_check -= delta
	if _cam_check <= 0.0:
		_cam_check = 0.5
		var d: float = NatureKit.camera_distance(self, global_position + Vector3(0, 2.5, 0))
		_set_ambient(d < (NEAR_OFF if _ambient_on else NEAR_ON) and _progress >= 1.0)


func _set_ambient(on: bool) -> void:
	if on == _ambient_on:
		return
	_ambient_on = on
	for p: GPUParticles3D in _ambient:
		p.emitting = on


func _on_progress(building: bool) -> void:
	if _ground_mat:
		_ground_mat.set_shader_parameter(&"build", _progress)
	if building:
		_set_ambient(false)
		if _progress <= 0.0:
			for part: GeometryInstance3D in _parts:
				part.visible = false   # at 0 only the glowing outline shows (art-keep.md 8.2)
	else:
		_cam_check = 0.0


func _on_health(smoke_on: bool, fire_on: bool) -> void:
	if _progress >= 1.0:
		_lost.visible = not smoke_on
	NatureKit.apply_health(_mats, _health_ratio, smoke_on, fire_on)
	(_mats["Gate"] as ShaderMaterial).set_shader_parameter(&"energy", 0.7 if fire_on else 1.6)
	_agitated = fire_on
	if _ground_mat:
		_ground_mat.set_shader_parameter(&"damage", 1.0 if fire_on else (0.5 if smoke_on else 0.0))


func _on_team_color(_g: Color) -> void:
	NatureKit.apply_team(_mats, _team_color)
	var glow: Color = NatureKit.glow_of(_team_color)
	if _ground_mat:
		_ground_mat.set_shader_parameter(&"glow_color", glow)
	for gr: Gradient in _glow_ramps:
		for i: int in gr.get_point_count():
			gr.set_color(i, Color(glow, gr.get_color(i).a))
	for gr: Gradient in _leaf_ramps:
		for i: int in gr.get_point_count():
			gr.set_color(i, Color(_team_color.darkened(0.25 * gr.get_offset(i)), gr.get_color(i).a))


func _on_destroy_start() -> void:
	_set_ambient(false)


## The collapse: keep the moss patch (the base swaps in its plain wreck stain), wither it, drain the sap.
func _on_destroy(t_now: float) -> void:
	if _decal.material_override != _ground_mat:
		_decal.material_override = _ground_mat
	var k: float = clampf((t_now - 1.2) / 1.0, 0.0, 1.0)
	_ground_mat.set_shader_parameter(&"scorch", k)
	if t_now >= 0.5:
		NatureKit.apply_wreck(_mats, k)


## The Heartwood's green idle rim (selection still turns it to the team colour), glow boost.
func _apply_rim_and_glow() -> void:
	super()
	if _ready_done and _body != null and not _mats.is_empty():
		NatureKit.apply_rim(_mats, _team_color, _sel_k, _progress < 1.0 and not _destroyed)
		NatureKit.apply_boost(_mats, _sel_boost())
