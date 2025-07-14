	# DeviceModelName
	$deviceName = $versionTable.NewRow()
	$deviceName["About"] = "DeviceModelName"
	
	$wmi = Get-WmiObject -Class Win32_ComputerSystem
	$modelName = $wmi.Model.Trim() 
	
	$modelNameParts = $modelName.Split(' ')
	$matchFound = $false
	$jsonModelName = $jsonContent.DeviceModelName -split " / "
	$currentModelName = $modelNameParts.ToLower()

	foreach ($model in $jsonModelName) {
		if ($model -like "*$currentModelName*") {
			$matchFound = $true
			break 
		}
	}
	
	if ($matchFound) {
		$deviceName["Value"] = $modelName
        $deviceName["Status"] = "pass"
	} else {
		if (Test-Path "C:\Version.json") { 
			$deviceName["Value"] = $modelName
			$deviceName["Status"] = "fail "
			Write-Output = "Device Model Name: => fail: $currentModelName `nExpected: $jsonModelName `n" | Out-File .\errors -Append
		} else {
			$deviceName["Value"] = $modelName
			$deviceName["Status"] = "missing "
			Write-Output "Device Model Name: => missing: validation file was not detected: C:\Version.json `n" | Out-File .\errors -Append
		}

	}
	$versionTable.Rows.Add($deviceName)