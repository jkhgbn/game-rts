extends SceneTree
## Task 12.C11: EpicBeasts (docs/design/map-fill.md 5.5, contract section 13, "Done when" 12.C11).
## A small scene without a map: a stub level (match clock, beasts_enabled), stub beast UnitTypes (the 8 .tres of 12.C4
## may not exist yet), a stub BeastBrain and a stub CreatureAbilities, stub wizards (level, add_xp); real Units as
## killers, real EssenceBanks, real items.
## Run:  godot --headless --path . -s tests/test_12_c11.gd --fixed-fps 60 --quit-after 3000

const TASK_ID := "12.C11"

const LEVEL_SRC := """
extends Node3D
var clock := 0.0
var beasts_enabled := true
func match_time() -> float:
	return clock
"""

const BRAIN_SRC := """
extends Node
var beast: Node
var lair: Dictionary = {}
func setup(b: Node, l: Dictionary) -> void:
	beast = b
	lair = l
	b.set_physics_process(false)   # no navmesh here: it just stands
"""

const ABIL_SRC := """
extends Node
var unit: Node
var ids: Array[StringName] = []
func setup(u: Node, a: Array[StringName]) -> void:
	unit = u
	ids = a
"""

const WIZ_SRC := """
extends Node3D
var team := 0
var level := 1
var xp_got := 0
func add_xp(amount: int) -> void:
	xp_got += amount
func is_alive() -> bool:
	return true
"""

## kill_xp and HP per beast type (map-fill.md 5.5).
const TYPES := {
	&"ironhide_tusker": [110, 1800.0], &"old_scarback": [130, 2160.0],
	&"stormcrest_roc": [100, 1500.0], &"duskwing_roc": [100, 1500.0],
	&"greymane_direwolf": [90, 1300.0], &"moonpelt_direwolf": [105, 1300.0],
	&"grizzlemaw": [180, 2600.0], &"elder_grizzlemaw": [210, 3000.0],
}

var errors: Array[String] = []
var _done := false
var level
var eb: EpicBeasts
var wiz_p
var wiz_e
var spawned: Array = []     # [beast, lair_id, variant]
var slain: Array = []       # [beast, team, drops]
var msgs: Array[String] = []
var bank_p: EssenceBank
var bank_e: EssenceBank
var soldier_type: UnitType


func _initialize() -> void:
	var ls := GDScript.new()
	ls.source_code = LEVEL_SRC
	ls.reload()
	level = Node3D.new()
	level.set_script(ls)
	level.name = "Level"
	root.add_child(level)
	current_scene = level
	_run.call_deferred()


func _process(_delta: float) -> bool:
	return _done


func _run() -> void:
	await process_frame
	_build()
	await _phase_schedule()
	await _phase_kill_underdog()
	await _phase_respawn_block()
	await _phase_kill_enemy()
	_phase_drop_tables()
	_phase_grant()
	await _phase_disabled()
	if errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(errors)])
	_done = true


func _check(cond: bool, what: String) -> void:
	if not cond:
		errors.append(what)


func _script(src: String) -> GDScript:
	var s := GDScript.new()
	s.source_code = src
	s.reload()
	return s


func _build() -> void:
	bank_p = EssenceBank.new()
	bank_p.team = 0
	bank_p.trickle_enabled = false
	level.add_child(bank_p)
	bank_e = EssenceBank.new()
	bank_e.team = 1
	bank_e.trickle_enabled = false
	level.add_child(bank_e)
	var ws := _script(WIZ_SRC)
	wiz_p = Node3D.new()
	wiz_p.set_script(ws)
	wiz_p.add_to_group("heroes")
	level.add_child(wiz_p)
	wiz_e = Node3D.new()
	wiz_e.set_script(ws)
	wiz_e.team = 1
	wiz_e.add_to_group("enemy_heroes")
	level.add_child(wiz_e)
	wiz_e.global_position = Vector3(80, 0, 80)
	soldier_type = UnitType.find("flame_guard")
	eb = EpicBeasts.new()
	eb.name = "EpicBeasts"
	for id: StringName in TYPES:
		var t := UnitType.new()
		t.id = id
		t.display_name = String(id).capitalize()
		t.faction = &"neutral"
		t.kill_xp = int(TYPES[id][0])
		t.max_hp = float(TYPES[id][1])
		t.aggro_range = 0.0
		t.neutral_leash = false
		eb.unit_types[id] = t
	eb.brain_script = _script(BRAIN_SRC)
	eb.abilities_script = _script(ABIL_SRC)
	level.add_child(eb)
	eb.setup(EpicBeasts.default_lairs())
	eb.beast_spawned.connect(func(b: Node, id: StringName, v: int) -> void: spawned.append([b, id, v]))
	eb.beast_slain.connect(func(b: Node, t: int, d: Array) -> void: slain.append([b, t, d]))
	eb.message.connect(func(text: String, _s: float) -> void: msgs.append(text))


func _at(t: float) -> void:
	level.clock = t
	for i in 20:   # > TICK (0.25 s = 15 frames at 60 fps)
		await physics_frame


func _alive_ids() -> Array:
	var out: Array = []
	for b in eb.beasts():
		out.append(str(b.get_meta(&"lair_id")))
	out.sort()
	return out


func _soldier(team: int, pos: Vector3) -> Unit:
	var u := Worker.make_unit(soldier_type)
	u.team = team as Unit.Team
	level.add_child(u)
	u.global_position = pos
	u.set_physics_process(false)
	return u


# ------------------------------------------------------------------ phases

func _phase_schedule() -> void:
	var lairs := eb.lairs()
	_check(lairs.size() == 8, "8 lairs, got %d" % lairs.size())
	var west := 0
	for l in lairs:
		if (l["center"] as Vector3).x < 0.0:
			west += 1
	_check(west == 4, "4 lairs per bank, got %d west" % west)
	_check(EpicBeasts.instance(self) == eb, "instance() finds the node")
	await _at(0.0)
	_check(eb.beasts().is_empty(), "nothing alive at 0:00")
	_check(is_equal_approx(eb.respawn_left(&"lair_heath_w"), 390.0), "West Heath first spawn in 390 s")
	await _at(389.0)
	_check(eb.beasts().is_empty(), "nothing alive at 6:29")
	await _at(390.0)
	_check(_alive_ids() == ["lair_heath_e", "lair_heath_w"],"Tuskers at 6:30, got %s" % str(_alive_ids()))
	await _at(449.0)
	_check(eb.beasts().size() == 2, "still 2 beasts at 7:29")
	await _at(450.0)
	_check(eb.beasts().size() == 4, "Direwolves at 7:30, got %d" % eb.beasts().size())
	await _at(510.0)
	_check(eb.beasts().size() == 6, "Rocs at 8:30, got %d" % eb.beasts().size())
	await _at(600.0)
	_check(eb.beasts().size() == 8, "Grizzlemaws at 10:00, got %d" % eb.beasts().size())
	_check(get_nodes_in_group("beasts").size() == 8, "8 in group beasts")
	var tusker: Unit = eb.beast_of(&"lair_heath_w")
	_check(tusker != null and int(tusker.team) == 2, "beast is NEUTRAL")
	_check(tusker != null and tusker.is_in_group(&"units"), "beast is a Unit in group units")
	_check(eb.spawn_count(&"lair_heath_w") == 1 and eb.variant_of(&"lair_heath_w") == 0, "first spawn = variant A")
	_check(tusker != null and tusker.unit_type.id == &"ironhide_tusker", "West Heath gets an Ironhide Tusker")
	_check(tusker != null and tusker.global_position.distance_to(Vector3(-53, 0, 13)) < 0.5, "spawned at the lair centre")
	_check(eb.strength_of(tusker) == 900.0, "Tusker A strength 900")
	_check(eb.lair_of(tusker).get("kind") == &"tusker", "lair_of")
	# Brain and abilities.
	var brains: Array = []
	for c in eb.get_children():
		if c.get(&"beast") != null:
			brains.append(c)
	_check(brains.size() == 8, "one brain per beast, got %d" % brains.size())
	for br in brains:
		if br.beast == tusker:
			_check(is_equal_approx(float(br.lair["leash"]), 14.0), "leash = radius 4 + 10")
			_check((br.lair["patrol"] as PackedVector3Array).size() == 4, "4 patrol points")
			_check(int(br.lair["variant"]) == 0, "brain gets variant 0")
	var ab := tusker.get_node_or_null(^"CreatureAbilities") if tusker else null
	_check(ab != null and ab.ids == [&"gore_charge", &"bristle_hide"], "Tusker abilities set up")
	var roc: Node = eb.beast_of(&"lair_crag_w")
	var rab := roc.get_node_or_null(^"CreatureAbilities") if roc else null
	_check(rab != null and rab.ids == [&"gale_swoop", &"updraft"], "Roc A abilities")
	_check(msgs.has("An Ironhide Tusker roams the West Heath"), "spawn message, got %s" % str(msgs))
	_check(msgs.has("A Grizzlemaw roams the Old Wood Den"), "Grizzlemaw spawn message")
	_check(spawned.size() == 8, "beast_spawned x8")


func _phase_kill_underdog() -> void:
	var tusker: Unit = eb.beast_of(&"lair_heath_w")
	wiz_p.level = 2
	wiz_e.level = 3
	_check(eb.underdog_team() == 0, "underdog = player (lower level)")
	wiz_p.global_position = tusker.global_position + Vector3(5, 0, 0)
	eb.rewards[&"tusker"] = {&"essence": 7, &"food": 40}
	var ess0 := bank_p.essence
	var pickups0 := get_nodes_in_group("item_pickups").size()
	var killer := _soldier(0, tusker.global_position + Vector3(2, 0, 0))
	msgs.clear()
	level.clock = 700.0
	tusker.take_damage(1.0e7, killer)
	await physics_frame
	_check(slain.size() == 1 and slain[0][1] == 0, "beast_slain team 0, got %s" % str(slain))
	var drops: Array = slain[0][2] if slain.size() == 1 else []
	_check(drops.size() >= 1, "Tusker A drops >= 1 item")
	_check(get_nodes_in_group("item_pickups").size() - pickups0 == drops.size(), "drops lie on the ground")
	_check(wiz_p.xp_got == roundi(110 * 0.25), "underdog +25 %% XP to the wizard: %d" % wiz_p.xp_got)
	# + the normal kill essence (60 % of 110) when the Events autoload runs (EssenceBank listens to unit_died).
	var kill_ess := EssenceBank.kill_essence(110) if root.get_node_or_null(^"Events") != null else 0
	_check(bank_p.essence - ess0 == 7 + kill_ess, "reward essence paid (%d, kill %d)" % [bank_p.essence - ess0, kill_ess])
	_check(is_equal_approx(float(eb.granted_totals.get(0, {}).get(&"food", 0.0)), 40.0), "food kept, not paid")
	_check(msgs.size() == 1 and msgs[0].begins_with("Your army slew the Ironhide Tusker + ") \
			and msgs[0].ends_with("(underdog bonus: +25 % XP)"), "slain message, got %s" % str(msgs))
	_check(is_equal_approx(eb.respawn_left(&"lair_heath_w"), 600.0), "respawn in 600 s")
	_check(eb.variant_of(&"lair_heath_w") == 1, "next spawn = variant B")
	_check(eb.beasts().size() == 7, "7 alive")
	eb.rewards[&"tusker"] = {}
	killer.queue_free()
	for p in get_nodes_in_group("item_pickups"):
		p.queue_free()


func _phase_respawn_block() -> void:
	var blocker := _soldier(1, Vector3(-53, 0, 13) + Vector3(20, 0, 0))   # 20 m < 25 m
	await _at(1300.0)
	_check(eb.beast_of(&"lair_heath_w") == null, "respawn blocked by a unit within 25 m")
	_check(eb.respawn_left(&"lair_heath_w") == 0.0, "due and waiting")
	blocker.global_position = Vector3(-53, 0, 13) + Vector3(30, 0, 0)   # 30 m
	await _at(1302.0)
	_check(eb.beast_of(&"lair_heath_w") == null, "retry only every 5 s")
	await _at(1305.5)
	var b: Unit = eb.beast_of(&"lair_heath_w")
	_check(b != null and b.unit_type.id == &"old_scarback", "second spawn = Old Scarback")
	_check(eb.spawn_count(&"lair_heath_w") == 2 and eb.variant_of(&"lair_heath_w") == 1, "spawn 2 = variant B")
	_check(b != null and int(b.get_meta(&"beast_variant")) == 1, "variant meta")
	_check(eb.strength_of(b) == 1080.0, "Tusker B strength 1080")
	_check(msgs.has("Old Scarback, an alpha Tusker, roams the West Heath!"), "variant B spawn message")
	# An east-bank Grizzlemaw: the mirror lair.
	var gm: Unit = eb.beast_of(&"lair_den_e")
	_check(gm != null and gm.global_position.distance_to(Vector3(26, 0, 54)) < 0.5, "mirror lair at (26, 54)")
	blocker.queue_free()


func _phase_kill_enemy() -> void:
	var b: Unit = eb.beast_of(&"lair_heath_w")
	if b == null:
		errors.append("no Old Scarback to kill")
		return
	wiz_p.level = 3
	wiz_e.level = 3
	wiz_e.xp_got = 0
	_check(eb.underdog_team() == -1, "equal levels: no underdog")
	var killer := _soldier(1, b.global_position + Vector3(2, 0, 0))
	msgs.clear()
	slain.clear()
	b.take_damage(1.0e7, killer)
	await physics_frame
	_check(slain.size() == 1 and slain[0][1] == 1, "slain by the enemy")
	var drops: Array = slain[0][2] if slain.size() == 1 else []
	_check(drops.size() >= 2, "Old Scarback drops >= 2 items, got %s" % str(drops))
	_check(wiz_e.xp_got == 0, "no underdog XP when levels are equal")
	_check(msgs == ["The enemy slew Old Scarback"], "enemy slain message, got %s" % str(msgs))
	killer.queue_free()
	# Third spawn: variant A again.
	var third: Unit = eb.spawn_now(&"lair_heath_w")
	_check(third != null and third.unit_type.id == &"ironhide_tusker" and eb.spawn_count(&"lair_heath_w") == 3,
			"third spawn = variant A")
	for p in get_nodes_in_group("item_pickups"):
		p.queue_free()


func _phase_drop_tables() -> void:
	const TUSK := [&"ironbark_plate", &"bone_charm", &"swiftsoles", &"vital_root"]
	for i in 200:
		var ta := eb.roll_drops(&"tusker", 0)
		var tb := eb.roll_drops(&"tusker", 1)
		var ra := eb.roll_drops(&"roc", 0)
		var rb := eb.roll_drops(&"roc", 1)
		var da := eb.roll_drops(&"direwolf", 0)
		var db := eb.roll_drops(&"direwolf", 1)
		var ga := eb.roll_drops(&"grizzlemaw", 0)
		var gb := eb.roll_drops(&"grizzlemaw", 1)
		if ta.size() < 1 or ta.size() > 2 or tb.size() < 2 or tb.size() > 3:
			errors.append("tusker drop counts %s / %s" % [ta, tb])
			return
		for id in ta + tb:
			if not TUSK.has(id):
				errors.append("tusker drop %s" % id)
				return
		if ra.has(&"duskglass") or ra.has(&"gloom_ink") or rb.has(&"swiftsoles") or rb.has(&"cinder_ring"):
			errors.append("roc variant lists %s / %s" % [ra, rb])
			return
		if da.has(&"vital_root") or da.size() != 1 or db.size() < 1:
			errors.append("direwolf %s / %s" % [da, db])
			return
		if not gb.has(&"warden_scale") or ga.size() < 1:
			errors.append("grizzlemaw %s / %s" % [ga, gb])
			return
		for trophy in [&"ironhide_tusk", &"scarback_tusk", &"stormcrest_plume", &"duskwing_plume", &"greymane_pelt",
				&"moonpelt_pelt", &"grizzlemaw_claw", &"elder_grizzlemaw_claw"]:
			if ItemType.find(trophy) == null and (ta + tb + ra + rb + da + db + ga + gb).has(trophy):
				errors.append("trophy %s dropped without an item" % trophy)
				return
	# Chances roughly right (30 % Vital Root on Tusker A, 40 % on Direwolf B).
	var vr := 0
	var dvr := 0
	for i in 1000:
		if eb.roll_drops(&"tusker", 0).has(&"vital_root"):
			vr += 1
		if eb.roll_drops(&"direwolf", 1).has(&"vital_root"):
			dvr += 1
	_check(vr > 240 and vr < 360, "Tusker A vital root ~30 %%: %d / 1000" % vr)
	_check(dvr > 340 and dvr < 460, "Direwolf B vital root ~40 %%: %d / 1000" % dvr)


func _phase_grant() -> void:
	var e0 := bank_e.essence
	eb.grant(1, {&"essence": 3, &"food": 5, &"weird": 1}, null)
	_check(bank_e.essence - e0 == 3, "grant pays essence")
	var gt: Dictionary = eb.granted_totals.get(1, {})
	_check(is_equal_approx(float(gt.get(&"food", 0.0)), 5.0) and is_equal_approx(float(gt.get(&"weird", 0.0)), 1.0),
			"grant keeps unknown keys: %s" % str(gt))
	_check(is_equal_approx(float(eb.paid_totals.get(1, {}).get(&"essence", 0.0)), 3.0), "paid_totals")
	eb.grant(2, {&"essence": 3}, null)
	_check(not eb.granted_totals.has(2) and not eb.paid_totals.has(2), "neutral team gets nothing")


func _phase_disabled() -> void:
	level.beasts_enabled = false
	eb.setup(EpicBeasts.default_lairs())   # despawns everything, counts restart
	await physics_frame
	await _at(5000.0)
	_check(eb.beasts().is_empty(), "beasts_enabled = false spawns nothing")
	level.beasts_enabled = true
	await _at(5001.0)
	_check(eb.beasts().size() == 8, "enabled again: all 8 spawn (all first spawns are due)")
