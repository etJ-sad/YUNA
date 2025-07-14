	# OEM Phone
	$oemPhoneRow = $versionTable.NewRow()
	$oemPhoneRow["About"] = "SupportPhone"

	$regPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation'
	$validationFile = ".\_validation\.oemPhone.json"

	if (Test-Path $regPath) {
		$phone = (Get-ItemProperty -Path $regPath).SupportPhone

		if ($null -ne $phone -and $phone -ne "") {
			if (Test-Path $validationFile) {
				$expected = Get-Content $validationFile -Raw | ConvertFrom-Json

				if ($phone -eq $expected.SupportPhone) {
					$oemPhoneRow["Value"] = $phone
					$oemPhoneRow["Status"] = "pass"
				} else {
					$oemPhoneRow["Value"] = $phone
					$oemPhoneRow["Status"] = "fail"
					$message = "SupportPhone: => fail: $phone `nExpected: $($expected.SupportPhone) `n"
					Write-Output $message | Out-File .\errors -Append
				}
			} else {
				$oemPhoneRow["Value"] = $phone
				$oemPhoneRow["Status"] = "missing"
				Write-Output "SupportPhone: => missing: validation file was not detected: $validationFile `n" | Out-File .\errors -Append
			}
		} else {
			$oemPhoneRow["Value"] = "Error | SupportPhone value is empty"
			$oemPhoneRow["Status"] = "error"
		}
	} else {
		$oemPhoneRow["Value"] = "Error | OEMInformation key not found"
		$oemPhoneRow["Status"] = "missing"
	}

	$versionTable.Rows.Add($oemPhoneRow)
