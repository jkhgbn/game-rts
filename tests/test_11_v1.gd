extends SceneTree
## Task 11.V1: champion class weapon kit (art/units/champions/weapons/) + CharacterModel.set_weapon_class, the 4 class
## attack styles and the generic poses of the 12 class skills.
## Run: $GODOT --headless --path . -s tests/test_11_v1.gd --fixed-fps 60 --quit-after 9000
## Checks: the kit (4 classes, 7 pieces, shared materials, 1 glow = the crystal, vertex budgets); each of the 4 champion
## models with each class and &"" (weapon merged into the grip pivots: 0 extra draw instances, 0 lights, <= 16 draw
## instances, the class pieces' materials on the right pivots, attack_style / windup, get_weapon_tip, the crystal glow
## driven); the 0.3 s scale-in; team colour on the tassel / shield boss (either order); each attack style and each of
## the 12 class skill poses plays and ends on every model (javelin shown during the throw, shield hidden in flight);
## the archetype casts still play; death / revive keep the class; the tagging convention on a code-built test model
## (static archetype parts left out, keep_separate ones hidden, parts only for one class, _weapon_pieces /
## _on_weapon_class hooks). Prints "PASS 11.v1" or "FAIL 11.v1: <reasons>".

const TASK_ID := "11.v1"
const KIT := "res://art/units/champions/weapons/champion_weapon_kit.gd"
const WEAPON_MATS := "res://art/units/champions/weapons/materials/"
const CHAMPIONS: Array[String] = ["wayfinder", "oathwall", "coin_cutter", "mender"]
const CLASSES: Array[StringName] = [&"spear", &"sword_shield", &"two_hand", &"wizard"]
const STYLE: Dictionary = {&"spear": &"spear_thrust", &"sword_shield": &"sword_slash", &"two_hand": &"great_cleave",
	&"wizard": &"staff_bolt"}
const SKILLS: Dictionary = {
	&"spear": [&"lunge", &"hobbling_javelin", &"skewer"],
	&"sword_shield": [&"riposte", &"second_wind", &"shield_throw"],
	&"two_hand": [&"cleave", &"crushing_blow", &"whirlwind"],
	&"wizard": [&"arc_bolt", &"slipstep", &"starfall"],
}
const ARCH_CASTS: Dictionary = {"wayfinder": &"flare_arrow", "oathwall": &"shield_bash", "coin_cutter": &"cutpurse",
	"mender": &"lifeline"}
const SHADOW := Color(0.42, 0.22, 0.60)
const ICE := Color(0.45, 0.75, 0.95)

var _fails: PackedStringArray = PackedStringArray()
var _world: Node3D
var _kit: GDScript


func _initialize() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	_run()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)
		print("  FAILED: ", what)


func _wait(sec: float) -> void:
	for i: int in int(ceil(sec * 60.0)):
		await process_frame


func _spawn(path: String, at: Vector3) -> Node3D:
	var holder := Node3D.new()
	holder.position = at
	_world.add_child(holder)
	var m: Node3D = (load(path) as PackedScene).instantiate()
	holder.add_child(m)
	return m


func _run() -> void:
	_kit = load(KIT)
	_check(_kit != null, "weapon kit script loads")
	_check_kit()
	var models: Array = []
	for i: int in CHAMPIONS.size():
		var p := "res://art/units/champions/%s/%s.tscn" % [CHAMPIONS[i], CHAMPIONS[i]]
		_check(ResourceLoader.exists(p), "%s scene exists" % CHAMPIONS[i])
		models.append(_spawn(p, Vector3(3.0 * i, 0, 0)))
	await _wait(0.2)
	await _check_classes(models)
	await _check_pop(models[0])
	await _check_team(models)
	await _check_motion(models)
	await _check_convention()
	# a second instance of a class-swapped type reuses the cached variants and starts with the archetype look
	var again: Node3D = (load("res://art/units/champions/wayfinder/wayfinder.tscn") as PackedScene).instantiate()
	again.call(&"set_weapon_class", &"wizard")   # before _ready: kept and applied without the pop
	var holder := Node3D.new()
	holder.position = Vector3(0, 0, 6)
	_world.add_child(holder)
	holder.add_child(again)
	await _wait(0.1)
	_check(again.call(&"weapon_class") == &"wizard", "set_weapon_class before _ready is applied")
	_check(again.find_children("WeaponPop", "", true, false).is_empty(), "no scale-in for a class applied before _ready")
	if _fails.is_empty():
		print("PASS %s" % TASK_ID)
	else:
		print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
	quit()


# ---------------------------------------------------------------- the kit

func _check_kit() -> void:
	var files := DirAccess.get_files_at(WEAPON_MATS)
	var tres := 0
	for f: String in files:
		if f.ends_with(".tres"):
			tres += 1
	print("weapon materials on disk: ", tres)
	_check(tres == 8, "8 shared weapon materials (got %d)" % tres)
	var total := 0
	for cls: StringName in CLASSES:
		_check(bool(_kit.call(&"has_class", cls)), "kit has class %s" % cls)
		_check(_kit.call(&"attack_style_for", cls) == STYLE[cls], "attack style of %s" % cls)
		var pieces: Array = _kit.call(&"pieces_for", cls)
		_check(not pieces.is_empty(), "%s has pieces" % cls)
		for p: StringName in pieces:
			var m: ArrayMesh = _kit.call(&"piece_mesh", p)
			var nv: int = int(_kit.call(&"piece_vertices", p))
			total += nv
			var glows := 0
			for s: int in m.get_surface_count():
				var mat := m.surface_get_material(s)
				_check(mat != null and mat.resource_path.begins_with(WEAPON_MATS), "%s surface %d uses a shared weapon material" % [p, s])
				var sh := (mat as ShaderMaterial).shader.resource_path if mat is ShaderMaterial else ""
				_check(sh.ends_with("unit_painted.gdshader") or sh.ends_with("unit_glow.gdshader"), "%s uses a kit unit shader" % p)
				if sh.ends_with("unit_glow.gdshader"):
					glows += 1
			print("  piece %-13s %d surfaces, %d vertices, aabb %s" % [p, m.get_surface_count(), nv, m.get_aabb().size])
			_check(nv > 40 and nv <= 1400, "%s vertices in budget (got %d)" % [p, nv])
			_check(glows == (1 if p == &"staff" else 0), "%s glow surfaces (got %d)" % [p, glows])
	print("weapon kit vertices (all pieces): ", total)
	_check(_kit.call(&"has_class", &"archer") == false, "unknown class refused by the kit")
	# sizes of the spec (skills-rework.md 5)
	var spear: AABB = (_kit.call(&"piece_mesh", &"spear") as Mesh).get_aabb()
	_check(spear.size.y > 2.55 and spear.size.y < 2.9, "spear ~2.3 m shaft + blade (got %.2f)" % spear.size.y)
	var gs: AABB = (_kit.call(&"piece_mesh", &"greatsword") as Mesh).get_aabb()
	_check(gs.size.y > 2.0 and gs.size.y < 2.3 and gs.size.x > 0.45, "greatsword 1.6 m blade + grip, wide guard")
	var sh: AABB = (_kit.call(&"piece_mesh", &"round_shield") as Mesh).get_aabb()
	_check(absf(sh.size.x - 0.856) < 0.05, "round shield r 0.4 (got %.2f wide)" % sh.size.x)
	var st: AABB = (_kit.call(&"piece_mesh", &"staff") as Mesh).get_aabb()
	_check(st.size.y > 1.8 and st.size.y < 2.2, "staff ~1.8 m + head (got %.2f)" % st.size.y)


# ---------------------------------------------------------------- each model x each class

func _check_classes(models: Array) -> void:
	var base_inst: Array[int] = []
	for m: Node3D in models:
		base_inst.append(_draw_instances(m))
	for cls: StringName in [&"spear", &"sword_shield", &"two_hand", &"wizard", &""]:
		for m: Node3D in models:
			m.call(&"set_weapon_class", cls, false)
		await _wait(0.1)
		for k: int in models.size():
			var m: Node3D = models[k]
			var nm := CHAMPIONS[k]
			var inst := _draw_instances(m)
			var verts := _vertices(m)
			print("%-11s %-12s draw instances %d (archetype %d), vertices %d, lights %d" % [nm, cls if cls != &"" else &"(archetype)",
				inst, base_inst[k], verts, m.find_children("*", "Light3D", true, false).size()])
			_check(inst == base_inst[k], "%s %s: weapon merged, no extra draw instance (%d vs %d)" % [nm, cls, inst, base_inst[k]])
			_check(inst <= 17, "%s %s: <= 17 draw instances (16 + the Face node)" % [nm, cls])
			_check(m.find_children("*", "Light3D", true, false).is_empty(), "%s %s: 0 lights" % [nm, cls])
			_check(m.call(&"weapon_class") == cls, "%s weapon_class() = %s" % [nm, cls])
			var own := 0
			for mat: Material in _materials(m):
				if mat.resource_path.begins_with("res://art/units/champions/%s/" % nm):
					own += 1
			_check(own <= 5, "%s %s: <= 5 own materials (got %d)" % [nm, cls, own])
			if cls == &"":
				_check(m.get(&"attack_style") != &"spear_thrust" and m.call(&"get_weapon_tip") == null, "%s back to the archetype weapon" % nm)
				_check(_pivot_has(m, "Root/Chest/ArmR", "weapon_") == false and _pivot_has(m, "Root/Chest", "weapon_") == false,
					"%s: no weapon surface left with the archetype look" % nm)
				continue
			_check(m.get(&"attack_style") == STYLE[cls], "%s %s: attack_style %s" % [nm, cls, STYLE[cls]])
			_check(is_equal_approx(float(m.get(&"attack_windup")), 0.12 if cls == &"wizard" else 0.0), "%s %s: attack_windup" % [nm, cls])
			var tip: Variant = m.call(&"get_weapon_tip")
			_check(tip is Vector3, "%s %s: get_weapon_tip is a position" % [nm, cls])
			if tip is Vector3:
				var local: Vector3 = m.to_local(tip)
				_check(local.y > 0.5 and local.y < 3.2 and local.length() < 3.2, "%s %s: weapon tip near the model (%s)" % [nm, cls, local])
			match cls:
				&"spear":
					_check(_pivot_has(m, "Root/Chest/ArmR", "weapon_ash") and _pivot_has(m, "Root/Chest/ArmR", "weapon_team_cloth"), "%s spear in ArmR" % nm)
					_check(_pivot_has(m, "Root/Chest", "weapon_leather"), "%s quiver on the back (Chest)" % nm)
					_check(not _pivot_has(m, "Root/Chest/ArmL", "weapon_ash"), "%s javelin hidden at rest" % nm)
				&"sword_shield":
					_check(_pivot_has(m, "Root/Chest/ArmR", "weapon_brass"), "%s sword in ArmR" % nm)
					if nm == "oathwall":   # 11.V3: he keeps his own door shield (tested in test_11_v3)
						_check(not _pivot_has(m, "Root/Chest/ArmL", "weapon_team_cloth") and _door_scale(m) > 0.9,
							"oathwall keeps his door, no round shield")
					else:
						_check(_pivot_has(m, "Root/Chest/ArmL", "weapon_team_cloth"), "%s round shield in ArmL" % nm)
				&"two_hand":
					_check(_pivot_has(m, "Root/Chest/ArmR", "weapon_steel") and _pivot_has(m, "Root/Chest/ArmR", "weapon_iron"), "%s greatsword in ArmR" % nm)
				&"wizard":
					_check(_pivot_has(m, "Root/Chest/ArmR", "weapon_crystal_glow"), "%s staff crystal in ArmR" % nm)
					var arm: Node = m.get_node("Root/Chest/ArmR/Merged")
					_check((m.get(&"_wk_glow_added") as Array).has(arm) and arm.has_meta(&"own_glow"), "%s crystal glow driven by the kit" % nm)
			# the weapon hand: the main piece's grip sits near the arm's lowest point, under the shoulder
			var g: Transform3D = m.call(&"weapon_slot_xf", &"hand_r")
			var sh: Vector3 = (m.get_node("Root/Chest/ArmR") as Node3D).global_position - m.global_position
			_check(g.origin.y < sh.y - 0.1 and g.origin.y > 0.4, "%s hand_r grip under the shoulder (%s)" % [nm, g.origin])


# ---------------------------------------------------------------- scale-in

func _check_pop(m: Node3D) -> void:
	var base := _draw_instances(m)
	m.call(&"set_weapon_class", &"spear")
	await process_frame
	var pops := m.find_children("WeaponPop", "", true, false)
	_check(pops.size() == 2, "scale-in: 2 pop nodes (spear + quiver), got %d" % pops.size())
	_check(not _pivot_has(m, "Root/Chest/ArmR", "weapon_ash"), "scale-in: the spear is not merged yet")
	await _wait(0.12)
	if not pops.is_empty() and is_instance_valid(pops[0]):
		var s: float = (pops[0] as Node3D).transform.basis.get_scale().x
		_check(s > 0.3 and s < 1.2, "scale-in: growing (scale %.2f)" % s)
	await _wait(0.35)
	_check(m.find_children("WeaponPop", "", true, false).is_empty(), "scale-in over after 0.3 s")
	_check(_pivot_has(m, "Root/Chest/ArmR", "weapon_ash"), "scale-in: the spear merged at the end")
	_check(_draw_instances(m) == base, "scale-in: back to the same draw instances")
	m.call(&"set_weapon_class", &"")
	await process_frame


# ---------------------------------------------------------------- team colour

func _check_team(models: Array) -> void:
	var a: Node3D = models[1]   # Oathwall (own set_team_color override); 11.V3: no round shield, so his spear tassel
	a.call(&"set_team_color", SHADOW)
	a.call(&"set_weapon_class", &"spear", false)
	await process_frame
	_check(_team_color_on(a, "Root/Chest/ArmR").is_equal_approx(SHADOW), "oathwall spear tassel takes the team colour (colour first)")
	var c: Node3D = models[3]
	c.call(&"set_team_color", SHADOW)
	c.call(&"set_weapon_class", &"sword_shield", false)
	await process_frame
	_check(_team_color_on(c, "Root/Chest/ArmL").is_equal_approx(SHADOW), "shield boss takes the team colour (colour first)")
	var b: Node3D = models[2]
	b.call(&"set_weapon_class", &"spear", false)
	b.call(&"set_team_color", ICE)
	await process_frame
	_check(_team_color_on(b, "Root/Chest/ArmR").is_equal_approx(ICE), "spear tassel takes the team colour (class first)")
	for m: Node3D in [a, b, c]:
		m.call(&"set_weapon_class", &"")
	await process_frame


# ---------------------------------------------------------------- attack styles + class skill poses

func _check_motion(models: Array) -> void:
	for cls: StringName in CLASSES:
		for m: Node3D in models:
			m.call(&"set_weapon_class", cls, false)
		await _wait(0.1)
		# attack style: the weapon arm moves at the strike frame, the attack ends
		for m: Node3D in models:
			m.call(&"play_attack")
		await _wait(0.13)
		for k: int in models.size():
			var m: Node3D = models[k]
			_check(m.get(&"_action") == &"attack", "%s %s: attacking" % [CHAMPIONS[k], STYLE[cls]])
			_check(_posed(m), "%s %s: the body moves at the strike" % [CHAMPIONS[k], STYLE[cls]])
		await _wait(0.9)
		for k: int in models.size():
			_check(models[k].get(&"_action") == &"", "%s %s: attack finished" % [CHAMPIONS[k], STYLE[cls]])
		# the 3 class skills
		for id: StringName in SKILLS[cls]:
			for m: Node3D in models:
				m.call(&"play_cast", id)
			var probe := 0.22
			match id:
				&"hobbling_javelin":
					probe = 0.25
				&"shield_throw":
					probe = 0.5
				&"slipstep":
					probe = 0.15
			await _wait(probe)
			for k: int in models.size():
				var m: Node3D = models[k]
				var nm := CHAMPIONS[k]
				_check(m.get(&"_action") == &"cast" and m.get(&"_cast_id") == id, "%s %s: casting" % [nm, id])
				_check(_posed(m), "%s %s: the generic pose moves the body" % [nm, id])
				match id:
					&"hobbling_javelin":
						_check(_pivot_has(m, "Root/Chest/ArmL", "weapon_ash"), "%s javelin in the left hand during the throw" % nm)
					&"shield_throw":
						_check(not _pivot_has(m, "Root/Chest/ArmL", "weapon_team_cloth") and (nm != "oathwall" or _door_scale(m) < 0.1), "%s shield hidden in flight" % nm)
					&"lunge":
						_check((m.get_node("Root") as Node3D).position.z > 0.25, "%s lunge: the kit's dash-thrust (not the model's cast)" % nm)
			var length: float = {&"riposte": 4.0, &"whirlwind": 2.0, &"second_wind": 1.4, &"starfall": 1.2}.get(id, 1.1)
			await _wait(length - probe + 0.2)
			for k: int in models.size():
				var m: Node3D = models[k]
				_check(m.get(&"_action") == &"", "%s %s: finished" % [CHAMPIONS[k], id])
				if id == &"hobbling_javelin":
					_check(not _pivot_has(m, "Root/Chest/ArmL", "weapon_ash"), "%s javelin gone after the throw" % CHAMPIONS[k])
				if id == &"shield_throw":
					_check(_has_shield(m), "%s shield caught back" % CHAMPIONS[k])
				if id == &"slipstep":
					_check((m.get_node("Root") as Node3D).scale.is_equal_approx(Vector3.ONE), "%s slipstep: back to full size" % CHAMPIONS[k])
		# an interrupted shield throw gives the shield back
		if cls == &"sword_shield":
			for m: Node3D in models:
				m.call(&"play_cast", &"shield_throw")
			await _wait(0.5)
			for m: Node3D in models:
				m.call(&"play_attack")
			await _wait(0.1)
			for k: int in models.size():
				_check(_has_shield(models[k]), "%s shield back when an attack interrupts the throw" % CHAMPIONS[k])
			await _wait(0.8)
	# archetype casts still play with a class weapon (their per-champion versions come in 11.V2-11.V5)
	for k: int in models.size():
		models[k].call(&"play_cast", ARCH_CASTS[CHAMPIONS[k]])
	await _wait(0.3)
	for k: int in models.size():
		_check(models[k].get(&"_action") == &"cast", "%s archetype cast plays with a class weapon" % CHAMPIONS[k])
	await _wait(1.3)
	# death and revive keep the class
	var m0: Node3D = models[0]
	var got: Array = [false]
	m0.connect(&"death_finished", func() -> void: got[0] = true, CONNECT_ONE_SHOT)
	m0.call(&"play_death")
	await _wait(1.3)
	_check(got[0], "death_finished with a class weapon")
	m0.call(&"revive")
	await _wait(0.2)
	_check(m0.call(&"weapon_class") == &"wizard" and _pivot_has(m0, "Root/Chest/ArmR", "weapon_crystal_glow"), "revive keeps the class weapon")
	for m: Node3D in models:
		m.call(&"set_weapon_class", &"")
	await _wait(0.1)
	for k: int in models.size():
		_check(models[k].get(&"attack_style") == [&"bow", &"slam", &"slash2", &"staff"][k], "%s archetype attack style restored" % CHAMPIONS[k])


# ---------------------------------------------------------------- tagging convention (code-built model)

const TEST_MODEL_SRC := """extends CharacterModel
var classes_seen: Array = []
func _build_parts() -> void:
	var chest: Node3D = $Root/Chest
	var arm_r: Node3D = $Root/Chest/ArmR
	add_part(chest, box(Vector3(0.5, 0.6, 0.3)), palette(&"fire_cloth"), Vector3(0, 1.2, 0))
	add_part(arm_r, capsule(0.08, 0.5), palette(&"fire_skin"), Vector3(0.3, 1.15, 0))
	add_part(arm_r, sphere(0.09), palette(&"fire_skin"), Vector3(0.3, 0.92, 0.05))
	var hammer := add_part(arm_r, box(Vector3(0.1, 0.5, 0.1)), palette(&"fire_bronze"), Vector3(0.3, 0.8, 0.3))
	mark_archetype_weapon(hammer)
	var back := add_part(chest, box(Vector3(0.6, 0.8, 0.05)), palette(&"shadow_iron"), Vector3(0, 1.2, -0.25))
	mark_weapon_classes(back, [&"two_hand", &"wizard"])
	var bow := add_part(arm_r, box(Vector3(0.05, 0.8, 0.05)), palette(&"fire_wood"), Vector3(0.35, 0.92, 0.1), Vector3.ZERO, Vector3.ONE, true, "Bow")
	mark_archetype_weapon(bow)
func _weapon_pieces(class_id: StringName) -> Array[StringName]:
	var p := super._weapon_pieces(class_id)
	if class_id == &"sword_shield":
		p.erase(&"round_shield")
	return p
func _on_weapon_class(class_id: StringName) -> void:
	classes_seen.append(class_id)
"""


func _check_convention() -> void:
	var s := GDScript.new()
	s.source_code = TEST_MODEL_SRC
	var err := s.reload()
	_check(err == OK, "test model script compiles")
	if err != OK:
		return
	var made: Array = []
	for n: int in 2:
		var m := Node3D.new()
		m.name = "TagTest%d" % n
		m.set_script(s)
		var r := Node3D.new()
		r.name = "Root"
		m.add_child(r)
		var chest := Node3D.new()
		chest.name = "Chest"
		chest.position = Vector3(0, 1.0, 0)
		r.add_child(chest)
		var arm := Node3D.new()
		arm.name = "ArmR"
		arm.position = Vector3(0.3, 0.42, 0)
		chest.add_child(arm)
		var arm_l := Node3D.new()
		arm_l.name = "ArmL"
		arm_l.position = Vector3(-0.3, 0.42, 0)
		chest.add_child(arm_l)
		var holder := Node3D.new()
		holder.position = Vector3(20 + 3 * n, 0, 0)
		_world.add_child(holder)
		holder.add_child(m)
		made.append(m)
	await _wait(0.1)
	for m: Node3D in made:
		var bow: Node3D = m.get_node("Root/Chest/ArmR/Bow")
		_check(_pivot_has(m, "Root/Chest/ArmR", "fire_bronze"), "tag: the archetype hammer is merged before a class")
		_check(not _pivot_has(m, "Root/Chest", "shadow_iron"), "tag: a part only for two_hand / wizard is left out before a class")
		_check(bow.visible, "tag: keep_separate archetype bow visible before a class")
		m.call(&"set_weapon_class", &"spear", false)
		await process_frame
		_check(not _pivot_has(m, "Root/Chest/ArmR", "fire_bronze") and _pivot_has(m, "Root/Chest/ArmR", "fire_skin"),
			"tag: spear drops the hammer, keeps the arm")
		_check(_pivot_has(m, "Root/Chest/ArmR", "weapon_ash"), "tag: the spear merged into ArmR")
		_check(not bow.visible, "tag: keep_separate bow hidden with a class")
		_check(not _pivot_has(m, "Root/Chest", "shadow_iron"), "tag: two_hand-only part still out with spear")
		m.call(&"set_weapon_class", &"two_hand", false)
		await process_frame
		_check(_pivot_has(m, "Root/Chest", "shadow_iron"), "tag: two_hand-only part merged with two_hand")
		m.call(&"set_weapon_class", &"sword_shield", false)
		await process_frame
		_check(_pivot_has(m, "Root/Chest/ArmR", "weapon_brass") and not _pivot_has(m, "Root/Chest/ArmL", "weapon_team_cloth"),
			"tag: _weapon_pieces drops the round shield")
		m.call(&"set_weapon_class", &"")
		await process_frame
		_check(_pivot_has(m, "Root/Chest/ArmR", "fire_bronze") and bow.visible and not _pivot_has(m, "Root/Chest/ArmR", "weapon_"),
			"tag: &\"\" restores the archetype weapon")
		_check(m.get(&"classes_seen") == [&"spear", &"two_hand", &"sword_shield", &""], "tag: _on_weapon_class called for each change")
		# auto grip: the fist found at the lowest point of the arm (the hand sphere, the hammer left out)
		var g: Transform3D = m.call(&"weapon_slot_xf", &"hand_r")
		_check(absf(g.origin.y - (0.83 + 0.085)) < 0.03 and absf(g.origin.x - 0.3) < 0.05, "tag: auto grip at the fist (%s)" % g.origin)


# ---------------------------------------------------------------- helpers

## 11.V3: the Oathwall throws his own door (node DoorShield, shrunk away in flight); the others the kit's round shield.
func _has_shield(m: Node3D) -> bool:
	if m.has_node("Root/Chest/ArmL/DoorShield"):
		return _door_scale(m) > 0.9
	return _pivot_has(m, "Root/Chest/ArmL", "weapon_team_cloth")


func _door_scale(m: Node3D) -> float:
	var d := m.get_node_or_null("Root/Chest/ArmL/DoorShield") as Node3D
	if d == null or not d.visible:
		return 0.0
	return d.transform.basis.get_scale().x

func _posed(m: Node3D) -> bool:
	for p: String in ["Root", "Root/Chest", "Root/Chest/ArmR", "Root/Chest/ArmL"]:
		var n: Node3D = m.get_node(p)
		if n.rotation.length() > 0.08:
			return true
	var r: Node3D = m.get_node("Root")
	return r.position.length() > 0.05 or not r.scale.is_equal_approx(Vector3.ONE)


## True when the merged mesh of the pivot has a surface whose material file name contains `mat_part`.
func _pivot_has(m: Node3D, pivot: String, mat_part: String) -> bool:
	var node := m.get_node_or_null(pivot + "/Merged") as MeshInstance3D
	if node == null or node.mesh == null:
		return false
	for s: int in node.mesh.get_surface_count():
		var mat := node.mesh.surface_get_material(s)
		if mat and mat.resource_path.get_file().contains(mat_part):
			return true
	return false


## The team colour on the weapon_team_cloth surface of a pivot (its override), black when none.
func _team_color_on(m: Node3D, pivot: String) -> Color:
	var node := m.get_node_or_null(pivot + "/Merged") as MeshInstance3D
	if node == null or node.mesh == null:
		return Color.BLACK
	for s: int in node.mesh.get_surface_count():
		var mat := node.mesh.surface_get_material(s)
		if mat and mat.resource_path.ends_with("weapon_team_cloth.tres"):
			var o := node.get_surface_override_material(s) as ShaderMaterial
			if o:
				return o.get_shader_parameter(&"base_color")
	return Color.BLACK


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
