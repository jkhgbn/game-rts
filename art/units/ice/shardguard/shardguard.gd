extends IceModel
## Shardguard, Ice T3 anti-dive halberdier (t3-helpers.md 7.2 / 7.3, tiers wave). Height 2.2, radius 0.5, reach 2.4.
## A tall Ice heavy in WHITE-BLUE LAMELLAR (rows of pale plates over dark steel: skirt, cuirass, rerebraces), a tall
## helm with a glass fin crest and a glowing visor slit, a big crystal pauldron on the left only (the asymmetry), a
## rimed team cape with a fringe of icicles. The silhouette hook: a TOWER-HIGH GLAIVE held upright in the right fist,
## crowned by a glass-crescent head (Aldra's workshop) with a glowing rune at its socket and a team streamer.
## Glow points: the visor slit + the socket rune (both ice_glow_unit; the rune sits high = upper half).
## Attack `glaive_cleave` (0.8 s, strike 0.24 s): wind back, the crescent comes over and down in front, a step in.
## play_cast (any id: Hold the Line / Challenge, 1.0 s): the glaive is hoisted and PLANTED, a glass ring flashes at
## the feet. Braced (Hold the Line ready): `set_braced(true)` or `set_status(&"braced", true)` -> planted stance, glaive
## tipped forward, faint glass ring at the feet (hidden again with false).
## Death: IceModel freeze + shatter. Level 4: gold ring on the helm.
## Draws: merged pivots + Ring (keep_separate, hidden at rest) + blob + hidden vet trim; 0 lights.

const ATTACK_LEN := 0.8
const STRIKE_T := 0.24
const CAST_LEN := 1.0
const PLANT_T := 0.45
const FIST_R := Vector3(0.46, 1.08, 0.26)
const SHAFT_X := 0.46
const SHAFT_Z := 0.26
const HEAD_Y := 2.32

# Tracks: pairs [t, value, t, value ...], smoothstep between keys (degrees / metres).
static var A_ARM_R := PackedFloat32Array([0.0, 0.0, 0.12, -34.0, 0.24, 84.0, 0.42, 80.0, 0.8, 0.0])
static var A_ARM_RZP := PackedFloat32Array([0.0, 0.0, 0.12, -0.10, 0.24, 0.30, 0.42, 0.28, 0.8, 0.0])
static var A_ARM_RZ := PackedFloat32Array([0.0, 0.0, 0.12, -8.0, 0.24, 4.0, 0.8, 0.0])
static var A_ARM_L := PackedFloat32Array([0.0, 0.0, 0.12, -48.0, 0.24, -72.0, 0.42, -64.0, 0.8, 0.0])
static var A_CHEST_X := PackedFloat32Array([0.0, 0.0, 0.12, -8.0, 0.24, 14.0, 0.42, 12.0, 0.8, 0.0])
static var A_CHEST_Y := PackedFloat32Array([0.0, 0.0, 0.12, 24.0, 0.24, -4.0, 0.42, -2.0, 0.8, 0.0])
static var A_ROOT_Z := PackedFloat32Array([0.0, 0.0, 0.12, -0.08, 0.24, 0.36, 0.42, 0.32, 0.8, 0.0])
static var A_LEG_L := PackedFloat32Array([0.0, 0.0, 0.12, 6.0, 0.24, -30.0, 0.42, -26.0, 0.8, 0.0])
static var A_LEG_R := PackedFloat32Array([0.0, 0.0, 0.12, -4.0, 0.24, 18.0, 0.42, 16.0, 0.8, 0.0])
static var C_ARM_R := PackedFloat32Array([0.0, 0.0, 0.30, -24.0, 0.45, 20.0, 0.8, 16.0, 1.0, 0.0])
static var C_ARM_RY := PackedFloat32Array([0.0, 0.0, 0.30, 0.30, 0.45, -0.04, 0.8, -0.03, 1.0, 0.0])
static var C_ARM_L := PackedFloat32Array([0.0, 0.0, 0.30, -125.0, 0.45, -62.0, 0.8, -55.0, 1.0, 0.0])
static var C_CHEST_X := PackedFloat32Array([0.0, 0.0, 0.30, -12.0, 0.45, 14.0, 0.8, 10.0, 1.0, 0.0])
static var C_ROOT_Y := PackedFloat32Array([0.0, 0.0, 0.30, 0.05, 0.45, -0.11, 0.8, -0.08, 1.0, 0.0])

var _ring: MeshInstance3D
var _braced: bool = false
var _brace_w: float = 0.0
var _ring_t: float = 99.0     # time since the cast's ring flash
var _planted: bool = false


## Hold the Line ready -> braced stance + faint glass ring (gameplay calls it; also via set_status(&"braced")).
func set_braced(on: bool) -> void:
	_braced = on


func is_braced() -> bool:
	return _braced


func set_status(id: StringName, on: bool) -> bool:
	if id == &"braced" or id == &"hold_the_line":
		set_braced(on)
		return true
	return super.set_status(id, on)


func _build_parts() -> void:
	var root: Node3D = $Root
	var hips: Node3D = $Root/Hips
	var chest: Node3D = $Root/Chest
	var head: Node3D = $Root/Chest/Head
	var arm_l: Node3D = $Root/Chest/ArmL
	var arm_r: Node3D = $Root/Chest/ArmR
	var leg_l: Node3D = $Root/Hips/LegL
	var leg_r: Node3D = $Root/Hips/LegR
	var cloth := ice(&"ice_cloth")
	var dark := ice(&"ice_cloth_dark")
	var plate := ice(&"ice_metal")
	var steel := ice(&"ice_steel")
	var fur := ice(&"ice_fur")
	var rime := ice(&"ice_fur_pale")
	var frost := ice(&"ice_frost_crystal")
	var glow := ice(&"ice_glow_unit")
	var wood := ice(&"ice_wood")
	# ---- Legs: dark trousers, steel greaves with pale knee cops, heavy sabatons.
	for leg: Node3D in [leg_l, leg_r]:
		var sx: float = -1.0 if leg == leg_l else 1.0
		add_part(leg, capsule(0.12, 0.66), dark, Vector3(0.17 * sx, 0.48, 0))
		add_part(leg, cyl(0.13, 0.11, 0.36, 8), steel, Vector3(0.17 * sx, 0.30, 0.02))
		add_part(leg, sphere(0.095, 8, 4), plate, Vector3(0.17 * sx, 0.52, 0.09), Vector3.ZERO, Vector3(1.0, 1.0, 0.8))
		add_part(leg, box(Vector3(0.24, 0.12, 0.36)), steel, Vector3(0.17 * sx, 0.06, 0.05))
		add_part(leg, cyl(0.0, 0.09, 0.16, 6), plate, Vector3(0.17 * sx, 0.07, 0.27), Vector3(90, 0, 0), Vector3(1.2, 1.0, 0.6))
	# ---- Hips: dark fur under a flared LAMELLAR skirt (3 rows of pale plates, offset), steel belt + buckle.
	add_part(hips, cyl(0.27, 0.32, 0.30, 10), fur, Vector3(0, 0.76, 0))
	add_part(hips, _lamellar("sg_skirt2", 0.88, 0.36, 0.30, 0.38, 2, 13, 0.0, TAU), ice(&"ice_sec_shield"), Vector3.ZERO)
	add_part(hips, cyl(0.31, 0.31, 0.08, 12), steel, Vector3(0, 0.90, 0))
	add_part(hips, box(Vector3(0.14, 0.12, 0.05)), plate, Vector3(0, 0.90, 0.31))
	add_part(hips, box(Vector3(0.18, 0.40, 0.04)), cloth, Vector3(0, 0.68, 0.38), Vector3(-10, 0, 0))
	# ---- Chest: team torso, lamellar cuirass (front half), steel gorget; left crystal pauldron (big, 3 shards),
	# right round steel pauldron with plate lames; the rimed cape with an icicle fringe.
	add_part(chest, cyl(0.36, 0.27, 0.66, 10), cloth, Vector3(0, 1.22, 0))
	add_part(chest, _lamellar("sg_cuirass2", 1.48, 0.50, 0.38, 0.31, 4, 9, -1.6, 1.6), plate, Vector3.ZERO)
	add_part(chest, box(Vector3(0.46, 0.08, 0.10)), steel, Vector3(0, 1.00, 0.29))
	add_part(chest, cyl(0.20, 0.26, 0.14, 10), steel, Vector3(0, 1.56, 0))
	add_part(chest, cyl(0.15, 0.15, 0.08, 6), frost, Vector3(0, 1.30, 0.36), Vector3(82, 0, 0))
	add_part(chest, sphere(0.23, 10, 5), plate, Vector3(-0.46, 1.54, 0), Vector3.ZERO, Vector3(1.15, 0.72, 1.15))
	add_crystal(chest, Vector3(-0.52, 1.58, 0.04), Vector3(-0.55, 1.0, 0.12), 0.11, 0.56, frost)
	add_crystal(chest, Vector3(-0.46, 1.60, -0.12), Vector3(-0.3, 1.0, -0.5), 0.075, 0.38, frost)
	add_crystal(chest, Vector3(-0.58, 1.50, 0.14), Vector3(-1.0, 0.4, 0.3), 0.06, 0.28, frost)
	add_part(chest, sphere(0.19, 10, 5), steel, Vector3(0.46, 1.55, 0), Vector3.ZERO, Vector3(1.1, 0.75, 1.1))
	add_part(chest, _lamellar("sg_lames_r", 1.48, 0.20, 0.20, 0.24, 2, 6, 0.6, 2.6), plate, Vector3(0.46, 0, 0))
	add_part(chest, cape(0.66, 1.22), ice(&"ice_cape"), Vector3(0, 0.97, -0.34), Vector3(-7, 180, 0))
	add_part(chest, box(Vector3(0.70, 0.08, 0.10)), rime, Vector3(0, 1.54, -0.30))
	add_part(chest, box(Vector3(0.70, 0.07, 0.07)), rime, Vector3(0, 0.38, -0.42), Vector3(-7, 0, 0))
	for k: int in 5:
		var x: float = -0.28 + 0.14 * k
		add_crystal(chest, Vector3(x, 0.37, -0.43), Vector3(0.05 * (k - 2), -1.0, -0.12), 0.03, 0.16 + 0.05 * float(k % 2), frost, 0.6)
	# ---- Head: tall steel helm, pale brow plate, glowing visor slit, cheek guards, a crest of 3 glass fins.
	add_part(head, cyl(0.19, 0.22, 0.38, 10), steel, Vector3(0, 1.94, 0.02))
	add_part(head, cyl(0.02, 0.19, 0.16, 10), steel, Vector3(0, 2.20, 0.02))
	add_part(head, box(Vector3(0.40, 0.08, 0.10)), plate, Vector3(0, 2.02, 0.19), Vector3(-10, 0, 0))
	add_part(head, box(Vector3(0.28, 0.05, 0.05)), glow, Vector3(0, 1.94, 0.22))
	for sx: float in [-1.0, 1.0]:
		add_part(head, box(Vector3(0.06, 0.20, 0.14)), plate, Vector3(0.17 * sx, 1.84, 0.12), Vector3(0, 12 * sx, 0))
	add_part(head, box(Vector3(0.05, 0.14, 0.40)), cloth, Vector3(0, 2.18, -0.02))
	add_crystal(head, Vector3(0, 2.22, 0.10), Vector3(0, 1.0, 0.35), 0.06, 0.34, frost)
	add_crystal(head, Vector3(0, 2.24, -0.04), Vector3(0, 1.0, -0.25), 0.055, 0.30, frost)
	add_crystal(head, Vector3(0, 2.20, -0.16), Vector3(0, 0.6, -1.0), 0.05, 0.26, frost)
	var trim := add_part(head, torus(0.21, 0.26), palette(&"unit_gold_trim"), Vector3(0, 2.08, 0.02), Vector3.ZERO,
		Vector3.ONE, true, "VetTrim")
	if trim:
		trim.set_meta(&"vet_trim", true)
		trim.visible = false
	# ---- Left arm: dark sleeve, pale lamellar rerebrace, steel gauntlet (free hand, guard forward).
	add_limb(arm_l, Vector3(-0.47, 1.50, 0), Vector3(-0.50, 1.18, 0.04), 0.10, dark)
	add_part(arm_l, cyl(0.12, 0.13, 0.22, 8), plate, Vector3(-0.48, 1.36, 0.01))
	add_limb(arm_l, Vector3(-0.50, 1.18, 0.04), Vector3(-0.46, 0.96, 0.18), 0.09, steel, 0.10, steel)
	# ---- Right arm: sleeve, rerebrace, gauntlet round the shaft.
	add_limb(arm_r, Vector3(0.47, 1.50, 0), Vector3(0.50, 1.24, 0.03), 0.10, dark)
	add_part(arm_r, cyl(0.12, 0.13, 0.22, 8), plate, Vector3(0.48, 1.38, 0.01))
	add_limb(arm_r, Vector3(0.50, 1.24, 0.03), FIST_R, 0.09, steel, 0.105, steel)
	# ---- The glaive: tower-high dark shaft with steel bands and a butt spike, a steel socket, the glowing rune,
	# the glass-crescent head bulging forward, a top spike, a back hook, a team streamer.
	add_part(arm_r, cyl(0.035, 0.04, 2.26, 8), wood, Vector3(SHAFT_X, 1.21, SHAFT_Z))
	for y: float in [0.62, 1.36, 1.86]:
		add_part(arm_r, cyl(0.048, 0.048, 0.06, 8), steel, Vector3(SHAFT_X, y, SHAFT_Z))
	add_part(arm_r, cyl(0.0, 0.04, 0.16, 6), steel, Vector3(SHAFT_X, 0.03, SHAFT_Z), Vector3(180, 0, 0))
	add_part(arm_r, cyl(0.05, 0.065, 0.20, 8), steel, Vector3(SHAFT_X, 2.18, SHAFT_Z))
	add_part(arm_r, sphere(0.055, 8, 4), glow, Vector3(SHAFT_X, 2.20, SHAFT_Z + 0.06))
	add_part(arm_r, _crescent_mesh(), frost, Vector3(SHAFT_X, HEAD_Y, SHAFT_Z))
	add_crystal(arm_r, Vector3(SHAFT_X, 2.30, SHAFT_Z), Vector3.UP, 0.04, 0.50, frost, 0.55)
	add_crystal(arm_r, Vector3(SHAFT_X, 2.26, SHAFT_Z - 0.03), Vector3(0, 0.35, -1.0), 0.035, 0.22, frost, 0.6)
	add_part(arm_r, box(Vector3(0.04, 0.46, 0.08)), cloth, Vector3(SHAFT_X + 0.05, 1.90, SHAFT_Z - 0.06), Vector3(0, 0, -8))
	# ---- The glass ring (braced / planted): flat, at the feet, hidden at rest.
	_ring = add_part(root, torus(0.82, 0.92, 24), ice(&"ice_frost_glass"), Vector3(0, 0.04, 0.1), Vector3.ZERO,
		Vector3(1.0, 0.3, 1.0), true, "GlassRing")
	_ring.visible = false
	# ---- FX: chips from the cuirass, breath through the visor, shatter.
	add_hit_chips(Vector3(0, 1.30, 0.30), 7)
	add_breath(Vector3(0, 1.92, 0.26), 0.22)
	add_shatter(Vector3(0, 1.05, 0.05), 16, 0.4, 0.12)
	ensure_shadow_blob(0.5, BLOB_TINT)


# ================================================================ meshes (cached, model space)

## Rows of overlapping plates on a flared band (angles from +Z, a0..a1), plates tilted so each row's lower edge flares
## out over the next. y_top = top of the band, h = height. One cached mesh.
static func _lamellar(key: String, y_top: float, h: float, r_top: float, r_bot: float, rows: int, cols: int,
		a0: float, a1: float) -> Mesh:
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	var rh: float = h / float(rows)
	var slope: float = atan2(r_bot - r_top, h)
	for row: int in rows:
		var v: float = (float(row) + 0.5) / float(rows)
		var r: float = lerpf(r_top, r_bot, v) + 0.012 * float(row % 2)
		var y: float = y_top - (float(row) + 0.5) * rh
		var n: int = cols
		var span: float = a1 - a0
		var w: float = span * r / float(n) * 1.1
		var pm := BoxMesh.new()
		pm.size = Vector3(w, rh * 1.35, 0.03)
		for c: int in n:
			var a: float = a0 + span * (float(c) + 0.5 + 0.5 * float(row % 2)) / float(n)
			if span < TAU - 0.01 and (row % 2) == 1 and c == n - 1:
				continue
			var b := Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, slope + 0.10)
			st.append_from(pm, 0, Transform3D(b, Vector3(sin(a) * r, y, cos(a) * r)))
	st.index()
	return _cached(key, st.commit())


## The glass crescent: a moon-shaped blade in the YZ plane bulging forward (+Z) from the shaft, a sharp ridge down the
## middle (flat facets). Origin at the shaft axis at HEAD_Y.
static func _crescent_mesh() -> Mesh:
	const KEY := "sg_crescent2"
	if _mesh_cache.has(KEY):
		return _mesh_cache[KEY]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var n := 12
	var c := Vector3(0, 0, -0.04)
	var rad := 0.36
	var rows: Array[PackedVector3Array] = []
	for i: int in n + 1:
		var u: float = float(i) / float(n)
		var a: float = lerpf(-70.0, 74.0, u) * DEG
		var dirv := Vector3(0, sin(a), cos(a))
		var mid: Vector3 = c + dirv * rad
		var w: float = 0.19 * sin(PI * u) + 0.012
		var th: float = 0.05 * sin(PI * u) + 0.01
		var ring := PackedVector3Array([mid - dirv * w * 0.5, mid + Vector3(th * 0.5, 0, 0) + dirv * w * 0.05,
			mid + dirv * w * 0.5 + dirv * 0.035 * sin(PI * u), mid - Vector3(th * 0.5, 0, 0) + dirv * w * 0.05])
		rows.append(ring)
	for i: int in n:
		for k: int in 4:
			var a0: Vector3 = rows[i][k]
			var a1: Vector3 = rows[i][(k + 1) % 4]
			var b0: Vector3 = rows[i + 1][k]
			var b1: Vector3 = rows[i + 1][(k + 1) % 4]
			for p: Vector3 in [a0, b0, a1, a1, b0, b1]:
				st.add_vertex(p)
	st.generate_normals()
	# make the facets face outward whatever the winding
	var m := st.commit()
	var arr := m.surface_get_arrays(0)
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	for t: int in range(0, verts.size(), 3):
		var cen: Vector3 = (verts[t] + verts[t + 1] + verts[t + 2]) / 3.0
		var mid_c: Vector3 = c + Vector3(0, cen.y - c.y, cen.z - c.z).normalized() * rad
		var o: Vector3 = cen - mid_c
		if norms[t].dot(o) < 0.0:
			var tmp: Vector3 = verts[t + 1]
			verts[t + 1] = verts[t + 2]
			verts[t + 2] = tmp
			for q: int in 3:
				norms[t + q] = -norms[t + q]
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return _cached(KEY, am)


# ================================================================ motion

static func _tk(t: float, k: PackedFloat32Array) -> float:
	var n := k.size()
	if t <= k[0]:
		return k[1]
	if t >= k[n - 2]:
		return k[n - 1]
	var i := 2
	while t >= k[i]:
		i += 2
	var u := (t - k[i - 2]) / (k[i] - k[i - 2])
	u = u * u * (3.0 - 2.0 * u)
	return lerpf(k[i - 1], k[i + 1], u)


func _pose_attack(prev: float, t: float) -> bool:
	if attack_style != &"glaive_cleave":
		return super._pose_attack(prev, t)
	rot(P_ARM_R, Vector3(_tk(t, A_ARM_R) * DEG, 0, _tk(t, A_ARM_RZ) * DEG))
	pos(P_ARM_R, Vector3(0, 0, _tk(t, A_ARM_RZP)))
	rot(P_CHEST, Vector3(_tk(t, A_CHEST_X) * DEG, _tk(t, A_CHEST_Y) * DEG, 0))
	pos(P_ROOT, Vector3(0, 0, _tk(t, A_ROOT_Z)))
	rot(P_ARM_L, Vector3(_tk(t, A_ARM_L) * DEG, 0, 0))
	if _tier == 0:
		rot(P_LEG_L, Vector3(_tk(t, A_LEG_L) * DEG, 0, 0))
		rot(P_LEG_R, Vector3(_tk(t, A_LEG_R) * DEG, 0, 0))
	if prev < STRIKE_T and t >= STRIKE_T:
		_on_action_event(&"release")
	return t < ATTACK_LEN


## Hold the Line / Challenge: hoist the glaive, then plant it with a glass ring flash at the feet.
func _pose_cast(_spell: StringName, t: float) -> float:
	rot(P_ARM_R, Vector3(_tk(t, C_ARM_R) * DEG, 0, 0))
	pos(P_ARM_R, Vector3(0, _tk(t, C_ARM_RY), 0))
	rot(P_ARM_L, Vector3(_tk(t, C_ARM_L) * DEG, 0, 0))
	rot(P_CHEST, Vector3(_tk(t, C_CHEST_X) * DEG, 0, 0))
	pos(P_ROOT, Vector3(0, _tk(t, C_ROOT_Y), 0))
	if not _planted and t >= PLANT_T:
		_planted = true
		_ring_t = 0.0
		if _chips and _tier == 0:
			_chips.restart()
	return CAST_LEN


func _on_action_event(ev: StringName) -> void:
	match ev:
		&"cast_start":
			_planted = false


func _ice_process(dt: float) -> void:
	if _dead:
		if _ring.visible:
			_ring.visible = false
		return
	_brace_w = move_toward(_brace_w, 1.0 if _braced and _action == &"" else 0.0, dt / 0.25)
	# the ring: a flash after the plant (grows, then fades out by hiding), or a faint steady ring while braced
	if _ring_t < 0.6:
		_ring_t += dt
		var k: float = clampf(_ring_t / 0.6, 0.0, 1.0)
		var s: float = lerpf(0.55, 1.25, 1.0 - (1.0 - k) * (1.0 - k))
		_ring.scale = Vector3(s, 0.3, s)
		_ring.visible = true
	elif _brace_w > 0.5:
		_ring.scale = Vector3(1.0, 0.3, 1.0)
		_ring.visible = true
	elif _ring.visible:
		_ring.visible = false
	if _brace_w > 0.0:
		_force_write = true   # keep the full pose path while braced (the idle fast path ignores offsets)
		var w: float = _brace_w
		rot(P_ARM_R, Vector3(18.0 * DEG * w, 0, 4.0 * DEG * w))
		rot(P_ARM_L, Vector3(-38.0 * DEG * w, 0, 8.0 * DEG * w))
		rot(P_CHEST, Vector3(7.0 * DEG * w, -10.0 * DEG * w, 0))
		pos(P_ROOT, Vector3(0, -0.06 * w, 0))
		rot(P_LEG_L, Vector3(-16.0 * DEG * w, 0, 0))
		rot(P_LEG_R, Vector3(12.0 * DEG * w, 0, 0))
	# march: the glaive stays upright, slight forward lean
	if _walk_w > 0.0:
		var sw := sin(TAU * _walk_p)
		rot(P_ARM_R, Vector3(-6.0 * DEG * sw * _walk_w, 0, 0))
		rot(P_CHEST, Vector3(4.0 * DEG * _walk_w, 0, 0))


func _ice_revive() -> void:
	_ring_t = 99.0
	_brace_w = 0.0
	_ring.visible = false


## Fidget: lifts the glaive and knocks its butt on the ground twice, a look to the side.
func _pose_fidget(t: float) -> float:
	var up := _k3(t, 0.0, 0.25, 1.1, 1.4, 1.0, 1.0)
	var tap := 0.0
	if t > 0.25 and t < 1.1:
		tap = absf(sin((t - 0.25) * TAU / 0.42))
	pos(P_ARM_R, Vector3(0, 0.08 * tap * up, 0))
	rot(P_HEAD, Vector3(0, -18.0 * DEG * up, 0))
	rot(P_CHEST, Vector3(0, -6.0 * DEG * up, 0))
	return 1.4
