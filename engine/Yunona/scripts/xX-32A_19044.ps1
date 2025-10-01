$baseRegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"

# Function to find adapter by device ID pattern
function Find-AdapterPath {
    param(
        [string]$DevicePattern
    )
    
    # Search through all subkeys (0000-9999)
    for ($i = 0; $i -lt 100; $i++) {
        $subKey = "{0:D4}" -f $i
        $path = Join-Path $baseRegistryPath $subKey
        
        if (Test-Path $path) {
            $matchingId = Get-ItemProperty -Path $path -Name "MatchingDeviceId" -ErrorAction SilentlyContinue
            if ($matchingId.MatchingDeviceId -match $DevicePattern) {
                return $path
            }
        }
    }
    return $null
}

Write-Host "Searching for Intel network adapters..." -ForegroundColor Cyan

# Find I210 (DEV_1533)
$i210Path = Find-AdapterPath "DEV_1533"
if ($i210Path) {
    Write-Host "Found I210 at: $i210Path" -ForegroundColor Green
    
    Set-ItemProperty -Path $i210Path -Name "EnableWakeOnManagmentOnTCO" -Value "0" -Type String
    Set-ItemProperty -Path $i210Path -Name "*RSSProfile" -Value "4" -Type String
    Set-ItemProperty -Path $i210Path -Name "BusType" -Value "5" -Type String
    Set-ItemProperty -Path $i210Path -Name "*FlowControl" -Value "3" -Type String
    Set-ItemProperty -Path $i210Path -Name "*TransmitBuffers" -Value "512" -Type String
    Set-ItemProperty -Path $i210Path -Name "*ReceiveBuffers" -Value "256" -Type String
    Set-ItemProperty -Path $i210Path -Name "*TCPChecksumOffloadIPv4" -Value "3" -Type String
    Set-ItemProperty -Path $i210Path -Name "*TCPChecksumOffloadIPv6" -Value "3" -Type String
    Set-ItemProperty -Path $i210Path -Name "*UDPChecksumOffloadIPv4" -Value "3" -Type String
    Set-ItemProperty -Path $i210Path -Name "*UDPChecksumOffloadIPv6" -Value "3" -Type String
    Set-ItemProperty -Path $i210Path -Name "*IPChecksumOffloadIPv4" -Value "0" -Type String
    Set-ItemProperty -Path $i210Path -Name "LogLinkStateEvent" -Value "51" -Type String
    Set-ItemProperty -Path $i210Path -Name "WaitAutoNegComplete" -Value "0" -Type String
    Set-ItemProperty -Path $i210Path -Name "ITR" -Value "65535" -Type String
    Set-ItemProperty -Path $i210Path -Name "*InterruptModeration" -Value "1" -Type String
    Set-ItemProperty -Path $i210Path -Name "*PriorityVLANTag" -Value "3" -Type String
    Set-ItemProperty -Path $i210Path -Name "*LsoV2IPv4" -Value "1" -Type String
    Set-ItemProperty -Path $i210Path -Name "*LsoV2IPv6" -Value "1" -Type String
    Set-ItemProperty -Path $i210Path -Name "*JumboPacket" -Value "1514" -Type String
    Set-ItemProperty -Path $i210Path -Name "*SpeedDuplex" -Value "0" -Type String
    Set-ItemProperty -Path $i210Path -Name "AdaptiveIFS" -Value "0" -Type String
    Set-ItemProperty -Path $i210Path -Name "MasterSlave" -Value "0" -Type String
    Set-ItemProperty -Path $i210Path -Name "*RSS" -Value "1" -Type String
    Set-ItemProperty -Path $i210Path -Name "*NumRssQueues" -Value "2" -Type String
    Set-ItemProperty -Path $i210Path -Name "*MaxRssProcessors" -Value "8" -Type String
    Set-ItemProperty -Path $i210Path -Name "*RssBaseProcNumber" -Value "0" -Type String
    Set-ItemProperty -Path $i210Path -Name "*NumaNodeId" -Value "65535" -Type String
    Set-ItemProperty -Path $i210Path -Name "*RssMaxProcNumber" -Value "63" -Type String
    Set-ItemProperty -Path $i210Path -Name "EEELinkAdvertisement" -Value "1" -Type String
    Set-ItemProperty -Path $i210Path -Name "DMACoalescing" -Value "0" -Type String
    Set-ItemProperty -Path $i210Path -Name "*PMARPOffload" -Value "1" -Type String
    Set-ItemProperty -Path $i210Path -Name "*PMNSOffload" -Value "1" -Type String
    Set-ItemProperty -Path $i210Path -Name "*PtpHardwareTimestamp" -Value "0" -Type String
    Set-ItemProperty -Path $i210Path -Name "*SoftwareTimestamp" -Value "0" -Type String
    Set-ItemProperty -Path $i210Path -Name "PciScanMethod" -Value "3" -Type String
    Set-ItemProperty -Path $i210Path -Name "TxIntDelay" -Value "28" -Type String
    Set-ItemProperty -Path $i210Path -Name "MulticastFilterType" -Value "0" -Type String
    Set-ItemProperty -Path $i210Path -Name "VlanFiltering" -Value "0" -Type String
    Set-ItemProperty -Path $i210Path -Name "*LsoV1IPv4" -Value "0" -Type String
    Set-ItemProperty -Path $i210Path -Name "WakeOnSlot" -Value "0" -Type String
    Set-ItemProperty -Path $i210Path -Name "EnableDca" -Value "1" -Type String
    Set-ItemProperty -Path $i210Path -Name "EnableLLI" -Value "0" -Type String
    Set-ItemProperty -Path $i210Path -Name "ReduceSpeedOnPowerDown" -Value "1" -Type String
    Set-ItemProperty -Path $i210Path -Name "EnablePME" -Value "0" -Type String
    Set-ItemProperty -Path $i210Path -Name "PrimarySecondary" -Value "0" -Type String
    Set-ItemProperty -Path $i210Path -Name "*WakeOnPattern" -Value "0" -Type String
    Set-ItemProperty -Path $i210Path -Name "*WakeOnMagicPacket" -Value "0" -Type String
    Set-ItemProperty -Path $i210Path -Name "WakeOnLink" -Value "0" -Type String
    Set-ItemProperty -Path $i210Path -Name "VlanId" -Value "0" -Type String
    
}

$i219Path = Find-AdapterPath "DEV_15F9"
if ($i219Path) {
    Write-Host "Found I219 at: $i219Path" -ForegroundColor Green
    
    Set-ItemProperty -Path $i219Path -Name "SVOFFMode" -Value "1" -Type String
    Set-ItemProperty -Path $i219Path -Name "LinkNegotiationProcess" -Value "1" -Type String
    Set-ItemProperty -Path $i219Path -Name "ForceHostExitUlp" -Value "1" -Type String
    Set-ItemProperty -Path $i219Path -Name "BusType" -Value "5" -Type String
    Set-ItemProperty -Path $i219Path -Name "*FlowControl" -Value "3" -Type String
    Set-ItemProperty -Path $i219Path -Name "*TransmitBuffers" -Value "512" -Type String
    Set-ItemProperty -Path $i219Path -Name "*ReceiveBuffers" -Value "256" -Type String
    Set-ItemProperty -Path $i219Path -Name "*TCPChecksumOffloadIPv4" -Value "3" -Type String
    Set-ItemProperty -Path $i219Path -Name "*TCPChecksumOffloadIPv6" -Value "3" -Type String
    Set-ItemProperty -Path $i219Path -Name "*UDPChecksumOffloadIPv4" -Value "3" -Type String
    Set-ItemProperty -Path $i219Path -Name "*UDPChecksumOffloadIPv6" -Value "3" -Type String
    Set-ItemProperty -Path $i219Path -Name "*IPChecksumOffloadIPv4" -Value "0" -Type String
    Set-ItemProperty -Path $i219Path -Name "LogLinkStateEvent" -Value "51" -Type String
    Set-ItemProperty -Path $i219Path -Name "WaitAutoNegComplete" -Value "0" -Type String
    Set-ItemProperty -Path $i219Path -Name "ITR" -Value "65535" -Type String
    Set-ItemProperty -Path $i219Path -Name "*InterruptModeration" -Value "1" -Type String
    Set-ItemProperty -Path $i219Path -Name "*PriorityVLANTag" -Value "3" -Type String
    Set-ItemProperty -Path $i219Path -Name "*LsoV2IPv4" -Value "1" -Type String
    Set-ItemProperty -Path $i219Path -Name "*LsoV2IPv6" -Value "1" -Type String
    Set-ItemProperty -Path $i219Path -Name "*JumboPacket" -Value "1514" -Type String
    Set-ItemProperty -Path $i219Path -Name "*SpeedDuplex" -Value "0" -Type String
    Set-ItemProperty -Path $i219Path -Name "AdaptiveIFS" -Value "0" -Type String
    Set-ItemProperty -Path $i219Path -Name "MasterSlave" -Value "0" -Type String
    Set-ItemProperty -Path $i219Path -Name "*PMARPOffload" -Value "1" -Type String
    Set-ItemProperty -Path $i219Path -Name "*PMNSOffload" -Value "1" -Type String
    Set-ItemProperty -Path $i219Path -Name "EEELinkAdvertisement" -Value "1" -Type String
    Set-ItemProperty -Path $i219Path -Name "ULPMode" -Value "1" -Type String
    Set-ItemProperty -Path $i219Path -Name "PciScanMethod" -Value "3" -Type String
    Set-ItemProperty -Path $i219Path -Name "TxIntDelay" -Value "28" -Type String
    Set-ItemProperty -Path $i219Path -Name "MulticastFilterType" -Value "0" -Type String
    Set-ItemProperty -Path $i219Path -Name "VlanFiltering" -Value "0" -Type String
    Set-ItemProperty -Path $i219Path -Name "AutoPowerSaveModeEnabled" -Value "0" -Type String
    Set-ItemProperty -Path $i219Path -Name "ProcessLSCinWorkItem" -Value "1" -Type String
    Set-ItemProperty -Path $i219Path -Name "Enable9KJFTpt" -Value "1" -Type String
    Set-ItemProperty -Path $i219Path -Name "ReceiveScalingMode" -Value "1" -Type String
    Set-ItemProperty -Path $i219Path -Name "*LsoV1IPv4" -Value "0" -Type String
    Set-ItemProperty -Path $i219Path -Name "WakeOnSlot" -Value "0" -Type String
    Set-ItemProperty -Path $i219Path -Name "ReduceSpeedOnPowerDown" -Value "1" -Type String
    Set-ItemProperty -Path $i219Path -Name "EnablePME" -Value "0" -Type String
    Set-ItemProperty -Path $i219Path -Name "SipsEnabled" -Value "0" -Type String
    Set-ItemProperty -Path $i219Path -Name "*WakeOnPattern" -Value "0" -Type String
    Set-ItemProperty -Path $i219Path -Name "*WakeOnMagicPacket" -Value "0" -Type String
    Set-ItemProperty -Path $i219Path -Name "WakeOnLink" -Value "0" -Type String
    Set-ItemProperty -Path $i219Path -Name "*ModernStandbyWoLMagicPacket" -Value "0" -Type String
    Set-ItemProperty -Path $i219Path -Name "S0ixWakeMagicPacket" -Value "0" -Type String
    Set-ItemProperty -Path $i219Path -Name "EnableK1" -Value "1" -Type String
    Set-ItemProperty -Path $i219Path -Name "VlanId" -Value "0" -Type String
    Set-ItemProperty -Path $i219Path -Name "*PtpHardwareTimestamp" -Value "0" -Type String
    Set-ItemProperty -Path $i219Path -Name "*SoftwareTimestamp" -Value "0" -Type String  
} 
