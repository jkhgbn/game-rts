class_name MissionE5Base
extends MissionBase
## Episode 5 "The Spark and the Candle" (origins) shared rules (docs/design/mission-e5-01.md "Episode 5 shared rules"
## F1-F11), used by MissionE5_01..MissionE5_04 (each still a MissionBase):
## - F1 flags only (CampaignState.MISSION_REWARDS "save_items": false, nothing carried in: no apply_to_start);
## - F3 tier 1 only (tiers on, max_tier 1, bots never upgrade), every system the young heroes would not have is off;
## - F2 the young / apprentice looks (`set_look` when the model has it, else a smaller model scale);
## - F11 story enemy kinds built in code from existing numbers (`local_unit`): saved and rebuilt by id through
##   `save_spawn_unit` (SaveWorld calls it for a unit whose type id is not in data/units);
## - the mission's lines by spec id (`say_l`), a seeded tree / rock scatter that keeps clearings and lanes open, flat
##   ground decals (shadow zones, reed fields) drawn only outside the Bot Lab sim.

## The mission's line ids in order (LINE_IDS[n - 1] = id of dialogue line n). Set by the subclass in _init.
var line_ids: Array[String] = []
## Line ids said so far (in order). Read only.
var said: Array[String] = []

var _said := {}
var _local_units := {}        # type id (String) -> UnitType built in code (never saved: rebuilt by _init / _ready)


func _init() -> void:
	super()
	tavern_enabled = false
	trade_enabled = false
	river_enabled = false
	points_enabled = false
	camps_enabled = false
	beasts_enabled = false


## F3: tier 1 only, no casters / helpers / titans, bots never upgrade; the instant-loss rule of the player's wizard.
static func e5_config(c: MissionConfig) -> void:
	c.tiers_enabled = true
	c.max_tier = 1
	c.bots_upgrade = false
	c.casters_enabled = false
	c.t3_enabled = false
	c.helpers_enabled = false
	c.titans_enabled = false
	c.instant_loss_on_wizard_death = true


func _use_map_dressing() -> bool:
	return true


# ---------------------------------------------------------------- lines

## Says the spec line `id` ("L7") once.
func say_l(id: String) -> void:
	if _said.has(id):
		return
	var n := line_ids.find(id)
	if n < 0:
		return
	_said[id] = true
	said.append(id)
	say_line(n + 1)


## Says the spec line `id` again (barks with their own cooldown).
func say_again(id: String) -> void:
	var n := line_ids.find(id)
	if n < 0:
		return
	_said[id] = true
	said.append(id)
	say_line(n + 1)


# ---------------------------------------------------------------- local unit / building types (F11)

## A mission-local UnitType: a copy of `base_id` with a new id / name and the `fields` given (UnitType properties).
func local_unit(base_id: String, id: String, display: String, fields: Dictionary = {}) -> UnitType:
	var base := UnitType.find(base_id)
	var t := (base.duplicate() as UnitType) if base else UnitType.new()
	t.id = StringName(id)
	t.display_name = display
	for k: Variant in fields:
		t.set(StringName(str(k)), fields[k])
	_local_units[id] = t
	return t


func local_type(id: String) -> UnitType:
	return _local_units.get(id) as UnitType


## make_unit with the mission's local types first (reivers, wardens...), else data/units.
func make_unit(type_id: String) -> Unit:
	if _local_units.has(type_id):
		return Worker.make_unit(_local_units[type_id] as UnitType)
	return super(type_id)


## SaveWorld hook: a saved unit whose type is one of this mission's local types is rebuilt from it.
func save_spawn_unit(row: Dictionary) -> Unit:
	var id := String(row.get("type", ""))
	if not _local_units.has(id):
		return null
	var u := Worker.make_unit(_local_units[id] as UnitType)
	u.team = int(row["team"]) as Unit.Team
	add_child(u)
	u.global_position = row["pos"]
	u.command_stop()
	return u


## A mission-local BuildingType: a copy of `base_id` (same model) with a new name, HP, no pop, free.
static func local_building(base_id: String, id: String, display: String, hp: float, counts_for_defeat := false) -> BuildingType:
	var base := BuildingType.find(base_id)
	if base == null:
		return null
	var t := base.duplicate() as BuildingType
	t.id = StringName(id)
	t.display_name = display
	t.max_hp = hp
	t.pop_bonus = 0
	t.cost = 0
	t.max_count = 0
	t.counts_for_defeat = counts_for_defeat
	return t


## Spawns `rows` ([type_id, normal count]) through scaled() in a ring (or a spiral when `spiral`), local types
## included; all scripted; `hold_spot` makes them guards (walk home when idle). Returns the units.
func spawn_rows(rows: Array, center: Vector3, ring: float, team: Unit.Team, hold_spot: bool, spiral := false) -> Array:
	var types: Array[String] = []
	for row: Array in rows:
		for i in scaled(int(row[1]), String(row[0])):
			types.append(String(row[0]))
	var out: Array = []
	for i in types.size():
		var p := center
		if spiral:
			var a := float(i) * 2.39996
			var r := 1.0 + 0.45 * sqrt(float(i))
			p += Vector3(cos(a) * r, 0.0, sin(a) * r)
		elif types.size() > 1:
			var a := TAU / 8.0 + float(i) * TAU / float(types.size())
			p += Vector3(cos(a) * ring, 0.0, sin(a) * ring)
		var u := make_unit(types[i])
		if u == null:
			continue
		_spawn(u, team, p)
		mark_scripted(u)
		if hold_spot:
			u.set_meta(META_HOME, u.global_position)
			_guards.append(u)
		out.append(u)
	return out


# ---------------------------------------------------------------- looks

## F2: `look` on the wizard's model when it has set_look (tech-artist), else the model scaled to `scale`.
static func young_look(w: Unit, look: StringName, scale: float) -> void:
	if w == null:
		return
	var m := w.get_model()
	if m == null:
		return
	if m.has_method(&"set_look"):
		m.call(&"set_look", look)
	elif scale > 0.0 and absf(scale - 1.0) > 0.01:
		m.scale = Vector3.ONE * scale


# ---------------------------------------------------------------- the map

## The `main.gd` generator's look with the mission's seed: `clusters` tree clusters and `rocks` rocks inside
## +-`half` m, kept out of `clearings` ([[Vector3, r], ...]) and `lanes` ([[from, to, half width], ...]).
func scatter_props(seed_n: int, clearings: Array, lanes: Array, clusters: int, rocks: int, half := 54.0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_n
	var blocked := func(p: Vector3) -> bool:
		if absf(p.x) > half or absf(p.z) > half:
			return true
		for c: Array in clearings:
			if _flat(p, c[0]) < float(c[1]):
				return true
		for l: Array in lanes:
			var q := Vector2(p.x, p.z)
			var a := Vector2((l[0] as Vector3).x, (l[0] as Vector3).z)
			var b := Vector2((l[1] as Vector3).x, (l[1] as Vector3).z)
			if q.distance_to(Geometry2D.get_closest_point_to_segment(q, a, b)) < float(l[2]):
				return true
		return false
	for k in clusters:
		var center := Vector3(rng.randf_range(-half, half), 0.0, rng.randf_range(-half, half))
		for i in rng.randi_range(5, 9):
			var p := center + Vector3(rng.randf_range(-6.0, 6.0), 0.0, rng.randf_range(-6.0, 6.0))
			if not bool(blocked.call(p)):
				_add_tree(p, rng.randf_range(0.8, 1.3))
	for i in rocks:
		var p := Vector3(rng.randf_range(-half, half), 0.0, rng.randf_range(-half, half))
		if not bool(blocked.call(p)):
			_add_rock(p, rng.randf_range(0.8, 2.0), rng.randf() * TAU)


## An invisible bound wall (layer 1, baked into the navmesh) from `a` to `b`, `height` m tall, 1 m thick.
func bound_wall(a: Vector3, b: Vector3, height := 2.5) -> StaticBody3D:
	var shape := BoxShape3D.new()
	var length_m := _flat(a, b)
	shape.size = Vector3(length_m, height, 1.0)
	var body := _static_obstacle((a + b) * 0.5, shape, height * 0.5)
	body.rotation.y = -atan2(b.z - a.z, b.x - a.x)
	return body


## A flat ground disc (decal stand-in: shadow zones, reed fields, rings), drawn only outside the Bot Lab sim.
func ground_disc(pos: Vector3, r: float, color: Color, y := 0.03) -> MeshInstance3D:
	if _SIM.enabled:
		return null
	var disc := CylinderMesh.new()
	disc.top_radius = r
	disc.bottom_radius = r
	disc.height = 0.02
	disc.radial_segments = 40
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var mi := MeshInstance3D.new()
	mi.mesh = disc
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.global_position = pos + Vector3(0.0, y, 0.0)
	return mi


## A simple placeholder prop (box + roof), drawn only outside the Bot Lab sim; no collider.
func box_prop(pos: Vector3, size: Vector3, color: Color, yaw := 0.0) -> Node3D:
	if _SIM.enabled:
		return null
	var root := Node3D.new()
	add_child(root)
	root.global_position = pos
	root.rotation.y = yaw
	var box := BoxMesh.new()
	box.size = size
	_mesh(root, box, color, size.y * 0.5)
	return root


## The mood on the warm rig until the tech-artist's presets exist (vale_dusk, fen_noon, wick_night, green_afternoon):
## sun colour / energy factor / pitch, ambient and sky colours (m04's storm-dusk pattern). Nothing in the Bot Lab sim.
func tint_light(sun_color: Color, energy_mult: float, pitch: float, ambient: Color, sky_top: Color, sky_horizon: Color) -> void:
	var rig := get_node_or_null(^"LightingRig")
	if rig == null:
		return
	var sun := rig.get(&"sun") as DirectionalLight3D
	if sun:
		sun.light_color = sun_color
		sun.light_energy *= energy_mult
		sun.rotation_degrees.x = pitch
	var we := rig.get(&"world_environment") as WorldEnvironment
	if we and we.environment:
		var env := we.environment
		env.ambient_light_color = ambient
		var sky_mat := env.sky.sky_material as ProceduralSkyMaterial if env.sky else null
		if sky_mat:
			sky_mat.sky_top_color = sky_top
			sky_mat.sky_horizon_color = sky_horizon


## A per-mission building cap (Hearth max 1 / 2): a site past `max_count` of `type_id` is cancelled with a full
## refund (`message` shown). Call it from a tick.
func enforce_max(type_id: StringName, max_count: int, message: String, team: int = Unit.Team.PLAYER) -> void:
	var have: Array = []
	for b in Building.for_team(team):
		if b.is_alive() and b.building_type and b.building_type.id == type_id:
			have.append(b)
	if have.size() <= max_count:
		return
	for b: Variant in have.duplicate():
		var site := b as Building
		if have.size() > max_count and not site.is_constructed():
			have.erase(site)
			var refund := int(site.building_type.cost) - int(floor(float(site.building_type.cost) * 0.75))
			site.cancel_construction()
			var eco := Economy.for_team(team)
			if eco:
				eco.add(refund)
			if hud and team == Unit.Team.PLAYER:
				hud.show_message(message, 4.0)


# ---------------------------------------------------------------- helpers

## Living units of `team` (optionally only non-workers that are not dormant).
func units_of(team: int, soldiers_only := false) -> Array[Unit]:
	var out: Array[Unit] = []
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or not u.is_alive() or int(u.team) != team or is_dormant(u):
			continue
		if soldiers_only and (u.is_worker() or u is Wizard):
			continue
		out.append(u)
	return out


## The nearest living hostile (to PLAYER) unit within `r` of `at` (dormant ones skipped), else null.
func foe_near(at: Vector3, r: float, of_team: int = Unit.Team.PLAYER) -> Unit:
	var best: Unit = null
	var d := r
	for n in get_tree().get_nodes_in_group(&"units"):
		var u := n as Unit
		if u == null or not u.is_alive() or is_dormant(u) or not Teams.is_hostile(int(u.team), of_team):
			continue
		var dd := _flat(u.global_position, at)
		if dd < d:
			d = dd
			best = u
	return best


## Seconds as "m:ss".
static func mmss(t: float) -> String:
	var s := int(maxf(0.0, t))
	return "%d:%02d" % [s / 60, s % 60]
