<#
.SYNOPSIS
  Bot Lab runner (docs/plan/bot-lab.md): many headless bot-vs-bot matches in parallel, one JSON line each, then a
  Markdown + HTML report.

.DESCRIPTION
  Runs tools/bot_lab/lab_match.gd once per (pair, seed) in -Dir (default: the lab worktree), up to -Parallel Godot
  processes at a time. Each match writes <OutDir>\matches\<pair>_s<seed>.json (+ .log); every result is appended to
  <OutDir>\results.jsonl, then tools/bot_lab/lab_report.gd writes <OutDir>\report.md and report.html.
  lab_match.gd / lab_report.gd are taken from -Dir when it has them, else from this script's own folder (so a lab
  worktree on an older commit still works; sim mode is then "partial": per-frame savings only).
  Only the Godot processes this script starts are ever stopped (on -TimeoutMin).
  -Dir defaults to the lab worktree (..\four-wizards-rts-lab) when it exists, else this repo (laptop).
  Before starting, the runner prints the expected wall time (quiet PC .. busy PC); -DryRun prints the plan and stops.
  -Validate runs the sim-vs-normal validation (bot-lab.md "Validation"): 3 arms (normal = sim off, sim, sim30 =
  sim + tick 30) over the same pairs x seeds (default fire:shadow,ice:nature x 1-8, 10:00, early stop off, no stall),
  and the report compares the arms.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tools\bot_lab\run_lab.ps1
  (16 pairs x seed 1, sim, normal, balanced, into ..\four-wizards-lab-runs\<date-time>)

.EXAMPLE
  .\run_lab.ps1 -Pairs fire:ice,ice:fire -Seeds 1-6 -Difficulty "player:hard,enemy:normal" -Sim off

.EXAMPLE
  .\run_lab.ps1 -Validate -DryRun      (the plan + expected time of the sim-vs-normal validation, nothing run)

.EXAMPLE
  .\run_lab.ps1 -Short                 (quick validation: fire:shadow x seeds 1-2 x 3 arms, 5:30 each, ~10 min, hard stop +11 min)
#>
param(
	[string]$Dir = "",
	[string[]]$Pairs = @(),
	[string[]]$Seeds = @("1"),
	[int]$Parallel = 0,
	[string]$Difficulty = "normal",
	[string]$Style = "balanced",
	[ValidateSet("on", "off")][string]$Sim = "on",
	[string]$OutDir = "",
	[int]$Limit = 1800,
	[ValidateSet("on", "off")][string]$Early = "on",
	[int]$Tick = 60,
	[string]$Extra = "",
	[string]$Title = "",
	[int]$TimeoutMin = 90,
	[string]$StopAt = "",
	[switch]$Validate,
	[switch]$Short,
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
if ($Short) {
	# -Short = the quick validation (bot-lab.md "Validation, short mode"): 1 pair x 2 seeds x 3 arms = 6 matches of 5:30,
	# fits in ~10 min on a quiet PC; a hard stop 11 min from now unless -StopAt is given. A smoke of the arms, not a verdict.
	$Validate = $true
	if (-not $PSBoundParameters.ContainsKey("Pairs")) { $Pairs = @("fire:shadow") }
	if (-not $PSBoundParameters.ContainsKey("Seeds")) { $Seeds = @("1-2") }
	if (-not $PSBoundParameters.ContainsKey("Limit")) { $Limit = 330 }
	if ($StopAt -eq "") { $StopAt = (Get-Date).AddMinutes(11).ToString("HH:mm") }
	if ($Title -eq "") { $Title = "Bot Lab validation (short): sim vs normal" }
}
if ($Validate) {
	# bot-lab.md "Validation": same pairs x seeds in 3 arms, 10:00 scored at the limit, no early stop, no stall end.
	if (-not $PSBoundParameters.ContainsKey("Pairs") -and -not $Short) { $Pairs = @("fire:shadow", "ice:nature") }
	if (-not $PSBoundParameters.ContainsKey("Seeds") -and -not $Short) { $Seeds = @("1-8") }
	if (-not $PSBoundParameters.ContainsKey("Limit") -and -not $Short) { $Limit = 600 }
	$Early = "off"
	if ($Extra -notmatch "--stall=") { $Extra = ("$Extra --stall=0").Trim() }
	if ($Title -eq "") { $Title = "Bot Lab validation: sim vs normal" }
}

if (-not (Test-Path $Godot)) { throw "Godot not found: $Godot" }
# The console build only starts the real exe as a child: run the real one (its CPU time is measurable and a timeout
# stops the right process). Its stdout still goes to our log files.
$GuiExe = $Godot -replace "_console\.exe$", ".exe"
if ($GuiExe -ne $Godot -and (Test-Path $GuiExe)) { $Godot = $GuiExe }
if (-not (Test-Path (Join-Path $Dir "project.godot"))) { throw "No Godot project in $Dir" }
$Dir = (Resolve-Path $Dir).Path

if ($Pairs.Count -eq 0) {
	$Pairs = foreach ($p in $Kingdoms) { foreach ($e in $Kingdoms) { "${p}:${e}" } }
}
# "-Pairs a:b,c:d" given as one string also works.
$Pairs = @($Pairs | ForEach-Object { $_ -split "," } | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ -ne "" })
foreach ($p in $Pairs) {
	$k = $p -split ":"
	if ($k.Count -ne 2 -or -not ($Kingdoms -contains $k[0]) -or -not ($Kingdoms -contains $k[1])) { throw "Bad pair '$p' (use fire:ice)" }
}
# Seeds: "1,2,3", "1-6" or (1..6) (a -File call hands them over as one string).
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
if ($OutDir -eq "") {
	$OutDir = Join-Path (Split-Path -Parent $Dir) ("four-wizards-lab-runs\" + (Get-Date -Format "yyyyMMdd-HHmm"))
}
if (-not $DryRun) {
	New-Item -ItemType Directory -Force (Join-Path $OutDir "matches") | Out-Null
	$OutDir = (Resolve-Path $OutDir).Path
}
$Results = Join-Path $OutDir "results.jsonl"

# The scripts: from the project when it has them (res://), else this folder's copy (absolute path).
function Resolve-LabScript([string]$name) {
	if (Test-Path (Join-Path $Dir "tools\bot_lab\$name")) { return "res://tools/bot_lab/$name" }
	return ((Join-Path $Here $name) -replace "\\", "/")
}
$MatchScript = Resolve-LabScript "lab_match.gd"
$ReportScript = Resolve-LabScript "lab_report.gd"

# The commit the lab is on, read from the .git files (git itself is never run).
function Get-Commit([string]$root) {
	try {
		$dotgit = Join-Path $root ".git"
		$gitdir = $dotgit
		if (Test-Path $dotgit -PathType Leaf) {
			$gitdir = ((Get-Content $dotgit -TotalCount 1) -replace "^gitdir:\s*", "").Trim()
			if (-not [IO.Path]::IsPathRooted($gitdir)) { $gitdir = Join-Path $root $gitdir }
		}
		$head = (Get-Content (Join-Path $gitdir "HEAD") -TotalCount 1).Trim()
		if ($head -notmatch "^ref:\s*(.+)$") { return $head.Substring(0, [Math]::Min(10, $head.Length)) }
		$ref = $Matches[1].Trim()
		$common = $gitdir
		$cd = Join-Path $gitdir "commondir"
		if (Test-Path $cd) { $common = Join-Path $gitdir ((Get-Content $cd -TotalCount 1).Trim()) }
		foreach ($base in @($gitdir, $common)) {
			$f = Join-Path $base $ref
			if (Test-Path $f) { $sha = (Get-Content $f -TotalCount 1).Trim(); return "$($ref -replace '^refs/heads/', '')@$($sha.Substring(0, 10))" }
		}
		$packed = Join-Path $common "packed-refs"
		if (Test-Path $packed) {
			$line = Select-String -Path $packed -Pattern (" " + [Regex]::Escape($ref) + "$") | Select-Object -First 1
			if ($line) { return "$($ref -replace '^refs/heads/', '')@$($line.Line.Substring(0, 10))" }
		}
		return $ref
	} catch { return "" }
}
$Commit = Get-Commit $Dir

# First run in a fresh worktree: import once.
if (-not $DryRun -and -not (Test-Path (Join-Path $Dir ".godot\global_script_class_cache.cfg"))) {
	Write-Host "Importing $Dir (first run)..."
	$imp = Start-Process -FilePath $Godot -ArgumentList "--headless --path `"$Dir`" --import" -NoNewWindow -PassThru -Wait `
		-RedirectStandardOutput (Join-Path $OutDir "import.log") -RedirectStandardError (Join-Path $OutDir "import.err")
}

$EarlyArg = if ($Early -eq "on") { "1" } else { "0" }
# Arms: one (the -Sim / -Tick given) or, with -Validate, normal / sim / sim30 over the same pairs x seeds.
$Arms = @(@{ Name = ""; Sim = $Sim; Tick = $Tick })
if ($Validate) {
	$Arms = @(@{ Name = "normal"; Sim = "off"; Tick = 60 }, @{ Name = "sim"; Sim = "on"; Tick = 60 }, @{ Name = "sim30"; Sim = "on"; Tick = 30 })
}
$Jobs = New-Object System.Collections.Queue
# seed -> pair -> arm: the arms of one pair / seed start back to back (same machine load).
foreach ($s in $Seeds) { foreach ($p in $Pairs) { foreach ($arm in $Arms) { $Jobs.Enqueue(@{ Pair = $p; Seed = $s; Arm = $arm }) } } }
$Total = $Jobs.Count

. (Join-Path $Here "lab_eta.ps1")
$Quiet = 0.0; $Busy = 0.0
foreach ($arm in $Arms) {
	$e = Get-LabEta -Games ($Pairs.Count * $Seeds.Count) -Limit $Limit -EarlyOn ($Early -eq "on") -SimOn ($arm.Sim -eq "on") -Tick $arm.Tick -Parallel $Parallel
	$Quiet += $e.QuietMin; $Busy += $e.BusyMin
}
Write-Host ("Bot Lab: {0} matches ({1} pairs x {2} seeds{3}), {4} in parallel, {5} / {6}, limit {7} s, early {8}" -f `
	$Total, $Pairs.Count, $Seeds.Count, $(if ($Validate) { " x 3 arms normal / sim / sim30" } else { ", sim $Sim, tick $Tick" }), `
	$Parallel, $Difficulty, $Style, $Limit, $Early)
Write-Host ("Expected wall time: ~{0} on a quiet PC, up to ~{1} while other agents run Godot (rough model, lab_eta.ps1)." -f `
	(Format-LabMinutes $Quiet), (Format-LabMinutes $Busy))
Write-Host "Dir $Dir ($Commit) -> $OutDir"
if ($DryRun) {
	foreach ($j in $Jobs) { Write-Host ("  {0} seed {1}{2}" -f $j.Pair, $j.Seed, $(if ($j.Arm.Name) { " [$($j.Arm.Name)]" } else { "" })) }
	Write-Host "Dry run: nothing started."
	return
}

# -StopAt "00:45": no match starts after that clock time, running ones are stopped (this runner's own processes)
# and the report covers what finished. A time earlier than now means tomorrow.
$StopTime = $null
if ($StopAt -ne "") {
	$StopTime = [DateTime]::ParseExact($StopAt, "HH:mm", [Globalization.CultureInfo]::InvariantCulture)
	if ($StopTime -le (Get-Date)) { $StopTime = $StopTime.AddDays(1) }
	Write-Host ("Hard stop at {0:yyyy-MM-dd HH:mm}" -f $StopTime)
}
$Stopped = $false
# The machine-wide Godot "traffic light" (tools/godot_run.ps1): each match holds one slot of the named semaphore
# "Local\FourWizardsGodotGate" (FW_GODOT_SLOTS, default 4) and only starts while fewer than FW_GODOT_HARDCAP (default 6)
# Godot processes of any origin run. After FW_GODOT_MAXWAIT s (default 900) of waiting it starts anyway (like the gate).
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
		# Gate: a free slot and room under the hard cap, polled (so -StopAt keeps working while we wait).
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
		$name = ("{0}{1}_s{2}" -f $(if ($j.Arm.Name) { $j.Arm.Name + "_" } else { "" }), ($j.Pair -replace ":", "-"), $j.Seed)
		$json = Join-Path $OutDir "matches\$name.json"
		$log = Join-Path $OutDir "matches\$name.log"
		$err = Join-Path $OutDir "matches\$name.err"
		if (Test-Path $json) { Remove-Item $json }
		$jt = [int]$j.Arm.Tick
		$simArg = if ($j.Arm.Sim -eq "on") { "1" } else { "0" }
		$quitAfter = ($Limit + 240) * $jt + 8000
		$a = "--headless --path `"$Dir`" -s `"$MatchScript`" --fixed-fps $jt --quit-after $quitAfter -- " +
			"--pair=$($j.Pair) --seed=$($j.Seed) --difficulty=$Difficulty --style=$Style --sim=$simArg --limit=$Limit " +
			"--early=$EarlyArg --tick=$jt --commit=$Commit `"--out=$($json -replace '\\', '/')`" $Extra"
		$proc = Start-Process -FilePath $Godot -ArgumentList $a -NoNewWindow -PassThru -RedirectStandardOutput $log -RedirectStandardError $err
		$null = $proc.Handle   # keeps the handle: ExitCode / TotalProcessorTime stay readable after the exit
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
		$armJson = if ($r.Job.Arm.Name) { '"arm":"{0}",' -f $r.Job.Arm.Name } else { "" }
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
		[IO.File]::AppendAllText($Results, $line + "`n", (New-Object Text.UTF8Encoding $false))   # no BOM
		$w = ""
		if ($line -match '"winner":"(\w+)"') { $w = $Matches[1] }
		$why2 = ""
		if ($line -match '"end_reason":"([\w-]+)"') { $why2 = $Matches[1] }
		$when = ""
		if ($line -match '"end_clock":"([\d:]+)"') { $when = $Matches[1] }
		Write-Host ("[{0}/{1}] {2} seed {3}: {4} {5} {6} ({7} s{8})" -f ($Done + $Failed), $Total, `
			$(if ($r.Job.Arm.Name) { "$($r.Job.Arm.Name) $($r.Job.Pair)" } else { $r.Job.Pair }), $r.Job.Seed, `
			$w, $why2, $when, $real, $(if ($scriptErrors -gt 0) { ", $scriptErrors script errors" } else { "" }))
	}
	$Running = $still
}
} finally {
	# Ctrl+C or an error: give the gate slots back (the matches themselves keep running to their own end).
	foreach ($r in $Running) { if ($r.Held) { try { [void]$Gate.Release() } catch {} } }
	$Gate.Dispose()
}
$Wall =[Math]::Round(((Get-Date) - $Start).TotalSeconds, 0)
Write-Host ("Done: {0} ok, {1} failed, wall {2} s, {3:N1} matches per hour" -f $Done, $Failed, $Wall, (3600.0 * $Done / [Math]::Max(1, $Wall)))

if ($Title -eq "") { $Title = "Bot Lab: $($Pairs.Count) pairs x $($Seeds.Count) seeds, $Difficulty, $Style, sim $Sim, tick $Tick" }
$rep = "--headless --path `"$Dir`" -s `"$ReportScript`" --quit-after 600 -- `"--in=$($Results -replace '\\', '/')`" " +
	"`"--out=$($OutDir -replace '\\', '/')`" --wall=$Wall --parallel=$Parallel `"--title=$Title`""
Start-Process -FilePath $Godot -ArgumentList $rep -NoNewWindow -Wait -RedirectStandardOutput (Join-Path $OutDir "report.log") `
	-RedirectStandardError (Join-Path $OutDir "report.err")
if (Test-Path (Join-Path $OutDir "report.md")) {
	Write-Host "Report: $(Join-Path $OutDir 'report.md')  /  $(Join-Path $OutDir 'report.html')"
} else {
	Write-Host "Report failed: see $(Join-Path $OutDir 'report.err')"
}
