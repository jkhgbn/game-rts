class_name Keep
extends TrainingBuilding
## The team's keep: trains workers only (from wave 2), is the workers' crystal drop-off point,
## gives +20 pop (building_type.pop_bonus). Queue / rally API: TrainingBuilding.
## Numbers: docs/design/economy.md and buildings.md. From balance-1 the keep also shoots like a spire
## (BuildingGun: attack_damage / attack_range / attack_cooldown of its BuildingType, units first;
## the range counts from its walls).

const SIZE := Vector3(5.0, 6.0, 5.0)
const BOLT_SIZE := 0.16
const DROP_OFF_DISTANCE := 3.5   ## Per axis, toward the corner facing front_toward: (3.5, -3.5) on the Fire side.
const RALLY_DISTANCE := 6.0
const ESSENCE_BANK_PATH := "res://scripts/items/essence_bank.gd"

## The optional crystal -> essence exchange (items.md, a user decision). False = refused everywhere.
static var exchange_enabled := true

## Read only: what the keep shoots at (null when idle or when its type has no attack).
var attack_target: Node3D:
	get:
		return _gun.target if _gun else null

var _gun: BuildingGun


func _physics_process(delta: float) -> void:
	super(delta)
	if _dead or not is_constructed() or not BuildingGun.can_shoot(building_type):
		return
	if _gun == null:
		_gun = BuildingGun.new(self, building_type.height, BOLT_SIZE, target_radius())
	_gun.tick(delta)


## The living keep of `for_team_id` closest to `pos` (null if none).
static func nearest(for_team_id: int, pos: Vector3) -> Keep:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var best: Keep = null
	var best_d := INF
	for node in tree.get_nodes_in_group("buildings"):
		var k := node as Keep
		if k == null or k.team != for_team_id or not k.is_alive():
			continue
		var d := k.global_position.distance_squared_to(pos)
		if d < best_d:
			best_d = d
			best = k
	return best


## The base-shop exchange: `team` pays 100 crystals and gets 40 essence (EssenceBank). "" = done,
## else the reason. The caller (shop UI / bot) checks the wizard is within ShopStock.SHOP_RADIUS.
func exchange_crystals(for_team: int) -> String:
	if not exchange_enabled:
		return "Exchange disabled"
	if not is_shop():
		return "No shop nearby"
	if for_team != int(team):
		return "Not your shop"
	var bank: Object = essence_bank_for(for_team)
	if bank == null:
		return "Essence not available"
	var eco := Economy.for_team(for_team)
	if eco == null or not eco.spend(ShopStock.EXCHANGE_CRYSTALS):   # a failed spend flashes the top bar
		return TrainingBuilding.REASON_NO_CRYSTALS
	bank.call(&"add", ShopStock.EXCHANGE_ESSENCE)
	return ""


## EssenceBank.for_team(team) if scripts/items/essence_bank.gd exists (else null).
static func essence_bank_for(for_team: int) -> Object:
	if not ResourceLoader.exists(ESSENCE_BANK_PATH):
		return null
	var script := load(ESSENCE_BANK_PATH) as Script
	if script == null or not script_has(script, &"for_team"):
		return null
	return script.call(&"for_team", for_team) as Object


static func script_has(script: Script, method: StringName) -> bool:
	for m in script.get_script_method_list():
		if StringName(m.get("name", "")) == method:
			return true
	return false


## Where workers drop crystals and where trained units appear.
func drop_off_point() -> Vector3:
	return global_position + _corner_offset(DROP_OFF_DISTANCE)


func spawn_point() -> Vector3:
	return drop_off_point()


func _spawn_distance() -> float:
	return DROP_OFF_DISTANCE


func _rally_distance() -> float:
	return RALLY_DISTANCE


func _default_type() -> BuildingType:
	return BuildingType.find("fire_keep" if team == Unit.Team.PLAYER else "shadow_keep")


func _body_size() -> Vector3:
	return SIZE


func _top_height() -> float:
	return maxf(9.0, _model_top())   # the art keeps are ~15-18 m tall


func _build_shape() -> void:
	var box := BoxMesh.new()
	box.size = SIZE
	_add_mesh(box, building_type.body_color if building_type else Color(0.5, 0.45, 0.4), SIZE.y * 0.5)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 3.8
	cone.height = 3.0
	cone.radial_segments = 4
	var roof := _add_mesh(cone, team_color.darkened(0.2), 7.5)
	roof.rotation.y = PI / 4.0
