	# usedDriverBaseline
	$osUsedDriverBaseline = $versionTable.NewRow()
	$osUsedDriverBaseline["About"] = "UsedDriverBaseline"

	$currentUsedDriverBaseline = $jsonContent.UsedDriverBaseline
	$DriverBaselineValidation = Get-Content ".\_validation\.baseline.json" -Raw | ConvertFrom-Json
	
	$mustUsedDriverBaseline = $DriverBaselineValidation.baseline
		
	if (Test-Path "C:\Version.json") {
		$exist = $true
	} else {
		$exist = $false
	}

	if ($currentUsedDriverBaseline -eq $mustUsedDriverBaseline) {
		if ($exist){
			$osUsedDriverBaseline["Value"] = $currentUsedDriverBaseline
			$osUsedDriverBaseline["Status"] = "pass"	
		} else {
			$osUsedDriverBaseline["Value"] = "missing main data"
			$osUsedDriverBaseline["Status"] = "missing"
			Write-Output "UsedDriverBaseline: => missing: main data `n" | Out-File .\errors -Append
		}

	} else {
		if (Test-Path ".\_validation\.baseline.json") { 
			$osUsedDriverBaseline["Value"] = $currentUsedDriverBaseline
			$osUsedDriverBaseline["Status"] = "fail"
			Write-Output "UsedDriverBaseline: => fail: $currentUsedDriverBaseline `nExpected: $mustUsedDriverBaseline `n" | Out-File .\errors -Append
		} else {
			$osUsedDriverBaseline["Value"] = $currentUsedDriverBaseline
			$osUsedDriverBaseline["Status"] = "missing"
			Write-Output "UsedDriverBaseline: => missing: validation file was not detected: .\_validation\.baseline.json `n" | Out-File .\errors -Append
		}
	}
	$versionTable.Rows.Add($osUsedDriverBaseline)