extends RefCounted
## Map Lab (docs/plan/map-lab.md): the baked navmesh rasterised onto a 0.25 m grid (one cell = one heat-map pixel).
## Each cell keeps the connected navmesh component it belongs to (polygons joined by shared edges), so the lab can
## find islands, measure corridor widths, compare the navmesh with its mirror image and paint the heat map.
## The navmesh is the one units walk on: it is already shrunk by the agent radius (0.5 m), so a corridor of navmesh
## width W lets units through a real gap of about W + 1.0 m.
## No class_name on purpose (preloaded tool script).

const CELL := 0.25
const HEAT_CELL := 1.0

var half := 60.0
var n := 480                           ## cells per side
var cell_comp := PackedInt32Array()    ## component id per cell, -1 = no navmesh
var cell_y := PackedFloat32Array()
var comp_area: Array[float] = []       ## m² per component
var comp_y: Array[float] = []          ## mean height per component
var comp_center: Array[Vector2] = []
var main_comp := -1
var polygon_count := 0
var vertex_count := 0
var heat_n := 120
var heat := PackedFloat32Array()


## Rasterises every polygon of the given NavigationRegion3D nodes (after their bake).
func build(regions: Array, half_size: float) -> void:
	half = half_size
	n = int(round(2.0 * half / CELL))
	cell_comp.resize(n * n)
	cell_comp.fill(-1)
	cell_y.resize(n * n)
	cell_y.fill(INF)
	heat_n = int(round(2.0 * half / HEAT_CELL))
	heat.resize(heat_n * heat_n)
	heat.fill(0.0)
	var polys: Array[PackedVector3Array] = []
	for r: Node in regions:
		var region := r as NavigationRegion3D
		if region == null or region.navigation_mesh == null:
			continue
		var nm := region.navigation_mesh
		var xf := region.global_transform if region.is_inside_tree() else region.transform
		var verts := nm.get_vertices()
		vertex_count += verts.size()
		for i in nm.get_polygon_count():
			var idx := nm.get_polygon(i)
			var pts := PackedVector3Array()
			for k in idx:
				pts.append(xf * verts[k])
			polys.append(pts)
	polygon_count = polys.size()
	# Union-find over polygons sharing an edge (vertex positions quantised to 1 cm, height to 5 cm).
	var parent := PackedInt32Array()
	parent.resize(polys.size())
	for i in polys.size():
		parent[i] = i
	var edge_owner := {}
	for i in polys.size():
		var p := polys[i]
		for k in p.size():
			var a := _vkey(p[k])
			var b := _vkey(p[(k + 1) % p.size()])
			var key := a + "|" + b if a < b else b + "|" + a
			if edge_owner.has(key):
				_union(parent, i, int(edge_owner[key]))
			else:
				edge_owner[key] = i
	var root_to_comp := {}
	var poly_comp := PackedInt32Array()
	poly_comp.resize(polys.size())
	var y_sum: Array[float] = []
	var y_cnt: Array[int] = []
	for i in polys.size():
		var r := _find(parent, i)
		if not root_to_comp.has(r):
			root_to_comp[r] = comp_area.size()
			comp_area.append(0.0)
			comp_y.append(0.0)
			comp_center.append(Vector2.ZERO)
			y_sum.append(0.0)
			y_cnt.append(0)
		var c: int = root_to_comp[r]
		poly_comp[i] = c
		for v in polys[i]:
			y_sum[c] += v.y
			y_cnt[c] += 1
	for c in comp_area.size():
		comp_y[c] = y_sum[c] / maxf(1.0, float(y_cnt[c]))
	# Rasterise (convex polygons, XZ projection); where two overlap, the one nearer the ground wins.
	for i in polys.size():
		var p := polys[i]
		if p.size() < 3:
			continue
		var minx := INF
		var maxx := -INF
		var minz := INF
		var maxz := -INF
		var ysum := 0.0
		for v in p:
			minx = minf(minx, v.x)
			maxx = maxf(maxx, v.x)
			minz = minf(minz, v.z)
			maxz = maxf(maxz, v.z)
			ysum += v.y
		var py := ysum / float(p.size())
		var i0 := clampi(int(floor((minx + half) / CELL)), 0, n - 1)
		var i1 := clampi(int(floor((maxx + half) / CELL)), 0, n - 1)
		var j0 := clampi(int(floor((minz + half) / CELL)), 0, n - 1)
		var j1 := clampi(int(floor((maxz + half) / CELL)), 0, n - 1)
		var c: int = poly_comp[i]
		for j in range(j0, j1 + 1):
			var cz := -half + (float(j) + 0.5) * CELL
			for ii in range(i0, i1 + 1):
				var cx := -half + (float(ii) + 0.5) * CELL
				if not _in_convex(p, cx, cz):
					continue
				var ci := j * n + ii
				if cell_comp[ci] >= 0 and absf(cell_y[ci]) <= absf(py):
					continue
				cell_comp[ci] = c
				cell_y[ci] = py
	# Areas and centres from the cells.
	var cx_sum: Array[float] = []
	var cz_sum: Array[float] = []
	var cells: Array[int] = []
	for c in comp_area.size():
		cx_sum.append(0.0)
		cz_sum.append(0.0)
		cells.append(0)
	for j in n:
		for ii in n:
			var c := cell_comp[j * n + ii]
			if c < 0:
				continue
			cells[c] += 1
			cx_sum[c] += -half + (float(ii) + 0.5) * CELL
			cz_sum[c] += -half + (float(j) + 0.5) * CELL
	var best := -1.0
	for c in comp_area.size():
		comp_area[c] = float(cells[c]) * CELL * CELL
		if cells[c] > 0:
			comp_center[c] = Vector2(cx_sum[c] / cells[c], cz_sum[c] / cells[c])
		if comp_area[c] > best:
			best = comp_area[c]
			main_comp = c


static func _vkey(v: Vector3) -> String:
	return "%d,%d,%d" % [roundi(v.x * 100.0), roundi(v.z * 100.0), roundi(v.y * 20.0)]


static func _find(parent: PackedInt32Array, i: int) -> int:
	var r := i
	while parent[r] != r:
		r = parent[r]
	var k := i
	while parent[k] != r:
		var nx := parent[k]
		parent[k] = r
		k = nx
	return r


static func _union(parent: PackedInt32Array, a: int, b: int) -> void:
	var ra := _find(parent, a)
	var rb := _find(parent, b)
	if ra != rb:
		parent[maxi(ra, rb)] = mini(ra, rb)


static func _in_convex(p: PackedVector3Array, x: float, z: float) -> bool:
	var side := 0
	var m := p.size()
	for k in m:
		var a := p[k]
		var b := p[(k + 1) % m]
		var cr := (b.x - a.x) * (z - a.z) - (b.z - a.z) * (x - a.x)
		if absf(cr) < 1e-9:
			continue
		var s := 1 if cr > 0.0 else -1
		if side == 0:
			side = s
		elif s != side:
			return false
	return true


# ---------------------------------------------------------------- queries

func cell_index(x: float, z: float) -> int:
	var i := int(floor((x + half) / CELL))
	var j := int(floor((z + half) / CELL))
	if i < 0 or j < 0 or i >= n or j >= n:
		return -1
	return j * n + i


func comp_at(x: float, z: float) -> int:
	var ci := cell_index(x, z)
	return cell_comp[ci] if ci >= 0 else -1


## True on the main (largest) navmesh component.
func walkable(x: float, z: float) -> bool:
	return main_comp >= 0 and comp_at(x, z) == main_comp


## Coarse 0.5 m grid for the geometric shortest paths (octile Dijkstra): walkable when >= 2 of its 4 fine cells are
## on the main navmesh. It maps onto itself under the map's mirrors, so its path lengths are exactly fair when the
## navmesh is, unlike the NavigationServer's polygon A* whose triangulation is not mirrored.
var coarse_n := 0
var coarse := PackedByteArray()


func build_coarse() -> void:
	coarse_n = n / 2
	coarse.resize(coarse_n * coarse_n)
	coarse.fill(0)
	for j in coarse_n:
		for i in coarse_n:
			var k := 0
			for dj in 2:
				for di in 2:
					if cell_comp[(2 * j + dj) * n + 2 * i + di] == main_comp:
						k += 1
			if k >= 2:
				coarse[j * coarse_n + i] = 1


func coarse_index(x: float, z: float) -> int:
	var i := int(floor((x + half) / (2.0 * CELL)))
	var j := int(floor((z + half) / (2.0 * CELL)))
	if i < 0 or j < 0 or i >= coarse_n or j >= coarse_n:
		return -1
	return j * coarse_n + i


## The walkable coarse cell nearest (x, z) within 2 m, -1 when none.
func coarse_near(x: float, z: float) -> int:
	var c := coarse_index(x, z)
	if c >= 0 and coarse[c] == 1:
		return c
	var best := -1
	var best_d := INF
	var step := 2.0 * CELL
	for dj in range(-4, 5):
		for di in range(-4, 5):
			var q := coarse_index(x + di * step, z + dj * step)
			if q < 0 or coarse[q] != 1:
				continue
			var d := Vector2(di, dj).length()
			if d < best_d:
				best_d = d
				best = q
	return best


## Octile shortest-path distances (m) from the nearest of the coarse cells `srcs` to every coarse cell (INF = unreachable).
func dijkstra(srcs: PackedInt32Array) -> PackedFloat32Array:
	var cn := coarse_n
	var dist := PackedFloat32Array()
	dist.resize(cn * cn)
	dist.fill(INF)
	var step := 2.0 * CELL
	var diag := step * sqrt(2.0)
	var heap_d := PackedFloat32Array()
	var heap_c := PackedInt32Array()
	for src in srcs:   # several sources = the distance to the nearest of them (a spot on a mirror axis)
		if src >= 0 and dist[src] > 0.0:
			dist[src] = 0.0
			heap_d.append(0.0)
			heap_c.append(src)
	var offs := [[1, 0, step], [-1, 0, step], [0, 1, step], [0, -1, step], [1, 1, diag], [1, -1, diag], [-1, 1, diag], [-1, -1, diag]]
	while heap_d.size() > 0:
		var d := heap_d[0]
		var c := heap_c[0]
		# pop
		var last := heap_d.size() - 1
		heap_d[0] = heap_d[last]
		heap_c[0] = heap_c[last]
		heap_d.resize(last)
		heap_c.resize(last)
		var k := 0
		while true:
			var l := 2 * k + 1
			if l >= last:
				break
			var r := l + 1
			var m := l if r >= last or heap_d[l] <= heap_d[r] else r
			if heap_d[m] >= heap_d[k]:
				break
			var td := heap_d[m]
			heap_d[m] = heap_d[k]
			heap_d[k] = td
			var tc := heap_c[m]
			heap_c[m] = heap_c[k]
			heap_c[k] = tc
			k = m
		if d > dist[c]:
			continue
		var ci := c % cn
		var cj := c / cn
		for o: Array in offs:
			var a: int = ci + int(o[0])
			var b: int = cj + int(o[1])
			if a < 0 or b < 0 or a >= cn or b >= cn:
				continue
			var q := b * cn + a
			if coarse[q] != 1:
				continue
			if int(o[0]) != 0 and int(o[1]) != 0 and (coarse[cj * cn + a] != 1 or coarse[b * cn + ci] != 1):
				continue   # no corner cutting
			var nd: float = d + float(o[2])
			if nd < dist[q]:
				dist[q] = nd
				# push
				var h := heap_d.size()
				heap_d.append(nd)
				heap_c.append(q)
				while h > 0:
					var p := (h - 1) / 2
					if heap_d[p] <= heap_d[h]:
						break
					var sd := heap_d[p]
					heap_d[p] = heap_d[h]
					heap_d[h] = sd
					var sc := heap_c[p]
					heap_c[p] = heap_c[h]
					heap_c[h] = sc
					h = p
	return dist


## The nearest main-component cell centre to `p` (x, z) as Vector3 (y = the polygon height), or Vector3.INF when
## none lies within `max_r` metres. Square rings outwards, then the closest cell of the first ring that has one.
func nearest_main(x: float, z: float, max_r: float = 20.0) -> Vector3:
	var ci := int(floor((x + half) / CELL))
	var cj := int(floor((z + half) / CELL))
	var rings := int(ceil(max_r / CELL))
	var first := -1
	var best_key := Vector2(INF, INF)
	var out := Vector3.INF
	for r in rings + 1:
		if first >= 0 and r > int(ceil(first * 1.42)) + 1:
			break
		for dj in range(-r, r + 1):
			for di in range(-r, r + 1):
				if absi(di) != r and absi(dj) != r:
					continue
				var a := ci + di
				var b := cj + dj
				if a < 0 or b < 0 or a >= n or b >= n or cell_comp[b * n + a] != main_comp:
					continue
				if first < 0:
					first = r
				var cx := -half + (float(a) + 0.5) * CELL
				var cz := -half + (float(b) + 0.5) * CELL
				# Distance rounded to 0.5 m, ties to the cell nearest the map centre: the same rule picks the mirror
				# cell for the mirror spot (a plain "first found" would pick the same corner of every obstacle).
				var key := Vector2(snappedf(Vector2(cx - x, cz - z).length(), 0.5), Vector2(cx, cz).length())
				if key.x < best_key.x or (key.x == best_key.x and key.y < best_key.y):
					best_key = key
					out = Vector3(cx, cell_y[b * n + a], cz)
	return out


## Navmesh width through `p` along `across` (normalised): walks both ways on the main component until it leaves it.
## If `p` itself is off the mesh, starts from the nearest main cell within 1.5 m. Returns {width, a, b, ok}.
func width_at(p: Vector2, across: Vector2, max_half: float = 20.0) -> Dictionary:
	var start := p
	if not walkable(p.x, p.y):
		var found := false
		for r in [0.25, 0.5, 0.75, 1.0, 1.25, 1.5]:
			for k in 16:
				var q: Vector2 = p + Vector2.from_angle(TAU * k / 16.0) * float(r)
				if walkable(q.x, q.y):
					start = q
					found = true
					break
			if found:
				break
		if not found:
			return {"width": 0.0, "a": p, "b": p, "ok": false}
	var d := across.normalized()
	var step := CELL * 0.5
	var t_plus := 0.0
	while t_plus < max_half:
		var q := start + d * (t_plus + step)
		if not walkable(q.x, q.y):
			break
		t_plus += step
	var t_minus := 0.0
	while t_minus < max_half:
		var q := start - d * (t_minus + step)
		if not walkable(q.x, q.y):
			break
		t_minus += step
	return {"width": t_plus + t_minus + CELL * 0.5, "a": start - d * t_minus, "b": start + d * t_plus,
		"ok": t_plus < max_half and t_minus < max_half}


## Cells whose "on the main navmesh" differs from their image under `xf` (ignoring 1-cell edge noise: a cell only
## counts when no cell within 1 of its image matches). Returns {mismatch, walkable, tiles: [[center, count]...]}.
func mirror_mismatch(xf: Transform3D, tile_m: float = 4.0) -> Dictionary:
	var mism := 0
	var total := 0
	var tiles := {}
	for j in n:
		var z := -half + (float(j) + 0.5) * CELL
		for i in n:
			var x := -half + (float(i) + 0.5) * CELL
			var here := cell_comp[j * n + i] == main_comp
			if here:
				total += 1
			var q := xf * Vector3(x, 0.0, z)
			var qi := int(floor((q.x + half) / CELL))
			var qj := int(floor((q.z + half) / CELL))
			var any_match := false
			for dj in [-1, 0, 1]:
				for di in [-1, 0, 1]:
					var a: int = qi + di
					var b: int = qj + dj
					var there := a >= 0 and b >= 0 and a < n and b < n and cell_comp[b * n + a] == main_comp
					if there == here:
						any_match = true
						break
				if any_match:
					break
			if not any_match:
				mism += 1
				var tk := Vector2i(int(floor((x + half) / tile_m)), int(floor((z + half) / tile_m)))
				tiles[tk] = int(tiles.get(tk, 0)) + 1
	var tl: Array = []
	for tk: Vector2i in tiles:
		tl.append([Vector2(-half + (tk.x + 0.5) * tile_m, -half + (tk.y + 0.5) * tile_m), int(tiles[tk])])
	tl.sort_custom(func(a: Array, b: Array) -> bool: return int(a[1]) > int(b[1]))
	return {"mismatch": mism, "walkable": total, "tiles": tl}


## Adds one path to the heat grid (each 1 m cell counted once per path).
func add_heat(path: PackedVector3Array, weight: float = 1.0) -> void:
	var seen := {}
	for k in range(path.size() - 1):
		var a := path[k]
		var b := path[k + 1]
		var seg_len := a.distance_to(b)
		var steps := maxi(1, int(ceil(seg_len / (HEAT_CELL * 0.5))))
		for s in steps + 1:
			var q := a.lerp(b, float(s) / float(steps))
			var i := int(floor((q.x + half) / HEAT_CELL))
			var j := int(floor((q.z + half) / HEAT_CELL))
			if i < 0 or j < 0 or i >= heat_n or j >= heat_n:
				continue
			var hk := j * heat_n + i
			if seen.has(hk):
				continue
			seen[hk] = true
			heat[hk] += weight


## The heat map image: one pixel per 0.25 m cell (+x right, +z down = the minimap view). Dark = no navmesh, grey =
## main navmesh, blue = islands, yellow -> red = how many shortest paths cross the metre (sqrt scale).
## `marks` = [{pos: Vector3, color: Color}] drawn as 5 px squares.
func heat_image(marks: Array) -> Image:
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var hmax := 0.0
	for v in heat:
		hmax = maxf(hmax, v)
	for j in n:
		for i in n:
			var c := cell_comp[j * n + i]
			var col := Color(0.12, 0.12, 0.14)
			if c == main_comp:
				col = Color(0.72, 0.74, 0.70)
			elif c >= 0:
				col = Color(0.35, 0.5, 0.85)
			if hmax > 0.0:
				var hi := int(floor(float(i) * CELL / HEAT_CELL))
				var hj := int(floor(float(j) * CELL / HEAT_CELL))
				var h := heat[hj * heat_n + hi] / hmax
				if h > 0.0:
					var hc := Color(1.0, 0.95, 0.2).lerp(Color(0.85, 0.05, 0.05), clampf(h, 0.0, 1.0))
					col = col.lerp(hc, clampf(1.1 * sqrt(h), 0.0, 0.92))
			img.set_pixel(i, j, col)
	for m: Dictionary in marks:
		var p: Vector3 = m["pos"]
		var ci := int(floor((p.x + half) / CELL))
		var cj := int(floor((p.z + half) / CELL))
		for dj in range(-2, 3):
			for di in range(-2, 3):
				var a := ci + di
				var b := cj + dj
				if a >= 0 and b >= 0 and a < n and b < n:
					img.set_pixel(a, b, Color.BLACK if absi(di) == 2 or absi(dj) == 2 else m["color"])
	return img


## The hottest heat cells (1 m), [[center Vector2, value]...], at least `spacing` metres apart.
func hot_spots(count: int, spacing: float = 8.0) -> Array:
	var cells: Array = []
	for j in heat_n:
		for i in heat_n:
			var v := heat[j * heat_n + i]
			if v > 0.0:
				cells.append([Vector2(-half + (i + 0.5) * HEAT_CELL, -half + (j + 0.5) * HEAT_CELL), v])
	cells.sort_custom(func(a: Array, b: Array) -> bool: return float(a[1]) > float(b[1]))
	var out: Array = []
	for c: Array in cells:
		var ok := true
		for o: Array in out:
			if (c[0] as Vector2).distance_to(o[0]) < spacing:
				ok = false
				break
		if ok:
			out.append(c)
			if out.size() >= count:
				break
	return out
