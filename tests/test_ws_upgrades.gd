extends SceneTree
## WS4.C1 (docs/design/wave-strike.md 16.5, price / gate / save rows of test_ws_upgrades): card upgrade prices (A = card
## price x1.5, B = x2.5, rounded to 5, minima 100 / 150) for every card of the 4 kingdoms, the Armoury table (16.1),
## tier gates (A = the card's tier, B = the next, T3 B = Citadel), refusals, the 5 s cancel, the role templates + T3
## signatures + Lingering on every ranged on-hit card, the Armoury stats, rule upgrades_enabled, save / load of upgrades
## and Armoury levels. WS4.C2 spawn rows (real level): the next-horn rule, `ws_up:*` / `ws_armoury` modifiers with the
## 16.1 / 16.2 numbers, per-seat lane type copies (Long Draw, Lingering), the release list, saved units' upgrades.
## Prints "PASS ws_upgrades" or "FAIL ws_upgrades: <reasons>".
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_ws_upgrades.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "ws_upgrades"
const A := WaveUpgradeTable.SLOT_A
const B := WaveUpgradeTable.SLOT_B
const KINGDOMS: Array[StringName] = [&"fire", &"ice", &"nature", &"shadow"]
const SCENE := "res://scenes/wave_strike.tscn"

var _fails: Array[String] = []
var _rules: WaveStrikeRules
var _table: WaveCardTable
var _ups: WaveUpgradeTable
var _dir: WaveDirector
var _level: Node
var _ws: Node
var _frames := 0
var _n := 0


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)


func _initialize() -> void:
	_rules = WaveStrikeRules.load_default()
	_table = WaveCardTable.load_default()
	_ups = WaveUpgradeTable.load_default()
	_level = Node.new()
	root.add_child(_level)
	_dir = WaveDirector.new()
	_dir.setup(_rules, _level)
	_level.add_child(_dir)
	_check(_rules.upgrades_enabled, "rule upgrades_enabled defaults to true")
	_prices()
	_effects()
	_gates()
	_armoury()
	_cancel_and_switch()
	_save()
	# WS4.C2 spawn rows on the real level (seat 0 Fire, seat 1 Ice)
	_ws = (load(SCENE) as PackedScene).instantiate()
	var rules := WaveStrikeRules.load_default()
	rules.horn_first = 100000.0
	rules.time_limit = 0.0
	_ws.set(&"rules", rules)
	_ws.set(&"player_kingdom", &"fire")
	_ws.set(&"enemy_kingdom", &"ice")
	_ws.set(&"autopilot_player", true)
	_ws.set(&"wizards_enabled", false)
	root.add_child(_ws)
	current_scene = _ws


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames > 3000:
		_fails.append("level never ready")
		return _finish()
	if _ws == null or _ws.get(&"director") == null:
		return false
	_spawn_rows()
	return _finish()


func _finish() -> bool:
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit(0 if _fails.is_empty() else 1)
	return true


func _spawn(seat: int, id: StringName) -> Unit:
	var at: Vector3 = _ws.call(&"gate_position", seat)
	_n += 1
	var u: Unit = _ws.call(&"spawn_lane_unit", seat, id, at + Vector3(0, 0, float(_n % 9) - 4.0), 0.0)
	if u == null:
		_fails.append("spawn %s seat %d returned null" % [id, seat])
	return u


func _spawn_rows() -> void:
	var rosters: Array = _ws.get(&"rosters")
	var spawners: Array = _ws.get(&"spawners")
	var r0: MusterRoster = rosters[0]
	var r1: MusterRoster = rosters[1]
	var sp0: LaneSpawner = spawners[0]
	var sp1: LaneSpawner = spawners[1]
	for r: MusterRoster in [r0, r1]:
		r.tier = 3
		r.bank.economy.crystals = 1000000
	var fg_base := UnitType.find("flame_guard")
	var ea_base := UnitType.find("ember_archer")
	# horn 1 snapshot: nothing bought
	sp0.queue_horn(r0)
	sp1.queue_horn(r1)
	var u1 := _spawn(0, &"flame_guard")
	# bought after the horn: counts from the next horn only
	r0.buy_upgrade(&"flame_guard", A)
	r0.buy_upgrade(&"flame_guard", B)
	r0.buy_upgrade(&"ember_archer", A)
	r0.buy_upgrade(&"blaze_rider", A)
	r0.buy_upgrade(&"kilnwarden", B)
	r0.armoury_buy(&"weapons")
	r0.armoury_buy(&"arcana")
	r1.buy_upgrade(&"shardcaster", B)
	var u2 := _spawn(0, &"flame_guard")
	if u1 == null or u2 == null:
		return
	_check(not u2.has_modifier(&"ws_up:shield_drill") and not u2.has_modifier(&"ws_armoury"),
			"next-horn rule: a copy spawned before the next horn has no upgrade")
	_check(sp0.release_effects(&"flame_guard").is_empty(), "no War Cry before the next horn")
	# horn 2
	sp0.queue_horn(r0)
	sp1.queue_horn(r1)
	var u3 := _spawn(0, &"flame_guard")
	_check(u3.has_modifier(&"ws_up:shield_drill") and u3.has_modifier(&"ws_armoury"), "flame_guard: ws_up:shield_drill + ws_armoury")
	_check(is_equal_approx(u3.get_stat(&"armor") - u1.get_stat(&"armor"), 3.0),
			"Shield Drill armour +%.1f (want +3)" % (u3.get_stat(&"armor") - u1.get_stat(&"armor")))
	_check(is_equal_approx(u3.get_stat(&"attack_damage") / u1.get_stat(&"attack_damage"), 1.06),
			"Weapons I damage x%.3f (want x1.06)" % (u3.get_stat(&"attack_damage") / u1.get_stat(&"attack_damage")))
	_check(not u1.has_modifier(&"ws_up:shield_drill") and not u1.has_modifier(&"ws_armoury"), "a living unit keeps what it spawned with")
	_check(is_equal_approx(u3.hp, u3.max_hp), "spawns at full HP")
	var fx := sp0.release_effects(&"flame_guard")
	_check(fx.size() == 1 and str(fx[0].get("status", "")) == "haste" and is_equal_approx(float(fx[0]["duration"]), 4.0),
			"War Cry release list %s" % [fx])
	var f := sp0.formation
	_check(f == null or not f.is_member(u3), "a unit spawned outside the horn queue is no formation member")
	# Long Draw: the seat's own type copy
	var a0 := _spawn(0, &"ember_archer")
	var a1 := _spawn(1, &"ember_archer")
	_check(is_equal_approx(a0.unit_type.attack_range, ea_base.attack_range + 1.5) and is_equal_approx(a0.unit_type.aggro_range,
			ea_base.aggro_range + 1.5), "Long Draw range %.1f (base %.1f)" % [a0.unit_type.attack_range, ea_base.attack_range])
	_check(is_equal_approx(a1.unit_type.attack_range, ea_base.attack_range), "seat 1 range unchanged (%.1f)" % a1.unit_type.attack_range)
	_check(is_equal_approx(ea_base.attack_range, UnitType.find("ember_archer").attack_range) and fg_base.commandable,
			"the base UnitType is untouched")
	# Barding: +20 % max HP, full
	var br := _spawn(0, &"blaze_rider")
	var br_base := UnitType.find("blaze_rider")
	_check(br.has_modifier(&"ws_up:barding") and is_equal_approx(br.max_hp, br_base.max_hp * 1.2) and is_equal_approx(br.hp, br.max_hp),
			"Barding max HP %.0f (base %.0f)" % [br.max_hp, br_base.max_hp])
	_check(br.has_modifier(&"ws_armoury") and not (br.get_meta(&"ws_arm", {}) as Dictionary).has("spell_power"),
			"Arcana skips a rider")
	# Focus + Arcana on a caster
	var kw := _spawn(0, &"kilnwarden")
	var kw1 := _spawn(1, &"kilnwarden")
	if kw and kw1:
		_check(kw.has_modifier(&"ws_up:focus") and is_equal_approx(kw.get_stat(&"spell_power") - kw1.get_stat(&"spell_power"), 40.0),
				"kilnwarden Focus + Arcana I spell power +%.1f (want +40)" % (kw.get_stat(&"spell_power") - kw1.get_stat(&"spell_power")))
	# Lingering (seat 1, Ice shardcaster: the only ranged card with an on-hit status)
	var sc_base := UnitType.find("shardcaster")
	var sc := _spawn(1, &"shardcaster")
	_check(is_equal_approx(sc.unit_type.on_hit_duration, sc_base.on_hit_duration * 1.5) and sc.unit_type.on_hit_status == sc_base.on_hit_status,
			"Lingering on-hit %.2f s (base %.2f)" % [sc.unit_type.on_hit_duration, sc_base.on_hit_duration])
	# a saved lane unit comes back with its own upgrades, even after the roster changed
	var row := {"team": 0, "pos": (_ws.call(&"gate_position", 0) as Vector3) + Vector3(2, 0, 2),
			"metas": {"ws_card": "flame_guard", "ws_seat": 0, "ws_up_mask": int(u3.get_meta(&"ws_up_mask", 0)),
			"ws_arm": u3.get_meta(&"ws_arm", {})}}
	var back: Unit = _ws.call(&"save_spawn_unit", row)
	_check(back != null and back.has_modifier(&"ws_up:shield_drill") and back.has_modifier(&"ws_armoury")
			and is_equal_approx(back.get_stat(&"armor"), u3.get_stat(&"armor")), "save_spawn_unit re-applies the unit's upgrades")
	var plain := {"team": 0, "pos": row["pos"], "metas": {"ws_card": "flame_guard", "ws_seat": 0}}
	var back2: Unit = _ws.call(&"save_spawn_unit", plain)
	_check(back2 != null and not back2.has_modifier(&"ws_up:shield_drill"), "a saved unit without upgrades loads without them")


func _roster(kingdom: StringName, seat: int, rules: WaveStrikeRules = null) -> MusterRoster:
	var eco := Economy.new()
	eco.team = Unit.Team.PLAYER
	_level.add_child(eco)
	var bank := WaveBank.new()
	bank.setup(seat, Unit.Team.PLAYER, rules if rules else _rules, eco)
	_level.add_child(bank)
	bank.economy.crystals = 1000000
	var r := MusterRoster.new()
	r.setup(seat, Unit.Team.PLAYER, kingdom, rules if rules else _rules, _table, bank, _dir)
	_level.add_child(r)
	return r


static func _round5(v: float) -> int:
	return int(roundf(v / 5.0) * 5.0)


func _prices() -> void:
	# spec examples: flame_guard (95) A 145 / B 240; scorchling (50) A 75 -> min 100, B 125 -> min 150
	_check(_ups.price(_table, &"flame_guard", A) == 145, "flame_guard A %d (want 145)" % _ups.price(_table, &"flame_guard", A))
	_check(_ups.price(_table, &"flame_guard", B) == 240, "flame_guard B %d (want 240)" % _ups.price(_table, &"flame_guard", B))
	_check(_ups.price(_table, &"scorchling", A) == 100, "scorchling A %d (min 100)" % _ups.price(_table, &"scorchling", A))
	_check(_ups.price(_table, &"scorchling", B) == 150, "scorchling B %d (min 150)" % _ups.price(_table, &"scorchling", B))
	for k in KINGDOMS:
		for id in _table.cards_of(k):
			var p := _table.price(id)
			var want_a := maxi(_round5(p * 1.5), 100)
			var want_b := maxi(_round5(p * 2.5), 150)
			_check(_ups.price(_table, id, A) == want_a, "%s A %d (want %d)" % [id, _ups.price(_table, id, A), want_a])
			_check(_ups.price(_table, id, B) == want_b, "%s B %d (want %d)" % [id, _ups.price(_table, id, B), want_b])
	_check(_ups.price(_table, &"flame_guard", 2) == -1, "slot 2 has no price")


func _effects() -> void:
	# role templates (16.2)
	var want := {&"flame_guard": ["shield_drill", "war_cry"], &"ember_archer": ["long_draw", "spotter_marks"],
			&"blaze_rider": ["barding", "flank_gallop"], &"shadow_knight": ["plate", "brace"],
			&"rime_seer": ["deep_wells", "quick_hands"], &"kilnwarden": ["mana_font", "focus"],
			&"ash_hurler": ["long_draw", "spotter_marks"],
			# T3: A from the role, signature B
			&"sunforge_cataphract": ["barding", "sunforged_charge"], &"frostcrown_juggernaut": ["barding", "rime_mantle"],
			&"shardguard": ["shield_drill", "shard_ward"], &"briar_roc": ["long_draw", "thorned_pinions"],
			&"glade_outrider": ["barding", "far_sight"], &"nightblood_reaver": ["shield_drill", "blood_feast"],
			&"veilborn_dreadrider": ["barding", "veil_ride"]}
	for id: StringName in want:
		for slot in 2:
			var got := str(_ups.upgrade(_table, id, slot).get("id", ""))
			_check(got == str(want[id][slot]), "%s %s = %s (want %s)" % [id, "AB"[slot], got, want[id][slot]])
	# every card has both upgrades with a name and a description
	for k in KINGDOMS:
		for id in _table.cards_of(k):
			for slot in 2:
				var u := _ups.upgrade(_table, id, slot)
				_check(not u.is_empty() and str(u.get("name", "")) != "" and str(u.get("desc", "")) != "",
						"%s %s complete" % [id, "AB"[slot]])
	# numbers
	_check(is_equal_approx(float(_ups.upgrade(_table, &"flame_guard", A)["mods"]["armor"]), 3.0), "Shield Drill +3 armour")
	_check(is_equal_approx(float(_ups.upgrade(_table, &"shadow_knight", A)["mods"]["armor"]), 4.0), "Plate +4 armour")
	_check(is_equal_approx(float(_ups.upgrade(_table, &"ember_archer", A)["type_add"]["attack_range"]), 1.5), "Long Draw +1.5")
	_check(is_equal_approx(float(_ups.upgrade(_table, &"blaze_rider", A)["mods"]["max_hp_pct"]), 0.2), "Barding +20 %")
	_check(is_equal_approx(float(_ups.upgrade(_table, &"rime_seer", B)["type_mult"]["support_interval"]), 0.75), "Quick Hands x0.75")
	_check(is_equal_approx(float(_ups.upgrade(_table, &"shardguard", B)["release"][0]["shield"]), 150.0), "Shard Ward 150")
	# Lingering on every ranged card that already has an on-hit status; Spotter Marks on the other ranged cards
	var lingering: Array[String] = []
	for k in KINGDOMS:
		for id in _table.cards_of(k):
			if _table.upgrade_role(id) != &"ranged" or _ups.overrides.has(String(id)):
				continue
			var t := UnitType.find(String(id))
			var b := str(_ups.upgrade(_table, id, B).get("id", ""))
			if t.on_hit_status != &"":
				lingering.append(String(id))
				_check(b == "lingering", "%s (on-hit %s) B = %s (want lingering)" % [id, t.on_hit_status, b])
				var mult := float(_ups.upgrade(_table, id, B)["type_mult"]["on_hit_duration"])
				_check(is_equal_approx(t.on_hit_duration * mult, t.on_hit_duration * 1.5), "%s Lingering x1.5" % id)
			else:
				_check(b == "spotter_marks", "%s B = %s (want spotter_marks)" % [id, b])
	_check(lingering == ["shardcaster"], "Lingering cards: %s (want [shardcaster])" % [lingering])
	print("ws_upgrades: Lingering cards %s" % [lingering])


func _gates() -> void:
	var r := _roster(&"fire", 0)
	_check(r.can_buy_upgrade(&"flame_guard", A) == "", "flame_guard A at Keep: %s" % r.can_buy_upgrade(&"flame_guard", A))
	_check(r.can_buy_upgrade(&"flame_guard", B) == "Requires Stronghold", "flame_guard B at Keep: %s" % r.can_buy_upgrade(&"flame_guard", B))
	_check(r.can_buy_upgrade(&"cinder_arbalest", A) == "Requires Stronghold", "T2 A at Keep: %s" % r.can_buy_upgrade(&"cinder_arbalest", A))
	r.tier = 2
	_check(r.can_buy_upgrade(&"cinder_arbalest", B) == "Requires Citadel", "T2 B at Stronghold: %s" % r.can_buy_upgrade(&"cinder_arbalest", B))
	_check(r.can_buy_upgrade(&"sunforge_cataphract", A) == "Requires Citadel", "T3 A at Stronghold")
	r.tier = 3
	_check(r.can_buy_upgrade(&"sunforge_cataphract", B) == "", "T3 B at Citadel: %s" % r.can_buy_upgrade(&"sunforge_cataphract", B))
	for id in r.card_ids():
		var t := UnitType.find(String(id))
		_check(_ups.gate_tier(id, A) == t.requires_tier and _ups.gate_tier(id, B) == mini(t.requires_tier + 1, 3),
				"%s gates %d / %d" % [id, _ups.gate_tier(id, A), _ups.gate_tier(id, B)])
	_check(r.can_buy_upgrade(&"shade", A) == MusterRoster.REASON_UNKNOWN, "another kingdom's card: unknown")
	# buy: price paid, no copy needed, bought once
	var before := r.bank.crystals()
	_check(r.buy_upgrade(&"flame_guard", A) == "", "buy flame_guard A")
	_check(before - r.bank.crystals() == 145, "paid %d (want 145)" % (before - r.bank.crystals()))
	_check(r.has_upgrade(&"flame_guard", A) and not r.has_upgrade(&"flame_guard", B), "has A only")
	_check(r.buy_upgrade(&"flame_guard", A) == "Already bought", "A twice: %s" % r.can_buy_upgrade(&"flame_guard", A))
	_check(r.upgrades_of(&"flame_guard").size() == 1 and str(r.upgrades_of(&"flame_guard")[0]["id"]) == "shield_drill",
			"upgrades_of flame_guard")
	r.bank.economy.crystals = 10
	_check(r.can_buy_upgrade(&"flame_guard", B) == "Not enough crystals", "B broke: %s" % r.can_buy_upgrade(&"flame_guard", B))
	# upgrades stay when the last copy is sold
	r.bank.economy.crystals = 100000
	r.buy(&"flame_guard")
	r.sell(&"flame_guard")
	_check(r.has_upgrade(&"flame_guard", A), "upgrade stays after the last copy is sold")


func _armoury() -> void:
	# the 16.1 table
	_check(_ups.armoury_max(&"weapons") == 3 and _ups.armoury_max(&"armour") == 3 and _ups.armoury_max(&"arcana") == 2,
			"Armoury levels 3 / 3 / 2")
	for line: StringName in [&"weapons", &"armour"]:
		for lv in 3:
			_check(_ups.armoury_price(line, lv) == [200, 350, 500][lv] and _ups.armoury_tier(line, lv) == lv + 1,
					"%s level %d price / tier" % [line, lv + 1])
	_check(_ups.armoury_price(&"arcana", 0) == 250 and _ups.armoury_price(&"arcana", 1) == 450, "Arcana prices")
	_check(_ups.armoury_tier(&"arcana", 0) == 2 and _ups.armoury_tier(&"arcana", 1) == 3, "Arcana tiers")
	var r := _roster(&"fire", 1)
	_check(r.armoury_price(&"weapons") == 200, "Weapons I 200")
	_check(r.armoury_buy(&"weapons") == "", "buy Weapons I at Keep")
	_check(r.can_armoury_buy(&"weapons") == "Requires Stronghold", "Weapons II at Keep: %s" % r.can_armoury_buy(&"weapons"))
	_check(r.can_armoury_buy(&"arcana") == "Requires Stronghold", "Arcana I at Keep: %s" % r.can_armoury_buy(&"arcana"))
	_check(r.can_armoury_buy(&"shields") == "Unknown upgrade", "unknown line")
	r.tier = 3
	var before := r.bank.crystals()
	_check(r.armoury_buy(&"weapons") == "" and r.armoury_buy(&"weapons") == "", "Weapons II, III")
	_check(before - r.bank.crystals() == 850, "Weapons II + III paid %d (want 850)" % (before - r.bank.crystals()))
	_check(r.armoury_level(&"weapons") == 3 and r.can_armoury_buy(&"weapons") == "Max level", "Weapons max")
	_check(r.armoury_buy(&"arcana") == "" and r.armoury_buy(&"arcana") == "" and r.armoury_buy(&"arcana") == "Max level",
			"Arcana I, II, max")
	r.armoury_buy(&"armour")
	r.bank.economy.crystals = 0
	_check(r.can_armoury_buy(&"armour") == "Not enough crystals", "Armour II broke")
	# the seat-wide stats a lane unit gets (WS4.C2 applies them as ws_armoury)
	var m := r.armoury_mods(&"flame_guard")
	_check(is_equal_approx(float(m.get("attack_damage_pct", 0.0)), 0.18) and is_equal_approx(float(m.get("armor", 0.0)), 1.0)
			and not m.has("spell_power"), "flame_guard Armoury stats %s" % m)
	var c := r.armoury_mods(&"kilnwarden")
	_check(is_equal_approx(float(c.get("spell_power", 0.0)), 30.0) and is_equal_approx(float(c.get("mana_regen_pct", 0.0)), 0.4),
			"kilnwarden Arcana II stats %s" % c)


func _cancel_and_switch() -> void:
	var r := _roster(&"fire", 2)
	var before := r.bank.crystals()
	r.buy_upgrade(&"ember_archer", A)
	_check(r.cancel_upgrade(&"ember_archer", A) == "" and r.bank.crystals() == before and not r.has_upgrade(&"ember_archer", A),
			"cancel within 5 s refunds 100 %")
	r.buy_upgrade(&"ember_archer", A)
	r.armoury_buy(&"armour")
	_dir.time += 6.0
	_check(r.cancel_upgrade(&"ember_archer", A) == "Too late to cancel", "cancel after 5 s refused")
	_check(r.armoury_cancel(&"armour") == "Too late to cancel", "Armoury cancel after 5 s refused")
	r.armoury_buy(&"weapons")
	before = r.bank.crystals()
	_check(r.armoury_cancel(&"weapons") == "" and r.bank.crystals() == before + 200 and r.armoury_level(&"weapons") == 0,
			"Armoury cancel within 5 s")
	# labs switch
	var off := _rules.duplicate() as WaveStrikeRules
	off.upgrades_enabled = false
	var r2 := _roster(&"fire", 3, off)
	_check(r2.buy_upgrade(&"flame_guard", A) == "Upgrades off" and r2.armoury_buy(&"weapons") == "Upgrades off",
			"upgrades_enabled = false refuses")


func _save() -> void:
	var r := _roster(&"ice", 4)
	r.tier = 3
	r.buy_upgrade(&"shardcaster", A)
	r.buy_upgrade(&"shardcaster", B)
	r.buy_upgrade(&"frostcrown_juggernaut", B)
	r.armoury_buy(&"armour")
	r.armoury_buy(&"armour")
	r.armoury_buy(&"arcana")
	var d: Dictionary = JSON.parse_string(JSON.stringify(r.save_state()))
	var r2 := _roster(&"ice", 5)
	r2.load_state(d)
	_check(r2.has_upgrade(&"shardcaster", A) and r2.has_upgrade(&"shardcaster", B), "loaded shardcaster A + B")
	_check(r2.has_upgrade(&"frostcrown_juggernaut", B) and not r2.has_upgrade(&"frostcrown_juggernaut", A), "loaded juggernaut B only")
	_check(r2.armoury_level(&"armour") == 2 and r2.armoury_level(&"arcana") == 1 and r2.armoury_level(&"weapons") == 0,
			"loaded Armoury levels")
	_check(r2.upgrades_bought.size() == 6, "loaded upgrades_bought %s" % [r2.upgrades_bought])
	_check(r2.can_buy_upgrade(&"shardcaster", A) == "Already bought", "loaded: A refused as bought")
	# a save from before upgrades loads with none
	d.erase("upgrades")
	d.erase("armoury")
	var r3 := _roster(&"ice", 6)
	r3.load_state(d)
	_check(not r3.has_upgrade(&"shardcaster", A) and r3.armoury_level(&"armour") == 0, "old save: no upgrades")
