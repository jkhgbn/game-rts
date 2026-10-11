# Builds the unit balance sheet (units.csv, matchups.csv, kingdoms.csv) from Unit Lab matrix JSONL.
# Usage: python build_sheet.py [lab_runs_dir]   (default ../../../../../four-wizards-lab-runs)
# Reads every unit-lab-sheet_2026-10-11_<basis>*/ *.jsonl (cost / pop / both), the unit .tres files and the Unit Guide roles.
import csv, glob, json, math, os, re, sys
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
RUNS = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(REPO), "four-wizards-lab-runs")
TAG = "unit-lab-sheet_2026-10-11_"
BASES = ["cost", "pop", "both"]
KINGDOM_ORDER = ["fire", "ice", "nature", "shadow"]

# Role exemptions (balance_pass_2026-10-06.md section 4): alone head-on they lose by construction; judge them in mixes.
EXEMPT = {
    "rime_seer": "support", "bloomtender": "support",
    "ember_archer": "T1 archer", "wildwood_archer": "T1 archer", "nightbolt": "T1 archer", "shardcaster": "T1 archer",
    "burr_slinger": "T1 archer", "thistle_darter": "T1 archer",
    "frostbow": "bowman", "scorchbow": "bowman", "bleakbow": "bowman", "hoarlight_magebow": "bowman",
    "ash_hurler": "siege", "hexweaver": "debuff", "ashveil_saboteur": "spy / building saboteur",
}


# Suggestions checked with focus A/B runs (validate/: r1 = sheet_suggested.json, r2 = sheet_round2.json, 4 seeds,
# judged field, before -> after at crystals / pop). These replace the formula's text.
VALIDATED = {
    "frostcrown_juggernaut": "small nerf: max_hp 780 -> 700 and armor 35 -> 28 (r2: crystals 100 -> 79, pop 98 -> 93; next step armor 25)",
    "vinelasher": "small nerf: max_hp 170 -> 145 and attack_damage 13 -> 12 (r1 HP 145 alone: 69 -> 52 crystals, pop stays 97; pop 1 -> 2 overshoots: pop 32)",
    "bramblehorn": "small nerf: max_hp 380 -> 325 and attack_damage 18 -> 16 (r2: 80 -> 54 crystals, 95 -> 77 pop)",
    "pyre_adept": "small nerf: max_hp 80 -> 70 (r1: 76 -> 74; r2 + dmg 9: 72); pop 93 is pricing (130 c for 1 pop), judge it on both (73)",
    "rimeshield": "small nerf: max_hp 150 -> 130 and attack_damage 11 -> 10 (r2: 89 -> 70 crystals, 93 -> 88 pop); Ice mix was fair (37-51 %): confirm in mix_line_check first",
    "rime_colossus": "small nerf: max_hp 520 -> 440 and attack_damage 28 -> 25 (r2: 77 -> 60 crystals, 93 -> 79 pop)",
    "shade": "small nerf: max_hp 110 -> 95 (r1: 88 -> 73 crystals, 74 -> 61 pop)",
    "greenheart_oathkeeper": "small nerf: max_hp 300 -> 260 (r1: 87 -> 78 crystals, 75 -> 67 pop)",
    "shardguard": "small buff: attack_damage 18 -> 21 (r2 at 24 dmg + 495 HP overshot: crystals 26 -> 86; pop stays 14-18: pop 3 is the real limit, consider pop 3 -> 2)",
    "briar_roc": "investigate before tuning: HP +12 % (r1) and dmg 18 -> 23 (r2) both left it at 14-18 crystals / 25-29 pop",
}


def swarm(u):  # cheap pop-1 body: priced by supply, judged on the "both" budget only
    return u["pop"] == 1 and u["cost"] <= 60


def read_tres(uid):
    p = os.path.join(REPO, "data", "units", uid + ".tres")
    out = {}
    with open(p, encoding="utf-8") as f:
        for line in f:
            m = re.match(r"^(\w+) = (.+)$", line.strip())
            if m:
                out[m.group(1)] = m.group(2).strip().strip('&"')
    num = lambda k, d=0.0: float(out.get(k, d))
    return {
        "id": uid, "name": out.get("display_name", uid), "kingdom": out.get("faction", ""),
        "tier": int(num("requires_tier", 1)), "cost": int(num("cost")), "pop": int(num("pop", 1)),
        "train_time": num("train_time"), "hp": num("max_hp"), "damage": num("attack_damage"),
        "cooldown": num("attack_cooldown", 1.0), "range": num("attack_range"), "speed": num("move_speed"),
        "armor": num("armor"),
    }


def load(basis):
    cells = defaultdict(lambda: [0.0, 0])  # (row, col) -> [score sum, games]
    files = glob.glob(os.path.join(RUNS, TAG + basis + "*", "*.jsonl"))
    seen = set()
    for fp in files:
        with open(fp, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                r = json.loads(line)
                a, b = r["entry_a"], r["entry_b"]
                key = (a, b, r["seed"], r.get("variant", ""))
                if key in seen:
                    continue
                seen.add(key)
                s = 1.0 if r["winner"] == "a" else (0.0 if r["winner"] == "b" else 0.5)
                cells[(a, b)][0] += s; cells[(a, b)][1] += 1
                cells[(b, a)][0] += 1 - s; cells[(b, a)][1] += 1
    return cells


def main():
    guide = json.load(open(os.path.join(REPO, "data", "ui", "unit_guide.json"), encoding="utf-8"))["units"]
    mats = {b: load(b) for b in BASES}
    entries = sorted({k[0] for k in mats["cost"]})
    units = {}
    for e in entries:
        uid = e.split("+")[0]
        u = read_tres(uid)
        u["entry"] = e
        g = guide.get(uid, {})
        u["role"] = g.get("role", "")
        u["class"] = g.get("class", "")
        u["dps"] = u["damage"] / u["cooldown"] if u["cooldown"] > 0 else 0.0
        units[e] = u
    # judged field: T1/T2 entries vs the T1/T2 field (as in the earlier passes), T3 vs the other T3; "all" = vs everyone
    for e, u in units.items():
        field = [o for o in entries if o != e and (units[o]["tier"] == 3) == (u["tier"] == 3)]
        for b in BASES:
            for tag, opp in (("", field), ("all_", [o for o in entries if o != e])):
                cs = [mats[b][(e, o)] for o in opp if mats[b][(e, o)][1] > 0]
                u["mean_" + tag + b] = 100.0 * sum(c[0] / c[1] for c in cs) / len(cs) if cs else float("nan")
                if tag == "":
                    u["games_" + b] = sum(c[1] for c in cs)
        t12 = [o for o in entries if units[o]["tier"] <= 2]
        cs = [mats["cost"][(e, o)] for o in t12 if o != e and mats["cost"][(e, o)][1] > 0]
        u["mean_vs_t12_cost"] = 100.0 * sum(c[0] / c[1] for c in cs) / len(cs)
    for e, u in units.items():
        cellv = {o: 100.0 * mats["cost"][(e, o)][0] / mats["cost"][(e, o)][1]
                 for o in entries if o != e and mats["cost"][(e, o)][1] > 0}
        srt = sorted(cellv.items(), key=lambda kv: (-kv[1], kv[0]))
        u["best"] = "; ".join("%s %d" % (o, v) for o, v in srt[:3])
        u["worst"] = "; ".join("%s %d" % (o, v) for o, v in sorted(cellv.items(), key=lambda kv: (kv[1], kv[0]))[:3])
        units[e] = u

    # rank in kingdom (by equal-crystal mean)
    for k in KINGDOM_ORDER:
        ks = sorted([u for u in units.values() if u["kingdom"] == k], key=lambda u: -u["mean_all_cost"])
        for i, u in enumerate(ks):
            u["rank"] = "%d/%d" % (i + 1, len(ks))

    for u in units.values():
        verdict(u)

    order = sorted(units.values(), key=lambda u: (KINGDOM_ORDER.index(u["kingdom"]), u["tier"], u["cost"], u["entry"]))
    cols = ["entry", "name", "kingdom", "tier", "role", "class", "cost", "pop", "train_time", "hp", "damage", "cooldown",
            "dps", "range", "speed", "armor", "judged_vs", "mean_crystals", "mean_pop", "mean_both", "mean_3_budgets",
            "mean_crystals_vs_all", "mean_pop_vs_all", "mean_both_vs_all", "t3_vs_t1t2_crystals", "rank_in_kingdom",
            "best_matchups_crystals", "worst_matchups_crystals", "games_crystals", "games_pop", "games_both",
            "exemption", "outlier", "severity", "suggested_change", "note"]
    with open(os.path.join(HERE, "units.csv"), "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(cols)
        for u in order:
            w.writerow([u["entry"], u["name"], u["kingdom"], u["tier"], u["role"], u["class"], u["cost"], u["pop"],
                        "%g" % u["train_time"], "%g" % u["hp"], "%g" % u["damage"], "%g" % u["cooldown"],
                        "%.1f" % u["dps"], "%g" % u["range"], "%g" % u["speed"], "%g" % u["armor"],
                        "T3 field" if u["tier"] == 3 else "T1+T2 field", "%.0f" % u["mean_cost"], "%.0f" % u["mean_pop"], "%.0f" % u["mean_both"],
                        "%.0f" % ((u["mean_cost"] + u["mean_pop"] + u["mean_both"]) / 3),
                        "%.0f" % u["mean_all_cost"], "%.0f" % u["mean_all_pop"], "%.0f" % u["mean_all_both"],
                        ("%.0f" % u["mean_vs_t12_cost"]) if u["tier"] == 3 else "", u["rank"],
                        u["best"], u["worst"], u["games_cost"], u["games_pop"], u["games_both"],
                        u["exempt"], u["outlier"], "%.0f" % u["severity"], u["change"], u["note"]])

    with open(os.path.join(HERE, "matchups.csv"), "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        ids = [u["entry"] for u in order]
        w.writerow(["row_vs_col_win_pct_equal_crystals"] + ids)
        for a in ids:
            row = [a]
            for b in ids:
                c = mats["cost"][(a, b)]
                row.append("" if a == b or c[1] == 0 else "%.0f" % (100.0 * c[0] / c[1]))
            w.writerow(row)

    with open(os.path.join(HERE, "kingdoms.csv"), "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["kingdom", "tier", "units", "mean_crystals", "mean_pop", "mean_both", "best_unit", "worst_unit",
                    "outliers"])
        for k in KINGDOM_ORDER:
            for t in [1, 2, 3, "all"]:
                us = [u for u in units.values() if u["kingdom"] == k and (t == "all" or u["tier"] == t)]
                if not us:
                    continue
                m = lambda key: sum(u[key] for u in us) / len(us)
                bu = max(us, key=lambda u: u["mean_cost"]); wu = min(us, key=lambda u: u["mean_cost"])
                w.writerow([k, t, len(us), "%.0f" % m("mean_cost"), "%.0f" % m("mean_pop"), "%.0f" % m("mean_both"),
                            bu["entry"], wu["entry"], sum(1 for u in us if u["outlier"] not in ("", "exempt"))])

    top = sorted([u for u in units.values() if u["outlier"] in ("strong", "weak")], key=lambda u: -u["severity"])
    print("entries", len(entries))
    for u in top[:14]:
        print("%-28s %-6s c%3.0f p%3.0f b%3.0f sev %2.0f  %s" % (u["entry"], u["outlier"], u["mean_cost"], u["mean_pop"],
                                                              u["mean_both"], u["severity"], u["change"]))


def rnd5(x):
    return int(5 * round(x / 5.0))


def verdict(u):
    c, p, b = u["mean_cost"], u["mean_pop"], u["mean_both"]
    u["exempt"] = EXEMPT.get(u["entry"].split("+")[0], "")
    u["note"] = ""
    if "+" in u["entry"]:
        u["note"] = "caster entry = 1 caster + its line unit at equal budget"
    if swarm(u) and not u["exempt"]:
        u["exempt"] = "swarm (judged on both)"
        considered = {"both": b}
    else:
        considered = {"crystals": c, "pop": p}
    hi = {k: v for k, v in considered.items() if v > 70}
    lo = {k: v for k, v in considered.items() if v < 30}
    sev = max([v - 70 for v in hi.values()] + [30 - v for v in lo.values()] + [0])
    u["severity"] = sev
    u["outlier"], u["change"] = "", "none"
    if u["exempt"] and not u["exempt"].startswith("swarm"):
        if hi:
            u["outlier"], u["note"] = "exempt", (u["note"] + " exempt role scores high: check in mixes").strip()
        elif lo:
            u["outlier"] = "exempt"
        return
    if not hi and not lo:
        return
    pct = lambda over: min(15, max(5, 5 + round(over * 0.5)))
    if hi:
        u["outlier"] = "strong"
        over = max(hi.values()) - 70
        k = pct(over)
        if u["exempt"].startswith("swarm"):
            u["change"] = "small nerf: cost %d -> %d (+%d%%)" % (u["cost"], rnd5(u["cost"] * (1 + k / 100)), k)
        elif len(hi) == 2 or min(c, p) > 65:
            u["change"] = "small nerf: max_hp %g -> %d (-%d%%)" % (u["hp"], rnd5(u["hp"] * (1 - k / 100)), k)
        elif "crystals" in hi:
            u["change"] = "small nerf: cost %d -> %d (+%d%%)" % (u["cost"], rnd5(u["cost"] * (1 + k / 100)), k)
        else:
            nd = max(1, round(u["damage"] * k / 100))
            u["change"] = "small nerf: attack_damage %g -> %g (-%d%%; strong per pop only)" % (
                u["damage"], u["damage"] - nd, k)
    else:
        u["outlier"] = "weak"
        under = 30 - min(lo.values())
        k = pct(under)
        if u["exempt"].startswith("swarm"):
            u["change"] = "small buff: max_hp %g -> %d (+%d%%)" % (u["hp"], rnd5(u["hp"] * (1 + k / 100)), k)
        elif len(lo) == 2 or max(c, p) < 35:
            u["change"] = "small buff: max_hp %g -> %d (+%d%%)" % (u["hp"], rnd5(u["hp"] * (1 + k / 100)), k)
        elif "crystals" in lo:
            u["change"] = "small buff: cost %d -> %d (-%d%%)" % (u["cost"], rnd5(u["cost"] * (1 - k / 100)), k)
        else:
            nd = max(1, round(u["damage"] * k / 100))
            u["change"] = "small buff: attack_damage %g -> %g (+%d%%; weak per pop only)" % (
                u["damage"], u["damage"] + nd, k)
    if u["entry"] in VALIDATED:
        u["change"] = VALIDATED[u["entry"]]
        u["note"] = (u["note"] + " suggestion tested (validate/)").strip()
    if "+" in u["entry"]:
        u["change"] = "none here: caster entry, judge in mixes (caster_ab.md); was: " + u["change"]


if __name__ == "__main__":
    main()
