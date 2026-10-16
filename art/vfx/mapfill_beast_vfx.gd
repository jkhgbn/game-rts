class_name MapFillBeastVfx
extends Node3D
## Epic-beast effects (task 12.V31, docs/design/map-fill.md sections 5.5 and 10). Draw-only: never touches gameplay.
##
## ENTRY POINT (agreed with 12.V25): MapFillVfx (art/vfx/mapfill_vfx.gd) loads this script when the file exists,
## creates ONE instance as its child and forwards every id it does not handle itself:
##   var s := load("res://art/vfx/mapfill_beast_vfx.gd") as GDScript   # guarded by ResourceLoader.exists
##   _beasts = s.new(); add_child(_beasts)
##   ...
##   if _beasts and _beasts.play(id, at, target): return
## `play(id: StringName, at: Variant, target: Variant = null) -> bool` returns true when `id` is a beast effect (EFFECTS)
## (it is then "handled", even if fog hides it or a pool is full), false for any other id (nothing happens).
## `at` is a world point (Vector3; a Node3D is read once; null = the target's position); `target` a Node3D or null.
## `handles(id) -> bool` tells the same without playing. The node is also in group "mapfill_beast_vfx" (tests); it is
## NOT in "mapfill_vfx" (callers keep finding MapFillVfx). It can also live on its own (a test level): add it anywhere.
##
## Ids and the arguments their callers pass (scripts/units/creature_abilities.gd, scripts/world/epic_beasts.gd):
##   gore_charge     at = where the charge will end, target = the Tusker. Dust kicked up at the start, a dust + clod
##                   trail behind the running beast and a churned furrow with two tusk gouges stretching after it;
##                   when it stops (reaches `at`, or hits its victim early): a shock ring, a dust burst, clods, sparks.
##   gale_swoop      at = the landing point beside the victim, target = the Stormcrest Roc. A faint ring marks the spot
##                   during the dive, a pale wind streak trails the roc; on landing a storm-blue wind ring r 2.5, gust
##                   streaks blown outward, dust, a few pale feathers.
##   shrieking_dive  same arguments (the Duskwing Roc): violet shriek ring (sound waves racing out r 2.5), three air
##                   ripples at head height, violet motes (the Mark), dark feathers.
##   updraft         at = the Roc's position, target = the Roc. A feather swirl spiralling up around it (storm-blue or
##                   near-black / violet by variant) inside a wind column, a wind ring and dust blown out on the ground.
##   pounce          at = the landing point beside the victim, target = the Direwolf. A leap streak (grey or, for the
##                   Moonpelt, pale blue) trailing the wolf; on landing root claw marks raked into the ground at the
##                   victim (two paws, glowing edges, a binding ring flash), a small ring, dust and sparks.
##   hamstring       at = the victim's position, target = the victim. A small red slash across its legs + flecks.
##   maul            at = the victim's position, target = the victim. A three-claw swipe raked across it (0.11 s),
##                   an impact flare, a small ring, flecks and sparks.
##   rending_roar    at = the Grizzlemaw's position, target = it. A shock ring racing to r 6 (the dazed area) with a
##                   trailing ring, radial ground cracks, air ripples from the head, a dust wall, hopping pebbles.
##   beast_spawn     at = the lair centre, target = the new beast. A flock of birds bursts up from over the lair and
##                   flies off (plus a second, smaller flock), leaves shaken down, dust.
## Travel (gore_charge / gale_swoop / shrieking_dive / pounce): the impact waits for the beast to arrive. Landing =
## the beast stopped moving (>= 0.06 s) after it moved, or the travel time from the ability speeds (12 / 16 m/s, min
## 0.25 s) + 0.2 s is over, or the beast left the tree; the impact is placed where the beast is then.
## Variant (B = Old Scarback, Duskwing, Moonpelt, Elder Grizzlemaw): meta &"beast_variant" (EpicBeasts stamps it), else
## the UnitType id; it tints the updraft feathers and the pounce streak / claws.
## Fog: effects on a Unit follow its `visible` (fogged beasts / victims hide their effects); others check
## FogOfWar.is_visible at the point (4 times per second). The beast_spawn birds are the exception: they rise above the
## fog on purpose (the spawn is announced anyway, it is the "something woke up over there" tell).
## Budget: everything is pre-built at _ready and pooled (ground marks, glows, slashes, streaks, a column, one-shot
## bursts, a few trail emitters). One material per shader, looks set with instance uniforms: no node, material or mesh
## is created after _ready. No lights, no shadows. Every particle quad has a shape mask and `billboard_keep_scale`.
## Shaders: own mapfill_beast_ground (furrow, claws, shriek, cracks), mapfill_beast_air (slash, ripple),
## mapfill_beast_streak, mapfill_beast_column; reused read-only: champion_ground (shock / wind rings, soot),
## champion_flare (glows), combat_streak (sparks).

const GROUP := &"mapfill_beast_vfx"
const EFFECTS: Array[StringName] = [&"gore_charge", &"gale_swoop", &"shrieking_dive", &"updraft", &"pounce",
		&"hamstring", &"maul", &"rending_roar", &"beast_spawn"]

# Numbers from creature_abilities.gd (ABILITIES / motion constants).
const CHARGE_SPEED := 12.0
const LEAP_SPEED := 16.0
const MIN_MOTION_TIME := 0.25
const DIVE_RADIUS := 2.5
const ROAR_RADIUS := 6.0

# Palette (art-keep 0: painted, glow only where it matters). sRGB, converted with _hdr / _lin.
const DUST := Color(0.58, 0.48, 0.33)
const EARTH := Color(0.34, 0.25, 0.16)
const IMPACT := Color(1.0, 0.86, 0.62)
const STORM := Color(0.60, 0.80, 1.0)
const STORM_HOT := Color(0.88, 0.96, 1.0)
const SHRIEK := Color(0.70, 0.30, 1.0)          # the Shadow glow of art-keep 0.2: Duskwing's violet sheen
const SHRIEK_HOT := Color(0.92, 0.74, 1.0)
const WOLF := Color(0.86, 0.89, 0.94)
const MOON := Color(0.62, 0.82, 1.0)
const BLOOD := Color(0.92, 0.16, 0.10)
const BONE := Color(1.0, 0.93, 0.82)
const CLAW := Color(1.0, 0.52, 0.36)           # maul rake glow (white-hot core from the shader)
const ROAR := Color(1.0, 0.80, 0.52)
const BIRD := Color(0.10, 0.09, 0.10)

## UnitType ids of the B variants.
const B_TYPES: Array[StringName] = [&"old_scarback", &"duskwing_roc", &"moonpelt_direwolf", &"elder_grizzlemaw"]

const END_FADE := 0.2
const CHECK_INTERVAL := 0.25
const FOG_RESCAN := 1.0
const LAND_STILL := 0.06       # stopped this long after moving = landed
const LAND_GRACE := 0.2        # a still-moving beast lands at most this long after its estimated arrival
const NEVER := 1.0e9

enum { A_POINT, A_TARGET, A_START, A_LAND }
enum { VIS_POINT, VIS_TARGET }
enum { SPAN_NONE, SPAN_GROUND, SPAN_AIR }
enum { G_SHOCK, G_WIND, G_HEAL, G_ROPE, G_GLOW, G_SOOT, G_WARD }   # champion_ground.gdshader patterns
enum { M_FURROW, M_CLAWS, M_SHRIEK, M_CRACKS }                      # mapfill_beast_ground.gdshader patterns
enum { S_SLASH, S_RIPPLE }                                          # mapfill_beast_air.gdshader patterns

## Mesh pools (pre-built): pool -> size.
const POOL_SIZES := {&"disc": 14, &"mark": 10, &"flare": 16, &"air": 12, &"streak": 8, &"column": 3}
## One-shot bursts: look -> [amount, lifetime, draw pass, pool size, explosiveness].
const BURSTS := {
	&"dust_kick": [14, 0.8, &"mix_smoke", 4, 0.95],
	&"impact_dust": [22, 1.1, &"mix_smoke", 3, 0.95],
	&"impact_clods": [14, 0.8, &"mix_dot", 3, 1.0],
	&"tusk_sparks": [12, 0.35, &"streak", 3, 1.0],
	&"gust_streaks": [20, 0.45, &"streak", 3, 1.0],
	&"gust_dust": [16, 0.8, &"mix_smoke", 4, 0.95],
	&"storm_feathers": [7, 1.4, &"mix_feather", 3, 0.9],
	&"dusk_feathers": [8, 1.4, &"mix_feather", 3, 0.9],
	&"shriek_motes": [16, 0.9, &"add_star", 3, 0.8],
	&"updraft_dust": [18, 0.9, &"mix_smoke", 2, 0.95],
	&"pounce_dust": [10, 0.7, &"mix_smoke", 3, 0.95],
	&"claw_sparks": [8, 0.3, &"streak", 4, 1.0],
	&"blood_flecks": [6, 0.45, &"mix_dot", 4, 1.0],
	&"maul_flecks": [12, 0.6, &"mix_dot", 3, 1.0],
	&"roar_dust": [30, 1.1, &"mix_smoke", 2, 0.95],
	&"roar_debris": [22, 0.7, &"mix_dot", 2, 0.9],
	&"flock": [18, 3.8, &"mix_bird", 2, 0.75],
	&"flock_small": [9, 3.4, &"mix_bird", 2, 0.6],
	&"lair_leaves": [14, 1.6, &"mix_leaf", 2, 0.9],
}
## Trail emitters (emit while running, follow their anchor): look -> [amount, lifetime, draw pass, pool size].
const TRAILS := {
	&"charge_dust": [28, 0.95, &"mix_smoke", 3],
	&"charge_clods": [18, 0.6, &"mix_dot", 3],
	&"feather_swirl_a": [24, 1.5, &"mix_feather", 2],
	&"feather_swirl_b": [24, 1.5, &"mix_feather", 2],
}
## Emitters whose particles travel far (bigger visibility box).
const BIG_LOOKS: Array[StringName] = [&"flock", &"flock_small", &"roar_dust", &"roar_debris", &"feather_swirl_a",
		&"feather_swirl_b", &"lair_leaves"]

const GROUND_SHADER := preload("res://art/vfx/champion_ground.gdshader")
const FLARE_SHADER := preload("res://art/vfx/champion_flare.gdshader")
const SPARK_SHADER := preload("res://art/vfx/combat_streak.gdshader")
const MARK_SHADER := preload("res://art/vfx/mapfill_beast_ground.gdshader")
const AIR_SHADER := preload("res://art/vfx/mapfill_beast_air.gdshader")
const STREAK_SHADER := preload("res://art/vfx/mapfill_beast_streak.gdshader")
const COLUMN_SHADER := preload("res://art/vfx/mapfill_beast_column.gdshader")

## Shape masks shared by every instance (built once per run).
static var _tex_cache: Dictionary = {}


## One running effect.
class Fx:
	extends RefCounted
	var id: StringName
	var t := 0.0
	var dur := 1.0
	var target: Node3D
	var has_target := false
	var point := Vector3.ZERO
	var tpos := Vector3.ZERO
	var start := Vector3.ZERO
	var dir := Vector3(0.0, 0.0, 1.0)
	var team := -1
	var variant := 0
	var vis := 0                  # VIS_POINT / VIS_TARGET
	var end_at := -1.0
	var shown := true
	var check_left := 0.0
	# Dashes and leaps: pieces / bursts marked "on_rel" wait for the landing.
	var travel := false
	var est := 0.0
	var landed := true
	var land_t := 0.0
	var land_pos := Vector3.ZERO
	var after := 0.0
	var moved := false
	var still := 0.0
	var prev := Vector3.ZERO
	var pieces: Array[Piece] = []
	var bursts: Array[Dictionary] = []
	var bursts_left := 0
	var trails: Array[Dictionary] = []


## One pooled mesh of an effect: when it shows (on / off; off <= 0 = relative to the effect's end; on_rel / off_rel =
## measured from the landing), where (anchor + offset lerped from o0 while growing), how it grows (s0 -> s1 over
## `grow`), how it fades. `span` pieces stretch between the take-off and the beast instead (furrow, streak).
class Piece:
	extends RefCounted
	var n: GeometryInstance3D
	var pool: StringName
	var is_disc := false
	var at := 0
	var ofs := Vector3.ZERO
	var o0 := Vector3.ZERO
	var on := 0.0
	var off := 0.0
	var fin := 0.0
	var fout := 0.0
	var on_rel := false
	var off_rel := false
	var s0 := Vector3.ONE
	var s1 := Vector3.ONE
	var grow := 0.0
	var back := false
	var yaw := 0.0
	var span := 0
	var width := 1.0
	var maxlen := 4.0
	var lf := -1.0                # last fade sent
	var lr := -1.0                # last radius sent


var _fx: Array[Fx] = []
var _free: Dictionary = {}          # pool -> Array[GeometryInstance3D]
var _all: Dictionary = {}           # pool -> Array[GeometryInstance3D]
var _bursts: Dictionary = {}        # look -> Array[GPUParticles3D]
var _burst_next: Dictionary = {}
var _live_bursts: Array[Dictionary] = []   # {p, left}
var _trail_all: Dictionary = {}     # look -> Array[GPUParticles3D]
var _trail_free: Dictionary = {}
var _draining: Array[Dictionary] = []      # stopped trails whose particles still fly: {p, look, left}
var _pmats: Dictionary = {}
var _passes: Dictionary = {}
var _fog: Node
var _fog_left := 0.0
var _layer := 0


func _ready() -> void:
	add_to_group(GROUP)
	top_level = true                  # effects are placed in world space
	global_transform = Transform3D.IDENTITY
	_build_shared()


func _process(delta: float) -> void:
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
	for i in range(_draining.size() - 1, -1, -1):
		var d: Dictionary = _draining[i]
		d["left"] = float(d["left"]) - delta
		if float(d["left"]) <= 0.0:
			var p: GPUParticles3D = d["p"]
			p.visible = false
			(_trail_free[d["look"]] as Array).append(p)
			_draining.remove_at(i)


# ---------------------------------------------------------------- public API

## Plays beast effect `id` (see the header). Returns true when `id` is a beast effect (handled), false otherwise.
func play(id: StringName, at: Variant, target: Variant = null) -> bool:
	if not EFFECTS.has(id):
		return false
	if not is_node_ready() or not is_inside_tree():
		return true
	var t: Node3D = null
	if typeof(target) == TYPE_OBJECT and is_instance_valid(target) and target is Node3D:
		t = target as Node3D
		if not t.is_inside_tree():
			t = null
	var point: Vector3
	if at is Vector3:
		point = at
	elif typeof(at) == TYPE_OBJECT and is_instance_valid(at) and at is Node3D and (at as Node3D).is_inside_tree():
		point = (at as Node3D).global_position
	elif t:
		point = t.global_position
	else:
		return true
	var fx := Fx.new()
	fx.id = id
	fx.target = t
	fx.has_target = t != null
	fx.point = point
	fx.tpos = t.global_position if t else point
	fx.start = fx.tpos
	fx.land_pos = point
	fx.prev = fx.tpos
	fx.vis = VIS_TARGET if t else VIS_POINT
	if t:
		var team: Variant = t.get(&"team")
		fx.team = int(team) if team != null else -1
		fx.variant = _variant_of(t)
	match id:
		&"gore_charge": _gore_charge(fx)
		&"gale_swoop": _dive(fx, false)
		&"shrieking_dive": _dive(fx, true)
		&"updraft": _updraft(fx)
		&"pounce": _pounce(fx)
		&"hamstring": _hamstring(fx)
		&"maul": _maul(fx)
		&"rending_roar": _roar(fx)
		&"beast_spawn": _spawn(fx)
	_start(fx)
	return true


## True when `id` is one of this node's effects.
func handles(id: StringName) -> bool:
	return EFFECTS.has(id)


## Number of running effects.
func active_count() -> int:
	return _fx.size()


## Ids of the running effects.
func active_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for fx in _fx:
		out.append(fx.id)
	return out


## Pooled pieces still on screen + bursts / trails still alive (0 once everything has ended).
func live_count() -> int:
	var n := _live_bursts.size()
	for pool: StringName in _all:
		for g: GeometryInstance3D in _all[pool]:
			if g.visible:
				n += 1
	for look: StringName in _trail_all:   # emitting or draining trail emitters
		n += (_trail_all[look] as Array).size() - (_trail_free[look] as Array).size()
	return n


# ---------------------------------------------------------------- the 9 effects

func _gore_charge(fx: Fx) -> void:
	var up := Vector3.UP
	_travel(fx, CHARGE_SPEED, 1.6)
	var hit := fx.dir * 1.3                       # the tusks strike ahead of the body
	# Take-off: hooves dig in.
	_sched(fx, &"dust_kick", 0.0, A_START, up * 0.2, 1.3)
	_disc(fx, A_START, Vector3.ZERO, G_SOOT, _lin(DUST), 0.7, 1.6, 0.3, 0.0, 1.4, 0.0, 0.7)
	# The run: dust + clods behind the beast, the furrow stretching after it.
	_trail(fx, &"charge_dust", A_TARGET, up * 0.15, 0.0, 0.02, true)
	_trail(fx, &"charge_clods", A_TARGET, up * 0.25, 0.0, 0.0, true)
	_furrow(fx, 0.95, _lin(EARTH), 1.0)
	# Impact where it stops.
	_disc(fx, A_LAND, hit, G_SHOCK, _hdr(IMPACT, 1.5), 0.5, 3.1, 0.32, 0.0, 0.5, 0.0, 0.28, true)
	_disc(fx, A_LAND, hit * 0.6, G_SOOT, _lin(DUST), 1.0, 2.5, 0.3, 0.0, 0.0, 0.0, 0.9, true)
	_flare(fx, A_LAND, hit + up * 1.0, _hdr(IMPACT, 2.3), 1.3, 2.7, 0.12, 0.0, 0.28, 0.0, 0.16, 1.0, 6.0, true)
	_sched(fx, &"impact_dust", 0.0, A_LAND, hit + up * 0.3, 1.0, true)
	_sched(fx, &"impact_clods", 0.0, A_LAND, hit + up * 0.3, 1.0, true)
	_sched(fx, &"tusk_sparks", 0.0, A_LAND, hit + up * 0.9, 1.0, true)


## Gale Swoop (storm-blue wind ring) and Shrieking Dive (violet shriek ring).
func _dive(fx: Fx, shriek: bool) -> void:
	var up := Vector3.UP
	_travel(fx, LEAP_SPEED, 1.1)
	var c := fx.dir * 1.3                         # the strike centre: the victim, just past the landing point
	var col := SHRIEK if shriek else STORM
	var hot := SHRIEK_HOT if shriek else STORM_HOT
	# The mark where it will strike, then the streak behind the diving bird.
	var tel := _disc(fx, A_POINT, c, G_SHOCK, _hdr(col, 0.6), 1.4, DIVE_RADIUS, maxf(0.2, fx.est), 0.0, 0.08, 0.1,
			0.12)
	if tel:
		tel.off_rel = true
	_streak(fx, 2.3, 1.2, 6.0, _hdr(col, 0.55 if shriek else 0.8))
	_streak(fx, 2.35, 0.36, 4.5, _hdr(hot, 1.1))
	_disc(fx, A_LAND, c, G_SHOCK, _hdr(hot, 0.75), 0.5, DIVE_RADIUS + 0.6, 0.3, 0.0, 0.45, 0.0, 0.25, true)
	_flare(fx, A_LAND, c + up * 0.9, _hdr(col, 1.2), 1.0, 2.0, 0.15, 0.0, 0.3, 0.0, 0.18, 0.8, 8.0, true)
	_sched(fx, &"gust_dust", 0.0, A_LAND, c + up * 0.2, 1.0, true)
	if shriek:
		_mark(fx, A_LAND, c, M_SHRIEK, _hdr(SHRIEK, 1.0), 0.8, DIVE_RADIUS + 0.4, 0.3, 0.0, 1.0, 0.0, 0.35, 0.0, true)
		for i in 3:
			var on := float(i) * 0.12
			_air(fx, A_LAND, c * 0.4 + up * 2.3, S_RIPPLE, _hdr(SHRIEK, 1.15), 0.8, 4.4, 0.45, on, on + 0.5, 0.0,
					0.25, true)
		_sched(fx, &"shriek_motes", 0.05, A_LAND, c + up * 0.3, 1.0, true)
		_sched(fx, &"dusk_feathers", 0.0, A_LAND, up * 2.4, 1.0, true)
	else:
		_disc(fx, A_LAND, c, G_WIND, _hdr(STORM, 0.95), 1.0, DIVE_RADIUS + 0.3, 0.35, 0.0, 0.95, 0.0, 0.4, true)
		_sched(fx, &"gust_streaks", 0.0, A_LAND, c + up * 0.5, 1.0, true)
		_sched(fx, &"storm_feathers", 0.0, A_LAND, up * 2.4, 1.0, true)


func _updraft(fx: Fx) -> void:
	var up := Vector3.UP
	fx.dur = 1.9
	var dusk := fx.variant == 1
	var col := SHRIEK if dusk else STORM
	var hot := SHRIEK_HOT if dusk else STORM_HOT
	_trail(fx, &"feather_swirl_b" if dusk else &"feather_swirl_a", A_TARGET, up * 0.7, 0.0, 1.1, false)
	_column(fx, A_TARGET, 1.5, 0.8, 6.5, 0.6, _hdr(col, 0.7 if dusk else 0.95), 0.0, 1.7, 0.1, 0.6)
	_disc(fx, A_POINT, Vector3.ZERO, G_WIND, _hdr(col, 1.3), 0.8, 2.5, 0.45, 0.0, 1.3, 0.0, 0.45)
	_disc(fx, A_POINT, Vector3.ZERO, G_SHOCK, _hdr(hot, 1.0), 0.4, 2.2, 0.3, 0.0, 0.4, 0.0, 0.2)
	_sched(fx, &"updraft_dust", 0.0, A_POINT, up * 0.15)
	_flare(fx, A_TARGET, up * 2.6, _hdr(hot, 1.6), 0.8, 2.2, 0.2, 0.0, 0.35, 0.0, 0.2)


func _pounce(fx: Fx) -> void:
	var up := Vector3.UP
	_travel(fx, LEAP_SPEED, 1.9)
	var moon := fx.variant == 1
	var col := MOON if moon else WOLF
	var e := 1.5 if moon else 1.15
	var c := fx.dir * 0.95                        # the victim: just past the landing point
	_sched(fx, &"dust_kick", 0.0, A_START, up * 0.2, 0.8)
	_streak(fx, 0.95, 0.95, 4.5, _hdr(col, 0.55 * e))
	_streak(fx, 1.0, 0.3, 3.5, _hdr(col, 1.1 * e))
	_mark(fx, A_LAND, fx.dir * 0.6, M_CLAWS, _hdr(col, 0.9 * e), 1.35, 1.35, 0.0, 0.0, 0.0, 0.0, 0.7, _yaw(fx.dir), true)
	_disc(fx, A_LAND, c, G_SHOCK, _hdr(col, 0.7), 0.3, 1.7, 0.22, 0.0, 0.35, 0.0, 0.2, true)
	_flare(fx, A_LAND, c + up * 0.8, _hdr(col, 1.3), 0.6, 1.2, 0.1, 0.0, 0.22, 0.0, 0.14, 1.0, 4.0, true)
	_sched(fx, &"pounce_dust", 0.0, A_LAND, c + up * 0.2, 1.0, true)
	_sched(fx, &"claw_sparks", 0.0, A_LAND, c + up * 0.6, 1.0, true)


func _hamstring(fx: Fx) -> void:
	var up := Vector3.UP
	fx.dur = 0.45
	var y := clampf(_h(fx.target) * 0.28, 0.3, 0.7)
	var d := _air(fx, A_TARGET, up * y, S_SLASH, _hdr(BLOOD, 2.2), 0.95, 1.1, 0.1, 0.0, 0.45, 0.0, 0.2)
	_params(d, {&"count": 1.0, &"angle": -0.1 - randf() * 0.35, &"sweep": 0.08,
			&"halo": Color(0.10, 0.01, 0.01, 0.55)})
	_flare(fx, A_TARGET, up * y, _hdr(BLOOD, 1.8), 0.35, 0.7, 0.08, 0.0, 0.18, 0.0, 0.1)
	_sched(fx, &"blood_flecks", 0.02, A_TARGET, up * y)


func _maul(fx: Fx) -> void:
	var up := Vector3.UP
	fx.dur = 0.75
	var h := _h(fx.target)
	var y := clampf(h * 0.55, 0.6, 1.6)
	var size := clampf(h * 1.1 + 0.4, 1.8, 3.0)
	var d := _air(fx, A_TARGET, up * y, S_SLASH, _hdr(CLAW, 2.0), size * 0.9, size, 0.12, 0.0, 0.6, 0.0, 0.3)
	_params(d, {&"count": 3.0, &"angle": -0.6 - randf() * 0.25, &"sweep": 0.11,
			&"halo": Color(0.16, 0.02, 0.02, 0.6)})
	_flare(fx, A_TARGET, up * y, _hdr(BONE, 1.2), 0.6, 1.3, 0.08, 0.0, 0.2, 0.0, 0.12, 1.0, 4.0)
	_disc(fx, A_TARGET, Vector3.ZERO, G_SHOCK, _hdr(ROAR, 0.6), 0.3, 1.6, 0.22, 0.0, 0.4, 0.0, 0.22)
	_sched(fx, &"maul_flecks", 0.04, A_TARGET, up * y)
	_sched(fx, &"claw_sparks", 0.02, A_TARGET, up * y)


func _roar(fx: Fx) -> void:
	var up := Vector3.UP
	fx.dur = 1.4
	var head := up * clampf(_h(fx.target) * 0.8, 1.2, 2.6)
	_disc(fx, A_POINT, Vector3.ZERO, G_SHOCK, _hdr(ROAR, 1.4), 1.0, ROAR_RADIUS, 0.45, 0.0, 0.8, 0.0, 0.35)
	_disc(fx, A_POINT, Vector3.ZERO, G_SHOCK, _hdr(ROAR, 1.0), 0.8, ROAR_RADIUS * 0.72, 0.55, 0.1, 0.9, 0.0, 0.35)
	_mark(fx, A_POINT, Vector3.ZERO, M_CRACKS, _hdr(IMPACT, 1.5), 1.5, ROAR_RADIUS * 0.95, 0.45, 0.0, 0.0, 0.0, 0.6,
			randf() * TAU)
	for i in 3:
		var on := float(i) * 0.13
		_air(fx, A_TARGET, head, S_RIPPLE, _hdr(ROAR, 1.5), 1.2, 6.0, 0.5, on, on + 0.55, 0.0, 0.3)
	_flare(fx, A_TARGET, head, _hdr(ROAR, 2.0), 1.4, 3.0, 0.15, 0.0, 0.35, 0.0, 0.2, 1.0, 8.0)
	_sched(fx, &"roar_dust", 0.0, A_POINT, up * 0.2)
	_sched(fx, &"roar_debris", 0.05, A_POINT, up * 0.1)


func _spawn(fx: Fx) -> void:
	var up := Vector3.UP
	fx.dur = 0.6
	fx.vis = VIS_POINT
	var yaw := randf() * TAU
	var side := Vector3(cos(yaw + 1.3), 0.0, sin(yaw + 1.3)) * 3.0
	_sched(fx, &"flock", 0.0, A_POINT, up * 3.0, 1.0, false, true, yaw)
	_sched(fx, &"flock_small", 0.45, A_POINT, up * 2.6 + side, 1.0, false, true, yaw + 0.4)
	_sched(fx, &"lair_leaves", 0.0, A_POINT, up * 3.2)
	_sched(fx, &"dust_kick", 0.05, A_POINT, up * 0.2, 1.4)


# ---------------------------------------------------------------- effect runtime

## Marks `fx` as a dash / leap toward its point at `speed`; its landing pieces show `after` seconds.
func _travel(fx: Fx, speed: float, after: float) -> void:
	fx.travel = true
	fx.landed = false
	fx.after = after
	fx.dur = NEVER
	if fx.has_target:
		var flat := Vector3(fx.point.x - fx.start.x, 0.0, fx.point.z - fx.start.z)
		fx.est = maxf(MIN_MOTION_TIME, flat.length() / speed)
		if flat.length() > 0.05:
			fx.dir = flat.normalized()
	else:
		fx.est = 0.12   # no beast to follow: the impact plays at `at` right away (dir stays +Z)


func _start(fx: Fx) -> void:
	_fx.append(fx)
	_refresh(fx)
	fx.check_left = CHECK_INTERVAL
	_tick(fx, 0.0)


## Advances one effect. Returns true when it is over.
func _tick(fx: Fx, delta: float) -> bool:
	fx.t += delta
	var live := fx.has_target and _in_tree(fx.target)
	if live:
		fx.tpos = fx.target.global_position
	if not fx.landed:
		_track(fx, delta, live)
	fx.check_left -= delta
	if fx.check_left <= 0.0:
		fx.check_left += CHECK_INTERVAL
		_refresh(fx)
	var ef := 1.0 if fx.end_at < 0.0 else clampf((fx.end_at - fx.t) / END_FADE, 0.0, 1.0)
	for d in fx.pieces:
		_tick_piece(fx, d, ef)
	if fx.bursts_left > 0:
		for b in fx.bursts:
			if b["done"]:
				continue
			var on := float(b["on"])
			if b["rel"]:
				if not fx.landed:
					continue
				on += fx.land_t
			if fx.t < on:
				continue
			b["done"] = true
			fx.bursts_left -= 1
			if (fx.shown or b["always"]) and fx.end_at < 0.0:
				_burst(b["look"], _anchor(fx, b["at"]) + (b["ofs"] as Vector3), b["size"], b["yaw"])
	var trails_busy := _tick_trails(fx)
	if fx.end_at >= 0.0:
		return fx.t >= fx.end_at and not trails_busy
	if not fx.landed:
		return false
	return fx.t >= fx.dur and fx.bursts_left <= 0 and not trails_busy


## Dash / leap tracking: lands when the beast stopped after moving, when the travel time (+ grace) is over, or when
## the beast is gone.
func _track(fx: Fx, delta: float, live: bool) -> void:
	if live:
		var mv := Vector2(fx.tpos.x - fx.prev.x, fx.tpos.z - fx.prev.z).length()
		fx.prev = fx.tpos
		if mv > 0.004:
			fx.moved = true
			fx.still = 0.0
		else:
			fx.still += delta
		var arrived := fx.moved and fx.still >= LAND_STILL and fx.t >= 0.1
		var late := fx.t >= fx.est + (LAND_GRACE if fx.moved else 0.0)
		if arrived or late:
			_land(fx)
	elif fx.has_target or fx.t >= fx.est:
		_land(fx)


func _land(fx: Fx) -> void:
	fx.landed = true
	fx.land_t = fx.t
	fx.land_pos = fx.tpos if fx.has_target else fx.point
	fx.dur = fx.t + fx.after


func _tick_piece(fx: Fx, d: Piece, ef: float) -> void:
	var n := d.n
	if d.on_rel and not fx.landed:
		if n.visible:
			n.visible = false
		return
	var on := d.on + (fx.land_t if d.on_rel else 0.0)
	var off: float
	if d.off > 0.0:
		off = d.off if not d.off_rel else (fx.land_t + d.off if fx.landed else NEVER)
	else:
		off = fx.dur + d.off if fx.landed else NEVER
	var lt := fx.t - on
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
		k = _ease(clampf(lt / d.grow, 0.0, 1.0), d.back)
	var xf: Transform3D
	var radius := 0.0
	match d.span:
		SPAN_GROUND:
			xf = _span_ground(fx, d)
		SPAN_AIR:
			var sa := _span_air(fx, d)
			xf = sa[0]
			f = minf(f, float(sa[1]))
		_:
			var s := d.s0.lerp(d.s1, k)
			radius = s.x
			var b := Basis.from_scale(s) if d.yaw == 0.0 else Basis(Vector3.UP, d.yaw) * Basis.from_scale(s)
			xf = Transform3D(b, _anchor(fx, d.at) + d.o0.lerp(d.ofs, k))
	if not xf.is_equal_approx(n.transform):
		n.transform = xf
	# Only what changed goes to the RenderingServer.
	if absf(f - d.lf) > 0.003:
		d.lf = f
		n.set_instance_shader_parameter(&"fade", f)
	if lt <= 1.05 and d.pool != &"streak" and d.pool != &"column":
		n.set_instance_shader_parameter(&"age", lt)
	if d.is_disc and absf(radius - d.lr) > 0.001:
		d.lr = radius
		n.set_instance_shader_parameter(&"radius", radius)
	var vis := fx.shown and f > 0.002
	if n.visible != vis:
		n.visible = vis


## The furrow: from just behind the take-off to just ahead of the beast (while it runs), flat on the ground.
func _span_ground(fx: Fx, d: Piece) -> Transform3D:
	var a := _anchor(fx, A_START)
	var b := _anchor(fx, A_LAND)
	var seg := Vector3(b.x - a.x, 0.0, b.z - a.z)
	var dir := seg.normalized() if seg.length() > 0.05 else fx.dir
	var a2 := a - dir * 0.3
	var b2 := b + dir * 0.6
	var half := maxf(0.3, Vector3(b2.x - a2.x, 0.0, b2.z - a2.z).length() * 0.5)
	var mid := (a2 + b2) * 0.5
	mid.y = a.y + d.ofs.y
	return Transform3D(Basis(dir * half, Vector3.UP, dir.cross(Vector3.UP).normalized() * d.width), mid)


## The streak: from the beast back along its leap, up to `maxlen`; it shrinks into the beast in 0.22 s on landing.
## Returns [transform, fade factor].
func _span_air(fx: Fx, d: Piece) -> Array:
	var body := _anchor(fx, A_LAND)
	var head := body + Vector3.UP * d.ofs.y
	var length := minf(Vector2(body.x - fx.start.x, body.z - fx.start.z).length(), d.maxlen)
	if fx.landed:
		length *= 1.0 - clampf((fx.t - fx.land_t) / 0.22, 0.0, 1.0)
	var vis := clampf(length / 0.6, 0.0, 1.0)
	length = maxf(length, 0.05)
	var tail := head - fx.dir * length
	var side := fx.dir.cross(Vector3.UP)
	return [Transform3D(Basis(Vector3.UP * d.width, head - tail, side * d.width), (head + tail) * 0.5), vis]


## Trail emitters: start at `on`, follow their anchor, stop at `off` (off_rel: after the landing); then their last
## particles drain. Returns true while one is pending or emitting.
func _tick_trails(fx: Fx) -> bool:
	var busy := false
	for tr in fx.trails:
		var st := int(tr["state"])
		if st >= 2:
			continue
		var stop := fx.end_at >= 0.0
		if bool(tr["off_rel"]):
			stop = stop or (fx.landed and fx.t >= fx.land_t + float(tr["off"]))
		else:
			stop = stop or fx.t >= float(tr["off"])
		if st == 0:
			if stop:
				tr["state"] = 2
				continue
			busy = true
			if fx.t < float(tr["on"]):
				continue
			var free: Array = _trail_free[tr["look"]]
			if free.is_empty():
				tr["state"] = 2   # pool exhausted: skipped
				continue
			var p: GPUParticles3D = free.pop_back()
			tr["p"] = p
			p.transform = Transform3D(Basis.IDENTITY, _anchor(fx, tr["at"]) + (tr["ofs"] as Vector3))
			p.visible = fx.shown
			p.restart()
			p.emitting = true
			tr["state"] = 1
			continue
		var pe: GPUParticles3D = tr["p"]
		if stop:
			pe.emitting = false
			_draining.append({"p": pe, "look": tr["look"], "left": pe.lifetime + 0.1})
			tr["state"] = 2
			continue
		busy = true
		pe.transform = Transform3D(Basis.IDENTITY, _anchor(fx, tr["at"]) + (tr["ofs"] as Vector3))
		if pe.visible != fx.shown:
			pe.visible = fx.shown
	return busy


func _finish(fx: Fx) -> void:
	for d in fx.pieces:
		d.n.visible = false
		d.n.set_instance_shader_parameter(&"fade", 0.0)
		(_free[d.pool] as Array).append(d.n)
	fx.pieces.clear()
	for tr in fx.trails:
		if int(tr["state"]) == 1:
			var p: GPUParticles3D = tr["p"]
			p.emitting = false
			_draining.append({"p": p, "look": tr["look"], "left": p.lifetime + 0.1})
			tr["state"] = 2
	fx.trails.clear()


## Fog / hidden units (4 times per second).
func _refresh(fx: Fx) -> void:
	if fx.vis == VIS_TARGET and fx.has_target and _in_tree(fx.target):
		fx.shown = fx.target.is_visible_in_tree()
	else:
		fx.shown = _fog_ok(fx.team, _anchor(fx, A_LAND))


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
		A_START:
			return fx.start
		A_LAND:
			return fx.land_pos if fx.landed else fx.tpos
	return fx.point


# ---------------------------------------------------------------- piece helpers

func _piece(fx: Fx, pool: StringName, at: int, ofs: Vector3, on: float, off: float, fin: float, fout: float,
		rel: bool = false) -> Piece:
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
	d.on_rel = rel
	d.off_rel = rel
	d.n.set_instance_shader_parameter(&"fade", 0.0)
	d.n.visible = false
	fx.pieces.append(d)
	return d


func _grow(d: Piece, s0: Variant, s1: Variant, time: float, back: bool = false) -> void:
	if d == null:
		return
	d.s0 = s0 if s0 is Vector3 else Vector3.ONE * float(s0)
	d.s1 = s1 if s1 is Vector3 else Vector3.ONE * float(s1)
	d.grow = time
	d.back = back


func _params(d: Piece, params: Dictionary) -> void:
	if d == null:
		return
	for k: StringName in params:
		d.n.set_instance_shader_parameter(k, params[k])


func _ground_y() -> float:
	_layer = (_layer + 1) % 8
	return 0.05 + 0.006 * float(_layer)


## Champion ground ring / soot (champion_ground.gdshader) growing from radius r0 to r1, at anchor + ofs (xz).
func _disc(fx: Fx, at: int, ofs: Vector3, pattern: int, tint: Color, r0: float, r1: float, grow: float, on: float,
		off: float, fin: float, fout: float, rel: bool = false) -> Piece:
	var d := _piece(fx, &"disc", at, Vector3(ofs.x, _ground_y(), ofs.z), on, off, fin, fout, rel)
	_grow(d, Vector3(r0, 1.0, r0), Vector3(r1, 1.0, r1), grow)
	_params(d, {&"pattern": float(pattern), &"tint": tint, &"seed": randf() * 10.0})
	return d


## Beast ground mark (mapfill_beast_ground.gdshader): half size r0 -> r1 metres, local +X turned to `yaw`.
func _mark(fx: Fx, at: int, ofs: Vector3, pattern: int, tint: Color, r0: float, r1: float, grow: float, on: float,
		off: float, fin: float, fout: float, yaw: float = 0.0, rel: bool = false) -> Piece:
	var d := _piece(fx, &"mark", at, Vector3(ofs.x, _ground_y(), ofs.z), on, off, fin, fout, rel)
	_grow(d, Vector3(r0, 1.0, r0), Vector3(r1, 1.0, r1), grow)
	if d:
		d.yaw = yaw
	_params(d, {&"pattern": float(pattern), &"tint": tint, &"seed": randf() * 10.0})
	return d


## The Gore Charge furrow (a span on the ground), `width` = half width in metres; fades out at the effect's end.
func _furrow(fx: Fx, width: float, tint: Color, fout: float) -> Piece:
	var d := _piece(fx, &"mark", A_START, Vector3(0.0, _ground_y(), 0.0), 0.0, 0.0, 0.08, fout)
	if d:
		d.span = SPAN_GROUND
		d.width = width
	_params(d, {&"pattern": float(M_FURROW), &"tint": tint, &"seed": randf() * 10.0})
	return d


## A leap / swoop streak at `height` behind the travelling beast (`width` m wide, at most `maxlen` long).
func _streak(fx: Fx, height: float, width: float, maxlen: float, tint: Color) -> Piece:
	var d := _piece(fx, &"streak", A_LAND, Vector3.UP * height, 0.0, 0.3, 0.06, 0.0)
	if d:
		d.span = SPAN_AIR
		d.width = width
		d.maxlen = maxlen
		d.off_rel = true
	_params(d, {&"tint": tint, &"seed": randf() * 10.0})
	return d


## Camera-facing glow (champion_flare.gdshader) growing from size s0 to s1 metres.
func _flare(fx: Fx, at: int, ofs: Vector3, tint: Color, s0: float, s1: float, grow: float, on: float, off: float,
		fin: float, fout: float, rays: float = 0.0, spikes: float = 4.0, rel: bool = false) -> Piece:
	var d := _piece(fx, &"flare", at, ofs, on, off, fin, fout, rel)
	_grow(d, s0, s1, grow)
	_params(d, {&"tint": tint, &"rays": rays, &"spikes": spikes, &"pulse": 0.0, &"seed": randf() * 10.0,
			&"halo": Color(0, 0, 0, 0)})
	return d


## Camera-facing slash / ripple (mapfill_beast_air.gdshader), size s0 -> s1 metres.
func _air(fx: Fx, at: int, ofs: Vector3, pattern: int, tint: Color, s0: float, s1: float, grow: float, on: float,
		off: float, fin: float, fout: float, rel: bool = false) -> Piece:
	var d := _piece(fx, &"air", at, ofs, on, off, fin, fout, rel)
	_grow(d, s0, s1, grow)
	_params(d, {&"pattern": float(pattern), &"tint": tint, &"seed": randf() * 10.0,
			&"halo": Color(0, 0, 0, 0), &"count": 3.0, &"angle": -0.6, &"sweep": 0.1})
	return d


## Wind column (mapfill_beast_column.gdshader): radius r, height h0 -> h1, standing on its anchor.
func _column(fx: Fx, at: int, r: float, h0: float, h1: float, grow: float, tint: Color, on: float, off: float,
		fin: float, fout: float) -> Piece:
	var d := _piece(fx, &"column", at, Vector3.UP * (h1 * 0.5), on, off, fin, fout)
	_grow(d, Vector3(r, h0, r), Vector3(r, h1, r), grow)
	if d:
		d.o0 = Vector3.UP * (h0 * 0.5)
	_params(d, {&"tint": tint, &"seed": randf() * 10.0})
	return d


func _sched(fx: Fx, look: StringName, on: float, at: int, ofs: Vector3, size: float = 1.0, rel: bool = false,
		always: bool = false, yaw: float = 0.0) -> void:
	fx.bursts.append({"look": look, "on": on, "at": at, "ofs": ofs, "size": size, "done": false, "rel": rel,
			"always": always, "yaw": yaw})
	fx.bursts_left += 1


func _trail(fx: Fx, look: StringName, at: int, ofs: Vector3, on: float, off: float, off_rel: bool) -> void:
	fx.trails.append({"look": look, "at": at, "ofs": ofs, "on": on, "off": off, "off_rel": off_rel, "state": 0,
			"p": null})


func _burst(look: StringName, pos: Vector3, size: float = 1.0, yaw: float = 0.0) -> void:
	var pool: Array = _bursts[look]
	var i: int = _burst_next[look]
	_burst_next[look] = (i + 1) % pool.size()
	var p: GPUParticles3D = pool[i]
	p.transform = Transform3D(Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3.ONE * clampf(size, 0.4, 3.0)), pos)
	p.visible = true
	p.restart()
	for b in _live_bursts:
		if b["p"] == p:
			b["left"] = p.lifetime + 0.1
			return
	_live_bursts.append({"p": p, "left": p.lifetime + 0.1})


func _ease(k: float, back: bool) -> float:
	if back:
		var c1 := 1.70158
		var c3 := c1 + 1.0
		return 1.0 + c3 * pow(k - 1.0, 3.0) + c1 * pow(k - 1.0, 2.0)
	return 1.0 - pow(1.0 - k, 3.0)


func _yaw(dir: Vector3) -> float:
	return atan2(-dir.z, dir.x)   # local +X -> dir


func _in_tree(n: Variant) -> bool:
	return is_instance_valid(n) and (n as Node).is_inside_tree()


func _h(n: Variant) -> float:
	if not is_instance_valid(n):
		return 1.6
	var h: Variant = (n as Object).get(&"body_height")
	return float(h) if h != null else 1.6


## 0 = variant A, 1 = variant B: meta beast_variant (EpicBeasts), else the UnitType id, else a `variant` property.
func _variant_of(n: Node3D) -> int:
	if n.has_meta(&"beast_variant"):
		return int(n.get_meta(&"beast_variant"))
	var ut: Variant = n.get(&"unit_type")
	if ut is Object and is_instance_valid(ut):
		var tid: Variant = (ut as Object).get(&"id")
		if tid != null:
			return 1 if B_TYPES.has(StringName(str(tid))) else 0
	var v: Variant = n.get(&"variant")
	if v is int:
		return int(v)
	return 0


## sRGB colour -> linear HDR (instance uniforms and particle colours are linear).
func _hdr(c: Color, energy: float, alpha: float = 1.0) -> Color:
	var l := c.srgb_to_linear()
	return Color(l.r * energy, l.g * energy, l.b * energy, alpha)


func _lin(c: Color, alpha: float = 1.0) -> Color:
	var l := c.srgb_to_linear()
	return Color(l.r, l.g, l.b, alpha)


# ---------------------------------------------------------------- shared resources (built once)

func _build_shared() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(2.0, 2.0)
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.0
	cyl.height = 1.0
	cyl.radial_segments = 20
	cyl.rings = 3
	cyl.cap_top = false
	cyl.cap_bottom = false
	var meshes := {&"disc": plane, &"mark": plane, &"flare": quad, &"air": quad, &"streak": quad, &"column": cyl}
	var mats := {&"disc": _shader_mat(GROUND_SHADER), &"mark": _shader_mat(MARK_SHADER),
			&"flare": _shader_mat(FLARE_SHADER), &"air": _shader_mat(AIR_SHADER),
			&"streak": _shader_mat(STREAK_SHADER), &"column": _shader_mat(COLUMN_SHADER)}
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
			if pool != &"disc" and pool != &"mark":
				m.extra_cull_margin = 3.0   # billboards / streaks leave their mesh AABB
			if pool == &"air":
				m.sorting_offset = 1.0      # slashes over their glow
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
	for look: StringName in TRAILS:
		var spec: Array = TRAILS[look]
		var arr: Array = []
		for i in int(spec[3]):
			var p := _emitter(look, int(spec[0]), float(spec[1]), spec[2])
			p.one_shot = false
			p.explosiveness = 0.0
			p.randomness = 0.3
			add_child(p)
			arr.append(p)
		_trail_all[look] = arr
		_trail_free[look] = arr.duplicate()


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
	if look == &"flock" or look == &"flock_small":
		p.visibility_aabb = AABB(Vector3(-26.0, -4.0, -26.0), Vector3(52.0, 34.0, 52.0))
	elif BIG_LOOKS.has(look):
		p.visibility_aabb = AABB(Vector3(-9.0, -3.0, -9.0), Vector3(18.0, 12.0, 18.0))
	else:
		p.visibility_aabb = AABB(Vector3(-5.0, -3.0, -5.0), Vector3(10.0, 9.0, 10.0))
	VfxCap.fit(p)   # G-F VFX caps: under the mix / additive caps (docs/art/gf_vfx_caps.md)
	return p


## Draw passes: textured billboard quads (never a bare square: every one has a shape mask and keeps the particle
## scale, Godot 4.7) + velocity-aligned sparks (combat_streak.gdshader).
func _build_passes() -> void:
	_passes[&"add_star"] = _particle_quad(_shape_tex(&"star"), BaseMaterial3D.BLEND_MODE_ADD)
	_passes[&"mix_dot"] = _particle_quad(_shape_tex(&"dot"), BaseMaterial3D.BLEND_MODE_MIX)
	_passes[&"mix_smoke"] = _particle_quad(_shape_tex(&"smoke"), BaseMaterial3D.BLEND_MODE_MIX, true)
	_passes[&"mix_feather"] = _particle_quad(_shape_tex(&"feather"), BaseMaterial3D.BLEND_MODE_MIX)
	_passes[&"mix_leaf"] = _particle_quad(_shape_tex(&"leaf"), BaseMaterial3D.BLEND_MODE_MIX)
	var bird := _particle_quad(_shape_tex(&"bird"), BaseMaterial3D.BLEND_MODE_MIX)
	var bm := bird.material as StandardMaterial3D
	bm.particles_anim_h_frames = 4
	bm.particles_anim_v_frames = 1
	bm.particles_anim_loop = true
	_passes[&"mix_bird"] = bird
	var streak := QuadMesh.new()
	var sm := ShaderMaterial.new()
	sm.shader = SPARK_SHADER
	sm.set_shader_parameter(&"stretch", 4.0)
	streak.material = sm
	_passes[&"streak"] = streak


func _particle_quad(tex: Texture2D, blend: BaseMaterial3D.BlendMode, soft: bool = false) -> QuadMesh:
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
	if soft:
		# Big dust quads cut into the ground: soften the cut (no hard line where they meet it).
		mat.proximity_fade_enabled = true
		mat.proximity_fade_distance = 0.7
	var q := QuadMesh.new()
	q.size = Vector2.ONE   # 1 m: ParticleProcessMaterial scale_min / scale_max are the sizes in metres
	q.material = mat
	return q


## White shape masks (alpha = shape, grey = shading), tinted by the particle colour. Built once per run.
func _shape_tex(kind: StringName) -> ImageTexture:
	if _tex_cache.has(kind):
		return _tex_cache[kind]
	var n := 64
	var frames := 4 if kind == &"bird" else 1
	var img := Image.create_empty(n * frames, n, false, Image.FORMAT_RGBA8)
	# Bird wing poses per frame (elbow y, tip y; -y = up): up, level, down, level.
	var poses: Array[Vector2] = [Vector2(-0.30, -0.64), Vector2(-0.08, -0.10), Vector2(0.14, 0.44),
			Vector2(-0.04, 0.04)]
	for f in frames:
		for y in n:
			for x in n:
				var u := (float(x) + 0.5) / float(n) * 2.0 - 1.0
				var v := (float(y) + 0.5) / float(n) * 2.0 - 1.0   # -1 = top of the quad
				var r := sqrt(u * u + v * v)
				var a := 0.0
				var shade := 1.0
				match kind:
					&"dot":
						a = clampf(1.0 - r, 0.0, 1.0)
						a = a * a * (3.0 - 2.0 * a)
					&"star":
						var core := clampf(1.0 - r / 0.32, 0.0, 1.0)
						var ray := maxf(clampf(1.0 - absf(u) / 0.08, 0.0, 1.0) * clampf(1.0 - absf(v), 0.0, 1.0),
								clampf(1.0 - absf(v) / 0.08, 0.0, 1.0) * clampf(1.0 - absf(u), 0.0, 1.0))
						a = clampf(core * core * 1.2 + ray * ray, 0.0, 1.0) * clampf((1.0 - r) / 0.2, 0.0, 1.0)
					&"smoke":
						var nse := _vn(u * 2.3 + 7.1, v * 2.3 + 3.3) * 0.6 + _vn(u * 5.1 + 1.7, v * 5.1 - 2.2) * 0.4
						a = clampf((1.0 - r) * 1.6 + (nse - 0.5) * 0.9 - 0.2, 0.0, 1.0)
						a = a * a * (3.0 - 2.0 * a) * clampf((1.0 - r) / 0.2, 0.0, 1.0)
						shade = clampf(0.82 + 0.14 * (0.5 - v * 0.5) + (nse - 0.5) * 0.25, 0.0, 1.0)
					&"feather":
						# Tip at the top, quill at the bottom, a slight curve, a pale shaft, barbs.
						var t := (v + 0.9) / 1.8
						var uc := u - 0.1 * (t - 0.5) * (t - 0.5) * 4.0 + 0.05
						if t >= 0.0 and t <= 1.0:
							var w := 0.34 * pow(sin(PI * clampf(t * 0.92 + 0.04, 0.0, 1.0)), 0.7) * (1.0 - 0.4 * t)
							if t > 0.86:
								w = 0.035
							a = clampf((w - absf(uc)) / 0.05, 0.0, 1.0)
							var barbs := 0.07 * sin(t * 42.0 + absf(uc) * 30.0)
							shade = (0.8 if uc > 0.0 else 0.62) + barbs + 0.15 * t
							if absf(uc) < 0.03:
								shade = 1.0
					&"leaf":
						var q := Vector2(u / 0.46, v / 0.9)
						a = clampf((1.0 - q.length()) / 0.12, 0.0, 1.0)
						shade = 0.78 + 0.18 * signf(u) * 0.5 + (0.2 if absf(u) < 0.04 else 0.0)
					&"bird":
						var pose := poses[f]
						var pt := Vector2(u, v)
						for side: float in [-1.0, 1.0]:
							var sh := Vector2(0.07 * side, 0.02)
							var el := Vector2(0.44 * side, pose.x)
							var tip := Vector2(0.94 * side, pose.y)
							a = maxf(a, _stroke(pt, sh, el, 0.13, 0.09))
							a = maxf(a, _stroke(pt, el, tip, 0.09, 0.025))
						var body := Vector2(u / 0.12, (v - 0.08) / 0.26).length()
						a = maxf(a, clampf((1.0 - body) / 0.2, 0.0, 1.0))
						var head := Vector2(u, v + 0.16).length()
						a = maxf(a, clampf((0.085 - head) / 0.03, 0.0, 1.0))
						var tail := _stroke(pt, Vector2(0.0, 0.25), Vector2(0.0, 0.42), 0.05, 0.1)
						a = maxf(a, tail)
						shade = 0.9 + 0.1 * (-v)
				img.set_pixel(f * n + x, y, Color(shade, shade, shade, a))
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_tex_cache[kind] = tex
	return tex


## Coverage of a tapered stroke from a (width wa) to b (width wb).
func _stroke(p: Vector2, a: Vector2, b: Vector2, wa: float, wb: float) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	var dist := (p - (a + ab * t)).length()
	var w := lerpf(wa, wb, t)
	return clampf((w - dist) / 0.035 + 0.5, 0.0, 1.0)


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
	var dust_cols := _lin_all([DUST, Color(0.50, 0.41, 0.28), Color(0.66, 0.57, 0.42)])
	var earth := _lin(EARTH)
	var earth_dark := _lin(Color(0.22, 0.16, 0.10))
	match key:
		&"dust_kick":
			_shape_ring(m, 0.6, 0.05)
			m.direction = Vector3.UP
			m.spread = 70.0
			m.initial_velocity_min = 0.8
			m.initial_velocity_max = 1.6
			m.radial_velocity_min = 1.5
			m.radial_velocity_max = 3.0
			m.damping_min = 2.5
			m.damping_max = 3.5
			m.gravity = Vector3(0, 0.3, 0)
			_spin(m, 40.0)
			_size(m, 0.6, 1.0, &"grow")
			m.color_initial_ramp = _ramp(dust_cols)
			m.color_ramp = _ramp([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.65), Color(1, 1, 1, 0.0)])
		&"impact_dust":
			_shape_ring(m, 0.8, 0.1)
			m.direction = Vector3.UP
			m.spread = 60.0
			m.initial_velocity_min = 1.0
			m.initial_velocity_max = 2.2
			m.radial_velocity_min = 3.0
			m.radial_velocity_max = 5.5
			m.damping_min = 3.5
			m.damping_max = 4.5
			m.gravity = Vector3(0, 0.35, 0)
			_spin(m, 40.0)
			_size(m, 1.0, 1.6, &"grow")
			m.color_initial_ramp = _ramp(dust_cols)
			m.color_ramp = _ramp_at([0.0, 0.12, 0.6, 1.0],
					[Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.78), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0.0)])
		&"impact_clods", &"charge_clods":
			_shape_sphere(m, 0.4 if key == &"impact_clods" else 0.6)
			m.direction = Vector3.UP
			m.spread = 60.0 if key == &"impact_clods" else 55.0
			m.initial_velocity_min = 3.5 if key == &"impact_clods" else 2.5
			m.initial_velocity_max = 6.5 if key == &"impact_clods" else 4.5
			m.gravity = Vector3(0, -14.0, 0)
			_spin(m, 180.0)
			if key == &"impact_clods":
				_size(m, 0.13, 0.22, &"hold")
			else:
				_size(m, 0.1, 0.17, &"hold")
			m.color_initial_ramp = _ramp([earth, earth_dark, _lin(Color(0.42, 0.33, 0.22))])
			m.color_ramp = _ramp_at([0.0, 0.8, 1.0], [Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
		&"tusk_sparks", &"claw_sparks":
			var big := key == &"tusk_sparks"
			_shape_sphere(m, 0.3 if big else 0.25)
			m.direction = Vector3.UP
			m.spread = 80.0 if big else 85.0
			m.initial_velocity_min = 4.0 if big else 3.0
			m.initial_velocity_max = 7.5 if big else 5.5
			m.gravity = Vector3(0, -9.0 if big else -8.0, 0)
			m.damping_min = 3.0 if big else 4.0
			m.damping_max = 5.0 if big else 6.0
			m.particle_flag_align_y = true
			if big:
				_size(m, 0.05, 0.08, &"shrink")
			else:
				_size(m, 0.04, 0.06, &"shrink")
			var hot := _hdr(Color(1.0, 0.95, 0.85), 2.6)
			m.color_ramp = _ramp([hot, _hdr(IMPACT, 1.8), _hdr(IMPACT, 1.0, 0.0)])
		&"gust_streaks":
			_shape_ring(m, 0.9, 0.3)
			m.emission_ring_inner_radius = 0.6
			m.direction = Vector3.UP
			m.spread = 8.0
			m.initial_velocity_min = 0.3
			m.initial_velocity_max = 0.8
			m.radial_velocity_min = 9.0
			m.radial_velocity_max = 13.0
			m.damping_min = 10.0
			m.damping_max = 14.0
			m.gravity = Vector3(0, 0.1, 0)
			m.particle_flag_align_y = true
			_size(m, 0.07, 0.1, &"shrink")
			m.color_ramp = _ramp([_hdr(STORM_HOT, 1.6, 0.9), _hdr(STORM, 1.2, 0.6), _hdr(STORM, 1.0, 0.0)])
		&"gust_dust", &"updraft_dust", &"pounce_dust":
			var r := 1.0 if key == &"gust_dust" else (0.9 if key == &"updraft_dust" else 0.5)
			_shape_ring(m, r, 0.05)
			m.direction = Vector3.UP
			m.spread = 50.0 if key != &"pounce_dust" else 60.0
			m.initial_velocity_min = 0.4 if key != &"pounce_dust" else 0.6
			m.initial_velocity_max = 0.9 if key != &"pounce_dust" else 1.3
			m.radial_velocity_min = 4.0 if key != &"pounce_dust" else 2.0
			m.radial_velocity_max = 6.5 if key != &"pounce_dust" else 3.5
			m.damping_min = 4.0 if key != &"pounce_dust" else 3.0
			m.damping_max = 5.0 if key != &"pounce_dust" else 4.0
			m.gravity = Vector3(0, 0.2, 0)
			_spin(m, 40.0)
			if key == &"pounce_dust":
				_size(m, 0.5, 0.85, &"grow")
			else:
				_size(m, 0.7, 1.1, &"grow")
			m.color_initial_ramp = _ramp(_lin_all([Color(0.66, 0.58, 0.44), DUST, Color(0.72, 0.66, 0.54)]))
			m.color_ramp = _ramp([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.0)])
		&"storm_feathers", &"dusk_feathers":
			_shape_sphere(m, 0.9)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 0.8
			m.initial_velocity_max = 2.0
			m.gravity = Vector3(0, -1.4, 0)
			m.damping_min = 1.0
			m.damping_max = 1.6
			_spin(m, 220.0)
			_size(m, 0.3, 0.42, &"hold")
			m.color_initial_ramp = _ramp(_feather_cols(key == &"dusk_feathers"))
			m.color_ramp = _ramp([Color(1, 1, 1, 0.0), Color(1, 1, 1, 1.0), Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.0)])
		&"feather_swirl_a", &"feather_swirl_b":
			# A helix: ring emission, climbing (gravity up = the swirl axis), tangential push, pulled inward.
			_shape_ring(m, 1.2, 0.4)
			m.emission_ring_inner_radius = 0.9
			m.direction = Vector3.UP
			m.spread = 12.0
			m.initial_velocity_min = 2.2
			m.initial_velocity_max = 3.2
			m.gravity = Vector3(0, 1.0, 0)
			m.tangential_accel_min = 10.0
			m.tangential_accel_max = 14.0
			m.radial_accel_min = -3.0
			m.radial_accel_max = -1.5
			m.damping_min = 1.2
			m.damping_max = 1.8
			_spin(m, 300.0)
			_size(m, 0.3, 0.45, &"hold")
			m.color_initial_ramp = _ramp(_feather_cols(key == &"feather_swirl_b"))
			m.color_ramp = _ramp([Color(1, 1, 1, 0.0), Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.0)])
		&"shriek_motes":
			_shape_disc(m, 2.2)
			m.direction = Vector3.UP
			m.spread = 12.0
			m.initial_velocity_min = 1.4
			m.initial_velocity_max = 2.4
			m.damping_min = 1.2
			m.damping_max = 1.8
			_size(m, 0.16, 0.26, &"grow")
			m.color_ramp = _ramp([_hdr(SHRIEK_HOT, 2.6, 0.0), _hdr(SHRIEK_HOT, 2.6), _hdr(SHRIEK, 2.2),
					_hdr(SHRIEK, 1.2, 0.0)])
		&"blood_flecks", &"maul_flecks":
			var small := key == &"blood_flecks"
			_shape_sphere(m, 0.12 if small else 0.3)
			m.direction = Vector3.UP
			m.spread = 70.0 if small else 75.0
			m.initial_velocity_min = 1.4 if small else 2.5
			m.initial_velocity_max = 2.8 if small else 4.5
			m.gravity = Vector3(0, -12.0, 0)
			if small:
				_size(m, 0.06, 0.09, &"hold")
			else:
				_size(m, 0.08, 0.13, &"hold")
			m.color_initial_ramp = _ramp(_lin_all([Color(0.55, 0.06, 0.04), Color(0.42, 0.05, 0.04),
					Color(0.36, 0.22, 0.13) if not small else Color(0.6, 0.1, 0.06)]))
			m.color_ramp = _ramp_at([0.0, 0.75, 1.0], [Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
		&"roar_dust":
			_shape_ring(m, 1.4, 0.1)
			m.emission_ring_inner_radius = 1.1
			m.direction = Vector3.UP
			m.spread = 30.0
			m.initial_velocity_min = 0.5
			m.initial_velocity_max = 1.2
			m.radial_velocity_min = 7.5
			m.radial_velocity_max = 9.5
			m.damping_min = 6.5
			m.damping_max = 7.5
			m.gravity = Vector3(0, 0.2, 0)
			_spin(m, 40.0)
			_size(m, 1.0, 1.5, &"grow")
			m.color_initial_ramp = _ramp(dust_cols)
			m.color_ramp = _ramp_at([0.0, 0.1, 0.6, 1.0],
					[Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.7), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0.0)])
		&"roar_debris":
			_shape_disc(m, 5.2)
			m.direction = Vector3.UP
			m.spread = 15.0
			m.initial_velocity_min = 2.0
			m.initial_velocity_max = 3.5
			m.gravity = Vector3(0, -12.0, 0)
			_spin(m, 180.0)
			_size(m, 0.1, 0.17, &"hold")
			m.color_initial_ramp = _ramp([earth, earth_dark, _lin(Color(0.5, 0.46, 0.4))])
			m.color_ramp = _ramp_at([0.0, 0.8, 1.0], [Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
		&"flock", &"flock_small":
			# Birds burst up from the trees over the lair and fly off together (the emitter yaw picks the heading).
			_shape_sphere(m, 2.5 if key == &"flock" else 1.6)
			m.emission_shape_scale = Vector3(1.0, 0.35, 1.0)
			m.direction = Vector3(0.55, 1.0, 0.15)
			m.spread = 22.0
			m.initial_velocity_min = 3.4
			m.initial_velocity_max = 5.0
			m.gravity = Vector3(0, -0.5, 0)
			m.damping_min = 0.1
			m.damping_max = 0.3
			m.anim_speed_min = 11.0
			m.anim_speed_max = 15.0
			m.anim_offset_min = 0.0
			m.anim_offset_max = 1.0
			_size(m, 0.95, 1.35, &"hold")
			var bird := _lin(BIRD)
			m.color_initial_ramp = _ramp([bird, _lin(Color(0.16, 0.14, 0.14)), _lin(Color(0.07, 0.07, 0.09))])
			m.color_ramp = _ramp_at([0.0, 0.05, 0.82, 1.0],
					[Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.95), Color(1, 1, 1, 0.95), Color(1, 1, 1, 0.0)])
		&"lair_leaves":
			_shape_sphere(m, 2.2)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 0.6
			m.initial_velocity_max = 1.6
			m.gravity = Vector3(0, -1.6, 0)
			m.damping_min = 0.6
			m.damping_max = 1.0
			_spin(m, 200.0)
			_size(m, 0.16, 0.24, &"hold")
			m.color_initial_ramp = _ramp(_lin_all([Color(0.36, 0.50, 0.20), Color(0.52, 0.56, 0.22),
					Color(0.55, 0.40, 0.18)]))
			m.color_ramp = _ramp([Color(1, 1, 1, 0.0), Color(1, 1, 1, 1.0), Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.0)])
		&"charge_dust":
			_shape_sphere(m, 0.6)
			m.emission_shape_scale = Vector3(1.0, 0.3, 1.0)
			m.direction = Vector3.UP
			m.spread = 70.0
			m.initial_velocity_min = 0.5
			m.initial_velocity_max = 1.3
			m.damping_min = 1.5
			m.damping_max = 2.2
			m.gravity = Vector3(0, 0.35, 0)
			_spin(m, 40.0)
			_size(m, 0.8, 1.3, &"grow")
			m.color_initial_ramp = _ramp(dust_cols)
			m.color_ramp = _ramp_at([0.0, 0.15, 0.6, 1.0],
					[Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.7), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0.0)])
	_pmats[key] = m
	return m


func _feather_cols(dusk: bool) -> Array:
	if dusk:
		return _lin_all([Color(0.14, 0.11, 0.20), Color(0.24, 0.15, 0.36), Color(0.10, 0.08, 0.13)])
	return _lin_all([Color(0.72, 0.80, 0.90), Color(0.52, 0.62, 0.78), Color(0.88, 0.92, 0.97)])


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


func _shape_disc(m: ParticleProcessMaterial, r: float) -> void:
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	m.emission_ring_axis = Vector3.UP
	m.emission_ring_radius = r
	m.emission_ring_inner_radius = 0.0
	m.emission_ring_height = 0.1


func _shape_sphere(m: ParticleProcessMaterial, r: float) -> void:
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = r


## Particle sizes in metres + a scale curve: shrink (sparks), grow (dust, motes), hold (clods, feathers, birds).
func _size(m: ParticleProcessMaterial, lo: float, hi: float, kind: StringName) -> void:
	m.scale_min = lo
	m.scale_max = hi
	match kind:
		&"grow":
			m.scale_curve = _curve([Vector2(0.0, 0.3), Vector2(0.3, 1.0), Vector2(1.0, 0.3)])
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


func _lin_all(colors: Array) -> Array:
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
