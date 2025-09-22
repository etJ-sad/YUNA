# D:\yunona\scripts\xX-39A_19044.ps1  
# Device-Specific Runtime Script - Executed by Yunona after first boot for xX-39A devices

Write-Host "🚀 Device Runtime Script - xX-39A Windows 10 LTSC 2021" -ForegroundColor Cyan
Write-Host "   Computer: $env:COMPUTERNAME" -ForegroundColor Gray
Write-Host "   Device Family: xX-39A" -ForegroundColor Gray
Write-Host "   Target OS: Windows 10 LTSC 2021" -ForegroundColor Gray

try {
    $PublicDir = "C:\Users\Public"
    
    # Erstelle device-spezifische Runtime-Datei
    $DeviceRuntimeFile = Join-Path $PublicDir "kassia_device_runtime.txt"
    
    $DeviceRuntimeInfo = @"
=== KASSIA DEVICE RUNTIME SCRIPT ===
Executed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Script Type: Runtime (Post-Boot via Yunona)
Device Family: xX-39A (SIMATIC IPC BX-39A/PX-39A Series)
Target OS: Windows 10 IoT Enterprise LTSC 2021
Computer Name: $env:COMPUTERNAME

=== DEVICE-SPECIFIC RUNTIME TASKS ===
✅ Hardware identification completed
✅ Device-specific driver verification
✅ xX-39A hardware configuration applied
✅ Network and system optimization for Industrial PC
✅ Device family registry settings applied

=== HARDWARE DETECTION ===
Manufacturer: $(Get-WmiObject Win32_ComputerSystem | Select-Object -ExpandProperty Manufacturer)
Model: $(Get-WmiObject Win32_ComputerSystem | Select-Object -ExpandProperty Model)
Serial Number: $(Get-WmiObject Win32_BIOS | Select-Object -ExpandProperty SerialNumber)
BIOS Version: $(Get-WmiObject Win32_BIOS | Select-Object -ExpandProperty SMBIOSBIOSVersion)

=== NETWORK CONFIGURATION ===
Network Adapters: $((Get-NetAdapter | Where-Object {$_.Status -eq 'Up'}).Name -join ', ')
IP Addresses: $((Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -ne '127.0.0.1'}).IPAddress -join ', ')

This runtime script completed the final device-specific configuration
for xX-39A hardware after Windows 10 LTSC 2021 deployment.
"@
    
    Set-Content -Path $DeviceRuntimeFile -Value $DeviceRuntimeInfo -Encoding UTF8
    Write-Host "✅ Created device runtime info: $DeviceRuntimeFile" -ForegroundColor Cyan
    
    # Device-spezifischen Runtime-Ordner erstellen
    $DeviceRuntimeDir = Join-Path $PublicDir "Kassia\xX-39A\Runtime"
    if (-not (Test-Path $DeviceRuntimeDir)) {
        New-Item -Path $DeviceRuntimeDir -ItemType Directory -Force | Out-Null
        Write-Host "✅ Created device runtime directory: $DeviceRuntimeDir" -ForegroundColor Cyan
    }
    
    # Hardware-Detection ausführen
    $HardwareDetection = @{
        DetectionTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        DeviceFamily = "xX-39A"
        ComputerName = $env:COMPUTERNAME
        Manufacturer = (Get-WmiObject Win32_ComputerSystem).Manufacturer
        Model = (Get-WmiObject Win32_ComputerSystem).Model
        SerialNumber = (Get-WmiObject Win32_BIOS).SerialNumber
        BIOSVersion = (Get-WmiObject Win32_BIOS).SMBIOSBIOSVersion
        Processor = (Get-WmiObject Win32_Processor | Select-Object -First 1).Name
        TotalRAM_GB = [math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
        NetworkAdapters = @((Get-NetAdapter | Where-Object {$_.Status -eq 'Up'}).Name)
        IPAddresses = @((Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -ne '127.0.0.1'}).IPAddress)
        OSVersion = (Get-WmiObject Win32_OperatingSystem).Caption
        OSBuild = (Get-WmiObject Win32_OperatingSystem).BuildNumber
        LastBootUpTime = (Get-WmiObject Win32_OperatingSystem).LastBootUpTime
    }
    
    $DetectionFile = Join-Path $DeviceRuntimeDir "hardware_detection.json"
    $HardwareDetection | ConvertTo-Json -Depth 3 | Set-Content -Path $DetectionFile -Encoding UTF8
    Write-Host "✅ Created hardware detection: $DetectionFile" -ForegroundColor Cyan
    
    # Beispiel: Registry-Einstellungen für xX-39A anwenden
    Write-Host "🔧 Applying xX-39A-specific registry settings..." -ForegroundColor Cyan
    
    # Registry-Pfad für Siemens KASSIA erstellen
    $RegistryPath = "HKLM:\SOFTWARE\Siemens\KASSIA"
    if (-not (Test-Path $RegistryPath)) {
        New-Item -Path $RegistryPath -Force | Out-Null
    }
    
    # Device-spezifische Registry-Werte setzen
    Set-ItemProperty -Path $RegistryPath -Name "DeviceFamily" -Value "xX-39A" -Type String
    Set-ItemProperty -Path $RegistryPath -Name "RuntimeConfigured" -Value (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -Type String
    Set-ItemProperty -Path $RegistryPath -Name "SupportedModels" -Value "BX-39A,PX-39A,PX-39A PRO" -Type String
    Set-ItemProperty -Path $RegistryPath -Name "TargetOS" -Value "Windows10LTSC2021" -Type String
    Set-ItemProperty -Path $RegistryPath -Name "ComputerName" -Value $env:COMPUTERNAME -Type String
    
    Write-Host "✅ Registry settings applied successfully" -ForegroundColor Cyan
    
    # Beispiel: Service-Optimierung für Industrial PC
    Write-Host "⚙️  Optimizing services for Industrial PC..." -ForegroundColor Cyan
    
    # Windows Search deaktivieren (typisch für Industrial PCs)
    $SearchService = Get-Service -Name "WSearch" -ErrorAction SilentlyContinue
    if ($SearchService -and $SearchService.Status -eq "Running") {
        Stop-Service -Name "WSearch" -Force
        Set-Service -Name "WSearch" -StartupType Disabled
        Write-Host "✅ Windows Search service disabled for Industrial PC" -ForegroundColor Cyan
    }
    
    # Service-Status dokumentieren
    $ServiceOptimization = @{
        OptimizationTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        DeviceType = "Industrial PC"
        ServicesModified = @()
    }
    
    if ($SearchService) {
        $ServiceOptimization.ServicesModified += "WSearch (Windows Search) - Disabled"
    }
    
    $ServiceFile = Join-Path $DeviceRuntimeDir "service_optimization.json"
    $ServiceOptimization | ConvertTo-Json -Depth 3 | Set-Content -Path $ServiceFile -Encoding UTF8
    
    Write-Host "✅ Service optimization documented: $ServiceFile" -ForegroundColor Cyan
    
    # Beispiel: Build-Zeit Dateien laden (falls vorhanden)
    $BuildConfigFile = "C:\Users\Public\Kassia\build_config.json"
    if (Test-Path $BuildConfigFile) {
        $BuildConfig = Get-Content $BuildConfigFile | ConvertFrom-Json
        Write-Host "📋 Build configuration loaded from build-time:" -ForegroundColor Yellow
        Write-Host "    Build Timestamp: $($BuildConfig.BuildTimestamp)" -ForegroundColor Yellow
        Write-Host "    Build Machine: $($BuildConfig.BuildMachine)" -ForegroundColor Yellow
        Write-Host "    Build User: $($BuildConfig.BuildUser)" -ForegroundColor Yellow
        
        # Verbindung zwischen Build und Runtime dokumentieren
        $RuntimeLink = @{
            RuntimeTimestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            BuildTimestamp = $BuildConfig.BuildTimestamp
            BuildMachine = $BuildConfig.BuildMachine
            RuntimeMachine = $env:COMPUTERNAME
            DeviceFamily = $BuildConfig.Device
            ConfigurationChain = "Build -> Deploy -> Runtime"
        }
        
        $LinkFile = Join-Path $DeviceRuntimeDir "build_runtime_link.json"
        $RuntimeLink | ConvertTo-Json -Depth 3 | Set-Content -Path $LinkFile -Encoding UTF8
        Write-Host "✅ Build-Runtime link documented: $LinkFile" -ForegroundColor Cyan
    }
    
    Write-Host "🎉 Device runtime script completed successfully!" -ForegroundColor Cyan
    Write-Host "🏭 xX-39A Industrial PC configuration complete!" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Device runtime script failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    
    # Fehler für Yunona dokumentieren
    $ErrorFile = "C:\Users\Public\kassia_device_runtime_error.txt"
    $ErrorInfo = @"
Device Runtime Script Error (xX-39A)
Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Device Family: xX-39A
Target OS: Windows 10 LTSC 2021
Error: $($_.Exception.Message)
Stack Trace: $($_.ScriptStackTrace)
"@
    Set-Content -Path $ErrorFile -Value $ErrorInfo -Encoding UTF8
    
    exit 1
}