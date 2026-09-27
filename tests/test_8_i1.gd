extends SceneTree
## Task 8.I1: the 4 Nature items (kingdom-nature.md section 5) with their numbers and recipes, and
## Barbs (melee attackers take 20 % of the damage they deal, shield included), Blossom (spell heals /
## shields x1.25 after spell_power: Wild Bloom rank 1 = 60 x 1.25 = 75 before the staff's own spell
## power), Verdant Ward (soldiers within 10 m +2 hp_regen) and Overgrowth (friendly units within 8 m
## heal 100 over 5 s, cooldown 80).
## Run: godot --headless --path . -s tests/test_8_i1.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "8.i1"
const AURA_FRAMES := 30          # 0.5 s: the aura (0.25 s tick) reached the soldier
const HOT_FRAMES := 320          # 5.33 s: Overgrowth (5 s) is done
const TIMEOUT_FRAMES := 600

var main: Node
var frame := 0
var _wait := 0
var _fail := ""
var hero
var inv
var actives
var soldier
var far_soldier
var _soldier_hp0 := 0.0
var _regen_before := 0.0


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
	if frame == 1:
		_setup()
	elif frame == 1 + AURA_FRAMES and _fail == "":
		_check_aura()
	elif frame == 1 + HOT_FRAMES and _fail == "":
		_check_overgrowth()
		if _fail == "":
			print("PASS %s" % TASK_ID)
			return true
	if _fail != "":
		print("FAIL %s: %s" % [TASK_ID, _fail])
		return true
	if frame > TIMEOUT_FRAMES:
		print("FAIL %s: timed out" % TASK_ID)
		return true
	return false


func _setup() -> void:
	hero = main.hero
	inv = hero.inventory
	_expect(inv != null, "the hero has no inventory")
	if _fail != "":
		return
	# --- Data (kingdom-nature.md 5)
	_check_item(&"verdant_seed", ItemType.Tier.COMPONENT, 180, {&"hp_regen": 2.0, &"max_hp": 30.0})
	_check_item(&"thornweave_vest", ItemType.Tier.MID, 610, {&"armor": 18.0, &"hp_regen": 2.0})
	_check_item(&"bloomcaller_staff", ItemType.Tier.MID, 630,
			{&"spell_power": 20.0, &"hp_regen": 2.0, &"max_mana": 30.0})
	_check_item(&"heart_of_the_grove", ItemType.Tier.TOP, 1910,
			{&"spell_power": 35.0, &"max_hp": 200.0, &"hp_regen": 4.0})
	if _fail != "":
		return
	var vest := ItemType.find(&"thornweave_vest")
	var staff := ItemType.find(&"bloomcaller_staff")
	var heart := ItemType.find(&"heart_of_the_grove")
	_expect(vest.passive_id == &"barbs" and ItemPassives.is_known(vest.passive_id), "vest passive barbs")
	_expect(staff.passive_id == &"blossom" and ItemPassives.is_known(staff.passive_id), "staff passive blossom")
	_expect(heart.passive_id == &"verdant_ward" and ItemPassives.is_known(heart.passive_id), "heart passive")
	_expect(ItemActives.effect_key(heart) == &"overgrowth" and ItemActives.target_kind(heart) == "self"
			and is_equal_approx(heart.active_cooldown, 80.0), "heart active overgrowth / self / 80 s")
	_expect(ItemActives.effect_key(vest) == &"" and ItemActives.effect_key(staff) == &"",
			"vest / staff should have no active")
	# --- Recipes
	_clear()
	inv.add_item(ItemType.find(&"verdant_seed"))
	inv.add_item(ItemType.find(&"ironbark_plate"))
	var p: Dictionary = Recipes.plan(inv, vest)
	_expect(int(p["essence_cost"]) == 250 and (p["consume_slots"] as Array).size() == 2,
			"vest from both parts should cost 250, got %s" % [p])
	_clear()
	inv.add_item(staff)
	p = Recipes.plan(inv, heart)
	_expect(int(p["essence_cost"]) == 1910 - 630 and (p["consume_slots"] as Array).size() == 1,
			"heart with the staff should cost 1280, got %s" % [p])
	_clear()
	if _fail != "":
		return
	_check_blossom(staff)
	_check_barbs(vest)
	if _fail != "":
		return
	_start_overgrowth(heart)


# Blossom: x1.25 on spell heals / shields, only while the staff is carried.
func _check_blossom(staff: ItemType) -> void:
	_expect(is_equal_approx(ItemPassives.heal_multiplier(hero), 1.0), "heal multiplier without Blossom")
	inv.add_item(staff)
	var mult := ItemPassives.heal_multiplier(hero)
	_expect(is_equal_approx(mult, 1.25), "Blossom multiplier should be 1.25, got %.3f" % mult)
	var bloom := load("res://data/spells/wild_bloom.tres")
	var base_heal := 60.0
	if bloom and bloom.has_method(&"heal_at"):
		base_heal = float(bloom.call(&"heal_at", 1))
	elif bloom and bloom.get(&"heal_amount") != null:
		base_heal = float(bloom.get(&"heal_amount"))
	_expect(is_equal_approx(base_heal * mult, 75.0),
			"Wild Bloom rank 1 with Blossom should heal 75 (before spell power), got %.1f" % (base_heal * mult))
	var sp: float = hero.get_stat(&"spell_power")
	print("8.i1: Wild Bloom rank 1 with the staff equipped: 60 x %.2f (spell power %d) x 1.25 = %.1f"
			% [1.0 + sp / 100.0, int(sp), 60.0 * (1.0 + sp / 100.0) * mult])
	_clear()
	_expect(is_equal_approx(ItemPassives.heal_multiplier(hero), 1.0), "Blossom should end with the staff")


# Barbs: 20 % of the damage a melee attacker deals (HP + shield, after the wizard's armor) goes back.
func _check_barbs(vest: ItemType) -> void:
	inv.add_item(vest)
	var enemy: Unit = _spawn(&"flame_guard", Unit.Team.ENEMY, Vector3(25, 0, 0))
	_expect(enemy != null and enemy.attack_range <= 3.0, "no melee enemy to test Barbs")
	if _fail != "":
		return
	enemy.add_modifier(&"test_8_i1", {&"max_hp": 1000.0})
	var emult := Unit.armor_multiplier(enemy.get_stat(&"armor"))
	hero.heal(10000.0)
	# Melee hit on HP
	var h0: float = hero.hp
	var e0: float = enemy.hp
	hero.take_damage(50.0, enemy)
	var lost: float = h0 - hero.hp
	var back: float = e0 - enemy.hp
	_expect(lost > 1.0 and absf(back - lost * 0.2 * emult) < 0.01,
			"Barbs: hero lost %.2f, attacker should lose %.2f, lost %.2f" % [lost, lost * 0.2 * emult, back])
	# A ranged attacker is not hurt
	enemy.attack_range = 8.0
	e0 = enemy.hp
	hero.take_damage(50.0, enemy)
	_expect(is_equal_approx(enemy.hp, e0), "Barbs hurt a ranged attacker")
	enemy.attack_range = 1.5
	# A hit fully absorbed by a shield still reflects
	hero.heal(10000.0)
	hero.add_shield(1000.0, 5.0)
	h0 = hero.hp
	e0 = enemy.hp
	hero.take_damage(50.0, enemy)
	var absorbed: float = 1000.0 - hero.shield
	back = e0 - enemy.hp
	_expect(is_equal_approx(hero.hp, h0) and absorbed > 1.0, "the shield should take the whole hit")
	_expect(absf(back - absorbed * 0.2 * emult) < 0.01,
			"Barbs through a shield: expected %.2f back, got %.2f" % [absorbed * 0.2 * emult, back])
	hero.add_shield(0.0, 0.0)
	enemy.die()
	_clear()


# Overgrowth + Verdant Ward: a hurt soldier next to the wizard, one 20 m away.
func _start_overgrowth(heart: ItemType) -> void:
	soldier = _spawn(&"flame_guard", Unit.Team.PLAYER, Vector3(3, 0, 0))
	far_soldier = _spawn(&"flame_guard", Unit.Team.PLAYER, Vector3(20, 0, 0))
	_expect(soldier != null and far_soldier != null, "could not spawn test soldiers")
	if _fail != "":
		return
	_regen_before = soldier.get_stat(&"hp_regen")
	soldier.add_modifier(&"test_8_i1", {&"max_hp": 1000.0})
	soldier.hp = 50.0
	far_soldier.add_modifier(&"test_8_i1", {&"max_hp": 1000.0})
	far_soldier.hp = 50.0
	_soldier_hp0 = soldier.hp
	inv.add_item(heart)
	var slot: int = inv.find_slot(&"heart_of_the_grove")
	var reason: String = inv.use_item(slot, null)
	_expect(reason == "", "Overgrowth refused: %s" % reason)
	_expect(inv.use_item(slot, null) == "On cooldown", "second Overgrowth should be on cooldown")
	actives = ItemActives.for_inventory(inv)
	var cdr: float = hero.get_stat(&"cooldown_reduction")
	_expect(absf(actives.cooldown_left(slot) - 80.0 * (1.0 - cdr / 100.0)) < 0.1,
			"Overgrowth cooldown should be 80, got %.2f" % actives.cooldown_left(slot))


func _check_aura() -> void:
	_expect(soldier.has_modifier(&"aura:verdant_ward"), "Verdant Ward did not reach the soldier at 3 m")
	_expect(absf(soldier.get_stat(&"hp_regen") - _regen_before - 2.0) < 0.01,
			"Verdant Ward should give +2 hp_regen (%.2f -> %.2f)" % [_regen_before, soldier.get_stat(&"hp_regen")])
	_expect(not far_soldier.has_modifier(&"aura:verdant_ward"), "Verdant Ward reached a soldier 20 m away")


func _check_overgrowth() -> void:
	var gained: float = soldier.hp - _soldier_hp0
	var regen: float = soldier.get_stat(&"hp_regen") * HOT_FRAMES / 60.0
	_expect(gained >= 99.5 and gained <= 100.5 + regen + 1.0,
			"Overgrowth should heal 100 over 5 s (+ %.1f regen), healed %.1f" % [regen, gained])
	var far_gained: float = far_soldier.hp - 50.0
	_expect(far_gained < 50.0, "Overgrowth healed a soldier 20 m away (%.1f)" % far_gained)
	_clear()


func _spawn(type_id: StringName, team: int, offset: Vector3) -> Unit:
	var u: Unit = main.make_unit(String(type_id))
	if u == null:
		return null
	u.team = team
	main.add_child(u)
	u.global_position = hero.global_position + offset
	u.command_stop()
	return u


func _clear() -> void:
	for i in 6:
		inv.remove_item(i)


func _check_item(id: StringName, tier: int, total: int, stats: Dictionary) -> void:
	var t := ItemType.find(id)
	if t == null:
		_fail = "missing data/items/%s.tres" % id
		return
	_expect(int(t.tier) == tier, "%s tier %d" % [id, t.tier])
	_expect(t.total_cost() == total, "%s total cost %d, expected %d" % [id, t.total_cost(), total])
	_expect(t.is_sold_at(ItemType.SOLD_BASE), "%s not sold at base shops" % id)
	_expect(t.stats.size() == stats.size(), "%s has %d stats, expected %d" % [id, t.stats.size(), stats.size()])
	for k: StringName in stats:
		_expect(is_equal_approx(float(t.stats.get(String(k), t.stats.get(k, -1.0))), float(stats[k])),
				"%s stat %s = %s" % [id, k, t.stats.get(String(k))])


func _expect(ok: bool, msg: String) -> void:
	if not ok and _fail == "":
		_fail = msg
