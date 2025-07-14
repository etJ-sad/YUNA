# RECOVERY.ps1 - Subscript for YUNA (Yielding Universal Node Automation)

# This script is responsible for:
# - Ensuring the current OS is set before execution
# - Running RECOVERY-specific PowerShell scripts
# - Importing RECOVERY-specific registry modifications
# - Logging each step for tracking and debugging

$scriptName = $MyInvocation.MyCommand.Name
# Log the start of the script execution
Write-Log "Script '$scriptName' started."

# Ensure the 'currentOS' variable is defined before proceeding
if (-not $currentOS) {
    Write-Log "Variable 'currentOS' is not defined." "ERROR"
    exit 1  # Exit with an error code if 'currentOS' is missing
}

# Define the path to the RECOVERY scripts folder
$scriptsFolder = Join-Path -Path "$PSScriptRoot/RECOVERY" -ChildPath "scripts"

# Check if the scripts folder exists before executing scripts
if (Test-Path $scriptsFolder) {
    Write-Log "Executing RECOVERY-specific scripts from: $scriptsFolder" "INFO"

    # Retrieve all PowerShell scripts in the folder and execute them
    Get-ChildItem -Path $scriptsFolder -Filter "*.ps1" | ForEach-Object {
        
        # Log the execution of each script
        Write-Log "Running script: $($_.Name)" "EXECUTING"

        try {
            # Execute the script
            & $_.FullName
            Write-Log "Script executed successfully: $($_.Name)" "OK"
        } catch {
            # Handle errors during script execution
            Write-Log "Failed to execute script: $($_.Name). Error: $($_.Exception.Message)" "ERROR"
        }
    }
}

# Define the path to the RECOVERY registry folder
$registryFolder = Join-Path -Path "$PSScriptRoot/RECOVERY" -ChildPath "registry"

if (Test-Path $registryFolder) {
    Write-Log "Importing RECOVERY-specific registry files from: $registryFolder" "INFO"

    # Use the module to handle registry imports
    Set-RegistryEntries -FolderPath $registryFolder
} else {
    Write-Log "Registry folder not found: $registryFolder" "ERROR"
}

# Log the completion of the script execution
Write-Log "Script '$scriptName' execution completed." "INFO"
