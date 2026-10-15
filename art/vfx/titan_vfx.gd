class_name TitanVfx
extends Node3D
## Titan effects. Draw-only: never touches gameplay.
##   Task 13.V14 Dragon VFX (docs/design/cavalry-mounts.md 5.1 / 5.2 / 10): the Cinder Dragon.
##   Task 13c.V2 Frost Dragon VFX (docs/design/titans-2.md 3 / 11): the Frost Dragon, same machinery recoloured.
##   Task 13.V19 (non-dragon titans: War Mammoth, Elder Treant, Nightmare Knight): GROUND_IDS, drawn by the family node
##       art/vfx/titan_ground_vfx.gd (TitanGroundVfx, a child "TitanGroundVfx" made in _ready; it auto-attaches those
##       models itself). play() forwards them; active_count / active_ids / live_count include it. Ids and hooks: its header.
##
## API (group "titan_vfx"; callers: get_tree().get_first_node_in_group(&"titan_vfx").play(id, at, target)):
##   play(id: StringName, at: Variant, target: Variant = null) -> bool   true when `id` is a titan effect (handled,
##       even if the fog hides it or a pool is full), false for any other id (nothing happens).
##   handles(id) -> bool · attach(model) -> bool · detach(model) · is_attached(model) -> bool
##   active_count() / active_ids() / live_count() (tests) · trail_emitting(model) -> bool (tests)
## `target` may be the dragon Unit (its get_model() is used), the dragon model (FlyerModel) itself, or null.
## `at` is a world point (Vector3), a Node3D (read once) or, for a breath without any dragon, a Transform3D (the mouth,
## +Z = the breath direction).
## Ids:
##   dragon_breath / frost_breath   at = the aim point on the ground (optional: default = 4 m ahead of the dragon),
##       target = the dragon. The jet leaves the mouth (FlyerModel.get_breath_origin(), followed live: the head sweep
##       sweeps it) for 0.6 s: flame (rime) cone + billboard puffs + sparks (ice glints), a 60 deg fan of fire (rime)
##       rolls out on the ground to 6 m (6.5 m), then soot smoke (cold mist).
##   burning_ground / hoarfrost     at = the patch centre, target = the dragon (team for the fog) or null. Decal r 2 +
##       low flames for 3 s (rime r 2.5 + low mist for 4 s), a glowing line on the damage edge, then it fades.
##   dragon_crash / frost_crash     at = the impact point, target = the dragon or null. Crater decal, shock ring, a big
##       dust wall (snow dust), clods and embers (ice shards and glints), lingering smoke (cold mist).
##   dragon_trail / frost_trail     at = ignored, target = the dragon: an ember (ice-shard) trail while it flies,
##       only within 45 m of the camera (same as attach, without the breath / crash hooks).
##
## GLUE. The lead adds ONE Node3D named "TitanVfx" with this script to scenes/main.tscn and scenes/skirmish.tscn (next to
## TradeVfx). Dragon models then need no wiring: every node entering the tree with the FlyerModel hooks (signals
## `breath_released`, `crashed(at)` and `get_breath_origin()`) is attached automatically: its breath plays on
## breath_released (0.35 s after play_attack), its crash dust on crashed(at), its trail while it flies. Frost look when
## the model's script file name starts with "frost" or its meta "titan_vfx_kind" is &"frost".
## Gameplay (TitanAbilities, 13.C3) calls play(&"burning_ground" / &"hoarfrost", centre, dragon) when it makes a patch.
## An explicit dragon_breath / frost_breath for an attached dragon MERGES with the automatic one: called before the jaw
## opens it waits for breath_released (<= 0.45 s) and gives it its aim; called just after (<= 0.5 s) it re-aims it.
## An explicit dragon_crash / frost_crash for an attached dragon waits (<= 1.5 s) for crashed(at) (the real impact).
##
## Fog: breaths and trails follow the dragon's `visible` (a fogged dragon hides them); patches and craters check
## FogOfWar.is_visible at their point for the other teams (4 times per second).
## Budget: everything is built at _ready and pooled (mesh pools, stream emitters, one-shot bursts): no node, material
## or mesh is created after _ready. 0 lights, no shadows. One ShaderMaterial per shader (own titan_breath, titan_ground;
## reused read-only champion_ground (rings), champion_flare (glows), combat_streak (sparks)), looks set with instance
## uniforms. Every particle quad has a shape mask and billboard_keep_scale. Per breath: 2 jet meshes, 1 fan decal, 2 glows,
## 3-4 emitters; per patch: 1 decal + 1 emitter; per crash: 1 decal, 2 rings, 1 glow, 4 bursts; per trail: 1 emitter.

const GROUP := &"titan_vfx"
const EFFECTS: Array[StringName] = [&"dragon_breath", &"burning_ground", &"dragon_crash", &"dragon_trail",
		&"frost_breath", &"hoarfrost", &"frost_crash", &"frost_trail",
		&"frost_aura", &"trample", &"howdah_bolt", &"root_morph", &"grove_pulse", &"thorn_volley", &"sapling_sprout",
		&"knight_knockback"]
## 13.V19: the non-dragon titan ids, forwarded to the family node (GROUND_FAMILY). The Knight's charge impact is
## CavalryVfx's `charge` (13.V20), not a titan id.
const GROUND_IDS: Array[StringName] = [&"frost_aura", &"trample", &"howdah_bolt", &"root_morph", &"grove_pulse",
		&"thorn_volley", &"sapling_sprout", &"knight_knockback"]
const GROUND_FAMILY := "res://art/vfx/titan_ground_vfx.gd"
const FROST_IDS: Array[StringName] = [&"frost_breath", &"hoarfrost", &"frost_crash", &"frost_trail"]

# Numbers from the specs (cm. = cavalry-mounts.md, t2. = titans-2.md).
const BREATH_ARC_DEG := 60.0      # cm. 5.1 / t2. 3.1
const BREATH_RANGE := 6.0         # Cinder Dragon cone
const FROST_RANGE := 6.5          # Frost Dragon cone
const JET_TIME := 0.6             # the jaw stays open 0.6 s (cm. 10)
const PATCH_AHEAD := 4.0          # patch centre 4 m ahead of the dragon (cm. 5.2, t2. 3.2)
const BURN_RADIUS := 2.0
const BURN_TIME := 3.0
const HOAR_RADIUS := 2.5
const HOAR_TIME := 4.0
const TRAIL_RANGE := 45.0         # cm. 10: ember trail < 45 m from the camera
const FLY_HEIGHT := 4.0
const MOUTH_AHEAD := 3.2
const JET_LAND := 4.8               # where the jet hits the ground by default
# Glue timing.
const MERGE_WINDOW := 0.5
const PENDING_MAX := 0.45
const CRASH_MERGE := 1.5
const CHECK_INTERVAL := 0.25
const FOG_RESCAN := 1.0
const TRAIL_MIN_SPEED := 0.8      # the hover bob stays under it

enum { K_BREATH, K_PATCH, K_CRASH }
enum { G_BURN, G_HOAR, G_FAN_FIRE, G_FAN_FROST, G_CRATER_FIRE, G_CRATER_ICE }   # titan_ground.gdshader
enum { R_SHOCK = 0, R_SOOT = 5 }                                                # champion_ground.gdshader

## Mesh pools: pool -> size.
const MESH_POOLS := {&"jet": 8, &"ground": 24, &"ring": 8, &"flare": 12}
## Stream emitters (emit while an effect runs, follow their anchor): look -> [amount, lifetime, draw pass, pool size].
const STREAMS := {
	&"fire_jet": [56, 0.5, &"add_puff", 4],
	&"fire_splash": [46, 0.55, &"add_flame", 4],
	&"fire_sparks": [26, 0.55, &"streak", 4],
	&"frost_jet": [40, 0.55, &"mix_puff", 4],
	&"frost_glints": [18, 0.55, &"add_star", 8],
	&"frost_splash": [36, 0.85, &"mix_puff", 4],
	&"ground_flames": [18, 0.75, &"add_flame", 12],
	&"frost_mist": [10, 1.8, &"mix_puff", 12],
	&"ember_trail": [60, 1.5, &"add_dot", 8],
	&"frost_trail": [48, 1.4, &"add_shard", 8],
}
## One-shot bursts: look -> [amount, lifetime, draw pass, pool size, explosiveness].
const BURSTS := {
	&"breath_smoke": [14, 1.7, &"mix_puff", 4, 0.7],
	&"rime_linger": [12, 1.9, &"mix_puff", 4, 0.7],
	&"crash_dust": [40, 1.8, &"mix_puff", 3, 0.95],
	&"crash_clods": [20, 1.0, &"mix_dot", 3, 1.0],
	&"crash_embers": [28, 0.9, &"streak", 3, 0.95],
	&"crash_smoke": [12, 2.6, &"mix_puff", 3, 0.6],
	&"snow_dust": [40, 1.8, &"mix_puff", 3, 0.95],
	&"ice_shards": [22, 1.1, &"mix_shard", 3, 1.0],
	&"ice_glints": [20, 0.9, &"add_star", 3, 0.9],
	&"cold_mist": [12, 2.6, &"mix_puff", 3, 0.6],
}
## Emitters whose particles travel far (bigger visibility box).
const BIG_LOOKS: Array[StringName] = [&"fire_jet", &"frost_jet", &"crash_dust", &"snow_dust", &"crash_smoke",
		&"cold_mist", &"ember_trail", &"frost_trail"]

const BREATH_SHADER := preload("res://art/vfx/titan_breath.gdshader")
const GROUND_SHADER := preload("res://art/vfx/titan_ground.gdshader")
const RING_SHADER := preload("res://art/vfx/champion_ground.gdshader")
const FLARE_SHADER := preload("res://art/vfx/champion_flare.gdshader")
const SPARK_SHADER := preload("res://art/vfx/combat_streak.gdshader")

# Palette (sRGB; art-keep 0.2: Fire glow #FF8C26, Ice glow #BFEBFF / team #73BFF2 / cloth #265999).
const FIRE_HOT := Color(1.0, 0.93, 0.62)
const FIRE := Color(1.0, 0.55, 0.15)
const FIRE_DEEP := Color(0.85, 0.2, 0.05)
const SOOT := Color(0.06, 0.045, 0.04)
const SMOKE := Color(0.2, 0.17, 0.15)
const FROST_HOT := Color(0.93, 0.98, 1.0)
const FROST := Color(0.75, 0.92, 1.0)
const FROST_TEAM := Color(0.45, 0.75, 0.95)
const FROST_DEEP := Color(0.15, 0.35, 0.6)
const RIME := Color(0.82, 0.9, 0.97)
const SNOW := Color(0.94, 0.97, 1.0)
const DUST := Color(0.55, 0.46, 0.34)
const EARTH := Color(0.3, 0.22, 0.15)

## Shape masks shared by every instance (built once per run).
static var _tex_cache: Dictionary = {}


## One running effect.
class Fx:
	extends RefCounted
	var id: StringName
	var kind := 0
	var frost := false
	var t := 0.0
	var dur := 1.0
	var life := 1.0
	var model: Node3D             # the dragon model (null without one)
	var unit: Node3D              # its Unit (team, visibility)
	var team := -1
	var follow := false           # visibility follows the dragon (breaths) or the fog at `point`
	var shown := true
	var check_left := 0.0
	var point := Vector3.ZERO     # breath splash centre / patch centre / impact
	var ground := Vector3.ZERO    # breath: the dragon's ground point (the cone origin)
	var dir := Vector3(0.0, 0.0, 1.0)
	var mouth := Transform3D.IDENTITY
	var yaw0 := 0.0
	var reach := 6.0
	var gy := 0.05                # decal lift (layered so marks never z-fight)
	var moving_anchors := false   # breaths: the streams follow the mouth every frame
	var t_last_full := 0.0        # patches: time of the last full uniform update
	var nodes: Dictionary = {}    # role -> GeometryInstance3D
	var pools: Dictionary = {}    # role -> pool
	var anchors: Dictionary = {}  # anchor -> Transform3D (streams, bursts)
	var streams: Array[Dictionary] = []
	var bursts: Array[Dictionary] = []
	var bursts_left := 0


## A dragon's flight trail (one per attached / trailed dragon; the emitter is taken only while it is near and flying).
class Trail:
	extends RefCounted
	var model: Node3D
	var unit: Node3D
	var frost := false
	var look: StringName
	var p: GPUParticles3D
	var body: Node3D              # the model's Root/Body pivot (cached)
	var acc := 0.0
	var prev := Vector3.ZERO
	var has_prev := false
	var speed := 0.0
	var near := false
	var ok := true
	var check_left := 0.0
	var crashed_t := -99.0


var _fx: Array[Fx] = []
var _trails: Array[Trail] = []
var _att: Dictionary = {}           # model -> record (Dictionary)
var _pending: Array[Node3D] = []    # models with an explicit breath / crash waiting for their signal
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
var _family: Node3D                 # 13.V19 TitanGroundVfx (null when its script is missing)


func _ready() -> void:
	add_to_group(GROUP)
	top_level = true                  # effects are placed in world space
	global_transform = Transform3D.IDENTITY
	_build_shared()
	if ResourceLoader.exists(GROUND_FAMILY):
		var fam := load(GROUND_FAMILY) as GDScript
		if fam and fam.can_instantiate():
			_family = fam.new() as Node3D
			_family.name = "TitanGroundVfx"
			add_child(_family)
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
	_tick_pending()
	for i in range(_fx.size() - 1, -1, -1):
		var fx := _fx[i]
		if _tick(fx, delta):
			_finish(fx)
			_fx.remove_at(i)
	_tick_trails(delta)
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

## Plays titan effect `id` (see the header). Returns true when `id` is a titan effect (handled), false otherwise.
func play(id: StringName, at: Variant, target: Variant = null) -> bool:
	if not EFFECTS.has(id):
		return false
	if not _built or not is_inside_tree():
		return true
	if GROUND_IDS.has(id):
		if _family:
			_family.call(&"play", id, at, target)
		return true
	var frost := FROST_IDS.has(id)
	var t: Node3D = null
	if typeof(target) == TYPE_OBJECT and is_instance_valid(target) and target is Node3D \
			and (target as Node3D).is_inside_tree():
		t = target as Node3D
	var res := _resolve(t)
	var model: Node3D = res[0]
	var unit: Node3D = res[1]
	match id:
		&"dragon_breath", &"frost_breath":
			_request_breath(frost, _aim_of(at), model, unit)
		&"burning_ground", &"hoarfrost":
			var p: Variant = _point_of(at, unit)
			if p is Vector3:
				_start_patch(frost, p, unit if unit else model)
		&"dragon_crash", &"frost_crash":
			_request_crash(frost, _point_of(at, unit if unit else model), model, unit)
		&"dragon_trail", &"frost_trail":
			var src: Node3D = model if model else unit
			if src:
				_ensure_trail(src, unit, frost)
	return true


## True when `id` is one of this node's effects.
func handles(id: StringName) -> bool:
	return EFFECTS.has(id)


## Hooks a dragon model (FlyerModel signals): breath on breath_released, crash on crashed(at), trail while it flies.
## Done automatically for every such model entering the tree. Returns true when newly attached.
func attach(model: Node3D) -> bool:
	if model == null or not is_instance_valid(model) or _att.has(model) or not _is_flyer(model):
		return false
	var frost := _model_is_frost(model)
	_att[model] = {"frost": frost, "unit": null, "breath_t": -99.0, "breath_fx": null, "pending_t": -99.0,
			"pending_aim": null, "crash_t": -99.0, "crash_wait_t": -99.0, "crash_at": null}
	model.connect(&"breath_released", _on_breath_released.bind(model))
	model.connect(&"crashed", _on_crashed.bind(model))
	model.connect(&"tree_exiting", _on_model_exiting.bind(model))
	_ensure_trail(model, null, frost)
	return true


## Unhooks a dragon model (its trail stops).
func detach(model: Node3D) -> void:
	if not _att.has(model):
		return
	_att.erase(model)
	_pending.erase(model)
	if is_instance_valid(model):
		for sig: StringName in [&"breath_released", &"crashed", &"tree_exiting"]:
			for c: Dictionary in model.get_signal_connection_list(sig):
				var cb: Callable = c["callable"]
				if cb.get_object() == self:
					model.disconnect(sig, cb)
	for tr in _trails:
		if tr.model == model:
			tr.model = null   # released on the next tick


func is_attached(model: Node3D) -> bool:
	return _att.has(model)


## Number of running effects (trails not counted; the family's auras / root beds are).
func active_count() -> int:
	return _fx.size() + (int(_family.call(&"active_count")) if _family else 0)


## Ids of the running effects.
func active_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for fx in _fx:
		out.append(fx.id)
	if _family:
		out.append_array(_family.call(&"active_ids"))
	return out


## Pooled meshes on screen + bursts alive + stream emitters taken (running, draining or trailing). 0 when idle.
func live_count() -> int:
	var n := _live_bursts.size() + (int(_family.call(&"live_count")) if _family else 0)
	for pool: StringName in _all:
		for g: GeometryInstance3D in _all[pool]:
			if g.visible:
				n += 1
	for look: StringName in _stream_all:
		n += (_stream_all[look] as Array).size() - (_stream_free[look] as Array).size()
	return n


## True while `model`'s trail emitter is emitting (tests).
func trail_emitting(model: Node3D) -> bool:
	for tr in _trails:
		if tr.model == model:
			return tr.p != null and tr.p.emitting
	return false


## The running effect of `id` started last (tests / previews), or null.
func last_fx(id: StringName) -> Fx:
	for i in range(_fx.size() - 1, -1, -1):
		if _fx[i].id == id:
			return _fx[i]
	return null


# ================================================================ auto attach

func _on_node_added(n: Node) -> void:
	if n is Node3D and _is_flyer(n):
		attach(n as Node3D)


func _scan(n: Node) -> void:
	if not is_instance_valid(n):
		return
	if n is Node3D and _is_flyer(n):
		attach(n as Node3D)
	for c: Node in n.get_children():
		_scan(c)


func _on_model_exiting(model: Node3D) -> void:
	detach(model)


func _on_breath_released(model: Node3D) -> void:
	var rec: Dictionary = _att.get(model, {})
	if rec.is_empty() or not _alive_node(model):
		return
	var aim: Variant = null
	if _clock - float(rec["pending_t"]) <= PENDING_MAX + 0.05:
		aim = rec["pending_aim"]
	rec["pending_t"] = -99.0
	rec["breath_t"] = _clock
	rec["breath_fx"] = _start_breath(bool(rec["frost"]), aim, model, _unit_of(model))


func _on_crashed(at: Vector3, model: Node3D) -> void:
	var rec: Dictionary = _att.get(model, {})
	if rec.is_empty():
		return
	for tr in _trails:
		if tr.model == model:
			tr.crashed_t = _clock
	if _clock - float(rec["crash_t"]) < CRASH_MERGE:
		return
	rec["crash_t"] = _clock
	rec["crash_wait_t"] = -99.0
	_start_crash(bool(rec["frost"]), at, _unit_of(model))


## Explicit breaths / crashes still waiting for their model's signal: play them anyway when it never came.
func _tick_pending() -> void:
	for i in range(_pending.size() - 1, -1, -1):
		var model := _pending[i]
		var rec: Dictionary = _att.get(model, {})
		if rec.is_empty():
			_pending.remove_at(i)
			continue
		var waiting := false
		var pt := float(rec["pending_t"])
		if pt > -90.0:
			if _clock - pt > PENDING_MAX:
				rec["pending_t"] = -99.0
				rec["breath_t"] = _clock
				if _alive_node(model):
					rec["breath_fx"] = _start_breath(bool(rec["frost"]), rec["pending_aim"], model, _unit_of(model))
			else:
				waiting = true
		var ct := float(rec["crash_wait_t"])
		if ct > -90.0:
			if _clock - ct > CRASH_MERGE:
				rec["crash_wait_t"] = -99.0
				rec["crash_t"] = _clock
				var p: Variant = rec["crash_at"]
				if p is Vector3:
					_start_crash(bool(rec["frost"]), p, _unit_of(model))
			else:
				waiting = true
		if not waiting:
			_pending.remove_at(i)


# ================================================================ requests

func _request_breath(frost: bool, aim: Variant, model: Node3D, unit: Node3D) -> void:
	if model and _att.has(model):
		var rec: Dictionary = _att[model]
		if _clock - float(rec["breath_t"]) < MERGE_WINDOW:
			var fx: Variant = rec["breath_fx"]
			if fx is Fx and _fx.has(fx) and aim is Vector3:
				_aim(fx as Fx, aim)
			return
		rec["pending_t"] = _clock
		rec["pending_aim"] = aim
		if not _pending.has(model):
			_pending.append(model)
		return
	_start_breath(frost, aim, model, unit)


func _request_crash(frost: bool, p: Variant, model: Node3D, unit: Node3D) -> void:
	if model and _att.has(model):
		var rec: Dictionary = _att[model]
		if _clock - float(rec["crash_t"]) < CRASH_MERGE:
			return
		rec["crash_wait_t"] = _clock
		rec["crash_at"] = p
		if not _pending.has(model):
			_pending.append(model)
		return
	if p is Vector3:
		_start_crash(frost, p, unit if unit else model)


# ================================================================ breath

func _start_breath(frost: bool, aim: Variant, model: Node3D, unit: Node3D) -> Fx:
	var fx := Fx.new()
	fx.kind = K_BREATH
	fx.moving_anchors = true
	fx.id = &"frost_breath" if frost else &"dragon_breath"
	fx.frost = frost
	fx.model = model if _alive_node(model) else null
	fx.unit = unit if _alive_node(unit) else null
	fx.team = _team_of(fx.unit if fx.unit else fx.model)
	fx.follow = fx.model != null or fx.unit != null
	fx.reach = FROST_RANGE if frost else BREATH_RANGE
	var fwd := Vector3(0.0, 0.0, 1.0)
	if fx.model:
		fx.ground = fx.model.global_position
		fx.mouth = fx.model.call(&"get_breath_origin")
		fwd = _flat(fx.model.global_transform.basis.z)
	elif fx.unit:
		fx.ground = fx.unit.global_position
		fx.mouth = _unit_mouth(fx.unit)
		fwd = _flat(fx.unit.global_transform.basis.z)
	elif aim is Transform3D:
		fx.mouth = aim
		fwd = _flat(fx.mouth.basis.z)
		fx.ground = Vector3(fx.mouth.origin.x, 0.0, fx.mouth.origin.z) - fwd * MOUTH_AHEAD
		aim = null
	elif aim is Vector3:
		fx.ground = aim
		fx.mouth = Transform3D(Basis.IDENTITY, (aim as Vector3) + Vector3(0.0, FLY_HEIGHT + 0.9, MOUTH_AHEAD))
		aim = null
	else:
		return null
	fx.dir = fwd
	fx.point = fx.ground + fwd * JET_LAND
	if aim is Vector3:
		_aim(fx, aim)
	fx.yaw0 = _yaw_z(fx.mouth.basis.z)
	fx.gy = _ground_y()
	fx.dur = 2.6 if frost else 2.3
	fx.life = JET_TIME
	var seed := randf() * 10.0
	# The jet: a soft outer stream + a hot (bright) core.
	var jet := _take(fx, &"jet", &"jet")
	var core := _take(fx, &"core", &"jet")
	if frost:
		_params(jet, {&"pattern": 1.0, &"hot_color": _hdr(FROST_HOT, 2.6), &"mid_color": _hdr(FROST, 1.1),
				&"edge_color": _hdr(FROST_TEAM, 0.7), &"cover": _lin(SNOW, 0.55), &"seed": seed, &"density": 1.0})
		_params(core, {&"pattern": 1.0, &"hot_color": _hdr(Color.WHITE, 3.2), &"mid_color": _hdr(FROST_HOT, 1.9),
				&"edge_color": _hdr(FROST, 1.2), &"cover": _lin(Color(0.97, 0.99, 1.0), 0.3), &"seed": seed + 3.3,
				&"density": 1.15})
	else:
		_params(jet, {&"pattern": 0.0, &"hot_color": _hdr(FIRE_HOT, 1.6), &"mid_color": _hdr(FIRE, 1.3),
				&"edge_color": _hdr(FIRE_DEEP, 1.0), &"cover": _lin(SMOKE, 0.55), &"seed": seed, &"density": 1.0})
		_params(core, {&"pattern": 0.0, &"hot_color": _hdr(Color(1.0, 0.95, 0.8), 1.9),
				&"mid_color": _hdr(FIRE_HOT, 1.4), &"edge_color": _hdr(FIRE, 1.1), &"cover": Color(0, 0, 0, 0),
				&"seed": seed + 3.3, &"density": 0.6})
	# The fan on the ground.
	var fan := _take(fx, &"fan", &"ground")
	_params(fan, {&"pattern": float(G_FAN_FROST if frost else G_FAN_FIRE), &"seed": seed, &"radius": fx.reach,
			&"arc": deg_to_rad(BREATH_ARC_DEG * 0.5), &"rim": 0.0, &"rim_at": 1.0,
			&"glow": _hdr(FROST, 1.3) if frost else _hdr(FIRE, 1.5),
			&"cover": _lin(RIME, 0.7) if frost else _lin(SOOT, 0.72)})
	# Glows at the mouth and where the jet hits the ground.
	var mg := _take(fx, &"mouth_glow", &"flare")
	_params(mg, {&"tint": _hdr(FROST_HOT, 1.3) if frost else _hdr(FIRE_HOT, 1.6), &"rays": 0.0, &"spikes": 4.0,
			&"pulse": 1.0, &"seed": seed, &"halo": Color(0, 0, 0, 0)})
	var sg := _take(fx, &"splash_glow", &"flare")
	_params(sg, {&"tint": _hdr(FROST, 0.8) if frost else _hdr(FIRE, 1.0), &"rays": 0.0, &"spikes": 6.0,
			&"pulse": 1.0, &"seed": seed + 1.0, &"halo": Color(0, 0, 0, 0)})
	if frost:
		_stream(fx, &"frost_jet", &"mouth", 0.0, JET_TIME)
		_stream(fx, &"frost_glints", &"mouth", 0.02, JET_TIME)
		_stream(fx, &"frost_splash", &"splash", 0.08, JET_TIME + 0.05)
		_stream(fx, &"frost_glints", &"splash", 0.1, JET_TIME + 0.1)
		_sched(fx, &"rime_linger", 0.45, &"smoke")
	else:
		_stream(fx, &"fire_jet", &"mouth", 0.0, JET_TIME)
		_stream(fx, &"fire_splash", &"splash", 0.07, JET_TIME + 0.05)
		_stream(fx, &"fire_sparks", &"splash", 0.06, JET_TIME)
		_sched(fx, &"breath_smoke", 0.5, &"smoke")
	_start(fx)
	return fx


## Aims a breath at a ground point: direction from the dragon's ground point, splash 2.5-5 m ahead.
func _aim(fx: Fx, aim: Vector3) -> void:
	var off := aim - fx.ground
	off.y = 0.0
	if off.length() < 0.5:
		return
	fx.dir = off.normalized()
	fx.point = fx.ground + fx.dir * clampf(off.length(), 3.0, 5.5)


func _tick_breath(fx: Fx) -> void:
	var t := fx.t
	if t > JET_TIME + 0.35 and fx.t_last_full > JET_TIME + 0.35:
		# The jaw is shut and the streams are off: only the ground fan cools and fades (it no longer moves).
		var fan0: GeometryInstance3D = fx.nodes.get(&"fan")
		if fan0:
			var fade0 := 1.0 - smoothstep(fx.dur - 0.8, fx.dur - 0.05, t)
			var cool0 := JET_TIME + 0.05
			_uf(fan0, &"heat", 1.0 - smoothstep(cool0, cool0 + (1.0 if fx.frost else 0.7), t))
			_uf(fan0, &"fade", fade0)
			_vis(fan0, fx.shown and fade0 > 0.002)
		return
	fx.t_last_full = t
	var live := false
	if _alive_node(fx.model):
		fx.mouth = fx.model.call(&"get_breath_origin")
		live = true
	elif _alive_node(fx.unit):
		fx.mouth = _unit_mouth(fx.unit)
		live = true
	# The head sweep (FlyerModel breath pose) swings the jet's landing point about the dragon.
	var dyaw := 0.0
	if live:
		dyaw = clampf(wrapf(_yaw_z(fx.mouth.basis.z) - fx.yaw0, -PI, PI), -0.45, 0.45) * 0.8
	var off := fx.point - fx.ground
	off.y = 0.0
	var e := fx.ground + off.rotated(Vector3.UP, dyaw)
	e.y = fx.ground.y + 0.05
	var m := fx.mouth.origin
	var grow := _ease_out(clampf(t / 0.1, 0.0, 1.0))
	var tail := clampf((t - JET_TIME) / 0.18, 0.0, 1.0)
	var widen := _ease_out(clampf(t / 0.2, 0.0, 1.0))
	var er := lerpf(0.5, 1.9 if fx.frost else 1.6, widen)
	var jet_on := t < JET_TIME + 0.2
	_place_jet(fx, &"jet", m, e, er, grow, tail, jet_on)
	_place_jet(fx, &"core", m, e, er * 0.42, grow, minf(1.0, tail * 1.3), jet_on)
	# Ground fan: the front rolls out, the fire (rime glow) dies after the jaw closes, the soot (rime) fades last.
	var fan: GeometryInstance3D = fx.nodes.get(&"fan")
	if fan:
		var front := _ease_out(clampf((t - 0.05) / 0.3, 0.0, 1.0))
		var cool_from := JET_TIME + 0.05
		var heat := 1.0 - smoothstep(cool_from, cool_from + (1.0 if fx.frost else 0.7), t)
		var fade := 1.0 - smoothstep(fx.dur - 0.8, fx.dur - 0.05, t)
		var fan_dir := off.rotated(Vector3.UP, dyaw * 0.5).normalized() if off.length() > 0.01 else fx.dir
		_xf(fan, Transform3D(Basis(Vector3.UP, _yaw_x(fan_dir)) * Basis.from_scale(Vector3(fx.reach, 1.0, fx.reach)),
				fx.ground + Vector3.UP * fx.gy))
		_uf(fan, &"front", front)
		_uf(fan, &"heat", heat)
		_uf(fan, &"fade", fade)
		_vis(fan, fx.shown and fade > 0.002 and t >= 0.05)
	# Glows.
	var zdir := (e - m).normalized() if (e - m).length() > 0.01 else Vector3.DOWN
	var mg: GeometryInstance3D = fx.nodes.get(&"mouth_glow")
	if mg:
		var k := clampf(t / 0.05, 0.0, 1.0) * (1.0 - smoothstep(JET_TIME - 0.05, JET_TIME + 0.12, t))
		var s := (0.95 if fx.frost else 0.9) * (1.0 + 0.12 * sin(t * 47.0))
		_xf(mg, Transform3D(Basis.from_scale(Vector3.ONE * s), m + zdir * 0.25))
		_uf(mg, &"fade", k)
		_vis(mg, fx.shown and k > 0.002)
	var sg: GeometryInstance3D = fx.nodes.get(&"splash_glow")
	if sg:
		var k2 := smoothstep(0.04, 0.12, t) * (1.0 - smoothstep(JET_TIME, JET_TIME + 0.3, t))
		var s2 := (2.2 if fx.frost else 2.0) * (1.0 + 0.1 * sin(t * 31.0))
		_xf(sg, Transform3D(Basis.from_scale(Vector3.ONE * s2), e + Vector3.UP * 0.6))
		_uf(sg, &"fade", k2 * (0.8 if fx.frost else 1.0))
		_vis(sg, fx.shown and k2 > 0.002)
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


# ================================================================ burning ground / hoarfrost

func _start_patch(frost: bool, p: Vector3, owner_node: Node3D) -> void:
	var fx := Fx.new()
	fx.kind = K_PATCH
	fx.id = &"hoarfrost" if frost else &"burning_ground"
	fx.frost = frost
	fx.unit = owner_node
	fx.team = _team_of(owner_node)
	fx.point = p
	fx.life = HOAR_TIME if frost else BURN_TIME
	fx.dur = fx.life + 0.85
	var rim_at := 0.92
	var size := (HOAR_RADIUS if frost else BURN_RADIUS) / rim_at
	var mark := _take(fx, &"mark", &"ground")
	if mark:
		mark.transform = Transform3D(Basis(Vector3.UP, randf() * TAU) * Basis.from_scale(Vector3(size, 1.0, size)),
				p + Vector3.UP * _ground_y())
		_params(mark, {&"pattern": float(G_HOAR if frost else G_BURN), &"seed": randf() * 10.0, &"radius": size,
				&"rim_at": rim_at, &"arc": 0.5, &"heat": 0.0, &"front": 0.0, &"rim": 0.0, &"fade": 0.0,
				&"glow": _hdr(FROST, 1.3) if frost else _hdr(FIRE, 1.6),
				&"cover": _lin(RIME, 0.72) if frost else _lin(SOOT, 0.8)})
	fx.anchors[&"centre"] = Transform3D(Basis.IDENTITY, p + Vector3.UP * 0.05)
	fx.anchors[&"mist"] = Transform3D(Basis.IDENTITY, p + Vector3.UP * 0.4)
	if frost:
		_stream(fx, &"frost_mist", &"mist", 0.0, fx.life - 0.6)
	else:
		_stream(fx, &"ground_flames", &"centre", 0.0, fx.life - 0.3)
	_start(fx)


func _tick_patch(fx: Fx) -> void:
	var t := fx.t
	var T := fx.life
	var n: GeometryInstance3D = fx.nodes.get(&"mark")
	if n == null:
		return
	if t > 0.45 and t < T - 0.65 and fx.t_last_full > 0.45:
		_vis(n, fx.shown)   # steady middle: every uniform is already at its value
		return
	fx.t_last_full = t
	var heat := clampf(t / 0.18, 0.0, 1.0) * (1.0 - smoothstep(T - 0.6, T, t))
	var rim := clampf(t / 0.25, 0.0, 1.0) * (1.0 - smoothstep(T - 0.3, T, t))
	var front := _ease_out(clampf(t / (0.4 if fx.frost else 0.22), 0.0, 1.0))
	var fade := 1.0 - smoothstep(T, T + 0.8, t)
	_uf(n, &"heat", heat)
	_uf(n, &"rim", rim)
	_uf(n, &"front", front)
	_uf(n, &"fade", fade)
	_vis(n, fx.shown and fade > 0.002)


# ================================================================ crash

func _start_crash(frost: bool, p: Vector3, owner_node: Node3D) -> void:
	var fx := Fx.new()
	fx.kind = K_CRASH
	fx.id = &"frost_crash" if frost else &"dragon_crash"
	fx.frost = frost
	fx.unit = owner_node if _alive_node(owner_node) else null
	fx.team = _team_of(fx.unit)
	fx.point = p
	fx.dur = 5.0
	fx.life = 5.0
	var seed := randf() * 10.0
	var crater := _take(fx, &"crater", &"ground")
	if crater:
		var size := 3.8 if frost else 3.6
		crater.transform = Transform3D(Basis(Vector3.UP, randf() * TAU) * Basis.from_scale(Vector3(size, 1.0, size)),
				p + Vector3.UP * _ground_y())
		_params(crater, {&"pattern": float(G_CRATER_ICE if frost else G_CRATER_FIRE), &"seed": seed, &"radius": size,
				&"rim": 0.0, &"rim_at": 0.9, &"arc": 0.5, &"heat": 1.0, &"front": 0.0, &"fade": 0.0,
				&"glow": _hdr(FROST_HOT, 1.3) if frost else _hdr(FIRE, 2.2),
				&"cover": _lin(Color(0.7, 0.84, 0.95), 0.78) if frost else _lin(Color(0.05, 0.04, 0.035), 0.85)})
	var shock := _take(fx, &"shock", &"ring")
	if shock:
		shock.transform = Transform3D(Basis.from_scale(Vector3(1.0, 1.0, 1.0)), p + Vector3.UP * _ground_y())
		_params(shock, {&"pattern": float(R_SHOCK), &"seed": seed,
				&"tint": _hdr(FROST_HOT, 1.1) if frost else _hdr(Color(1.0, 0.72, 0.42), 1.6)})
	var dust := _take(fx, &"dust_ring", &"ring")
	if dust:
		dust.transform = Transform3D(Basis.from_scale(Vector3(2.2, 1.0, 2.2)), p + Vector3.UP * _ground_y())
		_params(dust, {&"pattern": float(R_SOOT), &"seed": seed + 2.0,
				&"tint": _lin(SNOW) if frost else _lin(Color(0.36, 0.3, 0.23))})
	var flash := _take(fx, &"flash", &"flare")
	_params(flash, {&"tint": _hdr(FROST_HOT, 1.2) if frost else _hdr(FIRE_HOT, 1.4), &"rays": 0.5, &"spikes": 8.0,
			&"pulse": 0.0, &"seed": seed, &"halo": Color(0, 0, 0, 0)})
	fx.anchors[&"impact"] = Transform3D(Basis.IDENTITY, p + Vector3.UP * 0.25)
	fx.anchors[&"ground"] = Transform3D(Basis.IDENTITY, p + Vector3.UP * 0.7)
	if frost:
		_sched(fx, &"snow_dust", 0.0, &"ground")
		_sched(fx, &"ice_shards", 0.0, &"impact")
		_sched(fx, &"ice_glints", 0.03, &"impact")
		_sched(fx, &"cold_mist", 0.14, &"ground")
	else:
		_sched(fx, &"crash_dust", 0.0, &"ground")
		_sched(fx, &"crash_clods", 0.0, &"impact")
		_sched(fx, &"crash_embers", 0.0, &"impact")
		_sched(fx, &"crash_smoke", 0.14, &"ground")
	_start(fx)


func _tick_crash(fx: Fx) -> void:
	var t := fx.t
	var crater: GeometryInstance3D = fx.nodes.get(&"crater")
	if crater:
		var fade := clampf(t / 0.05, 0.0, 1.0) * (1.0 - smoothstep(3.8, 4.9, t))
		_uf(crater, &"front", _ease_out(clampf(t / 0.14, 0.0, 1.0)))
		_uf(crater, &"heat", 1.0 - smoothstep(0.3, 3.5 if fx.frost else 3.0, t))
		_uf(crater, &"fade", fade)
		_vis(crater, fx.shown and fade > 0.002)
	var shock: GeometryInstance3D = fx.nodes.get(&"shock")
	if shock:
		var r := lerpf(1.0, 6.5, _ease_out(clampf(t / 0.5, 0.0, 1.0)))
		var f := clampf(t / 0.03, 0.0, 1.0) * (1.0 - smoothstep(0.2, 0.6, t))
		_xf(shock, Transform3D(Basis.from_scale(Vector3(r, 1.0, r)), shock.transform.origin))
		_uf(shock, &"radius", r)
		_uf(shock, &"fade", f)
		_uf(shock, &"age", minf(t, 1.05))
		_vis(shock, fx.shown and f > 0.002)
	var dust: GeometryInstance3D = fx.nodes.get(&"dust_ring")
	if dust:
		var r2 := lerpf(2.2, 4.8, _ease_out(clampf(t / 1.0, 0.0, 1.0)))
		var f2 := clampf(t / 0.1, 0.0, 1.0) * 0.9 * (1.0 - smoothstep(0.9, 1.9, t))
		_xf(dust, Transform3D(Basis.from_scale(Vector3(r2, 1.0, r2)), dust.transform.origin))
		_uf(dust, &"radius", r2)
		_uf(dust, &"fade", f2)
		_vis(dust, fx.shown and f2 > 0.002)
	var flash: GeometryInstance3D = fx.nodes.get(&"flash")
	if flash:
		var s := lerpf(2.0, 4.2, _ease_out(clampf(t / 0.1, 0.0, 1.0)))
		var f3 := 1.0 - smoothstep(0.05, 0.25, t)
		_xf(flash, Transform3D(Basis.from_scale(Vector3.ONE * s), fx.point + Vector3.UP * 1.0))
		_uf(flash, &"fade", f3)
		_vis(flash, fx.shown and f3 > 0.002)


# ================================================================ trails

func _ensure_trail(src: Node3D, unit: Node3D, frost: bool) -> void:
	for tr in _trails:
		if tr.model == src:
			return
	var tr := Trail.new()
	tr.model = src
	tr.unit = unit
	tr.frost = frost
	tr.look = &"frost_trail" if frost else &"ember_trail"
	tr.check_left = 0.0
	_trails.append(tr)


func _tick_trails(dt: float) -> void:
	for i in range(_trails.size() - 1, -1, -1):
		var tr := _trails[i]
		if not _alive_node(tr.model):
			_trail_stop(tr)
			_trails.remove_at(i)
			continue
		# Speed, camera distance, life and visibility are sampled 4 times per second (cheap for far dragons).
		tr.acc += dt
		tr.check_left -= dt
		if tr.check_left <= 0.0:
			tr.check_left = CHECK_INTERVAL
			var body := _body_pos(tr)
			if tr.has_prev and tr.acc > 0.0:
				tr.speed = Vector2(body.x - tr.prev.x, body.z - tr.prev.z).length() / tr.acc
			tr.prev = body
			tr.has_prev = true
			tr.acc = 0.0
			if tr.unit == null:
				tr.unit = _unit_of(tr.model)
			tr.near = _has_cam and _cam_pos.distance_to(body) < TRAIL_RANGE
			var alive := true
			if _alive_node(tr.unit) and tr.unit.has_method(&"is_alive"):
				alive = bool(tr.unit.call(&"is_alive"))
			tr.ok = alive and _clock - tr.crashed_t > 3.0 and tr.model.is_visible_in_tree()
		var want := tr.near and tr.ok and tr.speed > TRAIL_MIN_SPEED
		if want and tr.p == null:
			var free: Array = _stream_free[tr.look]
			if not free.is_empty():
				tr.p = free.pop_back()
				tr.p.transform = _trail_xf(tr.model, _body_pos(tr))
				tr.p.visible = true
				tr.p.restart()
				tr.p.emitting = true
		if tr.p:
			if want:
				tr.p.transform = _trail_xf(tr.model, _body_pos(tr))
			else:
				_trail_stop(tr)


func _trail_stop(tr: Trail) -> void:
	if tr.p == null:
		return
	tr.p.emitting = false
	_draining.append({"p": tr.p, "look": tr.look, "left": tr.p.lifetime + 0.1})
	tr.p = null


## The trail emitter sits on the body, a little behind, turned with it (the box spans the wings).
func _trail_xf(model: Node3D, body: Vector3) -> Transform3D:
	var fwd := _flat(model.global_transform.basis.z)
	return Transform3D(_basis_z(fwd), body - fwd * 1.3)


func _body_pos(tr: Trail) -> Vector3:
	if tr.body == null or not is_instance_valid(tr.body):
		tr.body = tr.model.get_node_or_null(^"Root/Body") as Node3D
		if tr.body == null:
			tr.body = tr.model
	if tr.body == tr.model:
		return tr.model.global_position + Vector3.UP * FLY_HEIGHT
	return tr.body.global_position


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
		K_PATCH:
			_tick_patch(fx)
		_:
			_tick_crash(fx)
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


## Fog / hidden dragons (4 times per second).
func _refresh(fx: Fx) -> void:
	if fx.follow:
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

func _is_flyer(n: Object) -> bool:
	return n.has_signal(&"breath_released") and n.has_signal(&"crashed") and n.has_method(&"get_breath_origin")


func _model_is_frost(model: Node3D) -> bool:
	if model.has_meta(&"titan_vfx_kind"):
		return StringName(str(model.get_meta(&"titan_vfx_kind"))) == &"frost"
	var s: Script = model.get_script()
	return s != null and s.resource_path.get_file().begins_with("frost")


## [model, unit] for a target that is a dragon model, a Unit with such a model, or any other node (its own unit).
func _resolve(t: Node3D) -> Array:
	if t == null:
		return [null, null]
	if _is_flyer(t):
		if not _att.has(t):
			attach(t)
		return [t, _unit_of(t)]
	if t.has_method(&"get_model"):
		var m: Variant = t.call(&"get_model")
		if m is Node3D and is_instance_valid(m) and _is_flyer(m):
			if not _att.has(m):
				attach(m)
			return [m, t]
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


func _aim_of(at: Variant) -> Variant:
	if at is Vector3 or at is Transform3D:
		return at
	if typeof(at) == TYPE_OBJECT and is_instance_valid(at) and at is Node3D and (at as Node3D).is_inside_tree():
		return (at as Node3D).global_position
	return null


func _point_of(at: Variant, fallback: Node3D) -> Variant:
	if at is Vector3:
		return at
	if at is Transform3D:
		return (at as Transform3D).origin
	if typeof(at) == TYPE_OBJECT and is_instance_valid(at) and at is Node3D and (at as Node3D).is_inside_tree():
		return (at as Node3D).global_position
	if _alive_node(fallback):
		return fallback.global_position
	return null


func _unit_mouth(unit: Node3D) -> Transform3D:
	return unit.global_transform * Transform3D(Basis.IDENTITY, Vector3(0.0, FLY_HEIGHT + 0.9, MOUTH_AHEAD))


func _alive_node(n: Variant) -> bool:
	return n != null and is_instance_valid(n) and (n as Node).is_inside_tree()


func _flat(v: Vector3) -> Vector3:
	var f := Vector3(v.x, 0.0, v.z)
	return f.normalized() if f.length() > 0.0001 else Vector3(0.0, 0.0, 1.0)


## Yaw that turns local +Z onto `d` (flat).
func _yaw_z(d: Vector3) -> float:
	return atan2(d.x, d.z)


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
	var meshes := {&"jet": _cone_mesh(), &"ground": plane, &"ring": plane, &"flare": quad}
	var mats := {&"jet": _shader_mat(BREATH_SHADER), &"ground": _shader_mat(GROUND_SHADER),
			&"ring": _shader_mat(RING_SHADER), &"flare": _shader_mat(FLARE_SHADER)}
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


## The jet cone: apex at the origin, axis +Z, length 1, radius 1 at the far end (a slightly bulging flare shape).
## UV.x around (0-1), UV.y along (0 = mouth).
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
	if BIG_LOOKS.has(look):
		p.visibility_aabb = AABB(Vector3(-8.0, -6.0, -8.0), Vector3(16.0, 14.0, 16.0))
	else:
		p.visibility_aabb = AABB(Vector3(-5.0, -3.0, -5.0), Vector3(10.0, 9.0, 10.0))
	return p


## Draw passes: textured billboard quads (never a bare square: every one has a shape mask and keeps the particle
## scale, Godot 4.7) + velocity-aligned sparks (combat_streak.gdshader).
func _build_passes() -> void:
	_passes[&"add_puff"] = _particle_quad(_shape_tex(&"puff"), BaseMaterial3D.BLEND_MODE_ADD, true)
	_passes[&"add_flame"] = _particle_quad(_shape_tex(&"flame"), BaseMaterial3D.BLEND_MODE_ADD, true)
	_passes[&"add_dot"] = _particle_quad(_shape_tex(&"dot"), BaseMaterial3D.BLEND_MODE_ADD)
	_passes[&"add_star"] = _particle_quad(_shape_tex(&"star"), BaseMaterial3D.BLEND_MODE_ADD)
	_passes[&"add_shard"] = _particle_quad(_shape_tex(&"shard"), BaseMaterial3D.BLEND_MODE_ADD)
	_passes[&"mix_puff"] = _particle_quad(_shape_tex(&"puff"), BaseMaterial3D.BLEND_MODE_MIX, true)
	_passes[&"mix_dot"] = _particle_quad(_shape_tex(&"dot"), BaseMaterial3D.BLEND_MODE_MIX)
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
		# Big puffs cut into the ground: soften the cut (no hard line where they meet it).
		mat.proximity_fade_enabled = true
		mat.proximity_fade_distance = 0.3
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
				&"shard":
					# A long crystal splinter: a kite with a lit facet and a dark facet, a bright ridge.
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
	var smoke_cols := _lin_all([SMOKE, Color(0.14, 0.12, 0.11), Color(0.28, 0.24, 0.21)])
	var snow_cols := [_hdr(SNOW, 1.25), _hdr(RIME, 1.15), _hdr(Color(0.86, 0.94, 1.0), 1.3)]
	var dust_cols := _lin_all([DUST, Color(0.48, 0.4, 0.28), Color(0.64, 0.56, 0.42)])
	match key:
		&"fire_jet":
			_shape_sphere(m, 0.22)
			m.direction = Vector3(0, 0, 1)
			m.spread = 11.0
			m.initial_velocity_min = 9.0
			m.initial_velocity_max = 12.0
			m.damping_min = 5.0
			m.damping_max = 7.0
			m.gravity = Vector3(0, 0.8, 0)
			_spin(m, 120.0)
			m.scale_min = 1.0
			m.scale_max = 1.6
			m.scale_curve = _curve([Vector2(0.0, 0.3), Vector2(0.5, 0.85), Vector2(1.0, 1.0)])
			m.color_ramp = _ramp_at([0.0, 0.25, 0.6, 1.0], [_hdr(FIRE_HOT, 1.9, 0.75), _hdr(FIRE, 1.6, 0.7),
					_hdr(FIRE_DEEP, 1.2, 0.5), _hdr(FIRE_DEEP, 0.8, 0.0)])
		&"fire_splash":
			_shape_box(m, Vector3(1.5, 0.1, 1.7))
			m.direction = Vector3(0, 0.55, 1)
			m.spread = 40.0
			m.initial_velocity_min = 2.0
			m.initial_velocity_max = 4.2
			m.damping_min = 1.5
			m.damping_max = 2.5
			m.gravity = Vector3(0, 2.8, 0)
			m.angle_min = -10.0
			m.angle_max = 10.0
			m.scale_min = 0.8
			m.scale_max = 1.35
			m.scale_curve = _curve([Vector2(0.0, 0.35), Vector2(0.3, 1.0), Vector2(1.0, 0.45)])
			m.color_ramp = _ramp_at([0.0, 0.2, 0.6, 1.0], [_hdr(FIRE_HOT, 2.0, 0.8), _hdr(FIRE, 1.7, 0.75),
					_hdr(FIRE_DEEP, 1.2, 0.55), _hdr(FIRE_DEEP, 0.8, 0.0)])
		&"fire_sparks":
			_shape_box(m, Vector3(1.4, 0.1, 1.5))
			m.direction = Vector3(0, 1, 0.6)
			m.spread = 50.0
			m.initial_velocity_min = 4.0
			m.initial_velocity_max = 8.5
			m.damping_min = 1.0
			m.damping_max = 2.0
			m.gravity = Vector3(0, -7.0, 0)
			m.particle_flag_align_y = true
			_size(m, 0.05, 0.085, &"shrink")
			m.color_ramp = _ramp([_hdr(Color(1.0, 0.96, 0.8), 3.2), _hdr(FIRE, 2.4), _hdr(FIRE, 1.2, 0.0)])
		&"frost_jet":
			_shape_sphere(m, 0.25)
			m.direction = Vector3(0, 0, 1)
			m.spread = 13.0
			m.initial_velocity_min = 8.0
			m.initial_velocity_max = 11.0
			m.damping_min = 5.0
			m.damping_max = 7.0
			m.gravity = Vector3(0, -0.5, 0)
			_spin(m, 70.0)
			m.scale_min = 1.0
			m.scale_max = 1.45
			m.scale_curve = _curve([Vector2(0.0, 0.3), Vector2(0.5, 0.85), Vector2(1.0, 1.0)])
			m.color_initial_ramp = _ramp(snow_cols)
			m.color_ramp = _ramp_at([0.0, 0.12, 0.6, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.9),
					Color(1, 1, 1, 0.6), Color(1, 1, 1, 0.0)])
		&"frost_glints":
			_shape_sphere(m, 0.4)
			m.direction = Vector3(0, 0, 1)
			m.spread = 18.0
			m.initial_velocity_min = 6.0
			m.initial_velocity_max = 10.0
			m.damping_min = 4.0
			m.damping_max = 6.0
			m.gravity = Vector3(0, -1.0, 0)
			_spin(m, 200.0)
			_size(m, 0.14, 0.26, &"hold")
			m.color_ramp = _ramp_at([0.0, 0.1, 0.55, 1.0], [_hdr(FROST_HOT, 3.4, 0.0), _hdr(FROST_HOT, 3.4),
					_hdr(FROST, 2.6), _hdr(FROST, 1.5, 0.0)])
		&"frost_splash":
			_shape_box(m, Vector3(1.6, 0.1, 1.8))
			m.direction = Vector3(0, 0.35, 1)
			m.spread = 45.0
			m.initial_velocity_min = 1.5
			m.initial_velocity_max = 3.4
			m.damping_min = 1.2
			m.damping_max = 2.0
			m.gravity = Vector3(0, 0.25, 0)
			_spin(m, 40.0)
			_size(m, 1.1, 1.8, &"grow")
			m.color_initial_ramp = _ramp(snow_cols)
			m.color_ramp = _ramp_at([0.0, 0.15, 0.6, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.75),
					Color(1, 1, 1, 0.45), Color(1, 1, 1, 0.0)])
		&"ground_flames":
			_shape_disc(m, 1.7)
			m.direction = Vector3.UP
			m.spread = 8.0
			m.initial_velocity_min = 0.4
			m.initial_velocity_max = 0.9
			m.damping_min = 0.6
			m.damping_max = 1.0
			m.gravity = Vector3(0, 1.2, 0)
			m.angle_min = -8.0
			m.angle_max = 8.0
			m.scale_min = 0.42
			m.scale_max = 0.72
			m.scale_curve = _curve([Vector2(0.0, 0.25), Vector2(0.3, 1.0), Vector2(1.0, 0.15)])
			m.color_ramp = _ramp_at([0.0, 0.25, 0.65, 1.0], [_hdr(FIRE_HOT, 2.6), _hdr(FIRE, 2.2),
					_hdr(FIRE_DEEP, 1.3, 0.7), _hdr(FIRE_DEEP, 0.8, 0.0)])
		&"frost_mist":
			_shape_disc(m, 2.1)
			m.direction = Vector3.UP
			m.spread = 70.0
			m.initial_velocity_min = 0.1
			m.initial_velocity_max = 0.35
			m.radial_velocity_min = 0.15
			m.radial_velocity_max = 0.45
			m.damping_min = 0.2
			m.damping_max = 0.4
			m.gravity = Vector3(0, -0.05, 0)
			_spin(m, 20.0)
			_size(m, 1.1, 1.7, &"grow")
			m.color_initial_ramp = _ramp([_hdr(RIME, 1.15), _hdr(SNOW, 1.2), _hdr(FROST, 1.1)])
			m.color_ramp = _ramp_at([0.0, 0.25, 0.7, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.42),
					Color(1, 1, 1, 0.3), Color(1, 1, 1, 0.0)])
		&"ember_trail":
			_shape_box(m, Vector3(2.4, 0.2, 0.5))
			m.direction = Vector3(0, -0.3, -1)
			m.spread = 35.0
			m.initial_velocity_min = 0.3
			m.initial_velocity_max = 1.2
			m.damping_min = 0.4
			m.damping_max = 0.8
			m.gravity = Vector3(0, -0.5, 0)
			m.turbulence_enabled = true
			m.turbulence_noise_strength = 0.6
			m.turbulence_noise_scale = 3.0
			m.turbulence_influence_min = 0.05
			m.turbulence_influence_max = 0.15
			_size(m, 0.15, 0.26, &"hold")
			m.color_ramp = _ramp_at([0.0, 0.3, 0.7, 1.0], [_hdr(FIRE_HOT, 3.4), _hdr(FIRE, 2.8), _hdr(FIRE_DEEP, 1.6),
					_hdr(FIRE_DEEP, 1.0, 0.0)])
		&"frost_trail":
			_shape_box(m, Vector3(2.6, 0.2, 0.5))
			m.direction = Vector3(0, -0.5, -1)
			m.spread = 35.0
			m.initial_velocity_min = 0.3
			m.initial_velocity_max = 1.0
			m.damping_min = 0.3
			m.damping_max = 0.6
			m.gravity = Vector3(0, -1.2, 0)
			_spin(m, 260.0)
			_size(m, 0.16, 0.28, &"hold")
			m.color_ramp = _ramp_at([0.0, 0.15, 0.7, 1.0], [_hdr(FROST_HOT, 3.0, 0.0), _hdr(FROST_HOT, 3.0),
					_hdr(FROST, 2.2), _hdr(FROST_TEAM, 1.4, 0.0)])
		&"breath_smoke":
			_shape_box(m, Vector3(1.7, 0.2, 1.9))
			m.direction = Vector3.UP
			m.spread = 25.0
			m.initial_velocity_min = 0.8
			m.initial_velocity_max = 1.6
			m.damping_min = 0.6
			m.damping_max = 1.0
			m.gravity = Vector3(0, 0.4, 0)
			_spin(m, 30.0)
			_size(m, 1.1, 1.9, &"grow")
			m.color_initial_ramp = _ramp(smoke_cols)
			m.color_ramp = _ramp_at([0.0, 0.15, 0.6, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.55),
					Color(1, 1, 1, 0.35), Color(1, 1, 1, 0.0)])
		&"rime_linger":
			_shape_box(m, Vector3(2.0, 0.1, 2.2))
			m.direction = Vector3.UP
			m.spread = 70.0
			m.initial_velocity_min = 0.15
			m.initial_velocity_max = 0.45
			m.damping_min = 0.2
			m.damping_max = 0.4
			m.gravity = Vector3(0, -0.05, 0)
			_spin(m, 20.0)
			_size(m, 1.3, 2.1, &"grow")
			m.color_initial_ramp = _ramp([_hdr(RIME, 1.1), _hdr(SNOW, 1.15), _hdr(FROST, 1.05)])
			m.color_ramp = _ramp_at([0.0, 0.2, 0.65, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.5),
					Color(1, 1, 1, 0.3), Color(1, 1, 1, 0.0)])
		&"crash_dust", &"snow_dust":
			_shape_ring(m, 1.3, 0.1)
			m.direction = Vector3.UP
			m.spread = 55.0
			m.initial_velocity_min = 1.0
			m.initial_velocity_max = 2.6
			m.radial_velocity_min = 2.2
			m.radial_velocity_max = 3.8
			m.damping_min = 2.6
			m.damping_max = 3.4
			m.gravity = Vector3(0, 0.35, 0)
			_spin(m, 40.0)
			m.scale_min = 1.9
			m.scale_max = 3.1
			m.scale_curve = _curve([Vector2(0.0, 0.35), Vector2(0.35, 1.0), Vector2(1.0, 1.15)])   # the wall billows, never shrinks
			if key == &"snow_dust":
				m.color_initial_ramp = _ramp([_hdr(SNOW, 1.2), _hdr(RIME, 1.1), _hdr(Color(0.8, 0.9, 1.0), 1.2)])
			else:
				m.color_initial_ramp = _ramp(dust_cols)
			m.color_ramp = _ramp_at([0.0, 0.1, 0.6, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.8),
					Color(1, 1, 1, 0.5), Color(1, 1, 1, 0.0)])
		&"crash_clods":
			_shape_sphere(m, 0.9)
			m.direction = Vector3.UP
			m.spread = 60.0
			m.initial_velocity_min = 4.0
			m.initial_velocity_max = 8.0
			m.gravity = Vector3(0, -14.0, 0)
			_spin(m, 180.0)
			_size(m, 0.14, 0.26, &"hold")
			m.color_initial_ramp = _ramp(_lin_all([EARTH, Color(0.2, 0.15, 0.1), Color(0.14, 0.1, 0.08)]))
			m.color_ramp = _ramp_at([0.0, 0.8, 1.0], [Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
		&"crash_embers":
			_shape_sphere(m, 1.0)
			m.direction = Vector3.UP
			m.spread = 70.0
			m.initial_velocity_min = 5.0
			m.initial_velocity_max = 10.0
			m.damping_min = 2.0
			m.damping_max = 3.0
			m.gravity = Vector3(0, -8.0, 0)
			m.particle_flag_align_y = true
			_size(m, 0.06, 0.1, &"shrink")
			m.color_ramp = _ramp([_hdr(Color(1.0, 0.96, 0.8), 3.2), _hdr(FIRE, 2.4), _hdr(FIRE_DEEP, 1.2, 0.0)])
		&"crash_smoke", &"cold_mist":
			_shape_sphere(m, 1.5)
			m.emission_shape_scale = Vector3(1.0, 0.3, 1.0)
			m.direction = Vector3.UP
			m.spread = 25.0 if key == &"crash_smoke" else 70.0
			m.initial_velocity_min = 0.8 if key == &"crash_smoke" else 0.2
			m.initial_velocity_max = 1.5 if key == &"crash_smoke" else 0.5
			m.damping_min = 0.4
			m.damping_max = 0.7
			m.gravity = Vector3(0, 0.5, 0) if key == &"crash_smoke" else Vector3(0, 0.05, 0)
			_spin(m, 25.0)
			_size(m, 1.7, 2.7, &"grow")
			if key == &"crash_smoke":
				m.color_initial_ramp = _ramp(smoke_cols)
			else:
				m.color_initial_ramp = _ramp([_hdr(RIME, 1.1), _hdr(SNOW, 1.15), _hdr(FROST, 1.05)])
			m.color_ramp = _ramp_at([0.0, 0.15, 0.6, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.6),
					Color(1, 1, 1, 0.4), Color(1, 1, 1, 0.0)])
		&"ice_shards":
			_shape_sphere(m, 0.9)
			m.direction = Vector3.UP
			m.spread = 65.0
			m.initial_velocity_min = 4.0
			m.initial_velocity_max = 8.5
			m.gravity = Vector3(0, -13.0, 0)
			_spin(m, 400.0)
			_size(m, 0.24, 0.42, &"hold")
			m.color_initial_ramp = _ramp([_hdr(Color(0.8, 0.93, 1.0), 1.5), _hdr(FROST_HOT, 1.7),
					_hdr(FROST_TEAM, 1.3)])
			m.color_ramp = _ramp_at([0.0, 0.8, 1.0], [Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
		&"ice_glints":
			_shape_sphere(m, 2.2)
			m.emission_shape_scale = Vector3(1.0, 0.4, 1.0)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 0.5
			m.initial_velocity_max = 2.0
			m.gravity = Vector3(0, -1.0, 0)
			_size(m, 0.16, 0.32, &"hold")
			m.color_ramp = _ramp_at([0.0, 0.1, 0.5, 1.0], [_hdr(FROST_HOT, 3.6, 0.0), _hdr(FROST_HOT, 3.6),
					_hdr(FROST, 2.6), _hdr(FROST, 1.4, 0.0)])
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


## Particle sizes in metres + a scale curve: shrink (sparks, embers), grow (smoke, mist), hold (clods, shards).
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
