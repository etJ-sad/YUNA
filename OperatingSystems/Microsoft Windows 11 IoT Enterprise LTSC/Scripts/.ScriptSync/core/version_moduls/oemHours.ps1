	# OEM Hours
	$oemHoursRow = $versionTable.NewRow()
	$oemHoursRow["About"] = "SupportHours"

	$regPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation'
	$validationFile = ".\_validation\.oemHours.json"

	if (Test-Path $regPath) {
		$hours = (Get-ItemProperty -Path $regPath).SupportHours

		if ($null -ne $hours -and $hours -ne "") {
			if (Test-Path $validationFile) {
				$expected = Get-Content $validationFile -Raw | ConvertFrom-Json

				if ($hours -eq $expected.SupportHours) {
					$oemHoursRow["Value"] = $hours
					$oemHoursRow["Status"] = "pass"
				} else {
					$oemHoursRow["Value"] = $hours
					$oemHoursRow["Status"] = "fail"
					$message = "SupportHours: => fail: $hours `nExpected: $($expected.SupportHours) `n"
					Write-Output $message | Out-File .\errors -Append
				}
			} else {
				$oemHoursRow["Value"] = $hours
				$oemHoursRow["Status"] = "missing"
				Write-Output "SupportHours: => missing: validation file was not detected: $validationFile `n" | Out-File .\errors -Append
			}
		} else {
			$oemHoursRow["Value"] = "Error | SupportHours value is empty"
			$oemHoursRow["Status"] = "error"
		}
	} else {
		$oemHoursRow["Value"] = "Error | OEMInformation key not found"
		$oemHoursRow["Status"] = "missing"
	}

	$versionTable.Rows.Add($oemHoursRow)
