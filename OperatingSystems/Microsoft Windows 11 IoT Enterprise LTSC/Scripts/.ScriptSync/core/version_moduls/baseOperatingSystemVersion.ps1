	# baseOperatingSystemVersion
	$osBaseOperatingSystemVersion = $versionTable.NewRow()
	$osBaseOperatingSystemVersion["About"] = "BaseOperatingSystemVersion"
	
	$currentOsBaseOperatingSystemVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name DisplayVersion).DisplayVersion
	
	$jsonBaseOperatingSystemVersion = $jsonContent.BaseOperatingSystemVersion
	
	if ($currentOsBaseOperatingSystemVersion -eq $jsonBaseOperatingSystemVersion) {
		$osBaseOperatingSystemVersion["Value"] = $currentOsBaseOperatingSystemVersion
		$osBaseOperatingSystemVersion["Status"] = "pass"
	} else {
		if (Test-Path "C:\Version.json") { 
			$osBaseOperatingSystemVersion["Value"] = $currentOsBaseOperatingSystemVersion
			$osBaseOperatingSystemVersion["Status"] = "fail"
			Write-Output "Base Operating System Version: => fail: $currentOsBaseOperatingSystemVersion `nExpected: $jsonBaseOperatingSystemVersion `n" | Out-File .\errors -Append
		} else {
			$osBaseOperatingSystemVersion["Value"] = $currentOsBaseOperatingSystemVersion
			$osBaseOperatingSystemVersion["Status"] = "missing"
			Write-Output "Base Operating System Build: => missing: validation file was not detected: C:\Version.json `n" | Out-File .\errors -Append
		}
	}
	$versionTable.Rows.Add($osBaseOperatingSystemVersion)