	# OEM Website
	$oemWebsiteRow = $versionTable.NewRow()
	$oemWebsiteRow["About"] = "SupportURL"

	$regPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation'
	$validationFile = ".\_validation\.oemWebsite.json"

	if (Test-Path $regPath) {
		$url = (Get-ItemProperty -Path $regPath).SupportURL

		if ($null -ne $url -and $url -ne "") {
			if (Test-Path $validationFile) {
				$expected = Get-Content $validationFile -Raw | ConvertFrom-Json

				if ($url -eq $expected.SupportURL) {
					$oemWebsiteRow["Value"] = $url
					$oemWebsiteRow["Status"] = "pass"
				} else {
					$oemWebsiteRow["Value"] = $url
					$oemWebsiteRow["Status"] = "fail"
					$message = "SupportURL: => fail: $url `nExpected: $($expected.SupportURL) `n"
					Write-Output $message | Out-File .\errors -Append
				}
			} else {
				$oemWebsiteRow["Value"] = $url
				$oemWebsiteRow["Status"] = "missing"
				Write-Output "SupportURL: => missing: validation file was not detected: $validationFile `n" | Out-File .\errors -Append
			}
		} else {
			$oemWebsiteRow["Value"] = "Error | SupportURL value is empty"
			$oemWebsiteRow["Status"] = "error"
		}
	} else {
		$oemWebsiteRow["Value"] = "Error | OEMInformation key not found"
		$oemWebsiteRow["Status"] = "missing"
	}

	$versionTable.Rows.Add($oemWebsiteRow)
