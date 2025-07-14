	# Manufacturer
	$manufacturerRow = $versionTable.NewRow()
	$manufacturerRow["About"] = "Manufacturer"

	$regPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation'
	$validationFile = ".\_validation\.oemManufacturer.json"

	if (Test-Path $regPath) {
		$manufacturer = (Get-ItemProperty -Path $regPath).Manufacturer

		if ($null -ne $manufacturer -and $manufacturer -ne "") {
			if (Test-Path $validationFile) {
				$expected = Get-Content $validationFile -Raw | ConvertFrom-Json

				if ($manufacturer -eq $expected.Manufacturer) {
					$manufacturerRow["Value"] = $manufacturer
					$manufacturerRow["Status"] = "pass"
				} else {
					$manufacturerRow["Value"] = $manufacturer
					$manufacturerRow["Status"] = "fail"
					$message = "Manufacturer: => fail: $manufacturer `nExpected: $($expected.Manufacturer) `n"
					Write-Output $message | Out-File .\errors -Append
				}
			} else {
				$manufacturerRow["Value"] = $manufacturer
				$manufacturerRow["Status"] = "missing"
				Write-Output "Manufacturer: => missing: validation file was not detected: $validationFile `n" | Out-File .\errors -Append
			}
		} else {
			$manufacturerRow["Value"] = "Error | Manufacturer value is empty"
			$manufacturerRow["Status"] = "error"
		}
	} else {
		$manufacturerRow["Value"] = "Error | OEMInformation key not found"
		$manufacturerRow["Status"] = "missing"
	}

	$versionTable.Rows.Add($manufacturerRow)
