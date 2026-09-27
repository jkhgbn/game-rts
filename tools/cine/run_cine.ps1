# cine: the Movie Maker CLI (tools/cine/README.md). Usage:
#   .\tools\cine\run_cine.ps1 help
#   .\tools\cine\run_cine.ps1 check watch_keep            # headless, < 60 s; exit 0 PASS / WARN, 1 FAIL, 2 bad input
#   .\tools\cine\run_cine.ps1 build watch_keep            # check + bake data/cinematics/watch_keep.tres
#   .\tools\cine\run_cine.ps1 sheet watch_keep            # headless timing sheet PNG
#   .\tools\cine\run_cine.ps1 stills watch_keep [shot=S3] [res=1600x900,3440x1440]   # opens a window
#   .\tools\cine\run_cine.ps1 animatic watch_keep         # opens a window, grey proxies
#   .\tools\cine\run_cine.ps1 play watch_keep             # opens a window, live
#   .\tools\cine\run_cine.ps1 record watch_keep [fps=30] [res=1920x804] [dur=10]   # Movie Maker PNG + WAV
#   .\tools\cine\run_cine.ps1 perf watch_keep             # opens a window: ms / draw calls per shot
#   .\tools\cine\run_cine.ps1 diff watch_keep [against=golden]   # opens a window: which shots changed (stills golden=1 registers goldens)
#   .\tools\cine\run_cine.ps1 demo                        # the acceptance demo (headless + stills + 10 s record)
# Outputs: docs/tools/cine/out/<id>/ (report.md, report.json, timing.png, stills.png ...), docs/tools/cine/history.md.
# Recordings: $env:USERPROFILE\Videos\four-wizards-rec\<id>\<id>00000000.png ... + <id>.wav (outside res://).
param(
	[Parameter(Position = 0)][string]$Verb = "help",
	[Parameter(Position = 1)][string]$Id = "",
	[Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest = @()
)
$common = Join-Path $PSScriptRoot "..\common\run_tool.ps1"
$script = "res://tools/cine/cine_main.gd"
if ($Id -match "=") { $Rest = @($Id) + $Rest; $Id = "" }
function Opt([string]$k, [string]$d) { foreach ($r in $Rest) { if ($r -like "$k=*") { return $r.Substring($k.Length + 1) } }; return $d }

switch ($Verb) {
	{ $_ -in @("stills", "animatic", "play", "perf", "diff") } {
		$res = (Opt "res" "1600x900").Split(",")[0]
		& $common -Script $script -Windowed -QuitAfter 36000 -GodotArgs @("--windowed", "--resolution", $res) -ToolArgs (@($Verb, $Id) + $Rest) -Quiet
		exit $LASTEXITCODE
	}
	"record" {
		$fps = [int](Opt "fps" "30")
		$res = Opt "res" "1920x804"
		$out = Opt "out" (Join-Path $env:USERPROFILE "Videos\four-wizards-rec\$Id")
		New-Item -ItemType Directory -Force $out | Out-Null
		Get-ChildItem $out -Filter "$Id*" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
		$movie = Join-Path $out "$Id.png"
		$pass = @($Rest | Where-Object { $_ -notlike "res=*" -and $_ -notlike "fps=*" }) + @("res=$res", "fps=$fps")
		# Movie Maker frames = the project viewport size (1600x900); the window keeps it (no --resolution: it would stretch)
		& $common -Script $script -Windowed -Fps $fps -QuitAfter ($fps * 130) -GodotArgs @("--windowed", "--write-movie", $movie) -ToolArgs (@($Verb, $Id) + $pass) -Quiet
		$code = $LASTEXITCODE
		& $common -Script $script -QuitAfter 600 -ToolArgs @("reframe", $Id, "dir=$out", "res=$res", "fps=$fps") -Quiet
		if ($LASTEXITCODE -ne 0) { $code = 1 }
		$pngs = @(Get-ChildItem $out -Filter "$Id*.png" -ErrorAction SilentlyContinue)
		$wav = Join-Path $out "$Id.wav"
		$wavok = Test-Path $wav
		$mb = [math]::Round((($pngs | Measure-Object Length -Sum).Sum) / 1MB, 1)
		Write-Output ("CINE record {0}: {1} PNG frames ({2} MB) + WAV {3} in {4}" -f $Id, $pngs.Count, $mb, $(if ($wavok) { "yes" } else { "MISSING" }), $out)
		if ($pngs.Count -eq 0 -or -not $wavok) { exit 1 }
		exit $code
	}
	"demo" {
		& $common -Script $script -QuitAfter 30000 -ToolArgs @("demo") -Quiet
		$c1 = $LASTEXITCODE
		& $common -Script $script -Windowed -QuitAfter 36000 -GodotArgs @("--windowed", "--resolution", "1600x900") -ToolArgs @("stills", "watch_keep") -Quiet
		$c2 = $LASTEXITCODE
		& $PSCommandPath record watch_keep dur=10 res=1280x536
		$c3 = $LASTEXITCODE
		Write-Output ("CINE demo: headless {0}, stills {1}, record {2} -> {3}" -f $c1, $c2, $c3, $(if ($c1 -eq 0 -and $c2 -eq 0 -and $c3 -eq 0) { "PASS" } else { "FAIL" }))
		if ($c1 -ne 0 -or $c2 -ne 0 -or $c3 -ne 0) { exit 1 }
		exit 0
	}
	default {
		& $common -Script $script -QuitAfter 30000 -ToolArgs (@($Verb, $Id) + $Rest) -Quiet
		exit $LASTEXITCODE
	}
}
