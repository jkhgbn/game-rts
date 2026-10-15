# Changed-only test selection for the fast CI (tools/ci/ci_quick.ps1 -Changed). Windows PowerShell 5.1.
# Reads git (diff / ls-files / rev-parse only, never changes anything), then picks the tests that statically REACH a
# changed file (tools/ci/dep_index.ps1: res:// loads, scenes, `Foo.new()`, static calls, constants, data ids; cached
# by file hash), adds the core set, and says why each test was picked. Docs: docs/plan/error-lab.md "Fast CI".
# Two modes (measured 2026-10-14, see the ci-suite skill):
#   near  (default) the tests within -NearHops (3) dependency hops of a changed file. In this codebase ~330 of the 501
#         tests boot a level, and a level reaches ~60 % of the scripts, so "every reaching test" is most of the suite
#         for any gameplay file; the 4+ hop tests only run the file as part of a whole level (the smoke step does that).
#   reach every test whose reach includes a changed file (the safe set; milestone-like).
# Either way a file whose picked tests exceed -WideShare (50 %) of the suite is reported as WIDE with its count, and
# its tests are picked (never the whole list by name). Only project.godot and the Godot gate mean "the full list".
#
#   tools\ci\select_tests.ps1                       # uncommitted changes (tracked + new files) vs HEAD
#   tools\ci\select_tests.ps1 -Base HEAD~3          # everything since 3 commits ago, plus uncommitted changes
#   tools\ci\select_tests.ps1 -Base last-green      # since the commit of the last PASS / WARN full CI row
#   tools\ci\select_tests.ps1 -Base HEAD~1 -Head HEAD   # exactly one commit (no working tree)
#   tools\ci\select_tests.ps1 -Files scripts/units/caster_kit.gd,art/vfx/caster_ice_vfx.gd   # no git
#   ... -Explain                                    # one line per picked test: the changed file and the chain to it
#   ... -Mode reach                                 # every reaching test (slower, safest)
#   ... -NearHops 2                                 # near mode: a tighter radius
# Output (pipeline): one object { full; base; tests; slow_skipped; reasons; files; wide; index_s }. Text goes to the host.
param(
	[string]$Base = "",
	[string]$Head = "",
	[string[]]$Files = @(),
	[switch]$IncludeSlow,
	[string]$Root = "",
	[switch]$Explain,
	[ValidateSet("near", "reach")][string]$Mode = "near",
	[int]$NearHops = 3,
	[double]$WideShare = 0.5,
	[int]$MaxStatic = 2,
	[switch]$Quiet
)
$ErrorActionPreference = "Stop"
if (-not $Root) {
	# The repo root: the first folder up from this script with a project.godot (works from tools/ci and from a copy).
	$d = $PSScriptRoot
	while ($d -and -not (Test-Path (Join-Path $d "project.godot"))) { $d = Split-Path $d -Parent }
	$Root = $d
}
$Root = (Resolve-Path $Root).Path.TrimEnd('\')
. (Join-Path $PSScriptRoot "dep_index.ps1")

# Always run (cheap, cover the shared paths every change can break). Smoke and perf run as the CI's own steps.
$CoreTests = @("test_save_metas", "test_i18n", "test_tiers", "test_ui_card_hotkeys", "test_casters", "test_stables")
# A change here can break any test whatever reaches it (engine settings, input map, the Godot gate): full list.
$FullTriggers = @("project.godot", "tools/godot_run.ps1")
# Never select tests (text / tooling outside the game). tools/ci and tools/error_lab changes get a hint instead.
$NoTestRx = '^(docs/|\.claude/|\.github/|README|LICENSE|\.gitignore|\.gitattributes|tools/ci/|tools/error_lab/|tools/git_hooks/)|\.md$|\.txt$'
# Folder names too generic to stand for a test (the name fallback skips them).
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
function Say([string]$s, [string]$color = "") {
	if ($Quiet) { return }
	if ($color) { Write-Host $s -ForegroundColor $color } else { Write-Host $s }
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
			if ($g.Count -gt 0) { $Base = $g[0].commit; Say "select: last green full CI run $($g[0].run) ($($g[0].result)) at $Base" }
		}
		if (-not $Base) { $Base = "HEAD~1"; Say "select: no green full CI row with a commit in docs/ci/history.jsonl yet, using HEAD~1" }
	}
	# A base this clone does not know (a last-green commit from the other machine): HEAD~1 instead of an abort.
	try { $null = Invoke-Git @("rev-parse", "--verify", "--quiet", "$Base^{commit}") }
	catch { Say "select: unknown base '$Base' in this clone, using HEAD~1"; $Base = "HEAD~1" }
	$baseUsed = $Base
	if ($Head) {
		$changed = @(Invoke-Git @("diff", "--name-only", $Base, $Head))
		$baseUsed = "$Base..$Head"
	} else {
		$changed = @(Invoke-Git @("diff", "--name-only", $Base))
		# New files too, except Godot's generated .uid companions (the script itself is listed when it is new).
		$changed += @(Invoke-Git @("ls-files", "--others", "--exclude-standard") | Where-Object { $_ -notmatch '\.uid$' })
	}
}
$changed = @($changed | ForEach-Object { ($_ -replace '\\', '/').Trim() } | Where-Object { $_ } | Sort-Object -Unique)
# An already-committed change diffed against HEAD selects only the core set and looks green: say so.
if ($changed.Count -eq 0 -and $baseUsed -eq "HEAD") {
	Say "select: WARNING no uncommitted change vs HEAD: only the core set runs. Checking a commit? use -Base HEAD~1 (or last-green)." "Yellow"
}

# ---------- the tests ----------
$all = @(Get-ChildItem (Join-Path $Root "tests") -Filter "test_*.gd" | Sort-Object Name | ForEach-Object { $_.BaseName })
$isTest = @{}; foreach ($t in $all) { $isTest[$t] = $true }
$slowFile = Join-Path $Root "tools\ci\slow_tests.txt"
$slow = @()
if (Test-Path $slowFile) { $slow = @(Get-Content $slowFile | ForEach-Object { ($_ -replace '#.*$', '').Trim() } | Where-Object { $_ }) }
$ix = $null
$text = $null   # test texts, read only for the name fallback
function Get-Index {
	if ($null -eq $script:ix) { $script:ix = Get-DepIndex -Root $Root -Quiet; $script:ix.Graph.MaxStatic = $MaxStatic }
	return $script:ix
}

$reasons = [ordered]@{}   # test -> list of reasons
function Add-Pick([string]$test, [string]$why) {
	if (-not $isTest.ContainsKey($test)) { return }
	if (-not $reasons.Contains($test)) { $reasons[$test] = New-Object System.Collections.Generic.List[string] }
	if ($reasons[$test].Count -lt 3 -and -not $reasons[$test].Contains($why)) { $reasons[$test].Add($why) }
}
# Last resort for a file nothing reaches (an image loaded by a computed name...): tests naming its base name or its
# nearest specific folder as a word, or the tool folder's own test.
function Get-NameFallback([string]$p) {
	if ($null -eq $script:text) {
		$script:text = @{}
		foreach ($t in $all) { $script:text[$t] = [IO.File]::ReadAllText((Join-Path $Root "tests\$t.gd")) }
	}
	$name = [IO.Path]::GetFileNameWithoutExtension($p)
	$cands = @()
	if ($name.Length -ge 4) { $cands += @{ needle = $name; how = "names '$name'" } }
	$dirs = @(($p -split '/') | Select-Object -SkipLast 1); [array]::Reverse($dirs)
	foreach ($dn in ($dirs | Select-Object -First 3)) {
		if ($GenericDirs -contains $dn.ToLower() -or $dn.Length -lt 4) { continue }
		$cands += @{ needle = $dn; how = "names folder '$dn'" }
	}
	foreach ($c in $cands) {
		$rx = '(?<![A-Za-z0-9_])' + [regex]::Escape($c.needle) + '(?![A-Za-z0-9_])'
		$hits = @($script:text.Keys | Where-Object { $script:text[$_] -match $rx } | Sort-Object)
		if ($hits.Count -gt 0) { return @{ hits = $hits; how = $c.how } }
	}
	if ($p -match '^tools/([^/]+)/' -and $isTest.ContainsKey("test_$($Matches[1])")) { return @{ hits = @("test_$($Matches[1])"); how = "tool folder" } }
	return @{ hits = @(); how = "" }
}

$full = $false
$fullWhy = @()
$notes = New-Object System.Collections.Generic.List[string]
$fileRows = New-Object System.Collections.Generic.List[string]
$wideRows = New-Object System.Collections.Generic.List[object]
$docsOnly = 0
$wideLimit = [math]::Max(1, [math]::Floor($WideShare * $all.Count))
foreach ($f in $changed) {
	$p = $f -replace '\.(uid|import)$', ''
	$trigger = @($FullTriggers | Where-Object { $p -eq $_ -or ($_.EndsWith('/') -and $p.StartsWith($_)) } | Select-Object -First 1)
	if ($trigger.Count -gt 0) { $full = $true; $fullWhy += "$f"; $fileRows.Add("  $f -> GLOBAL ($($trigger[0])): full ci_quick list"); continue }
	if ($p -match '^tests/(smoke_test|perf_test)\.gd$') { $fileRows.Add("  $f -> the CI smoke / perf steps"); continue }
	if ($p -match $NoTestRx) {
		if ($p -match '^tools/error_lab/') { $notes.Add("tools/error_lab changed: also run powershell -NoProfile -ExecutionPolicy Bypass -File tests\test_error_lab.ps1") }
		if ($p -match '^tools/ci/') { $notes.Add("tools/ci changed: also run powershell -NoProfile -ExecutionPolicy Bypass -File tools\ci\test_select_tests.ps1") }
		$docsOnly++
		continue
	}
	$own = ""
	if ($p -match '^tests/(test_[^/]+)\.gd$') {
		$own = $Matches[1]
		if ($isTest.ContainsKey($own)) { Add-Pick $own "the test itself changed" } else { $fileRows.Add("  $f -> (test removed)") }
	}
	$x = Get-Index
	$hits = Get-ReachingTests $x $p
	$n = $hits.Count
	if ($n -eq 0 -and -not $own) {
		$fb = Get-NameFallback $p
		foreach ($t in $fb.hits) { Add-Pick $t "$f (nothing loads it; $($fb.how))" }
		if (@($fb.hits).Count -eq 0) { $fileRows.Add("  $f -> nothing reaches it, no test names it") }
		else { $fileRows.Add("  $f -> nothing reaches it; name fallback: $(@($fb.hits).Count) test(s) ($($fb.how))") }
		continue
	}
	$picked = @($hits.Keys)
	if ($Mode -eq "near") { $picked = @($hits.Keys | Where-Object { $hits[$_].hops -le $NearHops }) }
	$row = "  $f -> reached by $n test(s)" + $(if ($Mode -eq "near") { ", $($picked.Count) within $NearHops hops" } else { "" })
	if ($picked.Count -gt $wideLimit) {
		$pct = [math]::Round(100.0 * $picked.Count / $all.Count)
		$row += " WIDE ($pct % of the tests > $([math]::Round(100 * $WideShare)) %): all $($picked.Count) picked"
		$wideRows.Add([pscustomobject]@{ file = $f; reached = $n; picked = $picked.Count; share = $pct })
	}
	foreach ($t in $picked) {
		$h = $hits[$t]
		$chain = $h.chain
		if ($chain.Length -gt 220) { $chain = $chain.Substring(0, 217) + "..." }
		Add-Pick $t ("{0} ({1} hop{2}: {3})" -f $f, $h.hops, $(if ($h.hops -eq 1) { "" } else { "s" }), $chain)
	}
	$fileRows.Add($row)
}
foreach ($t in $CoreTests) { Add-Pick $t "core set (always)" }

if ($full) {
	$tests = @($all | Where-Object { $slow -notcontains $_ })
	$slowSkipped = @($slow | Where-Object { $isTest.ContainsKey($_) })
	# A slow test whose own file changed always runs.
	$ownSlow = @($slowSkipped | Where-Object { $reasons.Contains($_) -and $reasons[$_].Contains("the test itself changed") })
	if ($IncludeSlow) { $ownSlow = $slowSkipped }
	$tests += $ownSlow
	$slowSkipped = @($slowSkipped | Where-Object { $ownSlow -notcontains $_ })
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
Say ("select: base {0}, {1} changed file(s), mode {3}{2}" -f $baseUsed, $changed.Count, $(if ($ix) { ", dependency index {0:N1} s ({1} file(s) re-read)" -f $ix.Seconds, $ix.Parsed } else { "" }), $(if ($Mode -eq "near") { "near (<= $NearHops hops; -Mode reach = every reaching test)" } else { "reach (every reaching test)" }))
foreach ($r in ($fileRows | Select-Object -First 60)) { Say $r }
if ($fileRows.Count -gt 60) { Say "  ... +$($fileRows.Count - 60) more files" }
if ($docsOnly -gt 0) { Say "  + $docsOnly docs / CI-tooling file(s): no test" }
if ($wideRows.Count -gt 0) {
	Say ("select: {0} wide file(s) (more than {1} % of the {2} tests picked for it): {3}" -f $wideRows.Count, [math]::Round(100 * $WideShare), $all.Count,
		(($wideRows | Sort-Object picked -Descending | Select-Object -First 4 | ForEach-Object { "$($_.file) $($_.picked)" }) -join ", ")) "Yellow"
}
if ($full) {
	Say ("select: FULL ci_quick list ({0} tests): global file(s) changed: {1}" -f $tests.Count, (($fullWhy | Select-Object -First 3) -join "; "))
} else {
	Say ("select: {0} of {1} tests ({2} slow left out){3}" -f $tests.Count, $all.Count, $slowSkipped.Count, $(if ($Explain) { ":" } else { " (-Explain or -ListOnly: why each one)" }))
	if ($Explain) { foreach ($t in $tests) { Say ("  {0,-28} {1}" -f $t, ($reasons[$t] -join " | ")) } }
}
if ($slowSkipped.Count -gt 0) { Say ("select: slow, not run (add -IncludeSlow): {0}" -f ($slowSkipped -join ", ")) }
foreach ($n in $notes | Sort-Object -Unique) { Say "select: note: $n" }
[pscustomobject]@{ full = $full; base = $baseUsed; tests = $tests; slow_skipped = $slowSkipped; files = $changed
	reasons = $(if ($full) { @{} } else { $reasons }); wide = $wideRows.ToArray(); index_s = $(if ($ix) { $ix.Seconds } else { 0 }) }
