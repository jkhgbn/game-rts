# PreToolUse hook (Bash | PowerShell): blocks shell commands that break the project rules.
#   1. Godot launched directly instead of through tools/godot_run.ps1 (the Godot gate: max 4 runs at once).
#   2. git run by a subagent ("Agents never run git"; only the lead commits). The contract-reviewer agent may run
#      read-only git (diff / show / log / status) to read the change it reviews.
# Exit 2 + stderr = the call is blocked and Claude sees the reason. Never launches Godot; must stay fast.
# Test: Get-Content sample.json | powershell -NoProfile -File .claude\hooks\guard_shell.ps1 ; $LASTEXITCODE
$ErrorActionPreference = "Stop"
try { $j = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { exit 0 }
$cmd = [string]$j.tool_input.command
if (-not $cmd) { exit 0 }
$isSub = -not [string]::IsNullOrEmpty([string]$j.agent_id)
$agent = [string]$j.agent_type

# 1. Godot direct launch (console or editor exe, or the $GODOT shorthand from CLAUDE.md) without the gate.
$mentionsGodot = $cmd -match '(?i)Godot_v[0-9.]+-stable_win64(_console)?\.exe' -or $cmd -match '(?i)(^|[\s;&|(])\$GODOT\b'
$usesGate = $cmd -match '(?i)godot_run\.ps1'
$runsGodot = $cmd -match '(?i)(--headless|--path|--import|--export|-s\s|--script|--quit-after)' -or $cmd -match '(?i)(&|Start-Process|Invoke-Expression)\s*["'']?[^\s"'']*Godot_v'
if ($mentionsGodot -and $runsGodot -and -not $usesGate) {
	[Console]::Error.WriteLine("BLOCKED by .claude/hooks/guard_shell.ps1: launch Godot through the gate, not the exe. Use:`n  & tools\godot_run.ps1 <same arguments as the Godot exe>`n(windowed runs too: just leave out --headless). The gate caps parallel Godot runs so tests and perf numbers stay valid.")
	exit 2
}

# 2. git in a subagent.
if ($isSub -and $cmd -match '(?i)(^|[\s;&|(`"''\\/])git(\.exe)?["'']?\s+(-C\s+\S+\s+)?([a-z-]+)') {
	$sub = $Matches[4].ToLower()
	$readOnly = @("diff", "show", "log", "status", "blame", "ls-files", "rev-parse")
	if ($agent -eq "contract-reviewer" -and $readOnly -contains $sub) { exit 0 }
	[Console]::Error.WriteLine("BLOCKED by .claude/hooks/guard_shell.ps1: agents never run git (here: git $sub). Only the lead (main session) stages, commits, tags or pushes. Finish your files and list them in your final reply; the lead commits them.")
	exit 2
}
exit 0
