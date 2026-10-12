# PreToolUse hook (Edit | Write | MultiEdit | NotebookEdit): blocks edits that break the project rules.
#   1. Anything in .godot/ or a *.import file (everyone, lead included).
#   2. A NAMED owner agent (owners.json) writing outside its folders (+ its tests/test_*.gd and docs/handoff/).
#      Files outside the repo (scratchpad, temp) are never checked.
# Exit 2 + stderr = blocked, Claude sees why. Never launches Godot; must stay fast.
$ErrorActionPreference = "Stop"
try { $j = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { exit 0 }
$path = [string]$j.tool_input.file_path
if (-not $path) { $path = [string]$j.tool_input.notebook_path }
if (-not $path) { exit 0 }
$root = $env:CLAUDE_PROJECT_DIR
if (-not $root) { $root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent }
$full = $path -replace '/', '\'
$rootN = ($root -replace '/', '\').TrimEnd('\') + '\'
if (-not $full.StartsWith($rootN, [StringComparison]::OrdinalIgnoreCase)) { exit 0 }
$rel = $full.Substring($rootN.Length) -replace '\\', '/'

if ($rel -match '(?i)^\.godot/' -or $rel -match '(?i)\.import$') {
	[Console]::Error.WriteLine("BLOCKED by .claude/hooks/guard_edit.ps1: never edit .godot/ or *.import files ($rel). Godot regenerates them; run the import instead.")
	exit 2
}

$agent = [string]$j.agent_type
if ([string]::IsNullOrEmpty([string]$j.agent_id) -or -not $agent) { exit 0 }
$owners = Get-Content (Join-Path $PSScriptRoot "owners.json") -Raw | ConvertFrom-Json
$own = $owners.PSObject.Properties[$agent]
if ($own -eq $null) { exit 0 }
$allowed = @($own.Value) + @($owners.any)
foreach ($p in $allowed) { if ($rel.StartsWith([string]$p, [StringComparison]::OrdinalIgnoreCase)) { exit 0 } }
[Console]::Error.WriteLine("BLOCKED by .claude/hooks/guard_edit.ps1: $agent does not own $rel (CLAUDE.md 'Who owns what'; yours: $((@($own.Value) -join ', '))). Write the request in docs/handoff/for-<owner>.md and mention it in your final reply.")
exit 2
