function Export-Port445StatusToJson {
    param(
        [bool]$includeDetails = $false,
        [bool]$updateUI = $true
    )

    $port445StatusJsonObject = [ordered]@{}
    $isFirewallBlocked = $false
    $isConnectionBlocked = $false

    # Try TCP connect to localhost:445
    try {
        $tcpClient = [System.Net.Sockets.TcpClient]::new()
        $tcpClient.Connect("localhost", 445)
        $tcpClient.Dispose()
    }
    catch {
        $isConnectionBlocked = $true
    }

    # Check for both inbound and outbound firewall rules
    $firewallInboundRule = Get-NetFirewallRule -DisplayName "Block Port 445 Inbound" -ErrorAction SilentlyContinue
    $firewallOutboundRule = Get-NetFirewallRule -DisplayName "Block Port 445 Outbound" -ErrorAction SilentlyContinue
    if ($firewallInboundRule -and $firewallOutboundRule) {
        $isFirewallBlocked = $true
    }

    $isPortCorrect = $isConnectionBlocked -or $isFirewallBlocked

    # Optional UI update
    if ($updateUI -and $port445Checkbox -and $port445Panel -and $miscGridPanel) {
        $port445Checkbox.Content = if ($isPortCorrect) {
            "Port 445 is not in use or blocked for IO"
        } else {
            "Port 445 is open for IO"
        }
        $port445Checkbox.Margin = "5,265,5,5"
        $port445Checkbox.IsChecked = $isPortCorrect
        $port445Panel.Children.Add($port445Checkbox)
        $miscGridPanel.Children.Add($port445Panel)
    }

    # Build result object
    $port445Properties = [ordered]@{
        "Port"       = 445
        "InUse"      = -not $isPortCorrect
        "IsCorrect"  = $isPortCorrect
    }

    if ($includeDetails) {
        $port445Properties["ConnectionBlocked"] = $isConnectionBlocked
        $port445Properties["FirewallBlocked"]   = $isFirewallBlocked
        $port445Properties["Timestamp"]         = (Get-Date).ToString("o")
    }

    $port445StatusJsonObject["Port445Status"] = $port445Properties

    # Ensure output directory exists
    $outputPath = ".\output\_port445Status.json"
    $outputDir = Split-Path $outputPath
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir | Out-Null
    }

    # Write JSON to file
    $port445StatusJsonObject | ConvertTo-Json -Depth 3 | Out-File -Encoding UTF8 $outputPath

    return $port445StatusJsonObject
}

# Call the function
Export-Port445StatusToJson -includeDetails $true -updateUI $true
