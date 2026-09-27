<#
.SYNOPSIS
  Balance Lab runner (docs/plan/balance-lab.md): Bot Lab matches for a BASELINE arm and one or more stat VARIANT arms
  over the same pairs and seeds, then a scorecard comparing win rate / length / score per pair.

.DESCRIPTION
  Each arm = one variant JSON (tools/balance_lab/variants/*.json, applied in memory by balance_match.gd at match start;
  data/*.tres are never written) or "baseline" (no override). Jobs are interleaved (pair, seed, then arm) so the
  baseline and the variant of one pair / seed run at about the same time, under the same machine load.
  Same machinery as tools/bot_lab/run_lab.ps1: sim mode, the machine-wide Godot gate (FW_GODOT_SLOTS / HARDCAP /
  MAXWAIT), -StopAt, per-match timeout; only the Godot processes this script starts are ever stopped.
  Raw output (matches, logs, results.jsonl) goes to -OutDir (outside the repo); the scorecard goes to
  <repo>\docs\balance\lab\<run>\ (scorecard.md, scorecard.json) and one row to docs\balance\lab\history.md.
  -Dir defaults to the lab worktree (..\four-wizards-rts-lab) when it exists, else this repo (laptop). Before starting,
  the runner prints the expected wall time and what N per arm can show (~98 games per arm for a 20-point change);
  -DryRun prints that plan and starts nothing.

.EXAMPLE
  .\tools\balance_lab\run_balance.ps1 -Variants tools\balance_lab\variants\grave_hound_dps.json -Pairs shadow:fire,fire:shadow -Seeds 1 -StopAt 00:35

.EXAMPLE
  .\tools\balance_lab\run_balance.ps1 -Variants a.json,b.json -Pairs shadow:fire,fire:shadow,shadow:nature,nature:shadow -Seeds 1-6 -Tick 30
#>
param(
	[string]$Dir = "",
	[string[]]$Variants = @(),
	[switch]$NoBaseline,
	[string[]]$Pairs = @(),
	[string[]]$Seeds = @("1"),
	[int]$Parallel = 0,
	[string]$Difficulty = "normal",
	[string]$Style = "balanced",
	[ValidateSet("on", "off")][string]$Sim = "on",
	[string]$OutDir = "",
	[string]$Run = "",
	[string]$ReportDir = "",
	[int]$Limit = 1800,
	[ValidateSet("on", "off")][string]$Early = "on",
	[int]$Tick = 60,
	[string]$Extra = "",
	[int]$TimeoutMin = 90,
	[string]$StopAt = "",
	[switch]$NoHistory,
	[switch]$DryRun,
	[string]$Godot = "C:\Godot\Godot_v4.7.2-stable_win64_console.exe"
)

$ErrorActionPreference = "Stop"
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$Repo = (Resolve-Path (Join-Path $Here "..\..")).Path
$Kingdoms = @("fire", "shadow", "ice", "nature")
# Default project: the lab worktree (desktop) when it exists, else this repo (laptop: no worktree).
if ($Dir -eq "") {
	$Dir = Join-Path (Split-Path -Parent $Repo) "four-wizards-rts-lab"
	if (-not (Test-Path (Join-Path $Dir "project.godot"))) { $Dir = $Repo }
}

if (-not (Test-Path $Godot)) { throw "Godot not found: $Godot" }
$GuiExe = $Godot -replace "_console\.exe$", ".exe"
if ($GuiExe -ne $Godot -and (Test-Path $GuiExe)) { $Godot = $GuiExe }
if (-not (Test-Path (Join-Path $Dir "project.godot"))) { throw "No Godot project in $Dir" }
$Dir = (Resolve-Path $Dir).Path

if ($Pairs.Count -eq 0) { $Pairs = foreach ($p in $Kingdoms) { foreach ($e in $Kingdoms) { if ($p -ne $e) { "${p}:${e}" } } } }
$Pairs = @($Pairs | ForEach-Object { $_ -split "," } | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ -ne "" })
foreach ($p in $Pairs) {
	$k = $p -split ":"
	if ($k.Count -ne 2 -or -not ($Kingdoms -contains $k[0]) -or -not ($Kingdoms -contains $k[1])) { throw "Bad pair '$p' (use fire:ice)" }
}
$SeedList = @()
foreach ($item in ($Seeds | ForEach-Object { $_ -split "," })) {
	$item = $item.Trim()
	if ($item -match "^(\d+)-(\d+)$") { $SeedList += ([int]$Matches[1])..([int]$Matches[2]) }
	elseif ($item -match "^\d+$") { $SeedList += [int]$item }
	elseif ($item -ne "") { throw "Bad seed '$item' (use 1,2,3 or 1-6)" }
}
$Seeds = $SeedList
# Default: logical CPUs - 2, but never more than the shared Godot gate lets run at once (FW_GODOT_SLOTS, default 4).
if ($Parallel -le 0) {
	$slots = 4; if ($env:FW_GODOT_SLOTS) { $slots = [int]$env:FW_GODOT_SLOTS }
	$Parallel = [Math]::Max(1, [Math]::Min($slots, [Environment]::ProcessorCount - 2))
}
if ($Run -eq "") { $Run = Get-Date -Format "yyyy-MM-dd_HHmm" }
if ($OutDir -eq "") { $OutDir = Join-Path (Split-Path -Parent $Repo) ("four-wizards-lab-runs\balance-" + $Run) }
if ($ReportDir -eq "") { $ReportDir = Join-Path $Repo "docs\balance\lab\$Run" }
if (-not $DryRun) {
	New-Item -ItemType Directory -Force (Join-Path $OutDir "matches") | Out-Null
	New-Item -ItemType Directory -Force (Join-Path $OutDir "variants") | Out-Null
	$OutDir = (Resolve-Path $OutDir).Path
}
$Results = Join-Path $OutDir "results.jsonl"

# Arms: baseline first, then each variant (copied into the run folder so the run keeps what it tested).
$Arms = @()
if (-not $NoBaseline) { $Arms += @{ Name = "baseline"; File = "baseline" } }
foreach ($v in ($Variants | ForEach-Object { $_ -split "," } | Where-Object { $_.Trim() -ne "" })) {
	$vp = $v.Trim()
	if (-not [IO.Path]::IsPathRooted($vp)) {
		if (Test-Path $vp) { $vp = (Resolve-Path $vp).Path }
		elseif (Test-Path (Join-Path $Repo $vp)) { $vp = (Join-Path $Repo $vp) }
		elseif (Test-Path (Join-Path $Here "variants\$vp")) { $vp = (Join-Path $Here "variants\$vp") }
		elseif (Test-Path (Join-Path $Here "variants\$vp.json")) { $vp = (Join-Path $Here "variants\$vp.json") }
	}
	if (-not (Test-Path $vp)) { throw "Variant not found: $v" }
	try { $vj = Get-Content $vp -Raw | ConvertFrom-Json } catch { throw "Variant $vp is not valid JSON: $_" }
	$name = if ($vj.name) { [string]$vj.name } else { [IO.Path]::GetFileNameWithoutExtension($vp) }
	$name = ($name -replace "[^\w\-]", "_")
	$copy = Join-Path $OutDir "variants\$name.json"
	if ($DryRun) { $copy = $vp } else { Copy-Item $vp $copy -Force }
	$Arms += @{ Name = $name; File = ($copy -replace "\\", "/") }
}
if ($Arms.Count -eq 0) { throw "Nothing to run (no baseline, no variant)" }

# The match script: the project's copy when it has one (res://), else ours by absolute path (it extends
# ../bot_lab/lab_match.gd relative to itself, so our bot_lab copy comes with it).
function Resolve-Script([string]$sub, [string]$name) {
	if (Test-Path (Join-Path $Dir "tools\$sub\$name")) { return "res://tools/$sub/$name" }
	return ((Join-Path $Repo "tools\$sub\$name") -replace "\\", "/")
}
$MatchScript = Resolve-Script "balance_lab" "balance_match.gd"
$ReportScript = ((Join-Path $Here "balance_report.gd") -replace "\\", "/")

if (-not $DryRun -and -not (Test-Path (Join-Path $Dir ".godot\global_script_class_cache.cfg"))) {
	Write-Host "Importing $Dir (first run)..."
	Start-Process -FilePath $Godot -ArgumentList "--headless --path `"$Dir`" --import" -NoNewWindow -PassThru -Wait `
		-RedirectStandardOutput (Join-Path $OutDir "import.log") -RedirectStandardError (Join-Path $OutDir "import.err") | Out-Null
}

$SimArg = if ($Sim -eq "on") { "1" } else { "0" }
$EarlyArg = if ($Early -eq "on") { "1" } else { "0" }
$QuitAfter = ($Limit + 240) * $Tick + 8000
$Jobs = New-Object System.Collections.Queue
foreach ($s in $Seeds) { foreach ($p in $Pairs) { foreach ($a in $Arms) { $Jobs.Enqueue(@{ Pair = $p; Seed = $s; Arm = $a }) } } }
$Total = $Jobs.Count
Write-Host ("Balance Lab: {0} matches ({1} arms x {2} pairs x {3} seeds), {4} in parallel, sim {5}, limit {6} s, tick {7}" -f `
	$Total, $Arms.Count, $Pairs.Count, $Seeds.Count, $Parallel, $Sim, $Limit, $Tick)
Write-Host ("Arms: " + (($Arms | ForEach-Object { $_.Name }) -join ", "))
Write-Host "Dir $Dir -> $OutDir"
. (Join-Path $Repo "tools\bot_lab\lab_eta.ps1")
$Eta = Get-LabEta -Games $Total -Limit $Limit -EarlyOn ($Early -eq "on") -SimOn ($Sim -eq "on") -Tick $Tick -Parallel $Parallel
Write-Host ("Expected wall time: ~{0} on a quiet PC, up to ~{1} while other agents run Godot (rough model, tools\bot_lab\lab_eta.ps1)." -f `
	(Format-LabMinutes $Eta.QuietMin), (Format-LabMinutes $Eta.BusyMin))
# Evidence: ~98 games per arm per matchup-level question to see a 20-point win-rate change, ~392 for 10 points
# (balance_report.gd games_needed, 80 % power). Say what this batch can and cannot show before it runs.
$PerArm = $Pairs.Count * $Seeds.Count
if ($PerArm -lt 98) {
	$e98 = Get-LabEta -Games (98 * $Arms.Count) -Limit $Limit -EarlyOn ($Early -eq "on") -SimOn ($Sim -eq "on") -Tick $Tick -Parallel $Parallel
	Write-Host ("Evidence: {0} games per arm. A 20-point win-rate change needs ~98 per arm (~{1} quiet / ~{2} busy for {3} arm(s)); below that the scorecard is a direction hint (WARN), not a verdict." -f `
		$PerArm, (Format-LabMinutes $e98.QuietMin), (Format-LabMinutes $e98.BusyMin), $Arms.Count)
}
if ($DryRun) {
	foreach ($j in $Jobs) { Write-Host ("  {0} {1} seed {2}" -f $j.Arm.Name, $j.Pair, $j.Seed) }
	Write-Host "Dry run: nothing started."
	return
}

$StopTime = $null
if ($StopAt -ne "") {
	$StopTime = [DateTime]::ParseExact($StopAt, "HH:mm", [Globalization.CultureInfo]::InvariantCulture)
	if ($StopTime -le (Get-Date)) { $StopTime = $StopTime.AddDays(1) }
	Write-Host ("Hard stop at {0:yyyy-MM-dd HH:mm}" -f $StopTime)
}
$Stopped = $false
$GateSlots = 4; if ($env:FW_GODOT_SLOTS) { $GateSlots = [int]$env:FW_GODOT_SLOTS }
$HardCap = 6; if ($env:FW_GODOT_HARDCAP) { $HardCap = [int]$env:FW_GODOT_HARDCAP }
$MaxWait = 900; if ($env:FW_GODOT_MAXWAIT) { $MaxWait = [int]$env:FW_GODOT_MAXWAIT }
$Gate = New-Object System.Threading.Semaphore($GateSlots, $GateSlots, "Local\FourWizardsGodotGate")
$WaitSince = $null
$Running = @()
$Done = 0
$Failed = 0
$Start = Get-Date
try {
while ($Jobs.Count -gt 0 -or $Running.Count -gt 0) {
	if ($StopTime -and -not $Stopped -and (Get-Date) -ge $StopTime) {
		$Stopped = $true
		Write-Host ("Hard stop reached: {0} matches not started, {1} running stopped" -f $Jobs.Count, $Running.Count)
		$Jobs.Clear()
	}
	while (-not $Stopped -and $Running.Count -lt $Parallel -and $Jobs.Count -gt 0) {
		if ($null -eq $WaitSince) { $WaitSince = Get-Date }
		$late = ((Get-Date) - $WaitSince).TotalSeconds -gt $MaxWait
		$held = $Gate.WaitOne(0)
		$godots = @(Get-Process -Name "Godot_v4.7.2*" -ErrorAction SilentlyContinue).Count
		if (-not $late -and (-not $held -or $godots -ge $HardCap)) {
			if ($held) { [void]$Gate.Release() }
			break
		}
		$WaitSince = $null
		$j = $Jobs.Dequeue()
		$name = ("{0}_{1}_s{2}" -f $j.Arm.Name, ($j.Pair -replace ":", "-"), $j.Seed)
		$json = Join-Path $OutDir "matches\$name.json"
		$log = Join-Path $OutDir "matches\$name.log"
		$err = Join-Path $OutDir "matches\$name.err"
		if (Test-Path $json) { Remove-Item $json }
		$a = "--headless --path `"$Dir`" -s `"$MatchScript`" --fixed-fps $Tick --quit-after $QuitAfter -- " +
			"--pair=$($j.Pair) --seed=$($j.Seed) --difficulty=$Difficulty --style=$Style --sim=$SimArg --limit=$Limit " +
			"--early=$EarlyArg --tick=$Tick `"--variant=$($j.Arm.File)`" `"--out=$($json -replace '\\', '/')`" $Extra"
		$proc = Start-Process -FilePath $Godot -ArgumentList $a -NoNewWindow -PassThru -RedirectStandardOutput $log -RedirectStandardError $err
		$null = $proc.Handle
		$Running += @{ Proc = $proc; Job = $j; Name = $name; Json = $json; Log = $log; Err = $err; Start = Get-Date; Held = $held }
	}
	Start-Sleep -Milliseconds 500
	$still = @()
	foreach ($r in $Running) {
		$timedOut = $Stopped -or ((Get-Date) - $r.Start).TotalMinutes -gt $TimeoutMin
		if (-not $r.Proc.HasExited -and -not $timedOut) { $still += $r; continue }
		if (-not $r.Proc.HasExited) {
			try { $r.Proc.Kill() } catch {}   # our own process only
			Start-Sleep -Milliseconds 300
		}
		if ($r.Held) { [void]$Gate.Release(); $r.Held = $false }
		$real = [Math]::Round(((Get-Date) - $r.Start).TotalSeconds, 1)
		$cpu = 0
		try { $cpu = [Math]::Round($r.Proc.TotalProcessorTime.TotalSeconds, 1) } catch {}
		$scriptErrors = 0
		foreach ($f in @($r.Log, $r.Err)) {
			if (Test-Path $f) { $scriptErrors += @(Select-String -Path $f -Pattern "SCRIPT ERROR" -SimpleMatch).Count }
		}
		$line = $null
		if (Test-Path $r.Json) { $line = (Get-Content $r.Json -TotalCount 1) }
		$armJson = ('"arm":"{0}",' -f $r.Job.Arm.Name)
		if ($line -and $line.StartsWith("{")) {
			$line = "{" + $armJson + ('"script_errors":{0},"wall_s":{1},"cpu_s":{2},"log":"{3}",' -f $scriptErrors, `
				([string]$real).Replace(",", "."), ([string]$cpu).Replace(",", "."), ($r.Name + ".log")) + $line.Substring(1)
			$Done++
		} else {
			$why = if ($Stopped) { "stopped at $StopAt" } elseif ($timedOut) { "timeout after $TimeoutMin min" } `
				else { "no result (exit code $($r.Proc.ExitCode))" }
			$line = ('{{{0}"pair":"{1}","player":"{2}","enemy":"{3}","seed":{4},"error":"{5}","script_errors":{6},"real_s":{7},"log":"{8}"}}' -f `
				$armJson, $r.Job.Pair, ($r.Job.Pair -split ":")[0], ($r.Job.Pair -split ":")[1], $r.Job.Seed, $why, $scriptErrors, `
				([string]$real).Replace(",", "."), ($r.Name + ".log"))
			$Failed++
		}
		[IO.File]::AppendAllText($Results, $line + "`n", (New-Object Text.UTF8Encoding $false))
		$w = ""; if ($line -match '"winner":"(\w+)"') { $w = $Matches[1] }
		$why2 = ""; if ($line -match '"end_reason":"([\w-]+)"') { $why2 = $Matches[1] }
		$when = ""; if ($line -match '"end_clock":"([\d:]+)"') { $when = $Matches[1] }
		Write-Host ("[{0}/{1}] {2} {3} seed {4}: {5} {6} {7} ({8} s{9})" -f ($Done + $Failed), $Total, $r.Job.Arm.Name, $r.Job.Pair, `
			$r.Job.Seed, $w, $why2, $when, $real, $(if ($scriptErrors -gt 0) { ", $scriptErrors script errors" } else { "" }))
	}
	$Running = $still
}
} finally {
	foreach ($r in $Running) { if ($r.Held) { try { [void]$Gate.Release() } catch {} } }
	$Gate.Dispose()
}
$Wall = [Math]::Round(((Get-Date) - $Start).TotalSeconds, 0)
Write-Host ("Done: {0} ok, {1} failed, wall {2} s" -f $Done, $Failed, $Wall)

# The scorecard (a few seconds, not gated, like run_lab's report).
$hist = if ($NoHistory) { "0" } else { "1" }
$rep = "--headless --path `"$Dir`" -s `"$ReportScript`" --quit-after 600 -- `"--in=$($Results -replace '\\', '/')`" " +
	"`"--out=$($ReportDir -replace '\\', '/')`" `"--run=$Run`" --wall=$Wall --limit=$Limit --tick=$Tick --sim=$Sim " +
	"`"--history=$((Join-Path $Repo 'docs\balance\lab\history.md') -replace '\\', '/')`" --log=$hist"
Start-Process -FilePath $Godot -ArgumentList $rep -NoNewWindow -Wait -RedirectStandardOutput (Join-Path $OutDir "report.log") `
	-RedirectStandardError (Join-Path $OutDir "report.err")
Get-Content (Join-Path $OutDir "report.log") | Select-String "BALANCE LAB" | ForEach-Object { Write-Host $_.Line }
if (Test-Path (Join-Path $ReportDir "scorecard.md")) {
	Write-Host "Scorecard: $(Join-Path $ReportDir 'scorecard.md')"
} else {
	Write-Host "Report failed: see $(Join-Path $OutDir 'report.err')"
}
