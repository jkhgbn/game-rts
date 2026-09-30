extends "res://art/units/mounts/ember_boar/ember_boar.gd"
## Pyrehoof Boar: the Pyrehoof Lancer's war boar (stables.md 2, Fire C). The shared 13.V2 Ember Boar (same anatomy, gait,
## charge, fidget, death, eyes, and its bronze barding kept for set_barded: the rank-3 Pyrehoof Warlord look) dressed for
## the line, everything merged into the Ember Boar's own pivots (0 extra draw instances, own type key = own caches):
##  - the "pyrehoof" read: every hoof sits in three ember flame tongues over a bronze fetlock cuff. The embers are a SOFT
##    glow (glow_boost 0.3 x the kit level: under the bloom, so the 40 m glow points stay the mane + the lance head) that
##    flares hot on the charge / snort;
##  - a long quilted team TRAPPER hanging from under the caparison down to the knees on both flanks (fire_cloth, a dark
##    quilting band, a flame-cut fire_cloth_dark hem, a bronze sun roundel) and team CRUPPER DRAPES over both haunches
##    behind the cantle (the rump flames stay free between them): the big team read from the RTS camera;
##  - a light bronze chanfron with a ridge and a bronze peytral with a boss (the heavy barding is the rank-3 look).
## Scene: parts/pyrehoof_boar.tscn (the Ember Boar's pivots and tuning).

const HOOF_SOFT := 0.3       # hoof ember glow_boost at rest (x glow_level): under the bloom level
const HOOF_FLARE := 2.2      # added on the charge / snort flare (x _flare)
## Trapper: model z range (between the thighs and the fore legs, with their walk swing), columns, drop below its top.
const SKIRT_Z0 := -0.24
const SKIRT_Z1 := 0.14
const SKIRT_COLS := 6
const SKIRT_DROP := 0.27
const SKIRT_A := 98.0   # barrel angle of its top edge (deg from the top): just under the caparison drape's hem row

var _hoof_nodes: Array[GeometryInstance3D] = []
var _hoof_w: float = -1.0


func _build_mount() -> void:
	super()
	var body: Node3D = $Root/Mount
	add_sculpt(body, _trapper_sculpt)
	add_sculpt($Root/Mount/Head, _chanfron_sculpt)
	for leg: Node3D in [$Root/Mount/LegFL, $Root/Mount/LegFR, $Root/Mount/LegBL, $Root/Mount/LegBR]:
		var p := model_origin(leg)
		add_sculpt(leg, func(s: Dictionary) -> void: _hoof_fire(s, p))


# ================================================================ trapper, crupper drapes, peytral (body)

## The long team trapper under the caparison drape: per column z, from under the drape's hem (barrel angle SKIRT_A) down
## SKIRT_DROP, flaring out a little; part 0 = the team cloth, 1 = the dark quilting band, 2 = the flame-cut dark hem.
static func _skirt_mesh(sx: float, part: int) -> Mesh:
	var key := "pyrehoof_trapper_%s_%d_v2" % [sx, part]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows: Array = [[], [], [], []]
	var nh := Vector3(sx, -0.05, 0.0).normalized()
	for i: int in SKIRT_COLS + 1:
		var z := lerpf(SKIRT_Z0, SKIRT_Z1, float(i) / float(SKIRT_COLS))
		var e := _bp(z, SKIRT_A * sx, 0.03)
		var top: Vector3 = e[0]
		var tip: bool = i % 2 == 1
		var rnd: float = fposmod(sin(float(i) * 7.31 + sx * 2.7) * 43758.5453, 1.0)
		(rows[0] as Array).append(top)
		(rows[1] as Array).append(top + Vector3(0.03 * sx, -SKIRT_DROP * 0.66, 0))
		(rows[2] as Array).append(top + Vector3(0.04 * sx, -SKIRT_DROP * 0.82, 0))
		(rows[3] as Array).append(top + Vector3(0.05 * sx, -SKIRT_DROP - (0.10 * (0.8 + 0.4 * rnd) if tip else 0.0),
			-0.04 if tip else 0.0))
	var pr: Array = [[0, 1], [1, 2], [2, 3]][part]
	var ra: Array = rows[pr[0]]
	var rb: Array = rows[pr[1]]
	for i: int in SKIRT_COLS:
		var j := i + 1
		var t := 0.016
		var a0: Vector3 = ra[i]
		var a1: Vector3 = ra[j]
		var b0: Vector3 = rb[i]
		var b1: Vector3 = rb[j]
		_emit(st, a0, a1, b1, nh, nh, nh)
		_emit(st, a0, b1, b0, nh, nh, nh)
		_emit(st, a0 - nh * t, b1 - nh * t, a1 - nh * t, -nh, -nh, -nh)
		_emit(st, a0 - nh * t, b0 - nh * t, b1 - nh * t, -nh, -nh, -nh)
	st.index()
	return _cached(key, st.commit())


func _trapper_sculpt(s: Dictionary) -> void:
	var cloth := m("fire_cloth")
	var cdark := m("fire_cloth_dark")
	var bronze := m("fire_bronze")
	var leather := m("fire_leather")
	for sx: float in [-1.0, 1.0]:
		sculpt_add(s, _skirt_mesh(sx, 0), Transform3D.IDENTITY, cloth)
		sculpt_add(s, _skirt_mesh(sx, 1), Transform3D.IDENTITY, cdark)
		sculpt_add(s, _skirt_mesh(sx, 2), Transform3D.IDENTITY, cloth)
		# a bronze sun roundel on the trapper
		var rc := _bp(-0.05, SKIRT_A * sx, 0.03)
		var c: Vector3 = (rc[0] as Vector3) + Vector3(0.028 * sx, -0.10, 0)
		var n := Vector3(sx, -0.05, 0).normalized()
		var fb := frame(c, n, Vector3.UP).basis
		sculpt_add(s, cyl(0.07, 0.07, 0.022, 10), Transform3D(fb, c), bronze)
		sculpt_add(s, cyl(0.035, 0.035, 0.03, 8), Transform3D(fb, c + n * 0.006), cdark)
		# a leather strap tying the trapper to the girth
		sculpt_put(s, box(Vector3(0.02, 0.12, 0.05)), leather, (rc[0] as Vector3) + Vector3(0.02 * sx, 0.02, 0.14))
		# the crupper drape over the haunch behind the cantle (from beside the spine down the flank), flame-cut hem
		# (a band round the rump's vertical axis: 0 deg = forward, 90 = the flank; the spine and its flames stay free)
		var c0: float = 45.0 if sx > 0.0 else -160.0
		var c1: float = 160.0 if sx > 0.0 else -45.0
		sculpt_fringe(s, cloth, fringe_mesh("pyrehoof_crupper_%s_v2" % sx, 0.34, 0.38, 0.41, 0.45, 0.18, c0, c1, 4, 0.11,
			0.02, 0.8), Vector3(0, 1.02, RUMP_C.z))
		sculpt_fringe(s, cdark, fringe_mesh("pyrehoof_crupper_hem_%s_v2" % sx, 0.345, 0.385, 0.35, 0.39, 0.035, c0, c1, 4,
			0.0, 0.024, 0.0), Vector3(0, 1.025, RUMP_C.z))
	# peytral: a bronze breastplate under the neck, a leather rim and a bronze boss
	var cb := Basis(Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0))
	sculpt_add(s, shell_mesh("pyrehoof_peytral_v3", 0.40, 0.38, -66.0, 66.0, 0.0, 0.24, 0.03, 6, 1, 1.04, 0.0),
		Transform3D(cb, Vector3(0, 0.50, 0.58)), bronze)
	sculpt_add(s, shell_mesh("pyrehoof_peytral_rim_v3", 0.412, 0.392, -68.0, 68.0, 0.22, 0.27, 0.035, 6, 1),
		Transform3D(cb, Vector3(0, 0.50, 0.58)), leather)
	sculpt_put(s, sphere(0.06, 8, 4), bronze, Vector3(0, 0.64, 0.97), Vector3.ZERO, Vector3(1.0, 1.0, 0.6))


## A light bronze chanfron down the skull with a ridge (the rank-3 barding has the full one).
func _chanfron_sculpt(s: Dictionary) -> void:
	var bronze := m("fire_bronze")
	var sd := (SK_F - SK_B).normalized()
	var up := Vector3(0, sd.z, -sd.y)
	var sf := frame(SK_B, sd, Vector3.UP)
	var hb := Basis(-sf.basis.x, sf.basis.z, sf.basis.y)
	sculpt_add(s, shell_mesh("pyrehoof_chanfron_v1", 0.33, 0.378, -34.0, 34.0, 0.14, 0.62, 0.025, 4, 2, 0.6, 0.02),
		Transform3D(hb, SK_B), bronze)
	var rp := PackedVector3Array([SK_B + sd * 0.16 + up * 0.38, SK_B + sd * 0.40 + up * 0.31, SK_B + sd * 0.60 + up * 0.255])
	sculpt_add(s, tube_mesh("pyrehoof_chanfron_ridge_v1", rp, PackedFloat32Array([0.03, 0.024, 0.016]), 5, true, 0.6),
		Transform3D.IDENTITY, bronze)


# ================================================================ burning hooves (legs)

## A bronze fetlock cuff and three ember tongues round the hoof, leaning back (the gallop wind).
func _hoof_fire(s: Dictionary, p: Vector3) -> void:
	var bronze := m("fire_bronze")
	var flame := m("fire_flame")
	var front: bool = p.z > 0.0
	var cz: float = 0.05 if front else 0.0
	sculpt_add(s, cyl(0.105, 0.096, 0.05, 8, false), Transform3D(Basis.IDENTITY, Vector3(p.x, 0.13, p.z + cz)), bronze)
	for k: int in 3:
		var a := TAU * float(k) / 3.0 + (0.5 if front else 1.2)
		var out := Vector3(sin(a), 0.0, cos(a))
		var root := Vector3(p.x, 0.06, p.z + cz + 0.02) + out * 0.075
		var dir := (Vector3.UP + out * 0.4 + Vector3(0, 0, -0.5)).normalized()
		var f := frame(root, dir, out)
		var h: float = 0.19 if k == 0 else 0.14
		sculpt_add(s, cyl(0.0, 1.0, 1.0, 5), Transform3D(Basis(f.basis.x * 0.05, f.basis.y * h, f.basis.z * 0.035),
			root + f.basis.y * h * 0.5), flame)


# ================================================================ motion

func _mount_ready() -> void:
	super()
	_hoof_nodes.clear()
	for i: int in [P_LEG_FL, P_LEG_FR, P_LEG_BL, P_LEG_BR]:
		var mi: MeshInstance3D = _merged_nodes.get(i)
		if mi:
			_glow_nodes.erase(mi)   # the hoof embers are driven here (soft), not at the kit's full level
			mi.set_meta(&"own_glow", true)
			_hoof_nodes.append(mi)
	_hoof_w = -1.0
	_write_hooves()


## set_barded swaps the fore legs' merged mesh (knee cops): the kit re-adds them as glow nodes; take them back.
func set_barded(on: bool) -> void:
	super(on)
	for gi: GeometryInstance3D in _hoof_nodes:
		_glow_nodes.erase(gi)
	_hoof_w = -1.0
	_write_hooves()


func _mount_process(dt: float) -> void:
	super(dt)
	_write_hooves()


func _mount_revive() -> void:
	super()
	_hoof_w = -1.0
	_write_hooves()


func _write_hooves() -> void:
	var g: float = 0.0 if _glows_off else snappedf(glow_level() * (HOOF_SOFT + HOOF_FLARE * _flare), 0.05)
	if g == _hoof_w:
		return
	_hoof_w = g
	for gi: GeometryInstance3D in _hoof_nodes:
		gi.set_instance_shader_parameter(&"glow_boost", g)
