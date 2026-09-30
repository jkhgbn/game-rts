class_name NatureVfx
extends Node3D
## Nature effects (task 8.V5, kingdom-nature.md 8 + 7.1). Add ONE of these to a level, next to IceVfx / SpellVfx /
## CombatVfx; it never edits gameplay code. It hooks:
##   SpellCaster (every wizard) spell_cast / spell_effect for Ysolde's ids:
##     cast of any of them       -> leaf swirl + small ring at the wizard
##     thornburst (point)        -> torn-soil scar with glowing root cracks (radius_of) + 12 thorn cones that erupt
##                                  (0 -> full in 0.15 s), hold, then crumble from the tip (0.6 s); dirt, dust, sparks
##     wild_bloom (area centre)  -> blooming circle (radius_of) that lasts the heal (SpellType duration_at, else 5 s),
##                                  30 rising petals + sparkles; every friendly unit inside at cast gets a green `+`
##                                  every 0.5 s tick while the heal lasts
##     call_the_thicket (point)  -> mossy grove circle (ring r 1.2) + leaf swirl; each Sapling does its own sprout
##   Summons (Unit with unit_type.id == &"sapling" or lifetime_total() > 0): sprout (soil mound, dirt, leaves, ring)
##     when spawned, wither (falling brown leaves, dust, dry litter) when it dies / its lifetime ends.
##   Support autocast `heal`: signal support_cast(caster, target, kind) on the unit's "SupportCaster" child, the unit
##     or the Events autoload -> vine beam (0.75, 1.00, 0.40) 0.25 s + pollen at the caster + `+` at the target.
##     IceVfx also draws a (plain green) heal beam: while an IceVfx is in the scene this node only adds the pollen and
##     the `+` (heal_beam_mode AUTO), so there is never a double beam.
##   Verdant regen: units with get_idle_regen_pct() > 0, hurt, alive, >= 4 s since damage, in the camera frustum and
##     < 45 m from the camera get 2 tiny leaf sparkles per second. ONE MultiMesh draws all of them (polled 4 / s).
##   Bramble Spire aura: every completed Nature building with aura_radius > 0 sends a slow green pulse ring out to
##     its aura radius every 4 s (skipped if its model has draws_aura_pulse() returning true).
## NOT here: `rooted` (thorns + roots at the feet) is drawn by IceVfx (kingdom-ice.md 2.1), so keep an IceVfx in every
## level where Nature can play. Budget: every burst, ring, beam, light, patch and spell set is pooled (no allocations
## per event after warm-up).

enum HealBeam { AUTO, ALWAYS, NEVER }

const META := &"nature_vfx"
const SUMMON_META := &"nature_vfx_summon"
const LEAF := Color(0.75, 1.0, 0.40)
const LEAF_DEEP := Color(0.42, 0.85, 0.25)
## Pale gold (in-game grade pass 2026-09-30): the Wild Bloom / Call the Thicket circles were the same green as the
## meadow; their rims, rings and petals are pale gold / cream now so they read on grass.
const GOLD := Color(1.0, 0.84, 0.48)
const NATURE_SPELLS: Array[StringName] = [&"thornburst", &"wild_bloom", &"call_the_thicket"]
const SAPLING_ID := &"sapling"
const POLL_INTERVAL := 0.25
const RESCAN_INTERVAL := 1.0
const REGEN_DELAY := 4.0          # Unit.IDLE_REGEN_DELAY
const REGEN_LOD_FAR := 45.0       # art-units.md 8: looping particles only < 45 m
const MAX_REGEN_UNITS := 160
const BLOOM_TICK := 0.5
const BLOOM_MAX_UNITS := 24
const SPIRE_PULSE := 4.0
const SPIRE_VIEW_DIST := 75.0
const THORNS := 12
const BEAM_TIME := 0.25
const MAX_LIGHTS := 2
const BEAM_POOL := 8
const RING_POOL := 10
const PATCH_POOL := 10
const THORN_POOL := 3
const BLOOM_POOL := 3
## look -> [amount, lifetime, draw pass, pool size]
const LOOKS := {
	&"leaf_cast": [18, 0.9, &"add_leaf", 3],
	&"dirt_chips": [16, 0.9, &"chip", 5],
	&"dust": [10, 1.2, &"mix_dot", 6],
	&"thorn_sparks": [14, 0.8, &"add_dot", 3],
	&"bloom_petals": [30, 2.4, &"mix_petal", 3],
	&"bloom_sparks": [24, 1.6, &"add_leaf", 3],
	&"plus": [2, 0.9, &"add_plus", 24],
	&"sprout_leaves": [12, 0.9, &"mix_leaf", 6],
	&"wither_leaves": [16, 2.0, &"mix_leaf", 6],
	&"pollen": [10, 0.8, &"add_dot", 8],
}

const GROUND_SHADER := preload("res://art/vfx/vfx_ground.gdshader")
const NGROUND_SHADER := preload("res://art/vfx/nature_ground.gdshader")
const THORN_SHADER := preload("res://art/vfx/nature_thorn.gdshader")
const BLOOM_SHADER := preload("res://art/vfx/nature_bloom.gdshader")
const MOTE_SHADER := preload("res://art/vfx/nature_mote.gdshader")
const BEAM_SHADER := preload("res://art/vfx/nature_beam.gdshader")

## AUTO: draw the heal beam only when no IceVfx is in the scene (IceVfx draws one). ALWAYS / NEVER force it.
@export var heal_beam_mode: HealBeam = HealBeam.AUTO
## Pulse ring of Nature aura buildings (Bramble Spire).
@export var spire_pulse := true

var _wizards: Array[Node3D] = []
var _support_last: Dictionary = {}   # caster -> msec (dedupe when two sources emit)
var _ice_present := false
var _pools: Dictionary = {}
var _pool_next: Dictionary = {}
var _pmats: Dictionary = {}
var _passes: Dictionary = {}
var _lights: Array[OmniLight3D] = []
var _light_next := 0
var _beams: Array[MeshInstance3D] = []
var _beam_next := 0
var _rings: Array[MeshInstance3D] = []
var _ring_next := 0
var _patches: Array[MeshInstance3D] = []
var _patch_next := 0
var _thorn_sets: Array[Node3D] = []
var _thorn_next := 0
var _bloom_discs: Array[MeshInstance3D] = []
var _bloom_next := 0
var _blooms: Array[Dictionary] = []        # {units: Array, left: float, next: float}
var _spires: Dictionary = {}               # Building -> seconds to next pulse
var _regen_units: Array[Unit] = []
var _regen_scan: Array[Unit] = []          # reused by _poll (no allocation per poll)
var _motes: MultiMeshInstance3D
var _poll_left := 0.0
var _rescan_left := 0.0

# Shared resources (built once).
var _plane: PlaneMesh
var _cone: CylinderMesh
var _beam_mesh: CylinderMesh
var _scar_mat: ShaderMaterial
var _grove_mat: ShaderMaterial
var _mound_mat: ShaderMaterial
var _litter_mat: ShaderMaterial
var _thorn_mat: ShaderMaterial
var _bloom_mat: ShaderMaterial


func _ready() -> void:
	top_level = true                  # effects are placed in world space
	global_transform = Transform3D.IDENTITY
	_build_shared()
	get_tree().node_added.connect(_on_node_added)
	var events := get_node_or_null(^"/root/Events")
	if events and events.has_signal(&"support_cast"):
		events.connect(&"support_cast", _on_support_cast)
	_rescan()


func _process(delta: float) -> void:
	_rescan_left -= delta
	if _rescan_left <= 0.0:
		_rescan_left = RESCAN_INTERVAL
		_rescan()
	_poll_left -= delta
	if _poll_left <= 0.0:
		_poll_left = POLL_INTERVAL
		_poll()
	_follow_regen()
	_tick_blooms(delta)
	if spire_pulse and not _spires.is_empty():
		_tick_spires(delta)


# ---------------------------------------------------------------- hooking

func _on_node_added(node: Node) -> void:
	if node is Unit:
		_hook.call_deferred(node, true)


func _rescan() -> void:
	for group: StringName in [&"units", &"heroes", &"enemy_heroes"]:
		for node in get_tree().get_nodes_in_group(group):
			if not node.has_meta(META):
				_hook(node, false)
	_ice_present = _find_ice()
	for node in get_tree().get_nodes_in_group(&"buildings"):
		var b := node as Building
		if b == null or _spires.has(b) or b.building_type == null:
			continue
		if b.building_type.faction == &"nature" and b.building_type.aura_radius > 0.0:
			_spires[b] = randf() * SPIRE_PULSE


func _find_ice() -> bool:
	for holder: Node in [get_parent(), get_tree().current_scene]:
		if holder == null:
			continue
		for c in holder.get_children():
			if c is IceVfx:
				return true
	return false


func _hook(node: Variant, fresh: bool) -> void:
	if not is_instance_valid(node) or not node is Unit:
		return
	var u := node as Unit
	if not u.has_meta(SUMMON_META) and _is_summon(u):
		u.set_meta(SUMMON_META, true)
		u.died.connect(_on_summon_died, CONNECT_ONE_SHOT)
		if fresh and u.is_alive():
			_sprout(u)
	if u.has_meta(META):
		return
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


func _is_summon(u: Unit) -> bool:
	if u.unit_type != null and u.unit_type.id == SAPLING_ID:
		return true
	return u.lifetime_total() > 0.0


# ---------------------------------------------------------------- spells

func _on_spell_cast(id: StringName, w: Node3D) -> void:
	if not NATURE_SPELLS.has(id) or not is_instance_valid(w):
		return
	var pos := w.global_position
	_burst(&"leaf_cast", pos + Vector3.UP * 0.1)
	_ring(pos, 0.3, 1.6, LEAF, 0.4, 0.1, 0.1)
	if id != &"thornburst":
		_light_flash(pos + Vector3.UP * 1.8, LEAF, 1.4, 6.0, 0.35)


func _on_spell_effect(id: StringName, pos: Vector3, w: Node3D) -> void:
	if not is_instance_valid(w):
		return
	match id:
		&"thornburst":
			_thornburst(pos, _radius_of(w, id, 3.0))
		&"wild_bloom":
			var r := _radius_of(w, id, 5.0)
			_wild_bloom(pos, r, _duration_of(w, id, 5.0), w)
		&"call_the_thicket":
			_thicket(pos, _radius_of(w, id, 1.2))


func _thornburst(pos: Vector3, r: float) -> void:
	var set_root := _thorn_sets[_thorn_next]
	_thorn_next = (_thorn_next + 1) % _thorn_sets.size()
	_kill_tween(set_root)
	set_root.visible = true
	set_root.position = pos + Vector3.UP * 0.03
	var disc: MeshInstance3D = set_root.get_child(0)
	var thorns: MultiMeshInstance3D = set_root.get_child(1)
	disc.scale = Vector3(r * 1.15, 1.0, r * 1.15)
	disc.set_instance_shader_parameter(&"seed", randf() * 10.0)
	disc.set_instance_shader_parameter(&"fade", 1.0)
	disc.set_instance_shader_parameter(&"glow", 1.0)
	_layout_thorns(thorns.multimesh, r)
	thorns.set_instance_shader_parameter(&"fade", 1.0)
	thorns.scale = Vector3(1.0, 0.02, 1.0)
	thorns.visible = true
	var s := r / 3.0
	_burst(&"dirt_chips", pos + Vector3.UP * 0.15, s)
	_burst(&"dust", pos + Vector3.UP * 0.3, s)
	_burst(&"thorn_sparks", pos + Vector3.UP * 0.1, s)
	_ring(pos, 0.4, r * 1.1, LEAF, 0.3, 0.08, 0.1)
	_light_flash(pos + Vector3.UP * 1.5, LEAF, 1.6, r * 3.0, 0.5)
	var tw := set_root.create_tween().set_parallel(true)
	set_root.set_meta(&"tw", tw)
	tw.tween_property(thorns, "scale", Vector3.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_method(_set_inst.bind(thorns, &"fade"), 1.0, 0.0, 0.6).set_delay(0.55)
	tw.tween_method(_set_inst.bind(disc, &"glow"), 1.0, 0.0, 1.4).set_delay(0.2)
	tw.tween_method(_set_inst.bind(disc, &"fade"), 1.0, 0.0, 1.0).set_delay(1.4)
	tw.chain().tween_callback(func() -> void: set_root.visible = false)


## 12 thorns: 8 on the rim leaning outward, 4 inside; random height (0.8 - 1.4 m) / width / lean.
func _layout_thorns(mm: MultiMesh, r: float) -> void:
	for i in THORNS:
		var rim := i < 8
		var a := TAU * (float(i) / 8.0 + randf_range(-0.04, 0.04)) if rim else TAU * (float(i - 8) / 4.0 + randf() * 0.2)
		var d := r * randf_range(0.6, 0.85) if rim else r * randf_range(0.15, 0.45)
		var out := Vector3(cos(a), 0.0, sin(a))
		var h := randf_range(1.1, 1.5) if rim else randf_range(0.8, 1.1)
		var wdt := randf_range(1.1, 1.6)
		var lean := randf_range(0.3, 0.6) if rim else randf_range(0.1, 0.35)
		var k := Vector3.UP.cross(out).normalized()
		var rot := Basis(k, lean) * Basis(Vector3.UP, randf() * TAU)
		var b := rot * Basis.from_scale(Vector3(wdt, h, wdt))
		var base := out * d + Vector3.DOWN * 0.05
		mm.set_instance_transform(i, Transform3D(b, base + rot * Vector3(0.0, h * 0.5, 0.0)))


func _wild_bloom(pos: Vector3, r: float, dur: float, w: Node3D) -> void:
	var disc := _bloom_discs[_bloom_next]
	_bloom_next = (_bloom_next + 1) % _bloom_discs.size()
	_kill_tween(disc)
	disc.visible = true
	disc.position = pos + Vector3.UP * 0.06
	disc.scale = Vector3(r, 1.0, r)
	disc.set_instance_shader_parameter(&"seed", randf() * TAU)
	disc.set_instance_shader_parameter(&"fade", 1.0)
	disc.set_instance_shader_parameter(&"grow", 0.0)
	var tw := disc.create_tween()
	disc.set_meta(&"tw", tw)
	tw.tween_method(_set_inst.bind(disc, &"grow"), 0.0, 1.0, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_interval(maxf(0.2, dur - 1.0))
	tw.tween_method(_set_inst.bind(disc, &"fade"), 1.0, 0.0, 0.6)
	tw.tween_callback(func() -> void: disc.visible = false)
	var s := r / 5.0
	_burst(&"bloom_petals", pos + Vector3.UP * 0.2, s)
	_burst(&"bloom_sparks", pos + Vector3.UP * 0.2, s)
	_ring(pos, 0.5, r, GOLD, 0.5, 0.06, 0.08)
	_light_flash(pos + Vector3.UP * 2.0, LEAF, 1.6, r + 4.0, 0.8)
	# Friendly units inside at cast get a `+` every tick while the heal lasts (kingdom-nature.md 3.1: not
	# buildings, not Saplings).
	var team: int = int(w.get(&"team")) if w.get(&"team") != null else -1
	var list: Array = []
	var r2 := r * r
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u == null or not u.is_alive() or u.team != team or u.has_meta(SUMMON_META):
			continue
		var d := u.global_position - pos
		if d.x * d.x + d.z * d.z <= r2:
			list.append(u)
			if list.size() >= BLOOM_MAX_UNITS:
				break
	if not list.is_empty():
		_blooms.append({"units": list, "left": dur, "next": BLOOM_TICK})


func _tick_blooms(delta: float) -> void:
	for i in range(_blooms.size() - 1, -1, -1):
		var b: Dictionary = _blooms[i]
		b["left"] = float(b["left"]) - delta
		b["next"] = float(b["next"]) - delta
		if float(b["next"]) <= 0.0:
			b["next"] = float(b["next"]) + BLOOM_TICK
			for u: Variant in b["units"]:
				if is_instance_valid(u) and (u as Unit).is_alive() and (u as Unit).is_visible_in_tree():
					var n := u as Unit
					_burst(&"plus", n.global_position + Vector3.UP * (_height(n) + 0.25))
		if float(b["left"]) <= 0.01:
			_blooms.remove_at(i)


func _thicket(pos: Vector3, r: float) -> void:
	_patch(pos, r * 1.9, _grove_mat, 1.6, 1.0)
	_burst(&"leaf_cast", pos + Vector3.UP * 0.1, 1.4)
	_burst(&"dust", pos + Vector3.UP * 0.2, 0.8)
	_ring(pos, 0.3, r * 2.0, GOLD, 0.45, 0.08, 0.06)
	_light_flash(pos + Vector3.UP * 1.5, LEAF, 1.4, 7.0, 0.6)


# ---------------------------------------------------------------- summons

func _sprout(u: Unit) -> void:
	var pos := u.global_position
	var s := clampf(_radius(u) / 0.4, 0.8, 2.0)
	_patch(pos, 0.9 * s, _mound_mat, 0.9, 0.8)
	_burst(&"dirt_chips", pos + Vector3.UP * 0.1, 0.55 * s)
	_burst(&"sprout_leaves", pos + Vector3.UP * 0.3, s)
	_ring(pos, 0.2, 1.1 * s, LEAF, 0.4, 0.14, 0.1)


func _on_summon_died(u: Unit) -> void:
	if not is_instance_valid(u) or not u.is_inside_tree():
		return
	var pos := u.global_position
	var s := clampf(_radius(u) / 0.4, 0.8, 2.0)
	_burst(&"wither_leaves", pos + Vector3.UP * _height(u) * 0.8, s)
	_burst(&"dust", pos + Vector3.UP * 0.25, 0.5 * s)
	_patch(pos, 0.9 * s, _litter_mat, 1.6, 1.2)


# ---------------------------------------------------------------- support autocast (heal)

func _on_support_cast(caster: Variant, target: Variant, kind: Variant) -> void:
	if StringName(str(kind)) != &"heal" or not is_instance_valid(caster) or not is_instance_valid(target):
		return
	var now := Time.get_ticks_msec()
	if now - int(_support_last.get(caster, -1000)) < 60:
		return
	_support_last[caster] = now
	var c := caster as Node3D
	var t := target as Node3D
	var to := t.global_position + Vector3.UP * _height(t) * 0.6
	var from := _hand_of(c, to)
	if heal_beam_mode == HealBeam.ALWAYS or (heal_beam_mode == HealBeam.AUTO and not _ice_present):
		_beam(from, to)
	_burst(&"pollen", from)
	_burst(&"plus", t.global_position + Vector3.UP * (_height(t) + 0.25))


func _hand_of(c: Node3D, toward: Vector3) -> Vector3:
	var model: Variant = c.call(&"get_model") if c.has_method(&"get_model") else null
	if model and is_instance_valid(model) and (model as Node).has_method(&"get_beam_origin"):
		return (model as Node).call(&"get_beam_origin")
	var base := c.global_position + Vector3.UP * _height(c) * 0.85
	var dir := toward - base
	dir.y = 0.0
	return base + (dir.normalized() * _radius(c) if dir.length() > 0.01 else Vector3.ZERO)


func _beam(a: Vector3, b: Vector3) -> void:
	var len := a.distance_to(b)
	if len < 0.1:
		return
	var beam := _beams[_beam_next]
	_beam_next = (_beam_next + 1) % _beams.size()
	_kill_tween(beam)
	var dir := (b - a) / len
	var side := dir.cross(Vector3.FORWARD if absf(dir.dot(Vector3.FORWARD)) < 0.95 else Vector3.RIGHT).normalized()
	var fwd := side.cross(dir).normalized()
	beam.global_transform = Transform3D(Basis(side, dir * len, fwd), (a + b) * 0.5)
	beam.set_instance_shader_parameter(&"fade", 1.0)
	beam.visible = true
	var tw := beam.create_tween()
	beam.set_meta(&"tw", tw)
	tw.tween_method(_set_inst.bind(beam, &"fade"), 1.0, 0.0, BEAM_TIME).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void: beam.visible = false)


# ---------------------------------------------------------------- Verdant regen motes (polled)

func _poll() -> void:
	var cam := get_viewport().get_camera_3d()
	var cam_pos := cam.global_position if cam else Vector3.ZERO
	var far2 := REGEN_LOD_FAR * REGEN_LOD_FAR
	_regen_scan.clear()
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u == null or u.get_idle_regen_pct() <= 0.0:
			continue
		if u.hp >= u.max_hp or not u.is_alive() or u.seconds_since_damage() < REGEN_DELAY:
			continue
		var p := u.global_position
		if cam and (cam_pos.distance_squared_to(p) > far2 or not cam.is_position_in_frustum(p + Vector3.UP)):
			continue
		if not u.is_visible_in_tree():
			continue
		_regen_scan.append(u)
		if _regen_scan.size() >= MAX_REGEN_UNITS:
			break
	if _regen_scan == _regen_units:
		return
	_regen_units.assign(_regen_scan)
	var mm := _motes.multimesh
	for i in _regen_units.size():
		var u := _regen_units[i]
		var ph := fmod(float(u.get_instance_id() % 9973) * 0.6180339, 1.0)
		var custom := Color(ph, _radius(u) * 1.15, _height(u), clampf(_height(u) / 1.6, 0.85, 1.4))
		mm.set_instance_custom_data(i * 2, custom)
		custom.r = fmod(ph + 0.5, 1.0)
		mm.set_instance_custom_data(i * 2 + 1, custom)
	mm.visible_instance_count = _regen_units.size() * 2
	_motes.visible = not _regen_units.is_empty()


func _follow_regen() -> void:
	if _regen_units.is_empty():
		return
	var mm := _motes.multimesh
	for i in _regen_units.size():
		var u := _regen_units[i]
		if not is_instance_valid(u):
			mm.set_instance_custom_data(i * 2, Color(0, 0, 0, 0))
			mm.set_instance_custom_data(i * 2 + 1, Color(0, 0, 0, 0))
			continue
		var t := Transform3D(Basis.IDENTITY, u.global_position)
		mm.set_instance_transform(i * 2, t)
		mm.set_instance_transform(i * 2 + 1, t)


# ---------------------------------------------------------------- Bramble Spire aura pulse

func _tick_spires(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	for b: Variant in _spires.keys():
		if not is_instance_valid(b) or not (b as Building).is_alive():
			_spires.erase(b)
			continue
		var left := float(_spires[b]) - delta
		if left > 0.0:
			_spires[b] = left
			continue
		_spires[b] = left + SPIRE_PULSE
		var bld := b as Building
		if not bld.is_constructed() or not bld.is_visible_in_tree():
			continue
		var pos := bld.global_position
		if cam and cam.global_position.distance_to(pos) > SPIRE_VIEW_DIST:
			continue
		var model: Variant = bld.get(&"_model")
		if model is Node and is_instance_valid(model) and (model as Node).has_method(&"draws_aura_pulse") \
				and bool((model as Node).call(&"draws_aura_pulse")):
			continue
		_ring(pos, 1.2, bld.building_type.aura_radius, LEAF, 1.8, 0.035, 0.04)


# ---------------------------------------------------------------- pooled building blocks

func _burst(look: StringName, pos: Vector3, size: float = 1.0) -> void:
	var pool: Array = _pools[look]
	var i: int = _pool_next[look]
	_pool_next[look] = (i + 1) % pool.size()
	var p: GPUParticles3D = pool[i]
	p.visible = true
	p.global_transform = Transform3D(Basis.from_scale(Vector3.ONE * clampf(size, 0.4, 3.0)), pos)
	p.restart()


## Expanding glowing ring on the ground (vfx_ground.gdshader), pooled.
func _ring(pos: Vector3, r0: float, r1: float, col: Color, time: float, width: float, fill_a: float) -> void:
	var ring := _rings[_ring_next]
	_ring_next = (_ring_next + 1) % _rings.size()
	_kill_tween(ring)
	var mat := ring.material_override as ShaderMaterial
	mat.set_shader_parameter(&"fill_color", Color(col, fill_a))
	mat.set_shader_parameter(&"ring_color", Color(col, 1.0))
	mat.set_shader_parameter(&"ring_width", width)
	mat.set_shader_parameter(&"fade", 1.0)
	ring.visible = true
	ring.position = pos + Vector3.UP * 0.08
	ring.scale = Vector3(r0, 1.0, r0)
	var tw := ring.create_tween().set_parallel(true)
	ring.set_meta(&"tw", tw)
	tw.tween_property(ring, "scale", Vector3(r1, 1.0, r1), time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter(&"fade", v), 1.0, 0.0, time).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func() -> void: ring.visible = false)


## Ground patch (nature_ground.gdshader): pops in, holds, fades.
func _patch(pos: Vector3, r: float, mat: ShaderMaterial, hold: float, fade_time: float) -> void:
	var patch := _patches[_patch_next]
	_patch_next = (_patch_next + 1) % _patches.size()
	_kill_tween(patch)
	patch.material_override = mat
	patch.position = pos + Vector3.UP * 0.05
	patch.scale = Vector3(r * 0.4, 1.0, r * 0.4)
	patch.set_instance_shader_parameter(&"seed", randf() * 10.0)
	patch.set_instance_shader_parameter(&"fade", 1.0)
	patch.set_instance_shader_parameter(&"glow", 1.0)
	patch.visible = true
	var tw := patch.create_tween()
	patch.set_meta(&"tw", tw)
	tw.tween_property(patch, "scale", Vector3(r, 1.0, r), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_method(_set_inst.bind(patch, &"glow"), 1.0, 0.0, hold + fade_time)
	tw.tween_interval(hold)
	tw.tween_method(_set_inst.bind(patch, &"fade"), 1.0, 0.0, fade_time)
	tw.tween_callback(func() -> void: patch.visible = false)


func _light_flash(pos: Vector3, col: Color, energy: float, reach: float, time: float) -> void:
	var l := _lights[_light_next]
	_light_next = (_light_next + 1) % _lights.size()
	_kill_tween(l)
	l.light_color = col
	l.light_energy = energy
	l.omni_range = reach
	l.position = pos
	l.visible = true
	var tw := l.create_tween()
	l.set_meta(&"tw", tw)
	tw.tween_property(l, "light_energy", 0.0, time).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void: l.visible = false)


func _set_inst(v: float, g: GeometryInstance3D, param: StringName) -> void:
	g.set_instance_shader_parameter(param, v)


func _kill_tween(n: Node) -> void:
	var old: Variant = n.get_meta(&"tw") if n.has_meta(&"tw") else null
	if old is Tween and (old as Tween).is_valid():
		(old as Tween).kill()


func _mesh(mesh: Mesh, mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.visible = false
	return m


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


func _duration_of(w: Node3D, id: StringName, fallback: float) -> float:
	var caster := w.get_node_or_null(^"SpellCaster")
	if caster and caster.has_method(&"spell_type") and caster.has_method(&"rank_of"):
		var t: Variant = caster.call(&"spell_type", id)
		if t is SpellType:
			var d := (t as SpellType).duration_at(maxi(1, int(caster.call(&"rank_of", id))))
			if d > 0.0:
				return d
	return fallback


# ---------------------------------------------------------------- shared resources

func _build_shared() -> void:
	_plane = PlaneMesh.new()
	_plane.size = Vector2(2.0, 2.0)
	_cone = CylinderMesh.new()
	_cone.top_radius = 0.0
	_cone.bottom_radius = 0.17
	_cone.height = 1.0
	_cone.radial_segments = 6
	_cone.rings = 1
	_beam_mesh = CylinderMesh.new()
	_beam_mesh.top_radius = 0.13
	_beam_mesh.bottom_radius = 0.17
	_beam_mesh.height = 1.0
	_beam_mesh.radial_segments = 8
	_beam_mesh.rings = 1
	_scar_mat = _ground_mat(Color(0.17, 0.11, 0.06), Color(0.30, 0.46, 0.12), 0.15, 1.6, 0.88, 0.0, 7.0)
	_grove_mat = _ground_mat(Color(0.20, 0.14, 0.07), Color(0.40, 0.46, 0.18), 0.55, 1.3, 0.8, 1.0, 6.0)
	_grove_mat.set_shader_parameter(&"rim_color", GOLD)
	_mound_mat = _ground_mat(Color(0.24, 0.16, 0.08), Color(0.30, 0.46, 0.13), 0.35, 1.2, 0.85, 0.0, 5.0)
	_litter_mat = _ground_mat(Color(0.26, 0.17, 0.08), Color(0.55, 0.38, 0.14), 0.7, 0.0, 0.75, 0.0, 5.0)
	_thorn_mat = ShaderMaterial.new()
	_thorn_mat.shader = THORN_SHADER
	_bloom_mat = ShaderMaterial.new()
	_bloom_mat.shader = BLOOM_SHADER
	var beam_mat := ShaderMaterial.new()
	beam_mat.shader = BEAM_SHADER
	_build_passes()
	for look: StringName in LOOKS:
		var spec: Array = LOOKS[look]
		var arr: Array[GPUParticles3D] = []
		for i in int(spec[3]):
			var p := GPUParticles3D.new()
			p.process_material = _pmat(look)
			p.draw_pass_1 = _passes[spec[2]]
			p.amount = int(spec[0])
			p.lifetime = float(spec[1])
			p.one_shot = true
			p.explosiveness = 0.6 if look == &"bloom_petals" or look == &"wither_leaves" else 0.9
			p.local_coords = false
			p.emitting = false
			p.visible = false
			p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			p.visibility_aabb = AABB(Vector3(-7.0, -2.0, -7.0), Vector3(14.0, 9.0, 14.0))
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
		var beam := _mesh(_beam_mesh, beam_mat)
		add_child(beam)
		_beams.append(beam)
	for i in RING_POOL:
		var mat := ShaderMaterial.new()
		mat.shader = GROUND_SHADER
		mat.set_shader_parameter(&"ring_energy", 2.6)
		var ring := _mesh(_plane, mat)
		add_child(ring)
		_rings.append(ring)
	for i in PATCH_POOL:
		var patch := _mesh(_plane, _mound_mat)
		add_child(patch)
		_patches.append(patch)
	for i in BLOOM_POOL:
		var disc := _mesh(_plane, _bloom_mat)
		add_child(disc)
		_bloom_discs.append(disc)
	for i in THORN_POOL:
		var root := Node3D.new()
		root.name = "Thornburst%d" % i
		root.visible = false
		add_child(root)
		var disc := _mesh(_plane, _scar_mat)
		disc.visible = true
		root.add_child(disc)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = _cone
		mm.instance_count = THORNS
		var thorns := MultiMeshInstance3D.new()
		thorns.multimesh = mm
		thorns.material_override = _thorn_mat
		thorns.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON   # big thorns: a shadow grounds them
		root.add_child(thorns)
		_thorn_sets.append(root)
	# Verdant regen motes: one MultiMesh, 2 instances per unit, everything animated in nature_mote.gdshader.
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	var mote_mat := ShaderMaterial.new()
	mote_mat.shader = MOTE_SHADER
	var mmm := MultiMesh.new()
	mmm.transform_format = MultiMesh.TRANSFORM_3D
	mmm.use_custom_data = true
	mmm.mesh = quad
	mmm.instance_count = MAX_REGEN_UNITS * 2
	mmm.visible_instance_count = 0
	_motes = MultiMeshInstance3D.new()
	_motes.name = "RegenMotes"
	_motes.multimesh = mmm
	_motes.material_override = mote_mat
	_motes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_motes.custom_aabb = AABB(Vector3(-2000.0, -50.0, -2000.0), Vector3(4000.0, 100.0, 4000.0))
	_motes.visible = false
	add_child(_motes)


func _ground_mat(soil: Color, moss: Color, moss_amount: float, glow_energy: float, opacity: float,
		rim: float, cracks: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = NGROUND_SHADER
	m.set_shader_parameter(&"soil_color", soil)
	m.set_shader_parameter(&"moss_color", moss)
	m.set_shader_parameter(&"moss_amount", moss_amount)
	m.set_shader_parameter(&"glow_energy", glow_energy)
	m.set_shader_parameter(&"opacity", opacity)
	m.set_shader_parameter(&"rim_glow", rim)
	m.set_shader_parameter(&"cracks", cracks)
	return m


## Draw passes: billboard quads with a generated shape texture (soft dot, leaf, petal, plus) + a clod mesh.
func _build_passes() -> void:
	var dot := _shape_tex(&"dot")
	var leaf := _shape_tex(&"leaf")
	var petal := _shape_tex(&"petal")
	var plus := _shape_tex(&"plus")
	_passes[&"add_dot"] = _particle_quad(dot, BaseMaterial3D.BLEND_MODE_ADD, 1.0)
	_passes[&"mix_dot"] = _particle_quad(dot, BaseMaterial3D.BLEND_MODE_MIX, 1.0)
	_passes[&"add_leaf"] = _particle_quad(leaf, BaseMaterial3D.BLEND_MODE_ADD, 1.0)
	_passes[&"mix_leaf"] = _particle_quad(leaf, BaseMaterial3D.BLEND_MODE_MIX, 1.0)
	_passes[&"mix_petal"] = _particle_quad(petal, BaseMaterial3D.BLEND_MODE_MIX, 1.0)
	_passes[&"add_plus"] = _particle_quad(plus, BaseMaterial3D.BLEND_MODE_ADD, 1.0)
	# The heal + floats over the unit like combat text: never hidden behind helmets and shields.
	((_passes[&"add_plus"] as QuadMesh).material as StandardMaterial3D).no_depth_test = true
	var clod_mat := StandardMaterial3D.new()
	clod_mat.vertex_color_use_as_albedo = true
	clod_mat.roughness = 1.0
	clod_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var clod := SphereMesh.new()
	clod.radius = 0.11
	clod.height = 0.14
	clod.radial_segments = 5
	clod.rings = 2
	clod.material = clod_mat
	_passes[&"chip"] = clod


func _particle_quad(tex: Texture2D, blend: BaseMaterial3D.BlendMode, size: float) -> QuadMesh:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = blend
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.billboard_keep_scale = true   # Godot 4.7: without it the particle scale (scale_min/max, scale_curve) is ignored
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = tex
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.disable_receive_shadows = true
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	q.material = mat
	return q


## 64 x 64 white shape textures (alpha = shape), tinted by the particle colour. Built once.
func _shape_tex(kind: StringName) -> ImageTexture:
	var n := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var u := (float(x) + 0.5) / float(n) * 2.0 - 1.0
			var v := (float(y) + 0.5) / float(n) * 2.0 - 1.0
			var a := 0.0
			var shade := 1.0
			match kind:
				&"dot":
					var r := sqrt(u * u + v * v)
					a = clampf(1.0 - r, 0.0, 1.0)
					a = a * a * (3.0 - 2.0 * a)
				&"leaf":
					# Pointed leaf along v (tip at the top), bright midrib.
					var t := (v + 0.9) / 1.8
					var w := 0.42 * sin(clampf(t, 0.0, 1.0) * PI) * (1.0 - 0.3 * t)
					a = clampf((w - absf(u)) / 0.08, 0.0, 1.0) * (1.0 if t >= 0.0 and t <= 1.0 else 0.0)
					shade = 0.75 + 0.25 * (1.0 - clampf(absf(u) / maxf(w, 0.01), 0.0, 1.0)) \
							+ 0.3 * clampf(1.0 - absf(u) / 0.05, 0.0, 1.0)
				&"petal":
					# Rounded teardrop: wide at the top, pinched at the base; lighter toward the edge.
					var t := (v + 0.85) / 1.7
					var w := 0.5 * pow(clampf(t, 0.0, 1.0), 0.6) * sqrt(clampf(1.0 - pow(t * 1.05 - 0.05, 4.0), 0.0, 1.0))
					a = clampf((w - absf(u)) / 0.07, 0.0, 1.0) * (1.0 if t >= 0.0 and t <= 1.0 else 0.0)
					shade = 0.8 + 0.2 * t
				&"plus":
					var bar := maxf(clampf((0.17 - absf(u)) / 0.06, 0.0, 1.0) * clampf((0.78 - absf(v)) / 0.06, 0.0, 1.0),
							clampf((0.17 - absf(v)) / 0.06, 0.0, 1.0) * clampf((0.78 - absf(u)) / 0.06, 0.0, 1.0))
					var r := sqrt(u * u + v * v)
					var halo := clampf(1.0 - r, 0.0, 1.0) * 0.3
					a = maxf(bar, halo)
					shade = 0.6 + 0.4 * bar
			img.set_pixel(x, y, Color(shade, shade, shade, a))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## Particle process materials, one per look, shared by every emitter of that look.
func _pmat(key: StringName) -> ParticleProcessMaterial:
	if _pmats.has(key):
		return _pmats[key]
	var m := ParticleProcessMaterial.new()
	var glow := Color(0.9, 1.5, 0.5, 1.0)
	var glow_soft := Color(0.6, 1.2, 0.35, 1.0)
	match key:
		&"leaf_cast":
			_shape_ring(m, 0.8, 0.1)
			m.direction = Vector3.UP
			m.spread = 12.0
			m.initial_velocity_min = 2.0
			m.initial_velocity_max = 3.8
			m.damping_min = 2.0
			m.damping_max = 3.0
			m.tangential_accel_min = 4.0
			m.tangential_accel_max = 6.0
			m.angle_min = -180.0
			m.angle_max = 180.0
			m.angular_velocity_min = -200.0
			m.angular_velocity_max = 200.0
			_size(m, 0.8, 1.1, false)
			m.color_ramp = _ramp([glow, glow_soft, Color(0.5, 1.2, 0.3, 0.0)])
		&"dirt_chips":
			_shape_disc(m, 0.9)
			m.direction = Vector3.UP
			m.spread = 35.0
			m.initial_velocity_min = 3.0
			m.initial_velocity_max = 6.0
			m.gravity = Vector3(0, -16.0, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			m.particle_flag_rotate_y = true
			_size(m, 0.8, 1.8, false)
			m.color_initial_ramp = _ramp(_lin([Color(0.36, 0.24, 0.12), Color(0.26, 0.17, 0.09), Color(0.30, 0.38, 0.14)]))
			m.color_ramp = _ramp([Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
		&"dust":
			_shape_disc(m, 1.0)
			m.direction = Vector3.UP
			m.spread = 60.0
			m.initial_velocity_min = 0.6
			m.initial_velocity_max = 1.6
			m.gravity = Vector3(0, 0.2, 0)
			m.damping_min = 1.5
			m.damping_max = 2.5
			m.angle_min = -180.0
			m.angle_max = 180.0
			_size(m, 1.4, 2.2, true)
			m.color_ramp = _ramp(_lin([Color(0.45, 0.37, 0.25, 0.0), Color(0.42, 0.34, 0.22, 0.4), Color(0.40, 0.33, 0.22, 0.0)]))
		&"thorn_sparks":
			_shape_disc(m, 2.2)
			m.direction = Vector3.UP
			m.spread = 25.0
			m.initial_velocity_min = 2.5
			m.initial_velocity_max = 5.0
			m.gravity = Vector3(0, -4.0, 0)
			m.damping_min = 1.0
			m.damping_max = 2.0
			m.angle_min = -180.0
			m.angle_max = 180.0
			_size(m, 0.3, 0.45, false)
			m.color_ramp = _ramp([Color(0.95, 1.25, 0.5, 1.0), Color(0.6, 1.0, 0.3, 1.0), Color(0.3, 0.7, 0.15, 0.0)])
		&"bloom_petals":
			_shape_disc(m, 4.2)
			m.direction = Vector3.UP
			m.spread = 25.0
			m.initial_velocity_min = 1.0
			m.initial_velocity_max = 2.2
			m.gravity = Vector3(0, -0.25, 0)
			m.damping_min = 0.4
			m.damping_max = 0.8
			m.tangential_accel_min = 0.6
			m.tangential_accel_max = 1.2
			m.angle_min = -180.0
			m.angle_max = 180.0
			m.angular_velocity_min = -160.0
			m.angular_velocity_max = 160.0
			m.turbulence_enabled = true
			m.turbulence_noise_strength = 1.2
			m.turbulence_noise_scale = 3.0
			m.turbulence_influence_min = 0.05
			m.turbulence_influence_max = 0.12
			_size(m, 0.8, 1.1, true)
			m.color_initial_ramp = _ramp(_lin([Color(1.0, 0.86, 0.50), Color(1.0, 0.95, 0.74), Color(1.0, 0.72, 0.80),
					Color(0.98, 0.9, 0.58), Color(1.0, 0.8, 0.45)]))
			m.color_ramp = _ramp([Color(1, 1, 1, 0.0), Color(1, 1, 1, 1.0), Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.0)])
		&"bloom_sparks":
			_shape_disc(m, 4.5)
			m.direction = Vector3.UP
			m.spread = 10.0
			m.initial_velocity_min = 1.2
			m.initial_velocity_max = 2.8
			m.damping_min = 0.6
			m.damping_max = 1.2
			m.angle_min = -180.0
			m.angle_max = 180.0
			_size(m, 0.5, 0.7, false)
			m.color_ramp = _ramp([glow, glow_soft, Color(0.5, 1.2, 0.3, 0.0)])
		&"plus":
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			m.emission_sphere_radius = 0.25
			m.direction = Vector3.UP
			m.spread = 15.0
			m.initial_velocity_min = 0.9
			m.initial_velocity_max = 1.4
			m.damping_min = 0.8
			m.damping_max = 1.2
			m.angle_min = -6.0
			m.angle_max = 6.0
			_size(m, 0.75, 0.9, true, true)
			m.color_ramp = _ramp([Color(0.85, 1.5, 0.45, 1.0), Color(0.7, 1.3, 0.38, 1.0), Color(0.4, 0.9, 0.25, 0.0)])
		&"sprout_leaves":
			_shape_disc(m, 0.35)
			m.direction = Vector3.UP
			m.spread = 40.0
			m.initial_velocity_min = 2.0
			m.initial_velocity_max = 3.6
			m.gravity = Vector3(0, -5.0, 0)
			m.damping_min = 1.0
			m.damping_max = 1.5
			m.angle_min = -180.0
			m.angle_max = 180.0
			m.angular_velocity_min = -300.0
			m.angular_velocity_max = 300.0
			_size(m, 0.8, 1.0, false)
			m.color_initial_ramp = _ramp(_lin([Color(0.52, 0.86, 0.30), Color(0.36, 0.70, 0.22), Color(0.70, 0.95, 0.38)]))
			m.color_ramp = _ramp([Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
		&"wither_leaves":
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			m.emission_sphere_radius = 0.6
			m.direction = Vector3.UP
			m.spread = 75.0
			m.initial_velocity_min = 1.2
			m.initial_velocity_max = 2.4
			m.gravity = Vector3(0, -2.2, 0)
			m.damping_min = 0.6
			m.damping_max = 1.0
			m.angle_min = -180.0
			m.angle_max = 180.0
			m.angular_velocity_min = -220.0
			m.angular_velocity_max = 220.0
			m.turbulence_enabled = true
			m.turbulence_noise_strength = 1.5
			m.turbulence_noise_scale = 2.5
			m.turbulence_influence_min = 0.08
			m.turbulence_influence_max = 0.16
			_size(m, 0.8, 1.1, false)
			m.color_initial_ramp = _ramp(_lin([Color(0.58, 0.38, 0.14), Color(0.72, 0.48, 0.16), Color(0.46, 0.30, 0.12),
					Color(0.62, 0.56, 0.22)]))
			m.color_ramp = _ramp([Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
		&"pollen":
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
			m.emission_sphere_radius = 0.2
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 0.4
			m.initial_velocity_max = 1.0
			m.damping_min = 1.0
			m.damping_max = 1.5
			m.angle_min = -180.0
			m.angle_max = 180.0
			_size(m, 0.35, 0.55, true)
			m.color_ramp = _ramp([Color(1.05, 1.0, 0.4, 0.0), Color(1.0, 1.0, 0.35, 1.0), Color(0.6, 0.85, 0.25, 0.0)])
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


func _size(m: ParticleProcessMaterial, lo: float, hi: float, grow: bool, pop: bool = false) -> void:
	m.scale_min = lo
	m.scale_max = hi
	var c := Curve.new()
	if pop:   # pops in at once, then shrinks slowly (the heal +)
		c.add_point(Vector2(0.0, 0.55))
		c.add_point(Vector2(0.12, 1.0))
		c.add_point(Vector2(1.0, 0.4))
	elif grow:
		c.add_point(Vector2(0.0, 0.3))
		c.add_point(Vector2(0.3, 1.0))
		c.add_point(Vector2(1.0, 0.3))
	else:
		c.add_point(Vector2(0.0, 1.0))
		c.add_point(Vector2(1.0, 0.15))
	var ct := CurveTexture.new()
	ct.curve = c
	m.scale_curve = ct


## sRGB -> linear: particle vertex colours are used as linear values (vertex_color_is_srgb off), so earthy
## colours written as they should look on screen go through this.
func _lin(colors: Array) -> Array:
	var out: Array = []
	for c: Color in colors:
		out.append(c.srgb_to_linear())
	return out


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
