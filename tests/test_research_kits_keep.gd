extends SceneTree
## UR.G4 (docs/design/unit-upgrades.md 9-10, 14): K reads for the 4 caster rows and the 4 tier-3 rows through
## UnitResearch.param. The PLAYER team is granted the 8 rows, the ENEMY team is not: each number changes only for the
## team that has the row.
## - Molten Slag: Slag Rain 12 -> 18 damage, radius 3 -> 3.5 m;
## - Hungering Tithe: Blood Tithe heal 10 -> 14 / s, drain 5 -> 7 / s;
## - Deep Bulwark: Rime Bulwark 8 -> 12 s, 4 -> 5 m;
## - Deep Snag: Snagroot drag 7 -> 9 m, root 1 -> 1.5 s;
## - Double Powder: Powder Charge 250 -> 325, pause 10 -> 14 s;
## - Crimson Thirst: Nightblood 35 -> 45 %, Blood Frenzy under 50 % (was 40);
## - Shard Ward: Hold the Line shields the Shardguard 100 for 6 s;
## - Thornstorm: Seed Storm 30 -> 40 damage, cooldown 16 -> 12 s.
## Run:  tools/godot_run.ps1 --headless --path . -s tests/test_research_kits_keep.gd --fixed-fps 60 --quit-after 20000

const TASK_ID := "research_kits_keep"
const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER := preload("res://scripts/ai/commander.gd")
const PLAYER := 0
const ENEMY := 1
const ROWS: Array[StringName] = [&"kilnwarden_molten_slag", &"gloom_deacon_hungering_tithe",
		&"rimecarver_deep_bulwark", &"bramblesage_deep_snag", &"ashveil_saboteur_double_powder",
		&"nightblood_reaver_crimson_thirst", &"shardguard_shard_ward", &"briar_roc_thornstorm"]

var main: Node
var _errors: Array[String] = []
var _checks := 0
var _at := Vector3.ZERO
var _dir := Vector3.ZERO
var _side := Vector3.ZERO


## A fake enemy building for the Powder Charge.
class FakeBuilding extends Node3D:
	var team := 1
	var hp := 2000.0
	func _ready() -> void:
		add_to_group(&"buildings")
	func is_alive() -> bool:
		return hp > 0.0
	func take_damage(amount: float, _attacker: Node3D = null) -> void:
		hp -= amount
	func target_radius() -> float:
		return 1.0


func _initialize() -> void:
	_run.call_deferred()


func _ok(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_errors.append(what)
		print("  x " + what)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _near(a: float, b: float, eps: float = 0.6) -> bool:
	return absf(a - b) <= eps


func _run() -> void:
	main = load(SCENE).instantiate()
	main.set(&"camps_enabled", false)
	main.set(&"beasts_enabled", false)
	main.set(&"time_limit_s", 0.0)
	root.add_child(main)
	current_scene = main
	var t0 := Time.get_ticks_msec()
	while not bool(main.get(&"match_started")) or main.get(&"hero") == null:
		await process_frame
		if Time.get_ticks_msec() - t0 > 180000:
			_ok(false, "the skirmish never started")
			_finish()
			return
	await _frames(5)
	for n in main.get_children():
		if n.get_script() == COMMANDER:
			n.set(&"enabled", false)
	var keep: Node3D = main.get(&"keep")
	_dir = -Vector3(keep.global_position.x, 0.0, keep.global_position.z).normalized()
	_side = _dir.cross(Vector3.UP)
	_at = keep.global_position + _dir * 52.0
	for n in get_nodes_in_group(&"units"):
		if n is Unit and int(n.team) == 2 and _flat(n.global_position, _at) < 45.0:
			n.queue_free()
	await _frames(2)
	_check_defaults()   # before any grant: every key gives today's number
	var ur := UnitResearch.for_team(PLAYER)
	_ok(ur != null, "no UnitResearch node in the skirmish")
	if ur == null:
		_finish()
		return
	for id in ROWS:
		ur.grant(id)
	_ok(UnitResearch.team_has(PLAYER, &"briar_roc_thornstorm") and not UnitResearch.team_has(ENEMY,
			&"briar_roc_thornstorm"), "grant: only the player has the rows")
	await _check_slag()
	await _check_tithe()
	await _check_bulwark()
	await _check_snag()
	await _check_powder()
	await _check_reaver()
	await _check_shard_ward()
	await _check_seed_storm()
	await _check_mid_life()
	_finish()


func _finish() -> void:
	if _errors.is_empty():
		print("PASS %s (%d checks)" % [TASK_ID, _checks])
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors.slice(0, 30))])
	quit(0 if _errors.is_empty() else 1)


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _spawn(id: String, team: int, pos: Vector3) -> Unit:
	var u := UnitType.find(id).create_unit()
	u.team = team as Unit.Team
	main.add_child(u)
	u.global_position = pos
	u.command_hold()
	return u


func _dummy(pos: Vector3, team: int, hp: float = 5000.0) -> Unit:
	var u := Unit.new()
	u.team = team as Unit.Team
	u.max_hp = hp
	u.aggro_range = 0.0
	u.attack_damage = 0.0
	main.add_child(u)
	u.global_position = pos
	u.command_hold()
	u.hide_from_auto_target(9999.0)
	return u


func _cleanup(nodes: Array) -> void:
	for n in nodes:
		if is_instance_valid(n):
			n.queue_free()
	await _frames(3)


## A caster of `team` with full mana and every autocast off.
func _caster(id: String, team: int, pos: Vector3) -> Unit:
	var u := _spawn(id, team, pos)
	var ab := CasterKit.ability_of(u)
	if ab:
		for sid: StringName in CasterKit.CASTERS[StringName(id)]["spells"]:
			ab.set_autocast(sid, false)
		ab.mana = 1000.0
	return u


func _other(team: int) -> int:
	return ENEMY if team == PLAYER else PLAYER


# ---------------------------------------------------------------- defaults (nothing granted)

func _check_defaults() -> void:
	var cases := {"kilnwarden": [[&"slag_rain_damage", 12.0], [&"slag_rain_radius", 3.0]],
			"ashveil_saboteur": [[&"powder_damage", 250.0]], "briar_roc": [[&"seed_storm_cd", 16.0]]}
	for id: String in cases:
		var u := _spawn(id, PLAYER, _at + _side * 30.0)
		for kv: Array in cases[id]:
			_ok(_near(UnitResearch.param(u, kv[0], kv[1]), kv[1], 0.001), "default %s %s" % [id, kv[0]])
		u.queue_free()
	await _frames(2)


# ---------------------------------------------------------------- casters

func _slag_case(team: int) -> Array[float]:
	var c := _caster("kilnwarden", team, _at)
	var p := _at + _dir * 6.0
	var inner := _dummy(p, _other(team))
	var outer := _dummy(p, _other(team))
	outer.global_position = p + _side * (3.25 + outer.radius)   # the slag counts the victim's radius
	await _frames(30)   # the caster's sight reaches the fog first
	var r := CasterKit.ability_of(c).cast(&"slag_rain", p)
	_ok(r == "", "Slag Rain cast (team %d): %s" % [team, r])
	await _frames(90)
	var out: Array[float] = [5000.0 - inner.hp, 5000.0 - outer.hp]
	await _cleanup([c, inner, outer])
	return out


func _check_slag() -> void:
	var mine := await _slag_case(PLAYER)
	var theirs := await _slag_case(ENEMY)
	_ok(_near(mine[0], 18.0, 0.5) and _near(mine[1], 18.0, 0.5), "Molten Slag: 18 in 3.5 m (%.1f / %.1f)" % mine)
	_ok(_near(theirs[0], 12.0, 0.5) and theirs[1] < 0.1, "no row: 12 in 3 m (%.1f / %.1f)" % theirs)


func _tithe_case(team: int) -> Array[float]:
	var c := _caster("gloom_deacon", team, _at)
	var ally := _dummy(_at + _dir * 3.0, team)
	ally.hp = 1000.0
	var foe := _dummy(_at + _dir * 5.0, _other(team))
	await _frames(30)
	var r := CasterKit.ability_of(c).cast(&"blood_tithe", ally)
	_ok(r == "", "Blood Tithe cast (team %d): %s" % [team, r])
	await _frames(30)
	var h0 := ally.hp
	var f0 := foe.hp
	await _frames(120)
	var out: Array[float] = [(ally.hp - h0) / 2.0, (f0 - foe.hp) / 2.0]
	await _cleanup([c, ally, foe])
	return out


func _check_tithe() -> void:
	var mine := await _tithe_case(PLAYER)
	var theirs := await _tithe_case(ENEMY)
	_ok(_near(mine[0], 14.0, 1.5) and _near(mine[1], 7.0, 0.8), "Hungering Tithe 14 / 7 per s (%.1f / %.1f)" % mine)
	_ok(_near(theirs[0], 10.0, 1.5) and _near(theirs[1], 5.0, 0.8), "no row: Tithe 10 / 5 per s (%.1f / %.1f)" % theirs)


func _bulwark_case(team: int) -> Array[float]:
	var c := _caster("rimecarver", team, _at)
	await _frames(30)
	var before := CasterKit.bulwarks_of(team).size()
	var r := CasterKit.ability_of(c).cast(&"rime_bulwark", _at + _dir * 5.0)
	_ok(r == "", "Rime Bulwark cast (team %d): %s" % [team, r])
	await _frames(45)
	var walls := CasterKit.bulwarks_of(team)
	var out: Array[float] = [0.0, 0.0]
	if walls.size() > before:
		var w := walls[walls.size() - 1] as RimeBulwark
		out = [w.length, w.lifetime]
	for w: Variant in walls:
		(w as RimeBulwark).finish(&"melt")
	await _cleanup([c])
	return out


func _check_bulwark() -> void:
	var mine := await _bulwark_case(PLAYER)
	var theirs := await _bulwark_case(ENEMY)
	_ok(_near(mine[0], 5.0, 0.01) and _near(mine[1], 12.0, 0.01), "Deep Bulwark 5 m / 12 s (%.1f / %.1f)" % mine)
	_ok(_near(theirs[0], 4.0, 0.01) and _near(theirs[1], 8.0, 0.01), "no row: Bulwark 4 m / 8 s (%.1f / %.1f)" % theirs)


func _snag_case(team: int) -> Array[float]:
	var c := _caster("bramblesage", team, _at)
	var t := _dummy(_at + _dir * 8.9, _other(team))
	await _frames(2)
	t.global_position = c.global_position + _dir * (8.9 + t.radius)
	var spot := _dummy(t.global_position + _side * 2.0, team)   # sight on the target (fog)
	await _frames(30)
	var d0 := _flat(t.global_position, c.global_position)
	var r := CasterKit.ability_of(c).cast(&"snagroot", t)
	_ok(r == "", "Snagroot cast (team %d): %s" % [team, r])
	var root := 0.0
	for i in 150:
		await _frames(1)
		if t.has_status(&"rooted"):
			root = t.status_time_left(&"rooted")
			break
	var out: Array[float] = [d0 - _flat(t.global_position, c.global_position), root]
	await _cleanup([c, t, spot])
	return out


func _check_snag() -> void:
	var mine := await _snag_case(PLAYER)
	var theirs := await _snag_case(ENEMY)
	_ok(mine[0] > 7.3 and _near(mine[1], 1.5, 0.05), "Deep Snag drag > 7 m, root 1.5 s (%.2f / %.2f)" % mine)
	_ok(_near(theirs[0], 7.0, 0.15) and _near(theirs[1], 1.0, 0.05), "no row: drag 7 m, root 1 s (%.2f / %.2f)" % theirs)


# ---------------------------------------------------------------- tier-3 units

func _check_powder() -> void:
	var a := _at
	var b := _at + _side * 20.0
	var sab_p := _spawn("ashveil_saboteur", PLAYER, a)
	var sab_e := _spawn("ashveil_saboteur", ENEMY, b)
	sab_p.attack_damage = 0.0   # only the charge hurts the buildings
	sab_e.attack_damage = 0.0
	var fb_p := FakeBuilding.new()   # the player's Saboteur blows an enemy building
	fb_p.team = ENEMY
	main.add_child(fb_p)
	fb_p.global_position = a - _side * 2.5
	var fb_e := FakeBuilding.new()
	fb_e.team = PLAYER
	main.add_child(fb_e)
	fb_e.global_position = b + _side * 2.5
	await _frames(int(9.0 * 60))
	var lost_p := 2000.0 - fb_p.hp
	var lost_e := 2000.0 - fb_e.hp
	_ok(_near(lost_p, 325.0, 0.5), "Double Powder 325 (%.0f)" % lost_p)
	_ok(_near(lost_e, 250.0, 0.5), "no row: Powder Charge 250 (%.0f)" % lost_e)
	var key := T3Kit.META_PAUSED
	if fb_p.has_meta(key) and fb_e.has_meta(key):
		var diff := float(fb_p.get_meta(key)) - float(fb_e.get_meta(key))
		_ok(_near(diff, 4.0, 0.3), "Double Powder pause 14 s vs 10 s (diff %.2f)" % diff)
	else:
		_ok(false, "a Powder Charge did not pause its building")
	await _cleanup([sab_p, sab_e, fb_p, fb_e])


func _check_reaver() -> void:
	var cases := {PLAYER: 45.0, ENEMY: 35.0}
	for team: int in cases:
		var rv := _spawn("nightblood_reaver", team, _at)
		var bag := _dummy(_at + _dir * 1.5, _other(team))
		await _frames(2)
		rv.hp = 100.0
		rv.attack_landed.emit(bag, 100.0)
		_ok(_near(rv.hp - 100.0, cases[team], 0.1), "Nightblood team %d: %.0f %% (%.1f)" % [team, cases[team], rv.hp - 100.0])
		# 45 % HP: under the researched 50 % bar, over the base 40 %.
		rv.hp = rv.max_hp * 0.45
		await _frames(40)
		var fr := T3Kit.ability_of(rv).is_frenzied()
		_ok(fr == (team == PLAYER), "Blood Frenzy at 45 %% HP, team %d: %s" % [team, fr])
		await _cleanup([rv, bag])


func _check_shard_ward() -> void:
	for team: int in [PLAYER, ENEMY]:
		var sg := _spawn("shardguard", team, _at)
		var foe := _dummy(_at + _dir * 2.0, _other(team))
		await _frames(2)
		var fired := T3Kit.ability_of(sg).hold_the_line(foe)
		_ok(fired, "Hold the Line fired (team %d)" % team)
		if team == PLAYER:
			_ok(_near(sg.shield, 100.0, 0.01) and _near(sg.shield_time_left(), 6.0, 0.05),
					"Shard Ward shield 100 / 6 s (%.0f / %.2f)" % [sg.shield, sg.shield_time_left()])
		else:
			_ok(sg.shield <= 0.0, "no row: no Hold the Line shield (%.0f)" % sg.shield)
		await _cleanup([sg, foe])
	# A bigger shield already on it (Snow Shield, Rime Aegis, Vow) is never replaced by the ward.
	var sg2 := _spawn("shardguard", PLAYER, _at)
	var foe2 := _dummy(_at + _dir * 2.0, ENEMY)
	await _frames(2)
	sg2.add_shield(150.0, 10.0)
	T3Kit.ability_of(sg2).hold_the_line(foe2)
	_ok(_near(sg2.shield, 150.0, 0.01), "Shard Ward replaced a bigger shield (%.0f)" % sg2.shield)
	await _cleanup([sg2, foe2])


func _check_seed_storm() -> void:
	var cases := {PLAYER: [40.0, 12.0], ENEMY: [30.0, 16.0]}
	for team: int in cases:
		var roc := _spawn("briar_roc", team, _at)
		roc.set_physics_process(false)
		var g := _dummy(_at + _dir * 5.0, _other(team))
		await _frames(2)
		var g0 := g.hp
		var ab := T3Kit.ability_of(roc)
		ab.seed_storm(g.global_position)
		var want: Array = cases[team]
		_ok(_near(g0 - g.hp, want[0], 0.1) and _near(ab.cooldown_left(&"seed_storm"), want[1], 0.05),
				"Seed Storm team %d: %.0f / %.0f s (%.1f / %.2f)" % [team, want[0], want[1], g0 - g.hp,
				ab.cooldown_left(&"seed_storm")])
		await _cleanup([roc, g])


# ---------------------------------------------------------------- a row finished while the unit lives

## Last: grants ENEMY rows while its Reaver / Deacon already live; the cached numbers follow.
func _check_mid_life() -> void:
	var rv := _spawn("nightblood_reaver", ENEMY, _at)
	var bag := _dummy(_at + _dir * 1.5, PLAYER)
	await _frames(2)
	rv.hp = 100.0
	rv.attack_landed.emit(bag, 100.0)
	_ok(_near(rv.hp - 100.0, 35.0, 0.1), "mid-life: before the row 35 %% (%.1f)" % (rv.hp - 100.0))
	rv.hp = rv.max_hp   # no Blood Frenzy (60 %) while it waits
	var ur := UnitResearch.for_team(ENEMY)
	ur.grant(&"nightblood_reaver_crimson_thirst")
	ur.grant(&"gloom_deacon_hungering_tithe")
	await _frames(40)   # the team's research node was just made: the Reaver finds it on its next 0.5 s tick
	rv.hp = 100.0
	rv.attack_landed.emit(bag, 100.0)
	_ok(_near(rv.hp - 100.0, 45.0, 0.1), "mid-life: Crimson Thirst on a living Reaver (%.1f)" % (rv.hp - 100.0))
	await _cleanup([rv, bag])
	var theirs := await _tithe_case(ENEMY)
	_ok(_near(theirs[0], 14.0, 1.5), "mid-life: Hungering Tithe for the enemy now (%.1f)" % theirs[0])
