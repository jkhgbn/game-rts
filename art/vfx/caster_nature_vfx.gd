class_name CasterNatureVfx
extends Node3D
## Bramblesage effects (task CU.V6, Nature part; docs/design/caster-units.md 5.3 / 10.5). An effect FAMILY of UnitVfx
## (art/vfx/unit_vfx.gd loads it once its path is listed in MODULES: the ui-coder wires that line and the calls);
## callers never reach it directly:
##   var vfx := get_tree().get_first_node_in_group(&"unit_vfx")
##   if vfx: vfx.play(&"snagroot", bramblesage, victim)
## It can also live on its own (a test level, the Art Lab `kind=vfx`). Draw-only: it never moves units (gameplay's
## Unit.displace drags the victim; the vine follows it).
## Ids (`target` may always be null):
##   snagroot     at = the Bramblesage (Node3D: its Unit or BramblesageModel; the vine leaves the crook's hook,
##                get_hook_position(), and stays tied to it) or a Vector3 (the hook point). target = the victim (Node3D:
##                tracked while gameplay drags it), a Vector3 (a point: the drag is simulated toward `at`), or a
##                Dictionary {to: Node3D / Vector3, drag: 7.0 (m, simulated drags only)}. A thorned briar vine whips out
##                of the hook and reaches the victim in 0.25 s (sap beads racing along it), wraps it (a lime snap, a
##                coil, leaves), goes taut and drags it (0.5 s, a furrow of torn earth grows behind the victim, clods
##                fly), lets go and whips back, and the victim is rooted 1 s (bark roots coil around its feet).
##   pollen_haze  at = the cloud's centre (Vector3; a Node3D = its position). target = the radius (float, 3.5), or a
##                Dictionary {radius: 3.5, time: 6.0, team: int}. A drifting straw-yellow pollen cloud (max 24 soft
##                puffs) with floating glowing motes over a pale veil on the ground with a thin rim, visible to both
##                teams; it thins out in the last second.
##   hazed        at = the hazed unit (Node3D: follows its head) or a Vector3 (a head point). target = the duration
##                (float, default 1.0; calling again on the same unit extends it). A ring of glowing pollen motes
##                turning around the head. Cheap: meant to be called on every haze refresh (0.25 s).
##   seedcloak    at = the Bramblesage (Node3D, followed) or a Vector3 (its feet). A burst of seed-dust rolling out to
##                2.5 m, cream moth-wing flakes fluttering up, and a free 2.5 m pollen cloud for 3 s.
## Fog: the local team's effects always show; others only where the local team sees (FogOfWar.is_visible), checked 4 x
## per second (the snagroot at its victim).
## Budget: everything is pre-built at _ready and pooled (vines, ground marks, rings, flares, haze emitters, one-shot
## bursts). One material per shader / look, looks set with instance uniforms: no node, material or mesh is created
## after _ready. No lights, no shadows. Bursts are not started beyond 45 m from the camera.
## Colours: bark-brown / straw / pale moss with lime sap glows (never a green wash on the green meadow).

const GROUP := &"caster_nature_vfx"
const EFFECTS: Array[StringName] = [&"snagroot", &"pollen_haze", &"hazed", &"seedcloak"]

const SAP := Color(0.75, 1.0, 0.40)
const POLLEN := Color(0.92, 0.80, 0.28)
const POLLEN_PALE := Color(0.98, 0.94, 0.66)
const STRAW := Color(0.80, 0.72, 0.42)
const SOIL := Color(0.30, 0.21, 0.12)
const MOTH := Color(0.88, 0.82, 0.62)

const SHOOT := 0.25
const DRAG := 0.5
const LETGO := 0.2
const ROOT_TIME := 1.0
const DRAG_DIST := 7.0
const HAZE_RADIUS := 3.5
const HAZE_TIME := 6.0
const CLOAK_RADIUS := 2.5
const CLOAK_TIME := 3.0
const HAZED_LINGER := 0.5
const PARTICLE_RANGE := 45.0
const BURSTS_PER_FRAME := 16
const CHECK_INTERVAL := 0.25
const FOG_RESCAN := 1.0

enum { A_POINT, A_TARGET, A_WORLD, A_HEAD }

const POOL_SIZES := {&"vine": 8, &"ground": 32, &"ring": 12, &"flare": 32}
const HAZE_POOL := 6
const BURSTS := {
	&"wrap_leaves": [9, 0.9, &"leaf", 8, 1.0, 3.0],
	&"clods": [10, 0.8, &"chip", 8, 1.0, 3.0],
	&"root_leaves": [6, 1.1, &"leaf", 8, 0.9, 3.0],
	&"cloak_dust": [18, 1.3, &"dust", 4, 0.95, 4.0],
	&"cloak_flutter": [10, 1.6, &"moth", 4, 0.85, 4.0],
	&"haze_burst": [10, 1.2, &"dust", 6, 0.95, 5.0],
}
const OPTIONAL_BURSTS: Array[StringName] = [&"root_leaves", &"cloak_flutter"]

const GROUND_SHADER := preload("res://art/vfx/caster_nature_ground.gdshader")
const VINE_SHADER := preload("res://art/vfx/caster_nature_vine.gdshader")
const FLARE_SHADER := preload("res://art/vfx/champion_flare.gdshader")
const RING_SHADER := preload("res://art/vfx/vfx_ring.gdshader")


class Fx:
	extends RefCounted
	var id: StringName
	var t := 0.0
	var dur := 1.0
	var point := Vector3.ZERO      # anchor A_POINT (the caster's feet / the cloud centre)
	var tpos := Vector3.ZERO       # anchor A_TARGET (the victim's feet)
	var team := -1
	var shown := true
	var check_left := 0.0
	var follow: Node3D = null      # the caster (snagroot, seedcloak) / the hazed unit
	var victim: Node3D = null
	var head_h := 1.6
	var pieces: Array[Piece] = []
	var bursts: Array[Dictionary] = []
	var bursts_left := 0
	# snagroot
	var vine: Piece = null
	var furrow: Piece = null
	var hook := Vector3.ZERO
	var start := Vector3.ZERO      # the victim's feet at the cast
	var sim_end := Vector3.ZERO    # simulated drag end (Vector3 targets)
	var chest := 1.0
	var tracked := false           # a real victim was given: when it dies / goes, its last spot stays (no simulation)
	# haze
	var emit: Array = []           # [puffs, motes] while the cloud runs
	var stop_at := 0.0


class Piece:
	extends RefCounted
	var n: GeometryInstance3D
	var pool: StringName
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
	var last: Dictionary = {}     # instance uniform -> the last value sent (_set_p skips unchanged values)


var _fx: Array[Fx] = []
var _free: Dictionary = {}
var _all: Dictionary = {}
var _bursts: Dictionary = {}
var _burst_next: Dictionary = {}
var _live_bursts: Array[Dictionary] = []
var _bursts_this_frame := 0
var _haze_free: Array = []        # [puffs, motes] pairs
var _haze_all: Array = []
var _haze_draining: Array[Dictionary] = []   # {pair, left}
var _pmats: Dictionary = {}
var _passes: Dictionary = {}
var _fog: Node
var _fog_left := 0.0
var _cam: Camera3D
var _rng := RandomNumberGenerator.new()
var _layer := 0


func _ready() -> void:
	add_to_group(GROUP)
	top_level = true
	global_transform = Transform3D.IDENTITY
	_rng.seed = 3109
	_build_shared()
	set_process(false)   # woken by _start; sleeps again once nothing runs


func _process(delta: float) -> void:
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
	for i in range(_haze_draining.size() - 1, -1, -1):
		var h: Dictionary = _haze_draining[i]
		h["left"] = float(h["left"]) - delta
		if float(h["left"]) <= 0.0:
			for p: GPUParticles3D in h["pair"]:
				p.visible = false
			_haze_free.append(h["pair"])
			_haze_draining.remove_at(i)
	if _fx.is_empty() and _live_bursts.is_empty() and _haze_draining.is_empty():
		set_process(false)


## Turns _process back on (and refreshes the camera / fog it cached) when an effect starts while idle.
func _wake() -> void:
	if is_processing():
		return
	set_process(true)
	_cam = get_viewport().get_camera_3d() if get_viewport() else null
	_fog_left = FOG_RESCAN
	_fog = get_tree().get_first_node_in_group(&"fog") if is_inside_tree() else null


# ---------------------------------------------------------------- public API

func handles(id: StringName) -> bool:
	return EFFECTS.has(id)


func play(id: StringName, at: Variant, target: Variant = null) -> bool:
	if not EFFECTS.has(id):
		return false
	if not is_node_ready() or not is_inside_tree():
		return true
	match id:
		&"snagroot": _snagroot(at, target)
		&"pollen_haze": _haze(at, target, &"pollen_haze")
		&"hazed": _hazed(at, target)
		&"seedcloak": _seedcloak(at)
	return true


func active_count() -> int:
	return _fx.size()


func live_count() -> int:
	var n := _live_bursts.size() + _haze_draining.size()
	for pool: StringName in _all:
		for g: GeometryInstance3D in _all[pool]:
			if g.visible:
				n += 1
	for pair: Array in _haze_all:
		if (pair[0] as GPUParticles3D).emitting:
			n += 1
	return n


# ---------------------------------------------------------------- the effects

func _snagroot(at: Variant, target: Variant) -> void:
	var caster := _node(at)
	var hook: Variant = null
	if at is Vector3:
		hook = at
	elif caster:
		hook = _hook_of(caster)
	if hook == null:
		return
	var to: Variant = target
	var drag := DRAG_DIST
	if target is Dictionary:
		to = (target as Dictionary).get("to", null)
		drag = float((target as Dictionary).get("drag", drag))
	var victim := _node(to)
	var feet: Variant = null
	if victim:
		feet = victim.global_position
	elif to is Vector3:
		feet = to
	if feet == null:
		return
	var h: Vector3 = hook
	var fx := _new_fx(&"snagroot", caster.global_position if caster else Vector3(h.x, (feet as Vector3).y, h.z),
		_team_of(caster))
	fx.follow = caster
	fx.victim = victim
	fx.tracked = victim != null
	fx.hook = h
	fx.start = feet
	fx.tpos = feet
	fx.chest = _h(victim) * 0.55 if victim else 0.9
	var back: Vector3 = fx.point - (feet as Vector3)
	back.y = 0.0
	var dist := back.length()
	fx.sim_end = (feet as Vector3) + (back / maxf(dist, 0.001)) * minf(drag, dist * 0.7) if dist > 0.5 else feet
	fx.dur = SHOOT + DRAG + ROOT_TIME + 0.4
	var v := _piece(fx, &"vine", A_WORLD, Vector3.ZERO, 0.0, SHOOT + DRAG + LETGO, 0.0, 0.08)
	if v:
		fx.vine = v
		_params(v, {&"width": 0.22, &"grow": 0.0, &"taut": 0.0, &"pulse": 0.0, &"seed": _rng.randf() * 10.0})
	# The hook flares as the vine leaves; the snap at the victim (lime star + a coil hoop at the waist + leaves).
	_flare(fx, A_WORLD, h, _hdr(SAP, 1.4), 0.25, 0.6, 0.08, 0.0, 0.25, 0.0, 0.15, 0.6, 4.0)
	_flare(fx, A_TARGET, Vector3.UP * fx.chest, _hdr(SAP, 1.8), 0.4, 1.1, 0.08, SHOOT, SHOOT + 0.3, 0.0, 0.2, 1.0, 6.0)
	var coil := _ring(fx, A_TARGET, _hdr(SAP, 1.2), 0.25, 0.55, 0.12, SHOOT, SHOOT + DRAG + 0.1, 0.02, 0.2, 0.18, 0.1)
	if coil:
		coil.ofs = Vector3.UP * fx.chest * 0.8
		coil.o0 = coil.ofs
		_params(coil, {&"fill": Color(0.10, 0.07, 0.03, 0.0)})
	_sched(fx, &"wrap_leaves", SHOOT, A_TARGET, Vector3.UP * fx.chest)
	# The furrow behind the dragged victim (updated every tick), clods at the start.
	fx.furrow = _ground(fx, A_WORLD, 0, _hdr(STRAW, 0.2), Vector3(0.38, 1.0, 0.1), feet, Basis.IDENTITY, SHOOT,
		0.0, 0.05, 0.6)
	_sched(fx, &"clods", SHOOT + 0.04, A_WORLD, (feet as Vector3) + Vector3.UP * 0.1)
	_sched(fx, &"clods", SHOOT + DRAG * 0.6, A_TARGET, Vector3.UP * 0.1)
	# Rooted: bark roots coil in at the feet for 1 s.
	var root := _ground(fx, A_TARGET, 2, _hdr(SAP, 1.0), Vector3(0.95, 1.0, 0.95), Vector3.ZERO, Basis.IDENTITY,
		SHOOT + DRAG, SHOOT + DRAG + ROOT_TIME + 0.3, 0.12, 0.3)
	if root:
		_grow(root, Vector3(0.4, 1.0, 0.4), Vector3(0.95, 1.0, 0.95), 0.18)
	_sched(fx, &"root_leaves", SHOOT + DRAG + 0.02, A_TARGET, Vector3.UP * 0.2)
	_start(fx)
	if fx.shown:
		_gplay(&"snagroot", feet, {"team": fx.team, "delay": SHOOT})


## `follow`: the cloud rides on this node (Seedcloak: the gameplay haze, CasterHaze, follows the fleeing Bramblesage):
## the veil and rings sit on fx.point, which _tick moves, and the emitter pair moves with it.
func _haze(at: Variant, target: Variant, id: StringName, follow: Node3D = null) -> void:
	var anchor := _node(at)
	var c: Variant = at if at is Vector3 else (anchor.global_position if anchor else null)
	if c == null:
		return
	var radius := HAZE_RADIUS
	var time := HAZE_TIME
	var team := _team_of(anchor)
	if target is float or target is int:
		radius = float(target)
	elif target is Dictionary:
		var d: Dictionary = target
		radius = float(d.get("radius", radius))
		time = float(d.get("time", time))
		team = int(d.get("team", team))
	radius = clampf(radius, 1.0, 6.0)
	time = maxf(time, 1.5)
	var fx := _new_fx(id, c, team)
	fx.follow = follow
	fx.dur = time
	fx.stop_at = time - 1.2
	var k := radius / HAZE_RADIUS
	# The veil on the ground, the rim ring rolling out, a soft flash, the cloud emitters.
	var veil := _ground(fx, A_POINT, 1, _hdr(POLLEN, 0.8), Vector3(radius, 1.0, radius), Vector3.ZERO, Basis.IDENTITY,
		0.0, 0.0, 0.4, 1.0)
	if veil:
		_grow(veil, Vector3(radius * 0.5, 1.0, radius * 0.5), Vector3(radius, 1.0, radius), 0.45)
	_ring(fx, A_POINT, _hdr(POLLEN, 1.0), 0.4 * k, radius, 0.45, 0.0, 0.8, 0.0, 0.35, 0.06, 0.2)
	_sched(fx, &"haze_burst", 0.0, A_POINT, Vector3.UP * 0.6, k)
	if not _haze_free.is_empty():
		var pair: Array = _haze_free.pop_back()
		fx.emit = pair
		var puffs: GPUParticles3D = pair[0]
		var motes: GPUParticles3D = pair[1]
		for p: GPUParticles3D in pair:
			p.transform = Transform3D(Basis.from_scale(Vector3.ONE * k), (c as Vector3) + Vector3.UP * 0.9)
			p.visible = true
			p.emitting = true
			p.restart()
		puffs.amount_ratio = 1.0
		motes.amount_ratio = 1.0
	_start(fx)
	if fx.shown and follow == null:
		_gplay(&"pollen_haze", c, {"team": fx.team, "r": radius})


func _hazed(at: Variant, target: Variant) -> void:
	var n := _node(at)
	var dur := float(target) if (target is float or target is int) else 1.0
	# refresh an existing halo on the same unit
	if n:
		for fx in _fx:
			if fx.id == &"hazed" and fx.follow == n:
				fx.dur = maxf(fx.dur, fx.t + dur + HAZED_LINGER)
				return
	var p: Variant = at if at is Vector3 else (n.global_position if n else null)
	if p == null:
		return
	var fx := _new_fx(&"hazed", p, _team_of(n))
	fx.follow = n
	fx.head_h = _h(n) * 0.95 if n else 1.6
	fx.dur = dur + HAZED_LINGER
	var halo := _ground(fx, A_HEAD, 3, _hdr(POLLEN_PALE, 1.3), Vector3(0.36, 1.0, 0.36), Vector3.ZERO, Basis.IDENTITY,
		0.0, 0.0, 0.15, HAZED_LINGER)
	if halo:
		halo.ofs = Vector3.ZERO
	_start(fx)


func _seedcloak(at: Variant) -> void:
	var n := _node(at)
	var p: Variant = at if at is Vector3 else (n.global_position if n else null)
	if p == null:
		return
	var fx := _new_fx(&"seedcloak", p, _team_of(n))
	fx.follow = n
	fx.dur = 1.4
	_ring(fx, A_POINT, _hdr(POLLEN, 1.1), 0.3, CLOAK_RADIUS, 0.35, 0.0, 0.7, 0.0, 0.35, 0.08, 0.3)
	_flare(fx, A_POINT, Vector3.UP * 1.3, _hdr(POLLEN_PALE, 1.2), 0.6, 1.6, 0.15, 0.0, 0.35, 0.0, 0.25, 0.5, 6.0)
	_sched(fx, &"cloak_dust", 0.0, A_POINT, Vector3.UP * 0.5)
	_sched(fx, &"cloak_flutter", 0.05, A_POINT, Vector3.UP * 1.3)
	_start(fx)
	if fx.shown:
		_gplay(&"seedcloak", p, {"team": fx.team})
	# The cloud follows the Bramblesage like the gameplay haze (CasterHaze.spawn(..., unit)), code review L3.
	_haze(p, {"radius": CLOAK_RADIUS, "time": CLOAK_TIME, "team": fx.team}, &"pollen_haze", n)


## G-B: the Medium+ spell layer (art/vfx/spells_g/spell_fx_g.gd) adds its pieces; nothing at Low (SpellFxG.live = null).
func _gplay(id: StringName, pos: Vector3, opts: Dictionary = {}) -> void:
	var g := SpellFxG.live(self)
	if g:
		g.play(id, pos, opts)


# ---------------------------------------------------------------- runtime

func _new_fx(id: StringName, point: Vector3, team: int) -> Fx:
	var fx := Fx.new()
	fx.id = id
	fx.point = point
	fx.tpos = point
	fx.team = team
	return fx


func _start(fx: Fx) -> void:
	_wake()
	_fx.append(fx)
	_refresh(fx)
	fx.check_left = CHECK_INTERVAL
	_tick(fx, 0.0)


func _tick(fx: Fx, delta: float) -> bool:
	fx.t += delta
	if fx.follow:
		if is_instance_valid(fx.follow) and fx.follow.is_inside_tree():
			fx.point = fx.follow.global_position
			if fx.id == &"snagroot":
				var hk: Variant = _hook_of(fx.follow)
				if hk != null:
					fx.hook = hk
		else:
			fx.follow = null
	if fx.id == &"snagroot":
		_tick_snag(fx)
	fx.check_left -= delta
	if fx.check_left <= 0.0:
		fx.check_left += CHECK_INTERVAL
		_refresh(fx)
	if not fx.emit.is_empty():
		var vis := fx.shown
		for p: GPUParticles3D in fx.emit:
			if p.visible != vis:
				p.visible = vis
			if fx.follow:   # a following cloud (Seedcloak): new puffs spawn where the Bramblesage is now
				var o := fx.point + Vector3.UP * 0.9
				if not p.transform.origin.is_equal_approx(o):
					p.transform.origin = o
		if fx.t >= fx.stop_at and (fx.emit[0] as GPUParticles3D).emitting:
			for p: GPUParticles3D in fx.emit:
				p.emitting = false
			_haze_draining.append({"pair": fx.emit, "left": (fx.emit[0] as GPUParticles3D).lifetime + 0.2})
			fx.emit = []
	for d in fx.pieces:
		_tick_piece(fx, d)
	if fx.bursts_left > 0:
		for b in fx.bursts:
			if not b["done"] and fx.t >= float(b["on"]):
				b["done"] = true
				fx.bursts_left -= 1
				if fx.shown:
					_burst(b["look"], _anchor(fx, b["at"]) + (b["ofs"] as Vector3), b["size"], b["basis"])
	return fx.t >= fx.dur and fx.bursts_left <= 0 and fx.emit.is_empty()


## Snagroot: the victim's position (tracked or simulated), the vine curve and growth, the furrow.
func _tick_snag(fx: Fx) -> void:
	var t := fx.t
	if fx.victim:
		if is_instance_valid(fx.victim) and fx.victim.is_inside_tree() and _alive(fx.victim):
			fx.tpos = fx.victim.global_position
		else:
			fx.victim = null   # died / freed: tpos stays at its last real spot
	elif not fx.tracked:
		var k := _ease(clampf((t - SHOOT) / DRAG, 0.0, 1.0))
		fx.tpos = fx.start.lerp(fx.sim_end, k)
	var v := fx.vine
	if v:
		var grow := 1.0
		if t < SHOOT:
			grow = _ease(clampf(t / SHOOT, 0.0, 1.0))
		elif t > SHOOT + DRAG:
			grow = 1.0 - _ease(clampf((t - SHOOT - DRAG) / LETGO, 0.0, 1.0))
		var taut := clampf((t - SHOOT) / 0.1, 0.0, 1.0) * (1.0 - clampf((t - SHOOT - DRAG) / LETGO, 0.0, 1.0))
		var pulse := snappedf(exp(-maxf(t - SHOOT, 0.0) * 10.0), 0.01) * (1.0 if t >= SHOOT else 0.0)
		var p0 := fx.hook
		var p2 := fx.tpos + Vector3.UP * fx.chest
		var mid := (p0 + p2) * 0.5
		var p1 := mid + Vector3.UP * (0.7 * (1.0 - taut) + 0.1)
		_set_p(v, &"p0", p0)
		_set_p(v, &"p1", p1)
		_set_p(v, &"p2", p2)
		_set_p(v, &"grow", maxf(grow, 0.001))
		_set_p(v, &"taut", taut)
		_set_p(v, &"pulse", pulse)
		_set_p(v, &"length_m", maxf(p0.distance_to(p2), 0.5))
	var f := fx.furrow
	if f:
		var a := fx.start
		var b := fx.tpos
		b.y = a.y
		var d := b - a
		var l := d.length()
		if l > 0.05:
			var z := d / l
			f.rot = Basis(Vector3.UP.cross(z), Vector3.UP, z)
			f.ofs = (a + b) * 0.5 + Vector3.UP * 0.045
			f.s0 = Vector3(0.38, 1.0, maxf(l * 0.5 + 0.2, 0.1))
			f.s1 = f.s0
			_set_p(f, &"size", Vector2(0.38, f.s0.z))
		else:
			f.s0 = Vector3(0.38, 1.0, 0.1)
			f.s1 = f.s0


func _tick_piece(fx: Fx, d: Piece) -> void:
	var n := d.n
	var off := d.off if d.off > 0.0 else fx.dur + d.off
	var lt := fx.t - d.on
	if lt < 0.0 or fx.t >= off:
		if n.visible:
			n.visible = false
		return
	var f := 1.0
	if d.fin > 0.0:
		f = minf(f, lt / d.fin)
	if d.fout > 0.0:
		f = minf(f, (off - fx.t) / d.fout)
	f = clampf(f, 0.0, 1.0)
	if d.pool != &"vine":
		var k := 1.0
		if d.grow > 0.0:
			k = _ease(clampf(lt / d.grow, 0.0, 1.0))
		var s := d.s0.lerp(d.s1, k)
		var pos := _anchor(fx, d.at) + d.o0.lerp(d.ofs, k)
		var xf := Transform3D(d.rot * Basis.from_scale(s), pos)
		if not xf.is_equal_approx(n.transform):
			n.transform = xf
		if d.pool == &"ground" and d.grow > 0.0 and lt <= d.grow + 0.05:
			_set_p(d, &"size", Vector2(s.x, s.z))
		if d.pool == &"flare" and lt <= 1.05:
			n.set_instance_shader_parameter(&"age", lt)
	if absf(f - d.lf) > 0.003:
		d.lf = f
		n.set_instance_shader_parameter(&"fade", f)
	var vis := fx.shown and f > 0.002
	if n.visible != vis:
		n.visible = vis


func _finish(fx: Fx) -> void:
	for d in fx.pieces:
		d.n.visible = false
		d.n.set_instance_shader_parameter(&"fade", 0.0)
		(_free[d.pool] as Array).append(d.n)
	fx.pieces.clear()
	if not fx.emit.is_empty():
		for p: GPUParticles3D in fx.emit:
			p.emitting = false
		_haze_draining.append({"pair": fx.emit, "left": (fx.emit[0] as GPUParticles3D).lifetime + 0.2})
		fx.emit = []


func _refresh(fx: Fx) -> void:
	var at := fx.tpos if fx.id == &"snagroot" else fx.point
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
		A_HEAD:
			return fx.point + Vector3.UP * fx.head_h
	return fx.point


func _piece(fx: Fx, pool: StringName, at: int, ofs: Vector3, on: float, off: float, fin: float, fout: float) -> Piece:
	var free: Array = _free[pool]
	if free.is_empty():
		return null
	var d := Piece.new()
	d.n = free.pop_back()
	d.pool = pool
	d.at = at
	d.ofs = ofs
	d.o0 = ofs
	d.on = on
	d.off = off
	d.fin = fin
	d.fout = fout
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
		d.last[k] = params[k]


## Sends one instance uniform only when its value changed since the last send on this piece.
func _set_p(d: Piece, param: StringName, value: Variant) -> void:
	if d.last.has(param) and d.last[param] == value:
		return
	d.last[param] = value
	d.n.set_instance_shader_parameter(param, value)


func _ground(fx: Fx, at: int, pattern: int, tint: Color, half: Vector3, ofs: Vector3, rot: Basis, on: float, off: float,
		fin: float, fout: float) -> Piece:
	_layer = (_layer + 1) % 8
	var lift := Vector3.ZERO if at == A_HEAD else Vector3.UP * (0.04 + 0.006 * float(_layer))
	var d := _piece(fx, &"ground", at, ofs + lift, on, off, fin, fout)
	if d == null:
		return null
	d.rot = rot
	_grow(d, Vector3(half.x, 1.0, half.z), Vector3(half.x, 1.0, half.z), 0.0)
	_params(d, {&"pattern": float(pattern), &"tint": tint, &"seed": _rng.randf() * 10.0, &"draw": 1.0,
			&"size": Vector2(half.x, half.z)})
	return d


func _ring(fx: Fx, at: int, tint: Color, r0: float, r1: float, grow: float, on: float, off: float, fin: float,
		fout: float, width: float = 0.1, glow: float = 0.25) -> Piece:
	_layer = (_layer + 1) % 8
	var d := _piece(fx, &"ring", at, Vector3.UP * (0.06 + 0.006 * float(_layer)), on, off, fin, fout)
	_grow(d, Vector3(r0, 1.0, r0), Vector3(r1, 1.0, r1), grow)
	_params(d, {&"tint": tint, &"fill": Color(0, 0, 0, 0), &"width": width, &"glow": glow, &"seed": _rng.randf() * 10.0})
	return d


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
		return
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


# ---------------------------------------------------------------- helpers

func _node(v: Variant) -> Node3D:
	if typeof(v) == TYPE_OBJECT and is_instance_valid(v) and v is Node3D and (v as Node3D).is_inside_tree():
		return v as Node3D
	return null


## The crook hook of a Bramblesage (its model's get_hook_position(), through Unit.get_model()), else 1.9 m up.
func _hook_of(n: Node3D) -> Variant:
	if n == null:
		return null
	var m: Node = n
	if n.has_method(&"get_model"):
		var mm: Variant = n.call(&"get_model")
		if mm is Node3D and is_instance_valid(mm):
			m = mm
	if m.has_method(&"get_hook_position"):
		var p: Variant = m.call(&"get_hook_position")
		if p is Vector3:
			return p
	return n.global_position + Vector3.UP * 1.9


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


static func _alive(node: Node3D) -> bool:
	if node.has_method(&"is_alive"):
		return bool(node.call(&"is_alive"))
	return true


func _h(n: Variant) -> float:
	if not is_instance_valid(n):
		return 1.6
	var h: Variant = (n as Object).get(&"body_height")
	return float(h) if h != null else 1.6


func _ease(k: float) -> float:
	return 1.0 - pow(1.0 - k, 3.0)


func _hdr(c: Color, energy: float, alpha: float = 1.0) -> Color:
	var l := c.srgb_to_linear()
	return Color(l.r * energy, l.g * energy, l.b * energy, alpha)


# ---------------------------------------------------------------- shared resources (built once)

func _build_shared() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(2.0, 2.0)
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	var vine_quad := QuadMesh.new()
	vine_quad.size = Vector2(1.0, 1.0)
	vine_quad.subdivide_depth = 24
	var meshes := {&"vine": vine_quad, &"ground": plane, &"ring": plane, &"flare": quad}
	var mats := {&"vine": _shader_mat(VINE_SHADER), &"ground": _shader_mat(GROUND_SHADER),
		&"ring": _shader_mat(RING_SHADER), &"flare": _shader_mat(FLARE_SHADER)}
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
			if pool == &"flare":
				m.extra_cull_margin = 4.0
			if pool == &"vine":
				m.custom_aabb = AABB(Vector3(-2000, -200, -2000), Vector3(4000, 400, 4000))   # world-space ribbon
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
	for i in HAZE_POOL:
		var puffs := _emitter(&"haze_puffs", 24, 2.0, &"puff", 6.0)
		puffs.one_shot = false
		puffs.explosiveness = 0.0
		puffs.preprocess = 0.0
		var motes := _emitter(&"haze_motes", 30, 1.8, &"mote", 6.0)
		motes.one_shot = false
		add_child(puffs)
		add_child(motes)
		_haze_all.append([puffs, motes])
		_haze_free.append([puffs, motes])


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
	p.visibility_aabb = AABB(Vector3(-half, -2.0, -half), Vector3(half * 2.0, 6.0, half * 2.0))
	return p


func _build_passes() -> void:
	_passes[&"leaf"] = _particle_quad(_shape_tex(&"leaf"), BaseMaterial3D.BLEND_MODE_MIX)
	_passes[&"moth"] = _particle_quad(_shape_tex(&"moth"), BaseMaterial3D.BLEND_MODE_MIX)
	_passes[&"chip"] = _particle_quad(_shape_tex(&"chip"), BaseMaterial3D.BLEND_MODE_MIX)
	_passes[&"dust"] = _particle_quad(_shape_tex(&"smoke"), BaseMaterial3D.BLEND_MODE_MIX)
	_passes[&"puff"] = _particle_quad(_shape_tex(&"smoke"), BaseMaterial3D.BLEND_MODE_MIX)
	_passes[&"mote"] = _particle_quad(_shape_tex(&"dot"), BaseMaterial3D.BLEND_MODE_ADD)


func _particle_quad(tex: Texture2D, blend: BaseMaterial3D.BlendMode) -> QuadMesh:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = blend
	mat.disable_fog = blend == BaseMaterial3D.BLEND_MODE_ADD  # G-E 5: an additive quad must not fog
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.billboard_keep_scale = true
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = tex
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.disable_receive_shadows = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
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
					var lu := (u + v) * 0.7071
					var lv := (v - u) * 0.7071
					var hl := 0.92
					var hw := 0.4
					var off := (hl * hl - hw * hw) / (2.0 * hw)
					var rad := off + hw
					var d := maxf(Vector2(lu, lv - off).length(), Vector2(lu, lv + off).length())
					a = clampf((rad - d) / 0.06, 0.0, 1.0)
					var rib := 1.0 - clampf((absf(lv) - 0.03) / 0.04, 0.0, 1.0)
					shade = clampf((0.9 if lv > 0.0 else 0.72) - rib * 0.3, 0.3, 1.0)
				&"moth":
					# two rounded wing lobes either side of a thin body, a dark eye-spot on each
					var ax := absf(u)
					var lobe := Vector2((ax - 0.45) / 0.5, (v + 0.1) / 0.7).length()
					var lobe2 := Vector2((ax - 0.35) / 0.35, (v - 0.5) / 0.35).length()
					a = clampf((1.0 - minf(lobe, lobe2)) / 0.1, 0.0, 1.0)
					var eye := Vector2(ax - 0.5, v + 0.05).length()
					shade = 0.95 - (0.6 if eye < 0.12 else 0.0) - 0.15 * ax
				&"chip":
					var ang := atan2(v, u)
					var poly := cos(PI / 6.0) / cos(fmod(ang + TAU * 2.0 + 0.4, TAU / 6.0) - PI / 6.0)
					a = clampf((0.72 * poly - r) / 0.07, 0.0, 1.0)
					shade = clampf(0.72 - 0.3 * (u + v) * 0.5, 0.35, 1.0)
				&"smoke":
					var nse := _vn(u * 2.3 + 7.1, v * 2.3 + 3.3) * 0.6 + _vn(u * 5.1 + 1.7, v * 5.1 - 2.2) * 0.4
					a = clampf((1.0 - r) * 1.6 + (nse - 0.5) * 0.9 - 0.2, 0.0, 1.0)
					a = a * a * (3.0 - 2.0 * a) * clampf((1.0 - r) / 0.2, 0.0, 1.0)
					shade = clampf(0.85 + 0.12 * (0.5 - v * 0.5) + (nse - 0.5) * 0.2, 0.0, 1.0)
				&"dot":
					a = clampf((1.0 - r) / 0.5, 0.0, 1.0)
					a = a * a
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


func _ramp(a: Color, b: Color, peak: float = 0.15) -> GradientTexture1D:
	var g := Gradient.new()
	g.set_color(0, Color(a.r, a.g, a.b, 0.0))
	g.set_color(1, Color(b.r, b.g, b.b, 0.0))
	g.add_point(peak, a)
	g.add_point(0.7, Color(b.r, b.g, b.b, b.a * 0.7))
	var t := GradientTexture1D.new()
	t.gradient = g
	return t


func _curve(pts: Array) -> CurveTexture:
	var c := Curve.new()
	for p: Vector2 in pts:
		c.add_point(p)
	var t := CurveTexture.new()
	t.curve = c
	return t


func _pmat(look: StringName) -> ParticleProcessMaterial:
	if _pmats.has(look):
		return _pmats[look]
	var m := ParticleProcessMaterial.new()
	m.collision_mode = ParticleProcessMaterial.COLLISION_DISABLED
	match look:
		&"wrap_leaves", &"root_leaves":
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			m.emission_sphere_radius = 0.3
			m.direction = Vector3.UP
			m.spread = 180.0 if look == &"wrap_leaves" else 70.0
			m.initial_velocity_min = 1.0
			m.initial_velocity_max = 2.4
			m.gravity = Vector3(0, -3.0, 0)
			m.damping_min = 1.0
			m.damping_max = 2.0
			m.angle_min = -180.0
			m.angle_max = 180.0
			m.angular_velocity_min = -200.0
			m.angular_velocity_max = 200.0
			m.scale_min = 0.12
			m.scale_max = 0.2
			m.color_ramp = _ramp(Color(0.66, 0.66, 0.30, 1.0), Color(0.55, 0.46, 0.22, 0.9), 0.08)
		&"clods":
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			m.emission_sphere_radius = 0.25
			m.direction = Vector3.UP
			m.spread = 60.0
			m.initial_velocity_min = 1.5
			m.initial_velocity_max = 3.2
			m.gravity = Vector3(0, -9.0, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			m.scale_min = 0.08
			m.scale_max = 0.16
			m.color_ramp = _ramp(Color(SOIL.r, SOIL.g, SOIL.b, 1.0), Color(0.24, 0.17, 0.10, 1.0), 0.05)
		&"cloak_dust", &"haze_burst":
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
			m.emission_ring_axis = Vector3.UP
			m.emission_ring_radius = 0.5
			m.emission_ring_inner_radius = 0.1
			m.emission_ring_height = 0.3
			m.direction = Vector3(1, 0.25, 0)
			m.spread = 180.0
			m.flatness = 0.8
			m.initial_velocity_min = 1.5
			m.initial_velocity_max = 3.0
			m.gravity = Vector3(0, 0.1, 0)
			m.damping_min = 1.5
			m.damping_max = 2.5
			m.scale_min = 0.8
			m.scale_max = 1.4
			m.scale_curve = _curve([Vector2(0, 0.4), Vector2(1, 1.0)])
			m.color_ramp = _ramp(Color(POLLEN.r, POLLEN.g, POLLEN.b, 0.5), Color(STRAW.r, STRAW.g, STRAW.b, 0.35))
		&"cloak_flutter":
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			m.emission_sphere_radius = 0.4
			m.direction = Vector3.UP
			m.spread = 60.0
			m.initial_velocity_min = 0.8
			m.initial_velocity_max = 1.6
			m.gravity = Vector3(0, -0.3, 0)
			m.damping_min = 0.5
			m.damping_max = 1.0
			m.angle_min = -40.0
			m.angle_max = 40.0
			m.angular_velocity_min = -90.0
			m.angular_velocity_max = 90.0
			m.scale_min = 0.12
			m.scale_max = 0.2
			m.color_ramp = _ramp(Color(MOTH.r, MOTH.g, MOTH.b, 1.0), Color(0.80, 0.74, 0.54, 0.9), 0.08)
		&"haze_puffs":
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
			m.emission_ring_axis = Vector3.UP
			m.emission_ring_radius = HAZE_RADIUS * 0.8
			m.emission_ring_inner_radius = 0.0
			m.emission_ring_height = 1.2
			m.direction = Vector3.UP
			m.spread = 180.0
			m.flatness = 0.6
			m.initial_velocity_min = 0.1
			m.initial_velocity_max = 0.35
			m.gravity = Vector3(0, 0.04, 0)
			m.damping_min = 0.1
			m.damping_max = 0.2
			m.angle_min = -180.0
			m.angle_max = 180.0
			m.angular_velocity_min = -12.0
			m.angular_velocity_max = 12.0
			m.scale_min = 1.6
			m.scale_max = 2.6
			m.scale_curve = _curve([Vector2(0, 0.55), Vector2(1, 1.0)])
			m.color_ramp = _ramp(Color(POLLEN.r, POLLEN.g, POLLEN.b, 0.42), Color(0.84, 0.74, 0.30, 0.3), 0.25)
		&"haze_motes":
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
			m.emission_ring_axis = Vector3.UP
			m.emission_ring_radius = HAZE_RADIUS * 0.9
			m.emission_ring_inner_radius = 0.0
			m.emission_ring_height = 1.6
			m.direction = Vector3.UP
			m.spread = 60.0
			m.initial_velocity_min = 0.1
			m.initial_velocity_max = 0.35
			m.gravity = Vector3(0, 0.06, 0)
			m.scale_min = 0.06
			m.scale_max = 0.11
			var c := _hdr(POLLEN_PALE, 1.5)
			m.color_ramp = _ramp(Color(c.r, c.g, c.b, 1.0), Color(c.r, c.g, c.b, 0.7), 0.2)
	_pmats[look] = m
	return m
