class_name CasterIceVfx
extends Node3D
## Rimecarver effects (task CU.V5, Ice part; docs/design/caster-units.md 5.2 / 10.5). An effect FAMILY of UnitVfx
## (art/vfx/unit_vfx.gd loads it once its path is listed in MODULES: the ui-coder wires that line and the calls);
## callers never reach it directly:
##   var vfx := get_tree().get_first_node_in_group(&"unit_vfx")
##   if vfx: vfx.play(&"rime_bulwark", wall_centre, {"from": rimecarver, "time": 8.0})
## It can also live on its own (a test level, the Art Lab `kind=vfx`). Draw-only: it never touches gameplay (the wall's
## collision / navigation obstacle is gameplay's StaticBody3D; this draws its look).
## Ids (`target` may always be null):
##   rime_bulwark         at = the wall's ground centre: a Vector3, a Transform3D (origin = centre, basis.x = the long
##                        axis), or a Node3D (gameplay's Bulwark body: its transform; the wall follows it while it lives).
##                        target = the caster (Node3D: a Rimecarver unit / model; the wall is laid perpendicular to the
##                        line caster -> centre and a frost crack runs from the caster's feet to it), a Vector3 (the
##                        caster's position), or a Dictionary {from: Node3D / Vector3, time: 8.0, team: int}.
##                        Rise: the frost crack races to the spot (0.15 s), ice shards burst up along the 4 m line, the
##                        slab grows out of the ground in 0.3 s (a glowing growth rim, a flash at full height), frost mist
##                        at its base, a steel-blue rime strip under it. Stand: a translucent steel-blue slab with carved
##                        runes glowing inside, `time` s (default 8). Then it melts by itself (see rime_bulwark_melt).
##   rime_bulwark_shatter at = the wall's centre (Vector3; the nearest wall within 2 m) or its Node3D. A pop-3 unit or a
##                        titan broke it: a cyan crack flash, 20 ice chunks thrown out, a frost puff; the slab dissolves
##                        from its cracks in 0.15 s.
##   rime_bulwark_melt    at = as shatter. The 8 s ran out: it slumps and turns clear, drips fall, gone in 0.5 s.
##   scrying_rune         at = the rune's ground point (Vector3; a Node3D = its position). target = the owner team (int),
##                        or a Dictionary {team: int, time: 20.0, from: Node3D / Vector3 (the thrower: a short arc)}.
##                        A grey rune-stone with a cyan carver's rune drops in (a lob from the thrower when given), sticks
##                        in the ground with a puff, a soft 2 m light pillar, glints; the 10 m vision ring turns on the
##                        ground for the OWNER team only. Lasts `time` s (20), then fades (0.5 s).
##   scrying_rune_end     at = the rune's point (the nearest rune within 1.5 m) or its Node3D anchor: fades it now.
## Fog: the local team's effects always show; others only where the local team sees (FogOfWar.is_visible), checked 4 x
## per second. The Scrying Rune's ring shows only to its owner team; its stone / pillar follow the fog rule.
## Budget: everything is pre-built at _ready and pooled (walls, ground marks, rings, flares, rune stones, pillars,
## one-shot bursts). One material per shader / look, looks set with instance uniforms: no node, material or mesh is
## created after _ready. No lights, no shadows. Bursts are not started beyond 45 m from the camera; at most
## BURSTS_PER_FRAME new bursts a frame. A pool that runs dry skips that piece (never allocates).
## Colours: Ice clarity pass (2026-09-30): steel-blue bodies, cyan accents, nothing near-white; glows at or under the
## bloom except the rune strokes.

const GROUP := &"caster_ice_vfx"
const EFFECTS: Array[StringName] = [&"rime_bulwark", &"rime_bulwark_shatter", &"rime_bulwark_melt", &"scrying_rune",
		&"scrying_rune_end"]

const CYAN := Color(0.30, 0.82, 1.0)
const STEEL := Color(0.30, 0.46, 0.66)
const MIST := Color(0.56, 0.70, 0.86)

const WALL_LEN := 4.0
const WALL_THICK := 0.9
const WALL_H := 2.2
const WALL_TIME := 8.0
const RISE_DELAY := 0.12      # the crack reaches the spot first
const RISE_TIME := 0.3
const MELT_TIME := 0.5
const SHATTER_TIME := 0.15
const RUNE_TIME := 20.0
const RUNE_RADIUS := 10.0
const RUNE_FADE := 0.5
const PARTICLE_RANGE := 45.0
const BURSTS_PER_FRAME := 16
const CHECK_INTERVAL := 0.25
const FOG_RESCAN := 1.0
const MATCH_DIST := 2.0

enum { A_POINT, A_WORLD }

const POOL_SIZES := {&"wall": 8, &"ground": 24, &"ring": 12, &"flare": 32, &"stone": 12, &"pillar": 12}
## One-shot bursts: look -> [amount, lifetime, draw pass, pool size, explosiveness, visibility half-extent (m)].
const BURSTS := {
	&"rise_shards": [26, 0.9, &"shard", 6, 0.9, 4.0],
	&"rise_mist": [10, 1.5, &"mist", 6, 0.8, 4.0],
	&"shatter_chunks": [20, 1.3, &"chunk", 4, 1.0, 5.0],
	&"shatter_mist": [8, 1.2, &"mist", 4, 0.9, 5.0],
	&"melt_drips": [16, 0.7, &"drip", 6, 0.1, 4.0],
	&"rune_puff": [7, 0.9, &"mist", 8, 0.95, 3.0],
	&"rune_glints": [8, 1.2, &"glint", 8, 0.7, 3.0],
}
const OPTIONAL_BURSTS: Array[StringName] = [&"rune_glints", &"rise_mist", &"shatter_mist"]

const GROUND_SHADER := preload("res://art/vfx/caster_ice_ground.gdshader")
const WALL_SHADER := preload("res://art/vfx/caster_ice_wall.gdshader")
const FLARE_SHADER := preload("res://art/vfx/champion_flare.gdshader")
const RING_SHADER := preload("res://art/vfx/vfx_ring.gdshader")
const BEAM_SHADER := preload("res://art/vfx/vfx_beam.gdshader")


## One running effect: pooled pieces + scheduled bursts. A wall / rune keeps its piece list until it ends.
class Fx:
	extends RefCounted
	var id: StringName
	var t := 0.0
	var dur := 1.0
	var point := Vector3.ZERO
	var basis := Basis.IDENTITY
	var team := -1
	var shown := true
	var owner_only := false        # the scrying ring: owner team only
	var check_left := 0.0
	var follow: Node3D = null
	var pieces: Array[Piece] = []
	var bursts: Array[Dictionary] = []
	var bursts_left := 0
	# wall / rune state
	var wall: Piece = null
	var ending := &""              # &"", &"melt", &"shatter", &"fade"
	var end_t := -1.0
	var hold := 0.0                # the time the wall / rune stands (s)
	var lob_from := Vector3.ZERO
	var lob := false
	var followed := false          # `follow` was given: the wall melts when that body goes away


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
	var draw_time := 0.0          # ground marks: `draw` 0 -> 1 over this (0 = drawn at once)
	var lf := -1.0
	var ld := -1.0
	var owner_only := false
	var last: Dictionary = {}     # instance uniform -> the last value sent (_set_p skips unchanged values)


var _fx: Array[Fx] = []
var _free: Dictionary = {}
var _all: Dictionary = {}
var _bursts: Dictionary = {}
var _burst_next: Dictionary = {}
var _live_bursts: Array[Dictionary] = []
var _bursts_this_frame := 0
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
	_rng.seed = 2107
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
	return EFFECTS.has(id)


## Plays effect `id` (see the header). True when `id` is one of EFFECTS (handled even if fog hides it or a pool is full).
func play(id: StringName, at: Variant, target: Variant = null) -> bool:
	if not EFFECTS.has(id):
		return false
	if not is_node_ready() or not is_inside_tree():
		return true
	match id:
		&"rime_bulwark": _bulwark(at, target)
		&"rime_bulwark_shatter": _end_wall(at, &"shatter")
		&"rime_bulwark_melt": _end_wall(at, &"melt")
		&"scrying_rune": _rune(at, target)
		&"scrying_rune_end": _end_rune(at)
	return true


func active_count() -> int:
	return _fx.size()


func live_count() -> int:
	var n := _live_bursts.size()
	for pool: StringName in _all:
		for g: GeometryInstance3D in _all[pool]:
			if g.visible:
				n += 1
	return n


## Standing walls (tests).
func wall_count() -> int:
	var n := 0
	for fx in _fx:
		if fx.id == &"rime_bulwark" and fx.ending == &"":
			n += 1
	return n


## Standing runes (tests).
func rune_count() -> int:
	var n := 0
	for fx in _fx:
		if fx.id == &"scrying_rune" and fx.ending == &"":
			n += 1
	return n


# ---------------------------------------------------------------- the effects

func _bulwark(at: Variant, target: Variant) -> void:
	var anchor := _node(at)
	var centre: Variant = null
	var basis := Basis.IDENTITY
	var has_basis := false
	if at is Vector3:
		centre = at
	elif at is Transform3D:
		centre = (at as Transform3D).origin
		basis = _flat_basis((at as Transform3D).basis.x)
		has_basis = true
	elif anchor:
		centre = anchor.global_position
		basis = _flat_basis(anchor.global_basis.x)
		has_basis = true
	if centre == null:
		return
	var c: Vector3 = centre
	var from: Variant = null
	var hold := WALL_TIME
	var team := -1
	var src: Variant = target
	if target is Dictionary:
		var d: Dictionary = target
		src = d.get("from", null)
		hold = float(d.get("time", hold))
		team = int(d.get("team", -1))
	var src_node := _node(src)
	if src_node:
		from = src_node.global_position
		if team < 0:
			team = _team_of(src_node)
	elif src is Vector3:
		from = src
	if not has_basis:
		var dir := Vector3.FORWARD
		if from != null:
			var dd: Vector3 = c - (from as Vector3)
			dd.y = 0.0
			if dd.length_squared() > 0.04:
				dir = dd.normalized()
		basis = _flat_basis(dir.cross(Vector3.UP))   # the long axis across the caster's line
	var fx := _new_fx(&"rime_bulwark", c, team)
	fx.basis = basis
	fx.follow = anchor
	fx.followed = anchor != null
	fx.hold = maxf(hold, RISE_DELAY + RISE_TIME + 0.2)
	fx.dur = fx.hold + MELT_TIME
	# The frost crack from the caster's feet to the wall (drawn in over RISE_DELAY + a little).
	if from != null:
		var f: Vector3 = from
		f.y = c.y
		var v := c - f
		var l := v.length()
		if l > 0.6:
			var zb := _flat_basis_z(v / l)
			var cr := _ground(fx, A_WORLD, 0, _hdr(CYAN, 1.3), Vector3(0.35, 1.0, l * 0.5), (f + c) * 0.5, zb, 0.0,
				RISE_DELAY + 1.4, 0.0, 0.8)
			if cr:
				cr.draw_time = RISE_DELAY + 0.04
	# The rime strip under the wall, the wall itself, the growth flash.
	_ground(fx, A_POINT, 2, _hdr(CYAN, 0.8), Vector3(WALL_LEN * 0.56, 1.0, WALL_THICK * 0.9), Vector3.ZERO, basis,
		RISE_DELAY, -MELT_TIME * 0.5, 0.2, 0.6)
	var w := _piece(fx, &"wall", A_POINT, Vector3.ZERO, RISE_DELAY, 0.0, 0.0, 0.0)
	if w:
		w.rot = basis
		fx.wall = w
		_params(w, {&"rise": 0.0, &"melt": 0.0, &"fade": 1.0, &"age": -1.0, &"seed": _rng.randf() * 10.0})
	_flare(fx, A_POINT, Vector3.UP * WALL_H * 0.9, _hdr(CYAN, 1.2), 0.8, 2.6, 0.15, RISE_DELAY + RISE_TIME - 0.05,
		RISE_DELAY + RISE_TIME + 0.35, 0.03, 0.3, 0.6, 6.0)
	_ring(fx, A_POINT, _hdr(CYAN, 0.9), 0.8, 2.4, RISE_TIME, RISE_DELAY, RISE_DELAY + 0.45, 0.02, 0.25, 0.03, 0.05)
	_sched(fx, &"rise_shards", RISE_DELAY, A_POINT, Vector3.UP * 0.1, 1.0, basis)
	_sched(fx, &"rise_mist", RISE_DELAY + 0.05, A_POINT, Vector3.UP * 0.15, 1.0, basis)
	_start(fx)
	if fx.shown:
		_gplay(&"rime_bulwark", c, {"team": fx.team, "axis": basis.x, "delay": RISE_DELAY})


func _end_wall(at: Variant, how: StringName) -> void:
	var fx := _find(&"rime_bulwark", at, MATCH_DIST)
	if fx == null:
		if _find(&"rime_bulwark", at, MATCH_DIST, true) == null:
			_loose_end(at, how)   # no wall there at all (an ending one there: already going, nothing to add)
		return
	fx.ending = how
	fx.end_t = fx.t
	var len := SHATTER_TIME if how == &"shatter" else MELT_TIME
	fx.dur = fx.t + len + 0.05
	var up := fx.basis
	if how == &"shatter":
		_flare(fx, A_POINT, Vector3.UP * 1.1, _hdr(CYAN, 1.8), 1.2, 3.2, 0.1, fx.t, fx.t + 0.3, 0.0, 0.2, 0.9, 6.0)
		_sched(fx, &"shatter_chunks", fx.t, A_POINT, Vector3.UP * 1.0, 1.0, up)
		_sched(fx, &"shatter_mist", fx.t + 0.02, A_POINT, Vector3.UP * 0.4, 1.0, up)
	else:
		_sched(fx, &"melt_drips", fx.t, A_POINT, Vector3.UP * 1.2, 1.0, up)
	if fx.shown:
		_gplay(&"rime_bulwark_shatter" if how == &"shatter" else &"rime_bulwark_melt", fx.point, {"team": fx.team})


func _rune(at: Variant, target: Variant) -> void:
	var anchor := _node(at)
	var p: Variant = at if at is Vector3 else (anchor.global_position if anchor else null)
	if p == null:
		return
	var team := -1
	var hold := RUNE_TIME
	var from: Variant = null
	if target is int:
		team = int(target)
	elif target is Dictionary:
		var d: Dictionary = target
		team = int(d.get("team", -1))
		hold = float(d.get("time", hold))
		var f: Variant = d.get("from", null)
		var fn := _node(f)
		if fn:
			from = fn.global_position + Vector3.UP * 1.1
			if team < 0:
				team = _team_of(fn)
		elif f is Vector3:
			from = f
	var c: Vector3 = p
	var fx := _new_fx(&"scrying_rune", c, team)
	fx.follow = anchor
	fx.hold = maxf(hold, 1.0)
	fx.dur = fx.hold + RUNE_FADE
	var land := 0.0
	if from != null and (from as Vector3).distance_to(c) > 1.0:
		fx.lob = true
		fx.lob_from = from
		land = 0.35
	# The stone (lobbed or dropped in), the pillar, the vision ring (owner team only), a small frost mark.
	var st := _piece(fx, &"stone", A_POINT, Vector3.ZERO, 0.0, 0.0, 0.0, RUNE_FADE)
	if st:
		st.rot = Basis(Vector3.UP, _rng.randf() * TAU)
		fx.wall = st   # the anchor piece (moved by the lob)
	var pl := _piece(fx, &"pillar", A_POINT, Vector3.UP * 1.1, land + 0.05, 0.0, 0.35, RUNE_FADE)
	if pl:
		pl.rot = Basis.from_scale(Vector3(1.0, 2.0, 1.0))
		_params(pl, {&"core": _hdr(CYAN, 0.9, 0.55), &"body_color": Color(0.04, 0.12, 0.22, 0.0), &"width": 0.34,
				&"tail": 0.85, &"flow": 0.8, &"wobble": 0.0, &"seed": _rng.randf() * 10.0})
	var ring := _ground(fx, A_POINT, 1, _hdr(CYAN, 0.9), Vector3(RUNE_RADIUS, 1.0, RUNE_RADIUS), Vector3.ZERO,
		Basis.IDENTITY, land, 0.0, 0.3, RUNE_FADE)
	if ring:
		ring.owner_only = true
		ring.draw_time = 0.6
	_ground(fx, A_POINT, 2, _hdr(CYAN, 0.7), Vector3(0.55, 1.0, 0.55), Vector3.ZERO, Basis.IDENTITY, land, 0.0, 0.1,
		RUNE_FADE)
	_flare(fx, A_POINT, Vector3.UP * 0.35, _hdr(CYAN, 1.5), 0.3, 1.2, 0.12, land, land + 0.4, 0.0, 0.3, 0.7, 6.0)
	_ring(fx, A_POINT, _hdr(CYAN, 1.0), 0.2, 1.6, 0.45, land, land + 0.6, 0.0, 0.35, 0.08, 0.2)
	_sched(fx, &"rune_puff", land, A_POINT, Vector3.UP * 0.1)
	_sched(fx, &"rune_glints", land + 0.05, A_POINT, Vector3.UP * 0.3)
	_start(fx)
	if fx.shown:
		_gplay(&"scrying_rune", c, {"team": fx.team, "delay": land})


## A shatter / melt with no wall drawn there (gameplay's wall was never shown, or a test): the burst alone.
func _loose_end(at: Variant, how: StringName) -> void:
	var n := _node(at)
	var p: Variant = at if at is Vector3 else (n.global_position if n else null)
	if p == null:
		return
	var fx := _new_fx(&"rime_bulwark_end", p, _team_of(n))
	fx.dur = 0.9
	fx.hold = 99.0
	fx.ending = &"loose"
	_ground(fx, A_POINT, 2, _hdr(CYAN, 0.8), Vector3(WALL_LEN * 0.5, 1.0, WALL_THICK * 0.8), Vector3.ZERO, Basis.IDENTITY,
		0.0, 0.0, 0.05, 0.5)
	if how == &"shatter":
		_flare(fx, A_POINT, Vector3.UP * 1.1, _hdr(CYAN, 1.8), 1.2, 3.2, 0.1, 0.0, 0.3, 0.0, 0.2, 0.9, 6.0)
		_sched(fx, &"shatter_chunks", 0.0, A_POINT, Vector3.UP * 1.0)
		_sched(fx, &"shatter_mist", 0.02, A_POINT, Vector3.UP * 0.4)
	else:
		_flare(fx, A_POINT, Vector3.UP * 0.8, _hdr(CYAN, 0.9), 1.6, 2.4, 0.4, 0.0, 0.6, 0.05, 0.3)
		_sched(fx, &"melt_drips", 0.0, A_POINT, Vector3.UP * 1.2)
		_sched(fx, &"rise_mist", 0.05, A_POINT, Vector3.UP * 0.15)
	_start(fx)
	if fx.shown:
		_gplay(&"rime_bulwark_shatter" if how == &"shatter" else &"rime_bulwark_melt", fx.point, {"team": fx.team})


func _end_rune(at: Variant) -> void:
	var fx := _find(&"scrying_rune", at, 1.5)
	if fx == null:
		if _find(&"scrying_rune", at, 1.5, true) != null:
			return   # the rune there is already fading
		var n := _node(at)
		var p: Variant = at if at is Vector3 else (n.global_position if n else null)
		if p == null:
			return
		var lf := _new_fx(&"scrying_rune_end", p, _team_of(n))
		lf.dur = 0.7
		lf.hold = 99.0
		lf.ending = &"loose"
		_flare(lf, A_POINT, Vector3.UP * 0.4, _hdr(CYAN, 1.4), 0.9, 0.3, 0.6, 0.0, 0.6, 0.0, 0.4, 0.5, 6.0)
		_ring(lf, A_POINT, _hdr(CYAN, 0.9), 1.4, 0.3, 0.6, 0.0, 0.6, 0.0, 0.4, 0.1, 0.2)
		_sched(lf, &"rune_puff", 0.0, A_POINT, Vector3.UP * 0.1)
		_start(lf)
		return
	fx.ending = &"fade"
	fx.end_t = fx.t
	fx.dur = fx.t + RUNE_FADE


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
	fx.team = team
	return fx


func _start(fx: Fx) -> void:
	_wake()
	_fx.append(fx)
	_refresh(fx)
	fx.check_left = CHECK_INTERVAL
	_tick(fx, 0.0)


## The running effect of `id` that `at` names: the Fx following that Node3D first, else the nearest to `at` (a
## Vector3, or the node's position) within `dist` m, the oldest on a tie. Effects already ending are skipped unless
## `ending_too` (then only those are looked at), so a second end call never hits a wall / rune that is already going.
func _find(id: StringName, at: Variant, dist: float, ending_too := false) -> Fx:
	var n := _node(at)
	var p: Variant = at if at is Vector3 else (n.global_position if n else null)
	var best: Fx = null
	var bd := dist
	for fx in _fx:   # oldest first
		if fx.id != id or (fx.ending != &"") != ending_too:
			continue
		if n and fx.follow == n:
			return fx
		if p == null:
			continue
		var d := fx.point.distance_to(p)
		if d < bd or (best == null and d <= dist):
			bd = d
			best = fx
	return best


func _tick(fx: Fx, delta: float) -> bool:
	fx.t += delta
	if fx.follow:
		if is_instance_valid(fx.follow) and fx.follow.is_inside_tree():
			fx.point = fx.follow.global_position
		else:
			fx.follow = null
	if fx.followed and fx.follow == null and fx.id == &"rime_bulwark" and fx.ending == &"":
		_melt_now(fx)   # gameplay's wall body was freed / left the tree without a melt or shatter call
	fx.check_left -= delta
	if fx.check_left <= 0.0:
		fx.check_left += CHECK_INTERVAL
		_refresh(fx)
	# Auto-end: the wall melts, the rune fades once its time is up.
	if fx.ending == &"" and fx.t >= fx.hold:
		fx.ending = &"melt" if fx.id == &"rime_bulwark" else &"fade"
		fx.end_t = fx.hold
		if fx.id == &"rime_bulwark":
			_sched(fx, &"melt_drips", fx.t, A_POINT, Vector3.UP * 1.2, 1.0, fx.basis)
	var ef := 1.0
	if fx.ending != &"" and fx.ending != &"loose":
		var len := SHATTER_TIME if fx.ending == &"shatter" else (MELT_TIME if fx.ending == &"melt" else RUNE_FADE)
		ef = clampf(1.0 - (fx.t - fx.end_t) / len, 0.0, 1.0)
	_tick_wall(fx, ef)
	for d in fx.pieces:
		if d != fx.wall or fx.id != &"rime_bulwark":
			_tick_piece(fx, d, ef)
	if fx.bursts_left > 0:
		for b in fx.bursts:
			if not b["done"] and fx.t >= float(b["on"]):
				b["done"] = true
				fx.bursts_left -= 1
				if fx.shown:
					_burst(b["look"], _anchor(fx, b["at"]) + fx.basis * (b["ofs"] as Vector3), b["size"], b["basis"])
	return fx.t >= fx.dur and fx.bursts_left <= 0


## Starts the melt of a standing wall now (its body went away early).
func _melt_now(fx: Fx) -> void:
	fx.ending = &"melt"
	fx.end_t = fx.t
	fx.dur = fx.t + MELT_TIME + 0.05
	_sched(fx, &"melt_drips", fx.t, A_POINT, Vector3.UP * 1.2, 1.0, fx.basis)


## The wall's rise / melt / shatter uniforms, and the scrying stone's lob.
func _tick_wall(fx: Fx, ef: float) -> void:
	var d := fx.wall
	if d == null:
		return
	if fx.id == &"scrying_rune":
		if fx.lob:
			var k := clampf(fx.t / 0.35, 0.0, 1.0)
			var p := fx.lob_from.lerp(fx.point, k) + Vector3.UP * sin(k * PI) * 1.2
			d.ofs = p - fx.point
			d.o0 = d.ofs
		else:
			var k2 := clampf(fx.t / 0.15, 0.0, 1.0)
			d.ofs = Vector3.UP * (1.0 - k2 * k2) * 1.0
			d.o0 = d.ofs
		return
	var n := d.n
	var lt := fx.t - RISE_DELAY
	if lt < 0.0:
		if n.visible:
			n.visible = false
		return
	var rise := _ease(clampf(lt / RISE_TIME, 0.0, 1.0))
	var melt := 0.0
	var fade := 1.0
	if fx.ending == &"melt":
		melt = 1.0 - ef
		fade = clampf(ef * 1.6, 0.0, 1.0)
	elif fx.ending == &"shatter":
		fade = ef
	var xf := Transform3D(fx.basis, fx.point)
	if not xf.is_equal_approx(n.transform):
		n.transform = xf
	_set_p(d, &"rise", rise)
	_set_p(d, &"melt", melt)
	_set_p(d, &"fade", fade)
	if lt < 1.5:
		_set_p(d, &"age", lt - RISE_TIME + 0.3)
	var vis := fx.shown and fade > 0.01
	if n.visible != vis:
		n.visible = vis


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
	if d.fout > 0.0 and d.off > 0.0:
		f = minf(f, (off - fx.t) / d.fout)
	f = clampf(f, 0.0, 1.0)
	var k := 1.0
	if d.grow > 0.0:
		k = _ease(clampf(lt / d.grow, 0.0, 1.0))
	var s := d.s0.lerp(d.s1, k)
	var pos := _anchor(fx, d.at) + (fx.basis if d.at == A_POINT and d.pool != &"ground" else Basis.IDENTITY) * d.o0.lerp(d.ofs, k)
	if d.pool == &"stone":
		pos.y -= (1.0 - f) * 0.45   # the stone sinks away instead of fading
	var xf := Transform3D(d.rot * Basis.from_scale(s), pos)
	if not xf.is_equal_approx(n.transform):
		n.transform = xf
	if absf(f - d.lf) > 0.003 and d.pool != &"stone":
		d.lf = f
		n.set_instance_shader_parameter(&"fade", f)
	if d.pool == &"ground" and d.draw_time > 0.0:
		var dr := clampf(lt / d.draw_time, 0.0, 1.0)
		if absf(dr - d.ld) > 0.003:
			d.ld = dr
			n.set_instance_shader_parameter(&"draw", dr)
	if d.pool == &"flare" and lt <= 1.05:
		n.set_instance_shader_parameter(&"age", lt)
	var vis := fx.shown and f > 0.002 and (not d.owner_only or _is_owner(fx.team))
	if n.visible != vis:
		n.visible = vis


func _finish(fx: Fx) -> void:
	for d in fx.pieces:
		d.n.visible = false
		if d.pool != &"stone":
			d.n.set_instance_shader_parameter(&"fade", 0.0)
		(_free[d.pool] as Array).append(d.n)
	fx.pieces.clear()
	fx.wall = null


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


## True when the local team (the fog's local_team, else team 0) owns an effect of `team` (-1 = unknown: shown).
func _is_owner(team: int) -> bool:
	if team < 0:
		return true
	var local: Variant = _fog.get(&"local_team") if is_instance_valid(_fog) else null
	return team == (int(local) if local != null else 0)


func _anchor(fx: Fx, at: int) -> Vector3:
	return Vector3.ZERO if at == A_WORLD else fx.point


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
	if pool != &"stone":
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


## A ground mark (caster_ice_ground.gdshader) of half size `half` (x, -, z metres), at `ofs` (A_POINT: relative to
## the effect's point, A_WORLD: a world point), turned by `rot`.
func _ground(fx: Fx, at: int, pattern: int, tint: Color, half: Vector3, ofs: Vector3, rot: Basis, on: float, off: float,
		fin: float, fout: float) -> Piece:
	_layer = (_layer + 1) % 8
	var d := _piece(fx, &"ground", at, ofs + Vector3.UP * (0.04 + 0.006 * float(_layer)), on, off, fin, fout)
	if d == null:
		return null
	d.rot = rot
	_grow(d, Vector3(half.x, 1.0, half.z), Vector3(half.x, 1.0, half.z), 0.0)
	_params(d, {&"pattern": float(pattern), &"tint": tint, &"seed": _rng.randf() * 10.0, &"draw": 1.0,
			&"size": Vector2(half.x, half.z), &"age": 0.0})
	d.ld = -1.0
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


## A level basis whose +X is the flat direction `x`.
func _flat_basis(x: Vector3) -> Basis:
	var f := Vector3(x.x, 0.0, x.z)
	if f.length_squared() < 0.0001:
		f = Vector3.RIGHT
	f = f.normalized()
	return Basis(f, Vector3.UP, f.cross(Vector3.UP))


## A level basis whose +Z is the flat direction `z`.
func _flat_basis_z(z: Vector3) -> Basis:
	var f := Vector3(z.x, 0.0, z.z)
	if f.length_squared() < 0.0001:
		f = Vector3.BACK
	f = f.normalized()
	return Basis(Vector3.UP.cross(f), Vector3.UP, f)


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
	var wall_mat := ShaderMaterial.new()
	wall_mat.shader = WALL_SHADER
	var meshes := {&"wall": _wall_mesh(), &"ground": plane, &"ring": plane, &"flare": quad, &"stone": _stone_mesh(),
		&"pillar": quad}
	var mats := {&"wall": wall_mat, &"ground": _shader_mat(GROUND_SHADER), &"ring": _shader_mat(RING_SHADER),
		&"flare": _shader_mat(FLARE_SHADER), &"stone": null, &"pillar": _shader_mat(BEAM_SHADER)}
	for pool: StringName in POOL_SIZES:
		var arr: Array = []
		for i in int(POOL_SIZES[pool]):
			var m := MeshInstance3D.new()
			m.name = "%s%d" % [String(pool).capitalize(), i]
			m.mesh = meshes[pool]
			if mats[pool] != null:
				m.material_override = mats[pool]
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			m.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
			m.visible = false
			if pool == &"flare" or pool == &"pillar":
				m.extra_cull_margin = 4.0
			if pool == &"wall":
				m.extra_cull_margin = 1.0
			add_child(m)
			arr.append(m)
		_all[pool] = arr
		_free[pool] = arr.duplicate()
	_build_passes()
	for look: StringName in BURSTS:
		var spec: Array = BURSTS[look]
		var arr: Array = []
		for i in int(spec[3]):
			var p := GPUParticles3D.new()
			p.name = "%s_%d" % [look, i]
			p.process_material = _pmat(look)
			p.draw_pass_1 = _passes[spec[2]]
			p.amount = int(spec[0])
			p.lifetime = float(spec[1])
			p.one_shot = true
			p.explosiveness = float(spec[4])
			p.local_coords = false
			p.emitting = false
			p.visible = false
			p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			p.visibility_range_end = PARTICLE_RANGE
			var h: float = spec[5]
			p.visibility_aabb = AABB(Vector3(-h, -2.0, -h), Vector3(h * 2.0, 6.0, h * 2.0))
			VfxCap.fit(p)   # G-F VFX caps (docs/art/gf_vfx_caps.md)
			add_child(p)
			arr.append(p)
		_bursts[look] = arr
		_burst_next[look] = 0


func _shader_mat(shader: Shader) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader
	return m


## The Bulwark slab: 4.0 x 2.2 x 0.9 m, origin at the ground centre, long axis X. A trapezoid prism (0.9 m at the
## foot, 0.5 at the top) whose top edge is a row of jagged ice points (1.75-2.2 m), chiselled facets on both faces.
func _wall_mesh() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 9
	var tops: Array[float] = [1.80, 2.12, 1.86, 2.20, 1.95, 2.16, 1.78, 2.05, 1.84, 1.95]
	var hl := WALL_LEN * 0.5
	var front := PackedVector3Array()
	var back := PackedVector3Array()
	var ft := PackedVector3Array()
	var bt := PackedVector3Array()
	for i in n + 1:
		var u := float(i) / float(n)
		var x := -hl + u * WALL_LEN
		var end := 1.0 - 0.12 * (1.0 if i == 0 or i == n else 0.0)
		var h: float = tops[i] * end
		var bz := WALL_THICK * 0.5 * (1.0 + 0.06 * sin(float(i) * 2.7))
		var tz := 0.22 + 0.05 * sin(float(i) * 1.9)
		front.append(Vector3(x, 0.0, bz))
		back.append(Vector3(x, 0.0, -bz))
		# the upper facet row bends in half way up (a chiselled face), then the jagged point
		ft.append(Vector3(x + 0.05 * sin(float(i) * 3.1), h * 0.55, bz * 0.82))
		bt.append(Vector3(x - 0.05 * sin(float(i) * 2.3), h * 0.55, -bz * 0.82))
	var peaks := PackedVector3Array()
	for i in n + 1:
		peaks.append(Vector3(front[i].x + 0.04 * cos(float(i) * 2.1), tops[i] * (1.0 - 0.12 * (1.0 if i == 0 or i == n else 0.0)),
			0.03 * sin(float(i) * 1.3)))
	for i in n:
		var j := i + 1
		# front face: foot -> bend -> peak ridge
		_quad(st, front[i], front[j], ft[j], ft[i], Vector3(0, 0, 1))
		_quad(st, ft[i], ft[j], peaks[j], peaks[i], Vector3(0, 0.5, 1))
		_quad(st, back[j], back[i], bt[i], bt[j], Vector3(0, 0, -1))
		_quad(st, bt[j], bt[i], peaks[i], peaks[j], Vector3(0, 0.5, -1))
	# end caps
	for e: int in [0, n]:
		var sgn := -1.0 if e == 0 else 1.0
		var pts := [front[e], ft[e], peaks[e], bt[e], back[e]]
		var c := (front[e] + back[e] + peaks[e]) / 3.0
		for k in pts.size() - 1:
			_tri(st, c, pts[k], pts[k + 1], Vector3(sgn, 0, 0))
		_tri(st, c, back[e], front[e], Vector3(sgn, 0, 0))
	st.generate_normals()
	return st.commit()


## Triangle facing `out` (front face = (c - a) x (b - a) along `out`).
func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, out: Vector3) -> void:
	if (c - a).cross(b - a).dot(out) < 0.0:
		var t := b
		b = c
		c = t
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, out: Vector3) -> void:
	_tri(st, a, b, c, out)
	_tri(st, a, c, d, out)


## The scrying stone: a grey rune-stone (0.5 m) standing in the ground, the carver's rune glowing cyan on both faces.
func _stone_mesh() -> Mesh:
	var am := ArrayMesh.new()
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.36, 0.40, 0.47)
	stone.roughness = 0.85
	var glyph := StandardMaterial3D.new()
	glyph.albedo_color = Color(0.20, 0.62, 0.85)
	glyph.emission_enabled = true
	glyph.emission = Color(0.30, 0.85, 1.0)
	glyph.emission_energy_multiplier = 2.6
	var sp := SphereMesh.new()
	sp.radius = 0.2
	sp.height = 0.4
	sp.radial_segments = 8
	sp.rings = 4
	var st := SurfaceTool.new()
	st.append_from(sp, 0, Transform3D(Basis.from_scale(Vector3(0.85, 1.3, 0.55)), Vector3(0, 0.2, 0)))
	st.index()
	st.commit(am)
	am.surface_set_material(0, stone)
	var g := SurfaceTool.new()
	var bars: Array = [[Vector3(0.035, 0.24, 0.02), Vector3(0, 0.28, 0), 0.0], [Vector3(0.03, 0.12, 0.02), Vector3(-0.045, 0.32, 0), 40.0],
		[Vector3(0.03, 0.12, 0.02), Vector3(0.045, 0.32, 0), -40.0], [Vector3(0.11, 0.03, 0.02), Vector3(0, 0.165, 0), 0.0]]
	for z: float in [0.105, -0.105]:
		for b: Array in bars:
			var bm := BoxMesh.new()
			bm.size = b[0]
			g.append_from(bm, 0, Transform3D(Basis(Vector3.BACK, deg_to_rad(float(b[2]))), (b[1] as Vector3) + Vector3(0, 0, z)))
	g.index()
	g.commit(am)
	am.surface_set_material(1, glyph)
	return am


func _build_passes() -> void:
	_passes[&"shard"] = _prism_pass(Vector3(0.09, 0.22, 0.06), Color(0.36, 0.60, 0.84), 0.5)
	_passes[&"chunk"] = _prism_pass(Vector3(0.24, 0.34, 0.18), Color(0.30, 0.52, 0.78), 0.35)
	_passes[&"mist"] = _particle_quad(_soft_tex(), BaseMaterial3D.BLEND_MODE_MIX)
	_passes[&"drip"] = _particle_quad(_soft_tex(), BaseMaterial3D.BLEND_MODE_MIX)
	_passes[&"glint"] = _particle_quad(_soft_tex(), BaseMaterial3D.BLEND_MODE_ADD)


func _prism_pass(size: Vector3, col: Color, emit: float) -> PrismMesh:
	var m := PrismMesh.new()
	m.size = size
	var sm := StandardMaterial3D.new()
	sm.albedo_color = col
	sm.emission_enabled = true
	sm.emission = Color(0.14, 0.52, 0.90)
	sm.emission_energy_multiplier = emit
	sm.roughness = 0.2
	sm.metallic_specular = 0.9
	m.material = sm
	return m


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
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	q.material = mat
	return q


func _soft_tex() -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.45, Color(1, 1, 1, 0.55))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 64
	gt.height = 64
	return gt


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


## Particle process materials (one per look). Directions are in the emitter's basis (the wall's: X along it).
func _pmat(look: StringName) -> ParticleProcessMaterial:
	if _pmats.has(look):
		return _pmats[look]
	var m := ParticleProcessMaterial.new()
	m.collision_mode = ParticleProcessMaterial.COLLISION_DISABLED
	match look:
		&"rise_shards":
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			m.emission_box_extents = Vector3(WALL_LEN * 0.5, 0.05, WALL_THICK * 0.45)
			m.direction = Vector3.UP
			m.spread = 28.0
			m.initial_velocity_min = 3.0
			m.initial_velocity_max = 6.0
			m.gravity = Vector3(0, -12.0, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			m.angular_velocity_min = -400.0
			m.angular_velocity_max = 400.0
			m.particle_flag_rotate_y = true
			m.scale_min = 0.6
			m.scale_max = 1.5
			m.scale_curve = _curve([Vector2(0, 1.0), Vector2(0.8, 0.9), Vector2(1, 0.0)])
		&"shatter_chunks":
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			m.emission_box_extents = Vector3(WALL_LEN * 0.45, 0.8, WALL_THICK * 0.3)
			m.direction = Vector3(0, 0.6, 1.0)
			m.spread = 180.0
			m.initial_velocity_min = 2.5
			m.initial_velocity_max = 6.0
			m.gravity = Vector3(0, -14.0, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			m.angular_velocity_min = -500.0
			m.angular_velocity_max = 500.0
			m.particle_flag_rotate_y = true
			m.scale_min = 0.6
			m.scale_max = 1.6
			m.scale_curve = _curve([Vector2(0, 1.0), Vector2(0.85, 0.9), Vector2(1, 0.0)])
		&"rise_mist", &"shatter_mist":
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			m.emission_box_extents = Vector3(WALL_LEN * 0.5, 0.1, WALL_THICK * 0.6)
			m.direction = Vector3.UP
			m.spread = 60.0
			m.initial_velocity_min = 0.3
			m.initial_velocity_max = 0.9
			m.gravity = Vector3(0, 0.15, 0)
			m.damping_min = 0.5
			m.damping_max = 1.0
			m.scale_min = 1.2
			m.scale_max = 2.0
			m.scale_curve = _curve([Vector2(0, 0.4), Vector2(1, 1.0)])
			m.color_ramp = _ramp(Color(MIST.r, MIST.g, MIST.b, 0.42), Color(0.44, 0.58, 0.76, 0.3))
		&"melt_drips":
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			m.emission_box_extents = Vector3(WALL_LEN * 0.45, 0.8, WALL_THICK * 0.35)
			m.direction = Vector3.DOWN
			m.spread = 10.0
			m.initial_velocity_min = 0.2
			m.initial_velocity_max = 0.8
			m.gravity = Vector3(0, -9.0, 0)
			m.scale_min = 0.08
			m.scale_max = 0.14
			m.color_ramp = _ramp(Color(0.46, 0.72, 0.95, 0.8), Color(0.30, 0.55, 0.85, 0.6))
		&"rune_puff":
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			m.emission_sphere_radius = 0.15
			m.direction = Vector3.UP
			m.spread = 80.0
			m.initial_velocity_min = 0.4
			m.initial_velocity_max = 1.0
			m.gravity = Vector3(0, 0.1, 0)
			m.damping_min = 0.8
			m.damping_max = 1.4
			m.scale_min = 0.5
			m.scale_max = 0.9
			m.scale_curve = _curve([Vector2(0, 0.5), Vector2(1, 1.0)])
			m.color_ramp = _ramp(Color(MIST.r, MIST.g, MIST.b, 0.45), Color(0.44, 0.58, 0.76, 0.3))
		&"rune_glints":
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			m.emission_sphere_radius = 0.3
			m.direction = Vector3.UP
			m.spread = 20.0
			m.initial_velocity_min = 0.3
			m.initial_velocity_max = 0.8
			m.gravity = Vector3(0, 0.2, 0)
			m.scale_min = 0.06
			m.scale_max = 0.12
			var c := _hdr(CYAN, 1.6)
			m.color_ramp = _ramp(Color(c.r, c.g, c.b, 1.0), Color(c.r, c.g, c.b, 0.6), 0.1)
	_pmats[look] = m
	return m
