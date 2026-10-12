# Laptop setup (Claude tooling + nightly CI)

The Claude setup lives in the repo (`.claude/settings.json` hooks, `.claude/hooks/`, `.claude/skills/`,
`.claude/agents/`), so a `git pull` brings it to any machine. Only the nightly CI needs a one-time step per machine,
and it belongs on the laptop (JS doesn't use it; the desktop stays quiet).

## 1. Get the latest main
In `Documents\four-wizards-rts` on the laptop (with no agent running there):
```powershell
$env:PATH = "C:\Program Files\Git\cmd;$env:PATH"
git status            # commit or stash local work first
git pull origin main
```

## 2. Check the hooks
```powershell
powershell -NoProfile -File .claude\hooks\test_hooks.ps1     # must print "hooks: 35/35 OK"
```
Godot is at `C:\Godot` on both machines. If it ever moves, set the user environment variable `FW_GODOT` to the
console exe path (`tools/godot_run.ps1` reads it). The hooks never launch Godot.

## 3. Nightly CI
```powershell
tools\ci\nightly.ps1 -NoFetch -Quick       # dry run: creates ..\four-wizards-rts-ci, import + 1 smoke + perf
tools\ci\install_nightly_task.ps1          # scheduled task every night at 03:00 (-At 02:30 to change, -Remove to undo)
```
- Each night: fetch origin, CI worktree -> `origin/main` (detached; the main folder is never touched except
  `docs/ci/history.jsonl` and `docs/ci/nightly_<date>/`), full `tools\ci\ci.ps1`, report in
  `Documents\four-wizards-nightly\<date>.txt` and `latest.txt`.
- It tests what is on GitHub, so it only sees work that was pushed.
- No Claude tokens are used (plain PowerShell + Godot). It waits up to 60 min for other Godot runs to finish, then
  goes through the Godot gate anyway (one gate per machine).
- The task runs only while JS's Windows session is logged on, and can wake the laptop from sleep (keep it plugged in).
- Morning: the lead reads `latest.txt` (the `/ci-suite` skill says so) and launches fix agents for failures.
