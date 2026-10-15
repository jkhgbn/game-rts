class_name CavalryVfx
extends Node3D
## Cavalry effects (task 13.V20, docs/design/cavalry-mounts.md 3.2 / 5.2 / 6.2 / 10). Draw-only: never touches gameplay.
##
## API (group "cavalry_vfx"; callers: get_tree().get_first_node_in_group(&"cavalry_vfx").play(id, at, target)):
##   play(id: StringName, at: Variant, target: Variant = null) -> bool   true when `id` is a cavalry effect (handled,
##       even if the fog hides it, a pool is full or a repeat was merged), false for any other id (nothing happens).
##   handles(id) -> bool · active_count() / active_ids() / live_count() / last_fx(id) (tests) · rider_count() ·
##   lines_emitting(unit) -> bool (tests)
## `target` is the unit the effect belongs to (a Unit, its model, or any Node3D with `team`); `at` is a world point
## (Vector3), a Node3D (its position, followed live where it matters) or null.
## Ids:
##   charge          at = the struck unit (or the hit point), target = the charging unit. Call it on the charge hit,
##                   together with the mount's play_charge(): a wind streak (the last 5 m of the run) trails into the
##                   rider at once; with the model's strike frame (0.10 s) a kingdom-coloured shock ring + flash
##                   burst at the hit, sparks fly on along the charge, a dust ring and clods kick up. Titans
##                   (Nightmare Knight: is_titan() or tag "titan") get a bigger, higher version.
##   lifesteal       at = the victim (followed), target = the drainer (Gloam Rider 20 %, Nightmare Knight 30 %). A dark
##                   rip flashes on the victim, 3 soul wisps (4 for a titan) arc from it into the rider's chest (live
##                   end points, ~0.45 s), an absorb glow + rising motes on arrival. At most one per drainer per
##                   0.25 s, 12 at once.
##   mount           at = the unit (or its position), target = the unit. Plays with play_mount(): a dense dust puff
##                   around the mount body at t = 0 (it hides the rider's hop-on start INSIDE the mount: the kit's
##                   hop begins on the rider's own origin), a small puff where the rider pushes off the left flank,
##                   kingdom glints, a dust ring + a faint kingdom ring on the ground.
##   dismount        same arguments, call with play_dismount(): the landing puff on the left flank at 0.26 s and the
##                   big body puff peaking at 0.3 s (CharacterModel.MOUNT_HOP_LEN), when the mount model is removed.
##   thrown          same arguments, call with play_thrown(): a jolt puff at the saddle, the tumble's skid dust + clods
##                   where the rider lands (0.3 s, both flanks: the kit picks the side), the mount puff at 0.45 s
##                   (the rider is unseated at 0.5 s, CharacterModel.THROWN_LEN). `at` may be the landing point.
##   speed_lines     at = ignored, target = the riding unit. Starts a rider tracker: pale wind lines stream off the
##                   rider and hoof dust kicks up while it moves >= 3 m/s, is visible and < 45 m from the camera.
##                   It stops by itself when the unit dies / leaves, or stops riding (its "MountRider" child's
##                   is_riding() or its is_mounted() turns false). Calling it again for the same unit does nothing.
##   speed_lines_off target = the unit: stops its tracker at once (the last lines drain).
## Kingdom colour: the unit's `kingdom` (wizards), else unit_type.faction, else meta "cavalry_vfx_kingdom", else neutral
## gold (champions' Roan Courser).
##
## GLUE (the lead adds the node, 13.L2). ONE Node3D named "CavalryVfx" with this script in scenes/main.tscn and
## scenes/skirmish.tscn (next to TitanVfx / UnitVfx; missions without cavalry can keep it, it costs nothing idle).
## Callers (13.C1 / 13.C4 / 13.C7, through the group, never a static type):
##   Unit charge hit (signal charged(unit, target))       play(&"charge", target, self)
##   Unit._on_attack_hit when lifesteal heals and the unit is mounted (Gloam Rider, Knight)
##                                                        play(&"lifesteal", target, self)
##   MountRider.mount() completes (with rider.play_mount())   play(&"mount", unit, unit) then play(&"speed_lines", unit, unit)
##   MountRider.dismount(false) (with play_dismount())    play(&"dismount", unit, unit)
##   MountRider.dismount(true)  (with play_thrown())      play(&"thrown", unit, unit)
##   (the speed-line tracker stops by itself when riding ends; speed_lines_off is there for other callers)
## Fog: effects with a unit follow its `is_visible_in_tree()` (the fog hides enemy units); point effects check
## FogOfWar.is_visible for the other teams, 4 times per second.
## Budget: everything is built at _ready and pooled (mesh pools, stream emitters, one-shot bursts): no node, material or
## mesh is created after _ready. 0 lights, no shadows, no own shader: reused read-only mapfill_beast_streak (streaks,
## wisp tails), champion_ground (shock / dust rings), champion_flare (flashes, wisps), combat_streak (sparks, wind
## lines); looks set with instance uniforms. Every particle quad has a shape mask and billboard_keep_scale.
## Per charge: 2 streaks, 2 rings, 1 flare, 3 bursts; per lifesteal: 1 + 3-4 flares, 3-4 streaks, 1 burst; per puff:
## 2 rings, 2-4 bursts; per moving rider near the camera: 2 stream emitters.

const GROUP := &"cavalry_vfx"
const EFFECTS: Array[StringName] = [&"charge", &"lifesteal", &"mount", &"dismount", &"thrown", &"speed_lines",
		&"speed_lines_off"]
const KINGDOMS: Array[StringName] = [&"fire", &"shadow", &"ice", &"nature", &"neutral"]

# Numbers from the specs / the kit.
const HOP_LEN := 0.3              # CharacterModel.MOUNT_HOP_LEN (hop-on / hop-off)
const THROWN_LEN := 0.5           # CharacterModel.THROWN_LEN
const STREAK_BACK := 5.0          # cm. 3.2: a charge follows a >= 5 m run
const CHARGE_STRIKE := 0.10       # MountModel.play_charge strike frame (call it with the charge hit)
const LINES_RANGE := 45.0         # rider speed lines only near the camera
const LINES_MIN_SPEED := 3.0      # m/s (walking heroes are slower, riding ones 6-7.5)
const DRAIN_GAP := 0.25           # one lifesteal per drainer per 0.25 s
const MAX_DRAINS := 12
const REPEAT_GAP := 0.12          # the same id for the same unit within this = one effect
const CHECK_INTERVAL := 0.25
const W_ROLES: Array[StringName] = [&"w0", &"w1", &"w2", &"w3"]   # lifesteal wisp heads / tails
const T_ROLES: Array[StringName] = [&"t0", &"t1", &"t2", &"t3"]
const FOG_RESCAN := 1.0

enum { K_CHARGE, K_DRAIN, K_PUFF }
enum { R_SHOCK = 0, R_SOOT = 5 }  # champion_ground.gdshader patterns

## Mesh pools: pool -> size.
const MESH_POOLS := {&"streak": 60, &"ring": 24, &"flare": 72}
## Stream emitters (riders): look -> [amount, lifetime, draw pass, pool size].
const STREAMS := {
	&"speed_lines": [26, 0.36, &"line", 8],
	&"hoof_dust": [14, 0.8, &"mix_puff", 8],
}
## One-shot bursts: look -> [amount, lifetime, draw pass, pool size, explosiveness, per kingdom].
const BURSTS := {
	&"charge_dust": [16, 1.1, &"mix_puff", 4, 0.95, false],
	&"charge_clods": [10, 0.8, &"mix_dot", 5, 1.0, false],
	&"charge_sparks": [18, 0.55, &"streak", 2, 0.95, true],
	&"drain_motes": [10, 0.8, &"add_dot", 3, 0.8, true],
	&"mount_puff": [34, 1.05, &"mix_puff_hard", 4, 1.0, false],
	&"mount_glints": [12, 0.8, &"add_star", 2, 0.85, true],
	&"hop_puff": [8, 0.7, &"mix_puff", 4, 0.95, false],
	&"thrown_dust": [22, 1.2, &"mix_puff", 3, 0.95, false],
}
## Emitters whose particles travel far (bigger visibility box).
const BIG_LOOKS: Array[StringName] = [&"charge_dust", &"mount_puff", &"thrown_dust", &"speed_lines"]

const STREAK_SHADER := preload("res://art/vfx/mapfill_beast_streak.gdshader")
const RING_SHADER := preload("res://art/vfx/champion_ground.gdshader")
const FLARE_SHADER := preload("res://art/vfx/champion_flare.gdshader")
const SPARK_SHADER := preload("res://art/vfx/combat_streak.gdshader")

# Palette (sRGB; art-keep 0.2 glow column + a hot core each; neutral = the champions' warm gold).
const GLOW := {
	&"fire": Color(1.0, 0.55, 0.15), &"shadow": Color(0.70, 0.30, 1.00), &"ice": Color(0.75, 0.92, 1.0),
	&"nature": Color(0.75, 1.0, 0.40), &"neutral": Color(1.0, 0.82, 0.5),
}
const HOT := {
	&"fire": Color(1.0, 0.93, 0.62), &"shadow": Color(0.93, 0.78, 1.0), &"ice": Color(0.95, 0.99, 1.0),
	&"nature": Color(0.95, 1.0, 0.78), &"neutral": Color(1.0, 0.97, 0.85),
}
## Dark halo behind the drain wisps (the Shadow drain reads as torn-out soul, not a heal).
const DRAIN_HALO := {
	&"fire": Color(0.1, 0.03, 0.0), &"shadow": Color(0.05, 0.0, 0.09), &"ice": Color(0.02, 0.05, 0.1),
	&"nature": Color(0.02, 0.07, 0.0), &"neutral": Color(0.08, 0.05, 0.0),
}
const DUST := Color(0.66, 0.58, 0.46)
const DUST_DARK := Color(0.52, 0.45, 0.35)
const DUST_LIGHT := Color(0.78, 0.72, 0.6)
const EARTH := Color(0.3, 0.22, 0.15)
const WIND := Color(0.9, 0.95, 1.0)

## Shape masks shared by every instance (built once per run).
static var _tex_cache: Dictionary = {}


## One running effect.
class Fx:
	extends RefCounted
	var id: StringName
	var kind := 0
	var t := 0.0
	var dur := 1.0
	var unit: Node3D              # the rider / drainer / charger (visibility, team, kingdom)
	var other: Node3D             # the victim (lifesteal) or struck unit (charge), followed live
	var team := -1
	var follow := false           # visibility follows `unit`, else the fog at `point`
	var shown := true
	var check_left := 0.0
	var kingdom := &"neutral"
	var big := false              # a titan (Nightmare Knight)
	var point := Vector3.ZERO     # the hit / puff centre
	var dir := Vector3(0.0, 0.0, 1.0)
	var basis := Basis.IDENTITY   # the unit's facing (puffs)
	var from := Vector3.ZERO      # charge: streak head (charger chest) / lifesteal: the victim chest
	var to := Vector3.ZERO        # lifesteal: the drainer chest
	var chest_to := 1.7
	var chest_from := 1.0
	var wisps: Array[Dictionary] = []
	var arrived := -1.0           # lifesteal: time the first wisp arrived
	var nodes: Dictionary = {}    # role -> GeometryInstance3D
	var pools: Dictionary = {}    # role -> pool
	var anchors: Dictionary = {}  # anchor -> Transform3D (bursts)
	var bursts: Array[Dictionary] = []
	var bursts_left := 0


## A riding unit's speed-line tracker (the emitters are taken only while it is near, visible and fast).
class Rider:
	extends RefCounted
	var unit: Node3D
	var lines: GPUParticles3D
	var dust: GPUParticles3D
	var acc := 0.0
	var prev := Vector3.ZERO
	var has_prev := false
	var speed := 0.0
	var dir := Vector3(0.0, 0.0, 1.0)
	var last := Vector3.ZERO
	var near := false
	var ok := true
	var check_left := 0.0


var _fx: Array[Fx] = []
var _riders: Array[Rider] = []
var _free: Dictionary = {}          # pool -> Array[GeometryInstance3D]
var _all: Dictionary = {}           # pool -> Array[GeometryInstance3D]
var _sent: Dictionary = {}          # node -> {uniform: last float sent}
var _stream_all: Dictionary = {}    # look -> Array[GPUParticles3D]
var _stream_free: Dictionary = {}
var _draining: Array[Dictionary] = []      # {p, look, left}
var _bursts: Dictionary = {}        # look key -> Array[GPUParticles3D]
var _burst_next: Dictionary = {}
var _live_bursts: Array[Dictionary] = []   # {p, left}
var _pmats: Dictionary = {}
var _passes: Dictionary = {}
var _last_play: Dictionary = {}     # "id:instance" -> clock
var _fog: Node
var _fog_left := 0.0
var _cam_left := 0.0
var _cam_pos := Vector3.ZERO
var _has_cam := false
var _clock := 0.0
var _prune_left := 5.0
var _layer := 0
var _built := false


func _ready() -> void:
	add_to_group(GROUP)
	top_level = true                  # effects are placed in world space
	global_transform = Transform3D.IDENTITY
	_build_shared()
	_built = true


func _process(delta: float) -> void:
	_clock += delta
	_fog_left -= delta
	if _fog_left <= 0.0:
		_fog_left = FOG_RESCAN
		_fog = get_tree().get_first_node_in_group(&"fog")
	_cam_left -= delta
	if _cam_left <= 0.0:
		_cam_left = CHECK_INTERVAL
		var cam := get_viewport().get_camera_3d()
		_has_cam = cam != null
		if cam:
			_cam_pos = cam.global_position
	_prune_left -= delta
	if _prune_left <= 0.0:
		_prune_left = 5.0
		for k: String in _last_play.keys():
			if _clock - float(_last_play[k]) > 2.0:
				_last_play.erase(k)
	for i in range(_fx.size() - 1, -1, -1):
		var fx := _fx[i]
		if _tick(fx, delta):
			_finish(fx)
			_fx.remove_at(i)
	_tick_riders(delta)
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
			(_stream_free[d["look"]] as Array).append(p)
			_draining.remove_at(i)


# ================================================================ public API

## Plays cavalry effect `id` (see the header). Returns true when `id` is a cavalry effect (handled), false otherwise.
func play(id: StringName, at: Variant, target: Variant = null) -> bool:
	if not EFFECTS.has(id):
		return false
	if not _built or not is_inside_tree():
		return true
	var t: Node3D = null
	if typeof(target) == TYPE_OBJECT and is_instance_valid(target) and target is Node3D \
			and (target as Node3D).is_inside_tree():
		t = target as Node3D
	var unit := _unit_of(t)
	match id:
		&"speed_lines":
			if unit:
				_ensure_rider(unit)
			return true
		&"speed_lines_off":
			if unit:
				_stop_rider(unit)
			return true
	# The same effect for the same unit twice in a row (two callers, one event) = one effect.
	if unit:
		var key := "%s:%d" % [id, unit.get_instance_id()]
		if _clock - float(_last_play.get(key, -99.0)) < REPEAT_GAP:
			return true
		_last_play[key] = _clock
	match id:
		&"charge":
			_start_charge(at, unit)
		&"lifesteal":
			_start_drain(at, unit)
		&"mount", &"dismount", &"thrown":
			_start_puff(id, at, unit)
	return true


## True when `id` is one of this node's effects.
func handles(id: StringName) -> bool:
	return EFFECTS.has(id)


## Number of running effects (rider trackers not counted).
func active_count() -> int:
	return _fx.size()


## Ids of the running effects.
func active_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for fx in _fx:
		out.append(fx.id)
	return out


## Pooled meshes on screen + bursts alive + stream emitters taken (running or draining). 0 when idle.
func live_count() -> int:
	var n := _live_bursts.size()
	for pool: StringName in _all:
		for g: GeometryInstance3D in _all[pool]:
			if g.visible:
				n += 1
	for look: StringName in _stream_all:
		n += (_stream_all[look] as Array).size() - (_stream_free[look] as Array).size()
	return n


## The running effect of `id` started last (tests / previews), or null.
func last_fx(id: StringName) -> Fx:
	for i in range(_fx.size() - 1, -1, -1):
		if _fx[i].id == id:
			return _fx[i]
	return null


## Number of rider trackers (speed_lines).
func rider_count() -> int:
	return _riders.size()


## True while `unit`'s speed lines emit (tests).
func lines_emitting(unit: Node3D) -> bool:
	for r in _riders:
		if r.unit == unit:
			return r.lines != null and r.lines.emitting
	return false


# ================================================================ charge

func _start_charge(at: Variant, unit: Node3D) -> void:
	var fx := Fx.new()
	fx.kind = K_CHARGE
	fx.id = &"charge"
	fx.unit = unit
	fx.team = _team_of(unit)
	fx.follow = unit != null
	fx.kingdom = _kingdom_of(unit)
	fx.big = _is_big(unit)
	if typeof(at) == TYPE_OBJECT and _alive_node(at):
		fx.other = at as Node3D
	var src: Variant = unit.global_position if unit else null
	var hit: Variant = _point_of(at)
	if hit == null:
		if src == null:
			return
		hit = (src as Vector3) + _flat(unit.global_transform.basis.z) * 1.6
	if src == null:
		src = (hit as Vector3) - Vector3(0.0, 0.0, 1.6)
	var d: Vector3 = (hit as Vector3) - (src as Vector3)
	d.y = 0.0
	fx.dir = d.normalized() if d.length() > 0.1 else (_flat(unit.global_transform.basis.z) if unit else Vector3.FORWARD)
	fx.point = Vector3((hit as Vector3).x, (src as Vector3).y, (hit as Vector3).z)
	fx.chest_to = 1.45 if fx.big else 1.05
	fx.from = (src as Vector3) + fx.dir * (1.0 if fx.big else 0.75) + Vector3.UP * fx.chest_to
	fx.dur = 1.4
	var k := fx.kingdom
	var seed := randf() * 10.0
	var outer := _take(fx, &"streak", &"streak")
	_params(outer, {&"tint": _hdr(GLOW[k], 0.75), &"seed": seed, &"fade": 0.0})
	var core := _take(fx, &"core", &"streak")
	_params(core, {&"tint": _hdr(HOT[k], 1.05), &"seed": seed + 2.7, &"fade": 0.0})
	var gy := _ground_y()
	var shock := _take(fx, &"shock", &"ring")
	if shock:
		shock.transform = Transform3D(Basis.IDENTITY, fx.point + Vector3.UP * gy)
		_params(shock, {&"pattern": float(R_SHOCK), &"seed": seed, &"tint": _hdr(GLOW[k], 1.7), &"age": 0.0})
	var dust := _take(fx, &"dust_ring", &"ring")
	if dust:
		dust.transform = Transform3D(Basis.IDENTITY, fx.point + Vector3.UP * (gy - 0.004))
		_params(dust, {&"pattern": float(R_SOOT), &"seed": seed + 1.0, &"tint": _lin(DUST_DARK)})
	var flash := _take(fx, &"flash", &"flare")
	_params(flash, {&"tint": _hdr(HOT[k], 1.4), &"rays": 0.7, &"spikes": 6.0, &"pulse": 0.0, &"seed": seed,
			&"halo": Color(0, 0, 0, 0)})
	var bz := _basis_z(fx.dir)
	fx.anchors[&"hit"] = Transform3D(bz, fx.point + Vector3.UP * (fx.chest_to - 0.1))
	fx.anchors[&"ground"] = Transform3D(bz, fx.point + Vector3.UP * 0.35)
	fx.anchors[&"low"] = Transform3D(bz, fx.point + Vector3.UP * 0.2)
	_sched(fx, _tinted(&"charge_sparks", k), CHARGE_STRIKE, &"hit")
	_sched(fx, &"charge_dust", CHARGE_STRIKE, &"ground")
	_sched(fx, &"charge_clods", CHARGE_STRIKE + 0.02, &"low")
	_start(fx)


func _tick_charge(fx: Fx) -> void:
	var t := fx.t
	var sc := 1.35 if fx.big else 1.0
	# The streak: the head rides the charger's chest, the tail is the run behind it; it snaps out to 5 m at the hit
	# and is swallowed by the rider in 0.45 s.
	# Each piece is only worked on during its own window (then hidden once): a charge costs little after 0.5 s.
	if t < 0.5:
		var head := fx.from
		if _alive_node(fx.unit):
			head = fx.unit.global_position + fx.dir * (1.0 if fx.big else 0.75) + Vector3.UP * fx.chest_to
		var grow := _ease_out(clampf(t / 0.05, 0.0, 1.0))
		var run := STREAK_BACK * grow * (1.0 - smoothstep(0.12, 0.5, t))
		var sf := 1.0 - smoothstep(0.28, 0.5, t)
		_place_streak(fx.nodes.get(&"streak"), head, head - fx.dir * run, 1.25 * sc, sf, fx.shown)
		_place_streak(fx.nodes.get(&"core"), head + Vector3.UP * 0.02, head - fx.dir * run * 0.8, 0.38 * sc, sf,
				fx.shown)
	else:
		_hide_roles(fx, [&"streak", &"core"])
	# The impact lands with the mount's strike frame (MountModel.play_charge: 0.10 s after the call).
	t -= CHARGE_STRIKE
	if t < 0.0:
		_hide_roles(fx, [&"shock", &"dust_ring", &"flash"])
		return
	var shock: GeometryInstance3D = fx.nodes.get(&"shock")
	if shock and t >= 0.5:
		_vis(shock, false)
	elif shock:
		var r := lerpf(0.5, 2.7 * sc, _ease_out(clampf(t / 0.35, 0.0, 1.0)))
		var f := clampf(t / 0.03, 0.0, 1.0) * (1.0 - smoothstep(0.15, 0.48, t))
		_xf(shock, Transform3D(Basis.from_scale(Vector3(r, 1.0, r)), shock.transform.origin))
		_uf(shock, &"radius", r)
		_uf(shock, &"fade", f)
		_uf(shock, &"age", minf(t, 1.05))
		_vis(shock, fx.shown and f > 0.002)
	var dust: GeometryInstance3D = fx.nodes.get(&"dust_ring")
	if dust:
		var r2 := lerpf(0.9, 2.3 * sc, _ease_out(clampf(t / 0.9, 0.0, 1.0)))
		var f2 := clampf(t / 0.08, 0.0, 1.0) * 0.8 * (1.0 - smoothstep(0.7, 1.35, t))
		_xf(dust, Transform3D(Basis.from_scale(Vector3(r2, 1.0, r2)), dust.transform.origin))
		_uf(dust, &"radius", r2)
		_uf(dust, &"fade", f2)
		_vis(dust, fx.shown and f2 > 0.002)
	var flash: GeometryInstance3D = fx.nodes.get(&"flash")
	if flash and t >= 0.25:
		_vis(flash, false)
	elif flash:
		var s := lerpf(1.2, 2.5, _ease_out(clampf(t / 0.08, 0.0, 1.0))) * sc
		var f3 := 1.0 - smoothstep(0.05, 0.24, t)
		_xf(flash, Transform3D(Basis.from_scale(Vector3.ONE * s), fx.point + Vector3.UP * fx.chest_to))
		_uf(flash, &"fade", f3)
		_vis(flash, fx.shown and f3 > 0.002)


func _hide_roles(fx: Fx, roles: Array) -> void:
	for role: StringName in roles:
		var n: GeometryInstance3D = fx.nodes.get(role)
		if n:
			_vis(n, false)


func _place_streak(n: GeometryInstance3D, head: Vector3, tail: Vector3, width: float, fade: float,
		shown: bool) -> void:
	if n == null:
		return
	var axis := head - tail
	if axis.length() < 0.05 or fade <= 0.002 or not shown:
		_vis(n, false)
		return
	var side := axis.cross(Vector3.UP)
	side = side.normalized() if side.length() > 0.0001 else Vector3.RIGHT
	_xf(n, Transform3D(Basis(Vector3.UP * width, axis, side * width), (head + tail) * 0.5))
	_uf(n, &"fade", fade)
	_vis(n, true)


# ================================================================ lifesteal

func _start_drain(at: Variant, unit: Node3D) -> void:
	if unit == null:
		return
	var busy := 0
	for f in _fx:
		if f.kind == K_DRAIN:
			busy += 1
			if f.unit == unit and f.t < DRAIN_GAP:
				return
	if busy >= MAX_DRAINS:
		return
	var fx := Fx.new()
	fx.kind = K_DRAIN
	fx.id = &"lifesteal"
	fx.unit = unit
	fx.team = _team_of(unit)
	fx.follow = true
	fx.kingdom = _kingdom_of(unit)
	fx.big = _is_big(unit)
	if typeof(at) == TYPE_OBJECT and _alive_node(at):
		fx.other = at as Node3D
		fx.chest_from = _height_of(fx.other, 1.8) * 0.55
	var p: Variant = _point_of(at)
	if p == null:
		p = unit.global_position + _flat(unit.global_transform.basis.z) * 1.6
	fx.point = p
	fx.from = (p as Vector3) + Vector3.UP * fx.chest_from
	# The rider's chest (UnitType.height = the top of the rider on its mount).
	fx.chest_to = _height_of(unit, 2.8 if fx.big else 2.0) * (0.95 if fx.big else 1.05)
	fx.to = unit.global_position + Vector3.UP * fx.chest_to
	var k := fx.kingdom
	var seed := randf() * 10.0
	var count := 4 if fx.big else 3
	var last_end := 0.0
	for i in count:
		var head := _take(fx, W_ROLES[i], &"flare")
		_params(head, {&"tint": _hdr(GLOW[k], 3.0), &"rays": 0.0, &"spikes": 4.0, &"pulse": 1.0,
				&"seed": seed + float(i), &"halo": _lin(DRAIN_HALO[k], 0.55)})
		var tail := _take(fx, T_ROLES[i], &"streak")
		_params(tail, {&"tint": _hdr(GLOW[k], 1.7), &"seed": seed + 3.0 + float(i), &"fade": 0.0})
		var ang := TAU * (float(i) / float(count)) + randf_range(-0.4, 0.4)
		var w := {"delay": 0.02 + 0.07 * float(i), "flight": randf_range(0.4, 0.5),
				"off": Vector3(cos(ang) * 0.28, randf_range(-0.2, 0.25), sin(ang) * 0.28),
				"lift": randf_range(0.8, 1.35) * (1.2 if fx.big else 1.0), "side": randf_range(-0.9, 0.9),
				"size": randf_range(0.62, 0.78) * (1.25 if fx.big else 1.0)}
		fx.wisps.append(w)
		last_end = maxf(last_end, float(w["delay"]) + float(w["flight"]))
	var rip := _take(fx, &"rip", &"flare")
	_params(rip, {&"tint": _hdr(GLOW[k], 1.2), &"rays": 0.35, &"spikes": 5.0, &"pulse": 0.0, &"seed": seed,
			&"halo": _lin(DRAIN_HALO[k], 0.7)})
	var absorb := _take(fx, &"absorb", &"flare")
	_params(absorb, {&"tint": _hdr(HOT[k], 1.3), &"rays": 0.0, &"spikes": 4.0, &"pulse": 1.0, &"seed": seed + 5.0,
			&"halo": Color(0, 0, 0, 0)})
	fx.dur = last_end + 0.55
	_start(fx)


func _tick_drain(fx: Fx) -> void:
	var t := fx.t
	if _alive_node(fx.other):
		fx.from = fx.other.global_position + Vector3.UP * fx.chest_from
	if _alive_node(fx.unit):
		fx.to = fx.unit.global_position + Vector3.UP * fx.chest_to
	var p0 := fx.from
	var p1 := fx.to
	var span := p1 - p0
	var side := span.cross(Vector3.UP)
	side = side.normalized() if side.length() > 0.0001 else Vector3.RIGHT
	var k := fx.kingdom
	for i in fx.wisps.size():
		var w: Dictionary = fx.wisps[i]
		var head: GeometryInstance3D = fx.nodes.get(W_ROLES[i])
		var tail: GeometryInstance3D = fx.nodes.get(T_ROLES[i])
		var u := (t - float(w["delay"])) / float(w["flight"])
		if u < 0.0 or u > 1.08:
			if head:
				_vis(head, false)
			if tail:
				_vis(tail, false)
			if u > 1.0 and fx.arrived < 0.0:
				fx.arrived = t
				fx.anchors[&"chest"] = Transform3D(Basis.IDENTITY, p1)
				if fx.shown:
					_burst(_tinted(&"drain_motes", k), fx.anchors[&"chest"])
			continue
		var a := p0 + (w["off"] as Vector3)
		var c := (a + p1) * 0.5 + Vector3.UP * float(w["lift"]) + side * float(w["side"])
		var e := smoothstep(0.0, 1.0, clampf(u, 0.0, 1.0))
		var pos := _bezier(a, c, p1, e)
		var back := _bezier(a, c, p1, smoothstep(0.0, 1.0, clampf(u - 0.22, 0.0, 1.0)))
		var appear := clampf(u / 0.12, 0.0, 1.0)
		var sink := 1.0 - smoothstep(0.9, 1.05, u)
		if head:
			var s := float(w["size"]) * (1.0 + 0.15 * sin(t * 31.0 + float(i) * 2.0)) * lerpf(1.0, 0.55, e)
			_xf(head, Transform3D(Basis.from_scale(Vector3.ONE * s), pos))
			_uf(head, &"fade", appear * sink)
			_vis(head, fx.shown)
		_place_streak(tail, pos, back, float(w["size"]) * 0.45, appear * sink, fx.shown)
	var rip: GeometryInstance3D = fx.nodes.get(&"rip")
	if rip and t >= 0.36:
		_vis(rip, false)
	elif rip:
		var f := clampf(t / 0.04, 0.0, 1.0) * (1.0 - smoothstep(0.12, 0.34, t))
		var s2 := lerpf(0.8, 1.5, _ease_out(clampf(t / 0.2, 0.0, 1.0))) * (1.2 if fx.big else 1.0)
		_xf(rip, Transform3D(Basis.from_scale(Vector3.ONE * s2), p0))
		_uf(rip, &"fade", f)
		_vis(rip, fx.shown and f > 0.002)
	var absorb: GeometryInstance3D = fx.nodes.get(&"absorb")
	# It swells from the first wisp's arrival and holds while the others sink in.
	var first := float(fx.wisps[0]["delay"]) + float(fx.wisps[0]["flight"]) if not fx.wisps.is_empty() else 0.4
	if absorb and t > first - 0.13:
		var at := t - fx.arrived if fx.arrived >= 0.0 else -1.0
		var pre := smoothstep(first - 0.12, first, t)
		var f4 := pre * (1.0 - smoothstep(fx.dur - 0.4, fx.dur - 0.05, t))
		var s3 := lerpf(0.55, 1.25, _ease_out(clampf(maxf(at, 0.0) / 0.2, 0.0, 1.0))) * (1.25 if fx.big else 1.0)
		_xf(absorb, Transform3D(Basis.from_scale(Vector3.ONE * s3), p1))
		_uf(absorb, &"fade", f4 * 0.85)
		_vis(absorb, fx.shown and f4 > 0.002)


func _bezier(a: Vector3, c: Vector3, b: Vector3, e: float) -> Vector3:
	var q := 1.0 - e
	return a * (q * q) + c * (2.0 * q * e) + b * (e * e)


# ================================================================ mount / dismount / thrown

func _start_puff(id: StringName, at: Variant, unit: Node3D) -> void:
	var fx := Fx.new()
	fx.kind = K_PUFF
	fx.id = id
	fx.unit = unit
	fx.team = _team_of(unit)
	fx.follow = unit != null
	fx.kingdom = _kingdom_of(unit)
	fx.big = _is_big(unit)
	var p: Variant = null
	if unit:
		p = unit.global_position
		fx.basis = Basis(Vector3.UP, _yaw_z(_flat(unit.global_transform.basis.z)))
	var land: Variant = null
	if at is Vector3 or at is Transform3D:
		land = _point_of(at)
		if p == null:
			p = land
	elif p == null:
		p = _point_of(at)
	if p == null:
		return
	fx.point = p
	var gy := _ground_y()
	var seed := randf() * 10.0
	var k := fx.kingdom
	var dust := _take(fx, &"dust_ring", &"ring")
	if dust:
		dust.transform = Transform3D(Basis.IDENTITY, fx.point + Vector3.UP * gy)
		_params(dust, {&"pattern": float(R_SOOT), &"seed": seed, &"tint": _lin(DUST)})
	var left := -fx.basis.x      # the kit's hop side: the mount's left flank
	var body := Transform3D(fx.basis, fx.point + Vector3.UP * 0.95)
	fx.anchors[&"body"] = body
	fx.anchors[&"flank"] = Transform3D(fx.basis, fx.point + left * 0.85 + Vector3.UP * 0.35)
	match id:
		&"mount":
			fx.dur = 1.2
			var ring := _take(fx, &"shock", &"ring")
			if ring:
				ring.transform = Transform3D(Basis.IDENTITY, fx.point + Vector3.UP * (gy + 0.003))
				_params(ring, {&"pattern": float(R_SHOCK), &"seed": seed + 1.0, &"tint": _hdr(GLOW[k], 0.9),
						&"age": 0.0})
			_sched(fx, &"mount_puff", 0.0, &"body")
			_sched(fx, &"hop_puff", 0.0, &"flank")
			_sched(fx, _tinted(&"mount_glints", k), 0.03, &"body")
		&"dismount":
			fx.dur = 1.5
			_sched(fx, &"hop_puff", HOP_LEN - 0.05, &"flank")
			_sched(fx, &"mount_puff", HOP_LEN - 0.1, &"body")
			_sched(fx, _tinted(&"mount_glints", k), HOP_LEN - 0.06, &"body")
		&"thrown":
			fx.dur = 1.7
			var lp: Vector3 = land if land is Vector3 else fx.point
			fx.anchors[&"seat"] = Transform3D(fx.basis, fx.point + Vector3.UP * (1.9 if fx.big else 1.45))
			fx.anchors[&"skid"] = Transform3D(fx.basis, lp + Vector3.UP * 0.25)
			fx.anchors[&"clods"] = Transform3D(fx.basis, lp + Vector3.UP * 0.2)
			_sched(fx, &"hop_puff", 0.0, &"seat")
			_sched(fx, &"thrown_dust", 0.28, &"skid")
			_sched(fx, &"charge_clods", 0.29, &"clods")
			_sched(fx, &"mount_puff", THROWN_LEN - 0.05, &"body")
	_start(fx)


func _tick_puff(fx: Fx) -> void:
	var t := fx.t
	var sc := 1.3 if fx.big else 1.0
	# The dust ring spreads when the big puff goes off (at once, at the hop-off, at the tumble's landing).
	var t0 := 0.0
	match fx.id:
		&"dismount":
			t0 = HOP_LEN - 0.1
		&"thrown":
			t0 = 0.28
	var dust: GeometryInstance3D = fx.nodes.get(&"dust_ring")
	if dust:
		var u := t - t0
		var r := lerpf(1.0, (2.6 if fx.id == &"thrown" else 2.2) * sc, _ease_out(clampf(u / 0.8, 0.0, 1.0)))
		var f := clampf(u / 0.08, 0.0, 1.0) * 0.75 * (1.0 - smoothstep(0.55, 0.9, u))
		_xf(dust, Transform3D(Basis.from_scale(Vector3(r, 1.0, r)), dust.transform.origin))
		_uf(dust, &"radius", r)
		_uf(dust, &"fade", f)
		_vis(dust, fx.shown and f > 0.002 and u >= 0.0)
	var ring: GeometryInstance3D = fx.nodes.get(&"shock")
	if ring:
		var r2 := lerpf(0.5, 2.0 * sc, _ease_out(clampf(t / 0.35, 0.0, 1.0)))
		var f2 := clampf(t / 0.04, 0.0, 1.0) * (1.0 - smoothstep(0.2, 0.5, t))
		_xf(ring, Transform3D(Basis.from_scale(Vector3(r2, 1.0, r2)), ring.transform.origin))
		_uf(ring, &"radius", r2)
		_uf(ring, &"fade", f2 * 0.8)
		_uf(ring, &"age", minf(t, 1.05))
		_vis(ring, fx.shown and f2 > 0.002)


# ================================================================ rider speed lines

func _ensure_rider(unit: Node3D) -> void:
	for r in _riders:
		if r.unit == unit:
			return
	var r := Rider.new()
	r.unit = unit
	r.last = unit.global_position
	_riders.append(r)


func _stop_rider(unit: Node3D) -> void:
	for i in range(_riders.size() - 1, -1, -1):
		if _riders[i].unit == unit:
			_rider_release(_riders[i])
			_riders.remove_at(i)


func _tick_riders(dt: float) -> void:
	for i in range(_riders.size() - 1, -1, -1):
		var r := _riders[i]
		if not _alive_node(r.unit):
			_rider_release(r)
			_riders.remove_at(i)
			continue
		var pos := r.unit.global_position
		# Speed, camera distance, riding and visibility are sampled 4 times per second.
		r.acc += dt
		r.check_left -= dt
		if r.check_left <= 0.0:
			r.check_left = CHECK_INTERVAL
			if r.has_prev and r.acc > 0.0:
				r.speed = Vector2(pos.x - r.prev.x, pos.z - r.prev.z).length() / r.acc
			r.prev = pos
			r.has_prev = true
			r.acc = 0.0
			if not _is_riding(r.unit):
				_rider_release(r)
				_riders.remove_at(i)
				continue
			var alive := true
			if r.unit.has_method(&"is_alive"):
				alive = bool(r.unit.call(&"is_alive"))
			if not alive:
				_rider_release(r)
				_riders.remove_at(i)
				continue
			r.near = _has_cam and _cam_pos.distance_to(pos) < LINES_RANGE
			r.ok = r.unit.is_visible_in_tree()
		var step := Vector2(pos.x - r.last.x, pos.z - r.last.z)
		if step.length() > 0.004:
			r.dir = Vector3(step.x, 0.0, step.y).normalized()
		r.last = pos
		var want := r.near and r.ok and r.speed >= LINES_MIN_SPEED
		if want and r.lines == null:
			r.lines = _take_stream(&"speed_lines")
			r.dust = _take_stream(&"hoof_dust")
			for p: GPUParticles3D in [r.lines, r.dust]:
				if p:
					p.transform = _rider_xf(r, p == r.dust)
					p.visible = true
					p.restart()
					p.emitting = true
		if r.lines or r.dust:
			if want:
				if r.lines:
					r.lines.transform = _rider_xf(r, false)
				if r.dust:
					r.dust.transform = _rider_xf(r, true)
			else:
				_rider_release(r)


func _rider_xf(r: Rider, ground: bool) -> Transform3D:
	var pos := r.unit.global_position
	var bz := _basis_z(r.dir)
	if ground:
		return Transform3D(bz, pos - r.dir * 0.4 + Vector3.UP * 0.12)
	return Transform3D(bz, pos + r.dir * 0.2 + Vector3.UP * 1.15)


func _rider_release(r: Rider) -> void:
	if r.lines:
		_drain(r.lines, &"speed_lines")
		r.lines = null
	if r.dust:
		_drain(r.dust, &"hoof_dust")
		r.dust = null


func _take_stream(look: StringName) -> GPUParticles3D:
	var free: Array = _stream_free[look]
	return free.pop_back() if not free.is_empty() else null


func _drain(p: GPUParticles3D, look: StringName) -> void:
	p.emitting = false
	_draining.append({"p": p, "look": look, "left": p.lifetime + 0.1})


## Riding: the unit's MountRider child says so (wizards, champions), else its is_mounted() (cavalry, 13.C1), else
## (no hook yet) it rides until speed_lines_off / death.
func _is_riding(u: Node3D) -> bool:
	var mr := u.get_node_or_null(^"MountRider")
	if mr and mr.has_method(&"is_riding"):
		return bool(mr.call(&"is_riding"))
	if u.has_method(&"is_mounted"):
		return bool(u.call(&"is_mounted"))
	return true


# ================================================================ effect runtime

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
	match fx.kind:
		K_CHARGE:
			_tick_charge(fx)
		K_DRAIN:
			_tick_drain(fx)
		_:
			_tick_puff(fx)
	if fx.bursts_left > 0:
		for b in fx.bursts:
			if b["done"] or fx.t < float(b["on"]):
				continue
			b["done"] = true
			fx.bursts_left -= 1
			if fx.shown:
				_burst(b["look"], fx.anchors.get(b["at"], Transform3D(Basis.IDENTITY, fx.point)))
	return fx.t >= fx.dur and fx.bursts_left <= 0


func _finish(fx: Fx) -> void:
	for role: StringName in fx.nodes:
		var n: GeometryInstance3D = fx.nodes[role]
		n.visible = false
		n.set_instance_shader_parameter(&"fade", 0.0)
		(_free[fx.pools[role]] as Array).append(n)
	fx.nodes.clear()


## Fog / hidden units (4 times per second).
func _refresh(fx: Fx) -> void:
	if fx.follow and _alive_node(fx.unit):
		fx.shown = fx.unit.is_visible_in_tree()
		return
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


# ---------------------------------------------------------------- pool helpers

func _take(fx: Fx, role: StringName, pool: StringName) -> GeometryInstance3D:
	var free: Array = _free[pool]
	if free.is_empty():
		return null   # pool exhausted: this piece is skipped (every helper accepts null)
	var n: GeometryInstance3D = free.pop_back()
	(_sent[n] as Dictionary).clear()
	n.set_instance_shader_parameter(&"fade", 0.0)
	n.visible = false
	fx.nodes[role] = n
	fx.pools[role] = pool
	return n


func _sched(fx: Fx, look: StringName, on: float, at: StringName) -> void:
	fx.bursts.append({"look": look, "on": on, "at": at, "done": false})
	fx.bursts_left += 1


func _burst(look: StringName, xf: Transform3D) -> void:
	var pool: Array = _bursts.get(look, [])
	if pool.is_empty():
		return
	var i: int = _burst_next[look]
	_burst_next[look] = (i + 1) % pool.size()
	var p: GPUParticles3D = pool[i]
	p.transform = xf
	p.visible = true
	p.restart()
	for b in _live_bursts:
		if b["p"] == p:
			b["left"] = p.lifetime + 0.1
			return
	_live_bursts.append({"p": p, "left": p.lifetime + 0.1})


func _tinted(look: StringName, kingdom: StringName) -> StringName:
	return StringName("%s/%s" % [look, kingdom])


func _params(n: GeometryInstance3D, params: Dictionary) -> void:
	if n == null:
		return
	for k: StringName in params:
		n.set_instance_shader_parameter(k, params[k])
		if params[k] is float:
			(_sent[n] as Dictionary)[k] = params[k]


## Sends a float instance uniform only when it changed.
func _uf(n: GeometryInstance3D, key: StringName, v: float) -> void:
	var c: Dictionary = _sent[n]
	var old: Variant = c.get(key)
	if old == null or absf(float(old) - v) > 0.003:
		c[key] = v
		n.set_instance_shader_parameter(key, v)


func _xf(n: GeometryInstance3D, xf: Transform3D) -> void:
	if not xf.is_equal_approx(n.transform):
		n.transform = xf


func _vis(n: GeometryInstance3D, v: bool) -> void:
	if n.visible != v:
		n.visible = v


func _ground_y() -> float:
	_layer = (_layer + 1) % 8
	return 0.05 + 0.006 * float(_layer)


# ---------------------------------------------------------------- small helpers

## The Unit behind a target: the node itself when it has `team`, else the nearest ancestor with one (a model inside
## its unit), else the node itself.
func _unit_of(t: Node3D) -> Node3D:
	if t == null:
		return null
	if &"team" in t:
		return t
	var c: Node = t.get_parent()
	var hops := 0
	while c and hops < 4:
		if c is Node3D and &"team" in c:
			return c as Node3D
		c = c.get_parent()
		hops += 1
	return t


func _team_of(n: Node) -> int:
	if n == null or not is_instance_valid(n):
		return -1
	var team: Variant = n.get(&"team")
	return int(team) if team != null else -1


func _kingdom_of(n: Node) -> StringName:
	if n == null or not is_instance_valid(n):
		return &"neutral"
	if n.has_meta(&"cavalry_vfx_kingdom"):
		var m := StringName(str(n.get_meta(&"cavalry_vfx_kingdom")))
		if KINGDOMS.has(m):
			return m
	var k: Variant = n.get(&"kingdom")
	if k != null and KINGDOMS.has(StringName(str(k))):
		return StringName(str(k))
	var ut: Variant = n.get(&"unit_type")
	if ut is Object and is_instance_valid(ut):
		var f: Variant = (ut as Object).get(&"faction")
		if f != null and KINGDOMS.has(StringName(str(f))):
			return StringName(str(f))
	return &"neutral"


## Titans (the Nightmare Knight) get the bigger versions.
func _is_big(n: Node) -> bool:
	if n == null or not is_instance_valid(n):
		return false
	if n.has_method(&"is_titan"):
		return bool(n.call(&"is_titan"))
	var ut: Variant = n.get(&"unit_type")
	if ut is Object and is_instance_valid(ut):
		var tags: Variant = (ut as Object).get(&"tags")
		if tags is Array and (tags as Array).has(&"titan"):
			return true
	return n.has_meta(&"titan")


## A unit's height (UnitType.height when it has one).
func _height_of(n: Node, fallback: float) -> float:
	if n == null or not is_instance_valid(n):
		return fallback
	var ut: Variant = n.get(&"unit_type")
	if ut is Object and is_instance_valid(ut):
		var h: Variant = (ut as Object).get(&"height")
		if h != null and float(h) > 0.3:
			return float(h)
	return fallback


func _point_of(at: Variant) -> Variant:
	if at is Vector3:
		return at
	if at is Transform3D:
		return (at as Transform3D).origin
	if typeof(at) == TYPE_OBJECT and _alive_node(at) and at is Node3D:
		return (at as Node3D).global_position
	return null


func _alive_node(n: Variant) -> bool:
	return n != null and is_instance_valid(n) and n is Node and (n as Node).is_inside_tree()


func _flat(v: Vector3) -> Vector3:
	var f := Vector3(v.x, 0.0, v.z)
	return f.normalized() if f.length() > 0.0001 else Vector3(0.0, 0.0, 1.0)


## Yaw that turns local +Z onto `d` (flat).
func _yaw_z(d: Vector3) -> float:
	return atan2(d.x, d.z)


## An orthonormal basis whose +Z is `d`.
func _basis_z(d: Vector3) -> Basis:
	var z := d.normalized() if d.length() > 0.0001 else Vector3(0.0, 0.0, 1.0)
	var up := Vector3.UP if absf(z.y) < 0.97 else Vector3(0.0, 0.0, -1.0)
	var x := up.cross(z).normalized()
	return Basis(x, z.cross(x), z)


func _ease_out(k: float) -> float:
	return 1.0 - pow(1.0 - k, 3.0)


## sRGB colour -> linear HDR (instance uniforms and particle colours are linear).
func _hdr(c: Color, energy: float, alpha: float = 1.0) -> Color:
	var l := c.srgb_to_linear()
	return Color(l.r * energy, l.g * energy, l.b * energy, alpha)


func _lin(c: Color, alpha: float = 1.0) -> Color:
	var l := c.srgb_to_linear()
	return Color(l.r, l.g, l.b, alpha)


# ================================================================ shared resources (built once)

func _build_shared() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(2.0, 2.0)
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	var meshes := {&"streak": quad, &"ring": plane, &"flare": quad}
	var mats := {&"streak": _shader_mat(STREAK_SHADER), &"ring": _shader_mat(RING_SHADER),
			&"flare": _shader_mat(FLARE_SHADER)}
	for pool: StringName in MESH_POOLS:
		var arr: Array = []
		for i in int(MESH_POOLS[pool]):
			var m := MeshInstance3D.new()
			m.name = "%s%d" % [String(pool).capitalize(), i]
			m.mesh = meshes[pool]
			m.material_override = mats[pool]
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			m.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
			m.visible = false
			if pool != &"ring":
				m.extra_cull_margin = 3.0      # billboards / streaks leave their mesh AABB
			if pool == &"streak":
				m.sorting_offset = 0.3
			add_child(m)
			arr.append(m)
			_sent[m] = {}
		_all[pool] = arr
		_free[pool] = arr.duplicate()
	_build_passes()
	for look: StringName in STREAMS:
		var spec: Array = STREAMS[look]
		var arr: Array = []
		for i in int(spec[3]):
			var p := _emitter(look, _pmat(look, &"neutral"), int(spec[0]), float(spec[1]), spec[2])
			p.one_shot = false
			p.explosiveness = 0.0
			p.randomness = 0.3
			add_child(p)
			arr.append(p)
		_stream_all[look] = arr
		_stream_free[look] = arr.duplicate()
	for look: StringName in BURSTS:
		var spec: Array = BURSTS[look]
		var kingdoms: Array[StringName] = [&"neutral"]
		if bool(spec[5]):
			kingdoms = KINGDOMS.duplicate()
		for k: StringName in kingdoms:
			var key: StringName = _tinted(look, k) if bool(spec[5]) else look
			var arr: Array = []
			for i in int(spec[3]):
				var p := _emitter(key, _pmat(look, k), int(spec[0]), float(spec[1]), spec[2])
				p.one_shot = true
				p.explosiveness = float(spec[4])
				add_child(p)
				arr.append(p)
			_bursts[key] = arr
			_burst_next[key] = 0


func _shader_mat(shader: Shader) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader
	return m


func _emitter(look: StringName, pm: ParticleProcessMaterial, amount: int, lifetime: float,
		pass_id: StringName) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "%s_%d" % [String(look).replace("/", "_"), get_child_count()]
	p.process_material = pm
	p.draw_pass_1 = _passes[pass_id]
	p.amount = amount
	p.lifetime = lifetime
	p.local_coords = false
	p.emitting = false
	p.visible = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var base := StringName(String(look).get_slice("/", 0))
	if BIG_LOOKS.has(base):
		p.visibility_aabb = AABB(Vector3(-6.0, -3.0, -6.0), Vector3(12.0, 9.0, 12.0))
	else:
		p.visibility_aabb = AABB(Vector3(-4.0, -3.0, -4.0), Vector3(8.0, 7.0, 8.0))
	return p


## Draw passes: textured billboard quads (never a bare square: every one has a shape mask and keeps the particle
## scale, Godot 4.7) + velocity-aligned streaks (combat_streak.gdshader): short sparks and long thin wind lines.
func _build_passes() -> void:
	_passes[&"add_dot"] = _particle_quad(_shape_tex(&"dot"), BaseMaterial3D.BLEND_MODE_ADD)
	_passes[&"add_star"] = _particle_quad(_shape_tex(&"star"), BaseMaterial3D.BLEND_MODE_ADD)
	_passes[&"mix_puff"] = _particle_quad(_shape_tex(&"puff"), BaseMaterial3D.BLEND_MODE_MIX, true)
	# The mount puff must COVER the rider standing inside the mount: only a short fade where it cuts bodies.
	_passes[&"mix_puff_hard"] = _particle_quad(_shape_tex(&"puff"), BaseMaterial3D.BLEND_MODE_MIX, true, 0.08)
	_passes[&"mix_dot"] = _particle_quad(_shape_tex(&"dot"), BaseMaterial3D.BLEND_MODE_MIX)
	_passes[&"streak"] = _streak_quad(4.0, 0.25)
	_passes[&"line"] = _streak_quad(26.0, 0.45)


func _streak_quad(stretch: float, core: float) -> QuadMesh:
	var q := QuadMesh.new()
	var sm := ShaderMaterial.new()
	sm.shader = SPARK_SHADER
	sm.set_shader_parameter(&"stretch", stretch)
	sm.set_shader_parameter(&"core_width", core)
	q.material = sm
	return q


func _particle_quad(tex: Texture2D, blend: BaseMaterial3D.BlendMode, soft: bool = false,
		fade_m: float = 0.3) -> QuadMesh:
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
		# Big puffs cut into the ground and the mount: soften the cut (no hard line where they meet it).
		mat.proximity_fade_enabled = true
		mat.proximity_fade_distance = fade_m
	var q := QuadMesh.new()
	q.size = Vector2.ONE   # 1 m: ParticleProcessMaterial scale_min / scale_max are the sizes in metres
	q.material = mat
	return q


## White shape masks (alpha = shape, grey = shading), tinted by the particle colour. Built once per run.
func _shape_tex(kind: StringName) -> ImageTexture:
	if _tex_cache.has(kind):
		return _tex_cache[kind]
	var n := 64
	var img := Image.create_empty(n, n, false, Image.FORMAT_RGBA8)
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
				&"puff":
					var nse := _vn(u * 2.3 + 7.1, v * 2.3 + 3.3) * 0.6 + _vn(u * 5.1 + 1.7, v * 5.1 - 2.2) * 0.4
					a = clampf((1.0 - r) * 1.6 + (nse - 0.5) * 0.9 - 0.2, 0.0, 1.0)
					a = a * a * (3.0 - 2.0 * a) * clampf((1.0 - r) / 0.2, 0.0, 1.0)
					shade = clampf(0.82 + 0.14 * (0.5 - v * 0.5) + (nse - 0.5) * 0.25, 0.0, 1.0)
			img.set_pixel(x, y, Color(shade, shade, shade, a))
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_tex_cache[kind] = tex
	return tex


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


## Particle process materials, one per look (and per kingdom for the tinted looks), shared by its emitters.
func _pmat(look: StringName, k: StringName) -> ParticleProcessMaterial:
	var key := StringName("%s/%s" % [look, k])
	if _pmats.has(key):
		return _pmats[key]
	var m := ParticleProcessMaterial.new()
	var dust_cols := _lin_all([DUST, DUST_DARK, DUST_LIGHT])
	var glow: Color = GLOW[k]
	var hot: Color = HOT[k]
	match look:
		&"speed_lines":
			# Thin pale wind lines left behind the rider (world space: the emitter runs ahead of them).
			_shape_box(m, Vector3(0.9, 0.7, 0.9))
			m.direction = Vector3(0, 0, -1)
			m.spread = 3.0
			m.initial_velocity_min = 1.2
			m.initial_velocity_max = 2.6
			m.gravity = Vector3.ZERO
			m.particle_flag_align_y = true
			m.scale_min = 0.035
			m.scale_max = 0.055
			m.scale_curve = _curve([Vector2(0.0, 0.5), Vector2(0.25, 1.0), Vector2(1.0, 0.3)])
			m.color_ramp = _ramp_at([0.0, 0.2, 0.6, 1.0], [_hdr(WIND, 1.4, 0.0), _hdr(WIND, 1.4, 0.75),
					_hdr(WIND, 1.1, 0.35), _hdr(WIND, 1.0, 0.0)])
		&"hoof_dust":
			_shape_box(m, Vector3(0.45, 0.05, 0.8))
			m.direction = Vector3(0, 1, -0.6)
			m.spread = 25.0
			m.initial_velocity_min = 0.4
			m.initial_velocity_max = 1.1
			m.damping_min = 0.8
			m.damping_max = 1.4
			m.gravity = Vector3(0, 0.3, 0)
			_spin(m, 30.0)
			_size(m, 0.4, 0.8, &"grow")
			m.color_initial_ramp = _ramp(dust_cols)
			m.color_ramp = _ramp_at([0.0, 0.15, 0.6, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.45),
					Color(1, 1, 1, 0.3), Color(1, 1, 1, 0.0)])
		&"charge_dust":
			_shape_ring(m, 0.7, 0.1)
			m.direction = Vector3.UP
			m.spread = 50.0
			m.initial_velocity_min = 0.6
			m.initial_velocity_max = 1.6
			m.radial_velocity_min = 1.8
			m.radial_velocity_max = 3.2
			m.damping_min = 2.6
			m.damping_max = 3.4
			m.gravity = Vector3(0, 0.3, 0)
			_spin(m, 40.0)
			m.scale_min = 0.9
			m.scale_max = 1.6
			m.scale_curve = _curve([Vector2(0.0, 0.35), Vector2(0.35, 1.0), Vector2(1.0, 1.15)])
			m.color_initial_ramp = _ramp(dust_cols)
			m.color_ramp = _ramp_at([0.0, 0.1, 0.6, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.75),
					Color(1, 1, 1, 0.45), Color(1, 1, 1, 0.0)])
		&"charge_clods":
			_shape_sphere(m, 0.4)
			m.direction = Vector3(0, 1, 0.5)
			m.spread = 45.0
			m.initial_velocity_min = 3.0
			m.initial_velocity_max = 6.0
			m.gravity = Vector3(0, -13.0, 0)
			_spin(m, 180.0)
			_size(m, 0.09, 0.17, &"hold")
			m.color_initial_ramp = _ramp(_lin_all([EARTH, Color(0.2, 0.15, 0.1), Color(0.38, 0.3, 0.2)]))
			m.color_ramp = _ramp_at([0.0, 0.8, 1.0], [Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
		&"charge_sparks":
			# Sparks fly on along the charge (the burst's +Z = the charge direction).
			_shape_sphere(m, 0.3)
			m.direction = Vector3(0, 0.5, 1)
			m.spread = 48.0
			m.initial_velocity_min = 4.0
			m.initial_velocity_max = 8.0
			m.damping_min = 1.0
			m.damping_max = 2.0
			m.gravity = Vector3(0, -8.0, 0)
			m.particle_flag_align_y = true
			_size(m, 0.05, 0.085, &"shrink")
			m.color_ramp = _ramp([_hdr(hot, 3.2), _hdr(glow, 2.4), _hdr(glow, 1.2, 0.0)])
		&"drain_motes":
			_shape_sphere(m, 0.35)
			m.direction = Vector3.UP
			m.spread = 40.0
			m.initial_velocity_min = 0.6
			m.initial_velocity_max = 1.4
			m.damping_min = 0.5
			m.damping_max = 0.9
			m.gravity = Vector3(0, 0.4, 0)
			_size(m, 0.1, 0.2, &"hold")
			m.color_ramp = _ramp_at([0.0, 0.1, 0.6, 1.0], [_hdr(hot, 3.0, 0.0), _hdr(hot, 3.0),
					_hdr(glow, 2.4), _hdr(glow, 1.4, 0.0)])
		&"mount_puff":
			# The big body puff: dense at once (it must hide the rider's hop start inside the mount), billowing out.
			_shape_box(m, Vector3(0.8, 0.55, 1.1))
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 0.3
			m.initial_velocity_max = 0.9
			m.damping_min = 1.5
			m.damping_max = 2.5
			m.gravity = Vector3(0, 0.25, 0)
			_spin(m, 30.0)
			m.scale_min = 1.15
			m.scale_max = 1.75
			m.scale_curve = _curve([Vector2(0.0, 0.95), Vector2(0.15, 1.0), Vector2(1.0, 1.25)])
			m.color_initial_ramp = _ramp(_lin_all([DUST_LIGHT, DUST, Color(0.84, 0.79, 0.69)]))
			m.color_ramp = _ramp_at([0.0, 0.15, 0.55, 1.0], [Color(1, 1, 1, 0.95), Color(1, 1, 1, 0.95),
					Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.0)])
		&"mount_glints":
			_shape_box(m, Vector3(0.7, 0.6, 1.2))
			m.direction = Vector3.UP
			m.spread = 60.0
			m.initial_velocity_min = 0.4
			m.initial_velocity_max = 1.2
			m.damping_min = 0.6
			m.damping_max = 1.0
			m.gravity = Vector3(0, 0.2, 0)
			_spin(m, 120.0)
			_size(m, 0.16, 0.3, &"hold")
			m.color_ramp = _ramp_at([0.0, 0.1, 0.55, 1.0], [_hdr(hot, 3.2, 0.0), _hdr(hot, 3.2),
					_hdr(glow, 2.4), _hdr(glow, 1.3, 0.0)])
		&"hop_puff":
			_shape_sphere(m, 0.3)
			m.emission_shape_scale = Vector3(1.0, 0.6, 1.4)
			m.direction = Vector3.UP
			m.spread = 70.0
			m.initial_velocity_min = 0.4
			m.initial_velocity_max = 1.0
			m.damping_min = 1.5
			m.damping_max = 2.2
			m.gravity = Vector3(0, 0.3, 0)
			_spin(m, 40.0)
			_size(m, 0.5, 0.9, &"grow")
			m.color_initial_ramp = _ramp(dust_cols)
			m.color_ramp = _ramp_at([0.0, 0.1, 0.55, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.75),
					Color(1, 1, 1, 0.4), Color(1, 1, 1, 0.0)])
		&"thrown_dust":
			# The tumble's skid: low, wide (both flanks), rolling out sideways.
			_shape_box(m, Vector3(1.5, 0.1, 0.8))
			m.direction = Vector3.UP
			m.spread = 65.0
			m.initial_velocity_min = 0.8
			m.initial_velocity_max = 2.0
			m.damping_min = 2.2
			m.damping_max = 3.0
			m.gravity = Vector3(0, 0.3, 0)
			_spin(m, 45.0)
			m.scale_min = 0.9
			m.scale_max = 1.6
			m.scale_curve = _curve([Vector2(0.0, 0.5), Vector2(0.3, 1.0), Vector2(1.0, 1.15)])
			m.color_initial_ramp = _ramp(dust_cols)
			m.color_ramp = _ramp_at([0.0, 0.1, 0.6, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.88),
					Color(1, 1, 1, 0.45), Color(1, 1, 1, 0.0)])
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


func _shape_box(m: ParticleProcessMaterial, extents: Vector3) -> void:
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = extents


## Particle sizes in metres + a scale curve: shrink (sparks), grow (dust puffs), hold (clods, motes, glints).
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
