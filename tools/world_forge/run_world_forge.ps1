# World Forge CLI (tools/world_forge/README.md).
#   tools\world_forge\run_world_forge.ps1 <verb> <id> [key=value...]
# Verbs: help | check <set> | build <set> | sheet <set> (windowed) | map <map> [live=1] | export-map <crown_hollow|res://scene.tscn> | demo
#        fix <map> [rounds=3] | gen <id> archetype= players= tempo= biome= seed= count= full= | template <name|all> | mapsheet <map> (windowed)
#        gate <map> [games= pass= limit= skip=bots,perf fresh=1 dryrun=1] (MT8 acceptance gate, see below)
#        balance <map> [out=<file.json>] (balance score + predicted G5 seat win rates, no bot games: tools\map_lab\balance\run_balance.ps1)
# Exit code: 0 PASS / WARN, 1 FAIL, 2 bad input. Goes through tools\godot_run.ps1 (the Godot gate).
param([Parameter(Position = 0)][string]$Verb = "help", [Parameter(Position = 1)][string]$Id = "", [Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest)
$proj = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$gate = Join-Path $proj "tools\godot_run.ps1"
# MT8: `gate <map> [games=40] [games2=120] [pass=auto|1|2] [limit=1800] [skip=forge,bots,perf] [fresh=1] [resume=1] [dryrun=1]` = the
# map acceptance gate (tools\map_lab\run_map_gate.ps1: World Forge + Map Lab, spacing, symmetry, bot fairness in two
# passes, perf, one PASS / PARTIAL / FAIL scorecard in docs\tools\map_gate\<map>\).
if ($Verb -eq "gate") {
	$ga = @{}
	foreach ($kv in @($Rest)) {
		$k, $v = ([string]$kv).TrimStart("-").Split("=", 2)
		switch ($k.ToLower()) {
			"games" { $ga["Games"] = [int]$v }
			"games2" { $ga["Games2"] = [int]$v }
			"pass" { $ga["Pass"] = $v }
			"limit" { $ga["Limit"] = [int]$v }
			"out" { $ga["OutDir"] = $v }
			"fresh" { $ga["Fresh"] = $true }
			"dryrun" { $ga["DryRun"] = $true }
			"resume" { $ga["Resume"] = $true }
			"skip" { foreach ($s in ($v -split "[, ]+" | Where-Object { $_ })) { $ga["Skip" + (Get-Culture).TextInfo.ToTitleCase($s.Trim().ToLower())] = $true } }
			default { Write-Host "WORLD FORGE gate: unknown option '$kv' (games= games2= pass= limit= out= skip=forge,bots,perf fresh=1 resume=1 dryrun=1)"; exit 2 }
		}
	}
	& (Join-Path $proj "tools\map_lab\run_map_gate.ps1") $Id @ga
	exit $LASTEXITCODE
}
# Balance model (docs\tools\map_gate\balance_model.md): `balance <map>` = internal balance score + predicted G5, seconds.
if ($Verb -eq "balance") {
	& (Join-Path $proj "tools\map_lab\balance\run_balance.ps1") $Id @Rest
	exit $LASTEXITCODE
}
$user = @("verb=$Verb")
if ($Id -ne "") {
	if ($Id -match "=") { $user += $Id } else { $user += "id=$Id" }
}
if ($Rest) { $user += $Rest }
$quit = "8000"
if ($Verb -eq "demo") { $quit = "30000" }
if ($Verb -eq "fix") { $quit = "40000" }
if ($Verb -eq "gen" -or $Verb -eq "template") { $quit = "200000" }
if ($Verb -eq "sheet" -or $Verb -eq "mapsheet") {
	& $gate --path $proj -s res://tools/world_forge/world_forge.gd '--fixed-fps' 60 '--quit-after' 12000 '--' @user
} else {
	& $gate --headless --path $proj -s res://tools/world_forge/world_forge.gd '--fixed-fps' 60 '--quit-after' $quit '--' @user
}
exit $LASTEXITCODE
