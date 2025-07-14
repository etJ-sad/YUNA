	# baseOperatingSystemBuild
	$osBaseOperatingSystemBuild = $versionTable.NewRow()
	$osBaseOperatingSystemBuild["About"] = "BaseOperatingSystemBuild"
	$osBuildVersionArray = Invoke-Expression -Command "cmd /c ver"
	$osBuildVersion = $osBuildVersionArray -split ' '
	$osBuildVersionAsText = $osBuildVersion[4]

	$lastIndex = $osBuildVersionAsText.LastIndexOf("]")

	$osBuildVersionAsText = $osBuildVersionAsText.Substring(0,$lastIndex)
	$osBuildVersionAsText = $osBuildVersionAsText.Substring(5,10)

	$osBaseOperatingSystemBuild["Value"] = $osBuildVersionAsText

	$jsonBaseOperatingSystemBuild = $jsonContent.BaseOperatingSystemBuild

	if ($osBuildVersionAsText -eq $jsonBaseOperatingSystemBuild) {
		$osBaseOperatingSystemBuild["Value"] = $osBuildVersionAsText
		$osBaseOperatingSystemBuild["Status"] = "pass"
	} else {
		if (Test-Path "C:\Version.json") { 
			$osBaseOperatingSystemBuild["Value"] = $osBuildVersionAsText
			$osBaseOperatingSystemBuild["Status"] = "fail"
			Write-Output "Base Operating System Build: => fail: $osBuildVersionAsText `nExpected: $jsonBaseOperatingSystemBuild `n" | Out-File .\errors -Append
		} else {
			$osBaseOperatingSystemBuild["Value"] = $osBuildVersionAsText
			$osBaseOperatingSystemBuild["Status"] = "missing"
			Write-Output "Base Operating System Build: => missing: validation file was not detected: C:\Version.json `n" | Out-File .\errors -Append
		}
	}
	$versionTable.Rows.Add($osBaseOperatingSystemBuild)