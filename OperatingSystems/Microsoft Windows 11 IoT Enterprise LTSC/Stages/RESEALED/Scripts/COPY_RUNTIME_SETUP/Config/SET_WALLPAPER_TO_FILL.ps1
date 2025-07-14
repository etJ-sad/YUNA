$scriptName = $MyInvocation.MyCommand.Name
$registryFolder = Join-Path -Path "$PSScriptRoot" -ChildPath "SET_WALLPAPER_TO_FILL"
$logFile = "C:\Windows\Temp\initializationComplete.log"

# Ensure Temp Directory Exists
if (!(Test-Path "C:\Windows\Temp")) {
    New-Item -ItemType Directory -Path "C:\Windows\Temp" | Out-Null
}

# Function to Write Logs
Function Write-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp $message" | Out-File -Append -FilePath $logFile
}

Write-HOST "[INFO] Script '$scriptName' started."
Write-Log "[INFO] Script '$scriptName' started."

Write-HOST "[INFO] Checking registry folder: $registryFolder"
Write-Log "[INFO] Checking registry folder: $registryFolder"

# Ensure the Registry Folder Exists
if (Test-Path $registryFolder) {
    Get-ChildItem -Path $registryFolder -Filter "*.reg" | ForEach-Object {
        $regFilePath = "`"$($_.FullName)`""  # Properly quote the file path

        Write-Host "[APPLYING] Importing registry file: $($_.Name)"
        Write-Log "[APPLYING] Importing registry file: $($_.Name)"

        try {
            Start-Process -FilePath "reg" -ArgumentList "import $regFilePath" -Wait -NoNewWindow -ErrorAction Stop
            Write-Host "[OK] Registry imported successfully: $($_.Name)"
            Write-Log "[OK] Registry imported successfully: $($_.Name)"
        } catch {
            $errorMsg = "[ERROR] Failed to import registry file: $($_.Name). Error: $($_.Exception.Message)"
            Write-Host $errorMsg
            Write-Log $errorMsg
        }
    }
} else {
    Write-Host "[ERROR] Registry folder not found: $registryFolder"
    Write-Log "[ERROR] Registry folder not found: $registryFolder"
}

Write-Host "[INFO] Script '$scriptName' execution completed."
Write-Log "[INFO] Script '$scriptName' execution completed."
