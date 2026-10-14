extends SceneTree
## UR.G2 (docs/design/unit-upgrades.md 10 / 12): ResearchEffects H kinds off the hit path, and the save prefix.
## - thorns: Flame Guard Backdraft hurts a melee attacker 3 per strike, at most once per attacker per 0.5 s (a very fast
##   attacker), never a ranged attacker, a spell / DoT (no melee strike) nor a building; nothing without the row;
## - combat_shield: Sunforge Dawnshield shields 120 on a hit after 5 s unhurt, not again within the 20 s cooldown, again
##   after it; a bigger shield already on is never replaced (R3-2) and that skip spends no cooldown;
## - low_hp_status: Shadow Knight Grim Reprisal braced under 50 % HP, once per 30 s; Veilborn Veil Ride shroud;
## - kill_status: Stagrunner Wild Gallop haste after its attack kills a unit;
## - pack_aura: two Grave Hounds within 5 m get +2 damage (not stacked), a lone hound nothing;
## - idle_regen: Bramblehorn Mossback 2 -> 3 % / s;
## - on_applied: a unit spawned after the grant gets the effects cached;
## - save: "research:" modifiers are kept by save_snapshot, a damaged Grave Hound with Bone-Fed keeps its HP above the
##   base max on load, and the re-apply never doubles the modifier.
## Run:  tools/godot_run.ps1 --headless --path . -s tests/test_research_passives.gd --fixed-fps 60 --quit-after 8000

const TASK_ID := "research_passives"
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
	for id: StringName in [&"flame_guard_backdraft", &"sunforge_cataphract_dawnshield", &"shadow_knight_grim_reprisal",
			&"veilborn_dreadrider_veil_ride", &"stagrunner_wild_gallop", &"grave_hound_pack_hunger",
			&"grave_hound_bone_fed", &"bramblehorn_mossback"]:
		bank.grant(id)
	await _check_thorns()
	await _check_combat_shield()
	await _check_low_hp()
	await _check_kill_status()
	await _check_pack_aura()
	await _check_idle_regen()
	await _check_save()
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


## Holds, never attacks, 5000 extra HP.
func _passive(u: Unit) -> Unit:
	u.add_modifier(&"test_hp", {&"max_hp": 5000.0})
	u.hp = u.max_hp
	u.attacks_blocked = true
	u.command_hold()
	return u


func _clear(units: Array) -> void:
	for u: Variant in units:
		if is_instance_valid(u):
			(u as Node).queue_free()
	await _physics(2)


## A fake building attacker: a Node3D with team / is_alive / take_damage that counts the damage it takes.
func _fake_building(team: int, pos: Vector3) -> Node3D:
	var s := GDScript.new()
	s.source_code = "extends Node3D\nvar team := 0\nvar hp := 1000.0\nvar hits := 0\n" \
			+ "func is_alive() -> bool:\n\treturn true\n" \
			+ "func target_radius() -> float:\n\treturn 1.0\n" \
			+ "func take_damage(amount: float, _attacker: Node3D = null) -> void:\n\thits += 1\n\thp -= amount\n"
	s.reload()
	var n := Node3D.new()
	n.set_script(s)
	n.set(&"team", team)
	main.add_child(n)
	n.global_position = pos
	return n


# ---------------------------------------------------------------- kinds

func _check_thorns() -> void:
	var base := Vector3(0, 0, 0)
	var fg := _passive(_spawn("flame_guard", A, base))
	var shade := _spawn("shade", B, base + Vector3(1.2, 0, 0))
	shade.add_modifier(&"test_hp", {&"max_hp": 5000.0})
	shade.hp = shade.max_hp
	var fg_b := _passive(_spawn("flame_guard", B, base + Vector3(0, 0, 60)))
	var shade_b := _spawn("shade", A, base + Vector3(1.2, 0, 60))
	await _physics(3)
	_ok(not fg.research_hurt_fx.is_empty(), "thorns: the A Flame Guard has its hurt effect cached")
	var full := shade.max_hp
	var hits: Array[float] = []
	shade.attack_landed.connect(func(_t: Node3D, _d: float) -> void: hits.append(shade.hp))
	var hits_b: Array[int] = [0]
	shade_b.attack_landed.connect(func(_t: Node3D, _d: float) -> void: hits_b[0] += 1)
	shade.command_attack(fg)
	shade_b.command_attack(fg_b)
	await _until(func() -> bool: return hits.size() >= 2 and hits_b[0] >= 1, 300)
	# Consecutive strikes 1 s apart (the shade may already have struck on its own before the recorder).
	var one := hits[0] - hits[1] if hits.size() >= 2 else 0.0
	_ok(absf(one - 3.0) < 0.01, "thorns: a melee strike takes 3 back (%.2f, max HP %.0f)" % [one, full])
	_ok(is_equal_approx(shade_b.hp, shade_b.max_hp), "thorns: nothing without the row")
	# A very fast attacker (0.1 s cooldown): at most one thorns per 0.5 s.
	shade.set_base_stat(&"attack_cooldown", 0.1)
	var hp0 := shade.hp
	var n0 := hits.size()
	await _physics(180)   # 3 s
	var strikes := hits.size() - n0
	var taken := hp0 - shade.hp
	_ok(strikes >= 12, "thorns: the fast attacker struck many times (%d)" % strikes)
	_ok(taken <= 3.0 * 7.0 + 0.01 and taken >= 3.0 * 3.0 - 0.01 and taken < 3.0 * strikes * 0.5, "thorns: once per attacker per 0.5 s (%.1f over %d strikes)"
			% [taken, strikes])
	shade.command_stop()
	shade.attacks_blocked = true
	await _physics(40)
	# A spell / DoT (no melee strike), a ranged attacker, a building: never.
	var hp1 := shade.hp
	fg.take_damage(5.0, shade)
	_ok(is_equal_approx(shade.hp, hp1), "thorns: damage outside a melee strike reflects nothing")
	var bolt := _spawn("nightbolt", B, base + Vector3(-1.5, 0, 0))
	await _physics(3)
	var bolt_full := bolt.hp
	bolt.command_attack(fg)
	var bolt_hits: Array[int] = [0]
	bolt.attack_landed.connect(func(_t: Node3D, _d: float) -> void: bolt_hits[0] += 1)
	await _until(func() -> bool: return bolt_hits[0] >= 1, 300)
	_ok(bolt_hits[0] >= 1 and is_equal_approx(bolt.hp, bolt_full), "thorns: never a ranged attacker")
	var tower := _fake_building(B, base + Vector3(0, 0, 2))
	fg.take_damage(10.0, tower)
	_ok(int(tower.get(&"hits")) == 0, "thorns: never hits a building")
	await _clear([fg, shade, fg_b, shade_b, bolt, tower])


func _check_combat_shield() -> void:
	var base := Vector3(200, 0, 0)
	var c := _passive(_spawn("sunforge_cataphract", A, base))
	var cb := _passive(_spawn("sunforge_cataphract", B, base + Vector3(0, 0, 60)))
	await _physics(3)
	c.take_damage(10.0, null)
	cb.take_damage(10.0, null)
	_ok(c.shield > 100.0 and c.shield < 120.0, "combat_shield: a hit after 5 s unhurt gives the shield (%.1f)" % c.shield)
	_ok(c.shield_time_left() > 5.0, "combat_shield: lasts 6 s")
	_ok(cb.shield == 0.0, "combat_shield: nothing without the row")
	await _physics(420)   # 7 s: shield gone, unhurt 7 s, cooldown still running
	_ok(c.shield == 0.0, "combat_shield: the shield ended")
	c.take_damage(10.0, null)
	_ok(c.shield == 0.0, "combat_shield: not again within the 20 s cooldown")
	await _physics(900)   # 15 s more: cooldown over, unhurt 15 s
	c.take_damage(10.0, null)
	_ok(c.shield > 100.0, "combat_shield: again after the cooldown (%.1f)" % c.shield)
	# R3-2: a bigger shield already on (Snow Shield, Vow...) is never replaced, and the cooldown is not spent.
	var c2 := _passive(_spawn("sunforge_cataphract", A, base + Vector3(0, 0, 120)))
	await _physics(3)
	c2.add_shield(300.0, 10.0)
	c2.take_damage(10.0, null)
	_ok(c2.shield > 280.0 and c2.shield < 300.0, "combat_shield: a bigger shield is kept (%.1f)" % c2.shield)
	c2.add_shield(0.0, 0.0)
	await _physics(320)   # unhurt > 5 s again
	c2.take_damage(10.0, null)
	_ok(c2.shield > 100.0 and c2.shield < 120.0, "combat_shield: the skipped hit spent no cooldown (%.1f)" % c2.shield)
	await _clear([c, cb, c2])


func _check_low_hp() -> void:
	var base := Vector3(400, 0, 0)
	var k := _spawn("shadow_knight", A, base)
	var kb := _spawn("shadow_knight", B, base + Vector3(0, 0, 60))
	var v := _spawn("veilborn_dreadrider", A, base + Vector3(0, 0, 120))
	for u: Unit in [k, kb, v]:
		u.attacks_blocked = true
		u.command_hold()
	await _physics(3)
	k.hp = k.max_hp * 0.6
	k.take_damage(1.0, null)
	_ok(not k.has_status(&"braced"), "low_hp_status: nothing above 50 %")
	k.hp = k.max_hp * 0.45
	k.take_damage(1.0, null)
	_ok(k.has_status(&"braced"), "low_hp_status: braced under 50 %")
	kb.hp = kb.max_hp * 0.45
	kb.take_damage(1.0, null)
	_ok(not kb.has_status(&"braced"), "low_hp_status: nothing without the row")
	v.hp = v.max_hp * 0.45
	v.take_damage(1.0, null)
	_ok(v.has_status(&"shroud"), "low_hp_status: Veil Ride shroud")
	await _physics(300)   # 5 s: braced (4 s) ended
	_ok(not k.has_status(&"braced"), "low_hp_status: braced ended")
	k.take_damage(1.0, null)
	_ok(not k.has_status(&"braced"), "low_hp_status: not again within 30 s")
	await _clear([k, kb, v])


func _check_kill_status() -> void:
	var base := Vector3(600, 0, 0)
	var s := _spawn("stagrunner", A, base)
	var victim := _spawn("shade", B, base + Vector3(1.2, 0, 0))
	var sb := _spawn("stagrunner", B, base + Vector3(0, 0, 60))
	var victim_b := _spawn("shade", A, base + Vector3(1.2, 0, 60))
	for u: Unit in [victim, victim_b]:
		u.attacks_blocked = true
		u.command_hold()
	await _physics(3)
	victim.hp = 1.0
	victim_b.hp = 1.0
	s.command_attack(victim)
	sb.command_attack(victim_b)
	await _until(func() -> bool: return not victim.is_alive() and not victim_b.is_alive(), 300)
	_ok(not victim.is_alive() and s.has_status(&"haste"), "kill_status: Wild Gallop haste after a kill")
	_ok(not victim_b.is_alive() and not sb.has_status(&"haste"), "kill_status: nothing without the row")
	await _clear([s, sb, victim, victim_b])


func _check_pack_aura() -> void:
	var base := Vector3(800, 0, 0)
	var h1 := _passive(_spawn("grave_hound", A, base))
	var h2 := _passive(_spawn("grave_hound", A, base + Vector3(3, 0, 0)))
	var lone := _passive(_spawn("grave_hound", A, base + Vector3(0, 0, 60)))
	var hb1 := _passive(_spawn("grave_hound", B, base + Vector3(0, 0, 120)))
	var hb2 := _passive(_spawn("grave_hound", B, base + Vector3(3, 0, 120)))
	await _physics(40)
	var base_dmg := lone.attack_damage
	_ok(absf(h1.attack_damage - base_dmg - 2.0) < 0.01 and absf(h2.attack_damage - base_dmg - 2.0) < 0.01,
			"pack_aura: two hounds within 5 m get +2 (%.1f / %.1f, lone %.1f)" % [h1.attack_damage, h2.attack_damage, base_dmg])
	_ok(not lone.has_modifier(&"aura:research_pack_hunger"), "pack_aura: a lone hound gets nothing")
	_ok(is_equal_approx(hb1.attack_damage, base_dmg), "pack_aura: nothing without the row")
	h2.global_position = base + Vector3(20, 0, 0)
	await _physics(90)   # the aura lingers 1 s
	_ok(is_equal_approx(h1.attack_damage, base_dmg), "pack_aura: gone when the other hound left")
	await _clear([h1, h2, lone, hb1, hb2])


func _check_idle_regen() -> void:
	var base := Vector3(1000, 0, 0)
	var a := _spawn("bramblehorn", A, base)
	var b := _spawn("bramblehorn", B, base + Vector3(0, 0, 60))
	await _physics(3)
	_ok(is_equal_approx(a.get_idle_regen_pct(), 3.0), "idle_regen: Mossback 3 %% / s (%.2f)" % a.get_idle_regen_pct())
	_ok(is_equal_approx(b.get_idle_regen_pct(), 2.0), "idle_regen: 2 %% / s without the row (%.2f)" % b.get_idle_regen_pct())
	await _clear([a, b])


func _check_save() -> void:
	var base := Vector3(1200, 0, 0)
	var h := _spawn("grave_hound", A, base)
	await _physics(3)
	var base_max := float(UnitType.find("grave_hound").max_hp)
	var want_max := roundf(base_max * 1.25)
	_ok(h.has_modifier(&"research:grave_hound_bone_fed") and absf(h.max_hp - want_max) < 0.01,
			"save: Bone-Fed applied (%.1f)" % h.max_hp)
	h.hp = base_max + 10.0
	var d := h.save_snapshot({})
	_ok((d["mods"] as Dictionary).has("research:grave_hound_bone_fed"), "save: the research modifier is saved")
	# A load: the rebuilt unit gets the saved modifiers before UnitResearch re-applies its rows.
	UnitResearch.lab_off = true
	var h2 := _spawn("grave_hound", A, base + Vector3(0, 0, 10))
	await _physics(3)
	_ok(not h2.has_modifier(&"research:grave_hound_bone_fed"), "save: the rebuilt unit starts without the row")
	h2.load_snapshot_base(d, {})
	h2.load_snapshot_late(d, {}, {})
	UnitResearch.lab_off = false
	_ok(absf(h2.hp - (base_max + 10.0)) < 0.01, "save: a damaged unit keeps its HP above the base max (%.1f)" % h2.hp)
	UnitResearch.apply_to(h2, false)
	_ok(absf(h2.max_hp - want_max) < 0.01 and absf(h2.hp - (base_max + 10.0)) < 0.01,
			"save: the re-apply never doubles nor heals (%.1f / %.1f)" % [h2.hp, h2.max_hp])
	await _clear([h, h2])
