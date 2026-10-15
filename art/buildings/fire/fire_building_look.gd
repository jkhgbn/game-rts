class_name FireBuildingLook
extends RefCounted
## Task G-B Fire (docs/art/gb_fire_buildings.md): the Fire buildings' shared look layer.
##   apply(body)   switches a PaintedVC body material (painted_vc.gdshader) to fire_painted_vc.gdshader (same
##                 contract and uniforms + the Fire paint layer) and writes the graphics tier into it.
##   detail()      the paint tier from GameSettings.effective_graphics_quality() (0 Low .. 3 Ultra; Low in tests).
##   add_heat_haze(parent, pos, size)  a heat shimmer quad over a chimney / forge mouth (High and Ultra only:
##                 one small screen-reading quad; nothing at Low / Medium).
## Called by the Fire models only (FireHallModel / SmallBuildingModel check `_gb_fire()` first), so the other
## kingdoms' halls and small buildings that share those scripts keep their look.

const FIRE_VC: Shader = preload("res://art/buildings/fire/fire_painted_vc.gdshader")
const HAZE: Shader = preload("res://art/buildings/fire/fire_heat_haze.gdshader")
const PAINTED_VC: Shader = preload("res://art/shaders/painted_vc.gdshader")

static var _haze_mesh: QuadMesh
static var _haze_mat: ShaderMaterial   ## one material for every haze quad (strength is an instance uniform)
## Tools only (gb_fire_shots.gd legacy=1): the before look for comparison shots (no Fire layer, no haze, no tiers).
static var legacy: bool = false


## The tier the Fire paint uses (GameSettings.effective_graphics_quality(); High without the settings script).
static func detail() -> int:
	return clampi(GameSettings.effective_graphics_quality(), 0, 3)


## Switches `body` (the PaintedVC body material) to the Fire shader. Returns false when it is not a painted_vc one.
static func apply(body: ShaderMaterial) -> bool:
	if legacy or body == null or not (body.shader == PAINTED_VC or body.shader == FIRE_VC):
		return false
	body.shader = FIRE_VC
	body.set_shader_parameter(&"gb_detail", float(detail()))
	return true


## Writes the tier into a material that includes the Fire paint layer (the keep's painted material).
static func set_detail(m: ShaderMaterial) -> void:
	if m:
		m.set_shader_parameter(&"gb_detail", -1.0 if legacy else float(detail()))
		if legacy:
			m.set_shader_parameter(&"lava_glow", 1.0)


## A heat-haze quad (billboard, refracts the screen behind it) at `pos` under `parent`. High / Ultra only; returns
## null otherwise. `size` in metres (width, height).
static func add_heat_haze(parent: Node3D, pos: Vector3, size: Vector2, strength: float = 1.0) -> MeshInstance3D:
	if legacy or detail() < 2 or parent == null:
		return null
	if _haze_mesh == null:
		_haze_mesh = QuadMesh.new()
		_haze_mesh.size = Vector2.ONE
		_haze_mesh.center_offset = Vector3(0, 0.5, 0)
	if _haze_mat == null:
		_haze_mat = ShaderMaterial.new()
		_haze_mat.shader = HAZE
	var mi := MeshInstance3D.new()
	mi.name = "HeatHaze"
	mi.set_meta(&"no_ghost", true)   # Building.make_ghost skips it (no grey square in the fog)
	mi.mesh = _haze_mesh
	mi.material_override = _haze_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	mi.scale = Vector3(size.x, size.y, 1.0)
	mi.extra_cull_margin = 1.0
	parent.add_child(mi)
	mi.set_instance_shader_parameter(&"strength", strength)
	return mi
