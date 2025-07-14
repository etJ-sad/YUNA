	# FullReport
    $createFullReportjsonfileButton.VerticalAlignment = "Bottom"
    $createFullReportjsonfileButton.Margin = "1,1,1,1"
    $createFullReportjsonfileButton.Content = "Create Full Report as json file"
    
	$createFullReportjsonfileButton.Add_Click({
		if (Test-Path ".\output\__FullReport.json") {
			Remove-Item ".\output\__FullReport.json"
			foreach ($file in $filesToDelete) {
				$filePath = Join-Path -Path "${PSScriptRoot}\output\" -ChildPath $file
				if (Test-Path $filePath) { Remove-Item $filePath -Force }
			}
		} 
        else {
		    if ($versionCheckbox.IsChecked) {
				Export-VersionTojson
                [System.Windows.MessageBox]::Show("Export complete.", "Windows version", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
            } else {
					$LogObject = @{
						Setting = "Not verified"
						Value = "Not verified"
						Status = "missing"
					}
					$jsonString = $LogObject | ConvertTo-Json
					$jsonArrayString = "[" + $jsonString + "]"
					$jsonArrayString | Out-File ".\output\_version.json"
					[System.Windows.MessageBox]::Show("Windows basic setting of image has not been verified by you.", "Error!", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            }

            if ($installedSoftwareCheckbox.IsChecked) {
				Export-InstalledSoftwareTojson
                [System.Windows.MessageBox]::Show("Export complete.", "Installed software", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
            } else {
					$LogObject = @{
						Software0 = @{
							Publisher = "Not verified"
							Name = "Not verified"
							Version = "missing"
						}
					}
					$jsonString = $LogObject | ConvertTo-Json
					$jsonString | Out-File ".\output\_installedSoftware.json"
					[System.Windows.MessageBox]::Show("Installed software has not been verified by you.", "Error!", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            }

            if ($installedDriversCheckbox.IsChecked) {
				Export-InstalledDriversTojson
                [System.Windows.MessageBox]::Show("Export complete.", "Installed Drivers", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
            } else {
					$LogObject = @{
						Driver0 = @{
							DeviceName = "Not verified"
							DriverVersion = "missing"
						}
					}
					$jsonString = $LogObject | ConvertTo-Json
					$jsonString | Out-File ".\output\_installedDrivers.json"
					[System.Windows.MessageBox]::Show("Installed drivers has not been verified by you.", "Error!", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            }
			
			if ($validateInstalledDriversCheckbox.IsChecked) {
					$LogObject = @{
						entity = "Not verified"
						identifier ="Not verified"
						vendor = "Not verified"
						entityName = "Not verified"
						entityVersion = "Not verified"
						driverFamilyId =   "missing"
					}
					$jsonString = $LogObject | ConvertTo-Json
					$jsonArrayString = "[" + $jsonString + "]"
					$jsonArrayString | Out-File ".\output\_autovalidation.json"
					
					$LogObject = @{
						detail = "Aborted"
						status = "missing"
					}
					$jsonString = $LogObject | ConvertTo-Json
					$jsonArrayString = $jsonString 
					$jsonArrayString | Out-File ".\output\_devicePass.json"
					$jsonArrayString | Out-File ".\output\_deviceFail.json"
				
				$path = Split-Path -Path $PSScriptRoot -Parent
				Write-Output $path
				$scriptPath = $path + "\_inputter.ps1"
				Write-Output $scriptPath
				Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
			} else {
					$LogObject = @{
						entity = "Not verified"
						identifier ="Not verified"
						vendor = "Not verified"
						entityName = "Not verified"
						entityVersion = "Not verified"
						driverFamilyId =   "missing"
					}
					$jsonString = $LogObject | ConvertTo-Json
					$jsonArrayString = "[" + $jsonString + "]"
					$jsonArrayString | Out-File ".\output\_autovalidation.json"
					
					$LogObject = @{
						detail = "Not verified"
						status = "missing"
					}
					$jsonString = $LogObject | ConvertTo-Json
					$jsonArrayString = $jsonString 
					$jsonArrayString | Out-File ".\output\_devicePass.json"
					$jsonArrayString | Out-File ".\output\_deviceFail.json"
					[System.Windows.MessageBox]::Show("Device Mask has not been validated by you.", "Error!", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
			}
		
		    if ($partitionCheckbox.IsChecked) {
				Export-PartitionTojson
                [System.Windows.MessageBox]::Show("Export complete.", "Partition Table", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
            } else {
					$LogObject = @{
						DriveLetter = "Not verified"
						Size_GB = "Not verified"
						FreeSpace_GB = "Not verified"
						Status = "missing"
					}
					$jsonString = $LogObject | ConvertTo-Json
					$jsonArrayString = "[" + $jsonString + "]"
					$jsonArrayString | Out-File ".\output\_partition.json"
					[System.Windows.MessageBox]::Show("Partiton has not been verified by you.", "Error!", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            }
			
			if ($powerSchemaCheckbox.IsChecked) {
				Export-PowerSchemaToJson
                [System.Windows.MessageBox]::Show("Export complete.", "Power Schema", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
            } else {
					$LogObject = @{
						Setting = "Not verified"
						Value = "Not verified"
						Status = "missing"
					}
					$jsonString = $LogObject | ConvertTo-Json
					$jsonArrayString = "[" + $jsonString + "]"
					$jsonArrayString | Out-File ".\output\_powerSchema.json"
					[System.Windows.MessageBox]::Show("Power Schema has not been verified by you.", "Error!", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            }

			if ($systemResetCheckbox.IsChecked) {
				if (Test-Path ".\output\_systemReset.json") {
					[System.Windows.MessageBox]::Show("Export complete.", "System Reset", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
				} else {
					$LogObject = @{
						EndTime = "Not verified"
						Operation = "Not verified"
						Status = "missing"
					}
					$nJSON = $LogObject  | ConvertTo-Json
					$nJSON| Out-File ".\output\_systemReset.json"
					[System.Windows.MessageBox]::Show("Windows Reset has not been verified by you.", "Error!", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
					
				}
            } else {
                Write-Output "$systemResetCheckbox is not checked"
					$LogObject = @{
						EndTime = "Not verified"
						Operation = "Not verified"
						Status = "missing"
					}
					$nJSON = $LogObject  | ConvertTo-Json
					$nJSON| Out-File ".\output\_systemReset.json"
                [System.Windows.MessageBox]::Show("Windows Reset has not been verified by you.", "Error!", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            }
			
			if ($systemRecoveryMenuCheckbox.IsChecked) {
				if (Test-Path ".\output\_systemRecoveryMenu.json") {
					[System.Windows.MessageBox]::Show("Export complete.", "Windows Recovery Menu", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
				} else {
					$LogObject = @{
						EndTime = "Not verified"
						Operation = "Not verified"
						Status = "missing"
					}
					$nJSON = $LogObject  | ConvertTo-Json
					$nJSON| Out-File ".\output\_systemRecoveryMenu.json"
					[System.Windows.MessageBox]::Show("Windows Recovery Menu has not been verified by you.", "Error!", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
				}
                
            } else {
                Write-Output "$systemResetCheckbox is not checked"
					$LogObject = @{
						EndTime = "Not verified"
						Operation = "Not verified"
						Status = "missing"
					}
					$nJSON = $LogObject  | ConvertTo-Json
					$nJSON| Out-File ".\output\_systemRecoveryMenu.json"
                [System.Windows.MessageBox]::Show("Windows Recovery Menu has not been verified by you.", "Error!", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            }
			
			if ($eventLogCheckbox.IsChecked) {
				Export-EventLogTojson
                [System.Windows.MessageBox]::Show("Export complete.", "Event Log", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
            } else {
					$LogObject = @{
						TimeGenerated = "Not verified"
						EntryType = "Not verified"
						Message = "Not verified"
						Status = "missing"
					}
					$jsonString = $LogObject | ConvertTo-Json
					$jsonArrayString = "[" + $jsonString + "]"
					$jsonArrayString | Out-File ".\output\_eventLog.json"
					[System.Windows.MessageBox]::Show("Event Log has not been verified by you.", "Error!", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            }
			

			if (Test-Path ".\output\_version.json") {
				$object1 = Get-Content -Path '.\output\_version.json' -Raw | ConvertFrom-json
			}

			else {
				$object1 = $null
			}
			
			if (Test-Path ".\output\_installedSoftware.json") {
				$object2 = Get-Content -Path '.\output\_installedSoftware.json' -Raw | ConvertFrom-json
			}
			else {
				$object2 = $null
			}
			
			if (Test-Path ".\output\_installedDrivers.json") {
				$object3 = Get-Content -Path '.\output\_installedDrivers.json' -Raw | ConvertFrom-json
			}
			else {
				$object3 = $null
			}
			
			if (Test-Path ".\output\_partition.json") {
				$object4 = Get-Content -Path '.\output\_partition.json' -Raw | ConvertFrom-json
			}
			else {
				$object4 = $null
			}
			
			if (Test-Path ".\output\_autovalidation.json") {
				$object5 = Get-Content -Path '.\output\_autovalidation.json' -Raw | ConvertFrom-json
				$object6 = Get-Content -Path '.\output\_devicePass.json' -Raw | ConvertFrom-json
				$object7 = Get-Content -Path '.\output\_deviceFail.json' -Raw | ConvertFrom-json
			}
			else {
				$object5 = $null
				$object6 = $null
				$object7 = $null
			}
			
			if (Test-Path ".\output\_powerSchema.json") {
				$object8 = Get-Content -Path '.\output\_powerSchema.json' -Raw | ConvertFrom-json
			}
			else {
				$object8 = $null
			}

			if (Test-Path ".\output\_systemReset.json") {
				$object9 = Get-Content -Path '.\output\_systemReset.json' -Raw | ConvertFrom-json
			}
			else {
				$object9 = $null
			}

			if (Test-Path ".\output\_systemRecoveryMenu.json") {
				$object10 = Get-Content -Path '.\output\_systemRecoveryMenu.json' -Raw | ConvertFrom-json
			}
			else {
				$object10 = $null
			}
			
			if (Test-Path ".\output\_eventLog.json") {
				$object11 = Get-Content -Path '.\output\_eventLog.json' -Raw | ConvertFrom-json
			}
			else {
				$object11 = $null
			}
			
			$jsonArray = @($object1, $object2, $object3, $object4, $object5, $object6, $object7, $object8, $object9, $object10, $object11)
			$jsonString = $jsonArray | ConvertTo-json -Depth 100
			$jsonString | Out-file -filePath '.\output\__FullReport.json' -Encoding UTF8
			
			. ".\core\report_moduls\htmlReport.ps1"
			
			[System.Windows.MessageBox]::Show("Export Full Report complete.", "Full Report .json file", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        }
    })
	$reportGridPanel.Children.Add($createFullReportjsonfileButton)