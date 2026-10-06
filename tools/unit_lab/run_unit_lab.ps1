# Unit Lab runner (docs/plan/unit-lab.md): plays the fights of a spec headless through the real game systems, in
# parallel shards (tools/godot_run.ps1 gate), then writes the scorecard (tools/unit_lab/unit_lab_report.gd).
# Usage:
#   powershell -ExecutionPolicy Bypass -File tools\unit_lab\run_unit_lab.ps1 c1_kilnwarden            # a preset
#   ... run_unit_lab.ps1 "6 flame_guard + 1 kilnwarden mana=full vs 7 rimeshield ; dist=20" -Seeds 1-10
#   ... run_unit_lab.ps1 -Equal grave_hound,flame_guard -Budget 720 -Seeds 1-20                      # cost-equal duel
#   ... run_unit_lab.ps1 -Matrix -Kingdoms fire,ice,nature,shadow -Tiers 1,2 -Seeds 1-4               # matrix
#   ... run_unit_lab.ps1 -Matrix -Basis pop [-PopBudget 8]       # equal pop (-Basis both: crystals AND pop budgets)
#   ... run_unit_lab.ps1 c4_gloom_deacon -Variants grave_hound_dps                                    # A/B variants
# Output: docs\balance\unit_lab\<run>\scorecard.md / .json (+ matrix.md / matrix.csv), raw JSONL in
# ..\four-wizards-lab-runs\unit-lab-<run>\ (one file per variant x shard, plus each shard's log).
param(
	[Parameter(Position = 0)][string]$Spec = "",
	[string]$Seeds = "",
	[int]$Parallel = 4,
	[string]$Run = "",
	[string]$Variants = "",
	[switch]$NoBaseline,
	[int]$Tick = 60,
	[double]$Limit = 0,
	[switch]$Matrix,
	[string]$Kingdoms = "fire,ice,nature,shadow",
	[string]$Tiers = "1,2",
	[switch]$NoCasters,
	[int]$Budget = 720,
	[ValidateSet("cost", "pop", "both")][string]$Basis = "cost",
	[int]$PopBudget = 0,
	[string]$Entries = "",
	[string]$Equal = "",
	[string]$Out = "",
	[string]$RawDir = "",
	[int]$TimeoutMin = 300,
	[switch]$Log,
	[switch]$DryRun
)
$ErrorActionPreference = "Stop"
$Repo = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$Gate = Join-Path $Repo "tools\godot_run.ps1"
if ($Run -eq "") { $Run = Get-Date -Format "yyyy-MM-dd_HHmm" }
if ($Out -eq "") { $Out = Join-Path $Repo "docs\balance\unit_lab\$Run" }
if ($RawDir -eq "") { $RawDir = Join-Path (Split-Path $Repo -Parent) "four-wizards-lab-runs\unit-lab-$Run" }
New-Item -ItemType Directory -Force -Path $RawDir | Out-Null
New-Item -ItemType Directory -Force -Path $Out | Out-Null
function Fwd([string]$p) { return ($p -replace '\\', '/') }

# ---- the spec argument the Godot side reads (--spec=)
$SpecArg = ""
if ($Matrix -or $Entries -ne "") {
	$m = @{ budget = $Budget; casters = (-not $NoCasters); basis = $Basis }
	if ($PopBudget -gt 0) { $m.pop_budget = $PopBudget }
	if ($Entries -ne "") { $m.ids = @($Entries.Split(",") | ForEach-Object { $_.Trim() }) }
	else {
		$m.kingdoms = @($Kingdoms.Split(",") | ForEach-Object { $_.Trim() })
		$m.tiers = @($Tiers.Split(",") | ForEach-Object { [int]$_.Trim() })
	}
	$obj = @{ name = "matrix $Run"; matrix = $m; seeds = $(if ($Seeds) { $Seeds } else { "1-4" }) }
	$p = Join-Path $RawDir "spec.json"
	$obj | ConvertTo-Json -Depth 6 | Set-Content -Encoding utf8 $p
	$SpecArg = Fwd $p
} elseif ($Equal -ne "") {
	$ab = $Equal.Split(",")
	$obj = @{ name = "equal $($ab[0]) vs $($ab[1]) @$Budget"; equal = @{ a = $ab[0].Trim(); b = $ab[1].Trim(); budget = $Budget; basis = $Basis; pop_budget = $PopBudget };
		seeds = $(if ($Seeds) { $Seeds } else { "1-20" }) }
	$p = Join-Path $RawDir "spec.json"
	$obj | ConvertTo-Json -Depth 6 | Set-Content -Encoding utf8 $p
	$SpecArg = Fwd $p
} elseif ($Spec -match " vs | ~ ") {
	$p = Join-Path $RawDir "spec.json"
	@{ text = $Spec } | ConvertTo-Json | Set-Content -Encoding utf8 $p
	$SpecArg = Fwd $p
} elseif ($Spec -like "*.json") {
	$SpecArg = Fwd (Resolve-Path $Spec).Path
} elseif ($Spec -ne "") {
	if (-not (Test-Path (Join-Path $Repo "tools\unit_lab\presets\$Spec.json"))) {
		Write-Host "Unknown preset '$Spec'. Presets:"; Get-ChildItem (Join-Path $Repo "tools\unit_lab\presets") -Filter *.json | ForEach-Object { "  " + $_.BaseName }
		exit 2
	}
	$SpecArg = $Spec
} else {
	Write-Host "Give a preset, a .json spec, a text line, -Equal a,b or -Matrix."; exit 2
}

# ---- arms: baseline + variants
$Arms = @()
if (-not $NoBaseline) { $Arms += @{ Name = "baseline"; Path = "baseline" } }
if ($Variants -ne "") {
	foreach ($v in $Variants.Split(",")) {
		$v = $v.Trim()
		$vp = $v
		if (-not (Test-Path $vp)) { $vp = Join-Path $Repo "tools\balance_lab\variants\$v.json" }
		if (-not (Test-Path $vp)) { Write-Host "Unknown variant $v"; exit 2 }
		$Arms += @{ Name = [IO.Path]::GetFileNameWithoutExtension($vp); Path = Fwd (Resolve-Path $vp).Path }
	}
}
$extra = ""
if ($Seeds -ne "" -and -not ($Matrix -or $Equal -ne "")) { $extra += " ++seeds=$Seeds" }
if ($Limit -gt 0) { $extra += " ++limit=$Limit" }
if ($Log) { $extra += " ++log=1" }
Write-Host ("Unit Lab run {0}: spec {1}, {2} arm(s) x {3} shard(s), tick {4}" -f $Run, $SpecArg, $Arms.Count, $Parallel, $Tick)
Write-Host "  raw: $RawDir"
Write-Host "  scorecard: $Out"
if ($DryRun) { exit 0 }

# ---- launch (the gate in godot_run.ps1 holds at most FW_GODOT_SLOTS Godot runs at once)
$procs = @()
$start = Get-Date
foreach ($arm in $Arms) {
	for ($i = 0; $i -lt $Parallel; $i++) {
		$jsonl = Join-Path $RawDir ("{0}_{1}.jsonl" -f $arm.Name, $i)
		if (Test-Path $jsonl) { Remove-Item $jsonl }
		$logf = Join-Path $RawDir ("{0}_{1}.log" -f $arm.Name, $i)
		$errf = Join-Path $RawDir ("{0}_{1}.err" -f $arm.Name, $i)
		# "++" = Godot's user-argument separator (a bare "--" does not survive powershell -File)
		$a = "-NoProfile -ExecutionPolicy Bypass -File `"$Gate`" --headless --path `"$Repo`" -s res://tools/unit_lab/unit_lab_run.gd " +
			"--fixed-fps $Tick --quit-after 90000000 ++ ++spec=$SpecArg ++shard=$i/$Parallel ++out=$(Fwd $jsonl) " +
			"++variant=$($arm.Path) ++tick=$Tick$extra"
		$p = Start-Process -FilePath "powershell" -ArgumentList $a -NoNewWindow -PassThru -RedirectStandardOutput $logf -RedirectStandardError $errf
		$null = $p.Handle
		$procs += @{ Proc = $p; Name = "$($arm.Name)_$i"; Start = Get-Date }
	}
}
while ($true) {
	$alive = @($procs | Where-Object { -not $_.Proc.HasExited })
	if ($alive.Count -eq 0) { break }
	if (((Get-Date) - $start).TotalMinutes -gt $TimeoutMin) {
		Write-Host "Timeout: stopping $($alive.Count) shard(s)"
		foreach ($r in $alive) { try { & taskkill /PID $r.Proc.Id /T /F | Out-Null } catch {} }
		break
	}
	Start-Sleep -Seconds 5
}
$errors = 0
foreach ($r in $procs) {
	$lf = Join-Path $RawDir "$($r.Name).log"
	if (Test-Path $lf) {
		$e = @(Select-String -Path $lf -Pattern "SCRIPT ERROR" -SimpleMatch).Count
		$errors += $e
	}
}
$mins = ((Get-Date) - $start).TotalMinutes
Write-Host ("Fights done in {0:N1} min, {1} SCRIPT ERROR line(s) in the shard logs" -f $mins, $errors)

# ---- report
$ra = "-NoProfile -ExecutionPolicy Bypass -File `"$Gate`" --headless --path `"$Repo`" -s res://tools/unit_lab/unit_lab_report.gd " +
	"--quit-after 60000 ++ ++in=$(Fwd $RawDir) ++spec=$SpecArg ++out=$(Fwd $Out) ++title=$Run"
Start-Process -FilePath "powershell" -ArgumentList $ra -NoNewWindow -Wait -RedirectStandardOutput (Join-Path $RawDir "report.log") `
	-RedirectStandardError (Join-Path $RawDir "report.err")
$card = Join-Path $Out "scorecard.md"
if (Test-Path $card) {
	Write-Host "Scorecard: $card"
	Get-Content $card -TotalCount 40
} else {
	Write-Host "No scorecard (see $RawDir\report.log)"
	exit 1
}
