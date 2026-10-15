class_name WaterQuality
extends Node
## Task G2b: puts the graphics tier (GameSettings.effective_graphics_quality(), 0 Low .. 3 Ultra) on the shared
## water materials (`quality` uniform of water.gdshader, docs/art/g2b_water.md). The materials are shared .tres, so
## one call covers the river, the moat, the fords and the river mouths.
## - `WaterQuality.apply(q)`: sets the tier now (labs, tests).
## - `WaterQuality.ensure()`: one watcher node under /root ("WaterQuality") that re-reads the setting every 0.5 s,
##   so a change in the settings menu reaches the water without any call from the menu. WaterMeshes calls it whenever
##   it builds a water surface; RiverMouthsArt in its _ready. water.gdshader defaults to `quality` 0, so water this
##   never reaches keeps the old (Low) look and cost. Marsh puddles share water_ford_mat.tres: every map with the
##   marsh biome has a river today (tests/test_g2b_water.gd checks it), so the river's build reaches them too.
## Reaches GameSettings through load() (this folder compiles without scripts/ui), default High when it is missing.

const MATERIALS: Array[String] = [
	"res://art/environment/water/water_mat.tres",
	"res://art/environment/water/water_ford_mat.tres",
	"res://art/environment/autumn/water_autumn_mat.tres",   # autumn_swap.gd swaps it in for both
	"res://art/environment/bridges/waterline_mat.tres",
]
## Wet-stone overlay of the crossings (art/environment/bridges/waterline_mat.tres): on from Medium up.
const WATERLINE_MAT := "res://art/environment/bridges/waterline_mat.tres"
const OVERLAY_GROUP := &"water_overlays"
const OVERLAY_MIN_TIER := 1
const SETTINGS_PATH := "res://scripts/ui/menus/game_settings.gd"
const NODE_NAME := "WaterQuality"
const POLL_S := 0.5
const DEFAULT_TIER := 2

static var _applied := -1
## Labs: true = the watcher leaves the tier alone (set with `pin(q)`, cleared with `unpin()`).
static var _pinned := false
## GameSettings script, looked up once (null = missing / without effective_graphics_quality -> DEFAULT_TIER).
static var _settings: Script = null
static var _settings_checked := false

var _left := 0.0


## Labs / tests: sets tier `q` and keeps it (the watcher stops following the setting) until `unpin()`.
static func pin(q: int) -> int:
	_pinned = true
	return apply(q)


static func unpin() -> void:
	_pinned = false


## Sets tier `q` (clamped 0..3) on the shared water materials. Returns the tier set.
static func apply(q: int) -> int:
	q = clampi(q, 0, 3)
	for path in MATERIALS:
		if not ResourceLoader.exists(path):
			continue
		var mat := load(path) as ShaderMaterial
		if mat:
			mat.set_shader_parameter(&"quality", q)
	_applied = q
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		for n in tree.get_nodes_in_group(OVERLAY_GROUP):
			_set_overlay(n as GeometryInstance3D, q)
	return q


## Crossing models: gives `mi` the wet-stone waterline overlay at water height `water_y` (on from Medium up, kept in
## step with the tier). Also makes sure the watcher runs.
static func register_overlay(mi: GeometryInstance3D, water_y: float) -> void:
	if mi == null or not ResourceLoader.exists(WATERLINE_MAT):
		return
	if not mi.is_in_group(OVERLAY_GROUP):
		mi.add_to_group(OVERLAY_GROUP)
	ensure()
	_set_overlay(mi, _applied if _applied >= 0 else current_tier())
	mi.set_instance_shader_parameter(&"water_y", water_y)


static func _set_overlay(mi: GeometryInstance3D, q: int) -> void:
	if mi == null:
		return
	mi.material_overlay = load(WATERLINE_MAT) as Material if q >= OVERLAY_MIN_TIER else null


## The tier the game runs on (GameSettings.effective_graphics_quality()), DEFAULT_TIER without the settings script.
static func current_tier() -> int:
	if not _settings_checked:
		_settings_checked = true
		var s: Script = load(SETTINGS_PATH) if ResourceLoader.exists(SETTINGS_PATH) else null
		if s != null and _has_method(s, "effective_graphics_quality"):
			_settings = s
			if _has_method(s, "ensure_read"):
				s.call(&"ensure_read")   # once: the settings file is read, later changes live in its statics
	if _settings == null:
		return DEFAULT_TIER
	return clampi(int(_settings.call(&"effective_graphics_quality")), 0, 3)


## The last tier `apply` set (-1 = never).
static func applied() -> int:
	return _applied


## Applies the current tier and makes sure the watcher node exists (idempotent, safe before the tree is ready).
static func ensure() -> void:
	if not _pinned:
		apply(current_tier())
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return
	if tree.root.get_node_or_null(NODE_NAME) != null or tree.root.has_meta(&"_water_quality_pending"):
		return
	# Own script by path: works before the global class cache knows WaterQuality (fresh checkouts, no --import yet).
	var n := (load("res://art/environment/water/water_quality.gd") as Script).new() as Node
	n.name = NODE_NAME
	n.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.root.set_meta(&"_water_quality_pending", true)
	tree.root.add_child.call_deferred(n)


func _ready() -> void:
	var r := get_tree().root
	if r.has_meta(&"_water_quality_pending"):
		r.remove_meta(&"_water_quality_pending")


func _process(delta: float) -> void:
	_left -= delta
	if _left > 0.0:
		return
	_left = POLL_S
	if _pinned:
		return
	var q := current_tier()
	if q != _applied:
		apply(q)


static func _has_method(s: Script, method: String) -> bool:
	for m: Dictionary in s.get_script_method_list():
		if String(m.get("name", "")) == method:
			return true
	return false
