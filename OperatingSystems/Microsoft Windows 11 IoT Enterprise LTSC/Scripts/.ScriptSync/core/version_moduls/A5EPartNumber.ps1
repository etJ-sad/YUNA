	# A5EPartNumber
	$osA5EPartNumber = $versionTable.NewRow()
	$osA5EPartNumber["About"] = "A5EPartNumber"
	$currentA5EPartNumber = $jsonContent.PartNumber
	$A5EValidation = Get-Content ".\_validation\.A5E.json" -Raw | ConvertFrom-Json
	
	if (Test-Path "C:\Version.json") {
		$exist = $true
	} else {
		$exist = $false
	}
	
	$mustA5EPartNumber = $A5EValidation.A5E
	if ($currentA5EPartNumber -eq $mustA5EPartNumber) {
		if ($exist) {
			$osA5EPartNumber["Value"] = $currentA5EPartNumber
			$osA5EPartNumber["Status"] = "pass"
		} else {
			$osA5EPartNumber["Value"] = "missing main data"
			$osA5EPartNumber["Status"] = "missing"
			Write-Output "A5E PartNumber: => missing: main data `n" | Out-File .\errors -Append
		}
	} else {
		if (Test-Path ".\_validation\.A5E.json") { 
			$osA5EPartNumber["Value"] = $currentA5EPartNumber
			$osA5EPartNumber["Status"] = "fail"
			Write-Output "A5E PartNumber: => fail: $currentA5EPartNumber `nExpected: $mustA5EPartNumber `n" | Out-File .\errors -Append
		} else {
			$osA5EPartNumber["Value"] = $currentA5EPartNumber
			$osA5EPartNumber["Status"] = "missing"
			Write-Output "A5E PartNumber: => missing: validation file was not detected: .\_validation\.A5E.json `n" | Out-File .\errors -Append
		}
	}
	$versionTable.Rows.Add($osA5EPartNumber)