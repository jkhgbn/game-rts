class_name ToolCli
extends RefCounted
## The shared command line of the tools wave (docs/plan/tools-wave.md section 0 "One CLI"; API in tools/common/README.md).
## A tool's entry script (`extends SceneTree`, run with `-s`) receives, after `--`:  `<verb> [<id>] [key=value ...]`
## (a leading `--` on keys is tolerated). Exit codes are shared: OK 0 (PASS / WARN), FAIL 1, BAD_INPUT 2, WATCHDOG 3.
##   var cli := ToolCli.parse("cine", VERBS, KEYS)       # VERBS / KEYS = help tables (see README)
##   if cli.bad != "": print(cli.bad); quit(ToolCli.BAD_INPUT)

const OK := 0
const FAIL := 1
const BAD_INPUT := 2
const WATCHDOG := 3

var tool: String = ""
var verb: String = ""
var id: String = ""
var opts: Dictionary = {}                 # key -> String
var positional: PackedStringArray = []    # extra positional args after the id
var bad: String = ""                      # "" = arguments are fine, else a teaching error line
var verbs: Array = []                     # [{verb, args, text}]
var keys: Array = []                      # [{key, default, text}]


## Parses the user args (`OS.get_cmdline_user_args()` unless `argv` is given) against the help tables.
## `verbs` = [{verb, args, text, needs_id: bool}], `keys` = [{key, default, text}] (the known key=value options).
static func parse(tool_name: String, verb_table: Array, key_table: Array, argv: PackedStringArray = PackedStringArray()) -> ToolCli:
	var c := ToolCli.new()
	c.tool = tool_name
	c.verbs = verb_table
	c.keys = key_table
	var a := argv if not argv.is_empty() else OS.get_cmdline_user_args()
	for raw: String in a:
		var s := raw.trim_prefix("--")
		if s == "":
			continue
		var eq := s.find("=")
		if eq > 0:
			c.opts[s.substr(0, eq)] = s.substr(eq + 1)
		elif c.verb == "":
			c.verb = s
		elif c.id == "":
			c.id = s
		else:
			c.positional.append(s)
	if c.verb == "":
		c.verb = "help"
	var names: Array = []
	for v: Dictionary in verb_table:
		names.append(String(v["verb"]))
	if not c.verb in names:
		var n := ToolSpec.nearest(c.verb, names)
		c.bad = "%s: unknown verb \"%s\"%s. Verbs: %s" % [tool_name, c.verb,
			(" -> did you mean \"%s\"?" % n) if n != "" else "", ", ".join(PackedStringArray(names))]
		return c
	for v: Dictionary in verb_table:
		if String(v["verb"]) == c.verb and bool(v.get("needs_id", false)) and c.id == "":
			c.bad = "%s %s: missing <id>. Usage: %s %s %s" % [tool_name, c.verb, tool_name, c.verb, v.get("args", "<id>")]
			return c
	var known: Array = []
	for k: Dictionary in key_table:
		known.append(String(k["key"]))
	for k2: String in c.opts:
		if not k2 in known:
			var n2 := ToolSpec.nearest(k2, known)
			c.bad = "%s: unknown option \"%s=\"%s. Options: %s" % [tool_name, k2,
				(" -> did you mean \"%s\"?" % n2) if n2 != "" else "", ", ".join(PackedStringArray(known))]
			return c
	return c


func has(key: String) -> bool:
	return opts.has(key)


func opt(key: String, default: String = "") -> String:
	return String(opts[key]) if opts.has(key) else default


func opt_float(key: String, default: float = 0.0) -> float:
	var v := opt(key, "")
	return v.to_float() if v.is_valid_float() else default


func opt_int(key: String, default: int = 0) -> int:
	var v := opt(key, "")
	return v.to_int() if v.is_valid_int() else default


func opt_bool(key: String, default: bool = false) -> bool:
	if not opts.has(key):
		return default
	return opt(key).to_lower() in ["1", "true", "yes", "on"]


## `WxH` -> Vector2i (default when absent / bad). `res=1600x900,3440x1440` -> use `opt_sizes`.
func opt_size(key: String, default: Vector2i) -> Vector2i:
	var l := opt_sizes(key, [default])
	return l[0]


func opt_sizes(key: String, default: Array) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for part: String in opt(key, "").split(",", false):
		var p := part.strip_edges().to_lower().split("x")
		if p.size() == 2 and p[0].is_valid_int() and p[1].is_valid_int():
			out.append(Vector2i(p[0].to_int(), p[1].to_int()))
	if out.is_empty():
		for d: Variant in default:
			out.append(d as Vector2i)
	return out


## The help text: usage, verbs table, options table, then `example` verbatim (a complete spec is best).
func help_text(summary: String, example: String = "") -> String:
	var s := "%s: %s\n\nUsage: tools/%s/run_%s.ps1 <verb> <id> [key=value ...]\n\nVerbs:\n" % [tool, summary, tool, tool]
	for v: Dictionary in verbs:
		s += "  %-9s %-28s %s\n" % [v["verb"], v.get("args", ""), v.get("text", "")]
	if not keys.is_empty():
		s += "\nOptions (key=value):\n"
		for k: Dictionary in keys:
			s += "  %-10s %-14s %s\n" % [k["key"], "(" + String(k.get("default", "")) + ")", k.get("text", "")]
	s += "\nExit codes: 0 PASS / WARN, 1 FAIL, 2 bad input, 3 watchdog.\n"
	if example != "":
		s += "\nExample:\n" + example + "\n"
	return s


## True when a real renderer exists (windowed run): stills / sheets that need pixels check this first.
static func is_windowed() -> bool:
	return DisplayServer.get_name() != "headless"


## Quits the tree with WATCHDOG after `seconds` (prints `<TOOL> ERROR: watchdog`), so a hung run never blocks the gate.
static func watchdog(tree: SceneTree, seconds: float, tool_name: String) -> void:
	tree.create_timer(seconds, true, false, true).timeout.connect(func() -> void:
		print("%s ERROR: watchdog (%d s)" % [tool_name.to_upper(), int(seconds)])
		tree.quit(WATCHDOG))


## Deterministic hash of a string / bytes (hex sha256, first 16 chars): what reports print as "hash".
static func hash_of(data: Variant) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	if data is PackedByteArray:
		ctx.update(data)
	else:
		ctx.update(str(data).to_utf8_buffer())
	return ctx.finish().hex_encode().left(16)


static func file_hash(file_path: String) -> String:
	if not FileAccess.file_exists(file_path):
		return ""
	return hash_of(FileAccess.get_file_as_bytes(file_path))
