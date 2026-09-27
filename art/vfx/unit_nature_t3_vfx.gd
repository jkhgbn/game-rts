class_name UnitNatureT3Vfx
extends Node3D
## Nature tier-3 unit effects (task 13b.V9, docs/design/tier3-extras.md 7 / 12 / 13): the Glade Outrider's Parting Shots
## and the Mossback's Canopy. An effect FAMILY of UnitVfx (art/vfx/unit_vfx.gd loads this file and forwards the ids
## below); callers never reach it directly:
##   var vfx := get_tree().get_first_node_in_group(&"unit_vfx")
##   if vfx: vfx.play(&"canopy_block", hit_point, attacker)
## It can also live on its own (a test level). Draw-only: it never touches gameplay.
##
## Ids and their arguments (`target` may always be null):
##   parting_shot  at = the shot origin: a Vector3 (world), OR the Outrider (its Unit or its GladeOutriderModel: the
##                 model's get_arrow_origin() is used, through Unit.get_model() too).
##                 target = the victim (Node3D: tracked like Projectile, landing at its body / a building's wall),
##                 a Vector3 world point, a Dictionary {dir: Vector3, range: float (10)} (free flight), or null (the
##                 shooter's attack_target, else straight ahead 10 m). A leaf-fletched arrow with a glowing lime
##                 seed head and a lime trail flies the Projectile arc (arc 0.6, speed = the shooter's
##                 UnitType.projectile_speed, else 25 m/s, so it rides the gameplay bolt); a green snap at the bow,
##                 glints along the shot, a leaf shaken off; a small leaf-green spark where it lands.
##   kite_dust     at = the Outrider (Node3D: the dust follows it as it bolts; its feet) or a Vector3 (ground point).
##                 target = the threat it runs from (Node3D / Vector3: the dust and clods are kicked back toward it)
##                 or null (all around). Hoof skid scuff, a burst of tan dust, clods, leaves kicked up, and a
##                 second dust puff 0.2 s later where the stag has got to.
##   canopy_pulse  at = the Mossback (Unit or MossbackModel: follows it, the grove crowns from get_canopy_points()) or
##                 a Vector3 (centre). target = the aura radius (float, default 6, clamped 2-10) or a Dictionary
##                 {radius, team, force}. A lime wave rolls out to the rim in 0.7 s under a dappled leaf shade, a ring
##                 of leaves sprouts along r 6 and flashes, glowing leaves spray from the grove out to the rim and
##                 swirl up along it, the three crowns glow once. 1.9 s. Self-throttled: one pulse per Mossback per
##                 PULSE_INTERVAL (4 s) — callers may call it on every aura tick; `force` skips the throttle.
##   canopy_block  at = where a reduced shot lands: a Vector3, or the victim (Node3D: the side of its body facing the
##                 shooter). target = the shooter / where the shot came from (Node3D / Vector3) or null. A small
##                 leaf-shield spark: a lime leaf-star, an upright ripple ring facing the shot, glowing leaf chips
##                 flicked back toward the shooter. 0.4 s. Cheap: meant for every ranged hit on a unit under Canopy.
## Auto-attach (`auto_attach`, default true): once per second the family looks at the "units" group for models with
## the 13b.V3 / 13b.V4 hooks. An Outrider model's arrow_released(from, dir) plays parting_shot (target = the owning
## unit's attack_target); a Mossback model whose is_canopy() is true and whose crowns have spread (canopy_blend() >= 0.6)
## pulses every 4 s while its unit lives. attach(model) does the same for a model outside a unit (previews, tests).
## Double calls are safe: a parting_shot from the same Outrider within 0.25 s of another is dropped (a bare Vector3
## origin: within 1.5 m of a recent loose),
## and canopy_pulse throttles per Mossback, so gameplay may also call both ids itself.
## Fog: effects of the local team always show; others only where the local team sees (FogOfWar.is_visible), checked 4
## times per second (arrows at their current position).
## Budget: everything is pre-built at _ready and pooled (ground marks, canopy discs, flares, rings, arrows, one-shot
## bursts). One material per shader, looks set with instance uniforms: no node, material or mesh is created after
## _ready. No lights, no shadows. Particle bursts are not drawn beyond 45 m from the camera (visibility range) and not
## even started there; at most BURSTS_PER_FRAME new bursts per frame (optional glints / leaves are dropped first).
## Shaders: own unit_nature_t3_arrow (the arrow), unit_nature_t3_canopy (the pulse floor); reused read-only: vfx_ring
## (block ripple), champion_ground (dust scuff), champion_flare (flashes), combat_streak (glints).

const GROUP := &"unit_nature_t3_vfx"
const EFFECTS: Array[StringName] = [&"parting_shot", &"kite_dust", &"canopy_pulse", &"canopy_block"]

# Palette: art-keep.md 0.2 Nature glow #BFFF66, team #59B340, cloth shadow #266626; the Outrider's arrow (0.75, 1.0, 0.4).
const NATURE_GLOW := Color(0.75, 1.0, 0.40)
const NATURE_TEAM := Color(0.35, 0.70, 0.25)
const NATURE_DEEP := Color(0.15, 0.40, 0.15)
const LEAF_PALE := Color(0.92, 1.0, 0.72)
const SEED_HOT := Color(1.0, 1.0, 0.82)
const DUST := Color(0.62, 0.55, 0.42)
const DUST_DARK := Color(0.40, 0.33, 0.23)
const CLOD := Color(0.30, 0.22, 0.13)
const LEAF_GREEN := Color(0.36, 0.56, 0.18)
const LEAF_DRY := Color(0.62, 0.52, 0.22)

# Numbers from tier3-extras.md 3 / 7 / 13 and scripts/units/projectile.gd.
const CANOPY_RADIUS := 6.0
const PULSE_INTERVAL := 4.0
const PULSE_TIME := 1.9
const ARROW_SPEED := 25.0          # Unit.DEFAULT_BOLT_SPEED (Projectile.launch_at_target default)
const ARROW_ARC := 0.6             # Projectile.launch_at_target default arc
const ARROW_RANGE := 10.0          # free flight length (Outrider attack range 10)
const ARROW_LEN := 0.95
const ARROW_WIDTH := 0.26
const TRAIL_LEN := 2.6
const SHOT_DEDUPE_TIME := 0.25
const SHOT_DEDUPE_DIST := 1.5
const PARTICLE_RANGE := 45.0       # no particles beyond this distance from the camera
const BURSTS_PER_FRAME := 24

const END_FADE := 0.2
const CHECK_INTERVAL := 0.25
const FOG_RESCAN := 1.0
const ATTACH_SCAN := 1.0
const CANOPY_CHECK := 0.25

enum { A_POINT, A_TARGET, A_WORLD }
enum { G_SHOCK, G_WIND, G_HEAL, G_ROPE, G_GLOW, G_SOOT, G_WARD }   # champion_ground.gdshader patterns

## Mesh pools (pre-built): pool -> size.
const POOL_SIZES := {&"disc": 16, &"canopy": 8, &"ring": 32, &"flare": 80, &"arrow": 24}
## One-shot bursts: look -> [amount, lifetime, draw pass, pool size, explosiveness, visibility half-extent (m)].
const BURSTS := {
	&"release_glints": [6, 0.3, &"streak", 12, 1.0, 5.0],
	&"release_leaf": [2, 1.1, &"mix_leaf", 12, 0.9, 5.0],
	&"arrow_hit": [7, 0.4, &"add_leaf", 12, 1.0, 5.0],
	&"kite_dust": [14, 1.2, &"mix_smoke", 8, 0.9, 5.0],
	&"kite_trail": [8, 0.95, &"mix_smoke", 8, 0.85, 5.0],
	&"kite_clods": [10, 0.7, &"mix_chip", 8, 1.0, 5.0],
	&"kite_leaves": [5, 1.3, &"mix_leaf", 8, 1.0, 5.0],
	&"canopy_spray": [30, 1.3, &"add_leaf", 6, 0.85, 9.0],
	&"canopy_ring": [44, 1.5, &"add_leaf", 6, 0.75, 9.0],
	&"block_leaves": [6, 0.45, &"add_leaf", 16, 1.0, 5.0],
}
## Bursts dropped first when a frame starts too many (the flashes, rings and arrows always stay).
const OPTIONAL_BURSTS: Array[StringName] = [&"release_glints", &"release_leaf", &"arrow_hit", &"kite_leaves",
		&"block_leaves"]

const GROUND_SHADER := preload("res://art/vfx/champion_ground.gdshader")
const FLARE_SHADER := preload("res://art/vfx/champion_flare.gdshader")
const STREAK_SHADER := preload("res://art/vfx/combat_streak.gdshader")
const RING_SHADER := preload("res://art/vfx/vfx_ring.gdshader")
const ARROW_SHADER := preload("res://art/vfx/unit_nature_t3_arrow.gdshader")
const CANOPY_SHADER := preload("res://art/vfx/unit_nature_t3_canopy.gdshader")


## One running effect: pooled pieces + scheduled one-shot bursts (+ an arrow in flight for parting_shot).
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
	var follow: Node3D = null        # the anchor follows this node (its feet) while it lives
	var pieces: Array[Piece] = []
	var bursts: Array[Dictionary] = []
	var bursts_left := 0
	var arrow: Arrow = null


## One pooled mesh of an effect (see TradeVfx.Piece), plus a rotation `rot` (upright rings).
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
	var age_until := 1.05             # `age` is sent while the piece is younger than this
	var lf := -1.0
	var lr := -1.0


## An arrow in flight (the Projectile arc: lerp + sin(k * PI) * arc).
class Arrow:
	extends RefCounted
	var n: GeometryInstance3D
	var from := Vector3.ZERO
	var to := Vector3.ZERO
	var target: Node3D = null
	var toff := Vector3.UP
	var dur := 0.4
	var t := 0.0
	var arc := ARROW_ARC
	var landed := false
	var head := Vector3.ZERO
	var lf := -1.0


var auto_attach := true              ## Connect to Outrider / Mossback models found in the "units" group.

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
var _rng := RandomNumberGenerator.new()

# Auto-attach and throttles.
var _scan_left := 0.0
var _seen_units: Dictionary = {}     # unit instance id -> true (its model was looked at)
var _canopy_models: Array[Node3D] = []
var _canopy_check_left := 0.0
var _last_pulse: Dictionary = {}     # anchor (model) instance id -> clock of its last pulse
var _recent_shots: Array[Dictionary] = []   # {key, pos, t}


func _ready() -> void:
	add_to_group(GROUP)
	top_level = true
	global_transform = Transform3D.IDENTITY
	_rng.seed = 1309
	_build_shared()


func _process(delta: float) -> void:
	_clock += delta
	_bursts_this_frame = 0
	_cam = get_viewport().get_camera_3d() if get_viewport() else null
	_fog_left -= delta
	if _fog_left <= 0.0:
		_fog_left = FOG_RESCAN
		_fog = get_tree().get_first_node_in_group(&"fog")
	if auto_attach:
		_scan_left -= delta
		if _scan_left <= 0.0:
			_scan_left = ATTACH_SCAN
			_scan_units()
	_canopy_check_left -= delta
	if _canopy_check_left <= 0.0:
		_canopy_check_left = CANOPY_CHECK
		_auto_canopy()
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


# ---------------------------------------------------------------- public API

## True for the ids this family draws.
func handles(id: StringName) -> bool:
	return EFFECTS.has(id)


## Plays effect `id` (see the header for the arguments). Returns true when `id` is one of EFFECTS (handled, even if
## fog hides it, a throttle drops it or a pool is full), false for any other id (nothing happens).
func play(id: StringName, at: Variant, target: Variant = null) -> bool:
	if not EFFECTS.has(id):
		return false
	if not is_node_ready() or not is_inside_tree():
		return true
	match id:
		&"parting_shot": _parting_shot(at, target)
		&"kite_dust": _kite_dust(at, target)
		&"canopy_pulse": _canopy_pulse(at, target)
		&"canopy_block": _canopy_block(at, target)
	return true


## Number of running effects (an arrow counts until it has landed and its spark is over).
func active_count() -> int:
	return _fx.size()


## Ids of the running effects.
func active_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for fx in _fx:
		out.append(fx.id)
	return out


## Pooled pieces (arrows included) still on screen + bursts still alive (0 once everything has ended).
func live_count() -> int:
	var n := _live_bursts.size()
	for pool: StringName in _all:
		for g: GeometryInstance3D in _all[pool]:
			if g.visible:
				n += 1
	return n


## Arrows in flight (tests, debug).
func arrow_count() -> int:
	var n := 0
	for fx in _fx:
		if fx.arrow and not fx.arrow.landed:
			n += 1
	return n


## World positions of the arrow heads in flight (tests, debug).
func arrow_heads() -> PackedVector3Array:
	var out := PackedVector3Array()
	for fx in _fx:
		if fx.arrow and not fx.arrow.landed:
			out.append(fx.arrow.head)
	return out


## Hooks this family to a model outside the "units" group (previews, tests): an Outrider model's arrow_released plays
## parting_shot; a Mossback model pulses every 4 s while its canopy is spread. Safe to call twice.
func attach(model: Node3D) -> void:
	if model == null or not is_instance_valid(model):
		return
	if model.has_signal(&"arrow_released"):
		var cb := _on_arrow_released.bind(model)
		if not model.is_connected(&"arrow_released", cb):
			model.connect(&"arrow_released", cb)
	if model.has_method(&"is_canopy") and model.has_method(&"canopy_blend") and not _canopy_models.has(model):
		_canopy_models.append(model)


## Mossback models whose canopy pulse this family drives (tests).
func attached_canopy_count() -> int:
	var n := 0
	for m in _canopy_models:
		if is_instance_valid(m):
			n += 1
	return n


# ---------------------------------------------------------------- the effects

## `shooter_model` = the Outrider model when known apart from `at` (the signal path: `at` is then its Vector3 origin).
func _parting_shot(at: Variant, target: Variant, shooter_model: Node3D = null) -> void:
	var shooter := _node(at)
	var model := shooter_model if shooter_model else _model_or_self(shooter)
	var origin: Variant = null
	if at is Vector3:
		origin = at
	elif shooter:
		for src: Object in [shooter, model]:
			if src and is_instance_valid(src) and src.has_method(&"get_arrow_origin"):
				var v: Variant = src.call(&"get_arrow_origin")
				if v is Vector3:
					origin = v
					break
		if origin == null:
			origin = shooter.global_position + Vector3.UP * _h(shooter) * 0.75   # Unit._shot_origin
	if origin == null:
		return
	var from: Vector3 = origin
	# Two calls for one loose (the model's signal + gameplay): keep the first.
	var key: int = model.get_instance_id() if model else 0
	for s in _recent_shots:
		if _clock - float(s["t"]) > SHOT_DEDUPE_TIME:
			continue
		var other := int(s["key"])
		if key != 0 and other != 0:
			if other == key:
				return   # the same Outrider's loose, reported twice
		elif (s["pos"] as Vector3).distance_to(from) < SHOT_DEDUPE_DIST:
			return   # a bare origin next to a recent loose
	_recent_shots.append({"key": key, "pos": from, "t": _clock})
	if _recent_shots.size() > 24:
		_recent_shots = _recent_shots.filter(func(s: Dictionary) -> bool: return _clock - float(s["t"]) <= SHOT_DEDUPE_TIME)
	# Where it flies.
	var owner_unit := _owner_unit(shooter if shooter else model)
	var aim_node: Node3D = _node(target)
	var dest: Variant = null
	var dir: Variant = null
	var reach := ARROW_RANGE
	if aim_node == null:
		if target is Vector3:
			dest = target
		elif target is Dictionary:
			var d: Dictionary = target
			if d.get("dir") is Vector3:
				dir = d["dir"]
			reach = clampf(float(d.get("range", reach)), 1.0, 40.0)
		elif owner_unit:
			var t: Variant = owner_unit.get(&"attack_target")
			if typeof(t) == TYPE_OBJECT and is_instance_valid(t) and t is Node3D and (t as Node3D).is_inside_tree():
				aim_node = t
	var toff := Vector3.UP
	if aim_node:
		toff = _aim_offset(aim_node, from)
		dest = aim_node.global_position + toff
	if dest == null:
		var fwd := Vector3.FORWARD
		if dir is Vector3 and (dir as Vector3).length_squared() > 0.01:
			fwd = (dir as Vector3).normalized()
		elif shooter:
			fwd = shooter.global_basis.z
			fwd.y = 0.0
			fwd = fwd.normalized() if fwd.length_squared() > 0.001 else Vector3.FORWARD
		var end := from + fwd * reach
		end.y = minf(end.y, from.y - 0.6)   # a free arrow drops toward the ground at the end of its flight
		dest = end
	var to: Vector3 = dest
	var speed := ARROW_SPEED
	var ut: Variant = owner_unit.get(&"unit_type") if owner_unit else null
	if ut is Object and is_instance_valid(ut):
		var ps: Variant = (ut as Object).get(&"projectile_speed")
		if ps != null and float(ps) > 0.0:
			speed = float(ps)
	var fx := _new_fx(&"parting_shot", from, _team_of(owner_unit if owner_unit else shooter))
	var ar := Arrow.new()
	ar.from = from
	ar.to = to
	ar.target = aim_node
	ar.toff = toff
	ar.dur = maxf(0.15, from.distance_to(to) / speed)   # Projectile._setup
	ar.head = from
	var free: Array = _free[&"arrow"]
	if not free.is_empty():
		ar.n = free.pop_back()
		ar.n.set_instance_shader_parameter(&"seed", _rng.randf() * 10.0)
		ar.n.set_instance_shader_parameter(&"tint", _hdr(NATURE_GLOW, 2.2))
		ar.n.set_instance_shader_parameter(&"fade", 0.0)
	fx.arrow = ar
	fx.tpos = to
	fx.dur = ar.dur + 0.3
	var shot_dir := (to - from).normalized() if to.distance_to(from) > 0.05 else Vector3.FORWARD
	# The loose: a green snap at the bow, glints along the shot, a leaf shaken off the bow.
	_flare(fx, A_WORLD, from, _hdr(NATURE_GLOW, 2.0), 0.35, 0.7, 0.05, 0.0, 0.14, 0.0, 0.09, 0.8, 6.0)
	_flare(fx, A_WORLD, from + shot_dir * 0.25, _hdr(SEED_HOT, 1.4), 0.2, 0.32, 0.04, 0.0, 0.08, 0.0, 0.05)
	_sched(fx, &"release_glints", 0.0, A_WORLD, from + shot_dir * 0.1, 1.0, _z_along(shot_dir))
	_sched(fx, &"release_leaf", 0.02, A_WORLD, from + Vector3.DOWN * 0.1)
	_start(fx)


## The owning unit's hit point on `n`, like Projectile.launch_at_target: a Unit's body (1 m up), a building's wall
## facing the shooter (1.5 m up).
func _aim_offset(n: Node3D, from: Vector3) -> Vector3:
	if not _is_building(n):
		return Vector3.UP
	var off := Vector3.UP * 1.5
	var away := from - n.global_position
	away.y = 0.0
	if away.length() > 0.01:
		var reach := 2.0
		if n.has_method(&"target_radius"):
			reach = float(n.call(&"target_radius"))
		off += away.normalized() * reach * 0.8
	return off


func _kite_dust(at: Variant, target: Variant) -> void:
	var runner := _node(at)
	var point: Variant = _point_of(at, 0.0)
	if point == null:
		return
	var c: Vector3 = point
	var fx := _new_fx(&"kite_dust", c, _team_of(runner))
	fx.follow = runner
	fx.dur = 1.5
	# Kicked back toward the threat (flat), else all around.
	var back: Variant = _dir_to(c, target)
	var basis := Basis.IDENTITY
	if back != null:
		var b: Vector3 = back
		basis = _z_along((b + Vector3.UP * 0.35).normalized())
	var up := Vector3.UP
	var scuff := _disc(fx, A_WORLD, G_SOOT, DUST.srgb_to_linear(), 0.8, 1.6, 0.2, 0.0, 1.5, 0.05, 0.8)
	if scuff:
		scuff.ofs += c
		scuff.o0 += c
		if back != null:
			var sb: Vector3 = back
			scuff.o0 += sb * 0.3
			scuff.ofs += sb * 0.6
	_sched(fx, &"kite_dust", 0.0, A_WORLD, c + up * 0.15, 1.0, basis)
	_sched(fx, &"kite_clods", 0.0, A_WORLD, c + up * 0.2, 1.0, basis)
	_sched(fx, &"kite_leaves", 0.03, A_WORLD, c + up * 0.2, 1.0, basis)
	# The second puff follows the stag (A_POINT = its feet at 0.2 s).
	_sched(fx, &"kite_trail", 0.2, A_POINT, up * 0.15, 1.0, basis)
	_start(fx)


func _canopy_pulse(at: Variant, target: Variant) -> void:
	var anchor := _node(at)
	var model := _model_or_self(anchor)
	var point: Variant = _point_of(at, 0.0)
	if point == null:
		return
	var radius := CANOPY_RADIUS
	var team := _team_of(anchor)
	var force := false
	if target is float or target is int:
		radius = float(target)
	elif target is Dictionary:
		var d: Dictionary = target
		radius = float(d.get("radius", radius))
		team = int(d.get("team", team))
		force = bool(d.get("force", false))
	radius = clampf(radius, 2.0, 10.0)
	if model:
		var key := model.get_instance_id()
		if not force and _last_pulse.has(key) and _clock - float(_last_pulse[key]) < PULSE_INTERVAL - 0.5:
			return
		_last_pulse[key] = _clock
	var c: Vector3 = point
	var fx := _new_fx(&"canopy_pulse", c, team)
	fx.follow = anchor
	fx.dur = PULSE_TIME
	var k := radius / CANOPY_RADIUS
	# The floor: wave, leaf shade, the leaf ring (own shader, animated by `age`).
	var floor_d := _piece(fx, &"canopy", A_POINT, Vector3.UP * 0.045, 0.0, PULSE_TIME, 0.08, 0.55)
	if floor_d:
		_grow(floor_d, Vector3(radius, 1.0, radius), Vector3(radius, 1.0, radius), 0.0)
		floor_d.age_until = PULSE_TIME + 0.1
		_params(floor_d, {&"tint": _hdr(NATURE_GLOW, 1.1), &"shade": Color(0.02, 0.07, 0.02, 0.24),
				&"seed": _rng.randf() * 10.0, &"age": 0.0})
	# A thin shock line racing ahead of the wave (reads at 40 m; no inner glow: a big ring blooms into a lime floor).
	_ring(fx, A_POINT, _hdr(NATURE_GLOW, 1.1), 1.2 * k, radius, 0.7, 0.0, 0.9, 0.0, 0.3, 0.03, 0.05)
	# The grove breathes: a soft glow on each crown.
	var crowns := PackedVector3Array()
	if model and model.has_method(&"get_canopy_points"):
		var v: Variant = model.call(&"get_canopy_points")
		if v is PackedVector3Array:
			crowns = v
	if crowns.is_empty():
		crowns.append(c + Vector3.UP * 2.6)
	var top := Vector3.ZERO
	for p in crowns:
		_flare(fx, A_POINT, p - c, _hdr(NATURE_GLOW, 0.9), 0.7, 1.25, 0.2, 0.0, 0.5, 0.06, 0.3)
		top += p
	top /= float(crowns.size())
	_sched(fx, &"canopy_spray", 0.02, A_POINT, top - c, k)
	_sched(fx, &"canopy_ring", 0.5, A_POINT, Vector3.UP * 0.2, k)
	_start(fx)


func _canopy_block(at: Variant, target: Variant) -> void:
	var victim := _node(at)
	var src: Variant = _point_of(target, 0.55)
	var point: Variant = null
	if at is Vector3:
		point = at
	elif victim:
		point = _chest(victim)
		if src != null:
			var flat: Vector3 = (src as Vector3) - (point as Vector3)
			flat.y = 0.0
			if flat.length_squared() > 0.01:
				point = (point as Vector3) + flat.normalized() * _radius(victim) * 0.9
	if point == null:
		return
	var p: Vector3 = point
	var fx := _new_fx(&"canopy_block", p, _team_of(victim))
	fx.dur = 0.45
	var toward := Vector3.UP
	if src != null and (src as Vector3).distance_to(p) > 0.05:
		toward = ((src as Vector3) - p).normalized()
	# Leaf-star glint (6 points) + a pale core.
	_flare(fx, A_POINT, toward * 0.05, _hdr(NATURE_GLOW, 1.6), 0.35, 0.7, 0.06, 0.0, 0.24, 0.0, 0.15, 1.0, 6.0)
	_flare(fx, A_POINT, toward * 0.08, _hdr(LEAF_PALE, 1.3), 0.16, 0.28, 0.04, 0.0, 0.1, 0.0, 0.06)
	# An upright ripple facing the shot: the leaf shield it struck (a thin band, no fill: never hides the unit).
	var ring := _ring(fx, A_POINT, _hdr(NATURE_GLOW, 1.5), 0.14, 0.46, 0.14, 0.0, 0.32, 0.0, 0.2, 0.14, 0.12)
	if ring:
		ring.rot = _y_along(toward)
		ring.o0 = toward * 0.06
		ring.ofs = toward * 0.14
		_params(ring, {&"fill": Color(0.02, 0.05, 0.01, 0.0)})
	_sched(fx, &"block_leaves", 0.0, A_POINT, toward * 0.1, 1.0, _z_along((toward + Vector3.UP * 0.4).normalized()))
	_start(fx)


# ---------------------------------------------------------------- auto-attach

func _scan_units() -> void:
	if _seen_units.size() > 4000:
		_seen_units.clear()
	for u: Node in get_tree().get_nodes_in_group(&"units"):
		var id := u.get_instance_id()
		if _seen_units.has(id) or not u.has_method(&"get_model"):
			continue
		var m: Variant = u.call(&"get_model")
		if not (m is Node3D) or not is_instance_valid(m):
			continue   # no model yet: looked at again next scan
		_seen_units[id] = true
		attach(m)


## An attached Outrider model loosed an arrow: parting_shot from the signal's origin toward the owning unit's
## attack_target (else along `dir`). The model is the dedupe key, so a gameplay call for the same shot is dropped.
func _on_arrow_released(from: Vector3, dir: Vector3, model: Node3D) -> void:
	if not is_inside_tree() or not is_instance_valid(model) or not model.is_visible_in_tree():
		return
	var owner_unit := _owner_unit(model)
	var target: Variant = null
	if owner_unit:
		var t: Variant = owner_unit.get(&"attack_target")
		if typeof(t) == TYPE_OBJECT and is_instance_valid(t) and t is Node3D and (t as Node3D).is_inside_tree():
			target = t
	if target == null:
		target = {"dir": dir, "range": ARROW_RANGE}
	_parting_shot(from, target, model)


func _auto_canopy() -> void:
	if _last_pulse.size() > 256:
		for key: int in _last_pulse.keys():
			if _clock - float(_last_pulse[key]) > PULSE_INTERVAL * 2.0:
				_last_pulse.erase(key)
	for i in range(_canopy_models.size() - 1, -1, -1):
		var m := _canopy_models[i]
		if not is_instance_valid(m):
			_canopy_models.remove_at(i)
			continue
		if not m.is_inside_tree() or not m.is_visible_in_tree():
			continue
		if not bool(m.call(&"is_canopy")) or float(m.call(&"canopy_blend")) < 0.6:
			continue
		var u := _owner_unit(m)
		if u and u.has_method(&"is_alive") and not bool(u.call(&"is_alive")):
			continue
		var key := m.get_instance_id()
		if _last_pulse.has(key) and _clock - float(_last_pulse[key]) < PULSE_INTERVAL:
			continue
		_canopy_pulse(m, null)


# ---------------------------------------------------------------- argument helpers

## The model of a unit (Unit.get_model()), else the node itself; null for null.
func _model_or_self(n: Node3D) -> Node3D:
	if n == null:
		return null
	if n.has_method(&"get_model"):
		var m: Variant = n.call(&"get_model")
		if m is Node3D and is_instance_valid(m):
			return m
	return n


## The unit that owns `n` (itself, or up to 3 parents: a model sits under Unit._visual): the first with attack_target.
func _owner_unit(n: Node) -> Node3D:
	var cur := n
	for i in 4:
		if cur == null:
			return null
		if cur is Node3D and &"attack_target" in cur:
			return cur as Node3D
		cur = cur.get_parent()
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


## `team` of the node or of one of its 3 parents (a model under Unit._visual), else -1.
func _team_of(v: Variant) -> int:
	var n: Node = _node(v)
	for i in 4:
		if n == null:
			return -1
		var team: Variant = n.get(&"team")
		if team != null:
			return int(team)
		n = n.get_parent()
	return -1


func _is_building(n: Node3D) -> bool:
	if n == null:
		return false
	return n.is_in_group(&"buildings") or n.get(&"building_type") != null


func _h(n: Variant) -> float:
	if not is_instance_valid(n):
		return 1.6
	var h: Variant = (n as Object).get(&"body_height")
	return float(h) if h != null else 1.6


func _radius(n: Node3D) -> float:
	var r: Variant = n.get(&"radius")
	return clampf(float(r), 0.2, 2.5) if r != null else 0.45


## Basis whose +Y is `d` (upright rings: meshes whose normal is local Y).
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


# ---------------------------------------------------------------- effect runtime (UnitFireGunVfx pattern)

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
	if fx.follow:
		if is_instance_valid(fx.follow) and fx.follow.is_inside_tree():
			fx.point = fx.follow.global_position
		else:
			fx.follow = null
	if fx.arrow:
		_tick_arrow(fx, delta)
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
	return fx.t >= fx.dur and fx.bursts_left <= 0 and (fx.arrow == null or fx.arrow.landed)


## Moves the arrow along the Projectile arc; on landing, hides it and adds the landing spark.
func _tick_arrow(fx: Fx, delta: float) -> void:
	var ar := fx.arrow
	if ar.landed:
		return
	ar.t += delta
	if ar.target:
		if is_instance_valid(ar.target) and ar.target.is_inside_tree() and _alive(ar.target):
			ar.to = ar.target.global_position + ar.toff
		else:
			ar.target = null
	var k := clampf(ar.t / ar.dur, 0.0, 1.0)
	var pos := ar.from.lerp(ar.to, k) + Vector3.UP * sin(k * PI) * ar.arc
	ar.head = pos
	if k >= 1.0:
		ar.landed = true
		fx.tpos = ar.to
		if ar.n:
			ar.n.visible = false
		if fx.shown:
			var back := (ar.from - ar.to)
			back = back.normalized() if back.length_squared() > 0.01 else Vector3.UP
			_flare(fx, A_TARGET, back * 0.1, _hdr(NATURE_GLOW, 1.7), 0.4, 0.75, 0.05, fx.t, fx.t + 0.22, 0.0, 0.14, 0.8, 6.0)
			_flare(fx, A_TARGET, back * 0.15, _hdr(SEED_HOT, 1.3), 0.18, 0.3, 0.04, fx.t, fx.t + 0.1, 0.0, 0.06)
			_burst(&"arrow_hit", ar.to + back * 0.1, 1.0, _z_along((back + Vector3.UP * 0.5).normalized()))
		fx.dur = maxf(fx.dur, fx.t + 0.2)
		return
	if ar.n == null:
		return
	var vel := (ar.to - ar.from) / ar.dur + Vector3.UP * cos(k * PI) * PI * ar.arc / ar.dur
	var d := vel.normalized() if vel.length_squared() > 0.0001 else Vector3.FORWARD
	var flown := ar.from.distance_to(ar.to) * k
	var trail := minf(TRAIL_LEN, maxf(flown - ARROW_LEN * 0.3, 0.0))
	var total := ARROW_LEN + trail
	var x := d.cross(Vector3.UP)
	x = x.normalized() if x.length_squared() > 0.0001 else Vector3.RIGHT
	var z := x.cross(d).normalized()
	ar.n.transform = Transform3D(Basis(x * ARROW_WIDTH, d * total, z), pos - d * (total * 0.5))
	ar.n.set_instance_shader_parameter(&"arrow_frac", ARROW_LEN / total)
	var f := clampf(ar.t / 0.03, 0.0, 1.0)
	if absf(f - ar.lf) > 0.003:
		ar.lf = f
		ar.n.set_instance_shader_parameter(&"fade", f)
	var vis := fx.shown
	if ar.n.visible != vis:
		ar.n.visible = vis


static func _alive(node: Node3D) -> bool:
	if node.has_method(&"is_alive"):
		return bool(node.call(&"is_alive"))
	return true


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
	if lt <= d.age_until and d.pool != &"ring":   # vfx_ring has no `age`
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
	if fx.arrow and fx.arrow.n:
		fx.arrow.n.visible = false
		fx.arrow.n.set_instance_shader_parameter(&"fade", 0.0)
		(_free[&"arrow"] as Array).append(fx.arrow.n)
		fx.arrow.n = null


func _refresh(fx: Fx) -> void:
	var at := fx.point
	if fx.arrow:
		at = fx.arrow.head
	fx.shown = _fog_ok(fx.team, at)


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
	d.is_disc = pool == &"disc" or pool == &"canopy"
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


## Thin ring (vfx_ring.gdshader: a glowing band, no fill) growing from radius r0 to r1; `width` = band width as a
## fraction of the radius, `glow` = the soft light trailing inside the band.
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
	p.transform = Transform3D(basis * Basis.from_scale(Vector3.ONE * clampf(size, 0.3, 2.0)), pos)
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


# ---------------------------------------------------------------- shared resources (built once)

func _build_shared() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(2.0, 2.0)
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	var meshes := {&"disc": plane, &"canopy": plane, &"ring": plane, &"flare": quad, &"arrow": quad}
	var mats := {&"disc": _shader_mat(GROUND_SHADER), &"canopy": _shader_mat(CANOPY_SHADER),
			&"ring": _shader_mat(RING_SHADER), &"flare": _shader_mat(FLARE_SHADER), &"arrow": _shader_mat(ARROW_SHADER)}
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
			if pool == &"flare" or pool == &"arrow":
				m.extra_cull_margin = 4.0   # billboards / axial quads leave their mesh AABB
			add_child(m)
			arr.append(m)
		_all[pool] = arr
		_free[pool] = arr.duplicate()
	_build_passes()
	for look: StringName in BURSTS:
		var spec: Array = BURSTS[look]
		var arr: Array = []
		for i in int(spec[3]):
			var p := _emitter(look, int(spec[0]), float(spec[1]), spec[2], float(spec[5]))
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


func _emitter(look: StringName, amount: int, lifetime: float, pass_id: StringName, half: float) -> GPUParticles3D:
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
	p.visibility_aabb = AABB(Vector3(-half, -3.0, -half), Vector3(half * 2.0, 8.0, half * 2.0))
	return p


## Draw passes: textured billboard quads (a shape mask each, billboard_keep_scale) + velocity-aligned streaks.
func _build_passes() -> void:
	_passes[&"add_leaf"] = _particle_quad(_shape_tex(&"leaf"), BaseMaterial3D.BLEND_MODE_ADD)
	_passes[&"mix_leaf"] = _particle_quad(_shape_tex(&"leaf"), BaseMaterial3D.BLEND_MODE_MIX)
	_passes[&"mix_chip"] = _particle_quad(_shape_tex(&"chip"), BaseMaterial3D.BLEND_MODE_MIX)
	_passes[&"mix_smoke"] = _particle_quad(_shape_tex(&"smoke"), BaseMaterial3D.BLEND_MODE_MIX)
	var streak := QuadMesh.new()
	var sm := ShaderMaterial.new()
	sm.shader = STREAK_SHADER
	sm.set_shader_parameter(&"stretch", 6.0)
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
		mat.proximity_fade_distance = 0.4
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
				&"leaf":
					# A pointed leaf (lens of two circles) along the diagonal, a darker midrib, lit on one half.
					var lu := (u + v) * 0.7071
					var lv := (v - u) * 0.7071
					var hl := 0.92
					var hw := 0.4
					var off := (hl * hl - hw * hw) / (2.0 * hw)
					var rad := off + hw
					var d := maxf(Vector2(lu, lv - off).length(), Vector2(lu, lv + off).length())
					a = clampf((rad - d) / 0.06, 0.0, 1.0)
					var rib := 1.0 - clampf((absf(lv) - 0.03) / 0.04, 0.0, 1.0)
					shade = clampf((0.9 if lv > 0.0 else 0.72) - rib * 0.3 + 0.08 * _vn(u * 5.0, v * 5.0), 0.3, 1.0)
				&"chip":
					# A dirt clod: a lumpy 6-sided polygon, lit top-left.
					var ang := atan2(v, u)
					var sides := 6.0
					var poly := cos(PI / sides) / cos(fmod(ang + TAU * 2.0 + 0.4, TAU / sides) - PI / sides)
					var edge := (0.72 + 0.1 * _vn(cos(ang) * 2.0 + 3.0, sin(ang) * 2.0)) * poly
					a = clampf((edge - r) / 0.07, 0.0, 1.0)
					shade = clampf(0.72 - 0.3 * (u + v) * 0.5 + 0.12 * _vn(u * 6.0, v * 6.0), 0.35, 1.0)
				&"smoke":
					var nse := _vn(u * 2.3 + 7.1, v * 2.3 + 3.3) * 0.6 + _vn(u * 5.1 + 1.7, v * 5.1 - 2.2) * 0.4
					a = clampf((1.0 - r) * 1.6 + (nse - 0.5) * 0.9 - 0.2, 0.0, 1.0)
					a = a * a * (3.0 - 2.0 * a) * clampf((1.0 - r) / 0.2, 0.0, 1.0)
					shade = clampf(0.82 + 0.14 * (0.5 - v * 0.5) + (nse - 0.5) * 0.25, 0.0, 1.0)
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
	var pale := _hdr(LEAF_PALE, 2.6)
	var glow := _hdr(NATURE_GLOW, 2.2)
	var team := _hdr(NATURE_TEAM, 1.6)
	var deep := _hdr(NATURE_DEEP, 1.0, 0.0)
	match key:
		&"release_glints":
			# Lime glints along the shot (+Z of the emitter), fast, short.
			_shape_sphere(m, 0.05)
			m.direction = Vector3(0, 0, 1)
			m.spread = 10.0
			m.initial_velocity_min = 7.0
			m.initial_velocity_max = 13.0
			m.damping_min = 8.0
			m.damping_max = 12.0
			m.gravity = Vector3(0, -2.0, 0)
			m.particle_flag_align_y = true
			_size(m, 0.035, 0.055, &"shrink")
			m.color_ramp = _ramp([pale, glow, team, deep])
		&"release_leaf":
			# A leaf or two shaken off the bow, fluttering down.
			_shape_sphere(m, 0.12)
			m.direction = Vector3.UP
			m.spread = 60.0
			m.initial_velocity_min = 0.6
			m.initial_velocity_max = 1.4
			m.damping_min = 1.5
			m.damping_max = 2.5
			m.gravity = Vector3(0, -1.6, 0)
			_spin(m, 360.0)
			_size(m, 0.16, 0.22, &"hold")
			m.color_initial_ramp = _ramp(_lin([LEAF_GREEN, NATURE_TEAM, LEAF_DRY]))
			m.color_ramp = _ramp([Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0.0)])
		&"arrow_hit":
			# Where the arrow lands: glowing leaf bits flicked back toward the shooter (+Z).
			_shape_sphere(m, 0.08)
			m.direction = Vector3(0, 0, 1)
			m.spread = 55.0
			m.initial_velocity_min = 2.0
			m.initial_velocity_max = 4.5
			m.damping_min = 3.0
			m.damping_max = 5.0
			m.gravity = Vector3(0, -5.0, 0)
			_spin(m, 540.0)
			_size(m, 0.12, 0.18, &"shrink")
			m.color_ramp = _ramp([pale, glow, team, deep])
		&"kite_dust":
			# Hoof dust kicked back toward the threat (+Z of the emitter) and around the stag's feet.
			_shape_ring(m, 0.6, 0.1)
			m.direction = Vector3(0, 0, 1)
			m.spread = 55.0
			m.initial_velocity_min = 1.8
			m.initial_velocity_max = 3.6
			m.radial_velocity_min = 0.6
			m.radial_velocity_max = 1.4
			m.damping_min = 2.5
			m.damping_max = 3.5
			m.gravity = Vector3(0, 0.35, 0)
			_spin(m, 60.0)
			_size(m, 0.75, 1.25, &"grow")
			m.color_initial_ramp = _ramp(_lin([DUST, Color(0.55, 0.48, 0.36), Color(0.68, 0.61, 0.48)]))
			m.color_ramp = _ramp_at([0.0, 0.15, 0.6, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.6),
					Color(1, 1, 1, 0.35), Color(1, 1, 1, 0.0)])
		&"kite_trail":
			_shape_sphere(m, 0.5)
			m.direction = Vector3(0, 0.3, 1)
			m.spread = 70.0
			m.initial_velocity_min = 0.8
			m.initial_velocity_max = 1.8
			m.damping_min = 2.0
			m.damping_max = 3.0
			m.gravity = Vector3(0, 0.3, 0)
			_spin(m, 60.0)
			_size(m, 0.6, 1.0, &"grow")
			m.color_initial_ramp = _ramp(_lin([DUST, Color(0.58, 0.5, 0.38)]))
			m.color_ramp = _ramp_at([0.0, 0.2, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0.0)])
		&"kite_clods":
			# Clods of earth thrown back by the hooves.
			_shape_sphere(m, 0.35)
			m.direction = Vector3(0, 0.5, 1)
			m.spread = 40.0
			m.initial_velocity_min = 3.0
			m.initial_velocity_max = 5.5
			m.gravity = Vector3(0, -15.0, 0)
			_spin(m, 500.0)
			_size(m, 0.1, 0.18, &"hold")
			m.color_initial_ramp = _ramp(_lin([CLOD, DUST_DARK, Color(0.24, 0.17, 0.1), LEAF_GREEN]))
			m.color_ramp = _ramp([Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0.0)])
		&"kite_leaves":
			# Fallen leaves kicked up, tumbling down.
			_shape_sphere(m, 0.4)
			m.direction = Vector3(0, 1, 0.5)
			m.spread = 40.0
			m.initial_velocity_min = 2.0
			m.initial_velocity_max = 3.5
			m.damping_min = 2.0
			m.damping_max = 3.0
			m.gravity = Vector3(0, -2.5, 0)
			_spin(m, 400.0)
			_size(m, 0.18, 0.26, &"hold")
			m.color_initial_ramp = _ramp(_lin([LEAF_DRY, LEAF_GREEN, Color(0.5, 0.36, 0.16)]))
			m.color_ramp = _ramp([Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0.0)])
		&"canopy_spray":
			# Glowing leaves blown from the grove out toward the rim (6 m in ~1.2 s), settling.
			_shape_sphere(m, 0.9)
			m.direction = Vector3.UP
			m.spread = 30.0
			m.initial_velocity_min = 0.5
			m.initial_velocity_max = 1.5
			m.radial_velocity_min = 4.5
			m.radial_velocity_max = 6.5
			m.damping_min = 2.2
			m.damping_max = 3.0
			m.gravity = Vector3(0, -1.2, 0)
			_spin(m, 300.0)
			_size(m, 0.2, 0.3, &"hold")
			m.color_ramp = _ramp_at([0.0, 0.1, 0.6, 1.0], [Color(pale, 0.0), glow, team, deep])
		&"canopy_ring":
			# Leaves sprouting along the rim (ring r 6 = the aura), swirling round it and rising, then gone.
			_shape_ring(m, CANOPY_RADIUS, 0.2)
			m.emission_ring_inner_radius = CANOPY_RADIUS * 0.94
			m.direction = Vector3.UP
			m.spread = 20.0
			m.initial_velocity_min = 0.4
			m.initial_velocity_max = 1.1
			m.tangential_accel_min = 2.5
			m.tangential_accel_max = 4.0
			m.damping_min = 0.5
			m.damping_max = 1.0
			m.gravity = Vector3(0, 0.5, 0)
			_spin(m, 240.0)
			_size(m, 0.22, 0.32, &"grow")
			m.color_ramp = _ramp_at([0.0, 0.15, 0.55, 1.0], [Color(pale, 0.0), glow, team, deep])
		&"block_leaves":
			# The leaf shield's chips flicked back toward the shooter (+Z), fading fast.
			_shape_sphere(m, 0.1)
			m.direction = Vector3(0, 0, 1)
			m.spread = 50.0
			m.initial_velocity_min = 2.0
			m.initial_velocity_max = 4.0
			m.damping_min = 4.0
			m.damping_max = 6.0
			m.gravity = Vector3(0, -3.0, 0)
			_spin(m, 600.0)
			_size(m, 0.12, 0.2, &"shrink")
			m.color_ramp = _ramp([pale, glow, team, deep])
	_pmats[key] = m
	return m


func _spin(m: ParticleProcessMaterial, deg_per_s: float) -> void:
	m.angle_min = -180.0
	m.angle_max = 180.0
	m.angular_velocity_min = -deg_per_s
	m.angular_velocity_max = deg_per_s


func _shape_ring(m: ParticleProcessMaterial, r: float, h: float) -> void:
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	m.emission_ring_axis = Vector3.UP
	m.emission_ring_radius = r
	m.emission_ring_inner_radius = r * 0.85
	m.emission_ring_height = h


func _shape_sphere(m: ParticleProcessMaterial, r: float) -> void:
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = r


## Particle sizes in metres + a scale curve: shrink (glints), grow (dust), hold (leaves, clods).
func _size(m: ParticleProcessMaterial, lo: float, hi: float, kind: StringName) -> void:
	m.scale_min = lo
	m.scale_max = hi
	match kind:
		&"grow":
			m.scale_curve = _curve([Vector2(0.0, 0.3), Vector2(0.3, 1.0), Vector2(1.0, 0.6)])
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
