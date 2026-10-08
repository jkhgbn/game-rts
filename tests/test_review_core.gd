extends SceneTree
## Regression checks for the core / units / AI findings of docs/reviews/review-2026-10-08.md (scenes/main.tscn):
## - H1 Starfall spares allied seats and truced nodes, still hits both hostile seats;
## - H2 ChampionAbilities._scan puts an allied seat's units in _allies, never in _enemies (truced: neither);
##   ChampionSense never lists an allied seat's units / towers / keep as enemies or danger;
## - M1 Commander senses every hostile seat (_is_hostile_seat), NEUTRAL excluded;
## - M2 Projectile splash and SpellZone ticks spare allied seats and truced nodes;
## - M3 Flame Burst makes ONE enemy scan per try (was 1 + one per candidate) and still hits the clump, not the ally;
## - M4 caster ally spells accept an allied seat (Blood Tithe target_reason);
## - L2 T3Kit counts no allied unit as an enemy; L3 an allied Scrying Rune reveals no friend; L4 the Bulwark registry
##   empties; L5 AICasters.prune_dead_ids drops freed ids; L10 Teams.is_ally == is_allied_fast; L11 bound is_connected.
## Run:  godot --headless --path . -s tests/test_review_core.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "review_core"
const PLAYER := 0
const ENEMY := 1
const NEUTRAL := 2
const ALLY := 3
const ENEMY_2 := 4
const SIDES_2V2 := {PLAYER: 0, ALLY: 0, ENEMY: 1, ENEMY_2: 1}

var main: Node
var _errors: Array[String] = []
var _checks := 0
var _spot := Vector3.ZERO


func _initialize() -> void:
	_run.call_deferred()


func _ok(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_errors.append(what)
		print("  x " + what)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _physics(n: int) -> void:
	for i in n:
		await physics_frame


func _run() -> void:
	NewUnits12.force_enabled = true
	CasterKit.force_enabled = true
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	var t0 := Time.get_ticks_msec()
	while main.get(&"hero") == null:
		await process_frame
		if Time.get_ticks_msec() - t0 > 120000:
			_ok(false, "the map never got ready")
			_finish()
			return
	await _frames(5)
	var keep: Node3D = main.get(&"keep")
	var dir := -Vector3(keep.global_position.x, 0.0, keep.global_position.z).normalized()
	_spot = keep.global_position + dir * 16.0
	_check_teams()
	await _check_starfall()
	await _check_projectile()
	await _check_spell_zone()
	await _check_champion_scan()
	await _check_champion_sense()
	_check_commander()
	await _check_flame_burst()
	await _check_blood_tithe()
	await _check_lows()
	_finish()


func _finish() -> void:
	Teams.reset()
	CasterKit.reset()
	NewUnits12.force_enabled = false
	CasterKit.force_enabled = false
	if _errors.is_empty():
		print("PASS %s (%d checks)" % [TASK_ID, _checks])
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors.slice(0, 30))])
	quit(0 if _errors.is_empty() else 1)


## A punching bag: no damage, never auto-targeted, holds still.
func _dummy(team: int, pos: Vector3, hp: float = 5000.0) -> Unit:
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


func _unit(id: String, team: int, pos: Vector3) -> Unit:
	var u: Unit = UnitType.find(id).create_unit()
	u.team = team as Unit.Team
	main.add_child(u)
	u.global_position = pos
	return u


func _lost(u: Unit) -> float:
	return u.max_hp - u.hp


func _free(nodes: Array) -> void:
	for n: Variant in nodes:
		if is_instance_valid(n):
			Unit.set_truce_id(n as Node, &"")
			(n as Node).queue_free()
	await _frames(2)


## Caster (PLAYER) + ally (ALLY) + enemy (ENEMY) + enemy_2 (ENEMY_2) + truced (ENEMY, same truce as the caster), all
## within 1.2 m of `c`. Returns [src, ally, enemy, enemy2, truced].
func _cast_set(c: Vector3) -> Array:
	var src := _dummy(PLAYER, c + Vector3(-6.0, 0, 0))
	var ally := _dummy(ALLY, c + Vector3(0.8, 0, 0))
	var enemy := _dummy(ENEMY, c + Vector3(-0.8, 0, 0))
	var enemy2 := _dummy(ENEMY_2, c + Vector3(0, 0, 0.8))
	var truced := _dummy(ENEMY, c + Vector3(0, 0, -0.8))
	Unit.set_truce_id(src, &"review_core")
	Unit.set_truce_id(truced, &"review_core")
	return [src, ally, enemy, enemy2, truced]


func _check_hits(grp: Array, what: String) -> void:
	_ok(_lost(grp[1]) == 0.0, "%s: the allied seat took %.1f" % [what, _lost(grp[1])])
	_ok(_lost(grp[4]) == 0.0, "%s: the truced unit took %.1f" % [what, _lost(grp[4])])
	_ok(_lost(grp[2]) > 0.0, "%s: the ENEMY seat took nothing" % what)
	_ok(_lost(grp[3]) > 0.0, "%s: the ENEMY_2 seat took nothing" % what)


# ---------------------------------------------------------------- L10

func _check_teams() -> void:
	Teams.configure(SIDES_2V2)
	for a in [PLAYER, ENEMY, NEUTRAL, ALLY, ENEMY_2]:
		for b in [PLAYER, ENEMY, NEUTRAL, ALLY, ENEMY_2]:
			_ok(Teams.is_ally(a, b) == Teams.is_allied_fast(a, b), "Teams.is_ally(%d, %d) differs" % [a, b])
	_ok(Teams.hostile_seats(ALLY) == [ENEMY, ENEMY_2], "hostile seats of ALLY: %s" % [Teams.hostile_seats(ALLY)])


# ---------------------------------------------------------------- H1

func _check_starfall() -> void:
	Teams.configure(SIDES_2V2)
	var c := _spot
	var grp := _cast_set(c)
	var star := ChampionAbilities.StarfallStrike.new()
	star.caster = grp[0]
	star.team = PLAYER
	star.damage = 40.0
	star.radius = 3.5
	star.left = 0.05
	main.add_child(star)
	star.global_position = c
	await _physics(10)
	_check_hits(grp, "Starfall")
	await _free(grp)


# ---------------------------------------------------------------- M2

func _check_projectile() -> void:
	Teams.configure(SIDES_2V2)
	var c := _spot + Vector3(0, 0, 8.0)
	var grp := _cast_set(c)
	var p := Projectile.new()
	main.add_child(p)
	p.launch_at_point(grp[0], c + Vector3(-3.0, 1.5, 0), c, 40.0, 3.0, Color.ORANGE)
	await _physics(60)
	_check_hits(grp, "Projectile splash")
	await _free(grp)


func _check_spell_zone() -> void:
	Teams.configure(SIDES_2V2)
	var c := _spot + Vector3(0, 0, -8.0)
	var grp := _cast_set(c)
	var z := SpellZone.new()
	z.setup(grp[0], PLAYER, 3.0, 1.0, 10.0, 0.25, 0.0, Color.ORANGE)
	main.add_child(z)
	z.global_position = c
	await _physics(75)
	_check_hits(grp, "SpellZone")
	await _free(grp)


# ---------------------------------------------------------------- H2

func _check_champion_scan() -> void:
	Teams.configure(SIDES_2V2)
	var c := _spot
	var grp := _cast_set(c)
	var ab := ChampionAbilities.new()
	ab.setup(grp[0])
	main.add_child(ab)
	ab.set_physics_process(false)
	ab._scan(false)
	var enemies: Array = ab._enemies
	var allies: Array = ab._allies
	_ok(allies.has(grp[1]), "champion scan: the allied seat's unit is not in _allies")
	_ok(not enemies.has(grp[1]), "champion scan: the allied seat's unit is in _enemies")
	_ok(not enemies.has(grp[4]), "champion scan: the truced unit is in _enemies")
	_ok(enemies.has(grp[2]) and enemies.has(grp[3]), "champion scan: a hostile seat's unit is missing from _enemies")
	ab.queue_free()
	await _free(grp)


func _check_champion_sense() -> void:
	# ENEMY (the map's enemy seat, with its keep / towers / army) joins PLAYER's side: nothing of it is an enemy now.
	Teams.configure({PLAYER: 0, ENEMY: 0, ENEMY_2: 1})
	var sense := ChampionSense.for_team(PLAYER)
	await _frames(3)
	sense.set_physics_process(false)
	sense.refresh()
	var bad_units := 0
	for e: Dictionary in sense.enemies:
		var n: Variant = e.get("node")
		if is_instance_valid(n) and int((n as Node).get(&"team")) == ENEMY:
			bad_units += 1
	var bad_structs := 0
	for s: Dictionary in sense.structures:
		var n: Variant = s.get("node")
		if is_instance_valid(n) and int((n as Node).get(&"team")) == ENEMY:
			bad_structs += 1
	_ok(bad_units == 0, "ChampionSense: %d allied-seat units listed as enemies" % bad_units)
	_ok(bad_structs == 0, "ChampionSense: %d allied-seat towers / keeps listed as danger" % bad_structs)
	sense.queue_free()
	Teams.configure(SIDES_2V2)
	await _frames(2)


# ---------------------------------------------------------------- M1

func _check_commander() -> void:
	Teams.configure(SIDES_2V2)
	var cmd := Commander.new()
	cmd.set(&"team", ALLY)
	cmd._enemy_team = ENEMY
	_ok(cmd._is_hostile_seat(ENEMY), "Commander (ALLY): its lane opponent is not hostile")
	_ok(cmd._is_hostile_seat(ENEMY_2), "Commander (ALLY): the other hostile seat is not sensed")
	_ok(not cmd._is_hostile_seat(PLAYER), "Commander (ALLY): the allied PLAYER seat counts as hostile")
	_ok(not cmd._is_hostile_seat(NEUTRAL), "Commander (ALLY): NEUTRAL counts as a hostile seat")
	cmd.free()


# ---------------------------------------------------------------- M3

func _check_flame_burst() -> void:
	Teams.configure(SIDES_2V2)
	var p := _spot + Vector3(0, 0, 16.0)
	var nodes: Array = []
	var clump: Array[Unit] = []
	for k in 3:
		var e := _dummy(ENEMY if k != 1 else ENEMY_2, p + Vector3(5.0, 0, -0.8 + 0.8 * k))
		clump.append(e)
		nodes.append(e)
	var ally := _dummy(ALLY, p + Vector3(5.6, 0, 0.0))
	nodes.append(ally)
	# Lone candidates on the far side, 4 m apart (no clump of their own): each one used to cost a full "units" pass.
	for k in 6:
		nodes.append(_dummy(ENEMY, p + Vector3(7.5, 0, 0).rotated(Vector3.UP, deg_to_rad(100.0 + 32.0 * k))))
	var a := _unit("pyre_adept", PLAYER, p)
	nodes.append(a)
	await _physics(2)
	var ab := NewUnits12.ability_of(a)
	_ok(ab != null, "Pyre Adept has no NewUnits12 ability")
	if ab:
		for e in clump:
			e.hp = e.max_hp
		ab.enemy_scans = 0
		var casts := ab.casts
		ab._try_flame_burst()
		_ok(ab.enemy_scans == 1, "Flame Burst made %d enemy scans (want 1)" % ab.enemy_scans)
		_ok(ab.casts == casts + 1, "Flame Burst did not fire on the clump")
		for e in clump:
			_ok(_lost(e) >= 30.0 - 0.01, "Flame Burst: a clumped enemy lost %.1f" % _lost(e))
		_ok(_lost(ally) == 0.0, "Flame Burst hit the allied seat (%.1f)" % _lost(ally))
	await _free(nodes)


# ---------------------------------------------------------------- M4

func _check_blood_tithe() -> void:
	Teams.configure(SIDES_2V2)
	var p := _spot + Vector3(0, 0, -16.0)
	var deacon := _unit("gloom_deacon", PLAYER, p)
	var ally := _dummy(ALLY, p + Vector3(2.0, 0, 0))
	var foe := _dummy(ENEMY, p + Vector3(-2.0, 0, 0))
	await _physics(2)
	ally.hp = ally.max_hp * 0.5
	foe.hp = foe.max_hp * 0.5
	var ab := CasterKit.ability_of(deacon)
	_ok(ab != null, "Gloom Deacon has no CasterAbility")
	if ab:
		_ok(ab.target_reason(&"blood_tithe", ally) == "",
				"Blood Tithe refuses the allied seat: %s" % ab.target_reason(&"blood_tithe", ally))
		_ok(ab.target_reason(&"blood_tithe", foe) != "", "Blood Tithe accepts an enemy")
	await _free([deacon, ally, foe])


# ---------------------------------------------------------------- lows

func _check_lows() -> void:
	Teams.configure(SIDES_2V2)
	var p := _spot + Vector3(8.0, 0, 0)
	var ally := _dummy(ALLY, p)
	var friend := _dummy(PLAYER, p + Vector3(1.0, 0, 0))
	var foe := _dummy(ENEMY_2, p + Vector3(-1.0, 0, 0))
	await _physics(1)
	# L2: only the ENEMY_2 dummy is a threat for PLAYER.
	_ok(T3Kit._enemies_near_count(PLAYER, p, 3.0) == 1,
			"T3Kit counts %d enemies near (want 1)" % T3Kit._enemies_near_count(PLAYER, p, 3.0))
	# L3: an ALLY rune never reveals the PLAYER's unit; it reveals the hostile one.
	CasterKit.register_rune(ALLY, p, 6.0, 1.0e9, null, null)
	_ok(not CasterKit.revealed_for(friend), "an allied Scrying Rune reveals a PLAYER unit")
	_ok(CasterKit.revealed_for(foe), "an allied Scrying Rune does not reveal an ENEMY_2 unit")
	CasterKit.reset()
	# L4: the Bulwark registry empties once the team's walls are gone.
	var wall := Node3D.new()
	CasterKit.register_bulwark(PLAYER, wall)
	wall.free()
	_ok(CasterKit.bulwarks_of(PLAYER).is_empty(), "a freed Bulwark still listed")
	_ok(CasterKit._bulwarks.is_empty(), "the Bulwark registry keeps an empty team list (early-out lost)")
	# L5: AICasters drops freed ids, keeps living ones.
	var aic := AICasters.new()
	var gone := Node.new()
	var gone_id := gone.get_instance_id()
	gone.free()
	aic._dive_at[gone_id] = 1.0
	aic._orders[gone_id] = [Vector3.ZERO, 1.0]
	aic._adopted[friend.get_instance_id()] = true
	var dropped := aic.prune_dead_ids()
	_ok(dropped == 2 and aic._adopted.has(friend.get_instance_id()),
			"AICasters.prune_dead_ids dropped %d (want 2) or lost a living id" % dropped)
	aic.free()
	# L11: the bound callable is what is_connected must check (the thief adopt guard).
	var cb := _on_probe.bind(friend)
	friend.damage_taken.connect(cb)
	_ok(friend.damage_taken.is_connected(_on_probe.bind(friend)), "a bound callable is not seen as connected")
	friend.damage_taken.disconnect(cb)
	await _free([ally, friend, foe])


func _on_probe(_amount: float, _attacker: Node3D, _who: Unit) -> void:
	pass
