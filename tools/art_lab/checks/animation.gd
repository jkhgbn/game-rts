class_name ArtLabCheckAnim
extends RefCounted
## Art Lab checks (docs/plan/art-lab.md section 3): animation. A1 standard hooks, A2 death_finished, A3 attack reads at
## 40 m (called from the readability pass: same frozen pose and mask) and the animation strip shot.

static func check_hooks(ctx: ArtLabRunner) -> void:
	var need := ArtLabCensus.expected_hooks(ctx.kind)
	if need.is_empty():
		return
	var missing: Array[String] = []
	for h: String in need:
		if not ArtLabCensus.has_hook(ctx.target, h):
			missing.append(h)
	var st := "PASS" if missing.is_empty() else "WARN"
	ctx.rep.add("A1", "anim", "Standard hooks", st, "missing: " + ", ".join(missing) if not missing.is_empty() else "all %d present" % need.size(),
		", ".join(need), "Add the missing hooks (gameplay calls them through has_method; missing = no animation)",
		1.0 - float(missing.size()) / float(need.size()), "" if missing.is_empty() else "Implement %s" % ", ".join(missing))


## play_death -> death_finished within 2 s (the gameplay fallback frees the unit at 2.0 s).
static func death_check(ctx: ArtLabRunner, strip: Array, capture: bool) -> void:
	if not ctx.target.has_method(&"play_death"):
		return
	var t_done: Array[float] = [-1.0]
	var t0 := Time.get_ticks_msec()
	var has_sig := ctx.target.has_signal(&"death_finished")
	var cb := func() -> void:
		if t_done[0] < 0.0:
			t_done[0] = float(Time.get_ticks_msec() - t0) / 1000.0
	if has_sig:
		ctx.target.connect(&"death_finished", cb, CONNECT_ONE_SHOT)
	ctx.target.call(&"play_death")
	if capture:
		await ctx.wait(0.45)
		ArtLabStage.freeze(ctx.target, true)
		strip.append({"img": await ctx.stage.grab(), "label": "death 0.45 s"})
		ArtLabStage.freeze(ctx.target, false)
	var guard := 0
	while t_done[0] < 0.0 and float(Time.get_ticks_msec() - t0) < 3000.0 and guard < 600:
		await ctx.get_tree().process_frame
		guard += 1
	if capture:
		strip.append({"img": await ctx.stage.grab(), "label": "death end (%s s)" % ctx.fmt(t_done[0], 2)})
	if not has_sig:
		return
	var t: float = t_done[0]
	var st := "PASS" if t >= 0.0 and t <= 2.0 else "WARN"
	ctx.rep.add("A2", "anim", "death_finished", st, "after %s s" % ctx.fmt(t, 2) if t >= 0.0 else "never (3 s)",
		"emitted <= 2.0 s after play_death (gameplay fallback 2.0 s, art-units 6.7)",
		"Emit death_finished at the end of the death timeline (it must fire even at the far distance tier)",
		1.0 if st == "PASS" else 0.3)
	if ctx.target.has_method(&"revive"):
		ctx.target.call(&"revive")
		await ctx.wait(0.3)


static func anim_strip(ctx: ArtLabRunner) -> void:
	var box: AABB = ctx.m["box"]
	ctx.stage.fit_cam(box.grow(0.4), 16.0, 0.0, 0.7)
	var strip: Array = []
	await ctx.wait(0.3)
	strip.append({"img": await ctx.stage.grab(), "label": "idle"})
	match ctx.kind:
		&"building", &"landmark":
			if ctx.call_hook(ctx.target, &"set_construction_progress", [0.5]):
				await ctx.wait(0.6)
				strip.append({"img": await ctx.stage.grab(), "label": "construction 50 %"})
				ctx.call_hook(ctx.target, &"set_construction_progress", [1.0])
				await ctx.wait(0.8)
			if ctx.call_hook(ctx.target, &"set_health_ratio", [0.4]):
				await ctx.wait(0.8)
				strip.append({"img": await ctx.stage.grab(), "label": "40 % HP"})
				ctx.call_hook(ctx.target, &"set_health_ratio", [0.2])
				await ctx.wait(0.8)
				strip.append({"img": await ctx.stage.grab(), "label": "20 % HP"})
				ctx.call_hook(ctx.target, &"set_health_ratio", [1.0])
			if ctx.call_hook(ctx.target, &"play_training_pulse"):
				await ctx.wait(0.12)
				strip.append({"img": await ctx.stage.grab(), "label": "training pulse"})
			if ctx.call_hook(ctx.target, &"set_selected", [true]):
				await ctx.wait(0.3)
				strip.append({"img": await ctx.stage.grab(), "label": "selected"})
				ctx.call_hook(ctx.target, &"set_selected", [false])
			if ctx.call_hook(ctx.target, &"play_destroyed"):
				await ctx.wait(1.2)
				strip.append({"img": await ctx.stage.grab(), "label": "destroyed 1.2 s"})
				await ctx.wait(1.8)
				strip.append({"img": await ctx.stage.grab(), "label": "destroyed 3 s"})
		&"critter":
			for step: Array in [[&"play_move", [ctx.stride], 0.5, "move"], [&"play_flee", [], 0.5, "flee"],
					[&"play_hit", [], 0.07, "hit"], [&"play_death", [], 0.6, "death 0.6 s"]]:
				if ctx.call_hook(ctx.target, step[0], step[1]):
					await ctx.wait(step[2])
					ArtLabStage.freeze(ctx.target, true)
					strip.append({"img": await ctx.stage.grab(), "label": step[3]})
					ArtLabStage.freeze(ctx.target, false)
		_:
			if ctx.call_hook(ctx.target, &"set_moving", [ctx.stride]):
				await ctx.wait(0.7)
				ArtLabStage.freeze(ctx.target, true)
				strip.append({"img": await ctx.stage.grab(), "label": "move"})
				ArtLabStage.freeze(ctx.target, false)
				if ctx.kind == &"mount":
					ctx.target.call(&"set_moving", ctx.stride * 2.2)
					await ctx.wait(0.8)
					ArtLabStage.freeze(ctx.target, true)
					strip.append({"img": await ctx.stage.grab(), "label": "gallop"})
					ArtLabStage.freeze(ctx.target, false)
				ctx.target.call(&"set_moving", 0.0)
				await ctx.wait(0.6)
			if ctx.call_hook(ctx.target, &"play_attack"):
				var wu: Variant = ctx.target.get(&"attack_windup")
				var t_hit := 0.35 if ctx.flyer or ctx.kind == &"titan" else (float(wu) if wu != null and float(wu) > 0.0 else 0.1)
				if float(ctx.m.get("a3_t", 0.0)) > 0.0:
					t_hit = float(ctx.m["a3_t"])   # v3.1: A3's biggest-change moment (a custom timeline peaks elsewhere)
				await ctx.wait(t_hit)
				ArtLabStage.freeze(ctx.target, true)
				strip.append({"img": await ctx.stage.grab(), "label": "attack (strike, t %s s)" % ctx.fmt(t_hit, 2)})
				ArtLabStage.freeze(ctx.target, false)
				await ctx.wait(1.0)
			if ctx.kind == &"mount" and ctx.call_hook(ctx.target, &"play_charge"):
				await ctx.wait(0.2)
				ArtLabStage.freeze(ctx.target, true)
				strip.append({"img": await ctx.stage.grab(), "label": "charge"})
				ArtLabStage.freeze(ctx.target, false)
				await ctx.wait(0.8)
			if ctx.call_hook(ctx.target, &"play_hit"):
				await ctx.wait(0.07)
				ArtLabStage.freeze(ctx.target, true)
				strip.append({"img": await ctx.stage.grab(), "label": "hit"})
				ArtLabStage.freeze(ctx.target, false)
				await ctx.wait(0.5)
			if ctx.target.has_method(&"play_cast"):
				await cast_pose(ctx, box, strip)
			await death_check(ctx, strip, true)
	var imgs: Array[Image] = []
	var cbox := box.grow(maxf(box.size.length() * 0.12, 0.3))
	for f: Dictionary in strip:
		var c := ctx.crop_box(f["img"], cbox, 0.05)
		imgs.append(c)
		ctx.add_tile(c, "anim: " + String(f["label"]))
	var sheet := ArtLabImage.grid(imgs, 4, 480, 270)
	ctx.save_shot(sheet, "anim")


## U1 (2026-09-27): cast-pose shot. v3.1 only called `play_cast` on beasts / wizards / champions, so the casting
## soldiers (Pyre Adept, Hexweaver: kit `CharacterModel.play_cast`) were never seen casting. Every model with the hook
## now casts once in the strip camera: the silhouette change vs the rest pose is sampled at CAST_SAMPLES, the biggest
## moment goes into the strip and `cast.jpg` (rest | cast peak). A4 is INFO (unscored until calibrated): the value is
## the change and the moment; a hint when the cast barely moves the outline.
const CAST_SAMPLES: Array[float] = [0.12, 0.25, 0.4, 0.6]
const CAST_READ_MIN := 0.06


static func cast_pose(ctx: ArtLabRunner, box: AABB, strip: Array) -> void:
	var roi := ctx.stage.roi_of(box.grow(maxf(box.size.length() * 0.2, 0.5)), 8)
	ArtLabStage.freeze(ctx.target, true)
	var rest := ArtLabImage.sil_mask(await ArtLabShots.sil(ctx, ctx.target), roi)
	var rest_img: Image = await ctx.stage.grab()
	ArtLabStage.freeze(ctx.target, false)
	var spell := StringName(ctx.opts.get("cast_id", "lab_cast"))
	if not ctx.call_hook(ctx.target, &"play_cast", [spell]):
		return
	var best := -1.0
	var best_t := 0.0
	var best_img: Image = null
	var t_prev := 0.0
	var seen: Array[String] = []
	for t_s: float in CAST_SAMPLES:
		await ctx.wait(t_s - t_prev)
		t_prev = t_s
		ArtLabStage.freeze(ctx.target, true)
		var mk := ArtLabImage.sil_mask(await ArtLabShots.sil(ctx, ctx.target), roi)
		var ch := 1.0 - ArtLabImage.iou(rest, mk)
		seen.append("%s s %d%%" % [ctx.fmt(t_s, 2), int(ch * 100.0)])
		if ch > best:
			best = ch
			best_t = t_s
			best_img = await ctx.stage.grab()
		ArtLabStage.freeze(ctx.target, false)
	ctx.m["cast_change"] = best
	ctx.m["cast_t"] = best_t
	if best_img != null:
		strip.append({"img": best_img, "label": "cast (peak, t %s s)" % ctx.fmt(best_t, 2)})
		var cbox := box.grow(maxf(box.size.length() * 0.12, 0.3))
		var pair: Array[Image] = [ctx.crop_box(rest_img, cbox, 0.05), ctx.crop_box(best_img, cbox, 0.05)]
		ctx.save_shot(ArtLabImage.grid(pair, 2, 480, 270), "cast")
	ctx.rep.add("A4", "anim", "Cast pose reads (play_cast)", "INFO",
		"cast pose changes %d%% of the silhouette at its peak (t %s s; %s)" % [int(best * 100.0), ctx.fmt(best_t, 2), ", ".join(seen)],
		"shown in the strip + cast.jpg (rest | peak); INFO until calibrated (a cast should change >= %d%% of the outline)" % int(CAST_READ_MIN * 100.0),
		"", -1.0,
		"The cast barely moves the outline (%d%%): raise the staff / arms or add a cast flare above the head so the cast reads" % int(best * 100.0) if best < CAST_READ_MIN else "",
		"anim")
	await ctx.wait(0.8)


## Reach weapons (whips, pikes, halberds): a declared reach at or above this (m) is judged by A3r; shorter
## attack_range values of ordinary melee units (1.2-2.0 m, gameplay distance to the target's edge) are INFO only.
const REACH_JUDGE_MIN := 2.5
## A3r PASS when the tip reaches this share of the declared reach at one of the A3 moments.
const REACH_PASS := 0.8


## The declared weapon reach: `reach=<m>` (the brief) > the scene's `attack_reach` > the UnitType's `attack_range`.
## Returns {reach, src, judged} (judged = a reach weapon: reach= / attack_reach, or attack_range >= REACH_JUDGE_MIN).
static func declared_reach(ctx: ArtLabRunner) -> Dictionary:
	if ctx.opts.has("reach") and float(ctx.opts["reach"]) > 0.0:
		return {"reach": float(ctx.opts["reach"]), "src": "reach= (brief)", "judged": true}
	var ar: Variant = ctx.target.get(&"attack_reach")
	if ar != null and float(ar) > 0.0:
		return {"reach": float(ar), "src": "scene attack_reach", "judged": true}
	if ctx.unit.has("attack_range"):
		var r := float(ctx.unit["attack_range"])
		return {"reach": r, "src": "UnitType attack_range (%s)" % String(ctx.unit.get("file", "")).get_file(),
			"judged": r >= REACH_JUDGE_MIN and r <= 4.0}
	return {}


## Weapon-tip reach of the frozen pose: the farthest horizontal distance from the model's origin of any drawn
## geometry at or above the ground (triangle edges clipped at y = 0.02, so a lash driven into the ground stops where it
## meets it). Holder frame (the model's own axes, +Z forward). Returns {reach, fwd, point}.
static func tip_reach(ctx: ArtLabRunner) -> Dictionary:
	var inv := ctx.holder.global_transform.affine_inverse()
	var best := 0.0
	var best_p := Vector3.ZERO
	var fwd := 0.0
	var y0 := 0.02
	for gi: GeometryInstance3D in ArtLabCensus.geometry(ctx.target):
		if not gi.is_visible_in_tree() or ArtLabCensus.is_particles(gi) or ArtLabCensus.is_flat_decal(gi, ctx.ground_y):
			continue
		if not gi is MeshInstance3D or (gi as MeshInstance3D).mesh == null:
			continue
		var mesh := (gi as MeshInstance3D).mesh
		var xf := inv * gi.global_transform
		for s: int in mesh.get_surface_count():
			var arr := mesh.surface_get_arrays(s)
			if arr.is_empty():
				continue
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var pts := PackedVector3Array()
			pts.resize(v.size())
			for i: int in v.size():
				pts[i] = xf * v[i]
			var idx: Variant = arr[Mesh.ARRAY_INDEX]
			var ids: PackedInt32Array = idx if idx is PackedInt32Array and (idx as PackedInt32Array).size() > 0 else PackedInt32Array()
			var cand: Array[Vector3] = []
			for p: Vector3 in pts:
				if p.y >= y0:
					cand.append(p)
			for t: int in range(0, ids.size() - 2, 3):
				for e: int in 3:
					var a := pts[ids[t + e]]
					var b := pts[ids[t + (e + 1) % 3]]
					if (a.y >= y0) != (b.y >= y0):
						cand.append(a.lerp(b, (y0 - a.y) / (b.y - a.y)))
			for c: Vector3 in cand:
				var hr := Vector2(c.x, c.z).length()
				if hr > best:
					best = hr
					best_p = c
				fwd = maxf(fwd, c.z)
	return {"reach": best, "fwd": fwd, "point": best_p}


static func _side_box(ctx: ArtLabRunner, reach: float) -> AABB:
	var box: AABB = ctx.m["box"]
	var far := maxf(reach, maxf(box.size.x, box.size.z) * 0.5) + 0.3
	var xf := ctx.holder.global_transform
	box = box.expand(xf * Vector3(0.0, 0.0, far)).expand(xf * Vector3(0.0, 0.0, -0.6))
	return box


## A lit side view of the frozen pose (camera square to the model's facing, low pitch) with the declared reach (red
## post on the ground) and the measured tip (green box) marked.
static func _side_frame(ctx: ArtLabRunner, box: AABB, declared: float, rr: Dictionary, t_s: float) -> Image:
	ctx.stage.fit_cam(box, 6.0, ArtLabRunner.MAIN_YAW + 90.0, 0.9)
	var img: Image = (await ctx.stage.grab()).duplicate() as Image
	img.convert(Image.FORMAT_RGBA8)
	var xf := ctx.holder.global_transform
	if declared > 0.0:
		var g := ctx.stage.cam.unproject_position(xf * Vector3(0.0, 0.0, declared))
		var top := ctx.stage.cam.unproject_position(xf * Vector3(0.0, maxf(ctx.body_height, 1.0), declared))
		for y: int in range(int(minf(top.y, g.y)), int(maxf(top.y, g.y)) + 1):
			for dx: int in [-1, 0, 1]:
				var px := int(g.x) + dx
				if px >= 0 and y >= 0 and px < img.get_width() and y < img.get_height():
					img.set_pixel(px, y, Color(1.0, 0.15, 0.1))
	if float(rr.get("reach", 0.0)) > 0.0:
		var tp := ctx.stage.cam.unproject_position(xf * (rr["point"] as Vector3))
		ArtLabShots.mark(img, int(tp.x), int(tp.y), 6, Color(0.2, 1.0, 0.3))
	var crop := ctx.crop_box(img, box, 0.04)
	return crop


static func reach_report(ctx: ArtLabRunner, declared: Dictionary, best: Dictionary) -> void:
	var reach := float(best.get("reach", 0.0))
	var val := "tip reaches %s m from the body centre at t %s s (%s m forward; geometry clipped at the ground)" % [
		ctx.fmt(reach, 2), ctx.fmt(float(best.get("t", 0.0)), 2), ctx.fmt(float(best.get("fwd", 0.0)), 2)]
	if declared.is_empty():
		ctx.rep.add("A3r", "anim", "Weapon reach at the strike", "INFO", val + "; no declared reach (no UnitType, no reach=)",
			"reach weapons: pass reach=<m> (the brief) or set attack_reach on the scene")
		return
	var want := float(declared["reach"])
	val += "; declared %s m (%s)" % [ctx.fmt(want, 1), declared["src"]]
	if not bool(declared["judged"]):
		ctx.rep.add("A3r", "anim", "Weapon reach at the strike", "INFO", val + " - not a reach weapon (< %s m): not judged" % ctx.fmt(REACH_JUDGE_MIN, 1),
			"judged for reach weapons (declared reach >= %s m, or reach= / attack_reach)" % ctx.fmt(REACH_JUDGE_MIN, 1))
		return
	var ratio := reach / maxf(want, 0.01)
	var st := "PASS" if ratio >= REACH_PASS else "WARN"
	var hint := "The strike stops at %s m of the declared %s m: aim the strike at the target height (not the ground) and extend the weapon fully at the hit frame (see strike_side.jpg)" % [
		ctx.fmt(reach, 2), ctx.fmt(want, 1)]
	ctx.rep.add("A3r", "anim", "Weapon reach at the strike", st, val,
		"the strike frame shows the weapon tip at >= %d%% of the declared reach, above the ground (side frames: strike_side.jpg)" % int(REACH_PASS * 100.0),
		hint if st != "PASS" else "", ArtLabScore.grade(ratio, 0.4, 1.0), hint if st != "PASS" else "", "strike_side")


## A3 attack reads at 40 m: the biggest silhouette change (1 - IoU rest vs pose) over 4 moments of play_attack.
## Called from the readability pass with the frozen 40 m rest mask; leaves the target frozen again.
static func attack_reads(ctx: ArtLabRunner, rules: Dictionary, roi: Rect2i, mask: ArtLabImage.Mask) -> void:
	var mot: float = rules.get("motion", 0.0)
	if mot > 0.0 and ctx.target.has_method(&"play_attack"):
		# Sample the timeline at 4 moments (custom attack styles peak at different times) and keep the biggest change.
		ArtLabStage.freeze(ctx.target, false)
		ctx.target.call(&"play_attack")
		var change := 0.0
		var strike := 0.0
		var t_prev := 0.0
		# v3.1 A3r: weapon-tip reach at every sample (geometry, clipped at the ground) + a side frame per sample
		var declared := declared_reach(ctx)
		var reach_best := {"reach": 0.0, "t": 0.0, "fwd": 0.0}
		var sides: Array[Image] = []
		var side_box := _side_box(ctx, float(declared.get("reach", 0.0)))
		for t_s: float in [0.08, 0.14, 0.24, 0.36]:
			await ctx.wait(t_s - t_prev)
			t_prev = t_s
			ArtLabStage.freeze(ctx.target, true)
			var mask_a := ArtLabImage.sil_mask(await ArtLabShots.sil(ctx, ctx.target), roi)
			var ch := 1.0 - ArtLabImage.iou(mask, mask_a)
			if ch > change:
				change = ch
				strike = t_s
			if ctx.wants(["A3r"]):
				var rr := tip_reach(ctx)
				if float(rr["reach"]) > float(reach_best["reach"]):
					reach_best = rr
					reach_best["t"] = t_s
				sides.append(await _side_frame(ctx, side_box, float(declared.get("reach", 0.0)), rr, t_s))
				ctx.stage.game_cam(ctx.gp, 40.0)
			ArtLabStage.freeze(ctx.target, false)
		await ctx.wait(1.0)
		ctx.m["a3_t"] = strike   # the anim strip shoots its "attack (strike)" frame at this moment (v3.1)
		if not sides.is_empty():
			var sheet := ArtLabImage.grid(sides, 4, 480, 270)
			ctx.save_shot(sheet, "strike_side")
			ctx.add_tile(sheet, "A3 strike from the side: t 0.08 / 0.14 / 0.24 / 0.36 s (red = declared reach, green = tip)")
			reach_report(ctx, declared, reach_best)
		var st8 := "PASS" if change >= mot else "WARN"
		ctx.rep.add("A3", "anim", "Attack reads at 40 m", st8, "strike pose changes %d%% of the silhouette (t %s s)" % [int(change * 100.0), ctx.fmt(strike, 2)],
			">= %d%% (1 - IoU rest vs strike)" % int(mot * 100.0), "Bigger wind-up / strike: the weapon or head should leave the body outline",
			ArtLabScore.grade(change, 0.0, mot * 2.5), "Push the attack pose: the strike should change >= %d%% of the 40 m silhouette (now %d%%)" % [int(mot * 250.0), int(change * 100.0)], "anim")
		ArtLabStage.freeze(ctx.target, true)
		await ctx.frames(1)
