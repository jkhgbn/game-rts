class_name UnitFireGunVfx
extends Node3D
## Gunpowder effects of the Cinderlock Musketeer (task 13b.V6, docs/design/tier3-extras.md 4.1-4.2, 12, 13). An effect
## FAMILY of UnitVfx (art/vfx/unit_vfx.gd loads this file and forwards the ids below); callers never reach it directly:
##   var vfx := get_tree().get_first_node_in_group(&"unit_vfx")
##   if vfx: vfx.play(&"musket_shot", model.get_muzzle_xf(), victim)
## It can also live on its own (a test level). Draw-only: it never touches gameplay.
##
## Ids and their arguments (`target` may always be null):
##   musket_shot    at = the muzzle: a Transform3D (CinderlockModel.get_muzzle_xf(): origin = the bell mouth,
##                  basis.z = out of the muzzle), OR the shooter / its model (a Node3D: its get_muzzle_xf() is used,
##                  through Unit.get_model() too), OR a Vector3 (the mouth; aimed at `target`).
##                  target = the victim (Node3D or Vector3; aims a Vector3 `at`). Call it at the release (the model's
##                  attack_windup 0.15 s). Orange flame cone out of the bell (0.11 s), a white-hot flash + a fireball
##                  0.5 m out, sparks sprayed along the barrel, 3 powder wisps rolling off the muzzle.
##   powder_volley  at = the shooters' centre (Vector3 / Node3D), target = what they shoot at (Node3D / Vector3 /
##                  null: gives the direction of the air shock). Once per volley (>= 3 shots in 0.25 s), on top of each
##                  shot's musket_shot. Ground shock ring to r 4.2, a second ring, an upright shock ring in front of
##                  the line, a big low flash, dust kicked outward, a ring of sparks, a powder-black scorch.
##   powder_smoke   at = the cloud centre, target = the radius (float, clamped 2.5-4.0), OR a shooter (Node3D: its
##                  team; r 2.5), OR a Dictionary {radius, team, duration}. The 3 s cloud of 4.2: 10 billowing puffs
##                  (warm powder glow as it is born, rolls out, hangs, thins in the last second).
##                  Pooled per team: at most 6 clouds per team (the oldest is replaced), 60 puffs.
##   musket_impact  at = the hit point (Vector3; a Node3D = its chest), target = the victim. A building (group
##                  "buildings" / has building_type) gets the breach: a spray of sparks off the wall, stone chips,
##                  stone dust, a hot flash. Anything else: a small fire burst, dirt grit, sparks, the 1.5 m splash
##                  ring, a scorch, 2 dark smoke wisps.
##   musket_breach  the breach look of musket_impact, whatever the target.
## Fog: effects of the local team always show; others only where the local team sees (FogOfWar.is_visible at the
## point), checked 4 times per second (clouds too: a fogged cloud's puffs go to alpha 0). Muzzle wisps are checked once.
## Budget: everything is pre-built at _ready and pooled (ground marks, flares, flame cones, one-shot bursts, 4 puff
## MultiMeshes). One material per shader, looks set with instance uniforms: no node, material or mesh is created after
## _ready. No lights, no shadows. Particle bursts are not drawn beyond 45 m from the camera (visibility range) and not
## even started there; at most BURSTS_PER_FRAME new bursts per frame (a 20-gun volley keeps its flashes, drops sparks).
## Smoke: 3 MultiMeshes of 60 puffs (team 0, team 1, others) + 1 of 72 muzzle wisps, hidden when empty, animated in
## the shader (unit_fire_gun_smoke.gdshader): 10 musketeers volleying = ~30 wisps + 10-20 puffs, 2-4 draw calls.
## Shaders: own unit_fire_gun_flash (the cone), unit_fire_gun_smoke (puffs); reused read-only: vfx_ring (thin shock
## rings), champion_ground (soot / scorch), champion_flare (flashes), combat_streak (sparks).

const GROUP := &"unit_fire_gun_vfx"
const EFFECTS: Array[StringName] = [&"musket_shot", &"powder_volley", &"powder_smoke", &"musket_impact",
		&"musket_breach"]

# Palette: art-keep.md 0.2 Fire glow #FF8C26, team #D94D1F, deep red #8C140D; black-powder smoke off-white.
const FIRE_GLOW := Color(1.0, 0.55, 0.15)
const FIRE_HOT := Color(1.0, 0.86, 0.5)
const WHITE_HOT := Color(1.0, 0.95, 0.82)
const FIRE_DEEP := Color(0.55, 0.08, 0.05)
const POWDER_SMOKE := Color(0.80, 0.78, 0.74)
const MUZZLE_SMOKE := Color(0.74, 0.72, 0.69)
const IMPACT_SMOKE := Color(0.34, 0.31, 0.29)
const SOOT := Color(0.07, 0.055, 0.05)
const SOOT_LIGHT := Color(0.2, 0.17, 0.14)   # the volley's powder blackening (under the cloud: never a black pit)
const DIRT := Color(0.36, 0.30, 0.22)
const STONE := Color(0.56, 0.51, 0.46)

# Numbers from tier3-extras.md 4.1 / 4.2 / 13.
const SMOKE_RADIUS_MIN := 2.5
const SMOKE_RADIUS_MAX := 4.0
const SMOKE_TIME := 3.0
const SPLASH_RADIUS := 1.5
const CLOUDS_PER_TEAM := 6
const PUFFS_PER_CLOUD := 10
const SMOKE_SLOTS := 3            # team 0, team 1, everything else
const WISP_COUNT := 72
const PARTICLE_RANGE := 45.0      # no particles beyond this distance from the camera
const BURSTS_PER_FRAME := 24

const END_FADE := 0.2
const CHECK_INTERVAL := 0.25
const FOG_RESCAN := 1.0

enum { A_POINT, A_TARGET, A_WORLD }
enum { G_SHOCK, G_WIND, G_HEAL, G_ROPE, G_GLOW, G_SOOT, G_WARD }   # champion_ground.gdshader patterns

## Mesh pools (pre-built): pool -> size.
const POOL_SIZES := {&"disc": 32, &"ring": 40, &"flare": 64, &"cone": 24}
## One-shot bursts: look -> [amount, lifetime, draw pass, pool size, explosiveness].
const BURSTS := {
	&"muzzle_sparks": [14, 0.4, &"streak", 16, 1.0],
	&"impact_fire": [12, 0.45, &"add_blob", 12, 0.95],
	&"impact_grit": [12, 0.7, &"mix_chip", 12, 1.0],
	&"impact_sparks": [10, 0.35, &"streak", 12, 1.0],
	&"breach_sparks": [26, 0.6, &"streak", 8, 1.0],
	&"breach_chips": [10, 0.8, &"mix_chip", 8, 1.0],
	&"breach_dust": [8, 0.9, &"mix_smoke", 6, 0.9],
	&"volley_dust": [24, 0.9, &"mix_smoke", 4, 0.95],
	&"volley_sparks": [16, 0.35, &"streak", 4, 1.0],
}
## Bursts dropped first when a frame starts too many (the flash, cone and rings always stay).
const OPTIONAL_BURSTS: Array[StringName] = [&"muzzle_sparks", &"impact_sparks", &"volley_sparks"]

const GROUND_SHADER := preload("res://art/vfx/champion_ground.gdshader")
const FLARE_SHADER := preload("res://art/vfx/champion_flare.gdshader")
const STREAK_SHADER := preload("res://art/vfx/combat_streak.gdshader")
const RING_SHADER := preload("res://art/vfx/vfx_ring.gdshader")
const CONE_SHADER := preload("res://art/vfx/unit_fire_gun_flash.gdshader")
const SMOKE_SHADER := preload("res://art/vfx/unit_fire_gun_smoke.gdshader")


## One running effect: pooled pieces + scheduled one-shot bursts.
class Fx:
	extends RefCounted
	var id: StringName
	var t := 0.0
	var dur := 1.0
	var point := Vector3.ZERO
	var tpos := Vector3.ZERO
	var team := -1
	var end_at := -1.0
	var shown := true
	var check_left := 0.0
	var pieces: Array[Piece] = []
	var bursts: Array[Dictionary] = []
	var bursts_left := 0


## One pooled mesh of an effect (see TradeVfx.Piece), plus a rotation `rot` (flame cones, upright rings).
class Piece:
	extends RefCounted
	var n: GeometryInstance3D
	var pool: StringName
	var is_disc := false
	var at := 0
	var ofs := Vector3.ZERO
	var o0 := Vector3.ZERO
	var rot := Basis.IDENTITY
	var on := 0.0
	var off := 0.0
	var fin := 0.0
	var fout := 0.0
	var s0 := Vector3.ONE
	var s1 := Vector3.ONE
	var grow := 0.0
	var lf := -1.0
	var lr := -1.0


var _fx: Array[Fx] = []
var _free: Dictionary = {}          # pool -> Array[GeometryInstance3D]
var _all: Dictionary = {}           # pool -> Array[GeometryInstance3D]
var _bursts: Dictionary = {}        # look -> Array[GPUParticles3D]
var _burst_next: Dictionary = {}
var _live_bursts: Array[Dictionary] = []   # {p, left}
var _bursts_this_frame := 0
var _pmats: Dictionary = {}
var _passes: Dictionary = {}
var _fog: Node
var _fog_left := 0.0
var _layer := 0
var _cam: Camera3D
var _clock := 0.0

# Smoke (MultiMesh puffs).
var _smoke_mat: ShaderMaterial
var _cloud_mmi: Array[MultiMeshInstance3D] = []
var _cloud_next: PackedInt32Array = PackedInt32Array()
var _clouds: Array[Dictionary] = []   # slot * CLOUDS_PER_TEAM + i -> {alive, t0, end, point, team, radius, shown, cols}
var _wisp_mmi: MultiMeshInstance3D
var _wisp_next := 0
var _wisp_end := -1.0
var _smoke_check_left := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group(GROUP)
	top_level = true
	global_transform = Transform3D.IDENTITY
	_rng.seed = 1306
	_build_shared()
	_build_smoke()


func _process(delta: float) -> void:
	_clock += delta
	_bursts_this_frame = 0
	_cam = get_viewport().get_camera_3d() if get_viewport() else null
	_fog_left -= delta
	if _fog_left <= 0.0:
		_fog_left = FOG_RESCAN
		_fog = get_tree().get_first_node_in_group(&"fog")
	for i in range(_fx.size() - 1, -1, -1):
		var fx := _fx[i]
		if _tick(fx, delta):
			_finish(fx)
			_fx.remove_at(i)
	for i in range(_live_bursts.size() - 1, -1, -1):
		var b: Dictionary = _live_bursts[i]
		b["left"] = float(b["left"]) - delta
		if float(b["left"]) <= 0.0:
			var p: GPUParticles3D = b["p"]
			p.emitting = false
			p.visible = false
			_live_bursts.remove_at(i)
	_tick_smoke(delta)


# ---------------------------------------------------------------- public API

## True for the ids this family draws.
func handles(id: StringName) -> bool:
	return EFFECTS.has(id)


## Plays effect `id` (see the header for the arguments). Returns true when `id` is one of EFFECTS (handled, even if
## fog hides it or a pool is full), false for any other id (nothing happens).
func play(id: StringName, at: Variant, target: Variant = null) -> bool:
	if not EFFECTS.has(id):
		return false
	if not is_node_ready() or not is_inside_tree():
		return true
	match id:
		&"musket_shot": _musket_shot(at, target)
		&"powder_volley": _powder_volley(at, target)
		&"powder_smoke": _powder_smoke(at, target)
		&"musket_impact": _musket_impact(at, target, false)
		&"musket_breach": _musket_impact(at, target, true)
	return true


## Number of running effects (clouds count until they are over).
func active_count() -> int:
	return _fx.size()


## Ids of the running effects.
func active_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for fx in _fx:
		out.append(fx.id)
	return out


## Pooled pieces still on screen + bursts still alive + live smoke clouds + 1 while muzzle wisps float (0 at the end).
func live_count() -> int:
	var n := _live_bursts.size()
	for pool: StringName in _all:
		for g: GeometryInstance3D in _all[pool]:
			if g.visible:
				n += 1
	for c in _clouds:
		if c["alive"]:
			n += 1
	if _clock < _wisp_end:
		n += 1
	return n


## Live smoke clouds of `team` (-2 = every team).
func smoke_cloud_count(team: int = -2) -> int:
	var n := 0
	for c in _clouds:
		if c["alive"] and (team == -2 or int(c["team"]) == team):
			n += 1
	return n


## Copies of the live clouds: {team, point, radius, shown, time_left} (tests, debug).
func smoke_clouds() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c in _clouds:
		if c["alive"]:
			out.append({"team": c["team"], "point": c["point"], "radius": c["radius"], "shown": c["shown"],
					"time_left": float(c["end"]) - _clock})
	return out


# ---------------------------------------------------------------- the effects

func _musket_shot(at: Variant, target: Variant) -> void:
	var xf: Variant = _muzzle_xf(at, target)
	if xf == null:
		return
	var mx: Transform3D = xf
	var dir := mx.basis.z.normalized()
	if dir.length_squared() < 0.5:
		dir = Vector3.FORWARD
	var fx := _new_fx(&"musket_shot", mx.origin, _team_of(at))
	fx.dur = 0.16
	var rot := _y_along(dir)
	# The flame cone: shoots out to 1.5 m in 35 ms, a second hotter, shorter one inside it.
	var cone := _piece(fx, &"cone", A_POINT, Vector3.ZERO, 0.0, 0.11, 0.0, 0.06)
	if cone:
		cone.rot = rot
		_grow(cone, Vector3(0.3, 0.35, 0.3), Vector3(0.62, 1.55, 0.62), 0.035)
		_params(cone, {&"hot": _hdr(FIRE_HOT, 2.4), &"tint": _hdr(FIRE_GLOW, 2.2), &"edge": _hdr(FIRE_DEEP, 2.2),
				&"seed": _rng.randf() * 10.0})
	var inner := _piece(fx, &"cone", A_POINT, dir * 0.02, 0.0, 0.07, 0.0, 0.04)
	if inner:
		inner.rot = rot
		_grow(inner, Vector3(0.18, 0.2, 0.18), Vector3(0.3, 0.75, 0.3), 0.03)
		_params(inner, {&"hot": _hdr(WHITE_HOT, 2.8), &"tint": _hdr(FIRE_HOT, 2.3), &"edge": _hdr(FIRE_GLOW, 2.0),
				&"seed": _rng.randf() * 10.0})
	# Hot flash at the bell + the fireball riding out 0.5 m (kept small: the cone is the read, not a bloom blob).
	_flare(fx, A_POINT, dir * 0.08, _hdr(FIRE_HOT, 2.0), 0.4, 0.75, 0.04, 0.0, 0.12, 0.0, 0.08, 0.9, 6.0)
	var ball := _flare(fx, A_POINT, dir * 0.75, _hdr(FIRE_GLOW, 1.6), 0.3, 0.55, 0.08, 0.0, 0.13, 0.0, 0.08)
	if ball:
		ball.o0 = dir * 0.15
	_sched(fx, &"muzzle_sparks", 0.0, A_POINT, dir * 0.05, 1.0, _z_along(dir))
	_start(fx)
	# Powder wisps rolling off the muzzle (own MultiMesh, animated in the shader).
	if _fog_ok(fx.team, mx.origin):
		for i in 3:
			var k := float(i)
			var p := mx.origin + dir * (0.15 + 0.35 * k) + _jitter(0.08)
			var drift := dir * (0.9 - 0.2 * k) + Vector3.UP * (0.55 + 0.15 * k) + _jitter(0.2)
			_wisp(p, 0.42 + 0.14 * k, drift, 0.02 + 0.05 * k, 1.25 + 0.2 * k, MUZZLE_SMOKE, 0.5, 30, 0.7)


func _powder_volley(at: Variant, target: Variant) -> void:
	var point: Variant = _point_of(at, 0.0)
	if point == null:
		return
	var c: Vector3 = point
	var fx := _new_fx(&"powder_volley", c, _team_of(at))
	fx.dur = 1.4
	var up := Vector3.UP
	# The ring races out fast and thin (0.3 s to r 4.2); a slower, fainter one behind it.
	_ring(fx, A_POINT, _hdr(FIRE_GLOW, 1.8), 1.0, 4.2, 0.3, 0.0, 0.5, 0.0, 0.25, 0.08, 0.15)
	_ring(fx, A_POINT, _hdr(FIRE_HOT, 0.8), 0.6, 2.9, 0.45, 0.08, 0.7, 0.0, 0.3, 0.06, 0.12)
	_disc(fx, A_POINT, G_SOOT, SOOT_LIGHT.srgb_to_linear(), 1.4, 1.9, 0.25, 0.0, 1.4, 0.05, 0.8)
	_flare(fx, A_POINT, up * 1.2, _hdr(FIRE_GLOW, 1.2), 1.0, 1.7, 0.1, 0.0, 0.16, 0.0, 0.1, 0.6, 8.0)
	# An upright shock ring racing out in front of the line (the air slap of the volley).
	var dir: Variant = _dir_to(c, target)
	if dir != null:
		var d: Vector3 = dir
		var ring := _ring(fx, A_POINT, _hdr(FIRE_HOT, 2.0), 0.4, 2.3, 0.26, 0.02, 0.38, 0.0, 0.2, 0.08, 0.2)
		if ring:
			ring.rot = _y_along(d)
			ring.o0 = d * 1.0 + up * 1.3
			ring.ofs = d * 3.2 + up * 1.35
	_sched(fx, &"volley_dust", 0.0, A_POINT, up * 0.15)
	_sched(fx, &"volley_sparks", 0.0, A_POINT, up * 0.9)
	_start(fx)


func _powder_smoke(at: Variant, target: Variant) -> void:
	var point: Variant = _point_of(at, 0.0)
	if point == null:
		return
	var c: Vector3 = point
	var radius := SMOKE_RADIUS_MIN
	var dur := SMOKE_TIME
	var team := _team_of(at)
	if target is float or target is int:
		radius = float(target)
	elif target is Dictionary:
		var d: Dictionary = target
		radius = float(d.get("radius", radius))
		team = int(d.get("team", team))
		dur = maxf(float(d.get("duration", dur)), 0.5)
	elif typeof(target) == TYPE_OBJECT and is_instance_valid(target) and target is Node:
		team = _team_of(target) if team == -1 else team
	radius = clampf(radius, SMOKE_RADIUS_MIN, SMOKE_RADIUS_MAX)
	var fx := _new_fx(&"powder_smoke", c, team)   # no pieces: it only tracks the cloud's life (active_ids)
	fx.dur = dur
	_start(fx)
	_cloud(c, radius, dur, team)


func _musket_impact(at: Variant, target: Variant, force_breach: bool) -> void:
	var t: Node3D = _node(target)
	var point: Variant = _point_of(at, 0.55)
	if point == null and t:
		point = _chest(t)
	if point == null:
		return
	var p: Vector3 = point
	var breach := force_breach or _is_building(t)
	var fx := _new_fx(&"musket_breach" if force_breach else &"musket_impact", p, _team_of(t))
	var up := Vector3.UP
	if breach:
		fx.dur = 0.9
		# Outward from the wall: from the building's centre toward the hit (flat), tilted up.
		var out := Vector3.UP
		if t:
			var flat := p - t.global_position
			flat.y = 0.0
			if flat.length_squared() > 0.01:
				out = (flat.normalized() + Vector3.UP * 0.45).normalized()
		_flare(fx, A_POINT, out * 0.2, _hdr(FIRE_HOT, 2.2), 0.7, 1.2, 0.05, 0.0, 0.14, 0.0, 0.09, 1.0, 8.0)
		_flare(fx, A_POINT, out * 0.3, _hdr(FIRE_GLOW, 1.4), 1.1, 1.7, 0.1, 0.0, 0.22, 0.0, 0.15)
		var basis := _z_along(out)
		_sched(fx, &"breach_sparks", 0.0, A_POINT, out * 0.1, 1.0, basis)
		_sched(fx, &"breach_chips", 0.0, A_POINT, out * 0.1, 1.0, basis)
		_sched(fx, &"breach_dust", 0.02, A_POINT, out * 0.25, 1.0, basis)
		_sched(fx, &"impact_fire", 0.0, A_POINT, out * 0.15, 0.8)
		_start(fx)
		_smoke_puffs(p + out * 0.4, 2, IMPACT_SMOKE, fx.team)
		return
	fx.dur = 1.2
	var ground := p
	ground.y = t.global_position.y if t else p.y
	var g_ofs := ground - p
	_flare(fx, A_POINT, Vector3.ZERO, _hdr(FIRE_HOT, 1.6), 0.45, 0.75, 0.05, 0.0, 0.11, 0.0, 0.07, 0.8, 6.0)
	var ring := _ring(fx, A_POINT, _hdr(FIRE_GLOW, 1.2), 0.3, SPLASH_RADIUS, 0.16, 0.0, 0.28, 0.0, 0.14, 0.1, 0.18)
	if ring:
		ring.o0 += g_ofs
		ring.ofs += g_ofs
	var scorch := _disc(fx, A_POINT, G_SOOT, SOOT.srgb_to_linear(), 0.5, 0.75, 0.12, 0.0, 1.2, 0.03, 0.6)
	if scorch:
		scorch.o0 += g_ofs
		scorch.ofs += g_ofs
	_sched(fx, &"impact_fire", 0.0, A_POINT, Vector3.ZERO)
	_sched(fx, &"impact_grit", 0.0, A_POINT, g_ofs + up * 0.1)
	_sched(fx, &"impact_sparks", 0.0, A_POINT, Vector3.ZERO)
	_start(fx)
	_smoke_puffs(p + up * 0.2, 2, IMPACT_SMOKE, fx.team)


# ---------------------------------------------------------------- argument helpers

## The muzzle frame from `at` (see musket_shot), or null.
func _muzzle_xf(at: Variant, target: Variant) -> Variant:
	if at is Transform3D:
		return at
	var aim: Variant = _point_of(target, 0.55)
	if at is Vector3:
		var o: Vector3 = at
		var d := Vector3.FORWARD
		if aim != null and (aim as Vector3).distance_to(o) > 0.05:
			d = ((aim as Vector3) - o).normalized()
		return Transform3D(_z_along(d), o)
	var n := _node(at)
	if n == null:
		return null
	for src: Object in [n, _model_of(n)]:
		if src and is_instance_valid(src) and src.has_method(&"get_muzzle_xf"):
			var v: Variant = src.call(&"get_muzzle_xf")
			if v is Transform3D:
				return v
	# No muzzle hook: chest height, 0.9 m in front, toward the target (else the node's facing).
	var fwd := n.global_basis.z
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length_squared() > 0.001 else Vector3.FORWARD
	var o2 := n.global_position + Vector3.UP * 1.3 + fwd * 0.9
	if aim != null and (aim as Vector3).distance_to(o2) > 0.05:
		fwd = ((aim as Vector3) - o2).normalized()
	return Transform3D(_z_along(fwd), o2)


func _model_of(n: Node) -> Object:
	if n.has_method(&"get_model"):
		var m: Variant = n.call(&"get_model")
		if m is Object and is_instance_valid(m):
			return m
	return null


## World point of a Vector3 / Node3D (a node: its position + `chest` x its body height), else null.
func _point_of(v: Variant, chest: float) -> Variant:
	if v is Vector3:
		return v
	var n := _node(v)
	if n == null:
		return null
	if chest > 0.0:
		return n.global_position + Vector3.UP * _h(n) * chest
	return n.global_position


func _chest(n: Node3D) -> Vector3:
	return n.global_position + Vector3.UP * _h(n) * 0.55


## Flat direction from `from` toward a Node3D / Vector3 target, or null.
func _dir_to(from: Vector3, target: Variant) -> Variant:
	var p: Variant = _point_of(target, 0.0)
	if p == null:
		return null
	var d: Vector3 = (p as Vector3) - from
	d.y = 0.0
	if d.length_squared() < 0.04:
		return null
	return d.normalized()


func _node(v: Variant) -> Node3D:
	if typeof(v) == TYPE_OBJECT and is_instance_valid(v) and v is Node3D and (v as Node3D).is_inside_tree():
		return v as Node3D
	return null


func _team_of(v: Variant) -> int:
	var n := _node(v)
	if n == null:
		return -1
	var team: Variant = n.get(&"team")
	if team == null and n.get_parent() is Node3D:
		team = n.get_parent().get(&"team")   # a model under its unit
	return int(team) if team != null else -1


func _is_building(n: Node3D) -> bool:
	if n == null:
		return false
	return n.is_in_group(&"buildings") or n.get(&"building_type") != null


func _h(n: Variant) -> float:
	if not is_instance_valid(n):
		return 1.6
	var h: Variant = (n as Object).get(&"body_height")
	return float(h) if h != null else 1.6


## Basis whose +Y is `d` (flame cones, upright rings: meshes whose axis / normal is local Y).
func _y_along(d: Vector3) -> Basis:
	var y := d.normalized()
	var ref := Vector3.UP if absf(y.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	var x := ref.cross(y).normalized()
	var z := x.cross(y).normalized()
	return Basis(x, y, z)


## Basis whose +Z is `d` (directional bursts: their ParticleProcessMaterial direction is +Z).
func _z_along(d: Vector3) -> Basis:
	var z := d.normalized()
	var ref := Vector3.UP if absf(z.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	var x := ref.cross(z).normalized()
	var y := z.cross(x).normalized()
	return Basis(x, y, z)


func _jitter(r: float) -> Vector3:
	return Vector3(_rng.randf_range(-r, r), _rng.randf_range(-r, r) * 0.5, _rng.randf_range(-r, r))


# ---------------------------------------------------------------- effect runtime (TradeVfx pattern)

func _new_fx(id: StringName, point: Vector3, team: int) -> Fx:
	var fx := Fx.new()
	fx.id = id
	fx.point = point
	fx.tpos = point
	fx.team = team
	return fx


func _start(fx: Fx) -> void:
	_fx.append(fx)
	_refresh(fx)
	fx.check_left = CHECK_INTERVAL
	_tick(fx, 0.0)


## Advances one effect. Returns true when it is over.
func _tick(fx: Fx, delta: float) -> bool:
	fx.t += delta
	fx.check_left -= delta
	if fx.check_left <= 0.0:
		fx.check_left += CHECK_INTERVAL
		_refresh(fx)
	var ef := 1.0 if fx.end_at < 0.0 else clampf((fx.end_at - fx.t) / END_FADE, 0.0, 1.0)
	for d in fx.pieces:
		_tick_piece(fx, d, ef)
	if fx.bursts_left > 0:
		for b in fx.bursts:
			if not b["done"] and fx.t >= float(b["on"]):
				b["done"] = true
				fx.bursts_left -= 1
				if fx.shown and fx.end_at < 0.0:
					_burst(b["look"], _anchor(fx, b["at"]) + (b["ofs"] as Vector3), b["size"], b["basis"])
	if fx.end_at >= 0.0:
		return fx.t >= fx.end_at
	return fx.t >= fx.dur and fx.bursts_left <= 0


func _tick_piece(fx: Fx, d: Piece, ef: float) -> void:
	var n := d.n
	var off := d.off if d.off > 0.0 else fx.dur + d.off
	var lt := fx.t - d.on
	if lt < 0.0 or fx.t >= off:
		if n.visible:
			n.visible = false
		return
	var f := ef
	if d.fin > 0.0:
		f = minf(f, lt / d.fin)
	if d.fout > 0.0:
		f = minf(f, (off - fx.t) / d.fout)
	f = clampf(f, 0.0, 1.0)
	var k := 1.0
	if d.grow > 0.0:
		k = _ease(clampf(lt / d.grow, 0.0, 1.0))
	var s := d.s0.lerp(d.s1, k)
	var pos := _anchor(fx, d.at) + d.o0.lerp(d.ofs, k)
	var xf := Transform3D(d.rot * Basis.from_scale(s), pos)
	if not xf.is_equal_approx(n.transform):
		n.transform = xf
	if absf(f - d.lf) > 0.003:
		d.lf = f
		n.set_instance_shader_parameter(&"fade", f)
	if lt <= 1.05 and d.pool != &"ring":   # vfx_ring has no `age`
		n.set_instance_shader_parameter(&"age", lt)
	if d.is_disc and absf(s.x - d.lr) > 0.001:
		d.lr = s.x
		n.set_instance_shader_parameter(&"radius", s.x)
	var vis := fx.shown and f > 0.002
	if n.visible != vis:
		n.visible = vis


func _finish(fx: Fx) -> void:
	for d in fx.pieces:
		d.n.visible = false
		d.n.set_instance_shader_parameter(&"fade", 0.0)
		(_free[d.pool] as Array).append(d.n)
	fx.pieces.clear()


func _refresh(fx: Fx) -> void:
	fx.shown = _fog_ok(fx.team, fx.point)


func _fog_ok(team: int, pos: Vector3) -> bool:
	if not is_instance_valid(_fog):
		return true
	if not bool(_fog.get(&"enabled")):
		return true
	var local: Variant = _fog.get(&"local_team")
	if local == null or int(local) == team or not _fog.has_method(&"is_visible"):
		return true
	return bool(_fog.call(&"is_visible", int(local), pos))


func _anchor(fx: Fx, at: int) -> Vector3:
	match at:
		A_TARGET:
			return fx.tpos
		A_WORLD:
			return Vector3.ZERO
	return fx.point


func _piece(fx: Fx, pool: StringName, at: int, ofs: Vector3, on: float, off: float, fin: float,
		fout: float) -> Piece:
	var free: Array = _free[pool]
	if free.is_empty():
		return null   # pool exhausted: this piece is skipped (every helper accepts null)
	var d := Piece.new()
	d.n = free.pop_back()
	d.pool = pool
	d.is_disc = pool == &"disc"
	d.at = at
	d.ofs = ofs
	d.o0 = ofs
	d.on = on
	d.off = off
	d.fin = fin
	d.fout = fout
	d.lf = -1.0
	d.lr = -1.0
	d.n.set_instance_shader_parameter(&"fade", 0.0)
	fx.pieces.append(d)
	return d


func _grow(d: Piece, s0: Variant, s1: Variant, time: float) -> void:
	if d == null:
		return
	d.s0 = s0 if s0 is Vector3 else Vector3.ONE * float(s0)
	d.s1 = s1 if s1 is Vector3 else Vector3.ONE * float(s1)
	d.grow = time


func _params(d: Piece, params: Dictionary) -> void:
	if d == null:
		return
	for k: StringName in params:
		d.n.set_instance_shader_parameter(k, params[k])


## Ground mark (champion_ground.gdshader) growing from radius r0 to r1.
func _disc(fx: Fx, at: int, pattern: int, tint: Color, r0: float, r1: float, grow: float, on: float, off: float,
		fin: float, fout: float) -> Piece:
	_layer = (_layer + 1) % 8
	var d := _piece(fx, &"disc", at, Vector3.UP * (0.05 + 0.006 * float(_layer)), on, off, fin, fout)
	_grow(d, Vector3(r0, 1.0, r0), Vector3(r1, 1.0, r1), grow)
	_params(d, {&"pattern": float(pattern), &"tint": tint, &"seed": _rng.randf() * 10.0})
	return d


## Thin shock ring (vfx_ring.gdshader: a glowing band, no fill) growing from radius r0 to r1; `width` = band width as
## a fraction of the radius, `glow` = the soft light trailing inside the band.
func _ring(fx: Fx, at: int, tint: Color, r0: float, r1: float, grow: float, on: float, off: float, fin: float,
		fout: float, width: float = 0.1, glow: float = 0.25) -> Piece:
	_layer = (_layer + 1) % 8
	var d := _piece(fx, &"ring", at, Vector3.UP * (0.06 + 0.006 * float(_layer)), on, off, fin, fout)
	_grow(d, Vector3(r0, 1.0, r0), Vector3(r1, 1.0, r1), grow)
	_params(d, {&"tint": tint, &"fill": Color(0, 0, 0, 0), &"width": width, &"glow": glow,
			&"seed": _rng.randf() * 10.0})
	return d


## Camera-facing glow (champion_flare.gdshader) growing from size s0 to s1 metres.
func _flare(fx: Fx, at: int, ofs: Vector3, tint: Color, s0: float, s1: float, grow: float, on: float, off: float,
		fin: float, fout: float, rays: float = 0.0, spikes: float = 4.0) -> Piece:
	var d := _piece(fx, &"flare", at, ofs, on, off, fin, fout)
	_grow(d, s0, s1, grow)
	_params(d, {&"tint": tint, &"rays": rays, &"spikes": spikes, &"pulse": 0.0, &"seed": _rng.randf() * 10.0,
			&"halo": Color(0, 0, 0, 0)})
	return d


func _sched(fx: Fx, look: StringName, on: float, at: int, ofs: Vector3, size: float = 1.0,
		basis: Basis = Basis.IDENTITY) -> void:
	fx.bursts.append({"look": look, "on": on, "at": at, "ofs": ofs, "size": size, "basis": basis, "done": false})
	fx.bursts_left += 1


func _burst(look: StringName, pos: Vector3, size: float, basis: Basis) -> void:
	if _cam and is_instance_valid(_cam) and _cam.global_position.distance_to(pos) > PARTICLE_RANGE:
		return   # too far to read: not even started
	if _bursts_this_frame >= BURSTS_PER_FRAME and OPTIONAL_BURSTS.has(look):
		return
	_bursts_this_frame += 1
	var pool: Array = _bursts[look]
	var i: int = _burst_next[look]
	_burst_next[look] = (i + 1) % pool.size()
	var p: GPUParticles3D = pool[i]
	p.transform = Transform3D(basis * Basis.from_scale(Vector3.ONE * clampf(size, 0.4, 3.0)), pos)
	p.visible = true
	p.restart()
	for b in _live_bursts:
		if b["p"] == p:
			b["left"] = p.lifetime + 0.1
			return
	_live_bursts.append({"p": p, "left": p.lifetime + 0.1})


func _ease(k: float) -> float:
	return 1.0 - pow(1.0 - k, 3.0)


## sRGB colour -> linear HDR (instance uniforms and particle colours are linear).
func _hdr(c: Color, energy: float, alpha: float = 1.0) -> Color:
	var l := c.srgb_to_linear()
	return Color(l.r * energy, l.g * energy, l.b * energy, alpha)


# ---------------------------------------------------------------- smoke (MultiMesh puffs)

func _slot_of(team: int) -> int:
	return team if team == 0 or team == 1 else 2


## One powder cloud: 10 puffs written once into the team's MultiMesh (the oldest of its 6 clouds is replaced).
func _cloud(c: Vector3, radius: float, dur: float, team: int) -> void:
	var slot := _slot_of(team)
	var ci: int = _cloud_next[slot]
	# Prefer a free cloud; else the one that ends first (the oldest).
	var best := -1
	var best_end := INF
	for i in CLOUDS_PER_TEAM:
		var rec: Dictionary = _clouds[slot * CLOUDS_PER_TEAM + i]
		if not rec["alive"]:
			best = i
			break
		if float(rec["end"]) < best_end:
			best_end = float(rec["end"])
			best = i
	ci = best
	_cloud_next[slot] = (ci + 1) % CLOUDS_PER_TEAM
	var rec: Dictionary = _clouds[slot * CLOUDS_PER_TEAM + ci]
	var shown := _fog_ok(team, c)
	rec["alive"] = true
	rec["t0"] = _clock
	rec["end"] = _clock + dur + 0.05
	rec["point"] = c
	rec["team"] = team
	rec["radius"] = radius
	rec["shown"] = shown
	var cols: PackedColorArray = rec["cols"]
	var mm := _cloud_mmi[slot].multimesh
	var base := ci * PUFFS_PER_CLOUD
	var k := radius / SMOKE_RADIUS_MIN
	var spin := _rng.randf() * TAU
	var wind := Vector3(0.35, 0.0, -0.15)   # a faint common drift so clouds do not look stamped
	for j in PUFFS_PER_CLOUD:
		var pos := c
		var size := 2.6 * k
		var start := 0.0
		var alpha := 0.52
		var glow := 0.85
		var h := 1.15
		if j >= 1 and j <= 6:
			var a := spin + TAU * float(j - 1) / 6.0 + _rng.randf_range(-0.25, 0.25)
			var dist := radius * _rng.randf_range(0.46, 0.58)
			pos += Vector3(cos(a), 0.0, sin(a)) * dist
			size = 2.05 * k * _rng.randf_range(0.9, 1.1)
			start = _rng.randf_range(0.02, 0.12)
			alpha = 0.5
			glow = 0.6
			h = _rng.randf_range(0.75, 1.3)
		elif j >= 7:
			var a2 := spin + TAU * (float(j - 7) / 3.0 + 1.0 / 12.0) + _rng.randf_range(-0.3, 0.3)
			var dist2 := radius * _rng.randf_range(0.76, 0.86)
			pos += Vector3(cos(a2), 0.0, sin(a2)) * dist2
			size = 1.55 * k * _rng.randf_range(0.9, 1.12)
			start = _rng.randf_range(0.1, 0.22)
			alpha = 0.42
			glow = 0.3
			h = _rng.randf_range(0.55, 0.85)
		pos.y += h
		var flat := pos - c
		flat.y = 0.0
		var outward := flat.normalized() if flat.length_squared() > 0.01 else Vector3.ZERO
		var drift := outward * _rng.randf_range(0.35, 0.6) + Vector3.UP * _rng.randf_range(0.45, 0.8) + wind
		var pdur := maxf(dur - start + _rng.randf_range(-0.12, 0.08), 0.5)
		var col := POWDER_SMOKE * _rng.randf_range(0.9, 1.06)
		col = Color(col.r, col.g, col.b).srgb_to_linear()
		cols[j] = Color(col.r, col.g, col.b, alpha)
		mm.set_instance_transform(base + j, Transform3D(Basis(Vector3(size, 0, 0), drift, Vector3(0, 0, 1)), pos))
		mm.set_instance_color(base + j, Color(col.r, col.g, col.b, alpha if shown else 0.0))
		mm.set_instance_custom_data(base + j, Color(_clock + start, pdur, 62.0 + _rng.randf() * 0.99, glow))
	rec["cols"] = cols
	_cloud_mmi[slot].visible = true
	_smoke_mat.set_shader_parameter(&"now", _clock)


## A few small puffs (muzzle / impact smoke) in the wisp MultiMesh.
func _smoke_puffs(p: Vector3, count: int, color: Color, team: int) -> void:
	if not _fog_ok(team, p):
		return
	for i in count:
		var drift := Vector3.UP * _rng.randf_range(0.8, 1.2) + _jitter(0.35)
		_wisp(p + _jitter(0.2), _rng.randf_range(0.7, 0.95), drift, 0.03 + 0.06 * float(i), _rng.randf_range(0.95, 1.2),
				color, 0.55, 30, 0.9)


func _wisp(p: Vector3, size: float, drift: Vector3, delay: float, dur: float, color: Color, alpha: float,
		fade_pct: int, glow: float) -> void:
	var mm := _wisp_mmi.multimesh
	var i := _wisp_next
	_wisp_next = (_wisp_next + 1) % WISP_COUNT
	var col := color.srgb_to_linear()
	mm.set_instance_transform(i, Transform3D(Basis(Vector3(size, 0, 0), drift, Vector3(0, 0, 1)), p))
	mm.set_instance_color(i, Color(col.r, col.g, col.b, alpha))
	mm.set_instance_custom_data(i, Color(_clock + delay, dur, float(fade_pct) + _rng.randf() * 0.99, glow))
	_wisp_end = maxf(_wisp_end, _clock + delay + dur + 0.05)
	_wisp_mmi.visible = true
	_smoke_mat.set_shader_parameter(&"now", _clock)


func _tick_smoke(delta: float) -> void:
	var any := false
	_smoke_check_left -= delta
	var check := _smoke_check_left <= 0.0
	if check:
		_smoke_check_left = CHECK_INTERVAL
	for slot in SMOKE_SLOTS:
		var live := false
		for i in CLOUDS_PER_TEAM:
			var rec: Dictionary = _clouds[slot * CLOUDS_PER_TEAM + i]
			if not rec["alive"]:
				continue
			if _clock >= float(rec["end"]):
				rec["alive"] = false
				_hide_cloud(slot, i)
				continue
			live = true
			if check:
				var shown := _fog_ok(int(rec["team"]), rec["point"])
				if shown != bool(rec["shown"]):
					rec["shown"] = shown
					_set_cloud_alpha(slot, i, shown)
		if _cloud_mmi[slot].visible != live:
			_cloud_mmi[slot].visible = live
		any = any or live
	var wisps := _clock < _wisp_end
	if _wisp_mmi.visible != wisps:
		_wisp_mmi.visible = wisps
	if any or wisps:
		_smoke_mat.set_shader_parameter(&"now", _clock)


func _set_cloud_alpha(slot: int, ci: int, shown: bool) -> void:
	var rec: Dictionary = _clouds[slot * CLOUDS_PER_TEAM + ci]
	var cols: PackedColorArray = rec["cols"]
	var mm := _cloud_mmi[slot].multimesh
	for j in PUFFS_PER_CLOUD:
		var c := cols[j]
		mm.set_instance_color(ci * PUFFS_PER_CLOUD + j, Color(c.r, c.g, c.b, c.a if shown else 0.0))


## A cloud that ended: its puffs are already collapsed by the shader (k >= 1); zero them so a stale slot never shows.
func _hide_cloud(slot: int, ci: int) -> void:
	var mm := _cloud_mmi[slot].multimesh
	for j in PUFFS_PER_CLOUD:
		mm.set_instance_custom_data(ci * PUFFS_PER_CLOUD + j, Color(-100.0, 0.001, 0.0, 0.0))


func _build_smoke() -> void:
	_smoke_mat = ShaderMaterial.new()
	_smoke_mat.shader = SMOKE_SHADER
	# Toward the game's sun (world_env / scene sun: pitch -50, yaw 35; light shines along its -Z).
	var sun := Basis.from_euler(Vector3(deg_to_rad(-50.0), deg_to_rad(35.0), 0.0))
	_smoke_mat.set_shader_parameter(&"light_dir", sun.z.normalized())
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var big := AABB(Vector3(-2000.0, -50.0, -2000.0), Vector3(4000.0, 200.0, 4000.0))
	_cloud_next.resize(SMOKE_SLOTS)
	for slot in SMOKE_SLOTS:
		_cloud_mmi.append(_puff_mm("SmokeTeam%d" % slot, quad, CLOUDS_PER_TEAM * PUFFS_PER_CLOUD, big))
		_cloud_next[slot] = 0
		for i in CLOUDS_PER_TEAM:
			var cols := PackedColorArray()
			cols.resize(PUFFS_PER_CLOUD)
			_clouds.append({"alive": false, "t0": 0.0, "end": 0.0, "point": Vector3.ZERO, "team": -1,
					"radius": 0.0, "shown": true, "cols": cols})
	_wisp_mmi = _puff_mm("SmokeWisps", quad, WISP_COUNT, big)


func _puff_mm(nm: String, quad: QuadMesh, count: int, aabb: AABB) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = quad
	mm.instance_count = count
	mm.custom_aabb = aabb
	for i in count:
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * 0.001), Vector3.ZERO))
		mm.set_instance_color(i, Color(0, 0, 0, 0))
		mm.set_instance_custom_data(i, Color(-100.0, 0.001, 0.0, 0.0))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = nm
	mmi.multimesh = mm
	mmi.material_override = _smoke_mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	mmi.visible = false
	add_child(mmi)
	return mmi


# ---------------------------------------------------------------- shared resources (built once)

func _build_shared() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(2.0, 2.0)
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	var meshes := {&"disc": plane, &"ring": plane, &"flare": quad, &"cone": quad}
	var mats := {&"disc": _shader_mat(GROUND_SHADER), &"ring": _shader_mat(RING_SHADER),
			&"flare": _shader_mat(FLARE_SHADER), &"cone": _shader_mat(CONE_SHADER)}
	for pool: StringName in POOL_SIZES:
		var arr: Array = []
		for i in int(POOL_SIZES[pool]):
			var m := MeshInstance3D.new()
			m.name = "%s%d" % [String(pool).capitalize(), i]
			m.mesh = meshes[pool]
			m.material_override = mats[pool]
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			m.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
			m.visible = false
			if pool == &"flare" or pool == &"cone":
				m.extra_cull_margin = 2.0   # billboards / axial cones leave their mesh AABB
			add_child(m)
			arr.append(m)
		_all[pool] = arr
		_free[pool] = arr.duplicate()
	_build_passes()
	for look: StringName in BURSTS:
		var spec: Array = BURSTS[look]
		var arr: Array = []
		for i in int(spec[3]):
			var p := _emitter(look, int(spec[0]), float(spec[1]), spec[2])
			p.one_shot = true
			p.explosiveness = float(spec[4])
			add_child(p)
			arr.append(p)
		_bursts[look] = arr
		_burst_next[look] = 0


func _shader_mat(shader: Shader) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader
	return m


func _emitter(look: StringName, amount: int, lifetime: float, pass_id: StringName) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "%s_%d" % [look, get_child_count()]
	p.process_material = _pmat(look)
	p.draw_pass_1 = _passes[pass_id]
	p.amount = amount
	p.lifetime = lifetime
	p.local_coords = false
	p.emitting = false
	p.visible = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_range_end = PARTICLE_RANGE
	p.visibility_aabb = AABB(Vector3(-5.0, -3.0, -5.0), Vector3(10.0, 8.0, 10.0))
	return p


## Draw passes: textured billboard quads (a shape mask each, billboard_keep_scale) + velocity-aligned streaks.
func _build_passes() -> void:
	_passes[&"add_blob"] = _particle_quad(_shape_tex(&"blob"), BaseMaterial3D.BLEND_MODE_ADD)
	_passes[&"mix_chip"] = _particle_quad(_shape_tex(&"chip"), BaseMaterial3D.BLEND_MODE_MIX)
	_passes[&"mix_smoke"] = _particle_quad(_shape_tex(&"smoke"), BaseMaterial3D.BLEND_MODE_MIX)
	var streak := QuadMesh.new()
	var sm := ShaderMaterial.new()
	sm.shader = STREAK_SHADER
	sm.set_shader_parameter(&"stretch", 5.0)
	streak.material = sm
	_passes[&"streak"] = streak


func _particle_quad(tex: Texture2D, blend: BaseMaterial3D.BlendMode) -> QuadMesh:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = blend
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.billboard_keep_scale = true   # Godot 4.7: without it the particle scale (scale_min/max, curve) is ignored
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = tex
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.disable_receive_shadows = true
	if blend == BaseMaterial3D.BLEND_MODE_MIX:
		mat.proximity_fade_enabled = true
		mat.proximity_fade_distance = 0.5
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	q.material = mat
	return q


## 64 x 64 white shape masks (alpha = shape, grey = shading), tinted by the particle colour. Built once.
func _shape_tex(kind: StringName) -> ImageTexture:
	var n := 64
	var img := Image.create_empty(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var u := (float(x) + 0.5) / float(n) * 2.0 - 1.0
			var v := (float(y) + 0.5) / float(n) * 2.0 - 1.0
			var r := sqrt(u * u + v * v)
			var a := 0.0
			var shade := 1.0
			match kind:
				&"blob":
					# A ragged ball of flame: soft core, noisy edge.
					var nse := _vn(u * 3.0 + 4.1, v * 3.0 - 1.7)
					a = clampf((1.0 - r) * 1.5 + (nse - 0.5) * 0.8 - 0.15, 0.0, 1.0)
					a = a * a * (3.0 - 2.0 * a) * clampf((1.0 - r) / 0.25, 0.0, 1.0)
				&"chip":
					# An angular pebble / stone chip: a 5-sided polygon, lit top-left.
					var ang := atan2(v, u)
					var sides := 5.0
					var poly := cos(PI / sides) / cos(fmod(ang + TAU * 2.0 + 0.3, TAU / sides) - PI / sides)
					var edge := 0.78 * poly
					a = clampf((edge - r) / 0.06, 0.0, 1.0)
					shade = clampf(0.72 - 0.3 * (u + v) * 0.5 + 0.1 * _vn(u * 6.0, v * 6.0), 0.35, 1.0)
				&"smoke":
					var nse2 := _vn(u * 2.3 + 7.1, v * 2.3 + 3.3) * 0.6 + _vn(u * 5.1 + 1.7, v * 5.1 - 2.2) * 0.4
					a = clampf((1.0 - r) * 1.6 + (nse2 - 0.5) * 0.9 - 0.2, 0.0, 1.0)
					a = a * a * (3.0 - 2.0 * a) * clampf((1.0 - r) / 0.2, 0.0, 1.0)
					shade = clampf(0.82 + 0.14 * (0.5 - v * 0.5) + (nse2 - 0.5) * 0.25, 0.0, 1.0)
			img.set_pixel(x, y, Color(shade, shade, shade, a))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _vn(x: float, y: float) -> float:
	var ix := floorf(x)
	var iy := floorf(y)
	var fx := x - ix
	var fy := y - iy
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	return lerpf(lerpf(_h2(ix, iy), _h2(ix + 1.0, iy), fx), lerpf(_h2(ix, iy + 1.0), _h2(ix + 1.0, iy + 1.0), fx), fy)


func _h2(x: float, y: float) -> float:
	return fposmod(sin(x * 127.1 + y * 311.7) * 43758.5453, 1.0)


## Particle process materials, one per look, shared by every emitter of that look.
func _pmat(key: StringName) -> ParticleProcessMaterial:
	if _pmats.has(key):
		return _pmats[key]
	var m := ParticleProcessMaterial.new()
	var white := _hdr(WHITE_HOT, 3.0)
	var hot := _hdr(FIRE_HOT, 2.6)
	var glow := _hdr(FIRE_GLOW, 2.2)
	var deep := _hdr(FIRE_DEEP, 1.4, 0.0)
	match key:
		&"muzzle_sparks":
			# Sprayed along the barrel (+Z of the emitter), 9-16 m/s, dropping.
			_shape_sphere(m, 0.06)
			m.direction = Vector3(0, 0, 1)
			m.spread = 13.0
			m.initial_velocity_min = 9.0
			m.initial_velocity_max = 16.0
			m.damping_min = 5.0
			m.damping_max = 8.0
			m.gravity = Vector3(0, -7.0, 0)
			m.particle_flag_align_y = true
			_size(m, 0.045, 0.07, &"shrink")
			m.color_ramp = _ramp([white, hot, glow, deep])
		&"impact_fire":
			# A small ball of burning powder: flame blobs puff out and rise, orange -> red -> gone.
			_shape_sphere(m, 0.22)
			m.direction = Vector3.UP
			m.spread = 70.0
			m.initial_velocity_min = 1.2
			m.initial_velocity_max = 3.2
			m.damping_min = 3.0
			m.damping_max = 4.5
			m.gravity = Vector3(0, 2.5, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			m.angular_velocity_min = -90.0
			m.angular_velocity_max = 90.0
			m.scale_min = 0.38
			m.scale_max = 0.62
			m.scale_curve = _curve([Vector2(0.0, 0.45), Vector2(0.2, 1.0), Vector2(1.0, 0.35)])
			m.color_ramp = _ramp_at([0.0, 0.15, 0.5, 1.0], [white, hot, glow, deep])
		&"impact_grit":
			# Dirt and pebbles thrown up by the charge.
			_shape_sphere(m, 0.15)
			m.direction = Vector3.UP
			m.spread = 45.0
			m.initial_velocity_min = 3.0
			m.initial_velocity_max = 6.0
			m.gravity = Vector3(0, -16.0, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			m.angular_velocity_min = -600.0
			m.angular_velocity_max = 600.0
			_size(m, 0.08, 0.15, &"hold")
			m.color_initial_ramp = _ramp(_lin([DIRT, Color(0.26, 0.21, 0.15), Color(0.46, 0.39, 0.29), SOOT]))
			m.color_ramp = _ramp([Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0.0)])
		&"impact_sparks":
			_shape_sphere(m, 0.1)
			m.direction = Vector3.UP
			m.spread = 80.0
			m.initial_velocity_min = 4.0
			m.initial_velocity_max = 9.0
			m.damping_min = 2.0
			m.damping_max = 3.0
			m.gravity = Vector3(0, -10.0, 0)
			m.particle_flag_align_y = true
			_size(m, 0.04, 0.06, &"shrink")
			m.color_ramp = _ramp([white, hot, glow, deep])
		&"breach_sparks":
			# Off the wall (+Z of the emitter = outward), a wide fan that rains down.
			_shape_sphere(m, 0.12)
			m.direction = Vector3(0, 0, 1)
			m.spread = 55.0
			m.initial_velocity_min = 5.0
			m.initial_velocity_max = 12.0
			m.damping_min = 1.5
			m.damping_max = 2.5
			m.gravity = Vector3(0, -12.0, 0)
			m.particle_flag_align_y = true
			_size(m, 0.05, 0.08, &"shrink")
			m.color_ramp = _ramp([white, hot, hot, glow, deep])
		&"breach_chips":
			_shape_sphere(m, 0.15)
			m.direction = Vector3(0, 0, 1)
			m.spread = 50.0
			m.initial_velocity_min = 3.0
			m.initial_velocity_max = 7.0
			m.gravity = Vector3(0, -15.0, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			m.angular_velocity_min = -500.0
			m.angular_velocity_max = 500.0
			_size(m, 0.12, 0.22, &"hold")
			m.color_initial_ramp = _ramp(_lin([STONE, Color(0.42, 0.38, 0.35), Color(0.66, 0.61, 0.55)]))
			m.color_ramp = _ramp([Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0.0)])
		&"breach_dust":
			_shape_sphere(m, 0.25)
			m.direction = Vector3(0, 0.3, 1)
			m.spread = 60.0
			m.initial_velocity_min = 1.0
			m.initial_velocity_max = 2.5
			m.damping_min = 2.0
			m.damping_max = 3.0
			m.gravity = Vector3(0, 0.3, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			_size(m, 0.7, 1.2, &"grow")
			var dust := Color(0.62, 0.57, 0.5).srgb_to_linear()
			m.color_ramp = _ramp([Color(dust, 0.0), Color(dust, 0.55), Color(dust, 0.0)])
		&"volley_dust":
			# Ground dust slapped outward by the volley.
			_shape_ring(m, 1.2, 0.1)
			m.direction = Vector3.UP
			m.spread = 25.0
			m.initial_velocity_min = 0.5
			m.initial_velocity_max = 1.2
			m.radial_velocity_min = 4.0
			m.radial_velocity_max = 7.0
			m.damping_min = 3.0
			m.damping_max = 4.0
			m.gravity = Vector3(0, 0.2, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			_size(m, 0.6, 1.0, &"grow")
			m.color_initial_ramp = _ramp(_lin([Color(0.58, 0.50, 0.38), Color(0.5, 0.43, 0.32), Color(0.64, 0.57, 0.46)]))
			m.color_ramp = _ramp([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0.0)])
		&"volley_sparks":
			_shape_ring(m, 0.8, 0.3)
			m.direction = Vector3.UP
			m.spread = 15.0
			m.initial_velocity_min = 0.5
			m.initial_velocity_max = 1.5
			m.radial_velocity_min = 6.0
			m.radial_velocity_max = 10.0
			m.damping_min = 3.0
			m.damping_max = 5.0
			m.gravity = Vector3(0, -4.0, 0)
			m.particle_flag_align_y = true
			_size(m, 0.05, 0.07, &"shrink")
			m.color_ramp = _ramp([white, hot, glow, deep])
	_pmats[key] = m
	return m


func _shape_ring(m: ParticleProcessMaterial, r: float, h: float) -> void:
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	m.emission_ring_axis = Vector3.UP
	m.emission_ring_radius = r
	m.emission_ring_inner_radius = r * 0.85
	m.emission_ring_height = h


func _shape_sphere(m: ParticleProcessMaterial, r: float) -> void:
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = r


## Particle sizes in metres + a scale curve: shrink (sparks), grow (dust), hold (chips).
func _size(m: ParticleProcessMaterial, lo: float, hi: float, kind: StringName) -> void:
	m.scale_min = lo
	m.scale_max = hi
	match kind:
		&"grow":
			m.scale_curve = _curve([Vector2(0.0, 0.3), Vector2(0.3, 1.0), Vector2(1.0, 0.5)])
		&"hold":
			m.scale_curve = _curve([Vector2(0.0, 1.0), Vector2(0.8, 1.0), Vector2(1.0, 0.4)])
		_:
			m.scale_curve = _curve([Vector2(0.0, 1.0), Vector2(1.0, 0.15)])


func _curve(points: Array) -> CurveTexture:
	var c := Curve.new()
	for p: Vector2 in points:
		c.add_point(p)
	var ct := CurveTexture.new()
	ct.curve = c
	return ct


func _lin(colors: Array) -> Array:
	var out: Array = []
	for c: Color in colors:
		out.append(c.srgb_to_linear())
	return out


func _ramp(colors: Array) -> GradientTexture1D:
	var offsets: Array = []
	for i in colors.size():
		offsets.append(float(i) / float(colors.size() - 1))
	return _ramp_at(offsets, colors)


func _ramp_at(offsets: Array, colors: Array) -> GradientTexture1D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(offsets)
	g.colors = PackedColorArray(colors)
	var t := GradientTexture1D.new()
	t.gradient = g
	t.use_hdr = true
	return t
