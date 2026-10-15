extends SceneTree
## Task G1 (UI side): the "Graphics quality" setting.
## Run:  godot --headless --path . -s tests/test_g1_settings.gd --fixed-fps 60 --quit-after 600
## Optional:  -- --gfx=ultra  (checks the live command-line override too)
## Checks: ids / names, save + load, command-line parsing, headless default Low, the effective tier, the viewport side
## (AA / LOD / anisotropy per tier, FSR 2 keeps MSAA off), the "lighting_rigs" group call, the settings panel row.

const TASK_ID := "g1_settings"

var _fails: PackedStringArray = []
var _frame := 0
var _panel: Node


class FakeRig extends Node:
	var got: Array[int] = []

	func set_quality(q: int) -> void:
		got.append(q)


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails.append(what)


func _initialize() -> void:
	GameSettings.use_test_file()


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 2:
		_static_checks()
		_viewport_checks()
		_panel = load("res://scripts/ui/menus/settings_panel.gd").new()
		root.add_child(_panel)
	elif _frame == 6:
		_panel_checks()
		GameSettings.use_test_file()
		if _fails.is_empty():
			print("PASS %s" % TASK_ID)
		else:
			print("FAIL %s: %s" % [TASK_ID, "; ".join(_fails)])
		return true
	return false


func _static_checks() -> void:
	_check(",".join(GameSettings.GFX_IDS) == "low,medium,high,ultra", "ids")
	_check(GameSettings.GFX_LOW == 0 and GameSettings.GFX_ULTRA == 3, "constants")
	_check(GameSettings.GFX_TOOLTIPS.size() == 4, "4 tooltips")
	# Headless / scripted run: the default and the effective tier are Low.
	_check(GameSettings.is_quiet_run(), "a -s run is quiet")
	_check(GameSettings.default_graphics_quality() == GameSettings.GFX_LOW, "headless default Low")
	_check(GameSettings.graphics_quality == GameSettings.GFX_LOW, "reset default Low in a test")
	# Command line parsing.
	_check(GameSettings.gfx_from_args(PackedStringArray(["--gfx=ultra"])) == 3, "--gfx=ultra")
	_check(GameSettings.gfx_from_args(PackedStringArray(["--x=1", "--gfx=Medium"])) == 1, "--gfx=Medium")
	_check(GameSettings.gfx_from_args(PackedStringArray(["--gfx=bogus"])) == -1, "--gfx bogus ignored")
	_check(GameSettings.gfx_from_args(PackedStringArray([])) == -1, "no --gfx")
	var live := GameSettings.gfx_override()
	_check(GameSettings.effective_graphics_quality() == (live if live >= 0 else GameSettings.GFX_LOW),
			"effective = --gfx else Low in a quiet run")
	# Save / load round trip (the tier is stored as its id; the command line is never saved).
	GameSettings.graphics_quality = GameSettings.GFX_ULTRA
	_check(GameSettings.save_settings() == OK, "save")
	var cfg := ConfigFile.new()
	cfg.load(GameSettings.settings_path)
	_check(str(cfg.get_value(GameSettings.SECTION, "graphics_quality", "")) == "ultra", "saved as 'ultra'")
	GameSettings.graphics_quality = GameSettings.GFX_LOW
	GameSettings.load_settings()
	_check(GameSettings.graphics_quality == GameSettings.GFX_ULTRA, "load gives Ultra back")
	cfg.set_value(GameSettings.SECTION, "graphics_quality", "nonsense")
	cfg.save(GameSettings.settings_path)
	GameSettings.load_settings()
	_check(GameSettings.graphics_quality == GameSettings.default_graphics_quality(), "bad value -> default")
	GameSettings.set_graphics_quality(GameSettings.GFX_MEDIUM, null, true)
	GameSettings.load_settings()
	_check(GameSettings.graphics_quality == GameSettings.GFX_MEDIUM, "set_graphics_quality saves")
	# The group call (a stand-in for the tech-artist's LightingRig).
	var rig := FakeRig.new()
	rig.add_to_group(GameSettings.GROUP_LIGHTING_RIGS)
	root.add_child(rig)
	var applied := GameSettings.apply_graphics(self)
	_check(applied == GameSettings.effective_graphics_quality(), "apply_graphics(-1) = effective tier")
	GameSettings.apply_graphics(self, GameSettings.GFX_HIGH)
	_check(rig.got.size() == 2 and rig.got[1] == GameSettings.GFX_HIGH, "lighting_rigs got set_quality(2)")
	rig.queue_free()


func _viewport_checks() -> void:
	var vp := SubViewport.new()
	root.add_child(vp)
	var project_msaa := int(ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa_3d", 0))
	GameSettings.apply_viewport_quality(vp, GameSettings.GFX_LOW)
	_check(int(vp.msaa_3d) == project_msaa, "Low keeps the project MSAA")
	_check(is_equal_approx(vp.mesh_lod_threshold, 1.0), "Low LOD 1.0")
	GameSettings.apply_viewport_quality(vp, GameSettings.GFX_HIGH)
	_check(vp.msaa_3d == Viewport.MSAA_4X, "High 4x MSAA")
	_check(vp.screen_space_aa == Viewport.SCREEN_SPACE_AA_SMAA, "High SMAA")
	_check(vp.mesh_lod_threshold < 1.0, "High finer LOD")
	if &"anisotropic_filtering_level" in vp:
		_check(int(vp.get(&"anisotropic_filtering_level")) == Viewport.ANISOTROPY_16X, "High 16x aniso")
	GameSettings.apply_viewport_quality(vp, GameSettings.GFX_ULTRA)
	_check(vp.msaa_3d == Viewport.MSAA_4X, "Ultra 4x MSAA (same AA as High)")
	_check(vp.screen_space_aa == Viewport.SCREEN_SPACE_AA_SMAA, "Ultra SMAA")
	_check(is_zero_approx(vp.mesh_lod_threshold), "Ultra LOD 0")
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2
	GameSettings.apply_viewport_quality(vp, GameSettings.GFX_ULTRA)
	_check(vp.msaa_3d == Viewport.MSAA_DISABLED, "FSR 2 keeps MSAA off")
	_check(vp.screen_space_aa == Viewport.SCREEN_SPACE_AA_DISABLED, "FSR 2 keeps SMAA off")
	vp.queue_free()


func _panel_checks() -> void:
	var opt: OptionButton = _panel.get(&"graphics_option")
	_check(opt != null and opt.item_count == 4, "panel row with 4 items")
	if opt == null:
		return
	_check(opt.get_item_tooltip(3) == GameSettings.GFX_TOOLTIPS[3], "per-tier tooltip")
	var rig := FakeRig.new()
	rig.add_to_group(GameSettings.GROUP_LIGHTING_RIGS)
	root.add_child(rig)
	opt.select(GameSettings.GFX_ULTRA)
	opt.item_selected.emit(GameSettings.GFX_ULTRA)
	_check(GameSettings.graphics_quality == GameSettings.GFX_ULTRA, "panel sets the tier")
	_check(rig.got.size() == 1 and rig.got[0] == GameSettings.GFX_ULTRA, "panel change calls lighting_rigs.set_quality(3) at once")
	_check(root.msaa_3d == Viewport.MSAA_4X or root.scaling_3d_mode == Viewport.SCALING_3D_MODE_FSR2,
			"panel change sets the root viewport")
	rig.queue_free()
	_panel.queue_free()
