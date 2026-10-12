# Nightly CI (meant for the laptop, run by Windows Task Scheduler; see docs/laptop-setup.md).
# 1. Fetches origin and moves the CI worktree (..\four-wizards-rts-ci, created if missing) to origin/main (detached).
#    Never touches the main folder's branch or files: work in progress there is safe.
# 2. Runs the full milestone CI (tools\ci\ci.ps1) on that worktree. Every Godot run goes through the Godot gate.
# 3. Writes Documents\four-wizards-nightly\<yyyy-MM-dd>.txt (summary + failing tests) and latest.txt.
# Uses no Claude tokens (plain PowerShell + Godot), so the 5-hour meter is not involved. It waits while other Godot
# processes run (JS or agents busy) up to -WaitQuietMin, then runs anyway through the gate.
#   tools\ci\nightly.ps1                   # normal nightly run
#   tools\ci\nightly.ps1 -NoFetch -Quick   # test the script: no fetch, import + 1 smoke + perf only
param(
	[string]$CiDir = "",
	[string]$ReportDir = "",
	[string]$Ref = "origin/main",
	[int]$WaitQuietMin = 60,
	[switch]$NoFetch,
	[switch]$Quick
)
$ErrorActionPreference = "Stop"
$Repo = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if (-not $CiDir) { $CiDir = Join-Path (Split-Path $Repo -Parent) "four-wizards-rts-ci" }
if (-not $ReportDir) { $ReportDir = Join-Path (Split-Path $Repo -Parent) "four-wizards-nightly" }
New-Item -ItemType Directory -Force $ReportDir | Out-Null
$git = "C:\Program Files\Git\cmd\git.exe"
if (-not (Test-Path $git)) { $git = "git" }
$day = Get-Date -Format "yyyy-MM-dd"
$report = Join-Path $ReportDir "$day.txt"
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("Four Wizards nightly CI $day (started $(Get-Date -Format HH:mm), machine $env:COMPUTERNAME)")

try {
	if (-not $NoFetch) { & $git -C $Repo fetch origin 2>&1 | Out-Null; if ($LASTEXITCODE) { throw "git fetch failed ($LASTEXITCODE)" } }
	if (-not (Test-Path (Join-Path $CiDir ".git"))) {
		& $git -C $Repo worktree add --detach $CiDir $Ref 2>&1 | Out-Null
		if ($LASTEXITCODE) { throw "git worktree add $CiDir failed ($LASTEXITCODE)" }
	} else {
		& $git -C $CiDir checkout --detach --force $Ref 2>&1 | Out-Null
		if ($LASTEXITCODE) { throw "git checkout $Ref in $CiDir failed ($LASTEXITCODE)" }
	}
	$head = (& $git -C $CiDir log -1 --format="%h %ad %s" --date=short)
	$lines.Add("commit: $head")

	# Be polite: wait for a quiet machine (no Godot engine running) so perf numbers mean something.
	$t0 = Get-Date
	while ((Get-Process -Name "Godot_v4*" -ErrorAction SilentlyContinue) -and ((Get-Date) - $t0).TotalMinutes -lt $WaitQuietMin) { Start-Sleep -Seconds 60 }
	if (Get-Process -Name "Godot_v4*" -ErrorAction SilentlyContinue) { $lines.Add("note: other Godot processes were running; perf numbers may be noisy") }

	$resultFile = Join-Path $ReportDir "$day.ci_result.txt"
	$ciArgs = @{ Dir = $CiDir; ResultFile = $resultFile; Run = "nightly_$day" }
	if ($Quick) { $ciArgs.SkipTests = $true; $ciArgs.SmokeRuns = 1 }
	& (Join-Path $PSScriptRoot "ci.ps1") @ciArgs *>&1 | Out-Null
	if (Test-Path $resultFile) { foreach ($l in Get-Content $resultFile) { $lines.Add($l) } }
	else { $lines.Add("CI: no result file (ci.ps1 crashed?): see docs\ci\nightly_$day\") }
	$lines.Add("full report: $Repo\docs\ci\nightly_$day\ (error_lab\scorecard.md has fix-agent briefs)")
} catch {
	$lines.Add("NIGHTLY ERROR: $($_.Exception.Message)")
}
$lines.Add("finished $(Get-Date -Format HH:mm)")
$lines | Set-Content -Encoding UTF8 $report
$lines | Set-Content -Encoding UTF8 (Join-Path $ReportDir "latest.txt")
Write-Host ($lines -join "`n")
