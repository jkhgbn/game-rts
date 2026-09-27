class_name ToolCapture
extends RefCounted
## Shared 3D capture for the tools wave (docs/plan/tools-wave.md section 1; API in tools/common/README.md).
## A SubViewport of W x H with its own Camera3D, rendering whatever 3D content you add under `viewport` (its own world)
## or a world you pass in. WINDOWED ONLY: under --headless the dummy renderer draws nothing (`snap` returns null and
## says so once). Deterministic enough for goldens on one machine (fixed frames, no time-based effects of our own).
##   var cap := ToolCapture.create(root, Vector2i(1600, 900))     # root = any node in the tree (e.g. get_root())
##   cap.viewport.add_child(my_stage)                             # or ToolCapture.create(root, size, some_world_3d)
##   cap.set_camera(xform, 38.0)
##   var img: Image = await cap.snap(3)                           # wait 3 frames, then read the pixels
##   cap.free_viewport()

var viewport: SubViewport
var camera: Camera3D
var _warned := false


static func create(parent: Node, size: Vector2i, world: World3D = null, transparent: bool = false) -> ToolCapture:
	var c := ToolCapture.new()
	c.viewport = SubViewport.new()
	c.viewport.name = "ToolCapture"
	c.viewport.size = size
	c.viewport.transparent_bg = transparent
	c.viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	c.viewport.msaa_3d = Viewport.MSAA_4X
	if world != null:
		c.viewport.world_3d = world
	else:
		c.viewport.own_world_3d = true
	parent.add_child(c.viewport)
	c.camera = Camera3D.new()
	c.camera.near = 0.1
	c.camera.far = 250.0
	c.viewport.add_child(c.camera)
	c.camera.current = true
	return c


func set_camera(xform: Transform3D, fov_deg: float = 45.0) -> void:
	camera.global_transform = xform
	camera.fov = fov_deg


func set_size(size: Vector2i) -> void:
	viewport.size = size


## Waits `frames` rendered frames and returns the viewport image (RGBA8), or null when headless.
func snap(frames: int = 3) -> Image:
	if not ToolCli.is_windowed():
		if not _warned:
			print("TOOL CAPTURE: headless run, no pixels (run the verb windowed)")
			_warned = true
		return null
	var tree := viewport.get_tree()
	for i: int in maxi(1, frames):
		await tree.process_frame
	await RenderingServer.frame_post_draw
	var img := viewport.get_texture().get_image()
	if img != null and img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	return img


## The main window's pixels (for tools that draw into the root viewport, e.g. a live `play`).
static func grab_main(tree: SceneTree, frames: int = 2) -> Image:
	if not ToolCli.is_windowed():
		return null
	for i: int in maxi(1, frames):
		await tree.process_frame
	await RenderingServer.frame_post_draw
	var img := tree.root.get_texture().get_image()
	if img != null and img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	return img


func free_viewport() -> void:
	if is_instance_valid(viewport):
		viewport.queue_free()
