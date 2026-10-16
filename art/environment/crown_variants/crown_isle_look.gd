extends RefCounted
## G-F crown isle variants (docs/art/gf_crown_isle.md): each layout map's own look of the Crown Isle, art only.
## Reach it with load() (no class_name). CrownPedestalArt._ready calls `ensure_for_pedestal(self)` (deferred, windowed
## runs only); tests call `ensure_for_level(level)` with `allow_headless`.
## Variant per map (the level's MapLayout id): crown_hollow / no layout (skirmish.tscn, missions, menus) = none,
## thornwater / quartermeet = their own, every other layout map = &"neutral". The work is in crown_isle_variant.gd;
## nothing shared is changed (level-local mesh / multimesh copies and the level's own ground material only), and the
## variant node puts every swapped value back when it leaves the tree.

const VARIANT_SCRIPT := "res://art/environment/crown_variants/crown_isle_variant.gd"
const NODE_NAME := &"CrownIsleVariant"
const SIM_MODE := "res://scripts/core/sim_mode.gd"
const GAME_SETTINGS_PATH := "res://scripts/ui/menus/game_settings.gd"
const OWN := [&"thornwater", &"quartermeet"]
const NONE := [&"crown_hollow", &""]

## Shots / labs: true = no variant (the "before" frames).
static var disabled := false
## Tests / tools: >= 0 beats the settings for the tier (0 Low .. 3 Ultra).
static var quality_override := -1
## Tests: true = the pedestal hook also runs headless.
static var allow_headless := false


## The variant `level` gets: &"" (none), &"thornwater", &"quartermeet" or &"neutral".
static func variant_for(level: Node) -> StringName:
	if level == null or not level.has_method(&"map_layout"):
		return &""
	var lay: Variant = level.call(&"map_layout")
	if not (lay is Resource and &"id" in lay):
		return &""
	var id := StringName(String((lay as Resource).get(&"id")))
	if NONE.has(id):
		return &""
	return id if OWN.has(id) else &"neutral"


static func settings_quality() -> int:
	if quality_override >= 0:
		return clampi(quality_override, 0, 3)
	if not ResourceLoader.exists(GAME_SETTINGS_PATH):
		return 2
	var gs := load(GAME_SETTINGS_PATH) as Script
	if gs and gs.has_method(&"effective_graphics_quality"):
		return clampi(int(gs.call(&"effective_graphics_quality")), 0, 3)
	return 2


## From the crown altar: finds its level (the nearest ancestor with map_layout()) and applies the variant.
static func ensure_for_pedestal(pedestal: Node) -> Node:
	if pedestal == null or not pedestal.is_inside_tree():
		return null
	if DisplayServer.get_name() == "headless" and not allow_headless:
		return null
	var n := pedestal.get_parent()
	while n and not n.has_method(&"map_layout"):
		n = n.get_parent()
	return ensure_for_level(n, pedestal) if n else null


## Applies the variant once (idempotent). Returns the CrownIsleVariant node or null (none for this map, sim mode,
## disabled, a level not in the tree).
static func ensure_for_level(level: Node, pedestal: Node = null) -> Node:
	if disabled or level == null or not level.is_inside_tree() or _sim_enabled():
		return null
	var v := variant_for(level)
	if v == &"":
		return null
	var old := level.get_node_or_null(NodePath(String(NODE_NAME)))
	if old:
		return old
	if pedestal == null:
		pedestal = _find_pedestal(level)
	var vs := load(VARIANT_SCRIPT) as Script
	if vs == null or not vs.can_instantiate():
		return null
	var node := vs.new() as Node3D
	node.name = NODE_NAME
	node.call(&"setup", level, pedestal, v, settings_quality())
	level.add_child(node)
	return node


static func _find_pedestal(level: Node) -> Node:
	for n: Node in level.find_children("*", "Node3D", true, false):
		if n.get_node_or_null(^"RuinDressing") and n.get_node_or_null(^"Stone"):
			return n
	return null


static func _sim_enabled() -> bool:
	if not ResourceLoader.exists(SIM_MODE):
		return false
	var s := load(SIM_MODE) as Script
	return s != null and bool(s.get(&"enabled"))
