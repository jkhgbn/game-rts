class_name MissionFlashRing
extends RefCounted
## The look of MissionBase.flash_ring (G-F r2 item 15, docs/art/gf_r2_ground.md): a thin warm-gold rim that grows a
## little and fades in 1 s, with a soft warm light. Replaces the old flat white CylinderMesh disc (alpha 0.7, fog on)
## that read as a 5 m translucent grey disc under the Emberguard squad at m00's start (the night fog greyed it).
## Draw only: one call builds the nodes, a tween frees them. Rim only, no fill; fog disabled (additive).
##   MissionFlashRing.play(parent, pos, radius)          # parent = the mission node (any Node3D in the tree)

const GOLD := Color(1.0, 0.8, 0.38)
const TIME := 1.0
const PEAK_ALPHA := 0.55
const LIGHT_ENERGY := 1.6

static var _tex: Texture2D = null


## Builds the ring under `parent` at `pos` (world), outer radius `radius` (m); returns the ring node (freed after TIME).
static func play(parent: Node, pos: Vector3, radius: float, color: Color = GOLD) -> MeshInstance3D:
	if parent == null or not parent.is_inside_tree():
		return null
	var pm := PlaneMesh.new()
	pm.size = Vector2.ONE * radius * 2.0
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.disable_fog = true
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_texture = rim_texture()
	mat.albedo_color = Color(color, PEAK_ALPHA)
	var mi := MeshInstance3D.new()
	mi.name = "FlashRing"
	mi.mesh = pm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.global_position = pos + Vector3(0.0, 0.08, 0.0)
	mi.scale = Vector3(0.7, 1.0, 0.7)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = LIGHT_ENERGY
	light.omni_range = radius
	light.shadow_enabled = false
	mi.add_child(light)
	light.position.y = 3.0
	var tw := mi.create_tween().set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE, TIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(mat, "albedo_color:a", 0.0, TIME).set_ease(Tween.EASE_IN)
	tw.tween_property(light, "light_energy", 0.0, TIME)
	tw.chain().tween_callback(mi.queue_free)
	return mi


## A thin bright band at 92 % of the radius, nothing inside.
static func rim_texture() -> Texture2D:
	if _tex:
		return _tex
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.86, 0.92, 0.97, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0), Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.0),
		Color(1, 1, 1, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 256
	_tex = tex
	return tex
