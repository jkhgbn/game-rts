# T3 game changers + T1/T2 outliers: writes the A/B variants (Balance Lab format, applied in memory by the Unit Lab).
import json, os
HERE = os.path.dirname(os.path.abspath(__file__))
T12 = {
	"flame_guard": {"max_hp": 110},
	"blaze_rider": {"max_hp": 205},
	"pyre_adept": {"max_hp": 70, "attack_damage": 9},
	"cinder_arbalest": {"attack_damage": 18},
	"pyrehoof_lancer": {"attack_damage": 26},
	"rimeshield": {"max_hp": 135, "attack_damage": 10},
	"snowdrift_rider": {"max_hp": 210},
	"rime_colossus": {"max_hp": 420, "attack_damage": 24},
	"frost_mortar": {"max_hp": 145},
	"rimehorn_rider": {"attack_damage": 22},
	"bramblehorn": {"max_hp": 315, "attack_damage": 15},
	"vinelasher": {"pop": 2, "cost": 135},
	"greenheart_oathkeeper": {"max_hp": 255, "attack_damage": 14},
	"thornback_charger": {"attack_damage": 23},
	"shade": {"max_hp": 100, "attack_damage": 10},
	"gloam_rider": {"max_hp": 215},
	"shadow_knight": {"max_hp": 435},
	"barrow_knight": {"attack_damage": 28},
	"rimeling": {"max_hp": 70},
	"emberdart_harrier": {"attack_damage": 15},
	"rime_harrier": {"attack_damage": 14},
	"bramble_harrier": {"max_hp": 185},
	"duskbolt_harrier": {"attack_damage": 16},
}
T3 = {
	"t3gc_v1": {
		"frostcrown_juggernaut": {"max_hp": 700, "armor": 28},
		"sunforge_cataphract": {"max_hp": 650},
		"veilborn_dreadrider": {"max_hp": 620},
		"shardguard": {"pop": 2, "attack_damage": 20, "max_hp": 450},
		"briar_roc": {"attack_damage": 28, "max_hp": 780, "armor": 10},
	},
	"t3gc_v2": {
		"frostcrown_juggernaut": {"max_hp": 680, "armor": 25, "attack_damage": 38},
		"sunforge_cataphract": {"max_hp": 630},
		"veilborn_dreadrider": {"max_hp": 610},
		"glade_outrider": {"max_hp": 540},
		"shardguard": {"pop": 2, "attack_damage": 21, "max_hp": 460},
		"briar_roc": {"attack_damage": 30, "max_hp": 800, "armor": 12},
	},
	"t3gc_v3": {
		"frostcrown_juggernaut": {"max_hp": 650, "armor": 22, "attack_damage": 36},
		"sunforge_cataphract": {"max_hp": 615},
		"veilborn_dreadrider": {"max_hp": 600},
		"glade_outrider": {"max_hp": 560, "attack_damage": 35},
		"shardguard": {"pop": 2, "attack_damage": 22, "max_hp": 470},
		"briar_roc": {"attack_damage": 32, "max_hp": 820, "armor": 15, "attack_range": 5},
	},
	"t3gc_v4": {
		"frostcrown_juggernaut": {"max_hp": 680, "armor": 25, "attack_damage": 38},
		"sunforge_cataphract": {"max_hp": 630},
		"veilborn_dreadrider": {"max_hp": 610},
		"glade_outrider": {"max_hp": 540},
		"shardguard": {"pop": 2, "attack_damage": 22, "max_hp": 480},
		"briar_roc": {"attack_damage": 30, "max_hp": 800, "armor": 12, "attack_range": 6},
	},
}
import sys
extra = json.load(open(sys.argv[1])) if len(sys.argv) > 1 else {}
T3.update(extra.get("t3", {}))
T12.update(extra.get("t12", {}))
for name, t3 in T3.items():
	units = dict(T12)
	units.update(t3)
	json.dump({"name": name, "notes": "T3 game changers + T1/T2 sheet outliers (sheet 2026-10-11, t3gc/).", "units": units},
		open(os.path.join(HERE, name + ".json"), "w", newline="\n"), indent="\t")
	print(name)
