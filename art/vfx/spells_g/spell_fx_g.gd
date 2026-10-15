class_name SpellFxG
extends Node3D
## G-B spell VFX layer (docs/art/gb_spell_vfx.md, graphics week wave G-B). Medium / High / Ultra ONLY: at Low (and in
## every headless or `-s` run, see GameSettings.effective_graphics_quality) it is never created, so Low keeps the exact
## look and cost the spell hubs had before G-B.
##
## The spell hubs (SpellVfx, IceVfx, NatureVfx and the four caster families of UnitVfx) keep drawing their own effects
## at every tier; at their existing timing hooks they also call
##   var g := SpellFxG.live(self)        # null at Low
##   if g: g.play(&"fireball_impact", pos, {"r": radius})
## and this node adds the layers a modern RTS spell has on top: a boiling noise-shaded fireball / implosion sphere,
## screen-space shockwaves and heat haze (High+), pooled dynamic light flashes with an attack / decay curve (the hubs'
## own light flashes are routed here too, with the same energies), flying lights on projectiles, extra particle layers
## (velocity streaks, debris chunks, smoke plumes, rising ash, ice shards, frost mist, void motes, leaves, petals,
## spores) and small ground marks that fade. Recipes per spell id are in `play`.
##
## Readability rules (in-game grade passes of 2026-09-30 / 10-12 kept): the big spheres live <= 0.75 s and dissolve
## from their thin parts first; smoke is <= 55 % opaque and rises above the units; ground marks stay <= 0.62 alpha; Ice
## lights stay at the hubs' energies (no cyan wash); no new light casts shadows.
## Budget: ONE node per level (group "spell_fx_g"), built once with pools sized by tier (CAPS); nothing allocated per
## cast except a few small dictionaries for delayed recipes. A full pool steals its oldest slot. Particles are not started
## beyond PARTICLE_RANGE from the camera, at most BURSTS_PER_FRAME bursts a frame. Effects of another team in the fog are
## skipped (caster families pass `team`; same rule as the families' _fog_ok).

const GROUP := &"spell_fx_g"
const BILLOW_SHADER := preload("res://art/vfx/spells_g/g_billow.gdshader")
const DISTORT_SHADER := preload("res://art/vfx/spells_g/g_distort.gdshader")
const MARK_SHADER := preload("res://art/vfx/spells_g/g_mark.gdshader")

const TIER_LOW := 0
const TIER_MEDIUM := 1
const TIER_HIGH := 2
const TIER_ULTRA := 3

## Pool sizes per tier [Low, Medium, High, Ultra] (Low never builds).
const CAPS := {
	&"billow": [0, 6, 10, 14],
	&"distort": [0, 0, 6, 10],
	&"mark": [0, 8, 12, 16],
	&"light": [0, 3, 6, 8],
	&"trail": [0, 4, 6, 8],
}
## Particle amounts are the High numbers in LOOKS times this.
const AMOUNT_MULT: Array[float] = [0.0, 0.5, 1.0, 1.6]
## One-shot emitters per look.
const BURST_POOL: Array[int] = [0, 2, 3, 4]
const PARTICLE_RANGE := 70.0
const BURSTS_PER_FRAME := 18
const LIGHT_RANGE := 90.0

## Billow palettes (linear HDR): [hot, mid, smoke (alpha = smoke opacity)].
const PALETTES := {
	&"fire": [Color(1.9, 0.78, 0.18), Color(1.15, 0.24, 0.03), Color(0.08, 0.055, 0.045, 0.55)],
	&"fire_core": [Color(2.9, 1.55, 0.5), Color(1.9, 0.6, 0.08), Color(1.0, 0.25, 0.04, 0.6)],
	&"smoke": [Color(0.16, 0.12, 0.10), Color(0.11, 0.09, 0.08), Color(0.06, 0.05, 0.05, 0.5)],
	&"molten": [Color(2.8, 1.2, 0.3), Color(1.4, 0.32, 0.04), Color(0.10, 0.06, 0.04, 0.8)],
	&"shadow": [Color(1.0, 0.3, 2.0), Color(0.14, 0.02, 0.26), Color(0.015, 0.0, 0.03, 0.85)],
	&"ice": [Color(1.0, 1.35, 1.6), Color(0.38, 0.66, 0.95), Color(0.55, 0.68, 0.80, 0.42)],
	&"steam": [Color(1.5, 1.7, 1.9), Color(0.7, 0.85, 1.0), Color(0.62, 0.68, 0.74, 0.45)],
	&"dust": [Color(0.70, 0.62, 0.40), Color(0.42, 0.33, 0.20), Color(0.30, 0.24, 0.16, 0.5)],
	&"gold": [Color(2.2, 1.8, 0.8), Color(1.0, 0.85, 0.35), Color(0.6, 0.55, 0.3, 0.3)],
}

## Every event id play draws (the hubs call no other; tests/test_gb_vfx.gd checks both ways).
const RECIPES: Array[StringName] = [&"fireball_cast", &"fireball_fly", &"fireball_impact", &"ember_step_out",
		&"ember_step_in", &"kindle", &"shadow_lance_cast", &"lance_fly", &"lance_hit", &"soul_siphon", &"umbral_shroud",
		&"rime_bolt_fly", &"rime_bolt_hit", &"flash_freeze", &"rime_aegis", &"rime_aegis_shield", &"thornburst",
		&"wild_bloom", &"call_the_thicket", &"sprout", &"slag_rain", &"slag_land", &"mana_scald", &"stoke",
		&"rime_bulwark", &"rime_bulwark_shatter", &"rime_bulwark_melt", &"scrying_rune", &"snagroot", &"pollen_haze",
		&"seedcloak", &"blood_tithe", &"umbral_passage", &"passage_step", &"vigil"]

## Light colours (linear).
const L_FIRE := Color(1.0, 0.46, 0.13)
const L_VIOLET := Color(0.62, 0.26, 1.0)
const L_LEAF := Color(0.62, 1.0, 0.36)
const L_GOLD := Color(1.0, 0.80, 0.42)
const L_BLOOD := Color(0.95, 0.22, 0.55)
const L_STEAM := Color(0.75, 0.88, 1.0)

## Particle looks: [amount at High, lifetime, draw pass, explosiveness]. Process materials in _pmat.
const LOOKS := {
	&"ember_burst": [70, 0.95, &"streak", 0.95],
	&"ember_small": [22, 0.5, &"streak", 0.9],
	&"fire_debris": [14, 1.25, &"chunk_glow", 1.0],
	&"smoke_plume": [14, 2.6, &"smoke", 0.85],
	&"ash_rise": [26, 2.2, &"soft_add", 0.5],
	&"fire_ring": [56, 0.6, &"streak", 0.95],
	&"void_in": [50, 0.6, &"soft_add", 0.95],
	&"void_sparks": [40, 0.5, &"streak", 1.0],
	&"void_smoke": [12, 1.6, &"smoke", 0.8],
	&"ice_shards": [18, 1.15, &"shard", 1.0],
	&"frost_mist": [14, 1.3, &"smoke", 0.9],
	&"ice_glints": [32, 1.1, &"soft_add", 0.7],
	&"earth_debris": [16, 1.2, &"chunk", 1.0],
	&"dust_ring": [14, 1.6, &"smoke", 0.9],
	&"leaf_burst": [26, 1.7, &"petal", 0.9],
	&"petal_spiral": [36, 2.3, &"petal", 0.4],
	&"spores": [30, 2.6, &"soft_add", 0.3],
	&"steam_puff": [10, 1.0, &"smoke", 0.9],
}
## Continuous emitters on projectiles: look -> [amount at High, lifetime, draw pass].
const TRAILS := {
	&"trail_fire_g": [48, 0.55, &"streak"],
	&"trail_void_g": [36, 0.5, &"soft_add"],
	&"trail_frost_g": [30, 0.6, &"soft_add"],
}

## One pooled piece (billow, distortion, mark, light or trail).
class Slot:
	extends RefCounted
	var n: Node3D
	var busy := false
	var t := 0.0
	var dur := 1.0
	var delay := 0.0
	var pos := Vector3.ZERO
	var vel := Vector3.ZERO
	var s0 := 1.0
	var s1 := 1.0
	var e0 := 1.0
	var reach := 1.0
	var mode := 0.0
	var follow: Node3D = null
	var ofs := Vector3.ZERO
	var hold := 0.0
	var a := Vector3.ZERO
	var b := Vector3.ZERO
	var arc := 0.0
	var fly := 0.0
	var ending := false
	var team := -1


## Look-dev / labs: true = never build (the before shots of gb_vfx_shots.gd at the same tier).
static var force_off := false
## Tests: >= 0 replaces the settings tier (tests/test_gb_vfx.gd builds the layer in a headless run).
static var test_tier := -1
static var _inst: SpellFxG = null
static var _pending_ms := 0
static var _tier_cache := -1
static var _tier_ms := -100000

var tier_built := 0
var _billows: Array[Slot] = []
var _distorts: Array[Slot] = []
var _marks: Array[Slot] = []
var _lights: Array[Slot] = []
var _trails: Array[Slot] = []
var _next := {}                       # pool name -> round-robin index
var _bursts: Dictionary = {}          # look -> Array[GPUParticles3D]
var _burst_next: Dictionary = {}
var _live_bursts: Array[GPUParticles3D] = []
var _queue: Array[Dictionary] = []    # delayed recipes {t, id, pos, opts}
var _last_play: Dictionary = {}       # throttle key -> msec
var _bursts_this_frame := 0
var _clock := 0.0
var _cur_team := -1                  # team of the recipe being played (fog of its followers)
var _follow_fog_left := 0.0
var _cam: Camera3D
var _fog: Node
var _fog_left := 0.0
var _rng := RandomNumberGenerator.new()

# Shared resources (built once).
var _passes: Dictionary = {}
var _pmats: Dictionary = {}
var _billow_mat: ShaderMaterial
var _distort_mat: ShaderMaterial
var _mark_mat: ShaderMaterial
var _sphere: SphereMesh
var _quad: QuadMesh
var _plane: PlaneMesh


# ---------------------------------------------------------------- access

## The tier now (cached 1 s): GameSettings.effective_graphics_quality(), Low in headless / scripted runs.
static func tier() -> int:
	if test_tier >= 0:
		_tier_cache = clampi(test_tier, TIER_LOW, TIER_ULTRA)
		return _tier_cache
	var now := Time.get_ticks_msec()
	if _tier_cache < 0 or now - _tier_ms > 1000:
		_tier_ms = now
		_tier_cache = clampi(GameSettings.effective_graphics_quality(), TIER_LOW, TIER_ULTRA)
	return _tier_cache


## The level's G layer (made on first use, next to `from`), or null at Low / outside a tree. A tier change rebuilds it.
static func live(from: Node) -> SpellFxG:
	var q := tier() if not force_off else TIER_LOW
	if is_instance_valid(_inst) and not _inst.is_queued_for_deletion():
		if _inst.tier_built == q:
			if _inst.is_inside_tree():
				return _inst
			if Time.get_ticks_msec() - _pending_ms < 1000:
				return null   # its add_child is still deferred: keep it, never build a second one
			_inst.free()      # never entered a tree (its holder left first): rebuild below
		else:
			_inst.queue_free()
	_inst = null
	if q < TIER_MEDIUM or from == null or not is_instance_valid(from) or not from.is_inside_tree():
		return null
	var tree := from.get_tree()
	for n in tree.get_nodes_in_group(GROUP):
		var g := n as SpellFxG
		if g and not g.is_queued_for_deletion() and g.tier_built == q:
			_inst = g
			return g
	var holder: Node = from.get_parent() if from.get_parent() else from
	var g := SpellFxG.new()
	g.name = "SpellFxG"
	g.tier_built = q
	if holder.is_node_ready() and not holder.is_queued_for_deletion():
		holder.add_child(g)
	else:
		holder.add_child.call_deferred(g)
		_pending_ms = Time.get_ticks_msec()
	_inst = g
	return g if g.is_inside_tree() else null


func _ready() -> void:
	add_to_group(GROUP)
	top_level = true
	global_transform = Transform3D.IDENTITY
	_rng.seed = 7331
	_build_shared()


func _exit_tree() -> void:
	if _inst == self:
		_inst = null


## Pieces / bursts on screen now (tests).
func live_count() -> int:
	var c := _live_bursts.size()
	for pool: Array[Slot] in [_billows, _distorts, _marks, _lights, _trails]:
		for s in pool:
			if s.busy:
				c += 1
	return c


## Pool sizes built (tests): {billow, distort, mark, light, trail, bursts (emitters)}.
func pool_sizes() -> Dictionary:
	var em := 0
	for look: StringName in _bursts:
		em += (_bursts[look] as Array).size()
	return {&"billow": _billows.size(), &"distort": _distorts.size(), &"mark": _marks.size(), &"light": _lights.size(),
			&"trail": _trails.size(), &"bursts": em}


# ---------------------------------------------------------------- recipes

## Plays the G layer of spell event `id` at `pos`. opts: r (radius), dir (Vector3), node (Node3D to follow: projectile,
## unit), from (Vector3), team (int, fog), delay (s), axis (Vector3, walls), size.
func play(id: StringName, pos: Vector3, opts: Dictionary = {}) -> void:
	if not is_inside_tree():
		return
	var delay := float(opts.get("delay", 0.0))
	if delay > 0.0:
		var o := opts.duplicate()
		o.erase("delay")
		_queue.append({"t": _clock + delay, "id": id, "pos": pos, "opts": o})
		return
	var team := int(opts.get("team", -1))
	if not _fog_ok(team, pos):
		return
	_cur_team = team
	if _cam == null or not is_instance_valid(_cam):
		_cam = get_viewport().get_camera_3d() if get_viewport() else null
	if _cam and _cam.global_position.distance_to(pos) > LIGHT_RANGE and not opts.has("node"):
		return
	var r := float(opts.get("r", 3.0))
	var k := r / 3.5
	var up := Vector3.UP
	var dir: Vector3 = opts.get("dir", Vector3.ZERO)
	var node: Node3D = opts.get("node") as Node3D if opts.get("node") is Node3D else null
	var hi := tier_built >= TIER_HIGH
	var ultra := tier_built >= TIER_ULTRA
	match id:
		# ---------------- Fire (Vessa)
		&"fireball_cast":
			_burst(&"ember_small", pos, 0.8)
		&"fireball_fly":
			if node:
				_trail(&"trail_fire_g", node)
				_follow_light(node, L_FIRE, 2.4, 7.0)
				_head(node, &"fire", 0.95)
				if ultra:
					_haze_follow(node, 1.3, 1.7)
		&"fireball_impact":
			_billow(pos + up * 0.5 * k, &"fire_core", r * 0.25, r * 0.8, 0.3, up * 0.6)
			_billow(pos + up * 0.6 * k, &"fire", r * 0.45, r * 1.45, 0.85, up * 1.9)
			_billow(pos + up * 1.1 * k, &"smoke", r * 0.6, r * 1.4, 1.7, up * 3.0, 0.15, 0.58)
			_burst(&"ember_burst", pos + up * 0.4, k)
			_burst(&"fire_debris", pos + up * 0.3, k)
			_burst(&"smoke_plume", pos + up * 0.9, k)
			_burst(&"ash_rise", pos + up * 0.4, k)
			if hi:
				_shock(pos, r * 2.6, 0.5, 0.05)
				_haze(pos + up * 1.4 * k, r * 1.2, r * 1.5, 1.8, 0.012)
		&"ember_step_out":
			_billow(pos + up * 0.8, &"fire", 0.6, 1.9, 0.42, up * 2.2)
			_burst(&"ember_small", pos + up * 0.6, 1.2)
			_burst(&"fire_ring", pos + up * 0.1, 0.5)
		&"ember_step_in":
			_billow(pos + up * 0.6, &"fire_core", 0.4, 1.3, 0.25, up * 0.4)
			_billow(pos + up * 0.5, &"fire", 0.7, 2.2, 0.5, up * 1.4)
			_burst(&"ember_burst", pos + up * 0.3, 0.7)
			_burst(&"fire_ring", pos + up * 0.1, 0.8)
			if hi:
				_shock(pos, 5.0, 0.4, 0.04)
		&"kindle":
			_burst(&"fire_ring", pos + up * 0.1, minf(r * 0.3, 2.4))
			_burst(&"ash_rise", pos + up * 0.3, r / 3.0)
			_burst(&"ember_burst", pos + up * 0.2, 0.8)
			_billow(pos + up * 0.4, &"fire_core", 0.5, 1.6, 0.3, up * 0.8)
			if hi:
				_shock(pos, r * 2.15, 0.65, 0.04)
		# ---------------- Shadow (Malrik)
		&"shadow_lance_cast":
			_burst(&"void_sparks", pos, 0.4)
		&"lance_fly":
			if node:
				_trail(&"trail_void_g", node)
				_follow_light(node, L_VIOLET, 1.8, 5.5)
		&"lance_hit":
			_billow(pos, &"shadow", 0.5, 2.2, 0.45, up * 0.3, 0.0, 0.9)
			_burst(&"void_sparks", pos + dir * 0.3, 1.1, dir)
			_burst(&"void_smoke", pos, 0.6)
			_light(pos + up * 0.4, L_VIOLET, 2.6, 5.0, 0.4)
			_mark(Vector3(pos.x, pos.y - 1.0, pos.z), 2, 0.9, 1.4, 1.0, 1.0)
			if hi:
				_shock(Vector3(pos.x, pos.y - 1.0, pos.z), 3.2, 0.32, 0.035)
		&"soul_siphon":
			_billow(pos + up * 0.8, &"shadow", r * 0.85, r * 0.15, 0.6, Vector3.ZERO, 0.0, 0.55, true)
			_burst(&"void_in", pos + up * 0.6, r / 2.5)
			_burst(&"void_smoke", pos + up * 0.3, r / 3.0)
			_light(pos + up * 1.2, L_VIOLET, 1.8, r * 1.6, 1.4)
			_mark(pos, 2, r * 0.85, 3.2, 1.0, 1.0)
			if hi:
				_implode(pos, r * 2.3, 0.7, 0.045)
		&"umbral_shroud":
			_billow(pos + up * 1.0, &"shadow", 2.8, 0.5, 0.45, Vector3.ZERO, 0.0, 0.6, true)
			_burst(&"void_in", pos + up * 1.0, 0.8)
			_burst(&"void_smoke", pos + up * 0.4, 0.8)
			if hi:
				_implode(pos, 4.5, 0.5, 0.04)
		# ---------------- Ice (Torvald)
		&"rime_bolt_fly":
			if node:
				_trail(&"trail_frost_g", node)
		&"rime_bolt_hit":
			_billow(pos + up * 0.9, &"ice", 0.35, 1.3, 0.4, up * 0.5, 0.0, 0.4)
			_burst(&"ice_shards", pos + up * 0.9, 0.7)
			_burst(&"frost_mist", pos + up * 0.2, 0.6)
			_mark(pos, 1, 1.2, 1.6, 1.2, 1.0)
			if hi:
				_shock(pos, 2.6, 0.3, 0.03)
		&"flash_freeze":
			_billow(pos + up * 0.5, &"ice", r * 0.4, r * 1.3, 0.5, up * 0.8, 0.0, 0.3)
			_burst(&"ice_shards", pos + up * 0.4, r / 3.0)
			_burst(&"frost_mist", pos + up * 0.2, r / 3.0)
			_burst(&"ice_glints", pos + up * 0.8, r / 3.0)
			if hi:
				_shock(pos, r * 2.6, 0.5, 0.05)
		&"rime_aegis":
			_burst(&"ice_glints", pos + up * 0.6, r / 4.0)
			if hi:
				_shock(pos, r * 2.0, 0.6, 0.025)
		&"rime_aegis_shield":
			_burst(&"ice_glints", pos + up * 1.0, 0.35)
		# ---------------- Nature (Ysolde)
		&"thornburst":
			_billow(pos + up * 0.4, &"dust", r * 0.45, r * 1.2, 0.55, up * 0.9, 0.05, 0.4)
			_burst(&"earth_debris", pos + up * 0.2, r / 3.0)
			_burst(&"dust_ring", pos + up * 0.2, r / 3.0)
			_burst(&"leaf_burst", pos + up * 0.4, r / 3.0)
			if hi:
				_shock(pos, r * 2.2, 0.4, 0.04)
		&"wild_bloom":
			_burst(&"petal_spiral", pos + up * 0.2, r / 4.0)
			_burst(&"spores", pos + up * 0.5, r / 4.0)
			_billow(pos + up * 0.6, &"gold", r * 0.3, r * 1.1, 0.6, up * 0.8, 0.0, 0.35)
		&"call_the_thicket":
			_burst(&"leaf_burst", pos + up * 0.3, 1.2)
			_burst(&"earth_debris", pos + up * 0.1, 0.8)
			_burst(&"dust_ring", pos + up * 0.1, 0.8)
			if hi:
				_shock(pos, 4.5, 0.4, 0.03)
		&"sprout":
			_burst(&"earth_debris", pos + up * 0.1, 0.45)
		# ---------------- Casters
		&"slag_rain":
			var from: Vector3 = opts.get("from", pos + Vector3(0, 2.4, -4.0))
			var fly := float(opts.get("fly", 0.6))
			_arc_light(from, pos + up * 0.3, float(opts.get("arc", 2.2)), fly, L_FIRE, 1.6, 4.5)
			play(&"slag_land", pos, {"r": r, "delay": fly})
		&"slag_land":
			_billow(pos + up * 0.4, &"molten", r * 0.35, r * 1.05, 0.55, up * 1.0, 0.0, 0.95)
			_billow(pos + up * 0.8, &"smoke", r * 0.5, r * 1.1, 1.3, up * 2.2, 0.1, 0.45)
			_light(pos + up * 1.0, L_FIRE, 3.0, r * 1.8, 0.45)
			_burst(&"ember_burst", pos + up * 0.3, k * 0.9)
			_burst(&"fire_debris", pos + up * 0.2, k * 0.8)
			if hi:
				_shock(pos, r * 2.2, 0.4, 0.04)
				_haze(pos + up * 1.0, r * 1.1, r * 1.3, 1.4, 0.01)
		&"mana_scald":
			_billow(pos, &"steam", 0.3, 1.2, 0.4, up * 0.6, 0.0, 0.4)
			_burst(&"steam_puff", pos, 0.8)
			_light(pos, L_STEAM, 2.2, 4.0, 0.3)
		&"stoke":
			_light(pos, L_FIRE, 1.6, 3.0, 0.35)
			_burst(&"ember_small", pos, 0.5)
		&"rime_bulwark":
			var axis: Vector3 = opts.get("axis", Vector3.RIGHT)
			axis.y = 0.0
			axis = axis.normalized() if axis.length() > 0.01 else Vector3.RIGHT
			for i in 3:
				var at := pos + axis * (float(i) - 1.0) * 1.4
				_burst(&"ice_shards", at + up * 0.3, 0.6)
			_burst(&"frost_mist", pos + up * 0.15, 1.1)
			if hi:
				_shock(pos, 6.0, 0.4, 0.03)
		&"rime_bulwark_shatter":
			_billow(pos + up * 1.0, &"ice", 0.6, 2.2, 0.35, up * 0.4, 0.0, 0.35)
			_burst(&"ice_shards", pos + up * 1.0, 1.4)
			_burst(&"frost_mist", pos + up * 0.2, 1.0)
			if hi:
				_shock(pos, 5.0, 0.35, 0.045)
		&"rime_bulwark_melt":
			_burst(&"frost_mist", pos + up * 0.3, 0.9)
		&"scrying_rune":
			_burst(&"ice_glints", pos + up * 0.8, 0.6)
			if hi:
				_shock(pos, 3.0, 0.4, 0.025)
		&"snagroot":
			_burst(&"earth_debris", pos + up * 0.1, 0.55)
			_burst(&"dust_ring", pos + up * 0.1, 0.5)
			_burst(&"leaf_burst", pos + up * 0.8, 0.45)
		&"pollen_haze":
			_burst(&"spores", pos + up * 0.6, r / 3.0)
			_burst(&"petal_spiral", pos + up * 0.2, r / 5.0)
			_light(pos + up * 1.5, L_GOLD, 0.9, r * 1.6, 1.6, 0.5)
		&"seedcloak":
			_burst(&"spores", pos + up * 0.6, 0.7)
			_burst(&"leaf_burst", pos + up * 0.5, 0.5)
		&"blood_tithe":
			if _throttle(id, pos, 900):
				_burst(&"void_sparks", pos + up * 1.0, 0.35)
				_light(pos + up * 1.0, L_BLOOD, 1.0, 3.5, 0.5, 0.3)
		&"umbral_passage":
			_billow(pos + up * 1.2, &"shadow", 2.6, 0.4, 0.6, Vector3.ZERO, 0.0, 0.55, true)
			_burst(&"void_in", pos + up * 1.0, 0.9)
			_light(pos + up * 1.4, L_VIOLET, 1.6, 6.0, 1.2, 0.4)
			if hi:
				_implode(pos, 5.0, 0.6, 0.04)
		&"passage_step":
			if _throttle(id, pos, 150):
				_burst(&"void_smoke", pos + up * 0.4, 0.45)
		&"vigil":
			_burst(&"void_sparks", pos + up * 0.8, 0.3)


## Routed light flash of a hub (same arguments as the hubs' _light_flash): a pooled light with a fast attack and a
## squared decay instead of the hub's 2 or 3 lights with a linear fade.
func light(pos: Vector3, col: Color, energy: float, reach: float, time: float) -> void:
	if not _fog_ok(-1, pos):
		return
	_cur_team = -1
	_light(pos, col, energy, reach, time)


# ---------------------------------------------------------------- per frame

func _process(delta: float) -> void:
	_clock += delta
	_bursts_this_frame = 0
	_fog_left -= delta
	if _fog_left <= 0.0:
		_fog_left = 1.0
		_fog = get_tree().get_first_node_in_group(&"fog")
		_cam = get_viewport().get_camera_3d() if get_viewport() else null
	if not _queue.is_empty():
		for i in range(_queue.size() - 1, -1, -1):
			var q: Dictionary = _queue[i]
			if _clock >= float(q["t"]):
				_queue.remove_at(i)
				play(q["id"], q["pos"], q["opts"])
	_follow_fog_left -= delta
	if _follow_fog_left <= 0.0:
		_follow_fog_left = 0.25
		_fog_followers()
	for s in _billows:
		if s.busy:
			_tick_billow(s, delta)
	for s in _distorts:
		if s.busy:
			_tick_distort(s, delta)
	for s in _marks:
		if s.busy:
			_tick_mark(s, delta)
	for s in _lights:
		if s.busy:
			_tick_light(s, delta)
	for s in _trails:
		if s.busy:
			_tick_trail(s, delta)
	for i in range(_live_bursts.size() - 1, -1, -1):
		var p := _live_bursts[i]
		if _clock > float(p.get_meta(&"until", 0.0)):
			p.emitting = false
			p.visible = false
			_live_bursts.remove_at(i)


## Pieces riding a projectile hide while it flies through fog the local team does not see (an enemy shot).
func _fog_followers() -> void:
	for pool: Array[Slot] in [_billows, _lights, _trails, _distorts]:
		for s in pool:
			if s.busy and s.follow != null and is_instance_valid(s.follow) and s.delay <= 0.0 and not s.ending:
				var vis := _fog_ok(s.team, s.follow.global_position)
				if s.n.visible != vis:
					s.n.visible = vis


static func _ease_out(k: float) -> float:
	return 1.0 - pow(1.0 - clampf(k, 0.0, 1.0), 3.0)


func _follow_ok(s: Slot) -> bool:
	var f := s.follow
	return f != null and is_instance_valid(f) and f.is_inside_tree() and f.is_processing() and f.is_visible_in_tree()


func _tick_billow(s: Slot, delta: float) -> void:
	var m := s.n as MeshInstance3D
	if s.delay > 0.0:
		s.delay -= delta
		if s.delay > 0.0:
			return
		m.visible = true
	s.t += delta
	if s.mode > 1.5:   # a projectile head: boils at the head while the shot flies
		if _follow_ok(s):
			m.global_position = s.follow.global_position
			var pulse := 1.0 + 0.1 * sin(_clock * 31.0) + 0.06 * sin(_clock * 17.0)
			m.scale = Vector3.ONE * s.s0 * pulse
			return
		_free_slot(s)
		return
	var k := clampf(s.t / s.dur, 0.0, 1.0)
	if k >= 1.0:
		_free_slot(s)
		return
	var e := _ease_out(k)
	var sc := lerpf(s.s0, s.s1, e if s.mode < 0.5 else k * k)
	m.scale = Vector3.ONE * maxf(sc, 0.01)
	m.global_position = s.pos + s.vel * e
	var life := k if s.mode < 0.5 else 0.25 + 0.6 * k
	m.set_instance_shader_parameter(&"life", life)


func _tick_distort(s: Slot, delta: float) -> void:
	var m := s.n as MeshInstance3D
	if s.delay > 0.0:
		s.delay -= delta
		if s.delay > 0.0:
			return
		m.visible = true
	s.t += delta
	if s.follow != null:
		if _follow_ok(s):
			m.global_position = s.follow.global_position + s.ofs
			m.set_instance_shader_parameter(&"life", 0.5)
			return
		s.follow = null
		s.t = s.dur * 0.5   # fade out from mid-envelope
	var k := clampf(s.t / s.dur, 0.0, 1.0)
	if k >= 1.0:
		_free_slot(s)
		return
	m.set_instance_shader_parameter(&"life", k if s.mode != 1.0 else k)


func _tick_mark(s: Slot, delta: float) -> void:
	var m := s.n as MeshInstance3D
	s.t += delta
	var total := s.hold + s.dur
	if s.t >= total:
		_free_slot(s)
		return
	var fin := clampf(s.t / 0.12, 0.0, 1.0)
	var fout := 1.0 - clampf((s.t - s.hold) / s.dur, 0.0, 1.0)
	m.set_instance_shader_parameter(&"fade", fin * fout)
	m.set_instance_shader_parameter(&"heat", s.e0 * clampf(1.0 - s.t / maxf(total * 0.8, 0.1), 0.0, 1.0))


func _tick_light(s: Slot, delta: float) -> void:
	var l := s.n as OmniLight3D
	if s.delay > 0.0:
		s.delay -= delta
		if s.delay > 0.0:
			return
		l.visible = true
	s.t += delta
	if s.mode > 0.5 and s.mode < 1.5 and not s.ending:   # follows a projectile
		if _follow_ok(s):
			l.global_position = s.follow.global_position + Vector3.UP * 0.2
			l.light_energy = s.e0 * (0.9 + 0.1 * sin(_clock * 23.0) + 0.05 * sin(_clock * 41.0))
			return
		s.ending = true
		s.t = 0.0
		s.dur = 0.18
	if s.mode > 1.5 and not s.ending:   # flies along an arc (slag glob)
		var kf := clampf(s.t / maxf(s.fly, 0.01), 0.0, 1.0)
		l.global_position = s.a.lerp(s.b, kf) + Vector3.UP * sin(kf * PI) * s.arc
		l.light_energy = s.e0
		if kf >= 1.0:
			_free_slot(s)
		return
	var k := clampf(s.t / s.dur, 0.0, 1.0)
	if k >= 1.0:
		_free_slot(s)
		return
	var att := 0.06 / maxf(s.dur, 0.06)
	var e := k / att if k < att else pow(1.0 - (k - att) / (1.0 - att), 2.0)
	if s.ending:
		e = 1.0 - k
	l.light_energy = s.e0 * e


func _tick_trail(s: Slot, delta: float) -> void:
	var p := s.n as GPUParticles3D
	if not s.ending:
		if _follow_ok(s):
			p.global_position = s.follow.global_position
			return
		s.ending = true
		s.t = 0.0
		p.emitting = false
	s.t += delta
	if s.t > p.lifetime + 0.1:
		_free_slot(s)


func _free_slot(s: Slot) -> void:
	s.busy = false
	s.follow = null
	s.ending = false
	s.n.visible = false
	if s.n is GPUParticles3D:
		(s.n as GPUParticles3D).emitting = false


# ---------------------------------------------------------------- pieces

## Takes a free slot of `pool` (round robin), else steals the next one.
func _take(pool: Array[Slot], key: StringName) -> Slot:
	if pool.is_empty():
		return null
	var i0 := int(_next.get(key, 0))
	for j in pool.size():
		var i := (i0 + j) % pool.size()
		if not pool[i].busy:
			_next[key] = (i + 1) % pool.size()
			return _reset(pool[i])
	_next[key] = (i0 + 1) % pool.size()
	var s := pool[i0]
	_free_slot(s)
	return _reset(s)


func _reset(s: Slot) -> Slot:
	s.busy = true
	s.t = 0.0
	s.delay = 0.0
	s.follow = null
	s.ending = false
	s.vel = Vector3.ZERO
	s.ofs = Vector3.ZERO
	s.mode = 0.0
	s.team = _cur_team
	return s


## A boiling sphere (diameter s0 -> s1 m) at `pos`, drifting by `vel` over `dur`. implode = shrinks and keeps a hot rim.
func _billow(pos: Vector3, palette: StringName, s0: float, s1: float, dur: float, vel: Vector3 = Vector3.ZERO,
		delay: float = 0.0, opacity: float = 0.95, implode := false) -> void:
	var s := _take(_billows, &"billow")
	if s == null:
		return
	s.pos = pos
	s.vel = vel
	s.s0 = s0
	s.s1 = s1
	s.dur = maxf(dur, 0.05)
	s.delay = delay
	s.mode = 1.0 if implode else 0.0
	var m := s.n as MeshInstance3D
	_palette(m, palette)
	m.set_instance_shader_parameter(&"life", 0.0)
	m.set_instance_shader_parameter(&"opacity", opacity)
	m.set_instance_shader_parameter(&"implode", 1.0 if implode else 0.0)
	m.set_instance_shader_parameter(&"turb", 0.3 if implode else 0.38)
	m.set_instance_shader_parameter(&"seed", _rng.randf() * 20.0)
	m.global_position = pos
	m.scale = Vector3.ONE * maxf(s0, 0.01)
	m.rotation = Vector3(0.0, _rng.randf() * TAU, 0.0)
	m.visible = delay <= 0.0


## A boiling head on a projectile (the fireball itself), until the projectile stops.
func _head(node: Node3D, palette: StringName, size: float) -> void:
	var s := _take(_billows, &"billow")
	if s == null:
		return
	s.follow = node
	s.mode = 2.0
	s.s0 = size
	s.dur = 999.0
	var m := s.n as MeshInstance3D
	_palette(m, palette)
	m.set_instance_shader_parameter(&"life", 0.12)
	m.set_instance_shader_parameter(&"opacity", 0.9)
	m.set_instance_shader_parameter(&"implode", 0.0)
	m.set_instance_shader_parameter(&"turb", 0.42)
	m.set_instance_shader_parameter(&"seed", _rng.randf() * 20.0)
	m.global_position = node.global_position
	m.scale = Vector3.ONE * size
	m.visible = true


func _palette(m: MeshInstance3D, palette: StringName) -> void:
	var p: Array = PALETTES.get(palette, PALETTES[&"fire"])
	m.set_instance_shader_parameter(&"c_hot", p[0])
	m.set_instance_shader_parameter(&"c_mid", p[1])
	m.set_instance_shader_parameter(&"c_smoke", p[2])


## Shockwave: a refracting ring racing out over a ground disc `size` m wide (High+).
func _shock(pos: Vector3, size: float, dur: float, strength: float) -> void:
	_distort(pos + Vector3.UP * 0.08, size, dur, strength, 0.0)


## Implosion: the ring closes from the rim to the centre (High+).
func _implode(pos: Vector3, size: float, dur: float, strength: float) -> void:
	_distort(pos + Vector3.UP * 0.08, size, dur, strength, 2.0)


## Heat haze: a camera-facing shimmer `w` x `h` m at `pos` for `dur` (High+).
func _haze(pos: Vector3, w: float, h: float, dur: float, strength: float) -> void:
	var s := _take(_distorts, &"distort")
	if s == null:
		return
	s.dur = dur
	s.mode = 1.0
	var m := s.n as MeshInstance3D
	m.rotation = Vector3.ZERO
	m.scale = Vector3(w, h, 1.0)
	m.global_position = pos
	m.set_instance_shader_parameter(&"mode", 1.0)
	m.set_instance_shader_parameter(&"life", 0.0)
	m.set_instance_shader_parameter(&"strength", strength)
	m.set_instance_shader_parameter(&"seed", _rng.randf() * 20.0)
	m.set_instance_shader_parameter(&"tint", Color(0, 0, 0, 0))
	m.visible = true


## Heat haze trailing a projectile (Ultra).
func _haze_follow(node: Node3D, w: float, h: float) -> void:
	var s := _take(_distorts, &"distort")
	if s == null:
		return
	s.follow = node
	s.dur = 0.3
	s.mode = 1.0
	s.ofs = Vector3.UP * 0.2
	var m := s.n as MeshInstance3D
	m.rotation = Vector3.ZERO
	m.scale = Vector3(w, h, 1.0)
	m.global_position = node.global_position
	m.set_instance_shader_parameter(&"mode", 1.0)
	m.set_instance_shader_parameter(&"life", 0.5)
	m.set_instance_shader_parameter(&"strength", 0.012)
	m.set_instance_shader_parameter(&"seed", _rng.randf() * 20.0)
	m.set_instance_shader_parameter(&"tint", Color(0, 0, 0, 0))
	m.visible = true


func _distort(pos: Vector3, size: float, dur: float, strength: float, mode: float) -> void:
	var s := _take(_distorts, &"distort")
	if s == null:
		return
	s.dur = dur
	s.mode = mode
	var m := s.n as MeshInstance3D
	m.rotation = Vector3(-PI * 0.5, 0.0, 0.0)
	m.scale = Vector3(size, size, 1.0)
	m.global_position = pos
	m.set_instance_shader_parameter(&"mode", mode)
	m.set_instance_shader_parameter(&"life", 0.0)
	m.set_instance_shader_parameter(&"strength", strength)
	m.set_instance_shader_parameter(&"seed", _rng.randf() * 20.0)
	m.set_instance_shader_parameter(&"tint", Color(0.05, 0.04, 0.03, 0.0))
	m.visible = true


## A ground mark (kind 0 scorch, 1 frost, 2 void, 3 earth) of radius r: holds `hold` s then fades over `fade` s.
func _mark(pos: Vector3, kind: int, r: float, hold: float, fade: float, heat: float) -> void:
	var s := _take(_marks, &"mark")
	if s == null:
		return
	s.hold = hold
	s.dur = maxf(fade, 0.05)
	s.e0 = heat
	var m := s.n as MeshInstance3D
	m.global_position = Vector3(pos.x, pos.y + 0.035 + 0.004 * float(_next.get(&"mark", 0)), pos.z)
	m.scale = Vector3(r, 1.0, r)
	m.rotation = Vector3(0.0, _rng.randf() * TAU, 0.0)
	m.set_instance_shader_parameter(&"kind", float(kind))
	m.set_instance_shader_parameter(&"fade", 0.0)
	m.set_instance_shader_parameter(&"heat", heat)
	m.set_instance_shader_parameter(&"seed", _rng.randf() * 10.0)
	m.visible = true


func _light(pos: Vector3, col: Color, energy: float, reach: float, time: float, delay: float = 0.0) -> void:
	if _cam and is_instance_valid(_cam) and _cam.global_position.distance_to(pos) > LIGHT_RANGE:
		return
	var s := _take(_lights, &"light")
	if s == null:
		return
	s.dur = maxf(time, 0.08)
	s.delay = delay
	s.e0 = energy
	var l := s.n as OmniLight3D
	l.light_color = col
	l.omni_range = reach
	l.light_energy = 0.0
	l.global_position = pos
	l.visible = delay <= 0.0


func _follow_light(node: Node3D, col: Color, energy: float, reach: float) -> void:
	var s := _take(_lights, &"light")
	if s == null:
		return
	s.follow = node
	s.mode = 1.0
	s.e0 = energy
	s.dur = 999.0
	var l := s.n as OmniLight3D
	l.light_color = col
	l.omni_range = reach
	l.light_energy = energy
	l.global_position = node.global_position
	l.visible = true


func _arc_light(a: Vector3, b: Vector3, arc: float, fly: float, col: Color, energy: float, reach: float) -> void:
	var s := _take(_lights, &"light")
	if s == null:
		return
	s.mode = 2.0
	s.a = a
	s.b = b
	s.arc = arc
	s.fly = fly
	s.e0 = energy
	s.dur = fly
	var l := s.n as OmniLight3D
	l.light_color = col
	l.omni_range = reach
	l.light_energy = energy
	l.global_position = a
	l.visible = true


func _trail(look: StringName, node: Node3D) -> void:
	var want: StringName = look
	var s: Slot = null
	for t in _trails:   # one emitter per look kind: reuse a free one of that look
		if not t.busy and t.n.get_meta(&"look", &"") == want:
			s = _reset(t)
			break
	if s == null:
		return
	s.follow = node
	var p := s.n as GPUParticles3D
	p.global_position = node.global_position
	p.visible = true
	p.emitting = true
	p.restart()


func _burst(look: StringName, pos: Vector3, size: float = 1.0, dir: Vector3 = Vector3.ZERO) -> void:
	if not _bursts.has(look):
		return
	if _cam and is_instance_valid(_cam) and _cam.global_position.distance_to(pos) > PARTICLE_RANGE:
		return
	if _bursts_this_frame >= BURSTS_PER_FRAME:
		return
	_bursts_this_frame += 1
	var pool: Array = _bursts[look]
	var i: int = _burst_next[look]
	_burst_next[look] = (i + 1) % pool.size()
	var p: GPUParticles3D = pool[i]
	var basis := Basis.IDENTITY
	if dir.length_squared() > 0.001:
		var d := dir.normalized()
		var side := d.cross(Vector3.UP)
		if side.length_squared() < 0.001:
			side = Vector3.RIGHT
		side = side.normalized()
		basis = Basis(side, d, side.cross(d).normalized())   # local +Y along the direction
	p.global_transform = Transform3D(basis.scaled(Vector3.ONE * clampf(size, 0.25, 3.0)), pos)
	p.visible = true
	p.restart()
	p.set_meta(&"until", _clock + p.lifetime + 0.15)
	if not _live_bursts.has(p):
		_live_bursts.append(p)


func _throttle(id: StringName, pos: Vector3, ms: int) -> bool:
	var key := "%s:%d:%d" % [id, roundi(pos.x), roundi(pos.z)]
	var now := Time.get_ticks_msec()
	if now - int(_last_play.get(key, -100000)) < ms:
		return false
	_last_play[key] = now
	if _last_play.size() > 256:
		_last_play.clear()
	return true


## Fog rule: the local team's own effects always show; any other team's (or an unknown team's, -1) only where the
## local team sees the point (FogOfWar.is_visible). No fog in the level = everything shows.
func _fog_ok(team: int, pos: Vector3) -> bool:
	if not is_instance_valid(_fog) and is_inside_tree():
		_fog = get_tree().get_first_node_in_group(&"fog")
	if not is_instance_valid(_fog):
		return true
	if not bool(_fog.get(&"enabled")):
		return true
	var local: Variant = _fog.get(&"local_team")
	if local == null or (team >= 0 and int(local) == team) or not _fog.has_method(&"is_visible"):
		return true
	return bool(_fog.call(&"is_visible", int(local), pos))


# ---------------------------------------------------------------- shared resources (built once)

func _build_shared() -> void:
	var q := clampi(tier_built, TIER_MEDIUM, TIER_ULTRA)
	_sphere = SphereMesh.new()
	_sphere.radius = 0.5
	_sphere.height = 1.0
	_sphere.radial_segments = 32 if q >= TIER_ULTRA else 24
	_sphere.rings = 16 if q >= TIER_ULTRA else 12
	_quad = QuadMesh.new()
	_quad.size = Vector2(1.0, 1.0)
	_plane = PlaneMesh.new()
	_plane.size = Vector2(2.0, 2.0)
	_billow_mat = ShaderMaterial.new()
	_billow_mat.shader = BILLOW_SHADER
	_distort_mat = ShaderMaterial.new()
	_distort_mat.shader = DISTORT_SHADER
	_mark_mat = ShaderMaterial.new()
	_mark_mat.shader = MARK_SHADER
	for i in int(CAPS[&"billow"][q]):
		_billows.append(_slot(_mesh_node(_sphere, _billow_mat, "Billow%d" % i, 4.0)))
	for i in int(CAPS[&"distort"][q]):
		_distorts.append(_slot(_mesh_node(_quad, _distort_mat, "Distort%d" % i, 6.0)))
	for i in int(CAPS[&"mark"][q]):
		_marks.append(_slot(_mesh_node(_plane, _mark_mat, "Mark%d" % i, 0.5)))
	for i in int(CAPS[&"light"][q]):
		var l := OmniLight3D.new()
		l.name = "Light%d" % i
		l.shadow_enabled = false
		l.light_specular = 0.35
		l.omni_attenuation = 1.4
		l.distance_fade_enabled = true
		l.distance_fade_begin = 70.0
		l.distance_fade_length = 20.0
		l.visible = false
		add_child(l)
		_lights.append(_slot(l))
	_build_passes(q)
	for look: StringName in LOOKS:
		var spec: Array = LOOKS[look]
		var arr: Array = []
		for i in BURST_POOL[q]:
			var p := _emitter(look, maxi(2, int(float(spec[0]) * AMOUNT_MULT[q])), float(spec[1]), spec[2])
			p.one_shot = true
			p.explosiveness = float(spec[3])
			add_child(p)
			arr.append(p)
		_bursts[look] = arr
		_burst_next[look] = 0
	var per_kind := maxi(1, int(CAPS[&"trail"][q]) / TRAILS.size() + 1)
	for look: StringName in TRAILS:
		var spec: Array = TRAILS[look]
		for i in per_kind:
			var p := _emitter(look, maxi(4, int(float(spec[0]) * AMOUNT_MULT[q])), float(spec[1]), spec[2])
			p.one_shot = false
			p.explosiveness = 0.0
			p.set_meta(&"look", look)
			add_child(p)
			_trails.append(_slot(p))


func _slot(n: Node3D) -> Slot:
	var s := Slot.new()
	s.n = n
	return s


func _mesh_node(mesh: Mesh, mat: Material, nm: String, margin: float) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = nm
	m.mesh = mesh
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	m.extra_cull_margin = margin
	m.visible = false
	add_child(m)
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
	p.visibility_aabb = AABB(Vector3(-8, -3, -8), Vector3(16, 14, 16))
	p.visibility_range_end = PARTICLE_RANGE + 10.0
	if pass_id == &"streak":
		p.transform_align = GPUParticles3D.TRANSFORM_ALIGN_Z_BILLBOARD_Y_TO_VELOCITY
	return p


func _build_passes(q: int) -> void:
	var soft := _soft_tex()
	var smoke := _smoke_tex()
	var petal := _petal_tex()
	_passes[&"soft_add"] = _billboard(soft, BaseMaterial3D.BLEND_MODE_ADD, Vector2(0.3, 0.3), false)
	_passes[&"smoke"] = _billboard(smoke, BaseMaterial3D.BLEND_MODE_MIX, Vector2(1.0, 1.0), q >= TIER_HIGH)
	_passes[&"petal"] = _billboard(petal, BaseMaterial3D.BLEND_MODE_MIX, Vector2(0.22, 0.15), false)
	var streak := QuadMesh.new()
	streak.size = Vector2(0.07, 0.75)
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	sm.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	sm.vertex_color_use_as_albedo = true
	sm.albedo_texture = soft
	sm.cull_mode = BaseMaterial3D.CULL_DISABLED
	streak.material = sm
	_passes[&"streak"] = streak
	var chunk := BoxMesh.new()
	chunk.size = Vector3(0.16, 0.12, 0.14)
	var cm := StandardMaterial3D.new()
	cm.vertex_color_use_as_albedo = true
	cm.roughness = 0.95
	chunk.material = cm
	_passes[&"chunk"] = chunk
	var glow := BoxMesh.new()
	glow.size = Vector3(0.13, 0.1, 0.12)
	var gm := StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.vertex_color_use_as_albedo = true
	glow.material = gm
	_passes[&"chunk_glow"] = glow
	var shard := PrismMesh.new()
	shard.size = Vector3(0.14, 0.48, 0.1)
	var shm := StandardMaterial3D.new()
	shm.vertex_color_use_as_albedo = true
	shm.roughness = 0.12
	shm.metallic_specular = 0.9
	shm.emission_enabled = true
	shm.emission = Color(0.18, 0.42, 0.62)
	shm.rim_enabled = true
	shm.rim = 0.6
	shard.material = shm
	_passes[&"shard"] = shard


func _billboard(tex: Texture2D, blend: BaseMaterial3D.BlendMode, size: Vector2, soft_edges: bool) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = size
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = blend
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = tex
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.billboard_keep_scale = true
	if soft_edges:
		m.proximity_fade_enabled = true
		m.proximity_fade_distance = 0.6
	q.material = m
	return q


func _soft_tex() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.25, 0.6, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.75), Color(1, 1, 1, 0.18), Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(0.5, 0.0)
	t.width = 64
	t.height = 64
	return t


## A soft cloudy puff (value noise inside a round falloff), 64 x 64, made once.
func _smoke_tex() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var u := (float(x) + 0.5) / 32.0 - 1.0
			var v := (float(y) + 0.5) / 32.0 - 1.0
			var d := sqrt(u * u + v * v)
			var n := 0.55 * _vn(float(x) / 9.0, float(y) / 9.0) + 0.3 * _vn(float(x) / 4.5 + 7.0, float(y) / 4.5 + 3.0) \
					+ 0.15 * _vn(float(x) / 2.2 + 1.0, float(y) / 2.2 + 9.0)
			var a := pow(clampf(1.0 - smoothstep(0.0, 1.0, d + (n - 0.5) * 0.35), 0.0, 1.0), 1.4)
			var shade := 0.82 + 0.18 * n
			img.set_pixel(x, y, Color(shade, shade, shade, a * (0.6 + 0.4 * n)))
	return ImageTexture.create_from_image(img)


func _petal_tex() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in 32:
		for x in 32:
			var u := ((float(x) + 0.5) / 16.0 - 1.0) / 0.95
			var v := ((float(y) + 0.5) / 16.0 - 1.0) / 0.6
			var d := sqrt(u * u + v * v)
			var a := clampf((1.0 - d) * 4.0, 0.0, 1.0)
			var vein := 1.0 - 0.25 * clampf(1.0 - absf(v) * 8.0, 0.0, 1.0)
			img.set_pixel(x, y, Color(vein, vein, vein, a))
	return ImageTexture.create_from_image(img)


func _vn(x: float, y: float) -> float:
	var ix := floorf(x)
	var iy := floorf(y)
	var fx := x - ix
	var fy := y - iy
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	var a := _h2(ix, iy)
	var b := _h2(ix + 1.0, iy)
	var c := _h2(ix, iy + 1.0)
	var d := _h2(ix + 1.0, iy + 1.0)
	return lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fy)


func _h2(x: float, y: float) -> float:
	var s := sin(x * 127.1 + y * 311.7) * 43758.5453
	return s - floorf(s)


# ---------------------------------------------------------------- particle looks

func _pmat(look: StringName) -> ParticleProcessMaterial:
	if _pmats.has(look):
		return _pmats[look]
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = 0.2
	m.direction = Vector3.UP
	m.gravity = Vector3.ZERO
	match look:
		&"ember_burst", &"ember_small":
			m.emission_sphere_radius = 0.35
			m.spread = 75.0
			m.initial_velocity_min = 5.0 if look == &"ember_burst" else 2.5
			m.initial_velocity_max = 13.0 if look == &"ember_burst" else 6.0
			m.gravity = Vector3(0, -9.0, 0)
			m.damping_min = 1.0
			m.damping_max = 2.5
			_size(m, 0.5, 1.2, [Vector2(0, 1.0), Vector2(0.7, 0.8), Vector2(1, 0.0)])
			m.color_ramp = _ramp([Color(8.0, 5.5, 2.4, 1), Color(5.0, 1.8, 0.3, 1), Color(2.0, 0.35, 0.05, 0.8), Color(0.4, 0.05, 0.0, 0)])
		&"fire_debris":
			m.emission_sphere_radius = 0.4
			m.spread = 60.0
			m.initial_velocity_min = 4.0
			m.initial_velocity_max = 9.0
			m.gravity = Vector3(0, -15.0, 0)
			m.angular_velocity_min = -540.0
			m.angular_velocity_max = 540.0
			m.particle_flag_rotate_y = true
			_size(m, 0.5, 1.4, [Vector2(0, 1.0), Vector2(1, 0.7)])
			m.color_ramp = _ramp([Color(6.0, 2.2, 0.4, 1), Color(1.4, 0.3, 0.05, 1), Color(0.06, 0.045, 0.04, 1), Color(0.05, 0.04, 0.035, 1)])
		&"smoke_plume":
			m.emission_sphere_radius = 0.9
			m.spread = 30.0
			m.initial_velocity_min = 1.2
			m.initial_velocity_max = 3.0
			m.gravity = Vector3(0, 0.5, 0)
			m.damping_min = 0.6
			m.damping_max = 1.2
			m.angle_min = -180.0
			m.angle_max = 180.0
			m.angular_velocity_min = -25.0
			m.angular_velocity_max = 25.0
			_size(m, 1.2, 2.0, [Vector2(0, 0.6), Vector2(0.4, 1.4), Vector2(1, 2.6)])
			m.color_ramp = _ramp([Color(0.35, 0.18, 0.08, 0.0), Color(0.16, 0.12, 0.1, 0.5), Color(0.13, 0.12, 0.11, 0.36), Color(0.12, 0.12, 0.12, 0)])
		&"ash_rise":
			m.emission_sphere_radius = 1.4
			m.spread = 25.0
			m.initial_velocity_min = 0.6
			m.initial_velocity_max = 1.8
			m.gravity = Vector3(0, 0.4, 0)
			m.turbulence_enabled = true
			m.turbulence_noise_strength = 1.2
			m.turbulence_noise_scale = 2.5
			m.turbulence_influence_min = 0.05
			m.turbulence_influence_max = 0.15
			_size(m, 0.12, 0.3, [Vector2(0, 1.0), Vector2(1, 0.2)])
			m.color_ramp = _ramp([Color(4.0, 1.4, 0.25, 1), Color(2.2, 0.55, 0.08, 1), Color(0.6, 0.1, 0.02, 0)])
		&"fire_ring":
			_ring_shape(m, 1.0, 0.1)
			m.direction = Vector3(0, 1, 0)
			m.spread = 20.0
			m.initial_velocity_min = 2.0
			m.initial_velocity_max = 4.5
			m.radial_velocity_min = 1.5
			m.radial_velocity_max = 3.5
			m.damping_min = 2.0
			m.damping_max = 4.0
			m.gravity = Vector3(0, 1.0, 0)
			_size(m, 0.5, 0.9, [Vector2(0, 0.5), Vector2(0.25, 1.0), Vector2(1, 0.0)])
			m.color_ramp = _ramp([Color(3.5, 1.7, 0.5, 1), Color(2.2, 0.6, 0.08, 0.85), Color(0.7, 0.12, 0.02, 0.4), Color(0.1, 0.03, 0.01, 0)])
		&"void_in":
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE_SURFACE
			m.emission_sphere_radius = 2.6
			m.spread = 180.0
			m.initial_velocity_min = 0.0
			m.initial_velocity_max = 0.5
			m.radial_accel_min = -22.0
			m.radial_accel_max = -14.0
			_size(m, 0.5, 1.0, [Vector2(0, 0.2), Vector2(0.4, 1.0), Vector2(1, 0.0)])
			m.color_ramp = _ramp([Color(0.5, 0.15, 1.2, 0), Color(1.6, 0.5, 3.2, 1), Color(0.6, 0.1, 1.2, 0.8), Color(0.05, 0.0, 0.1, 0)])
		&"void_sparks":
			m.emission_sphere_radius = 0.25
			m.spread = 55.0
			m.initial_velocity_min = 5.0
			m.initial_velocity_max = 11.0
			m.damping_min = 4.0
			m.damping_max = 8.0
			m.gravity = Vector3(0, -2.0, 0)
			_size(m, 0.5, 1.0, [Vector2(0, 1.0), Vector2(1, 0.0)])
			m.color_ramp = _ramp([Color(3.0, 1.6, 4.5, 1), Color(1.4, 0.35, 2.8, 1), Color(0.3, 0.02, 0.6, 0)])
		&"void_smoke":
			m.emission_sphere_radius = 0.7
			m.spread = 60.0
			m.initial_velocity_min = 0.5
			m.initial_velocity_max = 1.5
			m.gravity = Vector3(0, 0.7, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			_size(m, 1.0, 1.6, [Vector2(0, 0.5), Vector2(0.5, 1.2), Vector2(1, 1.8)])
			m.color_ramp = _ramp([Color(0.05, 0.0, 0.08, 0), Color(0.06, 0.01, 0.1, 0.55), Color(0.12, 0.03, 0.2, 0.3), Color(0.1, 0.02, 0.16, 0)])
		&"ice_shards":
			m.emission_sphere_radius = 0.5
			m.spread = 50.0
			m.initial_velocity_min = 4.0
			m.initial_velocity_max = 8.5
			m.gravity = Vector3(0, -16.0, 0)
			m.angular_velocity_min = -720.0
			m.angular_velocity_max = 720.0
			m.particle_flag_rotate_y = true
			_size(m, 0.6, 1.4, [Vector2(0, 1.0), Vector2(0.8, 1.0), Vector2(1, 0.0)])
			m.color_ramp = _ramp([Color(0.75, 0.92, 1.1, 1), Color(0.5, 0.78, 1.0, 1), Color(0.4, 0.65, 0.9, 1)])
		&"frost_mist", &"dust_ring":
			_ring_shape(m, 0.6, 0.1)
			m.direction = Vector3(0, 1, 0)
			m.spread = 15.0
			m.initial_velocity_min = 0.2
			m.initial_velocity_max = 0.7
			m.radial_velocity_min = 2.5
			m.radial_velocity_max = 5.0
			m.damping_min = 2.0
			m.damping_max = 3.5
			m.angle_min = -180.0
			m.angle_max = 180.0
			_size(m, 1.0, 1.8, [Vector2(0, 0.5), Vector2(0.5, 1.3), Vector2(1, 2.0)])
			if look == &"frost_mist":
				m.radial_velocity_min = 1.2
				m.radial_velocity_max = 2.6
				m.color_ramp = _ramp([Color(0.75, 0.88, 1.0, 0), Color(0.72, 0.86, 1.0, 0.24), Color(0.66, 0.8, 0.95, 0.12), Color(0.6, 0.75, 0.9, 0)])
			else:
				m.radial_velocity_min = 1.5
				m.radial_velocity_max = 3.0
				m.color_ramp = _ramp([Color(0.26, 0.2, 0.12, 0), Color(0.25, 0.19, 0.11, 0.38), Color(0.24, 0.19, 0.12, 0.18), Color(0.22, 0.18, 0.12, 0)])
		&"ice_glints":
			m.emission_sphere_radius = 1.8
			m.spread = 40.0
			m.initial_velocity_min = 0.5
			m.initial_velocity_max = 2.0
			m.gravity = Vector3(0, 0.6, 0)
			_size(m, 0.25, 0.6, [Vector2(0, 0.0), Vector2(0.15, 1.0), Vector2(0.35, 0.3), Vector2(0.55, 1.0), Vector2(1, 0.0)])
			m.color_ramp = _ramp([Color(1.2, 1.6, 2.0, 1), Color(0.8, 1.2, 1.8, 1), Color(0.5, 0.8, 1.2, 0)])
		&"earth_debris":
			m.emission_sphere_radius = 0.6
			m.spread = 45.0
			m.initial_velocity_min = 3.5
			m.initial_velocity_max = 8.0
			m.gravity = Vector3(0, -15.0, 0)
			m.angular_velocity_min = -540.0
			m.angular_velocity_max = 540.0
			m.particle_flag_rotate_y = true
			_size(m, 0.6, 1.5, [Vector2(0, 1.0), Vector2(1, 0.8)])
			m.color_ramp = _ramp([Color(0.30, 0.22, 0.13, 1), Color(0.24, 0.18, 0.11, 1), Color(0.2, 0.16, 0.1, 1)])
		&"leaf_burst":
			m.emission_sphere_radius = 0.6
			m.spread = 70.0
			m.initial_velocity_min = 2.5
			m.initial_velocity_max = 5.5
			m.gravity = Vector3(0, -2.2, 0)
			m.damping_min = 2.0
			m.damping_max = 3.0
			m.angle_min = -180.0
			m.angle_max = 180.0
			m.angular_velocity_min = -300.0
			m.angular_velocity_max = 300.0
			_size(m, 0.8, 1.4, [Vector2(0, 1.0), Vector2(0.8, 1.0), Vector2(1, 0.0)])
			m.color_ramp = _ramp([Color(0.55, 0.85, 0.25, 1), Color(0.4, 0.7, 0.18, 1), Color(0.55, 0.6, 0.2, 0)])
		&"petal_spiral":
			_ring_shape(m, 1.0, 0.1)
			m.spread = 15.0
			m.initial_velocity_min = 0.8
			m.initial_velocity_max = 2.0
			m.orbit_velocity_min = 0.15
			m.orbit_velocity_max = 0.3
			m.gravity = Vector3(0, 0.4, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			m.angular_velocity_min = -200.0
			m.angular_velocity_max = 200.0
			_size(m, 0.8, 1.3, [Vector2(0, 0.0), Vector2(0.15, 1.0), Vector2(0.85, 1.0), Vector2(1, 0.0)])
			m.color_ramp = _ramp([Color(1.0, 0.86, 0.9, 1), Color(1.0, 0.92, 0.6, 1), Color(0.95, 0.75, 0.85, 0.9), Color(1.0, 0.9, 0.7, 0)])
		&"spores":
			m.emission_sphere_radius = 1.6
			m.spread = 40.0
			m.initial_velocity_min = 0.3
			m.initial_velocity_max = 0.9
			m.gravity = Vector3(0, 0.25, 0)
			m.turbulence_enabled = true
			m.turbulence_noise_strength = 1.0
			m.turbulence_noise_scale = 3.0
			m.turbulence_influence_min = 0.05
			m.turbulence_influence_max = 0.12
			_size(m, 0.18, 0.4, [Vector2(0, 0.0), Vector2(0.2, 1.0), Vector2(1, 0.0)])
			m.color_ramp = _ramp([Color(2.2, 1.9, 0.7, 1), Color(1.4, 1.5, 0.5, 1), Color(0.8, 1.0, 0.3, 0)])
		&"steam_puff":
			m.emission_sphere_radius = 0.4
			m.spread = 80.0
			m.initial_velocity_min = 1.0
			m.initial_velocity_max = 2.4
			m.damping_min = 2.0
			m.damping_max = 3.0
			m.gravity = Vector3(0, 1.2, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			_size(m, 0.7, 1.2, [Vector2(0, 0.4), Vector2(1, 1.6)])
			m.color_ramp = _ramp([Color(0.9, 0.95, 1.0, 0.5), Color(0.82, 0.9, 1.0, 0.3), Color(0.8, 0.86, 0.95, 0)])
		&"trail_fire_g":
			m.emission_sphere_radius = 0.22
			m.spread = 180.0
			m.initial_velocity_min = 0.6
			m.initial_velocity_max = 2.2
			m.gravity = Vector3(0, -4.0, 0)
			_size(m, 0.35, 0.7, [Vector2(0, 1.0), Vector2(1, 0.0)])
			m.color_ramp = _ramp([Color(7.0, 4.0, 1.4, 1), Color(3.0, 0.9, 0.12, 1), Color(0.6, 0.1, 0.0, 0)])
		&"trail_void_g":
			m.emission_sphere_radius = 0.25
			m.spread = 180.0
			m.initial_velocity_min = 0.2
			m.initial_velocity_max = 0.8
			_size(m, 0.6, 1.1, [Vector2(0, 1.0), Vector2(1, 0.0)])
			m.color_ramp = _ramp([Color(1.4, 0.4, 2.8, 1), Color(0.5, 0.08, 1.0, 0.8), Color(0.05, 0.0, 0.1, 0)])
		&"trail_frost_g":
			m.emission_sphere_radius = 0.25
			m.spread = 180.0
			m.initial_velocity_min = 0.2
			m.initial_velocity_max = 0.9
			m.gravity = Vector3(0, -1.0, 0)
			_size(m, 0.25, 0.55, [Vector2(0, 1.0), Vector2(0.5, 0.4), Vector2(0.7, 1.0), Vector2(1, 0.0)])
			m.color_ramp = _ramp([Color(1.1, 1.5, 1.9, 1), Color(0.6, 0.95, 1.4, 0.9), Color(0.4, 0.7, 1.0, 0)])
	_pmats[look] = m
	return m


func _ring_shape(m: ParticleProcessMaterial, r: float, h: float) -> void:
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	m.emission_ring_axis = Vector3.UP
	m.emission_ring_radius = r
	m.emission_ring_inner_radius = r * 0.85
	m.emission_ring_height = h


func _size(m: ParticleProcessMaterial, lo: float, hi: float, pts: Array) -> void:
	m.scale_min = lo
	m.scale_max = hi
	var c := Curve.new()
	c.max_value = 3.0
	for p: Vector2 in pts:
		c.add_point(p)
	var t := CurveTexture.new()
	t.curve = c
	m.scale_curve = t


func _ramp(colors: Array) -> GradientTexture1D:
	var g := Gradient.new()
	var offs := PackedFloat32Array()
	var cols := PackedColorArray()
	for i in colors.size():
		offs.append(float(i) / float(colors.size() - 1))
		cols.append(colors[i])
	g.offsets = offs
	g.colors = cols
	var t := GradientTexture1D.new()
	t.gradient = g
	t.use_hdr = true
	return t
