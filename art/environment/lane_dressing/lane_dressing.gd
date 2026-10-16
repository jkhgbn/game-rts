class_name LaneDressing
extends Node3D
## G-E fixes C, review item 10 (docs/art/ge_review.md, docs/art/ge_fixes_c.md): dressing for the Wave Strike lane maps
## (Ashwind Reach today), whose level draws only its forest / rock blocks. Read from the level's MapLayout:
##   road edges   kerb stones (heath lichen stones) in broken runs along both edges of every road, waystones every
##                ~30 m (alternating sides), banner poles in pairs at each spawn approach and at the quarter lines
##   lane edges   split-rail fence runs, fallen trunks, mossy boulders and gorse along the treelines (|z| 17-20)
##   grass bands  autumn grass / heather patches between the road and the treeline
##   ward line    a ruined shrine on each side of the central plaza (plinths, drums, flagstones, ember moss, a
##                broken pillar), at the lane's edge, not on the march line
##   plazas       burnt grass and charred wood in the layout's ash zones (round the Bastions)
##   muster pads  G-F review 2 item 10: a broken flagstone apron round each pad's plate (the plate itself is drawn by
##                scripts/ui/wave_strike/pad_view.gd) and a banner at each corner, so the pad sits in a dressed yard
## One MultiMeshInstance3D per mesh kind (~14 draws, shadows only on the big pieces). Draw-only: no collider, no
## navmesh effect, nothing on nav layers; tall pieces stay at the lane edges. Kept clear: Bastions, spawn boxes,
## tower / muster slots, rock blocks, the wizard starts. Deterministic (same layout = same dressing). No new shader
## pass, particles or lights (the meshes are the shared nature_mat ones, AutumnSwap recolours them).
## Tiers: nothing at Low (the cost before G1); Map detail Low keeps half of the small scatter kinds (THIN_KINDS).
## Which levels: any level with `lane_for()` and a `layout` (MapLayout) whose path `lane_a` exists (WaveStrikeLevel).
## Hook: LevelLooks.apply (art/environment/level_looks.gd) from GroundDetail._ready; `ensure_for_level` is idempotent.

const NODE_NAME := &"LaneDressing"
const B := "res://art/environment/biomes/"
const M := "res://art/environment/meshes/"
const G := "res://art/environment/ge_props/meshes/"
const KERB := B + "heath/heath_lichen_stones.res"
const GRASS := B + "heath/heath_tall_grass.res"
const HEATHER := B + "heath/heath_heather.res"
const GORSE := B + "heath/heath_gorse.res"
const TRUNK := B + "old_wood/ow_fallen_trunk.res"
const BOULDER := B + "old_wood/ow_moss_boulders.res"
const MONUMENT := B + "ruins/ruins_monuments.res"
const DRUMS := B + "ruins/ruins_drums.res"
const FLAGS := B + "ruins/ruins_flagstones.res"
const EMBER_MOSS := B + "ruins/ruins_ember_moss.res"
const BURNT := B + "ash/ash_burnt_grass.res"
const CHARRED := B + "ash/ash_charred_wood.res"
const WAYSTONE := M + "waystone.res"
const PILLAR := M + "ruin_pillar.res"
const FENCE := G + "lane_fence.res"
const BANNER := G + "lane_banner.res"
## Kinds that cast shadows (the big pieces).
const SHADOW_KINDS: Array[String] = [TRUNK, BOULDER, MONUMENT, WAYSTONE, PILLAR, FENCE, BANNER, CHARRED, GORSE]
const EDGE_Z := 18.6                ## the treeline band's centre (the lane is |z| < 20, forest blocks beyond)
const WAYSTONE_STEP := 30.0
const SHRINE_Z := 14.5              ## shrine centre off the lane line (the plaza is r 9 at the centre)
const GAME_SETTINGS_PATH := "res://scripts/ui/menus/game_settings.gd"
const LOW_DETAIL := 0.5             ## Map detail Low: this share of the small scatter kinds (as MapDressingArt)
## Scatter kinds thinned on Map detail Low (the landmarks, fences, banners and waystones stay whole).
const THIN_KINDS: Array[String] = [KERB, GRASS, HEATHER, GORSE, BURNT, FLAGS, EMBER_MOSS, DRUMS]

## Tests / tools: >= 0 beats the settings (0 Low .. 3 Ultra).
static var quality_override := -1

## G-F review 3 item 5 (docs/art/gf_r3_autumn.md): the lane road and plaza dirt of a lane map, a desaturated
## brown-ochre (the autumn red-brown read as a maroon smear under the old orange fog). Painted on the level's own
## ground material only (a per-level duplicate; a shared .tres is never touched), at every tier (colour only).
const LANE_GROUND := {
	&"road_color": Color(0.43, 0.33, 0.22), &"road_dark": Color(0.30, 0.23, 0.155),
	&"dirt_color": Color(0.41, 0.315, 0.21), &"dirt_dark": Color(0.285, 0.215, 0.145),
}
const GROUND_SHADER := "res://art/environment/ground.gdshader"

var counts := {}                     ## mesh path -> instances placed (tests)
var _level: Node
var _layout: Resource
var _rng := RandomNumberGenerator.new()
var _lists := {}                     ## mesh path -> Array[Transform3D]
var _avoid: Array[Vector3] = []      ## (x, z, radius)
var _avoid_rects: Array[Rect2] = []
var _keep := 1.0                     ## share of THIN_KINDS kept (Map detail Low: LOW_DETAIL)
var _thin_rng := RandomNumberGenerator.new()


static func wants(level: Node) -> bool:
	if level == null or not level.has_method(&"lane_for") or not (&"layout" in level):
		return false
	var lay: Variant = level.get(&"layout")
	if not (lay is Resource) or not (lay as Resource).has_method(&"path"):
		return false
	var lane: Variant = (lay as Resource).call(&"path", "lane_a")
	return lane is PackedVector3Array and not (lane as PackedVector3Array).is_empty()


## The graphics tier (--gfx / headless Low / the saved setting; High when the settings script is missing).
static func settings_quality() -> int:
	if quality_override >= 0:
		return clampi(quality_override, 0, 3)
	if not ResourceLoader.exists(GAME_SETTINGS_PATH):
		return 2
	var gs := load(GAME_SETTINGS_PATH) as Script
	if gs and gs.has_method(&"effective_graphics_quality"):
		return clampi(int(gs.call(&"effective_graphics_quality")), 0, 3)
	return 2


## The level's LaneDressing (created when the level wants one and the tier is Medium+: Low keeps the cost before G1).
static func ensure_for_level(level: Node) -> LaneDressing:
	if level == null or not level.is_inside_tree() or not wants(level):
		return null
	paint_lane_ground(level)
	if settings_quality() < 1:
		return null
	var old := level.get_node_or_null(NodePath(String(NODE_NAME))) as LaneDressing
	if old:
		return old
	var d := LaneDressing.new()
	d.name = NODE_NAME
	level.add_child(d)
	return d


## Sets LANE_GROUND on every level-owned ground-shader material under `level` (shared .tres files skipped).
## Returns how many materials were painted. Idempotent.
static func paint_lane_ground(level: Node) -> int:
	if level == null:
		return 0
	var seen := {}
	var n := 0
	for node: Node in level.find_children("*", "GeometryInstance3D", true, false):
		var gi := node as GeometryInstance3D
		var mats: Array = [gi.material_override]
		var mi := gi as MeshInstance3D
		if mi and mi.mesh:
			for s: int in mi.mesh.get_surface_count():
				mats.append(mi.get_surface_override_material(s))
				mats.append(mi.mesh.surface_get_material(s))
		for m: Variant in mats:
			var sm := m as ShaderMaterial
			if sm == null or seen.has(sm) or sm.shader == null or sm.shader.resource_path != GROUND_SHADER:
				continue
			seen[sm] = true
			var p := sm.resource_path
			if p != "" and not p.contains("::"):
				continue   # a shared file (e.g. the plateau): other maps load it too
			for k: StringName in LANE_GROUND:
				sm.set_shader_parameter(k, LANE_GROUND[k])
			n += 1
	return n


## CPU copies of one kind's instance transforms (mesh path), e.g. for tests: the headless renderer keeps no MultiMesh data.
func instance_transforms(path: String) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	for xf: Variant in _lists.get(path, []):
		out.append(xf as Transform3D)
	return out


func _ready() -> void:
	_level = get_parent()
	_layout = _level.get(&"layout") as Resource
	build()


## Builds (or rebuilds) every MultiMesh. Returns the instances placed.
func build() -> int:
	for c: Node in get_children():
		remove_child(c)
		c.queue_free()
	_rng.seed = hash(String(_layout.get(&"id"))) if _layout else 7
	_thin_rng.seed = _rng.seed + 1
	_keep = LOW_DETAIL if MapDressingArt.map_detail() == &"low" else 1.0
	_lists.clear()
	counts.clear()
	if _layout == null:
		return 0
	_read_avoid()
	_road_edges()
	_lane_edges()
	_grass_bands()
	_shrines()
	_ash_plazas()
	_muster_pads()
	var total := 0
	for path: String in _lists:
		var list: Array = _lists[path]
		if list.is_empty() or not ResourceLoader.exists(path):
			continue
		var mesh := load(path) as Mesh
		if mesh == null:
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = list.size()
		for i: int in list.size():
			mm.set_instance_transform(i, list[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = path.get_file().get_basename().to_pascal_case()
		mmi.multimesh = mm
		mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		if not path in SHADOW_KINDS:
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
		counts[path] = list.size()
		total += list.size()
	return total


# ---------------------------------------------------------------- what to keep clear

func _read_avoid() -> void:
	_avoid.clear()
	_avoid_rects.clear()
	var spots: Array = _layout.get(&"spots")
	for s: Dictionary in spots:
		var p: Vector3 = s.get("pos", Vector3.ZERO)
		var kind := String(s.get("kind", ""))
		var sub := String(s.get("sub", ""))
		match kind:
			"keep":
				var fp := float((s.get("props", {}) as Dictionary).get("footprint", 6.0))
				_avoid.append(Vector3(p.x, p.z, fp + 3.5))
			"start":
				_avoid.append(Vector3(p.x, p.z, 3.0))
			"slot":
				if sub == "muster_spawn":
					_avoid_rects.append(Rect2(p.x - 10.0, p.z - 13.0, 20.0, 26.0))   # the 18 x 24 m spawn box + 1 m
				elif sub == "muster_pad":
					_avoid.append(Vector3(p.x, p.z, 17.0))
				elif sub == "gate":
					_avoid.append(Vector3(p.x, p.z, 5.0))
				elif sub.begins_with("tower_ring"):
					_avoid.append(Vector3(p.x, p.z, 4.5))
	var blocks: Array = _layout.get(&"blocks")
	for b: Dictionary in blocks:
		if String(b.get("kind", "")) == "forest":
			continue
		var c: Vector3 = b["center"]
		var hb: Vector3 = b["half"]
		_avoid_rects.append(Rect2(c.x - hb.x - 1.2, c.z - hb.z - 1.2, hb.x * 2.0 + 2.4, hb.z * 2.0 + 2.4))


func _blocked(p: Vector3, pad: float = 0.0) -> bool:
	if absf(p.x) > MapInfo.half_x() - 1.0 or absf(p.z) > MapInfo.half_z() - 1.0:
		return true
	for a: Vector3 in _avoid:
		if Vector2(p.x - a.x, p.z - a.y).length() < a.z + pad:
			return true
	for r: Rect2 in _avoid_rects:
		if r.grow(pad).has_point(Vector2(p.x, p.z)):
			return true
	return false


func _put(path: String, p: Vector3, s: float, yaw: float = INF, tilt := Vector3.ZERO) -> void:
	if _keep < 1.0 and path in THIN_KINDS and _thin_rng.randf() > _keep:
		return
	if not _lists.has(path):
		_lists[path] = []
	var y := yaw if yaw != INF else _rng.randf() * TAU
	var b := Basis.from_euler(Vector3(tilt.x, y, tilt.z)).scaled(Vector3(s, s, s))
	(_lists[path] as Array).append(Transform3D(b, Vector3(p.x, 0.0, p.z)))


## Every road as segments [a, b, half width] (the layout's roads, else the lane path with an 8 m road).
func _segments() -> Array:
	var out: Array = []
	var roads: Array = _layout.get(&"roads")
	for r: Dictionary in roads:
		var poly: PackedVector3Array = r.get("poly", PackedVector3Array())
		var hw := float(r.get("width", 8.0)) * 0.5
		for i: int in poly.size() - 1:
			out.append([poly[i], poly[i + 1], hw])
	if out.is_empty():
		var lane: PackedVector3Array = _layout.call(&"path", "lane_a")
		for i: int in lane.size() - 1:
			out.append([lane[i], lane[i + 1], 4.0])
	return out


# ---------------------------------------------------------------- the pieces

func _road_edges() -> void:
	var k := 0
	for seg: Array in _segments():
		var a: Vector3 = seg[0]
		var b: Vector3 = seg[1]
		var hw: float = seg[2]
		var d := (b - a)
		var length := d.length()
		if length < 1.0:
			continue
		var u := d / length
		var n := Vector3(-u.z, 0.0, u.x)
		# Kerb stones: broken runs on both edges.
		for side: float in [-1.0, 1.0]:
			var t := 2.0
			var run := 0
			while t < length - 1.0:
				run += 1
				if run > _rng.randi_range(2, 7):   # a gap
					run = 0
					t += _rng.randf_range(3.0, 9.0)
					continue
				var p := a + u * t + n * side * (hw + _rng.randf_range(0.15, 1.4))
				if not _blocked(p, 0.5):
					_put(KERB, p, _rng.randf_range(0.4, 0.8))
					if _rng.randf() < 0.3:   # a second, smaller stone tucked against it
						_put(KERB, p + Vector3(_rng.randf_range(-0.6, 0.6), 0.0, _rng.randf_range(-0.5, 0.5)), _rng.randf_range(0.3, 0.5))
				t += _rng.randf_range(1.0, 3.2)
		# Waystones every ~30 m, alternating sides, facing the road.
		var w := WAYSTONE_STEP * 0.5
		while w < length - 4.0:
			var side2 := 1.0 if (k % 2) == 0 else -1.0
			var p2 := a + u * w + n * side2 * (hw + 1.5)
			if not _blocked(p2, 1.0):
				_put(WAYSTONE, p2, _rng.randf_range(0.95, 1.1), atan2(n.x * side2, n.z * side2) + _rng.randf_range(-0.2, 0.2))
			k += 1
			w += WAYSTONE_STEP
		# Banners: a pair at the outer end of the road (the spawn approach) and a pair at its middle.
		for f: float in [0.12, 0.55]:
			for side3: float in [-1.0, 1.0]:
				var p3 := a + u * (length * f) + n * side3 * (hw + 2.6)
				if not _blocked(p3, 1.0):
					# The cloth hangs along the banner's +X: turn it along the road, toward the lane's middle.
					_put(BANNER, p3, 1.0, atan2(-u.z, u.x) + (PI if side3 < 0.0 else 0.0) + _rng.randf_range(-0.15, 0.15))


func _lane_edges() -> void:
	var lane: PackedVector3Array = _layout.call(&"path", "lane_a")
	if lane.size() < 2:
		return
	var x0 := minf(lane[0].x, lane[lane.size() - 1].x)
	var x1 := maxf(lane[0].x, lane[lane.size() - 1].x)
	for side: float in [-1.0, 1.0]:
		var x := x0 + 6.0
		while x < x1 - 6.0:
			var choice := _rng.randf()
			var z := side * (EDGE_Z + _rng.randf_range(-0.8, 0.8))
			var p := Vector3(x, 0.0, z)
			if choice < 0.42:
				# A fence run of 2-4 spans along the treeline.
				var spans := _rng.randi_range(2, 4)
				for s: int in spans:
					var q := Vector3(x + s * 3.25, 0.0, z + _rng.randf_range(-0.25, 0.25))
					if _blocked(q, 1.8):
						continue
					_put(FENCE, q, _rng.randf_range(0.95, 1.08), _rng.randf_range(-0.08, 0.08) + (PI if side < 0.0 else 0.0))
				x += spans * 3.25 + _rng.randf_range(4.0, 9.0)
				continue
			if not _blocked(p, 1.5):
				if choice < 0.58:
					_put(TRUNK, p + Vector3(0, 0, side * 0.8), _rng.randf_range(0.85, 1.1), _rng.randf_range(-0.4, 0.4))
				elif choice < 0.76:
					_put(BOULDER, p, _rng.randf_range(0.7, 1.05))
				# Gorse and heather at the foot of every piece.
				for i: int in _rng.randi_range(2, 4):
					var g := p + Vector3(_rng.randf_range(-2.4, 2.4), 0.0, _rng.randf_range(-1.0, 1.0))
					if not _blocked(g, 0.5):
						_put(GORSE if _rng.randf() < 0.45 else HEATHER, g, _rng.randf_range(0.8, 1.15))
			x += _rng.randf_range(5.0, 9.0)


func _grass_bands() -> void:
	var lane: PackedVector3Array = _layout.call(&"path", "lane_a")
	if lane.size() < 2:
		return
	var x0 := minf(lane[0].x, lane[lane.size() - 1].x)
	var x1 := maxf(lane[0].x, lane[lane.size() - 1].x)
	var patches := int((x1 - x0) / 1.4)
	for i: int in patches:
		var c := Vector3(_rng.randf_range(x0, x1), 0.0, _rng.randf_range(6.5, 17.5) * (1.0 if _rng.randf() < 0.5 else -1.0))
		if _blocked(c, 1.0):
			continue
		var kind := GRASS if _rng.randf() < 0.7 else HEATHER
		for j: int in _rng.randi_range(3, 7):
			var p := c + Vector3(_rng.randfn(0.0, 1.1), 0.0, _rng.randfn(0.0, 1.1))
			if absf(p.z) > 5.5 and not _blocked(p, 0.3):
				_put(kind, p, _rng.randf_range(0.75, 1.2))
	# A few charred snags and burnt patches in the outer bands (the Ashwind: old fires along the road).
	for i: int in int((x1 - x0) / 9.0):
		var q := Vector3(_rng.randf_range(x0, x1), 0.0, _rng.randf_range(11.0, 16.5) * (1.0 if _rng.randf() < 0.5 else -1.0))
		if _blocked(q, 2.0):
			continue
		if _rng.randf() < 0.45:
			_put(CHARRED, q, _rng.randf_range(0.8, 1.05))
		for j: int in _rng.randi_range(4, 9):
			var b := q + Vector3(_rng.randfn(0.0, 1.4), 0.0, _rng.randfn(0.0, 1.0))
			if absf(b.z) > 5.5 and not _blocked(b, 0.3):
				_put(BURNT, b, _rng.randf_range(0.8, 1.15))


## A ruined shrine on both sides of the central plaza (the ward line), at the lane's edge.
func _shrines() -> void:
	var lane: PackedVector3Array = _layout.call(&"path", "lane_a")
	if lane.size() < 2:
		return
	var mid := (lane[0] + lane[lane.size() - 1]) * 0.5
	for side: float in [-1.0, 1.0]:
		var c := Vector3(mid.x, 0.0, mid.z + side * SHRINE_Z)
		var face := 0.0 if side > 0.0 else PI
		# Paving, then the plinths in a broken arc facing the plaza, a pillar at the back, drums and ember moss.
		for i: int in 12:
			var p := c + Vector3(_rng.randf_range(-3.2, 3.2), 0.0, _rng.randf_range(-2.0, 2.0))
			_put(FLAGS, p, _rng.randf_range(0.85, 1.2))
		for i: int in 3:
			var a := deg_to_rad(-50.0 + i * 50.0) + (PI * 0.5 if side < 0.0 else -PI * 0.5)
			var p2 := c + Vector3(cos(a) * 2.7, 0.0, sin(a) * 2.2 * -side)
			_put(MONUMENT, p2, _rng.randf_range(0.95, 1.15), face + _rng.randf_range(-0.3, 0.3))
		_put(PILLAR, c + Vector3(_rng.randf_range(-1.0, 1.0), 0.0, side * 2.6), 0.8, _rng.randf() * TAU)
		for i: int in 5:
			var p3 := c + Vector3(_rng.randf_range(-3.6, 3.6), 0.0, _rng.randf_range(-1.5, 2.6) * side)
			_put(DRUMS, p3, _rng.randf_range(0.85, 1.1))
		for i: int in 8:
			var p4 := c + Vector3(_rng.randf_range(-3.5, 3.5), 0.0, _rng.randf_range(-2.2, 2.2))
			_put(EMBER_MOSS, p4, _rng.randf_range(0.8, 1.2))


## Burnt grass and charred wood in the layout's ash zones (outside the kept-clear areas).
func _ash_plazas() -> void:
	var zones: Array = _layout.get(&"zones")
	for z: Dictionary in zones:
		if String(z.get("biome", "")) != "ash":
			continue
		var c: Vector3 = z.get("center", Vector3.ZERO)
		var r1 := float(z.get("r1", 10.0))
		var r0 := float(z.get("r0", 0.0))
		var n := int(PI * (r1 * r1 - r0 * r0) / 100.0 * 30.0)
		for i: int in n:
			var a := _rng.randf() * TAU
			var r := sqrt(_rng.randf_range(maxf(r0, 4.2) ** 2, r1 * r1))   # outside the Bastion body (half footprint 3)
			var p := c + Vector3(cos(a) * r, 0.0, sin(a) * r)
			if absf(p.x) > MapInfo.half_x() - 1.0 or absf(p.z) > MapInfo.half_z() - 1.0:
				continue
			_put(BURNT, p, _rng.randf_range(0.8, 1.25))   # low tufts: allowed in the spawn box (units walk through)
		for i: int in int(r1 * 0.6):
			var a2 := _rng.randf() * TAU
			var r2 := _rng.randf_range(maxf(r0, r1 * 0.55), r1)
			var p2 := c + Vector3(cos(a2) * r2, 0.0, sin(a2) * r2)
			if not _blocked(p2, 1.0):
				_put(CHARRED, p2, _rng.randf_range(0.85, 1.1))


## The Muster Pad yards (G-F r2 item 10): around every `slot sub=muster_pad` (MusterPad: COLS x ROWS cells of CELL m,
## + the view's 1 m rim; rows along the lane direction), a broken flagstone apron 0.4-2.2 m outside the rim, a few kerb
## stones, and a banner at each corner facing out. The plate's own look is the ui view's (see docs/art/gf_r2_autumn.md).
func _muster_pads() -> void:
	var spots: Array = _layout.get(&"spots")
	var he := Vector2(MusterPad.ROWS * MusterPad.CELL * 0.5 + 1.0, MusterPad.COLS * MusterPad.CELL * 0.5 + 1.0)
	for sp: Dictionary in spots:
		if String(sp.get("kind", "")) != "slot" or String(sp.get("sub", "")) != "muster_pad":
			continue
		var c: Vector3 = sp.get("pos", Vector3.ZERO)
		# The lane runs along x (Ashwind): the pad's forward axis is x, its lateral axis z.
		var perim := 2.0 * (he.x + he.y) * 2.0
		var t := _rng.randf_range(0.0, 1.0)
		while t < perim:
			var q := _rim_point(t, he)
			var out := _rim_normal(t, he)
			var d := _rng.randf_range(0.4, 2.2)
			var p := c + Vector3(q.x + out.x * d, 0.0, q.y + out.y * d)
			if not _off_map(p):
				_put(FLAGS, p, _rng.randf_range(0.8, 1.15))
				if _rng.randf() < 0.18:
					_put(KERB, p + Vector3(out.x, 0.0, out.y) * _rng.randf_range(0.8, 1.4), _rng.randf_range(0.45, 0.75))
			t += _rng.randf_range(1.0, 2.6) if _rng.randf() > 0.12 else _rng.randf_range(3.0, 5.0)   # a broken run
		for sx: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				var b := c + Vector3(sx * (he.x + 1.6), 0.0, sz * (he.y + 0.6))
				b.z = clampf(b.z, -MapInfo.half_z() + 1.3, MapInfo.half_z() - 1.3)   # Ashwind: the outer yard edge is the map edge
				if not _off_map(b):
					# The cloth hangs along +X: point it away from the pad along the lane axis.
					_put(BANNER, b, 1.0, (0.0 if sx > 0.0 else PI) + _rng.randf_range(-0.15, 0.15))


## A point on the rim rectangle (half extents `he`, x = forward, y = lateral) at arc length `t` (clockwise from +x, -y).
static func _rim_point(t: float, he: Vector2) -> Vector2:
	var w := he.x * 2.0
	var h := he.y * 2.0
	t = fposmod(t, 2.0 * (w + h))
	if t < h:
		return Vector2(he.x, -he.y + t)
	t -= h
	if t < w:
		return Vector2(he.x - t, he.y)
	t -= w
	if t < h:
		return Vector2(-he.x, he.y - t)
	t -= h
	return Vector2(-he.x + t, -he.y)


static func _rim_normal(t: float, he: Vector2) -> Vector2:
	var w := he.x * 2.0
	var h := he.y * 2.0
	t = fposmod(t, 2.0 * (w + h))
	if t < h:
		return Vector2(1, 0)
	if t < h + w:
		return Vector2(0, 1)
	if t < 2.0 * h + w:
		return Vector2(-1, 0)
	return Vector2(0, -1)


func _off_map(p: Vector3) -> bool:
	return absf(p.x) > MapInfo.half_x() - 1.0 or absf(p.z) > MapInfo.half_z() - 1.0
