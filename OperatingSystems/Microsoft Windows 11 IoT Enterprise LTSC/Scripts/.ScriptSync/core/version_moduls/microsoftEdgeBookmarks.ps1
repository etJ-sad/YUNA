	# microsoftEdgeBookmarks
	$edgeBookmarks = $versionTable.NewRow()
	$edgeBookmarks["About"] = "MicrosoftEdgeBookmarks"

	$file1Path = "C:\Users\%username%\AppData\Local\Microsoft\Edge\User Data\Default\Bookmarks"

	$build = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuild
	if ($build -eq '26100') {
		$file2Path = ".\_validation\.bookmarks26100"
	} elseif ($build -eq '19044'){
		$file2Path = ".\_validation\.bookmarks19044"
	} else {
		$file2Path = ".\_validation\.bookmarks19044"
	}

	$fcResult = cmd /c fc /B $file1Path $file2Path
	
	if ($fcResult -match "no differences encountered") {
		$edgeBookmarks["Value"] = $file1Path
		$edgeBookmarks["Status"] = "pass"
	} else {
		if (Test-Path ".\_validation\.bookmarks") { 
			$edgeBookmarks["Value"] = $file1Path
			$edgeBookmarks["Status"] = "fail"
			$message = "Microsoft Edge Bookmarks Comparison: => fail: The bookmark files are different. `nFile: $file1Path `nExpected: $file2Path `n" 
			Write-Output $message | Out-File .\errors -Append
		} else {
			$edgeBookmarks["Value"] = $file1Path
			$edgeBookmarks["Status"] = "missing"
			Write-Output "Microsoft Edge Bookmarks Comparison: => missing: validation file was not detected: .\_validation\.bookmarks `n" | Out-File .\errors -Append
		}
	}
	$versionTable.Rows.Add($edgeBookmarks)