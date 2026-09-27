extends SceneTree
## Task 12.V4 (map-fill.md 2.2 and section 10): bakes the road bridges, ford dressing and Crown Steps of the river
## Hollowmere. Run once (headless is fine), then import:
##   $GODOT --headless --path . -s res://art/environment/bridges/build_crossings.gd --quit-after 600
##   $GODOT --headless --path . --import
## Writes art/environment/bridges/meshes/<name>_body.res, <name>_foam.res and the scenes road_bridge.tscn,
## ford_stones.tscn, crown_steps.tscn. Format (same as the waystones / env props, art/environment/build_env.gd):
## ONE painted surface with the shared art/environment/env_painted_mat.tres (colour blocks in COLOR.rgb, height
## gradient in COLOR.a, UV = (sway weight, height above the part's contact line), flat shaded, indexed); the bridge
## lanterns are a second surface with the shared lantern_glow_mat.tres (1.0, 0.8, 0.4); the white water is a
## separate mesh with crossing_foam_mat.tres. 0 lights, no colliders (the navmesh carve does the work). The scene
## roots carry crossing_art.gd (CrossingArt: `kind`, place_crossing(), basis_for()).
##
## Frames (the placer turns the root; see each _build_* comment and docs/handoff/for-systems-coder.md):
##   road_bridge   origin = the crossing centre on the road at ground level (y 0); local +Z along the road pointing
##                 east, X across. Deck 9 m long, 5.2 m of planks (ring road 3 m + margin; the 6 m navmesh gap minus
##                 the 0.5 m agent radius stays on the planks), top at y 0.05. The two stone piers and the bank
##                 abutments are baked skewed 12.8 deg to follow the river under Saltgate Bridge (ring road vs river
##                 of map-fill.md 2.1) and the pier wakes trail downstream (south). Millstone Bridge is the point
##                 mirror: the same road and river axes and the same southward flow, so it takes the SAME yaw.
##   ford_stones   origin = the ford centre (y 0); local +Z DOWNSTREAM (the flow), X across the channel. Ford circle
##                 r 3.5 over the 5 m channel: the sill stones and the rapids sit where the circle meets the trench.
##   crown_steps   origin = the steps centre (y 0); local +Z AWAY from the Crown Isle centre (the isle is at local
##                 (0, 0, -12.75), as for the lane bridge), X along the moat. Circle r 3.0 over the 3.5 m moat (water
##                 r 11.0 - 14.5 around the isle).

const DIR := "res://art/environment/bridges/"
const MESH_DIR := "res://art/environment/bridges/meshes/"
const PAINTED_MAT := "res://art/environment/env_painted_mat.tres"
const GLOW_MAT := "res://art/environment/lantern_glow_mat.tres"
const FOAM_MAT := "res://art/environment/bridges/crossing_foam_mat.tres"

# map-fill.md 2.1 / 2.2.
const WATER_Y := -0.35
const FOAM_Y := -0.335
const FILM_TOP := 0.045           # just over the ford film (12.V1 FILM_Y 0.02)
const RIVER_HALF := 2.5
const ROAD_DIR := Vector2(45.0, -1.0)    # ring segment nw2 (-44, -48) -> n_door (1, -49), world x/z
const RIVER_DIR := Vector2(6.0, 24.0)    # N0 (-15, -62) -> N2 (-9, -38): the flow (north -> south) at N1
const DECK_HALF_W := 2.6
const DECK_HALF_L := 4.5
const DECK_TOP := 0.05
const PIER_OFFSET := 0.85         # piers at +-0.85 m from the river centre line (spans 1.65 / 1.7 / 1.65 m)
const FORD_R := 3.5
const STEPS_R := 3.0
const MOAT_R := 12.75
const MOAT_IN := 11.0
const MOAT_OUT := 14.5

# Palette (sRGB): neutral stone and timber like the trading post / waystones; pale ruin stone for the Crown Steps.
const STONE := Color(0.50, 0.48, 0.44)
const STONE_L := Color(0.60, 0.57, 0.52)
const STONE_D := Color(0.35, 0.33, 0.31)
const STONE_WET := Color(0.26, 0.27, 0.25)
const TIMBER := Color(0.31, 0.21, 0.13)
const WOOD := Color(0.45, 0.33, 0.22)
const WOOD_OLD := Color(0.45, 0.41, 0.34)
const POST := Color(0.40, 0.29, 0.18)
const POLE := Color(0.46, 0.38, 0.27)
const HEMP := Color(0.70, 0.59, 0.38)
const IRON := Color(0.21, 0.21, 0.23)
const MOSS := Color(0.28, 0.42, 0.16)
const RAG_RED := Color(0.74, 0.22, 0.14)
const RAG_OCHRE := Color(0.86, 0.60, 0.22)
const RUIN := Color(0.57, 0.55, 0.53)
const RUIN_L := Color(0.66, 0.64, 0.61)
const RUIN_D := Color(0.38, 0.37, 0.37)
const RUIN_WET := Color(0.30, 0.31, 0.31)
const BARK := Color(0.36, 0.28, 0.20)
const BARK_L := Color(0.55, 0.47, 0.36)
const WHITE := Color(1.0, 1.0, 1.0)


class Surf:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var uv := PackedVector2Array()
	var uv2 := PackedVector2Array()


var _conv: float = 1.0
var _rng := RandomNumberGenerator.new()
var _s: Surf                  # painted (or glow) target of _tri
var _f: Surf                  # foam target
var _contact: float = 0.0     # UV.y = y - _contact (the painted shader's dark contact band sits at UV.y 0)
var _sway: float = 0.0        # UV.x (wind weight, only the ford rags)


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MESH_DIR))
	_detect_winding()
	_build_bridge()
	_build_ford()
	_build_steps()
	quit()


# --- Road bridge -------------------------------------------------------------------------------------------------

## Saltgate / Millstone Bridge. Timber plank deck with dark edge beams on two stone piers (pointed cutwaters with
## sloped cap stones poking out both sides of the deck), stone abutments down the trench walls, stone newels at the
## four corners, rope rails on timber posts, and a lantern post on two diagonal newels (glow (1.0, 0.8, 0.4)).
## Foam: bow waves around the piers and two wakes behind each.
func _build_bridge() -> void:
	_rng.seed = 12041
	var body := Surf.new()
	var glow := Surf.new()
	_f = Surf.new()
	_s = body
	# The river in the bridge's frame (flow direction, across direction): baked skew.
	var yaw: float = atan2(ROAD_DIR.x, ROAD_DIR.y)
	var ax := Vector2(cos(yaw), -sin(yaw))
	var az := Vector2(sin(yaw), cos(yaw))
	var fw: Vector2 = RIVER_DIR.normalized()
	var fl := Vector3(fw.dot(ax), 0.0, fw.dot(az)).normalized()
	var nr: Vector3 = fl.cross(Vector3.UP).normalized()
	var riv := Basis(fl, Vector3.UP, nr)
	print("road bridge: river skew %.1f deg" % rad_to_deg(atan2(absf(fl.z), absf(fl.x))))

	# Abutments: three courses of blocks along each bank line, from the lip down under the water.
	_contact = WATER_Y
	for s: float in [-1.0, 1.0]:
		# Top course just under the ground (only its lip shows inside the river cut, never a slab on the grass).
		var courses: Array = [[-0.02, -0.19], [-0.19, -0.42], [-0.42, -1.1]]
		for k: int in courses.size():
			var top: float = courses[k][0]
			var bot: float = courses[k][1]
			var t: float = -3.7 + 0.37 * float(k)
			while t < 3.7:
				var t1: float = minf(t + _rng.randf_range(0.65, 1.05), 3.7)
				if 3.7 - t1 < 0.3:
					t1 = 3.7
				var a0: float = RIVER_HALF - 0.12 + _rng.randf_range(0.0, 0.05) + 0.04 * float(k)
				var a1: float = RIVER_HALF + 0.7
				var yj: float = _rng.randf_range(-0.012, 0.0) if k == 0 else 0.0
				var ctr: Vector3 = fl * ((t + t1) * 0.5) + nr * (s * (a0 + a1) * 0.5) \
					+ Vector3(0.0, (top + bot) * 0.5 + yj, 0.0)
				var half := Vector3((t1 - t) * 0.5 - 0.025, (top - bot) * 0.5, (a1 - a0) * 0.5)
				var val: float = _rng.randf_range(0.9, 1.08)
				var side: Color = (STONE if k == 0 else STONE_WET.lerp(STONE_D, 0.5)) * val
				var topc: Color = STONE_L * val
				if k == 0 and _rng.randf() < 0.3:
					topc = topc.lerp(MOSS, 0.55)
				_box(ctr, riv, half, side, topc)
				t = t1

	# Piers: pointed on both ends (cutwaters), wet dark below, stone above, a lighter cap course, sloped cap stones
	# on the tips (the part that shows beyond the deck edges).
	for s: float in [-1.0, 1.0]:
		var pc: Vector3 = nr * (s * PIER_OFFSET)
		var hexp: Array[Vector2] = [Vector2(-3.3, 0.0), Vector2(-2.72, -0.36), Vector2(2.72, -0.36),
			Vector2(3.3, 0.0), Vector2(2.72, 0.36), Vector2(-2.72, 0.36)]
		_contact = WATER_Y
		_stone(pc, _outline(hexp, fl, nr, 1.0, 1.0), -1.1, -0.3, 0.0, STONE_WET, STONE_WET)
		_stone(pc, _outline(hexp, fl, nr, 1.0, 1.0), -0.3, -0.1, 0.0, STONE, STONE)
		_stone(pc, _outline(hexp, fl, nr, 1.03, 1.18), -0.1, -0.03, 0.02, STONE_L, STONE_L)
		for e: float in [-1.0, 1.0]:
			var b0: Vector3 = pc + fl * (e * 2.7) + nr * -0.43 + Vector3(0.0, -0.03, 0.0)
			var b1: Vector3 = pc + fl * (e * 3.42) + Vector3(0.0, -0.03, 0.0)
			var b2: Vector3 = pc + fl * (e * 2.7) + nr * 0.43 + Vector3(0.0, -0.03, 0.0)
			# Wedge cap: a sloped ridge from the tip back under the deck edge (reads as a cutwater, not a pyramid).
			var r0: Vector3 = pc + fl * (e * 3.3) + Vector3(0.0, 0.03, 0.0)
			var r1: Vector3 = pc + fl * (e * 2.55) + Vector3(0.0, 0.1, 0.0)
			var capc: Color = STONE.lerp(MOSS, 0.3) if e * s > 0.0 else STONE
			_tri(b0, b1, r0, (b0 + b1) * 0.5 - pc + Vector3.UP * 0.6, capc)
			_tri(b1, b2, r0, (b1 + b2) * 0.5 - pc + Vector3.UP * 0.6, capc * 0.92)
			_quad(b0, r0, r1, pc + fl * (e * 2.55) + nr * -0.43 + Vector3(0.0, -0.03, 0.0),
				-nr + Vector3.UP * 0.8, capc)
			_quad(b2, r0, r1, pc + fl * (e * 2.55) + nr * 0.43 + Vector3(0.0, -0.03, 0.0),
				nr + Vector3.UP * 0.8, capc * 0.92)

	# Deck: 30 planks across the road, a little uneven, a few old grey ones.
	_contact = -1.0
	var n_pl: int = 30
	var pitch: float = DECK_HALF_L * 2.0 / float(n_pl)
	for i: int in n_pl:
		var zc: float = -DECK_HALF_L + (float(i) + 0.5) * pitch
		var top: float = DECK_TOP - _rng.randf_range(0.0, 0.018)
		var hx: float = DECK_HALF_W + _rng.randf_range(-0.07, 0.03)
		var b := Basis(Vector3.UP, _rng.randf_range(-0.014, 0.014))
		var col: Color = WOOD * _rng.randf_range(0.82, 1.1)
		if _rng.randf() < 0.13:
			col = WOOD_OLD * _rng.randf_range(0.92, 1.05)
		_box(Vector3(_rng.randf_range(-0.05, 0.05), top - 0.05, zc), b, Vector3(hx, 0.05, pitch * 0.5 - 0.02),
			col * 0.72, col)
	# Edge beams (a 5 cm curb over the planks) and the sleepers the planks rest on at both ends.
	for s: float in [-1.0, 1.0]:
		_box(Vector3(s * 2.71, -0.08, 0.0), Basis(), Vector3(0.09, 0.18, 4.62), TIMBER, TIMBER * 1.2)
	for e: float in [-1.0, 1.0]:
		_box(Vector3(0.0, -0.1, e * 4.38), Basis(), Vector3(2.62, 0.06, 0.13), TIMBER, TIMBER)

	# Newels: stone blocks at the four corners with a cap slab and a low pyramid.
	_contact = 0.0
	for s: float in [-1.0, 1.0]:
		for e: float in [-1.0, 1.0]:
			var nb := Basis(Vector3.UP, _rng.randf_range(-0.05, 0.05))
			var c := Vector3(s * 2.76, 0.35, e * 4.45)
			_box(c, nb, Vector3(0.26, 0.45, 0.26), STONE, STONE_L)
			_box(c + Vector3(0.0, 0.5, 0.0), nb, Vector3(0.31, 0.05, 0.31), STONE_L * 0.92, STONE_L)
			_pyramid(c + Vector3(0.0, 0.55, 0.0), nb, 0.24, 0.12, STONE_L)
			# Two mossy stones at the foot, on the bank side.
			_rock(c + Vector3(s * 0.3, -0.33, e * 0.18), 0.13, 0.6, STONE_D, 0.8)

	# Rope-rail posts (timber, leaning a little) and the ropes, sagging between them.
	var rails: Array = []
	for s: float in [-1.0, 1.0]:
		var pts: Array[Vector3] = [Vector3(s * 2.74, 0.72, -4.45 + 0.27)]
		for z: float in [-3.0, -1.0, 1.0, 3.0]:
			var lean := Basis(Vector3.BACK, _rng.randf_range(-0.045, 0.045)) \
				* Basis(Vector3.RIGHT, _rng.randf_range(-0.035, 0.035))
			var c := Vector3(s * 2.72, 0.40, z)
			_contact = 0.05
			_box(c, lean, Vector3(0.1, 0.66, 0.1), POST, POST * 1.15)
			_pyramid(c + lean * Vector3(0.0, 0.66, 0.0), lean, 0.1, 0.09, POST * 1.15)
			pts.append(c + lean * Vector3(0.0, 0.54, 0.0))
		pts.append(Vector3(s * 2.74, 0.72, 4.45 - 0.27))
		rails.append(pts)
	_contact = -0.2
	for pts: Array in rails:
		var line := PackedVector3Array()
		for j: int in pts.size() - 1:
			var a: Vector3 = pts[j]
			var b: Vector3 = pts[j + 1]
			var sag: float = 0.055 * a.distance_to(b)
			for k: int in 7:
				if j > 0 and k == 0:
					continue
				var u: float = float(k) / 6.0
				line.append(a.lerp(b, u) - Vector3(0.0, sag * 4.0 * u * (1.0 - u), 0.0))
		_tube(line, 0.048, 5, HEMP, false, false)
		# A wrap of rope around each post.
		for j: int in range(1, pts.size() - 1):
			var p: Vector3 = pts[j]
			_box(p, Basis(), Vector3(0.125, 0.05, 0.125), HEMP * 0.9, HEMP)

	# Lantern posts on two diagonal newels, the arm reaching out over the bank (never over the road).
	for se: Array in [[1.0, 1.0], [-1.0, -1.0]]:
		_lantern_post(float(se[0]), float(se[1]), glow)
	_s = body

	# Foam: bow wave around each pier (bigger upstream: the flow runs along +fl) and two wakes behind it.
	for s: float in [-1.0, 1.0]:
		var pc: Vector3 = nr * (s * PIER_OFFSET)
		var rows: Array = []
		var env: Array = []
		var across := PackedFloat32Array([0.0, 0.4, 0.9])
		var widths: Array = [[0.03, 0.03, 0.03], [0.6, 0.3, 0.22], [1.1, 0.62, 0.45]]
		var envs: Array = [1.0, 0.5, 0.0]
		for r: int in 3:
			var w: Array = widths[r]
			var hexo: Array[Vector2] = [Vector2(-3.3 - float(w[0]), 0.0), Vector2(-2.72, -0.36 - float(w[1])),
				Vector2(2.72, -0.36 - float(w[1])), Vector2(3.3 + float(w[2]), 0.0), Vector2(2.72, 0.36 + float(w[1])),
				Vector2(-2.72, 0.36 + float(w[1])), Vector2(-3.3 - float(w[0]), 0.0)]
			var row := PackedVector3Array()
			var er := PackedFloat32Array()
			for j: int in hexo.size() - 1:
				for k: int in 4:
					var q: Vector2 = hexo[j].lerp(hexo[j + 1], float(k) / 4.0)
					row.append(pc + fl * q.x + nr * q.y + Vector3(0.0, FOAM_Y, 0.0))
					# Upstream (q.x < 0) foams more.
					er.append(float(envs[r]) * (1.0 if q.x < 0.0 else 0.75))
			row.append(row[0])
			er.append(er[0])
			rows.append(row)
			env.append(er)
		_foam(rows, across, env, 0.0, 1.0)
		for side: float in [-1.0, 1.0]:
			var d: Vector3 = fl.rotated(Vector3.UP, side * 0.28)
			var perp: Vector3 = d.cross(Vector3.UP).normalized()
			var tip: Vector3 = pc + fl * 3.3 + Vector3(0.0, FOAM_Y + 0.002, 0.0)
			var w0 := PackedVector3Array()
			var w1 := PackedVector3Array()
			var w2 := PackedVector3Array()
			var e1 := PackedFloat32Array()
			var e0 := PackedFloat32Array()
			for j: int in 8:
				var u: float = float(j) / 7.0
				var c: Vector3 = tip + d * (0.05 + 1.9 * u)
				var hw: float = 0.1 + 0.12 * u
				w0.append(c - perp * hw)
				w1.append(c)
				w2.append(c + perp * hw)
				e1.append(0.8 * (1.0 - u) * smoothstep(0.0, 0.2, u + 0.05))
				e0.append(0.0)
			_foam([w0, w1, w2], PackedFloat32Array([-0.15, 0.0, 0.15]), [e0, e1, e0], 0.0, 2.0)

	var mesh := ArrayMesh.new()
	_commit_painted(mesh, body, -0.9, 1.7, load(PAINTED_MAT) as Material)
	_commit_painted(mesh, glow, -0.9, 1.7, load(GLOW_MAT) as Material)
	var foam := ArrayMesh.new()
	_commit_foam(foam, _f)
	_save("road_bridge", "RoadBridge", &"bridge_road", mesh, foam, true)


## A lantern post standing on the newel at (s * 2.76, e * 4.45): timber pole, an arm reaching out over the bank
## (+x for s = 1) with a brace, an iron lantern hanging from it (its glass is the glow surface).
func _lantern_post(s: float, e: float, glow: Surf) -> void:
	var base := Vector3(s * 2.76, 0.9, e * 4.45)
	_contact = 0.9
	_box(base + Vector3(0.0, 0.93, 0.0), Basis(), Vector3(0.085, 0.93, 0.085), POST, POST * 1.1)
	_pyramid(base + Vector3(0.0, 1.86, 0.0), Basis(), 0.11, 0.12, IRON)
	var arm_y: float = base.y + 1.68
	_beam(Vector3(s * 2.70, arm_y, base.z), Vector3(s * 3.62, arm_y, base.z), 0.055, POST * 1.1)
	_beam(Vector3(s * 2.80, arm_y - 0.45, base.z), Vector3(s * 3.18, arm_y - 0.02, base.z), 0.04, POST)
	# The lantern is chunky (glass 0.36 x 0.46 m) so it reads as a glow point from the RTS camera.
	var lx: float = s * 3.48
	var ly: float = arm_y - 0.055
	_contact = 1.8
	_box(Vector3(lx, ly - 0.07, base.z), Basis(), Vector3(0.03, 0.07, 0.03), IRON, IRON)
	# Roof: rim + pyramid; base plate; four corner bars.
	_box(Vector3(lx, ly - 0.2, base.z), Basis(), Vector3(0.27, 0.035, 0.27), IRON, IRON * 1.3)
	_pyramid(Vector3(lx, ly - 0.165, base.z), Basis(), 0.26, 0.2, IRON * 1.2)
	_box(Vector3(lx, ly - 0.72, base.z), Basis(), Vector3(0.23, 0.04, 0.23), IRON, IRON * 1.2)
	_pyramid(Vector3(lx, ly - 0.76, base.z), Basis(Vector3.RIGHT, PI), 0.12, 0.1, IRON)
	for cx: float in [-1.0, 1.0]:
		for cz: float in [-1.0, 1.0]:
			_box(Vector3(lx + cx * 0.19, ly - 0.46, base.z + cz * 0.19), Basis(), Vector3(0.03, 0.23, 0.03),
				IRON, IRON)
	var keep: Surf = _s
	_s = glow
	_box(Vector3(lx, ly - 0.46, base.z), Basis(), Vector3(0.18, 0.23, 0.18), WHITE, WHITE, true)
	_s = keep


# --- Ford --------------------------------------------------------------------------------------------------------

## Reed Ford / Willow Ford dressing (local +Z downstream). A line of flat stepping stones across the channel on the
## upstream half (1.85 m upstream: the Mirefang nest of 12.V24 keeps the centre, r 1.6 free), loose cobbles, a sill
## of mossy boulders on the upstream rim, three lip stones on the downstream rim, a lodged driftwood log, four marker
## poles on the banks with red / ochre
## rags and a little cairn at each foot. Foam: rapids where the trench meets the ford (foam against the upstream
## sill, a thin spill line onto the film, a short cascade off the downstream lip and the churn below it).
func _build_ford() -> void:
	_rng.seed = 12042
	var body := Surf.new()
	_f = Surf.new()
	_s = body
	# Stepping stones.
	_contact = -0.2
	# Irregular spacing and sizes (a worn, hand-laid line, not a row of coins), wet darker tops, some moss, a small
	# companion stone beside a few of them.
	var sx: float = -3.15
	while sx < 3.1:
		var r: float = _rng.randf_range(0.2, 0.34)
		sx += r
		var x: float = sx
		var z: float = -1.85 + 0.18 * sin(x * 1.1 + 0.4) + _rng.randf_range(-0.12, 0.12)
		var on_bank: bool = absf(x) > RIVER_HALF - 0.1
		var top: float = _rng.randf_range(0.07, 0.09) if on_bank else _rng.randf_range(0.1, 0.155)
		var topc: Color = STONE_D.lerp(STONE, _rng.randf_range(0.25, 0.8))
		if _rng.randf() < 0.4:
			topc = topc.lerp(MOSS, _rng.randf_range(0.35, 0.65))
		_stone(Vector3(x, 0.0, z), _blob(9, r, _rng.randf_range(1.0, 1.3)), -0.3, top, 0.06, STONE_WET, topc,
			Vector2(_rng.randf_range(-0.05, 0.05), _rng.randf_range(-0.05, 0.05)), 0.7)
		if _rng.randf() < 0.3:
			var side: float = 1.0 if _rng.randf() < 0.5 else -1.0
			var r2: float = r * _rng.randf_range(0.45, 0.6)
			_stone(Vector3(x + _rng.randf_range(-0.1, 0.1), 0.0, z + side * (r + r2 + 0.04)), _blob(8, r2, 1.1), -0.3,
				top - 0.03, 0.04, STONE_WET, STONE_D.lerp(STONE, 0.4), Vector2.ZERO, 0.7)
		sx += r + _rng.randf_range(0.14, 0.3)
	# Loose cobbles in the film (not in the middle: the nest).
	var placed: int = 0
	var tries: int = 0
	while placed < 16 and tries < 400:
		tries += 1
		var p := Vector2(_rng.randf_range(-2.3, 2.3), _rng.randf_range(-3.1, 3.1))
		if p.length() > 3.15 or p.length() < 1.6:
			continue
		var zpath: float = -1.85 + 0.18 * sin(p.x * 1.1 + 0.4)
		if absf(p.y - zpath) < 0.5:
			continue
		var rr: float = _rng.randf_range(0.09, 0.17)
		_rock(Vector3(p.x, 0.0, p.y), rr, 0.5, STONE_D.lerp(STONE, _rng.randf()), 0.4)
		placed += 1
	# Upstream sill (half in the trench water) and downstream lip stones.
	var n_sill: int = 8
	for i: int in n_sill:
		var x: float = -2.3 + 4.6 * float(i) / float(n_sill - 1) + _rng.randf_range(-0.1, 0.1)
		var rs: float = FORD_R + _rng.randf_range(0.0, 0.12)
		var z: float = -sqrt(maxf(rs * rs - x * x, 0.0))
		var rad: float = _rng.randf_range(0.22, 0.32)
		_contact = WATER_Y
		_rock(Vector3(x, -0.13, z), rad, 0.78, STONE_WET, 0.7)
	for x: float in [-1.7, 0.35, 1.85]:
		var rs: float = FORD_R + 0.08
		var z: float = sqrt(rs * rs - x * x)
		_rock(Vector3(x, -0.16, z), _rng.randf_range(0.2, 0.26), 0.8, STONE_WET, 0.5)
	# Driftwood lodged against the sill.
	_contact = WATER_Y
	var log_pts := PackedVector3Array([Vector3(-2.35, -0.07, -3.0), Vector3(-1.6, -0.02, -3.35),
		Vector3(-0.75, -0.04, -3.62)])
	_tube(log_pts, 0.1, 6, BARK, true, true, BARK_L)
	_tube(PackedVector3Array([Vector3(-1.6, 0.0, -3.35), Vector3(-1.45, 0.14, -3.05)]), 0.045, 5, BARK, false, true,
		BARK_L)
	# Marker poles with rags, a cairn at each foot.
	var poles: Array = [[-2.95, -2.1, RAG_RED], [2.95, -2.05, RAG_OCHRE], [-2.95, 1.15, RAG_OCHRE],
		[2.95, 1.1, RAG_RED]]
	for pd: Array in poles:
		_marker_pole(Vector3(float(pd[0]), 0.0, float(pd[1])), pd[2])

	# Foam. x samples across the channel; the envelope fades out toward the banks.
	var xs := PackedFloat32Array()
	for i: int in 19:
		xs.append(-2.45 + 4.9 * float(i) / 18.0)
	# a) against the upstream sill on the trench side (drifts toward the lip).
	_foam_arc(xs, [FORD_R, FORD_R + 0.35, FORD_R + 0.95], -1.0, [FOAM_Y, FOAM_Y, FOAM_Y], [1.0, 0.65, 0.0],
		0.0, -1.0)
	# b) the spill onto the film (inside the circle, drifts downstream onto the ford).
	_foam_arc(xs, [FORD_R - 0.05, FORD_R - 0.4, FORD_R - 0.75], -1.0, [FILM_TOP, FILM_TOP, FILM_TOP],
		[0.95, 0.35, 0.0], 0.0, 1.0)
	# c) cascade off the downstream lip.
	_foam_arc(xs, [FORD_R - 0.02, FORD_R + 0.1, FORD_R + 0.2], 1.0, [FILM_TOP, -0.14, WATER_Y + 0.01],
		[0.8, 0.8, 0.8], 1.0, 1.0)
	# d) churn below the cascade.
	_foam_arc(xs, [FORD_R + 0.2, FORD_R + 0.45, FORD_R + 0.85, FORD_R + 1.4], 1.0, [FOAM_Y, FOAM_Y, FOAM_Y, FOAM_Y],
		[0.85, 0.55, 0.22, 0.0], 0.0, 1.0)

	var mesh := ArrayMesh.new()
	_commit_painted(mesh, body, -0.45, 1.6, load(PAINTED_MAT) as Material)
	var foam := ArrayMesh.new()
	_commit_foam(foam, _f)
	_save("ford_stones", "FordStones", &"ford", mesh, foam, false)


## A ford marker: a leaning weathered pole (1.85-2.2 m) with a rag tied under its top (a knot band and two
## fluttering tails, double-sided), three stones at its foot.
func _marker_pole(foot: Vector3, rag: Color) -> void:
	var h: float = _rng.randf_range(1.85, 2.2)
	var lean_dir := Vector3(_rng.randf_range(-1.0, 1.0), 0.0, _rng.randf_range(-1.0, 1.0)).normalized()
	var tilt: float = _rng.randf_range(0.05, 0.12)
	var top: Vector3 = foot + (Vector3.UP * cos(tilt) + lean_dir * sin(tilt)) * h
	_contact = 0.0
	_tube(PackedVector3Array([foot + Vector3(0.0, -0.15, 0.0), foot.lerp(top, 0.5), top]), 0.075, 6, POLE, false, true,
		POLE * 1.2)
	# Sharpened tip.
	var axis: Vector3 = (top - foot).normalized()
	_tube(PackedVector3Array([top, top + axis * 0.12]), 0.075, 6, POLE * 1.1, false, false)
	var tip: Vector3 = top + axis * 0.2
	var ring: Array[Vector3] = _ring(top + axis * 0.12, axis, 0.075, 6)
	for j: int in 6:
		var a: Vector3 = ring[j]
		var b: Vector3 = ring[(j + 1) % 6]
		_tri(a, b, tip, (a + b) * 0.5 - (top + axis * 0.12), POLE * 1.2)
	# Rag: knot band + two tails blowing the same way (local wind), fluttering a little in the shader wind.
	var knot: Vector3 = foot.lerp(top, 0.9)
	_tube(PackedVector3Array([knot - axis * 0.06, knot + axis * 0.06]), 0.1, 6, rag, true, true, rag)
	var wind := Vector3(0.85, 0.0, 0.35).normalized()
	_sway = 0.8
	for tail: Array in [[0.0, 0.62, 0.21], [0.55, 0.42, 0.15]]:
		var wdir: Vector3 = wind.rotated(Vector3.UP, float(tail[0]) - 0.25)
		var ln: float = float(tail[1])
		var wd: float = float(tail[2])
		var pts: Array[Vector3] = []
		for k: int in 4:
			var u: float = float(k) / 3.0
			pts.append(knot + wdir * (ln * u) + Vector3(0.0, -0.22 * u * u - 0.02, 0.0)
				+ wdir.cross(Vector3.UP) * (sin(u * 5.0) * 0.05))
		for k: int in 3:
			var w0: float = wd * (1.0 - 0.45 * float(k) / 3.0)
			var w1: float = wd * (1.0 - 0.45 * float(k + 1) / 3.0)
			var a0: Vector3 = pts[k] + Vector3(0.0, w0 * 0.5, 0.0)
			var b0: Vector3 = pts[k] - Vector3(0.0, w0 * 0.5, 0.0)
			var a1: Vector3 = pts[k + 1] + Vector3(0.0, w1 * 0.5, 0.0)
			var b1: Vector3 = pts[k + 1] - Vector3(0.0, w1 * 0.5, 0.0)
			var nrm: Vector3 = (pts[k + 1] - pts[k]).cross(Vector3.UP).normalized()
			var shade: Color = rag * (0.85 if k % 2 == 1 else 1.0)
			_quad(a0, a1, b1, b0, nrm, shade)
			_quad(a0, a1, b1, b0, -nrm, shade * 0.85)
	_sway = 0.0
	# Cairn.
	_contact = 0.0
	for k: int in 3:
		var ang: float = TAU * float(k) / 3.0 + _rng.randf() * 0.8
		_rock(foot + Vector3(cos(ang) * 0.2, 0.0, sin(ang) * 0.2), _rng.randf_range(0.1, 0.14), 0.65, STONE_D, 0.6)


# --- Crown Steps -------------------------------------------------------------------------------------------------

## North-west / south-east Crown Steps (local +Z away from the isle centre). Pale ruin stone: broken stone steps
## descending into the moat on both flanks of the crossing (three terraces following the circle rim, a few blocks
## missing, tilted or fallen into the water), cracked tread slabs across the shallows, a curb (the top step) along
## each bank edge, a few landing flagstones, a broken column stump on the isle side and a toppled drum on the outer
## bank. Foam at the foot of the flank steps.
func _build_steps() -> void:
	_rng.seed = 12043
	var body := Surf.new()
	_f = Surf.new()
	_s = body
	var isle := Vector2(0.0, -MOAT_R)
	var origin := Vector2.ZERO
	# Flank terraces around the crossing circle.
	var terr: Array = [[2.7, 3.08, 0.045], [3.08, 3.45, -0.1], [3.45, 3.83, -0.235]]
	for s: float in [-1.0, 1.0]:
		for k: int in terr.size():
			var r0: float = terr[k][0]
			var r1: float = terr[k][1]
			var ytop: float = terr[k][2]
			var rm: float = (r0 + r1) * 0.5
			var rng2: Vector2 = _water_arc(origin, rm, s, isle)
			var margin: float = 0.25 / rm
			var a: float = rng2.x - margin
			while a < rng2.y + margin:
				var da: float = _rng.randf_range(0.55, 0.85) / rm
				var a1: float = minf(a + da, rng2.y + margin)
				if a1 - a < 0.25 / rm:
					break
				var roll: float = _rng.randf()
				if k > 0 and roll < 0.1:
					a = a1   # missing block
					continue
				var tilt := Vector2.ZERO
				var sink: float = 0.0
				if roll > 0.82:
					tilt = Vector2(_rng.randf_range(-0.12, 0.12), _rng.randf_range(-0.12, 0.12))
					sink = _rng.randf_range(0.02, 0.07)
				var val: float = _rng.randf_range(0.9, 1.08)
				var topc: Color = RUIN_L * val if k == 0 else (RUIN * val if k == 1 else RUIN.lerp(RUIN_WET, 0.35) * val)
				if k < 2 and _rng.randf() < 0.28:
					topc = topc.lerp(MOSS, 0.55)
				_contact = WATER_Y if k > 0 else -0.25
				_sector(origin, r0 + 0.02, r1 - 0.02, a + 0.02 / rm, a1 - 0.02 / rm,
					-0.9, ytop - sink + _rng.randf_range(-0.012, 0.01), RUIN_D.lerp(RUIN_WET, 0.3 * float(k)) * val,
					topc, tilt)
				a = a1
	# Two blocks fallen into the moat.
	_contact = WATER_Y
	_box(Vector3(4.3, -0.33, 0.35), Basis(Vector3(0.3, 1.0, 0.2).normalized(), 0.45), Vector3(0.36, 0.17, 0.26),
		RUIN_WET, RUIN.lerp(MOSS, 0.4))
	_box(Vector3(-4.15, -0.36, -0.55), Basis(Vector3(-0.2, 1.0, 0.4).normalized(), -0.6), Vector3(0.3, 0.16, 0.3),
		RUIN_WET, RUIN)
	# Tread slabs across the shallows: a broken paved way in five loose rows (running bond), higher and paler at the
	# banks, wet and sunk in the middle; irregular sizes, turned a little, many missing, some cracked in two.
	_contact = -0.3
	var rows_y: Array = [0.05, 0.038, 0.03, 0.038, 0.05]
	for bi: int in 5:
		var zc: float = -1.4 + 0.7 * float(bi)
		var x: float = -2.5 + _rng.randf_range(0.0, 0.35) + (0.3 if bi % 2 == 1 else 0.0)
		var wet: float = 1.0 - absf(float(bi) - 2.0) / 2.0
		while x < 2.5:
			var ln: float = _rng.randf_range(0.42, 0.8)
			var xc: float = x + ln * 0.5 + _rng.randf_range(-0.05, 0.05)
			x += ln + _rng.randf_range(0.07, 0.18)
			var hz: float = _rng.randf_range(0.2, 0.3)
			var zz: float = zc + _rng.randf_range(-0.07, 0.07)
			var far: float = Vector2(absf(xc) + ln * 0.5, absf(zz) + hz).length()
			if far > 2.72:
				continue
			var d: float = Vector2(xc, zz).distance_to(isle)
			if d < MOAT_IN + 0.05 or d > MOAT_OUT - 0.05:
				continue
			if _rng.randf() < 0.4:
				continue
			var yt: float = float(rows_y[bi]) + _rng.randf_range(-0.01, 0.006)
			var b := Basis(Vector3.UP, _rng.randf_range(-0.16, 0.16))
			var val: float = _rng.randf_range(0.88, 1.08)
			var topc: Color = RUIN.lerp(RUIN_WET, 0.25 + 0.4 * wet) * val
			if _rng.randf() < 0.25:
				topc = topc.lerp(MOSS, 0.45)
			if _rng.randf() < 0.25 and ln > 0.6:
				# Cracked in two, the halves settled differently.
				var h1: float = ln * _rng.randf_range(0.4, 0.6)
				_box(Vector3(xc - ln * 0.5 + h1 * 0.5, yt - 0.085, zz), b, Vector3(h1 * 0.5 - 0.03, 0.085, hz),
					RUIN_D * val, topc)
				var yt2: float = yt - _rng.randf_range(0.01, 0.025)
				_box(Vector3(xc + h1 * 0.5, yt2 - 0.085, zz), b * Basis(Vector3.BACK, 0.04),
					Vector3((ln - h1) * 0.5 - 0.03, 0.085, hz), RUIN_D * val, topc * 0.95)
			else:
				_box(Vector3(xc, yt - 0.085, zz), b, Vector3(ln * 0.5, 0.085, hz), RUIN_D * val, topc)
	# Curbs along both bank edges (the top step), inside the circle.
	for edge: Array in [[MOAT_IN - 0.33, MOAT_IN + 0.05], [MOAT_OUT - 0.05, MOAT_OUT + 0.33]]:
		var r0: float = edge[0]
		var r1: float = edge[1]
		var rm: float = (r0 + r1) * 0.5
		var span: Vector2 = _inside_arc(isle, rm, 2.85)
		var a: float = span.x
		while a < span.y:
			var a1: float = minf(a + _rng.randf_range(0.6, 0.9) / rm, span.y)
			if (a1 - a) * rm < 0.3:
				break
			var val: float = _rng.randf_range(0.92, 1.06)
			var topc: Color = RUIN_L * val
			if _rng.randf() < 0.3:
				topc = topc.lerp(MOSS, 0.5)
			_contact = -0.2
			_sector(isle, r0, r1, a + 0.015 / rm, a1 - 0.015 / rm, -0.4, 0.075 + _rng.randf_range(-0.012, 0.008),
				RUIN_D * val, topc, Vector2.ZERO)
			a = a1
	# Landing flagstones on the isle bank (leading up to the ruins).
	for band: Array in [[MOAT_IN - 1.25, MOAT_IN - 0.4]]:
		var r0: float = band[0]
		var r1: float = band[1]
		var rm: float = (r0 + r1) * 0.5
		var span: Vector2 = _inside_arc(isle, rm, 2.7)
		var a: float = span.x
		while a < span.y:
			var a1: float = minf(a + _rng.randf_range(0.6, 1.0) / rm, span.y)
			if (a1 - a) * rm < 0.35:
				break
			if _rng.randf() > 0.45:
				_contact = -0.2
				var lc: Color = RUIN.lerp(RUIN_D, 0.25) * _rng.randf_range(0.92, 1.05)
				if _rng.randf() < 0.4:
					lc = lc.lerp(MOSS, 0.45)
				_sector(isle, r0 + 0.04, r1 - 0.04, a + 0.03 / rm, a1 - 0.03 / rm, -0.2,
					0.022 + _rng.randf_range(-0.006, 0.006), RUIN_D, lc, Vector2.ZERO)
			a = a1
	# Broken column stump (isle side) and a toppled drum (outer bank).
	_contact = 0.0
	_stump(Vector3(-2.15, 0.0, -2.25), 0.36, 0.62)
	_contact = 0.0
	_tube(PackedVector3Array([Vector3(1.95, 0.27, 2.45), Vector3(2.55, 0.27, 2.05)]), 0.3, 8, RUIN_D.lerp(RUIN, 0.2),
		true, true, RUIN_D.lerp(MOSS, 0.4))
	_rock(Vector3(1.6, 0.0, 2.75), 0.16, 0.6, RUIN_D, 0.6)
	_rock(Vector3(-2.5, 0.0, -1.85), 0.13, 0.6, RUIN_D, 0.6)

	# Foam at the foot of the flank steps (slow moat: lighter).
	for s: float in [-1.0, 1.0]:
		var rr: Vector2 = _water_arc(origin, 3.83, s, isle)
		var rows: Array = []
		var env: Array = []
		var radii: Array = [3.84, 4.15, 4.7]
		var ev: Array = [0.8, 0.45, 0.0]
		var n: int = 16
		for k: int in radii.size():
			var row := PackedVector3Array()
			var er := PackedFloat32Array()
			for j: int in n + 1:
				var u: float = float(j) / float(n)
				var ang: float = lerpf(rr.x, rr.y, u)
				var r: float = float(radii[k])
				row.append(Vector3(cos(ang) * r, FOAM_Y, sin(ang) * r))
				var arc_m: float = minf(u, 1.0 - u) * (rr.y - rr.x) * 3.83
				er.append(float(ev[k]) * smoothstep(0.0, 0.6, arc_m))
			rows.append(row)
			env.append(er)
		_foam(rows, PackedFloat32Array([0.0, 0.31, 0.86]), env, 0.0, 1.0)

	var mesh := ArrayMesh.new()
	_commit_painted(mesh, body, -0.45, 0.7, load(PAINTED_MAT) as Material)
	var foam := ArrayMesh.new()
	_commit_foam(foam, _f)
	_save("crown_steps", "CrownSteps", &"steps", mesh, foam, false)


## A broken column stump: 8 sides, the top snapped at a slant, moss on the high side.
func _stump(c: Vector3, r: float, h: float) -> void:
	var sides: int = 8
	var bot: Array[Vector3] = []
	var top: Array[Vector3] = []
	for j: int in sides:
		var a: float = TAU * float(j) / float(sides) + 0.2
		var d := Vector3(cos(a), 0.0, sin(a))
		bot.append(c + d * r * 1.04 + Vector3(0.0, -0.05, 0.0))
		var yt: float = h - 0.22 * (cos(a - 0.9) * 0.5 + 0.5) + (_h(Vector3(j, 3.0, 1.0)) - 0.5) * 0.08
		top.append(c + d * r + Vector3(0.0, yt, 0.0))
	var mid := c + Vector3(0.0, h - 0.12, 0.0)
	for j: int in sides:
		var j2: int = (j + 1) % sides
		var out: Vector3 = (bot[j] + bot[j2]) * 0.5 - c
		out.y = 0.0
		_quad(bot[j], bot[j2], top[j2], top[j], out, RUIN)
		var tc: Color = RUIN_L.lerp(MOSS, 0.5) if top[j].y < c.y + h - 0.12 else RUIN_L
		_tri(top[j], top[j2], mid, Vector3.UP, tc)


## [min, max] angle (around `center`, atan2 of z, x) of the arc of radius `r` on side `s` (x sign, around the
## origin) whose points lie in the moat water (MOAT_IN < distance to `isle` < MOAT_OUT).
func _water_arc(center: Vector2, r: float, s: float, isle: Vector2) -> Vector2:
	var lo: float = INF
	var hi: float = -INF
	var a0: float = -PI * 0.5 if s > 0.0 else PI * 0.5
	for i: int in 721:
		var a: float = a0 + PI * float(i) / 720.0
		var p: Vector2 = center + Vector2(cos(a), sin(a)) * r
		var d: float = p.distance_to(isle)
		if d > MOAT_IN and d < MOAT_OUT:
			lo = minf(lo, a)
			hi = maxf(hi, a)
	return Vector2(lo, hi)


## [min, max] angle around `isle` of the arc of radius `r` (around the isle) that stays within `max_r` of the origin.
func _inside_arc(isle: Vector2, r: float, max_r: float) -> Vector2:
	var lo: float = INF
	var hi: float = -INF
	var base: float = atan2(-isle.y, -isle.x)
	for i: int in 721:
		var a: float = base + (float(i) / 720.0 - 0.5) * 1.2
		var p: Vector2 = isle + Vector2(cos(a), sin(a)) * r
		if p.length() <= max_r:
			lo = minf(lo, a)
			hi = maxf(hi, a)
	return Vector2(lo, hi)


# --- Shapes ------------------------------------------------------------------------------------------------------

## An annular sector block around `center` (x/z): radii r0..r1, angles a0..a1, from y0 up to y1 (+ tilt), chamfered.
func _sector(center: Vector2, r0: float, r1: float, a0: float, a1: float, y0: float, y1: float, side: Color,
		top: Color, tilt: Vector2) -> void:
	var pts: Array[Vector2] = []
	for k: int in 3:
		var a: float = lerpf(a0, a1, float(k) / 2.0)
		pts.append(center + Vector2(cos(a), sin(a)) * r1)
	for k: int in 3:
		var a: float = lerpf(a1, a0, float(k) / 2.0)
		pts.append(center + Vector2(cos(a), sin(a)) * r0)
	var cen := Vector2.ZERO
	for p: Vector2 in pts:
		cen += p
	cen /= float(pts.size())
	var rel := PackedVector2Array()
	for p: Vector2 in pts:
		rel.append(p - cen)
	_stone(Vector3(cen.x, 0.0, cen.y), rel, y0, y1, 0.035, side, top, tilt)


## Converts an outline given as (t along `fl`, a along `nr`) to local x/z offsets, scaled (st along, sa across).
func _outline(pts: Array[Vector2], fl: Vector3, nr: Vector3, st: float, sa: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q: Vector2 in pts:
		var p: Vector3 = fl * (q.x * st) + nr * (q.y * sa)
		out.append(Vector2(p.x, p.z))
	return out


## An irregular convex-ish pebble outline: `n` points, radius r (+-15 %), stretched `stretch` along x.
func _blob(n: int, r: float, stretch: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var rot: float = _rng.randf() * TAU
	for j: int in n:
		var a: float = TAU * float(j) / float(n)
		var rr: float = r * _rng.randf_range(0.85, 1.12)
		out.append(Vector2(cos(a) * rr * stretch, sin(a) * rr).rotated(rot))
	return out


## A prism from outline `rel` (x/z offsets around `c`, star-shaped) between y0 and y1: sides, a chamfer band
## (the top ring scaled by `inset` toward the centre, `chamfer` m high) and a flat top (fan). `tilt` = top slope
## (dy per m in x, z).
func _stone(c: Vector3, rel: PackedVector2Array, y0: float, y1: float, chamfer: float, side: Color, top: Color,
		tilt: Vector2 = Vector2.ZERO, inset: float = 0.82) -> void:
	var n: int = rel.size()
	var r0: Array[Vector3] = []
	var r1: Array[Vector3] = []
	var r2: Array[Vector3] = []
	for j: int in n:
		var q: Vector2 = rel[j]
		var ty: float = tilt.x * q.x + tilt.y * q.y
		r0.append(c + Vector3(q.x, y0, q.y))
		r1.append(c + Vector3(q.x, y1 - chamfer + ty, q.y))
		var qi: Vector2 = q * (inset if chamfer > 0.0 else 1.0)
		r2.append(c + Vector3(qi.x, y1 + ty, qi.y))
	var ctop := Vector3(c.x, y1, c.z)
	for j: int in n:
		var j2: int = (j + 1) % n
		var mid: Vector3 = (r0[j] + r0[j2]) * 0.5
		var out := Vector3(mid.x - c.x, 0.0, mid.z - c.z)
		_quad(r0[j], r0[j2], r1[j2], r1[j], out, side)
		if chamfer > 0.0:
			_quad(r1[j], r1[j2], r2[j2], r2[j], out + Vector3.UP * out.length(), side.lerp(top, 0.55))
		_tri(r2[j], r2[j2], ctop, Vector3.UP, top)


## An oriented box (centre, basis, half extents); side faces `side`, top face `top`, no bottom unless asked.
func _box(c: Vector3, b: Basis, h: Vector3, side: Color, top: Color, bottom: bool = false) -> void:
	var k: Array[Vector3] = []
	for i: int in 8:
		k.append(c + b * Vector3(h.x * (1.0 if i & 1 else -1.0), h.y * (1.0 if i & 2 else -1.0),
			h.z * (1.0 if i & 4 else -1.0)))
	_quad(k[2], k[3], k[7], k[6], b.y, top)
	_quad(k[1], k[3], k[7], k[5], b.x, side)
	_quad(k[0], k[2], k[6], k[4], -b.x, side)
	_quad(k[4], k[5], k[7], k[6], b.z, side)
	_quad(k[0], k[1], k[3], k[2], -b.z, side)
	if bottom:
		_quad(k[0], k[1], k[5], k[4], -b.y, side)


## A square beam of half width `w` from a to b.
func _beam(a: Vector3, b: Vector3, w: float, col: Color) -> void:
	var z: Vector3 = (b - a).normalized()
	var ref: Vector3 = Vector3.UP if absf(z.y) < 0.9 else Vector3.RIGHT
	var x: Vector3 = ref.cross(z).normalized()
	var y: Vector3 = z.cross(x).normalized()
	_box((a + b) * 0.5, Basis(x, y, z), Vector3(w, w, a.distance_to(b) * 0.5), col, col * 1.1, true)


## A 4-sided pyramid on a square base (half size `half`, centred on `c`, turned by `b`), `height` tall.
func _pyramid(c: Vector3, b: Basis, half: float, height: float, col: Color) -> void:
	var q: Array[Vector3] = [c + b * Vector3(-half, 0.0, -half), c + b * Vector3(half, 0.0, -half),
		c + b * Vector3(half, 0.0, half), c + b * Vector3(-half, 0.0, half)]
	var apex: Vector3 = c + b * Vector3(0.0, height, 0.0)
	for j: int in 4:
		var a: Vector3 = q[j]
		var d: Vector3 = q[(j + 1) % 4]
		_tri(a, d, apex, (a + d) * 0.5 - c + b.y * half, col)


## A tube through `pts` (radius `r`, `sides` sides), optional end caps (fans).
func _tube(pts: PackedVector3Array, r: float, sides: int, col: Color, cap0: bool, cap1: bool,
		cap_col: Color = Color(-1, 0, 0)) -> void:
	var cc: Color = col if cap_col.r < 0.0 else cap_col
	var rings: Array = []
	for i: int in pts.size():
		var t: Vector3
		if i == 0:
			t = pts[1] - pts[0]
		elif i == pts.size() - 1:
			t = pts[i] - pts[i - 1]
		else:
			t = pts[i + 1] - pts[i - 1]
		rings.append(_ring(pts[i], t.normalized(), r, sides))
	for i: int in pts.size() - 1:
		var ra: Array[Vector3] = rings[i]
		var rb: Array[Vector3] = rings[i + 1]
		var mid: Vector3 = (pts[i] + pts[i + 1]) * 0.5
		for j: int in sides:
			var j2: int = (j + 1) % sides
			_quad(ra[j], ra[j2], rb[j2], rb[j], (ra[j] + ra[j2] + rb[j] + rb[j2]) * 0.25 - mid, col)
	if cap0:
		var ra: Array[Vector3] = rings[0]
		var t0: Vector3 = (pts[0] - pts[1]).normalized()
		for j: int in sides:
			_tri(ra[j], ra[(j + 1) % sides], pts[0], t0, cc)
	if cap1:
		var n: int = pts.size() - 1
		var rb: Array[Vector3] = rings[n]
		var t1: Vector3 = (pts[n] - pts[n - 1]).normalized()
		for j: int in sides:
			_tri(rb[j], rb[(j + 1) % sides], pts[n], t1, cc)


func _ring(c: Vector3, t: Vector3, r: float, sides: int) -> Array[Vector3]:
	var ref: Vector3 = Vector3.UP if absf(t.y) < 0.9 else Vector3.RIGHT
	var u: Vector3 = t.cross(ref).normalized()
	var w: Vector3 = t.cross(u).normalized()
	var out: Array[Vector3] = []
	for j: int in sides:
		var a: float = TAU * float(j) / float(sides)
		out.append(c + (u * cos(a) + w * sin(a)) * r)
	return out


## A low faceted rock (7 x 4 sphere, squashed to `squash` in y) at `c` (its centre), radius `r`; up-facing faces
## get `moss` of the moss colour.
func _rock(c: Vector3, r: float, squash: float, col: Color, moss: float) -> void:
	var sph := SphereMesh.new()
	sph.radius = r
	sph.height = r * 2.0
	sph.radial_segments = 7
	sph.rings = 4
	var arr: Array = sph.get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var xf := Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(1.2, squash, 1.0)), c)
	var tv := PackedVector3Array()
	tv.resize(v.size())
	for i: int in v.size():
		tv[i] = xf * v[i] + (Vector3(_h(v[i] + c), _h(v[i] * 1.7 + c), _h(v[i] * 2.3 + c)) - Vector3.ONE * 0.5) * r * 0.25
	for t: int in range(0, idx.size(), 3):
		var a: Vector3 = tv[idx[t]]
		var b: Vector3 = tv[idx[t + 1]]
		var d: Vector3 = tv[idx[t + 2]]
		var hint: Vector3 = xf.basis * (n[idx[t]] + n[idx[t + 1]] + n[idx[t + 2]])
		var fn: Vector3 = (b - a).cross(d - a)
		if fn.length_squared() < 1e-12:
			continue
		fn = fn.normalized()
		if fn.dot(hint) < 0.0:
			fn = -fn
		var fc: Color = col.lerp(MOSS, moss) if fn.y > 0.6 else col
		_tri(a, b, d, hint, fc)


# --- Foam --------------------------------------------------------------------------------------------------------

## Foam arcs on the ford circle: for each x in `xs`, a point on the circle of radius radii[k] (z sign `zs`) at
## height ys[k]; envelope envs[k] (faded toward the banks); UV.y = metres from the first row.
func _foam_arc(xs: PackedFloat32Array, radii: Array, zs: float, ys: Array, envs: Array, sheet: float,
		flow: float) -> void:
	var rows: Array = []
	var env: Array = []
	var across := PackedFloat32Array()
	var acc: float = 0.0
	for k: int in radii.size():
		var row := PackedVector3Array()
		var er := PackedFloat32Array()
		for x: float in xs:
			var r: float = float(radii[k])
			var z: float = zs * sqrt(maxf(r * r - x * x, 0.0))
			row.append(Vector3(x, float(ys[k]), z))
			er.append(float(envs[k]) * smoothstep(RIVER_HALF - 0.02, RIVER_HALF - 0.6, absf(x)))
		if k > 0:
			var prev: PackedVector3Array = rows[k - 1]
			acc += prev[xs.size() / 2].distance_to(row[xs.size() / 2])
		across.append(acc)
		rows.append(row)
		env.append(er)
	_foam(rows, across, env, sheet, flow)


## Quads between consecutive rows (same point count). UV = (metres along row 0, across[k]); COLOR.a = envelope;
## UV2 = (sheet, flow code).
func _foam(rows: Array, across: PackedFloat32Array, env: Array, sheet: float, flow: float) -> void:
	var p0: PackedVector3Array = rows[0]
	var along := PackedFloat32Array()
	var acc: float = 0.0
	for j: int in p0.size():
		if j > 0:
			acc += p0[j].distance_to(p0[j - 1])
		along.append(acc)
	for r: int in rows.size() - 1:
		var ra: PackedVector3Array = rows[r]
		var rb: PackedVector3Array = rows[r + 1]
		var ea: PackedFloat32Array = env[r]
		var eb: PackedFloat32Array = env[r + 1]
		for j: int in p0.size() - 1:
			var q: Array = [[ra[j], along[j], across[r], ea[j]], [ra[j + 1], along[j + 1], across[r], ea[j + 1]],
				[rb[j + 1], along[j + 1], across[r + 1], eb[j + 1]], [rb[j], along[j], across[r + 1], eb[j]]]
			for t: Array in [q[0], q[1], q[2], q[0], q[2], q[3]]:
				_f.v.append(t[0])
				_f.n.append(Vector3.UP)
				_f.c.append(Color(1.0, 1.0, 1.0, float(t[3])))
				_f.uv.append(Vector2(float(t[1]), float(t[2])))
				_f.uv2.append(Vector2(sheet, flow))


# --- Triangles, commit, save -------------------------------------------------------------------------------------

func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, hint: Vector3, col: Color) -> void:
	_tri(a, b, c, hint, col)
	_tri(a, c, d, hint, col)


## Adds a flat triangle facing along `hint` (winding fixed like Godot's primitives), value-jittered per face.
func _tri(a: Vector3, b: Vector3, c: Vector3, hint: Vector3, col: Color) -> void:
	var fn: Vector3 = (b - a).cross(c - a)
	if fn.length_squared() < 1e-12:
		return
	fn = fn.normalized()
	var s: float = 1.0 if fn.dot(hint) >= 0.0 else -1.0
	if s != _conv:
		var tmp: Vector3 = b
		b = c
		c = tmp
	fn *= s
	var k: float = 1.0 + (_h((a + b + c).snappedf(0.01)) - 0.5) * 0.10
	var fc := Color(col.r * k, col.g * k, col.b * k)
	for p: Vector3 in [a, b, c]:
		_s.v.append(p)
		_s.n.append(fn)
		_s.c.append(fc)
		_s.uv.append(Vector2(_sway, p.y - _contact))


## Painted surface: COLOR.a = height gradient between lo and hi (0.70x at lo -> 1.10x at hi in env_painted).
func _commit_painted(mesh: ArrayMesh, s: Surf, lo: float, hi: float, mat: Material) -> void:
	if s.v.is_empty():
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in s.v.size():
		var cc: Color = s.c[i]
		cc.a = clampf((s.v[i].y - lo) / (hi - lo), 0.0, 1.0)
		st.set_color(cc)
		st.set_normal(s.n[i])
		st.set_uv(s.uv[i])
		st.add_vertex(s.v[i])
	st.index()
	st.set_material(mat)
	st.commit(mesh)


func _commit_foam(mesh: ArrayMesh, s: Surf) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in s.v.size():
		st.set_color(s.c[i])
		st.set_normal(s.n[i])
		st.set_uv(s.uv[i])
		st.set_uv2(s.uv2[i])
		st.add_vertex(s.v[i])
	st.index()
	st.set_material(load(FOAM_MAT) as Material)
	st.commit(mesh)


## Saves <file>_body.res / <file>_foam.res and <file>.tscn (root Node3D `root_name` with MeshInstance3D children
## "Body" and "Foam").
func _save(file: String, root_name: String, kind: StringName, body: ArrayMesh, foam: ArrayMesh,
		body_shadow: bool) -> void:
	body.resource_name = file + "_body"
	foam.resource_name = file + "_foam"
	var bp: String = MESH_DIR + file + "_body.res"
	var fp: String = MESH_DIR + file + "_foam.res"
	var e1: int = ResourceSaver.save(body, bp, ResourceSaver.FLAG_CHANGE_PATH)
	var e2: int = ResourceSaver.save(foam, fp, ResourceSaver.FLAG_CHANGE_PATH)
	body.take_over_path(bp)
	foam.take_over_path(fp)
	var root := Node3D.new()
	root.name = root_name
	root.set_script(load(DIR + "crossing_art.gd"))
	root.set(&"kind", kind)
	var mi := MeshInstance3D.new()
	mi.name = "Body"
	mi.mesh = body
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if body_shadow \
		else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	mi.owner = root
	var fi := MeshInstance3D.new()
	fi.name = "Foam"
	fi.mesh = foam
	fi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(fi)
	fi.owner = root
	var ps := PackedScene.new()
	ps.pack(root)
	var e3: int = ResourceSaver.save(ps, DIR + file + ".tscn")
	var tris: int = 0
	for i: int in body.get_surface_count():
		tris += (body.surface_get_arrays(i)[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	var ftris: int = (foam.surface_get_arrays(0)[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	print("%s: body %d tris (%d surfaces), foam %d tris, aabb %s, save %d %d %d" % [file, tris,
		body.get_surface_count(), ftris, str(body.get_aabb()), e1, e2, e3])
	root.free()


func _detect_winding() -> void:
	var arr: Array = BoxMesh.new().get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
	var fn: Vector3 = (v[idx[1]] - v[idx[0]]).cross(v[idx[2]] - v[idx[0]])
	_conv = 1.0 if fn.dot(n[idx[0]]) >= 0.0 else -1.0


func _h(p: Vector3) -> float:
	return fposmod(sin(p.dot(Vector3(12.9898, 78.233, 37.719))) * 43758.5453, 1.0)
