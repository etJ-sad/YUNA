# xX-32A_19044_build.ps1
# Device-Specific Build Script

param(
    [Parameter(Mandatory=$true)]
    [string]$MountPoint,    # e.g. "D:\runtime\mount"
    
    [Parameter(Mandatory=$true)]
    [string]$Device,        # e.g. "xX-39A"
    
    [Parameter(Mandatory=$true)]
    [string]$OsId           # e.g. "10"
)

Write-Host "Device Build Script - Keys Integration" -ForegroundColor Cyan
Write-Host "   Mount Point: $MountPoint" -ForegroundColor Gray
Write-Host "   Device: $Device" -ForegroundColor Gray  

try {
    # Host paths for keys
    $HostKeysPath = "D:\_Assets\Keys\xX-39A\19044"
    $BootexSource = Join-Path $HostKeysPath "bootext.dat"
    $HashRegSource = Join-Path $HostKeysPath "hash.reg"
    
    Write-Host "Starting keys integration..." -ForegroundColor Yellow
    
    # 1. Copy bootex.dat
    $WindowsDir = Join-Path $MountPoint "Windows"
    $BootexTarget = Join-Path $WindowsDir "bootex.dat"
    
    if (Test-Path $BootexSource) {
        if (Test-Path $WindowsDir) {
            Copy-Item -Path $BootexSource -Destination $BootexTarget -Force
            Write-Host "bootex.dat copied successfully: $BootexTarget" -ForegroundColor Green
        } else {
            Write-Host "Target Windows directory not found: $WindowsDir" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "bootex.dat not found at: $BootexSource" -ForegroundColor Red
        exit 1
    }
    
    # 2. Import hash.reg into WIM registry
    if (Test-Path $HashRegSource) {
        Write-Host "Processing hash.reg for WIM import..." -ForegroundColor Yellow
        
        # Read hash.reg content and modify for WIM
        $RegContent = Get-Content $HashRegSource -Raw -Encoding UTF8
        
        # Load SOFTWARE hive
        $SoftwareHivePath = Join-Path $MountPoint "Windows\System32\config\SOFTWARE"
        $TempHiveKey = "HKLM\WIM_SOFTWARE"
        
        # Load registry hive
        $loadResult = reg load $TempHiveKey $SoftwareHivePath 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Registry hive loaded successfully" -ForegroundColor Green
            
            # Replace HKEY_LOCAL_MACHINE\SOFTWARE with mounted hive
            $ModifiedRegContent = $RegContent -replace 'HKEY_LOCAL_MACHINE\\SOFTWARE', $TempHiveKey
            
            # Create temporary .reg file
            $TempRegFile = Join-Path $env:TEMP "temp_wim_hash.reg"
            Set-Content -Path $TempRegFile -Value $ModifiedRegContent -Encoding UTF8
            
            # Import modified .reg file
            Write-Host "Importing modified hash.reg..." -ForegroundColor Yellow
            $importResult = reg import $TempRegFile 2>&1
            
            # Delete temporary file
            Remove-Item $TempRegFile -Force -ErrorAction SilentlyContinue
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "hash.reg imported successfully" -ForegroundColor Green
            } else {
                Write-Host "Registry import warning/error: $importResult" -ForegroundColor Yellow
            }
            
            # Unload registry hive
            $unloadResult = reg unload $TempHiveKey 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Registry hive unloaded successfully" -ForegroundColor Green
            } else {
                Write-Host "Registry unload warning: $unloadResult" -ForegroundColor Yellow
                # Sometimes it takes a moment - try again
                Start-Sleep -Seconds 2
                reg unload $TempHiveKey 2>&1 | Out-Null
            }
        } else {
            Write-Host "Failed to load registry hive: $loadResult" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "hash.reg not found at: $HashRegSource" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Keys integration completed successfully!" -ForegroundColor Green
    
} catch {
    Write-Host "Keys integration failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
}