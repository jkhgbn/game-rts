# PostToolUse hook (Edit | Write | MultiEdit): fast GDScript rule check on the lines just written to a .gd file.
# Only the NEW text is checked (Write content / Edit new_string), so old code never floods the agent. Rules:
#   R1 untyped var:  `var x = ...` -> `var x: Type = ...` or `var x := ...` (escape: a `# untyped` comment on the line)
#   R2 parent chains: get_node("../..") / $"../.." / get_parent().get_parent() -> a group, a signal or an export
#   R3 class_name equal to an autoload name from project.godot (Events...) -> parse error at startup
#   R4 `Events.` in tests/ (test scripts compile before autoloads exist) -> get_node_or_null(^"/root/Events")
# Exit 2 + stderr = Claude sees the problems right after its edit and fixes them. Never launches Godot.
# Add a rule here each time a bug class comes back (CLAUDE.md "Recurring bugs").
$ErrorActionPreference = "Stop"
try { $j = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { exit 0 }
$path = [string]$j.tool_input.file_path
if (-not $path -or $path -notmatch '(?i)\.gd$') { exit 0 }
$ti = $j.tool_input
$texts = @()
if ($ti.content) { $texts += [string]$ti.content }
if ($ti.new_string) { $texts += [string]$ti.new_string }
if ($ti.edits) { foreach ($e in @($ti.edits)) { if ($e.new_string) { $texts += [string]$e.new_string } } }
if ($texts.Count -eq 0) { exit 0 }
$lines = ($texts -join "`n") -split "`r?`n"
$isTest = ($path -replace '\\', '/') -match '(?i)/tests/'

$root = $env:CLAUDE_PROJECT_DIR
if (-not $root) { $root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent }
$autoloads = @()
$pg = Join-Path $root "project.godot"
if (Test-Path $pg) {
	$inAuto = $false
	foreach ($l in Get-Content $pg) {
		if ($l -match '^\[') { $inAuto = ($l -eq '[autoload]'); continue }
		if ($inAuto -and $l -match '^(\w+)=') { $autoloads += $Matches[1] }
	}
}

$problems = New-Object System.Collections.Generic.List[string]
foreach ($raw in $lines) {
	$code = ($raw -split '#', 2)[0]
	if ($code -cmatch '^\s*(@\w+(\([^)]*\))?\s+)*(static\s+)?var\s+\w+\s*=(?!=)' -and $raw -notmatch '#\s*untyped') {
		$problems.Add("R1 untyped var (add a type or use :=): $($raw.Trim())")
	}
	if ($code -match 'get_node(_or_null)?\(\s*\^?"\.\./\.\.' -or $code -match '\$"?\.\./\.\.' -or $code -match 'get_parent\(\)\.get_parent\(\)') {
		$problems.Add("R2 parent chain (use a group, a signal or an @export NodePath): $($raw.Trim())")
	}
	if ($code -match '^\s*class_name\s+(\w+)' -and $autoloads -contains $Matches[1]) {
		$problems.Add("R3 class_name $($Matches[1]) is also an autoload name in project.godot (parse error): rename the class")
	}
	if ($isTest -and $code -cmatch '(?<![\w."/])Events\.') {
		$problems.Add("R4 'Events.' in a test (tests compile before autoloads exist): use get_node_or_null(^`"/root/Events`"): $($raw.Trim())")
	}
}
# R5 (2026-10-12, seen twice in one night): a whole-file Write turned a CRLF file into LF, so the commit showed every
# line changed. Only for Write (Edit keeps line endings) on a file git already tracks with CRLF.
if ($ti.content -and (Test-Path $path)) {
	$now = [IO.File]::ReadAllText($path)
	if (-not $now.Contains("`r`n")) {
		$git = "C:\Program Files\Git\cmd\git.exe"; if (-not (Test-Path $git)) { $git = "git" }
		$rel = ($path -replace '\\', '/')
		$rootF = ($root -replace '\\', '/').TrimEnd('/') + '/'
		if ($rel.StartsWith($rootF, [StringComparison]::OrdinalIgnoreCase)) { $rel = $rel.Substring($rootF.Length) }
		# cmd redirect keeps the bytes (a PowerShell pipe would strip the CRs we are looking for).
		$tmp = [IO.Path]::GetTempFileName()
		& cmd /c "`"$git`" -C `"$root`" show `"HEAD:$rel`" > `"$tmp`" 2>nul"
		$hasCr = ($LASTEXITCODE -eq 0) -and ([IO.File]::ReadAllText($tmp)).Contains("`r`n")
		Remove-Item $tmp -ErrorAction SilentlyContinue
		if ($hasCr) { $problems.Add("R5 line endings: $rel was CRLF in git and is now LF (the whole file will show as changed). Rewrite it with CRLF, or use Edit for partial changes.") }
	}
}
if ($problems.Count -eq 0) { exit 0 }
[Console]::Error.WriteLine("GDScript rules (.claude/hooks/check_gd.ps1) found $($problems.Count) problem(s) in what you just wrote to $(Split-Path $path -Leaf). Fix them now:")
foreach ($p in $problems) { [Console]::Error.WriteLine("  - $p") }
exit 2
