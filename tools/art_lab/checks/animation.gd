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
				await ctx.wait(0.35 if ctx.flyer or ctx.kind == &"titan" else (float(wu) if wu != null and float(wu) > 0.0 else 0.1))
				ArtLabStage.freeze(ctx.target, true)
				strip.append({"img": await ctx.stage.grab(), "label": "attack (strike)"})
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
			if (ctx.kind == &"beast" or ctx.tier in [&"wizard", &"champion"]) and ctx.call_hook(ctx.target, &"play_cast", [&"lab_cast"]):
				await ctx.wait(0.25)
				ArtLabStage.freeze(ctx.target, true)
				strip.append({"img": await ctx.stage.grab(), "label": "cast"})
				ArtLabStage.freeze(ctx.target, false)
				await ctx.wait(1.0)
			await death_check(ctx, strip, true)
	var imgs: Array[Image] = []
	var cbox := box.grow(maxf(box.size.length() * 0.12, 0.3))
	for f: Dictionary in strip:
		var c := ctx.crop_box(f["img"], cbox, 0.05)
		imgs.append(c)
		ctx.add_tile(c, "anim: " + String(f["label"]))
	var sheet := ArtLabImage.grid(imgs, 4, 480, 270)
	ctx.save_shot(sheet, "anim")


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
		for t_s: float in [0.08, 0.14, 0.24, 0.36]:
			await ctx.wait(t_s - t_prev)
			t_prev = t_s
			ArtLabStage.freeze(ctx.target, true)
			var mask_a := ArtLabImage.sil_mask(await ArtLabShots.sil(ctx, ctx.target), roi)
			var ch := 1.0 - ArtLabImage.iou(mask, mask_a)
			if ch > change:
				change = ch
				strike = t_s
			ArtLabStage.freeze(ctx.target, false)
		await ctx.wait(1.0)
		var st8 := "PASS" if change >= mot else "WARN"
		ctx.rep.add("A3", "anim", "Attack reads at 40 m", st8, "strike pose changes %d%% of the silhouette (t %s s)" % [int(change * 100.0), ctx.fmt(strike, 2)],
			">= %d%% (1 - IoU rest vs strike)" % int(mot * 100.0), "Bigger wind-up / strike: the weapon or head should leave the body outline",
			ArtLabScore.grade(change, 0.0, mot * 2.5), "Push the attack pose: the strike should change >= %d%% of the 40 m silhouette (now %d%%)" % [int(mot * 250.0), int(change * 100.0)], "anim")
		ArtLabStage.freeze(ctx.target, true)
		await ctx.frames(1)
