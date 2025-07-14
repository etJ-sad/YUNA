	# UAC
	if ($currentOsBaseOperatingSystem -like "*Server*"){
		Write-Output "OS = $currentOsBaseOperatingSystem"
		$uacValues = Get-Content ".\_validation\.uacSettingsServer.json" | ConvertFrom-Json
		$uacPathFile = ".\_validation\.uacSettingsServer.json"
	} else {
		Write-Output "OS = $currentOsBaseOperatingSystem"
		$uacValues = Get-Content ".\_validation\.uacSettings.json" | ConvertFrom-Json
		$uacPathFile = ".\_validation\.uacSettings.json"
	}
	
	$registryPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System"
	$uacSettings = Get-ItemProperty -Path $registryPath -Name EnableLUA, ConsentPromptBehaviorAdmin, ConsentPromptBehaviorUser, PromptOnSecureDesktop

	$enableLUADescription = if ($uacSettings.EnableLUA -eq 1) {"Enabled"} else {"Disabled"}
	$consentPromptBehaviorAdminDescription = switch ($uacSettings.ConsentPromptBehaviorAdmin) {
		0 {"No prompt"}
		2 {"Prompt for consent on the secure desktop"}
		5 {"Prompt for consent"}
		4 {"Auto-approve in Admin Mode"}
		default {"Unknown setting"}
	}
	$consentPromptBehaviorUserDescription = switch ($uacSettings.ConsentPromptBehaviorUser) {
		0 {"Automatically deny elevation requests"}
		1 {"Prompt for credentials on the secure desktop"}
		3 {"Prompt for credentials"}
		default {"Unknown setting"}
	}
	$promptOnSecureDesktopDescription = if ($uacSettings.PromptOnSecureDesktop -eq 1) {"Enabled"} else {"Disabled"}

	$uacCurrent = @{
		"EnableLUA" = "EnableLUA (UAC is enabled): $enableLUADescription"
		"ConsentPromptBehaviorAdmin" = "ConsentPromptBehaviorAdmin: $consentPromptBehaviorAdminDescription"
		"ConsentPromptBehaviorUser" = "ConsentPromptBehaviorUser: $consentPromptBehaviorUserDescription"
		"PromptOnSecureDesktop" = "PromptOnSecureDesktop: $promptOnSecureDesktopDescription"
	}

	if (Test-Path $uacPathFile) {
		$uacSettingsMatch = $true
	} else {
		$uacSettingsMatch = $false
	}
	
	foreach ($key in $uacValues.psobject.Properties.Name) {
		$expectedValue = $uacValues.$key
		$actualValue = $uacCurrent.$key

		if ($actualValue -ne $expectedValue) {
			$uacSettingsMatch = $false
			break
		}
	}
	$uacCurrentJson = $uacCurrent | ConvertTo-Json
	
	$osUAC = $versionTable.NewRow()
	$osUAC["About"] = "UAC Settings"
	if ($uacSettingsMatch) {
		$osUAC["Value"] = $uacCurrentJson
		$osUAC["Status"] = "pass"
	} else {
		if (Test-Path "$uacPathFile") { 
			$osUAC["Value"] = $uacCurrentJson
			$osUAC["Status"] = "fail"
			Write-Output "UAC: => fail: `n $uacCurrentJson `n`nExpected: $uacValues `n" | Out-File .\errors -Append
		} else {
			$osUAC["Value"] = $uacCurrentJson
			$osUAC["Status"] = "missing"
			Write-Output "UAC: => missing: validation file was not detected: $uacPathFile `n" | Out-File .\errors -Append
		}
	}
	$versionTable.Rows.Add($osUAC)