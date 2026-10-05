<#
.SYNOPSIS
  Balance model labels (docs/tools/map_gate/balance_model.md): Bot Lab games on many maps, seats alternated as the
  map gate's G5 plays them (odd seeds: the PLAYER bot on seat 0, even seeds: --swap-sides), mirrors fire / shadow /
  ice / nature x easy / normal / hard. Results land in tools\map_lab\balance\labels\<map>\<difficulty>[_swap].jsonl.

.DESCRIPTION
  Work units (map x difficulty x seat order) are dealt to -Workers background runners; each runs tools\bot_lab\run_lab.ps1
  -Parallel 1 unit after unit, so -Workers games run at once (Bot Lab's own Godot semaphore holds the global limit
  of 4 with every other agent's runs). A unit already complete in labels\ is skipped (re-run = resume).
  -Seeds N = N seeds per seat order (seed 2k-1 normal, 2k swapped) -> 8 N games per difficulty per map.

.EXAMPLE
  tools\map_lab\balance\run_labels.ps1 -Maps thornwater_s20,gtest_s4 -Seeds 1 -Limit 1200
  tools\map_lab\balance\run_labels.ps1 -Maps tw_eco0_far -DryRun
#>
param(
	[string[]]$Maps = @(),
	[int]$Seeds = 1,
	[int]$FirstSeed = 1,
	[string[]]$Difficulties = @("easy", "normal", "hard"),
	[int]$Limit = 1200,
	[int]$Workers = 4,
	[string]$RunsDir = "",
	[int]$Worker = -1,
	[string]$UnitFile = "",
	[switch]$DryRun
)
$ErrorActionPreference = "Stop"
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$Repo = (Resolve-Path (Join-Path $Here "..\..\..")).Path
$Lab = Join-Path $Repo "tools\bot_lab\run_lab.ps1"
$Labels = Join-Path $Here "labels"
if ($RunsDir -eq "") { $RunsDir = Join-Path (Split-Path -Parent $Repo) "four-wizards-lab-runs\balance" }
$Mirrors = "fire:fire,shadow:shadow,ice:ice,nature:nature"

function Resolve-Layout([string]$id) {
	foreach ($p in @("data\maps\${id}_layout.tres", "data\maps\gen\${id}_layout.tres", "tools\map_lab\balance\variants\${id}_layout.tres")) {
		if (Test-Path (Join-Path $Repo $p)) { return "res://" + ($p -replace "\\", "/") }
	}
	throw "No layout for map '$id'"
}

# ---- worker mode: run the units listed in the unit file for this worker
if ($Worker -ge 0) {
	$units = Get-Content $UnitFile | ConvertFrom-Json
	foreach ($u in $units) {
		if ([int]$u.worker -ne $Worker) { continue }
		$dest = Join-Path $Labels "$($u.map)\$($u.cell).jsonl"
		$out = Join-Path $RunsDir "$($u.map)\$($u.cell)_s$($u.seed)"
		$extra = "--layout=$($u.layout)"
		if ($u.swap) { $extra = "$extra --swap-sides=1" }
		& $Lab -Dir $Repo -Pairs $Mirrors -Seeds "$($u.seed)" -Difficulty $u.diff -Limit $Limit -Parallel 1 -Extra $extra `
			-OutDir $out -Title "balance labels $($u.map) $($u.cell) seed $($u.seed)" -TimeoutMin 240 *>> (Join-Path $RunsDir "worker$Worker.log")
		$res = Join-Path $out "results.jsonl"
		if (Test-Path $res) {
			New-Item -ItemType Directory -Force (Split-Path -Parent $dest) | Out-Null
			Get-Content $res | Where-Object { $_.Trim() -ne "" } | Add-Content -Path $dest -Encoding utf8
		}
		Add-Content -Path (Join-Path $RunsDir "progress.log") -Value ("{0:HH:mm} worker {1} done {2} {3} seed {4}" -f (Get-Date), $Worker, $u.map, $u.cell, $u.seed)
	}
	exit 0
}

# ---- driver: build the unit list (skip units whose games are already in labels\), start the workers
if ($Maps.Count -eq 0) { Get-Help $PSCommandPath -Detailed | Out-Host; exit 2 }
$Maps = @($Maps | ForEach-Object { $_ -split "," } | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
New-Item -ItemType Directory -Force $RunsDir | Out-Null
$units = @()
$i = 0
foreach ($k in 0..($Seeds - 1)) {
	foreach ($m in $Maps) {
		$lay = Resolve-Layout $m
		foreach ($d in $Difficulties) {
			foreach ($swap in @($false, $true)) {
				$seed = $FirstSeed + 2 * $k + $(if ($swap) { 1 } else { 0 })
				$cell = if ($swap) { "${d}_swap" } else { $d }
				$dest = Join-Path $Labels "$m\$cell.jsonl"
				if (Test-Path $dest) {
					$have = @(Get-Content $dest | Where-Object { $_ -match "`"seed`":$seed[,}]" }).Count
					if ($have -ge 4) { continue }
				}
				$units += [pscustomobject]@{ map = $m; layout = $lay; diff = $d; swap = $swap; cell = $cell; seed = $seed; worker = ($i % $Workers) }
				$i++
			}
		}
	}
}
$games = $units.Count * 4
Write-Host ("Balance labels: {0} units x 4 mirrors = {1} games on {2} map(s), {3} workers, limit {4} s (~{5:N1} h at ~5 min a game)" -f `
	$units.Count, $games, $Maps.Count, $Workers, $Limit, ($games * 5.0 / 60.0 / $Workers))
if ($DryRun -or $units.Count -eq 0) { $units | Format-Table map, cell, seed, worker | Out-Host; exit 0 }
$uf = Join-Path $RunsDir ("units_{0:yyyyMMdd_HHmmss}.json" -f (Get-Date))
$units | ConvertTo-Json -Depth 3 | Set-Content -Path $uf -Encoding utf8
$procs = @()
foreach ($w in 0..($Workers - 1)) {
	$procs += Start-Process -FilePath "powershell.exe" -WindowStyle Hidden -PassThru -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass",
		"-File", "`"$PSCommandPath`"", "-Worker", "$w", "-UnitFile", "`"$uf`"", "-Limit", "$Limit", "-RunsDir", "`"$RunsDir`"")
}
Write-Host ("Started {0} workers (pids {1}); progress: {2}" -f $Workers, (($procs | ForEach-Object { $_.Id }) -join ", "), (Join-Path $RunsDir "progress.log"))
$procs | Wait-Process
Write-Host "Balance labels: done"
