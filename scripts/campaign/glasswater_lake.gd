class_name GlasswaterLake
extends Node3D
## Glasswater Mere, the frozen lake of mission 2 (docs/design/mission-02.md "Mechanic: thin ice"). Old Ice (r <=
## OLD_ICE, never breaks) plus 8 floes F0-F7 between OLD_ICE and LAKE_RADIUS; floe i covers the angles
## [i x 45 - 22.5, i x 45 + 22.5) (angle a places (cos a, sin a), +z = south). Each floe has cracks 0-4 and breaks
## at 4: every ground unit on it takes 80 damage (wizards 40, armor applies, attacker = the credit) and chill 4 s,
## it is moved to the nearest point outside the floe (ground items too), then the floe is open water (a wedge
## obstacle in group "navigation_geometry" under the nav region + a rebake) for `refreeze_time` s.
## Crack sources the mission forwards: `crack_at(pos, amount, credit)` (Fireball impact +1, Ember Step landing +1,
## Ash Hurler hit +0.25). Weight (12+ pop on a floe, wizards 0) adds +1 every 5 s while true; knitting removes 1 every
## 20 s without a new crack. Group "no_build_zones": no building at r <= NO_BUILD_RADIUS (BuildGrid asks).
## Placeholder art (M9.V1): ice disc, seams, crack line stages 1-3, a 0.4 s flash + 16 chunks on a break, open water
## (0.05, 0.15, 0.25) with 6 floating chunks.

signal floe_broken(index: int, credit: Node3D)
signal floe_refrozen(index: int)
signal cracks_changed(index: int, cracks: float)

const LAKE_RADIUS := 22.0
const OLD_ICE := 7.0
const NO_BUILD_RADIUS := 23.0
const FLOES := 8
const BREAK_AT := 4.0
const BREAK_DAMAGE := 80.0
const BREAK_DAMAGE_WIZARD := 40.0
const BREAK_CHILL := 4.0
const WEIGHT_POP := 12
const WEIGHT_INTERVAL := 5.0
const KNIT_INTERVAL := 20.0
const SLICE_DEG := 7.5
const ICE_COLOR := Color(0.62, 0.80, 0.92)
const DEEP_COLOR := Color(0.35, 0.55, 0.75)
const WATER_COLOR := Color(0.05, 0.15, 0.25)
const MSG_NO_BUILD := "Can't build on the frozen lake"

var refreeze_time := 45.0
## The level's BuildGrid (request_rebake) and its NavigationRegion3D (the wedge obstacles go under it).
var build_grid: BuildGrid
var nav_region: NavigationRegion3D
var cracks: Array[float] = []          ## Read only, per floe.
var open_left: Array[float] = []       ## Read only: > 0 while the floe is open water (seconds to refreeze).
var breaks := 0                        ## Read only: floes broken so far.

var _credit: Array = []                # last crediting node per floe (Vessa / a Fire unit / null)
var _since_crack: Array[float] = []
var _weight_time: Array[float] = []
var _obstacles: Array = []             # StaticBody3D or null per floe
var _water: Array = []                 # MeshInstance3D per floe (open water look)
var _crack_meshes: Array = []          # MeshInstance3D per floe (crack lines)
var _weight_tick := 0.0


func _ready() -> void:
	add_to_group(&"no_build_zones")
	add_to_group(&"glasswater_lake")
	for i in FLOES:
		cracks.append(0.0)
		open_left.append(0.0)
		_credit.append(null)
		_since_crack.append(0.0)
		_weight_time.append(0.0)
		_obstacles.append(null)
	_build_look()


# ---------------------------------------------------------------- queries

## Floe index under `pos` (-1 on Old Ice, off the lake or nowhere).
static func floe_at(pos: Vector3) -> int:
	var r := Vector2(pos.x, pos.z).length()
	if r <= OLD_ICE or r > LAKE_RADIUS:
		return -1
	var a := fposmod(rad_to_deg(atan2(pos.z, pos.x)) + 22.5, 360.0)
	return int(a / 45.0) % FLOES


static func on_lake(pos: Vector3) -> bool:
	return Vector2(pos.x, pos.z).length() <= LAKE_RADIUS


func is_open(index: int) -> bool:
	return index >= 0 and index < FLOES and open_left[index] > 0.0


## BuildGrid hook: "" or why a footprint cannot be placed (any part at r <= NO_BUILD_RADIUS).
func no_build_reason(rect: Rect2) -> String:
	var c := Vector2(clampf(0.0, rect.position.x, rect.end.x), clampf(0.0, rect.position.y, rect.end.y))
	return MSG_NO_BUILD if c.length() <= NO_BUILD_RADIUS else ""


# ---------------------------------------------------------------- cracks

## Adds `amount` cracks to the floe under `pos` (nothing on Old Ice / open water). `credit` gets the kills.
func crack_at(pos: Vector3, amount: float, credit: Node3D = null) -> void:
	crack(floe_at(pos), amount, credit)


func crack(index: int, amount: float, credit: Node3D = null) -> void:
	if index < 0 or index >= FLOES or is_open(index) or amount == 0.0:
		return
	cracks[index] = clampf(cracks[index] + amount, 0.0, BREAK_AT)
	if amount > 0.0:
		_since_crack[index] = 0.0
		_credit[index] = credit
	cracks_changed.emit(index, cracks[index])
	_update_cracks(index)
	if cracks[index] >= BREAK_AT:
		break_floe(index)


func _physics_process(delta: float) -> void:
	for i in FLOES:
		if open_left[i] > 0.0:
			open_left[i] -= delta
			if open_left[i] <= 0.0:
				_refreeze(i)
			continue
		if cracks[i] > 0.0:
			_since_crack[i] += delta
			if _since_crack[i] >= KNIT_INTERVAL:
				_since_crack[i] = 0.0
				cracks[i] = maxf(0.0, cracks[i] - 1.0)
				cracks_changed.emit(i, cracks[i])
				_update_cracks(i)
	_weight_tick -= delta
	if _weight_tick <= 0.0:
		var step := 0.5
		_weight_tick = step
		var pops := floe_pops()
		for i in FLOES:
			if is_open(i) or pops[i] < WEIGHT_POP:
				_weight_time[i] = 0.0
				continue
			_weight_time[i] += step
			if _weight_time[i] >= WEIGHT_INTERVAL:
				_weight_time[i] = 0.0
				var keep: Variant = _credit[i]
				crack(i, 1.0, null)   # weight: nobody gets the credit
				if not is_open(i):
					_credit[i] = keep


## Pop standing on each floe now (any team; wizards count 0).
func floe_pops() -> Array[int]:
	var out: Array[int] = []
	out.resize(FLOES)
	out.fill(0)
	if not is_inside_tree():
		return out
	for node in get_tree().get_nodes_in_group(&"units"):
		var u := node as Unit
		if u == null or not u.is_alive() or u is Wizard or u.unit_type == null:
			continue
		var i := floe_at(u.global_position)
		if i >= 0:
			out[i] += int(u.unit_type.pop)
	return out


# ---------------------------------------------------------------- break / refreeze

## Breaks floe `index` now (scripts / tests too): damage + chill + displacement, then open water.
func break_floe(index: int) -> void:
	if index < 0 or index >= FLOES or is_open(index):
		return
	var credit: Node3D = _credit[index] if is_instance_valid(_credit[index]) else null
	breaks += 1
	if is_inside_tree():
		for node in get_tree().get_nodes_in_group(&"units"):
			var u := node as Unit
			if u == null or not u.is_alive() or floe_at(u.global_position) != index:
				continue
			u.take_damage(BREAK_DAMAGE_WIZARD if u is Wizard else BREAK_DAMAGE, credit)
			if u.is_alive():
				u.apply_status(&"chill", BREAK_CHILL)
				u.global_position = outside_point(u.global_position, index)
				u.command_stop()
		for node in get_tree().get_nodes_in_group(&"item_pickups"):
			var p := node as Node3D
			if p and floe_at(p.global_position) == index:
				p.global_position = outside_point(p.global_position, index)
	cracks[index] = 0.0
	open_left[index] = refreeze_time
	_update_cracks(index)
	_add_obstacle(index)
	_break_fx(index)
	floe_broken.emit(index, credit)


## The nearest point outside floe `index` from `pos`: Old Ice inward, the shore outward, or the next floe sideways.
static func outside_point(pos: Vector3, index: int) -> Vector3:
	var flat := Vector2(pos.x, pos.z)
	var r := flat.length()
	var a := atan2(pos.z, pos.x)
	var lo := deg_to_rad(index * 45.0 - 22.5)
	var hi := deg_to_rad(index * 45.0 + 22.5)
	var cands: Array[Vector2] = [
		Vector2.from_angle(a) * (OLD_ICE - 0.8),
		Vector2.from_angle(a) * (LAKE_RADIUS + 1.0),
		Vector2.from_angle(lo - deg_to_rad(2.5) - 0.8 / maxf(r, 1.0)) * r,
		Vector2.from_angle(hi + deg_to_rad(2.5) + 0.8 / maxf(r, 1.0)) * r,
	]
	var best := cands[0]
	for c in cands:
		if c.distance_to(flat) < best.distance_to(flat):
			best = c
	return Vector3(best.x, pos.y, best.y)


func _refreeze(index: int) -> void:
	open_left[index] = 0.0
	cracks[index] = 0.0
	_since_crack[index] = 0.0
	var ob: Variant = _obstacles[index]
	if ob != null and is_instance_valid(ob):
		(ob as Node).queue_free()
	_obstacles[index] = null
	if _water.size() > index:
		(_water[index] as Node3D).visible = false
	_update_cracks(index)
	_rebake_after_frame()
	floe_refrozen.emit(index)


## The wedge obstacle: one convex prism per SLICE_DEG slice (layer 1, group "navigation_geometry").
func _add_obstacle(index: int) -> void:
	var body := StaticBody3D.new()
	body.name = "OpenWater%d" % index
	body.collision_layer = 1
	body.collision_mask = 0
	body.add_to_group(&"navigation_geometry")
	var a0 := index * 45.0 - 22.5
	var slices := int(45.0 / SLICE_DEG)
	for s in slices:
		var b0 := deg_to_rad(a0 + s * SLICE_DEG)
		var b1 := deg_to_rad(a0 + (s + 1) * SLICE_DEG)
		var pts := PackedVector3Array()
		for rr: float in [OLD_ICE + 0.6, LAKE_RADIUS - 0.4]:
			for b: float in [b0, b1]:
				for y: float in [-0.2, 1.6]:
					pts.append(Vector3(cos(b) * rr, y, sin(b) * rr))
		var shape := ConvexPolygonShape3D.new()
		shape.points = pts
		var col := CollisionShape3D.new()
		col.shape = shape
		body.add_child(col)
	var parent: Node = nav_region if nav_region != null else self
	parent.add_child(body)
	_obstacles[index] = body
	if _water.size() > index:
		(_water[index] as Node3D).visible = true
	if build_grid:
		build_grid.request_rebake()


func _rebake_after_frame() -> void:
	if build_grid and is_inside_tree():
		await get_tree().process_frame   # the freed obstacle is gone from the physics space first
		if is_instance_valid(build_grid):
			build_grid.request_rebake()


# ---------------------------------------------------------------- look (placeholder, M9.V1)

func _build_look() -> void:
	var disc := CylinderMesh.new()
	disc.top_radius = LAKE_RADIUS
	disc.bottom_radius = LAKE_RADIUS
	disc.height = 0.04
	disc.radial_segments = 96
	var ice := StandardMaterial3D.new()
	ice.albedo_color = ICE_COLOR
	ice.roughness = 0.12
	ice.metallic = 0.15
	ice.metallic_specular = 0.8
	ice.rim_enabled = true
	ice.rim = 0.3
	var mi := MeshInstance3D.new()
	mi.name = "IceDisc"
	mi.mesh = disc
	mi.material_override = ice
	mi.position.y = 0.02
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	# Deep streaks and the floe seams (lines on the ice).
	var seam := _line_material(Color(DEEP_COLOR, 0.55))
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES, seam)
	for i in FLOES:
		var a := deg_to_rad(i * 45.0 + 22.5)
		im.surface_add_vertex(Vector3(cos(a) * OLD_ICE, 0.06, sin(a) * OLD_ICE))
		im.surface_add_vertex(Vector3(cos(a) * LAKE_RADIUS, 0.06, sin(a) * LAKE_RADIUS))
	for k in 64:
		var a0 := TAU * k / 64.0
		var a1 := TAU * (k + 1) / 64.0
		im.surface_add_vertex(Vector3(cos(a0) * OLD_ICE, 0.06, sin(a0) * OLD_ICE))
		im.surface_add_vertex(Vector3(cos(a1) * OLD_ICE, 0.06, sin(a1) * OLD_ICE))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1202
	for k in 18:   # deep streaks
		var a := rng.randf() * TAU
		var r0 := rng.randf_range(3.0, 18.0)
		var len := rng.randf_range(2.0, 5.0)
		var b := a + rng.randf_range(-0.6, 0.6)
		im.surface_add_vertex(Vector3(cos(a) * r0, 0.05, sin(a) * r0))
		im.surface_add_vertex(Vector3(cos(a) * r0 + cos(b) * len, 0.05, sin(a) * r0 + sin(b) * len))
	im.surface_end()
	var lines := MeshInstance3D.new()
	lines.name = "Seams"
	lines.mesh = im
	lines.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(lines)
	for i in FLOES:
		var w := MeshInstance3D.new()
		w.name = "Water%d" % i
		w.mesh = _sector_mesh(i, 0.07)
		var wm := StandardMaterial3D.new()
		wm.albedo_color = WATER_COLOR
		wm.roughness = 0.05
		wm.metallic = 0.3
		wm.cull_mode = BaseMaterial3D.CULL_DISABLED
		w.material_override = wm
		w.visible = false
		w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(w)
		var chunk_mat := StandardMaterial3D.new()
		chunk_mat.albedo_color = Color(0.82, 0.92, 1.0)
		for c in 6:
			var box := BoxMesh.new()
			box.size = Vector3(rng.randf_range(0.6, 1.4), 0.2, rng.randf_range(0.5, 1.2))
			var cm := MeshInstance3D.new()
			cm.mesh = box
			cm.material_override = chunk_mat
			var ca := deg_to_rad(i * 45.0 + rng.randf_range(-18.0, 18.0))
			var cr := rng.randf_range(OLD_ICE + 2.0, LAKE_RADIUS - 2.0)
			cm.position = Vector3(cos(ca) * cr, 0.12, sin(ca) * cr)
			cm.rotation.y = rng.randf() * TAU
			w.add_child(cm)
		_water.append(w)
		var cmi := MeshInstance3D.new()
		cmi.name = "Cracks%d" % i
		cmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(cmi)
		_crack_meshes.append(cmi)


## Crack lines: stage 1 / 2 / 3 at 1 / 2 / 3 cracks (more and longer lines), none at 0.
func _update_cracks(index: int) -> void:
	if _crack_meshes.size() <= index:
		return
	var mi := _crack_meshes[index] as MeshInstance3D
	var stage := clampi(int(floor(cracks[index])), 0, 3)
	if stage == 0 or is_open(index):
		mi.mesh = null
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 7000 + index
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES, _line_material(Color(0.12, 0.2, 0.3, 0.9)))
	for k in stage * 5:
		var a := deg_to_rad(index * 45.0 + rng.randf_range(-20.0, 20.0))
		var r := rng.randf_range(OLD_ICE + 1.0, LAKE_RADIUS - 1.0)
		var p := Vector3(cos(a) * r, 0.07, sin(a) * r)
		for seg in 2 + stage:
			var dir := Vector3(rng.randf_range(-1, 1), 0.0, rng.randf_range(-1, 1)).normalized() * rng.randf_range(0.8, 2.0)
			im.surface_add_vertex(p)
			p += dir
			im.surface_add_vertex(p)
	im.surface_end()
	mi.mesh = im


func _break_fx(index: int) -> void:
	if not is_inside_tree():
		return
	var flash := MeshInstance3D.new()
	flash.mesh = _sector_mesh(index, 0.1)
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(1.0, 1.0, 1.0, 0.9)
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.cull_mode = BaseMaterial3D.CULL_DISABLED
	flash.material_override = fm
	add_child(flash)
	var tw := flash.create_tween()
	tw.tween_property(fm, "albedo_color:a", 0.0, 0.4)
	tw.tween_callback(flash.queue_free)
	var chunk_mat := StandardMaterial3D.new()
	chunk_mat.albedo_color = Color(0.85, 0.95, 1.0)
	for c in 16:
		var box := BoxMesh.new()
		box.size = Vector3(0.5, 0.3, 0.4) * randf_range(0.6, 1.5)
		var cm := MeshInstance3D.new()
		cm.mesh = box
		cm.material_override = chunk_mat
		var a := deg_to_rad(index * 45.0 + randf_range(-20.0, 20.0))
		var r := randf_range(OLD_ICE + 1.0, LAKE_RADIUS - 1.0)
		cm.position = Vector3(cos(a) * r, 0.1, sin(a) * r)
		add_child(cm)
		var up := cm.position + Vector3(randf_range(-1.0, 1.0), randf_range(1.0, 2.5), randf_range(-1.0, 1.0))
		var ctw := cm.create_tween()
		ctw.tween_property(cm, "position", up, 0.35).set_ease(Tween.EASE_OUT)
		ctw.tween_property(cm, "position:y", -0.3, 0.6).set_ease(Tween.EASE_IN)
		ctw.tween_callback(cm.queue_free)


func _sector_mesh(index: int, y: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := 12
	var a0 := deg_to_rad(index * 45.0 - 22.5)
	for s in steps:
		var b0 := a0 + deg_to_rad(45.0) * s / steps
		var b1 := a0 + deg_to_rad(45.0) * (s + 1) / steps
		var i0 := Vector3(cos(b0) * OLD_ICE, y, sin(b0) * OLD_ICE)
		var i1 := Vector3(cos(b1) * OLD_ICE, y, sin(b1) * OLD_ICE)
		var o0 := Vector3(cos(b0) * LAKE_RADIUS, y, sin(b0) * LAKE_RADIUS)
		var o1 := Vector3(cos(b1) * LAKE_RADIUS, y, sin(b1) * LAKE_RADIUS)
		st.set_normal(Vector3.UP)
		for v: Vector3 in [i0, o1, o0, i0, i1, o1]:
			st.add_vertex(v)
	return st.commit()


static func _line_material(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m
