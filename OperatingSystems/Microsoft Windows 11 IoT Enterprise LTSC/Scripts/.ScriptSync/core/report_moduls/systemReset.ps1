	# System Reset
    $systemResetCheckbox.Content = "Windows System Reset"
    $systemResetCheckbox.Margin = "5,230,5,5"
    $systemResetPanel.Children.Add($systemResetCheckbox)
	
	if (Test-Path ".\output\_systemReset.json") { 
		$systemResetLogObject = @{
			EndTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
			Operation = "System Reset"
			Status = "Completed"
		}
		$systemResetJSON = $systemResetLogObject| ConvertTo-Json
		$systemResetJSON | Out-File ".\output\_systemReset.json"

		#$systemResetExportButton.Visibility = 'Hidden'
        $systemResetCheckbox.IsChecked = $true
		[System.Windows.MessageBox]::Show("System reset log (output\_systemReset.json) detected. Log is now complete", "System reset", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
	}

    $systemResetExportButton.Content = "  Make system reset  "
    $systemResetExportButton.Margin = "162,227,5,5"
	#$systemResetExportButton.Visibility = 'Hidden'
    $systemResetExportButton.VerticalAlignment = "Top"
    $systemResetExportButton.Add_Click({
        if ($systemResetCheckbox.IsChecked) {
            [System.Windows.MessageBox]::Show("System reset will be executed", "System reset", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
			
			if (Test-Path ".\output\_systemReset.json") { 
				[System.Windows.MessageBox]::Show("System reset was already started. Previus log will be removed.", "System reset", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
				$systemResetLogObject = @{
					StartTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
					Operation = "System Reset"
					Status = "Started"
				}
				
				$systemResetJSON = $systemResetLogObject| ConvertTo-Json
				$systemResetJSON | Out-File ".\output\_systemReset.json"

				systemreset -factoryreset
			}
			else {
				$systemResetLogObject = @{
					StartTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
					Operation = "System Reset"
					Status = "Started"
				}
				
				$systemResetJSON = $systemResetLogObject| ConvertTo-Json
				$systemResetJSON | Out-File ".\output\_systemReset.json"

				systemreset -factoryreset
			}
        } else {
            Write-Output "systemResetCheckbox is not checked"
            [System.Windows.MessageBox]::Show("System reset is not selected!", "Error!", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    })
	$systemResetPanel.Children.Add($systemResetExportButton)
	$reportGridPanel.Children.Add($systemResetPanel)