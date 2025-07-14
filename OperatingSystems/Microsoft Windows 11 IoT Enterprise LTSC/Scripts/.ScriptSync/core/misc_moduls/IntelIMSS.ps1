	# Intel IMSS
	$intelIMSSInstalled = Get-AppxPackage -AllUsers | Where-Object { $_.Name -eq "AppUp.IntelManagementandSecurityStatus" }

	$intelIMSSCheckbox.Content = "Intel Management and Security Status"
	$intelIMSSCheckbox.Margin = "5,86,5,5"
	if ($intelIMSSInstalled -ne $null){
		$intelIMSSCheckbox.IsChecked = $true
	}
	$intelIMSSPanel.Children.Add($intelIMSSCheckbox)

	$intelIMSSExportButton.Content = " Start Intel Management and Security Status "
	$intelIMSSExportButton.Margin = "68,84,5,5"
	$intelIMSSExportButton.VerticalAlignment = "Top"
	$intelIMSSExportButton.IsEnabled = $intelIMSSInstalled -ne $null

	$intelIMSSExportButton.Add_Click({
		Start-Process "explorer.exe" "shell:appsFolder\AppUp.IntelManagementandSecurityStatus_8j3eq9eme6ctt!App"
	})

	$intelIMSSPanel.Children.Add($intelIMSSExportButton)

	$miscGridPanel.Children.Add($intelIMSSPanel)
