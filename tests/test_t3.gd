extends SceneTree
## T3 (docs/design/t3-helpers.md, plan docs/plan/tiers-wave.md "T3 agent"): the 4 helpers (data, level = wizard level,
## kits, passives, bonds, stances, call / revive at the keep with the section-3 refusals), the 5 tier-3 units
## (requires_tier 3 at the keep, abilities), the Genie hire, the bot's call.
## Run:  godot --headless --path . -s tests/test_t3.gd --fixed-fps 60 --quit-after 9000

const TASK_ID := "t3"
const SCENE := "res://scenes/skirmish.tscn"
const COMMANDER := preload("res://scripts/ai/commander.gd")
const PLAYER := 0
const ENEMY := 1
const TIMEOUT_FRAMES := 7000

var main: Node
var frame := 0
var _wait := 0
var _started := false
var _done := false
var _errors: Array[String] = []
var _spot := Vector3.ZERO
var _dir := Vector3.ZERO
var _side := Vector3.ZERO


## A fake enemy building for the Powder Charge (take_damage, team, group "buildings").
class FakeBuilding extends Node3D:
	var team := 1
	var hp := 1000.0
	func _ready() -> void:
		add_to_group(&"buildings")
	func is_alive() -> bool:
		return hp > 0.0
	func take_damage(amount: float, _attacker: Node3D = null) -> void:
		hp -= amount
	func target_radius() -> float:
		return 1.0


func _initialize() -> void:
	main = load(SCENE).instantiate()
	main.camps_enabled = false
	main.beasts_enabled = false
	root.add_child(main)
	current_scene = main


func _process(_delta: float) -> bool:
	if main.hero == null:
		_wait += 1
		if _wait > 5000:
			print("FAIL %s: navigation never finished baking" % TASK_ID)
			return true
		return false
	frame += 1
	if frame == 5 and not _started:
		_started = true
		_run()
	if _done:
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out; %s" % [TASK_ID, "; ".join(_errors)])
		return true
	return false


func _check(ok: bool, what: String) -> void:
	if not ok:
		_errors.append(what)
		print("  x " + what)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _run() -> void:
	for n in main.get_children():
		if n.get_script() == COMMANDER:
			n.set(&"enabled", false)   # the bot is checked on its own below
	var keep: Node3D = main.keep
	_dir = -Vector3(keep.global_position.x, 0.0, keep.global_position.z).normalized()
	_side = _dir.cross(Vector3.UP)
	_spot = keep.global_position + _dir * 22.0
	main.economy.add(30000)
	main.economy.add_pop_bonus(150)
	_check_data()
	await _check_roster()
	await _check_vey()
	await _check_hush()
	await _check_aldra()
	await _check_maelis()
	await _check_units()
	await _check_bot()
	_done = true


func _tiers() -> TierSystem:
	var ts := TierSystem.instance()
	if ts == null:
		ts = TierSystem.new()
		main.add_child(ts)
	return ts


func _dummy(pos: Vector3, hp: float = 5000.0, team: int = ENEMY) -> Unit:
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


func _spawn(id: String, team: int, pos: Vector3) -> Unit:
	var u := UnitType.find(id).create_unit()
	u.team = team as Unit.Team
	main.add_child(u)
	u.global_position = pos
	u.command_hold()
	return u


func _helper(id: StringName, team: int, pos: Vector3, lvl: int) -> Helper:
	var h := Helper.new()
	h.apply_helper_type(HelperType.find(id), lvl)
	h.team = team as Unit.Team
	main.add_child(h)
	h.global_position = pos
	h.command_stop()
	h.set_physics_process(false)            # no brain / auto-attacks: the test drives it
	h.helper_abilities.set_physics_process(false)
	return h


func _wizard_level(n: int) -> void:
	main.hero.level = n
	main.hero.level_changed.emit(main.hero, n)


func _cleanup(nodes: Array) -> void:
	for n in nodes:
		if is_instance_valid(n):
			n.queue_free()
	await _frames(2)


func _near(a: float, b: float, eps: float = 0.6) -> bool:
	return absf(a - b) <= eps


# ---------------------------------------------------------------- data

func _check_data() -> void:
	_check(T3Kit.ENABLED and T3Kit.enabled_here(), "T3 not enabled in the skirmish")
	var kingdoms := {}
	for hid in HelperType.IDS:
		var t := HelperType.find(hid)
		_check(t != null and t.model_scene != null and t.ability_ids.size() == 3 and t.passive_id != &"", "%s data" % hid)
		if t:
			kingdoms[t.kingdom] = hid
			var m := t.model_scene.instantiate()
			_check(m is Node3D, "%s model" % hid)
			if m:
				m.free()
	_check(kingdoms.size() == 4, "one helper per kingdom: %s" % str(kingdoms))
	_check(HelperType.for_kingdom(&"fire").id == &"helper_vey", "fire helper is Vey")
	var vey := HelperType.find(&"helper_vey")
	_check(vey.max_hp_at(4) == 850.0 and vey.damage_at(4) == 35.0 and vey.max_hp_at(8) == 1050.0, "Vey L4 / L8 stats")
	for id: StringName in T3Kit.UNIT_IDS:
		var t := UnitType.find(String(id))
		_check(t != null and t.requires_tier == 3 and t.model_scene != null, "%s data / requires_tier 3" % id)
		if t:
			var m := t.model_scene.instantiate()
			_check(m is Node3D, "%s model" % id)
			if m:
				m.free()


# ---------------------------------------------------------------- roster: call, refusals, revive

func _check_roster() -> void:
	var ts := _tiers()
	ts.set_tier(PLAYER, 1)
	var keep: TrainingBuilding = main.keep
	while keep.queue.size() > 0:
		keep.cancel(keep.queue.size() - 1)
	var ids := keep.trainable_types().map(func(t: UnitType) -> StringName: return t.id)
	var k: StringName = main.kingdom_of(PLAYER)
	_check(ids.has(T3Kit.KEEP_UNITS[k]) and ids.has(HelperRoster.CALL_ID), "keep card lacks T3 unit / call: %s" % str(ids))
	var roster := HelperRoster.for_team(PLAYER)
	var stub := roster.call_type()
	_check(stub.display_name == "Call %s" % HelperType.for_kingdom(k).display_name, "stub name %s" % stub.display_name)
	_check(keep.can_queue(stub) == TierSystem.MSG_T3, "call at tier 1: '%s'" % keep.can_queue(stub))
	_check(keep.can_queue(UnitType.find(String(T3Kit.KEEP_UNITS[k]))) == TierSystem.MSG_T3, "T3 unit at tier 1 not refused")
	(keep as Keep).set_tier_now(3)
	ts.set_tier(PLAYER, 3)
	var bank := EssenceBank.for_team(PLAYER)
	if bank:
		bank.trickle_enabled = false
		bank.add(-bank.essence)
		_check(keep.can_queue(stub) == HelperRoster.REASON_NO_ESSENCE, "no essence: '%s'" % keep.can_queue(stub))
		bank.add(2000)
	var e0: int = bank.essence if bank else 0
	var pop0: int = main.economy.pop_used
	_check(keep.queue_unit(stub) == "", "call refused: %s" % keep.can_queue(stub))
	if bank:
		_check(bank.essence == e0 - 200, "call essence 200 (%d -> %d)" % [e0, bank.essence])
	_check(roster.state() == &"queued", "state after call %s" % roster.state())
	_check(roster.can_call() == HelperRoster.REASON_ALREADY, "second call: '%s'" % roster.can_call())
	_check(keep.trainable_types().filter(func(t: UnitType) -> bool: return t.id == HelperRoster.CALL_ID).size() == 1,
			"call stub listed once")
	# Cancel refunds, then call again and let it finish fast.
	keep.cancel(keep.queue.find(stub))
	_check(roster.state() == &"none" and (bank == null or bank.essence == e0), "cancel refund")
	stub.train_time = 0.1
	keep.queue_unit(stub)
	await _frames(20)
	var h := roster.helper
	_check(h != null and is_instance_valid(h) and h.is_alive() and roster.state() == &"alive", "helper did not arrive")
	if h == null:
		return
	stub.train_time = 60.0
	_check(main.economy.pop_used >= pop0 + 4, "helper pop 4 held (%d -> %d)" % [pop0, main.economy.pop_used])
	_check(not h.is_commandable(), "helper is commandable")
	_check(h.bonded_wizard == main.hero, "bonded to the player's wizard")
	_check(h.level == main.hero.level, "level follows the wizard at call")
	main.hero.level = 4
	main.hero.level_changed.emit(main.hero, 4)
	_check(h.level == 4, "level after the wizard's level-up: %d" % h.level)
	h.add_xp(5000)
	_check(h.level == 4, "add_xp is not a no-op")
	_check(h.set_stance(&"vanguard") == "" and h.stance == &"vanguard" and h.set_stance(&"nope") == "Invalid stance",
			"stances")
	h.set_stance(&"escort")
	_check(Unit.kill_xp_value(h) == 100 + 30 * 4, "victim XP %d" % Unit.kill_xp_value(h))
	# Death: fallen, never ends the match; revive = 120 + 20 x level essence, 25 + 5 x level s.
	h.take_damage(99999.0, null)
	await _frames(2)
	_check(roster.state() == &"fallen" and not main.game_over, "fallen state / match over")
	_check(roster.revive_cost() == 200 and _near(roster.revive_time(), 45.0), "revive L4 %d / %.0f s"
			% [roster.revive_cost(), roster.revive_time()])
	var rev := roster.revive_type()
	var ids2 := keep.trainable_types().map(func(t: UnitType) -> StringName: return t.id)
	_check(ids2.has(HelperRoster.REVIVE_ID) and not ids2.has(HelperRoster.CALL_ID), "revive slot: %s" % str(ids2))
	_check(keep.queue_unit(rev) == "", "revive refused: %s" % keep.can_queue(rev))
	rev.train_time = 0.1
	await _frames(20)
	_check(h.is_alive() and roster.state() == &"alive", "revive did not bring it back")
	h.set_physics_process(true)
	# The brain: escort stays near the wizard.
	main.hero.global_position = _spot
	await _frames(240)
	_check(Helper._flat(h.global_position, main.hero.global_position) < 9.0, "escort did not follow the wizard (%.1f m)"
			% Helper._flat(h.global_position, main.hero.global_position))
	h.set_stance(&"home")
	await _frames(2)
	h.queue_free()
	roster.helper = null
	await _frames(2)


# ---------------------------------------------------------------- Old Vey

func _check_vey() -> void:
	var at := _spot + _side * 30.0
	_wizard_level(4)
	var vey := _helper(&"helper_vey", PLAYER, at, 4)
	vey.bond_to(main.hero)
	_check(_near(vey.max_hp, 850.0) and _near(vey.attack_damage, 35.0), "Vey L4 %.0f / %.0f" % [vey.max_hp, vey.attack_damage])
	var ab := vey.helper_abilities
	_check(ab.cast(&"vey_stormcall") == "Requires level 5", "signature before L5: %s" % ab.cast(&"vey_stormcall"))
	var dummies: Array = []
	for i in 5:
		dummies.append(_dummy(at + _dir * (3.0 + 2.5 * i)))
	await _frames(2)
	var r := ab.cast(&"vey_chain", dummies[0])
	_check(r == "", "chain: %s" % r)
	var want := [45.0, 38.0, 32.0, 27.0, 23.0]
	for i in 5:
		var lost: float = 5000.0 - (dummies[i] as Unit).hp
		_check(_near(lost, want[i] * 1.12, 0.2), "chain jump %d: %.2f (want %.2f)" % [i, lost, want[i] * 1.12])
	var cd0 := ab.cooldown_left(&"vey_chain")
	main.hero.spell_hit.emit(dummies[0], 10.0, &"fireball")
	_check(_near(ab.cooldown_left(&"vey_chain"), cd0 - 2.0, 0.05), "Fireball cut the chain by 2 s")
	main.hero.spell_hit.emit(dummies[0], 10.0, &"fireball")
	_check(_near(ab.cooldown_left(&"vey_chain"), cd0 - 2.0, 0.05), "Fireball cut twice within 2 s")
	# Storm-Sworn: every 3rd strike chains to 2 enemies within 5 m for 50 %.
	var before: float = (dummies[1] as Unit).hp
	for i in 3:
		vey.attack_landed.emit(dummies[0], 20.0)
	_check(_near(before - (dummies[1] as Unit).hp, 10.0, 0.1), "Storm-Sworn 3rd strike")
	vey.set_level(5)
	_check(ab.can_cast(&"vey_stormcall") == "", "signature at L5: %s" % ab.can_cast(&"vey_stormcall"))
	await _cleanup(dummies + [vey])


# ---------------------------------------------------------------- Mother Hush

func _check_hush() -> void:
	var at := _spot - _side * 30.0
	var hush := _helper(&"helper_hush", ENEMY, at, 1)
	hush.helper_abilities.set_physics_process(true)
	var foe := _spawn("flame_guard", PLAYER, at + _dir * 6.0)
	foe.aggro_range = 12.0
	foe.command_stop()
	foe.set_physics_process(false)
	await _frames(int(4.6 * 60))
	_check(hush.helper_abilities.veiled and hush.is_hidden_from_auto_target(), "Hush not veiled after 4 s")
	foe.set_physics_process(true)
	await _frames(20)
	_check(foe.attack_target != hush, "a unit at 6 m auto-targeted the veiled Hush")
	hush.helper_abilities.set_physics_process(false)
	var bag := _dummy(at + _dir * 2.0, 5000.0, PLAYER)
	hush.helper_abilities.veiled = true
	hush.attack_landed.emit(bag, 20.0)
	_check(_near(5000.0 - bag.hp, 12.0, 0.1), "veil +60 %% first strike (%.1f)" % (5000.0 - bag.hp))
	var hp0 := bag.hp
	hush.helper_abilities._on_wizard_spell_hit(bag, 10.0, &"shadow_lance")
	hush.attack_landed.emit(bag, 20.0)
	_check(_near(hp0 - bag.hp, 3.0, 0.1), "Bishop's knife +15 %% (%.1f)" % (hp0 - bag.hp))
	_check(hush.helper_abilities.cast(&"hush_blink", bag) == "", "blink")
	await _frames(40)
	_check(bag.hp < hp0 - 50.0, "Blink Strike did not hit")
	await _cleanup([hush, foe, bag])


# ---------------------------------------------------------------- Aldra Stillwater

func _check_aldra() -> void:
	var at := _spot + _dir * 12.0
	_wizard_level(5)
	var aldra := _helper(&"helper_aldra", PLAYER, at, 5)
	aldra.helper_abilities.set_physics_process(true)
	var ally := _dummy(at + _side * 3.0, 1000.0, PLAYER)
	var archer := _spawn("ember_archer", ENEMY, at + _side * 12.0)
	archer.set_physics_process(false)
	await _frames(40)
	var hp0 := ally.hp
	ally.take_damage(100.0, archer)
	_check(_near(hp0 - ally.hp, 88.0, 0.5), "ward: ranged hit took %.1f (want 88)" % (hp0 - ally.hp))
	var p := at + _dir * 6.0
	var r := aldra.helper_abilities.cast(&"aldra_sentinel", p)
	_check(r == "", "sentinel: %s" % r)
	var s := aldra.helper_abilities.sentinel
	_check(s != null and s.is_alive() and s.unit_type.pop == 0 and _near(s.lifetime_left(), 30.0, 0.2), "Sentinel 30 s pop 0")
	_check(aldra.helper_abilities._pick(&"aldra_sentinel") == null, "second Sentinel allowed")
	await _cleanup([aldra, ally, archer, s])


# ---------------------------------------------------------------- Maelis

func _check_maelis() -> void:
	var at := _spot - _dir * 6.0 + _side * 12.0
	_wizard_level(4)
	var maelis := _helper(&"helper_maelis", PLAYER, at, 4)
	maelis.set_physics_process(true)   # the aura carrier ticks in Unit._physics_process
	var foe := _dummy(at + _dir * 8.0)
	await _frames(2)
	_check(maelis.helper_abilities.cast(&"call_the_pack", foe) == "", "call the pack")
	var wolves := maelis.helper_abilities.wolves
	_check(wolves.size() == 2, "wolves %d" % wolves.size())
	await _frames(30)
	if wolves.size() > 0:
		var w := wolves[0]
		_check(_near(w.get_stat(&"move_speed"), w.unit_type.move_speed + 1.0, 0.05), "Opinions +1 speed (%.2f)"
				% w.get_stat(&"move_speed"))
		_check(_near(w.max_hp, 180.0 * 1.12, 0.5), "wolf HP x level factor (%.1f)" % w.max_hp)
	await _cleanup([maelis, foe] + wolves)


# ---------------------------------------------------------------- T3 units

func _check_units() -> void:
	var at := _spot + _dir * 30.0
	for n in get_nodes_in_group(&"units"):   # map-fill neutrals wandering there would take the chains
		if n is Unit and int(n.team) == 2 and Helper._flat(n.global_position, at) < 40.0:
			n.queue_free()
	await _frames(2)
	# Saboteur: enemy auto-aggro ignores it at 10 m; a hero within 8 m reveals it.
	var sab := _spawn("ashveil_saboteur", ENEMY, at)
	var guard := _spawn("flame_guard", PLAYER, at + _side * 10.0)
	guard.aggro_range = 12.0
	guard.command_stop()
	await _frames(30)
	_check(T3Kit.ability_of(sab).disguised and sab.is_disguised_for(PLAYER) and not sab.is_disguised_for(ENEMY), "disguise")
	_check(guard.attack_target != sab, "a soldier auto-targeted the disguised Saboteur")
	guard.queue_free()
	await _frames(2)
	var fb := FakeBuilding.new()
	fb.team = PLAYER
	main.add_child(fb)
	fb.global_position = at - _side * 2.5
	await _frames(int(3.8 * 60))
	_check(not T3Kit.ability_of(sab).disguised, "planting did not reveal")
	await _frames(int(5.5 * 60))
	_check(1000.0 - fb.hp >= 250.0 and 1000.0 - fb.hp < 340.0, "Powder Charge %.0f" % (1000.0 - fb.hp))
	_check(T3Kit.is_paused(fb), "charge did not pause the building")
	await _cleanup([sab, guard, fb])
	# Reaver: heals 35 %, 17.5 % after a fire hit.
	var rv := _spawn("nightblood_reaver", ENEMY, at)
	var bag := _dummy(at + _dir * 1.5, 5000.0, PLAYER)
	rv.hp = 100.0
	rv.attack_landed.emit(bag, 100.0)
	_check(_near(rv.hp, 135.0, 0.1), "Nightblood 35 %% (%.1f)" % rv.hp)
	var fire := _spawn("flame_guard", PLAYER, at + _side * 3.0)
	fire.set_physics_process(false)
	rv.take_damage(1.0, fire)
	var hp1 := rv.hp
	rv.attack_landed.emit(bag, 100.0)
	_check(_near(rv.hp - hp1, 17.5, 0.1), "Sunburn halves drinking (%.1f)" % (rv.hp - hp1))
	rv.hp = rv.max_hp * 0.3
	await _frames(40)
	_check(T3Kit.ability_of(rv).is_frenzied(), "Blood Frenzy under 40 %")
	await _cleanup([rv, bag, fire])
	# Shardguard: a charge that ends within 2.4 m is frozen 1 s, once per 10 s.
	var sg := _spawn("shardguard", PLAYER, at)
	var rider := _spawn("blaze_rider", ENEMY, at + _dir * 9.0)
	rider.set_physics_process(false)
	await _frames(12)
	rider.global_position = at + _dir * 1.6
	await _frames(12)
	_check(rider.has_status(&"frozen"), "Hold the Line did not freeze the charge")
	var rider2 := _spawn("blaze_rider", ENEMY, at - _dir * 9.0)
	rider2.set_physics_process(false)
	await _frames(12)
	rider2.global_position = at - _dir * 1.6
	await _frames(12)
	_check(not rider2.has_status(&"frozen"), "Hold the Line fired twice within 10 s")
	await _cleanup([sg, rider, rider2])
	# Briar Roc: Seed Storm roots ground enemies only.
	var roc := _spawn("briar_roc", PLAYER, at)
	roc.set_physics_process(false)
	var g1 := _dummy(at + _dir * 5.0)
	var flyer := _spawn("briar_roc", ENEMY, at + _dir * 5.5)
	flyer.set_physics_process(false)
	await _frames(2)
	var g0 := g1.hp
	T3Kit.ability_of(roc).seed_storm(g1.global_position)
	_check(g1.has_status(&"rooted") and not flyer.has_status(&"rooted") and _near(g0 - g1.hp, 30.0, 0.1), "Seed Storm (rooted %s, flyer %s, lost %.1f)" % [g1.has_status(&"rooted"), flyer.has_status(&"rooted"), g0 - g1.hp])
	await _cleanup([roc, g1, flyer])
	# Genie: chain 22 / 16 on its bolt, Tempest 120 (+40 x2), x1.5 on titans.
	var genie := _spawn("stormbottle_genie", PLAYER, at)
	genie.set_physics_process(false)
	var d1 := _dummy(at + _dir * 8.0)
	var d2 := _dummy(at + _dir * 10.0)
	var d3 := _dummy(at + _dir * 12.0)
	await _frames(2)
	var h1 := d1.hp
	var h2 := d2.hp
	var h3 := d3.hp
	genie.attack_landed.emit(d1, 30.0)
	_check(_near(h2 - d2.hp, 22.0, 0.1) and _near(h3 - d3.hp, 16.0, 0.1), "Genie chain 22 / 16 (%.1f / %.1f)" % [h2 - d2.hp, h3 - d3.hp])
	T3Kit.ability_of(genie).tempest_bolt(d1)
	_check(_near(h1 - d1.hp, 120.0, 0.1) and _near(h2 - d2.hp, 62.0, 0.1), "Tempest 120 + 40 (%.1f / %.1f)" % [h1 - d1.hp, h2 - d2.hp])
	await _cleanup([genie, d1, d2, d3])
	# The T3 unit trains at the Citadel keep.
	var k: StringName = main.kingdom_of(PLAYER)
	var t := UnitType.find(String(T3Kit.KEEP_UNITS[k]))
	var keep: TrainingBuilding = main.keep
	_check(keep.can_queue(t) == "", "T3 unit at the Citadel: %s" % keep.can_queue(t))


# ---------------------------------------------------------------- bot

func _check_bot() -> void:
	var ts := _tiers()
	(main.keep_of(ENEMY) as Keep).set_tier_now(3)
	ts.set_tier(ENEMY, 3)
	var eco := Economy.for_team(ENEMY)
	eco.add(5000)
	eco.add_pop_bonus(100)
	var bank := EssenceBank.for_team(ENEMY)
	if bank:
		bank.add(1000)
	var ek: Keep = main.keep_of(ENEMY)
	# The real Commander (normal) calls its helper at the Citadel through its think tick.
	var roster := HelperRoster.for_team(ENEMY)
	for n in main.get_children():
		if n.get_script() == COMMANDER and int(n.get(&"team")) == ENEMY:
			n.set(&"enabled", true)
			n.set(&"difficulty", 1)
	for i in 20:
		await _frames(30)
		if roster.state() != &"none":
			break
	_check(roster.state() != &"none", "the Commander never called its helper (keep queue %s)"
			% str(ek.queue.map(func(t: UnitType) -> StringName: return t.id)))
	for n in main.get_children():
		if n.get_script() == COMMANDER:
			n.set(&"enabled", false)
	while ek.queue.size() > 0:
		ek.cancel(ek.queue.size() - 1)
	await _frames(2)
	_check(roster.state() == &"none", "cancel did not reset the bot's call")
	T3Kit.bot_tick(ENEMY, 1, ek, 600.0)
	var ids := ek.queue.map(func(t: UnitType) -> StringName: return t.id)
	_check(ids.has(HelperRoster.CALL_ID), "normal bot did not call its helper: %s" % str(ids))
	T3Kit.bot_tick(ENEMY, 0, ek, 600.0)
	_check(roster.state() == &"queued", "bot helper state %s" % roster.state())
	T3Kit.bot_tick(ENEMY, 2, ek, 601.0)
	var ids2 := ek.queue.map(func(t: UnitType) -> StringName: return t.id)
	_check(ids2.has(T3Kit.KEEP_UNITS[main.kingdom_of(ENEMY)]), "hard bot did not queue its T3 unit: %s" % str(ids2))
	# Genie: refused before any tavern opens / without money reasons in order.
	var r := T3Kit.can_hire_genie(ENEMY)
	_check(r == "" or r == T3Kit.REASON_NO_TAVERN, "genie hire: %s" % r)
