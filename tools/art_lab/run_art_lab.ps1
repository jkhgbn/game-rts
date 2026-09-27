# Art Lab wrapper for the lead (docs/plan/art-lab.md). Runs the lab windowed through the Godot gate (tools/godot_run.ps1).
# Usage:
#   .\tools\art_lab\run_art_lab.ps1 sapling unit nature                  # one asset (short names work)
#   .\tools\art_lab\run_art_lab.ps1 -Sweep ice                           # army sweep of art/units/ice/
#   .\tools\art_lab\run_art_lab.ps1 fire_keep building fire -Extra 'ground=ash'
# Prints the lab's result lines; exit code = the lab's (0 PASS / WARN, 1 FAIL, 2 bad arguments, 3 watchdog).
param(
	[string]$Scene = "",
	[string]$Kind = "unit",
	[string]$Kingdom = "",
	[string]$Sweep = "",
	[string[]]$Extra = @(),
	[switch]$Headless
)
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$gate = Join-Path $root "tools\godot_run.ps1"
$labArgs = @()
if ($Sweep -ne "") {
	$labArgs += "sweep=$Sweep"
	$labArgs += "kind=$Kind"
	$quit = 900000
} else {
	if ($Scene -eq "") { Write-Output "usage: run_art_lab.ps1 <scene> [kind] [kingdom] | -Sweep <kingdom>"; exit 2 }
	$labArgs += "scene=$Scene"
	$labArgs += "kind=$Kind"
	if ($Kingdom -ne "") { $labArgs += "kingdom=$Kingdom" }
	$quit = 90000
}
$labArgs += $Extra
$godotArgs = @()
if ($Headless) { $godotArgs += "--headless" }
$godotArgs += @("--path", $root, "-s", "res://tools/art_lab/art_lab.gd", "--quit-after", "$quit", "--") + $labArgs
# stderr lines (Godot warnings) must not stop the wrapper; script / parse errors are shown so a broken lab is not silent.
$ErrorActionPreference = "Continue"
& $gate @godotArgs 2>&1 | ForEach-Object { "$_" } | Where-Object { $_ -match "ART LAB|^\s+(FAIL|WARN)|^\s+\||SCRIPT ERROR|Parse Error" }
$code = $LASTEXITCODE
if ($Sweep -eq "" -and $Scene -ne "") {
	$name = [IO.Path]::GetFileNameWithoutExtension($Scene)
	$card = Join-Path $root "docs\art\lab\$name\scorecard.md"
	if (Test-Path $card) { Write-Output "Scorecard: $card (contact sheet: contact_sheet.png next to it)" }
}
exit $code
