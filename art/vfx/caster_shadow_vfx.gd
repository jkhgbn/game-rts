class_name CasterShadowVfx
extends Node3D
## Shadow caster effects (caster-units.md 5.4 / 10.5, task CU.V6 Shadow half): the Gloom Deacon's Blood Tithe tether,
## Umbral Passage rifts and the Vigil wisp. An effect FAMILY of UnitVfx (art/vfx/unit_vfx.gd loads this file from its
## MODULES list and forwards the ids below); callers never reach it directly:
##   var vfx := get_tree().get_first_node_in_group(&"unit_vfx")
##   if vfx: vfx.play(&"blood_tithe", deacon, {"to": ally, "drain": enemy})
## It can also live on its own (tests, the Art Lab `kind=vfx`, docs/art/ingame_grade/caster_lineup.gd). Draw-only.
##
## Ids and their arguments (`target` may always be null):
##   blood_tithe     at = the Deacon (Unit or model: the tether leaves the model's get_tether_origin(), the taper flame)
##                   or a Vector3; target = the ally (Node3D / Vector3) or {to: ally, drain: enemy or null, duration: s}.
##                   A violet-red tether (a 0.14 m beam + a bead thread pulsing toward the ally) from the flame to the
##                   ally's chest, a heal shimmer on the ally (rising motes, a soft pulsing ring at its feet) and, when an
##                   enemy is drained, a thinner dark-red thread from its chest to the ally with a dark flare on it.
##                   One tether per (Deacon, ally): playing it again (every channel tick) refreshes it and swaps the
##                   drained enemy; it lasts `duration` (default 1.0 s) after the last call, then fades in 0.25 s.
##                   Ends early with `blood_tithe_end` (at = the Deacon, target = the ally or null = all its tethers;
##                   not in EFFECTS: it draws nothing) or when either end dies.
##   umbral_passage  at = the rift point (Vector3); target = the Deacon (Node3D: the second rift opens at her and follows
##                   her) or a Vector3, or {deacon, duration (2.5)}. Two vertical violet oval rifts (2.5 m), swirling,
##                   each over a dark ground ring, open in 0.3 s, turn toward the camera, flare and close at the end.
##   passage_step    at = a unit that stepped through (Node3D / Vector3): a violet silhouette flash and a ring of motes
##                   at its feet (gameplay plays it on every carried soldier, at the out-rift and at the in-rift).
##   vigil           at = the ally that died (Node3D / Vector3); target = the Deacon (the wisp flies to the model's
##                   get_reliquary_point() and calls its play_vigil() on arrival) or a Vector3. 0.6 s.
## Fog: effects of the local team always show; others only where the local team sees (checked 4 times per second).
## Budget: every piece and emitter is pre-built and pooled (no node, material or mesh after _ready), 0 lights, no
## shadows, particles not started beyond 45 m. Shaders reused read-only: vfx_beam (tether), champion_rope (bead
## threads), champion_flare (flares, wisp), vfx_ring (rings), vfx_siphon (the rifts, on vertical planes),
## champion_ground (the rift floor).

const GROUP := &"caster_shadow_vfx"
const EFFECTS: Array[StringName] = [&"blood_tithe", &"umbral_passage", &"passage_step", &"vigil"]
const CONTROL: Array[StringName] = [&"blood_tithe_end"]

# Palette: the Deacon's bolt (0.75, 0.30, 0.55), Shadow glow (0.72, 0.34, 1.0), a blood violet-red for the tithe.
const VIOLET := Color(0.72, 0.34, 1.0)
const BLOOD := Color(0.92, 0.20, 0.58)
const BLOOD_DARK := Color(0.55, 0.05, 0.16)
const TITHE := Color(0.84, 0.26, 0.92)
const PALE := Color(0.95, 0.85, 1.0)
const DUSK := Color(0.06, 0.01, 0.10)

const TITHE_DEFAULT := 1.0
const PASSAGE_TIME := 2.5
const RIFT_H := 2.5
const RIFT_W := 1.4
const VIGIL_TIME := 0.6
const PARTICLE_RANGE := 45.0
const CHECK_INTERVAL := 0.25
const FOG_RESCAN := 1.0
const END_FADE := 0.25
const BURSTS_PER_FRAME := 24

enum { A_POINT, A_TARGET, A_WORLD }
enum { G_SOOT = 5 }   # champion_ground.gdshader pattern used here

const POOL_SIZES := {&"disc": 8, &"ring": 18, &"flare": 28, &"beam": 6, &"rope": 12, &"rift": 6}
const BURSTS := {
	&"tithe_heal": [7, 0.9, &"add_dot", 12, 0.7, 2.0],
	&"tithe_spark": [10, 0.4, &"add_dot", 6, 1.0, 2.0],
	&"rift_swirl": [16, 1.1, &"add_dot", 8, 0.4, 3.0],
	&"rift_smoke": [10, 1.6, &"mix_smoke", 6, 0.8, 3.0],
	&"step_motes": [12, 0.8, &"add_dot", 12, 0.9, 2.0],
	&"vigil_trail": [4, 0.5, &"add_dot", 12, 0.6, 2.0],
}
const OPTIONAL_BURSTS: Array[StringName] = [&"tithe_heal", &"vigil_trail", &"rift_swirl"]

const GROUND_SHADER := preload("res://art/vfx/champion_ground.gdshader")
const RING_SHADER := preload("res://art/vfx/vfx_ring.gdshader")
const FLARE_SHADER := preload("res://art/vfx/champion_flare.gdshader")
const BEAM_SHADER := preload("res://art/vfx/vfx_beam.gdshader")
const ROPE_SHADER := preload("res://art/vfx/champion_rope.gdshader")
const RIFT_SHADER := preload("res://art/vfx/vfx_siphon.gdshader")


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
	var follow: Node3D = null
	var tnode: Node3D = null
	var tlift := 0.0
	var pieces: Array[Piece] = []
	var bursts: Array[Dictionary] = []
	var bursts_left := 0
	# tether (blood_tithe)
	var src: Node3D = null           # the Deacon (unit or model)
	var src_pos := Vector3.ZERO
	var drain: Node3D = null
	var beam: Piece = null
	var thread: Piece = null
	var dthread: Piece = null
	var dflare: Piece = null
	var heal_left := 0.0
	var key := ""
	# rifts (umbral_passage)
	var rifts: Array[Piece] = []
	# wisp (vigil)
	var mover: Piece = null
	var a := Vector3.ZERO
	var b := Vector3.ZERO
	var fly := 0.6
	var arc := 1.0
	var landed := false
	var trail_left := 0.0


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
	var free_move := false
	var hidden := false               # kept hidden by the effect (the drain thread while nothing is drained)
	var last: Dictionary = {}         # instance uniform -> the last value sent (_set_p skips unchanged values)


var _fx: Array[Fx] = []
var _free: Dictionary = {}
var _all: Dictionary = {}
var _bursts: Dictionary = {}
var _burst_next: Dictionary = {}
var _live_bursts: Array[Dictionary] = []
var _bursts_this_frame := 0
var _tethers: Dictionary = {}       # "deacon_id:ally_id" -> Fx
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
	_rng.seed = 5104
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


func play(id: StringName, at: Variant, target: Variant = null) -> bool:
	if not handles(id):
		return false
	if not is_node_ready() or not is_inside_tree():
		return true
	match id:
		&"blood_tithe": _blood_tithe(at, target)
		&"blood_tithe_end": _tithe_end(at, target)
		&"umbral_passage": _umbral_passage(at, target)
		&"passage_step": _passage_step(at)
		&"vigil": _vigil(at, target)
	return true


func active_count() -> int:
	return _fx.size()


func active_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for fx in _fx:
		out.append(fx.id)
	return out


func live_count() -> int:
	var n := _live_bursts.size()
	for pool: StringName in _all:
		for g: GeometryInstance3D in _all[pool]:
			if g.visible:
				n += 1
	return n


## Live Blood Tithe tethers (tests).
func tether_count() -> int:
	return _tethers.size()


# ---------------------------------------------------------------- the effects

func _blood_tithe(at: Variant, target: Variant) -> void:
	var to_v: Variant = target
	var drain_v: Variant = null
	var dur := TITHE_DEFAULT
	if target is Dictionary:
		var d: Dictionary = target
		to_v = d.get("to")
		drain_v = d.get("drain")
		dur = float(d.get("duration", dur))
	dur = clampf(dur, 0.2, 30.0)
	var deacon := _node(at)
	var ally := _node(to_v)
	var key := ""
	if deacon and ally:
		key = "%d:%d" % [deacon.get_instance_id(), ally.get_instance_id()]
		if _tethers.has(key):
			var old: Fx = _tethers[key]
			if old.end_at < 0.0:
				old.dur = old.t + dur
				old.drain = _node(drain_v)
				return
	var origin: Variant = _origin_of(deacon, at)
	var dest: Variant = null
	if ally:
		dest = ally.global_position + Vector3.UP * _h(ally) * 0.55
	elif to_v is Vector3:
		dest = (to_v as Vector3) + Vector3.UP * 0.9
	if origin == null or dest == null:
		return
	var fx := _new_fx(&"blood_tithe", origin, _team_of(deacon))
	fx.src = deacon
	fx.src_pos = origin
	fx.tnode = ally
	fx.tlift = _h(ally) * 0.55 if ally else 0.0
	fx.tpos = dest
	fx.drain = _node(drain_v)
	fx.dur = dur
	fx.key = key
	# the tether: a beam (dark crimson body, violet-red core flowing toward the ally) + a bead thread over it
	fx.beam = _piece(fx, &"beam", A_WORLD, Vector3.ZERO, 0.0, 1.0e6, 0.12, END_FADE)
	if fx.beam:
		fx.beam.free_move = true
		_params(fx.beam, {&"core": _hdr(TITHE, 1.9), &"body_color": Color(0.28, 0.02, 0.10, 0.55), &"width": 0.16,
				&"tail": 0.15, &"flow": 5.0, &"wobble": 0.45, &"seed": _rng.randf() * 10.0})
	fx.thread = _piece(fx, &"rope", A_WORLD, Vector3.ZERO, 0.0, 1.0e6, 0.12, END_FADE)
	if fx.thread:
		fx.thread.free_move = true
		_params(fx.thread, {&"tint": _hdr(BLOOD, 1.5), &"style": 1.0, &"wave": 0.0, &"width_m": 0.34})
	# the drained enemy: a thinner dark-red thread to the ally and a dark flare on the victim (shown while draining)
	fx.dthread = _piece(fx, &"rope", A_WORLD, Vector3.ZERO, 0.0, 1.0e6, 0.12, END_FADE)
	if fx.dthread:
		fx.dthread.free_move = true
		_params(fx.dthread, {&"tint": _hdr(BLOOD_DARK, 1.6), &"style": 1.0, &"wave": 0.0, &"width_m": 0.22})
	fx.dflare = _flare(fx, A_WORLD, Vector3.ZERO, _hdr(BLOOD, 1.2), 0.5, 0.5, 0.0, 0.0, 1.0e6, 0.12, END_FADE, 0.3, 4.0)
	if fx.dflare:
		fx.dflare.free_move = true
		_params(fx.dflare, {&"pulse": 1.0, &"halo": Color(0.10, 0.0, 0.04, 0.5)})
	# the heal shimmer: a pulsing ring at the ally's feet + the flame flares as the tether takes hold
	var ring := _ring(fx, A_TARGET, _hdr(TITHE, 1.3), 0.5, 0.8, 0.4, 0.0, 1.0e6, 0.2, END_FADE, 0.16, 0.5)
	if ring:
		ring.ofs = Vector3(0, -fx.tlift + 0.06, 0)
		ring.o0 = ring.ofs
		_params(ring, {&"fill": Color(0.12, 0.0, 0.06, 0.18)})
	_flare(fx, A_POINT, Vector3.ZERO, _hdr(TITHE, 2.0), 0.3, 0.7, 0.1, 0.0, 0.35, 0.0, 0.25, 0.6, 6.0)
	_sched(fx, &"tithe_spark", 0.0, A_POINT, Vector3.ZERO)
	if key != "":
		_tethers[key] = fx
	_start(fx)
	if fx.shown:
		_gplay(&"blood_tithe", (dest as Vector3) - Vector3.UP * 0.9, {"team": fx.team})


func _tithe_end(at: Variant, target: Variant) -> void:
	var deacon := _node(at)
	if deacon == null:
		return
	var ally := _node(target)
	var prefix := "%d:" % deacon.get_instance_id()
	for k: String in _tethers.keys():
		if not k.begins_with(prefix):
			continue
		if ally and k != prefix + str(ally.get_instance_id()):
			continue
		var fx: Fx = _tethers[k]
		if fx.end_at < 0.0:
			fx.end_at = fx.t + END_FADE


func _umbral_passage(at: Variant, target: Variant) -> void:
	var p: Variant = _point_of(at, 0.0)
	if p == null:
		return
	var deacon_v: Variant = target
	var dur := PASSAGE_TIME
	if target is Dictionary:
		deacon_v = (target as Dictionary).get("deacon")
		dur = float((target as Dictionary).get("duration", dur))
	dur = clampf(dur, 0.5, 10.0)
	var deacon := _node(deacon_v)
	var home: Variant = null
	if deacon:
		home = deacon.global_position
	elif deacon_v is Vector3:
		home = deacon_v
	var fx := _new_fx(&"umbral_passage", p, _team_of(deacon))
	fx.dur = dur + 0.1
	fx.tnode = deacon
	fx.tpos = home if home != null else p
	var ends: Array[int] = [A_POINT]
	if home != null:
		ends.append(A_TARGET)
	for at_i: int in ends:
		# the ground under the rift: a dark ring with a violet band, and a darkened floor
		var floor_d := _disc(fx, at_i, G_SOOT, DUSK, 0.6, 1.5, 0.3, 0.0, dur, 0.2, 0.3)
		if floor_d:
			floor_d.age_until = 0.0
		var ring := _ring(fx, at_i, _hdr(VIOLET, 1.4), 0.5, 1.45, 0.3, 0.0, dur, 0.1, 0.3, 0.12, 0.45)
		_params(ring, {&"fill": Color(0.05, 0.0, 0.08, 0.35)})
		# the rift itself: a vertical oval vortex facing the camera, opening in 0.3 s and pinching shut at the end
		var rift := _piece(fx, &"rift", at_i, Vector3.UP * (RIFT_H * 0.5 + 0.05), 0.0, dur, 0.15, 0.25)
		if rift:
			rift.free_move = true
			rift.ofs = Vector3.UP * (RIFT_H * 0.5 + 0.05)
			fx.rifts.append(rift)
		# flash at the opening and at the crossing
		_flare(fx, at_i, Vector3.UP * 1.3, _hdr(VIOLET, 1.8), 0.8, 2.2, 0.25, 0.0, 0.45, 0.0, 0.3, 0.6, 6.0)
		_flare(fx, at_i, Vector3.UP * 1.2, _hdr(PALE, 1.5), 1.0, 2.6, 0.2, dur - 0.3, dur, 0.05, 0.2, 0.9, 8.0)
		var t := 0.1
		while t < dur - 0.3:
			_sched(fx, &"rift_swirl", t, at_i, Vector3.UP * 0.2)
			t += 0.55
		_sched(fx, &"rift_smoke", 0.05, at_i, Vector3.UP * 0.2)
		_sched(fx, &"step_motes", dur - 0.25, at_i, Vector3.UP * 0.1, 1.5)
	_start(fx)
	if fx.shown:
		_gplay(&"umbral_passage", p, {"team": fx.team})
		if home != null:
			_gplay(&"umbral_passage", home, {"team": fx.team, "delay": 0.1})


func _passage_step(at: Variant) -> void:
	var unit := _node(at)
	var p: Variant = _point_of(at, 0.0)
	if p == null:
		return
	var h := _h(unit) if unit else 1.6
	var fx := _new_fx(&"passage_step", p, _team_of(unit))
	fx.follow = unit
	fx.dur = 0.7
	_flare(fx, A_POINT, Vector3.UP * h * 0.55, _hdr(VIOLET, 1.8), h * 0.7, h * 1.1, 0.2, 0.0, 0.55, 0.0, 0.4, 0.5, 6.0)
	_flare(fx, A_POINT, Vector3.UP * h * 0.55, _hdr(PALE, 1.3), h * 0.3, h * 0.5, 0.15, 0.0, 0.3, 0.0, 0.2)
	var ring := _ring(fx, A_POINT, _hdr(VIOLET, 1.5), 0.3, 1.1, 0.4, 0.0, 0.6, 0.0, 0.35, 0.14, 0.4)
	_params(ring, {&"fill": Color(0.05, 0.0, 0.08, 0.3)})
	_sched(fx, &"step_motes", 0.0, A_POINT, Vector3.UP * 0.1)
	_start(fx)
	if fx.shown:
		_gplay(&"passage_step", p, {"team": fx.team})


func _vigil(at: Variant, target: Variant) -> void:
	var from: Variant = _point_of(at, 0.5)
	if from == null:
		return
	var deacon := _node(target)
	var dest: Variant = null
	if deacon:
		dest = _call_point(deacon, &"get_reliquary_point")
		if dest == null:
			dest = deacon.global_position + Vector3.UP * _h(deacon) * 0.95
	elif target is Vector3:
		dest = (target as Vector3) + Vector3.UP * 1.9
	else:
		dest = (from as Vector3) + Vector3(2.0, 1.2, 0.0)
	var fx := _new_fx(&"vigil", from, _team_of(deacon))
	fx.tnode = deacon
	fx.a = from
	fx.b = dest
	fx.tpos = dest
	fx.fly = VIGIL_TIME
	fx.arc = 1.4
	fx.dur = VIGIL_TIME + 0.4
	var wisp := _flare(fx, A_WORLD, from, _hdr(VIOLET, 2.8), 0.6, 0.45, 0.3, 0.0, VIGIL_TIME + 0.02, 0.08, 0.06, 0.5, 4.0)
	if wisp:
		wisp.free_move = true
		_params(wisp, {&"pulse": 1.0})
	fx.mover = wisp
	_flare(fx, A_POINT, Vector3.ZERO, _hdr(PALE, 1.6), 0.5, 1.0, 0.1, 0.0, 0.35, 0.0, 0.25, 0.5, 4.0)
	_flare(fx, A_TARGET, Vector3.ZERO, _hdr(VIOLET, 2.4), 0.5, 1.4, 0.12, VIGIL_TIME, VIGIL_TIME + 0.4, 0.0, 0.3, 0.8, 6.0)
	_start(fx)
	if fx.shown:
		_gplay(&"vigil", (dest as Vector3) - Vector3.UP * 0.8, {"team": fx.team, "delay": VIGIL_TIME})


## G-B: the Medium+ spell layer (art/vfx/spells_g/spell_fx_g.gd) adds its pieces; nothing at Low (SpellFxG.live = null).
func _gplay(id: StringName, pos: Vector3, opts: Dictionary = {}) -> void:
	var g := SpellFxG.live(self)
	if g:
		g.play(id, pos, opts)


# ---------------------------------------------------------------- effect runtime (specific)

func _tick(fx: Fx, delta: float) -> bool:
	fx.t += delta
	if fx.follow:
		if is_instance_valid(fx.follow) and fx.follow.is_inside_tree():
			fx.point = fx.follow.global_position
		else:
			fx.follow = null
	if fx.tnode:
		if is_instance_valid(fx.tnode) and fx.tnode.is_inside_tree() and (fx.id != &"blood_tithe" or _alive(fx.tnode)):
			if fx.id == &"vigil":
				var rp: Variant = _call_point(fx.tnode, &"get_reliquary_point")
				if rp != null:
					fx.b = rp
					fx.tpos = rp
			else:
				fx.tpos = fx.tnode.global_position + Vector3.UP * fx.tlift
		else:
			fx.tnode = null
			if fx.id == &"blood_tithe" and fx.end_at < 0.0:
				fx.end_at = fx.t + END_FADE   # the ally died or left
	fx.check_left -= delta
	if fx.check_left <= 0.0:
		fx.check_left += CHECK_INTERVAL
		_refresh(fx)
	if fx.id == &"blood_tithe":
		_tick_tether(fx, delta)
	elif fx.id == &"umbral_passage":
		_tick_rifts(fx)
	elif fx.mover:
		_tick_mover(fx)
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
	if fx.id == &"blood_tithe" and fx.t >= fx.dur:
		fx.end_at = fx.t + END_FADE
		return false
	return fx.t >= fx.dur and fx.bursts_left <= 0


## The tether follows the live flame and the ally's chest; the drain thread / flare follow the drained enemy.
func _tick_tether(fx: Fx, delta: float) -> void:
	if fx.src:
		if is_instance_valid(fx.src) and fx.src.is_inside_tree() and _alive(fx.src):
			var o: Variant = _origin_of(fx.src, null)
			if o != null:
				fx.src_pos = o
		else:
			fx.src = null
			if fx.end_at < 0.0:
				fx.end_at = fx.t + END_FADE   # the Deacon died
	fx.point = fx.src_pos
	var reach := _ease(clampf(fx.t / 0.15, 0.0, 1.0))
	var tip := fx.src_pos.lerp(fx.tpos, reach)
	var pulse := 0.5 + 0.5 * sin(fx.t * 7.0)
	if fx.beam:
		_axial(fx.beam.n, tip, tip - fx.src_pos, fx.src_pos.distance_to(tip), 1.0)
		_set_p(fx.beam, &"core", _hdr(TITHE, snappedf(1.5 + 0.8 * pulse, 0.1)))
	if fx.thread:
		var l := fx.src_pos.distance_to(tip)
		_axial(fx.thread.n, tip, tip - fx.src_pos, l, 0.34)
		_set_p(fx.thread, &"length_m", snappedf(l, 0.01))
	var draining := fx.drain != null and is_instance_valid(fx.drain) and fx.drain.is_inside_tree() and _alive(fx.drain)
	if not draining:
		fx.drain = null
	if fx.dthread:
		if draining:
			var dp := fx.drain.global_position + Vector3.UP * _h(fx.drain) * 0.55
			var dtip := dp.lerp(fx.tpos, reach)
			var dl := dp.distance_to(dtip)
			_axial(fx.dthread.n, dtip, dtip - dp, dl, 0.22)
			_set_p(fx.dthread, &"length_m", snappedf(dl, 0.01))
			if fx.dflare:
				fx.dflare.n.transform = Transform3D(Basis.from_scale(Vector3.ONE * (0.45 + 0.15 * pulse)), dp)
	# the drain thread and flare stay hidden while nothing is drained
	for p: Piece in [fx.dthread, fx.dflare]:
		if p:
			p.hidden = not draining
	fx.heal_left -= delta
	if fx.heal_left <= 0.0 and fx.shown and fx.end_at < 0.0:
		fx.heal_left = 0.45
		_burst(&"tithe_heal", fx.tpos - Vector3.UP * fx.tlift * 0.6, 1.0, Basis.IDENTITY)


## The rifts: vertical ovals turned toward the camera (yaw only), opening in 0.3 s, pinching shut in the last 0.25 s.
func _tick_rifts(fx: Fx) -> void:
	var open := _ease(clampf(fx.t / 0.3, 0.0, 1.0)) * (1.0 - smoothstep(fx.dur - 0.35, fx.dur - 0.05, fx.t))
	var pulse := 0.5 + 0.5 * sin(fx.t * 6.0)
	for d: Piece in fx.rifts:
		var base := _anchor(fx, d.at)
		var to_cam := Vector3.BACK
		if _cam and is_instance_valid(_cam):
			to_cam = _cam.global_position - base
			to_cam.y = 0.0
			to_cam = to_cam.normalized() if to_cam.length_squared() > 0.01 else Vector3.BACK
		# PlaneMesh lies in XZ (normal +Y): its normal -> toward the camera, its Z -> up.
		var nrm := to_cam
		var up := Vector3.UP
		var side := up.cross(nrm).normalized()
		var bs := Basis(side * (RIFT_W * 0.5) * (0.35 + 0.65 * open), nrm, up * (RIFT_H * 0.5) * maxf(open, 0.02))
		d.n.transform = Transform3D(bs, base + Vector3.UP * (0.05 + RIFT_H * 0.5 * maxf(open, 0.02)))
		_set_p(d, &"pulse", snappedf(0.25 * pulse + (0.8 if fx.t > fx.dur - 0.35 else 0.0), 0.05))


## Moves the Vigil wisp along lerp + sin arc; a thin trail of motes; calls play_vigil() on the Deacon on arrival.
func _tick_mover(fx: Fx) -> void:
	var k := clampf(fx.t / maxf(fx.fly, 0.01), 0.0, 1.0)
	var e := k * k * (3.0 - 2.0 * k)
	var p := fx.a.lerp(fx.b, e) + Vector3.UP * sin(k * PI) * fx.arc
	var s := fx.mover.s0.lerp(fx.mover.s1, k)
	var xf := Transform3D(Basis.from_scale(s), p)
	if not xf.is_equal_approx(fx.mover.n.transform):
		fx.mover.n.transform = xf
	if k < 1.0:
		fx.trail_left -= get_process_delta_time()
		if fx.trail_left <= 0.0 and fx.shown:
			fx.trail_left = 0.06
			_burst(&"vigil_trail", p, 1.0, Basis.IDENTITY)
	elif not fx.landed:
		fx.landed = true
		if fx.tnode:
			var m := _model_of(fx.tnode)
			for o: Node3D in [fx.tnode, m]:
				if o and is_instance_valid(o) and o.has_method(&"play_vigil"):
					o.call(&"play_vigil")
					break


func _finish(fx: Fx) -> void:
	for d in fx.pieces:
		d.n.visible = false
		d.n.set_instance_shader_parameter(&"fade", 0.0)
		(_free[d.pool] as Array).append(d.n)
	fx.pieces.clear()
	fx.rifts.clear()
	fx.beam = null
	fx.thread = null
	fx.dthread = null
	fx.dflare = null
	fx.mover = null
	if fx.key != "" and _tethers.get(fx.key) == fx:
		_tethers.erase(fx.key)


## The tether origin: the Deacon model's taper flame (get_tether_origin), else 2.1 m over the node / the Vector3.
func _origin_of(deacon: Node3D, fallback: Variant) -> Variant:
	if deacon:
		var o: Variant = _call_point(deacon, &"get_tether_origin")
		if o != null:
			return o
		return deacon.global_position + Vector3.UP * _h(deacon) * 1.1
	if fallback is Vector3:
		return (fallback as Vector3) + Vector3.UP * 2.1
	return null


## Axial billboard (beam / rope shaders): +Y end at `head`, basis Y = dir x length, X = width.
func _axial(n: Node3D, head: Vector3, dir: Vector3, length: float, width: float) -> void:
	var dn := dir.normalized() if dir.length_squared() > 0.000001 else Vector3.UP
	length = maxf(length, 0.05)
	var ref := Vector3.UP if absf(dn.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	var side := dn.cross(ref).normalized()
	var fwd := side.cross(dn).normalized()
	n.transform = Transform3D(Basis(side * width, dn * length, fwd), head - dn * length * 0.5)


# ---------------------------------------------------------------- shared resources (built once)

func _build_shared() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(2.0, 2.0)
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	var meshes := {&"disc": plane, &"ring": plane, &"flare": quad, &"beam": quad, &"rope": quad, &"rift": plane}
	var mats := {&"disc": _shader_mat(GROUND_SHADER), &"ring": _shader_mat(RING_SHADER),
			&"flare": _shader_mat(FLARE_SHADER), &"beam": _shader_mat(BEAM_SHADER), &"rope": _shader_mat(ROPE_SHADER),
			&"rift": _shader_mat(RIFT_SHADER)}
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
			if pool != &"disc" and pool != &"ring":
				m.extra_cull_margin = 8.0   # billboards / axial quads / turned rifts leave their mesh AABB
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


func _pmat(key: StringName) -> ParticleProcessMaterial:
	if _pmats.has(key):
		return _pmats[key]
	var m := ParticleProcessMaterial.new()
	var pale := _hdr(PALE, 2.2)
	var violet := _hdr(VIOLET, 1.8)
	var tithe := _hdr(TITHE, 1.8)
	var dusk := _hdr(VIOLET, 0.4, 0.0)
	match key:
		&"tithe_heal":
			# violet-red motes rising round the healed ally
			_ring_shape(m, 0.35, 0.3)
			m.direction = Vector3.UP
			m.spread = 10.0
			m.initial_velocity_min = 0.8
			m.initial_velocity_max = 1.4
			m.damping_min = 0.5
			m.damping_max = 1.0
			_size(m, 0.08, 0.12, &"shrink")
			m.color_ramp = _ramp_tex([pale, tithe, _hdr(BLOOD, 0.6, 0.0)])
		&"tithe_spark":
			_sphere(m, 0.06)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 1.0
			m.initial_velocity_max = 2.2
			m.damping_min = 3.0
			m.damping_max = 5.0
			_size(m, 0.06, 0.1, &"shrink")
			m.color_ramp = _ramp_tex([pale, tithe, _hdr(BLOOD, 0.5, 0.0)])
		&"rift_swirl":
			# motes spiralling up and in around the rift
			_ring_shape(m, 1.1, 0.2)
			m.direction = Vector3.UP
			m.spread = 15.0
			m.initial_velocity_min = 0.9
			m.initial_velocity_max = 1.8
			m.tangential_accel_min = 3.0
			m.tangential_accel_max = 5.0
			m.radial_accel_min = -2.5
			m.radial_accel_max = -1.5
			m.damping_min = 0.4
			m.damping_max = 0.8
			_size(m, 0.08, 0.13, &"hold")
			m.color_ramp = _ramp_at([0.0, 0.15, 0.7, 1.0], [Color(pale, 0.0), violet, violet, dusk])
		&"rift_smoke":
			_ring_shape(m, 0.9, 0.2)
			m.direction = Vector3.UP
			m.spread = 25.0
			m.initial_velocity_min = 0.4
			m.initial_velocity_max = 1.0
			m.tangential_accel_min = 1.0
			m.tangential_accel_max = 2.0
			m.gravity = Vector3(0, 0.4, 0)
			_spin(m, 50.0)
			_size(m, 0.7, 1.1, &"grow")
			m.color_initial_ramp = _ramp_tex(_lin([Color(0.10, 0.04, 0.14), Color(0.18, 0.08, 0.24)]))
			m.color_ramp = _ramp_at([0.0, 0.2, 0.65, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.6), Color(1, 1, 1, 0.3),
					Color(1, 1, 1, 0.0)])
		&"step_motes":
			_ring_shape(m, 0.45, 0.1)
			m.direction = Vector3.UP
			m.spread = 20.0
			m.initial_velocity_min = 1.2
			m.initial_velocity_max = 2.4
			m.damping_min = 1.5
			m.damping_max = 2.5
			_size(m, 0.08, 0.13, &"shrink")
			m.color_ramp = _ramp_tex([pale, violet, dusk])
		&"vigil_trail":
			_sphere(m, 0.05)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 0.1
			m.initial_velocity_max = 0.4
			_size(m, 0.06, 0.09, &"shrink")
			m.color_ramp = _ramp_tex([pale, violet, dusk])
	_pmats[key] = m
	return m


# ---------------------------------------------------------------- shared runtime (same pattern as CasterFireVfx)

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


## Fades a piece the effect positions itself (tether, threads, rifts, wisp).
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
	var vis := fx.shown and f > 0.002 and not d.hidden
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
	if lt <= d.age_until and (d.pool == &"disc" or d.pool == &"flare"):
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
	d.is_disc = pool == &"disc"
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


func _ramp(d: Piece, param: StringName, c0: Color, c1: Color, time: float) -> void:
	if d == null:
		return
	d.ramp_param = param
	d.c0 = c0
	d.c1 = c1
	d.ramp_time = time
	d.lc = -1.0


func _disc(fx: Fx, at: int, pattern: int, tint: Color, r0: float, r1: float, grow: float, on: float, off: float,
		fin: float, fout: float) -> Piece:
	_layer = (_layer + 1) % 8
	var d := _piece(fx, &"disc", at, Vector3.UP * (0.05 + 0.006 * float(_layer)), on, off, fin, fout)
	_grow(d, Vector3(r0, 1.0, r0), Vector3(r1, 1.0, r1), grow)
	_params(d, {&"pattern": float(pattern), &"tint": tint, &"seed": _rng.randf() * 10.0})
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
