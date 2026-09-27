# Self-test of the Build Lab without Godot: builds a tiny fake project + two synthetic builds
#   A: pack format 3 embedded in a fake exe (paths without res://), everything right   -> no FAIL
#   B: pack format 2 as a side .pck (paths with res://), docs/ leak + missing data file -> FAIL on both checks
#   C: a full run with no export templates (-TemplateDir <empty>)                       -> BLOCKED, exit 3
# and runs build_lab.ps1 -AnalyzeOnly -ProjectRoot <fake> on A and B. Prints "PASS build_lab" or "FAIL build_lab: ...".
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\build_lab\test_build_lab.ps1
$ErrorActionPreference = "Stop"
$Lab = Join-Path $PSScriptRoot "build_lab.ps1"
$Tmp = Join-Path $env:TEMP ("fw_build_lab_test_" + [guid]::NewGuid().ToString("N").Substring(0, 8))
$Proj = Join-Path $Tmp "project"
$fails = New-Object System.Collections.ArrayList
function Put([string]$rel, [string]$text) {
	$p = Join-Path $Proj $rel
	New-Item -ItemType Directory -Force (Split-Path $p) | Out-Null
	[IO.File]::WriteAllText($p, $text)
}
function New-Pack([int]$ver, [string[]]$paths, [bool]$withPrefix) {
	# Returns the pack bytes (Godot PCK layout: header, file data, directory; v3+ has a directory offset).
	$ms = New-Object IO.MemoryStream
	$bw = New-Object IO.BinaryWriter($ms)
	$bw.Write([uint32]0x43504447); $bw.Write([uint32]$ver); $bw.Write([uint32]4); $bw.Write([uint32]7); $bw.Write([uint32]2)
	$bw.Write([uint32]2)                     # flags: relative file base
	$posBase = $ms.Position; $bw.Write([int64]0)
	$posDir = -1
	if ($ver -ge 3) { $posDir = $ms.Position; $bw.Write([int64]0) }
	for ($i = 0; $i -lt 16; $i++) { $bw.Write([uint32]0) }
	$dataBlocks = @()
	if ($ver -lt 3) {
		# v2: directory right after the header; data after it.
		$bw.Write([uint32]$paths.Count)
		$entryPos = @()
		foreach ($p in $paths) {
			$name = $p; if ($withPrefix) { $name = "res://$p" }
			$b = [Text.Encoding]::UTF8.GetBytes($name); $pad = (4 - ($b.Length % 4)) % 4
			$bw.Write([uint32]($b.Length + $pad)); $bw.Write($b); for ($k = 0; $k -lt $pad; $k++) { $bw.Write([byte]0) }
			$entryPos += $ms.Position; $bw.Write([int64]0); $bw.Write([int64]0); $bw.Write((New-Object byte[] 16)); $bw.Write([uint32]0)
		}
		$fileBase = $ms.Position
		$ms.Position = $posBase; $bw.Write([int64]$fileBase); $ms.Position = $ms.Length
		for ($i = 0; $i -lt $paths.Count; $i++) {
			$data = [Text.Encoding]::UTF8.GetBytes("data of " + $paths[$i] + ("x" * (100 * ($i + 1))))
			$ofs = $ms.Position - $fileBase; $bw.Write($data); $end = $ms.Position
			$ms.Position = $entryPos[$i]; $bw.Write([int64]$ofs); $bw.Write([int64]$data.Length); $ms.Position = $end
		}
	} else {
		$fileBase = $ms.Position
		$ms.Position = $posBase; $bw.Write([int64]$fileBase); $ms.Position = $ms.Length
		$ofs = @(); $sizes = @()
		for ($i = 0; $i -lt $paths.Count; $i++) {
			$data = [Text.Encoding]::UTF8.GetBytes("data of " + $paths[$i] + ("x" * (100 * ($i + 1))))
			$ofs += ($ms.Position - $fileBase); $sizes += $data.Length; $bw.Write($data)
		}
		$dir = $ms.Position
		$ms.Position = $posDir; $bw.Write([int64]$dir); $ms.Position = $ms.Length
		$bw.Write([uint32]$paths.Count)
		for ($i = 0; $i -lt $paths.Count; $i++) {
			$name = $paths[$i]; if ($withPrefix) { $name = "res://$name" }
			$b = [Text.Encoding]::UTF8.GetBytes($name); $pad = (4 - ($b.Length % 4)) % 4
			$bw.Write([uint32]($b.Length + $pad)); $bw.Write($b); for ($k = 0; $k -lt $pad; $k++) { $bw.Write([byte]0) }
			$bw.Write([int64]$ofs[$i]); $bw.Write([int64]$sizes[$i]); $bw.Write((New-Object byte[] 16)); $bw.Write([uint32]0)
		}
	}
	$bw.Flush()
	return $ms.ToArray()
}
function Run-Lab([string]$name, [string]$buildDir) {
	$out = Join-Path $Tmp "out_$name"
	& powershell -NoProfile -ExecutionPolicy Bypass -File $Lab -AnalyzeOnly -ProjectRoot $Proj -BuildDir $buildDir -OutDir $out -HistoryFile (Join-Path $Tmp "history.jsonl") -Run $name | Out-Null
	return (Get-Content (Join-Path $out "scorecard.json") -Raw -Encoding UTF8 | ConvertFrom-Json)
}
function Status($card, [string]$check) { $c = @($card.checks | Where-Object { $_.check -eq $check }); if ($c.Count -eq 0) { return "(none)" }; return $c[0].status }
function Expect([string]$what, $got, $want) { if ("$got" -ne "$want") { [void]$fails.Add("${what}: got '$got', want '$want'") } }

try {
	# ---------- fake project ----------
	Put "export_presets.cfg" "[preset.0]`n`nname=`"Windows Desktop`"`nplatform=`"Windows Desktop`"`ninclude_filter=`"*.json`"`nexclude_filter=`"tests/*, docs/*, tools/*`"`nexport_path=`"build/FakeGame.exe`"`n`n[preset.0.options]`n`ndebug/export_console_wrapper=1`n"
	Put "project.godot" "[application]`n`nrun/main_scene=`"res://scenes/m.tscn`"`n`n[autoload]`n`nEvents=`"*res://scripts/events.gd`"`n"
	Put "scenes/m.tscn" "[gd_scene format=3]`n[ext_resource type=`"Script`" path=`"res://scripts/x.gd`" id=`"1`"]`n"
	Put "scripts/x.gd" "extends Node`nconst DATA := `"res://data/a.json`"`n"
	Put "scripts/events.gd" "extends Node`n"
	Put "data/a.json" "{`"a`": 1}"
	Put "docs/notes.md" "notes"
	$later = (Get-Date).AddMinutes(5)

	# ---------- A: v3 embedded, clean ----------
	$bA = Join-Path $Tmp "buildA"; New-Item -ItemType Directory -Force (Join-Path $bA "game") | Out-Null
	$packA = New-Pack 3 @("project.binary", "scenes/m.tscn.remap", ".godot/exported/1/export-abc-m.scn", "scripts/x.gd.remap", "scripts/x.gdc", "scripts/events.gdc", "data/a.json") $false
	$stub = New-Object byte[] 4096
	$exeA = Join-Path $bA "game\FakeGame.exe"
	$fs = [IO.File]::Create($exeA); $fs.Write($stub, 0, $stub.Length); $fs.Write($packA, 0, $packA.Length)
	$tr = New-Object IO.BinaryWriter($fs); $tr.Write([int64]$packA.Length); $tr.Write([uint32]0x43504447); $tr.Flush(); $fs.Close()
	(Get-Item $exeA).LastWriteTime = $later
	$a = Run-Lab "A" $bA
	Expect "A files" $a.files 7
	Expect "A pck bytes" $a.pck_bytes ($packA.Length + 12)
	Expect "A exe bytes" $a.exe_bytes (4096 + $packA.Length + 12)
	Expect "A result" $a.result "PASS"
	foreach ($c in @("Filter: excludes dev folders", "Filter: includes *.json", "Filter: no dev files in pack", "Filter: data files ship", "Filter: referenced files ship", "Main scene + autoloads")) { Expect "A $c" (Status $a $c) "PASS" }
	$top = @($a.top | ForEach-Object { $_.path })
	Expect "A biggest file" $top[0] "data/a.json"
	$conv = @($a.top | Where-Object { $_.path -eq ".godot/exported/1/export-abc-m.scn" })
	Expect "A converted source" $(if ($conv.Count) { $conv[0].source } else { "" }) "scenes/m.tscn"

	# ---------- B: v2 side pck, docs leak + data file missing ----------
	$bB = Join-Path $Tmp "buildB"; New-Item -ItemType Directory -Force (Join-Path $bB "game") | Out-Null
	$exeB = Join-Path $bB "game\FakeGame.exe"
	[IO.File]::WriteAllBytes($exeB, $stub)
	$packB = New-Pack 2 @("project.binary", "scenes/m.tscn", "scripts/x.gdc", "scripts/events.gdc", "docs/notes.md") $true
	[IO.File]::WriteAllBytes((Join-Path $bB "game\FakeGame.pck"), $packB)
	(Get-Item $exeB).LastWriteTime = $later
	$b = Run-Lab "B" $bB
	Expect "B files" $b.files 5
	Expect "B result" $b.result "FAIL"
	Expect "B no dev files" (Status $b "Filter: no dev files in pack") "FAIL"
	Expect "B data files" (Status $b "Filter: data files ship") "FAIL"
	Expect "B referenced" (Status $b "Filter: referenced files ship") "FAIL"
	Expect "B size vs previous" (Status $b "Size vs previous") "PASS"   # smaller than A
	Expect "B previous run" $b.previous_run "A"

	# ---------- C: no export templates on this PC -> BLOCKED (exit 3), never FAIL, nothing exported ----------
	$outC = Join-Path $Tmp "out_C"
	& powershell -NoProfile -ExecutionPolicy Bypass -File $Lab -ProjectRoot $Proj -BuildsRoot (Join-Path $Tmp "builds") -TemplateDir (Join-Path $Tmp "no_templates") -OutDir $outC -HistoryFile (Join-Path $Tmp "history.jsonl") -Run "C" | Out-Null
	Expect "C exit code" $LASTEXITCODE 3
	$c = Get-Content (Join-Path $outC "scorecard.json") -Raw -Encoding UTF8 | ConvertFrom-Json
	Expect "C result" $c.result "BLOCKED"
	Expect "C export" (Status $c "Export") "BLOCKED"
	Expect "C filter still checked" (Status $c "Filter: excludes dev folders") "PASS"
	Expect "C nothing built" (Test-Path (Join-Path $Tmp "builds\C")) $false
} catch {
	[void]$fails.Add("exception: $_")
} finally {
	Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue
}
if ($fails.Count -gt 0) { Write-Host ("FAIL build_lab: " + ($fails -join " | ")); exit 1 }
Write-Host "PASS build_lab"
exit 0
