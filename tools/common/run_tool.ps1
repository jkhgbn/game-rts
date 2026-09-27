# Shared launcher of the tools wave (tools/common/README.md). A tool's run_<tool>.ps1 calls it with its entry script.
# Runs Godot through the gate (tools/godot_run.ps1), headless unless -Windowed, always with --fixed-fps and --quit-after,
# passes the tool args after '--' and returns the tool's exit code (0 PASS / WARN, 1 FAIL, 2 bad input, 3 watchdog).
#   & "$PSScriptRoot\..\common\run_tool.ps1" -Script res://tools/cine/cine_main.gd -ToolArgs (@($Verb, $Id) + $Rest)
param(
	[Parameter(Mandatory = $true)][string]$Script,
	[string[]]$ToolArgs = @(),
	[switch]$Windowed,
	[int]$Fps = 60,
	[int]$QuitAfter = 20000,
	[string[]]$GodotArgs = @(),
	[switch]$Quiet
)
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$gate = Join-Path $root "tools\godot_run.ps1"
$a = @()
if (-not $Windowed) { $a += "--headless" }
$a += @("--path", $root) + $GodotArgs + @("-s", $Script, "--fixed-fps", "$Fps", "--quit-after", "$QuitAfter", "--")
$a += ($ToolArgs | Where-Object { $_ -ne $null -and $_ -ne "" })
if ($Quiet) {
	& $gate @a | Where-Object { $_ -notmatch "^Godot Engine v|^Vulkan|^OpenGL|^\s*$|^WARNING: .*ObjectDB" }
} else {
	& $gate @a
}
exit $LASTEXITCODE
