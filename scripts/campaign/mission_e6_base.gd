class_name MissionE6Base
extends MissionE5Base
## Episode 6 "The Lake and the Seed" (origins) shared rules (docs/design/mission-e6-01.md section 0, ER1-ER8), used by
## MissionE6_01..MissionE6_04 (each still a MissionBase through MissionE5Base: lines by id, local unit types saved by id,
## the prop scatter, ground discs, light tints, building caps):
## - ER3 flags only (CampaignState.MISSION_REWARDS "save_items": false), essence 400, empty slots, no artifact;
## - ER4 tier 1 (e6m4: Stronghold), no helpers / champions / trade / map-fill;
## - ER6 the Hollow's Ruin Wardens and the Warden Breaker (`warden_breaker`, x2 vs buildings and scripted targets) plus
##   its named elite, every enemy mission-spawned;
## - the PLAYER scripted target (`E6Target`: the Heartfrost of e6m1 / e6m2, the Throne seal of e6m4): only ENEMY damage,
##   regen while a mission rule says so;
## - seasons / nights (`set_cold`): PLAYER sight x mult (FogOfWar.sight_scale) and the MissionBlizzard look, ENEMY speed
##   modifier `season:drift`.

const BREAKER_ID := "warden_breaker"
const WARDEN_ID := "hollow_warden"      ## the Ruin Warden as a Host unit (pop 2 = floe weight 2, aggro 9)
const BREAKER_X2 := 2.0
const DRIFT := &"season:drift"
const E6_ESSENCE := 400

## The ice / seal target of the episode: a Heartfrost that only ENEMY units damage (Breakers x2 through the mission's
## hook), regenerating `regen_per_second` while `regen_ok` (Callable -> bool) says so. `look` false hides the ice
## prisms (the e6m4 seal draws its own stone).
class E6Target:
	extends Heartfrost
	var regen_ok: Callable
	var look := true
	var display_name := "The Heartfrost"

	func _ready() -> void:
		super()
		team = Unit.Team.PLAYER
		if not look:
			for c in get_children():
				if c is Node3D and not c is CollisionShape3D and c != _bar_root:
					(c as Node3D).visible = false

	func accepts_damage_from(attacker: Node3D) -> bool:
		if attacker == null or not is_instance_valid(attacker):
			return false
		var t: Variant = attacker.get(&"team")
		return t != null and int(t) == Unit.Team.ENEMY

	func _physics_process(delta: float) -> void:
		if is_melted:
			return
		since_fire_damage += delta
		if hp < max_hp and (not regen_ok.is_valid() or bool(regen_ok.call())):
			hp = minf(max_hp, hp + regen_per_second * delta)
			_update_look()

	func ratio() -> float:
		return clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)

	## Loses `amount` with no attacker (a mission rule: "the Hollow counts the dead").
	func drain(amount: float) -> void:
		if not is_alive() or amount <= 0.0:
			return
		hp = maxf(0.0, hp - amount)
		_update_look()
		if hp <= 0.0:
			is_melted = true
			melted.emit(self)


var blizzard: MissionBlizzard           ## Read only (null until the first cold phase).
var cold := false                       ## Read only: a winter / night is on.

var _cold_sight := 0.6
var _cold_drift := -0.4
var _scales := {}                       # local type id -> model scale (Breakers x1.5, elites x1.8)


func _init() -> void:
	super()


## Snow theme (M9.V1, Mission02's ground recolour): set in the subclass's _init.
var snow_theme := false


func _use_map_dressing() -> bool:
	return not snow_theme


func _build_ground() -> void:
	super()
	if not snow_theme or nav_region == null:
		return
	var snow := {
		&"grass_dark": Color(0.80, 0.84, 0.90), &"grass_light": Color(0.93, 0.95, 0.98),
		&"grass_warm": Color(0.88, 0.89, 0.92), &"grass_cool": Color(0.78, 0.83, 0.92),
		&"grass_dry": Color(0.86, 0.87, 0.90), &"clover_color": Color(0.84, 0.87, 0.93),
		&"dirt_color": Color(0.70, 0.72, 0.76), &"dirt_dark": Color(0.58, 0.60, 0.66),
		&"pebble_color": Color(0.62, 0.64, 0.70), &"paving_color": Color(0.74, 0.76, 0.80),
		&"canopy_dark": Color(0.16, 0.22, 0.24), &"canopy_light": Color(0.62, 0.68, 0.74),
		&"rock_color": Color(0.52, 0.55, 0.60), &"haze_color": Color(0.80, 0.86, 0.94),
		&"tuft_density": 0.0, &"flower_amount": 0.0, &"groove_energy": 0.0,
	}
	for body in nav_region.get_children():
		for c in body.get_children():
			var mi := c as MeshInstance3D
			if mi == null:
				continue
			var mat := mi.material_override as ShaderMaterial
			if mat:
				for k: StringName in snow:
					mat.set_shader_parameter(k, snow[k])
			elif mi.material_override is StandardMaterial3D:
				(mi.material_override as StandardMaterial3D).albedo_texture = null
				(mi.material_override as StandardMaterial3D).albedo_color = Color(0.88, 0.91, 0.96)


## ER3 / ER4: MissionE5Base's tier-1 switches, then the episode's essence (400, trickle and kills on).
static func e6_config(c: MissionConfig, max_tier := 1) -> void:
	MissionE5Base.e5_config(c)
	c.max_tier = max_tier
	c.start_essence = E6_ESSENCE
	c.essence_trickle = true
	c.kill_essence = true


## ER6: the Warden Breaker and its named elite (`elite_id` / `elite_name`, 2 400 HP x1.8) from the Ruin Warden.
func make_breakers(elite_id: String, elite_name: String, elite_hp: float) -> void:
	local_unit("ruin_warden", BREAKER_ID, "Warden Breaker", {"max_hp": 900.0, "armor": 15.0, "attack_damage": 30.0,
			"attack_range": 1.8, "attack_cooldown": 1.4, "move_speed": 3.6, "aggro_range": 9.0, "pop": 4, "kill_xp": 150,
			"cost": 330, "commandable": false})
	_scales[BREAKER_ID] = 1.5
	local_unit("ruin_warden", WARDEN_ID, "Ruin Warden", {"aggro_range": 9.0, "commandable": false, "cost": 120,
			"pop": 2})
	if elite_id != "":
		local_unit("ruin_warden", elite_id, elite_name, {"max_hp": elite_hp, "armor": 15.0, "attack_damage": 40.0,
				"attack_range": 2.0, "attack_cooldown": 1.4, "move_speed": 3.6, "aggro_range": 9.0, "pop": 4,
				"kill_xp": 300, "cost": 800, "commandable": false})
		_scales[elite_id] = 1.8


## True for a Breaker or the named elite (x2 vs buildings and scripted targets; sinks / never pulled).
func is_breaker(u: Variant) -> bool:
	var unit := u as Unit
	return unit != null and is_instance_valid(unit) and unit.unit_type != null and int(unit.unit_type.pop) >= 4 \
			and int(unit.team) == Unit.Team.ENEMY


## A spawned enemy: scripted, the cold's drift if a winter is on, the Breakers' x2 hook.
func arm_enemy(u: Unit) -> void:
	if u == null:
		return
	mark_scripted(u)
	if cold:
		u.add_modifier(DRIFT, {"move_speed": _cold_drift})
	if is_breaker(u) and not u.attack_landed.is_connected(_on_breaker_hit.bind(u)):
		u.attack_landed.connect(_on_breaker_hit.bind(u))
	var sc := float(_scales.get(String(u.unit_type.id), 1.0)) if u.unit_type else 1.0
	var m := u.get_model() if absf(sc - 1.0) > 0.01 else null
	if m:
		m.scale = Vector3.ONE * sc


func _on_breaker_hit(target: Node3D, amount: float, u: Unit) -> void:
	if target == null or not is_instance_valid(target) or not is_instance_valid(u):
		return
	if target is Building or target.is_in_group(SCRIPTED_GROUP) and not target is Unit:
		if target.has_method(&"take_damage"):
			target.call(&"take_damage", amount * (BREAKER_X2 - 1.0), u)


## Spawns `rows` ([type_id, normal count]) as a wave at `at` (scaled, a spiral), each armed, ordered `mode` at `to`.
func wave(rows: Array, at: Vector3, mode: StringName, to: Vector3) -> Array:
	var out := spawn_rows(rows, at, 0.0, Unit.Team.ENEMY, false, true)
	for v: Variant in out:
		var u := v as Unit
		arm_enemy(u)
		order_wave(u, mode, to)
	return out


## The scripted target at `pos` under the nav region (an obstacle before the bake).
func add_target(pos: Vector3, hp: float, regen: float, regen_ok: Callable, label: String, look := true) -> E6Target:
	var t := E6Target.new()
	t.name = label.replace(" ", "")
	t.display_name = label
	t.look = look
	t.regen_ok = regen_ok
	t.setup(hp, regen)
	nav_region.add_child(t)
	t.position = pos
	return t


## Winter / night on or off: PLAYER sight x `sight` (floor 5 m), the snow look (`snow`), ENEMY move speed + `drift`.
func set_cold(on: bool, sight: float, drift: float, snow := true) -> void:
	cold = on
	_cold_sight = sight
	_cold_drift = drift
	if snow and blizzard == null and not _SIM.enabled:
		blizzard = MissionBlizzard.new()
		blizzard.name = "Blizzard"
		blizzard.follow = camera_rig
		add_child(blizzard)
	if blizzard:
		blizzard.sight_mult = sight
		blizzard.set_blowing(on and snow)
	if fog:
		fog.sight_scale[Unit.Team.PLAYER] = sight if on else 1.0
		if fog.sight_scale.size() > Unit.Team.ENEMY:
			fog.sight_scale[Unit.Team.ENEMY] = 1.0
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or int(u.team) != Unit.Team.ENEMY:
			continue
		if on:
			u.add_modifier(DRIFT, {"move_speed": drift})
		else:
			u.remove_modifier(DRIFT)


## Every ENEMY unit left crumbles (no XP): the end of a winter / the victory.
func crumble_enemies() -> void:
	clear_waves()
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u and u.is_alive() and int(u.team) == Unit.Team.ENEMY:
			u.leave_map()


## The living ENEMY units within `r` of `at`.
func enemies_near(at: Vector3, r: float) -> int:
	var n := 0
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u and u.is_alive() and int(u.team) == Unit.Team.ENEMY and not is_dormant(u) and _flat(u.global_position, at) <= r:
			n += 1
	return n


## A Warden Gate spawner (team ENEMY, `hp`): `spawner` (gate) -> void runs every `every` s once open (0 = only by the
## mission). Under the nav region before the bake.
func add_warden_gate(id: StringName, pos: Vector3, face: Vector3, hp: float, every: float, spawner: Callable) -> WardenGate:
	var g := WardenGate.new()
	g.gate_id = id
	g.name = "WardenGate_%s" % String(id)
	g.face_toward = face
	g.position = pos
	g.setup(hp, every if every > 0.0 else 99999.0)
	g.armor = 10.0
	g.team = Unit.Team.ENEMY
	g.spawner = spawner
	nav_region.add_child(g)
	g.open()   # attackable from the start (a gate without a spawner spawns nothing by itself)
	return g


## An invisible, sleeping anchor unit at `at` (a story helper escorts it: "hold the mere", "keeper of the well"; the
## e4m3 pattern). Move it to move the helper's post.
func story_anchor(at: Vector3) -> Unit:
	var a := make_unit("rimeling")
	_spawn(a, Unit.Team.NEUTRAL, at)   # neutral and asleep: no pop, no target, no aggro
	set_dormant(a, true)
	a.visible = false
	a.collision_layer = 0
	a.collision_mask = 0
	a.process_mode = Node.PROCESS_MODE_DISABLED
	mark_scripted(a)
	return a


## The young / prime looks (F2 rule of Episode 5: set_look when the model has it, else a scale).
static func set_story_look(u: Unit, look: StringName, scale := 1.0) -> void:
	MissionE5Base.young_look(u, look, scale)


## A Helper (t3-helpers.md) as a story unit: `helper_id` at `level`, team PLAYER, not commandable, bonded to `anchor`
## with `stance` (the helper's own numbers at that level). Null when the helper type is missing.
func story_helper(helper_id: StringName, label: String, at: Vector3, level: int, anchor: Unit, stance: StringName) -> Helper:
	var ht := HelperType.find(helper_id)
	if ht == null:
		return null
	var h := Helper.new()
	h.apply_helper_type(ht, level)
	h.name = label
	_spawn(h, Unit.Team.PLAYER, at)
	h.set_level(level)
	if anchor:
		h.bond_to(anchor)
	h.set_stance(stance)
	mark_scripted(h)
	return h
