	# installedUpdates
	$osInstalledUpdatesList = $versionTable.NewRow()
	$osInstalledUpdatesList["About"] = "InstalledUpdatesList"
	
	$kbNumbers = @()
    
	$hotfixes = Get-Hotfix
    foreach ($hotfix in $hotfixes) {
        if ($hotfix.HotFixID -match '(?i)kb(\d+)') {
            $kbNumbers += $hotfix.HotFixID
        }
    }

	$kbNumbersUnique = $kbNumbers | Select-Object -Unique | Sort-Object

	$jsonFilePath = ".\output\.currentInstalledWindowsUpdates.json"
	$data = @{}
	for ($i = 0; $i -lt $kbNumbersUnique.Count; $i++) {
		$update = "Update$($i+1)"
		$data[$update] = $kbNumbersUnique[$i]
	}
	$jsonData = $data.GetEnumerator() | Sort-Object Value | Select-Object -Property Key, Value | ConvertTo-Json
	$jsonData | Out-File -FilePath $jsonFilePath

	Write-Output "Current Updates KB saved in JSON: $jsonFilePath"

	$currentInstalledWindowsUpdates = Get-Content ".\output\.currentInstalledWindowsUpdates.json" -Raw | ConvertFrom-Json
	$reqInstalledWindowsUpdates = Get-Content ".\_validation\.installedWindowsUpdates.json" -Raw | ConvertFrom-Json
	
	$fullList = ($currentInstalledWindowsUpdates | ForEach-Object { $_.Value }) -join ",`n"

	if ($currentInstalledWindowsUpdates.Count -ne $reqInstalledWindowsUpdates.Count) {
		$osInstalledUpdatesList["Value"] = $currentInstalledWindowsUpdates
		$osInstalledUpdatesList["Status"] = "fail"
		if (Test-Path ".\_validation\.installedWindowsUpdates.json") { 
			$osInstalledUpdatesList["Value"] = $fullList
			$osInstalledUpdatesList["Status"] = "fail"
			Write-Output "Windows update: => fail: Update $($i+1) does not match." | Out-File .\errors -Append
		} else {
			$osInstalledUpdatesList["Value"] = $fullList
			$osInstalledUpdatesList["Status"] = "missing"
			Write-Output "Windows update: => missing: validation file was not detected `n" | Out-File .\errors -Append
		}
	} else {
		$mismatch = $false
		for ($i = 0; $i -lt $currentInstalledWindowsUpdates.Count; $i++) {
			$currentUpdate = $currentInstalledWindowsUpdates[$i]
			$reqUpdate = $reqInstalledWindowsUpdates[$i]

			if ($currentUpdate.Key -ne $reqUpdate.Key -or $currentUpdate.Value -ne $reqUpdate.Value) {
				$mismatch = $true
				break
			}
		}

		if ($mismatch) {
			if (Test-Path ".\_validation\.installedWindowsUpdates.json") { 
				$osInstalledUpdatesList["Value"] = $fullList
				$osInstalledUpdatesList["Status"] = "fail"
				Write-Output "Windows update: => fail: Update $($i+1) does not match." | Out-File .\errors -Append
			} else {
				$osInstalledUpdatesList["Value"] = $fullList
				$osInstalledUpdatesList["Status"] = "missing"
				Write-Output "Windows update: => missing: validation file was not detected: .\_validation\.installedWindowsUpdates.json `n" | Out-File .\errors -Append
			}
		} else {
			$osInstalledUpdatesList["Value"] = $fullList
			$osInstalledUpdatesList["Status"] = "pass"
		}
	}
	$versionTable.Rows.Add($osInstalledUpdatesList)