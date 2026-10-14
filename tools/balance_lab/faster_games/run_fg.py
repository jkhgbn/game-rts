"""Faster-games batch runner (docs/balance/faster_games_2026-10-06.md).

Bot-vs-bot skirmishes on Crown Hollow through tools/balance_lab/faster_games/fg_match.gd, one Godot run per match,
every run through tools/godot_run.ps1 (the machine-wide Godot gate). Arms = Balance Lab variant JSONs (in memory,
nothing in data/ is written) or "baseline". Jobs are interleaved (level, seed, pair, then arm) so the arms of one
cell run side by side under the same machine load. Resumable: a match whose JSON already exists is skipped.

  python tools/balance_lab/faster_games/run_fg.py --run fg1 --arms baseline,fg_a_pacing,fg_b_siege \
      --levels easy,normal,hard --seeds 1-3 [--pairs fire:shadow,...] [--parallel 4] [--stop-at 23:30]

Raw output: ..\\four-wizards-lab-runs\\fg-<run>\\<arm>__<level>__<pair>__s<seed>.json (+ .log).
Report: python tools/balance_lab/faster_games/fg_report.py --run fg1

Broken-game guards (fg_validity.py, 2026-10-13, after the fg-ab-hush-main run on an unimported worktree):
- before the first game, a Godot --import runs when the repo's git HEAD or its class_name scripts changed since the
  last import stamp (..\\four-wizards-lab-runs\\fg_import_stamps.json) or Godot's class cache misses a script
  (--import forces it, --no-import skips the check);
- after each game, its log (Parse / Compile errors, "Nonexistent function", SCRIPT ERROR floods) and its JSON (a side
  that trained 0 units) are checked: a broken game gets "invalid": <reason> in its JSON, is not counted by
  fg_report.py and is re-run on resume; the run aborts after MAX_INVALID invalid games.
"""
import argparse
import datetime as dt
import os
import subprocess
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fg_validity  # noqa: E402

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
GATE = os.path.join(REPO, "tools", "godot_run.ps1")
SCRIPT = "res://tools/balance_lab/faster_games/fg_match.gd"
KINGDOMS = ["fire", "shadow", "ice", "nature"]
LAB_RUNS = os.path.join(os.path.dirname(REPO), "four-wizards-lab-runs")
STAMP = os.path.join(LAB_RUNS, "fg_import_stamps.json")
MAX_INVALID = 2


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
	ap.add_argument("--style", default="balanced", help='lab_match --style, e.g. "player:rusher,enemy:balanced"')
	ap.add_argument("--limit", type=int, default=1800)
	ap.add_argument("--early", default="1")
	ap.add_argument("--timeout-min", type=int, default=60)
	ap.add_argument("--stop-at", default="")
	ap.add_argument("--layout", default="", help="res:// path of a map layout (e.g. Thornwater); default Crown Hollow")
	ap.add_argument("--dry-run", action="store_true")
	ap.add_argument("--import", dest="force_import", action="store_true", help="always run a Godot --import first")
	ap.add_argument("--no-import", action="store_true", help="skip the import check (not recommended)")
	a = ap.parse_args()

	out_dir = os.path.join(LAB_RUNS, "fg-" + a.run)
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
		needed, why, fp = fg_validity.import_needed(REPO, STAMP)
		print(f"import check: {'NEEDED (' + why + ')' if needed else 'up to date'} (HEAD {fp['head'][:8]}, "
			f"{len(fp['class_set'])} class_name scripts)")
		return
	if not a.no_import:
		try:
			print(fg_validity.ensure_import(REPO, STAMP, lambda: run_import(out_dir), a.force_import), flush=True)
		except RuntimeError as e:
			sys.exit(f"ABORT before the first game: {e}")
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
	jobs_by_name = {j[0]: j for j in todo}
	tries = {}
	err_streak = 0
	pause_until = 0.0
	invalid = []
	while todo or running:
		if stop and dt.datetime.now() >= stop and todo:
			print(f"stop time reached: {len(todo)} matches not started")
			todo = []
		while todo and len(running) < a.parallel:
			name, arm, path, lv, p, s = todo.pop(0)
			if done(os.path.join(out_dir, name + ".json")):   # finished or placeholder-skipped since the queue was built
				continue
			js = os.path.join(out_dir, name + ".json").replace("\\", "/")
			cmd = (f"& '{GATE}' --headless --path '{REPO}' -s {SCRIPT} --fixed-fps {a.tick} --quit-after {quit_after} "
				f"'--' --pair={p} --seed={s} --difficulty={lv} --sim=1 --limit={a.limit} --early={a.early} --tick={a.tick} "
				f"'--style={a.style}' '--variant={path}' '--out={js}'" + (f" '--layout={a.layout}'" if a.layout else ""))
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
			bad = validate(out_dir, name, res)
			if bad:
				res = f"INVALID ({bad}); was: {res}"
			print(f"[{finished}] {name}: {res} ({(time.time() - start):.0f} s real; {el:.0f} min elapsed)", flush=True)
			if bad:
				invalid.append((name, bad))
				if len(invalid) >= MAX_INVALID:
					for proc2, log2, _n, _s in running:
						if proc2.poll() is None:
							subprocess.run(["taskkill", "/PID", str(proc2.pid), "/T", "/F"], capture_output=True)
						if log2 is not log:
							log2.close()
					print(f"\nABORT: {len(invalid)} invalid games - this run's results cannot be trusted.", flush=True)
					for n, why in invalid:
						print(f"  {n}: {why}", flush=True)
					print("Likely a stale Godot import (re-run with --import) or broken scripts in the repo. Invalid games "
						"are marked \"invalid\" in their JSON, skipped by fg_report.py and re-run on resume.", flush=True)
					sys.exit(2)
				continue
			# live repo mid-edit by another agent (parse errors -> "navigation never finished baking"): requeue the job
			# and pause new launches a while; at most 6 tries per job
			if res.startswith("none error") or res == "NO RESULT":
				tries[name] = tries.get(name, 0) + 1
				err_streak += 1
				if tries[name] < 6 and name in jobs_by_name:
					todo.append(jobs_by_name[name])
				if err_streak >= 2:
					pause_until = time.time() + 180
					print("errors in a row: pausing launches 3 min (repo probably mid-edit)", flush=True)
			else:
				err_streak = 0
		running = still
	print(f"done in {(time.time() - t0) / 60:.1f} min")


def done(path):
	try:
		with open(path, encoding="utf-8") as f:
			line = f.readline()
			return line.startswith("{") and '"end_reason":"error"' not in line and '"invalid":' not in line
	except OSError:
		return False


def run_import(out_dir):
	"""One Godot --import of REPO through the gate (log in <out_dir>/_import.log). True on exit code 0."""
	cmd = f"& '{GATE}' --headless --path '{REPO}' --import"
	with open(os.path.join(out_dir, "_import.log"), "w", encoding="utf-8", errors="replace") as log:
		try:
			r = subprocess.run(["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", cmd],
				stdout=log, stderr=subprocess.STDOUT, timeout=1200)
		except subprocess.TimeoutExpired:
			return False
	return r.returncode == 0


def validate(out_dir, name, res):
	"""Checks a finished game (fg_validity.check_game); marks its JSON invalid. Returns the reason or "".
	Games without a result / with end_reason error are left to the requeue logic (never counted anyway)."""
	if res == "NO RESULT" or res.startswith("none error"):
		return ""
	jp = os.path.join(out_dir, name + ".json")
	lp = os.path.join(out_dir, name + ".log")
	result, reason = fg_validity.check_files(jp, lp)
	if reason and result is not None and "end_time" in result:
		fg_validity.mark_invalid(jp, result, reason, fg_validity.log_counts(fg_validity.read_text(lp)))
		return reason
	return ""


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
