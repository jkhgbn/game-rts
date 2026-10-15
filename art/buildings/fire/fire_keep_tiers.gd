class_name FireKeepTiers
extends RefCounted
## Task G-B Fire (docs/art/gb_fire_buildings.md): the Fire Keep's tier looks and upgrade scaffold, built at run time
## with the keep builder's mesh kit (fire_keep_build.gd MB: metre UVs, palette slots S O D M T, glow kinds), drawn with
## the keep's own two materials (painted "P", glow "G") and its banner material: no new material.
##   Tier 2 Stronghold: four flying buttresses from the corner towers to the donjon (bronze-capped), a ring of bronze
##     war-spikes round the donjon crown, two tall obsidian standards flanking the gate with team war-banners.
##   Tier 3 Citadel (adds to tier 2): a crown of eight obsidian blades on the donjon, lava veins down the four corner
##     towers, four obsidian obelisks with ember tips at the plinth corners, a bronze crown hoop over the Ember Heart
##     (a child of the Spire: it topples with it).
##   Upgrade: a timber-and-bronze scaffold cage round the donjon, a glowing forging band that climbs it (animated by
##     FireKeepModel).
## Meshes are built once per run and shared by every Fire keep (static cache).

const KB := preload("res://art/buildings/fire_keep_build.gd")
const TOWERS: Array[Vector2] = [Vector2(2.6, -2.6), Vector2(-2.6, -2.6), Vector2(2.6, 2.6), Vector2(-2.6, 2.6)]
const CHIMNEY := 3   ## the forge chimney tower (fire_keep_build.gd)
const BAND_KIND := 0   ## glow kind of the forging band (coal: the fire glow, pulsing)

static var _cache: Dictionary = {}


## Builds the tier nodes under `body` (Body space) and `spire` (the Spire node). Returns
## {t2: Node3D, t3: Node3D, t3_spire: Node3D, scaffold: Node3D, band: MeshInstance3D}. All hidden.
static func build(body: Node3D, spire: Node3D, painted: Material, glow: Material, banner: Material) -> Dictionary:
	var mats := {"P": painted, "G": glow, "Banner": banner}
	var out := {}
	var t2 := Node3D.new()
	t2.name = "TierStronghold"
	body.add_child(t2)
	_add_mesh(t2, "Buttresses", _mesh("t2_stone", mats, _t2_stone), mats, 6.0, 7.0)
	_add_mesh(t2, "Standards", _mesh("t2_banners", mats, _t2_banners), mats, 0.0, 10.0, false)
	out["t2"] = t2
	var t3 := Node3D.new()
	t3.name = "TierCitadel"
	body.add_child(t3)
	_add_mesh(t3, "Blades", _mesh("t3_stone", mats, _t3_stone), mats, 0.0, 14.0)
	_add_mesh(t3, "Veins", _mesh("t3_glow", mats, _t3_glow), mats, 0.0, 1.0, false)
	out["t3"] = t3
	var t3s := Node3D.new()
	t3s.name = "CitadelCrown"
	spire.add_child(t3s)
	_add_mesh(t3s, "Hoop", _mesh("t3_crown", mats, _t3_crown), mats, 4.0, 3.0)
	out["t3_spire"] = t3s
	var sc := Node3D.new()
	sc.name = "UpgradeScaffold"
	body.add_child(sc)
	_add_mesh(sc, "Cage", _mesh("scaffold", mats, _scaffold), mats, 6.0, 7.0)
	out["scaffold"] = sc
	# The forging band: an octagonal glowing ring round the donjon (coal kind), moved by the keep.
	var band := MeshInstance3D.new()
	band.name = "ForgeBand"
	band.mesh = _mesh("band", mats, _band)[0]
	band.material_override = glow
	band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sc.add_child(band)
	band.set_instance_shader_parameter(&"kind_override", BAND_KIND)
	out["band"] = band
	for k: String in ["t2", "t3", "t3_spire", "scaffold"]:
		(out[k] as Node3D).visible = false
	return out


## [mesh, materials] for this keep: the mesh is built once per run (shared), the surface materials are this keep's own
## (every keep has its own painted / glow / banner materials: selection and damage stay per keep).
static func _mesh(key: String, mats: Dictionary, fn: Callable) -> Array:
	if not _cache.has(key):
		var mb: Variant = KB.MB.new()
		fn.call(mb)
		var res: Array = mb.commit(mats)
		var keys: Array[String] = []
		for m: Material in res[1]:
			keys.append(str(mats.find_key(m)))
		_cache[key] = [res[0], keys]
	var c: Array = _cache[key]
	var used: Array = []
	for k: String in c[1]:
		used.append(mats[k])
	return [c[0], used]


static func _add_mesh(parent: Node3D, nm: String, res: Array, _mats: Dictionary, ao_bottom: float, ao_height: float,
		shadow: bool = true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = res[0]
	var used: Array = res[1]
	for i: int in used.size():
		mi.set_surface_override_material(i, used[i])
	parent.add_child(mi)
	mi.set_instance_shader_parameter(&"ao_bottom", ao_bottom)
	mi.set_instance_shader_parameter(&"ao_height", ao_height)
	if not shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

## Tier 2: flying buttresses (tower top -> donjon) with bronze caps, bronze war-spikes round the donjon crown.
static func _t2_stone(mb: Variant) -> void:
	for c: Vector2 in TOWERS:
		var d := Vector3(c.x, 0, c.y).normalized()
		var p0: Vector3 = d * 3.05 + Vector3(0, 8.2, 0)
		var p1: Vector3 = d * 1.78 + Vector3(0, 10.9, 0)
		var axis: Vector3 = (p1 - p0)
		var seg_len: float = axis.length()
		var fwd: Vector3 = axis / seg_len
		var side: Vector3 = fwd.cross(Vector3.UP).normalized()
		var up: Vector3 = side.cross(fwd).normalized()
		var b := Basis(side, up, -fwd)
		var mid: Vector3 = (p0 + p1) * 0.5
		mb.box("S", mid, Vector3(0.46, 0.62, seg_len), b)
		mb.box("M", mid + up * 0.36, Vector3(0.56, 0.12, seg_len + 0.1), b)
		# A pier under the low end, on the tower crown, and a bronze collar where it meets the donjon.
		mb.box("D", p0 + Vector3(0, -0.15, 0) - d * 0.05, Vector3(0.62, 0.5, 0.62), Basis(Vector3.UP, atan2(d.x, d.z)))
		mb.box("M", p1 + d * 0.05, Vector3(0.66, 0.66, 0.2), b)
	# War-spikes: eight bronze spikes pointing out and up from under the donjon crown.
	for k: int in 8:
		var a: float = TAU * float(k) / 8.0 + PI / 8.0
		var d := Vector3(cos(a), 0, -sin(a))
		var side: Vector3 = d.cross(Vector3.UP)
		var base: Vector3 = d * 1.95 + Vector3(0, 11.55, 0)
		mb.tube("M", [base, base + d * 0.55 + Vector3(0, 0.18, 0), base + d * 1.05 + Vector3(0, 0.5, 0)] as Array[Vector3],
			[0.16, 0.09, 0.0] as Array[float], 4, side, PI * 0.25, true)
	# Tall finials on the two front tower roofs (bronze collar, obsidian spike to 15.8 m): the silhouette tells the
	# Stronghold from the Keep at any zoom. Not on the roof that falls below 50 % HP (tower 2) or the chimney (3).
	for ti: int in 2:
		var c: Vector2 = TOWERS[ti]
		var cc := Vector3(c.x, 0, c.y)
		mb.loft("M", [KB.hexr(0.26, c), KB.hexr(0.2, c), KB.hexr(0.2, c)], [12.75, 13.05, 13.3], true)
		mb.tube("O", [cc + Vector3(0, 13.3, 0), cc + Vector3(0, 14.4, 0), cc + Vector3(0, 15.8, 0)] as Array[Vector3],
			[0.16, 0.1, 0.0] as Array[float], 4, Vector3.RIGHT, PI * 0.25)


## Tier 2: two obsidian standards flanking the gate stairs, each with a crossbar and a team war-banner.
static func _t2_banners(mb: Variant) -> void:
	for sx: float in [-1.0, 1.0]:
		# On the ground just outside the plinth's front corners (clear of the tower banners).
		var foot := Vector3(sx * 3.95, 0.0, -3.45)
		var f2 := Vector2(foot.x, foot.z)
		mb.loft("D", [KB.hexr(0.42, f2), KB.hexr(0.34, f2)], [0.0, 0.45], true)
		mb.loft("O", [KB.hexr(0.16, f2), KB.hexr(0.11, f2)], [0.45, 10.6], false)
		mb.loft("M", [KB.hexr(0.24, f2), KB.hexr(0.24, f2)], [0.45, 0.9], false)
		mb.tooth("M", Vector3(foot.x, 10.6, foot.z), 0.26, 0.26, 0.0, 0.9, 0.0)
		mb.box("M", Vector3(foot.x, 10.15, foot.z - 0.02), Vector3(1.55, 0.12, 0.12))
		# The war-banner hangs in front of the pole (faces -Z, toward the gate side camera).
		var top := Vector3(foot.x, 10.1, foot.z - 0.14)
		var nx: int = 2
		var ny: int = 8
		var w: float = 1.35
		var h: float = 4.2
		for i: int in nx:
			for j: int in ny:
				var u0: float = float(i) / nx
				var u1: float = float(i + 1) / nx
				var v0: float = float(j) / ny
				var v1: float = float(j + 1) / ny
				var p := func(u: float, v: float) -> Vector3:
					return top + Vector3((u - 0.5) * w, -v * h, 0)
				mb.quad("Banner", p.call(u0, v0), p.call(u1, v0), p.call(u1, v1), p.call(u0, v1),
					Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1),
					top + Vector3(0, -h * 0.5, 1.0), Vector2(1.1 + sx, 0))


## Tier 3: a crown of eight obsidian blades on the donjon, four obelisks at the plinth corners.
static func _t3_stone(mb: Variant) -> void:
	for k: int in 8:
		var a: float = TAU * float(k) / 8.0
		var d := Vector3(cos(a), 0, -sin(a))
		var side: Vector3 = d.cross(Vector3.UP)
		var base: Vector3 = d * 1.98 + Vector3(0, 12.0, 0)
		var tall: float = 2.4 if k % 2 == 0 else 1.6
		mb.tube("O", [base, base + d * 0.25 + Vector3(0, tall * 0.5, 0), base + d * 0.55 + Vector3(0, tall, 0)] as Array[Vector3],
			[0.26, 0.17, 0.0] as Array[float], 4, side, PI * 0.25, true)
	for c: Vector2 in TOWERS:
		var d := Vector3(c.x, 0, c.y).normalized()
		var p: Vector3 = d * 4.75
		var ring0: Array = KB.ring_n(4, 0.48, PI * 0.25 + atan2(d.z, d.x), Vector2(p.x, p.z))
		var ring1: Array = KB.ring_n(4, 0.30, PI * 0.25 + atan2(d.z, d.x), Vector2(p.x, p.z))
		mb.loft("D", [KB.ring_n(4, 0.7, PI * 0.25, Vector2(p.x, p.z)), KB.ring_n(4, 0.6, PI * 0.25, Vector2(p.x, p.z))], [0.0, 0.35], true)
		mb.loft("O", [ring0, ring1], [0.35, 4.2], false)
		mb.tube("O", [p + Vector3(0, 4.2, 0), p + Vector3(0, 4.85, 0)] as Array[Vector3], [0.30 * 0.7071 + 0.08, 0.0] as Array[float],
			4, Vector3.RIGHT, PI * 0.25)
		mb.loft("M", [KB.ring_n(4, 0.52, PI * 0.25 + atan2(d.z, d.x), Vector2(p.x, p.z)),
			KB.ring_n(4, 0.52, PI * 0.25 + atan2(d.z, d.x), Vector2(p.x, p.z))], [1.6, 1.78], false)
	# The forge chimney rises 2.6 m higher (the Citadel's second vertical), bronze bands, a flared crown.
	var ch := Vector2(TOWERS[CHIMNEY].x, TOWERS[CHIMNEY].y)
	mb.loft("S", [KB.oct(0.66, ch), KB.oct(0.56, ch)], [14.85, 17.3], false)
	mb.band("M", KB.oct(0.7, ch), KB.oct(0.6, ch), 15.9, 16.2)
	mb.loft("D", [KB.oct(0.56, ch), KB.oct(0.82, ch), KB.oct(0.82, ch)], [17.3, 17.6, 17.9], false)
	mb.annulus("D", KB.oct(0.82, ch), KB.oct(0.5, ch), 17.9)
	for k: int in 4:
		var a: float = PI * 0.5 * float(k) + PI * 0.25
		var dd := Vector3(cos(a), 0, -sin(a))
		mb.tooth("O", Vector3(ch.x, 17.9, ch.y) + dd * 0.7, 0.24, 0.2, 0.0, 0.7, a + PI * 0.5)


## Tier 3 glow: lava veins down the outer diagonal face of each corner tower, ember tips on the obelisks.
static func _t3_glow(mb: Variant) -> void:
	for c: Vector2 in TOWERS:
		var d := Vector3(c.x, 0, c.y).normalized()
		var cc := Vector3(c.x, 0, c.y)
		var tng: Vector3 = d.cross(Vector3.UP)
		var vlen: float = 0.0
		var ys: Array[float] = [8.3, 6.6, 5.1, 3.3, 1.4]
		for i: int in ys.size() - 1:
			var y0: float = ys[i]
			var y1: float = ys[i + 1]
			var r0: float = lerpf(0.9, 1.06, (8.4 - y0) / 7.1) + 0.03
			var r1: float = lerpf(0.9, 1.06, (8.4 - y1) / 7.1) + 0.03
			var w0: float = 0.2 + 0.07 * float(i)
			var w1: float = 0.2 + 0.07 * float(i + 1)
			var wig0: float = 0.12 * sin(float(i) * 2.1)
			var wig1: float = 0.12 * sin(float(i + 1) * 2.1)
			var a: Vector3 = cc + d * r0 + tng * (wig0 - w0 * 0.5) + Vector3(0, y0, 0)
			var b: Vector3 = cc + d * r0 + tng * (wig0 + w0 * 0.5) + Vector3(0, y0, 0)
			var e: Vector3 = cc + d * r1 + tng * (wig1 + w1 * 0.5) + Vector3(0, y1, 0)
			var f: Vector3 = cc + d * r1 + tng * (wig1 - w1 * 0.5) + Vector3(0, y1, 0)
			var seg: float = y0 - y1
			mb.quad("Lava", a, b, e, f, Vector2(0, vlen), Vector2(w0, vlen), Vector2(w1, vlen + seg), Vector2(0, vlen + seg),
				cc + Vector3(0, (y0 + y1) * 0.5, 0))
			vlen += seg
		var p: Vector3 = d * 4.75
		mb.tube("Coal", [p + Vector3(0, 4.7, 0), p + Vector3(0, 5.25, 0)] as Array[Vector3], [0.16, 0.0] as Array[float], 4,
			Vector3.RIGHT, PI * 0.25)
	# The raised chimney's glowing mouth.
	var ch := Vector2(TOWERS[CHIMNEY].x, TOWERS[CHIMNEY].y)
	var mc := Vector3(ch.x, 17.7, ch.y)
	var mouth: Array = KB.oct(0.5, ch)
	for i: int in mouth.size():
		var q0: Vector2 = mouth[i]
		var q1: Vector2 = mouth[(i + 1) % mouth.size()]
		mb.tri("Coal", mc, Vector3(q0.x, 17.7, q0.y), Vector3(q1.x, 17.7, q1.y), Vector2.ZERO, Vector2.ZERO, Vector2.ZERO,
			mc - Vector3(0, 1, 0))


## Tier 3: a bronze crown hoop with eight points round the Ember Heart (Spire space: the heart is 4.2 m up).
static func _t3_crown(mb: Variant) -> void:
	var y: float = 5.25
	mb.band("M", KB.oct(1.62), KB.oct(1.46), y, y + 0.26)
	for k: int in 8:
		var a: float = TAU * float(k) / 8.0 + PI / 8.0
		var d := Vector3(cos(a), 0, -sin(a))
		mb.tooth("M", d * 1.6 + Vector3(0, y + 0.26, 0), 0.26, 0.14, 0.0, 0.95 if k % 2 == 0 else 0.5, a + PI * 0.5)


## Upgrade scaffold: four poles at the donjon diagonals (6 .. 13 m), two plank decks, cross braces, a hoist beam.
static func _scaffold(mb: Variant) -> void:
	var r: float = 2.55
	var pts: Array[Vector3] = []
	for k: int in 4:
		var a: float = PI * 0.25 + PI * 0.5 * float(k)
		pts.append(Vector3(cos(a) * r, 0, -sin(a) * r))
	for p: Vector3 in pts:
		mb.box("D", p + Vector3(0, 9.6, 0), Vector3(0.16, 7.2, 0.16))
	for k: int in 4:
		var p0: Vector3 = pts[k]
		var p1: Vector3 = pts[(k + 1) % 4]
		var mid: Vector3 = (p0 + p1) * 0.5
		var yaw: float = atan2((p1 - p0).x, (p1 - p0).z)
		for y: float in [8.6, 11.4]:
			mb.box("M", mid + Vector3(0, y, 0), Vector3(0.42, 0.07, p0.distance_to(p1) + 0.2), Basis(Vector3.UP, yaw))
		var dl: float = sqrt(pow(p0.distance_to(p1), 2.0) + 2.8 * 2.8)
		var tilt: float = atan2(2.8, p0.distance_to(p1))
		mb.box("D", mid + Vector3(0, 10.0, 0), Vector3(0.08, 0.08, dl), Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, tilt))
	mb.box("D", Vector3(0, 13.1, -1.2), Vector3(0.14, 0.14, 3.6))


## The forging band: a thin octagonal glowing ring (y 0, moved up the donjon by the keep).
static func _band(mb: Variant) -> void:
	mb.band("Gate", KB.oct(2.12), KB.oct(1.98), -0.06, 0.06)
