class_name ElderTreantModel
extends Node3D
## The Elder Treant, Nature's tier-3 titan, both forms (cavalry-mounts.md 5 / 10 row 13.V18; task 13.V18).
## Own rig (the CharacterModel kit has no knees, elbows or morph); geometry in treant_mesh.gd (static, cached per game).
## Look: an ancient walking oak 4 m tall, hunched, dark furrowed bark with moss on every up-facing surface and faint
## green sap in the furrows; a stern bark face (mossy drooping brows, glowing green eyes, a big knotty nose) with a
## long moss beard; long branch arms with twig fingers; a crown of short thick branches with leaf masses and pink
## blossoms; a living branch on the left of the back (asymmetric read); a garland of team-coloured leaves at the waist.
## ROOTED form (set_rooted, 3 s morph): the body sinks 0.78 m, the legs splay and bend into the ground where roots
## burst out and spread (11 roots, collars, a mossy mound, blossoms), the chest and face tilt up, the arms lift into a
## V and a canopy grows on them (leaf masses, blossoms, 12 glowing seed pods) -> a wide tree, 4.4 m.
## Heal glow (research.md: the Treant is Nature's regenerator): heal_glow drives the sap veins (pulsing up the limbs),
## a green rim and green motes rising around it; full in the rooted form (grove aura), half with set_regen(true).
##
## Hooks (Unit, has_method-guarded; calls before _ready are kept):
##   set_team_color(c) (the garland) · set_moving(speed) · play_attack() (walking: an overhead arm slam, strike at
##   ATTACK_STRIKE; rooted: = play_volley) · play_cast(id) (same routing) · play_hit() · play_death() + signal
##   death_finished (DEATH_LEN 1.8 s, a felled-tree topple) · revive() · set_status(id, on) -> bool (haste true) ·
##   play_level_up() · set_veterancy(level) · set_carrying / play_mine (no-ops) · glow_level()
##   set_rooted(on: bool, instant := false) (ROOT_TIME 3 s either way; signal root_changed(rooted) at the end) ·
##   is_rooted() -> bool · root_progress() -> float (0 walking .. 1 rooted) · is_morphing() -> bool ·
##   play_volley() (the thorn volley: signal volley_released at VOLLEY_RELEASE) ·
##   get_volley_origins() -> PackedVector3Array (world: left canopy, right canopy, crown) · set_regen(on: bool)
## Budget: 12 pivot meshes + 3 canopy meshes (head crown, both forearms) + the ground blob = 16 meshes, 18 draw
## instances with the 2 particle systems (crown petals, heal motes; both looping, stopped beyond 45 m), 0 lights,
## 3 materials (this folder) + the kit blob. The rooted-only nodes (3 canopies + ground roots) are hidden while
## walking (14 draw instances then); they are separate so an overlay material (the Ice chill tint) never draws the
## collapsed canopy at full size.

signal death_finished
## The morph finished (true = now rooted, false = walking again).
signal root_changed(rooted: bool)
## The thorn volley leaves the canopy (VOLLEY_RELEASE after play_volley).
signal volley_released

const TM := preload("res://art/units/titans/elder_treant/treant_mesh.gd")
const DEG := PI / 180.0
const ROOT_TIME := 3.0
const HIT_LEN := 0.32
const ATTACK_LEN := 0.95
## Frame where the slam lands (melee damage is applied at the trigger; the strike follows at once).
const ATTACK_STRIKE := 0.18
const VOLLEY_LEN := 1.0
const VOLLEY_RELEASE := 0.15
## Topple: under Unit.DEATH_FALLBACK_TIME (2.0 s).
const DEATH_LEN := 1.8
const DEATH_IMPACT := 1.05
const LEVEL_LEN := 0.4
const WHITE := Vector3(1.0, 1.0, 1.0)
const GOLD := Vector3(1.0, 0.58, 0.08)
const PETAL_COLOR := Color(1.0, 0.72, 0.84)
const HEAL_COLOR := Color(0.62, 1.0, 0.38)
const BLOB_MAT := "res://art/units/kit/materials/unit_shadow_blob.tres"

## Kit contract: HP bar / chevrons at the type's body_height; the crown top.
@export var body_height: float = 4.2
## Speed (m/s) that plays the walk at rate 1 (Unit overwrites it with the type's move_speed, 3.8).
@export var stride_speed: float = 3.8
## Seconds per full stride (two steps) at rate 1.
@export var stride_time: float = 0.95
## Kit contract (<= 0.15). 0: melee; the rooted volley is timed by play_volley (VOLLEY_RELEASE).
@export_range(0.0, 0.15, 0.01) var attack_windup: float = 0.0
## The colour the garland is authored with (Nature green).
@export var kingdom_color: Color = Color(0.35, 0.70, 0.25)
@export var idle_period: float = 4.2
## Kit contract: Unit reads these on some models.
@export var attack_style: StringName = &"treant_slam"
@export var death_style: StringName = &"topple"

# --- rig
var _piv: Array[Node3D] = []
var _pidx: PackedInt32Array = PackedInt32Array()
var _rest_pos := PackedVector3Array()
var _off_pos := PackedVector3Array()
var _off_rot := PackedVector3Array()
var _rooted_rot := PackedVector3Array()   # radians
var _rooted_pos := PackedVector3Array()

# --- nodes
var _shadow: GeometryInstance3D
var _spread: Node3D
var _mesh_nodes: Array[GeometryInstance3D] = []
var _node_pivot: Dictionary = {}
var _flash_nodes: Array[GeometryInstance3D] = []
var _petals: GPUParticles3D
var _motes: GPUParticles3D
var _markers: Array[Node3D] = []
var _growth_nodes: Array[Node3D] = []   # the canopy nodes + the ground roots: shown only while root_k > 0
var _ready_done: bool = false

# --- state
var _t: float = 0.0
var _phase_off: float = 0.0
var _tier: int = 0
var _tier_timer: float = 0.0
var _acc: float = 0.0
var _speed: float = 0.0
var _walk_w: float = 0.0
var _walk_p: float = 0.0
var _action: StringName = &""          # &"attack", &"volley"
var _action_t: float = 0.0
var _attack_side: float = 1.0
var _hit_t: float = 99.0
var _last_hit_time: float = -9.0
var _level_t: float = 99.0
var _dead: bool = false
var _death_t: float = 0.0
var _death_emitted: bool = false
var _glows_off: bool = false
var _root_k: float = 0.0
var _root_target: float = 0.0
var _regen: bool = false
var _haste: bool = false
var _frozen_status: bool = false
var _vet_boost: float = 1.0
var _flare: float = 0.0
var _flash_v: float = 0.0
var _flash_gold: bool = false
var _team_pending: Variant = null
var _tint: Color = Color(0.35, 0.70, 0.25)
var _morph_written: float = -1.0
var _heal_written: float = -1.0
var _ao_written: float = -999.0
var _glow_written: Dictionary = {}
var _fx_state: int = -1
## G-F (tests/test_gf_offscreen_emitters.gd): set by Unit._build_model like the kit's. While the treant is off-camera
## (OffscreenEmitters.outside_view, re-checked every 0.1 s) the petals and heal motes stop (the animation goes on).
var offscreen_freeze: bool = false
var _offscreen: bool = false
var _off_timer: float = 0.0


# ================================================================ lifecycle

func _ready() -> void:
	_phase_off = float(hash(get_instance_id()) % 100) / 100.0 * idle_period
	_tier_timer = float(hash(get_instance_id()) % 50) / 100.0
	_piv.resize(TM.NP)
	for a: PackedVector3Array in [_rest_pos, _off_pos, _off_rot, _rooted_rot, _rooted_pos]:
		a.resize(TM.NP)
	for i: int in TM.NP:
		var n := get_node_or_null(TM.PIVOT_PATHS[i]) as Node3D
		_piv[i] = n
		_rooted_rot[i] = TM.ROOTED_ROT[i] * DEG
		_rooted_pos[i] = TM.ROOTED_POS[i]
		if n:
			_pidx.append(i)
			_rest_pos[i] = n.position
	_spread = _piv[TM.P_SPREAD]
	_shadow = get_node_or_null("Shadow") as GeometryInstance3D
	_tint = kingdom_color
	_build_parts()
	_collect(self)
	_ready_done = true
	for gi: GeometryInstance3D in _flash_nodes:
		gi.set_instance_shader_parameter(&"ao_height", body_height)
		gi.set_instance_shader_parameter(&"hit_flash", 0.0)
	_write_tint()
	if _team_pending != null:
		set_team_color(_team_pending)
	_animate(0.0)


func _build_parts() -> void:
	for i: int in TM.NP:
		if i == TM.P_ROOT or _piv[i] == null:
			continue
		var mi := MeshInstance3D.new()
		mi.name = String(TM.PIVOT_PATHS[i].get_file()) + "Mesh"
		mi.mesh = TM.mesh(i)
		mi.position = -model_origin(_piv[i])
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if TM.SHADOW_PIVOTS.has(i) \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_piv[i].add_child(mi)
		# the rooted-only canopy of this pivot: its own node, hidden while walking
		var gm := TM.growth_mesh(i)
		if gm:
			var g := MeshInstance3D.new()
			g.name = String(TM.PIVOT_PATHS[i].get_file()) + "Growth"
			g.mesh = gm
			g.position = mi.position
			g.visible = false
			_piv[i].add_child(g)
			_growth_nodes.append(g)
	if _spread:
		_growth_nodes.append(_spread)
	# volley origin markers (no geometry): canopy centres + the crown
	for side: int in 2:
		var sx := -1.0 if side == 0 else 1.0
		var fi := TM.P_FORE_L if side == 0 else TM.P_FORE_R
		var mk := Node3D.new()
		mk.name = "VolleyL" if side == 0 else "VolleyR"
		_add_at(fi, mk, TM.canopy_centre(sx))
		_markers.append(mk)
	var cr := Node3D.new()
	cr.name = "Crown"
	_add_at(TM.P_HEAD, cr, TM.crown_canopy_centre())
	_markers.append(cr)
	# petals drifting down from the crown (world space: they trail behind it)
	_petals = _make_petals()
	_petals.name = "Petals"
	_add_at(TM.P_HEAD, _petals, Vector3(0.0, 3.95, 0.05))
	# heal motes rising around the trunk
	_motes = _make_motes()
	_motes.name = "HealMotes"
	_add_at(TM.P_CHEST, _motes, Vector3(0.0, 1.5, 0.0))
	ensure_shadow_blob()


func _add_at(i: int, n: Node3D, model_pos: Vector3) -> void:
	n.position = model_pos - model_origin(_piv[i])
	_piv[i].add_child(n)


## Model-space rest position of a node (pivots are unrotated at rest).
func model_origin(n: Node3D) -> Vector3:
	var p := Vector3.ZERO
	var c: Node = n
	while c and c != self:
		p += (c as Node3D).position
		c = c.get_parent()
	return p


static var _blob_plane: PlaneMesh


func ensure_shadow_blob() -> void:
	if _shadow == null:
		var mi := MeshInstance3D.new()
		mi.name = "Shadow"
		# G-C: one shared unit plane for every treant (Art Lab B9m: no mesh built per instance)
		if _blob_plane == null:
			var pm := PlaneMesh.new()
			pm.size = Vector2.ONE
			_blob_plane = pm
		mi.mesh = _blob_plane
		mi.material_override = load(BLOB_MAT)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3(0, 0.02, 0)
		add_child(mi)
		_shadow = mi
	_shadow.set_instance_shader_parameter(&"blob_color", Color(0.05, 0.04, 0.02, 0.45))


static var _petal_pm: ParticleProcessMaterial
static var _petal_draw: QuadMesh
static var _mote_pm: ParticleProcessMaterial
static var _mote_draw: QuadMesh
static var _mote_tex: Texture2D
static var _shader_iu: Dictionary = {}


## Soft round mask (bright core, smooth falloff), shared by the petals and the motes.
static func _soft_texture() -> Texture2D:
	if _mote_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(0, 0, 0, 0))
		g.add_point(0.25, Color(1, 1, 1, 0.9))
		g.add_point(0.6, Color(0.45, 0.45, 0.45, 0.35))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.0, 0.5)
		gt.width = 32
		gt.height = 32
		_mote_tex = gt
	return _mote_tex


## Green heal motes rising around the trunk (additive, like the kit's motes). Off until healing.
static func _make_motes() -> GPUParticles3D:
	if _mote_pm == null:
		var pm := ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = 1.15
		pm.direction = Vector3.UP
		pm.spread = 25.0
		pm.initial_velocity_min = 0.45
		pm.initial_velocity_max = 0.8
		pm.gravity = Vector3.ZERO
		var cv := Curve.new()
		cv.add_point(Vector2(0, 0.4))
		cv.add_point(Vector2(0.2, 1.0))
		cv.add_point(Vector2(1, 0.2))
		var ct := CurveTexture.new()
		ct.curve = cv
		pm.scale_curve = ct
		_mote_pm = pm
		var q := QuadMesh.new()
		q.size = Vector2(0.2, 0.2)
		var sm := StandardMaterial3D.new()
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		sm.disable_fog = true  # G-E 5: an additive quad must not fog
		sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		sm.billboard_keep_scale = true
		sm.albedo_texture = _soft_texture()
		sm.albedo_color = Color(HEAL_COLOR.r * 2.0, HEAL_COLOR.g * 2.0, HEAL_COLOR.b * 2.0, 1.0)
		q.material = sm
		_mote_draw = q
	var p := GPUParticles3D.new()
	p.amount = 12
	p.lifetime = 2.2
	p.emitting = false
	p.process_material = _mote_pm
	p.draw_pass_1 = _mote_draw
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-3.0, -2.0, -3.0), Vector3(6.0, 6.0, 6.0))
	return p


## Instance uniform names of a material's shader (#include files resolved), cached per shader.
static func _uniform_names(mat: Material) -> PackedStringArray:
	if not mat is ShaderMaterial or (mat as ShaderMaterial).shader == null:
		return PackedStringArray()
	var sh := (mat as ShaderMaterial).shader
	if not _shader_iu.has(sh):
		var names := PackedStringArray()
		_scan_uniforms(sh.code, names, 0)
		_shader_iu[sh] = names
	return _shader_iu[sh]


static func _scan_uniforms(code: String, names: PackedStringArray, depth: int) -> void:
	for line: String in code.split("\n", false):
		var l := line.strip_edges()
		if l.begins_with("instance uniform "):
			var w := l.substr(17).split(" ", false)
			if w.size() >= 2:
				var nm: String = w[1]
				for sep: String in [":", "=", ";"]:
					nm = nm.get_slice(sep, 0)
				names.append(nm)
		elif l.begins_with("#include") and depth < 4:
			var q := l.split("\"")
			if q.size() >= 2:
				var inc := load(q[1]) as ShaderInclude
				if inc:
					_scan_uniforms(inc.code, names, depth + 1)


static func _make_petals() -> GPUParticles3D:
	if _petal_pm == null:
		var pm := ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = Vector3(0.6, 0.15, 0.5)
		pm.direction = Vector3(0, -1, 0)
		pm.spread = 70.0
		pm.initial_velocity_min = 0.1
		pm.initial_velocity_max = 0.35
		pm.gravity = Vector3(0.12, -0.38, 0.05)
		pm.angular_velocity_min = -90.0
		pm.angular_velocity_max = 90.0
		pm.angle_min = 0.0
		pm.angle_max = 360.0
		var g := Gradient.new()
		g.set_color(0, Color(1.0, 0.62, 0.78))
		g.set_color(1, Color(1.0, 0.92, 0.95))
		var gt := GradientTexture1D.new()
		gt.gradient = g
		pm.color_initial_ramp = gt
		var cv := Curve.new()
		cv.add_point(Vector2(0, 0.6))
		cv.add_point(Vector2(0.15, 1.0))
		cv.add_point(Vector2(0.85, 1.0))
		cv.add_point(Vector2(1, 0.0))
		var ct := CurveTexture.new()
		ct.curve = cv
		pm.scale_curve = ct
		_petal_pm = pm
		var q := QuadMesh.new()
		q.size = Vector2(0.17, 0.12)
		var sm := StandardMaterial3D.new()
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		sm.billboard_keep_scale = true
		sm.vertex_color_use_as_albedo = true
		sm.albedo_texture = _soft_texture()
		sm.albedo_color = Color(1.1, 1.0, 1.0, 1.0)
		q.material = sm
		_petal_draw = q
	var p := GPUParticles3D.new()
	p.amount = 8
	p.lifetime = 3.2
	p.process_material = _petal_pm
	p.draw_pass_1 = _petal_draw
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-3.0, -5.0, -3.0), Vector3(6.0, 6.5, 6.0))
	return p


func _collect(n: Node) -> void:
	for c: Node in n.get_children():
		if c is GeometryInstance3D and c != _shadow and not c is GPUParticles3D:
			var gi := c as GeometryInstance3D
			_mesh_nodes.append(gi)
			_node_pivot[gi] = _pivot_index_of(gi)
			var names := PackedStringArray()
			for m: Material in _materials_of(gi):
				names.append_array(_uniform_names(m))
			if names.has("hit_flash"):
				_flash_nodes.append(gi)
		_collect(c)


func _pivot_index_of(n: Node) -> int:
	var c: Node = n
	while c and c != self:
		var k := _piv.find(c)
		if k >= 0:
			return k
		c = c.get_parent()
	return -1


func _materials_of(gi: GeometryInstance3D) -> Array[Material]:
	var out: Array[Material] = []
	if gi.material_override:
		out.append(gi.material_override)
		return out
	if gi is MeshInstance3D and (gi as MeshInstance3D).mesh:
		var mi := gi as MeshInstance3D
		for s: int in mi.mesh.get_surface_count():
			var m := mi.mesh.surface_get_material(s)
			if m:
				out.append(m)
	return out


# ================================================================ hooks

## Kingdom colour -> the waist garland (instance uniform team_tint, no material duplicate).
func set_team_color(c: Color) -> void:
	if not _ready_done:
		_team_pending = c
		return
	_team_pending = null
	_tint = c
	_write_tint()


func set_moving(speed: float) -> void:
	_speed = maxf(speed, 0.0)


## Walking: the arm slam (alternating arms). Rooted: the thorn volley. Ignored during the morph.
func play_attack() -> void:
	if _dead or is_morphing():
		return
	if _root_k >= 0.999:
		play_volley()
		return
	_action = &"attack"
	_action_t = 0.0
	_attack_side = -_attack_side


func play_cast(_spell_id: StringName) -> void:
	play_attack()


## The thorn volley (rooted form): the canopy draws back while the pods flare, then snaps forward
## (volley_released at VOLLEY_RELEASE) and shivers.
func play_volley() -> void:
	if _dead or is_morphing() or _root_k < 0.999:
		return
	_action = &"volley"
	_action_t = 0.0


func play_hit() -> void:
	if _dead or _t - _last_hit_time < 0.15:
		return
	_last_hit_time = _t
	_hit_t = 0.0


func play_death() -> void:
	if _dead:
		return
	_dead = true
	_death_t = 0.0
	_death_emitted = false
	_action = &""
	_hit_t = 99.0
	_speed = 0.0
	_update_fx()
	set_process(true)


func revive() -> void:
	_dead = false
	_death_t = 0.0
	_death_emitted = false
	_glows_off = false
	_action = &""
	_hit_t = 99.0
	_level_t = 99.0
	_speed = 0.0
	_walk_w = 0.0
	_root_k = 0.0
	_root_target = 0.0
	_flare = 0.0
	_set_flash(0.0)
	if _shadow:
		_shadow.transparency = 0.0
	_glow_written.clear()
	set_process(true)
	_update_fx()
	_animate(0.0)


## Take root (true) or uproot (false): the 3 s morph (reverses smoothly if called again mid-way).
## instant: jump to the end state (spawn / load); root_changed is emitted either way when the state is reached.
func set_rooted(on: bool, instant: bool = false) -> void:
	if _dead:
		return
	var target := 1.0 if on else 0.0
	_root_target = target
	if on or _root_k > 0.0:
		_action = &"" if _action == &"attack" else _action
	if instant:
		_root_k = target
		_animate(0.0)
		root_changed.emit(on)


func is_rooted() -> bool:
	return _root_target >= 1.0 and _root_k >= 1.0


## 0 = walking form .. 1 = rooted form.
func root_progress() -> float:
	return _root_k


func is_morphing() -> bool:
	return _root_k != _root_target


## Walking regeneration (idle regen) shows half the heal glow; the rooted form always shows the full one.
func set_regen(on: bool) -> void:
	_regen = on


## World positions the thorn volley leaves from: left canopy, right canopy, crown.
func get_volley_origins() -> PackedVector3Array:
	var out := PackedVector3Array()
	for mk: Node3D in _markers:
		if mk.is_inside_tree():
			out.append(mk.global_position)
		else:
			out.append(global_transform * model_origin(mk))
	return out


## Titans have no veterancy (spec 3.4); kept for the kit contract (glow multiplier).
func set_veterancy(level: int) -> void:
	_vet_boost = [1.0, 1.0, 1.25, 1.5, 1.8][clampi(level, 0, 4)]


func play_level_up() -> void:
	if not _dead:
		_level_t = 0.0


func set_carrying(_on: bool) -> void:
	pass


func play_mine() -> void:
	pass


## haste -> brighter glows (true). frozen -> holds the pose (false: the ice look is the VFX's).
func set_status(id: StringName, on: bool) -> bool:
	match id:
		&"haste":
			_haste = on
			return true
		&"frozen":
			_frozen_status = on
	return false


func glow_level() -> float:
	if _glows_off:
		return 0.0
	return _vet_boost * (1.3 if _haste else 1.0)


# ================================================================ per frame

func _process(delta: float) -> void:
	_t += delta
	_tier_timer -= delta
	if _tier_timer <= 0.0:
		_tier_timer = 0.5
		_update_tier()
	var off := false
	if offscreen_freeze:
		_off_timer -= delta
		if _off_timer <= 0.0 or _offscreen:
			_off_timer = 0.1
			off = OffscreenEmitters.outside_view(self)
		else:
			off = _offscreen
	if off != _offscreen:
		_offscreen = off
		_update_fx()
	var busy: bool = _dead or _action != &"" or _hit_t < HIT_LEN or _level_t < LEVEL_LEN or is_morphing() \
		or _speed >= 0.3 or _walk_w > 0.0
	_acc += delta
	if _tier == 2 and not busy:
		return
	if _tier >= 1 and ((Engine.get_process_frames() + get_instance_id()) & 1) == 1:
		return
	var dt := _acc
	_acc = 0.0
	_animate(dt)


func _update_tier() -> void:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	var nt: int = 1
	if cam:
		var d := cam.global_position.distance_to(global_position)
		nt = 0 if d < 30.0 else (1 if d < 45.0 else 2)
	_tier = nt
	_update_fx()
	if is_inside_tree():
		var y := global_position.y
		if absf(y - _ao_written) > 0.05:
			_ao_written = y
			for gi: GeometryInstance3D in _mesh_nodes:
				gi.set_instance_shader_parameter(&"ao_bottom", y)


## Petals while alive and near; heal motes while healing too.
func _update_fx() -> void:
	if _petals == null:
		return
	var near := _tier < 2 and not _dead and not _offscreen
	var st := (1 if near else 0) + (2 if near and _heal_level() > 0.3 else 0)
	if st == _fx_state:
		return
	_fx_state = st
	_petals.emitting = (st & 1) != 0
	_motes.emitting = (st & 2) != 0


func _heal_level() -> float:
	if _dead:
		return 0.0
	return maxf(smoothstep(0.3, 1.0, _root_k), 0.55 if _regen else 0.0)


func _animate(dt: float) -> void:
	for i: int in _pidx:
		_off_pos[i] = Vector3.ZERO
		_off_rot[i] = Vector3.ZERO
	var pdt := 0.0 if _frozen_status else dt
	_update_root(dt)
	if _dead:
		_pose_root(_root_k)
		_pose_death(dt)
	else:
		var walk_target := 1.0 if _speed >= 0.3 and _root_k == 0.0 and _root_target == 0.0 else 0.0
		_walk_w = move_toward(_walk_w, walk_target, dt / 0.3)
		var arm_w := smoothstep(0.22, 0.85, _root_k)
		_pose_idle(1.0 - _walk_w, arm_w)
		if _walk_w > 0.0:
			var rate := _speed / maxf(stride_speed, 0.1)
			_walk_p = fmod(_walk_p + pdt * rate / maxf(stride_time, 0.05), 1.0)
			_pose_walk(_walk_w)
		_pose_root(_root_k)
		if _action != &"":
			var prev := _action_t
			_action_t += pdt
			if _action == &"attack":
				_pose_attack(prev, _action_t)
				if _action_t >= ATTACK_LEN:
					_action = &""
			else:
				_pose_volley(prev, _action_t)
				if _action_t >= VOLLEY_LEN:
					_action = &""
					_flare = 0.0
		if _hit_t < HIT_LEN:
			_hit_t += dt
			_pose_hit(_hit_t, arm_w)
	_update_flash(dt)
	_apply()
	_apply_uniforms()


func _update_root(dt: float) -> void:
	if _root_k == _root_target or _dead:
		return
	_root_k = move_toward(_root_k, _root_target, dt / ROOT_TIME)
	if _root_k == _root_target:
		_update_fx()
		root_changed.emit(_root_target >= 1.0)


# ---------------------------------------------------------------- poses

## Walking-form idle (slow breath, the head looks about, arms sway) blended into the rooted idle (the canopy sways
## in the wind, the face turns slowly).
func _pose_idle(w: float, arm_w: float) -> void:
	var ph := (_t + _phase_off) * TAU / idle_period
	var s := sin(ph)
	var wi := w * (1.0 - arm_w)
	pos(TM.P_ROOT, Vector3(0.0, 0.025 * s * wi, 0.0))
	rot(TM.P_CHEST, Vector3((1.6 * s + 3.0) * DEG * wi, 0.0, 0.0))
	rot(TM.P_HEAD, Vector3(-2.0 * s * DEG * wi, 6.0 * sin(0.45 * ph + 1.0) * DEG * wi, 0.0))
	rot(TM.P_ARM_L, Vector3(-3.0 * DEG * wi, 0.0, (-4.0 - 2.0 * sin(ph + 0.6)) * DEG * wi))
	rot(TM.P_ARM_R, Vector3(-3.0 * DEG * wi, 0.0, (4.0 + 2.0 * sin(ph + 1.4)) * DEG * wi))
	var fore_bend := (1.0 - smoothstep(0.4, 0.95, _root_k))
	rot(TM.P_FORE_L, Vector3((-12.0 - 3.0 * s) * DEG * fore_bend, 0.0, 0.0))
	rot(TM.P_FORE_R, Vector3((-12.0 - 3.0 * sin(ph + 0.8)) * DEG * fore_bend, 0.0, 0.0))
	# rooted: the canopy sways
	var wr := arm_w
	if wr > 0.0:
		var wind := (_t + _phase_off) * TAU / 5.5
		rot(TM.P_ARM_L, Vector3(1.5 * sin(wind + 0.4) * DEG * wr, 0.0, 2.4 * sin(wind) * DEG * wr))
		rot(TM.P_ARM_R, Vector3(1.5 * sin(wind + 1.2) * DEG * wr, 0.0, 2.4 * sin(wind + 0.9) * DEG * wr))
		rot(TM.P_FORE_L, Vector3(0.0, 0.0, 3.2 * sin(wind - 0.7) * DEG * wr))
		rot(TM.P_FORE_R, Vector3(0.0, 0.0, 3.2 * sin(wind + 0.2) * DEG * wr))
		rot(TM.P_HEAD, Vector3(0.0, 4.0 * sin(wind * 0.37) * DEG * wr, 0.0))
		rot(TM.P_CHEST, Vector3(0.8 * sin(ph) * DEG * wr, 0.0, 0.0))


## Heavy lumbering walk: long leg swings, knees lift on the swing, a dip at every footfall, hips roll, the chest
## counter-twists, the arms swing opposite with a lagging forearm, hunched forward.
func _pose_walk(w: float) -> void:
	var a := TAU * _walk_p
	var s := sin(a)
	var c := cos(a)
	rot(TM.P_LEG_L, Vector3(30.0 * s * DEG * w, 0.0, 0.0))
	rot(TM.P_LEG_R, Vector3(-30.0 * s * DEG * w, 0.0, 0.0))
	rot(TM.P_SHIN_L, Vector3(40.0 * maxf(0.0, -c) * DEG * w, 0.0, 0.0))
	rot(TM.P_SHIN_R, Vector3(40.0 * maxf(0.0, c) * DEG * w, 0.0, 0.0))
	pos(TM.P_ROOT, Vector3(0.0, (0.09 * c * c - 0.06) * w, 0.0))
	rot(TM.P_HIPS, Vector3(0.0, 6.0 * s * DEG * w, 3.0 * c * DEG * w))
	rot(TM.P_CHEST, Vector3(6.0 * DEG * w, -5.0 * s * DEG * w, -2.5 * c * DEG * w))
	rot(TM.P_HEAD, Vector3(-4.0 * DEG * w + 2.0 * c * c * DEG * w, 4.0 * s * DEG * w, 0.0))
	rot(TM.P_ARM_L, Vector3(-18.0 * s * DEG * w, 0.0, 0.0))
	rot(TM.P_ARM_R, Vector3(18.0 * s * DEG * w, 0.0, 0.0))
	rot(TM.P_FORE_L, Vector3((-10.0 * sin(a - 0.9) - 6.0) * DEG * w, 0.0, 0.0))
	rot(TM.P_FORE_R, Vector3((10.0 * sin(a - 0.9) - 6.0) * DEG * w, 0.0, 0.0))


## The morph: legs and sink first (0 .. 0.45), then chest, face and arms (0.22 .. 0.85), forearms last
## (0.4 .. 0.95); a straining tremble and a crouch while it changes. At k = 1 the offsets are exactly
## treant_mesh.gd's ROOTED_* (the canopy geometry is authored in that pose).
func _pose_root(k: float) -> void:
	if k <= 0.0:
		return
	var e1 := smoothstep(0.0, 0.45, k)
	var e2 := smoothstep(0.22, 0.85, k)
	var e3 := smoothstep(0.4, 0.95, k)
	for i: int in [TM.P_ROOT, TM.P_HIPS, TM.P_LEG_L, TM.P_SHIN_L, TM.P_LEG_R, TM.P_SHIN_R]:
		rot(i, _rooted_rot[i] * e1)
		pos(i, _rooted_pos[i] * e1)
	for i: int in [TM.P_CHEST, TM.P_HEAD, TM.P_ARM_L, TM.P_ARM_R]:
		rot(i, _rooted_rot[i] * e2)
	for i: int in [TM.P_FORE_L, TM.P_FORE_R]:
		rot(i, _rooted_rot[i] * e3)
	if is_morphing() and not _dead:
		var env := 4.0 * k * (1.0 - k)
		rot(TM.P_CHEST, Vector3(4.0 * env * DEG, 0.0, 1.4 * sin(_t * 21.0) * env * DEG))
		rot(TM.P_HEAD, Vector3(-5.0 * env * DEG, 0.0, 0.0))
		pos(TM.P_ROOT, Vector3(0.02 * sin(_t * 27.0) * env, -0.08 * env, 0.0))


## Overhead slam with one arm (alternating): raise (0 .. 0.10), smash down (strike ATTACK_STRIKE), recover.
func _pose_attack(_prev: float, t: float) -> void:
	var sd := _attack_side
	var arm := TM.P_ARM_R if sd > 0.0 else TM.P_ARM_L
	var fore := TM.P_FORE_R if sd > 0.0 else TM.P_FORE_L
	var other := TM.P_ARM_L if sd > 0.0 else TM.P_ARM_R
	var t0 := 0.0
	var t1 := 0.10
	var t2 := ATTACK_STRIKE
	var t3 := ATTACK_LEN
	rot(arm, Vector3(_k3(t, t0, t1, t2, t3, -150.0, -28.0) * DEG, 0.0, _k3(t, t0, t1, t2, t3, 8.0 * sd, -6.0 * sd) * DEG))
	rot(fore, Vector3(_k3(t, t0, t1, t2, t3, -35.0, -4.0) * DEG, 0.0, 0.0))
	rot(other, Vector3(_k3(t, t0, t1, t2, t3, -18.0, 12.0) * DEG, 0.0, 0.0))
	rot(TM.P_CHEST, Vector3(_k3(t, t0, t1, t2, t3, -10.0, 16.0) * DEG, _k3(t, t0, t1, t2, t3, 12.0 * sd, -10.0 * sd) * DEG,
		0.0))
	rot(TM.P_HEAD, Vector3(_k3(t, t0, t1, t2, t3, -8.0, 10.0) * DEG, 0.0, 0.0))
	pos(TM.P_ROOT, Vector3(0.0, _k3(t, 0.06, t2, 0.32, t3, -0.10, -0.08), _k3(t, t0, t1, t2, t3, -0.06, 0.22)))
	var lead := TM.P_LEG_L if sd > 0.0 else TM.P_LEG_R
	var back := TM.P_LEG_R if sd > 0.0 else TM.P_LEG_L
	rot(lead, Vector3(_k3(t, t0, t1, t2, t3, -6.0, -18.0) * DEG, 0.0, 0.0))
	rot(back, Vector3(_k3(t, t0, t1, t2, t3, 4.0, 14.0) * DEG, 0.0, 0.0))
	rot(TM.P_SHIN_L if sd > 0.0 else TM.P_SHIN_R, Vector3(_k3(t, t0, t1, t2, t3, 8.0, 20.0) * DEG, 0.0, 0.0))


## Thorn volley: the canopy draws back while the pods flare (0 .. 0.15), snaps forward (volley_released), shivers.
func _pose_volley(prev: float, t: float) -> void:
	var ts: Array = [0.0, VOLLEY_RELEASE, 0.30, VOLLEY_LEN]
	var ax := _kf(t, ts, [0.0, 12.0, -16.0, 0.0])
	var fx := _kf(t, ts, [0.0, 10.0, -14.0, 0.0])
	var shake := 0.0
	if t > 0.3:
		shake = 4.0 * exp(-(t - 0.3) * 7.0) * sin((t - 0.3) * 32.0)
	rot(TM.P_ARM_L, Vector3(ax * DEG, 0.0, shake * DEG))
	rot(TM.P_ARM_R, Vector3(ax * DEG, 0.0, -shake * DEG))
	rot(TM.P_FORE_L, Vector3(fx * DEG, 0.0, 1.4 * shake * DEG))
	rot(TM.P_FORE_R, Vector3(fx * DEG, 0.0, -1.4 * shake * DEG))
	rot(TM.P_HEAD, Vector3(_kf(t, ts, [0.0, -8.0, 7.0, 0.0]) * DEG, 0.0, 0.0))
	rot(TM.P_CHEST, Vector3(_kf(t, ts, [0.0, -3.0, 4.0, 0.0]) * DEG, 0.0, 0.0))
	_flare = _kf(t, [0.0, VOLLEY_RELEASE, 0.35, VOLLEY_LEN], [0.0, 1.7, 0.5, 0.0])
	if prev < VOLLEY_RELEASE and t >= VOLLEY_RELEASE:
		volley_released.emit()


## A jolt back (walking) or a shiver through the canopy (rooted); white flash on bark and leaves.
func _pose_hit(t: float, arm_w: float) -> void:
	var k: float = clampf(t / 0.06, 0.0, 1.0) if t < 0.06 else clampf(1.0 - (t - 0.06) / (HIT_LEN - 0.06), 0.0, 1.0)
	k = k * k * (3.0 - 2.0 * k)
	var wk := 1.0 - arm_w
	rot(TM.P_CHEST, Vector3(-7.0 * k * DEG, 0.0, 0.0))
	rot(TM.P_HEAD, Vector3(-10.0 * k * DEG, 0.0, 0.0))
	pos(TM.P_ROOT, Vector3(0.0, 0.0, -0.08 * k * wk))
	if arm_w > 0.0:
		var sh := 3.5 * k * sin(t * 45.0) * arm_w
		rot(TM.P_ARM_L, Vector3(0.0, 0.0, sh * DEG))
		rot(TM.P_ARM_R, Vector3(0.0, 0.0, -sh * DEG))
	_flash_gold = false


## A felled tree: it groans and rears back (0 .. 0.35), topples forward (accelerating), crashes at DEATH_IMPACT (a
## bounce, the arms flop, the glows go out), then sinks into the ground; death_finished at DEATH_LEN.
func _pose_death(dt: float) -> void:
	_death_t += dt
	var t := _death_t
	var creak := _ease_out(clampf(t / 0.35, 0.0, 1.0)) * (1.0 - clampf((t - 0.35) / 0.3, 0.0, 1.0))
	var fall := _ease_in(clampf((t - 0.3) / (DEATH_IMPACT - 0.3), 0.0, 1.0))
	var landed := t >= DEATH_IMPACT
	var tilt := 84.0 * fall - 5.0 * creak
	var ti := t - DEATH_IMPACT
	if landed:
		tilt = 84.0 - 5.0 * exp(-ti * 7.0) * absf(sin(ti * 18.0))
		if not _glows_off:
			_glows_off = true
			_update_fx()
	rot(TM.P_ROOT, Vector3(tilt * DEG, 0.0, 6.0 * fall * DEG))
	rot(TM.P_CHEST, Vector3(-12.0 * creak * DEG, 0.0, 0.0))
	rot(TM.P_HEAD, Vector3((-18.0 * creak + 12.0 * fall) * DEG, 0.0, 0.0))
	var flop := _ease_out(clampf(ti / 0.25, 0.0, 1.0)) if landed else 0.0
	rot(TM.P_ARM_L, Vector3((-40.0 * fall - 30.0 * flop) * DEG, 0.0, (-25.0 * creak - 20.0 * flop) * DEG))
	rot(TM.P_ARM_R, Vector3((-40.0 * fall - 30.0 * flop) * DEG, 0.0, (25.0 * creak + 20.0 * flop) * DEG))
	rot(TM.P_LEG_L, Vector3(-10.0 * fall * DEG, 0.0, 0.0))
	rot(TM.P_LEG_R, Vector3(8.0 * fall * DEG, 0.0, 0.0))
	var sink := _ease_in(clampf((t - 1.3) / (DEATH_LEN - 1.3), 0.0, 1.0))
	pos(TM.P_ROOT, Vector3(0.0, -0.9 * sink, 0.0))
	pos(TM.P_SPREAD, Vector3(0.0, -0.5 * sink, 0.0))
	if _shadow:
		_shadow.transparency = clampf((t - 1.2) / 0.5, 0.0, 1.0)
	if t >= DEATH_LEN and not _death_emitted:
		_death_emitted = true
		death_finished.emit()
		set_process(false)


func _update_flash(dt: float) -> void:
	if _hit_t < HIT_LEN and not _dead:
		_flash_gold = false
		_set_flash(clampf(1.0 - _hit_t / 0.13, 0.0, 1.0))
	elif _level_t < LEVEL_LEN and not _dead:
		_level_t += dt
		_flash_gold = true
		_set_flash(0.42 * clampf(1.0 - _level_t / LEVEL_LEN, 0.0, 1.0))
	elif _flash_v != 0.0:
		_set_flash(0.0)


func _set_flash(v: float) -> void:
	if v == _flash_v:
		return
	_flash_v = v
	var col := GOLD if _flash_gold else WHITE
	for gi: GeometryInstance3D in _flash_nodes:
		gi.set_instance_shader_parameter(&"hit_flash", v)
		gi.set_instance_shader_parameter(&"flash_color", col)


# ================================================================ pose helpers

## Adds an Euler rotation offset (radians, YXZ) to pivot i for this frame.
func rot(i: int, r: Vector3) -> void:
	if _piv[i]:
		_off_rot[i] += r


## Adds a position offset (m, parent space) to pivot i for this frame.
func pos(i: int, p: Vector3) -> void:
	if _piv[i]:
		_off_pos[i] += p


## Keyframes 0 -> v1 (t0..t1) -> v2 (t1..t2) -> 0 (t2..t3), smooth (the kit's _k3).
static func _k3(t: float, t0: float, t1: float, t2: float, t3: float, v1: float, v2: float) -> float:
	if t <= t0 or t >= t3:
		return 0.0
	if t < t1:
		return v1 * _ease_out((t - t0) / maxf(t1 - t0, 0.0001))
	if t < t2:
		return lerpf(v1, v2, _ease_out((t - t1) / maxf(t2 - t1, 0.0001)))
	return v2 * (1.0 - smoothstep(0.0, 1.0, (t - t2) / maxf(t3 - t2, 0.0001)))


## Smooth keyframes (times ascending, values), smoothstep between keys, clamped at the ends.
static func _kf(t: float, ts: Array, vs: Array) -> float:
	if t <= float(ts[0]):
		return float(vs[0])
	for k: int in range(1, ts.size()):
		if t < float(ts[k]):
			var a := (t - float(ts[k - 1])) / maxf(float(ts[k]) - float(ts[k - 1]), 0.0001)
			return lerpf(float(vs[k - 1]), float(vs[k]), a * a * (3.0 - 2.0 * a))
	return float(vs[vs.size() - 1])


static func _ease_out(x: float) -> float:
	return 1.0 - (1.0 - x) * (1.0 - x)


static func _ease_in(x: float) -> float:
	return x * x


func _apply() -> void:
	for i: int in _pidx:
		_piv[i].transform = Transform3D(Basis.from_euler(_off_rot[i]), _rest_pos[i] + _off_pos[i])
	if _shadow:
		var s := lerpf(3.0, 4.8, smoothstep(0.0, 0.5, _root_k))
		_shadow.scale = Vector3(s, 1.0, s * 0.92)


## Per-node instance uniforms: root_morph (all), heal_glow (all), glow_boost (the eyes brighten when rooted, the
## pods and eyes flare with the volley; 0 = dead).
func _apply_uniforms() -> void:
	if not _ready_done:
		return
	if absf(_root_k - _morph_written) > 0.0005:
		_morph_written = _root_k
		for gi: GeometryInstance3D in _mesh_nodes:
			gi.set_instance_shader_parameter(&"root_morph", _root_k)
		var show := _root_k > 0.001
		for g: Node3D in _growth_nodes:
			g.visible = show
	var h := _heal_level()
	if absf(h - _heal_written) > 0.01:
		_heal_written = h
		for gi: GeometryInstance3D in _mesh_nodes:
			gi.set_instance_shader_parameter(&"heal_glow", h)
		_update_fx()
	var g := glow_level()
	for gi: GeometryInstance3D in _mesh_nodes:
		var pi: int = _node_pivot.get(gi, -1)
		var v := g
		if pi == TM.P_HEAD:
			v = g * (1.0 + 0.35 * _root_k + 0.6 * _flare)
		elif pi == TM.P_FORE_L or pi == TM.P_FORE_R:
			v = g * (1.0 + 1.3 * _flare)
		if absf(float(_glow_written.get(gi, -99.0)) - v) > 0.004:
			_glow_written[gi] = v
			gi.set_instance_shader_parameter(&"glow_boost", v)


func _write_tint() -> void:
	var v := Vector3(_tint.r, _tint.g, _tint.b)
	for gi: GeometryInstance3D in _mesh_nodes:
		gi.set_instance_shader_parameter(&"team_tint", v)
