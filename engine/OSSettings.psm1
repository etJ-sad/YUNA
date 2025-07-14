# OSSettings.psm1 - Operating System Configuration Module

# This module provides functions to:
# - Retrieve OS-specific settings from a JSON file
# - Apply registry configurations and scripts based on the settings

$OSSettingsVersion = 1.0.0

# Function to retrieve OS settings from a JSON file
function Get-OSSettings {
    param (
        # The folder where OS settings are stored
        [string]$OSFolder
    )

    # Construct the full path to the settings JSON file
    $settingsFile = Join-Path -Path $OSFolder -ChildPath "settings.json"

    # Check if the settings file exists
    if (Test-Path $settingsFile) {
        # Read and convert the JSON settings file into a PowerShell object
        return Get-Content $settingsFile | ConvertFrom-Json
    }
    else {
        # Display a message if the settings file is not found
        Write-Host "Settings for $OSFolder not found, skipping."
        return $null
    }
}

# Function to apply OS settings based on the retrieved configuration
function Set-OSSettings {
    param (
        # The folder where OS settings and scripts are located
        [string]$OSFolder
    )

    # Retrieve the OS settings
    $settings = Get-OSSettings -OSFolder $OSFolder

    # If no settings are found, exit the function
    if ($settings -eq $null) { return }

    # Apply registry settings
    foreach ($regFile in $settings.RegistryFiles) {
        # Construct the full path to the registry file
        $fullPath = Join-Path -Path $OSFolder -ChildPath $regFile

        # Import the registry file using regedit.exe (silent mode)
        Start-Process "regedit.exe" -ArgumentList "/s", $fullPath -Wait
    }

    # Execute additional setup scripts
    foreach ($script in $settings.Scripts) {
        # Construct the full path to the script
        $fullPath = Join-Path -Path $OSFolder -ChildPath $script

        # Execute the script
        & $fullPath
    }

    # Confirm that the OS configuration has been applied
    Write-Host "OS configuration applied: $($settings.OSName)"
}

# Export the module functions for use in other scripts
Export-ModuleMember -Function Get-OSSettings, Set-OSSettings
