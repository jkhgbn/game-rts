class_name TradeVfx
extends Node3D
## Trade effects (task 10.V11, docs/design/market-trade.md sections 4-6 and 9). Add ONE of these to a level, next to
## SpellVfx / CombatVfx / ChampionVfx; it never edits gameplay code. It is in group "trade_vfx"; callers do
##   var vfx := get_tree().get_first_node_in_group(&"trade_vfx")
##   if vfx: vfx.play(id, at, target)
## `at` is a world point (Vector3; a Node3D is accepted too and read once), `target` an optional Node3D (null ok).
## Unknown ids are ignored.
##   delivery     gold motes rise 1.5 m in 0.6 s over `at` (the Bazaar drop point), coins hop, a gold ring.
##                target = the caravan (only used for its team / fog).
##   post_trade   a puff of road dust at `at` (the post door) and 3 coins arcing from the door onto `target` (the
##                caravan: its cargo is loaded). No target: the coins land 1.7 m beside the door.
##   snatch       a trail of coins (0.4 s) from `at` (the robbed caravan) to `target` (the Magpie), gold sparks at
##                the caravan, a glint on the thief. The thief may keep running: the coins follow it.
##   smoke        a grey-blue smoke puff filling r 3 for 1.2 s at `at` (a fleeing Magpie); MIX blend, soot smudge.
##   sack_pickup  a gold sparkle on the sack at `at`; with a `target` (the unit that took it) 3 coins hop to it.
##   snare        rope coils bind `target`'s feet for 0.5 s (a tracker's snare arrow; ends early when the unit
##                reports that `rooted` is over, e.g. the halved root on a hero, or when it dies).
##   ware_bought  a gold ring pulse on the Bazaar (`at` = its centre, `target` = the Bazaar): two shock rings to
##                ~its footprint + 1.5 m, a riveted gold ward ring, sparks, rising motes and a flash over its roof.
## Fog: effects of the local team always show; others only where the local team sees (`FogOfWar.is_visible`), and
## `snare` only while its unit is visible. Checked 4 times per second.
## Budget: everything is pre-built at _ready and pooled (ground discs, glows, coins, one-shot bursts restarted). One
## material per shader, looks set with instance uniforms: no material, mesh or node is created after _ready. No
## lights, no shadows. Every particle quad has a shape mask and `billboard_keep_scale` (no white squares).
## Shaders reused from ChampionVfx (read only): champion_ground (rings, soot, rope coils), champion_flare (glows),
## champion_coin (spinning gold coins), combat_streak (sparks).

const GROUP := &"trade_vfx"
const EFFECTS: Array[StringName] = [&"delivery", &"post_trade", &"snatch", &"smoke", &"sack_pickup", &"snare",
		&"ware_bought"]

# Palette (market-trade.md 2.5 / 9): gold of the loot sack and the route line, road dust, Magpie smoke.
const GOLD := Color(1.0, 0.85, 0.3)
const GOLD_HOT := Color(1.0, 0.95, 0.65)
const BRASS := Color(0.70, 0.55, 0.25)
const AMBER := Color(1.0, 0.8, 0.4)            # tracker arrow tip
const DUST := Color(0.55, 0.45, 0.30)          # road paint
const SMOKE := Color(0.50, 0.56, 0.66)         # grey-blue
const SMOKE_DARK := Color(0.30, 0.34, 0.42)
const MAGPIE_TEAL := Color(0.35, 0.95, 0.85)   # iridescent trim of the Magpie cloak

# Numbers from market-trade.md 9.
const DELIVERY_TIME := 0.6
const DELIVERY_RISE := 1.5
const SNATCH_TIME := 0.4
const SMOKE_RADIUS := 3.0
const SMOKE_TIME := 1.2
const SNARE_TIME := 0.5
const POST_COINS := 3
const SNATCH_COINS := 7

const END_FADE := 0.2           # fade when the unit an effect sits on dies
const CHECK_INTERVAL := 0.25    # fog / status checks per effect
const STATUS_GRACE := 0.15      # the root may be applied just after play()
const FOG_RESCAN := 1.0

enum { A_POINT, A_TARGET, A_WORLD }
enum { VIS_POINT, VIS_TARGET }
enum { G_SHOCK, G_WIND, G_HEAL, G_ROPE, G_GLOW, G_SOOT, G_WARD }   # champion_ground.gdshader patterns

## Mesh pools (pre-built): pool -> size.
const POOL_SIZES := {&"disc": 16, &"flare": 36, &"coin": 30}
## One-shot bursts: look -> [amount, lifetime, draw pass, pool size, explosiveness].
const BURSTS := {
	&"rise_motes": [16, 0.6, &"add_star", 4, 0.8],
	&"rise_dots": [14, 0.6, &"add_dot", 4, 0.75],
	&"coin_hop": [7, 0.65, &"mix_coin", 4, 0.95],
	&"trade_dust": [14, 0.9, &"mix_dot", 4, 0.9],
	&"gold_sparks": [16, 0.45, &"streak", 4, 1.0],
	&"coin_glint": [10, 0.6, &"add_star", 8, 0.9],
	&"smoke_puff": [24, 1.2, &"mix_smoke", 5, 0.9],
	&"smoke_pop": [12, 0.55, &"mix_smoke", 5, 1.0],
	&"teal_glint": [6, 0.5, &"add_star", 5, 1.0],
	&"sack_sparkle": [18, 0.7, &"add_star", 4, 0.85],
	&"rope_dust": [8, 0.5, &"mix_dot", 4, 0.9],
	&"ware_motes": [28, 1.2, &"add_star", 2, 0.7],
	&"ware_sparks": [30, 0.7, &"streak", 2, 0.95],
}

const GROUND_SHADER := preload("res://art/vfx/champion_ground.gdshader")
const FLARE_SHADER := preload("res://art/vfx/champion_flare.gdshader")
const COIN_SHADER := preload("res://art/vfx/champion_coin.gdshader")
const STREAK_SHADER := preload("res://art/vfx/combat_streak.gdshader")


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
	var dep := false              # ends (fade) when the target dies
	var vis := 0                  # VIS_POINT / VIS_TARGET
	var status := &""             # status on the target that this effect shows
	var end_at := -1.0
	var shown := true
	var check_left := 0.0
	var pieces: Array[Piece] = []
	var bursts: Array[Dictionary] = []
	var bursts_left := 0


## One pooled mesh of an effect: when it shows (on / off, off <= 0 = relative to the effect's end), where (anchor +
## offset lerped from o0 while growing), how it grows (s0 -> s1 over `grow`), how it fades. Mode "toss": flies from
## (from_at anchor + from_ofs) to (at anchor + ofs) in `time` s on an arc `apex` m high, then hides.
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
	var toss := false
	var from_at := 0
	var from_ofs := Vector3.ZERO
	var time := 0.3
	var apex := 1.0
	var lf := -1.0                # last fade sent
	var lr := -1.0                # last radius sent


var _fx: Array[Fx] = []
var _free: Dictionary = {}          # pool -> Array[GeometryInstance3D]
var _all: Dictionary = {}           # pool -> Array[GeometryInstance3D]
var _bursts: Dictionary = {}        # look -> Array[GPUParticles3D]
var _burst_next: Dictionary = {}
var _live_bursts: Array[Dictionary] = []   # {p, left}
var _pmats: Dictionary = {}
var _passes: Dictionary = {}
var _fog: Node
var _fog_left := 0.0
var _layer := 0


func _ready() -> void:
	add_to_group(GROUP)
	top_level = true                  # effects are placed in world space
	global_transform = Transform3D.IDENTITY
	_build_shared()


func _process(delta: float) -> void:
	_fog_left -= delta
	if _fog_left <= 0.0:
		_fog_left = FOG_RESCAN
		_fog = get_tree().get_first_node_in_group(&"fog")
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


# ---------------------------------------------------------------- public API

## Plays effect `id` (market-trade.md 9) at the world point `at` (Vector3, or a Node3D read once), on the optional
## `target` (Node3D or null). See the header for what each id expects.
func play(id: StringName, at: Variant, target: Variant = null) -> void:
	if not is_node_ready() or not is_inside_tree() or not EFFECTS.has(id):
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
	var fx := Fx.new()
	fx.id = id
	fx.target = t
	fx.has_target = t != null
	fx.point = point
	fx.tpos = t.global_position if t else point
	if t:
		var team: Variant = t.get(&"team")
		fx.team = int(team) if team != null else -1
	match id:
		&"delivery": _delivery(fx)
		&"post_trade": _post_trade(fx)
		&"snatch": _snatch(fx)
		&"smoke": _smoke(fx)
		&"sack_pickup": _sack_pickup(fx)
		&"snare": _snare(fx)
		&"ware_bought": _ware_bought(fx)
	_start(fx)


## Number of running effects.
func active_count() -> int:
	return _fx.size()


## Ids of the running effects.
func active_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for fx in _fx:
		out.append(fx.id)
	return out


## Pooled pieces still on screen + bursts still alive (0 once everything has ended).
func live_count() -> int:
	var n := _live_bursts.size()
	for pool: StringName in _all:
		for g: GeometryInstance3D in _all[pool]:
			if g.visible:
				n += 1
	return n


# ---------------------------------------------------------------- the 7 effects

func _delivery(fx: Fx) -> void:
	var up := Vector3.UP
	fx.dur = DELIVERY_TIME
	_sched(fx, &"rise_motes", 0.0, A_POINT, up * 0.25)
	_sched(fx, &"rise_dots", 0.0, A_POINT, up * 0.2)
	_sched(fx, &"coin_hop", 0.0, A_POINT, up * 0.55)
	_disc(fx, A_POINT, G_SHOCK, _hdr(GOLD, 1.4), 0.3, 1.7, 0.4, 0.0, 0.5, 0.0, 0.3)
	_flare(fx, A_POINT, up * 0.8, _hdr(GOLD, 2.0), 0.8, 1.3, 0.16, 0.0, 0.3, 0.0, 0.2, 0.9, 4.0)
	# A bright glint leading the motes up 1.5 m.
	var lead := _flare(fx, A_POINT, up * (0.3 + DELIVERY_RISE), _hdr(GOLD_HOT, 2.2), 0.55, 0.35, DELIVERY_TIME, 0.0,
			DELIVERY_TIME, 0.05, 0.22, 0.6, 4.0)
	if lead:
		lead.o0 = up * 0.3


func _post_trade(fx: Fx) -> void:
	var up := Vector3.UP
	fx.dur = 0.9
	_sched(fx, &"trade_dust", 0.0, A_POINT, up * 0.15)
	_disc(fx, A_POINT, G_SOOT, DUST.srgb_to_linear(), 0.7, 1.9, 0.45, 0.0, 0.9, 0.0, 0.5)
	_disc(fx, A_POINT, G_SHOCK, _hdr(GOLD, 1.1), 0.4, 1.5, 0.35, 0.05, 0.45, 0.0, 0.25)
	var h := _h(fx.target) * 0.75 if fx.has_target else 1.1
	var land := up * h if fx.has_target else Vector3(1.2, 0.35, 1.2)
	var flight := 0.38
	for i in POST_COINS:
		var on := 0.06 + float(i) * 0.1
		var side := Vector3(0.12 * float(i - 1), 0.0, -0.08 * float(i - 1))
		_coin_toss(fx, A_POINT, up * 1.25 + side, A_TARGET, land + side * 0.5, on, flight, 1.0 + 0.15 * float(i),
				0.13, 16.0)
	_sched(fx, &"coin_glint", 0.06 + float(POST_COINS - 1) * 0.1 + flight, A_TARGET, land)


func _snatch(fx: Fx) -> void:
	var up := Vector3.UP
	fx.dur = SNATCH_TIME + 0.05
	var from := up * 1.1                      # the caravan's strongbox
	var th := _h(fx.target) * 0.6 if fx.has_target else 0.9
	var land := up * th if fx.has_target else Vector3(1.8, 0.9, 0.0)
	var flight := 0.22
	var step := (SNATCH_TIME - flight) / float(SNATCH_COINS - 1)
	for i in SNATCH_COINS:
		var j := float(i)
		var wob := Vector3(sin(j * 2.3) * 0.18, cos(j * 1.7) * 0.1, cos(j * 2.9) * 0.18)
		_coin_toss(fx, A_POINT, from + wob, A_TARGET, land + wob * 0.4, j * step, flight, 0.55 + 0.18 * fmod(j, 3.0),
				0.1 + 0.015 * fmod(j, 2.0), 22.0)
	_sched(fx, &"gold_sparks", 0.0, A_POINT, from)
	_sched(fx, &"coin_glint", flight + 0.02, A_TARGET, land)
	_flare(fx, A_POINT, from, _hdr(GOLD, 2.4), 0.9, 1.4, 0.12, 0.0, 0.28, 0.0, 0.18, 1.0, 4.0)
	_flare(fx, A_TARGET, land, _hdr(GOLD, 2.0), 0.5, 0.9, 0.2, flight, 0.0, 0.03, 0.15)


func _smoke(fx: Fx) -> void:
	var up := Vector3.UP
	fx.dur = SMOKE_TIME
	_sched(fx, &"smoke_pop", 0.0, A_POINT, up * 1.0)
	_sched(fx, &"smoke_puff", 0.02, A_POINT, up * 1.3)
	_sched(fx, &"teal_glint", 0.0, A_POINT, up * 1.0)
	_disc(fx, A_POINT, G_SOOT, SMOKE_DARK.srgb_to_linear(), 1.0, SMOKE_RADIUS * 1.02, 0.35, 0.0, SMOKE_TIME, 0.05,
			0.55)
	_flare(fx, A_POINT, up * 0.9, _hdr(Color(0.85, 0.92, 1.0), 1.3), 0.9, 1.9, 0.12, 0.0, 0.18, 0.0, 0.12)


func _sack_pickup(fx: Fx) -> void:
	var up := Vector3.UP
	fx.dur = 0.6
	_sched(fx, &"sack_sparkle", 0.0, A_POINT, up * 0.35)
	_flare(fx, A_POINT, up * 0.4, _hdr(GOLD, 2.0), 0.5, 1.0, 0.15, 0.0, 0.28, 0.0, 0.18, 1.1, 4.0)
	_disc(fx, A_POINT, G_SHOCK, _hdr(GOLD, 1.1), 0.3, 1.4, 0.3, 0.0, 0.4, 0.0, 0.25)
	if not fx.has_target:
		return
	var land := up * _h(fx.target) * 0.6
	for i in 3:
		var side := Vector3(0.1 * float(i - 1), 0.0, 0.1 * float(1 - i))
		_coin_toss(fx, A_POINT, up * 0.45 + side, A_TARGET, land + side * 0.4, 0.04 + float(i) * 0.06, 0.28,
				0.7 + 0.12 * float(i), 0.11, 18.0)
	_sched(fx, &"coin_glint", 0.04 + 0.12 + 0.28, A_TARGET, land)


func _snare(fx: Fx) -> void:
	fx.dur = SNARE_TIME
	fx.dep = fx.has_target
	fx.vis = VIS_TARGET if fx.has_target else VIS_POINT
	fx.status = &"rooted"
	var rr := _r(fx.target) * 1.9 + 0.45
	_disc(fx, A_TARGET, G_ROPE, _hdr(AMBER, 0.8), rr * 1.6, rr, 0.12, 0.0, 0.0, 0.03, 0.15)
	_sched(fx, &"rope_dust", 0.0, A_TARGET, Vector3.UP * 0.1)
	_flare(fx, A_TARGET, Vector3.UP * 0.35, _hdr(AMBER, 2.2), 0.7, 1.1, 0.1, 0.0, 0.2, 0.0, 0.14, 0.8, 4.0)


func _ware_bought(fx: Fx) -> void:
	var up := Vector3.UP
	fx.dur = 1.3
	var big := clampf(_footprint(fx.target) + 1.5, 3.5, 6.5)
	var roof := _roof(fx.target)
	_disc(fx, A_POINT, G_SHOCK, _hdr(GOLD, 1.9), 1.0, big, 0.55, 0.0, 0.8, 0.0, 0.35)
	_disc(fx, A_POINT, G_SHOCK, _hdr(GOLD, 1.1), 0.8, big * 0.7, 0.55, 0.18, 0.95, 0.0, 0.35)
	_disc(fx, A_POINT, G_WARD, _hdr(GOLD, 1.2), big * 1.15, big * 0.85, 0.3, 0.05, 0.0, 0.1, 0.5)
	_sched(fx, &"ware_sparks", 0.0, A_POINT, up * 0.3)
	_sched(fx, &"ware_motes", 0.1, A_POINT, up * 0.2, big / 4.5)
	_flare(fx, A_POINT, up * roof, _hdr(GOLD, 2.6), 2.0, 3.2, 0.25, 0.0, 0.55, 0.0, 0.3, 1.2, 4.0)
	_flare(fx, A_POINT, up * 0.6, _hdr(GOLD_HOT, 1.6), 1.6, 2.6, 0.2, 0.0, 0.35, 0.0, 0.2)


## A spinning gold coin flying from one anchor to another on an arc, with a small glow riding along.
func _coin_toss(fx: Fx, from_at: int, from_ofs: Vector3, to_at: int, to_ofs: Vector3, on: float, flight: float,
		apex: float, size: float, spin: float) -> void:
	var coin := _piece(fx, &"coin", to_at, to_ofs, on, on + flight, 0.0, 0.0)
	if coin:
		_grow(coin, size, size, 0.0)
		_toss(coin, from_at, from_ofs, flight, apex)
		_params(coin, {&"spin": spin, &"energy": 1.7, &"phase": randf() * TAU})
	var glow := _piece(fx, &"flare", to_at, to_ofs, on, on + flight, 0.0, 0.0)
	if glow:
		_grow(glow, size * 4.5, size * 4.5, 0.0)
		_toss(glow, from_at, from_ofs, flight, apex)
		_params(glow, {&"tint": _hdr(GOLD, 1.6), &"rays": 0.0, &"spikes": 4.0, &"pulse": 0.0, &"seed": randf() * 10.0,
				&"halo": Color(0, 0, 0, 0)})


# ---------------------------------------------------------------- effect runtime

func _start(fx: Fx) -> void:
	_fx.append(fx)
	_refresh(fx)
	fx.check_left = CHECK_INTERVAL
	_tick(fx, 0.0)


## Advances one effect. Returns true when it is over.
func _tick(fx: Fx, delta: float) -> bool:
	fx.t += delta
	if fx.has_target and _in_tree(fx.target):
		fx.tpos = fx.target.global_position
	fx.check_left -= delta
	if fx.check_left <= 0.0:
		fx.check_left += CHECK_INTERVAL
		if fx.end_at < 0.0 and fx.dep and not _alive(fx.target):
			_end_early(fx)
		_refresh(fx)
	elif fx.end_at < 0.0 and fx.dep and not _in_tree(fx.target):
		_end_early(fx)   # freed / removed: at once
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
	if d.toss:
		var u := clampf(lt / d.time, 0.0, 1.0)
		var a := _anchor(fx, d.from_at) + d.from_ofs
		var e := u * u * (3.0 - 2.0 * u) * 0.35 + u * 0.65   # quick start, soft catch
		pos = a.lerp(pos, e) + Vector3.UP * d.apex * 4.0 * u * (1.0 - u)
	var xf := Transform3D(Basis.from_scale(s), pos)
	if not xf.is_equal_approx(n.transform):
		n.transform = xf
	# Only what changed goes to the RenderingServer.
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


func _end_early(fx: Fx) -> void:
	fx.end_at = fx.t + END_FADE


func _finish(fx: Fx) -> void:
	for d in fx.pieces:
		d.n.visible = false
		d.n.set_instance_shader_parameter(&"fade", 0.0)
		(_free[d.pool] as Array).append(d.n)
	fx.pieces.clear()


## Fog / hidden units (4 times per second) and the status the effect shows.
func _refresh(fx: Fx) -> void:
	if fx.vis == VIS_TARGET and fx.has_target and _in_tree(fx.target):
		fx.shown = fx.target.is_visible_in_tree()
	else:
		fx.shown = _fog_ok(fx.team, fx.point)
	if fx.status == &"" or fx.end_at >= 0.0 or fx.t < STATUS_GRACE or not fx.has_target or not _alive(fx.target):
		return
	var u := fx.target
	if u.has_method(&"has_status") and not bool(u.call(&"has_status", fx.status)):
		_end_early(fx)


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


func _toss(d: Piece, from_at: int, from_ofs: Vector3, time: float, apex: float) -> void:
	if d == null:
		return
	d.toss = true
	d.from_at = from_at
	d.from_ofs = from_ofs
	d.time = maxf(time, 0.01)
	d.apex = apex


func _params(d: Piece, params: Dictionary) -> void:
	if d == null:
		return
	for k: StringName in params:
		d.n.set_instance_shader_parameter(k, params[k])


## Ground mark (champion_ground.gdshader) growing from radius r0 to r1.
func _disc(fx: Fx, at: int, pattern: int, tint: Color, r0: float, r1: float, grow: float, on: float, off: float,
		fin: float, fout: float) -> Piece:
	_layer = (_layer + 1) % 8
	var d := _piece(fx, &"disc", at, Vector3.UP * (0.05 + 0.006 * float(_layer)), on, off, fin, fout)
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


## Half-width of a building (target_radius) or 3 m (a 6 x 6 Bazaar).
func _footprint(n: Variant) -> float:
	if is_instance_valid(n) and (n as Object).has_method(&"target_radius"):
		return clampf(float((n as Object).call(&"target_radius")), 1.0, 6.0)
	return 3.0


## Height of the flash over a building: 75 % of its BuildingType height, else 3.4 m (a 4.5 m Bazaar).
func _roof(n: Variant) -> float:
	if is_instance_valid(n):
		var bt: Variant = (n as Object).get(&"building_type")
		if bt is Object and is_instance_valid(bt):
			var h: Variant = (bt as Object).get(&"height")
			if h != null and float(h) > 0.5:
				return float(h) * 0.75
	return 3.4


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
	var coin := CylinderMesh.new()
	coin.top_radius = 1.0
	coin.bottom_radius = 1.0
	coin.height = 0.14
	coin.radial_segments = 16
	coin.rings = 1
	var meshes := {&"disc": plane, &"flare": quad, &"coin": coin}
	var mats := {&"disc": _shader_mat(GROUND_SHADER), &"flare": _shader_mat(FLARE_SHADER),
			&"coin": _shader_mat(COIN_SHADER)}
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
			if pool != &"disc":
				m.extra_cull_margin = 2.0   # billboards / the standing coin leave their mesh AABB
			if pool == &"coin":
				m.sorting_offset = 1.0      # drawn after its glow
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
	var big := look == &"smoke_puff" or look == &"ware_motes" or look == &"ware_sparks"
	p.visibility_aabb = AABB(Vector3(-8.0, -3.0, -8.0), Vector3(16.0, 11.0, 16.0)) if big \
			else AABB(Vector3(-4.0, -3.0, -4.0), Vector3(8.0, 8.0, 8.0))
	return p


## Draw passes: textured billboard quads (never a bare square: every one has a shape mask and keeps the particle
## scale, Godot 4.7) + velocity-aligned streaks (combat_streak.gdshader).
func _build_passes() -> void:
	_passes[&"add_dot"] = _particle_quad(_shape_tex(&"dot"), BaseMaterial3D.BLEND_MODE_ADD)
	_passes[&"mix_dot"] = _particle_quad(_shape_tex(&"dot"), BaseMaterial3D.BLEND_MODE_MIX)
	_passes[&"add_star"] = _particle_quad(_shape_tex(&"star"), BaseMaterial3D.BLEND_MODE_ADD)
	_passes[&"mix_coin"] = _particle_quad(_shape_tex(&"coin"), BaseMaterial3D.BLEND_MODE_MIX)
	_passes[&"mix_smoke"] = _particle_quad(_shape_tex(&"smoke"), BaseMaterial3D.BLEND_MODE_MIX)
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
	mat.disable_fog = blend == BaseMaterial3D.BLEND_MODE_ADD  # G-E 5: an additive quad must not fog
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.billboard_keep_scale = true   # Godot 4.7: without it the particle scale (scale_min/max, curve) is ignored
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = tex
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.disable_receive_shadows = true
	if blend == BaseMaterial3D.BLEND_MODE_MIX:
		# Big smoke / dust quads cut into the ground: soften the cut (no hard line where they meet it).
		mat.proximity_fade_enabled = true
		mat.proximity_fade_distance = 0.7
	var q := QuadMesh.new()
	q.size = Vector2.ONE   # 1 m: ParticleProcessMaterial scale_min / scale_max are the sizes in metres
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
					# Four-point sparkle: hot core + two thin rays, zero at the quad edge.
					var core := clampf(1.0 - r / 0.32, 0.0, 1.0)
					var ray := maxf(clampf(1.0 - absf(u) / 0.08, 0.0, 1.0) * clampf(1.0 - absf(v), 0.0, 1.0),
							clampf(1.0 - absf(v) / 0.08, 0.0, 1.0) * clampf(1.0 - absf(u), 0.0, 1.0))
					a = clampf(core * core * 1.2 + ray * ray, 0.0, 1.0) * clampf((1.0 - r) / 0.2, 0.0, 1.0)
				&"coin":
					a = clampf((0.9 - r) / 0.07, 0.0, 1.0)
					var rim := clampf((r - 0.64) / 0.08, 0.0, 1.0)
					var groove := 1.0 - clampf(absf(r - 0.56) / 0.05, 0.0, 1.0)
					var hl := clampf(1.0 - Vector2(u + 0.28, v + 0.28).length() / 0.32, 0.0, 1.0)
					shade = clampf(0.72 + 0.22 * rim - 0.28 * groove + 0.3 * hl, 0.0, 1.0)
				&"smoke":
					var nse := _vn(u * 2.3 + 7.1, v * 2.3 + 3.3) * 0.6 + _vn(u * 5.1 + 1.7, v * 5.1 - 2.2) * 0.4
					a = clampf((1.0 - r) * 1.6 + (nse - 0.5) * 0.9 - 0.2, 0.0, 1.0)
					a = a * a * (3.0 - 2.0 * a) * clampf((1.0 - r) / 0.2, 0.0, 1.0)
					shade = clampf(0.82 + 0.14 * (0.5 - v * 0.5) + (nse - 0.5) * 0.25, 0.0, 1.0)
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
	var gold_hot := _hdr(GOLD_HOT, 2.6)
	var gold := _hdr(GOLD, 2.0)
	var gold_end := _hdr(BRASS, 1.2, 0.0)
	match key:
		&"rise_motes":
			# Gold sparkles rising 1.5 m in 0.6 s (v 2.6-3.4 m/s, damping 1.5).
			_shape_disc(m, 0.7)
			m.direction = Vector3.UP
			m.spread = 8.0
			m.initial_velocity_min = 2.6
			m.initial_velocity_max = 3.4
			m.damping_min = 1.3
			m.damping_max = 1.7
			m.tangential_accel_min = -1.5
			m.tangential_accel_max = 1.5
			_size(m, 0.2, 0.32, &"grow")
			m.color_ramp = _ramp([Color(gold, 0.0), gold_hot, gold, gold_end])
		&"rise_dots":
			_shape_disc(m, 0.55)
			m.direction = Vector3.UP
			m.spread = 12.0
			m.initial_velocity_min = 2.2
			m.initial_velocity_max = 3.2
			m.damping_min = 1.2
			m.damping_max = 1.6
			_size(m, 0.12, 0.2, &"shrink")
			m.color_ramp = _ramp([gold_hot, gold, gold_end])
		&"coin_hop":
			_shape_sphere(m, 0.25)
			m.direction = Vector3.UP
			m.spread = 30.0
			m.initial_velocity_min = 3.0
			m.initial_velocity_max = 4.5
			m.gravity = Vector3(0, -13.0, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			m.angular_velocity_min = -480.0
			m.angular_velocity_max = 480.0
			_size(m, 0.22, 0.3, &"hold")
			var coin := _hdr(GOLD, 1.35)
			m.color_ramp = _ramp([coin, coin, coin, Color(coin, 0.0)])
		&"trade_dust":
			_shape_ring(m, 0.6, 0.05)
			m.direction = Vector3.UP
			m.spread = 65.0
			m.initial_velocity_min = 0.6
			m.initial_velocity_max = 1.3
			m.radial_velocity_min = 1.2
			m.radial_velocity_max = 2.4
			m.damping_min = 2.0
			m.damping_max = 3.0
			m.gravity = Vector3(0, 0.25, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			_size(m, 0.55, 0.95, &"grow")
			m.color_initial_ramp = _ramp(_lin([Color(0.58, 0.49, 0.35), Color(0.50, 0.42, 0.30), Color(0.64, 0.55, 0.40)]))
			m.color_ramp = _ramp([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.6), Color(1, 1, 1, 0.0)])
		&"gold_sparks":
			_shape_sphere(m, 0.15)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 3.0
			m.initial_velocity_max = 7.0
			m.gravity = Vector3(0, -9.0, 0)
			m.damping_min = 3.0
			m.damping_max = 5.0
			m.particle_flag_align_y = true
			_size(m, 0.06, 0.09, &"shrink")
			m.color_ramp = _ramp([gold_hot, gold, gold_end])
		&"coin_glint":
			_shape_sphere(m, 0.3)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 0.4
			m.initial_velocity_max = 1.2
			m.damping_min = 1.0
			m.damping_max = 1.5
			_size(m, 0.14, 0.24, &"grow")
			m.color_ramp = _ramp([gold_hot, gold, gold_end])
		&"smoke_puff":
			# Grey-blue cloud filling r 3 for 1.2 s (MIX).
			_shape_sphere(m, 1.6)
			m.emission_shape_scale = Vector3(1.0, 0.55, 1.0)   # a wide, low cloud
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 1.6
			m.initial_velocity_max = 3.0
			m.damping_min = 2.2
			m.damping_max = 3.0
			m.gravity = Vector3(0, 0.4, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			m.angular_velocity_min = -40.0
			m.angular_velocity_max = 40.0
			m.scale_min = 2.2
			m.scale_max = 3.0
			m.scale_curve = _curve([Vector2(0.0, 0.4), Vector2(0.25, 1.0), Vector2(1.0, 1.2)])
			m.color_initial_ramp = _ramp(_lin([SMOKE, Color(0.42, 0.47, 0.57), Color(0.56, 0.61, 0.70)]))
			m.color_ramp = _ramp_at([0.0, 0.1, 0.6, 1.0],
					[Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.75), Color(1, 1, 1, 0.0)])
		&"smoke_pop":
			_shape_sphere(m, 0.3)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 3.5
			m.initial_velocity_max = 6.0
			m.damping_min = 5.0
			m.damping_max = 7.0
			m.angle_min = -180.0
			m.angle_max = 180.0
			_size(m, 0.8, 1.3, &"grow")
			m.color_initial_ramp = _ramp(_lin([Color(0.62, 0.67, 0.76), SMOKE_DARK]))
			m.color_ramp = _ramp([Color(1, 1, 1, 0.8), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0.0)])
		&"teal_glint":
			# A few blue-green glints from the cloak trim as the Magpie vanishes.
			_shape_sphere(m, 0.5)
			m.direction = Vector3.UP
			m.spread = 180.0
			m.initial_velocity_min = 1.5
			m.initial_velocity_max = 3.0
			m.damping_min = 3.0
			m.damping_max = 4.0
			_size(m, 0.16, 0.26, &"shrink")
			var teal := _hdr(MAGPIE_TEAL, 2.2)
			m.color_ramp = _ramp([_hdr(Color(0.8, 1.0, 1.0), 2.4), teal, Color(teal, 0.0)])
		&"sack_sparkle":
			_shape_sphere(m, 0.4)
			m.direction = Vector3.UP
			m.spread = 60.0
			m.initial_velocity_min = 1.0
			m.initial_velocity_max = 2.6
			m.damping_min = 1.5
			m.damping_max = 2.5
			m.gravity = Vector3(0, -0.5, 0)
			_size(m, 0.2, 0.34, &"grow")
			m.color_ramp = _ramp([gold_hot, gold_hot, gold, gold_end])
		&"rope_dust":
			_shape_ring(m, 0.55, 0.05)
			m.direction = Vector3.UP
			m.spread = 70.0
			m.initial_velocity_min = 0.6
			m.initial_velocity_max = 1.4
			m.radial_velocity_min = 0.5
			m.radial_velocity_max = 1.2
			m.damping_min = 1.5
			m.damping_max = 2.5
			m.gravity = Vector3(0, 0.2, 0)
			m.angle_min = -180.0
			m.angle_max = 180.0
			_size(m, 0.4, 0.65, &"grow")
			var dust := DUST.srgb_to_linear()
			m.color_ramp = _ramp([Color(dust, 0.0), Color(dust, 0.45), Color(dust, 0.0)])
		&"ware_motes":
			_shape_disc(m, 4.0)
			m.direction = Vector3.UP
			m.spread = 15.0
			m.initial_velocity_min = 1.0
			m.initial_velocity_max = 2.2
			m.damping_min = 0.6
			m.damping_max = 1.0
			_size(m, 0.2, 0.34, &"grow")
			m.color_ramp = _ramp([Color(gold, 0.0), gold_hot, gold, gold_end])
		&"ware_sparks":
			_shape_ring(m, 1.2, 0.1)
			m.emission_ring_inner_radius = 1.0
			m.direction = Vector3.UP
			m.spread = 20.0
			m.initial_velocity_min = 1.0
			m.initial_velocity_max = 2.4
			m.radial_velocity_min = 5.0
			m.radial_velocity_max = 8.0
			m.damping_min = 2.0
			m.damping_max = 3.0
			m.particle_flag_align_y = true
			_size(m, 0.07, 0.1, &"shrink")
			m.color_ramp = _ramp([gold_hot, gold, gold, gold_end])
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


## Particle sizes in metres + a scale curve: shrink (sparks), grow (motes, dust), hold (coins).
func _size(m: ParticleProcessMaterial, lo: float, hi: float, kind: StringName) -> void:
	m.scale_min = lo
	m.scale_max = hi
	match kind:
		&"grow":
			m.scale_curve = _curve([Vector2(0.0, 0.3), Vector2(0.3, 1.0), Vector2(1.0, 0.3)])
		&"hold":
			m.scale_curve = _curve([Vector2(0.0, 1.0), Vector2(0.8, 1.0), Vector2(1.0, 0.4)])
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
