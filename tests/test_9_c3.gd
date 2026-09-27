extends SceneTree
## Task 9.C3: taverns on Crown Hollow, ChampionGuild (hire / costs / pop / refusals / door choice / names /
## upkeep / unpaid / revive / dismiss) and the campaign companion (docs/design/champions.md 2, 3, 11).
## Champions are stubs (StubChampion below) so the test doesn't depend on 9.C1 (Champion / ChampionType):
## the guild's hooks `champion_script` / `type_lookup` point at them. Set USE_REAL_CHAMPION once 9.C1 has
## landed to run the same checks with the real Champion (it needs respawn(at) and to stay in the tree while fallen).
## Run:  godot --headless --path . -s tests/test_9_c3.gd --fixed-fps 60 --quit-after 7000

const TASK_ID := "9.C3"
const TIMEOUT_FRAMES := 6800
const SCENE := "res://scenes/skirmish.tscn"
const USE_REAL_CHAMPION := false
const TEST_SAVE := "user://test_9_c3_campaign.json"
const P := 0   # Unit.Team.PLAYER
const E := 1   # Unit.Team.ENEMY
const NAMES := {
	&"wayfinder": ["Tamsin Farrow", "Tobin Farrow"],
	&"oathwall": ["Garran Stoneward", "Gerda Stoneward"],
	&"coin_cutter": ["Sable Quint", "Silas Quint"],
	&"mender": ["Orla Fenwick", "Osric Fenwick"],
}


class StubType extends Resource:
	var id: StringName = &""
	var names := PackedStringArray()


class StubInventory extends RefCounted:
	var slots: Array = [null, null, null, null]
	var item_value := 0

	func add_item(type: Resource, count: int = 1, _cooldown_left: float = 0.0) -> bool:
		for i in slots.size():
			if slots[i] == null:
				slots[i] = {"type": type, "count": count, "cooldown_left": 0.0}
				return true
		return false

	func total_item_value() -> int:
		return item_value


## Enough of the Champion contract for the guild: team / champion_type / variant / display_name / purse /
## is_unpaid / inventory, add_purse / spend_purse, respawn(at), stays in the tree (hidden) while fallen.
## Every archetype but the Mender carries a UnitType with pop 2 (Economy counts it); the Mender has none
## (the guild must reserve its pop itself): both paths are tested.
class StubChampion extends Unit:
	var champion_type: Resource
	var variant := 0
	var display_name := ""
	var purse := 0
	var is_unpaid := false
	var inventory: Object

	func setup(type: Resource, v: int) -> void:
		champion_type = type
		variant = v
		inventory = StubInventory.new()
		if StringName(type.get(&"id")) != &"mender":
			var ut := UnitType.new()
			ut.pop = 2
			ut.id = StringName(type.get(&"id"))
			unit_type = ut

	func _ready() -> void:
		var names: PackedStringArray = champion_type.get(&"names")
		display_name = names[variant]
		unit_name = display_name
		add_to_group("champions")
		super()

	func add_purse(n: int) -> void:
		purse += n

	func spend_purse(n: int) -> bool:
		if n > purse:
			return false
		purse -= n
		return true

	func respawn(at: Vector3) -> void:
		_revive(at)

	func _on_death_finished() -> void:
		visible = false


var main: Node
var total := 0
var _done := false
var _errors: Array[String] = []
var _hired: Array = []       # [frame, team, champion]
var _fallen: Array = []
var _revived: Array = []
var _ticks := {P: [], E: []}  # team -> [[frame, paid, amount]]
var _messages: Array[String] = []
var _opened := 0
var _types := {}


func _initialize() -> void:
	main = load(SCENE).instantiate()
	var bot: Node = main.get_node_or_null("ShadowBot")
	if bot:
		bot.set("enabled", false)   # the bot would hire, build and fight
	root.add_child(main)
	current_scene = main
	_run()


func _process(_delta: float) -> bool:
	total += 1
	if total > TIMEOUT_FRAMES and not _done:
		_errors.append("timed out at frame %d" % total)
		return _finish()
	return _done


func _finish() -> bool:
	if _errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(_errors)])
	_done = true
	return true


func _check(cond: bool, what: String) -> void:
	if not cond:
		_errors.append(what)
		print("  x ", what)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _until(cond: Callable, max_frames: int) -> bool:
	for i in max_frames:
		if bool(cond.call()):
			return true
		await process_frame
	return bool(cond.call())


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _stub_type(id: StringName) -> Resource:
	if not _types.has(id):
		var t := StubType.new()
		t.id = id
		t.names = PackedStringArray(NAMES.get(id, ["?", "?"]))
		_types[id] = t
	return _types[id]


# ---------------------------------------------------------------- the run

func _run() -> void:
	if not await _until(func() -> bool: return main.hero != null, 5000):
		_errors.append("navigation never finished baking")
		_finish()
		return
	await _frames(10)
	var gp: ChampionGuild = ChampionGuild.for_team(P)
	var ge: ChampionGuild = ChampionGuild.for_team(E)
	_check(gp != null and ge != null and gp != ge, "one ChampionGuild per team")
	if gp == null or ge == null:
		_finish()
		return
	for g: ChampionGuild in [gp, ge]:
		if not USE_REAL_CHAMPION:
			g.champion_script = StubChampion
			g.type_lookup = _stub_type
		g.champion_hired.connect(func(ch: Node) -> void: _hired.append([total, g.team, ch]))
		g.champion_fallen.connect(func(ch: Node) -> void: _fallen.append(ch))
		g.champion_revived.connect(func(ch: Node) -> void: _revived.append([total, ch]))
		g.upkeep_ticked.connect(func(paid: bool, amount: int) -> void: _ticks[g.team].append([total, paid, amount]))
	gp.message.connect(func(t: String, _s: float) -> void: _messages.append(t))

	await _map_checks(gp)
	await _open_checks(gp)
	await _player_hires(gp)
	await _enemy_refusals(ge)
	await _upkeep(gp, ge)
	await _unpaid(gp)
	await _revive(gp)
	await _dismiss(gp)
	await _companion(gp)
	await _no_home(ge)
	_finish()


## Taverns at (-15, -15) / (15, 15), neutral, invulnerable, not targets, layer 1 + 2, clearing 6, block the
## build grid and the navmesh, door at spot x 0.8, explored for both teams at 0:00; missions have no taverns.
func _map_checks(gp: ChampionGuild) -> void:
	var taverns := root.get_tree().get_nodes_in_group("taverns")
	_check(taverns.size() == 2, "2 taverns (got %d)" % taverns.size())
	var spots: Array[Vector3] = [Vector3(-15, 0, -15), Vector3(15, 0, 15)]
	var map: RID = main.nav_region.get_navigation_map()
	for spot in spots:
		var t: Node3D = null
		for n: Node3D in taverns:
			if _flat(n.global_position, spot) < 0.1:
				t = n
		_check(t != null, "a tavern at %s" % spot)
		if t == null:
			continue
		_check(int(t.get("team")) == 2, "tavern team NEUTRAL")
		_check(not t.is_in_group("units") and not t.is_in_group("buildings"), "tavern is never a target (no units / buildings group)")
		t.call("take_damage", 99999.0, null)
		_check(bool(t.call("is_alive")) and not bool(t.call("is_targetable")), "tavern invulnerable")
		_check(((t as CollisionObject3D).collision_layer & 3) == 3, "tavern on layers 1 and 2")
		_check(t.get_parent() == main.nav_region, "tavern under the NavigationRegion3D")
		var door: Vector3 = t.call("door_point")
		# Lead: door moved to 5 m from the centre (just outside the 9.V6 art's door corner), toward the crown.
		_check(absf(_flat(door, spot) - 5.0) < 0.05 and door.length() < spot.length(), "door 5 m in front, toward the crown (%s)" % door)
		# Clearing r 6: no tree / rock centre within 6 m.
		for c in main.nav_region.get_children():
			if c is StaticBody3D and c != t and _flat((c as Node3D).global_position, spot) < 6.0:
				_check(false, "clearing: obstacle %s at %.1f m from %s" % [c.name, _flat(c.global_position, spot), spot])
		# Build grid: every 6 x 6 cell is refused.
		var tower := BuildingType.find("fire_tower")
		for off in [Vector3.ZERO, Vector3(-2, 0, -2), Vector3(2, 0, 2), Vector3(-2, 0, 2), Vector3(2, 0, -2)]:
			var reason: String = main.build_grid.check(tower, spot + off, P)
			_check(reason == BuildGrid.MSG_NOT_WALKABLE or reason == BuildGrid.MSG_BLOCKED,
					"build grid refuses a tower at %s (got '%s')" % [spot + off, reason])
		# Navmesh: a hole where the tavern stands (a path from the door to the back goes around it; the
		# closest-point query is no proof: it answers inside keeps too), walkable at the door.
		var back := spot * 1.2
		var path := NavigationServer3D.map_get_path(map, door, back, true)
		var length := 0.0
		var ground := true
		for k in range(1, path.size()):
			length += path[k - 1].distance_to(path[k])
			ground = ground and path[k].y < 1.0
		_check(path.size() >= 2 and ground and length > door.distance_to(back) + 1.5,
				"path door -> back goes around the tavern (%.1f m, straight %.1f)" % [length, door.distance_to(back)])
		var qd := NavigationServer3D.map_get_closest_point(map, door)
		_check(_flat(qd, door) < 0.6, "door on the navmesh (%.2f m)" % _flat(qd, door))
		for team in [P, E]:
			_check(main.fog.is_explored(team, spot) and main.fog.is_explored(team, door), "tavern %s explored for team %d at 0:00" % [spot, team])
	_check(main.fog.enabled, "fog on")
	_check(bool(main.get("tavern_enabled")), "the skirmish has taverns")
	var m1: Node = load("res://scripts/campaign/mission_01.gd").new()
	_check(not bool(m1.get("tavern_enabled")), "mission 1 has no taverns (tavern_enabled false)")
	m1.free()
	var plain := Node.new()
	_check(not CampaignState.tavern_enabled(plain), "a level without the flag has no taverns")
	plain.free()
	# Closed until 2:00.
	_check(not gp.is_open(), "closed at 0:00")
	_check(gp.can_hire(&"coin_cutter") == "Tavern closed", "0:00: Tavern closed (got '%s')" % gp.can_hire(&"coin_cutter"))
	_check(gp.hire(&"coin_cutter") == "Tavern closed", "hire refused while closed")
	_check(Tavern.MSG_CLOSED == "The tavern opens at 2:00", "closed window line")
	_check((taverns[0] as Tavern).time_until_open() > 100.0, "time until open")
	_check(gp.can_hire(&"nobody") == "Unknown champion", "unknown id refused")


## 2:00: both taverns open, message + hint once.
func _open_checks(gp: ChampionGuild) -> void:
	for t in root.get_tree().get_nodes_in_group("taverns"):
		(t as Tavern).opened.connect(func(_x: Tavern) -> void: _opened += 1)
	for team in [P, E]:
		Economy.for_team(team).crystals = 5000
		var bank := EssenceBank.for_team(team)
		bank.trickle_enabled = false
		bank.essence = 5000
	main.set("_match_time", 119.8)
	await _frames(30)
	_check(_opened == 2, "both taverns opened at 2:00 (%d)" % _opened)
	_check(gp.is_open(), "open after 2:00")
	var msg: String = (main.hud.get("_message") as Label).text
	_check(msg.contains(Tavern.MSG_OPEN) and msg.contains(Tavern.HINT_HIRE), "open message + hint (got '%s')" % msg)
	await _frames(30)
	_check(_opened == 2, "opened only once")


## 3 hires: 225+75, 275+100, 325+125 (step-11 prices), pop 2 each, Max 3, the free door nearer the wizard, 3 s, name A.
func _player_hires(gp: ChampionGuild) -> void:
	main.hero.global_position = Vector3(-24, 0, -4)   # nearer the (-15, -15) tavern (the start is equidistant)
	main.hero.command_stop()
	await _frames(20)
	var eco := Economy.for_team(P)
	var bank := EssenceBank.for_team(P)
	var costs := [[&"coin_cutter", 225, 75], [&"oathwall", 275, 100], [&"mender", 325, 125]]
	var hire_frame := total
	for row in costs:
		var c0 := eco.crystals
		var e0 := bank.essence
		var p0 := eco.pop_used
		var cost := gp.hire_cost(row[0])
		_check(int(cost["crystals"]) == row[1] and int(cost["essence"]) == row[2], "hire_cost %s = %s" % [row[0], cost])
		var r := gp.hire(row[0])
		_check(r == "", "hire %s (got '%s')" % [row[0], r])
		_check(eco.crystals == c0 - row[1] and bank.essence == e0 - row[2], "%s paid %d + %d" % [row[0], row[1], row[2]])
		_check(eco.pop_used == p0 + 2, "%s takes pop 2 at once (%d -> %d)" % [row[0], p0, eco.pop_used])
	_check(gp.roster_size() == 3 and gp.champions.is_empty() and gp.is_hiring(&"mender"), "3 on their way, none out yet")
	_check(gp.can_hire(&"wayfinder") == "Max 3 champions", "Max 3 champions (got '%s')" % gp.can_hire(&"wayfinder"))
	_check(gp.can_hire(&"coin_cutter") == "Max 3 champions", "Max 3 comes before Already hired")
	main.set("_match_time", 1.0)
	_check(gp.can_hire(&"wayfinder") == "Tavern closed", "Tavern closed comes before Max 3")
	main.set("_match_time", 125.0)
	await _frames(170)
	_check(gp.champions.is_empty(), "nobody out after 2.8 s")
	await _until(func() -> bool: return gp.champions.size() == 3, 30)
	_check(gp.champions.size() == 3, "3 champions out after 3 s")
	var door := Vector3(-12, 0, -12)
	for h in _hired:
		var dt: int = int(h[0]) - hire_frame
		_check(dt >= 178 and dt <= 183, "walks out 3 s after paying (%d frames)" % dt)
	var i := 0
	for ch: Node3D in gp.champions:
		var id := gp.archetype_of(ch)
		_check(_flat(ch.global_position, door) < 1.5, "%s at the free door nearer the wizard (%s)" % [id, ch.global_position])
		_check(int(ch.get("variant")) == 0 and str(ch.get("display_name")) == NAMES[id][0], "%s gets name A" % id)
		_check(int(ch.get("purse")) == 50, "%s purse 50" % id)
		_check(int(ch.get("team")) == P and ch.is_in_group("units"), "%s is a PLAYER unit" % id)
		_park(ch, Vector3(-44 + i * 2.0, 0, 20))
		i += 1
	_check(_messages.has("Sable Quint joins you"), "join message")
	var ge := ChampionGuild.for_team(E)
	_check(ge.next_name(&"coin_cutter") == "Silas Quint" and ge.next_name(&"wayfinder") == "Tamsin Farrow",
			"next_name: B after the other side's hire, else A")
	_hired.clear()


## ENEMY: every refusal after Max / Already, in order; then name B for the archetype the player hired first.
func _enemy_refusals(ge: ChampionGuild) -> void:
	var eco := Economy.for_team(E)
	var bank := EssenceBank.for_team(E)
	var holders: Array[Unit] = []
	for door in [Vector3(-12, 0, -12), Vector3(12, 0, 12)]:
		holders.append(main._spawn(main.make_unit("flame_guard"), P, door + Vector3(1, 0, 0)))
	var fill: int = eco.pop_cap - eco.pop_used - 1
	if fill > 0:
		eco.reserve_pop(fill)
	eco.crystals = 0
	bank.essence = 0
	await _frames(20)
	_check(ge.can_hire(&"coin_cutter") == "Population cap reached", "Population cap reached (got '%s')" % ge.can_hire(&"coin_cutter"))
	if fill > 0:
		eco.release_pop(fill)
	_check(ge.can_hire(&"coin_cutter") == "Not enough crystals", "Not enough crystals (got '%s')" % ge.can_hire(&"coin_cutter"))
	eco.crystals = 5000
	_check(ge.can_hire(&"coin_cutter") == "Not enough essence", "Not enough essence (got '%s')" % ge.can_hire(&"coin_cutter"))
	bank.essence = 5000
	_check(ge.can_hire(&"coin_cutter") == "Enemies hold both taverns", "Enemies hold both taverns (got '%s')" % ge.can_hire(&"coin_cutter"))
	_check(ge.hire(&"coin_cutter") == "Enemies hold both taverns" and eco.crystals == 5000, "a refused hire pays nothing")
	_check(ge.held_taverns().size() == 2 and ChampionGuild.for_team(P).held_taverns().is_empty(), "held_taverns()")
	holders[1].queue_free()
	await _frames(20)
	_check(ge.can_hire(&"coin_cutter") == "", "hire ok once one tavern is free (got '%s')" % ge.can_hire(&"coin_cutter"))
	_check(ge.hire(&"wayfinder") == "", "enemy hires the Wayfinder first")
	_check(ge.hire(&"coin_cutter") == "", "enemy hires the Coin-Cutter")
	_check(ge.can_hire(&"coin_cutter") == "Already hired", "Already hired (got '%s')" % ge.can_hire(&"coin_cutter"))
	holders[0].queue_free()
	await _until(func() -> bool: return ge.champions.size() == 2, 200)
	for ch: Node3D in ge.champions:
		var id := ge.archetype_of(ch)
		_check(_flat(ch.global_position, Vector3(12, 0, 12)) < 1.5, "enemy %s at the only free door" % id)
		var want := 1 if id == &"coin_cutter" else 0
		_check(int(ch.get("variant")) == want and str(ch.get("display_name")) == NAMES[id][want],
				"enemy %s gets name %s (%s)" % [id, "B" if want == 1 else "A", ch.get("display_name")])
	var i := 0
	for ch: Node3D in ge.champions:
		_park(ch, Vector3(44 - i * 2.0, 0, -20))
		i += 1
	_hired.clear()


## 1 essence per living champion every 10 s.
func _upkeep(gp: ChampionGuild, ge: ChampionGuild) -> void:
	EssenceBank.for_team(P).essence = 500
	EssenceBank.for_team(E).essence = 500
	_ticks[P].clear()
	_ticks[E].clear()
	await _until(func() -> bool: return _ticks[P].size() >= 2 and _ticks[E].size() >= 1, 1300)
	_check(_ticks[P].size() >= 2, "two player upkeep ticks")
	if _ticks[P].size() >= 2:
		var dt: int = int(_ticks[P][1][0]) - int(_ticks[P][0][0])
		_check(absi(dt - 600) <= 1, "upkeep every 10 s (%d frames)" % dt)
		_check(bool(_ticks[P][0][1]) and int(_ticks[P][0][2]) == 3, "player pays 3 (3 living)")
		_check(EssenceBank.for_team(P).essence == 500 - 3 * _ticks[P].size(), "bank - 3 per tick (%d)" % EssenceBank.for_team(P).essence)
	if _ticks[E].size() >= 1:
		_check(int(_ticks[E][0][2]) == 2, "enemy pays 2 (2 living)")
	_check(gp.living_count() == 3 and ge.living_count() == 2, "living counts")


## 3 failed ticks in a row -> Unpaid (message once); the next paid tick clears it.
func _unpaid(gp: ChampionGuild) -> void:
	gp.upkeep_interval = 0.5
	gp.set("_upkeep_left", 0.5)
	EssenceBank.for_team(P).essence = 0
	_ticks[P].clear()
	_messages.clear()
	await _until(func() -> bool: return _ticks[P].size() >= 2, 80)
	_check(not gp.unpaid and not bool(gp.champions[0].get("is_unpaid")), "not unpaid after 2 failed ticks")
	await _until(func() -> bool: return _ticks[P].size() >= 3, 40)
	_check(gp.unpaid, "unpaid after 3 failed ticks")
	for ch in gp.champions:
		_check(bool(ch.get("is_unpaid")), "%s is_unpaid" % gp.archetype_of(ch))
	await _until(func() -> bool: return _ticks[P].size() >= 5, 80)
	_check(_messages.count(ChampionGuild.MSG_UNPAID) == 1, "unpaid message once (%d)" % _messages.count(ChampionGuild.MSG_UNPAID))
	EssenceBank.for_team(P).essence = 100
	var n: int = _ticks[P].size()
	await _until(func() -> bool: return _ticks[P].size() > n, 40)
	_check(not gp.unpaid, "paid tick clears unpaid")
	for ch in gp.champions:
		_check(not bool(ch.get("is_unpaid")), "%s paid again" % gp.archetype_of(ch))
	gp.upkeep_interval = 10.0
	gp.set("_upkeep_left", 10.0)


## Fallen keeps its slot and pop; revive 80 + 35 x level (step 11) after 15 + 5 x level s at the keep spawn point.
func _revive(gp: ChampionGuild) -> void:
	var eco := Economy.for_team(P)
	var bank := EssenceBank.for_team(P)
	var ch: Unit = gp.champion_of(&"oathwall")
	ch.level = 2
	var pop0 := eco.pop_used
	_check(gp.can_revive(ch) == "Not fallen", "alive: Not fallen")
	ch.take_damage(99999.0, null)
	await _frames(5)
	_check(_fallen.has(ch) and gp.is_fallen(ch) and gp.champions.has(ch), "fallen, still in the roster")
	_check(eco.pop_used == pop0, "fallen keeps its pop (%d -> %d)" % [pop0, eco.pop_used])
	_check(gp.living_count() == 2, "upkeep counts only the living")
	_check(gp.revive_cost(ch) == 150 and absf(gp.revive_duration(ch) - 25.0) < 0.01, "L2 revive = 150 essence, 25 s")
	bank.essence = 50
	_check(gp.can_revive(ch) == "Not enough essence", "revive: Not enough essence")
	bank.essence = 1000
	var r := gp.revive(ch)
	var start := total
	_check(r == "" and bank.essence == 850, "revive paid 150 (got '%s', %d)" % [r, bank.essence])
	_check(absf(gp.revive_time_left(ch) - 25.0) < 0.1, "revive_time_left 25")
	_check(gp.can_revive(ch) == "Already reviving", "no second revive")
	_check(_messages.has("Garran Stoneward returns in 25 s"), "returns message")
	await _frames(1480)
	_check(not ch.is_alive(), "still fallen before 25 s")
	await _until(func() -> bool: return ch.is_alive(), 40)
	_check(ch.is_alive(), "back after 25 s")
	if not _revived.is_empty():
		var dt: int = int(_revived[0][0]) - start
		_check(absi(dt - 1500) <= 3, "revive took 25 s (%d frames)" % dt)
	var home: Vector3 = main.keep.spawn_point()
	_check(_flat(ch.global_position, home) < 1.5, "revived at the keep spawn point (%s vs %s)" % [ch.global_position, home])
	_check(ch.hp >= ch.max_hp, "full HP")
	_check(eco.pop_used == pop0, "pop unchanged after revive (%d)" % eco.pop_used)
	_park(ch, Vector3(-44, 0, 22))


## Dismiss: 50 % purse + 50 % items to the bank, slot and pop freed; the free-door rule with one tavern held.
func _dismiss(gp: ChampionGuild) -> void:
	var eco := Economy.for_team(P)
	var bank := EssenceBank.for_team(P)
	var mender: Node = gp.champion_of(&"mender")
	mender.set("purse", 60)
	mender.get("inventory").set("item_value", 200)
	var b0 := bank.essence
	var p0 := eco.pop_used
	var refund := gp.dismiss(mender)
	_check(refund == 130 and bank.essence == b0 + 130, "dismiss pays 30 + 100 (%d)" % refund)
	_check(eco.pop_used == p0 - 2, "dismiss frees pop 2 (%d -> %d)" % [p0, eco.pop_used])
	_check(gp.roster_size() == 2 and not gp.has_archetype(&"mender"), "slot freed")
	_check(_messages.has("Orla Fenwick leaves your service"), "leaves message")
	await _frames(70)
	_check(not is_instance_valid(mender), "faded out and freed after 1 s")
	# One tavern held by an enemy: the champion walks out of the other one, even though it is farther.
	var shade: Unit = main._spawn(main.make_unit("shade"), E, Vector3(-11.5, 0, -12))
	bank.essence = 1000
	eco.crystals = 1000
	await _frames(20)
	var cost := gp.hire_cost(&"wayfinder")
	_check(int(cost["crystals"]) == 325 and int(cost["essence"]) == 125, "3rd price again (%s)" % cost)
	_check(gp.hire(&"wayfinder") == "", "hire the Wayfinder")
	await _until(func() -> bool: return gp.champion_of(&"wayfinder") != null, 200)
	var wf: Node3D = gp.champion_of(&"wayfinder")
	_check(wf != null and _flat(wf.global_position, Vector3(12, 0, 12)) < 1.5, "held tavern skipped: out of the (12, 12) door")
	if wf:
		_check(int(wf.get("variant")) == 1 and str(wf.get("display_name")) == "Tobin Farrow", "name B: the enemy hired its Wayfinder first")
		_park(wf, Vector3(-44, 0, 24))
	shade.queue_free()
	# A fallen champion can be dismissed too.
	var cc: Unit = gp.champion_of(&"coin_cutter")
	cc.take_damage(99999.0, null)
	await _frames(5)
	b0 = bank.essence
	p0 = eco.pop_used
	_check(gp.dismiss(cc) == 25 and bank.essence == b0 + 25, "fallen dismiss pays 50 % of the purse")
	_check(eco.pop_used == p0 - 2, "fallen dismiss frees its pop")
	await _frames(5)
	_check(not is_instance_valid(cc), "fallen dismissed champion removed")


## Companion: saved (id, variant, 4 items, purse 50 % cap 300), reloaded, restored as roster slot 1.
func _companion(gp: ChampionGuild) -> void:
	var wf: Node = gp.champion_of(&"wayfinder")
	wf.set("purse", 800)
	var wf_inv: Object = wf.get("inventory")
	var wf_slots: Array = wf_inv.get("slots")
	wf_slots[0] = {"type": &"ember_shard", "count": 1}
	wf_inv.set("slots", wf_slots)
	var cs := CampaignState.open(TEST_SAVE)
	cs.reset()
	_check(cs.companion_candidates(main).has(wf), "the choice screen lists the hired champions")
	_check(cs.choose_companion(wf) == OK, "companion saved")
	var cs2 := CampaignState.open(TEST_SAVE)
	var c := cs2.companion
	_check(str(c.get("id", "")) == "wayfinder" and int(c.get("variant", -1)) == 1 and int(c.get("purse", -1)) == 300,
			"companion round-trip (%s)" % c)
	var items: Array = c.get("items", [])
	_check(items.size() == 4 and items[0] is Dictionary and str(items[0]["id"]) == "ember_shard" and items[1] == null,
			"companion items (%s)" % [items])
	_check(CampaignState.companion_purse(121) == 60 and CampaignState.companion_purse(1000) == 300, "purse 50 %, cap 300")
	for ch in gp.champions.duplicate():
		gp.dismiss(ch)
	await _frames(70)
	_check(gp.roster_size() == 0, "roster empty before the next mission")
	var comp: Node3D = cs2.apply_companion(main)
	_check(comp != null, "companion spawned")
	if comp:
		_check(gp.roster_size() == 1 and gp.archetype_of(comp) == &"wayfinder", "companion is roster slot 1")
		_check(int(comp.get("variant")) == 1 and int(comp.get("purse")) == 300 and int(comp.get("level")) == 1,
				"companion variant / purse / level 1")
		var inv_slots: Array = comp.get("inventory").get("slots")
		if ItemDrops.item_type(&"ember_shard") != null:
			_check(inv_slots[0] is Dictionary and StringName(inv_slots[0]["type"].get("id")) == &"ember_shard", "companion items restored")
		_check(_flat(comp.global_position, main.hero.global_position) < 4.5, "companion beside the wizard")
		var cost := gp.hire_cost(&"coin_cutter")
		_check(int(cost["crystals"]) == 275 and int(cost["essence"]) == 100, "next hire is the 2nd price (%s)" % cost)
		_check(cs2.apply_companion(main) == comp and gp.roster_size() == 1, "applied only once")
	cs2.reset()


## "No home": a fallen champion can't be revived once the team has no keep and no barracks.
func _no_home(ge: ChampionGuild) -> void:
	var cc: Unit = ge.champion_of(&"coin_cutter")
	cc.take_damage(99999.0, null)
	await _frames(5)
	EssenceBank.for_team(E).essence = 0
	_check(ge.can_revive(cc) == "Not enough essence", "enemy: Not enough essence while it has a keep")
	main.shadow_keep.take_damage(1.0e9, null)
	await _frames(5)
	_check(ge.can_revive(cc) == "No home", "No home comes before Not enough essence (got '%s')" % ge.can_revive(cc))
	EssenceBank.for_team(E).essence = 1000
	_check(ge.can_revive(cc) == "No home", "No home without keep / barracks")


func _park(ch: Node3D, at: Vector3) -> void:
	ch.global_position = at
	if ch.has_method("command_stop"):
		ch.call("command_stop")
