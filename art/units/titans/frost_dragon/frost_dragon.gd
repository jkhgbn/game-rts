class_name FrostDragonModel
extends CinderDragonModel
## The Frost Dragon, Ice's second tier-3 titan (titans-2.md 3 / 11 row 13c.V1). Built on the Cinder Dragon: the rig,
## the flight / breath / hit / death animation and every hook come unchanged from FlyerModel (flyer_model.gd), the
## mesh helpers (_loft, _horn, _blob, _grid...) and the four leg meshes from CinderDragonModel (the legs are reused
## as they are, with this folder's materials as surface overrides). Nothing in flyer_model.gd or cinder_dragon.gd changed.
## Hooks (FlyerModel): set_moving(speed) · set_turning(rate_deg_per_s) · play_attack() (= the Rime Breath: breath_released
## at 0.35 s) · play_hit() · play_death() (+ death_finished, crashed(at)) · set_team_color(c) (membrane tint) ·
## set_status(id, on) · revive() · get_breath_origin(); kit no-ops play_cast, play_level_up, set_veterancy...
## Look (the blue dragon next to the red one): pale-blue scales with a frost-white belly and a rime crust where the
## Cinder has lava seams, a broad horned head with TWO LONG SWEPT-BACK ICE HORNS (the read) and a frill of ice shards on
## each cheek, a row of glowing ice spines from the nape down the back to the tail, an ice-shard star at the tail tip,
## a compact deep-chested body, 7.5 m wings with frosted translucent membranes (rime feathering in from the trailing
## edge) that take the kingdom colour. Cold glow only (emission, 0 lights), 4 glow points: eyes + nostrils, the throat
## (palate, tongue, lip line), the spine row, the tail shard. It flares up the throat when it breathes and dies out at
## the crash.
## Budget: 16 pivot meshes + ground blob = 17 meshes, 19 draw instances with the 2 particle systems (frost motes off
## the tail shard, looping, stopped beyond 45 m; ice-shatter burst at the crash, one shot), 0 lights, 5 materials
## (this folder) + the kit blob. Shadows: body, 4 wing parts, necks, head, tail 1-2 (as the Cinder).

const FROST_MAT_PATH := "res://art/units/titans/frost_dragon/frost_"

# ---- anatomy, model space (feet origin, body centre at BAKE_HEIGHT 4.0), right side (x > 0); the left mirrors x.
# The neck, head and leg pivots are the Cinder Dragon's (same S-neck and animation); body and tail are shorter and
# the wing is longer (membrane span 7.5 m).
const F_SHOULDER := Vector3(0.42, 4.38, 0.46)
const F_ELBOW := Vector3(1.38, 4.58, -0.10)
const F_WRIST := Vector3(2.26, 4.76, 0.40)
const F_HIP_ATTACH := Vector3(0.36, 4.08, -1.00)
const F_FINGER_T := Vector3(1.36, 4.30, -1.90)
const F_FINGER_1 := Vector3(3.75, 5.06, -0.46)
const F_FINGER_2 := Vector3(3.36, 4.82, -1.50)
const F_FINGER_3 := Vector3(2.50, 4.54, -2.10)
const F_MOUTH := Vector3(0.0, 4.87, 3.18)
const F_HEAD_PIVOT := Vector3(0.0, 5.02, 2.18)
const F_HEAD_SCALE := 1.25
const F_TAIL_TIP := Vector3(0.0, 3.75, -3.56)

static var _fmats: Dictionary = {}
static var _fmeshes: Dictionary = {}

var _tip_fx: GPUParticles3D
var _shatter_fx: GPUParticles3D


static func _fmat(nm: String) -> Material:
	if not _fmats.has(nm):
		_fmats[nm] = load(FROST_MAT_PATH + nm + ".tres")
	return _fmats[nm]


# ================================================================ parts

func _build_parts() -> void:
	for side: int in 2:
		var sx := -1.0 if side == 0 else 1.0
		wing_axis[side] = (_mx(F_HIP_ATTACH, sx) - _mx(F_SHOULDER, sx)).normalized()
		hand_axis[side] = (_mx(F_FINGER_T, sx) - _mx(F_WRIST, sx)).normalized()
	add_pivot_mesh(P_BODY, _f_body_mesh(), true, "BodyMesh")
	add_pivot_mesh(P_NECK1, _f_neck_mesh(1), true, "Neck1Mesh")
	add_pivot_mesh(P_NECK2, _f_neck_mesh(2), true, "Neck2Mesh")
	add_pivot_mesh(P_HEAD, _f_head_mesh(), true, "HeadMesh")
	add_pivot_mesh(P_JAW, _f_jaw_mesh(), false, "JawMesh")
	add_pivot_mesh(P_WING_L, _f_wing_arm_mesh(-1.0), true, "WingLMesh")
	add_pivot_mesh(P_WING_L2, _f_wing_hand_mesh(-1.0), true, "WingL2Mesh")
	add_pivot_mesh(P_WING_R, _f_wing_arm_mesh(1.0), true, "WingRMesh")
	add_pivot_mesh(P_WING_R2, _f_wing_hand_mesh(1.0), true, "WingR2Mesh")
	add_pivot_mesh(P_TAIL1, _f_tail_mesh(1), true, "Tail1Mesh")
	add_pivot_mesh(P_TAIL2, _f_tail_mesh(2), true, "Tail2Mesh")
	add_pivot_mesh(P_TAIL3, _f_tail_mesh(3), false, "Tail3Mesh")
	# The legs are the Cinder Dragon's meshes (shared, cached there) with this folder's materials.
	var legs: Array = [[P_LEG_FL, _front_leg_mesh(-1.0), "LegFLMesh"], [P_LEG_FR, _front_leg_mesh(1.0), "LegFRMesh"],
		[P_LEG_BL, _hind_leg_mesh(-1.0), "LegBLMesh"], [P_LEG_BR, _hind_leg_mesh(1.0), "LegBRMesh"]]
	for l: Array in legs:
		var mi := add_pivot_mesh(int(l[0]), l[1] as Mesh, false, String(l[2]))
		if mi:
			mi.set_surface_override_material(0, _fmat("scale"))
			mi.set_surface_override_material(1, _fmat("horn"))
	var mouth := Node3D.new()
	mouth.name = "Mouth"
	add_pivot_node(P_HEAD, mouth, F_MOUTH)
	_mouth = mouth
	# Frost motes shed by the tail shard (world space: they trail behind in flight). Loop fx stop beyond 45 m.
	_tip_fx = CharacterModel.make_motes(Color(0.78, 0.94, 1.0), 10, 1.3, 0.3, 0.35, 0.15)
	_tip_fx.name = "TailFrost"
	_tip_fx.visibility_aabb = AABB(Vector3(-3.0, -2.0, -3.0), Vector3(6.0, 5.0, 6.0))
	add_pivot_node(P_TAIL3, _tip_fx, F_TAIL_TIP + Vector3(0.0, 0.0, -0.45))
	# The crash: a one-shot burst of ice shards from the body (the frost_crash VFX of 13c.V2 adds the big shatter).
	_shatter_fx = CharacterModel.make_motes(Color(0.85, 0.96, 1.0), 28, 1.1, 1.3, 3.2, 0.26, false, true)
	_shatter_fx.name = "CrashShards"
	_shatter_fx.visibility_aabb = AABB(Vector3(-4.0, -3.0, -4.0), Vector3(8.0, 8.0, 8.0))
	add_pivot_node(P_BODY, _shatter_fx, Vector3(0.0, BAKE_HEIGHT, 0.0))
	ensure_shadow_blob(Vector2(3.4, 3.7), Color(0.03, 0.05, 0.08, 0.42))


func _after_ready() -> void:
	_tip_fx.emitting = _tier == 0


func _on_revive() -> void:
	if _tip_fx:
		_tip_fx.emitting = _tier == 0


func _on_action_event(ev: StringName) -> void:
	if ev == &"crash" and _tip_fx:
		_tip_fx.emitting = false


# ================================================================ builders (static, cached per game)

static func _fbake(key: String, groups: Array) -> ArrayMesh:
	if _fmeshes.has(key):
		return _fmeshes[key]
	var am := ArrayMesh.new()
	for g: Array in groups:
		var s: CinderDragonModel.Surf = g[0]
		if s.v.is_empty():
			continue
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = s.v
		arr[Mesh.ARRAY_NORMAL] = s.n
		arr[Mesh.ARRAY_TEX_UV] = s.uv
		arr[Mesh.ARRAY_COLOR] = s.c
		arr[Mesh.ARRAY_INDEX] = s.i
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		am.surface_set_material(am.get_surface_count() - 1, _fmat(String(g[1])))
	_fmeshes[key] = am
	return am


static func _new_surf() -> CinderDragonModel.Surf:
	return CinderDragonModel.Surf.new()


## A faceted ice crystal from `base` along `dir`: a prism (radius r) that sharpens to a point over its outer half.
## COLOR r = glow (frost_ice.gdshader), g = 0 base -> 1 tip. flat < 1 flattens it sideways.
static func _shard(s: CinderDragonModel.Surf, base: Vector3, dir: Vector3, h: float, r: float, glow: float,
		sides: int = 5, flat: float = 1.0) -> void:
	var d := dir.normalized()
	var pts: Array[Vector3] = [base - d * 0.05, base + d * (h * 0.5), base + d * h]
	var prof := func(v: float) -> Vector4:
		var k := 1.0 - 0.14 * v if v < 0.5 else lerpf(0.93, 0.0, (v - 0.5) / 0.5)
		var rr := r * k + 0.003
		return Vector4(rr * flat, rr, rr, 0.0)
	var col := func(_ca: float, v: float) -> Color:
		return Color(glow, v, 0.0, 0.0)
	_loft(s, pts, prof, col, sides, 4, Vector3.FORWARD if absf(d.y) > 0.8 else Vector3.UP)


## Ice spines along a loft's top at spline params vs (heights hs), leaning back by `tilt` degrees; every spine glows.
static func _ice_spine_row(s: CinderDragonModel.Surf, pts: Array[Vector3], prof: Callable, vs: Array, hs: Array,
		r: float, tilt: float = 34.0) -> void:
	var t := tilt * DEG
	var dir := Vector3(0.0, cos(t), -sin(t))
	for k: int in vs.size():
		var v: float = vs[k]
		var tn := (_cr(pts, minf(v + 0.01, 1.0)) - _cr(pts, maxf(v - 0.01, 0.0))).normalized()
		var x := Vector3.UP.cross(tn).normalized()
		var up := tn.cross(x).normalized()
		if up.y < 0.0:
			up = -up
		var pr: Vector4 = prof.call(v)
		var base := _cr(pts, v) + up * (pr.y + pr.w - 0.06)
		var h: float = hs[k]
		_shard(s, base, dir, h, r * (0.6 + 0.4 * h / 0.5), 1.0, 5, 0.7)


# ================================================================ meshes

## Body: compact and deep-chested (shorter than the Cinder's, wider chest), shoulder bulges at the wing roots,
## thighs; 7 glowing ice spines down the back with small side crystals over the shoulders.
static func _f_body_mesh() -> ArrayMesh:
	if _fmeshes.has("body"):
		return _fmeshes["body"]
	var sc := _new_surf()
	var ic := _new_surf()
	var pts: Array[Vector3] = [Vector3(0, 4.44, 1.30), Vector3(0, 4.27, 0.88), Vector3(0, 4.12, 0.32),
		Vector3(0, 4.03, -0.30), Vector3(0, 3.99, -0.88), Vector3(0, 3.97, -1.26), Vector3(0, 3.96, -1.46)]
	var tab := [[0.0, 0.42, 0.38, 0.42, 0.0], [0.15, 0.62, 0.50, 0.62, 0.06], [0.34, 0.71, 0.48, 0.80, 0.08],
		[0.58, 0.57, 0.42, 0.58, 0.07], [0.80, 0.54, 0.42, 0.47, 0.06], [1.0, 0.36, 0.33, 0.33, 0.03]]
	var prof := func(v: float) -> Vector4:
		return _table(tab, v)
	_loft(sc, pts, prof, _scaled(1.0), 24, 24)
	for sx: float in [-1.0, 1.0]:
		_blob(sc, Vector3(0.42 * sx, 4.31, 0.42), Vector3(0.27, 0.26, 0.38), Color(0.9, 0.0, 0.0, 0.0),
			Basis(Vector3.FORWARD, 0.25 * sx), 0.04)
		_blob(sc, Vector3(0.34 * sx, 3.80, -0.92), Vector3(0.23, 0.28, 0.33), Color(0.7, 0.25, 0.0, 0.0),
			Basis.IDENTITY, 0.04)
		# rime crystals growing over each shoulder (lean out and back)
		_shard(ic, Vector3(0.30 * sx, 4.62, 0.62), Vector3(0.55 * sx, 0.75, -0.45), 0.34, 0.06, 0.6, 5, 0.8)
		_shard(ic, Vector3(0.36 * sx, 4.55, 0.30), Vector3(0.65 * sx, 0.6, -0.5), 0.26, 0.05, 0.6, 5, 0.8)
	_ice_spine_row(ic, pts, prof, [0.07, 0.2, 0.33, 0.46, 0.6, 0.74, 0.88], [0.40, 0.52, 0.58, 0.52, 0.44, 0.36, 0.28],
		0.10)
	return _fbake("body", [[sc, "scale"], [ic, "ice"]])


static func _f_neck_mesh(seg: int) -> ArrayMesh:
	var key := "neck%d" % seg
	if _fmeshes.has(key):
		return _fmeshes[key]
	var sc := _new_surf()
	var ic := _new_surf()
	var pts: Array[Vector3]
	var tab: Array
	if seg == 1:
		pts = [Vector3(0, 4.16, 0.72), Vector3(0, 4.32, 1.14), Vector3(0, 4.52, 1.45), Vector3(0, 4.72, 1.74)]
		tab = [[0.0, 0.49, 0.43, 0.49, 0.05], [0.5, 0.41, 0.36, 0.42, 0.04], [1.0, 0.33, 0.30, 0.34, 0.03]]
	else:
		pts = [Vector3(0, 4.55, 1.52), Vector3(0, 4.80, 1.84), Vector3(0, 4.98, 2.10), Vector3(0, 5.06, 2.30)]
		tab = [[0.0, 0.34, 0.31, 0.35, 0.03], [0.6, 0.29, 0.27, 0.30, 0.03], [1.0, 0.26, 0.24, 0.25, 0.02]]
	var prof := func(v: float) -> Vector4:
		return _table(tab, v)
	_loft(sc, pts, prof, _scaled(0.95), 18, 10)
	if seg == 1:
		_ice_spine_row(ic, pts, prof, [0.3, 0.62, 0.92], [0.30, 0.32, 0.30], 0.08, 38.0)
	else:
		_ice_spine_row(ic, pts, prof, [0.25, 0.6], [0.26, 0.22], 0.07, 42.0)
	return _fbake(key, [[sc, "scale"], [ic, "ice"]])


## Head (skull + upper jaw): broader skull and a blunter snout than the Cinder's, heavy brows, glowing eyes and
## nostrils, a cold lip line, upper teeth and fangs, the glowing palate, TWO LONG SWEPT-BACK ICE HORNS and a frill of
## three ice shards on each cheek.
static func _f_head_mesh() -> ArrayMesh:
	if _fmeshes.has("head"):
		return _fmeshes["head"]
	var sc := _new_surf()
	var hn := _new_surf()
	var ic := _new_surf()
	var gl := _new_surf()
	var pts: Array[Vector3] = [Vector3(0, 5.07, 2.00), Vector3(0, 5.09, 2.25), Vector3(0, 5.06, 2.53),
		Vector3(0, 5.01, 2.80), Vector3(0, 4.975, 3.03)]
	var tab := [[0.0, 0.18, 0.14, 0.12, 0.0], [0.12, 0.27, 0.20, 0.15, 0.02], [0.30, 0.29, 0.21, 0.155, 0.02],
		[0.50, 0.245, 0.17, 0.13, 0.015], [0.74, 0.18, 0.13, 0.108, 0.01], [0.93, 0.14, 0.105, 0.092, 0.0],
		[1.0, 0.04, 0.035, 0.035, 0.0]]
	var prof := func(v: float) -> Vector4:
		return _table(tab, v)
	var col := func(ca: float, v: float) -> Color:
		var lip := exp(-pow((ca + 0.93) / 0.09, 2.0)) * smoothstep(0.15, 0.3, v) * (1.0 - smoothstep(0.9, 1.0, v))
		return Color(0.6, smoothstep(-0.55, -0.85, ca) * 0.85, 1.0, 0.55 * lip)
	_loft(sc, pts, prof, col, 22, 16)
	for sx: float in [-1.0, 1.0]:
		# heavy brow ridge (stern slant) and a cheek plate
		_blob(sc, Vector3(0.175 * sx, 5.195, 2.48), Vector3(0.11, 0.07, 0.20), Color(0.6, 0.0, 0.0, 0.0),
			Basis(Vector3.FORWARD, -0.30 * sx) * Basis(Vector3.RIGHT, 0.12))
		_blob(sc, Vector3(0.25 * sx, 5.02, 2.32), Vector3(0.08, 0.11, 0.18), Color(0.5, 0.25, 0.0, 0.0))
		# eyes and nostrils (cold glow)
		_blob(gl, Vector3(0.222 * sx, 5.11, 2.575), Vector3(0.048, 0.036, 0.10), Color.WHITE,
			Basis(Vector3.UP, 0.35 * sx) * Basis(Vector3.FORWARD, -0.25 * sx), 0.0, 8, 4)
		_blob(gl, Vector3(0.07 * sx, 5.03, 2.96), Vector3(0.034, 0.028, 0.038), Color.WHITE, Basis.IDENTITY, 0.0, 6, 3)
		# THE read: two long ice horns sweeping back, out and up from behind the brows (hexagonal crystal)
		_horn(ic, [Vector3(0.13 * sx, 5.15, 2.30), Vector3(0.26 * sx, 5.32, 2.05), Vector3(0.38 * sx, 5.49, 1.80),
			Vector3(0.48 * sx, 5.66, 1.52), Vector3(0.54 * sx, 5.80, 1.24), Vector3(0.55 * sx, 5.90, 1.00)],
			0.13, 0.012, 0.35, 6, 11)
		# the cheek frill: three ice shards fanning back from the jaw hinge
		var ck := Vector3(0.26 * sx, 5.00, 2.26)
		_shard(ic, ck, Vector3(0.55 * sx, 0.28, -0.80), 0.40, 0.05, 0.25, 5, 0.7)
		_shard(ic, ck + Vector3(0.0, -0.06, 0.04), Vector3(0.62 * sx, -0.08, -0.76), 0.34, 0.045, 0.25, 5, 0.7)
		_shard(ic, ck + Vector3(-0.03 * sx, 0.07, -0.02), Vector3(0.40 * sx, 0.62, -0.68), 0.28, 0.04, 0.25, 5, 0.7)
		# upper teeth along the lip, a big fang at the front
		for k: int in 5:
			var v: float = 0.34 + 0.125 * float(k)
			var c := _cr(pts, v)
			var pr: Vector4 = prof.call(v)
			var base := c + Vector3(0.62 * pr.x * sx, -0.78 * pr.z, 0.0)
			var ln := 0.07 if k < 4 else 0.13
			_horn(hn, [base + Vector3(0, 0.02, 0), base + Vector3(0, -ln, 0.015)], 0.028 if k < 4 else 0.04, 0.004,
				0.0, 5, 2)
	# the glowing palate (seen when the jaw opens)
	_blob(gl, Vector3(0.0, 4.945, 2.60), Vector3(0.14, 0.022, 0.29), Color.WHITE, Basis.IDENTITY, 0.0, 8, 4)
	for s: CinderDragonModel.Surf in [sc, hn, ic, gl]:
		_scale_surf(s, F_HEAD_PIVOT, F_HEAD_SCALE)
	return _fbake("head", [[sc, "scale"], [hn, "horn"], [ic, "ice"], [gl, "glow"]])


## Lower jaw: glowing tongue / throat, lower teeth, three ice shards under the chin.
static func _f_jaw_mesh() -> ArrayMesh:
	if _fmeshes.has("jaw"):
		return _fmeshes["jaw"]
	var sc := _new_surf()
	var hn := _new_surf()
	var ic := _new_surf()
	var gl := _new_surf()
	var pts: Array[Vector3] = [Vector3(0, 4.905, 2.12), Vector3(0, 4.875, 2.40), Vector3(0, 4.86, 2.68),
		Vector3(0, 4.865, 2.96)]
	var tab := [[0.0, 0.18, 0.035, 0.105, 0.0], [0.4, 0.20, 0.04, 0.11, 0.0], [0.8, 0.14, 0.035, 0.08, 0.0],
		[1.0, 0.045, 0.015, 0.03, 0.0]]
	var prof := func(v: float) -> Vector4:
		return _table(tab, v)
	var col := func(ca: float, _v: float) -> Color:
		return Color(0.5, smoothstep(-0.2, -0.7, ca), 1.0, 0.0)
	_loft(sc, pts, prof, col, 16, 10)
	_blob(gl, Vector3(0.0, 4.893, 2.53), Vector3(0.12, 0.02, 0.28), Color.WHITE, Basis.IDENTITY, 0.0, 8, 4)
	for sx: float in [-1.0, 1.0]:
		for k: int in 4:
			var v: float = 0.3 + 0.16 * float(k)
			var c := _cr(pts, v)
			var pr: Vector4 = prof.call(v)
			var base := c + Vector3(0.66 * pr.x * sx, 0.6 * pr.y, 0.0)
			var ln := 0.06 if k < 3 else 0.10
			_horn(hn, [base + Vector3(0, -0.02, 0), base + Vector3(0, ln, 0.01)], 0.025 if k < 3 else 0.035, 0.004,
				0.0, 5, 2)
		_shard(ic, Vector3(0.10 * sx, 4.82, 2.58), Vector3(0.3 * sx, -0.75, -0.6), 0.24, 0.04, 0.2, 5, 0.8)
	_shard(ic, Vector3(0.0, 4.81, 2.74), Vector3(0.0, -0.8, -0.6), 0.30, 0.05, 0.2, 5, 0.8)
	for s: CinderDragonModel.Surf in [sc, hn, ic, gl]:
		_scale_surf(s, F_HEAD_PIVOT, F_HEAD_SCALE)
	return _fbake("jaw", [[sc, "scale"], [hn, "horn"], [ic, "ice"], [gl, "glow"]])


## Arm segment of a wing (the WingX pivot, hinged on the flank): humerus + forearm with an ice spike at the elbow,
## the last finger (wrist -> T, the hand hinge), and the inner membrane (shoulder -> wrist leading edge, hip -> T).
## The Cinder's builder with the longer Frost anatomy; the bones carry a rime line instead of a lava line.
static func _f_wing_arm_mesh(sx: float) -> ArrayMesh:
	var key := "wing_arm%d" % int(sx)
	if _fmeshes.has(key):
		return _fmeshes[key]
	var sc := _new_surf()
	var hn := _new_surf()
	var ic := _new_surf()
	var mb := _new_surf()
	var s := _mx(F_SHOULDER, sx)
	var e := _mx(F_ELBOW, sx)
	var w := _mx(F_WRIST, sx)
	var h := _mx(F_HIP_ATTACH, sx)
	var t := _mx(F_FINGER_T, sx)
	var bone := func(ca: float, _v: float) -> Color:
		return Color(0.8, _belly(ca) * 0.6, 1.0, 0.0)
	_loft(sc, [s + Vector3(-0.06 * sx, 0.0, 0.03), e.lerp(s, 0.5) + Vector3(0, 0.05, 0.02), e], _round(0.17, 0.115),
		bone, 8, 7)
	_loft(sc, [e, e.lerp(w, 0.5) + Vector3(0, 0.03, 0.03), w], _round(0.115, 0.09), bone, 8, 7)
	_loft(sc, [w, w.lerp(t, 0.5) + Vector3(0.05 * sx, 0.02, 0.0), t], _round(0.078, 0.036), bone, 6, 8)
	_blob(sc, e, Vector3(0.125, 0.115, 0.125), Color(0.8, 0.0, 0.0, 0.0))
	_blob(sc, s, Vector3(0.19, 0.17, 0.21), Color(0.8, 0.0, 0.0, 0.0))
	_shard(ic, e + Vector3(0.02 * sx, 0.04, -0.05), Vector3(0.25 * sx, 0.3, -1.0), 0.44, 0.06, 0.3, 5, 0.8)
	_horn(hn, [t + Vector3(0, 0, 0.03), t + (t - w).normalized() * 0.14 + Vector3(0, -0.03, 0)], 0.03, 0.006, 0.2, 5, 3)
	var lead := func(u: float) -> Vector3:
		return s.lerp(w, u) + Vector3(0.0, 0.04 * sin(PI * u), 0.10 * sin(PI * u))
	var trail := func(u: float) -> Vector3:
		var b := h.lerp(t, u)
		return b + ((lead.call(u) as Vector3) - b) * 0.24 * sin(PI * u)
	var fn := func(u: float, v: float) -> Vector3:
		var p: Vector3 = (lead.call(u) as Vector3).lerp(trail.call(u) as Vector3, v)
		return p + Vector3(0.0, -0.10 * sin(PI * u) * sin(PI * v), 0.0)
	var ctr := func(u: float, v: float) -> Vector3:
		return (fn.call(u, v) as Vector3) - Vector3.UP
	var col := func(u: float, v: float) -> Color:
		var mid := clampf(minf(minf(u, 1.0 - u) * 5.0, v * 4.0), 0.0, 1.0)
		return Color(mid, v, smoothstep(0.7, 1.0, v) * smoothstep(0.02, 0.12, u) * smoothstep(0.02, 0.1, 1.0 - u), 0.0)
	var span := s.distance_to(w)
	var chord := s.distance_to(h)
	var uvf := func(u: float, v: float) -> Vector2:
		return Vector2(u * span, v * chord)
	_grid(mb, fn, ctr, col, uvf, 12, 8)
	return _fbake(key, [[sc, "scale"], [hn, "horn"], [ic, "ice"], [mb, "membrane"]])


## Hand segment of a wing (WingX2 pivot at the wrist, hinged on the last finger): three finger bones with tip claws,
## the hooked thumb claw, three frosted membrane panels. The panel next to the last finger shares its edge exactly
## with the arm panel (wrist -> T).
static func _f_wing_hand_mesh(sx: float) -> ArrayMesh:
	var key := "wing_hand%d" % int(sx)
	if _fmeshes.has(key):
		return _fmeshes[key]
	var sc := _new_surf()
	var hn := _new_surf()
	var mb := _new_surf()
	var w := _mx(F_WRIST, sx)
	var tips: Array[Vector3] = [_mx(F_FINGER_1, sx), _mx(F_FINGER_2, sx), _mx(F_FINGER_3, sx), _mx(F_FINGER_T, sx)]
	var radii: Array[float] = [0.088, 0.075, 0.068]
	var bone := func(ca: float, _v: float) -> Color:
		return Color(0.8, _belly(ca) * 0.6, 1.0, 0.0)
	for k: int in 3:
		var tip := tips[k]
		var mid := w.lerp(tip, 0.5) + Vector3(0.0, 0.05, 0.0) + (tips[k + 1] - tip).normalized() * 0.06
		_loft(sc, [w, mid, tip], _round(radii[k], 0.03), bone, 6, 9)
		var out := (tip - mid).normalized()
		_horn(hn, [tip - out * 0.04, tip + out * 0.16 + Vector3(0, 0.02, 0), tip + out * 0.26 + Vector3(0, -0.04, -0.06)],
			0.04, 0.006, 0.15, 5, 4)
	_blob(sc, w, Vector3(0.115, 0.105, 0.125), Color(0.8, 0.0, 0.0, 0.0))
	_horn(hn, [w + Vector3(0.02 * sx, 0.03, 0.04), w + Vector3(0.06 * sx, 0.10, 0.24), w + Vector3(0.08 * sx, 0.10, 0.42),
		w + Vector3(0.06 * sx, 0.02, 0.52)], 0.075, 0.008, 0.25, 7, 7)
	var sags: Array[float] = [0.20, 0.23, 0.20]
	for k: int in 3:
		var a := tips[k]
		var b := tips[k + 1]
		var sag: float = sags[k]
		var edge := func(u: float) -> Vector3:
			var q := a.lerp(b, u)
			return q + (w - q) * sag * sin(PI * u)
		var la := a.distance_to(w)
		var fn := func(u: float, v: float) -> Vector3:
			var p: Vector3 = w + ((edge.call(u) as Vector3) - w) * v
			return p + Vector3(0.0, -0.05 * la * sin(PI * u) * sin(PI * v), 0.0)
		var ctr := func(u: float, v: float) -> Vector3:
			return (fn.call(u, v) as Vector3) - Vector3.UP
		var col := func(u: float, v: float) -> Color:
			var mid := clampf(minf(u, 1.0 - u) * 5.0, 0.0, 1.0) * smoothstep(0.0, 0.25, v)
			return Color(mid, v, smoothstep(0.7, 1.0, v) * smoothstep(0.02, 0.1, minf(u, 1.0 - u)), 0.0)
		var ab := a.distance_to(b)
		var uvf := func(u: float, v: float) -> Vector2:
			return Vector2(u * ab, v * la)
		_grid(mb, fn, ctr, col, uvf, 10, 9)
	return _fbake(key, [[sc, "scale"], [hn, "horn"], [mb, "membrane"]])


## Tail segments (shorter than the Cinder's), glowing ice spines along the top; the last ends in the ice-shard star:
## a long central shard, two side shards and a small upper / lower pair, all glowing from the core.
static func _f_tail_mesh(seg: int) -> ArrayMesh:
	var key := "tail%d" % seg
	if _fmeshes.has(key):
		return _fmeshes[key]
	var sc := _new_surf()
	var ic := _new_surf()
	var pts: Array[Vector3]
	var tab: Array
	var sv: Array
	var sh: Array
	match seg:
		1:
			pts = [Vector3(0, 3.98, -1.12), Vector3(0, 3.94, -1.64), Vector3(0, 3.88, -2.24)]
			tab = [[0.0, 0.38, 0.34, 0.34, 0.03], [1.0, 0.24, 0.22, 0.22, 0.02]]
			sv = [0.2, 0.55, 0.88]
			sh = [0.26, 0.24, 0.21]
		2:
			pts = [Vector3(0, 3.88, -2.04), Vector3(0, 3.83, -2.56), Vector3(0, 3.79, -3.08)]
			tab = [[0.0, 0.23, 0.21, 0.21, 0.02], [1.0, 0.14, 0.13, 0.13, 0.01]]
			sv = [0.25, 0.6, 0.92]
			sh = [0.20, 0.17, 0.15]
		_:
			pts = [Vector3(0, 3.79, -2.92), Vector3(0, 3.77, -3.26), Vector3(0, 3.75, -3.60)]
			tab = [[0.0, 0.145, 0.135, 0.135, 0.01], [0.85, 0.085, 0.08, 0.08, 0.0], [1.0, 0.06, 0.06, 0.06, 0.0]]
			sv = [0.35]
			sh = [0.13]
	var prof := func(v: float) -> Vector4:
		return _table(tab, v)
	_loft(sc, pts, prof, _scaled(0.9), 16, 10)
	_ice_spine_row(ic, pts, prof, sv, sh, 0.07, 40.0)
	if seg == 3:
		var t := F_TAIL_TIP
		_shard(ic, t + Vector3(0, 0, 0.14), Vector3(0.0, 0.02, -1.0), 0.98, 0.13, 1.0, 5)
		for sx: float in [-1.0, 1.0]:
			_shard(ic, t + Vector3(0.0, 0.0, 0.10), Vector3(0.62 * sx, 0.05, -0.78), 0.60, 0.095, 1.0, 5, 0.8)
		_shard(ic, t + Vector3(0.0, 0.02, 0.08), Vector3(0.0, 0.76, -0.65), 0.44, 0.08, 1.0, 5, 0.8)
		_shard(ic, t + Vector3(0.0, -0.02, 0.08), Vector3(0.0, -0.62, -0.78), 0.34, 0.07, 1.0, 5, 0.8)
	return _fbake(key, [[sc, "scale"], [ic, "ice"]])
