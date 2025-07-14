	# System Recovery
    $systemRecoveryMenuCheckbox.Content = "Windows Recovery Environment (WinRE)"
    $systemRecoveryMenuCheckbox.Margin = "5,260,5,5"
    $systemRecoveryMenuPanel.Children.Add($systemRecoveryMenuCheckbox)
	
	if (Test-Path ".\output\_systemRecoveryMenu.json") { 
		$systemRecoveryMenuLogObject = @{
			EndTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
			Operation = "Boot System Recovery Menu"
			Status = "Completed"
		}
		$systemRecoveryMenuJSON = $systemRecoveryMenuLogObject  | ConvertTo-Json
		$systemRecoveryMenuJSON | Out-File ".\output\_systemRecoveryMenu.json"
		
		#$systemRecoveryMenuExportButton.Visibility = 'Hidden'
        $systemRecoveryMenuCheckbox.IsChecked = $true
		[System.Windows.MessageBox]::Show("Windows Recovery Boot log (output\_systemRecoveryMenu.json) detected. Log is now complete", "System reset", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
	}

    $systemRecoveryMenuExportButton.Content = "  Boot Windows Recovery  "
    $systemRecoveryMenuExportButton.Margin = "68,257,5,5"
    $systemRecoveryMenuExportButton.VerticalAlignment = "Top"
	#$systemRecoveryMenuExportButton.Visibility = 'Hidden'
    $systemRecoveryMenuExportButton.Add_Click({
        if ($systemRecoveryMenuCheckbox.IsChecked) {
        	if (Test-Path ".\output\_systemRecoveryMenu.json") {
        		[System.Windows.MessageBox]::Show("Windows Recovery Boot was already started. Previus log will be removed.", "Boot Windows Recovery", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) 
			    $systemRecoveryMenuLogObject = @{
				    StartTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
				    Operation = "Boot System Recovery Menu"
				    Status = "Started"
			    }
			
			    $systemRecoveryMenuJSON = $systemRecoveryMenuLogObject  | ConvertTo-Json
			    $systemRecoveryMenuJSON | Out-File ".\output\_systemRecoveryMenu.json"
				shutdown /r /o /f /t 00
            } else {
                [System.Windows.MessageBox]::Show("Windows Recovery will be booted", "Boot Windows Recovery", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
			    $systemRecoveryMenuLogObject = @{
				    StartTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
				    Operation = "Boot System Recovery Menu"
				    Status = "Started"
			    }
			
			    $systemRecoveryMenuJSON = $systemRecoveryMenuLogObject  | ConvertTo-Json
			    $systemRecoveryMenuJSON | Out-File ".\output\_systemRecoveryMenu.json"
				shutdown /r /o /f /t 00
            }
        } else {
			Write-Output "systemResetCheckbox is not checked"
            [System.Windows.MessageBox]::Show("Windows Recovery is not selected!", "Error!", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        }
    })
	$systemRecoveryMenuPanel.Children.Add($systemRecoveryMenuExportButton)
	$reportGridPanel.Children.Add($systemRecoveryMenuPanel)