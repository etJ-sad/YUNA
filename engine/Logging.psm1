# Logging.psm1 - Enhanced Logging Module

# This module provides functionality to:
# - Log messages to a file with timestamps
# - Display messages in the console with color-coded log levels
# - Ensure logs are properly formatted and stored

# Version information for tracking purposes
$LoggingVersion = 1.0.1

# Global toggle for showing debug messages
# Set to $true to enable DEBUG-level logs in both console and file
$global:EnableDebugLogging = $false

# Determine the root directory dynamically based on the module location
$global:rootPath = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

# Set the global log file path with a timestamp in the filename to avoid overwriting
$global:logFile = "$rootPath\Logs\LOG_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Define a mapping of log levels to colors for better visibility in the PowerShell console
$global:colorMap = @{
    "INIT"      = "DarkYellow"  # Start of script, system initialization
    "INFO"      = "DarkCyan"    # General informational messages
    "OK"        = "Green"       # Success messages
    "WARNING"   = "Yellow"      # Warnings that require attention but are not errors
    "ERROR"     = "Red"         # Critical errors that need intervention
    "EXECUTING" = "Cyan"        # Messages indicating a process is running
    "APPLYING"  = "Magenta"     # Messages for applying configurations
    "DEBUG"     = "Blue"        # Debug messages for troubleshooting
}

# Define simple text-based prefixes for each log level, to make log entries easily scannable in files
$global:prefixMap = @{
    "INIT"      = "[INIT]     ####"  # Prefix for initialization logs  
    "INFO"      = "[INFO]     ---#"  # Prefix for informational logs
    "OK"        = "[OK]       ===#"  # Prefix for success messages
    "WARNING"   = "[WARNING]  !!!#"  # Prefix for warnings
    "ERROR"     = "[ERROR]    ***#"  # Prefix for errors
    "EXECUTING" = "[EXEC]     >>>#"  # Prefix for execution messages
    "APPLYING"  = "[APPLY]    ---#"  # Prefix for applying changes
    "DEBUG"     = "[DEBUG]    ...#"  # Prefix for debugging messages
}

# Define a visual divider line based on the current width of the PowerShell window
# Used to clearly separate log entries in both file and console
$global:divider = "-" * $host.UI.RawUI.WindowSize.Width

# Core function to log messages, with timestamp, color, and level formatting
function Write-Log {
    param (
        # The message to be logged
        [string]$Message,

        # The log level (default is INFO)
        [string]$Level = "INFO"
    )

    # Skip DEBUG-level messages if debug logging is not enabled
    if ($Level -eq "DEBUG" -and -not $global:EnableDebugLogging) {
        return
    }

    # Get the current timestamp in a human-readable format
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Get the prefix associated with the log level
    $prefix = $global:prefixMap[$Level]

    # Construct the full log message
    $logMessage = "[$timestamp] $prefix $Message"

    # Create the log file if it doesn't exist
    if (-not (Test-Path $global:logFile)) {
        New-Item -ItemType File -Path $global:logFile -Force | Out-Null
    }

    # Write the log message and divider to the log file
    Add-Content -Path $global:logFile -Value $logMessage -Force
    Add-Content -Path $global:logFile -Value $global:divider -Force

    # Determine the color for the log level and write to console with color
    $color = $global:colorMap[$Level]
    if ($color) {
        Write-Host $logMessage -ForegroundColor $color
        Write-Host $global:divider -ForegroundColor $color
    } else {
        # If no color defined, write normally
        Write-Host $logMessage
        Write-Host $global:divider
    }
}

# Export the logging function to make it usable from scripts that import this module
Export-ModuleMember -Function Write-Log
