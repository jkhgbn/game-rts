class_name SpellVfx
extends Node3D
## Spell effects for Vessa (Fire) and Malrik (Shadow): task 3.U2, polished in task A.13 (LoL-like, readable
## from the RTS camera). Add ONE of these to a level (any parent at the origin); it never edits gameplay code.
## It finds every wizard (groups "heroes" / "enemy_heroes" + wizards added later), connects to its
## "SpellCaster" child (spell_cast / spell_effect / healed) and shows:
##   cast wind-ups   gathering sparks + a flare at the hands / staff head (the model's `_palm` / `_bob` nodes)
##   fireball        boiling fire head + flame / smoke / ember trail on the projectile; on impact a white-hot
##                   core, shockwave ring, flame billows, streak sparks, smoke, a scorch decal with cooling
##                   ember cracks (4 s) and one short light
##   ember_step      flame column where she vanishes, a fire dash streak with embers, a landing burst
##                   (shockwave, sparks, small scorch, short light); the scorched ground (SpellZone) burns
##                   with licking flames and a glowing rim for its whole duration
##   kindle          a fire front racing out to the radius, leaving smouldering ground; flame marks on hasted units
##   shadow_lance    a violet lance streak with a dark umbra trail; on hit it pierces through (flash beam
##                   past the target, exit shards) and a drain tendril feeds Malrik
##   soul_siphon     dark vortex circle (spiral arms, rune rim), spiralling motes, draining tendrils from
##                   every enemy inside to the eye and one thick stream from the eye to Malrik (pulses per tick)
##   umbral_shroud   dark implosion on cast; a veil of dark smoke with a violet rim wrapped around Malrik,
##                   his body at alpha 0.4, a shadow pool at his feet, rising wisps
## Statuses (haste / shroud) are polled with has_status() 4 times per second on wizards and on units Kindle
## just hasted. Budget: every burst, trail, ring, flare, beam, tendril, decal, light, zone dressing and aura is
## pooled (no allocations per cast after warm-up, except one Tween per animated piece); lights: 3 pooled,
## big impacts only; shadows off everywhere. Materials: one per shader, looks set with instance uniforms.
## Fog (2026-10-15, VfxFog): every piece is gated with the caster's team (`_fx_team`, set by each entry point): another
## team's effect plays only where the local player sees it; shots, burning / siphon ground re-check at VfxFog.RECHECK;
## followers and auras hide with their (fog-hidden) unit.

const META := &"spell_vfx"
const FIRE := Color(1.0, 0.55, 0.15)
const FIRE_HOT := Color(1.0, 0.45, 0.1)
const SHADOW := Color(0.7, 0.3, 1.0)
const FIRE_SPELLS: Array[StringName] = [&"fireball", &"ember_step", &"kindle"]
const SHADOW_SPELLS: Array[StringName] = [&"shadow_lance", &"soul_siphon", &"umbral_shroud"]
const POLL_INTERVAL := 0.25
const RESCAN_INTERVAL := 1.0
const MAX_LIGHTS := 3
const LANCE_LEN := 4.2
const COMET_LEN := 2.4
const SIPHON_TENDRILS := 6
const STREAM_RANGE := 26.0
const AURA_CAPS := {&"haste": 40, &"shroud": 4}

## Particle looks: [amount, lifetime, draw (0 = round billboard, 1 = velocity streak, 2 = flame tongue),
## additive, erosion, hot core, explosiveness]. Additive stays <= ~0.35 for fire so overlapping flames keep
## their orange instead of stacking to white. Bursts are one-shot pooled emitters (BURST_POOLS = how many
## of each), the rest are continuous emitters inside pooled sets (trails, zone dressing, auras).
const LOOKS := {
	&"hand_fire": [22, 0.32, 0, 1.0, 0.0, 0.0, 0.8],
	&"hand_shadow": [22, 0.32, 0, 0.6, 0.0, 0.0, 0.8],
	&"impact_sparks": [40, 0.7, 1, 1.0, 0.0, 0.0, 0.95],
	&"impact_flames": [26, 0.85, 0, 0.3, 0.85, 0.3, 0.9],
	&"impact_smoke": [16, 1.8, 0, 0.0, 0.9, 0.0, 0.8],
	&"fire_column": [22, 0.7, 2, 0.3, 0.75, 0.0, 0.8],
	&"land_sparks": [24, 0.55, 1, 1.0, 0.0, 0.0, 0.95],
	&"dash_embers": [12, 0.6, 1, 1.0, 0.0, 0.0, 0.7],
	&"lance_shards": [22, 0.45, 1, 0.75, 0.0, 0.0, 0.95],
	&"shadow_puff": [16, 1.0, 0, 0.0, 0.85, 0.0, 0.85],
	&"shadow_motes": [18, 0.8, 0, 1.0, 0.0, 0.0, 0.9],
	&"implode": [28, 0.42, 0, 0.25, 0.7, 0.0, 0.9],
	&"trail_fire": [60, 0.45, 0, 0.3, 0.75, 0.0, 0.0],
	&"trail_smoke": [20, 0.9, 0, 0.0, 0.9, 0.0, 0.0],
	&"trail_embers": [16, 0.55, 1, 1.0, 0.0, 0.0, 0.0],
	&"trail_lance": [40, 0.3, 0, 0.8, 0.0, 0.4, 0.0],
	&"trail_umbra": [24, 0.55, 0, 0.0, 0.8, 0.0, 0.0],
	&"ground_flames": [44, 0.75, 2, 0.3, 0.75, 0.0, 0.0],
	&"ground_smoke": [8, 1.6, 0, 0.0, 0.9, 0.0, 0.0],
	&"kindle_flames": [96, 0.6, 2, 0.3, 0.75, 0.0, 0.0],
	&"siphon_motes": [36, 1.4, 0, 1.0, 0.0, 0.0, 0.0],
	&"siphon_wisps": [14, 1.6, 0, 0.0, 0.85, 0.0, 0.0],
	&"shroud_smoke": [30, 1.4, 0, 0.0, 0.85, 0.0, 0.0],
	&"shroud_wisps": [14, 1.0, 0, 1.0, 0.0, 0.0, 0.0],
	&"haste_embers": [12, 0.6, 1, 1.0, 0.0, 0.0, 0.0],
}
const BURST_POOLS := {&"hand_fire": 3, &"hand_shadow": 3, &"impact_sparks": 3, &"impact_flames": 3,
		&"impact_smoke": 3, &"fire_column": 4, &"land_sparks": 3, &"dash_embers": 10, &"lance_shards": 3,
		&"shadow_puff": 5, &"shadow_motes": 5, &"implode": 2}
const TRAIL_LOOKS := {&"fire": [&"trail_fire", &"trail_smoke", &"trail_embers"], &"lance": [&"trail_lance", &"trail_umbra"]}
const TRAIL_CAP := 5          # per kind
const FLARE_POOL := 12
const RING_POOL := 10
const BEAM_POOL := 6
const TENDRIL_CAP := 24
const SCORCH_POOL := 6
## Ground decal opacity of the two big area spells (in-game grade 2026-09-30: at 100 % the Kindle and Soul Siphon
## discs hid the keep and every unit standing in them; the spell still reads by its rim / front and particles).
const KINDLE_FADE := 0.6
const SIPHON_FADE := 0.6
const EMBER_SETS := 3
const SIPHON_SETS := 3
const KINDLE_SETS := 2

const PARTICLE_SHADER := preload("res://art/vfx/vfx_particle.gdshader")
const RING_SHADER := preload("res://art/vfx/vfx_ring.gdshader")
const FLARE_SHADER := preload("res://art/vfx/vfx_flare.gdshader")
const BEAM_SHADER := preload("res://art/vfx/vfx_beam.gdshader")
const TENDRIL_SHADER := preload("res://art/vfx/vfx_tendril.gdshader")
const SCORCH_SHADER := preload("res://art/vfx/vfx_scorch.gdshader")
const SIPHON_SHADER := preload("res://art/vfx/vfx_siphon.gdshader")
const FLAME_SHADER := preload("res://art/vfx/vfx_flame.gdshader")
const SHROUD_SHADER := preload("res://art/vfx/vfx_shroud.gdshader")

var _wizards: Array[Node3D] = []
var _tracked: Dictionary = {}       # Node3D unit -> true (statuses polled)
var _active: Dictionary = {}        # unit -> {status: aura root}
var _dying: Dictionary = {}         # aura root -> unit (fading out, still follows)
var _aura_free: Dictionary = {}     # status -> Array[Node3D]
var _aura_live: Dictionary = {}     # status -> int
var _lance_hits: Dictionary = {}    # wizard -> {pos: Vector3, t: float (_clock)}
var _ember_origin: Dictionary = {}  # wizard -> Vector3 (Ember Step start, waiting for the arrival)
var _shots: Array[Dictionary] = []  # tracked projectiles
var _cooling: Array[Dictionary] = []
var _trail_free: Dictionary = {}    # kind -> Array[Node3D]
var _trail_live: Dictionary = {}    # kind -> int
var _bursts: Dictionary = {}
var _burst_next: Dictionary = {}
var _live_bursts: Array[GPUParticles3D] = []
var _flares: Array[MeshInstance3D] = []
var _flare_next := 0
var _follows: Array[Dictionary] = []   # {n: Node3D, target: Node3D, until: int}
var _rings: Array[MeshInstance3D] = []
var _ring_next := 0
var _beams: Array[MeshInstance3D] = []
var _beam_next := 0
var _tendril_free: Array[MeshInstance3D] = []
var _tendril_count := 0
var _scorches: Array[MeshInstance3D] = []
var _scorch_next := 0
var _lights: Array[OmniLight3D] = []
var _light_next := 0
var _ember_free: Array[Node3D] = []
var _embers: Array[Dictionary] = []
var _siphon_free: Array[Node3D] = []
var _siphons: Array[Dictionary] = []
var _kindles: Array[Node3D] = []
var _kindle_next := 0
var _poll_left := 0.0
var _rescan_left := 0.0
var _clock := 0.0                  # game time (seconds), for pooled timers
var _fx_team := -1                 # team of the effect being spawned (VfxFog gate; -1 = unknown)
var _fog_left := 0.0               # countdown to the next fog re-check of long-lived pieces

# Shared resources (built once).
var _pmats: Dictionary = {}
var _particle_mat: ShaderMaterial
var _quad: QuadMesh
var _streak: QuadMesh
var _tongue: QuadMesh
var _plane: PlaneMesh
var _flare_quad: QuadMesh
var _beam_quad: QuadMesh
var _tendril_quad: QuadMesh
var _veil_mesh: CylinderMesh
var _ring_mat: ShaderMaterial
var _flare_mat: ShaderMaterial
var _beam_mat: ShaderMaterial
var _tendril_mat: ShaderMaterial
var _scorch_mat: ShaderMaterial
var _siphon_mat: ShaderMaterial
var _flame_mat: ShaderMaterial
var _veil_mat: ShaderMaterial
var _flame_quad: QuadMesh


func _ready() -> void:
	top_level = true                  # everything is placed in world space
	global_transform = Transform3D.IDENTITY
	_build_shared()
	get_tree().node_added.connect(_on_node_added)
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
	var poll := _poll_left <= 0.0
	if poll:
		_poll_left = POLL_INTERVAL
		_poll_statuses()
	_clock += delta
	var now := _clock
	_fog_left -= delta
	var fog_check := _fog_left <= 0.0
	if fog_check:
		_fog_left = VfxFog.RECHECK
	_update_shots(fog_check)
	_update_cooling(delta)
	_update_follows(now)
	_update_auras()
	_update_embers(delta, fog_check)
	_update_siphons(delta, poll, fog_check)
	for i in range(_live_bursts.size() - 1, -1, -1):
		var p := _live_bursts[i]
		if now > float(p.get_meta(&"until", 0.0)):
			p.visible = false
			_live_bursts.remove_at(i)


# ---------------------------------------------------------------- finding wizards

func _on_node_added(node: Node) -> void:
	if node is Wizard:
		_hook.call_deferred(node)


func _rescan() -> void:
	for group: StringName in [&"heroes", &"enemy_heroes"]:
		for node in get_tree().get_nodes_in_group(group):
			_hook(node)


func _hook(node: Variant) -> void:
	if not is_instance_valid(node) or not node is Node3D:
		return
	var w := node as Node3D
	if _wizards.has(w):
		return
	var caster := w.get_node_or_null(^"SpellCaster")
	if caster == null or not caster.has_signal(&"spell_effect"):
		return   # the next rescan tries again
	_wizards.append(w)
	caster.connect(&"spell_cast", _on_spell_cast.bind(w))
	caster.connect(&"spell_effect", _on_spell_effect.bind(w))
	if caster.has_signal(&"healed"):
		caster.connect(&"healed", _on_healed.bind(w))
	if w.has_signal(&"respawned"):
		w.connect(&"respawned", _on_respawned)
	w.tree_exiting.connect(_forget.bind(w), CONNECT_ONE_SHOT)
	_tracked[w] = true


func _forget(w: Node3D) -> void:
	_wizards.erase(w)
	_tracked.erase(w)
	_lance_hits.erase(w)
	_ember_origin.erase(w)


func _on_respawned(w: Variant) -> void:
	if is_instance_valid(w):
		_set_body_alpha(w as Node3D, 1.0)
		_poll_statuses()


# ---------------------------------------------------------------- spell events

## Wind-up at the hands (the cast itself is instant, the model plays its cast pose at the same time).
func _on_spell_cast(id: StringName, w: Node3D) -> void:
	if not is_instance_valid(w) or not (FIRE_SPELLS.has(id) or SHADOW_SPELLS.has(id)):
		return
	_fx_team = _team(w)
	var fire := FIRE_SPELLS.has(id)
	var staff := _anchor(w, &"_bob")
	var palm := _anchor(w, &"_palm") if fire else null
	var staff_pos := staff.global_position if staff else w.global_position + Vector3.UP * _height(w) * 1.05
	var hand_pos := palm.global_position if palm else staff_pos
	var feet := w.global_position
	match id:
		&"fireball":
			_burst(&"hand_fire", hand_pos, 0.9)
			_flare(hand_pos, 1.3, 0.3, Color(1.9, 0.6, 0.08, 1.0), Color(0, 0, 0, 0), 0.8, palm if palm else staff)
			_flare(staff_pos, 1.6, 0.35, Color(1.9, 0.6, 0.08, 1.0), Color(0, 0, 0, 0), 1.0, staff)
		&"ember_step":
			_flare(staff_pos, 1.8, 0.35, Color(1.9, 0.6, 0.08, 1.0), Color(0, 0, 0, 0), 0.8, staff)
		&"kindle":
			_burst(&"hand_fire", staff_pos, 1.4)
			_flare(staff_pos, 2.6, 0.55, Color(1.9, 0.6, 0.08, 1.0), Color(0, 0, 0, 0), 1.2, staff)
			_ring(feet, 0.4, 2.2, 0.35, Color(2.0, 0.6, 0.1, 1.0), Color(0, 0, 0, 0), 0.12)
		&"shadow_lance":
			_burst(&"hand_shadow", staff_pos, 0.9)
			_flare(staff_pos, 1.5, 0.3, Color(1.4, 0.4, 2.6, 1.0), Color(0.06, 0.0, 0.1, 0.55), 1.0, staff)
		&"soul_siphon":
			_burst(&"hand_shadow", staff_pos, 1.2)
			_flare(staff_pos, 1.8, 0.4, Color(1.3, 0.35, 2.5, 1.0), Color(0.06, 0.0, 0.1, 0.6), 0.8, staff)
			_ring(feet, 0.3, 1.8, 0.35, Color(1.3, 0.35, 2.4, 1.0), Color(0.05, 0.0, 0.1, 0.35), 0.12)
		&"umbral_shroud":
			_flare(staff_pos, 1.4, 0.3, Color(1.2, 0.35, 2.2, 1.0), Color(0.05, 0.0, 0.09, 0.7), 0.5, staff)
	var g := _g()
	if g and (id == &"fireball" or id == &"shadow_lance"):
		g.play(StringName(String(id) + "_cast"), hand_pos, {"team": _team(w)})


func _on_spell_effect(id: StringName, pos: Vector3, w: Node3D) -> void:
	if not is_instance_valid(w):
		return
	_fx_team = _team(w)
	match id:
		&"fireball":
			var r := _radius_of(w, id, 3.5)
			var p := _find_projectile(w)
			if p:
				_track_shot(p, &"fire", w, pos, r)
			else:   # no projectile found: impact after the flight time (Projectile speed 16)
				var from := w.global_position + Vector3.UP * _height(w)
				var tw := create_tween()
				tw.tween_interval(maxf(0.15, from.distance_to(pos) / 16.0))
				tw.tween_callback(_fireball_impact.bind(pos, r, _team(w)))
		&"shadow_lance":
			var p := _find_projectile(w)
			if p:
				_track_shot(p, &"lance", w, pos, 0.0)
		&"ember_step":
			_ember_origin[w] = pos
			_fire_column(pos, 1.0)
			_burst(&"impact_smoke", pos + Vector3.UP * 0.3, 0.6)
			_ring(pos, 1.6, 0.3, 0.25, Color(2.0, 0.6, 0.1, 1.0), Color(0, 0, 0, 0), 0.15, true)
			_dress_ember(pos, w)
			var g := _g()
			if g:
				g.play(&"ember_step_out", pos, {"team": _team(w)})
		&"ember_step_arrive":
			_ember_arrive(pos, w)
		&"kindle":
			_kindle(pos, _radius_of(w, id, 8.0), _team(w))
			_track_hasted(pos, _radius_of(w, id, 8.0))
		&"soul_siphon":
			var r := _radius_of(w, id, 4.0)
			_ring(pos, 0.5, r, 0.35, Color(1.4, 0.4, 2.6, 1.0), Color(0.04, 0.0, 0.08, 0.27), 0.1)
			_burst(&"shadow_puff", pos + Vector3.UP * 0.4, r / 3.0)
			_burst(&"shadow_motes", pos + Vector3.UP * 0.4, r / 3.0)
			_dress_siphon(pos, w)
			var g := _g()
			if g:
				g.play(&"soul_siphon", pos, {"r": r, "team": _team(w)})
		&"umbral_shroud":
			var at := w.global_position
			_ring(at, 2.6, 0.5, 0.32, Color(1.0, 0.25, 1.9, 1.0), Color(0.03, 0.0, 0.06, 0.42), 0.08, true, 0.08)
			_burst(&"implode", at + Vector3.UP * 0.2, 1.0)
			_burst(&"shadow_motes", at + Vector3.UP * 1.0, 0.8)
			var g := _g()
			if g:
				g.play(&"umbral_shroud", at, {"team": _team(w)})
			_tracked[w] = true
			_poll_statuses()


func _on_healed(amount: float, w: Node3D) -> void:
	if amount > 0.0:
		_heal_fx.call_deferred(w)   # after the lance's hit (same frame) records the hit spot


## Malrik is fed: a drain tendril from the lance hit (or a pulse on his siphon stream) + a violet flash.
func _heal_fx(w: Node3D) -> void:
	if not is_instance_valid(w) or not w.is_inside_tree():
		return
	_fx_team = _team(w)
	var chest := w.global_position + Vector3.UP * _height(w) * 0.6
	var hit: Dictionary = _lance_hits.get(w, {})
	if not hit.is_empty() and _clock - float(hit["t"]) < 0.4:
		_lance_hits.erase(w)
		_drain_tendril(hit["pos"], chest)
	else:
		for s in _siphons:
			if s["w"] == w and s["stream"] != null:
				s["pulse"] = 1.0
	_flare(chest, 1.5, 0.25, Color(1.3, 0.35, 2.4, 1.0), Color(0, 0, 0, 0), 0.4, w)


# ---------------------------------------------------------------- projectiles (fireball, lance)

func _track_shot(p: Node3D, kind: StringName, w: Node3D, target: Vector3, radius: float) -> void:
	p.set_meta(META, true)
	for c in p.get_children():
		if c is MeshInstance3D:
			(c as MeshInstance3D).visible = false   # the placeholder sphere: we draw our own head
	var set_root := _take_trail(kind, p.global_position)
	var team := _team(w)
	var s := {"p": p, "kind": kind, "w": w, "set": set_root, "head": null, "tail": null, "start": p.global_position,
			"last": p.global_position, "dir": Vector3.ZERO, "target": target, "radius": radius, "team": team,
			"shown": VfxFog.ok(team, p.global_position)}
	_shots.append(s)
	_give_head(s)
	if set_root:
		set_root.visible = bool(s["shown"])
	var tail := _take_beam()
	if kind == &"fire":   # comet tail
		_beam_params(tail, Color(1.8, 0.45, 0.05, 1.0), Color(0.4, 0.04, 0.0, 0.45), 0.9, 1.0, 0.55)
	else:                 # the lance itself: a long violet spear with a dark umbra
		_beam_params(tail, Color(1.3, 0.5, 2.2, 1.0), Color(0.16, 0.03, 0.3, 0.85), 0.8, 0.9, 0.3)
	tail.visible = false
	s["tail"] = tail
	if kind == &"lance" and p.has_signal(&"hit_unit"):
		p.connect(&"hit_unit", _on_lance_hit_unit.bind(s), CONNECT_ONE_SHOT)
	var g := _g()
	if g:
		g.play(&"fireball_fly" if kind == &"fire" else &"lance_fly", p.global_position, {"node": p, "team": _team(w)})


## The bright head of a tracked shot (a pooled flare): a boiling fireball, or the lance's violet tip.
func _give_head(s: Dictionary) -> void:
	var f := _take_flare()
	if s["kind"] == &"fire":
		_flare_params(f, Color(1.9, 0.55, 0.07, 1.0), Color(0.35, 0.04, 0.0, 0.4), 0.0, 1.0)
	else:
		_flare_params(f, Color(1.4, 0.4, 2.6, 1.0), Color(0.06, 0.0, 0.1, 0.5), 0.6, 0.0)
	f.global_position = s["last"]
	f.scale = Vector3.ONE * (1.5 if s["kind"] == &"fire" else 0.9)
	f.visible = bool(s.get("shown", true))
	s["head"] = f


func _update_shots(fog_check: bool) -> void:
	for i in range(_shots.size() - 1, -1, -1):
		var s: Dictionary = _shots[i]
		var p: Variant = s["p"]
		var live := is_instance_valid(p) and (p as Node).is_inside_tree() and (p as Node).is_processing()
		var fire: bool = s["kind"] == &"fire"
		if live:
			var pos := (p as Node3D).global_position
			var last: Vector3 = s["last"]
			if pos.distance_squared_to(last) > 0.0001:
				s["dir"] = (pos - last).normalized()
			s["last"] = pos
			var shown: bool = s["shown"]
			if fog_check:   # an enemy shot flying through fog the local player does not see draws nothing
				shown = VfxFog.ok(int(s["team"]), pos)
				s["shown"] = shown
			if s["set"]:
				(s["set"] as Node3D).global_position = pos
				(s["set"] as Node3D).visible = shown
			if s["head"] == null:
				_give_head(s)   # its flare was taken by the ring buffer
			var head: MeshInstance3D = s["head"]
			head.global_position = pos
			head.visible = shown
			if fire:
				head.scale = Vector3.ONE * (1.5 + 0.12 * sin(_clock * 30.0))
			var tail: Variant = s["tail"]
			var dir: Vector3 = s["dir"]
			if tail != null and dir != Vector3.ZERO:
				var start: Vector3 = s["start"]
				var back := minf(COMET_LEN if fire else LANCE_LEN, start.distance_to(pos))
				_place_beam(tail as MeshInstance3D, pos - dir * back, pos + dir * (0.25 if fire else 0.45))
				(tail as MeshInstance3D).visible = back > 0.3 and shown
			continue
		# Landed (or freed).
		_shots.remove_at(i)
		_finish_shot(s)


## The lance hit its target: show the pierce now, in the same frame as the heal (so the drain tendril finds it).
func _on_lance_hit_unit(_target: Node3D, _dealt: float, s: Dictionary) -> void:
	var i := _shots.find(s)
	if i < 0:
		return
	_shots.remove_at(i)
	_finish_shot(s)


func _finish_shot(s: Dictionary) -> void:
	var p: Variant = s["p"]
	var at: Vector3 = s["last"]
	if is_instance_valid(p):
		(p as Node3D).visible = false   # hides the placeholder blast sphere / light
		at = (p as Node3D).global_position
	if s["head"] != null:
		(s["head"] as MeshInstance3D).visible = false
	if s["tail"] != null:
		(s["tail"] as MeshInstance3D).visible = false
	if s["set"]:
		_release_trail(s["kind"], s["set"])
	if s["kind"] == &"fire":
		_fireball_impact(at, float(s["radius"]), _team(s["w"]))
	else:
		_lance_hit(at, s["dir"], s["w"])


func _fireball_impact(pos: Vector3, radius: float, team: int = -1) -> void:
	_fx_team = team
	var k := radius / 3.5
	var ground := Vector3(pos.x, pos.y, pos.z)
	_flare(ground + Vector3.UP * 0.9, radius * 0.85, 0.22, Color(1.9, 0.6, 0.08, 1.0), Color(0, 0, 0, 0), 0.8)
	_ring(ground, 0.4, radius * 1.3, 0.3, Color(2.0, 0.6, 0.1, 1.0), Color(0, 0, 0, 0), 0.08, false, 0.25)
	_ring(ground, 0.3, radius * 0.9, 0.5, Color(1.3, 0.4, 0.08, 0.6), Color(0.1, 0.04, 0.02, 0.35), 0.3, false, 0.6)
	_burst(&"impact_flames", ground + Vector3.UP * 0.4, k)
	_burst(&"impact_sparks", ground + Vector3.UP * 0.3, k)
	_burst(&"impact_smoke", ground + Vector3.UP * 0.6, k)
	_scorch(ground, radius * 0.95, 2.4, 4.2)
	_light_flash(ground + Vector3.UP * 1.6, FIRE_HOT, 3.5, radius * 1.5, 0.4)   # was 6.0 / radius x 3 (a 21 m lit disc)
	var g := _g()
	if g:
		g.play(&"fireball_impact", ground, {"r": radius, "team": team})


func _lance_hit(pos: Vector3, dir: Vector3, w: Variant) -> void:
	_fx_team = _team(w)
	if dir == Vector3.ZERO:
		dir = Vector3.FORWARD
	# The lance pierces: a flash beam through the target and shards bursting out the far side.
	_beam_flash(pos - dir * 3.0, pos + dir * 3.6, 1.1, 0.1, 0.4, Color(1.4, 0.55, 2.3, 1.0),
			Color(0.16, 0.03, 0.3, 0.85), 0.35)
	_burst(&"lance_shards", pos + dir * 0.3, 1.2, dir)
	_burst(&"shadow_puff", pos, 0.7)
	_flare(pos, 2.0, 0.28, Color(1.4, 0.4, 2.6, 1.0), Color(0.05, 0.0, 0.1, 0.65), 1.2)
	_ring(Vector3(pos.x, pos.y - 1.0, pos.z), 0.2, 1.5, 0.3, Color(1.3, 0.38, 2.5, 1.0), Color(0.04, 0.0, 0.08, 0.4), 0.14)
	if is_instance_valid(w):
		_lance_hits[w] = {"pos": pos, "t": _clock}
	var g := _g()
	if g:
		g.play(&"lance_hit", pos, {"dir": dir, "team": _team(w)})


# ---------------------------------------------------------------- Ember Step

func _ember_arrive(dest: Vector3, w: Node3D) -> void:
	_fx_team = _team(w)
	var from: Variant = _ember_origin.get(w)
	_ember_origin.erase(w)
	if from is Vector3:
		var a: Vector3 = from
		var d := dest - a
		d.y = 0.0
		if d.length() > 0.3:
			_beam_flash(a + Vector3.UP * 0.9, dest + Vector3.UP * 0.9, 1.5, 0.3, 0.45, Color(1.8, 0.45, 0.05, 1.0),
					Color(0.35, 0.06, 0.01, 0.35), 0.9)
			var n := clampi(int(d.length() / 2.0), 2, 6)
			for i in n:
				var t := (float(i) + 0.5) / float(n)
				_burst(&"dash_embers", a.lerp(dest, t) + Vector3.UP * 0.7, 1.0)
	_flare(dest + Vector3.UP * 1.0, 2.2, 0.3, Color(1.9, 0.6, 0.08, 1.0), Color(0, 0, 0, 0), 1.0)
	_ring(dest, 0.4, 3.2, 0.35, Color(1.9, 0.6, 0.08, 1.0), Color(0, 0, 0, 0), 0.1, false, 0.3)
	_fire_column(dest, 0.9)
	_burst(&"land_sparks", dest + Vector3.UP * 0.2, 1.0)
	_scorch(dest, 1.7, 1.0, 2.2, 0.55)
	_light_flash(dest + Vector3.UP * 1.3, FIRE, 3.0, 4.5, 0.35)   # was 4.5 / 8 m
	var g := _g()
	if g:
		g.play(&"ember_step_in", dest, {"team": _team(w)})
	var tw := create_tween()
	tw.tween_method(_fade_in_body.bind(w), 0.0, 1.0, 0.15)


func _fire_column(pos: Vector3, size: float) -> void:
	_burst(&"fire_column", pos + Vector3.UP * 0.1, size)


## Burning ground on Ember Step's SpellZone: hides the zone's placeholder disc, burns for its duration.
func _dress_ember(pos: Vector3, w: Node3D) -> void:
	var zone := _find_zone(&"ember_step", pos)
	if zone == null or _ember_free.is_empty():
		return
	zone.set_meta(META, true)
	_hide_zone_disc(zone)
	var r := float(zone.get(&"radius")) if zone.get(&"radius") != null else 2.5
	var dur := float(zone.get(&"duration")) if zone.get(&"duration") != null else 4.0
	var root: Node3D = _ember_free.pop_back()
	root.visible = true
	root.global_position = zone.global_position
	var disc: MeshInstance3D = root.get_child(0)
	disc.scale = Vector3(r, 1.0, r)
	disc.rotation.y = randf() * TAU
	_sp(disc, {&"burn": 0.8, &"heat": 0.9, &"flames": 0.45, &"rim": 1.0, &"front": -1.0, &"fade": 0.0, &"seed": randf() * 10.0})
	for i in [1, 2]:
		var e: GPUParticles3D = root.get_child(i)
		var pm := e.process_material as ParticleProcessMaterial
		pm.emission_ring_radius = r * (0.85 if i == 1 else 0.6)
		e.visible = true
		e.emitting = true
		e.restart()
	var team := _team(w)
	root.visible = VfxFog.ok(team, root.global_position)
	_embers.append({"root": root, "zone": zone, "dur": dur, "t": 0.0, "team": team})


func _update_embers(delta: float, fog_check: bool) -> void:
	for i in range(_embers.size() - 1, -1, -1):
		var s: Dictionary = _embers[i]
		s["t"] = float(s["t"]) + delta
		var t: float = s["t"]
		var dur: float = s["dur"]
		var root: Node3D = s["root"]
		var disc: MeshInstance3D = root.get_child(0)
		var zone: Variant = s["zone"]
		if is_instance_valid(zone):
			root.global_position = (zone as Node3D).global_position
		if fog_check and t <= dur + 0.9:
			root.visible = VfxFog.ok(int(s["team"]), root.global_position)
		var f := clampf(t / 0.2, 0.0, 1.0) * clampf((dur - t) / 0.9, 0.0, 1.0)
		disc.set_instance_shader_parameter(&"fade", f)
		disc.set_instance_shader_parameter(&"heat", 0.9 * clampf((dur - t) / 1.5, 0.3, 1.0))
		if t > dur - 0.8:
			for c in [1, 2]:
				(root.get_child(c) as GPUParticles3D).emitting = false
		if t > dur + 0.9:
			root.visible = false
			for c in [1, 2]:
				(root.get_child(c) as GPUParticles3D).visible = false
			_ember_free.append(root)
			_embers.remove_at(i)


# ---------------------------------------------------------------- Kindle

func _kindle(pos: Vector3, r: float, team: int = -1) -> void:
	_fx_team = team
	if not VfxFog.ok(team, pos):   # the G layer checks its own pieces
		var g0 := _g()
		if g0:
			g0.play(&"kindle", pos, {"r": r, "team": team})
		return
	var root := _kindles[_kindle_next]
	_kindle_next = (_kindle_next + 1) % _kindles.size()
	var disc: MeshInstance3D = root.get_child(0)
	var flames: GPUParticles3D = root.get_child(1)
	root.visible = true
	root.global_position = pos
	disc.scale = Vector3(r, 1.0, r)
	disc.rotation.y = randf() * TAU
	# In-game grade 2026-09-30: the decal is exactly the AoE (radius 8 / 10 m) and covered the keep and every unit
	# in it: ~60 % opacity (KINDLE_FADE), a lighter soot and shorter flame tongues; the travelling front still reads.
	_sp(disc, {&"burn": 0.16, &"heat": 0.24, &"flames": 0.18, &"rim": 0.0, &"front": 0.0, &"fade": KINDLE_FADE, &"seed": randf() * 10.0})
	flames.visible = true
	flames.emitting = true
	flames.restart()
	_kindle_front(0.05, root, r)
	var tw := _tw(root)
	tw.tween_method(_kindle_front.bind(root, r), 0.05, 1.04, 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func() -> void: flames.emitting = false)
	tw.tween_method(_ip.bind(disc, &"heat"), 0.24, 0.0, 1.3)
	tw.parallel().tween_method(_ip.bind(disc, &"flames"), 0.18, 0.0, 0.8)
	tw.parallel().tween_method(_ip.bind(disc, &"fade"), KINDLE_FADE, 0.0, 1.3).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		root.visible = false
		flames.visible = false)
	_fire_column(pos, 1.3)
	_burst(&"land_sparks", pos + Vector3.UP * 0.3, 1.3)
	# The flash lights only the heart of the zone: at energy 2.2 / reach r + 2 it painted a 12 m yellow disc over the
	# keep and every unit (in-game grade 2026-09-30).
	_light_flash(pos + Vector3.UP * 1.5, FIRE, 0.9, r * 0.5, 0.45)
	var g := _g()
	if g:
		g.play(&"kindle", pos, {"r": r, "team": team})


func _kindle_front(v: float, root: Node3D, r: float) -> void:
	var disc: MeshInstance3D = root.get_child(0)
	disc.set_instance_shader_parameter(&"front", v)
	var pm := (root.get_child(1) as GPUParticles3D).process_material as ParticleProcessMaterial
	pm.emission_ring_radius = maxf(0.1, v * r * 0.97)
	pm.emission_ring_inner_radius = maxf(0.0, v * r * 0.85)


# ---------------------------------------------------------------- Soul Siphon

func _dress_siphon(pos: Vector3, w: Node3D) -> void:
	var zone := _find_zone(&"soul_siphon", pos)
	if zone == null or _siphon_free.is_empty():
		return
	zone.set_meta(META, true)
	_hide_zone_disc(zone)
	var r := float(zone.get(&"radius")) if zone.get(&"radius") != null else 4.0
	var dur := float(zone.get(&"duration")) if zone.get(&"duration") != null else 5.0
	var root: Node3D = _siphon_free.pop_back()
	root.visible = true
	root.global_position = zone.global_position
	var disc: MeshInstance3D = root.get_child(0)
	disc.scale = Vector3(r, 1.0, r)
	_sp(disc, {&"fade": 0.0, &"seed": randf() * 10.0, &"pulse": 0.0})
	for i in [1, 2]:
		var e: GPUParticles3D = root.get_child(i)
		var pm := e.process_material as ParticleProcessMaterial
		pm.emission_ring_radius = r * (0.95 if i == 1 else 0.7)
		pm.emission_ring_inner_radius = r * (0.75 if i == 1 else 0.0)
		e.visible = true
		e.emitting = true
		e.restart()
	var fx_team := _team(w)
	var shown := VfxFog.ok(fx_team, root.global_position)
	root.visible = shown
	_siphons.append({"root": root, "zone": zone, "w": w, "r": r, "dur": dur, "t": 0.0, "team": zone.get(&"team"),
			"victims": {}, "stream": null, "pulse": 0.0, "fx_team": fx_team, "shown": shown})


func _update_siphons(delta: float, poll: bool, fog_check: bool) -> void:
	for i in range(_siphons.size() - 1, -1, -1):
		var s: Dictionary = _siphons[i]
		s["t"] = float(s["t"]) + delta
		var t: float = s["t"]
		var dur: float = s["dur"]
		var root: Node3D = s["root"]
		var disc: MeshInstance3D = root.get_child(0)
		var center := root.global_position
		var shown: bool = s["shown"]
		if fog_check and t <= dur + 0.9:
			shown = VfxFog.ok(int(s["fx_team"]), center)
			s["shown"] = shown
			root.visible = shown
		var f := clampf(t / 0.3, 0.0, 1.0) * clampf((dur - t) / 0.8, 0.0, 1.0)
		s["pulse"] = maxf(0.0, float(s["pulse"]) - delta * 2.5)
		disc.set_instance_shader_parameter(&"fade", f * SIPHON_FADE)
		disc.set_instance_shader_parameter(&"pulse", s["pulse"])
		var victims: Dictionary = s["victims"]
		var ending := t > dur - 0.5
		if poll and not ending:
			_siphon_victims(s)
		# Victim tendrils: unit chest -> the eye.
		var eye := center + Vector3.UP * 0.35
		for u: Variant in victims.keys():
			var td: MeshInstance3D = victims[u]
			if ending or not is_instance_valid(u) or not (u as Node).is_inside_tree():
				victims.erase(u)
				_release_tendril(td, 0.2)
				continue
			var chest := (u as Node3D).global_position + Vector3.UP * _height(u as Node3D) * 0.6
			_place_tendril(td, chest, (chest + eye) * 0.5 + Vector3.UP * 1.1, eye)
			td.visible = shown
		# The stream: the eye -> Malrik, while he is alive and not too far.
		var w: Variant = s["w"]
		var want := not ending and is_instance_valid(w) and (w as Node3D).is_visible_in_tree() \
				and (w as Node3D).global_position.distance_to(center) < STREAM_RANGE \
				and (not (w as Object).has_method(&"is_alive") or bool((w as Object).call(&"is_alive")))
		var stream: Variant = s["stream"]
		if want and stream == null and t > 0.15:
			stream = _take_tendril()
			if stream:
				_sp(stream as MeshInstance3D, {&"width": 0.8, &"core": Color(1.0, 0.28, 1.8, 1.0),
						&"body_color": Color(0.2, 0.04, 0.36, 0.9), &"grow": 0.0, &"fade": 1.0, &"seed": randf(), &"pulse": 0.0})
				var tw := _tw(stream as Node)
				tw.tween_method(_ip.bind(stream, &"grow"), 0.0, 1.0, 0.3).set_ease(Tween.EASE_OUT)
				s["stream"] = stream
		elif not want and stream != null:
			_release_tendril(stream as MeshInstance3D, 0.3)
			s["stream"] = null
			stream = null
		if stream != null:
			var chest := (w as Node3D).global_position + Vector3.UP * _height(w as Node3D) * 0.6
			var mid := (eye + chest) * 0.5 + Vector3.UP * (1.6 + eye.distance_to(chest) * 0.12)
			_place_tendril(stream as MeshInstance3D, eye, mid, chest)
			(stream as MeshInstance3D).set_instance_shader_parameter(&"pulse", s["pulse"])
			(stream as MeshInstance3D).visible = shown
		if ending:
			for c in [1, 2]:
				(root.get_child(c) as GPUParticles3D).emitting = false
		if t > dur + 0.9:
			root.visible = false
			for c in [1, 2]:
				(root.get_child(c) as GPUParticles3D).visible = false
			_siphon_free.append(root)
			_siphons.remove_at(i)


func _siphon_victims(s: Dictionary) -> void:
	var victims: Dictionary = s["victims"]
	var center: Vector3 = (s["root"] as Node3D).global_position
	var r: float = s["r"]
	var team: Variant = s["team"]
	var inside: Dictionary = {}
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Node3D
		if u == null or u.get(&"team") == team or not u.is_visible_in_tree():
			continue
		if u.has_method(&"is_alive") and not bool(u.call(&"is_alive")):
			continue
		var d := Vector2(u.global_position.x - center.x, u.global_position.z - center.z).length()
		if d <= r + _radius(u):
			inside[u] = true
	for u: Variant in victims.keys():
		if not inside.has(u):
			_release_tendril(victims[u], 0.2)
			victims.erase(u)
	for u: Variant in inside:
		if victims.has(u) or victims.size() >= SIPHON_TENDRILS:
			continue
		var td := _take_tendril()
		if td == null:
			break
		_sp(td, {&"width": 0.5, &"core": Color(1.0, 0.28, 1.8, 1.0), &"body_color": Color(0.22, 0.05, 0.4, 0.9),
				&"grow": 0.0, &"fade": 1.0, &"seed": randf(), &"pulse": 0.0})
		var tw := _tw(td)
		tw.tween_method(_ip.bind(td, &"grow"), 0.0, 1.0, 0.25).set_ease(Tween.EASE_OUT)
		victims[u] = td


func _drain_tendril(from: Vector3, to: Vector3) -> void:
	if not (VfxFog.ok(_fx_team, from) and VfxFog.ok(_fx_team, to)):
		return
	var td := _take_tendril()
	if td == null:
		return
	_sp(td, {&"width": 0.6, &"core": Color(1.1, 0.32, 2.0, 1.0), &"body_color": Color(0.2, 0.04, 0.36, 0.9),
			&"grow": 0.0, &"fade": 1.0, &"seed": randf(), &"pulse": 1.0})
	_place_tendril(td, from, (from + to) * 0.5 + Vector3.UP * 1.4, to)
	var tw := _tw(td)
	tw.tween_method(_ip.bind(td, &"grow"), 0.0, 1.0, 0.14).set_ease(Tween.EASE_OUT)
	tw.tween_method(_ip.bind(td, &"fade"), 1.0, 0.0, 0.4).set_ease(Tween.EASE_IN)
	tw.tween_callback(_release_tendril.bind(td, 0.0))


# ---------------------------------------------------------------- statuses (haste, shroud)

func _track_hasted(center: Vector3, r: float) -> void:
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Node3D
		if u == null or _tracked.has(u) or not u.has_method(&"has_status"):
			continue
		if Vector2(u.global_position.x - center.x, u.global_position.z - center.z).length() > r + 1.0:
			continue
		if bool(u.call(&"has_status", &"haste")):
			_tracked[u] = true
	_poll_statuses()


func _poll_statuses() -> void:
	for u: Variant in _tracked.keys():
		if not is_instance_valid(u):
			_tracked.erase(u)
			continue
		var unit := u as Node3D
		var shown := VfxFog.node_ok(unit)   # in the tree, not hidden by the fog, its point seen
		var auras: Dictionary = _active.get(unit, {})
		for status: StringName in [&"haste", &"shroud"]:
			var on := shown and unit.has_method(&"has_status") and bool(unit.call(&"has_status", status))
			if on != auras.has(status):
				_ensure(unit, status, on)
				auras = _active.get(unit, {})
		if auras.is_empty() and not _wizards.has(unit):
			_tracked.erase(unit)


func _ensure(u: Node3D, kind: StringName, on: bool) -> void:
	var auras: Dictionary = _active.get(u, {})
	if on == auras.has(kind):
		return
	if on:
		var root := _take_aura(kind)
		if root == null:
			return
		_fit_aura(root, kind, u)
		root.position = u.global_position
		auras[kind] = root
		_active[u] = auras
		_fade_aura(root, kind, true)
		if kind == &"shroud":
			_set_body_alpha(u, 0.4)
	else:
		var root: Node3D = auras[kind]
		auras.erase(kind)
		if auras.is_empty():
			_active.erase(u)
		if kind == &"shroud":
			_set_body_alpha(u, 1.0)
			_fx_team = _team(u)
			_burst(&"shadow_puff", u.global_position + Vector3.UP * 1.0, 0.8)
		_dying[root] = u
		_fade_aura(root, kind, false)


func _update_auras() -> void:
	for u: Variant in _active.keys():
		var auras: Dictionary = _active[u]
		if not is_instance_valid(u) or not (u as Node).is_inside_tree():
			for k: StringName in auras.keys():
				_release_aura(k, auras[k])
			_active.erase(u)
			continue
		if not (u as Node3D).is_visible_in_tree():   # the fog hid the unit: its auras go at once (the poll re-adds)
			for k: StringName in auras.keys():
				_release_aura(k, auras[k])
			_active.erase(u)
			if auras.has(&"shroud"):
				_set_body_alpha(u as Node3D, 1.0)
			continue
		var at := (u as Node3D).global_position
		for k: StringName in auras:
			(auras[k] as Node3D).position = at
	for root: Variant in _dying.keys():
		var u: Variant = _dying[root]
		if is_instance_valid(u) and (u as Node).is_inside_tree():
			if not (u as Node3D).is_visible_in_tree():
				_release_aura(StringName((root as Node).get_meta(&"kind", &"haste")), root as Node3D)
				continue
			(root as Node3D).position = (u as Node3D).global_position


func _fade_aura(root: Node3D, kind: StringName, show: bool) -> void:
	var fx: Array = root.get_meta(&"fx", [])
	for p: GPUParticles3D in root.get_meta(&"parts", []):
		p.emitting = show
		if show:
			p.visible = true
			p.restart()
	var tw := _tw(root)
	tw.set_parallel(true)
	for g: GeometryInstance3D in fx:
		tw.tween_method(_ip.bind(g, &"fade"), 0.0 if show else 1.0, 1.0 if show else 0.0, 0.25 if show else 0.35)
	if kind == &"haste":
		var flame: Node3D = fx[0]
		var s: Vector3 = root.get_meta(&"flame_scale", Vector3.ONE)
		if show:
			flame.scale = s * 0.2
			tw.tween_property(flame, "scale", s, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if not show:
		tw.chain().tween_interval(0.5)   # let the smoke / embers die out
		tw.chain().tween_callback(_release_aura.bind(kind, root))


func _release_aura(kind: StringName, root: Node3D) -> void:
	if not is_instance_valid(root) or not root.visible:
		return
	var old: Variant = root.get_meta(&"tw") if root.has_meta(&"tw") else null
	if old is Tween and (old as Tween).is_valid():
		(old as Tween).kill()
	_dying.erase(root)
	root.visible = false
	for p: GPUParticles3D in root.get_meta(&"parts", []):
		p.emitting = false
		p.visible = false
	(_aura_free[kind] as Array).append(root)
	_aura_live[kind] = int(_aura_live[kind]) - 1


func _take_aura(kind: StringName) -> Node3D:
	var free: Array = _aura_free[kind]
	var root: Node3D
	if not free.is_empty():
		root = free.pop_back()
	elif int(_aura_live[kind]) < int(AURA_CAPS[kind]):
		root = _build_aura(kind)
	else:
		return null
	_aura_live[kind] = int(_aura_live[kind]) + 1
	root.visible = true
	return root


func _fit_aura(root: Node3D, kind: StringName, u: Node3D) -> void:
	var h := _height(u)
	var r := maxf(_radius(u), 0.45)
	var fx: Array = root.get_meta(&"fx", [])
	if kind == &"haste":
		var flame: MeshInstance3D = fx[0]
		flame.position.y = h + 0.5
		root.set_meta(&"flame_scale", Vector3(0.7, 1.0, 0.7))
		flame.set_instance_shader_parameter(&"seed", randf() * 10.0)
		var ring: MeshInstance3D = fx[1]
		ring.scale = Vector3(r * 1.7, 1.0, r * 1.7)
		ring.set_instance_shader_parameter(&"seed", randf() * 10.0)
		var feet: GPUParticles3D = (root.get_meta(&"parts") as Array)[0]
		feet.scale = Vector3.ONE * clampf(r / 0.45, 0.8, 2.0)
	else:
		var veil: MeshInstance3D = fx[0]
		veil.scale = Vector3(r * 2.4, h * 1.25, r * 2.4)
		veil.position.y = h * 1.25 * 0.5 - 0.05
		veil.set_instance_shader_parameter(&"seed", randf() * 10.0)
		var pool: MeshInstance3D = fx[1]
		pool.scale = Vector3(r * 2.6, 1.0, r * 2.6)


func _build_aura(kind: StringName) -> Node3D:
	var root := Node3D.new()
	root.name = "Aura_" + String(kind)
	root.set_meta(&"kind", kind)
	add_child(root)
	var fx: Array[GeometryInstance3D] = []
	var parts: Array[GPUParticles3D] = []
	if kind == &"haste":
		var flame := _mesh(_flame_quad, _flame_mat)
		root.add_child(flame)
		fx.append(flame)
		var ring := _mesh(_plane, _ring_mat)   # a thin fire ring at the feet: "this unit is hasted" from far away
		ring.position.y = 0.06
		ring.set_instance_shader_parameter(&"tint", Color(1.8, 0.5, 0.08, 1.0))
		ring.set_instance_shader_parameter(&"fill", Color(0.35, 0.06, 0.0, 0.12))
		ring.set_instance_shader_parameter(&"width", 0.16)
		ring.set_instance_shader_parameter(&"glow", 0.3)
		root.add_child(ring)
		fx.append(ring)
		var feet := _emitter(&"haste_embers", false)
		root.add_child(feet)
		feet.position.y = 0.1
		parts.append(feet)
	else:
		var veil := _mesh(_veil_mesh, _veil_mat)
		root.add_child(veil)
		fx.append(veil)
		var pool := _mesh(_plane, _ring_mat)
		pool.position.y = 0.05
		pool.set_instance_shader_parameter(&"tint", Color(1.1, 0.3, 2.0, 0.8))
		pool.set_instance_shader_parameter(&"fill", Color(0.04, 0.0, 0.08, 0.6))
		pool.set_instance_shader_parameter(&"width", 0.06)
		pool.set_instance_shader_parameter(&"glow", 0.2)
		root.add_child(pool)
		fx.append(pool)
		for look: StringName in [&"shroud_smoke", &"shroud_wisps"]:
			var e := _emitter(look, false)
			root.add_child(e)
			parts.append(e)
	root.set_meta(&"fx", fx)
	root.set_meta(&"parts", parts)
	return root


func _fade_in_body(a: float, w: Node3D) -> void:
	if not is_instance_valid(w):
		return
	var shrouded := w.has_method(&"has_status") and bool(w.call(&"has_status", &"shroud"))
	_set_body_alpha(w, a * (0.4 if shrouded else 1.0))


## Body alpha of a unit: its visual is the plain Node3D child that Unit builds (never the HP bar, the
## selection ring or our own effects).
func _set_body_alpha(u: Node3D, alpha: float) -> void:
	for c in u.get_children():
		if c.get_class() == "Node3D" and not c.has_meta(META):
			_set_transparency(c, clampf(1.0 - alpha, 0.0, 1.0))


func _set_transparency(n: Node, t: float) -> void:
	for c in n.get_children():
		if c is GeometryInstance3D:
			(c as GeometryInstance3D).transparency = t
		_set_transparency(c, t)


# ---------------------------------------------------------------- pooled building blocks

func _burst(look: StringName, pos: Vector3, size: float = 1.0, dir: Vector3 = Vector3.ZERO) -> void:
	if not VfxFog.ok(_fx_team, pos):
		return
	var pool: Array = _bursts[look]
	var i: int = _burst_next[look]
	_burst_next[look] = (i + 1) % pool.size()
	var p: GPUParticles3D = pool[i]
	var b := Basis.IDENTITY
	if dir.length() > 0.01:
		var d := dir.normalized()
		b = Basis.looking_at(d, Vector3.UP if absf(d.y) < 0.95 else Vector3.FORWARD)
	p.global_transform = Transform3D(b * Basis.from_scale(Vector3.ONE * clampf(size, 0.4, 3.0)), pos)
	p.visible = true
	p.restart()
	p.set_meta(&"until", _clock + p.lifetime + 0.15)
	if not _live_bursts.has(p):
		_live_bursts.append(p)


func _take_trail(kind: StringName, at: Vector3) -> Node3D:
	var free: Array = _trail_free[kind]
	var root: Node3D
	if not free.is_empty():
		root = free.pop_back()
	elif int(_trail_live[kind]) < TRAIL_CAP:
		root = Node3D.new()
		root.name = "Trail_" + String(kind)
		add_child(root)
		for look: StringName in TRAIL_LOOKS[kind]:
			root.add_child(_emitter(look, false))
	else:
		return null
	_trail_live[kind] = int(_trail_live[kind]) + 1
	root.global_position = at   # before restart, or the first particles spawn where it was left
	root.visible = true
	for c in root.get_children():
		var e := c as GPUParticles3D
		e.visible = true
		e.emitting = true
		e.restart()
	return root


func _release_trail(kind: StringName, root: Node3D) -> void:
	for c in root.get_children():
		(c as GPUParticles3D).emitting = false
	_cooling.append({"root": root, "kind": kind, "t": 1.0})


func _update_cooling(delta: float) -> void:
	for i in range(_cooling.size() - 1, -1, -1):
		var c: Dictionary = _cooling[i]
		c["t"] = float(c["t"]) - delta
		if float(c["t"]) <= 0.0:
			var root: Node3D = c["root"]
			root.visible = false
			(_trail_free[c["kind"]] as Array).append(root)
			_trail_live[c["kind"]] = int(_trail_live[c["kind"]]) - 1
			_cooling.remove_at(i)


## Next flare of the ring buffer, skipping the ones used as live projectile heads (if all are, one is taken
## and its shot gets a fresh head next frame).
func _take_flare() -> MeshInstance3D:
	var f := _flares[_flare_next]
	for k in _flares.size():
		f = _flares[_flare_next]
		_flare_next = (_flare_next + 1) % _flares.size()
		if not _is_shot_part(f):
			break
	var old: Variant = f.get_meta(&"tw") if f.has_meta(&"tw") else null
	if old is Tween and (old as Tween).is_valid():
		(old as Tween).kill()
	for i in range(_follows.size() - 1, -1, -1):
		if _follows[i]["n"] == f:
			_follows.remove_at(i)
	for s in _shots:
		if s["head"] == f:
			s["head"] = null
	return f


func _is_shot_part(n: Node) -> bool:
	for s in _shots:
		if s["head"] == n or s["tail"] == n:
			return true
	return false


func _flare_params(f: MeshInstance3D, tint: Color, halo: Color, rays: float, turb: float) -> void:
	_sp(f, {&"tint": tint, &"halo": halo, &"rays": rays, &"turb": turb, &"fade": 1.0, &"seed": randf() * 10.0})


## A camera-facing flash: pops to `size` metres, fades out over `time`; follows `follow` if given.
func _flare(pos: Vector3, size: float, time: float, tint: Color, halo: Color = Color(0, 0, 0, 0), rays: float = 0.0,
		follow: Node3D = null) -> void:
	if not VfxFog.ok(_fx_team, pos) or (follow != null and is_instance_valid(follow) and not follow.is_visible_in_tree()):
		return
	var f := _take_flare()
	_flare_params(f, tint, halo, rays, 0.0)
	f.global_position = pos
	f.scale = Vector3.ONE * size * 0.45
	f.visible = true
	var tw := _tw(f)
	tw.set_parallel(true)
	tw.tween_property(f, "scale", Vector3.ONE * size, time * 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_method(_ip.bind(f, &"fade"), 1.0, 0.0, time).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func() -> void: f.visible = false)
	if follow and is_instance_valid(follow):
		_follows.append({"n": f, "target": follow, "until": _clock + time})


func _update_follows(now: float) -> void:
	for i in range(_follows.size() - 1, -1, -1):
		var d: Dictionary = _follows[i]
		var t: Variant = d["target"]
		if now > float(d["until"]) or not is_instance_valid(t) or not (t as Node).is_inside_tree():
			_follows.remove_at(i)
			continue
		if not (t as Node3D).is_visible_in_tree():   # the fog hid the unit it rides on
			(d["n"] as Node3D).visible = false
			_follows.remove_at(i)
			continue
		(d["n"] as Node3D).global_position = (t as Node3D).global_position


## Ground ring: scales r0 -> r1 in `time` (ease out; ease in for an implosion) while fading.
func _ring(pos: Vector3, r0: float, r1: float, time: float, tint: Color, fill: Color, width: float,
		implode: bool = false, glow: float = 0.35) -> void:
	if not VfxFog.ok(_fx_team, pos):
		return
	var ring := _rings[_ring_next]
	_ring_next = (_ring_next + 1) % _rings.size()
	_sp(ring, {&"tint": tint, &"fill": fill, &"width": width, &"glow": glow, &"fade": 1.0, &"seed": randf() * 10.0})
	ring.visible = true
	ring.global_position = pos + Vector3.UP * 0.07
	ring.scale = Vector3(r0, 1.0, r0)
	var tw := _tw(ring)
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector3(r1, 1.0, r1), time).set_trans(Tween.TRANS_CUBIC) \
			.set_ease(Tween.EASE_IN if implode else Tween.EASE_OUT)
	tw.tween_method(_ip.bind(ring, &"fade"), 1.0, 0.0, time).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func() -> void: ring.visible = false)


func _take_beam() -> MeshInstance3D:
	var b := _beams[_beam_next]
	for k in _beams.size():
		b = _beams[_beam_next]
		_beam_next = (_beam_next + 1) % _beams.size()
		if not _is_shot_part(b):
			break
	var old: Variant = b.get_meta(&"tw") if b.has_meta(&"tw") else null
	if old is Tween and (old as Tween).is_valid():
		(old as Tween).kill()
	for s in _shots:
		if s["tail"] == b:
			s["tail"] = null   # every beam is a live tail (many shots at once): that shot loses its tail
	return b


func _beam_params(b: MeshInstance3D, core: Color, edge: Color, width: float, tail: float, wobble: float) -> void:
	_sp(b, {&"core": core, &"body_color": edge, &"width": width, &"tail": tail, &"wobble": wobble, &"fade": 1.0,
			&"seed": randf() * 10.0, &"flow": 3.0})


func _place_beam(b: MeshInstance3D, a: Vector3, c: Vector3) -> void:
	var ax := c - a
	if ax.length() < 0.01:
		ax = Vector3.UP * 0.01
	var perp := ax.cross(Vector3.UP)
	perp = perp.normalized() if perp.length() > 0.001 else Vector3.RIGHT
	var perp2 := perp.cross(ax.normalized())
	b.global_transform = Transform3D(Basis(perp, ax, perp2), (a + c) * 0.5)


## A beam from a to b that flashes and thins out (w0 -> w1 metres) over `time`.
func _beam_flash(a: Vector3, b: Vector3, w0: float, w1: float, time: float, core: Color, edge: Color, tail: float) -> void:
	if not (VfxFog.ok(_fx_team, a) and VfxFog.ok(_fx_team, b)):
		return
	var beam := _take_beam()
	_beam_params(beam, core, edge, w0, tail, 0.35)
	_place_beam(beam, a, b)
	beam.visible = true
	var tw := _tw(beam)
	tw.set_parallel(true)
	tw.tween_method(_ip.bind(beam, &"width"), w0, w1, time).set_ease(Tween.EASE_IN)
	tw.tween_method(_ip.bind(beam, &"fade"), 1.0, 0.0, time).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func() -> void: beam.visible = false)


func _take_tendril() -> MeshInstance3D:
	var td: MeshInstance3D
	if not _tendril_free.is_empty():
		td = _tendril_free.pop_back()
	elif _tendril_count < TENDRIL_CAP:
		td = _mesh(_tendril_quad, _tendril_mat)
		add_child(td)
		_tendril_count += 1
	else:
		return null
	var old: Variant = td.get_meta(&"tw") if td.has_meta(&"tw") else null
	if old is Tween and (old as Tween).is_valid():
		(old as Tween).kill()
	td.set_meta(&"free", false)
	td.visible = true
	return td


func _release_tendril(td: MeshInstance3D, time: float) -> void:
	if not is_instance_valid(td) or bool(td.get_meta(&"free", false)):
		return
	if time > 0.0:
		var tw := _tw(td)
		tw.tween_method(_ip.bind(td, &"fade"), 1.0, 0.0, time)
		tw.tween_callback(_release_tendril.bind(td, 0.0))
		return
	td.set_meta(&"free", true)
	td.visible = false
	_tendril_free.append(td)


func _place_tendril(td: MeshInstance3D, a: Vector3, ctrl: Vector3, b: Vector3) -> void:
	td.set_instance_shader_parameter(&"p0", a)
	td.set_instance_shader_parameter(&"p1", ctrl)
	td.set_instance_shader_parameter(&"p2", b)
	var box := AABB(a, Vector3.ZERO).expand(ctrl).expand(b)
	td.custom_aabb = box.grow(1.0)


func _scorch(pos: Vector3, r: float, heat_time: float, life: float, burn: float = 0.85) -> void:
	if not VfxFog.ok(_fx_team, pos):
		return
	var s := _scorches[_scorch_next]
	_scorch_next = (_scorch_next + 1) % _scorches.size()
	s.visible = true
	s.global_position = pos + Vector3.UP * 0.035
	s.scale = Vector3(r, 1.0, r)
	s.rotation.y = randf() * TAU
	_sp(s, {&"burn": burn, &"heat": 1.0, &"flames": 0.0, &"rim": 0.0, &"front": -1.0, &"fade": 1.0, &"seed": randf() * 10.0})
	var tw := _tw(s)
	tw.set_parallel(true)
	tw.tween_method(_ip.bind(s, &"heat"), 1.0, 0.0, heat_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_method(_ip.bind(s, &"fade"), 1.0, 0.0, 1.2).set_delay(maxf(0.0, life - 1.2))
	tw.chain().tween_callback(func() -> void: s.visible = false)


func _light_flash(pos: Vector3, col: Color, energy: float, reach: float, time: float) -> void:
	if not VfxFog.ok(_fx_team, pos):
		return
	var g := _g()
	if g:   # Medium+: the G layer's pooled lights (same energy, attack / decay curve)
		g.light(pos, col, energy, reach, time)
		return
	var l := _lights[_light_next]
	_light_next = (_light_next + 1) % _lights.size()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = reach
	l.global_position = pos
	l.visible = true
	var tw := _tw(l)
	tw.tween_property(l, "light_energy", 0.0, time).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void: l.visible = false)


func _hide_zone_disc(zone: Node3D) -> void:
	for c in zone.get_children():
		if c is MeshInstance3D and not c.has_meta(META):
			(c as MeshInstance3D).visible = false


## Kills the node's previous tween (pooled pieces are reused) and returns a fresh one bound to it.
func _tw(n: Node) -> Tween:
	var old: Variant = n.get_meta(&"tw") if n.has_meta(&"tw") else null
	if old is Tween and (old as Tween).is_valid():
		(old as Tween).kill()
	var tw := n.create_tween()
	n.set_meta(&"tw", tw)
	return tw


func _ip(v: float, g: GeometryInstance3D, param: StringName) -> void:
	if is_instance_valid(g):
		g.set_instance_shader_parameter(param, v)


func _sp(g: GeometryInstance3D, params: Dictionary) -> void:
	for k: StringName in params:
		g.set_instance_shader_parameter(k, params[k])


func _mesh(mesh: Mesh, mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return m


func _emitter(look: StringName, one_shot: bool) -> GPUParticles3D:
	var d: Array = LOOKS[look]
	var p := GPUParticles3D.new()
	p.name = String(look)
	var pm := _pmat(look)
	if look in [&"ground_flames", &"ground_smoke", &"kindle_flames", &"siphon_motes", &"siphon_wisps"]:
		pm = pm.duplicate() as ParticleProcessMaterial   # per set: its radius changes
	p.process_material = pm
	var draw := int(d[2])
	p.draw_pass_1 = _quad if draw == 0 else (_streak if draw == 1 else _tongue)
	if String(look).begins_with("trail_"):
		p.fixed_fps = 0   # emit every frame: fast projectiles leave no gaps between puffs
	p.amount = int(d[0])
	p.lifetime = float(d[1])
	p.one_shot = one_shot
	p.explosiveness = float(d[6]) if one_shot else 0.0
	p.local_coords = false
	p.emitting = false
	p.visible = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-10.0, -3.0, -10.0), Vector3(20.0, 12.0, 20.0))
	p.set_instance_shader_parameter(&"axial", 1.0 if draw > 0 else 0.0)
	p.set_instance_shader_parameter(&"tongue", 1.0 if draw == 2 else 0.0)
	p.set_instance_shader_parameter(&"additive", float(d[3]))
	p.set_instance_shader_parameter(&"erosion", float(d[4]))
	p.set_instance_shader_parameter(&"core", float(d[5]))
	return p


func _find_projectile(w: Node3D) -> Node3D:
	var world := get_tree().current_scene if get_tree().current_scene else w.get_parent()
	var n := world.get_child_count()
	for i in range(n - 1, maxi(-1, n - 40), -1):
		var c := world.get_child(i)
		if c is Projectile and not c.has_meta(META) and (c as Projectile).source == w:
			return c
	return null


func _find_zone(id: StringName, pos: Vector3) -> Node3D:
	var world := get_tree().current_scene
	if world == null:
		return null
	var best: Node3D = null
	var best_d := 1.0
	var n := world.get_child_count()
	for i in range(n - 1, maxi(-1, n - 40), -1):
		var c := world.get_child(i)
		if c is SpellZone and not c.has_meta(META) and (c as SpellZone).spell_id == id:
			var d := (c as Node3D).global_position.distance_to(pos)
			if d < best_d:
				best_d = d
				best = c
	return best


## The model's staff head (`_bob`) or Vessa's off hand (`_palm`), if the wizard has a character model.
func _anchor(w: Node3D, part: StringName) -> Node3D:
	if not w.has_method(&"get_model"):
		return null
	var m: Variant = w.call(&"get_model")
	if m == null or not is_instance_valid(m):
		return null
	var n: Variant = (m as Object).get(part)
	if n is Node3D and is_instance_valid(n) and (n as Node3D).is_inside_tree():
		return n
	return null


func _height(u: Node3D) -> float:
	var h: Variant = u.get(&"body_height")
	return float(h) if h != null else 1.8


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


# ---------------------------------------------------------------- shared resources and pools

func _build_shared() -> void:
	# Seamless noise shared by the particle, scorch and veil shaders (generated once, on a worker thread).
	var fbm := FastNoiseLite.new()
	fbm.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	fbm.seed = 7
	fbm.frequency = 0.012
	fbm.fractal_type = FastNoiseLite.FRACTAL_FBM
	fbm.fractal_octaves = 4
	var noise_tex := NoiseTexture2D.new()
	noise_tex.width = 256
	noise_tex.height = 256
	noise_tex.seamless = true
	noise_tex.generate_mipmaps = true
	noise_tex.noise = fbm
	var cells := FastNoiseLite.new()
	cells.noise_type = FastNoiseLite.TYPE_CELLULAR
	cells.seed = 3
	cells.frequency = 0.035
	cells.fractal_type = FastNoiseLite.FRACTAL_NONE
	cells.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	cells.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	cells.cellular_jitter = 1.0
	var cell_tex := NoiseTexture2D.new()
	cell_tex.width = 256
	cell_tex.height = 256
	cell_tex.seamless = true
	cell_tex.generate_mipmaps = true
	cell_tex.noise = cells
	_particle_mat = ShaderMaterial.new()
	_particle_mat.shader = PARTICLE_SHADER
	_particle_mat.set_shader_parameter(&"noise_tex", noise_tex)
	_quad = QuadMesh.new()
	_quad.size = Vector2(1.0, 1.0)
	_quad.material = _particle_mat
	_streak = QuadMesh.new()
	_streak.size = Vector2(0.14, 1.0)
	_streak.material = _particle_mat
	_tongue = QuadMesh.new()
	_tongue.size = Vector2(0.8, 1.0)
	_tongue.center_offset = Vector3(0.0, 0.3, 0.0)   # the flame stands on its particle
	_tongue.material = _particle_mat
	_plane = PlaneMesh.new()
	_plane.size = Vector2(2.0, 2.0)
	_flare_quad = QuadMesh.new()
	_flare_quad.size = Vector2(1.0, 1.0)
	_beam_quad = QuadMesh.new()
	_beam_quad.size = Vector2(1.0, 1.0)
	_beam_quad.subdivide_depth = 6
	_tendril_quad = QuadMesh.new()
	_tendril_quad.size = Vector2(1.0, 1.0)
	_tendril_quad.subdivide_depth = 28
	_flame_quad = QuadMesh.new()
	_flame_quad.size = Vector2(1.0, 1.0)
	_veil_mesh = CylinderMesh.new()
	_veil_mesh.top_radius = 0.34
	_veil_mesh.bottom_radius = 0.5
	_veil_mesh.height = 1.0
	_veil_mesh.radial_segments = 18
	_veil_mesh.rings = 4
	_veil_mesh.cap_top = false
	_veil_mesh.cap_bottom = false
	_ring_mat = _shader_mat(RING_SHADER)
	_flare_mat = _shader_mat(FLARE_SHADER)
	_beam_mat = _shader_mat(BEAM_SHADER)
	_tendril_mat = _shader_mat(TENDRIL_SHADER)
	_scorch_mat = _shader_mat(SCORCH_SHADER)
	_siphon_mat = _shader_mat(SIPHON_SHADER)
	_flame_mat = _shader_mat(FLAME_SHADER)
	_veil_mat = _shader_mat(SHROUD_SHADER)
	_scorch_mat.set_shader_parameter(&"noise_tex", noise_tex)
	_scorch_mat.set_shader_parameter(&"cell_tex", cell_tex)
	_veil_mat.set_shader_parameter(&"noise_tex", noise_tex)
	for look: StringName in BURST_POOLS:
		var arr: Array[GPUParticles3D] = []
		for i in int(BURST_POOLS[look]):
			var p := _emitter(look, true)
			add_child(p)
			arr.append(p)
		_bursts[look] = arr
		_burst_next[look] = 0
	for kind: StringName in TRAIL_LOOKS:
		_trail_free[kind] = []
		_trail_live[kind] = 0
	for kind: StringName in AURA_CAPS:
		_aura_free[kind] = []
		_aura_live[kind] = 0
	for i in FLARE_POOL:
		var f := _mesh(_flare_quad, _flare_mat)
		f.visible = false
		add_child(f)
		_flares.append(f)
	for i in RING_POOL:
		var r := _mesh(_plane, _ring_mat)
		r.visible = false
		add_child(r)
		_rings.append(r)
	for i in BEAM_POOL:
		var b := _mesh(_beam_quad, _beam_mat)
		b.visible = false
		b.extra_cull_margin = 2.0
		add_child(b)
		_beams.append(b)
	for i in SCORCH_POOL:
		var s := _mesh(_plane, _scorch_mat)
		s.visible = false
		add_child(s)
		_scorches.append(s)
	for i in MAX_LIGHTS:
		var l := OmniLight3D.new()
		l.shadow_enabled = false
		l.light_specular = 0.2
		l.visible = false
		add_child(l)
		_lights.append(l)
	for i in EMBER_SETS:
		var root := Node3D.new()
		root.name = "EmberGround%d" % i
		root.visible = false
		add_child(root)
		var disc := _mesh(_plane, _scorch_mat)
		disc.position.y = 0.04
		root.add_child(disc)
		root.add_child(_emitter(&"ground_flames", false))
		root.add_child(_emitter(&"ground_smoke", false))
		_ember_free.append(root)
	for i in SIPHON_SETS:
		var root := Node3D.new()
		root.name = "Siphon%d" % i
		root.visible = false
		add_child(root)
		var disc := _mesh(_plane, _siphon_mat)
		disc.position.y = 0.05
		root.add_child(disc)
		root.add_child(_emitter(&"siphon_motes", false))
		root.add_child(_emitter(&"siphon_wisps", false))
		_siphon_free.append(root)
	for i in KINDLE_SETS:
		var root := Node3D.new()
		root.name = "Kindle%d" % i
		root.visible = false
		add_child(root)
		var disc := _mesh(_plane, _scorch_mat)
		disc.position.y = 0.045
		root.add_child(disc)
		root.add_child(_emitter(&"kindle_flames", false))
		_kindles.append(root)


func _shader_mat(shader: Shader) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader
	return m


## Particle process materials, one per look (shared by every emitter of that look, except the per-set
## duplicates made in _emitter).
func _pmat(key: StringName) -> ParticleProcessMaterial:
	if _pmats.has(key):
		return _pmats[key]
	var m := ParticleProcessMaterial.new()
	# Fire: r >> g >> b so it tonemaps to orange, not cream. Semi-opaque layers (additive 0.3) converge to about
	# colour / 0.7 where they overlap, so the flame ramps are that converged colour divided by 1.4.
	var sparks := [Color(2.0, 1.0, 0.3, 1.0), Color(1.8, 0.5, 0.08, 1.0), Color(0.8, 0.12, 0.02, 0.0)]
	var flames := [Color(1.25, 0.55, 0.12, 1.0), Color(1.0, 0.26, 0.035, 1.0), Color(0.5, 0.06, 0.01, 0.85), Color(0.08, 0.02, 0.01, 0.0)]
	var tongues := [Color(1.2, 0.45, 0.08, 0.0), Color(0.95, 0.22, 0.03, 1.0), Color(0.5, 0.06, 0.01, 0.8), Color(0.08, 0.02, 0.01, 0.0)]
	var violet := [Color(1.7, 0.7, 2.9, 1.0), Color(0.9, 0.25, 1.9, 1.0), Color(0.3, 0.05, 0.7, 0.0)]
	var dark := [Color(0.07, 0.02, 0.12, 0.0), Color(0.09, 0.03, 0.16, 0.8), Color(0.16, 0.06, 0.28, 0.45), Color(0.2, 0.08, 0.3, 0.0)]
	var smoke := [Color(0.06, 0.045, 0.04, 0.0), Color(0.06, 0.045, 0.04, 0.0), Color(0.08, 0.06, 0.05, 0.55), Color(0.16, 0.14, 0.13, 0.3), Color(0.2, 0.18, 0.17, 0.0)]   # appears after the flames
	match key:
		&"hand_fire", &"hand_shadow":
			_shape_ring(m, 0.9, 0.3, 0.7)
			m.direction = Vector3.UP
			m.spread = 0.0
			m.radial_velocity_min = -3.2
			m.radial_velocity_max = -2.4
			m.tangential_accel_min = 6.0
			m.tangential_accel_max = 9.0
			m.gravity = Vector3.ZERO
			_size(m, 0.16, 0.26, false)
			if key == &"hand_fire":
				m.color_ramp = _ramp([Color(2.0, 0.8, 0.2, 0.0), Color(1.9, 0.6, 0.1, 1.0), Color(2.1, 1.0, 0.3, 1.0)])
			else:
				m.color_ramp = _ramp([Color(1.4, 0.45, 2.6, 0.0), Color(1.3, 0.4, 2.4, 1.0), Color(1.7, 0.7, 2.9, 1.0)])
		&"impact_sparks":
			_shape_sphere(m, 0.35)
			m.direction = Vector3.UP
			m.spread = 80.0
			m.initial_velocity_min = 7.0
			m.initial_velocity_max = 14.0
			m.gravity = Vector3(0, -16.0, 0)
			m.damping_min = 1.0
			m.damping_max = 2.0
			m.particle_flag_align_y = true
			_size(m, 0.35, 0.65, false)
			m.color_ramp = _ramp(sparks)
		&"impact_flames":
			_shape_sphere(m, 0.9)
			m.direction = Vector3.UP
			m.spread = 70.0
			m.initial_velocity_min = 2.5
			m.initial_velocity_max = 5.5
			m.gravity = Vector3(0, 2.5, 0)
			m.damping_min = 3.0
			m.damping_max = 4.0
			_spin(m)
			_size(m, 1.3, 2.1, true)
			m.color_ramp = _ramp(flames)
		&"impact_smoke":
			_shape_sphere(m, 1.0)
			m.direction = Vector3.UP
			m.spread = 50.0
			m.initial_velocity_min = 1.0
			m.initial_velocity_max = 2.5
			m.gravity = Vector3(0, 1.2, 0)
			m.damping_min = 1.2
			m.damping_max = 1.8
			_spin(m)
			_size(m, 1.6, 2.6, true)
			m.color_ramp = _ramp(smoke)
		&"fire_column":
			_shape_ring(m, 0.5, 0.2, 0.0)
			m.direction = Vector3.UP
			m.spread = 12.0
			m.initial_velocity_min = 4.0
			m.initial_velocity_max = 7.5
			m.gravity = Vector3(0, 1.0, 0)
			m.damping_min = 3.5
			m.damping_max = 5.0
			m.particle_flag_align_y = true
			_size(m, 1.1, 1.9, true)
			m.color_ramp = _ramp(flames)
		&"land_sparks":
			_shape_ring(m, 0.45, 0.1, 0.2)
			m.direction = Vector3.UP
			m.spread = 60.0
			m.initial_velocity_min = 5.0
			m.initial_velocity_max = 9.0
			m.gravity = Vector3(0, -14.0, 0)
			m.particle_flag_align_y = true
			_size(m, 0.3, 0.5, false)
			m.color_ramp = _ramp(sparks)
		&"dash_embers":
			m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			m.emission_box_extents = Vector3(0.6, 0.4, 0.6)
			m.direction = Vector3.UP
			m.spread = 40.0
			m.initial_velocity_min = 1.0
			m.initial_velocity_max = 3.0
			m.gravity = Vector3(0, -6.0, 0)
			m.particle_flag_align_y = true
			_size(m, 0.2, 0.36, false)
			m.color_ramp = _ramp(sparks)
		&"lance_shards":
			_shape_sphere(m, 0.15)
			m.direction = Vector3(0, 0, -1)
			m.spread = 24.0
			m.initial_velocity_min = 8.0
			m.initial_velocity_max = 16.0
			m.gravity = Vector3.ZERO
			m.damping_min = 9.0
			m.damping_max = 13.0
			m.particle_flag_align_y = true
			_size(m, 0.55, 0.95, false)
			m.color_ramp = _ramp(violet)
		&"shadow_puff":
			_shape_sphere(m, 0.6)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 1.0
			m.initial_velocity_max = 2.5
			m.gravity = Vector3(0, 0.8, 0)
			m.damping_min = 2.0
			m.damping_max = 3.0
			_spin(m)
			_size(m, 1.0, 1.6, true)
			m.color_ramp = _ramp(dark)
		&"shadow_motes":
			_shape_sphere(m, 0.5)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 2.0
			m.initial_velocity_max = 4.0
			m.gravity = Vector3(0, 1.5, 0)
			m.damping_min = 3.0
			m.damping_max = 3.5
			_size(m, 0.18, 0.3, false)
			m.color_ramp = _ramp(violet)
		&"implode":
			_shape_ring(m, 2.6, 0.3, 2.0)
			m.direction = Vector3.UP
			m.spread = 0.0
			m.radial_velocity_min = -6.5
			m.radial_velocity_max = -5.0
			m.tangential_accel_min = 4.0
			m.tangential_accel_max = 6.0
			m.gravity = Vector3(0, 1.0, 0)
			_spin(m)
			_size(m, 0.9, 1.3, false)
			m.color_ramp = _ramp([Color(0.08, 0.02, 0.14, 0.0), Color(0.12, 0.04, 0.2, 0.85), Color(0.8, 0.35, 1.4, 0.6), Color(0.3, 0.1, 0.6, 0.0)])
		&"trail_fire":
			_shape_sphere(m, 0.18)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 0.3
			m.initial_velocity_max = 0.9
			m.gravity = Vector3(0, 1.5, 0)
			m.damping_min = 1.0
			m.damping_max = 1.0
			_spin(m)
			_size(m, 0.6, 0.95, true)
			m.color_ramp = _ramp(flames)
		&"trail_smoke":
			_shape_sphere(m, 0.2)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 0.2
			m.initial_velocity_max = 0.6
			m.gravity = Vector3(0, 1.0, 0)
			_spin(m)
			_size(m, 0.6, 1.0, true)
			m.color_ramp = _ramp([Color(0.1, 0.06, 0.05, 0.0), Color(0.12, 0.08, 0.07, 0.45), Color(0.2, 0.17, 0.16, 0.0)])
		&"trail_embers":
			_shape_sphere(m, 0.2)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 1.0
			m.initial_velocity_max = 3.0
			m.gravity = Vector3(0, -8.0, 0)
			m.particle_flag_align_y = true
			_size(m, 0.14, 0.26, false)
			m.color_ramp = _ramp(sparks)
		&"trail_lance":
			_shape_sphere(m, 0.12)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 0.2
			m.initial_velocity_max = 0.6
			m.gravity = Vector3.ZERO
			m.damping_min = 1.0
			m.damping_max = 1.0
			_size(m, 0.3, 0.5, false)
			m.color_ramp = _ramp(violet)
		&"trail_umbra":
			_shape_sphere(m, 0.15)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 0.2
			m.initial_velocity_max = 0.5
			m.gravity = Vector3(0, 0.3, 0)
			_spin(m)
			_size(m, 0.55, 0.85, true)
			m.color_ramp = _ramp([Color(0.06, 0.01, 0.1, 0.0), Color(0.1, 0.03, 0.18, 0.7), Color(0.15, 0.05, 0.25, 0.0)])
		&"ground_flames":
			_shape_ring(m, 2.0, 0.1, 0.0)
			m.direction = Vector3.UP
			m.spread = 8.0
			m.initial_velocity_min = 0.8
			m.initial_velocity_max = 1.8
			m.gravity = Vector3(0, 1.5, 0)
			m.damping_min = 0.5
			m.damping_max = 0.5
			m.particle_flag_align_y = true
			_size(m, 0.8, 1.35, true)
			m.color_ramp = _ramp(tongues)
		&"ground_smoke":
			_shape_ring(m, 1.5, 0.1, 0.0)
			m.direction = Vector3.UP
			m.spread = 10.0
			m.initial_velocity_min = 0.4
			m.initial_velocity_max = 0.9
			m.gravity = Vector3(0, 0.6, 0)
			_spin(m)
			_size(m, 1.0, 1.6, true)
			m.color_ramp = _ramp([Color(0.1, 0.07, 0.06, 0.0), Color(0.12, 0.09, 0.08, 0.35), Color(0.22, 0.2, 0.19, 0.0)])
		&"kindle_flames":
			_shape_ring(m, 1.0, 0.1, 0.85)
			m.direction = Vector3.UP
			m.spread = 10.0
			m.initial_velocity_min = 1.0
			m.initial_velocity_max = 2.0
			m.gravity = Vector3(0, 1.0, 0)
			m.damping_min = 1.0
			m.damping_max = 1.5
			m.particle_flag_align_y = true
			_size(m, 0.65, 1.1, true)
			m.color_ramp = _ramp(tongues)
		&"siphon_motes":
			_shape_ring(m, 3.8, 0.1, 3.0)
			m.direction = Vector3.UP
			m.spread = 5.0
			m.initial_velocity_min = 0.4
			m.initial_velocity_max = 0.8
			m.radial_accel_min = -1.8
			m.radial_accel_max = -1.2
			m.tangential_accel_min = 1.5
			m.tangential_accel_max = 2.2
			m.gravity = Vector3(0, 0.5, 0)
			_size(m, 0.18, 0.3, false)
			m.color_ramp = _ramp([Color(1.6, 0.8, 2.6, 0.0), Color(1.3, 0.38, 2.5, 1.0), Color(0.5, 0.15, 0.9, 0.0)])
		&"siphon_wisps":
			_shape_ring(m, 2.8, 0.1, 0.0)
			m.direction = Vector3.UP
			m.spread = 15.0
			m.initial_velocity_min = 0.3
			m.initial_velocity_max = 0.7
			m.tangential_accel_min = 0.8
			m.tangential_accel_max = 1.2
			m.gravity = Vector3(0, 0.6, 0)
			_spin(m)
			_size(m, 0.8, 1.3, true)
			m.color_ramp = _ramp(dark)
		&"shroud_smoke":
			_shape_ring(m, 0.7, 0.3, 0.4)
			m.direction = Vector3.UP
			m.spread = 25.0
			m.initial_velocity_min = 0.4
			m.initial_velocity_max = 0.9
			m.tangential_accel_min = 1.2
			m.tangential_accel_max = 2.0
			m.gravity = Vector3(0, 0.8, 0)
			_spin(m)
			_size(m, 0.7, 1.2, true)
			m.color_ramp = _ramp([Color(0.06, 0.01, 0.1, 0.0), Color(0.08, 0.02, 0.14, 0.75), Color(0.14, 0.05, 0.24, 0.4), Color(0.16, 0.06, 0.26, 0.0)])
		&"shroud_wisps":
			_shape_ring(m, 0.8, 1.4, 0.6)
			m.emission_shape_offset = Vector3(0, 0.8, 0)
			m.direction = Vector3.UP
			m.spread = 10.0
			m.initial_velocity_min = 0.8
			m.initial_velocity_max = 1.4
			m.tangential_accel_min = 3.0
			m.tangential_accel_max = 4.0
			m.radial_accel_min = -0.6
			m.radial_accel_max = -0.3
			_size(m, 0.12, 0.2, false)
			m.color_ramp = _ramp(violet)
		&"haste_embers":
			_shape_ring(m, 0.35, 0.1, 0.2)
			m.direction = Vector3.UP
			m.spread = 12.0
			m.initial_velocity_min = 1.5
			m.initial_velocity_max = 2.5
			m.gravity = Vector3.ZERO
			m.particle_flag_align_y = true
			_size(m, 0.16, 0.26, false)
			m.color_ramp = _ramp(sparks)
	_pmats[key] = m
	return m


func _shape_sphere(m: ParticleProcessMaterial, r: float) -> void:
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = r


func _shape_ring(m: ParticleProcessMaterial, r: float, h: float, inner: float) -> void:
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	m.emission_ring_axis = Vector3.UP
	m.emission_ring_radius = r
	m.emission_ring_inner_radius = inner
	m.emission_ring_height = h


func _spin(m: ParticleProcessMaterial) -> void:
	m.angle_min = -180.0
	m.angle_max = 180.0
	m.angular_velocity_min = -60.0
	m.angular_velocity_max = 60.0


## Particle size (the draw quad is 1 m): shrinks over life, or grows then shrinks a little (flames, smoke).
func _size(m: ParticleProcessMaterial, lo: float, hi: float, grow: bool) -> void:
	m.scale_min = lo
	m.scale_max = hi
	var c := Curve.new()
	if grow:
		c.add_point(Vector2(0.0, 0.45))
		c.add_point(Vector2(0.35, 1.0))
		c.add_point(Vector2(1.0, 0.75))
	else:
		c.add_point(Vector2(0.0, 1.0))
		c.add_point(Vector2(1.0, 0.15))
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
