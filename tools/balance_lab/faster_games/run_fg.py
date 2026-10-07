"""Faster-games batch runner (docs/balance/faster_games_2026-10-06.md).

Bot-vs-bot skirmishes on Crown Hollow through tools/balance_lab/faster_games/fg_match.gd, one Godot run per match,
every run through tools/godot_run.ps1 (the machine-wide Godot gate). Arms = Balance Lab variant JSONs (in memory,
nothing in data/ is written) or "baseline". Jobs are interleaved (level, seed, pair, then arm) so the arms of one
cell run side by side under the same machine load. Resumable: a match whose JSON already exists is skipped.

  python tools/balance_lab/faster_games/run_fg.py --run fg1 --arms baseline,fg_a_pacing,fg_b_siege \
      --levels easy,normal,hard --seeds 1-3 [--pairs fire:shadow,...] [--parallel 4] [--stop-at 23:30]

Raw output: ..\\four-wizards-lab-runs\\fg-<run>\\<arm>__<level>__<pair>__s<seed>.json (+ .log).
Report: python tools/balance_lab/faster_games/fg_report.py --run fg1
"""
import argparse
import datetime as dt
import os
import subprocess
import sys
import time

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
GATE = os.path.join(REPO, "tools", "godot_run.ps1")
SCRIPT = "res://tools/balance_lab/faster_games/fg_match.gd"
KINGDOMS = ["fire", "shadow", "ice", "nature"]


def seeds_of(text):
	out = []
	for part in text.split(","):
		part = part.strip()
		if "-" in part:
			a, b = part.split("-")
			out += list(range(int(a), int(b) + 1))
		elif part:
			out.append(int(part))
	return out


def main():
	ap = argparse.ArgumentParser()
	ap.add_argument("--run", required=True)
	ap.add_argument("--arms", default="baseline,fg_a_pacing,fg_b_siege")
	ap.add_argument("--levels", default="normal")
	ap.add_argument("--pairs", default="")
	ap.add_argument("--seeds", default="1-3")
	ap.add_argument("--parallel", type=int, default=4)
	ap.add_argument("--tick", type=int, default=60)
	ap.add_argument("--limit", type=int, default=1800)
	ap.add_argument("--early", default="1")
	ap.add_argument("--timeout-min", type=int, default=60)
	ap.add_argument("--stop-at", default="")
	ap.add_argument("--dry-run", action="store_true")
	a = ap.parse_args()

	out_dir = os.path.join(os.path.dirname(REPO), "four-wizards-lab-runs", "fg-" + a.run)
	os.makedirs(out_dir, exist_ok=True)
	pairs = [p.strip() for p in a.pairs.split(",") if p.strip()] or \
		[f"{p}:{e}" for p in KINGDOMS for e in KINGDOMS if p != e]
	arms = []
	for name in [x.strip() for x in a.arms.split(",") if x.strip()]:
		if name == "baseline":
			arms.append(("baseline", "baseline"))
			continue
		path = name if os.path.isfile(name) else os.path.join(REPO, "tools", "balance_lab", "variants", name + ".json")
		if not os.path.isfile(path):
			sys.exit(f"variant not found: {name}")
		arms.append((os.path.splitext(os.path.basename(path))[0], path.replace("\\", "/")))
	levels = [x.strip() for x in a.levels.split(",") if x.strip()]
	jobs = []
	for lv in levels:
		for s in seeds_of(a.seeds):
			for p in pairs:
				for arm, path in arms:
					name = f"{arm}__{lv}__{p.replace(':', '-')}__s{s}"
					jobs.append((name, arm, path, lv, p, s))
	todo = [j for j in jobs if not done(os.path.join(out_dir, j[0] + ".json"))]
	print(f"FG run {a.run}: {len(jobs)} matches ({len(arms)} arms x {len(levels)} levels x {len(pairs)} pairs x "
		f"{len(seeds_of(a.seeds))} seeds), {len(jobs) - len(todo)} already done, {a.parallel} in parallel -> {out_dir}")
	if a.dry_run:
		return
	stop = None
	if a.stop_at:
		h, m = a.stop_at.split(":")
		stop = dt.datetime.now().replace(hour=int(h), minute=int(m), second=0)
		if stop <= dt.datetime.now():
			stop += dt.timedelta(days=1)
	quit_after = (a.limit + 240) * a.tick + 8000
	running = []
	finished = 0
	t0 = time.time()
	while todo or running:
		if stop and dt.datetime.now() >= stop and todo:
			print(f"stop time reached: {len(todo)} matches not started")
			todo = []
		while todo and len(running) < a.parallel:
			name, arm, path, lv, p, s = todo.pop(0)
			js = os.path.join(out_dir, name + ".json").replace("\\", "/")
			cmd = (f"& '{GATE}' --headless --path '{REPO}' -s {SCRIPT} --fixed-fps {a.tick} --quit-after {quit_after} "
				f"'--' --pair={p} --seed={s} --difficulty={lv} --sim=1 --limit={a.limit} --early={a.early} --tick={a.tick} "
				f"'--variant={path}' '--out={js}'")
			log = open(os.path.join(out_dir, name + ".log"), "w", encoding="utf-8", errors="replace")
			proc = subprocess.Popen(["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", cmd],
				stdout=log, stderr=subprocess.STDOUT)
			running.append((proc, log, name, time.time()))
		time.sleep(2)
		still = []
		for proc, log, name, start in running:
			if proc.poll() is None and time.time() - start < a.timeout_min * 60:
				still.append((proc, log, name, start))
				continue
			if proc.poll() is None:
				subprocess.run(["taskkill", "/PID", str(proc.pid), "/T", "/F"], capture_output=True)
			log.close()
			finished += 1
			res = summary(os.path.join(out_dir, name + ".json"))
			el = (time.time() - t0) / 60
			print(f"[{finished}] {name}: {res} ({(time.time() - start):.0f} s real; {el:.0f} min elapsed)", flush=True)
		running = still
	print(f"done in {(time.time() - t0) / 60:.1f} min")


def done(path):
	try:
		with open(path, encoding="utf-8") as f:
			return f.readline().startswith("{")
	except OSError:
		return False


def summary(path):
	import json
	try:
		with open(path, encoding="utf-8") as f:
			d = json.loads(f.readline())
		return f"{d.get('winner')} {d.get('end_reason')} {d.get('end_clock')}"
	except Exception:
		return "NO RESULT"


if __name__ == "__main__":
	main()
