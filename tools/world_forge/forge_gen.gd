extends RefCounted
## World Forge `gen` (docs/design/map-production.md 2.4, tool task MT5): writes a mirrored skirmish `.map` from
## seed + archetype + players + tempo + biome, scores it on a coarse grid (the pre-filter: water, blocks and the
## MapForest forest as walls, 1 m octile Dijkstra from the canonical keep; the symmetry gives every other seat's
## distances), and sweeps seeds to keep the best. The full forge `map` + Map Lab + `fix` + the contact sheet run in
## world_forge.gd. No class_name on purpose (preloaded tool script).
##
## Archetypes (v1): river_split (Crown Hollow-like: a river through a moat isle, 2 or 4 players), open (no river, a
## pillar-ringed crown, more forest), spine (river_split + ridge blocks with gates on each bank). Players 2 = rot180
## (seat 0 south-west, seat 1 north-east), 4 = fourfold (allies on the west bank, a straight river on x = 0).
## Every candidate uses the template library (base_district, natural, rich_node, tavern_peddler, guild_pair,
## trade_post, camp / lair / point templates), so generated maps stay readable and fixable by hand.

const FMap := preload("res://tools/world_forge/forge_map.gd")
const Spacing := preload("res://tools/world_forge/forge_spacing.gd")
const GEN_DIR := "res://data/maps/gen"
const ARCHETYPES: Array[String] = ["river_split", "open", "spine"]
const TEMPOS: Array[String] = ["rush", "standard", "macro"]
const BIOMES: Array[String] = ["grass", "ash", "snow", "marsh", "sand", "meadow", "autumn", "forest", "salt", "crypt"]
const GRID := 1.0
const SQRT2 := 1.41421356
## Calibration of the grid's ally keep path against the Map Lab's navmesh path (quartermeet_s11: grid 53.0 m, navmesh
## 52.8 m): none needed; a forest cluster between allies shows on both.
const GRID_ALLY_OVERHEAD := 0.0

## Target bands per tempo (path metres; enemy_ally = nearest enemy / ally path), 1v1 and team maps.
const TARGETS_1V1 := {
	"rush": {"keep_enemy": Vector2(100, 125), "natural": Vector2(30, 50), "rich": Vector2(55, 85), "crown": Vector2(45, 65)},
	"standard": {"keep_enemy": Vector2(116, 150), "natural": Vector2(38, 58), "rich": Vector2(65, 95), "crown": Vector2(50, 72)},
	"macro": {"keep_enemy": Vector2(150, 190), "natural": Vector2(45, 68), "rich": Vector2(80, 115), "crown": Vector2(65, 92)},
}
const TARGETS_TEAM := {"ally": Vector2(60, 72), "enemy_ally": Vector2(2.0, 3.0), "keep_enemy": Vector2(130, 185),
	"natural": Vector2(32, 56), "rich": Vector2(50, 95), "crown": Vector2(60, 95)}
const SIZE_1V1 := {"rush": 112.0, "standard": 120.0, "macro": 144.0}
const SIZE_TEAM := 176.0

var id := ""
var archetype := "river_split"
var players := 2
var tempo := "standard"
var biome := "grass"
var size := 0.0
var debug_png := ""    ## score_layout writes its wall / distance grid here when set (debugging)


func _init(p_id: String, p_arch: String, p_players: int, p_tempo: String, p_biome: String, p_size: float = 0.0) -> void:
	id = p_id
	archetype = p_arch
	players = p_players
	tempo = p_tempo
	biome = p_biome
	size = p_size if p_size > 0.0 else (SIZE_TEAM if players >= 4 else float(SIZE_1V1.get(tempo, 120.0)))


func targets() -> Dictionary:
	if players >= 4:
		return TARGETS_TEAM
	return TARGETS_1V1.get(tempo, TARGETS_1V1["standard"])


# ---------------------------------------------------------------- text

## The `.map` text of one candidate.
func map_text(seed: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed(seed, archetype, players, tempo)
	return _text_team(seed, rng) if players >= 4 else _text_1v1(seed, rng)


## The candidate RNG seed (review L8): from `seed=` and the knobs only, never the map id (an adopted map keeps its
## seed under a new name), and plain integer arithmetic instead of Array.hash() (stable across Godot versions).
static func rng_seed(seed: int, arch: String, n_players: int, p_tempo: String) -> int:
	return seed * 1000003 + (ARCHETYPES.find(arch) + 1) * 7919 + n_players * 131 + (TEMPOS.find(p_tempo) + 1) * 17


static func _p(v: Vector2) -> String:
	return "(%.1f,%.1f)" % [snappedf(v.x, 0.1), snappedf(v.y, 0.1)]


static func _poly(pts: Array) -> String:
	var parts: Array[String] = []
	for v: Vector2 in pts:
		parts.append(_p(v))
	return "[%s]" % ",".join(parts)


func _head(seed: int, sym: String) -> String:
	var t := "# generated: gen %s archetype=%s seed=%d players=%d tempo=%s biome=%s size=%.0f (do not hand-edit; copy to data/maps/<id>.map to adopt)\n" % [
		id, archetype, seed, players, tempo, biome, size]
	t += "map %s_s%d  size=%.0f  symmetry=%s  biome=%s  title=\"%s (seed %d)\"  spec=docs/design/map-production.md\n" % [id, seed, size, sym, biome,
		id.capitalize(), seed]
	var tg := targets()
	var rl := "rules archetype=%s  tempo=%s  players=%d  seed=%d" % [archetype, tempo, players, seed]
	for k: String in tg:
		var b: Vector2 = tg[k]
		rl += "  %s=%s..%s" % [k, _num(b.x), _num(b.y)]
	rl += "  contest=%d\n" % (3 if players >= 4 else 5)
	return t + rl


static func _num(v: float) -> String:
	return str(snappedf(v, 0.01)).trim_suffix(".0")


## 1v1, rot180. Seat 0's frame: U = toward its keep (from the centre), V = U turned -90 deg; spots are written as
## a * U + b * V (Crown Hollow's own layout in this frame, scaled to the map and jittered by the seed).
func _text_1v1(seed: int, rng: RandomNumberGenerator) -> String:
	var h := size * 0.5
	var s := h / 60.0
	var ang := deg_to_rad(135.0 + rng.randf_range(-7.0, 7.0))
	var U := Vector2(cos(ang), sin(ang))
	var V := Vector2(U.y, -U.x)
	var tg := targets()
	var ke: Vector2 = tg["keep_enemy"]
	var r_k := clampf((ke.x + ke.y) * 0.5 / 2.0 / 1.1 + rng.randf_range(-2.5, 2.5), h * 0.6, (h - 15.0) * SQRT2)
	var keep := U * r_k
	# keep inside the square with a 15 m margin
	var lim := h - 15.0
	if absf(keep.x) > lim or absf(keep.y) > lim:
		keep *= lim / maxf(absf(keep.x), absf(keep.y))
		r_k = keep.length()
	var at := func(a: float, b: float, j: float = 4.0) -> Vector2:
		var p := U * (a * s + rng.randf_range(-j, j)) + V * (b * s + rng.randf_range(-j, j))
		return Vector2(clampf(p.x, -h + 6.0, h - 6.0), clampf(p.y, -h + 6.0, h - 6.0))
	var t := _head(seed, "rot180")
	t += "seat 0  name=\"south-west\"  side=0  frame=identity\nseat 1  name=\"north-east\"  side=1  frame=rot180\n\n"
	t += "# base, expansions (templates; resource templates face the owner's keep)\n"
	t += "use base_district  home  at=%s\n" % _p(keep)
	var nat: Vector2 = at.call(15.6, -7.1 if rng.randf() < 0.5 else 7.1, 4.0)
	var rich: Vector2 = at.call(rng.randf_range(-3.0, 3.0), -56.6, 3.0)
	t += "use natural  nat  at=%s  yaw=%.1f\n" % [_p(nat), _yaw_to(nat, keep)]
	t += "use rich_node  rich  at=%s  yaw=%.1f\n" % [_p(rich), _yaw_to(rich, keep)]
	# river and crown
	var river := archetype != "open"
	t += "\n# centre and river\n"
	t += "use crown_isle  centre  at=(0,0)  face=none\n" if river else "use crown_open  centre  at=(0,0)  face=none\n"
	var crossings: Array = []
	if river:
		var rv := _river_1v1(rng, U, h)
		t += rv["text"]
		crossings = rv["fords"]
	# points
	t += "\n# capture points, camps, lairs\n"
	t += "point tower_a  sub=watchtower  at=%s\n" % _p(at.call(-12.0, -46.0, 3.0))
	t += "point tower_b  sub=watchtower  at=%s\n" % _p(at.call(32.5, 24.0, 3.0))
	t += "point well     sub=well        at=%s\n" % _p(at.call(4.2, -38.0, 3.0))
	# review H2: the peddler of tavern_peddler sits ~10 m along U from the tavern, i.e. at about (10, -21.2): the old
	# shrine spot (11.3, -19.8) was on top of it (Thornwater shipped with them 2.3 m apart)
	t += "point shrine   sub=shrine      at=%s\n" % _p(at.call(11.3, -11.0, 3.0))
	t += "camp wallow  sub=bristleback  at=%s\n" % _p(at.call(50.2, 30.4, 3.0))
	if river and not crossings.is_empty():
		t += "use nest_in_ford  ford  at=%s  face=none\n" % _p(crossings[0])
	else:
		t += "camp nest  sub=mirefang  at=%s\n" % _p(at.call(-18.0, -30.0, 3.0))
	t += "camp stag  sub=hollow_stag  at=%s\n" % _p(at.call(19.1, -33.2, 3.0))
	t += "use lair_pair  lairs_w  at=%s  yaw=%.1f  a=tusker  b=roc\n" % [_p(at.call(36.0, -40.0, 3.0)), rad_to_deg(ang)]
	t += "use lair_pair  lairs_n  at=%s  yaw=%.1f  a=direwolf  b=grizzlemaw\n" % [_p(at.call(-2.0, -62.0, 2.0)), rad_to_deg(ang) + 90.0]
	# services
	t += "\n# services: tavern + peddler (contested axis), caches, guild houses, trade posts on the ring road\n"
	t += "use tavern_peddler  inn  at=%s  yaw=%.1f\n" % [_p(at.call(0.0, -21.2, 2.0)), rad_to_deg(ang) + 90.0]
	t += "cache cache_a  at=%s\ncache cache_b  at=%s\n" % [_p(at.call(21.2, -21.2, 3.0)), _p(at.call(23.3, 14.8, 3.0))]
	var post_a: Vector2 = at.call(38.2, -36.8, 2.0)
	var post_b: Vector2 = at.call(38.2, 36.8, 2.0)
	var start := keep - U * 9.9
	var door_a := post_a + (start - post_a).normalized() * 4.0
	var door_b := post_b + (start - post_b).normalized() * 4.0
	t += "post post_a  at=%s  door=%s\npost post_b  at=%s  door=%s\n" % [_p(post_a), _p(door_a), _p(post_b), _p(door_b)]
	var corner_a := U * 2.8 * s + V * -65.0 * s
	var corner_b := U * -2.8 * s + V * -65.0 * s
	t += "road ring  poly=%s  width=5\n" % _poly([start, door_a, _clampv(corner_a, h - 7.0), _clampv(corner_b, h - 7.0), -door_b, -start])
	var gp: Vector2 = at.call(0.0, -71.0, 1.5)
	gp = _clampv(gp, h - 9.0)
	t += "use guild_pair  guilds  at=%s  yaw=%.1f\n" % [_p(gp), _yaw_to(gp, Vector2.ZERO)]
	# archetype extras
	if archetype == "spine":
		t += "\n# spine: a ridge with a gate on each bank, across the route to the rich node\n"
		var ridge := (keep + rich) * 0.5 + V * rng.randf_range(-4.0, 4.0)
		t += "use spine_gate  ridge  at=%s  yaw=%.1f  gate=7  len=%.0f\n" % [_p(ridge), rad_to_deg(atan2((rich - keep).x, (rich - keep).y)), 18.0 * s]
	t += "\n# forest (the main.gd generator as data), bank willows, wildlife\n"
	t += "forest seed=%d  pre=auto  density=%.2f%s\n" % [seed * 7919 + 7, 1.6 if archetype == "open" else 1.0,
		"  pillars=(0,0,8)  pillar_count=10  pillar_gap=4" if river else "  pillars=(0,0,9)  pillar_count=10  pillar_gap=2"]
	if river:
		t += "willows seed=%d  draws=36  river_draws=28\n" % (seed * 31 + 17)
	for k in 4:
		t += "slot graze%d  sub=graze  at=%s  clear=0\n" % [k, _p(at.call(-14.0 - 8.0 * float(k % 2), -46.0 - 6.0 * float(k / 2), 2.0))]
	for k in 4:
		t += "slot rabbit%d  sub=rabbit  at=%s  clear=0\n" % [k, _p(at.call(30.0 + 6.0 * float(k), 10.0 - 12.0 * float(k % 2), 3.0))]
	t += "use biome_%s  ground  at=%s  face=none  r=%.0f\n" % [_biome_kit(), _p(keep * 0.55), 22.0 * s]
	return t


## The river through the centre, perpendicular to the keep axis U (jittered), into a moat; crossings in half-turn
## pairs: road bridges near the edges, fords half way, lane bridges on the moat facing the keeps.
func _river_1v1(rng: RandomNumberGenerator, U: Vector2, h: float) -> Dictionary:
	# Crown Hollow's river: the bisector (V) turned ~31 deg toward the enemy side, so the contested spots on the
	# bisector (rich nodes, tavern, peddler, guild houses) stay dry, one per bank.
	var V := Vector2(U.y, -U.x)
	var th := deg_to_rad(31.0 + rng.randf_range(-7.0, 7.0))
	var w := (-V * cos(th) - U * sin(th)).normalized()   # arm a runs out along w; arm b along -w
	var moat_r := 12.75
	var t_edge := minf(h / maxf(absf(w.x), 0.01), h / maxf(absf(w.y), 0.01)) + 2.0
	var side := Vector2(-w.y, w.x)
	var pts: Array = []
	var ts: Array[float] = [t_edge, t_edge * 0.78, t_edge * 0.6, t_edge * 0.44, t_edge * 0.3, moat_r + 0.25]
	for i in ts.size():
		var wob := 0.0 if i == 0 or i == ts.size() - 1 else rng.randf_range(-3.0, 3.0)
		pts.append(w * ts[i] + side * wob)
	var arm_b: Array = []
	for i in range(pts.size() - 1, -1, -1):
		arm_b.append(-(pts[i] as Vector2))
	var t := "river arm  poly=%s  half_width=2.5\nriver arm2 poly=%s  half_width=2.5\nmoat center=(0,0)  radius=%.2f  half_width=1.75\n" % [
		_poly(pts), _poly(arm_b), moat_r]
	# crossings on arm a, mirrored by hand (global statements are not mirrored)
	var bridge := _on_poly(pts, 0.25)
	var ford := _on_poly(pts, 0.45)
	var bdir := Vector2(-(bridge["tan"] as Vector2).y, (bridge["tan"] as Vector2).x)
	var fdir: Vector2 = ford["tan"]
	t += "crossing bridge_road_a  kind=bridge_road  at=%s  width=6  length=9  dir=%s\n" % [_p(bridge["p"]), _p(bdir)]
	t += "crossing bridge_road_b  kind=bridge_road  at=%s  width=6  length=9  dir=%s\n" % [_p(-(bridge["p"] as Vector2)), _p(-bdir)]
	t += "crossing ford_a  kind=ford  at=%s  width=7  length=7  dir=%s\n" % [_p(ford["p"]), _p(fdir)]
	t += "crossing ford_b  kind=ford  at=%s  width=7  length=7  dir=%s\n" % [_p(-(ford["p"] as Vector2)), _p(fdir)]
	var lane := U * moat_r
	t += "crossing bridge_crown_a  kind=bridge_lane  at=%s  width=8  length=6.5  dir=%s\n" % [_p(lane), _p(U)]
	t += "crossing bridge_crown_b  kind=bridge_lane  at=%s  width=8  length=6.5  dir=%s\n" % [_p(-lane), _p(-U)]
	# the Crown Steps on the bisector (Crown Hollow: 2 fords + 2 steps = the 4 circles of the ground shader)
	t += "crossing steps_a  kind=steps  at=%s  width=6  length=6  dir=%s\n" % [_p(-V * moat_r), _p(-V)]
	t += "crossing steps_b  kind=steps  at=%s  width=6  length=6  dir=%s\n" % [_p(V * moat_r), _p(V)]
	# which ford is on seat 0's side of the axis: the nest goes into the one nearer seat 0's keep
	var f0: Vector2 = ford["p"]
	return {"text": t, "fords": [f0 if f0.dot(U) > 0.0 else -f0]}


## The point at share `k` of a polyline's length (0 = first point) and its unit tangent.
static func _on_poly(pts: Array, k: float) -> Dictionary:
	var total := 0.0
	for i in pts.size() - 1:
		total += (pts[i] as Vector2).distance_to(pts[i + 1])
	var want := total * k
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var l := a.distance_to(b)
		if want <= l or i == pts.size() - 2:
			return {"p": a.lerp(b, clampf(want / maxf(l, 0.01), 0.0, 1.0)), "tan": (b - a).normalized()}
		want -= l
	return {"p": pts[0], "tan": Vector2.RIGHT}


static func _clampv(v: Vector2, lim: float) -> Vector2:
	return Vector2(clampf(v.x, -lim, lim), clampf(v.y, -lim, lim))


## Yaw (deg) that points a template's local +z from `from` toward `to`.
static func _yaw_to(from: Vector2, to: Vector2) -> float:
	var d := to - from
	return rad_to_deg(atan2(d.x, d.y))


func _biome_kit() -> String:
	return biome if biome in ["ash", "snow", "marsh", "sand", "meadow", "autumn", "forest", "salt", "crypt"] else "meadow"


## 2v2, fourfold: seat A1 (identity, x < 0, z > 0) and its ally A2 (mirror_z) on the west bank, B1 / B2 (rot180 /
## mirror_x) on the east; a straight river on x = 0 into a moat; spots written in the A1 quadrant.
func _text_team(seed: int, rng: RandomNumberGenerator) -> String:
	var h := size * 0.5
	var s := h / 80.0
	var tg := targets()
	var ally: Vector2 = tg["ally"]
	var z_k := (ally.x + ally.y) * 0.25 + rng.randf_range(-1.0, 1.0)
	var x_k := clampf(64.0 * s + rng.randf_range(-1.5, 1.5), 40.0, h - 14.0)
	var keep := Vector2(-x_k, z_k)
	var at := func(x: float, z: float, j: float = 3.0) -> Vector2:
		return Vector2(clampf(x * s + rng.randf_range(-j, j), -h + 6.0, -2.5), clampf(z * s + rng.randf_range(-j, j), 2.5, h - 6.0))
	var t := _head(seed, "fourfold")
	t += "seat 0  name=\"A1 south-west\"  side=0  frame=identity\nseat 3  name=\"A2 north-west\"  side=0  frame=mirror_z\n"
	t += "seat 1  name=\"B1 north-east\"  side=1  frame=rot180\nseat 4  name=\"B2 south-east\"  side=1  frame=mirror_x\n\n"
	t += "use base_district  home  at=%s\n" % _p(keep)
	var nat: Vector2 = at.call(-34.0, 14.0, 2.5)
	var rich: Vector2 = at.call(-12.0, 48.0, 2.5)
	var third: Vector2 = at.call(-70.0, 58.0, 2.0)
	t += "use natural  nat  at=%s  yaw=%.1f\n" % [_p(nat), _yaw_to(nat, keep)]
	t += "use rich_node  rich  at=%s  yaw=%.1f\n" % [_p(rich), _yaw_to(rich, keep)]
	t += "use third_far  third  at=%s  yaw=%.1f\n" % [_p(third), _yaw_to(third, keep)]
	var river := archetype != "open"
	t += "\n# centre and river (x = 0)\n"
	t += "use crown_isle  centre  at=(0,0)  face=none\n" if river else "use crown_open  centre  at=(0,0)  face=none\n"
	var fz := 0.42 * h + rng.randf_range(-3.0, 3.0)
	var bz := 0.72 * h + rng.randf_range(-3.0, 3.0)
	if river:
		t += "use river_straight  river  at=(0,0)  face=none  reach=%.0f  moat=13\n" % (h + 2.0)
		t += "use crossing_set_lean  x  at=(0,0)  face=none  road=%.1f  ford=%.1f  moat=13\n" % [bz, fz]
	t += "\n# capture points, camps, lairs (A1 quadrant; the symmetry places the other three)\n"
	t += "point tower_r  sub=watchtower  at=%s\n" % _p(at.call(-16.0, bz / s, 2.0))
	t += "point tower_c  sub=watchtower  at=%s\n" % _p(at.call(-20.0, 8.0, 2.0))
	t += "point well     sub=well        at=%s\n" % _p(at.call(-34.0, 46.0, 3.0))
	t += "point shrine   sub=shrine      at=%s\n" % _p(at.call(-48.0, 8.0, 3.0))
	t += "camp wallow  sub=bristleback  at=%s\n" % _p(at.call(-72.0, 44.0, 1.5))
	if river:
		t += "use nest_in_ford  ford  at=(0,%.1f)  face=none\n" % fz
	else:
		t += "camp nest  sub=mirefang  at=%s\n" % _p(at.call(-8.0, 34.0, 2.0))
	t += "camp stag  sub=hollow_stag  at=%s\n" % _p(at.call(-30.0, 66.0, 2.0))
	t += "use lair_pair  lairs  at=%s  yaw=0  a=tusker  b=direwolf\n" % _p(at.call(-50.0, 73.0, 1.0))
	t += "\n# services\n"
	t += "tavern inn  at=%s\npeddler peddler  at=%s\n" % [_p(at.call(-26.0, 22.0, 2.0)), _p(at.call(-58.0, 20.0, 2.0))]
	t += "cache cache_a  at=%s\ncache cache_b  at=%s\n" % [_p(at.call(-44.0, 58.0, 3.0)), _p(at.call(-6.0, 22.0, 2.0))]
	var post_w: Vector2 = at.call(-74.0, 12.0, 1.5)
	var post_s: Vector2 = at.call(-18.0, 72.0, 1.0)
	var start := keep + (-keep).normalized() * 9.9
	var door_w := post_w + (start - post_w).normalized() * 4.0
	var door_s := post_s + (start - post_s).normalized() * 4.0
	t += "post post_w  at=%s  door=%s\npost post_s  at=%s  door=%s\n" % [_p(post_w), _p(door_w), _p(post_s), _p(door_s)]
	t += "road trade  poly=%s  width=5\n" % _poly([door_w, start, door_s])
	var gp: Vector2 = at.call(-72.0, 70.0, 1.0)
	t += "use guild_pair  guilds  at=%s  yaw=%.1f\n" % [_p(gp), _yaw_to(gp, Vector2.ZERO)]
	if archetype == "spine":
		t += "use spine_gate  ridge  at=%s  yaw=0  gate=7  len=%.0f\n" % [_p(at.call(-40.0, 34.0, 2.0)), 16.0 * s]
	t += "\nforest seed=%d  pre=auto  density=%.2f  pillars=(0,0,8)  pillar_count=8  pillar_gap=-1\n" % [seed * 7919 + 7, 1.5 if archetype == "open" else 1.0]
	if river:
		t += "willows seed=%d  draws=30  river_draws=30  arc=90..180\n" % (seed * 31 + 17)
	for k in 3:
		t += "slot graze%d  sub=graze  at=%s  clear=0\n" % [k, _p(at.call(-60.0 + 8.0 * float(k), 56.0, 2.0))]
	for k in 3:
		t += "slot rabbit%d  sub=rabbit  at=%s  clear=0\n" % [k, _p(at.call(-30.0 - 10.0 * float(k), 30.0, 3.0))]
	t += "use biome_%s  ground  at=%s  face=none  r=%.0f\n" % [_biome_kit(), _p(keep * 0.6), 24.0 * s]
	return t


# ---------------------------------------------------------------- pre-filter (grid score)

## Compiles `path` and scores it: {ok, score (lower = better), measures: {key: value}, miss: {key: share}, errors}.
func score_file(path: String) -> Dictionary:
	var fm := FMap.new()
	if not fm.compile(path):
		return {"ok": false, "score": INF, "errors": fm.spec.error_lines()}
	return score_layout(fm.layout)


func score_layout(lay: MapLayout) -> Dictionary:
	var out := {"ok": true, "score": 0.0, "measures": {}, "miss": {}, "unreachable": 0}
	# review L1: MapInfo is process-global; score this layout at its size, then put the running map's size back
	var prev_size := Vector2(MapInfo.size_x, MapInfo.size_z)
	var prev_id := MapInfo.map_id
	MapInfo.setup(lay.size_x, lay.size_z, lay.id)
	out = _score_layout(lay, out)
	MapInfo.setup(prev_size.x, prev_size.y, prev_id)
	return out


func _score_layout(lay: MapLayout, out: Dictionary) -> Dictionary:
	var river: RiverSystem = null
	if not lay.river.is_empty() or not lay.moat.is_empty():
		river = RiverSystem.new()
		river.build_visuals = false
		river.setup(LayoutLevel.river_lines(lay), LayoutLevel.river_half_width(lay), LayoutLevel.moat_of(lay), LayoutLevel.crossings_of(lay))
	var plan := MapForest.plan(lay, river)
	var nx := int(ceil(lay.size_x / GRID))
	var nz := int(ceil(lay.size_z / GRID))
	var hx := lay.size_x * 0.5
	var hz := lay.size_z * 0.5
	var wall := PackedByteArray()
	wall.resize(nx * nz)
	wall.fill(0)
	if river:
		# deep water: rasterise the carve polygons (cells whose centre lies inside)
		for poly: PackedVector2Array in river.water_polygons():
			var lo := Vector2(INF, INF)
			var hi := Vector2(-INF, -INF)
			for q in poly:
				lo = lo.min(q)
				hi = hi.max(q)
			for j in range(maxi(0, int(floor((lo.y + hz) / GRID))), mini(nz - 1, int(floor((hi.y + hz) / GRID))) + 1):
				for i in range(maxi(0, int(floor((lo.x + hx) / GRID))), mini(nx - 1, int(floor((hi.x + hx) / GRID))) + 1):
					if Geometry2D.is_point_in_polygon(Vector2(-hx + (i + 0.5) * GRID, -hz + (j + 0.5) * GRID), poly):
						wall[j * nx + i] = 1
	var stamp := func(c: Vector3, r: float) -> void:
		var i0 := maxi(0, int(floor((c.x - r + hx) / GRID)))
		var i1 := mini(nx - 1, int(floor((c.x + r + hx) / GRID)))
		var j0 := maxi(0, int(floor((c.z - r + hz) / GRID)))
		var j1 := mini(nz - 1, int(floor((c.z + r + hz) / GRID)))
		for j in range(j0, j1 + 1):
			for i in range(i0, i1 + 1):
				var q := Vector3(-hx + (i + 0.5) * GRID, 0.0, -hz + (j + 0.5) * GRID)
				if Vector2(q.x - c.x, q.z - c.z).length() < r:
					wall[j * nx + i] = 1
	for t: Dictionary in plan["trees"]:
		stamp.call(t["pos"], 0.45 * float(t["s"]) + 0.5)
	for r: Dictionary in plan["rocks"]:
		stamp.call(r["pos"], 0.8 * float(r["s"]) + 0.4)
	for b: Dictionary in lay.blocks:
		var hb: Vector3 = b["half"]
		var basis := Basis(Vector3.UP, deg_to_rad(float(b.get("yaw", 0.0))))
		var rr := Vector2(hb.x, hb.z).length() + 0.5
		var c: Vector3 = b["center"]
		var i0 := maxi(0, int(floor((c.x - rr + hx) / GRID)))
		var i1 := mini(nx - 1, int(floor((c.x + rr + hx) / GRID)))
		var j0 := maxi(0, int(floor((c.z - rr + hz) / GRID)))
		var j1 := mini(nz - 1, int(floor((c.z + rr + hz) / GRID)))
		for j in range(j0, j1 + 1):
			for i in range(i0, i1 + 1):
				var q := Vector3(-hx + (i + 0.5) * GRID, 0.0, -hz + (j + 0.5) * GRID)
				var l := basis.inverse() * (q - c)
				if absf(l.x) < hb.x + 0.5 and absf(l.z) < hb.z + 0.5:
					wall[j * nx + i] = 1
	if river:
		river.free()
	# Dijkstra from the canonical keep
	var keep := {}
	for k: Dictionary in lay.spots_of("keep"):
		if String(k.get("image", "identity")) == "identity":
			keep = k
	if keep.is_empty():
		return {"ok": false, "score": INF, "errors": ["no canonical keep"]}
	var kp: Vector3 = keep["pos"]
	var tw := Time.get_ticks_usec()
	var dist := _dijkstra(wall, nx, nz, hx, hz, [kp + Vector3(0, 0, 0)], 4.0)
	out["dijkstra_ms"] = (Time.get_ticks_usec() - tw) / 1000.0
	if debug_png != "":
		var img := Image.create(nx, nz, false, Image.FORMAT_RGB8)
		for j in nz:
			for i in nx:
				var d := dist[j * nx + i]
				img.set_pixel(i, j, Color(0.1, 0.1, 0.6) if wall[j * nx + i] != 0 else (Color(1, 0, 0) if is_inf(d) else Color(0, clampf(1.0 - d / 250.0, 0, 1), 0)))
		img.save_png(debug_png)
	var d_at := func(p: Vector3) -> float:
		return _sample(dist, nx, nz, hx, hz, p)
	var imgs := MapForest.images(lay.symmetry)
	var seats := lay.seats
	# own / enemy / ally keep positions under the seat frames
	var own_side := 0
	for s: Dictionary in seats:
		if String(s.get("frame_name", "identity")) == "identity":
			own_side = int(s["side"])
	var enemy_keeps: Array[Vector3] = []
	var ally_keeps: Array[Vector3] = []
	for s: Dictionary in seats:
		if String(s.get("frame_name", "")) == "identity":
			continue
		var xf: Transform3D = s["frame"]
		if int(s["side"]) == own_side:
			ally_keeps.append(xf * kp)
		else:
			enemy_keeps.append(xf * kp)
	var m: Dictionary = out["measures"]
	var ne := INF
	for e in enemy_keeps:
		ne = minf(ne, d_at.call(e))
	m["keep_enemy"] = ne
	if not ally_keeps.is_empty():
		var na := INF
		for a in ally_keeps:
			na = minf(na, d_at.call(a))
		na += GRID_ALLY_OVERHEAD
		m["ally"] = na
		m["enemy_ally"] = ne / maxf(na, 0.01)
	for n: Dictionary in lay.spots_of("node"):
		if String(n.get("image", "identity")) != "identity":
			continue
		var role := LayoutLevel._role_of(n)
		if role == "mid":
			m["natural"] = d_at.call(n["pos"])
		elif role in ["rich", "third"]:
			m[role] = d_at.call(n["pos"])
	var cs := lay.spots_of("crown")
	if not cs.is_empty():
		m["crown"] = d_at.call(cs[0]["pos"])
	# every spot reachable (the canonical keep sees every image: the symmetry makes the rest)
	var unreach := 0
	for sp: Dictionary in lay.spots:
		if sp["kind"] in ["slot", "start"]:
			continue
		if is_inf(float(d_at.call(sp["pos"]))):
			unreach += 1
	out["unreachable"] = unreach
	var sc := float(unreach) * 50.0
	# L2: spots outside the map (2 m margin) and L3: spacing (forge_spacing.gd) are World Forge FAILs: both are scored,
	# and a candidate with a spacing FAIL is rejected (world_forge.gd gen never sends it to the Map Lab; review H2)
	var outside := 0
	for sp: Dictionary in lay.spots:
		var p: Vector3 = sp["pos"]
		if absf(p.x) > hx - 2.0 or absf(p.z) > hz - 2.0:
			outside += 1
	out["outside"] = outside
	sc += float(outside) * 50.0
	var close := Spacing.findings(lay)
	out["close"] = close.size()
	out["close_lines"] = Spacing.lines(close)
	sc += float(close.size()) * 200.0
	var tg: Dictionary = lay.rules.get("targets", {})
	for key: String in tg:
		if not m.has(key):
			continue
		var v: float = m[key]
		var miss := INF if is_inf(v) else _band_miss(v, tg[key])
		out["miss"][key] = miss
		sc += 100.0 if is_inf(miss) else 100.0 * miss * miss + (5.0 * miss if miss > 0.05 else 0.0)
		# inside the band: a small pull toward its middle (ranks the candidates that all fit)
		var b: Vector2 = tg[key]
		if not is_inf(v) and b.y > b.x:
			sc += 0.25 * pow((v - (b.x + b.y) * 0.5) / ((b.y - b.x) * 0.5), 2.0)
	# R3-like contest share: points / camps / crown between 0.9 and 1.45 of the enemy's path
	var contest := 0
	for sp: Dictionary in lay.spots:
		if not sp["kind"] in ["point", "camp", "crown", "post", "tavern"]:
			continue
		var own: float = d_at.call(sp["pos"])
		var en := INF
		for xf in imgs:
			if xf == Transform3D.IDENTITY:
				continue
			# the enemy keep's distance to sp = the canonical keep's distance to the image of sp
			for s2: Dictionary in seats:
				if int(s2["side"]) != own_side and (s2["frame"] as Transform3D) == xf:
					en = minf(en, d_at.call(xf.affine_inverse() * (sp["pos"] as Vector3)))
		if is_inf(own) or is_inf(en) or en <= 0.0:
			continue
		var r := own / en
		if r >= 0.9 and r <= 1.45:
			contest += 1
	m["contest"] = contest
	var need := float(lay.rules.get("contest", 5.0))
	if float(contest) < need:
		sc += 4.0 * (need - float(contest))
	else:
		sc -= 0.05 * minf(float(contest) - need, 4.0)
	out["score"] = sc
	out["trees"] = (plan["trees"] as Array).size()
	return out


static func _band_miss(v: float, band: Vector2) -> float:
	if v < band.x:
		return (band.x - v) / maxf(band.x, 0.01)
	if v > band.y:
		return (v - band.y) / maxf(band.y, 0.01)
	return 0.0


## 8-neighbour Dijkstra on the grid (walls = 1) from `sources` (world points; their `free` m radius is opened).
static func _dijkstra(wall: PackedByteArray, nx: int, nz: int, hx: float, hz: float, sources: Array, free: float) -> PackedFloat32Array:
	var dist := PackedFloat32Array()
	dist.resize(nx * nz)
	dist.fill(INF)
	var heap: Array = []   # binary heap of [d, idx]
	for src: Vector3 in sources:
		var ci := clampi(int(floor((src.x + hx) / GRID)), 0, nx - 1)
		var cj := clampi(int(floor((src.z + hz) / GRID)), 0, nz - 1)
		var rr := int(ceil(free / GRID))
		for dj in range(-rr, rr + 1):
			for di in range(-rr, rr + 1):
				var i := ci + di
				var j := cj + dj
				if i < 0 or j < 0 or i >= nx or j >= nz:
					continue
				var d := Vector2(di, dj).length() * GRID
				if d > free:
					continue
				var idx := j * nx + i
				if d < dist[idx]:
					dist[idx] = d
					_push(heap, [d, idx])
	var offs := [[1, 0, 1.0], [-1, 0, 1.0], [0, 1, 1.0], [0, -1, 1.0], [1, 1, SQRT2], [1, -1, SQRT2], [-1, 1, SQRT2], [-1, -1, SQRT2]]
	while not heap.is_empty():
		var top: Array = _pop(heap)
		var d0: float = top[0]
		var idx: int = top[1]
		if d0 > dist[idx] + 0.001:   # stale entry (dist is float32: compare with a tolerance)
			continue
		var i := idx % nx
		var j := idx / nx
		for o: Array in offs:
			var ni: int = i + int(o[0])
			var nj: int = j + int(o[1])
			if ni < 0 or nj < 0 or ni >= nx or nj >= nz:
				continue
			var nidx := nj * nx + ni
			if wall[nidx] != 0:
				continue
			if int(o[0]) != 0 and int(o[1]) != 0 and (wall[j * nx + ni] != 0 or wall[nj * nx + i] != 0):
				continue   # no corner cutting
			var nd := d0 + float(o[2]) * GRID
			if nd < dist[nidx] - 0.001:
				dist[nidx] = nd
				_push(heap, [nd, nidx])
	return dist


## Distance at a world point: the nearest open cell within 4 m (a spot inside its own building footprint).
static func _sample(dist: PackedFloat32Array, nx: int, nz: int, hx: float, hz: float, p: Vector3) -> float:
	var ci := clampi(int(floor((p.x + hx) / GRID)), 0, nx - 1)
	var cj := clampi(int(floor((p.z + hz) / GRID)), 0, nz - 1)
	var best := INF
	for r in 5:
		for dj in range(-r, r + 1):
			for di in range(-r, r + 1):
				if maxi(absi(di), absi(dj)) != r:
					continue
				var i := ci + di
				var j := cj + dj
				if i < 0 or j < 0 or i >= nx or j >= nz:
					continue
				var d := dist[j * nx + i]
				if not is_inf(d):
					best = minf(best, d + Vector2(di, dj).length() * GRID)
		if not is_inf(best):
			return best
	return best


static func _push(heap: Array, item: Array) -> void:
	heap.append(item)
	var i := heap.size() - 1
	while i > 0:
		var p := (i - 1) / 2
		if float(heap[p][0]) <= float(item[0]):
			break
		heap[i] = heap[p]
		i = p
	heap[i] = item


static func _pop(heap: Array) -> Array:
	var top: Array = heap[0]
	var last: Array = heap.pop_back()
	if heap.is_empty():
		return top
	var i := 0
	var n := heap.size()
	while true:
		var l := 2 * i + 1
		if l >= n:
			break
		var r := l + 1
		var c := r if r < n and float(heap[r][0]) < float(heap[l][0]) else l
		if float(heap[c][0]) >= float(last[0]):
			break
		heap[i] = heap[c]
		i = c
	heap[i] = last
	return top
