function Export-Port63105StatusToJson {
    param(
        [bool]$includeDetails = $false,
        [bool]$updateUI = $true
    )

    $port63105StatusJsonObject = [ordered]@{}
    $isFirewallBlocked = $false
    $isConnectionBlocked = $false

    # Try TCP connect to localhost:63105
    try {
        $tcpClient = [System.Net.Sockets.TcpClient]::new()
        $tcpClient.Connect("localhost", 63105)
        $tcpClient.Dispose()
    }
    catch {
        $isConnectionBlocked = $true
    }

    # Check for both inbound and outbound firewall rules blocking port 63105
    $firewallInboundRule = Get-NetFirewallRule -Direction Inbound -LocalPort 63105 -Action Block -ErrorAction SilentlyContinue
    $firewallOutboundRule = Get-NetFirewallRule -Direction Outbound -LocalPort 63105 -Action Block -ErrorAction SilentlyContinue
    if ($firewallInboundRule -and $firewallOutboundRule) {
        $isFirewallBlocked = $true
    }

    $isPortCorrect = $isConnectionBlocked -or $isFirewallBlocked

    # Optional UI update
    if ($updateUI -and $port63105Checkbox -and $port63105Panel -and $miscGridPanel) {
        $port63105Checkbox.Content = if ($isPortCorrect) {
            "Port 63105 is not in use or blocked for IO"
        } else {
            "Port 63105 is open for IO"
        }
        $port63105Checkbox.Margin = "5,285,5,5"
        $port63105Checkbox.IsChecked = $isPortCorrect
        $port63105Panel.Children.Add($port63105Checkbox)
        $miscGridPanel.Children.Add($port63105Panel)
    }

    # Build result object
    $port63105Properties = [ordered]@{
        "Port"       = 63105
        "InUse"      = -not $isPortCorrect
        "IsCorrect"  = $isPortCorrect
    }

    if ($includeDetails) {
        $port63105Properties["ConnectionBlocked"] = $isConnectionBlocked
        $port63105Properties["FirewallBlocked"]   = $isFirewallBlocked
        $port63105Properties["Timestamp"]         = (Get-Date).ToString("o")
    }

    $port63105StatusJsonObject["Port63105Status"] = $port63105Properties

    # Ensure output directory exists
    $outputPath = ".\output\_port63105Status.json"
    $outputDir = Split-Path $outputPath
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir | Out-Null
    }

    # Write JSON to file
    $port63105StatusJsonObject | ConvertTo-Json -Depth 3 | Out-File -Encoding UTF8 $outputPath

    return $port63105StatusJsonObject
}

# Call the function
Export-Port63105StatusToJson -includeDetails $true -updateUI $true
