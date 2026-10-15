class_name CombatFxG
extends Node3D
## G-D combat feedback layer (docs/art/gd_combat_feedback.md). CombatVfx creates ONE of these as its child and
## calls it from its own hooks (melee hits, projectile ends, deaths, building hits / destruction); it never hooks
## gameplay itself. Medium / High / Ultra only: at Low (every headless / -s run) it builds nothing and
## CombatVfx keeps its pre-G look, so tests and labs are unchanged.
##
## What it draws (all non-gory: dust, sparks, splinters, shards, embers, leaves, wisps):
##   melee / projectile hits   a response per TARGET material (steel sparks, flesh = dust, bone chips, wood
##                             splinters, ice shards + glints, stone chips + dust) + a few streaks in the
##                             attacker's kingdom colour (hit identity); arrows add a broken-shaft splinter.
##   unit deaths               per kingdom: Fire embers rising off the sinking body + scorch, Ice shards that land and
##                             melt + frost star, Nature leaves that settle + spores + leaf litter, Shadow wisps
##                             dissolving upward + ink stain, neutral dust. The ground mark fades after ~7 s.
##   building stages           crossing 66 % / 33 % HP: a crack (debris falls off the top, dust, sparks); below
##                             66 % smoke and below 33 % fire + embers for buildings whose model has no damage
##                             stages of its own (keeps / halls / towers that do keep theirs and only get embers).
##   building collapse         dust ring + rising dust column, debris falling off the walls, embers, a rubble
##                             pile + rubble stain that stay ~30 s and sink / fade away.
##                             Off-screen (fog-visible) collapses skip the dust / debris burst but still lay the
##                             rubble pile + stain, so panning back shows the ruin.
##
## Cost: NO node per event. Six MultiMeshes (one draw call each: sparks, mixed puffs, glowing puffs, chips,
## rubble, ground marks) are ring buffers; an effect writes its instances ONCE and the shaders fly them from one
## `now` uniform (ballistic flight, drag, ground rest, fade), so live effects cost no per-frame CPU. Caps: events
## per frame by tier (EVENTS_PER_FRAME), instances per frame (INSTANCES_PER_FRAME), at most BURN_MAX burning
## buildings, chips skipped beyond CHIP_CULL_DISTANCE, ring buffers overwrite their oldest pieces under load.
## Fog (VfxFog): every spawn is gated with its source team; ground marks (long-lived, transparent) re-check at
## VfxFog.RECHECK and hide while the fog covers them; rubble chips are opaque (the fog overlay covers them).

const GROUP := &"combat_fx_g"
const RIG_GROUP := &"lighting_rigs"   # GameSettings.apply_graphics -> set_quality(q) on a Settings change

## Tests / shots: >= 0 forces a tier (GameSettings.GFX_*), -1 = GameSettings.effective_graphics_quality().
static var test_tier := -1
## Shots: true = the layer is off at every tier (the "before" frames).
static var force_off := false

enum Sys { SPARK, PUFF, GLOW, CHIP, RUBBLE, MARK }
const CAPS: Array[int] = [2048, 1024, 512, 1024, 512, 192]
const SHADERS: Array[String] = ["res://art/vfx/combat_g/cg_spark.gdshader", "res://art/vfx/combat_g/cg_puff_mix.gdshader",
		"res://art/vfx/combat_g/cg_puff_add.gdshader", "res://art/vfx/combat_g/cg_chunk.gdshader",
		"res://art/vfx/combat_g/cg_chunk.gdshader", "res://art/vfx/combat_g/cg_mark.gdshader"]

## Hit materials (what the TARGET is made of).
enum Mat { FLESH, STEEL, BONE, WOOD, ICE, STONE }
const MAT_NAMES: Array[StringName] = [&"flesh", &"steel", &"bone", &"wood", &"ice", &"stone"]
## Unit id keywords, checked in this order (first match wins); no match: armor >= 15 = steel, else flesh.
const MAT_KEYS: Array = [
	# Beasts and camp creatures: hide (an armored beast is not steel).
	[Mat.FLESH, ["tusker", "direwolf", "grizzlemaw", "scarback", "bristleback", "mirefang", "roc", "hollow_stag",
			"spirit_wolf", "stagrunner", "magpie"]],
	[Mat.WOOD, ["sapling", "sprigling", "thornling", "bramblehorn", "greenheart", "treant", "gloomcap", "vinelasher",
			"caravan"]],
	[Mat.ICE, ["rimeling", "rime_colossus", "frost_wyrm", "frost_dragon", "shardguard"]],
	[Mat.STONE, ["ruin_warden", "golem", "sentinel"]],
	[Mat.STEEL, ["knight", "guard", "shield", "lancer", "cataphract", "juggernaut", "reaver", "dreadrider",
			"oathwall", "torren"]],
	[Mat.BONE, ["barrow", "grave_hound", "gloom_thrall", "shade", "mother_hush", "hollow_oathsworn"]],
]
## Shooters whose projectiles are physical (arrows, bolts, stones): their impact adds a broken shaft / pebble.
const PHYSICAL_KEYS: Array[String] = ["bow", "archer", "slinger", "darter", "arbalest", "hurler", "tower", "tracker"]
## Shooters that match PHYSICAL_KEYS but fire magic bolts (no broken shaft).
const MAGIC_KEYS: Array[String] = ["magebow"]


## True when a shooter with this unit / building id fires a physical projectile.
static func is_physical_id(id: String) -> bool:
	for key: String in MAGIC_KEYS:
		if id.contains(key):
			return false
	for key: String in PHYSICAL_KEYS:
		if id.contains(key):
			return true
	return false

## Per tier (index = GameSettings tier 0-3).
const EVENTS_PER_FRAME: Array[int] = [0, 14, 22, 30]       # hits / impacts per frame (deaths are not capped by it)
const CHIP_SCALE: Array[float] = [0.0, 0.6, 1.0, 1.35]     # piece count multiplier
const INSTANCES_PER_FRAME := 420
const DEATHS_PER_FRAME := 10            # full deaths per frame; more = ground mark only
const CHIP_CULL_DISTANCE := 55.0        # metres from the camera: farther hits draw sparks / puffs, no chips
const BURN_MAX := 24
const BURN_TICK := 0.25
const STAGE_1 := 0.66
const STAGE_2 := 0.33
const MARK_LIFE := 7.0
const RUBBLE_LIFE := 32.0

## Material palettes (albedo; chips' alpha = gloss).
const STEEL_SPARK := Color(2.4, 1.75, 0.85, 1.0)
const FLESH_DUST := Color(0.66, 0.58, 0.47, 0.7)
const FLESH_FLECK := Color(0.42, 0.34, 0.26, 0.0)
const BONE_CHIP := Color(0.86, 0.82, 0.7, 0.25)
const BONE_DUST := Color(0.75, 0.72, 0.66, 0.45)
const WOOD_CHIP := Color(0.48, 0.32, 0.17, 0.05)
const WOOD_DUST := Color(0.62, 0.5, 0.32, 0.45)
const ICE_CHIP := Color(0.62, 0.86, 1.0, 1.0)
const ICE_GLINT := Color(0.55, 1.05, 1.45, 0.9)
const ICE_STEAM := Color(0.62, 0.8, 0.95, 0.32)
const STONE_DUST := Color(0.6, 0.56, 0.5, 0.55)
const EMBER := Color(2.1, 0.85, 0.22, 1.0)
const SMOKE := Color(0.17, 0.15, 0.14, 0.55)

var _tier := 0
var _built := false
var _mm: Array[MultiMesh] = []
var _mmi: Array[MultiMeshInstance3D] = []
var _mats: Array[ShaderMaterial] = []
var _ring := PackedInt32Array()
var _written := PackedInt32Array()
var _alive_until := PackedFloat32Array()
var _clock := 0.0
var _events_left := 0
var _deaths_left := 0
var _inst_left := INSTANCES_PER_FRAME
var _rng := RandomNumberGenerator.new()
var _cam: Camera3D
var _cam_pos := Vector3.ZERO

# Ground marks: per slot (fog re-check).
var _mk_pos := PackedVector3Array()
var _mk_team := PackedInt32Array()
var _mk_col := PackedColorArray()
var _mk_end := PackedFloat32Array()
var _mk_shown := PackedByteArray()
var _fog_left := 0.0
var _anchor := Vector3.INF

# Damaged buildings: Building -> stage (1 / 2); ticked at BURN_TICK.
var _stage: Dictionary = {}
var _burning: Array[Node3D] = []
var _burn_left := 0.0

# Counters (tests, shots).
var _n_events := 0
var _n_skipped := 0
var _n_instances := 0
var _n_deaths := 0
var _n_collapses := 0
var _n_cracks := 0


func _ready() -> void:
	add_to_group(GROUP)
	add_to_group(RIG_GROUP)
	top_level = true
	global_transform = Transform3D.IDENTITY
	_rng.seed = 7351
	set_quality(GameSettings.effective_graphics_quality())


## The tier in use (test_tier first).
static func tier_now() -> int:
	if test_tier >= 0:
		return test_tier
	return GameSettings.effective_graphics_quality()


## GameSettings.apply_graphics (group "lighting_rigs"): Low turns the layer off (nothing built until first needed).
func set_quality(q: int) -> void:
	_tier = clampi(test_tier if test_tier >= 0 else q, 0, 3)
	if _tier >= 1 and not force_off and not _built:
		_build()
	for mmi in _mmi:
		mmi.visible = active()


## True when this layer draws (Medium+ and built); CombatVfx keeps its old look otherwise.
func active() -> bool:
	return _built and _tier >= 1 and not force_off


func stats() -> Dictionary:
	var live := 0
	for s in _mm.size():
		if _alive_until[s] > _clock:
			live += 1
	return {"tier": _tier, "active": active(), "events": _n_events, "skipped": _n_skipped, "instances": _n_instances,
			"deaths": _n_deaths, "collapses": _n_collapses, "cracks": _n_cracks, "burning": _burning.size(),
			"live_systems": live, "marks_shown": _marks_shown()}


## Instances written per system since start (tests).
func written(sys: int) -> int:
	return _written[sys] if sys < _written.size() else 0


func _process(delta: float) -> void:
	if not active():
		return
	_clock += delta
	for m in _mats:
		m.set_shader_parameter(&"now", _clock)
	_events_left = EVENTS_PER_FRAME[_tier]
	_deaths_left = DEATHS_PER_FRAME
	_inst_left = INSTANCES_PER_FRAME
	_cam = get_viewport().get_camera_3d()
	if _cam:
		_cam_pos = _cam.global_position
	for s in _mm.size():
		if _mm[s].visible_instance_count > 0 and _clock > _alive_until[s]:
			_mm[s].visible_instance_count = 0   # everything ended: draw nothing (and the fog test sees nothing)
	_fog_left -= delta
	if _fog_left <= 0.0:
		_fog_left = VfxFog.RECHECK
		_recheck_marks()
	_burn_left -= delta
	if _burn_left <= 0.0:
		_burn_left = BURN_TICK
		_tick_burning()


# ================================================================ public hooks (CombatVfx calls these)

## Melee blow landed: `pos` = the hit point on the target, `dir` = blow direction (flat), `k` = attacker kingdom
## (CombatVfx.Kind), `glow` = that kingdom's glow colour, `team` = attacker team (fog).
func melee_hit(pos: Vector3, dir: Vector3, target: Node3D, heavy: bool, glow: Color, team: int) -> void:
	if not _take_event(pos, team):
		return
	var mat := material_of(target)
	var ground := _ground_of(target, pos)
	var s := (1.3 if heavy else 1.0) * _zoom_scale(pos)
	_material_burst(mat, pos, dir, s, ground, 1.0)
	# Hit identity: two streaks in the attacker's kingdom colour along the blow.
	for i in 2:
		_spark(pos, _cone(Vector3.UP * 0.8 + dir * 0.5, 0.7, 4.0, 8.0), 0.035 * s, 12.0, 5.0, 0.045, _rng.randf_range(0.2, 0.3),
				Color(glow.r * 1.3, glow.g * 1.3, glow.b * 1.3, 1.0), 0.0, 0.0, ground)


## A non-splash projectile ended at `pos`: `target` = what it hit (null = the ground / its target died),
## `dir` = its flight direction (flat), `physical` = arrow / bolt / stone (else a magic bolt in `glow`).
func projectile_impact(pos: Vector3, dir: Vector3, target: Node3D, physical: bool, glow: Color, team: int) -> void:
	if not _take_event(pos, team):
		return
	var s := 0.8 * _zoom_scale(pos)
	var ground := _ground_of(target, pos) if target else pos.y - 1.0
	if target and is_instance_valid(target) and not _is_building(target):
		_material_burst(material_of(target), pos, dir, s, ground, 0.7)
	elif target == null:
		ground = _ground_y(pos)
		var g := Vector3(pos.x, ground + 0.05, pos.z)
		_puff(Sys.PUFF, g, Vector3(0, 0.6, 0) - dir * 0.6, 0.35 * s, -0.5, 2.5, 0.7, 1.4, STONE_DUST, 0.0, 0.15, 0.7, ground)
		_chips(g, -dir, 2, 0.05, 2.5, 4.5, Color(0.36, 0.31, 0.25, 0.0), 1.0, 0.0, ground, 0.6)
	if physical:   # the shaft breaks: two light splinters
		_chips(pos, -dir, 2, 0.045 * s, 2.0, 4.0, Color(0.66, 0.52, 0.32, 0.05), 3.5, 0.0, ground, 0.6)
	else:
		for i in 3:
			_spark(pos, _cone(-dir + Vector3.UP * 0.6, 0.9, 2.5, 5.5), 0.035 * s, 9.0, 5.0, 0.04,
					_rng.randf_range(0.2, 0.32), Color(glow.r * 1.4, glow.g * 1.4, glow.b * 1.4, 1.0), 0.0, 0.0, ground)


## A unit died (`k` = its kingdom, CombatVfx.Kind order fire / shadow / ice / nature / neutral). The kit sinks the
## body over 1 s (CharacterModel death); this adds the kingdom's dissolve over that second + a ground mark.
func unit_death(u: Node3D, k: int, hero: bool, team: int) -> void:
	if not active() or not is_instance_valid(u):
		return
	var pos := u.global_position
	if not VfxFog.ok(team, pos):
		_n_skipped += 1
		return
	var h := _height(u)
	var r := clampf(Unit.radius_of(u), 0.35, 2.5)
	var s := (1.8 if hero else clampf(h / 1.6, 0.8, 1.4)) * _zoom_scale(pos)
	var ground := pos.y
	_n_deaths += 1
	# Ground mark (always, even past the per-frame cap: cheap and it tells where the line broke).
	var mark_kind: int = [0, 3, 1, 2, 5][clampi(k, 0, 4)]
	var mark_col: Color = [Color(0.2, 0.14, 0.1, 0.6), Color(0.12, 0.06, 0.18, 0.7), Color(0.82, 0.92, 1.0, 0.55),
			Color(0.34, 0.48, 0.16, 0.95), Color(0.45, 0.4, 0.33, 0.5)][clampi(k, 0, 4)]
	_mark(Vector3(pos.x, ground + 0.045, pos.z), (r * 1.6 + 0.35) * (1.6 if hero else 1.0), mark_kind,
			MARK_LIFE * (1.7 if hero else 1.0), mark_col, 1.0, 0.25, 0.4, team)
	_deaths_left -= 1
	if _deaths_left < 0:
		return
	var n := CHIP_SCALE[_tier] * (1.8 if hero else 1.0)
	match k:
		0:   # Fire: embers lift off the body as it sinks, a little heat smoke.
			for i in int(14 * n):
				var d := _rng.randf_range(0.0, 0.9)
				var p := pos + Vector3(_rng.randf_range(-r, r), h * (0.85 - 0.75 * d) * _rng.randf_range(0.5, 1.0),
						_rng.randf_range(-r, r))
				_spark(p, Vector3(_rng.randf_range(-0.6, 0.6), _rng.randf_range(0.8, 2.4), _rng.randf_range(-0.6, 0.6)),
						0.035 * s, -2.2, 1.4, 0.09, _rng.randf_range(1.0, 1.9), EMBER, d, 0.8, ground)
			for i in int(3 * n + 1):
				_puff(Sys.PUFF, pos + Vector3(_rng.randf_range(-r, r) * 0.5, 0.4, _rng.randf_range(-r, r) * 0.5),
						Vector3(0, 0.5, 0), 0.5 * s, -0.4, 1.0, 2.2, 1.6, SMOKE, _rng.randf_range(0.15, 0.6), 0.15, 0.6, ground)
			_puff(Sys.GLOW, pos + Vector3.UP * h * 0.4, Vector3.ZERO, 0.9 * s, 0.0, 1.0, 0.45, 0.6,
					Color(1.4, 0.5, 0.12, 0.55), 0.0, 0.1, 0.0, ground)
		1:   # Shadow: violet wisps dissolve upward, high first then lower as the body sinks; ink smoke.
			for i in int(14 * n):
				var d := float(i) / maxf(14.0 * n, 1.0) * 0.9
				var p := pos + Vector3(_rng.randf_range(-r, r) * 0.7, h * (0.9 - 0.8 * d), _rng.randf_range(-r, r) * 0.7)
				_puff(Sys.GLOW, p, Vector3(_rng.randf_range(-0.3, 0.3), _rng.randf_range(0.6, 1.4), _rng.randf_range(-0.3, 0.3)),
						_rng.randf_range(0.22, 0.38) * s, -1.2, 1.2, _rng.randf_range(0.9, 1.5), 0.9,
						Color(0.62, 0.22, 1.1, 0.75), d, 0.2, 0.0, ground)
			for i in int(4 * n):
				_puff(Sys.PUFF, pos + Vector3(_rng.randf_range(-r, r) * 0.6, 0.35, _rng.randf_range(-r, r) * 0.6),
						Vector3(0, 0.4, 0), 0.55 * s, -0.3, 1.2, 1.8, 1.3, Color(0.1, 0.05, 0.16, 0.55),
						_rng.randf_range(0.0, 0.5), 0.15, 0.4, ground)
		2:   # Ice: the body shatters, shards land and lie, then melt; frost steam; glints.
			var mid := pos + Vector3.UP * h * 0.5
			for i in int(9 * n):
				var v := Vector3(_rng.randf_range(-1, 1), 0.0, _rng.randf_range(-1, 1)).normalized() * _rng.randf_range(1.2, 3.2)
				v.y = _rng.randf_range(1.5, 4.0)
				_chip(Sys.RUBBLE, mid + Vector3(_rng.randf_range(-r, r) * 0.5, _rng.randf_range(-h, h) * 0.3, 0.0), v,
						_rng.randf_range(0.1, 0.17) * s, 14.0, 0.8, _rng.randf_range(3.2, 4.4), _rng.randf_range(5.0, 10.0),
						_rng.randf_range(1.8, 2.8), ICE_CHIP.lerp(Color(0.85, 0.95, 1.0, 1.0), _rng.randf() * 0.5), 0.15, 0.0, ground)
			for i in int(3 * n + 1):
				_puff(Sys.PUFF, pos + Vector3(_rng.randf_range(-r, r), 0.3, _rng.randf_range(-r, r)), Vector3(0, 0.35, 0),
						0.45 * s, -0.4, 1.5, 1.4, 1.2, ICE_STEAM, _rng.randf_range(0.2, 0.8), 0.2, 0.8, ground)
			for i in int(5 * n):
				_spark(mid, _cone(Vector3.UP, 1.2, 2.0, 4.5), 0.025 * s, 4.0, 2.5, 0.05, _rng.randf_range(0.4, 0.7),
						ICE_GLINT, 0.0, 0.7, ground)
		3:   # Nature: a burst of small leaves falls and settles round the body; spores drift up.
			# G-E 13 (docs/art/ge_fixes_c.md): leaves were 0.16-0.24 m plates lying 3.5-4.8 s over the melee and its HP
			# bars; now half the size, twice the count, a shorter life (a leaf burst, not plates).
			# G-F: moss green / bronze of the Nature value pass (nature_leaf.tres), no pale lime.
			var greens: Array[Color] = [Color(0.36, 0.5, 0.16, 0.1), Color(0.3, 0.44, 0.14, 0.1), Color(0.48, 0.42, 0.17, 0.1),
					Color(0.52, 0.4, 0.18, 0.1)]
			for i in int(20 * n):
				var p := pos + Vector3(_rng.randf_range(-r, r), h * _rng.randf_range(0.4, 1.0), _rng.randf_range(-r, r))
				_chip(Sys.RUBBLE, p, Vector3(_rng.randf_range(-1.7, 1.7), _rng.randf_range(0.6, 2.2), _rng.randf_range(-1.7, 1.7)),
						_rng.randf_range(0.08, 0.12) * s, 2.6, 2.4, _rng.randf_range(1.8, 2.6), _rng.randf_range(4.0, 9.0), 0.14,
						greens[i % greens.size()], 0.0, _rng.randf_range(0.0, 0.3), ground)
			for i in int(7 * n):
				_puff(Sys.GLOW, pos + Vector3(_rng.randf_range(-r, r), _rng.randf_range(0.2, h), _rng.randf_range(-r, r)),
						Vector3(0, _rng.randf_range(0.3, 0.8), 0), 0.11 * s, -0.4, 1.0, 1.6, 0.5,
						Color(0.75, 1.25, 0.35, 0.7), _rng.randf_range(0.0, 0.8), 0.2, 0.0, ground)
		_:   # Neutral (beasts, critters): a puff of dust and a few clods.
			for i in int(4 * n + 1):
				_puff(Sys.PUFF, pos + Vector3(_rng.randf_range(-r, r), 0.3, _rng.randf_range(-r, r)),
						Vector3(_rng.randf_range(-0.8, 0.8), 0.5, _rng.randf_range(-0.8, 0.8)), 0.6 * s, -0.2, 2.0, 1.5, 1.4,
						STONE_DUST, _rng.randf_range(0.0, 0.3), 0.12, 0.7, ground)
			_chips(pos + Vector3.UP * 0.3, Vector3.UP, int(5 * n), 0.07 * s, 2.0, 4.0, Color(0.38, 0.32, 0.25, 0.0), 1.0, 0.0,
					ground, 1.6)


## A building was hit at `pos` (`dir` = blow direction, flat), `k` = its kingdom, `team` = attacker (fog).
func building_hit(b: Node3D, pos: Vector3, dir: Vector3, k: int, team: int) -> void:
	if not _take_event(pos, team):
		return
	var mat := building_material(b, k)
	var ground := b.global_position.y
	_material_burst(mat, pos, dir, 1.25 * _zoom_scale(pos), ground, 1.2)


## HP changed on a building (CombatVfx calls it on every `damaged`): crossing 66 % / 33 % cracks it, and it joins
## the burning list (smoke / fire / embers ticked at BURN_TICK). Healing back above drops the stage quietly.
func building_health(b: Node3D, k: int) -> void:
	if not active() or not is_instance_valid(b):
		return
	var st := _stage_of(b)
	var old := int(_stage.get(b, 0))
	if st == old:
		return
	if st == 0:
		_stage.erase(b)
		_burning.erase(b)
		return
	_stage[b] = st
	if not _burning.has(b):
		if _burning.size() >= BURN_MAX:
			return
		_burning.append(b)
	if st > old:
		_crack(b, k, st)


## The building is destroyed (not a cancelled site): dust ring + column, debris off the walls, embers, rubble pile
## and stain that stay ~RUBBLE_LIFE s. Its model plays its own collapse on top.
func building_collapse(b: Node3D, k: int) -> void:
	if not active() or not is_instance_valid(b):
		return
	_stage.erase(b)
	_burning.erase(b)
	var team := VfxFog.team_of(b)
	var c := b.global_position
	if not VfxFog.ok(team, c):
		_n_skipped += 1
		return
	# Off-screen: no dust / debris burst, but the rubble pile + stain still go down (panning back shows the ruin).
	var seen := _in_view(c, 8.0)
	_n_collapses += 1
	var ext := _extent(b)
	var hx := ext.x * 0.5
	var hz := ext.z * 0.5
	var h := ext.y
	var ground := c.y
	var n := CHIP_SCALE[_tier]
	var mat := building_material(b, k)
	var stone: Color = CombatVfx.STONE[clampi(k, 0, 4)]
	var dark: Color = CombatVfx.STONE_DARK[clampi(k, 0, 4)]
	if mat == Mat.WOOD:
		stone = Color(0.46, 0.33, 0.2)
		dark = Color(0.24, 0.17, 0.1)
	elif mat == Mat.ICE:
		stone = Color(0.66, 0.84, 0.97)
		dark = Color(0.36, 0.5, 0.66)
	var dust := Color(0.62, 0.57, 0.5, 0.78).lerp(Color(stone.r, stone.g, stone.b, 0.78), 0.35)
	var fire := k == 0
	# Rubble pile under the dust: stays, then sinks away.
	for i in int(22 * n) + 6:
		var p := c + Vector3(_rng.randf_range(-hx, hx) * 0.85, 0.25, _rng.randf_range(-hz, hz) * 0.85)
		_chip(Sys.RUBBLE, p, Vector3.ZERO, _rng.randf_range(0.28, 0.62), 4.0, 1.0, RUBBLE_LIFE + _rng.randf_range(-4.0, 2.0),
				0.0, _rng.randf_range(0.5, 1.5), _tint(stone, dark, mat), 0.0, _rng.randf_range(0.9, 1.8), ground)
	if seen:   # the burst only where the camera looks
		# Dust ring rolling out from the base.
		var ring_n := int(18 * n) + 4
		for i in ring_n:
			var a := TAU * float(i) / float(ring_n) + _rng.randf_range(-0.15, 0.15)
			var out := Vector3(cos(a), 0.0, sin(a))
			var p := c + Vector3(out.x * hx * 0.9, 0.4, out.z * hz * 0.9)
			_puff(Sys.PUFF, p, out * _rng.randf_range(2.5, 4.8) + Vector3.UP * 0.4, _rng.randf_range(1.2, 2.0), -0.15, 1.6,
					_rng.randf_range(3.0, 4.5), 1.5, dust, _rng.randf_range(0.0, 0.5), 0.08, 0.75, ground)
		# Dust column rising through the falling walls.
		for i in int(8 * n) + 2:
			var p := c + Vector3(_rng.randf_range(-hx, hx) * 0.6, _rng.randf_range(0.3, 0.9) * h, _rng.randf_range(-hz, hz) * 0.6)
			_puff(Sys.PUFF, p, Vector3(0, _rng.randf_range(0.4, 1.0), 0), _rng.randf_range(1.8, 2.8), -0.1, 0.8,
					_rng.randf_range(3.5, 5.0), 1.2, dust.darkened(0.08), _rng.randf_range(0.2, 1.2), 0.15, 0.75, ground)
		# Debris off the walls: falls, bounces to rest, sinks away.
		for i in int(34 * n) + 6:
			var p := c + Vector3(_rng.randf_range(-hx, hx), _rng.randf_range(0.4, 1.0) * h, _rng.randf_range(-hz, hz))
			var out := Vector3(p.x - c.x, 0.0, p.z - c.z).normalized() * _rng.randf_range(0.4, 2.0)
			_chip(Sys.RUBBLE, p, out + Vector3.UP * _rng.randf_range(0.0, 2.2), _rng.randf_range(0.18, 0.42), 15.0, 0.45,
					_rng.randf_range(7.0, 11.0), _rng.randf_range(3.0, 8.0), _rng.randf_range(0.6, 1.6),
					_tint(stone, dark, mat), 0.6 if fire else 0.0, _rng.randf_range(0.0, 1.4), ground)
		# Embers and sparks.
		for i in int((26 if fire else 14) * n) + 4:
			var p := c + Vector3(_rng.randf_range(-hx, hx), _rng.randf_range(0.2, 0.8) * h, _rng.randf_range(-hz, hz))
			_spark(p, Vector3(_rng.randf_range(-1.2, 1.2), _rng.randf_range(1.0, 3.5), _rng.randf_range(-1.2, 1.2)), 0.04,
					-1.5, 1.0, 0.1, _rng.randf_range(1.4, 2.6), EMBER, _rng.randf_range(0.0, 1.5), 0.8, ground)
	_mark(Vector3(c.x, ground + 0.06, c.z), maxf(hx, hz) * 1.3 + 0.6, 4, RUBBLE_LIFE + 4.0,
			Color(0.46, 0.41, 0.33, 0.85).lerp(Color(stone.r, stone.g, stone.b, 0.85), 0.35), 0.0, 1.2, 0.3, team)
	if fire:
		_mark(Vector3(c.x, ground + 0.07, c.z), maxf(hx, hz) * 0.9, 0, 18.0, Color(0.14, 0.09, 0.06, 0.8), 1.0, 0.6, 0.4, team)


# ================================================================ materials

## What a unit / building is made of for a hit (Mat).
static func material_of(n: Variant) -> int:
	if not is_instance_valid(n):
		return Mat.FLESH
	var node := n as Node
	if _is_building(node):
		return building_material(node, -1)
	var id := ""
	var armor := 0.0
	var ut: Variant = node.get(&"unit_type")
	if ut != null and is_instance_valid(ut):
		id = String((ut as Object).get(&"id"))
		var a: Variant = (ut as Object).get(&"armor")
		armor = float(a) if a != null else 0.0
	if id == "":
		id = String(node.name).to_lower()
	return material_of_id(id, armor)


static func material_of_id(id: String, armor: float = 0.0) -> int:
	for row: Array in MAT_KEYS:
		for key: String in row[1]:
			if id.contains(key):
				return int(row[0])
	return Mat.STEEL if armor >= 15.0 else Mat.FLESH


## Building material: Nature = wood, an Ice wall = ice, the rest stone (k = kingdom index, -1 = read it).
static func building_material(b: Variant, k: int) -> int:
	var bt: Variant = (b as Object).get(&"building_type") if is_instance_valid(b) else null
	var id := ""
	var f := ""
	if bt != null and is_instance_valid(bt):
		id = String((bt as Object).get(&"id"))
		f = String((bt as Object).get(&"faction"))
	if k == 3 or f == "nature" or id.contains("hovel") or id.contains("hearth_house"):
		return Mat.WOOD
	if (k == 2 or f == "ice") and id.contains("wall"):
		return Mat.ICE
	return Mat.STONE


static func _is_building(n: Variant) -> bool:
	if not is_instance_valid(n):
		return false
	return n is Building or ((n as Node).has_signal(&"damaged") and not (n as Node).has_signal(&"attack_landed"))


## One hit's material response at `pos`: pieces fly UP and to the sides, a little back along -`dir` (out of the
## bodies, toward the RTS camera, so they read at zoom 10-40); `amt` scales the piece count.
func _material_burst(mat: int, pos: Vector3, dir: Vector3, s: float, ground: float, amt: float) -> void:
	var n := CHIP_SCALE[_tier] * amt
	var near := _cam == null or _cam_pos.distance_squared_to(pos) < CHIP_CULL_DISTANCE * CHIP_CULL_DISTANCE
	var out := Vector3.UP * 1.1 - dir * 0.45
	var top := pos + Vector3.UP * 0.25   # puffs start a little higher so the body does not hide them
	match mat:
		Mat.STEEL:
			for i in int(9 * n) + 2:
				_spark(pos, _cone(out, 1.3, 4.5, 10.0), 0.04 * s, 16.0, 3.0, 0.05,
						_rng.randf_range(0.25, 0.45), STEEL_SPARK, 0.0, 0.3, ground)
			if _tier >= 2:
				_puff(Sys.PUFF, top, out * 0.4, 0.3 * s, -0.4, 3.0, 0.4, 1.2, Color(0.62, 0.6, 0.57, 0.4), 0.0, 0.1, 0.6, ground)
		Mat.FLESH:
			for i in int(2 * n) + 1:
				_puff(Sys.PUFF, top + _jit(0.15), _cone(out, 1.0, 0.8, 1.8), 0.5 * s, -0.3, 3.0,
						_rng.randf_range(0.45, 0.6), 1.3, FLESH_DUST, 0.0, 0.1, 0.7, ground)
			if near:
				_chips(pos, out, int(3 * n) + 1, 0.06 * s, 2.5, 4.5, FLESH_FLECK, 1.0, 0.0, ground, 0.7)
		Mat.BONE:
			if near:
				_chips(pos, out, int(5 * n) + 1, 0.09 * s, 3.0, 5.5, BONE_CHIP, 0.45, 0.0, ground, 1.0)
			_puff(Sys.PUFF, top, out * 0.6, 0.32 * s, -0.3, 3.0, 0.5, 1.3, BONE_DUST, 0.0, 0.1, 0.7, ground)
		Mat.WOOD:
			if near:
				_chips(pos, out, int(5 * n) + 1, 0.075 * s, 3.0, 6.0, WOOD_CHIP, 3.2, 0.0, ground, 1.0)
			_puff(Sys.PUFF, top, out * 0.5, 0.32 * s, -0.2, 3.0, 0.5, 1.3, WOOD_DUST, 0.0, 0.1, 0.7, ground)
		Mat.ICE:
			if near:
				_chips(pos, out, int(5 * n) + 1, 0.09 * s, 3.0, 6.5, ICE_CHIP, 2.4, 0.4, ground, 1.0)
			for i in int(3 * n) + 1:
				_spark(pos, _cone(out, 1.1, 2.0, 5.0), 0.03 * s, 6.0, 3.0, 0.05,
						_rng.randf_range(0.3, 0.5), ICE_GLINT, 0.0, 0.6, ground)
			if _tier >= 2:
				_puff(Sys.PUFF, top, out * 0.4, 0.3 * s, -0.5, 3.0, 0.5, 1.2, ICE_STEAM, 0.0, 0.1, 0.8, ground)
		_:   # STONE
			if near:
				_chips(pos, out, int(5 * n) + 1, 0.11 * s, 3.0, 6.5, Color(0.52, 0.49, 0.44, 0.0), 1.0, 0.0, ground, 1.1)
			_puff(Sys.PUFF, top, out * 0.6, 0.45 * s, -0.3, 2.5, 0.6, 1.4, STONE_DUST, 0.0, 0.1, 0.7, ground)
			for i in int(3 * n):
				_spark(pos, _cone(out, 1.2, 4.0, 8.0), 0.03 * s, 14.0, 3.5, 0.045, 0.3,
						Color(1.8, 1.1, 0.5, 0.9), 0.0, 0.3, ground)

# ================================================================ building stages

static func _stage_of(b: Node3D) -> int:
	var hp: Variant = b.get(&"hp")
	var mx: Variant = b.get(&"max_hp")
	if hp == null or mx == null or float(mx) <= 0.0:
		return 0
	if b.has_method(&"is_constructed") and not bool(b.call(&"is_constructed")):
		return 0   # a site under construction is not "damaged"
	var r := float(hp) / float(mx)
	if r <= 0.0:
		return 0
	return 2 if r <= STAGE_2 else (1 if r <= STAGE_1 else 0)


## A crack when a building drops a stage: debris falls off the top, dust, sparks.
func _crack(b: Node3D, k: int, st: int) -> void:
	var team := VfxFog.team_of(b)
	var c := b.global_position
	if not VfxFog.ok(team, c) or not _in_view(c, 6.0):
		return
	_n_cracks += 1
	var ext := _extent(b)
	var n := CHIP_SCALE[_tier] * (1.0 if st == 1 else 1.6)
	var mat := building_material(b, k)
	var stone: Color = CombatVfx.STONE[clampi(k, 0, 4)]
	var dark: Color = CombatVfx.STONE_DARK[clampi(k, 0, 4)]
	var ground := c.y
	for i in int(10 * n) + 2:
		var p := c + Vector3(_rng.randf_range(-0.5, 0.5) * ext.x, ext.y * _rng.randf_range(0.75, 1.0),
				_rng.randf_range(-0.5, 0.5) * ext.z)
		var out := Vector3(p.x - c.x, 0.0, p.z - c.z).normalized() * _rng.randf_range(0.5, 2.0)
		_chip(Sys.CHIP, p, out + Vector3.UP * _rng.randf_range(0.5, 2.0), _rng.randf_range(0.14, 0.3), 15.0, 0.5,
				_rng.randf_range(3.0, 4.5), _rng.randf_range(4.0, 9.0), _rng.randf_range(0.6, 1.5), _tint(stone, dark, mat),
				0.5 if k == 0 else 0.0, _rng.randf_range(0.0, 0.25), ground)
	for i in int(4 * n) + 1:
		var p := c + Vector3(_rng.randf_range(-0.5, 0.5) * ext.x, ext.y * _rng.randf_range(0.5, 0.95),
				_rng.randf_range(-0.5, 0.5) * ext.z)
		_puff(Sys.PUFF, p, Vector3(0, 0.3, 0), _rng.randf_range(0.9, 1.4), 0.3, 1.5, _rng.randf_range(1.8, 2.6), 1.3,
				STONE_DUST, _rng.randf_range(0.0, 0.3), 0.1, 0.7, ground)
	for i in int(8 * n) + 2:
		var p := c + Vector3(_rng.randf_range(-0.4, 0.4) * ext.x, ext.y * 0.8, _rng.randf_range(-0.4, 0.4) * ext.z)
		_spark(p, _cone(Vector3.UP, 1.2, 2.0, 5.0), 0.03, 9.0, 2.0, 0.06, _rng.randf_range(0.5, 0.9), EMBER, 0.0, 0.6, ground)


## Smoke / fire / embers on damaged buildings (BURN_TICK). Models with their own damage stages (set_health_ratio)
## already smoke and burn: they only get rising embers below 33 %.
func _tick_burning() -> void:
	var i := _burning.size() - 1
	while i >= 0:
		var b := _burning[i]
		if not is_instance_valid(b) or not b.is_inside_tree() or (b.has_method(&"is_alive") and not bool(b.call(&"is_alive"))):
			_stage.erase(b)
			_burning.remove_at(i)
			i -= 1
			continue
		var st := _stage_of(b)
		if st == 0:
			_stage.erase(b)
			_burning.remove_at(i)
			i -= 1
			continue
		_stage[b] = st
		i -= 1
		var c := b.global_position
		if not VfxFog.ok(VfxFog.team_of(b), c) or not _in_view(c, 4.0) or not b.is_visible_in_tree():
			continue
		var ext := _extent(b)
		var ground := c.y
		var own := _model_has_stages(b)
		var p := c + Vector3(_rng.randf_range(-0.35, 0.35) * ext.x, ext.y * _rng.randf_range(0.7, 1.0),
				_rng.randf_range(-0.35, 0.35) * ext.z)
		if not own:
			if _rng.randf() < 0.7:
				_puff(Sys.PUFF, p, Vector3(_rng.randf_range(-0.2, 0.2), 0.9, _rng.randf_range(-0.2, 0.2)),
						_rng.randf_range(0.7, 1.0), -0.5, 0.6, _rng.randf_range(2.6, 3.4), 1.7,
						SMOKE if st == 2 else Color(0.3, 0.29, 0.28, 0.45), 0.0, 0.15, 0.5, ground)
			if st == 2:
				_puff(Sys.GLOW, p - Vector3.UP * 0.3, Vector3(0, 0.6, 0), _rng.randf_range(0.5, 0.75), -0.5, 1.0,
						_rng.randf_range(0.5, 0.75), 0.8, Color(1.6, 0.6, 0.14, 0.7), 0.0, 0.1, 0.0, ground)
		if st == 2 and (not own or _tier >= 2):
			for j in 2:
				_spark(p, Vector3(_rng.randf_range(-0.6, 0.6), _rng.randf_range(1.2, 2.6), _rng.randf_range(-0.6, 0.6)),
						0.03, -1.2, 1.0, 0.1, _rng.randf_range(1.0, 1.8), EMBER, _rng.randf_range(0.0, BURN_TICK), 0.8, ground)


static func _model_has_stages(b: Node3D) -> bool:
	if not b.has_method(&"model"):
		return false
	var m: Variant = b.call(&"model")
	return m != null and is_instance_valid(m) and (m as Node).has_method(&"set_health_ratio")


## Footprint x / height / z of a building (metres).
static func _extent(b: Node3D) -> Vector3:
	var bt: Variant = b.get(&"building_type")
	if bt != null and is_instance_valid(bt) and (bt as Object).has_method(&"size_m"):
		var s: Vector2 = (bt as Object).call(&"size_m")
		var h: Variant = (bt as Object).get(&"height")
		return Vector3(s.x, maxf(float(h) if h != null else 3.0, 2.0), s.y)
	var r := Unit.radius_of(b)
	return Vector3(r * 2.0, 3.0, r * 2.0)


func _tint(stone: Color, dark: Color, mat: int) -> Color:
	var c := stone.lerp(dark, _rng.randf_range(0.0, 0.7))
	c.a = 0.9 if mat == Mat.ICE else 0.0
	return c


# ================================================================ spawning

## Per-frame / fog / view gate for one hit-like event.
func _take_event(pos: Vector3, team: int) -> bool:
	if not active():
		return false
	if _events_left <= 0 or _inst_left <= 0 or not VfxFog.ok(team, pos):
		_n_skipped += 1
		return false
	_events_left -= 1
	_n_events += 1
	return true


## Zoomed out, pieces grow (x1 at 25 m, up to x1.6) so they still read at 40-55 m, like CombatVfx's flashes.
func _zoom_scale(pos: Vector3) -> float:
	return clampf(_cam_pos.distance_to(pos) / 25.0, 1.0, 1.6) if _cam else 1.0


func _in_view(pos: Vector3, margin: float) -> bool:
	if _cam == null:
		return true
	if _cam.is_position_in_frustum(pos):
		return true
	return _cam.is_position_in_frustum(pos + Vector3(margin, 0.0, 0.0)) \
			or _cam.is_position_in_frustum(pos - Vector3(margin, 0.0, 0.0)) \
			or _cam.is_position_in_frustum(pos + Vector3(0.0, 0.0, margin)) \
			or _cam.is_position_in_frustum(pos - Vector3(0.0, 0.0, margin))


func _ground_of(n: Variant, pos: Vector3) -> float:
	if is_instance_valid(n):
		return (n as Node3D).global_position.y
	return pos.y - 1.0


func _ground_y(pos: Vector3) -> float:
	return pos.y   # a projectile that ends on the ground ends at the ground point


func _height(u: Node3D) -> float:
	var h: Variant = u.get(&"body_height")
	return float(h) if h != null else 1.6


func _jit(r: float) -> Vector3:
	return Vector3(_rng.randf_range(-r, r), _rng.randf_range(-r, r), _rng.randf_range(-r, r))


## A random velocity in a cone round `dir` (spread 0 = straight, 1 = wide).
func _cone(dir: Vector3, spread: float, v0: float, v1: float) -> Vector3:
	var d := dir.normalized() if dir.length_squared() > 0.0001 else Vector3.UP
	d = (d + _jit(spread)).normalized()
	return d * _rng.randf_range(v0, v1)


## `count` chips thrown round `dir` (CHIP system).
func _chips(pos: Vector3, dir: Vector3, count: int, size: float, v0: float, v1: float, col: Color, stretch: float,
		glow: float, ground: float, life: float) -> void:
	for i in count:
		_chip(Sys.CHIP, pos, _cone(dir, 0.9, v0, v1), size * _rng.randf_range(0.7, 1.3), 13.0, 1.5,
				life * _rng.randf_range(0.8, 1.2), _rng.randf_range(6.0, 14.0), stretch * _rng.randf_range(0.8, 1.2), col,
				glow, 0.0, ground)


func _spark(pos: Vector3, vel: Vector3, width: float, grav: float, drag: float, trail: float, life: float, col: Color,
		delay: float, flicker: float, ground: float) -> void:
	_write(Sys.SPARK, Transform3D(Basis(vel, Vector3(width, grav, drag), Vector3(trail, life, ground)), pos),
			Color(_clock + delay, _rng.randf(), flicker, 0.0), col, delay + life)


func _puff(sys: int, pos: Vector3, vel: Vector3, size: float, grav: float, drag: float, life: float, growth: float,
		col: Color, delay: float, fade_in: float, top: float, ground: float) -> void:
	_write(sys, Transform3D(Basis(vel, Vector3(size, grav, drag), Vector3(ground, life, growth)), pos),
			Color(_clock + delay, _rng.randf(), fade_in, top), col, delay + life)


func _chip(sys: int, pos: Vector3, vel: Vector3, size: float, grav: float, drag: float, life: float, spin: float,
		stretch: float, col: Color, glow: float, delay: float, ground: float) -> void:
	_write(sys, Transform3D(Basis(vel, Vector3(size, grav, drag), Vector3(ground, life, spin)), pos),
			Color(_clock + delay, stretch, _rng.randf(), glow), col, delay + life)


func _mark(pos: Vector3, radius: float, kind: int, life: float, col: Color, glow: float, fade_in: float,
		fade_out: float, team: int) -> void:
	if not active():
		return
	var idx := _ring[Sys.MARK]
	_write(Sys.MARK, Transform3D(Basis(Vector3(radius, _rng.randf() * TAU, float(kind)), Vector3(fade_in, life, fade_out),
			Vector3.ZERO), pos), Color(_clock, _rng.randf(), glow, 0.0), col, life, true)
	_mk_pos[idx] = pos
	_mk_team[idx] = team
	_mk_col[idx] = col
	_mk_end[idx] = _clock + life
	_mk_shown[idx] = 1


func _write(sys: int, xf: Transform3D, custom: Color, col: Color, until: float, force: bool = false) -> void:
	if not force:
		if _inst_left <= 0:
			return
		_inst_left -= 1
	if _anchor == Vector3.INF:
		# The pieces are written relative to the first effect's spot (always a point the local player sees), so the
		# MultiMesh nodes do not sit at the map origin, which may be unexplored fog (tests/test_fog_leak.gd).
		_anchor = xf.origin.round()
		global_position = _anchor
	xf.origin -= _anchor
	var mm := _mm[sys]
	var cap := CAPS[sys]
	var idx := _ring[sys]
	_ring[sys] = (idx + 1) % cap
	mm.set_instance_transform(idx, xf)
	mm.set_instance_custom_data(idx, custom)
	mm.set_instance_color(idx, col)
	_n_instances += 1
	if _written[sys] < cap:
		_written[sys] += 1
	_alive_until[sys] = maxf(_alive_until[sys], _clock + until + 0.05)
	if mm.visible_instance_count != _written[sys]:
		mm.visible_instance_count = _written[sys]


## Ground marks are long-lived and transparent (they would draw over the fog): hide them while the fog covers them.
func _recheck_marks() -> void:
	if _written.is_empty() or _written[Sys.MARK] == 0 or _mm[Sys.MARK].visible_instance_count == 0:
		return
	var mm := _mm[Sys.MARK]
	for i in _written[Sys.MARK]:
		if _mk_end[i] <= _clock:
			continue
		var ok := VfxFog.ok(_mk_team[i], _mk_pos[i])
		if ok != (_mk_shown[i] == 1):
			_mk_shown[i] = 1 if ok else 0
			var c := _mk_col[i]
			mm.set_instance_color(i, c if ok else Color(c.r, c.g, c.b, 0.0))


func _marks_shown() -> int:
	var n := 0
	for i in _mk_end.size():
		if _mk_end[i] > _clock and _mk_shown[i] == 1:
			n += 1
	return n


# ================================================================ build

func _build() -> void:
	_built = true
	_ring.resize(CAPS.size())
	_written.resize(CAPS.size())
	_alive_until.resize(CAPS.size())
	var quad := QuadMesh.new()
	var chip := _chip_mesh()
	for s in CAPS.size():
		var shader := load(SHADERS[s]) as Shader
		var mat := ShaderMaterial.new()
		mat.shader = shader
		var mesh: Mesh = chip if s == Sys.CHIP or s == Sys.RUBBLE else quad
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.use_custom_data = true
		mm.mesh = mesh
		mm.instance_count = CAPS[s]
		mm.visible_instance_count = 0
		mm.custom_aabb = AABB(Vector3(-2000.0, -100.0, -2000.0), Vector3(4000.0, 400.0, 4000.0))
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "CG" + String(Sys.keys()[s]).capitalize()
		mmi.multimesh = mm
		mmi.material_override = mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.custom_aabb = mm.custom_aabb
		if s == Sys.MARK:
			mmi.sorting_offset = -2.0   # ground marks first among the transparent pieces
		add_child(mmi)
		_mm.append(mm)
		_mmi.append(mmi)
		_mats.append(mat)
	var mc := CAPS[Sys.MARK]
	_mk_pos.resize(mc)
	_mk_team.resize(mc)
	_mk_col.resize(mc)
	_mk_end.resize(mc)
	_mk_shown.resize(mc)


## A low-poly irregular chip (a squashed, jittered octahedron, flat-shaded), 1 m across; the shader scales it.
static func _chip_mesh() -> ArrayMesh:
	var v: Array[Vector3] = [Vector3(0.5, 0.05, 0.0), Vector3(-0.42, -0.04, 0.08), Vector3(0.06, 0.0, 0.46),
			Vector3(-0.04, 0.06, -0.5), Vector3(0.05, 0.5, 0.04), Vector3(-0.06, -0.44, -0.05)]
	var faces: Array[Vector3i] = [Vector3i(4, 0, 2), Vector3i(4, 2, 1), Vector3i(4, 1, 3), Vector3i(4, 3, 0),
			Vector3i(5, 2, 0), Vector3i(5, 1, 2), Vector3i(5, 3, 1), Vector3i(5, 0, 3)]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for f in faces:
		var a := v[f.x]
		var b := v[f.y]
		var c := v[f.z]
		var n := (b - a).cross(c - a).normalized()
		if n.dot(a + b + c) < 0.0:
			n = -n   # outward
		for p: Vector3 in [a, b, c]:
			st.set_normal(n)
			st.add_vertex(p)
	return st.commit()
