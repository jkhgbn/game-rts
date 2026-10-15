class_name CasterFireVfx
extends Node3D
## Fire caster effects (caster-units.md 5.1 / 10.5, task CU.V5 Fire half): the Kilnwarden's Slag Rain, the `slagged`
## status, Mana Scald and the Stoke passive. An effect FAMILY of UnitVfx (art/vfx/unit_vfx.gd loads this file from its
## MODULES list and forwards the ids below); callers never reach it directly:
##   var vfx := get_tree().get_first_node_in_group(&"unit_vfx")
##   if vfx: vfx.play(&"slag_rain", point, kilnwarden)
## It can also live on its own (tests, the Art Lab `kind=vfx`, docs/art/ingame_grade/caster_lineup.gd). Draw-only: it
## never touches gameplay (damage, statuses, mana stay in CasterAbility).
##
## Ids and their arguments (`target` may always be null):
##   slag_rain   at = the landing point (Vector3, the spell's target point). target = the Kilnwarden (Unit or its model:
##               the glob leaves the model's get_ingot_point()), a Vector3 launch point, or a Dictionary
##               {from: Node3D / Vector3, radius: float (3.0), team: int}. An orange ring r 3 shows on the ground (both
##               teams) during the 0.6 s flight; a molten glob arcs from the ingot trailing smoke; the impact throws a
##               splash of dark-orange droplets, a flash and a shock ring, and leaves a crusted disc whose cracks cool
##               from orange to grey over 10 s.
##   slagged     at = the slagged unit (Node3D; a Vector3 = a ground point, for previews). target = the duration (float,
##               default 10; heroes 5) or {duration}. First the model's set_status(&"slagged", true) is tried (a model
##               that shows its own crust returns true); else a dark crust with orange cracks at its feet and 6 slow
##               orange drips falling off its legs follow it. Playing it again on the same unit refreshes it. It ends
##               with the duration, with the unit's death, or with `slagged_end` (at = the unit; not in EFFECTS: it
##               draws nothing).
##   mana_scald  at = the Kilnwarden (Node3D: the lash leaves the model's get_palm_point()) or a Vector3; target = the
##               victim (Node3D, its head) or a Vector3, or {from, to}. A white-blue steam lash snaps from the palm to
##               the target (0.3 s), a steam burst and a cold flash at the target's head.
##   stoke       at = the slagged unit that died (Node3D / Vector3); target = the Kilnwarden (its kiln mouth,
##               get_kiln_point()) or a Vector3. An ember arcs from the corpse into the kiln (0.5 s) and flares there.
## Fog: effects of the local team always show; others only where the local team sees (FogOfWar.is_visible), checked 4
## times per second. Budget: every mesh piece and emitter is built in _ready and pooled (no node, material or mesh
## after _ready; looks via instance uniforms), 0 lights, no shadows; particles are not started beyond 45 m.
## Shaders reused read-only: champion_ground (crust, soot), vfx_ring (flight ring, shock, cooling cracks),
## champion_flare (glob, flashes), vfx_beam (the steam lash).

const GROUP := &"caster_fire_vfx"
const EFFECTS: Array[StringName] = [&"slag_rain", &"slagged", &"mana_scald", &"stoke"]
const CONTROL: Array[StringName] = [&"slagged_end"]

# Palette: the Kilnwarden's bolt (1.0, 0.55, 0.20), the `slagged` status (0.95, 0.45, 0.10), steam white-blue.
const MOLTEN := Color(1.0, 0.55, 0.20)
const MOLTEN_HOT := Color(1.0, 0.84, 0.50)
const SLAG := Color(0.95, 0.45, 0.10)
const CRUST := Color(0.16, 0.11, 0.08)
const COOL := Color(0.40, 0.37, 0.34)
const STEAM := Color(0.86, 0.94, 1.0)
const STEAM_BLUE := Color(0.50, 0.78, 1.0)

const SLAG_RADIUS := 3.0
const FLIGHT := 0.6
const ARC := 2.2
const CRUST_TIME := 10.0
const SLAG_TIME := 10.0
const LASH_TIME := 0.3
const STOKE_TIME := 0.5
const PARTICLE_RANGE := 45.0
const CHECK_INTERVAL := 0.25
const FOG_RESCAN := 1.0
const END_FADE := 0.25
const BURSTS_PER_FRAME := 24

enum { A_POINT, A_TARGET, A_WORLD }
enum { G_SHOCK = 0, G_SOOT = 5 }   # champion_ground.gdshader patterns used here

## Mesh pools (pre-built): pool -> size. `warn` holds only the short slag_rain landing / shock rings and `crust` /
## `crust_ring` only the long `slagged` looks, so many slagged units (10 s each) never starve the landing warning.
const POOL_SIZES := {&"disc": 28, &"ring": 20, &"warn": 12, &"flare": 32, &"beam": 6, &"crust": 24, &"crust_ring": 24}
const DISC_POOLS: Array[StringName] = [&"disc", &"crust"]
## One-shot bursts: look -> [amount, lifetime, draw pass, pool size, explosiveness, visibility half-extent (m)].
const BURSTS := {
	&"glob_smoke": [5, 0.9, &"mix_smoke", 16, 0.8, 3.0],
	&"slag_splash": [22, 0.85, &"add_dot", 6, 1.0, 5.0],
	&"slag_smoke": [10, 1.5, &"mix_smoke", 6, 0.9, 5.0],
	&"steam_burst": [12, 0.9, &"mix_smoke", 8, 0.9, 3.0],
	&"steam_sparks": [8, 0.35, &"add_dot", 8, 1.0, 3.0],
	&"stoke_puff": [7, 0.5, &"add_dot", 8, 1.0, 3.0],
}
const OPTIONAL_BURSTS: Array[StringName] = [&"glob_smoke", &"steam_sparks", &"stoke_puff"]
## Looping drip emitters for `slagged` (one per slagged unit shown; the rest show the crust only).
const DRIP_POOL := 16

const GROUND_SHADER := preload("res://art/vfx/champion_ground.gdshader")
const RING_SHADER := preload("res://art/vfx/vfx_ring.gdshader")
const FLARE_SHADER := preload("res://art/vfx/champion_flare.gdshader")
const BEAM_SHADER := preload("res://art/vfx/vfx_beam.gdshader")


## One running effect.
class Fx:
	extends RefCounted
	var id: StringName
	var t := 0.0
	var dur := 1.0
	var point := Vector3.ZERO        # anchor A_POINT (follows `follow`)
	var tpos := Vector3.ZERO         # anchor A_TARGET (follows `tnode`)
	var team := -1
	var end_at := -1.0
	var shown := true
	var check_left := 0.0
	var follow: Node3D = null
	var tnode: Node3D = null
	var tlift := 0.0                 # A_TARGET height above tnode's origin
	var pieces: Array[Piece] = []
	var bursts: Array[Dictionary] = []
	var bursts_left := 0
	# flight (slag glob, stoke ember): a flare moved along an arc from `a` to `b`
	var mover: Piece = null
	var a := Vector3.ZERO
	var b := Vector3.ZERO
	var src: Node3D = null           # live source (the Kilnwarden model) for the lash tail
	var fly := 0.6
	var arc := 2.0
	var trail_left := 0.0
	var lash: Piece = null
	var drips: GPUParticles3D = null
	var unit_key := 0


## One pooled mesh of an effect (TradeVfx.Piece pattern) + an optional colour ramp on one instance uniform.
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
	var age_until := 1.05
	var lf := -1.0
	var lr := -1.0
	var ramp_param: StringName = &""
	var c0 := Color.WHITE
	var c1 := Color.WHITE
	var ramp_time := 0.0
	var lc := -1.0
	var free_move := false           # position written by the effect itself (movers, beams)


var _fx: Array[Fx] = []
var _free: Dictionary = {}
var _all: Dictionary = {}
var _bursts: Dictionary = {}
var _burst_next: Dictionary = {}
var _live_bursts: Array[Dictionary] = []
var _bursts_this_frame := 0
var _drips_free: Array[GPUParticles3D] = []
var _slagged: Dictionary = {}       # unit instance id -> Fx
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
	_rng.seed = 5101
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
		var bd: Dictionary = _live_bursts[i]
		bd["left"] = float(bd["left"]) - delta
		if float(bd["left"]) <= 0.0:
			var p: GPUParticles3D = bd["p"]
			p.emitting = false
			p.visible = false
			_live_bursts.remove_at(i)
	if _fx.is_empty() and _live_bursts.is_empty():
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
	return EFFECTS.has(id) or CONTROL.has(id)


## Plays effect `id` (see the header). Returns true for the ids of this family (handled, even when fog hides it or a
## pool is full), false for any other id.
func play(id: StringName, at: Variant, target: Variant = null) -> bool:
	if not handles(id):
		return false
	if not is_node_ready() or not is_inside_tree():
		return true
	match id:
		&"slag_rain": _slag_rain(at, target)
		&"slagged": _slagged_on(at, target)
		&"slagged_end": _slagged_off(at)
		&"mana_scald": _mana_scald(at, target)
		&"stoke": _stoke(at, target)
	return true


func active_count() -> int:
	return _fx.size()


func active_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for fx in _fx:
		out.append(fx.id)
	return out


## Pooled pieces still on screen + bursts / drip emitters still alive (0 once everything has ended).
func live_count() -> int:
	var n := _live_bursts.size()
	for pool: StringName in _all:
		for g: GeometryInstance3D in _all[pool]:
			if g.visible:
				n += 1
	for fx in _fx:
		if fx.drips:
			n += 1
	return n


## Units currently showing the slagged look (tests).
func slagged_count() -> int:
	return _slagged.size()


# ---------------------------------------------------------------- the effects

func _slag_rain(at: Variant, target: Variant) -> void:
	var land: Variant = _point_of(at, 0.0)
	if land == null:
		return
	var c: Vector3 = land
	var radius := SLAG_RADIUS
	var src_v: Variant = target
	var team := -1
	if target is Dictionary:
		var d: Dictionary = target
		src_v = d.get("from")
		radius = clampf(float(d.get("radius", radius)), 1.0, 8.0)
		team = int(d.get("team", -1))
	var src := _node(src_v)
	var from: Variant = null
	if src_v is Vector3:
		from = src_v
	elif src:
		from = _call_point(src, &"get_ingot_point")
		if from == null:
			from = src.global_position + Vector3.UP * _h(src) * 0.95
		if team < 0:
			team = _team_of(src)
	if from == null:
		from = c + Vector3(0, 2.4, -4.0)
	var fx := _new_fx(&"slag_rain", c, team)
	fx.a = from
	fx.b = c + Vector3.UP * 0.15
	fx.fly = FLIGHT
	fx.arc = ARC
	fx.dur = FLIGHT + CRUST_TIME
	var k := radius / SLAG_RADIUS
	# During the flight: the landing ring (both teams see where it falls) with a faint warm floor.
	var warn := _ring(fx, A_POINT, _hdr(MOLTEN, 1.25), radius * 0.92, radius, 0.25, 0.0, FLIGHT + 0.06, 0.1, 0.08, 0.07, 0.18,
		&"warn")
	_params(warn, {&"fill": Color(0.20, 0.07, 0.02, 0.18)})
	# The glob: a hot molten flare (its core white-orange) that the tick moves along the arc.
	var glob := _flare(fx, A_WORLD, from, _hdr(MOLTEN, 2.2), 0.45, 0.62, 0.15, 0.0, FLIGHT + 0.02, 0.04, 0.04, 0.35, 6.0)
	if glob:
		glob.free_move = true
		_params(glob, {&"pulse": 1.0, &"halo": Color(0.12, 0.04, 0.01, 0.45)})
	fx.mover = glob
	fx.trail_left = 0.0
	# The impact (scheduled at the landing): flash, shock ring, crust + cooling cracks, splash and smoke.
	var f := FLIGHT
	_flare(fx, A_POINT, Vector3.UP * 0.5, _hdr(MOLTEN_HOT, 1.8), 1.0 * k, 2.0 * k, 0.1, f, f + 0.35, 0.0, 0.25, 0.7, 8.0)
	_ring(fx, A_POINT, _hdr(MOLTEN, 1.6), 0.4, radius * 1.08, 0.28, f, f + 0.55, 0.0, 0.3, 0.1, 0.15, &"warn")
	var soot := _disc(fx, A_POINT, G_SOOT, CRUST, radius * 0.75, radius * 1.02, 0.25, f, f + CRUST_TIME, 0.05, 1.5)
	if soot:
		soot.age_until = 0.0
	var cracks := _ring(fx, A_POINT, _hdr(MOLTEN, 1.5), radius * 0.72, radius * 0.97, 0.25, f, f + CRUST_TIME, 0.05, 1.5,
		0.07, 0.06)
	if cracks:
		_params(cracks, {&"fill": Color(0.12, 0.07, 0.04, 0.32)})
		_ramp(cracks, &"tint", _hdr(MOLTEN, 1.5), Color(COOL.r * 0.25, COOL.g * 0.25, COOL.b * 0.25, 0.4), CRUST_TIME)
	var core := _disc(fx, A_POINT, G_SHOCK, _hdr(SLAG, 1.2), radius * 0.25, radius * 0.45, 0.3, f, f + 1.8, 0.0, 1.4)
	if core:
		_ramp(core, &"tint", _hdr(SLAG, 1.2), Color(0.1, 0.05, 0.02, 0.2), 1.8)
	_sched(fx, &"slag_splash", f, A_POINT, Vector3.UP * 0.2, k)
	_sched(fx, &"slag_smoke", f + 0.05, A_POINT, Vector3.UP * 0.3, k)
	_start(fx)
	if fx.shown:
		_gplay(&"slag_rain", c, {"from": from, "r": radius, "team": team, "fly": FLIGHT, "arc": ARC})


func _slagged_on(at: Variant, target: Variant) -> void:
	var unit := _node(at)
	var dur := SLAG_TIME
	if target is float or target is int:
		dur = float(target)
	elif target is Dictionary:
		dur = float((target as Dictionary).get("duration", dur))
	dur = clampf(dur, 0.5, 60.0)
	if unit:
		var key := unit.get_instance_id()
		if _slagged.has(key):
			var old: Fx = _slagged[key]
			old.dur = old.t + dur
			old.end_at = -1.0
			return
		var model := _model_of(unit)
		if model and model.has_method(&"set_status") and bool(model.call(&"set_status", &"slagged", true)):
			var mfx := _new_fx(&"slagged", unit.global_position, _team_of(unit))
			mfx.follow = unit
			mfx.dur = dur
			mfx.unit_key = key
			_slagged[key] = mfx
			_start(mfx)
			return
	var p: Variant = _point_of(at, 0.0)
	if p == null:
		return
	var fx := _new_fx(&"slagged", p, _team_of(unit))
	fx.follow = unit
	fx.dur = dur
	var r := _radius(unit) if unit else 0.45
	var h := _h(unit) if unit else 1.6
	var crust := _disc(fx, A_POINT, G_SOOT, CRUST, r * 1.1, r * 1.6, 0.3, 0.0, -0.0001, 0.2, 0.6, &"crust")
	if crust:
		crust.age_until = 0.0
	var glow := _ring(fx, A_POINT, _hdr(SLAG, 1.3), r * 1.1, r * 1.55, 0.3, 0.0, -0.0001, 0.2, 0.6, 0.12, 0.1, &"crust_ring")
	if glow:
		_params(glow, {&"fill": Color(0.09, 0.05, 0.03, 0.45)})
	if not _drips_free.is_empty():
		var dp: GPUParticles3D = _drips_free.pop_back()
		dp.scale = Vector3(r / 0.45, maxf(h, 0.8) / 1.6, r / 0.45)
		dp.global_position = p
		dp.visible = true
		dp.emitting = true
		fx.drips = dp
	if unit:
		fx.unit_key = unit.get_instance_id()
		_slagged[fx.unit_key] = fx
	_start(fx)


func _slagged_off(at: Variant) -> void:
	var unit := _node(at)
	if unit == null:
		return
	var key := unit.get_instance_id()
	if _slagged.has(key):
		var fx: Fx = _slagged[key]
		if fx.end_at < 0.0:
			fx.end_at = fx.t + END_FADE


func _mana_scald(at: Variant, target: Variant) -> void:
	var from_v: Variant = at
	var to_v: Variant = target
	if target is Dictionary:
		from_v = (target as Dictionary).get("from", at)
		to_v = (target as Dictionary).get("to")
	var src := _node(from_v)
	var from: Variant = null
	if src:
		from = _call_point(src, &"get_palm_point")
		if from == null:
			from = src.global_position + Vector3.UP * _h(src) * 0.6
	elif from_v is Vector3:
		from = (from_v as Vector3) + Vector3.UP * 1.1
	var victim := _node(to_v)
	var dest: Variant = null
	if victim:
		dest = victim.global_position + Vector3.UP * _h(victim) * 0.85
	elif to_v is Vector3:
		dest = (to_v as Vector3) + Vector3.UP * 1.3
	if from == null or dest == null:
		return
	var fx := _new_fx(&"mana_scald", from, _team_of(src))
	fx.src = src
	fx.tnode = victim
	fx.tlift = _h(victim) * 0.85 if victim else 0.0
	fx.a = from
	fx.b = dest
	fx.tpos = dest
	fx.dur = 0.9
	var lash := _piece(fx, &"beam", A_WORLD, Vector3.ZERO, 0.0, LASH_TIME + 0.12, 0.0, 0.14)
	if lash:
		lash.free_move = true
		_params(lash, {&"core": _hdr(STEAM, 2.2), &"body_color": Color(0.30, 0.52, 0.75, 0.38), &"width": 0.26,
				&"tail": 0.35, &"flow": 9.0, &"wobble": 0.8, &"seed": _rng.randf() * 10.0})
	fx.lash = lash
	# the palm flash (at the source), the cold flash + steam at the head (at the target, once the lash arrives)
	_flare(fx, A_POINT, Vector3.ZERO, _hdr(STEAM_BLUE, 1.8), 0.3, 0.55, 0.08, 0.0, 0.22, 0.0, 0.15, 0.6, 6.0)
	_flare(fx, A_TARGET, Vector3.ZERO, _hdr(STEAM_BLUE, 2.0), 0.5, 1.1, 0.12, 0.12, 0.5, 0.0, 0.3, 0.8, 8.0)
	_flare(fx, A_TARGET, Vector3.ZERO, _hdr(STEAM, 1.6), 0.25, 0.4, 0.06, 0.12, 0.3, 0.0, 0.14)
	_sched(fx, &"steam_burst", 0.12, A_TARGET, Vector3.UP * 0.1)
	_sched(fx, &"steam_sparks", 0.12, A_TARGET, Vector3.ZERO)
	_start(fx)
	if fx.shown:
		_gplay(&"mana_scald", dest, {"team": fx.team, "delay": 0.12})


func _stoke(at: Variant, target: Variant) -> void:
	var from: Variant = _point_of(at, 0.5)
	if from == null:
		return
	var kw := _node(target)
	var dest: Variant = null
	if kw:
		dest = _call_point(kw, &"get_kiln_point")
		if dest == null:
			dest = kw.global_position + Vector3.UP * _h(kw) * 0.6
	elif target is Vector3:
		dest = (target as Vector3) + Vector3.UP * 1.1
	else:
		dest = (from as Vector3) + Vector3(0, 0.6, -2.0)
	var fx := _new_fx(&"stoke", from, _team_of(kw))
	fx.tnode = kw
	fx.a = from
	fx.b = dest
	fx.tpos = dest
	fx.fly = STOKE_TIME
	fx.arc = 1.2
	fx.dur = STOKE_TIME + 0.4
	var ember := _flare(fx, A_WORLD, from, _hdr(MOLTEN, 2.4), 0.3, 0.26, 0.2, 0.0, STOKE_TIME + 0.02, 0.05, 0.05)
	if ember:
		ember.free_move = true
		_params(ember, {&"pulse": 1.0})
	fx.mover = ember
	_flare(fx, A_TARGET, Vector3.ZERO, _hdr(MOLTEN_HOT, 2.0), 0.3, 0.8, 0.1, STOKE_TIME, STOKE_TIME + 0.35, 0.0, 0.25, 0.6, 6.0)
	_sched(fx, &"stoke_puff", STOKE_TIME, A_TARGET, Vector3.ZERO)
	_sched(fx, &"stoke_puff", 0.0, A_POINT, Vector3.ZERO)
	_start(fx)
	if fx.shown:
		_gplay(&"stoke", dest, {"team": fx.team, "delay": STOKE_TIME})


## G-B: the Medium+ spell layer (art/vfx/spells_g/spell_fx_g.gd) adds its pieces; nothing at Low (SpellFxG.live = null).
func _gplay(id: StringName, pos: Vector3, opts: Dictionary = {}) -> void:
	var g := SpellFxG.live(self)
	if g:
		g.play(id, pos, opts)


# ---------------------------------------------------------------- effect runtime

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


## Advances one effect; true when it is over.
func _tick(fx: Fx, delta: float) -> bool:
	fx.t += delta
	if fx.follow:
		if is_instance_valid(fx.follow) and fx.follow.is_inside_tree() and _alive(fx.follow):
			fx.point = fx.follow.global_position
		else:
			fx.follow = null
			if fx.id == &"slagged" and fx.end_at < 0.0:
				fx.end_at = fx.t + END_FADE   # the unit died or left: the look goes with it
	if fx.tnode:
		if is_instance_valid(fx.tnode) and fx.tnode.is_inside_tree():
			fx.tpos = fx.tnode.global_position + Vector3.UP * fx.tlift if fx.id == &"mana_scald" else fx.tpos
			if fx.id == &"stoke":
				var kp: Variant = _call_point(fx.tnode, &"get_kiln_point")
				if kp != null:
					fx.tpos = kp
					fx.b = kp
			elif fx.id == &"mana_scald":
				fx.b = fx.tpos
		else:
			fx.tnode = null
	fx.check_left -= delta
	if fx.check_left <= 0.0:
		fx.check_left += CHECK_INTERVAL
		_refresh(fx)
	if fx.mover:
		_tick_mover(fx)
	if fx.lash:
		_tick_lash(fx)
	if fx.drips:
		fx.drips.global_position = fx.point
		var want := fx.shown and (fx.end_at < 0.0) and fx.t < fx.dur - 0.5
		if fx.drips.emitting != want:
			fx.drips.emitting = want
	var ef := 1.0 if fx.end_at < 0.0 else clampf((fx.end_at - fx.t) / END_FADE, 0.0, 1.0)
	for d in fx.pieces:
		if not d.free_move:
			_tick_piece(fx, d, ef)
		else:
			_fade_piece(fx, d, ef)
	if fx.bursts_left > 0:
		for bd in fx.bursts:
			if not bd["done"] and fx.t >= float(bd["on"]):
				bd["done"] = true
				fx.bursts_left -= 1
				if fx.shown and fx.end_at < 0.0:
					_burst(bd["look"], _anchor(fx, bd["at"]) + (bd["ofs"] as Vector3), bd["size"], bd["basis"])
	if fx.end_at >= 0.0:
		return fx.t >= fx.end_at
	return fx.t >= fx.dur and fx.bursts_left <= 0


## Moves a flight flare (slag glob / stoke ember) along lerp + sin arc; puffs a smoke trail behind the glob.
func _tick_mover(fx: Fx) -> void:
	var k := clampf(fx.t / maxf(fx.fly, 0.01), 0.0, 1.0)
	var p := fx.a.lerp(fx.b, k) + Vector3.UP * sin(k * PI) * fx.arc
	var s := fx.mover.s0.lerp(fx.mover.s1, k)
	var xf := Transform3D(Basis.from_scale(s), p)
	if not xf.is_equal_approx(fx.mover.n.transform):
		fx.mover.n.transform = xf
	if fx.id == &"slag_rain" and k < 1.0:
		fx.trail_left -= get_process_delta_time()
		if fx.trail_left <= 0.0 and fx.shown and fx.t > 0.02:
			fx.trail_left = 0.12
			_burst(&"glob_smoke", p, 1.0, Basis.IDENTITY)


## Stretches the steam lash between the (live) palm and the target head: the head races out in 0.12 s.
func _tick_lash(fx: Fx) -> void:
	var from := fx.a
	if fx.src and is_instance_valid(fx.src) and fx.src.is_inside_tree():
		var pp: Variant = _call_point(fx.src, &"get_palm_point")
		if pp != null:
			from = pp
	var reach := clampf(fx.t / 0.12, 0.0, 1.0)
	var to := from.lerp(fx.b, reach)
	var d := to - from
	var len := maxf(d.length(), 0.05)
	var y := d / len
	var x := y.cross(Vector3.UP)
	x = x.normalized() if x.length_squared() > 0.0001 else Vector3.RIGHT
	var z := x.cross(y).normalized()
	fx.lash.n.transform = Transform3D(Basis(x, y * len, z), from + d * 0.5)


func _fade_piece(fx: Fx, d: Piece, ef: float) -> void:
	var off := d.off if d.off > 0.0 else fx.dur + d.off
	var lt := fx.t - d.on
	if lt < 0.0 or fx.t >= off:
		if d.n.visible:
			d.n.visible = false
		return
	var f := ef
	if d.fin > 0.0:
		f = minf(f, lt / d.fin)
	if d.fout > 0.0:
		f = minf(f, (off - fx.t) / d.fout)
	f = clampf(f, 0.0, 1.0)
	if absf(f - d.lf) > 0.003:
		d.lf = f
		d.n.set_instance_shader_parameter(&"fade", f)
	var vis := fx.shown and f > 0.002
	if d.n.visible != vis:
		d.n.visible = vis


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
	if lt <= d.age_until and (d.is_disc or d.pool == &"flare"):
		n.set_instance_shader_parameter(&"age", lt)
	if d.is_disc and absf(s.x - d.lr) > 0.001:
		d.lr = s.x
		n.set_instance_shader_parameter(&"radius", s.x)
	if d.ramp_param != &"":
		var c := snappedf(clampf(lt / maxf(d.ramp_time, 0.01), 0.0, 1.0), 0.01)
		if c != d.lc:
			d.lc = c
			n.set_instance_shader_parameter(d.ramp_param, d.c0.lerp(d.c1, c))
	var vis := fx.shown and f > 0.002
	if n.visible != vis:
		n.visible = vis


func _finish(fx: Fx) -> void:
	for d in fx.pieces:
		d.n.visible = false
		d.n.set_instance_shader_parameter(&"fade", 0.0)
		(_free[d.pool] as Array).append(d.n)
	fx.pieces.clear()
	fx.mover = null
	fx.lash = null
	if fx.drips:
		fx.drips.emitting = false
		fx.drips.visible = false
		_drips_free.append(fx.drips)
		fx.drips = null
	if fx.id == &"slagged" and fx.unit_key != 0:
		if _slagged.get(fx.unit_key) == fx:
			_slagged.erase(fx.unit_key)
		var u: Variant = instance_from_id(fx.unit_key)
		if u is Node3D and is_instance_valid(u):
			var m := _model_of(u as Node3D)
			if m and m.has_method(&"set_status"):
				m.call(&"set_status", &"slagged", false)


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


func _piece(fx: Fx, pool: StringName, at: int, ofs: Vector3, on: float, off: float, fin: float, fout: float) -> Piece:
	var free: Array = _free[pool]
	if free.is_empty():
		return null   # pool exhausted: the piece is skipped (every helper accepts null)
	var d := Piece.new()
	d.n = free.pop_back()
	d.pool = pool
	d.is_disc = DISC_POOLS.has(pool)
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


func _ramp(d: Piece, param: StringName, c0: Color, c1: Color, time: float) -> void:
	if d == null:
		return
	d.ramp_param = param
	d.c0 = c0
	d.c1 = c1
	d.ramp_time = time
	d.lc = -1.0


func _disc(fx: Fx, at: int, pattern: int, tint: Color, r0: float, r1: float, grow: float, on: float, off: float,
		fin: float, fout: float, pool: StringName = &"disc") -> Piece:
	_layer = (_layer + 1) % 8
	var d := _piece(fx, pool, at, Vector3.UP * (0.05 + 0.006 * float(_layer)), on, off, fin, fout)
	_grow(d, Vector3(r0, 1.0, r0), Vector3(r1, 1.0, r1), grow)
	_params(d, {&"pattern": float(pattern), &"tint": tint, &"seed": _rng.randf() * 10.0})
	return d


func _ring(fx: Fx, at: int, tint: Color, r0: float, r1: float, grow: float, on: float, off: float, fin: float,
		fout: float, width: float = 0.1, glow: float = 0.25, pool: StringName = &"ring") -> Piece:
	_layer = (_layer + 1) % 8
	var d := _piece(fx, pool, at, Vector3.UP * (0.06 + 0.006 * float(_layer)), on, off, fin, fout)
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


func _sched(fx: Fx, look: StringName, on: float, at: int, ofs: Vector3, size: float = 1.0, basis: Basis = Basis.IDENTITY) -> void:
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
	p.transform = Transform3D(basis * Basis.from_scale(Vector3.ONE * clampf(size, 0.3, 2.5)), pos)
	p.visible = true
	p.restart()
	for bd in _live_bursts:
		if bd["p"] == p:
			bd["left"] = p.lifetime + 0.1
			return
	_live_bursts.append({"p": p, "left": p.lifetime + 0.1})


static func _ease(k: float) -> float:
	return 1.0 - pow(1.0 - k, 3.0)


## sRGB colour -> linear HDR (instance uniforms and particle colours are linear).
static func _hdr(c: Color, energy: float, alpha: float = 1.0) -> Color:
	var l := c.srgb_to_linear()
	return Color(l.r * energy, l.g * energy, l.b * energy, alpha)


# ---------------------------------------------------------------- argument helpers

func _node(v: Variant) -> Node3D:
	if typeof(v) == TYPE_OBJECT and is_instance_valid(v) and v is Node3D and (v as Node3D).is_inside_tree():
		return v as Node3D
	return null


## The model of a unit (Unit.get_model()), else the node itself.
func _model_of(n: Node3D) -> Node3D:
	if n == null:
		return null
	if n.has_method(&"get_model"):
		var m: Variant = n.call(&"get_model")
		if m is Node3D and is_instance_valid(m):
			return m
	return n


## A world point from a model hook (`method`) on the node or its model, else null.
func _call_point(n: Node3D, method: StringName) -> Variant:
	for o: Node3D in [n, _model_of(n)]:
		if o and is_instance_valid(o) and o.has_method(method):
			var v: Variant = o.call(method)
			if v is Vector3:
				return v
	return null


func _point_of(v: Variant, chest: float) -> Variant:
	if v is Vector3:
		return v
	var n := _node(v)
	if n == null:
		return null
	return n.global_position + Vector3.UP * _h(n) * chest


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


func _radius(n: Node3D) -> float:
	var r: Variant = n.get(&"radius")
	return clampf(float(r), 0.2, 2.5) if r != null else 0.45


func _h(n: Variant) -> float:
	if not is_instance_valid(n):
		return 1.6
	var h: Variant = (n as Object).get(&"body_height")
	return clampf(float(h), 0.5, 6.0) if h != null else 1.6


# ---------------------------------------------------------------- shared resources (built once)

func _build_shared() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(2.0, 2.0)
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	var ground_mat := _shader_mat(GROUND_SHADER)
	var ring_mat := _shader_mat(RING_SHADER)
	var meshes := {&"disc": plane, &"ring": plane, &"warn": plane, &"flare": quad, &"beam": quad, &"crust": plane,
			&"crust_ring": plane}
	var mats := {&"disc": ground_mat, &"ring": ring_mat, &"warn": ring_mat, &"flare": _shader_mat(FLARE_SHADER),
			&"beam": _shader_mat(BEAM_SHADER), &"crust": ground_mat, &"crust_ring": ring_mat}
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
			if pool == &"flare" or pool == &"beam":
				m.extra_cull_margin = 6.0   # billboards / axial quads leave their mesh AABB
			add_child(m)
			arr.append(m)
		_all[pool] = arr
		_free[pool] = arr.duplicate()
	_passes[&"add_dot"] = _particle_quad(CharacterModel.mote_texture(), BaseMaterial3D.BLEND_MODE_ADD)
	_passes[&"mix_smoke"] = _particle_quad(_smoke_tex(), BaseMaterial3D.BLEND_MODE_MIX)
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
	for i in DRIP_POOL:
		var dp := _emitter(&"slag_drips", 6, 1.3, &"add_dot", 2.0)
		dp.one_shot = false
		dp.explosiveness = 0.0
		add_child(dp)
		_drips_free.append(dp)


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


## 64 x 64 soft smoke puff mask (alpha = shape, grey = shading), tinted by the particle colour. Built once.
func _smoke_tex() -> ImageTexture:
	var n := 64
	var img := Image.create_empty(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var u := (float(x) + 0.5) / float(n) * 2.0 - 1.0
			var v := (float(y) + 0.5) / float(n) * 2.0 - 1.0
			var r := sqrt(u * u + v * v)
			var nse := _vn(u * 2.3 + 7.1, v * 2.3 + 3.3) * 0.6 + _vn(u * 5.1 + 1.7, v * 5.1 - 2.2) * 0.4
			var a := clampf((1.0 - r) * 1.6 + (nse - 0.5) * 0.9 - 0.2, 0.0, 1.0)
			a = a * a * (3.0 - 2.0 * a) * clampf((1.0 - r) / 0.2, 0.0, 1.0)
			var shade := clampf(0.82 + 0.14 * (0.5 - v * 0.5) + (nse - 0.5) * 0.25, 0.0, 1.0)
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
	var hot := _hdr(MOLTEN_HOT, 2.6)
	var molten := _hdr(MOLTEN, 2.0)
	var slag := _hdr(SLAG, 1.2)
	var cold := _hdr(CRUST, 1.0, 0.0)
	match key:
		&"glob_smoke":
			# a smoke puff left behind the flying glob, rising slowly
			_sphere(m, 0.12)
			m.direction = Vector3.UP
			m.spread = 60.0
			m.initial_velocity_min = 0.2
			m.initial_velocity_max = 0.6
			m.gravity = Vector3(0, 0.6, 0)
			_spin(m, 60.0)
			_size(m, 0.35, 0.55, &"grow")
			m.color_initial_ramp = _ramp_tex(_lin([Color(0.30, 0.27, 0.25), Color(0.38, 0.34, 0.31)]))
			m.color_ramp = _ramp_at([0.0, 0.2, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.0)])
		&"slag_splash":
			# molten droplets thrown up and out from the impact, falling back and cooling to dark crust
			_sphere(m, 0.4)
			m.direction = Vector3.UP
			m.spread = 70.0
			m.initial_velocity_min = 2.5
			m.initial_velocity_max = 5.5
			m.gravity = Vector3(0, -12.0, 0)
			m.damping_min = 0.3
			m.damping_max = 0.8
			_size(m, 0.12, 0.2, &"shrink")
			m.color_ramp = _ramp_tex([hot, molten, slag, cold])
		&"slag_smoke":
			# a dark oily smoke cloud rolling off the splash
			_ring_shape(m, 1.2, 0.2)
			m.direction = Vector3.UP
			m.spread = 25.0
			m.initial_velocity_min = 0.6
			m.initial_velocity_max = 1.4
			m.gravity = Vector3(0, 0.5, 0)
			m.damping_min = 0.6
			m.damping_max = 1.2
			_spin(m, 40.0)
			_size(m, 0.8, 1.3, &"grow")
			m.color_initial_ramp = _ramp_tex(_lin([Color(0.20, 0.16, 0.14), Color(0.30, 0.24, 0.20)]))
			m.color_ramp = _ramp_at([0.0, 0.15, 0.6, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.6), Color(1, 1, 1, 0.3),
					Color(1, 1, 1, 0.0)])
		&"steam_burst":
			# white-blue steam boiling off the target's head
			_sphere(m, 0.18)
			m.direction = Vector3.UP
			m.spread = 55.0
			m.initial_velocity_min = 0.8
			m.initial_velocity_max = 1.8
			m.gravity = Vector3(0, 0.9, 0)
			m.damping_min = 1.0
			m.damping_max = 2.0
			_spin(m, 90.0)
			_size(m, 0.35, 0.6, &"grow")
			m.color_initial_ramp = _ramp_tex(_lin([STEAM, Color(0.72, 0.84, 0.95)]))
			m.color_ramp = _ramp_at([0.0, 0.12, 0.55, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.75), Color(1, 1, 1, 0.35),
					Color(1, 1, 1, 0.0)])
		&"steam_sparks":
			_sphere(m, 0.1)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 1.5
			m.initial_velocity_max = 3.0
			m.damping_min = 3.0
			m.damping_max = 5.0
			_size(m, 0.06, 0.1, &"shrink")
			m.color_ramp = _ramp_tex([_hdr(STEAM, 2.4), _hdr(STEAM_BLUE, 1.8), _hdr(STEAM_BLUE, 0.6, 0.0)])
		&"stoke_puff":
			_sphere(m, 0.08)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 0.8
			m.initial_velocity_max = 1.8
			m.damping_min = 2.0
			m.damping_max = 3.0
			m.gravity = Vector3(0, 0.5, 0)
			_size(m, 0.08, 0.13, &"shrink")
			m.color_ramp = _ramp_tex([hot, molten, _hdr(SLAG, 0.8, 0.0)])
		&"slag_drips":
			# slow molten drips sliding off the legs (a ring round the body, 0.3-0.9 m up), falling, cooling
			_ring_shape(m, 0.32, 0.6)
			m.emission_ring_inner_radius = 0.2
			m.direction = Vector3.DOWN
			m.spread = 8.0
			m.initial_velocity_min = 0.1
			m.initial_velocity_max = 0.3
			m.gravity = Vector3(0, -1.6, 0)
			_size(m, 0.07, 0.1, &"hold")
			m.color_ramp = _ramp_tex([hot, molten, slag, _hdr(SLAG, 0.4, 0.0)])
	_pmats[key] = m
	return m


func _spin(m: ParticleProcessMaterial, deg_per_s: float) -> void:
	m.angle_min = -180.0
	m.angle_max = 180.0
	m.angular_velocity_min = -deg_per_s
	m.angular_velocity_max = deg_per_s


func _ring_shape(m: ParticleProcessMaterial, r: float, h: float) -> void:
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	m.emission_ring_axis = Vector3.UP
	m.emission_ring_radius = r
	m.emission_ring_inner_radius = r * 0.85
	m.emission_ring_height = h


func _sphere(m: ParticleProcessMaterial, r: float) -> void:
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = r


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


func _ramp_tex(colors: Array) -> GradientTexture1D:
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
