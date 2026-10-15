class_name IceVfx
extends Node3D
## Ice effects (task 7.V5, kingdom-ice.md 2.1 / 2.3 / 4.1). Add ONE of these to a level, like SpellVfx and
## CombatVfx; it never edits gameplay code. It hooks:
##   SpellCaster (every wizard) spell_cast / spell_effect for Torvald's ids:
##     rime_bolt (+ rime_bolt_hit) -> frost cast swirl, pooled ice trail on the bolt, shatter on hit
##     flash_freeze                -> frost circle (radius_of) with a glowing rim + 20 ice shards that
##                                    erupt, hold and sink, snow puff, cold light
##     rime_aegis (+ rime_aegis_shield per unit) -> expanding ring, rising sparkles, a dome per shielded unit
##   Unit statuses, polled with has_status() 4 times per second on visible living units:
##     chill  -> body modulate (0.70, 0.85, 1.00) (material_overlay, multiply) + frost patch + 12 blue motes
##     frozen -> translucent ice block (radius x 2.2, height x 1.1) + frost patch
##     rooted -> brown-green thorns and roots at the feet (Nature, step 8)
##   Support autocast: signal support_cast(caster, target, kind) on the unit's "SupportCaster" child,
##     the unit itself or the Events autoload -> 0.25 s beam (ice = shield, green = heal); a shield target
##     keeps an ice dome while its shield lasts (same as Rime Aegis).
## The Unit's own placeholder status marks / ice block are hidden while this node shows the status.
## Budget: every aura, burst, trail, beam, ring, light and Flash Freeze set is pooled (no allocations per
## hit after warm-up); auras are capped per kind and follow their unit from one _process loop.

const META := &"ice_vfx"
const SPELL_META := &"spell_vfx"     # CombatVfx skips projectiles carrying this (no double trail)
## In-game grade pass (2026-09-30): Ice effects turned the fight white (additive near-white domes, blocks, puffs and
## rings over the bloom). Now saturated cyan / steel, alpha-blended, every colour <= 1.5 x (most under ~1.1, the
## bloom threshold), puffs half size, the Rime Aegis dome hollowed to a rim (ice_dome.gdshader).
## Ice readability pass (2026-10-12, under_90.md rows 17 / 19): the cyan light flashes still washed Torvald and the
## frozen targets (LIGHT_* energies cut ~40 %), the Flash Freeze disc and its veins dimmed, ground rings and the
## support beam no longer additive / over 1.0, the dome's base band and rim thinner.
const ICE := Color(0.25, 0.74, 1.0)
const ICE_PALE := Color(0.45, 0.80, 0.98)
const STEEL := Color(0.30, 0.46, 0.62)
const RING_ENERGY := 1.0
const LIGHT_CAST := 0.7       # pooled OmniLight flash energies (were 1.0-1.5: a cyan wash over the fight)
const LIGHT_HIT := 0.6
const LIGHT_FREEZE := 0.9
const LIGHT_AEGIS := 0.7
const NATURE := Color(0.45, 1.0, 0.35)
const CHILL_TINT := Color(0.70, 0.85, 1.00)
const POLL_INTERVAL := 0.25
const RESCAN_INTERVAL := 1.0
const MAX_LIGHTS := 3
const BEAM_TIME := 0.25
const SHARDS := 20
const FREEZE_HOLD := 1.3
const STATUS_IDS: Array[StringName] = [&"chill", &"frozen", &"rooted"]
const ICE_SPELLS: Array[StringName] = [&"rime_bolt", &"flash_freeze", &"rime_aegis"]
## Max live auras per kind (the rest of the units simply show no aura).
const AURA_CAPS := {&"chill": 80, &"frozen": 48, &"rooted": 48, &"dome": 48}
## Auras built up front per kind (hidden, in the free pool) so a fight's first statuses add no nodes mid-match
## (a rooted aura is 12 nodes; test_ice_vfx_read counts nodes added per event). More are still built lazily up to the cap.
const AURA_PREBUILD := {&"chill": 8, &"frozen": 4, &"rooted": 8, &"dome": 2}
const POOL_SIZES := {&"frost_cast": 4, &"bolt_shatter": 6, &"freeze_chips": 3, &"snow_puff": 6,
		&"aegis_rise": 3, &"heal_sparkle": 6}
const AMOUNTS := {&"frost_cast": 16, &"bolt_shatter": 12, &"freeze_chips": 28, &"snow_puff": 10,
		&"aegis_rise": 30, &"heal_sparkle": 10}
const LIFETIMES := {&"frost_cast": 0.7, &"bolt_shatter": 0.6, &"freeze_chips": 0.8, &"snow_puff": 0.7,
		&"aegis_rise": 1.3, &"heal_sparkle": 0.7}
const MESH_LOOKS: Array[StringName] = [&"bolt_shatter", &"freeze_chips"]
const MIX_LOOKS: Array[StringName] = [&"snow_puff", &"frost_cast", &"aegis_rise", &"bolt_shatter", &"freeze_chips"]
const TRAIL_POOL := 6
const BEAM_POOL := 8
const RING_POOL := 6
const FREEZE_POOL := 3

const GROUND_SHADER := preload("res://art/vfx/vfx_ground.gdshader")
const BLOCK_SHADER := preload("res://art/vfx/ice_block.gdshader")
const FROST_SHADER := preload("res://art/vfx/ice_frost.gdshader")
const DOME_SHADER := preload("res://art/vfx/ice_dome.gdshader")

var _wizards: Array[Node3D] = []
var _active: Dictionary = {}        # Unit -> {kind: aura root}
var _dying: Dictionary = {}         # aura root -> Unit (fading out, still follows)
var _free: Dictionary = {}          # kind -> Array[Node3D]
var _live: Dictionary = {}          # kind -> int (acquired, incl. dying)
var _domes: Dictionary = {}         # Unit -> true: show an ice dome while its shield lasts
var _overlays: Dictionary = {}      # Unit -> Array[GeometryInstance3D] carrying the chill overlay
var _support_last: Dictionary = {}  # caster -> msec (dedupe when two sources emit)
var _pools: Dictionary = {}
var _pool_next: Dictionary = {}
var _pmats: Dictionary = {}
var _bolts: Array[Dictionary] = []  # {p: Node3D, e: GPUParticles3D}
var _trail_free: Array[GPUParticles3D] = []
var _cooling: Array[Dictionary] = []
var _lights: Array[OmniLight3D] = []
var _light_next := 0
var _beams: Array[MeshInstance3D] = []
var _beam_next := 0
var _rings: Array[MeshInstance3D] = []
var _ring_next := 0
var _freezes: Array[Node3D] = []
var _freeze_next := 0
var _poll_left := 0.0
var _rescan_left := 0.0

# Shared resources (built once).
var _soft_tex: GradientTexture2D
var _quad_add: QuadMesh
var _quad_mix: QuadMesh
var _chip_mesh: CylinderMesh
var _plane: PlaneMesh
var _box: BoxMesh
var _dome_mesh: SphereMesh
var _thorn_mesh: CylinderMesh
var _root_mesh: CylinderMesh
var _shard_mesh: CylinderMesh
var _beam_mesh: CylinderMesh
var _frost_mat: ShaderMaterial
var _chill_frost_mat: ShaderMaterial
var _moss_mat: ShaderMaterial
var _block_mat: ShaderMaterial
var _dome_mat: ShaderMaterial
var _thorn_mat: StandardMaterial3D
var _bark_mat: StandardMaterial3D
var _shard_mat: StandardMaterial3D
var _overlay_mat: StandardMaterial3D


func _ready() -> void:
	top_level = true                  # auras and effects are placed in world space
	global_transform = Transform3D.IDENTITY
	_build_shared()
	get_tree().node_added.connect(_on_node_added)
	var events := get_node_or_null(^"/root/Events")
	if events and events.has_signal(&"support_cast"):
		events.connect(&"support_cast", _on_support_cast)
	_rescan()
	_g.call_deferred()   # G-B: builds the Medium+ spell layer up front (nothing at Low)


## The G-B spell layer (art/vfx/spells_g/spell_fx_g.gd), null at Low: Low keeps this file's exact look and cost.
func _g() -> SpellFxG:
	return SpellFxG.live(self)


## The caster's team for the G layer's fog check (-1 = unknown: the layer checks the point against the local fog).
func _team(w: Variant) -> int:
	if is_instance_valid(w) and (w as Object).get(&"team") != null:
		return int((w as Object).get(&"team"))
	return -1


func _process(delta: float) -> void:
	_rescan_left -= delta
	if _rescan_left <= 0.0:
		_rescan_left = RESCAN_INTERVAL
		_rescan()
	_poll_left -= delta
	if _poll_left <= 0.0:
		_poll_left = POLL_INTERVAL
		_poll()
	# Auras follow their unit.
	for u: Variant in _active.keys():
		var auras: Dictionary = _active[u]
		if not is_instance_valid(u) or not (u as Node).is_inside_tree():
			for k: StringName in auras.keys():
				_release(k, auras[k])
			_active.erase(u)
			_clear_overlay(u)
			continue
		var at := (u as Node3D).global_position
		for k: StringName in auras:
			(auras[k] as Node3D).position = at
	for root: Variant in _dying.keys():
		var u: Variant = _dying[root]
		if is_instance_valid(u) and (u as Node).is_inside_tree():
			(root as Node3D).position = (u as Node3D).global_position
	# Rime Bolt trails follow their bolt.
	for i in range(_bolts.size() - 1, -1, -1):
		var b: Dictionary = _bolts[i]
		var p: Variant = b["p"]
		var e: GPUParticles3D = b["e"]
		if is_instance_valid(p) and (p as Node).is_inside_tree():
			e.global_position = (p as Node3D).global_position
		else:
			_bolts.remove_at(i)
			e.emitting = false
			_cooling.append({"e": e, "t": 0.5})
	for i in range(_cooling.size() - 1, -1, -1):
		var c: Dictionary = _cooling[i]
		c["t"] = float(c["t"]) - delta
		if float(c["t"]) <= 0.0:
			var e: GPUParticles3D = c["e"]
			e.visible = false
			_trail_free.append(e)
			_cooling.remove_at(i)


# ---------------------------------------------------------------- hooking

func _on_node_added(node: Node) -> void:
	if node is Unit:
		_hook.call_deferred(node)


func _rescan() -> void:
	for group: StringName in [&"units", &"heroes", &"enemy_heroes"]:
		for node in get_tree().get_nodes_in_group(group):
			if not node.has_meta(META):
				_hook(node)


func _hook(node: Variant) -> void:
	if not is_instance_valid(node) or not node is Unit or (node as Node).has_meta(META):
		return
	var u := node as Unit
	var caster := u.get_node_or_null(^"SpellCaster")
	if u is Wizard and (caster == null or not caster.has_signal(&"spell_effect")):
		return   # the SpellCaster may not exist yet: the next rescan tries again
	u.set_meta(META, true)
	if caster and caster.has_signal(&"spell_effect") and not _wizards.has(u):
		_wizards.append(u)
		caster.connect(&"spell_cast", _on_spell_cast.bind(u))
		caster.connect(&"spell_effect", _on_spell_effect.bind(u))
		u.tree_exiting.connect(func() -> void: _wizards.erase(u), CONNECT_ONE_SHOT)
	var sc := u.get_node_or_null(^"SupportCaster")
	if sc and sc.has_signal(&"support_cast"):
		sc.connect(&"support_cast", _on_support_cast)
	elif u.has_signal(&"support_cast"):
		u.connect(&"support_cast", _on_support_cast)


# ---------------------------------------------------------------- spells

func _on_spell_cast(id: StringName, w: Node3D) -> void:
	if not ICE_SPELLS.has(id) or not is_instance_valid(w):
		return
	var pos := w.global_position
	_burst(&"frost_cast", pos + Vector3.UP * 0.1)
	_ring(pos, 0.3, 1.5, ICE, 0.35, 0.1)
	if id != &"rime_bolt":
		_light_flash(pos + Vector3.UP * 1.6, ICE, LIGHT_CAST, 6.0, 0.3)


func _on_spell_effect(id: StringName, pos: Vector3, w: Node3D) -> void:
	if not is_instance_valid(w):
		return
	match id:
		&"rime_bolt":
			var p := _find_projectile(w)
			if p:
				p.set_meta(SPELL_META, true)
				_attach_trail(p)
				var g := _g()
				if g:
					g.play(&"rime_bolt_fly", p.global_position, {"node": p, "team": _team(w)})
		&"rime_bolt_hit":
			_burst(&"bolt_shatter", pos + Vector3.UP * 1.0)
			_burst(&"snow_puff", pos + Vector3.UP * 0.8)
			_ring(pos, 0.2, 1.3, ICE_PALE, 0.3, 0.12)
			_light_flash(pos + Vector3.UP * 1.3, ICE, LIGHT_HIT, 5.0, 0.25)
			var g := _g()
			if g:
				g.play(&"rime_bolt_hit", pos, {"team": _team(w)})
		&"flash_freeze":
			var r := _radius_of(w, id, 3.0)
			_flash_freeze(pos, r)
			var g := _g()
			if g:
				g.play(&"flash_freeze", pos, {"r": r, "team": _team(w)})
		&"rime_aegis":
			var r := _radius_of(w, id, 8.0)
			_ring(pos, 0.5, r, ICE, 0.55, 0.035)
			_burst(&"aegis_rise", pos)
			_light_flash(pos + Vector3.UP * 2.0, ICE, LIGHT_AEGIS, r + 3.0, 0.6)
			var g := _g()
			if g:
				g.play(&"rime_aegis", pos, {"r": r, "team": _team(w)})
		&"rime_aegis_shield":
			var u := _unit_at(pos)
			if u:
				_domes[u] = true
				_ensure(u, &"dome", true)
				var g := _g()
				if g:
					g.play(&"rime_aegis_shield", u.global_position, {"team": _team(w)})


func _flash_freeze(pos: Vector3, r: float) -> void:
	var set_root := _freezes[_freeze_next]
	_freeze_next = (_freeze_next + 1) % _freezes.size()
	var old: Variant = set_root.get_meta(&"tw") if set_root.has_meta(&"tw") else null
	if old is Tween and (old as Tween).is_valid():
		(old as Tween).kill()
	set_root.visible = true
	set_root.position = pos + Vector3.UP * 0.05
	var disc: MeshInstance3D = set_root.get_child(0)
	var shards: MultiMeshInstance3D = set_root.get_child(1)
	disc.scale = Vector3(r * 1.12, 1.0, r * 1.12)
	disc.set_instance_shader_parameter(&"seed", randf() * 10.0)
	disc.set_instance_shader_parameter(&"fade", 1.0)
	_layout_shards(shards.multimesh, r)
	shards.scale = Vector3(1.0, 0.02, 1.0)
	shards.position = Vector3.ZERO
	shards.visible = true
	_burst(&"snow_puff", pos + Vector3.UP * 0.4, r / 3.0)
	_burst(&"freeze_chips", pos + Vector3.UP * 0.2, r / 3.0)
	_ring(pos, 0.4, r * 1.15, ICE, 0.3, 0.07)
	_light_flash(pos + Vector3.UP * 1.8, ICE, LIGHT_FREEZE, r * 1.6, 0.6)
	var tw := set_root.create_tween()
	set_root.set_meta(&"tw", tw)
	tw.tween_property(shards, "scale", Vector3.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(FREEZE_HOLD)
	tw.tween_callback(_burst.bind(&"freeze_chips", pos + Vector3.UP * 0.4, r / 3.0))
	tw.tween_property(shards, "position", Vector3.DOWN * 1.7, 0.35).set_ease(Tween.EASE_IN)   # sink into the ground
	tw.tween_callback(func() -> void: shards.visible = false)
	tw.tween_method(func(v: float) -> void: disc.set_instance_shader_parameter(&"fade", v), 1.0, 0.0, 1.0)
	tw.tween_callback(func() -> void: set_root.visible = false)


## 20 shards: 14 on the rim leaning outward, 6 inside; random height / width / lean.
func _layout_shards(mm: MultiMesh, r: float) -> void:
	for i in SHARDS:
		var rim := i < 14
		var a := TAU * (float(i) / 14.0 + randf_range(-0.025, 0.025)) if rim else randf() * TAU
		var d := r * randf_range(0.82, 1.0) if rim else r * sqrt(randf()) * 0.7
		var out := Vector3(cos(a), 0.0, sin(a))
		var h := randf_range(0.8, 1.5) if rim else randf_range(0.5, 1.0)
		var wdt := randf_range(1.2, 2.0)
		var lean := randf_range(0.25, 0.55) if rim else randf_range(-0.3, 0.3)
		var k := Vector3.UP.cross(out).normalized()
		var rot := Basis(k, lean) * Basis(Vector3.UP, randf() * TAU)
		var b := rot * Basis.from_scale(Vector3(wdt, h, wdt))
		var base := out * d + Vector3.DOWN * 0.1
		mm.set_instance_transform(i, Transform3D(b, base + rot * Vector3(0.0, h * 0.5, 0.0)))


# ---------------------------------------------------------------- support autocast

func _on_support_cast(caster: Variant, target: Variant, kind: Variant) -> void:
	if not is_instance_valid(caster) or not is_instance_valid(target):
		return
	var now := Time.get_ticks_msec()
	if now - int(_support_last.get(caster, -1000)) < 60:
		return
	_support_last[caster] = now
	var c := caster as Node3D
	var t := target as Node3D
	var heal := StringName(str(kind)) == &"heal"
	var to := t.global_position + Vector3.UP * _height(t) * 0.6
	var from := _hand_of(c, to)
	_beam(from, to, NATURE if heal else ICE)
	if heal:
		_burst(&"heal_sparkle", to)
	elif t is Unit:
		_domes[t] = true
		_ensure(t as Unit, &"dome", true)


func _hand_of(c: Node3D, toward: Vector3) -> Vector3:
	var model: Variant = c.call(&"get_model") if c.has_method(&"get_model") else null
	if model and is_instance_valid(model) and (model as Node).has_method(&"get_beam_origin"):
		return (model as Node).call(&"get_beam_origin")
	var base := c.global_position + Vector3.UP * _height(c) * 0.85
	var dir := toward - base
	dir.y = 0.0
	return base + (dir.normalized() * _radius(c) if dir.length() > 0.01 else Vector3.ZERO)


func _beam(a: Vector3, b: Vector3, col: Color) -> void:
	var len := a.distance_to(b)
	if len < 0.1:
		return
	var beam := _beams[_beam_next]
	_beam_next = (_beam_next + 1) % _beams.size()
	var old: Variant = beam.get_meta(&"tw") if beam.has_meta(&"tw") else null
	if old is Tween and (old as Tween).is_valid():
		(old as Tween).kill()
	var mat := beam.material_override as StandardMaterial3D
	mat.albedo_color = Color(col.r, col.g, col.b, 0.75)   # alpha-blended, <= 1.0 (was additive x1.2)
	var dir := (b - a) / len
	var side := dir.cross(Vector3.FORWARD if absf(dir.dot(Vector3.FORWARD)) < 0.95 else Vector3.RIGHT).normalized()
	var fwd := side.cross(dir).normalized()
	beam.global_transform = Transform3D(Basis(side, dir * len, fwd), (a + b) * 0.5)
	beam.visible = true
	var tw := beam.create_tween()
	beam.set_meta(&"tw", tw)
	tw.tween_property(mat, "albedo_color:a", 0.0, BEAM_TIME).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void: beam.visible = false)


# ---------------------------------------------------------------- statuses (polled)

func _poll() -> void:
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u == null:
			continue
		var shown := u.is_alive() and u.is_visible_in_tree()
		var auras: Variant = _active.get(u)
		for s: StringName in STATUS_IDS:
			var on := shown and u.has_status(s)
			var has: bool = auras != null and (auras as Dictionary).has(s)
			if on != has:
				_ensure(u, s, on)
				auras = _active.get(u)
	for u: Variant in _domes.keys():
		if not is_instance_valid(u):
			_domes.erase(u)
			continue
		var unit := u as Unit
		var on := unit.is_alive() and unit.is_visible_in_tree() and unit.has_status(&"shield")
		if not on:
			_domes.erase(u)
		_ensure(unit, &"dome", on)


## Shows (on = true) or fades out aura `kind` on unit `u`. Does nothing if it is already in that state.
func _ensure(u: Unit, kind: StringName, on: bool) -> void:
	var auras: Dictionary = _active.get(u, {})
	if on == auras.has(kind):
		return
	if on:
		var root := _acquire(kind)
		if root == null:
			return
		_fit(root, kind, u)
		root.position = u.global_position
		auras[kind] = root
		_active[u] = auras
		_fade(root, kind, 0.0, 1.0, 0.2, false)
		if kind == &"chill":
			_set_overlay(u)
		if kind != &"dome":
			_hide_placeholder(u, kind)
	else:
		var root: Node3D = auras[kind]
		auras.erase(kind)
		if auras.is_empty():
			_active.erase(u)
		if kind == &"chill":
			_clear_overlay(u)
		_dying[root] = u
		_fade(root, kind, 1.0, 0.0, 0.3 if kind != &"frozen" else 0.2, true)


func _fade(root: Node3D, kind: StringName, from: float, to: float, time: float, release: bool) -> void:
	var old: Variant = root.get_meta(&"tw") if root.has_meta(&"tw") else null
	if old is Tween and (old as Tween).is_valid():
		(old as Tween).kill()
	for p: GPUParticles3D in root.get_meta(&"parts", []):
		p.emitting = not release
		if not release:
			p.restart()
	var tw := root.create_tween()
	root.set_meta(&"tw", tw)
	if kind == &"rooted":
		var holder: Node3D = root.get_child(0)
		var s: float = root.get_meta(&"size", 1.0)
		holder.scale = Vector3(s, maxf(0.01, s * from), s)
		tw.tween_property(holder, "scale", Vector3(s, maxf(0.01, s * to), s), time) \
				.set_trans(Tween.TRANS_BACK if not release else Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	else:
		tw.tween_method(_set_fade.bind(root), from, to, time)
	if kind == &"dome" and not release:
		root.scale = Vector3.ONE * 1.25
		tw.parallel().tween_property(root, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if release:
		tw.tween_callback(_release.bind(kind, root))


func _set_fade(v: float, root: Node3D) -> void:
	for g: GeometryInstance3D in root.get_meta(&"fx", []):
		g.set_instance_shader_parameter(&"fade", v)


func _release(kind: StringName, root: Node3D) -> void:
	if not is_instance_valid(root) or not root.visible:
		return
	var old: Variant = root.get_meta(&"tw") if root.has_meta(&"tw") else null
	if old is Tween and (old as Tween).is_valid():
		(old as Tween).kill()
	_dying.erase(root)
	root.visible = false
	root.scale = Vector3.ONE
	for p: GPUParticles3D in root.get_meta(&"parts", []):
		p.emitting = false
	(_free[kind] as Array).append(root)
	_live[kind] = int(_live[kind]) - 1


func _acquire(kind: StringName) -> Node3D:
	var free: Array = _free[kind]
	var root: Node3D
	if not free.is_empty():
		root = free.pop_back()
	elif int(_live[kind]) < int(AURA_CAPS[kind]):
		root = _build_aura(kind)
	else:
		return null
	_live[kind] = int(_live[kind]) + 1
	root.visible = true
	return root


## Sizes a pooled aura to its unit (radius / body height).
func _fit(root: Node3D, kind: StringName, u: Unit) -> void:
	var r := _radius(u)
	var h := _height(u)
	match kind:
		&"chill":
			var disc: MeshInstance3D = root.get_child(0)
			disc.scale = Vector3(r * 1.8, 1.0, r * 1.8)
			disc.set_instance_shader_parameter(&"seed", randf() * 10.0)
			var motes: GPUParticles3D = root.get_child(1)
			motes.scale = Vector3.ONE * clampf(r / 0.45, 0.8, 2.2)
			motes.position.y = h * 0.5
		&"frozen":
			var block: MeshInstance3D = root.get_child(0)
			block.scale = Vector3(r * 2.2, h * 1.1, r * 2.2)
			block.position.y = h * 0.55
			block.rotation.y = randf_range(-0.4, 0.4)
			block.set_instance_shader_parameter(&"seed", randf() * 10.0)
			var disc: MeshInstance3D = root.get_child(1)
			disc.scale = Vector3(r * 2.8, 1.0, r * 2.8)
			disc.set_instance_shader_parameter(&"seed", randf() * 10.0)
		&"rooted":
			root.set_meta(&"size", clampf(r / 0.45, 0.8, 2.2))
			root.get_child(0).rotation.y = randf() * TAU
		&"dome":
			var dome: MeshInstance3D = root.get_child(0)
			dome.scale = Vector3(r * 1.9 + 0.35, h * 0.7 + 0.3, r * 1.9 + 0.35)
			dome.set_instance_shader_parameter(&"phase", randf())


func _build_aura(kind: StringName) -> Node3D:
	var root := Node3D.new()
	root.name = "Aura_" + String(kind)
	add_child(root)
	var fx: Array[GeometryInstance3D] = []
	var parts: Array[GPUParticles3D] = []
	match kind:
		&"chill":
			var disc := _frost_disc()
			disc.material_override = _chill_frost_mat
			root.add_child(disc)
			fx.append(disc)
			var motes := _particles(_pmat(&"chill_motes"), 8, 1.4, false, true)
			root.add_child(motes)
			parts.append(motes)
		&"frozen":
			var block := MeshInstance3D.new()
			block.mesh = _box
			block.material_override = _block_mat
			block.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(block)
			fx.append(block)
			var disc := _frost_disc()
			disc.set_instance_shader_parameter(&"rim", 0.35)
			root.add_child(disc)
			fx.append(disc)
		&"rooted":
			var holder := Node3D.new()
			root.add_child(holder)
			var moss := _frost_disc()   # brown-green tangle on the ground
			moss.material_override = _moss_mat
			moss.scale = Vector3(0.95, 1.0, 0.95)
			holder.add_child(moss)
			for i in 5:   # thorns (kingdom-ice.md 2.1: cones r 0.08 h 0.5)
				var a := TAU * float(i) / 5.0 + randf_range(-0.2, 0.2)
				var out := Vector3(cos(a), 0.0, sin(a))
				var thorn := _mesh(_thorn_mesh, _thorn_mat)
				var lean := Basis(Vector3.UP.cross(out).normalized(), randf_range(0.2, 0.5))
				var sc := randf_range(1.6, 2.2)   # a bit over spec so they read from 30 m
				thorn.transform = Transform3D(lean * Basis.from_scale(Vector3.ONE * sc),
						out * randf_range(0.5, 0.65) + lean * Vector3(0.0, 0.25 * sc, 0.0))
				holder.add_child(thorn)
			for i in 4:   # roots crawling in from the ground
				var a := TAU * (float(i) + 0.5) / 4.0 + randf_range(-0.3, 0.3)
				var out := Vector3(cos(a), 0.0, sin(a))
				var root_seg := _mesh(_root_mesh, _bark_mat if i % 2 == 0 else _thorn_mat)
				var tilt := Basis(Vector3.UP.cross(out).normalized(), -1.25)   # lies down, top toward the unit
				root_seg.transform = Transform3D(tilt, out * 0.6 + Vector3.UP * 0.08)
				holder.add_child(root_seg)
		&"dome":
			var dome := MeshInstance3D.new()
			dome.mesh = _dome_mesh
			dome.material_override = _dome_mat
			dome.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(dome)
			fx.append(dome)
	root.set_meta(&"fx", fx)
	root.set_meta(&"parts", parts)
	return root


func _frost_disc() -> MeshInstance3D:
	var disc := _mesh(_plane, _frost_mat)
	disc.position.y = 0.04
	return disc


func _mesh(mesh: Mesh, mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return m


## Chill tint: one shared multiply overlay on the unit's body meshes (never replaces an existing overlay).
func _set_overlay(u: Unit) -> void:
	if _overlays.has(u):
		return
	var list: Array[GeometryInstance3D] = []
	for c in u.get_children():
		if c.get_class() == "Node3D" and not c.has_meta(META):
			_collect_meshes(c, list)
	_overlays[u] = list


func _collect_meshes(n: Node, list: Array[GeometryInstance3D]) -> void:
	for c in n.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).material_overlay == null:
			(c as MeshInstance3D).material_overlay = _overlay_mat
			list.append(c)
		_collect_meshes(c, list)


func _clear_overlay(u: Variant) -> void:
	var list: Variant = _overlays.get(u)
	_overlays.erase(u)
	if list == null:
		return
	for g: Variant in list:
		if is_instance_valid(g) and (g as GeometryInstance3D).material_overlay == _overlay_mat:
			(g as GeometryInstance3D).material_overlay = null


## Hides the Unit's placeholder look for `status` (its ice block, or its small coloured sphere mark).
func _hide_placeholder(u: Unit, status: StringName) -> void:
	var col: Color = (Unit.STATUSES.get(status, {}) as Dictionary).get("color", Color(0, 0, 0, 0))
	for c in u.get_children():
		var m := c as MeshInstance3D
		if m == null or m.has_meta(META):
			continue
		var mat := m.material_override as StandardMaterial3D
		if mat == null:
			continue
		var same := absf(mat.albedo_color.r - col.r) + absf(mat.albedo_color.g - col.g) + absf(mat.albedo_color.b - col.b) < 0.02
		if same and (m.mesh is BoxMesh or (m.mesh is SphereMesh and (m.mesh as SphereMesh).radius < 0.2)):
			m.visible = false


# ---------------------------------------------------------------- pooled building blocks

func _burst(look: StringName, pos: Vector3, size: float = 1.0) -> void:
	var pool: Array = _pools[look]
	var i: int = _pool_next[look]
	_pool_next[look] = (i + 1) % pool.size()
	var p: GPUParticles3D = pool[i]
	p.visible = true
	p.global_transform = Transform3D(Basis.from_scale(Vector3.ONE * clampf(size, 0.5, 3.0)), pos)
	p.restart()


func _attach_trail(p: Node3D) -> void:
	var e: GPUParticles3D
	if not _trail_free.is_empty():
		e = _trail_free.pop_back()
	elif _bolts.size() + _cooling.size() < TRAIL_POOL:
		e = _particles(_pmat(&"bolt_trail"), 28, 0.35, true, false)
		add_child(e)
	else:
		return
	e.global_position = p.global_position
	e.visible = true
	e.emitting = true
	e.restart()
	_bolts.append({"p": p, "e": e})


## Expanding glowing ring on the ground (vfx_ground.gdshader), pooled.
func _ring(pos: Vector3, r0: float, r1: float, col: Color, time: float, width: float) -> void:
	var ring := _rings[_ring_next]
	_ring_next = (_ring_next + 1) % _rings.size()
	var old: Variant = ring.get_meta(&"tw") if ring.has_meta(&"tw") else null
	if old is Tween and (old as Tween).is_valid():
		(old as Tween).kill()
	var mat := ring.material_override as ShaderMaterial
	mat.set_shader_parameter(&"fill_color", Color(STEEL, 0.06))
	mat.set_shader_parameter(&"ring_color", Color(col, 1.0))
	mat.set_shader_parameter(&"ring_width", width)
	mat.set_shader_parameter(&"fade", 1.0)
	ring.visible = true
	ring.position = pos + Vector3.UP * 0.07
	ring.scale = Vector3(r0, 1.0, r0)
	var tw := ring.create_tween().set_parallel(true)
	ring.set_meta(&"tw", tw)
	tw.tween_property(ring, "scale", Vector3(r1, 1.0, r1), time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter(&"fade", v), 1.0, 0.0, time).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func() -> void: ring.visible = false)


func _light_flash(pos: Vector3, col: Color, energy: float, reach: float, time: float) -> void:
	var g := _g()
	if g:   # Medium+: the G layer's pooled lights (same energy, attack / decay curve)
		g.light(pos, col, energy, reach, time)
		return
	var l := _lights[_light_next]
	_light_next = (_light_next + 1) % _lights.size()
	var old: Variant = l.get_meta(&"tw") if l.has_meta(&"tw") else null
	if old is Tween and (old as Tween).is_valid():
		(old as Tween).kill()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = reach
	l.position = pos
	l.visible = true
	var tw := l.create_tween()
	l.set_meta(&"tw", tw)
	tw.tween_property(l, "light_energy", 0.0, time).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void: l.visible = false)


func _particles(pmat: ParticleProcessMaterial, amount: int, lifetime: float, additive: bool,
		local: bool) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.process_material = pmat
	p.draw_pass_1 = _quad_add if additive else _quad_mix
	p.amount = amount
	p.lifetime = lifetime
	p.local_coords = local
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-6.0, -2.0, -6.0), Vector3(12.0, 8.0, 12.0))
	return p


func _find_projectile(w: Node3D) -> Node3D:
	var world := get_tree().current_scene if get_tree().current_scene else w.get_parent()
	var n := world.get_child_count()
	for i in range(n - 1, maxi(-1, n - 40), -1):
		var c := world.get_child(i)
		if c is Projectile and not c.has_meta(SPELL_META) and (c as Projectile).source == w:
			return c
	return null


func _unit_at(pos: Vector3) -> Unit:
	var best: Unit = null
	var best_d := 0.5
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u == null:
			continue
		var d := u.global_position.distance_to(pos)
		if d < best_d:
			best_d = d
			best = u
	return best


func _height(u: Node3D) -> float:
	var h: Variant = u.get(&"body_height")
	return float(h) if h != null else 1.6


func _radius(u: Node3D) -> float:
	var r: Variant = u.get(&"radius")
	return float(r) if r != null else 0.45


func _radius_of(w: Node3D, id: StringName, fallback: float) -> float:
	var caster := w.get_node_or_null(^"SpellCaster")
	if caster and caster.has_method(&"radius_of"):
		var r := float(caster.call(&"radius_of", id))
		if r > 0.0:
			return r
	return fallback


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
	_quad_add = _particle_quad(BaseMaterial3D.BLEND_MODE_ADD)
	_quad_mix = _particle_quad(BaseMaterial3D.BLEND_MODE_MIX)
	var chip_mat := StandardMaterial3D.new()
	chip_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	chip_mat.vertex_color_use_as_albedo = true
	chip_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_chip_mesh = CylinderMesh.new()
	_chip_mesh.top_radius = 0.0
	_chip_mesh.bottom_radius = 0.07
	_chip_mesh.height = 0.26
	_chip_mesh.radial_segments = 4
	_chip_mesh.rings = 0
	_chip_mesh.material = chip_mat
	_plane = PlaneMesh.new()
	_plane.size = Vector2(2.0, 2.0)
	_box = BoxMesh.new()
	_dome_mesh = SphereMesh.new()
	_dome_mesh.radius = 1.0
	_dome_mesh.height = 1.0
	_dome_mesh.is_hemisphere = true
	_dome_mesh.radial_segments = 24
	_dome_mesh.rings = 8
	_thorn_mesh = CylinderMesh.new()
	_thorn_mesh.top_radius = 0.0
	_thorn_mesh.bottom_radius = 0.08
	_thorn_mesh.height = 0.5
	_thorn_mesh.radial_segments = 5
	_thorn_mesh.rings = 0
	_root_mesh = CylinderMesh.new()
	_root_mesh.top_radius = 0.025
	_root_mesh.bottom_radius = 0.07
	_root_mesh.height = 0.8
	_root_mesh.radial_segments = 5
	_root_mesh.rings = 0
	_shard_mesh = CylinderMesh.new()
	_shard_mesh.top_radius = 0.0
	_shard_mesh.bottom_radius = 0.16
	_shard_mesh.height = 1.0
	_shard_mesh.radial_segments = 5
	_shard_mesh.rings = 0
	_beam_mesh = CylinderMesh.new()
	_beam_mesh.top_radius = 0.06
	_beam_mesh.bottom_radius = 0.1
	_beam_mesh.height = 1.0
	_beam_mesh.radial_segments = 8
	_beam_mesh.rings = 1
	# Blue-grey frost with cyan veins (the stock near-white frost read as snow blobs under every unit).
	_frost_mat = ShaderMaterial.new()
	_frost_mat.shader = FROST_SHADER
	_frost_mat.set_shader_parameter(&"frost_color", Color(0.50, 0.66, 0.80))
	_frost_mat.set_shader_parameter(&"glow_color", ICE)
	_frost_mat.set_shader_parameter(&"glow_energy", 0.85)
	_frost_mat.set_shader_parameter(&"opacity", 0.26)
	_chill_frost_mat = ShaderMaterial.new()
	_chill_frost_mat.shader = FROST_SHADER
	_chill_frost_mat.set_shader_parameter(&"frost_color", Color(0.46, 0.62, 0.78))
	_chill_frost_mat.set_shader_parameter(&"glow_color", ICE)
	_chill_frost_mat.set_shader_parameter(&"opacity", 0.26)
	_chill_frost_mat.set_shader_parameter(&"glow_energy", 1.0)
	_moss_mat = ShaderMaterial.new()
	_moss_mat.shader = FROST_SHADER
	_moss_mat.set_shader_parameter(&"frost_color", Color(0.45, 0.32, 0.14))
	_moss_mat.set_shader_parameter(&"glow_color", Color(0.5, 0.8, 0.2))
	_moss_mat.set_shader_parameter(&"glow_energy", 1.3)
	_moss_mat.set_shader_parameter(&"spikes", 6.0)
	_moss_mat.set_shader_parameter(&"opacity", 0.75)
	_block_mat = ShaderMaterial.new()
	_block_mat.shader = BLOCK_SHADER
	_dome_mat = ShaderMaterial.new()
	_dome_mat.shader = DOME_SHADER
	_thorn_mat = StandardMaterial3D.new()
	_thorn_mat.albedo_color = Color(0.30, 0.45, 0.15)
	_thorn_mat.roughness = 0.8
	_bark_mat = StandardMaterial3D.new()
	_bark_mat.albedo_color = Color(0.32, 0.22, 0.12)
	_bark_mat.roughness = 0.9
	_shard_mat = StandardMaterial3D.new()   # steel-blue crystal with a cyan edge light (was near-white + glow)
	_shard_mat.albedo_color = Color(0.36, 0.58, 0.78)
	_shard_mat.roughness = 0.15
	_shard_mat.metallic_specular = 0.8
	_shard_mat.emission_enabled = true
	_shard_mat.emission = Color(0.16, 0.55, 0.85)
	_shard_mat.emission_energy_multiplier = 0.45
	_shard_mat.rim_enabled = true
	_shard_mat.rim = 0.5
	_shard_mat.rim_tint = 0.6
	_overlay_mat = StandardMaterial3D.new()
	_overlay_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_overlay_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_overlay_mat.blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	_overlay_mat.albedo_color = CHILL_TINT
	_overlay_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	_overlay_mat.disable_receive_shadows = true
	for k: StringName in AURA_CAPS:
		_free[k] = []
		_live[k] = 0
		for i in int(AURA_PREBUILD.get(k, 0)):
			var aura := _build_aura(k)
			aura.visible = false
			for p: GPUParticles3D in aura.get_meta(&"parts", []):
				p.emitting = false
			(_free[k] as Array).append(aura)
	# Pools.
	for look: StringName in POOL_SIZES:
		var arr: Array[GPUParticles3D] = []
		for i in int(POOL_SIZES[look]):
			var p := _particles(_pmat(look), int(AMOUNTS[look]), float(LIFETIMES[look]), not MIX_LOOKS.has(look), false)
			if MESH_LOOKS.has(look):
				p.draw_pass_1 = _chip_mesh
			p.one_shot = true
			p.explosiveness = 0.9
			p.emitting = false
			p.visible = false
			add_child(p)
			arr.append(p)
		_pools[look] = arr
		_pool_next[look] = 0
	for i in MAX_LIGHTS:
		var l := OmniLight3D.new()
		l.shadow_enabled = false
		l.visible = false
		add_child(l)
		_lights.append(l)
	for i in BEAM_POOL:
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
		var beam := _mesh(_beam_mesh, mat)
		beam.visible = false
		add_child(beam)
		_beams.append(beam)
	for i in RING_POOL:
		var mat := ShaderMaterial.new()
		mat.shader = GROUND_SHADER
		mat.set_shader_parameter(&"ring_energy", RING_ENERGY)
		var ring := _mesh(_plane, mat)
		ring.visible = false
		add_child(ring)
		_rings.append(ring)
	for i in FREEZE_POOL:
		var root := Node3D.new()
		root.name = "FlashFreeze%d" % i
		root.visible = false
		add_child(root)
		var disc := _frost_disc()
		disc.set_instance_shader_parameter(&"rim", 1.0)
		root.add_child(disc)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = _shard_mesh
		mm.instance_count = SHARDS
		var shards := MultiMeshInstance3D.new()
		shards.multimesh = mm
		shards.material_override = _shard_mat
		shards.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(shards)
		_freezes.append(root)


func _particle_quad(blend: BaseMaterial3D.BlendMode) -> QuadMesh:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = blend
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = _soft_tex
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.disable_receive_shadows = true
	var q := QuadMesh.new()
	q.size = Vector2(1.0, 1.0)
	q.material = mat
	return q


## Particle process materials, one per look, shared by every emitter of that look.
func _pmat(key: StringName) -> ParticleProcessMaterial:
	if _pmats.has(key):
		return _pmats[key]
	var m := ParticleProcessMaterial.new()
	var ice_hot := Color(0.55, 1.0, 1.25, 1.0)   # <= 1.5 x: under the bloom (was up to 2.6)
	var ice := Color(0.25, 0.72, 1.05, 1.0)
	match key:
		&"chill_motes":
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			m.emission_box_extents = Vector3(0.5, 0.8, 0.5)
			m.direction = Vector3.UP
			m.spread = 30.0
			m.initial_velocity_min = 0.1
			m.initial_velocity_max = 0.35
			m.gravity = Vector3(0, -0.15, 0)
			_size(m, 0.06, 0.1, true)
			m.color_ramp = _ramp([Color(0.25, 0.72, 1.05, 0.0), Color(0.25, 0.72, 1.05, 0.85), Color(0.2, 0.5, 0.85, 0.0)])
		&"frost_cast":
			_shape_ring(m, 0.8, 0.1)
			m.direction = Vector3.UP
			m.spread = 10.0
			m.initial_velocity_min = 2.0
			m.initial_velocity_max = 4.0
			m.damping_min = 2.0
			m.damping_max = 3.0
			m.tangential_accel_min = 4.0
			m.tangential_accel_max = 6.0
			_size(m, 0.16, 0.26, false)
			m.color_ramp = _ramp([ice_hot, ice, Color(0.2, 0.55, 0.9, 0.0)])
		&"bolt_shatter":
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			m.emission_sphere_radius = 0.25
			m.direction = Vector3.UP
			m.spread = 90.0
			m.initial_velocity_min = 3.0
			m.initial_velocity_max = 6.0
			m.gravity = Vector3(0, -14.0, 0)
			m.angular_velocity_min = -400.0
			m.angular_velocity_max = 400.0
			m.particle_flag_rotate_y = true
			m.angle_min = -180.0
			m.angle_max = 180.0
			_size(m, 0.5, 0.9, false)
			m.color_ramp = _ramp([Color(0.55, 0.85, 1.0, 1.0), Color(0.3, 0.62, 0.9, 1.0), Color(0.22, 0.45, 0.72, 0.0)])
		&"freeze_chips":
			_shape_ring(m, 3.0, 0.1)
			m.emission_ring_inner_radius = 0.5
			m.direction = Vector3.UP
			m.spread = 35.0
			m.initial_velocity_min = 3.0
			m.initial_velocity_max = 6.5
			m.gravity = Vector3(0, -14.0, 0)
			m.particle_flag_rotate_y = true
			m.angle_min = -180.0
			m.angle_max = 180.0
			_size(m, 0.6, 1.1, false)
			m.color_ramp = _ramp([Color(0.55, 0.85, 1.0, 1.0), Color(0.3, 0.62, 0.9, 1.0), Color(0.22, 0.45, 0.72, 0.0)])
		&"snow_puff":
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			m.emission_sphere_radius = 0.6
			m.direction = Vector3.UP
			m.spread = 60.0
			m.initial_velocity_min = 0.5
			m.initial_velocity_max = 1.3
			m.gravity = Vector3(0, 0.3, 0)
			m.damping_min = 1.5
			m.damping_max = 2.5
			_size(m, 0.4, 0.7, true)   # half the old puff: a snow burst, not a white wall
			m.color_ramp = _ramp([Color(0.55, 0.74, 0.9, 0.0), Color(0.5, 0.72, 0.9, 0.38), Color(0.42, 0.62, 0.82, 0.0)])
		&"aegis_rise":
			_shape_ring(m, 1.6, 0.2)
			m.direction = Vector3.UP
			m.spread = 8.0
			m.initial_velocity_min = 2.0
			m.initial_velocity_max = 4.0
			m.damping_min = 1.0
			m.damping_max = 2.0
			m.tangential_accel_min = 2.0
			m.tangential_accel_max = 3.0
			_size(m, 0.14, 0.24, false)
			m.color_ramp = _ramp([ice_hot, ice, Color(0.2, 0.55, 0.9, 0.0)])
		&"heal_sparkle":
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			m.emission_sphere_radius = 0.4
			m.direction = Vector3.UP
			m.spread = 40.0
			m.initial_velocity_min = 0.8
			m.initial_velocity_max = 1.6
			_size(m, 0.14, 0.24, false)
			m.color_ramp = _ramp([Color(1.2, 2.2, 0.8, 1.0), Color(0.5, 1.6, 0.4, 1.0), Color(0.3, 1.0, 0.2, 0.0)])
		&"bolt_trail":
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			m.emission_sphere_radius = 0.1
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 0.2
			m.initial_velocity_max = 0.5
			m.gravity = Vector3(0, -0.4, 0)
			_size(m, 0.14, 0.24, false)
			m.color_ramp = _ramp([Color(0.4, 0.9, 1.15, 0.9), Color(0.22, 0.65, 1.0, 0.7), Color(0.15, 0.45, 0.85, 0.0)])
	_pmats[key] = m
	return m


func _shape_ring(m: ParticleProcessMaterial, r: float, h: float) -> void:
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	m.emission_ring_axis = Vector3.UP
	m.emission_ring_radius = r
	m.emission_ring_inner_radius = r * 0.85
	m.emission_ring_height = h


func _size(m: ParticleProcessMaterial, lo: float, hi: float, grow: bool) -> void:
	m.scale_min = lo
	m.scale_max = hi
	var c := Curve.new()
	if grow:
		c.add_point(Vector2(0.0, 0.3))
		c.add_point(Vector2(0.3, 1.0))
		c.add_point(Vector2(1.0, 0.2))
	else:
		c.add_point(Vector2(0.0, 1.0))
		c.add_point(Vector2(1.0, 0.1))
	var ct := CurveTexture.new()
	ct.curve = c
	m.scale_curve = ct


func _ramp(colors: Array) -> GradientTexture1D:
	var g := Gradient.new()
	var offsets := PackedFloat32Array()
	for i in colors.size():
		offsets.append(float(i) / float(colors.size() - 1))
	g.offsets = offsets
	g.colors = PackedColorArray(colors)
	var t := GradientTexture1D.new()
	t.gradient = g
	t.use_hdr = true
	return t
