<#
.SYNOPSIS
  MAP GATE (docs/design/map-production.md 4.3 + 9, tool task MT8): one command per map runs the acceptance gates and
  prints PASS / PARTIAL / FAIL with the scorecard.

.DESCRIPTION
  tools\map_lab\run_map_gate.ps1 <map> [options]   (also: tools\world_forge\run_world_forge.ps1 gate <map> [options])
  Steps (every Godot run goes through the Godot gate: tools\godot_run.ps1, or the Bot Lab's own use of its semaphore):
   1. World Forge `map <map>` (layout, spacing L3, R5, the Map Lab: score, symmetry / fairness checks). Skipped when the
      last report was made from the current .map text (`-Fresh` forces the run).
   2. Bot fairness, two passes (section 9): pass 1 = 40 games over easy / normal / hard x the 4 kingdom mirrors (sim
      mode, the map's layout; a mirror's two seats are the two sides). When a difficulty's seat win rate is within
      3 points of the 45 / 55 % edge or a cell looks lopsided, pass 2 tops it up to 120 games (10 per cell).
      -Seats alternate (default on layout maps): even seeds swap the teams' seats (lab --swap-sides, results in
      bots\<d>_swap) and G5 counts SEAT wins, so a bot-side (team) effect cancels; -Seats fixed = the old order.
   3. Performance: tests/test_mt2_perf.gd on the map (PASS mt2_perf = frame time within live Crown Hollow's).
   4. Verdict: tools/map_lab/map_gate.gd reads all of it and writes docs/tools/map_gate/<map>/scorecard.md (+ .json).
  Exit code: 0 PASS or PARTIAL (a step skipped, nothing failed), 1 FAIL, 2 bad input.
  Wall time: the forge ~2-20 min (skipped when fresh), pass 1 ~20-40 min at 4 parallel matches, pass 2 another
  ~60-90 min, perf ~2 min. -DryRun prints the plan.

.EXAMPLE
  tools\map_lab\run_map_gate.ps1 thornwater
.EXAMPLE
  tools\map_lab\run_map_gate.ps1 quartermeet -SkipBots          (forge + perf only: PARTIAL at best)
.EXAMPLE
  tools\map_lab\run_map_gate.ps1 crown_hollow -Pass 2           (the full 120-game matrix at once)
.EXAMPLE
  tools\map_lab\run_map_gate.ps1 thornwater -Games 12 -Limit 600 (a quick smoke of the pipeline: not a verdict)
.EXAMPLE
  tools\map_lab\run_map_gate.ps1 thornwater -Resume              (a stopped gate: keeps each difficulty's results.jsonl
                                                                 and plays only the seeds whose 4 mirrors are missing;
                                                                 only valid while the map and the bot code are unchanged)
#>
param(
	[Parameter(Position = 0)][string]$Map = "",
	[int]$Games = 40,
	[int]$Games2 = 120,
	[ValidateSet("auto", "1", "2")][string]$Pass = "auto",
	[int]$Limit = 1800,
	[switch]$Fresh,
	[switch]$SkipForge,
	[switch]$SkipBots,
	[switch]$SkipPerf,
	[switch]$Resume,
	[ValidateSet("alternate", "fixed")][string]$Seats = "alternate",
	[string]$OutDir = "",
	[switch]$DryRun
)
$ErrorActionPreference = "Continue"   # Godot writes warnings to stderr: never a terminating error here
$Repo = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$Gate = Join-Path $Repo "tools\godot_run.ps1"
$Forge = Join-Path $Repo "tools\world_forge\run_world_forge.ps1"
$Lab = Join-Path $Repo "tools\bot_lab\run_lab.ps1"
if ($Map -eq "") { Write-Host "MAP GATE: give a map id (run_map_gate.ps1 thornwater)"; exit 2 }
$Map = $Map.Trim().ToLower()
$ForgeId = if ($Map -eq "crown_hollow") { "crown_hollow_level" } else { $Map }
if (-not (Test-Path (Join-Path $Repo "data\maps\$ForgeId.map"))) { Write-Host "MAP GATE: no data\maps\$ForgeId.map"; exit 2 }
$Layout = if ($Map -eq "crown_hollow") { "" } else { "res://data/maps/${Map}_layout.tres" }
if ($Layout -ne "" -and -not (Test-Path (Join-Path $Repo "data\maps\${Map}_layout.tres")) -and $SkipForge) {
	Write-Host "MAP GATE: no data\maps\${Map}_layout.tres (run without -SkipForge)"; exit 2
}
if ($OutDir -eq "") { $OutDir = Join-Path $Repo "docs\tools\map_gate\$Map" }
$Mirrors = "fire:fire,shadow:shadow,ice:ice,nature:nature"
$Diffs = @("easy", "normal", "hard")

# Seeds per difficulty for N games over 3 difficulties x 4 mirrors: 40 -> easy 3, normal 4, hard 3 (= 12 + 16 + 12).
function Get-SeedPlan([int]$n) {
	$cells = [Math]::Max(3, [Math]::Round($n / 4.0))
	$base = [Math]::Floor($cells / 3); $rem = $cells - 3 * $base
	$plan = @{ easy = $base; normal = $base; hard = $base }
	if ($rem -ge 1) { $plan.normal += 1 }
	if ($rem -ge 2) { $plan.hard += 1 }
	return $plan
}
$Plan1 = Get-SeedPlan $Games
$Plan2 = Get-SeedPlan $Games2
$Extra = if ($Layout -ne "") { "--layout=$Layout" } else { "" }

Write-Host ("MAP GATE {0}: forge id {1}, layout {2}" -f $Map, $ForgeId, $(if ($Layout) { $Layout } else { "scenes/skirmish.tscn (Crown Hollow)" }))
Write-Host ("  bots pass 1: {0} games (easy {1}, normal {2}, hard {3} seeds x 4 mirrors), pass 2 up to {4}, limit {5} s, pass {6}" -f `
	$Games, $Plan1.easy, $Plan1.normal, $Plan1.hard, $Games2, $Limit, $Pass)
Write-Host "  out: $OutDir"
if ($DryRun) { Write-Host "Dry run: nothing started."; exit 0 }
New-Item -ItemType Directory -Force $OutDir | Out-Null
$Start = Get-Date
$Skips = @()

function Invoke-GateGodot([string[]]$GodotArgs, [string]$Log) {
	& $Gate @GodotArgs *> $Log
	return $LASTEXITCODE
}

# 1. World Forge map (+ Map Lab), unless the last report is fresh
if ($SkipForge) {
	$Skips += "forge"
	Write-Host "[1/4] World Forge: skipped (-SkipForge); the verdict reads the last report"
} else {
	$freshCode = 3
	if (-not $Fresh) {
		$freshCode = Invoke-GateGodot @("--headless", "--path", $Repo, "-s", "res://tools/map_lab/map_gate.gd", "--quit-after", "4000", "--", "id=$Map", "step=fresh") (Join-Path $OutDir "fresh.log")
		Get-Content (Join-Path $OutDir "fresh.log") | Select-String "MAP GATE fresh" | ForEach-Object { Write-Host ("[1/4] " + $_.Line) }
	}
	if ($freshCode -ne 0) {
		Write-Host "[1/4] World Forge map $ForgeId (layout + Map Lab; minutes)..."
		& $Forge map $ForgeId *> (Join-Path $OutDir "forge.log")
		$fc = $LASTEXITCODE
		Get-Content (Join-Path $OutDir "forge.log") | Select-String "WORLD FORGE map|MAP LAB:" | Select-Object -Last 3 | ForEach-Object { Write-Host ("      " + $_.Line.Trim()) }
		if ($fc -eq 2) { Write-Host "MAP GATE: World Forge refused the .map (see $OutDir\forge.log)"; exit 2 }
	}
}

# 2. Bot fairness (Bot Lab, sim mode; run_lab.ps1 holds the Godot gate's semaphore per match)
# -Seats alternate (default on a layout map): odd seeds play as laid out (the PLAYER team on the side-0 seat) into
# bots\<d>, even seeds with --swap-sides (the PLAYER team on the side-1 seat) into bots\<d>_swap. G5 counts seat wins
# (`winner_seat`), so a bot effect that favours one TEAM (not one seat) cancels out instead of failing the map.
$BotDirs = @()
function Get-BotDirs([string]$d) {
	$out = @(@{ dir = (Join-Path $OutDir "bots\$d"); swap = $false; log = "bots_$d.log" })
	if ($Seats -eq "alternate" -and $Layout -ne "") { $out += @{ dir = (Join-Path $OutDir "bots\${d}_swap"); swap = $true; log = "bots_${d}_swap.log" } }
	return $out
}
function Invoke-BotPass($plan, [int]$from, [string]$label) {
	foreach ($d in $Diffs) {
		$to = [int]$plan[$d]
		if ($to -lt $from) { continue }
		foreach ($bd in (Get-BotDirs $d)) {
			$dir = $bd.dir
			$seedList = @($from..$to)
			if ($Seats -eq "alternate" -and $Layout -ne "") { $seedList = @($seedList | Where-Object { ($_ % 2 -eq 0) -eq $bd.swap }) }
			if ($seedList.Count -eq 0) { continue }
			$tag = if ($bd.swap) { "$d, seats swapped" } else { $d }
			if ($Resume) {   # skip the seeds whose 4 mirrors already have a result line (a stopped gate goes on)
				$rj = Join-Path $dir "results.jsonl"
				$have = @{}
				if (Test-Path $rj) {
					foreach ($line in Get-Content $rj) {
						try { $r = $line | ConvertFrom-Json; $k = [int]$r.seed; $have[$k] = 1 + $(if ($have.ContainsKey($k)) { $have[$k] } else { 0 }) } catch {}
					}
				}
				$seedList = @($seedList | Where-Object { -not $have.ContainsKey($_) -or $have[$_] -lt 4 })
				if ($seedList.Count -eq 0) { Write-Host ("[2/4] Bot Lab {0}: {1}, seeds {2}-{3} already played (-Resume)" -f $label, $tag, $from, $to); continue }
			}
			$seedArg = ($seedList | ForEach-Object { "$_" }) -join ","
			Write-Host ("[2/4] Bot Lab {0}: {1}, seeds {2} x 4 mirrors" -f $label, $tag, $seedArg)
			$a = @{ Dir = $Repo; Pairs = @($Mirrors); Seeds = @($seedArg); Difficulty = $d; Sim = "on"; Limit = $Limit; OutDir = $dir;
				Title = "Map gate $Map ($tag)"; TimeoutMin = 110 }
			$ex = $Extra
			if ($bd.swap) { $ex = "$ex --swap-sides=1".Trim() }
			if ($ex -ne "") { $a["Extra"] = $ex }
			& $Lab @a *> (Join-Path $OutDir $bd.log)
			# -Resume replays a whole seed when one of its mirrors is missing: keep one line per (pair, seed), the newest
			$rjd = Join-Path $dir "results.jsonl"
			if (Test-Path $rjd) {
				$byKey = [ordered]@{}
				foreach ($line in Get-Content $rjd) {
					if ($line.Trim() -eq "") { continue }
					try { $r = $line | ConvertFrom-Json; $key = "$($r.pair)|$($r.seed)" } catch { $key = "raw|" + $byKey.Count }
					if ($byKey.Contains($key)) { $byKey.Remove($key) }
					$byKey[$key] = $line
				}
				[System.IO.File]::WriteAllLines($rjd, [string[]]@($byKey.Values), (New-Object System.Text.UTF8Encoding $false))
			}
			Get-Content (Join-Path $OutDir $bd.log) | Select-String "^Done:" | ForEach-Object { Write-Host ("      " + $_.Line) }
		}
	}
}
if ($SkipBots) {
	$Skips += "bots"
	Write-Host "[2/4] Bot fairness: skipped (-SkipBots)"
} else {
	foreach ($d in $Diffs) {
		foreach ($bd in (Get-BotDirs $d)) {
			$dir = $bd.dir
			if (-not $Resume -and (Test-Path (Join-Path $dir "results.jsonl"))) { Remove-Item (Join-Path $dir "results.jsonl") }   # a new gate run starts clean
			$BotDirs += $dir
		}
	}
	if ($Pass -eq "2") {
		Invoke-BotPass $Plan2 1 "pass 2 (120)"
	} else {
		Invoke-BotPass $Plan1 1 "pass 1 ($Games)"
		if ($Pass -eq "auto") {
			$probe = Join-Path $OutDir "probe"
			$botsArg = ($BotDirs | ForEach-Object { $_ -replace "\\", "/" }) -join ";"
			$null = Invoke-GateGodot @("--headless", "--path", $Repo, "-s", "res://tools/map_lab/map_gate.gd", "--quit-after", "4000", "--",
				"id=$Map", "step=verdict", "bots=$botsArg", "skip=perf", "out=$($probe -replace '\\', '/')") (Join-Path $OutDir "probe.log")
			$pj = Join-Path $probe "scorecard.json"
			if ((Test-Path $pj) -and ((Get-Content $pj -Raw | ConvertFrom-Json).second_pass)) {
				Write-Host "[2/4] Close to the 45-55 % edge: pass 2 tops it up to $Games2 games"
				$next = @{ easy = $Plan1.easy + 1; normal = $Plan1.normal + 1; hard = $Plan1.hard + 1 }
				foreach ($d in $Diffs) {
					if ($Plan2[$d] -ge $next[$d]) {
						$p2 = @{ easy = 0; normal = 0; hard = 0 }; $p2[$d] = $Plan2[$d]
						Invoke-BotPass $p2 $next[$d] "pass 2 ($Games2)"
					}
				}
			} else {
				Write-Host "[2/4] Pass 1 is clear of the edge: no 120-game pass"
			}
		}
	}
}

# 3. Performance (the MT2 perf gate on this map)
$PerfLog = Join-Path $OutDir "perf.log"
if ($SkipPerf) {
	$Skips += "perf"
	Write-Host "[3/4] Performance: skipped (-SkipPerf)"
} else {
	Write-Host "[3/4] Performance: tests/test_mt2_perf.gd"
	$pa = @("--headless", "--path", $Repo, "-s", "tests/test_mt2_perf.gd", "--fixed-fps", "60", "--quit-after", "12000")
	if ($Layout -ne "") { $pa += @("--", "map=$Layout") }
	$null = Invoke-GateGodot $pa $PerfLog
	Get-Content $PerfLog | Select-String "mt2_perf" | Select-Object -Last 1 | ForEach-Object { Write-Host ("      " + $_.Line.Trim()) }
}

# 4. Verdict
$va = @("--headless", "--path", $Repo, "-s", "res://tools/map_lab/map_gate.gd", "--quit-after", "4000", "--", "id=$Map", "step=verdict",
	"out=$($OutDir -replace '\\', '/')")
if ($BotDirs.Count -gt 0) { $va += "bots=" + (($BotDirs | ForEach-Object { $_ -replace "\\", "/" }) -join ";") }
if (-not $SkipPerf) { $va += "perf=$($PerfLog -replace '\\', '/')" }
$sk = @($Skips | Where-Object { $_ -ne "forge" })
if ($sk.Count -gt 0) { $va += "skip=" + ($sk -join ",") }
$code = Invoke-GateGodot $va (Join-Path $OutDir "verdict.log")
$md = Join-Path $OutDir "scorecard.md"
if (Test-Path $md) { Get-Content $md | ForEach-Object { Write-Host $_ } }
Get-Content (Join-Path $OutDir "verdict.log") | Select-String "^MAP GATE " | ForEach-Object { Write-Host $_.Line }
Write-Host ("MAP GATE {0}: done in {1:N0} min" -f $Map, ((Get-Date) - $Start).TotalMinutes)
if ($code -ne 0 -and $code -ne 1) { $code = 1 }
exit $code
