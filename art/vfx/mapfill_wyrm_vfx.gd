class_name MapFillWyrmVfx
extends Node3D
## Frost Wyrm effects (task 13c.V9, docs/design/titans-2.md 7 + section 11 row 13c.V9). Draw-only: never touches
## gameplay.
##
## ENTRY POINT: MapFillVfx (art/vfx/mapfill_vfx.gd) loads this script when the file exists (`wyrm_vfx_path`), adds ONE
## instance as its child "WyrmVfx" and forwards the ids this node `handles()` (before the beast effects of 12.V31).
## Callers keep using MapFillVfx:
##   var vfx := get_tree().get_first_node_in_group(&"mapfill_vfx")
##   if vfx and vfx.has_method(&"play"): vfx.call(&"play", id, at, target)
## It also works on its own (a test / preview level): add it anywhere. Group "mapfill_wyrm_vfx" (NOT "mapfill_vfx").
## `play(id, at, target) -> bool`: true when `id` is a wyrm effect (handled, even if fog hides it or a pool is full).
## `at` = a world point (Vector3; a Node3D is read once; null = the target's position). `target` = the Frost Wyrm Unit,
## its model (art/units/neutral/beasts/frost_wyrm, a FlyerModel with the wyrm signals) or null.
## Ids (numbers from titans-2.md 7):
##   wyrm_breath    Rime Breath. at = the aim point on the ground (optional), target = the Wyrm. The 13c.V2 frost
##                  breath scaled to the Wyrm: a rime jet from the head (followed live, the head sweep swings it) for
##                  0.6 s, a 60 deg rime fan rolling out to 7.0 m, ice glints, snow billows, lingering cold mist.
##                  Variant B (Old Hoarfang): white-violet glow.
##   wyrm_dive      Glacial Dive. at = the landing point (the ring centre), target = the Wyrm. A frost ring r 3 with
##                  ice chevrons and a rime fill closing to the centre over 1.0 s (the countdown, shown to BOTH teams:
##                  only the fog at the spot hides it), then the ICE BURST where it lands: a crown of ice spikes erupts
##                  (and shatters 1 s later), a shattered-ice crater r 3.6, a shock ring, a snow-dust wall, shards,
##                  glints, cold mist.
##   wyrm_tail      Tail Lash. at = the Wyrm's position (the r 3.5 centre), target = the Wyrm. Snow kicked at the tail
##                  tip in the wind-up, then at the strike a white-hot arc sweeps round the coil (~200 deg, the
##                  tail's side and direction), snow sprayed along it, a low shock ring r 3.5, ice chips.
##   wyrm_blizzard  Blizzard (B only). at = the Wyrm's position, target = the Wyrm. For 8 s a wall of blowing snow
##                  r 8 (two turning snow cylinders) FOLLOWS the Wyrm, snow cover and spiral drifts on the ground with
##                  a bright danger edge at r 8, streams of snow swirling inside; a burst and a ring racing out at
##                  the release. Ends early (0.9 s fade) if the Wyrm dies.
##   wyrm_warning   The 30 s pre-spawn warning. at = the lair centre (the Icebound Barge), target = null. A cold mist
##                  creeps over the river r 9 and thickens for 30 s (low mist banks, rising vapour, frost haze and
##                  glints on the water), then a frost pulse; the mist lingers 3.5 s into the spawn. Shown through
##                  the fog on purpose (both teams get the warning message: this is the "something is coming" tell).
## AUTO HOOKS (no gameplay wiring needed): every node entering the tree with the Frost Wyrm signals (`breath_released`,
## `dive_landed(at)`, `tail_struck(at)`, `blizzard_released(at)`) is attached: breath on breath_released, the ice burst
## on dive_landed (no telegraph: the ring needs the gameplay call at the cast), the lash on tail_struck, the blizzard on
## blizzard_released, a rime wake off the tail tip while it flies (< 45 m from the camera), and its death crash
## (`crashed(at)`) is forwarded to TitanVfx `frost_crash` (13c.V2's ice shatter, reused). The Wyrm model is a
## FlyerModel, so TitanVfx attaches it too: this node DETACHES it from TitanVfx (`detach(model)`) so the breath is not
## drawn twice. Explicit calls MERGE with the model's signals: wyrm_breath before the jaw opens waits <= 0.45 s for
## breath_released, just after it (<= 0.5 s) re-aims it; wyrm_dive shows the ring at once and lands on dive_landed
## (else at 1.0 s, 1.5 s for an attached Wyrm); wyrm_tail waits <= 0.6 s for tail_struck (else strikes at 0.35 s);
## wyrm_blizzard waits <= 1.0 s for blizzard_released; a second call for the same cast is ignored.
## Fog: breath / lash / blizzard / wake follow the Wyrm's `visible` (a fogged Wyrm hides them); the dive checks
## FogOfWar.is_visible at its point (4 times per second); the warning always shows.
## Budget: everything is built at _ready and pooled (mesh pools, stream emitters, one-shot bursts): no node, material
## or mesh is created after _ready. 0 lights, no shadows. One ShaderMaterial per shader; own: mapfill_wyrm_ground
## (telegraph, arc, blizzard floor, mist), mapfill_wyrm_storm (snow wall), mapfill_wyrm_ice (ice crown); reused
## read-only: titan_breath (jet), titan_ground (rime fan, ice crater), champion_ground (rings), champion_flare (glows),
## combat_streak (streak pass). Every particle quad has a shape mask and billboard_keep_scale.

const GROUP := &"mapfill_wyrm_vfx"
const EFFECTS: Array[StringName] = [&"wyrm_breath", &"wyrm_dive", &"wyrm_tail", &"wyrm_blizzard", &"wyrm_warning"]

# Spec numbers (titans-2.md 7).
const BREATH_RANGE := 7.0
const BREATH_ARC_DEG := 60.0
const JET_TIME := 0.6
const JET_LAND := 5.0
const DIVE_RADIUS := 3.0
const DIVE_TELEGRAPH := 1.0
const LASH_RADIUS := 3.5
const LASH_WINDUP := 0.35
const LASH_SWEEP_DEG := 200.0
const BLIZZARD_RADIUS := 8.0
const BLIZZARD_TIME := 8.0
const BLIZZARD_HEIGHT := 7.0
const WARNING_TIME := 30.0
const WARNING_RADIUS := 9.0
const WARNING_LINGER := 3.5
const FLY_HEIGHT := 4.0
const WAKE_RANGE := 45.0
const WAKE_MIN_SPEED := 0.8
# Glue timing.
const MERGE_WINDOW := 0.5
const PENDING_MAX := 0.45
const DIVE_WAIT := 1.5
const LASH_WAIT := 0.6
const BLIZ_WAIT := 1.0
const CHECK_INTERVAL := 0.25
const FOG_RESCAN := 1.0
const TAKEOVER_SCAN := 1.0

enum { K_BREATH, K_DIVE, K_LASH, K_BLIZ, K_WARN }
enum { VIS_TARGET, VIS_POINT, VIS_ALWAYS }
enum { W_TELE, W_ARC, W_BLIZ, W_MIST }                  # mapfill_wyrm_ground.gdshader
enum { G_FAN_FROST = 3, G_CRATER_ICE = 5 }              # titan_ground.gdshader
enum { R_SHOCK = 0, R_WIND = 1, R_SOOT = 5 }            # champion_ground.gdshader

## Mesh pools: pool -> size (two Wyrms at once, each busy).
const MESH_POOLS := {&"jet": 4, &"tground": 6, &"wground": 10, &"ring": 10, &"flare": 12, &"storm": 4, &"crown": 4}
## Stream emitters (emit while an effect runs, follow their anchor): look -> [amount, lifetime, draw pass, pool size].
const STREAMS := {
	&"wyrm_jet": [48, 0.6, &"mix_puff", 4],
	&"wyrm_glints": [22, 0.6, &"add_star", 8],
	&"wyrm_splash": [44, 0.9, &"mix_puff", 4],
	&"tele_motes": [18, 0.9, &"add_star", 4],
	&"lash_windup": [14, 0.5, &"mix_puff", 2],
	&"bliz_snow": [160, 1.6, &"mix_dot", 2],
	&"bliz_flakes": [48, 2.2, &"mix_flake", 2],
	&"bliz_ground": [28, 1.5, &"mix_puff", 2],
	&"warn_mist": [20, 5.0, &"mix_puff", 2],
	&"warn_vapour": [16, 3.5, &"mix_puff", 2],
	&"wyrm_wake": [30, 1.4, &"add_shard", 2],
}
## One-shot bursts: look -> [amount, lifetime, draw pass, pool size, explosiveness].
const BURSTS := {
	&"rime_linger": [14, 2.0, &"mix_puff", 4, 0.7],
	&"snow_dust": [44, 1.8, &"mix_puff", 3, 0.95],
	&"ice_shards": [26, 1.1, &"mix_shard", 4, 1.0],
	&"ice_glints": [22, 0.9, &"add_star", 4, 0.9],
	&"cold_mist": [12, 2.6, &"mix_puff", 3, 0.6],
	&"lash_spray_a": [22, 0.8, &"mix_puff", 2, 0.9],
	&"lash_spray_b": [22, 0.8, &"mix_puff", 2, 0.9],
	&"lash_chips": [16, 0.8, &"mix_shard", 2, 1.0],
	&"bliz_burst": [40, 1.3, &"mix_puff", 2, 0.95],
	&"warn_glints": [30, 1.4, &"add_star", 2, 0.8],
}
## Emitters whose particles travel far (bigger visibility box).
const BIG_LOOKS: Array[StringName] = [&"wyrm_jet", &"wyrm_splash", &"snow_dust", &"cold_mist", &"lash_spray_a",
		&"lash_spray_b", &"bliz_burst", &"wyrm_wake", &"rime_linger"]
## Emitters spanning the storm / the mist (the biggest box).
const HUGE_LOOKS: Array[StringName] = [&"bliz_snow", &"bliz_flakes", &"bliz_ground", &"warn_mist", &"warn_vapour",
		&"warn_glints"]

const BREATH_SHADER := preload("res://art/vfx/titan_breath.gdshader")
const TGROUND_SHADER := preload("res://art/vfx/titan_ground.gdshader")
const WGROUND_SHADER := preload("res://art/vfx/mapfill_wyrm_ground.gdshader")
const STORM_SHADER := preload("res://art/vfx/mapfill_wyrm_storm.gdshader")
const ICE_SHADER := preload("res://art/vfx/mapfill_wyrm_ice.gdshader")
const RING_SHADER := preload("res://art/vfx/champion_ground.gdshader")
const FLARE_SHADER := preload("res://art/vfx/champion_flare.gdshader")
const SPARK_SHADER := preload("res://art/vfx/combat_streak.gdshader")

# Palette (sRGB; the Frost Dragon's of 13c.V2 + Old Hoarfang's white-violet).
const FROST_HOT := Color(0.93, 0.98, 1.0)
const FROST := Color(0.75, 0.92, 1.0)
const FROST_TEAM := Color(0.45, 0.75, 0.95)
const FROST_DEEP := Color(0.15, 0.35, 0.6)
const RIME := Color(0.82, 0.9, 0.97)
const SNOW := Color(0.94, 0.97, 1.0)
const HOAR := Color(0.86, 0.78, 1.0)          # B glow (white-violet)
const HOAR_DEEP := Color(0.55, 0.38, 0.9)

## Shape masks shared by every instance (built once per run).
static var _tex_cache: Dictionary = {}


## One running effect.
class Fx:
	extends RefCounted
	var id: StringName
	var kind := 0
	var t := 0.0
	var dur := 1.0
	var end_at := -1.0            # set when stopped early (blizzard: the Wyrm died)
	var model: Node3D
	var unit: Node3D
	var team := -1
	var variant := 0
	var vis := 0
	var shown := true
	var check_left := 0.0
	var point := Vector3.ZERO
	var ground := Vector3.ZERO
	var dir := Vector3(0.0, 0.0, 1.0)
	var mouth := Vector3.ZERO
	var yaw0 := 0.0
	var reach := BREATH_RANGE
	var gy := 0.05
	var land_t := -1.0            # dive: landing time / lash: strike time (-1 = not yet)
	var deadline := 1.0           # dive / lash: fallback landing / strike time
	var strike := Vector3.ZERO
	var a0 := 0.0
	var a1 := 0.0
	var moving_anchors := false
	var t_last_full := 0.0
	var nodes: Dictionary = {}    # role -> GeometryInstance3D
	var pools: Dictionary = {}    # role -> pool
	var anchors: Dictionary = {}  # anchor -> Transform3D
	var streams: Array[Dictionary] = []
	var bursts: Array[Dictionary] = []
	var bursts_left := 0


var _fx: Array[Fx] = []
var _att: Dictionary = {}           # model -> record (Dictionary)
var _free: Dictionary = {}          # pool -> Array[GeometryInstance3D]
var _all: Dictionary = {}           # pool -> Array[GeometryInstance3D]
var _sent: Dictionary = {}          # node -> {uniform: last float sent}
var _stream_all: Dictionary = {}    # look -> Array[GPUParticles3D]
var _stream_free: Dictionary = {}
var _draining: Array[Dictionary] = []      # {p, look, left}
var _bursts: Dictionary = {}        # look -> Array[GPUParticles3D]
var _burst_next: Dictionary = {}
var _live_bursts: Array[Dictionary] = []   # {p, left}
var _pmats: Dictionary = {}
var _passes: Dictionary = {}
var _fog: Node
var _fog_left := 0.0
var _cam_left := 0.0
var _cam_pos := Vector3.ZERO
var _has_cam := false
var _clock := 0.0
var _layer := 0
var _built := false
var _takeover_left := 0.0
var _crown_mesh: ArrayMesh


func _ready() -> void:
	add_to_group(GROUP)
	top_level = true                  # effects are placed in world space
	global_transform = Transform3D.IDENTITY
	_build_shared()
	_built = true
	_connect_tree()
	_scan.call_deferred(get_tree().root)


func _enter_tree() -> void:
	if _built:
		_connect_tree()


func _exit_tree() -> void:
	var tree := get_tree()
	if tree and tree.node_added.is_connected(_on_node_added):
		tree.node_added.disconnect(_on_node_added)


func _connect_tree() -> void:
	var tree := get_tree()
	if tree and not tree.node_added.is_connected(_on_node_added):
		tree.node_added.connect(_on_node_added)


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
	if not _att.is_empty():
		_tick_wyrms(delta)
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
			p.amount_ratio = 1.0
			(_stream_free[d["look"]] as Array).append(p)
			_draining.remove_at(i)


# ================================================================ public API

## Plays wyrm effect `id` (see the header). Returns true when `id` is a wyrm effect (handled), false otherwise.
func play(id: StringName, at: Variant, target: Variant = null) -> bool:
	if not EFFECTS.has(id):
		return false
	if not _built or not is_inside_tree():
		return true
	var t: Node3D = null
	if typeof(target) == TYPE_OBJECT and is_instance_valid(target) and target is Node3D \
			and (target as Node3D).is_inside_tree():
		t = target as Node3D
	var res := _resolve(t)
	var model: Node3D = res[0]
	var unit: Node3D = res[1]
	var body: Node3D = unit if unit else model
	match id:
		&"wyrm_breath":
			_request_breath(_aim_of(at), model, unit)
		&"wyrm_dive":
			var p: Variant = _point_of(at, body)
			if p is Vector3:
				_request_dive(p, model, unit)
		&"wyrm_tail":
			var p2: Variant = _point_of(at, body)
			if p2 is Vector3:
				_request_lash(p2, model, unit)
		&"wyrm_blizzard":
			var p3: Variant = _point_of(at, body)
			if p3 is Vector3:
				_request_blizzard(p3, model, unit)
		&"wyrm_warning":
			var p4: Variant = _point_of(at, t)
			if p4 is Vector3:
				_start_warning(p4)
	return true


## True when `id` is one of this node's effects.
func handles(id: StringName) -> bool:
	return EFFECTS.has(id)


## Hooks a Frost Wyrm model (its signals). Done automatically for every such model entering the tree. Returns true when
## newly attached.
func attach(model: Node3D) -> bool:
	if model == null or not is_instance_valid(model) or _att.has(model) or not _is_wyrm(model):
		return false
	_att[model] = {"unit": null, "breath_t": -99.0, "breath_fx": null, "pend_t": -99.0, "pend_aim": null,
			"dive_fx": null, "lash_fx": null, "lash_t": -99.0, "bliz_t": -99.0, "bliz_wait_t": -99.0,
			"bliz_at": Vector3.ZERO, "tip": Vector3.ZERO, "prev_tip": Vector3.ZERO, "has_tip": false,
			"wake": null, "wake_prev": Vector3.ZERO, "wake_speed": 0.0, "wake_acc": 0.0, "wake_left": 0.0,
			"wake_ok": false, "has_wake_prev": false}
	model.connect(&"breath_released", _on_breath_released.bind(model))
	model.connect(&"dive_landed", _on_dive_landed.bind(model))
	model.connect(&"tail_struck", _on_tail_struck.bind(model))
	model.connect(&"blizzard_released", _on_blizzard_released.bind(model))
	if model.has_signal(&"crashed"):
		model.connect(&"crashed", _on_crashed.bind(model))
	model.connect(&"tree_exiting", _on_model_exiting.bind(model))
	_take_over.call_deferred(model)
	return true


## Unhooks a Frost Wyrm model (its wake stops).
func detach(model: Node3D) -> void:
	if not _att.has(model):
		return
	var rec: Dictionary = _att[model]
	_wake_stop(rec)
	_att.erase(model)
	if is_instance_valid(model):
		for sig: StringName in [&"breath_released", &"dive_landed", &"tail_struck", &"blizzard_released", &"crashed",
				&"tree_exiting"]:
			if not model.has_signal(sig):
				continue
			for c: Dictionary in model.get_signal_connection_list(sig):
				var cb: Callable = c["callable"]
				if cb.get_object() == self:
					model.disconnect(sig, cb)


func is_attached(model: Node3D) -> bool:
	return _att.has(model)


## Number of running effects (wakes not counted).
func active_count() -> int:
	return _fx.size()


## Ids of the running effects.
func active_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for fx in _fx:
		out.append(fx.id)
	return out


## Pooled meshes on screen + bursts alive + stream emitters taken (running, draining or waking). 0 when idle.
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


## True while `model`'s rime wake is emitting (tests).
func wake_emitting(model: Node3D) -> bool:
	var rec: Dictionary = _att.get(model, {})
	if rec.is_empty() or rec["wake"] == null:
		return false
	return (rec["wake"] as GPUParticles3D).emitting


# ================================================================ auto attach

func _on_node_added(n: Node) -> void:
	if n is Node3D and _is_wyrm(n):
		attach(n as Node3D)


func _scan(n: Node) -> void:
	if not is_instance_valid(n):
		return
	if n is Node3D and _is_wyrm(n):
		attach(n as Node3D)
	for c: Node in n.get_children():
		_scan(c)


func _on_model_exiting(model: Node3D) -> void:
	detach(model)


## TitanVfx attaches every FlyerModel (the Wyrm is one): take the Wyrm back so its breath is drawn once.
func _take_over(model: Node3D) -> void:
	if not is_instance_valid(model) or not _att.has(model) or not is_inside_tree():
		return
	for tv: Node in get_tree().get_nodes_in_group(&"titan_vfx"):
		if tv.has_method(&"is_attached") and tv.has_method(&"detach") and bool(tv.call(&"is_attached", model)):
			tv.call(&"detach", model)


func _on_breath_released(model: Node3D) -> void:
	var rec: Dictionary = _att.get(model, {})
	if rec.is_empty() or not _alive_node(model):
		return
	var aim: Variant = null
	if _clock - float(rec["pend_t"]) <= PENDING_MAX + 0.05:
		aim = rec["pend_aim"]
	rec["pend_t"] = -99.0
	rec["breath_t"] = _clock
	rec["breath_fx"] = _start_breath(aim, model, _unit_of(model))


func _on_dive_landed(at: Vector3, model: Node3D) -> void:
	var rec: Dictionary = _att.get(model, {})
	if rec.is_empty():
		return
	var fx: Variant = rec["dive_fx"]
	rec["dive_fx"] = null
	if fx is Fx and _fx.has(fx) and (fx as Fx).land_t < 0.0:
		_land_dive(fx as Fx)
		return
	var d := _start_dive(at, model, _unit_of(model), false)
	if d:
		_land_dive(d)


func _on_tail_struck(at: Vector3, model: Node3D) -> void:
	var rec: Dictionary = _att.get(model, {})
	if rec.is_empty():
		return
	rec["lash_t"] = _clock
	var fx: Variant = rec["lash_fx"]
	rec["lash_fx"] = null
	if fx is Fx and _fx.has(fx) and (fx as Fx).land_t < 0.0:
		_strike_lash(fx as Fx, at)
		return
	var unit := _unit_of(model)
	var c: Vector3 = (unit if unit else model).global_position
	var l := _start_lash(c, model, unit)
	if l:
		_strike_lash(l, at)


func _on_blizzard_released(at: Vector3, model: Node3D) -> void:
	var rec: Dictionary = _att.get(model, {})
	if rec.is_empty():
		return
	rec["bliz_wait_t"] = -99.0
	if _clock - float(rec["bliz_t"]) < BLIZ_WAIT:
		return
	rec["bliz_t"] = _clock
	var unit := _unit_of(model)
	var c: Vector3 = (unit if unit else model).global_position if _alive_node(model) else at
	_start_blizzard(c, model, unit)


func _on_crashed(at: Vector3, _model: Node3D) -> void:
	if not is_inside_tree():
		return
	var tv := get_tree().get_first_node_in_group(&"titan_vfx")
	if tv and tv.has_method(&"play"):
		tv.call(&"play", &"frost_crash", at, null)   # null target: TitanVfx must not re-attach the Wyrm


## Pending explicit breaths / blizzards, tail tips (lash direction), rime wakes, the TitanVfx take-over.
func _tick_wyrms(delta: float) -> void:
	_takeover_left -= delta
	var rescan := _takeover_left <= 0.0
	if rescan:
		_takeover_left = TAKEOVER_SCAN
	for key: Variant in _att.keys():
		if not is_instance_valid(key):
			_att.erase(key)
			continue
		var model := key as Node3D
		var rec: Dictionary = _att[model]
		if rescan:
			_take_over(model)
		var pt := float(rec["pend_t"])
		if pt > -90.0 and _clock - pt > PENDING_MAX:
			rec["pend_t"] = -99.0
			rec["breath_t"] = _clock
			if _alive_node(model):
				rec["breath_fx"] = _start_breath(rec["pend_aim"], model, _unit_of(model))
		var bt := float(rec["bliz_wait_t"])
		if bt > -90.0 and _clock - bt > BLIZ_WAIT:
			rec["bliz_wait_t"] = -99.0
			rec["bliz_t"] = _clock
			_start_blizzard(rec["bliz_at"], model, _unit_of(model))
		if model.is_inside_tree() and model.has_method(&"get_tail_tip"):
			rec["prev_tip"] = rec["tip"]
			rec["tip"] = model.call(&"get_tail_tip")
			if not bool(rec["has_tip"]):
				rec["prev_tip"] = rec["tip"]
				rec["has_tip"] = true
		_tick_wake(model, rec, delta)


# ---------------------------------------------------------------- rime wake

func _tick_wake(model: Node3D, rec: Dictionary, dt: float) -> void:
	rec["wake_acc"] = float(rec["wake_acc"]) + dt
	rec["wake_left"] = float(rec["wake_left"]) - dt
	if float(rec["wake_left"]) <= 0.0:
		rec["wake_left"] = CHECK_INTERVAL
		var pos := model.global_position
		if bool(rec["has_wake_prev"]) and float(rec["wake_acc"]) > 0.0:
			var prev: Vector3 = rec["wake_prev"]
			rec["wake_speed"] = Vector2(pos.x - prev.x, pos.z - prev.z).length() / float(rec["wake_acc"])
		rec["wake_prev"] = pos
		rec["has_wake_prev"] = true
		rec["wake_acc"] = 0.0
		var grounded := model.has_method(&"is_grounded") and bool(model.call(&"is_grounded"))
		var unit := _unit_of(model)
		var alive := true
		if _alive_node(unit) and unit.has_method(&"is_alive"):
			alive = bool(unit.call(&"is_alive"))
		var near := _has_cam and _cam_pos.distance_to(pos + Vector3.UP * FLY_HEIGHT) < WAKE_RANGE
		rec["wake_ok"] = alive and near and not grounded and model.is_visible_in_tree() \
				and float(rec["wake_speed"]) > WAKE_MIN_SPEED
	var want := bool(rec["wake_ok"])
	var p: GPUParticles3D = rec["wake"]
	if want and p == null:
		var free: Array = _stream_free[&"wyrm_wake"]
		if not free.is_empty():
			p = free.pop_back()
			rec["wake"] = p
			p.transform = _wake_xf(model)
			p.visible = true
			p.restart()
			p.emitting = true
	if p:
		if want:
			p.transform = _wake_xf(model)
		else:
			_wake_stop(rec)


func _wake_stop(rec: Dictionary) -> void:
	var p: GPUParticles3D = rec["wake"]
	if p == null:
		return
	p.emitting = false
	_draining.append({"p": p, "look": &"wyrm_wake", "left": p.lifetime + 0.1})
	rec["wake"] = null


func _wake_xf(model: Node3D) -> Transform3D:
	var tip: Vector3 = model.call(&"get_tail_tip") if model.has_method(&"get_tail_tip") \
			else model.global_position + Vector3.UP * FLY_HEIGHT
	return Transform3D(_basis_z(_flat(model.global_transform.basis.z)), tip)


# ================================================================ requests

func _request_breath(aim: Variant, model: Node3D, unit: Node3D) -> void:
	if model and _att.has(model):
		var rec: Dictionary = _att[model]
		if _clock - float(rec["breath_t"]) < MERGE_WINDOW:
			var fx: Variant = rec["breath_fx"]
			if fx is Fx and _fx.has(fx) and aim is Vector3:
				_aim(fx as Fx, aim)
			return
		rec["pend_t"] = _clock
		rec["pend_aim"] = aim
		return
	_start_breath(aim, model, unit)


func _request_dive(p: Vector3, model: Node3D, unit: Node3D) -> void:
	var fx := _start_dive(p, model, unit, true)
	if fx and model and _att.has(model):
		(_att[model] as Dictionary)["dive_fx"] = fx


func _request_lash(p: Vector3, model: Node3D, unit: Node3D) -> void:
	if model and _att.has(model):
		var rec: Dictionary = _att[model]
		if _clock - float(rec["lash_t"]) < LASH_WAIT:
			return   # the strike already played for this cast
		var old: Variant = rec["lash_fx"]
		if old is Fx and _fx.has(old) and (old as Fx).land_t < 0.0:
			return   # already winding up
		var fx := _start_lash(p, model, unit)
		if fx:
			fx.deadline = LASH_WAIT
			rec["lash_fx"] = fx
		return
	_start_lash(p, model, unit)


func _request_blizzard(p: Vector3, model: Node3D, unit: Node3D) -> void:
	if model and _att.has(model):
		var rec: Dictionary = _att[model]
		if _clock - float(rec["bliz_t"]) < BLIZ_WAIT or float(rec["bliz_wait_t"]) > -90.0:
			return
		rec["bliz_wait_t"] = _clock
		rec["bliz_at"] = p
		return
	_start_blizzard(p, model, unit)


# ================================================================ rime breath

func _start_breath(aim: Variant, model: Node3D, unit: Node3D) -> Fx:
	var fx := Fx.new()
	fx.kind = K_BREATH
	fx.id = &"wyrm_breath"
	fx.moving_anchors = true
	fx.model = model if _alive_node(model) else null
	fx.unit = unit if _alive_node(unit) else null
	fx.team = _team_of(fx.unit if fx.unit else fx.model)
	fx.variant = _variant_of(fx.unit, fx.model)
	fx.vis = VIS_TARGET
	fx.reach = BREATH_RANGE
	var body: Node3D = fx.unit if fx.unit else fx.model
	var fwd := Vector3(0.0, 0.0, 1.0)
	if body:
		fx.ground = body.global_position
		fwd = _flat(body.global_transform.basis.z)
	elif aim is Vector3:
		fx.ground = (aim as Vector3) - fwd * JET_LAND
	else:
		return null
	fx.dir = fwd
	fx.point = fx.ground + fwd * JET_LAND
	if aim is Vector3:
		_aim(fx, aim)
	fx.mouth = _mouth_of(fx)
	fx.yaw0 = _head_yaw(fx)
	fx.gy = _ground_y()
	fx.dur = 2.8
	var b := fx.variant == 1
	var glow_hot := HOAR if b else FROST_HOT
	var glow := HOAR if b else FROST
	var edge := HOAR_DEEP if b else FROST_TEAM
	var seed := randf() * 10.0
	var jet := _take(fx, &"jet", &"jet")
	var core := _take(fx, &"core", &"jet")
	_params(jet, {&"pattern": 1.0, &"hot_color": _hdr(glow_hot, 2.6), &"mid_color": _hdr(glow, 1.1),
			&"edge_color": _hdr(edge, 0.7), &"cover": _lin(SNOW, 0.6), &"seed": seed, &"density": 1.1})
	_params(core, {&"pattern": 1.0, &"hot_color": _hdr(Color.WHITE, 3.2), &"mid_color": _hdr(glow_hot, 1.9),
			&"edge_color": _hdr(glow, 1.2), &"cover": _lin(Color(0.97, 0.99, 1.0), 0.32), &"seed": seed + 3.3,
			&"density": 1.2})
	var fan := _take(fx, &"fan", &"tground")
	_params(fan, {&"pattern": float(G_FAN_FROST), &"seed": seed, &"radius": fx.reach,
			&"arc": deg_to_rad(BREATH_ARC_DEG * 0.5), &"rim": 0.0, &"rim_at": 1.0, &"heat": 1.0, &"front": 0.0,
			&"glow": _hdr(glow, 1.35), &"cover": _lin(RIME, 0.72)})
	var mg := _take(fx, &"mouth_glow", &"flare")
	_params(mg, {&"tint": _hdr(glow_hot, 1.4), &"rays": 0.0, &"spikes": 4.0, &"pulse": 1.0, &"seed": seed,
			&"halo": Color(0, 0, 0, 0)})
	var sg := _take(fx, &"splash_glow", &"flare")
	_params(sg, {&"tint": _hdr(glow, 0.85), &"rays": 0.0, &"spikes": 6.0, &"pulse": 1.0, &"seed": seed + 1.0,
			&"halo": Color(0, 0, 0, 0)})
	_breath_anchors(fx, fx.mouth, fx.point)
	_stream(fx, &"wyrm_jet", &"mouth", 0.0, JET_TIME)
	_stream(fx, &"wyrm_glints", &"mouth", 0.02, JET_TIME)
	_stream(fx, &"wyrm_splash", &"splash", 0.08, JET_TIME + 0.05)
	_stream(fx, &"wyrm_glints", &"splash", 0.1, JET_TIME + 0.1)
	_sched(fx, &"rime_linger", 0.45, &"smoke")
	_start(fx)
	return fx


## Aims a breath at a ground point: direction from the Wyrm's ground point, the jet lands 3-6 m ahead.
func _aim(fx: Fx, aim: Vector3) -> void:
	var off := aim - fx.ground
	off.y = 0.0
	if off.length() < 0.5:
		return
	fx.dir = off.normalized()
	fx.point = fx.ground + fx.dir * clampf(off.length(), 3.0, 6.0)


## The mouth: the head point pushed forward along the breath (the jaw is ahead of the head joint).
func _mouth_of(fx: Fx) -> Vector3:
	if _alive_node(fx.model) and fx.model.has_method(&"get_head_point"):
		var h: Vector3 = fx.model.call(&"get_head_point")
		return h + fx.dir * 0.85 - Vector3.UP * 0.1
	if _alive_node(fx.unit):
		fx.ground = fx.unit.global_position
		return fx.ground + Vector3.UP * (FLY_HEIGHT + 0.6) + fx.dir * 2.6
	if fx.mouth != Vector3.ZERO:
		return fx.mouth
	return fx.ground + Vector3.UP * (FLY_HEIGHT + 0.6) + fx.dir * 2.6


## Yaw of the head around the Wyrm's ground point (the breath sweep), 0 when the head is too close to measure.
func _head_yaw(fx: Fx) -> float:
	var off := fx.mouth - fx.ground
	off.y = 0.0
	return atan2(off.x, off.z) if off.length() > 1.0 else 0.0


func _tick_breath(fx: Fx) -> void:
	var t := fx.t
	if t > JET_TIME + 0.35 and fx.t_last_full > JET_TIME + 0.35:
		var fan0: GeometryInstance3D = fx.nodes.get(&"fan")
		if fan0:
			var fade0 := 1.0 - smoothstep(fx.dur - 0.9, fx.dur - 0.05, t)
			_uf(fan0, &"heat", 1.0 - smoothstep(JET_TIME + 0.05, JET_TIME + 1.1, t))
			_uf(fan0, &"fade", fade0)
			_vis(fan0, fx.shown and fade0 > 0.002)
		return
	fx.t_last_full = t
	var live := _alive_node(fx.model) or _alive_node(fx.unit)
	fx.mouth = _mouth_of(fx)
	var dyaw := 0.0
	var hy := _head_yaw(fx)
	if live and hy != 0.0 and fx.yaw0 != 0.0:
		dyaw = clampf(wrapf(hy - fx.yaw0, -PI, PI), -0.45, 0.45) * 0.8
	var off := fx.point - fx.ground
	off.y = 0.0
	var e := fx.ground + off.rotated(Vector3.UP, dyaw)
	e.y = fx.ground.y + 0.05
	var m := fx.mouth
	var grow := _ease_out(clampf(t / 0.1, 0.0, 1.0))
	var tail := clampf((t - JET_TIME) / 0.18, 0.0, 1.0)
	var widen := _ease_out(clampf(t / 0.2, 0.0, 1.0))
	var er := lerpf(0.55, 2.1, widen)
	var jet_on := t < JET_TIME + 0.2
	_place_jet(fx, &"jet", m, e, er, grow, tail, jet_on)
	_place_jet(fx, &"core", m, e, er * 0.42, grow, minf(1.0, tail * 1.3), jet_on)
	var fan: GeometryInstance3D = fx.nodes.get(&"fan")
	if fan:
		var front := _ease_out(clampf((t - 0.05) / 0.32, 0.0, 1.0))
		var heat := 1.0 - smoothstep(JET_TIME + 0.05, JET_TIME + 1.1, t)
		var fade := 1.0 - smoothstep(fx.dur - 0.9, fx.dur - 0.05, t)
		var fan_dir := off.rotated(Vector3.UP, dyaw * 0.5).normalized() if off.length() > 0.01 else fx.dir
		_xf(fan, Transform3D(Basis(Vector3.UP, _yaw_x(fan_dir)) * Basis.from_scale(Vector3(fx.reach, 1.0, fx.reach)),
				fx.ground + Vector3.UP * fx.gy))
		_uf(fan, &"front", front)
		_uf(fan, &"heat", heat)
		_uf(fan, &"fade", fade)
		_vis(fan, fx.shown and fade > 0.002 and t >= 0.05)
	var zdir := (e - m).normalized() if (e - m).length() > 0.01 else Vector3.DOWN
	var mg: GeometryInstance3D = fx.nodes.get(&"mouth_glow")
	if mg:
		var k := clampf(t / 0.05, 0.0, 1.0) * (1.0 - smoothstep(JET_TIME - 0.05, JET_TIME + 0.12, t))
		var s := 1.05 * (1.0 + 0.12 * sin(t * 47.0))
		_xf(mg, Transform3D(Basis.from_scale(Vector3.ONE * s), m + zdir * 0.25))
		_uf(mg, &"fade", k)
		_vis(mg, fx.shown and k > 0.002)
	var sg: GeometryInstance3D = fx.nodes.get(&"splash_glow")
	if sg:
		var k2 := smoothstep(0.04, 0.12, t) * (1.0 - smoothstep(JET_TIME, JET_TIME + 0.3, t))
		var s2 := 2.5 * (1.0 + 0.1 * sin(t * 31.0))
		_xf(sg, Transform3D(Basis.from_scale(Vector3.ONE * s2), e + Vector3.UP * 0.6))
		_uf(sg, &"fade", k2 * 0.8)
		_vis(sg, fx.shown and k2 > 0.002)
	_breath_anchors(fx, m, e)


func _breath_anchors(fx: Fx, m: Vector3, e: Vector3) -> void:
	var zdir := (e - m).normalized() if (e - m).length() > 0.01 else Vector3.DOWN
	fx.anchors[&"mouth"] = Transform3D(_basis_z(zdir), m)
	var sdir := _flat(e - fx.ground) if Vector2(e.x - fx.ground.x, e.z - fx.ground.z).length() > 0.1 else fx.dir
	fx.anchors[&"splash"] = Transform3D(_basis_z(sdir), fx.ground + sdir * fx.reach * 0.55 + Vector3.UP * 0.15)
	fx.anchors[&"smoke"] = Transform3D(_basis_z(sdir), fx.ground + sdir * fx.reach * 0.55 + Vector3.UP * 0.9)


func _place_jet(fx: Fx, role: StringName, m: Vector3, e: Vector3, er: float, grow: float, tail: float,
		on: bool) -> void:
	var n: GeometryInstance3D = fx.nodes.get(role)
	if n == null:
		return
	var d := e - m
	var dl := d.length()
	if dl < 0.1 or not on:
		_vis(n, false)
		return
	var z := d / dl
	var up := Vector3.UP if absf(z.y) < 0.97 else Vector3.FORWARD
	var x := up.cross(z).normalized()
	var y := z.cross(x)
	_xf(n, Transform3D(Basis(x * er, y * er, z * dl * 1.04), m))
	_uf(n, &"grow", grow)
	_uf(n, &"tail", tail)
	_uf(n, &"fade", 1.0 - smoothstep(JET_TIME + 0.1, JET_TIME + 0.2, fx.t))
	_vis(n, fx.shown)


# ================================================================ glacial dive

## A dive: the telegraph ring now (`telegraph`), the ice burst when it lands (_land_dive).
func _start_dive(p: Vector3, model: Node3D, unit: Node3D, telegraph: bool) -> Fx:
	var fx := Fx.new()
	fx.kind = K_DIVE
	fx.id = &"wyrm_dive"
	fx.model = model if _alive_node(model) else null
	fx.unit = unit if _alive_node(unit) else null
	fx.team = _team_of(fx.unit if fx.unit else fx.model)
	fx.variant = _variant_of(fx.unit, fx.model)
	fx.vis = VIS_POINT
	fx.point = p
	fx.dur = 99.0
	fx.deadline = DIVE_TELEGRAPH + (0.5 if fx.model and _att.has(fx.model) else 0.0)
	var b := fx.variant == 1
	var seed := randf() * 10.0
	if telegraph:
		var tele := _take(fx, &"tele", &"wground")
		if tele:
			var rr := DIVE_RADIUS
			tele.transform = Transform3D(Basis.from_scale(Vector3(rr, 1.0, rr)), p + Vector3.UP * (_ground_y() + 0.02))
			_params(tele, {&"pattern": float(W_TELE), &"seed": seed, &"radius": rr, &"front": 0.0, &"fade": 0.0,
					&"glow": _hdr(HOAR if b else FROST, 1.35), &"cover": _lin(RIME, 0.62)})
		fx.anchors[&"tele"] = Transform3D(Basis.IDENTITY, p + Vector3.UP * 0.1)
		_stream(fx, &"tele_motes", &"tele", 0.0, DIVE_TELEGRAPH)
	else:
		fx.deadline = 0.0
	# The burst pieces are taken now (no allocation later) and shown on landing.
	var crater := _take(fx, &"crater", &"tground")
	if crater:
		var size := 3.6
		crater.transform = Transform3D(Basis(Vector3.UP, randf() * TAU) * Basis.from_scale(Vector3(size, 1.0, size)),
				p + Vector3.UP * _ground_y())
		_params(crater, {&"pattern": float(G_CRATER_ICE), &"seed": seed, &"radius": size, &"rim": 0.0, &"rim_at": 0.9,
				&"arc": 0.5, &"heat": 1.0, &"front": 0.0, &"fade": 0.0,
				&"glow": _hdr(HOAR if b else FROST_HOT, 1.35), &"cover": _lin(Color(0.7, 0.84, 0.95), 0.8)})
	var shock := _take(fx, &"shock", &"ring")
	if shock:
		shock.transform = Transform3D(Basis.IDENTITY, p + Vector3.UP * _ground_y())
		_params(shock, {&"pattern": float(R_SHOCK), &"seed": seed, &"tint": _hdr(HOAR if b else FROST_HOT, 1.2)})
	var dust := _take(fx, &"dust_ring", &"ring")
	if dust:
		dust.transform = Transform3D(Basis.from_scale(Vector3(2.4, 1.0, 2.4)), p + Vector3.UP * _ground_y())
		_params(dust, {&"pattern": float(R_SOOT), &"seed": seed + 2.0, &"tint": _lin(SNOW)})
	var flash := _take(fx, &"flash", &"flare")
	_params(flash, {&"tint": _hdr(HOAR if b else FROST_HOT, 1.3), &"rays": 0.6, &"spikes": 8.0, &"pulse": 0.0,
			&"seed": seed, &"halo": Color(0, 0, 0, 0)})
	var crown := _take(fx, &"crown", &"crown")
	_params(crown, {&"glow": _hdr(HOAR if b else FROST, 0.9), &"melt": 0.0, &"seed": seed, &"frost": 0.0})
	var crown2 := _take(fx, &"crown2", &"crown")
	_params(crown2, {&"glow": _hdr(HOAR if b else FROST, 1.1), &"melt": 0.0, &"seed": seed + 4.0, &"frost": 0.4})
	fx.a0 = randf() * TAU
	fx.anchors[&"impact"] = Transform3D(Basis.IDENTITY, p + Vector3.UP * 0.3)
	fx.anchors[&"ground"] = Transform3D(Basis.IDENTITY, p + Vector3.UP * 0.7)
	fx.anchors[&"crown"] = Transform3D(Basis.IDENTITY, p + Vector3.UP * 1.1)
	_start(fx)
	return fx


func _land_dive(fx: Fx) -> void:
	if fx.land_t >= 0.0:
		return
	fx.land_t = fx.t
	fx.dur = fx.t + 4.2
	var on := fx.t
	_sched(fx, &"snow_dust", on, &"ground")
	_sched(fx, &"ice_shards", on, &"impact")
	_sched(fx, &"ice_glints", on + 0.03, &"impact")
	_sched(fx, &"cold_mist", on + 0.15, &"ground")
	_sched(fx, &"ice_shards", on + 1.05, &"crown")   # the crown shatters
	_sched(fx, &"ice_glints", on + 1.1, &"crown")


func _tick_dive(fx: Fx) -> void:
	var t := fx.t
	if fx.land_t < 0.0 and t >= fx.deadline:
		_land_dive(fx)
	var tele: GeometryInstance3D = fx.nodes.get(&"tele")
	if tele:
		var fin := clampf(t / 0.08, 0.0, 1.0)
		var fo := 1.0
		var k := clampf(t / DIVE_TELEGRAPH, 0.0, 1.0)
		if fx.land_t >= 0.0:
			fo = 1.0 - clampf((t - fx.land_t) / 0.12, 0.0, 1.0)
			k = 1.0
		_uf(tele, &"front", k)
		_uf(tele, &"fade", fin * fo)
		_vis(tele, fx.shown and fin * fo > 0.002)
	if fx.land_t < 0.0:
		return
	var lt := t - fx.land_t
	var p := fx.point
	var crater: GeometryInstance3D = fx.nodes.get(&"crater")
	if crater:
		var fade := clampf(lt / 0.05, 0.0, 1.0) * (1.0 - smoothstep(3.0, 4.1, lt))
		_uf(crater, &"front", _ease_out(clampf(lt / 0.14, 0.0, 1.0)))
		_uf(crater, &"heat", 1.0 - smoothstep(0.4, 3.4, lt))
		_uf(crater, &"fade", fade)
		_vis(crater, fx.shown and fade > 0.002)
	var shock: GeometryInstance3D = fx.nodes.get(&"shock")
	if shock:
		var r := lerpf(1.0, DIVE_RADIUS + 2.4, _ease_out(clampf(lt / 0.45, 0.0, 1.0)))
		var f := clampf(lt / 0.03, 0.0, 1.0) * (1.0 - smoothstep(0.2, 0.55, lt))
		_xf(shock, Transform3D(Basis.from_scale(Vector3(r, 1.0, r)), shock.transform.origin))
		_uf(shock, &"radius", r)
		_uf(shock, &"fade", f)
		_uf(shock, &"age", minf(lt, 1.05))
		_vis(shock, fx.shown and f > 0.002)
	var dust: GeometryInstance3D = fx.nodes.get(&"dust_ring")
	if dust:
		var r2 := lerpf(2.4, 5.0, _ease_out(clampf(lt / 1.0, 0.0, 1.0)))
		var f2 := clampf(lt / 0.1, 0.0, 1.0) * 0.5 * (1.0 - smoothstep(0.6, 1.5, lt))
		_xf(dust, Transform3D(Basis.from_scale(Vector3(r2, 1.0, r2)), dust.transform.origin))
		_uf(dust, &"radius", r2)
		_uf(dust, &"fade", f2)
		_vis(dust, fx.shown and f2 > 0.002)
	var flash: GeometryInstance3D = fx.nodes.get(&"flash")
	if flash:
		var s := lerpf(2.5, 5.2, _ease_out(clampf(lt / 0.1, 0.0, 1.0)))
		var f3 := 1.0 - smoothstep(0.05, 0.3, lt)
		_xf(flash, Transform3D(Basis.from_scale(Vector3.ONE * s), p + Vector3.UP * 1.2))
		_uf(flash, &"fade", f3)
		_vis(flash, fx.shown and f3 > 0.002)
	# The ice crown erupts (0.12 s, a little overshoot), holds, shatters from the tips (1.0 .. 1.5 s).
	for role: StringName in [&"crown", &"crown2"]:
		var cr: GeometryInstance3D = fx.nodes.get(role)
		if cr == null:
			continue
		var big := role == &"crown"
		var rise := _ease_back(clampf((lt - (0.0 if big else 0.05)) / 0.14, 0.0, 1.0))
		var melt := smoothstep(1.0 if big else 0.9, 1.55 if big else 1.4, lt)
		var sc := Vector3(2.35, 1.55, 2.35) if big else Vector3(1.15, 1.05, 1.15)
		var drop := (1.0 - rise) * sc.y * 1.6
		var yaw := fx.a0 + (0.0 if big else 0.45)
		_xf(cr, Transform3D(Basis(Vector3.UP, yaw) * Basis.from_scale(sc), p - Vector3.UP * drop))
		_uf(cr, &"melt", melt)
		_vis(cr, fx.shown and rise > 0.01 and melt < 0.999)


# ================================================================ tail lash

func _start_lash(c: Vector3, model: Node3D, unit: Node3D) -> Fx:
	var fx := Fx.new()
	fx.kind = K_LASH
	fx.id = &"wyrm_tail"
	fx.model = model if _alive_node(model) else null
	fx.unit = unit if _alive_node(unit) else null
	fx.team = _team_of(fx.unit if fx.unit else fx.model)
	fx.variant = _variant_of(fx.unit, fx.model)
	fx.vis = VIS_TARGET
	fx.point = c
	fx.dur = 99.0
	fx.deadline = LASH_WINDUP
	fx.moving_anchors = true
	var b := fx.variant == 1
	var seed := randf() * 10.0
	var arc := _take(fx, &"arc", &"wground")
	if arc:
		var rr := LASH_RADIUS + 0.3
		arc.transform = Transform3D(Basis.from_scale(Vector3(rr, 1.0, rr)), c + Vector3.UP * _ground_y())
		_params(arc, {&"pattern": float(W_ARC), &"seed": seed, &"radius": rr, &"front": 0.0, &"fade": 0.0,
				&"glow": _hdr(HOAR if b else FROST_HOT, 1.4), &"cover": _lin(RIME, 0.7)})
	var ring := _take(fx, &"ring", &"ring")
	if ring:
		ring.transform = Transform3D(Basis.IDENTITY, c + Vector3.UP * _ground_y())
		_params(ring, {&"pattern": float(R_SHOCK), &"seed": seed, &"tint": _hdr(HOAR if b else FROST, 0.8)})
	var flash := _take(fx, &"flash", &"flare")
	_params(flash, {&"tint": _hdr(HOAR if b else FROST_HOT, 1.25), &"rays": 0.4, &"spikes": 6.0, &"pulse": 0.0,
			&"seed": seed, &"halo": Color(0, 0, 0, 0)})
	fx.anchors[&"tip"] = Transform3D(Basis.IDENTITY, _tip_of(fx))
	fx.anchors[&"centre"] = Transform3D(Basis.IDENTITY, c + Vector3.UP * 0.4)
	_stream(fx, &"lash_windup", &"tip", 0.0, LASH_WAIT)
	_start(fx)
	return fx


func _tip_of(fx: Fx) -> Vector3:
	if _alive_node(fx.model) and fx.model.has_method(&"get_tail_tip"):
		var tip: Vector3 = fx.model.call(&"get_tail_tip")
		return Vector3(tip.x, maxf(tip.y, fx.point.y + 0.2), tip.z)
	return fx.point + Vector3(LASH_RADIUS, 0.3, 0.0)


## The strike: the arc sweeps ~200 deg round the Wyrm and ends at `at` (the tail's side, in its direction).
func _strike_lash(fx: Fx, at: Vector3) -> void:
	if fx.land_t >= 0.0:
		return
	fx.land_t = fx.t
	fx.dur = fx.t + 1.15
	for s in fx.streams:
		s["off"] = minf(float(s["off"]), fx.t)
	var c := fx.point
	var body: Node3D = fx.unit if _alive_node(fx.unit) else (fx.model if _alive_node(fx.model) else null)
	if body:
		c = body.global_position
		fx.point = c
	var d := Vector3(at.x - c.x, 0.0, at.z - c.z)
	if d.length() < 0.3:
		d = Vector3(LASH_RADIUS, 0.0, 0.0)
	var end := atan2(d.z, d.x)
	# Sweep direction from the tail tip's motion (angle grows from +X toward +Z), else counter-clockwise.
	var sgn := 1.0
	if fx.model and _att.has(fx.model):
		var rec: Dictionary = _att[fx.model]
		var tip: Vector3 = rec["tip"]
		var prev: Vector3 = rec["prev_tip"]
		var r := Vector2(tip.x - c.x, tip.z - c.z)
		var v := Vector2(tip.x - prev.x, tip.z - prev.z)
		var cr := r.x * v.y - r.y * v.x
		if absf(cr) > 0.0001:
			sgn = signf(cr)
	fx.a0 = end - sgn * deg_to_rad(LASH_SWEEP_DEG - 20.0)
	fx.a1 = end + sgn * deg_to_rad(20.0)
	fx.strike = Vector3(at.x, c.y, at.z)
	var arc: GeometryInstance3D = fx.nodes.get(&"arc")
	if arc:
		arc.transform = Transform3D(arc.transform.basis, Vector3(c.x, arc.transform.origin.y, c.z))
		_params(arc, {&"a0": fx.a0, &"a1": fx.a1})
	var ring: GeometryInstance3D = fx.nodes.get(&"ring")
	if ring:
		ring.transform = Transform3D(ring.transform.basis, Vector3(c.x, ring.transform.origin.y, c.z))
	fx.anchors[&"centre"] = Transform3D(Basis.IDENTITY, c + Vector3.UP * 0.35)
	var dn := d.normalized()
	fx.anchors[&"strike"] = Transform3D(_basis_z(Vector3(-dn.z, 0.0, dn.x) * sgn), c + dn * LASH_RADIUS * 0.9
			+ Vector3.UP * 0.4)
	var on := fx.t
	_sched(fx, &"lash_spray_a" if sgn > 0.0 else &"lash_spray_b", on + 0.02, &"centre")
	_sched(fx, &"lash_chips", on + 0.1, &"strike")
	_sched(fx, &"ice_glints", on + 0.12, &"strike")


func _tick_lash(fx: Fx) -> void:
	var t := fx.t
	if fx.land_t < 0.0:
		fx.anchors[&"tip"] = Transform3D(Basis.IDENTITY, _tip_of(fx))
		if t >= fx.deadline:
			_strike_lash(fx, _tip_of(fx))
		if fx.land_t < 0.0:
			return
	var ls := t - fx.land_t
	var arc: GeometryInstance3D = fx.nodes.get(&"arc")
	if arc:
		var fade := clampf(ls / 0.04, 0.0, 1.0) * (1.0 - smoothstep(0.55, 1.1, ls))
		_uf(arc, &"front", _ease_out(clampf(ls / 0.17, 0.0, 1.0)))
		_uf(arc, &"fade", fade)
		_vis(arc, fx.shown and fade > 0.002)
	var ring: GeometryInstance3D = fx.nodes.get(&"ring")
	if ring:
		var r := lerpf(1.6, LASH_RADIUS + 0.9, _ease_out(clampf((ls - 0.08) / 0.35, 0.0, 1.0)))
		var f := clampf((ls - 0.08) / 0.05, 0.0, 1.0) * (1.0 - smoothstep(0.25, 0.55, ls)) * 0.6
		_xf(ring, Transform3D(Basis.from_scale(Vector3(r, 1.0, r)), ring.transform.origin))
		_uf(ring, &"radius", r)
		_uf(ring, &"fade", f)
		_uf(ring, &"age", minf(ls, 1.05))
		_vis(ring, fx.shown and f > 0.002)
	var flash: GeometryInstance3D = fx.nodes.get(&"flash")
	if flash:
		var k := clampf((ls - 0.1) / 0.04, 0.0, 1.0) * (1.0 - smoothstep(0.16, 0.36, ls))
		var s := lerpf(1.4, 2.6, _ease_out(clampf((ls - 0.1) / 0.12, 0.0, 1.0)))
		_xf(flash, Transform3D(Basis.from_scale(Vector3.ONE * s), fx.strike + Vector3.UP * 0.8))
		_uf(flash, &"fade", k)
		_vis(flash, fx.shown and k > 0.002)


# ================================================================ blizzard

func _start_blizzard(c: Vector3, model: Node3D, unit: Node3D) -> Fx:
	var fx := Fx.new()
	fx.kind = K_BLIZ
	fx.id = &"wyrm_blizzard"
	fx.model = model if _alive_node(model) else null
	fx.unit = unit if _alive_node(unit) else null
	fx.team = _team_of(fx.unit if fx.unit else fx.model)
	fx.variant = _variant_of(fx.unit, fx.model)
	fx.vis = VIS_TARGET
	fx.point = c
	fx.dur = BLIZZARD_TIME + 1.0
	fx.moving_anchors = true
	fx.gy = _ground_y()
	var glow := HOAR if fx.variant == 1 else FROST   # the Blizzard is Old Hoarfang's: white-violet in the game
	var seed := randf() * 10.0
	var wall := _take(fx, &"wall", &"storm")
	_params(wall, {&"tint": _hdr(glow, 0.55), &"cover": _lin(SNOW, 0.78), &"seed": seed, &"spin": 1.0,
			&"density": 1.0, &"fade": 0.0})
	var inner := _take(fx, &"inner", &"storm")
	_params(inner, {&"tint": _hdr(glow, 0.45), &"cover": _lin(Color(0.9, 0.95, 1.0), 0.42), &"seed": seed + 2.0,
			&"spin": 1.6, &"density": 0.8, &"fade": 0.0})
	var floor_n := _take(fx, &"floor", &"wground")
	_params(floor_n, {&"pattern": float(W_BLIZ), &"seed": seed, &"radius": BLIZZARD_RADIUS, &"front": 0.0,
			&"fade": 0.0, &"spin": 1.0, &"glow": _hdr(glow, 1.0), &"cover": _lin(Color(0.88, 0.93, 0.99), 0.75)})
	var ring := _take(fx, &"release", &"ring")
	_params(ring, {&"pattern": float(R_SHOCK), &"seed": seed, &"tint": _hdr(glow, 1.1)})
	var flash := _take(fx, &"flash", &"flare")
	_params(flash, {&"tint": _hdr(glow, 1.3), &"rays": 0.7, &"spikes": 8.0, &"pulse": 0.0, &"seed": seed,
			&"halo": Color(0, 0, 0, 0)})
	_bliz_anchors(fx, c)
	_stream(fx, &"bliz_snow", &"centre", 0.05, BLIZZARD_TIME)
	_stream(fx, &"bliz_flakes", &"high", 0.1, BLIZZARD_TIME)
	_stream(fx, &"bliz_ground", &"centre", 0.2, BLIZZARD_TIME)
	_sched(fx, &"bliz_burst", 0.0, &"centre")
	_sched(fx, &"ice_glints", 0.05, &"head")
	_start(fx)
	return fx


func _bliz_anchors(fx: Fx, c: Vector3) -> void:
	fx.anchors[&"centre"] = Transform3D(Basis.IDENTITY, c + Vector3.UP * 0.4)
	fx.anchors[&"high"] = Transform3D(Basis.IDENTITY, c + Vector3.UP * 6.0)
	fx.anchors[&"head"] = Transform3D(Basis.IDENTITY, c + Vector3.UP * 4.5)


func _tick_bliz(fx: Fx) -> void:
	var t := fx.t
	var body: Node3D = fx.unit if _alive_node(fx.unit) else (fx.model if _alive_node(fx.model) else null)
	if body:
		fx.point = body.global_position
		if fx.end_at < 0.0 and body.has_method(&"is_alive") and not bool(body.call(&"is_alive")):
			_stop(fx)
	var c := fx.point   # a Wyrm that left the tree: the storm keeps its last spot and runs out
	_bliz_anchors(fx, c)
	var k_in := _ease_out(clampf(t / 0.7, 0.0, 1.0))
	var end := fx.end_at if fx.end_at >= 0.0 else BLIZZARD_TIME
	var fo := 1.0 - clampf((t - end) / 0.9, 0.0, 1.0)
	var fin := clampf(t / 0.35, 0.0, 1.0)
	var f := fin * fo
	var wall: GeometryInstance3D = fx.nodes.get(&"wall")
	if wall:
		var r := BLIZZARD_RADIUS * lerpf(0.3, 1.0, k_in)
		var h := BLIZZARD_HEIGHT * lerpf(0.35, 1.0, k_in)
		_xf(wall, Transform3D(Basis.from_scale(Vector3(r, h, r)), c + Vector3.UP * (h * 0.5 - 0.3)))
		_uf(wall, &"fade", f)
		_vis(wall, fx.shown and f > 0.002)
	var inner: GeometryInstance3D = fx.nodes.get(&"inner")
	if inner:
		var r2 := 4.6 * lerpf(0.3, 1.0, k_in)
		var h2 := 5.2 * lerpf(0.35, 1.0, k_in)
		_xf(inner, Transform3D(Basis.from_scale(Vector3(r2, h2, r2)), c + Vector3.UP * (h2 * 0.5 - 0.3)))
		_uf(inner, &"fade", f * 0.9)
		_vis(inner, fx.shown and f > 0.002)
	var fl: GeometryInstance3D = fx.nodes.get(&"floor")
	if fl:
		_xf(fl, Transform3D(Basis.from_scale(Vector3(BLIZZARD_RADIUS, 1.0, BLIZZARD_RADIUS)), c + Vector3.UP * fx.gy))
		_uf(fl, &"front", _ease_out(clampf(t / 0.9, 0.0, 1.0)))
		_uf(fl, &"fade", f)
		_vis(fl, fx.shown and f > 0.002)
	var ring: GeometryInstance3D = fx.nodes.get(&"release")
	if ring:
		var rr := lerpf(1.0, BLIZZARD_RADIUS + 0.6, _ease_out(clampf(t / 0.6, 0.0, 1.0)))
		var fr := clampf(t / 0.04, 0.0, 1.0) * (1.0 - smoothstep(0.3, 0.75, t))
		_xf(ring, Transform3D(Basis.from_scale(Vector3(rr, 1.0, rr)), c + Vector3.UP * (fx.gy + 0.01)))
		_uf(ring, &"radius", rr)
		_uf(ring, &"fade", fr)
		_uf(ring, &"age", minf(t, 1.05))
		_vis(ring, fx.shown and fr > 0.002)
	var flash: GeometryInstance3D = fx.nodes.get(&"flash")
	if flash:
		var head := c + Vector3.UP * 4.8
		if _alive_node(fx.model) and fx.model.has_method(&"get_head_point"):
			head = fx.model.call(&"get_head_point")
		var s := lerpf(2.5, 5.5, _ease_out(clampf(t / 0.15, 0.0, 1.0)))
		var k := 1.0 - smoothstep(0.08, 0.4, t)
		_xf(flash, Transform3D(Basis.from_scale(Vector3.ONE * s), head))
		_uf(flash, &"fade", k)
		_vis(flash, fx.shown and k > 0.002)


## Stops an effect early (fades out over its own tail).
func _stop(fx: Fx) -> void:
	if fx.end_at >= 0.0:
		return
	fx.end_at = fx.t
	fx.dur = minf(fx.dur, fx.t + 1.0)
	for s in fx.streams:
		s["off"] = minf(float(s["off"]), fx.t)


# ================================================================ pre-spawn warning

func _start_warning(p: Vector3) -> void:
	for other in _fx:
		if other.kind == K_WARN and other.end_at < 0.0 and other.t < WARNING_TIME \
				and Vector2(other.point.x - p.x, other.point.z - p.z).length() < 3.0:
			return   # the same warning twice
	var fx := Fx.new()
	fx.kind = K_WARN
	fx.id = &"wyrm_warning"
	fx.vis = VIS_ALWAYS
	fx.point = p
	fx.dur = WARNING_TIME + WARNING_LINGER
	fx.gy = _ground_y()
	var seed := randf() * 10.0
	var m1 := _take(fx, &"mist", &"wground")
	if m1:
		m1.transform = Transform3D(Basis.from_scale(Vector3(WARNING_RADIUS, 1.0, WARNING_RADIUS)),
				p + Vector3.UP * (fx.gy + 0.05))
		_params(m1, {&"pattern": float(W_MIST), &"seed": seed, &"radius": WARNING_RADIUS, &"front": 0.0,
				&"fade": 0.0, &"spin": 1.0, &"glow": _hdr(FROST, 1.1), &"cover": _lin(Color(0.84, 0.9, 0.97), 0.5)})
	var m2 := _take(fx, &"mist2", &"wground")
	if m2:
		m2.transform = Transform3D(Basis.from_scale(Vector3(6.0, 1.0, 6.0)), p + Vector3.UP * (fx.gy + 0.35))
		_params(m2, {&"pattern": float(W_MIST), &"seed": seed + 3.0, &"radius": 6.0, &"front": 0.0,
				&"fade": 0.0, &"spin": -1.3, &"glow": _hdr(FROST_HOT, 0.9), &"cover": _lin(SNOW, 0.35)})
	var pulse := _take(fx, &"pulse", &"ring")
	if pulse:
		pulse.transform = Transform3D(Basis.IDENTITY, p + Vector3.UP * (fx.gy + 0.4))
		_params(pulse, {&"pattern": float(R_WIND), &"seed": seed, &"tint": _hdr(FROST, 1.2)})
	fx.anchors[&"low"] = Transform3D(Basis.IDENTITY, p + Vector3.UP * 0.3)
	fx.anchors[&"vapour"] = Transform3D(Basis.IDENTITY, p + Vector3.UP * 0.1)
	fx.anchors[&"pulse"] = Transform3D(Basis.IDENTITY, p + Vector3.UP * 1.0)
	_stream(fx, &"warn_mist", &"low", 0.0, WARNING_TIME + 0.5)
	_stream(fx, &"warn_vapour", &"vapour", 1.0, WARNING_TIME)
	_sched(fx, &"warn_glints", WARNING_TIME, &"pulse")
	_start(fx)


func _tick_warn(fx: Fx) -> void:
	var t := fx.t
	var W := WARNING_TIME
	var fo := 1.0 - smoothstep(W, W + WARNING_LINGER, t)
	var ramp := lerpf(0.3, 1.0, clampf(t / 20.0, 0.0, 1.0))
	for role: StringName in [&"mist", &"mist2"]:
		var m: GeometryInstance3D = fx.nodes.get(role)
		if m == null:
			continue
		var f := clampf(t / 3.0, 0.0, 1.0) * fo * (lerpf(0.55, 1.0, clampf(t / 20.0, 0.0, 1.0)))
		_uf(m, &"front", _ease_out(clampf(t / (8.0 if role == &"mist" else 12.0), 0.0, 1.0)))
		_uf(m, &"fade", f)
		_vis(m, fx.shown and f > 0.002)
	var pulse: GeometryInstance3D = fx.nodes.get(&"pulse")
	if pulse:
		var pt := t - W
		var r := lerpf(2.0, WARNING_RADIUS + 0.5, _ease_out(clampf(pt / 1.2, 0.0, 1.0)))
		var f2 := clampf(pt / 0.08, 0.0, 1.0) * (1.0 - smoothstep(0.6, 1.4, pt)) if pt >= 0.0 else 0.0
		_xf(pulse, Transform3D(Basis.from_scale(Vector3(r, 1.0, r)), pulse.transform.origin))
		_uf(pulse, &"radius", r)
		_uf(pulse, &"fade", f2)
		_uf(pulse, &"age", clampf(pt, 0.0, 1.05))
		_vis(pulse, fx.shown and f2 > 0.002)
	for s in fx.streams:
		if int(s["state"]) == 1:
			(s["p"] as GPUParticles3D).amount_ratio = ramp


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
		K_BREATH:
			_tick_breath(fx)
		K_DIVE:
			_tick_dive(fx)
		K_LASH:
			_tick_lash(fx)
		K_BLIZ:
			_tick_bliz(fx)
		_:
			_tick_warn(fx)
	var busy := _tick_streams(fx)
	if fx.bursts_left > 0:
		for b in fx.bursts:
			if b["done"] or fx.t < float(b["on"]):
				continue
			b["done"] = true
			fx.bursts_left -= 1
			if fx.shown:
				_burst(b["look"], fx.anchors.get(b["at"], Transform3D(Basis.IDENTITY, fx.point)))
	return fx.t >= fx.dur and not busy and fx.bursts_left <= 0


## Streams start at `on`, follow their anchor, stop at `off`; then their last particles drain. True while one runs.
func _tick_streams(fx: Fx) -> bool:
	var busy := false
	for s in fx.streams:
		var st := int(s["state"])
		if st >= 2:
			continue
		var stop := fx.t >= float(s["off"])
		if st == 0:
			if stop:
				s["state"] = 2
				continue
			busy = true
			if fx.t < float(s["on"]):
				continue
			var free: Array = _stream_free[s["look"]]
			if free.is_empty():
				s["state"] = 2   # pool exhausted: skipped
				continue
			var p: GPUParticles3D = free.pop_back()
			s["p"] = p
			p.transform = fx.anchors.get(s["at"], Transform3D(Basis.IDENTITY, fx.point))
			p.visible = fx.shown
			p.amount_ratio = 1.0
			p.restart()
			p.emitting = true
			s["state"] = 1
			continue
		var pe: GPUParticles3D = s["p"]
		if stop:
			pe.emitting = false
			_draining.append({"p": pe, "look": s["look"], "left": pe.lifetime + 0.1})
			s["state"] = 2
			continue
		busy = true
		if fx.moving_anchors:
			pe.transform = fx.anchors.get(s["at"], pe.transform)
		if pe.visible != fx.shown:
			pe.visible = fx.shown
	return busy


func _finish(fx: Fx) -> void:
	for role: StringName in fx.nodes:
		var n: GeometryInstance3D = fx.nodes[role]
		n.visible = false
		n.set_instance_shader_parameter(&"fade", 0.0)
		(_free[fx.pools[role]] as Array).append(n)
	fx.nodes.clear()
	for s in fx.streams:
		if int(s["state"]) == 1:
			var p: GPUParticles3D = s["p"]
			p.emitting = false
			_draining.append({"p": p, "look": s["look"], "left": p.lifetime + 0.1})
			s["state"] = 2
	fx.streams.clear()


## Fog / hidden Wyrms (4 times per second).
func _refresh(fx: Fx) -> void:
	match fx.vis:
		VIS_ALWAYS:
			fx.shown = true
			return
		VIS_TARGET:
			var n: Node3D = fx.unit if _alive_node(fx.unit) else (fx.model if _alive_node(fx.model) else null)
			if n:
				fx.shown = n.is_visible_in_tree()
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


func _stream(fx: Fx, look: StringName, at: StringName, on: float, off: float) -> void:
	fx.streams.append({"look": look, "at": at, "on": on, "off": off, "state": 0, "p": null})


func _sched(fx: Fx, look: StringName, on: float, at: StringName) -> void:
	fx.bursts.append({"look": look, "on": on, "at": at, "done": false})
	fx.bursts_left += 1


func _burst(look: StringName, xf: Transform3D) -> void:
	var pool: Array = _bursts[look]
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

func _is_wyrm(n: Object) -> bool:
	return n.has_signal(&"dive_landed") and n.has_signal(&"tail_struck") and n.has_signal(&"blizzard_released") \
			and n.has_signal(&"breath_released")


## [model, unit] for a target that is a Wyrm model, a Unit with such a model, or any other node (its own unit).
func _resolve(t: Node3D) -> Array:
	if t == null:
		return [null, null]
	if _is_wyrm(t):
		if not _att.has(t):
			attach(t)
		return [t, _unit_of(t)]
	if t.has_method(&"get_model"):
		var m: Variant = t.call(&"get_model")
		if m is Node3D and is_instance_valid(m) and _is_wyrm(m):
			if not _att.has(m):
				attach(m)
			return [m, t]
	for c: Node in t.get_children():
		if c is Node3D and _is_wyrm(c):
			if not _att.has(c):
				attach(c as Node3D)
			return [c, t]
	return [null, t]


## The Unit carrying a model: the nearest ancestor with a `team` (cached on the attach record).
func _unit_of(model: Node3D) -> Node3D:
	var rec: Dictionary = _att.get(model, {})
	if not rec.is_empty() and _alive_node(rec["unit"]):
		return rec["unit"]
	var c: Node = model.get_parent() if is_instance_valid(model) else null
	var hops := 0
	while c and hops < 4:
		if c is Node3D and &"team" in c:
			if not rec.is_empty():
				rec["unit"] = c
			return c as Node3D
		c = c.get_parent()
		hops += 1
	return null


func _team_of(n: Node) -> int:
	if n == null or not is_instance_valid(n):
		return -1
	var team: Variant = n.get(&"team")
	return int(team) if team != null else -1


## 0 = Rimescale Wyrm, 1 = Old Hoarfang: meta beast_variant (EpicBeasts) on the unit or model, else the model's variant.
func _variant_of(unit: Node3D, model: Node3D) -> int:
	for n: Node3D in [unit, model]:
		if n and n.has_meta(&"beast_variant"):
			return int(n.get_meta(&"beast_variant"))
	if model and model.has_method(&"get_variant"):
		return int(model.call(&"get_variant"))
	return 0


func _aim_of(at: Variant) -> Variant:
	if at is Vector3:
		return at
	if typeof(at) == TYPE_OBJECT and is_instance_valid(at) and at is Node3D and (at as Node3D).is_inside_tree():
		return (at as Node3D).global_position
	return null


func _point_of(at: Variant, fallback: Node3D) -> Variant:
	if at is Vector3:
		return at
	if typeof(at) == TYPE_OBJECT and is_instance_valid(at) and at is Node3D and (at as Node3D).is_inside_tree():
		return (at as Node3D).global_position
	if _alive_node(fallback):
		return fallback.global_position
	return null


func _alive_node(n: Variant) -> bool:
	return n != null and is_instance_valid(n) and (n as Node).is_inside_tree()


func _flat(v: Vector3) -> Vector3:
	var f := Vector3(v.x, 0.0, v.z)
	return f.normalized() if f.length() > 0.0001 else Vector3(0.0, 0.0, 1.0)


## Yaw that turns local +X onto `d` (flat): the fan decals (UV.x = the breath direction).
func _yaw_x(d: Vector3) -> float:
	return atan2(-d.z, d.x)


## An orthonormal basis whose +Z is `d`.
func _basis_z(d: Vector3) -> Basis:
	var z := d.normalized() if d.length() > 0.0001 else Vector3(0.0, 0.0, 1.0)
	var up := Vector3.UP if absf(z.y) < 0.97 else Vector3(0.0, 0.0, -1.0)
	var x := up.cross(z).normalized()
	return Basis(x, z.cross(x), z)


func _ease_out(k: float) -> float:
	return 1.0 - pow(1.0 - k, 3.0)


func _ease_back(k: float) -> float:
	var c1 := 1.70158
	var c3 := c1 + 1.0
	return 1.0 + c3 * pow(k - 1.0, 3.0) + c1 * pow(k - 1.0, 2.0)


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
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.0
	cyl.height = 1.0
	cyl.radial_segments = 40
	cyl.rings = 4
	cyl.cap_top = false
	cyl.cap_bottom = false
	_crown_mesh = _build_crown()
	var meshes := {&"jet": _cone_mesh(), &"tground": plane, &"wground": plane, &"ring": plane, &"flare": quad,
			&"storm": cyl, &"crown": _crown_mesh}
	var mats := {&"jet": _shader_mat(BREATH_SHADER), &"tground": _shader_mat(TGROUND_SHADER),
			&"wground": _shader_mat(WGROUND_SHADER), &"ring": _shader_mat(RING_SHADER),
			&"flare": _shader_mat(FLARE_SHADER), &"storm": _shader_mat(STORM_SHADER), &"crown": _shader_mat(ICE_SHADER)}
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
			if pool == &"flare":
				m.extra_cull_margin = 3.0      # billboards leave their mesh AABB
			if pool == &"jet":
				m.sorting_offset = 0.5         # the jet over the fan it lands on
			if pool == &"storm":
				m.sorting_offset = 1.0         # the snow wall over the floor marks
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
			var p := _emitter(look, int(spec[0]), float(spec[1]), spec[2])
			p.one_shot = false
			p.explosiveness = 0.0
			p.randomness = 0.3
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


## The jet cone (same shape as TitanVfx's): apex at the origin, axis +Z, length 1, radius 1 at the far end.
func _cone_mesh() -> ArrayMesh:
	var seg := 18
	var rings := 12
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	for j in rings + 1:
		var v := float(j) / float(rings)
		var r := lerpf(0.06, 1.0, pow(v, 0.7))
		var dr := 0.94 * 0.7 * pow(maxf(v, 0.03), -0.3)
		for i in seg + 1:
			var a := float(i) / float(seg) * TAU
			var c := cos(a)
			var s := sin(a)
			verts.append(Vector3(c * r, s * r, v))
			norms.append(Vector3(c, s, -dr).normalized())
			uvs.append(Vector2(float(i) / float(seg), v))
	for j in rings:
		for i in seg:
			var a0 := j * (seg + 1) + i
			var b0 := a0 + seg + 1
			idx.append_array(PackedInt32Array([a0, b0, a0 + 1, a0 + 1, b0, b0 + 1]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## The ice crown: 12 jagged spikes leaning out on a unit ring + 5 short ones inside, flat facets, feet sunk under the
## ground. COLOR.a = 0 at a spike's foot -> 1 at its tip (glow and melt). Built once per node.
func _build_crown() -> ArrayMesh:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var conv := _winding()
	var rng := RandomNumberGenerator.new()
	rng.seed = 9137
	var specs: Array = []   # [angle, ring radius, height, base radius, lean]
	for i in 12:
		specs.append([float(i) / 12.0 * TAU + rng.randf_range(-0.12, 0.12), rng.randf_range(0.88, 1.08),
				rng.randf_range(0.75, 1.45), rng.randf_range(0.16, 0.26), rng.randf_range(0.35, 0.62)])
	for i in 5:
		specs.append([float(i) / 5.0 * TAU + 0.4 + rng.randf_range(-0.2, 0.2), rng.randf_range(0.4, 0.58),
				rng.randf_range(0.45, 0.8), rng.randf_range(0.12, 0.18), rng.randf_range(0.2, 0.4)])
	for sp: Array in specs:
		var ang: float = sp[0]
		var out := Vector3(cos(ang), 0.0, sin(ang))
		var foot := out * float(sp[1]) - Vector3.UP * 0.35
		var h: float = sp[2]
		var br: float = sp[3]
		var lean: float = sp[4]
		var axis := (Vector3.UP + out * lean).normalized()
		var side := axis.cross(out).normalized()
		var fwd := side.cross(axis).normalized()
		var tip := foot + axis * (h + 0.35) + side * rng.randf_range(-0.06, 0.06)
		var sides := 5
		var ring: Array[Vector3] = []
		for k in sides:
			var a := float(k) / float(sides) * TAU + rng.randf_range(-0.2, 0.2)
			var rr := br * rng.randf_range(0.8, 1.15)
			ring.append(foot + (side * cos(a) + fwd * sin(a)) * rr)
		# A shoulder a third of the way up: a faceted crystal, not a cone.
		var mid: Array[Vector3] = []
		for k in sides:
			mid.append(ring[k].lerp(tip, 0.35) + (ring[k] - foot) * 0.15)
		for k in sides:
			var k2 := (k + 1) % sides
			_crown_tri(verts, norms, cols, conv, ring[k], ring[k2], mid[k2], foot, 0.0, 0.0, 0.35)
			_crown_tri(verts, norms, cols, conv, ring[k], mid[k2], mid[k], foot, 0.0, 0.35, 0.35)
			_crown_tri(verts, norms, cols, conv, mid[k], mid[k2], tip, foot, 0.35, 0.35, 1.0)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## One outward-facing flat triangle (`inside` = a point inside the spike); a / b / c = COLOR.a of the corners.
func _crown_tri(verts: PackedVector3Array, norms: PackedVector3Array, cols: PackedColorArray, conv: float,
		p0: Vector3, p1: Vector3, p2: Vector3, inside: Vector3, a: float, b: float, c: float) -> void:
	var n := (p1 - p0).cross(p2 - p0).normalized()
	var centre := (p0 + p1 + p2) / 3.0
	if n.dot(centre - inside) < 0.0:
		n = -n
	# Order the corners for the engine's front-face winding (conv: +1 when cross(b-a, c-a) points out).
	var q0 := p0
	var q1 := p1
	var q2 := p2
	var qa := a
	var qb := b
	var qc := c
	if signf((q1 - q0).cross(q2 - q0).dot(n)) != conv:
		q1 = p2
		q2 = p1
		qb = c
		qc = b
	for pair: Array in [[q0, qa], [q1, qb], [q2, qc]]:
		verts.append(pair[0])
		norms.append(n)
		cols.append(Color(1.0, 1.0, 1.0, float(pair[1])))


## +1 when the engine's front faces have cross(b - a, c - a) along the outward normal, else -1 (read off a BoxMesh).
func _winding() -> float:
	var arr: Array = BoxMesh.new().get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	return 1.0 if (v[idx[1]] - v[idx[0]]).cross(v[idx[2]] - v[idx[0]]).dot(n[idx[0]]) >= 0.0 else -1.0


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
	if HUGE_LOOKS.has(look):
		p.visibility_aabb = AABB(Vector3(-12.0, -4.0, -12.0), Vector3(24.0, 14.0, 24.0))
	elif BIG_LOOKS.has(look):
		p.visibility_aabb = AABB(Vector3(-8.0, -6.0, -8.0), Vector3(16.0, 14.0, 16.0))
	else:
		p.visibility_aabb = AABB(Vector3(-5.0, -3.0, -5.0), Vector3(10.0, 9.0, 10.0))
	VfxCap.fit(p)   # G-F VFX caps: under the mix / additive caps (docs/art/gf_vfx_caps.md)
	return p


## Draw passes: textured billboard quads (never a bare square: every one has a shape mask and keeps the particle
## scale, Godot 4.7) + velocity-aligned streaks.
func _build_passes() -> void:
	_passes[&"add_star"] = _particle_quad(_shape_tex(&"star"), BaseMaterial3D.BLEND_MODE_ADD)
	_passes[&"add_shard"] = _particle_quad(_shape_tex(&"shard"), BaseMaterial3D.BLEND_MODE_ADD)
	_passes[&"mix_puff"] = _particle_quad(_shape_tex(&"puff"), BaseMaterial3D.BLEND_MODE_MIX, true)
	_passes[&"mix_dot"] = _particle_quad(_shape_tex(&"dot"), BaseMaterial3D.BLEND_MODE_MIX)
	_passes[&"mix_flake"] = _particle_quad(_shape_tex(&"flake"), BaseMaterial3D.BLEND_MODE_MIX)
	_passes[&"mix_shard"] = _particle_quad(_shape_tex(&"shard"), BaseMaterial3D.BLEND_MODE_MIX)
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
		mat.proximity_fade_enabled = true
		mat.proximity_fade_distance = 0.4
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
			var v := (float(y) + 0.5) / float(n) * 2.0 - 1.0
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
				&"flake":
					# A six-armed snow star with a soft round body (reads as a flake up close, a dot far away).
					var ang := atan2(v, u)
					var arms := pow(absf(cos(ang * 3.0)), 8.0)
					var body := clampf(1.0 - r / 0.35, 0.0, 1.0)
					var arm := arms * clampf(1.0 - r / 0.95, 0.0, 1.0)
					a = clampf(body * body * 1.3 + arm * 0.9, 0.0, 1.0)
					shade = 0.85 + 0.15 * body
				&"shard":
					var k := absf(u) / 0.24 + absf(v + 0.1) / 0.86
					a = clampf((1.0 - k) / 0.1, 0.0, 1.0)
					shade = 1.0 if u > 0.0 else 0.62
					if absf(u) < 0.035:
						shade = 1.0
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
	var snow_cols := [_hdr(SNOW, 1.25), _hdr(RIME, 1.15), _hdr(Color(0.86, 0.94, 1.0), 1.3)]
	var mist_cols := [_hdr(RIME, 1.1), _hdr(SNOW, 1.15), _hdr(FROST, 1.05)]
	match key:
		&"wyrm_jet":
			_shape_sphere(m, 0.3)
			m.direction = Vector3(0, 0, 1)
			m.spread = 13.0
			m.initial_velocity_min = 9.0
			m.initial_velocity_max = 12.5
			m.damping_min = 5.0
			m.damping_max = 7.0
			m.gravity = Vector3(0, -0.5, 0)
			_spin(m, 70.0)
			m.scale_min = 1.15
			m.scale_max = 1.7
			m.scale_curve = _curve([Vector2(0.0, 0.3), Vector2(0.5, 0.85), Vector2(1.0, 1.0)])
			m.color_initial_ramp = _ramp(snow_cols)
			m.color_ramp = _ramp_at([0.0, 0.12, 0.6, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.9),
					Color(1, 1, 1, 0.6), Color(1, 1, 1, 0.0)])
		&"wyrm_glints":
			_shape_sphere(m, 0.45)
			m.direction = Vector3(0, 0, 1)
			m.spread = 18.0
			m.initial_velocity_min = 6.5
			m.initial_velocity_max = 10.5
			m.damping_min = 4.0
			m.damping_max = 6.0
			m.gravity = Vector3(0, -1.0, 0)
			_spin(m, 200.0)
			_size(m, 0.15, 0.28, &"hold")
			m.color_ramp = _ramp_at([0.0, 0.1, 0.55, 1.0], [_hdr(FROST_HOT, 3.4, 0.0), _hdr(FROST_HOT, 3.4),
					_hdr(FROST, 2.6), _hdr(FROST, 1.5, 0.0)])
		&"wyrm_splash":
			_shape_box(m, Vector3(1.8, 0.1, 2.0))
			m.direction = Vector3(0, 0.35, 1)
			m.spread = 45.0
			m.initial_velocity_min = 1.6
			m.initial_velocity_max = 3.6
			m.damping_min = 1.2
			m.damping_max = 2.0
			m.gravity = Vector3(0, 0.25, 0)
			_spin(m, 40.0)
			_size(m, 1.2, 2.0, &"grow")
			m.color_initial_ramp = _ramp(snow_cols)
			m.color_ramp = _ramp_at([0.0, 0.15, 0.6, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.75),
					Color(1, 1, 1, 0.45), Color(1, 1, 1, 0.0)])
		&"rime_linger":
			_shape_box(m, Vector3(2.2, 0.1, 2.4))
			m.direction = Vector3.UP
			m.spread = 70.0
			m.initial_velocity_min = 0.15
			m.initial_velocity_max = 0.45
			m.damping_min = 0.2
			m.damping_max = 0.4
			m.gravity = Vector3(0, -0.05, 0)
			_spin(m, 20.0)
			_size(m, 1.4, 2.2, &"grow")
			m.color_initial_ramp = _ramp(mist_cols)
			m.color_ramp = _ramp_at([0.0, 0.2, 0.65, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.5),
					Color(1, 1, 1, 0.3), Color(1, 1, 1, 0.0)])
		&"tele_motes":
			# Frost motes drawn in to the ring centre, rising a little (the air freezing over the spot).
			_shape_ring(m, 2.9, 0.1)
			m.emission_ring_inner_radius = 2.4
			m.direction = Vector3.UP
			m.spread = 20.0
			m.initial_velocity_min = 0.3
			m.initial_velocity_max = 0.8
			m.radial_accel_min = -3.5
			m.radial_accel_max = -2.0
			m.tangential_accel_min = 1.5
			m.tangential_accel_max = 3.0
			m.gravity = Vector3(0, 0.4, 0)
			_size(m, 0.14, 0.24, &"hold")
			m.color_ramp = _ramp_at([0.0, 0.2, 0.7, 1.0], [_hdr(FROST_HOT, 2.8, 0.0), _hdr(FROST_HOT, 2.8),
					_hdr(FROST, 2.2), _hdr(FROST, 1.2, 0.0)])
		&"lash_windup":
			_shape_sphere(m, 0.5)
			m.direction = Vector3.UP
			m.spread = 60.0
			m.initial_velocity_min = 0.6
			m.initial_velocity_max = 1.4
			m.damping_min = 1.0
			m.damping_max = 1.6
			m.gravity = Vector3(0, -0.6, 0)
			_spin(m, 60.0)
			_size(m, 0.6, 1.0, &"grow")
			m.color_initial_ramp = _ramp(snow_cols)
			m.color_ramp = _ramp_at([0.0, 0.2, 0.6, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.6),
					Color(1, 1, 1, 0.35), Color(1, 1, 1, 0.0)])
		&"lash_spray_a", &"lash_spray_b":
			# Snow flung round the coil along the tail's sweep (sign = the sweep direction).
			var sg := 1.0 if key == &"lash_spray_a" else -1.0
			_shape_ring(m, 3.1, 0.2)
			m.emission_ring_inner_radius = 2.2
			m.direction = Vector3.UP
			m.spread = 25.0
			m.initial_velocity_min = 0.8
			m.initial_velocity_max = 1.8
			m.radial_velocity_min = 1.0
			m.radial_velocity_max = 2.5
			m.tangential_accel_min = 9.0 * sg
			m.tangential_accel_max = 14.0 * sg
			m.damping_min = 2.0
			m.damping_max = 3.0
			m.gravity = Vector3(0, -0.8, 0)
			_spin(m, 60.0)
			_size(m, 1.3, 2.1, &"grow")
			m.color_initial_ramp = _ramp(snow_cols)
			m.color_ramp = _ramp_at([0.0, 0.1, 0.55, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.55),
					Color(1, 1, 1, 0.3), Color(1, 1, 1, 0.0)])
		&"lash_chips":
			_shape_sphere(m, 0.6)
			m.direction = Vector3(0, 0.8, 1)
			m.spread = 45.0
			m.initial_velocity_min = 3.5
			m.initial_velocity_max = 6.5
			m.gravity = Vector3(0, -12.0, 0)
			_spin(m, 400.0)
			_size(m, 0.18, 0.32, &"hold")
			m.color_initial_ramp = _ramp([_hdr(Color(0.8, 0.93, 1.0), 1.5), _hdr(FROST_HOT, 1.7),
					_hdr(FROST_TEAM, 1.3)])
			m.color_ramp = _ramp_at([0.0, 0.8, 1.0], [Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
		&"snow_dust", &"bliz_burst":
			var bl := key == &"bliz_burst"
			_shape_ring(m, 2.0 if bl else 1.4, 0.1)
			m.direction = Vector3.UP
			m.spread = 55.0
			m.initial_velocity_min = 1.0
			m.initial_velocity_max = 2.8
			m.radial_velocity_min = 3.5 if bl else 2.4
			m.radial_velocity_max = 6.5 if bl else 4.0
			m.damping_min = 2.4
			m.damping_max = 3.2
			m.gravity = Vector3(0, 0.35, 0)
			_spin(m, 40.0)
			m.scale_min = 1.7 if not bl else 2.2
			m.scale_max = 2.7 if not bl else 3.4
			m.scale_curve = _curve([Vector2(0.0, 0.35), Vector2(0.35, 1.0), Vector2(1.0, 1.15)])
			m.color_initial_ramp = _ramp([_hdr(SNOW, 1.2), _hdr(RIME, 1.1), _hdr(Color(0.8, 0.9, 1.0), 1.2)])
			m.color_ramp = _ramp_at([0.0, 0.1, 0.6, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.68),
					Color(1, 1, 1, 0.4), Color(1, 1, 1, 0.0)])
		&"ice_shards":
			_shape_sphere(m, 1.0)
			m.direction = Vector3.UP
			m.spread = 65.0
			m.initial_velocity_min = 4.0
			m.initial_velocity_max = 8.5
			m.gravity = Vector3(0, -13.0, 0)
			_spin(m, 400.0)
			_size(m, 0.26, 0.46, &"hold")
			m.color_initial_ramp = _ramp([_hdr(Color(0.8, 0.93, 1.0), 1.5), _hdr(FROST_HOT, 1.7),
					_hdr(FROST_TEAM, 1.3)])
			m.color_ramp = _ramp_at([0.0, 0.8, 1.0], [Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
		&"ice_glints", &"warn_glints":
			var wg := key == &"warn_glints"
			_shape_sphere(m, 6.0 if wg else 2.2)
			m.emission_shape_scale = Vector3(1.0, 0.15 if wg else 0.4, 1.0)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 0.5
			m.initial_velocity_max = 2.0
			m.gravity = Vector3(0, -1.0 if not wg else 0.3, 0)
			_size(m, 0.16, 0.32, &"hold")
			m.color_ramp = _ramp_at([0.0, 0.1, 0.5, 1.0], [_hdr(FROST_HOT, 3.6, 0.0), _hdr(FROST_HOT, 3.6),
					_hdr(FROST, 2.6), _hdr(FROST, 1.4, 0.0)])
		&"cold_mist":
			_shape_sphere(m, 1.6)
			m.emission_shape_scale = Vector3(1.0, 0.3, 1.0)
			m.direction = Vector3.UP
			m.spread = 70.0
			m.initial_velocity_min = 0.2
			m.initial_velocity_max = 0.5
			m.damping_min = 0.4
			m.damping_max = 0.7
			m.gravity = Vector3(0, 0.05, 0)
			_spin(m, 25.0)
			_size(m, 1.8, 2.8, &"grow")
			m.color_initial_ramp = _ramp(mist_cols)
			m.color_ramp = _ramp_at([0.0, 0.15, 0.6, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.6),
					Color(1, 1, 1, 0.4), Color(1, 1, 1, 0.0)])
		&"bliz_snow":
			# The storm's body: flakes swirling round the Wyrm inside the wall (tangential push, pulled in a little).
			_shape_ring(m, 7.6, 3.0)
			m.emission_ring_inner_radius = 1.5
			m.direction = Vector3(0, 0.2, 1)
			m.spread = 40.0
			m.initial_velocity_min = 1.0
			m.initial_velocity_max = 2.5
			m.tangential_accel_min = 10.0
			m.tangential_accel_max = 16.0
			m.radial_accel_min = -2.0
			m.radial_accel_max = -0.5
			m.damping_min = 1.5
			m.damping_max = 2.5
			m.gravity = Vector3(0, -1.5, 0)
			_size(m, 0.14, 0.24, &"hold")
			m.color_initial_ramp = _ramp([_hdr(SNOW, 1.35), _hdr(RIME, 1.25), _hdr(Color(0.9, 0.95, 1.0), 1.4)])
			m.color_ramp = _ramp_at([0.0, 0.15, 0.8, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.95),
					Color(1, 1, 1, 0.8), Color(1, 1, 1, 0.0)])
		&"bliz_flakes":
			_shape_disc(m, 7.5)
			m.direction = Vector3(0, -1, 0)
			m.spread = 25.0
			m.initial_velocity_min = 1.5
			m.initial_velocity_max = 3.0
			m.tangential_accel_min = 4.0
			m.tangential_accel_max = 8.0
			m.gravity = Vector3(0, -2.0, 0)
			_spin(m, 240.0)
			_size(m, 0.22, 0.36, &"hold")
			m.color_initial_ramp = _ramp([_hdr(SNOW, 1.3), _hdr(RIME, 1.2)])
			m.color_ramp = _ramp_at([0.0, 0.1, 0.85, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 1.0),
					Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.0)])
		&"bliz_ground":
			_shape_ring(m, 7.0, 0.1)
			m.emission_ring_inner_radius = 2.0
			m.direction = Vector3(0, 0.1, 1)
			m.spread = 30.0
			m.initial_velocity_min = 1.0
			m.initial_velocity_max = 2.2
			m.tangential_accel_min = 6.0
			m.tangential_accel_max = 10.0
			m.damping_min = 1.0
			m.damping_max = 1.8
			m.gravity = Vector3(0, 0.1, 0)
			_spin(m, 40.0)
			_size(m, 1.4, 2.4, &"grow")
			m.color_initial_ramp = _ramp(snow_cols)
			m.color_ramp = _ramp_at([0.0, 0.2, 0.7, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.55),
					Color(1, 1, 1, 0.35), Color(1, 1, 1, 0.0)])
		&"warn_mist":
			_shape_ring(m, 7.0, 0.2)
			m.emission_ring_inner_radius = 0.0
			m.direction = Vector3.UP
			m.spread = 80.0
			m.initial_velocity_min = 0.08
			m.initial_velocity_max = 0.25
			m.radial_velocity_min = 0.05
			m.radial_velocity_max = 0.25
			m.tangential_accel_min = 0.1
			m.tangential_accel_max = 0.3
			m.damping_min = 0.05
			m.damping_max = 0.15
			m.gravity = Vector3.ZERO
			_spin(m, 8.0)
			_size(m, 3.0, 4.6, &"grow")
			m.color_initial_ramp = _ramp(mist_cols)
			m.color_ramp = _ramp_at([0.0, 0.25, 0.7, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.26),
					Color(1, 1, 1, 0.2), Color(1, 1, 1, 0.0)])
		&"warn_vapour":
			_shape_disc(m, 5.0)
			m.direction = Vector3.UP
			m.spread = 15.0
			m.initial_velocity_min = 0.25
			m.initial_velocity_max = 0.55
			m.damping_min = 0.05
			m.damping_max = 0.1
			m.gravity = Vector3(0, 0.05, 0)
			_spin(m, 15.0)
			_size(m, 0.9, 1.6, &"grow")
			m.color_initial_ramp = _ramp(mist_cols)
			m.color_ramp = _ramp_at([0.0, 0.3, 0.7, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.28),
					Color(1, 1, 1, 0.18), Color(1, 1, 1, 0.0)])
		&"wyrm_wake":
			_shape_sphere(m, 0.5)
			m.direction = Vector3(0, -0.5, -1)
			m.spread = 35.0
			m.initial_velocity_min = 0.3
			m.initial_velocity_max = 1.0
			m.damping_min = 0.3
			m.damping_max = 0.6
			m.gravity = Vector3(0, -1.2, 0)
			_spin(m, 260.0)
			_size(m, 0.14, 0.26, &"hold")
			m.color_ramp = _ramp_at([0.0, 0.15, 0.7, 1.0], [_hdr(FROST_HOT, 2.6, 0.0), _hdr(FROST_HOT, 2.6),
					_hdr(FROST, 2.0), _hdr(FROST_TEAM, 1.2, 0.0)])
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


func _shape_disc(m: ParticleProcessMaterial, r: float) -> void:
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	m.emission_ring_axis = Vector3.UP
	m.emission_ring_radius = r
	m.emission_ring_inner_radius = 0.0
	m.emission_ring_height = 0.1


func _shape_sphere(m: ParticleProcessMaterial, r: float) -> void:
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = r


func _shape_box(m: ParticleProcessMaterial, extents: Vector3) -> void:
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = extents


## Particle sizes in metres + a scale curve: shrink, grow (smoke, mist), hold (shards, flakes).
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
