    # defenderSignatureVersion
    $osDefenderSignatureVersion = $versionTable.NewRow()
    $osDefenderSignatureVersion["About"] = "DefenderSignatureVersion"
	
	$currentDefenderSignature = (Get-MpComputerStatus).AntispywareSignatureVersion
	$DefenderSignatureValidation = Get-Content ".\_validation\.msDefenderSignatureVersion.json" -Raw | ConvertFrom-Json
	$mustSignatureVersion = $DefenderSignatureValidation.DefenderSignatureVersion

	if($currentDefenderSignature -eq $mustSignatureVersion) {
		$osDefenderSignatureVersion["Value"] = $currentDefenderSignature
		$osDefenderSignatureVersion["Status"] = "pass"
	} else {
		if (Test-Path ".\_validation\.msDefenderSignatureVersion.json") { 
			$osDefenderSignatureVersion["Value"] = $currentDefenderSignature
			$osDefenderSignatureVersion["Status"] = "fail"
			Write-Output "Defender Signanature Version: => fail: $currentDefenderSignature `nExpected: $mustSignatureVersion `n" | Out-File .\errors -Append
		} else {
			$osDefenderSignatureVersion["Value"] = $currentDefenderSignature
			$osDefenderSignatureVersion["Status"] = "missing"
			Write-Output "Defender Signanature Version: => missing: validation file was not detected: .\_validation\.msDefenderSignatureVersion.json `n" | Out-File .\errors -Append
		}
	}
    $versionTable.Rows.Add($osDefenderSignatureVersion)