# RegistryManagement.psm1 - Registry Import Module

# This module provides functions to:
# - Import multiple .reg files from a specified folder (including subfolders)
# - Automate registry modifications using reg.exe
# - Log errors and process status

$registryManagementVersion = 1.0.0

# Function to import all .reg files from a specified folder recursively
function Set-RegistryEntries {
    param (
        [string]$FolderPath
    )

    # Check if the folder exists
    if (-Not (Test-Path -Path $FolderPath)) {
        Write-Log "Registry folder not found: $FolderPath" "ERROR"
        return
    }

    # Get all .reg files in the specified folder and subfolders
    $regFiles = Get-ChildItem -Path $FolderPath -Filter "*.reg" -Recurse

    if ($regFiles.Count -eq 0) {
        Write-Log "No .reg files found in: $FolderPath" "WARNING"
        return
    }

    foreach ($file in $regFiles) {
        $customFile = $file.FullName
        Write-Log "Importing registry file: $customFile" "APPLYING"

        try {
            $output = & reg import "`"$customFile`"" 2>&1
            $exitCode = $LASTEXITCODE  

            if ($exitCode -eq 0) {
                Write-Log "Registry imported successfully: $customFile" "OK"
            } else {
                Write-Log "Failed to import registry file: $customFile. Error: $output" "ERROR"
                Write-Log "Registry import failed with exit code: $exitCode" "ERROR"
            }
        } catch {
            Write-Log "Failed to import registry file: $customFile. Exception: $($_.Exception.Message)" "ERROR"
        }
    }
}

# Export function for external use
Export-ModuleMember -Function Set-RegistryEntries 
