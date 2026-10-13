class_name CrystalNode
extends StaticBody3D
## A mana crystal deposit that workers mine. Group "crystal_nodes". Layer 1: an obstacle for the
## navmesh like a rock, so add it under the NavigationRegion3D BEFORE the navmesh bakes.
## Right-click raycasts on layer 1 hit this body directly (collider is CrystalNode).
## Numbers: docs/design/economy.md.

signal depleted(node: CrystalNode)

const RADIUS := 1.2
const MAX_MINERS := 3
const COLOR := Color(0.45, 0.85, 1.0)
const PRISM_HEIGHTS: Array[float] = [1.6, 1.2, 0.9]
const DEPLETE_TIME := 0.5
const ART_PATH := "res://art/environment/crystal_node.tscn"   ## Default model_scene (CrystalNodeArt).

@export var node_id: StringName = &""
@export var crystals_left: int = 600
## Drop a real model here later to replace the placeholder prisms.
@export var model_scene: PackedScene

var max_crystals: int = 0   ## Crystals at the start (the look shrinks from this).

var _miners: Array[Node] = []     # workers mining right now (max MAX_MINERS)
var _gatherers: Array[Node] = []  # workers assigned to this node (used to spread their spots)
var _visual: Node3D
var _model: Node3D                # model_scene instance (art/environment/crystal_node.tscn), or null
var _depleting := false


func _ready() -> void:
	add_to_group("crystal_nodes")
	collision_layer = 1
	collision_mask = 0
	max_crystals = maxi(crystals_left, 1)
	var shape := CylinderShape3D.new()
	shape.radius = RADIUS
	shape.height = 2.0
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position.y = 1.0
	add_child(col)
	_build_visual()
	_update_look()


## True if `worker` may mine here now (crystals left and a free spot, or already mining).
func can_mine(worker: Node) -> bool:
	if _depleting or crystals_left <= 0:
		return false
	_prune(_miners)
	return _miners.has(worker) or _miners.size() < MAX_MINERS


## Takes up to `amount` crystals. Returns what was really taken. At 0 the node disappears.
func take(amount: int) -> int:
	if _depleting or amount <= 0:
		return 0
	var got := mini(amount, crystals_left)
	crystals_left -= got
	_update_look()
	if crystals_left <= 0:
		_deplete()
	return got


func is_depleted() -> bool:
	return _depleting or crystals_left <= 0


## Workers call this when they start mining. Returns false if there is no free spot.
func begin_mining(worker: Node) -> bool:
	if not can_mine(worker):
		return false
	if not _miners.has(worker):
		_miners.append(worker)
	return true


func end_mining(worker: Node) -> void:
	_miners.erase(worker)


func add_gatherer(worker: Node) -> void:
	if not _gatherers.has(worker):
		_gatherers.append(worker)


func remove_gatherer(worker: Node) -> void:
	_gatherers.erase(worker)
	_miners.erase(worker)


## Where `worker` should stand to mine: on the node's edge, on the side of `toward`, spread so
## the workers of this node don't all aim at the same spot.
func work_spot(worker: Node, toward: Vector3, worker_radius: float) -> Vector3:
	var dir := toward - global_position
	dir.y = 0.0
	if dir.length() < 0.01:
		dir = Vector3.BACK
	_prune(_gatherers)
	var idx := maxi(0, _gatherers.find(worker))
	# 0, +0.7, -0.7, +1.4, -1.4 ... radians around the side facing `toward`.
	var step := ceili(idx / 2.0) * 0.7 * (1.0 if idx % 2 == 1 else -1.0)
	var dist := RADIUS + worker_radius + 0.3
	return global_position + dir.normalized().rotated(Vector3.UP, step) * dist


## The nearest node with crystals left within `max_distance` of `pos` (null if none).
static func nearest(pos: Vector3, max_distance: float = INF, exclude: Node = null) -> CrystalNode:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var best: CrystalNode = null
	var best_d := max_distance
	for node in tree.get_nodes_in_group("crystal_nodes"):
		var cn := node as CrystalNode
		if cn == null or cn == exclude or cn.is_depleted():
			continue
		var d := Vector2(cn.global_position.x - pos.x, cn.global_position.z - pos.z).length()
		if d < best_d:
			best_d = d
			best = cn
	return best


## Drops workers that were freed without telling us.
func _prune(list: Array[Node]) -> void:
	for i in range(list.size() - 1, -1, -1):
		if not is_instance_valid(list[i]):
			list.remove_at(i)


func _deplete() -> void:
	_depleting = true
	remove_from_group("crystal_nodes")
	_miners.clear()
	depleted.emit(self)
	var tween := create_tween()
	tween.tween_property(_visual, "scale", Vector3(0.01, 0.01, 0.01), DEPLETE_TIME)
	tween.tween_callback(_vanish)


# Review R4-6: the node is a navmesh obstacle. It leaves the tree first, then the level's BuildGrid rebakes, so the
# ground it stood on becomes walkable / buildable again. Runs from the shrink tween only (never during a level
# teardown: the tween dies with the level).
func _vanish() -> void:
	var grid := _level_grid()
	var parent := get_parent()
	if parent:
		parent.remove_child(self)
	if grid and grid.is_inside_tree() and not grid.is_queued_for_deletion():
		grid.request_rebake()
	queue_free()


## The BuildGrid of the level this node sits in (the first ancestor with a `build_grid`), or null.
func _level_grid() -> BuildGrid:
	var n := get_parent()
	while n:
		var g: Variant = n.get(&"build_grid")
		if g is BuildGrid and is_instance_valid(g):
			return g as BuildGrid
		n = n.get_parent()
	return null


## The art model shrinks its own prisms (set_fill_ratio); the placeholder scales from 1.0 (full)
## to 0.5 (last crystal).
func _update_look() -> void:
	if _visual == null or _depleting:
		return
	var ratio := clampf(float(crystals_left) / float(max_crystals), 0.0, 1.0)
	if _model != null and _model.has_method(&"set_fill_ratio"):
		_model.call(&"set_fill_ratio", ratio)
		return
	var s := lerpf(0.5, 1.0, ratio)
	_visual.scale = Vector3(s, s, s)


## The art model's fill ratio (crystals left / max, 0-1); -1 without a model that has the hook.
func model_fill_ratio() -> float:
	if _model != null and _model.has_method(&"get_fill_ratio"):
		return float(_model.call(&"get_fill_ratio"))
	return -1.0


func _build_visual() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	if model_scene == null and ResourceLoader.exists(ART_PATH):
		model_scene = load(ART_PATH) as PackedScene
	if model_scene:
		_model = model_scene.instantiate() as Node3D
		if _model:
			_visual.add_child(_model)
			return

	var rock := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = RADIUS * 0.9
	disc.bottom_radius = RADIUS
	disc.height = 0.25
	rock.mesh = disc
	var rock_mat := StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.42, 0.4, 0.42)
	rock_mat.roughness = 0.95
	rock.material_override = rock_mat
	rock.position.y = 0.125
	_visual.add_child(rock)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = COLOR
	mat.emission_enabled = true
	mat.emission = COLOR
	mat.emission_energy_multiplier = 1.5
	mat.roughness = 0.2
	var offsets: Array[Vector3] = [Vector3(0.0, 0.0, 0.0), Vector3(0.5, 0.0, 0.3), Vector3(-0.35, 0.0, 0.45)]
	var tilts: Array[Vector3] = [Vector3(0.05, 0.0, 0.08), Vector3(-0.1, 0.6, -0.25), Vector3(0.2, 1.2, 0.18)]
	for i in PRISM_HEIGHTS.size():
		var h := PRISM_HEIGHTS[i]
		var prism := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.45, h, 0.45)
		prism.mesh = pm
		prism.material_override = mat
		prism.position = offsets[i] + Vector3(0.0, 0.25 + h * 0.5, 0.0)
		prism.rotation = tilts[i]
		_visual.add_child(prism)
