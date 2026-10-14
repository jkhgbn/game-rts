"""Guards for run_fg.py / fg_report.py against broken games (recurring bug, 2026-10-13).

The Hush A/B (fg-ab-hush-main) ran 12 games on a git worktree moved to a new commit without a Godot --import: the
global class cache was stale, every script that named a new class_name failed to compile (~13 000 "Nonexistent
function" / Parse Error lines per log), no unit was ever trained, and the harness still wrote winners. Two guards:

1. import_needed(repo) / ensure_import(repo, stamp_path, run_import): before the first game, compare the repo's git
   HEAD (read from the .git files, no git command) and the class_name scripts on disk with the last import stamp
   (kept in the lab-runs folder, never in .godot/) and with .godot/global_script_class_cache.cfg; run one
   `godot_run.ps1 --headless --path <repo> --import` when anything differs.
2. check_game(result, log_text) -> "" (valid) or the reason it is invalid: Parse / Compile errors, a flood of
   "Nonexistent function" / SCRIPT ERROR lines, or a side that never trained a unit in a game past 4:00.

Self-test: python tools/balance_lab/faster_games/test_fg_validity.py
"""
import hashlib
import json
import os
import re

# log thresholds (healthy games: 0 Parse / Compile, 0 Nonexistent, 0-2 SCRIPT ERROR lines; the broken Hush logs:
# 13 Parse, ~13 000 Nonexistent, ~13 000 SCRIPT ERROR)
MAX_NONEXISTENT = 20
MAX_SCRIPT_ERRORS = 300
NO_TRAIN_AFTER_S = 240.0   # a game this long where a side trained 0 units is broken (bots train from ~1:00)

_CLASS_RE = re.compile(r"^class_name\s+([A-Za-z_][A-Za-z0-9_]*)", re.M)
_CACHE_RE = re.compile(r'"class":\s*&"([^"]+)"[^}]*?"path":\s*"res://([^"]+)"', re.S)
_SKIP_DIRS = {".godot", ".git", "__pycache__", "node_modules"}


# ---------------------------------------------------------------- per-game check

def log_counts(log_text):
	return {
		"parse_errors": log_text.count("Parse Error"),
		"compile_errors": log_text.count("Compile Error"),
		"nonexistent": log_text.count("Nonexistent function"),
		"script_errors": log_text.count("SCRIPT ERROR"),
	}


def check_game(result, log_text):
	"""result: the game's JSON dict (or None when there is none); log_text: its .log ("" when missing).
	Returns "" when the game is valid, else a short reason."""
	reasons = []
	c = log_counts(log_text or "")
	if c["parse_errors"] or c["compile_errors"]:
		reasons.append(f"{c['parse_errors']} Parse Error / {c['compile_errors']} Compile Error in the log "
			"(stale import or broken scripts)")
	if c["nonexistent"] >= MAX_NONEXISTENT:
		reasons.append(f"{c['nonexistent']} 'Nonexistent function' errors in the log")
	if c["script_errors"] >= MAX_SCRIPT_ERRORS:
		reasons.append(f"{c['script_errors']} SCRIPT ERROR lines in the log")
	if result:
		stats = result.get("stats") or {}
		t = float(result.get("end_time", 0) or 0)
		if t >= NO_TRAIN_AFTER_S and result.get("end_reason") not in ("error", "bad layout", "cap"):
			if not stats:
				reasons.append("no per-side stats in the result")
			for side in ("player", "enemy"):
				s = stats.get(side)
				if s is not None and float(s.get("units_trained", -1)) == 0:
					reasons.append(f"{side} trained 0 units in {int(t)} s")
	return "; ".join(reasons)


def read_text(path):
	try:
		with open(path, encoding="utf-8-sig", errors="replace") as f:   # -sig: some .gd files start with a BOM
			return f.read()
	except OSError:
		return ""


def check_files(json_path, log_path):
	"""(result dict or None, reason). Reads the first JSON line (run_fg format) and the log."""
	result = None
	try:
		with open(json_path, encoding="utf-8") as f:
			result = json.loads(f.readline())
	except Exception:
		result = None
	return result, check_game(result, read_text(log_path))


def mark_invalid(json_path, result, reason, counts=None):
	"""Rewrites the game's JSON (one line) with "invalid": reason (+ the log counts)."""
	result = dict(result or {})
	result["invalid"] = reason
	if counts is not None:
		result["invalid_log_counts"] = counts
	with open(json_path, "w", encoding="utf-8") as f:
		f.write(json.dumps(result, separators=(",", ":"), sort_keys=True) + "\n")
	return result


# ---------------------------------------------------------------- import stamp

def git_head(repo):
	"""The commit hash of repo's HEAD, read from the .git files (plain repo or worktree). "" if unknown."""
	dot = os.path.join(repo, ".git")
	gitdir = dot
	if os.path.isfile(dot):   # worktree: ".git" is "gitdir: <path>"
		with open(dot, encoding="utf-8") as f:
			line = f.read().strip()
		if not line.startswith("gitdir:"):
			return ""
		gitdir = line[len("gitdir:"):].strip()
		if not os.path.isabs(gitdir):
			gitdir = os.path.normpath(os.path.join(repo, gitdir))
	common = gitdir
	cd = os.path.join(gitdir, "commondir")
	if os.path.isfile(cd):
		with open(cd, encoding="utf-8") as f:
			common = os.path.normpath(os.path.join(gitdir, f.read().strip()))
	try:
		with open(os.path.join(gitdir, "HEAD"), encoding="utf-8") as f:
			head = f.read().strip()
	except OSError:
		return ""
	for _ in range(5):
		if not head.startswith("ref:"):
			return head
		ref = head[4:].strip()
		head = ""
		for base in (gitdir, common):
			p = os.path.join(base, *ref.split("/"))
			if os.path.isfile(p):
				with open(p, encoding="utf-8") as f:
					head = f.read().strip()
				break
		if not head:
			packed = os.path.join(common, "packed-refs")
			if os.path.isfile(packed):
				with open(packed, encoding="utf-8") as f:
					for line in f:
						parts = line.strip().split(" ")
						if len(parts) == 2 and parts[1] == ref:
							head = parts[0]
							break
		if not head:
			return ""
	return head


def class_scripts(repo):
	"""{(class_name, res path)} of every .gd with a class_name (dirs with .gdignore skipped, like Godot)."""
	out = set()
	for root, dirs, files in os.walk(repo):
		dirs[:] = [d for d in dirs if d not in _SKIP_DIRS and not os.path.isfile(os.path.join(root, d, ".gdignore"))]
		for fn in files:
			if not fn.endswith(".gd"):
				continue
			p = os.path.join(root, fn)
			m = _CLASS_RE.search(read_text(p))
			if m:
				out.add((m.group(1), os.path.relpath(p, repo).replace("\\", "/")))
	return out


def cached_classes(repo):
	"""{(class_name, res path)} from .godot/global_script_class_cache.cfg; None if missing."""
	p = os.path.join(repo, ".godot", "global_script_class_cache.cfg")
	if not os.path.isfile(p):
		return None
	return set(_CACHE_RE.findall(read_text(p)))


def fingerprint(repo):
	cls = sorted(class_scripts(repo))
	h = hashlib.sha1("\n".join(f"{c} {p}" for c, p in cls).encode("utf-8")).hexdigest()
	return {"head": git_head(repo), "classes": h, "class_set": cls}


def import_needed(repo, stamp_path):
	"""(needed: bool, why: str, fingerprint dict)."""
	fp = fingerprint(repo)
	cache = cached_classes(repo)
	if cache is None:
		return True, "no .godot/global_script_class_cache.cfg (never imported)", fp
	missing = set(map(tuple, fp["class_set"])) - cache
	if missing:
		sample = ", ".join(c for c, _ in sorted(missing)[:5])
		return True, f"{len(missing)} class_name script(s) not in Godot's class cache ({sample})", fp
	stamps = {}
	try:
		with open(stamp_path, encoding="utf-8") as f:
			stamps = json.load(f)
	except Exception:
		stamps = {}
	st = stamps.get(os.path.normcase(os.path.abspath(repo)))
	if not st:
		return True, "no import stamp for this repo yet", fp
	if st.get("head") != fp["head"]:
		return True, f"git HEAD changed since the last import ({st.get('head', '')[:8]} -> {fp['head'][:8]})", fp
	if st.get("classes") != fp["classes"]:
		return True, "class_name scripts changed since the last import", fp
	return False, "", fp


def write_stamp(repo, stamp_path, fp):
	stamps = {}
	try:
		with open(stamp_path, encoding="utf-8") as f:
			stamps = json.load(f)
	except Exception:
		stamps = {}
	stamps[os.path.normcase(os.path.abspath(repo))] = {"head": fp["head"], "classes": fp["classes"]}
	os.makedirs(os.path.dirname(stamp_path), exist_ok=True)
	with open(stamp_path, "w", encoding="utf-8") as f:
		json.dump(stamps, f, indent=1, sort_keys=True)


def ensure_import(repo, stamp_path, run_import, force=False):
	"""Runs run_import() (returns True on success) when needed; raises RuntimeError when the import fails or the
	class cache still misses scripts afterwards. Returns a one-line status."""
	needed, why, fp = import_needed(repo, stamp_path)
	if force:
		needed, why = True, "forced (--import)"
	if not needed:
		return f"import up to date (HEAD {fp['head'][:8]}, {len(fp['class_set'])} class_name scripts)"
	print(f"Godot import needed: {why} -> running --import once", flush=True)
	if not run_import():
		raise RuntimeError("Godot --import failed (see the import log)")
	cache = cached_classes(repo) or set()
	missing = set(map(tuple, fp["class_set"])) - cache
	if missing:
		raise RuntimeError(f"after --import, {len(missing)} class_name script(s) are still missing from the class "
			f"cache: {', '.join(c for c, _ in sorted(missing)[:8])}")
	write_stamp(repo, stamp_path, fp)
	return f"imported (HEAD {fp['head'][:8]}, {len(fp['class_set'])} class_name scripts)"
