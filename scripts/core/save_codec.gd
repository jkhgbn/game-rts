class_name SaveCodec
extends RefCounted
## Turns live values into save values and back (docs/design/save-load.md). Plain values pass through (they are stored
## with FileAccess.store_var, so Vector3 / StringName / packed arrays keep their types); a saved unit or building
## becomes {"$ref": save id}; a Resource with a path becomes {"$res": path}. Anything else (other nodes, lambdas,
## resources built in code) cannot be saved: encode() returns SKIP and the caller leaves that value alone.

const SKIP := &"__save_skip__"
const REF := "$ref"
const RES := "$res"


static func is_skip(v: Variant) -> bool:
	return typeof(v) == TYPE_STRING_NAME and v == SKIP


## `ids`: saved node -> save id.
static func encode(v: Variant, ids: Dictionary, depth: int = 0) -> Variant:
	if depth > 8:
		return SKIP
	match typeof(v):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_STRING_NAME, TYPE_VECTOR2, TYPE_VECTOR2I, \
				TYPE_VECTOR3, TYPE_VECTOR3I, TYPE_VECTOR4, TYPE_COLOR, TYPE_RECT2, TYPE_RECT2I, TYPE_NODE_PATH, \
				TYPE_PACKED_BYTE_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, TYPE_PACKED_FLOAT32_ARRAY, \
				TYPE_PACKED_FLOAT64_ARRAY, TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_VECTOR2_ARRAY, \
				TYPE_PACKED_VECTOR3_ARRAY, TYPE_PACKED_COLOR_ARRAY, TYPE_TRANSFORM3D, TYPE_BASIS, TYPE_QUATERNION:
			return v
		TYPE_OBJECT:
			if v == null or not is_instance_valid(v):
				return null
			if ids.has(v):
				return {REF: ids[v]}
			if v is Unit or v is Building:
				return null   # a unit / building the save does not hold (dead, dying): gone after the load too
			if v is Resource and (v as Resource).resource_path != "" and not (v as Resource).resource_path.contains("::"):
				return {RES: (v as Resource).resource_path}
			return SKIP
		TYPE_ARRAY:
			var out: Array = []
			for e: Variant in v:
				var x: Variant = encode(e, ids, depth + 1)
				if is_skip(x):
					return SKIP
				out.append(x)
			return out
		TYPE_DICTIONARY:
			var out := {}
			for k: Variant in v:
				var ek: Variant = encode(k, ids, depth + 1)
				var ev: Variant = encode((v as Dictionary)[k], ids, depth + 1)
				if is_skip(ek) or is_skip(ev):
					return SKIP
				out[ek] = ev
			return out
	return SKIP


## `nodes`: save id -> rebuilt node. A reference to something that is gone decodes to null.
static func decode(v: Variant, nodes: Dictionary) -> Variant:
	if v is Array:
		var out: Array = []
		for e: Variant in v:
			out.append(decode(e, nodes))
		return out
	if v is Dictionary:
		var d := v as Dictionary
		if d.size() == 1 and d.has(REF):
			var n: Variant = nodes.get(d[REF])
			return n if n != null and is_instance_valid(n) else null
		if d.size() == 1 and d.has(RES):
			return load(String(d[RES])) if ResourceLoader.exists(String(d[RES])) else null
		var out := {}
		for k: Variant in d:
			out[decode(k, nodes)] = decode(d[k], nodes)
		return out
	return v


## Writes `value` into `target.prop`, keeping a typed Array / Dictionary typed (assign). False if it did not fit.
static func assign_property(target: Object, prop: StringName, value: Variant) -> bool:
	var cur: Variant = target.get(prop)
	if cur is Array and value is Array:
		var arr := cur as Array
		if arr.is_typed():
			var clean: Array = []
			for e: Variant in value:
				if e != null:
					clean.append(e)
			arr.assign(clean)
			return true
	elif cur is Dictionary and value is Dictionary and (cur as Dictionary).is_typed():
		var dict := cur as Dictionary
		dict.assign(value)
		return true
	if cur != null and value != null and typeof(cur) != typeof(value) \
			and not (typeof(cur) in [TYPE_INT, TYPE_FLOAT] and typeof(value) in [TYPE_INT, TYPE_FLOAT]) \
			and not (typeof(cur) in [TYPE_STRING, TYPE_STRING_NAME] and typeof(value) in [TYPE_STRING, TYPE_STRING_NAME]):
		if not (typeof(cur) == TYPE_OBJECT and typeof(value) == TYPE_OBJECT):
			return false
	target.set(prop, value)
	return true


## A node's metas (not "_"-prefixed) that can be saved, encoded.
static func encode_metas(node: Object, ids: Dictionary) -> Dictionary:
	var out := {}
	for m: StringName in node.get_meta_list():
		if String(m).begins_with("_"):
			continue
		var x: Variant = encode(node.get_meta(m), ids)
		if not is_skip(x):
			out[String(m)] = x
	return out


## Metas renamed with a "_" prefix (review 2026-10-12 R5-2 / RC): an older save still has the plain names. Old name ->
## new name ("" = dropped: a "hooked" marker that must not survive a load, or it would stop the rebuilt node's hookup).
const LEGACY_METAS := {
	"mission_held": "_mission_held",
	"mission_truce_hook": "",
	"game_audio": "",
	"game_audio_crit": "",
}


static func decode_metas(node: Object, metas: Dictionary, nodes: Dictionary) -> void:
	for m: Variant in metas:
		var meta_name := str(m)
		if LEGACY_METAS.has(meta_name):
			meta_name = String(LEGACY_METAS[meta_name])
			if meta_name == "":
				continue
		node.set_meta(StringName(meta_name), decode(metas[m], nodes))


## A Callable on `owner` as a save row [method name, encoded bound args] (mission-save-hardening A5): a method of
## `owner` by name, with or without `.bind(...)` arguments that encode (plain values, saved units / buildings). SKIP for
## a lambda, another object's method, an unbound Callable or an argument that cannot be saved.
static func encode_call(c: Callable, owner: Object, ids: Dictionary) -> Variant:
	if not c.is_valid() or c.get_object() != owner or not owner.has_method(c.get_method()):
		return SKIP
	if c.get_unbound_arguments_count() > 0:
		return SKIP
	var args: Variant = encode(c.get_bound_arguments(), ids)
	if is_skip(args):
		return SKIP
	return [String(c.get_method()), args]


## The Callable of an encode_call() row on `owner` (an invalid Callable when the method is gone). A bound unit /
## building that did not survive the load comes back as null.
static func decode_call(row: Variant, owner: Object, nodes: Dictionary) -> Callable:
	if not row is Array or (row as Array).is_empty():
		return Callable()
	var method := StringName(str((row as Array)[0]))
	if not owner.has_method(method):
		return Callable()
	var c := Callable(owner, method)
	var args: Variant = decode((row as Array)[1], nodes) if (row as Array).size() > 1 else []
	if args is Array and not (args as Array).is_empty():
		return c.bindv(args as Array)
	return c


## Groups a node is in, minus Godot's internal ones ("_..."), as Strings.
static func custom_groups(node: Node) -> Array:
	var out: Array = []
	for g: StringName in node.get_groups():
		if not String(g).begins_with("_"):
			out.append(String(g))
	return out
