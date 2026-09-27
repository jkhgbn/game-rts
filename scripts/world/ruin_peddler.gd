class_name RuinPeddler
extends StaticBody3D
## A neutral shop on Crown Hollow (docs/design/items.md "Where items come from"): team NEUTRAL,
## invulnerable, ignored by every unit (not in "units" / "buildings"), group "shops". Sells
## ShopStock.PEDDLER and combines any recipe for a wizard within ShopStock.SHOP_RADIUS.
## Look: a 1.8 m capsule beside a 2 x 1 x 1.5 cart and a glowing lantern orb. Add it under the
## NavigationRegion3D before the bake (the cart is an obstacle, layer 1 only).

const CART_SIZE := Vector3(2.0, 1.0, 1.5)
const ART_PATH := "res://art/environment/ruin_peddler.tscn"   ## Placeholder shapes if missing.

var team: int = Unit.Team.NEUTRAL
var display_name := "Ruin Peddler"


func _ready() -> void:
	add_to_group("shops")
	add_to_group("peddlers")
	collision_layer = 1
	collision_mask = 0
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.2, 1.8, 1.8)
	col.shape = box
	col.position = Vector3(0.4, 0.9, 0.0)
	add_child(col)

	if ResourceLoader.exists(ART_PATH):
		var art := (load(ART_PATH) as PackedScene).instantiate() as Node3D
		if art:
			art.name = "Art"
			add_child(art)   # RuinPeddlerArt: root = this body's origin; it has the one lantern light
			return
	var body := CapsuleMesh.new()
	body.radius = 0.35
	body.height = 1.8
	_mesh(body, Color(0.60, 0.50, 0.30), Vector3(-0.8, 0.9, 0.0))
	var cart := BoxMesh.new()
	cart.size = CART_SIZE
	_mesh(cart, Color(0.35, 0.25, 0.15), Vector3(0.6, 0.5, 0.0))
	var orb := SphereMesh.new()
	orb.radius = 0.18
	orb.height = 0.36
	var lantern := _mesh(orb, Color(1.0, 0.8, 0.4), Vector3(0.6, 1.9, 0.0))
	var mat := lantern.material_override as StandardMaterial3D
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.8, 0.4)
	mat.emission_energy_multiplier = 2.0


func is_shop() -> bool:
	return true


func is_peddler() -> bool:
	return true


func shop_stock() -> Array[StringName]:
	return ShopStock.peddler()


func is_alive() -> bool:
	return true


## Invulnerable: damage is ignored.
func take_damage(_amount: float, _attacker: Node3D = null) -> void:
	pass


func _mesh(mesh: Mesh, color: Color, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	return mi
