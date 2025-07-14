$powerProfile = Get-Content -Raw -Path ".\_validation\.powerschemaProfile.json" | ConvertFrom-Json

# Ignore Errors 
$ErrorActionPreference = 'silentlycontinue' 

<#
$sting = "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings" 
$querylist = reg query $sting 
	
foreach ($regfolder in $querylist) { 
	$querylist2 = reg query $regfolder 
		foreach($2ndfolder in $querylist2){ 
			$active2 = $2ndfolder -replace "HKEY_LOCAL_MACHINE" , "HKLM:" 
			Get-ItemProperty -Path $active2 
			Set-ItemProperty -Path "$active2" -Name "Attributes" -Value '2' 
		} 
	$active = $regfolder -replace "HKEY_LOCAL_MACHINE" , "HKLM:" 
	Get-ItemProperty -Path $active 
	Set-ItemProperty -Path "$active" -Name "Attributes" -Value '2' 
}
#>

function Show-PowerSchemaTab(){
    $powerSchemaTabItem.Header = "Power Schema"
    
    $activeSchemaGuid = $( powercfg /getactivescheme) |% {$_.split(" ")[3]}

    $powerSchemaCfgOutput = Invoke-Expression "powercfg /query $activeSchemaGuid"

    $powerSchemaTable.Clear()
    $powerSchemaTable.Columns.Clear()
    $powerSchemaTable.Columns.Add("Setting")
    $powerSchemaTable.Columns.Add("Value")
    $powerSchemaTable.Columns.Add("Status")
	$powerSchemaDataGrid.FontSize = 12

	foreach ($line in $powerSchemaCfgOutput -split "`r`n") {
		if ($line -match "Power Scheme GUID: (.*)\s+\((.*)\)") {
			$schemeGuid = $matches[1].Trim()
			$schemeName = $matches[2].Trim()
		} elseif ($line -match "Subgroup GUID: (.*)\s+\((.*)\)") {
			$subgroupGuid = $matches[1].Trim()
			$subgroupName = $matches[2].Trim()
		} elseif ($line -match "Power Setting GUID: (.*)\s+\((.*)\)") {
			$settingGuid = $matches[1].Trim()
			$settingName = $matches[2].Trim()
		} elseif ($line -match "\s+Possible Setting Index: (\d+)") {
			$settingIndex = $matches[1].Trim()
		} elseif ($line -match "\s+Possible Setting Friendly Name: (.*)") {
			$settingFriendlyName = $matches[1].Trim()
			
			if ($schemeName -like "*Internet Explorer*" -or $subgroupName -like "*Internet Explorer*" -or $settingName -like "*Internet Explorer*") {
				continue
			}
			
			$row = $powerSchemaTable.NewRow()
			$row["Setting"] = "$subgroupName - $settingName"
			$row["Value"] = $settingFriendlyName
			$powerSchemaTable.Rows.Add($row)
		}
	}
	
	$modelFound = $false
	$wmi = Get-WmiObject -Class Win32_ComputerSystem
	$modelName = $wmi.Model.Trim() 

	foreach ($key in $powerProfile.PSObject.Properties.Name) {
		$deviceName = $key
		Write-Output "DeviceName: $deviceName"
		
		if ($modelName -like "*$deviceName*") {
			$filePath = $powerProfile.$key
			$passValues = Get-Content ".\_validation\$filePath"
			Write-Output "File Path: $filePath"
			Write-Output "Pass Values: $passValues"
			$modelFound = $true
			break
		}
	}

	if (-not $modelFound) {
		$currentOS = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\" -Name "ProductName"
		if ($currentOS -like "*Server*") {
			$filePath = $powerProfile.default_server
		} else {
			$filePath = $powerProfile.default
		}
		$passValues = Get-Content ".\_validation\$filePath"
	}

	$expectedValues = @{}
	foreach ($passValue in $passValues) {
		$settingValue = $passValue -split ':'
		$expectedKey = $settingValue[0].Trim()
		$expectedValue = $settingValue[1].Trim()

		if (-not $expectedValues.ContainsKey($expectedKey)) {
			$expectedValues[$expectedKey] = New-Object System.Collections.ArrayList
		}
		$expectedValues[$expectedKey].Add($expectedValue) | Out-Null
	}

	foreach ($row in $powerSchemaTable.Rows) {
		$currentSetting = $row["Setting"]
		if ($expectedValues.ContainsKey($currentSetting)) {
			$expectedValueList = $expectedValues[$currentSetting]
			if ($expectedValueList -contains $row["Value"]) {
				$row["Status"] = "pass"
			} else {
				if (Test-Path ".\_validation\$filePath") { 
					if ($row["Value"] -like "*Internet Explorer*") {
						continue
					}
					$row["Status"] = "fail"
					Write-Output = "Powerschema:$currentSetting => fail: `nExpected: $expectedValueList `n" | Out-File .\errors -Append
				} else {
					$row["Status"] = "missing"
					Write-Output "Powerschema: => missing: validation file was not detected: .\_validation\$filePath `n" | Out-File .\errors -Append
				}
			}
		} else {
			if (Test-Path ".\_validation\$filePath") { 
				$row["Status"] = "fail"
				if ($row["Value"] -like "*Internet Explorer*") {
					continue
				}
				Write-Output = "Powerschema: => fail: $currentSetting  `nExpected: $($expectedValues.ContainsKey($currentSetting)) `n" | Out-File .\errors -Append
			} else {
				$row["Status"] = "missing"
				Write-Output "Powerschema: => missing: validation file was not detected: .\_validation\$filePath `n" | Out-File .\errors -Append
			}
		}
	}

	<#
	$powerSchemaDataGrid.add_LoadingRow({
        param($sender, $e)
        $row = $e.Row
        $status = $row.DataContext.Status
        if ($status -eq "fail") {
            $row.Background = "Red"
        } elseif ($status -eq "pass") {
            $row.Background = "#FFC4FFA6"
        }
    })
	
	#>

    # Append Content
    $powerSchemaDataGrid.ItemsSource = $powerSchemaTable.DefaultView
	$powerSchemaDataGrid.add_AutoGeneratedColumns({
		param($sender, $e)
		if ($sender.Columns.Count -ge 3) {
			$sender.Columns[0].Width = 75
			$sender.Columns[1].Width = 495
			$sender.Columns[2].Width = 300
		}
	})
	
	$powerStatusColumn = New-Object Windows.Controls.DataGridTemplateColumn
	$powerStatusColumn.Header = "Status"
	$powerStatusColumn.CellTemplate = [Windows.Markup.XamlReader]::Parse($cellTemplate)
	
	$powerSchemaDataGrid.Columns.Add($powerStatusColumn)
	
	$powerSchemaTabItem.Content = $powerSchemaDataGrid
    $tabControl.Items.Add($powerSchemaTabItem)
}
 
function Export-PowerSchemaToJson {
    param(
        [bool]$fullReport = $false
    )

    $powerSchemaJson = @()
	
    $powerSchemaTable.Rows | ForEach-Object {
        $powerSchemaInfo = [PSCustomObject]@{
            "Setting" = $_["Setting"]
            "Value" = $_["Value"]
			"Status" = $_["Status"]
        }
        $powerSchemaJson += $powerSchemaInfo
    }

    $jsonOutput = $powerSchemaJson | ConvertTo-Json -Depth 2
    $jsonOutput | Out-File -Encoding UTF8 -FilePath ".\output\_powerSchema.json"
}

