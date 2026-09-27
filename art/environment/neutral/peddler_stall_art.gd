class_name PeddlerStallArt
extends Node3D
## Ruin Peddler stall look (docs/design/items.md; polished in task A2.7). Root = the RuinPeddler body origin (its
## collider box 3.2 x 1.8 x 1.8 at (0.4, 0.9, 0)); everything fits inside Pell's mission cage (4.2 x 2.6 x 3.0).
## A merchant's stall set up in a ruin: a timber counter on two old moss-stone blocks under a sloped awning striped
## saffron / cream with a scalloped valance (the "shop" read from the RTS camera), two amber lanterns, glowing
## potions in the three item-tier colours, jars, scrolls, a rolled rug, herb bundles; a patterned rug of wares in
## front (a bronze Warden Scale, a Vital Root, pots, a small chest), barrel and sacks, the peddler's huge travelling
## pack leaning on a broken mossy column, a signpost with a gold coin. Palette = the tavern's (warm timber, moss
## stone, plaster, thatch, gold) + saffron; amber lanterns (1.0, 0.8, 0.4). No real light.
## The peddler: a plump old merchant in a moss robe and a cream apron, straw hat with a feather, big cream beard and
## a saffron scarf. Idle only (no hooks): he breathes, looks around, and every few seconds waves customers over;
## the lanterns sway. Front = +Z (counter side).

const SITE_GROUND := preload("res://art/environment/neutral/site_ground.gd")

var _t: float = 0.0
var _wave_in: float = 3.0
var _wave_t: float = 99.0
var _look_yaw: float = 0.0
var _look_target: float = 0.0
var _look_in: float = 2.0

var _lanterns: Array[Node3D] = []
var _peddler: Node3D
var _body: Node3D
var _head: Node3D
var _arm_r: Node3D
var _arm_l: Node3D
var _arm_r_rest: Vector3
var _arm_l_rest: Vector3


func _ready() -> void:
	for n: String in ["LanternPivot", "LanternPivot2"]:
		var l := get_node_or_null(n) as Node3D
		if l:
			_lanterns.append(l)
	_peddler = get_node("Peddler") as Node3D
	_body = get_node("Peddler/Body") as Node3D
	_head = get_node("Peddler/Head") as Node3D
	_arm_r = get_node("Peddler/ArmR") as Node3D
	_arm_l = get_node("Peddler/ArmL") as Node3D
	_arm_r_rest = _arm_r.rotation
	_arm_l_rest = _arm_l.rotation
	_t = randf() * 10.0
	_wave_in = 2.0 + randf() * 3.0
	# MAP.P2: a trodden-earth patch with a baked contact shadow seats the stall on the map ground; its tongue runs
	# out in front of the counter where the customers stand (shared mesh + material).
	if get_node_or_null(^"SiteGround") == null:
		var g: MeshInstance3D = SITE_GROUND.add(self, "SiteGround", Vector2(1.45, 0.75), 0.55, 1.7, Vector3(0, 0, 1), 1.6, 5)
		g.position.x = 0.35
		move_child(g, 0)


func _process(delta: float) -> void:
	_t += delta
	for i: int in _lanterns.size():
		var l := _lanterns[i]
		l.rotation.z = sin(_t * 1.35 + i * 1.7) * 0.10
		l.rotation.x = sin(_t * 1.05 + 1.0 + i * 2.3) * 0.06
	# Breath + a little bounce on the heels while waving.
	var wave_k := 0.0
	if _wave_t < 1.6:
		_wave_t += delta
		wave_k = sin(PI * clampf(_wave_t / 1.6, 0.0, 1.0))
	else:
		_wave_in -= delta
		if _wave_in <= 0.0:
			_wave_in = 4.0 + randf() * 5.0
			_wave_t = 0.0
	_body.scale = Vector3(1.0 - 0.01 * sin(_t * 1.9), 1.0 + 0.02 * sin(_t * 1.9), 1.0 - 0.01 * sin(_t * 1.9))
	_peddler.position.y = 0.04 * absf(sin(_wave_t * 7.0)) * wave_k
	# Right arm: raised high, waving side to side. Left hand stays on the belly (tiny sway).
	var wave := sin(_wave_t * 11.0) * wave_k
	_arm_r.rotation = _arm_r_rest + Vector3(deg_to_rad(-150.0) * wave_k, 0.0, deg_to_rad(25.0) * wave_k + deg_to_rad(22.0) * wave)
	_arm_l.rotation = _arm_l_rest + Vector3(deg_to_rad(3.0) * sin(_t * 1.9), 0.0, 0.0)
	# Head: glances around (to a new spot every few seconds), faces the customers while waving, nods with the breath.
	_look_in -= delta
	if _look_in <= 0.0:
		_look_in = 1.8 + randf() * 2.5
		_look_target = deg_to_rad(randf_range(-40.0, 40.0))
	var target := lerpf(_look_target, 0.0, wave_k)
	_look_yaw = lerpf(_look_yaw, target, clampf(delta * 3.0, 0.0, 1.0))
	_head.rotation = Vector3(deg_to_rad(4.0) * sin(_t * 1.9) - deg_to_rad(8.0) * wave_k, _look_yaw, deg_to_rad(6.0) * wave)
