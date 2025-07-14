	# version
	$osVersion = $versionTable.NewRow()
	$osVersion["About"] = "Version"
	$currentVersion = $jsonContent.Version
	
	$versionValidation = Get-Content ".\_validation\.version.json" -Raw | ConvertFrom-Json
	$mustVersionValidation = $versionValidation.version
	
	if (Test-Path "C:\Version.json") {
		$exist = $true
	} else {
		$exist = $false
	}
	
	if ($currentVersion -eq $mustVersionValidation) {
		if ($exist) {
			$osVersion["Value"] = $currentVersion
			$osVersion["Status"] = "pass"
		} else {
			$osVersion["Value"] = "missing main data"
			$osVersion["Status"] = "missing"
			Write-Output "Version: => missing: main data `n" | Out-File .\errors -Append
		}

	} else {
		if (Test-Path ".\_validation\.version.json") { 
			$osVersion["Value"] = $currentVersion
			$osVersion["Status"] = "fail"
			Write-Output "Version: => fail: $currentVersion `nExpected: $mustVersionValidation `n" | Out-File .\errors -Append
		} else {
			$osVersion["Value"] = $currentVersion
			$osVersion["Status"] = "missing"
			Write-Output "Version: => missing: validation file was not detected: .\_validation\.version.json `n" | Out-File .\errors -Append
		}
	}
	$versionTable.Rows.Add($osVersion)