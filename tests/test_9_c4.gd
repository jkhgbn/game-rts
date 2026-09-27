extends SceneTree
## Task 9.C4: BountyBoard / Bounty / SightMarker / fog sources / champions opening Lost Caches
## (docs/design/champions.md "Done when" 9.C4). A small scene (fog + banks + stub champions); no map.
## Run:  godot --headless --path . -s tests/test_9_c4.gd --fixed-fps 60 --quit-after 14000

const TASK_ID := "9.C4"


## Stands in for Champion (9.C1): the members the board and the cache use.
class StubChampion extends Node3D:
	var team := 0
	var purse := 50
	var xp := 0
	var display_name := "Stub"
	var alive := true

	func is_alive() -> bool:
		return alive

	func add_purse(n: int) -> void:
		purse += n

	func add_xp(n: int) -> void:
		xp += n

	func take_damage(_amount: float, _attacker: Node3D = null) -> void:
		pass

	func target_radius() -> float:
		return 0.45


var errors: Array[String] = []
var _done := false
var level: Node3D
var fog: FogOfWar
var board: BountyBoard
var eboard: BountyBoard
var bank_p: EssenceBank
var bank_e: EssenceBank
var pmsgs: Array[String] = []
var emsgs: Array[String] = []
var ended: Dictionary = {}          # bounty instance id -> reason
var cache_loot: Dictionary = {}
var cache_opener: Node = null
var c1: StubChampion
var c2: StubChampion


func _initialize() -> void:
	level = Node3D.new()
	level.name = "Level"
	root.add_child(level)
	current_scene = level
	_run.call_deferred()


func _process(_delta: float) -> bool:
	return _done


func _run() -> void:
	await process_frame
	fog = FogOfWar.new()
	fog.name = "Fog"
	level.add_child(fog)
	bank_p = EssenceBank.for_team(0)
	bank_p.trickle_enabled = false
	bank_p.essence = 2000
	bank_e = EssenceBank.for_team(1)
	bank_e.trickle_enabled = false
	bank_e.essence = 0
	board = BountyBoard.for_team(0)
	eboard = BountyBoard.for_team(1)
	_check(board != null and board == BountyBoard.for_team(0) and board != eboard, "for_team: one board per team")
	board.message.connect(func(t: String) -> void: pmsgs.append(t))
	eboard.message.connect(func(t: String) -> void: emsgs.append(t))
	board.bounty_ended.connect(func(b: Node, reason: StringName) -> void: ended[b.get_instance_id()] = reason)
	SightMarker.spawn(0, Vector3.ZERO, 24.0, 0.0, level)   # permanent PLAYER vision around the origin
	fog.update_team(0)
	fog.update_team(1)
	_check(fog.is_visible(0, Vector3(5, 0, 5)) and not fog.is_visible(0, Vector3(50, 0, 50)),
			"fog_sources: a permanent SightMarker stamps PLAYER vision")
	await _phase_place()
	await _phase_explore()
	await _phase_hunt()
	await _phase_visibility()
	await _phase_cache()
	await _phase_timed()
	if errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(errors)])
	_done = true


# ---------------------------------------------------------------- place / raise / remove

func _phase_place() -> void:
	_check(board.place(Bounty.EXPLORE, null, Vector3(-20, 0, 20)) == "No champions", "No champions first")
	c1 = _champ(0, Vector3(-50, 0, -50), "Sable Quint")
	_check(board.min_stake(Bounty.HUNT) == 75 and board.min_stake(Bounty.EXPLORE) == 25
			and board.min_stake(Bounty.GUARD) == 50 and board.min_stake(Bounty.ESCORT) == 50, "min stakes")
	var far_shade := _unit(1, Vector3(45, 0, 45), "Shade")
	_check(board.kind_for(far_shade) == Bounty.HUNT and board.kind_for(null) == Bounty.EXPLORE, "kind_for")
	_check(board.place(Bounty.HUNT, far_shade, far_shade.global_position) == "Invalid target",
			"Hunt on an unseen unit refused")
	var enemy_hall := Building.new()
	enemy_hall.team = Unit.Team.ENEMY
	level.add_child(enemy_hall)
	enemy_hall.global_position = Vector3(10, 0, -10)
	_check(board.place(Bounty.GUARD, enemy_hall, enemy_hall.global_position) == "Invalid target",
			"Guard on an enemy building refused")
	var site := Building.new()
	site.team = Unit.Team.PLAYER
	site.make_site()
	level.add_child(site)
	site.global_position = Vector3(-10, 0, 10)
	_check(board.kind_for(site) == Bounty.GUARD, "kind_for own building = GUARD")
	_check(board.place(Bounty.GUARD, site, site.global_position) == "Invalid target", "Guard on a site refused")
	_check(board.place(Bounty.EXPLORE, null, Vector3(70, 0, 0)) == "Invalid target", "Explore off the map refused")
	_check(board.place(Bounty.ESCORT, c1, c1.global_position) == "Invalid target", "Escort on a champion refused")
	bank_p.essence = 10
	_check(board.place(Bounty.EXPLORE, null, Vector3(-20, 0, 20)) == "Not enough essence", "Not enough essence")
	bank_p.essence = 2000
	for p: Vector3 in [Vector3(-20, 0, 20), Vector3(0, 0, 40), Vector3(20, 0, -20), Vector3(40, 0, 0),
			Vector3(-40, 0, 0)]:
		_check(board.place(Bounty.EXPLORE, null, p) == "", "place Explore at %s" % p)
	_check(board.bounties.size() == 5 and bank_p.essence == 1875, "5 Explore flags cost 125 (%d)" % bank_p.essence)
	# Explore within 8 m of another Explore flag raises that one.
	_check(board.place(Bounty.EXPLORE, null, Vector3(-17, 0, 22)) == "" and board.bounties.size() == 5
			and board.bounties[0].stake == 50 and bank_p.essence == 1850, "Explore merge within 8 m raises +25")
	_check(board.place(Bounty.EXPLORE, null, Vector3(50, 0, -50)) == "Too many bounties", "max 5 bounties")
	var b0: Bounty = board.bounties[0]
	_check(board.raise(b0, 1000) == "" and b0.stake == 500 and bank_p.essence == 1400, "raise clipped at 500")
	_check(board.raise(b0, 25) == "Max bounty", "Max bounty")
	var before := bank_p.essence
	_check(board.remove(b0) == 500 and bank_p.essence == before + 500, "remove without pursuers refunds 100 %")
	var b1: Bounty = board.bounties[0]
	pmsgs.clear()
	b1.add_pursuer(c1)
	_check(pmsgs.has("Sable Quint took your scouting bounty"), "took-bounty message (%s)" % str(pmsgs))
	_check(b1.refund_preview() == 13, "refund preview 50 %")
	var purse0 := c1.purse
	var xp0 := c1.xp
	before = bank_p.essence
	_check(board.remove(b1) == 13 and bank_p.essence == before + 13 and c1.purse == purse0 + 12
			and c1.xp == xp0 + 6, "remove with a pursuer: 13 back, 12 walk fee (purse %d)" % (c1.purse - purse0))
	for b: Bounty in board.bounties.duplicate():
		board.remove(b)
	_check(board.bounties.is_empty(), "all removed")
	await _wait(0.1)
	_check(root.get_tree().get_nodes_in_group(&"bounties").is_empty(), "ended flags leave group 'bounties'")
	far_shade.queue_free()


# ---------------------------------------------------------------- Explore

func _phase_explore() -> void:
	c2 = _champ(0, Vector3(-50, 0, 50), "Tamsin Farrow")
	var before := bank_p.essence
	_check(board.place(Bounty.EXPLORE, null, Vector3(-10, 0, -10), 100) == "" and bank_p.essence == before - 100,
			"Explore with stake 100")
	var b: Bounty = board.bounties.back()
	var id := b.get_instance_id()
	var p1 := c1.purse
	var x1 := c1.xp
	var p2 := c2.purse
	await _wait(0.5)
	_check(not ended.has(id), "Explore not paid while nobody is near")
	c2.global_position = Vector3(-10.0 + 3.9, 0, -10)
	c1.global_position = Vector3(-10.0 + 3.0, 0, -10)
	await _wait(0.5)
	_check(ended.get(id) == &"paid" and c1.purse == p1 + 100 and c2.purse == p2,
			"Explore pays the first (nearest) champion within 4 m all (c1 +%d, c2 +%d)" % [c1.purse - p1, c2.purse - p2])
	_check(c1.xp == x1 + 50, "bounty XP = half the payment (%d)" % (c1.xp - x1))
	_check(pmsgs.has("Bounty paid: 100 to Sable Quint"), "Bounty paid message")
	c1.global_position = Vector3(-50, 0, -50)
	c2.global_position = Vector3(-50, 0, 50)


# ---------------------------------------------------------------- Hunt

func _phase_hunt() -> void:
	var e1 := _unit(1, Vector3(5, 0, 5), "Shade")
	fog.update_team(0)
	emsgs.clear()
	_check(board.place(Bounty.HUNT, e1, e1.global_position) == "", "Hunt on a visible Shade")
	var h: Bounty = board.bounty_on(e1)
	_check(h != null and h.stake == 75 and emsgs.size() == 1 and emsgs[0] == "A bounty of 75 is on your Shade!",
			"hunted owner warned at placement (%s)" % str(emsgs))
	_check(h != null and board.hunts_on(1).has(h) and BountyBoard.all_hunts_on(1).has(h)
			and board.hunts_on(0).is_empty(), "hunts_on lists it")
	_check(board.place(Bounty.HUNT, e1, e1.global_position) == "" and h.stake == 100 and emsgs.size() == 1
			and board.bounties.size() == 1, "placing on a flagged target raises +25, no new warning")
	_check(board.raise(h, 100) == "" and h.stake == 200 and emsgs.size() == 2
			and emsgs[1] == "A bounty of 200 is on your Shade!", "raise +100 warns again")
	var id := h.get_instance_id()
	var p1 := c1.purse
	var p2 := c2.purse
	var x2 := c2.xp
	e1.take_damage(1.0, c1)
	e1.take_damage(1.0, c2)
	await _wait(0.2)
	e1.take_damage(99999.0, c1)
	await _wait(0.1)
	_check(ended.get(id) == &"paid" and c1.purse == p1 + 100 and c2.purse == p2 + 100 and c2.xp == x2 + 50,
			"Hunt split equally between the 2 contributors (+%d / +%d)" % [c1.purse - p1, c2.purse - p2])

	# Pursuer within 12 m counts, one 35 m away does not.
	var e3 := _unit(1, Vector3(-5, 0, 5), "Shade")
	_check(board.place(Bounty.HUNT, e3, e3.global_position) == "", "Hunt 2")
	var h3: Bounty = board.bounty_on(e3)
	var id3 := h3.get_instance_id()
	pmsgs.clear()
	c2.global_position = Vector3(-5, 0, 14)
	c1.global_position = Vector3(-5, 0, 40)
	h3.add_pursuer(c2)
	h3.add_pursuer(c1)
	_check(pmsgs.has("Tamsin Farrow took your bounty on the Shade"), "took-bounty message (%s)" % str(pmsgs))
	p1 = c1.purse
	p2 = c2.purse
	e3.take_damage(99999.0, null)
	await _wait(0.1)
	_check(ended.get(id3) == &"paid" and c2.purse == p2 + 75 and c1.purse == p1,
			"Hunt pays the pursuer within 12 m only (+%d / +%d)" % [c2.purse - p2, c1.purse - p1])

	# Damage older than 10 s and no pursuer: 100 % refund.
	c1.global_position = Vector3(-50, 0, -50)
	c2.global_position = Vector3(-50, 0, 50)
	var e2 := _unit(1, Vector3(6, 0, -6), "Shade")
	_check(board.place(Bounty.HUNT, e2, e2.global_position) == "", "Hunt 3")
	var id2 := board.bounty_on(e2).get_instance_id()
	e2.take_damage(1.0, c1)
	await _wait(11.0)
	var before := bank_p.essence
	p1 = c1.purse
	pmsgs.clear()
	e2.take_damage(99999.0, null)
	await _wait(0.1)
	_check(ended.get(id2) == &"no_contributor" and bank_p.essence == before + 75 and c1.purse == p1,
			"no contributor: 100 %% refund (%s, bank +%d)" % [str(ended.get(id2)), bank_p.essence - before])
	_check(pmsgs.has("Bounty refunded: 75"), "refund message (%s)" % str(pmsgs))


# ---------------------------------------------------------------- enemy vision

func _phase_visibility() -> void:
	fog.local_team = Unit.Team.PLAYER
	_check(board.place(Bounty.EXPLORE, null, Vector3(0, 0, -40)) == "", "Explore for the visibility check")
	var b: Bounty = board.bounties.back()
	await _wait(0.3)
	_check(b.is_shown() and b.is_visible_to(0) and not b.is_visible_to(1), "own flag shown, enemy has no vision")
	var marker := SightMarker.spawn(1, Vector3(0, 0, -40), 8.0, 1.0, level)
	fog.update_team(1)
	_check(fog.is_visible(1, Vector3(0, 0, -40)) and b.is_visible_to(1), "enemy SightMarker gives vision")
	fog.local_team = Unit.Team.ENEMY
	await _wait(0.3)
	_check(b.is_shown(), "enemy view: flag shown inside its vision")
	await _wait(1.2)
	fog.update_team(1)
	_check(not is_instance_valid(marker), "SightMarker frees itself after its lifetime")
	_check(not fog.is_visible(1, Vector3(0, 0, -40)) and fog.is_explored(1, Vector3(0, 0, -40))
			and not b.is_visible_to(1), "vision gone after the marker")
	await _wait(0.3)
	var click := b.get_node(^"ClickBody") as StaticBody3D
	_check(not b.is_shown() and click.collision_layer == 0, "enemy view: flag hidden and not clickable")
	fog.local_team = Unit.Team.PLAYER
	await _wait(0.3)
	_check(b.is_shown() and click.collision_layer == 2 and b.is_in_group(&"bounties"), "own view: shown, layer 2")
	board.remove(b)


# ---------------------------------------------------------------- Lost Cache

func _phase_cache() -> void:
	var seed_found := -1
	for s in 500:
		var rng := RandomNumberGenerator.new()
		rng.seed = s
		if rng.randf() < ItemDrops.LOOT_ESSENCE:
			seed_found = s
			break
	var cache := LostCache.new()
	cache.first_delay = 0.2
	cache.rng.seed = seed_found
	level.add_child(cache)
	cache.global_position = Vector3(30, 0, -30)
	cache.opened.connect(func(_c: Node, who: Node, loot: Dictionary) -> void:
		cache_loot = loot
		cache_opener = who)
	var c3 := _champ(1, Vector3(30, 0, -30.5), "Silas Quint")
	var enemy_bank := bank_e.essence
	await _wait(0.6)
	_check(cache_opener == c3 and cache_loot.get("given") == "purse" and cache_loot.has("essence")
			and c3.purse == 50 + int(cache_loot.get("essence", -999)) and bank_e.essence == enemy_bank,
			"a champion opening a Lost Cache puts the essence in its purse (%s, purse %d)" % [str(cache_loot), c3.purse])


# ---------------------------------------------------------------- timers: Hunt expiry, Guard, Escort

func _phase_timed() -> void:
	var e4 := _unit(1, Vector3(8, 0, 0), "Shade")
	fog.update_team(0)
	_check(board.place(Bounty.HUNT, e4, e4.global_position) == "", "Hunt 4")
	var hx: Bounty = board.bounty_on(e4)
	var idx := hx.get_instance_id()
	var g1 := Building.new()
	g1.team = Unit.Team.PLAYER
	level.add_child(g1)
	g1.global_position = Vector3(-20, 0, 0)
	_check(board.place(Bounty.GUARD, g1, g1.global_position, 90) == "", "Guard 90")
	var hg: Bounty = board.bounty_on(g1)
	var idg := hg.get_instance_id()
	var u1 := _unit(0, Vector3(20, 0, -20), "Flame Guard")
	_check(board.kind_for(u1) == Bounty.ESCORT, "kind_for own unit = ESCORT")
	_check(board.place(Bounty.ESCORT, u1, u1.global_position, 90) == "", "Escort 90")
	var he: Bounty = board.bounty_on(u1)
	var ide := he.get_instance_id()
	c1.global_position = Vector3(-20, 0, 5)     # 5 m from the guarded building
	c2.global_position = Vector3(20, 0, -17)    # 3 m from the escorted unit
	var p1 := c1.purse
	var p2 := c2.purse
	_check(absf(hg.time_left() - 180.0) < 0.1 and hx.time_left() < 0.0, "time_left at placement")
	await _wait(0.5)
	e4.global_position = Vector3(50, 0, 50)     # leaves the team's vision
	await _wait(1.0)
	_check(not hx.is_tracking() and Vector2(hx.global_position.x - 8.0, hx.global_position.z).length() < 0.5
			and hx.time_left() > 57.0 and hx.time_left() < 60.0,
			"unseen Hunt target: flag stays on the last seen spot (%s, %.1f s left)" % [hx.global_position, hx.time_left()])
	await _wait(19.0)                           # 20.5 s since placement
	_check(c2.purse == p2 + 20 and he.paid == 20 and he.ticks_paid == 2,
			"Escort pays stake / 9 every 10 s within 10 m (+%d)" % (c2.purse - p2))
	var before := bank_p.essence
	u1.take_damage(99999.0, null)
	await _wait(0.1)
	_check(ended.get(ide) == &"target_died" and bank_p.essence == before + 70,
			"Escort target died: rest refunded (+%d)" % (bank_p.essence - before))
	await _wait(10.4)                           # 31 s
	_check(c1.purse == p1 + 30 and hg.ticks_paid == 3, "Guard pays stake / 9 every 10 s within 14 m (+%d)" % (c1.purse - p1))
	c1.global_position = Vector3(-50, 0, -50)   # leaves: later ticks are kept
	before = bank_p.essence
	await _wait(31.0)                           # 62 s: 60 s unseen since ~1 s
	_check(ended.get(idx) == &"expired" and bank_p.essence == before + 75,
			"Hunt expires 60 s after the target is unseen, 100 %% refund (%s)" % str(ended.get(idx)))
	before = bank_p.essence
	_check(not ended.has(idg) and hg.ticks_paid == 3, "Guard still running, nobody near")
	await _wait(119.0)                          # 181 s
	_check(ended.get(idg) == &"expired" and bank_p.essence == before + 60 and c1.purse == p1 + 30,
			"Guard: at 180 s the unpaid rest is refunded (%s, +%d)" % [str(ended.get(idg)), bank_p.essence - before])


# ---------------------------------------------------------------- helpers

func _champ(team: int, pos: Vector3, champ_name: String) -> StubChampion:
	var c := StubChampion.new()
	c.team = team
	c.display_name = champ_name
	c.name = champ_name.replace(" ", "")
	c.add_to_group(&"champions")
	level.add_child(c)
	c.global_position = pos
	return c


func _unit(team: int, pos: Vector3, unit_label: String) -> Unit:
	var u := Unit.new()
	u.team = team as Unit.Team
	u.unit_name = unit_label
	level.add_child(u)
	u.global_position = pos
	u.set_physics_process(false)   # no navmesh here: it just stands (and never fights back)
	return u


func _wait(seconds: float) -> void:
	for i in roundi(seconds * 60.0):
		await physics_frame


func _check(ok: bool, what: String) -> void:
	if not ok:
		errors.append(what)
		print("  check failed: %s" % what)
