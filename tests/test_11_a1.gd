extends SceneTree
## Task 11.A1: ChampionBrain class behaviour (docs/design/skills-rework.md section 6). Headless on
## scenes/skirmish.tscn with the bot off, REAL Champions (ChampionType.create_champion + set_champion_class), their
## brains and autocast switched off (the test calls think_now). Proves each row of section 6:
##  1. stance: is_back_line() = Wizard class, or a ranged archetype (Wayfinder, Mender) before its class;
##     in a fight a Wizard Mender keeps 4 m behind its ally, a Sword and Shield Mender attacks;
##  2. target preference: a Spear Wayfinder picks a Nightbolt over a Shade at equal distance (no class: the nearest);
##     a Two-Hand picks the enemy with the most neighbours; a Sword and Shield the enemy attacking an ally; a Wizard
##     the enemy attacking the most hurt ally; the archetype rule first (Spear Oathwall: the keep's attacker; Two-Hand
##     Coin-Cutter: the lowest HP %);
##  3. Mender default: a melee Mender follows 1 m behind the army centre, a Wizard Mender 4 m;
##  4. flee: Champion.flee_pct with the class delta (Sword and Shield Oathwall 15 %, Wizard Mender 50 %);
##  5. decisions use only the team's fog (a Nightbolt in fog is not picked, then is once seen);
##  6. PERF OK: brains + senses <= BUDGET_CAL calibration loops per frame with 6 class champions and 200 units (the
##     old line was 0.1 ms = 100 us per frame).
## Calibration (2026-10-02, as test_20_a3 in 394f88c3 / test_12_a1 in e967cb21): the same code measured 52 us per
##   frame on a quiet laptop and 115.5 us in a loaded CI run (4 Godot runs in parallel + a background service on 13 of
##   16 threads), so the fixed 100 us line flipped. The timing phase times a fixed GDScript loop (_calib_once, the same
##   workload as test_20_a3's) every CAL_EVERY frames, best of CAL_REPEAT, and judges brains + senses per frame as a
##   RATIO of that loop's median: same machine, same moment. The us numbers stay in the log.
## Run:  godot --headless --path . -s tests/test_11_a1.gd --fixed-fps 60 --quit-after 12000

const TASK_ID := "11.A1"
const SCENE := "res://scenes/skirmish.tscn"
const P := 0
const E := 1
const A := Vector3(-30.0, 0.0, 20.0)   # a quiet spot on the player's side
const BUDGET_USEC := 100.0   ## info only now (the old absolute line, printed next to the ratio verdict)
## Brains + senses per frame <= this many calibration-loop medians. Quiet laptop: loop 0.232 ms (test_20_a3's quiet
## runs), brains + senses 52 us = 0.22 loops; 0.43 loops = the old 100 us line on that quiet machine (~1.9x headroom,
## as before). A real regression (2x the work) still fails.
const BUDGET_CAL := 0.43
const CAL_EVERY := 30
const CAL_REPEAT := 3
const TIMING_FRAMES := 600
const UNIT_TARGET := 200

var main: Node
var fog: FogOfWar
var _done := false
var _errors: Array[String] = []
var _checks := 0
var _temp: Array = []


func _initialize() -> void:
	main = load(SCENE).instantiate()
	root.add_child(main)
	current_scene = main
	_run.call_deferred()


func _process(_delta: float) -> bool:
	return _done


# ---------------------------------------------------------------- helpers

func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _check(ok: bool, what: String) -> void:
	_checks += 1
	if ok:
		print("ok   " + what)
	else:
		_errors.append(what)
		print("FAIL " + what)


## A real champion of `arch` with class `cls` (&"" = none) at `level` (only with a class: no draw), brain and
## autocast off.
func _champ(arch: StringName, cls: StringName, pos: Vector3, level: int = 1, auto: bool = false) -> Champion:
	var ch := ChampionType.find(arch).create_champion(0)
	ch.team = P as Unit.Team
	if cls != &"":
		ch.set_champion_class(cls)
	main.add_child(ch)
	ch.global_position = pos
	ch.command_stop()
	if cls != &"" and level > 1:
		ch.add_xp(Champion.LEVEL_TOTAL_XP[level - 1] - ch.xp)
	ch.hp = ch.max_hp
	var brain := _brain(ch)
	if brain:
		brain.enabled = auto
	if ch.abilities and &"autocast_enabled" in ch.abilities:
		ch.abilities.set(&"autocast_enabled", auto)
	_temp.append(ch)
	return ch


func _brain(ch: Node) -> ChampionBrain:
	return ch.get_node_or_null(^"Brain") as ChampionBrain


func _unit(type_id: String, team: int, pos: Vector3) -> Unit:
	var u: Unit = main.make_unit(type_id)
	u.team = team as Unit.Team
	main.add_child(u)
	u.global_position = pos
	u.command_stop()
	_temp.append(u)
	return u


## `foe` attacks `victim` (a recent hit, so the sense lists it in `hits` / the champion's R4 trigger a).
func _hit(foe: Unit, victim: Node) -> void:
	foe.attack_target = victim
	victim.call(&"take_damage", 1.0, foe)


func _sync() -> void:
	fog.update_team(P)
	ChampionSense.for_team(P).refresh()


func _clear() -> void:
	for n: Variant in _temp:
		if n != null and is_instance_valid(n):
			(n as Node).queue_free()
	_temp.clear()
	await _frames(2)


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _nm(n: Variant) -> String:
	return str((n as Node).name) if n != null and is_instance_valid(n) else "null"


# ---------------------------------------------------------------- the run

func _run() -> void:
	var waited := 0
	while not main.match_started:
		await process_frame
		waited += 1
		if waited > 6000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			_done = true
			return
	for child in main.get_children():
		if child is Commander:
			(child as Commander).enabled = false
	fog = main.get(&"fog") as FogOfWar
	if fog == null:
		fog = FogOfWar.find()
	if fog == null:
		print("FAIL %s: no fog of war in the skirmish" % TASK_ID)
		_done = true
		return
	ChampionSense.for_team(P)
	ChampionSense.for_team(E)
	await _frames(3)

	await _phase_stance()
	await _phase_mender_fight()
	await _phase_spear()
	await _phase_two_hand()
	await _phase_sword_shield()
	await _phase_wizard()
	await _phase_archetype_first()
	await _phase_mender_follow()
	await _phase_flee()
	await _phase_fog()
	await _phase_timing()

	print("---- %d checks, %d failed" % [_checks, _errors.size()])
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	_done = true


# 1. Stance flags: every archetype x (no class + the 4 classes).
func _phase_stance() -> void:
	var i := 0
	for arch: StringName in [&"wayfinder", &"oathwall", &"coin_cutter", &"mender"]:
		for cls: StringName in [&"", &"spear", &"sword_shield", &"two_hand", &"wizard"]:
			var ch := _champ(arch, cls, A + Vector3(2.0 * float(i % 5), 0.0, 2.0 * float(i / 5)))
			i += 1
			var want := cls == &"wizard" or (cls == &"" and (arch == &"wayfinder" or arch == &"mender"))
			var b := _brain(ch)
			_check(b != null and b.is_back_line() == want and b.class_id() == cls,
					"stance %s / %s: back line %s" % [arch, cls if cls != &"" else &"no class", want])
	await _clear()


# 1b. In a fight: a Wizard Mender keeps 4 m behind the hit ally; a Sword and Shield Mender attacks.
func _phase_mender_fight() -> void:
	for cls: StringName in [&"wizard", &"sword_shield"]:
		var me := _champ(&"mender", cls, A + Vector3(0.0, 0.0, 5.0))
		var ally := _unit("flame_guard", P, A + Vector3(3.0, 0.0, 0.0))
		var foe := _unit("shade", E, A + Vector3(4.2, 0.0, 0.0))
		foe.max_hp = 4000.0
		foe.hp = 4000.0
		_hit(foe, ally)
		_sync()
		var b := _brain(me)
		b.think_now()
		if cls == &"wizard":
			var goal := b.plan_goal()
			_check(me.intent == ChampionBrain.I_FIGHTING and me.attack_target != foe and goal != Vector3.INF
					and absf(_flat(goal, ally.global_position) - 4.0) <= 0.3
					and _flat(goal, foe.global_position) > _flat(ally.global_position, foe.global_position),
					"Wizard Mender in a fight: back line, goal %.1f m behind the ally (no attack)" % (
					_flat(goal, ally.global_position) if goal != Vector3.INF else -1.0))
		else:
			_check(me.intent == ChampionBrain.I_FIGHTING and me.attack_target == foe,
					"Sword and Shield Mender in a fight: closes in and attacks (target %s)" % _nm(me.attack_target))
		await _clear()


# 2a. Spear: an enemy ranged unit first. Equal distance: the Nightbolt; no class: the nearest.
func _phase_spear() -> void:
	var sp := _champ(&"wayfinder", &"spear", A)
	var shade := _unit("shade", E, A + Vector3(3.0, 0.0, 0.0))
	var bolt := _unit("nightbolt", E, A + Vector3(-3.0, 0.0, 0.0))
	_hit(shade, sp)
	_sync()
	_brain(sp).think_now()
	_check(sp.attack_target == bolt, "Spear Wayfinder picks the Nightbolt over a Shade at equal distance (%s)"
			% _nm(sp.attack_target))
	await _clear()
	# control: no class, the Nightbolt a bit farther -> the nearest (the Shade); the Spear still takes the Nightbolt
	for cls: StringName in [&"", &"spear"]:
		var ch := _champ(&"wayfinder", cls, A)
		var s2 := _unit("shade", E, A + Vector3(3.0, 0.0, 0.0))
		var b2 := _unit("nightbolt", E, A + Vector3(-5.0, 0.0, 0.0))
		_hit(s2, ch)
		_sync()
		_brain(ch).think_now()
		var want: Unit = b2 if cls == &"spear" else s2
		_check(ch.attack_target == want, "%s Wayfinder, Shade 3 m / Nightbolt 5 m: picks the %s (%s)" % [
				"Spear" if cls == &"spear" else "No-class", want.unit_type.id, _nm(ch.attack_target)])
		await _clear()


# 2b. Two-Hand: the enemy with the most enemies within 2.5 m (the middle of a line of three, not a nearer lone one).
func _phase_two_hand() -> void:
	# level 3 (power 340): 4 Shades (danger 320) stay under courage x power x 1.5
	var ch := _champ(&"wayfinder", &"two_hand", A, 3)
	var lone := _unit("shade", E, A + Vector3(0.0, 0.0, -2.0))
	var s1 := _unit("shade", E, A + Vector3(5.0, 0.0, 0.0))
	var s2 := _unit("shade", E, A + Vector3(6.5, 0.0, 0.0))
	var s3 := _unit("shade", E, A + Vector3(8.0, 0.0, 0.0))
	_hit(lone, ch)
	_sync()
	_brain(ch).think_now()
	_check(ch.attack_target == s2, "Two-Hand picks the Shade with 2 neighbours within 2.5 m (%s; lone %s, ends %s %s)"
			% [_nm(ch.attack_target), _nm(lone), _nm(s1), _nm(s3)])
	await _clear()


# 2c. Sword and Shield: the enemy attacking an ally (over a nearer one attacking itself).
func _phase_sword_shield() -> void:
	for cls: StringName in [&"sword_shield", &""]:
		var ch := _champ(&"wayfinder", cls, A)
		var mine := _unit("shade", E, A + Vector3(2.0, 0.0, 0.0))
		var ally := _unit("flame_guard", P, A + Vector3(-5.0, 0.0, 0.0))
		var theirs := _unit("shade", E, A + Vector3(-6.2, 0.0, 0.0))
		_hit(mine, ch)
		_hit(theirs, ally)
		_sync()
		_brain(ch).think_now()
		var want: Unit = theirs if cls == &"sword_shield" else mine
		_check(ch.attack_target == want, "%s: picks the Shade %s (%s)" % ["Sword and Shield" if cls != &"" else "no class",
				"attacking the ally" if cls != &"" else "nearest", _nm(ch.attack_target)])
		await _clear()


# 2d. Wizard: the enemy attacking the most hurt ally (not the nearest attacker).
func _phase_wizard() -> void:
	for cls: StringName in [&"wizard", &""]:
		var ch := _champ(&"wayfinder", cls, A)
		var hurt := _unit("flame_guard", P, A + Vector3(6.0, 0.0, 0.0))
		var fine := _unit("flame_guard", P, A + Vector3(0.0, 0.0, 3.0))
		var foe_hurt := _unit("shade", E, A + Vector3(7.2, 0.0, 0.0))
		var foe_fine := _unit("shade", E, A + Vector3(0.0, 0.0, 4.2))
		_hit(foe_hurt, hurt)
		_hit(foe_fine, fine)
		hurt.hp = hurt.max_hp * 0.3
		fine.hp = fine.max_hp * 0.8
		_sync()
		_brain(ch).think_now()
		var want: Unit = foe_hurt if cls == &"wizard" else foe_fine
		_check(ch.attack_target == want, "%s: picks the Shade %s (%s)" % ["Wizard" if cls != &"" else "no class",
				"attacking the ally at 30 %" if cls != &"" else "nearest", _nm(ch.attack_target)])
		await _clear()


# 2e. The archetype rule first: a Spear Oathwall takes the Shade hitting the keep over a Nightbolt hitting a
# soldier; a Two-Hand Coin-Cutter takes the lowest HP % over a crowd.
func _phase_archetype_first() -> void:
	var keep := main.keep_of(P) as Node3D
	var kp := keep.global_position
	var out := _dir(kp)
	var oath := _champ(&"oathwall", &"spear", kp + out * 9.0)
	var on_keep := _unit("shade", E, kp + out * (Unit.radius_of(keep) + 1.0) + _side(out) * 2.0)
	var ally := _unit("flame_guard", P, kp + out * 11.0 + _side(out) * 3.0)
	var bolt := _unit("nightbolt", E, kp + out * 11.0 + _side(out) * 6.0)
	_hit(on_keep, keep)
	_hit(bolt, ally)
	_sync()
	_brain(oath).think_now()
	_check(oath.attack_target == on_keep, "Spear Oathwall: the keep's attacker first (archetype rule) over a Nightbolt (%s)"
			% _nm(oath.attack_target))
	await _clear()
	var cc := _champ(&"coin_cutter", &"two_hand", A, 3)
	var weak := _unit("shade", E, A + Vector3(0.0, 0.0, -4.0))
	weak.hp = weak.max_hp * 0.4
	_hit(weak, cc)
	var crowd: Array[Unit] = []
	for k in 3:
		crowd.append(_unit("shade", E, A + Vector3(3.0 + 1.5 * float(k), 0.0, 0.0)))
	_sync()
	_brain(cc).think_now()
	_check(cc.attack_target == weak, "Two-Hand Coin-Cutter: the lowest HP %% first (archetype rule) over a crowd (%s)"
			% _nm(cc.attack_target))
	await _clear()


func _dir(kp: Vector3) -> Vector3:
	var d := Vector3(-kp.x, 0.0, -kp.z)   # toward the map centre
	return d.normalized() if d.length() > 0.1 else Vector3.FORWARD


func _side(d: Vector3) -> Vector3:
	return Vector3(-d.z, 0.0, d.x)


# 3. Mender default: 1 m behind the army centre with a melee class, 4 m as a Wizard (and before the class).
func _phase_mender_follow() -> void:
	var b := Vector3(-20.0, 0.0, 30.0)
	for cls: StringName in [&"sword_shield", &"wizard", &"", &"spear"]:
		var big: Array[Unit] = []
		for i in 5:
			big.append(_unit("flame_guard", P, b + Vector3(float(i % 3) * 1.6, 0.0, float(i / 3) * 1.6)))
		var me := _champ(&"mender", cls, Vector3(-28.0, 0.0, 40.0))
		var brain := _brain(me)
		_sync()
		brain.think_now()
		var centre := brain.plan_node() as Node3D
		var goal := brain.plan_goal()
		var want := 4.0 if cls == &"wizard" or cls == &"" else 1.0
		var got := _flat(goal, centre.global_position) if centre != null and goal != Vector3.INF else -1.0
		_check(brain.plan == ChampionBrain.Plan.FOLLOW and centre != null and big.has(centre)
				and absf(got - want) <= 0.3 and me.intent == ChampionBrain.I_ARMY,
				"Mender %s follows the army %.0f m behind its centre (%.2f)" % [cls if cls != &"" else &"no class", want, got])
		await _clear()


# 4. Flee: Champion.flee_pct holds the class delta; the brain reads it (never adds it twice).
func _phase_flee() -> void:
	var kp := (main.keep_of(P) as Node3D).global_position
	var cases := [[&"oathwall", &"sword_shield", 0.15], [&"oathwall", &"", 0.20], [&"mender", &"wizard", 0.50],
			[&"coin_cutter", &"two_hand", 0.35]]
	for c: Array in cases:
		var ch := _champ(c[0], c[1], kp + Vector3(0.0, 0.0, -28.0))
		var brain := _brain(ch)
		var want: float = c[2]
		_sync()
		_check(absf(brain.flee_ratio() - want) < 0.001, "%s %s: flee threshold %d %% (reads %.3f)" % [c[0], c[1], roundi(want * 100.0),
				brain.flee_ratio()])
		ch.hp = ch.max_hp * (want + 0.01)
		brain.think_now()
		var stays := not brain.fleeing
		ch.hp = ch.max_hp * (want - 0.01)
		brain.think_now()
		_check(stays and brain.fleeing and ch.intent == ChampionBrain.I_FLEEING,
				"%s %s: stays at %d %%, flees at %d %%" % [c[0], c[1], roundi(want * 100.0) + 1, roundi(want * 100.0) - 1])
		await _clear()


# 5. Fog: a Spear Wayfinder does not pick a Nightbolt it cannot see (22 m: beyond its 18 m sight and 13 m from the
# ally), then picks it once the fog shows it.
func _phase_fog() -> void:
	var sp := _champ(&"wayfinder", &"spear", A)
	var ally := _unit("flame_guard", P, A + Vector3(9.0, 0.0, 0.0))
	var shade := _unit("shade", E, A + Vector3(10.4, 0.0, 0.0))
	var bolt := _unit("nightbolt", E, A + Vector3(22.0, 0.0, 0.0))
	_hit(shade, ally)
	_sync()
	var sense := ChampionSense.for_team(P)
	var hidden := not sense.knows(bolt)
	_brain(sp).think_now()
	_check(hidden and sp.attack_target == shade, "fog: the hidden Nightbolt is ignored (hidden %s, target %s)" % [hidden,
			_nm(sp.attack_target)])
	fog.enabled = false
	shade.attack_target = ally
	_hit(shade, ally)
	_sync()
	_brain(sp).think_now()
	_check(sense.knows(bolt) and sp.attack_target == bolt, "fog off: the Nightbolt is seen and picked (%s)"
			% _nm(sp.attack_target))
	fog.enabled = true
	await _clear()
	await _frames(2)


# 6. Timing: 6 class champions (automatic brains and autocast), 200 units.
func _phase_timing() -> void:
	var list := [[&"wayfinder", &"spear", Vector3(-30.0, 0.0, 30.0)], [&"oathwall", &"sword_shield", Vector3(-38.0, 0.0, 34.0)],
			[&"mender", &"wizard", Vector3(-34.0, 0.0, 28.0)], [&"coin_cutter", &"two_hand", Vector3(-26.0, 0.0, 34.0)],
			[&"mender", &"spear", Vector3(-32.0, 0.0, 38.0)], [&"wayfinder", &"wizard", Vector3(-36.0, 0.0, 24.0)]]
	for e: Array in list:
		_champ(e[0], e[1], e[2], 3, true)
	var have := get_nodes_in_group(&"units").size()
	var i := 0
	while have < UNIT_TARGET:
		var team := P if i % 2 == 0 else E
		var k := i / 2
		var base := Vector3(-48.0, 0.0, 12.0) if team == P else Vector3(34.0, 0.0, -12.0)
		_unit("flame_guard" if team == P else "shade", team, base + Vector3(float(k % 10) * 1.5, 0.0, float(k / 10) * 1.5))
		have += 1
		i += 1
	await _frames(60)
	_init_calib()
	var b0 := ChampionBrain.usec_total
	var s0 := ChampionSense.usec_total
	for f in TIMING_FRAMES:
		await process_frame
		if f % CAL_EVERY == 0:
			_sample_calib()
	var per_frame := float(ChampionBrain.usec_total - b0 + ChampionSense.usec_total - s0) / float(TIMING_FRAMES)
	var cal_us := _cal_median_usec()
	var ratio := per_frame / cal_us if cal_us > 0.0 else INF
	print("timing: %d units, 6 class champions: brains + senses %.1f us per frame" % [
			get_nodes_in_group(&"units").size(), per_frame])
	print("timing: calibration loop median %.3f ms over %d samples (best of %d); brains + senses = %.3f loops per frame (budget %.2f; the old %.0f us line %s)"
			% [cal_us / 1000.0, _cal_samples.size(), CAL_REPEAT, ratio, BUDGET_CAL, BUDGET_USEC,
			"over" if per_frame >= BUDGET_USEC else "under"])
	_check(cal_us > 0.0 and ratio <= BUDGET_CAL, "timing: %.3f calibration loops per frame (<= %.2f; %.1f us, loop %.3f ms)"
			% [ratio, BUDGET_CAL, per_frame, cal_us / 1000.0])
	if cal_us > 0.0 and ratio <= BUDGET_CAL:
		print("PERF OK")
	await _clear()


# ---------------------------------------------------------------- calibration (test_20_a3's workload)

var _cal_pts: Array[Vector3] = []
var _cal_dict := {}
var _cal_samples: Array[int] = []
var _cal_sink := 0.0


func _init_calib() -> void:
	_cal_pts.clear()
	_cal_dict.clear()
	_cal_samples.clear()
	for i in 256:
		_cal_pts.append(Vector3(float((i * 37) % 101) - 50.0, 0.0, float((i * 53) % 97) - 48.0))
	for i in 64:
		_cal_dict[i] = i * 0.5


func _sample_calib() -> void:
	var best := 1 << 30
	for r in CAL_REPEAT:
		best = mini(best, _calib_once())
	_cal_samples.append(best)


## The calibration workload (usec): a fixed loop of Vector3 math, typed-array reads and Dictionary lookups, the kind
## of work a brain / sense pass is made of.
func _calib_once() -> int:
	var t0 := Time.get_ticks_usec()
	var acc := 0.0
	var n := _cal_pts.size()
	for r in 8:
		for i in n:
			var p := _cal_pts[i]
			var d := p.distance_squared_to(_cal_pts[(i * 7 + r) % n])
			if d < 400.0:
				acc += sqrt(d)
			acc += float(_cal_dict.get(i & 63, 0.0))
	_cal_sink += acc
	return Time.get_ticks_usec() - t0


func _cal_median_usec() -> float:
	if _cal_samples.is_empty():
		return 0.0
	var s := _cal_samples.duplicate()
	s.sort()
	return float(s[s.size() / 2])
