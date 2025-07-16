# Enhanced Logging.psm1 - Advanced Logging Module for YUNA (Emoji-Free Version)

# This module provides enhanced functionality to:
# - Log structured messages with rich context
# - Support multiple output targets (file, console, event log, remote)
# - Provide performance metrics and correlation IDs
# - Enable log rotation and archiving
# - Support different log formats (JSON, XML, plain text)

# Version information
$LoggingVersion = "2.0.0"

# Import required assemblies for advanced features
Add-Type -AssemblyName System.Web.Extensions

# Global configuration object
$global:LogConfig = @{
    # Basic settings
    EnableDebugLogging = $false
    EnableVerboseLogging = $false
    
    # Output targets
    OutputTargets = @("Console", "File")  # Options: Console, File, EventLog, Remote
    
    # File settings
    LogDirectory = ""
    LogFileName = ""
    MaxLogSizeBytes = 50MB
    MaxLogFiles = 10
    
    # Format settings
    LogFormat = "Structured"  # Options: Simple, Structured, JSON, XML
    IncludeStackTrace = $false
    IncludeSystemInfo = $true
    
    # Performance settings
    BufferLogs = $false
    FlushInterval = 30  # seconds
    
    # Remote logging (future enhancement)
    RemoteEndpoint = ""
    RemoteApiKey = ""
    
    # Correlation settings
    CorrelationId = [System.Guid]::NewGuid().ToString()
    SessionId = [System.Guid]::NewGuid().ToString()
}

# Initialize logging configuration
function Initialize-LoggingSystem {
    param(
        [string]$RootPath = $null,
        [hashtable]$CustomConfig = @{}
    )
    
    # Determine root path
    if (-not $RootPath) {
        $RootPath = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
    }
    
    # Set default paths
    $global:LogConfig.LogDirectory = Join-Path $RootPath "Logs"
    $global:LogConfig.LogFileName = "YUNA_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    
    # Apply custom configuration
    foreach ($key in $CustomConfig.Keys) {
        if ($global:LogConfig.ContainsKey($key)) {
            $global:LogConfig[$key] = $CustomConfig[$key]
        }
    }
    
    # Ensure log directory exists
    if (-not (Test-Path $global:LogConfig.LogDirectory)) {
        New-Item -ItemType Directory -Path $global:LogConfig.LogDirectory -Force | Out-Null
    }
    
    # Initialize session
    Write-Log "Logging system initialized" -Level "INIT" -Context @{
        LogVersion = $LoggingVersion
        SessionId = $global:LogConfig.SessionId
        CorrelationId = $global:LogConfig.CorrelationId
        OutputTargets = $global:LogConfig.OutputTargets -join ", "
        LogFormat = $global:LogConfig.LogFormat
    }
}

# Enhanced color mapping without emojis
$global:EnhancedColorMap = @{
    "INIT"      = @{ ForegroundColor = "DarkYellow"; BackgroundColor = $null; Symbol = "[INIT]" }
    "INFO"      = @{ ForegroundColor = "DarkCyan"; BackgroundColor = $null; Symbol = "[INFO]" }
    "OK"        = @{ ForegroundColor = "Green"; BackgroundColor = $null; Symbol = "[OK]" }
    "SUCCESS"   = @{ ForegroundColor = "Green"; BackgroundColor = $null; Symbol = "[SUCCESS]" }
    "WARNING"   = @{ ForegroundColor = "Yellow"; BackgroundColor = $null; Symbol = "[WARNING]" }
    "ERROR"     = @{ ForegroundColor = "Red"; BackgroundColor = $null; Symbol = "[ERROR]" }
    "CRITICAL"  = @{ ForegroundColor = "White"; BackgroundColor = "Red"; Symbol = "[CRITICAL]" }
    "EXECUTING" = @{ ForegroundColor = "Cyan"; BackgroundColor = $null; Symbol = "[EXEC]" }
    "APPLYING"  = @{ ForegroundColor = "Magenta"; BackgroundColor = $null; Symbol = "[APPLY]" }
    "DEBUG"     = @{ ForegroundColor = "Blue"; BackgroundColor = $null; Symbol = "[DEBUG]" }
    "VERBOSE"   = @{ ForegroundColor = "DarkGray"; BackgroundColor = $null; Symbol = "[VERBOSE]" }
    "SECURITY"  = @{ ForegroundColor = "Yellow"; BackgroundColor = "DarkRed"; Symbol = "[SECURITY]" }
    "NETWORK"   = @{ ForegroundColor = "Cyan"; BackgroundColor = $null; Symbol = "[NETWORK]" }
    "PERFORMANCE" = @{ ForegroundColor = "Magenta"; BackgroundColor = $null; Symbol = "[PERF]" }
}

# Performance tracking
$global:PerformanceCounters = @{}

# Main logging function with enhanced features
function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INIT", "INFO", "OK", "SUCCESS", "WARNING", "ERROR", "CRITICAL", "EXECUTING", "APPLYING", "DEBUG", "VERBOSE", "SECURITY", "NETWORK", "PERFORMANCE")]
        [string]$Level = "INFO",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Context = @{},
        
        [Parameter(Mandatory = $false)]
        [string]$Component = "YUNA",
        
        [Parameter(Mandatory = $false)]
        [string]$CorrelationId = $null,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeStackTrace,
        
        [Parameter(Mandatory = $false)]
        [System.Exception]$Exception = $null
    )
    
    # Skip debug/verbose messages if not enabled
    if ($Level -eq "DEBUG" -and -not $global:LogConfig.EnableDebugLogging) { return }
    if ($Level -eq "VERBOSE" -and -not $global:LogConfig.EnableVerboseLogging) { return }
    
    # Use provided correlation ID or global one
    if (-not $CorrelationId) {
        $CorrelationId = $global:LogConfig.CorrelationId
    }
    
    # Gather system information
    $systemInfo = @{}
    if ($global:LogConfig.IncludeSystemInfo) {
        $systemInfo = @{
            ProcessId = $PID
            ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
            UserName = $env:USERNAME
            ComputerName = $env:COMPUTERNAME
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        }
    }
    
    # Add stack trace if requested or if it is an error
    $stackTrace = $null
    if ($IncludeStackTrace -or $Level -in @("ERROR", "CRITICAL") -or $Exception) {
        $stackTrace = (Get-PSCallStack | Select-Object -Skip 1 | ForEach-Object { 
            "$($_.Command) at $($_.Location)" 
        }) -join " -> "
    }
    
    # Create structured log entry
    $logEntry = [PSCustomObject]@{
        Timestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffK'
        Level = $Level
        Message = $Message
        Component = $Component
        CorrelationId = $CorrelationId
        SessionId = $global:LogConfig.SessionId
        Context = $Context
        SystemInfo = $systemInfo
        StackTrace = $stackTrace
        Exception = if ($Exception) { 
            @{
                Type = $Exception.GetType().Name
                Message = $Exception.Message
                StackTrace = $Exception.StackTrace
            }
        } else { $null }
    }
    
    # Output to different targets
    foreach ($target in $global:LogConfig.OutputTargets) {
        switch ($target) {
            "Console" { Write-ToConsole $logEntry }
            "File" { Write-ToFile $logEntry }
            "EventLog" { Write-ToEventLog $logEntry }
            "Remote" { Write-ToRemote $logEntry }
        }
    }
}

# Console output with enhanced formatting
function Write-ToConsole {
    param([PSCustomObject]$LogEntry)
    
    $colorInfo = $global:EnhancedColorMap[$LogEntry.Level]
    $symbol = $colorInfo.Symbol
    
    # Create console message based on format
    switch ($global:LogConfig.LogFormat) {
        "Simple" {
            $consoleMessage = "[$($LogEntry.Timestamp)] [$($LogEntry.Level)] $($LogEntry.Message)"
        }
        "Structured" {
            $contextStr = if ($LogEntry.Context.Count -gt 0) { 
                " | Context: $($LogEntry.Context | ConvertTo-Json -Compress)" 
            } else { "" }
            $consoleMessage = "$symbol [$($LogEntry.Timestamp)] [$($LogEntry.Component)] $($LogEntry.Message)$contextStr"
        }
        default {
            $consoleMessage = "$symbol [$($LogEntry.Timestamp)] [$($LogEntry.Level)] $($LogEntry.Message)"
        }
    }
    
    # Write with colors
    $writeParams = @{ Object = $consoleMessage }
    if ($colorInfo.ForegroundColor) { $writeParams.ForegroundColor = $colorInfo.ForegroundColor }
    if ($colorInfo.BackgroundColor) { $writeParams.BackgroundColor = $colorInfo.BackgroundColor }
    
    Write-Host @writeParams
    
    # Add separator for better readability
    if ($LogEntry.Level -in @("ERROR", "CRITICAL", "INIT")) {
        Write-Host ("-" * 80) -ForegroundColor DarkGray
    }
}

# File output with rotation support
function Write-ToFile {
    param([PSCustomObject]$LogEntry)
    
    $logFile = Join-Path $global:LogConfig.LogDirectory $global:LogConfig.LogFileName
    
    # Check for log rotation
    if ((Test-Path $logFile) -and (Get-Item $logFile).Length -gt $global:LogConfig.MaxLogSizeBytes) {
        Rotate-LogFile $logFile
    }
    
    # Format based on configuration
    $fileContent = switch ($global:LogConfig.LogFormat) {
        "JSON" {
            $LogEntry | ConvertTo-Json -Compress
        }
        "XML" {
            $LogEntry | ConvertTo-Xml -NoTypeInformation | Select-Object -ExpandProperty OuterXml
        }
        default {
            # Structured text format
            $contextStr = if ($LogEntry.Context.Count -gt 0) { 
                "`n    Context: $($LogEntry.Context | ConvertTo-Json -Compress)" 
            } else { "" }
            $stackStr = if ($LogEntry.StackTrace) { "`n    StackTrace: $($LogEntry.StackTrace)" } else { "" }
            "[$($LogEntry.Timestamp)] [$($LogEntry.Level)] [$($LogEntry.Component)] [CID:$($LogEntry.CorrelationId.Substring(0,8))] $($LogEntry.Message)$contextStr$stackStr"
        }
    }
    
    # Write to file with error handling
    try {
        Add-Content -Path $logFile -Value $fileContent -Encoding UTF8 -ErrorAction Stop
    }
    catch {
        Write-Warning "Failed to write to log file: $_"
    }
}

# Log rotation function
function Rotate-LogFile {
    param([string]$LogFile)
    
    try {
        $directory = Split-Path $LogFile -Parent
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($LogFile)
        $extension = [System.IO.Path]::GetExtension($LogFile)
        
        # Rotate existing files
        for ($i = $global:LogConfig.MaxLogFiles - 1; $i -ge 1; $i--) {
            $oldFile = Join-Path $directory "$baseName.$i$extension"
            $newFile = Join-Path $directory "$baseName.$($i + 1)$extension"
            
            if (Test-Path $oldFile) {
                if (Test-Path $newFile) { Remove-Item $newFile -Force }
                Move-Item $oldFile $newFile
            }
        }
        
        # Move current log to .1
        $rotatedFile = Join-Path $directory "$baseName.1$extension"
        if (Test-Path $rotatedFile) { Remove-Item $rotatedFile -Force }
        Move-Item $LogFile $rotatedFile
        
        Write-Log "Log file rotated" -Level "INFO" -Context @{ RotatedTo = $rotatedFile }
    }
    catch {
        Write-Warning "Failed to rotate log file: $_"
    }
}

# Event log output (Windows Event Log)
function Write-ToEventLog {
    param([PSCustomObject]$LogEntry)
    
    $sourceName = "YUNA"
    
    # Create event source if it doesn't exist
    if (-not [System.Diagnostics.EventLog]::SourceExists($sourceName)) {
        try {
            [System.Diagnostics.EventLog]::CreateEventSource($sourceName, "Application")
        }
        catch {
            return  # Skip if can't create event source (requires admin)
        }
    }
    
    # Map log levels to event log entry types
    $entryType = switch ($LogEntry.Level) {
        { $_ -in @("ERROR", "CRITICAL") } { "Error" }
        "WARNING" { "Warning" }
        default { "Information" }
    }
    
    $eventMessage = "$($LogEntry.Message)`n`nComponent: $($LogEntry.Component)`nCorrelationId: $($LogEntry.CorrelationId)"
    if ($LogEntry.Context.Count -gt 0) {
        $eventMessage += "`nContext: $($LogEntry.Context | ConvertTo-Json)"
    }
    
    try {
        Write-EventLog -LogName "Application" -Source $sourceName -EntryType $entryType -EventId 1000 -Message $eventMessage
    }
    catch {
        # Silently fail if can't write to event log
    }
}

# Remote logging (placeholder for future implementation)
function Write-ToRemote {
    param([PSCustomObject]$LogEntry)
    
    # TODO: Implement remote logging to centralized log server
    # This could be Splunk, ELK stack, Azure Log Analytics, etc.
}

# Performance measurement functions
function Start-PerformanceTimer {
    param(
        [Parameter(Mandatory = $true)]
        [string]$OperationName,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Context = @{}
    )
    
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    $global:PerformanceCounters[$OperationName] = @{
        Timer = $timer
        StartTime = Get-Date
        Context = $Context
    }
    
    Write-Log "Performance timer started" -Level "PERFORMANCE" -Context (@{ OperationName = $OperationName } + $Context)
}

function Stop-PerformanceTimer {
    param(
        [Parameter(Mandatory = $true)]
        [string]$OperationName,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$AdditionalContext = @{}
    )
    
    if (-not $global:PerformanceCounters.ContainsKey($OperationName)) {
        Write-Log "Performance timer not found" -Level "WARNING" -Context @{ OperationName = $OperationName }
        return
    }
    
    $counter = $global:PerformanceCounters[$OperationName]
    $counter.Timer.Stop()
    
    $performanceData = @{
        OperationName = $OperationName
        Duration = $counter.Timer.Elapsed.ToString()
        DurationMs = $counter.Timer.ElapsedMilliseconds
        StartTime = $counter.StartTime
        EndTime = Get-Date
    } + $counter.Context + $AdditionalContext
    
    Write-Log "Performance timer completed" -Level "PERFORMANCE" -Context $performanceData
    
    # Remove from tracking
    $global:PerformanceCounters.Remove($OperationName)
}

# Convenience functions for common log levels
function Write-LogInfo { param([string]$Message, [hashtable]$Context = @{}) Write-Log $Message -Level "INFO" -Context $Context }
function Write-LogWarning { param([string]$Message, [hashtable]$Context = @{}) Write-Log $Message -Level "WARNING" -Context $Context }
function Write-LogError { param([string]$Message, [hashtable]$Context = @{}, [System.Exception]$Exception = $null) Write-Log $Message -Level "ERROR" -Context $Context -Exception $Exception }
function Write-LogSuccess { param([string]$Message, [hashtable]$Context = @{}) Write-Log $Message -Level "SUCCESS" -Context $Context }
function Write-LogDebug { param([string]$Message, [hashtable]$Context = @{}) Write-Log $Message -Level "DEBUG" -Context $Context }
function Write-LogSecurity { param([string]$Message, [hashtable]$Context = @{}) Write-Log $Message -Level "SECURITY" -Context $Context }

# Export functions
Export-ModuleMember -Function @(
    'Initialize-LoggingSystem',
    'Write-Log',
    'Start-PerformanceTimer',
    'Stop-PerformanceTimer',
    'Write-LogInfo',
    'Write-LogWarning', 
    'Write-LogError',
    'Write-LogSuccess',
    'Write-LogDebug',
    'Write-LogSecurity'
)