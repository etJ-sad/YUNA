	# languages
	$dismOutput = dism /online /get-intl
	$languages = @()

	$dismOutput -split "`r`n" | ForEach-Object {
		if ($_ -match "Installed language\(s\): (.*)") {
			$languages += $matches[1]
		}
	}
	
	$languagesString = $languages -join ", "
	$osLanguageExpected = Get-Content ".\_validation\.languages.json" -Raw | ConvertFrom-Json

	if ($null -ne $languages -and $languages.Count -gt 0) {
		$osLanguages = $versionTable.NewRow()
		$osLanguages["About"] = "Languages"
        if($languagesString -eq $osLanguageExpected.languages) {
            $osLanguages["Value"] = $languagesString
            $osLanguages["Status"] = "pass"
        } else {
			if (Test-Path ".\_validation\.languages.json") { 
				$osLanguages["Value"] = $languagesString
				$osLanguages["Status"] = "fail"
				Write-Output "Languages: => fail: $languagesString `nExpected: $osLanguageExpected `n" | Out-File .\errors -Append
			} else {
				$osLanguages["Value"] = $languagesString
				$osLanguages["Status"] = "missing"
				Write-Output "Languages: => missing: validation file was not detected: .\_validation\.languages.json `n" | Out-File .\errors -Append
			}
        }
		$versionTable.Rows.Add($osLanguages)
	} else {
		$osLanguages = $versionTable.NewRow()
		$osLanguages["About"] = "Languages"
		$osLanguages["Value"] = "Error | Windows not in English"
		$versionTable.Rows.Add($osLanguages)
	}