# D:\yunona\build_scripts\common_build.ps1
# Common Build Script - Executed during WIM build-time (WIM mounted)

param(
    [Parameter(Mandatory=$true)]
    [string]$MountPoint,    # e.g. "D:\runtime\mount"
    
    [Parameter(Mandatory=$true)]
    [string]$Device,        # e.g. "xX-39A"
    
    [Parameter(Mandatory=$true)]
    [string]$OsId           # e.g. "10"
)

Write-Host "Common Build Script - WIM Build-Time Execution" -ForegroundColor Green
Write-Host "   Mount Point: $MountPoint" -ForegroundColor Gray
Write-Host "   Device: $Device" -ForegroundColor Gray  
Write-Host "   OS ID: $OsId" -ForegroundColor Gray

try {
    # Target path in mounted WIM - this will be C:\key.txt when the WIM is deployed
    $KeyFilePath = Join-Path $MountPoint "key.txt"
    
    # Write "123" to the key file
    Set-Content -Path $KeyFilePath -Value "123" -Encoding ASCII
    
    Write-Host "SUCCESS: Created key file: $KeyFilePath" -ForegroundColor Green
    Write-Host "File will appear as C:\key.txt on deployed system" -ForegroundColor Cyan
    
    # Verify file was created
    if (Test-Path $KeyFilePath) {
        $content = Get-Content $KeyFilePath
        Write-Host "SUCCESS: File verified with content: $content" -ForegroundColor Green
    } else {
        Write-Host "ERROR: File was not created successfully" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Common build script completed successfully!" -ForegroundColor Green
    
} catch {
    Write-Host "ERROR: Common build script failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
}