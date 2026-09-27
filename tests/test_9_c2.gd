extends SceneTree
## Task 9.C2: champion abilities (docs/design/champions.md 4.3 / 5, "Done when" 9.C2), on stub champions
## (a Unit with the Champion fields the abilities read) in a small world with a FogOfWar.
## - cast() reasons in order: "Dead", "Cannot act", "Locked", "On cooldown", "Invalid target".
## - Mender: Mending Draught 50 / 62 (L4) / 70 (L6) on the most hurt ally, spell_power and
##   cooldown_reduction apply; Soothing Circle 30 over 5 s on allies inside; Lifeline 100 x growth for 5 s
##   (wizard first); autocast = one cast per 0.5 s check; play_cast + ChampionVfx.play.
## - Wayfinder: Flare Arrow 20 damage and a point 18 m away visible for 6 s (sight marker 8 m / 6 s),
##   exploring / fighting triggers; Snare Line 15 + rooted 1.5 s (0.75 s on a hero), flee / hunt
##   triggers; Trailblaze only from L4, haste 5 s on itself + non-worker allies within 8 m.
## - Oathwall: Oath of Iron taunts 3 non-hero enemies within 6 m (not the wizard, not farther), +20 armor
##   3 s; Shield Bash 30 + dazed 0.8 s, prefers the enemy hitting the wizard; Bulwark roots itself 6 s and
##   braces allies within 5 m.
## - Coin-Cutter: Cutpurse +25 on the next attack and +15 purse on a kill; Smoke Pouch shroud 3 s and
##   enemy targets cleared for 3 s; Marked for Coin x1.15 for 6 s (L4), on the hunt target.
## Checks that need the 9.C1 statuses (taunted / dazed / braced / marked in Unit.STATUSES) are skipped
## with a NOTE until they exist.
## Run:  godot --headless --path . -s tests/test_9_c2.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "9.C2"
const AB_PATH := "res://scripts/units/champion_abilities.gd"
const P := 0   # Unit.Team.PLAYER
const E := 1   # Unit.Team.ENEMY
const MENDER: Array[StringName] = [&"mending_draught", &"soothing_circle", &"lifeline"]
const WAYFINDER: Array[StringName] = [&"flare_arrow", &"snare_line", &"trailblaze"]
const OATHWALL: Array[StringName] = [&"oath_of_iron", &"shield_bash", &"bulwark_stand"]
const COIN_CUTTER: Array[StringName] = [&"cutpurse", &"smoke_pouch", &"marked_for_coin"]
const MODEL_SRC := "extends Node3D\nvar casts: Array = []\nfunc play_cast(id: StringName) -> void:\n\tcasts.append(id)\n"
const VFX_SRC := "extends Node3D\nvar calls: Array = []\nfunc play(id: StringName, caster: Node3D, target: Variant) -> void:\n\tcalls.append([id, caster, target])\n"
const BOUNTY_SRC := "extends Node3D\nvar target: Node3D = null\nvar stake := 75\n"


## ChampionType stand-in (9.C1 builds the real one).
class StubType extends Resource:
	var id: StringName = &""
	var ability_ids: Array[StringName] = []
	var growth_pct := 0.08
	var flee_pct := 0.35


## Champion stand-in: the fields ChampionAbilities reads, and the child it creates.
class StubChampion extends Unit:
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
		visible = false   # a fallen champion stays in the tree


var world: Node3D
var fog: FogOfWar
var vfx: Node3D
var errors: Array[String] = []
var notes: Array[String] = []
var finished := false
var spawned: Array = []
var cast_log: Array = []
var has_taunted := false
var has_dazed := false
var has_braced := false
var has_marked := false
var fog_has_sources := false


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
	fog = FogOfWar.new()
	world.add_child(fog)
	fog_has_sources = (fog.get_script() as Script).source_code.contains("fog_sources")
	vfx = Node3D.new()
	vfx.set_script(_script(VFX_SRC))
	vfx.add_to_group(&"champion_vfx")
	world.add_child(vfx)
	has_taunted = Unit.STATUSES.has(&"taunted")
	has_dazed = Unit.STATUSES.has(&"dazed")
	has_braced = Unit.STATUSES.has(&"braced")
	has_marked = Unit.STATUSES.has(&"marked")
	for pair: Array in [["taunted", has_taunted], ["dazed", has_dazed], ["braced", has_braced],
			["marked", has_marked]]:
		if not pair[1]:
			notes.append("Unit.STATUSES has no '%s' yet (9.C1): its status checks are skipped" % pair[0])
	if not fog_has_sources:
		notes.append("FogOfWar does not stamp 'fog_sources' yet (9.C4): Flare vision checked on the marker only")
	_run()


func _process(_delta: float) -> bool:
	return finished


func _run() -> void:
	await _wait(3)
	if not ResourceLoader.exists(AB_PATH):
		_fail("missing " + AB_PATH)
		return
	await _test_mender()
	await _clear()
	await _test_wayfinder()
	await _clear()
	await _test_oathwall()
	await _clear()
	await _test_coin_cutter()
	await _clear()
	await _test_real_champion()
	await _clear()
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


# ---------------------------------------------------------------- Mender + reasons + autocast

func _test_mender() -> void:
	var M := Vector3(-35.0, 0.0, -35.0)
	var m = _champ(&"mender", MENDER, M, 1, true)
	var ab = m.abilities
	var ally1 := _unit(P, M + Vector3(3.0, 0.0, 0.0))
	var ally2 := _unit(P, M + Vector3(-2.0, 0.0, 0.0))
	var far_ally := _unit(P, M + Vector3(12.0, 0.0, 0.0))
	var foe := _unit(E, M + Vector3(0.0, 0.0, 3.0))
	var wiz := _unit(P, M + Vector3(0.0, 0.0, -3.0))
	wiz.add_to_group(&"heroes")
	await _wait(15)
	_check(ab.get_parent() == m and ab.champion == m, "ChampionAbilities takes its parent as champion")
	_check(str(ab.ability_ids()) == str(MENDER), "ability_ids() = champion_type.ability_ids (%s)" % str(ab.ability_ids()))
	_check(ab.is_unlocked(&"mending_draught") and ab.is_unlocked(&"soothing_circle") \
			and not ab.is_unlocked(&"lifeline"), "L1: 2 abilities unlocked, Lifeline locked")
	# Reasons.
	ally1.hp = 40.0
	far_ally.hp = 40.0
	_eq(ab.cast(&"flare_arrow", M), "Locked", "not its ability")
	_eq(ab.cast(&"lifeline", wiz), "Locked", "Lifeline before level 4")
	_eq(ab.cast(&"mending_draught", foe), "Invalid target", "Mending Draught on an enemy")
	_eq(ab.cast(&"mending_draught", far_ally), "Invalid target", "Mending Draught out of range (12 m)")
	_eq(ab.cast(&"mending_draught", ally1), "", "Mending Draught on an ally")
	_near(ally1.hp, 90.0, "Mending Draught heals 50 at L1")
	_eq(ab.cast(&"mending_draught", foe), "On cooldown", "On cooldown comes before Invalid target")
	_near(ab.cooldown_left(&"mending_draught"), 7.0, "Mending Draught cooldown 7 s")
	_check(m.get_model() != null and m.get_model().casts.has(&"mending_draught"), "model play_cast(ability_id) called")
	var call_ok := false
	for c: Array in vfx.calls:
		if c[0] == &"mending_draught" and c[1] == m and c[2] == ally1:
			call_ok = true
	_check(call_ok, "ChampionVfx.play(id, caster, target) called (%s)" % str(vfx.calls))
	m.level = 4
	ab.reset_cooldowns()
	_eq(ab.cast(&"lifeline", wiz), "", "Lifeline at level 4")
	m.level = 1
	_eq(ab.cast(&"lifeline", foe), "Locked", "Locked comes before On cooldown / Invalid target")
	m.apply_status(&"frozen", 1.0)
	_eq(ab.cast(&"mending_draught", ally1), "Cannot act", "Cannot act (frozen) comes before Locked / cooldown")
	_eq(ab.cast(&"lifeline", ally1), "Cannot act", "Cannot act before Locked")
	await _wait(70)
	_eq(ab.cast(&"soothing_circle", M + Vector3(20.0, 0.0, 0.0)), "Invalid target", "Soothing Circle point 20 m away")
	# Growth: 62 at L4, 70 at L6, on the lowest HP % ally when no target is given.
	wiz.shield = 0.0
	ally1.hp = 20.0
	ally2.hp = 50.0
	m.level = 4
	ab.reset_cooldowns()
	_eq(ab.cast(&"mending_draught", null), "", "Mending Draught without a target")
	_near(ally1.hp, 82.0, "Mending Draught heals 62 at L4, on the most hurt ally")
	_near(ally2.hp, 50.0, "the less hurt ally is not healed")
	m.level = 6
	ab.reset_cooldowns()
	ally1.hp = 10.0
	ab.cast(&"mending_draught", ally1)
	_near(ally1.hp, 80.0, "Mending Draught heals 70 at L6")
	# Spell power + cooldown reduction.
	m.level = 1
	m.add_modifier(&"item:0", {&"spell_power": 20.0, &"cooldown_reduction": 25.0})
	ab.reset_cooldowns()
	ally1.hp = 10.0
	ab.cast(&"mending_draught", ally1)
	_near(ally1.hp, 70.0, "spell_power 20: Mending Draught heals 60")
	_near(ab.cooldown_left(&"mending_draught"), 5.25, "cooldown_reduction 25: 7 s -> 5.25 s")
	_near(ab.cooldown_total(&"mending_draught"), 5.25, "cooldown_total with cdr")
	m.remove_modifier(&"item:0")
	# Lifeline: 100 x growth (124 at L4) for 5 s; autocast picks the wizard first.
	m.level = 4
	ab.reset_cooldowns()
	wiz.shield = 0.0
	ab.cast(&"lifeline", wiz)
	_near(wiz.shield, 124.0, "Lifeline shield 100 x 1.24 at L4")
	_near(wiz.shield_time_left(), 5.0, "Lifeline lasts 5 s")
	await _wait(306)
	_near(wiz.shield, 0.0, "Lifeline shield gone after 5 s")
	ab.reset_cooldowns()
	for u in [ally1, ally2, far_ally]:
		u.hp = u.max_hp
	wiz.hp = 30.0
	m.hp = m.max_hp * 0.3
	_eq(ab.try_autocast(), &"lifeline", "autocast Lifeline: wizard below 35 %")
	_check(wiz.shield > 0.0 and m.shield <= 0.0, "Lifeline autocast shields the wizard first")
	ab.reset_cooldowns()
	wiz.shield = 0.0
	wiz.hp = 100.0
	_eq(ab.try_autocast(), &"lifeline", "autocast Lifeline: a champion below 35 % (itself)")
	_check(m.shield > 0.0, "Lifeline autocast on the champion")
	m.shield = 0.0
	m.hp = m.max_hp
	# Soothing Circle: 3 hurt allies within 5 m of one point -> 30 each over 5 s (L1), not outside.
	m.level = 1
	ab.reset_cooldowns()
	ally1.hp = 50.0
	ally2.hp = 50.0
	wiz.hp = 50.0
	far_ally.hp = 40.0
	_eq(ab.try_autocast(), &"soothing_circle", "autocast Soothing Circle: 3 allies below 80 % close together")
	await _wait(165)   # 2.75 s: half of it
	_near(ally1.hp, 65.0, "Soothing Circle: 15 after 2.75 s", 0.1)
	await _wait(141)   # 5.1 s
	_near(ally1.hp, 80.0, "Soothing Circle heals 30 over 5 s (ally 1)", 0.1)
	_near(ally2.hp, 80.0, "Soothing Circle heals 30 over 5 s (ally 2)", 0.1)
	_near(wiz.hp, 80.0, "Soothing Circle heals 30 over 5 s (wizard)", 0.1)
	_near(far_ally.hp, 40.0, "Soothing Circle: an ally outside is not healed")
	# Mending autocast: an ally within 9 m below 70 %; not above it.
	ab.reset_cooldowns()
	ally1.hp = 100.0
	ally2.hp = 100.0
	wiz.hp = 100.0
	_eq(ab.try_autocast(), &"", "no autocast when every ally in range is above 70 %")
	ally2.hp = 60.0
	_eq(ab.try_autocast(), &"mending_draught", "autocast Mending Draught: ally below 70 %")
	_near(ally2.hp, 100.0, "autocast Mending Draught healed the hurt ally")
	# Autocast timer: every 0.5 s, one cast per check.
	ab.reset_cooldowns()
	ally1.hp = 50.0
	ally2.hp = 50.0
	wiz.hp = 50.0
	cast_log.clear()
	ab.ability_cast.connect(_on_cast)
	ab.autocast_enabled = true
	await _wait(62)
	ab.autocast_enabled = false
	ab.ability_cast.disconnect(_on_cast)
	_eq(cast_log.size(), 2, "two autocast checks in ~1 s -> 2 casts (%s)" % str(cast_log))
	if cast_log.size() >= 2:
		_eq(cast_log[0][0], &"soothing_circle", "first check casts Soothing Circle only")
		_eq(cast_log[1][0], &"mending_draught", "second check casts Mending Draught")
		var gap: int = cast_log[1][1] - cast_log[0][1]
		_check(gap >= 29 and gap <= 31, "checks are 0.5 s apart (%d frames)" % gap)
	# Dead + revive reset.
	m.die()
	_eq(ab.cast(&"mending_draught", ally1), "Dead", "Dead comes first")
	_eq(ab.cast(&"flare_arrow", ally1), "Dead", "Dead before Locked")
	_eq(ab.try_autocast(), &"", "no autocast while dead")
	ab.reset_cooldowns()
	var all_ready := true
	for id in MENDER:
		if ab.cooldown_left(id) > 0.0:
			all_ready = false
	_check(all_ready, "reset_cooldowns() readies every ability (revive)")


func _on_cast(id: StringName) -> void:
	cast_log.append([id, Engine.get_physics_frames()])


# ---------------------------------------------------------------- Wayfinder

func _test_wayfinder() -> void:
	var W := Vector3(0.0, 0.0, 40.0)
	var w = _champ(&"wayfinder", WAYFINDER, W, 1)
	var ab = w.abilities
	var pt := W + Vector3(18.0, 0.0, 0.0)
	var foe_f := _unit(E, pt)
	await _wait(15)
	_check(fog.state_at(P, pt) != FogOfWar.VISIBLE, "the point 18 m away starts hidden")
	# Flare Arrow.
	_eq(ab.cast(&"flare_arrow", W + Vector3(25.0, 0.0, 0.0)), "Invalid target", "Flare Arrow beyond 20 m")
	_eq(ab.cast(&"flare_arrow", pt), "", "Flare Arrow 18 m away")
	_near(foe_f.hp, 80.0, "Flare Arrow deals 20")
	var marker: Node3D = ab.last_sight_marker
	_check(marker != null and is_instance_valid(marker) and marker.is_in_group(&"fog_sources"),
			"Flare Arrow leaves a sight marker in 'fog_sources'")
	if marker and is_instance_valid(marker):
		_eq(int(marker.get(&"team")), P, "sight marker team")
		_near(float(marker.get(&"sight_radius")), 8.0, "sight marker radius 8")
		_near(float(marker.get(&"lifetime")), 6.0, "sight marker lifetime 6")
		_near(Vector2(marker.global_position.x - pt.x, marker.global_position.z - pt.z).length(), 0.0,
				"sight marker at the point")
	await _wait(15)
	if fog_has_sources:
		_check(fog.state_at(P, pt) == FogOfWar.VISIBLE, "Flare Arrow: the point is visible")
	await _wait(318)   # 5.55 s after the cast
	_check(is_instance_valid(marker), "sight marker still there at 5.5 s")
	if fog_has_sources:
		_check(fog.state_at(P, pt) == FogOfWar.VISIBLE, "Flare Arrow: still visible at 5.5 s")
	await _wait(33)    # 6.1 s
	_check(not is_instance_valid(marker), "sight marker gone after 6 s")
	await _wait(15)
	if fog_has_sources:
		_check(fog.state_at(P, pt) != FogOfWar.VISIBLE, "Flare Arrow: hidden again after 6 s")
	foe_f.queue_free()
	# Snare Line.
	var foe_s := _unit(E, W + Vector3(0.0, 0.0, 5.0))
	var hero_s := _unit(E, W + Vector3(0.0, 0.0, -5.0))
	hero_s.add_to_group(&"enemy_heroes")
	var foe_far := _unit(E, W + Vector3(0.0, 0.0, 10.0))
	await _wait(15)
	_eq(ab.cast(&"snare_line", foe_far), "Invalid target", "Snare Line beyond 8 m")
	_eq(ab.cast(&"snare_line", foe_s), "", "Snare Line")
	_near(foe_s.hp, 85.0, "Snare Line deals 15")
	_near(foe_s.status_time_left(&"rooted"), 1.5, "Snare Line roots 1.5 s")
	ab.reset_cooldowns()
	_eq(ab.cast(&"snare_line", hero_s), "", "Snare Line on a hero")
	_near(hero_s.status_time_left(&"rooted"), 0.75, "Snare Line roots a hero 0.75 s")
	await _wait(95)
	_check(not foe_s.has_status(&"rooted"), "Snare root over after 1.5 s")
	# Snare autocast: fleeing and an enemy within 8 m targets it.
	ab.reset_cooldowns()
	w.intent = &"fleeing"
	for u in [foe_s, hero_s, foe_far]:
		u.attack_target = null   # the snared ones fought back
	_eq(ab.try_autocast(), &"", "fleeing, nobody targets it: no Snare")
	foe_s.attack_target = w
	_eq(ab.try_autocast(), &"snare_line", "autocast Snare Line: fleeing, an enemy targets it")
	_check(foe_s.has_status(&"rooted"), "the enemy targeting it is snared")
	foe_s.attack_target = null
	await _wait(95)
	# Snare autocast: its hunt target (through a bounty flag) moves away within 8 m.
	ab.reset_cooldowns()
	var flag := Node3D.new()
	flag.set_script(_script(BOUNTY_SRC))
	flag.add_to_group(&"bounties")
	world.add_child(flag)
	spawned.append(flag)
	flag.set(&"target", foe_s)
	w.intent = &"hunting_bounty"
	w.intent_target = flag
	foe_s.velocity = Vector3(0.0, 0.0, -3.0)   # toward the Wayfinder
	_eq(ab.try_autocast(), &"", "hunt target coming closer: no Snare")
	foe_s.velocity = Vector3(0.0, 0.0, 3.0)    # away
	_eq(ab.try_autocast(), &"snare_line", "autocast Snare Line: hunt target moving away")
	w.intent = &"idle"
	w.intent_target = null
	for u in [foe_s, hero_s, foe_far]:
		u.queue_free()
	await _wait(2)
	# Flare autocast, exploring: the least explored point 14-20 m ahead (toward its destination).
	ab.reset_cooldowns()
	var dest := Node3D.new()
	world.add_child(dest)
	spawned.append(dest)
	dest.global_position = W + Vector3(-30.0, 0.0, 0.0)
	w.intent = &"exploring"
	w.intent_target = dest
	_eq(ab.try_autocast(), &"flare_arrow", "autocast Flare Arrow while exploring")
	var m2: Node3D = ab.last_sight_marker
	if m2 and is_instance_valid(m2):
		var d := Vector2(m2.global_position.x - W.x, m2.global_position.z - W.z).length()
		_check(d >= 13.9 and d <= 20.1 and m2.global_position.x < W.x,
				"explore flare 14-20 m ahead (%.1f m, x %.1f)" % [d, m2.global_position.x])
	# Flare autocast, fighting: the last spot of an enemy that just left vision within 20 m.
	ab.reset_cooldowns()
	w.intent = &"fighting"
	w.intent_target = null
	var runner := _unit(E, W + Vector3(6.0, 0.0, -6.0))
	var last := runner.global_position
	await _wait(15)
	_eq(ab.try_autocast(), &"", "fighting, enemy in sight: no Flare")
	runner.global_position = W + Vector3(14.0, 0.0, -8.0)
	await _wait(15)
	_check(not fog.is_visible(P, runner.global_position), "the runner left vision")
	_eq(ab.try_autocast(), &"flare_arrow", "autocast Flare Arrow on an enemy that left vision")
	var m3: Node3D = ab.last_sight_marker
	if m3 and is_instance_valid(m3):
		_near(Vector2(m3.global_position.x - last.x, m3.global_position.z - last.z).length(), 0.0,
				"fight flare at the enemy's last seen spot")
	runner.queue_free()
	w.intent = &"idle"
	# Trailblaze: locked before L4; haste 5 s on itself and own non-workers within 8 m.
	var ally_t := _unit(P, W + Vector3(-4.0, 0.0, 0.0))
	var worker := _worker(P, W + Vector3(-3.0, 0.0, 2.0))
	var ally_far := _unit(P, W + Vector3(-10.0, 0.0, 0.0))
	var foe_t := _unit(E, W + Vector3(0.0, 0.0, 5.0))
	await _wait(15)
	_eq(ab.cast(&"trailblaze"), "Locked", "Trailblaze locked at level 1")
	w.level = 4
	_check(ab.is_unlocked(&"trailblaze"), "Trailblaze unlocked at level 4")
	_eq(ab.cast(&"trailblaze"), "", "Trailblaze at level 4")
	_near(w.status_time_left(&"haste"), 5.0, "Trailblaze hastes itself 5 s")
	_near(ally_t.status_time_left(&"haste"), 5.0, "Trailblaze hastes an ally within 8 m")
	_check(not worker.has_status(&"haste"), "Trailblaze skips workers")
	_check(not ally_far.has_status(&"haste"), "Trailblaze skips allies beyond 8 m")
	_check(not foe_t.has_status(&"haste"), "Trailblaze skips enemies")
	ab.reset_cooldowns()
	w.intent = &"fleeing"
	_eq(ab.try_autocast(), &"trailblaze", "autocast Trailblaze while fleeing")
	ab.reset_cooldowns()
	w.intent = &"scouting_bounty"
	w.intent_target = dest
	w.velocity = Vector3(-3.0, 0.0, 0.0)
	_eq(ab.try_autocast(), &"trailblaze", "autocast Trailblaze walking to a point 30 m away")
	ab.reset_cooldowns()
	dest.global_position = W + Vector3(-20.0, 0.0, 0.0)
	w.velocity = Vector3(-3.0, 0.0, 0.0)
	_check(ab.try_autocast() != &"trailblaze", "no Trailblaze for a point 20 m away")


# ---------------------------------------------------------------- Oathwall

func _test_oathwall() -> void:
	var O := Vector3(35.0, 0.0, -35.0)
	var o = _champ(&"oathwall", OATHWALL, O, 1)
	var ab = o.abilities
	var e1 := _unit(E, O + Vector3(3.0, 0.0, 0.0))
	var e2 := _unit(E, O + Vector3(0.0, 0.0, 3.0))
	var e3 := _unit(E, O + Vector3(-3.0, 0.0, 1.0))
	var ew := _unit(E, O + Vector3(0.0, 0.0, -3.0))
	ew.add_to_group(&"enemy_heroes")
	var ef := _unit(E, O + Vector3(7.5, 0.0, 0.0))
	var ow := _unit(P, O + Vector3(-1.0, 0.0, 4.5))
	ow.add_to_group(&"heroes")
	var ally_o := _unit(P, O + Vector3(1.0, 0.0, -1.5))
	await _wait(15)
	var armor0: float = o.get_stat(&"armor")
	_eq(ab.cast(&"oath_of_iron"), "", "Oath of Iron")
	var taunted := 0
	for e in [e1, e2, e3]:
		if e.attack_target == o:
			taunted += 1
		if has_taunted:
			_check(e.has_status(&"taunted"), "non-hero enemy within 6 m taunted")
	_eq(taunted, 3, "Oath of Iron: 3 enemies within 6 m now attack the Oathwall")
	_check(ew.attack_target != o and not ew.has_status(&"taunted"), "Oath of Iron: the wizard is immune")
	_check(ef.attack_target != o and not ef.has_status(&"taunted"), "Oath of Iron: an enemy at 7.5 m is not taunted")
	_near(o.get_stat(&"armor"), armor0 + 20.0, "Oath of Iron: +20 armor")
	_check(o.has_modifier(&"ability:oath"), "modifier ability:oath")
	if has_taunted:
		_near(e1.status_time_left(&"taunted"), 3.0, "taunted 3 s")
	await _wait(60)
	e1.attack_target = null
	await _wait(2)
	_check(e1.attack_target == o, "a taunted enemy keeps the Oathwall as its target")
	await _wait(126)   # 3.1 s
	_near(o.get_stat(&"armor"), armor0, "Oath armor gone after 3 s")
	_check(not o.has_modifier(&"ability:oath"), "modifier ability:oath removed")
	e1.attack_target = null
	await _wait(2)
	_check(e1.attack_target == null, "taunt over: the target is free again")
	for e in [e1, e2, e3, ew, ef]:
		e.attack_target = null
	# Oath autocast: 2 enemies within 6 m attack an own unit.
	ab.reset_cooldowns()
	e1.attack_target = ally_o
	_eq(ab.try_autocast(), &"", "one enemy on an ally: no Oath")
	e2.attack_target = ally_o
	_eq(ab.try_autocast(), &"oath_of_iron", "autocast Oath of Iron: 2 enemies attack an ally")
	for e in [e1, e2, e3, ew, ef]:
		e.attack_target = null
	# Oath autocast: 3 enemies target the Oathwall.
	ab.reset_cooldowns()
	await _wait(2)
	for e in [e1, e2, ew]:
		e.attack_target = o
	_eq(ab.try_autocast(), &"oath_of_iron", "autocast Oath of Iron: 3 enemies target it")
	await _wait(190)
	for e in [e1, e2, e3, ew, ef]:
		e.attack_target = null
	# Shield Bash.
	ab.reset_cooldowns()
	_eq(ab.cast(&"shield_bash", ef), "Invalid target", "Shield Bash beyond 2.2 m")
	_eq(ab.cast(&"shield_bash", ally_o), "Invalid target", "Shield Bash on an ally")
	_eq(ab.cast(&"shield_bash", e1), "", "Shield Bash")
	_near(e1.hp, 70.0, "Shield Bash deals 30")
	if has_dazed:
		_near(e1.status_time_left(&"dazed"), 0.8, "Shield Bash dazes 0.8 s")
		_check(not e1.can_act() and not e1.can_move(), "dazed: no move, no act")
		await _wait(54)
		_check(e1.can_act() and not e1.has_status(&"dazed"), "daze over after 0.8 s")
	# Bash autocast prefers the enemy hitting the wizard over its own target.
	ab.reset_cooldowns()
	for e in [e1, e2, e3, ew, ef]:
		e.attack_target = null   # e1 fought back after the bash
	o.attack_target = e1
	e2.attack_target = ow
	var hp_e1: float = e1.hp
	var hp_e2: float = e2.hp
	_eq(ab.try_autocast(), &"shield_bash", "autocast Shield Bash")
	_near(e2.hp, hp_e2 - 30.0, "Shield Bash hits the enemy attacking the wizard")
	_near(e1.hp, hp_e1, "not its own target")
	ab.reset_cooldowns()
	e2.attack_target = null
	_eq(ab.try_autocast(), &"shield_bash", "autocast Shield Bash on its current target")
	_near(e1.hp, hp_e1 - 30.0, "Shield Bash on the current target")
	o.command_stop()
	# Bulwark Stand.
	var ally_in := _unit(P, O + Vector3(-4.0, 0.0, -1.0))
	var ally_out := _unit(P, O + Vector3(-6.0, 0.0, -2.0))
	await _wait(2)
	ab.reset_cooldowns()
	_eq(ab.cast(&"bulwark_stand"), "Locked", "Bulwark locked at level 1")
	o.level = 4
	_eq(ab.cast(&"bulwark_stand"), "", "Bulwark Stand at level 4")
	_near(o.status_time_left(&"rooted"), 6.0, "Bulwark roots itself 6 s")
	_check(not o.can_move(), "planted: can't move")
	if has_braced:
		_check(ally_in.has_status(&"braced"), "Bulwark braces an ally within 5 m")
		_check(not ally_out.has_status(&"braced"), "Bulwark skips an ally beyond 5 m")
		_check(not e1.has_status(&"braced"), "Bulwark never braces enemies")
	await _wait(180)
	if has_braced:
		_check(ally_in.has_status(&"braced"), "still braced after 3 s (refreshed)")
		var before: float = ally_in.hp
		ally_in.take_damage(10.0)
		_near(before - ally_in.hp, 7.0, "braced: a 10 hit takes 7")
	_check(o.has_status(&"rooted"), "still rooted after 3 s")
	await _wait(190)   # 6.2 s
	_check(not o.has_status(&"rooted"), "Bulwark over after 6 s")
	if has_braced:
		_check(not ally_in.has_status(&"braced"), "braces end with the stand")
	# Bulwark autocast: 3 enemies within 8 m while guarding.
	ab.reset_cooldowns()
	for e in [e1, e2, e3, ew, ef]:
		e.attack_target = null
	o.intent = &"guarding"
	_eq(ab.try_autocast(), &"bulwark_stand", "autocast Bulwark Stand: 3+ enemies within 8 m while guarding")
	ab.reset_cooldowns()
	await _wait(370)
	o.intent = &"idle"
	_eq(ab.try_autocast(), &"", "not guarding and no own building near: no Bulwark")


# ---------------------------------------------------------------- Coin-Cutter

func _test_coin_cutter() -> void:
	var C := Vector3(35.0, 0.0, 35.0)
	var cc = _champ(&"coin_cutter", COIN_CUTTER, C, 1)
	cc.attack_damage = 17.0
	cc.attack_cooldown = 0.9
	var ab = cc.abilities
	var v1 := _unit(E, C + Vector3(1.5, 0.0, 0.0))
	var v2 := _unit(E, C + Vector3(0.0, 0.0, 1.5))
	var vfar := _unit(E, C + Vector3(5.0, 0.0, 0.0))
	await _wait(15)
	# Cutpurse: +25 on the next attack only, +15 purse on a kill.
	_eq(ab.cast(&"cutpurse", vfar), "Invalid target", "Cutpurse needs melee reach")
	_eq(ab.cast(&"cutpurse", v1), "", "Cutpurse")
	_check(ab.is_cutpurse_armed(), "Cutpurse armed")
	cc.command_attack(v1)
	await _wait(4)
	_near(v1.hp, 100.0 - 17.0 - 25.0, "Cutpurse: next attack deals 17 + 25")
	_check(not ab.is_cutpurse_armed(), "Cutpurse used up")
	await _wait(56)
	_near(v1.hp, 100.0 - 17.0 - 25.0 - 17.0, "the attack after is a normal one")
	_eq(cc.purse, 0, "no loot without a kill")
	cc.command_stop()
	v2.hp = 30.0
	ab.reset_cooldowns()
	_eq(ab.cast(&"cutpurse", v2), "", "Cutpurse on a weak target")
	cc.command_attack(v2)
	await _wait(60)   # its own attack cooldown may still run
	_check(not v2.is_alive(), "Cutpurse kill")
	_eq(cc.purse, 15, "Cutpurse kill: +15 purse")
	cc.command_stop()
	# Cutpurse autocast: target below 50 % HP, or a worker.
	var v3 := _unit(E, C + Vector3(0.0, 0.0, -1.5))
	var wk := _worker(E, C + Vector3(-1.5, 0.0, 0.0))
	await _wait(15)
	ab.reset_cooldowns()
	cc.attack_target = v3
	_eq(ab.try_autocast(), &"", "healthy soldier target: no Cutpurse")
	v3.hp = 40.0
	cc.attack_target = v3
	_eq(ab.try_autocast(), &"cutpurse", "autocast Cutpurse on a target below 50 %")
	ab.reset_cooldowns()
	cc.attack_target = wk
	_eq(ab.try_autocast(), &"cutpurse", "autocast Cutpurse on a worker")
	ab.reset_cooldowns()
	cc.command_stop()
	for u in [v1, v3, wk, vfar]:
		u.queue_free()
	await _wait(2)
	# Smoke Pouch: shroud 3 s, enemies within 6 m drop it and can't retarget it for 3 s.
	var s1 := _unit(E, C + Vector3(3.0, 0.0, 0.0))
	var s2 := _unit(E, C + Vector3(0.0, 0.0, 4.0))
	var sfar := _unit(E, C + Vector3(8.0, 0.0, 0.0))
	await _wait(15)
	for s in [s1, s2, sfar]:
		s.attack_target = cc
	_eq(ab.cast(&"smoke_pouch"), "", "Smoke Pouch")
	_near(cc.status_time_left(&"shroud"), 3.0, "Smoke Pouch shrouds 3 s")
	_check(s1.attack_target == null and s2.attack_target == null, "enemies within 6 m drop it as a target")
	_check(sfar.attack_target == cc, "an enemy at 8 m keeps its target")
	await _wait(30)
	s1.aggro_range = 10.0
	await _wait(30)
	_check(s1.attack_target == null, "no auto-targeting it during the smoke")
	await _wait(125)   # 3.1 s
	_check(not cc.has_status(&"shroud"), "shroud over after 3 s")
	await _wait(20)
	_check(s1.attack_target == cc, "after the smoke it is auto-targeted again")
	s1.aggro_range = 0.0
	for s in [s1, s2, sfar]:
		s.attack_target = null
	await _wait(190)   # no hit for 3 s
	# Smoke autocast: low HP while hurt; 3 enemies targeting it.
	ab.reset_cooldowns()
	cc.hp = cc.max_hp * 0.4
	_eq(ab.try_autocast(), &"", "low HP but not being hit: no Smoke")
	cc.take_damage(1.0, s1)
	cc.command_stop()
	_eq(ab.try_autocast(), &"smoke_pouch", "autocast Smoke Pouch below flee threshold + 10 %")
	cc.hp = cc.max_hp
	await _wait(190)
	ab.reset_cooldowns()
	for s in [s1, s2, sfar]:
		s.attack_target = cc
	_eq(ab.try_autocast(), &"smoke_pouch", "autocast Smoke Pouch: 3 enemies target it")
	for s in [s1, s2, sfar]:
		s.attack_target = null
	await _wait(190)
	# Marked for Coin (L4): x1.15 damage taken for 6 s.
	var mk := _unit(E, C + Vector3(5.0, 0.0, 2.0))
	var mfar := _unit(E, C + Vector3(10.0, 0.0, 0.0))
	await _wait(15)
	ab.reset_cooldowns()
	_eq(ab.cast(&"marked_for_coin", mk), "Locked", "Marked for Coin locked at level 1")
	cc.level = 4
	_eq(ab.cast(&"marked_for_coin", mfar), "Invalid target", "Marked for Coin beyond 8 m")
	_eq(ab.cast(&"marked_for_coin", mk), "", "Marked for Coin")
	if has_marked:
		_near(mk.status_time_left(&"marked"), 6.0, "marked 6 s")
		var before: float = mk.hp
		mk.take_damage(10.0)
		_near(before - mk.hp, 11.5, "marked: a 10 hit takes 11.5")
		await _wait(366)
		_check(not mk.has_status(&"marked"), "mark over after 6 s")
	# Marked autocast on its hunt target (through a bounty flag).
	var mk2 := _unit(E, C + Vector3(-5.0, 0.0, 0.0))
	await _wait(15)
	ab.reset_cooldowns()
	var flag := Node3D.new()
	flag.set_script(_script(BOUNTY_SRC))
	flag.add_to_group(&"bounties")
	world.add_child(flag)
	spawned.append(flag)
	flag.set(&"target", mk2)
	cc.intent = &"hunting_bounty"
	cc.intent_target = flag
	_eq(ab.try_autocast(), &"marked_for_coin", "autocast Marked for Coin on the hunt target")
	if has_marked:
		_check(mk2.has_status(&"marked"), "the hunt target is marked")
	cc.intent = &"idle"


# ---------------------------------------------------------------- the real Champion (9.C1), if present

func _test_real_champion() -> void:
	var paths := ["res://scripts/units/champion.gd", "res://data/champions/coin_cutter.tres",
			"res://data/champions/wayfinder.tres"]
	for p: String in paths:
		if not ResourceLoader.exists(p):
			notes.append("%s missing: real-Champion check skipped" % p)
			return
	var C := Vector3(0.0, 0.0, -40.0)
	var ids_by_type := {"coin_cutter": COIN_CUTTER, "wayfinder": WAYFINDER, "oathwall": OATHWALL,
			"mender": MENDER}
	for kind: String in ids_by_type:
		var type: Resource = load("res://data/champions/%s.tres" % kind)
		if type == null:
			continue
		var want: Array[StringName] = ids_by_type[kind]
		_check(str(type.get(&"ability_ids")) == str(want), "%s.tres ability_ids match 4.3" % kind)
	var ct: Resource = load("res://data/champions/coin_cutter.tres")
	var ch: Node3D = ct.call(&"create_champion", 0)
	ch.set(&"team", P)
	world.add_child(ch)
	spawned.append(ch)
	ch.global_position = C
	var foe := _unit(E, C + Vector3(1.5, 0.0, 0.0))
	await _wait(2)
	var ab: Node = ch.get_node_or_null(^"ChampionAbilities")
	_check(ab != null and ch.get(&"abilities") == ab, "Champion creates its 'ChampionAbilities' child")
	if ab == null:
		return
	ab.set(&"autocast_enabled", false)
	var brain: Node = ch.get_node_or_null(^"Brain")
	if brain:
		brain.process_mode = Node.PROCESS_MODE_DISABLED   # this check drives the casts itself
	_check(ab.champion == ch, "abilities bound to the Champion")
	_check(str(ab.ability_ids()) == str(COIN_CUTTER), "real Coin-Cutter ability ids (%s)" % str(ab.ability_ids()))
	_eq(ab.cast(&"marked_for_coin", foe), "Locked", "real Coin-Cutter: Marked locked at L1")
	_eq(ab.cast(&"cutpurse", foe), "", "real Coin-Cutter: Cutpurse")
	_near(ab.amount_of(&"cutpurse"), 25.0, "real Coin-Cutter: Cutpurse bonus 25 at L1")
	ch.set(&"intent", &"Hunting bounty")
	ch.set(&"intent_target", foe)
	ch.call(&"add_xp", 940)   # step 11 XP table (x1.25)
	_eq(int(ch.get(&"level")), 4, "real Coin-Cutter reaches level 4 at 940 XP")
	_near(ab.amount_of(&"cutpurse"), 31.0, "Cutpurse bonus x1.24 at L4")
	await _wait(15)
	_eq(ab.try_autocast(), &"marked_for_coin", "real Coin-Cutter: Marked for Coin on its hunt target (intent 'Hunting bounty')")
	ch.call(&"die")
	_eq(ab.cast(&"smoke_pouch"), "Dead", "real Coin-Cutter: Dead")


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
		if n is SpellHot or n.is_in_group(&"fog_sources"):
			n.queue_free()
	vfx.calls.clear()
	await _wait(3)


func _script(src: String) -> GDScript:
	var gs := GDScript.new()
	gs.source_code = src
	gs.reload()
	return gs


func _unit(team: int, pos: Vector3) -> Unit:
	var u := Unit.new()
	u.team = team
	u.max_hp = 100.0
	u.attack_damage = 0.0
	u.aggro_range = 0.0
	world.add_child(u)
	u.global_position = pos
	u.command_stop()
	spawned.append(u)
	return u


func _worker(team: int, pos: Vector3) -> Unit:
	var t := UnitType.new()
	t.id = &"test_worker"
	t.display_name = "Test Worker"
	t.is_worker = true
	t.max_hp = 100.0
	t.attack_damage = 0.0
	t.aggro_range = 0.0
	var u := Unit.new()
	u.apply_type(t)
	u.team = team
	world.add_child(u)
	u.global_position = pos
	u.command_stop()
	spawned.append(u)
	return u


func _champ(kind: StringName, ids: Array[StringName], pos: Vector3, lvl: int, with_model: bool = false) -> StubChampion:
	var t := StubType.new()
	t.id = kind
	t.ability_ids = ids
	var c := StubChampion.new()
	c.champion_type = t
	c.team = P
	c.unit_name = String(kind)
	c.max_hp = 300.0
	c.attack_damage = 0.0
	c.aggro_range = 0.0
	c.level = lvl
	if with_model:
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
	return c


func _check(ok: bool, msg: String) -> void:
	if not ok:
		errors.append(msg)


func _eq(got: Variant, want: Variant, msg: String) -> void:
	if typeof(got) == typeof(want) or (got is String or got is StringName) and (want is String or want is StringName):
		if str(got) == str(want) and typeof(got) != TYPE_NIL:
			return
		if typeof(got) == TYPE_NIL and typeof(want) == TYPE_NIL:
			return
		if typeof(got) != TYPE_STRING and typeof(got) != TYPE_STRING_NAME and got == want:
			return
	errors.append("%s: got '%s', want '%s'" % [msg, str(got), str(want)])


func _near(got: float, want: float, msg: String, tol: float = 0.05) -> void:
	if absf(got - want) > tol:
		errors.append("%s: got %.3f, want %.3f" % [msg, got, want])
