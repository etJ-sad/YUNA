	# imageBuild
	$osImageBuild = $versionTable.NewRow()
	$osImageBuild["About"] = "ImageBuild"

	$currentImageBuild = $jsonContent.ImageBuild
	
	$imageBuildValidation = Get-Content ".\_validation\.imageBuild.json" -Raw | ConvertFrom-Json
	$mustImageValidation = $imageBuildValidation.imageBuild
	
	if (Test-Path "C:\Version.json") {
		$exist = $true
	} else {
		$exist = $false
	}

	if ($currentImageBuild -eq $mustImageValidation) {
		if ($exist) {
			$osImageBuild["Value"] = $currentImageBuild
			$osImageBuild["Status"] = "pass"
		} else {
			$osImageBuild["Value"] = "missing main data"
			$osImageBuild["Status"] = "missing"
			Write-Output "ImageBuild: => missing: main data `n" | Out-File .\errors -Append
		}
	} else {
		if (Test-Path ".\_validation\.imageBuild.json") { 
			$osImageBuild["Value"] = $currentImageBuild
			$osImageBuild["Status"] = "fail"
			Write-Output "ImageBuild: => fail: $currentImageBuild `nExpected: $mustImageValidation `n" | Out-File .\errors -Append
		} else {
			$osImageBuild["Value"] = $currentImageBuild
			$osImageBuild["Status"] = "missing"
			Write-Output "ImageBuild: => missing: validation file was not detected: .\_validation\.imageBuild.json `n" | Out-File .\errors -Append
		}
	}
	$versionTable.Rows.Add($osImageBuild)