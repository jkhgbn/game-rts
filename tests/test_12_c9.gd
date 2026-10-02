extends SceneTree
## Task 12.C9: the creature and beast models are plugged (map-fill.md 10 / 15 row 12.C9).
## Small world like test_12_c4 (flat ground, a hand-made navmesh, a stub MapFillVfx). Checks:
## - hollow_stag + the 8 beast .tres: model_scene = the model_path scene, body_height (stag 2.6, Tusker 2.1 / 2.4,
##   Roc 3.6, Direwolf 1.8, Grizzlemaw 2.6 / 3.0); Gloomcap Elder projectile_speed 14, UnitType default 25 (units
##   that set no speed fly at 25, tiers-wave units with their own speed stay within 12-45);
##   Unit.MAX_UNIT_RADIUS >= every radius in data/units/;
## - every spawned creature / beast builds its model (no placeholder) and shows its variant: set_variant comes from
##   CreatureAbilities too (a B beast spawned without EpicBeasts, attached before or after entering the tree);
## - the play_cast ids reach the models: antler_sweep (stag sweep), gore_charge (Tusker gallop, facing the dash),
##   bristle_hide (bristle spike on a melee reflect), gale_swoop / shrieking_dive / updraft (Roc), pounce (Direwolf),
##   maul / rending_roar / enrage look (Grizzlemaw);
## - the Elder's bolt flies at ~14 m/s, a default ranged unit's at ~25 m/s;
## - a held melee unit finds a Grizzlemaw (radius 1.1) standing in its reach (MAX_UNIT_RADIUS 1.1).
## Run:  godot --headless --path . -s tests/test_12_c9.gd --fixed-fps 60 --quit-after 6000

const TASK_ID := "12.C9"
const P := 0   # Unit.Team.PLAYER
const N := 2   # Unit.Team.NEUTRAL
const VFX_SRC := "extends Node3D\nvar calls: Array = []\nfunc play(id: StringName, at: Vector3, target: Variant) -> void:\n\tcalls.append([id, at, target])\n"

## id: [model scene, body_height, variant]
const MODELS := {
	&"hollow_stag": ["res://art/units/neutral/hollow_stag/hollow_stag.tscn", 2.6, -1],
	&"ironhide_tusker": ["res://art/units/neutral/beasts/tusker/tusker.tscn", 2.1, 0],
	&"old_scarback": ["res://art/units/neutral/beasts/tusker/tusker.tscn", 2.4, 1],
	&"stormcrest_roc": ["res://art/units/neutral/beasts/roc/roc.tscn", 3.6, 0],
	&"duskwing_roc": ["res://art/units/neutral/beasts/roc/roc.tscn", 3.6, 1],
	&"greymane_direwolf": ["res://art/units/neutral/beasts/direwolf/direwolf.tscn", 1.8, 0],
	&"moonpelt_direwolf": ["res://art/units/neutral/beasts/direwolf/direwolf.tscn", 1.8, 1],
	&"grizzlemaw": ["res://art/units/neutral/beasts/grizzlemaw/grizzlemaw.tscn", 2.6, 0],
	&"elder_grizzlemaw": ["res://art/units/neutral/beasts/grizzlemaw/grizzlemaw.tscn", 3.0, 1],
}

var world: Node3D
var vfx: Node3D
var errors: Array[String] = []
var finished := false
var spawned: Array = []
var checks := 0


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
	var nm := NavigationMesh.new()
	nm.vertices = PackedVector3Array([Vector3(-60.0, 0.0, -60.0), Vector3(60.0, 0.0, -60.0),
			Vector3(60.0, 0.0, 60.0), Vector3(-60.0, 0.0, 60.0)])
	nm.add_polygon(PackedInt32Array([0, 1, 2, 3]))
	var region := NavigationRegion3D.new()
	region.navigation_mesh = nm
	world.add_child(region)
	vfx = Node3D.new()
	var gs := GDScript.new()
	gs.source_code = VFX_SRC
	gs.reload()
	vfx.set_script(gs)
	vfx.add_to_group(&"mapfill_vfx")
	world.add_child(vfx)
	_run()


func _process(_delta: float) -> bool:
	return finished


func _run() -> void:
	await _wait(3)
	var map := world.get_world_3d().navigation_map
	var tries := 0
	while NavigationServer3D.map_get_iteration_id(map) <= 0 and tries < 120:
		tries += 1
		await _wait(1)
	_test_data()
	await _test_spawn_models()
	await _clear()
	await _test_stag()
	await _clear()
	await _test_tusker()
	await _clear()
	await _test_roc()
	await _clear()
	await _test_direwolf()
	await _clear()
	await _test_grizzlemaw()
	await _clear()
	await _test_bolt_speed()
	await _clear()
	await _test_held_reach()
	await _clear()
	print("%d checks" % checks)
	if errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		for e in errors:
			print("  - ", e)
		print("FAIL %s: %d problem(s)" % [TASK_ID, errors.size()])
	finished = true


# ---------------------------------------------------------------- data

func _test_data() -> void:
	for id: StringName in MODELS:
		var row: Array = MODELS[id]
		var t := UnitType.find(String(id))
		if t == null:
			errors.append("missing type %s" % id)
			continue
		_check(t.model_scene != null and t.model_scene.resource_path == row[0], "%s model_scene = %s" % [id, row[0]])
		_eq(t.model_path, row[0], "%s model_path" % id)
		_near(t.body_height, float(row[1]), "%s body_height" % id)
	var elder := UnitType.find("gloomcap_elder")
	_check(elder != null and is_equal_approx(elder.projectile_speed, 14.0), "Gloomcap Elder projectile_speed 14")
	_near(UnitType.new().projectile_speed, 25.0, "UnitType default projectile_speed")
	var biggest := 0.0
	var dir := DirAccess.open("res://data/units/")
	if dir != null:
		for f in dir.get_files():
			if not f.ends_with(".tres"):
				continue
			var ut := load("res://data/units/" + f) as UnitType
			if ut != null:
				# Since the tiers wave (2026-09-27) ranged units may set their own bolt speed (Frost Mortar 18 ...
				# Stormbottle Genie 40): a unit that sets none flies at the default 25, one that sets it stays in a
				# readable 12-45 m/s band.
				var sets_speed := FileAccess.get_file_as_string("res://data/units/" + f).contains("projectile_speed")
				if ut.id == &"gloomcap_elder":
					_near(ut.projectile_speed, 14.0, "%s projectile_speed" % ut.id)
				elif not sets_speed:
					_near(ut.projectile_speed, 25.0, "%s projectile_speed (default)" % ut.id)
				else:
					_check(ut.projectile_speed >= 12.0 and ut.projectile_speed <= 45.0,
							"%s projectile_speed %.1f in 12-45" % [ut.id, ut.projectile_speed])
				biggest = maxf(biggest, ut.radius)
	_check(biggest >= 1.1 - 0.001, "the biggest unit radius is the Grizzlemaw's 1.1 (got %.2f)" % biggest)
	_check(Unit.MAX_UNIT_RADIUS >= biggest - 0.001, "Unit.MAX_UNIT_RADIUS %.2f >= %.2f" % [Unit.MAX_UNIT_RADIUS, biggest])


# ---------------------------------------------------------------- models and variants

func _test_spawn_models() -> void:
	var x := -50.0
	for id: StringName in MODELS:
		var row: Array = MODELS[id]
		var arr := _creature(String(id), Vector3(x, 0.0, -40.0))
		x += 10.0
		var u: Unit = arr[0]
		var m := u.get_model()
		_check(m != null and m.scene_file_path == row[0], "%s builds its model (%s)" % [id, m.scene_file_path if m else "none"])
		_check(u.model_has(&"play_cast"), "%s model has play_cast" % id)
		if int(row[2]) >= 0:
			_eq(_variant_of(u), int(row[2]), "%s model variant (CreatureAbilities)" % id)
	# A B beast whose CreatureAbilities is attached before it enters the tree (the model is built in Unit._ready).
	var u2 := UnitType.find("elder_grizzlemaw").create_unit()
	u2.team = N as Unit.Team
	CreatureAbilities.attach(u2).autocast_enabled = false
	world.add_child(u2)
	u2.global_position = Vector3(40.0, 0.0, 40.0)
	u2.command_stop()
	spawned.append(u2)
	await _wait(2)
	_eq(_variant_of(u2), 1, "elder grizzlemaw attached before the tree: variant 1")
	var gm := u2.get_model()
	_check(gm != null and gm.scale.x > 1.1, "elder grizzlemaw model scaled x1.15")
	await _wait(10)


func _variant_of(u: Unit) -> int:
	var v: Variant = u.model_call(&"get_variant")
	if v == null:
		v = u.model_call(&"variant")
	return -1 if v == null else int(v)


# ---------------------------------------------------------------- hooks

func _test_stag() -> void:
	var S := Vector3(-30.0, 0.0, 0.0)
	var arr := _creature("hollow_stag", S)
	var u: Unit = arr[0]
	var ab: CreatureAbilities = arr[1]
	_victim(Vector3(S.x + 1.8, 0.0, S.z))
	_victim(Vector3(S.x - 1.8, 0.0, S.z))
	await _wait(3)
	var m := u.get_model()
	_skip_opening_delay(ab, &"antler_sweep")
	_eq(ab.cast(&"antler_sweep"), "", "antler sweep cast")
	await _wait(120)
	_check(int(m.call(&"sweep_count")) == 1, "stag model played the antler sweep (%d)" % int(m.call(&"sweep_count")))


func _test_tusker() -> void:
	var T := Vector3(-30.0, 0.0, 20.0)
	var arr := _creature("ironhide_tusker", T)
	var u: Unit = arr[0]
	var ab: CreatureAbilities = arr[1]
	var m := u.get_model()
	var v := _victim(T + Vector3(7.0, 0.0, 7.0))   # 9.9 m away, diagonal (the tusker faces +Z at spawn)
	await _wait(3)
	var c0 := int(m.call(&"charge_count"))
	_skip_opening_delay(ab, &"gore_charge")
	_eq(ab.cast(&"gore_charge", v), "", "gore charge cast")
	await _wait(4)
	var fwd := m.global_transform.basis.z
	var want := (v.global_position - T)
	var ang := rad_to_deg(Vector2(fwd.x, fwd.z).angle_to(Vector2(want.x, want.z)))
	_check(absf(ang) < 15.0, "the charging tusker faces its dash (off by %.1f deg)" % ang)
	_check(bool(m.call(&"is_charging")), "tusker model gallops while dashed")
	await _wait(120)
	_check(int(m.call(&"charge_count")) == c0 + 1, "tusker model played one gore charge")
	# Bristle Hide: a melee attacker's hits spike the bristles.
	var k0 := int(m.call(&"bristle_kicks"))
	var melee := _victim(u.global_position + Vector3(-2.4, 0.0, 0.0), 5.0, 1.6)
	melee.command_attack(u)
	await _wait(200)
	_check(int(m.call(&"bristle_kicks")) >= k0 + 2, "bristle hide reflects spike the bristles (%d -> %d)"
			% [k0, int(m.call(&"bristle_kicks"))])


func _test_roc() -> void:
	var R := Vector3(-30.0, 0.0, -20.0)
	var arr := _creature("stormcrest_roc", R)
	var u: Unit = arr[0]
	var ab: CreatureAbilities = arr[1]
	var m := u.get_model()
	var v := _victim(R + Vector3(8.0, 0.0, 0.0))
	await _wait(3)
	_skip_opening_delay(ab, &"gale_swoop")
	_eq(ab.cast(&"gale_swoop", v), "", "gale swoop cast")
	await _wait(100)
	_check(int(m.call(&"swoop_count")) == 1, "roc model played the gale swoop")
	u.hp = u.max_hp * 0.35
	_eq(ab.cast(&"updraft", R), "", "updraft cast")
	await _wait(80)
	_check(int(m.call(&"updraft_count")) == 1, "roc model played the updraft")
	_check(u.has_status(&"shroud"), "updraft shroud on the unit")
	var arr2 := _creature("duskwing_roc", R + Vector3(0.0, 0.0, -12.0))
	var u2: Unit = arr2[0]
	var ab2: CreatureAbilities = arr2[1]
	var v2 := _victim(u2.global_position + Vector3(8.0, 0.0, 0.0))
	await _wait(3)
	_skip_opening_delay(ab2, &"shrieking_dive")
	_eq(ab2.cast(&"shrieking_dive", v2), "", "shrieking dive cast")
	await _wait(100)
	_check(int(u2.get_model().call(&"swoop_count")) == 1, "duskwing model played the shrieking dive")
	_eq(_variant_of(u2), 1, "duskwing variant")


func _test_direwolf() -> void:
	var D := Vector3(10.0, 0.0, 0.0)
	var arr := _creature("moonpelt_direwolf", D)
	var u: Unit = arr[0]
	var ab: CreatureAbilities = arr[1]
	var m := u.get_model()
	var v := _victim(D + Vector3(7.0, 0.0, 0.0))
	await _wait(3)
	_skip_opening_delay(ab, &"pounce")
	_eq(ab.cast(&"pounce", v), "", "pounce cast")
	await _wait(2)
	var fwd := m.global_transform.basis.z
	_check(fwd.x > 0.9, "the pouncing wolf faces its leap (%s)" % fwd)
	await _wait(100)
	_check(int(m.call(&"pounce_count")) == 1, "direwolf model played the pounce")


func _test_grizzlemaw() -> void:
	var G := Vector3(10.0, 0.0, 25.0)
	var arr := _creature("grizzlemaw", G)
	var u: Unit = arr[0]
	var ab: CreatureAbilities = arr[1]
	var m := u.get_model()
	var v := _victim(G + Vector3(2.5, 0.0, 0.0))
	await _wait(3)
	_skip_opening_delay(ab, &"maul")
	_eq(ab.cast(&"maul", v), "", "maul cast")
	await _wait(90)
	_check(int(m.call(&"maul_count")) == 1, "grizzlemaw model played the maul")
	u.hp = u.max_hp * 0.45
	_skip_opening_delay(ab, &"rending_roar")
	_eq(ab.cast(&"rending_roar"), "", "rending roar cast")
	await _wait(150)
	_check(int(m.call(&"roar_count")) == 1, "grizzlemaw model played the rending roar")
	_check(not bool(m.call(&"is_enraged")), "no enrage look above 30 %")
	u.hp = u.max_hp * 0.31
	u.take_damage(200.0, v)   # below 30 %: enrage (damage_taken)
	await _wait(2)
	_check(ab.is_enraged() and bool(m.call(&"is_enraged")), "enrage modifier and model look at once")
	u.heal(u.max_hp)
	await _wait(40)
	_check(not ab.is_enraged() and not bool(m.call(&"is_enraged")), "enrage look off after a heal")


# ---------------------------------------------------------------- bolt speed, held reach

func _test_bolt_speed() -> void:
	var elder_speed := await _measure_bolt(UnitType.find("gloomcap_elder"), Vector3(-40.0, 0.0, 40.0))
	_check(elder_speed > 11.5 and elder_speed < 15.5, "Elder bolt ~14 m/s (%.1f)" % elder_speed)
	var t := UnitType.new()
	t.id = &"test_archer"
	t.display_name = "Archer"
	t.faction = &"neutral"
	t.max_hp = 500.0
	t.attack_damage = 5.0
	t.attack_range = 7.0
	t.attack_cooldown = 1.0
	t.aggro_range = 8.0
	t.radius = 0.45
	t.body_height = 1.6
	var def_speed := await _measure_bolt(t, Vector3(-40.0, 0.0, 20.0))
	_check(def_speed > 21.0 and def_speed < 27.5, "default bolt ~25 m/s (%.1f)" % def_speed)


## Spawns a neutral shooter of `type` 6 m from a dummy and returns the measured bolt speed (m/s), 0 = none seen.
func _measure_bolt(type: UnitType, at: Vector3) -> float:
	if type == null:
		return 0.0
	var s := type.create_unit()
	s.team = N as Unit.Team
	world.add_child(s)
	s.global_position = at
	s.command_stop()
	spawned.append(s)
	var v := _victim(at + Vector3(6.0, 0.0, 0.0))
	var bolt: Node3D = null
	var seen := false   # a freed bolt may compare equal to null: keep a flag
	var born := 0
	var from := Vector3.ZERO
	for i in 240:
		await _wait(1)
		if not seen:
			for c in world.get_children():
				if c is Projectile and (c as Projectile).source == s:
					bolt = c
					seen = true
					born = Engine.get_physics_frames()
					from = s.global_position + Vector3.UP * s.body_height * 0.75
					break
		elif not is_instance_valid(bolt) or bolt.is_queued_for_deletion():
			var secs := float(Engine.get_physics_frames() - born) / 60.0
			var to := v.global_position + Vector3.UP
			return from.distance_to(to) / maxf(secs, 0.001)
	return 0.0


func _test_held_reach() -> void:
	var G := Vector3(30.0, 0.0, -30.0)
	var arr := _creature("grizzlemaw", G)
	var g: Unit = arr[0]
	# Centre distance 3.0 m: inside reach (1.6 + 0.45 + 1.1 = 3.15) but beyond the old search (1.6 + 0.45 + 0.7).
	var h := _victim(G + Vector3(3.0, 0.0, 0.0), 1.0, 1.6)
	h.command_hold()
	await _wait(30)
	_check(h.attack_target == g, "a held melee unit hits the Grizzlemaw in its reach (target %s)" % h.attack_target)


# ---------------------------------------------------------------- helpers

## The casts here test the model hooks, not the fight rules. A creature that sees its fight start (its first
## _think after spawn, staggered over 0.5 s by instance id, so it may land inside the 3-frame settle wait) puts every
## ability on CreatureAbilities.OPENING_DELAY (1.5 s): cast() then answers "On cooldown" by design. Which run hits it
## depends on the instance ids (more objects since the casters merge), so 1 run in ~4 failed under parallel CI.
## Only that opening delay is skipped here; any longer (real) cooldown still fails the check.
func _skip_opening_delay(ab: CreatureAbilities, id: StringName) -> void:
	var left := ab.cooldown_left(id)
	if left <= 0.0:
		return
	_check(left <= CreatureAbilities.OPENING_DELAY + 0.001,
			"%s: only the fight's opening delay may run before the cast (%.2f s left)" % [id, left])
	ab.reset_cooldowns()


func _creature(id: String, pos: Vector3) -> Array:
	var u := UnitType.find(id).create_unit()
	u.team = N as Unit.Team
	world.add_child(u)
	u.global_position = pos
	u.command_stop()
	spawned.append(u)
	var ab := CreatureAbilities.attach(u)
	ab.autocast_enabled = false
	return [u, ab]


## A PLAYER dummy: 5000 HP; damage 0 = never attacks.
func _victim(pos: Vector3, dmg: float = 0.0, rng: float = 1.6) -> Unit:
	var t := UnitType.new()
	t.id = &"test_dummy"
	t.display_name = "Dummy"
	t.faction = &"fire"
	t.max_hp = 5000.0
	t.move_speed = 5.0
	t.attack_damage = dmg
	t.attack_range = rng
	t.attack_cooldown = 1.0
	t.aggro_range = 0.0
	t.radius = 0.45
	var u := t.create_unit()
	u.team = P as Unit.Team
	world.add_child(u)
	u.global_position = pos
	u.command_stop()
	spawned.append(u)
	return u


func _wait(frames: int) -> void:
	for i in frames:
		await physics_frame


func _clear() -> void:
	for n in spawned:
		if is_instance_valid(n):
			n.queue_free()
	spawned.clear()
	for c in world.get_children():
		if c is Projectile:
			c.queue_free()
	vfx.calls.clear()
	await _wait(3)


func _check(ok: bool, msg: String) -> void:
	checks += 1
	if not ok:
		errors.append(msg)


func _eq(got: Variant, want: Variant, msg: String) -> void:
	checks += 1
	if str(got) != str(want):
		errors.append("%s: got '%s', want '%s'" % [msg, str(got), str(want)])


func _near(got: float, want: float, msg: String, tol: float = 0.05) -> void:
	checks += 1
	if absf(got - want) > tol:
		errors.append("%s: got %.3f, want %.3f" % [msg, got, want])
