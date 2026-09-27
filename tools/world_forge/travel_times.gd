extends SceneTree
## Travel-time table for a World Forge map preview (docs/design/map-2v2-audit.md). Loads
## docs/tools/world_forge/out/<map>/preview.tscn (run `run_world_forge.ps1 map <map>` first), rasterises its navmesh with the
## Map Lab grid, runs a 16-neighbour Dijkstra (max error ~2.7 % vs a straight line, exactly mirror-invariant) from every
## seat's keep, with the ford slow (-35 %) on ford cells, and writes per seat the path length and walking time to every spot.
## Rows are grouped by the target's image in seat A1's frame, so the 4 (or 2) seats' numbers for "the same objective"
## sit on one row. Also the NavigationServer path length (what units walk today, engine noise included).
##   & tools/godot_run.ps1 --headless --path . -s res://tools/world_forge/travel_times.gd --quit-after 20000 '--' map=fourfold_hollow out=<dir>
## Writes <out>/<map>_travel.md and <map>_travel.json. Speeds: soldier 5.0 m/s (flame_guard), worker 4.6 m/s.

const MapGrid := preload("res://tools/map_lab/map_grid.gd")
const SOLDIER := 5.0
const WORKER := 4.6
const FORD_MULT := 1.0 / 0.65
const SEAT_SUFFIX := {0: "a1", 3: "a2", 1: "b1", 4: "b2"}

var opts := {}
var level: Node
var frame := 0
var ready_frame := -1


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		opts[kv[0]] = kv[1] if kv.size() > 1 else "1"
	var id := String(opts.get("map", "fourfold_hollow"))
	var path := "res://docs/tools/world_forge/out/%s/preview.tscn" % id
	if not ResourceLoader.exists(path):
		print("TRAVEL: FAIL no preview %s" % path)
		quit(1)
		return
	level = (load(path) as PackedScene).instantiate()
	root.add_child(level)


func _process(_d: float) -> bool:
	frame += 1
	if ready_frame < 0:
		if level.get(&"match_started") == true:
			ready_frame = frame
			print("TRAVEL: ready at frame %d" % frame)
		elif frame > 6000:
			print("TRAVEL: FAIL never ready")
			quit(1)
		return false
	if frame < ready_frame + 10:
		return false
	_run()
	quit(0)
	return true


func _run() -> void:
	var t0 := Time.get_ticks_msec()
	var layout: MapLayout = level.get(&"layout")
	var half := layout.size * 0.5
	var grid := MapGrid.new()
	grid.build(level.find_children("*", "NavigationRegion3D", true, false), half)
	grid.build_coarse()
	print("TRAVEL: grid %d ms" % (Time.get_ticks_msec() - t0))
	var cn: int = grid.coarse_n
	var step := 2.0 * MapGrid.CELL
	var mult := PackedFloat32Array()
	mult.resize(cn * cn)
	mult.fill(1.0)
	for c: Dictionary in layout.crossings:
		if String(c.get("kind", "")) != "ford":
			continue
		var cc: Vector3 = c["center"]
		var r := float(c.get("width", 7.0)) * 0.5
		for j in cn:
			var z := -half + (j + 0.5) * step
			for i in cn:
				var x := -half + (i + 0.5) * step
				if Vector2(x - cc.x, z - cc.z).length() <= r:
					mult[j * cn + i] = FORD_MULT
	var nav_map: RID = (level.get(&"nav_region") as NavigationRegion3D).get_navigation_map()
	# targets
	var targets: Array[Dictionary] = []
	for s: Dictionary in layout.spots:
		var k: String = s["kind"]
		if k == "start" or k == "slot":
			continue
		var p: Vector3 = s["pos"]
		var q := grid.nearest_main(p.x, p.z, 20.0)
		if q == Vector3.INF:
			continue
		targets.append({"id": s["id"], "kind": k, "sub": String(s.get("sub", "")), "props": s.get("props", {}),
			"pos": p, "nav": q, "cell": _near_cell(grid, q), "cells": _cells_near(grid, p, q)})
	for c: Dictionary in layout.crossings:
		var p: Vector3 = c["center"]
		var q := grid.nearest_main(p.x, p.z, 20.0)
		targets.append({"id": c["id"], "kind": "crossing", "sub": String(c.get("kind", "")), "props": {}, "pos": p,
			"nav": q, "cell": _near_cell(grid, q), "cells": _cells_near(grid, p, q)})
	# seats
	var seats: Array[Dictionary] = []
	for st: Dictionary in layout.seats:
		var team := int(st["team"])
		var keep := layout.keep_of(team)
		var kp: Vector3 = keep["pos"]
		var q := grid.nearest_main(kp.x, kp.z, 20.0)
		# Sources: every walkable coarse cell on the keep's rim (a mirror-invariant set: units leave by any face).
		var fp := float((keep.get("props", {}) as Dictionary).get("footprint", 6.0))
		var srcs := PackedInt32Array()
		var reach := fp * 0.5 + 0.75
		while srcs.is_empty() and reach < fp * 0.5 + 12.0:
			reach += 0.5
			for j in cn:
				var z := -half + (j + 0.5) * step
				if absf(z - kp.z) > reach:
					continue
				for i in cn:
					var x := -half + (i + 0.5) * step
					if absf(x - kp.x) <= reach and grid.coarse[j * cn + i] == 1:
						srcs.append(j * cn + i)
		var dist := _dijkstra(grid, mult, srcs)
		print("TRAVEL: seat %d dijkstra done %d ms" % [team, Time.get_ticks_msec() - t0])
		var row := {}
		for t: Dictionary in targets:
			var d := INF if t["cell"] < 0 else float(dist[t["cell"]])
			for cc: int in (t["cells"] as PackedInt32Array):
				d = minf(d, dist[cc])
			var np := NavigationServer3D.map_get_path(nav_map, q, t["nav"], true)
			var nl := 0.0
			for i in range(np.size() - 1):
				nl += np[i].distance_to(np[i + 1])
			row[t["id"]] = {"grid": d, "nav": nl}
		seats.append({"team": team, "name": st["name"], "frame": st["frame"], "keep": keep["id"], "row": row})
	# group targets by their image in the canonical (A1 / identity) frame
	var groups := {}
	var order: Array = []
	for si in seats.size():
		var s: Dictionary = seats[si]
		var fr: Transform3D = s["frame"]
		for t: Dictionary in targets:
			var cp: Vector3 = fr * (t["pos"] as Vector3)   # frames are reflections / half turns: self-inverse
			var key := "%s|%.1f|%.1f" % [t["kind"], snappedf(cp.x, 0.5), snappedf(cp.z, 0.5)]
			if not groups.has(key):
				groups[key] = {"kind": t["kind"], "sub": t["sub"], "props": t["props"], "cpos": cp, "per": {}}
				order.append(key)
			var g: Dictionary = groups[key]
			(g["per"] as Dictionary)[s["team"]] = {"id": t["id"], "grid": s["row"][t["id"]]["grid"], "nav": s["row"][t["id"]]["nav"]}
	var two := seats.size() == 2
	var rows: Array = []
	for key: String in order:
		var g: Dictionary = groups[key]
		var cp: Vector3 = g["cpos"]
		var rel := ""
		if two:
			rel = "own half" if cp.x < -0.5 else ("enemy half" if cp.x > 0.5 else "centre")
		else:
			var ax := absf(cp.x) < 0.5
			var az := absf(cp.z) < 0.5
			if ax and az:
				rel = "centre"
			elif ax:
				rel = "river (own side)" if cp.z > 0 else "river (ally side)"
			elif az:
				rel = "team midline" if cp.x < 0 else "enemy midline"
			elif cp.x < 0:
				rel = "own" if cp.z > 0 else "ally's"
			else:
				rel = "facing enemy's" if cp.z > 0 else "diagonal enemy's"
		var vals: Array[float] = []
		var navs: Array[float] = []
		for s: Dictionary in seats:
			var e: Dictionary = (g["per"] as Dictionary).get(s["team"], {})
			vals.append(float(e.get("grid", INF)))
			navs.append(float(e.get("nav", INF)))
		var mn: float = vals.min()
		var mx: float = vals.max()
		var name := String(((g["per"] as Dictionary).get(seats[0]["team"], {"id": "?"}) as Dictionary)["id"])
		rows.append({"name": name, "kind": g["kind"], "sub": g["sub"], "tier": str((g["props"] as Dictionary).get("tier", "")),
			"rel": rel, "grid": vals, "nav": navs, "spread": (mx - mn) / maxf(mn, 0.01) * 100.0, "mean": _mean(vals)})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["mean"]) < float(b["mean"]))
	# markdown
	var md := PackedStringArray()
	md.append("# Travel times: %s" % layout.title)
	md.append("")
	md.append("16-neighbour Dijkstra on the preview navmesh (0.5 m grid, ford cells x%.2f), from each keep's navmesh point. Soldier %.1f m/s, worker %.1f m/s. `nav` = NavigationServer path (engine, not mirrored)." % [FORD_MULT, SOLDIER, WORKER])
	md.append("")
	var hdr := "| Target (A1 view) | Kind | Where | "
	var sep := "|---|---|---|"
	for s: Dictionary in seats:
		hdr += "%s m | " % SEAT_SUFFIX.get(int(s["team"]), str(s["team"]))
		sep += "---|"
	hdr += "spread | soldier s | worker s | nav min-max m |"
	sep += "---|---|---|---|"
	md.append(hdr)
	md.append(sep)
	for r: Dictionary in rows:
		var line := "| %s | %s%s | %s | " % [r["name"], r["kind"], (" " + String(r["sub"]) + String(r["tier"])) if (String(r["sub"]) + String(r["tier"])) != "" else "", r["rel"]]
		for v: float in r["grid"]:
			line += "%.1f | " % v
		var nv: Array[float] = r["nav"]
		line += "%.1f %% | %.1f | %.1f | %.1f-%.1f |" % [r["spread"], float(r["mean"]) / SOLDIER, float(r["mean"]) / WORKER, nv.min(), nv.max()]
		md.append(line)
	md.append("")
	# Contest: per spot, the nearest seat of each side; a spot is "contested" when the two sides are within 15 %.
	md.append("## Contest per spot (nearest seat of each side, m; contested = sides within 15 %)")
	md.append("")
	md.append("| Spot | Kind | nearest side 0 | m | nearest side 1 | m | ratio 0/1 | |")
	md.append("|---|---|---|---|---|---|---|---|")
	var side_of := {}
	for st: Dictionary in layout.seats:
		side_of[int(st["team"])] = int(st["side"])
	var raw: Array = []
	for t: Dictionary in targets:
		if t["kind"] == "keep" or t["kind"] == "crossing":
			continue
		var best := [INF, INF]
		var who := ["", ""]
		for s: Dictionary in seats:
			var sd: int = side_of[int(s["team"])]
			var d: float = s["row"][t["id"]]["grid"]
			if d < best[sd]:
				best[sd] = d
				who[sd] = SEAT_SUFFIX.get(int(s["team"]), str(s["team"]))
		var ratio: float = best[0] / maxf(best[1], 0.01)
		var tag := "contested" if absf(best[0] - best[1]) / minf(best[0], best[1]) <= 0.15 else ""
		raw.append({"id": t["id"], "kind": t["kind"], "d0": best[0], "d1": best[1], "w0": who[0], "w1": who[1], "ratio": ratio, "tag": tag})
	raw.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["id"]) < String(b["id"]))
	for e: Dictionary in raw:
		md.append("| %s | %s | %s | %.1f | %s | %.1f | %.2f | %s |" % [e["id"], e["kind"], e["w0"], e["d0"], e["w1"], e["d1"], e["ratio"], e["tag"]])
	md.append("")
	md.append("%d targets, %d seats, %.1f s." % [rows.size(), seats.size(), (Time.get_ticks_msec() - t0) / 1000.0])
	var out := String(opts.get("out", "user://"))
	DirAccess.make_dir_recursive_absolute(out)
	var f := FileAccess.open(out.path_join("%s_travel.md" % layout.id), FileAccess.WRITE)
	f.store_string("\n".join(md) + "\n")
	f.close()
	var jrows: Array = []
	for r: Dictionary in rows:
		jrows.append({"name": r["name"], "kind": r["kind"], "sub": r["sub"], "tier": r["tier"], "rel": r["rel"],
			"grid": r["grid"], "nav": r["nav"], "spread": r["spread"]})
	var fj := FileAccess.open(out.path_join("%s_travel.json" % layout.id), FileAccess.WRITE)
	fj.store_string(JSON.stringify({"map": layout.id, "seats": seats.map(func(s: Dictionary) -> int: return int(s["team"])), "rows": jrows}, "\t"))
	fj.close()
	print("TRAVEL: OK %s %d rows -> %s" % [layout.id, rows.size(), out])


static func _mean(v: Array[float]) -> float:
	var s := 0.0
	for x in v:
		s += x
	return s / maxf(1.0, v.size())


## Every walkable coarse cell within (distance spot -> its nearest navmesh point) + 1 m of the spot: a mirror-invariant
## entry set (a building's nearest face is a tie between faces; the min over the set picks the one facing the walker).
static func _cells_near(grid: RefCounted, p: Vector3, q: Vector3) -> PackedInt32Array:
	var out := PackedInt32Array()
	if q == Vector3.INF:
		return out
	var rad := Vector2(q.x - p.x, q.z - p.z).length() + 1.0
	var step: float = 2.0 * MapGrid.CELL
	var k := int(ceil(rad / step)) + 1
	var cn: int = grid.coarse_n
	var h: float = grid.half
	for dj in range(-k, k + 1):
		for di in range(-k, k + 1):
			var ci: int = grid.coarse_index(p.x + di * step, p.z + dj * step)
			if ci < 0 or grid.coarse[ci] != 1:
				continue
			var cx := -h + (ci % cn + 0.5) * step
			var cz := -h + (ci / cn + 0.5) * step
			if Vector2(cx - p.x, cz - p.z).length() <= rad and not out.has(ci):
				out.append(ci)
	return out


## The walkable coarse cell nearest a navmesh point (Map Lab's 2 m search, then up to 6 m).
static func _near_cell(grid: RefCounted, q: Vector3) -> int:
	if q == Vector3.INF:
		return -1
	var c: int = grid.coarse_near(q.x, q.z)
	if c >= 0:
		return c
	for r in [2.5, 3.0, 4.0, 5.0, 6.0]:
		for k in 24:
			var p: Vector2 = Vector2(q.x, q.z) + Vector2.from_angle(TAU * k / 24.0) * float(r)
			var ci: int = grid.coarse_index(p.x, p.y)
			if ci >= 0 and grid.coarse[ci] == 1:
				return ci
	return -1


## Dijkstra on the coarse grid, 16 neighbours (octile + knight moves), per-cell cost multiplier.
static func _dijkstra(grid: RefCounted, mult: PackedFloat32Array, srcs: PackedInt32Array) -> PackedFloat32Array:
	var cn: int = grid.coarse_n
	var coarse: PackedByteArray = grid.coarse
	var step: float = 2.0 * MapGrid.CELL
	var dist := PackedFloat32Array()
	dist.resize(cn * cn)
	dist.fill(INF)
	var hd := PackedFloat32Array()
	var hc := PackedInt32Array()
	for src in srcs:
		if src >= 0 and dist[src] > 0.0:
			dist[src] = 0.0
			hd.append(0.0)
			hc.append(src)
	var offs: Array = []
	for o in [[1, 0], [-1, 0], [0, 1], [0, -1], [1, 1], [1, -1], [-1, 1], [-1, -1],
			[1, 2], [2, 1], [-1, 2], [-2, 1], [1, -2], [2, -1], [-1, -2], [-2, -1]]:
		offs.append([o[0], o[1], step * Vector2(o[0], o[1]).length()])
	while hd.size() > 0:
		var d := hd[0]
		var c := hc[0]
		var last := hd.size() - 1
		hd[0] = hd[last]
		hc[0] = hc[last]
		hd.resize(last)
		hc.resize(last)
		var k := 0
		while true:
			var l := 2 * k + 1
			if l >= last:
				break
			var r := l + 1
			var m := l if r >= last or hd[l] <= hd[r] else r
			if hd[m] >= hd[k]:
				break
			var td := hd[m]
			hd[m] = hd[k]
			hd[k] = td
			var tc := hc[m]
			hc[m] = hc[k]
			hc[k] = tc
			k = m
		if d > dist[c]:
			continue
		var ci := c % cn
		var cj := c / cn
		for o: Array in offs:
			var dx: int = o[0]
			var dz: int = o[1]
			var a := ci + dx
			var b := cj + dz
			if a < 0 or b < 0 or a >= cn or b >= cn:
				continue
			var q := b * cn + a
			if coarse[q] != 1:
				continue
			if absi(dx) == 1 and absi(dz) == 1:
				if coarse[cj * cn + a] != 1 or coarse[b * cn + ci] != 1:
					continue
			elif absi(dx) + absi(dz) == 3:
				# knight move: both cells it sweeps through must be walkable
				var sx := signi(dx)
				var sz := signi(dz)
				var m1 := (cj + sz) * cn + ci + sx
				var m2 := (cj + (sz if absi(dz) == 2 else 0)) * cn + ci + (sx if absi(dx) == 2 else 0)
				if coarse[m1] != 1 or coarse[m2] != 1:
					continue
			var nd: float = d + float(o[2]) * 0.5 * (mult[c] + mult[q])
			if nd < dist[q] - 0.001:   # epsilon: float32 ties must not re-open settled cells (cascade)
				dist[q] = nd
				var h := hd.size()
				hd.append(nd)
				hc.append(q)
				while h > 0:
					var p := (h - 1) / 2
					if hd[p] <= hd[h]:
						break
					var sd := hd[p]
					hd[p] = hd[h]
					hd[h] = sd
					var sc := hc[p]
					hc[p] = hc[h]
					hc[h] = sc
					h = p
	return dist
