class_name CritterSystem
extends Node3D
## Cosmetic ambient critters (task 12.V16, docs/design/map-fill.md 3.3 and 9): 3 bird flocks x 6, 30 butterflies,
## 40 fireflies, 12 dragonflies, 10 frogs and a pool of 3 splashes (leaping fish, frog dives) = 113 (<= 120).
## DRAW-ONLY: no collider, no click, no Unit, never in "units", no fog source, never read by gameplay.
## - One MultiMesh per kind (6 draw calls), each drawn by its own shader (critter_<kind>.gdshader) that computes all the
##   motion (flap, hop, loops, darts, jumps) from a clock this node sets on the materials every frame; the CPU only
##   writes an instance when its state changes (take-off, landing, a frog's jump...). 0 lights, 0 shadows.
## - 10 Hz logic, alternating a visibility pass (camera range + fog) and a reaction pass (units nearby):
##   * only critters within ANIM_RANGE (50 m) of the camera focus and in cells the local team sees NOW (FogOfWar state
##     VISIBLE) are drawn and animate, at most MAX_ANIMATED (60), nearest first; the rest are parked (hidden);
##   * birds take off when a unit VISIBLE to the local team (or an own unit) comes within 8 m, circle 6-10 s at
##     6-12 m and land at another spot; frogs jump into the water within 4 m and come back after 10 s. Hidden units
##     never scare anything (no information leak). Units are read only through `visible` / `global_position`.
## - Frogs, dragonflies, bank fireflies and splashes need water: they read the RiverSystem (group "river",
##   `shader_params()`, optional `is_water` / `is_bridge` / `crossings`) through GroundParams' analytic distance; with
##   no RiverSystem but a level whose `river_enabled` is true they use the map-fill.md 2.1 river (fixed spots); a level
##   without a river gets no water critters.
## - Settings "Map detail: Low" (GameSettings.map_detail == &"low", read load-guarded at setup) builds nothing.
##
## Glue (the lead, next to the map dressing in main.gd `_ready`):
##     if ResourceLoader.exists("res://art/environment/critters/critter_system.gd"):
##         var critters: Node3D = load("res://art/environment/critters/critter_system.gd").new()
##         critters.name = "CritterSystem"
##         add_child(critters)
##         critters.call(&"setup", self)
## The build waits until the level's `hero` exists (the navmesh is baked, trees / river in place) and runs in a
## physics frame (spot checks ray-cast the world).

enum Kind { BIRD, BUTTERFLY, FIREFLY, DRAGONFLY, FROG, SPLASH }

const DIR := "res://art/environment/critters/"
const KIND_IDS: Array[StringName] = [&"bird", &"butterfly", &"firefly", &"dragonfly", &"frog", &"splash"]
const GAME_SETTINGS_PATH := "res://scripts/ui/menus/game_settings.gd"
const GROUND_PARAMS_PATH := "res://art/environment/ground_params.gd"
const MAP_DETAIL_LOW := &"low"

const MAX_CRITTERS := 120
const MAX_ANIMATED := 60
const ANIM_RANGE := 50.0
const TICK := 0.1
const BUILD_TIMEOUT := 6.0          ## Build anyway if the level's hero never shows up (previews, odd levels).
const WATER_Y := -0.35

# Birds (map-fill.md 3.3). Keep BIRD_FLY_SPEED / ACCEL / RISE and the bob in sync with critter_bird.gdshader.
const BIRD_FLOCKS := 3
const BIRDS_PER_FLOCK := 6
const BIRD_SCARE := 8.0
const BIRD_FLY_SPEED := 6.5
const BIRD_ACCEL_TIME := 0.8
const BIRD_RISE_TIME := 2.4
const BIRD_HEIGHT := Vector2(6.0, 12.0)
const BIRD_CIRCLE_TIME := Vector2(6.0, 10.0)
const BIRD_IDLE_FLIGHT := Vector2(40.0, 90.0)   ## A settled flock moves on by itself every 40-90 s.
const BIRD_SPREAD := 1.7
const BIRD_HOP_REACH := 0.6                     ## The ground hops wander this far from a bird's spot.
const BIRD_SCALE: Array[float] = [1.4, 1.1, 1.2]   ## crows, finches, bluewings
## 12 landing spots in the glade / heath / meadow: these 6 (player half) + their point mirrors.
const BIRD_SPOTS_HALF: Array[Vector2] = [Vector2(-24, 41), Vector2(-55, 30), Vector2(-33, 15), Vector2(-24, 55),
	Vector2(-45, -26), Vector2(-13, 29)]
const BIRD_START_SPOTS: Array[int] = [0, 6, 2]
# Butterflies: 5 flower patches per half x 3.
const BUTTERFLY_PATCHES_HALF: Array[Vector2] = [Vector2(-28, 29), Vector2(-42, 21), Vector2(-21, 45),
	Vector2(-25, 12), Vector2(-11, 34)]
const BUTTERFLIES_PER_PATCH := 3
# Fireflies: Old Wood clumps per half (x, z, count, radius) + 6 under the bank willows per half (moved into the
# Old Wood when there is no water).
const FIREFLY_WOOD_HALF: Array[Vector4] = [Vector4(-30, -56, 4, 3.5), Vector4(-57, -32, 4, 3.0),
	Vector4(-49, -53, 3, 3.0), Vector4(-44, -30, 3, 3.0)]
const FIREFLIES_BANK_HALF := 6
const DRAGONFLIES_HALF := 6
const FROGS_HALF := 5
const FROG_SCARE := 4.0
const FROG_UNDER_TIME := 10.0
const FROG_JUMP_END := 1.3          ## crouch 0.12 + leap 0.55 + sinking; then parked under water.
const FROG_RETURN_TIME := 1.0
const SPLASH_POOL := 3
const SPLASH_LIFETIME := 2.2
const FISH_INTERVAL := Vector2(6.0, 10.0)
const FISH_VIEW_RANGE := 26.0
## map-fill.md 2.2 bridge centres (fallback when the RiverSystem gives no crossings).
const BRIDGES_FALLBACK: Array[Vector2] = [Vector2(-12, -48.7), Vector2(12, 48.7), Vector2(-9.02, 9.02),
	Vector2(9.02, -9.02)]
const BRIDGE_CLEAR := 6.5
const MAP_LIMIT := 56.0             ## Crown Hollow (120 m); other maps: their half size - 4 m (_limit).
const GRID_CELL := 4.0              ## Reaction pass cells (metres).

## Tests / tools: &"low" or &"high" here beats the settings store (empty = read GameSettings.map_detail).
static var map_detail_override: StringName = &""

var level: Node

var _enabled := true
var _built := false
var _building := false
var _wait := 0.0
var _clock := 0.0
var _tick_left := 0.0
var _phase := 0
var _rng := RandomNumberGenerator.new()
var _focus := Vector3.ZERO
var _focus_override: Variant = null
var _fog: FogOfWar

var _mmi: Array[MultiMeshInstance3D] = []
var _mm: Array[MultiMesh] = []
var _mats: Array[ShaderMaterial] = []
var _kind_first := PackedInt32Array()
var _kind_count := PackedInt32Array()

# Per critter (index i over all kinds).
var _n := 0
var _kind := PackedInt32Array()
var _slot := PackedInt32Array()
var _origin := PackedVector3Array()
var _yaw := PackedFloat32Array()
var _scale := PackedFloat32Array()
var _custom := PackedColorArray()
var _home := PackedVector3Array()
var _shown := PackedByteArray()
var _d2 := PackedFloat32Array()
var _bin := PackedByteArray()

# Birds.
var _spots: Array[Vector3] = []
var _spot_offsets: Array[PackedVector3Array] = []
var _flocks: Array[Dictionary] = []
# Frogs: {i, bank, water, state, t, threat}
var _frogs: Array[Dictionary] = []
# Water.
var _water := false
var _fish_spots := PackedVector3Array()
var _next_fish := 0.0
var _splash_end := PackedFloat32Array()
# Map scale (review L3): the spot tables are Crown Hollow's (120 m); on another map size they are stretched by
# MapInfo half / 60 per axis (1, 1 on Crown Hollow), and the water / reaction limits follow the map.
var _k := Vector2.ONE
var _limit := MAP_LIMIT
# Reaction pass scratch: GRID_CELL cells over [-_grid_half, _grid_half] (Crown Hollow: 32 x 32 over [-64, 64]).
var _grid_half := 64.0
var _grid_n := 32
var _mask := PackedByteArray()
var _marked := PackedInt32Array()
var _t_pos := PackedVector3Array()
var _t_r2 := PackedFloat32Array()
var _t_ref := PackedInt32Array()

enum { FLOCK_GROUND, FLOCK_FLY, FLOCK_LAND }
enum { FROG_SIT, FROG_JUMP, FROG_UNDER, FROG_RETURN }


# ---------------------------------------------------------------- public API

## Starts the critters for `level` (the main / skirmish node). Safe before or after add_child. The build itself waits
## for the level's hero (navmesh baked) and runs in a physics frame; calling setup again rebuilds.
func setup(p_level: Node) -> void:
	level = p_level
	_clear()
	_built = false
	_building = true
	_wait = 0.0
	set_physics_process(true)


## Shows / hides every critter at once (their logic pauses while hidden).
func set_enabled(on: bool) -> void:
	_enabled = on
	if not _built:
		return
	if on:
		_update_visibility()
	else:
		for i: int in _n:
			if _shown[i] != 0:
				_shown[i] = 0
				_write(i)


func is_enabled() -> bool:
	return _enabled


## True once the critters exist (false before the build, and with Map detail Low).
func is_built() -> bool:
	return _built


## Number of critters of a kind id (&"bird", &"butterfly", &"firefly", &"dragonfly", &"frog", &"splash"), all if empty.
func critter_count(kind: StringName = &"") -> int:
	if kind == &"":
		return _n
	var k := KIND_IDS.find(kind)
	return _kind_count[k] if k >= 0 and k < _kind_count.size() else 0


## Critters drawn (and animating) right now.
func animated_count() -> int:
	var c := 0
	for i: int in _n:
		c += _shown[i]
	return c


## Read-only snapshot for tests and tools: [{kind, index, pos, shown, state}], `pos` = where the CPU places it
## (birds: their flight position).
func critters_info(kind: StringName = &"") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i: int in _n:
		if kind != &"" and KIND_IDS[_kind[i]] != kind:
			continue
		out.append({"kind": KIND_IDS[_kind[i]], "index": i, "pos": _cpu_pos(i), "shown": _shown[i] != 0,
			"state": _state_name(i)})
	return out


## The camera focus used for the 50 m range (null = the current camera's ground point). Tests and previews.
func set_focus_override(pos: Variant) -> void:
	_focus_override = pos
	if _built:
		_focus = _camera_focus()
		_update_visibility()


## Test / profiling hook: runs `frames` frames of the critter logic at 60 fps (clock, materials, the 10 Hz tick)
## right now and returns the average cost per frame in microseconds.
func benchmark(frames: int) -> float:
	var t0 := Time.get_ticks_usec()
	for k: int in frames:
		_process(1.0 / 60.0)
	return float(Time.get_ticks_usec() - t0) / float(maxi(frames, 1))


## The Map detail setting the next build uses: map_detail_override, else GameSettings.map_detail (load-guarded),
## else &"high".
static func map_detail() -> StringName:
	if map_detail_override != &"":
		return map_detail_override
	if not ResourceLoader.exists(GAME_SETTINGS_PATH):
		return &"high"
	var gs := load(GAME_SETTINGS_PATH) as Script
	if gs == null:
		return &"high"
	if gs.has_method(&"ensure_read"):
		gs.call(&"ensure_read")
	var v: Variant = gs.get(&"map_detail")
	if v == null:
		return &"high"
	return StringName(str(v))


# ---------------------------------------------------------------- frame

func _ready() -> void:
	set_physics_process(_building)


func _physics_process(delta: float) -> void:
	if not _building:
		set_physics_process(false)
		return
	_wait += delta
	var hero_ready := true
	if is_instance_valid(level) and &"hero" in level:
		hero_ready = level.get(&"hero") != null
	if not hero_ready and _wait < BUILD_TIMEOUT:
		return
	_building = false
	set_physics_process(false)
	_build()


func _process(delta: float) -> void:
	if not _built or _n == 0:
		return
	_clock += delta
	for m: ShaderMaterial in _mats:
		if m:
			m.set_shader_parameter(&"clock", _clock)
	if not _enabled:
		return
	_tick_left -= delta
	if _tick_left > 0.0:
		return
	_tick_left += TICK
	if _tick_left < 0.0:
		_tick_left = TICK
	_tick()


func _tick() -> void:
	_focus = _camera_focus()
	_phase = 1 - _phase
	_update_flocks()
	_update_frogs()
	_update_splashes()
	if _phase == 0:
		_update_visibility()
	else:
		_react()


# ---------------------------------------------------------------- build

func _clear() -> void:
	for m: MultiMeshInstance3D in _mmi:
		if is_instance_valid(m):
			m.queue_free()
	_mmi.clear()
	_mm.clear()
	_mats.clear()
	_n = 0
	_kind.clear()
	_slot.clear()
	_origin.clear()
	_yaw.clear()
	_scale.clear()
	_custom.clear()
	_home.clear()
	_shown.clear()
	_d2.clear()
	_bin.clear()
	_spots.clear()
	_spot_offsets.clear()
	_flocks.clear()
	_frogs.clear()
	_fish_spots.clear()
	_splash_end.clear()
	_kind_first.clear()
	_kind_count.clear()
	_water = false


func _build() -> void:
	_clear()
	_rng.seed = 1216
	_fog = FogOfWar.find()
	_built = true
	_k = Vector2(MapInfo.half_x() / 60.0, MapInfo.half_z() / 60.0)
	_limit = minf(MapInfo.half_x(), MapInfo.half_z()) - 4.0
	_grid_half = maxf(64.0, ceilf((MapInfo.half_max() + 4.0) / GRID_CELL) * GRID_CELL)
	_grid_n = int(_grid_half * 2.0 / GRID_CELL)
	if map_detail() == MAP_DETAIL_LOW:
		return
	var model := _water_model()
	_water = not model.is_empty()
	var per_kind: Array[Array] = [[], [], [], [], [], []]   # of Dictionary {origin, yaw, scale, custom}
	_build_birds(per_kind[Kind.BIRD])
	_build_butterflies(per_kind[Kind.BUTTERFLY])
	var banks: Dictionary = _water_spots(model) if _water else {}
	_build_fireflies(per_kind[Kind.FIREFLY], banks.get("fireflies", PackedVector3Array()))
	if _water:
		_build_dragonflies(per_kind[Kind.DRAGONFLY], banks.get("dragonflies", []))
		_build_frogs(per_kind[Kind.FROG], banks.get("frogs", []))
		for i: int in SPLASH_POOL:
			per_kind[Kind.SPLASH].append({"origin": Vector3(0, WATER_Y, 0), "yaw": 0.0, "scale": 1.0,
				"custom": Color(-100.0, 0, 0, 0)})
		_fish_spots = banks.get("fish", PackedVector3Array())
	# Flatten.
	var builder: RefCounted = null
	for k: int in per_kind.size():
		var list: Array = per_kind[k]
		_kind_first.append(_n)
		_kind_count.append(list.size())
		var slot := 0
		for e: Dictionary in list:
			if _n >= MAX_CRITTERS:
				break
			_kind.append(k)
			_slot.append(slot)
			_origin.append(e["origin"])
			_yaw.append(float(e["yaw"]))
			_scale.append(float(e["scale"]))
			_custom.append(e["custom"])
			_home.append(e.get("home", e["origin"]))
			_shown.append(0)
			_d2.append(-1.0)
			_bin.append(0)
			slot += 1
			_n += 1
		_kind_count[k] = slot
		if slot == 0:
			_mmi.append(null)
			_mm.append(null)
			_mats.append(null)
			continue
		var mesh: Mesh = null
		var mesh_path := DIR + "meshes/critter_%s.res" % KIND_IDS[k]
		if ResourceLoader.exists(mesh_path):
			mesh = load(mesh_path) as Mesh
		if mesh == null:
			if builder == null:
				builder = (load(DIR + "critter_meshes.gd") as GDScript).new()
			mesh = builder.call(&"build", KIND_IDS[k])
		var mat := load(DIR + "materials/critter_%s_mat.tres" % KIND_IDS[k]) as ShaderMaterial
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.mesh = mesh
		mm.instance_count = slot
		var ext := MapInfo.half_max() + 10.0   # Crown Hollow: 70
		mm.custom_aabb = AABB(Vector3(-ext, -2, -ext), Vector3(ext * 2.0, 22, ext * 2.0))
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Critters_%s" % KIND_IDS[k]
		mmi.multimesh = mm
		mmi.material_override = mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		mmi.custom_aabb = mm.custom_aabb
		add_child(mmi)
		_mmi.append(mmi)
		_mm.append(mm)
		_mats.append(mat)
	# Group bookkeeping now that indices are known.
	var bf: int = _kind_first[Kind.BIRD]
	for f: int in _flocks.size():
		var members := PackedInt32Array()
		for j: int in BIRDS_PER_FLOCK:
			members.append(bf + f * BIRDS_PER_FLOCK + j)
		_flocks[f]["members"] = members
	var ff: int = _kind_first[Kind.FROG]
	for j: int in _frogs.size():
		_frogs[j]["i"] = ff + j
	_splash_end.resize(_kind_count[Kind.SPLASH])
	_splash_end.fill(0.0)
	_next_fish = _clock + _rng.randf_range(FISH_INTERVAL.x, FISH_INTERVAL.y)
	for i: int in _n:
		_write(i)
	_mask.resize(_grid_n * _grid_n)
	_mask.fill(0)
	_focus = _camera_focus()
	if _enabled:
		_update_visibility()


func _build_birds(out: Array) -> void:
	for p: Vector2 in BIRD_SPOTS_HALF:
		_spots.append(Vector3(p.x * _k.x, 0, p.y * _k.y))
	for p: Vector2 in BIRD_SPOTS_HALF:
		_spots.append(Vector3(-p.x * _k.x, 0, -p.y * _k.y))
	for s: int in _spots.size():
		_spots[s] = _free_spot(_spots[s], 3.0)
		var offs := PackedVector3Array()
		var tries := 0
		while offs.size() < BIRDS_PER_FLOCK and tries < 60:
			tries += 1
			var a := _rng.randf() * TAU
			var r := sqrt(_rng.randf()) * BIRD_SPREAD
			var o := Vector3(cos(a) * r, 0, sin(a) * r)
			var ok := not _blocked(_spots[s] + o, BIRD_HOP_REACH)
			for q: Vector3 in offs:
				if q.distance_to(o) < 0.5:
					ok = false
			if ok or tries > 40:
				offs.append(o)
		_spot_offsets.append(offs)
	for f: int in BIRD_FLOCKS:
		var spot: int = BIRD_START_SPOTS[f]
		_flocks.append({"spot": spot, "target": spot, "state": FLOCK_GROUND, "land_at": 0.0,
			"next_idle": _rng.randf_range(15.0, BIRD_IDLE_FLIGHT.y), "centre": _spots[spot],
			"members": PackedInt32Array(), "switch_at": PackedFloat32Array(), "heights": PackedFloat32Array()})
		for j: int in BIRDS_PER_FLOCK:
			out.append({"origin": _spots[spot] + _spot_offsets[spot][j], "yaw": _rng.randf() * TAU,
				"scale": BIRD_SCALE[f] * _rng.randf_range(0.92, 1.08), "custom": Color(_clock, 0, 0, 0)})


func _build_butterflies(out: Array) -> void:
	for side: float in [1.0, -1.0]:
		for c: Vector2 in BUTTERFLY_PATCHES_HALF:
			var pal := _rng.randi_range(0, 3)
			for j: int in BUTTERFLIES_PER_PATCH:
				var a := _rng.randf() * TAU
				var o := Vector3(c.x * _k.x * side + cos(a) * 1.5, 0, c.y * _k.y * side + sin(a) * 1.5)
				# Mostly one colour per patch, now and then another.
				var p := pal if _rng.randf() < 0.65 else _rng.randi_range(0, 3)
				out.append({"origin": o, "yaw": 0.0, "scale": _rng.randf_range(1.2, 1.45),
					"custom": Color(_rng.randf(), float(p), _rng.randf_range(1.4, 2.6), _rng.randf_range(0.8, 1.5))})


func _build_fireflies(out: Array, bank: PackedVector3Array) -> void:
	var extra := FIREFLIES_BANK_HALF * 2 - bank.size()   # without water: the bank ones go to the Old Wood
	for side: float in [1.0, -1.0]:
		for w: Vector4 in FIREFLY_WOOD_HALF:
			var cnt := int(w.z)
			if extra > 0:
				var add := mini(extra, 2 if side > 0.0 else 1)
				cnt += add
				extra -= add
			for j: int in cnt:
				var a := _rng.randf() * TAU
				var r := sqrt(_rng.randf()) * w.w
				var o := Vector3(w.x * _k.x * side + cos(a) * r, 0, w.y * _k.y * side + sin(a) * r)
				out.append(_firefly(o, _rng.randf_range(0.9, 1.6)))
	for p: Vector3 in bank:
		out.append(_firefly(p, _rng.randf_range(1.0, 1.8)))
	while extra > 0:   # rounding leftovers
		extra -= 1
		out.append(_firefly(Vector3(-50.0 * _k.x, 0, -44.0 * _k.y) * (1.0 if extra % 2 == 0 else -1.0), 2.0))


func _firefly(o: Vector3, radius: float) -> Dictionary:
	return {"origin": o, "yaw": 0.0, "scale": _rng.randf_range(0.85, 1.2),
		"custom": Color(_rng.randf(), 0, radius, 0)}


func _build_dragonflies(out: Array, spots: Array) -> void:
	for e: Dictionary in spots:
		var p: Vector3 = e["pos"]
		var moat: bool = e["moat"]
		out.append({"origin": Vector3(p.x, WATER_Y, p.z), "yaw": float(e["yaw"]), "scale": _rng.randf_range(1.25, 1.4),
			"custom": Color(_rng.randf(), float(_rng.randi_range(0, 1)), _rng.randf_range(2.0, 3.5) if not moat else 1.8,
				0.9 if not moat else 0.5), "home": Vector3(p.x, 0, p.z)})


func _build_frogs(out: Array, spots: Array) -> void:
	for e: Dictionary in spots:
		var bank: Vector3 = e["bank"]
		var water: Vector3 = e["water"]
		var d := water - bank
		var yaw := atan2(d.x, d.z)
		out.append({"origin": bank, "yaw": yaw, "scale": _rng.randf_range(1.25, 1.45),
			"custom": Color(_clock - _rng.randf() * 8.0, 0, 0, 0)})
		_frogs.append({"i": -1, "bank": bank, "water": water, "state": FROG_SIT, "t": 0.0, "threat": -100.0})


# ---------------------------------------------------------------- water

## The river as GroundParams uniforms ({} = no water critters on this level).
func _water_model() -> Dictionary:
	if not ResourceLoader.exists(GROUND_PARAMS_PATH):
		return {}
	var river := _river()
	if river and river.has_method(&"shader_params"):
		var p: Variant = river.call(&"shader_params")
		if p is Dictionary and not (p as Dictionary).is_empty():
			return p
	if is_instance_valid(level) and &"river_enabled" in level and bool(level.get(&"river_enabled")):
		var gp := load(GROUND_PARAMS_PATH) as GDScript
		return gp.call(&"skirmish_river")
	return {}


func _river() -> Node:
	return get_tree().get_first_node_in_group(&"river") if is_inside_tree() else null


## Sampled spots on the north half (z < 0), point-mirrored: {dragonflies: [{pos, yaw, moat}], frogs: [{bank, water}],
## fireflies: PackedVector3Array, fish: PackedVector3Array}.
func _water_spots(params: Dictionary) -> Dictionary:
	var gp := load(GROUND_PARAMS_PATH) as GDScript
	var river := _river()
	var bridges: Array[Vector2] = []
	if river and river.has_method(&"crossings"):
		for c: Variant in river.call(&"crossings"):
			if c is Dictionary and String((c as Dictionary).get("kind", "")).begins_with("bridge"):
				var cc: Vector3 = (c as Dictionary).get("center", Vector3.ZERO)
				bridges.append(Vector2(cc.x, cc.z))
	if bridges.is_empty():
		bridges = BRIDGES_FALLBACK.duplicate()
	var fords := PackedVector4Array(params.get(&"fords", PackedVector4Array()))
	var half_w: float = params.get(&"river_half_width", 2.5)
	var moat: Vector4 = params.get(&"moat", Vector4.ZERO)
	# Centre-line samples: {p: Vector2, t: Vector2 (downstream / round), hw: float, moat: bool}.
	var cands: Array[Dictionary] = []
	var segs := PackedVector4Array(params.get(&"river_segs", PackedVector4Array()))
	for si: int in mini(int(params.get(&"river_count", 0)), segs.size()):
		var s: Vector4 = segs[si]
		var a := Vector2(s.x, s.y)
		var b := Vector2(s.z, s.w)
		var steps := maxi(int(a.distance_to(b) / 1.5), 1)
		for k: int in steps:
			cands.append({"p": a.lerp(b, (float(k) + 0.5) / float(steps)), "t": (b - a).normalized(), "hw": half_w,
				"moat": false})
	if moat.z > 0.0:
		for k: int in 60:
			var ang := TAU * float(k) / 60.0
			var dir := Vector2(cos(ang), sin(ang))
			cands.append({"p": Vector2(moat.x, moat.y) + dir * moat.z, "t": Vector2(-dir.y, dir.x), "hw": moat.w,
				"moat": true})
	var ok_water := func(p: Vector2) -> bool:
		if absf(p.x) > _limit or absf(p.y) > _limit:
			return false
		for f: Vector4 in fords:
			if f.z > 0.0 and p.distance_to(Vector2(f.x, f.y)) < f.z + 1.2:
				return false
		for bc: Vector2 in bridges:
			if p.distance_to(bc) < BRIDGE_CLEAR:
				return false
		if float(gp.call(&"water_distance", params, p)) > -0.8:
			return false
		if river and river.has_method(&"is_water") and not bool(river.call(&"is_water", Vector3(p.x, 0, p.y))):
			return false
		return true
	var ok_bank := func(p: Vector2, lo: float, hi: float) -> bool:
		if absf(p.x) > _limit or absf(p.y) > _limit:
			return false
		var wd := float(gp.call(&"water_distance", params, p))
		if wd < lo or wd > hi:
			return false
		for f: Vector4 in fords:
			if f.z > 0.0 and p.distance_to(Vector2(f.x, f.y)) < f.z + 1.0:
				return false
		for bc: Vector2 in bridges:
			if p.distance_to(bc) < BRIDGE_CLEAR:
				return false
		if river and river.has_method(&"is_water") and bool(river.call(&"is_water", Vector3(p.x, 0, p.y))):
			return false
		return not _blocked(Vector3(p.x, 0, p.y), 0.4)
	var fish := PackedVector3Array()
	var north: Array[Dictionary] = []
	for c: Dictionary in cands:
		var p: Vector2 = c["p"]
		if ok_water.call(p):
			fish.append(Vector3(p.x, WATER_Y, p.y))
			if p.y < -0.5:
				north.append(c)
	# Shuffle deterministically.
	for i: int in range(north.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp := north[i]
		north[i] = north[j]
		north[j] = tmp
	var mirror := func(p: Vector2) -> bool: return bool(ok_water.call(-p))
	# Dragonflies: the river first (4), then the moat, 5.5 m apart; whatever is left over the other.
	var dfly: Array[Dictionary] = []
	var used: Array[Vector2] = []
	for pass_i: int in 3:
		var want_moat := pass_i == 1
		for c: Dictionary in north:
			if dfly.size() >= DRAGONFLIES_HALF or (pass_i == 0 and dfly.size() >= 4):
				break
			if pass_i < 2 and bool(c["moat"]) != want_moat:
				continue
			var p: Vector2 = c["p"]
			if not bool(mirror.call(p)) or _near_any(p, used, 5.5):
				continue
			used.append(p)
			var t: Vector2 = c["t"]
			dfly.append({"pos": Vector3(p.x, 0, p.y), "yaw": atan2(t.x, t.y), "moat": bool(c["moat"])})
	var n_df := dfly.size()
	for i: int in n_df:
		var e: Dictionary = dfly[i]
		dfly.append({"pos": -(e["pos"] as Vector3), "yaw": float(e["yaw"]) + PI, "moat": e["moat"]})
	# Frogs (5 per half) and bank fireflies (6 per half), river banks first, 6 / 5 m apart.
	var frogs: Array[Dictionary] = []
	var ffl := PackedVector3Array()
	var used_f: Array[Vector2] = []
	var used_b: Array[Vector2] = []
	for c: Dictionary in north:
		var p: Vector2 = c["p"]
		var t: Vector2 = c["t"]
		var hw: float = c["hw"]
		var nrm := Vector2(-t.y, t.x)
		for sd: float in [1.0, -1.0]:
			var bank := p + nrm * sd * (hw + 0.75)
			var wpt := p + nrm * sd * (hw - 1.2)
			if frogs.size() < FROGS_HALF and not _near_any(bank, used_f, 6.0) and bool(ok_bank.call(bank, 0.3, 1.5)) \
					and bool(ok_bank.call(-bank, 0.3, 1.5)) and bool(ok_water.call(wpt)) and bool(ok_water.call(-wpt)):
				used_f.append(bank)
				frogs.append({"bank": Vector3(bank.x, 0, bank.y), "water": Vector3(wpt.x, 0, wpt.y)})
				break
			var far := p + nrm * sd * (hw + 2.6)
			if ffl.size() < FIREFLIES_BANK_HALF and not bool(c["moat"]) and not _near_any(far, used_b, 5.0) \
					and bool(ok_bank.call(far, 1.5, 4.0)) and bool(ok_bank.call(-far, 1.5, 4.0)):
				used_b.append(far)
				ffl.append(Vector3(far.x, 0, far.y))
	var n_fr := frogs.size()
	for i: int in n_fr:
		frogs.append({"bank": -(frogs[i]["bank"] as Vector3), "water": -(frogs[i]["water"] as Vector3)})
	var n_ff := ffl.size()
	for i: int in n_ff:
		ffl.append(-ffl[i])
	return {"dragonflies": dfly, "frogs": frogs, "fireflies": ffl, "fish": fish}


func _near_any(p: Vector2, list: Array[Vector2], dist: float) -> bool:
	for q: Vector2 in list:
		if p.distance_to(q) < dist:
			return true
	return false


# ---------------------------------------------------------------- spots

## True if a prop (tree, rock, landmark: a world collider above the ground) or a building stands at `p` (within r).
func _blocked(p: Vector3, r: float) -> bool:
	if not is_inside_tree():
		return false
	for b: Node in get_tree().get_nodes_in_group(&"buildings"):
		var n := b as Node3D
		if n and Vector2(n.global_position.x - p.x, n.global_position.z - p.z).length() < r + 3.0:
			return true
	var space := get_world_3d().direct_space_state if get_world_3d() else null
	if space == null:
		return false
	for o: Vector3 in [Vector3.ZERO, Vector3(r, 0, 0), Vector3(-r, 0, 0), Vector3(0, 0, r), Vector3(0, 0, -r)]:
		var q := PhysicsRayQueryParameters3D.create(p + o + Vector3(0, 4.0, 0), p + o + Vector3(0, -1.0, 0), 1)
		var hit := space.intersect_ray(q)
		if not hit.is_empty() and (hit["position"] as Vector3).y > 0.12:
			return true
	return false


## `p` or the nearest free point on a small spiral around it.
func _free_spot(p: Vector3, r: float) -> Vector3:
	if not _blocked(p, r) and not _wet(p):
		return p
	for k: int in 24:
		var a := float(k) * 2.4
		var q := p + Vector3(cos(a), 0, sin(a)) * (1.5 + float(k) * 0.5)
		if not _blocked(q, r) and not _wet(q):
			return q
	return p


## True when `p` is in the river / moat (a stretched Crown Hollow spot can land in another map's water).
func _wet(p: Vector3) -> bool:
	var river := _river()
	return river != null and river.has_method(&"is_water") and bool(river.call(&"is_water", p))


# ---------------------------------------------------------------- instances

const _PARKED := Transform3D(Basis(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO), Vector3(0, -200, 0))


func _write(i: int) -> void:
	var mm := _mm[_kind[i]]
	if mm == null:
		return
	var slot := _slot[i]
	if _shown[i] == 0:
		mm.set_instance_transform(slot, _PARKED)
		return
	mm.set_instance_transform(slot, Transform3D(Basis(Vector3.UP, _yaw[i]).scaled(Vector3.ONE * _scale[i]), _origin[i]))
	mm.set_instance_custom_data(slot, _custom[i])


## Where the CPU places critter i (the shader's own formula for flying birds).
func _cpu_pos(i: int) -> Vector3:
	if _kind[i] != Kind.BIRD:
		return _home[i]
	var c := _custom[i]
	if c.g < 0.5:
		return _origin[i]
	var tau := maxf(_clock - c.r, 0.0)
	var o := _origin[i]
	if c.g < 99.5:
		var h := c.g - 1.0
		var r := maxf(absf(c.a), 0.5)
		var dir := -1.0 if c.a < 0.0 else 1.0
		var dist := BIRD_FLY_SPEED * tau * tau / (2.0 * BIRD_ACCEL_TIME) if tau < BIRD_ACCEL_TIME \
				else BIRD_FLY_SPEED * (tau - BIRD_ACCEL_TIME * 0.5)
		var ang := c.b + dir * dist / r
		var rise := smoothstep(0.0, 1.0, tau / BIRD_RISE_TIME)
		var bob := sin(_clock * 1.3 + float(_slot[i]) * 1.7) * 0.35 * rise
		return o + Vector3(cos(ang) * r, h * rise + bob, sin(ang) * r)
	var y0 := c.g - 100.0
	var d := Vector2(c.b, c.a)
	var e := clampf(tau / _land_time(d), 0.0, 1.0)
	var ex := e * (2.0 - e)
	return o + Vector3(d.x * (1.0 - ex), y0 * (1.0 - e) * (1.0 - e), d.y * (1.0 - ex))


func _land_time(d: Vector2) -> float:
	return clampf(2.0 * d.length() / BIRD_FLY_SPEED, 1.6, 5.0)


func _state_name(i: int) -> StringName:
	match _kind[i]:
		Kind.BIRD:
			var c := _custom[i]
			return &"ground" if c.g < 0.5 else (&"fly" if c.g < 99.5 else &"land")
		Kind.FROG:
			for fr: Dictionary in _frogs:
				if int(fr["i"]) == i:
					return [&"sit", &"jump", &"under", &"return"][int(fr["state"])]
		Kind.SPLASH:
			return &"active" if _splash_end[_slot[i]] > _clock else &"idle"
	return &"idle"


# ---------------------------------------------------------------- visibility (range, fog, cap)

func _camera_focus() -> Vector3:
	if _focus_override != null:
		return _focus_override
	var vp := get_viewport()
	var cam := vp.get_camera_3d() if vp else null
	if cam == null:
		return _focus
	var o := cam.global_position
	var d := -cam.global_transform.basis.z
	if d.y < -0.05:
		return o + d * (-o.y / d.y)
	return Vector3(o.x, 0, o.z)


func _allowed(i: int) -> bool:
	if _kind[i] == Kind.FROG:
		var fr: Dictionary = _frogs[i - _kind_first[Kind.FROG]]
		return int(fr["state"]) != FROG_UNDER
	return true


func _update_visibility() -> void:
	if _n == 0:
		return
	var fog_on := is_instance_valid(_fog) and _fog.enabled
	var team: int = _fog.local_team if fog_on else 0
	var f := _focus
	var r2 := ANIM_RANGE * ANIM_RANGE
	var bins := PackedInt32Array()
	bins.resize(10)
	bins.fill(0)
	var cand := 0
	var splash_on := 0
	for i: int in _n:
		var k := _kind[i]
		if k == Kind.SPLASH:
			splash_on += _shown[i]
			_d2[i] = -1.0
			continue
		if not _allowed(i):
			_d2[i] = -1.0
			continue
		var p := _cpu_pos(i)
		var dx := p.x - f.x
		var dz := p.z - f.z
		var d2 := dx * dx + dz * dz
		if d2 > r2 or (fog_on and not _fog.is_visible(team, p)):
			_d2[i] = -1.0
			continue
		_d2[i] = d2
		var b := mini(int(sqrt(d2) / 5.0), 9)
		_bin[i] = b
		bins[b] += 1
		cand += 1
	var cap := MAX_ANIMATED - splash_on
	var cut_bin := 10
	var partial := 0
	if cand > cap:
		var cum := 0
		for b: int in 10:
			if cum + bins[b] > cap:
				cut_bin = b
				partial = cap - cum
				break
			cum += bins[b]
	for i: int in _n:
		if _kind[i] == Kind.SPLASH:
			continue
		var show := false
		if _d2[i] >= 0.0:
			var b := int(_bin[i])
			if b < cut_bin:
				show = true
			elif b == cut_bin and partial > 0:
				show = true
				partial -= 1
		if show != (_shown[i] != 0):
			_shown[i] = 1 if show else 0
			_write(i)


# ---------------------------------------------------------------- birds

func _flock_ref(fl: Dictionary) -> Vector3:
	return _spots[int(fl["spot"])] if int(fl["state"]) == FLOCK_GROUND else (fl["centre"] as Vector3)


func _flock_active(fl: Dictionary) -> bool:
	var p := _flock_ref(fl)
	return Vector2(p.x - _focus.x, p.z - _focus.z).length() <= ANIM_RANGE + 15.0


func _flock_shown(fl: Dictionary) -> bool:
	for i: int in fl["members"]:
		if _shown[i] != 0:
			return true
	return false


func _update_flocks() -> void:
	for fl: Dictionary in _flocks:
		var state := int(fl["state"])
		var active := _flock_active(fl)
		if state == FLOCK_GROUND:
			if active and _clock >= float(fl["next_idle"]):
				_take_off(fl, null)
			elif not active:
				fl["next_idle"] = maxf(float(fl["next_idle"]), _clock + 10.0)
			continue
		if not active:
			_settle(fl)
			continue
		var members: PackedInt32Array = fl["members"]
		var sw: PackedFloat32Array = fl["switch_at"]
		if state == FLOCK_FLY:
			if _clock < float(fl["land_at"]):
				continue
			var all_gliding := true
			for j: int in members.size():
				var i := members[j]
				if _custom[i].g < 99.5:
					if _clock >= sw[j]:
						_begin_glide(fl, j)
					else:
						all_gliding = false
			if all_gliding:
				fl["state"] = FLOCK_LAND
		else:
			var all_down := true
			for j: int in members.size():
				var i := members[j]
				var c := _custom[i]
				if c.g < 0.5:
					continue
				if _clock - c.r >= _land_time(Vector2(c.b, c.a)) + 0.05:
					_origin[i] = _spots[int(fl["target"])] + _spot_offsets[int(fl["target"])][j]
					_custom[i] = Color(_clock, 0, 0, 0)
					if _shown[i] != 0:
						_write(i)
				else:
					all_down = false
			if all_down:
				fl["state"] = FLOCK_GROUND
				fl["spot"] = fl["target"]
				fl["next_idle"] = _clock + _rng.randf_range(BIRD_IDLE_FLIGHT.x, BIRD_IDLE_FLIGHT.y)


## The flock takes off (threat = the scaring unit's position, or null for a spontaneous move) toward another spot.
func _take_off(fl: Dictionary, threat: Variant) -> void:
	var from: int = fl["spot"]
	var to := _pick_landing(fl, threat)
	if to < 0:
		fl["next_idle"] = _clock + 10.0
		return
	var a := _spots[from]
	var b := _spots[to]
	var centre := (a + b) * 0.5
	centre.y = 0.0
	var dir := 1.0 if _rng.randf() < 0.5 else -1.0
	var base_h := _rng.randf_range(BIRD_HEIGHT.x, BIRD_HEIGHT.y - 1.5)
	var members: PackedInt32Array = fl["members"]
	var sw := PackedFloat32Array()
	var heights := PackedFloat32Array()
	var r_mean := 0.0
	for j: int in members.size():
		var i := members[j]
		var p := _origin[i]
		var off := Vector2(p.x - centre.x, p.z - centre.z)
		var r := maxf(off.length(), 3.0)
		r_mean += r
		var h := clampf(base_h + _rng.randf_range(0.0, 1.5), BIRD_HEIGHT.x, BIRD_HEIGHT.y)
		heights.append(h)
		_custom[i] = Color(_clock + float(j) * 0.07 + _rng.randf() * 0.05, 1.0 + h, atan2(off.y, off.x), dir * r)
		_origin[i] = centre
		if _shown[i] != 0:
			_write(i)
	r_mean /= float(maxi(members.size(), 1))
	# Circle for about half a turn (the far side is near the new spot), within 6-10 s.
	var t_fly := clampf(PI * r_mean / BIRD_FLY_SPEED + 0.6, BIRD_CIRCLE_TIME.x, BIRD_CIRCLE_TIME.y) \
			+ _rng.randf_range(-0.4, 0.4)
	fl["land_at"] = _clock + clampf(t_fly, BIRD_CIRCLE_TIME.x, BIRD_CIRCLE_TIME.y)
	for j: int in members.size():
		sw.append(float(fl["land_at"]) + float(j) * 0.12 + _rng.randf() * 0.1)
	fl["switch_at"] = sw
	fl["heights"] = heights
	fl["state"] = FLOCK_FLY
	fl["target"] = to
	fl["centre"] = centre


func _begin_glide(fl: Dictionary, j: int) -> void:
	var i: int = (fl["members"] as PackedInt32Array)[j]
	var p := _cpu_pos(i)
	var to: int = fl["target"]
	var b := _spots[to] + _spot_offsets[to][j]
	var d := Vector2(p.x - b.x, p.z - b.z)
	_custom[i] = Color(_clock, 100.0 + maxf(p.y, 0.1), d.x, d.y)
	_origin[i] = Vector3(b.x, 0, b.z)
	_yaw[i] = atan2(-d.x, -d.y)
	if _shown[i] != 0:
		_write(i)


## Out of camera range mid-flight: everyone is simply on the ground at the target spot.
func _settle(fl: Dictionary) -> void:
	var to: int = fl["target"]
	var members: PackedInt32Array = fl["members"]
	for j: int in members.size():
		var i := members[j]
		_origin[i] = _spots[to] + _spot_offsets[to][j]
		_custom[i] = Color(_clock, 0, 0, 0)
		if _shown[i] != 0:
			_write(i)
	fl["state"] = FLOCK_GROUND
	fl["spot"] = to
	fl["next_idle"] = _clock + _rng.randf_range(BIRD_IDLE_FLIGHT.x, BIRD_IDLE_FLIGHT.y)


func _pick_landing(fl: Dictionary, threat: Variant) -> int:
	var from: int = fl["spot"]
	var busy := {}
	for o: Dictionary in _flocks:
		if o != fl:
			busy[int(o["spot"])] = true
			busy[int(o["target"])] = true
	var best := -1
	var best_score := -INF
	var a := _spots[from]
	for s: int in _spots.size():
		if s == from or busy.has(s):
			continue
		var d := Vector2(_spots[s].x - a.x, _spots[s].z - a.z).length()
		if d < 12.0 or d > 45.0:
			continue
		if _has_building(_spots[s], 4.0):
			continue
		var score := _rng.randf() * 10.0
		if threat != null:
			var t: Vector3 = threat
			score += Vector2(_spots[s].x - t.x, _spots[s].z - t.z).length()
		if score > best_score:
			best_score = score
			best = s
	if best < 0:   # nothing in 12-45 m: the nearest free spot
		var best_d := INF
		for s: int in _spots.size():
			if s == from or busy.has(s):
				continue
			var d := a.distance_to(_spots[s])
			if d < best_d:
				best_d = d
				best = s
	return best


func _has_building(p: Vector3, r: float) -> bool:
	for b: Node in get_tree().get_nodes_in_group(&"buildings"):
		var n := b as Node3D
		if n and Vector2(n.global_position.x - p.x, n.global_position.z - p.z).length() < r + 2.0:
			return true
	return false


# ---------------------------------------------------------------- frogs and splashes

func _update_frogs() -> void:
	for fr: Dictionary in _frogs:
		var i: int = fr["i"]
		var st := int(fr["state"])
		var t: float = fr["t"]
		if st == FROG_JUMP and _clock >= t + FROG_JUMP_END:
			fr["state"] = FROG_UNDER
			fr["t"] = _clock
			if _shown[i] != 0:
				_shown[i] = 0
				_write(i)
		elif st == FROG_UNDER and _clock >= t + FROG_UNDER_TIME and _clock - float(fr["threat"]) > 1.0:
			var bank: Vector3 = fr["bank"]
			var water: Vector3 = fr["water"]
			var d := water - bank
			fr["state"] = FROG_RETURN
			fr["t"] = _clock
			_origin[i] = bank
			_custom[i] = Color(_clock, 2.0, d.x, d.z)
			_spawn_splash(water, atan2(d.x, d.z), 0, _clock + 0.05)
			# Shown again by the next visibility pass (if in range and seen).
		elif st == FROG_RETURN and _clock >= t + FROG_RETURN_TIME:
			var d: Vector3 = (fr["water"] as Vector3) - (fr["bank"] as Vector3)
			fr["state"] = FROG_SIT
			_yaw[i] = atan2(-d.x, -d.z)
			_custom[i] = Color(_clock, 0, 0, 0)
			if _shown[i] != 0:
				_write(i)


func _frog_jump(fr: Dictionary) -> void:
	var i: int = fr["i"]
	var d: Vector3 = (fr["water"] as Vector3) - (fr["bank"] as Vector3)
	fr["state"] = FROG_JUMP
	fr["t"] = _clock
	_custom[i] = Color(_clock, 1.0, d.x, d.z)
	if _shown[i] != 0:
		_write(i)
	_spawn_splash(fr["water"], atan2(d.x, d.z), 0, _clock + 0.12 + 0.55)


## A splash (mode 0 plain, 1 leaping fish) at a water point, from time t0. False when the pool is busy or the point
## is out of camera range / not seen now by the local team.
func _spawn_splash(at: Vector3, yaw: float, mode: int, t0: float) -> bool:
	if _kind_count.size() <= Kind.SPLASH or _kind_count[Kind.SPLASH] == 0:
		return false
	if Vector2(at.x - _focus.x, at.z - _focus.z).length() > ANIM_RANGE:
		return false
	if is_instance_valid(_fog) and _fog.enabled and not _fog.is_visible(_fog.local_team, at):
		return false
	if animated_count() >= MAX_ANIMATED:
		return false
	var first: int = _kind_first[Kind.SPLASH]
	for s: int in _kind_count[Kind.SPLASH]:
		if _splash_end[s] > _clock:
			continue
		var i := first + s
		_origin[i] = Vector3(at.x, WATER_Y, at.z)
		_yaw[i] = yaw
		_scale[i] = _rng.randf_range(0.85, 1.15)
		_custom[i] = Color(t0, float(mode), 0, 0)
		_splash_end[s] = t0 + SPLASH_LIFETIME
		_shown[i] = 1
		_write(i)
		return true
	return false


func _update_splashes() -> void:
	if _kind_count.size() <= Kind.SPLASH or _kind_count[Kind.SPLASH] == 0:
		return
	var first: int = _kind_first[Kind.SPLASH]
	for s: int in _kind_count[Kind.SPLASH]:
		var i := first + s
		if _shown[i] != 0 and _clock >= _splash_end[s]:
			_shown[i] = 0
			_write(i)
	if _clock < _next_fish:
		return
	_next_fish = _clock + _rng.randf_range(FISH_INTERVAL.x, FISH_INTERVAL.y)
	if _fish_spots.is_empty() or animated_count() >= MAX_ANIMATED:
		return
	var fog_on := is_instance_valid(_fog) and _fog.enabled
	for k: int in 10:
		var p := _fish_spots[_rng.randi_range(0, _fish_spots.size() - 1)]
		if Vector2(p.x - _focus.x, p.z - _focus.z).length() > FISH_VIEW_RANGE:
			continue
		if fog_on and not _fog.is_visible(_fog.local_team, p):
			continue
		_spawn_splash(p, _rng.randf() * TAU, 1, _clock)
		return


# ---------------------------------------------------------------- reactions (visible units nearby)

func _react() -> void:
	_t_pos.clear()
	_t_r2.clear()
	_t_ref.clear()
	for f: int in _flocks.size():
		var fl := _flocks[f]
		if int(fl["state"]) == FLOCK_GROUND and _flock_shown(fl):
			var r := BIRD_SCARE + BIRD_SPREAD
			_t_pos.append(_spots[int(fl["spot"])])
			_t_r2.append(r * r)
			_t_ref.append(f)
	for j: int in _frogs.size():
		var fr := _frogs[j]
		var st := int(fr["state"])
		var i: int = fr["i"]
		if (st == FROG_SIT and _shown[i] != 0) or (st == FROG_UNDER and _clock >= float(fr["t"]) + FROG_UNDER_TIME - 1.5):
			_t_pos.append(fr["bank"])
			_t_r2.append(FROG_SCARE * FROG_SCARE)
			_t_ref.append(1000 + j)
	if _t_pos.is_empty():
		return
	for t: int in _t_pos.size():
		var p := _t_pos[t]
		var r := sqrt(_t_r2[t])
		var x0 := clampi(int((p.x - r + _grid_half) / GRID_CELL), 0, _grid_n - 1)
		var x1 := clampi(int((p.x + r + _grid_half) / GRID_CELL), 0, _grid_n - 1)
		var z0 := clampi(int((p.z - r + _grid_half) / GRID_CELL), 0, _grid_n - 1)
		var z1 := clampi(int((p.z + r + _grid_half) / GRID_CELL), 0, _grid_n - 1)
		for z: int in range(z0, z1 + 1):
			for x: int in range(x0, x1 + 1):
				var c := x + z * _grid_n
				if _mask[c] == 0:
					_mask[c] = 1
					_marked.append(c)
	for node: Node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Node3D
		if u == null or not u.visible:
			continue   # hidden by the fog for the local team (own units are always visible)
		var p := u.global_position
		var cx := int((p.x + _grid_half) / GRID_CELL)
		var cz := int((p.z + _grid_half) / GRID_CELL)
		if cx < 0 or cx >= _grid_n or cz < 0 or cz >= _grid_n or _mask[cx + cz * _grid_n] == 0:
			continue
		if u.has_method(&"is_alive") and not bool(u.call(&"is_alive")):
			continue
		for t: int in _t_pos.size():
			var q := _t_pos[t]
			var dx := p.x - q.x
			var dz := p.z - q.z
			if dx * dx + dz * dz > _t_r2[t]:
				continue
			var ref := _t_ref[t]
			if ref < 1000:
				var fl := _flocks[ref]
				if int(fl["state"]) == FLOCK_GROUND:
					_take_off(fl, p)
			else:
				var fr := _frogs[ref - 1000]
				fr["threat"] = _clock
				if int(fr["state"]) == FROG_SIT:
					_frog_jump(fr)
	for c: int in _marked:
		_mask[c] = 0
	_marked.clear()
