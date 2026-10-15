class_name UnitIceRifleVfx
extends Node3D
## Rune-rifle effects of the Frostrune Rifleman (task 13b.V7, docs/design/tier3-extras.md 5.1-5.2, 12, 13). An effect
## FAMILY of UnitVfx (art/vfx/unit_vfx.gd loads this file and forwards the ids below); callers never reach it directly:
##   var vfx := get_tree().get_first_node_in_group(&"unit_vfx")
##   if vfx: vfx.play(&"rifle_shot", rifleman, victim)
## It can also live on its own (a test level). Draw-only: it never touches gameplay.
##
## "The shooter" below = the Unit, or its FrostruneRiflemanModel (a Unit is read through get_model()); the model gives
## get_muzzle_position() / get_scope_position() (barrel direction), is_braced() / brace_amount(). Ids (`target` may
## always be null):
##   rifle_shot       at = the shooter (Node3D), OR a Transform3D (origin = the muzzle, basis.z = out of the barrel), OR
##                    a Vector3 (the muzzle; aimed at `target`). target = the victim (Node3D / Vector3; only aims a
##                    Vector3 `at`). Call it at the crack (the model's attack_windup 0.10 s). A crisp blue lance of light
##                    with snowflake barbs out of the crystal crown (0.08 s), a six-point star flash, two rune rings
##                    snapping out along the barrel, a burst of snowflakes, frost motes, a puff of cold vapour.
##   frost_tracer     at = the start (the shooter / Transform3D / Vector3 muzzle), target = the end: a Node3D (its
##                    chest), a Vector3, or a Dictionary {"to": Node3D / Vector3, "impact": bool}; null = 15 m along the
##                    barrel. The thin 15 m frost streak: a white head crosses the gap in 0.07 s (longer shots up to
##                    0.12 s), its cold tail catches up by 0.2 s, frost glints twinkle along it. "impact": true also plays
##                    rifle_impact at the end when the head lands (default false: gameplay plays the impact on the hit).
##   rifle_impact     the rime impact. at = the hit point (Vector3; a Node3D = its chest), target = the victim. A white
##                    star flash, ice chips, snowflakes, a cold puff, a frost ring r 1.0 and a rime patch at its feet
##                    (a building gets the chips / flash only: no ground patch).
##   rime_lock_aim    at = the shooter (tracked: the line leaves the muzzle every frame), or a Vector3 (fixed start);
##                    target = the aimed unit (Node3D, tracked) or a Vector3, or a Dictionary {"target", "time"}. The
##                    1.2 s Rime Lock sight line, visible to BOTH teams (shown when the local team sees either end):
##                    a thin blue line grows out of the muzzle, rune dashes flow down it and close into a solid,
##                    brightening line; a lock reticle on the ground under the target closes in (r 1.7 -> 0.9) with 3
##                    chevrons; the line end glows on the target and flickers in the last 0.25 s. It holds fully charged
##                    0.3 s after the aim time, then fades if no hit came. It ends early when the shooter or the target
##                    dies / leaves the tree (0.15 s fade).
##   rime_lock_hit    at = the hit point (Vector3) or the victim (Node3D: its chest), target = the victim. The freeze
##                    impact: if an aim line runs at that victim (or within 2 m of the point) it snaps into a thick
##                    white-blue shot beam (0.25 s) and ends; a big six-point flash, a freeze column of light, two
##                    shock rings (r 2.8 / 1.9), a rime patch with a glowing rim, 9 ice spikes erupting around the victim
##                    (hold 0.9 s, then shatter from the tips down), ice shards, snowflakes, a ring of cold mist.
##   rime_lock_cancel at = the shooter (or a Vector3 near the line's start): its running aim flickers out in 0.2 s
##                    (the aim was cancelled: target out of range / vision, the rifleman moved, dazed or frozen).
##   brace            at = the shooter (tracked), OR a Vector3 (a one-shot 1.8 s circle). The brace rune circle
##                    (r 1.05) at the feet: it is drawn around the circle over the 1.0 s kneel, flashes as it closes
##                    (frost glints rise, a ring pulses out), then stays dimly under the rifleman (rune band turning, a
##                    pale rime patch) until the model stands up (is_braced() false or brace_amount() < 0.5, polled
##                    4 x / s after 1.2 s), dies, leaves the tree, or brace_end; then it fades in 0.35 s. Playing brace
##                    again on a shooter whose circle still runs does nothing.
##   brace_end        at = the shooter: fades its brace circle (0.35 s).
## Fog: effects of the local team always show; others only where the local team sees (FogOfWar.is_visible at the
## point), checked 4 times per second (the brace circle follows its rifleman). The Rime Lock aim line is the exception
## above (both teams see it).
## Budget: everything is pre-built at _ready and pooled (flashes, flares, rings, lines, rime patches, rune marks, 8 ice
## spike sets, one-shot bursts). One material per shader, looks set with instance uniforms: no node, material or mesh is
## created after _ready. No lights, no shadows. Particle bursts are not drawn beyond 45 m from the camera (visibility
## range) and not even started there; at most BURSTS_PER_FRAME new bursts per frame (a 20-rifle volley keeps its
## flashes, drops motes). A pool that runs dry skips that piece (never allocates).
## Shaders: own unit_ice_rifle_flash (the muzzle lance), unit_ice_rifle_beam (tracer, aim line, shot / column),
## unit_ice_rifle_rune (brace circle, lock reticle), unit_ice_rifle_crystal (freeze spikes); reused read-only:
## champion_flare (flashes, stars), vfx_ring (rings), ice_frost (rime patches), combat_streak (motes).

const GROUP := &"unit_ice_rifle_vfx"
const EFFECTS: Array[StringName] = [&"rifle_shot", &"frost_tracer", &"rifle_impact", &"rime_lock_aim",
		&"rime_lock_hit", &"rime_lock_cancel", &"brace", &"brace_end"]

# Palette: art-keep.md 0.2 Ice glow #BFEBFF, team #73BFF2, cloth shadow #265999; the Rifleman colour (0.55, 0.80, 0.95).
const ICE_GLOW := Color(0.75, 0.92, 1.00)
const ICE_TEAM := Color(0.45, 0.75, 0.95)
const RIFLE := Color(0.55, 0.80, 0.95)
const ICE_DEEP := Color(0.15, 0.35, 0.60)
const WHITE_COLD := Color(0.93, 0.97, 1.00)
const FROST := Color(0.86, 0.94, 1.00)
const MIST := Color(0.82, 0.90, 0.98)

# Numbers from tier3-extras.md 5.1 / 5.2 / 13.
const TRACER_LENGTH := 15.0       # m, the streak when no end is given (the rifle's range)
const TRACER_MAX := 30.0
const TRACER_TIME := 0.2
const TRACER_HEAD := 0.07         # s for the head to cross 15 m (longer shots: up to 0.12)
const AIM_TIME := 1.2
const AIM_HOLD := 0.3             # s the charged line waits for the hit after the aim time
const BRACE_TIME := 1.0           # the model's kneel
const BRACE_SOLO := 1.8           # s, a brace circle with no shooter to follow
const BRACE_RADIUS := 1.05
const BRACE_GRACE := 1.2          # s before the stand-up poll starts
const SPIKES := 9                 # per freeze spike set
const PARTICLE_RANGE := 45.0
const BURSTS_PER_FRAME := 24

const END_FADE := 0.2
const CHECK_INTERVAL := 0.25
const FOG_RESCAN := 1.0

enum { A_POINT, A_TARGET, A_WORLD }
enum { R_BRACE, R_RETICLE }       # unit_ice_rifle_rune.gdshader patterns
enum { B_TRACER, B_AIM, B_SHOT }  # unit_ice_rifle_beam.gdshader modes

## Pre-built pools: pool -> size.
const POOL_SIZES := {&"flash": 32, &"flare": 128, &"ring": 64, &"beam": 48, &"frost": 40, &"rune": 48,
		&"crystal": 8}
## Pools whose shader reads an `age` uniform -> seconds it is sent for (champion_flare declares one but never reads it).
const AGE_POOLS := {&"flash": 0.3, &"rune": 2.5, &"crystal": 1.05}
## One-shot bursts: look -> [amount, lifetime, draw pass, pool size, explosiveness].
const BURSTS := {
	&"muzzle_flakes": [10, 0.9, &"add_flake", 24, 1.0],
	&"muzzle_motes": [12, 0.4, &"streak", 24, 1.0],
	&"muzzle_vapor": [4, 0.9, &"mix_mist", 16, 0.9],
	&"impact_shards": [12, 0.65, &"mix_shard", 16, 1.0],
	&"impact_flakes": [10, 0.8, &"add_flake", 16, 1.0],
	&"impact_mist": [5, 0.9, &"mix_mist", 12, 0.9],
	&"freeze_shards": [26, 0.9, &"mix_shard", 6, 1.0],
	&"freeze_flakes": [24, 1.3, &"add_flake", 6, 0.95],
	&"freeze_mist": [14, 1.4, &"mix_mist", 6, 0.9],
	&"brace_frost": [12, 0.9, &"add_glint", 16, 0.85],
}
## Bursts dropped first when a frame starts too many (the flash, lines and rings always stay).
const OPTIONAL_BURSTS: Array[StringName] = [&"muzzle_motes", &"impact_flakes", &"brace_frost", &"muzzle_vapor"]

const FLARE_SHADER := preload("res://art/vfx/champion_flare.gdshader")
const RING_SHADER := preload("res://art/vfx/vfx_ring.gdshader")
const FROST_SHADER := preload("res://art/vfx/ice_frost.gdshader")
const STREAK_SHADER := preload("res://art/vfx/combat_streak.gdshader")
const FLASH_SHADER := preload("res://art/vfx/unit_ice_rifle_flash.gdshader")
const BEAM_SHADER := preload("res://art/vfx/unit_ice_rifle_beam.gdshader")
const RUNE_SHADER := preload("res://art/vfx/unit_ice_rifle_rune.gdshader")
const CRYSTAL_SHADER := preload("res://art/vfx/unit_ice_rifle_crystal.gdshader")


## One running effect: pooled pieces + scheduled one-shot bursts (+ what the tracked effects follow).
class Fx:
	extends RefCounted
	var id: StringName
	var t := 0.0
	var dur := 1.0
	var point := Vector3.ZERO
	var tpos := Vector3.ZERO
	var team := -1
	var end_at := -1.0
	var fade_len := 0.2
	var shown := true
	var check_left := 0.0
	var pieces: Array[Piece] = []
	var bursts: Array[Dictionary] = []
	var bursts_left := 0
	# tracked effects (tracer, aim, brace)
	var src: Node3D          # the shooter (aim: muzzle source; brace: the node followed)
	var model: Node3D        # its rifleman model, if any
	var dst: Node3D          # the target (aim)
	var has_src := false     # a shooter / followed node was given (it may be freed since: never test `if src`)
	var has_dst := false
	var a := Vector3.ZERO    # line start (world)
	var b := Vector3.ZERO    # line end (world)
	var head_time := 0.07
	var impact := false
	var done := false        # tracer: head landed; aim: converted into the shot
	var line: Piece
	var mark: Piece
	var glow: Piece
	var patch: Piece


## One pooled mesh of an effect (TradeVfx / UnitFireGunVfx pattern). Beam pieces take their transform from pa -> pb.
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
	var k := 1.0             # extra fade multiplier (the brace circle dims after its flash)
	var beam := false
	var pa := Vector3.ZERO
	var pb := Vector3.ZERO
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
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group(GROUP)
	top_level = true
	global_transform = Transform3D.IDENTITY
	_rng.seed = 1307
	_build_shared()


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
		&"rifle_shot": _rifle_shot(at, target)
		&"frost_tracer": _frost_tracer(at, target)
		&"rifle_impact": _rifle_impact(at, target)
		&"rime_lock_aim": _rime_lock_aim(at, target)
		&"rime_lock_hit": _rime_lock_hit(at, target)
		&"rime_lock_cancel": _rime_lock_cancel(at)
		&"brace": _brace(at)
		&"brace_end": _brace_end(at)
	return true


## Number of running effects (a held brace circle counts until it has faded).
func active_count() -> int:
	return _fx.size()


## Ids of the running effects.
func active_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for fx in _fx:
		out.append(fx.id)
	return out


## Pooled pieces still on screen + bursts still alive (0 once everything has ended).
func live_count() -> int:
	var n := _live_bursts.size()
	for pool: StringName in _all:
		for g: GeometryInstance3D in _all[pool]:
			if g.visible:
				n += 1
	return n


## Running Rime Lock aim lines (not yet converted / fading).
func aim_count() -> int:
	var n := 0
	for fx in _fx:
		if fx.id == &"rime_lock_aim" and not fx.done and fx.end_at < 0.0:
			n += 1
	return n


## Brace circles still held (not fading).
func brace_count() -> int:
	var n := 0
	for fx in _fx:
		if fx.id == &"brace" and fx.end_at < 0.0:
			n += 1
	return n


## Copies of the running aim lines: {from, to, charge, shown} (tests, debug).
func aims() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for fx in _fx:
		if fx.id == &"rime_lock_aim" and not fx.done:
			out.append({"from": fx.a, "to": fx.b, "charge": clampf(fx.t / AIM_TIME, 0.0, 1.0), "shown": fx.shown,
					"ending": fx.end_at >= 0.0})
	return out


# ---------------------------------------------------------------- the effects

func _rifle_shot(at: Variant, target: Variant) -> void:
	var xf: Variant = _muzzle_xf(at, target)
	if xf == null:
		return
	var mx: Transform3D = xf
	var dir := mx.basis.z.normalized()
	if dir.length_squared() < 0.5:
		dir = Vector3.FORWARD
	var fx := _new_fx(&"rifle_shot", mx.origin, _team_of(at))
	fx.dur = 0.22
	fx.src = _node(at)   # the flash rides the muzzle as the rifle kicks
	fx.has_src = fx.src != null
	var rot := _y_along(dir)
	# The lance: out to 1.25 m in 30 ms, with its snowflake barbs.
	var lance := _piece(fx, &"flash", A_POINT, Vector3.ZERO, 0.0, 0.085, 0.0, 0.05)
	if lance:
		lance.rot = rot
		_grow(lance, Vector3(0.34, 0.4, 0.34), Vector3(0.62, 1.25, 0.62), 0.03)
		_params(lance, {&"hot": _hdr(WHITE_COLD, 3.0), &"tint": _hdr(ICE_GLOW, 2.4), &"edge": _hdr(ICE_TEAM, 2.2),
				&"seed": _rng.randf() * 10.0})
	# A six-point star at the crown (the snowflake read) + a soft cold halo.
	_flare(fx, A_POINT, dir * 0.05, _hdr(WHITE_COLD, 1.7), 0.3, 0.62, 0.03, 0.0, 0.09, 0.0, 0.05, 1.2, 6.0)
	_flare(fx, A_POINT, dir * 0.1, _hdr(ICE_TEAM, 1.2), 0.45, 0.85, 0.06, 0.0, 0.16, 0.0, 0.1)
	# Two rune rings snapping out along the barrel (they face down the barrel).
	var r1 := _ring(fx, A_POINT, _hdr(ICE_GLOW, 2.0), 0.08, 0.42, 0.11, 0.0, 0.2, 0.0, 0.1, 0.16, 0.3)
	if r1:
		r1.rot = rot
		r1.o0 = dir * 0.1
		r1.ofs = dir * 0.2
	var r2 := _ring(fx, A_POINT, _hdr(ICE_TEAM, 1.8), 0.05, 0.27, 0.1, 0.03, 0.2, 0.0, 0.08, 0.2, 0.3)
	if r2:
		r2.rot = rot
		r2.o0 = dir * 0.3
		r2.ofs = dir * 0.62
	var zb := _z_along(dir)
	_sched(fx, &"muzzle_flakes", 0.0, A_POINT, dir * 0.08, 1.0, zb)
	_sched(fx, &"muzzle_motes", 0.0, A_POINT, dir * 0.04, 1.0, zb)
	_sched(fx, &"muzzle_vapor", 0.01, A_POINT, dir * 0.2, 1.0, zb)
	_start(fx)


func _frost_tracer(at: Variant, target: Variant) -> void:
	var impact := false
	var to: Variant = target
	if target is Dictionary:
		to = (target as Dictionary).get("to", null)
		impact = bool((target as Dictionary).get("impact", false))
	var xf: Variant = _muzzle_xf(at, to)
	if xf == null:
		return
	var mx: Transform3D = xf
	var a := mx.origin
	var bp: Variant = _point_of(to, 0.55)
	var b: Vector3
	if bp == null:
		b = a + mx.basis.z.normalized() * TRACER_LENGTH
	else:
		b = bp
		if b.distance_to(a) > TRACER_MAX:
			b = a + (b - a).normalized() * TRACER_MAX
	if a.distance_to(b) < 0.2:
		return
	var fx := _new_fx(&"frost_tracer", a, _team_of(at))
	fx.a = a
	fx.b = b
	fx.tpos = b
	fx.dst = _node(to)
	fx.impact = impact and bp != null
	fx.head_time = clampf(TRACER_HEAD * a.distance_to(b) / TRACER_LENGTH, 0.035, 0.12)
	fx.dur = maxf(TRACER_TIME, fx.head_time + 0.1)
	fx.line = _beam(fx, B_TRACER, 0.075, _hdr(ICE_GLOW, 2.2), Color(ICE_DEEP.srgb_to_linear(), 0.28), 0.0, 0.0,
			0.0, 0.03)
	fx.glow = _flare(fx, A_WORLD, a, _hdr(WHITE_COLD, 1.6), 0.32, 0.32, 0.0, 0.0, fx.head_time + 0.02, 0.0, 0.02)
	_start(fx)


func _rifle_impact(at: Variant, target: Variant) -> void:
	var t: Node3D = _node(target)
	var point: Variant = _point_of(at, 0.55)
	if point == null and t:
		point = _chest(t)
	if point == null:
		return
	var p: Vector3 = point
	var fx := _new_fx(&"rifle_impact", p, _team_of(t))
	fx.dur = 0.9
	var building := _is_building(t)
	var up := Vector3.UP
	_flare(fx, A_POINT, Vector3.ZERO, _hdr(WHITE_COLD, 2.0), 0.3, 0.95, 0.05, 0.0, 0.14, 0.0, 0.08, 1.0, 6.0)
	_flare(fx, A_POINT, Vector3.ZERO, _hdr(ICE_TEAM, 1.3), 0.5, 1.15, 0.08, 0.0, 0.3, 0.0, 0.18)
	_sched(fx, &"impact_shards", 0.0, A_POINT, Vector3.ZERO)
	_sched(fx, &"impact_flakes", 0.0, A_POINT, Vector3.ZERO)
	_sched(fx, &"impact_mist", 0.02, A_POINT, up * 0.1)
	if not building:
		var ground := p
		ground.y = t.global_position.y if t else p.y
		var g := ground - p
		var ring := _ring(fx, A_POINT, _hdr(ICE_GLOW, 1.4), 0.25, 1.0, 0.18, 0.0, 0.34, 0.0, 0.16, 0.12, 0.3)
		if ring:
			ring.o0 += g
			ring.ofs += g
		var patch := _frost_patch(fx, A_POINT, 0.45, 0.75, 0.12, 0.0, 0.9, 0.03, 0.45, 0.0)
		if patch:
			patch.o0 += g
			patch.ofs += g
	_start(fx)


func _rime_lock_aim(at: Variant, target: Variant) -> void:
	var tgt: Variant = target
	var time := AIM_TIME
	if target is Dictionary:
		tgt = (target as Dictionary).get("target", null)
		time = maxf(float((target as Dictionary).get("time", AIM_TIME)), 0.2)
	var src := _node(at)
	var a: Variant = null
	if src:
		a = _muzzle_pos(src)
	elif at is Vector3:
		a = at
	var bp: Variant = _point_of(tgt, 0.55)
	if a == null or bp == null:
		return
	# One aim per shooter: a new aim replaces the running one.
	if src:
		for old in _fx:
			if old.id == &"rime_lock_aim" and old.src == src and not old.done:
				_end(old, 0.08)
	var fx := _new_fx(&"rime_lock_aim", a, _team_of(at))
	fx.src = src
	fx.model = _rifle_model(src)
	fx.dst = _node(tgt)
	fx.has_src = src != null
	fx.has_dst = fx.dst != null
	fx.a = a
	fx.b = bp
	fx.tpos = _ground_of(tgt, bp)
	fx.head_time = time            # the charge time
	fx.dur = time + AIM_HOLD
	fx.line = _beam(fx, B_AIM, 0.065, _hdr(RIFLE, 2.6), Color(ICE_DEEP.srgb_to_linear() * 0.5, 0.35), 0.0, 0.0,
			0.06, 0.0)
	var r := clampf(_radius_of(fx.dst) * 2.4, 1.1, 3.2)
	fx.mark = _rune(fx, A_TARGET, R_RETICLE, _hdr(RIFLE, 1.9), r * 1.55, r, time, 0.0, 0.0, 0.12, 0.0)
	fx.glow = _flare(fx, A_WORLD, bp, _hdr(ICE_GLOW, 1.4), 0.25, 0.55, time, 0.0, 0.0, 0.1, 0.0, 0.0, 4.0, 0.6)
	_start(fx)


func _rime_lock_hit(at: Variant, target: Variant) -> void:
	var t: Node3D = _node(target)
	if t == null:
		t = _node(at)
	var point: Variant = _point_of(at, 0.55)
	if point == null and t:
		point = _chest(t)
	if point == null:
		return
	var p: Vector3 = point
	# The aim line at this victim (or ending near this point) snaps into the shot.
	var aim: Fx = null
	for f in _fx:
		if f.id != &"rime_lock_aim" or f.done:
			continue
		var same := t != null and f.dst != null and (f.dst == t or f.dst == _model_of(t) or _model_of(f.dst) == t)
		if same or f.b.distance_to(p) < 2.0:
			aim = f
			break
	var fx := _new_fx(&"rime_lock_hit", p, _team_of(t))
	fx.dur = 1.4
	var up := Vector3.UP
	var ground := p
	ground.y = t.global_position.y if t else p.y
	var g := ground - p
	var h := _h(t) if t else 1.6
	if aim:
		aim.done = true
		_end(aim, 0.05)
		var a := aim.a
		var shot := _beam(fx, B_SHOT, 0.13, _hdr(ICE_GLOW, 2.1), Color(ICE_DEEP.srgb_to_linear(), 0.4), 0.0, 0.26,
				0.0, 0.18)
		if shot:
			shot.pa = a
			shot.pb = p
			_params(shot, {&"head": 1.0, &"tail": 0.0})
		_flare(fx, A_WORLD, a, _hdr(WHITE_COLD, 1.5), 0.35, 0.8, 0.04, 0.0, 0.14, 0.0, 0.1, 1.0, 6.0)
	# Flash: a big six-point star + a wide cold halo.
	_flare(fx, A_POINT, Vector3.ZERO, _hdr(WHITE_COLD, 2.0), 0.6, 2.0, 0.07, 0.0, 0.28, 0.0, 0.2, 1.3, 6.0)
	_flare(fx, A_POINT, Vector3.ZERO, _hdr(ICE_TEAM, 1.2), 1.0, 2.4, 0.12, 0.0, 0.5, 0.0, 0.35)
	# The freeze column: a pillar of light up through the victim.
	var col := _beam(fx, B_SHOT, 0.55, _hdr(ICE_GLOW, 1.9), Color(ICE_DEEP.srgb_to_linear(), 0.2), 0.0, 0.34, 0.02,
			0.22)
	if col:
		col.pa = ground + up * 0.05
		col.pb = ground + up * maxf(h * 1.6, 2.6)
		_params(col, {&"head": 1.0, &"tail": 0.0})
	# Shock rings + the rime patch with a glowing rim.
	var r := clampf(_radius_of(t) * 3.6, 1.5, 3.4) if t else 1.8
	for spec: Array in [[_hdr(ICE_GLOW, 2.0), 0.4, r * 1.5, 0.3, 0.0, 0.55, 0.1], [_hdr(ICE_TEAM, 1.6), 0.3, r, 0.45,
			0.06, 0.75, 0.12]]:
		var ring := _ring(fx, A_POINT, spec[0], spec[1], spec[2], spec[3], spec[4], spec[5], 0.0, 0.25, spec[6], 0.3)
		if ring:
			ring.o0 += g
			ring.ofs += g
	var patch := _frost_patch(fx, A_POINT, r * 0.5, r * 1.05, 0.12, 0.0, 1.4, 0.03, 0.45, 1.0)
	if patch:
		patch.o0 += g
		patch.ofs += g
	# Ice spikes erupting around the victim.
	var spikes := _piece(fx, &"crystal", A_POINT, g, 0.02, 1.35, 0.0, 0.42)
	if spikes:
		_layout_spikes(spikes.n as MultiMeshInstance3D, r * 0.52, clampf(h / 1.8, 0.7, 2.2))
		_grow(spikes, Vector3(1.0, 0.05, 1.0), Vector3.ONE, 0.1)
		_params(spikes, {&"seed": _rng.randf() * 10.0})
	_sched(fx, &"freeze_shards", 0.0, A_POINT, Vector3.ZERO, clampf(h / 1.8, 0.8, 1.8))
	_sched(fx, &"freeze_flakes", 0.02, A_POINT, g + up * 0.2, clampf(r / 1.8, 0.8, 1.8))
	_sched(fx, &"freeze_mist", 0.03, A_POINT, g + up * 0.1, clampf(r / 1.8, 0.8, 1.8))
	_sched(fx, &"freeze_shards", 1.0, A_POINT, g + up * 0.5, 0.8)   # the spikes shatter
	_start(fx)


func _rime_lock_cancel(at: Variant) -> void:
	var src := _node(at)
	for f in _fx:
		if f.id != &"rime_lock_aim" or f.done or f.end_at >= 0.0:
			continue
		if (src and _same(f, src)) or (src == null and at is Vector3 and f.a.distance_to(at) < 2.0):
			_end(f, 0.2)


func _brace(at: Variant) -> void:
	var src := _node(at)
	var point: Variant = _point_of(at, 0.0)
	if point == null:
		return
	if src:
		for f in _fx:
			if f.id == &"brace" and f.end_at < 0.0 and _same(f, src):
				return   # already drawn under this rifleman
	var fx := _new_fx(&"brace", point, _team_of(at))
	fx.src = src
	fx.model = _rifle_model(src)
	fx.has_src = src != null
	fx.dur = INF if src else BRACE_SOLO
	fx.fade_len = 0.35
	fx.mark = _rune(fx, A_POINT, R_BRACE, _hdr(ICE_GLOW, 1.7), BRACE_RADIUS, BRACE_RADIUS, 0.0, 0.0,
			-0.001 if src else 0.0, 0.06, 0.0 if src else 0.4)
	fx.patch = _frost_patch(fx, A_POINT, 0.6, BRACE_RADIUS * 1.1, BRACE_TIME, 0.0, -0.001 if src else 0.0, 0.8,
			0.0 if src else 0.4, 0.0)
	# The circle closes: a ring pulses out, frost glints rise.
	var pulse := _ring(fx, A_POINT, _hdr(ICE_GLOW, 1.3), BRACE_RADIUS * 0.9, BRACE_RADIUS * 1.7, 0.4, BRACE_TIME,
			BRACE_TIME + 0.45, 0.0, 0.25, 0.12, 0.3)
	if pulse:
		pulse.o0 += Vector3.UP * 0.01
	_sched(fx, &"brace_frost", BRACE_TIME, A_POINT, Vector3.UP * 0.05)
	_start(fx)


func _brace_end(at: Variant) -> void:
	var src := _node(at)
	if src == null:
		return
	for f in _fx:
		if f.id == &"brace" and f.end_at < 0.0 and _same(f, src):
			_end(f, 0.35)


## True when the brace / aim effect `f` belongs to node `n` (the unit or its model).
func _same(f: Fx, n: Node3D) -> bool:
	if f.src == null or n == null:
		return false
	return f.src == n or (f.model != null and f.model == n) or f.src == _model_of(n) or _model_of(f.src) == n


# ---------------------------------------------------------------- tracked updates (every frame)

func _update(fx: Fx) -> void:
	match fx.id:
		&"rifle_shot":
			if fx.has_src and _alive_node(fx.src):
				var m: Variant = _muzzle_pos(fx.src)
				if m != null:
					fx.point = m
		&"frost_tracer":
			var head := clampf(fx.t / fx.head_time, 0.0, 1.0)
			var tail := clampf((fx.t - fx.head_time * 0.4) / maxf(fx.dur - fx.head_time * 0.4, 0.01), 0.0, 1.0)
			tail = tail * tail
			if fx.line:
				fx.line.pa = fx.a
				fx.line.pb = fx.b
				_params(fx.line, {&"head": head, &"tail": tail})
			if fx.glow:
				fx.glow.ofs = fx.a.lerp(fx.b, head)
				fx.glow.o0 = fx.glow.ofs
			if head >= 1.0 and not fx.done:
				fx.done = true
				if fx.impact:
					_rifle_impact(fx.b, fx.dst)
				elif fx.shown:
					_burst(&"impact_flakes", fx.b, 0.6, Basis.IDENTITY)
		&"rime_lock_aim":
			if fx.done or fx.end_at >= 0.0:
				pass
			elif (fx.has_src and not _alive(fx.src)) or (fx.has_dst and not _alive(fx.dst)):
				_end(fx, 0.15)
			elif fx.t >= fx.dur:
				_end(fx, 0.15)
			if fx.has_src and _alive_node(fx.src):
				var m: Variant = _muzzle_pos(fx.src)
				if m != null:
					fx.a = m
			if fx.has_dst and _alive_node(fx.dst):
				fx.b = _chest(fx.dst)
				fx.tpos = fx.dst.global_position
			var charge := clampf(fx.t / fx.head_time, 0.0, 1.0)
			if fx.line:
				fx.line.pa = fx.a
				fx.line.pb = fx.b
				_params(fx.line, {&"head": clampf(fx.t / 0.14, 0.0, 1.0), &"tail": 0.0, &"charge": charge})
			if fx.mark:
				fx.mark.n.set_instance_shader_parameter(&"draw", charge)
			if fx.glow:
				fx.glow.ofs = fx.b
				fx.glow.o0 = fx.b
		&"brace":
			if fx.has_src and fx.end_at < 0.0:
				if not _alive(fx.src):
					_end(fx, 0.35)
				else:
					fx.point = fx.src.global_position
			if fx.mark and fx.t <= BRACE_TIME + 0.1:
				fx.mark.n.set_instance_shader_parameter(&"draw", clampf(fx.t / BRACE_TIME, 0.0, 1.0))
				fx.mark.k = lerpf(1.0, 0.55, clampf((fx.t - 1.6) / 0.8, 0.0, 1.0))
			if fx.patch:
				fx.patch.k = lerpf(0.5, 0.32, clampf((fx.t - 1.2) / 1.0, 0.0, 1.0))


## Slow checks (4 x / s): fog, the brace stand-up poll.
func _refresh(fx: Fx) -> void:
	if fx.id == &"rime_lock_aim":
		fx.shown = _fog_ok(fx.team, fx.a) or _fog_ok(fx.team, fx.b)   # both teams see the aim line
	else:
		fx.shown = _fog_ok(fx.team, fx.point)
	if fx.id == &"brace" and fx.has_src and fx.end_at < 0.0 and fx.t >= BRACE_GRACE:
		var m: Variant = fx.model
		if _alive_node(m):
			if m.has_method(&"is_braced") and not bool(m.call(&"is_braced")):
				_end(fx, 0.35)
			elif m.has_method(&"brace_amount") and float(m.call(&"brace_amount")) < 0.5:
				_end(fx, 0.35)


# ---------------------------------------------------------------- argument helpers

## The muzzle frame from `at` (see rifle_shot), or null.
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
		if src == null or not is_instance_valid(src):
			continue
		if src.has_method(&"get_muzzle_xf"):
			var v: Variant = src.call(&"get_muzzle_xf")
			if v is Transform3D:
				return v
		if src.has_method(&"get_muzzle_position"):
			var o2: Vector3 = src.call(&"get_muzzle_position")
			var d2 := Vector3.ZERO
			if src.has_method(&"get_scope_position"):
				# scope lens -> muzzle crown runs 4.4 deg below the bore: lift it back onto the barrel line.
				d2 = (o2 - (src.call(&"get_scope_position") as Vector3)).normalized()
				d2 = (d2 + Vector3.UP * 0.077).normalized()
			elif aim != null:
				d2 = ((aim as Vector3) - o2).normalized()
			if d2.length_squared() < 0.5:
				d2 = _facing(n)
			return Transform3D(_z_along(d2), o2)
	# No muzzle hook: chest height, 0.9 m in front, toward the target (else the node's facing).
	var fwd := _facing(n)
	var o3 := n.global_position + Vector3.UP * 1.3 + fwd * 0.9
	if aim != null and (aim as Vector3).distance_to(o3) > 0.05:
		fwd = ((aim as Vector3) - o3).normalized()
	return Transform3D(_z_along(fwd), o3)


## World muzzle position of a shooter node (tracked lines), or null.
func _muzzle_pos(n: Node3D) -> Variant:
	if n == null or not is_instance_valid(n) or not n.is_inside_tree():
		return null
	for src: Object in [n, _model_of(n)]:
		if src and is_instance_valid(src):
			if src.has_method(&"get_muzzle_position"):
				return src.call(&"get_muzzle_position")
			if src.has_method(&"get_muzzle_xf"):
				var v: Variant = src.call(&"get_muzzle_xf")
				if v is Transform3D:
					return (v as Transform3D).origin
			if src.has_method(&"get_beam_origin"):
				return src.call(&"get_beam_origin")
	return n.global_position + Vector3.UP * 1.3 + _facing(n) * 0.9


func _facing(n: Node3D) -> Vector3:
	var fwd := n.global_basis.z
	fwd.y = 0.0
	return fwd.normalized() if fwd.length_squared() > 0.001 else Vector3.FORWARD


func _model_of(n: Variant) -> Node3D:
	if n == null or not is_instance_valid(n) or not (n is Node3D):
		return null
	if (n as Node3D).has_method(&"get_model"):
		var m: Variant = (n as Node3D).call(&"get_model")
		if m is Node3D and is_instance_valid(m):
			return m
	return null


## The rifleman model of a shooter node (the node itself when it is one), or null.
func _rifle_model(n: Node3D) -> Node3D:
	if n == null:
		return null
	if n.has_method(&"is_braced") or n.has_method(&"get_muzzle_position"):
		return n
	return _model_of(n)


func _alive(n: Variant) -> bool:
	if not _alive_node(n):
		return false
	if (n as Node3D).has_method(&"is_alive"):
		return bool((n as Node3D).call(&"is_alive"))
	return true


## A valid Node3D still in the tree (safe on freed references).
func _alive_node(n: Variant) -> bool:
	return n != null and is_instance_valid(n) and n is Node3D and (n as Node3D).is_inside_tree()


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


func _ground_of(v: Variant, fallback: Vector3) -> Vector3:
	var n := _node(v)
	if n:
		return n.global_position
	var g := fallback
	g.y -= 0.9
	return g


func _chest(n: Node3D) -> Vector3:
	return n.global_position + Vector3.UP * _h(n) * 0.55


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
	if n == null or not is_instance_valid(n):
		return 1.6
	var h: Variant = (n as Object).get(&"body_height")
	return float(h) if h != null else 1.6


func _radius_of(n: Variant) -> float:
	if n == null or not is_instance_valid(n):
		return 0.45
	var r: Variant = (n as Object).get(&"radius")
	if r is float or r is int:
		return float(r)
	if (n as Object).has_method(&"target_radius"):
		return float((n as Object).call(&"target_radius"))
	return 0.45


## Basis whose +Y is `d` (flash lances, upright rings: meshes whose axis / normal is local Y).
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
	fx.fade_len = END_FADE
	return fx


func _start(fx: Fx) -> void:
	_fx.append(fx)
	_refresh(fx)
	fx.check_left = CHECK_INTERVAL
	_tick(fx, 0.0)


## Starts the fade-out of a running effect (`time` s).
func _end(fx: Fx, time: float) -> void:
	if fx.end_at >= 0.0 and fx.end_at <= fx.t + time:
		return
	fx.fade_len = maxf(time, 0.01)
	fx.end_at = fx.t + time


## Advances one effect. Returns true when it is over.
func _tick(fx: Fx, delta: float) -> bool:
	fx.t += delta
	fx.check_left -= delta
	if fx.check_left <= 0.0:
		fx.check_left += CHECK_INTERVAL
		_refresh(fx)
	_update(fx)
	var ef := 1.0 if fx.end_at < 0.0 else clampf((fx.end_at - fx.t) / fx.fade_len, 0.0, 1.0)
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
	var f := ef * d.k
	if d.fin > 0.0:
		f = minf(f, lt / d.fin)
	if d.fout > 0.0 and off < INF:
		f = minf(f, (off - fx.t) / d.fout)
	f = clampf(f, 0.0, 1.0)
	var k := 1.0
	if d.grow > 0.0:
		k = _ease(clampf(lt / d.grow, 0.0, 1.0))
	var s := d.s0.lerp(d.s1, k)
	var xf: Transform3D
	if d.beam:
		var ax := d.pb - d.pa
		var ln := maxf(ax.length(), 0.01)
		var bb := _y_along(ax if ax.length_squared() > 0.0001 else Vector3.UP)
		xf = Transform3D(Basis(bb.x, bb.y * ln, bb.z), (d.pa + d.pb) * 0.5)
	else:
		xf = Transform3D(d.rot * Basis.from_scale(s), _anchor(fx, d.at) + d.o0.lerp(d.ofs, k))
	if not xf.is_equal_approx(n.transform):
		n.transform = xf
	if absf(f - d.lf) > 0.003:
		d.lf = f
		n.set_instance_shader_parameter(&"fade", f)
	if AGE_POOLS.has(d.pool) and lt <= float(AGE_POOLS[d.pool]):
		n.set_instance_shader_parameter(&"age", lt)
	if d.pool == &"rune" and absf(s.x - d.lr) > 0.001:
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
	fx.line = null
	fx.mark = null
	fx.glow = null
	fx.patch = null


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


## Thin ring (vfx_ring.gdshader: a glowing band, no fill) growing from radius r0 to r1; flat on the ground unless the
## caller sets `rot`.
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
		fin: float, fout: float, rays: float = 0.0, spikes: float = 4.0, pulse: float = 0.0) -> Piece:
	var d := _piece(fx, &"flare", at, ofs, on, off, fin, fout)
	_grow(d, s0, s1, grow)
	_params(d, {&"tint": tint, &"rays": rays, &"spikes": spikes, &"pulse": pulse, &"seed": _rng.randf() * 10.0,
			&"halo": Color(0, 0, 0, 0)})
	return d


## Rime patch on the ground (ice_frost.gdshader), radius r0 -> r1; `rim` 1 = the bright freeze rim.
func _frost_patch(fx: Fx, at: int, r0: float, r1: float, grow: float, on: float, off: float, fin: float,
		fout: float, rim: float) -> Piece:
	_layer = (_layer + 1) % 8
	var d := _piece(fx, &"frost", at, Vector3.UP * (0.03 + 0.006 * float(_layer)), on, off, fin, fout)
	_grow(d, Vector3(r0, 1.0, r0), Vector3(r1, 1.0, r1), grow)
	_params(d, {&"seed": _rng.randf() * 10.0, &"rim": rim})
	return d


## Rune mark on the ground (unit_ice_rifle_rune.gdshader), radius r0 -> r1.
func _rune(fx: Fx, at: int, pattern: int, tint: Color, r0: float, r1: float, grow: float, on: float, off: float,
		fin: float, fout: float) -> Piece:
	_layer = (_layer + 1) % 8
	var d := _piece(fx, &"rune", at, Vector3.UP * (0.07 + 0.006 * float(_layer)), on, off, fin, fout)
	_grow(d, Vector3(r0, 1.0, r0), Vector3(r1, 1.0, r1), grow)
	_params(d, {&"tint": tint, &"pattern": float(pattern), &"seed": _rng.randf() * 10.0, &"draw": 0.0})
	return d


## A line (unit_ice_rifle_beam.gdshader) from piece.pa to piece.pb (set by the caller / _update).
func _beam(fx: Fx, mode: int, width: float, core: Color, edge: Color, on: float, off: float, fin: float,
		fout: float) -> Piece:
	var d := _piece(fx, &"beam", A_WORLD, Vector3.ZERO, on, off, fin, fout)
	if d == null:
		return null
	d.beam = true
	d.pa = fx.a
	d.pb = fx.b
	_params(d, {&"mode": float(mode), &"width": width, &"core": core, &"edge": edge, &"head": 0.0, &"tail": 0.0,
			&"charge": 0.0, &"seed": _rng.randf() * 10.0})
	return d


## 9 spikes around radius r: 7 on the rim leaning outward, 2 small ones leaning in over the victim; `hs` = height scale.
func _layout_spikes(mmi: MultiMeshInstance3D, r: float, hs: float) -> void:
	var mm := mmi.multimesh
	var spin := _rng.randf() * TAU
	for i in SPIKES:
		var rim := i < 7
		var a := spin + (TAU * (float(i) / 7.0 + _rng.randf_range(-0.03, 0.03)) if rim else _rng.randf() * TAU)
		var out := Vector3(cos(a), 0.0, sin(a))
		var dist := r * _rng.randf_range(0.85, 1.05) if rim else r * _rng.randf_range(0.45, 0.6)
		var h := _rng.randf_range(0.8, 1.45) * hs if rim else _rng.randf_range(0.45, 0.7) * hs
		var w := _rng.randf_range(1.0, 1.6) * clampf(hs, 0.8, 1.6)
		var lean := _rng.randf_range(0.3, 0.6) if rim else -_rng.randf_range(0.35, 0.55)
		var axis := Vector3.UP.cross(out).normalized()
		var rot := Basis(axis, lean) * Basis(Vector3.UP, _rng.randf() * TAU)
		var base := out * dist + Vector3.DOWN * 0.08
		mm.set_instance_transform(i, Transform3D(rot * Basis.from_scale(Vector3(w, h, w)), base + rot * Vector3(0.0, h * 0.5, 0.0)))


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


# ---------------------------------------------------------------- shared resources (built once)

func _build_shared() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(2.0, 2.0)
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	var meshes := {&"flash": quad, &"flare": quad, &"ring": plane, &"beam": quad, &"frost": plane, &"rune": plane}
	var mats := {&"flash": _shader_mat(FLASH_SHADER), &"flare": _shader_mat(FLARE_SHADER),
			&"ring": _shader_mat(RING_SHADER), &"beam": _shader_mat(BEAM_SHADER), &"frost": _shader_mat(FROST_SHADER),
			&"rune": _shader_mat(RUNE_SHADER), &"crystal": _shader_mat(CRYSTAL_SHADER)}
	var spike := CylinderMesh.new()   # a hexagonal ice spike, height 1 centred on 0
	spike.top_radius = 0.0
	spike.bottom_radius = 0.13
	spike.height = 1.0
	spike.radial_segments = 6
	spike.rings = 1
	var spike_aabb := AABB(Vector3(-4.0, -1.0, -4.0), Vector3(8.0, 6.0, 8.0))
	for pool: StringName in POOL_SIZES:
		var arr: Array = []
		for i in int(POOL_SIZES[pool]):
			var g: GeometryInstance3D
			if pool == &"crystal":
				var mm := MultiMesh.new()
				mm.transform_format = MultiMesh.TRANSFORM_3D
				mm.mesh = spike
				mm.instance_count = SPIKES
				mm.custom_aabb = spike_aabb
				var mmi := MultiMeshInstance3D.new()
				mmi.multimesh = mm
				g = mmi
			else:
				var m := MeshInstance3D.new()
				m.mesh = meshes[pool]
				g = m
			g.name = "%s%d" % [String(pool).capitalize(), i]
			g.material_override = mats[pool]
			g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			g.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
			g.visible = false
			if pool == &"flare" or pool == &"flash":
				g.extra_cull_margin = 2.0    # billboards / axial lances leave their mesh AABB
			elif pool == &"beam":
				g.extra_cull_margin = 16.0   # the line is rebuilt in the shader from the node's Y axis
			add_child(g)
			arr.append(g)
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
	_passes[&"add_flake"] = _particle_quad(_shape_tex(&"flake"), BaseMaterial3D.BLEND_MODE_ADD)
	_passes[&"add_glint"] = _particle_quad(_shape_tex(&"glint"), BaseMaterial3D.BLEND_MODE_ADD)
	_passes[&"mix_shard"] = _particle_quad(_shape_tex(&"shard"), BaseMaterial3D.BLEND_MODE_MIX)
	_passes[&"mix_mist"] = _particle_quad(_shape_tex(&"mist"), BaseMaterial3D.BLEND_MODE_MIX)
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
	mat.disable_fog = blend == BaseMaterial3D.BLEND_MODE_ADD  # G-E 5: an additive quad must not fog
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
				&"flake":
					# A six-armed snowflake: arms with two pairs of forward branches, a hex core, a soft glow.
					var ang := atan2(v, u)
					var sector := PI / 3.0
					var af := fposmod(ang + sector * 0.5, sector) - sector * 0.5
					var px := r * cos(af)
					var py := absf(r * sin(af))
					var q := Vector2(px, py)
					var dd := _seg(q, Vector2.ZERO, Vector2(0.86, 0.0))
					dd = minf(dd, _seg(q, Vector2(0.4, 0.0), Vector2(0.56, 0.2)))
					dd = minf(dd, _seg(q, Vector2(0.62, 0.0), Vector2(0.73, 0.13)))
					dd = minf(dd, r - 0.13)
					a = clampf(1.0 - smoothstep(0.045, 0.1, dd), 0.0, 1.0)
					a = maxf(a, exp(-maxf(dd, 0.0) * 9.0) * 0.35 * clampf((1.0 - r) / 0.2, 0.0, 1.0))
				&"glint":
					# A four-point sparkle with a round core.
					var s1 := exp(-absf(u) * 16.0) * exp(-absf(v) * 2.6)
					var s2 := exp(-absf(v) * 16.0) * exp(-absf(u) * 2.6)
					a = clampf(maxf(s1, s2) + exp(-r * 7.0) * 0.8, 0.0, 1.0) * clampf((1.0 - r) / 0.15, 0.0, 1.0)
				&"shard":
					# A long ice sliver: a diamond, the left facet lit, the right one in shade.
					var e := absf(u) / 0.3 + absf(v) / 0.95
					a = clampf((1.0 - e) / 0.08, 0.0, 1.0)
					shade = 1.0 if u < 0.0 else 0.66
					shade *= 0.85 + 0.15 * (1.0 - absf(v))
				&"mist":
					var nse := _vn(u * 2.3 + 3.1, v * 2.3 + 8.3) * 0.6 + _vn(u * 5.1 + 1.7, v * 5.1 - 2.2) * 0.4
					a = clampf((1.0 - r) * 1.6 + (nse - 0.5) * 0.9 - 0.2, 0.0, 1.0)
					a = a * a * (3.0 - 2.0 * a) * clampf((1.0 - r) / 0.2, 0.0, 1.0)
					shade = clampf(0.86 + 0.12 * (0.5 - v * 0.5) + (nse - 0.5) * 0.2, 0.0, 1.0)
			img.set_pixel(x, y, Color(shade, shade, shade, a))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _seg(p: Vector2, a: Vector2, b: Vector2) -> float:
	var pa := p - a
	var ba := b - a
	var h := clampf(pa.dot(ba) / ba.dot(ba), 0.0, 1.0)
	return (pa - ba * h).length()


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
	var white := _hdr(WHITE_COLD, 2.6)
	var glow := _hdr(ICE_GLOW, 2.0)
	var team := _hdr(ICE_TEAM, 1.6)
	var deep := _hdr(ICE_DEEP, 1.2, 0.0)
	var frost := FROST.srgb_to_linear()
	var mist := MIST.srgb_to_linear()
	match key:
		&"muzzle_flakes":
			# Snowflakes blown out of the crown (+Z), braking hard, then hanging and turning as they fade.
			_shape_sphere(m, 0.05)
			m.direction = Vector3(0, 0, 1)
			m.spread = 24.0
			m.initial_velocity_min = 3.0
			m.initial_velocity_max = 7.5
			m.damping_min = 7.0
			m.damping_max = 10.0
			m.gravity = Vector3(0, -0.4, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			m.angular_velocity_min = -220.0
			m.angular_velocity_max = 220.0
			_size(m, 0.08, 0.14, &"hold")
			m.color_ramp = _ramp_at([0.0, 0.2, 0.65, 1.0], [white, glow, team, deep])
		&"muzzle_motes":
			_shape_sphere(m, 0.04)
			m.direction = Vector3(0, 0, 1)
			m.spread = 9.0
			m.initial_velocity_min = 8.0
			m.initial_velocity_max = 14.0
			m.damping_min = 7.0
			m.damping_max = 11.0
			m.particle_flag_align_y = true
			_size(m, 0.03, 0.05, &"shrink")
			m.color_ramp = _ramp([white, glow, team, deep])
		&"muzzle_vapor":
			# A puff of cold vapour rolling off the crown.
			_shape_sphere(m, 0.08)
			m.direction = Vector3(0, 0, 1)
			m.spread = 30.0
			m.initial_velocity_min = 0.8
			m.initial_velocity_max = 1.6
			m.damping_min = 2.0
			m.damping_max = 3.0
			m.gravity = Vector3(0, -0.15, 0)   # cold air sinks
			m.angle_min = -180.0
			m.angle_max = 180.0
			_size(m, 0.32, 0.5, &"grow")
			m.color_ramp = _ramp([Color(mist, 0.0), Color(mist, 0.38), Color(mist, 0.0)])
		&"impact_shards":
			_shape_sphere(m, 0.12)
			m.direction = Vector3.UP
			m.spread = 75.0
			m.initial_velocity_min = 2.5
			m.initial_velocity_max = 5.5
			m.gravity = Vector3(0, -14.0, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			m.angular_velocity_min = -520.0
			m.angular_velocity_max = 520.0
			_size(m, 0.09, 0.16, &"hold")
			m.color_initial_ramp = _ramp(_lin([Color(0.80, 0.93, 1.0), Color(0.62, 0.82, 0.98), Color(0.93, 0.98, 1.0)]))
			m.color_ramp = _ramp([Color(1.3, 1.3, 1.3, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0.0)])
		&"impact_flakes":
			_shape_sphere(m, 0.15)
			m.direction = Vector3.UP
			m.spread = 90.0
			m.initial_velocity_min = 1.0
			m.initial_velocity_max = 2.6
			m.damping_min = 2.0
			m.damping_max = 3.0
			m.gravity = Vector3(0, -1.0, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			m.angular_velocity_min = -160.0
			m.angular_velocity_max = 160.0
			_size(m, 0.08, 0.14, &"hold")
			m.color_ramp = _ramp_at([0.0, 0.15, 0.6, 1.0], [white, glow, team, deep])
		&"impact_mist":
			_shape_sphere(m, 0.2)
			m.direction = Vector3.UP
			m.spread = 80.0
			m.initial_velocity_min = 0.4
			m.initial_velocity_max = 1.0
			m.damping_min = 1.5
			m.damping_max = 2.0
			m.gravity = Vector3(0, -0.1, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			_size(m, 0.4, 0.65, &"grow")
			m.color_ramp = _ramp([Color(mist, 0.0), Color(mist, 0.3), Color(mist, 0.0)])
		&"freeze_shards":
			_shape_sphere(m, 0.3)
			m.direction = Vector3.UP
			m.spread = 60.0
			m.initial_velocity_min = 4.0
			m.initial_velocity_max = 8.5
			m.gravity = Vector3(0, -15.0, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			m.angular_velocity_min = -600.0
			m.angular_velocity_max = 600.0
			_size(m, 0.12, 0.24, &"hold")
			m.color_initial_ramp = _ramp(_lin([Color(0.80, 0.93, 1.0), Color(0.55, 0.78, 0.97), Color(0.95, 0.99, 1.0)]))
			m.color_ramp = _ramp([Color(1.4, 1.4, 1.4, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0.0)])
		&"freeze_flakes":
			_shape_ring(m, 0.9, 0.2)
			m.direction = Vector3.UP
			m.spread = 30.0
			m.initial_velocity_min = 1.5
			m.initial_velocity_max = 3.6
			m.radial_velocity_min = 0.8
			m.radial_velocity_max = 2.0
			m.damping_min = 1.5
			m.damping_max = 2.5
			m.gravity = Vector3(0, -0.6, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			m.angular_velocity_min = -180.0
			m.angular_velocity_max = 180.0
			_size(m, 0.1, 0.18, &"hold")
			m.color_ramp = _ramp_at([0.0, 0.15, 0.6, 1.0], [white, glow, team, deep])
		&"freeze_mist":
			# A ring of cold mist rolling out along the ground.
			_shape_ring(m, 0.6, 0.1)
			m.direction = Vector3.UP
			m.spread = 20.0
			m.initial_velocity_min = 0.2
			m.initial_velocity_max = 0.6
			m.radial_velocity_min = 2.5
			m.radial_velocity_max = 4.0
			m.damping_min = 2.5
			m.damping_max = 3.5
			m.gravity = Vector3(0, 0.05, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			_size(m, 0.6, 1.0, &"grow")
			m.color_ramp = _ramp([Color(frost, 0.0), Color(frost, 0.26), Color(frost, 0.0)])
		&"brace_frost":
			# Frost glints rising off the closed circle.
			_shape_ring(m, 0.95, 0.05)
			m.direction = Vector3.UP
			m.spread = 12.0
			m.initial_velocity_min = 0.6
			m.initial_velocity_max = 1.4
			m.damping_min = 0.8
			m.damping_max = 1.2
			m.angle_min = -180.0
			m.angle_max = 180.0
			_size(m, 0.08, 0.14, &"shrink")
			m.color_ramp = _ramp_at([0.0, 0.2, 1.0], [white, glow, deep])
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


## Particle sizes in metres + a scale curve: shrink (motes), grow (mist), hold (flakes, chips).
func _size(m: ParticleProcessMaterial, lo: float, hi: float, kind: StringName) -> void:
	m.scale_min = lo
	m.scale_max = hi
	match kind:
		&"grow":
			m.scale_curve = _curve([Vector2(0.0, 0.3), Vector2(0.3, 1.0), Vector2(1.0, 0.6)])
		&"hold":
			m.scale_curve = _curve([Vector2(0.0, 0.6), Vector2(0.1, 1.0), Vector2(0.8, 1.0), Vector2(1.0, 0.4)])
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
