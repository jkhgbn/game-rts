class_name UnitVfx
extends Node3D
## Unit-ability effects (created by task 13b.V6; the family hub of tier3-extras.md 12 and rush-balance.md 16.V11).
## Add ONE of these to a level, next to SpellVfx / CombatVfx / TradeVfx / TitanVfx; it never edits gameplay code.
## It is in group "unit_vfx"; callers do
##   var vfx := get_tree().get_first_node_in_group(&"unit_vfx")
##   if vfx: vfx.play(id, at, target)
## `at` is a world point (Vector3; each family documents what else it accepts), `target` an optional Node3D (null ok).
## Unknown ids are ignored.
##
## This node draws nothing itself: every effect family is its own script (one per task / kingdom) listed in MODULES.
## At _ready each listed file that exists is loaded, instanced ONCE as a child and asked `handles(id) -> bool`;
## `play` forwards the id to the first family that handles it. A missing or broken family file = its ids do nothing.
## Family contract (same as MapFillVfx -> MapFillBeastVfx): a Node3D script with
##   const EFFECTS: Array[StringName]
##   func handles(id: StringName) -> bool
##   func play(id: StringName, at: Variant, target: Variant = null) -> bool    # true = id handled
##   func active_count() -> int ; func live_count() -> int                     # tests
## A new family = a new file + ONE line in MODULES (nothing else here changes).

const GROUP := &"unit_vfx"

## Effect families, in lookup order. Files that do not exist yet are skipped.
const MODULES: Array[String] = [
	"res://art/vfx/unit_fire_gun_vfx.gd",      # 13b.V6 Gunpowder (Fire): musket_shot, powder_volley, powder_smoke...
	"res://art/vfx/unit_ice_rifle_vfx.gd",     # 13b.V7 Rune-rifle (Ice)
	"res://art/vfx/unit_nature_t3_vfx.gd",     # 13b.V9 Nature tier 3
]

var _families: Array[Node] = []
var _route: Dictionary = {}   # id -> family node (cache)


func _ready() -> void:
	add_to_group(GROUP)
	top_level = true
	global_transform = Transform3D.IDENTITY
	for path in MODULES:
		_load_family(path)


# ---------------------------------------------------------------- public API

## Plays effect `id` at `at` on the optional `target` (see each family's header for the arguments it expects).
func play(id: StringName, at: Variant, target: Variant = null) -> void:
	var fam := _family_for(id)
	if fam:
		fam.call(&"play", id, at, target)


## True when a loaded family draws `id`.
func has_effect(id: StringName) -> bool:
	return _family_for(id) != null


## Every id the loaded families draw.
func effect_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for fam in _families:
		var ids: Variant = fam.get(&"EFFECTS")
		if ids is Array:
			for id: Variant in ids:
				out.append(StringName(id))
	return out


## The loaded family nodes (tests, previews).
func families() -> Array[Node]:
	return _families.duplicate()


## Running effects over every family.
func active_count() -> int:
	var n := 0
	for fam in _families:
		if fam.has_method(&"active_count"):
			n += int(fam.call(&"active_count"))
	return n


## Pieces / bursts still on screen over every family (0 once everything has ended).
func live_count() -> int:
	var n := 0
	for fam in _families:
		if fam.has_method(&"live_count"):
			n += int(fam.call(&"live_count"))
	return n


# ---------------------------------------------------------------- families

func _family_for(id: StringName) -> Node:
	if _route.has(id):
		var cached: Node = _route[id]
		if is_instance_valid(cached):
			return cached
		_route.erase(id)
	for fam in _families:
		if is_instance_valid(fam) and bool(fam.call(&"handles", id)):
			_route[id] = fam
			return fam
	return null


func _load_family(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var s := load(path) as Script
	if s == null or not s.can_instantiate():
		push_warning("UnitVfx: %s cannot be instantiated, its effects are off" % path)
		return
	var obj: Object = s.new()
	if not (obj is Node) or not obj.has_method(&"play") or not obj.has_method(&"handles"):
		push_warning("UnitVfx: %s is not an effect family (Node with play / handles)" % path)
		if obj is Node:
			(obj as Node).free()
		return
	var n := obj as Node
	n.name = path.get_file().get_basename().to_pascal_case()
	add_child(n)
	_families.append(n)
