<#
.SYNOPSIS
  Game Health Dashboard (docs/design/health-and-playtests.md): one score 0-100 from the latest outputs of every lab.

.DESCRIPTION
  Reads (never re-runs) the CI / Error Lab scorecards, Perf Lab latest, Balance + Unit Lab, map gate scorecards + map
  balance model, Map / Art / Visual / Audio / UI / Data Lab scorecards, the Replay / Build Lab history and the content
  folders (missions, unit guide / icons / voices, localization). Writes docs\health\latest.md, docs\health\latest.html
  (self-contained) and one row in docs\health\history.jsonl, then prints the score and the top 3 problems.
  -Refresh first runs the QUICK labs (Data Lab ~10 s, map balance model ~25 s per ready map) into docs\health\refresh\
  (the labs' own folders and the balance model's dataset are not touched). git is never run.

.EXAMPLE
  .\tools\health\run_health.ps1
.EXAMPLE
  .\tools\health\run_health.ps1 -Refresh
.EXAMPLE
  .\tools\health\run_health.ps1 -NoHistory -Open
#>
param(
	[switch]$Refresh,
	[switch]$NoHistory,
	[switch]$Open,
	[string]$OutDir = ""
)
$ErrorActionPreference = "Continue"
$proj = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$gate = Join-Path $proj "tools\godot_run.ps1"

if ($Refresh) {
	$ref = Join-Path $proj "docs\health\refresh"
	New-Item -ItemType Directory -Force (Join-Path $ref "map_balance") | Out-Null
	Write-Host "health -Refresh: Data Lab..."
	$o = ((Join-Path $ref "data_lab") -replace "\\", "/")
	& $gate --headless --path $proj -s res://tools/data_lab/data_lab.gd '--quit-after' 1200 '--' "out=$o" "log=0" "run=health-refresh" 2>&1 |
		Select-String "^DATA LAB" | Select-Object -Last 1 | ForEach-Object { Write-Host "  $_" }
	# Ready skirmish maps from the catalog text (ids of entries with "ready": true).
	$cat = Get-Content (Join-Path $proj "data\maps\catalog.tres") -Raw
	$ids = @()
	foreach ($block in ($cat -split '\}, \{')) {
		if ($block -match '"id": &"([a-z0-9_]+)"') {
			$id = $Matches[1]
			if ($block -match '"ready": true' -and $block -notmatch '"mode": "wave_strike"') { $ids += $id }
		}
	}
	foreach ($m in ($ids | Select-Object -Unique)) {
		Write-Host "health -Refresh: map balance $m..."
		$mo = ((Join-Path $ref "map_balance\$m.json") -replace "\\", "/")
		& $gate --headless --path $proj -s res://tools/map_lab/balance/balance.gd '--fixed-fps' 60 '--quit-after' 9000 '--' "map=$m" "out=$mo" 2>&1 |
			Select-String "^BALANCE" | Select-Object -Last 1 | ForEach-Object { Write-Host "  $_" }
	}
}

$user = @()
if ($OutDir) { $user += "out=$($OutDir -replace '\\', '/')" }
if ($NoHistory) { $user += "no-history" }
$lines = & $gate --headless --path $proj -s res://tools/health/health.gd '--quit-after' 3000 '--' @user 2>&1
$code = $LASTEXITCODE
$lines | Where-Object { "$_" -match "^HEALTH|SCRIPT ERROR|Parse Error" } | ForEach-Object { Write-Host $_ }
if (-not ($lines | Where-Object { "$_" -match "^HEALTH: wrote" })) { Write-Host "health: FAILED (no report written)"; exit 1 }
if ($Open) {
	$html = if ($OutDir) { Join-Path $OutDir "latest.html" } else { Join-Path $proj "docs\health\latest.html" }
	Start-Process $html
}
exit $code
