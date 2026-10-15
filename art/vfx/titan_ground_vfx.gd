class_name TitanGroundVfx
extends Node3D
## Titan effects of the non-dragon titans (task 13.V19, docs/design/cavalry-mounts.md 5.2 / 10). Draw-only: never
## touches gameplay. A FAMILY of TitanVfx: TitanVfx (art/vfx/titan_vfx.gd) creates one child node with this script in
## its _ready and forwards these ids from its play(); callers keep using the one TitanVfx API:
##   get_tree().get_first_node_in_group(&"titan_vfx").play(id, at, target) -> bool
## (This node also works on its own: same play(); it is in group "titan_ground_vfx", never in "titan_vfx".)
##
## `target` may be the titan's Unit (its get_model() is used), the titan model itself, or null. `at` is a world point
## (Vector3), a Node3D (followed or read once, see the id) or null.
## Ids:
##   War Mammoth (WarMammothModel: trample_stomped(at), get_howdah(), get_howdah_muzzle(); howdah shot_released(at))
##   frost_aura      target = the mammoth (or any node): the frost aura ring r 5 on the ground, following it while it
##                   lives (a faint rime rim, 12 crystal ticks turning, glints, the rim pulses once every 7 s with a short
##                   chill ripple; never a filled disc, G-F r2 item 5; rime mist at
##                   the rim within 45 m of the camera). Automatic for every mammoth model: the call only matters for a
##                   unit without the model. Fades out 1 s after death.
##   trample         at = the stomp point, target = the mammoth: a stomp crack with a snowy lip and glowing ice cracks at
##                   the foot, a frost shock ring r 1.6 at the trample centre (1.2 m ahead), snowy dust thrown outward,
##                   ice shards and glints. Automatic on trample_stomped(at); an explicit call for an attached mammoth
##                   MERGES (waits <= 0.4 s for the stomp, ignored within 0.6 s after it).
##   howdah_bolt     at = the shot's target (Node3D: homes on its body, flyers at 4 m; or a Vector3), target = the
##                   mammoth: an ice bolt (crystal + light streak + glints) from the archer's arrow tip at 30 m/s, an
##                   ice burst where it hits (+ a frost splat on the ground when the target is not flying). Automatic on
##                   the howdah's shot_released(at): without an explicit target it flies where the archer aims (9 m).
##                   An explicit call made at play_howdah_shot time waits (<= 0.35 s) for the release and gives it its
##                   target; one made just after (<= 0.4 s) re-targets the flying bolt.
##   Elder Treant (ElderTreantModel: root_changed(rooted), volley_released, is_morphing(), root_progress(), is_rooted(),
##   get_volley_origins())
##   root_morph      target = the treant: the 3 s take-root / uproot. Soil dust rising round the base, clods thrown,
##                   leaves falling from the crown, a torn-soil root bed (r 3.4, root furrows with a green sap line) that
##                   spreads with the roots and STAYS while the treant is rooted, then fades after it uproots. Automatic
##                   (the morph is watched 10 times per second); explicit calls only matter without the model (a 3 s
##                   rooting at `at`).
##   grove_pulse     at = the centre, target = the treant: one grove-aura pulse, a band of leaves and green light racing
##                   out to r 8 in 1.35 s, root veins lighting behind it, motes flung outward, a bloom in the canopy.
##                   Automatic every 4 s while a treant model is rooted (first one when it has rooted); an explicit call
##                   for such a treant merges (nothing extra).
##   thorn_volley    at = the target (Node3D homed / Vector3), target = the treant: 6 thorns (bark spikes with a
##                   glowing tip and a green trail) lobbed from the 3 volley origins, splinters + sap where they land,
##                   ground hits stay stuck for a second. Automatic on volley_released (default: 9 m ahead); explicit
##                   calls merge like the howdah bolt (wait <= 0.35 s / re-target <= 0.45 s).
##   sapling_sprout  at = the Sapling (Node3D: its visibility is used) or a point, target = the treant or null: a burst
##                   of soil and clods, a swirl of leaves, green motes, a small mound with a green ring. Explicit only
##                   (Call the Thicket saplings have their own sprout in SpellVfx).
##   Nightmare Knight
##   knight_knockback at = the knocked unit (Node3D: followed for 0.7 s while it slides) or a point, target = the knight
##                   (the push goes from it to `at`) or null: dust at the unit's feet while it slides and a ploughed
##                   skid from where it stood to where it stops (a point: a 3 m slide is drawn). Explicit only:
##                   gameplay calls it once per unit the charge knocks back (3 m, heroes 1.5, titans 1).
##                   The charge IMPACT itself is CavalryVfx's `charge` (13.V20, a titan-sized version for the Knight;
##                   lead decision): this family never hooks the Knight's charge_struck, so nothing is drawn twice.
##
## Fog: effects of a titan follow its (or the knocked unit's / sapling's) `visible`; the others check FogOfWar.is_visible
## at their point for the other teams (4 times per second). Projectiles follow their shooter.
## Budget: everything is built at _ready and pooled (mesh pools, stream emitters, one-shot bursts): no node, material or
## mesh is created after _ready. 0 lights, no shadows. One ShaderMaterial per shader (own titan_mark, titan_bolt; reused
## read-only champion_ground (rings), champion_flare (glows)), looks set with instance uniforms. Particle quads have a
## shape mask and billboard_keep_scale. Per mammoth: 1 aura mesh (+ 1 mist emitter < 45 m); per stomp 2 meshes + 3
## bursts; per bolt 3 meshes + 1 emitter + 3 bursts; per rooted treant 1 bed mesh (+ 2 emitters while morphing);
## per pulse 2 meshes + 1 burst; per volley 13 meshes + 15 bursts; per sprout 2 meshes + 3 bursts; per knockback
## 1 mesh + 1 emitter + 1 burst.

const GROUP := &"titan_ground_vfx"
const EFFECTS: Array[StringName] = [&"frost_aura", &"trample", &"howdah_bolt", &"root_morph", &"grove_pulse",
		&"thorn_volley", &"sapling_sprout", &"knight_knockback"]

# Numbers from the spec (cavalry-mounts.md 5.1 / 5.2 / 10).
const AURA_RADIUS := 5.0          # War Mammoth frost aura
const TRAMPLE_RADIUS := 1.6       # trample: within 1.6 m of a point 1.2 m ahead
const TRAMPLE_AHEAD := 1.2
const HOWDAH_RANGE := 9.0
const GROVE_RADIUS := 8.0         # Elder Treant grove aura
const GROVE_EVERY := 4.0          # the pulse cadence (13.V19)
const VOLLEY_AHEAD := 9.0         # default thorn landing distance (range 11)
const ROOT_TIME := 3.0            # take root / uproot
const KNOCK_DIST := 3.0           # Knight charge knockback (heroes 1.5, titans 1: a followed unit shows its own)
const NEAR_RANGE := 45.0          # emitters of persistent effects only near the camera
# Looks.
const STOMP_SIZE := 1.5
const BED_SIZE := 3.4
const SPROUT_SIZE := 1.3
const SPLAT_SIZE := 0.9
const SKID_HALF_W := 0.6
const BOLT_SPEED := 24.0
const THORN_SPEED := 18.0
const THORNS := 6
const FLY_HEIGHT := 4.0           # flyers' bodies (cm. 3.3)
const HOWDAH_Y := 4.4             # howdah height without the model
# Glue timing.
const STOMP_WAIT := 0.4
const STOMP_MERGE := 0.6
const SHOT_WAIT := 0.35
const SHOT_MERGE := 0.4
const VOLLEY_WAIT := 0.35
const VOLLEY_MERGE := 0.45
const TREANT_POLL := 0.1
const CHECK_INTERVAL := 0.25
const FOG_RESCAN := 1.0

enum { K_AURA, K_TRAMPLE, K_BOLT, K_MORPH, K_PULSE, K_VOLLEY, K_SPROUT, K_KNOCK }
enum { M_AURA, M_GROVE, M_STOMP, M_ROOT, M_SKID, M_SPROUT, M_SPLAT }   # titan_mark.gdshader
enum { B_ICE, B_THORN, B_STREAK }                                               # titan_bolt.gdshader
const R_SHOCK := 0                                                               # champion_ground.gdshader

## Mesh pools: pool -> size.
const MESH_POOLS := {&"mark": 40, &"aura": 10, &"ring": 12, &"flare": 20, &"bolt": 10, &"thorn": 30, &"streak": 40}
## Stream emitters (emit while an effect runs, follow their anchor): look -> [amount, lifetime, draw pass, pool size].
const STREAMS := {
	&"aura_frost": [14, 2.4, &"mix_puff", 6],
	&"bolt_trail": [18, 0.45, &"add_star", 8],
	&"morph_dust": [22, 1.8, &"mix_puff", 6],
	&"morph_leaves": [12, 2.2, &"mix_leaf", 6],
	&"knock_dust": [16, 0.9, &"mix_puff", 8],
}
## One-shot bursts: look -> [amount, lifetime, draw pass, pool size, explosiveness].
const BURSTS := {
	&"stomp_dust": [18, 1.4, &"mix_puff", 6, 0.95],
	&"stomp_shards": [14, 1.0, &"mix_shard", 6, 1.0],
	&"stomp_glints": [10, 0.8, &"add_star", 6, 0.95],
	&"bolt_hit": [14, 0.55, &"add_star", 6, 1.0],
	&"bolt_shards": [8, 0.75, &"mix_shard", 6, 1.0],
	&"bolt_mist": [6, 1.1, &"mix_puff", 6, 0.9],
	&"morph_burst": [16, 2.0, &"mix_puff", 4, 0.9],
	&"morph_clods": [16, 1.1, &"mix_clod", 4, 0.95],
	&"pulse_motes": [22, 1.6, &"add_dot", 6, 0.85],
	&"thorn_launch": [10, 0.55, &"add_dot", 6, 1.0],
	&"thorn_hit": [8, 0.8, &"mix_shard", 12, 1.0],
	&"thorn_sap": [5, 0.7, &"add_puff", 12, 0.95],
	&"sprout_soil": [14, 1.0, &"mix_clod", 4, 0.95],
	&"sprout_leaves": [14, 1.8, &"mix_leaf", 4, 0.8],
	&"sprout_motes": [12, 1.5, &"add_dot", 4, 0.7],
	&"knock_puff": [10, 1.0, &"mix_puff", 8, 0.95],
}
## Emitters whose particles travel far (bigger visibility box).
const BIG_LOOKS: Array[StringName] = [&"aura_frost", &"pulse_motes", &"morph_burst", &"morph_dust"]

const MARK_SHADER := preload("res://art/vfx/titan_mark.gdshader")
const BOLT_SHADER := preload("res://art/vfx/titan_bolt.gdshader")
const RING_SHADER := preload("res://art/vfx/champion_ground.gdshader")
const FLARE_SHADER := preload("res://art/vfx/champion_flare.gdshader")

# Palette (sRGB; art-keep 0.2). Ice: glow #BFEBFF, team #73BFF2, cloth #265999.
const FROST_HOT := Color(0.93, 0.98, 1.0)
const FROST := Color(0.75, 0.92, 1.0)
const FROST_TEAM := Color(0.45, 0.75, 0.95)
const FROST_DEEP := Color(0.15, 0.35, 0.6)
const RIME := Color(0.82, 0.9, 0.97)
const SNOW := Color(0.94, 0.97, 1.0)
# Nature: glow #BFFF66, team #59B340, cloth #266626, bark #664729.
const LEAF_GLOW := Color(0.75, 1.0, 0.4)
const SAP := Color(0.62, 1.0, 0.38)
const LEAF := Color(0.35, 0.7, 0.25)
const LEAF_DARK := Color(0.15, 0.4, 0.15)
## G-F r2 item 5 (docs/art/gf_r2_ground.md): the grove pulse band in a moss-lime at the value-pass level (LEAF_GLOW
## read as a pale lime ring on the meadow).
const GROVE_RIM := Color(0.62, 0.82, 0.36)
const BARK := Color(0.4, 0.28, 0.16)
const SOIL := Color(0.24, 0.18, 0.12)
const PETAL := Color(1.0, 0.72, 0.84)
const DUST := Color(0.55, 0.46, 0.34)
const EARTH := Color(0.3, 0.22, 0.15)

## Shape masks shared by every instance (built once per run).
static var _tex_cache: Dictionary = {}
## Projectile meshes (built once per run).
static var _mesh_cache: Dictionary = {}


## One running effect.
class Fx:
	extends RefCounted
	var id: StringName
	var kind := 0
	var t := 0.0
	var dur := 1.0
	var hold := false             # persistent (aura, root bed): runs until released
	var release_t := -1.0         # effect time when it was released (then it fades)
	var done := false             # finished and returned to the pools
	var alive := true             # persistent effects: the owner's life, sampled 4 times per second
	var last_pos := Vector3(INF, 0.0, 0.0)
	var model: Node3D             # the titan model (null without one)
	var unit: Node3D              # its Unit / owner (team, visibility)
	var src: Node3D               # a node the effect follows (aura owner, knocked unit)
	var follow: Node3D            # visibility follows this node (null = the fog at `point`)
	var team := -1
	var shown := true
	var check_left := 0.0
	var point := Vector3.ZERO
	var start := Vector3.ZERO
	var dir := Vector3(0.0, 0.0, 1.0)
	var gy := 0.05                # decal lift (layered so marks never z-fight)
	var nodes: Dictionary = {}    # role -> GeometryInstance3D
	var pools: Dictionary = {}    # role -> pool
	var anchors: Dictionary = {}  # anchor -> Transform3D (streams, bursts)
	var streams: Array[Dictionary] = []
	var bursts: Array[Dictionary] = []
	var bursts_left := 0
	var shots: Array[Dictionary] = []   # projectiles (bolt, thorns)
	var data: Dictionary = {}


var _fx: Array[Fx] = []
var _att: Dictionary = {}           # model -> record (Dictionary)
var _pending: Array[Node3D] = []    # models with an explicit call waiting for their signal
var _free: Dictionary = {}          # pool -> Array[GeometryInstance3D]
var _all: Dictionary = {}
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
	_tick_models(delta)
	_tick_pending()
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


# ================================================================ public API

## Plays effect `id` (see the header). Returns true when `id` is one of these effects (handled, even if the fog hides
## it, a pool is full or it merged with an automatic one), false otherwise.
func play(id: StringName, at: Variant, target: Variant = null) -> bool:
	if not EFFECTS.has(id):
		return false
	if not _built or not is_inside_tree():
		return true
	var res := _resolve(_node_arg(target))
	var model: Node3D = res[0]
	var unit: Node3D = res[1]
	var kind: StringName = res[2]
	var owner_node: Node3D = unit if unit else model
	match id:
		&"frost_aura":
			var src: Node3D = model if model else (unit if unit else _node_arg(at))
			if src:
				_ensure_aura(src, unit)
		&"trample":
			_request_trample(at, model if kind == &"mammoth" else null, owner_node)
		&"howdah_bolt":
			_request_bolt(at, model if kind == &"mammoth" else null, owner_node)
		&"root_morph":
			if kind == &"treant":
				_att[model]["poll"] = 0.0   # watched automatically: poll now
			else:
				var p: Variant = _point_of(at, owner_node)
				if p is Vector3:
					_start_bed(p, owner_node, null)
		&"grove_pulse":
			_request_pulse(at, model if kind == &"treant" else null, owner_node)
		&"thorn_volley":
			_request_volley(at, model if kind == &"treant" else null, owner_node)
		&"sapling_sprout":
			var sap := _node_arg(at)
			var p2: Variant = _point_of(at, null)
			if p2 is Vector3:
				_start_sprout(p2, owner_node, sap)
		&"knight_knockback":
			_start_knock(at, owner_node)
	return true


## True when `id` is one of this node's effects.
func handles(id: StringName) -> bool:
	return EFFECTS.has(id)


## Hooks a titan model (War Mammoth, Elder Treant; recognised by their signals). Done automatically
## for every such model entering the tree. Returns true when newly attached.
func attach(model: Node3D) -> bool:
	if model == null or not is_instance_valid(model) or _att.has(model):
		return false
	var kind := _kind_of(model)
	if kind == &"":
		return false
	_att[model] = {"kind": kind, "unit": null, "howdah": null, "aura": null,
			"stomp_t": -99.0, "stomp_wait_t": -99.0, "stomp_at": null,
			"shot_t": -99.0, "shot_fx": null, "shot_wait_t": -99.0, "shot_aim": null,
			"volley_t": -99.0, "volley_fx": null, "volley_wait_t": -99.0, "volley_aim": null,
			"poll": 0.0, "last_k": 0.0, "dir": 0, "bed": null, "rooted_on": false, "pulse_left": 0.0}
	match kind:
		&"mammoth":
			model.connect(&"trample_stomped", _on_stomped.bind(model))
			_hook_howdah(model, _att[model])
		&"treant":
			model.connect(&"root_changed", _on_root_changed.bind(model))
			model.connect(&"volley_released", _on_volley.bind(model))
	model.connect(&"tree_exiting", _on_model_exiting.bind(model))
	return true


## Unhooks a titan model (its aura / root bed fade out).
func detach(model: Node3D) -> void:
	if not _att.has(model):
		return
	var rec: Dictionary = _att[model]
	_att.erase(model)
	_pending.erase(model)
	var srcs: Array = [model, rec["howdah"]]
	for o: Variant in srcs:
		if o == null or not is_instance_valid(o):
			continue
		var obj := o as Object
		for sig: StringName in [&"trample_stomped", &"root_changed", &"volley_released", &"shot_released",
				&"tree_exiting"]:
			if not obj.has_signal(sig):
				continue
			for c: Dictionary in obj.get_signal_connection_list(sig):
				var cb: Callable = c["callable"]
				if cb.get_object() == self:
					obj.disconnect(sig, cb)
	for key: String in ["aura", "bed"]:
		var fx: Variant = rec[key]
		if fx is Fx:
			_release(fx as Fx)


func is_attached(model: Node3D) -> bool:
	return _att.has(model)


## Number of running effects (auras and root beds included).
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


## The running frost aura of a mammoth model / node, or null (tests).
func aura_of(src: Node3D) -> Fx:
	for fx in _fx:
		if fx.kind == K_AURA and fx.src == src and fx.release_t < 0.0:
			return fx
	return null


# ================================================================ auto attach

func _kind_of(n: Object) -> StringName:
	if n.has_signal(&"trample_stomped") and n.has_method(&"get_howdah_muzzle"):
		return &"mammoth"
	if n.has_signal(&"volley_released") and n.has_signal(&"root_changed") and n.has_method(&"get_volley_origins") \
			and n.has_method(&"root_progress"):
		return &"treant"
	return &""


func _on_node_added(n: Node) -> void:
	if n is Node3D and _kind_of(n) != &"":
		attach(n as Node3D)


func _scan(n: Node) -> void:
	if not is_instance_valid(n):
		return
	if n is Node3D and _kind_of(n) != &"":
		attach(n as Node3D)
	for c: Node in n.get_children():
		_scan(c)


func _on_model_exiting(model: Node3D) -> void:
	detach(model)


func _hook_howdah(model: Node3D, rec: Dictionary) -> void:
	if rec["howdah"] != null and is_instance_valid(rec["howdah"]):
		return
	if not model.has_method(&"get_howdah"):
		return
	var h: Variant = model.call(&"get_howdah")
	if h is Node3D and is_instance_valid(h) and (h as Node3D).has_signal(&"shot_released"):
		(h as Node3D).connect(&"shot_released", _on_shot.bind(model))
		rec["howdah"] = h


## Per-frame work for the attached titans: auras, the Treant's morph watch and its pulse cadence.
func _tick_models(dt: float) -> void:
	var gone: Array = []
	for key: Variant in _att:
		if not is_instance_valid(key):
			gone.append(key)
			continue
		var model := key as Node3D
		if not model.is_inside_tree():
			continue
		var rec: Dictionary = _att[model]
		match StringName(rec["kind"]):
			&"mammoth":
				# 4 times per second: the howdah hook (if missing) and a new aura when none runs (spawn, revive).
				rec["poll"] = float(rec["poll"]) - dt
				if float(rec["poll"]) > 0.0:
					continue
				rec["poll"] = CHECK_INTERVAL
				if rec["howdah"] == null:
					_hook_howdah(model, rec)
				var aura: Variant = rec["aura"]
				var running: bool = aura is Fx and not (aura as Fx).done and (aura as Fx).release_t < 0.0
				if not running and _model_alive(model):
					rec["aura"] = _start_aura(model, _unit_of(model))
			&"treant":
				rec["poll"] = float(rec["poll"]) - dt
				if float(rec["poll"]) <= 0.0:
					rec["poll"] = TREANT_POLL
					_poll_treant(model, rec)
				if bool(rec["rooted_on"]):
					rec["pulse_left"] = float(rec["pulse_left"]) - dt
					if float(rec["pulse_left"]) <= 0.0:
						rec["pulse_left"] = GROVE_EVERY
						_start_pulse(model.global_position, _owner_of(model), model)
	for key: Variant in gone:
		_att.erase(key)


## The Treant's morph (take root / uproot) and rooted state, 10 times per second.
func _poll_treant(model: Node3D, rec: Dictionary) -> void:
	var k := clampf(float(model.call(&"root_progress")), 0.0, 1.0)
	var morphing := bool(model.call(&"is_morphing"))
	var alive := _model_alive(model)
	var last := float(rec["last_k"])
	var d := 0
	if morphing and absf(k - last) > 0.0005:
		d = 1 if k > last else -1
	var bed: Fx = null
	if rec["bed"] is Fx and not (rec["bed"] as Fx).done and (rec["bed"] as Fx).release_t < 0.0:
		bed = rec["bed"]
	if alive and d != 0 and d != int(rec["dir"]):
		# A morph phase starts: rooting (d = 1) or uprooting (d = -1), or it reversed mid-way.
		if bed == null:
			bed = _start_bed(model.global_position, _owner_of(model), model)
			rec["bed"] = bed
		if bed:
			_morph_phase(bed, d > 0)
	if morphing:
		if d != 0:
			rec["dir"] = d
	else:
		rec["dir"] = 0
	rec["last_k"] = k
	if bed:
		bed.data["k"] = k
		bed.data["morphing"] = morphing
		if not alive or (not morphing and k <= 0.0):
			_release(bed)
	elif alive and not morphing and k >= 1.0:
		# Rooted without a morph (spawned / loaded rooted): the bed, already spread, no dust.
		bed = _start_bed(model.global_position, _owner_of(model), model)
		if bed:
			bed.data["k"] = 1.0
			bed.data["held"] = true
		rec["bed"] = bed
	var on := alive and not morphing and k >= 1.0
	if on and not bool(rec["rooted_on"]):
		rec["pulse_left"] = GROVE_EVERY
		_start_pulse(model.global_position, _owner_of(model), model)
	rec["rooted_on"] = on


func _on_root_changed(_rooted: bool, model: Node3D) -> void:
	var rec: Dictionary = _att.get(model, {})
	if not rec.is_empty():
		rec["poll"] = 0.0


func _on_stomped(at: Vector3, model: Node3D) -> void:
	var rec: Dictionary = _att.get(model, {})
	if rec.is_empty() or not _alive_node(model):
		return
	rec["stomp_t"] = _clock
	rec["stomp_wait_t"] = -99.0
	_start_trample(at, _owner_of(model), model)


func _on_shot(at: Vector3, model: Node3D) -> void:
	var rec: Dictionary = _att.get(model, {})
	if rec.is_empty() or not _alive_node(model):
		return
	var aim: Variant = null
	if _clock - float(rec["shot_wait_t"]) <= SHOT_WAIT + 0.05:
		aim = _live_aim(rec["shot_aim"])
	rec["shot_wait_t"] = -99.0
	rec["shot_t"] = _clock
	if aim == null:
		aim = _howdah_default_aim(model, rec, at)
	rec["shot_fx"] = _start_bolt(at, aim, _owner_of(model), model)


func _on_volley(model: Node3D) -> void:
	var rec: Dictionary = _att.get(model, {})
	if rec.is_empty() or not _alive_node(model):
		return
	var aim: Variant = null
	if _clock - float(rec["volley_wait_t"]) <= VOLLEY_WAIT + 0.05:
		aim = _live_aim(rec["volley_aim"])
	rec["volley_wait_t"] = -99.0
	rec["volley_t"] = _clock
	rec["volley_fx"] = _start_volley(model.call(&"get_volley_origins"), aim, _owner_of(model), model)


## Explicit calls still waiting for their model's signal: play them anyway when it never came.
func _tick_pending() -> void:
	for i in range(_pending.size() - 1, -1, -1):
		var mv: Variant = _pending[i]
		if not _alive_node(mv) or not _att.has(mv):
			_pending.remove_at(i)
			continue
		var model := mv as Node3D
		var rec: Dictionary = _att[model]
		var waiting := false
		var owner_node := _owner_of(model)
		var st := float(rec["stomp_wait_t"])
		if st > -90.0:
			if _clock - st > STOMP_WAIT:
				rec["stomp_wait_t"] = -99.0
				rec["stomp_t"] = _clock
				var p: Variant = rec["stomp_at"]
				_start_trample(p if typeof(p) == TYPE_VECTOR3 else model.global_position, owner_node, model)
			else:
				waiting = true
		var sh := float(rec["shot_wait_t"])
		if sh > -90.0:
			if _clock - sh > SHOT_WAIT:
				rec["shot_wait_t"] = -99.0
				rec["shot_t"] = _clock
				var from: Vector3 = model.call(&"get_howdah_muzzle")
				var aim: Variant = _live_aim(rec["shot_aim"])
				if aim == null:
					aim = _howdah_default_aim(model, rec, from)
				rec["shot_fx"] = _start_bolt(from, aim, owner_node, model)
			else:
				waiting = true
		var vt := float(rec["volley_wait_t"])
		if vt > -90.0:
			if _clock - vt > VOLLEY_WAIT:
				rec["volley_wait_t"] = -99.0
				rec["volley_t"] = _clock
				rec["volley_fx"] = _start_volley(model.call(&"get_volley_origins"), _live_aim(rec["volley_aim"]),
						owner_node, model)
			else:
				waiting = true
		if not waiting:
			_pending.remove_at(i)


func _wait_for(model: Node3D) -> void:
	if not _pending.has(model):
		_pending.append(model)


# ================================================================ requests

func _request_trample(at: Variant, model: Node3D, owner_node: Node3D) -> void:
	if model and _att.has(model):
		var rec: Dictionary = _att[model]
		if _clock - float(rec["stomp_t"]) < STOMP_MERGE or float(rec["stomp_wait_t"]) > -90.0:
			return
		rec["stomp_wait_t"] = _clock
		rec["stomp_at"] = _point_of(at, model)
		_wait_for(model)
		return
	var p: Variant = _point_of(at, owner_node)
	if p is Vector3:
		_start_trample(p, owner_node, null)


func _request_bolt(at: Variant, model: Node3D, owner_node: Node3D) -> void:
	var aim: Variant = _aim_arg(at)
	if model and _att.has(model):
		var rec: Dictionary = _att[model]
		var fx: Variant = rec["shot_fx"]
		if _clock - float(rec["shot_t"]) < SHOT_MERGE:
			if fx is Fx and not (fx as Fx).done and aim != null:
				_retarget(fx as Fx, aim)
			return
		rec["shot_wait_t"] = _clock
		rec["shot_aim"] = aim
		_wait_for(model)
		return
	if aim == null or owner_node == null:
		return
	var from := owner_node.global_position + Vector3.UP * HOWDAH_Y
	if owner_node.has_method(&"get_howdah_muzzle"):
		from = owner_node.call(&"get_howdah_muzzle")
	_start_bolt(from, aim, owner_node, null)


func _request_volley(at: Variant, model: Node3D, owner_node: Node3D) -> void:
	var aim: Variant = _aim_arg(at)
	if model and _att.has(model):
		var rec: Dictionary = _att[model]
		var fx: Variant = rec["volley_fx"]
		if _clock - float(rec["volley_t"]) < VOLLEY_MERGE:
			if fx is Fx and not (fx as Fx).done and aim != null:
				_retarget(fx as Fx, aim)
			return
		rec["volley_wait_t"] = _clock
		rec["volley_aim"] = aim
		_wait_for(model)
		return
	if owner_node == null:
		return
	# No treant model: the volley leaves from where its canopy would be.
	var b := owner_node.global_transform.basis
	var o := owner_node.global_position
	var origins := PackedVector3Array([o + b * Vector3(-1.4, 4.0, 0.3), o + b * Vector3(1.4, 4.0, 0.3),
			o + b * Vector3(0.0, 4.6, 0.1)])
	_start_volley(origins, aim, owner_node, null)


func _request_pulse(at: Variant, model: Node3D, owner_node: Node3D) -> void:
	if model and _att.has(model) and bool(_att[model]["rooted_on"]):
		return   # the automatic pulse (every 4 s) already shows it
	var p: Variant = _point_of(at, owner_node)
	if p is Vector3:
		_start_pulse(p, owner_node, model)


# ================================================================ frost aura (War Mammoth)

func _ensure_aura(src: Node3D, unit: Node3D) -> void:
	if aura_of(src) != null:
		return
	if _att.has(src):
		var rec: Dictionary = _att[src]
		if rec["aura"] is Fx and not (rec["aura"] as Fx).done and (rec["aura"] as Fx).release_t < 0.0:
			return
		rec["aura"] = _start_aura(src, unit if unit else _unit_of(src))
		return
	_start_aura(src, unit)


func _start_aura(src: Node3D, unit: Node3D) -> Fx:
	var fx := Fx.new()
	fx.kind = K_AURA
	fx.id = &"frost_aura"
	fx.hold = true
	fx.src = src
	fx.model = src if _att.has(src) else null
	fx.unit = unit if _alive_node(unit) else null
	fx.follow = fx.unit if fx.unit else src
	fx.team = _team_of(fx.unit if fx.unit else src)
	fx.point = src.global_position
	fx.gy = _ground_y()
	var ring := _take(fx, &"ring", &"aura")
	_params(ring, {&"pattern": float(M_AURA), &"seed": randf() * 10.0, &"radius": AURA_RADIUS, &"heat": 0.0,
			&"front": 1.0, &"fade": 1.0, &"glow": _hdr(FROST, 1.25), &"cover": _lin(RIME, 0.55)})
	_start(fx)
	return fx


func _tick_aura(fx: Fx) -> void:
	if not _alive_node(fx.src):
		_end_now(fx)
		return
	if fx.release_t < 0.0 and not fx.alive:   # fx.alive is sampled by _refresh (4 times per second)
		fx.release_t = fx.t
	var steady := fx.t > 0.6 and fx.release_t < 0.0
	var pos := fx.src.global_position
	var moved := not pos.is_equal_approx(fx.last_pos)
	var ring: GeometryInstance3D = fx.nodes.get(&"ring")
	if ring:
		if moved:
			fx.last_pos = pos
			fx.point = pos
			ring.transform = Transform3D(Basis.from_scale(Vector3(AURA_RADIUS, 1.0, AURA_RADIUS)), pos + Vector3.UP * fx.gy)
		if steady:
			_uf(ring, &"heat", 1.0)
			_vis(ring, fx.shown)
		else:
			var k_out := 1.0
			if fx.release_t >= 0.0:
				k_out = 1.0 - clampf((fx.t - fx.release_t) / 1.0, 0.0, 1.0)
				if k_out <= 0.0:
					_end_now(fx)
			var heat := smoothstep(0.0, 0.6, fx.t) * k_out
			_uf(ring, &"heat", heat)
			_vis(ring, fx.shown and heat > 0.002)
	elif fx.release_t >= 0.0 and fx.t - fx.release_t > 1.0:
		_end_now(fx)
	# Rime mist rolling at the rim, only near the camera (fx.data.near is sampled by _refresh).
	var want := fx.shown and fx.release_t < 0.0 and bool(fx.data.get("near", false))
	var p: GPUParticles3D = fx.data.get("p")
	if want and p == null:
		var free: Array = _stream_free[&"aura_frost"]
		if not free.is_empty():
			p = free.pop_back()
			p.transform = Transform3D(Basis.IDENTITY, pos + Vector3.UP * 0.15)
			p.visible = true
			p.restart()
			p.emitting = true
			fx.data["p"] = p
	elif p != null:
		if not want:
			_drop_emitter(fx, "p", &"aura_frost")
		elif moved:
			p.transform = Transform3D(Basis.IDENTITY, pos + Vector3.UP * 0.15)


func _src_alive(fx: Fx) -> bool:
	if fx.model:
		return _model_alive(fx.model)
	if _alive_node(fx.unit) and fx.unit.has_method(&"is_alive"):
		return bool(fx.unit.call(&"is_alive"))
	if fx.src.has_method(&"is_alive"):
		return bool(fx.src.call(&"is_alive"))
	return true


# ================================================================ trample

func _start_trample(foot: Vector3, owner_node: Node3D, model: Node3D) -> void:
	var fx := Fx.new()
	fx.kind = K_TRAMPLE
	fx.id = &"trample"
	var body: Node3D = model if _alive_node(model) else (owner_node if _alive_node(owner_node) else null)
	fx.unit = owner_node if _alive_node(owner_node) else null
	fx.follow = fx.unit if fx.unit else body
	fx.team = _team_of(fx.unit if fx.unit else body)
	fx.dir = _flat(body.global_transform.basis.z) if body else Vector3(0.0, 0.0, 1.0)
	var centre := foot
	if body:
		centre = body.global_position + fx.dir * TRAMPLE_AHEAD
		centre.y = foot.y
	fx.point = centre
	fx.start = foot
	fx.dur = 2.4
	var seed := randf() * 10.0
	var mark := _take(fx, &"mark", &"mark")
	if mark:
		mark.transform = Transform3D(Basis(Vector3.UP, randf() * TAU) * Basis.from_scale(Vector3(STOMP_SIZE, 1.0, STOMP_SIZE)),
				foot + Vector3.UP * _ground_y())
		_params(mark, {&"pattern": float(M_STOMP), &"seed": seed, &"radius": STOMP_SIZE, &"heat": 1.0, &"front": 0.0,
				&"fade": 1.0, &"glow": _hdr(FROST, 1.5), &"cover": _lin(Color(0.2, 0.18, 0.16), 0.62)})
	var ring := _take(fx, &"shock", &"ring")
	if ring:
		ring.transform = Transform3D(Basis.IDENTITY, centre + Vector3.UP * _ground_y())
		_params(ring, {&"pattern": float(R_SHOCK), &"seed": seed, &"tint": _hdr(FROST_HOT, 1.0)})
	fx.anchors[&"foot"] = Transform3D(Basis.IDENTITY, foot + Vector3.UP * 0.12)
	fx.anchors[&"centre"] = Transform3D(Basis.IDENTITY, centre + Vector3.UP * 0.15)
	_sched(fx, &"stomp_dust", 0.0, &"centre")
	_sched(fx, &"stomp_shards", 0.0, &"foot")
	_sched(fx, &"stomp_glints", 0.03, &"centre")
	_start(fx)


func _tick_trample(fx: Fx) -> void:
	var t := fx.t
	var mark: GeometryInstance3D = fx.nodes.get(&"mark")
	if mark:
		var fade := 1.0 - smoothstep(1.6, 2.35, t)
		_uf(mark, &"front", _ease_out(clampf(t / 0.12, 0.0, 1.0)))
		_uf(mark, &"heat", 1.0 - 0.75 * smoothstep(0.2, 1.4, t))
		_uf(mark, &"fade", fade)
		_vis(mark, fx.shown and fade > 0.002)
	var ring: GeometryInstance3D = fx.nodes.get(&"shock")
	if ring:
		var r := lerpf(0.5, TRAMPLE_RADIUS + 0.25, _ease_out(clampf(t / 0.32, 0.0, 1.0)))
		var f := clampf(t / 0.03, 0.0, 1.0) * (1.0 - smoothstep(0.18, 0.45, t))
		_xf(ring, Transform3D(Basis.from_scale(Vector3(r, 1.0, r)), ring.transform.origin))
		_uf(ring, &"radius", r)
		_uf(ring, &"fade", f)
		_uf(ring, &"age", minf(t, 1.05))
		_vis(ring, fx.shown and f > 0.002)


# ================================================================ projectiles (howdah bolt, thorn volley)

func _howdah_default_aim(model: Node3D, rec: Dictionary, from: Vector3) -> Vector3:
	var d := _flat(model.global_transform.basis.z)
	var h: Variant = rec["howdah"]
	if h is Node3D and is_instance_valid(h) and (h as Node3D).is_inside_tree():
		var chest := (h as Node3D).global_transform * Vector3(0.0, 1.18, -0.1)
		var v := from - chest
		if v.length() > 0.2:
			d = v.normalized()
	var ground := model.global_position.y
	var end := from + d * HOWDAH_RANGE
	if end.y < ground and d.y < -0.01:
		end = from + d * ((from.y - ground) / -d.y)
	return end


func _start_bolt(from: Vector3, aim: Variant, owner_node: Node3D, model: Node3D) -> Fx:
	var fx := Fx.new()
	fx.kind = K_BOLT
	fx.id = &"howdah_bolt"
	fx.model = model if _alive_node(model) else null
	fx.unit = owner_node if _alive_node(owner_node) else null
	fx.follow = fx.unit if fx.unit else fx.model
	fx.team = _team_of(fx.unit if fx.unit else fx.model)
	fx.start = from
	var to := _target_point(aim, from + Vector3(0.0, -2.0, HOWDAH_RANGE))
	fx.point = to
	var dist := from.distance_to(to)
	var s := {"from": from, "aim": aim, "to": to, "delay": 0.0, "flight": clampf(dist / BOLT_SPEED, 0.1, 0.7),
			"arc": clampf(dist * 0.03, 0.05, 0.4), "launched": true, "done": false, "hit_t": -1.0, "h": &"h0",
			"s": &"s0", "stick": false, "vel": Vector3.ZERO}
	fx.shots.append(s)
	var seed := randf() * 10.0
	var head := _take(fx, &"h0", &"bolt")
	_params(head, {&"pattern": float(B_ICE), &"seed": seed, &"tint": _hdr(FROST, 1.5),
			&"body": _lin(Color(0.2, 0.42, 0.72), 0.85), &"fade": 1.0})
	var streak := _take(fx, &"s0", &"streak")
	_params(streak, {&"pattern": float(B_STREAK), &"seed": seed, &"tint": _hdr(FROST, 2.0), &"fade": 1.0})
	var glow := _take(fx, &"g0", &"flare")
	_params(glow, {&"tint": _hdr(FROST_HOT, 1.1), &"rays": 0.0, &"spikes": 4.0, &"pulse": 1.0, &"seed": seed,
			&"halo": Color(0, 0, 0, 0), &"fade": 0.0})
	fx.anchors[&"h0"] = Transform3D(Basis.IDENTITY, from)
	_stream(fx, &"bolt_trail", &"h0", 0.0, float(s["flight"]))
	fx.dur = float(s["flight"]) + 1.8
	_start(fx)
	return fx


func _start_volley(origins: PackedVector3Array, aim: Variant, owner_node: Node3D, model: Node3D) -> Fx:
	if origins.is_empty():
		return null
	var fx := Fx.new()
	fx.kind = K_VOLLEY
	fx.id = &"thorn_volley"
	fx.model = model if _alive_node(model) else null
	fx.unit = owner_node if _alive_node(owner_node) else null
	fx.follow = fx.unit if fx.unit else fx.model
	fx.team = _team_of(fx.unit if fx.unit else fx.model)
	var body: Node3D = fx.model if fx.model else fx.unit
	var base := body.global_position if body else origins[0] - Vector3.UP * 4.0
	var fwd := _flat(body.global_transform.basis.z) if body else Vector3(0.0, 0.0, 1.0)
	if aim == null:
		aim = base + fwd * VOLLEY_AHEAD
	fx.start = base
	var to := _target_point(aim, base + fwd * VOLLEY_AHEAD)
	fx.point = to
	var flying := _is_flying(aim)
	var spread := 0.35 if _live3d(aim) else 0.85
	var seed := randf() * 10.0
	var last := 0.0
	for i in THORNS:
		var oi := i % origins.size()
		var a := randf() * TAU
		var off := Vector3(cos(a), 0.0, sin(a)) * spread * sqrt(randf())
		var from := origins[oi]
		var dist := from.distance_to(to + off)
		var delay := float(i / origins.size()) * 0.07 + float(oi) * 0.025
		var flight := clampf(dist / THORN_SPEED, 0.3, 0.9)
		var s := {"from": from, "aim": aim, "off": off, "to": to + off, "delay": delay, "flight": flight,
				"arc": 0.4 if flying else clampf(0.16 * dist + 1.0, 1.0, 3.0), "launched": false, "done": false,
				"hit_t": -1.0, "h": StringName("h%d" % i), "s": StringName("s%d" % i), "oi": oi, "stick": false,
				"vel": Vector3.ZERO}
		fx.shots.append(s)
		last = maxf(last, delay + flight)
		var head := _take(fx, StringName("h%d" % i), &"thorn")
		_params(head, {&"pattern": float(B_THORN), &"seed": seed + float(i), &"tint": _hdr(SAP, 1.7),
				&"body": _lin(BARK, 1.0), &"fade": 1.0})
		var streak := _take(fx, StringName("s%d" % i), &"streak")
		_params(streak, {&"pattern": float(B_STREAK), &"seed": seed + float(i), &"tint": _hdr(LEAF_GLOW, 0.9),
				&"fade": 1.0})
	var glow := _take(fx, &"g0", &"flare")
	_params(glow, {&"tint": _hdr(LEAF_GLOW, 1.2), &"rays": 0.4, &"spikes": 6.0, &"pulse": 0.0, &"seed": seed,
			&"halo": Color(0, 0, 0, 0), &"fade": 0.0})
	for oi in origins.size():
		var od := (to - origins[oi])
		fx.anchors[StringName("o%d" % oi)] = Transform3D(_basis_z(od), origins[oi])
		_sched(fx, &"thorn_launch", float(oi) * 0.025, StringName("o%d" % oi))
	fx.dur = last + 1.7
	_start(fx)
	return fx


## A new target for a flying projectile effect: shots not landed yet curve to it.
func _retarget(fx: Fx, aim: Variant) -> void:
	var to0 := _target_point(aim, fx.point)
	fx.point = to0
	for s in fx.shots:
		if bool(s["done"]):
			continue
		var off: Vector3 = s.get("off", Vector3.ZERO)
		s["aim"] = aim
		var lt := fx.t - float(s["delay"])
		if lt > 0.0 and bool(s["launched"]):
			# Restart the flight from where the projectile is now.
			s["from"] = _shot_pos(s, lt)
			s["delay"] = fx.t
			var dist := (s["from"] as Vector3).distance_to(to0 + off)
			s["flight"] = clampf(dist / (BOLT_SPEED if fx.kind == K_BOLT else THORN_SPEED), 0.06, 0.8)
			s["arc"] = minf(float(s["arc"]), 0.3)
		s["to"] = to0 + off
	var last := 0.0
	for s in fx.shots:
		last = maxf(last, float(s["delay"]) + float(s["flight"]))
	fx.dur = maxf(fx.dur, last + (1.8 if fx.kind == K_BOLT else 1.7))


func _shot_pos(s: Dictionary, lt: float) -> Vector3:
	var k := clampf(lt / float(s["flight"]), 0.0, 1.0)
	var from: Vector3 = s["from"]
	var to: Vector3 = s["to"]
	return from.lerp(to, k) + Vector3.UP * float(s["arc"]) * 4.0 * k * (1.0 - k)


func _tick_shots(fx: Fx) -> void:
	var t := fx.t
	var bolt := fx.kind == K_BOLT
	for s in fx.shots:
		var head: GeometryInstance3D = fx.nodes.get(s["h"])
		var streak: GeometryInstance3D = fx.nodes.get(s["s"])
		var lt := t - float(s["delay"])
		if lt < 0.0:
			continue
		if not bool(s["launched"]):
			s["launched"] = true
			if _alive_node(fx.model) and fx.model.has_method(&"get_volley_origins"):
				var o: PackedVector3Array = fx.model.call(&"get_volley_origins")
				var oi := int(s.get("oi", 0))
				if oi < o.size():
					s["from"] = o[oi]
		if not bool(s["done"]):
			# Home on a live target.
			var tn := _live3d(s["aim"])
			if tn:
				s["to"] = _target_point(tn, s["to"]) + (s.get("off", Vector3.ZERO) as Vector3)
			var flight := float(s["flight"])
			var k := lt / flight
			if k >= 1.0:
				s["done"] = true
				s["hit_t"] = t
				_impact(fx, s)
			else:
				var pos := _shot_pos(s, lt)
				var from: Vector3 = s["from"]
				var to: Vector3 = s["to"]
				var vel := (to - from) / flight + Vector3.UP * float(s["arc"]) * 4.0 * (1.0 - 2.0 * k) / flight
				s["vel"] = vel
				var vd := vel.normalized() if vel.length() > 0.01 else Vector3.FORWARD
				if head:
					_xf(head, Transform3D(_basis_z(vd), pos))
					_vis(head, fx.shown)
				if streak:
					# The light trail: from inside the body back along the path (grows from the launch point).
					var h0 := pos - vd * (0.35 if bolt else 0.55)
					var trail := minf((pos - from).length(), 2.6 if bolt else 1.9)
					var tail := h0 - vd * trail
					_xf(streak, Transform3D(_basis_y(h0 - tail, 0.45 if bolt else 0.2), (h0 + tail) * 0.5))
					_vis(streak, fx.shown and trail > 0.05)
				if bolt:
					var g: GeometryInstance3D = fx.nodes.get(&"g0")
					if g:
						_xf(g, Transform3D(Basis.from_scale(Vector3.ONE * 1.3), pos - vd * 0.2))
						_uf(g, &"fade", 0.8)
						_vis(g, fx.shown)
				fx.anchors[s["h"]] = Transform3D(_basis_z(-vd), pos)
				continue
		# Landed.
		var since := t - float(s["hit_t"])
		_vis(streak, false)
		if head:
			if bool(s["stick"]) and since < 1.4:
				var shrink := 1.0 - smoothstep(1.1, 1.4, since)
				var v: Vector3 = s["vel"]
				var vd2 := v.normalized() if v.length() > 0.01 else Vector3.DOWN
				_xf(head, Transform3D(_basis_z(vd2) * Basis.from_scale(Vector3.ONE * maxf(shrink, 0.01)),
						(s["to"] as Vector3) + vd2 * 0.28))
				_vis(head, fx.shown and shrink > 0.01)
			else:
				_vis(head, false)
	# Impact glow (first hit) and the bolt's frost splat.
	if not fx.data.has("hit_t"):
		return
	var g0: GeometryInstance3D = fx.nodes.get(&"g0")
	if g0:
		var since0 := t - float(fx.data["hit_t"])
		var f := (1.0 - smoothstep(0.03, 0.26 if bolt else 0.32, since0)) * (1.0 if bolt else 0.8)
		var s0 := lerpf(1.0, 2.2 if bolt else 2.6, _ease_out(clampf(since0 / 0.1, 0.0, 1.0)))
		_xf(g0, Transform3D(Basis.from_scale(Vector3.ONE * s0), fx.data["hit_at"]))
		_uf(g0, &"fade", f)
		_vis(g0, fx.shown and f > 0.002)
	var splat: GeometryInstance3D = fx.nodes.get(&"splat")
	if splat:
		var since1 := t - float(fx.data["hit_t"])
		var f1 := 1.0 - smoothstep(1.0, 1.7, since1)
		_uf(splat, &"front", _ease_out(clampf(since1 / 0.1, 0.0, 1.0)))
		_uf(splat, &"heat", 1.0 - 0.7 * smoothstep(0.1, 1.2, since1))
		_uf(splat, &"fade", f1)
		_vis(splat, fx.shown and f1 > 0.002)


func _impact(fx: Fx, s: Dictionary) -> void:
	var at: Vector3 = s["to"]
	var aim: Variant = _live_aim(s["aim"])
	if not fx.data.has("hit_t"):
		fx.data["hit_t"] = fx.t
		fx.data["hit_at"] = at + Vector3.UP * 0.2
	var xf := Transform3D(Basis.IDENTITY, at)
	if fx.kind == K_BOLT:
		for st in fx.streams:
			st["off"] = minf(float(st["off"]), fx.t)   # the glint trail stops with the bolt
		if fx.shown:
			_burst(&"bolt_hit", xf)
			_burst(&"bolt_shards", xf)
			_burst(&"bolt_mist", xf)
			var gp: Variant = _ground_under(aim, at)
			if typeof(gp) == TYPE_VECTOR3:
				var splat := _take(fx, &"splat", &"mark")
				if splat:
					splat.transform = Transform3D(Basis(Vector3.UP, randf() * TAU)
							* Basis.from_scale(Vector3(SPLAT_SIZE, 1.0, SPLAT_SIZE)), (gp as Vector3) + Vector3.UP * _ground_y())
					_params(splat, {&"pattern": float(M_SPLAT), &"seed": randf() * 10.0, &"radius": SPLAT_SIZE,
							&"heat": 1.0, &"front": 0.0, &"fade": 1.0, &"glow": _hdr(FROST, 1.4), &"cover": _lin(RIME, 0.7)})
	else:
		# A thorn: splinters and sap; one that lands on open ground stays stuck in it for a moment.
		if fx.shown:
			_burst(&"thorn_hit", xf)
			_burst(&"thorn_sap", xf)
		s["stick"] = typeof(aim) == TYPE_VECTOR3


## The ground point under a hit when the target is on the ground (not flying), else null.
func _ground_under(aim: Variant, at: Vector3) -> Variant:
	if typeof(aim) == TYPE_VECTOR3:
		return Vector3(at.x, (aim as Vector3).y, at.z)
	var n := _live3d(aim)
	if n:
		if _is_flying(n):
			return null
		return Vector3(at.x, n.global_position.y, at.z)
	return at


## A live Node3D in the tree, or null (never touches a freed object with `is`).
func _live3d(v: Variant) -> Node3D:
	if typeof(v) == TYPE_OBJECT and is_instance_valid(v) and v is Node3D and (v as Node3D).is_inside_tree():
		return v as Node3D
	return null


## A usable aim: a Vector3, a live Node3D, else null.
func _live_aim(v: Variant) -> Variant:
	if typeof(v) == TYPE_VECTOR3:
		return v
	return _live3d(v)


func _is_flying(aim: Variant) -> bool:
	var n := _live3d(aim)
	if n == null:
		return false
	if n.has_method(&"is_flying"):
		return bool(n.call(&"is_flying"))
	return n.has_signal(&"breath_released")


## World point to aim a projectile at: a node's body (flyers at 4 m), a point, else `fallback`.
func _target_point(aim: Variant, fallback: Vector3) -> Vector3:
	if typeof(aim) == TYPE_VECTOR3:
		return aim
	var n := _live3d(aim)
	if n == null:
		return fallback
	if _is_flying(n):
		return n.global_position + Vector3.UP * FLY_HEIGHT
	var h := 1.0
	var bh: Variant = n.get(&"body_height")
	if bh == null and n.has_method(&"get_model"):
		var m: Variant = n.call(&"get_model")
		if typeof(m) == TYPE_OBJECT and is_instance_valid(m):
			bh = (m as Object).get(&"body_height")
	if bh != null:
		h = float(bh) * 0.55
	return n.global_position + Vector3.UP * h


# ================================================================ root bed / morph dust (Elder Treant)

## The torn-soil bed under a treant (model) or a standalone 3 s rooting (model null).
func _start_bed(p: Vector3, owner_node: Node3D, model: Node3D) -> Fx:
	var fx := Fx.new()
	fx.kind = K_MORPH
	fx.id = &"root_morph"
	fx.model = model if _alive_node(model) else null
	fx.unit = owner_node if _alive_node(owner_node) else null
	fx.follow = fx.unit if fx.unit else fx.model
	fx.team = _team_of(fx.unit if fx.unit else fx.model)
	fx.point = p
	fx.hold = fx.model != null
	fx.dur = ROOT_TIME + 2.0
	fx.data["k"] = 0.0
	fx.data["morphing"] = false
	fx.data["phase_t"] = -99.0
	fx.data["rooting"] = true
	var mark := _take(fx, &"bed", &"mark")
	if mark:
		mark.transform = Transform3D(Basis(Vector3.UP, randf() * TAU) * Basis.from_scale(Vector3(BED_SIZE, 1.0, BED_SIZE)),
				p + Vector3.UP * _ground_y())
		_params(mark, {&"pattern": float(M_ROOT), &"seed": randf() * 10.0, &"radius": BED_SIZE, &"heat": 0.0,
				&"front": 0.0, &"fade": 0.0, &"glow": _hdr(SAP, 1.3), &"cover": _lin(SOIL, 0.82)})
	fx.anchors[&"base"] = Transform3D(Basis.IDENTITY, p + Vector3.UP * 0.1)
	fx.anchors[&"canopy"] = Transform3D(Basis.IDENTITY, p + Vector3.UP * 3.7)
	_start(fx)
	if fx.model == null:
		_morph_phase(fx, true)
	return fx


## Dust, clods and falling leaves for one take-root (rooting) or uproot phase, from now.
func _morph_phase(fx: Fx, rooting: bool) -> void:
	var t0 := fx.t
	fx.data["phase_t"] = t0
	fx.data["rooting"] = rooting
	_stream(fx, &"morph_dust", &"base", t0, t0 + ROOT_TIME - 0.3)
	_stream(fx, &"morph_leaves", &"canopy", t0 + 0.3, t0 + ROOT_TIME)
	if rooting:
		_sched(fx, &"morph_clods", t0 + 0.15, &"base")
		_sched(fx, &"morph_burst", t0 + 0.25, &"base")
		_sched(fx, &"morph_clods", t0 + 1.0, &"base")
		_sched(fx, &"morph_burst", t0 + 1.5, &"base")
	else:
		_sched(fx, &"morph_clods", t0 + 0.1, &"base")
		_sched(fx, &"morph_burst", t0 + 0.4, &"base")
		_sched(fx, &"morph_clods", t0 + 1.6, &"base")
		_sched(fx, &"morph_burst", t0 + 2.2, &"base")


func _tick_bed(fx: Fx) -> void:
	var t := fx.t
	if fx.hold and fx.release_t < 0.0 and not _alive_node(fx.model):
		_release(fx)
	var since := t - float(fx.data["phase_t"])
	var in_phase := since >= 0.0 and since < ROOT_TIME + 0.4
	var steady := fx.hold and fx.release_t < 0.0 and not in_phase and t > 0.7
	if steady and bool(fx.data.get("steady", false)):
		_vis(fx.nodes.get(&"bed"), fx.shown)   # a rooted treant's bed: every uniform is already at its value
		return
	fx.data["steady"] = steady
	var k := float(fx.data["k"])
	if fx.model == null:
		k = clampf(t / ROOT_TIME, 0.0, 1.0)   # standalone: a plain 3 s rooting
	var rooting := bool(fx.data["rooting"])
	var front := 1.0
	if not bool(fx.data.get("held", false)) and rooting:
		if in_phase:
			k = maxf(k, since / ROOT_TIME)   # smooth between the 10 Hz polls
		front = _ease_out(clampf(k / 0.55, 0.0, 1.0))
	var heat := 0.3
	if in_phase:
		heat = 0.3 + 0.7 * (1.0 - smoothstep(ROOT_TIME - 0.4, ROOT_TIME + 0.4, since)) * smoothstep(0.0, 0.3, since)
	var fade := clampf(t / 0.25, 0.0, 1.0)
	if bool(fx.data.get("held", false)):
		fade = clampf(t / 0.6, 0.0, 1.0)
	if fx.release_t >= 0.0:
		var out := 1.0 - clampf((t - fx.release_t) / 1.8, 0.0, 1.0)
		fade *= out
		if out <= 0.0:
			_end_now(fx)
	elif fx.model == null:
		fade *= 1.0 - smoothstep(fx.dur - 1.4, fx.dur - 0.05, t)
	var mark: GeometryInstance3D = fx.nodes.get(&"bed")
	if mark:
		_uf(mark, &"front", front)
		_uf(mark, &"heat", heat)
		_uf(mark, &"fade", fade)
		_vis(mark, fx.shown and fade > 0.002)


# ================================================================ grove pulse (Elder Treant)

func _start_pulse(p: Vector3, owner_node: Node3D, model: Node3D) -> void:
	var fx := Fx.new()
	fx.kind = K_PULSE
	fx.id = &"grove_pulse"
	fx.model = model if _alive_node(model) else null
	fx.unit = owner_node if _alive_node(owner_node) else null
	fx.follow = fx.unit if fx.unit else fx.model
	fx.team = _team_of(fx.unit if fx.unit else fx.model)
	fx.point = p
	fx.dur = 2.0
	var seed := randf() * 10.0
	var mark := _take(fx, &"wave", &"mark")
	if mark:
		mark.transform = Transform3D(Basis(Vector3.UP, randf() * TAU)
				* Basis.from_scale(Vector3(GROVE_RADIUS, 1.0, GROVE_RADIUS)), p + Vector3.UP * _ground_y())
		_params(mark, {&"pattern": float(M_GROVE), &"seed": seed, &"radius": GROVE_RADIUS, &"heat": 1.0,
				&"front": 0.0, &"fade": 1.0, &"glow": _hdr(GROVE_RIM, 1.0), &"cover": _lin(LEAF_DARK, 0.4)})
	var bloom := _take(fx, &"bloom", &"flare")
	_params(bloom, {&"tint": _hdr(LEAF_GLOW, 1.0), &"rays": 0.0, &"spikes": 6.0, &"pulse": 0.0, &"seed": seed,
			&"halo": Color(0, 0, 0, 0), &"fade": 0.0})
	var crown := p + Vector3.UP * 3.9
	if fx.model and fx.model.has_method(&"get_volley_origins"):
		var o: PackedVector3Array = fx.model.call(&"get_volley_origins")
		if o.size() >= 3:
			crown = o[2]
	fx.data["crown"] = crown
	fx.anchors[&"centre"] = Transform3D(Basis.IDENTITY, p + Vector3.UP * 0.3)
	_sched(fx, &"pulse_motes", 0.05, &"centre")
	_start(fx)


func _tick_pulse(fx: Fx) -> void:
	var t := fx.t
	var mark: GeometryInstance3D = fx.nodes.get(&"wave")
	if mark:
		var front := _ease_out(clampf(t / 1.35, 0.0, 1.0))
		var fade := 1.0 - smoothstep(1.45, 1.98, t)
		_uf(mark, &"front", front)
		_uf(mark, &"heat", clampf(t / 0.08, 0.0, 1.0) * lerpf(1.0, 0.75, front))
		_uf(mark, &"fade", fade)
		_vis(mark, fx.shown and fade > 0.002)
	var bloom: GeometryInstance3D = fx.nodes.get(&"bloom")
	if bloom:
		var k := clampf(t / 0.1, 0.0, 1.0) * (1.0 - smoothstep(0.15, 0.65, t)) * 0.7
		_xf(bloom, Transform3D(Basis.from_scale(Vector3.ONE * lerpf(2.4, 4.2, clampf(t / 0.5, 0.0, 1.0))),
				fx.data["crown"]))
		_uf(bloom, &"fade", k)
		_vis(bloom, fx.shown and k > 0.002)


# ================================================================ sapling sprout

func _start_sprout(p: Vector3, owner_node: Node3D, sapling: Node3D) -> void:
	var fx := Fx.new()
	fx.kind = K_SPROUT
	fx.id = &"sapling_sprout"
	fx.unit = owner_node if _alive_node(owner_node) else null
	fx.follow = sapling if _alive_node(sapling) else null
	fx.team = _team_of(sapling if fx.follow else fx.unit)
	fx.point = p
	fx.dur = 2.4
	var seed := randf() * 10.0
	var mark := _take(fx, &"mound", &"mark")
	if mark:
		mark.transform = Transform3D(Basis(Vector3.UP, randf() * TAU) * Basis.from_scale(Vector3(SPROUT_SIZE, 1.0, SPROUT_SIZE)),
				p + Vector3.UP * _ground_y())
		_params(mark, {&"pattern": float(M_SPROUT), &"seed": seed, &"radius": SPROUT_SIZE, &"heat": 1.0,
				&"front": 0.0, &"fade": 1.0, &"glow": _hdr(SAP, 1.3), &"cover": _lin(SOIL, 0.78)})
	var glow := _take(fx, &"glow", &"flare")
	_params(glow, {&"tint": _hdr(LEAF_GLOW, 1.1), &"rays": 0.35, &"spikes": 5.0, &"pulse": 0.0, &"seed": seed,
			&"halo": Color(0, 0, 0, 0), &"fade": 0.0})
	fx.anchors[&"base"] = Transform3D(Basis.IDENTITY, p + Vector3.UP * 0.1)
	fx.anchors[&"ring"] = Transform3D(Basis.IDENTITY, p + Vector3.UP * 0.25)
	_sched(fx, &"sprout_soil", 0.0, &"base")
	_sched(fx, &"sprout_leaves", 0.04, &"base")
	_sched(fx, &"sprout_motes", 0.1, &"ring")
	_start(fx)


func _tick_sprout(fx: Fx) -> void:
	var t := fx.t
	var mark: GeometryInstance3D = fx.nodes.get(&"mound")
	if mark:
		var fade := 1.0 - smoothstep(1.7, 2.35, t)
		_uf(mark, &"front", _ease_out(clampf(t / 0.18, 0.0, 1.0)))
		_uf(mark, &"heat", 1.0 - 0.8 * smoothstep(0.8, 2.2, t))
		_uf(mark, &"fade", fade)
		_vis(mark, fx.shown and fade > 0.002)
	var glow: GeometryInstance3D = fx.nodes.get(&"glow")
	if glow:
		var k := clampf(t / 0.05, 0.0, 1.0) * (1.0 - smoothstep(0.08, 0.4, t))
		_xf(glow, Transform3D(Basis.from_scale(Vector3.ONE * lerpf(1.2, 2.2, clampf(t / 0.2, 0.0, 1.0))),
				fx.point + Vector3.UP * 0.55))
		_uf(glow, &"fade", k)
		_vis(glow, fx.shown and k > 0.002)


# ================================================================ knockback dust

func _start_knock(at: Variant, pusher: Node3D) -> void:
	var node := _node_arg(at)
	var start: Variant = _point_of(at, null)
	if not (start is Vector3):
		return
	var fx := Fx.new()
	fx.kind = K_KNOCK
	fx.id = &"knight_knockback"
	fx.src = node
	fx.unit = pusher if _alive_node(pusher) else null
	fx.follow = node
	fx.team = _team_of(node if node else fx.unit)
	fx.start = start
	var d := Vector3(0.0, 0.0, 1.0)
	if fx.unit:
		d = _flat((start as Vector3) - fx.unit.global_position)
	fx.dir = d
	fx.point = start
	fx.gy = _ground_y()
	fx.dur = 2.4
	fx.data["end"] = start
	var mark := _take(fx, &"skid", &"mark")
	if mark:
		_params(mark, {&"pattern": float(M_SKID), &"seed": randf() * 10.0, &"radius": 0.3, &"width": SKID_HALF_W,
				&"heat": 0.0, &"front": 1.0, &"fade": 1.0, &"glow": Color(0, 0, 0, 1), &"cover": _lin(DUST, 0.85)})
	fx.anchors[&"feet"] = Transform3D(Basis.IDENTITY, (start as Vector3) + Vector3.UP * 0.1)
	_stream(fx, &"knock_dust", &"feet", 0.0, 0.6)
	_sched(fx, &"knock_puff", 0.0, &"feet")
	_start(fx)


func _tick_knock(fx: Fx) -> void:
	var t := fx.t
	var end: Vector3 = fx.data["end"]
	if t < 0.7:
		if _alive_node(fx.src):
			end = fx.src.global_position
		elif fx.src == null:
			end = fx.start + fx.dir * KNOCK_DIST * _ease_out(clampf(t / 0.35, 0.0, 1.0))
		var v := end - fx.start
		v.y = 0.0
		if v.length() > 6.0:
			end = fx.start + v.normalized() * 6.0
		fx.data["end"] = end
	fx.point = end
	var v2 := end - fx.start
	v2.y = 0.0
	var dl := v2.length()
	var dv := v2 / dl if dl > 0.05 else fx.dir
	var half := maxf(dl, 0.4) * 0.5 + 0.15
	var mark: GeometryInstance3D = fx.nodes.get(&"skid")
	if mark:
		var centre := fx.start + dv * (half - 0.15)
		centre.y = fx.start.y
		_xf(mark, Transform3D(Basis(Vector3.UP, _yaw_x(dv)) * Basis.from_scale(Vector3(half, 1.0, SKID_HALF_W)),
				centre + Vector3.UP * fx.gy))
		_uf(mark, &"radius", half)
		var fade := clampf(t / 0.05, 0.0, 1.0) * (1.0 - smoothstep(1.6, 2.35, t))
		_uf(mark, &"fade", fade)
		_vis(mark, fx.shown and fade > 0.002 and dl > 0.08)
	fx.anchors[&"feet"] = Transform3D(Basis.IDENTITY, end + Vector3.UP * 0.1)


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
		K_AURA:
			_tick_aura(fx)
		K_TRAMPLE:
			_tick_trample(fx)
		K_BOLT, K_VOLLEY:
			_tick_shots(fx)
		K_MORPH:
			_tick_bed(fx)
		K_PULSE:
			_tick_pulse(fx)
		K_SPROUT:
			_tick_sprout(fx)
		_:
			_tick_knock(fx)
	var busy := _tick_streams(fx)
	if fx.bursts_left > 0:
		for b in fx.bursts:
			if b["done"] or fx.t < float(b["on"]):
				continue
			b["done"] = true
			fx.bursts_left -= 1
			if fx.shown:
				_burst(b["look"], fx.anchors.get(b["at"], Transform3D(Basis.IDENTITY, fx.point)))
	if fx.hold:
		return false
	return fx.t >= fx.dur and not busy and fx.bursts_left <= 0


## Persistent effects: start fading now.
func _release(fx: Fx) -> void:
	if fx.release_t < 0.0:
		fx.release_t = fx.t


## Ends an effect at the end of this tick (its pending bursts are dropped, its streams drain).
func _end_now(fx: Fx) -> void:
	fx.hold = false
	fx.dur = fx.t
	fx.bursts_left = 0
	for s in fx.streams:
		s["off"] = minf(float(s["off"]), fx.t)


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
		var xf: Transform3D = fx.anchors.get(s["at"], pe.transform)
		if not xf.is_equal_approx(pe.transform):
			pe.transform = xf
		if pe.visible != fx.shown:
			pe.visible = fx.shown
	return busy


func _drop_emitter(fx: Fx, key: String, look: StringName) -> void:
	var p: GPUParticles3D = fx.data.get(key)
	if p == null:
		return
	p.emitting = false
	_draining.append({"p": p, "look": look, "left": p.lifetime + 0.1})
	fx.data.erase(key)


func _finish(fx: Fx) -> void:
	fx.done = true
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
	if fx.kind == K_AURA:
		_drop_emitter(fx, "p", &"aura_frost")


## Fog / hidden titans (4 times per second).
func _refresh(fx: Fx) -> void:
	if fx.kind == K_AURA and _alive_node(fx.src):
		fx.alive = _src_alive(fx)
		fx.data["near"] = _has_cam and _cam_pos.distance_to(fx.src.global_position) < NEAR_RANGE
	if fx.follow != null:
		if _alive_node(fx.follow):
			fx.shown = fx.follow.is_visible_in_tree()
			return
		if not is_instance_valid(fx.follow):
			fx.follow = null
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
	if n == null:
		return
	var c: Dictionary = _sent[n]
	var old: Variant = c.get(key)
	if old == null or absf(float(old) - v) > 0.003:
		c[key] = v
		n.set_instance_shader_parameter(key, v)


func _xf(n: GeometryInstance3D, xf: Transform3D) -> void:
	if n and not xf.is_equal_approx(n.transform):
		n.transform = xf


func _vis(n: GeometryInstance3D, v: bool) -> void:
	if n and n.visible != v:
		n.visible = v


func _ground_y() -> float:
	_layer = (_layer + 1) % 8
	return 0.045 + 0.006 * float(_layer)


# ---------------------------------------------------------------- small helpers

## [model, unit, kind] for a target that is a titan model, a Unit with such a model, or any other node (its own unit).
func _resolve(t: Node3D) -> Array:
	if t == null:
		return [null, null, &""]
	var k := _kind_of(t)
	if k != &"":
		if not _att.has(t):
			attach(t)
		return [t, _unit_of(t), k]
	if t.has_method(&"get_model"):
		var m: Variant = t.call(&"get_model")
		if m is Node3D and is_instance_valid(m):
			var mk := _kind_of(m as Node3D)
			if mk != &"":
				if not _att.has(m):
					attach(m as Node3D)
				return [m, t, mk]
	return [null, t, &""]


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


## The unit of a model, or the model itself (visibility / team owner).
func _owner_of(model: Node3D) -> Node3D:
	var u := _unit_of(model)
	return u if u else model


## Alive: the Unit's is_alive() when there is one, else the model's glows (0 once it dies).
func _model_alive(model: Node3D) -> bool:
	var u := _unit_of(model)
	if _alive_node(u) and u.has_method(&"is_alive"):
		return bool(u.call(&"is_alive"))
	if model.has_method(&"glow_level"):
		return float(model.call(&"glow_level")) > 0.0
	return true


func _team_of(n: Node) -> int:
	if n == null or not is_instance_valid(n):
		return -1
	var team: Variant = n.get(&"team")
	return int(team) if team != null else -1


func _node_arg(v: Variant) -> Node3D:
	if typeof(v) == TYPE_OBJECT and is_instance_valid(v) and v is Node3D and (v as Node3D).is_inside_tree():
		return v as Node3D
	return null


## A projectile aim: a live Node3D, a Vector3 (a Transform3D gives its origin), or null.
func _aim_arg(at: Variant) -> Variant:
	if at is Vector3:
		return at
	if at is Transform3D:
		return (at as Transform3D).origin
	return _node_arg(at)


func _point_of(at: Variant, fallback: Node3D) -> Variant:
	if at is Vector3:
		return at
	if at is Transform3D:
		return (at as Transform3D).origin
	var n := _node_arg(at)
	if n:
		return n.global_position
	if _alive_node(fallback):
		return fallback.global_position
	return null


func _alive_node(n: Variant) -> bool:
	return n != null and is_instance_valid(n) and (n as Node).is_inside_tree()


func _flat(v: Vector3) -> Vector3:
	var f := Vector3(v.x, 0.0, v.z)
	return f.normalized() if f.length() > 0.0001 else Vector3(0.0, 0.0, 1.0)


## Yaw that turns local +X onto `d` (flat): directional marks (UV.x = the direction).
func _yaw_x(d: Vector3) -> float:
	return atan2(-d.z, d.x)


## An orthonormal basis whose +Z is `d`.
func _basis_z(d: Vector3) -> Basis:
	var z := d.normalized() if d.length() > 0.0001 else Vector3(0.0, 0.0, 1.0)
	var up := Vector3.UP if absf(z.y) < 0.97 else Vector3(0.0, 0.0, -1.0)
	var x := up.cross(z).normalized()
	return Basis(x, z.cross(x), z)


## A streak basis: Y = `y` (its length included), X = `w` wide (titan_bolt.gdshader pattern 2).
func _basis_y(y: Vector3, w: float) -> Basis:
	var l := y.length()
	var yn := y / l if l > 0.0001 else Vector3.UP
	var side := Vector3.UP if absf(yn.y) < 0.97 else Vector3(1.0, 0.0, 0.0)
	var x := side.cross(yn).normalized()
	return Basis(x * w, yn * maxf(l, 0.01), x.cross(yn).normalized() * w)


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
	var mark_mat := _shader_mat(MARK_SHADER)
	var bolt_mat := _shader_mat(BOLT_SHADER)
	var meshes := {&"mark": plane, &"aura": plane, &"ring": plane, &"flare": quad, &"bolt": _proj_mesh(&"bolt"),
			&"thorn": _proj_mesh(&"thorn"), &"streak": quad}
	var mats := {&"mark": mark_mat, &"aura": mark_mat, &"ring": _shader_mat(RING_SHADER),
			&"flare": _shader_mat(FLARE_SHADER), &"bolt": bolt_mat, &"thorn": bolt_mat, &"streak": bolt_mat}
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
			if pool == &"flare" or pool == &"streak":
				m.extra_cull_margin = 3.0      # billboards leave their mesh AABB
			if pool == &"aura":
				m.sorting_offset = -0.5        # under the other marks and the mammoth's feet
			if pool == &"bolt" or pool == &"thorn":
				m.sorting_offset = 0.5
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


## Projectile meshes, tip at the origin, pointing +Z (UV.y 0 tail .. 1 tip), flat-shaded facets.
##   bolt: a six-sided ice crystal 1.0 m long, widest (r 0.085) 0.3 m behind the tip, a short faceted tail.
##   thorn: a curved bark spike 0.85 m long, base r 0.09, bending up toward its tip.
func _proj_mesh(kind: StringName) -> ArrayMesh:
	if _mesh_cache.has(kind):
		return _mesh_cache[kind]
	var seg := 6
	var prof: Array = []   # [z, radius, y offset]
	if kind == &"bolt":
		prof = [[0.0, 0.0, 0.0], [-0.3, 0.12, 0.0], [-0.75, 0.07, 0.0], [-1.05, 0.0, 0.0]]
	else:
		prof = [[0.0, 0.0, 0.0], [-0.22, 0.03, -0.02], [-0.5, 0.06, -0.06], [-0.85, 0.09, -0.1], [-0.9, 0.0, -0.1]]
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var total := absf(float((prof[prof.size() - 1] as Array)[0]))
	for j in prof.size() - 1:
		var a0: Array = prof[j]
		var a1: Array = prof[j + 1]
		for i in seg:
			var t0 := float(i) / float(seg) * TAU + (0.0 if kind == &"bolt" else 0.3)
			var t1 := float(i + 1) / float(seg) * TAU + (0.0 if kind == &"bolt" else 0.3)
			var p00 := Vector3(cos(t0) * float(a0[1]), sin(t0) * float(a0[1]) + float(a0[2]), float(a0[0]))
			var p01 := Vector3(cos(t1) * float(a0[1]), sin(t1) * float(a0[1]) + float(a0[2]), float(a0[0]))
			var p10 := Vector3(cos(t0) * float(a1[1]), sin(t0) * float(a1[1]) + float(a1[2]), float(a1[0]))
			var p11 := Vector3(cos(t1) * float(a1[1]), sin(t1) * float(a1[1]) + float(a1[2]), float(a1[0]))
			var v0 := 1.0 - absf(float(a0[0])) / total
			var v1 := 1.0 - absf(float(a1[0])) / total
			var quad_pts := [[p00, v0], [p10, v1], [p11, v1], [p00, v0], [p11, v1], [p01, v0]]
			var nrm := (p10 - p00).cross(p11 - p00)
			if nrm.length() < 0.00001:
				nrm = (p11 - p00).cross(p01 - p00)
			nrm = nrm.normalized()
			var mid := (p00 + p11) * 0.5
			var axis_pt := Vector3(0.0, float(a0[2]), mid.z)
			if nrm.dot(mid - axis_pt) < 0.0:
				nrm = -nrm
			for q: Array in quad_pts:
				verts.append(q[0])
				norms.append(nrm)
				uvs.append(Vector2(float(i) / float(seg), q[1]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_mesh_cache[kind] = mesh
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
		p.visibility_aabb = AABB(Vector3(-9.0, -4.0, -9.0), Vector3(18.0, 12.0, 18.0))
	else:
		p.visibility_aabb = AABB(Vector3(-5.0, -3.0, -5.0), Vector3(10.0, 9.0, 10.0))
	return p


## Draw passes: textured billboard quads (a shape mask each, billboard_keep_scale, Godot 4.7) + velocity sparks.
func _build_passes() -> void:
	_passes[&"add_puff"] = _particle_quad(_shape_tex(&"puff"), BaseMaterial3D.BLEND_MODE_ADD, true)
	_passes[&"add_dot"] = _particle_quad(_shape_tex(&"dot"), BaseMaterial3D.BLEND_MODE_ADD)
	_passes[&"add_star"] = _particle_quad(_shape_tex(&"star"), BaseMaterial3D.BLEND_MODE_ADD)
	_passes[&"mix_puff"] = _particle_quad(_shape_tex(&"puff"), BaseMaterial3D.BLEND_MODE_MIX, true)
	_passes[&"mix_shard"] = _particle_quad(_shape_tex(&"shard"), BaseMaterial3D.BLEND_MODE_MIX)
	_passes[&"mix_leaf"] = _particle_quad(_shape_tex(&"leaf"), BaseMaterial3D.BLEND_MODE_MIX)
	_passes[&"mix_clod"] = _particle_quad(_shape_tex(&"clod"), BaseMaterial3D.BLEND_MODE_MIX)


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
				&"shard":
					var k := absf(u) / 0.24 + absf(v + 0.1) / 0.86
					a = clampf((1.0 - k) / 0.1, 0.0, 1.0)
					shade = 1.0 if u > 0.0 else 0.62
					if absf(u) < 0.035:
						shade = 1.0
				&"leaf":
					# A pointed leaf along v with a midrib, lit on one half, a short stem at the bottom.
					var vv := (v + 0.05) / 0.85
					var half := 0.42 * sqrt(maxf(0.0, 1.0 - vv * vv)) * (1.0 - 0.25 * vv)
					var body := clampf((half - absf(u)) / 0.05, 0.0, 1.0) * (1.0 if absf(vv) <= 1.0 else 0.0)
					var stem := clampf((0.03 - absf(u)) / 0.02, 0.0, 1.0) * (1.0 if v >= 0.75 and v <= 0.98 else 0.0)
					a = maxf(body, stem)
					shade = 0.72 + 0.28 * (1.0 if u > 0.0 else 0.0) - 0.1 * vv
					if absf(u) < 0.025 and absf(vv) < 0.9:
						shade = 1.0
				&"clod":
					# A lumpy chunk of soil / rock: noisy outline, top-left lit, speckled.
					var ang := atan2(v, u)
					var edge := 0.62 + 0.18 * sin(ang * 3.0 + 1.3) + 0.1 * sin(ang * 5.0 + 0.4)
					a = clampf((edge - r) / 0.08, 0.0, 1.0)
					var nse2 := _vn(u * 6.0 + 3.1, v * 6.0 - 1.7)
					shade = clampf(0.62 + 0.3 * (-u - v) * 0.5 + (nse2 - 0.5) * 0.35, 0.3, 1.0)
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
	var soil_cols := _lin_all([Color(0.42, 0.34, 0.24), Color(0.35, 0.28, 0.19), Color(0.5, 0.42, 0.3)])
	var snowdust_cols := [_hdr(SNOW, 1.15), _hdr(RIME, 1.05), _hdr(Color(0.62, 0.58, 0.52), 1.0)]
	var fade_puff := _ramp_at([0.0, 0.12, 0.6, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.75), Color(1, 1, 1, 0.45),
			Color(1, 1, 1, 0.0)])
	var hold_solid := _ramp_at([0.0, 0.8, 1.0], [Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	match key:
		&"aura_frost":
			_shape_ring(m, 4.85, 0.12, 0.88)
			m.direction = Vector3.UP
			m.spread = 30.0
			m.initial_velocity_min = 0.1
			m.initial_velocity_max = 0.3
			m.radial_velocity_min = -0.35
			m.radial_velocity_max = -0.08
			m.damping_min = 0.2
			m.damping_max = 0.4
			m.gravity = Vector3(0, -0.02, 0)
			_spin(m, 20.0)
			# G-F r2 item 5: smaller, fainter, not HDR (the old 0.9-1.5 m puffs at 0.26 made a wide pale glass band).
			_size(m, 0.5, 0.85, &"grow")
			m.color_initial_ramp = _ramp([_hdr(RIME, 0.9), _hdr(SNOW, 0.9), _hdr(FROST, 0.9)])
			m.color_ramp = _ramp_at([0.0, 0.25, 0.7, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.12),
					Color(1, 1, 1, 0.07), Color(1, 1, 1, 0.0)])
		&"bolt_trail":
			_shape_sphere(m, 0.06)
			m.direction = Vector3(0, 0, 1)
			m.spread = 180.0
			m.initial_velocity_min = 0.2
			m.initial_velocity_max = 0.9
			m.damping_min = 1.0
			m.damping_max = 2.0
			m.gravity = Vector3(0, -2.0, 0)
			_spin(m, 200.0)
			_size(m, 0.1, 0.2, &"shrink")
			m.color_ramp = _ramp_at([0.0, 0.15, 0.6, 1.0], [_hdr(FROST_HOT, 3.2), _hdr(FROST_HOT, 3.0),
					_hdr(FROST, 2.0), _hdr(FROST_TEAM, 1.2, 0.0)])
		&"morph_dust":
			_shape_ring(m, 2.0, 0.12, 0.4)
			m.direction = Vector3.UP
			m.spread = 35.0
			m.initial_velocity_min = 0.6
			m.initial_velocity_max = 1.4
			m.radial_velocity_min = 0.2
			m.radial_velocity_max = 0.6
			m.damping_min = 0.8
			m.damping_max = 1.2
			m.gravity = Vector3(0, 0.2, 0)
			_spin(m, 30.0)
			_size(m, 1.0, 1.8, &"grow")
			m.color_initial_ramp = _ramp(soil_cols)
			m.color_ramp = _ramp_at([0.0, 0.15, 0.6, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.6),
					Color(1, 1, 1, 0.35), Color(1, 1, 1, 0.0)])
		&"morph_leaves":
			_shape_ring(m, 2.4, 0.5, 0.0)
			m.direction = Vector3.DOWN
			m.spread = 40.0
			m.initial_velocity_min = 0.3
			m.initial_velocity_max = 0.8
			m.damping_min = 0.6
			m.damping_max = 1.0
			m.gravity = Vector3(0, -1.2, 0)
			m.turbulence_enabled = true
			m.turbulence_noise_strength = 0.8
			m.turbulence_noise_scale = 2.0
			m.turbulence_influence_min = 0.1
			m.turbulence_influence_max = 0.25
			_spin(m, 220.0)
			_size(m, 0.22, 0.34, &"hold")
			m.color_initial_ramp = _ramp([_lin(LEAF), _lin(Color(0.45, 0.62, 0.2)), _lin(LEAF_DARK), _lin(PETAL),
					_lin(Color(0.55, 0.72, 0.25))])
			m.color_ramp = hold_solid
		&"knock_dust":
			_shape_sphere(m, 0.3)
			m.emission_shape_scale = Vector3(1.0, 0.3, 1.0)
			m.direction = Vector3.UP
			m.spread = 60.0
			m.initial_velocity_min = 0.4
			m.initial_velocity_max = 1.2
			m.damping_min = 1.5
			m.damping_max = 2.2
			m.gravity = Vector3(0, 0.3, 0)
			_spin(m, 40.0)
			_size(m, 0.6, 1.1, &"grow")
			m.color_initial_ramp = _ramp(_lin_all([DUST, Color(0.48, 0.4, 0.28), Color(0.62, 0.54, 0.42)]))
			m.color_ramp = fade_puff
		&"stomp_dust":
			_shape_ring(m, 0.7, 0.1, 0.7)
			m.direction = Vector3.UP
			m.spread = 60.0
			m.initial_velocity_min = 0.5
			m.initial_velocity_max = 1.3
			m.radial_velocity_min = 2.4
			m.radial_velocity_max = 3.8
			m.damping_min = 2.8
			m.damping_max = 3.4
			m.gravity = Vector3(0, 0.3, 0)
			_spin(m, 40.0)
			m.scale_min = 0.9
			m.scale_max = 1.6
			m.scale_curve = _curve([Vector2(0.0, 0.35), Vector2(0.35, 1.0), Vector2(1.0, 1.15)])
			m.color_initial_ramp = _ramp(snowdust_cols)
			m.color_ramp = fade_puff
		&"stomp_shards":
			_shape_sphere(m, 0.35)
			m.direction = Vector3.UP
			m.spread = 55.0
			m.initial_velocity_min = 3.5
			m.initial_velocity_max = 6.5
			m.gravity = Vector3(0, -14.0, 0)
			_spin(m, 400.0)
			_size(m, 0.18, 0.32, &"hold")
			m.color_initial_ramp = _ramp([_hdr(Color(0.8, 0.93, 1.0), 1.5), _hdr(FROST_HOT, 1.7), _hdr(FROST_TEAM, 1.3)])
			m.color_ramp = hold_solid
		&"stomp_glints", &"bolt_hit":
			var hit := key == &"bolt_hit"
			_shape_sphere(m, 0.15 if hit else 0.9)
			if not hit:
				m.emission_shape_scale = Vector3(1.0, 0.3, 1.0)
			m.direction = Vector3.UP
			m.spread = 180.0 if hit else 80.0
			m.initial_velocity_min = 2.5 if hit else 0.8
			m.initial_velocity_max = 5.5 if hit else 2.2
			m.damping_min = 3.0 if hit else 0.5
			m.damping_max = 5.0 if hit else 1.0
			m.gravity = Vector3(0, -4.0 if hit else -2.0, 0)
			_size(m, 0.14, 0.26, &"hold")
			m.color_ramp = _ramp_at([0.0, 0.1, 0.5, 1.0], [_hdr(FROST_HOT, 3.6, 0.0), _hdr(FROST_HOT, 3.6),
					_hdr(FROST, 2.6), _hdr(FROST, 1.4, 0.0)])
		&"bolt_shards":
			_shape_sphere(m, 0.1)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 3.0
			m.initial_velocity_max = 6.0
			m.gravity = Vector3(0, -12.0, 0)
			_spin(m, 500.0)
			_size(m, 0.1, 0.2, &"hold")
			m.color_initial_ramp = _ramp([_hdr(Color(0.8, 0.93, 1.0), 1.5), _hdr(FROST_HOT, 1.7), _hdr(FROST_TEAM, 1.3)])
			m.color_ramp = hold_solid
		&"bolt_mist":
			_shape_sphere(m, 0.3)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 0.3
			m.initial_velocity_max = 0.8
			m.damping_min = 1.0
			m.damping_max = 1.5
			_spin(m, 30.0)
			_size(m, 0.8, 1.3, &"grow")
			m.color_initial_ramp = _ramp([_hdr(RIME, 1.15), _hdr(SNOW, 1.2), _hdr(FROST, 1.1)])
			m.color_ramp = _ramp_at([0.0, 0.12, 0.6, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.55),
					Color(1, 1, 1, 0.3), Color(1, 1, 1, 0.0)])
		&"morph_burst":
			_shape_ring(m, 1.4, 0.12, 0.55)
			m.direction = Vector3.UP
			m.spread = 40.0
			m.initial_velocity_min = 1.2
			m.initial_velocity_max = 2.4
			m.radial_velocity_min = 1.2
			m.radial_velocity_max = 2.4
			m.damping_min = 1.6
			m.damping_max = 2.2
			m.gravity = Vector3(0, 0.25, 0)
			_spin(m, 35.0)
			m.scale_min = 1.4
			m.scale_max = 2.4
			m.scale_curve = _curve([Vector2(0.0, 0.35), Vector2(0.35, 1.0), Vector2(1.0, 1.15)])
			m.color_initial_ramp = _ramp(soil_cols)
			m.color_ramp = _ramp_at([0.0, 0.1, 0.6, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.7),
					Color(1, 1, 1, 0.4), Color(1, 1, 1, 0.0)])
		&"morph_clods", &"sprout_soil":
			var big := key == &"morph_clods"
			if big:
				_shape_ring(m, 1.4, 0.1, 0.4)
			else:
				_shape_sphere(m, 0.35)
			m.direction = Vector3.UP
			m.spread = 45.0 if big else 40.0
			m.initial_velocity_min = 3.5 if big else 2.0
			m.initial_velocity_max = 6.0 if big else 4.0
			m.radial_velocity_min = 1.0 if big else 0.3
			m.radial_velocity_max = 2.5 if big else 1.0
			m.gravity = Vector3(0, -14.0 if big else -12.0, 0)
			_spin(m, 300.0)
			_size(m, 0.16 if big else 0.1, 0.32 if big else 0.2, &"hold")
			m.color_initial_ramp = _ramp(_lin_all([Color(0.3, 0.22, 0.14), Color(0.22, 0.16, 0.1), Color(0.36, 0.3, 0.18),
					Color(0.24, 0.3, 0.12)]))
			m.color_ramp = hold_solid
		&"pulse_motes":
			_shape_ring(m, 1.2, 0.2, 0.75)
			m.direction = Vector3.UP
			m.spread = 30.0
			m.initial_velocity_min = 0.6
			m.initial_velocity_max = 1.4
			m.radial_velocity_min = 5.5
			m.radial_velocity_max = 7.0
			m.damping_min = 2.2
			m.damping_max = 2.6
			m.gravity = Vector3(0, 0.3, 0)
			_size(m, 0.12, 0.22, &"hold")
			m.color_ramp = _ramp_at([0.0, 0.1, 0.6, 1.0], [_hdr(LEAF_GLOW, 3.0, 0.0), _hdr(LEAF_GLOW, 3.0),
					_hdr(SAP, 2.2), _hdr(SAP, 1.2, 0.0)])
		&"thorn_launch":
			_shape_sphere(m, 0.3)
			m.direction = Vector3(0, 0, 1)
			m.spread = 60.0
			m.initial_velocity_min = 2.0
			m.initial_velocity_max = 4.0
			m.damping_min = 3.0
			m.damping_max = 4.0
			m.gravity = Vector3(0, -1.0, 0)
			_size(m, 0.1, 0.2, &"shrink")
			m.color_ramp = _ramp([_hdr(LEAF_GLOW, 3.2), _hdr(SAP, 2.2), _hdr(SAP, 1.0, 0.0)])
		&"thorn_hit":
			_shape_sphere(m, 0.1)
			m.direction = Vector3.UP
			m.spread = 80.0
			m.initial_velocity_min = 2.5
			m.initial_velocity_max = 5.0
			m.gravity = Vector3(0, -12.0, 0)
			_spin(m, 500.0)
			_size(m, 0.12, 0.22, &"hold")
			m.color_initial_ramp = _ramp(_lin_all([BARK, Color(0.3, 0.2, 0.1), LEAF_DARK, Color(0.5, 0.36, 0.2)]))
			m.color_ramp = hold_solid
		&"thorn_sap":
			_shape_sphere(m, 0.15)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 0.4
			m.initial_velocity_max = 1.2
			m.damping_min = 2.0
			m.damping_max = 3.0
			_size(m, 0.35, 0.6, &"grow")
			m.color_ramp = _ramp_at([0.0, 0.15, 0.6, 1.0], [_hdr(SAP, 1.4, 0.0), _hdr(SAP, 1.4, 0.6),
					_hdr(LEAF, 1.0, 0.3), _hdr(LEAF, 0.6, 0.0)])
		&"sprout_leaves":
			_shape_ring(m, 0.4, 0.1, 0.0)
			m.direction = Vector3.UP
			m.spread = 20.0
			m.initial_velocity_min = 1.2
			m.initial_velocity_max = 2.4
			m.radial_velocity_min = 0.3
			m.radial_velocity_max = 0.8
			m.tangential_accel_min = 3.0
			m.tangential_accel_max = 5.0
			m.damping_min = 1.0
			m.damping_max = 1.4
			m.gravity = Vector3(0, -0.6, 0)
			_spin(m, 260.0)
			_size(m, 0.18, 0.3, &"hold")
			m.color_initial_ramp = _ramp([_lin(LEAF), _lin(Color(0.5, 0.8, 0.3)), _lin(LEAF_DARK), _lin(PETAL)])
			m.color_ramp = hold_solid
		&"sprout_motes":
			_shape_ring(m, 0.9, 0.1, 0.6)
			m.direction = Vector3.UP
			m.spread = 15.0
			m.initial_velocity_min = 0.6
			m.initial_velocity_max = 1.4
			m.damping_min = 0.4
			m.damping_max = 0.8
			m.gravity = Vector3(0, 0.3, 0)
			_size(m, 0.1, 0.18, &"hold")
			m.color_ramp = _ramp_at([0.0, 0.15, 0.6, 1.0], [_hdr(LEAF_GLOW, 3.0, 0.0), _hdr(LEAF_GLOW, 3.0),
					_hdr(SAP, 2.0), _hdr(SAP, 1.0, 0.0)])
		&"knock_puff":
			_shape_sphere(m, 0.35)
			m.emission_shape_scale = Vector3(1.0, 0.3, 1.0)
			m.direction = Vector3.UP
			m.spread = 70.0
			m.initial_velocity_min = 0.8
			m.initial_velocity_max = 1.8
			m.damping_min = 2.0
			m.damping_max = 2.6
			m.gravity = Vector3(0, 0.3, 0)
			_spin(m, 40.0)
			_size(m, 0.7, 1.2, &"grow")
			m.color_initial_ramp = _ramp(_lin_all([DUST, Color(0.48, 0.4, 0.28), Color(0.62, 0.54, 0.42)]))
			m.color_ramp = fade_puff
	_pmats[key] = m
	return m


func _spin(m: ParticleProcessMaterial, deg_per_s: float) -> void:
	m.angle_min = -180.0
	m.angle_max = 180.0
	m.angular_velocity_min = -deg_per_s
	m.angular_velocity_max = deg_per_s


## A ring emission: radius r, height h, inner radius = r * inner.
func _shape_ring(m: ParticleProcessMaterial, r: float, h: float, inner: float) -> void:
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	m.emission_ring_axis = Vector3.UP
	m.emission_ring_radius = r
	m.emission_ring_inner_radius = r * inner
	m.emission_ring_height = h


func _shape_sphere(m: ParticleProcessMaterial, r: float) -> void:
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = r


func _shape_box(m: ParticleProcessMaterial, extents: Vector3) -> void:
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = extents


## Particle sizes in metres + a scale curve: shrink (sparks), grow (smoke, mist), hold (clods, shards, leaves).
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
