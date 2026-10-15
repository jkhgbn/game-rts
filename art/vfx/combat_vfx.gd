class_name CombatVfx
extends Node3D
## Combat effects (task 5.V4, polish A.12). Add ONE of these to a level, like SpellVfx; it never edits gameplay code.
## It hooks nodes as they appear (SceneTree.node_added, deferred) plus a 1 Hz safety rescan of the groups:
##   Unit      attack_landed -> melee hit: star flash + streak sparks in the ATTACKER's kingdom colour (melee only)
##             level_changed -> gold level-up pillar + ring + rising glints (one soft light)
##   Events    unit_died     -> death per kingdom: Fire ember burst + smoke, Shadow dissolve motes + smoke,
##                              Ice shatter (crystal shards + frost mist), Nature leaf burst + spores,
##                              neutral dust. Heroes: x1.9, light flash + shock ring.
##   Projectile (not SpellVfx's, not splash) -> glowing streak trail + flash / sparks where it ends.
##   Building  damaged       -> impact flash + stone chunks in the building's stone colour + dust (throttled)
##   ItemPickup picked_up    -> gold sparkle + ring (tree_exiting fallback if the signal is missing)
## Cost (100 v 100): particle bursts come from 4 small shared pools (one-shot GPUParticles3D, the look is swapped
## per burst: process material + draw pass), finished emitters are hidden. Hit flashes and projectile trails are
## TWO MultiMeshes (one draw call each, no emitters). LOD: at most SPAWNS_PER_FRAME new bursts per frame,
## effects outside the camera frustum are skipped, sparks farther than SPARK_CULL_DISTANCE are skipped, and when
## many emitters are live the secondary layers (smoke, spores) then the hit sparks are dropped (flash stays).
## Billboard materials use billboard_keep_scale, so ParticleProcessMaterial scale_min / scale_max are metres.
## Fog (2026-10-15, VfxFog): every burst / flash / ring / pillar / light is gated with the team of its source
## (`_fx_team`: attacker, dying unit, shooter); projectile trails re-check at VfxFog.RECHECK and collapse while hidden.

const META := &"combat_vfx"
const SPELL_META := &"spell_vfx"
const SUMMON_META := &"nature_vfx_summon"   # NatureVfx gives its summons their own wither death
const RESCAN_INTERVAL := 1.0
const SPAWNS_PER_FRAME := 10          # new particle bursts per frame, all looks together (deaths may exceed it)
const BUILDING_HIT_GAP := 0.15        # seconds between two debris bursts on one building
const MAX_LIGHTS := 3
const MAX_FLASHES := 64
const MAX_TRAILS := 64
const TRAIL_TIME := 0.075             # trail length = projectile speed x this (s)
const TRAIL_MAX_LENGTH := 2.4
const TRAIL_FADE := 0.1
const LOD_SECONDARY := 24             # live emitters above which smoke / spores / dust are skipped
const LOD_SPARKS := 36                # live emitters above which hit and impact sparks are skipped
const SPARK_CULL_DISTANCE := 70.0     # metres from the camera
const ZERO_BASIS := Basis(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO)   # a hidden trail instance (zero size)

enum Kind { FIRE, SHADOW, ICE, NATURE, NEUTRAL }
const KIND_NAMES: Array[StringName] = [&"fire", &"shadow", &"ice", &"nature", &"neutral"]

## Per kingdom (index = Kind): white-hot core, glow, deep (fade) colours; HDR, kept under ~1.8 for the bloom.
## Ice (in-game grade pass 2026-09-30): saturated cyan, no white-hot core, every channel <= 1.25 (the Ice line
## turned into one white smear mid-fight); Ice hit flashes and frost puffs are also half size / half life
## (ICE_HIT_SCALE, ICE_HIT_LIFE).
const HOT: Array[Color] = [Color(1.7, 1.1, 0.45), Color(1.35, 0.8, 1.8), Color(0.4, 0.95, 1.25),
		Color(1.3, 1.65, 0.6), Color(1.5, 1.4, 1.2)]
const GLOW: Array[Color] = [Color(1.5, 0.55, 0.12), Color(0.85, 0.32, 1.4), Color(0.12, 0.62, 1.1),
		Color(0.55, 1.25, 0.25), Color(1.0, 0.88, 0.65)]
const ICE_HIT_SCALE := 0.5
const ICE_HIT_LIFE := 0.5
## Ice readability pass (2026-10-12): Ice flashes are COOL (combat_flash.gdshader: ray strength + ICE_COOL = no
## white-hot core) and dimmer (ICE_FLASH alpha 0.6), so additive hits on the pale Ice units stay cyan and under the
## bloom; the Ice hit sparks / impacts are also dimmer (ICE_SPARK_ALPHA) and shorter.
const ICE_COOL := 2.0
const ICE_FLASH := Color(0.16, 0.6, 1.0, 0.6)
const ICE_SPARK_ALPHA := 0.7
## Ice death frost mist peak colour (the mist_ice look's ramp: fades in to this, then out).
const ICE_MIST := Color(0.3, 0.62, 0.9, 0.28)
const DEEP: Array[Color] = [Color(0.9, 0.2, 0.04), Color(0.35, 0.1, 0.6), Color(0.08, 0.32, 0.75),
		Color(0.2, 0.55, 0.12), Color(0.5, 0.45, 0.4)]
## art-keep.md 0.2 "glow" column (lights, rings).
const LIGHT: Array[Color] = [Color(1.0, 0.55, 0.15), Color(0.7, 0.3, 1.0), Color(0.75, 0.92, 1.0),
		Color(0.75, 1.0, 0.4), Color(1.0, 0.9, 0.7)]
## art-keep.md 0.2 stone / dark stone, lifted so chunks read against the wall they fly off.
const STONE: Array[Color] = [Color(0.52, 0.45, 0.4), Color(0.4, 0.35, 0.5), Color(0.8, 0.88, 0.95),
		Color(0.62, 0.58, 0.45), Color(0.5, 0.46, 0.4)]
const STONE_DARK: Array[Color] = [Color(0.16, 0.12, 0.12), Color(0.12, 0.1, 0.17), Color(0.36, 0.45, 0.56),
		Color(0.3, 0.27, 0.18), Color(0.22, 0.2, 0.18)]
const GOLD := Color(1.0, 0.78, 0.3)

const GROUND_SHADER := preload("res://art/vfx/vfx_ground.gdshader")
const STREAK_SHADER := preload("res://art/vfx/combat_streak.gdshader")
const FLASH_SHADER := preload("res://art/vfx/combat_flash.gdshader")

## Emitter pools: pool -> [particle amount, max emitters]. A look uses amount_ratio for its own count.
const POOLS := {
	&"spark": [12, 22],    # hit / impact sparks, spores, glints
	&"burst": [24, 12],    # death primaries, level-up, pickup
	&"puff": [7, 12],      # smoke, mist, dust (MIX)
	&"debris": [12, 8],    # building chunks
}

var _pools: Dictionary = {}           # pool -> Array[GPUParticles3D] (all emitters of the pool)
var _free: Dictionary = {}            # pool -> Array[GPUParticles3D] (idle, hidden)
var _steal: Dictionary = {}           # pool -> int ring index used when the pool is full
var _pool_of: Dictionary = {}         # GPUParticles3D -> pool
var _live: Array[GPUParticles3D] = []
var _live_end: PackedFloat32Array = PackedFloat32Array()
var _looks: Dictionary = {}           # look -> [pool, count, lifetime, draw mesh, process material]
var _spawn_budget := SPAWNS_PER_FRAME
var _clock := 0.0
var _building_last: Dictionary = {}   # Building -> msec of its last debris burst
var _lights: Array[OmniLight3D] = []
var _light_next := 0
var _pillars: Array[MeshInstance3D] = []
var _pillar_next := 0
var _rings: Array[MeshInstance3D] = []
var _ring_next := 0
var _rescan_left := 0.0
var _cam: Camera3D
var _cam_pos := Vector3.ZERO

# Hit flashes: one MultiMesh, fixed-capacity parallel arrays, swap-remove.
var _flash_mm: MultiMesh
var _fl_n := 0
var _fl_pos := PackedVector3Array()
var _fl_col := PackedColorArray()
var _fl_size := PackedFloat32Array()
var _fl_start := PackedFloat32Array()
var _flash_mat: ShaderMaterial
var _fl_dur := PackedFloat32Array()
var _fl_rot := PackedFloat32Array()
var _fl_rays := PackedFloat32Array()

# Projectile trails: one MultiMesh (2 instances each: wide glow + thin core), same scheme.
var _trail_mm: MultiMesh
var _tr_n := 0
var _tr_p: Array = []                # Projectile or null (untyped: freed projectiles are moved around)
var _tr_head := PackedVector3Array()
var _tr_vel := PackedVector3Array()
var _tr_kind := PackedInt32Array()
var _tr_fade := PackedFloat32Array()
var _tr_dirty := PackedByteArray()
var _tr_team := PackedInt32Array()     # shooter's team (VfxFog)
var _tr_shown := PackedByteArray()     # 1 = drawn (last fog check)
var _fx_team := -1                     # team of the effect being spawned (VfxFog gate; -1 = unknown)
var _fog_left := 0.0

# Counters for the stress preview (stats()).
var _n_bursts := 0
var _n_lod := 0
var _n_culled := 0
var _n_flashes := 0

var _soft_tex: GradientTexture2D
var _leaf_tex: ImageTexture
var _draw: Dictionary = {}            # draw key -> Mesh


func _ready() -> void:
	top_level = true                        # effects are placed in world space: keep this node at the origin
	global_transform = Transform3D.IDENTITY
	_build_shared()
	_build_looks()
	get_tree().node_added.connect(_on_node_added)
	var events := get_node_or_null(^"/root/Events")
	if events and events.has_signal(&"unit_died"):
		events.connect(&"unit_died", _on_unit_died)
	_rescan()


## Starts watching a node that has the Building / Unit / ItemPickup signals but no class (previews, tests).
func watch(node: Node) -> void:
	_hook(node)


## Counters for previews / perf checks.
func stats() -> Dictionary:
	var emitters := 0
	for pool: StringName in _pools:
		emitters += (_pools[pool] as Array).size()
	return {"bursts": _n_bursts, "skipped_lod": _n_lod, "skipped_offscreen": _n_culled, "flashes": _n_flashes,
			"emitters": emitters, "live_emitters": _live.size(), "trails": _tr_n}


func _process(delta: float) -> void:
	_clock += delta
	_spawn_budget = SPAWNS_PER_FRAME
	_cam = get_viewport().get_camera_3d()
	if _cam:
		_cam_pos = _cam.global_position
	_rescan_left -= delta
	if _rescan_left <= 0.0:
		_rescan_left = RESCAN_INTERVAL
		_rescan()
	# Hide finished emitters and give them back to their pool.
	for i in range(_live.size() - 1, -1, -1):
		if _clock >= _live_end[i]:
			var e := _live[i]
			e.visible = false
			(_free[_pool_of[e]] as Array).append(e)
			var last := _live.size() - 1
			_live[i] = _live[last]
			_live_end[i] = _live_end[last]
			_live.resize(last)
			_live_end.resize(last)
	if _fl_n > 0:
		_update_flashes()
	if _tr_n > 0 or _trail_mm.visible_instance_count > 0:
		_update_trails(delta)


# ---------------------------------------------------------------- hooking

func _on_node_added(node: Node) -> void:
	if node is Projectile:
		if node.get_parent() != self:
			_hook_projectile.call_deferred(node)   # deferred: launch_at_target runs right after add_child
	elif node is Unit or node is Building or node is ItemPickup:
		_hook.call_deferred(node)


func _rescan() -> void:
	var tree := get_tree()
	for group: StringName in [&"units", &"buildings", &"item_pickups"]:
		for node in tree.get_nodes_in_group(group):
			if not node.has_meta(META):
				_hook(node)


func _hook(node: Variant) -> void:
	if not is_instance_valid(node):
		return
	var n := node as Node3D
	if n == null or n.has_meta(META):
		return
	n.set_meta(META, true)
	if n.has_signal(&"attack_landed"):
		n.connect(&"attack_landed", _on_attack_landed.bind(n))
	if n.has_signal(&"level_changed"):
		n.connect(&"level_changed", _on_level_changed)
	if n.has_signal(&"damaged") and not n.has_signal(&"attack_landed"):
		n.connect(&"damaged", _on_building_damaged.bind(n))
		n.tree_exiting.connect(func() -> void: _building_last.erase(n), CONNECT_ONE_SHOT)
	if n is ItemPickup or n.is_in_group(&"item_pickups"):
		if n.has_signal(&"picked_up"):
			n.connect(&"picked_up", _on_picked_up)
		else:
			n.tree_exiting.connect(_on_pickup_gone.bind(n), CONNECT_ONE_SHOT)


func _hook_projectile(node: Variant) -> void:
	if not is_instance_valid(node) or not (node as Node).is_inside_tree():
		return
	var p := node as Projectile
	if p == null or p.has_meta(META) or p.has_meta(SPELL_META) or p.splash_radius > 0.0:
		return   # fireballs and spell projectiles are SpellVfx's / IceVfx's
	p.set_meta(META, true)
	var kind := _kind_of_color(p.color)
	var team := -1
	if is_instance_valid(p.source):
		kind = _kind_of(p.source, kind)
		team = VfxFog.team_of(p.source)
	if _tr_n < MAX_TRAILS:
		var i := _tr_n
		_tr_n += 1
		_tr_p[i] = p
		_tr_head[i] = p.global_position
		_tr_vel[i] = Vector3.ZERO
		_tr_kind[i] = kind
		_tr_fade[i] = 1.0
		_tr_dirty[i] = 1
		_tr_team[i] = team
		_tr_shown[i] = 1 if VfxFog.ok(team, p.global_position) else 0
	p.tree_exiting.connect(_on_projectile_gone.bind(p, kind, team), CONNECT_ONE_SHOT)


# ---------------------------------------------------------------- events

func _on_attack_landed(target: Variant, _amount: float, attacker: Node3D) -> void:
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return
	var range_v: Variant = attacker.get(&"attack_range")
	if range_v != null and float(range_v) > 3.0:
		return   # ranged: the projectile makes its own impact
	var t := target as Node3D
	var pos := t.global_position
	_fx_team = VfxFog.team_of(attacker)
	if not _in_view(pos, 1.5):
		_n_culled += 1
		return
	var dir := pos - attacker.global_position
	dir.y = 0.0
	dir = dir.normalized() if dir.length() > 0.01 else Vector3.FORWARD
	var r := float((t as Unit).radius) if t is Unit else Unit.radius_of(t) * 0.8
	var h := _height(t) if t is Unit else 1.5
	pos += -dir * r * 0.9 + Vector3.UP * h * 0.55
	var k := _kind_of(attacker, Kind.NEUTRAL)
	var heavy := _height(attacker) > 2.0
	var ice_k := k == Kind.ICE
	_flash(pos, ICE_FLASH if ice_k else GLOW[k].lerp(HOT[k], 0.4),
			(1.4 if heavy else 1.05) * (ICE_HIT_SCALE if ice_k else 1.0),
			0.16 * (ICE_HIT_LIFE if ice_k else 1.0), ICE_COOL + 0.6 if ice_k else 1.0)
	if _live.size() < LOD_SPARKS and _near(pos):
		_burst(StringName("spark_" + KIND_NAMES[k]), pos, dir, (1.25 if heavy else 1.0) * (0.6 if ice_k else 1.0))
	else:
		_n_lod += 1


func _on_projectile_gone(p: Projectile, kind: int, team: int = -1) -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		return
	_fx_team = team
	var pos := p.global_position
	if not _in_view(pos, 1.0):
		_n_culled += 1
		return
	var dir := Vector3.FORWARD
	if is_instance_valid(p.source):
		var s := (p.source as Node3D).global_position
		dir = Vector3(pos.x - s.x, 0.0, pos.z - s.z)
		dir = dir.normalized() if dir.length() > 0.01 else Vector3.FORWARD
	var ice_k := kind == Kind.ICE
	_flash(pos, ICE_FLASH if ice_k else GLOW[kind].lerp(HOT[kind], 0.4), 0.75 * (ICE_HIT_SCALE if ice_k else 1.0),
			0.14 * (ICE_HIT_LIFE if ice_k else 1.0), ICE_COOL + 0.5 if ice_k else 0.8)
	if _live.size() < LOD_SPARKS and _near(pos):
		_burst(StringName("impact_" + KIND_NAMES[kind]), pos, -dir, 0.6 if ice_k else 1.0)   # splash back toward the shooter
	else:
		_n_lod += 1


func _on_unit_died(unit: Variant) -> void:
	if not is_instance_valid(unit):
		return
	var u := unit as Node3D
	var pos := u.global_position
	_fx_team = VfxFog.team_of(u)
	var hero := u is Wizard or u.is_in_group(&"heroes") or u.is_in_group(&"enemy_heroes")
	if not hero and not _in_view(pos, 3.0):
		_n_culled += 1
		return
	var h := _height(u)
	var k := _kind_of(u, Kind.NEUTRAL)
	var s := clampf(h / 1.6, 0.8, 1.35)
	if hero:
		s = 1.9
	var second := _live.size() < LOD_SECONDARY or hero
	var mid := pos + Vector3.UP * h * 0.5
	if k == Kind.ICE:
		_flash(mid, ICE_FLASH, 1.5 * s * 0.6, 0.26 * 0.7, ICE_COOL + 0.8)
	else:
		_flash(mid, GLOW[k].lerp(HOT[k], 0.5), 1.5 * s, 0.26, 1.0)
	match k:
		Kind.FIRE:
			_burst(&"death_fire", pos + Vector3.UP * h * 0.4, Vector3.FORWARD, s, true)
			if second:
				_burst(&"smoke_fire", pos + Vector3.UP * 0.35, Vector3.FORWARD, s)
		Kind.SHADOW:
			_burst(&"death_shadow", mid, Vector3.FORWARD, s, true)
			if second:
				_burst(&"smoke_shadow", pos + Vector3.UP * 0.35, Vector3.FORWARD, s)
		Kind.ICE:
			_burst(&"death_ice", mid, Vector3.FORWARD, s, true)
			if second:
				_burst(&"mist_ice", pos + Vector3.UP * 0.4, Vector3.FORWARD, s)
				_burst(&"glint_ice", mid, Vector3.FORWARD, s)
		Kind.NATURE:
			if not u.has_meta(SUMMON_META):   # NatureVfx withers its own summons
				_burst(&"death_nature", mid, Vector3.FORWARD, s, true)
			if second:
				_burst(&"spores_nature", pos + Vector3.UP * 0.3, Vector3.FORWARD, s)
		_:
			_burst(&"dust", pos + Vector3.UP * 0.4, Vector3.FORWARD, s, true)
			_burst(&"chunks_neutral", mid, Vector3.FORWARD, s * 0.8, true)
	if hero:
		_flash(mid + Vector3.UP * 0.3, LIGHT[k], 2.4, 0.4, 0.5)
		_ring(pos, 0.4, 3.2, LIGHT[k], 0.55)
		_light_flash(pos + Vector3.UP * 1.8, LIGHT[k], 2.2, 8.0, 0.6)


func _on_building_damaged(_amount: float, attacker: Variant, b: Node3D) -> void:
	if not is_instance_valid(b) or not b.is_inside_tree():
		return
	var now := Time.get_ticks_msec()
	if now - int(_building_last.get(b, -100000)) < int(BUILDING_HIT_GAP * 1000.0):
		return
	_building_last[b] = now
	var dir := Vector3.FORWARD
	var hit_h := randf_range(1.0, 2.2)
	if is_instance_valid(attacker):
		var d := b.global_position - (attacker as Node3D).global_position
		d.y = 0.0
		if d.length() > 0.01:
			dir = d.normalized()
		if attacker.get(&"attack_range") != null and float(attacker.get(&"attack_range")) > 3.0:
			hit_h = Projectile.BUILDING_AIM_HEIGHT
	var r := Unit.radius_of(b) * 0.8
	var pos := b.global_position - dir * r + Vector3.UP * hit_h
	_fx_team = VfxFog.team_of(attacker)
	if not _in_view(pos, 2.0):
		_n_culled += 1
		return
	var k := _kind_of(b, Kind.NEUTRAL)
	_flash(pos, Color(1.4, 1.2, 0.9), 0.9, 0.12, 0.6)
	_burst(StringName("debris_" + KIND_NAMES[k]), pos, -dir)
	if _live.size() < LOD_SECONDARY:
		_burst(&"dust", pos + Vector3(0.0, -0.5, 0.0) - dir * 0.3, -dir, 1.1)


func _on_level_changed(unit: Variant, _level: int) -> void:
	if not is_instance_valid(unit):
		return
	var u := unit as Node3D
	if not u.is_inside_tree() or not _in_view(u.global_position, 3.0):
		return
	_fx_team = VfxFog.team_of(u)
	var pos := u.global_position
	var h := _height(u)
	_burst(&"levelup_glints", pos + Vector3.UP * 0.2, Vector3.FORWARD, 1.0, true)
	_burst(&"levelup_rise", pos + Vector3.UP * 0.1, Vector3.FORWARD, 1.0, true)
	_pillar(pos, h + 2.4)
	_ring(pos, 0.3, 1.6, GOLD, 0.5)
	_light_flash(pos + Vector3.UP * 1.6, GOLD, 0.8, 4.5, 0.4)


func _on_picked_up(pickup: Variant, _wizard: Variant, _type: Variant) -> void:
	if is_instance_valid(pickup):
		_pickup_fx((pickup as Node3D).global_position)


func _on_pickup_gone(p: Node3D) -> void:
	if is_inside_tree() and p.is_inside_tree():
		_pickup_fx(p.global_position)


func _pickup_fx(pos: Vector3) -> void:
	_fx_team = -1   # a ground item: shown where the local player sees it
	_burst(&"pickup_sparkle", pos + Vector3.UP * 0.6, Vector3.FORWARD, 1.0, true)
	_flash(pos + Vector3.UP * 0.6, Color(1.5, 1.2, 0.6), 0.9, 0.18, 1.0)
	_ring(pos, 0.2, 1.1, GOLD, 0.35)


# ---------------------------------------------------------------- culling / LOD

## Inside the camera frustum (or within `margin` metres of it). No camera = always.
func _in_view(pos: Vector3, margin: float) -> bool:
	if _cam == null:
		return true
	if _cam.is_position_in_frustum(pos):
		return true
	return _cam.is_position_in_frustum(pos + Vector3(margin, 0.0, 0.0)) \
			or _cam.is_position_in_frustum(pos - Vector3(margin, 0.0, 0.0)) \
			or _cam.is_position_in_frustum(pos + Vector3(0.0, 0.0, margin)) \
			or _cam.is_position_in_frustum(pos - Vector3(0.0, 0.0, margin))


func _near(pos: Vector3) -> bool:
	return _cam == null or _cam_pos.distance_squared_to(pos) < SPARK_CULL_DISTANCE * SPARK_CULL_DISTANCE


# ---------------------------------------------------------------- pooled bursts

## Starts a pooled one-shot burst of `look` at `pos`; its local -Z points along `dir`; `size` scales it
## (spread, speed and particle size). `force` ignores the per-frame budget (deaths, level-ups).
func _burst(look: StringName, pos: Vector3, dir: Vector3, size: float = 1.0, force: bool = false) -> void:
	if not is_inside_tree() or is_queued_for_deletion() or not _looks.has(look):
		return
	if not VfxFog.ok(_fx_team, pos):
		return
	if _spawn_budget <= 0 and not force:
		_n_lod += 1
		return
	_spawn_budget -= 1
	_n_bursts += 1
	var info: Array = _looks[look]
	var e := _take(info[0])
	var pmat: ParticleProcessMaterial = info[4]
	if e.process_material != pmat:
		e.process_material = pmat
	var mesh: Mesh = info[3]
	if e.draw_pass_1 != mesh:
		e.draw_pass_1 = mesh
	var life: float = info[2]
	if not is_equal_approx(e.lifetime, life):
		e.lifetime = life
	e.amount_ratio = float(info[1]) / float(e.amount)
	var b := Basis.looking_at(dir, Vector3.UP if absf(dir.y) < 0.95 else Vector3.RIGHT)
	e.global_transform = Transform3D(b.scaled(Vector3.ONE * clampf(size, 0.5, 2.2)), pos)
	e.visible = true
	e.restart()
	var end := _clock + life + 0.1
	var i := _live.find(e)
	if i >= 0:
		_live_end[i] = end
	else:
		_live.append(e)
		_live_end.append(end)


func _take(pool: StringName) -> GPUParticles3D:
	var free: Array = _free[pool]
	if not free.is_empty():
		return free.pop_back()
	var all: Array = _pools[pool]
	var spec: Array = POOLS[pool]
	if all.size() < int(spec[1]):
		var e := GPUParticles3D.new()
		e.amount = int(spec[0])
		e.lifetime = 1.0
		e.one_shot = true
		e.explosiveness = 1.0
		e.emitting = false
		e.local_coords = false
		e.fixed_fps = 30
		e.interpolate = true
		e.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		e.visibility_aabb = AABB(Vector3(-4.0, -3.0, -4.0), Vector3(8.0, 9.0, 8.0))
		e.visible = false
		add_child(e)
		all.append(e)
		_pool_of[e] = pool
		return e
	# Pool full: recycle the oldest live one of this pool.
	var idx := int(_steal[pool]) % all.size()
	_steal[pool] = idx + 1
	return all[idx]


# ---------------------------------------------------------------- flashes (MultiMesh)

func _flash(pos: Vector3, col: Color, size: float, dur: float, rays: float) -> void:
	if _fl_n >= MAX_FLASHES or not VfxFog.ok(_fx_team, pos):
		return
	var i := _fl_n
	_fl_n += 1
	_n_flashes += 1
	_fl_pos[i] = pos
	_fl_col[i] = col
	# Zoomed out, flashes grow up to x1.6 so a hit still reads from 40-55 m.
	_fl_size[i] = size * (clampf(_cam_pos.distance_to(pos) / 25.0, 1.0, 1.6) if _cam else 1.0)
	_fl_start[i] = _clock
	_fl_dur[i] = dur
	_fl_rot[i] = randf() * TAU
	_fl_rays[i] = rays
	_write_flash(i)
	_flash_mm.visible_instance_count = _fl_n


## combat_flash.gdshader animates a flash from its start time: an instance is only written when it starts
## or when the swap-remove below moves it.
func _write_flash(i: int) -> void:
	var s := _fl_size[i]
	_flash_mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(s, s, s)), _fl_pos[i]))
	_flash_mm.set_instance_color(i, _fl_col[i])
	_flash_mm.set_instance_custom_data(i, Color(_fl_rot[i], _fl_rays[i], _fl_start[i], _fl_dur[i]))


func _update_flashes() -> void:
	_flash_mat.set_shader_parameter(&"now", _clock)
	var i := 0
	var moved := false
	while i < _fl_n:
		if _clock - _fl_start[i] >= _fl_dur[i]:
			_fl_n -= 1
			var j := _fl_n
			if i != j:
				_fl_pos[i] = _fl_pos[j]
				_fl_col[i] = _fl_col[j]
				_fl_size[i] = _fl_size[j]
				_fl_start[i] = _fl_start[j]
				_fl_dur[i] = _fl_dur[j]
				_fl_rot[i] = _fl_rot[j]
				_fl_rays[i] = _fl_rays[j]
				_write_flash(i)
			moved = true
			continue
		i += 1
	if moved:
		_flash_mm.visible_instance_count = _fl_n


# ---------------------------------------------------------------- trails (MultiMesh)

func _update_trails(delta: float) -> void:
	_fog_left -= delta
	var fog_check := _fog_left <= 0.0
	if fog_check:
		_fog_left = VfxFog.RECHECK
	var i := 0
	while i < _tr_n:
		var p: Variant = _tr_p[i]
		if is_instance_valid(p) and (p as Node3D).is_inside_tree():
			var pos := (p as Node3D).global_position
			var v := (pos - _tr_head[i]) / maxf(delta, 0.001)
			_tr_vel[i] = v if _tr_vel[i] == Vector3.ZERO else _tr_vel[i].lerp(v, 0.5)
			_tr_head[i] = pos
			if fog_check:   # an enemy shot in fog the local player does not see: collapsed (drawn as nothing)
				_tr_shown[i] = 1 if VfxFog.ok(_tr_team[i], pos) else 0
		else:
			_tr_p[i] = null
			_tr_fade[i] -= delta / TRAIL_FADE
			if _tr_fade[i] <= 0.0:
				_tr_n -= 1
				var j := _tr_n
				_tr_p[i] = _tr_p[j]
				_tr_p[j] = null
				_tr_head[i] = _tr_head[j]
				_tr_vel[i] = _tr_vel[j]
				_tr_kind[i] = _tr_kind[j]
				_tr_fade[i] = _tr_fade[j]
				_tr_team[i] = _tr_team[j]
				_tr_shown[i] = _tr_shown[j]
				_tr_dirty[i] = 1
				continue
		if _tr_shown[i] == 0:
			var hid := Transform3D(ZERO_BASIS, _tr_head[i])
			_trail_mm.set_instance_transform(i * 2, hid)
			_trail_mm.set_instance_transform(i * 2 + 1, hid)
			_tr_dirty[i] = 1
			i += 1
			continue
		var fade := _tr_fade[i]
		var along := _tr_vel[i] * TRAIL_TIME
		var l := along.length()
		if l > TRAIL_MAX_LENGTH:
			along *= TRAIL_MAX_LENGTH / l
			l = TRAIL_MAX_LENGTH
		along *= fade
		if l < 0.02:
			along = Vector3(0.0, 0.02, 0.0)
		var k := _tr_kind[i]
		var head := _tr_head[i]
		var mid := head - along * 0.5
		_trail_mm.set_instance_transform(i * 2, _streak_xform(mid, along, 0.4))
		_trail_mm.set_instance_transform(i * 2 + 1, _streak_xform(mid, along, 0.11))
		if fade < 1.0 or _tr_dirty[i] != 0:   # colours only change when a trail starts, moves slot or fades
			_tr_dirty[i] = 0
			var core := HOT[k].lerp(GLOW[k], 0.35)
			_trail_mm.set_instance_color(i * 2, Color(GLOW[k].r, GLOW[k].g, GLOW[k].b, 0.85 * fade))
			_trail_mm.set_instance_color(i * 2 + 1, Color(core.r, core.g, core.b, fade))
		i += 1
	_trail_mm.visible_instance_count = _tr_n * 2


## Basis for combat_streak.gdshader: Y = the streak (length included), X / Z = width.
static func _streak_xform(mid: Vector3, along: Vector3, width: float) -> Transform3D:
	var y := along
	var side := y.cross(Vector3.UP)
	if side.length_squared() < 0.000001:
		side = Vector3.RIGHT
	var x := side.normalized() * width
	var z := x.cross(y).normalized() * width
	return Transform3D(Basis(x, y, z), mid)


# ---------------------------------------------------------------- lights, pillar, ring (rare, tweened)

func _light_flash(pos: Vector3, col: Color, energy: float, reach: float, time: float) -> void:
	if not VfxFog.ok(_fx_team, pos):
		return
	var l: OmniLight3D
	if _lights.size() < MAX_LIGHTS:
		l = OmniLight3D.new()
		l.shadow_enabled = false
		l.light_specular = 0.2
		add_child(l)
		_lights.append(l)
	else:
		l = _lights[_light_next]
		_light_next = (_light_next + 1) % MAX_LIGHTS
	l.light_color = col
	l.omni_range = reach
	l.light_energy = energy
	l.global_position = pos
	l.visible = true
	var tw := l.create_tween()
	tw.tween_property(l, "light_energy", 0.0, time).set_ease(Tween.EASE_IN)
	tw.tween_callback(l.hide)


## Gold level-up pillar: a slim additive cylinder that shoots up, spins its gradient and fades (0.7 s).
func _pillar(pos: Vector3, height: float) -> void:
	if not VfxFog.ok(_fx_team, pos):
		return
	var m: MeshInstance3D
	if _pillars.size() < 4:
		m = MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.26
		cyl.bottom_radius = 0.42
		cyl.height = 1.0
		cyl.radial_segments = 16
		cyl.rings = 1
		cyl.cap_top = false
		cyl.cap_bottom = false
		m.mesh = cyl
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		mat.albedo_texture = _pillar_tex()
		m.material_override = mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(m)
		_pillars.append(m)
	else:
		m = _pillars[_pillar_next]
		_pillar_next = (_pillar_next + 1) % _pillars.size()
	var mat2 := m.material_override as StandardMaterial3D
	mat2.albedo_color = Color(1.05, 0.72, 0.26, 0.5)
	m.visible = true
	m.global_position = pos
	m.scale = Vector3(0.7, 0.05, 0.7)
	m.rotation.y = 0.0
	var tw := m.create_tween().set_parallel(true)
	tw.tween_property(m, "scale", Vector3(1.0, height, 1.0), 0.16).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(m, "position:y", pos.y + height * 0.5, 0.16).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(m, "rotation:y", TAU * 0.5, 0.7)
	tw.tween_property(mat2, "albedo_color:a", 0.0, 0.5).set_delay(0.2)
	tw.tween_property(m, "scale:x", 0.2, 0.5).set_delay(0.2)
	tw.tween_property(m, "scale:z", 0.2, 0.5).set_delay(0.2)
	tw.chain().tween_callback(m.hide)


## Expanding glowing ground ring (pooled, vfx_ground.gdshader like SpellVfx).
func _ring(pos: Vector3, r0: float, r1: float, col: Color, time: float) -> void:
	if not VfxFog.ok(_fx_team, pos):
		return
	var ring: MeshInstance3D
	if _rings.size() < 6:
		ring = MeshInstance3D.new()
		ring.mesh = _draw[&"plane"]
		var mat := ShaderMaterial.new()
		mat.shader = GROUND_SHADER
		mat.set_shader_parameter(&"ring_energy", 2.4)
		mat.set_shader_parameter(&"ring_width", 0.12)
		mat.set_shader_parameter(&"ember_strength", 0.0)
		ring.material_override = mat
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ring)
		_rings.append(ring)
	else:
		ring = _rings[_ring_next]
		_ring_next = (_ring_next + 1) % _rings.size()
	var m := ring.material_override as ShaderMaterial
	m.set_shader_parameter(&"fill_color", Color(col, 0.12))
	m.set_shader_parameter(&"ring_color", Color(col, 1.0))
	m.set_shader_parameter(&"fade", 1.0)
	ring.visible = true
	ring.global_position = pos + Vector3.UP * 0.07
	ring.scale = Vector3(r0, 1.0, r0)
	var tw := ring.create_tween().set_parallel(true)
	tw.tween_property(ring, "scale", Vector3(r1, 1.0, r1), time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(m, "shader_parameter/fade", 0.0, time)
	tw.chain().tween_callback(ring.hide)


# ---------------------------------------------------------------- helpers

## Kingdom of a unit, wizard, building or tower (data faction first, then Wizard.kingdom, then colours).
func _kind_of(n: Node, fallback: int) -> int:
	var f: StringName = &""
	var ut: Variant = n.get(&"unit_type")
	if ut != null and is_instance_valid(ut):
		f = StringName((ut as Object).get(&"faction"))
	else:
		var bt: Variant = n.get(&"building_type")
		if bt != null and is_instance_valid(bt) and (bt as Object).get(&"faction") != null:
			f = StringName((bt as Object).get(&"faction"))
	if f == &"":
		var kd: Variant = n.get(&"kingdom")
		if kd != null:
			f = StringName(kd)
	var i := KIND_NAMES.find(f)
	if i >= 0:
		return i
	if n.is_in_group(&"heroes") or n.is_in_group(&"enemy_heroes"):
		var bc: Variant = n.get(&"body_color")
		if bc is Color:
			return _kind_of_color(bc)
	return fallback


func _kind_of_color(c: Color) -> int:
	if c.g > c.r and c.g > c.b:
		return Kind.NATURE
	if c.b > c.r and c.g > c.r * 1.3:
		return Kind.ICE
	return Kind.SHADOW if c.b > c.r else Kind.FIRE


func _height(u: Node3D) -> float:
	var h: Variant = u.get(&"body_height")
	return float(h) if h != null else 1.6


func _build_shared() -> void:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.35, Color(1, 1, 1, 0.75))
	_soft_tex = GradientTexture2D.new()
	_soft_tex.gradient = g
	_soft_tex.fill = GradientTexture2D.FILL_RADIAL
	_soft_tex.fill_from = Vector2(0.5, 0.5)
	_soft_tex.fill_to = Vector2(1.0, 0.5)
	_soft_tex.width = 64
	_soft_tex.height = 64
	_leaf_tex = _make_leaf_tex()
	_draw[&"soft_add"] = _billboard_quad(_soft_tex, BaseMaterial3D.BLEND_MODE_ADD)
	_draw[&"soft_mix"] = _billboard_quad(_soft_tex, BaseMaterial3D.BLEND_MODE_MIX)
	_draw[&"leaf"] = _billboard_quad(_leaf_tex, BaseMaterial3D.BLEND_MODE_MIX)
	# Sparks / embers: velocity-aligned streaks (4 x longer than wide).
	var streak := QuadMesh.new()
	var sm := ShaderMaterial.new()
	sm.shader = STREAK_SHADER
	sm.set_shader_parameter(&"stretch", 4.0)
	streak.material = sm
	_draw[&"streak"] = streak
	# Stone chunks and ice shards: small shaded meshes, colour from the particle (vertex colour).
	var chunk := BoxMesh.new()
	chunk.size = Vector3.ONE
	var cm := StandardMaterial3D.new()
	cm.vertex_color_use_as_albedo = true
	cm.roughness = 1.0
	chunk.material = cm
	_draw[&"chunk"] = chunk
	var shard := CylinderMesh.new()   # a 4-sided spike, point along +Y (align_y puts it along the flight)
	shard.top_radius = 0.0
	shard.bottom_radius = 0.22
	shard.height = 1.0
	shard.radial_segments = 4
	shard.rings = 1
	var ice := StandardMaterial3D.new()
	ice.vertex_color_use_as_albedo = true
	ice.roughness = 0.12
	ice.metallic_specular = 0.9
	ice.emission_enabled = true
	ice.emission = Color(0.35, 0.55, 0.75)
	ice.emission_energy_multiplier = 0.6
	ice.rim_enabled = true
	ice.rim = 0.6
	ice.rim_tint = 0.2
	shard.material = ice
	_draw[&"shard"] = shard
	var plane := PlaneMesh.new()
	plane.size = Vector2(2.0, 2.0)
	_draw[&"plane"] = plane
	for pool: StringName in POOLS:
		_pools[pool] = []
		_free[pool] = []
		_steal[pool] = 0
	# Flash MultiMesh.
	var fq := QuadMesh.new()
	_flash_mat = ShaderMaterial.new()
	_flash_mat.shader = FLASH_SHADER
	fq.material = _flash_mat
	_flash_mm = _make_mm(fq, MAX_FLASHES, true)
	_fl_pos.resize(MAX_FLASHES)
	_fl_col.resize(MAX_FLASHES)
	_fl_size.resize(MAX_FLASHES)
	_fl_start.resize(MAX_FLASHES)
	_fl_dur.resize(MAX_FLASHES)
	_fl_rot.resize(MAX_FLASHES)
	_fl_rays.resize(MAX_FLASHES)
	# Trail MultiMesh.
	var tq := QuadMesh.new()
	var tm := ShaderMaterial.new()
	tm.shader = STREAK_SHADER
	tm.set_shader_parameter(&"stretch", 1.0)
	tm.set_shader_parameter(&"tail_power", 1.2)
	tm.set_shader_parameter(&"core_width", 0.3)
	tq.material = tm
	_trail_mm = _make_mm(tq, MAX_TRAILS * 2, false)
	_tr_p.resize(MAX_TRAILS)
	_tr_head.resize(MAX_TRAILS)
	_tr_vel.resize(MAX_TRAILS)
	_tr_kind.resize(MAX_TRAILS)
	_tr_fade.resize(MAX_TRAILS)
	_tr_dirty.resize(MAX_TRAILS)
	_tr_team.resize(MAX_TRAILS)
	_tr_shown.resize(MAX_TRAILS)


func _make_mm(mesh: Mesh, count: int, custom: bool) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = custom
	mm.mesh = mesh
	mm.instance_count = count
	mm.visible_instance_count = 0
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.custom_aabb = AABB(Vector3(-2000.0, -100.0, -2000.0), Vector3(4000.0, 400.0, 4000.0))
	add_child(mmi)
	return mm


func _billboard_quad(tex: Texture2D, blend: BaseMaterial3D.BlendMode) -> QuadMesh:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = blend
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.billboard_keep_scale = true   # without it Godot draws every billboard particle at the quad size
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = tex
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.disable_receive_shadows = true
	var q := QuadMesh.new()
	q.size = Vector2.ONE   # 1 m: ParticleProcessMaterial scale_min / scale_max are the sizes in metres
	q.material = mat
	return q


## A pointed leaf (tip up), white so the particle colour tints it; soft edge, brighter midrib.
static func _make_leaf_tex() -> ImageTexture:
	var s := 32
	var img := Image.create_empty(s, s, false, Image.FORMAT_RGBA8)
	for y in s:
		for x in s:
			var u := (float(x) + 0.5) / float(s) * 2.0 - 1.0
			var v := (float(y) + 0.5) / float(s)          # 0 = tip, 1 = stem
			var w := sin(clampf(v * 1.08, 0.0, 1.0) * PI) * 0.7 * (1.0 - 0.3 * v)
			var a := 1.0 - smoothstep(w - 0.14, w, absf(u))
			if v > 0.9:
				a = maxf(a, 1.0 - smoothstep(0.05, 0.1, absf(u)))   # stem
			var rib := 1.0 - smoothstep(0.03, 0.09, absf(u))
			var shade := 0.72 + 0.18 * (1.0 - absf(u) / maxf(w, 0.05)) + 0.25 * rib
			img.set_pixel(x, y, Color(shade, shade, shade, clampf(a, 0.0, 1.0)))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _pillar_tex() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.12, 0.55, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.85), Color(1, 1, 1, 0.3), Color(1, 1, 1, 0.0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill_from = Vector2(0.0, 1.0)   # v = 1 at the bottom of a CylinderMesh
	t.fill_to = Vector2(0.0, 0.0)
	t.width = 8
	t.height = 64
	return t


# ---------------------------------------------------------------- looks

## look -> [pool, particle count, lifetime, draw mesh, process material]. Directions are local: the emitter's
## -Z is the hit direction (see _burst). Sizes (scale_min / scale_max) are metres.
func _build_looks() -> void:
	var m: ParticleProcessMaterial
	for k in KIND_NAMES.size():
		var kn := String(KIND_NAMES[k])
		# Melee hit sparks: a fan of hot streaks thrown along the blow.
		m = _pm()
		_sphere(m, 0.1)
		m.direction = Vector3(0.0, 0.4, -1.0)
		m.spread = 55.0
		m.initial_velocity_min = 5.0
		m.initial_velocity_max = 10.0
		m.gravity = Vector3(0, -12.0, 0)
		m.damping_min = 5.0
		m.damping_max = 9.0
		m.particle_flag_align_y = true
		_size(m, 0.08, 0.13, false)
		var ice_a := ICE_SPARK_ALPHA if k == Kind.ICE else 1.0
		m.color_ramp = _ramp([Color(HOT[k], ice_a), Color(GLOW[k], ice_a), Color(GLOW[k], ice_a), Color(DEEP[k], 0.0)])
		_look(StringName("spark_" + kn), &"spark", 9, 0.35 * (0.7 if k == Kind.ICE else 1.0), &"streak", m)
		# Projectile impact: a smaller splash thrown back and up.
		m = _pm()
		_sphere(m, 0.08)
		m.direction = Vector3(0.0, 0.9, -0.6)
		m.spread = 65.0
		m.initial_velocity_min = 3.0
		m.initial_velocity_max = 6.5
		m.gravity = Vector3(0, -12.0, 0)
		m.damping_min = 3.0
		m.damping_max = 6.0
		m.particle_flag_align_y = true
		_size(m, 0.06, 0.1, false)
		m.color_ramp = _ramp([Color(HOT[k], ice_a), Color(GLOW[k], ice_a), Color(GLOW[k], ice_a), Color(DEEP[k], 0.0)])
		_look(StringName("impact_" + kn), &"spark", 7, 0.3 * (0.7 if k == Kind.ICE else 1.0), &"streak", m)
		# Building chunks in the kingdom's stone.
		m = _pm()
		_sphere(m, 0.3)
		m.direction = Vector3(0.0, 0.8, -1.0)
		m.spread = 45.0
		m.initial_velocity_min = 3.5
		m.initial_velocity_max = 7.0
		m.gravity = Vector3(0, -18.0, 0)
		m.angular_velocity_min = -540.0
		m.angular_velocity_max = 540.0
		m.angle_min = 0.0
		m.angle_max = 360.0
		m.particle_flag_rotate_y = true
		_size_hold(m, 0.16, 0.34)
		m.color_initial_ramp = _ramp([STONE[k], STONE[k].lerp(STONE_DARK[k], 0.4), STONE_DARK[k]], false)
		_look(StringName("debris_" + kn), &"debris", 11, 1.0, &"chunk", m)
	_look(&"chunks_neutral", &"debris", 7, 0.9, &"chunk", _pmat_of(&"debris_neutral"))
	var fi := Kind.FIRE
	var sh := Kind.SHADOW
	var ic := Kind.ICE
	var na := Kind.NATURE
	# Fire death: embers bursting up (streaks) + dark smoke.
	m = _pm()
	_sphere(m, 0.35)
	m.direction = Vector3.UP
	m.spread = 60.0
	m.initial_velocity_min = 3.0
	m.initial_velocity_max = 7.5
	m.gravity = Vector3(0, -7.0, 0)
	m.damping_min = 1.5
	m.damping_max = 3.0
	m.particle_flag_align_y = true
	_size(m, 0.07, 0.13, false)
	m.color_ramp = _ramp([HOT[fi], GLOW[fi], Color(DEEP[fi], 0.0)])
	_look(&"death_fire", &"burst", 22, 0.9, &"streak", m)
	m = _smoke([Color(0.25, 0.14, 0.1, 0.0), Color(0.2, 0.13, 0.11, 0.6), Color(0.14, 0.11, 0.11, 0.0)])
	_look(&"smoke_fire", &"puff", 6, 1.1, &"soft_mix", m)
	# Shadow death: violet motes dissolving upward in a spiral + purple smoke.
	m = _pm()
	_box(m, Vector3(0.35, 0.7, 0.35))
	m.direction = Vector3.UP
	m.spread = 25.0
	m.initial_velocity_min = 0.8
	m.initial_velocity_max = 2.2
	m.gravity = Vector3(0, 1.8, 0)
	m.tangential_accel_min = 1.5
	m.tangential_accel_max = 3.0
	_size(m, 0.14, 0.26, false)
	m.color_ramp = _ramp([Color(GLOW[sh], 0.0), GLOW[sh], Color(0.6, 0.2, 1.1), Color(DEEP[sh], 0.0)])
	_look(&"death_shadow", &"burst", 24, 1.3, &"soft_add", m)
	m = _smoke([Color(0.2, 0.1, 0.3, 0.0), Color(0.17, 0.07, 0.27, 0.65), Color(0.1, 0.05, 0.16, 0.0)])
	_look(&"smoke_shadow", &"puff", 6, 1.2, &"soft_mix", m)
	# Ice death: shatter. Crystal spikes fly out along their velocity and fall, frost mist, bright glints.
	m = _pm()
	_sphere(m, 0.3)
	m.direction = Vector3.UP
	m.spread = 75.0
	m.initial_velocity_min = 3.5
	m.initial_velocity_max = 7.0
	m.gravity = Vector3(0, -16.0, 0)
	m.damping_min = 0.5
	m.damping_max = 1.0
	m.particle_flag_align_y = true
	_size_hold(m, 0.18, 0.4)
	m.color_initial_ramp = _ramp([Color(0.55, 0.82, 1.0), Color(0.36, 0.6, 0.86), Color(0.24, 0.42, 0.66)], false)
	_look(&"death_ice", &"burst", 16, 0.95, &"shard", m)
	# Frost mist: half the old size and life, cyan (a white puff the size of a unit read as a render glitch;
	# 2026-10-12: the blue-grey still read pale over snow, now a saturated cyan at alpha 0.28).
	m = _smoke([Color(ICE_MIST, 0.0), ICE_MIST, Color(0.24, 0.5, 0.8, 0.0)])
	m.initial_velocity_max = 1.4
	_size(m, 0.3, 0.5, true)
	_look(&"mist_ice", &"puff", 5, 0.5, &"soft_mix", m)
	m = _pm()
	_sphere(m, 0.45)
	m.direction = Vector3.UP
	m.spread = 90.0
	m.initial_velocity_min = 1.5
	m.initial_velocity_max = 4.0
	m.gravity = Vector3(0, -3.0, 0)
	m.damping_min = 2.0
	m.damping_max = 3.0
	m.particle_flag_align_y = true
	_size(m, 0.05, 0.08, false)
	m.color_ramp = _ramp([HOT[ic], GLOW[ic], Color(DEEP[ic], 0.0)])
	_look(&"glint_ice", &"spark", 10, 0.6, &"streak", m)
	# Nature death: a burst of spinning leaves that flutter down + green spores drifting up.
	m = _pm()
	_sphere(m, 0.35)
	m.direction = Vector3.UP
	m.spread = 70.0
	m.initial_velocity_min = 2.5
	m.initial_velocity_max = 5.5
	m.gravity = Vector3(0, -2.6, 0)
	m.damping_min = 2.0
	m.damping_max = 3.0
	m.tangential_accel_min = -2.0
	m.tangential_accel_max = 2.0
	m.angle_min = 0.0
	m.angle_max = 360.0
	m.angular_velocity_min = -320.0
	m.angular_velocity_max = 320.0
	_size_hold(m, 0.28, 0.46)
	m.color_initial_ramp = _ramp([Color(0.5, 0.9, 0.22), Color(0.3, 0.68, 0.16), Color(0.72, 0.85, 0.2)], false)
	m.color_ramp = _ramp([Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0.0)])
	_look(&"death_nature", &"burst", 18, 1.5, &"leaf", m)
	m = _pm()
	_sphere(m, 0.55)
	m.direction = Vector3.UP
	m.spread = 45.0
	m.initial_velocity_min = 0.8
	m.initial_velocity_max = 2.2
	m.gravity = Vector3(0, 0.8, 0)
	m.damping_min = 0.5
	m.damping_max = 1.0
	_size(m, 0.08, 0.15, false)
	m.color_ramp = _ramp([Color(HOT[na], 0.0), HOT[na], GLOW[na], Color(DEEP[na], 0.0)])
	_look(&"spores_nature", &"spark", 11, 1.2, &"soft_add", m)
	# Neutral death and building dust: warm grey dust, opaque enough to read on grass and stone.
	m = _smoke([Color(0.72, 0.66, 0.58, 0.0), Color(0.7, 0.65, 0.57, 0.8), Color(0.55, 0.5, 0.45, 0.0)])
	m.direction = Vector3(0.0, 0.5, -1.0)
	m.initial_velocity_max = 2.6
	_size(m, 0.8, 1.5, true)
	_look(&"dust", &"puff", 7, 1.1, &"soft_mix", m)
	# Level-up: gold glints shooting up from a ring + motes spiralling up.
	m = _pm()
	_ring_shape(m, 0.6, 0.1)
	m.direction = Vector3.UP
	m.spread = 12.0
	m.initial_velocity_min = 3.0
	m.initial_velocity_max = 6.0
	m.gravity = Vector3(0, -1.5, 0)
	m.damping_min = 1.0
	m.damping_max = 2.0
	m.particle_flag_align_y = true
	_size(m, 0.07, 0.11, false)
	m.color_ramp = _ramp([Color(1.5, 1.15, 0.5), Color(1.2, 0.8, 0.25), Color(1.0, 0.55, 0.1, 0.0)])
	_look(&"levelup_glints", &"burst", 20, 1.0, &"streak", m)
	m = _pm()
	_ring_shape(m, 0.75, 0.1)
	m.direction = Vector3.UP
	m.spread = 5.0
	m.initial_velocity_min = 1.8
	m.initial_velocity_max = 3.2
	m.gravity = Vector3.ZERO
	m.tangential_accel_min = 2.0
	m.tangential_accel_max = 3.0
	_size(m, 0.1, 0.18, false)
	m.color_ramp = _ramp([Color(1.3, 1.0, 0.4), Color(1.1, 0.75, 0.22), Color(1.0, 0.6, 0.12, 0.0)])
	_look(&"levelup_rise", &"burst", 14, 1.2, &"soft_add", m)
	# Item pickup: gold sparkle.
	m = _pm()
	_sphere(m, 0.45)
	m.direction = Vector3.UP
	m.spread = 60.0
	m.initial_velocity_min = 1.0
	m.initial_velocity_max = 3.0
	m.gravity = Vector3(0, 1.0, 0)
	m.damping_min = 2.0
	m.damping_max = 3.0
	m.tangential_accel_min = 2.0
	m.tangential_accel_max = 4.0
	_size(m, 0.08, 0.16, false)
	m.color_ramp = _ramp([Color(1.5, 1.3, 0.7), Color(1.3, 0.9, 0.3), Color(1.0, 0.6, 0.15, 0.0)])
	_look(&"pickup_sparkle", &"burst", 18, 0.9, &"soft_add", m)


func _look(look: StringName, pool: StringName, count: int, life: float, draw: StringName,
		m: ParticleProcessMaterial) -> void:
	count = mini(count, int(POOLS[pool][0]))
	_looks[look] = [pool, count, life, _draw[draw], m]


func _pmat_of(look: StringName) -> ParticleProcessMaterial:
	return _looks[look][4]


func _pm() -> ParticleProcessMaterial:
	var m := ParticleProcessMaterial.new()
	m.particle_flag_inherit_emitter_scale = true   # _burst's `size` also scales the particles (hero deaths)
	return m


func _smoke(colors: Array) -> ParticleProcessMaterial:
	var m := _pm()
	_sphere(m, 0.4)
	m.direction = Vector3.UP
	m.spread = 80.0
	m.initial_velocity_min = 0.8
	m.initial_velocity_max = 1.8
	m.gravity = Vector3(0, 0.6, 0)
	m.damping_min = 1.5
	m.damping_max = 2.5
	m.angle_min = 0.0
	m.angle_max = 360.0
	_size(m, 0.8, 1.3, true)
	m.color_ramp = _ramp(colors)
	return m


func _sphere(m: ParticleProcessMaterial, r: float) -> void:
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = r


func _box(m: ParticleProcessMaterial, ext: Vector3) -> void:
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = ext


func _ring_shape(m: ParticleProcessMaterial, r: float, h: float) -> void:
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	m.emission_ring_axis = Vector3.UP
	m.emission_ring_radius = r
	m.emission_ring_inner_radius = r * 0.8
	m.emission_ring_height = h


## Sizes in metres; grow = puff (half size -> full at 30 % -> 30 %), else shrink from full to 10 %.
func _size(m: ParticleProcessMaterial, lo: float, hi: float, grow: bool) -> void:
	m.scale_min = lo
	m.scale_max = hi
	var c := Curve.new()
	if grow:
		c.add_point(Vector2(0.0, 0.5))
		c.add_point(Vector2(0.3, 1.0))
		c.add_point(Vector2(1.0, 0.3))
	else:
		c.add_point(Vector2(0.0, 1.0))
		c.add_point(Vector2(1.0, 0.1))
	var ct := CurveTexture.new()
	ct.curve = c
	m.scale_curve = ct


## Sizes in metres; solid bits (chunks, shards, leaves) keep their size, then shrink away in the last 25 %.
func _size_hold(m: ParticleProcessMaterial, lo: float, hi: float) -> void:
	m.scale_min = lo
	m.scale_max = hi
	var c := Curve.new()
	c.add_point(Vector2(0.0, 1.0))
	c.add_point(Vector2(0.75, 0.9))
	c.add_point(Vector2(1.0, 0.0))
	var ct := CurveTexture.new()
	ct.curve = c
	m.scale_curve = ct


func _ramp(colors: Array, hdr: bool = true) -> GradientTexture1D:
	var g := Gradient.new()
	var offsets := PackedFloat32Array()
	for i in colors.size():
		offsets.append(float(i) / float(colors.size() - 1))
	g.offsets = offsets
	g.colors = PackedColorArray(colors)
	var t := GradientTexture1D.new()
	t.gradient = g
	t.use_hdr = hdr
	return t
