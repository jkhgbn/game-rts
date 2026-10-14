extends SceneTree
## Task 11.V4: the Coin-Cutter's class weapons (art/units/champions/coin_cutter/, skills-rework.md 5).
## Run: $GODOT --headless --path . -s tests/test_11_v4.gd --fixed-fps 60 --quit-after 9000
## Checks: the two knives are tagged archetype weapon (merged before a class, gone with each of the 4 classes, back
## with &""); the hood tail, loot sack, coin belt and sash / pennant stay with every class; budgets per class (<= 26
## authored, same draw instances as the archetype and <= 16, 0 lights, <= 5 own materials); grips in the fists;
## attack style per class plays and ends; Cutpurse (lunge, weapon tip above the ground at the strike, a pose of its
## own per weapon), Smoke Pouch (pouch shown) and Marked for Coin (coin flipped; the weapon points at the mark) with
## each weapon; the 12 class skill poses play and end; get_beam_origin per class; the Sword and Shield idle fidget;
## the scale-in; death / revive keep the class. Prints "PASS 11.v4" or "FAIL 11.v4: <reasons>".

const TASK_ID := "11.v4"
const SCENE := "res://art/units/champions/coin_cutter/coin_cutter.tscn"
const OWN_DIR := "res://art/units/champions/coin_cutter/"
const CLASSES: Array[StringName] = [&"spear", &"sword_shield", &"two_hand", &"wizard"]
const STYLE: Dictionary = {&"spear": &"spear_thrust", &"sword_shield": &"sword_slash", &"two_hand": &"great_cleave",
	&"wizard": &"staff_bolt"}
const SKILLS: Dictionary = {
	&"spear": [&"lunge", &"hobbling_javelin", &"skewer"],
	&"sword_shield": [&"riposte", &"second_wind", &"shield_throw"],
	&"two_hand": [&"cleave", &"crushing_blow", &"whirlwind"],
	&"wizard": [&"arc_bolt", &"slipstep", &"starfall"],
}
const HAND_R := Vector3(0.32, 0.93, 0.09)
const HAND_L := Vector3(-0.38, 0.99, 0.12)

var _fails: PackedStringArray = PackedStringArray()
var _world: Node3D


func _initialize() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	# A close camera keeps the models at LOD tier 0 (fidgets only play there): without one, the 0.5 s tier timer
	# drops them to tier 1 and the idle-fidget check depended on that timer's phase.
	var cam := Camera3D.new()
	cam.position = Vector3(0.0, 2.0, 6.0)
	_world.add_child(cam)
	cam.current = true
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAILED: ", what)


func _wait(sec: float) -> void:
	for i: int in int(ceil(sec * 60.0)):
		await process_frame


func _until(m: Node, t: float) -> void:
	for i: int in 200:
		if float(m.get(&"_action_t")) >= t:
			return
		await process_frame


func _spawn(at: Vector3) -> Node3D:
	var holder := Node3D.new()
	holder.position = at
	_world.add_child(holder)
	var m: Node3D = (load(SCENE) as PackedScene).instantiate()
	holder.add_child(m)
	m.set(&"_idle_left", 1.0e9)
	return m


func _run() -> void:
	# ---- authored meshes (parts built outside the tree, no merge): the knives are 2 more parts
	var probe: Node3D = (load(SCENE) as PackedScene).instantiate()
	probe.call(&"_build_parts")
	var authored := 0
	var knives := 0
	for n: Node in probe.find_children("*", "", true, false):
		if n is MeshInstance3D or n is MultiMeshInstance3D:
			authored += 1
			if n.has_meta(&"weapon_classes") and PackedStringArray(n.get_meta(&"weapon_classes")) == PackedStringArray([""]):
				knives += 1
	probe.free()
	print("authored meshes: %d, tagged archetype weapon parts: %d" % [authored, knives])
	_check(authored <= 26, "authored meshes %d <= 26" % authored)
	_check(knives == 2, "two knife parts tagged archetype weapon (got %d)" % knives)

	var m := _spawn(Vector3.ZERO)
	await _wait(0.1)
	var base_inst := _draw_instances(m)
	_check(_pivot_has(m, "Root/Chest/ArmR", "coin_cutter_brass") and _pivot_has(m, "Root/Chest/ArmL", "coin_cutter_brass"),
		"archetype: both knives merged in the arms")
	_check(float(m.call(&"weapon_slot_xf", &"hand_r").origin.distance_to(HAND_R)) < 0.001, "hand_r grip = the right fist")
	_check(float(m.call(&"weapon_slot_xf", &"hand_l").origin.distance_to(HAND_L)) < 0.001, "hand_l grip = the left fist")
	var bo: Vector3 = m.call(&"get_beam_origin")
	_check(m.to_local(bo).distance_to(Vector3(0, 1.7 * 0.85, 0.45)) < 0.01, "archetype beam origin in front of the chest")

	for cls: StringName in CLASSES:
		m.call(&"set_weapon_class", cls, false)
		await _wait(0.1)
		await _check_class(m, cls, base_inst)

	# ---- back to the knives
	m.call(&"set_weapon_class", &"")
	await _wait(0.1)
	_check(_pivot_has(m, "Root/Chest/ArmR", "coin_cutter_brass") and _pivot_has(m, "Root/Chest/ArmL", "coin_cutter_brass")
		and not _pivot_has(m, "Root/Chest/ArmR", "weapon_"), "&\"\" gives the knives back")
	_check(m.get(&"attack_style") == &"slash2", "&\"\" restores slash2")

	# ---- scale-in when the class is drawn
	m.call(&"set_weapon_class", &"two_hand")
	await process_frame
	_check(m.find_children("WeaponPop", "", true, false).size() == 1, "scale-in: the greatsword pops in")
	_check(not _pivot_has(m, "Root/Chest/ArmR", "coin_cutter_brass"), "scale-in: the knife is gone at once")
	await _wait(0.45)
	_check(m.find_children("WeaponPop", "", true, false).is_empty() and _pivot_has(m, "Root/Chest/ArmR", "weapon_steel"),
		"scale-in over, greatsword merged")

	# ---- death / revive keep the class, knives stay hidden
	var got: Array = [false]
	m.connect(&"death_finished", func() -> void: got[0] = true, CONNECT_ONE_SHOT)
	m.call(&"play_death")
	await _wait(1.4)
	_check(got[0], "death_finished with the greatsword")
	m.call(&"revive")
	await _wait(0.2)
	_check(m.call(&"weapon_class") == &"two_hand" and _pivot_has(m, "Root/Chest/ArmR", "weapon_steel")
		and not _pivot_has(m, "Root/Chest/ArmR", "coin_cutter_brass"), "revive keeps the greatsword, no knife")

	# ---- the Sword and Shield idle fidget weighs the sack (no coin flip in front of the shield)
	m.call(&"set_weapon_class", &"sword_shield", false)
	m.set(&"_tier", 0)
	m.set(&"_idle_i", 0)   # IDLE_IDS[0] = idle_flip
	m.set(&"_idle_left", 0.0)
	await _wait(0.1)
	_check(m.get(&"_cast_id") == &"idle_weigh", "sword_shield idle fidget = idle_weigh (got %s)" % m.get(&"_cast_id"))

	# ---- a class set before _ready (save restore) appears without the pop, knives already hidden
	var early: Node3D = (load(SCENE) as PackedScene).instantiate()
	early.call(&"set_weapon_class", &"spear")
	var h := Node3D.new()
	h.position = Vector3(0, 0, 5)
	_world.add_child(h)
	h.add_child(early)
	await _wait(0.1)
	_check(early.call(&"weapon_class") == &"spear" and early.find_children("WeaponPop", "", true, false).is_empty()
		and not _pivot_has(early, "Root/Chest/ArmR", "coin_cutter_brass"), "class before _ready: spear, no pop, no knife")

	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


func _check_class(m: Node3D, cls: StringName, base_inst: int) -> void:
	# knives gone, identity props kept
	_check(not _pivot_has(m, "Root/Chest/ArmR", "coin_cutter_brass") and not _pivot_has(m, "Root/Chest/ArmL", "coin_cutter_brass"),
		"%s: both knives hidden" % cls)
	_check(_pivot_has(m, "Root/Chest/ArmR", "coin_cutter_charcoal") and _pivot_has(m, "Root/Chest/ArmL", "coin_cutter_charcoal"),
		"%s: the arms stay" % cls)
	for p: String in ["Root/Hips/LootSack", "Root/Chest/Head/HoodTail"]:
		var n := m.get_node_or_null(p) as Node3D
		_check(n != null and n.is_visible_in_tree(), "%s: %s kept" % [cls, p.get_file()])
	_check(_pivot_has(m, "Root/Hips", "coin_cutter_gold_glow"), "%s: coin belt kept" % cls)
	_check(_pivot_has(m, "Root/Chest", "coin_cutter_pennon"), "%s: sash / pennant kept" % cls)
	_check(_pivot_has(m, "Root/Chest/Head", "coin_cutter_charcoal"), "%s: hood kept" % cls)
	# budgets
	var inst := _draw_instances(m)
	_check(inst == base_inst and inst <= 16, "%s: draw instances %d (archetype %d)" % [cls, inst, base_inst])
	_check(m.find_children("*", "Light3D", true, false).is_empty(), "%s: 0 lights" % cls)
	var own := 0
	for mat: Material in _materials(m):
		if mat.resource_path.begins_with(OWN_DIR):
			own += 1
	_check(own <= 5, "%s: <= 5 own materials (got %d)" % [cls, own])
	print("%-12s draw instances %d, vertices %d, own materials %d" % [cls, inst, _vertices(m), own])
	# grip: the main piece sits in the right fist
	var main: StringName = (m.call(&"weapon_pieces") as Array)[0]
	var g: Transform3D = m.call(&"weapon_grip_xf", main)
	_check(g.origin.distance_to(HAND_R) < 0.05, "%s: %s held in the right fist (%s)" % [cls, main, g.origin])
	# beam origin
	var bo: Vector3 = m.call(&"get_beam_origin")
	match cls:
		&"wizard":
			_check(bo.distance_to(m.call(&"get_weapon_tip")) < 0.001, "wizard: beam origin = the staff crystal")
		&"spear", &"sword_shield":
			_check(m.to_local(bo).distance_to(HAND_L) < 0.05, "%s: beam origin = the left fist" % cls)
		_:
			_check(m.to_local(bo).distance_to(Vector3(0, 1.7 * 0.85, 0.45)) < 0.01, "%s: beam origin in front of the chest" % cls)

	# attack style
	_check(m.get(&"attack_style") == STYLE[cls], "%s: attack_style %s" % [cls, STYLE[cls]])
	m.call(&"play_attack")
	await _wait(0.13)
	_check(m.get(&"_action") == &"attack", "%s: attacking" % cls)
	await _wait(0.9)
	_check(m.get(&"_action") == &"", "%s: attack finished" % cls)

	# Cutpurse: a lunge with this weapon, its own arm pose, the tip off the ground at the strike
	m.call(&"play_cast", &"cutpurse")
	await _until(m, 0.26)
	var root_z: float = (m.get_node("Root") as Node3D).position.z
	var arm_r: Node3D = m.get_node("Root/Chest/ArmR")
	var tip: Vector3 = m.to_local(m.call(&"get_weapon_tip"))
	print("  cutpurse %-12s root z %.2f, ArmR rot %s, tip %s" % [cls, root_z, arm_r.rotation, tip])
	_check(root_z > 0.3, "%s cutpurse lunges (root z %.2f)" % [cls, root_z])
	_check(absf(arm_r.rotation.x - (-86.0 * PI / 180.0)) > 0.3, "%s cutpurse: a weapon pose, not the knife stab" % cls)
	_check(tip.y > 0.35, "%s cutpurse: the weapon tip stays off the ground (%.2f)" % [cls, tip.y])
	if cls == &"spear" or cls == &"sword_shield" or cls == &"wizard":
		_check(tip.z > root_z + 0.7, "%s cutpurse: the weapon points forward (tip z %.2f)" % [cls, tip.z])
	if cls == &"wizard":
		_check(float(m.get(&"_wk_flare")) > 0.3, "wizard cutpurse: the crystal flares")
	_check(_pivot_has(m, "Root/Chest/ArmR", "weapon_"), "%s cutpurse: the weapon stays in hand" % cls)
	await _wait(0.6)
	_check(m.get(&"_action") == &"", "%s cutpurse ends" % cls)

	# Smoke Pouch: the pouch is thrown by the left hand, the weapon guards
	var pouch := m.get_node("Root/Chest/ArmL/Pouch") as Node3D
	m.call(&"play_cast", &"smoke_pouch")
	var saw := false
	var guard_rx := 0.0
	for i: int in 60:
		await process_frame
		saw = saw or pouch.visible
		if float(m.get(&"_action_t")) > 0.35 and float(m.get(&"_action_t")) < 0.40:
			guard_rx = arm_r.rotation.x
		if m.get(&"_action") == &"":
			break
	_check(saw, "%s smoke_pouch shows the pouch" % cls)
	_check(m.get(&"_action") == &"" and not pouch.visible, "%s smoke_pouch ends, pouch hidden" % cls)
	if cls != &"sword_shield":
		_check(absf(guard_rx - (-115.0 * PI / 180.0)) > 0.4, "%s smoke_pouch: own weapon guard (%.2f rad)" % [cls, guard_rx])

	# Marked for Coin: the coin flips, then the weapon points at the mark
	var coin := m.get_node("Fx/FlipCoin") as Node3D
	m.call(&"play_cast", &"marked_for_coin")
	var top := -99.0
	var point_tip := Vector3.ZERO
	for i: int in 90:
		await process_frame
		if coin.visible:
			top = maxf(top, coin.position.y)
		var t: float = m.get(&"_action_t")
		if t > 0.82 and t < 0.88:
			point_tip = m.to_local(m.call(&"get_weapon_tip"))
		if m.get(&"_action") == &"":
			break
	_check(top > 1.6, "%s marked_for_coin flips the coin (top %.2f)" % [cls, top])
	_check(m.get(&"_action") == &"" and not coin.visible, "%s marked_for_coin ends, coin hidden" % cls)
	if cls == &"spear" or cls == &"sword_shield":
		_check(point_tip.z > 0.8, "%s marked_for_coin points the weapon at the mark (tip %s)" % [cls, point_tip])

	# the 3 class skills (kit poses) play and end with the Coin-Cutter
	for id: StringName in SKILLS[cls]:
		m.call(&"play_cast", id)
		await _wait(0.15)
		_check(m.get(&"_action") == &"cast" and m.get(&"_cast_id") == id, "%s: casting %s" % [cls, id])
		var length: float = {&"riposte": 4.0, &"whirlwind": 2.0, &"second_wind": 1.4, &"starfall": 1.2}.get(id, 1.1)
		await _wait(length)
		_check(m.get(&"_action") == &"", "%s: %s ends" % [cls, id])
		_check(not _pivot_has(m, "Root/Chest/ArmR", "coin_cutter_brass"), "%s: no knife after %s" % [cls, id])


# ---------------------------------------------------------------- helpers

func _pivot_has(m: Node3D, pivot: String, mat_part: String) -> bool:
	var node := m.get_node_or_null(pivot + "/Merged") as MeshInstance3D
	if node == null or node.mesh == null:
		return false
	# palette-aware (ChampionPalette B8 merge, 2026-09-30): folded parts are found per vertex by their source material
	return ChampionPalette.mesh_has(node.mesh, mat_part)


func _draw_instances(n: Node) -> int:
	var c := 0
	for g: Node in n.find_children("*", "GeometryInstance3D", true, false):
		if g is MeshInstance3D and (g as MeshInstance3D).mesh == null:
			continue
		c += 1
	return c


func _vertices(n: Node) -> int:
	var c := 0
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mesh := (g as MeshInstance3D).mesh
		if mesh:
			for s: int in mesh.get_surface_count():
				c += (mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return c


func _materials(n: Node) -> Array:
	var out: Array = []
	for g: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null or mi.name == "Shadow":
			continue
		if mi.material_override:
			if not (mi.material_override in out):
				out.append(mi.material_override)
			continue
		for s: int in mi.mesh.get_surface_count():
			var mat := mi.get_surface_override_material(s)
			if mat == null:
				mat = mi.mesh.surface_get_material(s)
			if mat and not (mat in out):
				out.append(mat)
	return out
