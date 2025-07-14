	# defaultAppAssociations
	$defaultAppAssociations = $versionTable.NewRow()
	$defaultAppAssociations["About"] = "DefaultAppAssociations"

	$exportPath = ".\output\_defaultAppAssociations.xml"
	dism /Online /Export-DefaultAppAssociations:$exportPath

	$file1Path = $exportPath
	
	$build = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuild
		if ($build -eq '26100') {
			$file2Path = ".\_validation\.defaultAppAssociations26100"
		} elseif ($build -eq '19044'){
			$file2Path = ".\_validation\.defaultAppAssociations19044"
		} else {
			$file2Path = ".\_validation\.defaultAppAssociations19044"
		}
		
	# Compare $file1Path against $file2Path using proper quoting
	$fcResult = cmd /c "fc /B `"$file1Path`" `"$file2Path`""
	if ($fcResult -match "no differences encountered") {
		$defaultAppAssociations["Value"] = $file1Path
		$defaultAppAssociations["Status"] = "pass"
	}
	$versionTable.Rows.Add($defaultAppAssociations)
