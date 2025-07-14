# SET_UNQUOTED_SERVICE_PATHS.ps1 - Subscript for YUNA (Yielding Universal Node Automation)
#
# This script is responsible for:
# - Creating a backup folder in the same directory as the script to store registry backups.
# - Generating a full registry backup of all Windows services (HKLM\SYSTEM\CurrentControlSet\Services).
# - Backing up all current ImagePath values from the registry before any modifications.
# - Identifying services with unquoted ImagePath entries that contain spaces,
#   which could be exploited for privilege escalation.
# - Excluding critical system services and specific NVIDIA services to ensure system stability.
# - Automatically correcting vulnerable service paths by wrapping the executable portion in quotes
#   while preserving any additional parameters.
# - Backing up the registry entries of the services that are modified, allowing for recovery if needed.
# - Providing log output to inform the user of the backup locations, modifications performed,
#   and a summary of all fixed services.

$ErrorActionPreference = 'SilentlyContinue'

# Create the backup folder in the same directory as the script
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$backupFolder = Join-Path -Path $scriptPath -ChildPath ".BACKUP_UNQUOTED_SERVICE_PATHS"

if (!(Test-Path $backupFolder)) {
    New-Item -ItemType Directory -Path $backupFolder | Out-Null
    Write-Log "Backup folder created: $backupFolder" "INFO"
} else {
    Write-Log "Backup folder exists: $backupFolder" "INFO"
}

# Backup 1: Full registry backup of all services
$fullRegBackupPath = Join-Path -Path $backupFolder -ChildPath "Services_Full_Backup.reg"
reg export "HKLM\SYSTEM\CurrentControlSet\Services" $fullRegBackupPath /y
Write-Log "Full registry backup saved: $fullRegBackupPath" "OK"

# Backup 2: All ImagePath values (before modification)
$imagePathRegBackupPath = Join-Path -Path $backupFolder -ChildPath "ServiceImagePaths_Backup.reg"

# Write registry file header
@"
Windows Registry Editor Version 5.00

"@ | Out-File -FilePath $imagePathRegBackupPath -Encoding ASCII

# Define critical system and NVIDIA services to exclude
$excludedServices = @(
    "msiserver", "svchost", "wuauserv", "TrustedInstaller", "WinDefend", "EventLog", 
    "RpcSs", "gpsvc", "LanmanServer", "LanmanWorkstation", "Dnscache", "Dhcp", "Netlogon", 
    "ProfSvc", "Themes", "Schedule", "Spooler", "Winmgmt", "FontCache", "TokenBroker", 
    "NlaSvc", "AudioSrv", "SysMain", "stisvc", "DoSvc", "BITS", "TimeBrokerSvc", 
    "StateRepository", "StorSvc", "wscsvc"
) + @(
    "NVDisplay.ContainerLocalSystem", "NvContainerLocalSystem", "NvTelemetryContainer", 
    "NvBackend", "NvBroadcastContainer"
) + @(
    "COMSysApp", "smstsmgr", "WSearch"
)

# Get all services from the registry
$services = Get-ChildItem -Path "HKLM:\SYSTEM\CurrentControlSet\Services"

# Create an array to store vulnerable services
$vulnerableServices = @()

# Variable to track if any modifications are needed
$modificationsMade = $false
$modifiedServicesBackupPath = Join-Path -Path $backupFolder -ChildPath "ModifiedServices_Backup.reg"

# Function to check if a path is unquoted and contains spaces
function Check-ServicePath {
    param ($servicePath)
    # Ignore empty paths and already quoted paths
    if ($servicePath -and $servicePath -match '^[A-Za-z]:\\' -and $servicePath -notmatch '^".*"$') {
        if ($servicePath -match "\s") {
            return $true
        }
    }
    return $false
}

# Loop through each service and check for unquoted paths
foreach ($service in $services) {
    $serviceName = $service.PSChildName
    $serviceRegPath = "HKLM\SYSTEM\CurrentControlSet\Services\$serviceName"
    $imagePath = (Get-ItemProperty -Path $service.PSPath -Name "ImagePath" -ErrorAction SilentlyContinue).ImagePath

    # Skip excluded critical services
    if ($excludedServices -contains $serviceName) {
        continue
    }

    # Ignore svchost services
    if ($imagePath -match "svchost.exe") { continue }

    # Backup all ImagePath values (before modification)
    if ($imagePath) {
        @"
[$serviceRegPath]
"ImagePath"="$imagePath"

"@ | Out-File -FilePath $imagePathRegBackupPath -Encoding ASCII -Append
    }

    # If path is unquoted, backup & fix it
    if (Check-ServicePath -servicePath $imagePath) {
        # Preserve parameters while quoting the executable path
        $executable, $parameters = $imagePath -split '\s+', 2
        $quotedPath = "`"$executable`" $parameters"  # Add quotes only around the executable

        # If this is the first modification, create the file header
        if (-not $modificationsMade) {
            @"
Windows Registry Editor Version 5.00

"@ | Out-File -FilePath $modifiedServicesBackupPath -Encoding ASCII
            $modificationsMade = $true
        }

        # Backup only the services that will be modified
        @"
[$serviceRegPath]
"ImagePath"="$imagePath"

"@ | Out-File -FilePath $modifiedServicesBackupPath -Encoding ASCII -Append

        # Apply fix
        Write-Log "Fixing: $serviceName -> $quotedPath" "APPLYING"
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$serviceName" -Name "ImagePath" -Value $quotedPath
        $vulnerableServices += [PSCustomObject]@{
            ServiceName = $serviceName
            OldPath     = $imagePath
            FixedPath   = $quotedPath
        }
    }
}

Write-Log "Backup of ImagePath values saved: $imagePathRegBackupPath" "OK"

# If no modifications were made, delete the modified services backup file
if (-not $modificationsMade -and (Test-Path $modifiedServicesBackupPath)) {
    Remove-Item -Path $modifiedServicesBackupPath -Force
    Write-Log "No modifications were needed, deleted: $modifiedServicesBackupPath" "INFO"
} else {
    Write-Log "Backup of modified services saved: $modifiedServicesBackupPath" "INFO"
}

# Display results
if ($vulnerableServices.Count -eq 0) {
    Write-Log "No unquoted service paths found." "OK"
} else {
    Write-Log "`n=== Summary of Fixed Services ===" "INFO"
    $vulnerableServices | Format-Table -AutoSize | Out-String | Write-Log -Level "INFO"
    Write-Log "`nAll vulnerable service paths have been fixed automatically." "OK"
}
