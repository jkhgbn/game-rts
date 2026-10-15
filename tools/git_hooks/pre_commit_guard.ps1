# Pre-commit guard (JS 2026-10-14: "garde-fou au commit"). Run by tools/git_hooks/pre-commit (core.hooksPath).
# Blocks a commit when a STAGED file shows one of the bug classes that came back on 2026-10-12 / 14, whatever wrote it
# (Edit, Write, a script, an agent):
#   G1 line endings flipped vs HEAD (CRLF <-> LF) on a code / data file (the whole file shows as changed);
#   G2 a UTF-8 BOM that HEAD had is gone (or one appeared);
#   G3 a .gd line with a run of tabs in the middle (a lost '\' line continuation, check_gd R6).
# Only code / data extensions are checked (lab outputs are not). New files: G3 only.
#   powershell -NoProfile -File tools\git_hooks\pre_commit_guard.ps1            (what the hook runs)
#   powershell -NoProfile -File tools\git_hooks\pre_commit_guard.ps1 -SelfTest  ("guard self-test: N/N OK")
param([switch]$SelfTest)

$CodeExt = @('.gd', '.gdshader', '.tscn', '.tres', '.ps1', '.py', '.cfg', '.po', '.pot', '.godot', '.json')
$CodeDirs = @('scripts/', 'tests/', 'tools/', 'data/', 'scenes/', 'missions/', 'art/', '.claude/', 'addons/')

function Get-Eol([byte[]]$b) {
	$crlf = 0; $lf = 0
	for ($i = 0; $i -lt $b.Length; $i++) {
		if ($b[$i] -eq 10) { if ($i -gt 0 -and $b[$i - 1] -eq 13) { $crlf++ } else { $lf++ } }
	}
	if ($crlf -eq 0 -and $lf -eq 0) { return 'none' }
	if ($crlf -gt 0 -and $lf -eq 0) { return 'crlf' }
	if ($lf -gt 0 -and $crlf -eq 0) { return 'lf' }
	return 'mixed'
}

function Test-Bom([byte[]]$b) { return $b.Length -ge 3 -and $b[0] -eq 239 -and $b[1] -eq 187 -and $b[2] -eq 191 }

## Problems for one file: $old = HEAD bytes ($null for a new file), $new = staged bytes.
function Get-Problems([string]$path, $old, [byte[]]$new) {
	$out = @()
	if ($null -ne $old) {
		$eo = Get-Eol $old
		$en = Get-Eol $new
		if ($eo -ne 'none' -and $en -ne 'none' -and $eo -ne 'mixed' -and $eo -ne $en) {
			$out += "G1 line endings $eo -> $en (whole file changed). Restore $eo."
		}
		$bo = Test-Bom $old
		$bn = Test-Bom $new
		if ($bo -and -not $bn) { $out += "G2 the UTF-8 BOM is gone. Put it back (write with UTF8Encoding(`$true))." }
		elseif ($bn -and -not $bo) { $out += "G2 a UTF-8 BOM appeared. Write without BOM." }
	}
	if ($path.EndsWith('.gd')) {
		$text = [Text.Encoding]::UTF8.GetString($new)
		$n = 0
		foreach ($line in ($text -split "`r?`n")) {
			$n++
			$code = ($line -split '#', 2)[0]
			if ($code -match '\S[ \t]*\t{2,}\S') {
				$out += "G3 line ${n}: tabs in the middle of the line (a lost '\' line continuation): put the '\' and the newline back"
			}
		}
	}
	return $out
}

if ($SelfTest) {
	$u = [Text.Encoding]::UTF8
	$cases = @(
		@{ name = 'same lf'; p = 'a.gd'; o = $u.GetBytes("a`nb`n"); n = $u.GetBytes("a`nc`n"); want = 0 },
		@{ name = 'lf to crlf'; p = 'a.gd'; o = $u.GetBytes("a`nb`n"); n = $u.GetBytes("a`r`nb`r`n"); want = 1 },
		@{ name = 'crlf to lf'; p = 'a.tscn'; o = $u.GetBytes("a`r`nb`r`n"); n = $u.GetBytes("a`nb`n"); want = 1 },
		@{ name = 'bom lost'; p = 'a.gd'; o = [byte[]](@(239, 187, 191) + $u.GetBytes("a`n")); n = $u.GetBytes("a`n"); want = 1 },
		@{ name = 'bom kept'; p = 'a.gd'; o = [byte[]](@(239, 187, 191) + $u.GetBytes("a`n")); n = [byte[]](@(239, 187, 191) + $u.GetBytes("b`n")); want = 0 },
		@{ name = 'lost continuation'; p = 'a.gd'; o = $null; n = $u.GetBytes("`tif a and `t`t`tb:`n"); want = 1 },
		@{ name = 'continuation ok'; p = 'a.gd'; o = $null; n = $u.GetBytes("`tif a and \`n`t`t`tb:`n"); want = 0 },
		@{ name = 'tabs in a comment'; p = 'a.gd'; o = $null; n = $u.GetBytes("var a := 1 # x`t`t`ty`n"); want = 0 }
	)
	$ok = 0
	foreach ($c in $cases) {
		$got = @(Get-Problems $c.p $c.o $c.n).Count
		if ($got -eq $c.want) { $ok++ } else { Write-Host "MISMATCH '$($c.name)': want $($c.want) got $got" }
	}
	Write-Host "guard self-test: $ok/$($cases.Count) OK"
	if ($ok -ne $cases.Count) { exit 1 }
	exit 0
}

function Get-Blob([string]$spec) {
	# Raw bytes of a git object (HEAD:path or :path for the index), no text conversion.
	$psi = New-Object Diagnostics.ProcessStartInfo
	$psi.FileName = 'git'
	$psi.Arguments = "cat-file blob `"$spec`""
	$psi.RedirectStandardOutput = $true
	$psi.RedirectStandardError = $true
	$psi.UseShellExecute = $false
	$pr = [Diagnostics.Process]::Start($psi)
	$ms = New-Object IO.MemoryStream
	$pr.StandardOutput.BaseStream.CopyTo($ms)
	$pr.WaitForExit()
	if ($pr.ExitCode -ne 0) { return $null }
	return $ms.ToArray()
}

$staged = @(git diff --cached --name-only --diff-filter=AMR)
$hasHead = $true
git rev-parse --verify HEAD 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) { $hasHead = $false }
$report = @()
foreach ($p in $staged) {
	$ext = [IO.Path]::GetExtension($p).ToLower()
	if ($CodeExt -notcontains $ext) { continue }
	$inDir = $false
	foreach ($d in $CodeDirs) { if ($p.StartsWith($d)) { $inDir = $true } }
	if (-not $inDir -and $p -ne 'project.godot') { continue }
	$new = Get-Blob ":$p"
	if ($null -eq $new) { continue }
	$old = if ($hasHead) { Get-Blob "HEAD:$p" } else { $null }
	foreach ($x in (Get-Problems $p $old $new)) { $report += "  $p : $x" }
}
if ($report.Count -eq 0) { exit 0 }
[Console]::Error.WriteLine("pre-commit guard (tools/git_hooks/pre_commit_guard.ps1): $($report.Count) problem(s) in staged files. Fix them, re-stage, commit again:")
foreach ($r in $report) { [Console]::Error.WriteLine($r) }
exit 1
