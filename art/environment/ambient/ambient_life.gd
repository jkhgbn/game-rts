class_name AmbientLife
extends Node3D
## G-D ambient life (docs/art/gd_ambient.md): the world feels alive at zoom 30-40 without clutter. Draw-only
## scenery: no collider, no click, never in "units", never read by gameplay. One per level (group "ambient_life"):
## `AmbientLife.ensure(level)` (main.gd hook, see docs/handoff/for-lead.md).
## - High flocks: small flocks of birds circling / crossing 10-17 m up (one MultiMesh, motion in ambient_birds.gdshader);
##   they scatter (climb away fast) when a fight or an army (8+ units) the LOCAL player can see is under them. Hidden
##   units never scare them (units are read through is_visible_in_tree(), the fog hides unseen enemies), so a flock
##   taking off never betrays an army in the fog. None at night.
## - Seven camera-following GPUParticles3D for the whole map (never per tile / unit), world-space particles spawned
##   only from emission points within VIEW_RADIUS of the camera focus that the local player has explored (refreshed
##   when the camera moves): Wings (butterflies by day, moths at night), Motes (pollen and sunlit glints by day,
##   fireflies at night), Leaves (falling from the tree crowns; autumn colours and more on autumn maps), Dust (puffs
##   blown along roads / heath in wind gusts), Mist (night and marsh), Ripples (rings on the water), Snow (snow maps /
##   the ice preset; a box over the view). Transparent ones also fade with the fog textures in the shader.
## - Mood (every MOOD_TIME s): night from the lighting rig's sun (a mission turning to night switches the set), snow
##   from the ice preset or a snow biome, autumn / marsh from the layout's biome. Amounts per mood are amount_ratio
##   changes (no particle restart).
## Tiers (GameSettings.effective_graphics_quality(), load-guarded): Low = no node at all (ensure returns null; a node
## switched to Low frees everything), Medium = one flock and a few particles, High / Ultra = the full set (CAPS).
## Never built headless (ensure returns null) unless a test sets `allow_headless`.

const GROUP := &"ambient_life"
const RIG_GROUP := &"lighting_rigs"
const GAME_SETTINGS_PATH := "res://scripts/ui/menus/game_settings.gd"
const DIR := "res://art/environment/ambient/"
const BIRD_MESH := "res://art/environment/critters/meshes/critter_bird.res"
const BUTTERFLY_MESH := "res://art/environment/critters/meshes/critter_butterfly.res"
const CRITTER_MESHES := "res://art/environment/critters/critter_meshes.gd"
const GROUND_SHADER := "res://art/environment/ground.gdshader"
const WATER_Y := -0.35

const EMITTERS: Array[StringName] = [&"wings", &"motes", &"leaves", &"dust", &"mist", &"ripples", &"snow"]
## Particle caps per tier [Low, Medium, High, Ultra] (the GPUParticles3D `amount`; the mood scales amount_ratio).
const CAPS := {
	&"wings": [0, 8, 20, 28],
	&"motes": [0, 24, 70, 110],
	&"leaves": [0, 10, 30, 44],
	&"dust": [0, 0, 22, 32],
	&"mist": [0, 0, 16, 24],
	&"ripples": [0, 6, 14, 20],
	&"snow": [0, 220, 520, 800],
}
const FLOCKS: Array[int] = [0, 1, 3, 4]
const BIRDS_PER_FLOCK := 7
const MAX_PARTICLES := 1100         ## hard cap of every emitter together at Ultra (test_gd_ambient checks CAPS)

const VIEW_RADIUS := 34.0           ## emission points within this of the camera focus
const REFRESH_MOVE := 6.0           ## re-pick the emission points when the focus moved this far...
const REFRESH_TIME := 2.0           ## ...or this often (the explored area grows)
const REFRESH_MIN := 0.5            ## never more often than this while the camera pans
const MOOD_TIME := 2.0
const LOGIC_TIME := 0.5             ## flock plans / scatter scan (alternating)
const GUST_TICK := 0.1
const MAX_POINTS := 160             ## emission points per emitter (texture width)
const GRID_STEP := 3.0              ## candidate spacing (m)
const CELL := 12.0                  ## candidate buckets (m)
const BUILD_ROWS_PER_FRAME := 6     ## candidate rows classified per frame (no load hitch on big maps)
const WIND := Vector2(0.8, 0.6)     ## same as grass_blades.gdshader wind_dir

const BIRD_ALT := Vector2(10.0, 16.0)
const BIRD_RADIUS := Vector2(8.0, 14.0)
const BIRD_SPEED := 5.5             ## m/s along the circle
const BIRD_SCALE := Vector2(1.25, 1.55)
const FLOCK_LEAVE := 62.0           ## a flock this far from the focus re-enters from off screen
const FLOCK_ENTER := 78.0
const SCARE_RADIUS := 18.0
const SCARE_ARMY := 8
const SCARE_COOLDOWN := 12.0
const SCATTER_TIME := 5.5
const SCATTER_DIST := 55.0

## Tests / tools: >= 0 beats the settings (0 Low .. 3 Ultra).
static var quality_override := -1
## Tests: build in a headless run too (GPUParticles3D exist, nothing is drawn).
static var allow_headless := false


class Flock:
	var a := Vector3.ZERO          # path start (x, base altitude, z)
	var b := Vector2.ZERO          # path end (x, z)
	var t0 := 0.0
	var dur := 0.01
	var radius := 10.0
	var phase := 0.0
	var omega := 0.5               # rad/s (signed)
	var omega_base := 0.5
	var climb := 0.0
	var palette := 0
	var next_t := 0.0
	var calm_t := 0.0
	var scatters := 0


var quality := -1
var _pending_quality := -1          # a tier asked before the build was ready (applied by _start)
var scatter_count := 0              ## flocks scattered so far (tests)
var _level: Node = null
var _ready_to_build := false
var _building := false
var _cand := {}                     # set name -> {Vector2i cell: PackedVector3Array}
var _trees := PackedVector4Array()  # (x, z, crown top y, crown radius)
var _tree_cells := {}               # Vector2i -> PackedInt32Array of _trees indices
var _em := {}                       # emitter id -> GPUParticles3D
var _pm := {}                       # emitter id -> ParticleProcessMaterial
var _img := {}                      # emitter id -> Image (RGBF, MAX_POINTS x 1)
var _tex := {}                      # emitter id -> ImageTexture
var _npts := {}                     # emitter id -> points used
var _ratio := {}                    # emitter id -> mood amount ratio
var _soft := {}                     # look -> ShaderMaterial (snow, dust, mist, ripples)
var _glow: ShaderMaterial = null
var _wing_mat: ShaderMaterial = null
var _leaf_mat: ShaderMaterial = null
var _birds: MultiMeshInstance3D = null
var _bird_mat: ShaderMaterial = null
var _flocks: Array[Flock] = []
var _mood := {}
var _clock := 0.0
var _focus := Vector3.ZERO
var _cam_pos := Vector3(0.0, 30.0, 20.0)
var _last_refresh_focus := Vector3(INF, 0.0, INF)
var _refresh_t := 0.0
var _mood_t := 0.0
var _logic_t := 0.0
var _logic_phase := 0
var _gust_t := 0.0
var _gust_clock := 0.0
var _gust_next := 3.0
var _fog: Node = null
var _fog_q: Node = null             # the fog points are tested against during one refresh (null = fog off)
var _fog_typed: FogOfWar = null
var _fog_team := 0
var _refresh_cool := 0.0
var _rng := RandomNumberGenerator.new()
var _build_ms := 0.0

## Tests: a fixed focus instead of the camera's (null = the camera).
var focus_override: Variant = null


## The level's AmbientLife, created (as a child of `level`) when it has none. Null at Low, headless, or no level.
static func ensure(level: Node) -> AmbientLife:
	if level == null or not level.is_inside_tree():
		return null
	for n in level.get_tree().get_nodes_in_group(GROUP):
		if is_instance_valid(n) and level.is_ancestor_of(n):
			return n as AmbientLife
	if DisplayServer.get_name() == "headless" and not allow_headless:
		return null
	if settings_quality() <= 0:
		return null
	var al := AmbientLife.new()
	al.name = "AmbientLife"
	level.add_child(al)
	return al


## The tier the settings ask for (load-guarded): --gfx, else Low in quiet runs, else the saved setting.
static func settings_quality() -> int:
	if quality_override >= 0:
		return clampi(quality_override, 0, 3)
	if not ResourceLoader.exists(GAME_SETTINGS_PATH):
		return 2
	var gs := load(GAME_SETTINGS_PATH) as Script
	if gs == null:
		return 2
	if gs.has_method(&"effective_graphics_quality"):
		return clampi(int(gs.call(&"effective_graphics_quality")), 0, 3)
	var v: Variant = gs.get(&"graphics_quality")
	return clampi(int(v), 0, 3) if v != null else 2


## The mood from what the level shows: night (a weak, cold sun), snow (ice preset / snow biome), autumn, marsh.
static func mood_from(sun_energy: float, sun_color: Color, preset_id: StringName, biome: String,
		preset_path: String = "") -> Dictionary:
	var night := sun_energy < 0.85 and sun_color.b > sun_color.r
	var b := biome.to_lower()
	return {
		"night": night,
		"snow": preset_id == &"ice" or b.contains("snow") or b.contains("frost"),
		"autumn": preset_path.contains("autumn"),
		"autumn_hint": b.contains("autumn"),
		"marsh": b.contains("marsh"),
	}


## Amount ratio (0-1) of each emitter for a mood, plus "birds" (0 or 1).
static func mood_ratios(m: Dictionary) -> Dictionary:
	var night := bool(m.get("night", false))
	var snow := bool(m.get("snow", false))
	var autumn := bool(m.get("autumn", false))
	var marsh := bool(m.get("marsh", false))
	var r := {}
	r[&"wings"] = 0.0 if snow else (0.45 if night else (0.5 if autumn else 1.0))
	r[&"motes"] = (0.0 if night else 0.3) if snow else (1.0 if night else 0.55)
	var hint := bool(m.get("autumn_hint", false))
	r[&"leaves"] = 0.0 if snow else (1.0 if autumn else (0.35 if night else (0.8 if hint else 0.6)))
	r[&"dust"] = 0.0 if snow else (0.3 if night else 1.0)
	r[&"mist"] = 1.0 if night else (0.6 if marsh else (0.35 if snow else 0.0))
	r[&"ripples"] = 0.0 if snow else (1.0 if marsh else 0.8)
	r[&"snow"] = 1.0 if snow else 0.0
	r[&"birds"] = 0.0 if night else 1.0
	return r


## Particles each emitter may show at tier `q` in mood `m` (cap x ratio) and the number of flocks.
static func plan(q: int, m: Dictionary) -> Dictionary:
	q = clampi(q, 0, 3)
	var r := mood_ratios(m)
	var out := {}
	for id: StringName in EMITTERS:
		out[id] = int(round(float((CAPS[id] as Array)[q]) * float(r[id])))
	out[&"flocks"] = FLOCKS[q] if float(r[&"birds"]) > 0.0 else 0
	return out


## Where a flock's circle centre is at time t (mirror of ambient_birds.gdshader flock_centre).
static func flock_centre(a: Vector3, b: Vector2, t0: float, dur: float, t: float) -> Vector2:
	var u := clampf((t - t0) / maxf(dur, 0.01), 0.0, 1.0)
	return Vector2(a.x, a.z).lerp(b, u * u * (3.0 - 2.0 * u))


func _ready() -> void:
	add_to_group(GROUP)
	add_to_group(RIG_GROUP)
	_level = get_parent()
	_rng.seed = 7311
	set_process(false)
	_start.call_deferred()


func _start() -> void:
	# Wait until the level has its ground uniforms, trees and river (written while the map builds).
	for i in 3:
		await get_tree().process_frame
	if not is_inside_tree():
		return
	await _build_candidates()
	if not is_inside_tree():
		return
	_ready_to_build = true
	set_quality(_pending_quality if _pending_quality >= 0 else settings_quality())


## Applies a tier (0 Low .. 3 Ultra). Low frees every child; safe to call any time.
func set_quality(q: int) -> void:
	q = clampi(quality_override if quality_override >= 0 else q, 0, 3)   # tests / tools beat the broadcast
	if not _ready_to_build:
		# The settings broadcast (HUD _ready -> GameSettings.apply_graphics) can come before the candidates exist:
		# keep the tier for _start, never mark it applied.
		_pending_quality = q
		return
	if q == quality:
		return
	quality = q
	_free_all()
	if q <= 0:
		set_process(false)
		return
	_find_fog()
	_update_focus()
	_build_materials()
	for id: StringName in EMITTERS:
		var cap: int = (CAPS[id] as Array)[q]
		if cap > 0:
			_make_emitter(id, cap)
	_make_birds(FLOCKS[q] * BIRDS_PER_FLOCK)
	_mood = {}
	_mood_t = 0.0
	_last_refresh_focus = Vector3(INF, 0.0, INF)
	set_process(true)
	_apply_mood(_read_mood())
	refresh_points()


## Emitter ids built now.
func emitter_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in EMITTERS:
		if _em.has(id):
			out.append(id)
	return out


## One emitter's state: {amount, ratio, points, emitting} ({} when it is not built).
func emitter_info(id: StringName) -> Dictionary:
	if not _em.has(id):
		return {}
	var p := _em[id] as GPUParticles3D
	return {"amount": p.amount, "ratio": p.amount_ratio, "points": int(_npts.get(id, 0)), "emitting": p.emitting}


## The emission points an emitter uses now (world positions).
func emitter_points(id: StringName) -> PackedVector3Array:
	var out := PackedVector3Array()
	if not _img.has(id):
		return out
	var img := _img[id] as Image
	for i in int(_npts.get(id, 0)):
		var c := img.get_pixel(i, 0)
		out.append(Vector3(c.r, c.g, c.b))
	return out


func flock_count() -> int:
	return _flocks.size()


## A flock's plan: {centre: Vector2 now, b, t0, dur, omega, in_transit, scatters}.
func flock_state(i: int) -> Dictionary:
	if i < 0 or i >= _flocks.size():
		return {}
	var f := _flocks[i]
	return {"centre": flock_centre(f.a, f.b, f.t0, f.dur, _clock), "b": f.b, "t0": f.t0, "dur": f.dur,
		"omega": f.omega, "in_transit": _clock < f.t0 + f.dur, "scatters": f.scatters, "alt": f.a.y}


func mood() -> Dictionary:
	return _mood.duplicate()


func candidate_count(set_name: String) -> int:
	var n := 0
	var cells: Dictionary = _cand.get(set_name, {})
	for k: Vector2i in cells:
		n += (cells[k] as PackedVector3Array).size()
	return n


func tree_count() -> int:
	return _trees.size()


func build_msec() -> float:
	return _build_ms


func clock() -> float:
	return _clock


## Tests: runs the flock plan + scatter scan now.
func tick_logic() -> void:
	_flock_plans()
	_scatter_scan()


## Tests: places a flock's centre (at rest) at `xz`.
func put_flock(i: int, xz: Vector2) -> void:
	if i < 0 or i >= _flocks.size():
		return
	var f := _flocks[i]
	f.a = Vector3(xz.x, f.a.y, xz.y)
	f.b = xz
	f.t0 = _clock - 1.0
	f.dur = 0.01
	f.calm_t = 0.0
	f.next_t = _clock + 1000.0
	_write_flock(i)


# ---------------------------------------------------------------- candidates

func _build_candidates() -> void:
	_building = true
	var t0 := Time.get_ticks_usec()
	var spent := 0
	var ground := _find_ground()
	var bm: BiomeMap = BiomeMap.from_ground(ground) if ground else null
	var roads := _roads(ground)
	_collect_trees()
	var hx := MapInfo.half_x() - 2.0
	var hz := MapInfo.half_z() - 2.0
	for set_name: String in ["meadow", "bank", "water", "road", "heath"]:
		_cand[set_name] = {}
	var rows := int(floor(hz * 2.0 / GRID_STEP)) + 1
	var cols := int(floor(hx * 2.0 / GRID_STEP)) + 1
	for j in rows:
		var z := -hz + float(j) * GRID_STEP
		for i in cols:
			var x := -hx + float(i) * GRID_STEP
			var p := Vector2(x, z)
			var set_name := _classify(p, bm, roads)
			if set_name != "":
				var y := WATER_Y if set_name == "water" else 0.0
				_add_cand(set_name, Vector3(x, y, z))
		if j % BUILD_ROWS_PER_FRAME == BUILD_ROWS_PER_FRAME - 1:
			spent += Time.get_ticks_usec() - t0
			await get_tree().process_frame
			if not is_inside_tree():
				return
			t0 = Time.get_ticks_usec()
	spent += Time.get_ticks_usec() - t0
	_build_ms = float(spent) / 1000.0
	_building = false


func _classify(p: Vector2, bm: BiomeMap, roads: PackedVector4Array) -> String:
	var wd := 1e4
	if bm and bm.has_water() and not bm.water_far(p, 5.0):
		wd = bm.water_distance(p)
	if wd < -0.8:
		return "water" if bm.is_cut(p) else ""
	if wd < 0.3:
		return ""
	for s: Vector4 in roads:
		var q := Geometry2D.get_closest_point_to_segment(p, Vector2(s.x, s.y), Vector2(s.z, s.w))
		if p.distance_to(q) < 1.6:
			return "road"
	if wd < 4.5:
		return "bank"
	var biome := &"glade"
	if bm and bm.enabled:
		biome = bm.biome_at(p)
	if biome == &"heath" or biome == &"ruins":
		return "heath"
	if biome == &"old_wood":
		return ""   # the wood's life comes from the tree list (motes round the trunks, leaves from the crowns)
	return "meadow"


func _add_cand(set_name: String, p: Vector3) -> void:
	var cells: Dictionary = _cand[set_name]
	var c := Vector2i(floori(p.x / CELL), floori(p.z / CELL))
	if not cells.has(c):
		cells[c] = PackedVector3Array()
	var arr: PackedVector3Array = cells[c]
	arr.append(p)
	cells[c] = arr


func _find_ground() -> ShaderMaterial:
	if _level == null:
		return null
	for mi: Node in _level.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var sm := m.material_override as ShaderMaterial
		if sm and sm.shader and sm.shader.resource_path == GROUND_SHADER and m.mesh is PlaneMesh:
			return sm
	return null


func _roads(ground: ShaderMaterial) -> PackedVector4Array:
	var out := PackedVector4Array()
	if ground == null:
		return out
	var n_v: Variant = ground.get_shader_parameter(&"road_count")
	var segs: Variant = ground.get_shader_parameter(&"road_segs")
	var n := int(n_v) if n_v != null else 0
	if segs is PackedVector4Array:
		var pa := segs as PackedVector4Array
		for i in mini(n, pa.size()):
			out.append(pa[i])
	elif segs is Array:
		var ar := segs as Array
		for i in mini(n, ar.size()):
			if ar[i] is Vector4:
				out.append(ar[i])
	return out


## Every tree the level draws (EnvProps / map dressing MultiMeshes whose mesh or node name says "tree").
func _collect_trees() -> void:
	_trees = PackedVector4Array()
	_tree_cells = {}
	if _level == null:
		return
	for n: Node in _level.find_children("*", "MultiMeshInstance3D", true, false):
		var mmi := n as MultiMeshInstance3D
		if mmi.multimesh == null or mmi.multimesh.mesh == null or mmi.get_parent() == self:
			continue
		var label := (String(mmi.name) + " " + mmi.multimesh.mesh.resource_path).to_lower()
		if not label.contains("tree") and not label.contains("willow") and not label.contains("birch"):
			continue
		var mm := mmi.multimesh
		var aabb := mm.mesh.get_aabb()
		var gx := mmi.global_transform
		for i in mm.instance_count:
			var xf := gx * mm.get_instance_transform(i)
			var s := xf.basis.get_scale()
			if s.y < 0.01:
				continue
			var top := xf.origin.y + aabb.end.y * s.y
			var r := maxf(aabb.size.x, aabb.size.z) * 0.5 * maxf(s.x, s.z)
			var p := xf.origin
			if absf(p.x) > MapInfo.half_x() + 6.0 or absf(p.z) > MapInfo.half_z() + 6.0:
				continue
			var idx := _trees.size()
			_trees.append(Vector4(p.x, p.z, top, clampf(r, 0.6, 4.0)))
			var c := Vector2i(floori(p.x / CELL), floori(p.z / CELL))
			if not _tree_cells.has(c):
				_tree_cells[c] = PackedInt32Array()
			var arr: PackedInt32Array = _tree_cells[c]
			arr.append(idx)
			_tree_cells[c] = arr


# ---------------------------------------------------------------- building

func _free_all() -> void:
	for c in get_children():
		c.queue_free()
	_em.clear()
	_pm.clear()
	_img.clear()
	_tex.clear()
	_npts.clear()
	_ratio.clear()
	_soft.clear()
	_glow = null
	_wing_mat = null
	_leaf_mat = null
	_birds = null
	_bird_mat = null
	_flocks.clear()


func _build_materials() -> void:
	_glow = ShaderMaterial.new()
	_glow.shader = load(DIR + "ambient_glow.gdshader") as Shader
	var soft_shader := load(DIR + "ambient_soft.gdshader") as Shader
	for look: int in 4:
		var m := ShaderMaterial.new()
		m.shader = soft_shader
		m.set_shader_parameter(&"look", look)
		_soft[look] = m
	(_soft[0] as ShaderMaterial).set_shader_parameter(&"strength", 0.85)
	(_soft[1] as ShaderMaterial).set_shader_parameter(&"strength", 0.9)
	(_soft[2] as ShaderMaterial).set_shader_parameter(&"near_fade", 10.0)
	var wing_shader := load(DIR + "ambient_wing.gdshader") as Shader
	_wing_mat = ShaderMaterial.new()
	_wing_mat.shader = wing_shader
	_wing_mat.set_shader_parameter(&"look", 0)
	_leaf_mat = ShaderMaterial.new()
	_leaf_mat.shader = wing_shader
	_leaf_mat.set_shader_parameter(&"look", 1)
	_apply_fog_params()


func _fog_mats() -> Array[ShaderMaterial]:
	var out: Array[ShaderMaterial] = []
	if _glow:
		out.append(_glow)
	for k: int in _soft:
		out.append(_soft[k] as ShaderMaterial)
	return out


func _find_fog() -> void:
	_fog = null
	if _level:
		var f: Variant = _level.get(&"fog")
		if f is Node and is_instance_valid(f):
			_fog = f
	if _fog == null:
		_fog = get_tree().get_first_node_in_group(&"fog")


func _apply_fog_params() -> void:
	var on := 0.0
	var ov: MeshInstance3D = null
	if is_instance_valid(_fog):
		ov = _fog.get_node_or_null(^"FogOverlay") as MeshInstance3D
		on = 1.0 if bool(_fog.get(&"enabled")) else 0.0
	var om := ov.material_override as ShaderMaterial if ov else null
	if om == null:
		on = 0.0
	for m: ShaderMaterial in _fog_mats():
		m.set_shader_parameter(&"fog_on", on)
		if om:
			m.set_shader_parameter(&"fog_vis", om.get_shader_parameter(&"vis_tex"))
			m.set_shader_parameter(&"fog_exp", om.get_shader_parameter(&"exp_tex"))
			m.set_shader_parameter(&"fog_half", om.get_shader_parameter(&"map_half"))


func _make_emitter(id: StringName, cap: int) -> void:
	var p := GPUParticles3D.new()
	p.name = String(id).capitalize()
	p.amount = cap
	p.local_coords = false
	p.emitting = false
	p.fixed_fps = 30
	p.interpolate = true
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	p.set_meta(&"no_ghost", true)
	var pm := ParticleProcessMaterial.new()
	var wind3 := Vector3(WIND.x, 0.0, WIND.y).normalized()
	if id != &"snow":
		var img := Image.create_empty(MAX_POINTS, 1, false, Image.FORMAT_RGBF)
		var tex := ImageTexture.create_from_image(img)
		_img[id] = img
		_tex[id] = tex
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINTS
		pm.emission_point_texture = tex
		pm.emission_point_count = 1
	match id:
		&"wings":
			p.lifetime = 9.0
			pm.direction = Vector3(0.0, 0.2, 0.0)
			pm.spread = 180.0
			pm.initial_velocity_min = 0.3
			pm.initial_velocity_max = 0.8
			pm.gravity = Vector3.ZERO
			_turbulence(pm, 1.4, 3.0, 0.35, 0.55)
			pm.particle_flag_rotate_y = true
			pm.angle_min = 0.0
			pm.angle_max = 360.0
			pm.scale_min = 1.3
			pm.scale_max = 1.7
			pm.scale_curve = _in_out_curve(0.08, 0.1)
			p.draw_pass_1 = _butterfly_mesh()
			p.material_override = _wing_mat
		&"motes":
			p.lifetime = 6.0
			pm.direction = Vector3(0.0, 1.0, 0.0)
			pm.spread = 180.0
			pm.initial_velocity_min = 0.05
			pm.initial_velocity_max = 0.25
			pm.gravity = wind3 * 0.05 + Vector3(0.0, 0.02, 0.0)
			_turbulence(pm, 0.6, 2.5, 0.06, 0.14)
			pm.scale_min = 0.7
			pm.scale_max = 1.3
			pm.color_ramp = _fade_ramp(0.15, 0.25, 1.0)
			var q := QuadMesh.new()
			q.size = Vector2(0.26, 0.26)
			p.draw_pass_1 = q
			p.material_override = _glow
		&"leaves":
			p.lifetime = 7.0
			pm.direction = Vector3(wind3.x, -0.3, wind3.z)
			pm.spread = 30.0
			pm.initial_velocity_min = 0.3
			pm.initial_velocity_max = 0.8
			pm.gravity = wind3 * 0.3 + Vector3(0.0, -0.5, 0.0)
			pm.damping_min = 0.25
			pm.damping_max = 0.4
			_turbulence(pm, 0.9, 2.0, 0.15, 0.3)
			pm.scale_min = 1.4
			pm.scale_max = 1.9
			pm.scale_curve = _in_out_curve(0.05, 0.12)
			p.draw_pass_1 = _leaf_mesh()
			p.material_override = _leaf_mat
		&"dust":
			p.lifetime = 3.2
			pm.direction = wind3 + Vector3(0.0, 0.08, 0.0)
			pm.spread = 14.0
			pm.initial_velocity_min = 2.2
			pm.initial_velocity_max = 3.8
			pm.gravity = Vector3(0.0, 0.12, 0.0)
			pm.damping_min = 0.6
			pm.damping_max = 0.9
			pm.scale_min = 0.7
			pm.scale_max = 1.2
			pm.scale_curve = _grow_curve(0.45, 1.6)
			pm.color = Color(0.80, 0.70, 0.54)
			pm.color_ramp = _fade_ramp(0.2, 0.45, 0.38)
			var q := QuadMesh.new()
			q.size = Vector2(1.8, 1.8)
			p.draw_pass_1 = q
			p.material_override = _soft[1]
		&"mist":
			p.lifetime = 14.0
			p.preprocess = 7.0
			pm.direction = wind3
			pm.spread = 25.0
			pm.initial_velocity_min = 0.12
			pm.initial_velocity_max = 0.32
			pm.gravity = Vector3.ZERO
			pm.scale_min = 0.8
			pm.scale_max = 1.25
			pm.scale_curve = _grow_curve(0.8, 1.2)
			pm.color = Color(0.78, 0.84, 0.96)
			pm.color_ramp = _fade_ramp(0.3, 0.35, 0.17)
			var pl := PlaneMesh.new()
			pl.size = Vector2(10.0, 10.0)
			p.draw_pass_1 = pl
			p.material_override = _soft[2]
		&"ripples":
			p.lifetime = 2.4
			pm.direction = Vector3.UP
			pm.spread = 0.0
			pm.initial_velocity_min = 0.0
			pm.initial_velocity_max = 0.0
			pm.gravity = Vector3.ZERO
			pm.scale_min = 0.7
			pm.scale_max = 1.3
			pm.color = Color(0.92, 0.96, 1.0)
			pm.color_ramp = _fade_ramp(0.05, 0.6, 0.55)
			var pl := PlaneMesh.new()
			pl.size = Vector2(1.6, 1.6)
			p.draw_pass_1 = pl
			p.material_override = _soft[3]
		&"snow":
			p.lifetime = 12.0
			p.preprocess = 12.0
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			pm.emission_box_extents = Vector3(VIEW_RADIUS - 4.0, 2.0, VIEW_RADIUS - 8.0)
			pm.direction = Vector3(0.0, -1.0, 0.0)
			pm.spread = 12.0
			pm.initial_velocity_min = 1.2
			pm.initial_velocity_max = 1.8
			pm.gravity = wind3 * 0.25 + Vector3(0.0, -0.05, 0.0)
			_turbulence(pm, 0.7, 4.0, 0.05, 0.15)
			pm.scale_min = 0.6
			pm.scale_max = 1.4
			pm.color = Color(0.96, 0.98, 1.0)
			pm.color_ramp = _fade_ramp(0.08, 0.1, 0.9)
			var q := QuadMesh.new()
			q.size = Vector2(0.2, 0.2)
			p.draw_pass_1 = q
			p.material_override = _soft[0]
	p.process_material = pm
	add_child(p)
	_em[id] = p
	_pm[id] = pm
	_npts[id] = 0
	_ratio[id] = 0.0


static func _turbulence(pm: ParticleProcessMaterial, strength: float, scale: float, lo: float, hi: float) -> void:
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = strength
	pm.turbulence_noise_scale = scale
	pm.turbulence_influence_min = lo
	pm.turbulence_influence_max = hi


## Alpha ramp: 0 -> `peak` over the first `rise` of the life, held, back to 0 over the last `fall`.
static func _fade_ramp(rise: float, fall: float, peak: float) -> GradientTexture1D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, rise, 1.0 - fall, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, peak), Color(1, 1, 1, peak), Color(1, 1, 1, 0)])
	var t := GradientTexture1D.new()
	t.gradient = g
	return t


## Scale curve 0 -> 1 over `rise`, 1 -> 0 over the last `fall` (opaque meshes appear / vanish by size).
static func _in_out_curve(rise: float, fall: float) -> CurveTexture:
	var c := Curve.new()
	c.add_point(Vector2(0.0, 0.0))
	c.add_point(Vector2(rise, 1.0))
	c.add_point(Vector2(1.0 - fall, 1.0))
	c.add_point(Vector2(1.0, 0.0))
	var t := CurveTexture.new()
	t.curve = c
	return t


static func _grow_curve(a: float, b: float) -> CurveTexture:
	var c := Curve.new()
	c.max_value = maxf(1.0, b)
	c.add_point(Vector2(0.0, a))
	c.add_point(Vector2(1.0, b))
	var t := CurveTexture.new()
	t.curve = c
	return t


func _butterfly_mesh() -> Mesh:
	if ResourceLoader.exists(BUTTERFLY_MESH):
		var m := load(BUTTERFLY_MESH) as Mesh
		if m:
			return m
	if ResourceLoader.exists(CRITTER_MESHES):
		var builder: Object = (load(CRITTER_MESHES) as GDScript).new()
		return builder.call(&"build", &"butterfly") as Mesh
	return QuadMesh.new()


## A 0.24 x 0.14 m leaf folded along its midrib (UV: x across, y along; the shader cuts the outline).
static func _leaf_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var w := 0.07
	var l := 0.12
	var f := 0.02
	var pts: Array[Vector3] = [Vector3(-w, 0, -l), Vector3(0, f, -l), Vector3(w, 0, -l), Vector3(-w, 0, l),
		Vector3(0, f, l), Vector3(w, 0, l)]
	var uvs: Array[Vector2] = [Vector2(0, 0), Vector2(0.5, 0), Vector2(1, 0), Vector2(0, 1), Vector2(0.5, 1),
		Vector2(1, 1)]
	for t: Array in [[0, 1, 4], [0, 4, 3], [1, 2, 5], [1, 5, 4]]:
		for k: int in t:
			st.set_uv(uvs[k])
			st.add_vertex(pts[k])
	st.generate_normals()
	return st.commit()


func _make_birds(count: int) -> void:
	if count <= 0:
		return
	var mesh: Mesh = null
	if ResourceLoader.exists(BIRD_MESH):
		mesh = load(BIRD_MESH) as Mesh
	if mesh == null and ResourceLoader.exists(CRITTER_MESHES):
		var builder: Object = (load(CRITTER_MESHES) as GDScript).new()
		mesh = builder.call(&"build", &"bird") as Mesh
	if mesh == null:
		return
	_bird_mat = ShaderMaterial.new()
	_bird_mat.shader = load(DIR + "ambient_birds.gdshader") as Shader
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = mesh
	mm.instance_count = count
	var h := MapInfo.half_max() + FLOCK_ENTER + 20.0
	mm.custom_aabb = AABB(Vector3(-h, -5.0, -h), Vector3(h * 2.0, 50.0, h * 2.0))
	_birds = MultiMeshInstance3D.new()
	_birds.name = "Birds"
	_birds.multimesh = mm
	_birds.material_override = _bird_mat
	_birds.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	# Little moving shadows on the ground at High / Ultra (tiny meshes: a few draws in the shadow pass).
	_birds.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if quality >= 2 \
		else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_birds.set_meta(&"no_ghost", true)
	add_child(_birds)
	var nf := count / BIRDS_PER_FLOCK
	for i in nf:
		var f := Flock.new()
		f.palette = i % 3
		f.radius = _rng.randf_range(BIRD_RADIUS.x, BIRD_RADIUS.y)
		var dir := -1.0 if _rng.randf() < 0.5 else 1.0
		f.omega = dir * BIRD_SPEED / f.radius
		f.omega_base = f.omega
		f.phase = _rng.randf() * TAU
		var c := Vector2(_focus.x, _focus.z) + Vector2(_rng.randf_range(-30.0, 30.0), _rng.randf_range(-30.0, 30.0))
		f.a = Vector3(c.x, _rng.randf_range(BIRD_ALT.x, BIRD_ALT.y), c.y)
		f.b = c
		f.t0 = _clock - 1.0
		f.dur = 0.01
		f.next_t = _clock + _rng.randf_range(8.0, 20.0)
		_flocks.append(f)
		_write_flock(i)


func _write_flock(fi: int) -> void:
	if _birds == null:
		return
	var f := _flocks[fi]
	var mm := _birds.multimesh
	var r := RandomNumberGenerator.new()
	r.seed = 1000 + fi * 37
	for k in BIRDS_PER_FLOCK:
		var i := fi * BIRDS_PER_FLOCK + k
		if i >= mm.instance_count:
			break
		# Loose V / cluster: the first bird leads, the others trail to the sides.
		var side := (float((k + 1) / 2) * (1.0 if k % 2 == 1 else -1.0)) * 1.3 + r.randf_range(-0.5, 0.5)
		var back := float((k + 1) / 2) * 1.2 + r.randf_range(-0.4, 0.6)
		var basis := Basis(Vector3(f.radius, f.phase, f.omega),
			Vector3(r.randf(), r.randf_range(BIRD_SCALE.x, BIRD_SCALE.y), f.climb),
			Vector3(side, back, float(f.palette)))
		mm.set_instance_transform(i, Transform3D(basis, f.a))
		mm.set_instance_custom_data(i, Color(f.b.x, f.b.y, f.t0, f.dur))


# ---------------------------------------------------------------- per frame

func _process(delta: float) -> void:
	_clock += delta
	if _bird_mat:
		_bird_mat.set_shader_parameter(&"clock", _clock)
	_update_focus()
	if _em.has(&"snow"):
		var sn := _em[&"snow"] as GPUParticles3D
		var c := _focus.lerp(Vector3(_cam_pos.x, 0.0, _cam_pos.z), 0.3)
		sn.global_position = Vector3(c.x, 15.0, c.z)
	_refresh_t -= delta
	_refresh_cool -= delta
	var moved := Vector2(_focus.x - _last_refresh_focus.x, _focus.z - _last_refresh_focus.z).length()
	if _refresh_t <= 0.0 or (_refresh_cool <= 0.0 and moved > REFRESH_MOVE):
		refresh_points()
	_mood_t -= delta
	if _mood_t <= 0.0:
		_mood_t = MOOD_TIME
		_apply_mood(_read_mood())
		_apply_fog_params()
	_logic_t -= delta
	if _logic_t <= 0.0:
		_logic_t = LOGIC_TIME
		_logic_phase = 1 - _logic_phase
		if _logic_phase == 0:
			_flock_plans()
		else:
			_scatter_scan()
	_gust_t -= delta
	if _gust_t <= 0.0:
		_gust_t = GUST_TICK
		_gusts(GUST_TICK)


func _update_focus() -> void:
	if focus_override is Vector3:
		_focus = focus_override
		_cam_pos = _focus + Vector3(0.0, 25.0, 17.0)
		return
	var vp := get_viewport()
	var cam := vp.get_camera_3d() if vp else null
	if cam == null:
		return
	_cam_pos = cam.global_position
	var vs := vp.get_visible_rect().size
	var o := cam.project_ray_origin(vs * 0.5)
	var d := cam.project_ray_normal(vs * 0.5)
	var c := Vector3(o.x, 0.0, o.z)
	if d.y < -0.05:
		c = o + d * (-o.y / d.y)
		c.y = 0.0
	_focus = c


## Re-picks every emitter's emission points round the focus (explored ground only).
func refresh_points() -> void:
	_refresh_t = REFRESH_TIME
	_refresh_cool = REFRESH_MIN
	_last_refresh_focus = _focus
	# Fog read once per refresh (not per point).
	_fog_q = null
	_fog_typed = null
	if is_instance_valid(_fog) and bool(_fog.get(&"enabled")) and _fog.has_method(&"is_explored"):
		_fog_q = _fog
		_fog_team = int(_fog.get(&"local_team"))
		_fog_typed = _fog as FogOfWar
	for id: StringName in _em:
		if id == &"snow":
			continue
		_fill_points(id)


func _explored(p: Vector3) -> bool:
	if _fog_typed:
		return _fog_typed.is_explored(_fog_team, p)
	if _fog_q == null:
		return true
	return bool(_fog_q.call(&"is_explored", _fog_team, p))


func _gather(set_name: String, r: float, out: PackedVector3Array) -> void:
	var cells: Dictionary = _cand.get(set_name, {})
	var c0 := Vector2i(floori((_focus.x - r) / CELL), floori((_focus.z - r) / CELL))
	var c1 := Vector2i(floori((_focus.x + r) / CELL), floori((_focus.z + r) / CELL))
	var r2 := r * r
	for cz in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			var k := Vector2i(cx, cz)
			if not cells.has(k):
				continue
			for p: Vector3 in (cells[k] as PackedVector3Array):
				var dx := p.x - _focus.x
				var dz := p.z - _focus.z
				if dx * dx + dz * dz <= r2:
					out.append(p)


func _gather_trees(r: float) -> PackedInt32Array:
	var out := PackedInt32Array()
	var c0 := Vector2i(floori((_focus.x - r) / CELL), floori((_focus.z - r) / CELL))
	var c1 := Vector2i(floori((_focus.x + r) / CELL), floori((_focus.z + r) / CELL))
	var r2 := r * r
	for cz in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			var k := Vector2i(cx, cz)
			if not _tree_cells.has(k):
				continue
			for i: int in (_tree_cells[k] as PackedInt32Array):
				var t := _trees[i]
				var dx := t.x - _focus.x
				var dz := t.y - _focus.z
				if dx * dx + dz * dz <= r2:
					out.append(i)
	return out


func _fill_points(id: StringName) -> void:
	var r := VIEW_RADIUS
	var base := PackedVector3Array()
	var tree_ids := PackedInt32Array()
	var night := bool(_mood.get("night", false))
	match id:
		&"wings":
			_gather("meadow", r, base)
		&"motes":
			_gather("meadow", r, base)
			_gather("bank", r, base)
			tree_ids = _gather_trees(r)
		&"leaves":
			tree_ids = _gather_trees(r)
		&"dust":
			_gather("road", r, base)
			_gather("heath", r, base)
		&"mist":
			_gather("meadow", r + 6.0, base)
			_gather("bank", r + 6.0, base)
			_gather("water", r + 6.0, base)
		&"ripples":
			_gather("water", r, base)
	var img := _img[id] as Image
	var n := 0
	var total := base.size() + tree_ids.size()
	# Random pick of up to MAX_POINTS (each candidate tried in a shuffled order), explored ground only.
	var tries := mini(total, MAX_POINTS * 3)
	for t in tries:
		if n >= MAX_POINTS:
			break
		var k := _rng.randi_range(0, total - 1)
		var p: Vector3
		if k < base.size():
			p = base[k]
			p.x += _rng.randf_range(-1.4, 1.4)
			p.z += _rng.randf_range(-1.4, 1.4)
		else:
			var tr := _trees[tree_ids[k - base.size()]]
			var ang := _rng.randf() * TAU
			if id == &"leaves":
				var rr := _rng.randf() * tr.w * 0.8
				p = Vector3(tr.x + cos(ang) * rr, tr.z * _rng.randf_range(0.6, 0.85), tr.y + sin(ang) * rr)
			else:
				var rr := tr.w + _rng.randf_range(0.4, 2.5)
				p = Vector3(tr.x + cos(ang) * rr, 0.0, tr.y + sin(ang) * rr)
		match id:
			&"wings":
				p.y = _rng.randf_range(0.5, 1.6)
			&"motes":
				if k >= base.size():
					p.y = _rng.randf_range(0.6, 2.8)
				else:
					p.y = _rng.randf_range(0.3, 1.4) if night else _rng.randf_range(0.4, 2.2)
			&"dust":
				p.y = _rng.randf_range(0.2, 0.6)
			&"mist":
				p.y = (WATER_Y + 0.25 if p.y < -0.1 else 0.0) + _rng.randf_range(0.25, 0.9)
			&"ripples":
				p.y = WATER_Y + 0.04
		if not _explored(p):
			continue
		img.set_pixel(n, 0, Color(p.x, p.y, p.z))
		n += 1
	_npts[id] = n
	(_tex[id] as ImageTexture).update(img)
	(_pm[id] as ParticleProcessMaterial).emission_point_count = maxi(n, 1)
	var em := _em[id] as GPUParticles3D
	var reach := r + 12.0
	em.visibility_aabb = AABB(Vector3(_focus.x - reach, -2.0, _focus.z - reach), Vector3(reach * 2.0, 24.0, reach * 2.0))
	_update_emitting(id)


func _update_emitting(id: StringName) -> void:
	var em := _em[id] as GPUParticles3D
	var ratio := float(_ratio.get(id, 0.0))
	var on := ratio > 0.0 and (id == &"snow" or int(_npts.get(id, 0)) > 0)
	if id != &"dust":
		em.amount_ratio = clampf(ratio, 0.0, 1.0)
	if em.emitting != on:
		em.emitting = on


# ---------------------------------------------------------------- mood

func _read_mood() -> Dictionary:
	var energy := 1.35
	var col := Color(1.0, 0.9, 0.75)
	var preset_id := &"warm"
	var preset_path := ""
	for n in get_tree().get_nodes_in_group(RIG_GROUP):
		if n == self or not (&"sun" in n):
			continue
		var sun_v: Variant = n.get(&"sun")
		var sun := sun_v as DirectionalLight3D if sun_v is DirectionalLight3D else null
		if sun == null or (_level and not _level.is_ancestor_of(n)):
			continue
		energy = sun.light_energy
		col = sun.light_color
		var pid: Variant = n.get(&"preset_id")
		if pid is StringName:
			preset_id = pid
		var pr: Variant = n.get(&"preset")
		if pr is Resource:
			preset_path = (pr as Resource).resource_path
		break
	var biome := ""
	if _level and _level.has_method(&"map_layout"):
		var lay: Variant = _level.call(&"map_layout")
		if lay is Resource and &"biome" in lay:
			biome = String(lay.get(&"biome"))
	var m := mood_from(energy, col, preset_id, biome, preset_path)
	m["sun_energy"] = energy
	return m


func _apply_mood(m: Dictionary) -> void:
	var same := not _mood.is_empty()
	for k: String in ["night", "snow", "autumn", "autumn_hint", "marsh"]:
		if bool(_mood.get(k, false)) != bool(m.get(k, false)):
			same = false
	if same:
		return
	var was_night := bool(_mood.get("night", false))
	_mood = m
	var night := bool(m.get("night", false))
	var snow := bool(m.get("snow", false))
	var autumn := bool(m.get("autumn", false))
	var r := mood_ratios(m)
	for id: StringName in _em:
		_ratio[id] = float(r[id])
	# Looks per mood.
	if _glow:
		if night:
			_glow.set_shader_parameter(&"glow", 3.0)
			_glow.set_shader_parameter(&"blink", 1.0)
			if _pm.has(&"motes"):
				(_pm[&"motes"] as ParticleProcessMaterial).color = Color(0.75, 1.0, 0.35)
		else:
			_glow.set_shader_parameter(&"glow", 1.4)
			_glow.set_shader_parameter(&"blink", 0.0)
			if _pm.has(&"motes"):
				(_pm[&"motes"] as ParticleProcessMaterial).color = Color(0.85, 0.9, 1.0) if snow \
					else Color(1.0, 0.86, 0.55)
	var tint := Color(0.42, 0.50, 0.78) if night else Color(1.0, 1.0, 1.0)
	for k: int in _soft:
		(_soft[k] as ShaderMaterial).set_shader_parameter(&"light_tint", tint)
	if _soft.has(2) and night:   # moonlit mist: paler than the night ground, never a dark smudge
		(_soft[2] as ShaderMaterial).set_shader_parameter(&"light_tint", Color(0.62, 0.70, 0.95))
	if _soft.has(2):
		(_soft[2] as ShaderMaterial).set_shader_parameter(&"strength", 1.0 if night else 0.7)
	if _wing_mat:
		_wing_mat.set_shader_parameter(&"night", 1.0 if night else 0.0)
	if _leaf_mat:
		if not autumn and bool(m.get("autumn_hint", false)):
			# An autumn-tagged map still drawn green: late-summer leaves (green, gold, a few orange).
			_leaf_mat.set_shader_parameter(&"leaf_a", Color(0.48, 0.58, 0.20))
			_leaf_mat.set_shader_parameter(&"leaf_b", Color(0.90, 0.68, 0.22))
			_leaf_mat.set_shader_parameter(&"leaf_c", Color(0.80, 0.40, 0.14))
		elif autumn:
			_leaf_mat.set_shader_parameter(&"leaf_a", Color(0.86, 0.42, 0.12))
			_leaf_mat.set_shader_parameter(&"leaf_b", Color(0.95, 0.70, 0.20))
			_leaf_mat.set_shader_parameter(&"leaf_c", Color(0.62, 0.20, 0.10))
		else:
			_leaf_mat.set_shader_parameter(&"leaf_a", Color(0.42, 0.58, 0.20))
			_leaf_mat.set_shader_parameter(&"leaf_b", Color(0.72, 0.66, 0.26))
			_leaf_mat.set_shader_parameter(&"leaf_c", Color(0.30, 0.46, 0.16))
	if _birds:
		_birds.visible = float(r[&"birds"]) > 0.0
	for id: StringName in _em:
		_update_emitting(id)
	if was_night != night:
		refresh_points()   # fireflies sit lower than pollen


func _gusts(dt: float) -> void:
	if not _em.has(&"dust"):
		return
	var em := _em[&"dust"] as GPUParticles3D
	var base := float(_ratio.get(&"dust", 0.0))
	_gust_clock += dt
	var env := 0.0
	if _gust_clock >= _gust_next:
		var g := _gust_clock - _gust_next
		if g < 3.5:
			env = sin(g / 3.5 * PI)
		else:
			_gust_clock = 0.0
			_gust_next = _rng.randf_range(4.0, 10.0)
	em.amount_ratio = clampf(base * (0.08 + 0.92 * env), 0.0, 1.0)


# ---------------------------------------------------------------- flocks

func _flock_plans() -> void:
	var fc := Vector2(_focus.x, _focus.z)
	for i in _flocks.size():
		var f := _flocks[i]
		if _clock < f.t0 + f.dur:
			continue
		var c := flock_centre(f.a, f.b, f.t0, f.dur, _clock)
		if f.omega != f.omega_base:
			_set_omega(f, f.omega_base)
			_write_flock(i)
		if c.distance_to(fc) > FLOCK_LEAVE:
			# Re-enter from off screen toward the view.
			var ang := _rng.randf() * TAU
			var start := fc + Vector2(cos(ang), sin(ang)) * FLOCK_ENTER
			var to := fc + Vector2(_rng.randf_range(-18.0, 18.0), _rng.randf_range(-18.0, 18.0))
			f.a = Vector3(start.x, _rng.randf_range(BIRD_ALT.x, BIRD_ALT.y), start.y)
			f.b = to
			f.t0 = _clock
			f.dur = start.distance_to(to) / 7.0
			f.climb = 0.0
			f.next_t = _clock + f.dur + _rng.randf_range(10.0, 25.0)
			_write_flock(i)
		elif _clock > f.next_t:
			var to := fc + Vector2(_rng.randf_range(-26.0, 26.0), _rng.randf_range(-26.0, 26.0))
			f.a = Vector3(c.x, f.a.y, c.y)
			f.b = to
			f.t0 = _clock
			f.dur = c.distance_to(to) / 4.0 + 2.0
			f.climb = 0.0
			f.next_t = _clock + f.dur + _rng.randf_range(10.0, 25.0)
			_write_flock(i)


## Keeps the circle angle continuous when the angular speed changes.
func _set_omega(f: Flock, w: float) -> void:
	f.phase += (f.omega - w) * _clock
	f.omega = w


## Fights and armies the LOCAL player sees (is_visible_in_tree: the fog hides unseen enemy units) scare a flock.
func _scatter_scan() -> void:
	if _flocks.is_empty() or (_birds and not _birds.visible):
		return
	var n := _flocks.size()
	var centres: Array[Vector2] = []
	var counts := PackedInt32Array()
	var fights := PackedInt32Array()
	var sums: Array[Vector2] = []
	var active := false
	for f: Flock in _flocks:
		var at_rest := _clock >= f.t0 + f.dur and _clock >= f.calm_t
		centres.append(flock_centre(f.a, f.b, f.t0, f.dur, _clock) if at_rest else Vector2(INF, INF))
		counts.append(0)
		fights.append(0)
		sums.append(Vector2.ZERO)
		active = active or at_rest
	if not active:
		return
	var r2 := SCARE_RADIUS * SCARE_RADIUS
	for u in get_tree().get_nodes_in_group(&"units"):
		var n3 := u as Node3D
		if n3 == null or not n3.is_visible_in_tree():
			continue
		var p := n3.global_position
		var seen := -1   # VfxFog check, done once per unit and only when a flock is in reach
		for i in n:
			var c := centres[i]
			var dx := p.x - c.x
			var dz := p.z - c.y
			if dx * dx + dz * dz > r2:
				continue
			if seen < 0:
				# A unit just spawned in fog stays visible until the next fog pass: non-allied units must also
				# stand where the local player sees now (VfxFog.ok is true for own / allied units).
				seen = 1 if VfxFog.ok(VfxFog.team_of(n3), p) else 0
			if seen == 0:
				break
			counts[i] += 1
			sums[i] += Vector2(p.x, p.z)
			var t: Variant = n3.get(&"attack_target")
			if t != null and is_instance_valid(t):
				fights[i] += 1
	for i in n:
		if fights[i] >= 1 or counts[i] >= SCARE_ARMY:
			_scatter(i, sums[i] / float(maxi(counts[i], 1)))


func _scatter(i: int, threat: Vector2) -> void:
	var f := _flocks[i]
	var c := flock_centre(f.a, f.b, f.t0, f.dur, _clock)
	var away := c - threat
	if away.length() < 0.5:
		away = Vector2(cos(f.phase), sin(f.phase))
	away = away.normalized()
	f.a = Vector3(c.x, f.a.y, c.y)
	f.b = c + away * SCATTER_DIST
	f.t0 = _clock
	f.dur = SCATTER_TIME
	f.climb = 5.0
	_set_omega(f, f.omega_base * 0.25)
	f.calm_t = _clock + SCARE_COOLDOWN
	f.next_t = _clock + SCATTER_TIME + _rng.randf_range(8.0, 16.0)
	f.scatters += 1
	scatter_count += 1
	_write_flock(i)
