<#
.SYNOPSIS
  Replay Lab scorecard runner (docs/plan/replay-lab.md next step 6): verifies every replay of a folder / a list of
  files / F8 bug-report zips in one command, headless, and writes a PASS / WARN / FAIL scorecard + a history row.

.DESCRIPTION
  Each replay is copied into the run folder (the run keeps what it verified; no spaces in paths), then replayed with
  tools/replay_lab/replay_match.gd --mode=play through the shared Godot gate (tools/godot_run.ps1), -Parallel at a
  time (default 2). A bug zip is unpacked and its replay.replay verified; its info.json (commit, match time) is shown.
  Verdict per replay:
    PASS  every checkpoint + the end hash match (or, for a file cut mid-match such as an F8 bug report, every
          checkpoint up to its last frame: "partial").
    WARN  nothing to compare (0 checkpoints: shorter than hash_every frames), or recorded on another commit and
          diverged (expected: game changes break old replays).
    FAIL  diverged on this commit, no result, timeout, bad file, SCRIPT ERROR.
  Every FAIL / WARN gets a "why / next step" hint (avoidance threads = replay-lab.md step 0, _process gameplay in a
  window recording = step 2, ...).
  Output: <OutDir>\scorecard.md|json + replays\ + logs\, copied to docs\replay\lab\<run>\ ; one row per run in
  docs\replay\lab\history.md (+ history.jsonl). Only the processes this script starts are ever stopped. git is never run.

.EXAMPLE
  .\tools\replay_lab\run_replay.ps1                      (the game's replays folder: %APPDATA%\Godot\app_userdata\Four Wizards RTS\replays)
.EXAMPLE
  .\tools\replay_lab\run_replay.ps1 -Path C:\Users\elzzo\OneDrive\bug_2026-09-27.zip
.EXAMPLE
  .\tools\replay_lab\run_replay.ps1 -Record -RecordMinutes 1     (self-check: record a fresh bot game, then verify it)
#>
param(
	[string[]]$Path = @(),
	[string]$Dir = "",
	[int]$Latest = 0,
	[int]$Parallel = 2,
	[int]$TimeoutMin = 30,
	[string]$Run = "",
	[string]$OutDir = "",
	[switch]$NoHistory,
	[switch]$Record,
	[double]$RecordMinutes = 1,
	[int]$Seed = 3,
	[string]$Pair = "fire:shadow",
	[switch]$DryRun
)

$ErrorActionPreference = "Stop"
[Threading.Thread]::CurrentThread.CurrentCulture = [Globalization.CultureInfo]::InvariantCulture
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$Repo = (Resolve-Path (Join-Path $Here "..\..")).Path
if ($Dir -eq "") { $Dir = $Repo }
$Dir = (Resolve-Path $Dir).Path
$Gate = Join-Path $Repo "tools\godot_run.ps1"
if (-not (Test-Path (Join-Path $Dir "project.godot"))) { throw "No Godot project in $Dir" }
$UserDir = Join-Path $env:APPDATA "Godot\app_userdata\Four Wizards RTS"
if ($Run -eq "") { $Run = Get-Date -Format "yyyy-MM-dd_HHmm" }
if ($OutDir -eq "") { $OutDir = Join-Path (Split-Path -Parent $Repo) ("four-wizards-replay-runs\" + $Run) }
$ReportDir = Join-Path $Repo "docs\replay\lab\$Run"
$Utf8 = New-Object Text.UTF8Encoding $false

# ---------------------------------------------------------------- helpers
function Get-HeadSha([string]$root) {
	try {
		$gitdir = Join-Path $root ".git"
		if (Test-Path $gitdir -PathType Leaf) { $gitdir = ((Get-Content $gitdir -TotalCount 1) -replace "^gitdir:\s*", "").Trim() }
		$head = (Get-Content (Join-Path $gitdir "HEAD") -TotalCount 1).Trim()
		if ($head -notmatch "^ref:\s*(.+)$") { return $head }
		$ref = $Matches[1].Trim()
		$f = Join-Path $gitdir $ref
		if (Test-Path $f) { return (Get-Content $f -TotalCount 1).Trim() }
		$packed = Join-Path $gitdir "packed-refs"
		if (Test-Path $packed) {
			$line = Select-String -Path $packed -Pattern (" " + [Regex]::Escape($ref) + "$") | Select-Object -First 1
			if ($line) { return $line.Line.Substring(0, 40) }
		}
	} catch {}
	return ""
}
$HeadSha = Get-HeadSha $Dir
$Commit12 = if ($HeadSha.Length -ge 12) { $HeadSha.Substring(0, 12) } else { "" }
# replay-lab.md step 0: multi-threaded avoidance is the known drift source until project.godot says otherwise.
$AvoidanceMT = -not (Select-String -Path (Join-Path $Dir "project.godot") -Pattern "avoidance_use_multiple_threads\s*=\s*false" -Quiet)

# Reads a .replay (JSON lines) summary without Godot: header, counts, end.
function Read-ReplayInfo([string]$file) {
	$info = @{ Header = $null; Cmds = 0; Hashes = 0; Bakes = 0; End = $null; LastF = 0; Bad = 0 }
	foreach ($line in [IO.File]::ReadLines($file)) {
		if ($line.Trim() -eq "") { continue }
		try { $d = $line | ConvertFrom-Json } catch { $info.Bad++; continue }
		if ($null -ne $d.f) { $info.LastF = [Math]::Max($info.LastF, [int]$d.f) }
		switch ([string]$d.k) {
			"header" { if ($null -eq $info.Header) { $info.Header = $d } }
			"cmd" { $info.Cmds++ }
			"hash" { $info.Hashes++ }
			"bake" { $info.Bakes++ }
			"end" { $info.End = $d }
		}
	}
	return $info
}
function Format-Clock([double]$frames) { $s = [int]($frames / 60); return ("{0}:{1:D2}" -f [int][Math]::Floor($s / 60), ($s % 60)) }

# ---------------------------------------------------------------- inputs
$Inputs = @()
if ($Path.Count -eq 0 -and -not $Record) { $Path = @(Join-Path $UserDir "replays") }
foreach ($p in ($Path | ForEach-Object { $_ -split "," } | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })) {
	if (-not (Test-Path $p)) {
		if ($p -like "$UserDir*") { throw "No replays yet in $p (the game records only with ReplayHooks.auto_record on, replay-lab.md next step 4; F8 bug zips go to bug_reports\). Try -Record for a self-check." }
		throw "Not found: $p"
	}
	if (Test-Path $p -PathType Container) {
		$Inputs += @(Get-ChildItem $p -File | Where-Object { $_.Extension -in ".replay", ".zip" } | Sort-Object LastWriteTime -Descending)
	} else { $Inputs += @(Get-Item $p) }
}
if ($Latest -gt 0) { $Inputs = @($Inputs | Sort-Object LastWriteTime -Descending | Select-Object -First $Latest) }
if ($Inputs.Count -eq 0 -and -not $Record) { throw "No .replay / .zip found in: $($Path -join ', ') (record with ReplayHooks.auto_record, F8, or -Record)" }

Write-Host ("Replay Lab: {0} input(s){1}, {2} at a time, project {3} ({4}){5}" -f $Inputs.Count,
	$(if ($Record) { " + 1 fresh bot recording ($Pair, seed $Seed, $RecordMinutes min)" } else { "" }), $Parallel, $Dir,
	$(if ($Commit12) { $Commit12 } else { "no commit" }), $(if ($AvoidanceMT) { "; avoidance multi-threaded (replay-lab.md step 0 not done: expect pos drift)" } else { "" }))
if ($DryRun) {
	foreach ($i in $Inputs) { Write-Host ("  {0}  ({1:yyyy-MM-dd HH:mm}, {2:N0} KB)" -f $i.FullName, $i.LastWriteTime, ($i.Length / 1KB)) }
	Write-Host "Dry run: nothing started."
	return
}
foreach ($sub in "replays", "logs", "results", "unzipped") { New-Item -ItemType Directory -Force (Join-Path $OutDir $sub) | Out-Null }
$OutDir = (Resolve-Path $OutDir).Path
$Start = Get-Date

# Runs the gate with the replay runner; returns the process (powershell -> godot_run.ps1 -> Godot).
function Start-ReplayRun([string[]]$userArgs, [string]$name, [int]$quitAfter) {
	$a = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$Gate`"", "--headless", "--path", "`"$Dir`"", "-s",
		"res://tools/replay_lab/replay_match.gd", "--fixed-fps", "60", "--quit-after", "$quitAfter", "++") + $userArgs
	$log = Join-Path $OutDir "logs\$name.log"
	$err = Join-Path $OutDir "logs\$name.err"
	$p = Start-Process -FilePath "powershell.exe" -ArgumentList ($a -join " ") -NoNewWindow -PassThru -RedirectStandardOutput $log -RedirectStandardError $err
	$null = $p.Handle
	return $p
}
function Stop-Tree([int]$id) { & taskkill.exe /PID $id /T /F 2>$null | Out-Null }   # our own process tree only

# ---------------------------------------------------------------- optional fresh recording
$Items = @()
if ($Record) {
	$rec = (Join-Path $OutDir "replays\recorded_bots_s$Seed.replay") -replace "\\", "/"
	$res = (Join-Path $OutDir "results\recorded_bots_s$Seed.rec.json") -replace "\\", "/"
	Write-Host "Recording a bot game ($Pair, seed $Seed, $RecordMinutes min, sim)..."
	$p = Start-ReplayRun @("--mode=bots", "--seed=$Seed", "--minutes=$RecordMinutes", "--pair=$Pair", "--sim=1", "`"--out=$rec`"", "`"--result=$res`"") "record_bots_s$Seed" ([int](($RecordMinutes * 60 + 120) * 60 + 20000))
	if (-not $p.WaitForExit($TimeoutMin * 60000)) { Stop-Tree $p.Id }
	if (Test-Path $rec) { $Items += @{ Name = "recorded_bots_s$Seed"; Source = "fresh recording (-Record)"; File = $rec; Info = $null } }
	else { Write-Host "Recording failed: see $(Join-Path $OutDir "logs\record_bots_s$Seed.log")" }
}

# ---------------------------------------------------------------- collect the replays (copies, zips unpacked)
foreach ($i in $Inputs) {
	$base = ($i.BaseName -replace "[^\w\-]", "_")
	if ($i.Extension -eq ".zip") {
		$to = Join-Path $OutDir "unzipped\$base"
		try { Expand-Archive -Path $i.FullName -DestinationPath $to -Force } catch { $Items += @{ Name = $base; Source = $i.FullName; File = ""; Error = "zip unreadable: $_" }; continue }
		$rp = Get-ChildItem $to -Recurse -Filter "*.replay" | Select-Object -First 1
		$bi = $null
		$ij = Get-ChildItem $to -Recurse -Filter "info.json" | Select-Object -First 1
		if ($ij) { try { $bi = Get-Content $ij.FullName -Raw | ConvertFrom-Json } catch {} }
		if (-not $rp) { $Items += @{ Name = $base; Source = $i.FullName; File = ""; Error = "no .replay in the zip"; Bug = $bi }; continue }
		$dst = Join-Path $OutDir "replays\$base.replay"
		Copy-Item $rp.FullName $dst -Force
		$Items += @{ Name = $base; Source = $i.FullName; File = $dst; Bug = $bi }
	} else {
		$dst = Join-Path $OutDir "replays\$base.replay"
		Copy-Item $i.FullName $dst -Force
		$Items += @{ Name = $base; Source = $i.FullName; File = $dst }
	}
}

# ---------------------------------------------------------------- verify
$Queue = New-Object System.Collections.Queue
foreach ($it in $Items) {
	if ($it.File -eq "") { continue }
	$it.Info = Read-ReplayInfo $it.File
	if ($null -eq $it.Info.Header) { $it.Error = "no header line (not a replay, or an empty file)"; continue }
	$Queue.Enqueue($it)
}
$Running = @()
while ($Queue.Count -gt 0 -or $Running.Count -gt 0) {
	while ($Running.Count -lt $Parallel -and $Queue.Count -gt 0) {
		$it = $Queue.Dequeue()
		$it.Result = (Join-Path $OutDir "results\$($it.Name).json")
		if (Test-Path $it.Result) { Remove-Item $it.Result }
		$quit = [int]($it.Info.LastF * 1.1 + 30000)   # frames: the match + start-up margin
		$it.Proc = Start-ReplayRun @("--mode=play", "`"--file=$($it.File -replace '\\', '/')`"", "`"--result=$($it.Result -replace '\\', '/')`"") $it.Name $quit
		$it.Started = Get-Date
		$Running += $it
		Write-Host ("  started {0} ({1} frames = {2}, {3} checkpoints, {4} commands)" -f $it.Name, $it.Info.LastF, (Format-Clock $it.Info.LastF), $it.Info.Hashes, $it.Info.Cmds)
	}
	Start-Sleep -Milliseconds 1000
	$still = @()
	foreach ($it in $Running) {
		$late = ((Get-Date) - $it.Started).TotalMinutes -gt $TimeoutMin
		if (-not $it.Proc.HasExited -and -not $late) { $still += $it; continue }
		if (-not $it.Proc.HasExited) { Stop-Tree $it.Proc.Id; $it.Error = "timeout after $TimeoutMin min" }
		$it.RealS = [Math]::Round(((Get-Date) - $it.Started).TotalSeconds, 0)
		if (Test-Path $it.Result) { try { $it.R = Get-Content $it.Result -Raw | ConvertFrom-Json } catch { $it.Error = "unreadable result file" } }
		elseif (-not $it.Error) { $it.Error = "no result (exit code $($it.Proc.ExitCode))" }
		$it.ScriptErrors = 0
		foreach ($f in @((Join-Path $OutDir "logs\$($it.Name).log"), (Join-Path $OutDir "logs\$($it.Name).err"))) {
			if (Test-Path $f) { $it.ScriptErrors += @(Select-String -Path $f -Pattern "SCRIPT ERROR" -SimpleMatch).Count }
		}
		Write-Host ("  done {0}: {1} ({2} s)" -f $it.Name, $(if ($it.R) { "ok=$($it.R.ok) checks $($it.R.checks_ok)/$($it.R.checks)" } else { $it.Error }), $it.RealS)
	}
	$Running = $still
}

# ---------------------------------------------------------------- verdicts + hints
$Rows = @()
foreach ($it in $Items) {
	$h = if ($it.Info) { $it.Info.Header } else { $null }
	$game = if ($h) { [string]$h.game } else { "" }
	$sameCommit = ($Commit12 -ne "" -and $game -eq $Commit12)
	$status = "FAIL"; $what = ""; $hint = ""
	$r = $it.R
	if ($it.Error) {
		$what = $it.Error
		$hint = if ($it.Error -like "timeout*") { "Raise -TimeoutMin, or check the log: a replay that never reaches its end frame waits for --quit-after." } `
			elseif ($it.Error -like "no result*") { "Read logs\$($it.Name).log / .err (a parse error in the runner or the game stops the replay before its result)." } `
			else { "The file is not a Replay Lab recording (replay-lab.md 'File format')." }
	} elseif ([bool]$r.ok -or [bool]$r.partial_ok) {
		$status = "PASS"
		$what = if ([bool]$r.partial) { "partial file: {0}/{1} checkpoints up to {2} (no end hash: cut mid-match)" -f $r.checks_ok, $r.checks, (Format-Clock $it.Info.LastF) } `
			else { "{0}/{1} checkpoints + end hash at {2}" -f $r.checks_ok, $r.checks, (Format-Clock ([double]$r.frame)) }
		if ([int]$r.checks -eq 0) { $status = "WARN"; $what += " - nothing to compare"; $hint = "Shorter than one checkpoint ($($h.hash_every) frames): record longer, or with --hash-every=60." }
	} else {
		$dv = $r.divergence
		$df = if ($dv -and $null -ne $dv.f) { [int]$dv.f } else { -1 }
		$diffs = if ($dv -and $dv.diff) { @($dv.diff) } else { @() }
		$what = "{0}/{1} checkpoints{2}; diverged at {3} (frame {4}): {5}" -f $r.checks_ok, $r.checks,
			$(if ([bool]$r.end_match) { " + end" } elseif ([bool]$r.partial) { " (partial file)" } else { "" }),
			$(if ($df -ge 0) { Format-Clock $df } else { "?" }), $df, (($diffs | ForEach-Object { ($_ -split ":")[0] }) -join ", ")
		$onlyPos = $diffs.Count -gt 0 -and @($diffs | Where-Object { $_ -notmatch "^(pos|t):" }).Count -eq 0
		$hints = @()
		if (-not $sameCommit -and $game -ne "") {
			$status = "WARN"
			$hints += "Recorded on $game, replayed on $(if ($Commit12) { $Commit12 } else { 'this tree' }) (+ uncommitted work): game changes since then break old replays. Replay it on its own commit (lab worktree) to check."
		}
		if ($onlyPos -and $AvoidanceMT) { $hints += "Only unit positions drift: multi-threaded avoidance (replay-lab.md step 0: project.godot avoidance_use_multiple_threads=false, lead)." }
		if ([string]$h.bake -eq "thread") { $hints += "A real-game recording (thread bakes): _process gameplay and idle timers drift in a window (replay-lab.md step 2: owners move them to _physics_process)." }
		if ($diffs | Where-Object { $_ -match "^(ess|gold|cry|gath):" }) { $hints += "Economy numbers differ: look for gameplay in _process (essence trickle) or an unrecorded UI command (replay-lab.md 'Not recorded yet')." }
		if ($hints.Count -eq 0) { $hints += "Record the same seed twice with --dump=<frame just before $df> and diff the DUMP lines to find the unit that drifts (replay-lab.md 'How to use')." }
		$hint = $hints -join " "
	}
	if ($it.ScriptErrors -gt 0) { $status = "FAIL"; $hint = "$($it.ScriptErrors) SCRIPT ERROR line(s) in logs\$($it.Name).log. " + $hint }
	$bug = ""
	if ($it.Bug) { $bug = ("bug report: commit {0}, match {1}" -f $it.Bug.commit, $it.Bug.match_time) }
	$Rows += [ordered]@{
		name = $it.Name; source = $it.Source; status = $status; what = $what; hint = $hint; bug = $bug
		mode = $(if ($h) { [string]$h.mode } else { "" }); seed = $(if ($h) { $h.seed } else { $null }); game = $game; same_commit = $sameCommit
		bake = $(if ($h) { [string]$h.bake } else { "" }); sim = $(if ($h -and $h.setup) { [bool]$h.setup.sim } else { $false })
		pair = $(if ($h -and $h.setup) { "$($h.setup.player_kingdom):$($h.setup.enemy_kingdom)" } else { "" })
		frames = $(if ($it.Info) { $it.Info.LastF } else { 0 }); commands = $(if ($it.Info) { $it.Info.Cmds } else { 0 })
		checks = $(if ($r) { [int]$r.checks } else { 0 }); checks_ok = $(if ($r) { [int]$r.checks_ok } else { 0 })
		end_match = $(if ($r) { [bool]$r.end_match } else { $false }); partial = $(if ($r) { [bool]$r.partial } else { $false })
		divergence_frame = $(if ($r -and $r.divergence -and $null -ne $r.divergence.f) { [int]$r.divergence.f } else { -1 })
		real_s = $it.RealS; script_errors = $it.ScriptErrors
	}
}

$n = $Rows.Count
$pass = @($Rows | Where-Object { $_.status -eq "PASS" }).Count
$warn = @($Rows | Where-Object { $_.status -eq "WARN" }).Count
$fail = @($Rows | Where-Object { $_.status -eq "FAIL" }).Count
$Result = if ($n -eq 0) { "FAIL" } elseif ($fail -gt 0) { "FAIL" } elseif ($warn -gt 0) { "WARN" } else { "PASS" }
$Score = if ($n -gt 0) { [int][Math]::Round(100.0 * ($pass + 0.5 * $warn) / $n) } else { 0 }
$Wall = [int]((Get-Date) - $Start).TotalSeconds
$When = Get-Date -Format "yyyy-MM-dd HH:mm"

# ---------------------------------------------------------------- scorecard
$md = New-Object Collections.Generic.List[string]
$md.Add("# Replay Lab scorecard: $Run")
$md.Add("")
$md.Add("**$Result, score $Score / 100**: $n replay(s), $pass PASS, $warn WARN, $fail FAIL. $When, project commit ``$(if ($Commit12) { $Commit12 } else { '?' })`` (+ uncommitted work), wall $Wall s.")
$md.Add("")
if ($AvoidanceMT) {
	$md.Add("> Avoidance runs on several threads (``project.godot`` has no ``avoidance_use_multiple_threads=false``, replay-lab.md step 0): replays are expected to drift on unit positions after 10-20 s. That FAIL is the determinism signal, not a broken lab.")
	$md.Add("")
}
$md.Add("PASS = every checkpoint + the end hash (a file cut mid-match: every checkpoint). WARN = nothing to compare, or recorded on another commit. FAIL = diverged on this commit, no result, SCRIPT ERROR.")
$md.Add("")
$md.Add("| Replay | Status | Mode | Pair / seed | Length | Cmds | Result | Recorded on |")
$md.Add("|---|---|---|---|---|---|---|---|")
foreach ($row in $Rows) {
	$md.Add(("| {0} | **{1}** | {2}{3} | {4} s{5} | {6} | {7} | {8} | {9}{10} |" -f $row.name, $row.status, $row.mode,
		$(if ($row.bake -eq "thread") { " (real game)" } elseif ($row.sim) { " (sim)" } else { "" }), $row.pair, $row.seed,
		(Format-Clock $row.frames), $row.commands, ($row.what -replace "\|", "/"), $row.game, $(if ($row.same_commit) { " (this)" } else { "" })))
}
$md.Add("")
$tips = @($Rows | Where-Object { $_.hint -ne "" })
$md.Add("## Next steps")
$md.Add("")
if ($tips.Count -eq 0) { $md.Add("Nothing to do: every replay matches.") }
foreach ($row in $tips) { $md.Add("- **$($row.name)** ($($row.status)): $($row.hint)$(if ($row.bug) { " ($($row.bug))" })") }
$md.Add("")
$md.Add("Watch one: ``& tools\godot_run.ps1 --path . -s tools/replay_lab/replay_match.gd --fixed-fps 60 ++ --mode=watch --file=<replay>`` (the timeline bar marks the diverged checkpoints in red; click it to seek). Raw run: ``$OutDir``.")
$mdText = ($md -join "`n") + "`n"
$card = [ordered]@{ run = $Run; date = $When; result = $Result; score = $Score; replays = $n; pass = $pass; warn = $warn; fail = $fail
	commit = $Commit12; avoidance_multithreaded = $AvoidanceMT; wall_s = $Wall; out_dir = $OutDir; rows = $Rows }
$json = $card | ConvertTo-Json -Depth 6
[IO.File]::WriteAllText((Join-Path $OutDir "scorecard.md"), $mdText, $Utf8)
[IO.File]::WriteAllText((Join-Path $OutDir "scorecard.json"), $json, $Utf8)
New-Item -ItemType Directory -Force $ReportDir | Out-Null
[IO.File]::WriteAllText((Join-Path $ReportDir "scorecard.md"), $mdText, $Utf8)
[IO.File]::WriteAllText((Join-Path $ReportDir "scorecard.json"), $json, $Utf8)

if (-not $NoHistory) {
	$hist = Join-Path $Repo "docs\replay\lab\history.md"
	if (-not (Test-Path $hist)) {
		[IO.File]::WriteAllText($hist, "# Replay Lab history`n`nOne row per ``tools/replay_lab/run_replay.ps1`` run (docs/plan/replay-lab.md). Score = % PASS (WARN counts half).`n`n| Run | Date | Commit | Result | Score | Replays (P / W / F) | Avoidance MT | Scorecard |`n|---|---|---|---|---|---|---|---|`n", $Utf8)
	}
	[IO.File]::AppendAllText($hist, ("| {0} | {1} | {2} | {3} | {4} | {5} ({6} / {7} / {8}) | {9} | [{0}/scorecard.md]({0}/scorecard.md) |`n" -f $Run, $When,
		$(if ($Commit12) { $Commit12 } else { "?" }), $Result, $Score, $n, $pass, $warn, $fail, $(if ($AvoidanceMT) { "yes" } else { "no" })), $Utf8)
	$hj = [ordered]@{ run = $Run; date = $When; commit = $Commit12; result = $Result; score = $Score; replays = $n; pass = $pass; warn = $warn; fail = $fail; avoidance_multithreaded = $AvoidanceMT }
	[IO.File]::AppendAllText((Join-Path $Repo "docs\replay\lab\history.jsonl"), (($hj | ConvertTo-Json -Compress) + "`n"), $Utf8)
}
Write-Host ("REPLAY LAB {0} score {1}: {2} replay(s), {3} PASS, {4} WARN, {5} FAIL -> {6}" -f $Result, $Score, $n, $pass, $warn, $fail, (Join-Path $ReportDir "scorecard.md"))
