# cine: the Movie Maker CLI (tools/cine/README.md). Usage:
#   .\tools\cine\run_cine.ps1 help
#   .\tools\cine\run_cine.ps1 check watch_keep            # headless, < 60 s; exit 0 PASS / WARN, 1 FAIL, 2 bad input
#   .\tools\cine\run_cine.ps1 build watch_keep            # check + bake data/cinematics/watch_keep.tres
#   .\tools\cine\run_cine.ps1 sheet watch_keep            # headless timing sheet PNG
#   .\tools\cine\run_cine.ps1 stills watch_keep [shot=S3] [res=1600x900,3440x1440]   # opens a window
#   .\tools\cine\run_cine.ps1 animatic watch_keep         # opens a window, grey proxies
#   .\tools\cine\run_cine.ps1 play watch_keep             # opens a window, live
#   .\tools\cine\run_cine.ps1 record watch_keep [fps=30] [res=1920x804] [dur=10]   # Movie Maker AVI at res (sized project copy)
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
# A project copy whose viewport size = $res, for Movie Maker AVI records: %LOCALAPPDATA%\four-wizards-cine\proj_<WxH>\
# = directory junctions to this project's folders (same files, same .godot import cache) + a fresh project.godot +
# override.cfg. Kept between runs (never delete it with Remove-Item -Recurse: that would follow the junctions).
function SizedProject([string]$res) {
	$root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
	$wh = $res.ToLower().Split("x")
	$p = Join-Path $env:LOCALAPPDATA "four-wizards-cine\proj_$res"
	New-Item -ItemType Directory -Force $p | Out-Null
	foreach ($d in Get-ChildItem $root -Directory -Force) {
		if ($d.Name -in @(".git", ".claude")) { continue }
		$l = Join-Path $p $d.Name
		if (-not (Test-Path $l)) { New-Item -ItemType Junction -Path $l -Target $d.FullName | Out-Null }
	}
	Copy-Item (Join-Path $root "project.godot") $p -Force
	Set-Content -Encoding ascii (Join-Path $p "override.cfg") ("[display]`r`n`r`nwindow/size/viewport_width={0}`r`nwindow/size/viewport_height={1}`r`n" -f [int]$wh[0], [int]$wh[1])
	return $p
}
# Frame size of an MJPEG AVI (the first JPEG's SOF marker, what players show) as "WxH".
function AviSize([string]$path) {
	$fs = [IO.File]::OpenRead($path); $buf = New-Object byte[] 262144; $n = $fs.Read($buf, 0, $buf.Length); $fs.Close()
	for ($i = 0; $i -lt $n - 9; $i++) {
		if ($buf[$i] -eq 0xFF -and ($buf[$i + 1] -eq 0xC0 -or $buf[$i + 1] -eq 0xC2)) {
			return "{0}x{1}" -f ($buf[$i + 7] * 256 + $buf[$i + 8]), ($buf[$i + 5] * 256 + $buf[$i + 6])
		}
	}
	return "unknown"
}

switch ($Verb) {
	{ $_ -in @("stills", "animatic", "play", "perf", "diff") } {
		$res = (Opt "res" "1600x900").Split(",")[0]
		& $common -Script $script -Windowed -QuitAfter 36000 -GodotArgs @("--windowed", "--resolution", $res) -ToolArgs (@($Verb, $Id) + $Rest) -Quiet
		exit $LASTEXITCODE
	}
	"record" {
		$fps = [int](Opt "fps" "30")
		$res = Opt "res" "1920x804"
		$format = Opt "format" "avi"
		$out = Opt "out" (Join-Path $env:USERPROFILE "Videos\four-wizards-rec\$Id")
		New-Item -ItemType Directory -Force $out | Out-Null
		if ($format -eq "avi") {
			# one .avi (MJPEG video + PCM audio: narration + music) written by Godot's Movie Maker, window = res
			$movie = Opt "movie" (Join-Path $out "$Id.avi")
			$mdir = Split-Path -Parent $movie
			if ($mdir) { New-Item -ItemType Directory -Force $mdir | Out-Null }
			if (Test-Path $movie) { Remove-Item -Force $movie }
			$dur = [double](Opt "dur" "200")
			$qa = [int](($dur + 5) * $fps)
			$pass = @($Rest | Where-Object { $_ -notlike "res=*" -and $_ -notlike "fps=*" -and $_ -notlike "movie=*" }) + @("res=$res", "fps=$fps")
			# Godot 4.7 Movie Maker resizes AVI frames to the project viewport size (display/window/size/viewport_*),
			# whatever the window. So the record runs from a sized project copy: junctions to this project's folders +
			# project.godot + override.cfg (viewport = res), and the window = res. At 2.39 the frame IS the band.
			$proj = SizedProject $res
			$ga = @("--path", $proj, "--windowed", "--resolution", $res, "--write-movie", $movie, "-s", $script,
				"--fixed-fps", "$fps", "--quit-after", "$qa", "--") + @(@($Verb, $Id) + $pass | Where-Object { $_ })
			& (Join-Path $PSScriptRoot "..\godot_run.ps1") @ga | Where-Object { $_ -notmatch "^Godot Engine v|^Vulkan|^OpenGL|^\s*$|^WARNING: .*ObjectDB" }
			$code = $LASTEXITCODE
			$hdr = if (Test-Path $movie) { AviSize $movie } else { "none" }
			Write-Output ("CINE record {0}: AVI frame size {1} (asked {2})" -f $Id, $hdr, $res)
			if ((Test-Path $movie) -and $hdr -ne $res) { $code = 1 }
			$ok = Test-Path $movie
			$mb = if ($ok) { [math]::Round((Get-Item $movie).Length / 1MB, 1) } else { 0 }
			Write-Output ("CINE record {0}: AVI {1} ({2} MB) {3}" -f $Id, $movie, $mb, $(if ($ok) { "written" } else { "MISSING" }))
			if (-not $ok) { exit 1 }
			exit $code
		}
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
