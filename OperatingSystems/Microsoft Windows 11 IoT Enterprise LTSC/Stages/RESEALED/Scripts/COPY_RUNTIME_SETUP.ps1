# COPY_RUNTIME_SETUP.ps1 - Subscript for YUNA (Yielding Universal Node Automation)

# This script is responsible for:
# - Copying required files from COPY_RUNTIME_SETUP folder to system paths
# - Handling SERVER mode (optional)
# - Logging each step of the process for tracking and debugging

# Define the script name dynamically
$scriptName = $MyInvocation.MyCommand.Name

# Log the start of the script execution
Write-Log "Script '$scriptName' started." "INFO"

# Define the script directory path
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Define the path for the initialization flag file
$initFlag = "C:\Users\Public\initializationComplete.ps1"

# Define source root (COPY_RUNTIME_SETUP)
$sourceRoot = Join-Path -Path $scriptDir -ChildPath "COPY_RUNTIME_SETUP"

# Define specific source paths
$hstartSource = Join-Path -Path $sourceRoot -ChildPath "hstart.exe"
$initScriptSource = Join-Path -Path $sourceRoot -ChildPath "initializationComplete.ps1"
$configSource = Join-Path -Path $sourceRoot -ChildPath "Config"
$runtimeSource = $sourceRoot  # whole folder

# Define destination paths
$hstartDestination = "C:\Windows\Panther\hstart.exe"
$initScriptDestination = $initFlag
$configDestination = "C:\Windows\Panther\Siemens\Config\"
$runtimeDestination = "C:\Recovery\OEM\$OEM$\$$\Setup\Scripts\Siemens\Runtime\"

# Check if the initialization flag already exists
if (Test-Path $initFlag) {
    Write-Log "'initializationComplete.ps1' already exists. Skipping setup." "INFO"
    return
}

# Log the start of system file copying
Write-Log "Copying hstart.exe and initializationComplete.ps1 to system paths." "INFO"

# Attempt to copy system files
try {
    Copy-Item -Path $hstartSource -Destination $hstartDestination -Force
    Copy-Item -Path $initScriptSource -Destination $initScriptDestination -Force
    Write-Log "System scripts copied successfully." "OK"
} catch {
    Write-Log "Failed to copy system scripts. Error: $($_.Exception.Message)" "ERROR"
}

# Log the start of Config copying
Write-Log "Copying configuration files to Siemens config path." "INFO"

# Attempt to copy Config
try {
    Copy-Item -Path "$configSource\*" -Destination $configDestination -Recurse -Force -Container
    Write-Log "Configuration files copied successfully." "OK"
} catch {
    Write-Log "Failed to copy configuration files. Error: $($_.Exception.Message)" "ERROR"
}

# Check for SERVER argument
if ($args.Count -gt 0 -and $args[0].ToUpper() -eq "SERVER") {
    Write-Log "SERVER argument detected – skipping Runtime folder copy." "INFO"
} else {
    # Log the start of Runtime copying
    Write-Log "Copying entire COPY_RUNTIME_SETUP folder to recovery path." "INFO"

    # Attempt to copy full Runtime folder
    try {
        Copy-Item -Path "$runtimeSource\*" -Destination $runtimeDestination -Recurse -Force -Container
        Write-Log "Runtime directory copied successfully." "OK"
    } catch {
        Write-Log "Failed to copy Runtime directory. Error: $($_.Exception.Message)" "ERROR"
    }
}

# Log the completion of the script execution
Write-Log "Script '$scriptName' execution completed." "INFO"
