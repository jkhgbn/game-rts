extends Node3D
## Builds the test map "Ruins of the Ember Crown", spawns both armies, and checks victory/defeat.
## Mission: the Fire Wizard must reach the Ember Crown, guarded by Shadow kingdom forces.
## The 1v1 map (scripts/world/skirmish.gd) extends this script and overrides the hooks
## _build_map, _on_navigation_ready, _objective_text and _lane_end.

const MAP_SIZE := 120.0
const PLAYER_START := Vector3(-36.0, 0.0, 36.0)

## Mission 1 values. Vars (not consts) only so the skirmish can move both to the map centre in
## its _init(); treat them as constants.
var MID_CAMP := Vector3(-2.0, 0.0, 2.0)
var ARTIFACT_POS := Vector3(34.0, 0.0, -34.0)

const FIRE_COLOR := Color(0.85, 0.3, 0.12)
const SHADOW_COLOR := Color(0.42, 0.22, 0.6)
const WORLD_ENV_PATH := "res://art/environment/world_env.tres"
const LIGHTING_RIG_PATH := "res://art/environment/lighting/lighting_rig.gd"
const CRITTER_SYSTEM_PATH := "res://art/environment/critters/critter_system.gd"
const _SIM := preload("res://scripts/core/sim_mode.gd")   # Bot Lab sim mode: no draw-only art (docs/plan/bot-lab.md)
## Replay Lab (docs/plan/replay-lab.md): deterministic runs (BAKE_SYNC) bake the first navmesh on the main thread,
## so the match starts on the level's first frame (no wall-clock-dependent wait before it).
const _REPLAY := preload("res://scripts/core/replay/replay_hooks.gd")

var nav_region: NavigationRegion3D
var camera_rig: RTSCamera
var selection: SelectionManager
var hud: GameHUD
var hero: Wizard
var artifact: Artifact
var game_over := false
var economy: Economy          ## The player's economy (the enemy's: Economy.for_team(Unit.Team.ENEMY)).
var keep: Keep                ## The player's keep.
var crystal_nodes: Dictionary = {}   ## node id (StringName) -> CrystalNode
var build_grid: BuildGrid     ## Building placement (snap / check / place), both teams.
var fog: FogOfWar             ## Fog of war (scripts/world/fog_of_war.gd), group "fog".
var env_props: EnvProps       ## The art trees / rocks / pillars (null = placeholder shapes).

## Start camera focus, relative to the player's keep: the keep sits a little left of and just
## below the screen centre, the workers and both home nodes are above the bottom HUD panels.
const START_FOCUS_FROM_KEEP := Vector3(3.0, 0.0, -1.0)
const START_HINT := "Click your Keep (bottom-left) to train workers — select workers and press B to build"


func _ready() -> void:
	# MT1 (map-production.md 2.8): the running map's size, read by the fog, BuildGrid, river, minimap and camera.
	var sz := _map_size()
	MapInfo.setup(sz.x, sz.y, _map_id(), self)
	# One Economy per team, created before any unit so every unit's pop is counted.
	economy = _add_economy(Unit.Team.PLAYER)
	_add_economy(Unit.Team.ENEMY)
	_build_environment()
	_build_nav_region()

	# Before the map, so levels can use build_grid.spawn_complete for their start buildings.
	build_grid = BuildGrid.new()
	build_grid.name = "BuildGrid"
	build_grid.nav_region = nav_region
	build_grid.front_toward = MID_CAMP
	add_child(build_grid)

	fog = FogOfWar.new()
	fog.name = "FogOfWar"
	add_child(fog)
	fog.reveal(Unit.Team.PLAYER, _player_start(), FogOfWar.START_REVEAL)

	if EnvProps.available() and not _SIM.enabled:   # trees / rocks / pillars drawn as MultiMeshes (6.S2)
		env_props = EnvProps.new()
		env_props.name = "EnvProps"
		add_child(env_props)
	_build_map()
	if env_props:
		env_props.commit()
	# Map edge dressing (cliffs, border forest, grass/flowers) from the tech-artist (A.10). Draw-only.
	if ResourceLoader.exists("res://art/environment/map_dressing.tscn") and not _SIM.enabled and _use_map_dressing():
		add_child(load(MapDressingArt.SCENE_PATH).instantiate())
	# Cosmetic ambient critters (12.V16, draw-only; builds itself once the hero exists; Map detail Low = none).
	if ResourceLoader.exists(CRITTER_SYSTEM_PATH) and not _SIM.enabled:
		var critter_script := load(CRITTER_SYSTEM_PATH) as Script
		var critters := critter_script.new() as Node3D if critter_script and critter_script.can_instantiate() else null
		if critters:
			critters.name = "CritterSystem"
			add_child(critters)
			critters.call(&"setup", self)

	camera_rig = RTSCamera.new()
	camera_rig.bounds = MapInfo.bounds().grow(-2.0)   # MT1: 116 x 116 on the 120 m maps (the old default)
	add_child(camera_rig)
	camera_rig.focus_on(keep.position + START_FOCUS_FROM_KEEP)

	selection = SelectionManager.new()
	add_child(selection)
	selection.camera = camera_rig.camera

	hud = GameHUD.new()
	add_child(hud)
	add_child(preload("res://scenes/ui/pause_menu.tscn").instantiate())   # Esc: pause (5.U1)
	hud.set_objective(_objective_text())
	hud.show_message("Baking pathfinding...", 1.0)

	nav_region.bake_finished.connect(_on_navigation_ready, CONNECT_ONE_SHOT)
	_REPLAY.level_ready()
	nav_region.bake_navigation_mesh(_REPLAY.bake_mode != _REPLAY.BAKE_SYNC)


func _on_navigation_ready() -> void:
	# Mission 1 starting forces: docs/design/units-fire-shadow.md.
	# --- Kingdom of Flame (player)
	hero = Wizard.new()
	_spawn(hero, Unit.Team.PLAYER, PLAYER_START)
	for i in 5:
		_spawn(make_unit("flame_guard"), Unit.Team.PLAYER, PLAYER_START + Vector3(-3.0 + i * 1.5, 0.0, -2.5))
	for i in 4:
		_spawn(make_unit("ember_archer"), Unit.Team.PLAYER, PLAYER_START + Vector3(-2.25 + i * 1.5, 0.0, 2.0))
	# Workers start gathering: 2 on node_home_a, 1 on node_home_b (both are equally near).
	for i in 3:
		var worker := _spawn(make_unit("cinder_hand"), Unit.Team.PLAYER,
				PLAYER_START + Vector3(-4.0 + i * 1.2, 0.0, 4.0 - i * 1.2))
		worker.call("command_gather", crystal_nodes[&"node_home_a" if i < 2 else &"node_home_b"])

	# --- Kingdom of Shadow (enemy)
	for i in 4:
		_spawn(make_unit("shade"), Unit.Team.ENEMY, MID_CAMP + Vector3(cos(i * 1.57) * 2.5, 0.0, sin(i * 1.57) * 2.5))
	_spawn(make_unit("grave_hound"), Unit.Team.ENEMY, MID_CAMP + Vector3(-4.0, 0.0, 0.0))
	_spawn(make_unit("grave_hound"), Unit.Team.ENEMY, MID_CAMP + Vector3(0.0, 0.0, 4.0))
	for i in 5:
		var a := i * TAU / 5.0
		_spawn(make_unit("shade"), Unit.Team.ENEMY, ARTIFACT_POS + Vector3(cos(a) * 4.0, 0.0, sin(a) * 4.0))
	_spawn(make_unit("nightbolt"), Unit.Team.ENEMY, ARTIFACT_POS + Vector3(5.0, 0.0, 1.0))
	_spawn(make_unit("nightbolt"), Unit.Team.ENEMY, ARTIFACT_POS + Vector3(1.0, 0.0, -5.0))
	_spawn(make_unit("shadow_knight"), Unit.Team.ENEMY, ARTIFACT_POS + Vector3(-3.0, 0.0, 3.0))
	var malrik := ShadowWizard.new()
	_spawn(malrik, Unit.Team.ENEMY, ARTIFACT_POS + Vector3(4.0, 0.0, -4.0))
	malrik.died.connect(func(_u: Unit) -> void:
		hud.show_message("Malrik has fallen back into the shadows", 4.0))

	# --- The artifact
	artifact = Artifact.new()
	add_child(artifact)
	artifact.global_position = ARTIFACT_POS
	artifact.claimed.connect(_on_artifact_claimed)

	hero.died.connect(_on_hero_died)
	for wiz: Unit in [hero, malrik]:
		ItemDrops.ensure_inventory(wiz)   # guarded: only once scripts/items/inventory.gd exists
	_setup_hud()
	hud.show_message(START_HINT, 10.0)


func _objective_text() -> String:
	return ("Mission 1: Ruins of the Ember Crown\n"
			+ "Lead the Fire Wizard to the Ember Crown (north-east).\n"
			+ "Your wizard must survive.")


## Connects the selection and the HUD to `hero` (call once the hero exists) and selects her.
func _setup_hud() -> void:
	selection.hero = hero
	selection.message.connect(hud.show_message)
	hud.fireball_pressed.connect(selection.begin_fireball_targeting)
	hud.setup(hero, selection)
	selection.select_units([hero])


## Builds a unit from data/units/<id>.tres. Accepts an id ("flame_guard") or a display name
## ("Flame Guard"). Worker types become a Worker. Set its team and add it to the scene
## afterwards (or use _spawn).
func make_unit(type_id: String) -> Unit:
	var type := UnitType.find(type_id)
	if type == null:
		push_error("Unknown unit type: %s" % type_id)
		return null
	return Worker.make_unit(type)


func _spawn(unit: Unit, team: Unit.Team, pos: Vector3) -> Unit:
	unit.team = team
	add_child(unit)
	unit.global_position = pos
	unit.command_stop()   # remember this spot as "home"
	if team == Unit.Team.ENEMY:
		unit._visual.rotation.y = PI * 0.75   # face toward the player's side
	return unit


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
		match code:
			KEY_SPACE:   # the wizard, or the keep while she is dead
				if hero and is_instance_valid(hero) and hero.is_alive():
					camera_rig.focus_on(hero.global_position)
				elif keep and is_instance_valid(keep) and keep.is_alive():
					camera_rig.focus_on(keep.global_position)
			KEY_F9:   # restart (R is a keep hotkey)
				get_tree().reload_current_scene()


func _on_artifact_claimed(claimed: Artifact, by: Wizard) -> void:
	hud.show_message("%s claims the %s!  +%d max mana, stronger Fireball" %
			[by.unit_name, claimed.artifact_name, int(claimed.bonus_mana)], 4.0)
	var events := get_node_or_null(^"/root/Events")
	if events:
		events.artifact_claimed.emit(claimed, by)
	_end_game(true)


func _on_hero_died(_unit: Unit) -> void:
	_end_game(false)


func _end_game(victory: bool) -> void:
	if game_over:
		return
	game_over = true
	var events := get_node_or_null(^"/root/Events")
	if events:
		events.mission_ended.emit(victory)
	if victory:
		hud.show_banner("VICTORY\nPress F9 to play again", Color(1.0, 0.85, 0.3))
	else:
		hud.show_banner("DEFEAT\nYour wizard has fallen.  Press F9 to retry", Color(0.9, 0.3, 0.3))


# ---------------------------------------------------------------- world building

## The map's mood: &"warm" (default) or &"ice". Missions / maps override it (an Ice mission returns &"ice").
func _lighting_preset() -> StringName:
	return &"warm"


func _build_environment() -> void:
	if _SIM.enabled:
		return   # Bot Lab sim: nothing is drawn
	# The tech-artist's lighting rig (docs/art/lighting.md): environment, sun, fill light, vignette.
	if ResourceLoader.exists(LIGHTING_RIG_PATH):
		var rig: Node = (load(LIGHTING_RIG_PATH) as GDScript).new()
		rig.set(&"preset_id", _lighting_preset())
		add_child(rig)
		return
	# The tech-artist's environment (art-keep.md 0.4) and its sun; the old one below is the fallback.
	if ResourceLoader.exists(WORLD_ENV_PATH):
		var art_env := load(WORLD_ENV_PATH) as Environment
		if art_env:
			var art_world_env := WorldEnvironment.new()
			art_world_env.environment = art_env
			add_child(art_world_env)
			var art_sun := DirectionalLight3D.new()
			art_sun.rotation_degrees = Vector3(-50.0, 35.0, 0.0)
			art_sun.light_energy = 1.3
			art_sun.light_color = Color(1.0, 0.93, 0.82)
			art_sun.shadow_enabled = true
			art_sun.shadow_normal_bias = 2.0
			art_sun.directional_shadow_max_distance = 90.0
			add_child(art_sun)
			return
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.32, 0.45, 0.68)
	sky_mat.sky_horizon_color = Color(0.72, 0.68, 0.62)
	sky_mat.ground_horizon_color = Color(0.5, 0.46, 0.4)
	var sky := Sky.new()
	sky.sky_material = sky_mat

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_bloom = 0.1
	env.ssao_enabled = true
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -35.0, 0.0)
	sun.light_energy = 1.2
	sun.light_color = Color(1.0, 0.95, 0.85)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90.0
	add_child(sun)


## The NavigationRegion3D and the ground. Everything added under nav_region with a collider becomes
## a pathfinding obstacle.
func _build_nav_region() -> void:
	nav_region = NavigationRegion3D.new()
	var nav_mesh := NavigationMesh.new()
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav_mesh.geometry_collision_mask = 1
	nav_mesh.agent_radius = 0.5
	nav_mesh.agent_height = 2.0
	nav_mesh.agent_max_climb = 0.25
	nav_mesh.cell_size = 0.25
	nav_mesh.cell_height = 0.25
	nav_region.navigation_mesh = nav_mesh
	add_child(nav_region)
	# F.2: sync region updates. With async iterations, a bake that finishes in the region's first sync frame
	# (slow first frame, e.g. the map dressing) is dropped: the map keeps an empty navmesh, every unit stuck.
	NavigationServer3D.region_set_use_async_iterations(nav_region.get_rid(), false)
	_build_ground()


## Review L1: the level gives MapInfo back (the 120 m default) when it leaves the tree, unless a newer level already
## set its own size. A notification, so subclasses' own _exit_tree (mission 1) cannot skip it.
func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE:
		MapInfo.release(self)


## The map's playable size in metres (x width, z depth). MAP_SIZE square here; a LayoutLevel returns its layout's.
func _map_size() -> Vector2:
	return Vector2(MAP_SIZE, MAP_SIZE)


## Where the player's wizard starts (the first fog reveal). PLAYER_START here; a LayoutLevel returns its seat's.
func _player_start() -> Vector3:
	return PLAYER_START


## True when the Crown Hollow edge dressing (art/environment/map_dressing.tscn, 120 m) fits this map.
func _use_map_dressing() -> bool:
	return true


## The map id for MapInfo (&"" for the hand-built maps).
func _map_id() -> StringName:
	return &""


## Trees, rocks, pillars, the keep and the crystal nodes (all before the first navmesh bake).
func _build_map() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7   # same map every time; change the number for a new layout
	var clearings := [
		[PLAYER_START, 12.0], [MID_CAMP, 7.0], [ARTIFACT_POS, 10.0],
	]

	# Forest clusters
	for cluster in 9:
		var center := Vector3(rng.randf_range(-50, 50), 0.0, rng.randf_range(-50, 50))
		for i in rng.randi_range(5, 9):
			var p := center + Vector3(rng.randf_range(-6, 6), 0.0, rng.randf_range(-6, 6))
			if _in_clearing(p, clearings) or _in_path_lane(p):
				continue
			_add_tree(p, rng.randf_range(0.8, 1.3))

	# Scattered rocks
	for i in 22:
		var p := Vector3(rng.randf_range(-54, 54), 0.0, rng.randf_range(-54, 54))
		if _in_clearing(p, clearings) or _in_path_lane(p):
			continue
		_add_rock(p, rng.randf_range(0.8, 2.2), rng.randf() * TAU)

	# Ruined pillars in a broken ring around the artifact
	for i in 10:
		if i == 3 or i == 7:
			continue   # gaps so you can walk in
		var a := i * TAU / 10.0
		_add_pillar(ARTIFACT_POS + Vector3(cos(a) * 8.0, 0.0, sin(a) * 8.0), rng.randf_range(2.0, 4.5))

	# Your keep (trains units, workers drop crystals at it) and the crystal nodes.
	# Both are navmesh obstacles, so they must exist before the bake.
	keep = Keep.new()
	keep.building_type = BuildingType.find("fire_keep")
	keep.team = Unit.Team.PLAYER
	keep.team_color = FIRE_COLOR
	keep.front_toward = MID_CAMP
	keep.position = PLAYER_START + Vector3(-7.0, 0.0, 7.0)
	nav_region.add_child(keep)
	_add_crystal_node(&"node_home_a", PLAYER_START + Vector3(-10.0, 0.0, -2.0), 600)
	_add_crystal_node(&"node_home_b", PLAYER_START + Vector3(2.0, 0.0, 10.0), 600)
	_add_crystal_node(&"node_mid", MID_CAMP + Vector3(4.0, 0.0, 4.0), 900)
	_add_crystal_node(&"node_ruins", ARTIFACT_POS + Vector3(6.0, 0.0, -7.0), 900)


func _build_ground() -> void:
	var ground := StaticBody3D.new()
	ground.collision_layer = 1
	var shape := BoxShape3D.new()
	shape.size = Vector3(MapInfo.size_x, 1.0, MapInfo.size_z)   # MT1: 120 x 120 on the hand-built maps
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position.y = -0.5
	ground.add_child(col)

	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(MapInfo.size_x, MapInfo.size_z)
	mesh.mesh = plane
	# The lowest surface shadows nothing; off also keeps the ground shader's river discard (12.V2) out of the sun's
	# shadow cascades.
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ground.add_child(mesh)
	nav_region.add_child(ground)
	if _SIM.enabled:
		return   # Bot Lab sim: the collider only (no ground paint)
	var painted := EnvProps.ground_material(_player_start(), _lane_end(), _ground_spots())
	if painted:
		apply_map_size(painted)
		mesh.material_override = painted
		return

	var noise := FastNoiseLite.new()
	noise.frequency = 0.03
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.24, 0.36, 0.16))
	ramp.set_color(1, Color(0.42, 0.46, 0.24))
	var tex := NoiseTexture2D.new()
	tex.noise = noise
	tex.seamless = true
	tex.color_ramp = ramp
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.uv1_scale = Vector3(4.0, 4.0, 1.0)
	mat.roughness = 0.95
	mesh.material_override = mat


## Tells the painted ground (art/environment/ground.gdshader) the running map's size (review H1): the border scree /
## rim / canopy start at the map edge on both axes and the plane's outer vertices are pushed out to a skirt at least
## 200 m wide, so a 176 m map is not painted as off-map and a 112 m map does not end in a hard cut.
static func apply_map_size(mat: ShaderMaterial) -> void:
	if mat == null:
		return
	mat.set_shader_parameter(&"map_half", MapInfo.half_max())
	mat.set_shader_parameter(&"map_half_xz", Vector2(MapInfo.half_x(), MapInfo.half_z()))
	mat.set_shader_parameter(&"expand_to", maxf(260.0, MapInfo.half_max() + 200.0))


## Painted ground spots Vector4(x, z, radius, kind: 0 dirt, 1 flagstones), max 4 (the skirmish overrides).
func _ground_spots() -> Array[Vector4]:
	return [Vector4(PLAYER_START.x, PLAYER_START.z, 11.0, 0.0), Vector4(MID_CAMP.x, MID_CAMP.z, 6.0, 0.0),
			Vector4(ARTIFACT_POS.x, ARTIFACT_POS.z, 9.5, 1.0)]


func _in_clearing(p: Vector3, clearings: Array) -> bool:
	for c in clearings:
		if p.distance_to(c[0]) < c[1]:
			return true
	return false


## Keeps a rough diagonal road open from your base to _lane_end() (the ruins).
func _in_path_lane(p: Vector3) -> bool:
	var a := Vector2(PLAYER_START.x, PLAYER_START.z)
	var end := _lane_end()
	var b := Vector2(end.x, end.z)
	var q := Vector2(p.x, p.z)
	var closest := Geometry2D.get_closest_point_to_segment(q, a, b)
	return q.distance_to(closest) < 5.0


func _lane_end() -> Vector3:
	return ARTIFACT_POS


func _static_obstacle(pos: Vector3, shape: Shape3D, shape_y: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position.y = shape_y
	body.add_child(col)
	nav_region.add_child(body)
	body.position = pos
	return body


func _mesh(parent: Node3D, mesh: Mesh, color: Color, y: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mi.material_override = mat
	mi.position.y = y
	parent.add_child(mi)
	return mi


func _add_tree(pos: Vector3, s: float) -> void:
	var shape := CylinderShape3D.new()
	shape.radius = 0.45 * s
	shape.height = 2.0
	var body := _static_obstacle(pos, shape, 1.0)
	if env_props:
		env_props.add_tree(pos, s)
		return
	if _SIM.enabled:
		return   # Bot Lab sim: collider only
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.2 * s
	trunk.bottom_radius = 0.3 * s
	trunk.height = 1.4 * s
	_mesh(body, trunk, Color(0.35, 0.24, 0.14), 0.7 * s)
	for layer in 3:
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = (1.6 - layer * 0.35) * s
		cone.height = 1.8 * s
		_mesh(body, cone, Color(0.13, 0.3 + layer * 0.04, 0.14), (1.9 + layer * 0.9) * s)


func _add_rock(pos: Vector3, s: float, rot: float) -> void:
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.6, 1.2, 1.3) * s
	var body := _static_obstacle(pos, shape, 0.5 * s)
	body.rotation.y = rot
	if env_props:
		env_props.add_rock(pos, s, rot)
		return
	if _SIM.enabled:
		return   # Bot Lab sim: collider only
	var box := BoxMesh.new()
	box.size = Vector3(1.6, 1.2, 1.3) * s
	var rock := _mesh(body, box, Color(0.46, 0.44, 0.42), 0.5 * s)
	rock.rotation = Vector3(0.15, 0.3, 0.1)


func _add_pillar(pos: Vector3, height: float) -> void:
	var shape := CylinderShape3D.new()
	shape.radius = 0.7
	shape.height = height
	var body := _static_obstacle(pos, shape, height * 0.5)
	if env_props:
		env_props.add_pillar(pos, height)
		return
	if _SIM.enabled:
		return   # Bot Lab sim: collider only
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.55
	cyl.bottom_radius = 0.7
	cyl.height = height
	_mesh(body, cyl, Color(0.55, 0.52, 0.6), height * 0.5)


func _add_crystal_node(id: StringName, pos: Vector3, amount: int) -> CrystalNode:
	var node := CrystalNode.new()
	node.node_id = id
	node.name = String(id)
	node.crystals_left = amount
	node.position = pos
	nav_region.add_child(node)
	crystal_nodes[id] = node
	return node


func _add_economy(team: Unit.Team) -> Economy:
	var eco := Economy.new()
	eco.team = team
	eco.name = "Economy%s" % ("Player" if team == Unit.Team.PLAYER else "Enemy")
	add_child(eco)
	return eco
