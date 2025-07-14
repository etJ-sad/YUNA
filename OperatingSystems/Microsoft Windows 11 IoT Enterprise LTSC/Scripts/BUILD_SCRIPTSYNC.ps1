# BUILD_SCRIPTSYNC.ps1 - Subscript for YUNA (Yielding Universal Node Automation)

# This script is responsible for:
# - Creating a password-protected ZIP archive of the .ScriptSync directory
# - Renaming the ZIP to 'ScriptSync' (no extension)
# - Copying the archive to the Siemens Panther directory
# - Reading the version number from init.ps1
# - Logging each step of the process for tracking and debugging

# Define the script name dynamically
$scriptName = $MyInvocation.MyCommand.Name

# Log the start of the script execution
Write-Log "Script '$scriptName' started." "INFO"

# Define paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceFolder = Join-Path $scriptDir ".ScriptSync"
$initFile     = Join-Path $sourceFolder "init.ps1"
$destinationZip = Join-Path $scriptDir "ScriptSync.zip"
$finalOutput = Join-Path $scriptDir "ScriptSync"
$siemensTarget = "C:\Windows\Panther\Siemens"
$sevenZipPath = Join-Path $scriptDir ".7z\7z.exe"
$password = "SiemensIPC"
$version = $null

# Cleanup existing archive
if (Test-Path $finalOutput) {
    try {
        Remove-Item $finalOutput -Force
        Write-Log "Existing 'ScriptSync' archive removed." "OK"
    } catch {
        Write-Log "Failed to remove existing 'ScriptSync'. Error: $($_.Exception.Message)" "ERROR"
    }
}

# Ensure target directory exists
if (-not (Test-Path $siemensTarget)) {
    try {
        New-Item -Path $siemensTarget -ItemType Directory -Force | Out-Null
        Write-Log "Created directory: $siemensTarget" "OK"
    } catch {
        Write-Log "Failed to create target directory. Error: $($_.Exception.Message)" "ERROR"
    }
}

# Create password-protected ZIP archive
try {
    & "$sevenZipPath" a -tzip -p"$password" "$destinationZip" "$sourceFolder\*" | Out-Null
    Write-Log "ZIP archive created successfully at '$destinationZip'." "OK"
} catch {
    Write-Log "Failed to create ZIP archive. Error: $($_.Exception.Message)" "ERROR"
}

# Rename ZIP to 'ScriptSync' (no extension)
try {
    if (Test-Path $destinationZip) {
        Rename-Item -Path $destinationZip -NewName "ScriptSync"
        Write-Log "Renamed 'ScriptSync.zip' to 'ScriptSync'." "OK"
    }
} catch {
    Write-Log "Failed to rename ZIP archive. Error: $($_.Exception.Message)" "ERROR"
}

# Copy archive to Siemens Panther directory
try {
    Copy-Item -Path $finalOutput -Destination $siemensTarget -Force
    Write-Log "Copied 'ScriptSync' archive to '$siemensTarget'." "OK"
} catch {
    Write-Log "Failed to copy archive to Panther. Error: $($_.Exception.Message)" "ERROR"
}

# Extract version from local init.ps1
if (Test-Path $initFile) {
    try {
        $content = Get-Content $initFile
        $match = $content | Select-String -Pattern '\$version\s*=\s*"(.*?)"' -AllMatches
        if ($match.Matches.Count -gt 0) {
            $version = $match.Matches[0].Groups[1].Value
            Write-Log "Detected ScriptSync version: $version" "OK"
        } else {
            Write-Log "Version string not found in 'init.ps1'." "INFO"
        }
    } catch {
        Write-Log "Failed to read version from 'init.ps1'. Error: $($_.Exception.Message)" "ERROR"
    }
} else {
    Write-Log "'init.ps1' not found at '$initFile'." "ERROR"
}

# Final summary output
Write-Log "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" "INFO"
Write-Log "ScriptSync build completed successfully!" "INFO"
if ($version) {
    Write-Log "ScriptSync version: $version" "INFO"
}
Write-Log "Everything is in place and ready to go." "INFO"
Write-Log "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" "INFO"

# Log the completion of the script execution
Write-Log "Script '$scriptName' execution completed." "INFO"
