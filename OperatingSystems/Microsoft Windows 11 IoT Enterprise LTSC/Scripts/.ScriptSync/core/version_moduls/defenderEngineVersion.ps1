    # defenderEngineVersion
    $osDefenderEngineVersion = $versionTable.NewRow()
    $osDefenderEngineVersion["About"] = "DefenderEngineVersion"
    $currentDefenderVersion = (Get-MpComputerStatus).AMServiceVersion
	
	$DefenderEngineValidation = Get-Content ".\_validation\.msDefenderEngineVersion.json" -Raw | ConvertFrom-Json
	$mustDefenderEngineVersion = $DefenderEngineValidation.DefenderEngineVersion

	if($currentDefenderVersion -eq $mustDefenderEngineVersion) {
		$osDefenderEngineVersion["Value"] = $currentDefenderVersion
		$osDefenderEngineVersion["Status"] = "pass"
	} else {
		if (Test-Path ".\_validation\.msDefenderEngineVersion.json") { 
			$osDefenderEngineVersion["Value"] = $currentDefenderVersion
			$osDefenderEngineVersion["Status"] = "fail"
			Write-Output "Defender Engine Version: => fail: $currentDefenderVersion `nExpected: $mustDefenderEngineVersion `n" | Out-File .\errors -Append
		} else {
			$osDefenderEngineVersion["Value"] = $currentDefenderVersion
			$osDefenderEngineVersion["Status"] = "missing"
			Write-Output "Defender Engine Version: => missing: validation file was not detected: .\_validation\.msDefenderEngineVersion.json `n" | Out-File .\errors -Append
		}
	}
	$versionTable.Rows.Add($osDefenderEngineVersion)