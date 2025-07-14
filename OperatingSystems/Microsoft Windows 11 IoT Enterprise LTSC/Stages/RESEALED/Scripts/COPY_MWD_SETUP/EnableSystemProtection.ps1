Enable-ComputerRestore -Drive "C:\"

#TBD
$currentSystemProtectionStatusValue = "Enabled"

$jsonFilePath = "C:\Windows\Panther\Siemens\.systemProtectionStatus.json"

$data = @{
		status = $currentSystemProtectionStatusValue
}

$jsonData = $data | ConvertTo-Json
$jsonData | Out-File -FilePath $jsonFilePath
Write-Host "System protection statys saved in JSON: $jsonFilePath"
