class_name ArtLabCheckBudgets
extends RefCounted
## Art Lab checks (docs/plan/art-lab.md section 3): budgets and health, the checks that need no renderer (they run
## first, also headless, and decide `fail_fast`). B1-B8 / B1a / B11 / B12 census vs the budget row, B9 / B9m
## per-instance resources, B10 allocations after the actions, B13 frame cost (windowed), H1 / H2 errors caught during
## the run. The numbers live in lab_budgets.gd (one editor at a time).

const KIT_DIR := "res://art/units/kit/"


static func check_budgets(ctx: ArtLabRunner, cen: Dictionary) -> void:
	var r := ctx.rep.budget_row
	var src: String = r.get("src", "")
	var rows: Array = [
		["B1", "Meshes after the kit merge", "meshes", int(cen["meshes"]) + int(cen["multimeshes"]),
			"Merge static parts per pivot (kit merge), drop hidden / duplicate parts, repeats as one MultiMesh"],
		["B2", "Draw instances at rest", "draw", int(cen["draw"]),
			"Fewer keep_separate parts, bake static props into one mesh, one MultiMesh per repeated part"],
		["B3", "keep_separate parts", "separate", int(cen["separate"]),
			"Only toggled / animated / own-glow parts stay separate (art-units 2.3)"],
		["B4", "Vertices", "verts", int(cen["verts"]), "Fewer segments (cylinders 6-8, spheres radial 10 / rings 5), no hidden faces"],
		["B4t", "Triangles", "tris", int(cen["tris"]), "Fewer segments; critters use a vertex-shader cycle, not more geometry"],
		["B5", "Real lights", "lights", int(cen["lights"]),
			"No Light3D: emission >= 2.5 on the glow part and the bloom carries it (art-keep 0.4)"],
		["B6", "Particle systems", "systems", int(cen["systems"]), "One system with emission points instead of several; pre-built one-shots"],
		["B6l", "Looping particle systems", "looping", int(cen["looping"]),
			"Looping systems only where the spec lists them; stop them beyond 45 m (kit does it for GPUParticles3D)"],
		["B6p", "Looping particles alive", "particles", int(cen["particles"]), "Lower `amount`, longer lifetime, bigger soft sprites"],
		["B7", "Shadow casters", "casters", int(cen["casters"]), "cast_shadow only on the 3-4 biggest parts (art-units 1.5 / 8)"],
		["B8", "Unique materials", "materials", int(cen["materials"]), "Snap to the closed palette (art-units 2.2); no per-part materials"],
	]
	for row_def: Array in rows:
		var key: String = row_def[2]
		var v: int = row_def[3]
		var lim := ArtLabBudgets.limit(r, key)
		if lim.is_empty():
			if key in ["meshes", "draw", "verts", "materials", "casters"] or v > 0:
				if key == "tris" or (key == "separate" and v == 0):
					continue
				ctx.rep.add(row_def[0], "budget", row_def[1], "INFO", str(v), "no budget for %s/%s" % [ctx.kind, ctx.tier])
			continue
		var st := ArtLabScore.budget_status(float(v), lim)
		var l := float(lim["limit"])
		var extra := ""
		if key == "meshes":
			extra = " drawn (%d mesh + %d multimesh)" % [int(cen["meshes"]), int(cen["multimeshes"])]
			var piv := meshes_per_pivot(cen["mesh_list"])
			if not piv.is_empty():
				extra += "; per pivot: " + ", ".join(PackedStringArray(piv.slice(0, 6).map(func(p: Array) -> String: return "%s %d" % [p[0], p[1]])))
				if st != "PASS" and int(piv[0][1]) >= 3:
					ctx.rep.extras.push_front({"title": "Meshes per pivot", "source": "B1", "text":
						"Pivot %s draws %d meshes: merge its static parts into one (the kit merge works per pivot; separate materials or keep_separate parts stop it)" % [piv[0][0], int(piv[0][1])]})
		if key == "verts" and not (cen["mesh_list"] as Array).is_empty():
			var top: Array[String] = []
			for me: Dictionary in (cen["mesh_list"] as Array).slice(0, 4):
				top.append("%s %d" % [String(me["name"]).get_file(), int(me["verts"])])
			extra = " (biggest: %s)" % ", ".join(top)
		if key == "lights" and v > 0:
			extra = " (%s)" % ", ".join(PackedStringArray(cen["light_names"]))
		if key == "looping" and v > 0:
			extra = " (%s)" % ", ".join(PackedStringArray(cen["looping_names"]))
		if key == "casters" and v > 0:
			extra = " (%s)" % ", ".join(PackedStringArray((cen["caster_names"] as Array).slice(0, 6)))
		var g := ArtLabScore.grade(float(v), l * 1.3 + 1.0, l * 0.7) if l > 0.0 else (1.0 if v == 0 else 0.0)
		ctx.rep.add(row_def[0], "budget", row_def[1], st, "%d%s" % [v, extra],
			"<= %s%s (%s)" % [str(lim["limit"]), "" if bool(lim["hard"]) else " soft", src],
			row_def[4] if st != "PASS" else "", g, "" if st == "PASS" else row_def[4])
	# B1a: authored build parts before the merge (v1's B1; INFO since the user decision 2026-09-26: render cost counts)
	var authored := int(ctx.m.get("authored", cen["meshes"]))
	var lim_m := ArtLabBudgets.limit(r, "meshes")
	ctx.rep.add("B1a", "budget", "Authored build parts (before the merge)", "INFO", "%d%s" % [authored,
		(" (model says %d)" % int(ctx.m["authored_claim"])) if ctx.m.has("authored_claim") else ""],
		"info only: authoring detail is cheap when the kit merges it (B1 counts the drawn meshes)%s" % ((", v1 limit %s" % str(lim_m["limit"])) if not lim_m.is_empty() else ""))
	# per-mesh vertex breakdown, surfaces, downward-facing waste
	var ml: Array = cen["mesh_list"]
	if not ml.is_empty():
		var rows_txt: Array[String] = []
		for me2: Dictionary in ml.slice(0, 8):
			rows_txt.append("%s %d v / %d s%s" % [String(me2["name"]), int(me2["verts"]), int(me2["surfaces"]),
				(" x%d" % int(me2["n"])) if int(me2["n"]) > 1 else ""])
		ctx.rep.notes.append("Per-mesh vertices (biggest first): " + "; ".join(rows_txt))
		var surf := int(cen["surfaces"])
		ctx.rep.add("B11", "budget", "Surfaces per instance", "INFO", "%d surfaces over %d meshes (each surface = 1 draw call)" % [surf, ml.size()],
			"about 1 surface per mesh after the merge; extra surfaces cost draw calls like extra meshes",
			"", -1.0, "")
		var dn := int(cen["down_tris"])
		var share := float(dn) / float(maxi(int(cen["tris"]), 1))
		# INFO + hint only: rounded bodies have ~15 % steep-down faces by nature; above ~25 % caps / undersides are waste
		ctx.rep.add("B12", "budget", "Downward-facing triangles", "INFO", "%d of %d triangles (%d%%) face steeply down (normal y < -0.7)" % [dn, int(cen["tris"]), int(share * 100.0)],
			"hint when > 25 %: the camera looks from above (pitch 55); a sphere has ~15 %, bottom caps add the rest",
			"", -1.0, "")
		if share > 0.25 and dn > 150:
			ctx.rep.extras.push_front({"title": "Downward-facing waste", "source": "B12", "text":
				"Drop bottom caps / undersides (cylinders, boxes, plinths, hat brims seen from below): %d%% of the triangles face down and are never seen" % int(share * 100.0)})
		if surf > ml.size() + 2:
			ctx.rep.extras.push_front({"title": "Surfaces per instance", "source": "B11", "text":
				"Merge surfaces that share a material (%d surfaces for %d meshes = %d draw calls)" % [surf, ml.size(), surf]})
	if int(cen["hidden_parts"]) > 0:
		ctx.rep.notes.append("%d hidden parts at rest (toggled states, not counted as draws)" % int(cen["hidden_parts"]))
	if int(cen["code_materials"]) > 0:
		ctx.rep.notes.append("%d materials are built in code (fine when cached per type: see B9)" % int(cen["code_materials"]))


## B1 breakdown: drawn meshes grouped by their parent node (the kit pivot: Torso, Head, ArmR...), biggest first,
## as [[pivot, count], ...]. A pivot with several drawn meshes is where a merge is missing.
static func meshes_per_pivot(mesh_list: Array) -> Array:
	var by := {}
	for me: Dictionary in mesh_list:
		var p := String(me["name"]).get_base_dir()
		var key := p.get_file() if p != "" else "(root)"
		by[key] = int(by.get(key, 0)) + 1
	var out: Array = []
	for k: String in by:
		out.append([k, int(by[k])])
	out.sort_custom(func(a: Array, b: Array) -> bool: return int(a[1]) > int(b[1]) or (int(a[1]) == int(b[1]) and String(a[0]) < String(b[0])))
	return out


static func check_instances(ctx: ArtLabRunner) -> void:
	var r1 := ArtLabCensus.resource_ids(ctx.target)
	var far := Node3D.new()
	far.position = ctx.gp + Vector3(400.0, 0.0, 400.0)
	ctx.stage.world.add_child(far)
	var second := ctx.spawn(ctx.scene_path, Vector3.ZERO, 0.0, far)
	await ctx.frames(4)
	if second == null:
		far.queue_free()
		return
	var r2 := ArtLabCensus.resource_ids(second)
	var mats := 0
	var meshes := 0
	for id: int in r2["materials"]:
		if not (r1["materials"] as Dictionary).has(id):
			mats += 1
	for id2: int in r2["meshes"]:
		if not (r1["meshes"] as Dictionary).has(id2):
			meshes += 1
	far.queue_free()
	var lim := ArtLabBudgets.limit(ctx.rep.budget_row, "runtime_mats")
	var st := ArtLabScore.budget_status(float(mats), lim) if not lim.is_empty() else ("WARN" if mats > 0 else "PASS")
	# art-keep 8.6: a building may duplicate its materials once per instance (selection rim, owner colour, damage
	# tint): a handful of buildings per map, so accepted (INFO, full score) up to 2x the building's own material
	# budget; beyond that it is a real per-instance leak (WARN).
	var accepted := false
	if ctx.kind in [&"building", &"landmark"] and st == "WARN":
		var mlim := ArtLabBudgets.limit(ctx.rep.budget_row, "materials")
		var cap := int(float(mlim["limit"]) * 2.0) if not mlim.is_empty() else 16
		if mats <= cap:
			st = "INFO"
			accepted = true
	ctx.rep.add("B9", "health", "Materials built per instance", st, "%d material(s), %d mesh(es) not shared by a 2nd instance%s" % [mats, meshes,
		" (per-building copies, accepted by art-keep 8.6)" if accepted else ""],
		"0: materials / meshes are shared per type (art-units 2.2: zero runtime materials); buildings may copy theirs per instance (art-keep 8.6)",
		"Cache built materials / meshes in a static dictionary keyed by type (or save them as .tres / .res); per-unit looks go through instance uniforms",
		1.0 if mats == 0 or accepted else 0.0, "" if mats == 0 or accepted else "Share the %d per-instance material(s) (static cache) so 200 units do not build 200 copies" % mats)
	if meshes > 0 and mats == 0:
		ctx.rep.add("B9m", "health", "Meshes built per instance", "WARN", "%d mesh(es) per instance" % meshes,
			"meshes shared per type", "Build meshes once (static cache or .res) and share them", 0.5,
			"Cache the %d per-instance mesh(es) in a static dictionary" % meshes)


## Runs the usual actions once and watches for nodes / materials created after _ready.
static func action_cycle(ctx: ArtLabRunner) -> void:
	var nodes0 := ctx.count_nodes(ctx.target)
	var seen1: Dictionary = (ArtLabCensus.resource_ids(ctx.target)["materials"] as Dictionary).duplicate()
	var created: Array[int] = [0]
	var cb := func(n: Node) -> void:
		if is_instance_valid(ctx.target) and ctx.target.is_ancestor_of(n):
			created[0] += 1
	ctx.get_tree().node_added.connect(cb)
	# Cycle 1 learns every material the actions show (cached / swapped ones included); cycle 2 counts only materials
	# never seen before: a material.duplicate() per action shows up again, a static cache does not.
	await actions_once(ctx, seen1)
	var created1 := created[0]
	var nodes1 := ctx.count_nodes(ctx.target)
	var seen2: Dictionary = {}
	await actions_once(ctx, seen2)
	ctx.get_tree().node_added.disconnect(cb)
	var created2 := created[0] - created1
	var new_mats := 0
	var swapped := 0
	for id: int in seen2:
		if seen1.has(id):
			continue
		if String(seen2[id]) != "":
			swapped += 1   # a saved resource: shared, never "built"
			continue
		new_mats += 1
	if swapped > 0:
		ctx.rep.notes.append("B10: %d saved material(s) swapped in by the actions (shared resources, not counted)" % swapped)
	var net := nodes1 - nodes0
	var hard := ctx.kind in [&"unit", &"mount", &"titan", &"beast", &"critter"]
	var st := "PASS"
	if new_mats > 0:
		st = "FAIL" if hard else "WARN"
	elif created1 > 0 or net > 0:
		st = "WARN"
	ctx.rep.add("B10", "health", "Allocations after _ready (actions)", st,
		"%d node(s) created, net %+d, 2nd action cycle: %d node(s), %d new material(s)" % [created1, net, created2, new_mats],
		"0: pre-built emitters restarted, instance uniforms for flashes (art-units 6.10); materials swapped from a cache are not new",
		"Pre-build the effect nodes as hidden children and restart / toggle them; never material.duplicate() in an action",
		1.0 if st == "PASS" else (0.5 if st == "WARN" else 0.0),
		"" if st == "PASS" else "Pre-build what the actions create (%d nodes, %d materials) and reuse it" % [created1, new_mats])


## One pass of the kind's usual actions; every material the model shows after each step goes into `seen`.
static func actions_once(ctx: ArtLabRunner, seen: Dictionary) -> void:
	var sample := func() -> void:
		if is_instance_valid(ctx.target):
			seen.merge(ArtLabCensus.resource_ids(ctx.target)["materials"])
	await actions_steps(ctx, sample)


static func actions_steps(ctx: ArtLabRunner, sample: Callable) -> void:
	match ctx.kind:
		&"building", &"landmark":
			ctx.call_hook(ctx.target, &"set_selected", [true])
			ctx.call_hook(ctx.target, &"set_health_ratio", [0.4])
			await ctx.wait(0.6)
			sample.call()
			ctx.call_hook(ctx.target, &"play_training_pulse")
			await ctx.wait(0.8)
			sample.call()
			ctx.call_hook(ctx.target, &"set_health_ratio", [1.0])
			ctx.call_hook(ctx.target, &"set_selected", [false])
			await ctx.wait(0.6)
			sample.call()
		&"critter":
			for step: Array in [[&"play_move", [ctx.stride], 0.8], [&"play_flee", [], 0.6], [&"play_hit", [], 0.4], [&"play_idle", [], 0.6]]:
				ctx.call_hook(ctx.target, step[0], step[1])
				await ctx.wait(float(step[2]))
				sample.call()
		_:
			if ctx.call_hook(ctx.target, &"set_moving", [ctx.stride]):
				await ctx.wait(1.0)
				sample.call()
				ctx.call_hook(ctx.target, &"set_moving", [0.0])
			if ctx.call_hook(ctx.target, &"play_attack"):
				await ctx.wait(1.0)
				sample.call()
			if ctx.call_hook(ctx.target, &"play_hit"):
				await ctx.wait(0.5)
				sample.call()
			if ctx.kind == &"beast" or ctx.tier in [&"wizard", &"champion"]:
				if ctx.call_hook(ctx.target, &"play_cast", [&"lab_cast"]):
					await ctx.wait(1.0)
					sample.call()
			await ctx.wait(0.5)
			sample.call()


static func measure(ctx: ArtLabRunner, frames: int, tick: Callable = Callable()) -> Vector3:
	var proc := 0.0
	var cpu := 0.0
	var gpu := 0.0
	var t0 := Time.get_ticks_usec()
	for i: int in frames:
		if tick.is_valid():
			tick.call(i)
		await ctx.get_tree().process_frame
		proc += Performance.get_monitor(Performance.TIME_PROCESS)
		var r := ctx.stage.render_ms()
		cpu += r.x
		gpu += r.y
	var wall := float(Time.get_ticks_usec() - t0) / 1000.0 / float(frames)
	# TIME_PROCESS is documented in seconds; this build reports milliseconds. A per-frame process time can never exceed
	# the wall frame time, so a value that would (x 1000) is already in ms.
	var p := proc / float(frames)
	if p * 1000.0 <= wall * 1.5:
		p *= 1000.0
	if ctx.opts.get("debug", "0") == "1":
		print("  measure: %d frames, wall %.2f ms/frame, process %.4f ms, render cpu %.2f gpu %.2f" % [frames, wall, p,
			cpu / frames, gpu / frames])
	return Vector3(p, cpu / float(frames), gpu / float(frames))


static func frame_cost(ctx: ArtLabRunner) -> void:
	var row := ctx.rep.budget_row
	var n := int(ctx.opts.get("n", row.get("n", 20)))
	if n <= 0:
		return
	ctx.stage.game_cam(ctx.gp, 40.0)
	ctx.holder.visible = false
	ArtLabStage.freeze(ctx.target, true)
	await ctx.frames(10)
	var base: Vector3 = await measure(ctx, 90)
	var box: AABB = ctx.m["box"]
	var step := maxf(maxf(box.size.x, box.size.z) + 0.6, 1.2)
	var cols := int(ceil(sqrt(float(n))))
	var inst: Array[Node3D] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i: int in n:
		var at := ctx.gp + Vector3((float(i % cols) - float(cols - 1) * 0.5) * step, 0.0, (float(i / cols) - float(cols - 1) * 0.5) * step)
		var mm := ctx.spawn(ctx.scene_path, at, rng.randf_range(0.0, 360.0))
		if mm:
			inst.append(mm)
	await ctx.frames(5)
	for i2: int in inst.size():
		if i2 % 2 == 0:
			ctx.call_hook(inst[i2], &"set_moving", [ctx.stride])
			ctx.call_hook(inst[i2], &"play_move", [ctx.stride])
	await ctx.frames(30)
	var tick := func(f: int) -> void:
		if f % 3 == 0 and not inst.is_empty():
			var u: Node3D = inst[(f / 3) % inst.size()]
			if is_instance_valid(u) and u.has_method(&"play_attack"):
				u.call(&"play_attack")
	var meas: Vector3 = await measure(ctx, 120, tick)
	var per := maxf(meas.x - base.x, 0.0) / float(maxi(inst.size(), 1))   # < 0 = noise
	var lim := ArtLabBudgets.limit(row, "frame_ms")
	# v3.1 (trial note 6): over the budget = measure again before judging (the same Shade measured 0.28 ms then 0: a
	# busy PC spikes one window); the lower of the two runs is kept, both are in the notes
	if not lim.is_empty() and per > float(lim["limit"]):
		var meas2: Vector3 = await measure(ctx, 120, tick)
		for mm3: Node3D in inst:
			ctx.free_model(mm3)
		await ctx.frames(10)
		var base2: Vector3 = await measure(ctx, 90)
		var per2 := maxf(meas2.x - base2.x, 0.0) / float(maxi(inst.size(), 1))
		ctx.rep.notes.append("B13 over the budget on the first window (%s ms): re-measured %s ms, kept the lower" % [ctx.fmt(per, 4), ctx.fmt(per2, 4)])
		if per2 < per:
			per = per2
			meas = meas2
			base = base2
	else:
		for mm2: Node3D in inst:
			ctx.free_model(mm2)
	ctx.holder.visible = true
	ArtLabStage.freeze(ctx.target, false)
	await ctx.frames(2)
	var st := ArtLabScore.budget_status(per, lim)
	if st == "FAIL" and per <= float(lim.get("limit", 0.0)) * 1.5:
		st = "WARN"   # v2 noise band: 1-1.5 x the budget on a loaded PC is not a verdict; re-run quiet to confirm
		ctx.rep.notes.append("B13 in the noise band (%s ms, budget %s): re-run on a quiet PC before fixing" % [ctx.fmt(per, 4), str(lim.get("limit", "-"))])
	var val := "%s ms process per instance (%d animated at 40 m: +%s ms process, render CPU +%s ms, GPU +%s ms)" % [
		ctx.fmt(per, 4), inst.size(), ctx.fmt(meas.x - base.x, 2), ctx.fmt(meas.y - base.y, 2), ctx.fmt(meas.z - base.z, 2)]
	var l := float(lim.get("limit", 0.01))
	ctx.rep.add("B13", "budget", "Frame cost", st, val,
		"<= %s ms per instance%s (%s)" % [str(lim.get("limit", "-")), "" if bool(lim.get("hard", true)) else " soft", row.get("src", "")],
		"One _process per model, cached pivots, no get_node / allocation per frame, respect the distance tiers (art-units 6.10)",
		ArtLabScore.grade(per, l * 1.5, l * 0.4), "Cut the per-frame script cost (%s ms per instance): write pivots only when they change, skip work at the far tiers" % ctx.fmt(per, 4) if per > l * 0.6 else "")


static func check_errors(ctx: ArtLabRunner) -> void:
	ctx.logger.mutex.lock()
	var entries := ctx.logger.entries.duplicate()
	ctx.logger.mutex.unlock()
	var own_dir := ctx.scene_path.get_base_dir()
	var asset_err: Array[String] = []
	var asset_warn: Array[String] = []
	var other: Array[String] = []
	var lab: Array[String] = []
	for e: Dictionary in entries:
		var f: String = e["file"]
		var line := "%s:%d %s" % [f.get_file(), int(e["line"]), String(e["msg"]).left(140)]
		if "tools/art_lab" in f:
			lab.append(line)
		elif f.begins_with(own_dir) or f.begins_with(KIT_DIR) or f == ctx.scene_path:
			if int(e["type"]) == 1:
				asset_warn.append(line)
			else:
				asset_err.append(line)
		else:
			other.append(line)
	var st := "PASS"
	if not asset_err.is_empty():
		st = "FAIL"
	elif not asset_warn.is_empty():
		st = "WARN"
	var shown := asset_err.slice(0, 3) + asset_warn.slice(0, 3)
	ctx.rep.add("H1", "health", "Errors from the asset while running", st, "%d error(s), %d warning(s)%s" % [asset_err.size(), asset_warn.size(),
		(": " + " / ".join(shown)) if not shown.is_empty() else ""], "0 (its folder + the kit)", "Fix the errors listed (full list in the console)",
		1.0 if st == "PASS" else (0.5 if st == "WARN" else 0.0))
	if not other.is_empty():
		ctx.rep.add("H2", "health", "Errors from other files during the run", "INFO", "%d: %s" % [other.size(), " / ".join(other.slice(0, 3))],
			"not the asset's fault (shared shaders, systems); report them to their owner")
	if not lab.is_empty():
		ctx.rep.notes.append("Art Lab errors (a lab bug, tell the lead): " + " / ".join(lab.slice(0, 4)))
