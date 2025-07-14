	# microsoftEdgeInitialPreferences
	$edgeInitialPreferences = $versionTable.NewRow()
	$edgeInitialPreferences["About"] = "MicrosoftEdgeInitialPreferences"
	
	$file1Path = "C:\Program Files (x86)\Microsoft\Edge\Application\initial_preferences"
	$file2Path = ".\_validation\.initial_preferences"

	$fcResult = cmd /c fc /B $file1Path $file2Path
	if ($fcResult -match "no differences encountered") {
		$edgeInitialPreferences["Value"] = $file1Path
		$edgeInitialPreferences["Status"] = "pass"
	} else {
		if (Test-Path ".\_validation\.initial_preferences") { 
			$edgeInitialPreferences["Value"] = $file1Path
			$edgeInitialPreferences["Status"] = "fail"
			$message = "Microsoft Edge Initial Preferences Comparison: => fail: The preference files are different. `nFile: $file1Path `nExpected: $file2Path `n" 
			Write-Output $message | Out-File .\errors -Append
		} else {
			$edgeInitialPreferences["Value"] = $file1Path
			$edgeInitialPreferences["Status"] = "missing"
			Write-Output "Microsoft Edge Bookmarks Comparison: => missing: validation file was not detected: .\_validation\.initial_preferences `n" | Out-File .\errors -Append
		}
	}
	$versionTable.Rows.Add($edgeInitialPreferences)