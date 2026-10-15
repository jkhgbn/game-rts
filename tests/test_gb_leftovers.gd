extends SceneTree
## Task G-B leftovers (docs/art/gb_leftovers.md):
## - the Fire / Nature / Shadow Forge models exist at their BuildingType.model_path, are the right classes, run the
##   FireHallModel hooks (team colour, selection, site with scaffold, damage, training pulse, collapse ->
##   destroyed_finished), stay under the hall vertex budget, paint with their kingdom's layer (Fire: fire_painted_vc,
##   Nature: NatureVC, Shadow: painted_vc + ShadowDress), Low headless (gb_detail 0, no ShadowDress);
## - the Ember Stables draw with fire_stables_painted (gb_detail 0 here), the other Stables keep their shaders,
##   FireBuildingLook.legacy keeps the old one;
## - the completion settle (BuildSettle): hall and small models carry the dust + glint emitters (no_ghost), the dust
##   tone is never bright, the flavour follows the kingdom, `play` fires both;
## - fog: an enemy building the local team does not see (VfxFog stand-in in group "fog") completes -> no settle; an own
##   building under the same fog still settles;
## - ShadowDress marks its model's grass-free radius and GroundDetail reads it from the building's model(), and
##   GroundDetail.refresh_clears (public path) clears one circle of the bigger (dead-ground) radius round it.
## Run:  tools\godot_run.ps1 --headless --path . -s tests/test_gb_leftovers.gd --fixed-fps 60 --quit-after 1500

const TASK_ID := "gb_leftovers"
const FORGES := {
	"fire": ["fire_forge", "EmberForgeModel"],
	"nature": ["nature_forge", "GroveForgeModel"],
	"shadow": ["shadow_forge", "GloomForgeModel"],
	"ice": ["ice_forge", "FrostForgeModel"],
}
const STABLES := {
	"fire": "res://art/buildings/stables/fire/fire_stables.tscn",
	"ice": "res://art/buildings/stables/ice/ice_stables.tscn",
	"nature": "res://art/buildings/stables/nature/nature_stables.tscn",
	"shadow": "res://art/buildings/stables/shadow/shadow_stables.tscn",
}
const HALLS := {
	"fire": "res://art/buildings/fire_hall.tscn",
	"ice": "res://art/buildings/ice_hall.tscn",
	"nature": "res://art/buildings/nature_hall.tscn",
	"shadow": "res://art/buildings/shadow_hall.tscn",
}
const HOVEL := "res://art/buildings/hovel.tscn"
const FIRE_STABLES_SHADER := "res://art/buildings/stables/fire/fire_stables_painted.gdshader"
const STABLES_SHADER := "res://art/buildings/stables/stables_painted.gdshader"

var _forges := {}
var _stables := {}
var _halls := {}
var _hovel: Node3D
var _legacy_stables: Node3D
var _dead := {}
var _frame := 0
var _fog: Node
var _fog_enemy: Node3D
var _fog_own: Node3D
var _errors: Array[String] = []


func _initialize() -> void:
	var x := 0.0
	for k: String in FORGES:
		var ty := BuildingType.find(FORGES[k][0])
		var ps: PackedScene = ty.get_model_scene() if ty else null
		_expect(ps != null, "%s finds its model (model_path %s)" % [FORGES[k][0], ty.model_path if ty else "?"])
		if ps == null:
			continue
		var n := ps.instantiate() as Node3D
		n.position = Vector3(x, 0, 0)
		x += 12.0
		root.add_child(n)
		_forges[k] = n
	for k: String in STABLES:
		var s := (load(STABLES[k]) as PackedScene).instantiate() as Node3D
		s.position = Vector3(x, 0, 20)
		x += 14.0
		root.add_child(s)
		_stables[k] = s
	for k: String in HALLS:
		var h := (load(HALLS[k]) as PackedScene).instantiate() as Node3D
		h.position = Vector3(x, 0, -20)
		x += 12.0
		root.add_child(h)
		_halls[k] = h
	_hovel = (load(HOVEL) as PackedScene).instantiate() as Node3D
	_hovel.position = Vector3(0, 0, -40)
	root.add_child(_hovel)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		var fbl := load("res://art/buildings/fire/fire_building_look.gd")
		fbl.set(&"legacy", true)
		_legacy_stables = (load(STABLES["fire"]) as PackedScene).instantiate() as Node3D
		_legacy_stables.position = Vector3(0, 0, 60)
		root.add_child(_legacy_stables)
		fbl.set(&"legacy", false)
	if _frame == 3:
		_check_forges()
		_check_stables()
		_check_settle()
		_check_grass_clear()
		_setup_fog_settle()
		for k: String in _forges:
			var f := _forges[k] as Node
			f.call(&"set_selected", true)
			f.call(&"set_team_color", Color(0.25, 0.45, 0.85))
			f.call(&"set_construction_progress", 0.5)
	if _frame == 4:
		_check_fog_settle()
	if _frame == 5:
		for k: String in _forges:
			var f := _forges[k] as Node
			var sc := f.get(&"_scaffold") as Node3D
			_expect(sc != null and sc.visible, "%s forge: scaffold shows on a site" % k)
			f.call(&"set_construction_progress", 1.0)
			_expect(sc != null and not sc.visible, "%s forge: scaffold gone when built" % k)
			f.call(&"play_training_pulse")
			f.call(&"set_health_ratio", 0.2)
			var hidden := f.get(&"_hide_below_50") as Array
			var any_hidden := false
			for n: Node3D in hidden:
				any_hidden = any_hidden or not n.visible
			_expect(any_hidden, "%s forge: a part is lost under 50 %% HP" % k)
			f.connect(&"destroyed_finished", func() -> void: _dead[k] = true)
			f.call(&"play_destroyed")
	if _frame == 60 * 3 + 40:
		for k: String in _forges:
			_expect(_dead.get(k, false), "%s forge: destroyed_finished" % k)
		if _errors.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			for e: String in _errors:
				print("  x ", e)
			print("FAIL %s: %s" % [TASK_ID, _errors[0]])
		return true
	return false


func _check_forges() -> void:
	for k: String in _forges:
		var f := _forges[k] as Node3D
		var cls: String = FORGES[k][1]
		_expect((f.get_script() as Script).get_global_name() == StringName(cls), "%s forge is a %s" % [k, cls])
		for hook: StringName in [&"set_team_color", &"set_construction_progress", &"set_health_ratio",
				&"play_training_pulse", &"play_destroyed", &"set_selected"]:
			_expect(f.has_method(hook), "%s forge has %s" % [k, hook])
		var verts := _vertex_count(f)
		_expect(verts > 1500 and verts <= 12000, "%s forge vertices %d in (1500, 12000]" % [k, verts])
	if _forges.has("fire"):
		var m: ShaderMaterial = (_forges["fire"] as Node).get(&"mat_team")
		_expect(m != null and m.shader.resource_path == "res://art/buildings/fire/fire_painted_vc.gdshader",
			"fire forge body uses fire_painted_vc (got %s)" % (m.shader.resource_path if m else "null"))
		_expect(m != null and float(m.get_shader_parameter(&"gb_detail")) == 0.0, "fire forge gb_detail 0 headless (Low)")
		_expect(((_forges["fire"] as Node).get(&"_hazes") as Array).is_empty(), "fire forge: no heat haze at Low")
	if _forges.has("nature"):
		var nat := _forges["nature"] as Node
		var found := false
		for mi: Node in nat.find_children("*", "MeshInstance3D", true, false):
			var g := mi as MeshInstance3D
			for i: int in g.get_surface_override_material_count():
				var sm := g.get_surface_override_material(i) as ShaderMaterial
				if sm and sm.shader and sm.shader.resource_path == "res://art/buildings/nature/nature_vc.gdshader":
					found = true
		_expect(found, "nature forge draws with the NatureVC merged material")
	if _forges.has("shadow"):
		var sh := _forges["shadow"] as Node
		_expect(sh.get(&"_dress") == null, "shadow forge: no ShadowDress at Low")
		_expect(sh.get(&"mat_team_dark") != null, "shadow forge: dark slate courses")


func _check_stables() -> void:
	var fire_body: ShaderMaterial = (_stables["fire"] as Node).get(&"mat_body")
	_expect(fire_body != null and fire_body.shader.resource_path == FIRE_STABLES_SHADER,
		"Ember Stables draw with fire_stables_painted (got %s)" % (fire_body.shader.resource_path if fire_body else "null"))
	_expect(fire_body != null and float(fire_body.get_shader_parameter(&"gb_detail")) == 0.0, "Ember Stables gb_detail 0 (Low)")
	for k: String in ["nature", "shadow"]:
		var b: ShaderMaterial = (_stables[k] as Node).get(&"mat_body")
		_expect(b != null and b.shader.resource_path == STABLES_SHADER, "%s stables keep stables_painted" % k)
	var ib: ShaderMaterial = (_stables["ice"] as Node).get(&"mat_body")
	_expect(ib != null and ib.shader.resource_path != FIRE_STABLES_SHADER, "ice stables keep their shader")
	var lb: ShaderMaterial = _legacy_stables.get(&"mat_body")
	_expect(lb != null and lb.shader.resource_path == STABLES_SHADER, "legacy Ember Stables keep stables_painted")


func _check_settle() -> void:
	var styles := {"fire": BuildSettle.Style.EMBER, "ice": BuildSettle.Style.FROST, "nature": BuildSettle.Style.POLLEN,
		"shadow": BuildSettle.Style.SOUL}
	for k: String in _halls:
		var h := _halls[k] as Node
		var dust := h.get(&"_build_dust") as GPUParticles3D
		var glint := h.get(&"_build_flash") as GPUParticles3D
		_expect(dust != null and glint != null, "%s hall has the settle emitters" % k)
		if dust == null or glint == null:
			continue
		_expect(dust.one_shot and glint.one_shot, "%s hall settle is one-shot" % k)
		_expect(dust.get_meta(&"no_ghost", false) and glint.get_meta(&"no_ghost", false), "%s hall settle is no_ghost" % k)
		var ramp := (dust.process_material as ParticleProcessMaterial).color_ramp as GradientTexture1D
		var c: Color = ramp.gradient.get_color(0)
		_expect(c.v <= BuildSettle.DUST_MAX_V + 0.001, "%s hall dust is not bright (v %.2f)" % [k, c.v])
		_expect(BuildSettle.style_of(h.get(&"glow_color")) == styles[k], "%s settle flavour" % k)
		BuildSettle.play(dust, glint, h as Node3D)
		_expect(dust.emitting and glint.emitting, "%s hall settle fires (no fog)" % k)
	var sd := _hovel.get(&"_settle_dust") as GPUParticles3D
	var sg := _hovel.get(&"_settle_glint") as GPUParticles3D
	_expect(sd != null and sg != null, "hovel has the settle emitters")
	if sd and sg:
		var rc: Color = ((sd.process_material as ParticleProcessMaterial).color_ramp as GradientTexture1D).gradient.get_color(0)
		_expect(rc.v <= BuildSettle.DUST_MAX_V + 0.001, "hovel dust is not bright")
		_expect(sd.get_meta(&"no_ghost", false), "hovel settle is no_ghost")
	_expect(BuildSettle.dust_color(Color(0.9, 0.92, 0.95), Color(0.4, 0.45, 0.6)).v <= BuildSettle.DUST_MAX_V + 0.001,
		"a pale dust colour is capped")


## A stand-in building: `team`, `is_constructed()`, `model()` (= `m`), `target_radius()` (BuildSettle.building_of and
## GroundDetail.refresh_clears only use these).
func _stub_building(team: int, model: Node3D, at: Vector3) -> Node3D:
	var gs := GDScript.new()
	gs.source_code = "extends Node3D\nvar team: int = 0\nvar m: Node3D\nfunc is_constructed() -> bool:\n\treturn true\n" \
		+ "func model() -> Node3D:\n\treturn m\nfunc target_radius() -> float:\n\treturn 3.0\n"
	gs.reload()
	var b := Node3D.new()
	b.set_script(gs)
	b.set(&"team", team)
	b.position = at
	root.add_child(b)
	if model:
		b.set(&"m", model)
		if model.get_parent() == null:
			b.add_child(model)
	return b


## Frame 3: a fog stand-in that sees nothing for the local team 0, an enemy (team 1) and an own Gloom Hall under it.
## (VfxFog caches "no fog" for the frame, so the check runs on the next frame.)
func _setup_fog_settle() -> void:
	var fs := GDScript.new()
	fs.source_code = "extends Node\nvar enabled: bool = true\nvar local_team: int = 0\n" \
		+ "func is_visible(_team: int, _pos: Vector3) -> bool:\n\treturn false\n"
	fs.reload()
	_fog = Node.new()
	_fog.set_script(fs)
	root.add_child(_fog)
	_fog.add_to_group(&"fog")
	_fog_enemy = _stub_building(1, (load(HALLS["shadow"]) as PackedScene).instantiate() as Node3D, Vector3(0, 0, 80))
	_fog_own = _stub_building(0, (load(HALLS["shadow"]) as PackedScene).instantiate() as Node3D, Vector3(20, 0, 80))


## Frame 4: completing a site (0.5 -> 1) fires the settle only where the local team may see it.
func _check_fog_settle() -> void:
	for pair: Array in [[_fog_enemy, false, "an enemy building under fog"], [_fog_own, true, "an own building under fog"]]:
		var model := (pair[0] as Node).get(&"m") as Node
		var dust := model.get(&"_build_dust") as GPUParticles3D
		var glint := model.get(&"_build_flash") as GPUParticles3D
		_expect(BuildSettle.building_of(model) == pair[0], "BuildSettle finds the building of %s" % pair[2])
		model.call(&"set_construction_progress", 0.5)
		dust.emitting = false
		glint.emitting = false
		model.call(&"set_construction_progress", 1.0)
		_expect(dust.emitting == pair[1] and glint.emitting == pair[1],
			"%s: settle %s (dust %s, glint %s)" % [pair[2], "fires" if pair[1] else "stays hidden", dust.emitting, glint.emitting])
	_fog.free()   # later frames (the forges' own completion) run without fog
	_fog_enemy.queue_free()
	_fog_own.queue_free()


func _check_grass_clear() -> void:
	var hall := _halls["shadow"] as Node3D
	ShadowDress.attach_at(hall, {"radius": 6.3, "inner": 3.3, "top": 10.0}, 2)
	_expect(is_equal_approx(float(hall.get_meta(&"_grass_clear_radius", 0.0)), 6.3 * ShadowDress.GRASS_CLEAR_K),
		"ShadowDress marks the grass-free radius on its model")
	var stub_src := "extends Node3D\nvar m: Node3D\nfunc model() -> Node3D:\n\treturn m\n"
	var gs := GDScript.new()
	gs.source_code = stub_src
	gs.reload()
	var stub := Node3D.new()
	stub.set_script(gs)
	root.add_child(stub)
	stub.set(&"m", hall)
	var r: float = GroundDetail.model_clear_radius(stub)
	_expect(absf(r - 6.3 * ShadowDress.GRASS_CLEAR_K) < 0.01, "GroundDetail reads the model's clear radius (%.2f)" % r)
	stub.set(&"m", _halls["fire"])
	_expect(GroundDetail.model_clear_radius(stub) == 0.0, "no clear radius without dead ground")
	stub.queue_free()
	# Public path: refresh_clears round a building whose model has dead ground -> one circle, the dead-ground radius
	# (bigger than target_radius() + 0.3). Headless GroundDetail builds nothing (no ground, no rings): refresh only.
	var lone := (load(HALLS["shadow"]) as PackedScene).instantiate() as Node3D
	var b := _stub_building(1, lone, Vector3(300, 0, 300))
	ShadowDress.attach_at(lone, {"radius": 6.3, "inner": 3.3, "top": 10.0}, 2)
	b.add_to_group(&"buildings")
	var gd := GroundDetail.new()
	root.add_child(gd)
	gd.refresh_clears(Vector3(300, 0, 300), 30.0)
	var cl: Array[Vector4] = gd.clear_list()
	_expect(cl.size() == 1, "refresh_clears: one circle round the Shadow building (got %d)" % cl.size())
	if cl.size() == 1:
		_expect(absf(cl[0].z - 6.3 * ShadowDress.GRASS_CLEAR_K) < 0.01 and cl[0].z > 3.3,
			"refresh_clears: the dead-ground radius %.2f wins over target_radius + 0.3 (got %.2f)" % [6.3 * ShadowDress.GRASS_CLEAR_K, cl[0].z])
		_expect(absf(cl[0].x - 300.0) < 0.01 and absf(cl[0].y - 300.0) < 0.01, "refresh_clears: circle at the building")
	b.remove_from_group(&"buildings")
	gd.queue_free()
	b.queue_free()


func _vertex_count(n: Node) -> int:
	var total := 0
	for c: Node in n.find_children("*", "MeshInstance3D", true, false):
		var mi := c as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree():
			continue
		for s: int in mi.mesh.get_surface_count():
			total += (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	return total


func _expect(cond: bool, what: String) -> void:
	if not cond:
		_errors.append(what)
