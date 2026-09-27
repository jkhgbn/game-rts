extends SceneTree
## Task 10.C10 (market-trade.md 9 / 12 / 14, "Done when" 10.C9 / 10.C10): the trade unit models are plugged.
## - data/units/caravan|magpie|greywater_tracker.tres have `model_scene` = their `model_path` scene, and spawned units
##   use the model (no placeholder capsule; the caravan skips its placeholder strongbox).
## - Public Unit wrappers: model_call / model_has, get_loot / set_loot (meta &"loot" + set_carrying), play_snatch /
##   cancel_snatch / is_snatching, team_kingdom_color / refresh_team_color.
## - The caravan's set_loaded follows its cargo; a Magpie shows its sack while loot > 0; shroud plays the flee.
## - Faction-less types (caravan, tracker) wear the owning team's kingdom colour (Economy kingdom, else the team's
##   wizard, else the level's player_kingdom / enemy_kingdom, else fire / shadow); Magpies get none.
## - A tracker's snare arrow plays TradeVfx `snare` on the victim it roots; other on-hit statuses do not.
## Run:  godot --headless --path . -s tests/test_10_c10.gd --fixed-fps 60 --quit-after 2400
## A small world (floor + flat navmesh, no UI) so other agents' files do not matter.

const TASK_ID := "10.C10"
const P := 0   # Unit.Team.PLAYER
const E := 1   # Unit.Team.ENEMY
const N := 2   # Unit.Team.NEUTRAL

const MODELS := {
	&"caravan": "res://art/units/caravan/caravan.tscn",
	&"magpie": "res://art/units/neutral/magpie/magpie.tscn",
	&"greywater_tracker": "res://art/units/neutral/tracker/tracker.tscn",
}
const TRADE_VFX_PATH := "res://art/vfx/trade_vfx.gd"

## Stub model: records the hooks Unit sends it.
const STUB_MODEL_SRC := "extends Node3D\nvar colors: Array = []\nvar calls: Array = []\n" \
		+ "func set_team_color(c: Color) -> void:\n\tcolors.append(c)\n" \
		+ "func set_carrying(on: bool) -> void:\n\tcalls.append([&\"set_carrying\", on])\n" \
		+ "func play_snatch() -> void:\n\tcalls.append([&\"play_snatch\"])\n" \
		+ "func cancel_snatch() -> void:\n\tcalls.append([&\"cancel_snatch\"])\n" \
		+ "func sum(a: int, b: int) -> int:\n\treturn a + b\n"
## Stub TradeVfx (group "trade_vfx"): records every play.
const STUB_VFX_SRC := "extends Node3D\nvar plays: Array = []\n" \
		+ "func _ready() -> void:\n\tadd_to_group(&\"trade_vfx\")\n" \
		+ "func play(id: StringName, at: Variant, target: Variant = null) -> void:\n" \
		+ "\tvar rooted := false\n" \
		+ "\tif target != null and is_instance_valid(target) and target.has_method(&\"has_status\"):\n" \
		+ "\t\trooted = target.has_status(&\"rooted\")\n" \
		+ "\tplays.append({\"id\": id, \"at\": at, \"target\": target, \"rooted\": rooted})\n"
## Stub wizard of a team (group "heroes" / "enemy_heroes") with a kingdom.
const STUB_HERO_SRC := "extends Node3D\nvar team := 0\nvar kingdom: StringName = &\"\"\n"

var world: Node3D
var errors: Array[String] = []
var finished := false
var stages := 0
var spawned: Array = []


func _initialize() -> void:
	world = Node3D.new()
	world.name = "TestWorld"
	root.add_child(world)
	current_scene = world
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200.0, 1.0, 200.0)
	shape.shape = box
	ground.add_child(shape)
	ground.position = Vector3(0.0, -0.5, 0.0)
	world.add_child(ground)
	var nav := NavigationMesh.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200.0, 200.0)
	nav.create_from_mesh(plane)
	var region := NavigationRegion3D.new()
	region.navigation_mesh = nav
	world.add_child(region)
	_run()


func _process(_delta: float) -> bool:
	return finished


func _run() -> void:
	await _wait(3)
	_test_data()
	await _test_caravan()
	await _clear()
	await _test_magpie()
	await _clear()
	await _test_kingdom_colors()
	await _clear()
	await _test_model_wrappers()
	await _clear()
	await _test_snare()
	await _clear()
	await _test_real_vfx()
	await _clear()
	# A script error aborts a stage silently: every stage counts itself at its very end.
	_eq(stages, 7, "every stage ran to its end")
	if errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(errors)])
	finished = true


# ---------------------------------------------------------------- data

func _test_data() -> void:
	for id: StringName in MODELS:
		var t := UnitType.find(String(id))
		if t == null:
			_check(false, "data/units/%s.tres loads" % id)
			continue
		_check(t.model_scene != null, "%s has a model_scene" % id)
		if t.model_scene:
			_eq(t.model_scene.resource_path, MODELS[id], "%s model_scene path" % id)
			_eq(t.model_scene.resource_path, t.model_path, "%s model_scene = model_path (section 12)" % id)
			var inst := t.model_scene.instantiate()
			_check(inst is Node3D, "%s model instantiates as a Node3D" % id)
			if inst:
				inst.free()
	stages += 1


# ---------------------------------------------------------------- caravan: set_loaded

func _test_caravan() -> void:
	var eco := _economy(P, &"ice")
	var caravan := _spawn("caravan", P, Vector3(-40.0, 0.0, -40.0))
	await _wait(2)
	_check(caravan.has_model(), "a caravan uses its model")
	var m := caravan.get_model()
	if m == null:
		_check(false, "caravan model present")
		stages += 1
		return
	_check(m.has_method(&"set_loaded"), "the caravan model has set_loaded")
	_eq(caravan.team_kingdom_color(), Unit.KINGDOM_COLORS[&"ice"], "the caravan wears its team's kingdom colour")
	if caravan.has_method(&"command_trade"):
		_eq(caravan.get(&"_cargo_visual"), null, "no placeholder strongbox on a caravan with a model")
		_eq(caravan.model_call(&"is_showing_cargo"), false, "an empty caravan shows no cargo")
		caravan.set(&"cargo", 50)
		_eq(caravan.model_call(&"is_showing_cargo"), true, "a loaded caravan shows its strongbox (set_loaded)")
		var got := int(caravan.call(&"steal", 50, null))
		_eq(got, 50, "steal takes the whole cargo")
		_eq(caravan.model_call(&"is_showing_cargo"), false, "a robbed caravan hides its cargo")
	else:
		print("  (caravan.gd not usable right now: checked the model only)")
	spawned.append(eco)
	stages += 1


# ---------------------------------------------------------------- magpie: loot sack, snatch, flee

func _test_magpie() -> void:
	var magpie := _spawn("magpie", N, Vector3(0.0, 0.0, 40.0))
	await _wait(2)
	_check(magpie.has_model(), "a Magpie uses its model")
	var m := magpie.get_model()
	if m == null:
		_check(false, "Magpie model present")
		stages += 1
		return
	_eq(magpie.team_kingdom_color().a, 0.0, "a Magpie has no kingdom colour")
	_eq(magpie.get_loot(), 0, "no loot at spawn")
	_eq(bool(m.get(&"_carrying")), false, "no sack at spawn")
	magpie.set_loot(45)
	_eq(magpie.get_loot(), 45, "set_loot / get_loot")
	_eq(int(magpie.get_meta(&"loot", 0)), 45, "set_loot writes the meta ThiefBand reads")
	_eq(bool(m.get(&"_carrying")), true, "loot > 0 shows the sack (set_carrying)")
	magpie.set_loot(-5)
	_eq(magpie.get_loot(), 0, "loot never below 0")
	_eq(bool(m.get(&"_carrying")), false, "loot 0 hides the sack")
	magpie.play_snatch()
	await _wait(2)
	_eq(magpie.is_snatching(), true, "play_snatch starts the channel pose")
	magpie.cancel_snatch()
	_eq(magpie.is_snatching(), false, "cancel_snatch ends it")
	magpie.play_snatch()
	await _wait(100)   # 1.67 s > the 1.5 s channel
	_eq(magpie.is_snatching(), false, "the snatch pose ends by itself after 1.5 s")
	_eq(bool(m.get(&"_carrying")), false, "a snatch without loot leaves no sack")
	magpie.apply_status(&"shroud", 2.0, true)
	await _wait(2)
	_eq(bool(m.call(&"is_fleeing")), true, "shroud plays the smoke flee on the model")
	_eq((magpie.get(&"_status_marks") as Dictionary).has(&"shroud"), false, "the model shows shroud (no placeholder)")
	stages += 1


# ---------------------------------------------------------------- kingdom colours

func _test_kingdom_colors() -> void:
	var stub_type := _stub_type("greywater_tracker")
	# 1) the team's Economy kingdom
	var eco := _economy(E, &"nature")
	var t1 := _spawn_type(stub_type, E, Vector3(30.0, 0.0, 0.0))
	_eq(_colors_of(t1), [Unit.KINGDOM_COLORS[&"nature"]], "a hired tracker gets its team's kingdom colour once")
	# 2) no Economy: the team's wizard
	eco.free()
	var hero := Node3D.new()
	hero.set_script(_script(STUB_HERO_SRC))
	hero.set(&"team", E)
	hero.set(&"kingdom", &"ice")
	hero.add_to_group(&"enemy_heroes")
	world.add_child(hero)
	spawned.append(hero)
	var t2 := _spawn_type(stub_type, E, Vector3(32.0, 0.0, 0.0))
	_eq(_colors_of(t2), [Unit.KINGDOM_COLORS[&"ice"]], "no Economy: the team's wizard kingdom")
	# 3) nothing known: fire for the player, shadow for the enemy
	var t3 := _spawn_type(stub_type, P, Vector3(34.0, 0.0, 0.0))
	_eq(_colors_of(t3), [Unit.KINGDOM_COLORS[&"fire"]], "nothing known: fire for the player")
	hero.remove_from_group(&"enemy_heroes")
	var t4 := _spawn_type(stub_type, E, Vector3(36.0, 0.0, 0.0))
	_eq(_colors_of(t4), [Unit.KINGDOM_COLORS[&"shadow"]], "nothing known: shadow for the enemy")
	# refresh_team_color once the kingdom is known
	var eco2 := _economy(E, &"ice")
	spawned.append(eco2)
	t4.refresh_team_color()
	_eq(_colors_of(t4).back(), Unit.KINGDOM_COLORS[&"ice"], "refresh_team_color re-sends the colour")
	# Magpie (neutral) never gets one; a soldier keeps its faction colour.
	var mag_type := _stub_type("magpie")
	var mp := _spawn_type(mag_type, N, Vector3(38.0, 0.0, 0.0))
	_eq(_colors_of(mp).size(), 0, "a Magpie gets no kingdom colour")
	var sc_type := _stub_type("shardcaster")
	var sc := _spawn_type(sc_type, P, Vector3(40.0, 0.0, 0.0))
	_eq(_colors_of(sc), [Unit.KINGDOM_COLORS[&"ice"]], "a faction soldier keeps its own kingdom colour")
	# The real tracker model through the real data.
	var real := _spawn("greywater_tracker", E, Vector3(42.0, 0.0, 0.0))
	await _wait(2)
	_check(real.has_model(), "a tracker uses its model")
	_eq(real.team_kingdom_color(), Unit.KINGDOM_COLORS[&"ice"], "the real tracker's colour = its team's kingdom")
	stages += 1


# ---------------------------------------------------------------- model_call wrappers

func _test_model_wrappers() -> void:
	var u := _spawn_type(_stub_type("magpie"), N, Vector3(-30.0, 0.0, 30.0))
	var m := u.get_model()
	_eq(u.model_call(&"sum", [2, 3]), 5, "model_call passes the arguments and returns the result")
	_eq(u.model_call(&"no_such_hook"), null, "model_call on a missing hook returns null")
	_eq(u.model_has(&"play_snatch"), true, "model_has")
	_eq(u.model_has(&"no_such_hook"), false, "model_has on a missing hook")
	u.set_loot(20)
	u.play_snatch()
	u.cancel_snatch()
	u.set_loot(0)
	_eq(m.get(&"calls"), [[&"set_carrying", true], [&"play_snatch"], [&"cancel_snatch"], [&"set_carrying", false]],
			"set_loot / play_snatch / cancel_snatch reach the model")
	var bare := _spawn("flame_guard", P, Vector3(-26.0, 0.0, 30.0))
	var placeholder_type := UnitType.find("flame_guard").duplicate() as UnitType
	placeholder_type.model_scene = null
	var capsule := _spawn_type(placeholder_type, P, Vector3(-22.0, 0.0, 30.0))
	_eq(capsule.has_model(), false, "a placeholder unit has no model")
	_eq(capsule.model_call(&"play_snatch"), null, "model_call without a model is a no-op")
	_eq(capsule.model_has(&"set_moving"), false, "model_has without a model")
	capsule.set_loot(10)   # no model: only the meta
	_eq(capsule.get_loot(), 10, "set_loot works without a model")
	_eq(capsule.is_snatching(), false, "is_snatching without a model")
	_eq(bare.is_snatching(), false, "is_snatching on a model without the hook")
	stages += 1


# ---------------------------------------------------------------- snare VFX (stub TradeVfx)

func _test_snare() -> void:
	var vfx := Node3D.new()
	vfx.set_script(_script(STUB_VFX_SRC))
	world.add_child(vfx)
	spawned.append(vfx)
	var tracker := _spawn("greywater_tracker", P, Vector3(0.0, 0.0, -40.0))
	var victim := _spawn("shade", E, Vector3(0.0, 0.0, -34.0))
	victim.command_hold()
	await _wait(2)
	tracker.command_attack(victim)
	var plays: Array = vfx.get(&"plays")
	for i in 300:   # 5 s
		await physics_frame
		if not plays.is_empty():
			break
	_check(not plays.is_empty(), "the tracker's hit played a trade effect")
	if not plays.is_empty():
		var p: Dictionary = plays[0]
		_eq(p["id"], &"snare", "the effect is `snare`")
		_eq(p["target"], victim, "on the victim")
		_eq(p["rooted"], true, "the victim is rooted when the snare plays")
		_check(p["at"] is Vector3 and _flat(p["at"], victim.global_position) < 0.5, "at the victim's feet")
	# More hits, one snare each.
	for i in 150:
		await physics_frame
	var hits := 0
	for p: Dictionary in plays:
		if p["id"] == &"snare":
			hits += 1
	_check(hits >= 2, "every rooting hit plays a snare (%d)" % hits)
	# A chill on-hit unit (Shardcaster) plays nothing.
	tracker.command_stop()
	tracker.command_hold()
	plays.clear()
	var caster := _spawn("shardcaster", P, Vector3(20.0, 0.0, -40.0))
	var target2 := _spawn("shade", E, Vector3(20.0, 0.0, -34.0))
	target2.command_hold()
	var hit_flag := [false]
	target2.damage_taken.connect(func(_a: float, by: Node3D) -> void:
		if by == caster:
			hit_flag[0] = true)
	caster.command_attack(target2)
	for i in 300:
		await physics_frame
		if hit_flag[0]:
			break
	await _wait(5)
	_check(hit_flag[0], "control: the Shardcaster hit its target")
	var snares := plays.filter(func(p: Dictionary) -> bool: return p["id"] == &"snare" and p["target"] == target2)
	_eq(snares.size(), 0, "a chill hit plays no snare")
	stages += 1


# ---------------------------------------------------------------- the real TradeVfx

func _test_real_vfx() -> void:
	if not ResourceLoader.exists(TRADE_VFX_PATH):
		print("  (art/vfx/trade_vfx.gd missing: real VFX check skipped)")
		stages += 1
		return
	var script := load(TRADE_VFX_PATH) as GDScript
	if script == null or not script.can_instantiate():
		print("  (art/vfx/trade_vfx.gd does not compile right now: skipped)")
		stages += 1
		return
	var vfx := Node3D.new()
	vfx.set_script(script)
	world.add_child(vfx)
	spawned.append(vfx)
	await _wait(2)
	var tracker := _spawn("greywater_tracker", E, Vector3(-40.0, 0.0, 0.0))
	var victim := _spawn("flame_guard", P, Vector3(-34.0, 0.0, 0.0))
	victim.command_hold()
	await _wait(2)
	tracker.command_attack(victim)
	var seen := false
	for i in 300:
		await physics_frame
		if vfx.has_method(&"active_ids") and (vfx.call(&"active_ids") as Array).has(&"snare"):
			seen = true
			break
	_check(seen, "the real TradeVfx runs `snare` after a tracker hit")
	stages += 1


# ---------------------------------------------------------------- helpers

# A copy of a data type whose model is the recording stub.
func _stub_type(id: String) -> UnitType:
	var t := UnitType.find(id).duplicate() as UnitType
	var holder := Node3D.new()
	holder.set_script(_script(STUB_MODEL_SRC))
	var scene := PackedScene.new()
	scene.pack(holder)
	holder.free()
	t.model_scene = scene
	return t


func _colors_of(u: Unit) -> Array:
	var m := u.get_model()
	return (m.get(&"colors") as Array).duplicate() if m and m.get(&"colors") != null else []


func _economy(team: int, kingdom: StringName) -> Node:
	var eco := Economy.new()
	eco.team = team
	world.add_child(eco)
	eco.set_kingdom(kingdom)
	return eco


func _spawn(id: String, team: int, pos: Vector3) -> Unit:
	return _spawn_type(UnitType.find(id), team, pos)


func _spawn_type(type: UnitType, team: int, pos: Vector3) -> Unit:
	var u: Unit
	if type.is_caravan and ResourceLoader.exists("res://scripts/economy/caravan.gd"):
		var cs := load("res://scripts/economy/caravan.gd") as GDScript
		if cs and cs.can_instantiate():
			u = cs.new() as Unit
			u.apply_type(type)
	if u == null:
		u = type.create_unit()
	u.team = team
	u.position = pos
	world.add_child(u)
	u.command_stop()
	spawned.append(u)
	return u


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _wait(frames: int) -> void:
	for i in frames:
		await physics_frame


func _clear() -> void:
	for n in spawned:
		if is_instance_valid(n):
			n.queue_free()
	spawned.clear()
	for n in world.get_children():
		if n is Projectile or n.is_in_group(&"economies") or n.is_in_group(&"units"):
			n.queue_free()
	await _wait(3)


func _script(src: String) -> GDScript:
	var gs := GDScript.new()
	gs.source_code = src
	gs.reload()
	return gs


func _check(cond: bool, msg: String) -> void:
	if not cond:
		errors.append(msg)
		print("  x %s" % msg)


func _eq(got: Variant, want: Variant, msg: String) -> void:
	_check(got == want, "%s (got %s, want %s)" % [msg, str(got), str(want)])
