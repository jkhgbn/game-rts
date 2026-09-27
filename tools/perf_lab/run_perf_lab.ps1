<#
.SYNOPSIS
  Perf Lab runner (docs/plan/perf-lab.md): deterministic perf scenarios, one Godot process at a time, with a
  machine-noise guard, repeats (median) and a scorecard per scenario + mode.

.DESCRIPTION
  For each scenario: -Repeats headless runs (logic / CPU; run 1 has the band profiler on for the hot list) and, unless
  -NoGpu, one windowed run per -Resolutions entry (GPU + render counters). Runs never overlap (parallel runs are
  noise). Before and during every run the guard samples: other Godot processes (not started by this script) and the
  whole-machine CPU load minus our own process. A run is "noisy" when another Godot ran or the other load averaged
  > -NoiseCpu %, or when the in-game calibration loop was > 1.3x slower than the fastest seen in history. The report
  merges quiet runs only (all runs, flagged noisy, when none was quiet). -WaitQuietS waits up to that many seconds
  for the machine to calm down before each run.
  Output: <OutDir>\runs\*.json|.log, <OutDir>\results.jsonl, then tools/perf_lab/perf_report.gd writes the scorecards
  to <OutDir> and docs/perf/lab/latest/, and appends docs/perf/lab/history.md (+ history.jsonl).
  Only the Godot processes this script starts are ever stopped (on -TimeoutMin). git is never run.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tools\perf_lab\run_perf_lab.ps1
.EXAMPLE
  .\run_perf_lab.ps1 -Scenarios mid100,late200 -Repeats 5 -Resolutions 1600x900,3440x1440
.EXAMPLE
  .\run_perf_lab.ps1 -Scenarios early -NoGpu -Quick      (short measure windows, for a smoke check)
#>
param(
	[string]$Dir = "",
	[string[]]$Scenarios = @("early", "mid100", "late200", "vfx_storm", "menu"),
	[int]$Repeats = 3,
	[string[]]$Resolutions = @("1600x900"),
	[switch]$NoGpu,
	[switch]$NoProfile,
	[switch]$Quick,
	[switch]$NoHistory,
	[int]$Seed = 1,
	[string]$OutDir = "",
	[int]$NoiseCpu = 20,
	[int]$WaitQuietS = 0,
	[int]$TimeoutMin = 15,
	[string]$Title = "",
	[string]$Godot = "C:\Godot\Godot_v4.7.2-stable_win64_console.exe"
)

$ErrorActionPreference = "Stop"
# JSON numbers need a dot decimal separator (the user's Windows is French: "79,5" would break the JSON lines).
[Threading.Thread]::CurrentThread.CurrentCulture = [Globalization.CultureInfo]::InvariantCulture
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
if ($Dir -eq "") { $Dir = (Resolve-Path (Join-Path $Here "..\..")).Path }
if (-not (Test-Path $Godot)) { throw "Godot not found: $Godot" }
if (-not (Test-Path (Join-Path $Dir "project.godot"))) { throw "No Godot project in $Dir" }
$Scenarios = @($Scenarios | ForEach-Object { $_ -split "," } | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
$Resolutions = @($Resolutions | ForEach-Object { $_ -split "," } | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
if ($OutDir -eq "") { $OutDir = Join-Path (Split-Path -Parent $Dir) ("four-wizards-perf-runs\" + (Get-Date -Format "yyyyMMdd-HHmm")) }
New-Item -ItemType Directory -Force (Join-Path $OutDir "runs") | Out-Null
$OutDir = (Resolve-Path $OutDir).Path
$Results = Join-Path $OutDir "results.jsonl"
$Cores = [Environment]::ProcessorCount

# The commit, read from the .git files (git itself is never run).
function Get-Commit([string]$root) {
	try {
		$gitdir = Join-Path $root ".git"
		if (Test-Path $gitdir -PathType Leaf) {
			$gitdir = ((Get-Content $gitdir -TotalCount 1) -replace "^gitdir:\s*", "").Trim()
		}
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
$Commit = Get-Commit $Dir
# The working tree may hold uncommitted changes (agents work in this folder): say so in the id.
$Commit = "$Commit+wip"

# ---------------------------------------------------------------- noise guard
function Get-CpuTotal {
	try { return [double](Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'").PercentProcessorTime }
	catch { try { return [double](Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average } catch { return -1 } }
}
# Godot processes this script did not start (the console wrapper starts a child: both are ours).
function Get-OtherGodot([int[]]$ours) {
	$all = @(Get-CimInstance Win32_Process -Filter "Name LIKE 'Godot%'" -ErrorAction SilentlyContinue)
	return @($all | Where-Object { -not ($ours -contains [int]$_.ProcessId) -and -not ($ours -contains [int]$_.ParentProcessId) })
}
function Get-TreeCpu([int]$rootPid) {
	$ids = @($rootPid) + @(Get-CimInstance Win32_Process -Filter "ParentProcessId=$rootPid" -ErrorAction SilentlyContinue | ForEach-Object { [int]$_.ProcessId })
	$t = 0.0
	foreach ($i in $ids) { try { $t += (Get-Process -Id $i -ErrorAction Stop).TotalProcessorTime.TotalSeconds } catch {} }
	return @{ Ids = $ids; Cpu = $t }
}
function Wait-Quiet([int]$seconds) {
	if ($seconds -le 0) { return }
	$until = (Get-Date).AddSeconds($seconds)
	while ((Get-Date) -lt $until) {
		$o = @(Get-OtherGodot @()).Count
		$c = Get-CpuTotal
		if ($o -eq 0 -and $c -ge 0 -and $c -lt $NoiseCpu) { return }
		Write-Host ("  waiting for a quiet machine: {0} other Godot, CPU {1:N0} %" -f $o, $c)
		Start-Sleep -Seconds 10
	}
}

# ---------------------------------------------------------------- jobs
if (-not (Test-Path (Join-Path $Dir ".godot\global_script_class_cache.cfg"))) {
	Write-Host "Importing $Dir (first run)..."
	Start-Process -FilePath $Godot -ArgumentList "--headless --path `"$Dir`" --import" -NoNewWindow -Wait `
		-RedirectStandardOutput (Join-Path $OutDir "import.log") -RedirectStandardError (Join-Path $OutDir "import.err")
}
$Jobs = @()
foreach ($s in $Scenarios) {
	for ($i = 1; $i -le $Repeats; $i++) {
		$Jobs += @{ Scenario = $s; Run = $i; Gpu = $false; Res = ""; Profile = ($i -eq 1 -and -not $NoProfile) }
	}
	if (-not $NoGpu) { foreach ($r in $Resolutions) { $Jobs += @{ Scenario = $s; Run = 1; Gpu = $true; Res = $r; Profile = $false } } }
}
Write-Host ("Perf Lab: {0} runs ({1} scenarios x {2} headless{3}), seed {4}, {5} -> {6}" -f $Jobs.Count, $Scenarios.Count, $Repeats,
	$(if ($NoGpu) { "" } else { " + windowed " + ($Resolutions -join ",") }), $Seed, $Commit, $OutDir)
$Start = Get-Date
$n = 0
foreach ($j in $Jobs) {
	$n++
	Wait-Quiet $WaitQuietS
	$tag = "{0}_{1}{2}_r{3}" -f $j.Scenario, $(if ($j.Gpu) { "gpu" } else { "cpu" }), $(if ($j.Gpu) { "_" + $j.Res } else { "" }), $j.Run
	$json = Join-Path $OutDir "runs\$tag.json"
	$log = Join-Path $OutDir "runs\$tag.log"
	$err = Join-Path $OutDir "runs\$tag.err"
	if (Test-Path $json) { Remove-Item $json }
	$extra = ""
	if ($Quick) { $extra = "--measure=8" }
	$prof = if ($j.Profile) { "1" } else { "0" }
	$display = if ($j.Gpu) { "--resolution $($j.Res) --position 0,0" } else { "--headless" }
	$a = "$display --path `"$Dir`" -s res://tools/perf_lab/perf_lab.gd --fixed-fps 60 --quit-after 40000 -- " +
		"--scenario=$($j.Scenario) --seed=$Seed --profile=$prof --run=$($j.Run) --commit=$Commit `"--out=$($json -replace '\\', '/')`" $extra"
	$before = @(Get-OtherGodot @())
	$cpu0 = Get-CpuTotal
	$proc = Start-Process -FilePath $Godot -ArgumentList $a -NoNewWindow -PassThru -RedirectStandardOutput $log -RedirectStandardError $err
	$t0 = Get-Date
	$samples = @()
	$maxOther = $before.Count
	$otherNames = @{}
	foreach ($b in $before) { $otherNames[[string]$b.ProcessId] = $true }
	$prevTree = Get-TreeCpu $proc.Id
	$prevT = Get-Date
	while (-not $proc.HasExited) {
		Start-Sleep -Milliseconds 2000
		if (((Get-Date) - $t0).TotalMinutes -gt $TimeoutMin) {
			& taskkill.exe /PID $proc.Id /T /F | Out-Null   # our own process tree only
			break
		}
		$tree = Get-TreeCpu $proc.Id
		$now = Get-Date
		$others = @(Get-OtherGodot $tree.Ids)
		foreach ($o in $others) { $otherNames[[string]$o.ProcessId] = $true }
		$maxOther = [Math]::Max($maxOther, $others.Count)
		$total = Get-CpuTotal
		$dt = ($now - $prevT).TotalSeconds
		$ours = if ($dt -gt 0) { 100.0 * ($tree.Cpu - $prevTree.Cpu) / $dt / $Cores } else { 0 }
		if ($total -ge 0) { $samples += [Math]::Max(0.0, $total - $ours) }
		$prevTree = $tree
		$prevT = $now
	}
	$wall = [Math]::Round(((Get-Date) - $t0).TotalSeconds, 1)
	$otherLoad = if ($samples.Count -gt 0) { [Math]::Round(($samples | Measure-Object -Average).Average, 1) } else { -1 }
	$reasons = @()
	if ($otherNames.Count -gt 0) { $reasons += "$($otherNames.Count) other Godot process(es) (max $maxOther at once)" }
	if ($otherLoad -gt $NoiseCpu) { $reasons += "other CPU load $otherLoad %" }
	$scriptErrors = 0
	foreach ($f in @($log, $err)) { if (Test-Path $f) { $scriptErrors += @(Select-String -Path $f -Pattern "SCRIPT ERROR" -SimpleMatch).Count } }
	$line = $null
	if (Test-Path $json) { $line = (Get-Content $json -TotalCount 1) }
	$noisy = if ($reasons.Count -gt 0) { "true" } else { "false" }
	$rj = ($reasons | ForEach-Object { '"' + ($_ -replace '"', "'") + '"' }) -join ","
	if ($line -and $line.StartsWith("{")) {
		$line = "{" + ('"noisy":{0},"noise_reasons":[{1}],"other_cpu_pct":{2},"other_godot_max":{3},"cpu_before_pct":{4},"script_errors":{5},"wall_s":{6},"log":"{7}",' -f `
			$noisy, $rj, $otherLoad, $maxOther, $cpu0, $scriptErrors, $wall, ($tag + ".log")) + $line.Substring(1)
		[IO.File]::AppendAllText($Results, $line + "`n", (New-Object Text.UTF8Encoding $false))
		$avg = ""
		if ($line -match '"frame":\{[^}]*"avg":([\d.]+)') { $avg = $Matches[1] }
		Write-Host ("[{0}/{1}] {2}: avg {3} ms, {4} s{5}{6}" -f $n, $Jobs.Count, $tag, $avg, $wall,
			$(if ($noisy -eq "true") { ", NOISY: " + ($reasons -join "; ") } else { ", quiet" }),
			$(if ($scriptErrors -gt 0) { ", $scriptErrors script errors" } else { "" }))
	} else {
		Write-Host ("[{0}/{1}] {2}: NO RESULT (exit {3}, {4} s) - see {5}" -f $n, $Jobs.Count, $tag, $proc.ExitCode, $wall, $log)
	}
}
$Wall = [Math]::Round(((Get-Date) - $Start).TotalSeconds, 0)
Write-Host "Runs done in $Wall s. Report..."
if ($Title -eq "") { $Title = "$($Scenarios -join ', ') x $Repeats (seed $Seed, $Commit)" }
$hist = if ($NoHistory) { "--no-history" } else { "" }
$rep = "--headless --path `"$Dir`" -s res://tools/perf_lab/perf_report.gd --quit-after 600 -- `"--in=$($Results -replace '\\', '/')`" " +
	"`"--out=$($OutDir -replace '\\', '/')`" `"--title=$Title`" $hist"
Start-Process -FilePath $Godot -ArgumentList $rep -NoNewWindow -Wait -RedirectStandardOutput (Join-Path $OutDir "report.log") `
	-RedirectStandardError (Join-Path $OutDir "report.err")
Get-Content (Join-Path $OutDir "report.log") | Where-Object { $_ -match "PERF_LAB|  \w" }
Write-Host "Scorecards: $OutDir and $(Join-Path $Dir 'docs\perf\lab\latest')"
