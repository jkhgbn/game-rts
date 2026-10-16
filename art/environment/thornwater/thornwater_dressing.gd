class_name ThornwaterDressing
extends Node3D
## G-F review 2 item 9 (docs/art/gf_thornwater.md): Thornwater's own dressing (Medium+ only; ThornwaterLook adds it),
## so the map stops reading as Crown Hollow:
##   water edges  reed beds in broken runs along both banks of the river and the moat (in the water at the trench edge
##                and on the bank), cattail stands, lily pads on the calm margins; marsh pockets (puddles + rushes)
##                round the two fords
##   rim          bramble thickets, gorse, rushes and mossy boulders clumped along the last ~3 m of the map, their depth
##                driven by noise (outcrops and open bays), so the straight edge breaks up; reed pools in some bays
##   border belt  a mixed fen wood outside the map (willow / broadleaf / pine / fir in species clusters, 3 sizes), a
##                ragged inner line, full trees in the front row at High+ and the cheap far stand-ins behind (Medium:
##                stand-ins only): it hides the uniform painted canopy band
##   crown isle   four thorn spires rising from the moat between the crossings (the landmark: Crown Hollow has none)
##                and briars at the feet of the ruin pillars
## One MultiMeshInstance3D per mesh kind (~14 draws). Draw-only: no collider, no navmesh effect, nothing on nav layers.
## Kept clear: keeps, nodes, building slots, points, camps, lairs, taverns, posts, caches, roads, crossings; a building
## placed later hides the small decor under its footprint (node_added). Map detail Low keeps half of every kind except
## the spires. Deterministic (same layout = same dressing).

const NODE_NAME := &"ThornwaterDressing"
const B := "res://art/environment/biomes/"
const M := "res://art/environment/meshes/"
const MESHES_SCRIPT := "res://art/environment/thornwater/thornwater_meshes.gd"
const LOOK_SCRIPT := "res://art/environment/thornwater/thornwater_look.gd"
const REEDS := B + "riverbank/rb_reeds.res"
const CATTAILS := B + "riverbank/rb_cattails.res"
const LILY := B + "riverbank/rb_lily_pads.res"
const RUSHES := B + "marsh/marsh_rushes.res"
const PUDDLES := B + "marsh/marsh_puddles.res"
const GORSE := B + "heath/heath_gorse.res"
const BOULDER := B + "old_wood/ow_moss_boulders.res"
## Built in code (thornwater_meshes.gd), keyed like a path.
const THICKET := "thornwater:thicket"
const SPIRE := "thornwater:spire"
const TREES: Array[String] = [M + "tree_willow.res", M + "tree_birch.res", M + "tree_broadleaf.res",
	M + "tree_pine.res", M + "tree_fir.res"]
const FAR_TREES: Array[String] = [M + "tree_willow_far.res", M + "tree_birch_far.res", M + "tree_broadleaf_far.res",
	M + "tree_pine_far.res", M + "tree_fir_far.res"]
## Species weights of the fen belt (willow, birch, broadleaf, pine, fir): a dark wet wood (no birch: its white trunks
## read as sticks lying on the rim from the game camera).
const SPECIES_W: Array[float] = [0.2, 0.0, 0.32, 0.22, 0.26]
const WATER_Y := -0.35
const SHADOW_KINDS: Array[String] = [SPIRE, BOULDER, M + "tree_willow.res", M + "tree_birch.res",
	M + "tree_broadleaf.res", M + "tree_pine.res", M + "tree_fir.res"]
## Kinds never hidden by a building (outside the map, or in the moat).
const FIXED_KINDS: Array[String] = [SPIRE]
const LOW_DETAIL := 0.5
const BELT_DEPTH := 12.0        ## metres of fen wood outside the map edge
const BELT_FULL := 4.6          ## full trees only in the front row and this close, far stand-ins beyond
const RIM_REACH := 3.2          ## the deepest outcrop into the map (m)

var counts := {}                     ## kind -> instances placed (tests)
var _level: Node
var _layout: Resource
var _river: Node
var _rng := RandomNumberGenerator.new()
var _thin_rng := RandomNumberGenerator.new()
var _keep := 1.0
var _lists := {}                     ## kind -> Array[Transform3D]
var _mmis := {}                      ## kind -> MultiMeshInstance3D
var _avoid: Array[Vector3] = []      ## (x, z, radius)
var _roads: Array[Vector4] = []      ## (a.x, a.z, b.x, b.z)
var _road_half := 3.3
var _hx := 60.0
var _hz := 60.0
var _full_trees := true              ## High+: full trees in the belt's front row; Medium: far stand-ins only


## CPU copies of one kind's instance transforms (tests: the headless renderer keeps no MultiMesh data).
func instance_transforms(kind: String) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	for xf: Variant in _lists.get(kind, []):
		out.append(xf as Transform3D)
	return out


func _ready() -> void:
	_level = get_parent()
	if _level and _level.has_method(&"map_layout"):
		_layout = _level.call(&"map_layout") as Resource
	_river = _level.get(&"river") as Node if _level and &"river" in _level else null
	build()
	if is_inside_tree():
		get_tree().node_added.connect(_on_node_added)


## Builds (or rebuilds) every MultiMesh. Returns the instances placed.
func build() -> int:
	for c: Node in get_children():
		remove_child(c)
		c.queue_free()
	_lists.clear()
	_mmis.clear()
	counts.clear()
	_hx = MapInfo.half_x()
	_hz = MapInfo.half_z()
	_rng.seed = hash("thornwater_dressing")
	_thin_rng.seed = _rng.seed + 1
	_keep = LOW_DETAIL if MapDressingArt.map_detail() == &"low" else 1.0
	var look := load(LOOK_SCRIPT) as Script if ResourceLoader.exists(LOOK_SCRIPT) else null
	_full_trees = look == null or int(look.call(&"settings_quality")) >= 2
	_read_avoid()
	_water_edges()
	_ford_marsh()
	_rim_and_belt()
	_crown_isle()
	_clear_existing_buildings()
	var total := 0
	for kind: String in _lists:
		var list: Array = _lists[kind]
		if list.is_empty():
			continue
		var mesh := _mesh_for(kind)
		if mesh == null:
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = list.size()
		for i: int in list.size():
			mm.set_instance_transform(i, list[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = kind.get_file().get_basename().to_pascal_case() if kind.begins_with("res://") \
			else kind.trim_prefix("thornwater:").to_pascal_case()
		mmi.multimesh = mm
		mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		if not kind in SHADOW_KINDS:
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if kind in FAR_TREES:
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
		_mmis[kind] = mmi
		counts[kind] = list.size()
		total += list.size()
	return total


func _mesh_for(kind: String) -> Mesh:
	if kind == THICKET or kind == SPIRE:
		if not ResourceLoader.exists(MESHES_SCRIPT):
			return null
		var tm := load(MESHES_SCRIPT) as Script
		return tm.call(&"thicket" if kind == THICKET else &"thorn_spire") as Mesh
	if not ResourceLoader.exists(kind):
		return null
	return load(kind) as Mesh


# ---------------------------------------------------------------- what to keep clear

const SPOT_RADII := {"keep": 9.5, "node": 3.5, "start": 3.0, "point": 4.5, "camp": 5.5, "lair": 5.5, "tavern": 6.5,
	"peddler": 4.5, "post": 5.0, "cache": 2.5, "guild": 5.5}
const SLOT_RADII := {"house": 4.5, "market": 5.5, "natural_hall": 6.5, "rich_hall": 6.5, "tower_natural": 4.0,
	"tower_rich": 4.0}


func _read_avoid() -> void:
	_avoid.clear()
	_roads.clear()
	if _layout == null:
		return
	var spots: Array = _layout.get(&"spots")
	for s: Dictionary in spots:
		var p: Vector3 = s.get("pos", Vector3.ZERO)
		var kind := String(s.get("kind", ""))
		var r := float(SPOT_RADII.get(kind, 0.0))
		if kind == "keep":
			r = float((s.get("props", {}) as Dictionary).get("footprint", 6.0)) + 3.5
		elif kind == "slot":
			r = float(SLOT_RADII.get(String(s.get("sub", "")), 0.0))
		if r > 0.0:
			_avoid.append(Vector3(p.x, p.z, r))
	var roads: Array = _layout.get(&"roads")
	for rd: Dictionary in roads:
		var poly: PackedVector3Array = rd.get("poly", PackedVector3Array())
		_road_half = float(rd.get("width", 5.0)) * 0.5 + 0.8
		for i: int in poly.size() - 1:
			_roads.append(Vector4(poly[i].x, poly[i].z, poly[i + 1].x, poly[i + 1].z))


func _on_road(p: Vector2, pad: float = 0.0) -> bool:
	for s: Vector4 in _roads:
		var q := Geometry2D.get_closest_point_to_segment(p, Vector2(s.x, s.y), Vector2(s.z, s.w))
		if q.distance_to(p) < _road_half + pad:
			return true
	return false


func _blocked(p: Vector2, pad: float = 0.0) -> bool:
	for a: Vector3 in _avoid:
		if Vector2(p.x - a.x, p.y - a.y).length() < a.z + pad:
			return true
	return _on_road(p, pad)


func _crossing_near(p: Vector2, dist: float) -> bool:
	if _river == null or not _river.has_method(&"distance_to_crossing"):
		return false
	return float(_river.call(&"distance_to_crossing", Vector3(p.x, 0.0, p.y))) < dist


func _is_water(p: Vector2) -> bool:
	return _river != null and _river.has_method(&"is_water") and bool(_river.call(&"is_water", Vector3(p.x, 0.0, p.y)))


func _water_dist(p: Vector2, cap: float) -> float:
	if _river == null or not _river.has_method(&"distance_to_water"):
		return INF
	return float(_river.call(&"distance_to_water", Vector3(p.x, 0.0, p.y), cap))


func _add(kind: String, p: Vector3, s: float, yaw: float = -1.0) -> void:
	if _keep < 1.0 and kind != SPIRE and _thin_rng.randf() > _keep:
		return
	if yaw < 0.0:
		yaw = _rng.randf() * TAU
	if not _lists.has(kind):
		_lists[kind] = []
	(_lists[kind] as Array).append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(s, s, s)), p))


static func _h(x: float, y: float) -> float:
	return fposmod(sin(x * 12.9898 + y * 78.233) * 43758.5453, 1.0)


## Smooth 1D value noise (period ~`cell` metres), 0..1.
static func _noise1(t: float, cell: float, seed: float) -> float:
	var x := t / cell
	var i := floorf(x)
	var f := x - i
	f = f * f * (3.0 - 2.0 * f)
	return lerpf(_h(i, seed), _h(i + 1.0, seed), f)


## Smooth 2D value noise, 0..1.
static func _noise2(p: Vector2, cell: float, seed: float) -> float:
	var x := p / cell
	var i := Vector2(floorf(x.x), floorf(x.y))
	var f := x - i
	f = f * f * (Vector2(3.0, 3.0) - 2.0 * f)
	var a := _h(i.x + seed, i.y)
	var b := _h(i.x + 1.0 + seed, i.y)
	var c := _h(i.x + seed, i.y + 1.0)
	var d := _h(i.x + 1.0 + seed, i.y + 1.0)
	return lerpf(lerpf(a, b, f.x), lerpf(c, d, f.x), f.y)


# ---------------------------------------------------------------- water edges

## Reed beds along every river arm and the moat: noise picks the bed runs (about half the bank length).
func _water_edges() -> void:
	if _river == null:
		return
	var hw := float(_river.call(&"half_width")) if _river.has_method(&"half_width") else 2.5
	var lines: Array = _river.call(&"polylines") if _river.has_method(&"polylines") else []
	var arc := 0.0
	for line: Variant in lines:
		var pl := line as PackedVector2Array
		for i: int in pl.size() - 1:
			var a := pl[i]
			var b := pl[i + 1]
			var seg := b - a
			var l := seg.length()
			if l < 0.01:
				continue
			var t_dir := seg / l
			var nrm := Vector2(-t_dir.y, t_dir.x)
			var s := 0.0
			while s < l:
				var c := a + t_dir * s
				for side: float in [-1.0, 1.0]:
					_edge_point(c, nrm * side, hw, arc + s, side)
				s += 0.85
			arc += l
	var moat: Vector4 = _river.call(&"moat") if _river.has_method(&"moat") else Vector4.ZERO
	if moat.z > 0.0:
		var circ := TAU * moat.z
		var steps := int(circ / 0.85)
		for k: int in steps:
			var ang := k * TAU / steps
			var dir := Vector2(cos(ang), sin(ang))
			var c := Vector2(moat.x, moat.y) + dir * moat.z
			_edge_point(c, dir, moat.w, 500.0 + ang * moat.z, 1.0)
			_edge_point(c, -dir, moat.w, 700.0 + ang * moat.z, -1.0)


## One bank sample: centre-line point `c`, outward unit `out`, channel half width `hw`, arc length `s`.
func _edge_point(c: Vector2, out: Vector2, hw: float, s: float, side: float) -> void:
	var bed := _noise1(s, 9.0, 3.1 + side)
	var edge := c + out * hw
	if _crossing_near(edge, 3.2) or absf(edge.x) > _hx - 0.5 or absf(edge.y) > _hz - 0.5:
		return
	var r := _rng.randf()
	# In the water at the trench edge (stems reach 0.5 m below the origin).
	if bed > 0.42:
		var pw := c + out * (hw - _rng.randf_range(0.15, 0.55)) + out.orthogonal() * _rng.randf_range(-0.3, 0.3)
		if _is_water(pw) and r < 0.55:
			_add(REEDS if r < 0.42 else CATTAILS, Vector3(pw.x, WATER_Y, pw.y), _rng.randf_range(0.85, 1.25))
	# On the bank.
	if bed > 0.5:
		var pb := c + out * (hw + _rng.randf_range(0.3, 1.8)) + out.orthogonal() * _rng.randf_range(-0.35, 0.35)
		if not _is_water(pb) and not _blocked(pb, 0.4) and not _crossing_near(pb, 3.0):
			var k := _rng.randf()
			if k < 0.45:
				_add(REEDS, Vector3(pb.x, 0.0, pb.y), _rng.randf_range(0.8, 1.2))
			elif k < 0.7:
				_add(CATTAILS, Vector3(pb.x, 0.0, pb.y), _rng.randf_range(0.8, 1.1))
			elif k < 0.85:
				_add(RUSHES, Vector3(pb.x, 0.0, pb.y), _rng.randf_range(0.8, 1.2))
	# Lily pads on the calm margins where there is no reed bed.
	if bed < 0.35 and _rng.randf() < 0.16:
		var pl := c + out * (hw - _rng.randf_range(0.7, 1.3))
		if _is_water(pl) and not _crossing_near(pl, 4.0):
			_add(LILY, Vector3(pl.x, WATER_Y, pl.y), _rng.randf_range(0.8, 1.2))


## Marsh pockets round the fords: puddles and rushes in a broken ring 4.5-9 m from each ford's centre.
func _ford_marsh() -> void:
	if _river == null or not _river.has_method(&"crossings"):
		return
	for cr: Dictionary in _river.call(&"crossings"):
		if String(cr.get("kind", "")) != "ford":
			continue
		var cv: Variant = cr.get("center", Vector3.ZERO)
		var c := Vector2((cv as Vector3).x, (cv as Vector3).z) if cv is Vector3 else (cv as Vector2)
		var puddles: Array[Vector2] = []
		for k: int in 70:
			var ang := _rng.randf() * TAU
			var rr := _rng.randf_range(4.5, 9.0)
			var p := c + Vector2(cos(ang), sin(ang)) * rr
			if _is_water(p) or _water_dist(p, 1.5) < 1.2 or _crossing_near(p, 1.6) or _blocked(p, 0.6):
				continue
			if puddles.size() < 5 and _rng.randf() < 0.3:
				var ok := true
				for q: Vector2 in puddles:
					if q.distance_to(p) < 2.6:
						ok = false
				if ok and not _crossing_near(p, 2.6) and _water_dist(p, 2.0) > 1.6:
					puddles.append(p)
					_add(PUDDLES, Vector3(p.x, 0.0, p.y), _rng.randf_range(0.75, 1.1))
					continue
			_add(RUSHES if _rng.randf() < 0.7 else CATTAILS, Vector3(p.x, 0.0, p.y), _rng.randf_range(0.75, 1.15))


# ---------------------------------------------------------------- rim + border belt

## Walks the 4 edges: noise gives each stretch an outcrop depth (decor this far into the map, the wood close behind)
## or a bay (open scree, a reed pool now and then, the wood set back).
func _rim_and_belt() -> void:
	var pools: Array[Vector2] = []
	for edge: int in 4:
		var horizontal := edge < 2                    # 0: z = -hz (north), 1: z = +hz, 2: x = -hx, 3: x = +hx
		var sgn := -1.0 if edge % 2 == 0 else 1.0
		var half_along := _hx if horizontal else _hz
		var half_across := _hz if horizontal else _hx
		var t := -half_along - BELT_DEPTH
		while t < half_along + BELT_DEPTH:
			var out := _noise1(t, 13.0, 11.0 + edge * 7.0)    # 0 = bay, 1 = outcrop
			var reach := lerpf(-0.8, RIM_REACH, out)             # decor depth into the map
			var in_span := absf(t) < half_along - 0.5
			# Rim decor (inside the map, last `reach` metres).
			if in_span and reach > 0.4:
				for _rep: int in 2:
					var inset := _rng.randf_range(0.2, reach)
					_rim_piece(horizontal, sgn, t + _rng.randf_range(-1.0, 1.0), half_across - inset)
			# Reed pool in a bay.
			elif in_span and out < 0.18 and _rng.randf() < 0.35:
				var pp := _edge_pos(horizontal, sgn, t, half_across - _rng.randf_range(1.0, 1.6))
				var far_enough := true
				for q: Vector2 in pools:
					if q.distance_to(pp) < 7.0:
						far_enough = false
				if far_enough and not _blocked(pp, 1.2) and _water_dist(pp, 4.0) > 3.0:
					pools.append(pp)
					_add(PUDDLES, Vector3(pp.x, 0.0, pp.y), _rng.randf_range(0.9, 1.15))
					for j: int in 4:
						var q := pp + Vector2(_rng.randf_range(-1.6, 1.6), _rng.randf_range(-1.6, 1.6))
						if absf(q.x) < _hx and absf(q.y) < _hz:
							_add(CATTAILS if j % 2 == 0 else RUSHES, Vector3(q.x, 0.0, q.y), _rng.randf_range(0.8, 1.1))
			# Border belt (outside the map): the wood comes close behind an outcrop and stands back behind a bay.
			var start := lerpf(3.2, 0.5, out)
			var o := start + _rng.randf_range(0.0, 1.2)
			var row := 0
			while o < BELT_DEPTH:
				var p2 := _edge_pos(horizontal, sgn, t + _rng.randf_range(-0.9, 0.9), half_across + o)
				# The corner squares are walked by both edges: only the "horizontal" ones plant there.
				var other := absf(p2.y if not horizontal else p2.x)
				var other_half := _hz if not horizontal else _hx
				if (horizontal or other <= other_half) and _water_dist(p2, 4.0) > 3.5:
					var sp := _species(p2)
					# Full trees only in the front row (the cheap ~110-triangle stand-ins behind it).
					var near := _full_trees and row == 0 and o < BELT_FULL
					var s := _rng.randf_range(0.8, 1.2) * lerpf(1.0, 1.2, clampf(o / BELT_DEPTH, 0.0, 1.0))
					if _rng.randf() < 0.2:
						s *= 1.2
					_add(TREES[sp] if near else FAR_TREES[sp], Vector3(p2.x, 0.0, p2.y), s)
				o += _rng.randf_range(2.4, 3.4) if row == 0 else _rng.randf_range(3.0, 4.4)
				row += 1
			t += _rng.randf_range(2.0, 3.0)


## One rim piece (thicket / gorse / rushes / mossy boulder) at `along`, `across` from the centre line.
func _rim_piece(horizontal: bool, sgn: float, along: float, across: float) -> void:
	var p := _edge_pos(horizontal, sgn, along, across)
	if _blocked(p, 0.3) or _is_water(p) or _water_dist(p, 3.0) <= 2.0:
		return
	var k := _rng.randf()
	if k < 0.42:
		_add(THICKET, Vector3(p.x, 0.0, p.y), _rng.randf_range(0.8, 1.35))
	elif k < 0.62:
		_add(GORSE, Vector3(p.x, 0.0, p.y), _rng.randf_range(0.7, 1.05))
	elif k < 0.85:
		_add(RUSHES, Vector3(p.x, 0.0, p.y), _rng.randf_range(0.8, 1.2))
	elif k < 0.95:
		_add(BOULDER, Vector3(p.x, 0.0, p.y), _rng.randf_range(0.7, 1.2))


func _edge_pos(horizontal: bool, sgn: float, along: float, across: float) -> Vector2:
	return Vector2(along, sgn * across) if horizontal else Vector2(sgn * across, along)


## A species index by cluster noise (stands of one kind, mixed at their borders).
func _species(p: Vector2) -> int:
	var n := _noise2(p + Vector2(_rng.randf_range(-3.0, 3.0), _rng.randf_range(-3.0, 3.0)), 11.0, 4.7)
	var acc := 0.0
	var total := 0.0
	for w: float in SPECIES_W:
		total += w
	for i: int in SPECIES_W.size():
		acc += SPECIES_W[i] / total
		if n <= acc:
			return i
	return SPECIES_W.size() - 1


# ---------------------------------------------------------------- crown isle

## Four thorn spires in the moat, at the angles furthest from every crossing (a river arm's mouth only needs ~16 deg:
## a spire beside the inflow reads as a gate); a spire in a tight gap is smaller. Briars at the pillars.
func _crown_isle() -> void:
	if _river == null or not _river.has_method(&"moat"):
		return
	var moat: Vector4 = _river.call(&"moat")
	if moat.z <= 0.0:
		return
	var centre := Vector2(moat.x, moat.y)
	var crossings: Array[float] = []
	var mouths: Array[float] = []
	for cr: Dictionary in _river.call(&"crossings"):
		var cv: Variant = cr.get("center", Vector3.ZERO)
		var c := Vector2((cv as Vector3).x, (cv as Vector3).z) if cv is Vector3 else (cv as Vector2)
		if c.distance_to(centre) < moat.z + 6.0:
			crossings.append((c - centre).angle())
	for line: Variant in _river.call(&"polylines"):
		var pl := line as PackedVector2Array
		for p: Vector2 in [pl[0], pl[pl.size() - 1]]:
			if p.distance_to(centre) < moat.z + 3.0:
				mouths.append((p - centre).angle())
	var chosen: Array[float] = []
	var clears: Array[float] = []
	for pick: int in 4:
		var best := -1.0
		var best_a := 0.0
		for k: int in 144:
			var a := k * TAU / 144.0
			var mouth_ok := true
			for m: float in mouths:
				if absf(angle_difference(a, m)) < deg_to_rad(16.0):
					mouth_ok = false
			if not mouth_ok:
				continue
			var clear := PI
			for bk: float in crossings:
				clear = minf(clear, absf(angle_difference(a, bk)))
			for ch: float in chosen:
				clear = minf(clear, absf(angle_difference(a, ch)) * 0.5)
			if clear > best:
				best = clear
				best_a = a
		if best < deg_to_rad(24.0):
			break
		chosen.append(best_a)
		clears.append(best)
	for k: int in chosen.size():
		var a := chosen[k]
		var p := centre + Vector2(cos(a), sin(a)) * moat.z
		var room := clampf(remap(clears[k], deg_to_rad(30.0), deg_to_rad(44.0), 0.0, 1.0), 0.0, 1.0)
		_add(SPIRE, Vector3(p.x, WATER_Y, p.y), lerpf(0.85, 1.2, room) + _h(p.x, p.y) * 0.12, a + PI * 0.5)
	# Briars at the feet of the ruin pillars.
	var plan: Variant = _level.get(&"forest_plan") if _level and &"forest_plan" in _level else null
	if plan is Dictionary:
		for pl: Dictionary in (plan as Dictionary).get("pillars", []):
			var pp: Vector3 = pl.get("pos", Vector3.ZERO)
			for j: int in 2:
				var ang := _rng.randf() * TAU
				var q := Vector2(pp.x, pp.z) + Vector2(cos(ang), sin(ang)) * _rng.randf_range(0.45, 0.7)
				if not _is_water(q):
					_add(THICKET, Vector3(q.x, 0.0, q.y), _rng.randf_range(0.45, 0.6))


# ---------------------------------------------------------------- buildings placed on the decor

func _clear_existing_buildings() -> void:
	if not is_inside_tree():
		return
	for b: Node in get_tree().get_nodes_in_group(&"buildings"):
		if b is Node3D and (_level == null or _level.is_ancestor_of(b)):
			clear_area((b as Node3D).global_position, _radius_of(b), false)


func _radius_of(b: Node) -> float:
	return float(b.call(&"target_radius")) + 0.6 if b.has_method(&"target_radius") else 3.0


func _on_node_added(n: Node) -> void:
	if n is Node3D and n.is_in_group(&"buildings") and _level and _level.is_ancestor_of(n):
		_clear_for.call_deferred(n)


func _clear_for(n: Node) -> void:
	if is_instance_valid(n) and n.is_inside_tree():
		clear_area((n as Node3D).global_position, _radius_of(n), true)


## Hides (zero scale) every small decor instance within `r` of `pos`; `live` = also update the MultiMeshes.
func clear_area(pos: Vector3, r: float, live: bool = true) -> int:
	var hidden := 0
	for kind: String in _lists:
		if kind in FIXED_KINDS or kind in TREES or kind in FAR_TREES:
			continue
		var list: Array = _lists[kind]
		for i: int in list.size():
			var xf: Transform3D = list[i]
			if xf.basis.get_scale().x < 0.001:
				continue
			if Vector2(xf.origin.x - pos.x, xf.origin.z - pos.z).length() < r:
				xf.basis = Basis().scaled(Vector3.ZERO)
				list[i] = xf
				hidden += 1
				if live and _mmis.has(kind):
					((_mmis[kind] as MultiMeshInstance3D).multimesh).set_instance_transform(i, xf)
	return hidden
