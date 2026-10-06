extends Node3D
## Unit Lab (docs/plan/unit-lab.md): the ARENA. A flat square of ground (collider on layer 1 + a navmesh) where two
## sides of REAL units fight: UnitType.create_unit(), the game's own Unit combat, abilities (NewUnits12 / T3Kit /
## BowmanKit / CasterKit attach themselves in Unit._ready), statuses, projectiles, support casters, and for "bot"
## casters the real AICasters brain (through tools/unit_lab/unit_lab_commander.gd). Nothing is scripted except the
## orders a player would give (attack-move, hold, retreat, focus fire) and the starting setup (level, "+", modifiers,
## statuses, HP, mana).
## Used by the headless runner (tools/unit_lab/unit_lab_run.gd: one arena per fight, freed after) and by the sandbox
## (scenes/unit_lab.tscn: tools/unit_lab/unit_lab_sandbox.gd extends this script).
## Side A spawns on -X, side B on +X, `distance` metres apart. Side index (0 = A, 1 = B) is not the team: setup()
## takes `swap` (A plays Unit.Team.ENEMY) so processing / team order never favours a side over many seeds.

const SPEC := preload("res://tools/unit_lab/unit_lab_spec.gd")
const COMMANDER := preload("res://tools/unit_lab/unit_lab_commander.gd")
const SIDE_NAMES := ["a", "b"]
const ORDER_TICK := 0.5
const HUNT_TICK := 1.0
const WARMUP_FRAMES := 4
const JITTER := 0.3

signal fight_started
signal fight_ended(result: Dictionary)
signal unit_spawned(unit: Unit, side: int)
signal fight_log(text: String)

## AICasters reads these on its commander's parent (the level).
var match_started := true
var game_over := false

var arena_size := 80.0
var distance := 20.0
var time_limit := 120.0
var spec_name := "unnamed"
var arm_name := "main"
var seed_value := 1
var swap := false
var sides: Array = [{}, {}]          # normalized SIDE dicts
var side_team: Array[int] = [0, 1]   # side -> Unit.Team
var time := 0.0
var running := false
var ended := false
var result: Dictionary = {}
var extra: Dictionary = {}           # copied into the result (matrix entries, variant name)
## Unit instance id -> record {side, id, cost, pop, dealt, taken, kills, born, died, unit (weakref), hp_max}
var records: Dictionary = {}
var log_lines: Array[String] = []
var log_enabled := true

var _rng := RandomNumberGenerator.new()
var _infra: Array[Node] = []
var _commanders: Array = [null, null]
var _order_left := 0.0
var _hunt_left := 0.0
var _warmup := 0
var _casts: Array = [{}, {}]         # spell id -> count (+ "passage_units": units an Umbral Passage carried)
var _carried: Array = [{}, {}]       # CasterAbility instance id -> its passage_units so far
var _first_cast: Array = [{}, {}]    # spell id -> time
var _other_dealt: Array[float] = [0.0, 0.0]   # damage by sources that are not tracked units (towers, hazards)
var _built := false
var _spawning := false               # true inside spawn_unit / spawn_hero (not a summon)


func _ready() -> void:
	build_arena()


# ---------------------------------------------------------------- arena

## The ground (StaticBody3D on layer 1) and a navmesh over it. Idempotent.
func build_arena() -> void:
	if _built:
		return
	_built = true
	var h := arena_size * 0.5
	var body := StaticBody3D.new()
	body.name = "LabFloor"
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(arena_size + 20.0, 1.0, arena_size + 20.0)
	shape.shape = box
	shape.position = Vector3(0, -0.5, 0)
	body.add_child(shape)
	add_child(body)
	_infra.append(body)
	var region := NavigationRegion3D.new()
	region.name = "LabNav"
	var plane := PlaneMesh.new()
	plane.size = Vector2(arena_size, arena_size)
	var nm := NavigationMesh.new()
	nm.create_from_mesh(plane)
	region.navigation_mesh = nm
	add_child(region)
	_infra.append(region)


## Nodes that survive clear_units() (the sandbox adds its camera, light and UI here).
func add_infra(n: Node) -> void:
	if not _infra.has(n):
		_infra.append(n)


# ---------------------------------------------------------------- setup

## Prepares one fight: `spec` normalized (UnitLabSpec), `arm` one of spec.arms, `seed`, `swap` (side A = ENEMY team).
## Spawns both sides now; the fight starts after a few physics frames (the navmesh syncs first).
func setup(spec: Dictionary, arm: Dictionary, p_seed: int, p_swap: bool) -> void:
	clear_units()
	spec_name = String(spec.get("name", "unnamed"))
	arm_name = String(arm.get("name", "main"))
	time_limit = float(spec.get("time_limit", 120.0))
	distance = float(spec.get("distance", 20.0))
	seed_value = p_seed
	swap = p_swap
	side_team.assign([1, 0] if swap else [0, 1])
	sides = [arm["a"], arm["b"]]
	_rng.seed = hash([p_seed, arm_name, spec_name])
	seed(p_seed * 7919 + 17)
	# spawn order alternates too (the team order and the node order both flip with `swap`)
	var order := [1, 0] if swap else [0, 1]
	for s: int in order:
		spawn_side(s)
	time = 0.0
	ended = false
	result = {}
	_warmup = WARMUP_FRAMES
	running = true
	_order_left = 0.0
	_hunt_left = HUNT_TICK


## The start centre of a side.
func side_centre(s: int) -> Vector3:
	return Vector3(-distance * 0.5 if s == 0 else distance * 0.5, 0.0, 0.0)


## Toward the enemy (+X for A, -X for B).
func side_facing(s: int) -> Vector3:
	return Vector3(1, 0, 0) if s == 0 else Vector3(-1, 0, 0)


## Spawns every group of side `s` in its formation; casters of "bot" sides get the stand-in commander.
func spawn_side(s: int) -> void:
	var side: Dictionary = sides[s]
	var normal: Array = []    # [type, group] entries placed by the formation
	for g: Dictionary in side.get("groups", []):
		var t := UnitType.find(String(g["id"]))
		if t == null:
			continue
		if g.get("at") != null:
			var c := Vector3(float(g["at"][0]), 0.0, float(g["at"][1]))
			var pts := formation_points(c, side_facing(s), [t], int(g["count"]), String(side.get("formation", "auto")))
			for p: Vector3 in pts:
				spawn_unit(String(g["id"]), s, p, g)
		else:
			for i in int(g["count"]):
				normal.append([t, g])
	if not normal.is_empty():
		var formation := String(side.get("formation", "auto"))
		if formation == "auto":
			normal.sort_custom(func(x: Array, y: Array) -> bool:
				return _rank(x[0]) < _rank(y[0]))
		var types: Array = []
		for e: Array in normal:
			types.append(e[0])
		var pts := formation_points(side_centre(s), side_facing(s), types, normal.size(), formation)
		for i in normal.size():
			spawn_unit(String((normal[i][1] as Dictionary)["id"]), s, pts[i], normal[i][1])
	var hero: Dictionary = side.get("hero", {})
	if not hero.is_empty():
		spawn_hero(s, hero)
	if String(side.get("casters", "autocast")) == "bot":
		_make_commander(s)


# melee first (front), then ranged, casters last (behind).
func _rank(t: UnitType) -> float:
	if CasterKit.is_caster(t.id):
		return 100.0
	return t.attack_range


## Points for `n` units around `centre`: rows across the facing line, the first row in front.
func formation_points(centre: Vector3, facing: Vector3, types: Array, n: int, formation: String) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var side_dir := facing.cross(Vector3.UP).normalized()
	var spacing := 1.3
	for t: Variant in types:
		if t is UnitType:
			spacing = maxf(spacing, (t as UnitType).radius * 2.0 + 0.5)
	var per_row := n if formation == "line" else maxi(3, ceili(sqrt(float(n) * 2.0)))
	per_row = mini(per_row, maxi(1, int(arena_size * 0.8 / spacing)))
	var rows := ceili(float(n) / float(per_row))
	for i in n:
		var row := i / per_row
		var col := i % per_row
		var in_row := mini(per_row, n - row * per_row)
		var lateral := (float(col) - float(in_row - 1) * 0.5) * spacing
		var back := float(row) * spacing - float(rows - 1) * spacing * 0.5
		var p := centre + side_dir * lateral - facing * back
		p += Vector3(_rng.randf_range(-JITTER, JITTER), 0.0, _rng.randf_range(-JITTER, JITTER))
		var hlim := arena_size * 0.5 - 1.0
		p.x = clampf(p.x, -hlim, hlim)
		p.z = clampf(p.z, -hlim, hlim)
		out.append(p)
	return out


## One real unit of `type_id` for side `s` at `pos`, with the group's setup (level, "+", mods, statuses, HP, mana).
func spawn_unit(type_id: String, s: int, pos: Vector3, g: Dictionary = {}) -> Unit:
	var t := UnitType.find(type_id)
	if t == null:
		return null
	var u := t.create_unit()
	u.set(&"team", side_team[s])
	u.position = Vector3(pos.x, 0.0, pos.z)
	_spawning = true
	add_child(u)
	_spawning = false
	u.look_at(u.global_position + side_facing(s), Vector3.UP)
	_after_spawn(u, s, g)
	return u


func _after_spawn(u: Unit, s: int, g: Dictionary) -> void:
	var lv := int(g.get("level", 1))
	while u.level < lv and u.veterancy_next_xp() > 0:
		u.add_xp(maxi(1, u.veterancy_next_xp() - u.xp))
	if bool(g.get("plus", false)) and u.unit_type and UnitUpgrades.has_plus(u.unit_type.id):
		u.add_modifier(UnitUpgrades.MODIFIER, UnitUpgrades.stats_of(u.unit_type.id))
		u.set_meta(&"plus", true)
	var mods: Dictionary = g.get("mods", {})
	if not mods.is_empty():
		u.add_modifier(&"unit_lab", mods)
	for b: Variant in g.get("bowman", []):
		var bu := BowmanUpgrades.for_team(int(u.team))
		if bu:
			bu.grant(StringName(String(b)))
	for st: Variant in g.get("statuses", []):
		if st is Array and (st as Array).size() >= 2:
			u.apply_status(StringName(String(st[0])), float(st[1]))
	var hp_pct := float(g.get("hp_pct", 1.0))
	if hp_pct < 1.0:
		u.hp = maxf(1.0, u.max_hp * hp_pct)
		u.heal(0.0)   # refreshes the HP bar
	var ab := CasterKit.ability_of(u)
	if ab:
		var mana := float(g.get("mana", -1.0))
		if mana >= 0.0:
			ab.mana = 0.0
			ab.add_mana(minf(mana, ab.max_mana()))
		var mode := String((sides[s] as Dictionary).get("casters", "autocast")) if s < sides.size() \
				and sides[s] is Dictionary else "autocast"
		var ac: Variant = g.get("autocast", null)
		for sp in ab.spell_ids():
			if ac != null:
				ab.set_autocast(sp, bool(ac))
			elif mode == "off":
				ab.set_autocast(sp, false)
			elif mode == "on":
				ab.set_autocast(sp, true)
		ab.spell_cast.connect(_on_spell_cast.bind(s, ab))
	register(u, s)
	unit_spawned.emit(u, s)


## The kingdom's wizard (experimental): level, spells learned in slot order; non-Fire wizards autocast their spells
## (their ai_auto_cast), the Fire wizard only auto-attacks.
func spawn_hero(s: int, hero: Dictionary) -> Unit:
	var k := String(hero.get("kingdom", "fire"))
	var path: String = {"fire": "res://scripts/units/wizard.gd", "shadow": "res://scripts/units/shadow_wizard.gd",
			"ice": "res://scripts/units/ice_wizard.gd", "nature": "res://scripts/units/nature_wizard.gd"}.get(k, "")
	if path == "" or not ResourceLoader.exists(path):
		return null
	var w := (load(path) as GDScript).new() as Unit
	w.set(&"team", side_team[s])
	var c := side_centre(s) - side_facing(s) * 3.0
	w.position = c
	_spawning = true
	add_child(w)
	_spawning = false
	var lv := int(hero.get("level", 1))
	for i in 20:
		if int(w.level) >= lv or not w.has_method(&"xp_to_next") or int(w.call(&"xp_to_next")) <= 0:
			break
		w.add_xp(int(w.call(&"xp_to_next")))
	if w.has_method(&"learn_spell") and &"default_spell_ids" in w:
		for round_i in 3:
			for sp: StringName in w.get(&"default_spell_ids"):
				w.call(&"learn_spell", sp)
	if &"ai_auto_cast" in w:
		w.set(&"ai_auto_cast", true)
	var inv: Variant = w.get(&"inventory") if &"inventory" in w else null
	for item_id: Variant in hero.get("items", []):
		var it := ItemType.find(StringName(String(item_id)))
		if inv and it:
			inv.call(&"add_item", it)
	register(w, s, "hero_" + k)
	unit_spawned.emit(w, s)
	return w


func _make_commander(s: int) -> void:
	var c: Node = COMMANDER.new()
	var faction := &"fire"
	for g: Dictionary in (sides[s] as Dictionary).get("groups", []):
		var t := UnitType.find(String(g["id"]))
		if t and CasterKit.is_caster(t.id):
			faction = t.faction
	var home := side_centre(s)
	var rt: Variant = (sides[s] as Dictionary).get("retreat_to")
	if rt is Array:
		home = Vector3(float(rt[0]), 0.0, float(rt[1]))
	c.call(&"setup", self, s, side_team[s], faction, home, String((sides[s] as Dictionary).get("order", "")) == "retreat",
			int((sides[s] as Dictionary).get("bot_difficulty", 1)))
	add_child(c)
	c.call(&"start_casters")
	_commanders[s] = c


# ---------------------------------------------------------------- tracking

## Starts tracking `u` for side `s` (spawned units, and summons that appear during the fight).
func register(u: Unit, s: int, key: String = "") -> void:
	var id := u.get_instance_id()
	if records.has(id):
		return
	var tid := key if key != "" else (String(u.unit_type.id) if u.unit_type else "unit")
	records[id] = {"side": s, "id": tid, "cost": u.unit_type.cost if u.unit_type else 0,
			"pop": u.unit_type.pop if u.unit_type else 0, "dealt": 0.0, "taken": 0.0, "kills": 0, "born": time,
			"died": -1.0, "unit": weakref(u), "hp_max": u.max_hp, "summon": false}
	u.damage_taken.connect(_on_damage.bind(u))
	u.died.connect(_on_died)


func _on_child_entered(n: Node) -> void:
	# summons / spawned helpers that join the arena mid-fight (NewUnits12 Saplings, Thicket wolves...)
	if n is Unit and not _spawning and not records.has(n.get_instance_id()):
		(n as Unit).ready.connect(_adopt_summon.bind(n), CONNECT_ONE_SHOT)


func _adopt_summon(n: Node) -> void:
	var u := n as Unit
	if u == null or records.has(u.get_instance_id()):
		return
	var s := side_team.find(int(u.team))
	if s < 0:
		return
	register(u, s)
	records[u.get_instance_id()]["summon"] = true
	records[u.get_instance_id()]["cost"] = 0


func _enter_tree() -> void:
	if not child_entered_tree.is_connected(_on_child_entered):
		child_entered_tree.connect(_on_child_entered)


func _on_damage(amount: float, attacker: Node3D, victim: Unit) -> void:
	var eff := amount + minf(0.0, victim.hp)   # no overkill
	if eff <= 0.0:
		return
	var vr: Dictionary = records.get(victim.get_instance_id(), {})
	if not vr.is_empty():
		vr["taken"] = float(vr["taken"]) + eff
	if attacker != null and is_instance_valid(attacker):
		var ar: Dictionary = records.get(attacker.get_instance_id(), {})
		if not ar.is_empty():
			ar["dealt"] = float(ar["dealt"]) + eff
			return
		var t: Variant = attacker.get(&"team")
		if t != null and side_team.has(int(t)):
			_other_dealt[side_team.find(int(t))] += eff


func _on_died(u: Unit) -> void:
	var r: Dictionary = records.get(u.get_instance_id(), {})
	if r.is_empty():
		return
	r["died"] = time
	var k: Node3D = u.killer
	if k != null and is_instance_valid(k):
		var kr: Dictionary = records.get(k.get_instance_id(), {})
		if not kr.is_empty():
			kr["kills"] = int(kr["kills"]) + 1
	if log_enabled:
		_log("%5.1fs  %s %s died%s" % [time, SIDE_NAMES[int(r["side"])].to_upper(), r["id"],
				(" (by %s)" % records[k.get_instance_id()]["id"]) if k != null and is_instance_valid(k) \
				and records.has(k.get_instance_id()) else ""])


func _on_spell_cast(spell_id: StringName, s: int, ab: Node = null) -> void:
	var key := String(spell_id)
	_casts[s][key] = int(_casts[s].get(key, 0)) + 1
	# Umbral Passage: how many units it carried (CasterAbility.casts["passage_units"] is per Deacon, cumulative).
	if spell_id == &"umbral_passage" and ab != null and is_instance_valid(ab):
		var c: Variant = ab.get(&"casts")
		if c is Dictionary:
			var before := int(_carried[s].get(ab.get_instance_id(), 0))
			var now := int((c as Dictionary).get(&"passage_units", 0))
			_carried[s][ab.get_instance_id()] = now
			_casts[s]["passage_units"] = int(_casts[s].get("passage_units", 0)) + now - before
	if not _first_cast[s].has(key):
		_first_cast[s][key] = snappedf(time, 0.01)
	if log_enabled:
		_log("%5.1fs  %s casts %s" % [time, SIDE_NAMES[s].to_upper(), key])


func _log(t: String) -> void:
	log_lines.append(t)
	if log_lines.size() > 400:
		log_lines.remove_at(0)
	fight_log.emit(t)


## The living units of side `s` (tracked ones).
func living_units(s: int) -> Array:
	var out: Array = []
	for id: int in records:
		var r: Dictionary = records[id]
		if int(r["side"]) != s:
			continue
		var u := (r["unit"] as WeakRef).get_ref() as Unit
		if u != null and u.is_alive() and u.is_inside_tree():
			out.append(u)
	return out


# ---------------------------------------------------------------- the fight

func _physics_process(delta: float) -> void:
	if not running or ended:
		return
	if _warmup > 0:
		_warmup -= 1
		if _warmup == 0:
			_issue_start_orders()
			fight_started.emit()
		return
	time += delta
	_order_left -= delta
	if _order_left <= 0.0:
		_order_left += ORDER_TICK
		for s in 2:
			_focus_tick(s)
	_hunt_left -= delta
	if _hunt_left <= 0.0:
		_hunt_left += HUNT_TICK
		for s in 2:
			_hunt_tick(s)
	_check_end()


func _is_bot_caster(u: Unit, s: int) -> bool:
	return String((sides[s] as Dictionary).get("casters", "")) == "bot" and CasterKit.is_caster_unit(u)


func _issue_start_orders() -> void:
	for s in 2:
		var side: Dictionary = sides[s]
		var order := String(side.get("order", "attack_move"))
		for u: Unit in living_units(s):
			if _is_bot_caster(u, s):
				continue
			if String(side.get("focus", "")) == "casters":
				u.prefer_casters = true
			match order:
				"attack_move":
					u.command_attack_move(attack_point(s))
				"hold":
					u.command_hold()
				"retreat":
					var rt: Variant = side.get("retreat_to")
					var p := side_centre(s) - side_facing(s) * 30.0
					if rt is Array:
						p = Vector3(float(rt[0]), 0.0, float(rt[1]))
					u.command_move(p)
				_:
					pass


## Where side `s` attack-moves: its spec's target, else just past the enemy's start.
func attack_point(s: int) -> Vector3:
	var t: Variant = (sides[s] as Dictionary).get("target")
	if t is Array:
		return Vector3(float(t[0]), 0.0, float(t[1]))
	return side_centre(1 - s) + side_facing(s) * 4.0


# Attack-move sides: an idle unit (no target, no order) attack-moves to the nearest enemy (a player's "A-click on the
# rest of them"), so a fight never stalls on two clumps out of aggro range.
func _hunt_tick(s: int) -> void:
	if String((sides[s] as Dictionary).get("order", "")) != "attack_move" 			or not bool((sides[s] as Dictionary).get("hunt", true)):
		return
	var enemies := living_units(1 - s)
	if enemies.is_empty():
		return
	for u: Unit in living_units(s):
		if _is_bot_caster(u, s) or u.attack_target != null or u.is_attack_moving() or u.has_move_order():
			continue
		var best: Unit = null
		var bd := INF
		for e: Unit in enemies:
			var d := u.global_position.distance_squared_to(e.global_position)
			if d < bd:
				bd = d
				best = e
		if best:
			u.command_attack_move(best.global_position)


func _focus_tick(s: int) -> void:
	if String((sides[s] as Dictionary).get("focus", "none")) != "lowest_hp":
		return
	var enemies := living_units(1 - s)
	for u: Unit in living_units(s):
		if _is_bot_caster(u, s):
			continue
		var reach := maxf(u.aggro_range, u.attack_range + 2.0)
		var best: Unit = null
		var bh := INF
		for e: Unit in enemies:
			if Vector2(e.global_position.x - u.global_position.x, e.global_position.z - u.global_position.z).length() \
					> reach:
				continue
			if e.hp < bh:
				bh = e.hp
				best = e
		if best and best != u.attack_target:
			u.set_auto_target(best)


func _check_end() -> void:
	var alive := [living_units(0).size(), living_units(1).size()]
	var winner := ""
	var reason := ""
	if alive[0] == 0 and alive[1] == 0:
		winner = "draw"
		reason = "kill"
	elif alive[0] == 0:
		winner = "b"
		reason = "kill"
	elif alive[1] == 0:
		winner = "a"
		reason = "kill"
	elif time >= time_limit:
		winner = "draw"
		reason = "time"
	if winner != "":
		end_fight(winner, reason)


## Ends the fight now (the sandbox's stop, the time limit, a side wiped out) and emits fight_ended(result).
func end_fight(winner: String, reason: String) -> Dictionary:
	if ended:
		return result
	ended = true
	running = false
	game_over = true
	result = build_result(winner, reason)
	if log_enabled:
		_log("%5.1fs  END: %s (%s)" % [time, "draw" if winner == "draw" else "side %s wins" % winner.to_upper(), reason])
	fight_ended.emit(result)
	return result


## The result Dictionary (one JSON line of the runner).
func build_result(winner: String, reason: String) -> Dictionary:
	var a := side_summary(0)
	var b := side_summary(1)
	var lead := "even"
	var va := float(a["value_left"]) / maxf(1.0, float(a["cost"]))
	var vb := float(b["value_left"]) / maxf(1.0, float(b["cost"]))
	if va > vb + 0.02:
		lead = "a"
	elif vb > va + 0.02:
		lead = "b"
	var r := {"spec": spec_name, "arm": arm_name, "seed": seed_value, "swap": swap, "winner": winner,
			"reason": reason, "time": snappedf(time, 0.01), "lead": lead, "a": a, "b": b}
	for k: String in extra:
		r[k] = extra[k]
	return r


func side_summary(s: int) -> Dictionary:
	var types := {}
	var n := 0
	var alive := 0
	var hp_left := 0.0
	var hp_max := 0.0
	var value_left := 0.0
	var dealt := 0.0
	var taken := 0.0
	var cost := 0
	var pop := 0
	for id: int in records:
		var r: Dictionary = records[id]
		if int(r["side"]) != s:
			continue
		var u := (r["unit"] as WeakRef).get_ref() as Unit
		var is_alive := u != null and u.is_alive()
		var hp := u.hp if is_alive else 0.0
		var mx := u.max_hp if u != null else float(r["hp_max"])
		var tid := String(r["id"])
		var row: Dictionary = types.get(tid, {"n": 0, "alive": 0, "hp_left": 0.0, "hp_max": 0.0, "dealt": 0.0,
				"taken": 0.0, "kills": 0, "alive_time": 0.0, "cost": 0, "pop": 0, "summon": bool(r["summon"])})
		row["n"] += 1
		row["alive"] += 1 if is_alive else 0
		row["hp_left"] += hp
		row["hp_max"] += mx
		row["dealt"] += float(r["dealt"])
		row["taken"] += float(r["taken"])
		row["kills"] += int(r["kills"])
		var died := float(r["died"])
		row["alive_time"] += (died if died >= 0.0 else time) - float(r["born"])
		row["cost"] += int(r["cost"])
		row["pop"] += int(r["pop"])
		types[tid] = row
		n += 1
		alive += 1 if is_alive else 0
		hp_left += hp
		hp_max += mx
		dealt += float(r["dealt"])
		taken += float(r["taken"])
		cost += int(r["cost"])
		pop += int(r["pop"])
		if mx > 0.0:
			value_left += float(r["cost"]) * hp / mx
	for tid: String in types:
		var row: Dictionary = types[tid]
		for k: String in ["hp_left", "hp_max", "dealt", "taken", "alive_time"]:
			row[k] = snappedf(float(row[k]), 0.1)
	return {"label": String((sides[s] as Dictionary).get("label", "")) if sides[s] is Dictionary else "",
			"n": n, "alive": alive, "hp_left": snappedf(hp_left, 0.1), "hp_max": snappedf(hp_max, 0.1),
			"value_left": snappedf(value_left, 0.1), "dealt": snappedf(dealt + _other_dealt[s], 0.1),
			"taken": snappedf(taken, 0.1), "cost": cost, "pop": pop, "casts": _casts[s].duplicate(),
			"first_cast": _first_cast[s].duplicate(), "types": types, "team": side_team[s]}


# ---------------------------------------------------------------- reset

## Frees every unit, projectile, wall, haze and commander (everything but the arena's own infra) and the records.
func clear_units() -> void:
	running = false
	ended = false
	game_over = false
	for c in get_children():
		if _infra.has(c):
			continue
		remove_child(c)
		c.queue_free()
	for grp: StringName in [&"bowman_upgrades", &"unit_upgrades"]:
		for n in get_tree().get_nodes_in_group(grp) if is_inside_tree() else []:
			n.queue_free()
	records.clear()
	_commanders = [null, null]
	_casts = [{}, {}]
	_carried = [{}, {}]
	_first_cast = [{}, {}]
	_other_dealt.assign([0.0, 0.0])
	log_lines.clear()
	time = 0.0
	CasterKit.reset()
	AICasters.reset_history()
