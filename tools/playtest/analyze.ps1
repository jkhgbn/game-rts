<#
.SYNOPSIS
  Playtest analyzer (docs/design/health-and-playtests.md): one or many Playtest Recorder files -> docs\playtests\<name>.md
  (pacing per objective, economy vs the bot, army timeline, fight / death heatmap PNGs, hotkeys vs clicks, hitches,
  tuning suggestions, replay hook).

.EXAMPLE
  .\tools\playtest\analyze.ps1                         (every recording in %APPDATA%\Godot\app_userdata\Four Wizards RTS\playtests)
.EXAMPLE
  .\tools\playtest\analyze.ps1 -Latest 1
.EXAMPLE
  .\tools\playtest\analyze.ps1 -Path C:\temp\2026-10-06_mission_m01.jsonl -Name js_m01
#>
param(
	[string[]]$Path = @(),
	[string]$Dir = "",
	[int]$Latest = 0,
	[string]$Name = "",
	[string]$OutDir = ""
)
$proj = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$gate = Join-Path $proj "tools\godot_run.ps1"
$user = @()
if ($Path.Count -gt 0) { $user += "files=" + (($Path | ForEach-Object { (Resolve-Path $_).Path -replace "\\", "/" }) -join ",") }
if ($Dir) { $user += "dir=$((Resolve-Path $Dir).Path -replace '\\', '/')" }
if ($Latest -gt 0) { $user += "latest=$Latest" }
if ($Name) { $user += "name=$Name" }
if ($OutDir) { New-Item -ItemType Directory -Force $OutDir | Out-Null; $user += "out=$((Resolve-Path $OutDir).Path -replace '\\', '/')" }
$lines = & $gate --headless --path $proj -s res://tools/playtest/analyze.gd '--quit-after' 3000 '--' @user 2>&1
$lines | Where-Object { "$_" -match "^PLAYTEST|SCRIPT ERROR|Parse Error" } | ForEach-Object { Write-Host $_ }
exit $LASTEXITCODE
