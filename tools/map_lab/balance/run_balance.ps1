# Balance model CLI (docs/tools/map_gate/balance_model.md).
#   tools\map_lab\balance\run_balance.ps1 <map> [out=<file.json>] [model=<model.json>]   score + predicted G5 (seconds)
#   tools\map_lab\balance\run_balance.ps1 <map> confirm=<results dir>                          map gate: judge a confirmation sample
#   tools\map_lab\balance\run_balance.ps1 fit [holdout=<map>] [dry=1]                        refit model.json from labels\ + dataset\
#   tools\map_lab\balance\run_balance.ps1 features <map>[,<map>...]                         (re)write dataset\<map>.json
# Exit: balance 0 = clearly fair / uncertain, 1 = likely biased (confirm: 0 PASS, 1 FULL), 2 = bad input; fit 0 ok.
param([Parameter(Position = 0)][string]$Map = "help", [Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest)
$proj = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$gate = Join-Path $proj "tools\godot_run.ps1"
if ($Map -eq "help" -or $Map -eq "") {
	Get-Content $PSCommandPath -TotalCount 6 | ForEach-Object { Write-Host $_ }
	exit 0
}
$user = @()
if ($Rest) { $user += $Rest }
if ($Map -eq "fit") {
	& $gate --headless --path $proj -s res://tools/map_lab/balance/balance_fit.gd '--quit-after' 4000 '--' @user
	exit $LASTEXITCODE
}
if ($Map -eq "features") {
	$ds = Join-Path $PSScriptRoot "dataset"
	New-Item -ItemType Directory -Force $ds | Out-Null
	$fail = 0
	foreach ($m in @($Rest | ForEach-Object { $_ -split "," } | Where-Object { $_ -ne "" })) {
		$o = (Join-Path $ds "$m.json") -replace "\\", "/"
		$line = & $gate --headless --path $proj -s res://tools/map_lab/balance/balance.gd '--fixed-fps' 60 '--quit-after' 9000 '--' "map=$m" "out=$o" 2>&1 |
			Select-String "^BALANCE" | Select-Object -Last 1
		if ($line) { Write-Host $line } else { Write-Host "BALANCE ${m}: FAIL (no result)"; $fail++ }
	}
	exit $(if ($fail -gt 0) { 1 } else { 0 })
}
$user = @("map=$Map") + $user
& $gate --headless --path $proj -s res://tools/map_lab/balance/balance.gd '--fixed-fps' 60 '--quit-after' 9000 '--' @user
exit $LASTEXITCODE
