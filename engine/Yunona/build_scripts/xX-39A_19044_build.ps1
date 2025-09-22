# D:\yunona\build_scripts\xX-39A_19044_build.ps1
# Device-Specific Build Script - Executed during WIM build-time (WIM mounted)

param(
    [Parameter(Mandatory=$true)]
    [string]$MountPoint,    # z.B. "D:\runtime\mount"
    
    [Parameter(Mandatory=$true)]
    [string]$Device,        # z.B. "xX-39A"
    
    [Parameter(Mandatory=$true)]
    [string]$OsId           # z.B. "10"
)

Write-Host "🚀 Device Build Script - xX-39A Windows 10 LTSC 2021" -ForegroundColor Cyan
Write-Host "   Mount Point: $MountPoint" -ForegroundColor Gray
Write-Host "   Device: $Device" -ForegroundColor Gray  
Write-Host "   OS ID: $OsId" -ForegroundColor Gray

try {
    # Ziel-Pfad im gemounteten WIM
    $PublicDir = Join-Path $MountPoint "Users\Public"
    
    if (-not (Test-Path $PublicDir)) {
        Write-Host "⚠️  Public directory not found: $PublicDir" -ForegroundColor Yellow
        return
    }
    
    # Erstelle device-spezifische Datei
    $DeviceInfoFile = Join-Path $PublicDir "kassia_device_build.txt"
    
    $DeviceInfo = @"
=== KASSIA DEVICE BUILD SCRIPT ===
Executed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Script Type: Build-Time (WIM mounted)
Device: $Device (SIMATIC IPC BX-39A/PX-39A)
OS: Windows 10 IoT Enterprise LTSC 2021 (OS ID: $OsId)
Mount Point: $MountPoint

=== DEVICE-SPECIFIC CONFIGURATIONS ===
✅ Device Family: xX-39A Series
✅ Supported Models: BX-39A, PX-39A, PX-39A PRO
✅ Target OS: Windows 10 LTSC 2021 (Build 19044)
✅ Driver Families: Intel Serial IO, TSN, Chipset, RAID Daemon, HSA, Misc
✅ Build Stage: Device-specific WIM customization

=== APPLIED MODIFICATIONS ===
- Device identification files created
- Hardware-specific registry preparations
- Custom device folder structure
- Build-time device configuration

This file proves the device-specific build script executed successfully
during WIM image preparation for $Device hardware.
"@
    
    # Schreibe Device-Info in WIM
    Set-Content -Path $DeviceInfoFile -Value $DeviceInfo -Encoding UTF8
    
    Write-Host "✅ Created device build info: $DeviceInfoFile" -ForegroundColor Cyan
    
    # Device-spezifischen Ordner erstellen
    $DeviceDir = Join-Path $PublicDir "Kassia\$Device"
    if (-not (Test-Path $DeviceDir)) {
        New-Item -Path $DeviceDir -ItemType Directory -Force | Out-Null
        Write-Host "✅ Created device directory: $DeviceDir" -ForegroundColor Cyan
    }
    
    # Device Hardware-Info erstellen
    $HardwareInfo = @{
        DeviceFamily = "xX-39A"
        SupportedModels = @("BX-39A", "PX-39A", "PX-39A PRO") 
        SupportedDeviceIds = @(1, 19951, 19952)
        TargetOS = "Windows 10 IoT Enterprise LTSC 2021"
        OSBuild = "19044"
        BuildTimestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        BuildScript = "xX-39A_19044_build.ps1"
        DriverFamilies = @(20007, 20008, 434245, 20056, 20002, 21706)
        BiosA5E = "A5E50588291"
        MLFBPattern = "6AG4142-.*|6AV7242-.*|6AV7252-.*"
    }
    
    $HardwareFile = Join-Path $DeviceDir "hardware_info.json"
    $HardwareInfo | ConvertTo-Json -Depth 3 | Set-Content -Path $HardwareFile -Encoding UTF8
    
    Write-Host "✅ Created hardware info: $HardwareFile" -ForegroundColor Cyan
    
    # Beispiel: Custom Registry-Vorbereitung (für spätere Runtime-Anwendung)
    $RegistryPrep = Join-Path $DeviceDir "registry_prep.reg"
    $RegContent = @"
Windows Registry Editor Version 5.00

; Device-specific registry preparations for xX-39A
; Applied during first boot by Yunona runtime scripts

[HKEY_LOCAL_MACHINE\SOFTWARE\Siemens\KASSIA]
"DeviceFamily"="xX-39A"
"BuildTimestamp"="$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
"BuildScript"="xX-39A_19044_build.ps1"
"TargetOS"="Windows10LTSC2021"

[HKEY_LOCAL_MACHINE\SOFTWARE\Siemens\KASSIA\Hardware]
"SupportedModels"="BX-39A,PX-39A,PX-39A PRO"
"BiosA5E"="A5E50588291"
"MLFBPattern"="6AG4142-.*,6AV7242-.*,6AV7252-.*"
"@
    
    Set-Content -Path $RegistryPrep -Value $RegContent -Encoding UTF8
    Write-Host "✅ Created registry prep: $RegistryPrep" -ForegroundColor Cyan
    
    Write-Host "🎉 Device build script completed successfully!" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Device build script failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
}