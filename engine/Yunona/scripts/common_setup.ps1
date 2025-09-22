# D:\yunona\scripts\common_setup.ps1
# Common Runtime Script - Executed by Yunona after first boot

# Yunona führt dieses Script automatisch nach dem ersten Boot aus
# Kein Mount Point nötig - Windows läuft bereits normal

Write-Host "🌟 Common Runtime Script - Post-Boot Execution" -ForegroundColor Green
Write-Host "   Computer: $env:COMPUTERNAME" -ForegroundColor Gray
Write-Host "   User: $env:USERNAME" -ForegroundColor Gray
Write-Host "   OS Version: $(Get-WmiObject Win32_OperatingSystem | Select-Object -ExpandProperty Caption)" -ForegroundColor Gray

try {
    # Direkter Zugriff auf C:\ (kein Mount Point)
    $PublicDir = "C:\Users\Public"
    
    # Erstelle Runtime-Info Datei
    $RuntimeInfoFile = Join-Path $PublicDir "kassia_runtime_common.txt"
    
    $RuntimeInfo = @"
=== KASSIA COMMON RUNTIME SCRIPT ===
Executed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Script Type: Runtime (Post-Boot via Yunona)
Computer Name: $env:COMPUTERNAME
Current User: $env:USERNAME
OS Version: $(Get-WmiObject Win32_OperatingSystem | Select-Object -ExpandProperty Caption)
OS Build: $(Get-WmiObject Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber)
PowerShell Version: $($PSVersionTable.PSVersion)

=== SYSTEM INFORMATION ===
Domain: $env:USERDOMAIN
Processor: $(Get-WmiObject Win32_Processor | Select-Object -ExpandProperty Name | Select-Object -First 1)
Total RAM: $([math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)) GB
IP Address: $((Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ethernet* | Where-Object {$_.IPAddress -ne '127.0.0.1'} | Select-Object -First 1).IPAddress)

=== RUNTIME TASKS COMPLETED ===
✅ System information collected
✅ Common runtime configuration applied
✅ Yunona post-deployment setup completed

This file was created during the first boot after WIM deployment.
The system is fully running and Yunona executed this script automatically.
"@
    
    # Schreibe Runtime-Info
    Set-Content -Path $RuntimeInfoFile -Value $RuntimeInfo -Encoding UTF8
    
    Write-Host "✅ Created runtime info file: $RuntimeInfoFile" -ForegroundColor Green
    
    # System-spezifische Konfiguration
    $KassiaDir = Join-Path $PublicDir "Kassia"
    if (-not (Test-Path $KassiaDir)) {
        New-Item -Path $KassiaDir -ItemType Directory -Force | Out-Null
        Write-Host "✅ Created Kassia runtime directory: $KassiaDir" -ForegroundColor Green
    }
    
    # Runtime-Konfiguration erstellen
    $RuntimeConfig = @{
        RuntimeTimestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        ComputerName = $env:COMPUTERNAME
        UserName = $env:USERNAME
        Domain = $env:USERDOMAIN
        ScriptType = "CommonRuntime"
        YunonaVersion = "3.0"
        OSVersion = (Get-WmiObject Win32_OperatingSystem).Caption
        OSBuild = (Get-WmiObject Win32_OperatingSystem).BuildNumber
        IPAddress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ethernet* | Where-Object {$_.IPAddress -ne '127.0.0.1'} | Select-Object -First 1).IPAddress
        ProcessorName = (Get-WmiObject Win32_Processor | Select-Object -ExpandProperty Name | Select-Object -First 1)
        TotalRAM_GB = [math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    }
    
    $ConfigFile = Join-Path $KassiaDir "runtime_config.json"
    $RuntimeConfig | ConvertTo-Json -Depth 3 | Set-Content -Path $ConfigFile -Encoding UTF8
    
    Write-Host "✅ Created runtime config: $ConfigFile" -ForegroundColor Green
    
    # Beispiel: Service-Konfiguration prüfen
    $Services = @("Themes", "AudioSrv", "BITS")
    $ServiceStatus = @{}
    
    foreach ($ServiceName in $Services) {
        $Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($Service) {
            $ServiceStatus[$ServiceName] = $Service.Status.ToString()
        } else {
            $ServiceStatus[$ServiceName] = "Not Found"
        }
    }
    
    $ServiceFile = Join-Path $KassiaDir "service_status.json"
    $ServiceStatus | ConvertTo-Json -Depth 2 | Set-Content -Path $ServiceFile -Encoding UTF8
    
    Write-Host "✅ Created service status: $ServiceFile" -ForegroundColor Green
    Write-Host "🎉 Common runtime script completed successfully!" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Common runtime script failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    
    # Log error for Yunona
    $ErrorFile = "C:\Users\Public\kassia_runtime_error.txt"
    $ErrorInfo = @"
Common Runtime Script Error
Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Error: $($_.Exception.Message)
Stack Trace: $($_.ScriptStackTrace)
"@
    Set-Content -Path $ErrorFile -Value $ErrorInfo -Encoding UTF8
    
    exit 1
}