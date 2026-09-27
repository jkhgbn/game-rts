# Voice Forge (tools/voice_forge/README.md): every spoken line of the game -> one Kokoro voice WAV. Usage:
#   .\tools\voice_forge\run_voice_forge.ps1 help
#   .\tools\voice_forge\run_voice_forge.ps1 check  [id]           # extract + report (no rendering); exit 0 PASS/WARN, 1 FAIL, 2 bad input
#   .\tools\voice_forge\run_voice_forge.ps1 build  [id] [force=1] [only=<speaker>]   # extract + render new/changed + import + report
#   .\tools\voice_forge\run_voice_forge.ps1 demo                  # the acceptance demo: build + check, all lines voiced, 0 FAIL
#   .\tools\voice_forge\run_voice_forge.ps1 audition [only=<speaker>]   # candidates -> docs/tools/voice_forge/auditions/
# Rendering runs in the Kokoro venv OUTSIDE the repo ($env:FW_VOICE_HOME, default ..\four-wizards-voice\venv).
# Outputs: assets/audio/voice/<speaker>/*.wav, data/voice/manifest.json, docs/tools/voice_forge/out/<id>/report.md.
param(
	[Parameter(Position = 0)][string]$Verb = "help",
	[Parameter(Position = 1)][string]$Id = "",
	[Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest = @()
)
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$common = Join-Path $PSScriptRoot "..\common\run_tool.ps1"
$script = "res://tools/voice_forge/voice_forge_main.gd"
if ($Id -match "=") { $Rest = @($Id) + $Rest; $Id = "" }
if ($Id -eq "") { $Id = "all" }
$home_dir = if ($env:FW_VOICE_HOME) { $env:FW_VOICE_HOME } else { Join-Path (Split-Path -Parent $root) "four-wizards-voice" }
$py = Join-Path $home_dir "venv\Scripts\python.exe"
$forge = Join-Path $PSScriptRoot "voice_forge.py"

function Py([string[]]$a) {
	if (-not (Test-Path $py)) { Write-Output "VOICE_FORGE: Kokoro venv not found at $py (set FW_VOICE_HOME)"; exit 2 }
	& $py $forge @a
	if ($LASTEXITCODE -ne 0) { Write-Output "VOICE_FORGE: voice_forge.py $($a[0]) failed ($LASTEXITCODE)"; exit 1 }
}
function Report([string]$v) {
	& $common -Script $script -QuitAfter 30000 -ToolArgs (@($v, $Id) + ($Rest | Where-Object { $_ -like "strict=*" })) -Quiet | Out-Host
	return $LASTEXITCODE
}
function Import() {
	& (Join-Path $root "tools\godot_run.ps1") --headless --path $root --import | Where-Object { $_ -match "ERROR|error" } | Select-Object -First 10
}

switch ($Verb) {
	"help" {
		& $common -Script $script -QuitAfter 3000 -ToolArgs @("help") -Quiet
		exit $LASTEXITCODE
	}
	"audition" {
		Py (@("audition") + $Rest)
		Write-Output "VOICE_FORGE audition -> docs/tools/voice_forge/auditions/auditions.md"
		exit 0
	}
	"check" {
		Py @("extract")
		exit (Report "check")
	}
	{ $_ -in @("build", "demo") } {
		$t0 = Get-Date
		Py (@("generate", "id=$Id") + ($Rest | Where-Object { $_ -notlike "strict=*" }))
		Import
		$code = Report $Verb
		Write-Output ("VOICE_FORGE {0} {1}: exit {2} in {3:N0} s" -f $Verb, $Id, $code, ((Get-Date) - $t0).TotalSeconds)
		exit $code
	}
	default {
		& $common -Script $script -QuitAfter 3000 -ToolArgs (@($Verb, $Id) + $Rest) -Quiet
		exit $LASTEXITCODE
	}
}
