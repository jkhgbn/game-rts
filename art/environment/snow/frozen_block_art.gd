class_name FrozenBlockArt
extends RefCounted
## G-F review 2 item 11 (docs/art/gf_m02.md): the frozen prisoners of mission 2, built in code, draw-only.
## - `dress_block(block)`: a Frozen Emberguard block (MissionFrozenEmberguard, scripts/campaign/frozen_emberguard.gd,
##   2.4 x 2.0 x 2.4, collider radius 1.2) becomes a leaning block of faceted ice (frozen_ice.gdshader: frosted facet
##   edges, rime on the base, cracks inside from Medium up) round a Flame Guard frozen mid-swing and an Ember Archer
##   behind him (the real Fire models, posed, process off, a cold multiply overlay: frozen_body.gdshader), on a snow
##   mound. The old placeholder box / capsules / stump are hidden (kept: the brazier code fades and hides "IceBlock").
##   Thaw (`lit_up`): the ice and the figures go at once, the block shatters into shards that fly, land and sink (10 at
##   High / Ultra, 7 Medium, 5 Low) and a low cold puff spreads; once "IceBlock" hides (the thaw tween, or a load of a
##   thawed block) a ring of broken ice teeth stays on the mound. Idempotent (meta `_frozen_block_art`).
## - `dress_shell(shell)`: a Sentinel's "IceShell" (MeshInstance3D, BoxMesh 2.6 x 3.6 x 2.6 centred at y 1.8 on the unit)
##   gets the same ice as a taller faceted block + a rime mound; `_shatter_shell` still frees it by name.
## - `block_mesh(size, rseed, centered, lean_deg)`: the faceted block (7-9 sided rings, a bulge, a slanted broken top,
##   a lean); `ice_material(height, y_min)`; `shard_mesh(rseed)`; `mound_mesh(inner, outer, height, rseed)`.
## Mission 2 already calls FrozenLook.dress_level(self) at the end of _build_map, which dresses every block; the
## Sentinel shells are made later (_spawn_sentinels) and need the one-line hook in docs/handoff/for-lead.md.
## Tiers: Low = no cracks / veils, fewer shards (the old block was one transparent box: about the same cost).

const ICE_SHADER := preload("res://art/environment/snow/frozen_ice.gdshader")
const BODY_SHADER := preload("res://art/environment/snow/frozen_body.gdshader")
const BACK_SHADER := preload("res://art/environment/snow/frozen_ice_back.gdshader")
const FROZEN_LOOK := "res://art/environment/snow/frozen_look.gd"
const GUARD_SCENE := "res://art/units/fire/flame_guard.tscn"
const ARCHER_SCENE := "res://art/units/fire/ember_archer.tscn"
const META := &"_frozen_block_art"
const BLOCK_SIZE := Vector3(2.5, 2.15, 2.4)     ## a little over the old 2.4 x 2.0 x 2.4 box (the soldier fits inside)
const SHELL_SIZE := Vector3(2.9, 3.9, 2.8)      ## Sentinel shell (old box 2.6 x 3.6 x 2.6)
const FIGURE_HEIGHT := 1.5                      ## the guard's height inside the block (the archer 0.92 of it)
const SHARDS: Array[int] = [5, 7, 10, 10]       ## shatter shards per tier
const PUFF_COLOR := Color(0.74, 0.80, 0.87, 0.32)
const GRAVITY := 9.0


## The graphics tier (FrozenLook.tier, load-guarded; High without it).
static func tier() -> int:
	if ResourceLoader.exists(FROZEN_LOOK):
		var fl := load(FROZEN_LOOK) as Script
		if fl and fl.has_method(&"tier"):
			return clampi(int(fl.call(&"tier")), 0, 3)
	return 2


## Clear block ice for a block `height` tall whose base sits at object y `y_min`. `volume`: from Medium up, a back-face
## pass (frozen_ice_back.gdshader, drawn first) gives the block its depth.
static func ice_material(height: float, y_min: float = 0.0, clarity: float = 0.52, volume: bool = false) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = ICE_SHADER
	m.set_shader_parameter(&"block_height", height)
	m.set_shader_parameter(&"y_min", y_min)
	m.set_shader_parameter(&"clarity", clarity)
	var q := tier()
	m.set_shader_parameter(&"gfx_detail", 1.0 if q >= 1 else 0.0)
	if volume and q >= 1:
		var back := ShaderMaterial.new()
		back.shader = BACK_SHADER
		back.render_priority = -1
		m.next_pass = back
	return m


## Restyles one Frozen Emberguard block (see the header). False when it is not one (no "IceBlock" child).
static func dress_block(block: Node3D) -> bool:
	if block == null or not is_instance_valid(block):
		return false
	if block.has_meta(META):
		return true
	var ice_root := block.get_node_or_null(^"IceBlock") as Node3D
	if ice_root == null:
		return false
	block.set_meta(META, true)
	var rseed := absi(hash(String(block.name))) % 100000
	var rng := RandomNumberGenerator.new()
	rng.seed = rseed
	# The placeholder: box + 3 capsules under IceBlock, and the cylinder stump.
	for c: Node in ice_root.get_children():
		if c is MeshInstance3D:
			(c as MeshInstance3D).visible = false
	var old_stump := block.get_node_or_null(^"Stump") as MeshInstance3D
	if old_stump:
		old_stump.visible = false

	var art := Node3D.new()
	art.name = "IceArt"
	ice_root.add_child(art)
	art.rotation.y = rng.randf_range(-PI, PI)
	# Figures first (opaque), the ice over them.
	var figures := Node3D.new()
	figures.name = "Figures"
	art.add_child(figures)
	var base_y := block.global_position.y if block.is_inside_tree() else block.position.y
	var body := ShaderMaterial.new()
	body.shader = BODY_SHADER
	body.set_shader_parameter(&"base_y", base_y)
	_add_figure(figures, GUARD_SCENE, Vector3(0.12, 0.0, 0.18), rng.randf_range(-0.3, 0.3), FIGURE_HEIGHT, body, true)
	_add_figure(figures, ARCHER_SCENE, Vector3(-0.42, 0.0, -0.42), rng.randf_range(2.4, 3.2), FIGURE_HEIGHT * 0.92,
			body, false)
	var crystal := MeshInstance3D.new()
	crystal.name = "Crystal"
	crystal.mesh = block_mesh(BLOCK_SIZE, rseed, false, rng.randf_range(3.0, 6.0))
	crystal.material_override = ice_material(BLOCK_SIZE.y, -0.12, 0.52, true)
	crystal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	art.add_child(crystal)
	# Two smaller crystals grown against the sides (the block is not a single box).
	for i in 2:
		var side := MeshInstance3D.new()
		side.name = "Spur%d" % i
		var hgt := rng.randf_range(0.9, 1.4)
		side.mesh = block_mesh(Vector3(0.8, hgt, 0.7), rseed + 31 * (i + 1), false, 0.0)
		side.material_override = ice_material(hgt, -0.12)
		var a := rng.randf_range(0.0, TAU) if i == 0 else rng.randf_range(0.0, TAU) + PI
		side.position = Vector3(cos(a) * 1.05, -0.05, sin(a) * 1.05)
		side.rotation = Vector3(rng.randf_range(-0.1, 0.1), rng.randf_range(-PI, PI), 0.0)
		side.rotate_object_local(Vector3(sin(a), 0.0, -cos(a)).normalized(), -rng.randf_range(0.25, 0.4))
		side.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		art.add_child(side)

	# The snow mound stays (frost on the base before, under the teeth after).
	var mound := MeshInstance3D.new()
	mound.name = "RimeMound"
	mound.mesh = mound_mesh(1.0, 2.0, 0.42, rseed)
	mound.material_override = _snow_material()
	mound.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	block.add_child(mound)
	var teeth := _build_teeth(rseed)
	teeth.visible = not ice_root.visible
	block.add_child(teeth)
	ice_root.visibility_changed.connect(func() -> void:
		if is_instance_valid(teeth) and is_instance_valid(ice_root):
			teeth.visible = not ice_root.visible)
	if block.has_signal(&"lit_up"):
		block.connect(&"lit_up", func(_b: Node) -> void: shatter(block))
	# A block already thawed (a load before the dress): no ice.
	if block.get(&"lit") == true:
		art.visible = false
		teeth.visible = true
	return true


## Shatter of a block (lit_up): the ice and figures hide, shards fly from the block and a cold puff spreads. Public so
## shot scripts / tests can play it on a block built by dress_block (it does not touch gameplay).
static func shatter(block: Node3D) -> void:
	if block == null or not is_instance_valid(block) or not block.is_inside_tree():
		return
	var art := block.get_node_or_null(^"IceBlock/IceArt") as Node3D
	if art:
		art.visible = false
	var q := tier()
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(hash(String(block.name))) + 7
	var fx := Node3D.new()
	fx.name = "ShatterFx"
	block.add_child(fx)
	var mat := ice_material(0.6, -0.3, 0.6)
	var n := SHARDS[q]
	for i in n:
		var sh := MeshInstance3D.new()
		sh.mesh = shard_mesh(i % 4)
		sh.material_override = mat
		sh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var a := TAU * (float(i) + rng.randf_range(-0.3, 0.3)) / float(n)
		var p0 := Vector3(cos(a) * rng.randf_range(0.3, 0.9), rng.randf_range(0.4, 1.7), sin(a) * rng.randf_range(0.3, 0.9))
		var v := Vector3(cos(a), 0.0, sin(a)) * rng.randf_range(1.6, 3.4) + Vector3(0.0, rng.randf_range(1.5, 3.5), 0.0)
		var s := rng.randf_range(1.2, 2.1)
		sh.scale = Vector3.ONE * s
		sh.position = p0
		var spin := Vector3(rng.randf_range(-9.0, 9.0), rng.randf_range(-6.0, 6.0), rng.randf_range(-9.0, 9.0))
		var r0 := Vector3(rng.randf_range(-PI, PI), rng.randf_range(-PI, PI), rng.randf_range(-PI, PI))
		sh.rotation = r0
		fx.add_child(sh)
		# Ballistic flight until it lands (y 0.08), then it lies still, then sinks into the snow.
		var t_land := (v.y + sqrt(v.y * v.y + 2.0 * GRAVITY * maxf(p0.y - 0.08, 0.0))) / GRAVITY
		var tw := sh.create_tween()
		tw.tween_method(func(t: float) -> void:
			sh.position = p0 + v * t + Vector3(0.0, -0.5 * GRAVITY * t * t, 0.0)
			sh.rotation = r0 + spin * t, 0.0, t_land, t_land)
		tw.tween_interval(rng.randf_range(1.0, 1.8))
		tw.tween_property(sh, "scale", Vector3(s, 0.05, s), 0.9)
		tw.tween_callback(sh.queue_free)
	# A low cold puff (not a white disc: value ~0.8, alpha 0.32 fading out).
	var puff := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 1.0
	disc.bottom_radius = 1.0
	disc.height = 0.04
	disc.radial_segments = 28
	disc.rings = 1
	puff.mesh = disc
	var pm := StandardMaterial3D.new()
	pm.albedo_color = PUFF_COLOR
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.roughness = 1.0
	puff.material_override = pm
	puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	puff.position.y = 0.12
	puff.scale = Vector3(0.8, 1.0, 0.8)
	fx.add_child(puff)
	var ptw := puff.create_tween().set_parallel(true)
	ptw.tween_property(puff, "scale", Vector3(2.8, 1.0, 2.8), 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	ptw.tween_property(pm, "albedo_color:a", 0.0, 0.7)
	ptw.chain().tween_callback(puff.queue_free)
	var ftw := fx.create_tween()
	ftw.tween_interval(4.5)
	ftw.tween_callback(fx.queue_free)


## Restyles a Sentinel's ice shell (MeshInstance3D "IceShell", centred at its position). False when not a shell.
static func dress_shell(shell: MeshInstance3D) -> bool:
	if shell == null or not is_instance_valid(shell):
		return false
	if shell.has_meta(META):
		return true
	shell.set_meta(META, true)
	var rseed := absi(hash(String(shell.get_parent().name if shell.get_parent() else shell.name))) % 100000
	var half := 1.8
	var box := shell.mesh as BoxMesh
	if box:
		half = box.size.y * 0.5
	shell.mesh = block_mesh(SHELL_SIZE, rseed, true, 3.0)
	shell.material_override = ice_material(SHELL_SIZE.y, -SHELL_SIZE.y * 0.5, 0.4, true)
	var mound := MeshInstance3D.new()
	mound.name = "RimeMound"
	mound.mesh = mound_mesh(1.15, 2.3, 0.5, rseed)
	mound.material_override = _snow_material()
	mound.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mound.position.y = -half
	shell.add_child(mound)
	return true


## A faceted ice block, base at y 0 (or centred on y 0 when `centered`), footprint ~size.x x size.z, height size.y,
## leaning `lean_deg` one way. COLOR.rgb = facet edge code (frozen_ice.gdshader), COLOR.a = per-facet tone.
static func block_mesh(size: Vector3, rseed: int, centered: bool = false, lean_deg: float = 4.0) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = rseed
	var n := rng.randi_range(7, 9)
	var hx := size.x * 0.5
	var hz := size.z * 0.5
	var h := size.y
	var y0 := -0.12
	# Ring heights + radius factors: sunk foot, bulge, shoulder, broken slanted top.
	var levels: Array[float] = [y0, h * rng.randf_range(0.3, 0.42), h * rng.randf_range(0.7, 0.8)]
	var radii: Array[float] = [0.92, 1.0, rng.randf_range(0.8, 0.9)]
	var twist: Array[float] = [0.0, rng.randf_range(-0.12, 0.12), rng.randf_range(-0.2, 0.2)]
	var tilt := Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)).normalized()
	var base_ang: Array[float] = []
	for i in n:
		base_ang.append(TAU * (float(i) + rng.randf_range(-0.28, 0.28)) / float(n))
	var rings: Array = []
	for k in levels.size():
		var ring: Array[Vector3] = []
		for i in n:
			var a := base_ang[i] + twist[k]
			var r := radii[k] * rng.randf_range(0.86, 1.06)
			ring.append(Vector3(cos(a) * hx * r, levels[k] + rng.randf_range(-0.06, 0.06) * h, sin(a) * hz * r))
		rings.append(ring)
	# Top: a smaller ring on a slanted plane (the block broke off at an angle), and a low off-centre peak.
	var top: Array[Vector3] = []
	for i in n:
		var a := base_ang[i] + rng.randf_range(-0.15, 0.15)
		var r := rng.randf_range(0.5, 0.7)
		var p := Vector3(cos(a) * hx * r, 0.0, sin(a) * hz * r)
		p.y = h * rng.randf_range(0.9, 0.97) + (p.x * tilt.x + p.z * tilt.y) * 0.22
		top.append(p)
	rings.append(top)
	var peak := Vector3(rng.randf_range(-0.2, 0.2) * hx, h * 1.0 + rng.randf_range(0.0, 0.08) * h, rng.randf_range(-0.2, 0.2) * hz)
	# Lean (shear along a random direction, more at the top) and the centring offset, on the points.
	var lean := tan(deg_to_rad(lean_deg))
	var ld := Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)).normalized()
	var off := -h * 0.5 if centered else 0.0
	for k in rings.size():
		var ring_k: Array[Vector3] = rings[k]
		for i in n:
			ring_k[i] = _lean_point(ring_k[i], h, lean, ld, off)
	peak = _lean_point(peak, h, lean, ld, off)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in rings.size() - 1:
		var lo: Array[Vector3] = rings[k]
		var hi: Array[Vector3] = rings[k + 1]
		for i in n:
			var j := (i + 1) % n
			_quad(st, lo[i], lo[j], hi[j], hi[i], rng.randf())
	var top_ring: Array[Vector3] = rings[rings.size() - 1]
	var tone := rng.randf()
	for i in n:
		_fan(st, peak, top_ring[i], top_ring[(i + 1) % n], tone + rng.randf_range(-0.1, 0.1))
	st.generate_normals()
	return st.commit()


static func _lean_point(v: Vector3, h: float, lean: float, ld: Vector2, off: float) -> Vector3:
	var t := clampf(v.y / maxf(h, 0.01), 0.0, 1.2)
	return Vector3(v.x + ld.x * lean * v.y * t, v.y + off, v.z + ld.y * lean * v.y * t)


## A small ice shard (shatter piece), ~0.35 m long, variant 0-3.
static func shard_mesh(variant: int) -> ArrayMesh:
	var key := "shard%d" % variant
	if _cache.has(key):
		return _cache[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = 9100 + variant
	var n := rng.randi_range(4, 5)
	var length := rng.randf_range(0.28, 0.45)
	var w := rng.randf_range(0.09, 0.15)
	var tip_a := Vector3(rng.randf_range(-0.03, 0.03), length * 0.5, rng.randf_range(-0.03, 0.03))
	var tip_b := Vector3(rng.randf_range(-0.04, 0.04), -length * rng.randf_range(0.2, 0.5), rng.randf_range(-0.04, 0.04))
	var ring: Array[Vector3] = []
	for i in n:
		var a := TAU * (float(i) + rng.randf_range(-0.2, 0.2)) / float(n)
		ring.append(Vector3(cos(a) * w * rng.randf_range(0.7, 1.2), rng.randf_range(-0.04, 0.04), sin(a) * w * 0.7))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n:
		var j := (i + 1) % n
		_tri(st, tip_a, ring[i], ring[j], rng.randf())
		_tri(st, tip_b, ring[j], ring[i], rng.randf())
	st.generate_normals()
	var m := st.commit()
	_cache[key] = m
	return m


## A rime mound ring round a block: rises from `inner` (under the block) to a crest near inner + 0.25 and falls to 0
## at `outer`, noisy outline; base y 0, skirt sunk 0.08. COLOR.r = height 0-1 (snow_drift.gdshader).
static func mound_mesh(inner: float, outer: float, height: float, rseed: int) -> ArrayMesh:
	var segs := 40
	var rings := 6
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var verts: Array[Vector3] = []
	var hs: Array[float] = []
	for s in segs:
		var a := TAU * float(s) / float(segs)
		var nz := 0.5 + 0.3 * sin(a * 3.0 + float(rseed)) + 0.2 * sin(a * 7.0 + float(rseed) * 0.37)
		for k in rings + 1:
			var t := float(k) / float(rings)
			var r := lerpf(inner * 0.7, outer * (0.8 + nz * 0.35), t)
			var crest := 0.28
			var h01 := smoothstep(0.0, crest, t) if t < crest else 1.0 - smoothstep(crest, 1.0, t)
			h01 *= 0.55 + 0.45 * nz
			verts.append(Vector3(cos(a) * r, h01 * height - 0.08 * (1.0 - h01), sin(a) * r))
			hs.append(h01)
	for s in segs:
		var s2 := (s + 1) % segs
		for k in rings:
			var a0 := s * (rings + 1) + k
			var b0 := a0 + 1
			var c0 := s2 * (rings + 1) + k
			var d0 := c0 + 1
			for idx: int in [a0, b0, c0, c0, b0, d0]:
				st.set_color(Color(hs[idx], 0.0, 0.0))
				st.add_vertex(verts[idx])
	st.index()
	st.generate_normals()
	return st.commit()


# ---------------------------------------------------------------- private

static var _cache: Dictionary = {}


static func _snow_material() -> Material:
	if ResourceLoader.exists(FROZEN_LOOK):
		var fl := load(FROZEN_LOOK) as Script
		if fl and fl.has_method(&"snow_material"):
			return fl.call(&"snow_material") as Material
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.76, 0.8, 0.86)
	m.roughness = 0.9
	return m


## A posed Fire model inside the ice: scaled to `height`, process off (no idle motion), shadow blob hidden, a cold
## multiply overlay. `swing`: the guard's sword arm frozen up, the chest twisted.
static func _add_figure(parent: Node3D, path: String, at: Vector3, yaw: float, height: float, body: ShaderMaterial,
		swing: bool) -> void:
	if not ResourceLoader.exists(path):
		return
	var ps := load(path) as PackedScene
	if ps == null:
		return
	var model := ps.instantiate() as Node3D
	if model == null:
		return
	model.name = "Frozen" + path.get_file().get_basename().capitalize().replace(" ", "")
	parent.add_child(model)
	model.process_mode = Node.PROCESS_MODE_DISABLED
	model.position = at
	model.rotation.y = yaw
	var shadow := model.get_node_or_null(^"Shadow") as Node3D
	if shadow:
		shadow.visible = false
	var fx := model.get_node_or_null(^"Fx") as Node3D
	if fx:
		fx.visible = false
	if swing:
		var arm := model.get_node_or_null(^"Root/Chest/ArmR") as Node3D
		if arm:
			arm.rotation.x = -2.3
		var arm_l := model.get_node_or_null(^"Root/Chest/ArmL") as Node3D
		if arm_l:
			arm_l.rotation.x = -0.5
		var chest := model.get_node_or_null(^"Root/Chest") as Node3D
		if chest:
			chest.rotation = Vector3(-0.15, 0.35, 0.0)
	else:
		var head := model.get_node_or_null(^"Root/Chest/Head") as Node3D
		if head:
			head.rotation.x = 0.25   # looking down, hunched against the cold
	# Fit the height from the model's mesh bounds (any scale the scene has).
	var top := 0.0
	for g: Node in model.find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		if not gi.visible:
			continue
		if gi is MeshInstance3D and (gi as MeshInstance3D).mesh:
			var aabb := (gi as MeshInstance3D).mesh.get_aabb()
			var xf := model.global_transform.affine_inverse() * gi.global_transform if model.is_inside_tree() \
					else Transform3D.IDENTITY
			top = maxf(top, (xf * aabb).end.y)
		gi.material_overlay = body
		gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if top > 0.3:
		model.scale = Vector3.ONE * (height / top)


## Broken ice teeth round the mound (shown once the block is gone).
static func _build_teeth(rseed: int) -> Node3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = rseed + 501
	var root := Node3D.new()
	root.name = "IceStump"
	var mat := ice_material(0.7, -0.12, 0.6)
	var n := 7
	for i in n:
		var a := TAU * (float(i) + rng.randf_range(-0.3, 0.3)) / float(n)
		var hgt := rng.randf_range(0.25, 0.65)
		var mi := MeshInstance3D.new()
		mi.mesh = block_mesh(Vector3(rng.randf_range(0.35, 0.6), hgt, rng.randf_range(0.3, 0.5)), rseed + 77 * i, false, 0.0)
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var r := rng.randf_range(0.65, 0.95)
		mi.position = Vector3(cos(a) * r, -0.05, sin(a) * r)
		mi.rotation.y = rng.randf_range(-PI, PI)
		mi.rotate(Vector3(sin(a), 0.0, -cos(a)).normalized(), -rng.randf_range(0.2, 0.5))   # leans out: burst from inside
		root.add_child(mi)
	# A thin cracked ice slab in the middle (where the block stood).
	var slab := MeshInstance3D.new()
	slab.mesh = block_mesh(Vector3(1.6, 0.16, 1.5), rseed + 999, false, 0.0)
	slab.material_override = mat
	slab.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(slab)
	return root


## A quad lo_i, lo_j, hi_j, hi_i as two flat triangles; the diagonal is coded out of the edge code.
static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, tone: float) -> void:
	# Triangle a b c (diagonal a-c opposite b: B's component held at 1), then a c d (diagonal opposite d).
	st.set_smooth_group(-1)
	st.set_color(Color(1.0, 1.0, 0.0, tone)); st.add_vertex(a)
	st.set_color(Color(0.0, 1.0, 0.0, tone)); st.add_vertex(b)
	st.set_color(Color(0.0, 1.0, 1.0, tone)); st.add_vertex(c)
	st.set_color(Color(1.0, 0.0, 1.0, tone)); st.add_vertex(a)
	st.set_color(Color(0.0, 1.0, 1.0, tone)); st.add_vertex(c)
	st.set_color(Color(0.0, 0.0, 1.0, tone)); st.add_vertex(d)


## A fan triangle o p q: only p-q is a real edge.
static func _fan(st: SurfaceTool, o: Vector3, p: Vector3, q: Vector3, tone: float) -> void:
	st.set_smooth_group(-1)
	st.set_color(Color(1.0, 1.0, 1.0, tone)); st.add_vertex(o)
	st.set_color(Color(0.0, 1.0, 1.0, tone)); st.add_vertex(p)
	st.set_color(Color(0.0, 1.0, 1.0, tone)); st.add_vertex(q)


## A plain triangle, all 3 edges real.
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, tone: float) -> void:
	st.set_smooth_group(-1)
	st.set_color(Color(1.0, 0.0, 0.0, tone)); st.add_vertex(a)
	st.set_color(Color(0.0, 1.0, 0.0, tone)); st.add_vertex(b)
	st.set_color(Color(0.0, 0.0, 1.0, tone)); st.add_vertex(c)
