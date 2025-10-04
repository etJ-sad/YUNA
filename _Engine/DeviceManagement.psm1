# DeviceManagement.psm1 - Device Management Module for YUNA

# This module provides functions to:
# - Retrieve the current device model

$DeviceManagement = 1.0.0

# Get the root path of the script/module
$rootPath = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

# Define the path to config.json
$modelMappingPath = "$rootPath\Engine\config.json"

# Load model mapping from JSON
try {
    if (Test-Path $modelMappingPath) {
        $config = Get-Content $modelMappingPath | ConvertFrom-Json
        if ($config -and $config.modelMapping) {
            $modelMapping = $config.modelMapping
        } else {
            Write-Log "Invalid JSON format: 'modelMapping' section missing." "ERROR"
        }
    } else {
        Write-Log "Model mapping JSON not found at: $modelMappingPath" "ERROR"
    }
} catch {
    Write-Log "Error loading model mapping: $_" "ERROR" "ERROR"
    return
}

# Function to get the device model
function Get-DeviceModel {
    try {
        # Use CIM instead of WMI for better performance and future compatibility
        $deviceModel = (Get-CimInstance Win32_ComputerSystem).Model.Trim()

        if (-not $deviceModel) {
            Write-Log "Could not retrieve device model from system."
        }

        # Process the model name
        $modelNameParts = $deviceModel -split ' '

        if ($modelNameParts[0] -eq "SIMATIC") {
            $skip = 1

            if ($modelNameParts[1] -eq "IPC") { 
                $skip = 2
            }

            $modelNameParts = $modelNameParts | Select-Object -Skip $skip
            $name = $modelNameParts -join " "

            # Check if the model exists in the JSON file and replace it
            if ($modelMapping.PSObject.Properties.Name -contains $name) {
				Write-Log "$modelMapping.$name"
                $name = $modelMapping.$name
            }
        } else {
			Write-Log "Error retrieving device model" "ERROR"
            $name = ".debug_device"
        }

        return $name
    } catch {
        Write-Log "Error retrieving device model" "ERROR"
        return $null
    }
}

# Export the function for module use
Export-ModuleMember -Function Get-DeviceModel
