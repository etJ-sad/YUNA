	# languagesLXP via Get-AppxPackage
	$lxpPackages = Get-AppxPackage -AllUsers | Where-Object { $_.Name -like 'Microsoft.LanguageExperiencePack*' }
	$languages = @()

	foreach ($pkg in $lxpPackages) {
		if ($pkg.Name -match "LanguageExperiencePack([a-z]{2}-[A-Z]{2})") {
			$languages += $matches[1]
		}
	}

	$languagesString = $languages -join ", "
	$osLanguageExpected = Get-Content ".\_validation\.languagesLXP.json" -Raw | ConvertFrom-Json

	$osLanguagesLXP = $versionTable.NewRow()
	$osLanguagesLXP["About"] = "LanguagesLXP"

	if ($languages.Count -gt 0) {
		if ($languagesString -eq $osLanguageExpected.languagesLXP) {
			$osLanguagesLXP["Value"] = $languagesString
			$osLanguagesLXP["Status"] = "pass"
		} else {
			if (Test-Path ".\_validation\.languagesLXP.json") {
				$osLanguagesLXP["Value"] = $languagesString
				$osLanguagesLXP["Status"] = "fail"
				Write-Output "LanguagesLXP: => fail: $languagesString `nExpected: $($osLanguageExpected.languagesLXP)`n" | Out-File .\errors -Append
			} else {
				$osLanguagesLXP["Value"] = $languagesString
				$osLanguagesLXP["Status"] = "missing"
				Write-Output "LanguagesLXP: => missing: validation file was not detected: .\_validation\.languagesLXP.json `n" | Out-File .\errors -Append
			}
		}

		$build = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuild
		if ($build -eq '26100') {
			$versionTable.Rows.Add($osLanguagesLXP)
		} else {
			Write-Output "Different build detected - not needed"
		}
	}