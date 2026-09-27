class_name ToolSpecLine
extends RefCounted
## One line of a spec read by ToolSpec: `keyword arg arg key=value ...` (+ the lines indented below it).

var line: int = 0                          # 1-based line number in the file
var indent: int = 0                        # columns (tab = 4)
var text: String = ""                      # the raw line (trimmed), for error messages
var keyword: String = ""
var args: PackedStringArray = []           # positional tokens (quotes removed)
var quoted: Array[bool] = []               # args[i] was "quoted"
var kv: Dictionary = {}                    # key -> raw value String (quotes removed)
var kv_order: PackedStringArray = []       # keys in written order
var children: Array[ToolSpecLine] = []
var parent: ToolSpecLine = null


func has(key: String) -> bool:
	return kv.has(key)


func arg(i: int, default: String = "") -> String:
	return args[i] if i >= 0 and i < args.size() else default


func arg_count() -> int:
	return args.size()


func get_str(key: String, default: String = "") -> String:
	return String(kv[key]) if kv.has(key) else default


## Number value; a non-number records nothing here (use `bad_number()` / ToolSpec.error to report it).
func get_float(key: String, default: float = 0.0) -> float:
	if not kv.has(key):
		return default
	var v := String(kv[key])
	return v.to_float() if v.is_valid_float() else default


func get_int(key: String, default: int = 0) -> int:
	if not kv.has(key):
		return default
	var v := String(kv[key])
	return v.to_int() if v.is_valid_int() else (int(v.to_float()) if v.is_valid_float() else default)


func get_bool(key: String, default: bool = false) -> bool:
	if not kv.has(key):
		return default
	return String(kv[key]).to_lower() in ["1", "true", "yes", "on"]


## Keys present whose value is not a number (for "expected a number" errors).
func bad_numbers(keys: Array) -> PackedStringArray:
	var out := PackedStringArray()
	for k: String in keys:
		if kv.has(k) and not String(kv[k]).is_valid_float():
			out.append(k)
	return out


## Children whose keyword is `keyword` ("" = all).
func find(keyword: String = "") -> Array[ToolSpecLine]:
	var out: Array[ToolSpecLine] = []
	for c: ToolSpecLine in children:
		if keyword == "" or c.keyword == keyword:
			out.append(c)
	return out


func _to_string() -> String:
	return "%d: %s" % [line, text]
