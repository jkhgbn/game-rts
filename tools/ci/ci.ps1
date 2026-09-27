param([string]$Dir = "C:\Users\elzzo\Documents\four-wizards-rts-ci", [string]$ResultFile = "C:\Users\elzzo\AppData\Local\Temp\claude\C--Users-elzzo-Documents-nouveau-projet-de-jeu\40b9bacd-6a9b-42d4-b775-f389cb84009d\scratchpad\ci_result.txt")
# Full integration check of a project copy: import, smoke x3, perf, every tests/test_*.gd.
$g = "C:\Godot\Godot_v4.7.2-stable_win64_console.exe"
$out = @()
$out += (& $g --headless --path $Dir --import 2>&1 | Select-String "SCRIPT ERROR|Parse Error" | Select-Object -First 5 | ForEach-Object { "IMPORT: $($_.Line)" })
foreach ($i in 1..3) { $out += (& $g --headless --path $Dir -s tests/smoke_test.gd --fixed-fps 60 --quit-after 7000 2>&1 | Select-String "SCRIPT ERROR|GAME OVER|TIMEOUT" | Select-Object -First 2 | ForEach-Object { "SMOKE: $($_.Line)" }) }
foreach ($n in 100, 200) { $out += (& $g --headless --path $Dir -s tests/perf_test.gd --fixed-fps 60 --quit-after 3000 -- units=$n 2>&1 | Select-String "PERF units" | ForEach-Object { $_.Line }) }
$tests = Get-ChildItem "$Dir\tests\test_*.gd"
$fails = @()
foreach ($t in $tests) {
	$q = 40000
	if ($t.Name -match "a1_attack|test_9_c11|test_8_b3") { $q = 95000 }
	if ($t.Name -match "bot_vs_bot") { $q = 116000 }
	if ($t.Name -match "test_8_a2") { $q = 100000 }
	if ($t.Name -match "test_12_a1") { $q = 60000 }
	if ($t.Name -match "test_20_a2") { $q = 60000 }
	if ($t.Name -match "test_20_a3") { $q = 80000 }
	if ($t.Name -match "test_9_c11") { $q = 95000 }
	if ($t.Name -match "test_9_c9|test_10_a3") { $q = 150000 }
	if ($t.Name -match "test_8_a1") { $q = 200000 }
	$o = & $g --headless --path $Dir -s "tests/$($t.Name)" --fixed-fps 60 --quit-after $q 2>&1
	$res = ($o | Select-String "^(PASS|FAIL)" | Select-Object -First 1)
	$errs = ($o | Select-String "SCRIPT ERROR").Count
	if (-not ($res -and $res.Line -match "PASS") -or $errs -gt 0) { $fails += "FAIL-> $($t.BaseName): $($res.Line) errors=$errs" }
}
$out += "tests run: $($tests.Count), failed: $($fails.Count)"
$out += $fails
$out | Out-File -Encoding utf8 $ResultFile
$out

