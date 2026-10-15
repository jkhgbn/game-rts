# Static dependency index for the changed-only CI (dot-source it; Windows PowerShell 5.1). Used by select_tests.ps1.
# Computed from the text (never by running Godot), cached per file. A test "reaches" a file through a chain of edges:
#   C  creation: a res:// path a file loads (preload / load / .tscn ext_resource / .tres script / shader #include),
#      `Foo.new()`, a data pattern ("res://data/units/%s.tres" or "res://art/units/" + id: every file it can match),
#      the autoload scripts (project.godot) for every test;
#   E  `extends Foo` / `extends "res://..."` (the subclass carries the parent's code);
#   S  a static call `Foo.f()` (also `const S := preload("x.gd")` + `S.f()`);
#   K  a value read: `Foo.CONST`, `Foo.Enum.X`, a static var `Foo.size_x`.
# A chain must read (C|E)* (S|E)* K? from the test to the changed file: what a test creates runs; static code it
# calls runs, but a static helper does not create its class's instance world; a value read depends on the file's text
# only. Type hints (`var u: Unit`, `is Unit`, `as Unit`), compared paths (`resource_path == "res://..."`) and unused
# path consts are no edge at all. Why (measured 2026-10-14): with every mention counted, unit.gd, the HUD, the level
# scripts and the mission table formed one cycle and any core file reached ~85 % of the 501 tests.
# Cache: %LOCALAPPDATA%\FourWizardsCI\dep_index_<root hash>.tsv (outside the repo), by size + mtime, then by MD5 when
# those change (a checkout that only touches mtimes keeps the parse); a parser change re-reads everything.
#
#   . tools\ci\dep_index.ps1
#   $ix = Get-DepIndex -Root $root                          # build / refresh (~10 s cold, ~2 s cached)
#   $hits = Get-ReachingTests $ix "scripts/units/unit.gd"   # test name -> @{ hops; chain }
$DepIndexVersion = "6"
$DepIndexRoots = @("addons", "art", "assets", "data", "missions", "scenes", "scripts", "tests", "tools")
$DepParseExt = @{ ".gd" = 1; ".tscn" = 1; ".tres" = 1; ".gdshader" = 1; ".gdshaderinc" = 1 }
# Folder / pattern rules need at least this many fixed folders: "res://data/units/" ok, "res://art/" ignored (a file
# browser on res://art/ would make every asset reach that script).
$DepPrefixMinDepth = 2
# Game data looked up by id: quoted ids / display names make the edge, folder scans of these folders do not (tests excepted).
$DepDataIdRx = '^data/(units|spells|buildings|items|champions|champion_classes|helpers|ai)/([^/]+)\.tres$'
$DepDataDirRx = '^data/(units|spells|buildings|items|champions|champion_classes|helpers|ai)/'
# Files whose quoted ids count as a dependency on that data file (see the "Q" tokens below).
$DepIdQuoteRx = '^(tests/|scripts/campaign/|missions/)'
# Level, menu and film scenes (entered by a scene change).
$DepLevelRx = '^(missions/[^/]+\.tscn|scenes/[^/]+\.tscn|scenes/(ui|cinematics)/.+\.tscn)$'

# One file -> @{ cls; paths ("C:scenes/main.tscn", kind + path without res://); tokens ("S:CasterKit", kind + class) }
function Read-DepFile([string]$abs, [string]$ext) {
	$t = [IO.File]::ReadAllText($abs)
	$cls = ""
	$tokens = @()
	if ($ext -eq ".gd") {
		# Comments out (full-line, then a trailing '#...' outside quotes): commented-out loads do not count.
		$t = [regex]::Replace($t, '(?m)^[ \t]*#.*$', '')
		$t = [regex]::Replace($t, '(?m)^((?:[^"''#\r\n]|"[^"\r\n]*"|''[^''\r\n]*'')*)#.*$', '$1')
		$m = [regex]::Match($t, '(?m)^class_name\s+(\w+)')
		if ($m.Success) { $cls = $m.Groups[1].Value }
		$code = [regex]::Replace($t, '"[^"\r\n]*"|''[^''\r\n]*''', '""')
		$seen = New-Object 'System.Collections.Generic.HashSet[string]'
		# `x.Unit` (a member) is not a class use: the lookbehind skips identifiers after a dot.
		foreach ($mm in [regex]::Matches($code, '(?<![A-Za-z0-9_.])([A-Z][A-Za-z0-9_]{2,})\s*\.\s*([A-Za-z_][A-Za-z0-9_]*)\s*(\()?')) {
			$member = $mm.Groups[2].Value
			$k = "K:"
			if ($mm.Groups[3].Success -and -not [char]::IsUpper($member[0])) { $k = $(if ($member -eq "new") { "C:" } else { "S:" }) }
			[void]$seen.Add($k + $mm.Groups[1].Value)
		}
		foreach ($mm in [regex]::Matches($code, '(?m)^extends\s+([A-Z][A-Za-z0-9_]*)')) { [void]$seen.Add("E:" + $mm.Groups[1].Value) }
		# Quoted words: a game-data id ("flame_guard", &"fireball") or display name ("Flame Guard") -> that data file.
		foreach ($mm in [regex]::Matches($t, '["'']([A-Za-z][A-Za-z0-9_ ''\-]{2,39})["'']')) { [void]$seen.Add("Q:" + $mm.Groups[1].Value) }
		$tokens = @($seen)
	} elseif ($ext -eq ".gdshader" -or $ext -eq ".gdshaderinc") {
		$t = [regex]::Replace($t, '(?m)//.*$', '')
	} elseif ($ext -eq ".tres") {
		$m = [regex]::Match($t, '(?m)^display_name\s*=\s*"([^"|\t]{3,40})"')
		if ($m.Success) { $cls = "dn:" + $m.Groups[1].Value }
	}
	$paths = New-Object 'System.Collections.Generic.HashSet[string]'
	foreach ($mm in [regex]::Matches($t, 'res://([A-Za-z0-9_\-./%]*)')) {
		$p = $mm.Groups[1].Value.TrimEnd('.')
		if (-not $p) { continue }
		$k = "C"
		if ($ext -eq ".gd") { $k = Get-DepPathKind $t $mm.Index $p }
		if ($k) { [void]$paths.Add("${k}:$p") }
	}
	return @{ cls = $cls; paths = @($paths); tokens = $tokens }
}

# The kind of one res:// literal in a .gd file: "C" (loaded / instanced), "E" (extends), "S" (a script whose static
# functions are called), "K" (a script whose constants are read), or "" = no dependency:
#   - only compared (`get_script().resource_path == SKIRMISH_SCRIPT`, `.begins_with("res://...")`),
#   - a script used only as a type (`x is preload("res://...gd")`, `as SomeScript`, `: SomeScript`),
#   - held by a const / var that this file never uses.
function Get-DepPathKind([string]$t, [int]$at, [string]$p) {
	$ls = $t.LastIndexOf("`n", [Math]::Max(0, $at - 1)) + 1
	$le = $t.IndexOf("`n", $at); if ($le -lt 0) { $le = $t.Length }
	$line = $t.Substring($ls, $le - $ls)
	if ($line -match '^\s*extends\s') { return "E" }
	$isScript = $p -match '\.gd$'
	$m = [regex]::Match($line, '^\s*(?:static\s+)?(?:const|var)\s+(\w+)\s*(?::\s*\w+\s*)?:?=\s*(?:(?:pre)?load\(\s*)?"res://')
	if ($m.Success) {
		$name = $m.Groups[1].Value
		$best = ""
		foreach ($u in [regex]::Matches($t, '(?<![A-Za-z0-9_."])' + [regex]::Escape($name) + '(?![A-Za-z0-9_])')) {
			if ($u.Index -ge $ls -and $u.Index -lt $le) { continue }   # the declaration
			$a = $t.LastIndexOf("`n", [Math]::Max(0, $u.Index - 1)) + 1
			$before = $t.Substring($a, $u.Index - $a)
			$after = $t.Substring($u.Index + $name.Length, [Math]::Min(40, $t.Length - $u.Index - $name.Length))
			if ($before -match '(==|!=|\bin)\s*$' -or $after -match '^\s*(==|!=)') { continue }
			if (-not $isScript) { return "C" }
			if ($before -match '(\bis|\bas|:|->|\[)\s*$') { continue }
			$k = Get-DepScriptUse $after
			if ($k -eq "C") { return "C" }
			if ($k -eq "S" -or $best -eq "") { $best = $k }
		}
		return $best
	}
	$before = $t.Substring($ls, [Math]::Max(0, $at - 1 - $ls))   # text before the opening quote of "res://
	if ($before -match '(==|!=|\.(begins_with|ends_with|contains|find)\()\s*$') { return "" }
	$q = $t.IndexOf('"', $at)
	$after = ""
	if ($q -gt 0) { $after = $t.Substring($q + 1, [Math]::Min(40, $t.Length - $q - 1)) }
	if ($after -match '^\s*(==|!=)') { return "" }
	if (-not $isScript) { return "C" }
	if ($before -match '(\bis|\bas)\s*(?:pre)?load\(\s*$') { return "" }
	# `preload("x.gd").f()` / `load("x.gd").new()`: the text after the closing parenthesis.
	if ($after -match '^\s*\)(.*)$') { return Get-DepScriptUse $Matches[1] }
	return "C"
}
# What follows a script reference: `.new(` = C, `.f(` = S, `.CONST` / `.var` = K, anything else (passed on,
# set_script(...)) = C.
function Get-DepScriptUse([string]$after) {
	if ($after -match '^\s*\.\s*new\s*\(') { return "C" }
	if ($after -match '^\s*\.\s*[a-z_][A-Za-z0-9_]*\s*\(') { return "S" }
	if ($after -match '^\s*\.\s*[A-Za-z_]') { return "K" }
	return "C"
}

function Get-DepCachePath([string]$root) {
	$md5 = [Security.Cryptography.MD5]::Create()
	$h = [BitConverter]::ToString($md5.ComputeHash([Text.Encoding]::UTF8.GetBytes($root.ToLower()))).Replace("-", "")
	$base = $env:LOCALAPPDATA
	if (-not $base) { $base = $env:TEMP }
	$dir = Join-Path $base "FourWizardsCI"
	New-Item -ItemType Directory -Force $dir | Out-Null
	return Join-Path $dir ("dep_index_{0}.tsv" -f $h.Substring(0, 10).ToLower())
}

function New-DepRx([string]$rx) { return New-Object regex ($rx, [Text.RegularExpressions.RegexOptions]::IgnoreCase) }

function Get-DepIndex([string]$Root, [switch]$NoCache, [switch]$Quiet) {
	$sw = [Diagnostics.Stopwatch]::StartNew()
	$files = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
	$parse = New-Object System.Collections.Generic.List[object]
	foreach ($r in $DepIndexRoots) {
		$d = Join-Path $Root $r
		if (-not [IO.Directory]::Exists($d)) { continue }
		foreach ($f in [IO.Directory]::EnumerateFiles($d, "*", [IO.SearchOption]::AllDirectories)) {
			$ext = [IO.Path]::GetExtension($f).ToLower()
			if ($ext -eq ".import" -or $ext -eq ".uid" -or $ext -eq ".tmp") { continue }
			$rel = $f.Substring($Root.Length + 1).Replace('\', '/')
			if ($rel.Contains("/__pycache__/") -or $rel.Contains("/.godot/")) { continue }
			[void]$files.Add($rel)
			if ($DepParseExt.ContainsKey($ext)) { $parse.Add(@($rel, $f, $ext)) }
		}
	}
	# ---- cache: rel, size, mtime ticks, md5, class, paths, tokens ----
	$ver = "v$DepIndexVersion-" + [BitConverter]::ToString([Security.Cryptography.MD5]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes("${function:Read-DepFile}${function:Get-DepPathKind}${function:Get-DepScriptUse}"))).Replace("-", "").Substring(0, 8)
	$cachePath = Get-DepCachePath $Root
	$cache = @{}
	if (-not $NoCache -and (Test-Path $cachePath)) {
		$lines = [IO.File]::ReadAllLines($cachePath)
		if ($lines.Length -gt 0 -and $lines[0] -eq $ver) {
			for ($i = 1; $i -lt $lines.Length; $i++) {
				$c = $lines[$i].Split("`t")
				if ($c.Length -ge 7) { $cache[$c[0]] = $c }
			}
		}
	}
	$md5 = [Security.Cryptography.MD5]::Create()
	$info = @{}
	$out = New-Object System.Collections.Generic.List[string]
	$out.Add($ver)
	$parsed = 0
	foreach ($e in $parse) {
		$rel = $e[0]; $abs = $e[1]; $ext = $e[2]
		$fi = New-Object IO.FileInfo($abs)
		$len = "$($fi.Length)"; $ticks = "$($fi.LastWriteTimeUtc.Ticks)"
		$c = $cache[$rel]
		$hash = ""
		$hit = $false
		if ($c -and $c[1] -eq $len -and $c[2] -eq $ticks) { $hit = $true; $hash = $c[3] }
		elseif ($c) {
			$hash = [BitConverter]::ToString($md5.ComputeHash([IO.File]::ReadAllBytes($abs))).Replace("-", "")
			if ($hash -eq $c[3]) { $hit = $true }
		}
		if ($hit) {
			$d = @{ cls = $c[4]; paths = @(if ($c[5]) { $c[5].Split('|') }); tokens = @(if ($c[6]) { $c[6].Split('|') }) }
		} else {
			if (-not $hash) { $hash = [BitConverter]::ToString($md5.ComputeHash([IO.File]::ReadAllBytes($abs))).Replace("-", "") }
			$d = Read-DepFile $abs $ext
			$parsed++
		}
		$info[$rel] = $d
		$out.Add(($rel, $len, $ticks, $hash, $d.cls, ($d.paths -join '|'), ($d.tokens -join '|')) -join "`t")
	}
	if (-not $NoCache -and $parsed -gt 0) { try { [IO.File]::WriteAllLines($cachePath, $out) } catch { } }
	# ---- classes ----
	$classes = @{}
	foreach ($rel in ($info.Keys | Sort-Object)) {
		$cn = $info[$rel].cls
		if ($cn -and -not $cn.StartsWith("dn:") -and -not $classes.ContainsKey($cn)) { $classes[$cn] = $rel }
	}
	# ---- autoloads ----
	$autoloads = @()
	$pg = Join-Path $Root "project.godot"
	if (Test-Path $pg) {
		$inAuto = $false
		foreach ($l in [IO.File]::ReadAllLines($pg)) {
			if ($l -match '^\[(.+)\]') { $inAuto = ($Matches[1] -eq "autoload"); continue }
			if ($inAuto -and $l -match '^\w+="\*?res://([^"]+)"') { $autoloads += $Matches[1] }
		}
	}
	# ---- graph (C#: the BFS over ~11k files and ~60k edges is too slow in PowerShell) ----
	$g = New-Object FourWizardsCI.DepGraph
	foreach ($f in $files) { [void]$g.Node($f) }
	$wide = New-Object System.Collections.Generic.List[string]
	$nRules = 0
	$kindWord = @{ "C" = ""; "E" = "extends "; "S" = "static "; "K" = "const " }
	# Game data looked up by id (data/units/<id>.tres...): a code file depends on the ids / display names it quotes,
	# not on every file of the folder its lookup helper scans (UnitType.find scans data/units/: with folder rules
	# every balance change reached ~350 tests). Tests that scan the folder themselves keep their folder rule.
	$dataIds = @{}
	foreach ($f in $files) {
		if ($f -match $DepDataIdRx) {
			$id = $Matches[2]
			if (-not $dataIds.ContainsKey($id)) { $dataIds[$id] = New-Object System.Collections.Generic.List[string] }
			$dataIds[$id].Add($f)
			$dn = $info[$f].cls
			if ($dn -and $dn.StartsWith("dn:")) {
				$k = $dn.Substring(3)
				if (-not $dataIds.ContainsKey($k)) { $dataIds[$k] = New-Object System.Collections.Generic.List[string] }
				$dataIds[$k].Add($f)
			}
		}
	}
	$droppedRules = 0
	foreach ($rel in $info.Keys) {
		$d = $info[$rel]
		$isTest = $rel.StartsWith("tests/")
		foreach ($kp in $d.paths) {
			if ($kp.Length -lt 3 -or $kp[1] -ne ':') { continue }
			$k = [string]$kp[0]; $p = $kp.Substring(2)
			if ($p.Contains('%')) {
				# "data/units/%s.tres" -> ^data/units/[^/]+\.tres$ ; "art/icons/%s/%s.png" -> two free segments
				$segs = @($p.Split('/') | Where-Object { $_ -ne "" })
				$fixed = 0
				foreach ($s in $segs) { if ($s.Contains('%')) { break }; $fixed++ }
				if ($fixed -lt $DepPrefixMinDepth) { $wide.Add("$rel -> res://$p"); continue }
				$lit = $p.Substring(0, $p.IndexOf('%'))
				if (-not $isTest -and ($lit -match $DepDataDirRx)) { $droppedRules++; continue }
				$rx ='^' + ([regex]::Escape($p) -replace '%[0-9.]*[sdif]', '[^/]+') + $(if ($p.EndsWith('/')) { '' } else { '$' })
				$g.AddRule($rel, $lit, $rx, "pattern res://$p"); $nRules++
				continue
			}
			$q = $p.TrimEnd('/')
			if (-not $q) { continue }
			# A level / menu / film scene named by game code (a mission table, a menu button, a film id) is entered by a scene
			# change, not loaded with the code: a value read (last hop). Tests, tools (labs boot levels) and scenes that
			# instance another scene keep the edge. Why: CampaignState's mission table made every mission reach every mission.
			if ($k -eq "C" -and $q -match $DepLevelRx -and $rel -notmatch '^(tests/|tools/)' -and $rel -notmatch '\.tscn$') { $k = "K" }
			if ($files.Contains($q)) { $g.AddEdge($rel, $q, "$($kindWord[$k])res://$q", $k); continue }
			if ([IO.Directory]::Exists((Join-Path $Root $q))) {
				$depth = @($q.Split('/') | Where-Object { $_ -ne "" }).Count
				if ($depth -lt $DepPrefixMinDepth) { $wide.Add("$rel -> res://$p"); continue }
				if (-not $isTest -and ("$q/" -match $DepDataDirRx)) { $droppedRules++; continue }
				$g.AddRule($rel, "$q/", "", "folder res://$q/"); $nRules++
				continue
			}
			# A path that does not exist (deleted / renamed file): keep the edge so the deleted file still finds its users.
			if ($q -match '\.[A-Za-z0-9]+$') { $g.AddEdge($rel, $q, "res://$q (missing)", $k) }
		}
		foreach ($tk in $d.tokens) {
			if ($tk.Length -lt 3 -or $tk[1] -ne ':') { continue }
			$k = [string]$tk[0]; $cn = $tk.Substring(2)
			if ($k -eq "Q") {
				# Only tests and level scripts (missions spawn given units) depend on a data file by quoting its id. Kit tables,
				# AI build lists and lookups quote every id without reading its numbers: with them, any balance change reached
				# ~370 tests (the old name-based pick: ~10-30; the failures it caused were the tests that pin the numbers).
				if (-not ($rel -match $DepIdQuoteRx)) { continue }
				$dl = $dataIds[$cn]
				# A quoted id reads that data: last hop only (otherwise unit.gd quoting "fire_barracks" reaches every unit id).
				if ($dl) { foreach ($df in $dl) { $g.AddEdge($rel, $df, "id '$cn'", "K") } }
				continue
			}
			$cr = $classes[$cn]
			if (-not $cr -or $cr -eq $rel) { continue }
			$lab = switch ($k) { "C" { "$cn.new()" } "E" { "extends $cn" } "S" { "$cn.f()" } default { "$cn.CONST" } }
			$g.AddEdge($rel, $cr, $lab, $k)
		}
	}
	$tests = @($info.Keys | Where-Object { $_ -match '^tests/test_[^/]+\.gd$' } | Sort-Object)
	foreach ($a in $autoloads) { foreach ($t in $tests) { $g.AddEdge($t, $a, "autoload", "C") } }
	$g.Build()
	$g.SetTests([string[]]$tests)
	$sw.Stop()
	if (-not $Quiet) { Write-Host ("dep-index: {0} files, {1} parsed ({2} re-read), {3} classes, {4} edges, {5} pattern / folder rules, {6:N1} s" -f $files.Count, $info.Count, $parsed, $classes.Count, $g.EdgeCount, $nRules, $sw.Elapsed.TotalSeconds) }
	return [pscustomobject]@{ Root = $Root; Files = $files; Info = $info; Classes = $classes; Graph = $g
		Tests = $tests; Autoloads = $autoloads; Wide = $wide; Seconds = $sw.Elapsed.TotalSeconds; Parsed = $parsed }
}

# Every test that reaches $changed, with its shortest chain. Returns an ordered hashtable
# test name -> @{ hops; chain } (chain read from the test to the changed file:
# "[res://scenes/main.tscn] scenes/main.tscn [res://scripts/world/main.gd] scripts/world/main.gd [GameHUD.new()]").
function Get-ReachingTests($ix, [string]$changed) {
	$found = [ordered]@{}
	foreach ($r in $ix.Graph.Reaching($changed)) {
		$found[[IO.Path]::GetFileNameWithoutExtension($r.Test)] = @{ hops = $r.Hops; chain = $r.Chain }
	}
	return $found
}

if (-not ("FourWizardsCI.DepGraph" -as [type])) {
	Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;
namespace FourWizardsCI {
	public class Reach { public string Test; public int Hops; public string Chain; }
	// Edge kinds (bit mask): C creation 1, E extends 2, S static call 4, K value read 8.
	// A chain from a test to the changed file reads (C|E)* (S|E)* K?  (see dep_index.ps1).
	public class DepGraph {
		Dictionary<string, int> ids = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
		List<string> names = new List<string>();
		// reverse adjacency: target -> { source, mask, label C, label E, label S, label K }
		List<List<int[]>> rev = new List<List<int[]>>();
		Dictionary<long, int[]> edgeOf = new Dictionary<long, int[]>();
		List<string> labels = new List<string>();
		Dictionary<string, int> labelIds = new Dictionary<string, int>();
		List<object[]> rules = new List<object[]>();
		HashSet<int> tests = new HashSet<int>();
		public int EdgeCount = 0;
		public int Node(string n) {
			int id;
			if (ids.TryGetValue(n, out id)) return id;
			id = names.Count; ids[n] = id; names.Add(n); rev.Add(new List<int[]>());
			return id;
		}
		int Label(string l) {
			int id;
			if (labelIds.TryGetValue(l, out id)) return id;
			id = labels.Count; labelIds[l] = id; labels.Add(l);
			return id;
		}
		static int Bit(string kind) {
			switch (kind) { case "E": return 2; case "S": return 4; case "K": return 8; default: return 1; }
		}
		public void AddEdge(string src, string dst, string label, string kind) {
			int s = Node(src), d = Node(dst);
			if (s == d) return;
			int bit = Bit(kind), slot = bit == 1 ? 2 : bit == 2 ? 3 : bit == 4 ? 4 : 5;
			long key = ((long)s << 32) | (uint)d;
			int[] e;
			if (!edgeOf.TryGetValue(key, out e)) {
				e = new int[] { s, 0, -1, -1, -1, -1 };
				edgeOf[key] = e; rev[d].Add(e); EdgeCount++;
			}
			if ((e[1] & bit) == 0) { e[1] |= bit; e[slot] = Label(label); }
		}
		public void AddRule(string src, string literalPrefix, string regex, string label) {
			rules.Add(new object[] { src, literalPrefix, regex.Length > 0 ? new Regex(regex, RegexOptions.IgnoreCase) : null, label });
		}
		public void Build() {
			int n = names.Count;
			foreach (object[] r in rules) {
				string src = (string)r[0], lit = (string)r[1]; Regex rx = (Regex)r[2]; string label = (string)r[3];
				for (int i = 0; i < n; i++) {
					string f = names[i];
					if (!f.StartsWith(lit, StringComparison.OrdinalIgnoreCase)) continue;
					if (rx != null && !rx.IsMatch(f)) continue;
					// A folder load ("res://art/environment/landmarks/" + name) loads scenes / resources: the scripts in that
					// folder are reached through the scenes they belong to (a preview tool script there loads a whole level).
					if (rx == null && f.EndsWith(".gd", StringComparison.OrdinalIgnoreCase)) continue;
					AddEdge(src, f, label, "C");
				}
			}
		}
		public void SetTests(string[] t) { foreach (string x in t) tests.Add(Node(x)); }
		public bool Has(string n) { return ids.ContainsKey(n); }
		// Longest static-call segment (S hops) a chain may hold. A static helper's callers depend on it; callers of
		// callers through more static helpers mostly do not run the changed function (the kit tables call each other).
		public int MaxStatic = 2;
		// Reverse BFS from the changed file over (node, state). State 0 = the changed file; 1..MaxStatic+1 = in the
		// static segment with (state - 1) S hops used (S / E / C may come next, going back toward the test);
		// MaxStatic+2 = in the creation segment (only C / E). A lower state is a wider one.
		public List<Reach> Reaching(string changed) {
			List<Reach> res = new List<Reach>();
			int c;
			if (!ids.TryGetValue(changed, out c)) return res;
			int n = names.Count, cre = MaxStatic + 2, ns_ = cre + 1;
			int[] best = new int[n];               // 0 = not reached, else the best state
			int[,] par = new int[n, ns_];          // [node, state] -> parent node
			int[,] pst = new int[n, ns_];          // parent state
			int[,] lab = new int[n, ns_];          // label of the edge used
			Queue<int> q = new Queue<int>();       // node * 64 + state
			best[c] = 1;
			q.Enqueue(c * 64 + 0);
			while (q.Count > 0) {
				int item = q.Dequeue(), x = item / 64, st = item % 64;
				if (st != 0 && best[x] < st) continue;   // a wider state of x was queued later
				foreach (int[] e in rev[x]) {
					int s = e[0], m = e[1], ns = 0, used = -1;
					// K: first hop only
					if (st == 0 && (m & 8) != 0) { ns = 1; used = e[5]; }
					// E: keeps the segment (start -> static, no S hop used)
					if ((m & 2) != 0) {
						int v = st == 0 ? 1 : st;
						if (ns == 0 || v < ns) { ns = v; used = e[3]; }
					}
					// S: one more static hop, never inside the creation segment
					if ((m & 4) != 0 && st != cre) {
						int v = (st == 0 ? 1 : st) + 1;
						if (v <= MaxStatic + 1 && (ns == 0 || v < ns)) { ns = v; used = e[4]; }
					}
					// C: the creation segment
					if ((m & 1) != 0 && ns == 0) { ns = cre; used = e[2]; }
					if (ns == 0) continue;
					if (best[s] != 0 && best[s] <= ns) continue;
					best[s] = ns;
					par[s, ns] = x; pst[s, ns] = st; lab[s, ns] = used;
					q.Enqueue(s * 64 + ns);
				}
			}
			List<int> found = new List<int>();
			foreach (int t in tests) if (t != c && best[t] != 0) found.Add(t);
			found.Sort(delegate(int a, int b) { return string.CompareOrdinal(names[a], names[b]); });
			foreach (int t in found) {
				List<string> parts = new List<string>();
				int x = t, st = best[t], hops = 0;
				while (x != c && hops < 64) {
					int nx = par[x, st], nst = pst[x, st];
					parts.Add("[" + labels[lab[x, st]] + "]");
					if (nx != c) parts.Add(names[nx]);
					x = nx; st = nst; hops++;
				}
				Reach r = new Reach(); r.Test = names[t]; r.Hops = hops; r.Chain = string.Join(" ", parts.ToArray());
				res.Add(r);
			}
			return res;
		}
		// How many tests reach each node (analysis): node -> count, for nodes under a prefix.
		public Dictionary<string, int> CountAll(string prefix) {
			Dictionary<string, int> d = new Dictionary<string, int>();
			for (int i = 0; i < names.Count; i++)
				if (names[i].StartsWith(prefix, StringComparison.OrdinalIgnoreCase)) d[names[i]] = Reaching(names[i]).Count;
			return d;
		}
	}
}
'@
}
