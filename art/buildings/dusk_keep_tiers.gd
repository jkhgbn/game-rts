class_name DuskKeepTiers
## G-B Shadow: the Dusk Keep's tier looks (Keep.set_tier: 1 Keep, 2 Stronghold, 3 Citadel) and its upgrade rig.
## Built once per keep by dusk_keep.gd in _ready, BEFORE the painted merge (the painted parts become vertex colours of
## the keep's one body material, like the carving). Model space (the Model node is scaled 1.12), gate = -Z (face 0).
##   Stronghold: four obsidian obelisks on the upper plinth (silver collars, a rune slit each, two carry team banners),
##     a ring of silver spikes at the prism 1 / 2 joint, a second counter-turning rune ring round prism 2.
##   Citadel: + a crown of six great obsidian thorns round the tip with a silver band, six obsidian fangs on the plinth
##     corners, a halo of seven blades with a soul ring orbiting the floating eye.
##   Upgrade rig (while upgrading): six soul-fire beams rising from the plinth corners (pulsed by the keep).
## Shapes only cost vertices: every painted part folds into the keep's existing body draw.

const BMG := preload("res://art/buildings/fire_hall_merge.gd")

const OBELISK_FACES: Array[float] = [60.0, 120.0, 240.0, 300.0]
const OBELISK_R := 2.62
const RING2_Y := 10.15
const HALO_Y := 16.6

static var _meshes: Dictionary = {}


## Horizontal unit vector `deg` degrees from -Z toward +X (dusk_keep.gd dir(), the art-keep.md face convention).
static func _dir(deg: float) -> Vector3:
	var th: float = deg_to_rad(deg)
	return Vector3(sin(th), 0.0, -cos(th))


static func _cyl(top: float, bottom: float, h: float, segs: int) -> CylinderMesh:
	var key: String = "%.3f|%.3f|%.3f|%d" % [top, bottom, h, segs]
	if not _meshes.has(key):
		var c := CylinderMesh.new()
		c.top_radius = top
		c.bottom_radius = bottom
		c.height = h
		c.radial_segments = segs
		c.rings = 0
		c.cap_top = top > 0.0
		_meshes[key] = c
	return _meshes[key]


static func _torus(inner: float, outer: float, rings: int) -> TorusMesh:
	var key: String = "t%.3f|%.3f|%d" % [inner, outer, rings]
	if not _meshes.has(key):
		var t := TorusMesh.new()
		t.inner_radius = inner
		t.outer_radius = outer
		t.rings = rings
		t.ring_segments = 4
		_meshes[key] = t
	return _meshes[key]


## A basis whose +Y points along `d` (normalised).
static func _along(d: Vector3) -> Basis:
	return Basis(Quaternion(Vector3.UP, d.normalized()))


## A cone (radius `r` at the base, `len` long) starting at `base` and pointing along `d`.
static func _spike(it: Array, base: Vector3, d: Vector3, r: float, length: float, mat: Material, segs: int = 4) -> void:
	var b: Basis = _along(d)
	it.append(BMG.item_xf(_cyl(0.0, r, length, segs), Transform3D(b, base + b * Vector3(0, length * 0.5, 0)), mat))


## Outward direction of face `deg`, raised `up_deg` above the horizontal.
static func _out(deg: float, up_deg: float) -> Vector3:
	var h: Vector3 = _dir(deg)
	var a: float = deg_to_rad(up_deg)
	return h * cos(a) + Vector3.UP * sin(a)


static func _mesh_node(nm: String, key: String, items: Array, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = BMG.mesh_for("dusk_keep/" + key, items)
	var mats: Array[Material] = BMG.materials_of(items)
	for i: int in mats.size():
		mi.set_surface_override_material(i, mats[i])
	parent.add_child(mi)
	return mi


## Builds every tier node under `model` (all hidden: the keep shows them by tier). `m` holds the keep's painted
## materials by name (dark, stone, silver, obsidian), `glow` its glow material, `banner` its banner material.
## Returns {t2, t3, ring2, halo, rig: Array[MeshInstance3D] beams}.
static func build(model: Node3D, m: Dictionary, glow: ShaderMaterial, banner: ShaderMaterial) -> Dictionary:
	var dark: Material = m["dark"]
	var stone: Material = m["stone"]
	var silver: Material = m["silver"]
	var obs: Material = m["obsidian"]
	var box := BoxMesh.new()
	var out := {}
	# --- Stronghold (tier 2) --------------------------------------------------------------------
	var t2 := Node3D.new()
	t2.name = "Tier2"
	model.add_child(t2)
	var it: Array = []
	for deg: float in OBELISK_FACES:
		var d: Vector3 = _dir(deg)
		var p: Vector3 = d * OBELISK_R + Vector3(0, 1.2, 0)
		var lean: Basis = Basis(Vector3.UP.cross(d).normalized(), deg_to_rad(-5.0))
		var yaw := Basis(Vector3.UP, -deg_to_rad(deg) + PI * 0.25)
		it.append(BMG.item_xf(box, Transform3D(yaw.scaled_local(Vector3(0.62, 0.3, 0.62)), p + Vector3(0, 0.15, 0)), dark))
		it.append(BMG.item_xf(_cyl(0.05, 0.31, 3.4, 4), Transform3D(lean * yaw, p + Vector3(0, 0.3, 0) + lean * Vector3(0, 1.7, 0)), obs))
		it.append(BMG.item_xf(_cyl(0.3, 0.32, 0.12, 4), Transform3D(lean * yaw, p + lean * Vector3(0, 1.05, 0)), silver))
		it.append(BMG.item_xf(_cyl(0.17, 0.2, 0.1, 4), Transform3D(lean * yaw, p + lean * Vector3(0, 2.5, 0)), silver))
		# Bone teeth round the obelisk's foot (pale stone).
		for k: int in 3:
			var a: float = deg_to_rad(deg + 40.0 * (k - 1))
			var td := Vector3(sin(a), 0.0, -cos(a))
			_spike(it, p + td * 0.36 + Vector3(0, 0.05, 0), td + Vector3(0, 1.6, 0), 0.07, 0.42, stone, 4)
	# Silver spikes at the prism 1 / prism 2 joint (y 8.7), on the twisted hex corners.
	for i: int in 6:
		var deg2: float = 30.0 + 60.0 * float(i) + 16.0
		var d2: Vector3 = _dir(deg2)
		_spike(it, d2 * 1.6 + Vector3(0, 8.62, 0), _out(deg2, 22.0), 0.12, 1.05, silver)
	_mesh_node("Tier2Stone", "tier2_stone", it, t2)
	# Glow: one rune slit on each obelisk's outer face.
	it = []
	for deg: float in OBELISK_FACES:
		var d: Vector3 = _dir(deg)
		var lean: Basis = Basis(Vector3.UP.cross(d).normalized(), deg_to_rad(-5.0))
		var p: Vector3 = d * OBELISK_R + Vector3(0, 1.5, 0) + lean * Vector3(0, 1.0, 0) + d * 0.17
		it.append(BMG.item_xf(box, Transform3D(lean * Basis(Vector3.UP, -deg_to_rad(deg)).scaled_local(Vector3(0.07, 0.9, 0.05)), p), glow))
	var slits := _mesh_node("Tier2Runes", "tier2_runes", it, t2)
	slits.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	slits.set_instance_shader_parameter(&"energy", 1.1)   # G-E fixes D (was 2.4)
	slits.set_instance_shader_parameter(&"pulse_speed", 1.3)
	# Team banners on the two obelisks flanking the gate.
	for deg: float in [60.0, 300.0]:
		var d: Vector3 = _dir(deg)
		var pm := PlaneMesh.new()
		pm.size = Vector2(0.62, 1.55)
		pm.orientation = PlaneMesh.FACE_Z
		pm.subdivide_width = 2
		pm.subdivide_depth = 8
		var bn := MeshInstance3D.new()
		bn.name = "Tier2Banner%d" % int(deg)
		bn.mesh = pm
		bn.material_override = banner
		bn.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bn.transform = Transform3D(Basis(Vector3.UP, PI - deg_to_rad(deg)), d * (OBELISK_R + 0.32) + Vector3(0, 2.35, 0))
		bn.set_instance_shader_parameter(&"phase", deg * 0.05)
		t2.add_child(bn)
	# Second rune ring, counter-turning round prism 2.
	var ring2 := MeshInstance3D.new()
	ring2.name = "RuneRing2"
	ring2.mesh = _torus(2.12, 2.24, 32)
	ring2.material_override = glow
	ring2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring2.position = Vector3(0, RING2_Y, 0)
	ring2.rotation = Vector3(deg_to_rad(7.0), 0, deg_to_rad(-5.0))
	ring2.set_instance_shader_parameter(&"energy", 1.0)   # G-E fixes D (was 2.2)
	ring2.set_instance_shader_parameter(&"pulse_speed", 1.6)
	ring2.set_instance_shader_parameter(&"rune_bands", 12)
	t2.add_child(ring2)
	out["t2"] = t2
	out["ring2"] = ring2
	# --- Citadel (tier 3) -----------------------------------------------------------------------
	var t3 := Node3D.new()
	t3.name = "Tier3"
	model.add_child(t3)
	it = []
	# Crown of six great thorns round the prism 3 / tip joint, and a silver band under them.
	it.append(BMG.item_xf(_cyl(1.02, 1.08, 0.24, 6), Transform3D(Basis(Vector3.UP, deg_to_rad(52.0)), Vector3(0, 13.45, 0)), silver))
	for i: int in 6:
		var deg3: float = 60.0 * float(i) + 52.0
		var d3: Vector3 = _dir(deg3)
		var tall: float = 2.9 if i % 2 == 0 else 2.2
		_spike(it, d3 * 0.82 + Vector3(0, 13.3, 0), _out(deg3, 58.0), 0.26, tall, obs)
		_spike(it, d3 * 0.95 + Vector3(0, 13.45, 0) + _out(deg3, 58.0) * 0.9, _out(deg3 + 25.0, 20.0), 0.08, 0.55, silver)
	# Fangs on the plinth corners.
	for i: int in 6:
		var deg4: float = 30.0 + 60.0 * float(i)
		var d4: Vector3 = _dir(deg4)
		_spike(it, d4 * 3.05 + Vector3(0, 0.6, 0), _out(deg4, 62.0), 0.24, 1.55, obs)
		_spike(it, d4 * 3.2 + _dir(deg4 + 90.0) * 0.32 + Vector3(0, 0.55, 0), _out(deg4 + 12.0, 50.0), 0.12, 0.8, dark)
	_mesh_node("Tier3Stone", "tier3_stone", it, t3)
	# Halo: seven blades and a soul ring orbiting the eye (turned by the keep).
	var halo := Node3D.new()
	halo.name = "Halo"
	halo.position = Vector3(0, HALO_Y, 0)
	t3.add_child(halo)
	it = []
	for i: int in 7:
		var a: float = TAU * float(i) / 7.0
		var d5 := Vector3(cos(a), 0.0, sin(a))
		var b: Basis = _along(d5 * 0.35 + Vector3.UP) * Basis.from_scale(Vector3(1.0, 1.0, 0.35))
		it.append(BMG.item_xf(_cyl(0.0, 0.17, 1.15, 4), Transform3D(b, d5 * 1.55 + Vector3(0, -0.15, 0)), obs))
	var blades := _mesh_node("HaloBlades", "halo_blades", it, halo)
	blades.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var crown := MeshInstance3D.new()
	crown.name = "SoulCrown"
	crown.mesh = _torus(1.5, 1.58, 28)
	crown.material_override = glow
	crown.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	crown.position = Vector3(0, -0.55, 0)
	crown.set_instance_shader_parameter(&"energy", 1.2)   # G-E fixes D (was 2.6)
	crown.set_instance_shader_parameter(&"pulse_speed", 2.2)
	crown.set_instance_shader_parameter(&"rune_bands", 7)
	halo.add_child(crown)
	out["t3"] = t3
	out["halo"] = halo
	# --- Upgrade rig ------------------------------------------------------------------------------
	var rig := Node3D.new()
	rig.name = "UpgradeRig"
	model.add_child(rig)
	var beams: Array[MeshInstance3D] = []
	for i: int in 6:
		var deg6: float = 30.0 + 60.0 * float(i)
		var bm := MeshInstance3D.new()
		bm.name = "Beam%d" % i
		bm.mesh = _cyl(0.05, 0.11, 1.0, 4)
		bm.material_override = glow
		bm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bm.position = _dir(deg6) * 3.05 + Vector3(0, 0.7, 0)
		bm.set_instance_shader_parameter(&"energy", 2.8)
		bm.set_instance_shader_parameter(&"pulse_speed", 5.0)
		bm.set_instance_shader_parameter(&"rune_bands", 3)
		bm.set_instance_shader_parameter(&"phase", float(i) * 1.1)
		rig.add_child(bm)
		beams.append(bm)
	out["rig"] = rig
	out["beams"] = beams
	t2.visible = false
	t3.visible = false
	rig.visible = false
	return out
