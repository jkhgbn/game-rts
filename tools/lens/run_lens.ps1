# Lens (tool 3): shot composer + icon / portrait studio (tools/lens/README.md). Usage:
#   .\tools\lens\run_lens.ps1 help
#   .\tools\lens\run_lens.ps1 check prose10                 # headless: solve every shot -> camera_<shot>.json + report
#   .\tools\lens\run_lens.ps1 shoot prose10 [shot=P02]      # opens a window: stills + measured framing + sheet
#   .\tools\lens\run_lens.ps1 marks prose10 set=forge_watch_keep prefix=L   # headless: marks.json for a stage set
#   .\tools\lens\run_lens.ps1 icons audit_icons [only=mossback,tavern]      # opens a window: icons + sheet
#   .\tools\lens\run_lens.ps1 portrait wizard_portraits     # opens a window: art/portraits/<speaker>.png
#   .\tools\lens\run_lens.ps1 turnaround res://art/units/wizards/vessa.tscn   # opens a window: 8-view sheet
#   .\tools\lens\run_lens.ps1 cinecheck lens_demo           # headless: the baked cine uses Lens cameras
#   .\tools\lens\run_lens.ps1 demo                          # the whole acceptance demo (a, b, c, d)
# Outputs: docs/tools/lens/out/<id>/ (report*.md / .json, PNGs, camera_<shot>.json), docs/tools/lens/history.md.
# Exit codes: 0 PASS / WARN, 1 FAIL, 2 bad input, 3 watchdog.
param(
	[Parameter(Position = 0)][string]$Verb = "help",
	[Parameter(Position = 1)][string]$Id = "",
	[Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest = @()
)
$common = Join-Path $PSScriptRoot "..\common\run_tool.ps1"
$script = "res://tools/lens/lens_main.gd"
if ($Id -match "=") { $Rest = @($Id) + $Rest; $Id = "" }
function Opt([string]$k, [string]$d) { foreach ($r in $Rest) { if ($r -like "$k=*") { return $r.Substring($k.Length + 1) } }; return $d }

switch ($Verb) {
	{ $_ -in @("shoot", "sheet", "icons", "portrait", "turnaround") } {
		& $common -Script $script -Windowed -QuitAfter 60000 -GodotArgs @("--windowed", "--resolution", "1280x720") -ToolArgs (@($Verb, $Id) + $Rest) -Quiet
		exit $LASTEXITCODE
	}
	"demo" {
		$steps = @(
			@("check", "prose10"), @("shoot", "prose10"), @("icons", "audit_icons"), @("portrait", "wizard_portraits"), @("check", "lens_demo")
		)
		$codes = @()
		foreach ($s in $steps) { & $PSCommandPath $s[0] $s[1]; $codes += $LASTEXITCODE }
		$cine = Join-Path $PSScriptRoot "..\cine\run_cine.ps1"
		if (Test-Path $cine) {
			& $cine build lens_demo src=res://tools/lens/specs/lens_demo.cine
			& $PSCommandPath cinecheck lens_demo
			$codes += $LASTEXITCODE
		} else { Write-Output "LENS demo: tools/cine missing, (d) skipped"; $codes += 1 }
		$bad = @($codes | Where-Object { $_ -ne 0 }).Count
		Write-Output ("LENS demo: exit codes {0} -> {1}" -f ($codes -join ","), $(if ($bad -eq 0) { "PASS" } else { "FAIL" }))
		if ($bad -ne 0) { exit 1 }
		exit 0
	}
	default {
		& $common -Script $script -QuitAfter 30000 -ToolArgs (@($Verb, $Id) + $Rest) -Quiet
		exit $LASTEXITCODE
	}
}
