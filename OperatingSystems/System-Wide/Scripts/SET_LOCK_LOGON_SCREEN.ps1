# SET_LOCK_LOGON_SCREEN.ps1 - Subscript for YUNA (Yielding Universal Node Automation)

# This script is responsible for:
# - Copying the lock screen images to the Windows system directory
# - Updating the registry keys to apply the new lock screen images
# - Logging each step of the process for tracking and debugging

# Define the script name dynamically
$scriptName = $MyInvocation.MyCommand.Name

# Log the start of the script execution
Write-Log "Script '$scriptName' started." "INFO"

# Define the script directory path
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Define the paths for the source lock screen images
$imagePath = Join-Path -Path $scriptDir -ChildPath "SET_LOCK_LOGON_SCREEN\SIMATIC_IPC_Device.jpg"
$imagePath2 = Join-Path -Path $scriptDir -ChildPath "SET_LOCK_LOGON_SCREEN\SIMATIC_IPC_CIty.jpg"

# Define the destination paths where the images will be copied
$destinationPath = "C:\Windows\Web\Screen\Lockscreen.jpg"
$destinationPath2 = "C:\Windows\Web\Screen\Lockscreen_alternative.jpg"

# Log the start of the image copying process
Write-Log "Copying lock screen images to destination." "INFO"

# Attempt to copy the images to the destination path
try {
    # Copy the main lock screen image
    Copy-Item -Path $imagePath -Destination $destinationPath -Force

    # Copy the alternative lock screen image
    Copy-Item -Path $imagePath2 -Destination $destinationPath2 -Force

    # Log success message
    Write-Log "Lock screen images copied successfully." "OK"
} catch {
    # Log any errors encountered during the copying process
    Write-Log "Failed to copy lock screen images. Error: $($_.Exception.Message)" "ERROR"
}

# Define the path to the folder containing registry files
$registryFolder = Join-Path -Path "$PSScriptRoot" -ChildPath "SET_LOCK_LOGON_SCREEN"

# Debugging log (commented out by default)
# Write-Log "DEBUG: Checking registry folder: $registryFolder"

# Ensure that the registry folder exists before proceeding
if (Test-Path $registryFolder) {
    # Call the function from RegistryManagement module
    Set-RegistryEntries -FolderPath $registryFolder
} else {
    Write-Log "ERROR: Registry folder not found: $registryFolder" "ERROR"
}

# Log the completion of the script execution
Write-Log "Script '$scriptName' execution completed." "INFO"
