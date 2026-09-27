class_name TradePost
extends StaticBody3D
## A neutral trading post on the ring road (docs/design/market-trade.md 2.2, contract section 12): where caravans
## trade. Team NEUTRAL, invulnerable and never a target: in neither "units" nor "buildings", so no unit, spell or
## bot picks it (like the taverns). Group "trade_posts"; clickable (collision layer 2).
## Its 6 x 6 m body (layer 1, square on the grid) blocks the build grid and the navmesh: add it under the
## NavigationRegion3D before the bake. Turn it so its front (local +Z) faces the road: the door is DOOR_DISTANCE
## (4 m, 1 m outside the face) in front of the centre, on the road node where caravans trade.
## - Open / held come from the TradeNetwork (set_open at 4:00, set_holder_team every pass); both are
##   forwarded to the model.
## Look: res://art/buildings/trade_post/trade_post.tscn (front = local +Z, footprint 6 x 6 centred on the origin;
## hooks set_sign(i), set_open(bool), set_held(color_or_null), set_selected(bool)) if it exists, else a code
## placeholder (open-sided timber waystation, signpost mast with a hanging sign, a glowing lantern, crates).
## - A caravan finishes its trade here (its cargo is set while its trade_state is &"trading" and its
##   route_post is this post) -> the model's `play_trade()` (sign swings, lantern flares), in step with the
##   caravan's own `post_trade` TradeVfx. Caravans are found through the group "caravans" (TRADE_POLL, while open).

const FOOTPRINT := 6.0                  ## Metres (6 x 6).
const BODY_HEIGHT := 4.0                ## Collider height (BuildGrid's probe sits at 0.15-2.15 m).
const DOOR_DISTANCE := 4.0              ## From the centre along the front (local +Z).
const LANTERN_COLOR := Color(1.0, 0.8, 0.4)
const SIGN_COLORS: Array[Color] = [Color(0.55, 0.70, 0.80), Color(0.78, 0.70, 0.50),
		Color(0.95, 0.72, 0.30), Color(0.72, 0.72, 0.76)]   ## Heron, millstone, lantern, gate.
const ART_PATH := "res://art/buildings/trade_post/trade_post.tscn"
const NEUTRAL_TEAM := 2   # Unit.Team.NEUTRAL
const TRADE_POLL := 0.25                ## Seconds between looks for caravans trading here (trade lasts 2 s).
const TRADING := &"trading"

## Stable id (&"heron_ford", &"millstone_cross", &"lantern_wharf", &"saltgate").
@export var post_id: StringName = &""
@export var display_name := "Trading Post"
## The hanging sign of the model: 0 heron, 1 millstone, 2 lantern, 3 gate.
@export var sign_index := 0

var team: int = NEUTRAL_TEAM

var _open := false
var _holder := -1
var _selected := false
var _art: Node3D
var _pennant: MeshInstance3D   # placeholder: shows the holder's colour
var _trade_poll := 0.0


func _ready() -> void:
	add_to_group("trade_posts")
	set_physics_process(_open)
	collision_layer = 1 | 2   # 1: blocks units, build grid and navmesh; 2: clicks find it
	collision_mask = 0
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(FOOTPRINT, BODY_HEIGHT, FOOTPRINT)
	col.shape = box
	col.position = Vector3(0.0, BODY_HEIGHT * 0.5, 0.0)
	add_child(col)
	if ResourceLoader.exists(ART_PATH):
		var scene := load(ART_PATH) as PackedScene
		_art = scene.instantiate() as Node3D if scene else null
		if _art:
			_art.name = "Art"
			add_child(_art)
			_art_call(&"set_sign", [sign_index])
			_art_call(&"set_open", [_open])
			_apply_held()
			return
	_build_placeholder()
	_apply_held()


# ---------------------------------------------------------------- public

func is_trade_post() -> bool:
	return true


## Always true: it can't be destroyed.
func is_alive() -> bool:
	return true


## Never a target.
func is_targetable() -> bool:
	return false


func is_invulnerable() -> bool:
	return true


## Invulnerable: damage is ignored.
func take_damage(_amount: float, _attacker: Node3D = null) -> void:
	pass


## Where caravans trade (y = 0): DOOR_DISTANCE in front of the centre (local +Z).
func door_point() -> Vector3:
	var p := global_transform * Vector3(0.0, 0.0, DOOR_DISTANCE)
	return Vector3(p.x, 0.0, p.z)


## True from 4:00 (the TradeNetwork opens it).
func is_open() -> bool:
	return _open


## TradeNetwork only: opens / closes the gates (forwarded to the model).
func set_open(value: bool) -> void:
	if _open == value:
		return
	_open = value
	_art_call(&"set_open", [value])
	set_physics_process(value)


## The team holding the post (its fighters within 12 m of the door, none of the other's), -1 = nobody.
func holder_team() -> int:
	return _holder


## TradeNetwork only (once per second).
func set_holder_team(holder: int) -> void:
	if _holder == holder:
		return
	_holder = holder
	_apply_held()


## True when the other side of `for_team` holds it (its caravans don't trade here then).
func is_held_by_enemy_of(for_team: int) -> bool:
	return _holder >= 0 and _holder != NEUTRAL_TEAM and _holder != for_team


## The selection ring of the model (the UI shows the post panel on a click).
func set_selected(value: bool) -> void:
	_selected = value
	_art_call(&"set_selected", [value])


## The 6 x 6 footprint as world x / z (the minimap square).
func footprint_rect() -> Rect2:
	var half := FOOTPRINT * 0.5
	return Rect2(Vector2(global_position.x - half, global_position.z - half), Vector2(FOOTPRINT, FOOTPRINT))


## Flat distance from `pos` to the door.
func distance_to_door(pos: Vector3) -> float:
	var d := door_point()
	return Vector2(pos.x - d.x, pos.z - d.z).length()


## The model (art scene or placeholder root), for VFX anchors.
func model() -> Node3D:
	return _art


## A caravan traded here: the sign swings and the lantern flares (model hook; the placeholder ignores it).
func play_trade() -> void:
	_art_call(&"play_trade", [])


# ---------------------------------------------------------------- internals

## While open: listen to the cargo of every caravan trading here (connected once per caravan).
func _physics_process(delta: float) -> void:
	_trade_poll -= delta
	if _trade_poll > 0.0:
		return
	_trade_poll = TRADE_POLL
	for c in get_tree().get_nodes_in_group(&"caravans"):
		if not is_instance_valid(c) or not c.has_signal(&"cargo_changed"):
			continue
		if c.get(&"trade_state") == TRADING and c.get(&"route_post") == self \
				and not c.is_connected(&"cargo_changed", _on_caravan_cargo):
			c.connect(&"cargo_changed", _on_caravan_cargo)


## The trade ends when the caravan takes its cargo (Caravan._finish_trade, still &"trading" then).
func _on_caravan_cargo(caravan: Node, amount: int) -> void:
	if amount > 0 and caravan != null and is_instance_valid(caravan) \
			and caravan.get(&"trade_state") == TRADING and caravan.get(&"route_post") == self:
		play_trade()


func _apply_held() -> void:
	var color: Variant = null
	if _holder == 0 or _holder == 1:
		color = Unit.team_color(_holder)
	_art_call(&"set_held", [color])
	if _pennant:
		_pennant.visible = color != null
		if color != null:
			(_pennant.material_override as StandardMaterial3D).albedo_color = color


func _art_call(method: StringName, args: Array) -> void:
	if _art and is_instance_valid(_art) and _art.has_method(method):
		_art.callv(method, args)


## An open-sided timber waystation: plank floor, four posts and a pitched roof, a tall signpost mast at the
## front-left corner with a hanging sign (colour per post), a lantern (emissive, no light), crates and a
## hitching rail; a small pennant on the mast shows the holder's colour.
func _build_placeholder() -> void:
	_art = Node3D.new()
	_art.name = "Placeholder"
	add_child(_art)
	var wood := Color(0.45, 0.31, 0.18)
	var dark := Color(0.28, 0.19, 0.11)
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(5.2, 0.3, 4.6)
	_mesh(floor_mesh, Color(0.50, 0.40, 0.28), Vector3(0.0, 0.15, -0.3))
	for x in [-2.3, 2.3]:
		for z in [-2.3, 1.7]:
			var post := BoxMesh.new()
			post.size = Vector3(0.3, 2.8, 0.3)
			_mesh(post, wood, Vector3(x, 1.7, z))
	var roof := PrismMesh.new()
	roof.size = Vector3(5.8, 1.4, 5.0)
	_mesh(roof, Color(0.55, 0.30, 0.18), Vector3(0.0, 3.8, -0.3))
	var mast := CylinderMesh.new()
	mast.top_radius = 0.12
	mast.bottom_radius = 0.16
	mast.height = 5.2
	_mesh(mast, dark, Vector3(-2.6, 2.6, 2.6))
	var arm := BoxMesh.new()
	arm.size = Vector3(1.4, 0.12, 0.12)
	_mesh(arm, dark, Vector3(-2.0, 4.6, 2.6))
	var sign_mesh := BoxMesh.new()
	sign_mesh.size = Vector3(1.0, 0.7, 0.08)
	var c: Color = SIGN_COLORS[clampi(sign_index, 0, SIGN_COLORS.size() - 1)]
	_mesh(sign_mesh, c, Vector3(-1.7, 4.1, 2.6))
	var orb := SphereMesh.new()
	orb.radius = 0.2
	orb.height = 0.4
	var lantern := _mesh(orb, LANTERN_COLOR, Vector3(1.9, 2.4, 1.9))
	var mat := lantern.material_override as StandardMaterial3D
	mat.emission_enabled = true
	mat.emission = LANTERN_COLOR
	mat.emission_energy_multiplier = 2.0
	for i in 3:
		var crate := BoxMesh.new()
		crate.size = Vector3(0.8, 0.8, 0.8)
		_mesh(crate, Color(0.60, 0.46, 0.26), Vector3(1.4 - i * 0.9, 0.7, -2.0 + (i % 2) * 0.4))
	var rail := BoxMesh.new()
	rail.size = Vector3(2.6, 0.1, 0.1)
	_mesh(rail, wood, Vector3(0.6, 0.9, 2.7))
	var flag := BoxMesh.new()
	flag.size = Vector3(0.6, 0.35, 0.04)
	_pennant = _mesh(flag, Color.WHITE, Vector3(-2.25, 5.0, 2.6))
	_pennant.visible = false


func _mesh(mesh: Mesh, color: Color, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if mesh is SphereMesh \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_art.add_child(mi)
	return mi
