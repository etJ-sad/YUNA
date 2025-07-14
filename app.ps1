# Main script for YUNA (Yielding Universal Node Automation)
$startTime = Get-Date

if (Test-Path "$PSScriptRoot\YUNA_DONE") {
    Remove-Item -Path "$PSScriptRoot\YUNA_DONE" -Force
}

if (Test-Path "$PSScriptRoot\YUNA_NOT_SUPPORTED") {
    Remove-Item -Path "$PSScriptRoot\YUNA_NOT_SUPPORTED" -Force
}

# Import engine modules
$modules = @(
    "Logging.psm1",
    "DeviceManagement.psm1",
    "OSSettings.psm1",
    "RegistryManagement.psm1"
)

foreach ($module in $modules) {
    $modulePath = Join-Path -Path "$PSScriptRoot/engine" -ChildPath $module
    try {
        if (Test-Path $modulePath) {
            Import-Module -Name $modulePath -Force
            Write-Log "Successfully imported module: $module" "INIT"
        } else {
            throw "Module not found: $modulePath"
        }
    } catch {
        Write-Log "Failed to import module: $module. Exception: $($_.Exception.Message)" "ERROR"
        exit 1
    }
}

# Load configuration
$configPath = "$PSScriptRoot/config.json"
if (!(Test-Path $configPath)) {
    Write-Log "Configuration file not found: $configPath" "ERROR"
    exit
}
$config = Get-Content $configPath | ConvertFrom-Json

# Always display INIT information
if ($config.debug -eq $true) { Write-Log "DEBUG MODE" "DEBUG" }
Write-Log "Initializing YUNA System..." "INIT"
Write-Log "YUNA Version: $($config.Version)" "INIT"
Write-Log "Current User: $([Environment]::UserName)" "INIT"
Write-Log "System Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "INIT"

if ($config.debug -eq $true) {
    $cpuUsage = Get-Counter '\Processor(_Total)\% Processor Time'
    $memoryUsage = Get-Process | Measure-Object WorkingSet64 -Sum
    Write-Log "CPU Usage: $($cpuUsage.CounterSamples[0].CookedValue)%" "DEBUG"
    Write-Log "Memory Usage: $([math]::Round($memoryUsage.Sum / 1MB, 2)) MB" "DEBUG"
	$loadedModules = Get-Module
    Write-Log "Loaded PowerShell Modules:" "DEBUG"
    foreach ($mod in $loadedModules) {
        Write-Log "Module: $($mod.Name) - Version: $($mod.Version)" "DEBUG"
    }
	$scriptPermissions = Get-Acl -Path $PSScriptRoot
    Write-Log "Script Folder Permissions:" "DEBUG"
    Write-Log "$($scriptPermissions | Out-String)" "DEBUG"
	if ($config.debug -eq $true) {
		$pingTest = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet
		Write-Log "Internet Connection: $(if ($pingTest) { 'Available' } else { 'Not Available' })" "DEBUG"
	}
}

# Detect current device model using WMI
$deviceModel = Get-DeviceModel
if ($deviceModel -eq ".debug_device") { 
	if ($config.debug -eq $true) { 
		Write-Log "Detected Device Model: $deviceModel" "DEBUG" 
	}
} else {
	Write-Log "Detected Device Model: $deviceModel" "INFO"
}

# Load device-specific JSON file
$deviceFile = Join-Path -Path "$PSScriptRoot/devices" -ChildPath "$deviceModel.json"
if (!(Test-Path $deviceFile)) {
	if ($config.debug -eq $true) { Write-Log "Device configuration file not found: $deviceFile" "ERROR" } 
    Write-Log "The current IPC model is not supported by YUNA." "ERROR"
	Write-Output "ERROR: The current IPC model is not supported by YUNA." | Out-File $PSScriptRoot\YUNA_NOT_SUPPORTED
    exit
}
$deviceConfig = Get-Content $deviceFile | ConvertFrom-Json

# Extract supported OS keys
$supportedOS = $deviceConfig.supportedOS.PSObject.Properties.Name

Write-Log "Supported OS for ${deviceModel}:" "INFO"
$supportedOS | ForEach-Object { Write-Log "    $_" "INFO" }

# Get current OS
$currentOS = (Get-CimInstance Win32_OperatingSystem).Caption
Write-Log "Detected Operating System: $currentOS" "INFO"

# Check if current OS is supported
if ($supportedOS -notcontains $currentOS) {
    Write-Log "Current OS ($currentOS) is not supported by ${deviceModel}." "ERROR"
    exit 1
}

Write-Log "Current OS ($currentOS) is supported for ${deviceModel}." "OK"

# Apply System-Wide-specific settings
Write-Log "Applying System-Wide-specific configurations for all operating systems" "INFO"
$scriptsFolder = Join-Path -Path "$PSScriptRoot/operatingsystems/System-Wide" -ChildPath "scripts"
if (Test-Path $scriptsFolder) {
    Get-ChildItem -Path $scriptsFolder -Filter "*.ps1" | ForEach-Object {
        Write-Log "Running script: $($_.Name)" "EXECUTING"
        try {
            & $_.FullName
            Write-Log "Script executed successfully: $($_.Name)" "OK"
        } catch {
            Write-Log "Failed to execute script: $($_.Name). Error: $($_.Exception.Message)" "ERROR"
        }
    }
}

# Import System-Wide-specific registry files
$registryFolder = Join-Path -Path "$PSScriptRoot/operatingsystems/System-Wide" -ChildPath "Registry"
try {
    if (Test-Path $registryFolder) {
        Write-Log "Importing system-wide registry files from: $registryFolder" "INFO"

        # Ensure the function exists before calling it
        if (Get-Command -Name Set-RegistryEntries -ErrorAction SilentlyContinue) {
            Set-RegistryEntries -FolderPath $registryFolder
        } else {
            throw "Set-RegistryEntries function not found."
        }
    } else {
        throw "Registry folder not found: $registryFolder"
    }
} catch {
    Write-Log "An error occurred: $_" "ERROR"
}

# Apply OS-specific configurations
Write-Log "Applying OS-specific configurations for $currentOS" "INFO"
$scriptsFolder = Join-Path -Path "$PSScriptRoot/operatingsystems/$currentOS" -ChildPath "Scripts"
if (Test-Path $scriptsFolder) {
    Get-ChildItem -Path $scriptsFolder -Filter "*.ps1" | ForEach-Object {
        Write-Log "Running script: $($_.Name)" "EXECUTING"
        try {
            & $_.FullName
            Write-Log "Script executed successfully: $($_.Name)" "OK"
        } catch {
            Write-Log "Failed to execute script: $($_.Name). Error: $($_.Exception.Message)" "ERROR"
        }
    }
}

$registryFolder = Join-Path -Path "$PSScriptRoot/operatingsystems/$currentOS" -ChildPath "Registry"
# Import OS-specific registry files  
try {
    if (Test-Path $registryFolder) {
        Write-Log "Importing OS-specific registry files from: $registryFolder" "INFO"

        # Ensure the function exists before calling it
        if (Get-Command -Name Set-RegistryEntries -ErrorAction SilentlyContinue) {
            Set-RegistryEntries -FolderPath $registryFolder
        } else {
            throw "Set-RegistryEntries function not found."
        }
    } else {
        throw "Registry folder not found: $registryFolder"
    }
} catch {
    Write-Log "An error occurred: $_" "ERROR"
}

# Apply device-specific configurations
Write-Log "Applying device-specific configurations for $deviceModel" "INFO"
foreach ($configKey in $deviceConfig.PSObject.Properties.Name) {
    if ($configKey -notin @("DeviceModel", "SupportedOS")) {
        $customFile = Join-Path -Path "$PSScriptRoot/devices/$deviceModel" -ChildPath $deviceConfig.$configKey
        
        if (Test-Path $customFile) {
            Write-Log "Processing device-specific setting: $configKey -> $($deviceConfig.$configKey)" "INFO"
            
            $fileExtension = [System.IO.Path]::GetExtension($customFile).ToLower()

            switch ($fileExtension) {
                ".ps1" {
                    Write-Log "Executing PowerShell script: $customFile" "EXECUTING"
                    try {
                        & $customFile
                        Write-Log "Script executed successfully: $customFile" "OK"
                    } catch {
                        Write-Log "Failed to execute script: $customFile. Error: $($_.Exception.Message)" "ERROR"
                    }
                }
                ".cmd" {
                    Write-Log "Executing CMD script: $customFile" "EXECUTING"
                    try {
                        Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$customFile`"" -Wait -NoNewWindow
                        Write-Log "CMD script executed successfully: $customFile" "OK"
                    } catch {
                        Write-Log "Failed to execute CMD script: $customFile. Error: $($_.Exception.Message)" "ERROR"
                    }
                }
				".reg" {
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
                ".exe" {
                    Write-Log "Running executable: $customFile" "EXECUTING"
                    try {
                        Start-Process -FilePath $customFile -Wait -NoNewWindow
                        Write-Log "Executable ran successfully: $customFile" "OK"
                    } catch {
                        Write-Log "Failed to run executable: $customFile. Error: $($_.Exception.Message)" "ERROR"
                    }
                }
                ".msi" {
                    Write-Log "Running MSI installer: $customFile" "EXECUTING"
                    try {
                        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$customFile`"" -Wait -NoNewWindow
                        Write-Log "MSI installed successfully: $customFile" "OK"
                    } catch {
                        Write-Log "Failed to install MSI: $customFile. Error: $($_.Exception.Message)" "ERROR"
                    }
                }
                default {
                    Write-Log "Unsupported file type for custom setting: $customFile" "WARNING"
                }
            }
        } else {
            Write-Log "File not found for custom setting: $configKey -> $($deviceConfig.$configKey)" "WARNING"
        }
    }
}

# Handle stage selection and execution
$currentStageFile = "$PSScriptRoot/current_stage.json"
if (Test-Path $currentStageFile) {
    Write-Log "Using saved stage from file: $currentStageFile" "INFO"
    $currentStage = Get-Content $currentStageFile | ConvertFrom-Json
    Write-Log "Current Stage: $($currentStage.Stage)" "INFO"
} else {
    Write-Log "Available Image Stages:" "INFO"
    $config.Images | ForEach-Object -Begin { $i = 1 } -Process {
        Write-Log "    [$i] [Stage: $($_.Stage)] - [Type: $($_.imageType)]" "INFO"
        $_ | Add-Member -MemberType NoteProperty -Name Index -Value $i
        $i++
    }
    $selectedInput = Read-Host "[INPUT] Enter the stage number or name (e.g., 1 or 1stImage)"
    $currentStage = if ($selectedInput -as [int]) {
        $config.Images | Where-Object { $_.Index -eq [int]$selectedInput }
    } else {
        $config.Images | Where-Object { $_.Stage -eq $selectedInput }
    }
    if ($null -eq $currentStage) {
        Write-Log "Invalid stage selected. Exiting." "ERROR"
        exit
    }
    try {
        $currentStage | ConvertTo-Json -Depth 2 | Set-Content -Path $currentStageFile
        Write-Log "Stage saved successfully to: $currentStageFile" "OK"
    } catch {
        Write-Log "Failed to save selected stage: $($_.Exception.Message)" "ERROR"
        exit
    }
    Write-Log "Selected Stage: $($currentStage.Stage)" "OK"
}

# Execute stage script
$stageScript = "$PSScriptRoot/operatingsystems/$currentOS/stages/$($currentStage.ImageType).ps1"
if (Test-Path $stageScript) {
    Write-Log "Running stage script: $stageScript" "EXECUTING"
    try {
        & $stageScript
        Write-Log "Stage script executed successfully: $($currentStage.ImageType)" "OK"
    } catch {
        Write-Log "Failed to execute stage script: $($_.Exception.Message)" "ERROR"
    }
} else {
    Write-Log "Stage script not found: $stageScript" "WARNING"
}

$endTime = Get-Date
$duration = $endTime - $startTime
$formattedDuration = "{0:D2}:{1:D2}:{2:D2}" -f $duration.Hours, $duration.Minutes, $duration.Seconds

Write-Log "YUNA execution completed." "INIT"
Write-Log "Total execution time: $formattedDuration (HH:MM:SS)" "INIT"
Write-Output "INIT: YUNA execution completed. Total execution time: $formattedDuration (HH:MM:SS)" | Out-File $PSScriptRoot\YUNA_DONE
