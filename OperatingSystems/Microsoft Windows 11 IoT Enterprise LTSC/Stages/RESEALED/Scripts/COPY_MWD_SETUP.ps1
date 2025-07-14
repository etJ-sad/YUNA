# COPY_MWD_SETUP.ps1 - Subscript for YUNA (Yielding Universal Node Automation)

# This script is responsible for:
# - Copying all contents of COPY_MWD_SETUP folder to the Siemens setup script folder
# - Logging each step of the process for tracking and debugging

# Define the script name dynamically
$scriptName = $MyInvocation.MyCommand.Name

# Log the start of the script execution
Write-Log "Script '$scriptName' started." "INFO"

# Define the source folder (COPY_MWD_SETUP)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceFolder = Join-Path -Path $scriptDir -ChildPath "COPY_MWD_SETUP"

# Define the destination folder
$destinationFolder = "$env:SystemRoot\Setup\Scripts\Siemens"

# Ensure the destination folder exists
if (-not (Test-Path $destinationFolder)) {
    try {
        New-Item -Path $destinationFolder -ItemType Directory -Force | Out-Null
        Write-Log "Created destination folder: $destinationFolder" "OK"
    } catch {
        Write-Log "Failed to create destination folder. Error: $($_.Exception.Message)" "ERROR"
    }
}

# Copy entire content of the folder
try {
    Copy-Item -Path "$sourceFolder\*" -Destination $destinationFolder -Recurse -Force -Container
    Write-Log "All files from '$sourceFolder' copied to '$destinationFolder'." "OK"
} catch {
    Write-Log "Failed to copy files. Error: $($_.Exception.Message)" "ERROR"
}

# Log the completion of the script execution
Write-Log "Script '$scriptName' execution completed." "INFO"
