extends SceneTree
## Task 11.C2: the 12 champion class skills (docs/design/skills-rework.md 4, "Done when" 11.C2), on stub
## champions (a Unit with the Champion fields ChampionAbilities reads + `class_id()`) in a small world with
## a navmesh and a FogOfWar (off except for the Slipstep "explored" check).
## - ability_ids() = 3 archetype + the class's 3 (none before the class); class unlocks 2 / 3 / 5 (and the
##   ChampionClass resource's unlock_levels when the champion has one); "Locked" for another class or a low
##   level; the 24-id AUTOCAST_ORDER of 4.3; one cast per 0.5 s check in that order.
## - Every class skill: level-1 data numbers, the numbers at its unlock level and at level 5, its trigger,
##   and the model play_cast(id) + ChampionVfx.play(id, caster, target) feedback.
## - PERF OK: 6 class champions at level 5 among 200 units, median try_autocast cost.
## - The real Champion (11.C1) when it has class_id(): ability ids = archetype + its class after level 2.
## Run:  godot --headless --path . -s tests/test_11_c2.gd --fixed-fps 60 --quit-after 9000

const TASK_ID := "11.C2"
const AB_PATH := "res://scripts/units/champion_abilities.gd"
const P := 0   # Unit.Team.PLAYER
const E := 1   # Unit.Team.ENEMY
const WAYFINDER: Array[StringName] = [&"flare_arrow", &"snare_line", &"trailblaze"]
const OATHWALL: Array[StringName] = [&"oath_of_iron", &"shield_bash", &"bulwark_stand"]
const COIN_CUTTER: Array[StringName] = [&"cutpurse", &"smoke_pouch", &"marked_for_coin"]
const MENDER: Array[StringName] = [&"mending_draught", &"soothing_circle", &"lifeline"]
const SPEAR: Array[StringName] = [&"lunge", &"hobbling_javelin", &"skewer"]
const SWORD_SHIELD: Array[StringName] = [&"riposte", &"second_wind", &"shield_throw"]
const TWO_HAND: Array[StringName] = [&"cleave", &"crushing_blow", &"whirlwind"]
const WIZARD: Array[StringName] = [&"arc_bolt", &"slipstep", &"starfall"]
const SPEC_ORDER: Array[StringName] = [&"smoke_pouch", &"slipstep", &"snare_line", &"trailblaze",
		&"lifeline", &"second_wind", &"bulwark_stand", &"oath_of_iron", &"riposte", &"shield_bash",
		&"hobbling_javelin", &"crushing_blow", &"whirlwind", &"starfall", &"skewer", &"marked_for_coin",
		&"lunge", &"cleave", &"shield_throw", &"arc_bolt", &"cutpurse", &"soothing_circle",
		&"mending_draught", &"flare_arrow"]
const PERF_MEDIAN_MS := 1.0   # one try_autocast check in a 200-unit crowd (step 9 alone: ~0.4 ms)
const PERF_FRAME_MS := 0.25   # all 6 champions' checks, averaged per frame (step 9 alone: ~0.09 ms)
const MODEL_SRC := "extends Node3D\nvar casts: Array = []\nfunc play_cast(id: StringName) -> void:\n\tcasts.append(id)\n"
const VFX_SRC := "extends Node3D\nvar calls: Array = []\nfunc play(id: StringName, caster: Node3D, target: Variant) -> void:\n\tcalls.append([id, caster, target])\n"
## A building stand-in (group "buildings"): records modifiers it is given (Crushing Blow must not give any).
const BUILDING_SRC := "extends Node3D\nvar team := 1\nvar hp := 500.0\nvar max_hp := 500.0\nvar armor := 0.0\nvar mods := 0\n" \
		+ "func is_alive() -> bool:\n\treturn hp > 0.0\n" \
		+ "func take_damage(amount: float, attacker: Node3D = null) -> void:\n\thp -= amount\n" \
		+ "func target_radius() -> float:\n\treturn 1.5\n" \
		+ "func add_modifier(id: StringName, stats: Dictionary) -> void:\n\tmods += 1\n"


## ChampionType stand-in.
class StubType extends Resource:
	var id: StringName = &""
	var ability_ids: Array[StringName] = []
	var growth_pct := 0.08
	var flee_pct := 0.35


## ChampionClass stand-in (11.C1 builds the real one): only the fields ChampionAbilities reads.
class StubClass extends Resource:
	var id: StringName = &""
	var ability_ids: Array[StringName] = []
	var unlock_levels: Array[int] = []


## The Champion fields ChampionAbilities reads, and the child it creates.
class BareChampion extends Unit:
	var champion_type: Resource = null
	var intent: StringName = &"idle"
	var intent_target: Node3D = null
	var purse := 0
	var abilities: Node = null

	func add_purse(n: int) -> void:
		purse += n

	func _ready() -> void:
		super._ready()
		add_to_group(&"champions")
		abilities = (load("res://scripts/units/champion_abilities.gd") as Script).new()
		abilities.name = "ChampionAbilities"
		abilities.set(&"autocast_enabled", false)
		add_child(abilities)   # no setup(): the node takes its parent

	func _on_death_finished() -> void:
		visible = false


## 11.C1's Champion API: class_id() (&"" = none).
class StubChampion extends BareChampion:
	var cls: StringName = &""

	func class_id() -> StringName:
		return cls


## A champion that only has the `champion_class` resource (no class_id()).
class ResChampion extends BareChampion:
	var champion_class: Resource = null


var world: Node3D
var fog: FogOfWar
var vfx: Node3D
var errors: Array[String] = []
var notes: Array[String] = []
var finished := false
var spawned: Array = []
var cast_log: Array = []
var hit_log: Array = []
var stages := 0
const STAGES := 12


func _initialize() -> void:
	world = Node3D.new()
	world.name = "TestWorld"
	root.add_child(world)
	current_scene = world
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200.0, 1.0, 200.0)
	shape.shape = box
	ground.add_child(shape)
	ground.position = Vector3(0.0, -0.5, 0.0)
	world.add_child(ground)
	var nav := NavigationMesh.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200.0, 200.0)
	nav.create_from_mesh(plane)
	var region := NavigationRegion3D.new()
	region.navigation_mesh = nav
	world.add_child(region)
	fog = FogOfWar.new()
	world.add_child(fog)
	fog.enabled = false
	vfx = Node3D.new()
	vfx.set_script(_script(VFX_SRC))
	vfx.add_to_group(&"champion_vfx")
	world.add_child(vfx)
	_run()


func _process(_delta: float) -> bool:
	return finished


func _run() -> void:
	await _wait(5)
	if not ResourceLoader.exists(AB_PATH):
		_fail("missing " + AB_PATH)
		return
	await _test_ids()
	await _clear()
	await _test_lunge()
	await _clear()
	await _test_javelin_skewer()
	await _clear()
	await _test_riposte()
	await _clear()
	await _test_second_wind_shield_throw()
	await _clear()
	await _test_cleave()
	await _clear()
	await _test_crushing_blow_whirlwind()
	await _clear()
	await _test_arc_bolt_slipstep()
	await _clear()
	await _test_starfall()
	await _clear()
	await _test_order()
	await _clear()
	await _test_real_champion()
	await _clear()
	await _test_perf()
	await _clear()
	_eq(stages, STAGES, "every stage ran to its end")
	for s in notes:
		print("NOTE %s" % s)
	if errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(errors)])
	finished = true


func _fail(msg: String) -> void:
	errors.append(msg)
	print("FAIL %s: %s" % [TASK_ID, msg])
	finished = true


# ---------------------------------------------------------------- ids, unlocks, order

func _test_ids() -> void:
	var A := Vector3(-40.0, 0.0, -40.0)
	var w := _champ(&"wayfinder", WAYFINDER, &"", A, 1)
	var ab = w.abilities
	var foe := _unit(E, A + Vector3(3.0, 0.0, 0.0))
	await _wait(3)
	_eq(str(ab.ability_ids()), str(WAYFINDER), "no class: the 3 archetype abilities")
	_eq(ab.class_id(), &"", "class_id() empty before the choice")
	_eq(ab.class_skill_ids().size(), 0, "no class skills before the choice")
	w.level = 2
	_eq(str(ab.ability_ids()), str(WAYFINDER), "level 2 without a class: still 3")
	_eq(ab.cast(&"lunge", foe), "Locked", "no class: Lunge is Locked")
	w.cls = &"spear"
	w.level = 5
	_eq(str(ab.ability_ids()), str(WAYFINDER + SPEAR),
			"a Spear Wayfinder at level 5 owns exactly Flare, Snare, Trailblaze, Lunge, Hobbling Javelin, Skewer")
	_eq(str(ab.archetype_ability_ids()), str(WAYFINDER), "archetype_ability_ids()")
	_eq(str(ab.class_skill_ids()), str(SPEAR), "class_skill_ids()")
	var want_unlocked := {1: [&"flare_arrow", &"snare_line"],
			2: [&"flare_arrow", &"snare_line", &"lunge"],
			3: [&"flare_arrow", &"snare_line", &"lunge", &"hobbling_javelin"],
			4: [&"flare_arrow", &"snare_line", &"trailblaze", &"lunge", &"hobbling_javelin"],
			5: [&"flare_arrow", &"snare_line", &"trailblaze", &"lunge", &"hobbling_javelin", &"skewer"],
			6: [&"flare_arrow", &"snare_line", &"trailblaze", &"lunge", &"hobbling_javelin", &"skewer"]}
	for lvl: int in want_unlocked:
		w.level = lvl
		var got: Array = []
		for id: StringName in ab.ability_ids():
			if ab.is_unlocked(id):
				got.append(id)
		_eq(str(got), str(want_unlocked[lvl]), "unlocked at level %d" % lvl)
		var n_class := 0
		for id: StringName in SPEAR:
			if ab.is_unlocked(id):
				n_class += 1
		_eq(ab.unlocked_class_skill_count(), n_class, "unlocked_class_skill_count at level %d" % lvl)
	# Reasons: below its level, another class, order Dead / Cannot act before Locked.
	w.level = 2
	_eq(ab.cast(&"hobbling_javelin", foe), "Locked", "Hobbling Javelin below level 3: Locked")
	_eq(ab.cast(&"skewer", foe), "Locked", "Skewer below level 5: Locked")
	w.level = 5
	for id: StringName in SWORD_SHIELD + TWO_HAND + WIZARD:
		_eq(ab.cast(id, foe), "Locked", "%s of another class: Locked" % id)
	w.level = 2
	w.apply_status(&"frozen", 0.5)
	_eq(ab.cast(&"skewer", foe), "Cannot act", "Cannot act comes before Locked (class skill)")
	await _wait(40)
	# Static data: 24 abilities, 12 class skills with their class and level, the 4.3 order.
	_eq(ChampionAbilities.ABILITIES.size(), 24, "ABILITIES has the 24 ids")
	_eq(str(ChampionAbilities.AUTOCAST_ORDER), str(SPEC_ORDER), "AUTOCAST_ORDER = skills-rework.md 4.3")
	for id: StringName in ChampionAbilities.ABILITIES:
		_check(ChampionAbilities.AUTOCAST_ORDER.has(id), "%s is in AUTOCAST_ORDER" % id)
	var classes := {&"spear": SPEAR, &"sword_shield": SWORD_SHIELD, &"two_hand": TWO_HAND, &"wizard": WIZARD}
	for cid: StringName in classes:
		var ids: Array[StringName] = classes[cid]
		_eq(str(ChampionAbilities.class_skills_of(cid)), str(ids), "class_skills_of(%s)" % cid)
		for i in 3:
			_eq(ChampionAbilities.skill_class(ids[i]), cid, "%s belongs to %s" % [ids[i], cid])
			_eq(ChampionAbilities.unlock_level(ids[i]), [2, 3, 5][i], "%s unlocks at level %d" % [ids[i], [2, 3, 5][i]])
	_check(not ChampionAbilities.is_class_skill(&"flare_arrow"), "archetype abilities are not class skills")
	_eq(ChampionAbilities.ability_name(&"flare_arrow"), "Signal Flare", "flare_arrow is displayed Signal Flare")
	var cds := {&"lunge": 14.0, &"hobbling_javelin": 16.0, &"skewer": 25.0, &"riposte": 22.0,
			&"second_wind": 45.0, &"shield_throw": 20.0, &"cleave": 10.0, &"crushing_blow": 20.0,
			&"whirlwind": 30.0, &"arc_bolt": 10.0, &"slipstep": 22.0, &"starfall": 35.0}
	for id: StringName in cds:
		_near(float(ChampionAbilities.ability_data(id)["cooldown"]), cds[id], "%s cooldown" % id)
	# A champion that only has the champion_class resource: its unlock_levels win.
	var t := StubType.new()
	t.id = &"oathwall"
	t.ability_ids = OATHWALL
	var rc := ResChampion.new()
	rc.champion_type = t
	rc.team = P
	rc.max_hp = 300.0
	rc.attack_damage = 0.0
	rc.aggro_range = 0.0
	var cc := StubClass.new()
	cc.id = &"two_hand"
	cc.ability_ids = TWO_HAND
	cc.unlock_levels = [2, 4, 6]
	rc.champion_class = cc
	world.add_child(rc)
	rc.global_position = A + Vector3(0.0, 0.0, 6.0)
	spawned.append(rc)
	await _wait(2)
	var rab = rc.abilities
	_eq(rab.class_id(), &"two_hand", "class id read from champion_class.id")
	_eq(str(rab.ability_ids()), str(OATHWALL + TWO_HAND), "ids with a champion_class resource")
	rc.level = 4
	_check(rab.is_unlocked(&"crushing_blow") and not rab.is_unlocked(&"whirlwind"),
			"champion_class.unlock_levels [2, 4, 6]: Crushing Blow at 4, Whirlwind not yet")
	rc.level = 3
	_check(not rab.is_unlocked(&"crushing_blow"), "champion_class.unlock_levels: Crushing Blow locked at 3")
	rc.level = 6
	_check(rab.is_unlocked(&"whirlwind"), "champion_class.unlock_levels: Whirlwind at 6")
	stages += 1


# ---------------------------------------------------------------- Spear: Lunge

func _test_lunge() -> void:
	var S := Vector3(-40.0, 0.0, 0.0)
	var sp := _champ(&"coin_cutter", COIN_CUTTER, &"spear", S, 2)
	sp.attack_range = 2.4
	var ab = sp.abilities
	var nb := _typed(&"nightbolt", E, S + Vector3(5.0, 0.0, 0.0))
	var hero := _unit(E, S + Vector3(0.0, 0.0, 5.0))
	hero.add_to_group(&"enemy_heroes")
	var far := _unit(E, S + Vector3(-8.0, 0.0, 0.0))
	await _wait(10)
	_near(float(ChampionAbilities.ability_data(&"lunge")["amount"]), 25.0, "Lunge level-1 damage 25")
	_eq(ab.cast(&"lunge", far), "Invalid target", "Lunge beyond 6 m")
	var hp0: float = nb.hp
	_eq(ab.cast(&"lunge", nb), "", "Lunge on a Nightbolt 5 m away")
	_fx(sp, &"lunge", nb, "Lunge")
	var d := _flat(sp.global_position, nb.global_position)
	_check(d >= 0.8 and d <= 1.3, "Lunge lands next to the Nightbolt (%.2f m)" % d)
	_near(hp0 - nb.hp, 27.0, "Lunge 25 x 1.08 at level 2")
	_near(nb.status_time_left(&"dazed"), 0.5, "Lunge dazes 0.5 s")
	_near(ab.cooldown_left(&"lunge"), 14.0, "Lunge cooldown 14 s")
	_check(_hit_logged(&"lunge", nb), "skill_hit(lunge, nightbolt)")
	await _calm([sp, nb, hero, far])
	sp.global_position = S
	await _wait(2)
	ab.reset_cooldowns()
	_eq(ab.cast(&"lunge", hero), "", "Lunge on a hero")
	_near(hero.status_time_left(&"dazed"), 0.25, "Lunge dazes a hero 0.25 s")
	await _calm([sp, nb, hero, far])
	# Level 5: 33.
	sp.level = 5
	sp.global_position = S
	var f5 := _unit(E, S + Vector3(0.0, 0.0, -4.0))
	await _wait(2)
	ab.reset_cooldowns()
	hp0 = f5.hp
	_eq(ab.cast(&"lunge", f5), "", "Lunge at level 5")
	_near(hp0 - f5.hp, 33.0, "Lunge 25 x 1.32 at level 5")
	await _calm([sp, nb, hero, far, f5])
	for u in [nb, hero, far, f5]:
		u.queue_free()
	await _wait(2)
	# Trigger: fighting + a preferred foe 3-6 m away; not a healthy melee foe; not near a known tower; hunt.
	sp.level = 2
	sp.global_position = S
	var bolt := _typed(&"nightbolt", E, S + Vector3(5.0, 0.0, 0.0))
	await _wait(3)
	ab.reset_cooldowns()
	sp.intent = &"idle"
	_check(ab.try_autocast() != &"lunge", "idle: no Lunge")
	sp.intent = &"fighting"
	_eq(ab.try_autocast(), &"lunge", "autocast Lunge on a ranged foe 5 m away while fighting")
	await _calm([sp, bolt])
	bolt.queue_free()
	sp.global_position = S
	var shade := _typed(&"shade", E, S + Vector3(0.0, 0.0, 5.0))
	await _wait(3)
	ab.reset_cooldowns()
	_eq(ab.try_autocast(), &"", "a healthy melee foe: no Lunge")
	shade.hp = shade.max_hp * 0.3
	var tower := Building.new()
	tower.building_type = BuildingType.find(&"shadow_tower")
	tower.team = E
	world.add_child(tower)
	tower.global_position = S + Vector3(8.0, 0.0, 10.0)   # 5.8 m from the shade
	spawned.append(tower)
	await _wait(2)
	_check(tower.is_constructed(), "test tower constructed")
	_eq(ab.try_autocast(), &"", "a foe within 11 m of a known enemy tower: no Lunge")
	tower.queue_free()
	await _wait(2)
	_eq(ab.try_autocast(), &"lunge", "autocast Lunge on a foe under 40 % HP")
	await _calm([sp, shade])
	sp.global_position = S
	var prey := _unit(E, S + Vector3(-4.0, 0.0, 0.0))
	await _wait(3)
	ab.reset_cooldowns()
	sp.intent = &"hunting_bounty"
	sp.intent_target = prey
	shade.queue_free()
	await _wait(1)
	prey.velocity = Vector3(3.0, 0.0, 0.0)   # toward the champion
	_eq(ab.try_autocast(), &"", "hunt target coming closer: no Lunge")
	prey.velocity = Vector3(-3.0, 0.0, 0.0)
	_eq(ab.try_autocast(), &"lunge", "autocast Lunge: hunt target within 6 m moving away")
	sp.intent = &"idle"
	sp.intent_target = null
	stages += 1


# ---------------------------------------------------------------- Spear: Hobbling Javelin, Skewer

func _test_javelin_skewer() -> void:
	var J := Vector3(-40.0, 0.0, 30.0)
	var sp := _champ(&"coin_cutter", COIN_CUTTER, &"spear", J, 3)
	var ab = sp.abilities
	var far := _unit(E, J + Vector3(11.5, 0.0, 0.0))
	var s := _typed(&"shade", E, J + Vector3(10.0, 0.0, 0.0))
	await _wait(5)
	_eq(ab.cast(&"hobbling_javelin", far), "Invalid target", "Hobbling Javelin beyond 10 m")
	var hp0: float = s.hp
	var speed0: float = s.get_stat(&"move_speed")
	_eq(ab.cast(&"hobbling_javelin", s), "", "Hobbling Javelin at 10 m")
	_fx(sp, &"hobbling_javelin", s, "Hobbling Javelin")
	_near(s.hp, hp0, "the javelin is still flying")
	var landed := await _until_hurt(s, hp0, 90)
	_check(landed, "the javelin lands")
	_near(hp0 - s.hp, 29.0, "Hobbling Javelin 25 x 1.16 at level 3")
	_check(s.status_time_left(&"smoulder") > 2.85 and s.status_time_left(&"smoulder") <= 3.0,
			"hobbled (smoulder) 3 s (%.2f)" % s.status_time_left(&"smoulder"))
	_near(s.get_stat(&"move_speed"), speed0 - 1.5, "hobbled: move speed -1.5")
	_check(_hit_logged(&"hobbling_javelin", s), "skill_hit(hobbling_javelin)")
	sp.level = 5
	ab.reset_cooldowns()
	var s5 := _unit(E, J + Vector3(0.0, 0.0, 8.0))
	await _wait(2)
	hp0 = s5.hp
	_eq(ab.cast(&"hobbling_javelin", s5), "", "Hobbling Javelin at level 5")
	await _until_hurt(s5, hp0, 90)
	_near(hp0 - s5.hp, 33.0, "Hobbling Javelin 25 x 1.32 at level 5")
	await _calm([sp, far, s, s5])
	for u in [far, s, s5]:
		u.queue_free()
	await _wait(2)
	# Trigger: under 60 % HP and moving away (from it, or from an own unit fighting it).
	sp.level = 3
	var run := _unit(E, J + Vector3(7.0, 0.0, 0.0))
	var ally := _unit(P, J + Vector3(9.0, 0.0, 0.0))
	await _wait(3)
	ab.reset_cooldowns()
	run.hp = 50.0
	run.velocity = Vector3(-3.0, 0.0, 0.0)
	_eq(ab.try_autocast(), &"", "a hurt foe coming closer: no javelin")
	ally.attack_target = run
	run.velocity = Vector3(-3.0, 0.0, 0.0)
	_eq(ab.try_autocast(), &"hobbling_javelin", "autocast Hobbling Javelin: a hurt foe fleeing an own unit")
	await _wait(40)
	ally.attack_target = null
	var run2 := _unit(E, J + Vector3(0.0, 0.0, -7.0))
	await _wait(2)
	ab.reset_cooldowns()
	run2.hp = 90.0
	run2.velocity = Vector3(0.0, 0.0, -3.0)
	_eq(ab.try_autocast(), &"", "a foe above 60 % moving away: no javelin")
	run2.hp = 55.0
	run2.velocity = Vector3(0.0, 0.0, -3.0)
	_eq(ab.try_autocast(), &"hobbling_javelin", "autocast Hobbling Javelin: a foe under 60 % moving away")
	await _wait(40)
	await _calm([sp, run, ally, run2])
	for u in [run, ally, run2]:
		u.queue_free()
	await _wait(2)
	# Skewer (level 5): 3 Shades in a 5 m line, not a 4th 1.5 m off it, not a 5th 7 m away.
	sp.level = 5
	sp.global_position = J
	await _wait(2)
	var a := _typed(&"shade", E, J + Vector3(1.5, 0.0, 0.0))
	var b := _typed(&"shade", E, J + Vector3(3.0, 0.0, 0.0))
	var c := _typed(&"shade", E, J + Vector3(4.5, 0.0, 0.0))
	var off := _typed(&"shade", E, J + Vector3(3.0, 0.0, 1.5))
	var beyond := _typed(&"shade", E, J + Vector3(7.0, 0.0, 0.0))
	await _wait(5)
	_near(float(ChampionAbilities.ability_data(&"skewer")["amount"]), 40.0, "Skewer level-1 damage 40")
	ab.reset_cooldowns()
	_eq(ab.try_autocast(), &"skewer", "autocast Skewer: 3 enemies in the line")
	for u in [a, b, c]:
		_near(u.max_hp - u.hp, 52.8, "Skewer 40 x 1.32 at level 5 on each Shade in the line")
	_near(off.max_hp - off.hp, 0.0, "Skewer misses a Shade 1.5 m off the line")
	_near(beyond.max_hp - beyond.hp, 0.0, "Skewer misses a Shade 7 m away")
	_fx(sp, &"skewer", J + Vector3(0.45 + 5.0, 0.0, 0.0), "Skewer (the line's far end)")
	await _calm([sp, a, b, c, off, beyond])
	ab.reset_cooldowns()
	c.queue_free()
	await _wait(2)
	_check(ab.try_autocast() != &"skewer", "2 enemies in the line: no Skewer")
	ab.reset_cooldowns()
	_eq(ab.cast(&"skewer", beyond), "Invalid target", "Skewer aim beyond 5 m")
	stages += 1


# ---------------------------------------------------------------- Sword and Shield: Riposte

func _test_riposte() -> void:
	var R := Vector3(-5.0, 0.0, -40.0)
	var ch := _champ(&"mender", MENDER, &"sword_shield", R, 2)
	ch.attack_range = 1.8
	var ab = ch.abilities
	var m1 := _typed(&"shade", E, R + Vector3(1.2, 0.0, 0.0))
	var m2 := _typed(&"shade", E, R + Vector3(-1.2, 0.0, 0.0))
	var rb := _typed(&"nightbolt", E, R + Vector3(0.0, 0.0, 6.0))
	await _wait(5)
	var all := [ch, m1, m2, rb]
	_eq(ab.cast(&"riposte"), "", "Riposte")
	_fx(ch, &"riposte", ch, "Riposte")
	_near(ab.riposte_time_left(), 4.0, "Riposte lasts 4 s")
	var hp0: float = m1.hp
	ch.take_damage(5.0, m1)
	_near(hp0 - m1.hp, 10.8, "a melee hit takes 10 x 1.08 back at level 2")
	_check(_hit_logged(&"riposte", m1), "skill_hit(riposte, attacker)")
	hp0 = rb.hp
	ch.take_damage(5.0, rb)
	_near(hp0 - rb.hp, 0.0, "a ranged hit takes nothing back")
	await _calm(all)
	# Two riposting champions: a counter never answers a counter.
	var foe_ch := _champ(&"mender", MENDER, &"sword_shield", R + Vector3(0.0, 0.0, -1.2), 2, E)
	foe_ch.attack_range = 1.8
	await _wait(3)
	_eq(foe_ch.abilities.cast(&"riposte"), "", "enemy champion Riposte")
	var mine: float = ch.hp
	var theirs: float = foe_ch.hp
	ch.take_damage(5.0, foe_ch)
	_near(theirs - foe_ch.hp, 10.8, "the enemy champion takes the counter")
	_near(mine - ch.hp, 5.0, "no counter to the counter")
	all.append(foe_ch)
	await _calm(all)
	await _wait(240)   # > 4 s after the cast
	_near(ab.riposte_time_left(), 0.0, "Riposte over after 4 s")
	hp0 = m1.hp
	ch.take_damage(5.0, m1)
	_near(hp0 - m1.hp, 0.0, "no counter after 4 s")
	await _calm(all)
	# Level 5: 13.2.
	ch.level = 5
	ab.reset_cooldowns()
	ab.cast(&"riposte")
	hp0 = m2.hp
	ch.take_damage(5.0, m2)
	_near(hp0 - m2.hp, 13.2, "Riposte 10 x 1.32 at level 5")
	await _calm(all)
	# Trigger: 2+ melee enemies attacking it.
	ab.reset_cooldowns()
	foe_ch.queue_free()
	await _wait(2)
	m1.attack_target = ch
	_eq(ab.try_autocast(), &"", "one melee enemy on it: no Riposte")
	m2.attack_target = ch
	rb.attack_target = ch
	_eq(ab.try_autocast(), &"riposte", "autocast Riposte: 2 melee enemies attack it")
	await _calm(all)
	stages += 1


# ---------------------------------------------------------------- Sword and Shield: Second Wind, Shield Throw

func _test_second_wind_shield_throw() -> void:
	var T := Vector3(-5.0, 0.0, -5.0)
	var ch := _champ(&"mender", MENDER, &"sword_shield", T, 3)
	var ab = ch.abilities
	await _wait(3)
	_near(float(ChampionAbilities.ability_data(&"second_wind")["heal_pct"]), 0.2, "Second Wind 20 % of max HP")
	ch.hp = 100.0
	_eq(ab.cast(&"second_wind"), "", "Second Wind")
	_fx(ch, &"second_wind", ch, "Second Wind")
	await _wait(121)
	_near(ch.hp, 130.0, "Second Wind: +30 after 2 s", 0.2)
	await _wait(126)
	_near(ch.hp, 160.0, "Second Wind heals 20 % of 300 over 4 s", 0.2)
	var ticks := 0
	for h: Array in hit_log:
		if h[0] == &"second_wind":
			ticks += 1
	_eq(ticks, 8, "Second Wind: 8 ticks")
	ch.level = 5
	ab.reset_cooldowns()
	ch.hp = 100.0
	ab.cast(&"second_wind")
	await _wait(247)
	_near(ch.hp, 160.0, "Second Wind at level 5: still 20 % of max HP", 0.2)
	# Trigger: HP under 50 % and hit in the last 2 s.
	var foe := _unit(E, T + Vector3(0.0, 0.0, 12.0))
	await _wait(2)
	ab.reset_cooldowns()
	ch.hp = 120.0   # 40 %: under 50 %, above Lifeline's 35 %
	await _wait(130)
	_check(ab.try_autocast() != &"second_wind", "low HP but not hit for 2 s: no Second Wind")
	ab.reset_cooldowns()
	ch.hp = 120.0
	ch.take_damage(1.0, foe)
	await _calm([ch, foe])
	_eq(ab.try_autocast(), &"second_wind", "autocast Second Wind: under 50 % and just hit")
	await _wait(250)
	foe.queue_free()
	# Shield Throw (level 5): 30 / 20 / 10 over 3 targets, bounces within 4 m.
	ch.hp = ch.max_hp
	var a := _unit(E, T + Vector3(6.0, 0.0, 0.0))
	var b := _unit(E, T + Vector3(6.0, 0.0, 3.0))
	var c := _unit(E, T + Vector3(6.0, 0.0, 6.0))
	var d := _unit(E, T + Vector3(6.0, 0.0, 11.0))
	var far := _unit(E, T + Vector3(10.0, 0.0, 0.0))
	await _wait(3)
	var data := ChampionAbilities.ability_data(&"shield_throw")
	_eq(str(data["bounces"]), str([20.0, 10.0]), "Shield Throw level-1 bounces 20 / 10")
	_near(float(data["amount"]), 30.0, "Shield Throw level-1 damage 30")
	ab.reset_cooldowns()
	_eq(ab.cast(&"shield_throw", far), "Invalid target", "Shield Throw beyond 8 m")
	_eq(ab.cast(&"shield_throw", a), "", "Shield Throw")
	_fx(ch, &"shield_throw", a, "Shield Throw")
	_near(100.0 - a.hp, 39.6, "Shield Throw 30 x 1.32 on the target")
	_near(100.0 - b.hp, 26.4, "first bounce 20 x 1.32")
	_near(100.0 - c.hp, 13.2, "second bounce 10 x 1.32")
	_near(100.0 - d.hp, 0.0, "no third bounce / nothing beyond 4 m")
	await _calm([ch, a, b, c, d, far])
	for u in [b, c, d, far]:
		u.queue_free()
	# Trigger: an enemy ranged unit within 8 m hitting an own unit; or its target 3-8 m away out of reach.
	var nb := _typed(&"nightbolt", E, T + Vector3(0.0, 0.0, -6.0))
	var ally := _unit(P, T + Vector3(0.0, 0.0, -9.0))
	await _wait(3)
	ab.reset_cooldowns()
	ch.attack_target = null
	_eq(ab.try_autocast(), &"", "nobody hit: no Shield Throw")
	nb.attack_target = ally
	var hp_nb: float = nb.hp
	_eq(ab.try_autocast(), &"shield_throw", "autocast Shield Throw on a ranged foe hitting an ally")
	_check(nb.hp < hp_nb, "the ranged foe was hit")
	await _calm([ch, a, nb, ally])
	ab.reset_cooldowns()
	ch.attack_target = a   # 6 m away, out of its 1.6 m reach
	_eq(ab.try_autocast(), &"shield_throw", "autocast Shield Throw on its target 3-8 m away")
	await _calm([ch, a, nb, ally])
	stages += 1


# ---------------------------------------------------------------- Two-Hand: Cleave

func _test_cleave() -> void:
	var C := Vector3(-5.0, 0.0, 30.0)
	var ch := _champ(&"coin_cutter", COIN_CUTTER, &"two_hand", C, 2)
	ch.attack_damage = 24.0
	ch.attack_range = 2.1
	ch.attack_cooldown = 1.55
	var ab = ch.abilities
	var t := _unit(E, C + Vector3(2.0, 0.0, 0.0), 200.0)
	var n1 := _unit(E, C + Vector3(3.5, 0.0, 0.0), 200.0)
	var n2 := _unit(E, C + Vector3(2.0, 0.0, 2.0), 200.0)
	var out := _unit(E, C + Vector3(5.5, 0.0, 0.0), 200.0)
	await _wait(5)
	_eq(ab.cast(&"cleave"), "", "Cleave arms")
	_check(ab.is_cleave_armed(), "Cleave armed")
	_check(not _vfx_has(&"cleave"), "no Cleave VFX when it arms")
	ch.command_attack(t)
	var hit := await _until_hurt(t, 200.0, 60)
	_check(hit, "the empowered attack lands")
	_near(200.0 - t.hp, 24.0, "the target takes the attack")
	_near(200.0 - n1.hp, 24.0, "Cleave hits a Shade 1.5 m from the target for the full 24")
	_near(200.0 - n2.hp, 24.0, "Cleave hits a Shade 2 m from the target for the full 24")
	_near(200.0 - out.hp, 0.0, "Cleave misses a Shade 3.5 m from the target")
	_check(not ab.is_cleave_armed(), "Cleave used up")
	_fx(ch, &"cleave", t, "Cleave (on the hit)")
	var n1_hp: float = n1.hp
	await _until_hurt(t, t.hp, 120)
	_near(n1.hp, n1_hp, "the attack after is a normal one")
	await _calm([ch, t, n1, n2, out])
	# Expires after 3 s.
	ab.reset_cooldowns()
	ab.cast(&"cleave")
	await _wait(185)
	_check(not ab.is_cleave_armed(), "Cleave expires after 3 s")
	# Level 5: the splash follows the attack's damage (the champion's grown attack_damage).
	ch.level = 5
	ch.attack_damage = 31.68
	ab.reset_cooldowns()
	ab.cast(&"cleave")
	var t_hp: float = t.hp
	n1_hp = n1.hp
	ch.command_attack(t)
	await _until_hurt(t, t_hp, 120)
	_near(n1_hp - n1.hp, 31.68, "level 5: Cleave splashes the full (grown) attack damage")
	await _calm([ch, t, n1, n2, out])
	# Trigger: its target has 2+ other enemies within 2.5 m (level 2: only Cleave of its class skills;
	# the Shades walked up to it while fighting back: put them back).
	ch.level = 2
	for pair: Array in [[t, Vector3(2.0, 0.0, 0.0)], [n1, Vector3(3.5, 0.0, 0.0)], [n2, Vector3(2.0, 0.0, 2.0)],
			[out, Vector3(5.5, 0.0, 0.0)], [ch, Vector3.ZERO]]:
		(pair[0] as Node3D).global_position = C + pair[1]
	await _calm([ch, t, n1, n2, out])
	ab.reset_cooldowns()
	ch.attack_target = t
	_eq(ab.try_autocast(), &"cleave", "autocast Cleave: 2 enemies next to its target")
	ab.reset_cooldowns()
	ch.attack_target = t
	n2.queue_free()
	await _wait(2)
	ch.attack_target = t
	_check(ab.try_autocast() != &"cleave", "1 enemy next to its target: no Cleave")
	await _calm([ch, t, n1, out])
	stages += 1


# ---------------------------------------------------------------- Two-Hand: Crushing Blow, Whirlwind

func _test_crushing_blow_whirlwind() -> void:
	var B := Vector3(30.0, 0.0, -40.0)
	var ch := _champ(&"coin_cutter", COIN_CUTTER, &"two_hand", B, 3)
	ch.attack_range = 2.1
	var ab = ch.abilities
	var plain := _unit(E, B + Vector3(0.0, 0.0, 2.0))
	var rs := _typed(&"rimeshield", E, B + Vector3(2.0, 0.0, 0.0))
	var far := _unit(E, B + Vector3(0.0, 0.0, -4.0))
	var bld := Node3D.new()
	bld.set_script(_script(BUILDING_SRC))
	bld.add_to_group(&"buildings")
	world.add_child(bld)
	bld.global_position = B + Vector3(-3.0, 0.0, 0.0)
	spawned.append(bld)
	await _wait(5)
	_near(float(ChampionAbilities.ability_data(&"crushing_blow")["amount"]), 30.0, "Crushing Blow level-1 damage 30")
	_eq(ab.cast(&"crushing_blow", far), "Invalid target", "Crushing Blow needs melee reach")
	_eq(ab.cast(&"crushing_blow", plain), "", "Crushing Blow")
	_fx(ch, &"crushing_blow", plain, "Crushing Blow")
	_near(100.0 - plain.hp, 34.8, "Crushing Blow 30 x 1.16 at level 3")
	_near(plain.get_stat(&"armor"), -20.0, "the unit loses 20 armor")
	_check(plain.has_modifier(&"ability:crush"), "modifier ability:crush")
	_near(ChampionAbilities.crush_time_left(plain), 6.0, "for 6 s")
	await _calm([ch, plain, rs, far])
	ab.reset_cooldowns()
	var rs_armor: float = rs.get_stat(&"armor")
	_near(rs_armor, 15.0, "a Rimeshield has 15 armor")
	_eq(ab.cast(&"crushing_blow", rs), "", "Crushing Blow on a Rimeshield")
	_near(rs.get_stat(&"armor"), -5.0, "Rimeshield armor 15 - 20")
	var hp0: float = rs.hp
	rs.take_damage(100.0)
	_near(hp0 - rs.hp, 105.0, "the crushed Rimeshield takes 105 from a 100 hit")
	await _calm([ch, plain, rs, far])
	ab.reset_cooldowns()
	_eq(ab.cast(&"crushing_blow", bld), "", "Crushing Blow on a building")
	_near(500.0 - float(bld.get(&"hp")), 34.8, "the building takes the damage")
	_eq(int(bld.get(&"mods")), 0, "a building gets no armor break")
	_check(bld.get_node_or_null(^"AbilityCrush") == null, "no crush mark on a building")
	await _wait(300)   # 6 s after the first blow
	await _wait(70)
	_near(plain.get_stat(&"armor"), 0.0, "the armor comes back after 6 s")
	_check(not plain.has_modifier(&"ability:crush"), "ability:crush removed")
	_near(rs.get_stat(&"armor"), 15.0, "the Rimeshield's armor comes back")
	_check(plain.get_node_or_null(^"AbilityCrush") == null, "the crush mark is gone")
	ch.level = 5
	ab.reset_cooldowns()
	hp0 = plain.hp
	ab.cast(&"crushing_blow", plain)
	_near(hp0 - plain.hp, 39.6, "Crushing Blow 30 x 1.32 at level 5")
	await _calm([ch, plain, rs, far])
	# Trigger: its target has armor >= 10, or is a hero, or costs >= 200.
	ch.level = 3
	ab.reset_cooldowns()
	var shade := _typed(&"shade", E, B + Vector3(-1.5, 0.0, 1.5))   # one neighbour only: no Cleave either
	await _wait(3)
	ch.attack_target = shade
	_eq(ab.try_autocast(), &"", "target without armor, not a hero, cost 80: no Crushing Blow")
	ch.attack_target = rs
	_eq(ab.try_autocast(), &"crushing_blow", "autocast Crushing Blow on a Rimeshield (armor 15)")
	ab.reset_cooldowns()
	plain.add_to_group(&"enemy_heroes")
	ch.attack_target = plain
	_eq(ab.try_autocast(), &"crushing_blow", "autocast Crushing Blow on a hero")
	await _calm([ch, plain, rs, far, shade])
	for u in [plain, rs, far, shade, bld]:
		u.queue_free()
	await _wait(3)
	# Whirlwind (level 5): 4 ticks of 12 x 1.32 to every enemy within 3 m.
	ch.level = 5
	ab.reset_cooldowns()
	var a := _unit(E, B + Vector3(1.5, 0.0, 0.0))
	var b := _unit(E, B + Vector3(0.0, 0.0, 2.5))
	var c := _unit(E, B + Vector3(-2.0, 0.0, -1.0))
	var o := _unit(E, B + Vector3(4.0, 0.0, 0.0))
	await _wait(3)
	_near(float(ChampionAbilities.ability_data(&"whirlwind")["amount"]), 12.0, "Whirlwind level-1 tick 12 (48 in 2 s)")
	hit_log.clear()
	_eq(ab.try_autocast(), &"whirlwind", "autocast Whirlwind: 3 enemies within 3 m")
	_fx(ch, &"whirlwind", ch, "Whirlwind")
	_near(ab.whirlwind_time_left(), 2.0, "spins 2 s")
	_near(100.0 - a.hp, 15.84, "first tick at once")
	await _wait(125)
	for u in [a, b, c]:
		_near(100.0 - u.hp, 63.36, "Whirlwind 48 x 1.32 over 2 s to each enemy within 3 m")
	_near(100.0 - o.hp, 0.0, "Whirlwind misses an enemy 4 m away")
	var n := 0
	for h: Array in hit_log:
		if h[0] == &"whirlwind" and h[1] == a:
			n += 1
	_eq(n, 4, "4 Whirlwind ticks")
	_near(ab.whirlwind_time_left(), 0.0, "spin over")
	await _calm([ch, a, b, c, o])
	ab.reset_cooldowns()
	c.queue_free()
	await _wait(2)
	_eq(ab.try_autocast(), &"", "2 enemies within 3 m: no Whirlwind")
	stages += 1


# ---------------------------------------------------------------- Wizard: Arc Bolt, Slipstep

func _test_arc_bolt_slipstep() -> void:
	var W := Vector3(30.0, 0.0, -5.0)
	var ch := _champ(&"wayfinder", WAYFINDER, &"wizard", W, 2)
	ch.attack_range = 7.5
	var ab = ch.abilities
	var s := _unit(E, W + Vector3(12.0, 0.0, 0.0))
	var far := _unit(E, W + Vector3(13.5, 0.0, 0.0))
	await _wait(3)
	_near(float(ChampionAbilities.ability_data(&"arc_bolt")["amount"]), 40.0, "Arc Bolt level-1 damage 40")
	_eq(ab.cast(&"arc_bolt", far), "Invalid target", "Arc Bolt beyond 12 m")
	_eq(ab.cast(&"arc_bolt", s), "", "Arc Bolt at 12 m")
	_fx(ch, &"arc_bolt", s, "Arc Bolt")
	_check(await _until_hurt(s, 100.0, 90), "the bolt lands")
	_near(100.0 - s.hp, 43.2, "Arc Bolt 40 x 1.08 at level 2")
	_check(_hit_logged(&"arc_bolt", s), "skill_hit(arc_bolt)")
	ch.level = 5
	ab.reset_cooldowns()
	var hp0: float = s.hp
	ab.cast(&"arc_bolt", s)
	await _until_hurt(s, hp0, 90)
	_near(hp0 - s.hp, 52.8, "Arc Bolt 40 x 1.32 at level 5")
	await _calm([ch, s, far])
	for u in [s, far]:
		u.queue_free()
	await _wait(2)
	# Trigger: a kill (highest cost first); else a hero; else the enemy on the most hurt ally.
	ch.level = 2
	var k1 := _unit(E, W + Vector3(8.0, 0.0, 0.0))
	var k2 := _typed(&"nightbolt", E, W + Vector3(0.0, 0.0, 9.0))
	var hero := _unit(E, W + Vector3(-10.0, 0.0, 0.0), 500.0)
	hero.add_to_group(&"enemy_heroes")
	var e1 := _unit(E, W + Vector3(0.0, 0.0, -8.0))
	var e2 := _unit(E, W + Vector3(5.0, 0.0, -8.0))
	var a1 := _unit(P, W + Vector3(0.0, 0.0, -10.0))
	var a2 := _unit(P, W + Vector3(5.0, 0.0, -10.0))
	await _wait(3)
	ab.reset_cooldowns()
	k1.hp = 30.0
	k2.hp = 40.0
	hp0 = k2.hp
	_eq(ab.try_autocast(), &"arc_bolt", "autocast Arc Bolt: a foe it kills")
	_check(await _until_hurt(k2, hp0, 90), "Arc Bolt picks the dearer kill (Nightbolt 100 over a 0-cost unit)")
	_check(not k2.is_alive(), "the Nightbolt dies")
	k1.queue_free()
	await _wait(2)
	ab.reset_cooldowns()
	a1.hp = 90.0
	a2.hp = 40.0
	e1.attack_target = a1
	e2.attack_target = a2
	hp0 = hero.hp
	_eq(ab.try_autocast(), &"arc_bolt", "autocast Arc Bolt: an enemy hero in range")
	_check(await _until_hurt(hero, hp0, 90), "Arc Bolt picks the hero")
	hero.queue_free()
	await _wait(2)
	ab.reset_cooldowns()
	e1.attack_target = a1
	e2.attack_target = a2
	hp0 = e2.hp
	_eq(ab.try_autocast(), &"arc_bolt", "autocast Arc Bolt: the enemy hitting the most hurt ally")
	_check(await _until_hurt(e2, hp0, 90), "Arc Bolt picks the enemy on the most hurt ally")
	await _calm([ch, e1, e2, a1, a2])
	for u in [e1, e2, a1, a2]:
		u.queue_free()
	await _wait(2)
	# Slipstep (level 3): 8 m straight away from the melee attacker.
	ch.level = 3
	ch.global_position = W
	var m := _unit(E, W + Vector3(1.2, 0.0, 0.0))
	await _wait(3)
	ab.reset_cooldowns()
	vfx.calls.clear()
	_eq(ab.cast(&"slipstep"), "", "Slipstep")
	var moved := _flat(ch.global_position, W)
	_check(moved >= 7.0 and moved <= 8.6, "Slipstep jumps ~8 m (%.2f)" % moved)
	_check(ch.global_position.x < W.x - 6.5, "Slipstep goes straight away from the melee enemy (x %.2f)" % ch.global_position.x)
	_fx(ch, &"slipstep", ch.global_position, "Slipstep (the landing point)")
	await _calm([ch, m])
	m.queue_free()
	var rb := _typed(&"nightbolt", E, ch.global_position + Vector3(3.0, 0.0, 0.0))
	await _wait(3)
	ab.reset_cooldowns()
	_eq(ab.cast(&"slipstep"), "Invalid target", "Slipstep without a melee enemy near")
	rb.queue_free()
	# Never onto a cell its team has not explored (fog on, a fresh corner of the map).
	var F := Vector3(55.0, 0.0, 55.0)
	ch.global_position = F   # no frame passes before the checks: the fog has never stamped this corner
	var m2 := _unit(E, F + Vector3(1.2, 0.0, 0.0))
	fog.enabled = true
	_check(fog.state_at(P, F + Vector3(-8.0, 0.0, 0.0)) == FogOfWar.UNEXPLORED, "the landing area starts unexplored")
	ab.reset_cooldowns()
	_eq(ab.cast(&"slipstep"), "Invalid target", "Slipstep refuses unexplored ground")
	fog.update_team(P)
	_eq(ab.cast(&"slipstep"), "", "Slipstep once the ground is explored")
	_check(fog.state_at(P, ch.global_position) != FogOfWar.UNEXPLORED, "landed on an explored cell")
	fog.enabled = false
	await _calm([ch, m2])
	# Trigger: a melee enemy within 3 m targets it and HP < 70 %; or fleeing with a melee enemy within 4 m.
	ch.global_position = W
	m2.global_position = W + Vector3(1.5, 0.0, 0.0)
	await _wait(3)
	ab.reset_cooldowns()
	m2.attack_target = ch
	_check(ab.try_autocast() != &"slipstep", "healthy: no Slipstep")
	ab.reset_cooldowns()
	ch.hp = ch.max_hp * 0.6
	m2.attack_target = ch
	_eq(ab.try_autocast(), &"slipstep", "autocast Slipstep: melee enemy on it, HP under 70 %")
	await _calm([ch, m2])
	ch.hp = ch.max_hp
	ch.global_position = W
	m2.global_position = W + Vector3(0.0, 0.0, 3.5)
	await _wait(3)
	ab.reset_cooldowns()
	ch.intent = &"fleeing"
	_eq(ab.try_autocast(), &"slipstep", "autocast Slipstep: fleeing with a melee enemy within 4 m")
	ch.intent = &"idle"
	stages += 1


# ---------------------------------------------------------------- Wizard: Starfall

func _test_starfall() -> void:
	var F := Vector3(30.0, 0.0, 25.0)
	var ch := _champ(&"wayfinder", WAYFINDER, &"wizard", F, 5)
	var ab = ch.abilities
	var at := F + Vector3(10.0, 0.0, 0.0)
	var u1 := _unit(E, at)
	var u2 := _unit(E, at + Vector3(1.0, 0.0, 1.0))
	var u3 := _unit(E, at + Vector3(0.0, 0.0, -2.0))
	var o := _unit(E, at + Vector3(0.0, 0.0, 4.5))
	var bld := Node3D.new()
	bld.set_script(_script(BUILDING_SRC))
	bld.add_to_group(&"buildings")
	world.add_child(bld)
	bld.global_position = at + Vector3(-3.0, 0.0, 0.0)
	spawned.append(bld)
	await _wait(3)
	_near(float(ChampionAbilities.ability_data(&"starfall")["amount"]), 45.0, "Starfall level-1 damage 45")
	_eq(ab.cast(&"starfall", F + Vector3(13.0, 0.0, 0.0)), "Invalid target", "Starfall beyond 12 m")
	_eq(ab.cast(&"starfall", at), "", "Starfall")
	_fx(ch, &"starfall", at, "Starfall (the point)")
	await _wait(54)
	_near(u1.hp, 100.0, "nothing before 1 s")
	await _wait(9)
	for u in [u1, u2, u3]:
		_near(100.0 - u.hp, 59.4, "Starfall 45 x 1.32 in r 3.5 after 1.0 s")
	_near(100.0 - o.hp, 0.0, "Starfall misses a unit 4.5 m away")
	_near(500.0 - float(bld.get(&"hp")), 59.4, "Starfall hits a building in the circle")
	_check(_hit_logged(&"starfall", u1), "skill_hit(starfall)")
	# Trigger: 3+ enemies within 3.5 m of one in range: the star falls on one of them.
	ab.reset_cooldowns()
	vfx.calls.clear()
	_eq(ab.try_autocast(), &"starfall", "autocast Starfall on a group of 3")
	var ok := false
	for c: Array in vfx.calls:
		if c[0] == &"starfall" and c[2] is Vector3:
			for u in [u1, u2, u3]:
				if (c[2] as Vector3).distance_to(u.global_position) < 0.05:
					ok = true
	_check(ok, "the star aims at a unit of the group")
	await _wait(70)
	ab.reset_cooldowns()
	u3.queue_free()
	await _wait(2)
	_check(ab.try_autocast() != &"starfall", "only 2 close together: no Starfall")
	# The star still falls if the champion dies meanwhile.
	var u4 := _unit(E, at + Vector3(0.0, 0.0, 1.0), 500.0)
	await _wait(2)
	ab.reset_cooldowns()
	_eq(ab.cast(&"starfall", at), "", "Starfall before falling")
	ch.die()
	await _wait(65)
	_check(u4.hp < 500.0, "the star lands even after the champion fell")
	stages += 1


# ---------------------------------------------------------------- autocast order: one cast per check

func _test_order() -> void:
	# A Two-Hand Mender at level 5 (its archetype triggers stay quiet: nobody of its side is hurt) next to a
	# Rimeshield it attacks, with 3 enemies within 3 m of it and 2 next to the Rimeshield: Crushing Blow,
	# Whirlwind and Cleave all fire; the 4.3 order casts them one per check. The enemies are rooted (the hits
	# make them fight back: they must not walk around).
	var O := Vector3(-40.0, 0.0, -10.0)
	var ch := _champ(&"mender", MENDER, &"two_hand", O, 5)
	ch.attack_range = 2.1
	var ab = ch.abilities
	var rs := _typed(&"rimeshield", E, O + Vector3(2.0, 0.0, 0.0))
	var n1 := _unit(E, O + Vector3(2.0, 0.0, 1.5), 400.0)
	var n2 := _unit(E, O + Vector3(-1.5, 0.0, 1.0), 400.0)
	var n3 := _unit(E, O + Vector3(3.5, 0.0, 0.0), 400.0)
	await _wait(5)
	for u in [rs, n1, n2, n3]:
		(u as Unit).apply_status(&"rooted", 30.0, true)
	rs.max_hp = 1000.0
	rs.hp = 1000.0
	ch.attack_target = rs
	cast_log.clear()
	ab.ability_cast.connect(_on_cast)
	ab.autocast_enabled = true
	await _wait(100)
	ab.autocast_enabled = false
	ab.ability_cast.disconnect(_on_cast)
	var ids: Array = []
	for c: Array in cast_log:
		ids.append(c[0])
	_check(ids.size() >= 3, "3 checks in 1.6 s cast 3 times (%s)" % str(ids))
	if ids.size() >= 3:
		_eq(str(ids.slice(0, 3)), str([&"crushing_blow", &"whirlwind", &"cleave"]),
				"one cast per check, in the 4.3 order (Crushing Blow, Whirlwind, Cleave)")
		for i in range(1, cast_log.size()):
			var gap: int = cast_log[i][1] - cast_log[i - 1][1]
			_check(gap >= 29 and gap <= 31, "checks 0.5 s apart (%d frames)" % gap)
	await _calm([ch, rs, n1, n2, n3])
	stages += 1


func _on_cast(id: StringName) -> void:
	cast_log.append([id, Engine.get_physics_frames()])


# ---------------------------------------------------------------- the real Champion (11.C1), if ready

func _test_real_champion() -> void:
	# Loaded dynamically: champion.gd / champion_type.gd change in 11.C1 at the same time.
	var path := "res://data/champions/oathwall.tres"
	var ct: Resource = load(path) if ResourceLoader.exists(path) else null
	if ct == null or not ct.has_method(&"create_champion"):
		notes.append("%s not loadable yet: real-Champion check skipped" % path)
		stages += 1
		return
	var ch: Node3D = ct.call(&"create_champion", 0)
	if ch == null:
		notes.append("create_champion failed: real-Champion check skipped")
		stages += 1
		return
	ch.set(&"team", P)
	world.add_child(ch)
	ch.global_position = Vector3(0.0, 0.0, 50.0)
	spawned.append(ch)
	await _wait(2)
	var brain := ch.get_node_or_null(^"Brain")
	if brain:
		brain.process_mode = Node.PROCESS_MODE_DISABLED
	var ab := ch.get_node_or_null(^"ChampionAbilities") as ChampionAbilities
	_check(ab != null, "real Champion has its ChampionAbilities")
	if ab == null:
		stages += 1
		return
	ab.autocast_enabled = false
	if not ch.has_method(&"class_id"):
		notes.append("Champion.class_id() not there yet (11.C1): real-Champion class check skipped")
		_eq(str(ab.ability_ids()), str(OATHWALL), "real Oathwall without classes: 3 ids")
		stages += 1
		return
	_eq(str(ab.ability_ids()), str(OATHWALL), "real Oathwall at level 1: 3 ids")
	ch.call(&"add_xp", 100000)
	await _wait(2)
	var cid: StringName = ch.call(&"class_id")
	_check(cid != &"", "real Oathwall chose a class at level 2 (%s)" % cid)
	_eq(ab.class_id(), cid, "abilities read the champion's class")
	_eq(str(ab.ability_ids()), str(OATHWALL + ChampionAbilities.class_skills_of(cid)),
			"real Oathwall at level 6: archetype + class ids")
	var all_on := true
	for id: StringName in ab.ability_ids():
		all_on = all_on and ab.is_unlocked(id)
	_check(all_on, "every ability unlocked at level 6")
	_eq(ab.unlocked_class_skill_count(), 3, "3 class skills unlocked at level 6")
	stages += 1


# ---------------------------------------------------------------- PERF: 6 class champions, 200 units

func _test_perf() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11002
	var champs: Array = []
	var kinds := [[&"wayfinder", WAYFINDER], [&"oathwall", OATHWALL], [&"coin_cutter", COIN_CUTTER],
			[&"mender", MENDER], [&"wayfinder", WAYFINDER], [&"coin_cutter", COIN_CUTTER]]
	var classes := [&"spear", &"sword_shield", &"two_hand", &"wizard", &"wizard", &"spear"]
	for i in 6:
		var pos := Vector3(-10.0 + 4.0 * i, 0.0, 0.0)
		var c := _champ(kinds[i][0], kinds[i][1], classes[i], pos, 5)
		c.attack_range = 7.5 if classes[i] == &"wizard" else 2.0
		champs.append(c)
	var units: Array = []
	for i in 200:
		var team := E if i % 2 == 0 else P
		var p := Vector3(rng.randf_range(-18.0, 18.0), 0.0, rng.randf_range(-18.0, 18.0))
		var u := _unit(team, p, 100.0)
		units.append(u)
	await _wait(5)
	for i in 200:
		var u: Unit = units[i]
		u.hp = rng.randf_range(35.0, 100.0)
		if u.team == E and i % 3 == 0:
			u.attack_target = champs[i % 6]
	# Worst case (info): every cooldown reset before each check, so each check casts.
	var forced: Array[float] = []
	for round in 8:
		for c in champs:
			var ab = c.abilities
			ab.reset_cooldowns()
			var t0 := Time.get_ticks_usec()
			ab.try_autocast()
			forced.append(float(Time.get_ticks_usec() - t0) / 1000.0)
		await _wait(3)
	forced.sort()
	print("PERF 11.C2 forced casts: median %.3f ms per check" % forced[forced.size() / 2])
	# Real play: each champion checks every 0.5 s (staggered), cooldowns run; 10 s with the classes, then
	# 10 s with no class (the step-9 cost) for comparison.
	var real := await _perf_run(champs, classes, 600)
	var base := await _perf_run(champs, [&"", &"", &"", &"", &"", &""], 600)
	print("PERF 11.C2: %d checks, median %.3f ms per check, %.4f ms per frame (step-9 abilities only: %.3f ms, %.4f ms per frame; 6 champions, 200 units)"
			% [int(real[2]), real[0], real[1], base[0], base[1]])
	if real[0] <= PERF_MEDIAN_MS and real[1] <= PERF_FRAME_MS:
		print("PERF OK")
	else:
		_check(false, "PERF: median %.3f ms per check (limit %.2f), %.4f ms per frame (limit %.2f)"
				% [real[0], PERF_MEDIAN_MS, real[1], PERF_FRAME_MS])
	stages += 1


# Drives the 0.5 s checks by hand for `frames` frames (champion i checks when (frame + 5 i) % 30 == 0).
# Returns [median ms per check, mean ms per frame, number of checks].
func _perf_run(champs: Array, classes: Array, frames: int) -> Array:
	for i in champs.size():
		champs[i].cls = classes[i]
		champs[i].abilities.reset_cooldowns()
	var samples: Array[float] = []
	var total := 0.0
	for f in frames:
		for i in champs.size():
			if (f + 5 * i) % 30 == 0:
				var t0 := Time.get_ticks_usec()
				champs[i].abilities.try_autocast()
				var ms := float(Time.get_ticks_usec() - t0) / 1000.0
				samples.append(ms)
				total += ms
		await _wait(1)
	samples.sort()
	return [samples[samples.size() / 2], total / float(frames), samples.size()]


# ---------------------------------------------------------------- helpers

func _wait(frames: int) -> void:
	for i in frames:
		await physics_frame


func _clear() -> void:
	for n in spawned:
		if is_instance_valid(n):
			n.queue_free()
	spawned.clear()
	for n in world.get_children():
		if n is Projectile or n is SpellHot or n.name.begins_with("Starfall") or n.is_in_group(&"fog_sources"):
			n.queue_free()
	vfx.calls.clear()
	hit_log.clear()
	await _wait(3)


# Stops every order / fight-back started by manual hits (0-damage swings would feed Riposte etc.).
func _calm(nodes: Array) -> void:
	for n in nodes:
		if is_instance_valid(n) and n is Unit:
			(n as Unit).command_stop()
			(n as Unit).attack_target = null
	await _wait(1)
	for n in nodes:
		if is_instance_valid(n) and n is Unit:
			(n as Unit).command_stop()
			(n as Unit).attack_target = null


# Waits until `u` has less than `hp0` HP (max `frames`); true if it happened.
func _until_hurt(u: Unit, hp0: float, frames: int) -> bool:
	for f in frames:
		if not is_instance_valid(u) or u.hp < hp0 - 0.001:
			return true
		await _wait(1)
	return is_instance_valid(u) and u.hp < hp0 - 0.001


func _script(src: String) -> GDScript:
	var gs := GDScript.new()
	gs.source_code = src
	gs.reload()
	return gs


func _unit(team: int, pos: Vector3, hp: float = 100.0) -> Unit:
	var u := Unit.new()
	u.team = team
	u.max_hp = hp
	u.attack_damage = 0.0
	u.aggro_range = 0.0
	world.add_child(u)
	u.hp = hp
	u.global_position = pos
	u.command_stop()
	spawned.append(u)
	return u


# A real unit type (armor, cost, reach from data/units), made harmless (no damage, no aggro).
func _typed(id: StringName, team: int, pos: Vector3) -> Unit:
	var u := Unit.new()
	u.apply_type(load("res://data/units/%s.tres" % id) as UnitType)
	u.team = team
	world.add_child(u)
	u.attack_damage = 0.0
	u.aggro_range = 0.0
	u.set_idle_regen_pct(0.0)
	u.global_position = pos
	u.command_stop()
	spawned.append(u)
	return u


func _champ(kind: StringName, ids: Array[StringName], cls: StringName, pos: Vector3, lvl: int,
		team: int = P) -> StubChampion:
	var t := StubType.new()
	t.id = kind
	t.ability_ids = ids
	var c := StubChampion.new()
	c.champion_type = t
	c.cls = cls
	c.team = team
	c.unit_name = String(kind)
	c.max_hp = 300.0
	c.attack_damage = 0.0
	c.aggro_range = 0.0
	c.level = lvl
	var n := Node3D.new()
	n.set_script(_script(MODEL_SRC))
	var ps := PackedScene.new()
	ps.pack(n)
	n.free()
	c.model_scene = ps
	world.add_child(c)
	c.global_position = pos
	c.command_stop()
	spawned.append(c)
	c.abilities.skill_hit.connect(_on_skill_hit)
	return c


func _on_skill_hit(id: StringName, target: Node3D, amount: float) -> void:
	hit_log.append([id, target, amount])


func _hit_logged(id: StringName, target: Node3D) -> bool:
	for h: Array in hit_log:
		if h[0] == id and h[1] == target:
			return true
	return false


# The model's play_cast(id) ran and ChampionVfx.play(id, champion, want) was called.
func _fx(ch: Unit, id: StringName, want: Variant, tag: String) -> void:
	var m := ch.get_model()
	_check(m != null and (m.get(&"casts") as Array).has(id), "%s: model play_cast(%s)" % [tag, id])
	var ok := false
	var got := []
	for c: Array in vfx.calls:
		if c[0] != id:
			continue
		got.append(c[2])
		if c[1] != ch:
			continue
		if want is Vector3:
			ok = c[2] is Vector3 and (c[2] as Vector3).distance_to(want) < 0.05
		else:
			ok = typeof(c[2]) == TYPE_OBJECT and is_instance_valid(c[2]) and c[2] == want
		if ok:
			break
	_check(ok, "%s: ChampionVfx.play(%s, champion, %s) (got %s)" % [tag, id, str(want), str(got)])


func _vfx_has(id: StringName) -> bool:
	for c: Array in vfx.calls:
		if c[0] == id:
			return true
	return false


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _check(ok: bool, msg: String) -> void:
	if not ok:
		errors.append(msg)
		print("  x %s" % msg)


func _eq(got: Variant, want: Variant, msg: String) -> void:
	if (got is String or got is StringName) and (want is String or want is StringName):
		if str(got) == str(want):
			return
	elif typeof(got) == typeof(want) and got == want:
		return
	_check(false, "%s: got '%s', want '%s'" % [msg, str(got), str(want)])


func _near(got: float, want: float, msg: String, tol: float = 0.05) -> void:
	if absf(got - want) > tol:
		_check(false, "%s: got %.3f, want %.3f" % [msg, got, want])
