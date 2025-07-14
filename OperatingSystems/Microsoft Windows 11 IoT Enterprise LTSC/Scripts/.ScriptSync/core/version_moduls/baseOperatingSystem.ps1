	# BaseOperatingSystem
	$osBaseOperatingSystem = $versionTable.NewRow()
	$osBaseOperatingSystem["About"] = "BaseOperatingSystem"

	$osDisplayVersionReg = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "DisplayVersion"
	$osProductNameReg = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "ProductName"
	$validationFile = "C:\Version.json"

	# Adjust for known variations
	$osProductName = $osProductNameReg
	if ($osDisplayVersionReg -like "*24H2*") {
		$osProductName = "Windows 11 IoT Enterprise"
	}
	if ($osProductNameReg -like "*LTSC 2024*") {
		$osProductName = "Windows 11 IoT Enterprise LTSC 2024"
	}

	# Compare with expected value
	if (Test-Path $validationFile) {
		$jsonContent = Get-Content $validationFile -Raw | ConvertFrom-Json
		$expected = $jsonContent.BaseOperatingSystem

		if ($osProductName -eq $expected) {
			$osBaseOperatingSystem["Value"] = $osProductName
			$osBaseOperatingSystem["Status"] = "pass"
		} else {
			$osBaseOperatingSystem["Value"] = $osProductName
			$osBaseOperatingSystem["Status"] = "fail"
			$message = "Base Operating System: => fail: $osProductName `nExpected: $expected `n"
			Write-Output $message | Out-File .\errors -Append
		}
	} else {
		$osBaseOperatingSystem["Value"] = $osProductName
		$osBaseOperatingSystem["Status"] = "missing"
		Write-Output "Base Operating System: => missing: validation file was not detected: $validationFile `n" | Out-File .\errors -Append
	}

	$versionTable.Rows.Add($osBaseOperatingSystem)
