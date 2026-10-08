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


static func decode_metas(node: Object, metas: Dictionary, nodes: Dictionary) -> void:
	for m: Variant in metas:
		node.set_meta(StringName(str(m)), decode(metas[m], nodes))


## Groups a node is in, minus Godot's internal ones ("_..."), as Strings.
static func custom_groups(node: Node) -> Array:
	var out: Array = []
	for g: StringName in node.get_groups():
		if not String(g).begins_with("_"):
			out.append(String(g))
	return out
