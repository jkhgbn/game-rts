class_name LootSack
extends Node3D
## A sack of stolen gold on the ground (docs/design/market-trade.md 5.4, contract section 12). Dropped when a
## Magpie dies with loot (all of it) or a loaded caravan dies (50 % of its cargo): `LootSack.spawn(...)`.
## Group "loot_sacks".
## - Pickup: every CHECK_INTERVAL the nearest living unit within PICKUP_RADIUS (2 m, flat) takes it: a PLAYER /
##   ENEMY unit (soldier, worker, caravan, wizard, champion, tracker) -> that team's gold (GoldBank in group
##   "gold_banks", `add(n, &"loot")`); a Magpie (group "magpies") -> its carried loot (meta &"loot", max 60 per
##   Magpie: the rest stays in the sack). Other neutral units never take it. `take(by)` does the same on demand.
## - Lifetime: LIFETIME (45 s), then it fades (lost).
## - Shown only in cells the local player sees (fog of war), like enemy units.
## - `picked(sack, team, amount)` (team NEUTRAL for a Magpie); the TradeNetwork is told too (loot_picked).
## Look: res://art/vfx/trade_loot_sack.tscn if it exists, else a code placeholder (burlap sack, coin spill, slow bob).
## The art reads this node by itself (amount, time_left, is_available) and bobs itself (`bobs_itself()`): the
## code bob (_process) only runs for the placeholder.

signal picked(sack: LootSack, team: int, amount: int)

const LIFETIME := 45.0
const PICKUP_RADIUS := 2.0
const CHECK_INTERVAL := 0.25
const MAX_SACKS := 6                  ## Perf budget: a 7th sack makes the oldest one fade.
const MAGPIE_LOOT_MAX := 60
const FADE_TIME := 0.5
const PICKUP_FADE_TIME := 0.2
const BOB_HEIGHT := 0.08
const BOB_SPEED := 2.2
const ART_PATH := "res://art/vfx/trade_loot_sack.tscn"
const GOLD_COLOR := Color(1.0, 0.85, 0.3)
const PLAYER_TEAM := 0
const ENEMY_TEAM := 1
const NEUTRAL_TEAM := 2
const LOCAL_TEAM := 0                 ## Whose fog hides it.

## Gold in the sack.
var amount: int = 0

var _age := 0.0
var _check_left := 0.0
var _gone := false
var _visual: Node3D


## Drops a sack of `gold` at `pos` (y 0) under `parent`; null when gold < 1.
static func spawn(parent: Node, pos: Vector3, gold: int) -> LootSack:
	if parent == null or gold < 1:
		return null
	if parent.is_inside_tree():
		var alive: Array = parent.get_tree().get_nodes_in_group(&"loot_sacks")
		if alive.size() >= MAX_SACKS:
			var oldest: LootSack = null
			for s in alive:
				var sack := s as LootSack
				if sack and (oldest == null or sack.age() > oldest.age()):
					oldest = sack
			if oldest:
				oldest.expire()
	var sack := LootSack.new()
	sack.name = "LootSack"
	sack.amount = gold
	sack.position = Vector3(pos.x, 0.0, pos.z)
	parent.add_child(sack, true)
	if sack.is_inside_tree():
		sack.global_position = Vector3(pos.x, 0.0, pos.z)
	return sack


func _ready() -> void:
	add_to_group("loot_sacks")
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	var art: Node3D = null
	if ResourceLoader.exists(ART_PATH):
		var scene := load(ART_PATH) as PackedScene
		art = scene.instantiate() as Node3D if scene else null
	if art:
		art.name = "Art"
		_visual.add_child(art)
		# The art bobs its own sack (the coin spill stays on the ground): no second bob here.
		if art.has_method(&"bobs_itself") and bool(art.call(&"bobs_itself")):
			set_process(false)
	else:
		_build_placeholder()
	_update_visibility()


func _physics_process(delta: float) -> void:
	if _gone:
		return
	_age += delta
	if _age >= LIFETIME:
		expire()
		return
	_check_left -= delta
	if _check_left > 0.0:
		return
	_check_left = CHECK_INTERVAL
	_update_visibility()
	var taker := _find_taker()
	if taker:
		take(taker)


func _process(_delta: float) -> void:
	if _visual and not _gone and visible:
		_visual.position.y = BOB_HEIGHT * (1.0 + sin(_age * BOB_SPEED))


# ---------------------------------------------------------------- public

## `by` takes the sack: a PLAYER / ENEMY unit adds all of it to its team's gold, a Magpie adds up to its
## carry room (60) to its loot. Returns the gold taken (0: gone already, or `by` can't take it).
func take(by: Node3D) -> int:
	if _gone or amount <= 0 or by == null or not is_instance_valid(by):
		return 0
	var team_v: Variant = by.get(&"team")
	var team := int(team_v) if team_v != null else -1
	var got := 0
	if by.is_in_group(&"magpies"):
		var carried := int(by.get_meta(&"loot", 0))
		var room := MAGPIE_LOOT_MAX - carried
		if room <= 0:
			return 0
		got = mini(room, amount)
		by.set_meta(&"loot", carried + got)
		_model_call(by, &"set_carrying", [true])
		team = NEUTRAL_TEAM
	elif team == PLAYER_TEAM or team == ENEMY_TEAM:
		got = amount
		var bank := _gold_bank(team)
		if bank:
			bank.call(&"add", got, &"loot")
	else:
		return 0
	amount -= got
	picked.emit(self, team, got)
	var net := TradeNetwork.instance(get_tree()) if is_inside_tree() else null
	if net:
		net.record_loot_pickup(team, got, self)
	_play_vfx(&"sack_pickup", by)
	if amount <= 0:
		_finish(PICKUP_FADE_TIME)
	return got


## Seconds since it was dropped.
func age() -> float:
	return _age


## Seconds until it fades (0 once gone).
func time_left() -> float:
	return 0.0 if _gone else maxf(0.0, LIFETIME - _age)


## True while it can still be picked up.
func is_available() -> bool:
	return not _gone and amount > 0


## Fades now (lost). Used at LIFETIME and when too many sacks lie around.
func expire() -> void:
	if _gone:
		return
	amount = 0
	_finish(FADE_TIME)


# ---------------------------------------------------------------- internals

func _find_taker() -> Node3D:
	var best: Node3D = null
	var best_d := PICKUP_RADIUS * PICKUP_RADIUS
	var me := global_position
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u == null or not u.is_alive():
			continue
		var t := int(u.team)
		if t != PLAYER_TEAM and t != ENEMY_TEAM:
			if not u.is_in_group(&"magpies") or int(u.get_meta(&"loot", 0)) >= MAGPIE_LOOT_MAX:
				continue
		var p := u.global_position
		var d := (p.x - me.x) * (p.x - me.x) + (p.z - me.z) * (p.z - me.z)
		if d <= best_d:
			best_d = d
			best = u
	return best


func _gold_bank(team: int) -> Node:
	for bank in get_tree().get_nodes_in_group(&"gold_banks"):
		var t: Variant = bank.get(&"team")
		if t != null and int(t) == team and bank.has_method(&"add"):
			return bank
	return null


func _finish(fade: float) -> void:
	_gone = true
	remove_from_group(&"loot_sacks")
	set_physics_process(false)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), fade)
	tween.tween_callback(queue_free)


func _update_visibility() -> void:
	var fog := FogOfWar.find() if is_inside_tree() else null
	visible = fog == null or not fog.enabled or fog.is_visible(LOCAL_TEAM, global_position)


func _play_vfx(id: StringName, target: Node3D) -> void:
	var vfx := get_tree().get_first_node_in_group(&"trade_vfx")
	if vfx and vfx.has_method(&"play"):
		vfx.call(&"play", id, global_position, target)


static func _model_call(unit: Node, method: StringName, args: Array) -> void:
	if not unit.has_method(&"get_model"):
		return
	var m: Variant = unit.call(&"get_model")
	if m is Object and is_instance_valid(m) and (m as Object).has_method(method):
		(m as Object).callv(method, args)


## A 0.5 m burlap sack tied at the neck, a few coins spilled beside it, a faint gold rim (emissive coins).
func _build_placeholder() -> void:
	var sack := SphereMesh.new()
	sack.radius = 0.26
	sack.height = 0.46
	_mesh(sack, Color(0.62, 0.50, 0.32), Vector3(0.0, 0.23, 0.0), false)
	var neck := CylinderMesh.new()
	neck.top_radius = 0.06
	neck.bottom_radius = 0.1
	neck.height = 0.16
	_mesh(neck, Color(0.50, 0.40, 0.25), Vector3(0.0, 0.5, 0.0), false)
	var coin := CylinderMesh.new()
	coin.top_radius = 0.06
	coin.bottom_radius = 0.06
	coin.height = 0.02
	for i in 4:
		var a := 0.6 + i * 0.5
		_mesh(coin, GOLD_COLOR, Vector3(cos(a) * (0.32 + i * 0.05), 0.02, sin(a) * (0.32 + i * 0.05)), true)


func _mesh(mesh: Mesh, color: Color, pos: Vector3, glow: bool) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	if glow:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.2
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_visual.add_child(mi)
