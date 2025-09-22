# setup-logging-environment.ps1
# Script to configure YUNA logging environment based on deployment scenario

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("Development", "Testing", "Production", "Debug")]
    [string]$Environment = "Development",
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "$PSScriptRoot\logging-config.json",
    
    [Parameter(Mandatory = $false)]
    [switch]$CreateDirectories,
    
    [Parameter(Mandatory = $false)]
    [switch]$TestConfiguration
)

Write-Host "=== YUNA Enhanced Logging Environment Setup ===" -ForegroundColor Cyan
Write-Host "Environment: $Environment" -ForegroundColor Yellow

# Define environment-specific configurations
$environmentConfigs = @{
    Development = @{
        enableDebugLogging = $false
        enableVerboseLogging = $true
        outputTargets = @("Console", "File")
        logFormat = "Structured"
        includeStackTrace = $true
        includeSystemInfo = $true
        maxLogSizeBytes = 10485760  # 10MB
        maxLogFiles = 5
        description = "Full logging for development and debugging"
    }
    
    Testing = @{
        enableDebugLogging = $true
        enableVerboseLogging = $false
        outputTargets = @("Console", "File")
        logFormat = "Structured"
        includeStackTrace = $true
        includeSystemInfo = $true
        maxLogSizeBytes = 52428800  # 50MB
        maxLogFiles = 10
        description = "Detailed logging for testing scenarios"
    }
    
    Production = @{
        enableDebugLogging = $false
        enableVerboseLogging = $false
        outputTargets = @("File", "EventLog")
        logFormat = "Structured"
        includeStackTrace = $false
        includeSystemInfo = $false
        maxLogSizeBytes = 104857600  # 100MB
        maxLogFiles = 20
        description = "Optimized logging for production deployment"
    }
    
    Debug = @{
        enableDebugLogging = $true
        enableVerboseLogging = $true
        outputTargets = @("Console", "File")
        logFormat = "JSON"
        includeStackTrace = $true
        includeSystemInfo = $true
        maxLogSizeBytes = 5242880  # 5MB
        maxLogFiles = 3
        bufferLogs = $false
        description = "Maximum detail logging for troubleshooting"
    }
}

# Create base configuration structure
$baseConfig = @{
    loggingConfig = @{
        enableDebugLogging = $false
        enableVerboseLogging = $false
        outputTargets = @("Console", "File")
        logFormat = "Structured"
        includeStackTrace = $false
        includeSystemInfo = $true
        maxLogSizeBytes = 52428800
        maxLogFiles = 10
        bufferLogs = $false
        flushInterval = 30
        remoteEndpoint = ""
        remoteApiKey = ""
    }
    logLevels = $environmentConfigs
}

# Apply environment-specific configuration
if ($environmentConfigs.ContainsKey($Environment)) {
    $envConfig = $environmentConfigs[$Environment]
    Write-Host "Applying $Environment configuration..." -ForegroundColor Green
    Write-Host "Description: $($envConfig.description)" -ForegroundColor Gray
    
    # Merge environment config into base config
    foreach ($key in $envConfig.Keys) {
        if ($key -ne "description") {
            $baseConfig.loggingConfig[$key] = $envConfig[$key]
        }
    }
} else {
    Write-Warning "Unknown environment: $Environment. Using Development configuration."
    $Environment = "Development"
}

# Create directories if requested
if ($CreateDirectories) {
    Write-Host "Creating logging directories..." -ForegroundColor Yellow
    
    $directories = @(
        "$PSScriptRoot\Logs",
        "$env:TEMP\YUNA_Registry_Backups",
        "$PSScriptRoot\Logs\Archive"
    )
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            try {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
                Write-Host "  Created: $dir" -ForegroundColor Green
            } catch {
                Write-Warning "Failed to create directory: $dir - $($_.Exception.Message)"
            }
        } else {
            Write-Host "  Exists: $dir" -ForegroundColor Gray
        }
    }
}

# Save configuration to file
try {
    $configJson = $baseConfig | ConvertTo-Json -Depth 5
    Set-Content -Path $ConfigPath -Value $configJson -Encoding UTF8
    Write-Host "Configuration saved to: $ConfigPath" -ForegroundColor Green
} catch {
    Write-Error "Failed to save configuration: $($_.Exception.Message)"
    exit 1
}

# Set environment variable
try {
    [System.Environment]::SetEnvironmentVariable("YUNA_ENVIRONMENT", $Environment, "Process")
    Write-Host "Environment variable set: YUNA_ENVIRONMENT=$Environment" -ForegroundColor Green
} catch {
    Write-Warning "Failed to set environment variable: $($_.Exception.Message)"
}

# Test configuration if requested
if ($TestConfiguration) {
    Write-Host "`nTesting logging configuration..." -ForegroundColor Yellow
    
    try {
        # First, check if the enhanced logging module exists
        $loggingModulePath = Join-Path $PSScriptRoot "Logging.psm1"
        if (-not (Test-Path $loggingModulePath)) {
            Write-Warning "Enhanced logging module not found at: $loggingModulePath"
            Write-Host "  ✗ Cannot test without enhanced logging module" -ForegroundColor Red
            Write-Host "  💡 Make sure you have the enhanced Logging.psm1 in the engine directory" -ForegroundColor Yellow
            return
        }
        
        # Import the enhanced logging module
        Write-Host "  Importing logging module..." -ForegroundColor Gray
        Import-Module $loggingModulePath -Force -ErrorAction Stop
        Write-Host "  ✓ Logging module imported successfully" -ForegroundColor Green
        
        # Load the configuration we just created
        Write-Host "  Loading configuration..." -ForegroundColor Gray
        $testConfig = Get-Content $ConfigPath | ConvertFrom-Json
        $configToTest = @{}
        foreach ($prop in $testConfig.loggingConfig.PSObject.Properties) {
            $configToTest[$prop.Name] = $prop.Value
        }
        Write-Host "  ✓ Configuration loaded successfully" -ForegroundColor Green
        
        # Initialize logging with test configuration
        Write-Host "  Initializing logging system..." -ForegroundColor Gray
        Initialize-LoggingSystem -RootPath $PSScriptRoot -CustomConfig $configToTest
        Write-Host "  ✓ Logging system initialized successfully" -ForegroundColor Green
        
        # Test various log levels
        Write-Host "  Testing log levels..." -ForegroundColor Gray
        Write-Log "Configuration test started" -Level "INIT" -Context @{
            Environment = $Environment
            ConfigFile = $ConfigPath
            TestTime = Get-Date
        }
        
        Write-LogInfo "Testing INFO level logging" -Context @{ Level = "INFO" }
        Write-LogSuccess "Testing SUCCESS level logging" -Context @{ Level = "SUCCESS" }
        Write-LogWarning "Testing WARNING level logging" -Context @{ Level = "WARNING" }
        
        if ($configToTest.enableDebugLogging) {
            Write-LogDebug "Testing DEBUG level logging" -Context @{ Level = "DEBUG" }
        }
        
        # Test performance timing
        Write-Host "  Testing performance timing..." -ForegroundColor Gray
        Start-PerformanceTimer -OperationName "ConfigurationTest"
        Start-Sleep -Milliseconds 100
        Stop-PerformanceTimer -OperationName "ConfigurationTest"
        
        Write-LogSuccess "Configuration test completed successfully" -Context @{
            Environment = $Environment
            AllTestsPassed = $true
        }
        
        Write-Host "  ✓ All log levels tested" -ForegroundColor Green
        Write-Host "  ✓ Performance timing tested" -ForegroundColor Green
        Write-Host "  ✓ Configuration test completed successfully" -ForegroundColor Green
        
    } catch {
        Write-Error "Configuration test failed: $($_.Exception.Message)"
        Write-Host "  ✗ Configuration test failed" -ForegroundColor Red
        Write-Host "  Error details: $($_.Exception.Message)" -ForegroundColor Red
        
        # Provide troubleshooting hints
        Write-Host "`n  💡 Troubleshooting hints:" -ForegroundColor Yellow
        Write-Host "     - Ensure engine\Logging.psm1 exists and is the enhanced version" -ForegroundColor Gray
        Write-Host "     - Check PowerShell execution policy: Get-ExecutionPolicy" -ForegroundColor Gray
        Write-Host "     - Try running as Administrator if needed" -ForegroundColor Gray
    }
}

# Display configuration summary
Write-Host "`n=== Configuration Summary ===" -ForegroundColor Cyan
Write-Host "Environment: $Environment" -ForegroundColor White
Write-Host "Debug Logging: $($baseConfig.loggingConfig.enableDebugLogging)" -ForegroundColor $(if($baseConfig.loggingConfig.enableDebugLogging){"Green"}else{"Red"})
Write-Host "Verbose Logging: $($baseConfig.loggingConfig.enableVerboseLogging)" -ForegroundColor $(if($baseConfig.loggingConfig.enableVerboseLogging){"Green"}else{"Red"})
Write-Host "Output Targets: $($baseConfig.loggingConfig.outputTargets -join ', ')" -ForegroundColor White
Write-Host "Log Format: $($baseConfig.loggingConfig.logFormat)" -ForegroundColor White
Write-Host "Max Log Size: $([math]::Round($baseConfig.loggingConfig.maxLogSizeBytes / 1MB, 1)) MB" -ForegroundColor White
Write-Host "Max Log Files: $($baseConfig.loggingConfig.maxLogFiles)" -ForegroundColor White
Write-Host "Include Stack Trace: $($baseConfig.loggingConfig.includeStackTrace)" -ForegroundColor $(if($baseConfig.loggingConfig.includeStackTrace){"Green"}else{"Gray"})
Write-Host "Include System Info: $($baseConfig.loggingConfig.includeSystemInfo)" -ForegroundColor $(if($baseConfig.loggingConfig.includeSystemInfo){"Green"}else{"Gray"})

Write-Host "`n=== Next Steps ===" -ForegroundColor Cyan
Write-Host "1. Run your YUNA scripts with the new logging configuration" -ForegroundColor White
Write-Host "2. Check the Logs directory for output files" -ForegroundColor White
Write-Host "3. Monitor Windows Event Log if EventLog output is enabled" -ForegroundColor White
Write-Host "4. Use 'Get-RegistryImportStatistics' to review backup statistics" -ForegroundColor White

if ($Environment -eq "Production") {
    Write-Host "`n⚠️  Production Environment Notes:" -ForegroundColor Yellow
    Write-Host "   - Debug logging is disabled for performance" -ForegroundColor Gray
    Write-Host "   - Logs are written to file and event log only" -ForegroundColor Gray
    Write-Host "   - Stack traces are disabled for security" -ForegroundColor Gray
    Write-Host "   - Consider setting up log rotation and monitoring" -ForegroundColor Gray
}

Write-Host "`n=== Setup Complete ===" -ForegroundColor Green