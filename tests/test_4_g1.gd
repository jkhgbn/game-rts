extends SceneTree
## Task 4.G1: item effect hooks (docs/design/items.md): shield, burn DoT, lifesteal + attack_landed,
## Searing Strikes, Rally aura (Horn, Banner override, drop after leaving), spell power on Fireball +
## spell_hit + Smoulder, cooldown reduction and its cap, stat caps.
## Run: godot --headless --path . -s tests/test_4_g1.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "4.G1"
const TIMEOUT_FRAMES := 900

var main: Node
var frame := 0
var _wait := 0
var _errors: Array[String] = []

var h            # Vessa (untyped: test scripts compile before autoloads)
var s_burn: Unit
var s_ls: Unit
var s_fb: Unit
var f_near: Unit
var f_far: Unit
var landed_sum := 0.0
var landed_count := 0
var hero_hp_start := 0.0
var burn_hp_start := 0.0
var fb_hp_start := 0.0
var fb_expected := 0.0
var spell_hits: Array = []
var ember_base := 0.0


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
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
	match frame:
		5:
			_setup()
		45:
			_check_horn()
		85:
			_check_banner()
		160:
			_check_burn_and_fireball()
		175:
			_check_aura_dropped()
		260:
			_check_lifesteal_and_cdr()
			if _errors.is_empty():
				print("PASS %s" % TASK_ID)
			else:
				print("FAIL %s: %s" % [TASK_ID, " | ".join(_errors)])
			return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out" % TASK_ID)
		return true
	return false


func _expect(cond: bool, what: String) -> void:
	if not cond:
		_errors.append(what)


func _spawn(type_id: String, team: int, offset: Vector3, hp: float = 0.0) -> Unit:
	var u: Unit = main.make_unit(type_id)
	u.team = team
	if hp > 0.0:
		u.max_hp = hp
	main.add_child(u)
	u.global_position = h.global_position + offset
	u.command_stop()
	u.aggro_range = 0.0
	u.attack_damage = 0.0
	return u


func _setup() -> void:
	h = main.hero
	# --- Shield absorbs before HP (after armor), a new one replaces the old, it expires.
	var g := _spawn("flame_guard", 0, Vector3(0, 0, 30))
	var g_hp: float = g.hp
	g.add_shield(50.0, 4.0)
	g.take_damage(30.0, null)
	_expect(is_equal_approx(g.hp, g_hp) and is_equal_approx(g.shield, 20.0),
			"shield absorbs 30 of 50 (hp %.1f -> %.1f, shield %.1f)" % [g_hp, g.hp, g.shield])
	g.take_damage(30.0, null)
	_expect(is_equal_approx(g.hp, g_hp - 10.0) and g.shield == 0.0, "overflow hits HP (hp %.1f)" % g.hp)
	g.add_shield(40.0, 4.0)
	g.add_shield(25.0, 4.0)
	_expect(is_equal_approx(g.shield, 25.0) and g.has_status(&"shield"), "a new shield replaces the old")
	# Armor per items.md: 25 armor -> a 100 hit deals 80.
	g.add_modifier(&"test_armor", {"armor": 25.0})
	g.add_shield(0.0, 0.0)
	var before: float = g.hp
	g.take_damage(50.0, null)
	_expect(is_equal_approx(before - g.hp, 40.0), "armor 25: 50 -> 40 (got %.2f)" % (before - g.hp))
	g.queue_free()

	# --- Stat caps (items.md): items give at most 40 CDR, 60 spell power (balance-1), lifesteal 30 total.
	h.add_modifier(&"item:8", {"cooldown_reduction": 30.0, "spell_power": 70.0, "armor": 100.0})
	h.add_modifier(&"item:9", {"cooldown_reduction": 30.0, "spell_power": 70.0, "armor": 100.0})
	_expect(is_equal_approx(h.get_stat(&"cooldown_reduction"), 40.0), "CDR cap 40: %.1f" % h.get_stat(&"cooldown_reduction"))
	_expect(is_equal_approx(h.get_stat(&"spell_power"), 60.0), "spell power cap 60")
	_expect(is_equal_approx(h.get_stat(&"armor"), 150.0), "armor item cap 150")
	h.remove_modifier(&"item:8")
	h.remove_modifier(&"item:9")
	h.add_modifier(&"test_ls", {"lifesteal": 55.0})
	_expect(is_equal_approx(h.get_stat(&"lifesteal"), 30.0), "lifesteal cap 30")
	h.remove_modifier(&"test_ls")

	# --- Burn: 4 every 0.5 s for 2 s = 16, refreshed not stacked.
	s_burn = _spawn("shade", 1, Vector3(25, 0, 0), 500.0)
	burn_hp_start = s_burn.hp
	s_burn.apply_dot(&"burn", 4.0, 0.5, 2.0, h)
	s_burn.apply_dot(&"burn", 4.0, 0.5, 2.0, h)
	_expect(s_burn.has_status(&"burn") and is_equal_approx(s_burn.dot_time_left(&"burn"), 2.0),
			"burn applied once (time %.2f)" % s_burn.dot_time_left(&"burn"))

	# --- Spell power +60 on a Fireball, Smoulder passive, spell_hit.
	ItemPassives.attach(h, &"smoulder", &"item:4")
	h.connect(&"spell_hit", func(t: Node3D, amount: float, id: StringName) -> void:
		# ItemPassives connected first, so Smoulder is already on the target here.
		spell_hits.append([t, amount, id, (t as Unit).has_status(&"smoulder") if t is Unit else false]))
	s_fb = _spawn("shade", 1, Vector3(0, 0, -12), 1000.0)
	fb_hp_start = s_fb.hp
	h.add_modifier(&"test_sp", {"spell_power": 60.0})
	var fb: SpellType = SpellType.find(&"fireball")
	fb_expected = fb.damage_at(h.spell_rank(&"fireball")) * 1.6
	h.mana = h.max_mana
	var reason: String = h.command_cast(&"fireball", s_fb.global_position)
	_expect(reason == "", "fireball cast: %s" % reason)
	h.remove_modifier(&"test_sp")

	# --- Lifesteal (Grave Pact Feed 12 %) + Searing Strikes (Blazing Edge) on auto-attacks.
	s_ls = _spawn("shade", 1, Vector3(-5, 0, 0), 2000.0)
	ItemPassives.attach(h, &"grave_pact", &"item:1")
	ItemPassives.attach(h, &"blazing_edge", &"item:2")
	ItemPassives.attach(h, &"blazing_edge", &"item:5")   # two copies: one passive
	_expect(ItemPassives.active_ids(h).count(&"searing_strikes") == 1, "unique passive once")
	_expect(is_equal_approx(h.get_stat(&"lifesteal"), 12.0), "Feed = 12 lifesteal")
	h.attack_landed.connect(func(_t: Node3D, amount: float) -> void:
		landed_sum += amount
		landed_count += 1)
	h.hp = 100.0
	hero_hp_start = h.hp
	h.command_attack(s_ls)

	# --- Rally aura (Warlord's Horn): soldiers within 8 m.
	f_near = _spawn("flame_guard", 0, Vector3(0, 0, 4))
	f_far = _spawn("flame_guard", 0, Vector3(0, 0, 20))
	ItemPassives.attach(h, &"warlords_horn", &"item:3")


func _check_horn() -> void:
	var base: float = f_near.get_base_stat(&"attack_damage")
	_expect(f_near.has_modifier(&"aura:rally"), "Rally reaches a soldier at 4 m within 0.5 s")
	_expect(is_equal_approx(f_near.get_stat(&"attack_damage"), base * 1.10),
			"Rally +10 %% (%.2f vs base %.2f)" % [f_near.get_stat(&"attack_damage"), base])
	_expect(not f_far.has_modifier(&"aura:rally"), "no Rally at 20 m")
	_expect(not h.has_modifier(&"aura:rally"), "the wizard is not a soldier")
	ItemPassives.attach(h, &"banner_of_embers", &"item:6")


func _check_banner() -> void:
	var base: float = f_near.get_base_stat(&"attack_damage")
	_expect(is_equal_approx(f_near.get_stat(&"attack_damage"), base * 1.15),
			"Banner overrides Horn: +15 %% (%.2f)" % f_near.get_stat(&"attack_damage"))
	_expect(ItemPassives.active_ids(h).has(&"rally_2") and not ItemPassives.active_ids(h).has(&"rally"),
			"Rally II wins")
	f_near.global_position = h.global_position + Vector3(0, 0, 30)


func _check_burn_and_fireball() -> void:
	var lost: float = burn_hp_start - s_burn.hp
	_expect(is_equal_approx(lost, 16.0), "burn dealt 16 over 2 s (got %.2f)" % lost)
	_expect(not s_burn.has_status(&"burn"), "burn ended")
	var fb_lost: float = fb_hp_start - s_fb.hp
	_expect(absf(fb_lost - fb_expected) < 0.01, "Fireball x1.6 with 60 spell power: %.2f vs %.2f" % [fb_lost, fb_expected])
	var hit_ok := false
	for e: Array in spell_hits:
		if e[0] == s_fb and e[2] == &"fireball" and absf(float(e[1]) - fb_lost) < 0.01:
			hit_ok = true
			_expect(bool(e[3]), "Smoulder passive applied on the spell hit")
	_expect(hit_ok, "spell_hit(target, %.1f, fireball) fired (%d hits)" % [fb_lost, spell_hits.size()])
	# Smoulder lasts 1.5 s after the hit (the Fireball landed ~0.8 s after the cast): re-apply to measure.
	s_fb.apply_status(&"smoulder", 1.5)
	_expect(is_equal_approx(s_fb.get_stat(&"move_speed"), maxf(0.0, s_fb.get_base_stat(&"move_speed") - 1.5)),
			"smoulder slows 1.5 m/s")


func _check_aura_dropped() -> void:
	# Moved away at frame 85: gone within 1 s + one refresh (frame 175 = 1.5 s later).
	_expect(not f_near.has_modifier(&"aura:rally"), "Rally drops after leaving the radius")
	var base: float = f_near.get_base_stat(&"attack_damage")
	_expect(is_equal_approx(f_near.get_stat(&"attack_damage"), base), "damage back to base")


func _check_lifesteal_and_cdr() -> void:
	_expect(landed_count >= 2, "attack_landed fired (%d)" % landed_count)
	_expect(landed_count == 0 or absf(landed_sum / landed_count - h.get_stat(&"attack_damage")) < 0.01,
			"attack_landed amount = damage dealt (%.2f)" % (landed_sum / maxf(1.0, landed_count)))
	var healed: float = h.hp - hero_hp_start
	_expect(absf(healed - landed_sum * 0.12) < 0.05,
			"lifesteal 12 %%: healed %.2f for %.2f dealt" % [healed, landed_sum])
	_expect(s_ls.has_status(&"burn") or s_ls.hp < 2000.0 - landed_sum - 0.01, "Searing Strikes burned the target")
	# CDR: Ember Step 12 s -> 9.6 with 20, 40 cap.
	var caster = h.spell_caster
	var es: SpellType = SpellType.find(&"ember_step")
	var base_cd: float = es.cooldown_at(1)
	caster.set_rank(&"ember_step", 1)
	h.add_modifier(&"item:7", {"cooldown_reduction": 20.0})
	_expect(is_equal_approx(caster.cooldown_total(&"ember_step"), base_cd * 0.8),
			"CDR 20: %.2f (base %.2f)" % [caster.cooldown_total(&"ember_step"), base_cd])
	h.mana = h.max_mana
	var reason: String = caster.cast(&"ember_step", h.global_position + Vector3(2, 0, 0))
	_expect(reason == "" and is_equal_approx(caster.cooldown_left(&"ember_step"), base_cd * 0.8),
			"cast Ember Step: cooldown %.2f (%s)" % [caster.cooldown_left(&"ember_step"), reason])
	h.add_modifier(&"item:7", {"cooldown_reduction": 90.0})
	_expect(is_equal_approx(caster.cooldown_total(&"ember_step"), base_cd * 0.8), "running cooldown total unchanged")
	_expect(is_equal_approx(SpellCaster.cooldown_multiplier(h.get_stat(&"cooldown_reduction")), 0.6),
			"CDR respects the 40 cap")
	# Detach: passives go away.
	ItemPassives.detach_source(h, &"item:1")
	_expect(is_equal_approx(h.get_stat(&"lifesteal"), 0.0), "Feed removed on detach")
