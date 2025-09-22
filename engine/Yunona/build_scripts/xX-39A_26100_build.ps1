# D:\yunona\build_scripts\xX-39A_19044_build.ps1

param(
    [Parameter(Mandatory=$true)]
    [string]$MountPoint    # z.B. "D:\runtime\mount"
)

Write-Host "🔧 Starting WIM build customization for xX-39A + Windows 10 LTSC 2021"
Write-Host "📁 Mount Point: $MountPoint"

try {
    # 📁 Copy additional files into mounted WIM
    Write-Host "📋 Copying custom files..."
    
    # Beispiel: Copy custom tools
    $ToolsSource = "D:\custom_tools"
    $ToolsTarget = "$MountPoint\Windows\System32\CustomTools"
    if (Test-Path $ToolsSource) {
        Copy-Item -Path $ToolsSource -Destination $ToolsTarget -Recurse -Force
        Write-Host "✅ Custom tools copied to: $ToolsTarget"
    }
    
    # 📝 Registry modifications (offline registry)
    Write-Host "🔧 Modifying offline registry..."
    
    # Load offline SOFTWARE hive
    $OfflineReg = "$MountPoint\Windows\System32\config\SOFTWARE"
    reg load HKLM\OFFLINE_SOFTWARE "$OfflineReg"
    
    # Make registry changes
    reg add "HKLM\OFFLINE_SOFTWARE\Siemens\IPC" /v "DeviceFamily" /t REG_SZ /d "xX-39A" /f
    
    # Unload offline registry
    reg unload HKLM\OFFLINE_SOFTWARE
    
    # 🛠️ DISM operations on mounted WIM
    Write-Host "🔧 Additional DISM operations..."
    
    # Enable/disable Windows features
    dism /Image:"$MountPoint" /Enable-Feature /FeatureName:TelnetClient /All
    dism /Image:"$MountPoint" /Disable-Feature /FeatureName:WindowsMediaPlayer
    
    # 📦 Add additional packages if needed
    # dism /Image:"$MountPoint" /Add-Package /PackagePath:"D:\extra_packages\custom.msu"
    
    Write-Host "✅ WIM build customization completed successfully"
    
} catch {
    Write-Host "❌ WIM build customization failed: $_"
    exit 1
}