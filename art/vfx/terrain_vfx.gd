class_name TerrainVfx
extends Node3D
## Terrain event effects (task 12b.V4, docs/design/terrain.md 6.2 / 6.3 / 7.3, contract section 13). Draw-only: never
## touches gameplay (no damage, no terrain change: the ash itself is the ground shader's, 12b.V1).
## API (group "terrain_vfx"; callers reach it through the group, load-guarded, never as a static type):
##     var vfx := get_tree().get_first_node_in_group(&"terrain_vfx")
##     if vfx and vfx.has_method(&"play"): vfx.call(&"play", id, at, radius, seconds)
##   play(id: StringName, at: Vector3, radius: float = 0.0, seconds := 0.0) -> void
##       radius <= 0 = the id's default (DEFAULT_RADIUS), seconds <= 0 = its default (DEFAULT_SECONDS). Unknown ids and
##       calls before _ready do nothing. The same id at the same spot within 0.3 s plays once (hook + direct call safe).
##   stop_at(at: Vector3, within := 1.0, ids: Array = []) -> int   ends the effects near `at` (fade 0.25 s)
##   stop_all() · handles(id) -> bool · active_count() / active_ids() / live_count() (tests)
## Ids:
##   scorch_spawn      a Fire scorch appearing (Fireball impact, Ember Step, dragon...: terrain.md 6.3): a quick heat
##                     flash on the ground (orange ring + glowing char that cools in ~1.3 s while the ground's fresh ash
##                     takes over), a soot puff, an ember burst. 1.6 s. radius default 2.5. Pooled: <= 8 at once.
##   wildfire_warning  seconds default 10: an orange ring on the exact radius (default 4.5) with a segmented countdown arc
##                     (one segment per second, lit clockwise from screen-up), heat specks, a contracting pulse that
##                     speeds up in the last 3 s, a smoke column that thickens, sparks rising in the second half, a
##                     smouldering glow at the centre.
##   wildfire_burn     seconds default 6 (EVENT_KINDS burn): the fire front rolls out to the radius in 0.5 s, a burning
##                     ground decal with a flickering fire line ON the damage edge, low flame cards over the disc
##                     (<= 32 flames + 8 embers = 40 quads), dark smoke, a broad fire glow (emission, no light). The
##                     char fades over 1.2 s after the flames: the ground's ash stays.
##   storm_warning     seconds default 10: a pale blue-white ring (default r 2.5) with the same countdown and a target
##                     reticle inside ("the bolt lands here"), a small dark cloud gathering 12 m above the spot with
##                     flickers inside that quicken, the cloud's shadow on the ground, static crackling on the ring in
##                     the last 3 s. The cloud dissipates over ~4 s after the warning ends (it is still there at the strike).
##   lightning_strike  a jagged bolt (6 pre-built shapes) races down from the cloud in 0.05 s: flash, dim gap, second
##                     stroke, gone at 0.3 s; a white flash quad, a sky flash in the cloud, a pale shock ring, a scorched
##                     crater glowing blue-white then orange and cooling, dust, sparks, clods; the sun pulses +0.3 energy
##                     for 0.1 s (`sun_flash`). A strike or a burn ends the matching warning at its spot.
## Hooks (`auto_hooks`, rescanned every second, no gameplay code change needed): the TerrainSystem (group "terrain") signals
##   event_warning(kind, spots, seconds) -> wildfire_warning / storm_warning at every spot (radius from its EVENT_KINDS),
##   event_started(kind, spots)          -> wildfire_burn (seconds = EVENT_KINDS burn) / lightning_strike at every spot,
##   scorch_added(id, pos, radius)       -> scorch_spawn.
##   A warning already live when the hook connects is caught up from live_events(). Kinds: &"wildfire", &"lightning".
## Fog (FogOfWar, group "fog"): weather is public (terrain.md 6.2): warnings, burns and strikes always show, under fog too.
##   scorch_spawn shows only where the local team sees the point (Fire's own scorch: terrain.md 6.3), checked 4 times / s.
## Budget: everything is built at _ready and pooled (mesh pools, stream emitters, one-shot bursts, the 6 bolt meshes): no
##   node, material or mesh is created after _ready. 0 lights, no shadows. One ShaderMaterial per shader, looks set with
##   instance uniforms. Own shaders: terrain_warning (rings), terrain_bolt; reused read-only: champion_ground (shock
##   rings, soot, cloud shadow), titan_ground (burning ground, strike crater), champion_flare (glows), combat_streak
##   (sparks / embers). Worst case the spec allows (2 pairs live = 4 events) + 8 scorches fits the pools; an exhausted
##   pool skips a piece, never allocates.
## GLUE (lead, 12b.L2): add ONE Node3D named "TerrainVfx" with this script to scenes/skirmish.tscn (next to MapFillVfx).
##   With a TerrainSystem in group "terrain" nothing else is needed (hooks). Missions without terrain: it stays idle.

const GROUP := &"terrain_vfx"
const EFFECTS: Array[StringName] = [&"scorch_spawn", &"wildfire_warning", &"wildfire_burn", &"storm_warning",
		&"lightning_strike"]
const DEFAULT_RADIUS := {&"scorch_spawn": 2.5, &"wildfire_warning": 4.5, &"wildfire_burn": 4.5,
		&"storm_warning": 2.5, &"lightning_strike": 2.5}
const DEFAULT_SECONDS := {&"scorch_spawn": 1.6, &"wildfire_warning": 10.0, &"wildfire_burn": 6.0,
		&"storm_warning": 10.0, &"lightning_strike": 0.3}
## Kind -> [radius, burn seconds] when the TerrainSystem has no EVENT_KINDS (terrain.md 13).
const KIND_FALLBACK := {&"wildfire": [4.5, 6.0], &"lightning": [2.5, 0.0]}

const CLOUD_HEIGHT := 12.0        # terrain.md 7.3: the storm cloud at 12 m
const BOLT_HEIGHT := 12.0
const BOLT_SHAPES := 6
const MAX_SECONDS := 30.0
const WILDFIRE_R := 4.5           # the radii the particle looks are made for (they scale with the radius)
const STRIKE_R := 2.5
const SCORCH_R := 2.5
const SUN_PULSE := 0.3
const SUN_PULSE_TIME := 0.1
const URGENT_TIME := 3.0          # the warnings' last seconds (faster pulse, static, sparks)
const DEDUPE_TIME := 0.3
const DEDUPE_DIST := 1.0
const HOOK_SCAN := 1.0
const FOG_RESCAN := 1.0
const CHECK_INTERVAL := 0.25
const STOP_FADE := 0.25
const WORLD_AABB := AABB(Vector3(-600.0, -60.0, -600.0), Vector3(1200.0, 120.0, 1200.0))

enum { VIS_POINT, VIS_ALWAYS }
enum { W_FIRE = 0, W_STORM = 1 }            # terrain_warning.gdshader styles
enum { G_SHOCK = 0, G_SOOT = 5 }            # champion_ground.gdshader patterns
enum { T_BURN = 0, T_CRATER = 4 }           # titan_ground.gdshader patterns

## Mesh pools: pool -> size.
const MESH_POOLS := {&"ring": 6, &"disc": 16, &"char": 12, &"flare": 20, &"bolt": BOLT_SHAPES}
## Stream emitters (emit while an effect runs, then drain): look -> [amount, lifetime, draw pass, pool size].
const STREAMS := {
	&"warn_smoke": [16, 3.4, &"mix_puff", 4],
	&"warn_sparks": [10, 1.3, &"add_dot", 4],
	&"storm_cloud": [14, 4.0, &"mix_cloud", 4],
	&"storm_static": [6, 0.5, &"add_star", 4],
	&"flames": [32, 0.85, &"add_flame", 4],
	&"fire_embers": [8, 1.1, &"streak", 4],
	&"burn_smoke": [10, 3.0, &"mix_puff", 4],
}
## One-shot bursts: look -> [amount, lifetime, draw pass, pool size, explosiveness].
const BURSTS := {
	&"scorch_smoke": [10, 1.6, &"mix_puff", 8, 0.8],
	&"scorch_embers": [14, 0.8, &"streak", 8, 0.95],
	&"strike_dust": [18, 1.4, &"mix_puff", 4, 0.95],
	&"strike_sparks": [20, 0.7, &"streak", 4, 1.0],
	&"strike_clods": [12, 0.9, &"mix_dot", 4, 1.0],
}

const WARN_SHADER := preload("res://art/vfx/terrain_warning.gdshader")
const BOLT_SHADER := preload("res://art/vfx/terrain_bolt.gdshader")
const DISC_SHADER := preload("res://art/vfx/champion_ground.gdshader")
const CHAR_SHADER := preload("res://art/vfx/titan_ground.gdshader")
const FLARE_SHADER := preload("res://art/vfx/champion_flare.gdshader")
const SPARK_SHADER := preload("res://art/vfx/combat_streak.gdshader")

# Palette (sRGB; art-keep 0.2 Fire glow #FF8C26; terrain.md 6.2 "orange for wildfire, pale blue-white for lightning").
const FIRE_HOT := Color(1.0, 0.9, 0.58)
const FIRE := Color(1.0, 0.55, 0.15)
const FIRE_DEEP := Color(0.85, 0.22, 0.05)
const SOOT := Color(0.05, 0.04, 0.035)
const SMOKE := Color(0.3, 0.27, 0.24)
const STORM := Color(0.72, 0.86, 1.0)
const STORM_HOT := Color(0.9, 0.96, 1.0)
const CLOUD := Color(0.17, 0.18, 0.23)
const CLOUD_SHADOW := Color(0.08, 0.09, 0.13)
const DUST := Color(0.5, 0.44, 0.35)
const EARTH := Color(0.2, 0.15, 0.11)

## Listen to the TerrainSystem (group "terrain") signals by itself.
@export var auto_hooks: bool = true
## lightning_strike pulses the scene's sun +0.3 energy for 0.1 s.
@export var sun_flash: bool = true

## Shape masks shared by every instance (built once per run).
static var _tex_cache: Dictionary = {}


## One running effect.
class Fx:
	extends RefCounted
	var id: StringName
	var t := 0.0
	var dur := 1.0
	var point := Vector3.ZERO
	var radius := 1.0
	var seconds := 0.0
	var vis := 0
	var shown := true
	var check_left := 0.0
	var end_at := -1.0
	var pieces: Array[Piece] = []
	var streams: Array[Stream] = []
	var bursts: Array[Dictionary] = []
	var bursts_left := 0
	var named: Dictionary = {}         # role -> Piece (driven uniforms)
	var flash := 0.0                   # storm flicker level
	var flash_next := 1.0
	var flash_echo := -1.0
	var switched := false
	var dirty := false                 # visibility changed: tick every piece / stream this frame


## One pooled mesh of an effect (MapFillVfx model): on / off window, offset lerped from o0 while growing, scale s0 -> s1
## over `grow`, fade in / out, `mul` scales the fade (flicker).
class Piece:
	extends RefCounted
	var n: GeometryInstance3D
	var pool: StringName
	var sends_radius := false
	var sends_age := false
	var ofs := Vector3.ZERO
	var o0 := Vector3.ZERO
	var on := 0.0
	var off := 0.0
	var fin := 0.0
	var fout := 0.0
	var s0 := Vector3.ONE
	var s1 := Vector3.ONE
	var grow := 0.0
	var back := false
	var yaw := 0.0
	var mul := 1.0
	var settled := false          # transform final (grown): no more transform updates
	var vis := false              # last visibility sent (the node is invisible while pooled)
	var dynamic := false          # its mul is driven every frame (flicker): never idles
	var idle_until := -1.0        # nothing changes before this effect time (settled, fully faded in)
	var sent: Dictionary = {}     # driven uniform -> last value sent
	var lf := -1.0
	var lr := -1.0


## A stream emitter of an effect: emits from `on` to `off` (amount_ratio r0 -> r1 over `ramp`), then drains.
class Stream:
	extends RefCounted
	var look: StringName
	var p: GPUParticles3D
	var on := 0.0
	var off := 0.0
	var ofs := Vector3.ZERO
	var size := 1.0
	var r0 := 1.0
	var r1 := 1.0
	var ramp := 0.0
	var state := 0                     # 0 waiting, 1 emitting, 2 done
	var last := -1.0
	var vis := false
	var idle_until := -1.0


var _fx: Array[Fx] = []
var _free: Dictionary = {}             # pool -> Array[GeometryInstance3D]
var _all: Dictionary = {}
var _stream_all: Dictionary = {}       # look -> Array[GPUParticles3D]
var _stream_free: Dictionary = {}
var _draining: Array[Dictionary] = []  # {p, look, left}
var _bursts: Dictionary = {}
var _burst_next: Dictionary = {}
var _live_bursts: Array[Dictionary] = []
var _pmats: Dictionary = {}
var _passes: Dictionary = {}
var _fog: Node
var _fog_left := 0.0
var _now := 0.0
var _recent: Array[Dictionary] = []
var _layer := 0
var _hook_left := 0.0
var _hooked: Dictionary = {}
var _terrain: Node
var _sun: DirectionalLight3D
var _sun_base := 0.0
var _sun_left := 0.0


func _ready() -> void:
	add_to_group(GROUP)
	top_level = true
	global_transform = Transform3D.IDENTITY
	_build_shared()
	_hook_left = 0.0


func _exit_tree() -> void:
	_sun_restore()


func _process(delta: float) -> void:
	_now += delta
	_fog_left -= delta
	if _fog_left <= 0.0:
		_fog_left = FOG_RESCAN
		_fog = get_tree().get_first_node_in_group(&"fog")
	if auto_hooks:
		_hook_left -= delta
		if _hook_left <= 0.0:
			_hook_left = HOOK_SCAN
			_scan_hooks()
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
			(_stream_free[d["look"]] as Array).append(p)
			_draining.remove_at(i)
	if _sun_left > 0.0:
		_sun_left -= delta
		if _sun_left <= 0.0:
			_sun_restore()
	if not _recent.is_empty() and _now - float(_recent[0]["t"]) > DEDUPE_TIME:
		while not _recent.is_empty() and _now - float(_recent[0]["t"]) > DEDUPE_TIME:
			_recent.remove_at(0)


# ---------------------------------------------------------------- public API

## Plays effect `id` at the ground point `at`. radius <= 0 / seconds <= 0 = the id's defaults (see the header).
func play(id: StringName, at: Vector3, radius: float = 0.0, seconds: float = 0.0) -> void:
	if not is_node_ready() or not is_inside_tree() or not EFFECTS.has(id):
		return
	var r: float = radius if radius > 0.05 else float(DEFAULT_RADIUS[id])
	var sec: float = seconds if seconds > 0.0 else float(DEFAULT_SECONDS[id])
	if _is_duplicate(id, at):
		return
	var fx := Fx.new()
	fx.id = id
	fx.point = Vector3(at.x, at.y, at.z)
	fx.radius = clampf(r, 0.5, 12.0)
	fx.seconds = clampf(sec, 0.3, MAX_SECONDS)
	fx.vis = VIS_ALWAYS
	match id:
		&"scorch_spawn": _scorch_spawn(fx)
		&"wildfire_warning": _wildfire_warning(fx)
		&"wildfire_burn": _wildfire_burn(fx)
		&"storm_warning": _storm_warning(fx)
		&"lightning_strike": _lightning_strike(fx)
	_start(fx)


## True for the ids this node plays.
func handles(id: StringName) -> bool:
	return EFFECTS.has(id)


## Ends the running effects within `within` metres of `at` (only those in `ids` when it is not empty), fading them out
## in 0.25 s; their emitters stop and drain. Returns how many were stopped.
func stop_at(at: Vector3, within: float = 1.0, ids: Array = []) -> int:
	var n := 0
	for fx in _fx:
		if fx.end_at >= 0.0 or (not ids.is_empty() and not ids.has(fx.id)):
			continue
		if Vector2(fx.point.x - at.x, fx.point.z - at.z).length() <= within:
			fx.end_at = fx.t + STOP_FADE
			n += 1
	return n


## Ends every running effect at once (a level reset).
func stop_all() -> void:
	for fx in _fx:
		_finish(fx)
	_fx.clear()


## Number of running effects.
func active_count() -> int:
	return _fx.size()


## Ids of the running effects.
func active_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for fx in _fx:
		out.append(fx.id)
	return out


## Pieces on screen + bursts alive + emitting / draining streams (0 once everything has ended).
func live_count() -> int:
	var n := _live_bursts.size() + _draining.size()
	for pool: StringName in _all:
		for g: GeometryInstance3D in _all[pool]:
			if g.visible:
				n += 1
	for fx in _fx:
		for s in fx.streams:
			if s.state == 1:
				n += 1
	return n


# ---------------------------------------------------------------- the effects

func _scorch_spawn(fx: Fx) -> void:
	var up := Vector3.UP
	var r := fx.radius
	var k := clampf(r / SCORCH_R, 0.4, 2.5)
	fx.dur = 1.6
	fx.vis = VIS_POINT
	fx.named[&"char"] = _char(fx, T_BURN, r / 0.92, _hdr(FIRE, 1.5), _lin(SOOT, 0.5), 0.0, 1.6, 0.0, 0.35)
	_disc(fx, G_SHOCK, _hdr(FIRE, 1.0), r * 0.3, r * 1.05, 0.3, 0.0, 0.55, 0.0, 0.25)
	_flare(fx, up * 0.6, _hdr(FIRE, 1.3), 0.8 * k, 1.6 * k, 0.12, 0.0, 0.35, 0.0, 0.22)
	_sched(fx, &"scorch_embers", 0.0, up * 0.2, k)
	_sched(fx, &"scorch_smoke", 0.03, up * 0.3, k)


func _wildfire_warning(fx: Fx) -> void:
	var up := Vector3.UP
	var r := fx.radius
	var T := fx.seconds
	var k := clampf(r / WILDFIRE_R, 0.4, 2.5)
	fx.dur = T + 0.35
	fx.named[&"ring"] = _ring(fx, W_FIRE, r, _hdr(FIRE, 1.7), T)
	# The ground darkens and smoulders where it will break out; smoke thickens; sparks in the second half.
	_disc(fx, G_SOOT, _lin(Color(0.09, 0.06, 0.045)), 0.5 * k, 1.8 * k, T * 0.8, 0.3, T + 0.3, 2.0, 0.3)
	var glow := _flare(fx, up * 0.45, _hdr(FIRE, 0.9), 1.4 * k, 2.2 * k, T * 0.8, 0.4, T, 1.2, 0.3, 0.0, 4.0, 1.0)
	if glow:
		glow.dynamic = true
	fx.named[&"glow"] = glow
	_stream(fx, &"warn_smoke", up * 0.3, 0.1, T, sqrt(k), 0.3, 1.0, T * 0.8)
	_stream(fx, &"warn_sparks", up * 0.1, T * 0.4, T, k, 0.25, 1.0, T * 0.5)


func _wildfire_burn(fx: Fx) -> void:
	var up := Vector3.UP
	var r := fx.radius
	var T := fx.seconds
	var k := clampf(r / WILDFIRE_R, 0.4, 2.5)
	stop_at(fx.point, 1.0, [&"wildfire_warning"])
	fx.dur = T + 1.3
	fx.named[&"char"] = _char(fx, T_BURN, r / 0.92, _hdr(FIRE, 1.7), _lin(SOOT, 0.85), 0.0, T + 1.3, 0.0, 1.2)
	_disc(fx, G_SHOCK, _hdr(FIRE, 1.6), r * 0.3, r * 1.02, 0.45, 0.0, 0.8, 0.0, 0.35)
	_flare(fx, up * 1.0, _hdr(FIRE, 0.22), 1.5 * r, 1.7 * r, 0.6, 0.0, T, 0.3, 0.8, 0.0, 4.0, 1.0)
	_flare(fx, up * 0.5, _hdr(FIRE, 0.55), 0.5 * r, 0.6 * r, 0.4, 0.1, T - 0.2, 0.2, 0.6, 0.0, 4.0, 1.0)
	_stream(fx, &"flames", up * 0.05, 0.05, T - 0.25, k, 0.35, 1.0, 0.7)
	_stream(fx, &"fire_embers", up * 0.3, 0.25, T - 0.3, k)
	_stream(fx, &"burn_smoke", up * 0.8, 0.3, T, k, 0.5, 1.0, 1.0)


func _storm_warning(fx: Fx) -> void:
	var up := Vector3.UP
	var r := fx.radius
	var T := fx.seconds
	var k := clampf(r / STRIKE_R, 0.4, 2.5)
	fx.dur = T + 0.4
	fx.named[&"ring"] = _ring(fx, W_STORM, r, _hdr(STORM, 1.6), T)
	# The cloud's shadow, the cloud gathering 12 m up (it drains away over ~4 s after the warning), flickers inside it.
	_disc(fx, G_SOOT, _lin(CLOUD_SHADOW), r * 0.9, r * 1.6, 2.0, 0.0, T + 0.9, 1.5, 0.8)
	_stream(fx, &"storm_cloud", up * CLOUD_HEIGHT, 0.0, T + 0.25, 1.0)
	_stream(fx, &"storm_static", up * 0.1, T - URGENT_TIME, T, k, 0.4, 1.0, URGENT_TIME * 0.8)
	var flash := _flare(fx, up * (CLOUD_HEIGHT - 0.4), _hdr(STORM, 1.3), 4.0, 4.0, 0.0, 0.6, T + 0.1, 0.0, 0.1)
	if flash:
		flash.mul = 0.0
		flash.dynamic = true
	fx.named[&"flash"] = flash
	fx.flash_next = 0.9 + randf() * 0.6


func _lightning_strike(fx: Fx) -> void:
	var up := Vector3.UP
	var r := fx.radius
	var k := clampf(r / STRIKE_R, 0.4, 2.5)
	stop_at(fx.point, 1.0, [&"storm_warning"])
	fx.dur = 2.6
	var bolt := _piece(fx, &"bolt", Vector3.ZERO, 0.0, 0.32, 0.0, 0.1, true)
	if bolt:
		bolt.yaw = randf() * TAU
		_grow(bolt, Vector3(k, 1.0, k).clamp(Vector3(0.8, 1.0, 0.8), Vector3(1.6, 1.0, 1.6)),
				Vector3(k, 1.0, k).clamp(Vector3(0.8, 1.0, 0.8), Vector3(1.6, 1.0, 1.6)), 0.0)
		_params(bolt, {&"tint": _hdr(STORM, 1.9), &"seed": randf() * 10.0})
	_flare(fx, up * 1.2, _hdr(Color(0.92, 0.96, 1.0), 1.6), 2.0 * k, 5.5 * k, 0.08, 0.0, 0.2, 0.0, 0.14)
	_flare(fx, up * CLOUD_HEIGHT, _hdr(STORM, 1.3), 4.5, 6.0, 0.1, 0.0, 0.3, 0.0, 0.2)
	_flare(fx, up * 0.35, _hdr(STORM_HOT, 2.0), 1.2 * k, 2.8 * k, 0.1, 0.0, 0.4, 0.0, 0.25, 1.0, 6.0)
	_disc(fx, G_SHOCK, _hdr(STORM, 2.0), r * 0.3, r * 1.8, 0.35, 0.0, 0.6, 0.0, 0.3)
	_disc(fx, G_SHOCK, _hdr(FIRE, 1.1), r * 0.2, r * 1.1, 0.5, 0.05, 0.9, 0.0, 0.4)
	fx.named[&"char"] = _char(fx, T_CRATER, r * 1.05, _hdr(STORM_HOT, 2.0), _lin(SOOT, 0.85), 0.0, 2.6, 0.0, 1.0)
	_sched(fx, &"strike_sparks", 0.0, up * 0.4, k)
	_sched(fx, &"strike_dust", 0.02, up * 0.3, k)
	_sched(fx, &"strike_clods", 0.0, up * 0.3, k)
	_sun_pulse()


## Per-frame uniforms of an effect (countdown, heat, flicker), before its pieces tick.
func _drive(fx: Fx, delta: float) -> void:
	var t := fx.t
	match fx.id:
		&"scorch_spawn":
			var c: Piece = fx.named.get(&"char")
			if c:
				_uf(c, &"heat", 0.45 * clampf(t / 0.08, 0.0, 1.0) * (1.0 - smoothstep(0.3, 1.3, t)))
				_uf(c, &"front", _ease(clampf(t / 0.25, 0.0, 1.0), false))
		&"wildfire_warning", &"storm_warning":
			var T := fx.seconds
			var urg := smoothstep(T - URGENT_TIME, T, t)
			var ring: Piece = fx.named.get(&"ring")
			if ring:
				_uf(ring, &"left", clampf(1.0 - t / T, 0.0, 1.0), 0.004)
				_uf(ring, &"urgency", urg, 0.01)
			var glow: Piece = fx.named.get(&"glow")
			if glow:
				glow.mul = 0.5 + 0.8 * urg
			var flash: Piece = fx.named.get(&"flash")
			if flash:
				var u := clampf(t / T, 0.0, 1.0)
				if t >= fx.flash_next:
					fx.flash = 1.0
					fx.flash_echo = t + randf_range(0.07, 0.12)
					fx.flash_next = t + randf_range(lerpf(1.5, 0.3, u), lerpf(2.5, 0.7, u))
				if fx.flash_echo > 0.0 and t >= fx.flash_echo:
					fx.flash = maxf(fx.flash, 0.75)
					fx.flash_echo = -1.0
				fx.flash *= exp(-delta * 15.0)
				flash.mul = 0.04 + fx.flash
		&"wildfire_burn":
			var T := fx.seconds
			var c: Piece = fx.named.get(&"char")
			if c:
				_uf(c, &"front", _ease(clampf(t / 0.5, 0.0, 1.0), false))
				_uf(c, &"heat", clampf(t / 0.15, 0.0, 1.0) * (1.0 - smoothstep(T - 0.8, T + 0.4, t)))
				_uf(c, &"rim", clampf(t / 0.3, 0.0, 1.0) * (1.0 - smoothstep(T - 0.5, T, t)))
		&"lightning_strike":
			var c: Piece = fx.named.get(&"char")
			if c:
				_uf(c, &"front", _ease(clampf(t / 0.1, 0.0, 1.0), false))
				_uf(c, &"heat", 1.0 - smoothstep(0.15, 1.6, t))
				if not fx.switched and t >= 0.12:
					fx.switched = true
					c.n.set_instance_shader_parameter(&"glow", _hdr(FIRE, 2.0))


# ---------------------------------------------------------------- hooks

func _scan_hooks() -> void:
	var terrain := get_tree().get_first_node_in_group(&"terrain")
	if terrain == null or _hooked.has(terrain.get_instance_id()):
		for id: int in _hooked.keys():
			if not is_instance_id_valid(id):
				_hooked.erase(id)
		return
	_terrain = terrain
	var any := false
	if terrain.has_signal(&"event_warning"):
		terrain.connect(&"event_warning", _on_event_warning)
		any = true
	if terrain.has_signal(&"event_started"):
		terrain.connect(&"event_started", _on_event_started)
		any = true
	if terrain.has_signal(&"scorch_added"):
		terrain.connect(&"scorch_added", _on_scorch_added)
		any = true
	if not any:
		return
	_hooked[terrain.get_instance_id()] = true
	# Catch up with a warning already running.
	if terrain.has_method(&"live_events"):
		for e: Variant in terrain.call(&"live_events"):
			if not (e is Dictionary):
				continue
			var d := e as Dictionary
			if StringName(str(d.get("state", ""))) != &"warning":
				continue
			var left := float(d.get("time_left", 0.0))
			if left > 0.5:
				_on_event_warning(StringName(str(d.get("kind", ""))), d.get("spots", []), left)


func _on_event_warning(kind: StringName, spots: Array, seconds: float) -> void:
	var fire := _is_fire(kind)
	var r := _kind_value(kind, "radius", 0)
	for s: Variant in spots:
		if s is Vector3:
			play(&"wildfire_warning" if fire else &"storm_warning", s, r, seconds)


func _on_event_started(kind: StringName, spots: Array) -> void:
	var fire := _is_fire(kind)
	var r := _kind_value(kind, "radius", 0)
	var burn := _kind_value(kind, "burn", 1) if fire else 0.0
	for s: Variant in spots:
		if s is Vector3:
			play(&"wildfire_burn" if fire else &"lightning_strike", s, r, burn)


func _on_scorch_added(_id: int, pos: Vector3, radius: float) -> void:
	play(&"scorch_spawn", pos, radius)


func _is_fire(kind: StringName) -> bool:
	var s := String(kind)
	return s.contains("fire") or s.contains("burn")


## A number of the TerrainSystem's EVENT_KINDS entry for `kind` (radius / burn), else KIND_FALLBACK[kind][slot].
func _kind_value(kind: StringName, key: String, slot: int) -> float:
	var fb: Array = KIND_FALLBACK[&"wildfire" if _is_fire(kind) else &"lightning"]
	if is_instance_valid(_terrain):
		var kinds: Variant = _terrain.get(&"EVENT_KINDS")
		if kinds is Dictionary and (kinds as Dictionary).has(kind):
			var e: Variant = (kinds as Dictionary)[kind]
			if e is Dictionary and (e as Dictionary).has(key):
				return float((e as Dictionary)[key])
	return float(fb[slot])


# ---------------------------------------------------------------- sun pulse

func _sun_pulse() -> void:
	if not sun_flash:
		return
	if _sun_left <= 0.0:
		_sun = _find_sun()
		if _sun == null:
			return
		_sun_base = _sun.light_energy
		_sun.light_energy = _sun_base + SUN_PULSE
	_sun_left = SUN_PULSE_TIME


func _sun_restore() -> void:
	if is_instance_valid(_sun):
		_sun.light_energy = _sun_base
	_sun_left = 0.0
	_sun = null


## The scene's sun: the first shadow-casting, visible DirectionalLight3D (LightingRig's "Sun").
func _find_sun() -> DirectionalLight3D:
	var scene: Node = get_tree().current_scene
	if scene == null:
		scene = get_tree().root
	var best: DirectionalLight3D = null
	for n in scene.find_children("*", "DirectionalLight3D", true, false):
		var l := n as DirectionalLight3D
		if l == null or not l.is_visible_in_tree():
			continue
		if l.shadow_enabled:
			return l
		if best == null:
			best = l
	return best


# ---------------------------------------------------------------- effect runtime

func _is_duplicate(id: StringName, pos: Vector3) -> bool:
	for r in _recent:
		if r["id"] == id and _now - float(r["t"]) <= DEDUPE_TIME and (r["pos"] as Vector3).distance_to(pos) <= DEDUPE_DIST:
			return true
	_recent.append({"id": id, "pos": pos, "t": _now})
	return false


func _start(fx: Fx) -> void:
	_fx.append(fx)
	_refresh(fx)
	fx.check_left = CHECK_INTERVAL
	_tick(fx, 0.0)


func _tick(fx: Fx, delta: float) -> bool:
	fx.t += delta
	fx.check_left -= delta
	if fx.check_left <= 0.0:
		fx.check_left += CHECK_INTERVAL
		_refresh(fx)
	var ef := 1.0 if fx.end_at < 0.0 else clampf((fx.end_at - fx.t) / STOP_FADE, 0.0, 1.0)
	_drive(fx, delta)
	# Settled pieces and steady streams sleep until their next change (fade-out, end): a running warning costs little.
	var full := fx.end_at >= 0.0 or fx.dirty
	fx.dirty = false
	for d in fx.pieces:
		if full or d.idle_until <= fx.t:
			_tick_piece(fx, d, ef)
	for s in fx.streams:
		if full or s.idle_until <= fx.t:
			_tick_stream(fx, s)
	if fx.bursts_left > 0:
		for b in fx.bursts:
			if not b["done"] and fx.t >= float(b["on"]):
				b["done"] = true
				fx.bursts_left -= 1
				if fx.shown and fx.end_at < 0.0:
					_burst(b["look"], fx.point + (b["ofs"] as Vector3), b["size"])
	if fx.end_at >= 0.0:
		return fx.t >= fx.end_at
	return fx.t >= fx.dur and fx.bursts_left <= 0


func _tick_piece(fx: Fx, d: Piece, ef: float) -> void:
	var n := d.n
	var off := d.off if d.off > 0.0 else fx.dur + d.off
	var lt := fx.t - d.on
	if lt < 0.0 or fx.t >= off:
		if d.vis:
			d.vis = false
			n.visible = false
		return
	var f := ef
	if d.fin > 0.0:
		f = minf(f, lt / d.fin)
	if d.fout > 0.0:
		f = minf(f, (off - fx.t) / d.fout)
	f = clampf(f, 0.0, 1.0) * d.mul
	# Transform: only while growing (and once when it appears); a settled piece costs nothing here.
	if not d.settled:
		d.settled = d.grow <= 0.0 or lt >= d.grow
		var k := 1.0
		if d.grow > 0.0:
			k = _ease(clampf(lt / d.grow, 0.0, 1.0), d.back)
		var s := d.s0.lerp(d.s1, k)
		n.transform = Transform3D(Basis(Vector3.UP, d.yaw) * Basis.from_scale(s), fx.point + d.o0.lerp(d.ofs, k))
		if d.sends_radius and absf(s.x - d.lr) > 0.001:
			d.lr = s.x
			n.set_instance_shader_parameter(&"radius", s.x)
	if absf(f - d.lf) > 0.003:
		d.lf = f
		n.set_instance_shader_parameter(&"fade", f)
	if d.sends_age and lt <= 1.05:
		n.set_instance_shader_parameter(&"age", lt)
	var vis := fx.shown and f > 0.002
	if d.vis != vis:
		d.vis = vis
		n.visible = vis
	if d.settled and not d.dynamic and f >= d.mul - 0.0001 and ef >= 1.0 and (not d.sends_age or lt > 1.05):
		d.idle_until = off - d.fout if d.fout > 0.0 else off


func _tick_stream(fx: Fx, s: Stream) -> void:
	if s.state == 0:
		if fx.end_at >= 0.0 or fx.t >= s.off:
			s.state = 2
			return
		if fx.t < s.on:
			return
		var free: Array = _stream_free[s.look]
		if free.is_empty():
			s.state = 2   # pool exhausted: skipped
			return
		var p: GPUParticles3D = free.pop_back()
		s.p = p
		p.transform = Transform3D(Basis.from_scale(Vector3.ONE * clampf(s.size, 0.4, 3.0)), fx.point + s.ofs)
		p.amount_ratio = s.r0
		s.last = s.r0
		p.visible = fx.shown
		s.vis = fx.shown
		p.restart()
		p.emitting = true
		s.state = 1
		return
	if s.state != 1:
		return
	if fx.t >= s.off or fx.end_at >= 0.0:
		_drain(s)
		return
	var k := 1.0 if s.ramp <= 0.0 else clampf((fx.t - s.on) / s.ramp, 0.0, 1.0)
	var r := lerpf(s.r0, s.r1, k)
	if absf(r - s.last) > 0.02:
		s.last = r
		s.p.amount_ratio = r
	if k >= 1.0 and absf(r - s.last) <= 0.02:
		s.idle_until = s.off   # steady until it stops
	if s.vis != fx.shown:
		s.vis = fx.shown
		s.p.visible = fx.shown


func _drain(s: Stream) -> void:
	if s.state == 1 and s.p != null:
		s.p.emitting = false
		_draining.append({"p": s.p, "look": s.look, "left": s.p.lifetime + 0.15})
	s.p = null
	s.state = 2


func _finish(fx: Fx) -> void:
	for d in fx.pieces:
		d.n.visible = false
		d.n.set_instance_shader_parameter(&"fade", 0.0)
		(_free[d.pool] as Array).append(d.n)
	fx.pieces.clear()
	for s in fx.streams:
		_drain(s)
	fx.named.clear()


func _refresh(fx: Fx) -> void:
	var was := fx.shown
	fx.shown = true if fx.vis == VIS_ALWAYS else _fog_ok(fx.point)
	if fx.shown != was:
		fx.dirty = true


## True when the local team sees `pos` (or there is no fog / it is off).
func _fog_ok(pos: Vector3) -> bool:
	if not is_instance_valid(_fog):
		return true
	if not bool(_fog.get(&"enabled")):
		return true
	var local: Variant = _fog.get(&"local_team")
	if local == null or not _fog.has_method(&"is_visible"):
		return true
	return bool(_fog.call(&"is_visible", int(local), pos))


# ---------------------------------------------------------------- piece helpers

func _piece(fx: Fx, pool: StringName, ofs: Vector3, on: float, off: float, fin: float, fout: float,
		pick_random: bool = false) -> Piece:
	var free: Array = _free[pool]
	if free.is_empty():
		return null   # pool exhausted: this piece is skipped (every helper accepts null)
	var d := Piece.new()
	d.n = free.pop_at(randi() % free.size()) if pick_random else free.pop_back()
	d.pool = pool
	d.sends_radius = pool == &"disc" or pool == &"ring"
	d.sends_age = pool == &"ring" or pool == &"bolt"   # the only shaders here that read `age`
	d.ofs = ofs
	d.o0 = ofs
	d.on = on
	d.off = off
	d.fin = fin
	d.fout = fout
	d.yaw = randf() * TAU if pool != &"ring" else 0.0
	d.n.set_instance_shader_parameter(&"fade", 0.0)
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


## A float instance uniform of a piece, sent only when it moved by more than step.
func _uf(d: Piece, uniform: StringName, v: float, step: float = 0.002) -> void:
	if absf(float(d.sent.get(uniform, -999.0)) - v) < step:
		return
	d.sent[uniform] = v
	d.n.set_instance_shader_parameter(uniform, v)


func _lift() -> Vector3:
	_layer = (_layer + 1) % 8
	return Vector3.UP * (0.05 + 0.006 * float(_layer))


## Ground mark (champion_ground.gdshader) growing from radius r0 to r1.
func _disc(fx: Fx, pattern: int, tint: Color, r0: float, r1: float, grow: float, on: float, off: float, fin: float,
		fout: float) -> Piece:
	var d := _piece(fx, &"disc", _lift(), on, off, fin, fout)
	_grow(d, Vector3(r0, 1.0, r0), Vector3(r1, 1.0, r1), grow)
	_params(d, {&"pattern": float(pattern), &"tint": tint, &"seed": randf() * 10.0})
	return d


## Burning ground / crater (titan_ground.gdshader) of `size` metres; heat / front / rim are driven per frame.
func _char(fx: Fx, pattern: int, size: float, glow: Color, cover: Color, on: float, off: float, fin: float,
		fout: float) -> Piece:
	var d := _piece(fx, &"char", _lift(), on, off, fin, fout)
	_grow(d, Vector3(size, 1.0, size), Vector3(size, 1.0, size), 0.0)
	_params(d, {&"pattern": float(pattern), &"seed": randf() * 10.0, &"radius": size, &"rim_at": 0.92 if pattern == T_BURN
			else 0.9, &"arc": 0.5, &"heat": 0.0, &"front": 0.0, &"rim": 0.0, &"glow": glow, &"cover": cover})
	return d


## Camera-facing glow (champion_flare.gdshader) growing from size s0 to s1 metres.
func _flare(fx: Fx, ofs: Vector3, tint: Color, s0: float, s1: float, grow: float, on: float, off: float, fin: float,
		fout: float, rays: float = 0.0, spikes: float = 4.0, pulse: float = 0.0) -> Piece:
	var d := _piece(fx, &"flare", ofs, on, off, fin, fout)
	_grow(d, s0, s1, grow)
	_params(d, {&"tint": tint, &"rays": rays, &"spikes": spikes, &"pulse": pulse, &"seed": randf() * 10.0,
			&"halo": Color(0, 0, 0, 0)})
	return d


## The warning ring (terrain_warning.gdshader) at radius `r`, counting down `T` seconds.
func _ring(fx: Fx, style: int, r: float, tint: Color, T: float) -> Piece:
	var d := _piece(fx, &"ring", Vector3.UP * 0.1, 0.0, T + 0.3, 0.25, 0.3)
	_grow(d, Vector3(r * 0.7, 1.0, r * 0.7), Vector3(r, 1.0, r), 0.35, true)
	_params(d, {&"tint": tint, &"style": float(style), &"ticks": clampf(roundf(T), 1.0, 20.0), &"left": 1.0,
			&"urgency": 0.0, &"seed": randf() * 10.0})
	return d


func _stream(fx: Fx, look: StringName, ofs: Vector3, on: float, off: float, size: float = 1.0, r0: float = 1.0,
		r1: float = 1.0, ramp: float = 0.0) -> void:
	if not _stream_free.has(look):
		return
	var s := Stream.new()
	s.look = look
	s.ofs = ofs
	s.on = maxf(on, 0.0)
	s.off = off
	s.size = size
	s.r0 = clampf(r0, 0.0, 1.0)
	s.r1 = clampf(r1, 0.0, 1.0)
	s.ramp = ramp
	s.idle_until = s.on
	fx.streams.append(s)


func _sched(fx: Fx, look: StringName, on: float, ofs: Vector3, size: float = 1.0) -> void:
	if not _bursts.has(look):
		return
	fx.bursts.append({"look": look, "on": on, "ofs": ofs, "size": size, "done": false})
	fx.bursts_left += 1


func _burst(look: StringName, pos: Vector3, size: float = 1.0) -> void:
	var pool: Array = _bursts[look]
	var i: int = _burst_next[look]
	_burst_next[look] = (i + 1) % pool.size()
	var p: GPUParticles3D = pool[i]
	p.transform = Transform3D(Basis.from_scale(Vector3.ONE * clampf(size, 0.4, 3.0)), pos)
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


## sRGB colour -> linear HDR (instance uniforms and particle colours are linear).
func _hdr(c: Color, energy: float, alpha: float = 1.0) -> Color:
	var l := c.srgb_to_linear()
	return Color(l.r * energy, l.g * energy, l.b * energy, alpha)


## sRGB colour -> linear with an alpha (cover colours).
func _lin(c: Color, alpha: float = 1.0) -> Color:
	var l := c.srgb_to_linear()
	return Color(l.r, l.g, l.b, alpha)


# ---------------------------------------------------------------- shared resources (built once)

func _build_shared() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(2.0, 2.0)
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	var meshes := {&"ring": plane, &"disc": plane, &"char": plane, &"flare": quad}
	var mats := {&"ring": _shader_mat(WARN_SHADER), &"disc": _shader_mat(DISC_SHADER), &"char": _shader_mat(CHAR_SHADER),
			&"flare": _shader_mat(FLARE_SHADER), &"bolt": _shader_mat(BOLT_SHADER)}
	for pool: StringName in MESH_POOLS:
		var arr: Array = []
		for i in int(MESH_POOLS[pool]):
			var m := MeshInstance3D.new()
			m.name = "%s%d" % [String(pool).capitalize(), i]
			m.mesh = _bolt_mesh(7 + i * 13) if pool == &"bolt" else meshes[pool]
			m.material_override = mats[pool]
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			m.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
			m.visible = false
			if pool == &"flare":
				m.extra_cull_margin = 2.0   # billboards leave their mesh AABB
			elif pool == &"bolt":
				m.extra_cull_margin = 2.0   # the ribbon is wider than its centre line
			add_child(m)
			arr.append(m)
		_all[pool] = arr
		_free[pool] = arr.duplicate()
	_build_passes()
	for look: StringName in STREAMS:
		var spec: Array = STREAMS[look]
		var arr: Array = []
		for i in int(spec[3]):
			var p := _emitter(look, int(spec[0]), float(spec[1]), spec[2])
			p.one_shot = false
			add_child(p)
			arr.append(p)
		_stream_all[look] = arr
		_stream_free[look] = arr.duplicate()
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


## A jagged bolt from (0, BOLT_HEIGHT, 0) to the ground at the origin, with 2-3 thinner branches (terrain_bolt.gdshader
## layout: centre-line points, tangent in NORMAL, UV = (edge -1 / +1, 0 cloud .. 1 ground), COLOR = (width, brightness)).
func _bolt_mesh(seed: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var n := 16
	var trunk := PackedVector3Array()
	var off := Vector2.ZERO
	for i in n:
		var t := float(i) / float(n - 1)
		var y := BOLT_HEIGHT * (1.0 - t)
		if i > 0 and i < n - 1:
			y += rng.randf_range(-0.22, 0.22)
			off += Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * 0.6
		trunk.append(Vector3(off.x, y, off.y))
	var end := trunk[n - 1]
	for i in n:
		var t := float(i) / float(n - 1)
		trunk[i] -= Vector3(end.x, 0.0, end.z) * t
	var lines: Array = [[trunk, 0.0, 1.0, 1.0, 1.0]]
	var branches := rng.randi_range(2, 3)
	for b in branches:
		var at := rng.randi_range(2, 9)
		var p := trunk[at]
		var a := rng.randf() * TAU
		var dir := Vector2(cos(a), sin(a))
		var pts := PackedVector3Array([p])
		var steps := rng.randi_range(4, 6)
		for s in steps:
			var h := rng.randf_range(0.4, 0.8)
			dir = dir.rotated(rng.randf_range(-0.5, 0.5))
			p += Vector3(dir.x * h, -rng.randf_range(0.45, 0.85), dir.y * h)
			pts.append(p)
		var a0 := float(at) / float(n - 1)
		lines.append([pts, a0, a0 + 0.3, 0.45, 0.62])
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	for line: Array in lines:
		var pts: PackedVector3Array = line[0]
		var last := pts.size() - 1
		for i in pts.size():
			var tan := (pts[mini(i + 1, last)] - pts[maxi(i - 1, 0)]).normalized()
			var along := lerpf(float(line[1]), float(line[2]), float(i) / float(last))
			var col := Color(float(line[3]), float(line[4]), 0.0, 1.0)
			for side: float in [-1.0, 1.0]:
				verts.append(pts[i])
				norms.append(tan)
				uvs.append(Vector2(side, along))
				cols.append(col)
			if i > 0:
				var base := verts.size() - 4
				idx.append_array([base, base + 2, base + 1, base + 1, base + 2, base + 3])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.custom_aabb = AABB(Vector3(-5.0, -0.5, -5.0), Vector3(10.0, BOLT_HEIGHT + 1.0, 10.0))
	return mesh


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
	p.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	match look:
		&"warn_smoke", &"burn_smoke":
			p.visibility_aabb = AABB(Vector3(-6.0, -1.0, -6.0), Vector3(14.0, 16.0, 14.0))
		&"storm_cloud":
			p.visibility_aabb = AABB(Vector3(-6.0, -3.0, -6.0), Vector3(12.0, 6.0, 12.0))
		_:
			p.visibility_aabb = AABB(Vector3(-7.0, -2.0, -7.0), Vector3(14.0, 8.0, 14.0))
	VfxCap.fit(p)   # G-F VFX caps: under the mix / additive caps (docs/art/gf_vfx_caps.md)
	return p


## Draw passes: textured billboard quads (a shape mask each, billboard_keep_scale) + velocity-aligned sparks.
func _build_passes() -> void:
	_passes[&"add_dot"] = _particle_quad(_shape_tex(&"dot"), BaseMaterial3D.BLEND_MODE_ADD)
	_passes[&"add_star"] = _particle_quad(_shape_tex(&"star"), BaseMaterial3D.BLEND_MODE_ADD)
	_passes[&"add_flame"] = _particle_quad(_shape_tex(&"flame"), BaseMaterial3D.BLEND_MODE_ADD, true)
	_passes[&"mix_puff"] = _particle_quad(_shape_tex(&"puff"), BaseMaterial3D.BLEND_MODE_MIX, true)
	_passes[&"mix_cloud"] = _particle_quad(_shape_tex(&"puff"), BaseMaterial3D.BLEND_MODE_MIX)
	_passes[&"mix_dot"] = _particle_quad(_shape_tex(&"dot"), BaseMaterial3D.BLEND_MODE_MIX)
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
	mat.billboard_keep_scale = true   # Godot 4.7: without it the particle scale is ignored
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = tex
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.disable_receive_shadows = true
	if soft:
		mat.proximity_fade_enabled = true
		mat.proximity_fade_distance = 0.35
	var q := QuadMesh.new()
	q.size = Vector2.ONE
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
				&"flame":
					# A tongue of flame: round base low in the quad, a wavy body tapering to a tip at the top.
					var tip := -0.94
					var base_c := 0.36
					var base_r := 0.44
					var w := 0.0
					if v < base_c:
						var tt := clampf((v - tip) / (base_c - tip), 0.0, 1.0)
						w = base_r * pow(tt, 0.8)
					else:
						w = sqrt(maxf(0.0, base_r * base_r - (v - base_c) * (v - base_c)))
					var tt2 := clampf((v - tip) / (base_c - tip), 0.0, 1.0)
					var uc := u + 0.1 * sin(v * 5.5 + 1.0) * (1.0 - tt2)
					a = clampf((w - absf(uc)) / 0.07, 0.0, 1.0) * clampf((v - tip) / 0.2, 0.0, 1.0)
					var inner := 1.0 - clampf(absf(uc) / maxf(w, 0.01), 0.0, 1.0)
					shade = clampf(0.55 + 0.45 * inner + 0.2 * tt2, 0.0, 1.0)
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


## Particle process materials, one per look, shared by every emitter of that look.
func _pmat(key: StringName) -> ParticleProcessMaterial:
	if _pmats.has(key):
		return _pmats[key]
	var m := ParticleProcessMaterial.new()
	var wind := Vector3(0.8, 0.0, 0.6)
	match key:
		&"scorch_smoke":
			_shape_sphere(m, 0.5)
			m.emission_shape_scale = Vector3(1.0, 0.4, 1.0)
			m.direction = Vector3.UP
			m.spread = 40.0
			m.initial_velocity_min = 1.2
			m.initial_velocity_max = 2.2
			m.damping_min = 1.5
			m.damping_max = 2.2
			m.gravity = Vector3(0, 0.6, 0) + wind * 0.3
			_spin(m, 30.0)
			_size(m, 1.0, 1.6, &"grow")
			m.color_initial_ramp = _ramp(_lin_all([Color(0.2, 0.17, 0.15), Color(0.28, 0.24, 0.21),
					Color(0.16, 0.14, 0.13)]))
			m.color_ramp = _ramp_at([0.0, 0.15, 0.6, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.8),
					Color(1, 1, 1, 0.5), Color(1, 1, 1, 0.0)])
		&"scorch_embers":
			_shape_ring(m, 1.2, 0.1)
			m.emission_ring_inner_radius = 0.2
			m.direction = Vector3.UP
			m.spread = 35.0
			m.initial_velocity_min = 3.0
			m.initial_velocity_max = 6.0
			m.damping_min = 1.0
			m.damping_max = 2.0
			m.gravity = Vector3(0, -6.0, 0)
			m.particle_flag_align_y = true
			_size(m, 0.05, 0.08, &"shrink")
			m.color_ramp = _ramp([_hdr(FIRE_HOT, 3.0), _hdr(FIRE, 2.4), _hdr(FIRE_DEEP, 1.4, 0.0)])
		&"warn_smoke":
			# The column rising where the fire will break out: grey-brown, leaning downwind, thickening.
			_shape_sphere(m, 0.5)
			m.emission_shape_scale = Vector3(1.0, 0.3, 1.0)
			m.direction = Vector3.UP
			m.spread = 7.0
			m.initial_velocity_min = 2.0
			m.initial_velocity_max = 2.8
			m.damping_min = 0.3
			m.damping_max = 0.5
			m.gravity = Vector3(0, 0.15, 0) + wind * 0.4
			_spin(m, 20.0)
			m.scale_min = 1.3
			m.scale_max = 2.1
			m.scale_curve = _curve([Vector2(0.0, 0.35), Vector2(0.4, 0.8), Vector2(1.0, 1.0)])
			m.color_initial_ramp = _ramp(_lin_all([Color(0.42, 0.38, 0.33), Color(0.35, 0.32, 0.29),
					Color(0.5, 0.47, 0.43)]))
			m.color_ramp = _ramp_at([0.0, 0.12, 0.6, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.6),
					Color(1, 1, 1, 0.38), Color(1, 1, 1, 0.0)])
		&"warn_sparks":
			_shape_disc(m, 3.6)
			m.direction = Vector3.UP
			m.spread = 12.0
			m.initial_velocity_min = 0.5
			m.initial_velocity_max = 1.2
			m.damping_min = 0.2
			m.damping_max = 0.4
			m.gravity = Vector3(0, 0.5, 0) + wind * 0.15
			_size(m, 0.08, 0.13, &"grow")
			var f := _hdr(FIRE, 2.4)
			m.color_ramp = _ramp([Color(f, 0.0), _hdr(FIRE_HOT, 2.8), f, Color(_hdr(FIRE_DEEP, 1.2), 0.0)])
		&"storm_cloud":
			# A small dark cloud churning 12 m up: slate puffs, slow swirl, built up over ~2 s.
			_shape_sphere(m, 1.6)
			m.emission_shape_scale = Vector3(1.4, 0.25, 0.8)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 0.05
			m.initial_velocity_max = 0.25
			m.damping_min = 0.1
			m.damping_max = 0.2
			m.tangential_accel_min = 0.15
			m.tangential_accel_max = 0.35
			m.gravity = Vector3.ZERO
			_spin(m, 10.0)
			m.scale_min = 3.4
			m.scale_max = 4.4
			m.scale_curve = _curve([Vector2(0.0, 0.5), Vector2(0.25, 1.0), Vector2(1.0, 0.95)])
			m.color_initial_ramp = _ramp(_lin_all([CLOUD, Color(0.23, 0.24, 0.3), Color(0.13, 0.14, 0.18)]))
			m.color_ramp = _ramp_at([0.0, 0.2, 0.8, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.95),
					Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.0)])
		&"storm_static":
			_shape_ring(m, 2.4, 0.1)
			m.emission_ring_inner_radius = 2.1
			m.direction = Vector3.UP
			m.spread = 60.0
			m.initial_velocity_min = 0.5
			m.initial_velocity_max = 1.5
			m.damping_min = 1.0
			m.damping_max = 2.0
			m.gravity = Vector3(0, -2.0, 0)
			_spin(m, 400.0)
			_size(m, 0.14, 0.24, &"shrink")
			m.color_ramp = _ramp([_hdr(STORM_HOT, 3.2), _hdr(STORM, 2.2), _hdr(STORM, 1.0, 0.0)])
		&"flames":
			# Low flame cards over the whole disc (made for r 4.5; the emitter scales with the radius).
			_shape_disc(m, 4.1)
			m.direction = Vector3.UP
			m.spread = 6.0
			m.initial_velocity_min = 0.4
			m.initial_velocity_max = 1.0
			m.damping_min = 0.5
			m.damping_max = 0.9
			m.gravity = Vector3(0, 1.4, 0) + wind * 0.3
			m.angle_min = -8.0
			m.angle_max = 8.0
			m.scale_min = 1.0
			m.scale_max = 1.6
			m.scale_curve = _curve([Vector2(0.0, 0.25), Vector2(0.3, 1.0), Vector2(1.0, 0.15)])
			m.color_ramp = _ramp_at([0.0, 0.25, 0.65, 1.0], [_hdr(FIRE_HOT, 2.6), _hdr(FIRE, 2.2),
					_hdr(FIRE_DEEP, 1.3, 0.7), _hdr(FIRE_DEEP, 0.8, 0.0)])
		&"fire_embers":
			_shape_disc(m, 3.8)
			m.direction = Vector3.UP
			m.spread = 25.0
			m.initial_velocity_min = 2.5
			m.initial_velocity_max = 4.5
			m.damping_min = 0.4
			m.damping_max = 0.7
			m.gravity = Vector3(0, -1.2, 0) + wind * 0.4
			m.particle_flag_align_y = true
			_size(m, 0.04, 0.07, &"shrink")
			m.color_ramp = _ramp([_hdr(FIRE_HOT, 3.0), _hdr(FIRE, 2.4), _hdr(FIRE, 1.2, 0.0)])
		&"burn_smoke":
			_shape_sphere(m, 2.5)
			m.emission_shape_scale = Vector3(1.0, 0.2, 1.0)
			m.direction = Vector3.UP
			m.spread = 12.0
			m.initial_velocity_min = 1.6
			m.initial_velocity_max = 2.4
			m.damping_min = 0.3
			m.damping_max = 0.5
			m.gravity = Vector3(0, 0.3, 0) + wind * 0.5
			_spin(m, 20.0)
			_size(m, 1.8, 2.8, &"grow")
			m.color_initial_ramp = _ramp(_lin_all([Color(0.14, 0.12, 0.11), Color(0.2, 0.18, 0.16),
					Color(0.1, 0.09, 0.09)]))
			m.color_ramp = _ramp_at([0.0, 0.12, 0.6, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.7),
					Color(1, 1, 1, 0.45), Color(1, 1, 1, 0.0)])
		&"strike_dust":
			_shape_ring(m, 0.8, 0.1)
			m.emission_ring_inner_radius = 0.3
			m.direction = Vector3.UP
			m.spread = 70.0
			m.initial_velocity_min = 0.8
			m.initial_velocity_max = 1.6
			m.radial_velocity_min = 3.5
			m.radial_velocity_max = 5.5
			m.damping_min = 3.0
			m.damping_max = 4.0
			m.gravity = Vector3(0, 0.3, 0)
			_spin(m, 30.0)
			_size(m, 1.4, 2.2, &"grow")
			m.color_initial_ramp = _ramp(_lin_all([DUST, Color(0.42, 0.37, 0.3), Color(0.58, 0.52, 0.44)]))
			m.color_ramp = _ramp_at([0.0, 0.15, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.75), Color(1, 1, 1, 0.0)])
		&"strike_sparks":
			_shape_sphere(m, 0.3)
			m.direction = Vector3.UP
			m.spread = 70.0
			m.initial_velocity_min = 5.0
			m.initial_velocity_max = 9.0
			m.damping_min = 1.5
			m.damping_max = 2.5
			m.gravity = Vector3(0, -8.0, 0)
			m.particle_flag_align_y = true
			_size(m, 0.05, 0.08, &"shrink")
			m.color_ramp = _ramp([_hdr(STORM_HOT, 3.4), _hdr(FIRE, 2.2), _hdr(FIRE_DEEP, 1.0, 0.0)])
		&"strike_clods":
			_shape_sphere(m, 0.3)
			m.direction = Vector3.UP
			m.spread = 50.0
			m.initial_velocity_min = 3.0
			m.initial_velocity_max = 6.0
			m.damping_min = 0.3
			m.damping_max = 0.6
			m.gravity = Vector3(0, -12.0, 0)
			_size(m, 0.12, 0.2, &"hold")
			m.color_initial_ramp = _ramp(_lin_all([EARTH, Color(0.14, 0.11, 0.09), Color(0.26, 0.2, 0.15)]))
			m.color_ramp = _ramp_at([0.0, 0.8, 1.0], [Color(1, 1, 1, 1.0), Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.0)])
	_pmats[key] = m
	return m


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


func _spin(m: ParticleProcessMaterial, deg: float) -> void:
	m.angle_min = -180.0
	m.angle_max = 180.0
	m.angular_velocity_min = -deg
	m.angular_velocity_max = deg


## Particle sizes in metres + a scale curve: shrink (sparks), grow (smoke, motes), hold (clods).
func _size(m: ParticleProcessMaterial, lo: float, hi: float, kind: StringName) -> void:
	m.scale_min = lo
	m.scale_max = hi
	match kind:
		&"grow":
			m.scale_curve = _curve([Vector2(0.0, 0.3), Vector2(0.3, 1.0), Vector2(1.0, 0.3)])
		&"hold":
			m.scale_curve = _curve([Vector2(0.0, 0.6), Vector2(0.15, 1.0), Vector2(0.85, 1.0), Vector2(1.0, 0.5)])
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
