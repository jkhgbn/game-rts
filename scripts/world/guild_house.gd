class_name GuildHouse
extends StaticBody3D
## A neutral guild house at a map corner (docs/design/market-trade.md 2.3, contract section 12): a Magpie Den
## (kind &"den", the Thieves' Guild: bands leave from its door) or a Greywater Lodge (kind &"lodge", the Hunters'
## Guild: trackers leave from its door). The organisations (ThievesGuild / HuntersGuild) run both houses of
## their kind; this node is only the building.
## Team NEUTRAL, invulnerable and never a target (in neither "units" nor "buildings"). Group "guilds";
## clickable (collision layer 2). Its 6 x 6 m body (layer 1, square on the grid) blocks the build grid and the
## navmesh: add it under the NavigationRegion3D before the bake. Turn it so its front (local +Z) faces the road:
## the door is DOOR_DISTANCE (4 m, 1 m outside the face) in front of the centre.
## Opens at 5:00 (the TradeNetwork calls set_open; the guild services have their own OPEN_TIME too).
## Look: res://art/buildings/guilds/magpie_den/magpie_den.tscn or .../greywater_lodge/greywater_lodge.tscn
## (front = local +Z, 6 x 6 centred on the origin; hooks set_open(bool), set_selected(bool), play_band_out() /
## play_contract()) if it exists, else a code placeholder.
## Hooks (10.C9): ThievesGuild._send calls play_band_out() on the Den a band leaves from and HuntersGuild.hire
## calls play_contract() on the Lodge the trackers leave from (so this node does not repeat them on
## band_sent / contract_started). A Den also listens to ThievesGuild.band_sent and plays play_band_out() again
## when one of that band's Magpies comes home and leaves the map at its door (Unit.left_map), at most once per
## BAND_OUT_GAP.

const FOOTPRINT := 6.0
const BODY_HEIGHT := 4.0
const DOOR_DISTANCE := 4.0
const DEN := &"den"
const LODGE := &"lodge"
const ART_PATHS := {
	&"den": "res://art/buildings/guilds/magpie_den/magpie_den.tscn",
	&"lodge": "res://art/buildings/guilds/greywater_lodge/greywater_lodge.tscn",
}
const NAMES := {&"den": "Magpie Den", &"lodge": "Greywater Lodge"}
const GUILD_NAMES := {&"den": "Thieves' Guild", &"lodge": "Hunters' Guild"}
const LANTERN_COLORS := {&"den": Color(0.35, 0.95, 0.85), &"lodge": Color(1.0, 0.72, 0.35)}
const NEUTRAL_TEAM := 2   # Unit.Team.NEUTRAL
const HOME_REACH := 4.0         ## A Magpie leaving the map this close to a Den door went in there.
const BAND_OUT_GAP := 1.5       ## Seconds: a band coming home swings the door once, not once per Magpie.

## &"den" (Magpie Den) or &"lodge" (Greywater Lodge). Set before the node enters the tree.
@export var kind: StringName = DEN

var team: int = NEUTRAL_TEAM
var display_name := ""
var guild_name := ""

var _open := false
var _art: Node3D
var _from_scene := false
var _thieves_guild: Node = null
var _band_out_frame := -1000000   # physics frame of the last play_band_out


func _ready() -> void:
	add_to_group("guilds")
	_link_guild_service.call_deferred()
	display_name = String(NAMES.get(kind, "Guild House"))
	guild_name = String(GUILD_NAMES.get(kind, ""))
	collision_layer = 1 | 2
	collision_mask = 0
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(FOOTPRINT, BODY_HEIGHT, FOOTPRINT)
	col.shape = box
	col.position = Vector3(0.0, BODY_HEIGHT * 0.5, 0.0)
	add_child(col)
	var path := String(ART_PATHS.get(kind, ""))
	if path != "" and ResourceLoader.exists(path):
		var scene := load(path) as PackedScene
		_art = scene.instantiate() as Node3D if scene else null
		if _art:
			_art.name = "Art"
			add_child(_art)
			_from_scene = true
			_art_call(&"set_open", [_open])
			return
	_build_placeholder()


# ---------------------------------------------------------------- public

func is_guild_house() -> bool:
	return true


func is_den() -> bool:
	return kind == DEN


func is_lodge() -> bool:
	return kind == LODGE


func is_alive() -> bool:
	return true


func is_targetable() -> bool:
	return false


func is_invulnerable() -> bool:
	return true


func take_damage(_amount: float, _attacker: Node3D = null) -> void:
	pass


## Where bands / trackers walk out and home (y = 0): DOOR_DISTANCE in front of the centre (local +Z).
func door_point() -> Vector3:
	var p := global_transform * Vector3(0.0, 0.0, DOOR_DISTANCE)
	return Vector3(p.x, 0.0, p.z)


## True from 5:00.
func is_open() -> bool:
	return _open


## TradeNetwork only: opens / closes the doors (forwarded to the model).
func set_open(value: bool) -> void:
	if _open == value:
		return
	_open = value
	_art_call(&"set_open", [value])
	if value:
		_link_guild_service()


func set_selected(value: bool) -> void:
	_art_call(&"set_selected", [value])


## A band leaves (ThievesGuild), or comes home: door swings, dust (model hook).
func play_band_out() -> void:
	_band_out_frame = Engine.get_physics_frames()
	_art_call(&"play_band_out", [])


## A contract starts (HuntersGuild): horn flag raised (model hook).
func play_contract() -> void:
	_art_call(&"play_contract", [])


## The 6 x 6 footprint as world x / z (the minimap square).
func footprint_rect() -> Rect2:
	var half := FOOTPRINT * 0.5
	return Rect2(Vector2(global_position.x - half, global_position.z - half), Vector2(FOOTPRINT, FOOTPRINT))


func distance_to_door(pos: Vector3) -> float:
	var d := door_point()
	return Vector2(pos.x - d.x, pos.z - d.z).length()


func model() -> Node3D:
	return _art


# ---------------------------------------------------------------- internals

## Den only: hears ThievesGuild.band_sent (group "thieves_guild"; retried when the house opens).
func _link_guild_service() -> void:
	if kind != DEN or not is_inside_tree():
		return
	if _thieves_guild != null and is_instance_valid(_thieves_guild):
		return
	var guild := get_tree().get_first_node_in_group(&"thieves_guild")
	if guild == null or not guild.has_signal(&"band_sent"):
		return
	_thieves_guild = guild
	if not guild.is_connected(&"band_sent", _on_band_sent):
		guild.connect(&"band_sent", _on_band_sent)
	if guild.has_method(&"bands"):
		for band in guild.call(&"bands"):
			_on_band_sent(band)


## Watches the band's Magpies: the ones that leave the map at this door went home here.
func _on_band_sent(band: Node) -> void:
	if band == null or not is_instance_valid(band):
		return
	var thieves: Variant = band.get(&"thieves")
	if not thieves is Array:
		return
	for t in thieves:
		if is_instance_valid(t) and t is Node and (t as Node).has_signal(&"left_map") \
				and not (t as Node).is_connected(&"left_map", _on_magpie_left_map):
			(t as Node).connect(&"left_map", _on_magpie_left_map)


func _on_magpie_left_map(unit: Node) -> void:
	if not is_instance_valid(unit) or not unit is Node3D or not is_inside_tree():
		return
	if distance_to_door((unit as Node3D).global_position) > HOME_REACH:
		return
	var gap := int(BAND_OUT_GAP * Engine.physics_ticks_per_second)
	if Engine.get_physics_frames() - _band_out_frame >= gap:
		play_band_out()


func _art_call(method: StringName, args: Array) -> void:
	if _from_scene and _art and is_instance_valid(_art) and _art.has_method(method):
		_art.callv(method, args)


## Den: a crooked tall timber house leaning a little, a magpie weather-vane on the roof peak, black / white
## shutters, a blue-green lantern. Lodge: a long low log hall, a tall stone chimney, a raised watch platform,
## an amber lantern. Emissive lanterns only (no light nodes).
func _build_placeholder() -> void:
	_art = Node3D.new()
	_art.name = "Placeholder"
	add_child(_art)
	var lantern_color: Color = LANTERN_COLORS.get(kind, Color(1.0, 0.8, 0.4))
	if kind == LODGE:
		var hall := BoxMesh.new()
		hall.size = Vector3(5.6, 2.2, 4.4)
		_mesh(hall, Color(0.42, 0.32, 0.22), Vector3(0.0, 1.1, -0.4), Vector3.ZERO)
		var roof := PrismMesh.new()
		roof.size = Vector3(6.0, 1.2, 4.8)
		_mesh(roof, Color(0.36, 0.44, 0.36), Vector3(0.0, 2.8, -0.4), Vector3.ZERO)
		var chimney := BoxMesh.new()
		chimney.size = Vector3(0.9, 5.6, 0.9)
		_mesh(chimney, Color(0.52, 0.52, 0.50), Vector3(2.1, 2.8, -1.6), Vector3.ZERO)
		var deck := BoxMesh.new()
		deck.size = Vector3(1.8, 0.2, 1.4)
		_mesh(deck, Color(0.45, 0.33, 0.20), Vector3(-2.0, 3.4, 1.9), Vector3.ZERO)
		for x in [-2.8, -1.2]:
			var leg := BoxMesh.new()
			leg.size = Vector3(0.18, 3.4, 0.18)
			_mesh(leg, Color(0.35, 0.25, 0.15), Vector3(x, 1.7, 2.5), Vector3.ZERO)
		_lantern(lantern_color, Vector3(0.9, 1.9, 1.95))
	else:
		var tilt := Vector3(0.0, 0.0, 0.05)
		var body := BoxMesh.new()
		body.size = Vector3(4.0, 4.6, 4.0)
		_mesh(body, Color(0.30, 0.26, 0.24), Vector3(0.0, 2.3, -0.4), tilt)
		var roof := PrismMesh.new()
		roof.size = Vector3(4.6, 2.0, 4.4)
		_mesh(roof, Color(0.16, 0.16, 0.18), Vector3(0.12, 5.6, -0.4), tilt)
		var vane := BoxMesh.new()
		vane.size = Vector3(0.08, 1.0, 0.08)
		_mesh(vane, Color(0.2, 0.2, 0.2), Vector3(0.2, 7.0, -0.4), Vector3.ZERO)
		var bird := PrismMesh.new()
		bird.size = Vector3(0.7, 0.35, 0.2)
		_mesh(bird, Color(0.95, 0.95, 0.95), Vector3(0.2, 7.5, -0.4), Vector3(0.0, 0.0, -PI / 2.0))
		for x in [-1.1, 1.1]:
			var shutter := BoxMesh.new()
			shutter.size = Vector3(0.7, 0.9, 0.08)
			_mesh(shutter, Color(0.92, 0.92, 0.90) if x < 0.0 else Color(0.08, 0.08, 0.10),
					Vector3(x, 3.2, 1.65), Vector3.ZERO)
		var crane := BoxMesh.new()
		crane.size = Vector3(0.15, 0.15, 2.0)
		_mesh(crane, Color(0.35, 0.25, 0.15), Vector3(-2.2, 4.0, 0.2), Vector3.ZERO)
		_lantern(lantern_color, Vector3(0.9, 2.1, 1.85))
	var door := BoxMesh.new()
	door.size = Vector3(1.2, 1.9, 0.12)
	_mesh(door, Color(0.20, 0.13, 0.08), Vector3(0.0, 0.95, 1.85), Vector3.ZERO)


func _lantern(color: Color, pos: Vector3) -> void:
	var orb := SphereMesh.new()
	orb.radius = 0.22
	orb.height = 0.44
	var mi := _mesh(orb, color, pos, Vector3.ZERO)
	var mat := mi.material_override as StandardMaterial3D
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _mesh(mesh: Mesh, color: Color, pos: Vector3, rot: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	_art.add_child(mi)
	return mi
