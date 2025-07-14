	# windowsLicenseStatus
    $osLicenseStatus = $versionTable.NewRow()
    $osLicenseStatus["About"] = "LicenseStatus"
    
    $licenseStatusRegex = "License\sStatus:\s(.+)"
    $licenseStatus = ([regex]::Match($output, $licenseStatusRegex)).Groups[1].Value.Trim()
	
	$currentOS = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\" -Name "ProductName"
	
	if ($currentOS -like "*Server*") {
		$licenseValidation = Get-Content ".\_validation\.windowsLicenseStatusServer.json" -Raw | ConvertFrom-Json
		$mustLicenseStatus = $licenseValidation.status
		if ($licenseStatus -eq $licenseValidation.status) {
			$osLicenseStatus["Value"] = $licenseStatus
			$osLicenseStatus["Status"] = "pass"
		} else {
			if (Test-Path ".\_validation\.windowsLicenseStatusServer.json") {
				$osLicenseStatus["Value"] = $licenseStatus
				$osLicenseStatus["Status"] = "fail"
				Write-Output "Windows License Status: => fail:  $licenseStatus `nExpected: $licenseValidation.status `n" | Out-File .\errors -Append
			} else {
				$osLicenseStatus["Value"] = $licenseStatus
				$osLicenseStatus["Status"] = "missing"
				Write-Output "Windows License Status: => missing: validation file was not detected: .\_validation\.windowsLicenseStatusServer.json `n" | Out-File .\errors -Append
			}
		}
	} else {
		$licenseValidation = Get-Content ".\_validation\.windowsLicenseStatus.json" -Raw | ConvertFrom-Json
		$mustLicenseStatus = $licenseValidation.status
		if ($licenseStatus -eq $licenseValidation.status) {
			$osLicenseStatus["Value"] = $licenseStatus
			$osLicenseStatus["Status"] = "pass"
		} else {
			if (Test-Path ".\_validation\.windowsLicenseStatus.json") {
				$osLicenseStatus["Value"] = $licenseStatus
				$osLicenseStatus["Status"] = "fail"
				Write-Output "Windows License Status: => fail:  $licenseStatus `nExpected: $licenseValidation.status `n" | Out-File .\errors -Append
			} else {
				$osLicenseStatus["Value"] = $licenseStatus
				$osLicenseStatus["Status"] = "missing"
				Write-Output "Windows License Status: => missing: validation file was not detected: .windowsLicenseStatus.json `n" | Out-File .\errors -Append
			}
		}
	}
    $versionTable.Rows.Add($osLicenseStatus)