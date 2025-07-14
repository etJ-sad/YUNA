function Export-Port135StatusToJson {
    param(
        [bool]$includeDetails = $false,
        [bool]$updateUI = $true
    )

    $port135StatusJsonObject = [ordered]@{}
    $isFirewallBlocked = $false
    $isConnectionBlocked = $false

    # Try TCP connect to localhost:135
    try {
        $tcpClient = [System.Net.Sockets.TcpClient]::new()
        $tcpClient.Connect("localhost", 135)
        $tcpClient.Dispose()
    }
    catch {
        $isConnectionBlocked = $true
    }

    # Check for both inbound and outbound firewall rules
    $firewallInboundRule = Get-NetFirewallRule -DisplayName "Block Port 135 Inbound" -ErrorAction SilentlyContinue
    $firewallOutboundRule = Get-NetFirewallRule -DisplayName "Block Port 135 Outbound" -ErrorAction SilentlyContinue
    if ($firewallInboundRule -and $firewallOutboundRule) {
        $isFirewallBlocked = $true
    }

    $isPortCorrect = $isConnectionBlocked -or $isFirewallBlocked

    # Optional UI update
    if ($updateUI -and $port135Checkbox -and $port135Panel -and $miscGridPanel) {
        $port135Checkbox.Content = if ($isPortCorrect) {
            "Port 135 is not in use or blocked for IO"
        } else {
            "Port 135 is open for IO"
        }
        $port135Checkbox.Margin = "5,245,5,5"
        $port135Checkbox.IsChecked = $isPortCorrect
        $port135Panel.Children.Add($port135Checkbox)
        $miscGridPanel.Children.Add($port135Panel)
    }

    # Build result object
    $port135Properties = [ordered]@{
        "Port"       = 135
        "InUse"      = -not $isPortCorrect
        "IsCorrect"  = $isPortCorrect
    }

    if ($includeDetails) {
        $port135Properties["ConnectionBlocked"] = $isConnectionBlocked
        $port135Properties["FirewallBlocked"]   = $isFirewallBlocked
        $port135Properties["Timestamp"]         = (Get-Date).ToString("o")
    }

    $port135StatusJsonObject["Port135Status"] = $port135Properties

    # Ensure output directory exists
    $outputPath = ".\output\_port135Status.json"
    $outputDir = Split-Path $outputPath
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir | Out-Null
    }

    # Write JSON to file
    $port135StatusJsonObject | ConvertTo-Json -Depth 3 | Out-File -Encoding UTF8 $outputPath

    return $port135StatusJsonObject
}

# Call the function
Export-Port135StatusToJson -includeDetails $true -updateUI $true
