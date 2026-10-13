class_name LostCache
extends Node3D
## A Lost Cache (chest) on Crown Hollow (docs/design/items.md "Where items come from"). Hidden until
## `first_delay` seconds after it enters the map (added at match start = 2:00), then a living
## wizard or champion (group "champions", champions.md section 7) of either team walking within
## OPEN_RADIUS opens it: one roll of the loot table (ItemDrops.roll_cache_loot). Essence goes to the
## opener's team (a champion: into its purse, `add_purse`; loot["given"] = "purse"), an item to the
## opener's inventory (or the ground beside the chest). It comes back `reopen_delay` seconds after
## being opened. Group "lost_caches" (the minimap can draw the closed ones).

## `wizard` is the opener: a wizard or a champion.
signal opened(cache: LostCache, wizard: Node, loot: Dictionary)
signal appeared(cache: LostCache)

const OPEN_RADIUS := 2.2
const CHECK_EVERY := 0.2
const BOX_SIZE := Vector3(1.0, 0.7, 0.7)
const LID_H := 0.18
const FADE_TIME := 1.0
const ART_PATH := "res://art/environment/lost_cache.tscn"   ## LostCacheArt (set_open); placeholder if missing.

@export var first_delay := 120.0
@export var reopen_delay := 180.0

var rng := RandomNumberGenerator.new()
## Seconds since the match started (the essence roll grows with it). Set by the map; defaults to
## this cache's own age.
var match_time_source: Callable

var _age := 0.0
var _wait_left := 0.0        # > 0: hidden, counting down to (re)appearing
var _available := false
var _check_left := 0.0
var _lid: Node3D
var _look: Node3D
var _art: Node3D             # the LostCacheArt instance (= _look), null with the placeholder look
var _ring: MeshInstance3D
var _mats: Array[StandardMaterial3D] = []


func _ready() -> void:
	add_to_group("lost_caches")
	_wait_left = first_delay
	_build_look()
	_set_shown(false)


## True while closed and on the map (a wizard walking in opens it).
func is_available() -> bool:
	return _available


## Seconds until it appears again (0 while available).
func time_until_available() -> float:
	return 0.0 if _available else maxf(_wait_left, 0.0)


## Opens the cache for `wizard` (normally by walking in). Returns the loot, {} if closed.
func open_by(wizard: Node) -> Dictionary:
	if not _available or wizard == null:
		return {}
	_available = false
	_wait_left = reopen_delay
	var t: float = float(match_time_source.call()) if match_time_source.is_valid() else _age
	var loot := ItemDrops.roll_cache_loot(rng, t)
	var team := int(wizard.get(&"team"))
	if loot.has("essence") and wizard.has_method(&"add_purse"):
		wizard.call(&"add_purse", int(loot["essence"]))   # a champion keeps it (champions.md 7)
		loot["given"] = "purse"
	elif loot.has("essence"):
		loot["given"] = "essence" if ItemDrops.give_essence(team, int(loot["essence"])) else ""
	else:
		var beside := global_position + Vector3(1.4, 0.0, 0.0)
		var parent := get_parent()
		loot["given"] = ItemDrops.give_item(wizard, StringName(loot["item"]), beside, parent)
	_play_open()
	opened.emit(self, wizard, loot)
	return loot


## Timers, state and loot roll state for the Skirmish save (review W1-4).
func save_world_state() -> Dictionary:
	return {"wait_left": _wait_left, "available": _available, "age": _age, "seed": rng.seed, "rng": rng.state}


## Puts a saved cache back: hidden with its time left, or on the map; the loot rolls go on where they were.
func load_world_state(d: Dictionary) -> void:
	_wait_left = float(d.get("wait_left", _wait_left))
	_age = float(d.get("age", _age))
	if d.has("seed"):
		rng.seed = int(d["seed"])
	if d.has("rng"):
		rng.state = int(d["rng"])
	_available = bool(d.get("available", _available))
	if _available:
		_reset_look()
	else:
		_set_shown(false)


func _physics_process(delta: float) -> void:
	_age += delta
	if not _available:
		_wait_left -= delta
		if _wait_left <= 0.0:
			_available = true
			_reset_look()
			appeared.emit(self)
		return
	_check_left -= delta
	if _check_left > 0.0:
		return
	_check_left = CHECK_EVERY
	for group in [&"heroes", &"enemy_heroes", &"champions"]:
		for node in get_tree().get_nodes_in_group(group):
			var w := node as Node3D
			if w == null or not w.has_method(&"is_alive") or not bool(w.call(&"is_alive")):
				continue
			var d := Vector2(w.global_position.x - global_position.x, w.global_position.z - global_position.z)
			if d.length() <= OPEN_RADIUS:
				open_by(w)
				return


# ---------------------------------------------------------------- look

func _build_look() -> void:
	if ResourceLoader.exists(ART_PATH):
		_art = (load(ART_PATH) as PackedScene).instantiate() as Node3D
	if _art:
		_look = _art
		add_child(_look)
	else:
		_build_placeholder()
	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.4
	torus.outer_radius = 1.5
	torus.rings = 32
	_ring.mesh = torus
	_ring.scale = Vector3(1.0, 0.1, 1.0)
	_ring.position.y = 0.03
	var ring_mat := StandardMaterial3D.new()
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.albedo_color = Color(1.0, 0.85, 0.3, 0.5)
	_ring.material_override = ring_mat
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)


## True if the chest art (LostCacheArt) shows the lid open.
func is_look_open() -> bool:
	return _art != null and bool(_art.call(&"is_open"))


func _build_placeholder() -> void:
	_look = Node3D.new()
	add_child(_look)
	var box := BoxMesh.new()
	box.size = Vector3(BOX_SIZE.x, BOX_SIZE.y - LID_H, BOX_SIZE.z)
	_mesh(_look, box, Color(0.45, 0.30, 0.15), Vector3(0.0, (BOX_SIZE.y - LID_H) * 0.5, 0.0))
	var band := BoxMesh.new()
	band.size = Vector3(BOX_SIZE.x + 0.04, 0.08, BOX_SIZE.z + 0.04)
	_mesh(_look, band, Color(1.0, 0.8, 0.3), Vector3(0.0, (BOX_SIZE.y - LID_H) * 0.6, 0.0))
	# The lid hinges on its -z edge (a pivot there, the lid box toward +z): rotation.x -70 opens it.
	_lid = Node3D.new()
	_lid.position = Vector3(0.0, BOX_SIZE.y - LID_H, -BOX_SIZE.z * 0.5)
	_look.add_child(_lid)
	var lid := BoxMesh.new()
	lid.size = Vector3(BOX_SIZE.x, LID_H, BOX_SIZE.z)
	_mesh(_lid, lid, Color(0.45, 0.30, 0.15), Vector3(0.0, LID_H * 0.5, BOX_SIZE.z * 0.5))


func _mesh(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	_mats.append(mat)
	return mi


func _set_shown(value: bool) -> void:
	_look.visible = value
	_ring.visible = value


func _reset_look() -> void:
	if _art:
		_art.scale = Vector3.ONE
		_art.call(&"set_open", false)
		_set_shown(true)
		return
	_lid.rotation.x = 0.0
	for mat in _mats:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		mat.albedo_color.a = 1.0
	_set_shown(true)


## The lid swings open (-70 degrees) and the chest fades out over 1 s (the art: it opens, then
## shrinks away).
func _play_open() -> void:
	_ring.visible = false
	if _art:
		_art.call(&"set_open", true)
		var t := create_tween()
		t.tween_interval(FADE_TIME * 0.6)
		t.tween_property(_art, "scale", Vector3(0.01, 0.01, 0.01), FADE_TIME * 0.4)
		t.tween_callback(func() -> void:
			if not _available:
				_look.visible = false)
		return
	for mat in _mats:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var tween := create_tween()
	tween.tween_property(_lid, "rotation:x", deg_to_rad(-70.0), 0.3)
	for mat in _mats:
		tween.parallel().tween_property(mat, "albedo_color:a", 0.0, FADE_TIME)
	tween.tween_callback(func() -> void:
		if not _available:
			_look.visible = false)
