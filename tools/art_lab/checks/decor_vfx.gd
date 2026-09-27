class_name ArtLabCheckDecorVfx
extends RefCounted
## Art Lab checks (docs/plan/art-lab.md section 3): the two non-model kinds. Decor sets (D1-D9, patch R5 / B13: a
## 30 x 30 m scattered patch with 4 kingdom units in it) and VFX families (B5, V2-V6, B13: every id played at 40 m).

const DECOR_UNITS: Array[String] = ["res://art/units/fire/flame_guard.tscn", "res://art/units/shadow/shade.tscn",
	"res://art/units/ice/rimeshield.tscn", "res://art/units/nature/thornling.tscn"]


static func run_decor(ctx: ArtLabRunner) -> void:
	var scr := load(ctx.scene_path) as GDScript
	if scr == null:
		ctx.rep.add("H0", "health", "Set script loads", "FAIL", "not a GDScript", "biome set file (map-fill.md 10)")
		return
	var consts := scr.get_script_constant_map()
	var entries: Array = consts.get("ENTRIES", [])
	var biome: StringName = consts.get("BIOME_ID", &"")
	if ctx.opts.get("ground", "") == "" and ArtLabStage.GROUND_POINTS.has(biome):
		ctx.ground_id = biome
	ctx.gp = ArtLabStage.GROUND_POINTS[ctx.ground_id]
	ctx.rep.add("H0", "health", "Set script loads", "PASS" if not entries.is_empty() else "FAIL", "%d entries, biome %s" % [entries.size(), biome],
		"ENTRIES / BIOME_ID / GROUND_TINT (map-fill.md 10)")
	var row := ctx.rep.budget_row
	# D1 kinds
	var lk := ArtLabBudgets.limit(row, "kinds")
	var stk := ArtLabScore.budget_status(float(entries.size()), lk)
	ctx.rep.add("D1", "decor", "Mesh kinds in the set", stk, str(entries.size()), "<= %s soft (map total <= 24 kinds, map-fill.md 9)" % str(lk.get("limit", "-")),
		"Merge look-alike kinds; use the 3 shape variants of nature_painted instead of new meshes", 1.0 if stk == "PASS" else 0.5)
	# per entry
	var max_tris := 0
	var tri_list: Array[String] = []
	var bad_shadow: Array[String] = []
	var bad_range: Array[String] = []
	var density := 0.0
	var mats := {}
	var meshes: Array[Mesh] = []
	for e: Dictionary in entries:
		var path: String = e.get("mesh", "")
		var mesh: Mesh = load(path) as Mesh if ResourceLoader.exists(path) else null
		meshes.append(mesh)
		if mesh == null:
			bad_range.append("%s missing" % path.get_file())
			continue
		var stt := ArtLabCensus.mesh_stats(mesh)
		max_tris = maxi(max_tris, stt.y)
		tri_list.append("%s %d" % [path.get_file().get_basename(), stt.y])
		for s: int in mesh.get_surface_count():
			if mesh.surface_get_material(s):
				mats[mesh.surface_get_material(s).get_instance_id()] = true
		var nm := path.get_file().to_lower()
		var big := false
		for w: String in ["tree", "log", "rock", "boulder", "stump", "trunk", "willow"]:
			if w in nm:
				big = true
		if bool(e.get("shadow", false)) and not big:
			bad_shadow.append(nm)
		var rng_end: float = float(e.get("range", 90.0))
		var small := false
		for w2: String in ["tuft", "flower", "clover", "pebble", "lily", "grass", "daisy", "dandelion"]:
			if w2 in nm:
				small = true
		if rng_end > 90.0 or (small and rng_end > 65.0):
			bad_range.append("%s %s m" % [nm.get_basename(), ctx.fmt(rng_end, 0)])
		density += float(e.get("per_100m2", 0.0))
	var lt := ArtLabBudgets.limit(row, "tris_per_mesh")
	var stt2 := ArtLabScore.budget_status(float(max_tris), lt)
	ctx.rep.add("D2", "decor", "Triangles per decor mesh", stt2, "max %d (%s)" % [max_tris, ", ".join(tri_list)], "<= %s soft (lab default)" % str(lt.get("limit", "-")),
		"Fewer segments / cards; the vertex wind and the variants carry the detail", ArtLabScore.grade(float(max_tris), 900.0, 250.0))
	ctx.rep.add("D3", "decor", "Shadow casters", "FAIL" if not bad_shadow.is_empty() else "PASS",
		", ".join(bad_shadow) if not bad_shadow.is_empty() else "only trees / logs / big rocks cast", "map-fill.md 9: only trees, logs, big rocks, landmarks, bridges cast shadows",
		"Set shadow false on small decor")
	ctx.rep.add("D4", "decor", "Visibility ranges", "WARN" if not bad_range.is_empty() else "PASS",
		", ".join(bad_range) if not bad_range.is_empty() else "all within 65 / 90 m", "tufts / flowers / pebbles <= 65 m, bushes / reeds / ferns / mushrooms <= 90 m (map-fill.md 9)",
		"Lower `range` on the small pieces")
	var budget_n: int = int(consts.get("INSTANCE_BUDGET", ArtLabBudgets.SET_INSTANCES.get(biome, 0)))
	if budget_n > 0 and density > 0.0:
		ctx.rep.add("D5", "decor", "Instance budget coverage", "INFO", "%s per 100 m2 -> the %d-instance budget covers %d m2 at full weight" % [ctx.fmt(density), budget_n, int(float(budget_n) / density * 100.0)],
			"map-fill.md 10 instance budget per set")
	ctx.rep.add("B8", "budget", "Unique materials", "INFO", str(mats.size()), "shared nature material + contact disc expected")
	if ctx.headless or ctx.fail_fast_stop():
		for id_name: Array in [["D7", "Units hidden by decor"], ["D8", "Units on this decor"], ["D9", "Decor coverage"]]:
			ctx.rep.add(id_name[0], "decor", id_name[1], "SKIP", "headless" if ctx.headless else "fail_fast", "needs a windowed run")
		return
	# scatter a 30 x 30 m patch
	var patch := Node3D.new()
	patch.name = "DecorPatch"
	ctx.stage.world.add_child(patch)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	var side := 30.0
	for i: int in entries.size():
		var e2: Dictionary = entries[i]
		var mesh2: Mesh = meshes[i]
		if mesh2 == null:
			continue
		var count := int(round(float(e2.get("per_100m2", 0.0)) * side * side / 100.0))
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh2
		mm.instance_count = count
		var cl: float = float(e2.get("cluster", 0.0))
		var sc: Vector2 = e2.get("scale", Vector2.ONE)
		var centre := Vector2.ZERO
		for k: int in count:
			var p := Vector2(rng.randf_range(-side * 0.5, side * 0.5), rng.randf_range(-side * 0.5, side * 0.5))
			if rng.randf() < cl:
				if k % 8 == 0:
					centre = Vector2(rng.randf_range(-side * 0.5, side * 0.5), rng.randf_range(-side * 0.5, side * 0.5))
				p = centre + Vector2(rng.randfn(0.0, 1.2), rng.randfn(0.0, 1.2))
			var yaw: float = float(e2["yaw"]) + rng.randf_range(-1.0, 1.0) * float(e2.get("yaw_jitter", 0.0)) if e2.has("yaw") else rng.randf_range(0.0, TAU)
			var s2 := rng.randf_range(sc.x, sc.y)
			mm.set_instance_transform(k, Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3.ONE * s2), ctx.gp + Vector3(p.x, 0.0, p.y)))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if bool(e2.get("shadow", false)) else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_end = float(e2.get("range", 90.0))
		mmi.visibility_range_end_margin = 10.0
		patch.add_child(mmi)
	# reference units standing in the patch
	var units: Array[Node3D] = []
	var xs: Array[float] = [-3.0, -1.0, 1.0, 3.0]
	for j: int in DECOR_UNITS.size():
		if ResourceLoader.exists(DECOR_UNITS[j]):
			var u := ctx.spawn(DECOR_UNITS[j], ctx.gp + Vector3(xs[j], 0.0, 1.0), 20.0)
			if u:
				units.append(u)
	await ctx.frames(6)
	await ctx.wait(0.5)
	ctx.stage.set_mode(&"lit")
	for z: float in [40.0, 55.0, 25.0]:
		ctx.stage.game_cam(ctx.gp, z)
		var img: Image = await ctx.stage.grab()
		ctx.save_shot(img, "z%d" % int(z))
		var roi0 := ctx.stage.roi_of(AABB(ctx.gp - Vector3(8.0, 0.0, 8.0), Vector3(16.0, 2.0, 16.0)), 0)
		ctx.add_tile(ctx.crop(img, Vector2(roi0.get_center()), roi0.size), "%d m game camera (patch + 4 units)" % int(z))
	ctx.stage.fit_cam(AABB(ctx.gp - Vector3(4.0, 0.0, 3.0), Vector3(8.0, 1.5, 6.0)), 25.0, 0.0, 0.9)
	var close: Image = await ctx.stage.grab()
	ctx.save_shot(close, "close")
	ctx.add_tile(close, "close-up")
	ctx.stage.game_cam(ctx.gp, 40.0)
	# D7 / D8: occlusion and contrast of each unit
	var rules := ArtLabBudgets.read_rules(ctx.kind)
	var worst_occ := 0.0
	var worst_de := 999.0
	var occ_list: Array[String] = []
	for u2: Node3D in units:
		ArtLabStage.freeze(u2, true)
	for u3: Node3D in units:
		var ub := ArtLabCensus.world_aabb(u3, ctx.ground_y)
		var roi_u := ctx.stage.roi_of(ub, 10)
		var others: Array = []
		for u4: Node3D in units:
			if u4 != u3:
				others.append(u4.get_parent())
				(u4.get_parent() as Node3D).visible = false
		# unit alone (decor hidden)
		patch.visible = false
		var mask_u := ArtLabImage.sil_mask(await ArtLabShots.sil(ctx, u3), roi_u)
		patch.visible = true
		# decor in white in front of the black unit
		ctx.stage.set_mode(&"sil")
		var rec := ctx.stage.override(u3, ctx.stage.black_mat, ctx.ground_y)
		var rec2 := ctx.stage.override(patch, ctx.stage.white_mat, ctx.ground_y)
		var vis: Image = await ctx.stage.grab()
		ctx.stage.restore(rec)
		ctx.stage.restore(rec2)
		ctx.stage.set_mode(&"lit")
		var mask_v := ArtLabImage.sil_mask(vis, roi_u)
		var occ := 1.0 - float(mask_v.count) / float(maxi(mask_u.count, 1))
		var lit_u: Image = await ctx.stage.grab()
		(u3.get_parent() as Node3D).visible = false
		var bg_u: Image = await ctx.stage.grab()
		(u3.get_parent() as Node3D).visible = true
		for o: Node3D in others:
			o.visible = true
		var cu := ArtLabImage.contrast(lit_u, bg_u, roi_u, mask_v if mask_v.count > 10 else mask_u)
		var de_u: float = cu.get("de_means", 0.0)
		worst_occ = maxf(worst_occ, occ)
		worst_de = minf(worst_de, de_u)
		occ_list.append("%s %d%% hidden, dE %s" % [u3.scene_file_path.get_file().get_basename(), int(occ * 100.0), ctx.fmt(de_u)])
	var ow: float = rules["occlude_warn"]
	var of: float = rules["occlude_fail"]
	var st7 := "PASS" if worst_occ <= ow else ("WARN" if worst_occ <= of else "FAIL")
	ctx.rep.add("D7", "decor", "Units hidden by decor at 40 m", st7, "worst %d%% (%s)" % [int(worst_occ * 100.0), "; ".join(occ_list)],
		"<= %d%% of a unit's silhouette (FAIL > %d%%)" % [int(ow * 100.0), int(of * 100.0)],
		"Lower / thin the tall pieces (tall grass, gorse) or lower their density near open ground", ArtLabScore.grade(worst_occ, of, 0.02),
		"Tall pieces hide up to %d%% of a unit: cap them ~0.6 m or thin the clusters" % int(worst_occ * 100.0) if worst_occ > 0.08 else "", "z40")
	var uw: float = rules["unit_de_warn"]
	var uf: float = rules["unit_de_fail"]
	# WARN only: a unit sharing the decor's colours is half the unit's own problem (its R4 on this ground)
	var st8 := "PASS" if worst_de >= uw else "WARN"
	ctx.rep.add("D8", "decor", "Units still read on this decor", st8, "worst unit mean-colour dE %s (per unit in D7)" % ctx.fmt(worst_de),
		"dE >= %s (WARN only; < %s = that unit melts into this decor)" % [ctx.fmt(uw, 0), ctx.fmt(uf, 0)],
		"Keep the decor a value step away from unit colours (darker / desaturated under units)", ArtLabScore.grade(worst_de, uf * 0.6, uw * 1.6),
		"Units drop to dE %s on this decor: desaturate / darken the busiest piece" % ctx.fmt(worst_de) if worst_de < uw * 1.3 else "", "z40")
	# D9 coverage + D10 glow
	for u5: Node3D in units:
		(u5.get_parent() as Node3D).visible = false
	var proi := ctx.stage.roi_of(AABB(ctx.gp - Vector3(6.0, 0.0, 6.0), Vector3(12.0, 0.1, 12.0)), 0)
	var pmask := ArtLabImage.sil_mask(await ArtLabShots.sil(ctx, patch), proi)
	var cover := float(pmask.count) / float(maxi(proi.size.x * proi.size.y, 1))
	var cw: float = rules["cover_warn"]
	ctx.rep.add("D9", "decor", "Decor coverage at 40 m", "PASS" if cover <= cw else "WARN", "%d%% of the ground covered" % int(cover * 100.0),
		"<= %d%% (busy ground hides units and orders)" % int(cw * 100.0), "Lower the densities or cluster more (bare ground between patches)",
		ArtLabScore.grade(cover, 0.8, 0.3), "Leave more bare ground between clumps (coverage %d%%)" % int(cover * 100.0) if cover > 0.4 else "", "z40")
	ctx.stage.set_mode(&"dark")
	var dark: Image = await ctx.stage.grab()
	ctx.stage.set_mode(&"lit")
	var gl := ArtLabImage.glow_clusters(dark, proi, 0.3, 3, 2)
	var gr: Vector2i = rules["glow"]
	ctx.rep.add("R5", "read", "Glow points in the patch (12 x 12 m)", "PASS" if gl.size() <= gr.y else "WARN", "%d" % gl.size(),
		"<= %d per 144 m2 (emissive decor only in its biome)" % gr.y, "Fewer / dimmer glowing pieces")
	# D11 frame cost
	patch.visible = false
	await ctx.frames(10)
	var base: Vector3 = await ArtLabCheckBudgets.measure(ctx, 60)
	patch.visible = true
	await ctx.frames(10)
	var with_p: Vector3 = await ArtLabCheckBudgets.measure(ctx, 60)
	var lim := ArtLabBudgets.limit(row, "frame_ms_patch")
	var dproc := with_p.x - base.x
	ctx.rep.add("B13", "budget", "Patch frame cost (900 m2)", "INFO", "process +%s ms, render CPU +%s ms, GPU +%s ms" % [ctx.fmt(dproc, 3), ctx.fmt(with_p.y - base.y, 2), ctx.fmt(with_p.z - base.z, 2)],
		"script cost ~0 (MultiMesh, vertex-shader wind); GPU for info (soft %s ms)" % str(lim.get("limit", "-")))
	for u6: Node3D in units:
		(u6.get_parent() as Node3D).visible = true


static func run_vfx(ctx: ArtLabRunner) -> void:
	ctx.gp = ArtLabStage.GROUND_POINTS[ctx.ground_id]
	var res := load(ctx.scene_path)
	var fam: Node3D = null
	if res is PackedScene:
		fam = (res as PackedScene).instantiate() as Node3D
	elif res is GDScript:
		fam = (res as GDScript).new() as Node3D
	if fam == null or not fam.has_method(&"play"):
		ctx.rep.add("H0", "health", "VFX family loads", "FAIL", "no Node3D with play(id, at, target)", "VFX family contract (TitanVfx / MapFillVfx / UnitVfx)")
		return
	ctx.stage.world.add_child(fam)
	var ids: Array[StringName] = []
	if ctx.opts.has("ids"):
		for s: String in String(ctx.opts["ids"]).split(",", false):
			ids.append(StringName(s.strip_edges()))
	else:
		var consts := (fam.get_script() as GDScript).get_script_constant_map()
		for k: String in ["EFFECTS", "IDS", "GROUND_IDS", "FROST_IDS"]:
			if consts.has(k):
				for e: Variant in consts[k]:
					if not StringName(e) in ids:
						ids.append(StringName(e))
	ctx.rep.add("H0", "health", "VFX family loads", "PASS", "%d effect ids" % ids.size(), "play(id, at, target)")
	ctx.target = fam
	var tgt := ctx.gp + Vector3(0.0, 0.0, -4.0)
	await ctx.frames(3)
	# warm-up (pools fill on first use)
	for id: StringName in ids:
		fam.call(&"play", id, ctx.gp, tgt)
		await ctx.wait(0.15)
	await ctx.wait(4.0)
	var nodes0 := ctx.count_nodes(fam)
	var lights_max := 0
	var part_max := 0
	var draw_max := 0
	var per_play: Array[String] = []
	var new_mats_total := 0
	var weak: Array[String] = []
	ctx.stage.game_cam(ctx.gp, 40.0)
	var base40: Image = null
	if not ctx.headless:
		base40 = await ctx.stage.grab()
	var droi := ctx.stage.roi_of(AABB(ctx.gp - Vector3(10.0, 0.0, 10.0), Vector3(20.0, 6.0, 20.0)), 0)
	var created: Array[int] = [0]
	var cb := func(n: Node) -> void:
		if is_instance_valid(fam) and fam.is_ancestor_of(n):
			created[0] += 1
	ctx.get_tree().node_added.connect(cb)
	var frames_all: Array[Image] = []
	var labels: Array[String] = []
	for id2: StringName in ids:
		created[0] = 0
		var r0 := ArtLabCensus.resource_ids(fam)
		fam.call(&"play", id2, ctx.gp, tgt)
		var peak := 0
		var t_prev := 0.0
		for t: float in [0.05, 0.12, 0.35, 0.8, 1.5]:
			await ctx.wait(maxf(t - t_prev, 0.01))
			t_prev = t
			var cen := ArtLabCensus.census(fam, ctx.ground_y)
			lights_max = maxi(lights_max, int(cen["lights"]))
			part_max = maxi(part_max, int(cen["particles"]))
			draw_max = maxi(draw_max, int(cen["draw"]))
			if not ctx.headless:
				var img: Image = await ctx.stage.grab()
				var full := ArtLabImage.Mask.new(droi.size.x, droi.size.y)
				full.bits.fill(1)
				full.finish()
				var ch := ArtLabImage.changed_fraction(base40, img, droi, full, 10.0)
				peak = maxi(peak, int(ch * float(full.count)))
				if t == 0.12 or t == 0.35:
					frames_all.append(ctx.crop(img, Vector2(droi.get_center()), Vector2i(droi.size.x / 2, droi.size.y / 2)))
					labels.append("%s %s s" % [id2, ctx.fmt(t, 2)])
		await ctx.wait(1.5)
		var r1 := ArtLabCensus.resource_ids(fam)
		var nm := 0
		for mid: int in r1["materials"]:
			if not (r0["materials"] as Dictionary).has(mid):
				nm += 1
		new_mats_total += nm
		per_play.append("%s %d" % [id2, created[0]])
		if not ctx.headless and peak < int(ArtLabBudgets.read_rules(&"vfx").get("area_warn", 200)):
			weak.append("%s %d px" % [id2, peak])
	ctx.get_tree().node_added.disconnect(cb)
	await ctx.wait(3.0)
	var leak := ctx.count_nodes(fam) - nodes0
	var row := ctx.rep.budget_row
	ctx.rep.add("B5", "budget", "Real lights during effects", "PASS" if lights_max == 0 else "FAIL", "max %d" % lights_max, "0 (emission + bloom)", "Replace lights with emissive cards")
	var tot_created := 0
	for s2: String in per_play:
		tot_created += int(s2.get_slice(" ", 1))
	ctx.rep.add("V2", "vfx", "Nodes created per play (after warm-up)", "PASS" if tot_created == 0 else "WARN", ", ".join(per_play),
		"0: pooled (art-units 6.10: no runtime instancing)", "Pool the nodes (create at _ready / first use, then reuse)", 1.0 if tot_created == 0 else 0.4,
		"Pool what each play creates (%d nodes over %d ids)" % [tot_created, ids.size()] if tot_created > 0 else "")
	ctx.rep.add("V3", "vfx", "Leak after all effects end", "PASS" if leak <= 0 else "WARN", "%+d nodes 3 s after the last effect" % leak, "back to the warm pool size",
		"Free / return every node when its effect ends", 1.0 if leak <= 0 else 0.3)
	ctx.rep.add("V4", "vfx", "Materials created per play", "PASS" if new_mats_total == 0 else "WARN", str(new_mats_total), "0 (shared materials, instance uniforms)",
		"Share materials; per-effect colour via instance uniforms or vertex colour", 1.0 if new_mats_total == 0 else 0.4)
	var lp := ArtLabBudgets.limit(row, "particles")
	ctx.rep.add("V5", "vfx", "Peak particles / draws", ArtLabScore.budget_status(float(part_max), lp), "%d looping particles, %d draw instances" % [part_max, draw_max],
		"particles <= %s soft, draws <= %s soft" % [str(lp.get("limit", "-")), str(ArtLabBudgets.limit(row, "draw").get("limit", "-"))], "Smaller amounts, bigger soft sprites")
	if ctx.headless:
		ctx.rep.add("V6", "vfx", "Visible at 40 m", "SKIP", "headless", "needs a windowed run")
		return
	ctx.rep.add("V6", "vfx", "Visible at 40 m", "PASS" if weak.is_empty() else "WARN", "weak: " + ", ".join(weak) if not weak.is_empty() else "every id changes >= %d px" % int(ArtLabBudgets.read_rules(&"vfx").get("area_warn", 200)),
		"each effect changes >= %d px of the 40 m frame (ids that need a unit target may show nothing here)" % int(ArtLabBudgets.read_rules(&"vfx").get("area_warn", 200)),
		"Bigger / brighter core (emission >= 2.5), a ground ring for area effects", 1.0 if weak.is_empty() else 0.5,
		"Strengthen the 40 m read of %s" % ", ".join(weak) if not weak.is_empty() else "")
	var sheet := ArtLabImage.grid(frames_all, 4, 400, 225)
	ctx.save_shot(sheet, "effects")
	for i: int in range(0, frames_all.size(), 2):
		var pair: Array[Image] = [frames_all[i]]
		if i + 1 < frames_all.size():
			pair.append(frames_all[i + 1])
		ctx.add_tile(ArtLabImage.grid(pair, 2, 400, 225), labels[i].get_slice(" ", 0) + " at 0.12 / 0.35 s (40 m)")
	# frame cost: every id at once, 3 times
	await ctx.frames(10)
	var base: Vector3 = await ArtLabCheckBudgets.measure(ctx, 60)
	var burst := func(f: int) -> void:
		if f % 20 == 0:
			for id3: StringName in ids:
				fam.call(&"play", id3, ctx.gp + Vector3(randf_range(-6.0, 6.0), 0.0, randf_range(-6.0, 6.0)), tgt)
	var with_p: Vector3 = await ArtLabCheckBudgets.measure(ctx, 60, burst)
	ctx.rep.add("B13", "budget", "Frame cost (all ids x 3 in 1 s)", "INFO", "process +%s ms, render CPU +%s ms, GPU +%s ms" % [ctx.fmt(with_p.x - base.x, 3), ctx.fmt(with_p.y - base.y, 2), ctx.fmt(with_p.z - base.z, 2)],
		"for information")
