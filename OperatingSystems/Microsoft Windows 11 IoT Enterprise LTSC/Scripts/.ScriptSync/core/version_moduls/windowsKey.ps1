	# Load Windows Key Information
	$output = & 'cscript.exe' 'C:\Windows\System32\slmgr.vbs' '/dli' 2>&1 | Out-String
	$osWindowsKey = $versionTable.NewRow()
	$osWindowsKey["About"] = "WindowsKey"

	$partialProductKeyRegex = "Partial\sProduct\sKey:\s(.+)"
	$partialProductKey = ([regex]::Match($output, $partialProductKeyRegex)).Groups[1].Value.Trim()

	# Determine the correct JSON file for validation based on the OS type
	$currentOS = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\" -Name "ProductName"
	if ($currentOS -like "*server*") {
		$windowsKeyValidation = Get-Content ".\_validation\.windowsKeysServer.json" -Raw | ConvertFrom-Json
	} elseif ($currentOS -like "*LTSC 2021*") {
		$windowsKeyValidation = Get-Content ".\_validation\.windowsKeysLTSC2021.json" -Raw | ConvertFrom-Json
	} elseif ($currentOS -like "*LTSC 2024*") {
		$windowsKeyValidation = Get-Content ".\_validation\.windowsKeysLTSC2024.json" -Raw | ConvertFrom-Json
	} elseif ($currentOS -like "*Windows 11*") { #TBD
		$windowsKeyValidation = Get-Content ".\_validation\.windowsKeysGAC.json" -Raw | ConvertFrom-Json
	} elseif ($currentOS -like "*Windows 10*") { #TBD
		$windowsKeyValidation = Get-Content ".\_validation\.windowsKeysGAC.json" -Raw | ConvertFrom-Json
	} else {
		Write-Output "No matching validation file found for the current OS."
		$osWindowsKey["Value"] = "Unknown OS"
		$osWindowsKey["Status"] = "fail"
		$versionTable.Rows.Add($osWindowsKey)
		return
	}

	$jsonContent = $windowsKeyValidation
	$wmi = Get-WmiObject -Class Win32_ComputerSystem
	$modelName = $wmi.Model.Trim()

	# Normalize the model name (remove spaces, special characters, and convert to uppercase)
	$normalizedModelName = $modelName -replace '\s+', '' -replace '[^a-zA-Z0-9]', '' | ForEach-Object { $_.ToUpper() }
	Write-Output "Normalized Model Name: $normalizedModelName"

	# Path for errors log
	$errorsPath = ".\errors"

	# Function to search for the model in JSON and compare the key
	function Compare-Key {
		param (
			$jsonSection,
			$sectionName
		)

		# Search in JSON for the corresponding device and compare the key
		foreach ($device in $jsonSection.device) {
			# Normalize the type in JSON (remove spaces, special characters, and convert to uppercase)
			$jsonType = $device.type -replace '\s+', '' -replace '[^a-zA-Z0-9]', '' | ForEach-Object { $_.ToUpper() }
			
			# Check if the JSON type is a substring of the normalized model name
			if ($normalizedModelName.Contains($jsonType)) {
				if ($device.key -eq $partialProductKey) {
					Write-Output "Match found in section: $sectionName - OK"
					$osWindowsKey["Value"] = $partialProductKey
					$osWindowsKey["Status"] = "pass"
					return $true
				}
			}
		}
		return $false
	}

	# Check all relevant sections in JSON (entry, value, high)
	$result = $false
	if (Compare-Key -jsonSection $jsonContent.entry -sectionName "entry") {
		$result = "entry"
	} elseif (Compare-Key -jsonSection $jsonContent.value -sectionName "value") {
		$result = "value"
	} elseif (Compare-Key -jsonSection $jsonContent.high -sectionName "high") {
		$result = "high"
	}

	# Check if a match was found and set status accordingly
	if ($result) {
		Write-Output "The key and model match in section: $result"
		$osWindowsKey["Status"] = "pass"
	} else {
		Write-Output "No match found for the model and key."
		$osWindowsKey["Value"] = $partialProductKey
		$osWindowsKey["Status"] = "fail"
		Write-Output "No match found for model: $normalizedModelName with key: $partialProductKey" | Out-File $errorsPath -Append
	}

	# Output the result object for clarity
	Write-Output "Status: $($osWindowsKey["Status"])"
	Write-Output "Value: $($osWindowsKey["Value"])"
		
	# Add the result to the version table
	$versionTable.Rows.Add($osWindowsKey)
