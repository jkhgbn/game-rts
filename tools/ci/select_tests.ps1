# Changed-only test selection for the fast CI (tools/ci/ci_quick.ps1 -Changed). Windows PowerShell 5.1.
# Reads git (diff / ls-files / rev-parse only, never changes anything), maps each changed file to the tests that name
# it, adds the core set, and prints which tests it picked and why. Docs: docs/plan/error-lab.md "Fast CI".
#
#   tools\ci\select_tests.ps1                       # uncommitted changes (tracked + new files) vs HEAD
#   tools\ci\select_tests.ps1 -Base HEAD~3          # everything since 3 commits ago, plus uncommitted changes
#   tools\ci\select_tests.ps1 -Base last-green      # since the commit of the last PASS / WARN full CI row
#   tools\ci\select_tests.ps1 -Files scripts/units/caster_kit.gd,art/vfx/caster_ice_vfx.gd   # no git
# Output (pipeline): one object { full; base; tests; slow_skipped; reasons; files }. The text report goes to the host.
param(
	[string]$Base = "",
	[string[]]$Files = @(),
	[switch]$IncludeSlow,
	[string]$Root = ""
)
$ErrorActionPreference = "Stop"
if (-not $Root) { $Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path }

# Always run (cheap, cover the shared paths every change can break). The smoke test runs as the CI's smoke step.
$CoreTests = @("test_tiers", "test_ui_card_hotkeys", "test_casters", "test_stables")
# A change here can break any test: fall back to ci_quick's full list. Prefixes (folders end with '/').
$FullTriggers = @("project.godot", "scripts/core/", "scripts/ui/command_card.gd", "scenes/main.tscn", "scenes/skirmish.tscn",
	"scripts/world/main.gd", "scripts/world/skirmish.gd", "scripts/units/unit.gd", "scripts/units/unit_type.gd",
	"scripts/buildings/building.gd", "scripts/buildings/building_type.gd", "scripts/ai/commander.gd", "addons/",
	"tests/_template.gd", "tools/godot_run.ps1")
# Never select tests (text / tooling outside the game). tools/ci and tools/error_lab changes get a hint instead.
$NoTestRx = '^(docs/|\.claude/|\.github/|README|LICENSE|\.gitignore|\.gitattributes|tools/ci/|tools/error_lab/)|\.md$|\.txt$'
# Folder names too generic to stand for a test (the folder fallback skips them).
$GenericDirs = @("art", "units", "buildings", "scripts", "data", "scenes", "vfx", "environment", "tools", "assets", "audio",
	"textures", "models", "materials", "ui", "ai", "world", "core", "items", "spells", "champions", "fire", "ice", "nature",
	"shadow", "neutral", "tests", "common", "src", "lib", "economy", "campaign", "missions", "cinematics", "sfx", "music",
	"voice", "fonts", "icons", "shaders", "meshes", "anims", "animations", "export", "maps", "previews")

function Invoke-Git([string[]]$a) {
	$git = "git"
	if (-not (Get-Command git -ErrorAction SilentlyContinue)) { $git = "C:\Program Files\Git\cmd\git.exe" }
	# PS 5.1: with $ErrorActionPreference = "Stop", redirected native stderr (a CRLF warning...) becomes a terminating
	# error record. Run git with "Continue", drop its stderr lines and judge by the exit code only.
	$eap = $ErrorActionPreference
	$ErrorActionPreference = "Continue"
	try {
		$out = @(& $git -C $Root @a 2>&1 | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } | ForEach-Object { "$_" })
		$code = $LASTEXITCODE
	} finally { $ErrorActionPreference = $eap }
	if ($code -ne 0) { throw "git $($a -join ' ') failed (exit $code)" }
	return @($out)
}

# ---------- the changed files ----------
$baseUsed = ""
if ($Files.Count -gt 0) {
	$changed = @($Files | ForEach-Object { $_ -split ',' } | Where-Object { $_ })
	$baseUsed = "(file list)"
} else {
	if (-not $Base) { $Base = "HEAD" }
	if ($Base -eq "last-green") {
		$Base = ""
		$hist = Join-Path $Root "docs\ci\history.jsonl"
		if (Test-Path $hist) {
			$rows = @(Get-Content $hist -Encoding UTF8 | Where-Object { $_.Trim() } | ForEach-Object { try { $_ | ConvertFrom-Json } catch { $null } } | Where-Object { $_ })
			# Only FULL runs count (ci.ps1 writes scope "full"; -Tests / -SkipTests runs are "subset" / "no-tests", and
			# rows from before the scope field never counted the whole suite for sure).
			$g = @($rows | Where-Object { $_.commit -and $_.scope -eq "full" -and ($_.result -eq "PASS" -or $_.result -eq "WARN") } | Select-Object -Last 1)
			if ($g.Count -gt 0) { $Base = $g[0].commit; Write-Host "select: last green full CI run $($g[0].run) ($($g[0].result)) at $Base" }
		}
		if (-not $Base) { $Base = "HEAD~1"; Write-Host "select: no green full CI row with a commit in docs/ci/history.jsonl yet, using HEAD~1" }
	}
	# A base this clone does not know (a last-green commit from the other machine): HEAD~1 instead of an abort.
	try { $null = Invoke-Git @("rev-parse", "--verify", "--quiet", "$Base^{commit}") }
	catch { Write-Host "select: unknown base '$Base' in this clone, using HEAD~1"; $Base = "HEAD~1" }
	$baseUsed = $Base
	$changed = @(Invoke-Git @("diff", "--name-only", $Base))
	# New files too, except Godot's generated .uid companions (the script itself is listed when it is new).
	$changed += @(Invoke-Git @("ls-files", "--others", "--exclude-standard") | Where-Object { $_ -notmatch '\.uid$' })
}
$changed = @($changed | ForEach-Object { ($_ -replace '\\', '/').Trim() } | Where-Object { $_ } | Sort-Object -Unique)
# An already-committed change diffed against HEAD selects only the core set and looks green: say so.
if ($changed.Count -eq 0 -and $baseUsed -eq "HEAD") {
	Write-Host "select: WARNING no uncommitted change vs HEAD: only the core set runs. Checking a commit? use -Base HEAD~1 (or last-green)." -ForegroundColor Yellow
}

# ---------- the tests and their text ----------
$all = @(Get-ChildItem (Join-Path $Root "tests") -Filter "test_*.gd" | Sort-Object Name)
$text = @{}
foreach ($t in $all) { $text[$t.BaseName] = [IO.File]::ReadAllText($t.FullName) }
$slowFile = Join-Path $Root "tools\ci\slow_tests.txt"
$slow = @()
if (Test-Path $slowFile) { $slow = @(Get-Content $slowFile | ForEach-Object { ($_ -replace '#.*$', '').Trim() } | Where-Object { $_ }) }

$reasons = [ordered]@{}   # test -> list of reasons
function Add-Pick([string]$test, [string]$why) {
	if (-not $text.ContainsKey($test)) { return }
	if (-not $reasons.Contains($test)) { $reasons[$test] = New-Object System.Collections.Generic.List[string] }
	if ($reasons[$test].Count -lt 4 -and -not $reasons[$test].Contains($why)) { $reasons[$test].Add($why) }
}
function Find-Tests([string]$needle, [bool]$word) {
	$hits = @()
	$rx = if ($word) { '(?<![A-Za-z0-9_])' + [regex]::Escape($needle) + '(?![A-Za-z0-9_])' } else { [regex]::Escape($needle) }
	foreach ($k in $text.Keys) { if ($text[$k] -match $rx) { $hits += $k } }
	return @($hits | Sort-Object)
}

# 1. res:// path, 2. class_name (scripts), 3. the base name as a word (>= 4 chars).
function Get-DirectHits([string]$p) {
	$hits = @(); $how = ""
	$h = Find-Tests "res://$p" $false
	if ($h.Count -gt 0) { $hits += $h; $how = "res://$p" }
	$c = Get-ClassName $p
	if ($c) {
		$h = Find-Tests $c $true
		if ($h.Count -gt 0) { $hits += $h; $how = (@($how, "class $c") | Where-Object { $_ }) -join ", " }
	}
	$name = [IO.Path]::GetFileNameWithoutExtension($p)
	if ($name.Length -ge 4) {
		$h = Find-Tests $name $true
		if ($h.Count -gt 0) { $hits += $h; $how = (@($how, "name '$name'") | Where-Object { $_ }) -join ", " }
	}
	return @{ hits = @($hits | Sort-Object -Unique); how = $how }
}
# 3c. Game data (data/units|spells|buildings|items|champions|champion_classes|helpers/<id>.tres): tests pin its numbers
#     through the id (any length, quoted: "id" &"id" 'id', or id.tres), the display name ("Flame Guard"), or by
#     scanning / formatting the whole folder (res://data/units/" + f, res://data/units/%s). Root-cause pass 2026-10-12:
#     the 10-11 balance commits left 6 unit-pin tests red for a day.
$DataDirsRx = '^data/(units|spells|buildings|items|champions|champion_classes|helpers)/([^/]+)\.tres$'
function Get-DataHits([string]$p) {
	if ($p -notmatch $DataDirsRx) { return @{ hits = @(); how = "" } }
	$dir = $Matches[1]; $id = $Matches[2]
	$rxs = [ordered]@{}
	$rxs["id '$id'"] = '(?:["'']' + [regex]::Escape($id) + '["'']|(?<![A-Za-z0-9_])' + [regex]::Escape($id) + '\.tres)'
	$abs = Join-Path $Root $p
	if (Test-Path $abs) {
		$dn = Select-String -Path $abs -Pattern '^display_name\s*=\s*"([^"]+)"' | Select-Object -First 1
		if ($dn) { $rxs["display name '$($dn.Matches[0].Groups[1].Value)'"] = '"' + [regex]::Escape($dn.Matches[0].Groups[1].Value) + '"' }
	}
	$rxs["scans data/$dir"] = 'res://data/' + [regex]::Escape($dir) + '/?(?:"|%s)'
	$hits = @(); $how = @()
	foreach ($k in $rxs.Keys) {
		$h = @(foreach ($t in $text.Keys) { if ($text[$t] -match $rxs[$k]) { $t } })
		if ($h.Count -gt 0) { $hits += $h; $how += $k }
	}
	return @{ hits = @($hits | Sort-Object -Unique); how = ($how -join ", ") }
}
function Get-ClassName([string]$p) {
	$abs = Join-Path $Root $p
	if ($p -notmatch '\.gd$' -or -not (Test-Path $abs)) { return "" }
	$cn = Select-String -Path $abs -Pattern '^class_name\s+(\w+)' | Select-Object -First 1
	if ($cn) { return $cn.Matches[0].Groups[1].Value }
	return ""
}
# Game sources that can load another file: every .gd under scripts/ art/ tools/ missions/, every .tscn under scenes/
# missions/ (read once, only when a file has no direct test).
$script:SrcText = $null
function Get-Referencers([string]$p) {
	Read-Sources
	$needles = @("res://$p")
	$c = Get-ClassName $p
	$out = @()
	foreach ($k in $script:SrcText.Keys) {
		if ($k -eq $p) { continue }
		$t = $script:SrcText[$k]
		if ($t.Contains("res://$p") -or ($c -and $t -match ('(?<![A-Za-z0-9_])' + [regex]::Escape($c) + '(?![A-Za-z0-9_])'))) { $out += $k }
	}
	return @($out | Sort-Object)
}
# The scripts that extend $p (`extends ClassName` or `extends "res://path"`): their tests must run when a base class
# changes (MissionBase -> Mission01 -> test_m7_s1...), even when some test names the base class directly.
function Get-Subclasses([string]$p) {
	if ($p -notmatch '\.gd$') { return @() }
	Read-Sources
	$c = Get-ClassName $p
	$rx = '(?m)^\s*extends\s+(?:"res://' + [regex]::Escape($p) + '"' + $(if ($c) { '|' + [regex]::Escape($c) + '(?![A-Za-z0-9_])' } else { '' }) + ')'
	$out = @()
	foreach ($k in $script:SrcText.Keys) {
		if ($k -ne $p -and $k -match '\.gd$' -and $script:SrcText[$k] -match $rx) { $out += $k }
	}
	return @($out | Sort-Object)
}
function Read-Sources {
	if ($null -eq $script:SrcText) {
		$script:SrcText = @{}
		foreach ($dir in @("scripts", "art", "tools", "missions", "scenes")) {
			$dp = Join-Path $Root $dir
			if (-not (Test-Path $dp)) { continue }
			$filter = if ($dir -eq "scenes" -or $dir -eq "missions") { @("*.gd", "*.tscn") } else { @("*.gd") }
			foreach ($fl in $filter) {
				foreach ($fi in (Get-ChildItem $dp -Recurse -Filter $fl -File)) {
					$rel = $fi.FullName.Substring($Root.Length + 1) -replace '\\', '/'
					$script:SrcText[$rel] = [IO.File]::ReadAllText($fi.FullName)
				}
			}
		}
	}
}

$full = $false
$fullWhy = @()
$notes = New-Object System.Collections.Generic.List[string]
$fileRows = New-Object System.Collections.Generic.List[string]
$docsOnly = 0
foreach ($f in $changed) {
	$p = $f -replace '\.(uid|import)$', ''
	$trigger = @($FullTriggers | Where-Object { $p -eq $_ -or ($_.EndsWith('/') -and $p.StartsWith($_)) } | Select-Object -First 1)
	if ($trigger.Count -gt 0) { $full = $true; $fullWhy += "$f (core: $($trigger[0]))"; $fileRows.Add("  $f -> CORE ($($trigger[0])): full ci_quick list"); continue }
	if ($p -match '^tests/(test_[^/]+)\.gd$') {
		if ($text.ContainsKey($Matches[1])) { Add-Pick $Matches[1] "the test itself changed"; $fileRows.Add("  $f -> $($Matches[1]) (itself)") }
		else { $fileRows.Add("  $f -> (test removed)") }
		continue
	}
	if ($p -match '^tests/(smoke_test|perf_test)\.gd$') { $fileRows.Add("  $f -> the CI smoke / perf steps"); continue }
	if ($p -match $NoTestRx) {
		if ($p -match '^tools/error_lab/') { $notes.Add("tools/error_lab changed: also run powershell -NoProfile -ExecutionPolicy Bypass -File tests\test_error_lab.ps1") }
		$docsOnly++
		continue
	}
	$d = Get-DirectHits $p
	$hits = @($d.hits)
	$how = $d.how
	$dd = Get-DataHits $p
	if (@($dd.hits).Count -gt 0) { $hits += @($dd.hits); $how = (@($how, $dd.how) | Where-Object { $_ }) -join ", " }
	# 3b. Always (even with direct hits): the tests of every script that extends this one, up to 3 levels down
	#     (a base-class change must run its subclasses' regression tests: MissionBase -> Mission01 -> test_m7_s1).
	$subFrontier = @($p); $subSeen = @($p)
	for ($lvl = 1; $lvl -le 3 -and $subFrontier.Count -gt 0; $lvl++) {
		$subs = @()
		foreach ($q in $subFrontier) { $subs += @(Get-Subclasses $q | Where-Object { $subSeen -notcontains $_ }) }
		$subs = @($subs | Sort-Object -Unique)
		foreach ($s in $subs) {
			$sd = Get-DirectHits $s
			if (@($sd.hits).Count -gt 0) { $hits += @($sd.hits); $how = (@($how, "subclass $s") | Where-Object { $_ }) -join ", " }
		}
		$subSeen += $subs
		$subFrontier = $subs
	}
	$hits = @($hits | Sort-Object -Unique)
	# 4. Up to 2 hops: the scripts / scenes that load this file (res:// path or class_name), mapped the same way
	#    (art/vfx/caster_ice_wall.gdshader -> art/vfx/caster_ice_vfx.gd -> art/vfx/unit_vfx.gd -> tests naming UnitVfx).
	$frontier = @($p)
	$seenRefs = @($p)
	for ($hop = 1; $hop -le 2 -and $hits.Count -eq 0 -and $frontier.Count -gt 0; $hop++) {
		$next = @()
		foreach ($q in $frontier) { $next += @(Get-Referencers $q | Where-Object { $seenRefs -notcontains $_ }) }
		$next = @($next | Sort-Object -Unique)
		if ($next.Count -gt 12) { $notes.Add("$f is loaded by $($next.Count) files at hop $($hop): mapping stops (too wide)"); break }
		foreach ($r in $next) {
			$rd = Get-DirectHits $r
			if (@($rd.hits).Count -gt 0) { $hits += @($rd.hits); $how = (@($how, "via $r") | Where-Object { $_ }) -join ", " }
		}
		$seenRefs += $next
		$frontier = $next
	}
	# 5. Nothing names the file: the nearest specific folder (art/units/fire/kilnwarden/x.png -> 'kilnwarden').
	if ($hits.Count -eq 0) {
		$dirs = @(($p -split '/') | Select-Object -SkipLast 1)
		[array]::Reverse($dirs)
		foreach ($dn in ($dirs | Select-Object -First 3)) {
			if ($GenericDirs -contains $dn.ToLower() -or $dn.Length -lt 4) { continue }
			$h = Find-Tests $dn $true
			if ($h.Count -gt 0) { $hits += $h; $how = "folder '$dn'"; break }
		}
		if ($hits.Count -eq 0 -and $p -match '^tools/([^/]+)/' -and $text.ContainsKey("test_$($Matches[1])")) { $hits += "test_$($Matches[1])"; $how = "tool folder" }
	}
	$hits = @($hits | Sort-Object -Unique)
	foreach ($t in $hits) { Add-Pick $t "$f ($how)" }
	if ($hits.Count -eq 0) { $fileRows.Add("  $f -> no test names it") }
	else { $fileRows.Add("  $f -> $($hits.Count) test(s): $how") }
}
foreach ($t in $CoreTests) { Add-Pick $t "core set (always)" }

if ($full) {
	$tests = @($all | ForEach-Object { $_.BaseName } | Where-Object { $slow -notcontains $_ })
	$slowSkipped = @($slow | Where-Object { $text.ContainsKey($_) })
	# A slow test whose own file changed always runs.
	$own = @($slowSkipped | Where-Object { $reasons.Contains($_) -and $reasons[$_].Contains("the test itself changed") })
	if ($IncludeSlow) { $own = $slowSkipped }
	$tests += $own
	$slowSkipped = @($slowSkipped | Where-Object { $own -notcontains $_ })
} else {
	$picked = @($reasons.Keys)
	$slowSkipped = @()
	if (-not $IncludeSlow) {
		$slowSkipped = @($picked | Where-Object { $slow -contains $_ -and -not $reasons[$_].Contains("the test itself changed") })
		$picked = @($picked | Where-Object { $slowSkipped -notcontains $_ })
	}
	$tests = @($picked | Sort-Object)
}

# ---------- report ----------
Write-Host ("select: base {0}, {1} changed file(s)" -f $baseUsed, $changed.Count)
foreach ($r in ($fileRows | Select-Object -First 60)) { Write-Host $r }
if ($fileRows.Count -gt 60) { Write-Host "  ... +$($fileRows.Count - 60) more files" }
if ($docsOnly -gt 0) { Write-Host "  + $docsOnly docs / CI-tooling file(s): no test" }
if ($full) {
	Write-Host ("select: FULL ci_quick list ({0} tests): core file(s) changed: {1}" -f $tests.Count, (($fullWhy | Select-Object -First 3) -join "; "))
} else {
	Write-Host ("select: {0} of {1} tests:" -f $tests.Count, $all.Count)
	foreach ($t in $tests) { Write-Host ("  {0,-28} {1}" -f $t, ($reasons[$t] -join " | ")) }
}
if ($slowSkipped.Count -gt 0) { Write-Host ("select: slow, not run (add -IncludeSlow): {0}" -f ($slowSkipped -join ", ")) }
foreach ($n in $notes | Sort-Object -Unique) { Write-Host "select: note: $n" }
[pscustomobject]@{ full = $full; base = $baseUsed; tests = $tests; slow_skipped = $slowSkipped; files = $changed
	reasons = $(if ($full) { @{} } else { $reasons }) }
