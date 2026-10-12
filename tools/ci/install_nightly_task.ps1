# Registers the Windows scheduled task "Four Wizards nightly CI" for the current user (laptop only; see docs/laptop-setup.md).
#   tools\ci\install_nightly_task.ps1              # every night at 03:00
#   tools\ci\install_nightly_task.ps1 -At 02:30
#   tools\ci\install_nightly_task.ps1 -Remove
# Runs only while the user is logged on (no stored password), wakes the PC if it sleeps, skips a missed run's backlog.
param([string]$At = "03:00", [switch]$Remove)
$name = "Four Wizards nightly CI"
if ($Remove) { Unregister-ScheduledTask -TaskName $name -Confirm:$false; Write-Host "removed '$name'"; exit 0 }
$script = Join-Path $PSScriptRoot "nightly.ps1"
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$script`""
$trigger = New-ScheduledTaskTrigger -Daily -At $At
$settings = New-ScheduledTaskSettingsSet -WakeToRun -StartWhenAvailable -DontStopIfGoingOnBatteries -AllowStartIfOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 5) -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName $name -Action $action -Trigger $trigger -Settings $settings -Description "Full CI of origin/main in ..\four-wizards-rts-ci; report in Documents\four-wizards-nightly" -Force | Out-Null
Write-Host "registered '$name' daily at $At -> $script"
