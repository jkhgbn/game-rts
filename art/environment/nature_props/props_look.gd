class_name PropsLook
extends RefCounted
## G-D map props (docs/art/gd_props.md): the graphics tier of the shared prop materials.
## Every map prop shares a handful of materials (nature_mat.tres = trees, rocks, pillars, biome sets, camps, lairs,
## landmarks; crystal_cluster_mat.tres = crystal nodes; crown_gold_mat.tres = the crown and its altar trims). Their
## shaders read a `gd_detail` uniform (0 Low = the look and cost before G-D, 1 Medium, 2 High, 3 Ultra; the default 0
## means a material nobody set stays on the old look). This helper writes it into the shared (cached) resources:
##   PropsLook.apply(q)     writes tier q; LightingRig calls it in _ready and set_quality (every level with a rig,
##                          Wave Strike and stage sets too; a Settings change arrives through "lighting_rigs")
##   PropsLook.ensure()     the tier of GameSettings.effective_graphics_quality() (Low in headless / -s runs) when the
##                          cached nature material does not have it yet; the crystal node and crown art call it in
##                          _ready, because they load after the rig and may load the materials for the first time
## No strong reference is kept here (AutumnSwap.release() and the resource cache stay in charge): `apply` returns
## the materials it wrote, and the caller that lives as long as the level (LightingRig) keeps them.
## No per-prop state, no _process, no node: the materials are shared by every instance (MultiMesh friendly).

const MATERIALS: Array[String] = [
	"res://art/environment/nature_props/nature_mat.tres",
	"res://art/environment/crystal/crystal_cluster_mat.tres",
	"res://art/environment/crown/crown_gold_mat.tres",
]

static var _applied := -1


## The prop tier the game asks for (0 Low .. 3 Ultra; Low in headless / -s runs unless --gfx).
static func tier() -> int:
	return clampi(GameSettings.effective_graphics_quality(), 0, 3)


## Applies the current tier when the cached nature material does not carry it (a cache read + one compare).
static func ensure() -> void:
	var q := tier()
	if _applied == q and ResourceLoader.exists(MATERIALS[0]):
		var m := load(MATERIALS[0]) as ShaderMaterial
		var v: Variant = m.get_shader_parameter(&"gd_detail") if m else null
		if float(v if v != null else 0.0) == float(q):
			return
	apply(q)


## Writes `gd_detail` = q into every shared prop material whose shader declares it (loaded through the cache, so
## the instances the meshes use). Returns them: keep the array as long as the tier must stick.
static func apply(q: int) -> Array[ShaderMaterial]:
	q = clampi(q, 0, 3)
	_applied = q
	var out: Array[ShaderMaterial] = []
	for p: String in MATERIALS:
		if not ResourceLoader.exists(p):
			continue
		var m := load(p) as ShaderMaterial
		if m and m.shader and m.shader.code.contains("gd_detail"):
			m.set_shader_parameter(&"gd_detail", float(q))
			out.append(m)
	return out


## The tier last written (-1 = never).
static func applied() -> int:
	return _applied
