extends SceneTree
## The i18n merge writes the same bytes on every run (tools/i18n/i18n_extract.gd `_sort_like`, fixed 2026-10-15:
## the unstable sort reshuffled the obsolete "#~" block on each merge).
## For every data/i18n/fr/<area>.po: parse it, shuffle the entries 5 times, sort with the merge's order and check the
## text is identical each time; live keys come in template order, obsolete ones after them; and a merged file on disk
## reads back to the same bytes (load + sort + to_text == file).
## Run: tools\godot_run.ps1 --headless --path . -s tests/test_i18n_stable.gd --quit-after 3000
## Prints "PASS i18n_stable" or "FAIL i18n_stable: <reason>".

const TASK_ID := "i18n_stable"
const SHUFFLES := 5

var fails: PackedStringArray = []


func _initialize() -> void:
	var ex := I18nExtract.new()
	ex.quiet = true
	ex._load_ignore()
	ex.scan_all()
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261015
	var files := 0
	var obsolete_total := 0
	for area: String in ex.keys:
		var path := I18nExtract.I18N.path_join("fr").path_join(area + ".po")
		if not FileAccess.file_exists(path):
			continue
		files += 1
		var tpl: I18nPo = ex.keys[area]
		var po := I18nPo.load_file(path)
		I18nExtract.sort_entries(po.entries, tpl)
		var want := po.to_text()
		# Live entries first, in template order; obsolete after.
		var seen_obsolete := false
		for e in po.entries:
			var live := tpl.has(e["ctx"], e["id"])
			if live and seen_obsolete:
				_fail("%s: live key after an obsolete one: %s" % [area, String(e["id"]).substr(0, 50)])
				break
			if not live:
				seen_obsolete = true
				obsolete_total += 1
		for i in SHUFFLES:
			var copy: Array[Dictionary] = po.entries.duplicate()
			_shuffle(copy, rng)
			var po2 := I18nPo.new()
			po2.header = po.header
			po2.title = po.title
			po2.entries = copy
			I18nExtract.sort_entries(po2.entries, tpl)
			if po2.to_text() != want:
				_fail("%s: shuffle %d sorts to a different text" % [area, i])
				break
		# Merged file on disk = its own sorted re-write (byte-identical second merge).
		if FileAccess.get_file_as_string(path) != want:
			_fail("%s: file on disk differs from its sorted re-write (run the merge once)" % area)
	if files == 0:
		_fail("no French .po file found")
	if obsolete_total == 0:
		print("note: no obsolete entries in the tree; the tie order is only checked on live keys")
	if fails.is_empty():
		print("PASS %s (%d files, %d obsolete entries)" % [TASK_ID, files, obsolete_total])
	else:
		for f in fails:
			print("  " + f)
		print("FAIL %s: %s" % [TASK_ID, fails[0]])
	quit(0 if fails.is_empty() else 1)


func _shuffle(a: Array[Dictionary], rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t: Dictionary = a[i]
		a[i] = a[j]
		a[j] = t


func _fail(msg: String) -> void:
	fails.append(msg)
