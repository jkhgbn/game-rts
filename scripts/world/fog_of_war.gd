class_name FogOfWar
extends Node
## Fog of war (docs/design/fog-of-war.md). One node per level (group "fog", `main.fog`).
## - A 60 x 60 grid of 2 m cells per team (PLAYER and ENEMY; NEUTRAL has no fog), cell i covers
##   x in [2i, 2i + 2), i in -30..29 (the BuildGrid cells). States UNEXPLORED / EXPLORED / VISIBLE.
## - Updated at 5 Hz per team (the two teams alternate every 0.1 s): the "visible now" layer is
##   cleared, then every living unit / building of the team stamps a circle of its sight radius
##   (precomputed row spans; one stamp per cell and radius per pass). Stamping also marks "explored".
##   Nodes in group "fog_sources" (SightMarker, champions) with `team` + `sight_radius` stamp too.
## - For the local team (PLAYER): enemy and neutral units / buildings outside VISIBLE cells get
##   `visible = false` (they stay in their groups and keep simulating); enemy buildings seen once leave
##   a grey ghost (group "fog_ghosts") until their area is seen again; crystal nodes and the artifact
##   show once explored. A world-space overlay (a big box whose shader reads the depth buffer and
##   samples the grid) darkens unexplored (alpha 1) and explored (alpha 0.55) ground.
## - F11 toggles the fog (enabled = false: everything visible, for every team).

signal updated   ## After each team pass (5 Hz per team). The minimap redraws on it.

enum { UNEXPLORED, EXPLORED, VISIBLE }

const CELL := 2.0
const SIZE := 60
const HALF := 30
const CELLS := SIZE * SIZE
const MAP_HALF := CELL * HALF          ## 60 m.
const TICK := 0.1                      ## One team pass per tick, so each team updates at 5 Hz.
const START_REVEAL := 20.0             ## Explored circle around a team's start (fog-of-war.md).
const EXPLORED_ALPHA := 0.55
const GHOST_COLOR := Color(0.5, 0.5, 0.55, 0.5)
const GRID_BYTES := [0, 140, 255]      ## grid_image() values per state.

## Sight in metres by UnitType id (fog-of-war.md), used when the UnitType has no sight_radius.
const UNIT_SIGHT := {
	&"cinder_hand": 8.0, &"gloom_thrall": 8.0,
	&"flame_guard": 10.0, &"shade": 10.0,
	&"ember_archer": 12.0, &"nightbolt": 12.0, &"blaze_rider": 12.0, &"grave_hound": 12.0,
	&"shadow_knight": 11.0, &"ash_hurler": 14.0,
	# Ice (same as the Fire / Shadow unit of the same role).
	&"rime_hauler": 8.0, &"rimeshield": 10.0, &"shardcaster": 12.0, &"rime_seer": 12.0, &"rime_colossus": 11.0,
}
const WIZARD_SIGHT := 14.0
const DEFAULT_UNIT_SIGHT := 10.0
## By BuildingType id suffix, used when the BuildingType's sight_radius is 0.
const BUILDING_SIGHT := {&"keep": 16.0, &"barracks": 12.0, &"hearth": 8.0, &"hovel": 8.0, &"tower": 16.0}
const DEFAULT_BUILDING_SIGHT := 12.0
const SITE_SIGHT := 6.0

var enabled := true: set = set_enabled
var local_team: int = Unit.Team.PLAYER   ## Whose view is drawn and hides the others.

# Per team: 255 = visible now / explored. Separate members (packed arrays are copied on write when
# taken out of a container, so every write goes straight to a member).
var _vis_p := PackedByteArray()
var _exp_p := PackedByteArray()
var _vis_e := PackedByteArray()
var _exp_e := PackedByteArray()
var _mark_tick := PackedInt32Array()   # per cell: pass id of the last stamp centred here...
var _mark_r := PackedInt32Array()      # ...and its radius key (skip smaller or equal stamps)
var _pass_id := 0
var _tick_left := 0.0
var _next_team := 0
var _spans := {}                       # radius key (decimetres) -> PackedInt32Array half widths
var _grid_images := {}                 # team -> Image (grid_image cache)
var _grid_image_pass := {}             # team -> pass id it was built at
var _team_pass := [0, 0]               # pass id of the last update of each team

var _seen := {}                        # enemy building instance id -> true (seen at least once)
var _ghosts := {}                      # building instance id -> {node, pos, half}
var _ghost_mat: StandardMaterial3D
var _overlay: MeshInstance3D
var _overlay_mat: ShaderMaterial
var _img_vis: Image
var _img_exp: Image
var _tex_vis: ImageTexture
var _tex_exp: ImageTexture


func _ready() -> void:
	add_to_group("fog")
	_vis_p.resize(CELLS)
	_exp_p.resize(CELLS)
	_vis_e.resize(CELLS)
	_exp_e.resize(CELLS)
	_vis_p.fill(0)
	_exp_p.fill(0)
	_vis_e.fill(0)
	_exp_e.fill(0)
	_mark_tick.resize(CELLS)
	_mark_tick.fill(-1)
	_mark_r.resize(CELLS)
	_ghost_mat = StandardMaterial3D.new()
	_ghost_mat.albedo_color = GHOST_COLOR
	_ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_build_overlay()


## The FogOfWar of the current level, or null.
static func find() -> FogOfWar:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.get_first_node_in_group("fog") as FogOfWar if tree else null


# ---------------------------------------------------------------- public API

func set_enabled(value: bool) -> void:
	enabled = value
	if _overlay:
		_overlay.visible = value
	if is_inside_tree():
		_apply_local_view()
		updated.emit()


## UNEXPLORED (0), EXPLORED (1) or VISIBLE (2) for `team` at `world_pos` (clamped to the map).
## Fog off, or a team without fog (NEUTRAL): always VISIBLE.
func state_at(team: int, world_pos: Vector3) -> int:
	if not enabled or (team != Unit.Team.PLAYER and team != Unit.Team.ENEMY):
		return VISIBLE
	var idx := _index(world_pos)
	if team == Unit.Team.PLAYER:
		return VISIBLE if _vis_p[idx] != 0 else (EXPLORED if _exp_p[idx] != 0 else UNEXPLORED)
	return VISIBLE if _vis_e[idx] != 0 else (EXPLORED if _exp_e[idx] != 0 else UNEXPLORED)


func is_visible(team: int, world_pos: Vector3) -> bool:
	return state_at(team, world_pos) == VISIBLE


func is_explored(team: int, world_pos: Vector3) -> bool:
	return state_at(team, world_pos) != UNEXPLORED


## Spec-style shortcuts for the local team (fog-of-war.md "Public API").
func get_state(world_pos: Vector3) -> int:
	return state_at(local_team, world_pos)


## The team's grid as a 60 x 60 R8 image: 0 unexplored, 140 explored, 255 visible; pixel (i, j) is
## the cell at x in [2(i - 30), ...), z in [2(j - 30), ...). Rebuilt at most once per update; don't
## modify it. Fog off: all 255.
func grid_image(team: int) -> Image:
	var img: Image = _grid_images.get(team)
	if img == null:
		img = Image.create_empty(SIZE, SIZE, false, Image.FORMAT_R8)
		_grid_images[team] = img
		_grid_image_pass[team] = -2
	var stamp: int = _team_pass[team] if team == Unit.Team.PLAYER or team == Unit.Team.ENEMY else 0
	var key: int = stamp if enabled else -1
	if int(_grid_image_pass[team]) == key:
		return img
	_grid_image_pass[team] = key
	var data := PackedByteArray()
	data.resize(CELLS)
	if key == -1 or (team != Unit.Team.PLAYER and team != Unit.Team.ENEMY):
		data.fill(255)
	elif team == Unit.Team.PLAYER:
		for i in CELLS:
			data[i] = 255 if _vis_p[i] != 0 else (140 if _exp_p[i] != 0 else 0)
	else:
		for i in CELLS:
			data[i] = 255 if _vis_e[i] != 0 else (140 if _exp_e[i] != 0 else 0)
	img.set_data(SIZE, SIZE, false, Image.FORMAT_R8, data)
	return img


## Marks a circle as explored for `team` (the start circle; scouting effects later).
func reveal(team: int, world_pos: Vector3, radius: float) -> void:
	if team != Unit.Team.PLAYER and team != Unit.Team.ENEMY:
		return
	var spans := _spans_for(radius)
	var r := (spans.size() - 1) / 2
	var cx := clampi(floori(world_pos.x / CELL) + HALF, 0, SIZE - 1)
	var cz := clampi(floori(world_pos.z / CELL) + HALF, 0, SIZE - 1)
	for dz in range(-r, r + 1):
		var z := cz + dz
		if z < 0 or z >= SIZE:
			continue
		var w := spans[dz + r]
		for x in range(maxi(cx - w, 0), mini(cx + w, SIZE - 1) + 1):
			if team == Unit.Team.PLAYER:
				_exp_p[x + z * SIZE] = 255
			else:
				_exp_e[x + z * SIZE] = 255
	if team == local_team:
		_upload()


## Sight radius (m) of a unit or building (0 = reveals nothing: dead, projectiles...).
static func sight_of(node: Node) -> float:
	var u := node as Unit
	if u:
		if not u.is_alive():
			return 0.0
		var sight := WIZARD_SIGHT if u is Wizard else DEFAULT_UNIT_SIGHT
		if u.unit_type:
			if &"sight_radius" in u.unit_type and float(u.unit_type.get(&"sight_radius")) > 0.0:
				sight = float(u.unit_type.get(&"sight_radius"))
			else:
				sight = float(UNIT_SIGHT.get(u.unit_type.id, DEFAULT_UNIT_SIGHT))
		return minf(sight, u.status_sight_cap())   # caster-units.md 3.5: `hazed` caps sight at 4 m
	var b := node as Building
	if b:
		if not b.is_alive():
			return 0.0
		if not b.is_constructed():
			return SITE_SIGHT
		if b.building_type:
			if b.building_type.sight_radius > 0.0:
				return b.building_type.sight_radius
			var id := String(b.building_type.id)
			for suffix: StringName in BUILDING_SIGHT:
				if id.ends_with(String(suffix)):
					return float(BUILDING_SIGHT[suffix])
		return DEFAULT_BUILDING_SIGHT
	return 0.0


# ---------------------------------------------------------------- update

func _physics_process(delta: float) -> void:
	_tick_left -= delta
	if _tick_left > 0.0:
		return
	_tick_left += TICK
	if _tick_left < 0.0:
		_tick_left = TICK
	var team: int = Unit.Team.PLAYER if _next_team == 0 else Unit.Team.ENEMY
	_next_team = 1 - _next_team
	update_team(team)


## Recomputes `team`'s "visible now" layer (normally at 5 Hz; tests may call it directly).
func update_team(team: int) -> void:
	_pass_id += 1
	if team == Unit.Team.PLAYER:
		_vis_p.fill(0)
	else:
		_vis_e.fill(0)
	var tree := get_tree()
	for node in tree.get_nodes_in_group("units"):
		var u := node as Unit
		if u and int(u.team) == team:
			_stamp(team, u.global_position, sight_of(u))
	for node in tree.get_nodes_in_group("buildings"):
		var b := node as Building
		if b and int(b.team) == team:
			_stamp(team, b.global_position, sight_of(b))
	# Other sight sources (champions.md 13): SightMarker, champions... anything in "fog_sources" with
	# `team` and `sight_radius` (skipped once its is_alive() is false).
	for node in tree.get_nodes_in_group("fog_sources"):
		var src := node as Node3D
		if src == null:
			continue
		var src_team: Variant = src.get(&"team")
		if src_team == null or int(src_team) != team:
			continue
		if src.has_method(&"is_alive") and not bool(src.call(&"is_alive")):
			continue
		var src_sight: Variant = src.get(&"sight_radius")
		if src_sight != null:
			_stamp(team, src.global_position, float(src_sight))
	_team_pass[team] = _pass_id
	if team == local_team:
		_upload()
		_apply_local_view()
	updated.emit()


func _stamp(team: int, pos: Vector3, radius: float) -> void:
	if radius <= 0.0:
		return
	var cx := floori(pos.x / CELL) + HALF
	var cz := floori(pos.z / CELL) + HALF
	if cx < 0 or cx >= SIZE or cz < 0 or cz >= SIZE:
		return
	var key := int(radius * 10.0)
	var centre := cx + cz * SIZE
	if _mark_tick[centre] == _pass_id and _mark_r[centre] >= key:
		return   # a same-or-bigger circle was already stamped from this cell in this pass
	_mark_tick[centre] = _pass_id
	_mark_r[centre] = key
	var spans := _spans_for(radius)
	var r := (spans.size() - 1) / 2
	var z0 := maxi(cz - r, 0)
	var z1 := mini(cz + r, SIZE - 1)
	if team == Unit.Team.PLAYER:
		for z in range(z0, z1 + 1):
			var w := spans[z - cz + r]
			var row := z * SIZE
			for x in range(maxi(cx - w, 0), mini(cx + w, SIZE - 1) + 1):
				_vis_p[row + x] = 255
				_exp_p[row + x] = 255
	else:
		for z in range(z0, z1 + 1):
			var w := spans[z - cz + r]
			var row := z * SIZE
			for x in range(maxi(cx - w, 0), mini(cx + w, SIZE - 1) + 1):
				_vis_e[row + x] = 255
				_exp_e[row + x] = 255


## Half widths (in cells) of each row of a circle of `radius` metres: cells whose centre is within
## radius / 2 cells of the stamping cell's centre.
func _spans_for(radius: float) -> PackedInt32Array:
	var key := int(radius * 10.0)
	var spans: PackedInt32Array = _spans.get(key, PackedInt32Array())
	if not spans.is_empty():
		return spans
	var rc := radius / CELL
	var r := floori(rc)
	for dz in range(-r, r + 1):
		spans.append(floori(sqrt(maxf(rc * rc - float(dz * dz), 0.0))))
	_spans[key] = spans
	return spans


func _index(world_pos: Vector3) -> int:
	var cx := clampi(floori(world_pos.x / CELL) + HALF, 0, SIZE - 1)
	var cz := clampi(floori(world_pos.z / CELL) + HALF, 0, SIZE - 1)
	return cx + cz * SIZE


func _local_vis(world_pos: Vector3) -> bool:
	var idx := _index(world_pos)
	return (_vis_p[idx] if local_team == Unit.Team.PLAYER else _vis_e[idx]) != 0


func _local_exp(world_pos: Vector3) -> bool:
	var idx := _index(world_pos)
	return (_exp_p[idx] if local_team == Unit.Team.PLAYER else _exp_e[idx]) != 0


## True if the centre or a corner (inset 0.5 m) of a `half` x `half` square is visible now.
func _area_vis(pos: Vector3, half: float) -> bool:
	if _local_vis(pos):
		return true
	if half <= 1.0:
		return false
	var h := half - 0.5
	return (_local_vis(pos + Vector3(h, 0.0, h)) or _local_vis(pos + Vector3(-h, 0.0, h))
			or _local_vis(pos + Vector3(h, 0.0, -h)) or _local_vis(pos + Vector3(-h, 0.0, -h)))


# ---------------------------------------------------------------- the local player's view

func _apply_local_view() -> void:
	var tree := get_tree()
	for node in tree.get_nodes_in_group("units"):
		var u := node as Unit
		if u and int(u.team) != local_team and u.is_alive():
			var show := not enabled or _local_vis(u.global_position)
			if u.visible != show:
				u.visible = show
	for node in tree.get_nodes_in_group("buildings"):
		var b := node as Building
		if b == null or int(b.team) == local_team or not b.is_alive():
			continue
		var half := _half_extent(b)
		var show := not enabled or _area_vis(b.global_position, half)
		var id := b.get_instance_id()
		if show:
			if enabled:
				_seen[id] = true
		elif _seen.has(id) and not _ghosts.has(id):
			_add_ghost(b, half)
		if b.visible != show:
			b.visible = show
	_update_ghosts()
	for node in tree.get_nodes_in_group("crystal_nodes"):
		var n := node as Node3D
		if n:
			n.visible = not enabled or _local_exp(n.global_position)
	_update_artifact()


func _half_extent(b: Building) -> float:
	if b.building_type:
		var size: Vector2 = b.building_type.size_m()
		return minf(size.x, size.y) * 0.5
	return 1.0


func _add_ghost(b: Building, half: float) -> void:
	var ghost := b.make_ghost(_ghost_mat)
	ghost.add_to_group("fog_ghosts")
	add_child(ghost)
	ghost.global_transform = b.global_transform
	_ghosts[b.get_instance_id()] = {"node": ghost, "pos": b.global_position, "half": half}


## Removes the ghosts whose area is visible again (or all of them with the fog off).
func _update_ghosts() -> void:
	if _ghosts.is_empty():
		return
	for id: int in _ghosts.keys():
		var g: Dictionary = _ghosts[id]
		if enabled and not _area_vis(g["pos"], g["half"]):
			continue
		var node := g["node"] as Node
		if is_instance_valid(node):
			node.queue_free()
		_ghosts.erase(id)
		if not is_instance_valid(instance_from_id(id)):
			_seen.erase(id)


## The artifact (main.artifact): shown once its spot is explored; while worn, only if the wearer is.
func _update_artifact() -> void:
	var level := get_parent()
	if level == null or not &"artifact" in level:
		return
	var art_v: Variant = level.get(&"artifact")
	if art_v == null or not is_instance_valid(art_v) or not art_v is Node3D:
		return
	var art := art_v as Node3D
	var wearer_v: Variant = art.get(&"wearer") if &"wearer" in art else null
	var wearer: Node3D = wearer_v as Node3D if wearer_v != null and is_instance_valid(wearer_v) else null
	if wearer != null:
		art.visible = not enabled or int(wearer.get(&"team")) == local_team or wearer.visible
	else:
		art.visible = not enabled or _local_exp(art.global_position)


# ---------------------------------------------------------------- overlay

func _build_overlay() -> void:
	_img_vis = Image.create_empty(SIZE, SIZE, false, Image.FORMAT_R8)
	_img_exp = Image.create_empty(SIZE, SIZE, false, Image.FORMAT_R8)
	_tex_vis = ImageTexture.create_from_image(_img_vis)
	_tex_exp = ImageTexture.create_from_image(_img_exp)
	var shader := Shader.new()
	shader.code = OVERLAY_SHADER
	_overlay_mat = ShaderMaterial.new()
	_overlay_mat.shader = shader
	_overlay_mat.render_priority = -100   # before the other see-through things (rings, HP bars, VFX)
	_overlay_mat.set_shader_parameter(&"vis_tex", _tex_vis)
	_overlay_mat.set_shader_parameter(&"exp_tex", _tex_exp)
	_overlay_mat.set_shader_parameter(&"map_half", MAP_HALF)
	_overlay_mat.set_shader_parameter(&"explored_alpha", EXPLORED_ALPHA)
	var box := BoxMesh.new()
	box.size = Vector3(600.0, 400.0, 600.0)   # the camera is always inside: back faces cover the screen
	_overlay = MeshInstance3D.new()
	_overlay.name = "FogOverlay"
	_overlay.mesh = box
	_overlay.material_override = _overlay_mat
	_overlay.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_overlay.extra_cull_margin = 1000.0
	_overlay.visible = enabled
	add_child(_overlay)


func _upload() -> void:
	if _tex_vis == null:
		return
	var vis := _vis_p if local_team == Unit.Team.PLAYER else _vis_e
	var ex := _exp_p if local_team == Unit.Team.PLAYER else _exp_e
	_img_vis.set_data(SIZE, SIZE, false, Image.FORMAT_R8, vis)
	_img_exp.set_data(SIZE, SIZE, false, Image.FORMAT_R8, ex)
	_tex_vis.update(_img_vis)
	_tex_exp.update(_img_exp)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	if code == KEY_F11:
		enabled = not enabled
		get_viewport().set_input_as_handled()


## Reads the opaque depth, rebuilds each pixel's world position and darkens it by the fog state
## there (linear filter = soft edges over about one cell). Sky / off-map pixels stay clear.
const OVERLAY_SHADER := """
shader_type spatial;
render_mode unshaded, cull_front, depth_test_disabled, depth_draw_never, blend_mix, shadows_disabled;

uniform sampler2D vis_tex : filter_linear, repeat_disable;
uniform sampler2D exp_tex : filter_linear, repeat_disable;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest, repeat_disable;
uniform float map_half = 60.0;
uniform float explored_alpha = 0.55;

void fragment() {
	float depth = texture(depth_tex, SCREEN_UV).r;
	vec4 view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	view.xyz /= view.w;
	vec3 world = (INV_VIEW_MATRIX * vec4(view.xyz, 1.0)).xyz;
	vec2 uv = (world.xz + vec2(map_half)) / (2.0 * map_half);
	ALBEDO = vec3(0.0);
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0 || world.y > 40.0) {
		ALPHA = 0.0;
	} else {
		float e = texture(exp_tex, uv).r;
		float v = texture(vis_tex, uv).r;
		ALPHA = mix(1.0, mix(explored_alpha, 0.0, v), e);
	}
}
"""
