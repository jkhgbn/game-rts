extends SceneTree
## Task 9.C10: the 4 champion models are plugged (ChampionType.model_scene), with the right variant and the
## owner's kingdom colour; Unit / Champion drive the model hooks (moving, attack windup, bolt from
## get_beam_origin(), hit, death, revive, level-up); every ability plays play_cast(id) on the model and
## ChampionVfx.play(id, caster, target_or_point) (Cutpurse when the empowered hit lands, Mending Draught on the
## healed unit, Soothing Circle at the centre point, Flare Arrow at the point); champions have a gold-framed
## world HP bar and never veterancy chevrons.
## Run:  godot --headless --path . -s tests/test_9_c10.gd --fixed-fps 60 --quit-after 4000
## A small world (no UI, no main scene). Reads a few model internals (_cast_id, _dead, _level_t...) to see
## that the hooks ran: the models have no public "last hook" API.

const TASK_ID := "9.C10"
const P := 0   # Unit.Team.PLAYER
const E := 1   # Unit.Team.ENEMY
const IDS: Array[StringName] = [&"wayfinder", &"oathwall", &"coin_cutter", &"mender"]
const GOLD := Color(1.0, 0.82, 0.3)
const WIZARD_SRC := "extends Node3D\nvar team := 0\nvar kingdom: StringName = &\"fire\"\n"
## Records every play() and forwards it to the real ChampionVfx (it is first in the group: tree order).
const SPY_SRC := "extends Node3D\nvar real: Node = null\nvar calls: Array = []\n" \
		+ "func play(id: StringName, caster: Node3D, target: Variant) -> void:\n" \
		+ "\tcalls.append([id, caster, target])\n\tif real:\n\t\treal.call(&\"play\", id, caster, target)\n"

var world: Node3D
var vfx: Node3D        # the real ChampionVfx
var spy: Node3D
var errors: Array[String] = []
var finished := false
var spawned: Array = []
var seen_bolts: Dictionary = {}
var stages := 0


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
	spy = Node3D.new()
	spy.name = "VfxSpy"
	spy.set_script(_script(SPY_SRC))
	spy.add_to_group(&"champion_vfx")
	world.add_child(spy)
	vfx = ChampionVfx.new()
	vfx.name = "ChampionVfx"
	world.add_child(vfx)
	spy.set(&"real", vfx)
	# The owners' wizards: the player's is Ice, the enemy's Nature (neither is the models' authored Fire).
	for pair: Array in [[P, &"ice"], [E, &"nature"]]:
		var w := Node3D.new()
		w.set_script(_script(WIZARD_SRC))
		w.set(&"team", pair[0])
		w.set(&"kingdom", pair[1])
		w.add_to_group(&"heroes")
		world.add_child(w)
	_run()


func _process(_delta: float) -> bool:
	return finished


func _run() -> void:
	await _wait(3)
	_check(spy == get_first_node_in_group_safe(), "the spy is the first champion_vfx node")
	await _test_types_and_models()
	await _clear()
	await _test_wayfinder()
	await _clear()
	await _test_oathwall()
	await _clear()
	await _test_coin_cutter()
	await _clear()
	await _test_mender()
	await _clear()
	await _test_hooks_and_bar()
	await _clear()
	# A script error aborts a stage silently: every stage counts itself at its very end.
	_eq(stages, 6, "every stage ran to its end")
	if errors.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, " | ".join(errors)])
	finished = true


func get_first_node_in_group_safe() -> Node:
	return world.get_tree().get_first_node_in_group(&"champion_vfx")


# ---------------------------------------------------------------- data + models

func _test_types_and_models() -> void:
	var at := Vector3(-30.0, 0.0, -30.0)
	var i := 0
	for id in IDS:
		var t := ChampionType.find(id)
		_check(t != null, "%s.tres loads" % id)
		if t == null:
			continue
		var path := "res://art/units/champions/%s/%s.tscn" % [id, id]
		_check(t.model_scene != null and t.model_scene.resource_path == path,
				"%s model_scene = %s" % [id, path])
		for variant in [0, 1]:
			var team := P if (i + variant) % 2 == 0 else E
			var ch := _champ(id, variant, team, at + Vector3(4.0 * i, 0.0, 6.0 * variant))
			await _wait(2)
			var m := ch.get_model()
			var tag := "%s v%d" % [id, variant]
			_check(ch.has_model() and m is CharacterModel, "%s: a CharacterModel replaces the placeholder" % tag)
			if m == null:
				continue
			_check((m.get_script() as Script).resource_path == "res://art/units/champions/%s/%s.gd" % [id, id],
					"%s: model script is the champion's" % tag)
			var mv: Variant = m.call(&"get_variant") if m.has_method(&"get_variant") else m.get(&"variant")
			_check(mv != null and int(mv) == variant, "%s: model variant %d (got %s)" % [tag, variant, str(mv)])
			var kc: Color = Unit.KINGDOM_COLORS[&"ice" if team == P else &"nature"]
			_check(ch.call(&"owner_kingdom") == (&"ice" if team == P else &"nature"), "%s: owner kingdom" % tag)
			_check(_has_team_color(m, kc), "%s: sash / pennant recoloured to the owner's kingdom colour" % tag)
			_check(not _has_placeholder_props(ch), "%s: no placeholder props with a model" % tag)
			var wind := float(ch.get(&"_model_windup"))
			var want := 0.15 if id == &"wayfinder" else (0.14 if id == &"mender" else 0.0)
			_near(wind, want, "%s: attack windup read from the model" % tag)
			_check(absf(float(m.get(&"stride_speed")) - t.move_speed) < 0.01, "%s: stride_speed = base move speed" % tag)
		i += 1
	stages += 1


# ---------------------------------------------------------------- abilities per champion

func _test_wayfinder() -> void:
	var at := Vector3(-30.0, 0.0, 20.0)
	var ch := _champ(&"wayfinder", 1, P, at)
	var foe := _unit(E, at + Vector3(5.0, 0.0, 0.0), 2000.0)
	await _wait(3)
	var ab := _abilities(ch)
	ch.add_xp(940)   # level 4: all three abilities (step 11 XP table)
	ch.set_champion_class(&"")   # step 11: keep the archetype weapon (the 9.C10 bow) after the level-2 draw
	var point := at + Vector3(0.0, 0.0, 15.0)
	await _cast_and_check(ch, ab, &"flare_arrow", point, point)
	await _cast_and_check(ch, ab, &"snare_line", foe, foe)
	await _cast_and_check(ch, ab, &"trailblaze", null, ch)
	# Ranged auto-attack: the arrow leaves after the 0.15 s windup, in the 4.1 colour.
	var bolt := await _next_bolt(ch, foe)
	_check(bolt != null, "Wayfinder shoots an arrow at a foe")
	if bolt:
		_check((bolt.get(&"color") as Color).is_equal_approx(Color(1.0, 0.8, 0.4)), "Wayfinder arrow colour (1.0, 0.8, 0.4)")
	stages += 1


func _test_oathwall() -> void:
	var at := Vector3(0.0, 0.0, 20.0)
	var ch := _champ(&"oathwall", 0, E, at)
	var foe := _unit(P, at + Vector3(1.5, 0.0, 0.0), 2000.0)
	await _wait(3)
	var ab := _abilities(ch)
	ch.add_xp(940)   # level 4 (step 11 XP table)
	await _cast_and_check(ch, ab, &"oath_of_iron", null, ch)
	await _cast_and_check(ch, ab, &"shield_bash", foe, foe)
	await _cast_and_check(ch, ab, &"bulwark_stand", null, ch)
	stages += 1


func _test_coin_cutter() -> void:
	var at := Vector3(30.0, 0.0, 20.0)
	var ch := _champ(&"coin_cutter", 0, P, at)
	var foe := _unit(E, at + Vector3(1.4, 0.0, 0.0), 2000.0)
	await _wait(3)
	var ab := _abilities(ch)
	ch.add_xp(940)   # level 4 (step 11 XP table)
	ch.set_champion_class(&"")   # step 11: archetype weapon, not the drawn class
	await _wait(2)
	# Cutpurse: arming shows nothing; the stab + coins come with the empowered hit.
	var m := ch.get_model()
	m.set(&"_cast_id", &"")
	var calls: Array = spy.get(&"calls")
	calls.clear()
	var hp0 := foe.hp
	_eq(ab.cast(&"cutpurse", foe), "", "Cutpurse arms")
	_check(not _spy_has(&"cutpurse"), "Cutpurse VFX not played when it arms")
	_check(m.get(&"_cast_id") != &"cutpurse", "Cutpurse stab not played when it arms")
	ch.command_attack(foe)
	var landed := false
	for f in 150:
		await _wait(1)
		if not ab.is_cutpurse_armed():
			landed = true
			break
	_check(landed, "the empowered hit lands")
	_check(foe.hp <= hp0 - 25.0 * 1.24, "the hit carried the Cutpurse bonus (%.1f -> %.1f)" % [hp0, foe.hp])
	var ok := false
	for c: Array in spy.get(&"calls"):
		if c[0] == &"cutpurse" and c[1] == ch and c[2] == foe:
			ok = true
	_check(ok, "ChampionVfx.play(cutpurse, champion, the hit unit) when the hit lands")
	_check(m.get(&"_cast_id") == &"cutpurse", "model play_cast(cutpurse) on the empowered hit")
	_check(_vfx_active(&"cutpurse"), "ChampionVfx runs the cutpurse effect")
	ch.command_stop()
	await _wait(2)
	await _cast_and_check(ch, ab, &"smoke_pouch", null, ch)
	await _cast_and_check(ch, ab, &"marked_for_coin", foe, foe)
	stages += 1


func _test_mender() -> void:
	var at := Vector3(30.0, 0.0, -20.0)
	var ch := _champ(&"mender", 1, E, at)
	var ally := _unit(E, at + Vector3(3.0, 0.0, 0.0), 200.0)
	var foe := _unit(P, at + Vector3(0.0, 0.0, 5.0), 2000.0)
	await _wait(3)
	var ab := _abilities(ch)
	ch.add_xp(940)   # level 4 (step 11 XP table)
	ch.set_champion_class(&"")   # step 11: archetype weapon, not the drawn class
	ally.hp = 60.0
	await _cast_and_check(ch, ab, &"mending_draught", null, ally)   # null = the most hurt ally: VFX on it
	var centre := at + Vector3(2.0, 0.0, 2.0)
	await _cast_and_check(ch, ab, &"soothing_circle", centre, centre)
	await _cast_and_check(ch, ab, &"lifeline", ally, ally)
	# Ranged jab: the bolt starts at the censer (get_beam_origin), in the 4.1 colour.
	var bolt := await _next_bolt(ch, foe)
	_check(bolt != null, "Mender shoots a bolt at a foe")
	if bolt:
		_check((bolt.get(&"color") as Color).is_equal_approx(Color(0.5, 1.0, 0.6)), "Mender bolt colour (0.5, 1.0, 0.6)")
		var start: Vector3 = bolt.get(&"_start")
		var origin: Vector3 = ch.get_model().call(&"get_beam_origin")
		_check(start.distance_to(origin) < 0.35, "Mender bolt starts at get_beam_origin() (%s vs %s)" % [start, origin])
		var default_origin := ch.global_position + Vector3.UP * ch.body_height * 0.75
		_check(start.distance_to(default_origin) > 0.05, "not the default origin")
	stages += 1


# ---------------------------------------------------------------- hooks, HP bar, chevrons

func _test_hooks_and_bar() -> void:
	var at := Vector3(-30.0, 0.0, -10.0)
	var ch := _champ(&"oathwall", 1, P, at)
	var soldier := _unit(P, at + Vector3(0.0, 0.0, 6.0), 100.0)
	var foe := _unit(E, at + Vector3(40.0, 0.0, 0.0), 100.0)
	await _wait(3)
	var m := ch.get_model()
	# Gold HP bar, shown at full HP; soldiers keep the thin black frame and hide at full HP.
	_check(ch.has_gold_hp_frame(), "Champion.has_gold_hp_frame()")
	_check(ch.hp_bar_frame_color().is_equal_approx(GOLD), "champion HP bar frame colour is gold")
	_check(soldier.hp_bar_frame_color().is_equal_approx(Color.BLACK), "soldier HP bar frame stays black")
	var bar := ch.get_node_or_null(^"HPBar") as MeshInstance3D
	_check(bar != null and bar.visible, "champion HP bar visible at full HP")
	if bar:
		var mat := bar.material_override as ShaderMaterial
		var fc: Variant = mat.get_shader_parameter(&"frame_color")
		_check(fc is Color and (fc as Color).is_equal_approx(GOLD), "HP bar shader frame_color = gold (%s)" % str(fc))
		var fs: Variant = mat.get_shader_parameter(&"frame_size")
		_check(fs is Vector2 and (fs as Vector2).x > 0.0 and (fs as Vector2).y > 0.0, "HP bar frame has a width")
		_near((bar.mesh as QuadMesh).size.y, 0.2, "champion HP bar 0.2 m tall")
	var sbar := soldier.get_node_or_null(^"HPBar") as MeshInstance3D
	_check(sbar != null and not sbar.visible, "soldier HP bar hidden at full HP")
	# Chevrons: never, even at level 6.
	ch.add_xp(5000)
	await _wait(2)
	_eq(ch.level, 6, "champion at level 6")
	var chev := ch.get_node_or_null(^"Chevrons") as Label3D
	_check(chev == null or not chev.visible, "no veterancy chevrons on a champion")
	_near(float(m.get(&"_vet_boost")), 1.0, "model never got set_veterancy")
	_check(float(m.get(&"_level_t")) < 1.0, "level-up played play_level_up on the model")
	# Moving.
	ch.command_move(at + Vector3(0.0, 0.0, -12.0))
	var moved := false
	for f in 60:
		await _wait(1)
		if float(m.get(&"_speed")) >= 0.3:
			moved = true
			break
	_check(moved, "set_moving(speed) reaches the model while walking")
	ch.command_stop()
	await _wait(30)
	# Hit.
	m.set(&"_hit_t", 99.0)
	ch.take_damage(10.0, foe)
	_check(float(m.get(&"_hit_t")) < 0.5, "play_hit on damage")
	# Death, then revive.
	ch.take_damage(100000.0, foe)
	_check(not ch.is_alive(), "champion dies")
	_check(bool(m.get(&"_dead")), "play_death on the model")
	_check(bar == null or not bar.visible, "HP bar hidden while fallen")
	for f in 180:
		await _wait(1)
		if not ch.visible:
			break
	_check(not ch.visible and is_instance_valid(ch), "fallen champion hidden, still in the tree")
	ch.respawn(at)
	await _wait(2)
	_check(ch.is_alive() and ch.visible, "champion revived")
	_check(not bool(m.get(&"_dead")), "model revive() ran")
	_check(bar != null and bar.visible, "HP bar back after the revive")
	_check(ch.get_model() == m, "same model instance after the revive")
	stages += 1


# ---------------------------------------------------------------- helpers

# Casts `id` at `target`, then checks the model's play_cast(id), the spy's play(id, champion, fx_target) and
# that the real ChampionVfx runs it.
func _cast_and_check(ch: Champion, ab: ChampionAbilities, id: StringName, target: Variant, fx_target: Variant) -> void:
	var m := ch.get_model()
	if m:
		m.set(&"_cast_id", &"")
	(spy.get(&"calls") as Array).clear()
	ab.reset_cooldowns()
	var r := ab.cast(id, target)
	_eq(r, "", "%s cast" % id)
	if r != "":
		return
	_check(m != null and m.get(&"_cast_id") == id, "%s: model play_cast(%s) (got %s)" % [id, id, str(m.get(&"_cast_id")) if m else "no model"])
	var ok := false
	var got := []
	for c: Array in spy.get(&"calls"):
		got.append([c[0], c[2]])
		if c[0] != id or c[1] != ch:
			continue
		if fx_target is Vector3:
			ok = c[2] is Vector3 and (c[2] as Vector3).distance_to(fx_target) < 0.01
		else:
			ok = typeof(c[2]) == TYPE_OBJECT and c[2] == fx_target
	_check(ok, "%s: ChampionVfx.play(%s, champion, %s) (got %s)" % [id, id, str(fx_target), str(got)])
	await _wait(1)
	_check(_vfx_active(id), "%s: the real ChampionVfx runs the effect (%s)" % [id, str(vfx.call(&"active_ids"))])


func _vfx_active(id: StringName) -> bool:
	var ids: Array = vfx.call(&"active_ids")
	return ids.has(id)


func _spy_has(id: StringName) -> bool:
	for c: Array in spy.get(&"calls"):
		if c[0] == id:
			return true
	return false


# Lets the champion attack `foe` and returns the first Projectile it fires (its _start read on its first frame).
func _next_bolt(ch: Champion, foe: Unit) -> Node:
	for n in world.get_children():
		if n is Projectile:
			seen_bolts[n.get_instance_id()] = true
	ch.command_attack(foe)
	for f in 180:
		await _wait(1)
		for n in world.get_children():
			if n is Projectile and not seen_bolts.has(n.get_instance_id()) and n.get(&"source") == ch:
				seen_bolts[n.get_instance_id()] = true
				ch.command_stop()
				return n
	ch.command_stop()
	return null


func _champ(id: StringName, variant: int, team: int, pos: Vector3) -> Champion:
	var ch := ChampionType.find(id).create_champion(variant)
	ch.team = team
	world.add_child(ch)
	ch.global_position = pos
	ch.command_stop()
	spawned.append(ch)
	var brain := ch.get_node_or_null(^"Brain")
	if brain:
		brain.process_mode = Node.PROCESS_MODE_DISABLED   # the test drives the champion
	var ab := ch.get_node_or_null(^"ChampionAbilities")
	if ab:
		ab.set(&"autocast_enabled", false)
	return ch


func _abilities(ch: Champion) -> ChampionAbilities:
	return ch.get_node_or_null(^"ChampionAbilities") as ChampionAbilities


func _unit(team: int, pos: Vector3, hp: float) -> Unit:
	var u := Unit.new()
	u.team = team
	u.max_hp = hp
	u.attack_damage = 0.0
	u.aggro_range = 0.0
	world.add_child(u)
	u.global_position = pos
	u.command_stop()
	spawned.append(u)
	return u


# A ShaderMaterial on the model whose cloth_color / base_color is `c` (the kit's cached team recolour).
func _has_team_color(n: Node, c: Color) -> bool:
	for child in n.get_children():
		if child is GeometryInstance3D:
			var mats: Array = []
			var gi := child as GeometryInstance3D
			if gi.material_override:
				mats.append(gi.material_override)
			if gi is MeshInstance3D and (gi as MeshInstance3D).mesh:
				var mi := gi as MeshInstance3D
				for s in mi.mesh.get_surface_count():
					mats.append(mi.get_surface_override_material(s))
			for mat: Variant in mats:
				if mat is ShaderMaterial:
					for p: StringName in [&"cloth_color", &"base_color"]:
						var v: Variant = (mat as ShaderMaterial).get_shader_parameter(p)
						if v is Color and absf((v as Color).r - c.r) + absf((v as Color).g - c.g) \
								+ absf((v as Color).b - c.b) < 0.02:
							return true
		if _has_team_color(child, c):
			return true
	return false


# The placeholder props are plain MeshInstance3D children of the Unit's _visual node with a StandardMaterial3D.
func _has_placeholder_props(ch: Champion) -> bool:
	var m := ch.get_model()
	if m == null:
		return true
	var visual := m.get_parent()
	for child in visual.get_children():
		if child != m and child is MeshInstance3D:
			return true
	return false


func _wait(frames: int) -> void:
	for i in frames:
		await physics_frame


func _clear() -> void:
	for n in spawned:
		if is_instance_valid(n):
			n.queue_free()
	spawned.clear()
	for n in world.get_children():
		if n is Projectile or n is SpellHot or n.is_in_group(&"fog_sources") and not n is Champion:
			n.queue_free()
	(spy.get(&"calls") as Array).clear()
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


func _near(got: float, want: float, msg: String) -> void:
	_check(absf(got - want) < 0.01, "%s (got %.3f, want %.3f)" % [msg, got, want])
