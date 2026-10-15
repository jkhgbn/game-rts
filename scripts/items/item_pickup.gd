class_name ItemPickup
extends StaticBody3D
## An item lying on the ground (docs/design/items.md "Drop" / "Pick up" / HUD "Ground item"). Groups
## `"item_pickups"` and `"ground_items"`; collision layer 2 so clicks find it (units only collide with
## layer 1, so it never blocks them). A living wizard that comes within 2.2 m takes it
## (`pick_up(wizard)`); the UI's right-click just orders a move onto it. Spawn with `ItemPickup.spawn`.

signal picked_up(pickup: ItemPickup, wizard: Node3D, type: ItemType)

const PICKUP_RADIUS := 2.2
const CHECK_INTERVAL := 0.2
const SPIN_SPEED := deg_to_rad(45.0)
const CUBE_SIZE := 0.5
const CUBE_Y := 0.6
const DISC_RADIUS := 0.6
const DISC_COLOR := Color(0.2, 0.2, 0.2)
## Generic saved state (CLAUDE.md "Saved state"): SaveWorld saves every ground item through this group.
const SAVED_STATE_GROUP := &"saved_state"
const SAVE_KEY_PREFIX := "item_pickup:"

@export var type: ItemType
@export var count := 1
## Drop a real model here later to replace the placeholder cube.
@export var model_scene: PackedScene
## True when a hero wore this item before (Inventory.drop): taking it gives no max_hp heal (code review R1-1).
var worn := false

var _cube: Node3D
var _ring: MeshInstance3D
var _check_left := 0.0
var _ignored: Node3D = null       # the wizard who dropped it, until she walks out of the radius
var _taken := false
var _restore_parent: Node = null  # create_for_save: where load_state puts the rebuilt pickup

static var _tier_mats: Dictionary = {}   # int tier -> StandardMaterial3D (shared)
static var _disc_mat: StandardMaterial3D
static var _cube_mesh: BoxMesh
static var _disc_mesh: CylinderMesh


## Puts `count` of `type` on the ground at `pos` (snapped to the nearest navmesh point when there is
## one) under `parent` (default: the current scene). Returns the pickup.
static func spawn(item: ItemType, pos: Vector3, amount: int = 1, parent: Node = null) -> ItemPickup:
	if item == null:
		return null
	if parent == null:
		var tree := Engine.get_main_loop() as SceneTree
		if tree == null:
			return null
		parent = tree.current_scene if tree.current_scene else tree.root
	var p := ItemPickup.new()
	p.type = item
	p.count = maxi(1, amount)
	p.name = "Item_%s" % item.id
	parent.add_child(p)
	p.global_position = p._snap_to_navmesh(pos)
	return p


func _ready() -> void:
	add_to_group("item_pickups")
	add_to_group("ground_items")
	add_to_group(SAVED_STATE_GROUP)
	collision_layer = 2
	collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.9, 1.0, 0.9)
	shape.shape = box
	shape.position.y = 0.5
	add_child(shape)
	_build_visual()


func _process(delta: float) -> void:
	if _cube:
		_cube.rotate_y(SPIN_SPEED * delta)


func _physics_process(delta: float) -> void:
	_check_left -= delta
	if _check_left > 0.0 or _taken:
		return
	_check_left = CHECK_INTERVAL
	var tree := get_tree()
	for group: StringName in [&"heroes", &"enemy_heroes"]:
		for w in tree.get_nodes_in_group(group):
			var wiz := w as Node3D
			if wiz == null or (wiz.has_method(&"is_alive") and not bool(wiz.call(&"is_alive"))):
				continue
			var d := Vector2(wiz.global_position.x - global_position.x,
					wiz.global_position.z - global_position.z).length()
			if wiz == _ignored:
				if d > PICKUP_RADIUS + 0.3:
					_ignored = null
				continue
			if d <= PICKUP_RADIUS and pick_up(wiz):
				return


## The wizard takes the item (true), or false if she can't (dead, full inventory, already taken).
func pick_up(wizard: Node) -> bool:
	if _taken or type == null or wizard == null or not is_instance_valid(wizard):
		return false
	if wizard.has_method(&"is_alive") and not bool(wizard.call(&"is_alive")):
		return false
	var inv := Inventory.ensure_for(wizard)
	if inv == null or not inv.add_item(type, count, 0.0, not worn):
		return false
	_taken = true
	picked_up.emit(self, wizard as Node3D, type)
	queue_free()
	return true


## Right-click by the dropper: she may take it back even while standing on it.
func request_pickup(wizard: Node) -> void:
	if wizard == _ignored:
		_ignored = null
		_check_left = 0.0


## The dropper does not take it back until she has walked out of the pickup radius.
func ignore_until_left(wizard: Node3D) -> void:
	_ignored = wizard


# ---------------------------------------------------------------- save / load (code review R5-5)

## Unique per match (the node's instance id): a loaded pickup is rebuilt by create_for_save.
func save_key() -> String:
	return "%s%d" % [SAVE_KEY_PREFIX, get_instance_id()]


## {id, count, pos, worn}; empty (not saved) once taken or without a type.
func save_state() -> Dictionary:
	if _taken or type == null or not is_inside_tree():
		return {}
	return {"id": String(type.id), "count": count, "pos": global_position, "worn": worn}


## Puts the saved item back: its type, stack and spot. A rebuilt pickup (create_for_save) enters the level here.
## An unknown item id frees the pickup.
func load_state(d: Dictionary, _nodes: Dictionary) -> void:
	var t := ItemType.find(StringName(str(d.get("id", ""))))
	if t == null:
		if is_inside_tree():
			queue_free()
		else:
			queue_free()   # never a bare free(): the exported game's GDScript refuses it (parse error)
		return
	type = t
	count = maxi(1, int(d.get("count", 1)))
	worn = bool(d.get("worn", false))
	name = "Item_%s" % t.id
	var pos: Variant = d.get("pos")
	if not is_inside_tree():
		var parent: Node = _restore_parent if is_instance_valid(_restore_parent) else null
		_restore_parent = null
		if parent == null:
			queue_free()   # never a bare free(): the exported game's GDScript refuses it (parse error)
			return
		parent.add_child(self)
	if pos is Vector3:
		global_position = pos


## A fresh pickup for a saved row (not in the tree yet: load_state adds it under `level` once its type is known).
static func create_for_save(level: Node, _key: String) -> Node:
	if level == null or not is_instance_valid(level):
		return null
	var p := ItemPickup.new()
	p._restore_parent = level
	return p


## Hover highlight (the UI calls it): a gold ring on the ground.
func set_hovered(value: bool) -> void:
	if value and _ring == null:
		var torus := TorusMesh.new()
		torus.inner_radius = DISC_RADIUS + 0.05
		torus.outer_radius = DISC_RADIUS + 0.15
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(1.0, 0.85, 0.3)
		_ring = MeshInstance3D.new()
		_ring.mesh = torus
		_ring.material_override = mat
		_ring.position.y = 0.05
		add_child(_ring)
	if _ring:
		_ring.visible = value


func display_name() -> String:
	if type == null:
		return ""
	return type.display_name if count <= 1 else "%s x%d" % [type.display_name, count]


# ---------------------------------------------------------------- look

func _build_visual() -> void:
	if model_scene:
		_cube = model_scene.instantiate() as Node3D
		add_child(_cube)
	else:
		if _cube_mesh == null:
			_cube_mesh = BoxMesh.new()
			_cube_mesh.size = Vector3.ONE * CUBE_SIZE
			_disc_mesh = CylinderMesh.new()
			_disc_mesh.top_radius = DISC_RADIUS
			_disc_mesh.bottom_radius = DISC_RADIUS
			_disc_mesh.height = 0.04
			_disc_mat = StandardMaterial3D.new()
			_disc_mat.albedo_color = DISC_COLOR
		var cube := MeshInstance3D.new()
		cube.mesh = _cube_mesh
		cube.material_override = _material_for(type)
		cube.position.y = CUBE_Y
		cube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(cube)
		_cube = cube
		var disc := MeshInstance3D.new()
		disc.mesh = _disc_mesh
		disc.material_override = _disc_mat
		disc.position.y = 0.02
		disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(disc)
	var label := Label3D.new()
	label.text = display_name()
	label.font_size = 32
	label.pixel_size = 0.006
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = CUBE_Y + 0.9
	label.modulate = type.tier_color() if type else Color.WHITE
	label.outline_size = 8
	add_child(label)


static func _material_for(item: ItemType) -> StandardMaterial3D:
	var tier := int(item.tier) if item else 0
	if not _tier_mats.has(tier):
		var color := item.tier_color() if item else Color.WHITE
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.8
		_tier_mats[tier] = mat
	return _tier_mats[tier]


func _snap_to_navmesh(pos: Vector3) -> Vector3:
	var world := get_world_3d()
	if world == null:
		return pos
	var map := world.navigation_map
	if not map.is_valid() or NavigationServer3D.map_get_iteration_id(map) == 0:
		return pos
	var p := NavigationServer3D.map_get_closest_point(map, pos)
	# Only nudge onto walkable ground nearby; a far or empty answer (e.g. the map origin) keeps `pos`.
	var flat := Vector2(p.x - pos.x, p.z - pos.z).length()
	return Vector3(p.x, pos.y, p.z) if flat < 1.5 else pos
