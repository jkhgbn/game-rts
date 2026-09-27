class_name ChampionMageArcherVfx
extends RefCounted
## The Mage Archer's effects (task 13b.V8, tier3-extras.md 6.5 / 12): a part of ChampionVfx. champion_vfx.gd creates
## one of these in _ready, builds its pools, bursts and streams with its own and hands it these ids; the effects then
## run on ChampionVfx's runtime (pooled pieces, one-shot bursts, streams, fog, deaths, statuses). Callers use the one
## ChampionVfx API:
##   get_tree().get_first_node_in_group(&"champion_vfx").play(id, caster, target_or_point)
##   arcane_arrow    her shot (optional, per attack; target = the unit): a white-violet arrow of light with swept vanes
##                   on the Projectile's own path (32 m/s, arc 0.6, aimed 1 m up the target), a violet mote trail, a
##                   string glint at the bow, splinters + a small flash on the hit.
##   sable_shaft     (target = the unit or the aim point) the bow charges (violet light gathering at the arrow head,
##                   a dark halo) until the model's loose at SHAFT_RELEASE (0.55 s); then a black barbed arrow rimmed in
##                   violet fire tears 16 m down the line (64 m/s) leaving a pierce beam (white-hot, then a black core
##                   between violet rims, 0.5 s) and a burning scar on the ground; splinters, smoke and a flash on the
##                   first enemy unit and up to 2 more behind it (1 m wide line, picked when she looses); a flash where
##                   it leaves the line. Dropped if she dies while drawing; once loosed it plays out.
##   grave_mark      (target = the unit) at the pointing jab a violet dart flies from her rune quiver (0.28 s + 0.12 s);
##                   the Grave Mark sigil drops over the target's head (a turning broken rune ring round a downward
##                   arrow struck through by a grave cross) with a chevron ring and a dark pool at its feet and violet
##                   ash drifting down, for the 6 s of `marked` (ends with the status, like Marked for Coin). If the
##                   marked unit dies (not when the mark runs out), a violet soul wisp arcs back into her (the 40 heal)
##                   and a glint flares at her bow (Sable Shaft is ready again): internal effect `grave_reap`.
##   eclipse_volley  (target = the point, r 4) the telegraph ring at once (a bright rune rim, the disc darkening with a
##                   violet corona, a ring closing on the centre, the black-sun glyph; shown to whoever sees the spot:
##                   both teams when their units stand in it), the bow looses a fan of arrows straight up at the
##                   model's 0.52 s, then 3 waves of falling violet arrows land at VOLLEY_WAVES (0.75, 1.125, 1.5 s):
##                   splinters, dust, a shock ring each, arrows left standing in the ground; they sink away and the
##                   pocked, glowing scorch fades 1.1 s after the last wave. Plays out even if she dies.
##   unique_call     (caster = the Mage Archer as she steps out, right with her model's play_call(); target = her, the
##                   Lair or a point) the call ritual under her: a summoning circle drawn in by a sweep (rune band,
##                   crescent and stars, the ground opened dark with glowing cracks), shadow smoke rolling out, a violet
##                   column rising from it with motes climbing, and the peak at 1.5 s (the model lifts the bow over her
##                   head): a flash, a shock ring, a belt of light, sparks; over at ~2.9 s. Without a caster: at the point.
##   unique_revive   (caster = the Mage Archer where she comes back) a pillar of violet light driven down from the sky
##                   (0.3 s), a flash and a shock ring where it lands, the revive circle (three turning crescents), a
##                   phase shimmer round her, rising motes; over at 1.7 s.
## Budget: 5 mesh pools (bolts 12, ground marks 14, columns 6, sigils 4, stuck-arrow sets 6), 15 burst looks and 6
## stream looks, all built at ChampionVfx._ready; 6 shaders, one material each; per-cast data only in instance
## uniforms. No lights, no shadows, nothing created after _ready.

const IDS: Array[StringName] = [&"arcane_arrow", &"sable_shaft", &"grave_mark", &"eclipse_volley", &"unique_call",
		&"unique_revive"]

# Palette: the Shadow kingdom glow (her string, tier3-extras.md 6.2 projectile colour) and its hot / deep ends.
const GLOW := Color(0.70, 0.30, 1.00)
const HOT := Color(0.93, 0.82, 1.00)
const DEEP := Color(0.36, 0.10, 0.66)
const SABLE := Color(0.07, 0.04, 0.10)
const DUST := Color(0.24, 0.20, 0.28)

# Numbers from tier3-extras.md 6.2 / 6.5 and the model's poses (art/units/champions/mage_archer/mage_archer.gd).
const ARROW_SPEED := 32.0        # her projectile, m/s
const ARROW_ARC := 0.6           # Projectile.launch_at_target's default arc
const ARROW_AIM := 1.0           # Projectile._target_offset on a unit
const SHAFT_RELEASE := 0.55      # the model's sable_shaft loose (a heavy charged draw)
const SHAFT_RANGE := 16.0
const SHAFT_HALF_WIDTH := 0.5
const SHAFT_SPEED := 64.0
const SHAFT_PIERCE := 3          # the first enemy unit + up to 2 behind it
const SHAFT_LINGER := 0.5
const MARK_RELEASE := 0.28       # the dart leaves just before the model's pointing jab (0.34 s)
const MARK_FLIGHT := 0.12
const MARK_TIME := 6.0
const REAP_FLIGHT := 0.5
const VOLLEY_RADIUS := 4.0
const VOLLEY_LOOSE := 0.52       # the model's eclipse_volley loose (aimed 68 deg up)
const VOLLEY_WAVES: Array[float] = [0.75, 1.125, 1.5]   # impacts: 3 waves over 1.5 s
const VOLLEY_FALL := 0.33        # each wave's fall time from VOLLEY_HEIGHT
const VOLLEY_HEIGHT := 10.0
const VOLLEY_SLANT := 0.22       # the rain drifts this much along her aim per metre of fall
const VOLLEY_LINGER := 1.1
const CALL_LEN := 2.0            # the model's play_call()
const CALL_FLASH := 1.5          # ... the bow lifted over her head
const CALL_RADIUS := 2.6
const COLUMN_HEIGHT := 5.5
const REVIVE_LAND := 0.3
const REVIVE_TIME := 1.7
const REVIVE_RADIUS := 1.9
const PILLAR_HEIGHT := 10.0
const STUCK_ARROWS := 16

const A_POINT := ChampionVfx.A_POINT
const A_TARGET := ChampionVfx.A_TARGET
const A_CASTER := ChampionVfx.A_CASTER
const A_ARROW := ChampionVfx.A_ARROW
const A_WORLD := ChampionVfx.A_WORLD
const VIS_CASTER := ChampionVfx.VIS_CASTER
const VIS_POINT := ChampionVfx.VIS_POINT
const G_SHOCK := ChampionVfx.G_SHOCK

# Ground patterns (champion_mage_archer_ground.gdshader) and bolt styles (champion_mage_archer_bolt.gdshader).
enum { M_ECLIPSE, M_CALL, M_REVIVE, M_GRAVE, M_RIFT, M_VOLLEY }
enum { B_ARROW, B_SHAFT, B_BEAM, B_DART }

## Mesh pools (pre-built by ChampionVfx): pool -> size.
const POOL_SIZES := {&"ma_bolt": 12, &"ma_ground": 14, &"ma_column": 6, &"ma_sigil": 4, &"ma_stuck": 6}
## Pools whose pieces are ground discs (ChampionVfx sends them `radius`).
const DISC_POOLS: Array[StringName] = [&"ma_ground"]
## One-shot bursts: look -> [amount, lifetime, draw pass, pool size, explosiveness] (ChampionVfx.BURSTS format).
const BURSTS := {
	&"ma_arrow_hit": [14, 0.4, &"streak", 8, 1.0],
	&"ma_gather": [22, 0.5, &"add_star", 3, 0.35],
	&"ma_bow_flash": [18, 0.35, &"streak", 4, 1.0],
	&"ma_shaft_hit": [26, 0.45, &"streak", 6, 1.0],
	&"ma_shaft_puff": [10, 0.9, &"mix_smoke", 6, 0.95],
	&"ma_mark_glint": [12, 0.6, &"add_star", 4, 0.95],
	&"ma_reap_heal": [18, 0.9, &"add_star", 3, 0.8],
	&"ma_volley_up": [14, 0.45, &"ma_arrow", 2, 0.85],
	&"ma_volley_rain": [20, 0.36, &"ma_arrow", 6, 0.85],
	&"ma_volley_hit": [30, 0.45, &"streak", 4, 0.85],
	&"ma_volley_dust": [14, 1.1, &"mix_smoke", 4, 0.85],
	&"ma_call_smoke": [22, 1.6, &"mix_smoke", 3, 0.9],
	&"ma_call_flash": [36, 0.7, &"streak", 2, 1.0],
	&"ma_revive_hit": [30, 0.55, &"streak", 2, 1.0],
	&"ma_revive_motes": [26, 1.2, &"add_star", 3, 0.6],
}
## Continuous streams: look -> [amount, lifetime, draw pass, cap, local] (ChampionVfx.STREAMS format).
const STREAMS := {
	&"ma_arrow_trail": [44, 0.3, &"add_dot", 6, false],
	&"ma_shaft_sparks": [40, 0.4, &"add_dot", 3, false],
	&"ma_shaft_smoke": [26, 0.8, &"mix_smoke", 3, false],
	&"ma_mark_ash": [10, 1.3, &"add_dot", 4, false],
	&"ma_reap_trail": [30, 0.35, &"add_dot", 3, false],
	&"ma_call_motes": [44, 1.4, &"add_dot", 2, false],
}

const GROUND_SHADER := preload("res://art/vfx/champion_mage_archer_ground.gdshader")
const BOLT_SHADER := preload("res://art/vfx/champion_mage_archer_bolt.gdshader")
const COLUMN_SHADER := preload("res://art/vfx/champion_mage_archer_column.gdshader")
const SIGIL_SHADER := preload("res://art/vfx/champion_mage_archer_sigil.gdshader")
const STUCK_SHADER := preload("res://art/vfx/champion_mage_archer_stuck.gdshader")
const ARROW_SHADER := preload("res://art/vfx/champion_mage_archer_arrow.gdshader")

var h: ChampionVfx
var _layer := 0


func _init(host: ChampionVfx) -> void:
	h = host


# ---------------------------------------------------------------- what ChampionVfx builds at _ready

func pool_mesh(pool: StringName) -> Mesh:
	match pool:
		&"ma_ground":
			var plane := PlaneMesh.new()
			plane.size = Vector2(2.0, 2.0)
			return plane
		&"ma_column":
			var cyl := CylinderMesh.new()
			cyl.top_radius = 1.0
			cyl.bottom_radius = 1.0
			cyl.height = 1.0
			cyl.radial_segments = 32
			cyl.rings = 3
			cyl.cap_top = false
			cyl.cap_bottom = false
			return cyl
		&"ma_stuck":
			return _stuck_mesh()
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	return quad


func pool_material(pool: StringName) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	match pool:
		&"ma_ground":
			m.shader = GROUND_SHADER
		&"ma_column":
			m.shader = COLUMN_SHADER
		&"ma_sigil":
			m.shader = SIGIL_SHADER
		&"ma_stuck":
			m.shader = STUCK_SHADER
		_:
			m.shader = BOLT_SHADER
	return m


## Extra cull margin of a pool's instances (axial / camera-facing quads leave their mesh AABB).
func pool_cull_margin(pool: StringName) -> float:
	match pool:
		&"ma_bolt", &"ma_sigil":
			return 2.0
		&"ma_stuck":
			return 1.0
	return 0.0


## Adds the draw passes of these looks to ChampionVfx's pass table.
func add_passes(passes: Dictionary) -> void:
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	var sm := ShaderMaterial.new()
	sm.shader = ARROW_SHADER
	sm.set_shader_parameter(&"stretch", 6.0)
	q.material = sm
	passes[&"ma_arrow"] = q


## Visibility box of an emitter of `look` (size zero = ChampionVfx's default): falls, climbs and long trails.
func emitter_aabb(look: StringName) -> AABB:
	match look:
		&"ma_volley_rain":
			return AABB(Vector3(-8.0, -12.0, -8.0), Vector3(16.0, 14.0, 16.0))
		&"ma_volley_up":
			return AABB(Vector3(-5.0, -2.0, -5.0), Vector3(10.0, 15.0, 10.0))
		&"ma_call_motes":
			return AABB(Vector3(-4.0, -1.0, -4.0), Vector3(8.0, 10.0, 8.0))
		&"ma_shaft_sparks", &"ma_shaft_smoke":
			return AABB(Vector3(-17.0, -4.0, -17.0), Vector3(34.0, 12.0, 34.0))
		&"ma_arrow_trail", &"ma_reap_trail", &"ma_volley_hit", &"ma_volley_dust":
			return AABB(Vector3(-9.0, -3.0, -9.0), Vector3(18.0, 12.0, 18.0))
	return AABB()


# ---------------------------------------------------------------- the effects

## Builds effect `fx` (fx.id is one of IDS). Called by ChampionVfx.play before it starts the effect.
func build(fx: ChampionVfx.Fx) -> void:
	match fx.id:
		&"arcane_arrow":
			_arcane_arrow(fx)
		&"sable_shaft":
			_sable_shaft(fx)
		&"grave_mark":
			_grave_mark(fx)
		&"eclipse_volley":
			_eclipse_volley(fx)
		&"unique_call":
			_unique_call(fx)
		&"unique_revive":
			_unique_revive(fx)


## Her shot: an arrow of light on the Projectile's path (it lands where the gameplay's bolt lands).
func _arcane_arrow(fx: ChampionVfx.Fx) -> void:
	var aim := Vector3.UP * (ARROW_AIM if fx.has_target else 0.25)
	var end := fx.tpos + aim
	var from := h._hand(fx.caster, end) if is_instance_valid(fx.caster) else end + Vector3(-4.0, 2.5, 3.0)
	var ft := maxf(0.1, from.distance_to(end) / ARROW_SPEED)
	var dir := (end - from).normalized() if from.distance_to(end) > 0.01 else Vector3.FORWARD
	fx.dur = ft + 0.35
	var arrow := h._piece(fx, &"ma_bolt", A_TARGET, aim, 0.0, ft, 0.0, 0.0)
	h._mode(arrow, &"home", {"from": from, "time": ft, "wave": ARROW_ARC, "ln": 1.5, "width": 0.42})
	h._params(arrow, {&"style": float(B_ARROW), &"tint": h._hdr(GLOW, 2.2), &"seed": randf() * 10.0})
	h._stream(fx, &"ma_arrow_trail", 0.0, ft + 0.02, A_ARROW, Vector3.ZERO)
	h._flare(fx, A_WORLD, from, h._hdr(GLOW, 2.0), 0.35, 0.75, 0.06, 0.0, 0.14, 0.0, 0.1, 0.6, 4.0)
	h._sched(fx, &"ma_arrow_hit", ft, A_TARGET, aim, 1.0, dir)
	h._flare(fx, A_TARGET, aim, h._hdr(GLOW, 2.4), 0.6, 1.1, 0.08, ft, ft + 0.22, 0.0, 0.16, 0.8, 4.0)


## Sable Shaft: the charge follows the bow (fx.ext) until SHAFT_RELEASE, then the shot is built from where the bow is.
func _sable_shaft(fx: ChampionVfx.Fx) -> void:
	var has_c := is_instance_valid(fx.caster)
	var rel := SHAFT_RELEASE if has_c else 0.0
	fx.dur = rel + (SHAFT_RANGE + 1.0) / SHAFT_SPEED + 1.5
	fx.vis = VIS_CASTER if has_c else VIS_POINT
	fx.dep = 2 if has_c else 0     # she dies drawing: no shot (set to 0 at the loose)
	fx.tail = 0.1
	fx.data["rel"] = rel
	fx.data["fired"] = false
	fx.data["arrow_pos"] = h._hand(fx.caster, fx.tpos) if has_c else fx.tpos + Vector3.UP * 1.4
	fx.ext = _shaft_tick
	if rel <= 0.0:
		return
	var charge := h._flare(fx, A_ARROW, Vector3.ZERO, h._hdr(GLOW, 2.2), 0.25, 1.15, rel, 0.0, rel + 0.05, 0.12, 0.05,
			1.0, 4.0, 0.6)
	h._params(charge, {&"halo": Color(0.02, 0.0, 0.04, 0.6)})
	h._sched(fx, &"ma_gather", 0.02, A_ARROW, Vector3.ZERO)
	h._disc(fx, A_CASTER, G_SHOCK, h._hdr(GLOW, 0.8), 1.8, 0.6, 0.45, 0.0, rel, 0.1, 0.1)


func _shaft_tick(fx: ChampionVfx.Fx, _delta: float) -> void:
	if bool(fx.data["fired"]):
		# The pierce beam trails the arrow head (one frame behind it), then spans the whole line.
		var beam: Variant = fx.data.get("beam")
		if beam != null:
			(beam as ChampionVfx.Piece).a = fx.data["arrow_pos"] if fx.t < float(fx.data["land"]) else fx.data["end"]
		return
	if h._in_tree(fx.caster):
		fx.data["arrow_pos"] = h._hand(fx.caster, fx.tpos)
	if fx.t < float(fx.data["rel"]):
		return
	fx.data["fired"] = true
	fx.dep = 0
	_shaft_shot(fx)


func _shaft_shot(fx: ChampionVfx.Fx) -> void:
	var t0 := fx.t
	var bow: Vector3 = fx.data["arrow_pos"]
	var c := fx.cpos
	var cr := h._r(fx.caster)
	var dir := h._toward(c, fx.tpos)
	if dir == Vector3.ZERO:
		dir = h._facing(fx.caster)
	var reach := cr + SHAFT_RANGE
	var start_g := c + dir * cr
	var end_g := c + dir * reach
	# Level over the ground (the shaft runs through bodies at ~1.1 m); aimed up the line at a flying first target.
	var end_y := c.y + 1.1
	if fx.has_target and fx.tpos.y - c.y > 2.0:
		var tc := fx.tpos + Vector3.UP * h._h(fx.target) * 0.5
		var hd := Vector2(tc.x - bow.x, tc.z - bow.z).length()
		end_y = bow.y + (tc.y - bow.y) * (reach / maxf(hd, 1.0))
	var end_h := Vector3(end_g.x, end_y, end_g.z)
	var flight := maxf(0.08, bow.distance_to(end_h) / SHAFT_SPEED)
	var land := t0 + flight
	fx.data["land"] = land
	fx.data["end"] = end_h
	fx.dur = land + 1.5
	var head := h._piece(fx, &"ma_bolt", A_WORLD, end_h, t0, land, 0.0, 0.0)
	h._mode(head, &"home", {"from": bow, "time": flight, "wave": 0.0, "ln": 3.0, "width": 1.0})
	h._params(head, {&"style": float(B_SHAFT), &"tint": h._hdr(GLOW, 2.3), &"seed": randf() * 10.0})
	var beam := h._piece(fx, &"ma_bolt", A_WORLD, Vector3.ZERO, t0, land + SHAFT_LINGER, 0.0, 0.35)
	h._mode(beam, &"dash", {"from": bow, "a": bow, "ext": 0.001, "width": 0.8})
	h._params(beam, {&"style": float(B_BEAM), &"tint": h._hdr(GLOW, 2.0), &"seed": randf() * 10.0})
	fx.data["beam"] = beam
	h._stream(fx, &"ma_shaft_sparks", t0, land + 0.02, A_ARROW, Vector3.ZERO)
	h._stream(fx, &"ma_shaft_smoke", t0, land + 0.02, A_ARROW, Vector3.ZERO)
	# The loose: a flash at the bow, sparks thrown down the line, a ring at her feet; the scar burns along the ground.
	h._flare(fx, A_WORLD, bow, h._hdr(GLOW.lerp(HOT, 0.4), 2.6), 1.2, 2.2, 0.08, t0, t0 + 0.28, 0.0, 0.2, 1.4, 4.0)
	h._sched(fx, &"ma_bow_flash", t0, A_WORLD, bow, 1.2, dir)
	h._disc(fx, A_CASTER, G_SHOCK, h._hdr(GLOW, 1.0), 0.3, 1.4, 0.25, t0, t0 + 0.4, 0.0, 0.3)
	var rift := _rift(fx, start_g, end_g, 0.6, t0, 0.0, 0.0, 0.9)
	h._params(rift, {&"speed": (reach - cr) / flight})
	# Where it leaves the line.
	h._flare(fx, A_WORLD, end_h, h._hdr(GLOW, 2.2), 0.8, 1.5, 0.1, land, land + 0.25, 0.0, 0.2, 0.9, 4.0)
	h._sched(fx, &"ma_bow_flash", land, A_WORLD, end_h, 0.8, dir)
	# The pierced: the first enemy unit in the 1 m line and up to 2 more behind it, as she looses.
	var hits: Array = []
	for node in h.get_tree().get_nodes_in_group(&"units"):
		if node == fx.caster or not h._is_enemy_of(node, fx.team):
			continue
		var u := node as Node3D
		var rel_p := u.global_position - c
		rel_p.y = 0.0
		var along := rel_p.dot(dir)
		var ur := h._r(u)
		if along < 0.0 or along > reach + ur or (rel_p - dir * along).length() > SHAFT_HALF_WIDTH + ur:
			continue
		hits.append([along, u])
	hits.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	for i in mini(hits.size(), SHAFT_PIERCE):
		var u: Node3D = hits[i][1]
		var at := t0 + clampf(float(hits[i][0]) / reach, 0.0, 1.0) * flight
		var p := u.global_position + Vector3.UP * h._h(u) * 0.55
		var big := i == 0
		h._sched(fx, &"ma_shaft_hit", at, A_WORLD, p, 1.25 if big else 0.9, dir)
		h._sched(fx, &"ma_shaft_puff", at, A_WORLD, p, 1.0 if big else 0.8)
		h._flare(fx, A_WORLD, p, h._hdr(GLOW.lerp(HOT, 0.3), 2.4), 0.9, 1.7 if big else 1.2, 0.1, at, at + 0.3, 0.0,
				0.2, 1.1, 4.0)


## Grave Mark: the dart, then the sigil for the 6 s of `marked`; a kill while marked sends the soul wisp back.
func _grave_mark(fx: ChampionVfx.Fx) -> void:
	var has_c := is_instance_valid(fx.caster)
	var ht := h._h(fx.target)
	var r := h._r(fx.target)
	var mh := ht + 0.95
	var rel := MARK_RELEASE if has_c else 0.0
	var land := rel + (MARK_FLIGHT if has_c else 0.0)
	fx.dep = 1 if fx.has_target else 0
	fx.dur = land + MARK_TIME
	fx.status = &"marked"
	fx.status_at = land
	fx.status_max = fx.dur
	fx.tail = 0.3
	fx.pop_look = &"ma_mark_glint"
	fx.data["pop_h"] = mh
	fx.data["land"] = land
	if fx.has_target:
		fx.ext_end = _mark_end
	if has_c:
		var q := _quiver(fx.caster, fx.tpos)
		h._flare(fx, A_WORLD, q, h._hdr(GLOW, 2.2), 0.6, 1.2, 0.1, maxf(rel - 0.14, 0.0), rel + 0.12, 0.05, 0.1, 0.8, 4.0)
		var dart := h._piece(fx, &"ma_bolt", A_TARGET, Vector3.UP * ht * 0.6, rel, land, 0.0, 0.0)
		h._mode(dart, &"home", {"from": q, "time": MARK_FLIGHT, "wave": 0.25, "ln": 0.9, "width": 0.26})
		h._params(dart, {&"style": float(B_DART), &"tint": h._hdr(GLOW, 2.2), &"seed": randf() * 10.0})
	var ph := randf() * TAU
	var glow := h._flare(fx, A_TARGET, Vector3.UP * mh, h._hdr(GLOW, 0.9), 1.3, 1.3, 0.0, land, 0.0, 0.1, 0.3, 0.3, 4.0,
			0.35)
	h._mode(glow, &"bob", {"ph": ph})
	var sig := h._piece(fx, &"ma_sigil", A_TARGET, Vector3.UP * mh, land, 0.0, 0.04, 0.3)
	if sig:
		sig.o0 = Vector3.UP * (mh + 0.45)   # it drops onto its place
	h._grow(sig, 0.3, 0.95, 0.25, true)
	h._mode(sig, &"bob", {"ph": ph})
	h._params(sig, {&"tint": h._hdr(GLOW, 2.0), &"seed": randf() * 6.0})
	var ring := r * 1.9 + 0.45
	_mdisc(fx, A_TARGET, Vector3.ZERO, M_GRAVE, h._hdr(GLOW, 1.3), ring * 1.5, ring, 0.2, land, 0.0, 0.1, 0.3)
	h._sched(fx, &"ma_mark_glint", land, A_TARGET, Vector3.UP * mh)
	h._sched(fx, &"ma_arrow_hit", land, A_TARGET, Vector3.UP * ht * 0.6, 0.8)
	h._flare(fx, A_TARGET, Vector3.UP * ht * 0.6, h._hdr(GLOW, 2.2), 0.8, 1.3, 0.1, land, land + 0.25, 0.0, 0.18, 0.8, 4.0)
	h._stream(fx, &"ma_mark_ash", land + 0.1, -0.3, A_TARGET, Vector3.UP * (mh - 0.15))


## The mark ended early: its unit died (or was freed) while marked -> the soul wisp flies back to a living caster.
func _mark_end(fx: ChampionVfx.Fx) -> void:
	if fx.t < float(fx.data.get("land", 0.0)) or h._alive(fx.target) or not h._alive(fx.caster):
		return
	if not fx.shown:
		return
	_reap(fx.caster, fx.tpos + Vector3.UP * h._h(fx.target) * 0.55)


func _reap(caster: Node3D, from: Vector3) -> void:
	var r := h._new_fx(&"grave_reap", caster, null, caster.global_position)
	var ch := h._h(caster)
	r.dur = REAP_FLIGHT + 0.7
	r.dep = 2
	r.vis = VIS_CASTER
	r.tail = 0.2
	r.data["arrow_pos"] = from
	var aim := Vector3.UP * ch * 0.6
	var wisp := h._flare(r, A_CASTER, aim, h._hdr(GLOW.lerp(HOT, 0.3), 2.4), 0.7, 0.7, 0.0, 0.0, REAP_FLIGHT, 0.05, 0.05,
			0.0, 4.0, 0.5)
	h._mode(wisp, &"home", {"from": from, "time": REAP_FLIGHT, "wave": 1.6, "ln": 0.02, "width": 0.75})
	h._sched(r, &"ma_mark_glint", 0.0, A_WORLD, from, 0.8)
	h._stream(r, &"ma_reap_trail", 0.0, REAP_FLIGHT + 0.02, A_ARROW, Vector3.ZERO)
	h._sched(r, &"ma_reap_heal", REAP_FLIGHT, A_CASTER, Vector3.UP * 0.2)
	h._flare(r, A_CASTER, aim, h._hdr(GLOW, 2.4), 1.2, 2.0, 0.15, REAP_FLIGHT, REAP_FLIGHT + 0.35, 0.0, 0.25, 1.0, 4.0)
	h._disc(r, A_CASTER, G_SHOCK, h._hdr(GLOW, 1.3), 0.3, h._r(caster) * 2.0 + 1.2, 0.3, REAP_FLIGHT,
			REAP_FLIGHT + 0.45, 0.0, 0.3)
	# Sable Shaft is ready again: a four-point glint at the bow.
	h._flare(r, A_CASTER, Vector3.UP * ch * 0.72 + h._facing(caster) * 0.35, h._hdr(GLOW.lerp(HOT, 0.5), 2.6), 0.5,
			1.1, 0.15, REAP_FLIGHT + 0.12, REAP_FLIGHT + 0.6, 0.0, 0.25, 1.6, 4.0)
	h._start(r)


## Eclipse Volley: the telegraph at once, the loose at VOLLEY_LOOSE, 3 waves at VOLLEY_WAVES.
func _eclipse_volley(fx: ChampionVfx.Fx) -> void:
	var has_c := is_instance_valid(fx.caster)
	var rr := VOLLEY_RADIUS
	var last: float = VOLLEY_WAVES[VOLLEY_WAVES.size() - 1]
	fx.dur = last + VOLLEY_LINGER
	fx.vis = VIS_POINT
	var dir := h._toward(fx.cpos, fx.point) if has_c else Vector3.ZERO
	if dir == Vector3.ZERO:
		dir = Vector3.FORWARD
	var tele := _mdisc(fx, A_POINT, Vector3.ZERO, M_ECLIPSE, h._hdr(GLOW, 1.5), rr * 0.8, rr, 0.25, 0.0, last + 0.12,
			0.08, 0.25)
	h._params(tele, {&"warn": VOLLEY_WAVES[0]})
	h._disc(fx, A_POINT, G_SHOCK, h._hdr(GLOW, 1.2), 0.5, rr + 0.3, 0.3, 0.0, 0.45, 0.0, 0.3)
	if has_c:
		var rel := VOLLEY_LOOSE
		fx.data["rel"] = rel
		fx.data["arrow_pos"] = h._hand(fx.caster, fx.point)
		fx.ext = _track_bow
		h._flare(fx, A_ARROW, Vector3.ZERO, h._hdr(GLOW, 2.2), 0.3, 1.0, rel, 0.0, rel + 0.06, 0.1, 0.06, 0.8, 4.0, 0.5)
		h._flare(fx, A_ARROW, Vector3.ZERO, h._hdr(GLOW.lerp(HOT, 0.4), 2.6), 1.0, 1.8, 0.08, rel, rel + 0.25, 0.0, 0.18,
				1.2, 4.0)
		h._sched(fx, &"ma_volley_up", rel, A_ARROW, Vector3.ZERO)
	var sky := Vector3.UP * VOLLEY_HEIGHT - dir * VOLLEY_HEIGHT * VOLLEY_SLANT
	for i in VOLLEY_WAVES.size():
		var t: float = VOLLEY_WAVES[i]
		h._sched(fx, &"ma_volley_rain", t - VOLLEY_FALL, A_POINT, sky, 1.0, dir)
		h._sched(fx, &"ma_volley_hit", t, A_POINT, Vector3.UP * 0.1)
		h._sched(fx, &"ma_volley_dust", t + 0.02, A_POINT, Vector3.UP * 0.2)
		h._disc(fx, A_POINT, G_SHOCK, h._hdr(GLOW, 1.1 + 0.25 * float(i)), rr * 0.5, rr + 0.4, 0.25, t, t + 0.4, 0.0, 0.3)
		var stuck := h._piece(fx, &"ma_stuck", A_POINT, Vector3.ZERO, t, 0.0, 0.0, 0.7)
		if stuck:
			stuck.rot = Basis(Vector3.UP, randf() * TAU)
		h._params(stuck, {&"tint": h._hdr(GLOW, 1.6), &"seed": randf() * 10.0})
	_mdisc(fx, A_POINT, Vector3.ZERO, M_VOLLEY, h._hdr(GLOW, 1.2), rr, rr, 0.0, VOLLEY_WAVES[0], 0.0, 0.1, 0.8)


## The bow's arrow head until the loose (anchor A_ARROW of the charge / loose pieces).
func _track_bow(fx: ChampionVfx.Fx, _delta: float) -> void:
	if fx.t < float(fx.data["rel"]) and h._in_tree(fx.caster):
		fx.data["arrow_pos"] = h._hand(fx.caster, fx.point)


## The call ritual under her as she rises (the model's play_call, 2.0 s; peak at 1.5 s).
func _unique_call(fx: ChampionVfx.Fx) -> void:
	var has_c := is_instance_valid(fx.caster)
	if has_c:
		fx.point = fx.cpos
	fx.vis = VIS_POINT
	fx.dur = CALL_LEN + 0.9
	var rr := CALL_RADIUS
	_mdisc(fx, A_POINT, Vector3.ZERO, M_CALL, h._hdr(GLOW, 1.5), rr * 0.85, rr, 0.5, 0.0, 0.0, 0.08, 0.7)
	h._disc(fx, A_POINT, G_SHOCK, h._hdr(GLOW, 1.0), 0.4, rr + 0.6, 0.35, 0.05, 0.5, 0.0, 0.3)
	h._sched(fx, &"ma_call_smoke", 0.05, A_POINT, Vector3.UP * 0.15)
	var col := h._piece(fx, &"ma_column", A_POINT, Vector3.UP * COLUMN_HEIGHT * 0.5, 0.1, CALL_LEN + 0.45, 0.1, 0.6)
	if col:
		col.o0 = Vector3.ZERO           # the foot stays on the ground while it rises
	h._grow(col, Vector3(rr * 0.55, 0.05, rr * 0.55), Vector3(rr * 0.42, COLUMN_HEIGHT, rr * 0.42), 0.7)
	h._params(col, {&"style": 0.0, &"tint": h._hdr(GLOW, 1.1), &"seed": randf() * 10.0})
	var core := h._piece(fx, &"ma_column", A_POINT, Vector3.UP * COLUMN_HEIGHT * 0.6, 0.25, CALL_LEN + 0.25, 0.1, 0.5)
	if core:
		core.o0 = Vector3.ZERO
	h._grow(core, Vector3(0.25, 0.05, 0.25), Vector3(0.5, COLUMN_HEIGHT * 1.2, 0.5), 0.6)
	h._params(core, {&"style": 0.0, &"tint": h._hdr(GLOW.lerp(HOT, 0.2), 0.8), &"seed": randf() * 10.0})
	h._stream(fx, &"ma_call_motes", 0.1, CALL_LEN, A_POINT, Vector3.UP * 0.1)
	# The peak: she lifts the bow over her head.
	var f := CALL_FLASH
	var ch := h._h(fx.caster) if has_c else 2.0
	h._disc(fx, A_POINT, G_SHOCK, h._hdr(GLOW, 1.8), 0.6, rr + 2.2, 0.45, f, f + 0.6, 0.0, 0.35)
	h._flare(fx, A_POINT, Vector3.UP * (ch + 0.7), h._hdr(GLOW.lerp(HOT, 0.3), 2.2), 1.2, 2.4, 0.15, f, f + 0.45, 0.0,
			0.3, 1.4, 6.0)
	h._sched(fx, &"ma_call_flash", f, A_POINT, Vector3.UP * 1.6)
	h._sched(fx, &"ma_revive_motes", f + 0.05, A_POINT, Vector3.UP * 0.2, 1.3)
	var belt := h._piece(fx, &"ma_column", A_POINT, Vector3.UP * 1.4, f, f + 0.55, 0.0, 0.4)
	h._grow(belt, Vector3(rr * 0.45, 1.6, rr * 0.45), Vector3(rr * 1.1, 2.4, rr * 1.1), 0.45)
	h._params(belt, {&"style": 2.0, &"tint": h._hdr(GLOW, 1.2), &"seed": randf() * 10.0})


## The revive: a pillar driven down from the sky onto her.
func _unique_revive(fx: ChampionVfx.Fx) -> void:
	var has_c := is_instance_valid(fx.caster)
	if has_c:
		fx.point = fx.cpos
	fx.vis = VIS_POINT
	fx.dur = REVIVE_TIME
	var land := REVIVE_LAND
	var rr := REVIVE_RADIUS
	var ch := h._h(fx.caster) if has_c else 2.0
	var pillar := h._piece(fx, &"ma_column", A_POINT, Vector3.UP * PILLAR_HEIGHT * 0.5, 0.0, land + 0.9, 0.0, 0.55)
	h._grow(pillar, Vector3(0.75, PILLAR_HEIGHT, 0.75), Vector3(0.75, PILLAR_HEIGHT, 0.75), 0.0)
	h._params(pillar, {&"style": 1.0, &"tint": h._hdr(GLOW, 1.5), &"seed": randf() * 10.0})
	var body := Vector3(0.9, ch * 0.6 + 0.1, 0.9)
	var sh := h._piece(fx, &"shell", A_POINT, Vector3.UP * ch * 0.5, land, land + 1.0, 0.05, 0.45)
	h._grow(sh, body * Vector3(1.5, 1.2, 1.5), body, 0.35)
	h._params(sh, {&"style": 1.0, &"tint": h._hdr(GLOW, 1.4), &"seed": randf()})
	_mdisc(fx, A_POINT, Vector3.ZERO, M_REVIVE, h._hdr(GLOW, 1.5), rr * 0.5, rr, 0.25, land, 0.0, 0.03, 0.5)
	h._disc(fx, A_POINT, G_SHOCK, h._hdr(GLOW, 1.7), 0.4, rr + 1.6, 0.35, land, land + 0.5, 0.0, 0.3)
	h._flare(fx, A_POINT, Vector3.UP * ch * 0.5, h._hdr(GLOW.lerp(HOT, 0.3), 2.2), 1.4, 2.4, 0.12, land, land + 0.4, 0.0,
			0.3, 1.3, 4.0)
	h._sched(fx, &"ma_revive_hit", land, A_POINT, Vector3.UP * 0.2)
	h._sched(fx, &"ma_revive_motes", land + 0.05, A_POINT, Vector3.UP * 0.2)
	h._sched(fx, &"ma_call_smoke", land, A_POINT, Vector3.UP * 0.1, 0.7)


# ---------------------------------------------------------------- helpers

## Ground mark (champion_mage_archer_ground.gdshader) growing from radius r0 to r1; `ofs` from the anchor.
func _mdisc(fx: ChampionVfx.Fx, at: int, ofs: Vector3, pattern: int, tint: Color, r0: float, r1: float, grow: float,
		on: float, off: float, fin: float, fout: float) -> ChampionVfx.Piece:
	_layer = (_layer + 1) % 6
	var d := h._piece(fx, &"ma_ground", at, ofs + Vector3.UP * (0.052 + 0.007 * float(_layer)), on, off, fin, fout)
	h._grow(d, Vector3(r0, 1.0, r0), Vector3(r1, 1.0, r1), grow, false)
	h._params(d, {&"pattern": float(pattern), &"tint": tint, &"seed": randf() * 10.0})
	return d


## The Sable Shaft scar from `from` to `to` (ground points), `half_w` metres each side.
func _rift(fx: ChampionVfx.Fx, from: Vector3, to: Vector3, half_w: float, on: float, off: float, fin: float,
		fout: float) -> ChampionVfx.Piece:
	var mid := (from + to) * 0.5
	var half_l := Vector2(to.x - from.x, to.z - from.z).length() * 0.5
	var d := _mdisc(fx, A_WORLD, Vector3(mid.x, from.y, mid.z), M_RIFT, h._hdr(GLOW, 1.6), half_w, half_w, 0.0, on, off,
			fin, fout)
	if d:
		d.s0 = Vector3(half_w, 1.0, half_l)
		d.s1 = d.s0
		d.rot = h._yaw_basis(to - from)
		h._params(d, {&"length_m": half_l})
	return d


## Her rune quiver's centre (the model's get_quiver_origin), else the bow.
func _quiver(c: Node3D, toward: Vector3) -> Vector3:
	var model: Variant = c.call(&"get_model") if c.has_method(&"get_model") else null
	if is_instance_valid(model) and (model as Object).has_method(&"get_quiver_origin"):
		return (model as Object).call(&"get_quiver_origin")
	return h._hand(c, toward)


## 16 arrows standing in the ground over the r 4 circle (two crossed quads each, heads down), built once.
func _stuck_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1308
	for i in STUCK_ARROWS:
		var rr := VOLLEY_RADIUS * 0.9 * sqrt((float(i) + 0.5) / float(STUCK_ARROWS)) + rng.randf_range(-0.2, 0.2)
		var a := float(i) * 2.39996 + rng.randf_range(-0.3, 0.3)
		var base := Vector3(cos(a) * rr, 0.0, sin(a) * rr)
		var lean := Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0))
		if lean.length() < 0.1:
			lean = Vector3.RIGHT
		var tilt := Basis(lean.normalized(), deg_to_rad(rng.randf_range(6.0, 24.0)))
		var up := tilt * Vector3.UP
		var length := rng.randf_range(0.72, 0.95)
		var bottom := base - up * 0.1
		var top := base + up * length
		var rnd := rng.randf()
		var spin := rng.randf() * PI
		for k in 2:
			var side := tilt * Vector3(cos(spin + float(k) * PI * 0.5), 0.0, sin(spin + float(k) * PI * 0.5))
			var w := side * 0.085
			var col := Color(rnd, 0.0, 0.0)
			var quad := [[bottom - w, Vector2(0.0, 0.0)], [bottom + w, Vector2(1.0, 0.0)], [top + w, Vector2(1.0, 1.0)],
					[top - w, Vector2(0.0, 1.0)]]
			for idx: int in [0, 1, 2, 0, 2, 3]:
				st.set_color(col)
				st.set_uv(quad[idx][1])
				st.set_normal(Vector3.UP)
				st.add_vertex(quad[idx][0])
	return st.commit()


# ---------------------------------------------------------------- particle looks

## Fills the process material of one of these looks (called from ChampionVfx._pmat).
func pmat(m: ParticleProcessMaterial, key: StringName) -> void:
	var v_hot := h._hdr(HOT, 2.6)
	var v := h._hdr(GLOW, 2.2)
	var v_end := h._hdr(DEEP, 1.0, 0.0)
	var sable := SABLE.srgb_to_linear()
	match key:
		&"ma_arrow_hit", &"ma_shaft_hit":
			var shaft := key == &"ma_shaft_hit"
			h._shape_sphere(m, 0.12 if not shaft else 0.2)
			m.direction = Vector3(0.0, 0.2, -1.0)
			m.spread = 70.0 if not shaft else 50.0
			m.initial_velocity_min = 3.0 if not shaft else 5.0
			m.initial_velocity_max = 7.0 if not shaft else 11.0
			m.gravity = Vector3(0, -8.0, 0)
			m.damping_min = 5.0
			m.damping_max = 7.0
			m.particle_flag_align_y = true
			h._size(m, 0.05 if not shaft else 0.06, 0.08 if not shaft else 0.1, &"shrink")
			m.color_ramp = h._ramp([v_hot, v_hot, v, v_end])
		&"ma_gather":
			h._shape_sphere(m, 1.15)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 0.0
			m.initial_velocity_max = 0.2
			m.radial_velocity_min = -2.6
			m.radial_velocity_max = -1.9
			m.tangential_accel_min = 2.0
			m.tangential_accel_max = 4.0
			h._size(m, 0.08, 0.15, &"shrink")
			m.color_ramp = h._ramp([Color(v, 0.0), v, v_hot])
		&"ma_bow_flash":
			h._shape_sphere(m, 0.08)
			m.direction = Vector3(0.0, 0.0, -1.0)
			m.spread = 22.0
			m.initial_velocity_min = 6.0
			m.initial_velocity_max = 12.0
			m.damping_min = 8.0
			m.damping_max = 12.0
			m.particle_flag_align_y = true
			h._size(m, 0.05, 0.08, &"shrink")
			m.color_ramp = h._ramp([v_hot, v, v_end])
		&"ma_shaft_puff", &"ma_shaft_smoke":
			var trail := key == &"ma_shaft_smoke"
			h._shape_sphere(m, 0.3 if not trail else 0.18)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 0.4 if not trail else 0.15
			m.initial_velocity_max = 1.4 if not trail else 0.5
			m.damping_min = 2.0
			m.damping_max = 3.0
			m.gravity = Vector3(0, 0.3, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			h._size(m, 0.45 if not trail else 0.3, 0.8 if not trail else 0.55, &"grow")
			m.color_initial_ramp = h._ramp([sable, h._hdr(DEEP, 0.35), sable])
			m.color_ramp = h._ramp([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.7), Color(1, 1, 1, 0.0)])
		&"ma_mark_glint":
			h._shape_sphere(m, 0.2)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 0.6
			m.initial_velocity_max = 1.8
			m.damping_min = 2.0
			m.damping_max = 3.0
			h._size(m, 0.14, 0.24, &"pop")
			m.color_ramp = h._ramp([v_hot, v, v_end])
		&"ma_reap_heal", &"ma_revive_motes":
			var revive := key == &"ma_revive_motes"
			h._shape_ring(m, 0.5 if not revive else 0.9, 0.1)
			m.direction = Vector3.UP
			m.spread = 15.0 if not revive else 10.0
			m.initial_velocity_min = 1.2
			m.initial_velocity_max = 2.4 if not revive else 2.8
			m.tangential_accel_min = 0.0 if not revive else 2.0
			m.tangential_accel_max = 0.0 if not revive else 4.0
			m.damping_min = 0.8
			m.damping_max = 1.2
			h._size(m, 0.12, 0.2, &"grow")
			m.color_ramp = h._ramp([Color(v, 0.0), v_hot, v, v_end])
		&"ma_volley_up", &"ma_volley_rain":
			var rain := key == &"ma_volley_rain"
			if rain:
				h._shape_disc(m, VOLLEY_RADIUS * 0.95)
				m.direction = Vector3(0.0, -1.0, -VOLLEY_SLANT).normalized()
				m.spread = 3.0
				var sp := Vector3(VOLLEY_HEIGHT * VOLLEY_SLANT, VOLLEY_HEIGHT, 0.0).length() / VOLLEY_FALL
				m.initial_velocity_min = sp * 0.96
				m.initial_velocity_max = sp * 1.04
				m.color_ramp = h._ramp_at([0.0, 0.1, 0.85, 1.0], [Color(v, 0.0), v, v, Color(v, 0.0)])
			else:
				h._shape_sphere(m, 0.2)
				m.direction = Vector3.UP
				m.spread = 16.0
				m.initial_velocity_min = 20.0
				m.initial_velocity_max = 26.0
				m.color_ramp = h._ramp_at([0.0, 0.7, 1.0], [v_hot, v, Color(v, 0.0)])
			m.particle_flag_align_y = true
			h._size(m, 0.13, 0.17, &"hold")
		&"ma_volley_hit", &"ma_call_flash", &"ma_revive_hit":
			match key:
				&"ma_volley_hit":
					h._shape_disc(m, VOLLEY_RADIUS * 0.95)
					m.spread = 50.0
					m.initial_velocity_min = 2.0
					m.initial_velocity_max = 5.0
					m.gravity = Vector3(0, -10.0, 0)
					m.damping_min = 3.0
					m.damping_max = 4.0
					h._size(m, 0.05, 0.08, &"shrink")
				_:
					var call := key == &"ma_call_flash"
					h._shape_ring(m, 0.5, 0.1)
					m.spread = 40.0
					m.initial_velocity_min = 2.0
					m.initial_velocity_max = 5.0
					m.radial_velocity_min = 7.0 if call else 5.0
					m.radial_velocity_max = 12.0 if call else 9.0
					m.gravity = Vector3(0, -6.0, 0)
					m.damping_min = 2.0
					m.damping_max = 3.0
					h._size(m, 0.07, 0.11, &"shrink")
			m.direction = Vector3.UP
			m.particle_flag_align_y = true
			m.color_ramp = h._ramp([v_hot, v_hot, v, v_end])
		&"ma_volley_dust", &"ma_call_smoke":
			var call := key == &"ma_call_smoke"
			if call:
				h._shape_ring(m, 1.4, 0.1)
				m.emission_ring_inner_radius = 0.6
				m.radial_velocity_min = 1.2
				m.radial_velocity_max = 2.2
			else:
				h._shape_disc(m, VOLLEY_RADIUS * 0.9)
			m.direction = Vector3.UP
			m.spread = 35.0
			m.initial_velocity_min = 0.4
			m.initial_velocity_max = 1.0
			m.damping_min = 1.2
			m.damping_max = 2.0
			m.gravity = Vector3(0, 0.2, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			h._size(m, 0.9 if call else 0.6, 1.5 if call else 1.0, &"grow")
			if call:
				m.color_initial_ramp = h._ramp([sable, h._hdr(DEEP, 0.4), h._hdr(SABLE, 1.3)])
			else:
				m.color_initial_ramp = h._ramp(h._lin([DUST, DUST.lerp(SABLE, 0.4), DUST.lightened(0.15)]))
			m.color_ramp = h._ramp([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.6 if call else 0.45), Color(1, 1, 1, 0.0)])
		&"ma_arrow_trail", &"ma_shaft_sparks", &"ma_reap_trail":
			h._shape_sphere(m, 0.05 if key == &"ma_arrow_trail" else 0.15)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 0.1
			m.initial_velocity_max = 0.5 if key == &"ma_arrow_trail" else 1.1
			match key:
				&"ma_arrow_trail":
					h._size(m, 0.08, 0.15, &"shrink")
				&"ma_shaft_sparks":
					h._size(m, 0.12, 0.22, &"shrink")
				_:
					h._size(m, 0.16, 0.26, &"shrink")
			m.color_ramp = h._ramp([v_hot, v, v_end])
		&"ma_mark_ash":
			h._shape_ring(m, 0.35, 0.1)
			m.direction = Vector3.DOWN
			m.spread = 25.0
			m.initial_velocity_min = 0.2
			m.initial_velocity_max = 0.5
			m.gravity = Vector3(0, -0.5, 0)
			m.damping_min = 0.3
			m.damping_max = 0.5
			h._size(m, 0.06, 0.11, &"grow")
			m.color_ramp = h._ramp([Color(v, 0.0), v_hot, v, v_end])
		&"ma_call_motes":
			h._shape_disc(m, CALL_RADIUS * 0.85)
			m.direction = Vector3.UP
			m.spread = 6.0
			m.initial_velocity_min = 2.5
			m.initial_velocity_max = 5.0
			m.tangential_accel_min = 1.5
			m.tangential_accel_max = 3.0
			m.radial_accel_min = -1.2
			m.radial_accel_max = -0.6
			m.damping_min = 0.3
			m.damping_max = 0.5
			h._size(m, 0.08, 0.14, &"grow")
			m.color_ramp = h._ramp([Color(v, 0.0), v_hot, v, v_end])
