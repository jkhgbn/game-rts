class_name Bounty
extends Node3D
## One bounty flag (docs/design/champions.md section 6). Created, paid and ended by the BountyBoard
## of its team (scripts/world/bounty_board.gd): never `new()` one yourself, call
## `BountyBoard.for_team(team).place(...)`. Group "bounties".
##
## Kinds: HUNT (0) a visible enemy / neutral unit or an enemy building, EXPLORE (1) a ground point,
## GUARD (2) an own completed building or an own-held capture point, ESCORT (3) an own living unit (same
## ints as the flag model's `set_kind`).
## Map fill (map-fill.md 6): an EXPLORE placed within 7 m of a capture point its team does not hold is a
## **Claim** (`is_claim()`, `claim_point`): it pays when that point becomes held by the flag's team, not on
## arrival (flag card `Claim Rookwatch`: `claim_name()`).
##
## Where the flag stands (`global_position` = the flag spot the rules measure from):
## - EXPLORE: on the ground at the point.
## - HUNT: follows the target while the bounty's team sees it (the flag floats small above it);
##   when the target is unseen it stays on the last seen spot, on the ground, full size.
## - ESCORT: follows the unit (small, above it). GUARD: on the building's roof.
## Look: `res://art/buildings/tavern/bounty_flag.tscn` (set_team_color, set_kind) when it exists,
## else a code placeholder (pole, team pennant, spinning gold coin with a kind gem). A gold Label3D
## shows the stake. Clickable: child StaticBody3D "ClickBody" on layer 2 (its parent is the
## Bounty; it also carries meta "bounty").
##
## Visibility: own flags always; for the other team only where its fog says VISIBLE (like a unit),
## see is_visible_to(). The HUNT victim's owner always sees a small coin above the hunted thing.
## The shown / hidden state is applied to the look (the root node stays `visible`): use
## is_shown() / is_visible_to(team).

## Stake, paid part or pursuers changed (flag card, labels).
signal changed
signal pursuer_added(champion: Node3D)
signal pursuer_removed(champion: Node3D)

enum { HUNT, EXPLORE, GUARD, ESCORT }
const KIND_NAMES: Array[String] = ["Hunt", "Explore", "Guard", "Escort"]
## Placeholder gem colour per kind.
const KIND_COLORS: Array[Color] = [Color(0.95, 0.3, 0.25), Color(0.45, 0.85, 1.0),
		Color(0.6, 0.75, 1.0), Color(0.5, 0.95, 0.55)]
const MODEL_PATH := "res://art/buildings/tavern/bounty_flag.tscn"
const GOLD := Color(1.0, 0.85, 0.4)
const VIEW_EVERY := 0.2           ## Seconds between visibility checks.
const LIFTED_SCALE := 0.6         ## Flag size while it floats above a unit.
const POLE_HEIGHT := 1.6
const COIN_RADIUS := 0.35
const COIN_Y := 1.95
const LABEL_Y := 2.8
const CLICK_SIZE := Vector3(0.9, 2.4, 0.9)
const COIN_SPIN := 1.6            ## rad / s
## GUARD on a capture point: the flag stands on top of its model (map-fill.md 4.2 heights).
const POINT_TOPS := {&"watchtower": 9.0, &"well": 1.6, &"shrine": 2.2}

## Owner (Unit.Team).
var team: int = 0
var kind: int = EXPLORE
## The hunted / guarded / escorted thing (null for EXPLORE). Check is_instance_valid before use.
var target: Node3D = null
## EXPLORE only: the capture point this flag claims (null = a plain Explore). Check is_instance_valid.
var claim_point: Node3D = null
## Essence put on it (already taken from the bank).
var stake := 0
## Essence already paid out to champions.
var paid := 0
## Own champions that took this bounty (their brain calls add_pursuer / remove_pursuer).
var pursuers: Array = []
## Seconds since it was placed.
var elapsed := 0.0
## HUNT: seconds the target has been unseen by `team` (0 while seen).
var unseen_time := 0.0
## HUNT: where the target was last seen by `team`.
var last_seen_pos := Vector3.ZERO
## GUARD / ESCORT: service ticks already paid (max BountyBoard.SERVICE_TICKS).
var ticks_paid := 0
## GUARD / ESCORT: 10 s ticks already checked (paid or kept).
var ticks_done := 0
## Champion instance id -> essence it received from this bounty.
var paid_to: Dictionary = {}
## HUNT: champion instance id -> board clock of its last hit on the target.
var hit_times: Dictionary = {}
## Champion instance ids already announced as "took your bounty".
var announced: Dictionary = {}
var ended := false
var end_reason: StringName = &""

var _tracking := false            # HUNT: the target is seen now (the flag follows it)
var _view_left := 0.0
var _shown := true
var _look: Node3D
var _spin: Node3D                 # placeholder coin (spins)
var _label: Label3D
var _click: StaticBody3D
var _owner_mark: Node3D           # HUNT: coin above the target for its owner
var _mark_spin: Node3D

static var _model_scene: PackedScene
static var _model_checked := false
static var _pole_mesh: CylinderMesh
static var _coin_mesh: CylinderMesh
static var _pennant_mesh: BoxMesh
static var _gem_mesh: BoxMesh
static var _pole_mat: StandardMaterial3D
static var _coin_mat: StandardMaterial3D
static var _kind_mats: Dictionary = {}   # int kind -> StandardMaterial3D
static var _team_mats: Dictionary = {}   # String colour html -> StandardMaterial3D


## BountyBoard only: fills the bounty before it enters the tree.
func setup(p_team: int, p_kind: int, p_target: Node3D, p_stake: int, pos: Vector3) -> void:
	team = p_team
	kind = p_kind
	target = p_target
	stake = p_stake
	position = Vector3(pos.x, 0.0, pos.z)
	last_seen_pos = position
	_tracking = kind == HUNT


func _ready() -> void:
	add_to_group("bounties")
	_build_look()
	_apply_mode()
	_update_label()
	_update_view()


func _process(delta: float) -> void:
	if ended:
		return
	if _spin:
		_spin.rotate_y(COIN_SPIN * delta)
	if _mark_spin:
		_mark_spin.rotate_y(COIN_SPIN * delta)
	_follow()
	_view_left -= delta
	if _view_left <= 0.0:
		_view_left = VIEW_EVERY
		_update_view()


# ---------------------------------------------------------------- public API

## Still active: not ended, and its target (HUNT / GUARD / ESCORT) exists and lives.
func is_valid() -> bool:
	if ended or not is_inside_tree():
		return false
	return kind == EXPLORE or _target_alive()


## Seconds before it runs out: GUARD / ESCORT until the 180 s expiry, HUNT while the target is unseen
## (60 s countdown). -1 = no timer (EXPLORE, HUNT on a seen target).
func time_left() -> float:
	match kind:
		GUARD, ESCORT:
			return maxf(BountyBoard.SERVICE_EXPIRY - elapsed, 0.0)
		HUNT:
			if unseen_time > 0.0:
				return maxf(BountyBoard.HUNT_UNSEEN_EXPIRY - unseen_time, 0.0)
	return -1.0


## Essence not paid out yet.
func unpaid() -> int:
	return maxi(stake - paid, 0)


func add_pursuer(champion: Node3D) -> void:
	if champion == null or not is_instance_valid(champion) or pursuers.has(champion) or ended:
		return
	pursuers.append(champion)
	pursuer_added.emit(champion)
	changed.emit()


func remove_pursuer(champion: Node3D) -> void:
	if not pursuers.has(champion):
		return
	pursuers.erase(champion)
	pursuer_removed.emit(champion)
	changed.emit()


## The pursuers that still count: valid, alive, of this team (dead / freed ones are dropped).
func active_pursuers() -> Array:
	var out: Array = []
	for ch: Variant in pursuers.duplicate():
		if ch == null or not is_instance_valid(ch):
			pursuers.erase(ch)
			continue
		var node := ch as Node3D
		if node == null or node.get(&"team") == null or int(node.get(&"team")) != team:
			continue
		if node.has_method(&"is_alive") and not bool(node.call(&"is_alive")):
			continue
		out.append(node)
	return out


## What BountyBoard.remove() would give back now (100 % without pursuers, else 50 %).
func refund_preview() -> int:
	var rest := unpaid()
	if active_pursuers().is_empty():
		return rest
	return rest - rest / 2


## True while a HUNT target is seen by the bounty's team (the flag follows it).
func is_tracking() -> bool:
	return _tracking


## True when team `t` may see this flag now (world and minimap): own flags always; others only where
## `t`'s fog is VISIBLE (fog off: always). A HUNT flag above a seen target is always seen by the
## target's owner.
func is_visible_to(t: int) -> bool:
	if ended:
		return false
	if t == team:
		return true
	var fog := FogOfWar.find()
	if fog == null or not fog.enabled:
		return true
	if kind == HUNT and _tracking and _target_alive() and target.get(&"team") != null \
			and int(target.get(&"team")) == t:
		return true
	return fog.is_visible(t, global_position)


## Whether the flag is drawn for the local team right now.
func is_shown() -> bool:
	return _shown


## The kind's name ("Hunt", "Explore", "Guard", "Escort"; "Claim" for a claim).
func kind_name() -> String:
	if is_claim():
		return "Claim"
	return KIND_NAMES[kind] if kind >= 0 and kind < KIND_NAMES.size() else "?"


## True for an EXPLORE flag that claims a capture point (paid when the point becomes held by `team`).
func is_claim() -> bool:
	return kind == EXPLORE and claim_point != null and is_instance_valid(claim_point)


## The claimed point's name ("Rookwatch"), "" when this is not a claim.
func claim_name() -> String:
	return BountyBoard.name_of(claim_point) if is_claim() else ""


## The target's name for messages and the flag card ("" for a plain EXPLORE; the point's name for a claim).
func target_name() -> String:
	if kind == EXPLORE:
		return claim_name()
	return BountyBoard.name_of(target) if _target_valid() else ""


## BountyBoard only: HUNT sighting update (`seen` by the team this check, `dt` seconds since the last).
func set_sighting(seen: bool, dt: float) -> void:
	if seen and _target_valid():
		unseen_time = 0.0
		last_seen_pos = Vector3(target.global_position.x, 0.0, target.global_position.z)
		if not _tracking:
			_tracking = true
			_apply_mode()
	else:
		unseen_time += dt
		if _tracking:
			_tracking = false
			global_position = last_seen_pos
			_apply_mode()


## BountyBoard only: stake / paid / pursuers changed.
func notify_changed() -> void:
	_update_label()
	changed.emit()


## BountyBoard only: the bounty is over; it leaves the group and frees itself.
func finish(reason: StringName) -> void:
	if ended:
		return
	ended = true
	end_reason = reason
	remove_from_group("bounties")
	if _click:
		_click.collision_layer = 0
	target = null
	queue_free()


# ---------------------------------------------------------------- internals

func _target_valid() -> bool:
	return target != null and is_instance_valid(target)


func _target_alive() -> bool:
	if not _target_valid():
		return false
	return not target.has_method(&"is_alive") or bool(target.call(&"is_alive"))


func _lifted() -> bool:
	return kind == ESCORT or kind == GUARD or (kind == HUNT and _tracking)


func _follow() -> void:
	if not _target_alive():
		return
	var p := target.global_position
	if kind == ESCORT or (kind == HUNT and _tracking):
		global_position = Vector3(p.x, 0.0, p.z)
	if _owner_mark and _owner_mark.visible:
		_owner_mark.global_position = Vector3(p.x, _target_top(), p.z)


## Height above the target's feet where a lifted flag stands.
func _target_top() -> float:
	if not _target_valid():
		return 0.0
	var b := target as Building
	if b:
		return (b.building_type.height if b.building_type else 2.0) + 0.3
	if target.is_in_group(&"capture_points"):   # GUARD on a point: above its model
		return float(POINT_TOPS.get(StringName(str(target.get(&"kind"))), 2.0)) + 0.3
	var h: Variant = target.get(&"body_height")
	return (float(h) if h != null else 1.6) + 0.7


func _apply_mode() -> void:
	if _look == null:
		return
	var lift := _target_top() if _lifted() else 0.0
	var s := LIFTED_SCALE if _lifted() and kind != GUARD else 1.0
	_look.position.y = lift
	_look.scale = Vector3.ONE * s
	for m in _look.get_children():
		if m.has_method(&"set_grounded"):
			m.call(&"set_grounded", not _lifted())
	_label.position.y = lift + LABEL_Y * s
	_click.position.y = lift + CLICK_SIZE.y * 0.5 * s
	if kind == GUARD and _target_valid():
		global_position = Vector3(target.global_position.x, 0.0, target.global_position.z)


func _update_label() -> void:
	if _label:
		_label.text = str(stake)


func _local_team() -> int:
	var fog := FogOfWar.find()
	return fog.local_team if fog else Unit.Team.PLAYER


func _update_view() -> void:
	var local := _local_team()
	var vis := is_visible_to(local)
	if vis != _shown:
		_shown = vis
		_look.visible = vis
		_label.visible = vis
		_click.collision_layer = 2 if vis else 0
	if _owner_mark:
		var owner_sees := kind == HUNT and not _tracking and local != team and _target_alive() \
				and target.get(&"team") != null and int(target.get(&"team")) == local
		if _owner_mark.visible != owner_sees:
			_owner_mark.visible = owner_sees
			if owner_sees:
				_follow()


# ---------------------------------------------------------------- look

func _build_look() -> void:
	_look = Node3D.new()
	_look.name = "Look"
	add_child(_look)
	var color := BountyBoard.team_color(team)
	var model := _load_model()
	if model:
		var inst := model.instantiate() as Node3D
		if inst:
			_look.add_child(inst)
			if inst.has_method(&"set_team_color"):
				inst.call(&"set_team_color", color)
			if inst.has_method(&"set_kind"):
				inst.call(&"set_kind", kind)
	if _look.get_child_count() == 0:
		_spin = _build_placeholder(_look, color)
	_label = Label3D.new()
	_label.name = "Stake"
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.modulate = GOLD
	_label.outline_modulate = Color.BLACK
	_label.outline_size = 8
	_label.font_size = 40
	_label.pixel_size = 0.006
	add_child(_label)
	_click = StaticBody3D.new()
	_click.name = "ClickBody"
	_click.collision_layer = 2
	_click.collision_mask = 0
	_click.set_meta(&"bounty", self)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = CLICK_SIZE
	shape.shape = box
	_click.add_child(shape)
	add_child(_click)
	if kind == HUNT:
		_owner_mark = Node3D.new()
		_owner_mark.name = "OwnerMark"
		_owner_mark.top_level = true
		_owner_mark.visible = false
		add_child(_owner_mark)
		_mark_spin = _coin(_owner_mark, 0.0)
		_mark_spin.scale = Vector3.ONE * 0.6


static func _load_model() -> PackedScene:
	if not _model_checked:
		_model_checked = true
		if ResourceLoader.exists(MODEL_PATH):
			_model_scene = load(MODEL_PATH) as PackedScene
	return _model_scene


## Pole + team pennant + spinning coin with a kind gem. Returns the coin pivot (spins).
func _build_placeholder(parent: Node3D, color: Color) -> Node3D:
	_ensure_shared()
	var pole := MeshInstance3D.new()
	pole.mesh = _pole_mesh
	pole.material_override = _pole_mat
	pole.position.y = POLE_HEIGHT * 0.5
	pole.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(pole)
	var pennant := MeshInstance3D.new()
	pennant.mesh = _pennant_mesh
	pennant.material_override = _team_mat(color)
	pennant.position = Vector3(0.3, POLE_HEIGHT - 0.2, 0.0)
	pennant.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(pennant)
	return _coin(parent, COIN_Y)


## A gold coin (edge up, so it reads while spinning) with the kind gem; returns its pivot.
func _coin(parent: Node3D, y: float) -> Node3D:
	_ensure_shared()
	var pivot := Node3D.new()
	pivot.name = "Coin"
	pivot.position.y = y
	parent.add_child(pivot)
	var coin := MeshInstance3D.new()
	coin.mesh = _coin_mesh
	coin.material_override = _coin_mat
	coin.rotation.x = PI * 0.5
	coin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pivot.add_child(coin)
	var gem := MeshInstance3D.new()
	gem.mesh = _gem_mesh
	gem.material_override = _kind_mat(kind)
	gem.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pivot.add_child(gem)
	return pivot


static func _ensure_shared() -> void:
	if _pole_mesh:
		return
	_pole_mesh = CylinderMesh.new()
	_pole_mesh.top_radius = 0.035
	_pole_mesh.bottom_radius = 0.045
	_pole_mesh.height = POLE_HEIGHT
	_pole_mesh.radial_segments = 8
	_coin_mesh = CylinderMesh.new()
	_coin_mesh.top_radius = COIN_RADIUS
	_coin_mesh.bottom_radius = COIN_RADIUS
	_coin_mesh.height = 0.06
	_coin_mesh.radial_segments = 20
	_pennant_mesh = BoxMesh.new()
	_pennant_mesh.size = Vector3(0.55, 0.32, 0.03)
	_gem_mesh = BoxMesh.new()
	_gem_mesh.size = Vector3(0.16, 0.16, 0.1)
	_pole_mat = StandardMaterial3D.new()
	_pole_mat.albedo_color = Color(0.36, 0.24, 0.12)
	_pole_mat.roughness = 0.9
	_coin_mat = StandardMaterial3D.new()
	_coin_mat.albedo_color = GOLD
	_coin_mat.metallic = 0.6
	_coin_mat.roughness = 0.35
	_coin_mat.emission_enabled = true
	_coin_mat.emission = GOLD
	_coin_mat.emission_energy_multiplier = 0.6


static func _kind_mat(k: int) -> StandardMaterial3D:
	if not _kind_mats.has(k):
		var c: Color = KIND_COLORS[clampi(k, 0, KIND_COLORS.size() - 1)]
		var mat := StandardMaterial3D.new()
		mat.albedo_color = c
		mat.emission_enabled = true
		mat.emission = c
		mat.emission_energy_multiplier = 1.2
		_kind_mats[k] = mat
	return _kind_mats[k]


static func _team_mat(c: Color) -> StandardMaterial3D:
	var key := c.to_html()
	if not _team_mats.has(key):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = c
		mat.roughness = 0.8
		_team_mats[key] = mat
	return _team_mats[key]
