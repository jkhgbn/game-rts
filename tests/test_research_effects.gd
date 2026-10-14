extends SceneTree
## UR.G1 (docs/design/unit-upgrades.md 10): ResearchEffects H kinds on the hit path, through real Unit attacks.
## Each kind: the team that has the row gets the effect, the other team's same unit does not.
## - on_hit_status: Nightbolt Hexed Bolts marks the target;
## - every_nth: Burr Slinger Sticky Burrs roots on the 5th hit only;
## - first_hit: Blaze Rider Running Start +12 on a fresh target, not on the 2nd hit, at most once per 4 s;
## - bonus_vs_status: Rime Colossus Shatter Blow +20 % on a target chilled before the hit (its own chill does not count
##   on the first hit);
## - splash: Ash Hurler Packed Shot hits an enemy 1 m away for <= 40 %, never an ally nor an enemy 3.5 m away;
## - dot: Emberdart Harrier burn, Duskbolt Harrier dusk_bleed (not Bleakbow's bleed);
## - a unit without rows keeps empty research_hit_fx / research_hurt_fx.
## Run:  tools/godot_run.ps1 --headless --path . -s tests/test_research_effects.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "research_effects"
const A := 0
const B := 1

var main: Node3D
var _errors: Array[String] = []
var _checks := 0


func _initialize() -> void:
	main = Node3D.new()
	main.name = "World"
	root.add_child(main)
	current_scene = main
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4000.0, 1.0, 4000.0)
	shape.shape = box
	shape.position.y = -0.5
	floor_body.add_child(shape)
	main.add_child(floor_body)
	_run.call_deferred()


func _ok(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_errors.append(what)
		print("  x " + what)


func _physics(n: int) -> void:
	for i in n:
		await physics_frame


func _until(cond: Callable, max_frames: int) -> bool:
	for i in max_frames:
		if bool(cond.call()):
			return true
		await physics_frame
	return bool(cond.call())


func _run() -> void:
	await process_frame
	UnitResearch.force_enabled = true
	var bank := UnitResearch.for_team(A)
	UnitResearch.for_team(B)
	_ok(bank != null, "UnitResearch node for team A")
	if bank == null:
		_finish()
		return
	for id: StringName in [&"nightbolt_hexed_bolts", &"burr_slinger_sticky_burrs", &"blaze_rider_running_start",
			&"rime_colossus_shatter_blow", &"ash_hurler_packed_shot", &"emberdart_harrier_firebrand",
			&"duskbolt_harrier_bleeding_bolts"]:
		bank.grant(id)
	await _check_on_hit_status()
	await _check_every_nth()
	await _check_first_hit()
	await _check_bonus_vs_status()
	await _check_splash()
	await _check_dot()
	_finish()


func _finish() -> void:
	UnitResearch.force_enabled = false
	if _errors.is_empty():
		print("PASS %s (%d checks)" % [TASK_ID, _checks])
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors.slice(0, 20))])
	quit()


# ---------------------------------------------------------------- helpers

func _spawn(id: String, team: int, pos: Vector3) -> Unit:
	var t := UnitType.find(id)
	var u: Unit = t.create_unit()
	u.team = team as Unit.Team
	main.add_child(u)
	u.global_position = pos
	return u


## A passive, sturdy enemy: holds, never attacks, 5000 extra HP, no armor.
func _dummy(team: int, pos: Vector3) -> Unit:
	var d := _spawn("flame_guard", team, pos)
	d.add_modifier(&"test_hp", {&"max_hp": 5000.0})
	d.hp = d.max_hp
	d.attacks_blocked = true
	d.command_hold()
	return d


## Records every landed hit of `attacker`: [dealt, target hp after the whole hit].
func _record(attacker: Unit) -> Array:
	var hits: Array = []
	attacker.attack_landed.connect(func(target: Node3D, dealt: float) -> void:
		hits.append([dealt, float(target.get(&"hp")), target]))
	return hits


func _clear(units: Array) -> void:
	for u: Variant in units:
		if is_instance_valid(u):
			(u as Node).queue_free()
	await _physics(2)


# ---------------------------------------------------------------- kinds

func _check_on_hit_status() -> void:
	var base := Vector3(0, 0, 0)
	var a := _spawn("nightbolt", A, base)
	var da := _dummy(B, base + Vector3(5, 0, 0))
	var b := _spawn("nightbolt", B, base + Vector3(0, 0, 60))
	var db := _dummy(A, base + Vector3(5, 0, 60))
	await _physics(3)
	_ok(not a.research_hit_fx.is_empty(), "on_hit_status: the A Nightbolt has its hit effect cached")
	_ok(b.research_hit_fx.is_empty() and b.research_hurt_fx.is_empty(), "the B Nightbolt (no row) has nothing cached")
	_ok(da.research_hit_fx.is_empty() and da.research_hurt_fx.is_empty(), "a Flame Guard without rows has nothing")
	var ha := _record(a)
	var hb := _record(b)
	a.command_attack(da)
	b.command_attack(db)
	await _until(func() -> bool: return ha.size() >= 1 and hb.size() >= 1, 600)
	_ok(ha.size() >= 1 and da.has_status(&"marked"), "on_hit_status: Hexed Bolts marks the target")
	_ok(hb.size() >= 1 and not db.has_status(&"marked"), "on_hit_status: no mark without the row")
	await _clear([a, b, da, db])


func _check_every_nth() -> void:
	var base := Vector3(200, 0, 0)
	var a := _spawn("burr_slinger", A, base)
	var da := _dummy(B, base + Vector3(5, 0, 0))
	await _physics(3)
	var rooted: Array[bool] = []
	a.attack_landed.connect(func(target: Node3D, _d: float) -> void:
		rooted.append((target as Unit).has_status(&"rooted")))
	a.command_attack(da)
	await _until(func() -> bool: return rooted.size() >= 6, 1200)
	_ok(rooted.size() >= 6, "every_nth: six hits landed (%d)" % rooted.size())
	if rooted.size() >= 5:
		_ok(str(rooted.slice(0, 5)) == "[false, false, false, false, true]",
				"every_nth: rooted on the 5th hit only (%s)" % str(rooted.slice(0, 6)))
	await _clear([a, da])


func _check_first_hit() -> void:
	var base := Vector3(400, 0, 0)
	var a := _spawn("blaze_rider", A, base)
	var d1 := _dummy(B, base + Vector3(1.2, 0, 0))
	var d2 := _dummy(B, base + Vector3(-1.2, 0, 0))
	var d3 := _dummy(B, base + Vector3(0, 0, 1.2))
	var b := _spawn("blaze_rider", B, base + Vector3(0, 0, 60))
	var db := _dummy(A, base + Vector3(1.2, 0, 60))
	await _physics(3)
	var full := d1.max_hp
	var ha := _record(a)
	var hb := _record(b)
	a.command_attack(d1)
	b.command_attack(db)
	await _until(func() -> bool: return ha.size() >= 2 and hb.size() >= 1, 600)
	if ha.size() < 2 or hb.size() < 1:
		_ok(false, "first_hit: hits never landed")
		await _clear([a, b, d1, d2, d3, db])
		return
	var extra1 := (full - float(ha[0][1])) - float(ha[0][0])
	var extra2 := (float(ha[0][1]) - float(ha[1][1])) - float(ha[1][0])
	var extra_b := (full - float(hb[0][1])) - float(hb[0][0])
	_ok(absf(extra1 - 12.0) < 0.5, "first_hit: +12 on a fresh target (%.2f)" % extra1)
	_ok(absf(extra2) < 0.01, "first_hit: nothing on the 2nd hit (%.2f)" % extra2)
	_ok(absf(extra_b) < 0.01, "first_hit: nothing without the row (%.2f)" % extra_b)
	# A fresh target less than 4 s after the bonus: no bonus.
	var n0 := ha.size()
	a.command_attack(d2)
	await _until(func() -> bool: return ha.size() > n0 and ha[ha.size() - 1][2] == d2, 300)
	var last: Array = ha[ha.size() - 1]
	var extra_cd := (full - float(last[1])) - float(last[0])
	_ok(last[2] == d2 and absf(extra_cd) < 0.01, "first_hit: once per 4 s (%.2f)" % extra_cd)
	# 4 s later: a fresh target gets it again.
	a.command_stop()
	await _physics(260)
	n0 = ha.size()
	a.command_attack(d3)
	await _until(func() -> bool: return ha.size() > n0 and ha[ha.size() - 1][2] == d3, 300)
	last = ha[ha.size() - 1]
	var extra3 := (full - float(last[1])) - float(last[0])
	_ok(last[2] == d3 and absf(extra3 - 12.0) < 0.5, "first_hit: back after 4 s (%.2f)" % extra3)
	await _clear([a, b, d1, d2, d3, db])


func _check_bonus_vs_status() -> void:
	var base := Vector3(600, 0, 0)
	var a := _spawn("rime_colossus", A, base)
	var da := _dummy(B, base + Vector3(1.3, 0, 0))
	var a2 := _spawn("rime_colossus", A, base + Vector3(0, 0, 60))
	var da2 := _dummy(B, base + Vector3(1.3, 0, 60))
	var b := _spawn("rime_colossus", B, base + Vector3(0, 0, 120))
	var db := _dummy(A, base + Vector3(1.3, 0, 120))
	await _physics(3)
	var full := da.max_hp
	da.apply_status(&"chill", 30.0)
	db.apply_status(&"chill", 30.0)
	var ha := _record(a)
	var ha2 := _record(a2)
	var hb := _record(b)
	a.command_attack(da)
	a2.command_attack(da2)
	b.command_attack(db)
	await _until(func() -> bool: return ha.size() >= 1 and ha2.size() >= 1 and hb.size() >= 1, 600)
	if ha.is_empty() or ha2.is_empty() or hb.is_empty():
		_ok(false, "bonus_vs_status: hits never landed")
		await _clear([a, a2, b, da, da2, db])
		return
	var want := a.attack_damage * 0.2
	var extra := (full - float(ha[0][1])) - float(ha[0][0])
	var extra_fresh := (full - float(ha2[0][1])) - float(ha2[0][0])
	var extra_b := (full - float(hb[0][1])) - float(hb[0][0])
	_ok(absf(extra - want) < 0.5, "bonus_vs_status: +20 %% on a chilled target (%.2f, want %.2f)" % [extra, want])
	_ok(absf(extra_fresh) < 0.01, "bonus_vs_status: its own chill of this hit does not count (%.2f)" % extra_fresh)
	_ok(absf(extra_b) < 0.01, "bonus_vs_status: nothing without the row (%.2f)" % extra_b)
	await _clear([a, a2, b, da, da2, db])


func _check_splash() -> void:
	var base := Vector3(800, 0, 0)
	var a := _spawn("ash_hurler", A, base)
	var target := _dummy(B, base + Vector3(8, 0, 0))
	var near := _dummy(B, base + Vector3(8, 0, 1.0))
	var far := _dummy(B, base + Vector3(8, 0, -3.5))
	var ally := _dummy(A, base + Vector3(9.0, 0, 0))
	var b := _spawn("ash_hurler", B, base + Vector3(0, 0, 60))
	var tb := _dummy(A, base + Vector3(8, 0, 60))
	var nb := _dummy(A, base + Vector3(8, 0, 61.0))
	await _physics(3)
	var full := target.max_hp
	var ha := _record(a)
	var hb := _record(b)
	a.command_attack(target)
	b.command_attack(tb)
	await _until(func() -> bool: return ha.size() >= 1 and hb.size() >= 1, 900)
	if ha.is_empty() or hb.is_empty():
		_ok(false, "splash: hits never landed")
		await _clear([a, b, target, near, far, ally, tb, nb])
		return
	var dealt := float(ha[0][0])
	var near_loss := full - near.hp
	_ok(near_loss > 0.5 and near_loss <= dealt * 0.4 + 0.01, "splash: the enemy 1 m away takes <= 40 %% (%.2f of %.2f)"
			% [near_loss, dealt])
	_ok(is_equal_approx(far.hp, full), "splash: nothing on an enemy 3.5 m away")
	_ok(is_equal_approx(ally.hp, ally.max_hp), "splash: never an ally")
	_ok(is_equal_approx(nb.hp, full), "splash: nothing without the row")
	await _clear([a, b, target, near, far, ally, tb, nb])


func _check_dot() -> void:
	var base := Vector3(1000, 0, 0)
	var a := _spawn("emberdart_harrier", A, base)
	var da := _dummy(B, base + Vector3(5, 0, 0))
	var a2 := _spawn("duskbolt_harrier", A, base + Vector3(0, 0, 60))
	var da2 := _dummy(B, base + Vector3(5, 0, 60))
	var b := _spawn("emberdart_harrier", B, base + Vector3(0, 0, 120))
	var db := _dummy(A, base + Vector3(5, 0, 120))
	await _physics(3)
	var ha := _record(a)
	var ha2 := _record(a2)
	var hb := _record(b)
	a.command_attack(da)
	a2.command_attack(da2)
	b.command_attack(db)
	await _until(func() -> bool: return ha.size() >= 1 and ha2.size() >= 1 and hb.size() >= 1, 900)
	_ok(da.dot_time_left(&"burn") > 2.0, "dot: Firebrand Javelins burn (%.2f s)" % da.dot_time_left(&"burn"))
	_ok(da2.dot_time_left(&"dusk_bleed") > 3.0 and da2.dot_time_left(&"bleed") == 0.0,
			"dot: Bleeding Bolts dusk_bleed, not Bleakbow's bleed")
	_ok(db.dot_time_left(&"burn") == 0.0, "dot: nothing without the row")
	await _clear([a, a2, b, da, da2, db])
