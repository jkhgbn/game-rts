# World Forge CLI (tools/world_forge/README.md).
#   tools\world_forge\run_world_forge.ps1 <verb> <id> [key=value...]
# Verbs: help | check <set> | build <set> | sheet <set> (windowed) | map <map> [live=1] | export-map <crown_hollow|res://scene.tscn> | demo
#        fix <map> [rounds=3] | gen <id> archetype= players= tempo= biome= seed= count= full= | template <name|all> | mapsheet <map> (windowed)
# Exit code: 0 PASS / WARN, 1 FAIL, 2 bad input. Goes through tools\godot_run.ps1 (the Godot gate).
param([Parameter(Position = 0)][string]$Verb = "help", [Parameter(Position = 1)][string]$Id = "", [Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest)
$proj = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$gate = Join-Path $proj "tools\godot_run.ps1"
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
