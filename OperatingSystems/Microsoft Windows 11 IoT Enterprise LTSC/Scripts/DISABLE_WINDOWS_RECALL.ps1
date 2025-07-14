# DISABLE_WINDOWS_RECALL.ps1 - Subscript for YUNA (Yielding Universal Node Automation)
#
# This script is responsible for:
# - Disabling the Windows Recall feature to prevent its automatic execution.
# - Stopping and disabling any related Windows Recall services (e.g., "RecallService").
# - Modifying registry settings to disable Windows Recall via defined keys and values.
# - Adjusting alternative registry entries to ensure the feature remains disabled.
# - Removing any scheduled tasks associated with Windows Recall to eliminate automated triggers.
# - Logging each step for clarity, including successes and any services or tasks not found.

$scriptName = $MyInvocation.MyCommand.Name
Write-Log "Script '$scriptName' started." "INFO"
Write-Log "Disabling Windows Recall..." "INFO"

# Stop related services (if applicable)
$services = @("RecallService")  # Example service, replace if necessary
foreach ($service in $services) {
    $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
    if ($svc) {
        Stop-Service -Name $service -Force
        Set-Service -Name $service -StartupType Disabled
        Write-Log "$service stopped and disabled." "APPLYING"
    }
}

# Disable Recall via registry
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"
$registryName = "DisableAIRecalling"
$registryValue = 1

if (-not (Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
    Write-Log "Registry path created: $registryPath" "INFO"
}
Set-ItemProperty -Path $registryPath -Name $registryName -Value $registryValue -Type DWord
Write-Log "Windows Recall disabled in registry at $registryPath with key $registryName set to $registryValue." "APPLYING"

# Alternative registry path (if applicable)
$altRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AIRecalling"
if (-not (Test-Path $altRegistryPath)) {
    New-Item -Path $altRegistryPath -Force | Out-Null
    Write-Log "Alternative registry path created: $altRegistryPath" "APPLYING"
}
Set-ItemProperty -Path $altRegistryPath -Name "Enabled" -Value 0 -Type DWord
Write-Log "Alternative registry key set at $altRegistryPath with 'Enabled' set to 0." "APPLYING"

# Remove Scheduled Tasks related to Recall (if any)
$tasks = @("\Microsoft\Windows\Recall\RecallTask")
foreach ($task in $tasks) {
    if (Get-ScheduledTask -TaskPath $task -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $task -Confirm:$false
        Write-Log "Scheduled task $task removed." "APPLYING"
    } 
}

Write-Log "Windows Recall disabled" "INFO"
Write-Log "Script '$scriptName' execution completed." "INFO"
