# ACTIVATE_WINDOWS.ps1 - Subscript for YUNA (Yielding Universal Node Automation)

# This script is responsible for:
# - Extracting the operating system configuration from the device settings.
# - Determining the activation method (Windows key or CYP file).
# - Activating Windows using slmgr or encrypted PKEA.
# - Logging each step for tracking and debugging.

# Define the script name dynamically
$scriptName = $MyInvocation.MyCommand.Name
Write-Log "Script '$scriptName' started." "INFO"

# Define paths
$scriptRoot = $PSScriptRoot
$activationFolder = Join-Path $rootPath "Engine\KeyBase"
$mEncryptExe = Join-Path $activationFolder "MEncryptPKEAFile.exe"
$cleanCmd = Join-Path $activationFolder "SieActivation.cmd"

Write-Log "Script root: $rootPath" "DEBUG"
Write-Log "Activation folder: $activationFolder" "DEBUG"
Write-Log "MEncryptPKEAFile.exe path: $mEncryptExe" "DEBUG"

# Get OS configuration
Write-Log "Current OS: $currentOS" "DEBUG"
$osConfig = $deviceConfig.supportedOS.$currentOS

if (-not $osConfig) {
    Write-Log "No device configuration found for OS: $currentOS" "ERROR"
    return
}

Write-Log "Loaded OS config object: $($osConfig | Out-String)" "DEBUG"

# Windows Client → CYP Activation
if ($osConfig.PSObject.Properties.Name -contains "cypFile") {
    $cypName = $osConfig.cypFile
    $cypPath = Join-Path $activationFolder "$cypName"
    Write-Log "Looking for CYP file: $cypPath" "DEBUG"

    if (Test-Path $cypPath) {
        Write-Log "Encrypting CYP file '$cypName' using MEncryptPKEAFile." "INFO"
        try {
            & "$mEncryptExe" -inputfile "$cypPath" -key2 get
            $exitCode = $LASTEXITCODE
            Write-Log "MEncryptPKEAFile exit code: $exitCode" "DEBUG"

            if ($exitCode -eq 1) {
                Write-Log "CYP activation completed successfully." "OK"
                return
            } else {
                Write-Log "CYP activation failed with exit code $exitCode." "ERROR"
            }
        } catch {
            Write-Log "Failed to run MEncryptPKEAFile. Error: $($_.Exception.Message)" "ERROR"
        }
    } else {
        Write-Log "CYP file not found at: $cypPath" "ERROR"
    }
}

# Windows Server → Product Key + PKEA Uninstall
if ($osConfig.PSObject.Properties.Name -contains "windowsKey") {
    $key = $osConfig.windowsKey
	$license = $osConfig.windowsLicense
    Write-Log "Applying Windows key: $key" "INFO"
    try {
        & cscript "$env:windir\system32\slmgr.vbs" -ipk $key 
		& cscript "$env:windir\system32\slmgr.vbs" -ilc $license
        Write-Log "Windows product key applied successfully." "OK"
    } catch {
        Write-Log "Failed to apply product key. Error: $($_.Exception.Message)" "ERROR"
    }

    Write-Log "Uninstalling Embedded PKEA using SieActivation.cmd clean." "INFO"
    try {
        & "$cleanCmd" clean
        Write-Log "Embedded PKEA uninstalled successfully." "OK"
    } catch {
        Write-Log "Failed to execute SieActivation.cmd clean. Error: $($_.Exception.Message)" "ERROR"
    }
}

# End
Write-Log "Script '$scriptName' execution completed." "INFO"
