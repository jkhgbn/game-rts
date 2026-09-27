class_name MapFillVfx
extends Node3D
## Map-fill effects (task 12.V25, docs/design/map-fill.md section 10 row 12.V25, contract section 13). Add ONE of these to
## the skirmish level next to TradeVfx / ChampionVfx; it never edits gameplay code. Group "mapfill_vfx"; callers do
##   var vfx := get_tree().get_first_node_in_group(&"mapfill_vfx")
##   if vfx and vfx.has_method(&"play"): vfx.call(&"play", id, at, target)
## `at` is a world point (Vector3; a Node3D is accepted too and read once), `target` an optional Node3D (null ok).
## Ids (EFFECTS):
##   capture_done   a ring burst in the new owner's colour racing out to the capture radius, a claimed rim, sparks and
##                  motes. target = the CapturePoint (reads `owner_team`, `capture_radius`). (capture_point.gd)
##   shrine_awaken  a gold column shoots 24 m up from the shrine and fades (2.7 s), a gold wind ring round the 6 m circle,
##                  motes spiral up, a sky flare. Shown through the fog (both teams hear the horn). (capture_point.gd)
##   well_pulse     violet essence motes spiral out of the well mouth, a small ring in the owner's colour (every income
##                  tick: kept light; the well model does its own big violet ring). (capture_point.gd)
##   blessing       target = a unit: the Wayfarer's rune over its head for 60 s (or until its `blessing:wayshrine`
##                  modifier goes) + a gold pop. No unit: a gold pop at `at`. Runes also come by themselves (below).
##   camp_respawn   dust ring + swirling leaves where a camp's creatures came back. target = the NeutralCamp.
##   camp_cleared   a ring in the clearing team's colour, essence motes rising, leaves settling. target = the camp.
##   wade           ripple rings on the water at `at` (ford film or deep water for swimmers), sized by the target's
##                  `radius`. Waders are also found by themselves (below). Pool of 16 rings (one MultiMesh).
##   spore_burst    a blue-grey spore cloud filling r 3 at the impact, glowing spores drifting, a spore-dust stain and a
##                  pale shock ring. (creature_abilities.gd, at = impact, target = the victim or null)
##   antler_sweep   a pale green wind ring r 3 round the Hollow Stag, glowing leaves and streaks flung outward, a flare
##                  at antler height. (creature_abilities.gd, at = the stag, target = the stag)
## Any other id is forwarded to the beast effects (task 12.V31): `beast_vfx_path` (res://art/vfx/mapfill_beast_vfx.gd)
## is loaded at _ready when it exists; a Node is added as a child "BeastVfx", anything with `play(id, at, target)` gets
## every id that is not in EFFECTS (optional `setup(host)` is called first). No beast file = unknown ids do nothing.
## Frost Wyrm ids (task 13c.V9: wyrm_breath, wyrm_dive, wyrm_tail, wyrm_blizzard, wyrm_warning) go first to
## `wyrm_vfx_path` (res://art/vfx/mapfill_wyrm_vfx.gd), loaded the same way as a child "WyrmVfx": an id it `handles()`
## is played there, any other unknown id still goes to the beast effects.
## By itself (`auto_hooks`, rescanned every second, no gameplay code changes needed):
##   - CapturePoints (group "capture_points_service") `blessing_started(team, s)` / `blessing_ended(team)`: while a team
##     is blessed, each of its units with the modifier `blessing:wayshrine` shows the rune (<= 80, nearest to the camera
##     first; fog: only units that are visible);
##   - CampManager (group "camp_manager") `camp_cleared(camp, team, reward)` -> camp_cleared in that team's colour;
##     every NeutralCamp (group "neutral_camps") `respawned(camp)` -> camp_respawn;
##   - `auto_wade`: 5 times per second (one pass over "units" spread over 12 frames, a byte lookup per unit in a
##     wet-ford grid built once), units standing in a ford / Crown Steps circle over the channel (RiverSystem, group
##     "river") and amphibious units in deep water get ripples (3 alive per moving wader, 1 per 1.2 s idle; <= 6
##     waders, nearest to the camera, only visible units within 70 m of the camera).
##   The same id at the same spot within 0.3 s plays once, so a later direct call from gameplay code never doubles.
## Fog: effects of the local team always show; others only where the local team sees (`FogOfWar.is_visible`), checked 4
## times per second; shrine_awaken always shows.
## Budget: everything is built at _ready and pooled (ground discs, glows, columns, one-shot bursts restarted, 2
## MultiMeshes). One material per shader, looks set with instance uniforms: no node, material or mesh is created after
## _ready. No lights, no shadows. Shaders reused read-only from ChampionVfx (champion_ground, champion_flare) and
## CombatVfx (combat_streak); own: mapfill_column, mapfill_rune; the wade ring material comes from 12.V1
## (art/environment/water/wade_ripple_mat.tres, a built-in ring if it is missing).

const GROUP := &"mapfill_vfx"
const EFFECTS: Array[StringName] = [&"capture_done", &"shrine_awaken", &"well_pulse", &"blessing", &"camp_respawn",
		&"camp_cleared", &"wade", &"spore_burst", &"antler_sweep"]
const BEAST_VFX_PATH := "res://art/vfx/mapfill_beast_vfx.gd"
const WYRM_VFX_PATH := "res://art/vfx/mapfill_wyrm_vfx.gd"
const RIPPLE_MAT_PATH := "res://art/environment/water/wade_ripple_mat.tres"

## Mirrors Unit.team_color (the capture point models and the minimap use the same colours).
const TEAM_COLORS := {0: Color(0.3, 1.0, 0.4), 1: Color(1.0, 0.3, 0.3)}
const GOLD := Color(1.0, 0.76, 0.3)
const GOLD_HOT := Color(1.0, 0.93, 0.66)
const BRASS := Color(0.7, 0.52, 0.22)
const ESSENCE := Color(0.72, 0.4, 1.0)          # violet essence (the wells, camp rewards)
const ESSENCE_HOT := Color(0.9, 0.75, 1.0)
const DUST := Color(0.5, 0.41, 0.28)
const SPORE := Color(0.5, 0.6, 0.66)            # Gloomcap blue-grey
const SPORE_GLOW := Color(0.55, 1.0, 0.9)
const STAG_GREEN := Color(0.62, 1.0, 0.48)      # Hollow Stag leaves / heart

const BLESSING_MODIFIER := &"blessing:wayshrine"
const BLESSING_TIME := 60.0
const SHRINE_RADIUS := 6.0
const COLUMN_HEIGHT := 24.0
const RUNE_MAX := 80
const RUNE_SIZE := 0.7
const RUNE_LIFT := 0.55              # metres over the unit's body_height
const RUNE_FADE := 0.3
const RIPPLE_MAX := 16
const RIPPLE_TIME := 1.2
const RIPPLE_MOVING := 0.4           # one ring every ... s for a moving wader (3 alive)
const RIPPLE_IDLE := 1.2
const WADERS_MAX := 6
const WADE_RANGE := 70.0
const WADE_SLICES := 12              # a pass over "units" takes 12 frames (5 passes / s at 60 fps)
const FILM_Y := 0.05                 # ripple height on a ford film (WaterMeshes.FILM_Y 0.02 + 0.03)
const WATER_SURFACE_Y := -0.32       # in deep water (RiverSystem.WATER_Y -0.35 + 0.03)
const GRID_CELL := 0.5               # wet-ford lookup grid over the map (-64..64 m)
const GRID_INV := 2.0
const GRID_N := 256
const GRID_HALF := 64.0
const WORLD_AABB := AABB(Vector3(-600.0, -60.0, -600.0), Vector3(1200.0, 120.0, 1200.0))
const HOOK_SCAN := 1.0
const BLESS_SCAN := 0.5
const DEDUPE_TIME := 0.3
const DEDUPE_DIST := 1.0

const END_FADE := 0.2
const CHECK_INTERVAL := 0.25
const FOG_RESCAN := 1.0

enum { A_POINT, A_TARGET, A_WORLD }
enum { VIS_POINT, VIS_TARGET, VIS_ALWAYS }
enum { G_SHOCK, G_WIND, G_HEAL, G_ROPE, G_GLOW, G_SOOT, G_WARD }   # champion_ground.gdshader patterns

## Mesh pools (pre-built): pool -> size.
const POOL_SIZES := {&"disc": 24, &"flare": 24, &"column": 4}
## One-shot bursts: look -> [amount, lifetime, draw pass, pool size, explosiveness]. Looks ending in _0 / _1 / _n are
## tinted in the player / enemy / neutral colour (built once each).
const BURSTS := {
	&"cap_sparks_0": [26, 0.7, &"streak", 2, 0.95],
	&"cap_sparks_1": [26, 0.7, &"streak", 2, 0.95],
	&"cap_sparks_n": [26, 0.7, &"streak", 2, 0.95],
	&"cap_motes_0": [20, 1.1, &"add_star", 3, 0.6],
	&"cap_motes_1": [20, 1.1, &"add_star", 3, 0.6],
	&"cap_motes_n": [20, 1.1, &"add_star", 3, 0.6],
	&"gold_spiral": [36, 2.2, &"add_star", 2, 0.35],
	&"gold_rise": [20, 1.2, &"streak", 2, 0.7],
	&"essence_motes": [14, 1.1, &"add_star", 4, 0.5],
	&"essence_dots": [10, 1.0, &"add_dot", 4, 0.6],
	&"dust_ring": [22, 1.4, &"mix_smoke", 4, 0.85],
	&"leaf_swirl": [22, 1.8, &"mix_leaf", 3, 0.8],
	&"leaf_fall": [16, 2.2, &"mix_leaf", 3, 0.45],
	&"spore_cloud": [24, 1.7, &"mix_smoke", 4, 0.9],
	&"spore_motes": [26, 1.8, &"add_dot", 3, 0.7],
	&"glow_leaves": [18, 1.1, &"add_leaf", 3, 0.9],
	&"sweep_streaks": [18, 0.45, &"streak", 3, 1.0],
	&"bless_pop": [8, 0.5, &"add_star", 6, 1.0],
}

const GROUND_SHADER := preload("res://art/vfx/champion_ground.gdshader")
const FLARE_SHADER := preload("res://art/vfx/champion_flare.gdshader")
const STREAK_SHADER := preload("res://art/vfx/combat_streak.gdshader")
const COLUMN_SHADER := preload("res://art/vfx/mapfill_column.gdshader")
const RUNE_SHADER := preload("res://art/vfx/mapfill_rune.gdshader")

## Forwards the ids that are not in EFFECTS to this script's node (12.V31). Set before the node enters the tree.
@export var beast_vfx_path: String = BEAST_VFX_PATH
## The Frost Wyrm effects (13c.V9): the ids this node's `handles(id)` accepts are forwarded to it before the beasts.
@export var wyrm_vfx_path: String = WYRM_VFX_PATH
## Listen to CapturePoints / CampManager / NeutralCamp signals and find waders by itself.
@export var auto_hooks: bool = true
@export var auto_wade: bool = true


## One running effect: pooled pieces + scheduled one-shot bursts.
class Fx:
	extends RefCounted
	var id: StringName
	var t := 0.0
	var dur := 1.0
	var target: Node3D
	var has_target := false
	var point := Vector3.ZERO
	var tpos := Vector3.ZERO
	var team := -1
	var dep := false
	var vis := 0
	var end_at := -1.0
	var shown := true
	var check_left := 0.0
	var pieces: Array[Piece] = []
	var bursts: Array[Dictionary] = []
	var bursts_left := 0


## One pooled mesh of an effect (same model as TradeVfx): on / off window, anchor + offset lerped from o0 while growing,
## scale s0 -> s1 over `grow`, fade in / out.
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
	var s0 := Vector3.ONE
	var s1 := Vector3.ONE
	var grow := 0.0
	var back := false
	var lf := -1.0
	var lr := -1.0


var _fx: Array[Fx] = []
var _free: Dictionary = {}
var _all: Dictionary = {}
var _bursts: Dictionary = {}
var _burst_next: Dictionary = {}
var _live_bursts: Array[Dictionary] = []
var _pmats: Dictionary = {}
var _passes: Dictionary = {}
var _fog: Node
var _fog_left := 0.0
var _layer := 0
var _now := 0.0
var _recent: Array[Dictionary] = []   # {id, pos, t}: dedupe
var _beast: Object = null
var _wyrm: Object = null

# Hooks.
var _hook_left := 0.0
var _hooked: Dictionary = {}          # instance id -> true
var _bless_until: Dictionary = {}     # team -> match-clock end (this node's clock)

# Wade ripples (MultiMesh pool).
var _rip_mmi: MultiMeshInstance3D
var _rip_mm: MultiMesh
var _rip_age := PackedFloat32Array()
var _rip_pos := PackedVector3Array()
var _rip_size := PackedFloat32Array()
var _rip_alive := 0
var _scan_list: Array = []            # the "units" snapshot of the running wade pass
var _scan_i := 0
var _scan_step := 1
var _scan_started := false
var _scan_frame := WADE_SLICES        # frames into the running pass (a new pass starts at WADE_SLICES)
var _scan_cands: Array = []           # [camera distance, unit, ripple y]
var _scan_cam := Vector3.ZERO
var _scan_cam_ok := false
var _waders: Array[Dictionary] = []   # {u, y, id}
var _wader_left: Dictionary = {}      # instance id -> seconds to the next ring (kept between scans)
var _river: Node
var _fords: Array[Vector3] = []       # x, z, r^2
var _lines: Array[PackedVector2Array] = []
var _half_width := 2.5
var _moat := Vector4.ZERO
var _river_cached: Node
var _wade_grid := PackedByteArray()

# Blessing runes (MultiMesh pool).
var _rune_mmi: MultiMeshInstance3D
var _rune_mm: MultiMesh
var _rune_u: Array = []               # slot -> unit (Node3D) or null
var _rune_uid := PackedInt64Array()   # slot -> the unit's instance id (0 = free slot)
var _rune_fade := PackedFloat32Array()
var _rune_age := PackedFloat32Array()
var _rune_lift := PackedFloat32Array()
var _rune_seed := PackedFloat32Array()
var _rune_out := PackedByteArray()    # 1 = fading out
var _rune_slots: Dictionary = {}      # instance id -> slot
var _rune_n := 0                      # used slots
var _rune_top := 0                    # highest used slot + 1 (= visible_instance_count)
var _explicit: Dictionary = {}        # instance id -> {u, until}
var _bless_left := 0.0
var _rune_buf := PackedFloat32Array()
var _rune_col := Color.WHITE


func _ready() -> void:
	add_to_group(GROUP)
	top_level = true
	global_transform = Transform3D.IDENTITY
	_build_shared()
	_build_ripples()
	_build_runes()
	_load_beast()
	_wyrm = _load_child(wyrm_vfx_path, "WyrmVfx")
	_hook_left = 0.0


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
	if auto_wade:
		_wade_step()
		_wade_tick(delta)
	_tick_ripples(delta)
	_bless_left -= delta
	if _bless_left <= 0.0:
		_bless_left = BLESS_SCAN
		_bless_scan()
	_tick_runes(delta)
	if not _recent.is_empty() and _now - float(_recent[0]["t"]) > DEDUPE_TIME:
		_trim_recent()


# ---------------------------------------------------------------- public API

## Plays effect `id` at the world point `at` (Vector3, or a Node3D read once), on the optional `target` (Node3D or null).
## See the header for what each id expects. Ids not in EFFECTS go to the beast effects (12.V31) when they exist.
func play(id: StringName, at: Variant, target: Variant = null) -> void:
	_play(id, at, target, -2)


## Number of running (pooled-piece) effects. Ripples and runes are counted by ripple_count() / rune_count().
func active_count() -> int:
	return _fx.size()


## Ids of the running effects.
func active_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for fx in _fx:
		out.append(fx.id)
	return out


## Pooled pieces on screen + bursts alive + ripples + runes (0 once everything has ended).
func live_count() -> int:
	var n := _live_bursts.size() + _rip_alive + _rune_n
	for pool: StringName in _all:
		for g: GeometryInstance3D in _all[pool]:
			if g.visible:
				n += 1
	return n


## Ripple rings alive (<= 16).
func ripple_count() -> int:
	return _rip_alive


## Blessing runes shown (incl. the ones fading out).
func rune_count() -> int:
	return _rune_n


## The units that carry a rune right now (not fading out).
func rune_units() -> Array:
	var out: Array = []
	for s in _rune_top:
		if _rune_uid[s] != 0 and _rune_out[s] == 0 and is_instance_valid(_rune_u[s]):
			out.append(_rune_u[s])
	return out


## Current waders found by the auto pass (units).
func waders() -> Array:
	var out: Array = []
	for w in _waders:
		if is_instance_valid(w["u"]):
			out.append(w["u"])
	return out


## The loaded beast effects object (12.V31), or null.
func beast_vfx() -> Object:
	return _beast if is_instance_valid(_beast) else null


## The loaded Frost Wyrm effects object (13c.V9), or null.
func wyrm_vfx() -> Object:
	return _wyrm if is_instance_valid(_wyrm) else null


# ---------------------------------------------------------------- dispatch

func _play(id: StringName, at: Variant, target: Variant, team_hint: int) -> void:
	if not is_node_ready() or not is_inside_tree():
		return
	if not EFFECTS.has(id):
		_forward(id, at, target)
		return
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
		return
	match id:
		&"wade":
			_wade_play(point, t)
			return
		&"blessing":
			_blessing_play(point, t)
			return
	if _is_duplicate(id, point):
		return
	var fx := Fx.new()
	fx.id = id
	fx.target = t
	fx.has_target = t != null
	fx.point = point
	fx.tpos = t.global_position if t else point
	fx.team = team_hint if team_hint > -2 else _team_of(t)
	match id:
		&"capture_done": _capture_done(fx)
		&"shrine_awaken": _shrine_awaken(fx)
		&"well_pulse": _well_pulse(fx)
		&"camp_respawn": _camp_respawn(fx)
		&"camp_cleared": _camp_cleared(fx)
		&"spore_burst": _spore_burst(fx)
		&"antler_sweep": _antler_sweep(fx)
	_start(fx)


func _forward(id: StringName, at: Variant, target: Variant) -> void:
	if _wyrm != null and is_instance_valid(_wyrm) and _wyrm.has_method(&"handles") \
			and bool(_wyrm.call(&"handles", id)):
		_wyrm.call(&"play", id, at, target)
		return
	if _beast == null or not is_instance_valid(_beast) or not _beast.has_method(&"play"):
		return   # no beast effects (yet): silent no-op
	_beast.call(&"play", id, at, target)


func _load_beast() -> void:
	if beast_vfx_path == "" or not ResourceLoader.exists(beast_vfx_path):
		return
	var s := load(beast_vfx_path) as Script
	if s == null or not s.can_instantiate():
		push_warning("MapFillVfx: %s cannot be instantiated, beast effects off" % beast_vfx_path)
		return
	var o: Variant = s.new()
	if not (o is Object) or not is_instance_valid(o):
		return
	var obj := o as Object
	if obj.has_method(&"setup"):
		obj.call(&"setup", self)
	if obj is Node:
		(obj as Node).name = "BeastVfx"
		add_child(obj as Node)
	_beast = obj


## Loads an effects script (guarded) and adds its instance as a child named `child_name` (13c.V9: the Wyrm effects).
func _load_child(path: String, child_name: String) -> Object:
	if path == "" or not ResourceLoader.exists(path):
		return null
	var s := load(path) as Script
	if s == null or not s.can_instantiate():
		push_warning("MapFillVfx: %s cannot be instantiated, its effects are off" % path)
		return null
	var o: Variant = s.new()
	if not (o is Object) or not is_instance_valid(o):
		return null
	var obj := o as Object
	if obj.has_method(&"setup"):
		obj.call(&"setup", self)
	if obj is Node:
		(obj as Node).name = child_name
		add_child(obj as Node)
	return obj


## The team an effect belongs to (fog): a capture point's owner, else the node's `team`, else -1.
func _team_of(t: Node3D) -> int:
	if t == null:
		return -1
	var o: Variant = t.get(&"owner_team")
	if o != null and (int(o) == 0 or int(o) == 1):
		return int(o)
	var team: Variant = t.get(&"team")
	return int(team) if team != null else -1


func _is_duplicate(id: StringName, pos: Vector3) -> bool:
	for r in _recent:
		if r["id"] == id and _now - float(r["t"]) <= DEDUPE_TIME and (r["pos"] as Vector3).distance_to(pos) <= DEDUPE_DIST:
			return true
	_recent.append({"id": id, "pos": pos, "t": _now})
	return false


func _trim_recent() -> void:
	while not _recent.is_empty() and _now - float(_recent[0]["t"]) > DEDUPE_TIME:
		_recent.remove_at(0)


# ---------------------------------------------------------------- the effects

func _capture_done(fx: Fx) -> void:
	var up := Vector3.UP
	var c := _team_color(fx.team)
	var big := 7.0
	if fx.has_target:
		var r: Variant = fx.target.get(&"capture_radius")
		if r != null:
			big = clampf(float(r), 3.0, 10.0)
	fx.dur = 1.5
	_disc(fx, A_POINT, G_SHOCK, _hdr(c, 2.1), 0.8, big, 0.6, 0.0, 0.85, 0.0, 0.35)
	_disc(fx, A_POINT, G_SHOCK, _hdr(c, 1.2), 0.5, big * 0.72, 0.6, 0.16, 1.0, 0.0, 0.35)
	_disc(fx, A_POINT, G_WARD, _hdr(c, 1.25), big * 1.06, big, 0.35, 0.1, 0.0, 0.12, 0.55)
	_disc(fx, A_POINT, G_GLOW, _hdr(c, 0.7), big * 0.6, big * 0.85, 0.5, 0.0, 0.0, 0.05, 0.6)
	var tk := _team_key(fx.team)
	_sched(fx, StringName("cap_sparks_" + tk), 0.0, A_POINT, up * 0.35, big / 6.0)
	_sched(fx, StringName("cap_motes_" + tk), 0.08, A_POINT, up * 0.2, big / 6.0)
	_flare(fx, A_POINT, up * 1.5, _hdr(c, 2.4), 2.4, 4.2, 0.3, 0.0, 0.6, 0.0, 0.3, 1.0, 4.0)
	_flare(fx, A_POINT, up * 0.6, _hdr(c.lerp(Color.WHITE, 0.35), 1.6), 2.0, 3.4, 0.2, 0.0, 0.35, 0.0, 0.2)


func _shrine_awaken(fx: Fx) -> void:
	var up := Vector3.UP
	fx.dur = 2.7
	fx.vis = VIS_ALWAYS
	var rise := 0.45
	var outer := _piece(fx, &"column", A_POINT, up * COLUMN_HEIGHT * 0.5, 0.0, 0.0, 0.0, 1.1)
	if outer:
		outer.o0 = up * 0.05
		_grow(outer, Vector3(1.5, 0.1, 1.5), Vector3(1.25, COLUMN_HEIGHT, 1.25), rise)
		_params(outer, {&"tint": _hdr(GOLD, 1.25), &"seed": randf() * 10.0, &"bands": 1.0, &"top_fade": 1.2})
	var core := _piece(fx, &"column", A_POINT, up * COLUMN_HEIGHT * 0.46, 0.0, 0.0, 0.0, 0.9)
	if core:
		core.o0 = up * 0.05
		_grow(core, Vector3(0.6, 0.1, 0.6), Vector3(0.42, COLUMN_HEIGHT * 0.92, 0.42), rise * 0.85)
		_params(core, {&"tint": _hdr(GOLD_HOT, 2.3), &"seed": randf() * 10.0, &"bands": 0.0, &"top_fade": 1.6})
	_disc(fx, A_POINT, G_SHOCK, _hdr(GOLD, 2.2), 1.0, SHRINE_RADIUS, 0.7, 0.0, 1.0, 0.0, 0.4)
	_disc(fx, A_POINT, G_WIND, _hdr(GOLD, 1.5), SHRINE_RADIUS, SHRINE_RADIUS, 0.0, 0.15, 0.0, 0.3, 0.9)
	_disc(fx, A_POINT, G_GLOW, _hdr(GOLD, 0.9), 2.2, 3.2, 0.6, 0.0, 0.0, 0.1, 1.0)
	_sched(fx, &"gold_spiral", 0.05, A_POINT, up * 0.3)
	_sched(fx, &"gold_rise", 0.1, A_POINT, up * 0.8)
	_flare(fx, A_POINT, up * 1.6, _hdr(GOLD, 2.6), 2.0, 4.0, 0.35, 0.0, 0.0, 0.0, 0.8, 1.2, 6.0)
	var sky := _flare(fx, A_POINT, up * COLUMN_HEIGHT * 0.9, _hdr(GOLD_HOT, 2.0), 3.0, 6.5, 0.6, 0.2, 0.0, 0.15, 1.0,
			0.8, 4.0)
	if sky:
		sky.o0 = up * 2.0


func _well_pulse(fx: Fx) -> void:
	var up := Vector3.UP
	fx.dur = 1.2
	var c := _team_color(fx.team)
	_sched(fx, &"essence_motes", 0.0, A_POINT, up * 0.9)
	_sched(fx, &"essence_dots", 0.05, A_POINT, up * 0.8)
	_disc(fx, A_POINT, G_SHOCK, _hdr(c, 1.1), 1.3, 2.5, 0.5, 0.0, 0.7, 0.0, 0.3)
	_flare(fx, A_POINT, up * 1.05, _hdr(ESSENCE, 2.0), 1.3, 2.3, 0.25, 0.0, 0.55, 0.0, 0.3, 0.6, 4.0)


func _camp_respawn(fx: Fx) -> void:
	var up := Vector3.UP
	fx.dur = 1.6
	_disc(fx, A_POINT, G_SOOT, DUST.srgb_to_linear(), 1.2, 3.4, 0.6, 0.0, 1.6, 0.05, 0.8)
	_sched(fx, &"dust_ring", 0.0, A_POINT, up * 0.3)
	_sched(fx, &"dust_ring", 0.12, A_POINT, up * 0.2, 0.6)
	_sched(fx, &"leaf_swirl", 0.05, A_POINT, up * 0.2)


func _camp_cleared(fx: Fx) -> void:
	var up := Vector3.UP
	fx.dur = 1.8
	var c := _team_color(fx.team)
	_disc(fx, A_POINT, G_SHOCK, _hdr(c, 1.2), 1.0, 4.6, 0.6, 0.0, 0.9, 0.0, 0.35)
	_disc(fx, A_POINT, G_WARD, _hdr(c, 0.8), 4.6, 4.2, 0.4, 0.15, 0.0, 0.1, 0.6)
	_sched(fx, &"essence_motes", 0.05, A_POINT, up * 0.5, 1.6)
	_sched(fx, StringName("cap_motes_" + _team_key(fx.team)), 0.0, A_POINT, up * 0.2, 0.7)
	_sched(fx, &"leaf_fall", 0.1, A_POINT, up * 2.6)
	_flare(fx, A_POINT, up * 1.2, _hdr(GOLD, 2.2), 1.8, 3.2, 0.3, 0.0, 0.6, 0.0, 0.3, 0.9, 4.0)


func _spore_burst(fx: Fx) -> void:
	var up := Vector3.UP
	fx.dur = 1.8
	# A pale spore-dust stain (not a dark hole), a quick pale ring, a dense cloud that lingers, glowing spores.
	_disc(fx, A_POINT, G_SOOT, Color(0.34, 0.42, 0.44), 0.8, 3.0, 0.4, 0.0, 1.8, 0.05, 0.9)
	_disc(fx, A_POINT, G_SHOCK, _hdr(SPORE_GLOW, 1.1), 0.4, 3.2, 0.35, 0.0, 0.5, 0.0, 0.25)
	_sched(fx, &"spore_cloud", 0.0, A_POINT, up * 0.8)
	_sched(fx, &"spore_cloud", 0.1, A_POINT, up * 0.5, 0.75)
	_sched(fx, &"spore_motes", 0.05, A_POINT, up * 0.5)
	_flare(fx, A_POINT, up * 0.7, _hdr(SPORE_GLOW, 1.2), 1.4, 2.6, 0.25, 0.0, 0.4, 0.0, 0.25)


func _antler_sweep(fx: Fx) -> void:
	var up := Vector3.UP
	fx.dur = 1.1
	var h := _h(fx.target) if fx.has_target else 2.8
	# Kept below the bloom blow-out so the stag stays readable inside its own ring.
	_disc(fx, A_POINT, G_WIND, _hdr(STAG_GREEN, 0.75), 3.2, 3.2, 0.0, 0.0, 0.9, 0.05, 0.35)
	_disc(fx, A_POINT, G_SHOCK, _hdr(STAG_GREEN.lerp(Color.WHITE, 0.25), 1.2), 0.8, 3.4, 0.3, 0.0, 0.45, 0.0, 0.2)
	_sched(fx, &"sweep_streaks", 0.0, A_POINT, up * 0.6)
	_sched(fx, &"glow_leaves", 0.0, A_POINT, up * clampf(h * 0.8, 1.2, 3.2))
	_flare(fx, A_POINT, up * clampf(h * 0.9, 1.4, 3.6), _hdr(STAG_GREEN, 1.4), 1.0, 1.8, 0.2, 0.0, 0.35, 0.0, 0.25, 0.8,
			6.0)


# ---------------------------------------------------------------- blessing runes

func _blessing_play(point: Vector3, t: Node3D) -> void:
	if t != null and _alive(t):
		_explicit[t.get_instance_id()] = {"u": t, "until": _now + BLESSING_TIME, "from": _now}
		_rune_add(t)
		if t.is_visible_in_tree():
			_burst(&"bless_pop", t.global_position + Vector3.UP * (_h(t) + RUNE_LIFT))
		return
	if _fog_ok(-1, point):
		_burst(&"bless_pop", point + Vector3.UP * 1.2, 1.6)


## Rebuilds the set of rune carriers (2 Hz): blessed teams' units with the modifier + explicit ones.
func _bless_scan() -> void:
	var want: Dictionary = {}
	for team: int in _bless_until.keys():
		if _now > float(_bless_until[team]):
			_bless_until.erase(team)
	if not _bless_until.is_empty():
		for n in get_tree().get_nodes_in_group(&"units"):
			var u := n as Node3D
			if u == null or not _bless_until.has(_team_of(u)):
				continue
			if not u.has_method(&"has_modifier") or not bool(u.call(&"has_modifier", BLESSING_MODIFIER)):
				continue
			if _alive(u):
				want[u.get_instance_id()] = u
	for id: int in _explicit.keys():
		var e: Dictionary = _explicit[id]
		var u: Variant = e["u"]
		var gone: bool = not _alive(u) or _now > float(e["until"])
		if not gone and (u as Object).has_method(&"has_modifier") and _now - float(e["from"]) > 0.5 \
				and not bool((u as Object).call(&"has_modifier", BLESSING_MODIFIER)) \
				and not _bless_until.has(_team_of(u as Node3D)):
			gone = true
		if gone:
			_explicit.erase(id)
		else:
			want[id] = u
	# Cap: nearest to the camera first.
	if want.size() > RUNE_MAX:
		var cam := _camera_pos()
		var arr: Array = want.values()
		arr.sort_custom(func(a: Node3D, b: Node3D) -> bool:
			return a.global_position.distance_squared_to(cam) < b.global_position.distance_squared_to(cam))
		want.clear()
		for i in RUNE_MAX:
			want[(arr[i] as Node3D).get_instance_id()] = arr[i]
	for s in _rune_top:
		if _rune_uid[s] != 0:
			_rune_out[s] = 0 if want.has(_rune_uid[s]) else 1
	for id: int in want:
		if not _rune_slots.has(id):
			_rune_add(want[id])


## Gives `u` a rune slot (fixed slot per rune: the constant parts of its MultiMesh entry are written once here).
func _rune_add(u: Node3D) -> void:
	var id := u.get_instance_id()
	if _rune_slots.has(id):
		_rune_out[int(_rune_slots[id])] = 0
		return
	if _rune_n >= RUNE_MAX:
		return
	var s := 0
	while _rune_uid[s] != 0:
		s += 1
	_rune_u[s] = u
	_rune_uid[s] = id
	_rune_fade[s] = 0.0
	_rune_age[s] = 0.0
	_rune_lift[s] = _h(u) + RUNE_LIFT
	_rune_seed[s] = randf()
	_rune_out[s] = 0
	_rune_slots[id] = s
	_rune_n += 1
	_rune_top = maxi(_rune_top, s + 1)
	var o := s * 20
	_rune_buf[o] = RUNE_SIZE
	_rune_buf[o + 5] = RUNE_SIZE
	_rune_buf[o + 10] = RUNE_SIZE
	_rune_buf[o + 12] = _rune_col.r
	_rune_buf[o + 13] = _rune_col.g
	_rune_buf[o + 14] = _rune_col.b
	_rune_buf[o + 15] = 0.0
	_rune_buf[o + 17] = _rune_seed[s]


func _rune_free(s: int) -> void:
	_rune_slots.erase(_rune_uid[s])
	_rune_u[s] = null
	_rune_uid[s] = 0
	_rune_n -= 1


## Moves / fades the runes: one MultiMesh buffer upload per frame; per rune only its position, fade and age change.
## A freed / removed unit's rune fades out; a hidden unit (fog) has none.
func _tick_runes(delta: float) -> void:
	if _rune_top == 0:
		return
	var step := delta / RUNE_FADE
	var buf := _rune_buf
	var fade := _rune_fade
	var ages := _rune_age
	var uid := _rune_uid
	var outs := _rune_out
	var lift := _rune_lift
	var seeds := _rune_seed
	var nodes := _rune_u
	var top := 0
	for s in _rune_top:
		if uid[s] == 0:
			continue
		var u: Variant = nodes[s]
		var ok := is_instance_valid(u)
		var out := outs[s] != 0 or not ok
		var f := fade[s]
		if out:
			f = maxf(f - step, 0.0)
		elif f < 1.0:
			f = minf(f + step, 1.0)
		fade[s] = f
		var age := ages[s] + delta
		ages[s] = age
		var o := s * 20
		if out and f <= 0.0:
			_rune_free(s)
			buf[o + 15] = 0.0
			continue
		top = s + 1
		# is_visible_in_tree() is false outside the tree too (and for fog-hidden units).
		if not ok or not (u as Node3D).is_visible_in_tree():
			buf[o + 15] = 0.0
			continue
		var p: Vector3 = (u as Node3D).global_position
		buf[o + 3] = p.x
		buf[o + 7] = p.y + lift[s] + sin(age * 2.2 + seeds[s] * TAU) * 0.06
		buf[o + 11] = p.z
		buf[o + 15] = f
		if age < 2.0:
			buf[o + 16] = age
	_rune_buf = buf
	_rune_fade = fade
	_rune_age = ages
	_rune_top = top
	_rune_mm.buffer = buf
	_rune_mm.visible_instance_count = top


func _on_blessing_started(team: int, seconds: float) -> void:
	_bless_until[team] = _now + maxf(seconds, 1.0) + 0.5
	_bless_left = 0.0   # rescan next frame


func _on_blessing_ended(team: int) -> void:
	_bless_until.erase(team)
	_bless_left = 0.0


# ---------------------------------------------------------------- wade ripples

func _wade_play(point: Vector3, t: Node3D) -> void:
	if t != null:
		if not t.is_visible_in_tree():
			return
	elif not _fog_ok(-1, point):
		return
	_spawn_ripple(point, _water_y(point), _ripple_scale(t))


## Finds the waders, spread over frames (WADE_SLICES frames per pass over "units", no spike): units in a ford / steps
## circle over the channel (one byte lookup in the wet-ford grid each), then amphibious units in deep water.
func _wade_step() -> void:
	if _scan_frame >= WADE_SLICES:
		if _scan_started:
			_wade_finish()
		var river := _get_river()
		_scan_started = river != null
		_scan_i = 0
		_scan_frame = 0
		_scan_cands.clear()
		if river == null:
			_scan_list = []
			_waders.clear()
			return
		_scan_list = get_tree().get_nodes_in_group(&"units") if not _fords.is_empty() else []
		_scan_step = maxi(1, ceili(float(_scan_list.size()) / float(WADE_SLICES)))
		_scan_cam_ok = _has_camera()
		_scan_cam = _camera_pos()
	_scan_frame += 1
	var grid := _wade_grid
	var end := mini(_scan_i + _scan_step, _scan_list.size())
	for k in range(_scan_i, end):
		var o: Variant = _scan_list[k]
		if not is_instance_valid(o):
			continue   # freed since the snapshot
		var u := o as Node3D
		if u == null:
			continue
		var gp := u.global_position
		var ci := int((gp.x + GRID_HALF) * GRID_INV)
		var cj := int((gp.z + GRID_HALF) * GRID_INV)
		if ci < 0 or cj < 0 or ci >= GRID_N or cj >= GRID_N or grid[cj * GRID_N + ci] == 0:
			continue
		_add_cand(_scan_cands, u, FILM_Y, _scan_cam_ok, _scan_cam)
	_scan_i = end


## End of a pass: adds the swimmers, keeps the WADERS_MAX nearest to the camera.
func _wade_finish() -> void:
	var cands := _scan_cands
	for i in range(cands.size() - 1, -1, -1):
		if not is_instance_valid((cands[i] as Array)[1]):
			cands.remove_at(i)   # freed during the pass
	var river := _get_river()
	if river != null and river.has_method(&"is_water"):
		for n in get_tree().get_nodes_in_group(&"amphibious"):
			var u := n as Node3D
			if u != null and bool(river.call(&"is_water", u.global_position)):
				_add_cand(cands, u, WATER_SURFACE_Y, _scan_cam_ok, _scan_cam)
	if cands.size() > WADERS_MAX:
		cands.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
		cands.resize(WADERS_MAX)
	var keep: Dictionary = {}
	_waders.clear()
	for c: Array in cands:
		var u: Node3D = c[1]
		var id := u.get_instance_id()
		keep[id] = true
		if not _wader_left.has(id):
			_wader_left[id] = 0.0   # a fresh wader rings at once
		_waders.append({"u": u, "y": float(c[2]), "id": id})
	for id: int in _wader_left.keys():
		if not keep.has(id):
			_wader_left.erase(id)
	_scan_cands = []


func _add_cand(cands: Array, u: Node3D, y: float, has_cam: bool, cam: Vector3) -> void:
	if not _alive(u) or not u.is_visible_in_tree():
		return
	var d := u.global_position.distance_to(cam) if has_cam else 0.0
	if has_cam and d > WADE_RANGE:
		return
	for c: Array in cands:
		if c[1] == u:
			return
	cands.append([d, u, y])


func _wade_tick(delta: float) -> void:
	for w in _waders:
		var u: Variant = w["u"]
		if not _in_tree(u):
			continue
		var id := int(w["id"])
		var left := float(_wader_left.get(id, 0.0)) - delta
		if left <= 0.0:
			var n3 := u as Node3D
			var v: Variant = n3.get(&"velocity")
			var moving := v is Vector3 and Vector2((v as Vector3).x, (v as Vector3).z).length() > 0.3
			left = RIPPLE_MOVING if moving else RIPPLE_IDLE
			_spawn_ripple(n3.global_position, float(w["y"]), _ripple_scale(n3))
		_wader_left[id] = left


func _spawn_ripple(pos: Vector3, y: float, size: float) -> void:
	for i in RIPPLE_MAX:
		if _rip_age[i] < 0.0:
			_rip_age[i] = 0.0
			_rip_pos[i] = Vector3(pos.x, y, pos.z)
			_rip_size[i] = size
			_rip_alive += 1
			_ripple_write(i)
			return
	# Pool full: this ring is skipped.


func _tick_ripples(delta: float) -> void:
	if _rip_alive == 0:
		return
	for i in RIPPLE_MAX:
		var a := _rip_age[i]
		if a < 0.0:
			continue
		a += delta
		if a >= RIPPLE_TIME:
			_rip_age[i] = -1.0
			_rip_alive -= 1
			_rip_mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3(0, -50, 0)))
			continue
		_rip_age[i] = a
		_ripple_write(i)


func _ripple_write(i: int) -> void:
	var k := clampf(_rip_age[i] / RIPPLE_TIME, 0.0, 1.0)
	var e := 1.0 - pow(1.0 - k, 2.2)
	var s := _rip_size[i] * lerpf(0.5, 1.9, e)
	var alpha := clampf(_rip_age[i] / 0.08, 0.0, 1.0) * pow(1.0 - k, 1.3)
	# Tiny height steps so overlapping rings never z-fight.
	var p := _rip_pos[i] + Vector3.UP * (0.002 * float(i % 4))
	_rip_mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(s, 1.0, s)), p))
	_rip_mm.set_instance_color(i, Color(1.0, 1.0, 1.0, alpha))


func _ripple_scale(t: Node3D) -> float:
	return clampf(_r(t) / 0.45, 0.8, 2.6) * 1.15 if t != null else 1.15


func _water_y(p: Vector3) -> float:
	var river := _get_river()
	if river and river.has_method(&"is_water") and bool(river.call(&"is_water", p)):
		return WATER_SURFACE_Y
	return FILM_Y if p.y < 0.3 else p.y + 0.05


func _get_river() -> Node:
	if not is_instance_valid(_river):
		_river = get_tree().get_first_node_in_group(&"river")
	if _river != _river_cached:
		_cache_river(_river)
	return _river


func _cache_river(river: Node) -> void:
	_river_cached = river
	_fords.clear()
	_lines.clear()
	_moat = Vector4.ZERO
	if river == null:
		return
	if river.has_method(&"crossings"):
		for c: Variant in river.call(&"crossings"):
			if not (c is Dictionary):
				continue
			var d := c as Dictionary
			var kind := StringName(str(d.get("kind", "")))
			if kind != &"ford" and kind != &"steps":
				continue
			var ctr: Variant = d.get("center", Vector3.ZERO)
			var r := float(d.get("radius", float(d.get("width", 6.0)) * 0.5))
			if ctr is Vector3:
				_fords.append(Vector3((ctr as Vector3).x, (ctr as Vector3).z, r * r))
	if river.has_method(&"polylines"):
		for l: Variant in river.call(&"polylines"):
			if l is PackedVector2Array:
				_lines.append(l)
	if river.has_method(&"half_width"):
		_half_width = float(river.call(&"half_width"))
	if river.has_method(&"moat"):
		_moat = river.call(&"moat")
	_build_wade_grid()


## Marks the 0.5 m cells whose centre is inside a ford / steps circle AND over the channel or the moat band (the part
## of the circle that has water on it; its banks stay dry). Built once per river, only over the circles.
func _build_wade_grid() -> void:
	_wade_grid.resize(GRID_N * GRID_N)
	_wade_grid.fill(0)
	for f in _fords:
		var c := Vector2(f.x, f.y)
		var r := sqrt(f.z)
		var segs: Array[Vector4] = []
		for line in _lines:
			for k in line.size() - 1:
				if Geometry2D.get_closest_point_to_segment(c, line[k], line[k + 1]).distance_to(c) < r + _half_width:
					segs.append(Vector4(line[k].x, line[k].y, line[k + 1].x, line[k + 1].y))
		var i0 := clampi(int((c.x - r + GRID_HALF) * GRID_INV), 0, GRID_N - 1)
		var i1 := clampi(int((c.x + r + GRID_HALF) * GRID_INV), 0, GRID_N - 1)
		var j0 := clampi(int((c.y - r + GRID_HALF) * GRID_INV), 0, GRID_N - 1)
		var j1 := clampi(int((c.y + r + GRID_HALF) * GRID_INV), 0, GRID_N - 1)
		for j in range(j0, j1 + 1):
			for i in range(i0, i1 + 1):
				var p := Vector2(-GRID_HALF + (float(i) + 0.5) * GRID_CELL, -GRID_HALF + (float(j) + 0.5) * GRID_CELL)
				if p.distance_squared_to(c) >= f.z:
					continue
				var wet := _moat.z > 0.0 and absf(p.distance_to(Vector2(_moat.x, _moat.y)) - _moat.z) < _moat.w
				if not wet:
					for s in segs:
						var q := Geometry2D.get_closest_point_to_segment(p, Vector2(s.x, s.y), Vector2(s.z, s.w))
						if p.distance_to(q) < _half_width:
							wet = true
							break
				if wet:
					_wade_grid[j * GRID_N + i] = 1


# ---------------------------------------------------------------- hooks

func _scan_hooks() -> void:
	var tree := get_tree()
	var cps := tree.get_first_node_in_group(&"capture_points_service")
	if cps != null and not _hooked.has(cps.get_instance_id()):
		if cps.has_signal(&"blessing_started") and cps.has_signal(&"blessing_ended"):
			cps.connect(&"blessing_started", _on_blessing_started)
			cps.connect(&"blessing_ended", _on_blessing_ended)
			_hooked[cps.get_instance_id()] = true
			if cps.has_method(&"blessing_time_left"):
				for team in [0, 1]:
					var left := float(cps.call(&"blessing_time_left", team))
					if left > 0.0:
						_on_blessing_started(team, left)
	var cm := tree.get_first_node_in_group(&"camp_manager")
	if cm != null and not _hooked.has(cm.get_instance_id()) and cm.has_signal(&"camp_cleared"):
		cm.connect(&"camp_cleared", _on_camp_cleared)
		_hooked[cm.get_instance_id()] = true
	for camp in tree.get_nodes_in_group(&"neutral_camps"):
		if not _hooked.has(camp.get_instance_id()) and camp.has_signal(&"respawned"):
			camp.connect(&"respawned", _on_camp_respawned)
			_hooked[camp.get_instance_id()] = true
	for id: int in _hooked.keys():
		if not is_instance_id_valid(id):
			_hooked.erase(id)


func _on_camp_cleared(camp: Node3D, team: int, _reward: Dictionary) -> void:
	if is_instance_valid(camp) and camp.is_inside_tree():
		_play(&"camp_cleared", camp.global_position, camp, team if team == 0 or team == 1 else -1)


func _on_camp_respawned(camp: Node3D) -> void:
	if is_instance_valid(camp) and camp.is_inside_tree():
		_play(&"camp_respawn", camp.global_position, camp, -1)


# ---------------------------------------------------------------- effect runtime (TradeVfx model)

func _start(fx: Fx) -> void:
	_fx.append(fx)
	_refresh(fx)
	fx.check_left = CHECK_INTERVAL
	_tick(fx, 0.0)


func _tick(fx: Fx, delta: float) -> bool:
	fx.t += delta
	if fx.has_target and _in_tree(fx.target):
		fx.tpos = fx.target.global_position
	fx.check_left -= delta
	if fx.check_left <= 0.0:
		fx.check_left += CHECK_INTERVAL
		if fx.end_at < 0.0 and fx.dep and not _alive(fx.target):
			fx.end_at = fx.t + END_FADE
		_refresh(fx)
	var ef := 1.0 if fx.end_at < 0.0 else clampf((fx.end_at - fx.t) / END_FADE, 0.0, 1.0)
	for d in fx.pieces:
		_tick_piece(fx, d, ef)
	if fx.bursts_left > 0:
		for b in fx.bursts:
			if not b["done"] and fx.t >= float(b["on"]):
				b["done"] = true
				fx.bursts_left -= 1
				if fx.shown and fx.end_at < 0.0:
					_burst(b["look"], _anchor(fx, b["at"]) + (b["ofs"] as Vector3), b["size"])
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
	var f := ef
	if d.fin > 0.0:
		f = minf(f, lt / d.fin)
	if d.fout > 0.0:
		f = minf(f, (off - fx.t) / d.fout)
	f = clampf(f, 0.0, 1.0)
	var k := 1.0
	if d.grow > 0.0:
		k = _ease(clampf(lt / d.grow, 0.0, 1.0), d.back)
	var s := d.s0.lerp(d.s1, k)
	var pos := _anchor(fx, d.at) + d.o0.lerp(d.ofs, k)
	var xf := Transform3D(Basis.from_scale(s), pos)
	if not xf.is_equal_approx(n.transform):
		n.transform = xf
	if absf(f - d.lf) > 0.003:
		d.lf = f
		n.set_instance_shader_parameter(&"fade", f)
	if lt <= 1.05:
		n.set_instance_shader_parameter(&"age", lt)
	if d.is_disc and absf(s.x - d.lr) > 0.001:
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


func _refresh(fx: Fx) -> void:
	match fx.vis:
		VIS_ALWAYS:
			fx.shown = true
		VIS_TARGET:
			fx.shown = fx.has_target and _in_tree(fx.target) and fx.target.is_visible_in_tree()
		_:
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


# ---------------------------------------------------------------- piece helpers

func _piece(fx: Fx, pool: StringName, at: int, ofs: Vector3, on: float, off: float, fin: float,
		fout: float) -> Piece:
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


## Ground mark (champion_ground.gdshader) growing from radius r0 to r1.
func _disc(fx: Fx, at: int, pattern: int, tint: Color, r0: float, r1: float, grow: float, on: float, off: float,
		fin: float, fout: float) -> Piece:
	_layer = (_layer + 1) % 8
	var d := _piece(fx, &"disc", at, Vector3.UP * (0.06 + 0.006 * float(_layer)), on, off, fin, fout)
	_grow(d, Vector3(r0, 1.0, r0), Vector3(r1, 1.0, r1), grow, false)
	_params(d, {&"pattern": float(pattern), &"tint": tint, &"seed": randf() * 10.0})
	return d


## Camera-facing glow (champion_flare.gdshader) growing from size s0 to s1 metres.
func _flare(fx: Fx, at: int, ofs: Vector3, tint: Color, s0: float, s1: float, grow: float, on: float, off: float,
		fin: float, fout: float, rays: float = 0.0, spikes: float = 4.0) -> Piece:
	var d := _piece(fx, &"flare", at, ofs, on, off, fin, fout)
	_grow(d, s0, s1, grow, false)
	_params(d, {&"tint": tint, &"rays": rays, &"spikes": spikes, &"pulse": 0.0, &"seed": randf() * 10.0,
			&"halo": Color(0, 0, 0, 0)})
	return d


func _sched(fx: Fx, look: StringName, on: float, at: int, ofs: Vector3, size: float = 1.0) -> void:
	if not _bursts.has(look):
		return
	fx.bursts.append({"look": look, "on": on, "at": at, "ofs": ofs, "size": size, "done": false})
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


# ---------------------------------------------------------------- small helpers

func _in_tree(n: Variant) -> bool:
	return is_instance_valid(n) and (n as Node).is_inside_tree()


func _alive(n: Variant) -> bool:
	if not is_instance_valid(n) or not (n as Node).is_inside_tree():
		return false
	if (n as Object).has_method(&"is_alive"):
		return bool((n as Object).call(&"is_alive"))
	return true


func _h(n: Variant) -> float:
	if not is_instance_valid(n):
		return 1.6
	var h: Variant = (n as Object).get(&"body_height")
	return float(h) if h != null else 1.6


func _r(n: Variant) -> float:
	if not is_instance_valid(n):
		return 0.45
	var r: Variant = (n as Object).get(&"radius")
	return float(r) if r != null else 0.45


func _team_color(team: int) -> Color:
	return TEAM_COLORS[team] if TEAM_COLORS.has(team) else GOLD


func _team_key(team: int) -> String:
	return "0" if team == 0 else ("1" if team == 1 else "n")


func _has_camera() -> bool:
	return get_viewport() != null and get_viewport().get_camera_3d() != null


func _camera_pos() -> Vector3:
	var vp := get_viewport()
	if vp == null:
		return Vector3.ZERO
	var cam := vp.get_camera_3d()
	if cam == null:
		return Vector3.ZERO
	# The RTS camera looks down at its focus: measure from the ground point it looks at, not from the lens.
	var o := cam.global_position
	var fwd := -cam.global_transform.basis.z
	if fwd.y < -0.1:
		return o + fwd * (o.y / -fwd.y)
	return o


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
	var column := CylinderMesh.new()
	column.top_radius = 1.0
	column.bottom_radius = 1.0
	column.height = 1.0
	column.radial_segments = 20
	column.rings = 4
	column.cap_top = false
	column.cap_bottom = false
	var meshes := {&"disc": plane, &"flare": quad, &"column": column}
	var mats := {&"disc": _shader_mat(GROUND_SHADER), &"flare": _shader_mat(FLARE_SHADER),
			&"column": _shader_mat(COLUMN_SHADER)}
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
			if pool == &"flare":
				m.extra_cull_margin = 2.0   # billboards leave their mesh AABB
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


func _build_ripples() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(1.0, 1.0)
	var mat: Material = load(RIPPLE_MAT_PATH) if ResourceLoader.exists(RIPPLE_MAT_PATH) else null
	if mat == null:
		var sm := StandardMaterial3D.new()
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.cull_mode = BaseMaterial3D.CULL_DISABLED
		sm.vertex_color_use_as_albedo = true
		sm.albedo_color = Color(0.86, 0.96, 0.92, 0.85)
		sm.albedo_texture = _shape_tex(&"ring")
		sm.disable_receive_shadows = true
		mat = sm
	plane.material = mat
	_rip_mm = MultiMesh.new()
	_rip_mm.transform_format = MultiMesh.TRANSFORM_3D
	_rip_mm.use_colors = true
	_rip_mm.mesh = plane
	_rip_mm.instance_count = RIPPLE_MAX
	_rip_mm.custom_aabb = WORLD_AABB   # instances go anywhere: never cull, never recompute the bounds
	_rip_age.resize(RIPPLE_MAX)
	_rip_pos.resize(RIPPLE_MAX)
	_rip_size.resize(RIPPLE_MAX)
	for i in RIPPLE_MAX:
		_rip_age[i] = -1.0
		_rip_mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3(0, -50, 0)))
		_rip_mm.set_instance_color(i, Color(1, 1, 1, 0))
	_rip_mmi = MultiMeshInstance3D.new()
	_rip_mmi.name = "WadeRipples"
	_rip_mmi.multimesh = _rip_mm
	_rip_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_rip_mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	add_child(_rip_mmi)


func _build_runes() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	quad.material = _shader_mat(RUNE_SHADER)
	_rune_mm = MultiMesh.new()
	_rune_mm.transform_format = MultiMesh.TRANSFORM_3D
	_rune_mm.use_colors = true
	_rune_mm.use_custom_data = true
	_rune_mm.mesh = quad
	_rune_mm.instance_count = RUNE_MAX
	_rune_mm.visible_instance_count = 0
	_rune_buf.resize(RUNE_MAX * 20)
	_rune_buf.fill(0.0)
	_rune_col = _hdr(GOLD, 2.4)
	_rune_u.resize(RUNE_MAX)
	_rune_uid.resize(RUNE_MAX)
	_rune_uid.fill(0)
	_rune_fade.resize(RUNE_MAX)
	_rune_age.resize(RUNE_MAX)
	_rune_lift.resize(RUNE_MAX)
	_rune_seed.resize(RUNE_MAX)
	_rune_out.resize(RUNE_MAX)
	_rune_mm.buffer = _rune_buf
	_rune_mm.custom_aabb = WORLD_AABB
	_rune_mmi = MultiMeshInstance3D.new()
	_rune_mmi.name = "BlessingRunes"
	_rune_mmi.multimesh = _rune_mm
	_rune_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_rune_mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	add_child(_rune_mmi)


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
	var tall := look == &"gold_spiral" or look == &"gold_rise"
	p.visibility_aabb = AABB(Vector3(-8.0, -2.0, -8.0), Vector3(16.0, 28.0, 16.0)) if tall \
			else AABB(Vector3(-8.0, -3.0, -8.0), Vector3(16.0, 11.0, 16.0))
	return p


## Draw passes: textured billboard quads with a shape mask and billboard_keep_scale (no white squares) + streaks.
func _build_passes() -> void:
	_passes[&"add_dot"] = _particle_quad(_shape_tex(&"dot"), BaseMaterial3D.BLEND_MODE_ADD)
	_passes[&"add_star"] = _particle_quad(_shape_tex(&"star"), BaseMaterial3D.BLEND_MODE_ADD)
	_passes[&"mix_smoke"] = _particle_quad(_shape_tex(&"smoke"), BaseMaterial3D.BLEND_MODE_MIX)
	var leaf := _shape_tex(&"leaf")
	_passes[&"mix_leaf"] = _particle_quad(leaf, BaseMaterial3D.BLEND_MODE_MIX)
	_passes[&"add_leaf"] = _particle_quad(leaf, BaseMaterial3D.BLEND_MODE_ADD)
	var streak := QuadMesh.new()
	var sm := ShaderMaterial.new()
	sm.shader = STREAK_SHADER
	sm.set_shader_parameter(&"stretch", 4.0)
	streak.material = sm
	_passes[&"streak"] = streak


func _particle_quad(tex: Texture2D, blend: BaseMaterial3D.BlendMode) -> QuadMesh:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = blend
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.billboard_keep_scale = true   # Godot 4.7: without it the particle scale is ignored
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = tex
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.disable_receive_shadows = true
	if blend == BaseMaterial3D.BLEND_MODE_MIX:
		mat.proximity_fade_enabled = true
		mat.proximity_fade_distance = 0.5
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
				&"leaf":
					# A chunky almond leaf along the quad's diagonal, a darker midrib, a lighter upper half, a stem.
					var lu := (u + v) * 0.7071
					var lv := (v - u) * 0.7071                  # along the leaf, -1 tip .. 1 stem
					var t := clampf(1.0 - lv * lv / 0.72, 0.0, 1.0)
					var w := 0.5 * sqrt(t) * (1.0 - 0.2 * lv)
					var inside := clampf((w - absf(lu)) / 0.05, 0.0, 1.0)
					var stem := clampf(1.0 - absf(lu) / 0.045, 0.0, 1.0) * clampf((lv - 0.7) / 0.05, 0.0, 1.0) \
							* clampf((0.98 - lv) / 0.04, 0.0, 1.0)
					a = maxf(inside, stem)
					var rib := clampf(1.0 - absf(lu) / 0.04, 0.0, 1.0)
					shade = clampf(0.9 + 0.12 * signf(lu) - 0.3 * rib * inside - 0.25 * (1.0 - inside), 0.0, 1.0)
				&"ring":
					a = clampf(1.0 - absf(r - 0.82) / 0.08, 0.0, 1.0) + clampf(1.0 - absf(r - 0.62) / 0.05, 0.0, 1.0) * 0.3
					a = clampf(a, 0.0, 1.0) * clampf((1.0 - r) / 0.05, 0.0, 1.0)
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
	var skey := String(key)
	var team := -1
	if skey.ends_with("_0"):
		team = 0
	elif skey.ends_with("_1"):
		team = 1
	var base := StringName(skey.substr(0, skey.length() - 2)) if skey.ends_with("_0") or skey.ends_with("_1") \
			or skey.ends_with("_n") else key
	var tc := _team_color(team)
	var gold_hot := _hdr(GOLD_HOT, 2.6)
	var gold := _hdr(GOLD, 2.0)
	var gold_end := _hdr(BRASS, 1.2, 0.0)
	match base:
		&"cap_sparks":
			# Sparks shooting out along the ground from the capture ring.
			_shape_ring(m, 1.0, 0.1)
			m.emission_ring_inner_radius = 0.8
			m.direction = Vector3.UP
			m.spread = 25.0
			m.initial_velocity_min = 1.0
			m.initial_velocity_max = 3.0
			m.radial_velocity_min = 7.0
			m.radial_velocity_max = 11.0
			m.damping_min = 3.0
			m.damping_max = 4.0
			m.gravity = Vector3(0, -4.0, 0)
			m.particle_flag_align_y = true
			_size(m, 0.08, 0.12, &"shrink")
			var hot := _hdr(tc.lerp(Color.WHITE, 0.5), 2.6)
			var tcol := _hdr(tc, 2.2)
			m.color_ramp = _ramp([hot, tcol, tcol, Color(tcol, 0.0)])
		&"cap_motes":
			_shape_disc(m, 3.0)
			m.direction = Vector3.UP
			m.spread = 10.0
			m.initial_velocity_min = 1.2
			m.initial_velocity_max = 2.6
			m.damping_min = 0.8
			m.damping_max = 1.2
			_size(m, 0.18, 0.3, &"grow")
			var tcol := _hdr(tc, 2.2)
			m.color_ramp = _ramp([Color(tcol, 0.0), _hdr(tc.lerp(Color.WHITE, 0.4), 2.6), tcol, Color(tcol, 0.0)])
		&"gold_spiral":
			# Gold motes spiralling up around the waking shrine.
			_shape_ring(m, 1.8, 0.3)
			m.emission_ring_inner_radius = 0.6
			m.direction = Vector3.UP
			m.spread = 8.0
			m.initial_velocity_min = 2.5
			m.initial_velocity_max = 5.5
			m.damping_min = 0.4
			m.damping_max = 0.8
			m.tangential_accel_min = 3.0
			m.tangential_accel_max = 5.0
			m.radial_accel_min = -0.8
			m.radial_accel_max = -0.3
			_size(m, 0.22, 0.38, &"grow")
			m.color_ramp = _ramp([Color(gold, 0.0), gold_hot, gold, gold_end])
		&"gold_rise":
			_shape_sphere(m, 0.6)
			m.direction = Vector3.UP
			m.spread = 6.0
			m.initial_velocity_min = 8.0
			m.initial_velocity_max = 15.0
			m.damping_min = 1.5
			m.damping_max = 2.5
			m.particle_flag_align_y = true
			_size(m, 0.08, 0.12, &"shrink")
			m.color_ramp = _ramp([gold_hot, gold_hot, gold, gold_end])
		&"essence_motes":
			_shape_ring(m, 0.9, 0.1)
			m.emission_ring_inner_radius = 0.3
			m.direction = Vector3.UP
			m.spread = 14.0
			m.initial_velocity_min = 1.5
			m.initial_velocity_max = 2.8
			m.damping_min = 1.0
			m.damping_max = 1.4
			m.tangential_accel_min = 1.5
			m.tangential_accel_max = 2.5
			_size(m, 0.16, 0.28, &"grow")
			var ess := _hdr(ESSENCE, 2.2)
			m.color_ramp = _ramp([Color(ess, 0.0), _hdr(ESSENCE_HOT, 2.6), ess, Color(ess, 0.0)])
		&"essence_dots":
			_shape_disc(m, 0.7)
			m.direction = Vector3.UP
			m.spread = 20.0
			m.initial_velocity_min = 1.0
			m.initial_velocity_max = 2.2
			m.damping_min = 1.0
			m.damping_max = 1.6
			_size(m, 0.08, 0.14, &"shrink")
			var ess := _hdr(ESSENCE, 2.0)
			m.color_ramp = _ramp([_hdr(ESSENCE_HOT, 2.4), ess, Color(ess, 0.0)])
		&"dust_ring":
			_shape_ring(m, 2.4, 0.1)
			m.emission_ring_inner_radius = 1.4
			m.direction = Vector3.UP
			m.spread = 60.0
			m.initial_velocity_min = 0.4
			m.initial_velocity_max = 1.1
			m.radial_velocity_min = 0.6
			m.radial_velocity_max = 1.5
			m.damping_min = 1.5
			m.damping_max = 2.5
			m.gravity = Vector3(0, 0.2, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			m.angular_velocity_min = -30.0
			m.angular_velocity_max = 30.0
			_size(m, 1.3, 2.0, &"grow")
			m.color_initial_ramp = _ramp(_lin([Color(0.62, 0.53, 0.38), Color(0.53, 0.45, 0.32), Color(0.68, 0.60, 0.45)]))
			m.color_ramp = _ramp_at([0.0, 0.2, 1.0], [Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.75), Color(1, 1, 1, 0.0)])
		&"leaf_swirl":
			# Leaves kicked up in a swirl, then fluttering down.
			_shape_ring(m, 2.2, 0.2)
			m.emission_ring_inner_radius = 0.5
			m.direction = Vector3.UP
			m.spread = 30.0
			m.initial_velocity_min = 2.8
			m.initial_velocity_max = 4.5
			m.gravity = Vector3(0, -3.2, 0)
			m.damping_min = 0.6
			m.damping_max = 1.0
			m.tangential_accel_min = 3.0
			m.tangential_accel_max = 5.0
			m.angle_min = -180.0
			m.angle_max = 180.0
			m.angular_velocity_min = -320.0
			m.angular_velocity_max = 320.0
			_size(m, 0.24, 0.34, &"hold")
			m.color_initial_ramp = _ramp(_lin([Color(0.42, 0.55, 0.2), Color(0.62, 0.62, 0.22), Color(0.7, 0.45, 0.18),
					Color(0.35, 0.47, 0.18)]))
			m.color_ramp = _ramp([Color(1, 1, 1, 1.0), Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.0)])
		&"leaf_fall":
			_shape_disc(m, 3.0)
			m.direction = Vector3.DOWN
			m.spread = 25.0
			m.initial_velocity_min = 0.2
			m.initial_velocity_max = 0.6
			m.gravity = Vector3(0, -1.1, 0)
			m.damping_min = 0.6
			m.damping_max = 0.9
			m.tangential_accel_min = -1.2
			m.tangential_accel_max = 1.2
			m.angle_min = -180.0
			m.angle_max = 180.0
			m.angular_velocity_min = -220.0
			m.angular_velocity_max = 220.0
			_size(m, 0.18, 0.28, &"hold")
			m.color_initial_ramp = _ramp(_lin([Color(0.45, 0.58, 0.22), Color(0.72, 0.62, 0.22), Color(0.66, 0.4, 0.16)]))
			m.color_ramp = _ramp_at([0.0, 0.1, 0.8, 1.0],
					[Color(1, 1, 1, 0.0), Color(1, 1, 1, 1.0), Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.0)])
		&"spore_cloud":
			_shape_sphere(m, 1.4)
			m.emission_shape_scale = Vector3(1.0, 0.45, 1.0)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 1.2
			m.initial_velocity_max = 2.4
			m.damping_min = 2.0
			m.damping_max = 2.8
			m.gravity = Vector3(0, 0.25, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			m.angular_velocity_min = -30.0
			m.angular_velocity_max = 30.0
			m.scale_min = 1.8
			m.scale_max = 2.6
			m.scale_curve = _curve([Vector2(0.0, 0.4), Vector2(0.25, 1.0), Vector2(1.0, 1.25)])
			m.color_initial_ramp = _ramp(_lin([Color(0.66, 0.74, 0.78), Color(0.58, 0.70, 0.70), Color(0.74, 0.79, 0.86)]))
			m.color_ramp = _ramp_at([0.0, 0.12, 0.6, 1.0],
					[Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.7), Color(1, 1, 1, 0.0)])
		&"spore_motes":
			_shape_sphere(m, 2.4)
			m.emission_shape_scale = Vector3(1.0, 0.35, 1.0)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 0.3
			m.initial_velocity_max = 1.0
			m.damping_min = 0.4
			m.damping_max = 0.8
			m.gravity = Vector3(0, 0.3, 0)
			_size(m, 0.1, 0.18, &"grow")
			var sg := _hdr(SPORE_GLOW, 2.0)
			m.color_ramp = _ramp([Color(sg, 0.0), _hdr(SPORE_GLOW, 2.6), sg, Color(sg, 0.0)])
		&"glow_leaves":
			# Glowing leaves shed from the antlers, flung outward by the sweep.
			_shape_ring(m, 0.8, 0.3)
			m.emission_ring_inner_radius = 0.3
			m.direction = Vector3.UP
			m.spread = 40.0
			m.initial_velocity_min = 1.0
			m.initial_velocity_max = 2.5
			m.radial_velocity_min = 4.5
			m.radial_velocity_max = 7.0
			m.gravity = Vector3(0, -4.0, 0)
			m.damping_min = 1.5
			m.damping_max = 2.2
			m.angle_min = -180.0
			m.angle_max = 180.0
			m.angular_velocity_min = -420.0
			m.angular_velocity_max = 420.0
			_size(m, 0.22, 0.32, &"hold")
			var gl := _hdr(STAG_GREEN, 1.6)
			m.color_ramp = _ramp([_hdr(STAG_GREEN.lerp(Color.WHITE, 0.15), 2.0), gl, Color(_hdr(STAG_GREEN, 1.0), 0.0)])
		&"sweep_streaks":
			_shape_ring(m, 0.8, 0.1)
			m.emission_ring_inner_radius = 0.6
			m.direction = Vector3.UP
			m.spread = 10.0
			m.initial_velocity_min = 0.5
			m.initial_velocity_max = 1.5
			m.radial_velocity_min = 8.0
			m.radial_velocity_max = 12.0
			m.damping_min = 4.0
			m.damping_max = 5.0
			m.particle_flag_align_y = true
			_size(m, 0.08, 0.12, &"shrink")
			var sw := _hdr(STAG_GREEN, 2.2)
			m.color_ramp = _ramp([_hdr(STAG_GREEN.lerp(Color.WHITE, 0.5), 2.8), sw, Color(sw, 0.0)])
		&"bless_pop":
			_shape_sphere(m, 0.35)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 0.8
			m.initial_velocity_max = 1.8
			m.damping_min = 2.0
			m.damping_max = 3.0
			_size(m, 0.12, 0.2, &"shrink")
			m.color_ramp = _ramp([gold_hot, gold, gold_end])
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


## Particle sizes in metres + a scale curve: shrink (sparks), grow (motes, dust), hold (leaves).
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
