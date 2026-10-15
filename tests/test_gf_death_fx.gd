extends SceneTree
## G-F death FX (docs/art/ge_review.md 13, docs/art/ge_fixes_d.md 3): Nature unit deaths make a small leaf fall, not a
## pale-green leaf cloud over the melee and its HP bars. Checks the CombatVfx looks (headless, Low tier):
## - death_nature: 12-14 leaves, 0.12-0.2 m, ~1.1 s, darker green-bronze (no pale lime: every colour <= 0.6, green
##   channel <= 0.55).
## - The other kingdoms' death primaries stay small: max particle size <= 0.3 m, count <= 22, life <= 1.2 s.
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_gf_death_fx.gd --fixed-fps 60 --quit-after 600

const TASK_ID := "gf_death_fx"

var _fails: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var vfx := CombatVfx.new()
	stage.add_child(vfx)
	await process_frame
	var na: Dictionary = vfx.look_info(&"death_nature")
	_check(not na.is_empty(), "death_nature look missing")
	if not na.is_empty():
		var n := int(na["count"])
		_check(n >= 12 and n <= 14, "death_nature count %d not in 12-14" % n)
		var lo := float(na["scale_min"])
		var hi := float(na["scale_max"])
		_check(lo >= 0.1 and hi <= 0.2 + 0.001 and lo <= hi, "death_nature size %.2f-%.2f not within 0.12-0.2 m" % [lo, hi])
		var life := float(na["life"])
		_check(life >= 0.9 and life <= 1.2, "death_nature life %.2f s not ~1.1 s" % life)
		var cols: Array = na["colors"]
		_check(not cols.is_empty(), "death_nature has no leaf colours")
		for c: Color in cols:
			_check(maxf(c.r, maxf(c.g, c.b)) <= 0.6 and c.g <= 0.55,
					"death_nature colour %s too pale / lime (Nature value pass is moss / bronze)" % c)
	for look: StringName in [&"death_fire", &"death_shadow", &"death_ice"]:
		var d: Dictionary = vfx.look_info(look)
		_check(not d.is_empty(), "%s look missing" % look)
		if d.is_empty():
			continue
		_check(float(d["scale_max"]) <= 0.3 + 0.001, "%s max size %.2f m > 0.3 m" % [look, float(d["scale_max"])])
		_check(int(d["count"]) <= 22, "%s count %d > 22" % [look, int(d["count"])])
		_check(float(d["life"]) <= 1.2, "%s life %.2f s > 1.2 s" % [look, float(d["life"])])
	stage.queue_free()
	await process_frame
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


func _check(ok: bool, msg: String) -> void:
	if not ok:
		_fails.append(msg)
