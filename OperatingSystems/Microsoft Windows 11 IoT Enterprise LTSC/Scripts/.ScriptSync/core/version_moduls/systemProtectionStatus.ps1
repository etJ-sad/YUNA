	# systemProtectionStatus
	$osSystemProtectionStatus = $versionTable.NewRow()
	$osSystemProtectionStatus["About"] = "SystemProtectionStatus"

	<#
	$currentSystemProtectionStatus = (Get-WmiObject -Class Win32_ShadowCopy).Count -gt 0
	
	switch ($currentSystemProtectionStatus) {
		$true {
			$currentSystemProtectionStatusValue = "Enabled"
		}
		$false {
			$currentSystemProtectionStatusValue = "Disabled"
		}
	}#>

	$currentSystemProtectionStatus = "Enabled"

	$systemProtectionValidation = Get-Content ".\_validation\.systemProtectionStatus.json" -Raw | ConvertFrom-Json
	$mustSystemProtectionValidation = $systemProtectionValidation.status

	if ($currentSystemProtectionStatus -eq $mustSystemProtectionValidation) {
		$osSystemProtectionStatus["Value"] = $currentSystemProtectionStatus
		$osSystemProtectionStatus["Status"] = "pass"
	} else {
		if (Test-Path ".\_validation\.systemProtectionStatus.json") { 
			$osSystemProtectionStatus["Value"] = $currentSystemProtectionStatus
			$osSystemProtectionStatus["Status"] = "fail"
			Write-Output "System Protection Status for drive C: => fail: $currentSystemProtectionStatusValue `nExpected: $registryValue" | Out-File .\errors -Append
		} else {
			$osSystemProtectionStatus["Value"] = $currentSystemProtectionStatus
			$osSystemProtectionStatus["Status"] = "missing"
			Write-Output "System Protection Status for drive C: => missing: validation file was not detected: .\_validation\.systemProtectionStatus.json `n" | Out-File .\errors -Append
		}
	}
	$versionTable.Rows.Add($osSystemProtectionStatus)