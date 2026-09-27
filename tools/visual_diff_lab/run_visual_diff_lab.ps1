<#
.SYNOPSIS
  Visual Diff Lab runner (docs/plan/visual-diff-lab.md): renders the fixed shot list at 1600x900 in a window and
  diffs it against the goldens in docs/visual/golden/ (or records them with -Golden).

.DESCRIPTION
  One windowed Godot run through tools/godot_run.ps1 (the Godot gate). Output: docs/visual/lab/latest/ (current
  shots, heatmaps, compare strips, scorecard.md / .json) and a row in docs/visual/lab/history.md (+ .jsonl).
  Exit code: 0 PASS / WARN (or goldens written), 1 a shot FAILs, 2 setup error, 3 watchdog.
  git is never run: the commit id is read from the .git files ("+wip": the working tree may hold changes).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tools\visual_diff_lab\run_visual_diff_lab.ps1
.EXAMPLE
  .\run_visual_diff_lab.ps1 -Golden                       (record every golden from the current tree)
.EXAMPLE
  .\run_visual_diff_lab.ps1 -Golden -Shots lineup_ice      (re-record one golden after an intended change)
.EXAMPLE
  .\run_visual_diff_lab.ps1 -Shots map_centre,menu_main -Tolerance 20 -NoHistory
#>
param(
	[switch]$Golden,
	[string[]]$Shots = @(),
	[int]$Tolerance = 12,
	[switch]$NoHistory,
	[string]$Dir = "",
	[string]$GoldenDir = "",
	[string]$OutDir = "",
	[int]$QuitAfter = 30000
)

$ErrorActionPreference = "Stop"
[Threading.Thread]::CurrentThread.CurrentCulture = [Globalization.CultureInfo]::InvariantCulture
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
if ($Dir -eq "") { $Dir = (Resolve-Path (Join-Path $Here "..\..")).Path }
$Gate = Join-Path $Dir "tools\godot_run.ps1"
if (-not (Test-Path $Gate)) { throw "Godot gate not found: $Gate" }

function Get-Commit([string]$root) {
	try {
		$gitdir = Join-Path $root ".git"
		if (Test-Path $gitdir -PathType Leaf) { $gitdir = ((Get-Content $gitdir -TotalCount 1) -replace "^gitdir:\s*", "").Trim() }
		$head = (Get-Content (Join-Path $gitdir "HEAD") -TotalCount 1).Trim()
		if ($head -notmatch "^ref:\s*(.+)$") { return $head.Substring(0, 10) }
		$ref = $Matches[1].Trim()
		$f = Join-Path $gitdir $ref
		if (Test-Path $f) { return "$($ref -replace '^refs/heads/', '')@$((Get-Content $f -TotalCount 1).Trim().Substring(0, 10))" }
		$packed = Join-Path $gitdir "packed-refs"
		if (Test-Path $packed) {
			$line = Select-String -Path $packed -Pattern (" " + [Regex]::Escape($ref) + "$") | Select-Object -First 1
			if ($line) { return "$($ref -replace '^refs/heads/', '')@$($line.Line.Substring(0, 10))" }
		}
		return $ref
	} catch { return "" }
}
$Commit = (Get-Commit $Dir) + "+wip"

$lab = @("--mode=$(if ($Golden) { 'golden' } else { 'check' })", "--tolerance=$Tolerance", "--commit=$Commit")
$Shots = @($Shots | ForEach-Object { $_ -split "," } | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
if ($Shots.Count -gt 0) { $lab += "--shots=$($Shots -join ',')" }
if ($NoHistory) { $lab += "--no-history" }
if ($GoldenDir -ne "") { $lab += "--golden=$($GoldenDir -replace '\\', '/')" }
if ($OutDir -ne "") { $lab += "--out=$($OutDir -replace '\\', '/')" }

Write-Host "Visual Diff Lab: $(if ($Golden) { 'recording goldens' } else { 'check' }) ($Commit) in $Dir"
$t0 = Get-Date
# Godot's stderr warnings ("ObjectDB instances leaked") must not become terminating NativeCommandErrors.
$ErrorActionPreference = "Continue"
# '--' is quoted so PowerShell passes it through to Godot (unquoted, PowerShell eats it).
& $Gate --path $Dir --resolution 1600x900 --position '0,0' -s res://tools/visual_diff_lab/visual_diff_lab.gd `
	--fixed-fps 60 --quit-after $QuitAfter '--' @lab
$code = $LASTEXITCODE
Write-Host ("Visual Diff Lab finished in {0:N0} s, exit {1}. Scorecard: {2}" -f ((Get-Date) - $t0).TotalSeconds, $code,
	(Join-Path $(if ($OutDir -ne "") { $OutDir } else { Join-Path $Dir "docs\visual\lab" }) "latest\scorecard.md"))
exit $code
