extends SceneTree
## Task 11.V3: the Oathwall's class weapons (skills-rework.md 5, oathwall.gd header).
## Run: $GODOT --headless --path . -s tests/test_11_v3.gd --fixed-fps 60 --quit-after 6000
## Checks, per class (archetype, spear, sword_shield, two_hand, wizard): the hammer only with the archetype; the door
## shield in ArmL (DoorShield) for "" / spear / sword_shield, on the back (DoorBack + strap + left gauntlet) for two_hand /
## wizard; Sword and Shield holds the kit sword and NO round shield; budgets (<= 26 authored, <= 16 draw instances,
## 0 lights, <= 5 own materials); grips (hand_r = the gauntlet, hand_l = the left fist); the slam dust only with the
## hammer; Oath of Iron raises every class weapon above the helm; Shield Bash / Bulwark Stand take the door off the back
## into the left hand and put it back; Bulwark plants the door in front for every class; the Hobbling Javelin stands
## the door on the ground; Shield Throw flings the door (shrunk away in flight, caught back, restored when an attack
## interrupts); Lunge / Skewer / Riposte keep the door in front; every class skill of the class plays and ends;
## get_beam_origin always a Vector3 (the Wizard's staff crystal, else in front of him); death / revive keep the door where it belongs.
## Prints "PASS 11.v3" or "FAIL 11.v3: <reasons>".

const TASK_ID := "11.v3"
const SCENE := "res://art/units/champions/oathwall/oathwall.tscn"
const OWN_DIR := "res://art/units/champions/oathwall/materials/"
const CLASSES: Array[StringName] = [&"", &"spear", &"sword_shield", &"two_hand", &"wizard"]
const SKILLS: Dictionary = {
	&"spear": [&"lunge", &"hobbling_javelin", &"skewer"],
	&"sword_shield": [&"riposte", &"second_wind", &"shield_throw"],
	&"two_hand": [&"cleave", &"crushing_blow", &"whirlwind"],
	&"wizard": [&"arc_bolt", &"slipstep", &"starfall"],
}
const SKILL_LEN: Dictionary = {&"riposte": 4.0, &"whirlwind": 2.0, &"second_wind": 1.4, &"starfall": 1.2}

var _fails: PackedStringArray = PackedStringArray()
var _m: Node3D


func _initialize() -> void:
	var holder := Node3D.new()
	root.add_child(holder)
	_m = (load(SCENE) as PackedScene).instantiate()
	_m.set(&"fidget_every", 0.0)
	holder.add_child(_m)
	_run()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAILED: ", what)


func _wait(sec: float) -> void:
	for i: int in int(ceil(sec * 60.0)):
		await process_frame


func _run() -> void:
	await _wait(0.1)
	_check(int(_m.call(&"authored_mesh_count")) <= 26, "authored meshes <= 26 (got %d)" % int(_m.call(&"authored_mesh_count")))
	for cls: StringName in CLASSES:
		_m.call(&"set_weapon_class", cls, false)
		await _wait(0.1)
		_check_look(cls)
		await _check_poses(cls)
	await _check_dust()
	await _check_death()
	_m.call(&"set_weapon_class", &"", false)
	await _wait(0.1)
	_check_look(&"")
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


# ---------------------------------------------------------------- the look per class

func _check_look(cls: StringName) -> void:
	var nm := String(cls) if cls != &"" else "archetype"
	var back := cls == &"two_hand" or cls == &"wizard"
	var arm_door := _m.get_node("Root/Chest/ArmL/DoorShield") as MeshInstance3D
	var back_door := _m.get_node("Root/Chest/DoorBack") as MeshInstance3D
	_check(arm_door.visible == not back, "%s: door in hand visible = %s" % [nm, not back])
	_check(back_door.visible == back, "%s: door on the back visible = %s" % [nm, back])
	_check(_m.call(&"door_in_hand") == not back and _m.call(&"door_node") == (back_door if back else arm_door), "%s: door_in_hand / door_node" % nm)
	_check(arm_door.transform.basis.get_scale().is_equal_approx(Vector3.ONE) and back_door.transform.basis.get_scale().is_equal_approx(Vector3.ONE),
		"%s: doors at full size at rest" % nm)
	# the hammer (oak haft + iron head in ArmR) only with the archetype
	_check(_pivot_has("Root/Chest/ArmR", "oathwall_oak") == (cls == &""), "%s: hammer haft only with the archetype" % nm)
	# the back classes: strap on the chest (oak), left gauntlet (iron on ArmL)
	_check(_pivot_has("Root/Chest", "oathwall_oak") == back, "%s: door strap across the chest = %s" % [nm, back])
	_check(_pivot_has("Root/Chest/ArmL", "oathwall_iron") == back, "%s: left gauntlet = %s" % [nm, back])
	_check(not _pivot_has("Root/Chest/ArmL", "weapon_team_cloth") and not _pivot_has("Root/Chest/ArmL", "weapon_wood_dark"),
		"%s: never the kit's round shield" % nm)
	match cls:
		&"sword_shield":
			_check(_m.call(&"weapon_pieces") == [&"sword"], "sword_shield pieces = [sword] (got %s)" % [_m.call(&"weapon_pieces")])
			_check(_pivot_has("Root/Chest/ArmR", "weapon_brass"), "sword in ArmR")
		&"spear":
			_check(_pivot_has("Root/Chest/ArmR", "weapon_ash") and _pivot_has("Root/Chest", "weapon_leather"), "spear in ArmR + quiver")
		&"two_hand":
			_check(_pivot_has("Root/Chest/ArmR", "weapon_steel"), "greatsword in ArmR")
		&"wizard":
			_check(_pivot_has("Root/Chest/ArmR", "weapon_crystal_glow"), "staff in ArmR")
	# budgets
	var inst := 0
	var lights := 0
	var own: Dictionary = {}
	for n: Node in _m.find_children("*", "", true, false):
		if n is Light3D:
			lights += 1
		var mi := n as MeshInstance3D
		if mi and mi.mesh and mi.is_visible_in_tree():
			inst += 1
			if mi.name != "Shadow":
				for s: int in mi.mesh.get_surface_count():
					var mat := mi.mesh.surface_get_material(s) if mi.material_override == null else mi.material_override
					if mat and mat.resource_path.begins_with(OWN_DIR):
						own[mat] = true
		elif n is GPUParticles3D:
			inst += 1
	_check(inst <= 16, "%s: <= 16 draw instances (got %d)" % [nm, inst])
	_check(lights == 0, "%s: 0 lights" % nm)
	_check(own.size() <= 5, "%s: <= 5 own materials (got %d)" % [nm, own.size()])
	# grips
	var gr: Transform3D = _m.call(&"weapon_slot_xf", &"hand_r")
	var gl: Transform3D = _m.call(&"weapon_slot_xf", &"hand_l")
	_check(gr.origin.is_equal_approx(Vector3(0.64, 1.00, 0.20)), "%s: hand_r grip at the gauntlet (%s)" % [nm, gr.origin])
	_check(gl.origin.is_equal_approx(Vector3(-0.48, 1.00, 0.24)), "%s: hand_l grip at the left fist (%s)" % [nm, gl.origin])
	# beam origin
	var bo: Variant = _m.call(&"get_beam_origin")
	_check(bo is Vector3, "%s: get_beam_origin is always a Vector3 (%s)" % [nm, bo])
	if bo is Vector3:
		var lb: Vector3 = _m.to_local(bo)
		if cls == &"wizard":
			_check(lb.distance_to(_m.to_local(_m.call(&"get_weapon_tip"))) < 0.01, "wizard: get_beam_origin = the staff crystal (%s)" % lb)
		else:
			_check(lb.y > 0.6 and lb.y < 1.8 and lb.z > 0.2 and lb.length() < 1.6, "%s: beam origin in front of him (%s)" % [nm, lb])


# ---------------------------------------------------------------- poses

func _check_poses(cls: StringName) -> void:
	var nm := String(cls) if cls != &"" else "archetype"
	var back := cls == &"two_hand" or cls == &"wizard"
	var door := _m.get_node("Root/Chest/DoorBack" if back else "Root/Chest/ArmL/DoorShield") as Node3D
	var fist := _m.get_node("Root/Chest/ArmL") as Node3D
	# Oath of Iron: the weapon goes above the helm
	_m.call(&"play_cast", &"oath_of_iron")
	await _wait(0.45)
	var tip: Variant = _m.call(&"get_weapon_tip")
	var top: float = (tip as Vector3).y if tip is Vector3 else _hammer_top()
	_check(top > 2.0, "%s: Oath of Iron raises the weapon above the helm (top %.2f)" % [nm, top])
	await _wait(0.8)
	# Shield Bash: the door comes into the left hand, then goes back
	_m.call(&"play_cast", &"shield_bash")
	await _wait(0.25)
	_check(_m.get(&"_action") == &"cast", "%s: bash playing" % nm)
	var dl: Vector3 = _local(door)
	_check(dl.z > 0.25, "%s: bash: the door is in front (z %.2f)" % [nm, dl.z])
	if back:
		var hand: Vector3 = _m.to_local(fist.global_transform * (_m.get(&"_door_arm_rest") as Transform3D).origin)
		_check(dl.distance_to(hand) < 0.12, "%s: bash: the door swung off the back into the left hand (%.2f m off)" % [nm, dl.distance_to(hand)])
	await _wait(0.8)
	_check(_m.get(&"_action") == &"", "%s: bash finished" % nm)
	_check(_at_rest(door, back), "%s: bash: the door is back where it rests" % nm)
	# Bulwark Stand: planted in front at 2 s, back after walking away
	_m.call(&"play_cast", &"bulwark_stand")
	await _wait(2.0)
	dl = _local(door)
	_check(dl.z > 0.35 and dl.y < 0.95, "%s: bulwark: the door planted in front (%s)" % [nm, dl])
	var wt: Variant = _m.call(&"get_weapon_tip")
	if wt is Vector3:
		_check(_m.to_local(wt).y > 0.3, "%s: bulwark: the weapon stays clear of the ground" % nm)
	_m.call(&"set_moving", 4.0)
	await _wait(0.7)
	_m.call(&"set_moving", 0.0)
	await _wait(0.3)
	_check(_m.get(&"_action") == &"", "%s: bulwark ended by walking" % nm)
	_check(_at_rest(door, back), "%s: bulwark: the door is back where it rests" % nm)
	# class skills
	if cls == &"":
		return
	for id: StringName in SKILLS[cls]:
		_m.call(&"play_cast", id)
		match id:
			&"hobbling_javelin":
				await _wait(0.2)
				var p1: Vector3 = _local(door)
				await _wait(0.15)
				var p2: Vector3 = _local(door)
				_check(p1.distance_to(p2) < 0.01 and p1.distance_to(Vector3(-0.44, 0.80, 0.74)) < 0.05,
					"spear javelin: the door stands still on the ground (%s / %s)" % [p1, p2])
				_check(_pivot_has("Root/Chest/ArmL", "weapon_ash"), "spear javelin: the javelin in the left hand")
			&"shield_throw":
				await _wait(0.5)
				_check(door.global_transform.basis.get_scale().x < 0.1, "sword_shield throw: the door is away (scale %.2f)" % door.global_transform.basis.get_scale().x)
			&"lunge", &"skewer", &"riposte":
				await _wait(0.3)
				_check(_local(door).z > 0.40, "%s: the door stays braced in front (z %.2f)" % [id, _local(door).z])
			_:
				await _wait(0.3)
		_check(_m.get(&"_action") == &"cast" and _m.get(&"_cast_id") == id, "%s: %s playing" % [nm, id])
		await _wait(float(SKILL_LEN.get(id, 1.1)) - 0.3 + 0.2)
		_check(_m.get(&"_action") == &"", "%s: %s finished" % [nm, id])
		_check(_at_rest(door, back),
			"%s: %s: the door back at rest" % [nm, id])
	if cls == &"sword_shield":
		_m.call(&"play_cast", &"shield_throw")
		await _wait(0.5)
		_m.call(&"play_attack")
		await _wait(0.05)
		_check(door.transform.basis.get_scale().is_equal_approx(Vector3.ONE), "shield throw interrupted: the door is back in hand")
		await _wait(0.8)


func _check_dust() -> void:
	var dust := _m.get_node("Fx/Dust") as GPUParticles3D
	for cls: StringName in [&"", &"sword_shield", &"two_hand"]:
		_m.call(&"set_weapon_class", cls, false)
		await _wait(0.1)
		dust.position = Vector3.ZERO
		_m.call(&"play_attack")
		await _wait(0.2)
		var burst: bool = dust.position.is_equal_approx(Vector3(0.40, 0.05, 1.22))
		_check(burst == (cls == &""), "slam dust only with the hammer (%s: burst %s)" % [cls, burst])
		await _wait(0.8)


func _check_death() -> void:
	_m.call(&"set_weapon_class", &"wizard", false)
	await _wait(0.1)
	var got: Array = [false]
	_m.connect(&"death_finished", func() -> void: got[0] = true, CONNECT_ONE_SHOT)
	_m.call(&"play_death")
	await _wait(1.3)
	_check(got[0], "death_finished with the door on the back")
	_m.call(&"revive")
	await _wait(0.2)
	_check((_m.get_node("Root/Chest/DoorBack") as Node3D).visible and not (_m.get_node("Root/Chest/ArmL/DoorShield") as Node3D).visible,
		"revive keeps the door on the back")


# ---------------------------------------------------------------- helpers

## The door node back on its authored local transform (in the hand / on the back, full size).
func _at_rest(door: Node3D, back: bool) -> bool:
	var rest: Transform3D = _m.get(&"_door_back_rest" if back else &"_door_arm_rest")
	return door.transform.is_equal_approx(rest)


func _local(n: Node3D) -> Vector3:
	return _m.to_local(n.global_position)


## The archetype: the top of the hammer = the highest point of the ArmR merged mesh.
func _hammer_top() -> float:
	var arm := _m.get_node("Root/Chest/ArmR/Merged") as MeshInstance3D
	var aabb: AABB = _m.global_transform.affine_inverse() * arm.global_transform * arm.get_aabb()
	return aabb.end.y


func _pivot_has(pivot: String, mat_part: String) -> bool:
	var node := _m.get_node_or_null(pivot + "/Merged") as MeshInstance3D
	if node == null or node.mesh == null:
		return false
	for s: int in node.mesh.get_surface_count():
		var mat := node.mesh.surface_get_material(s)
		if mat and mat.resource_path.get_file().contains(mat_part):
			return true
	return false
