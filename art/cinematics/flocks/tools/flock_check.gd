extends SceneTree
## Headless check of the dragon flock (art/cinematics/flocks/README.md):
##   & .\tools\godot_run.ps1 --headless --path . -s res://art/cinematics/flocks/tools/flock_check.gd --fixed-fps 30 --quit-after 3000 '--' [scene=res://...tscn]
## D1 same seed = same flock (two fresh instances, every flyer + hero pivot at 6 times).
## D2 seek order does not matter (times evaluated forward, backward, shuffled: identical transforms / custom data).
## D3 own clock under --fixed-fps == set_cine_time at the same time.
## B1 budget (flyers 30-60+, draws, verts, 0 lights). Prints "PASS flock_check" or "FAIL flock_check: ...".

var _fails: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _snapshot(fl: DragonFlock, t: float) -> PackedFloat64Array:
	fl.set_cine_time(t)
	var out := PackedFloat64Array()
	for c: Node in fl.get_children():
		if c is MultiMeshInstance3D:
			var mm := (c as MultiMeshInstance3D).multimesh
			out.append(mm.visible_instance_count)
			for i: int in mm.visible_instance_count:
				var x := mm.get_instance_transform(i)
				for v: Vector3 in [x.basis.x, x.basis.y, x.basis.z, x.origin]:
					out.append_array([v.x, v.y, v.z])
				var cd := mm.get_instance_custom_data(i)
				out.append_array([cd.r, cd.g, cd.b, cd.a])
		elif c is Node3D and c.name.begins_with("Hero_"):
			var h := c as Node3D
			for n: Node in h.find_children("*", "Node3D", true, false):
				var x2 := (n as Node3D).global_transform
				out.append_array([x2.origin.x, x2.origin.y, x2.origin.z, x2.basis.x.y, x2.basis.z.x])
	return out


func _same(a: PackedFloat64Array, b: PackedFloat64Array, eps: float = 0.00001) -> bool:
	if a.size() != b.size():
		return false
	for i: int in a.size():
		if absf(a[i] - b[i]) > eps:
			return false
	return true


func _run() -> void:
	var path := "res://art/cinematics/flocks/dragon_sky.tscn"
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("scene="):
			path = a.substr(6)
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.position = Vector3(0, 30, 120)
	cam.look_at(Vector3(0, 50, 0))
	cam.current = true
	var t0 := Time.get_ticks_usec()
	var a := (load(path) as PackedScene).instantiate() as DragonFlock
	root.add_child(a)
	var build_ms := (Time.get_ticks_usec() - t0) / 1000.0
	var b := (load(path) as PackedScene).instantiate() as DragonFlock
	root.add_child(b)
	var times: Array[float] = [0.0, 1.37, 7.5, 21.3, 44.9, 58.2]
	var snaps := {}
	for t: float in times:
		snaps[t] = _snapshot(a, t)
	# D1 same seed
	var d1 := true
	for t: float in times:
		if not _same(snaps[t], _snapshot(b, t)):
			d1 = false
	_row("D1", "same seed = same flock", d1, "2 instances x %d times" % times.size())
	# D2 seek order
	var d2 := true
	var order: Array[float] = [44.9, 0.0, 58.2, 1.37, 21.3, 7.5, 44.9]
	for t: float in order:
		if not _same(snaps[t], _snapshot(a, t)):
			d2 = false
	_row("D2", "seek order independent", d2, "shuffled + repeated times")
	# other seed differs
	b.flock_seed = 99
	b.rebuild()
	_row("D1b", "another seed = another flock", not _same(snaps[7.5], _snapshot(b, 7.5), 0.01), "seed 99 vs 7")
	b.queue_free()
	# D3 own clock (fixed fps 30): 45 frames = 1.5 s
	var c := (load(path) as PackedScene).instantiate() as DragonFlock
	root.add_child(c)
	for i: int in 46:
		await process_frame
	var tc := c.flock_time()
	var own := _snapshot_keep(c)
	var probe := _snapshot(c, tc)
	_row("D3", "own clock == set_cine_time(same t)", _same(own, probe), "t %.4f" % tc)
	# D4 leave / arrive: flyers move away after leave_at, the flock stops drawing 30 s after the last one left
	var lv := (load("res://art/cinematics/flocks/dragon_sky.tscn") as PackedScene).instantiate() as DragonFlock
	lv.leave_at = 10.0
	lv.arrive_until = 4.0
	root.add_child(lv)
	var d_before := 0.0
	var d_after := 0.0
	var d_arrive := 0.0
	for i: int in lv.flyer_count():
		d_before += lv.flyer_position(i, 9.0).length()
		d_after += lv.flyer_position(i, 25.0).length()
		d_arrive += lv.flyer_position(i, 0.0).length()
	lv.set_cine_time(60.0)
	var bl := lv.budget()
	var ok4 := d_after > d_before * 2.0 and int(bl["near"]) + int(bl["far"]) == 0
	_row("D4", "leave_at / arrive_until", ok4, "mean dist t9 %.0f m, t25 %.0f m (left), t0 %.0f m (arriving); drawn at t60: %d" % [
		d_before / lv.flyer_count(), d_after / lv.flyer_count(), d_arrive / lv.flyer_count(), int(bl["near"]) + int(bl["far"])])
	lv.queue_free()
	# B1 budget
	a.set_cine_time(7.5)
	var bu := a.budget()
	var cost_t := Time.get_ticks_usec()
	for i: int in 60:
		a.update_at(7.5 + i / 30.0)
	var upd_ms := (Time.get_ticks_usec() - cost_t) / 1000.0 / 60.0
	var ok := int(bu["flyers"]) >= 30 and int(bu["draws"]) <= 110 and int(bu["lights"]) == 0
	_row("B1", "budget", ok, "%d flyers (%d heroes, %d kinds), %d draws (%d hero + %d multimesh), %d verts, near %d far %d, update %.3f ms, build %.0f ms" % [
		bu["flyers"], bu["heroes"], bu["kinds"], bu["draws"], bu["hero_draws"], bu["impostor_draws"], bu["verts"],
		bu["near"], bu["far"], upd_ms, build_ms])
	var lights := 0
	for n: Node in a.find_children("*", "Light3D", true, false):
		if (n as Light3D).visible:
			lights += 1
	_row("B2", "0 lights", lights == 0, "%d visible lights" % lights)
	for kind: String in FlockKinds._cache:
		var kd: Dictionary = FlockKinds._cache[kind]
		print("  kind %-13s span %.1f m length %.1f m verts near %d far %d" % [kind, kd["span"], kd["length"], kd["verts_near"], kd["verts_far"]])
	if _fails.is_empty():
		print("PASS flock_check")
	else:
		print("FAIL flock_check: " + ", ".join(_fails))
	quit(0 if _fails.is_empty() else 1)


func _snapshot_keep(fl: DragonFlock) -> PackedFloat64Array:
	# read without re-posing (what the own clock drew)
	var out := PackedFloat64Array()
	for c: Node in fl.get_children():
		if c is MultiMeshInstance3D:
			var mm := (c as MultiMeshInstance3D).multimesh
			out.append(mm.visible_instance_count)
			for i: int in mm.visible_instance_count:
				var x := mm.get_instance_transform(i)
				for v: Vector3 in [x.basis.x, x.basis.y, x.basis.z, x.origin]:
					out.append_array([v.x, v.y, v.z])
				var cd := mm.get_instance_custom_data(i)
				out.append_array([cd.r, cd.g, cd.b, cd.a])
		elif c is Node3D and c.name.begins_with("Hero_"):
			for n: Node in (c as Node3D).find_children("*", "Node3D", true, false):
				var x2 := (n as Node3D).global_transform
				out.append_array([x2.origin.x, x2.origin.y, x2.origin.z, x2.basis.x.y, x2.basis.z.x])
	return out


func _row(id: String, what: String, ok: bool, value: String) -> void:
	print("%s %-4s %-36s %s" % ["PASS" if ok else "FAIL", id, what, value])
	if not ok:
		_fails.append(id)
