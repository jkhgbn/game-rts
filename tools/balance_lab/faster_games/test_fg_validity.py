"""Self-test of the broken-game guards (fg_validity.py, run_fg.py, fg_report.py). No Godot, temp folders only.

  python tools/balance_lab/faster_games/test_fg_validity.py      (prints FG VALIDITY OK, exit 0)
"""
import json
import os
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import fg_report  # noqa: E402
import fg_validity as v  # noqa: E402
import run_fg  # noqa: E402

FAILS = []


def check(cond, what):
	print(("ok   " if cond else "FAIL ") + what)
	if not cond:
		FAILS.append(what)


def result(trained=(40, 50), end_time=900.0, reason="concede"):
	return {"end_time": end_time, "end_reason": reason, "end_clock": "15:00", "winner": "fire", "winner_team": 0,
		"player": "fire", "enemy": "shadow", "style": "balanced",
		"stats": {"player": {"units_trained": trained[0]}, "enemy": {"units_trained": trained[1]}}}


GOOD_LOG = "Godot Engine v4.7.2\nLAB start fire:shadow\nLAB 5:00 fire 2869 army 3\nLAB_RESULT {}\n"
BROKEN_LOG = ("Godot Engine v4.7.2\n"
	"SCRIPT ERROR: Parse Error: Identifier \"ClockMetaLedger\" not declared in the current scope.\n"
	"SCRIPT ERROR: Compile Error: Failed to compile depended scripts.\n"
	+ "SCRIPT ERROR: Invalid call. Nonexistent function 'queue_unit' in base 'Node3D'.\n" * 500)


def write_game(folder, name, res, log):
	with open(os.path.join(folder, name + ".json"), "w", encoding="utf-8") as f:
		f.write(json.dumps(res, separators=(",", ":")) + "\n")
	with open(os.path.join(folder, name + ".log"), "w", encoding="utf-8") as f:
		f.write(log)


def test_check_game():
	check(v.check_game(result(), GOOD_LOG) == "", "healthy game is valid")
	check(v.check_game(result(), GOOD_LOG + "SCRIPT ERROR: one runtime error\n") == "", "one stray SCRIPT ERROR stays valid")
	r = v.check_game(result(), BROKEN_LOG)
	check("Parse Error" in r and "Nonexistent" in r, f"broken log is flagged ({r[:60]}...)")
	check("trained 0" in v.check_game(result(trained=(0, 0)), GOOD_LOG), "0 units trained (both sides) is flagged")
	check("enemy trained 0" in v.check_game(result(trained=(30, 0)), GOOD_LOG), "0 units trained (one side) is flagged")
	check(v.check_game(result(trained=(0, 0), end_time=120.0), GOOD_LOG) == "", "very short game with 0 trained is not judged")


def test_run_fg_validate_and_resume():
	with tempfile.TemporaryDirectory() as d:
		write_game(d, "good", result(), GOOD_LOG)
		write_game(d, "bad", result(trained=(0, 0)), BROKEN_LOG)
		check(run_fg.validate(d, "good", run_fg.summary(os.path.join(d, "good.json"))) == "", "run_fg.validate: good game")
		why = run_fg.validate(d, "bad", run_fg.summary(os.path.join(d, "bad.json")))
		check(why != "", "run_fg.validate: broken game -> invalid")
		with open(os.path.join(d, "bad.json"), encoding="utf-8") as f:
			marked = json.loads(f.readline())
		check(marked.get("invalid") == why and marked["invalid_log_counts"]["parse_errors"] == 1,
			"broken game's JSON carries \"invalid\" + log counts")
		check(run_fg.done(os.path.join(d, "good.json")) and not run_fg.done(os.path.join(d, "bad.json")),
			"resume re-runs the invalid game, keeps the good one")
		check(run_fg.validate(d, "none", "NO RESULT") == "", "no-result games are left to the requeue logic")


def test_report_skips():
	with tempfile.TemporaryDirectory() as root:
		repo = os.path.join(root, "repo")
		runs = os.path.join(root, "four-wizards-lab-runs", "fg-selftest")
		os.makedirs(repo)
		os.makedirs(runs)
		write_game(runs, "baseline__normal__fire-shadow__s1", result(), GOOD_LOG)
		write_game(runs, "baseline__normal__fire-shadow__s2", result(), BROKEN_LOG)            # old run, unmarked
		marked = result()
		marked["invalid"] = "marked by run_fg"
		write_game(runs, "baseline__normal__fire-shadow__s3", marked, GOOD_LOG)                # marked by run_fg
		old = fg_report.REPO
		fg_report.REPO = repo
		try:
			rows = fg_report.load(["selftest"], quiet=True)
		finally:
			fg_report.REPO = old
		check(len(rows) == 1 and len(fg_report.load.skipped) == 2, f"fg_report.load: 1 counted, 2 skipped "
			f"(got {len(rows)} / {len(fg_report.load.skipped)})")


def test_import_stamp():
	with tempfile.TemporaryDirectory() as root:
		# main repo + a linked worktree, laid out like git does it (HEAD via a loose ref, then via packed-refs)
		main = os.path.join(root, "main")
		gd = os.path.join(main, ".git")
		os.makedirs(os.path.join(gd, "refs", "heads"))
		os.makedirs(os.path.join(gd, "worktrees", "wt"))
		with open(os.path.join(gd, "HEAD"), "w") as f:
			f.write("ref: refs/heads/main\n")
		with open(os.path.join(gd, "refs", "heads", "main"), "w") as f:
			f.write("a" * 40 + "\n")
		with open(os.path.join(gd, "packed-refs"), "w") as f:
			f.write("# pack-refs\n" + "b" * 40 + " refs/heads/side\n")
		wt = os.path.join(root, "wt")
		os.makedirs(os.path.join(wt, "scripts"))
		with open(os.path.join(wt, ".git"), "w") as f:
			f.write("gitdir: " + os.path.join(gd, "worktrees", "wt") + "\n")
		with open(os.path.join(gd, "worktrees", "wt", "commondir"), "w") as f:
			f.write("../..\n")
		with open(os.path.join(gd, "worktrees", "wt", "HEAD"), "w") as f:
			f.write("ref: refs/heads/side\n")
		check(v.git_head(main) == "a" * 40, "git_head: plain repo, loose ref")
		check(v.git_head(wt) == "b" * 40, "git_head: worktree, packed ref")
		with open(os.path.join(wt, "scripts", "foo.gd"), "w", encoding="utf-8") as f:
			f.write("﻿class_name Foo\nextends Node\n")
		stamp = os.path.join(root, "stamps.json")
		need, why, _ = v.import_needed(wt, stamp)
		check(need and "never imported" in why, f"no class cache -> import needed ({why})")
		calls = []

		def fake_import(ok_cache):
			def run():
				calls.append(1)
				os.makedirs(os.path.join(wt, ".godot"), exist_ok=True)
				with open(os.path.join(wt, ".godot", "global_script_class_cache.cfg"), "w") as f:
					if ok_cache:
						f.write('list=[{\n"base": &"Node",\n"class": &"Foo",\n"icon": "",\n"path": "res://scripts/foo.gd"\n}]\n')
					else:
						f.write("list=[]\n")
				return True
			return run

		try:
			v.ensure_import(wt, stamp, fake_import(False))
			check(False, "import that leaves the class cache stale raises")
		except RuntimeError:
			check(True, "import that leaves the class cache stale raises")
		v.ensure_import(wt, stamp, fake_import(True))
		check(len(calls) == 2 and not v.import_needed(wt, stamp)[0], "after a good import + stamp: up to date")
		v.ensure_import(wt, stamp, fake_import(True))
		check(len(calls) == 2, "second run: no import")
		with open(os.path.join(gd, "packed-refs"), "w") as f:
			f.write("c" * 40 + " refs/heads/side\n")
		need, why, _ = v.import_needed(wt, stamp)
		check(need and "HEAD changed" in why, f"worktree moved to a new commit -> import needed ({why})")
		v.ensure_import(wt, stamp, fake_import(True))
		with open(os.path.join(wt, "scripts", "bar.gd"), "w", encoding="utf-8") as f:
			f.write("@tool\nclass_name Bar\nextends Node\n")
		need, why, _ = v.import_needed(wt, stamp)
		check(need and "Bar" in why, f"new class_name script -> import needed ({why})")


if __name__ == "__main__":
	test_check_game()
	test_run_fg_validate_and_resume()
	test_report_skips()
	test_import_stamp()
	if FAILS:
		print(f"FG VALIDITY FAIL ({len(FAILS)})")
		sys.exit(1)
	print("FG VALIDITY OK")
