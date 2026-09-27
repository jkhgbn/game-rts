# World Forge CLI (tools/world_forge/README.md).
#   tools\world_forge\run_world_forge.ps1 <verb> <id> [key=value...]
# Verbs: help | check <set> | build <set> | sheet <set> (windowed) | map <map> | export-map <crown_hollow|res://scene.tscn> | demo
# Exit code: 0 PASS / WARN, 1 FAIL, 2 bad input. Goes through tools\godot_run.ps1 (the Godot gate).
param([Parameter(Position = 0)][string]$Verb = "help", [Parameter(Position = 1)][string]$Id = "", [Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest)
$proj = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$gate = Join-Path $proj "tools\godot_run.ps1"
$user = @("verb=$Verb")
if ($Id -ne "") {
	if ($Id -match "=") { $user += $Id } else { $user += "id=$Id" }
}
if ($Rest) { $user += $Rest }
$quit = "6000"
if ($Verb -eq "demo") { $quit = "30000" }
if ($Verb -eq "sheet") {
	& $gate --path $proj -s res://tools/world_forge/world_forge.gd '--fixed-fps' 60 '--quit-after' 3000 '--' @user
} else {
	& $gate --headless --path $proj -s res://tools/world_forge/world_forge.gd '--fixed-fps' 60 '--quit-after' $quit '--' @user
}
exit $LASTEXITCODE
