    # microsoftEdgeVersion
    $osMircosoftEdgeVersion = $versionTable.NewRow()
    $osMircosoftEdgeVersion["About"] = "MicrosoftEdgeVersion"
    $EdgeExe = Get-ChildItem -Path "C:\Program Files (x86)\Microsoft\Edge\Application" -Filter msedge.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    $EdgeVersion = $EdgeExe.VersionInfo.FileVersion
	
	$EdgeValidation = Get-Content ".\_validation\.msEdgeVersion.json" -Raw | ConvertFrom-Json
	$mustEdgeVersion = $EdgeValidation.MSEdgeVersion
	
	if($EdgeVersion -eq $mustEdgeVersion) {
		$osMircosoftEdgeVersion["Value"] = $EdgeVersion
		$osMircosoftEdgeVersion["Status"] = "pass"
	} else {
		$osMircosoftEdgeVersion["Value"] = $EdgeVersion
		if (Test-Path ".\_validation\.msEdgeVersion.json") { 
			$osMircosoftEdgeVersion["Status"] = "fail"
			Write-Output "Microsoft Edge Version: => fail: $EdgeVersion `nExpected: $mustEdgeVersion `n" | Out-File .\errors -Append
		} else {
			$osMircosoftEdgeVersion["Status"] = "missing"
			Write-Output "Microsoft Edge Version: => missing: validation file was not detected: .\_validation\.msEdgeVersion.json `n" | Out-File .\errors -Append

		}
	}
	$versionTable.Rows.Add($osMircosoftEdgeVersion)