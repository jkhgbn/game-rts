extends SceneTree
## Task G-B Shadow (docs/art/gb_shadow_buildings.md): the Shadow building models after the graphics pass.
## Run: godot --headless --path . -s tests/test_gb_shadow.gd --fixed-fps 60 --quit-after 1500
## Checks: every Shadow model instantiates and takes its hooks; at Low (every headless run) no ShadowDress is added
## (Low = the cost before G1); ShadowDress.attach_at builds the right pieces per tier and follows sync / set_glow;
## the Dusk Keep's tier looks: set_tier before _ready is cached, tier 2 / 3 parts, the upgrade rig, tier-up, a site
## hides the tier parts, the collapse hides them and still emits destroyed_finished.

const TASK_ID := "gb_shadow"
const SCENES: Array[String] = [
	"res://art/buildings/dusk_keep.tscn", "res://art/buildings/shadow_hall.tscn", "res://art/buildings/hovel.tscn",
	"res://art/buildings/shadow_tower.tscn", "res://art/buildings/stables/shadow/shadow_stables.tscn",
	"res://art/buildings/market/shadow/market_shadow.tscn", "res://art/buildings/lair/shadow/dread_paddock.tscn",
]
const KEEP := "res://art/buildings/dusk_keep.tscn"

var frame := 0
var _models: Array[Node3D] = []
var _k: Node3D          # keep: tiers set after _ready
var _k_early: Node3D    # keep: tier 3 set before _ready
var _k_site: Node3D     # keep: tier 2 then a site
var _dress_host: Node3D
var _dresses: Array = []
var _finished: int = 0
var _errors: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	var world := Node3D.new()
	world.name = "World"
	root.add_child(world)
	for i: int in SCENES.size():
		var ps := load(SCENES[i]) as PackedScene
		if ps == null:
			_errors.append("cannot load " + SCENES[i])
			continue
		var m := ps.instantiate() as Node3D
		m.position = Vector3(i * 14.0, 0, 0)
		world.add_child(m)
		m.connect(&"destroyed_finished", func() -> void: _finished += 1)
		_models.append(m)
	var kp := load(KEEP) as PackedScene
	_k = kp.instantiate() as Node3D
	_k.position = Vector3(0, 0, 20)
	world.add_child(_k)
	_k_early = kp.instantiate() as Node3D
	_k_early.position = Vector3(14, 0, 20)
	_k_early.call(&"set_tier", 3)
	_k_early.call(&"set_upgrading", true)
	world.add_child(_k_early)
	_k_site = kp.instantiate() as Node3D
	_k_site.position = Vector3(28, 0, 20)
	world.add_child(_k_site)
	_dress_host = Node3D.new()
	_dress_host.position = Vector3(0, 0, -20)
	world.add_child(_dress_host)


func _process(_delta: float) -> bool:
	frame += 1
	match frame:
		3:
			_check_low()
			_check_dress()
			_check_keep_tiers()
			for m: Node3D in _models:
				m.call(&"set_construction_progress", 0.4)
		6:
			for m: Node3D in _models:
				m.call(&"set_construction_progress", 1.0)
				m.call(&"set_health_ratio", 0.3)
				m.call(&"set_selected", true)
				m.call(&"set_team_color", Color(0.85, 0.2, 0.2))
				if m.has_method(&"play_training_pulse"):
					m.call(&"play_training_pulse")
				if m.has_method(&"play_shot"):
					m.call(&"play_shot")
		10:
			for m: Node3D in _models:
				m.call(&"set_health_ratio", 1.0)
				m.call(&"set_selected", false)
		12:
			for m: Node3D in _models:
				m.call(&"play_destroyed")
			_k.call(&"play_destroyed")
		60:
			# Mid-collapse the keep's tier parts are gone.
			_check(not _vis(_k, "Model/Tier2") and not _vis(_k, "Model/Tier3"), "keep tier parts still shown mid-collapse")
		400:
			_check(_finished == _models.size(), "destroyed_finished %d / %d" % [_finished, _models.size()])
			if _errors.is_empty():
				print("PASS %s" % TASK_ID)
			else:
				print("FAIL %s: %s" % [TASK_ID, "; ".join(_errors)])
			return true
	return false


func _check(cond: bool, msg: String) -> void:
	if not cond:
		_errors.append(msg)


func _vis(m: Node, path: String) -> bool:
	var n := m.get_node_or_null(path) as Node3D
	return n != null and n.is_visible_in_tree()


## Low (headless): nothing new is added round any Shadow model.
func _check_low() -> void:
	_check(ShadowDress.quality() == 0, "headless run should be Low")
	for m: Node3D in _models + [_k, _k_early, _k_site]:
		_check(m.find_child("ShadowDress", true, false) == null, "%s has a ShadowDress at Low" % m.scene_file_path)


func _check_dress() -> void:
	var opts := {"radius": 6.0, "inner": 3.0, "top": 8.0, "embers": [Vector3(1, 3, 0), Vector3(-1, 4, 0)],
		"light": Vector3(0, 3, 0), "seed": 1.5}
	_check(ShadowDress.attach_at(_dress_host, opts, 0) == null, "attach_at Low must add nothing")
	for q: int in [1, 2, 3]:
		var d: ShadowDress = ShadowDress.attach_at(_dress_host, opts, q)
		_check(d != null and d.get_node_or_null(^"DeadGround") != null, "tier %d: no dead ground" % q)
		if d == null:
			continue
		_dresses.append(d)
		_check(bool(d.get_meta(&"no_ghost", false)), "tier %d: ShadowDress lacks the no_ghost meta (fog ghosts would copy it)" % q)
		var mist := d.get_node_or_null(^"ShadowMist") as GPUParticles3D
		var wisps := d.get_node_or_null(^"SoulWisps") as GPUParticles3D
		var light := d.get_node_or_null(^"SoulLight") as OmniLight3D
		_check((mist != null) == (q >= 2), "tier %d: mist %s" % [q, mist != null])
		_check((wisps != null) == (q >= 2), "tier %d: wisps %s" % [q, wisps != null])
		_check((light != null) == (q >= 3), "tier %d: light %s" % [q, light != null])
		if q >= 2:
			var embers: int = 0
			for c: Node in d.get_children():
				if String(c.name).begins_with("SoulEmbers"):
					embers += 1
			_check(embers == 2, "tier %d: %d ember emitters (want 2)" % [q, embers])
			d.sync(0.5, 1.0, false)
			_check(not mist.emitting and not wisps.emitting, "site: mist / wisps should be off")
			d.sync(1.0, 1.0, false)
			_check(mist.emitting and wisps.emitting, "built: mist / wisps should be on")
			var e1 := d.get_node(^"SoulEmbers1") as GPUParticles3D
			_check(not e1.emitting, "healthy: embers should be off")
			d.sync(1.0, 0.3, false)
			_check(e1.emitting, "hurt: embers should be on")
			d.sync(1.0, 0.3, true)
			_check(not mist.emitting, "wreck: mist should be off")
			d.set_glow(Color(0.2, 0.5, 1.0))
		if light:
			_check(not light.shadow_enabled, "the soul light must not cast shadows")


func _check_keep_tiers() -> void:
	for meth: StringName in [&"set_tier", &"set_upgrading", &"play_tier_up"]:
		_check(_k.has_method(meth), "dusk keep lacks %s" % meth)
	_check(not _vis(_k, "Model/Tier2") and not _vis(_k, "Model/Tier3"), "tier 1 keep shows tier parts")
	_check(not _vis(_k, "Model/UpgradeRig"), "upgrade rig shown on an idle keep")
	_k.call(&"set_upgrading", true)
	_check(_vis(_k, "Model/UpgradeRig"), "upgrade rig hidden while upgrading")
	_k.call(&"set_tier", 2)
	_k.call(&"play_tier_up")
	_k.call(&"set_upgrading", false)
	_check(not _vis(_k, "Model/UpgradeRig"), "upgrade rig still shown after the upgrade")
	_check(_vis(_k, "Model/Tier2") and not _vis(_k, "Model/Tier3"), "tier 2 look wrong")
	_check(_vis(_k_early, "Model/Tier2") and _vis(_k_early, "Model/Tier3"), "tier 3 set before _ready not applied")
	_check(_vis(_k_early, "Model/UpgradeRig"), "upgrading set before _ready not applied")
	_k_site.call(&"set_tier", 2)
	_k_site.call(&"set_construction_progress", 0.5)
	_check(not _vis(_k_site, "Model/Tier2"), "a keep site shows its tier parts")
	_k_site.call(&"set_construction_progress", 1.0)
	_check(_vis(_k_site, "Model/Tier2"), "tier parts missing once the site is built")
	_k.call(&"set_tier", 3)
	_check(_vis(_k, "Model/Tier3"), "tier 3 look missing")
	_k.call(&"set_tier", 1)
	_check(not _vis(_k, "Model/Tier2"), "back to tier 1 still shows tier 2")
	_k.call(&"set_tier", 3)
