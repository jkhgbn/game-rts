class_name Worker
extends Unit
## A worker (UnitType.is_worker, e.g. Cinder Hand). command_gather(node) loops:
## walk to the node -> mine 4 s -> carry 10 crystals -> drop them at the nearest drop-off (completed keep
## or barracks, Building.nearest_drop_off) -> back.
## command_build(site): walk to the site edge, build until it is finished, then go back to the node
## it was gathering (else stand at the site edge). Any other order stops gathering / building;
## crystals being carried are kept and delivered on the next drop-off.
## Numbers: docs/design/economy.md, buildings.md.

enum GatherState { NONE, TO_NODE, WAITING, MINING, TO_KEEP }
enum BuildState { NONE, TO_SITE, BUILDING }

const MINE_TIME := 4.0
const CARRY_AMOUNT := 10
const NODE_STOP_MARGIN := 0.3     # stop at node radius + own radius + this
const ARRIVE_SLACK := 0.9         # the nav agent stops up to 0.8 m short of its target
const DROP_OFF_REACH := 0.9
const STALL_CHECK := 0.5          # seconds between "am I still moving?" checks
const STALL_DISTANCE := 0.15
const STALL_EXTRA_REACH := 1.5    # a blocked worker this close to its goal counts as arrived
const NEW_NODE_RANGE := 30.0      # when a node runs out, look for another one this close
const CARRY_COLOR := Color(0.45, 0.85, 1.0)
const BUILD_MARGIN := 0.3         # stand at footprint edge + own radius + this

var carried: int = 0                              ## Read only: crystals being carried.
var gather_node: CrystalNode = null               ## Read only: the node being gathered.
var gather_state: GatherState = GatherState.NONE  ## Read only.
var build_site: Building = null                   ## Read only: the site being built.
var build_state: BuildState = BuildState.NONE     ## Read only.

var _resume_node: CrystalNode = null   # node to go back to after building
var _mine_left := 0.0
var _walk_target := Vector3.INF   # INF = no walk issued yet for the current step
var _last_node_pos := Vector3.ZERO
var _stall_left := STALL_CHECK
var _stall_from := Vector3.ZERO
var _stalled := false
var _drop: Building = null         # where the current load goes (keep or barracks)
var _economy: Economy = null
var _carry_visual: MeshInstance3D


## Creates the right Unit for any type: a Caravan for caravan types (UnitType.is_caravan), a Worker for
## worker types, else type.create_unit().
static func make_unit(type: UnitType) -> Unit:
	if type.get(&"is_caravan") == true:   # read by name: the field is added by task 10.C6
		var c := Caravan.new()
		c.apply_type(type)
		return c
	if type.is_worker:
		var w := Worker.new()
		w.apply_type(type)
		return w
	return type.create_unit()


func _ready() -> void:
	super()
	_build_carry_visual()


func _exit_tree() -> void:
	if is_instance_valid(gather_node):
		gather_node.remove_gatherer(self)
	_leave_site()


# ---------------------------------------------------------------- orders

## Gather from `node` until it runs out. A worker carrying crystals delivers them first.
func command_gather(node: CrystalNode) -> void:
	if not is_alive() or node == null or not is_instance_valid(node) or node.is_depleted():
		return
	_stop_building()
	_set_node(node)
	if carried > 0:
		_go_to_keep()
	else:
		_go_to_node()


func is_gathering() -> bool:
	return gather_state != GatherState.NONE


## Build (or resume) the construction site `site` of our team: walk to its edge, then build.
## When it is finished (or gone), go back to the node we were gathering, else stand at the edge.
## Also the right-click order on an unfinished own site.
func command_build(site: Building) -> void:
	if not is_alive() or site == null or not is_instance_valid(site) or not site.is_alive() \
			or site.is_constructed() or int(site.team) != int(team):
		return
	if build_state == BuildState.NONE:   # a new build job: remember what to go back to
		_resume_node = gather_node if is_gathering() and _node_ok() else null
	elif build_site != site:
		_leave_site()
	_stop_gathering()
	super.command_stop()
	build_site = site
	build_state = BuildState.TO_SITE
	_walk(site.build_spot(global_position, radius + BUILD_MARGIN))


func is_building() -> bool:
	return build_state != BuildState.NONE


func command_move(target: Vector3) -> void:
	_stop_gathering()
	_stop_building()
	super(target)


## `target`: a Unit or a building (same as Unit.command_attack).
func command_attack(target) -> void:
	_stop_gathering()
	_stop_building()
	super(target)


func command_attack_move(target: Vector3) -> void:
	_stop_gathering()
	_stop_building()
	super(target)


func command_stop() -> void:
	_stop_gathering()
	_stop_building()
	super()


func die() -> void:
	_stop_gathering()
	_stop_building()
	super()


# ---------------------------------------------------------------- gathering loop

func _physics_process(delta: float) -> void:
	super(delta)
	if not is_alive():
		return
	# Frozen (can_act() false): the mining timer and the gather / build loop pause; a site counts
	# only builders that can act (Building.build_speed), so it pauses too. Orders resume afterwards.
	if not can_act():
		return
	# Rooted (can_move() false, can_act() true): mining and building go on (kingdom-ice.md 2.1:
	# rooted stops movement only), but a walk in progress must not count as "stalled, arrived".
	if not can_move():
		_stalled = false
		_stall_left = STALL_CHECK
		_stall_from = global_position
	if build_state != BuildState.NONE:
		_build_process(delta)
		return
	if gather_state == GatherState.NONE:
		return

	# Hit while mining or waiting: the base Unit fights back. Pause, then walk back to work.
	if attack_target != null:
		if gather_state == GatherState.MINING or gather_state == GatherState.WAITING:
			if is_instance_valid(gather_node):
				gather_node.end_mining(self)
			gather_state = GatherState.TO_NODE
		_walk_target = Vector3.INF
		return

	match gather_state:
		GatherState.TO_NODE:
			if not _node_ok():
				_on_node_lost()
			elif _walk_target == Vector3.INF:
				_go_to_node()
			else:
				_update_stall(delta)
				var reach := CrystalNode.RADIUS + radius + NODE_STOP_MARGIN + ARRIVE_SLACK
				if _reached(gather_node.global_position, reach):
					super.command_stop()   # stand still (keeps the gather order)
					_face_point(gather_node.global_position)
					gather_state = GatherState.WAITING
					_try_start_mining()
		GatherState.WAITING:
			if not _node_ok():
				_on_node_lost()
			else:
				_try_start_mining()
		GatherState.MINING:
			if not _node_ok():
				_on_node_lost()
				return
			_mine_left -= delta
			if _mine_left <= 0.0:
				var got := gather_node.take(CARRY_AMOUNT)
				gather_node.end_mining(self)
				carried += got
				_update_carry_visual()
				if carried > 0:
					_go_to_keep()
				else:
					_on_node_lost()
		GatherState.TO_KEEP:
			if not _drop_ok():
				_walk_target = Vector3.INF
				if not _find_drop_off(global_position):
					super.command_stop()
					gather_state = GatherState.NONE
					return
			if _walk_target == Vector3.INF:
				_walk(_drop_point())
				return
			_update_stall(delta)
			if _reached(_walk_target, DROP_OFF_REACH):
				_deliver()


# ---------------------------------------------------------------- building

func _build_process(delta: float) -> void:
	if not _site_ok():
		_finish_building()
		return
	# Hit while building: the base Unit fights back. Leave the site (it pauses), walk back after.
	if attack_target != null:
		if build_state == BuildState.BUILDING:
			build_site.remove_builder(self)
			build_state = BuildState.TO_SITE
		_walk_target = Vector3.INF
		return
	if build_state == BuildState.TO_SITE:
		if _walk_target == Vector3.INF:
			_walk(build_site.build_spot(global_position, radius + BUILD_MARGIN))
			return
		_update_stall(delta)
		var d := build_site.distance_to_footprint(global_position)
		var reach := radius + BUILD_MARGIN + ARRIVE_SLACK
		if d <= reach or (_stalled and d <= reach + STALL_EXTRA_REACH):
			super.command_stop()   # stand still (keeps the build order)
			_face_point(build_site.global_position)
			build_state = BuildState.BUILDING
			build_site.add_builder(self)


func _site_ok() -> bool:
	return is_instance_valid(build_site) and build_site.is_alive() and not build_site.is_constructed()


## The site is finished or gone: back to the node we were gathering, else stand here.
func _finish_building() -> void:
	var node := _resume_node
	_stop_building()
	if node != null and is_instance_valid(node) and not node.is_depleted():
		command_gather(node)
	else:
		super.command_stop()


func _stop_building() -> void:
	_leave_site()
	build_site = null
	build_state = BuildState.NONE
	_resume_node = null


func _leave_site() -> void:
	if is_instance_valid(build_site):
		build_site.remove_builder(self)


# ---------------------------------------------------------------- gathering helpers

func _try_start_mining() -> void:
	if gather_node.begin_mining(self):
		gather_state = GatherState.MINING
		_mine_left = MINE_TIME
		_model_call(&"play_mine")


func _deliver() -> void:
	if _economy == null or not is_instance_valid(_economy):
		_economy = Economy.for_team(team)
	if _economy and carried > 0:
		_economy.add_gathered(carried)
	carried = 0
	_update_carry_visual()
	if _node_ok():
		_go_to_node()
	else:
		_on_node_lost()


## The node ran out (or vanished): take the nearest node within 30 m of it, else stop
## (after delivering what is being carried).
func _on_node_lost() -> void:
	var old: CrystalNode = gather_node if is_instance_valid(gather_node) else null
	var next := CrystalNode.nearest(_last_node_pos, NEW_NODE_RANGE, old)
	if old:
		old.remove_gatherer(self)
	gather_node = null
	if next:
		_set_node(next)
		if carried > 0:
			_go_to_keep()
		else:
			_go_to_node()
	elif carried > 0:
		_go_to_keep()
	else:
		gather_state = GatherState.NONE
		super.command_stop()


func _go_to_node() -> void:
	gather_state = GatherState.TO_NODE
	var toward := global_position
	if _find_drop_off(gather_node.global_position):
		toward = _drop_point()
	_walk(gather_node.work_spot(self, toward, radius))


func _go_to_keep() -> void:
	gather_state = GatherState.TO_KEEP
	_walk_target = Vector3.INF
	if _find_drop_off(global_position):
		_walk(_drop_point())


func _set_node(node: CrystalNode) -> void:
	if is_instance_valid(gather_node) and gather_node != node:
		gather_node.remove_gatherer(self)
	gather_node = node
	node.add_gatherer(self)
	_last_node_pos = node.global_position


func _stop_gathering() -> void:
	if is_instance_valid(gather_node):
		gather_node.remove_gatherer(self)
	gather_node = null
	gather_state = GatherState.NONE
	_mine_left = 0.0
	_walk_target = Vector3.INF


func _walk(pos: Vector3) -> void:
	_walk_target = pos
	_stalled = false
	_stall_left = STALL_CHECK
	_stall_from = global_position
	super.command_move(pos)   # the base order, so gathering is not cancelled


func _node_ok() -> bool:
	return is_instance_valid(gather_node) and not gather_node.is_depleted()


func _drop_ok() -> bool:
	return is_instance_valid(_drop) and _drop.is_drop_off()


## Picks the drop-off nearest to `from` (null if the team has none). Returns true if found.
func _find_drop_off(from: Vector3) -> bool:
	_drop = Building.nearest_drop_off(team, from)
	return _drop != null


func _drop_point() -> Vector3:
	return _drop.call(&"drop_off_point")


func _update_stall(delta: float) -> void:
	_stall_left -= delta
	if _stall_left <= 0.0:
		_stall_left = STALL_CHECK
		_stalled = _flat_dist(_stall_from) < STALL_DISTANCE
		_stall_from = global_position


func _reached(target: Vector3, reach: float) -> bool:
	var d := _flat_dist(target)
	return d <= reach or (_stalled and d <= reach + STALL_EXTRA_REACH)


func _flat_dist(pos: Vector3) -> float:
	return Vector2(global_position.x - pos.x, global_position.z - pos.z).length()


func _face_point(pos: Vector3) -> void:
	var dir := pos - global_position
	if _visual and Vector2(dir.x, dir.z).length() > 0.01:
		_visual.rotation.y = atan2(dir.x, dir.z)


# ---------------------------------------------------------------- look

## A small crystal above the worker's back, shown while carrying.
func _build_carry_visual() -> void:
	if _visual == null:
		return
	if _model and _model.has_method(&"set_carrying"):   # the model shows its own load (4.G2)
		return
	_carry_visual = MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(0.18, 0.25, 0.18)
	_carry_visual.mesh = prism
	var mat := StandardMaterial3D.new()
	mat.albedo_color = CARRY_COLOR
	mat.emission_enabled = true
	mat.emission = CARRY_COLOR
	mat.emission_energy_multiplier = 1.5
	_carry_visual.material_override = mat
	_carry_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_carry_visual.position = Vector3(0.0, body_height * 0.85, -radius * 0.9)
	_carry_visual.visible = false
	_visual.add_child(_carry_visual)


func _update_carry_visual() -> void:
	if _carry_visual:
		_carry_visual.visible = carried > 0
	if _model and _model.has_method(&"set_carrying"):
		_model.call(&"set_carrying", carried > 0)
