# BUILD_BACKUP_FROM_HKLM.ps1 - Subscript for YUNA (Yielding Universal Node Automation)
#
# This script is responsible for:
# - Dynamically defining a backup file name for the registry export using the current date and time.
# - Constructing the full backup file path based on the script's root directory.
# - Displaying a progress bar to track the export process of the HKEY_LOCAL_MACHINE registry hive.
# - Executing the "reg export" command in a separate process to create a backup of HKEY_LOCAL_MACHINE.
# - Updating the progress indicator during the export and finalizing once the process completes.
# - Handling errors gracefully and reporting any issues encountered during the backup process.

param(
    [string]$backupFile = "RegBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
)

# Define the script name dynamically
$scriptName = $MyInvocation.MyCommand.Name

# Define backup folder path (.BACKUP_UNQUOTED_SERVICE_PATHS) relative to the script root
$backupFolder = Join-Path -Path $PSScriptRoot -ChildPath ".CREATE_BACKUP_FROM_HKEY_LOCAL_MACHINE"

# Create the backup folder if it doesn't exist
if (-not (Test-Path $backupFolder)) {
    New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
    Write-Log "Backup folder created: $backupFolder" "INFO"
} else {
    Write-Log "Backup folder exists: $backupFolder" "INFO"
}

$fullPath = Join-Path -Path $backupFolder -ChildPath $backupFile

# Log the start of the script execution
Write-Log "Script '$scriptName' started." "INFO"
Write-Log "Creating backup of HKEY_LOCAL_MACHINE to '$fullPath'." "INFO"

try {
    $progress = 0
    Write-Progress -Activity "Exporting Registry" -Status "Initializing..." -PercentComplete $progress
    
    # Build the argument string with the file path enclosed in quotes
    $arguments = "export HKEY_LOCAL_MACHINE `"$fullPath`" /y"
    Write-Log "Executing command: reg $arguments" "APPLYING"
    
    $process = Start-Process -FilePath "reg" -ArgumentList $arguments -NoNewWindow -PassThru
    
    while (!$process.HasExited) {
        $progress += 5
        if ($progress -gt 95) { $progress = 95 }
        Write-Progress -Activity "Exporting Registry" -Status "Processing..." -PercentComplete $progress
        Start-Sleep -Seconds 1
    }
    
    Write-Progress -Activity "Exporting Registry" -Status "Finalizing..." -PercentComplete 100 -Completed
    Write-Log "Registry backup successfully created: $fullPath" "OK"
} catch {
    Write-Log "Error creating backup: $_" "ERROR"
}

Write-Log "Script '$scriptName' execution completed." "INFO"
