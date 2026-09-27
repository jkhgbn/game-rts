# Build Lab: export the Windows build with the existing preset into a folder OUTSIDE the repo, smoke-test the
# EXPORTED build (boot the exe headless + run tests/smoke_test.gd on the exported exe), report exe / pck sizes and
# the biggest files (vs the previous build), check the export filter, zip the build and PRINT the OneDrive copy
# command (it never copies anything to OneDrive itself: the lead runs it after asking the user).
# Scorecard in the labs' style (PASS / WARN / FAIL, score 0-100, Improve next) + history.
# Docs: docs/plan/build-lab.md. Windows PowerShell 5.1. Never runs git, never edits game files.
#
#   tools\build_lab\build_lab.ps1                              # export + boot + smoke + sizes + filter + zip
#   tools\build_lab\build_lab.ps1 -SkipSmoke                   # no gameplay smoke (boot check only)
#   tools\build_lab\build_lab.ps1 -BuildDir <existing build>   # re-analyse an existing build, no export
#   tools\build_lab\build_lab.ps1 -AnalyzeOnly -BuildDir <dir> # sizes + filter only (no Godot at all)
param(
	[string]$Preset = "",
	[string]$BuildsRoot = "C:\Users\elzzo\Documents\four-wizards-builds",
	[string]$BuildDir = "",
	[string]$Run = "",
	[string]$OutDir = "",
	[string]$HistoryFile = "",
	[switch]$ExportDebug,
	[switch]$SkipSmoke,
	[switch]$SkipBoot,
	[switch]$SkipZip,
	[switch]$AnalyzeOnly,
	[switch]$NoHistory,
	[int]$BootFrames = 600,
	[int]$SmokeFrames = 7000,
	[int]$ExportTimeoutSec = 3600,
	[int]$RunTimeoutSec = 1800,
	[int]$TopN = 25,
	[double]$GrowthWarnPct = 10.0,
	[string]$ProjectRoot = ""   # tests only: a fake project folder instead of the repo
)
$ErrorActionPreference = "Stop"
$LabVersion = "1.0"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
if ($ProjectRoot) { $Root = (Resolve-Path $ProjectRoot).Path }
$GodotExe = "C:\Godot\Godot_v4.7.2-stable_win64_console.exe"
$Gate = (Resolve-Path (Join-Path $PSScriptRoot "..\godot_run.ps1")).Path
if (-not $Run) { $Run = Get-Date -Format "yyyy-MM-dd_HHmm" }
if (-not $OutDir) { $OutDir = Join-Path $Root "docs\build\lab\$Run" }
if (-not $HistoryFile) { $HistoryFile = Join-Path $Root "docs\build\lab\history.jsonl" }
$Utf8 = New-Object System.Text.UTF8Encoding($false)
Add-Type -AssemblyName System.IO.Compression.FileSystem

# ---------- checks table ----------
$Checks = New-Object System.Collections.ArrayList
function Add-Check([string]$name, [string]$status, [string]$detail, [string]$fix = "") {
	[void]$Checks.Add([pscustomobject]@{ check = $name; status = $status; detail = $detail; fix = $fix })
	$c = "Gray"; if ($status -eq "FAIL") { $c = "Red" } elseif ($status -eq "WARN") { $c = "Yellow" } elseif ($status -eq "PASS") { $c = "Green" }
	Write-Host ("  [{0}] {1}: {2}" -f $status, $name, $detail) -ForegroundColor $c
}
function Fmt-MB([double]$b) { return ("{0:N1} MB" -f ($b / 1MB)) }
function Fmt-Delta([double]$b) {
	$s = "+"; if ($b -lt 0) { $s = "-" }
	if ([math]::Abs($b) -ge 1MB) { return ("{0}{1:N1} MB" -f $s, ([math]::Abs($b) / 1MB)) }
	return ("{0}{1:N0} KB" -f $s, ([math]::Abs($b) / 1KB))
}
function Norm-Res([string]$p) { return (($p -replace '\\', '/') -replace '^res://', '').TrimStart('/') }

# ---------- preset ----------
function Read-Presets([string]$file) {
	$list = @(); $cur = $null; $pre = ""
	foreach ($line in (Get-Content $file -Encoding UTF8)) {
		if ($line -match '^\[preset\.(\d+)\]\s*$') { $cur = @{ index = [int]$Matches[1] }; $list += $cur; $pre = ""; continue }
		if ($line -match '^\[preset\.(\d+)\.options\]\s*$') { $pre = "options."; continue }   # options of the preset above
		if ($line -match '^\[') { $cur = $null; continue }
		if ($null -ne $cur -and $line -match '^([A-Za-z0-9_/]+)=(.*)$') { $cur[$pre + $Matches[1]] = $Matches[2].Trim().Trim('"') }
	}
	return $list
}
$presetFile = Join-Path $Root "export_presets.cfg"
if (-not (Test-Path $presetFile)) { Write-Host "BUILD LAB: export_presets.cfg not found"; exit 2 }
$presets = @(Read-Presets $presetFile)
$P = $null
foreach ($x in $presets) {
	if ($Preset -and $x.name -eq $Preset) { $P = $x; break }
	if (-not $Preset -and $x.platform -eq "Windows Desktop") { $P = $x; break }
}
if ($null -eq $P) { Write-Host "BUILD LAB: preset '$Preset' not found (have: $(($presets | ForEach-Object { $_.name }) -join ', '))"; exit 2 }
$exeName = Split-Path $P.export_path -Leaf
if (-not $exeName) { $exeName = "FourWizards.exe" }
$baseName = [IO.Path]::GetFileNameWithoutExtension($exeName)

# ---------- build folder (must be outside the repo and outside OneDrive) ----------
$reuse = [bool]$BuildDir
if (-not $BuildDir) { $BuildDir = Join-Path $BuildsRoot $Run }
$BuildDir = [IO.Path]::GetFullPath($BuildDir)
$rootFull = [IO.Path]::GetFullPath($Root).TrimEnd('\') + '\'
if ($BuildDir.StartsWith($rootFull, [StringComparison]::OrdinalIgnoreCase)) { Write-Host "BUILD LAB: the build folder must be outside the repo ($BuildDir)"; exit 2 }
$od = @($env:OneDrive, $env:OneDriveConsumer, $env:OneDriveCommercial) | Where-Object { $_ }
foreach ($o in $od) { if ($BuildDir.StartsWith(([IO.Path]::GetFullPath($o).TrimEnd('\') + '\'), [StringComparison]::OrdinalIgnoreCase)) { Write-Host "BUILD LAB: refusing a build folder inside OneDrive ($BuildDir)"; exit 2 } }
if ($BuildDir -match '\\OneDrive(\\| - |$)') { Write-Host "BUILD LAB: refusing a build folder inside OneDrive ($BuildDir)"; exit 2 }
$GameDir = Join-Path $BuildDir "game"
$ExePath = Join-Path $GameDir $exeName
New-Item -ItemType Directory -Force $OutDir | Out-Null
$LogDir = Join-Path $OutDir "logs"
New-Item -ItemType Directory -Force $LogDir | Out-Null

Write-Host "BUILD LAB v$LabVersion run $Run - preset '$($P.name)' -> $ExePath"

# ---------- run helpers ----------
$ErrRx = 'SCRIPT ERROR|Parse Error|Invalid call|Nonexistent function|Failed to load|Cannot open file|ERROR:'
$NoiseRx = 'resources still in use at exit|ObjectDB instances (were )?leaked at exit|RID allocations of type .* were leaked at exit|Leaked instance:|Orphan StringName|Pages in use exist at exit|PagedAllocator'
function Get-LogErrors([string]$log) {
	if (-not (Test-Path $log)) { return @() }
	$u = @{}
	foreach ($l in (Get-Content $log -Encoding UTF8)) {
		if ($l -match $ErrRx -and $l -notmatch $NoiseRx) { $k = ($l.Trim() -replace '0x[0-9a-fA-F]+', '0x#'); if (-not $u.ContainsKey($k)) { $u[$k] = 0 }; $u[$k]++ }
	}
	return @($u.Keys | Sort-Object)
}
function Invoke-Logged([string]$exe, [string[]]$argList, [string]$log, [int]$timeout, [bool]$viaGate) {
	# Runs through cmd.exe so stdout+stderr land in the log; returns @{ exit; seconds; timed_out }.
	$q = @($argList | ForEach-Object { if ($_ -match '[\s"]') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ } }) -join ' '
	if ($viaGate) { $cmd = "powershell -NoProfile -ExecutionPolicy Bypass -File `"$Gate`" $q > `"$log`" 2>&1" }
	else { $cmd = "`"$exe`" $q > `"$log`" 2>&1" }
	$sem = $null; $got = $false
	if (-not $viaGate) {
		# Same traffic light as tools/godot_run.ps1 (the exported exe is a Godot run too).
		$sem = New-Object System.Threading.Semaphore(4, 4, "Local\FourWizardsGodotGate")
		$got = $sem.WaitOne([TimeSpan]::FromSeconds(900))
	}
	try {
		$start = Get-Date
		$p = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "`"$cmd`"" -WorkingDirectory $BuildDir -WindowStyle Hidden -PassThru
		$null = $p.Handle
		$timedOut = $false
		while (-not $p.HasExited) {
			if (((Get-Date) - $start).TotalSeconds -gt $timeout) { & taskkill.exe /T /F /PID $p.Id | Out-Null; $timedOut = $true; break }
			Start-Sleep -Milliseconds 500
		}
		$p.WaitForExit(5000) | Out-Null
		$code = -1; if (-not $timedOut) { $code = $p.ExitCode }
		return @{ exit = $code; seconds = [math]::Round(((Get-Date) - $start).TotalSeconds, 1); timed_out = $timedOut }
	} finally {
		if ($got) { [void]$sem.Release() }
		if ($sem) { $sem.Dispose() }
	}
}

# ---------- 0. pre-checks ----------
$tplName = "windows_release_x86_64.exe"; if ($ExportDebug) { $tplName = "windows_debug_x86_64.exe" }
$tpl = Join-Path $env:APPDATA "Godot\export_templates\4.7.2.stable\$tplName"
$exportInfo = @{ exit = $null; seconds = 0; skipped = $true }

# ---------- 1. export ----------
if (-not $reuse -and -not $AnalyzeOnly) {
	if (-not (Test-Path $GodotExe)) { Add-Check "Export" "FAIL" "Godot console exe not found: $GodotExe" }
	elseif (-not (Test-Path $tpl)) { Add-Check "Export" "FAIL" "export template missing: $tpl" "Install the 4.7.2 export templates (Editor > Manage Export Templates)." }
	else {
		New-Item -ItemType Directory -Force $GameDir | Out-Null
		$mode = "--export-release"; if ($ExportDebug) { $mode = "--export-debug" }
		Write-Host "BUILD LAB: exporting ($mode '$($P.name)') through the Godot gate..."
		$exportLog = Join-Path $LogDir "export.log"
		$exportInfo = Invoke-Logged $GodotExe @("--headless", "--path", $Root, $mode, $P.name, $ExePath) $exportLog $ExportTimeoutSec $true
		$exportInfo.skipped = $false
		$exErr = @(Get-LogErrors $exportLog)
		if ($exportInfo.timed_out) { Add-Check "Export" "FAIL" "timed out after $ExportTimeoutSec s (log: logs/export.log)" }
		elseif (-not (Test-Path $ExePath)) { Add-Check "Export" "FAIL" "no exe produced (exit $($exportInfo.exit), log: logs/export.log)" "Read logs/export.log; usually a missing template or a script parse error." }
		elseif ($exportInfo.exit -ne 0) { Add-Check "Export" "FAIL" "exit $($exportInfo.exit) in $($exportInfo.seconds) s (exe exists; log: logs/export.log)" "Read logs/export.log." }
		elseif ($exErr.Count -gt 0) { Add-Check "Export" "WARN" "exported in $($exportInfo.seconds) s with $($exErr.Count) unique error lines in the export log, first: $($exErr[0])" "Fix the resources named in logs/export.log (they may be broken in the build)." }
		else { Add-Check "Export" "PASS" "exported in $($exportInfo.seconds) s (exit 0, clean log)" }
	}
} else {
	if (-not (Test-Path $ExePath)) {
		$found = Get-ChildItem $BuildDir -Recurse -Filter "*.exe" -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch '\.console\.exe$' } | Select-Object -First 1
		if ($found) { $ExePath = $found.FullName; $GameDir = $found.DirectoryName }
	}
	Add-Check "Export" "INFO" "skipped (re-using $ExePath)"
}
$exportOk = (Test-Path $ExePath) -and -not (@($Checks | Where-Object { $_.check -eq "Export" -and $_.status -eq "FAIL" }).Count -gt 0)
$ConsoleExe = Join-Path $GameDir "$baseName.console.exe"

# ---------- 2. pck listing ----------
function Read-Pck([string]$path) {
	$fs = [IO.File]::OpenRead($path)
	$br = New-Object IO.BinaryReader($fs)
	try {
		$magic = [uint32]0x43504447   # "GDPC"
		$start = [int64]0
		if ($br.ReadUInt32() -ne $magic) {
			[void]$fs.Seek(-4, [IO.SeekOrigin]::End)
			if ($br.ReadUInt32() -ne $magic) { return $null }
			[void]$fs.Seek(-12, [IO.SeekOrigin]::End)
			$ds = $br.ReadInt64()
			$start = $fs.Length - 12 - $ds
			[void]$fs.Seek($start, [IO.SeekOrigin]::Begin)
			if ($br.ReadUInt32() -ne $magic) { return $null }
		}
		$ver = $br.ReadUInt32(); $maj = $br.ReadUInt32(); $min = $br.ReadUInt32(); $pat = $br.ReadUInt32()
		$flags = $br.ReadUInt32()
		[void]$br.ReadInt64()   # file base
		if ($ver -ge 3) { $dirOfs = $br.ReadInt64(); [void]$fs.Seek($start + $dirOfs, [IO.SeekOrigin]::Begin) }
		else { for ($i = 0; $i -lt 16; $i++) { [void]$br.ReadUInt32() } }
		$info = [pscustomobject]@{ format = $ver; godot = "$maj.$min.$pat"; flags = $flags; start = $start; size = ($fs.Length - $start); embedded = ($start -gt 0); files = @() }
		if ($flags -band 1) { return $info }   # encrypted directory
		$count = $br.ReadUInt32()
		$files = New-Object System.Collections.Generic.List[object]
		for ($i = 0; $i -lt $count; $i++) {
			$sl = $br.ReadUInt32()
			$name = [Text.Encoding]::UTF8.GetString($br.ReadBytes([int]$sl)).TrimEnd([char]0)
			[void]$br.ReadInt64()
			$size = $br.ReadInt64()
			[void]$br.ReadBytes(16)
			if ($ver -ge 2) { [void]$br.ReadUInt32() }
			$files.Add([pscustomobject]@{ path = (Norm-Res $name); size = $size })
		}
		$info.files = $files.ToArray()
		return $info
	} finally { $br.Close(); $fs.Close() }
}

$pck = $null; $pckPath = ""
$exeBytes = [int64]0; $pckBytes = [int64]0; $consoleBytes = [int64]0
if (Test-Path $ExePath) {
	$exeBytes = (Get-Item $ExePath).Length
	if (Test-Path $ConsoleExe) { $consoleBytes = (Get-Item $ConsoleExe).Length }
	$sidePck = Join-Path $GameDir "$baseName.pck"
	if (Test-Path $sidePck) { $pckPath = $sidePck } else { $pckPath = $ExePath }
	try { $pck = Read-Pck $pckPath } catch { $pck = $null; Write-Host "  pck read error: $_" }
	if ($null -eq $pck) { Add-Check "PCK listing" "WARN" "could not read the pack in $pckPath" }
	elseif ($pck.flags -band 1) { $pckBytes = $pck.size; Add-Check "PCK listing" "WARN" "pack directory is encrypted: no file listing" }
	else {
		$pckBytes = $pck.size
		$embeddedNote = "separate .pck"; if ($pck.embedded) { $embeddedNote = "embedded in the exe" }
		Add-Check "PCK listing" "INFO" ("{0} files, {1} ({2}), pack format {3}, Godot {4}" -f $pck.files.Count, (Fmt-MB $pckBytes), $embeddedNote, $pck.format, $pck.godot)
	}
}

# Source names for imported / exported files (from the repo's *.import files).
$importMap = @{}
if ($pck -and $pck.files.Count -gt 0) {
	foreach ($f in (Get-ChildItem $Root -Recurse -Filter "*.import" -File -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch '\\\.godot\\' })) {
		$src = Norm-Res ($f.FullName.Substring($rootFull.Length) -replace '\.import$', '')
		foreach ($l in [IO.File]::ReadLines($f.FullName)) {
			if ($l -match '^(path(\.[a-z0-9_]+)?|dest_files)=.*?"res://(\.godot/imported/[^"]+)"') { $importMap[$Matches[3]] = $src }
			if ($l -eq "[deps]") { break }
		}
	}
	# Text scenes / resources converted to binary on export: .godot/exported/<id>/export-<md5>-<name>.scn|.res.
	# Map them back by file name (x.tscn -> x.scn, x.tres -> x.res) when that name is unique in the repo.
	$convMap = @{}
	foreach ($g in @("scripts", "scenes", "missions", "data", "assets", "art")) {
		$gp = Join-Path $Root $g
		if (-not (Test-Path $gp)) { continue }
		foreach ($f in (Get-ChildItem $gp -Recurse -File -Include *.tscn, *.tres -ErrorAction SilentlyContinue)) {
			$bn = $f.Name -replace '\.tscn$', '.scn' -replace '\.tres$', '.res'
			$rel = Norm-Res $f.FullName.Substring($rootFull.Length)
			if ($convMap.ContainsKey($bn)) { $convMap[$bn] = "" } else { $convMap[$bn] = $rel }
		}
	}
}
function Get-Source([string]$p) {
	if ($importMap.ContainsKey($p)) { return $importMap[$p] }
	if ($p -match '^\.godot/imported/(.+)-[0-9a-f]{32}\.[^.]+$') { return "(imported) " + $Matches[1] }
	if ($p -match '^\.godot/exported/[^/]+/export-[0-9a-f]+-(.+)$') {
		$bn = $Matches[1]
		if ($convMap.ContainsKey($bn) -and $convMap[$bn]) { return $convMap[$bn] }
		return "(converted) " + $bn
	}
	return $p
}
function Get-Category([string]$src) {
	$s = $src -replace '^\((imported|converted)\) ', ''
	if ($s -match '^\.godot/') { return ".godot (engine)" }
	if ($s -notmatch '/') {
		if ($src -match '^\(') { return "converted / imported (name not unique)" }
		return "root files"
	}
	return ($s -split '/')[0] + "/"
}

$rows = New-Object System.Collections.Generic.List[object]
$categories = @{}
if ($pck -and $pck.files.Count -gt 0) {
	foreach ($f in $pck.files) {
		$src = Get-Source $f.path
		$cat = Get-Category $src
		if (-not $categories.ContainsKey($cat)) { $categories[$cat] = [pscustomobject]@{ category = $cat; bytes = [int64]0; files = 0 } }
		$categories[$cat].bytes += $f.size; $categories[$cat].files++
		$rows.Add([pscustomobject]@{ path = $f.path; source = $src; size = $f.size; category = $cat })
	}
	# Full listing next to the build (outside the repo) so the next run can diff per file.
	[IO.File]::WriteAllText((Join-Path $BuildDir "pck_files.json"), (@($rows | Select-Object path, source, size) | ConvertTo-Json -Depth 3 -Compress), $Utf8)
}
$top = @($rows | Sort-Object size -Descending | Select-Object -First $TopN)
$catRows = @($categories.Values | Sort-Object bytes -Descending)

# ---------- 3. previous build ----------
$prev = $null
if (Test-Path $HistoryFile) {
	$hl = @(Get-Content $HistoryFile -Encoding UTF8 | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json } | Where-Object { $_.exe_bytes -gt 0 -and $_.run -ne $Run })
	if ($hl.Count -gt 0) { $prev = $hl[$hl.Count - 1] }
}
$growers = @()
$prevFileCount = $null
if ($prev -and $rows.Count -gt 0) {
	$prevList = Join-Path $prev.build_dir "pck_files.json"
	$prevMap = @{}
	if ($prev.build_dir -and (Test-Path $prevList)) {
		foreach ($r in (Get-Content $prevList -Raw -Encoding UTF8 | ConvertFrom-Json)) { $prevMap[$r.path] = [int64]$r.size }
	} elseif ($prev.top) { foreach ($r in $prev.top) { $prevMap[$r.path] = [int64]$r.size } }
	$curMap = @{}
	foreach ($r in $rows) { $curMap[$r.path] = $r }
	$d = New-Object System.Collections.Generic.List[object]
	foreach ($r in $rows) { $old = [int64]0; if ($prevMap.ContainsKey($r.path)) { $old = $prevMap[$r.path] }; if ($r.size -ne $old) { $d.Add([pscustomobject]@{ path = $r.path; source = $r.source; before = $old; after = $r.size; delta = $r.size - $old; note = $(if ($old -eq 0) { "new" } else { "" }) }) } }
	foreach ($k in $prevMap.Keys) { if (-not $curMap.ContainsKey($k)) { $d.Add([pscustomobject]@{ path = $k; source = (Get-Source $k); before = $prevMap[$k]; after = 0; delta = -$prevMap[$k]; note = "removed" }) } }
	$growers = @($d | Sort-Object @{ e = { [math]::Abs($_.delta) } } -Descending | Select-Object -First 15)
}
if ($exeBytes -gt 0) {
	if ($prev) {
		$dExe = $exeBytes - [int64]$prev.exe_bytes
		$pct = 0.0; if ($prev.exe_bytes -gt 0) { $pct = 100.0 * $dExe / $prev.exe_bytes }
		$st = "PASS"; $fix = ""
		if ($pct -gt $GrowthWarnPct) { $st = "WARN"; $fix = "See 'Changed files vs previous build': the growth comes from the top rows." }
		Add-Check "Size vs previous" $st ("exe {0} ({1}, {2:+0.0;-0.0}%) vs {3} ({4})" -f (Fmt-MB $exeBytes), (Fmt-Delta $dExe), $pct, $prev.run, (Fmt-MB $prev.exe_bytes)) $fix
	} else { Add-Check "Size vs previous" "INFO" ("exe {0}, pack {1}; first build in the history" -f (Fmt-MB $exeBytes), (Fmt-MB $pckBytes)) }
}

# ---------- 4. export filter ----------
$inc = @(($P.include_filter -split ',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
$exc = @(($P.exclude_filter -split ',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
$DevFolders = @("docs", "tools", "tests")
$missingExc = @($DevFolders | Where-Object { $exc -notcontains "$_/*" -and $exc -notcontains "res://$_/*" -and $exc -notcontains "$_/**" })
if ($missingExc.Count -gt 0) { Add-Check "Filter: excludes dev folders" "FAIL" ("exclude_filter lacks: " + (($missingExc | ForEach-Object { "$_/*" }) -join ', ') + " (have: $($P.exclude_filter))") "Add them to the preset's exclude_filter (lead owns export_presets.cfg)." }
else { Add-Check "Filter: excludes dev folders" "PASS" "exclude_filter = $($P.exclude_filter)" }
if ($inc -contains "*.json") { Add-Check "Filter: includes *.json" "PASS" "include_filter = $($P.include_filter)" }
else { Add-Check "Filter: includes *.json" "WARN" "include_filter has no *.json (have: '$($P.include_filter)')" "Add *.json to include_filter so data files ship." }

$GameFolders = @("scripts", "scenes", "missions", "data", "assets", "art")
if ($pck -and $pck.files.Count -gt 0) {
	$pckSet = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
	foreach ($f in $pck.files) { [void]$pckSet.Add($f.path) }
	function In-Pck([string]$rel) {
		if ($pckSet.Contains($rel) -or $pckSet.Contains("$rel.remap") -or $pckSet.Contains("$rel.import")) { return $true }
		if ($rel -match '\.gd$' -and $pckSet.Contains(($rel -replace '\.gd$', '.gdc'))) { return $true }
		return $false
	}
	# 4a. nothing from the dev folders / repo tooling in the pack
	$leak = @($pck.files | Where-Object { $_.path -match '^(docs|tools|tests|build|\.claude|\.git)/' -or $_.path -match '\.(md|ps1|bat|blend|blend1|psd|kra|xcf)$' -or $_.path -match '^art/preview/' })
	if ($leak.Count -gt 0) {
		$lb = ($leak | Measure-Object size -Sum).Sum
		Add-Check "Filter: no dev files in pack" "FAIL" ("{0} dev files ({1}) in the pack, e.g. {2}" -f $leak.Count, (Fmt-MB $lb), (($leak | Select-Object -First 4 | ForEach-Object { $_.path }) -join ', ')) "Extend exclude_filter (export_presets.cfg, lead) or move the files."
	} else { Add-Check "Filter: no dev files in pack" "PASS" "no docs/ tools/ tests/ art/preview/ .md .ps1 source-art files in the pack" }
	# Art preview / render tool scenes and scripts inside art/ ship too (harmless, a little dead weight).
	$toolFiles = @($rows | Where-Object { $_.source -match '(^|/)tools/|_preview[._]|(^|/)render_[^/]*\.(gd|tscn)|_pose_check\.' })
	if ($toolFiles.Count -gt 0) {
		Add-Check "Art tool scripts in the pack" "INFO" ("{0} files ({1}) from art preview / render tools ship (e.g. {2}); an exclude like ``art/*/tools/*`` would drop them" -f $toolFiles.Count, (Fmt-MB (($toolFiles | Measure-Object size -Sum).Sum)), (($toolFiles | Select-Object -First 2 | ForEach-Object { $_.source }) -join ', '))
	}
	# 4b. non-resource data files in game folders must ship
	$dataFiles = @()
	foreach ($g in $GameFolders) {
		$gp = Join-Path $Root $g
		if (Test-Path $gp) { $dataFiles += @(Get-ChildItem $gp -Recurse -File -Include *.json, *.txt, *.csv, *.cfg, *.ini -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch '\\art\\preview\\' }) }
	}
	$missData = @($dataFiles | ForEach-Object { Norm-Res $_.FullName.Substring($rootFull.Length) } | Where-Object { -not (In-Pck $_) })
	if ($missData.Count -gt 0) { Add-Check "Filter: data files ship" "FAIL" ("{0} of {1} data files missing from the pack, e.g. {2}" -f $missData.Count, $dataFiles.Count, (($missData | Select-Object -First 4) -join ', ')) "Add their extension to include_filter." }
	else { Add-Check "Filter: data files ship" "PASS" ("{0} non-resource data files (json/txt/csv/cfg) in game folders, all in the pack" -f $dataFiles.Count) }
	# 4c. every res:// path named by exported game files is in the pack
	$refRx = [regex]'res://([A-Za-z0-9_\-./ ]+?\.[A-Za-z0-9]{2,8})(?=["''])'
	$missing = @{}; $devRefs = @{}; $newerRefs = @{}; $scanned = 0
	$exeTime = (Get-Item $ExePath).LastWriteTime
	foreach ($g in $GameFolders) {
		$gp = Join-Path $Root $g
		if (-not (Test-Path $gp)) { continue }
		foreach ($f in (Get-ChildItem $gp -Recurse -File -Include *.gd, *.tscn, *.tres, *.gdshader -ErrorAction SilentlyContinue)) {
			if ($f.FullName -match '\\art\\preview\\') { continue }
			$scanned++
			$from = Norm-Res $f.FullName.Substring($rootFull.Length)
			$txt = [IO.File]::ReadAllText($f.FullName)
			foreach ($m in $refRx.Matches($txt)) {
				$rel = $m.Groups[1].Value
				if ($rel -match '^(docs|tools|tests)/') { $devRefs["$rel <- $from"] = 1; continue }
				if (-not (Test-Path -LiteralPath (Join-Path $Root $rel))) { continue }   # dangling refs are the Data Lab's job
				if (-not (In-Pck $rel)) {
					# Files (or referrers) changed after the exe was written are not an export problem: the repo moved on.
					if ((Get-Item -LiteralPath (Join-Path $Root $rel)).LastWriteTime -gt $exeTime -or $f.LastWriteTime -gt $exeTime) { $newerRefs[$rel] = $from }
					elseif (-not $missing.ContainsKey($rel)) { $missing[$rel] = $from }
				}
			}
		}
	}
	if ($missing.Count -gt 0) { Add-Check "Filter: referenced files ship" "FAIL" ("{0} files referenced by game code are not in the pack, e.g. {1}" -f $missing.Count, (($missing.Keys | Select-Object -First 4 | ForEach-Object { "$_ (from $($missing[$_]))" }) -join ', ')) "Check the include / exclude filters for these paths." }
	else { Add-Check "Filter: referenced files ship" "PASS" "every existing res:// path named in $scanned game .gd/.tscn/.tres/.gdshader files is in the pack" }
	if ($newerRefs.Count -gt 0) { Add-Check "Repo changed since the build" "INFO" ("{0} referenced files are not in the pack but were added / changed after the exe ({1}), e.g. {2}" -f $newerRefs.Count, $exeTime.ToString("HH:mm"), (($newerRefs.Keys | Select-Object -First 3) -join ', ')) }
	# Preview / lab scripts (art previews that save screenshots into docs/) are expected to name docs/ paths.
	$devReal = @($devRefs.Keys | Where-Object { $_ -notmatch '<- \S*(preview|_lab|screenshot|_shots?|render_|/tools/)\S*\.(gd|tscn)$' })
	$devTool = $devRefs.Count - $devReal.Count
	if ($devReal.Count -gt 0) { Add-Check "Filter: game code uses dev folders" "WARN" ("{0} references from game code into docs/ tools/ tests/ (excluded from the build), e.g. {1}" -f $devReal.Count, (($devReal | Select-Object -First 3) -join '; ')) "Game code must not load from excluded folders (guard it or move the file)." }
	if ($devTool -gt 0) { Add-Check "Preview scripts in the build" "INFO" ("{0} docs/ paths named by art preview / lab scripts (screenshot outputs; they ship but never run in the game)" -f $devTool) }
	# 4d. main scene + autoloads
	$pg = Get-Content (Join-Path $Root "project.godot") -Encoding UTF8
	$need = @()
	foreach ($l in $pg) {
		if ($l -match '^run/main_scene="res://([^"]+)"') { $need += $Matches[1] }
		if ($l -match '^[A-Za-z0-9_]+="\*?res://([^"]+)"') { $need += $Matches[1] }
	}
	$missNeed = @($need | Where-Object { -not (In-Pck $_) })
	if ($missNeed.Count -gt 0) { Add-Check "Main scene + autoloads" "FAIL" ("missing from the pack: " + ($missNeed -join ', ')) }
	else { Add-Check "Main scene + autoloads" "PASS" ("in the pack: " + ($need -join ', ')) }
	# 4e. runtime folder listing (exports list *.remap / *.import names, not the source names)
	$dirUsers = @()
	foreach ($g in @("scripts", "missions", "scenes")) {
		$gp = Join-Path $Root $g
		if (-not (Test-Path $gp)) { continue }
		foreach ($f in (Get-ChildItem $gp -Recurse -File -Filter *.gd -ErrorAction SilentlyContinue)) {
			$t = [IO.File]::ReadAllText($f.FullName)
			if ($t -match 'DirAccess\.(open|get_files_at|get_directories_at)\s*\(\s*"res://' -and $t -notmatch 'remap|ResourceLoader\.list_directory') { $dirUsers += (Norm-Res $f.FullName.Substring($rootFull.Length)) }
		}
	}
	if ($dirUsers.Count -gt 0) { Add-Check "Runtime folder listing" "WARN" ("{0} scripts list res:// folders with DirAccess without .remap handling: {1}" -f $dirUsers.Count, (($dirUsers | Select-Object -First 4) -join ', ')) "In exports the listing shows x.tres.remap / x.png.import: strip the suffix or use ResourceLoader.list_directory()." }
	else { Add-Check "Runtime folder listing" "PASS" "no res:// DirAccess listing without .remap handling" }
} elseif ($exportOk) { Add-Check "Filter: pack contents" "WARN" "no pack listing, content checks skipped" }

# ---------- 5. smoke test on the exported build ----------
$bootInfo = $null; $smokeInfo = $null; $smokeLine = ""
$runExe = $ConsoleExe; if (-not (Test-Path $runExe)) { $runExe = $ExePath }
if ($exportOk -and -not $AnalyzeOnly) {
	if (-not (Test-Path $ConsoleExe)) {
		# export_console_wrapper: 0 = none, 1 = debug exports only (this preset), 2 = debug + release.
		if (-not $ExportDebug -and $P["options.debug/export_console_wrapper"] -ne "2") { Add-Check "Console wrapper" "INFO" "none for release exports (preset debug/export_console_wrapper=1); the lab reads the GUI exe's redirected output" }
		else { Add-Check "Console wrapper" "WARN" "$baseName.console.exe missing: logs come from the GUI exe" "Set debug/export_console_wrapper in the preset." }
	}
	if (-not $SkipBoot) {
		Write-Host "BUILD LAB: boot check (exported exe, main menu, $BootFrames frames)..."
		$bootLog = Join-Path $LogDir "boot.log"
		$bootInfo = Invoke-Logged $runExe @("--headless", "--fixed-fps", "60", "--quit-after", "$BootFrames") $bootLog $RunTimeoutSec $false
		$be = @(Get-LogErrors $bootLog)
		if ($bootInfo.timed_out) { Add-Check "Boot (exported)" "FAIL" "hung, killed after $RunTimeoutSec s (logs/boot.log)" }
		elseif ($bootInfo.exit -ne 0) { Add-Check "Boot (exported)" "FAIL" "exit $($bootInfo.exit) after $($bootInfo.seconds) s (logs/boot.log)" "Run the exe from a console and read logs/boot.log." }
		elseif ($be.Count -gt 0) { Add-Check "Boot (exported)" "FAIL" ("main scene boots but {0} unique error lines, first: {1}" -f $be.Count, $be[0]) "Errors that only happen in the export: missing files (filter), .remap listing, editor-only APIs." }
		else { Add-Check "Boot (exported)" "PASS" "main menu ran $BootFrames frames headless, exit 0, no errors ($($bootInfo.seconds) s)" }
	}
	if (-not $SkipSmoke) {
		# tests/ is excluded from the build, so the smoke script runs from a copy next to the build (absolute path).
		# Release templates ignore -s (checked 2026-09-26: they boot the main menu instead), so the smoke runs the
		# EXPORTED PACK with the Godot console exe: --main-pack <exported exe> (the pack is embedded; no --path, cwd =
		# the build folder, so nothing comes from the repo: scripts are the exported .gdc, scenes the converted .scn).
		$smokeDir = Join-Path $BuildDir "smoke"
		New-Item -ItemType Directory -Force $smokeDir | Out-Null
		Copy-Item (Join-Path $Root "tests\smoke_test.gd") (Join-Path $smokeDir "smoke_test.gd") -Force
		$smokeScript = (Join-Path $smokeDir "smoke_test.gd") -replace '\\', '/'
		Write-Host "BUILD LAB: gameplay smoke on the exported pack (--main-pack, tests/smoke_test.gd, cap $SmokeFrames frames)..."
		$smokeLog = Join-Path $LogDir "smoke.log"
		$packArg = $pckPath; if (-not $packArg) { $packArg = $ExePath }
		$smokeInfo = Invoke-Logged $GodotExe @("--headless", "--main-pack", $packArg, "-s", $smokeScript, "--fixed-fps", "60", "--quit-after", "$SmokeFrames") $smokeLog $RunTimeoutSec $true
		$se = @(Get-LogErrors $smokeLog)
		$sl = @(Get-Content $smokeLog -Encoding UTF8 -ErrorAction SilentlyContinue)
		$go = @($sl | Where-Object { $_ -match 'GAME OVER' } | Select-Object -Last 1)
		if ($go.Count -gt 0) { $smokeLine = $go[0].Trim() }
		$vic = @($sl | Where-Object { $_ -match 'victory=true' }).Count -gt 0
		if ($smokeInfo.timed_out) { Add-Check "Smoke (exported)" "FAIL" "hung, killed after $RunTimeoutSec s (logs/smoke.log)" }
		elseif (@($sl | Where-Object { $_ -match "Can't load script|Unrecognized command line|Failed loading script|Cannot open resource pack|Couldn't load project data" }).Count -gt 0) { Add-Check "Smoke (exported)" "FAIL" "the script or the exported pack did not load (logs/smoke.log)" "Read logs/smoke.log (pack path, script copy)." }
		elseif (@($sl | Where-Object { $_ -match "Navigation baked|FAIL:" }).Count -eq 0 -and -not $vic) { Add-Check "Smoke (exported)" "FAIL" ("the smoke script never reported (exit {0}, {1} s): -s ignored or main scene failed" -f $smokeInfo.exit, $smokeInfo.seconds) "Read logs/smoke.log." }
		elseif (-not $vic) { Add-Check "Smoke (exported)" "FAIL" ("no victory=true (exit {0}, {1} s): {2}" -f $smokeInfo.exit, $smokeInfo.seconds, $(if ($smokeLine) { $smokeLine } else { "no GAME OVER line" })) "Compare with the editor smoke test; if that passes, the export is missing something (logs/smoke.log)." }
		elseif ($se.Count -gt 0) { Add-Check "Smoke (exported)" "WARN" ("victory=true but {0} unique error lines, first: {1}" -f $se.Count, $se[0]) "Feed logs/smoke.log to the Error Lab (-Logs)." }
		else { Add-Check "Smoke (exported)" "PASS" ("$smokeLine ($($smokeInfo.seconds) s, exit $($smokeInfo.exit))") }
	} else { Add-Check "Smoke (exported)" "INFO" "skipped (-SkipSmoke)" }
}

# ---------- 6. zip + OneDrive command (printed, never run) ----------
$zipPath = ""; $zipBytes = [int64]0
$dateTag = Get-Date -Format "yyyy-MM-dd"
if ($exportOk -and -not $SkipZip -and -not $AnalyzeOnly) {
	$zipPath = Join-Path $BuildDir "$baseName-$dateTag.zip"
	if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
	Write-Host "BUILD LAB: zipping $GameDir..."
	$zs = Get-Date
	[IO.Compression.ZipFile]::CreateFromDirectory($GameDir, $zipPath, [IO.Compression.CompressionLevel]::Optimal, $false)
	$zipBytes = (Get-Item $zipPath).Length
	Add-Check "Zip" "PASS" ("{0} ({1}, {2:N0} s)" -f $zipPath, (Fmt-MB $zipBytes), ((Get-Date) - $zs).TotalSeconds)
}
$oneDriveCmd = ""
if ($zipPath) { $oneDriveCmd = "Copy-Item -LiteralPath `"$zipPath`" -Destination `"`$env:USERPROFILE\OneDrive\$baseName-$dateTag.zip`" -Force" }

# ---------- 7. score + scorecard ----------
$nFail = @($Checks | Where-Object { $_.status -eq "FAIL" }).Count
$nWarn = @($Checks | Where-Object { $_.status -eq "WARN" }).Count
$score = 100
foreach ($c in $Checks) {
	if ($c.status -eq "FAIL") { if ($c.check -match '^(Export|Boot|Smoke)') { $score -= 40 } else { $score -= 20 } }
	elseif ($c.status -eq "WARN") { $score -= 5 }
}
if (-not $exportOk) { $score = 0 }
$score = [math]::Max(0, $score)
$result = "PASS"; if ($nFail -gt 0) { $result = "FAIL" } elseif ($nWarn -gt 0) { $result = "WARN" }
$now = Get-Date -Format "yyyy-MM-dd HH:mm"
function Esc([string]$s) { return ($s -replace '\|', '\|') }
$md = New-Object System.Collections.Generic.List[string]
$md.Add("# Build Lab scorecard: $Run"); $md.Add("")
$md.Add("$now - lab v$LabVersion - preset **$($P.name)** ($(if ($ExportDebug) { 'debug' } else { 'release' })) - build: ``$BuildDir``"); $md.Add("")
$md.Add("## Result: **$result** - score **$score / 100**"); $md.Add("")
$md.Add("$nFail FAIL - $nWarn WARN. Score = 100 - 40 per failed export / boot / smoke - 20 per other FAIL - 5 per WARN (0 if the export failed)."); $md.Add("")
$md.Add("## Improve next")
$k = 1
$sevRank = @{ "FAIL" = 0; "WARN" = 1 }
foreach ($c in @($Checks | Where-Object { $_.status -eq "FAIL" -or $_.status -eq "WARN" } | Sort-Object @{ e = { $sevRank[$_.status] } } | Select-Object -First 3)) {
	$md.Add("$k. **$($c.check)** ($($c.status)): $(Esc $c.detail)$(if ($c.fix) { ' -> ' + (Esc $c.fix) })"); $k++
}
if ($k -eq 1) {
	foreach ($t in @($top | Select-Object -First 2)) { $md.Add("$k. Biggest file: ``$($t.source)`` $(Fmt-MB $t.size) - check its import settings (size / compression) if the build must shrink."); $k++ }
	if ($k -eq 1) { $md.Add("1. Nothing: every check passed.") }
}
$md.Add("")
$md.Add("## Checks")
$md.Add("| Check | Result | Detail |"); $md.Add("|---|---|---|")
foreach ($c in $Checks) { $md.Add("| $($c.check) | $(if ($c.status -eq 'FAIL') { '**FAIL**' } else { $c.status }) | $(Esc $c.detail) |") }
$md.Add("")
$md.Add("## Sizes")
$md.Add("| Item | Size | Previous ($(if ($prev) { $prev.run } else { 'none' })) | Delta |"); $md.Add("|---|---|---|---|")
function SizeRow([string]$n, [int64]$b, $pb) { if ($null -ne $pb -and $pb -gt 0) { return "| $n | $(Fmt-MB $b) | $(Fmt-MB $pb) | $(Fmt-Delta ($b - $pb)) |" } else { return "| $n | $(Fmt-MB $b) | - | - |" } }
$md.Add((SizeRow "$exeName (with embedded pack)" $exeBytes $(if ($prev) { [int64]$prev.exe_bytes } else { $null })))
$md.Add((SizeRow "pack" $pckBytes $(if ($prev) { [int64]$prev.pck_bytes } else { $null })))
$md.Add((SizeRow "engine part (exe - pack)" ($exeBytes - $pckBytes) $(if ($prev) { [int64]$prev.exe_bytes - [int64]$prev.pck_bytes } else { $null })))
if ($consoleBytes -gt 0) { $md.Add("| $baseName.console.exe | $("{0:N0} KB" -f ($consoleBytes / 1KB)) | - | - |") }
if ($zipBytes -gt 0) { $md.Add((SizeRow "zip" $zipBytes $(if ($prev -and $prev.zip_bytes) { [int64]$prev.zip_bytes } else { $null }))) }
if ($pck) { $md.Add("| files in pack | $($pck.files.Count) | $(if ($prev) { $prev.files } else { '-' }) | $(if ($prev) { $pck.files.Count - [int]$prev.files } else { '-' }) |") }
$md.Add("")
if ($catRows.Count -gt 0) {
	$md.Add("## Pack by folder")
	$md.Add("| Folder | Size | Files | Share |"); $md.Add("|---|---|---|---|")
	foreach ($c in $catRows) { $md.Add(("| {0} | {1} | {2} | {3:N1}% |" -f $c.category, (Fmt-MB $c.bytes), $c.files, (100.0 * $c.bytes / [math]::Max(1, $pckBytes)))) }
	$md.Add("")
	$md.Add("## Biggest files (top $TopN)")
	$md.Add("| # | Source | Packed as | Size |"); $md.Add("|---|---|---|---|")
	$k = 1
	foreach ($t in $top) { $md.Add("| $k | $(Esc $t.source) | $(Esc $t.path) | $(Fmt-MB $t.size) |"); $k++ }
	$md.Add("")
}
if ($growers.Count -gt 0) {
	$md.Add("## Changed files vs previous build ($($prev.run), biggest changes)")
	$md.Add("| Source | Before | After | Delta | Note |"); $md.Add("|---|---|---|---|---|")
	foreach ($g in $growers) { $md.Add("| $(Esc $g.source) | $(Fmt-MB $g.before) | $(Fmt-MB $g.after) | $(Fmt-Delta $g.delta) | $($g.note) |") }
	$md.Add("")
}
$md.Add("## Playtest copy (the lab never copies to OneDrive)")
if ($zipPath) {
	$md.Add("Zip ready: ``$zipPath``. **Ask the user first**, then the lead runs:")
	$md.Add('```powershell'); $md.Add($oneDriveCmd); $md.Add('```')
} else { $md.Add("No zip this run.") }
$md.Add("")
$md.Add("Logs: ``$LogDir``. Re-run: ``tools\build_lab\build_lab.ps1`` (see docs/plan/build-lab.md).")
[IO.File]::WriteAllLines((Join-Path $OutDir "scorecard.md"), $md, $Utf8)

$json = [pscustomobject]@{
	lab = "build_lab"; version = $LabVersion; run = $Run; time = $now; result = $result; score = $score
	preset = $P.name; release = (-not $ExportDebug); build_dir = $BuildDir; exe = $ExePath; zip = $zipPath
	exe_bytes = $exeBytes; pck_bytes = $pckBytes; zip_bytes = $zipBytes; files = $(if ($pck) { $pck.files.Count } else { 0 })
	export_seconds = $exportInfo.seconds; boot = $bootInfo; smoke = $smokeInfo; smoke_line = $smokeLine
	checks = @($Checks); categories = @($catRows); top = @($top | Select-Object path, source, size)
	changed_vs_previous = @($growers); previous_run = $(if ($prev) { $prev.run } else { "" })
	onedrive_command = $oneDriveCmd
	improve_next = @($Checks | Where-Object { $_.status -eq "FAIL" -or $_.status -eq "WARN" } | Select-Object -First 3 | ForEach-Object { "$($_.check): $($_.detail)" })
}
[IO.File]::WriteAllText((Join-Path $OutDir "scorecard.json"), ($json | ConvertTo-Json -Depth 6), $Utf8)

if (-not $NoHistory -and $exeBytes -gt 0) {
	$h = [pscustomobject]@{ run = $Run; time = $now; result = $result; score = $score; build_dir = $BuildDir; exe_bytes = $exeBytes
		pck_bytes = $pckBytes; zip_bytes = $zipBytes; files = $(if ($pck) { $pck.files.Count } else { 0 }); smoke = $smokeLine
		fails = $nFail; warns = $nWarn; top = @($top | Select-Object -First 10 path, size) }
	New-Item -ItemType Directory -Force (Split-Path $HistoryFile) | Out-Null
	[IO.File]::AppendAllText($HistoryFile, ($h | ConvertTo-Json -Depth 4 -Compress) + "`n", $Utf8)
}

Write-Host ""
Write-Host "BUILD LAB: $result score $score / 100 ($nFail FAIL, $nWarn WARN) - exe $(Fmt-MB $exeBytes), pack $(Fmt-MB $pckBytes)$(if ($zipBytes) { ', zip ' + (Fmt-MB $zipBytes) })"
foreach ($c in @($Checks | Where-Object { $_.status -eq "FAIL" -or $_.status -eq "WARN" } | Select-Object -First 3)) { Write-Host "  $($c.status) $($c.check): $($c.detail)" }
Write-Host "  scorecard: $(Join-Path $OutDir 'scorecard.md')"
if ($zipPath) {
	Write-Host "  zip ready: $zipPath"
	Write-Host "  OneDrive copy NOT done. After the user says yes, the lead runs:"
	Write-Host "    $oneDriveCmd"
}
if ($result -eq "FAIL") { exit 1 }
exit 0
