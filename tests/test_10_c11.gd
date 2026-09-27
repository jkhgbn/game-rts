extends SceneTree
## Task 10.C11 (docs/design/market-trade.md 3 + 12 + "Done when" 10.C11): GoldBank and the Building HP multiplier.
## Mission 1 map (trade off: no bank exists until the test creates them with GoldBank.create).
## Checks: for_team null with trade off; start 0; add / spend / can_afford / changed(gold) / spend_failed;
## earned per source; the 4 wares (prices, refusals in order, effects: Axles on caravans only, Tempered Steel and
## Gambesons on soldiers only - not workers, caravans, wizards, champions, trackers or the other team - on living
## and future units, idempotent apply_wares); Masons' Charter: the 2500 keep -> 2875 healed by 375, a site under
## construction and a site started after the purchase finish at x 1.15, a new building starts at x 1.15, the other
## team is unchanged; exchange 100 -> 80 crystals / 40 essence (Shift x5) with an own completed Bazaar only.
## The Bazaar is a stub (a plain Building with kind &"market"); caravans / trackers are stubs (UnitType ids).
## Run:  godot --headless --path . -s tests/test_10_c11.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "10.C11"
const TIMEOUT_FRAMES := 1500
const SETUP := 5
const CHARTER_AT := SETUP + 30
const KEEP_DAMAGE := 500.0
const ENEMY_BASE := Vector3(30.0, 0.0, 30.0)   # no buildings there on the mission 1 map (test_8_s1 uses it)
const BANK_SCRIPT := "res://scripts/economy/gold_bank.gd"

var main: Node
var frame := 0
var _wait := 0
var _errors: Array[String] = []
var _done := {}

var _bank: Node          # team 0 GoldBank (untyped on purpose: the class is new in this step)
var _bank_enemy: Node
var _changed := 0
var _last_changed := -1
var _failed := 0
var _bought: Array = []

var _soldier: Unit
var _soldier_dmg := 0.0
var _soldier_armor := 0.0
var _worker: Unit
var _caravan: Unit
var _caravan_speed := 0.0
var _caravan_hp := 0.0
var _tracker: Unit
var _champion: Unit
var _enemy_soldier: Unit
var _late_soldier: Unit
var _late_dmg_base := 0.0

var _bazaar: Building
var _hearth_type: BuildingType
var _site_pre: Building
var _site_post: Building
var _new_building: Building
var _enemy_building: Building
var _keep_base := 0.0


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
	if frame == SETUP:
		_setup_gold()
		_setup_units()
		_setup_buildings()
	elif frame == SETUP + 2:
		_check_wares()
	elif frame == SETUP + 4:
		_check_late_unit()
	elif frame == CHARTER_AT:
		_check_charter()
		_check_exchange()
	elif frame > CHARTER_AT:
		_tick_sites()
	if not _errors.is_empty():
		return _finish()
	if _done.size() >= 5:
		return _finish()
	if frame > TIMEOUT_FRAMES:
		_errors.append("timed out (done: %s)" % str(_done.keys()))
		return _finish()
	return false


func _finish() -> bool:
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
	return true


# ---------------------------------------------------------------- gold

func _setup_gold() -> void:
	var script: GDScript = load(BANK_SCRIPT)
	if main.get(&"trade_enabled") != true:
		if script.for_team(0) != null or script.for_team(1) != null:
			_errors.append("for_team is not null with trade off")
		if script.trade_active():
			_errors.append("trade_active() true with trade off")
	_bank = script.create(main, 0)
	_bank_enemy = script.create(main, 1)
	if script.create(main, 0) != _bank:
		_errors.append("create() made a second bank for team 0")
	if script.for_team(0) != _bank or script.for_team(1) != _bank_enemy or not _bank.is_in_group(&"gold_banks"):
		_errors.append("for_team does not find the created banks")
	if script.START_GOLD != 0 or _bank.gold != 0:
		_errors.append("start gold %d" % _bank.gold)
	_bank.changed.connect(func(g: int) -> void:
		_changed += 1
		_last_changed = g)
	_bank.spend_failed.connect(func() -> void: _failed += 1)
	_bank.ware_bought.connect(func(id: StringName) -> void: _bought.append(id))
	_bank.add(100, &"trade")
	_bank.add(30, &"loot")
	_bank.add(10, &"reward")
	if _bank.gold != 140 or _bank.earned() != 140 or _bank.earned(&"trade") != 100 or _bank.earned(&"loot") != 30 \
			or _bank.earned(&"reward") != 10:
		_errors.append("add / earned: gold %d, total %d, trade %d" % [_bank.gold, _bank.earned(), _bank.earned(&"trade")])
	if not _bank.can_afford(140) or _bank.can_afford(141):
		_errors.append("can_afford wrong")
	if _bank.spend(500) or _failed != 1 or _bank.gold != 140:
		_errors.append("spend(500) with 140: failed signals %d, gold %d" % [_failed, _bank.gold])
	if not _bank.spend(40) or _bank.gold != 100:
		_errors.append("spend(40) failed")
	if _changed != 4 or _last_changed != 100:
		_errors.append("changed emitted %d times, last %d" % [_changed, _last_changed])
	if _bank.earned() != 140:
		_errors.append("spending changed earned()")
	if _bank_enemy.gold != 0:
		_errors.append("enemy bank got gold")


# ---------------------------------------------------------------- units

func _setup_units() -> void:
	var home: Vector3 = main.keep.global_position + Vector3(10.0, 0.0, 0.0)
	_soldier = _spawn(UnitType.find("flame_guard"), home, 0)
	_worker = _spawn(UnitType.find("cinder_hand"), home + Vector3(2.0, 0.0, 0.0), 0)
	_caravan = _spawn(_stub_type(&"caravan"), home + Vector3(0.0, 0.0, 2.0), 0)
	_tracker = _spawn(_stub_type(&"greywater_tracker"), home + Vector3(2.0, 0.0, 2.0), 0, &"trackers")
	_enemy_soldier = _spawn(UnitType.find("shade"), home + Vector3(0.0, 0.0, 60.0), 1)
	# A real Champion when champion.gd loads (load-guarded: the test must not fail to compile with it),
	# else a plain unit in group "champions" (Champion._init puts every champion there).
	var champ: Unit = null
	var cs: Variant = load("res://scripts/units/champion.gd") if ResourceLoader.exists("res://scripts/units/champion.gd") else null
	if cs is GDScript and (cs as GDScript).can_instantiate():
		champ = (cs as GDScript).new() as Unit
		var ts: Variant = load("res://scripts/units/champion_type.gd") \
				if ResourceLoader.exists("res://scripts/units/champion_type.gd") else null
		if champ and ts is GDScript and (ts as GDScript).can_instantiate():
			var types: Variant = (ts as GDScript).call(&"all")
			if types is Array and not (types as Array).is_empty():
				champ.call(&"apply_champion_type", types[0])
	if champ == null:
		champ = _stub_type(&"champion_stub").create_unit()
		champ.add_to_group(&"champions")
	champ.team = Unit.Team.PLAYER
	main.add_child(champ)
	champ.global_position = home + Vector3(-2.0, 0.0, 2.0)
	_champion = champ


func _stub_type(id: StringName) -> UnitType:
	var t: UnitType = UnitType.find("flame_guard").duplicate()
	t.id = id
	t.aggro_range = 0.0
	return t


func _spawn(type: UnitType, pos: Vector3, team: int, group: StringName = &"") -> Unit:
	var u: Unit = main.make_unit(String(type.id)) if ResourceLoader.exists(UnitType.DIR + String(type.id) + ".tres") \
			and type == UnitType.find(String(type.id)) else type.create_unit()
	u.team = team as Unit.Team
	if group != &"":
		u.add_to_group(group)
	main.add_child(u)
	u.global_position = pos
	u.command_stop()
	return u


func _check_wares() -> void:
	var soldiers_ids := [&"tempered_steel", &"gambesons"]
	var prices := {&"iron_axles": 150, &"masons_charter": 350, &"tempered_steel": 350, &"gambesons": 350}
	var script: GDScript = load(BANK_SCRIPT)
	for id: StringName in prices:
		if script.ware_price(id) != prices[id] or not script.WARES.has(id):
			_errors.append("ware %s price %d" % [id, script.ware_price(id)])
	if script.EXCHANGE != {&"crystals": 80, &"essence": 40}:
		_errors.append("EXCHANGE %s" % str(script.EXCHANGE))
	# No Bazaar yet (the site is not finished): "No Bazaar" first, whatever the gold.
	if _bank.can_buy_ware(&"tempered_steel") != "No Bazaar":
		_errors.append("no Bazaar: '%s'" % _bank.can_buy_ware(&"tempered_steel"))
	if _bank.exchange(100, &"crystals") != "No Bazaar":
		_errors.append("exchange without a Bazaar was not refused")
	# Complete the Bazaar.
	var bazaar_type := _market_type()
	_bazaar = Building.new()
	_bazaar.building_type = bazaar_type
	_bazaar.team = Unit.Team.PLAYER
	var bp: Vector3 = main.build_grid.find_spot(bazaar_type, main.keep.global_position + Vector3(4.0, 0.0, -12.0),
			Unit.Team.PLAYER)
	if bp == Vector3.INF:
		_errors.append("no spot for the Bazaar")
		return
	_bazaar.position = bp
	main.add_child(_bazaar)
	if not _bank.has_bazaar():
		_errors.append("a completed Bazaar is not seen")
		return
	# 100 gold: not enough for a ware.
	var failed_before := _failed
	if _bank.buy_ware(&"tempered_steel") != "Not enough gold" or _failed != failed_before + 1:
		_errors.append("100 gold: ware not refused with 'Not enough gold' + spend_failed")
	_soldier_dmg = _soldier.get_stat(&"attack_damage")
	_soldier_armor = _soldier.get_stat(&"armor")
	_caravan_speed = _caravan.get_stat(&"move_speed")
	_caravan_hp = _caravan.max_hp
	var others := [_worker, _caravan, _tracker, _champion, main.hero, _enemy_soldier]
	var before := []
	for u: Unit in others:
		before.append([u.get_stat(&"attack_damage"), u.get_stat(&"armor")])
	_bank.add(3000, &"trade")
	for id: StringName in [&"tempered_steel", &"gambesons", &"iron_axles"]:
		var r: String = _bank.buy_ware(id)
		if r != "":
			_errors.append("buy %s: '%s'" % [id, r])
	if _bank.gold != 3100 - 850:
		_errors.append("gold after 3 wares %d, expected 2250" % _bank.gold)
	if _bought != [&"tempered_steel", &"gambesons", &"iron_axles"]:
		_errors.append("ware_bought signals %s" % str(_bought))
	if _bank.buy_ware(&"tempered_steel") != "Already owned":
		_errors.append("second Tempered Steel not refused")
	# Effects on the living soldier.
	if not is_equal_approx(_soldier.get_stat(&"attack_damage"), _soldier_dmg * 1.08) \
			or not _soldier.has_modifier(&"ware:tempered_steel"):
		_errors.append("soldier damage %.2f, expected %.2f" % [_soldier.get_stat(&"attack_damage"), _soldier_dmg * 1.08])
	if not is_equal_approx(_soldier.get_stat(&"armor"), _soldier_armor + 10.0) or not _soldier.has_modifier(&"ware:gambesons"):
		_errors.append("soldier armor %.1f, expected %.1f" % [_soldier.get_stat(&"armor"), _soldier_armor + 10.0])
	if _soldier.has_modifier(&"ware:iron_axles"):
		_errors.append("Iron-shod Axles on a soldier")
	# Nobody else gets the soldier wares.
	for i in others.size():
		var u: Unit = others[i]
		if u.has_modifier(&"ware:tempered_steel") or u.has_modifier(&"ware:gambesons") \
				or not is_equal_approx(u.get_stat(&"attack_damage"), before[i][0]) \
				or not is_equal_approx(u.get_stat(&"armor"), before[i][1]):
			_errors.append("soldier ware on %s (%s)" % [u.unit_name, u.name])
	# Axles on the caravan only: +0.5 speed, +60 max HP, the gain healed.
	if not is_equal_approx(_caravan.get_stat(&"move_speed"), _caravan_speed + 0.5) \
			or not is_equal_approx(_caravan.max_hp, _caravan_hp + 60.0) or not is_equal_approx(_caravan.hp, _caravan.max_hp):
		_errors.append("caravan speed %.2f / hp %.0f of %.0f" % [_caravan.get_stat(&"move_speed"), _caravan.hp, _caravan.max_hp])
	for u: Unit in [_worker, _tracker, _champion, main.hero, _enemy_soldier]:
		if u.has_modifier(&"ware:iron_axles"):
			_errors.append("Iron-shod Axles on %s" % u.name)
	# Idempotent.
	_bank.apply_wares(_soldier)
	_bank.apply_wares(_soldier)
	_bank.apply_wares(_caravan)
	_bank_enemy.apply_wares(_soldier)
	if not is_equal_approx(_soldier.get_stat(&"attack_damage"), _soldier_dmg * 1.08) \
			or not is_equal_approx(_caravan.max_hp, _caravan_hp + 60.0):
		_errors.append("apply_wares is not idempotent")
	# The enemy bank owns nothing: the enemy soldier stays plain even when asked.
	_bank.apply_wares(_enemy_soldier)
	if _enemy_soldier.has_modifier(&"ware:tempered_steel"):
		_errors.append("team 0 wares applied to an enemy unit")
	# A soldier trained after the purchase (checked 2 frames later: Unit._ready or the bank's safety net).
	_late_soldier = _spawn(UnitType.find("flame_guard"), main.keep.global_position + Vector3(12.0, 0.0, -3.0), 0)
	_late_dmg_base = _late_soldier.get_base_stat(&"attack_damage")
	_done["wares"] = true


func _market_type() -> BuildingType:
	var t: BuildingType = BuildingType.find("fire_barracks").duplicate()
	t.id = &"fire_market"
	t.display_name = "Ember Bazaar"
	t.kind = &"market"
	t.max_hp = 1000.0
	return t


func _check_late_unit() -> void:
	if _late_soldier == null:
		return
	if not _late_soldier.has_modifier(&"ware:tempered_steel") or not _late_soldier.has_modifier(&"ware:gambesons") \
			or not is_equal_approx(_late_soldier.get_stat(&"attack_damage"), _late_dmg_base * 1.08):
		_errors.append("a soldier spawned after the purchase has no wares")
	if _late_soldier.has_modifier(&"ware:iron_axles"):
		_errors.append("a new soldier got Iron-shod Axles")
	_done["future_units"] = true


# ---------------------------------------------------------------- Masons' Charter

func _setup_buildings() -> void:
	var grid: BuildGrid = main.build_grid
	_hearth_type = BuildingType.find("fire_hearth").duplicate()
	_hearth_type.build_time = 2.0
	_hearth_type.max_count = 0   # no hearth limit for the test buildings
	_keep_base = main.keep.max_hp
	if _keep_base != main.keep.building_type.max_hp:
		_errors.append("keep max HP %.0f before the Charter, type %.0f" % [_keep_base, main.keep.building_type.max_hp])
	main.keep.take_damage(KEEP_DAMAGE, null)
	_site_pre = _make_site(main.keep.global_position + Vector3(12.0, 0.0, -8.0), Unit.Team.PLAYER)
	var ep: Vector3 = grid.find_spot(_hearth_type, ENEMY_BASE, Unit.Team.ENEMY)
	if ep == Vector3.INF:
		_errors.append("no spot for the enemy building")
		return
	_enemy_building = grid.spawn_complete(_hearth_type, ep, Unit.Team.ENEMY)
	# An unfinished Bazaar does not count (in group "markets" like a real Market site).
	var site := Building.new()
	site.building_type = _market_type()
	site.team = Unit.Team.PLAYER
	site.add_to_group(&"markets")
	site.make_site()
	main.add_child(site)
	site.global_position = main.keep.global_position + Vector3(20.0, 0.0, -20.0)
	if _bank.has_bazaar():
		_errors.append("a Bazaar site counts as a Bazaar")


func _make_site(near: Vector3, team: int) -> Building:
	var p: Vector3 = main.build_grid.find_spot(_hearth_type, near, team)
	if p == Vector3.INF:
		_errors.append("no spot for a site near %s" % str(near))
		p = near
	var b := BuildGrid.create_building(_hearth_type)
	b.team = team as Unit.Team
	b.make_site()
	b.position = p
	main.add_child(b)
	b.add_builder(_worker)
	return b


func _check_charter() -> void:
	if _bank.building_hp_mult() != 1.0:
		_errors.append("building_hp_mult %.2f before the Charter" % _bank.building_hp_mult())
	var keep: Building = main.keep
	var hp_before := keep.hp
	var site_ratio := _site_pre.hp / _site_pre.max_hp
	if _site_pre.is_constructed():
		_errors.append("test site finished before the Charter")
	var r: String = _bank.buy_ware(&"masons_charter")
	if r != "":
		_errors.append("buy Masons' Charter: '%s'" % r)
		return
	if not is_equal_approx(_bank.building_hp_mult(), 1.15) or not is_equal_approx(_bank_enemy.building_hp_mult(), 1.0):
		_errors.append("building_hp_mult %.2f / enemy %.2f" % [_bank.building_hp_mult(), _bank_enemy.building_hp_mult()])
	var want := roundf(_keep_base * 1.15)
	if _keep_base == 2500.0 and want != 2875.0:
		_errors.append("2500 x 1.15 rounds to %.0f" % want)
	if keep.max_hp != want or not is_equal_approx(keep.hp - hp_before, want - _keep_base):
		_errors.append("keep %.0f / %.0f after the Charter (was %.0f / %.0f): expected max %.0f, +%.0f HP" % [
				keep.hp, keep.max_hp, hp_before, _keep_base, want, want - _keep_base])
	if not is_equal_approx(keep.hp_mult(), 1.15):
		_errors.append("keep hp_mult %.2f" % keep.hp_mult())
	if _site_pre.max_hp != 575.0 or absf(_site_pre.hp / _site_pre.max_hp - site_ratio) > 0.001:
		_errors.append("site after the Charter: %.1f / %.1f (ratio was %.3f)" % [_site_pre.hp, _site_pre.max_hp, site_ratio])
	if _enemy_building.max_hp != 500.0 or _enemy_building.hp != 500.0:
		_errors.append("enemy building changed: %.0f / %.0f" % [_enemy_building.hp, _enemy_building.max_hp])
	# Idempotent: applying again changes nothing.
	_bank.apply_building_hp_mult()
	if keep.max_hp != want:
		_errors.append("apply_building_hp_mult is not idempotent")
	# Future buildings: a finished one and a new site.
	var np: Vector3 = main.build_grid.find_spot(_hearth_type, keep.global_position + Vector3(18.0, 0.0, -4.0),
			Unit.Team.PLAYER)
	if np == Vector3.INF:
		_errors.append("no spot for the post-Charter building")
		return
	_new_building = main.build_grid.spawn_complete(_hearth_type, np, Unit.Team.PLAYER)
	if _new_building.max_hp != 575.0 or _new_building.hp != 575.0:
		_errors.append("building made after the Charter: %.0f / %.0f" % [_new_building.hp, _new_building.max_hp])
	_site_post = _make_site(keep.global_position + Vector3(8.0, 0.0, -18.0), Unit.Team.PLAYER)
	if _site_post.max_hp != 575.0 or not is_equal_approx(_site_post.hp, 57.5):
		_errors.append("site made after the Charter: %.1f / %.1f" % [_site_post.hp, _site_post.max_hp])
	if _bank.can_buy_ware(&"masons_charter") != "Already owned":
		_errors.append("Charter owned: '%s'" % _bank.can_buy_ware(&"masons_charter"))
	_done["charter"] = true


func _tick_sites() -> void:
	if _done.has("sites") or _site_pre == null or _site_post == null:
		return
	if not (_site_pre.is_constructed() and _site_post.is_constructed()):
		return
	for b: Building in [_site_pre, _site_post]:
		if b.max_hp != 575.0 or absf(b.hp - 575.0) > 0.5:
			_errors.append("site finished at %.1f / %.1f, expected 575" % [b.hp, b.max_hp])
	# Refusal order at the end: with the Bazaar gone, "No Bazaar" comes before "Already owned".
	_bazaar.take_damage(1.0e7, null)
	if _bank.can_buy_ware(&"tempered_steel") != "No Bazaar":
		_errors.append("Bazaar destroyed: '%s'" % _bank.can_buy_ware(&"tempered_steel"))
	if _bank.exchange(100, &"essence") != "No Bazaar":
		_errors.append("exchange after the Bazaar died was not refused")
	_done["sites"] = true


# ---------------------------------------------------------------- exchange

func _check_exchange() -> void:
	var eco := Economy.for_team(0)
	var ess := EssenceBank.for_team(0)
	if eco == null or ess == null:
		_errors.append("no Economy / EssenceBank for team 0")
		return
	if _bank_enemy.exchange(100, &"crystals") != "No Bazaar":
		_errors.append("enemy (no Bazaar) exchange: '%s'" % _bank_enemy.exchange(100, &"crystals"))
	var got := []
	_bank.exchanged.connect(func(g: int, to: StringName, n: int) -> void: got.append([g, to, n]))
	var gold0: int = _bank.gold
	var c0 := eco.crystals
	var r: String = _bank.exchange(100, &"crystals")
	if r != "" or eco.crystals - c0 != 80 or _bank.gold != gold0 - 100:
		_errors.append("100 -> crystals: '%s', +%d crystals, gold %d" % [r, eco.crystals - c0, _bank.gold])
	var e0 := ess.essence
	r = _bank.exchange(500, &"essence")
	if r != "" or ess.essence - e0 != 200 or _bank.gold != gold0 - 600:
		_errors.append("500 -> essence: '%s', +%d essence, gold %d" % [r, ess.essence - e0, _bank.gold])
	if got != [[100, &"crystals", 80], [500, &"essence", 200]]:
		_errors.append("exchanged signals %s" % str(got))
	if _bank.exchange(50, &"crystals") == "":
		_errors.append("50 gold was exchanged")
	if _bank.exchange(100, &"gold") == "":
		_errors.append("exchange to an unknown resource went through")
	# Drain the rest: then "Not enough gold" (+ spend_failed), nothing moves.
	_bank.spend(_bank.gold - 50)
	var failed_before := _failed
	c0 = eco.crystals
	if _bank.exchange(100, &"crystals") != "Not enough gold" or _failed != failed_before + 1 or eco.crystals != c0 \
			or _bank.gold != 50:
		_errors.append("exchange with 50 gold not refused cleanly")
	if _bank.can_buy_ware(&"tempered_steel") != "Already owned":
		_errors.append("owned ware with no gold: '%s' (Already owned comes first)" % _bank.can_buy_ware(&"tempered_steel"))
	if _bank.earned(&"trade") != 3100:
		_errors.append("earned(trade) %d" % _bank.earned(&"trade"))
	_done["exchange"] = true
