extends SceneTree
## Wave Strike card re-price from the Unit Lab matrices (docs/design/wave-strike.md 9.1, balance pass 2026-10-06).
## Reproducible: same matrices + same knobs = same mode_mult. Reads the three Unit Lab matrix scorecards (equal crystals,
## equal pop, both budgets), and for every card of data/wave_strike/card_prices.tres:
##   score_b   = the card's mean score in basis b (scorecard.json variants.baseline.mean)
##   role_rel  = score_b - mean(score_b of every matrix entry of the same ROLE) + 0.5
##               role = ranged (attack_range > 3) or melee; the matrix is head-on, so archers lose by construction
##               ("exempt by role", balance_pass_2026-10-06.md 4): a card is judged against its role peers
##   s         = sum_b weight_b x role_rel_b                                 (weights --w=crystals,pop,both)
##   mode_mult = clamp(1 + slope x (s - 0.5), min, max)                      (9.1: slope 0.6, 0.8 .. 1.3)
## then the card price = UnitType.cost x mode_mult rounded to 5 (WaveCardTable.price). Pop weighs most by default:
## Wave Strike is supply-capped (24 / 40 / 56), so from mid-game a card's value per pop decides, not per crystal.
## The slope is the one calibrated knob (Bot Lab batches, docs/tools/wave_strike/balance_2026-10-06/).
## Run (writes the .tres with --write, always prints the table as Markdown):
##   tools\godot_run.ps1 --headless --path . -s tools/wave_strike/reprice_cards.gd --quit-after 600 '--' --write
## Args: --crystals=DIR --pop=DIR --both=DIR (Unit Lab run folders under docs/balance/unit_lab/), --w=0.25,0.5,0.25,
##   --slope=1.2 --min=0.75 --max=1.35 --write (into card_prices.tres) or --save=res://other.tres (a candidate table
##   for test_ws_match --cards=PATH / run_ws_batch.ps1 -Cards PATH), --out=PATH (the Markdown table)

const TABLE_PATH := "res://data/wave_strike/card_prices.tres"
const LAB := "res://docs/balance/unit_lab/"

var args := {}


func _initialize() -> void:
	for a: String in OS.get_cmdline_user_args():
		var s := a.trim_prefix("--")
		var eq := s.find("=")
		args[s if eq < 0 else s.substr(0, eq)] = "1" if eq < 0 else s.substr(eq + 1)
	var dirs := [String(args.get("crystals", "final_matrix_t1t2")), String(args.get("pop", "final_matrix_t1t2_pop")),
			String(args.get("both", "final_matrix_t1t2_both"))]
	var wtxt := String(args.get("w", "0.25,0.5,0.25")).split(",")
	var weights: Array[float] = []
	for w in wtxt:
		weights.append(float(w))
	var slope := float(args.get("slope", "1.2"))
	var lo := float(args.get("min", "0.75"))
	var hi := float(args.get("max", "1.35"))
	var means: Array[Dictionary] = []
	for d in dirs:
		var m := _means(LAB + d + "/scorecard.json")
		if m.is_empty():
			printerr("reprice: no scorecard in %s" % d)
			quit(1)
			return
		means.append(m)
	# role means per basis
	var role_mean: Array[Dictionary] = []
	for m in means:
		var sums := {"melee": 0.0, "ranged": 0.0}
		var counts := {"melee": 0, "ranged": 0}
		for id: String in m:
			var r := _role(id)
			if r == "":
				continue
			sums[r] += float(m[id])
			counts[r] += 1
		role_mean.append({"melee": sums["melee"] / maxi(counts["melee"], 1), "ranged": sums["ranged"] / maxi(counts["ranged"], 1)})
	var table := load(TABLE_PATH) as WaveCardTable
	var lines: Array[String] = []
	lines.append("| Kingdom | Card | Role | Cost | Crystals | Pop | Both | Role-relative s | mode_mult | Price |")
	lines.append("|---|---|---|---|---|---|---|---|---|---|")
	var mult := {}
	var kingdoms: Array = table.cards.keys()
	kingdoms.sort()
	for k in kingdoms:
		for id in table.cards_of(k):
			var role := _role(String(id))
			var s := 0.0
			var cells: Array[String] = []
			for b in means.size():
				var sc := float(means[b].get(String(id), 0.5))
				cells.append("%d" % roundi(sc * 100.0))
				s += weights[b] * (sc - float(role_mean[b][role]) + 0.5)
			var m := snappedf(clampf(1.0 + slope * (s - 0.5), lo, hi), 0.01)
			mult[id] = m
			var t := UnitType.find(String(id))
			var price := int(roundf(t.cost * m / 5.0) * 5.0)
			lines.append("| %s | %s | %s | %d | %s | %s | %s | %.2f | %.2f | %d |" % [k, id, role, t.cost, cells[0], cells[1],
					cells[2], s, m, price])
	# Kingdom index: the bot mix-weighted (WaveBot.MIX) raw score per basis. Wave Strike is supply-capped, so the POP
	# column predicts the bot batches (balance pass 2026-10-06: b0 Ice 71 / Fire 62 / Shadow 54 / Nature 39 pop index
	# -> 92 / 58 / 25 / 25 % wins); the card SETS are chosen so these sit close together, prices do the rest.
	lines.append("")
	lines.append("| Kingdom | Index crystals | Index pop | Index both |")
	lines.append("|---|---|---|---|")
	for k in kingdoms:
		var mix: Dictionary = WaveBot.MIX.get(StringName(k), {})
		var row: Array[String] = []
		for b in means.size():
			var sw := 0.0
			var ss := 0.0
			for id in table.cards_of(k):
				var w := float(mix.get(id, 1.0))
				sw += w
				ss += w * float(means[b].get(String(id), 0.5))
			row.append("%d" % roundi(ss / maxf(sw, 0.001) * 100.0))
		lines.append("| %s | %s |" % [k, " | ".join(row)])
	lines.append("")
	lines.append("Role means (crystals / pop / both): melee %s, ranged %s. Weights %s, slope %.2f, clamp %.2f-%.2f. Matrices: %s." % [
			"/".join(role_mean.map(func(r: Dictionary) -> String: return "%d" % roundi(r["melee"] * 100.0))),
			"/".join(role_mean.map(func(r: Dictionary) -> String: return "%d" % roundi(r["ranged"] * 100.0))),
			",".join(wtxt), slope, lo, hi, ", ".join(dirs)])
	var md := "\n".join(lines)
	print(md)
	if args.has("out"):
		var f := FileAccess.open(String(args["out"]), FileAccess.WRITE)
		if f:
			f.store_string(md + "\n")
	if args.has("write") or args.has("save"):
		# --save=res://...tres writes a candidate table elsewhere (batches load it with test_ws_match --cards=PATH)
		var dest := String(args.get("save", TABLE_PATH))
		var outt := table.duplicate() as WaveCardTable
		outt.mode_mult = mult
		var err := ResourceSaver.save(outt, dest)
		print("reprice: wrote %d mode_mult to %s (%s)" % [mult.size(), dest, error_string(err)])
	quit(0)


static func _means(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not j is Dictionary:
		return {}
	return (j as Dictionary).get("variants", {}).get("baseline", {}).get("mean", {})


## "melee" / "ranged" by the unit's attack range; "" = a caster / support combo entry ("a+b") or unknown.
static func _role(id: String) -> String:
	if id.contains("+"):
		return ""
	var t := UnitType.find(id)
	if t == null:
		return ""
	return "ranged" if t.attack_range > 3.0 else "melee"
