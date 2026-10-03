class_name M00Vfx
extends RefCounted
## Mission 0 story effects (docs/design/mission-00.md 19.V3 / 19.V25 M0 parts, 19.V24 warmth ring), built in code:
## 0 lights, <= 1 particle system per effect, unshaded / emissive meshes, every one-shot frees itself.
## - `blink_ring(parent, at, seconds)`: Mother Hush's violet telegraph ring r 1.5 that closes over `seconds`.
## - `smoke_burst(parent, at)`: Hush's smoke cloak puff (violet-grey, 1.2 s).
## - `spark_arc(parent, from, to)`: Old Vey's weak blue-white spark jump (0.3 s).
## - `crackle_blink(parent, at)`: Vey's Intercept crackle at the blink end (0.4 s).
## - `warmth_ring(parent, at, radius)`: the lit watch brazier's soft flame ring on the ground (stays; pulses).
## - `grief_hands(wizard, seconds)`: Grief's Fire: two ember flames at Vessa's hands for `seconds`.
## - `miss_text(parent, at)` / `float_text(parent, at, text, color)`: a floating word (Blink Strike dodged).

const VIOLET := Color(0.62, 0.36, 0.95)
const STORM := Color(0.78, 0.88, 1.0)
const EMBER := Color(1.0, 0.5, 0.15)
const SMOKE := Color(0.34, 0.28, 0.42)


static func _unshaded(color: Color, emission := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = false
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = Color(color.r, color.g, color.b)
		m.emission_energy_multiplier = emission
	return m


static func _flat_ring(radius: float, width: float, mat: Material) -> MeshInstance3D:
	var torus := TorusMesh.new()
	torus.inner_radius = maxf(0.01, radius - width)
	torus.outer_radius = radius
	torus.rings = 48
	torus.ring_segments = 6
	var mi := MeshInstance3D.new()
	mi.mesh = torus
	mi.material_override = mat
	mi.scale = Vector3(1.0, 0.08, 1.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func _add(parent: Node, node: Node3D, at: Vector3) -> Node3D:
	if parent == null or not is_instance_valid(parent) or not parent.is_inside_tree():
		node.free()
		return null
	parent.add_child(node)
	node.global_position = at
	return node


## Hush's Blink Strike telegraph: a violet ring r 1.5 at `at` with a fill disc that grows to the rim in `seconds`.
static func blink_ring(parent: Node, at: Vector3, seconds: float, radius := 1.5) -> Node3D:
	var root := Node3D.new()
	root.name = "BlinkRing"
	var rim := _flat_ring(radius, 0.14, _unshaded(Color(VIOLET.r, VIOLET.g, VIOLET.b, 0.95), 2.5))
	root.add_child(rim)
	var disc := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = 0.02
	cyl.radial_segments = 40
	disc.mesh = cyl
	var fill := _unshaded(Color(VIOLET.r, VIOLET.g, VIOLET.b, 0.32), 1.2)
	disc.material_override = fill
	disc.scale = Vector3(0.05, 1.0, 0.05)
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(disc)
	if _add(parent, root, at + Vector3(0.0, 0.06, 0.0)) == null:
		return null
	var tw := root.create_tween()
	tw.tween_property(disc, "scale", Vector3.ONE, maxf(0.05, seconds))
	tw.tween_property(fill, "albedo_color:a", 0.0, 0.25)
	tw.parallel().tween_property(rim, "scale", Vector3(1.25, 0.08, 1.25), 0.25)
	tw.tween_callback(root.queue_free)
	return root


## Hush's smoke cloak: a violet-grey puff that swells and thins (1.2 s, one particle system).
static func smoke_burst(parent: Node, at: Vector3) -> Node3D:
	var p := CPUParticles3D.new()
	p.name = "HushSmoke"
	p.amount = 18
	p.lifetime = 1.1
	p.one_shot = true
	p.explosiveness = 0.85
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.6
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = 0.6
	p.initial_velocity_max = 1.6
	p.gravity = Vector3(0.0, 0.6, 0.0)
	p.scale_amount_min = 1.6
	p.scale_amount_max = 2.6
	var sphere := SphereMesh.new()
	sphere.radius = 0.35
	sphere.height = 0.7
	sphere.radial_segments = 8
	sphere.rings = 4
	sphere.material = _unshaded(Color(SMOKE.r, SMOKE.g, SMOKE.b, 0.45))
	p.mesh = sphere
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0.9))
	ramp.set_color(1, Color(1, 1, 1, 0.0))
	p.color_ramp = ramp
	if _add(parent, p, at + Vector3(0.0, 0.9, 0.0)) == null:
		return null
	p.emitting = true
	p.get_tree().create_timer(1.6).timeout.connect(p.queue_free)
	return p


## Old Vey's spark jump: a thin blue-white bolt from `from` to `to` with a flash at the end (0.3 s).
static func spark_arc(parent: Node, from: Vector3, to: Vector3, color := STORM) -> Node3D:
	var root := Node3D.new()
	root.name = "VeySpark"
	if _add(parent, root, from) == null:
		return null
	var a := from + Vector3(0.0, 1.2, 0.0)
	var b := to + Vector3(0.0, 1.0, 0.0)
	var mat := _unshaded(Color(color.r, color.g, color.b, 0.95), 3.0)
	# Two jagged segments through a kinked midpoint.
	var mid := (a + b) * 0.5 + Vector3(0.0, 0.35, 0.0) + (b - a).cross(Vector3.UP).normalized() * 0.25
	for seg: Array in [[a, mid], [mid, b]]:
		var p0: Vector3 = seg[0]
		var p1: Vector3 = seg[1]
		var len_m := p0.distance_to(p1)
		if len_m < 0.01:
			continue
		var box := BoxMesh.new()
		box.size = Vector3(0.05, 0.05, len_m)
		var mi := MeshInstance3D.new()
		mi.mesh = box
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
		mi.global_position = (p0 + p1) * 0.5
		mi.look_at_from_position(mi.global_position, p1, Vector3.UP if absf((p1 - p0).normalized().y) < 0.95 else Vector3.RIGHT)
	var flash := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.25
	s.height = 0.5
	s.radial_segments = 10
	s.rings = 5
	flash.mesh = s
	flash.material_override = mat
	root.add_child(flash)
	flash.global_position = b
	var tw := root.create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.3)
	tw.parallel().tween_property(flash, "scale", Vector3.ONE * 1.8, 0.3)
	tw.tween_callback(root.queue_free)
	return root


## Vey's Intercept: a crackling blue-white burst where he blinks in (0.4 s).
static func crackle_blink(parent: Node, at: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "VeyCrackle"
	if _add(parent, root, at) == null:
		return null
	var mat := _unshaded(Color(STORM.r, STORM.g, STORM.b, 0.85), 3.0)
	var ring := _flat_ring(1.1, 0.12, mat)
	ring.position.y = 0.08
	root.add_child(ring)
	for i in 5:
		var box := BoxMesh.new()
		box.size = Vector3(0.04, 1.4 + 0.3 * float(i % 2), 0.04)
		var bolt := MeshInstance3D.new()
		bolt.mesh = box
		bolt.material_override = mat
		var ang := float(i) * TAU / 5.0
		bolt.position = Vector3(cos(ang) * 0.55, 0.8, sin(ang) * 0.55)
		bolt.rotation = Vector3(0.35 * sin(ang * 3.0), ang, 0.4 * cos(ang * 2.0))
		root.add_child(bolt)
	var tw := root.create_tween()
	tw.tween_property(ring, "scale", Vector3(1.8, 0.08, 1.8), 0.4)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.4)
	tw.tween_callback(root.queue_free)
	return root


## A lit watch brazier's warmth: a soft flame-coloured ring of `radius` on the ground that breathes (stays).
static func warmth_ring(parent: Node, at: Vector3, radius: float) -> Node3D:
	var root := Node3D.new()
	root.name = "WarmthRing"
	var mat := _unshaded(Color(EMBER.r, EMBER.g, EMBER.b, 0.32), 1.4)
	var ring := _flat_ring(radius, 0.35, mat)
	root.add_child(ring)
	var inner := _flat_ring(radius * 0.55, 0.12, _unshaded(Color(1.0, 0.62, 0.25, 0.18), 1.0))
	root.add_child(inner)
	if _add(parent, root, at + Vector3(0.0, 0.05, 0.0)) == null:
		return null
	var tw := root.create_tween().set_loops()
	tw.tween_property(mat, "albedo_color:a", 0.16, 1.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(mat, "albedo_color:a", 0.34, 1.4).set_trans(Tween.TRANS_SINE)
	return root


## Grief's Fire: an ember flame cupped in each of the wizard's hands for `seconds` (flickers, then gutters out).
static func grief_hands(wizard: Node3D, seconds: float) -> Node3D:
	if wizard == null or not is_instance_valid(wizard) or not wizard.is_inside_tree():
		return null
	var old := wizard.get_node_or_null(^"GriefHands")
	if old:
		old.queue_free()
	var root := Node3D.new()
	root.name = "GriefHands"
	wizard.add_child(root)
	var mat := _unshaded(Color(1.0, 0.55, 0.18, 0.9), 4.0)
	var core := _unshaded(Color(1.0, 0.92, 0.6, 0.95), 5.0)
	for side: float in [-1.0, 1.0]:
		var hand := Node3D.new()
		hand.position = Vector3(0.42 * side, 1.02, 0.22)
		root.add_child(hand)
		var flame := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.13
		cone.height = 0.38
		cone.radial_segments = 8
		flame.mesh = cone
		flame.material_override = mat
		flame.position.y = 0.14
		flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		hand.add_child(flame)
		var ember := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.08
		s.height = 0.16
		s.radial_segments = 8
		s.rings = 4
		ember.mesh = s
		ember.material_override = core
		hand.add_child(ember)
		var tw := flame.create_tween().set_loops()
		tw.tween_property(flame, "scale", Vector3(1.15, 1.35, 1.15), 0.18 + 0.05 * side)
		tw.tween_property(flame, "scale", Vector3(0.9, 0.85, 0.9), 0.2)
	var end := root.create_tween()
	end.tween_interval(maxf(0.0, seconds - 1.0))
	end.tween_property(mat, "albedo_color:a", 0.0, 1.0)
	end.parallel().tween_property(core, "albedo_color:a", 0.0, 1.0)
	end.tween_callback(root.queue_free)
	return root


## A floating word over `at` (1 s), e.g. "Dodged" when a Blink Strike misses.
static func float_text(parent: Node, at: Vector3, text: String, color: Color) -> Node3D:
	var label := Label3D.new()
	label.text = text
	label.modulate = color
	label.outline_modulate = Color(0.05, 0.03, 0.08, 0.9)
	label.outline_size = 10
	label.font_size = 56
	label.pixel_size = 0.01
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	if _add(parent, label, at + Vector3(0.0, 2.4, 0.0)) == null:
		return null
	var tw := label.create_tween()
	tw.tween_property(label, "position:y", label.position.y + 1.0, 1.0)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 1.0).set_delay(0.4)
	tw.tween_callback(label.queue_free)
	return label


static func miss_text(parent: Node, at: Vector3) -> Node3D:
	return float_text(parent, at, "Dodged", Color(1.0, 0.85, 0.45))
