# Enhanced RegistryManagement.psm1 - Registry Import Module with Advanced Logging

# This module provides enhanced functions to:
# - Import multiple .reg files from a specified folder (including subfolders)
# - Validate registry file integrity before import
# - Backup registry keys before modification
# - Automate registry modifications using reg.exe
# - Provide detailed logging and error handling with performance metrics

$registryManagementVersion = "2.0.0"

# Function to validate registry file format
function Test-RegistryFileIntegrity {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
        
        # Check for required registry file header
        if (-not $content.StartsWith("Windows Registry Editor Version")) {
            Write-LogWarning "Registry file missing proper header" -Context @{ 
                FilePath = $FilePath
                FirstLine = ($content -split "`n")[0]
            }
            return $false
        }
        
        # Check for suspicious patterns that might indicate malicious content
        $suspiciousPatterns = @(
            "\.exe",
            "cmd\.exe",
            "powershell",
            "\\System32\\",
            "\\SysWOW64\\"
        )
        
        $suspiciousFound = @()
        foreach ($pattern in $suspiciousPatterns) {
            if ($content -match $pattern) {
                $suspiciousFound += $pattern
            }
        }
        
        if ($suspiciousFound.Count -gt 0) {
            Write-LogSecurity "Potentially suspicious patterns found in registry file" -Context @{
                FilePath = $FilePath
                SuspiciousPatterns = $suspiciousFound
            }
            # Don't automatically fail - log for review but continue
        }
        
        Write-LogDebug "Registry file integrity check passed" -Context @{ 
            FilePath = $FilePath
            FileSize = (Get-Item $FilePath).Length
            SuspiciousPatterns = $suspiciousFound.Count
        }
        return $true
        
    } catch {
        Write-LogError "Registry file integrity check failed" -Context @{ FilePath = $FilePath } -Exception $_.Exception
        return $false
    }
}

# Function to backup registry key before modification
function Backup-RegistryKey {
    param(
        [Parameter(Mandatory = $true)]
        [string]$KeyPath,
        
        [Parameter(Mandatory = $false)]
        [string]$BackupDirectory = $null
    )
    
    if (-not $BackupDirectory) {
        $BackupDirectory = Join-Path $env:TEMP "YUNA_Registry_Backups"
    }
    
    # Ensure backup directory exists
    if (-not (Test-Path $BackupDirectory)) {
        New-Item -ItemType Directory -Path $BackupDirectory -Force | Out-Null
    }
    
    # Generate backup filename
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $safeKeyName = $KeyPath -replace "[\[\]\\/:*?`"<>|]", "_"
    $backupFile = Join-Path $BackupDirectory "BACKUP_${safeKeyName}_${timestamp}.reg"
    
    try {
        # Export the registry key
        $output = & reg export $KeyPath "`"$backupFile`"" 2>&1
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -eq 0) {
            Write-LogSuccess "Registry key backed up successfully" -Context @{
                SourceKey = $KeyPath
                BackupFile = $backupFile
                BackupSize = (Get-Item $backupFile).Length
            }
            return $backupFile
        } else {
            Write-LogWarning "Registry key backup failed - key may not exist" -Context @{
                SourceKey = $KeyPath
                ExitCode = $exitCode
                Output = $output
            }
            return $null
        }
    } catch {
        Write-LogError "Registry key backup operation failed" -Context @{
            SourceKey = $KeyPath
            BackupFile = $backupFile
        } -Exception $_.Exception
        return $null
    }
}

# Function to extract registry keys from .reg file for backup purposes
function Get-RegistryKeysFromFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        $content = Get-Content -Path $FilePath -ErrorAction Stop
        $keys = @()
        
        foreach ($line in $content) {
            if ($line -match '^\[([^\]]+)\]$') {
                $keyPath = $matches[1]
                # Convert HKEY_ to standard abbreviations for reg export
                $keyPath = $keyPath -replace "HKEY_LOCAL_MACHINE", "HKLM"
                $keyPath = $keyPath -replace "HKEY_CURRENT_USER", "HKCU"
                $keyPath = $keyPath -replace "HKEY_CLASSES_ROOT", "HKCR"
                $keyPath = $keyPath -replace "HKEY_USERS", "HKU"
                $keyPath = $keyPath -replace "HKEY_CURRENT_CONFIG", "HKCC"
                
                if ($keyPath -notlike "*-*") {  # Skip deletion entries
                    $keys += $keyPath
                }
            }
        }
        
        return $keys | Select-Object -Unique
    } catch {
        Write-LogError "Failed to extract registry keys from file" -Context @{ FilePath = $FilePath } -Exception $_.Exception
        return @()
    }
}

# Enhanced function to import all .reg files from a specified folder recursively
function Set-RegistryEntries {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FolderPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateBackups = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$ValidateIntegrity = $true,
        
        [Parameter(Mandatory = $false)]
        [string]$BackupDirectory = $null
    )

    Write-LogInfo "Starting registry import operation" -Context @{
        FolderPath = $FolderPath
        CreateBackups = $CreateBackups.IsPresent
        ValidateIntegrity = $ValidateIntegrity.IsPresent
        BackupDirectory = $BackupDirectory
    }

    # Check if the folder exists
    if (-Not (Test-Path -Path $FolderPath)) {
        Write-LogError "Registry folder not found" -Context @{ FolderPath = $FolderPath }
        return
    }

    Start-PerformanceTimer -OperationName "Registry_Import_Total" -Context @{ FolderPath = $FolderPath }

    # Get all .reg files in the specified folder and subfolders
    try {
        $regFiles = Get-ChildItem -Path $FolderPath -Filter "*.reg" -Recurse -ErrorAction Stop
        Write-LogInfo "Registry files discovered" -Context @{
            FolderPath = $FolderPath
            FileCount = $regFiles.Count
            Files = $regFiles.Name
        }
    } catch {
        Write-LogError "Failed to enumerate registry files" -Context @{ FolderPath = $FolderPath } -Exception $_.Exception
        return
    }

    if ($regFiles.Count -eq 0) {
        Write-LogWarning "No .reg files found in folder" -Context @{ FolderPath = $FolderPath }
        return
    }

    # Initialize counters for summary
    $successCount = 0
    $failureCount = 0
    $skippedCount = 0
    $backedUpKeys = @()
    $processedFiles = @()

    foreach ($file in $regFiles) {
        $customFile = $file.FullName
        
        Start-PerformanceTimer -OperationName "Registry_File_$($file.BaseName)" -Context @{
            FileName = $file.Name
            FilePath = $customFile
        }

        Write-Log "Processing registry file" -Level "APPLYING" -Context @{
            FileName = $file.Name
            FilePath = $customFile
            FileSize = $file.Length
            LastModified = $file.LastWriteTime
        }

        try {
            # Validate file integrity if requested
            if ($ValidateIntegrity) {
                if (-not (Test-RegistryFileIntegrity -FilePath $customFile)) {
                    Write-LogError "Registry file failed integrity check" -Context @{
                        FileName = $file.Name
                        FilePath = $customFile
                    }
                    $skippedCount++
                    Stop-PerformanceTimer -OperationName "Registry_File_$($file.BaseName)" -AdditionalContext @{ Result = "Skipped_IntegrityFailed" }
                    continue
                }
            }

            # Create backups if requested
            if ($CreateBackups) {
                Write-LogDebug "Creating backups for registry keys" -Context @{ FileName = $file.Name }
                $keysToBackup = Get-RegistryKeysFromFile -FilePath $customFile
                
                foreach ($key in $keysToBackup) {
                    $backupFile = Backup-RegistryKey -KeyPath $key -BackupDirectory $BackupDirectory
                    if ($backupFile) {
                        $backedUpKeys += @{
                            OriginalKey = $key
                            BackupFile = $backupFile
                            SourceRegFile = $file.Name
                        }
                    }
                }
            }

            # Import the registry file
            Write-LogDebug "Executing registry import" -Context @{
                FileName = $file.Name
                Command = "reg import `"$customFile`""
            }

            $output = & reg import "`"$customFile`"" 2>&1
            $exitCode = $LASTEXITCODE  

            if ($exitCode -eq 0) {
                Write-LogSuccess "Registry imported successfully" -Context @{
                    FileName = $file.Name
                    FilePath = $customFile
                    ExitCode = $exitCode
                }
                $successCount++
                $processedFiles += @{
                    FileName = $file.Name
                    FilePath = $customFile
                    Result = "Success"
                    BackupCount = ($backedUpKeys | Where-Object { $_.SourceRegFile -eq $file.Name }).Count
                }
            } else {
                throw "Registry import failed with exit code: $exitCode. Output: $output"
            }
        } catch {
            Write-LogError "Registry import failed" -Context @{
                FileName = $file.Name
                FilePath = $customFile
                ExitCode = if ($exitCode) { $exitCode } else { "Unknown" }
                Output = if ($output) { $output } else { "No output captured" }
            } -Exception $_.Exception
            
            $failureCount++
            $processedFiles += @{
                FileName = $file.Name
                FilePath = $customFile
                Result = "Failed"
                Error = $_.Exception.Message
            }
        }

        Stop-PerformanceTimer -OperationName "Registry_File_$($file.BaseName)" -AdditionalContext @{
            FileName = $file.Name
            Result = if ($successCount + $failureCount + $skippedCount -eq ($regFiles.IndexOf($file) + 1)) { 
                if ($exitCode -eq 0) { "Success" } elseif ($skippedCount -gt ($regFiles.IndexOf($file))) { "Skipped" } else { "Failed" }
            } else { "Unknown" }
        }
    }

    Stop-PerformanceTimer -OperationName "Registry_Import_Total" -AdditionalContext @{
        TotalFiles = $regFiles.Count
        SuccessCount = $successCount
        FailureCount = $failureCount
        SkippedCount = $skippedCount
        BackupCount = $backedUpKeys.Count
    }

    # Final summary
    $successRate = if ($regFiles.Count -gt 0) { [math]::Round(($successCount / $regFiles.Count) * 100, 2) } else { 0 }
    
    Write-LogInfo "Registry import operation completed" -Context @{
        FolderPath = $FolderPath
        Summary = @{
            TotalFiles = $regFiles.Count
            Successful = $successCount
            Failed = $failureCount
            Skipped = $skippedCount
            SuccessRate = $successRate
            BackupsCreated = $backedUpKeys.Count
        }
        ProcessedFiles = $processedFiles
        BackedUpKeys = $backedUpKeys | Select-Object OriginalKey, SourceRegFile
    }

    # Log warnings if there were failures
    if ($failureCount -gt 0) {
        Write-LogWarning "Some registry imports failed" -Context @{
            FailureCount = $failureCount
            SuccessRate = $successRate
            FailedFiles = ($processedFiles | Where-Object { $_.Result -eq "Failed" }).FileName
        }
    }

    if ($skippedCount -gt 0) {
        Write-LogWarning "Some registry files were skipped" -Context @{
            SkippedCount = $skippedCount
            Reason = "Integrity validation failed"
        }
    }
}

# Function to restore registry from backup
function Restore-RegistryFromBackup {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BackupFile
    )
    
    if (-not (Test-Path $BackupFile)) {
        Write-LogError "Backup file not found" -Context @{ BackupFile = $BackupFile }
        return $false
    }
    
    Write-LogInfo "Restoring registry from backup" -Context @{ 
        BackupFile = $BackupFile
        BackupSize = (Get-Item $BackupFile).Length
        BackupDate = (Get-Item $BackupFile).LastWriteTime
    }
    
    try {
        $output = & reg import "`"$BackupFile`"" 2>&1
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -eq 0) {
            Write-LogSuccess "Registry restored successfully from backup" -Context @{
                BackupFile = $BackupFile
                ExitCode = $exitCode
            }
            return $true
        } else {
            Write-LogError "Registry restoration failed" -Context @{
                BackupFile = $BackupFile
                ExitCode = $exitCode
                Output = $output
            }
            return $false
        }
    } catch {
        Write-LogError "Registry restoration operation failed" -Context @{
            BackupFile = $BackupFile
        } -Exception $_.Exception
        return $false
    }
}

# Function to cleanup old backup files
function Remove-OldRegistryBackups {
    param(
        [Parameter(Mandatory = $false)]
        [string]$BackupDirectory = (Join-Path $env:TEMP "YUNA_Registry_Backups"),
        
        [Parameter(Mandatory = $false)]
        [int]$DaysToKeep = 30
    )
    
    if (-not (Test-Path $BackupDirectory)) {
        Write-LogDebug "Backup directory does not exist" -Context @{ BackupDirectory = $BackupDirectory }
        return
    }
    
    try {
        $cutoffDate = (Get-Date).AddDays(-$DaysToKeep)
        $oldBackups = Get-ChildItem -Path $BackupDirectory -Filter "BACKUP_*.reg" | Where-Object { $_.LastWriteTime -lt $cutoffDate }
        
        if ($oldBackups.Count -eq 0) {
            Write-LogDebug "No old registry backups found for cleanup" -Context @{
                BackupDirectory = $BackupDirectory
                DaysToKeep = $DaysToKeep
                CutoffDate = $cutoffDate
            }
            return
        }
        
        $removedCount = 0
        $totalSize = 0
        
        foreach ($backup in $oldBackups) {
            try {
                $totalSize += $backup.Length
                Remove-Item -Path $backup.FullName -Force
                $removedCount++
                
                Write-LogDebug "Old registry backup removed" -Context @{
                    BackupFile = $backup.Name
                    BackupDate = $backup.LastWriteTime
                    FileSize = $backup.Length
                }
            } catch {
                Write-LogWarning "Failed to remove old registry backup" -Context @{
                    BackupFile = $backup.FullName
                } -Exception $_.Exception
            }
        }
        
        Write-LogInfo "Registry backup cleanup completed" -Context @{
            BackupDirectory = $BackupDirectory
            RemovedCount = $removedCount
            TotalBackups = $oldBackups.Count
            SpaceFreed = $totalSize
            DaysToKeep = $DaysToKeep
        }
        
    } catch {
        Write-LogError "Registry backup cleanup failed" -Context @{
            BackupDirectory = $BackupDirectory
            DaysToKeep = $DaysToKeep
        } -Exception $_.Exception
    }
}

# Function to get registry import statistics
function Get-RegistryImportStatistics {
    param(
        [Parameter(Mandatory = $false)]
        [string]$BackupDirectory = (Join-Path $env:TEMP "YUNA_Registry_Backups")
    )
    
    $stats = @{
        BackupDirectory = $BackupDirectory
        BackupDirectoryExists = Test-Path $BackupDirectory
        TotalBackups = 0
        TotalBackupSize = 0
        OldestBackup = $null
        NewestBackup = $null
        BackupsByDate = @{}
    }
    
    if ($stats.BackupDirectoryExists) {
        try {
            $backups = Get-ChildItem -Path $BackupDirectory -Filter "BACKUP_*.reg" -ErrorAction Stop
            $stats.TotalBackups = $backups.Count
            
            if ($backups.Count -gt 0) {
                $stats.TotalBackupSize = ($backups | Measure-Object -Property Length -Sum).Sum
                $stats.OldestBackup = ($backups | Sort-Object LastWriteTime | Select-Object -First 1).LastWriteTime
                $stats.NewestBackup = ($backups | Sort-Object LastWriteTime | Select-Object -Last 1).LastWriteTime
                
                # Group backups by date
                $stats.BackupsByDate = $backups | Group-Object { $_.LastWriteTime.Date } | ForEach-Object {
                    @{
                        Date = $_.Name
                        Count = $_.Count
                        TotalSize = ($_.Group | Measure-Object -Property Length -Sum).Sum
                    }
                }
            }
        } catch {
            Write-LogWarning "Failed to gather registry backup statistics" -Context @{
                BackupDirectory = $BackupDirectory
            } -Exception $_.Exception
        }
    }
    
    Write-LogInfo "Registry import statistics gathered" -Context $stats
    return $stats
}

# Enhanced function for registry health check
function Test-RegistryHealth {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$KeyPaths
    )
    
    Write-LogInfo "Starting registry health check" -Context @{
        KeyCount = $KeyPaths.Count
        Keys = $KeyPaths
    }
    
    $results = @()
    
    foreach ($keyPath in $KeyPaths) {
        try {
            # Convert registry path format for PowerShell
            $psPath = $keyPath -replace "HKLM:", "HKLM:" -replace "HKCU:", "HKCU:" -replace "HKCR:", "HKCR:"
            
            if (Test-Path "Registry::$psPath") {
                $key = Get-Item "Registry::$psPath" -ErrorAction Stop
                $valueCount = ($key.GetValueNames()).Count
                
                $results += @{
                    KeyPath = $keyPath
                    Status = "Healthy"
                    ValueCount = $valueCount
                    LastWriteTime = $key.LastWriteTime
                }
                
                Write-LogDebug "Registry key health check passed" -Context @{
                    KeyPath = $keyPath
                    ValueCount = $valueCount
                    LastWriteTime = $key.LastWriteTime
                }
            } else {
                $results += @{
                    KeyPath = $keyPath
                    Status = "Missing"
                    ValueCount = 0
                    LastWriteTime = $null
                }
                
                Write-LogWarning "Registry key not found during health check" -Context @{
                    KeyPath = $keyPath
                }
            }
        } catch {
            $results += @{
                KeyPath = $keyPath
                Status = "Error"
                ValueCount = 0
                LastWriteTime = $null
                Error = $_.Exception.Message
            }
            
            Write-LogError "Registry key health check failed" -Context @{
                KeyPath = $keyPath
            } -Exception $_.Exception
        }
    }
    
    $healthySummary = @{
        Total = $results.Count
        Healthy = ($results | Where-Object { $_.Status -eq "Healthy" }).Count
        Missing = ($results | Where-Object { $_.Status -eq "Missing" }).Count
        Errors = ($results | Where-Object { $_.Status -eq "Error" }).Count
    }
    
    Write-LogInfo "Registry health check completed" -Context @{
        Summary = $healthySummary
        HealthRate = if ($results.Count -gt 0) { [math]::Round(($healthySummary.Healthy / $results.Count) * 100, 2) } else { 0 }
        Results = $results
    }
    
    return $results
}

# Export enhanced functions for external use
Export-ModuleMember -Function @(
    'Set-RegistryEntries',
    'Test-RegistryFileIntegrity',
    'Backup-RegistryKey',
    'Restore-RegistryFromBackup',
    'Remove-OldRegistryBackups',
    'Get-RegistryImportStatistics',
    'Test-RegistryHealth'
)