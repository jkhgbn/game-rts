class_name Building
extends StaticBody3D
## Base of every building (keep, barracks, hearth / hovel, tower), finished or under construction.
## Group "buildings", collision layers 1 (navmesh obstacle: add it under the NavigationRegion3D, then
## rebake) + 2 (click raycasts). Stats come from `building_type` (data/buildings/*.tres).
## Build them with BuildGrid (main.build_grid): place() makes a construction site, spawn_complete()
## a finished building. Numbers: docs/design/buildings.md.
##
## Construction: workers call add_builder / remove_builder (Worker.command_build does it). Progress
## per second = build_speed() / build_time; build_speed = 1.0 / 1.5 / 2.0 for 1 / 2 / 3+ workers.
## hp rises from 10 % to 100 % of max_hp with progress; damage is subtracted normally.
##
## Trade (market-trade.md 3.2): max_hp = building_type.max_hp x the team GoldBank's building_hp_mult()
## (1.15 with the Masons' Charter), read at creation; the bank calls set_hp_mult on living buildings.

signal destroyed(building: Building)            ## Destroyed, or a site cancelled (see `cancelled`).
signal construction_finished(building: Building)
signal damaged(amount: float, attacker: Node3D)

const START_HP_RATIO := 0.1
const BUILD_SPEED_EXTRA := 0.5       ## Per extra worker.
const MAX_COUNTED_BUILDERS := 3
const CANCEL_REFUND := 0.75
const SITE_ALPHA := 0.35
const FREE_DELAY := 5.0              ## Seconds between destruction and queue_free (rubble shrinks meanwhile).
## BuildingType.idle_regen_pct (Nature "Verdant"): starts this long after the last damage, completed
## buildings only, applied in steps of IDLE_REGEN_TICK s.
const IDLE_REGEN_DELAY := 10.0
const IDLE_REGEN_TICK := 0.5
const AURA_TICK := 0.25              ## BuildingType.aura_radius: refresh rate (Unit.AURA_LINGER keeps it 1 s).

@export var building_type: BuildingType
@export var team: Unit.Team = Unit.Team.PLAYER
## Kingdom colour; alpha 0 = take building_type.color.
@export var team_color := Color(0.0, 0.0, 0.0, 0.0)
## Point the building "faces" (spawn and rally corners are on that side). The map centre by default.
@export var front_toward := Vector3.ZERO
## Drop a real model here later to replace the placeholder shapes (defaults to building_type's).
@export var model_scene: PackedScene

var max_hp := 500.0
var hp := 500.0
var selected := false: set = set_selected
var cancelled := false               ## Read only: true when the site was cancelled (not destroyed).
## Read only: the last valid attacker (the killing blow once destroyed). Wizard XP reads it.
var killer: Node3D = null

var _progress := 1.0                 # construction progress 0-1; 1 = finished
var _dead := false
var _builders: Array[Node] = []
var _bonus_applied := false
var _economy: Economy
var _visual: Node3D
var _model: Node3D                   # the model_scene instance (null = placeholder shapes)
var _mats: Array[StandardMaterial3D] = []
var _look_is_site := false
var _outline: Node3D
var _ring: MeshInstance3D
var _hp_bar: MeshInstance3D
var _hp_mat: ShaderMaterial
var _since_damage := 1000.0          # seconds since the last take_damage (idle regen)
var _regen_left := IDLE_REGEN_TICK
var _aura_left := 0.0
var _hp_mult := 1.0                  # max HP factor from the team's GoldBank (Masons' Charter)

static var _hp_shader: Shader


## Living buildings of `for_team_id` (finished and under construction).
static func for_team(for_team_id: int) -> Array[Building]:
	var out: Array[Building] = []
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return out
	for node in tree.get_nodes_in_group("buildings"):
		var b := node as Building
		if b and b.team == for_team_id and b.is_alive():
			out.append(b)
	return out


## Living buildings of `for_team_id` that count for the 1v1 defeat rule (walls don't:
## BuildingType.counts_for_defeat). Empty = that side has lost.
static func defeat_relevant(for_team_id: int) -> Array[Building]:
	var out: Array[Building] = []
	for b in for_team(for_team_id):
		if b.counts_for_defeat():
			out.append(b)
	return out


## False for walls (their BuildingType.counts_for_defeat): a side with only walls left loses.
func counts_for_defeat() -> bool:
	return building_type == null or building_type.counts_for_defeat


## The drop-off building (is_drop_off(): completed keep or barracks) of `for_team_id` whose
## drop_off_point() is closest to `pos`, or null.
static func nearest_drop_off(for_team_id: int, pos: Vector3) -> Building:
	var best: Building = null
	var best_d := INF
	for b in for_team(for_team_id):
		if not b.is_drop_off():
			continue
		var p: Vector3 = b.call(&"drop_off_point")
		var d := Vector2(p.x - pos.x, p.z - pos.z).length_squared()
		if d < best_d:
			best_d = d
			best = b
	return best


## How many living buildings of type `type_id` the team has (finished or under construction).
static func count_of(type_id: StringName, for_team_id: int) -> int:
	var n := 0
	for b in for_team(for_team_id):
		if b.building_type and b.building_type.id == type_id:
			n += 1
	return n


## Turns this new building into a construction site (progress 0, hp 10 %). BuildGrid calls it
## before adding the building to the scene.
func make_site() -> void:
	_progress = 0.0
	if is_inside_tree():
		hp = max_hp * START_HP_RATIO
		_remove_pop_bonus()
		_update_look()


func _ready() -> void:
	if building_type == null:
		building_type = _default_type()
	if building_type:
		max_hp = building_type.max_hp
		# Masons' Charter (market-trade.md 3.2): a building created after the purchase starts at x 1.15.
		_hp_mult = _team_hp_mult()
		if _hp_mult != 1.0:
			max_hp = roundf(max_hp * _hp_mult)
		if model_scene == null:   # model_scene, else model_path once the file exists (null = placeholder shapes)
			model_scene = building_type.get_model_scene()
		if team_color.a == 0.0:
			team_color = building_type.color
	hp = max_hp * (START_HP_RATIO + (1.0 - START_HP_RATIO) * _progress)
	add_to_group("buildings")
	collision_layer = 1 | 2
	collision_mask = 0
	var body := _body_size()
	var shape := BoxShape3D.new()
	shape.size = body
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position.y = body.y * 0.5
	add_child(col)
	_build_visual()
	_build_outline()
	_build_ring()
	_build_hp_bar()
	_update_look()
	if is_constructed():
		_apply_pop_bonus()


# ---------------------------------------------------------------- public

func is_alive() -> bool:
	return not _dead


func is_constructed() -> bool:
	return _progress >= 1.0


## True if workers may deliver crystals here now (completed keeps and barracks; they also have
## drop_off_point()). Plain buildings never are.
func is_drop_off() -> bool:
	return false


## 0-1. 1 for a finished building.
func construction_progress() -> float:
	return _progress


## How far from our centre an attacker may stand and still reach us (on top of its own range).
func target_radius() -> float:
	var body := _body_size()
	return minf(body.x, body.z) * 0.5


func take_damage(amount: float, attacker: Node3D = null) -> void:
	if _dead or amount <= 0.0:
		return
	hp -= amount
	_since_damage = 0.0
	_regen_left = IDLE_REGEN_TICK
	if attacker != null and is_instance_valid(attacker):
		killer = attacker
	damaged.emit(amount, attacker)
	_update_hp_bar()
	if hp <= 0.0:
		_destroy()
	else:
		_call_model(&"set_health_ratio", [hp / maxf(max_hp, 1.0)])


## Restores up to `amount` HP (not above max_hp; nothing once destroyed).
func heal(amount: float) -> void:
	if _dead or amount <= 0.0 or hp >= max_hp:
		return
	hp = minf(max_hp, hp + amount)
	_update_hp_bar()
	_call_model(&"set_health_ratio", [hp / maxf(max_hp, 1.0)])


## The max HP factor in use (1.0, or GoldBank.building_hp_mult() = 1.15 with the Masons' Charter).
func hp_mult() -> float:
	return _hp_mult


## Rescales max_hp to (max_hp / old factor) x `mult` (rounded). GoldBank calls it when the Masons' Charter is
## bought. A finished building heals the HP gained (a full 2500 keep -> 2875 / 2875; 2000 / 2500 -> 2375 / 2875);
## a construction site keeps its HP ratio, so it still finishes at the new max. Never kills; no-op once destroyed.
func set_hp_mult(mult: float) -> void:
	if _dead or mult <= 0.0 or is_equal_approx(mult, _hp_mult):
		return
	var base := max_hp / _hp_mult
	var new_max := roundf(base * mult)
	var old_max := max_hp
	_hp_mult = mult
	max_hp = new_max
	if is_constructed():
		hp = clampf(hp + (new_max - old_max), minf(hp, 1.0), max_hp)
	else:
		hp = minf(max_hp, hp * new_max / maxf(old_max, 1.0))
	_update_hp_bar()
	_call_model(&"set_health_ratio", [hp / maxf(max_hp, 1.0)])


## The Masons' Charter factor of this building's team: GoldBank.building_hp_mult(), 1.0 without a bank
## (trade off). Found through the group, so this file never needs the GoldBank class at compile time.
func _team_hp_mult() -> float:
	if not is_inside_tree():
		return 1.0
	for bank in get_tree().get_nodes_in_group(&"gold_banks"):
		if is_instance_valid(bank) and int(bank.get(&"team")) == int(team) and bank.has_method(&"building_hp_mult"):
			return float(bank.call(&"building_hp_mult"))
	return 1.0


func set_selected(value: bool) -> void:
	selected = value and not _dead
	if _ring:
		_ring.visible = selected
	_update_hp_bar()
	_call_model(&"set_selected", [selected])
	_on_selected_changed()


## A fog-of-war ghost (fog-of-war.md): a grey, see-through copy of how the building looks now,
## meshes only (no collision, no script). Not in the tree yet: the caller adds it and sets its
## global_transform to this building's.
func make_ghost(material: Material) -> Node3D:
	var ghost := Node3D.new()
	ghost.name = "Ghost_%s" % name
	if _visual:
		_copy_meshes(_visual, _visual.transform, ghost, material)
	return ghost


## A node with meta `no_ghost` == true (ground decals, dressing) is skipped with its whole subtree.
func _copy_meshes(node: Node, xf: Transform3D, into: Node3D, material: Material) -> void:
	if node.get_meta(&"no_ghost", false) == true:
		return
	var mi := node as MeshInstance3D
	if mi and mi.mesh and mi.visible:
		var copy := MeshInstance3D.new()
		copy.mesh = mi.mesh
		copy.transform = xf
		copy.material_override = material
		copy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		into.add_child(copy)
	for child in node.get_children():
		var n3 := child as Node3D
		if n3 and n3.visible:
			_copy_meshes(n3, xf * n3.transform, into, material)


## Construction sites only: refunds 75 % of the cost (rounded down), removes the site.
func cancel_construction() -> void:
	if _dead or is_constructed():
		return
	cancelled = true
	var eco := _get_economy()
	if eco and building_type:
		eco.add(floori(building_type.cost * CANCEL_REFUND))
	_destroy()


## Current build speed (0 when nobody builds): 1.0, +0.5 per extra worker, max 3 counted.
## Frozen builders (can_act() false) stay registered but don't count: the site pauses for them.
func build_speed() -> float:
	var n := mini(active_builder_count(), MAX_COUNTED_BUILDERS)
	return 0.0 if n == 0 else 1.0 + BUILD_SPEED_EXTRA * float(n - 1)


## Workers registered on the site (including those waiting beyond the 3 counted).
func builder_count() -> int:
	_prune_builders()
	return _builders.size()


## Registered workers that are building right now (not frozen: Unit.can_act()).
func active_builder_count() -> int:
	_prune_builders()
	var n := 0
	for w in _builders:
		if not w.has_method(&"can_act") or bool(w.call(&"can_act")):
			n += 1
	return n


## Seconds since the building last took damage (large if never).
func seconds_since_damage() -> float:
	return _since_damage


## Workers call this when they arrive at the site and start building.
func add_builder(worker: Node) -> void:
	if worker != null and not _builders.has(worker) and not is_constructed() and not _dead:
		_builders.append(worker)


func remove_builder(worker: Node) -> void:
	_builders.erase(worker)


## The footprint in world x / z (Rect2 position = min corner).
func footprint_rect() -> Rect2:
	var size := building_type.size_m() if building_type else Vector2(2.0, 2.0)
	return Rect2(Vector2(global_position.x, global_position.z) - size * 0.5, size)


## Flat distance from `pos` to the footprint (0 inside it).
func distance_to_footprint(pos: Vector3) -> float:
	var r := footprint_rect()
	var p := Vector2(pos.x, pos.z)
	var q := Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y))
	return p.distance_to(q)


## Where a worker coming from `from` should stand: the nearest point of the footprint edge,
## pushed `clearance` metres outward.
func build_spot(from: Vector3, clearance: float) -> Vector3:
	var r := footprint_rect()
	var p := Vector2(from.x, from.z)
	var q := Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y))
	var out := p - q
	if out.length() < 0.01:
		# Inside the footprint: leave by the nearest edge.
		var to_edges := [p.x - r.position.x, r.end.x - p.x, p.y - r.position.y, r.end.y - p.y]
		var dirs := [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
		var best := 0
		for i in 4:
			if to_edges[i] < to_edges[best]:
				best = i
		out = dirs[best]
		q = p + out * float(to_edges[best])
	var spot := q + out.normalized() * clearance
	return Vector3(spot.x, 0.0, spot.y)


# ---------------------------------------------------------------- construction

func _physics_process(delta: float) -> void:
	if _dead or building_type == null:
		return
	_since_damage += delta
	if is_constructed():
		if building_type.idle_regen_pct > 0.0:
			_idle_regen_process(delta)
		if building_type.aura_radius > 0.0 and not building_type.aura_stats.is_empty():
			_aura_process(delta)
		return
	var speed := build_speed()
	if speed <= 0.0:
		return
	var step := minf(speed / maxf(building_type.build_time, 0.01) * delta, 1.0 - _progress)
	_progress += step
	hp = minf(max_hp, hp + max_hp * (1.0 - START_HP_RATIO) * step)
	_call_model(&"set_health_ratio", [hp / maxf(max_hp, 1.0)])
	if _progress >= 1.0 - 0.000001:
		_progress = 1.0
		_complete()
	_update_look()


func _complete() -> void:
	_builders.clear()
	_apply_pop_bonus()
	_update_look()
	construction_finished.emit(self)
	var events := get_node_or_null(^"/root/Events")
	if events:
		events.building_completed.emit(self)


## Nature "Verdant": idle_regen_pct % of max HP per second, IDLE_REGEN_DELAY s after the last damage.
func _idle_regen_process(delta: float) -> void:
	if _since_damage < IDLE_REGEN_DELAY or hp >= max_hp:
		_regen_left = IDLE_REGEN_TICK
		return
	_regen_left -= delta
	if _regen_left <= 0.0:
		_regen_left += IDLE_REGEN_TICK
		heal(max_hp * building_type.idle_regen_pct / 100.0 * IDLE_REGEN_TICK)


## Bramble Spire: every AURA_TICK s, friendly non-worker units (soldiers, wizards, summons) within
## aura_radius get the modifier `aura:<aura_id>` for Unit.AURA_LINGER s (Unit.receive_aura).
func _aura_process(delta: float) -> void:
	_aura_left -= delta
	if _aura_left > 0.0:
		return
	_aura_left += AURA_TICK
	var stats := building_type.aura_stats
	var mod_id := Unit.aura_modifier_id(building_type.aura_id if building_type.aura_id != &"" else building_type.id)
	var prio := 0.0
	for k: Variant in stats:
		prio += absf(float(stats[k]))
	var r2 := building_type.aura_radius * building_type.aura_radius
	var me := global_position
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u == null or not Teams.is_allied_fast(int(u.team), int(team)) or not u.is_alive():   # 2v2: allies too
			continue
		if u.unit_type != null and u.unit_type.is_worker:
			continue
		var dx := u.global_position.x - me.x
		var dz := u.global_position.z - me.z
		if dx * dx + dz * dz <= r2:
			u.receive_aura(mod_id, stats, self, prio)


func _prune_builders() -> void:
	for i in range(_builders.size() - 1, -1, -1):
		var w := _builders[i]
		if not is_instance_valid(w) or not w.is_inside_tree() \
				or (w.has_method(&"is_alive") and not bool(w.call(&"is_alive"))):
			_builders.remove_at(i)


func _destroy() -> void:
	if _dead:
		return
	_dead = true
	if cancelled:
		killer = null   # a cancelled site pays no XP (Wizard only credits hp <= 0 with a killer)
	else:
		hp = 0.0
		if not is_instance_valid(killer):
			killer = null   # the last attacker died / was freed since it hit us (a typed Node3D arg can't take it)
		Unit.award_soldier_kill_xp(self, killer)
	_on_destroyed()
	_remove_pop_bonus()
	_builders.clear()
	set_selected(false)
	remove_from_group("buildings")
	collision_layer = 0   # out of clicks, physics and the next navmesh bake
	set_physics_process(false)
	if _hp_bar:
		_hp_bar.visible = false
	destroyed.emit(self)
	_collapse()


func _apply_pop_bonus() -> void:
	if _bonus_applied or building_type == null or building_type.pop_bonus == 0:
		return
	var eco := _get_economy()
	if eco:
		# The team's kingdom sets its hard pop cap (Nature 50, else 40): the keep's faction wins,
		# another pop building only names it while it is still unknown.
		if building_type.faction != &"" and (building_type.kind == &"keep" or eco.kingdom == &""):
			eco.set_kingdom(building_type.faction)
		eco.add_pop_bonus(building_type.pop_bonus)
		_bonus_applied = true


func _remove_pop_bonus() -> void:
	if not _bonus_applied:
		return
	_bonus_applied = false
	var eco := _get_economy()
	if eco:
		eco.add_pop_bonus(-building_type.pop_bonus)


## The building changed team (MissionBase.switch_seat_side, review R4-5; called after `team` is set): forget the cached
## Economy and move a pop bonus already applied from the old team's Economy to the new one.
func refresh_economy() -> void:
	var had_bonus := _bonus_applied
	if had_bonus:
		_remove_pop_bonus()   # from the cached (old) Economy
	_economy = null
	if had_bonus:
		_apply_pop_bonus()


func _get_economy() -> Economy:
	if _economy == null or not is_instance_valid(_economy):
		_economy = Economy.for_team(team)
	return _economy


# ---------------------------------------------------------------- hooks for subclasses

## The type used when none was set (Keep picks its kingdom's keep).
func _default_type() -> BuildingType:
	return null


## Size of the collider / body box (x, height, z).
func _body_size() -> Vector3:
	if building_type == null:
		return Vector3(2.0, 2.0, 2.0)
	var s := building_type.size_m()
	return Vector3(s.x, building_type.height, s.y)


## Height of the highest point of the look (roof tip), for the HP bar.
func _top_height() -> float:
	return maxf(_body_size().y + 1.5, _model_top())


func _on_destroyed() -> void:
	pass


func _on_selected_changed() -> void:
	pass


## Builds the placeholder shapes under _visual with _add_mesh (so the site look can fade them).
func _build_shape() -> void:
	var kind := building_type.kind if building_type else &""
	var body := _body_size()
	match kind:
		&"barracks":
			var box := BoxMesh.new()
			box.size = body
			_add_mesh(box, Color(team_color.r * 0.7, team_color.g * 0.7, team_color.b * 0.7), body.y * 0.5)
			var roof := PrismMesh.new()
			roof.size = Vector3(body.x, 1.5, body.z)
			_add_mesh(roof, team_color, body.y + 0.75)
		&"house":
			var box := BoxMesh.new()
			box.size = body
			_add_mesh(box, building_type.body_color, body.y * 0.5)
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = Vector2(body.x, body.z).length() * 0.5 + 0.1
			cone.height = 1.5
			cone.radial_segments = 4
			var roof := _add_mesh(cone, team_color, body.y + 0.75)
			roof.rotation.y = PI / 4.0
		_:
			var box := BoxMesh.new()
			box.size = body
			_add_mesh(box, building_type.body_color if building_type else Color.GRAY, body.y * 0.5)


# ---------------------------------------------------------------- look

func _build_visual() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	if model_scene:
		_model = model_scene.instantiate() as Node3D
		if _model:
			# The model's gate is its local -Z: turn it toward front_toward (the map centre),
			# snapped to 90 degrees (Fire keep in the 1v1: -90, gate facing +x).
			_model.rotation.y = _gate_yaw()
			# Hooks are safe before the model's _ready (it caches and applies them).
			_call_model(&"set_team_color", [team_color])
			_call_model(&"set_construction_progress", [_progress])
			_call_model(&"set_health_ratio", [hp / maxf(max_hp, 1.0)])
			if _model.has_signal(&"destroyed_finished"):
				_model.connect(&"destroyed_finished", _on_model_destroyed_finished)
			_visual.add_child(_model)
			return
	_build_shape()


## The model_scene instance (the art), or null with the placeholder shapes.
func model() -> Node3D:
	return _model if _model != null and is_instance_valid(_model) else null


## Calls `method` on the model scene if it has it (the art hooks of docs/design/art-keep.md 8.8).
func _call_model(method: StringName, args: Array = []) -> void:
	if _model != null and is_instance_valid(_model) and _model.has_method(method):
		_model.callv(method, args)


## Yaw that turns local -Z toward front_toward along its dominant axis.
func _gate_yaw() -> float:
	var d := front_toward - global_position if is_inside_tree() else front_toward - position
	if absf(d.x) >= absf(d.z):
		return -PI / 2.0 if d.x >= 0.0 else PI / 2.0
	return 0.0 if d.z < 0.0 else PI


## Highest point of the model's meshes above the building's base (0 if none).
func _model_top() -> float:
	return _mesh_top(_model, _model.transform) if _model else 0.0


func _mesh_top(node: Node, xf: Transform3D) -> float:
	var top := 0.0
	var mi := node as MeshInstance3D
	if mi and mi.mesh:
		var box := xf * mi.mesh.get_aabb()
		top = box.end.y
	for child in node.get_children():
		var n3 := child as Node3D
		if n3:
			top = maxf(top, _mesh_top(n3, xf * n3.transform))
	return top


func _on_model_destroyed_finished() -> void:
	if _dead and is_inside_tree():
		queue_free()


func _add_mesh(mesh: Mesh, color: Color, y: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mi.material_override = mat
	mi.position.y = y
	_visual.add_child(mi)
	_mats.append(mat)
	return mi


## Site look: alpha 0.35, height 0.2 + 0.8 x progress, footprint outline. Finished: solid.
func _update_look() -> void:
	var site := not is_constructed() and not _dead
	if site != _look_is_site or _mats.is_empty():
		_look_is_site = site
		for mat in _mats:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if site else BaseMaterial3D.TRANSPARENCY_DISABLED
			mat.albedo_color.a = SITE_ALPHA if site else 1.0
		if _outline:
			_outline.visible = site
	if _model and _model.has_method(&"set_construction_progress"):
		if not _dead:
			_model.call(&"set_construction_progress", _progress)   # the model shows its own site
	elif _visual and not _dead:
		_visual.scale.y = (0.2 + 0.8 * _progress) if site else 1.0
	_update_hp_bar()


func _collapse() -> void:
	if _visual == null:
		queue_free()
		return
	if _model and _model.has_method(&"play_destroyed"):
		_model.call(&"play_destroyed")
		var tree := get_tree()
		if _model.has_signal(&"destroyed_finished"):
			# Freed by _on_model_destroyed_finished; this is only a safety net.
			tree.create_timer(FREE_DELAY * 3.0, false).timeout.connect(_on_model_destroyed_finished)
		else:
			tree.create_timer(FREE_DELAY, false).timeout.connect(_on_model_destroyed_finished)
		return
	for mat in _mats:
		mat.albedo_color = mat.albedo_color.darkened(0.6)
	var tween := create_tween()
	tween.tween_property(_visual, "scale", Vector3(1.05, 0.08, 1.05), 0.8)
	tween.tween_interval(FREE_DELAY - 0.8)
	tween.tween_callback(queue_free)


## A thin line box around the footprint on the ground (shown while under construction).
func _build_outline() -> void:
	_outline = Node3D.new()
	add_child(_outline)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = team_color
	var s := building_type.size_m() if building_type else Vector2(2.0, 2.0)
	var w := 0.1
	var edges := [
		[Vector3(s.x + w, 0.04, w), Vector3(0.0, 0.02, -s.y * 0.5)],
		[Vector3(s.x + w, 0.04, w), Vector3(0.0, 0.02, s.y * 0.5)],
		[Vector3(w, 0.04, s.y + w), Vector3(-s.x * 0.5, 0.02, 0.0)],
		[Vector3(w, 0.04, s.y + w), Vector3(s.x * 0.5, 0.02, 0.0)],
	]
	for e in edges:
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = e[0]
		mi.mesh = box
		mi.material_override = mat
		mi.position = e[1]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_outline.add_child(mi)
	_outline.visible = false


## Ring (`hp` false) / HP-bar colour of a building of `t` as the local player sees it: own green, ally blue, neutral
## gold, enemy red (Unit.team_color / team_hp_color shades). An ALLY seat's buildings in 2v2 are no longer red
## (review 2026-10-08 L2).
static func relation_color(t: int, hp: bool) -> Color:
	var rel := Teams.relation(Teams.human_seat(), t)
	var shade := Unit.Team.ENEMY
	if rel == &"self":
		shade = Unit.Team.PLAYER
	elif rel == &"ally":
		shade = Unit.Team.ALLY
	elif rel == &"neutral":
		shade = Unit.Team.NEUTRAL
	elif t == Unit.Team.ENEMY_2:
		shade = Unit.Team.ENEMY_2
	return Unit.team_hp_color(shade) if hp else Unit.team_color(shade)


## Same yellow-green ring as units; radius = half the footprint diagonal + 0.3.
func _build_ring() -> void:
	var s := building_type.size_m() if building_type else Vector2(2.0, 2.0)
	var r := s.length() * 0.5 + 0.3
	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = r - 0.1
	torus.outer_radius = r + 0.1
	torus.rings = 48
	_ring.mesh = torus
	_ring.scale = Vector3(1.0, 0.15, 1.0)
	_ring.position.y = 0.05
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = relation_color(int(team), false)
	_ring.material_override = mat
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.visible = false
	add_child(_ring)


## A camera-facing HP bar, shown when selected, damaged or under construction.
func _build_hp_bar() -> void:
	if _hp_shader == null:
		_hp_shader = Shader.new()
		_hp_shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform float fill = 1.0;
uniform vec4 fill_color : source_color = vec4(0.2, 0.9, 0.25, 1.0);
uniform vec4 back_color : source_color = vec4(0.08, 0.08, 0.08, 0.85);
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
	bool border = UV.x < 0.01 || UV.x > 0.99 || UV.y < 0.12 || UV.y > 0.88;
	vec4 c = border ? vec4(0.0, 0.0, 0.0, 1.0) : (UV.x < fill ? fill_color : back_color);
	ALBEDO = c.rgb;
	ALPHA = c.a;
}
"""
	_hp_mat = ShaderMaterial.new()
	_hp_mat.shader = _hp_shader
	_hp_mat.set_shader_parameter("fill_color", relation_color(int(team), true))
	_hp_bar = MeshInstance3D.new()
	var quad := QuadMesh.new()
	var s := building_type.size_m() if building_type else Vector2(2.0, 2.0)
	quad.size = Vector2(maxf(1.6, s.x * 0.8), 0.22)
	_hp_bar.mesh = quad
	_hp_bar.material_override = _hp_mat
	_hp_bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_hp_bar.position.y = _top_height() + 0.7
	add_child(_hp_bar)


func _update_hp_bar() -> void:
	if _hp_bar == null:
		return
	_hp_mat.set_shader_parameter("fill", clampf(hp / maxf(max_hp, 1.0), 0.0, 1.0))
	_hp_bar.visible = not _dead and (selected or hp < max_hp or not is_constructed())


# ---------------------------------------------------------------- save / load (docs/design/save-load.md)

## The building as a save row (SaveWorld). `ids` maps saved nodes -> save id.
func save_snapshot(ids: Dictionary) -> Dictionary:
	return {
		"type": String(building_type.id) if building_type else "",
		"team": int(team),
		"pos": global_position,
		"hp": hp,
		"max_hp": max_hp,
		"progress": _progress,
		"metas": SaveCodec.encode_metas(self, ids),
		"groups": SaveCodec.custom_groups(self),
	}


## Phase 1 of a load (the building is in the tree): construction progress (a finished start building can become a
## site again: no pop bonus), metas, groups. HP waits for load_snapshot_late (tier / Masons' Charter first).
func load_snapshot(d: Dictionary, nodes: Dictionary) -> void:
	var p := clampf(float(d.get("progress", 1.0)), 0.0, 1.0)
	if p < 1.0:
		_progress = p
		_remove_pop_bonus()
	elif not is_constructed():
		_progress = 1.0
		_complete()
	_update_look()
	SaveCodec.decode_metas(self, d.get("metas", {}), nodes)
	for g: Variant in d.get("groups", []):
		if not is_in_group(StringName(str(g))):
			add_to_group(StringName(str(g)))


## Phase 2: HP (after the tier and the team's HP multiplier are back).
func load_snapshot_late(d: Dictionary, _nodes: Dictionary) -> void:
	# The saved max_hp wins: it already holds the tier / Masons' Charter factors, and a max_hp a script set (a mission
	# tollgate or door) would be lost otherwise.
	var saved_max := float(d.get("max_hp", 0.0))
	if saved_max > 0.0:
		max_hp = saved_max
	hp = clampf(float(d.get("hp", hp)), 1.0, max_hp)
	_update_hp_bar()
	_call_model(&"set_health_ratio", [hp / maxf(max_hp, 1.0)])


## A start building the save does not have: leaves the world quietly (no death, no XP, no destroyed signal), gives
## its pop bonus back. The caller rebakes the navmesh.
func dispose_for_load() -> void:
	_remove_pop_bonus()
	_dead = true
	remove_from_group("buildings")
	collision_layer = 0
	var parent := get_parent()
	if parent:
		parent.remove_child(self)
	queue_free()
