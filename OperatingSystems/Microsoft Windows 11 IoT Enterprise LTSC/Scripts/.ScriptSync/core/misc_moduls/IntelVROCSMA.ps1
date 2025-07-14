	# Intel VROC SMA
	$intelVROCSMAInstalled = Get-AppxPackage -AllUsers | Where-Object { $_.Name -eq "AppUp.IntelVirtualRAIDonCPUStorageManagementApp" }

	$intelVROCSMACheckbox.Content = "Intel Virtual Raid on CPU Management"
	$intelVROCSMACheckbox.Margin = "5,113,5,5"
	if ($intelVROCSMAInstalled -ne $null) {
		$intelVROCSMACheckbox.IsChecked = $true
	}
	$intelVROCSMAPanel.Children.Add($intelVROCSMACheckbox)

	$intelVROCSMAExportButton.Content = " Start Intel Virtual Raid on CPU Management "
	$intelVROCSMAExportButton.Margin = "64,111,5,5"
	$intelVROCSMAExportButton.VerticalAlignment = "Top"
	$intelVROCSMAExportButton.IsEnabled = $intelVROCSMAInstalled -ne $null

	$intelVROCSMAExportButton.Add_Click({
		Start-Process "explorer.exe" "shell:appsFolder\AppUp.IntelVirtualRAIDonCPUStorageManagementApp_8.5.1592.0_x64__8j3eq9eme6ctt!App"
	})

	$intelVROCSMAPanel.Children.Add($intelVROCSMAExportButton)

	$miscGridPanel.Children.Add($intelVROCSMAPanel)
