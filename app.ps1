# Main script for YUNA (Yielding Universal Node Automation) - Clean Root Version
$startTime = Get-Date

# Cleanup previous run indicators  
if (Test-Path "$PSScriptRoot\YUNA_DONE") {
    Remove-Item -Path "$PSScriptRoot\YUNA_DONE" -Force
}

if (Test-Path "$PSScriptRoot\YUNA_NOT_SUPPORTED") {
    Remove-Item -Path "$PSScriptRoot\YUNA_NOT_SUPPORTED" -Force
}

# Define engine directory
$enginePath = Join-Path $PSScriptRoot "Engine"

# Import enhanced logging module first
try {
    $loggingModulePath = Join-Path $enginePath "Logging.psm1"
    if (Test-Path $loggingModulePath) {
        Import-Module -Name $loggingModulePath -Force
        
        # Load logging configuration from Engine directory
        $loggingConfigPath = Join-Path $enginePath "logging-config.json"
        $loggingConfig = @{}
        
        if (Test-Path $loggingConfigPath) {
            $configContent = Get-Content $loggingConfigPath | ConvertFrom-Json
            $environment = if ($env:YUNA_ENVIRONMENT) { $env:YUNA_ENVIRONMENT } else { "development" }
            
            # Merge base config with environment-specific config
            $loggingConfig = @{}
            foreach ($prop in $configContent.loggingConfig.PSObject.Properties) {
                $loggingConfig[$prop.Name] = $prop.Value
            }
            if ($configContent.logLevels.$environment) {
                foreach ($prop in $configContent.logLevels.$environment.PSObject.Properties) {
                    $loggingConfig[$prop.Name] = $prop.Value
                }
            }
        }
        
        # Initialize enhanced logging system
        Initialize-LoggingSystem -RootPath $PSScriptRoot -CustomConfig $loggingConfig
        Write-Log "Enhanced logging system initialized successfully" -Level "SUCCESS"
    } else {
        throw "Enhanced logging module not found: $loggingModulePath"
    }
} catch {
    Write-Host "[CRITICAL] Failed to initialize enhanced logging: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Make sure Engine\Logging.psm1 exists and is the enhanced version" -ForegroundColor Yellow
    exit 1
}

# Import other engine modules
$modules = @(
    "DeviceManagement.psm1",
    "OSSettings.psm1", 
    "RegistryManagement.psm1"
)

foreach ($module in $modules) {
    $modulePath = Join-Path $enginePath $module
    try {
        if (Test-Path $modulePath) {
            Import-Module -Name $modulePath -Force
            Write-LogSuccess "Successfully imported module: $module" -Context @{ ModulePath = $modulePath }
        } else {
            throw "Module not found: $modulePath"
        }
    } catch {
        Write-LogError "Failed to import module: $module" -Context @{ ModulePath = $modulePath } -Exception $_.Exception
        exit 1
    }
}

# Start performance tracking for entire YUNA execution
Start-PerformanceTimer -OperationName "YUNA_Total_Execution"

# Load configuration from Engine directory
$configPath = Join-Path $enginePath "config.json"
if (!(Test-Path $configPath)) {
    Write-LogError "Configuration file not found" -Context @{ ConfigPath = $configPath }
    exit
}

try {
    $config = Get-Content $configPath | ConvertFrom-Json
    Write-LogSuccess "Configuration loaded successfully" -Context @{ 
        ConfigPath = $configPath
        Version = $config.Version
        Debug = $config.debug
    }
} catch {
    Write-LogError "Failed to parse configuration file" -Context @{ ConfigPath = $configPath } -Exception $_.Exception
    exit
}

# Enhanced initialization logging
Write-Log "Initializing YUNA System..." -Level "INIT" -Context @{
    Version = $config.Version
    User = [Environment]::UserName
    Computer = $env:COMPUTERNAME
    PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    ExecutionPolicy = Get-ExecutionPolicy
    StartTime = $startTime.ToString('yyyy-MM-dd HH:mm:ss')
    EngineDirectory = $enginePath
}

# Debug information with enhanced context
if ($config.debug -eq $true) { 
    Write-LogDebug "Debug mode enabled" -Context @{
        PSVersion = $PSVersionTable.PSVersion
        OS = [System.Environment]::OSVersion.VersionString
        ProcessId = $PID
        WorkingDirectory = Get-Location
        YunaRootDirectory = $PSScriptRoot
        EngineDirectory = $enginePath
    }
    
    # System performance metrics
    try {
        $cpuUsage = Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1
        $memoryInfo = Get-CimInstance -ClassName Win32_OperatingSystem
        $diskInfo = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
        
        Write-LogDebug "System performance metrics gathered" -Context @{
            CPUUsage = [math]::Round($cpuUsage.CounterSamples[0].CookedValue, 2)
            TotalMemoryGB = [math]::Round($memoryInfo.TotalVisibleMemorySize / 1MB, 2)
            FreeMemoryGB = [math]::Round($memoryInfo.FreePhysicalMemory / 1MB, 2)
            MemoryUsagePercent = [math]::Round((1 - ($memoryInfo.FreePhysicalMemory / $memoryInfo.TotalVisibleMemorySize)) * 100, 2)
            DiskInfo = $diskInfo | ForEach-Object { 
                @{
                    Drive = $_.DeviceID
                    SizeGB = [math]::Round($_.Size / 1GB, 2)
                    FreeGB = [math]::Round($_.FreeSpace / 1GB, 2)
                    UsagePercent = [math]::Round((1 - ($_.FreeSpace / $_.Size)) * 100, 2)
                }
            }
        }
    } catch {
        Write-LogWarning "Failed to gather system performance metrics" -Exception $_.Exception
    }
}

# Device detection with performance tracking
Start-PerformanceTimer -OperationName "Device_Detection"
$deviceModel = Get-DeviceModel

if ($deviceModel -eq ".debug_device") { 
    if ($config.debug -eq $true) { 
        Write-LogDebug "Debug device model detected" -Context @{ DeviceModel = $deviceModel }
    }
} else {
    Write-LogInfo "Device model detected" -Context @{ DeviceModel = $deviceModel }
}
Stop-PerformanceTimer -OperationName "Device_Detection"

# Load device configuration with enhanced validation
Start-PerformanceTimer -OperationName "Device_Config_Load"
$deviceFile = Join-Path -Path "$PSScriptRoot/Devices" -ChildPath "$deviceModel.json"

if (!(Test-Path $deviceFile)) {
    Write-LogError "Device configuration not found - unsupported device" -Context @{ 
        DeviceModel = $deviceModel
        DeviceFile = $deviceFile
        AvailableDevices = (Get-ChildItem "$PSScriptRoot/Devices" -Filter "*.json" -ErrorAction SilentlyContinue).BaseName
    }
    Write-Output "ERROR: The current IPC model is not supported by YUNA." | Out-File $PSScriptRoot\YUNA_NOT_SUPPORTED
    exit
}

try {
    $deviceConfig = Get-Content $deviceFile | ConvertFrom-Json
    Write-LogSuccess "Device configuration loaded" -Context @{ 
        DeviceModel = $deviceModel
        ConfigFile = $deviceFile
        SupportedOSCount = $deviceConfig.supportedOS.PSObject.Properties.Count
    }
} catch {
    Write-LogError "Failed to parse device configuration" -Context @{ DeviceFile = $deviceFile } -Exception $_.Exception
    exit
}
Stop-PerformanceTimer -OperationName "Device_Config_Load"

# Extract and validate supported OS
$supportedOS = $deviceConfig.supportedOS.PSObject.Properties.Name
Write-LogInfo "Supported operating systems enumerated" -Context @{ 
    DeviceModel = $deviceModel
    SupportedOS = $supportedOS
    OSCount = $supportedOS.Count
}

# OS detection and validation
$currentOS = (Get-CimInstance Win32_OperatingSystem).Caption
Write-LogInfo "Operating system detected" -Context @{ 
    CurrentOS = $currentOS
    OSVersion = [System.Environment]::OSVersion.Version.ToString()
    Architecture = [System.Environment]::Is64BitOperatingSystem
}

if ($supportedOS -notcontains $currentOS) {
    Write-LogError "Unsupported operating system" -Context @{ 
        CurrentOS = $currentOS
        SupportedOS = $supportedOS
        DeviceModel = $deviceModel
    }
    exit 1
}

Write-LogSuccess "Operating system validation passed" -Context @{ 
    CurrentOS = $currentOS
    DeviceModel = $deviceModel
}

# Apply System-Wide configurations
Write-LogInfo "Starting system-wide configurations" -Component "SystemConfig"
Start-PerformanceTimer -OperationName "SystemWide_Config"

$scriptsFolder = Join-Path -Path "$PSScriptRoot/OperatingSystems/System-Wide" -ChildPath "scripts"
if (Test-Path $scriptsFolder) {
    $scripts = Get-ChildItem -Path $scriptsFolder -Filter "*.ps1"
    Write-LogInfo "System-wide scripts discovered" -Context @{ 
        ScriptCount = $scripts.Count
        ScriptFolder = $scriptsFolder
        Scripts = $scripts.Name
    }
    
    foreach ($script in $scripts) {
        Start-PerformanceTimer -OperationName "Script_$($script.BaseName)"
        Write-Log "Executing system-wide script" -Level "EXECUTING" -Context @{ 
            ScriptName = $script.Name
            ScriptPath = $script.FullName
        }
        
        try {
            & $script.FullName
            Write-LogSuccess "Script executed successfully" -Context @{ ScriptName = $script.Name }
        } catch {
            Write-LogError "Script execution failed" -Context @{ 
                ScriptName = $script.Name
                ScriptPath = $script.FullName
            } -Exception $_.Exception
        }
        Stop-PerformanceTimer -OperationName "Script_$($script.BaseName)" -AdditionalContext @{ ScriptName = $script.Name }
    }
} else {
    Write-LogWarning "System-wide scripts folder not found" -Context @{ ScriptFolder = $scriptsFolder }
}

Stop-PerformanceTimer -OperationName "SystemWide_Config"

# Registry import with enhanced logging
Write-LogInfo "Starting system-wide registry imports" -Component "RegistryConfig"
Start-PerformanceTimer -OperationName "SystemWide_Registry"

$registryFolder = Join-Path -Path "$PSScriptRoot/OperatingSystems/System-Wide" -ChildPath "Registry"
try {
    if (Test-Path $registryFolder) {
        Write-LogInfo "System-wide registry folder found" -Context @{ RegistryFolder = $registryFolder }
        
        if (Get-Command -Name Set-RegistryEntries -ErrorAction SilentlyContinue) {
            Set-RegistryEntries -FolderPath $registryFolder
        } else {
            throw "Set-RegistryEntries function not found."
        }
    } else {
        Write-LogWarning "System-wide registry folder not found" -Context @{ RegistryFolder = $registryFolder }
    }
} catch {
    Write-LogError "Registry import failed" -Context @{ RegistryFolder = $registryFolder } -Exception $_.Exception
}

Stop-PerformanceTimer -OperationName "SystemWide_Registry"

# OS-specific configurations with enhanced tracking
Write-LogInfo "Starting OS-specific configurations" -Component "OSConfig" -Context @{ OperatingSystem = $currentOS }
Start-PerformanceTimer -OperationName "OSSpecific_Config"

$osScriptsFolder = Join-Path -Path "$PSScriptRoot/OperatingSystems/$currentOS" -ChildPath "Scripts"
if (Test-Path $osScriptsFolder) {
    $osScripts = Get-ChildItem -Path $osScriptsFolder -Filter "*.ps1"
    Write-LogInfo "OS-specific scripts discovered" -Context @{ 
        ScriptCount = $osScripts.Count
        ScriptFolder = $osScriptsFolder
        Scripts = $osScripts.Name
        OperatingSystem = $currentOS
    }
    
    foreach ($script in $osScripts) {
        Start-PerformanceTimer -OperationName "OSScript_$($script.BaseName)"
        Write-Log "Executing OS-specific script" -Level "EXECUTING" -Context @{ 
            ScriptName = $script.Name
            ScriptPath = $script.FullName
            OperatingSystem = $currentOS
        }
        
        try {
            & $script.FullName
            Write-LogSuccess "OS-specific script executed successfully" -Context @{ 
                ScriptName = $script.Name
                OperatingSystem = $currentOS
            }
        } catch {
            Write-LogError "OS-specific script execution failed" -Context @{ 
                ScriptName = $script.Name
                ScriptPath = $script.FullName
                OperatingSystem = $currentOS
            } -Exception $_.Exception
        }
        Stop-PerformanceTimer -OperationName "OSScript_$($script.BaseName)" -AdditionalContext @{ 
            ScriptName = $script.Name
            OperatingSystem = $currentOS
        }
    }
} else {
    Write-LogWarning "OS-specific scripts folder not found" -Context @{ 
        ScriptFolder = $osScriptsFolder
        OperatingSystem = $currentOS
    }
}

# OS-specific registry imports
$osRegistryFolder = Join-Path -Path "$PSScriptRoot/OperatingSystems/$currentOS" -ChildPath "Registry"
try {
    if (Test-Path $osRegistryFolder) {
        Write-LogInfo "OS-specific registry folder found" -Context @{ 
            RegistryFolder = $osRegistryFolder
            OperatingSystem = $currentOS
        }
        
        if (Get-Command -Name Set-RegistryEntries -ErrorAction SilentlyContinue) {
            Set-RegistryEntries -FolderPath $osRegistryFolder
        } else {
            throw "Set-RegistryEntries function not found."
        }
    } else {
        Write-LogWarning "OS-specific registry folder not found" -Context @{ 
            RegistryFolder = $osRegistryFolder
            OperatingSystem = $currentOS
        }
    }
} catch {
    Write-LogError "OS-specific registry import failed" -Context @{ 
        RegistryFolder = $osRegistryFolder
        OperatingSystem = $currentOS
    } -Exception $_.Exception
}

Stop-PerformanceTimer -OperationName "OSSpecific_Config"

# Device-specific configurations with detailed tracking
Write-LogInfo "Starting device-specific configurations" -Component "DeviceConfig" -Context @{ DeviceModel = $deviceModel }
Start-PerformanceTimer -OperationName "DeviceSpecific_Config"

$processedSettings = @()
$failedSettings = @()

foreach ($configKey in $deviceConfig.PSObject.Properties.Name) {
    if ($configKey -notin @("DeviceModel", "SupportedOS")) {
        $customFile = Join-Path -Path "$PSScriptRoot/Devices/$deviceModel" -ChildPath $deviceConfig.$configKey
        
        Start-PerformanceTimer -OperationName "DeviceSetting_$configKey"
        
        if (Test-Path $customFile) {
            Write-LogInfo "Processing device-specific setting" -Context @{ 
                ConfigKey = $configKey
                FileName = $deviceConfig.$configKey
                FilePath = $customFile
                DeviceModel = $deviceModel
            }
            
            $fileExtension = [System.IO.Path]::GetExtension($customFile).ToLower()

            try {
                switch ($fileExtension) {
                    ".ps1" {
                        Write-Log "Executing PowerShell script" -Level "EXECUTING" -Context @{ 
                            ConfigKey = $configKey
                            FilePath = $customFile
                        }
                        & $customFile
                        Write-LogSuccess "PowerShell script executed successfully" -Context @{ 
                            ConfigKey = $configKey
                            FilePath = $customFile
                        }
                    }
                    ".cmd" {
                        Write-Log "Executing CMD script" -Level "EXECUTING" -Context @{ 
                            ConfigKey = $configKey
                            FilePath = $customFile
                        }
                        Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$customFile`"" -Wait -NoNewWindow
                        Write-LogSuccess "CMD script executed successfully" -Context @{ 
                            ConfigKey = $configKey
                            FilePath = $customFile
                        }
                    }
                    ".reg" {
                        Write-Log "Importing registry file" -Level "APPLYING" -Context @{ 
                            ConfigKey = $configKey
                            FilePath = $customFile
                        }
                        $output = & reg import "`"$customFile`"" 2>&1
                        $exitCode = $LASTEXITCODE  

                        if ($exitCode -eq 0) {
                            Write-LogSuccess "Registry imported successfully" -Context @{ 
                                ConfigKey = $configKey
                                FilePath = $customFile
                                ExitCode = $exitCode
                            }
                        } else {
                            throw "Registry import failed with exit code: $exitCode. Output: $output"
                        }
                    }
                    ".exe" {
                        Write-Log "Running executable" -Level "EXECUTING" -Context @{ 
                            ConfigKey = $configKey
                            FilePath = $customFile
                        }
                        Start-Process -FilePath $customFile -Wait -NoNewWindow
                        Write-LogSuccess "Executable ran successfully" -Context @{ 
                            ConfigKey = $configKey
                            FilePath = $customFile
                        }
                    }
                    ".msi" {
                        Write-Log "Running MSI installer" -Level "EXECUTING" -Context @{ 
                            ConfigKey = $configKey
                            FilePath = $customFile
                        }
                        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$customFile`"" -Wait -NoNewWindow
                        Write-LogSuccess "MSI installed successfully" -Context @{ 
                            ConfigKey = $configKey
                            FilePath = $customFile
                        }
                    }
                    default {
                        Write-LogWarning "Unsupported file type for custom setting" -Context @{ 
                            ConfigKey = $configKey
                            FilePath = $customFile
                            FileExtension = $fileExtension
                        }
                    }
                }
                $processedSettings += $configKey
            } catch {
                Write-LogError "Device-specific setting failed" -Context @{ 
                    ConfigKey = $configKey
                    FilePath = $customFile
                    FileExtension = $fileExtension
                } -Exception $_.Exception
                $failedSettings += $configKey
            }
        } else {
            Write-LogWarning "File not found for custom setting" -Context @{ 
                ConfigKey = $configKey
                ExpectedFile = $deviceConfig.$configKey
                ExpectedPath = $customFile
                DeviceModel = $deviceModel
            }
            $failedSettings += $configKey
        }
        
        Stop-PerformanceTimer -OperationName "DeviceSetting_$configKey" -AdditionalContext @{
            ConfigKey = $configKey
            Success = ($configKey -in $processedSettings)
        }
    }
}

Stop-PerformanceTimer -OperationName "DeviceSpecific_Config" -AdditionalContext @{
    ProcessedSettings = $processedSettings.Count
    FailedSettings = $failedSettings.Count
    TotalSettings = ($processedSettings.Count + $failedSettings.Count)
}

Write-LogInfo "Device-specific configuration summary" -Context @{
    DeviceModel = $deviceModel
    ProcessedSettings = $processedSettings
    FailedSettings = $failedSettings
    SuccessRate = if (($processedSettings.Count + $failedSettings.Count) -gt 0) { 
        [math]::Round(($processedSettings.Count / ($processedSettings.Count + $failedSettings.Count)) * 100, 2) 
    } else { 100 }
}

# Stage selection and execution with enhanced tracking
Write-LogInfo "Starting stage selection and execution" -Component "StageManager"
Start-PerformanceTimer -OperationName "Stage_Management"

$currentStageFile = "$PSScriptRoot/current_stage.json"
if (Test-Path $currentStageFile) {
    Write-LogInfo "Using saved stage from file" -Context @{ StageFile = $currentStageFile }
    try {
        $currentStage = Get-Content $currentStageFile | ConvertFrom-Json
        Write-LogInfo "Stage loaded from file" -Context @{ 
            Stage = $currentStage.Stage
            ImageType = $currentStage.ImageType
            StageFile = $currentStageFile
        }
    } catch {
        Write-LogError "Failed to parse stage file" -Context @{ StageFile = $currentStageFile } -Exception $_.Exception
        exit
    }
} else {
    Write-LogInfo "Available Image Stages:" -Component "StageSelection"
    $config.Images | ForEach-Object -Begin { $i = 1 } -Process {
        Write-LogInfo "Stage option available" -Context @{
            Index = $i
            Stage = $_.Stage
            ImageType = $_.imageType
            WimFileName = $_.wimFileName
        }
        $_ | Add-Member -MemberType NoteProperty -Name Index -Value $i
        $i++
    }
    
    $selectedInput = Read-Host "[INPUT] Enter the stage number or name (e.g., 1 or 1stImage)"
    Write-LogInfo "User stage selection received" -Context @{ UserInput = $selectedInput }
    
    $currentStage = if ($selectedInput -as [int]) {
        $config.Images | Where-Object { $_.Index -eq [int]$selectedInput }
    } else {
        $config.Images | Where-Object { $_.Stage -eq $selectedInput }
    }
    
    if ($null -eq $currentStage) {
        Write-LogError "Invalid stage selected" -Context @{ 
            UserInput = $selectedInput
            AvailableStages = $config.Images | ForEach-Object { "$($_.Index): $($_.Stage)" }
        }
        exit
    }
    
    try {
        $currentStage | ConvertTo-Json -Depth 2 | Set-Content -Path $currentStageFile
        Write-LogSuccess "Stage saved successfully" -Context @{ 
            Stage = $currentStage.Stage
            StageFile = $currentStageFile
        }
    } catch {
        Write-LogError "Failed to save selected stage" -Context @{ 
            Stage = $currentStage.Stage
            StageFile = $currentStageFile
        } -Exception $_.Exception
        exit
    }
    
    Write-LogSuccess "Stage selected successfully" -Context @{ 
        SelectedStage = $currentStage.Stage
        ImageType = $currentStage.ImageType
    }
}

# Execute stage script with performance tracking
$stageScript = "$PSScriptRoot/OperatingSystems/$currentOS/stages/$($currentStage.ImageType).ps1"
Start-PerformanceTimer -OperationName "Stage_Script_Execution"

if (Test-Path $stageScript) {
    Write-Log "Executing stage script" -Level "EXECUTING" -Component "StageExecution" -Context @{
        StageScript = $stageScript
        Stage = $currentStage.Stage
        ImageType = $currentStage.ImageType
        OperatingSystem = $currentOS
    }
    
    try {
        & $stageScript
        Write-LogSuccess "Stage script executed successfully" -Context @{ 
            Stage = $currentStage.Stage
            ImageType = $currentStage.ImageType
            StageScript = $stageScript
        }
    } catch {
        Write-LogError "Stage script execution failed" -Context @{ 
            Stage = $currentStage.Stage
            ImageType = $currentStage.ImageType
            StageScript = $stageScript
        } -Exception $_.Exception
    }
} else {
    Write-LogWarning "Stage script not found" -Context @{ 
        StageScript = $stageScript
        Stage = $currentStage.Stage
        ImageType = $currentStage.ImageType
        OperatingSystem = $currentOS
    }
}

Stop-PerformanceTimer -OperationName "Stage_Script_Execution"
Stop-PerformanceTimer -OperationName "Stage_Management"

# Final execution summary
$endTime = Get-Date
$duration = $endTime - $startTime
$formattedDuration = "{0:D2}:{1:D2}:{2:D2}" -f $duration.Hours, $duration.Minutes, $duration.Seconds

Stop-PerformanceTimer -OperationName "YUNA_Total_Execution" -AdditionalContext @{
    StartTime = $startTime
    EndTime = $endTime
    FormattedDuration = $formattedDuration
    DeviceModel = $deviceModel
    OperatingSystem = $currentOS
    Stage = if ($currentStage) { $currentStage.Stage } else { "None" }
    ProcessedDeviceSettings = $processedSettings.Count
    FailedDeviceSettings = $failedSettings.Count
}

Write-Log "YUNA execution completed successfully" -Level "SUCCESS" -Component "YUNA" -Context @{
    TotalExecutionTime = $formattedDuration
    DeviceModel = $deviceModel
    OperatingSystem = $currentOS
    Stage = if ($currentStage) { $currentStage.Stage } else { "None" }
    ConfigurationSummary = @{
        ProcessedSettings = $processedSettings.Count
        FailedSettings = $failedSettings.Count
        SuccessRate = if (($processedSettings.Count + $failedSettings.Count) -gt 0) { 
            [math]::Round(($processedSettings.Count / ($processedSettings.Count + $failedSettings.Count)) * 100, 2) 
        } else { 100 }
    }
    SystemInfo = @{
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        User = [Environment]::UserName
        Computer = $env:COMPUTERNAME
    }
}

Write-Output "SUCCESS: YUNA execution completed. Total execution time: $formattedDuration (HH:MM:SS)" | Out-File $PSScriptRoot\YUNA_DONE